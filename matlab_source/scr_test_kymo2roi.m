close all
clear all
clc
%% include dependencies
includeDependencies( )

%% define path to the files
% SourceDir = '../testcases/Christina/threshkymo/230614';
% fileName = '3.tif';
% outRoiName = 'out.roi';
SourceDir = '../testcases/QAN_WT_023_25112012_Rg14burst_Rg14fer'; % 017_23112012_Rg14burst';%
fileName = 'kymo.tif';
outRoiName = 'kymo.roi';
outImg = 'out.png';

tifPath = fullfile(SourceDir,  fileName);
outRoiPath = fullfile(SourceDir, outRoiName);
outImgPath = fullfile(SourceDir, outImg);

%% read the roi and overay it over the kymogram
% f = plot_roi_on_kymo(outRoiPath, tifPath, outImg, 'png', 'Resolution', 300);
%% segment the kymogram and save the roi
[rt_roi0, status] = kymo2roi( tifPath, outRoiPath,  0);
%% read the roi and overay it over the kymogram
[f, rt_roi] = plot_roi_on_kymo(outRoiPath, tifPath, outImgPath, 'png', 'Resolution', 300);