function h = visualize_demag_curve(this, varargin)
%visualize_demag_curve Visualizes the given demag curve.
%
% h = visualize_demag_curve(this, varargin) visualizes the currently-used
% BH curve and the corresponding magnetization curve.


h = plot(this.BH_table_now.H, this.BH_table_now.B, varargin{:});

M = this.BH_table_now.B - this.BH_table_now.H * emdconstants.mu0;

plot(this.BH_table_now.H, M);

legend('B', 'J')
xlabel('Field strength (A/m)')
ylabel('(T)')



end