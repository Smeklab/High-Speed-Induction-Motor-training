classdef InterpolatingThermalNode < ThermalNode
    %InterpolatingThermalNode Linearly-dependent node.
    %
    % The temperature of an InterpolatingThermalNode is fixed to a linear
    % combination of the temperatures of one or more other nodes in the
    % thermal model as follows:
    %
    % T(this) = c(1)*T(n(1)) + c(2)*T(n(2)) + ...
    %
    % where 
    % c = this.coeffs, real values
    % n = this.nodes, <ThermalNode> objects.
    properties
        %nodes Other nodes.
        %
        % An array of 1 or more <ThermalNode> objects that define the
        % temperature of `this`.
        nodes

        %coeffs Array of multipliers.
        coeffs
    end
    methods
        function matrices = get_matrices(this)
            
            matrices = get_matrices@ThermalNode(this);

            %initial stuff
            matrices.S_node2FEA = 0*matrices.S_node2FEA;
            matrices.S_node = 0*matrices.S_node;
            matrices.P_node = 0*matrices.P_node;

            Nn = this.parent_model.number_of_network_nodes;
            S = zeros(Nn, Nn);
            S(this.id, this.id) = -1;
            S(this.id, [this.nodes.id]) = this.coeffs;
            matrices.S_node = S;
        end
    end
end