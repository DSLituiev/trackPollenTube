
close all
clear all
clc
%% include dependencies
includeDependencies( )
% addpath('/usr/local/MATLAB/R2013b/bin/glnxa64/') % libtiff
%% define path to the files
SourceDir = '../testcases/QAN_WT_023_25112012_Rg14burst_Rg14fer';
fileName = 'dsRed-a-b.tif';
inRoiName = 'path.roi';
outKymoName = 'kymo.tif';

tifPath = fullfile(SourceDir, fileName); 
inRoiPath = fullfile(SourceDir, inRoiName);
outKymoPath = fullfile(SourceDir, outKymoName);
% 
% clear moo mov;
% mov = readTifSelected(tifPath);
% moo = crop_movie(tifPath, inRoiPath);
% moo(58,36,570)
% mov(58,36,570)
% figure; imagesc( moo(55:60,35:40,571) ); set(gca, 'clim', [1.5, 2]*1e4)
% figure; imagesc( mov(55:60,35:40,571) ); set(gca, 'clim', [1.5, 2]*1e4)

% tifBgPath = fullfile(SourceDir, 'dsRed-a-b-c.tif');
% remove_static_bg( tifPath, tifBgPath )
% tifPath = tifBgPath;
%%
[ kymogram, mov, xy_roi ] = movie2kymo( tifPath, inRoiPath, '', 'pad', 10 );

figure
imagesc( kymogram )
imwrite(kymogram, outKymoPath)

tt = 364; % ceil(size(mov,3)*4/5);
f = plot_snapshot_roi( mov, xy_roi, tt);

%% 
outRoiName = 'out.roi';
outRoiPath = fullfile(SourceDir, outRoiName);

kymo2roi( kymogram, outRoiPath, 1 );

%%
s=dbstatus;
save('myBreakpoints.mat', 's');
clear xxx
load('myBreakpoints.mat');
dbstop(s);

xxx = path_xyt(inRoiPath, outRoiPath);
pix = xxx.apply_mask(tifPath, 10);

movMasked= xxx.mask_outline(tifPath);
xxx.visualize_mask(movMasked, tt);

s=dbstatus;
save('myBreakpoints.mat', 's');
clear yyy
load('myBreakpoints.mat');
dbstop(s);

yyy = path_xyt(xxx);
yyy.refine_path(tifPath, 20, 2, 2, 'visualize', true)
yyy.visualize_mask(movMasked, tt);


xxx.plot_pixels()
