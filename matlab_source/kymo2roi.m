function [ status ] = kymo2roi( tifPath, outRoiPath, varargin )
%KYMO2ROI -- extract edge ROI from a thresholded kymogram
%
% Syntax:
%========
%    status = kymo2roi( tifPath, outRoiPath, [rotate], [visualize] )`
%
% Input:
% ======
% - tifPath    -- path to the input `tif` file (of a thresholded kymogram)
% - outRoiPath -- path to the output `roi` file
% - rotate     -- rotate the input image (optional, boolean, default = false)
% - visualize  -- plot the results       (optional, boolean, default = false)

FILTER_RADIUS = 3;
THRESHOLD = 2.5;

if nargin<3
    rotate = false;
else
    rotate = varargin{1};
end

if nargin<4
    visualize = false;
else
    visualize = varargin{2};
end

[ z, kymoEdge ] = kymo2path( tifPath, rotate );

if visualize
    lineWidth = 3;
    figure
    imagesc( (2^8-1)*uint8(kymoEdge) )
    hold on
    plot(z, 'k', 'linewidth', lineWidth)
end

%% analyse the speed
[ ind, dz, ddz ] = bendings( z, FILTER_RADIUS, THRESHOLD);

%% plot speed 

T = numel(z);
t = 1:T;

if visualize
    figure
    subplot(3,1,1)
    plot(t, z );
    hold all
    plot(t(ind), z(ind), 'r+' );
    xlabel('time')
    ylabel('z')

    subplot(3,1,2)
    plot(t(1:end-1), dz ); hold all
    plot(t(ind), dz(min(ind, numel(dz))), 'rx'  );
    ylim([0, min(2, 0.1*ceil(10*max(dz))) ])
    hold all
    plot([1, T], [0, 0], 'k-')
    xlabel('time')
    ylabel('speed')

    subplot(3,1,3)
    plot(t(2:end-1), ddz );
    hold all
    plot(t(ind), ddz(min(max(ind-1, 1), numel(ddz) ) ), 'rx' )
    xlabel('time')
    ylabel('acceleration')
end

if rotate    
    status = writeImageJRoi(outRoiPath, 'PolyLine',  uint16(t(ind)),  uint16(z(ind)) );
else
    status = writeImageJRoi(outRoiPath, 'PolyLine', uint16(z(ind)),  uint16(t(ind)) );
end

end

