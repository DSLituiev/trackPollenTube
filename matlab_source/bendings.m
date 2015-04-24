function [ t0, x0, dx, ddx ] = bendings( varargin )
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
addOptional(p, 'kymo', [], @(x)( isempty(x) || isnumeric(x) && sum(size(x)>1)==2 ) );
addParamValue(p, 'visualize',  false, @isscalar);
addParamValue(p, 'R',  3, @isscalar);
addParamValue(p, 'Q_dx',  1/3, @isscalar);
addParamValue(p, 'threshold_lo', 0.2, @isscalar);
addParamValue(p, 'threshold_hi',  10, @isscalar);
addParamValue(p, 'heuristic', true, @(x)(isscalar(x)));
% addParamValue(p, 'useAsEnergy', false, @(x)(isscalar(x)));

parse(p, varargin{:});
%%
T = numel(p.Results.x);
t = (1:T)';
xdim = find(size(p.Results.x)>1);
%%
[t0, dx, ddx] = ctrl_points_heuristic(p.Results.x, ...
    p.Results.R, p.Results.Q_dx, p.Results.threshold_lo, p.Results.threshold_hi);

%% line interpolation error
    function fun= line_interp_error(ind, z, t, T, varargin)
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
%% optimise
if isempty(p.Results.kymo) || p.Results.heuristic
    t0 = sort(round(fminsearch(@(y)line_interp_error(y, p.Results.x, t, T), t0)));%% add end points
    t0 = cat(xdim, 1, t0, T);
    t0 = [t0(diff(t0) > 0); t0(end)];
    sqddx = sum_square_ddx(ddx, t0);
    x0 = p.Results.x(t0);
else    
    t0 = cat(xdim, 1, t0, T);
    x0 = p.Results.x(t0);
    [ t0, x0 ] = segment_snake( p.Results.kymo,  t0, x0 );
    t0 = round(flipud(t0));
    x0 = round(flipud(x0));
end

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
    plot(t0, x(t0), 'ro' );
    [t_ , x_] = interp_implicit(t0, x(t0));
    plot(t_, x_, 'r-' );
    set(gca, 'xlim', [0, T])
    
    %% plot the derivatives
    nrow = 4;
    figure
    ax(1) = subplot(nrow,1,1);
    plot(t, p.Results.x );
    hold all
    plot(t(t0), p.Results.x(t0), 'r+' );
    xlabel('time')
    ylabel('z')
    
    ax(2) = subplot(nrow,1,2);
    plot(t(1:end-1), dx ); hold all
    plot(t(t0), dx(min(t0, numel(dx))), 'rx'  );
    ylim([0, min(2, 0.1*ceil(10*max(dx))) ])
    hold all
    plot([1, T], [0, 0], 'k-')
    xlabel('time')
    ylabel('speed')
    
    ax(3) = subplot(nrow,1,3);
    plot(t(2:end-1), ddx );
    hold all
    plot(t(t0), ddx(min(max(t0-1, 1), numel(ddx) ) ), 'rx' )
    xlabel('time')
    ylabel('acceleration')
    
    ax(4) = subplot(nrow,1,4);
    stem(t(t0), sqddx, 'rx', 'BaseValue', 10^-10);
    set(gca, 'yscale', 'log')
    xlabel('time')
    ylabel('local sq acceleration')
    
    set(ax, 'xlim', [0, T])
    
end

end

