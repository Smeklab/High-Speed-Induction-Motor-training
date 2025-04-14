%critical bending speed
m = rotor.mass;
d = 2*(dim.Rout-dim.h_coat);
d_in = 0;

E = 190e9;
l = dim.leff + 2*dim.stator_winding.overhang_length*1.3;

I = pi*d^4 / 64; %second moment of area
I_in = pi * (d_in)^4 / 64; %shaft hole;
I = I - I_in;

%K = 6*E*I / (l/2)^3;
K = 6*E*I / (l/2)^3;

%first bending frequency
fn = sqrt(K / m) / (2*pi);
rpm_n = fn * 60;

fprintf('Natural rpm: %.0f\n', rpm_n)

figure(2); clf; hold on; box on; axis equal;
motor.visualize_axial()
bearing_line = xline(l/2*[-1 1], 'b', 'LineWidth',2);
legend(bearing_line(1), 'Assumed bearing position')

%Wiart equation from Pyrhonen's book
n = 1; %order of bending mode
k = 1; %safety factor
omega = rpm_n/60*2*pi;
rho = 7900; %density
S = pi*dim.Rout^2; %surface area
lmax_sq = n * pi^2 / (k*omega) * sqrt(E*I/(rho*S));
lmax = sqrt(lmax_sq)