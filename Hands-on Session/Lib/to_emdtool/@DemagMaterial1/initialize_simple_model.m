function initialize_simple_model(this, problem)
%initialize_simple_model Initialize simple demagnetization model.
%
% initialize_simple_model(this, temperature) to specify a temperature.
%
% initialize_simple_model(this, problem) to parse the temperature from the
% <MagneticsProblem> object.
%
% The simple model uses the remanence flux density and intrinsic coercivity
% for the given temperature, with the methods inherited from <Material>.
% The magnetization curve `J(H)` is then assumed to decay exponentially to
% zero at `J(-HcJ)`, with the decay constant `-1/this.H0`.
%
% The corresponding flux density is then obtained with
%   `B(H) = mu0*H + J(H)`.
%
% These results are then used to initialize the BH interpolation table with
% `this.set_symmetric_BH_table_from_BH_data`.


component = this.parent;
if isa(problem, 'MagneticsProblem')
    T = problem.get_component_property(component, 'temperature');
else
    T = problem;
end

Br = this.remanence_flux_density_at_temperature(T, true, true);
HcJ = this.intrinsic_coercivity_at_temperature(T);


mur = this.material_properties.mur;
H0 = this.H0;

Hs = [linspace(-HcJ , 0, 100), -HcJ] ;
Hs = unique(Hs);

mult = (1 - exp(-1/H0*abs(Hs+HcJ)));
mult = mult * 1 / (1-exp(-1/H0*HcJ));

Ms = (Br + ...
    emdconstants.mu0*(mur-1)*Hs).*mult;

B = emdconstants.mu0*Hs + Ms;



data = struct();
data.B = B;
data.H = Hs;

%M2 = data.B - mu*data.H

this.set_symmetric_BH_table_from_BH_data(data);


end