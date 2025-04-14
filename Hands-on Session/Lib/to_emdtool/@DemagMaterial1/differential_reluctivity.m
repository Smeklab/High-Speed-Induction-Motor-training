function [H, dHdB] = differential_reluctivity(this, B2, harmonic)
%differential_reluctivity (H, dHdB) function.
%
% Reverts to the superclass implementation in case of harmonic analysis or
% if `this.ignore_demag` is set to true.
%
% Otherwise, calls `this.evaluate_H_vector` to obtain H, and numerically
% differentiates to obtain dHdB by calling the same method

if harmonic || this.ignore_demag
    H = this.evaluate_H_vector(B2, false);
    [~, dHdB] = differential_reluctivity@Material(this, B2, harmonic);
    return
end
H = this.evaluate_H_vector(B2, true);

tol = 1e-6;
Btemp = B2;
Btemp(1,:) = Btemp(1,:) + tol;
H1 = this.evaluate_H_vector(Btemp, false);

Btemp = B2;
Btemp(2,:) = Btemp(2,:) + tol;
H2 = this.evaluate_H_vector(Btemp, false);

dHdB = [H1-H; H2-H]/tol;

end