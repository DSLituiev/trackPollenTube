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
            if isempty(obj.x) || isempty(obj.y)
                status = writeImageJRoi(fileName, obj.strType, obj.mnCoordinates(:,1), obj.mnCoordinates(:,2) );
            else
                status = writeImageJRoi(fileName, obj.strType, obj.x0, obj.y0);
            end
        end
        
        function ff = plot(obj, ptFrame, varargin)
            
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            
            addRequired(p, 'ptFrame', @(x) readable(x) || ( isnumeric(x) && (sum(size(x)>1)==2) ) );
            addOptional(p, 'tt', 1, @isscalar );
            addOptional(p, 'padding', 10, @isscalar );
            addOptional(p, 'fontSize', 12, @isscalar );            
            addOptional(p, 'tick_spacing', 100, @isscalar );
            addOptional(p, 'pointSpacing', 25, @isscalar );
            parse(p, ptFrame, varargin{:});
            %%
            if readable(ptFrame)
                ptFrame = cropRectRoiFast(ptFrame, obj, p.Results.padding, p.Results.tt);
            end
                        
            ff = figure;
            imagesc(ptFrame)
            colormap gray
            hold on
            plot(obj.x, obj.y, 'w-', 'linewidth', 4)
            plot(obj.x, obj.y, 'm-', 'linewidth', 2)
            if ~isempty(obj.x0)
                plot(obj.x(1:p.Results.pointSpacing:end), obj.y(1:p.Results.pointSpacing:end), 'gx', 'linewidth', 2)
                plot(obj.x0, obj.y0, 'w+', 'markersize', 8, 'linewidth', 3)
                plot(obj.x0, obj.y0, 'm+', 'markersize', 6, 'linewidth', 2)
            else
                plot(obj.x, obj.y, 'w+', 'markersize', 8, 'linewidth', 3)
                plot(obj.x, obj.y, 'm+', 'markersize', 6, 'linewidth', 2)
                
            end
            axis  equal tight
            set(gca, 'tickdir', 'out', ...
                'xtick', 0:p.Results.tick_spacing:size(ptFrame,2),...
                'ytick', 0:p.Results.tick_spacing:size(ptFrame,1))
            xlabel('$x$', 'interpreter', 'latex', 'fontsize', p.Results.fontSize)
            ylabel('$y$',  'interpreter', 'latex', 'fontsize', p.Results.fontSize)
            fig(ff)
        end
    end
    
end
