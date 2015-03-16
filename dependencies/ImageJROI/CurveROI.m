classdef CurveROI < ImageJROI

properties
    x
    y
   % xy
    x0
    y0
    L
    frame
end

methods
    function obj = CurveROI(filename, varargin)
        obj@ImageJROI(filename);
        obj = constructCurveROI(obj, varargin{:});
    end
    
    function status = write(obj, fileName)
        if isempty(obj.x) || isempty(obj.y)
            status = writeImageJRoi(fileName, obj.strType, obj.mnCoordinates(:,1), obj.mnCoordinates(:,2) );
        else
            status = writeImageJRoi(fileName, obj.strType, obj.x0, obj.y0);
        end
    end
end

end
