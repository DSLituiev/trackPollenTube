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
tifBgName = 'dsRed-a-b.tif';

SourceDir = '/media/QuyNgo_data/Analysed data/WT';
FolderListing = DescrReaderOptsCell(SourceDir, nameCheckListCell('p'));
fprintf('======================\n')
for jj = 1:numel(FolderListing)
    ParentDir = fullfile(SourceDir, FolderListing(jj).name);
    fprintf('processing : %s\n', ParentDir)
    
    tifPath = fullfile(ParentDir,  fileName);
    inRoiPath = fullfile(ParentDir,  inRoiName);
%     outRoiPath = fullfile(ParentDir, outRoiName);
    outKymoPath = fullfile(ParentDir, outKymoName);
    outRoiPath = fullfile(ParentDir, outRoiName);
    tifBgPath = fullfile(ParentDir, tifBgName);
    %% remove background
    remove_static_bg( tifPath, tifBgPath )
    tifPath = tifBgPath;
    %% produce kymogram
    [ kymogram, mov, xy_roi ] = movie2kymo( tifPath, inRoiPath, outKymoPath );

    %% produce a (r,t)-roi
    kymo2roi( kymogram, outRoiPath, 1 );

end