function [tubepath, ptTipSignal,  ptTipSignalLag,  kymogram] = analyzeCurlyPTpath(SourceDir, ListingItem, tubepath)
%      Reconstructs the path of the growing (pollen) tube in 3D (namely x,y,and t),
%   based on the 2D (x&y) path curve
%   provided in the 'dsRED.roi' ImageJ ROI file,
%   beforhand cropping the picture with the 'crop.roi' frame;
%   both ROIs as well as the movie should be provided in the 'moviepath' folder.
%
%      Based on the 3D path, obtains distribution of pixel intensities in
%   the radius 'objpath.R' around the front tip of the tube with the offset
%   'objpath.offset'  and  'objpath.offset' - 'objpath.lag' .
%
% === Input Files ===
%   - 'dsRED.roi' ImageJ ROI file --  2D path curve of the object
%   - 'crop.roi'                  --  cropping frame.
%
% === Input Variables ===
%   - 'moviepath'  -- the path to the folder with the movie and the ROIs
%   - 'objpath'    -- structure specifying properties of the traced object
%                     in pixels or frames:
%
%                     *  'R' - radius;
%                     *  'offset';
%                     *  'lag'
%
% === Output Files ===
%   - 'kymoraw.tif'
%   - 'kymothr.tif'
%
%
% === Output Variables ===
%   - 'objpath'
%   - 'ptTipSignal'      -- signal at the very tip (structure with min, max, mean, median)
%   - 'ptTipSignalLag'   -- signal of a lagging part (the distance from the tip
%                            should be specified in the  'objpath.lag')
%   - 'kymoGram'         -- raw kymogram (for plotting)
%

%== Constants
EXT = 'tif';          %=  picture file format
BG_QUANTILE = 0.02;    %== the lower quantile of the intensity among
%                         t-points to be considered as background level
EDGE_SIGMA = 16;
KYMO_QUANTILE = 0.90;  %== the upper quantile to be cut in the kymogram
%                         before threshold determination
THR_COEFF = 0.8;      %== threshold reduction factor for the kymogram thresholding
M4_EPSILON = 16;
KYMO_INTERPOLATION_METHOD = 'l2';

%== load and crop the data
folderName = ListingItem.name;
folderPath =  fullfile( SourceDir, folderName );
finalMovPath = fullfile(folderPath , 'dsRed-a-b-c.tif');
if exist( finalMovPath, 'file' )
    tic
    mov = loadtiff(finalMovPath);
    fprintf( 'reading the pre-processed movie took\t%3.1f\ts\n', toc )
else
    tic
    mov = cropRectRoiFast(fullfile(folderPath , 'dsRED-a.tif'), fullfile(folderPath , 'crop.roi'));
    % minmov = min(mov, [], 3);
    minMov = uint16(quantile(single(mov), BG_QUANTILE , 3));
    mov = bsxfun( @minus, mov, minMov );
    %    f1 = fspecial('gaus', GAUSS_2D_SIZE, GAUSS_2D_SIGMA);
    %     mov = imfilter(mov, f1,'replicate'); clear f1
    % mov = imclose(mov, strel('disk', MOV_OPEN_DISK_RADIUS));
    %== save the movie
    saveastiff(mov, finalMovPath);
    fprintf( 'reading the movie and BG subtraction took\t%3.1f\ts\n', toc )
end
clear finalMovPath

%== length of the movie
% T = size(mov,3);
movDim = uint16(size(mov));
tubepath.T = movDim(3);

if ~isfield(ListingItem, 'CheckPathROIFlag') || isempty(ListingItem.CheckPathROIFlag)
    tubepath = setstructfields(tubepath,...
        constructCurveROI(fullfile(folderPath , 'path.roi')));
else    
    ii = 1;
   % for ii = numel(ListingItem.CheckPathROIFlag)-1:1
    tubepath = setstructfields(tubepath,...
        constructCurveROI(fullfile(folderPath , strcat('path-', ListingItem.CheckPathROIFlag{ii}, '.roi') ) ) );
  %  end
end



% plotframepath(mov, tubepath, 300)

if ListingItem.CustomThrKymogram
    kymoThr = logical(imread(fullfile(folderPath, 'kymothr-c.tif')));
    kymogram = imread(fullfile(folderPath, 'kymoraw.tif'));
    if any(size(kymogram) - size(kymoThr))
        warning('analyzeCurlyPTpath:KymoDimMisMatch', 'the dimension of the custom thresholded kymogram does not match the size of the original kymogram')
    end
else
    %== obtain the kymogram
    tic
    kymogram = constructKymogram(tubepath, mov, KYMO_INTERPOLATION_METHOD, M4_EPSILON);
    % figure; imagesc(kymogram)
    fprintf('constructing the kymogram took\t%3.1f\ts\n',toc)
    
    %== threshold the kymogram
    kymoThr = edgeKymogram(kymogram, KYMO_QUANTILE, EDGE_SIGMA);
    %== save the kymogram
    imwrite(kymogram, fullfile(folderPath, 'kymoraw.tif'), EXT)
    % clear kymogram
    imwrite(uint8(2^8*kymoThr),  fullfile(folderPath, 'kymothr.tif'), EXT)
end

%== get the z-path from the kymogram by filtering,
%==                         morphofiltering, and segmentation
[tubepath.z, tubepath.eruptionT, kymoThr] = ...
    constructPathUsingKymogramNeighbourhood(kymoThr);
