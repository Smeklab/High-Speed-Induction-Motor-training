function H = evaluate_magnetization_axis_H(this, B, update_state)
%evaluate_magnetization_axis_H Evaluate H on the magnetization direction.
%
% H = evaluate_magnetization_axis_H(this, B, update_state) returns the
% magnetization-axis H following the linear relationship
% `H = (B - Br_eq) / this.mu_now`
% where
% `Br_eq = this.get_equivalent_Br(B);`
%
% If `update_state == true`, `this.Bmin_cand` is updated to `B`.

if update_state
    this.Bmin_cand = B;
end

Br = this.get_equivalent_Br(B);

%getting H from B = Br + mu*H
H = (B - Br) / this.mu_now;

end