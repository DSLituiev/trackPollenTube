function [ out ] = readable( x )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

out = (ischar(x) && exist(x, 'file'));

end

