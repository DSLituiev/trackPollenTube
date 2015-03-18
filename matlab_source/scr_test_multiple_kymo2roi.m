close all
clear all
clc
%% include dependencies
includeDependencies( )

%% define path to the files
SourceDir = '/media/QuyNgo_data/Analysed data/WT';
fileName = 'kymo.tif';
outRoiName = 'out.roi';
outImg = 'out.png';

FolderListing = DescrReaderOptsCell(SourceDir, nameCheckListCell('p'));

for jj = 1:numel(FolderListing)
    ParentDir = fullfile(SourceDir, FolderListing(jj).name);
    
    tifPath = fullfile(ParentDir,  fileName);
    outRoiPath = fullfile(ParentDir, outRoiName);
    outImgPath = fullfile(ParentDir, outImg);
    %% read and normalize the kymogram
%     close all
    kymo2roi2plot( tifPath, outRoiPath, outImgPath);
end