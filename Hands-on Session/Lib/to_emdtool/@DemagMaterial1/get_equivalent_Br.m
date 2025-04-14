function Br = get_equivalent_Br(this, B)
%get_equivalent_Br Equivalent remanence.
%
% Br = get_equivalent_Br(this, B) returns the H=0 intercept of the
% elementwise (H,B) trace.
%
% The value is computed as
%   * `Bmin = min(this.Bmin, B);`
%   * `Hmin` is interpolated from `this.BH_table_now.H` with `Bmin` as
%   input
%   * `Br = Bmin - this.mu_now*`Hmin;`
%   * Values outside the data range of `this.BH_table_now.B` are clamped to
%   `+/- this.Br_now`
%
% If `this.ignore_demag` is true, `this.Br_now` is returned instead.

%actual H
if this.ignore_demag
    Br1 = this.Br_now;
    Br = repmat(Br1, 1, numel(this.Bmin_cand));
    return
end
B_to_use = min(this.Bmin, B);

Hactual = interp1(this.BH_table_now.B, this.BH_table_now.H, B_to_use, 'linear', nan);

%Br corresponding to linear behaviour
%Bmin = Br + mu*Hactual
Br = B_to_use - this.mu_now*Hactual;

%out-of_bounds values clamped to datasheet-like Br
Br(B_to_use < min(this.BH_table_now.B)) = -this.Br_now;
Br(B_to_use > max(this.BH_table_now.B)) = this.Br_now;


end