function [ cr, dx, ddx ] = peaks( x , R, THR)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

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
cr = crossing(ddx);
logInds = false(size(cr));

for ii = 2:numel(cr)-1
    
    norm_ddx = 3 * abs( 2*dx(cr(ii)) - dx(cr(ii-1))  - dx(cr(ii+1)) ) / ...
   ( dx(cr(ii)) + dx(cr(ii-1)) + dx(cr(ii+1)) ) ;

    logInds(ii) = norm_ddx > THR ;

%     logInds(ii) = logInds(ii) || 2 * abs(speedRawFiltered(cr(ii)) - speedRawFiltered(cr(ii-1)) ) / ...
%    ( speedRawFiltered(cr(ii)) + speedRawFiltered(cr(ii-1)) ) > THR ;
% 
%     logInds(ii) = logInds(ii) || 2 * abs(speedRawFiltered(cr(ii)) - speedRawFiltered(cr(ii+1)) ) / ...
%    ( speedRawFiltered(cr(ii)) + speedRawFiltered(cr(ii+1)) ) > THR ;
    if logInds(ii)
        [~, ind] = max( abs(ddx(cr(ii) + [-1:1:1])));
        cr(ii) = cr(ii)+ind;            
    end
end

% logInds(1) = true;
% logInds(end) = true;
cr = cat(find(size(cr)>1),1, cr(logInds)+1, numel(x));

end

