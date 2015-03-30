classdef ImageJROI < handle
    
    properties
        filename
        x0
        y0
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
        function copy_fields(obj, roi)
            if isstruct(roi)
                rf = fieldnames(roi);
            elseif isobject(roi)
                rf = properties(roi);
            end
            for ii = 1:numel(rf)
                if isprop(obj, rf{ii})
                    obj.(rf{ii}) = roi.(rf{ii});
                else
                    warning('ImageJROI:unknownPropery' ,'omitting a property: %s', rf{ii})
                end
            end
        end
        function obj  = ImageJROI(varargin)
            if readable(varargin{1})
                obj.filename = varargin{1};
                roi = ReadImageJROI(obj.filename);                
                if all(~roi.vnRectBounds)
                    warning('empty ROI')
                end
                obj.copy_fields(roi);
            elseif isobject(varargin{1})                
                obj.copy_fields(varargin{1});
            elseif writable(varargin{1}) && ~isempty(varargin{1})
                obj.filename = varargin{1};
                obj.x0 = [];
                obj.y0 = [];                
                obj.set_coordinates();
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
                
                obj.x0 = p.Results.x;
                obj.y0 = p.Results.y;
                
                obj.set_coordinates();
            end
        end
        
        function set_coordinates(obj)
            obj.x0 = round(obj.x0);
            obj.y0 = round(obj.y0);
            
            obj.calc_bounds();
            
            obj.mnCoordinates = [];
            if ~isempty(obj.x0)
                obj.mnCoordinates(:,1) = obj.x0 ;
            end
            if ~isempty(obj.y0)
                obj.mnCoordinates(:,2) = obj.y0 ;
            end
        end
        
        function calc_bounds(obj)
            obj.nNumCoords = numel(obj.y0);
            obj.vnRectBounds = [ min(obj.y0), min(obj.x0), ...
                max(obj.y0), max(obj.x0)];
        end
        
        function status = write(obj, varargin)
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            addOptional(p, 'filename', '', @writable);
            parse(p, varargin{:});
            %%
            if ~isempty(p.Results.filename)
                obj.filename = p.Results.filename;
            elseif isempty(obj.filename)
                error('no file name provided or set earlier')
            end
            %%
            obj.set_coordinates();
            status = writeImageJRoi(obj.filename, obj);
        end
    end
    
end
