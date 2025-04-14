function create_geometry(this)

%Mostly copy-pasted from the MassivePM template 
% see open MassivePM.create_geometry
%
% Scroll down to see the new part between the triple %%%%%%%-lines

dimensions = this.dimensions;

%calculating and parsing dimensions
Rout = dimensions.Rout;
h_sleeve = dimensions.h_sleeve;

if isfield(dimensions, 'h_shield')
    h_shield = dimensions.h_shield;
else
    h_shield = 0;
end

apole = pi / dimensions.p;

%some radii
r_sleeve_in = Rout - h_sleeve;
r_mag_out = r_sleeve_in - h_shield;


%characteristic lengths
if ~isfield(dimensions, 'delta')
    dimensions.delta = abs(dim.Sin - dim.Rout);
end
lcar_ag = Airgap.characteristic_length( this );
lcar_shield = h_shield/3;
lcar_sleeve = h_sleeve / 3;
lcar_mag = r_mag_out / 5;
lcar_mag_out = lcar_sleeve;

if isfield(dimensions, 'Rin')
    has_shaft = true;
    if isfield(dimensions, 'lcar_shaft')
        lcar_shaft = dimensions.lcar_shaft;
    else
        lcar_shaft = lcar_mag*2;
    end
else
    has_shaft = false;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%initializing materials, domains, surfaces, etc.

%parsing magnet material
if strcmpi(dimensions.magnet_material, 'custom')
    mmag = CustomMaterial( 'name', dimensions.magnet_material, 'Br', dimensions.Br, ...
        'mur', dimensions.mur, ...
        'sigma', dimensions.sigma_PM, 'alpha_sigma', dimensions.alpha_sigma_PM);
else
    mmag = Material.create( dimensions.magnet_material );
end

%other materials
msleeve = Material.create( dimensions.sleeve_material );
this.add_material(mmag, msleeve);


%surfaces and domains
ssleeve = Surface('sleeve');
Sleeve = Domain('Sleeve', msleeve, ssleeve);
this.add_domain(Sleeve);

%creating circuits
Magnet = Domain('Magnet', mmag);
Magnet.remanence_direction = pi/2;
this.add_domain(Magnet);
MagnetCircuit = SheetCircuit('Magnet');
MagnetCircuit.add_conductor( SolidConductor(Magnet) );
this.add_circuit(MagnetCircuit);

if msleeve.electrical_conductivity > 0
    SleeveCircuit = SheetCircuit('Sleeve');
    SleeveCircuit.add_conductor(SolidConductor(Sleeve));
    this.add_circuit(SleeveCircuit);
end

%shield material, surface, domain, and circuit, if needed
if h_shield
    mshield = Material.create( dimensions.shield_material);
    this.add_material(mshield);
    
    sshield = Surface('shield');
    lcar_mag_out = lcar_shield;
    
    Shield = Domain('Outer_shield', mshield, sshield);
    this.add_domain(Shield);
    
    ShieldCircuit = SheetCircuit('Shield');
    ShieldCircuit.add_conductor( SolidConductor( Shield ) );
    this.add_circuit(ShieldCircuit);
end

if has_shaft
    mshaft = this.create_and_add_material(dimensions.shaft_material);
    Shaft = Domain('Shaft', mshaft);
    this.add_domain(Shaft);
    if mshaft.electrical_conductivity > 0
        ShaftCircuit = SheetCircuit('Shaft');
        ShaftCircuit.add_conductor( SolidConductor( Shaft ) );
        this.add_circuit(ShaftCircuit);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% creating geometry

O = Point([0,0], lcar_mag*2);

%outer surface points
Xout_cw = Point([Rout, 0], lcar_ag);
Xout_mid = Xout_cw.rotate(apole/2);
Xout_ccw = Xout_cw.mirror(apole);

%magnet points
Xmag_out_cw = Point([r_mag_out, 0], lcar_mag_out);
Xmag_out_ccw = Xmag_out_cw.mirror(apole);
Xmag_mid_cw = Point([r_mag_out*0.9, 0], lcar_mag);
Xmag_mid_ccw = Xmag_mid_cw.mirror(apole);
Xmid = Xmag_out_cw.rotate(apole/2);

