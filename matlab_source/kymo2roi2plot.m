function [ f ] = kymo2roi2plot( tifPath, outRoiPath, outImg)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    [~, status] = kymo2roi( tifPath, outRoiPath,  0);
    if status < 0
        error('kymo2roi2plot:cannotWriteROI', 'could not write the ROI')
    end
        
    %% read the roi and overay it over the kymogram
    f = plot_roi_on_kymo(outRoiPath, tifPath, outImg, 'png', 'Resolution', 300);
end

