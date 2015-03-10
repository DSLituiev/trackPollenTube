function [ status ] = kymo2roi( tifPath, outRoiPath, varargin )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

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
    plot(t, z );
    hold all
    plot(t(ind), z(ind), 'r+' );
    xlabel('time')
    ylabel('z')

    figure
    plot(t(1:end-1), dz ); hold all
    plot(t(ind), dz(min(ind, numel(dz))), 'rx'  );
    ylim([0, min(2, 0.1*ceil(10*max(dz))) ])
    hold all
    plot([1, T], [0, 0], 'k-')
    xlabel('time')
    ylabel('speed')

    figure
    plot(t(2:end-1), ddz );
    hold all
    plot(t(ind), ddz(min(max(ind-1, 1), numel(ddz) ) ), 'rx' )
    xlabel('time')
    ylabel('acceleration')
end

status = writeImageJRoi(outRoiPath, 'PolyLine', uint16(z(ind)),  uint16(t(ind))  );

end

