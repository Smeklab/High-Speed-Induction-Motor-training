function Br = remanence_flux_density_at_temperature(this, T, regular_operation, from_parent)
%remanence_flux_density_at_temperature Remanence flux density.%
%
% Br = remanence_flux_density_at_temperature(this, T) returns zero, as this
% method is called by the `MagneticsProblem.set_load_vector` method, to
% account for the non-demagnetizable magnet behaviour.
%
% Br = remanence_flux_density_at_temperature(this, T, true) returns the H=0
% intercept of the current-set BH curve (this.BH_table_now)
%
% Br = remanence_flux_density_at_temperature(this, T, true, true) used
% the behaviour inherited from <Material>.

if nargin < 3
    regular_operation = false;
end
if nargin < 4
    from_parent = false;
end
if regular_operation
    if from_parent
        Br = remanence_flux_density_at_temperature@Material(this, T);
    else
        Br = interp1(this.BH_table_now.H, this.BH_table_now.B , 0 );
    end
else
    Br = 0;
end
end