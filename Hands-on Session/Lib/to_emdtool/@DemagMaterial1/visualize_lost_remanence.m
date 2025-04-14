function visualize_lost_remanence(this)
%visualize_lost_remanence Visualize lost remanance.
%
% Visualizes the amount of remanence flux density lost, elementwise,
% compared to the non-demagnetized case.

Bhere = min(this.Bmin, this.Bmin_cand);

Br_lost = this.Br_now - this.get_equivalent_Br(Bhere);
msh = this.domains(1).root();

msh_fill(msh, this.elements, Br_lost, 'linestyle', 'none');
colormap(jet);

end