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

%% read the ROI
[path] = constructCurveROI(outRoiPath);

%= plot the ROI
figure
plot( path.y, path.x )
xlabel('time')
ylabel('curve length')
set(gca, 'ydir', 'reverse')
xlabel('time')
ylabel('coordinate')

speedFromSpline = diff(path.y)./diff(path.x);

T = numel(z);
t = 1:T;
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
