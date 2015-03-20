function [ f ] = plot_snapshot_roi( mov, xy_roi, t)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if t > size(mov,3)
    t = floor( size(mov,3) / 3 );
end

f = figure('name', sprintf('frame %u', t));

imagesc( mov(:,:, t ))
hold all
plot(xy_roi.x, xy_roi.y, 'w-', 'linewidth', 2.5)
plot(xy_roi.x, xy_roi.y, 'k-', 'linewidth', 2)
plot(xy_roi.x0, xy_roi.y0, 'wx','linewidth', 2.5, 'markersize', 7.5)
plot(xy_roi.x0, xy_roi.y0, 'kx', 'linewidth', 2, 'markersize', 7)

end

