%Example simple steady-state thermal simulation
%
% WARNING: The thermal analysis utilizes a coupled FEA model (for the
% cross-section) and a lumped-parameter thermal model (for the
% end-windings, out-of-plane heat transfer, housings, etc.). The
% lumped-part of the default model is very rudimentary; hence caution is
% adviced.

solution_to_use = stepping_solution;
summary_to_use = summary;


model = RFThermalModel.from_model(motor);


%adding some indicator nodes
n_bar_ave = AverageTempNode.from_domain('Rotor coat average', rotor.domains.get('Rotor_coat_1'));
model.add_node(n_bar_ave);


%modifying yoke-to-ambient heat transfer, net
model.housing_model.heat_transfer_coefficient_total = 500;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% adding axial airgap flow

model.airgap_model.node.name = 'Airgap (average)';

%adding fixed-temperature node for coolant inlet
airgap_node = model.airgap_model.node;
n_inlet = AmbientNode('Coolant inlet');
n_inlet.temperature = 40;
model.add_node(n_inlet);

%volumetric flow; assuming inlet at core center and flow towards DE and
%NDE, using average flow temperature for airgap temp (hence the second
%factor of 2)
v_est = 30; %axial velocity
Q_ax = 2*pi*dim.Rout*dim.delta * v_est * 2 * 2 ; 
qm_ax = Q_ax*ThermalConstants.air_density; %mass flow
conn_flow = FlowHeatSinkConnection(airgap_node, n_inlet);
conn_flow.coolant_mass_flow = qm_ax;
conn_flow.coolant_specific_heat = 1e3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Adding more detailed end-winding model

h_surf = 50; %heat transfer coeff of surface

%mean radius (shaft center to toroid center) and length of the toroid
R_toroid = stator.mean_slot_radius();
L_toroid = 2*pi*stator.mean_slot_radius()/dim.symmetry_sectors*2; %two ends considered here

%end volume node
n_EV = ThermalNode('End-space volume, average');
model.add_node(n_EV);

%legs of toroid
r_leg = sqrt(stator.slot_area()/pi); %equivalent radius of single leg
l_ew_tot = winding_spec.end_winding_length_per_conductor;
l_leg = l_ew_tot - 2*pi/dim.Qs*winding_spec.span*R_toroid; %length of single leg
l_leg_tot = dim.Qs/dim.symmetry_sectors*l_leg; %total length of all legs
A_leg_tot = l_leg_tot * winding_spec.layout_spec.slot_liner_length; %surface area of legs

%leg average temperature node
n_leg_average = model.winding_model.end_winding_node; %re-purposing existing node
n_leg_average.name = 'End-winding leg average';

%resistance from leg average to winding temp node at stack end(s)
leg_to_stack_end = n_leg_average.connections; %existing Connection between EW node and FEA solution
%resistivity per meter, for axial heat flux in the slots:
r_winding_ax = 1/(dim.Qs/dim.symmetry_sectors * ...
    stator.slot_area*winding_spec.filling_factor * ...
    model.winding_model.conductor_thermal_conductivity); 
leg_to_stack_end.R = l_leg/2 * r_winding_ax; %division by 2 as we have two sides

%leg surface node
n_leg_surface = ThermalNode('End-winding leg surface');
model.add_node(n_leg_surface);

%resistance from leg surface to end volume
R_leg_surf_to_fluid = 1 / (h_surf*A_leg_tot);
leg_surf_to_fluid = Node2NodeConnection(n_leg_surface, n_EV);
leg_surf_to_fluid.R = R_leg_surf_to_fluid;

%resistance from leg average to leg surface
R_leg_rad = 1 / (8*pi*l_leg_tot*model.winding_model.homogenized_conductivity);
leg_ave_to_surf = Node2NodeConnection(n_leg_average, n_leg_surface);
leg_ave_to_surf.R = R_leg_rad;

% Creating toroidal part:
%Nodes for the toroidal part
n_ew_toroid_average = ThermalNode('End winding toroid average');
n_ew_toroid_surface = ThermalNode('End winding toroid surface');
model.add_node(n_ew_toroid_surface);
model.add_node(n_ew_toroid_average);

%resistance from toroid average temp to surface
R_rad_ave = 1 / (8*pi*L_toroid*model.winding_model.homogenized_conductivity);
ew_ave_to_surf = Node2NodeConnection(n_ew_toroid_average, n_ew_toroid_surface);
ew_ave_to_surf.R = R_rad_ave;

%resistance from toroid average node to leg average node
toroid_to_leg = Node2NodeConnection(n_leg_average, n_ew_toroid_average);
toroid_to_leg.R = leg_to_stack_end.R * l_ew_tot / (l_ew_tot-l_leg);

%end-winding surface to ambient
r_toroid = winding_spec.overhang_length/2;
p_surf = 2*pi * r_toroid;
A_surf_eff = L_toroid*p_surf * 1.5;
R_surf_to_fluid = 1 / (h_surf*A_surf_eff);

%end-winding center, dependent node
n_ew_max = InterpolatingThermalNode('End-winding toroid center');
n_ew_max.nodes = [n_ew_toroid_average, n_ew_toroid_surface];
n_ew_max.coeffs = [2 -1];
model.add_node(n_ew_max);

%end-winding surface to end-space volume
ew_surf_to_fluid = Node2NodeConnection(n_ew_toroid_surface, n_EV);
ew_surf_to_fluid.R = R_surf_to_fluid;

%losses in legs and toroid
P_ew_model = summary.Phasewinding_loss_data.mean_EW_losses / dim.symmetry_sectors;%losses in thermal model
P_leg = P_ew_model * l_leg/l_ew_tot;
P_toroid = P_ew_model - P_leg;
n_leg_average.heat_source = P_leg;
n_ew_toroid_average = P_ew_model - P_ew_model;

%coolant input to end-volume
n_inlet_EV = InterpolatingThermalNode('Coolant inlet to end volume');
n_inlet_EV.nodes = [airgap_node n_inlet];
n_inlet_EV.coeffs = [2 -1];
model.add_node(n_inlet_EV);

%end-space volume, heat rejection to coolant, average
conn_flow_ag2EV = FlowHeatSinkConnection(n_inlet_EV, n_EV);
conn_flow_ag2EV.coolant_mass_flow = qm_ax;
conn_flow_ag2EV.coolant_specific_heat = 1e3;

%end-space coolant output
n_outlet_EV = InterpolatingThermalNode('Coolant outlet');
n_outlet_EV.nodes = [n_EV, n_inlet_EV];
n_outlet_EV.coeffs = [2 -1];
model.add_node(n_outlet_EV);

%removing old maximum-temp node
for n = model.nodes
    if n.name == "Phase winding end-winding maximum"
        n.name = '(Not used)';
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

model.set_magnetic_solution(solution_to_use, summary_to_use);




%solving
figure(1); clf; hold on; box on; axis equal;
model.plot_thermal_conductivity();
model.mesh.plot_nodes(model.matrices.n_free, 'ko')

figure(2); clf; hold on; axis equal;
msh_fill(model.mesh, [], model.element_heat_generation);
colorbar;


solution = model.solve_steadystate();
T = solution.raw_solution;

figure(4); clf;
solution.plot(); %caxis([60 120])

solution.display_info();

%checking airgap heat fluxes
%{
nag = model.airgap_model.node;

c1 = nag.connections(1);
c2 = nag.connections(2);

c1.get_flux(solution)
c2.get_flux(solution)
%}