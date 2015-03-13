classdef roimovie()
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mov;
        kymogram;
        xy_roi;
        rt_roi;
        radius;        
    end
    
    methods
        function obj = roimovie(varargin)
            [ obj.kymogram, obj.mov, obj.xy_roi ] = movie2kymo( varargin{:} );
        end
        function kymo2roi(obj, varargin)
             [obj.rt_roi.t, obj.rt_roi.r] = kymo2roi( varargin{:} );
        end
        
    end
    
end

