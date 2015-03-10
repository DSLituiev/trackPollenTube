close all
clear all
clc

%% define paths to the functions
USERFNCT_PATH = '../dependencies';
addpath(USERFNCT_PATH);
addpath(fullfile(USERFNCT_PATH, 'MinMaxSelection'));
addpath(fullfile(USERFNCT_PATH, 'fastmedfilt1d'));
%% define path to the files

% SourceDir = '/media/Processing/Christina/WT/5mMCalcium/threshkymo/010714';
SourceDir = '..//testcases/Christina/threshkymo/230614';
fileName = '3.tif';
outRoiName = 'out.roi';
% R = 5;

tifPath = fullfile(SourceDir, fileName); 
outRoiPath = fullfile(SourceDir, outRoiName);

%% read and normalize the kymogram
kymo2roi( tifPath, outRoiPath, 0,1 );

%= NOW you can modify the ROI if it looks not as you expected
%% read the ROI
[path] = constructCurveROI(outRoiPath);

%= plot the ROI
figure
plot( path.x, path.y )
xlabel('time')
ylabel('curve length')
set(gca, 'ydir', 'reverse')
xlabel('time')
ylabel('coordinate')

speedFromSpline = diff(path.y)./diff(path.x);

speedFromSplineT = interp1(path.x(2:end), speedFromSpline, t, 'spline');

figure('name', 'speed from a saved ROI')
plot( path.x(2:end), speedFromSpline, 'gx')
ylim([min(0, 0.1*floor(10*min(speedFromSpline))), min(2, 0.1*ceil(10*max(speedFromSpline))) ])
hold all
plot([1, T], [0, 0], 'k-')
xlabel('time')
ylabel('speed')
plot( t , speedFromSplineT, 'r-')

fig(gcf)

export_fig 'test.pdf'