%== find a more exact burst time by the median intensity value
BURST_CORR_OFFSET = 20; 
BURST_CORR_R = 20;
rCentre = median(single(tubepath.z(max(tubepath.eruptionT-(-0:15),1) )));
% [~, burstCorr] = mink( diff(median( single(kymogram(ceil(end/2):end, max(1,tubepath.eruptionT-BURST_CORR_OFFSET):min(end, tubepath.eruptionT+BURST_CORR_OFFSET))) ,1)',2), 1 );
[~, burstCorr] = mink( diff(mink( single(kymogram( max(floor(rCentre - BURST_CORR_R),1):min(floor(rCentre + BURST_CORR_R), end), max(1,tubepath.eruptionT-BURST_CORR_OFFSET):min(end, tubepath.eruptionT+BURST_CORR_OFFSET))) ,1)',2), 1 );
% figure
% plot(  median( diff( single(kymogram(min(floor(rCentre - BURST_CORR_R),1):max(floor(rCentre + BURST_CORR_R), end), max(1,tubepath.eruptionT-BURST_CORR_OFFSET):min(end, tubepath.eruptionT+BURST_CORR_OFFSET))) ,1)',2) )
tubepath.eruptionT = tubepath.eruptionT + burstCorr - BURST_CORR_OFFSET  +1;

%    constructPathUsingKymogramMulti(kymoThr);
if ~ListingItem.CustomThrKymogram
    imwrite(uint8(2^8*kymoThr),  fullfile(folderPath, 'kymothr.tif'), EXT)
end

figure('name', folderName);
imagesc( kymoThr) % kymogram)
hold all
plot(tubepath.z, 'g-', 'linewidth', 2)
plot(tubepath.eruptionT, tubepath.z(tubepath.eruptionT), 'r*', 'linewidth', 2)
axis equal tight

clear kymoThr

%== create the PT tip mask
tic
mask = createKymoMask(movDim, tubepath);
fprintf('mask generation took\t%3.1f\ts\n',toc)
%== save the mask
tic
save(fullfile(folderPath, 'mask.mat'), 'mask')
fprintf('saving the mask took\t%3.1f\ts\n',toc)
%== generate and save the path outline
tic
maskOutline = ([ zeros([1,movDim(2:3)]); diff(int8(mask),2,1); zeros([1,movDim(2:3)])] + ...
   [zeros( movDim(1), 1, movDim(3) ), diff(int8(mask),2,2),  zeros( movDim(1), 1, movDim(3) ) ])>0;

movMasked = single(max(mov(:)))*single(maskOutline) + single(mov).* single(~maskOutline);
movMasked(:,:,:,2) = single(mov).* single(~maskOutline);
movMasked(:,:,:,3) = movMasked(:,:,:,2);
movMasked = uint8( 2^8 * movMasked./quantile(movMasked(:), 0.99));
movMasked = permute(movMasked , [1,2,4,3]);

options.color = true;
saveastiff(movMasked,  fullfile(folderPath , 'dsRed-a-b-c-mo.tif'), options);

fprintf('generation and saving the mask outline took\t%3.1f\ts\n', toc)
clear movMasked maskOutline
%== apply the mask: get the pixel distribution
tic
maskedPixels_t = getPixDistr(mov, mask);
fprintf('mask application took\t%3.1f\ts\n',toc)

%== calculate the statistics:
ptTipSignal = stats(maskedPixels_t);

%== create and apply the PT lagging mask
maskLag = createKymoMask(movDim, tubepath, 'lag');
maskedPixels_t_Lag = getPixDistr(mov, maskLag);
ptTipSignalLag = stats(maskedPixels_t_Lag);

%== add the "burst" field according to the file name and location
if   ~isempty(regexpi(SourceDir, '.*WT.*')) || ~isempty(regexpi(folderName, '.*burst.*'))
    % ( regexpi(SourceDir, '.*WT.*') && isempty(regexpi(folderName, '.*fer.*')) ) || regexpi(folderName, '.*burst.*') 
    tubepath.burst = true;
else
    tubepath.burst = false;
end


%== save the distribution and statistics:
save(fullfile(folderPath, 'pt_stats.mat'), 'tubepath', 'ptTipSignal', 'ptTipSignalLag')


%==================================
%
% %=------
% WINGS_T = [ 2, 80]; TAU_T = .8; OFFSET_T = 70;
% % filtT  = constructRectWaveFilter(WINGS_T, TAU_T);
%
% filtT  = - constructAssymRectWaveFilter(WINGS_T, OFFSET_T, TAU_T);
% %=------
% WINGS_R = [ 2, 80]; TAU_R = .8;
% OFFSET_R = 70;
% % filtR  = constructRect3WaveFilter(WINGS_R, TAU_R)';
% filtR  = - constructAssymRectWaveFilter(WINGS_R, OFFSET_R, TAU_R);
%
% figure; plot(filtR)
% filt2D = conv2(filtR,filtT');
% figure; imagesc(filt2D)
% %=------
% %
% %
% level = graythresh(kymogram);
% kymogramF = kymogram;
% kymogramF(kymogram < 2*level*max(kymogram(:))) = 0;
%
% kymogramF = conv2( filtR, filtT, kymogramF, 'same');
%
% kymogramF(kymogramF < 0) = 0;
%
% figure; imagesc(kymogramF); hold all; plot([856; 287], [228; 141], 'k+')