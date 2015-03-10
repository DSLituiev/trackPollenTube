function [movie, varargout] = cropRectRoiFast(movie, roiPath)
%== requires 'ReadImageJROI' function

[frame, ROI] = processRoiInput(roiPath);

movie = readTifSelected(movie, [frame(1,1),frame(2,1)], [ frame(1,2),frame(2,2)]);

if nargout>1
    varargout{1} = ROI;
    varargout{2} = frame;
end