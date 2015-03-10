function [ z ] = edge2path_im_pr( kymoEdge, MEDIAN_RADIUS)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    T = size(kymoEdge, 2);
    L = size(kymoEdge, 1);
    Connected = bwconncomp(kymoEdge);
    numPixels = cellfun(@numel,Connected.PixelIdxList);
    [~, idx] = max(numPixels);
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
