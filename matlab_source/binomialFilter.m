function [ out ] = binomialFilter( N )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

out = zeros(N,1);
for k = 0:N-1
    out(k+1) = nchoosek(N-1,k);
end

out = out./sum(out);
end

