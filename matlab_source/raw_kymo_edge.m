function [kymoEdge, grdiff] = raw_kymo_edge(kymo, sigma, threshold)
% uses a public domain canny routine which allows anisotropic sigma
% and can be [and is] modified to output gradient
% the gradient is used to exclude senseless edges
% as here one looks for edges from bright on top to dark on bottom,
% or dark on left and bright on right, we exlude the rest.

[kymoEdge, ~, gr] = canny(kymo, sigma, threshold);
grdiff =  gr{1}-gr{2};
kymoEdge( grdiff > 0) = 0;

%         figure; imagesc(gr{2}-gr{1})
end