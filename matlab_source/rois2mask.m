function [ output_args ] = rois2mask( xy_roi, rt_roi )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if feval( @(x)(ischar(x) && exist(x, 'file')) , xy_roi)
    xy_roi = CurveROI(xy_roi);
end

if feval( @(x)(ischar(x) && exist(x, 'file')) , rt_roi)
    rt_roi = CurveROI(rt_roi);
end



end

