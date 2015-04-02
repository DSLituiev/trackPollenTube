function [ rt_roi, status ] = kymo2roi( varargin )
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
% - outRoiPath -- path to the output `roi` file (optional, file path OR boolean, default = false)
%                 if set to `true` saves into directory of tifPath
%                 under the `kymo.tif` name.
% - rotate     -- rotate the input image (optional, boolean, default = false)
% - visualize  -- plot the results       (optional, boolean, default = false)
%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'tifPath', @(x)( readable(x) || ( isnumeric(x) && (sum(size(x)>1)==2) ) ) );
addOptional(p, 'outRoiPath', false, @(x)(writable(x) || islogical(x) || x==0 || x==1   )  );
addOptional(p, 'visualize',  false, @isscalar);
addParamValue(p, 'rotate', false, @(x)(isscalar(x)));
parse(p, varargin{:});
%%
includeDependencies( )

%% extract the object path
[ z, kymoEdge ] = kymo2path( p.Results.tifPath,  p.Results, p.Unmatched );

if p.Results.visualize
    lineWidth = 3;
    figure
    imagesc( (2^8-1)*uint8(kymoEdge) )
    hold on
    plot(z, 'k', 'linewidth', lineWidth)
end

%% analyse the speed
[ ind ] = bendings( z, p.Results, 'visualize', p.Results.visualize, p.Unmatched);

T = numel(z);
t = (1:T)';
%% write
if p.Results.rotate
    rt_roi = CurveROI('PolyLine', uint16(z(ind)),  uint16(t(ind)));
else
    rt_roi = CurveROI('PolyLine',  uint16(t(ind)), uint16(z(ind)));
end

if ischar(p.Results.outRoiPath)
    outRoiPath = p.Results.outRoiPath;
elseif p.Results.outRoiPath
    pathstr = fileparts(p.Results.tifPath);
    outRoiPath = fullfile(pathstr, 'kymo.roi');
else
    outRoiPath = '';
end

if ~isempty(outRoiPath)
    status = rt_roi.write(p.Results.outRoiPath);
    if status < 0
        error('kymo2roi2plot:cannotWriteROI', 'could not write the ROI')
    end
else 
    status = -1;
end

end

