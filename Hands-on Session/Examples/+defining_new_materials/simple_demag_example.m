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
mmag = DemagMaterial1().from_material(m_linear);

dim.magnet_material = mmag;

%change intrinsic coercivity to something resulting in a really poor value
%at the operating temp
try
    mmag.intrinsic_coercivity = 800e3;
catch
    disp('Please consider re-downloading EMDtool to access the latest updates :).')
    mmag.material_properties.HcJ = 800e3;
end
fprintf('HcJ at rotor temp: %.0f kA/m\n', ...
    mmag.intrinsic_coercivity_at_temperature(dim.temperature_rotor)/1e3);

%setting up simple model
mmag.use_simple_model = true;
mmag.H0 = 10e3; %change the squareness
mmag.initialize_simple_model(dim.temperature_rotor);

figure(10); clf; hold on; box on; grid on;
mmag.visualize_demag_curve();

xline(-mmag.intrinsic_coercivity_at_temperature(dim.temperature_rotor), 'r');
yline(mmag.remanence_flux_density_at_temperature(dim.temperature_rotor, true), 'c');

legend('B(H)', 'J(H)', 'HcJ', 'Br')

figure(11); clf; hold on; box on; grid on;
mmag.visualize_BH(0:0.25:2.5);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

stator = Stator(dim);
rotor = HSSPM(dim);

mmag_in_model = rotor.materials.get(mmag.name);

figure(1); clf; hold on; box on; axis equal;
stator.plot_geometry();
rotor.plot_geometry();


motor = RFmodel(dim, stator, rotor);

figure(2); clf; hold on; box on; axis equal;
motor.visualize('linestyle', '-');
rotor.PMs.plot_elementwise_remanence_direction('color', 'm');

