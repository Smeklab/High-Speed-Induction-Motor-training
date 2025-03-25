%Compute torque curve vs. slip, using harmonic analysis.

%rpm, slips
f = dim.rpm/60;

%Control flag for simulation supply mode. Only used outside core-EMDtool, so not
%standard naming or anything.
%
% NOTE: The supply mode will also influence the torque-slip behaviour.
supply_mode = "voltage";

%slip range to analyse - good values depend on the design etc
slips = linspace(0.1, 1, 10)*1e-2;
%slips = linspace(0.1, 3, 10)*1e-2; 


%initializing
problem = MagneticsProblem.new( motor );
phase_circuit = stator.winding;

if supply_mode == "current"
    %setting current supply
    Jrms = dim.Jrms; %rms current density for current supply, if used
    Imax = sqrt(2)*Jrms * phase_circuit.conductor_area_per_turn_and_coil();
    Is = dim.stator_winding.xy([Imax;0]);
    phase_circuit.set_source('uniform coil current', Is);
elseif supply_mode == "voltage"
    Uphase_peak = dim.ULL*sqrt(2/3);
    Usource = VoltageSource( motor );
    Usource.set_Udq( [Uphase_peak; 0] );
    phase_circuit.set_source('terminal voltage', @Usource.U);
else
    error('Invalid supply model.')
end

%simulation parameters
pars = SimulationParameters('f', f, 'slip', slips);

%solving
harmonic_solutions = problem.sweep_harmonic( pars );

%quick postprocessing of details
Ts = zeros(1, numel(slips));
ag_flux_densities = zeros(1, numel(slips));
for k = 1:numel(slips)
    T = motor.compute_torque( harmonic_solutions(k) );
    Ts(k) = T(1);

    %computing airgap flux density
    gap = motor.airgap.airgaps(1);
    Bdata = gap.compute_airgap_flux_density_data(harmonic_solutions(k), 1);
    %fundamental from FFT data
    ag_flux_densities(k) = abs(Bdata.Bn_spectrum(1+dim.p)); 
end

%interpolating rated slip
slip_int = interp1(Ts, slips, dim.Ttarget, 'linear', 'extrap');
n_int = interp1(Ts, 1:numel(slips), dim.Ttarget, 'nearest', 'extrap');

%plotting flux density
figure(4); clf; hold on; box on; axis equal;
title('Flux density at maximum torque')
[~, ind] = max(Ts);
motor.plot_flux( harmonic_solutions(ind) );

%torque vs slip curve
figure(5); clf; hold on; box on; grid on;
title('Torque vs slip')
plot(slips*1e2, Ts, 'bo-');
xlabel('Slip (%)')
ylabel('Torque (Nm)')
yline(dim.Ttarget)
xline(slip_int*1e2, 'm')
legend('Torque curve', 'Torque target', 'Rated slip (estimate)')


%power curve
figure(6); clf; hold on; box on; grid on;
title('Shaft power vs slip')
fms = pars.f*(1-slips) / motor.dimensions.p;
Ps = 2*pi*fms.*Ts;
plot(slips*1e2, Ps*1e-3);

figure(7); clf; hold on; box on; axis equal;
motor.plot_flux( harmonic_solutions(n_int) );
xlabel('Slip (%)');
ylabel('Shaft power (kW)');
title('Flux density closest to target torque')

figure(8); clf; hold on; box on; grid on;
title('Airgap flux density closest to target torque')
motor.plot_airgap_flux_density(harmonic_solutions(n_int), 1, 'plot_spectrum', true);

figure(9); clf; hold on; box on; grid on;
title('Airgap flux density vs slip')
plot(slips*1e2, ag_flux_densities, 'bo-')
xlabel('Slip (%)')
ylabel('Airgap flux density fundamental (T)')
yline(dim.B1_ag, 'r');
xline(slip_int*1e2, 'k')
legend('Flux density', 'Target flux density', 'Rated slip (estimate)')
