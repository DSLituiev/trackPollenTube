function [ t,z, status ] = kymo2roi( varargin )
%KYMO2ROI -- extract edge ROI from a thresholded kymogram
%
% Syntax:
%========
%    status = kymo2roi( tifPath, outRoiPath, [rotate], [visualize] )`
%
% Input:
% ======
% - tifPath    -- path to the input `tif` file (of a kymogram)
%                 OR a kymogram per se
% - outRoiPath -- path to the output `roi` file
% - rotate     -- rotate the input image (optional, boolean, default = false)
% - visualize  -- plot the results       (optional, boolean, default = false)
%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'tifPath', @(x)( (ischar(x) && exist(x, 'file')) || ( isnumeric(x) && (sum(size(x)>1)==2) ) ) );
addRequired(p, 'outRoiPath', @(x)(ischar(x)));
addOptional(p, 'visualize',  false, @isscalar);
addParamValue(p, 'rotate', false, @(x)(isscalar(x)));
parse(p, varargin{:});
%%
includeDependencies( )

%% extract the trace
[ z, kymoEdge ] = kymo2path( p.Results.tifPath,  p.Results, p.Unmatched );

if p.Results.visualize
    lineWidth = 3;
    figure
    imagesc( (2^8-1)*uint8(kymoEdge) )
    hold on
    plot(z, 'k', 'linewidth', lineWidth)
end

%% analyse the speed
[ ind ] = bendings( z, p.Results, p.Unmatched);

%% plot speed 
T = numel(z);
t = 1:T;
% 
% if visualize
%     figure
%     ax(1) = subplot(3,1,1);
%     plot(t, z );
%     hold all
%     plot(t(ind), z(ind), 'r+' );
%     xlabel('time')
%     ylabel('z')
% 
%     ax(2) = subplot(3,1,2);
%     plot(t(1:end-1), dz ); hold all
%     plot(t(ind), dz(min(ind, numel(dz))), 'rx'  );
%     ylim([0, min(2, 0.1*ceil(10*max(dz))) ])
%     hold all
%     plot([1, T], [0, 0], 'k-')
%     xlabel('time')
%     ylabel('speed')
% 
%     ax(3) = subplot(3,1,3);
%     plot(t(2:end-1), ddz );
%     hold all
%     plot(t(ind), ddz(min(max(ind-1, 1), numel(ddz) ) ), 'rx' )
%     xlabel('time')
%     ylabel('acceleration')
%     
%     set(ax, 'xlim', [0, T])
%     
% end
%% write
if p.Results.rotate    
    status = writeImageJRoi(p.Results.outRoiPath, 'PolyLine', uint16(z(ind)),  uint16(t(ind)) );
else
    status = writeImageJRoi(p.Results.outRoiPath, 'PolyLine',  uint16(t(ind)),  uint16(z(ind)) );
end

end

