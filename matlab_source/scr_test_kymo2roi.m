close all
clear all
clc
%% include dependencies
includeDependencies( )

%% define path to the files
% SourceDir = '../testcases/Christina/threshkymo/230614';
% fileName = '3.tif';
% outRoiName = 'out.roi';
SourceDir = '../testcases/QAN_WT_028_14042013_Rg8burst';
fileName = 'kymo.tif';
outRoiName = 'out.roi';
outImg = 'out.png';

tifPath = fullfile(SourceDir,  fileName);
outRoiPath = fullfile(SourceDir, outRoiName);
outImgPath = fullfile(SourceDir, outImg);

kymo2roi2plot( tifPath, outRoiPath, outImg);

return

SourceDir = '/media/QuyNgo_data/Analysed data/WT';
FolderListing = DescrReaderOptsCell(SourceDir, nameCheckList('p'));

for jj = 1:numel(FolderListing)
    ParentDir = fullfile(SourceDir, FolderListing(jj).name);
    
    tifPath = fullfile(ParentDir,  fileName);
    outRoiPath = fullfile(ParentDir, outRoiName);
    outImgPath = fullfile(ParentDir, outImg);
    %% read and normalize the kymogram
    close all
    kymo2roi2plot( tifPath, outRoiPath, outImg);
end