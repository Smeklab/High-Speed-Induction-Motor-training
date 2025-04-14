function this = init_for_problem(this, problem)

if this.use_simple_model
    this.initialize_simple_model(problem);
end

this.Br_now = remanence_flux_density_at_temperature(this, 0, true);

this.parse_element_remanence_directions();



end