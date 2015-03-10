function [ bnd, dx, ddx ] = bendings( x , R, THR )
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

if nargin < 2
    R = 3;
end
if nargin < 3
    THR = 0.98;
end

BINOM_FILTER = binomialFilter(1+2*R);
smoothX = paddedConv( x , BINOM_FILTER );
dx = diff( smoothX, 1);

ddx = diff(dx);
bnd = crossing(ddx);
logInds = false(size(bnd));

for ii = 2:numel(bnd)-1
    
    norm_ddx = 3 * abs( 2*dx(bnd(ii)) - dx(bnd(ii-1))  - dx(bnd(ii+1)) ) / ...
   ( dx(bnd(ii)) + dx(bnd(ii-1)) + dx(bnd(ii+1)) ) ;

    logInds(ii) = norm_ddx > THR ;

%     logInds(ii) = logInds(ii) || 2 * abs(speedRawFiltered(cr(ii)) - speedRawFiltered(cr(ii-1)) ) / ...
%    ( speedRawFiltered(cr(ii)) + speedRawFiltered(cr(ii-1)) ) > THR ;
% 
%     logInds(ii) = logInds(ii) || 2 * abs(speedRawFiltered(cr(ii)) - speedRawFiltered(cr(ii+1)) ) / ...
%    ( speedRawFiltered(cr(ii)) + speedRawFiltered(cr(ii+1)) ) > THR ;
    if logInds(ii)
        [~, ind] = max( abs(ddx(bnd(ii) + [-1:1:1])));
        bnd(ii) = bnd(ii)+ind;            
    end
end

% logInds(1) = true;
% logInds(end) = true;
bnd = cat(find(size(bnd)>1),1, bnd(logInds)+1, numel(x));

end

