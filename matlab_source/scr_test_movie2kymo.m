
close all
clear all
clc
%% include dependencies
includeDependencies( )
addpath('/usr/local/MATLAB/R2013b/bin/glnxa64/') % libtiff
%% define path to the files
SourceDir = '..//testcases/QAN_WT_017_23112012_Rg14burst';
fileName = 'dsRed-a-c.tif';
inRoiName = 'path.roi';

tifPath = fullfile(SourceDir, fileName); 
inRoiPath = fullfile(SourceDir, inRoiName);

[ kymogram, mov, xy_roi ] = movie2kymo( tifPath, inRoiPath );

figure
imagesc( kymogram )


figure
imagesc( mov(:,:, ceil(end*2/5) ))
hold all
plot(xy_roi.x, xy_roi.y, 'k-')

%% 
outRoiName = 'out.roi';
outRoiPath = fullfile(SourceDir, outRoiName);
kymo2roi( kymogram, outRoiPath, 0,1 );
