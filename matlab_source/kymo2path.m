function [ z, kymoEdge, kymoThr ] = kymo2path( tifPath, rotate )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if nargin>1 && rotate
    kymoThr = imread(tifPath);
else
    kymoThr = imread(tifPath)';
end


kymoThr = normalizeKymogramZeroOne(kymoThr);

kymoEdge = edge(kymoThr);

z =  edge2path( double(kymoEdge) );

end

