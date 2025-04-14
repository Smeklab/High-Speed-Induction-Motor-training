classdef HSSPM < SPM1
    %HSSPM Flexible high-speed SPM rotor.
    %
    % A high-speed SPM rotor template with the following features:
    %   * Retaining sleeve
    %   * Circumferentially and axially segmented magnets
    %   * Optional eddy-current shield between the sleeve and the magnets
    %   * Optional shield between the magnets and the core
    %   * Shaft with massive eddies modelled (if material conductive)
    %   * Rotor core with massive eddies modelled (if material conductive)
    %   * Solid shaft only (if core material = shaft material)
    %
    % Dimensions:
    %   * Rout : rotor outer radius
    %   * Rin : shaft radius. 
    %   * h_sleeve : retaining sleeve thickness
    %   * hpm : PM thickness
    %   * number_of_magnets : total number of magnet segments in-plane.
    %   * magnet_height : axial length of magnet segments.
    %   * h_shield : below-magnets eddy-shield thickness. OPTIONAL.
    %   * h_shield_top : above-magnets eddy-shield thickness. OPTIONAL.
    %
    % Materials:
    %   * rotor_core_material : Core material
    %   * shaft_material : Shaft material. If equal to core material, a
    %   solid homogeneous shaft and no core is modelled.
    %   * magnet_material
    %   * msleeve : retaining sleeve material.
    %   * shield_material : shield material. OPTIONAL, only needed if
    %   shield(s) modelled.
    methods
        create_geometry(this)
    end
end