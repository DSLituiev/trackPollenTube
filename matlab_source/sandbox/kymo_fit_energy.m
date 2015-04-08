function fun = kymo_fit_energy(r, edge_img, varargin)
%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'r', @isnumeric );
addRequired(p, 'edge_img', @(x)(isnumeric(x) && (sum(size(x)>1)==2) ) );
addOptional(p, 'img', @(x)(isnumeric(x) && (sum(size(x)>1)==2) ) );
addOptional(p, 'fixed',  [], @islogical);
addOptional(p, 'r0',  [], @isnumeric);
addParamValue(p, 'alpha',  1, @isscalar);
addParamValue(p, 'beta',  .5, @isscalar);
addParamValue(p, 'kappa',  1, @isscalar);
addParamValue(p, 'lambda',  0, @isscalar);

parse(p, r, edge_img, varargin{:});
%% 
if ~isempty(p.Results.fixed) && ~isempty(p.Results.r0) && ...
        all(size(p.Results.r0) ==  size(p.Results.r)) &&  all( size(p.Results.r0) ==  size(p.Results.fixed) )
    penalty_fix = 1e2 * p.Results.alpha * sum( (p.Results.r0(p.Results.fixed) - p.Results.r(p.Results.fixed)).^2);
else
    penalty_fix = 0;
end

[x, y] = interp_implicit( r(:,1), r(:,2));

rss = diff(r, 2);
maxY = size(edge_img,1) ;
maxX = size(edge_img,2) ;

outliers_yp = y > maxY ;
outliers_ym = y < 1 ;
y(outliers_yp) = size(edge_img,1);
y(outliers_ym) = 1;


outliers_xp = x > maxX ;
outliers_xm = x < 1 ;
x(outliers_xp) = size(edge_img, 2);
x(outliers_xm) = 1;

penalty_outliers = 1e2 * ( sum(mod(y(outliers_yp|outliers_ym), maxY).^2) + ...
    sum(mod(x(outliers_xp|outliers_xm), maxX).^2) );
%%
edge_intensity = integrate_over_edge(edge_img, x, y);
edge_energy = sum(edge_intensity);
%%
if p.Results.lambda > 0
BWup = poly2mask( [1;x;maxX;1], [1;y;1;1],  maxY, maxX);
BWdw = poly2mask( [1;x;maxX;1], [maxY;y;maxY;maxY],  maxY, maxX);
pix_up = p.Results.img(BWup);
pix_dw = p.Results.img(BWdw);
area_energy = (sum((pix_up(:) - mean(pix_up(:))).^2)/sum(BWup(:)) + sum( (pix_dw(:) - mean(pix_dw(:))).^2)/sum(BWdw(:)) ) ;
else
    area_energy = 0;
end
%%
fun =  p.Results.alpha * sum(rss(:)) + p.Results.kappa * edge_energy + ...
    p.Results.lambda * area_energy + ... 
    penalty_fix + penalty_outliers;
    
end