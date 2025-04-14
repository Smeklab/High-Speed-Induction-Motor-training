classdef DemagMaterial1 < Material
    %DemagMaterial1 Simple demagnetizable magnet material model.
    %
    % The class utilizes a simple demagnetization model based on given
    % material data. The demagnetization behaviour along the material axis
    % is defined as follows:
    %   * A demagnetization curve of type (H, B) is given by the user, for
    %   the temperature in question
    %       * This is set to `this.BH_table_now`
    %   * Material permeability (absolute, not relative) is set by the
    %   user.
    %   * For each element, the B(H) behaviour follows a linear
    %   relationship with the slope `this.mu`, going through the point
    %   (Bmin, Hmin), where `Bmin` is the lowest flux density encountered
    %   by the element so far, and `Hmin` is the corresponding field
    %   strength on the given demagnetization curve.
    %
    % Alternatively, a simple parametric demagnetization model can be used
    % by setting `this.use_simple_model = true`. 
    %
    % For the last bullet, the `get_equivalent_Br` method is used,
    % returning the `H=0` intersect of the current BH curve followed, for
    % each element.
    %
    % BH behaviour on the axis perpendicular to the magnetization direction
    % follows a linear relationship with the slope `this.mu_now`.
    %
    % See
    %   * `this.evaluate_H_vector`
    %   * `this.evaluate_magnetization_axis_H`
    %   * `this.get_equivalent_Br`
    %
    % Notes:
    %   * The default demagnetization evaluation functions
    %   (maximum_demag_field function, demag_check script) don't work with
    %   this class.
    %   * When creating geometries, a deep copy of this material class is
    %   generally created. Thus, changing the state of the
    %   originally-defined material object has no effect on simulation
    %   results; you must first do e.g. the following
    %       * `mat_new = rotor.materials.get(mat_name)`
    %       * `mat_new.ignore_demag = true`
    properties
        %retain_state Retain state between successive simulations?
        %
        % Default `false`, in which case the state (`this.Bmin`) is reset
        % to `this.Br_now` whenever the `.set_step` method is called with a
        % step index smaller than `this.step`.
        retain_state = false

        %ignore_demag Ignore demagnetization model.
        %
        % When true, the default linear approximation is used.
        ignore_demag = false

        %step Index of the current/latest time-step.
        step = inf;

        %use_simple_model Use simple demagnetization model.
        %
        % Use a simple single parameter exponential demagnetization model,
        % with no BH curve data needed. Defaults to false.
        %
        % See `this.initialize_simple_model`.
        use_simple_model = false

        %H0 Decay constant for the simple model.
        %
        % See `this.initialize_simple_model`. Directly influences the
        % squareness of the magnetic polarization curve. In (m/A).
        H0 = 50e3
    end
    %demag-model-specific properties
    properties
        %BH_table_now Demagnetization curve to follow.
        %
        % A structure with the fields `H` and `B` containing lookup values
        % for the current demagnetization curve to follow.
        BH_table_now = struct()

        %Br_now Current non-demagnetized remanence flux density.
        %
        % Used by the demag model to clamp extrapolated values.
        Br_now

        %mu_now Current permeability.
        %
        % Used as the slope of the recoil curve.
        mu_now
        
        %Bmin Elementwise lowest flux density.
        %
        % Lowest magnetization-direction flux density encountered so far.
        %
        % Note: only set when `this.set_step` is called, thus ignoring the
        % latest time-step by default.
        Bmin

        %Bmin_cand Candidate minimum flux density.
        %
        % Used during the newest time-step.
        Bmin_cand
        
        %remanence_direction_angles Elementwise remanence direction.
        remanence_direction_angles
    end
    methods
        [H, dHdB] = differential_reluctivity(this, B2, harmonic)
        H = evaluate_H_vector(this, Bvector, update_state)
        H = evaluate_magnetization_axis_H(this, B, update_state)
        Br = get_equivalent_Br(this, B)
        
        parse_element_remanence_directions(this)

        set_symmetric_BH_table_from_BH_data(this, data)
        Br = remanence_flux_density_at_temperature(this, T, regular_operation, varargin)

        [B_plot, H_plot] = visualize_BH(this, Bampls, varargin)
        visualize_lost_remanence(this)

        initialize_simple_model(this, problem)
    end
    
    methods
        function this = from_material(this_dummy, mat)
            this = feval(class(this_dummy)); %to work with subclasses, too
            MaterialBase.copy_basic_properties(this, mat);
            this.mu_now = emdconstants.mu0 * ...
                this.material_properties.mur;
        end
        
        function set_step(this, kstep, t, varargin)
            %set_step Set new time-step.
            %
            % set_step(this, kstep, t, varargin)
            
            if kstep < this.step
                %(re-)initialization
                if this.retain_state && numel(this.Bmin) == numel(this.elements)
                else
                    this.Bmin = ones(1, numel(this.elements)) * this.Br_now;
                    this.Bmin_cand = ones(1, numel(this.elements)) * this.Br_now;
                end
            elseif kstep > this.step
                this.Bmin = min(this.Bmin, this.Bmin_cand);
            end
            this.step = kstep;
        end
        
        function m = clear_copy(this)
            %basic copy stuff
            m = feval(class(this)); %to work with subclasses, too            
            MaterialBase.copy_basic_properties(m, this);
        end
    end
end