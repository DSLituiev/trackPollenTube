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
outRoiName = 'out.roi';
outImg = 'out.png';

tifPath = fullfile(SourceDir,  fileName);
outRoiPath = fullfile(SourceDir, outRoiName);
outImgPath = fullfile(SourceDir, outImg);

kymo2roi2plot( tifPath, outRoiPath, outImgPath);