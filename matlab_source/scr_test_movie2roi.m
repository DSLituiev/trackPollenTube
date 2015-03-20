
close all
clear all
clc
%% include dependencies
includeDependencies( )
% addpath('/usr/local/MATLAB/R2013b/bin/glnxa64/') % libtiff
%% define path to the files
SourceDir = '/home/dima/data/pollen_tubes/Hannes PT Growth'; % '../testcases/QAN_WT_023_25112012_Rg14burst_Rg14fer';
fileName = '1sec_delay5.tif'; % 'dsRed-a-b.tif';
inRoiName = '1sec_delay5.roi'; % 'path.roi';
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

tt = 364; % ceil(size(mov,3)*4/5);
f = plot_snapshot_roi( mov, xy_roi, tt);

%% 
ff = visualize_kymo3D(tifPath, kymogram, xy_roi, rt_roi);

rt_roi.plot(outKymoPath);

xy_roi.plot(tifPath, tt);