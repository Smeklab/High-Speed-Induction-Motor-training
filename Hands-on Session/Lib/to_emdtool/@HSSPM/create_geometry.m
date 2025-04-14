function create_geometry(this)

%parsing
dim = this.dimensions;

lcar_ag = Airgap.characteristic_length(this);
lcar_sleeve = lcar_ag;
lcar_mag = dim.hpm/5;

apole = pi/dim.p;

lcar_in = dim.Rin * apole/5;

%parsing shields
if isfield(dim, 'h_shield')
    h_shield = dim.h_shield;
    lcar_shield = h_shield;
else
    h_shield = 0;
end
has_shield = h_shield > 0;
if isfield(dim, 'h_shield_top')
    h_shield_top = dim.h_shield_top;
    lcar_shield_top = h_shield_top;
else
    h_shield_top = 0;
end
has_top_shield = h_shield_top>0;

%magnet span
rmag_out = dim.Rout - dim.h_sleeve - h_shield_top;
if isfield(dim, 'wmag')
    wmag = dim.wpm;
    amag = acos( (2*rmag_out^2 - wmag^2) / (2*rmag_out^2) );
    agap = 2*pi/dim.number_of_magnets - amag;
    if agap <= 0
        amag = 2*pi/dim.number_of_magnets;
        disp('No magnet gaps modelled.')
    else
        error('Not yet implemented.')
    end
else
    amag = 2*pi/dim.number_of_magnets;
end

Nmag = dim.number_of_magnets / (2*dim.p);

rmag_in = rmag_out - dim.hpm;
r_core_out = rmag_in - h_shield;


lcar_shaft = interp1([0, rmag_out-dim.h_sleeve], [lcar_in, lcar_mag], dim.Rin);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% materials

mcore = this.create_and_add_material(dim.rotor_core_material);
mmag = this.create_and_add_material(dim.magnet_material);
msleeve = this.create_and_add_material(dim.rotor_sleeve_material);
mshaft = this.create_and_add_material(dim.shaft_material);

Core = Domain('Rotor_core', mcore);
Sleeve = Domain('Sleeve', msleeve);
this.add_domain(Core, Sleeve);
if mcore == mshaft
    Shaft = Core;
else
    Shaft = Domain('Shaft', mshaft);
    this.add_domain(Shaft);
end

if has_shield
    mshield = this.create_and_add_material(dim.shield_material);
    Shield = Domain('Shield', mshield);
    this.add_domain(Shield);
    if mshield.electrical_conductivity > 0
        ShieldCircuit = SheetCircuit('Shield');
        ShieldCircuit.add_conductor(SolidConductor(Shield));
        this.add_circuit(ShieldCircuit);
    end
end
if has_top_shield
    mshield = this.create_and_add_material(dim.shield_material);
    TopShield = Domain('TopShield', mshield);
    this.add_domain(TopShield);
    if mshield.electrical_conductivity > 0
        TopShieldCircuit = SheetCircuit('TopShield');
        TopShieldCircuit.add_conductor(SolidConductor(TopShield));
        this.add_circuit(TopShieldCircuit);
    end
end

%magnet circuit
MagnetCircuit = ExtrudedBlockCircuit('Magnets');
MagnetCircuit.block_height = dim.magnet_height;
if mmag.electrical_conductivity > 0
    this.add_circuit(MagnetCircuit);
end

%core circuit
if mcore.electrical_conductivity > 0
    CoreCircuit = SheetCircuit('RotorCoreEddies');
    CoreCircuit.add_conductor(SolidConductor(Core));
    this.add_circuit(CoreCircuit);
end

%shaft circuit
if mshaft.electrical_conductivity > 0 && mcore ~= mshaft
    ShaftCircuit = SheetCircuit('Shaft');
    ShaftCircuit.add_conductor(SolidConductor(Shaft));
    this.add_circuit(ShaftCircuit);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% geometry

O = Origin(lcar_in);

%outer points
Xout_cw = Point([dim.Rout; 0], lcar_ag);
Xout_mid = Xout_cw.rotate(apole/2);
Xout_ccw = Xout_cw.rotate(apole);

%shaft points
Xshaft_cw = Point([dim.Rin; 0], lcar_shaft);
Xshaft_mid = Xshaft_cw.rotate(apole/2);
Xshaft_ccw = Xshaft_cw.rotate(apole);

%shaft surface
sshaft = Surface('', ...
    geo.line, O, Xshaft_cw, ...
    geo.arc, Xshaft_cw, O, Xshaft_mid, ...
    geo.arc, Xshaft_mid, O, Xshaft_ccw, ...
    geo.line, Xshaft_ccw, O);
geo.set_periodic(O, Xshaft_cw, O, Xshaft_ccw);
Shaft.add_surface(sshaft);

%magnets assembly
ssleeve = Surface('');
score = Surface('');
if has_shield
    Pshield_in_cw = Point([r_core_out; 0], lcar_shield);
    Pshield_in_mid = Pshield_in_cw.rotate(apole/2);
    Pshield_in_ccw = Pshield_in_cw.mirror(apole);
    sshield = Surface('');
    surface_below = sshield;
else
    surface_below = score;
