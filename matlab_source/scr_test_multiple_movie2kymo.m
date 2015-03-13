close all
clear all
clc
%% include dependencies
includeDependencies( )

%% define path to the files
fileName = 'dsRed-a.tif';
inRoiName = 'path.roi';
outKymoName = 'kymo.tif';
outRoiName = 'kymo.roi';

SourceDir = '/media/QuyNgo_data/Analysed data/WT';
FolderListing = DescrReaderOptsCell(SourceDir, nameCheckListCell('p'));

for jj = 1:numel(FolderListing)
    ParentDir = fullfile(SourceDir, FolderListing(jj).name);
    
    tifPath = fullfile(ParentDir,  fileName);
    inRoiPath = fullfile(ParentDir,  inRoiName);
%     outRoiPath = fullfile(ParentDir, outRoiName);
    outKymoPath = fullfile(ParentDir, outKymoName);
    %% read     
    [ kymogram, mov, xy_roi ] = movie2kymo( tifPath, inRoiPath, outKymoPath );
    
    figure
    imagesc( kymogram )    
end