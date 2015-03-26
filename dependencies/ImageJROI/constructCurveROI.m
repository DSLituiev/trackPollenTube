function [PTroi, varargout] = constructCurveROI(PTroi, varargin)
%CONSTRUCTCURVEROI(roiPath, varargin) -- gets ROI points given an ImageJ ROI file path
%
% Input:
% ======
% - roiPath     -- file path to the imageJ ROI (curve)
% - interpType  -- interpolation method (optional, default = 'pchip')
%
% Output:
% =======
% - path        -- a structure with fields:
%        - path.x,
%        - path.y
%              -- the vectors of [x, y] coordinates of the spline
%                 interpoalted curved roi

%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;
addRequired(p, 'PTroi', @(x)( (ischar(x) && exist(x, 'file') ) || isobject(x) || isstruct(x) ) );
addOptional(p, 'interp1', 'pchip', @(x)strcmpi(x, {'linear','pchip'}) );
parse(p, PTroi, varargin{:});
%% read roi if a file path is provided
if feval( @(x)(ischar(x) && exist(x, 'file')) , PTroi)
    PTroi = ReadImageJROI(PTroi);
end
%%
PTroi.x0 = PTroi.mnCoordinates(:,1);
PTroi.y0  = PTroi.mnCoordinates(:,2);

%%
[PTroi.x, PTroi.y, ~, ~, arc_length] = interp_implicit(PTroi.x0, PTroi.y0, p.Results.interp1);

PTroi.L = round(arc_length)+1;

%== frame
PTroi.frame = [PTroi.vnRectBounds(1), PTroi.vnRectBounds(2); PTroi.vnRectBounds(3), PTroi.vnRectBounds(4)]+1;
% PTroi.frame = [floor(min(PTroi.x)), floor(min(PTroi.y)); ceil(max(PTroi.x)), ceil(max(PTroi.y))];

if nargout>1
    varargout{1} = PTroi.frame;
end
