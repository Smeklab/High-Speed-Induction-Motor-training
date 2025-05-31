%Example demonstrating use of materials with a custom BH curve
%
% Also see:
% https://www.emdtool.com/documentation/knowledge_base/defining_materials.html

dim_base; %initial dimensions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% how to store custom BH curves and loss data in a local Excel file:

mcore = SteelLibrary.create('Custom_material_1', ... %material nime in Excel
    'file_to_use', 'Data/Custom_steels.xlsx', ... %loading from custom file
    'include_excess', true); %not included by default
mcore.material_properties.rho = 7.6e3; %custom density

dim.stator_core_material = mcore;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% How to create a one-off material with a custom BH curve

mrotor = Material.create(1); %start from built-in construction steel

%artificial BH curve saturating really early
B_an = transpose(0:0.1:1.2);
H_an = H_langevin_single(B_an, 1.2, 50);
mrotor.B = B_an;
mrotor.H = H_an;
mrotor.initialize_material_data();

% seeing interpolation/extrapolation data:
mrotor.data

% See help Material.iron_loss_density_time_domain_Steinmetz to see Steinmetz
% (hysteresis) exponents

%always a good idea to rename
mrotor.name = 'Custom low-saturation steel';

%let's put some large losses, in W/kg at 50 Hz and 1T
mrotor.material_properties.coeffs = [15, 1, 0.1]; %hysteresis / eddy / excess

%let's turn it magenta
mrotor.plot_args = {[1 0 1]};

dim.rotor_core_material = mrotor;
dim.shaft_material = mrotor;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finalizing model

stator = Stator(dim);
rotor = CoatedRotor(dim);

figure(1); clf; hold on; box on; axis equal;
stator.plot_geometry();
rotor.plot_geometry();

%for faster analysis
rotor.scale_mesh_density(2, 'lcar_max', 15e-3);

motor = RFmodel(dim, stator, rotor);

figure(2); clf; hold on; box on; axis equal;
motor.visualize();