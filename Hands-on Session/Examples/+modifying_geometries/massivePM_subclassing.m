% Example demonstrating on how to subclass geometries, this time creating a
% geometry with a ring magnet, shaft, and a hole.
%
% Alternative, never hesitate contacting Smeklab with any problems -
% standard EMDtool subscriptions include 10h of annual support, which is
% enough for 2-4 custom templates of small to moderate complexity :)
%
% Please also see:
% https://www.emdtool.com/documentation/templates/geometry_creation.html

dim_base; %initial dimensions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% new rotor dimensions

dim.h_sleeve = 3e-3;

dim.sleeve_material = 20;

dim.magnet_material = PMlibrary.create('N42UH');

dim.r_hole = dim.Rin / 2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finalizing model

stator = Stator(dim);


figure(1); clf; hold on; box on; axis equal;
stator.plot_geometry();

%instantiating the new rotor geometry template --> See
%Lib/@MassivePM_subclass for the implementation
rotor = MassivePM_subclass(dim);
rotor.plot_geometry();

%not foolproof, but quite good for checking new templates
assert(rotor.check_feasibility())


%return
motor = RFmodel(dim, stator, rotor);

figure(2); clf; hold on; box on; axis equal;
motor.visualize('linestyle','-');

figure(3); clf; hold on;
motor.mesh.triplot([]);
%shaft = rotor.domains.get('Shaft_1');
shaft = rotor.domains(end-1);
motor.mesh.triplot(shaft.elements, 'r');

