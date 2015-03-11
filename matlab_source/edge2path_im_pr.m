function [ z ] = edge2path_im_pr( kymoEdge, MEDIAN_RADIUS )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    MIN_T = 20;
    MIN_N_PIX = 7;
    K_PIX = 5;

    T = size(kymoEdge, 2);
    L = size(kymoEdge, 1);
    
    Connected = bwconncomp(kymoEdge, 8);
    numPixels = cellfun(@numel,Connected.PixelIdxList);
    Connected.PixelIdxList(numPixels<=MIN_N_PIX) = [];
    numPixels = numPixels(numPixels>MIN_N_PIX);
    
    for ii = numel(Connected.PixelIdxList):-1:1
       [Lc, Tc] = ind2sub([L, T], Connected.PixelIdxList{ii});
       [min_t(ii), min_i] = min(Tc);
       min_l(ii) = Lc(min_i);
    end
    
    valid_regions = find(min_t < MIN_T);
    [~, idx] = max( - min_l(valid_regions)/L + K_PIX*numPixels(valid_regions)/T);
    
    % [~, idx] = max(numPixels);
    [Lc, Tc] = ind2sub([L, T], Connected.PixelIdxList{idx});

    
    if (numel(Tc) == T) && all(diff(Tc) == 1)
        z = fastmedfilt1d(Lc, MEDIAN_RADIUS);
    else
        Lc = fastmedfilt1d(Lc, MEDIAN_RADIUS);
        z = zeros(T, 1);
        for cc = 2:numel(Tc)
            tt = Tc(cc);
            if Tc(cc) == Tc(cc-1) +1
                z(tt) = Lc(cc);
            else
                z(tt) = max(Lc(tt == Tc(cc)));
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

