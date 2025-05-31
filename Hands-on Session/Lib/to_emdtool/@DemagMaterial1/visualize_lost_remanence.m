function visualize_lost_remanence(this)
%visualize_lost_remanence Visualize lost remanence.
%
% Visualizes the amount of remanence flux density lost, elementwise,
% compared to the non-demagnetized case.
%
% The 'lost remanence' is defined as the difference between the datasheet
% (or initial, non-degraded)
% remanence flux density at the current temperature, and the actual
% elementwise remanence flux density (i.e. B(0) in the direction of the
% magnetization axis).

Bhere = min(this.Bmin, this.Bmin_cand);

Br_lost = this.Br_now - this.get_equivalent_Br(Bhere);
msh = this.domains(1).root();

msh_fill(msh, this.elements, Br_lost, 'linestyle', 'none');
colormap(jet);

end