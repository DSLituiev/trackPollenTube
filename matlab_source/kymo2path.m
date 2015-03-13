function [ z, kymoEdge, kymo ] = kymo2path(  varargin)
%KYMO2PATH(tifPath, rotate) -- extract edge path from a  kymogram
%
%   INPUT
% - tifPath    -- path to the input `tif` file (of a kymogram)
%                 OR a kymogram per se
% - rotate     -- rotate the input image (optional, boolean, default = false)
%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'tifPath', @(x)( (ischar(x) && exist(x, 'file')) || ( isnumeric(x) && (sum(size(x)>1)==2) ) ));
addParamValue(p, 'visualize',  false, @isscalar);
addParamValue(p, 'rotate', false, @(x)(isscalar(x)));
addParamValue(p, 'EDGE_SIGMA',  16, @isscalar);
addParamValue(p, 'EDGE_THRESH',  0, @isscalar);
addParamValue(p, 'KYMO_QUANTILE',  .9, @isscalar);

parse(p, varargin{:});
%% read the file or copy the array
if ischar(p.Results.tifPath)&& exist(p.Results.tifPath, 'file')
    if p.Results.rotate
        kymo = imread(p.Results.tifPath)';
    else
        kymo = imread(p.Results.tifPath);
    end
elseif isnumeric(p.Results.tifPath)
    kymo = p.Results.tifPath;
end

%== the upper quantile to be cut in the kymogram
%                         before threshold determination

q = quantile(kymo(:), p.Results.KYMO_QUANTILE);
kymo(kymo > q) = q;

% kymoThr = normalizeKymogramZeroOne(kymoThr);
kymoEdge = edge(kymo,'canny', p.Results.EDGE_THRESH, p.Results.EDGE_SIGMA );

kymoEdgeOnlyFw = automatonFilterRemoveBackWardMovements(kymoEdge, p.Results.visualize);

kymoEdgeOnlyFw(kymoEdgeOnlyFw<0) = 0;


if p.Results.visualize
    figure
    subplot(2,1,1)
    imagesc(kymoEdge)

    subplot(2,1,2)
    imagesc(kymoEdgeOnlyFw)
end

z =  edge2path( double(kymoEdgeOnlyFw) );

end

