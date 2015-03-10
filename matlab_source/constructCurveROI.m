function [path, varargout] = constructCurveROI(roiPath, varargin)
%CONSTRUCTCURVEROI(roiPath, varargin) -- gets ROI points given an ImageJ ROI file path
% 
% === Input:
% - roiPath   -- file path to the imageJ ROI (curve)
%
% === Output:
% - [path.x, path.y]        -- the vectors of [x, y] coordinates of the spline
%                interpoalted curved roi

if ~isempty(varargin)
    interpType = varargin{1};
else
    interpType = 'pchip';   
end

PTroi = ReadImageJROI(roiPath);

path.x0 = PTroi.mnCoordinates(:,1);
path.y0  = PTroi.mnCoordinates(:,2);

[N0, dx0] = arclength(path.x0 , path.y0, interpType);

r0 = (1+[0;cumsum(dx0)] );
r = 1+(0:1:round(N0))';

% curve = cscvn1(PTroi.mnCoordinates') ;

% path.xy = spline(r0, PTroi.mnCoordinates', r)';
% path.xy = pchip(r0, PTroi.mnCoordinates', r)';
% path.xy = cscvn(points) 
path.xy = interp1(r0', PTroi.mnCoordinates, r, interpType);

path.x = path.xy(:,1);
path.y = path.xy(:,2);

path.L = round(N0)+1;
%== frame
if nargout>1
   varargout{2} = [floor(min(path.x)), floor(min(path.y)); ceil(max(path.x)), ceil(max(path.y))];
end

% clear x x0
