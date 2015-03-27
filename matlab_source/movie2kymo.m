function [ kymogram, mov, xy_roi ] = movie2kymo( varargin )
%MOVIE2KYMO -- applies an `(x,y)`-roi on a `(x,y,t)` movie  and returns
%a kymogram. If the third argument is set and is non-empty,
%saves the obtained kymogram.
%
% Input
% =====
% - movPath        -- path of the movie file
% - roiPath        -- path of the roi file
% - kymoPath       -- (optional; default: '') path for saving the kymogram;
%                      if not specified: does not save (default)
% - interpolation  -- (optional; default: `'l2'`) interpolation type;
%                      possible options: `'l1', 'l2', 'm4'`.
%                      see `constructKymogram` for details
% - m4epsilon      -- (optional; 16) kernel size for `m4` interpolation method
%
% Output
% ======
% - kymogram
% - mov
% - roi
%
%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'movPath', @(x)(readable(x) || ( isnumeric(x) && (sum(size(x)>1)==3) ) ));
addRequired(p, 'roiPath', @readable );
addOptional(p, 'kymoPath', false, @(x)( isempty(x) || islogical(x) || x==0 || x==1 || writable(x) )  );
addParamValue(p, 'interpolation', 'l2', @(x)(any(strcmpi(x,{'l1', 'l2', 'm4'}))) );
addParamValue(p, 'm4epsilon', 16, @isscalar );
addParamValue(p, 'pad', 10, @isscalar );
parse(p, varargin{:});
%% read input roi
xy_roi = CurveROI(p.Results.roiPath);
%% read movie
if feval( @(x)(ischar(x) && exist(x, 'file')) , p.Results.movPath)
    [mov, cropped_roi] = cropRectRoiFast(p.Results.movPath, xy_roi, p.Results.pad);
elseif feval( ( isnumeric(x) && (sum(size(x)>1)==3) ),  p.Results.movPath)
    mov = p.Results.movPath;
    %% trim ROI
    cropped_roi = CurveROI('PolyLine', xy_roi.x0 - xy_roi.vnRectBounds(2)+ p.Results.pad,...
        xy_roi.y0 - xy_roi.vnRectBounds(1) + p.Results.pad);
end
%% construct kymogram
kymogram = constructKymogram(cropped_roi, mov, p.Results.interpolation, p.Results.m4epsilon);
%% save the kymogram if requested
if ischar(p.Results.kymoPath)
    kymoPath = p.Results.kymoPath;
elseif p.Results.kymoPath
    pathstr = fileparts(p.Results.tifPath);
    kymoPath = fullfile(pathstr, 'kymo.tif');
else
    kymoPath = '';
end

if  ~isempty( kymoPath )
    opts= {};
    fn = fieldnames(p.Unmatched);
    for ii = 1:numel(fn)
        opts = {opts{:}, fn{ii}, p.Unmatched.(fn{ii})};
    end
    imwrite(kymogram, kymoPath, opts{:})
end

end

