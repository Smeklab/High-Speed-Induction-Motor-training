%Simple example of a solid-rotor induction motor.
%
% Despite the name, the templates used are indeed quite flexible - it's the
% design here that is as suboptimal as it gets :)

%creating a struct for dimensions
dim = struct();

dim.UDC = 600; %DC-link voltage
dim.fs = 8e3; %switching frequency

%Some design point information - these are not used by the built-in
%templates, but keeping them here is handy.
dim.Ttarget = 10; %torque target
dim.rpm = 45e3; %rated rpm
dim.Jrms = 6e6; %target / fixed current density
dim.v_surface = 150; %rotor surface speed
dim.number_of_slots_per_pole_and_phase = 4;
dim.B1_ag = 0.4; %fundamental airgap flux density
dim.ULL = 400; %line-to-line voltage rms

dim.p = 1; %pole-pairs
dim.symmetry_sectors = 2*dim.p; %symmetry sectors in FEA model

dim.delta = 3e-3; %airgap
dim.leff = 150e-3; %stack length

%temperatures
dim.temperature_stator = 120;
dim.temperature_rotor = 160;

%rotor radius
dim.Rout = (dim.v_surface / (2*pi*dim.rpm/60));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% stator dimensions

%main stator dimensions
dim.Qs = 6*dim.p*dim.number_of_slots_per_pole_and_phase; %number of slots

dim.Sin = dim.Rout + dim.delta;  %stator inner radius
dim.Sout = dim.Sin / 0.4; %outer radius

%winding specification, all-default values
winding_spec = DistributedWindingSpec(dim);
winding_spec.N_layers = 2; %winding layers
winding_spec.number_of_turns_per_coil = 3;
winding_spec.c = -2; %short-pitching control variable
winding_spec.a = 2; %parallel paths
dim.stator_winding = winding_spec;

%slot dimensions
h_yoke = 2/pi * pi/dim.p*dim.Sin*dim.B1_ag / 1.5; %yoke height for given flux densities
dim.hslot_s = (dim.Sout - dim.Sin) - h_yoke; %ag to slot bottom distance
dim.htt_s = 3e-3; %tooth tip, total
dim.htt_taper_s = dim.htt_s/2; %slot opening height
dim.wso_s = 1.8e-3; %slot opening width
dim.r_slotbottom_s = 4e-3; %slot bottom fillet radius
dim.wtooth_s = 2*pi*dim.Sin/dim.Qs * 0.6; %tooth width

%stator materials
dim.stator_core_material = SteelLibrary.create('M270-35A');
dim.stator_stacking_factor = 0.95; %decent
dim.stator_wedge_material = 0; %no wedge

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% rotor dimensions

dim.Rout = dim.Sin - dim.delta; %outer radius
dim.Rin = dim.Rout/2; %virtual inner diameter, only controls mesh density here

dim.h_coat = 2e-3; %rotor coat thickness

%using some built-in hard-coded material here
% see help get_defaultMaterials
dim.rotor_core_material = 1; %core material; construction steel
dim.shaft_material = dim.rotor_core_material;
dim.rotor_coat_material = 18; %copper

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