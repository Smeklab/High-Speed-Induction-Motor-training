%calculate_no_load_flux_density 
% No-load flux density solution and plot. Intended for PM machines

problem = MagneticsProblem(motor);

%setting zero current density as source
phase_circuit = stator.winding;
phase_circuit.set_source('uniform coil current', zeros(stator.winding_spec.phases, 1)); %EXPLAIN

%rotor angle to analyse
pars = SimulationParameters('rotorAngle', 0);
%pars = SimulationParameters('rotorAngle', pi/8);

%solving
static_solution = problem.solve_static(pars);

%plotting
figure(5); clf; hold on; box on;
motor.plot_flux(static_solution);
title('No-load flux density');


figure(6); clf; hold on; box on; grid on;
motor.plot_airgap_flux_density(static_solution);
%Bag_plot;

