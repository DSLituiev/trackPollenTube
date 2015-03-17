function [ z ] = edge2path_im_pr( kymoEdge, MEDIAN_RADIUS )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

MIN_T = 20;
MIN_N_PIX = 7;
K_PIX = .5;

T = size(kymoEdge, 2);
L = size(kymoEdge, 1);

Connected = bwconncomp(kymoEdge, 8);
numPixels = cellfun(@numel,Connected.PixelIdxList);
Connected.PixelIdxList(numPixels<=MIN_N_PIX) = [];
numPixels = numPixels(numPixels>MIN_N_PIX);

for ii = numel(Connected.PixelIdxList):-1:1
    [Lc, Tc] = ind2sub([L, T], Connected.PixelIdxList{ii});
    [min_t(ii), min_i] = min(Tc);
    [max_t(ii), max_i] = max(Tc);
    max_l(ii) = Lc(min_i);
end

% valid_regions = find(min_t < MIN_T);

%     [~, idx] = max( - min_l(valid_regions)/L + K_PIX*numPixels(valid_regions)/T);

start_t = 0;
start_l = 0;
maxmax_t = T;
lls = []; tts = []; jj = 1;
regionIdxs = [];
idx = NaN;
while start_t < maxmax_t
    for ii = numel(Connected.PixelIdxList):-1:1
        [Lc, Tc] = ind2sub([L, T], Connected.PixelIdxList{ii});
        if (ii~=idx) && ...
                sum(Tc>start_t+MIN_T)>0 && ...
                sum(Lc>start_l)>0 && ...
                sum(Lc<start_l & Tc>start_t)/sum( Tc>start_t) < 1/3
                
            [min_t(ii), min_i] = min(Tc(Tc>start_t));
            [max_t(ii), max_i] = max(Tc(Tc>start_t));
            min_l(ii) = Lc(min_i);
            max_l(ii) = Lc(max_i);
        else
            min_t(ii) = NaN;
            max_t(ii) = NaN;
            min_l(ii) = NaN;
            max_l(ii) = NaN;
        end
        maxmax_t = max(max_t);
    end
    
    distance2 = (min_t - start_t).^2 + (min_l - start_l).^2 ;
    [~, idx] = min( distance2 );
    
    [ll0, tt0] = ind2sub([L, T], Connected.PixelIdxList{idx});
    lls = [lls(:); ll0(tt0>start_t)];
    tts = [tts(:); tt0(tt0>start_t)];
    
    regionIdxs = [regionIdxs, idx];
    
    start_t = max_t(idx);
    start_l = max_l(idx); 
    jj = jj+1;
end

figure; plot(tts, lls)

if (numel(tts) == T) && all(diff(tts) == 1)
    z = fastmedfilt1d(lls, MEDIAN_RADIUS);
else
    lls = fastmedfilt1d(lls, MEDIAN_RADIUS);
    z = zeros(T, 1);
    for cc = 2:numel(tts)
        tt = tts(cc);
        if tts(cc) == tts(cc-1) +1
            z(tt) = lls(cc);
        else
            z(tt) = max(lls(tt == tts));
        end
    end
    z = fastmedfilt1d(z, MEDIAN_RADIUS);
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

