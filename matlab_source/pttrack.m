classdef pttrack
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mov;
        cropped_mov;
        xy_roi;
        rt_roi;
        
    end
    
    methods
        function self = pttrack(mov_)
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            
            addRequired(p, 'movPath', @(x)(readable(x) || ( isnumeric(x) && (sum(size(x)>1)==3) ) ));
            addOptional(p, 'roiPath', @(x)(readable(x) || isobject(x) ) );
            addOptional(p, 'kymoPath', false, @(x)( isempty(x) || islogical(x) || x==0 || x==1 || writable(x) )  );
            addParamValue(p, 'interpolation', 'l2', @(x)(any(strcmpi(x,{'l1', 'l2', 'm4'}))) );
            addParamValue(p, 'm4epsilon', 16, @isscalar );
            addParamValue(p, 'pad', 10, @isscalar );
            parse(p, varargin{:});
            %% read input roi
            obj.mov = 
        end
    end
    
end

