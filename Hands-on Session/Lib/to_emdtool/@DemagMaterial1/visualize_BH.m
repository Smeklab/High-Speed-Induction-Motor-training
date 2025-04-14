function [B_plot, H_plot] = visualize_BH(this, Bampls, varargin)
%visualize_BH Visualize demagnetization/BH behaviour.
%
% [Bs_test, Hs_test] = visualize_BH(this, Bampls) draws (H, B) traces
% (numel(Bampls) in total) (magnetization axis only) as B is changed 
% linearly from Br to Bampls(k) and back.


%state dump
step_orig = this.step;
Bmin_orig = this.Bmin;
Bmin_cand_orig = this.Bmin;
elements_orig = this.elements;


mat = this;

Nsteps = 500;
Br = this.remanence_flux_density_at_temperature(20, true);
this.Br_now = Br;


Bplot = zeros(numel(Bampls), Nsteps);
Hplot = zeros(numel(Bampls), Nsteps);

for kb = 1:numel(Bampls)
    Bmin = Bampls(kb);
    B_plot = interp1([0 0.5 1], [Br, Bmin, Br], linspace(0, 1, Nsteps));
    H_plot = zeros(1, numel(B_plot));

    %looping
    mat.Bmin = inf;
    mat.step = inf;
    mat.elements = 1;
    for k = 1:numel(B_plot)
        mat.set_step(k);
        H_plot(k) = mat.evaluate_magnetization_axis_H(B_plot(k), true);
    end
    
    Bplot(kb, :) = B_plot;
    Hplot(kb, :) = H_plot;
end

plot(this.BH_table_now.H/1e3, this.BH_table_now.B, 'k', 'linewidth', 2)
plot(Hplot'/1e3, Bplot');


xlabel('Field strength (kA/m)');
ylabel('Flux density (T)');

ax = gca;
ax.XLim(2) = 0;

%returning state
this.step = step_orig;
this.Bmin = Bmin_orig;
this.Bmin = Bmin_cand_orig;
this.elements = elements_orig;

end