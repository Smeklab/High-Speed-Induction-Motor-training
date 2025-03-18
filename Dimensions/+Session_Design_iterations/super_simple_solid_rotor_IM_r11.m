%super_simple_solid_rotor_IM Super-simple template example.


%changed
% ag 2-->3
% ws0 2-->1.8
% ID/OD, slot height

dim = struct();

dim.Ttarget = 10;

dim.Jrms = 6e6;

dim.p = 1; %pole-pairs
dim.symmetry_sectors = 2*dim.p;

dim.delta = 3e-3; %airgap
dim.leff = 150e-3; %stack length

%temperatures
dim.temperature_stator = 120;
dim.temperature_rotor = 160;

%design point rpm; not required by anything but handy to keep here
dim.rpm = 45e3;

%rotor surface speed and radius
v = 150;
dim.Rout = (v / (2*pi*dim.rpm/60));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% stator dimensions

%main stator dimensions
dim.Qs = 6*dim.p*4; %number of slots

dim.Sin = dim.Rout + dim.delta; 
dim.Sout = dim.Sin / 0.4;


%winding specification, all-default values
winding_spec = DistributedWindingSpec(dim);
winding_spec.N_layers = 2;
winding_spec.number_of_turns_per_coil = 1;
winding_spec.c = -2;
%winding_spec.c = 0;
dim.stator_winding = winding_spec;


%slot dimensions
dim.hslot_s = (dim.Sout - dim.Sin)*0.65;
dim.htt_s = 3e-3; %tooth tip, total
dim.htt_taper_s = dim.htt_s/2; %slot opening height
dim.wso_s = 1.8e-3; %slot opening width
dim.r_slotbottom_s = 5e-3; %slot bottom fillet radius
dim.wtooth_s = 2*pi*dim.Sin/dim.Qs * 0.6; %tooth width

%stator materials
dim.stator_core_material = SteelLibrary.create('M270-35A');
dim.stator_stacking_factor = 0.95; %decent
dim.stator_wedge_material = 0; %no wedge

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% rotor dimensions

dim.Rout = dim.Sin - dim.delta; %outer radius
dim.Rin = dim.Rout/2; %virtual inner diameter, only controls mesh density here

dim.h_coat = 2e-3;

%using some built-in hard-coded material here
% see help get_defaultMaterials
dim.rotor_core_material = 1; %core material; construction steel
dim.shaft_material = dim.rotor_core_material;
dim.rotor_coat_material = 18;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% creating geometry

%initializing and plotting templates
stator = Stator(dim);
rotor = CoatedRotor(dim);

figure(1); clf; hold on; box on; axis equal;
stator.plot_geometry();
rotor.plot_geometry();

%for faster analysis
rotor.scale_mesh_density(2, 'lcar_max', 15e-3);

%model object and visualization
motor = RFmodel(dim, stator, rotor);

figure(2); clf; hold on; box on; axis equal;
motor.visualize('plot_axial', true);

figure(3); clf; hold on; box on; axis equal;
motor.mesh.triplot([]);