close all
clear all
clc

%% define paths to the functions
USERFNCT_PATH = '/media/Processing/MATLABuserfunctions';
addpath(USERFNCT_PATH);
addpath(fullfile(USERFNCT_PATH, 'MinMaxSelection'));
addpath(fullfile(USERFNCT_PATH, 'fastmedfilt1d'));
%% define path to the files

% SourceDir = '/media/Processing/Christina/WT/5mMCalcium/threshkymo/010714';
SourceDir = '..//testcases/Christina/threshkymo/230614';
fileName = '3.tif';
outRoiName = 'out.roi';
% R = 5;
lineWidth = 3;

tifPath = fullfile(SourceDir, fileName); 
outRoiPath = fullfile(SourceDir, outRoiName);

%% read and normalize the kymogram
kymoThr = imread(tifPath)';

kymoThr = normalizeKymogramZeroOne(kymoThr);

figure
imagesc(kymoThr)
% 
% figure
% p = surf( double(kymoThr )); set(p, 'linestyle', 'none'); view(0,90)

%% construct the curve based on the thresholded kymogram
kymoEdge = edge(kymoThr);

figure
imagesc(kymoEdge)

z =  constructPathUsingKymogramNeighbourhood(kymoThr);

T = numel(z);
t = 1:T;

figure
imagesc( (2^8-1)*uint8(kymoEdge) )
hold on
plot(z, 'k', 'linewidth', lineWidth)

%% analyse the speed
BINOM_FILTER = [1 4 6 4 1]';
% BINOM_FILTER = [1, 6, 15, 20, 15, 6, 1]';
BINOM_FILTER = BINOM_FILTER./sum(BINOM_FILTER(:));
smoothZ = conv( [z(1)*ones(numel(BINOM_FILTER),1) ; z; z(end)*ones(numel(BINOM_FILTER),1) ], BINOM_FILTER, 'same' );
smoothZ = smoothZ(numel(BINOM_FILTER)+1: end - numel(BINOM_FILTER));

speedRawFiltered = diff( smoothZ, 1);
%% plot speed 
figure
plot(t(2:end-2), speedRawFiltered(2:end-1) );
ylim([0, min(2, 0.1*ceil(10*max(speedRawFiltered))) ])
hold all
plot([1, T], [0, 0], 'k-')
xlabel('time')
ylabel('speed')

%% select control points (with highest second derivative + equally spaced ones)
%= you do not wish to edit control points for each frame if something goes
%=  wrong with the segmentation. Therefore, select only a few ones.

%= compute second derivative
d2z = diff( double(z), 2);

%= define constants to downsample your time frames
REDUCT_FACTOR = 2^5;
N_EXTR = floor(numel(d2z)/(REDUCT_FACTOR));

%= find 'N_EXTR' extrema in the second derivative
[ maxd2x, maxd2xInds] = maxk( abs(d2z), N_EXTR );

%= trash points with |second derivative| <= 1
maxd2xInds = maxd2xInds(maxd2x>1);
%= shift up by one to correct for reduciton of frame points due to differencing
maxd2xInds = maxd2xInds +1;


spacedInds = (1:REDUCT_FACTOR:T)';
allInds = sort( [spacedInds; maxd2xInds; T]);
%= decimate cluttered control points
cluttered = find(diff(allInds)==1);
allInds(cluttered(2:2:end)) = [];

figure
imagesc( (2^8-1)*uint8(kymoThr) )
hold on
plot(z, 'k', 'linewidth', lineWidth)

plot(t(allInds) , z(allInds) , 'xr:', 'linewidth', lineWidth)
%% write the ROI
writeImageJRoi(outRoiPath, 'PolyLine', uint16(t(allInds)) , uint16(z(allInds)) )

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
