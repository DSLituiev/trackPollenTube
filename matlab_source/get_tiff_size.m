function [ movDims ] = get_tiff_size( movPath )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
if ischar(movPath)
InfoImage    = imfinfo(movPath);
movDims = [0,0,0];
movDims(1) = InfoImage(1).Height;
movDims(2) = InfoImage(1).Width;
movDims(3) = numel(InfoImage);
elseif is3dstack(movPath)
    movDims = size(movPath);
else
    movDims = [0, 0, 0];
    warning('get_tiff_size:wrong_type','wrong input type!')
end

end

