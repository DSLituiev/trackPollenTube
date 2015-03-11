function  z = edge2path(kymoEdge, varargin)

%== Constants
MEDIAN_RADIUS = 5;
% BURST_Z_TOLERANCE = 5; %= pixels before the final point reached


if ImageProcessingToolboxAvailable()
    z = edge2path_im_pr( kymoEdge, MEDIAN_RADIUS );
else
    z = edge2path_makeshift( kymoEdge, MEDIAN_RADIUS );
end


