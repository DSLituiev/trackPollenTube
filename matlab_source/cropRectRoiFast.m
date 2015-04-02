function [movie, varargout] = cropRectRoiFast(varargin)
%== requires 'ReadImageJROI' function

%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'movPath', @(x)(readable(x) || is3dstack(x) ));
addRequired(p, 'roiPath', @(x)( readable(x)  || isstruct(x) || isobject(x)) );
addOptional(p, 'pad', 0, @isscalar );
addOptional(p, 'frames', [1, Inf], @isnumeric );
parse(p, varargin{:});
%%
[~, ROI] = processRoiInput(p.Results.roiPath);

cropped_roi = CurveROI(ROI);

if ~isempty(ROI.vnRectBounds)    
    x_from = max(0, ROI.vnRectBounds(1) - p.Results.pad) + 1;
    x_to = ROI.vnRectBounds(3) + p.Results.pad + 1;
    y_from = max(0, ROI.vnRectBounds(2) - p.Results.pad) + 1;
    y_to = ROI.vnRectBounds(4) + p.Results.pad + 1;
    
    cropped_roi.x0 = ROI.x0 - y_from + 1;
    cropped_roi.y0 = ROI.y0 - x_from + 1;
    
    cropped_roi.x0 = ROI.x0 - y_from + 1;
    cropped_roi.y0 = ROI.y0 - x_from + 1;
    cropped_roi.interp();
    cropped_roi.calc_bounds();
    cropped_roi.original_vnRectBounds = ROI.vnRectBounds;
    
else
    x_from = 1;
    y_from = 1;
    x_to = Inf;
    y_to = Inf;
end

if readable(p.Results.movPath)
    movie = readTifSelected(p.Results.movPath, ...
        [x_from , x_to ],...
        [y_from , y_to ], p.Results.frames);
else
    T = size( p.Results.movPath, 3);
    if ~isempty(p.Results.frames)
        t_from = max(1, p.Results.frames(1));
        t_to = min(T, p.Results.frames(end));
    else
        t_from = 1;
        t_to = T;
    end
    movie = p.Results.movPath( x_from:x_to, y_from:y_to, t_from:t_to );
end

if nargout>1
    varargout{1} = cropped_roi;
    varargout{2} = ROI.vnRectBounds;
end