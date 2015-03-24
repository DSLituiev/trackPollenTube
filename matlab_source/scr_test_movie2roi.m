
close all
clear all
clc
%% include dependencies
includeDependencies( )
% addpath('/usr/local/MATLAB/R2013b/bin/glnxa64/') % libtiff
%% define path to the files
SourceDir = '../testcases/QAN_WT_017_23112012_Rg14burst';
fileName = 'dsRed-a-c.tif';
inRoiName = 'path.roi';
outKymoName = 'kymo.tif';
outRoiName = 'kymo.roi';

tifPath = fullfile(SourceDir, fileName); 
inRoiPath = fullfile(SourceDir, inRoiName);
outKymoPath = fullfile(SourceDir, outKymoName);
outRoiPath = fullfile(SourceDir, outRoiName);
%%
[ kymogram, mov, xy_roi, rt_roi ] = movie2roi( tifPath, inRoiPath, true, 1, 0, 'pad', 10 );

figure
imagesc( kymogram )
imwrite(kymogram, outKymoPath)

tt = 620; % ceil(size(mov,3)*4/5);
f = plot_snapshot_roi( mov, xy_roi, tt);

%% 
ff = visualize_kymo3D(tifPath, kymogram, xy_roi, rt_roi, tt);
view(-15, 40)
% export_fig kymo3D.png  -nocrop -r300
% exportfig(ff, 'kymo3D.png', 'Format', 'png', 'Color', 'rgb', 'Resolution', 300)

ff = rt_roi.plot(kymogram, 1, 10, 'color', 'g', 'rotate', true, 'x', '$r$', 'y', '$t$', 'linewidth', 0.7);
set(gca, 'ydir', 'normal')
exportfig(ff, 'kymo.png', 'Format', 'png', 'Color', 'rgb', 'Resolution', 300, 'FontSizeMin', 10, 'Width', 2)

ff = xy_roi.plot(tifPath, tt, 10, 'color', 'm', 'tick_spacing', 50, 'linewidth', 0.7);

exportfig(ff, 'frameBurst.png', 'Format', 'png', 'Color', 'rgb', 'Resolution', 300, 'FontSizeMin', 10, 'Width', 2)