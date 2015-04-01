function [ varargout ] = movie2kymo( varargin )
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

%% process arguments
[cropped_roi, mov, interpolation, m4epsilon, roiPath, kymoPath, movPath] = movie2kymo_args( varargin{:} );
%% construct kymogram
kymogram = constructKymogram(cropped_roi, mov, interpolation, m4epsilon);
%% save the kymogram if requested


if  ~isempty( kymoPath )
    opts= {};
    fn = fieldnames(p.Unmatched);
    for ii = 1:numel(fn)
        opts = {opts{:}, fn{ii}, p.Unmatched.(fn{ii})};
    end
    imwrite(kymogram, kymoPath, opts{:})
end

varargout = {kymogram, mov, cropped_roi, roiPath, kymoPath, movPath, interpolation, m4epsilon};

end

