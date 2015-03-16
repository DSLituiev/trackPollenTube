classdef path_xyt
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        x
        y
        t
        radius
        lag
    end
    
    methods
        function obj = path_xyt( xy_roi, rt_roi )
            
            if feval( @(x)(ischar(x) && exist(x, 'file')) , xy_roi)
                xy_roi = CurveROI(xy_roi);
            end

            if feval( @(x)(ischar(x) && exist(x, 'file')) , rt_roi)
                rt_roi = CurveROI(rt_roi);
            end
%             if abs(numel(xy_roi.x) - max(rt_roi.x)) > 2
%                 warning('dimension mismatch between the (x,y) and (r,t) kymograms')
%             end
            obj.x = interp1(rt_roi.x, xy_roi.x);
            obj.y = xy_roi.y;
            obj.t = rt_roi.y;          
        end
    end
    
end

