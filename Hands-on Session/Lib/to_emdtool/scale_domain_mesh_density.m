function scale_domain_mesh_density(this, scale, varargin)

DEFAULTS = struct('curves_to_skip', ["n_ag"]);
DEFAULTS.lcar_max = inf;
DEFAULTS.lcar_min = 0;


args = parse_defaults(DEFAULTS, varargin{:});

ps = GeoHelper.get_points(this);

warning('Does not yet handle skipped curves. To be fixed.')
%{
for cname = args.curves_to_skip
    cs = GeoHelper.get_curve_by_name(this, cname);

    phere = [];
    for c = cs
        phere = [phere, c.pstart, c.pend];
    end

    ps = setdiff(ps, phere);
end
%}

for p = ps
    lcar_cand = p.lcar * scale;
    lcar_cand = min(lcar_cand, args.lcar_max);
    lcar_cand = max(lcar_cand, args.lcar_min);
    p.lcar = lcar_cand;
end