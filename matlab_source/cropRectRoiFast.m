function [movie, varargout] = cropRectRoiFast(varargin)
%== requires 'ReadImageJROI' function

%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'movPath', @(x)(ischar(x) && exist(x, 'file')) );
addRequired(p, 'roiPath', @(x)( (ischar(x) && exist(x, 'file')) || (isstruct(x)) || (isobject(x)) ));
addOptional(p, 'padding', 0, @isscalar );
addOptional(p, 'frames', [], @isnumeric );
parse(p, varargin{:});
%%
[frame, ROI] = processRoiInput(p.Results.roiPath);

movie = readTifSelected(p.Results.movPath, ...
    1 + [max(0, ROI.vnRectBounds(1) - p.Results.padding) , ROI.vnRectBounds(3) + p.Results.padding ],...
    1 + [max(0, ROI.vnRectBounds(2) - p.Results.padding) , ROI.vnRectBounds(4) + p.Results.padding ], p.Results.frames);

% movie = readTifSelected(p.Results.movPath, ...
%     [max(0, frame(1,1) - p.Results.padding) , frame(2,1) + p.Results.padding ],...
%     [max(0, frame(1,2) - p.Results.padding) , frame(2,2) + p.Results.padding ]);

if nargout>1
    varargout{1} = ROI;
    varargout{2} = frame;
end