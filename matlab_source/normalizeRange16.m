function [ image ] = normalizeRange16( image )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

image = image - min(image(:));
image = uint16( double(image) * (2^16 -1) / double(max(image(:))) );


end

