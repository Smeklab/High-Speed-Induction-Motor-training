%stepping_sim_dynamic Full transient simulation.

%operating point from harmonic analysis
rpm = dim.rpm;
slip = slip_int;

%input freq for the rpm
f = rpm/60*dim.p / (1-slip);


%interesting circuits
phase_circuit = stator.winding;
spec = stator.winding_spec;

%initializing problem
problem = MagneticsProblem.new(motor);

%setting parameters
pars = SimulationParameters('f', f, 'N_periods', 0.2, ...
    'N_stepsPerPeriod', 100, 'silent', true, 'slip', slip);
pars.alpha2 = 1.2;

if supply_mode == "current"
    %setting a current source
    Ipeak = sqrt(2)*Jrms * phase_circuit.conductor_area_per_turn_and_coil() * spec.a;
    Is = spec.xy(Ipeak*[0; 1], 2*pi*pars.f*pars.ts());
    phase_circuit.set_source('terminal current source', Is);
elseif supply_mode == "voltage"
    Uphase_peak = dim.ULL*sqrt(2/3);
    Usource = VoltageSource( motor );
    Usource.set_Udq( [Uphase_peak; 0] );
    phase_circuit.set_source('terminal voltage', @Usource.U);
else
    error('Invalid supply mode.')
end

%solving harmonic
harmonic_solution = problem.solve_harmonic(pars);
figure(5); clf; hold on; box on;
motor.plot_flux( harmonic_solution );
drawnow;


%solving stepping
stepping_solution = problem.solve_stepping(pars);

%plotting flux
figure(5); clf; hold on; box on;
motor.plot_flux( stepping_solution, 11);

%plotting torque
figure(6); clf; hold on; box on; grid on;
T = motor.compute_torque(stepping_solution);
plot(stepping_solution.ts, T);
xlabel('Time (s)');
ylabel('Torque (Nm)');


%plotting voltage and voltage space vector
E = phase_circuit.terminal_voltage(stepping_solution);
Edq = phase_circuit.phase_voltage(stepping_solution, 'output', 'space vector');
Edq_norm = colnorm( Edq );

figure(7); clf; hold on; box on; grid on;
plot(stepping_solution.ts, E', 'b');
plot(stepping_solution.ts, Edq_norm, 'k', 'linewidth', 2);
xlabel('Time (s)');
ylabel('Voltage (A)');
title('Terminal voltage and (phase) voltage vector amplitude');


%currents
I = phase_circuit.terminal_current(stepping_solution);
figure(8); clf; hold on; box on; grid on;
plot(stepping_solution.ts, I);
xlabel('Time (s)');
ylabel('Current (A)');
title('Terminal current');

%calculating copper losses
summary = motor.results_summary(stepping_solution, 'verbose', true);

Coat = rotor.circuits.get('Rotor_coat');

figure(11); clf; hold on; box on; drawnow;
Coat.losses(stepping_solution, true);
%Coat.losses(stepping_solution, true, 'plot_rms', true); %to plot rms
%Coat.losses(stepping_solution, true, 'steps', 150:198, 'Jlim', 1e8*[-1 1]);
colorbar;
clim(50e6*[-1 1])
axis equal tight;