classdef ImageJROI

properties
    nNumCoords
    nVersion
    strName
    strType
    vnRectBounds
    bSplineFit
    
    nArcSize
    strSubtype
    vfShapeSegments
    % Freehand, PolyLine
    mnCoordinates
    % Ellips
    vfEllipsePoints
    fAspectRatio
    % Line
    bDoubleHeaded    % Does the line have two arrowheads?
    bOutlined        % Is the arrow outlined?
    nArrowStyle      % The ImageJ style of the arrow (unknown interpretation)
    nArrowHeadSize   % The size of the arrowhead (unknown units)
% Additionally, ROIs from later versions (.nVersion >= 218) may have the
% following fields:

    nStrokeWidth     % The width of the line stroke
    nStrokeColor     % The encoded color of the stroke (ImageJ color format)
    nFillColor       % The encoded fill color for the ROI (ImageJ color format)
%
% If the ROI contains text:
%     .strSubtype = 'Text';
    nFontSize        % The desired font size
    nFontStyle       % The style of the font (unknown format)
    strFontName      % The name of the font to render the text with
    strText          % A string containing the text
end

methods
    function obj  = ImageJROI(filenames)
        roi = ReadImageJROI(filenames);
        rf = fieldnames(roi);
        for ii = 1:numel(rf)
            if isprop(obj, rf{ii})
                obj.(rf{ii}) = roi.(rf{ii});
            else
                warning('ImageJROI:unknownPropery' ,'omitting a property: %s', rf{ii})
            end
        end
    end
    function write(obj, fileName)
        if isempty(obj.x) || isempty(obj.y)
            writeImageJRoi(fileName, obj.strType, obj.mnCoordinates(:,1), obj.mnCoordinates(:,2) )
        else
            writeImageJRoi(fileName, obj.strType, obj.x, obj.y)
        end
    end
end

end
