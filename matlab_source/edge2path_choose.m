function  z = edge2path(kymoEdge, varargin)
%EDGE2PATH -- returns coordinates of the edge of a kymogram

%== Constants
MEDIAN_RADIUS = 5;
% BURST_Z_TOLERANCE = 5; %= pixels before the final point reached


if ImageProcessingToolboxAvailable()
    z = edge2path( kymoEdge, MEDIAN_RADIUS );
else
    z = edge2path_makeshift( kymoEdge, MEDIAN_RADIUS );
end


