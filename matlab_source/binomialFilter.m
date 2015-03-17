function [ out ] = binomialFilter( N )
%BINOMIALFILTER(N) constructs a normalized binomial filter of diameter N
% note that N usually should be an odd number

out = zeros(N,1);
for k = 0:N-1
    out(k+1) = nchoosek(N-1,k);
end

out = out./sum(out);
end

