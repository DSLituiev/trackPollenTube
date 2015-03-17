function [ varargout ] = remove_static_bg( mov, varargin )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
% 'q' -- the lower quantile of the intensity among
%        t-points to be considered as background level
%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;
addRequired(p, 'movPath', @(x)( (ischar(x) && exist(x, 'file')) || ( isnumeric(x) && ( numel(size(x))==3 ) ) ) );
addOptional(p, 'outPath', '', @writable); %
addParamValue(p, 'q', 0.02, @isscalar );
parse(p, mov, varargin{:});
%%

if feval( @(x)(ischar(x) && exist(x, 'file')), p.Results.movPath)
    mov = readTifSelected(p.Results.movPath);
end
%%
minMov = uint16(quantile(single(mov), p.Results.q , 3));
mov = bsxfun( @minus, mov, minMov );
%== save the movie
if ~isempty(p.Results.outPath)
    saveastiff(mov, p.Results.outPath)
end
if nargout > 0
    varargout = {mov};
end
end

