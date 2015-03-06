clear all
close all
clc
%% input path

inMoviePath = fullfile(folderPath , 'dsRED-a.tif');
inRoiPath = fullfile(folderPath , 'crop.roi');
outKymoRawPath = fullfile(folderPath, 'kymoraw.tif');
outKymoThrPath = fullfile(folderPath, 'kymothr.tif');


%% Constants
EXT = 'tif';          %=  picture file format
BG_QUANTILE = 0.02;    %== the lower quantile of the intensity among
%                         t-points to be considered as background level
EDGE_SIGMA = 16;
KYMO_QUANTILE = 0.90;  %== the upper quantile to be cut in the kymogram
%                         before threshold determination
THR_COEFF = 0.8;      %== threshold reduction factor for the kymogram thresholding
M4_EPSILON = 16;
KYMO_INTERPOLATION_METHOD = 'l2';
%% read a part of movie
%= (only a small rectangular area including the ROI, for speed and memory)
mov = cropRectRoiFast(inMoviePath , inRoiPath);

%% optionally: background subtraction

minMov = uint16(quantile(single(mov), BG_QUANTILE , 3));
mov = bsxfun( @minus, mov, minMov );

clear minMov
%% get ROI, get kymogram, threshold, and save it

%== get the coordinates from the input ROI
tubepath = constructCurveROI(inRoiPath);

%== obtain the kymogram
tic
kymogram = constructKymogram(tubepath, mov, KYMO_INTERPOLATION_METHOD, M4_EPSILON);

% figure; imagesc(kymogram)

fprintf('constructing the kymogram took\t%3.1f\ts\n',toc)

%== threshold the kymogram
kymoThr = edgeKymogram(kymogram, KYMO_QUANTILE, EDGE_SIGMA);
%== save the kymogram
imwrite(kymogram, outKymoRawPath , EXT)

imwrite(uint8(2^8*kymoThr),  outKymoThrPath, EXT)

