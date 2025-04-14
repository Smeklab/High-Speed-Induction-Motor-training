%Compute torque curve vs. slip, using harmonic analysis.

%rpm, slips
f = dim.rpm/60;

%slips = linspace(1, 5, 10)*1e-2; %good values depend on the model, ofc
slips = linspace(0.1, 1, 10)*1e-2; %good values depend on the model, ofc


%initializing
problem = MagneticsProblem.new( motor );
phase_circuit = stator.winding;

%setting current supply
%%{
Jrms = dim.Jrms; %rms current density for current supply, if used
Imax = sqrt(2)*Jrms * phase_circuit.conductor_area_per_turn_and_coil();
Is = dim.stator_winding.xy([Imax;0]);
phase_circuit.set_source('uniform coil current', Is);
%}

%setting voltage supply
%{
Uphase_peak = 420*sqrt(2/3);
Usource = VoltageSource( motor );
Usource.set_Udq( [Uphase_peak; 0] );
phase_circuit.set_source('terminal voltage', @Usource.U);
%}

pars = SimulationParameters('f', f, 'slip', slips);

harmonic_solutions = problem.sweep_harmonic( pars );

Ts = zeros(1, numel(slips));
for k = 1:numel(slips)
    T = motor.compute_torque( harmonic_solutions(k) );
    Ts(k) = T(1);
end

figure(4); clf; hold on; box on; axis equal;
[~, ind] = max(Ts);
motor.plot_flux( harmonic_solutions(ind) );
title('Flux density at maximum torque')
%caxis([0, 2.2]);

figure(5); clf; hold on; box on; grid on;
title('Torque vs slip')
plot(slips*1e2, Ts, 'bo-');

xlabel('Slip (%)')
ylabel('Torque (Nm)')

slip_int = interp1(Ts, slips, dim.Ttarget);
n_int = interp1(Ts, 1:numel(slips), dim.Ttarget, 'nearest');

%power curve
figure(6); clf; hold on; box on; grid on;
title('Shaft power vs slip')
fms = pars.f*(1-slips) / motor.dimensions.p;
Ps = 2*pi*fms.*Ts;
plot(slips*1e2, Ps*1e-3);

figure(8); clf; hold on; box on; axis equal;
[~, ind] = max(Ts);
motor.plot_flux( harmonic_solutions(n_int) );
title('Flux density at target torque')
%caxis([0, 2.2]);



xlabel('Slip (%)');
ylabel('Shaft power (kW)');

figure(7); clf; hold on; box on; grid on;
motor.plot_airgap_flux_density(harmonic_solutions(n_int), 1, 'plot_spectrum', true);
%winding_spec.plot_winding_factors(1:30);
