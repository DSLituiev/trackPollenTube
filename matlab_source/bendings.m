function [ bnd, dx, ddx ] = bendings( varargin )
%BENDINGS -- finds bendings in the `x`
%
% Syntax:
%========
%     [ bnd, dx, ddx ] = bendings( x , R, THR )
%
% Input:
% ======
% - x    -- data points (non-decreasinf track/path)
% - R    -- radius of the binomial filter used to smooth before taking the derivative
%           (size = 2*R + 1)
% - THR  -- threshold for removing redundant bending points
%           the raw bending points are discarded if
%           | dx(j(i-1)) - 2*dx(j(i)) + dx(j(i+1)) | / mean(dx( j([i-1,i,i+1]) ) < THR
%           note that `j` do not need to be consequtive
%
%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'x', @(x)( isnumeric(x) && sum(size(x)>1)==1 ) );
addParamValue(p, 'visualize',  false, @isscalar);
addParamValue(p, 'R',  3, @isscalar);
addParamValue(p, 'threshold',   .2, @isscalar);
addParamValue(p, 'threshold_sqddx',   10, @isscalar);
addParamValue(p, 'Q_dx',  1/3, @isscalar);

parse(p, varargin{:});
%%
T = numel(p.Results.x);
t = (1:T)';

xdim = find(size(p.Results.x)>1);

BINOM_FILTER = binomialFilter(1 + 2* p.Results.R);
smoothX = paddedConv( p.Results.x , BINOM_FILTER );
dx = diff( smoothX, 1);

ddx = diff(dx);
bnd = crossing(ddx);
bnd = bnd(dx(bnd)>0);
% figure; hist(log10(dx(bnd)))

bnd = bnd(dx(bnd) > quantile(dx(bnd), p.Results.Q_dx));

bnd = cat(xdim, 1, bnd, numel(ddx));

%%

    function sqddx = sum_square_ddx(ddx, bnd)
        sqddx = zeros(size(bnd));
        l_midpoint =  [0; floor((bnd(1:end-2) + bnd(2:end-1))/2);0];
        r_midpoint =  [0; floor((bnd(2:end-1) + bnd(3:end))/2); 0];
        r_midpoint(r_midpoint> numel(ddx)) = numel(ddx);
        for ii = 2:numel(bnd)-1
            %             l_midpoint =  floor((bnd(ii-1) + bnd(ii))/2);
            %             r_midpoint = floor((bnd(ii) + bnd(ii+1))/2);
            sqddx(ii) = sum(ddx(l_midpoint(ii):r_midpoint(ii)).^2);
        end
    end

for jj = 8:-1:1
    sqddx = sum_square_ddx(ddx, bnd);
    %     figure
    %     stem(t(bnd), sqddx, 'rx');
    %     set(gca, 'yscale', 'log')
    %     xlabel('time')
    %     ylabel('local sq acceleration')
    logInds = sqddx > p.Results.threshold/jj;
    logInds([1,end]) = true;
    bnd = bnd(logInds);
end

%%
large_bnds = bnd( dx(bnd)> 1 );
auxillary_bnds = min_speed_boundaries(dx, large_bnds);

bnd( dx(bnd)> 1 ) = auxillary_bnds(:,1);
bnd = sort([bnd(:); auxillary_bnds(:,2)]);


sqddx = sum_square_ddx(ddx, bnd);
bnd = sort([bnd(sqddx > p.Results.threshold_sqddx)-3; bnd(sqddx > p.Results.threshold_sqddx)-5; bnd]);
bnd = bnd(bnd>=1);

%% optimization

    function fun= interp_error(ind, z, t, T, varargin)
        %% check the input parameters
        pie = inputParser;
        pie.KeepUnmatched = true;
        addRequired(pie, 'ind', @isnumeric);
        addRequired(pie, 'z', @isnumeric);
        addRequired(pie, 't', @isnumeric);
        addOptional(pie, 'interp1', 'pchip', @(x)strcmpi(x, {'linear','pchip', 'spline'}) );
        parse(pie, ind, z, t, varargin{:});
        %%
        
        if any(ind > numel(z)) || any(ind < 1)
            fun = Inf;
            return
        end
        ii = [1; sort(round(ind)); T];
        if any(diff(ii) == 0)
            fun = Inf;
            return
        end
        [t_impl, z_impl] = interp_implicit(ii, z(ii), pie.Results.interp1);
        %        z_interp = interp1( ii, z(ii), t);
        z_interp = interp1( t_impl, z_impl, t, pie.Results.interp1, 'extrap');
        fun =  nansum( (z - z_interp).^2 );
    end
%% add end points
% bnd = cat(xdim, 1, bnd, T);
% bnd = [bnd(diff(bnd) > 0); bnd(end)];
%% optimise
heuristic_bnd = bnd(bnd~=1 & bnd~=T);
bnd = sort(round(fminsearch(@(y)interp_error(y, p.Results.x, t, T), heuristic_bnd)));

%% add end points
bnd = cat(xdim, 1, bnd, T);
bnd = [bnd(diff(bnd) > 0); bnd(end)];
sqddx = sum_square_ddx(ddx, bnd);

% figure
% stem(t(bnd), sqddx, 'rx');
% set(gca, 'yscale', 'log')
% xlabel('time')
% ylabel('local sq acceleration')

% logInds(1) = true;
% logInds(end) = true;
%% plot
if p.Results.visualize
    %% plot the control points
    x = p.Results.x;
    figure
    plot(t,x, 'g-')
    hold all
    plot(heuristic_bnd, x(heuristic_bnd) ,'bx' );
    plot(t, interp1(heuristic_bnd, x(heuristic_bnd), t),'b-' );
    hold all
    plot(bnd, x(bnd), 'ro' );
    [t_ , x_] = interp_implicit(bnd, x(bnd));
    plot(t_, x_, 'r-' );    
    set(gca, 'xlim', [0, T])
    
    %% plot the derivatives
    nrow = 4;
    figure
    ax(1) = subplot(nrow,1,1);
    plot(t, p.Results.x );
    hold all
    plot(t(bnd), p.Results.x(bnd), 'r+' );
    xlabel('time')
    ylabel('z')
    
    ax(2) = subplot(nrow,1,2);
    plot(t(1:end-1), dx ); hold all
    plot(t(bnd), dx(min(bnd, numel(dx))), 'rx'  );
    ylim([0, min(2, 0.1*ceil(10*max(dx))) ])
    hold all
    plot([1, T], [0, 0], 'k-')
    xlabel('time')
    ylabel('speed')
    
    ax(3) = subplot(nrow,1,3);
    plot(t(2:end-1), ddx );
    hold all
    plot(t(bnd), ddx(min(max(bnd-1, 1), numel(ddx) ) ), 'rx' )
    xlabel('time')
    ylabel('acceleration')
    
    ax(4) = subplot(nrow,1,4);
    stem(t(bnd), sqddx, 'rx', 'BaseValue', 10^-10);
    set(gca, 'yscale', 'log')
    xlabel('time')
    ylabel('local sq acceleration')
    
    set(ax, 'xlim', [0, T])
    
end

end

