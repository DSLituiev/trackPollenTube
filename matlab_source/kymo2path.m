function [ z, kymoEdge, kymoThr ] = kymo2path( tifPath )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

kymoThr = imread(tifPath)';

kymoThr = normalizeKymogramZeroOne(kymoThr);

kymoEdge = edge(kymoThr);

z =  edge2path( double(kymoEdge) );

end

