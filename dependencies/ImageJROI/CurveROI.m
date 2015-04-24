classdef CurveROI < ImageJROI & modifiable_line
    
    properties
        x
        y
        theta
        % xy
%         x0
%         y0
        L
        frame
        nondecreasing = false;
        original_vnRectBounds;
        cropped = false;
    end
    
    methods
        function obj = CurveROI(varargin)
            ndinds = strcmpi(varargin, 'nondecreasing') | strcmpi(varargin, 'nd');
            ndflag = any(ndinds);
            if nargin == 1 && isempty(varargin{1})
                args = {'PolyLine', [],[]};
            else
                args = varargin(~ndinds);
                if ~(readable(args{1}))
                    args = {'PolyLine', args{:}};
                end
            end
            
            obj@ImageJROI(args{:});            
            
            if (obj.cropped || ~isempty(obj.original_vnRectBounds)) && isobject(args{2})
                obj.mnCoordinates(:,1) = obj.mnCoordinates(:,1) + obj.original_vnRectBounds(2);
                obj.mnCoordinates(:,2) = obj.mnCoordinates(:,2) + obj.original_vnRectBounds(1);
                obj.cropped = false;
                obj.parent = args{2};
            end
%             clear args
            interp_ind = feval(@(x)strcmpi(x, 'pchip') | strcmpi(x, 'linear') | strcmpi(x, 'spline'),  varargin);
            if ~isempty(obj.mnCoordinates)
                obj = constructCurveROI(obj, varargin{interp_ind});
            end

            obj.nondecreasing = ndflag;
        end
        
        function save(inpobj, ~, obj, varargin)
            save@modifiable_line(inpobj, [], obj);            
            obj.set_coordinates();
            obj.calc_bounds();
            
            if obj.nondecreasing
                if any(diff(obj.x0)<0) || any(diff(obj.y0)<0)
                    warning('decreasing coordinates! correction will be applied')
                    for ii = 2:numel(obj.x0)
                        if obj.x0(ii) < obj.x0(ii-1)
                            obj.x0(ii) = obj.x0(ii-1);
                        end                        
                        if obj.y0(ii) < obj.y0(ii-1)
                            obj.y0(ii) = obj.y0(ii-1);
                        end
                    end
                    obj.redraw_all();
                end
            end
                       
            if ~obj.cropped && isempty(obj.original_vnRectBounds)
            	obj.write();
            else
                obj_uncropped = CurveROI(obj);
                obj_uncropped.write();
%                 notify(obj,' Saving'); 
            end
            
        end
        
        
        function put_in_frame(obj, vnRectBounds_)
            obj.vnRectBounds = vnRectBounds_;
            obj.x0 = obj.x0 + vnRectBounds_(2);
            obj.y0 = obj.y0 + vnRectBounds_(1);
            obj.interp();
            obj.backup();
        end
        %{
        function ff = plot(obj, img, varargin)
            
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
            parse(p, img, varargin{:});
            %%
            if readable(img)
                imsize = get_tiff_size(img);
                if imsize(3) == 1
                    img = imread(img);
                else
                    img = cropRectRoiFast(img, obj, p.Results.pad, p.Results.tt);
                end
            end
            
            ff = figure;
            if p.Results.rotate
                imagesc(img')
            else
                imagesc(img)
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
                    'xtick', 0:p.Results.tick_spacing:size(img,1),...
                    'ytick', 0:p.Results.tick_spacing:size(img,2))                
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
                    'xtick', 0:p.Results.tick_spacing:size(img,2),...
                    'ytick', 0:p.Results.tick_spacing:size(img,1))
            end
            xlabel( p.Results.x, 'interpreter', 'latex', 'fontsize', p.Results.fontSize)
            ylabel( p.Results.y,  'interpreter', 'latex', 'fontsize', p.Results.fontSize)
            fig(ff)
        end
        %}
        
        function namestr = getobjname(obj)
            namestr = evalin('caller','inputname(1)');
        end
    end
    
end

