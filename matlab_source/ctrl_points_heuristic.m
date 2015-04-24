function [heuristic_bnd, dx, ddx] = ctrl_points_heuristic(x,varargin)
%% check the input parameters
p = inputParser;
addRequired(p, 'x', @(x)( isnumeric(x) && sum(size(x)>1)==1 ) );
addOptional(p, 'R',  3, @isscalar);
addOptional(p, 'Q_dx',  1/3, @isscalar);
addOptional(p, 'threshold_lo',   .2, @isscalar);
addOptional(p, 'threshold_hi',   10, @isscalar);
parse(p, x, varargin{:});
%%
xdim = find(size(x)>1);
T = numel(p.Results.x);

BINOM_FILTER = binomialFilter(1 + 2* p.Results.R);
smoothX = paddedConv( x , BINOM_FILTER );
dx = diff( smoothX, 1);

ddx = diff(dx);
bnd = crossing(ddx);
bnd = bnd(dx(bnd)>0);
% figure; hist(log10(dx(bnd)))
bnd = bnd(dx(bnd) > quantile(dx(bnd), p.Results.Q_dx));

bnd = cat(xdim, 1, bnd, numel(ddx));
%%
for jj = 8:-1:1
    sqddx = sum_square_ddx(ddx, bnd);
    %     figure
    %     stem(t(bnd), sqddx, 'rx');
    %     set(gca, 'yscale', 'log')
    %     xlabel('time')
    %     ylabel('local sq acceleration')
    logInds = sqddx > p.Results.threshold_lo/jj;
    logInds([1,end]) = true;
    bnd = bnd(logInds);
end

%%
large_bnds = bnd( dx(bnd)> 1 );
auxillary_bnds = min_speed_boundaries(dx, large_bnds);

bnd( dx(bnd)> 1 ) = auxillary_bnds(:,1);
bnd = sort([bnd(:); auxillary_bnds(:,2)]);

sqddx = sum_square_ddx(ddx, bnd);
bnd = sort([bnd(sqddx > p.Results.threshold_hi)-3; bnd(sqddx > p.Results.threshold_hi)-5; bnd]);
bnd = bnd(bnd>=1);

dx = diff(x(bnd));
dt = diff(bnd);

bnd = bnd(logical(dx)|logical(dt));

heuristic_bnd = bnd(bnd~=1 & bnd~=T);
end