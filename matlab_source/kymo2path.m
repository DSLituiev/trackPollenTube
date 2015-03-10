function [ z, kymoEdge, kymoThr ] = kymo2path( tifPath, rotate )
%KYMO2PATH(tifPath, rotate) -- extract edge path from a (thresholded) kymogram
%
%   INPUT
% - tifPath    -- path to the input `tif` file (of a kymogram)
%                 OR a kymogram per se
% - rotate     -- rotate the input image (optional, boolean, default = false)

if ischar(tifPath)&& exist(tifPath, 'file')
    if nargin>1 && rotate
        kymoThr = imread(tifPath);
    else
        kymoThr = imread(tifPath)';
    end
elseif isnumeric(tifPath)
    kymoThr = tifPath;
end
    
EDGE_THRESH = 0;
EDGE_SIGMA = 16;

% kymoThr = normalizeKymogramZeroOne(kymoThr);
kymoEdge = edge(kymoThr,'canny', EDGE_THRESH, EDGE_SIGMA );

z =  edge2path( double(kymoEdge) );

end

