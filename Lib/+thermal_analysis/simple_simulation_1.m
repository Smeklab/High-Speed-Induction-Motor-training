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


%adding an indicator node
n_coat_ave = AverageTempNode.from_domain('Rotor coat average', rotor.domains.get('Rotor_coat_1'));
model.add_node(n_coat_ave);


% adding axial airgap flow

%adding fixed-temperature node for coolant inlet
n_inlet = AmbientNode('Coolant_inlet');
n_inlet.temperature = 40;
model.add_node(n_inlet);

v_est = 12; %axial velocity
%volumetric flow; assuming inlet at core center and flow towards DE and NDE
Q_ax = 2*pi*dim.Rout*dim.delta * v_est * 2 ; 
qm_ax = Q_ax*ThermalConstants.air_density; %mass flow
conn_flow = FlowHeatSinkConnection(model.airgap_model.node, n_inlet);
conn_flow.coolant_mass_flow = qm_ax;
conn_flow.coolant_specific_heat = 1e3;

%setting solution to use
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

%running simple sensitivity analysis
disp(' ')
disp('Results from simple sensitivity analysis:')
model.compute_sensitivity(solution);

return
%checking airgap heat fluxes
nag = model.airgap_model.node;

c1 = nag.connections(1);
c2 = nag.connections(2);

c1.get_flux(solution)
c2.get_flux(solution)