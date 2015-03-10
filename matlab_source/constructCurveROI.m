function [PTroi, varargout] = constructCurveROI(roiPath, varargin)
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

if ~isempty(varargin)
    interpType = varargin{1};
else
    interpType = 'pchip';   
end

PTroi = ReadImageJROI(roiPath);

PTroi.x0 = PTroi.mnCoordinates(:,1);
PTroi.y0  = PTroi.mnCoordinates(:,2);

[N0, dx0] = arclength(PTroi.x0 , PTroi.y0, interpType);

r0 = (1+[0;cumsum(dx0)] );
r = 1+(0:1:round(N0))';

PTroi.xy = interp1(r0', PTroi.mnCoordinates, r, interpType);

PTroi.x = PTroi.xy(:,1);
PTroi.y = PTroi.xy(:,2);

PTroi.L = round(N0)+1;

%== frame
PTroi.frame = [PTroi.vnRectBounds(1), PTroi.vnRectBounds(2); PTroi.vnRectBounds(3), PTroi.vnRectBounds(4)]+1;
% PTroi.frame = [floor(min(PTroi.x)), floor(min(PTroi.y)); ceil(max(PTroi.x)), ceil(max(PTroi.y))];

if nargout>1   
   varargout{1} = PTroi.frame;
end
