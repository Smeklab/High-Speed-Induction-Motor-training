%stepping_sim_dynamic Full transient simulation.

%operating point
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
pars = SimulationParameters('f', f, 'N_periods', 0.5, ...
    'N_stepsPerPeriod', 200, 'silent', true, 'slip', slip);
pars.alpha2 = 1.2;

%setting a current source
%%{
Ipeak = sqrt(2)*Jrms * phase_circuit.conductor_area_per_turn_and_coil() * spec.a;
Is = spec.xy(Ipeak*[0; 1], 2*pi*pars.f*pars.ts());
phase_circuit.set_source('terminal current source', Is);
%}



%solving harmonic
harmonic_solution = problem.solve_harmonic(pars);
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
figure(8); clf; hold on; box on; grid on;
plot(stepping_solution.ts, I);
xlabel('Time (s)');
ylabel('Current (A)');
title('Terminal current');

%calculating copper losses
%[P_Cu, data_pcu] = phase_circuit.losses( stepping_solution, false );


summary = motor.results_summary(stepping_solution, 'verbose', true);

Coat = rotor.circuits.get('Rotor_coat');

figure(11); clf; hold on; box on; drawnow;
Coat.losses(stepping_solution, true);
%Coat.losses(stepping_solution, true, 'plot_rms', true);
%Coat.losses(stepping_solution, true, 'steps', 150:198, 'Jlim', 1e8*[-1 1]);
colorbar;
clim(50e6*[-1 1])
axis equal tight;

return

figure(12); clf; hold on; box on;
pcoat = summary.Rotor_coat_loss_data.conductor_loss_waveform;
plot(summary.timestamps, pcoat)

pcoat_for_fft = pcoat((pars.N_stepsPerPeriod):end);
yloss = fft(pcoat_for_fft) * 2 / size(pcoat_for_fft,2);
yloss(1) = yloss(1)/2;
fstep = 1/(pars.N_periods-1);

Nh = 100;
figure(13); clf; hold on; box on; grid on;
title('Coat losses spectrum')
bar((0:Nh)*fstep,  abs(yloss(1:(Nh+1))) )


Js = [summary.Rotor_coat_loss_data.elementwise_current_density_array{:}];

ns_coat = unique(motor.mesh.t(:, Coat.conductors.domains.elements));
[~, inds] = ismember(unique(rotor.edges.n_ag(:)), ns_coat);

k = inds(15);

figure(15); clf; hold on; box on; grid on;
plot(Js(k,:))


Pj_for_fft = Js(k, (pars.N_stepsPerPeriod):end);
y = fft(Pj_for_fft) * 2 / size(Pj_for_fft,2);
y(1) = y(1)/2;
fstep = 1/(pars.N_periods-1);

figure(16); clf; hold on; box on; grid on;
bar((1:Nh)*fstep,  abs(y(2:(Nh+1))) )