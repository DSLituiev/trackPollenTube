classdef ImageJROI < handle
    
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
        function obj  = ImageJROI(varargin)
            if nargin == 1
                roi = ReadImageJROI(varargin{1});
                rf = fieldnames(roi);
                for ii = 1:numel(rf)
                    if isprop(obj, rf{ii})
                        obj.(rf{ii}) = roi.(rf{ii});
                    else
                        warning('ImageJROI:unknownPropery' ,'omitting a property: %s', rf{ii})
                    end
                end
            else
                %% check the input parameters
                p = inputParser;
                p.KeepUnmatched = true;
                addRequired(p, 'strType', @ischar );
                addRequired(p, 'x', @isnumeric );
                addRequired(p, 'y', @isnumeric );
                %
                parse(p, varargin{:});
                %%
                obj.strType = p.Results.strType;
                obj.nNumCoords = numel(p.Results.x);                
                assert( obj.nNumCoords ==  numel(p.Results.y) , 'x and y must have same length!')
                
                obj.x = p.Results.x;
                obj.y = p.Results.y;
                
                obj.mnCoordinates(:,1) = obj.x;
                obj.mnCoordinates(:,2) = obj.y;
                
                obj.vnRectBounds = [ min(p.Results.y), min(p.Results.x), ...
                                     max(p.Results.y), max(p.Results.x)];
            end
        end
        function write(obj, fileName)
            if isempty(obj.x) || isempty(obj.y)
                writeImageJRoi(fileName, obj )
            else
                writeImageJRoi(fileName, obj.strType, obj.x, obj.y)
            end
        end
    end
    
end
