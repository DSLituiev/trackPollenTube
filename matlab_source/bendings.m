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
addParamValue(p, 'threshold',   .25, @isscalar);
addParamValue(p, 'Q_dx',  1/3, @isscalar);

parse(p, varargin{:});
%%
T = numel(p.Results.x);
t = 1:T;

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
sqddx = zeros(size(bnd));

for jj = 1:4
    logInds = true(size(bnd));
    
    for ii = 2:numel(bnd)-1        
        sqddx(ii) = sum(ddx(bnd(ii-1):bnd(ii+1)).^2);
        logInds(ii) = sqddx(ii) > p.Results.threshold / 4;
        
%         if logInds(ii)
%             [~, ind] = max( abs(ddx(bnd(ii) + [-1:1:1])));
%             bnd(ii) = bnd(ii)+ind;
%         end
    end
    
%     figure
%     stem(t(bnd), sqddx, 'rx');
%     set(gca, 'yscale', 'log')
%     xlabel('time')
%     ylabel('local sq acceleration')
%     
%     bnd = bnd(logInds);
%     sqddx = sqddx(logInds);
end

logInds = sqddx > p.Results.threshold;
bnd = bnd(logInds);
sqddx = sqddx(logInds);

bnd = cat(xdim, 1, bnd+1, T);
sqddx = cat(xdim, 0, sqddx, 0);

for ii = 2:numel(bnd)-1   
    [~, ind] = max( abs(ddx(bnd(ii) + [-floor(p.Results.R/2):1:floor(p.Results.R/2)])));
    bnd(ii) = bnd(ii)+ind;
end
% figure
% stem(t(bnd), sqddx, 'rx');
% set(gca, 'yscale', 'log')
% xlabel('time')
% ylabel('local sq acceleration')

% logInds(1) = true;
% logInds(end) = true;
%% plot speed 

if p.Results.visualize
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
    stem(t(bnd), sqddx, 'rx');
    set(gca, 'yscale', 'log')
    xlabel('time')
    ylabel('local sq acceleration')
    
    set(ax, 'xlim', [0, T])
    
end

end

