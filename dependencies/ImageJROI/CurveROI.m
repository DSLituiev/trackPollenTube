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
        function obj = CurveROI(varargin)
            obj@ImageJROI(varargin{:})
            if nargin <= 2 && ...
                    feval( @(x)( ischar(x) && exist(x, 'file') ) , varargin{1} )    ;
                obj = constructCurveROI(obj, varargin{2:end});
            elseif nargin >= 3 && ...
                    any( strcmpi(varargin{1}, {'PolyLine', 'FreeLine', 'Freehand', 'Polygon'}) )
            end
            
        end
        
        function status = write(obj, fileName)
            if (isempty(obj.x) || isempty(obj.y)) && ~ isempty(obj.mnCoordinates)
                status = writeImageJRoi(fileName, obj.strType, obj.mnCoordinates(:,1), obj.mnCoordinates(:,2) );
            else
                status = writeImageJRoi(fileName, obj.strType, obj.x, obj.y);
            end
        end
        
        function ff = plot(obj, ptFrame, varargin)
            
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            
            addRequired(p, 'ptFrame', @(x) readable(x) || ( isnumeric(x) && (sum(size(x)>1)==2) ) );
            addOptional(p, 'tt', 1, @isscalar );
            addOptional(p, 'pad', 10, @isscalar );
            
            addParamValue(p, 'x', '$x$', @ischar );
            addParamValue(p, 'y', '$y$', @ischar );
            
            addParamValue(p, 'rotate', false, @isscalar );
            addParamValue(p, 'fontSize', 12, @isscalar );
            addParamValue(p, 'linewidth', 2, @isscalar );
            addParamValue(p, 'tick_spacing', 100, @isscalar );
            addParamValue(p, 'pointSpacing', 25, @isscalar );
            addParamValue(p, 'color', 'm', @(x)(isnumeric(x) || ischar(x)) )
            parse(p, ptFrame, varargin{:});
            %%
            if readable(ptFrame)
                imsize = get_tiff_size(ptFrame);
                if imsize(3) == 1
                    ptFrame = imread(ptFrame);
                else
                    ptFrame = cropRectRoiFast(ptFrame, obj, p.Results.pad, p.Results.tt);
                end
            end
            
            ff = figure;
            if p.Results.rotate
                imagesc(ptFrame')
            else
                imagesc(ptFrame)
            end
            colormap gray
            hold on
            
            if p.Results.rotate                
                plot(obj.y, obj.x, 'w-', 'linewidth',  p.Results.linewidth+1)
                plot(obj.y, obj.x, '-', 'color', p.Results.color, 'linewidth', p.Results.linewidth)
                if ~isempty(obj.y0)
                    plot(obj.y(1:p.Results.pointSpacing:end), obj.x(1:p.Results.pointSpacing:end), 'bx', 'linewidth', p.Results.linewidth)
                    plot(obj.y0, obj.x0, 'w+', 'markersize', 8, 'linewidth', p.Results.linewidth+1)
                    plot(obj.y0, obj.x0, '+', 'color', p.Results.color, 'markersize', 6, 'linewidth', p.Results.linewidth)
                else
                    plot(obj.y, obj.x, 'w+', 'markersize', 8, 'linewidth', p.Results.linewidth+1)
                    plot(obj.y, obj.x, '+','color', p.Results.color, 'markersize', 6, 'linewidth', p.Results.linewidth)
                    
                end
                axis  equal tight
                set(gca, 'tickdir', 'out', ...
                    'xtick', 0:p.Results.tick_spacing:size(ptFrame,1),...
                    'ytick', 0:p.Results.tick_spacing:size(ptFrame,2))                
            else
                plot(obj.x, obj.y, 'w-', 'linewidth',  p.Results.linewidth+1)
                plot(obj.x, obj.y, '-', 'color', p.Results.color, 'linewidth',  p.Results.linewidth)
                if ~isempty(obj.x0)
                    plot(obj.x(1:p.Results.pointSpacing:end), obj.y(1:p.Results.pointSpacing:end), 'bx', 'linewidth',  p.Results.linewidth)
                    plot(obj.x0, obj.y0, 'w+', 'markersize', 8, 'linewidth',  p.Results.linewidth+1)
                    plot(obj.x0, obj.y0, '+', 'color', p.Results.color, 'markersize', 6, 'linewidth',  p.Results.linewidth)
                else
                    plot(obj.x, obj.y, 'w+', 'markersize', 8, 'linewidth',  p.Results.linewidth+1)
                    plot(obj.x, obj.y, '+','color', p.Results.color, 'markersize', 6, 'linewidth',  p.Results.linewidth)
                    
                end
                axis  equal tight
                set(gca, 'tickdir', 'out', ...
                    'xtick', 0:p.Results.tick_spacing:size(ptFrame,2),...
                    'ytick', 0:p.Results.tick_spacing:size(ptFrame,1))
            end
            xlabel( p.Results.x, 'interpreter', 'latex', 'fontsize', p.Results.fontSize)
            ylabel( p.Results.y,  'interpreter', 'latex', 'fontsize', p.Results.fontSize)
            fig(ff)
        end
    end
    
end
