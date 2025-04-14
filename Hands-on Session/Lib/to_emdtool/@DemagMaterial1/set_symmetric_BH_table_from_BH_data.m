function set_symmetric_BH_table_from_BH_data(this, data)
%set_symmetric_BH_table_from_BH_data Sets a symmetric BH table to follow.
%
% set_symmetric_BH_table_from_BH_data(this, data) parses and sets 
% `this.BH_table_now` from the given BH curve, a structure `data` with the
% fields `B` and `H`.
%
% The method first computes the magnetization M from the given data, then
% creates a new magnetization curve that is anti-symmetric with respect to
% the intrinsic coercivity, and then computes the corresponding B values.

mu = emdconstants.mu0;
M = data.B - mu*data.H;

Hs = data.H;

inds_to_use = diff(M) ~= 0;
if min(M(inds_to_use)) > 0
    warning('The given curve does not extend to small-enough H. Extrapolation is performed.')
end
Hr0 = interp1(M(inds_to_use), Hs(inds_to_use), 0, 'linear', 'extrap');


%symmetrizing curve
inds = M > 0;
dH = Hs(inds) - Hr0;

Br_sym = [-fliplr(M(inds)) 0 M(inds)];
Hr_sym = [Hr0-fliplr(dH) Hr0 Hs(inds)];

[~, inds_unique] = unique(Hr_sym);
this.BH_table_now.H = Hr_sym(inds_unique);
this.BH_table_now.B = Br_sym(inds_unique) + mu*Hr_sym(inds_unique);



end