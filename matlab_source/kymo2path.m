function [ z, kymoEdge, kymo ] = kymo2path( tifPath, rotate,  varargin)
%KYMO2PATH(tifPath, rotate) -- extract edge path from a  kymogram
%
%   INPUT
% - tifPath    -- path to the input `tif` file (of a kymogram)
%                 OR a kymogram per se
% - rotate     -- rotate the input image (optional, boolean, default = false)

if ischar(tifPath)&& exist(tifPath, 'file')
    if nargin>1 && rotate
        kymo = imread(tifPath);
    else
        kymo = imread(tifPath)';
    end
elseif isnumeric(tifPath)
    kymo = tifPath;
end
    
EDGE_THRESH = 0;
EDGE_SIGMA = 16;


KYMO_QUANTILE = 0.90;  %== the upper quantile to be cut in the kymogram
%                         before threshold determination

q = quantile(kymo(:), KYMO_QUANTILE);
kymo(kymo > q) = q;

% kymoThr = normalizeKymogramZeroOne(kymoThr);
kymoEdge = edge(kymo,'canny', EDGE_THRESH, EDGE_SIGMA );

kymoEdgeOnlyFw = automatonFilterRemoveBackWardMovements(kymoEdge);

kymoEdgeOnlyFw(kymoEdgeOnlyFw<0) = 0;

if nargin<3
    visualize = false;
else
    visualize = varargin{1};
end
if visualize
    figure
    subplot(1,2,1)
    imagesc(kymoEdge)

    subplot(1,2,2)
    imagesc(kymoEdgeOnlyFw)
end

z =  edge2path( double(kymoEdgeOnlyFw) );

end

