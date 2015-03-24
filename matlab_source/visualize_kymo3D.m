function ff = visualize_kymo3D(tifPath, kymogram, xy_roi, rt_roi, varargin)
fontSize = 12;
%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'tifPath', @(x)( (ischar(x) && exist(x, 'file')) ) );
addRequired(p, 'kymogram',  @(x)( isnumeric(x) && (sum(size(x)>1)==2) ) );
addRequired(p, 'xy_roi',  @isobject );
addRequired(p, 'rt_roi',  @isobject );
addOptional(p, 'tt',  0, @isscalar);
addParamValue(p, 'fontSize', 12, @(x)(isscalar(x)));
parse(p, tifPath, kymogram, xy_roi, rt_roi, varargin{:});
%%
%%

    function s1 = plot_frame(tifPath, xy_roi, tt)
        ptFrame = cropRectRoiFast(tifPath, xy_roi, 0, tt);
        ptFrame = medfilt3(ptFrame, [3,3,3]);
        ptFrame  = normalizeRange16( ptFrame );
        s1 = surfc( 1:size(ptFrame,2),1:size(ptFrame,1), tt*ones(size(ptFrame)), ...
            double(ptFrame), 'linestyle', 'none');
        
        plot3(xy_roi.x, xy_roi.y, tt *ones(size(xy_roi.y)), '-', 'color', [0,.4,.4], 'linewidth', 1.2)
        
        set(gca, 'xlim', [1, size(ptFrame,2)], 'ylim', [1, size(ptFrame,1)] )
    end
%%
kymogram  = normalizeRange16( kymogram );

ptPath = path_xyt(xy_roi, rt_roi);
%
% ptPath.xyt = interp1( (1:ptPath.L)', [ptPath.x, ptPath.y], double(ptPath.r) );
% ptPath.xyt(:, 3) = double(1:1:ptPath.T)';

[X,T] = ndgrid(ptPath.x2d, ptPath.t);
[Y,~] = ndgrid(ptPath.y2d, ptPath.t);

axColor = [0.5, .2, 0.1];

ff = figure;
ss = surfc(X, Y , T, double(kymogram) );
colormap gray
set(ss, 'linestyle', 'none')
alpha( ss , 0.8)
set(gca, 'xcolor',axColor, 'ycolor',axColor, 'zcolor', axColor)
hold on
plot3(ptPath.x, ptPath.y, ptPath.t, 'g', 'linewidth', 1.2)

%%
if ~p.Results.tt
    tt = double(ptPath.T) * 2/(1+sqrt(5));
else
    tt = p.Results.tt;
end
%%
s1 = plot_frame(tifPath, xy_roi, 1);
s2 = plot_frame(tifPath, xy_roi, tt);
%%
view(7.5, 20)
xlabel('$x$', 'interpreter', 'latex', 'fontsize', fontSize)
ylabel('$y$', 'interpreter', 'latex', 'fontsize', fontSize)
zlabel('$t$', 'interpreter', 'latex', 'fontsize', fontSize)
daspect([1 1 2])

%%
fig(ff)
end