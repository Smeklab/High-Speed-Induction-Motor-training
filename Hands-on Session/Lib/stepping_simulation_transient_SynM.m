%Transient simulation for a synchronous machine.
%
% Notes:
%   * Using an equivalent circuit to get an estimate for the supply voltage
%   * It's often better to use the solve_quasistatic method for getting the
%   initial conditions than solve_harmonic

%operating point
rpm = dim.rpm;

%input freq for the rpm
f = rpm/60*dim.p;

%initializing problem
problem = MagneticsProblem.new(motor);

%computing estimate for the voltage supply with an equivalent circuit
eqcircuit = SynEquivalentCircuit.from_model(motor, 'problem', problem);
[~, ~, ed, eq] = eqcircuit.get_op(rpm, dim.Ttarget);
disp('Voltage estimate computed')


%interesting circuits
phase_circuit = stator.winding;
spec = stator.winding_spec;

problem = MagneticsProblem(motor);

%setting parameters
pars = SimulationParameters('f', f, 'N_periods', 2, ...
    'N_stepsPerPeriod', 200, 'silent', true);

%Use a hybrid time-stepping scheme between implicit Euler (alpha2 = 2.0)
%and trapezoidal rule (1.0)
pars.alpha2 = 1.2;

%setting a PWM voltage source
modulator = SpaceVectorModulator(dim.UDC, dim.fs);
Usource = VoltageSource( motor, modulator );
Usource.set_Udq( [ed; eq] );
phase_circuit.set_source('terminal voltage', Usource);

%solving harmonic
harmonic_solution = problem.solve_quasistatic(pars);
figure(5); clf; hold on; box on;
motor.plot_flux( harmonic_solution );
drawnow;

%Bag_plot; return


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
Idq = spec.dq(I, stepping_solution.angles);

figure(8); clf; hold on; box on; grid on;
plot(stepping_solution.ts, I);
plot(stepping_solution.ts, Idq, 'k');
xlabel('Time (s)');
ylabel('Current (A)');
title('Terminal current');

summary = motor.results_summary(stepping_solution, 'verbose', true);
