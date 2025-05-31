%Example on scaling the mesh density of the rotor shaft and core

dim_base; %initial dimensions

%let's assign a different material to the shaft, in order to actually
%create a Domain for the shaft
dim.shaft_material = Material.create(1);
dim.shaft_material.name = 'Another shaft material';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finalizing model

stator = Stator(dim);
rotor = CoatedRotor(dim);

figure(1); clf; hold on; box on; axis equal;
stator.plot_geometry();
rotor.plot_geometry();

%for faster analysis
rotor.scale_mesh_density(2, 'lcar_max', 15e-3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scaling the mesh density in the rotor core and shaft both

core = rotor.domains.get('Rotor_core');
shaft = rotor.domains.get('Shaft');

EXAMPLE_TYPE = 2;

if EXAMPLE_TYPE == 1
    %scaling the mesh density over rotor core and shaft both
    scale_domain_mesh_density([core shaft], 0.5, ... %halve edge length by default
        'lcar_min', 1e-3, ... %set minimum edge length
        'lcar_max', 15e-3); %set maximum edge length
    
    %further adjust the shaft
    scale_domain_mesh_density(shaft, 0.25, ... %halve edge length by default
        'lcar_min', 1.5e-3, ... %set minimum edge length
        'lcar_max', 15e-3); %set maximum edge length
elseif EXAMPLE_TYPE == 2
    %only refining the interface
    shaft_curves = GeoHelper.get_curves(shaft.surfaces);
    core_curves = GeoHelper.get_curves(core.surfaces);
    
    %shared curves
    interface_curves = intersect(shaft_curves, core_curves);

    %points on interface
    interface_points = GeoHelper.get_points(interface_curves);

    %adjusting characteristic length
    for p = interface_points
        %p.lcar = p.lcar * 0.1;
        p.lcar = 0.5e-3;
    end
end

motor = RFmodel(dim, stator, rotor);

figure(2); clf; hold on; box on; axis equal;
motor.visualize('linestyle','-');