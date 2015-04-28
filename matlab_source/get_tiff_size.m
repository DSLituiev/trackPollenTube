function [ movDims ] = get_tiff_size( movPath )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
if ischar(movPath)
    InfoImage    = imfinfo(movPath);
    movDims = [0,0,0];
    movDims(1) = InfoImage(1).Height;
    movDims(2) = InfoImage(1).Width;
    
    FileID = Tiff(movPath, 'r');
    try
        out = regexpi(FileID.getTag('ImageDescription'), 'channels=(\d*)\n', 'tokens');
        channels = str2double(out{1});
    catch
        channels = 1;
    end
    
    if isempty(channels)
        warning('number of channels not found; setting to 1')
        channels = 1;
    end
    
    movDims(3) = channels;
    movDims(4) = floor(NumberImages/channels);
    
elseif is3dstack(movPath) || is4dstack(movPath)
    movDims = size(movPath);
else
    movDims = [0, 0, 0];
    warning('get_tiff_size:wrong_type','wrong input type!')
end

end

