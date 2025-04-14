function H = evaluate_H_vector(this, B2, update_state)
%evaluate_H_vector Evaluates the H(B) vector relationship.
%
% H = evaluate_H_vector(this, Bvector, update_state) evaluates the H(B) vector
% relationship by decomposing Bvector into components parallel and
% perpendicular to the elementwise remanence direction. The perpendicular
% component follows a linear relationship with the slope `this.mu_now`,
% while the parallel component is evaluated with 
% `evaluate_magnetization_axis_H(this, update_state)`
%
% The results are then rotated back to the global frame.

as = this.remanence_direction_angles;

%remanence-axis B and perpendicular component
Bm = B2(1,:).*cos(as) + ...
    B2(2,:).*sin(as);
Bd = -B2(1,:).*sin(as) + ...
    B2(2,:).*cos(as);

Hd = Bd / this.mu_now;

%solving Hm
Hm = this.evaluate_magnetization_axis_H(Bm, update_state);

%rotating to actual frame
H = [Hm.*cos(as) - Hd.*sin(as);
    Hm.*sin(as) + Hd.*cos(as)];

end