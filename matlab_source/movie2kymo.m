function [ kymogram, mov, roi ] = movie2kymo( varargin )
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

addRequired(p, 'movPath', @(x)( (ischar(x) && exist(x, 'file')) || ( isnumeric(x) && (sum(size(x)>1)==3) ) ));
addRequired(p, 'roiPath', @(x)(ischar(x) && exist(x, 'file')) );
addOptional(p, 'kymoPath', '', @writable );
addParamValue(p, 'interpolation', 'l2', @(x)(any(strcmpi(x,{'l1', 'l2', 'm4'}))) );
addParamValue(p, 'm4epsilon', 16, @isscalar );
addParamValue(p, 'pad', 0, @isscalar );
parse(p, varargin{:});
%% read roi
roi = constructCurveROI(p.Results.roiPath);
%% read movie
if feval( @(x)(ischar(x) && exist(x, 'file')) , p.Results.movPath)
    [mov] = cropRectRoiFast(p.Results.movPath, roi, p.Results.pad);
elseif feval( ( isnumeric(x) && (sum(size(x)>1)==3) ),  p.Results.movPath)
    mov = p.Results.movPath;
end
%% trim ROI
roi.x0 = roi.x0 - roi.vnRectBounds(2) + p.Results.pad;
roi.y0 = roi.y0 - roi.vnRectBounds(1) + p.Results.pad;
roi.x = roi.x - roi.vnRectBounds(2) + p.Results.pad;
roi.y = roi.y - roi.vnRectBounds(1) + p.Results.pad;
%% construct kymogram
kymogram = constructKymogram(roi, mov, p.Results.interpolation, p.Results.m4epsilon);
%% save the kymogram if requested
if ~isempty(p.Results.kymoPath)    
    opts= {};
    fn = fieldnames(p.Unmatched);
    for ii = 1:numel(fn)
        opts = {opts{:}, fn{ii}, p.Unmatched.(fn{ii})};
    end
    imwrite(kymogram, p.Results.kymoPath, opts{:})
end

end