%shaft points, magnet surface
if has_shaft
    Xshaft_cw = Point([dimensions.Rin; 0], lcar_shaft);
    Xshaft_mid = Xshaft_cw.rotate(apole/2);
    Xshaft_ccw = Xshaft_cw.mirror(apole);
    smagnet = Surface('magnet', ...
        geo.line, Xshaft_cw, Xmag_mid_cw, 'n_cw', ...
        geo.line, Xmag_mid_cw, Xmag_out_cw, 'n_cw', ...
        geo.arc, Xmag_out_cw, O, Xmid, ...
        geo.arc, Xmid, O, Xmag_out_ccw, ...
        geo.line, Xmag_out_ccw, Xmag_mid_ccw, 'n_ccw', ...
        geo.line, Xmag_mid_ccw, Xshaft_ccw, 'n_ccw', ...
        geo.arc, Xshaft_ccw, O, Xshaft_mid, ...
        geo.arc, Xshaft_mid, O, Xshaft_cw);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%          MODIFIED FUNCTIONALITY BEGINS HERE                   %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %creating new points for the hole
    % Note that we need the center point to be able to model 2-pole
    % machines; EMDtool needs Arcs to be strictly less than 180 degrees in
    % span.
    X_hole_cw = Point([dimensions.r_hole; 0], lcar_shaft); %clockwise boundary point
    X_hole_mid = X_hole_cw.rotate(apole/2); %center point
    X_hole_ccw = X_hole_cw.rotate(apole); %counter-clockwise boundary

    %plotting our new points if needed
    if this.plot_debug
        X_hole_cw.plot('Hole-cw', 'ro');
        X_hole_mid.plot('Hole-mid', 'bo');
        X_hole_ccw.plot('Hole-ccw', 'co');
    end

    %hole domain and material
    mair = this.create_and_add_material(0);
    Hole = Domain('Shaft_hole', mair);
    this.add_domain(Hole);

    %Creating the hole surface
    shole = Surface('', ...
        geo.line, O, X_hole_cw, ...
        geo.arc, X_hole_cw, O, X_hole_mid, ...
        geo.arc, X_hole_mid, O, X_hole_ccw, ...
        geo.line, X_hole_ccw, O);
    Hole.add_surface(shole);

    %setting periodic boundaries
    geo.set_periodic(O, X_hole_cw, O, X_hole_ccw);

    %creating shaft surface
    sshaft = Surface('', ...
        geo.line, X_hole_cw, Xshaft_cw, ...
        geo.arc, Xshaft_cw, O, Xshaft_mid, ...
        geo.arc, Xshaft_mid, O, Xshaft_ccw, ...
        geo.line, Xshaft_ccw, X_hole_ccw, ...
        geo.arc, X_hole_ccw, O, X_hole_mid, ...
        geo.arc, X_hole_mid, O, X_hole_cw);
    Shaft.add_surface(sshaft);
    geo.set_periodic(X_hole_cw, Xshaft_cw, X_hole_ccw, Xshaft_ccw);
    geo.set_periodic(Xshaft_cw, Xmag_mid_cw, Xshaft_ccw, Xmag_mid_ccw);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    %magnet surface
    smagnet = Surface('magnet', ...
        geo.line, O, Xmag_mid_cw, 'n_cw', ...
        geo.line, Xmag_mid_cw, Xmag_out_cw, 'n_cw', ...
        geo.arc, Xmag_out_cw, O, Xmid, ...
        geo.arc, Xmid, O, Xmag_out_ccw, ...
        geo.line, Xmag_out_ccw, Xmag_mid_ccw, 'n_ccw', ...
        geo.line, Xmag_mid_ccw, O, 'n_ccw');
    geo.set_periodic(O, Xmag_mid_cw, O, Xmag_mid_ccw);
end
Magnet.add_surface(smagnet);

%rest of magnet periodic boundaries
geo.set_periodic(Xmag_mid_cw, Xmag_out_cw, Xmag_mid_ccw, Xmag_out_ccw);

%preparing for sleeve definition
if h_shield > 0
    Xsleeve_cw = Point([r_sleeve_in, 0], lcar_shield);
    Xsleeve_mid = Xsleeve_cw.rotate(apole/2);
    Xsleeve_ccw = Xsleeve_cw.mirror(apole);
else
    Xsleeve_cw = Xmag_out_cw;
    Xsleeve_mid = Xmid;
    Xsleeve_ccw = Xmag_out_ccw;
end

ssleeve.add_lines(geo.arc, Xsleeve_cw, O, Xsleeve_mid, ...
    geo.arc, Xsleeve_mid, O, Xsleeve_ccw, ...
    geo.line, Xsleeve_ccw, Xout_ccw, 'n_ccw', ...
    geo.arc, Xout_ccw, O, Xout_mid, 'n_ag', ...
    geo.arc, Xout_mid, O, Xout_cw, 'n_ag', ...
    geo.line, Xout_cw, Xsleeve_cw, 'n_cw');
geo.set_periodic(Xsleeve_cw, Xout_cw, Xsleeve_ccw, Xout_ccw);

%shield, if any
if h_shield > 0    
    sshield.add_lines(geo.arc, Xmag_out_cw, O, Xmid, ...
        geo.arc, Xmid, O, Xmag_out_ccw, ...
        geo.line, Xmag_out_ccw, Xsleeve_ccw, 'n_ccw', ...
        geo.arc, Xsleeve_ccw, O, Xsleeve_mid, ...
        geo.arc, Xsleeve_mid, O, Xsleeve_cw, ...
        geo.line, Xsleeve_cw, Xmag_out_cw, 'n_cw');
    
    geo.set_periodic(Xmag_out_cw, Xsleeve_cw, Xmag_out_ccw, Xsleeve_ccw);
end

end
