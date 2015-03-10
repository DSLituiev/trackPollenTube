function [ kymogram, mov, roi ] = movie2kymo( movPath, roiPath )
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

M4_EPSILON = 16;
KYMO_INTERPOLATION_METHOD = 'l2';

roi = constructCurveROI(roiPath);

[mov] = cropRectRoiFast(movPath, roi);

%% trim ROI
roi.x = roi.x  - roi.frame(1,2) +1;
roi.y = roi.y  - roi.frame(1,1) +1;

%%
kymogram = constructKymogram(roi, mov, KYMO_INTERPOLATION_METHOD, M4_EPSILON);

end

