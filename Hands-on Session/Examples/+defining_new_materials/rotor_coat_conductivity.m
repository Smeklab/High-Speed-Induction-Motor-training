%Example on changing scalar material properties


dim_base; %initial dimensions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%adjusting rotor coat material properties

mcoat = Material.create(18); %begin from built-in copper
mcoat.material_properties.sigma = 40e6; %conductivity, S/m
mcoat.material_properties.alpha_sigma = 0.002; %resistivity temp coeff, 1/K
mcoat.name = 'Custom coat material'; %Not needed, but good practice so that we don't forget

dim.rotor_coat_material = mcoat;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finalizing model

stator = Stator(dim);
rotor = CoatedRotor(dim);

figure(1); clf; hold on; box on; axis equal;
stator.plot_geometry();
rotor.plot_geometry();

return

%for faster analysis
rotor.scale_mesh_density(2, 'lcar_max', 15e-3);



motor = RFmodel(dim, stator, rotor);