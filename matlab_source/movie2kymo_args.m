function [ cropped_roi, mov, varargout] = movie2kymo_args( varargin )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'movPath', @(x)(readable(x) || is3dstack(x) ) );
addOptional(p, 'roiPath', '', @(x)(readable(x) || writable(x) || isobject(x) ) );
addOptional(p, 'kymoPath', false, @(x)( isempty(x) || islogical(x) || isscalar(x) && (x==0 || x==1) || writable(x) )  );
addParamValue(p, 'interpolation', 'l2', @(x)(any(strcmpi(x,{'l1', 'l2', 'm4'}))) );
addParamValue(p, 'm4epsilon', 16, @isscalar );
addParamValue(p, 'pad', 10, @isscalar );
parse(p, varargin{:});
%% read input roi
if isempty(p.Results.roiPath)
    roiPath = replace_extension(p.Results.movPath, 'roi');
else
    roiPath = p.Results.roiPath;   
end
xy_roi = CurveROI(roiPath);
%% read movie
if feval( @readable, p.Results.movPath)
    movPath = p.Results.movPath;
    [mov, cropped_roi, vnRectBounds] = cropRectRoiFast(p.Results.movPath, xy_roi, p.Results.pad);
elseif is3dstack(p.Results.movPath)
    movPath = '';
    mov = p.Results.movPath;
    vnRectBounds = [1, size(mov,1), 1, size(mov,2)];
    % trim ROI
    cropped_roi = CurveROI(ROI);
    cropped_roi.x0 = ROI.x0 - ROI.vnRectBounds(2) + p.Results.pad;
    cropped_roi.x0 = ROI.y0 - ROI.vnRectBounds(1) + p.Results.pad;
    cropped_roi.calc_bounds();
end
%%
    function out = save_xy(varargin)
        fprintf('saving xy ROI\n')
        out = varargin;
    end
%%
if isempty(xy_roi.x0) || isempty(xy_roi.y0) || isempty(xy_roi.vnRectBounds)
    fh = xy_roi.plot(mov);
    ls_xy_saving = addlistener( xy_roi,'Saving', @save_xy );
    title('No ROI has been provided. Please draw one!')
    waitfor(fh);
    if isempty(xy_roi.x0)
        error('no ROI has been drawn. Exiting')
    end
    [mov, cropped_roi, vnRectBounds] = cropRectRoiFast(mov, xy_roi, p.Results.pad);
else
    cropped_roi.filename = replace_extension(xy_roi.filename, '-crop.roi');
end

if ischar(p.Results.kymoPath)
    kymoPath = p.Results.kymoPath;
elseif p.Results.kymoPath
    pathstr_ = fileparts(p.Results.tifPath);
    kymoPath = fullfile(pathstr_, 'kymo.tif');
else
    kymoPath = '';
end
varargout = {p.Results.interpolation, p.Results.m4epsilon, roiPath, kymoPath, movPath, p.Unmatched};
end

