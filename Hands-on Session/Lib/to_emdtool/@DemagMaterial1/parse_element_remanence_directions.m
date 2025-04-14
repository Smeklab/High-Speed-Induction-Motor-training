function parse_element_remanence_directions(this)

ri = 0;
for d = this.domains
    els = d.elements;

    Brvec = d.remanence_direction_at();
    as = atan2(Brvec(2,:), Brvec(1,:));


    %{
    Brdir = d.remanence_direction;
    
    if ischar(Brdir)
        %parsing direction
        if Brdir(1) == '-'
            sig = -1;
            Brdir = Brdir(2:end);
        else
            sig = 1;
        end
        
        %elements centers of mass
        p0 = msh.p(:, msh.t(1, els));
        for kf = 2:size(msh.t,1)
            p0 = p0 + msh.p(:, msh.t(kf, els));
        end
        p0 = p0 / size(msh.t,1);
        
        %normalizing
        pnorm = sqrt( sum(p0.^2,1) );
        er = bsxfun(@rdivide, p0, pnorm);
        
        if strcmpi(Brdir, 'circumferential')
            er = [0 -1;1 0]*er;
        end
        tvec = sig*er;
        as = atan2(tvec(2,:), tvec(1,:));
    else
        as = repmat(Brdir, 1, numel(els));
    end
    %}
    
    this.remanence_direction_angles(:, (ri+1):(ri+numel(els))) = as;
    ri = ri + numel(els);
end

end