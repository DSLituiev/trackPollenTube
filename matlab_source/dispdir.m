function [ varargout ] = dispdir( SourceDir )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


fprintf('current directory content:\n')
fprintf('===========================================\n')
dir(SourceDir)
fprintf('===========================================\n')
if nargout> 0
    varargout{1} = dir(SourceDir);
end

end

