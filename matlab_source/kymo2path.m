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
addParamValue(p, 'EDGE_SIGMA',  8, @isscalar);
addParamValue(p, 'EDGE_THRESH',  [], @isscalar);
addParamValue(p, 'KYMO_QUANTILE',  .8, @isscalar);

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

    function kymoEdge = raw_edge(kymo, sigma, threshold)        
        % uses a public domain canny routine which allows anisotropic sigma
        % and can be [and is] modified to output gradient
        % the gradient is used to exclude senseless edges
        % as here one looks for edges from bright on top to dark on bottom,
        % or dark on left and bright on right, we exlude the rest.
        [kymoEdge, ~, gr] = canny(kymo, sigma, threshold);
        kymoEdge( gr{2}-gr{1} < 0) = 0;
    end

kymoEdge = raw_edge(single(kymo), p.Results.EDGE_SIGMA, p.Results.EDGE_THRESH );

kymoEdgeOnlyFw = automatonFilterRemoveBackWardMovements(kymoEdge, 0);

if p.Results.visualize
    figure
    subplot(3,1,1)
    imagesc(kymo)
    
    subplot(3,1,2)
    imagesc(kymoEdge)
    
    subplot(3,1,3)
    imagesc(kymoEdgeOnlyFw)
end

kymoEdgeOnlyFw(kymoEdgeOnlyFw<0) = 0;

z =  edge2path( double(kymoEdgeOnlyFw) );

end

