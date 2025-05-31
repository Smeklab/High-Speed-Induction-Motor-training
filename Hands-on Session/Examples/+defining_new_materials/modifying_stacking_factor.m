%Example for using a PM material with a custom demagnetization curve.
%
% Note that the BH behaviour is linear outside the 'demagnetization'
% region; please let us know if nonlinear but reversible BH behaviour is
% needed.

dim = struct();


dim.rpm = 30e3;
dim.Ttarget = 9.7949;

dim.UDC = 265.9928;
dim.fs = 8e3;

v = 100;
dim.Rout = v / (2*pi*dim.rpm/60);

dim.leff = dim.Rout*3;

dim.p = 1;
dim.temperature_rotor = 140;
dim.temperature_stator = 120;

dim.delta = 2e-3;
dim.symmetry_sectors = 2*dim.p;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% stator

dim.Sin = dim.Rout + dim.delta;
dim.Sout = dim.Sin / 0.5;

dim.Qs = 6*dim.p*3;

spec = DistributedWindingSpec(dim);
dim.stator_winding = spec;


dim.hslot_s = 20e-3;
dim.htt_s = 3e-3;
dim.htt_taper_s = 1.5e-3;
dim.wso_s = 2e-3;
dim.r_slotbottom_s = 2e-3;
dim.wtooth_s = 2*pi*dim.Sin/dim.Qs * 0.55;

dim.stator_core_material = SteelLibrary.create('NO20');
dim.stator_stacking_factor = 0.97;
dim.stator_wedge_material = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% rotor

dim.Rin = dim.Rout / 2;
dim.h_sleeve = 3e-3;
dim.hpm = 5e-3;

dim.number_of_magnets = 4;

dim.rotor_core_material = 1;
dim.shaft_material = 0;
dim.magnet_height = dim.leff/5;

dim.rotor_sleeve_material = 20;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Creating magnet material

%begin from existing material to avoid needing to set all properties
m_linear = PMlibrary.create('N42EH');
dim.magnet_material = m_linear;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

stator = Stator(dim);
rotor = HSSPM(dim);



figure(1); clf; hold on; box on; axis equal;
stator.plot_geometry();
rotor.plot_geometry();


motor = RFmodel(dim, stator, rotor);

%manually setting stacking factor
% NOTE: needs the latest EMDtool release (2025-04-15 or newer)
mcore_in_model = stator.materials.get(dim.stator_core_material.name);
mcore_in_model.stacking_factors = ones(1, numel(mcore_in_model.elements)) * 0.95;

figure(2); clf; hold on; box on; axis equal;
motor.visualize('linestyle', '-');

