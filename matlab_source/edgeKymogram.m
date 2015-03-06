function kymoThr = edgeKymogram(kymogram, KYMO_QUANTILE, EDGE_SIGMA)
% finds edges in the kymogram with the Canny filter.
% Pre-processing steps:
%  - evening out of too bright points (more than KYMO_QUANTILE* 100% of intensity)
%  - padding of the image with margins on the spatial sides: 
%      *  start-> [value(1) --- 0] <-end

% KYMO_QUANTILE = .9;
% EDGE_SIGMA = 22;
EDGE_THRESH = 0;

%== threshold the kymogram
% % hist(single (kymogram(:)) )
q = quantile(kymogram(:), KYMO_QUANTILE);
kymogram(kymogram > q) = q;

% [kymoThr, ~, ~, dy] = edgeD([fast_median(kymogram(1,:)')*ones(EDGE_SIGMA+1, size(kymogram, 2),'uint16'); kymogram; zeros(EDGE_SIGMA+1, size(kymogram, 2))], 'canny', EDGE_THRESH, EDGE_SIGMA );
[kymoThr, ~, ~, dy] = edge([fast_median(kymogram(1,:)')*ones(EDGE_SIGMA+1, size(kymogram, 2),'uint16');...
                             kymogram;...
                            repmat(kymogram(end,:), [EDGE_SIGMA+1, 1])],...
                             'canny', EDGE_THRESH, EDGE_SIGMA );

kymoThr = kymoThr & (dy<0);

kymoThr = kymoThr(EDGE_SIGMA+1:end-EDGE_SIGMA-1,:);
kymoThr(1,:) = 0;
kymoThr(end,:) = 0;
