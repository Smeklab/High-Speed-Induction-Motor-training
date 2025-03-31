function visualize_strand_layout(this, varargin)
%visualize_strand_layout Visualize strand-slot layout.
%
% visualize_strand_layout(this) visualizes the locations of each strand in
% in a phase in the slot. Each turn is colored by its corresponding color.
%
% visualize_strand_layout(this, varargin) supports the following key-value
% argumemts:
%   * turns_to_plot : number of turn(s) to plot. Defaults to 'all'.
%   * plot_numbers : plot number of each wire-in-hand. Defaults to true.
%   * phase_to_plot : which phase to plot. Defaults to 1.

DEFAULTS = struct();
DEFAULTS.turns_to_plot = 'all';
DEFAULTS.plot_numbers = true;
DEFAULTS.phase_to_plot = 1;



spec = this.winding_spec;
stator = spec.geometry;
Qs = spec.number_of_slots;
dim = stator.dimensions;


args = parse_defaults(DEFAULTS, varargin{:});
turns_to_plot = args.turns_to_plot;
plot_text = args.plot_numbers;
phase_to_plot = args.phase_to_plot;


wires_in_slot = spec.N_series * spec.N_layers * spec.wires_in_hand;
wires_in_bundle = spec.wires_in_hand;
N_bundles = spec.N_series * spec.wires_in_hand / wires_in_bundle;

if string(turns_to_plot) == "all"
    bundles_to_plot = 1:N_bundles;
else
    bundles_to_plot = turns_to_plot;
end


colors = cell(1, N_bundles);
L = spec.loop_matrix();

wire_inds = (phase_to_plot-1)*spec.wires_in_hand + (1:spec.wires_in_hand);

L = L(1:(Qs*wires_in_slot/dim.symmetry_sectors), wire_inds);
[J, I] = find(L');

ri = 0;
bundle_ind_prev = -1;
for k = 1:numel(I)
    cond = stator.winding.conductors(I(k));

    bundle_ind = mod(floor(ri/spec.wires_in_hand), N_bundles) + 1;
    ri = ri+1;

    if ~ismember(bundle_ind, bundles_to_plot)
        continue;
    end

    %hacking to get a new nice color
    if isempty(colors{bundle_ind})
        h = plot(nan,nan); %plots nothing visible
        colors{bundle_ind} = h.Color;
    end

    cond.visualize(colors{bundle_ind});
    
    if plot_text
        coil_direction = sign(L(I(k), J(k)));
        if coil_direction > 0
            txt_to_plot = num2str(J(k));
        else
            txt_to_plot = ['-' num2str(J(k))];
        end
    
        text(cond.position(1), cond.position(2), txt_to_plot, ...
            'VerticalAlignment','middle', 'HorizontalAlignment','center');
    end
end

