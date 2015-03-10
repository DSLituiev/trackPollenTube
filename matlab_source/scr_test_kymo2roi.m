close all
clear all
clc
%% include dependencies
includeDependencies( )

%% define path to the files
SourceDir = '..//testcases/Christina/threshkymo/230614';
fileName = '3.tif';
outRoiName = 'out.roi';

tifPath = fullfile(SourceDir, fileName); 
outRoiPath = fullfile(SourceDir, outRoiName);

%% read and normalize the kymogram
kymo2roi( tifPath, outRoiPath, 0,1 );

%= NOW you can modify the ROI if it looks not as you expected