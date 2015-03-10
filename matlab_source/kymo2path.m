function [ z, kymoEdge, kymoThr ] = kymo2path( tifPath, rotate )
%KYMO2PATH(tifPath, rotate) -- extract edge path from a thresholded kymogram
%
%   INPUT
% - tifPath    -- path to the input `tif` file (of a thresholded kymogram)
% - rotate     -- rotate the input image (optional, boolean, default = false)

if nargin>1 && rotate
    kymoThr = imread(tifPath);
else
    kymoThr = imread(tifPath)';
end

% kymoThr = normalizeKymogramZeroOne(kymoThr);
kymoEdge = edge(kymoThr);
z =  edge2path( double(kymoEdge) );

end

