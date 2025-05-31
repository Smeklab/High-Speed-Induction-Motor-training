%Somewhat stupid example on adding holes to an existing geometry.
% Note that the added surfaces have to be wholly within an existing
% surface, for now.

dim_base; %initial dimensions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finalizing model

stator = Stator(dim);
rotor = CoatedRotor(dim);

figure(1); clf; hold on; box on; axis equal;
stator.plot_geometry();
rotor.plot_geometry();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% adding holes to the rotor core
%
% Note that these holes are not allowed to intersect any existing Curves
% (Lines or Arcs)

mair = rotor.create_and_add_material(0); %to avoid dublicate materials
Holes = Domain('Holes', mair);
rotor.add_domain(Holes);
Core = rotor.domains.get('Rotor_core');

N = 7;
r = 3e-3;
R = dim.Rin + 2*r;
angles = linspace(0, pi, 2*N+2); angles = angles(2:2:(end-1));

for k = 1:numel(angles)
    c = Circle.from_coordinates(R*cos(angles(k)), R*sin(angles(k)), r, r/3);
    Holes.add_surface(c);
    Core.surfaces(1).add_hole(c);

    c.plot('r');
end
assert(rotor.check_feasibility())

rotor.plot_geometry();

%return

%for faster analysis
rotor.scale_mesh_density(2, 'lcar_max', 15e-3);



motor = RFmodel(dim, stator, rotor);

figure(2); clf; hold on; box on; axis equal;
motor.visualize('linestyle','-');

figure(3); clf; hold on;
motor.mesh.triplot([]);