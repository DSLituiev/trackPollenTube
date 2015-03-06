function varargout = processRoiInput(roiPath)

if ischar(roiPath)&& exist(roiPath, 'file')
    %== read the ROI
    ROI = ReadImageJROI(roiPath); 
    %== ROI.vnRectBounds:    ['nTop',  'nLeft' , 'nBottom'  , 'nRight']
    %=             frame:    ['ymin',  'xmin'  , 'ymax'     , 'xmax'] 
    frame = [ROI.vnRectBounds(1), ROI.vnRectBounds(2); ROI.vnRectBounds(3), ROI.vnRectBounds(4)]+1;
    % frameInd = {(ROI.vnRectBounds(1):ROI.vnRectBounds(3))+1, (ROI.vnRectBounds(2):ROI.vnRectBounds(4))+1};
elseif isstruct(roiPath)&& all(isfield(roiPath, {'vnRectBounds','strType'}))
    %== take the ROI supplied in the native format
    ROI = roiPath;
    frame = [roiPath.vnRectBounds(1), roiPath.vnRectBounds(2);roiPath.vnRectBounds(3), roiPath.vnRectBounds(4)]+1;
elseif   isnumeric(roiPath)
    %== take the ROI supplied in the 'frame' format
    %= frame: ['ymin', 'xmin'; 'ymax', 'xmax'] 
    ROI.vnRectBounds = roiPath([1,3,2,4])-1;
    frame = roiPath;
else
    error('processRoiInput:unknownRoiFormat', 'unknown ROI format')
end

varargout = {frame, ROI};