end
if has_top_shield
    Ptopshield_out_cw = Point([rmag_out+h_shield_top;0], lcar_shield_top);
    Ptopshield_out_mid = Ptopshield_out_cw.rotate(apole/2);
    Ptopshield_out_ccw = Ptopshield_out_cw.rotate(apole);
    sshield_top = Surface('');
    surface_above = sshield_top;
else
    surface_above = ssleeve;
end

Pmag_in_prev = Point([rmag_in; 0], lcar_mag); Pmag_in_first = Pmag_in_prev;
Pmag_out_prev = Point([rmag_out; 0], lcar_sleeve); Pmag_out_first = Pmag_out_prev;

for k = 1:Nmag
    Pin_next = Pmag_in_prev.rotate(amag);
    Pout_next = Pmag_out_prev.rotate(amag);

    smag = Surface('', ...
        geo.arc, Pmag_in_prev, O, Pin_next, ...
        geo.line, Pin_next, Pout_next, ...
        geo.arc, Pout_next, O, Pmag_out_prev, ...
        geo.line, Pmag_out_prev, Pmag_in_prev);
    Magnet = Domain(sprintf('Magnet_%d', k), mmag);
    Magnet.remanence_direction = 'radial';
    Magnet.add_surface(smag);
    this.add_domain(Magnet);
    MagnetCircuit.add_conductor(SolidConductor(Magnet));

    surface_below.add_curve(geo.arc, Pmag_in_prev, O, Pin_next);
    surface_above.add_curve(geo.arc, Pmag_out_prev, O, Pout_next);

    Pmag_in_prev = Pin_next;
    Pmag_out_prev = Pout_next;
end

%magnet periodicity
geo.set_periodic(Pmag_in_first, Pmag_out_first, Pmag_in_prev, Pmag_out_prev);

%finalizing core and optionally shield surfaces
if has_shield
    sshield.add_curve(...
        geo.line, Pmag_in_prev, Pshield_in_ccw, ...
        geo.arc, Pshield_in_ccw, O, Pshield_in_mid, ...
        geo.arc, Pshield_in_mid, O, Pshield_in_cw, ...
        geo.line, Pshield_in_cw, Pmag_in_first);
    score.add_curve(...
        geo.arc, Pshield_in_cw, O, Pshield_in_mid, ...
        geo.arc, Pshield_in_mid, O, Pshield_in_ccw, ...
        geo.line, Pshield_in_ccw, Xshaft_ccw, ...
        geo.arc, Xshaft_ccw, O, Xshaft_mid, ...
        geo.arc, Xshaft_mid, O, Xshaft_cw, ...
        geo.line, Xshaft_cw, Pshield_in_cw);
    geo.set_periodic(Pshield_in_cw, Pmag_in_first, Pshield_in_ccw, Pmag_in_prev);
    geo.set_periodic(Xshaft_cw, Pshield_in_cw, Xshaft_ccw, Pshield_in_ccw);

    Shield.add_surface(sshield);
else
    score.add_curve( ...
        geo.line, Pmag_in_prev, Xshaft_ccw, ...
        geo.arc, Xshaft_ccw, O, Xshaft_mid, ...
        geo.arc, Xshaft_mid, O, Xshaft_cw, ...
        geo.line, Xshaft_cw, Pmag_in_first);
    geo.set_periodic(Xshaft_cw, Pmag_in_first, Xshaft_ccw, Pmag_in_prev);
end
Core.add_surface(score);


%finalizing sleeve and top shield, if any
if has_top_shield
    sshield_top.add_curve(....
        geo.line, Pmag_out_prev, Ptopshield_out_ccw, ...
        geo.arc, Ptopshield_out_ccw, O, Ptopshield_out_mid, ...
        geo.arc, Ptopshield_out_mid, O, Ptopshield_out_cw, ...
        geo.line, Ptopshield_out_cw, Pmag_out_first);
    geo.set_periodic(Pmag_out_first, Ptopshield_out_cw, Pmag_out_prev, Ptopshield_out_ccw);
    TopShield.add_surface(sshield_top);
    
    ssleeve.add_curve(...
        geo.arc, Ptopshield_out_cw, O, Ptopshield_out_mid, ...
        geo.arc, Ptopshield_out_mid, O, Ptopshield_out_ccw, ...
        geo.line, Ptopshield_out_ccw, Xout_ccw, ...
        geo.arc, Xout_ccw, O, Xout_mid, 'n_ag', ...
        geo.arc, Xout_mid, O, Xout_cw, 'n_ag', ...
        geo.line, Xout_cw, Ptopshield_out_cw);
    geo.set_periodic(Ptopshield_out_cw, Xout_cw, Ptopshield_out_ccw, Xout_ccw)
else
    ssleeve.add_curve(...
        geo.line, Pmag_out_prev, Xout_ccw, ...
        geo.arc, Xout_ccw, O, Xout_mid, 'n_ag', ...
        geo.arc, Xout_mid, O, Xout_cw, 'n_ag', ...
        geo.line, Xout_cw, Pmag_out_first);
    geo.set_periodic(Pmag_out_first, Xout_cw, Pmag_out_prev, Xout_ccw);

end
Sleeve.add_surface(ssleeve);

end