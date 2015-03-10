function [ovalRoi, varargout] = cropOvalROI(ovalRoi, rectCropRoi)
% crops the oval ROI with the provided rectangular ROI frame
% the second argument can be whether a ROI object or a path to the ROI


%% check if the inputs are paths or a structures
[rectFrame, rectCropRoi] = processRoiInput(rectCropRoi);
[~, ovalRoi] = processRoiInput(ovalRoi);

 ovalRoi.vnRectBounds([1,3]) = ovalRoi.vnRectBounds([1,3]) - rectCropRoi.vnRectBounds(1);
 ovalRoi.vnRectBounds([2,4]) = ovalRoi.vnRectBounds([2,4]) - rectCropRoi.vnRectBounds(2);

if strcmpi( ovalRoi.strType, 'Oval')
    ovalRoi.Cy = 0.5 * (ovalRoi.vnRectBounds(3) + ovalRoi.vnRectBounds(1) );
    ovalRoi.Cx = 0.5 * (ovalRoi.vnRectBounds(4) + ovalRoi.vnRectBounds(2) );  
    ovalRoi.Ry = 0.5 * (ovalRoi.vnRectBounds(3) - ovalRoi.vnRectBounds(1) );
    ovalRoi.Rx = 0.5 * (ovalRoi.vnRectBounds(4) - ovalRoi.vnRectBounds(2) );
else
    error('cropOvalROI:WrongRoiType', 'the ROI\t%s\n\t is not of ''Oval'' type', ovalRoi);
end

ovalRoi = rmfield(ovalRoi, {'nStrokeWidth', 'nStrokeColor', 'nFillColor', 'bSplineFit', 'nVersion', 'strType'});

if nargout>1
    varargout{1} = rectCropRoi;
    varargout{2} = [diff(rectCropRoi.vnRectBounds([1,3])), diff(rectCropRoi.vnRectBounds([2,4]))]+1;
end


    %== ROI.vnRectBounds:    ['nTop',  'nLeft' , 'nBottom'  , 'nRight']
    %=             frame:    ['ymin',  'xmin'  , 'ymax'     , 'xmax'] 