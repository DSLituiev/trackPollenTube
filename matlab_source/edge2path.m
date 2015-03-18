function [ z ] = edge2path( kymoEdge, varargin )
%EDGE2PATH_IM_PR -- returns coordinates of the edge of a kymogram
%
% Input
% =====
% - kymoEdge      -- edge of a kymogram, size [L * T]
% - MEDIAN_RADIUS -- radius of the median filter
%
% Output
% =====
% z -- l-coordinate of the kymogram edge, size [T * 1]
%      with corresponding t-coordinate (time) :   1:T
%% check the input parameters
p = inputParser;
% p.KeepUnmatched = true;
addRequired(p, 'kymoEdge', @(x)( isnumeric(x) && (sum(size(x)>1)==2) ) );
addOptional(p, 'MEDIAN_RADIUS',  5, @isscalar);
addOptional(p, 'MIN_N_PIX', 7, @isscalar);
parse(p, kymoEdge, varargin{:});
%%

T = size(kymoEdge, 2);
L = size(kymoEdge, 1);

Connected = bwconncomp(kymoEdge, 8);
numPixels = cellfun(@numel,Connected.PixelIdxList);
Connected.PixelIdxList(numPixels<= p.Results.MIN_N_PIX) = [];

reg = struct('Lc',[], 'Tc', [], 'min_t', 0, 'max_t', 0, 'min_l', 0, 'max_l', 0, 'numel', 0, 'valid', false);

for ii = numel(Connected.PixelIdxList):-1:1
    [reg(ii).Lc, reg(ii).Tc] = ind2sub([L, T], Connected.PixelIdxList{ii});
    reg(ii).numel = numel(Connected.PixelIdxList{ii});
end

start_t = 0;
start_l = 0;
maxmax_t = T;
idx = NaN;
lls = [];   tts = [];
% jj = 1;
% regionIdxs = [];
while start_t < maxmax_t
    
    for ii = numel(reg):-1:1
        if (ii~=idx) && ...
                sum(reg(ii).Tc > start_t - p.Results.MIN_N_PIX)>0 && ...
                sum(reg(ii).Lc > start_l)>0 && ...
                sum(reg(ii).Lc < start_l & reg(ii).Tc>start_t)/sum( reg(ii).Tc>start_t) < 1/3
                
            [min_t(ii), min_i] = min(reg(ii).Tc(reg(ii).Tc>start_t));
            [max_t(ii), max_i] = max(reg(ii).Tc(reg(ii).Tc>start_t));
            min_l(ii) = reg(ii).Lc(min_i);
            max_l(ii) = reg(ii).Lc(max_i);          
            
            reg(ii).valid = true;
        else
            min_t(ii) = NaN;
            max_t(ii) = NaN;
            min_l(ii) = NaN;
            max_l(ii) = NaN;
            
            reg(ii).valid = false;
        end
        maxmax_t = max(max_t);
    end
    
    distance2 = (min_t - start_t).^2 + (min_l - start_l).^2 ;
    [~, idx] = min( distance2 );
    
    valid_t = reg(idx).Tc > start_t ;
    lls = [lls(:); reg(idx).Lc(valid_t)];
    tts = [tts(:); reg(idx).Tc(valid_t)];

    %     regionIdxs = [regionIdxs, idx];
    %     jj = jj+1;

    start_t = max_t(idx);
    start_l = max_l(idx); 
end

% figure; plot(tts, lls); set(gca, 'Ydir', 'reverse')

if (numel(tts) == T) && all(diff(tts) == 1)
    z = fastmedfilt1d(lls, p.Results.MEDIAN_RADIUS);
else
    lls = fastmedfilt1d(lls, p.Results.MEDIAN_RADIUS);
    z = zeros(T, 1);
    for cc = 2:numel(tts)
        tt = tts(cc);
        if tts(cc) == tts(cc-1) +1
            z(tt) = lls(cc);
        else
            z(tt) = max(lls(tt == tts));
        end
    end
    z = fastmedfilt1d(z, p.Results.MEDIAN_RADIUS);
end

for tt = 2:T
    if z(tt) < z(tt-1)
        z(tt) = z(tt-1);
    elseif z(tt) < z(tt-1)
        z(tt) = z(tt-1);
    else
        z(tt) = z(tt);
    end
end

end

