classdef path_xyt<handle
    %PATH_XYT( xy_roi, rt_roi ) -- constructs (x,y,t) ROI and mask from (x,y) and (r,t) ROIs
    
    properties
        x
        y
        r
        t
        radius = 0;
        lag
        L
        T
        stoptime
        mov_dims
        mask_dims
        mask
        pixels
    end
    
    properties
       vnRectBounds 
       strType = 'PolyLine';
       fast
    end
    
    methods
        function obj = path_xyt( xy_roi, rt_roi, varargin )
            
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;            
            addRequired(p, 'xy_roi', @(x)( (ischar(x) && exist(x, 'file') ) || isobject(x) ) );
            addRequired(p, 'rt_roi', @(x)( (ischar(x) && exist(x, 'file') ) || isobject(x) ) );
            addOptional(p, 'lag', 0, @isscalar );
            parse(p, xy_roi, rt_roi, varargin{:});
            %
            obj.lag = p.Results.lag;
            %%
            if feval( @(x)(ischar(x) && exist(x, 'file')) , xy_roi)
                xy_roi = CurveROI(xy_roi);
            end

            if feval( @(x)(ischar(x) && exist(x, 'file')) , rt_roi)
                rt_roi = CurveROI(rt_roi);
            end
%             if abs(numel(xy_roi.x) - max(rt_roi.x)) > 2
%                 warning('dimension mismatch between the (x,y) and (r,t) kymograms')
%             end

            obj.T = round(max(rt_roi.x));
            obj.t = (1:obj.T)';        
            
            obj.r = 1 + round( interp1(rt_roi.x, rt_roi.y, obj.t) );  
            obj.L = max(obj.r);
            
            
            obj.r = obj.r + obj.lag;
            obj.r(obj.r<1) = 1;
            obj.r(obj.r>obj.L) = obj.L;
            
            obj.x = xy_roi.x(obj.r);
            obj.y = xy_roi.y(obj.r);
            obj.calc_bounds();            

        end
        
        function calc_bounds(obj)
            obj.vnRectBounds = [ max(1, floor(min(obj.y)) - obj.radius), max(1, floor(min(obj.x)) - obj.radius),  ...                                
                                 ceil(max(obj.y)) + obj.radius, ceil(max(obj.x)) + obj.radius];
        end
        
        function varargout = xyt_mask(obj, varargin)
            % XYT_MASK -- creates a mask from the internally stored (x,y,t)-path
            
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;            
            addRequired(p, 'obj', @isobject);
            addRequired(p, 'radius', @isscalar );
            addOptional(p, 'movPath', '', @(x)( (ischar(x) && exist(x, 'file')) || ( isnumeric(x) && ( numel(x)==3 ) ) ));
            addOptional(p, 'stoptime', Inf, @isscalar );
            addParamValue(p, 'fast', true, @islogical);
            parse(p, obj, varargin{:});            
            %% process other arguments
            obj.stoptime = p.Results.stoptime;
            obj.radius = p.Results.radius;
            obj.fast = p.Results.fast;
            %% recalculate the frame
            obj.calc_bounds();
            %%
            obj.mov_dims = get_tiff_size( p.Results.movPath );            
            obj.stoptime = min(obj.mov_dims(3), obj.stoptime);            
            assert( abs(obj.mov_dims(3) - obj.T) < 3 )
            
            if obj.fast
                % [y x t]
                obj.mask_dims = [ diff(reshape(obj.vnRectBounds, [2,2]),1,2)'+1, obj.stoptime];
                x_m = obj.x(1:obj.stoptime) - obj.vnRectBounds(2);
                y_m = obj.y(1:obj.stoptime) - obj.vnRectBounds(1);
            else
                if feval( @(x)(ischar(x) && exist(x, 'file')), p.Results.movPath)
                    obj.mask_dims = obj.mov_dims;
                    %                 else
                    %                     obj.mask_dims = p.Results.movPath;
                    x_m = obj.x(1:obj.stoptime) ;
                    y_m = obj.y(1:obj.stoptime) ;
                end
            end
            %% compute
            [YY, ~, ~ ] = ndgrid(1:double(obj.mask_dims(1)), 1, 1:obj.stoptime );
            [ ~, XX, ~] = ndgrid(1, 1:double(obj.mask_dims(2)), 1:obj.stoptime );

            obj.mask =  bsxfun(@plus, ...
                bsxfun(@minus, XX, permute( x_m , [3,2,1]) ).^2 ,...
                bsxfun(@minus, YY, permute( y_m , [3,2,1]) ).^2) < obj.radius^2;

            obj.mask = cat(3, obj.mask, repmat(obj.mask(:,:, obj.stoptime), [1,1, obj.T - obj.stoptime]));
            % mask = rot90_3D(mask, 3,2);
            if nargout>0
                varargout{1} = obj.mask;
            end
            
        end
        function varargout = mask_outline(obj, varargin)
            %MASK_OUTLINE -- writes the outline of the masks onto the movie and saves it.
            %
            % to do: fast crop with `cropRectRoiFast.m`
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;            
            addRequired(p, 'obj', @isobject);
            addRequired(p, 'movPath', @(x)( (ischar(x) && exist(x, 'file')) || ( isnumeric(x) && ( numel(size(x))==3 ) ) ) );
            addOptional(p, 'outPath', '', @writeable );
            parse(p, obj, varargin{:});
            %% 
            if ~(numel(size(obj.mask)) == 3)
                obj.xyt_mask( varargin{:} )
            end
            
            if feval( @(x)(ischar(x) && exist(x, 'file')), p.Results.movPath)
                mov = cropRectRoiFast(p.Results.movPath, obj);
            else
                mov = p.Results.movPath;
            end
            %%
            dx =  diff(int8(obj.mask),2,1)>0;
            px = false([1, obj.mask_dims(2:3)]); 
            
            dy = diff(int8(obj.mask),2,2)>0;            
            py = false( obj.mask_dims(1), 1, obj.mask_dims(3) );
            
            maskOutline = [px; dx; px] + [py, dy, py];
            
            function movMasked = paint_outline(mov, maskOutline)
                %% colour the outline in red (rgb)
                assert( all(size(mov) == size(maskOutline)) )
                
                movMasked = single(max(mov(:)))*single(maskOutline) + single(mov).* single(~maskOutline);
                movMasked(:,:,:,2) = single(mov).* single(~maskOutline);
                movMasked(:,:,:,3) = movMasked(:,:,:,2);
                movMasked = uint8( 2^8 * movMasked./quantile(movMasked(:), 0.99));
                movMasked = permute(movMasked , [1,2,4,3]);
            end
            
            movMasked = paint_outline(mov, maskOutline);
            
            if ~isempty(p.Results.outPath)
                imwrite(movMasked, p.Results.outPath)
            end
            if nargout > 0 
                varargout = {movMasked};
            end
        end
        
        function visualize_mask(obj, movMasked, tt)
            lw = 2;
            figure; imagesc(movMasked(:,:,:,tt))
            if obj.fast
                hold all; plot(obj.x-obj.vnRectBounds(2) , obj.y-obj.vnRectBounds(1), 'g-', 'linewidth', lw)
            else
                hold all; plot(obj.x, obj.y, 'b-', 'linewidth', lw)
            end
        end
        
        function varargout = apply_mask(obj, varargin)
            %APPLY_MASK -- applies the mask on the movie and returns the
            %intensities of the masked pixels
            
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;            
            addRequired(p, 'obj', @isobject);
            addRequired(p, 'movPath', @(x)(ischar(x) && exist(x, 'file')) );
            addOptional(p, 'radius', 0, @isscalar );
            addOptional(p, 'lag', 0, @isscalar );
            addOptional(p, 'stoptime', Inf, @isscalar );
%             addParamValue(p, 'fast', true, @islogical);            
            addParamValue(p, 'out', '', @writeable );
            parse(p, obj, varargin{:});
            %% 
            if ~(numel(size(obj.mask)) == 3) && p.Results.radius >0
                if ~isempty(fieldnames(p.Unmatched))
                    obj.xyt_mask(p.Results.radius, p.Results.movPath, p.Results.lag, p.Results.stoptime, p.Unmatched )
                else
                    obj.xyt_mask(p.Results.radius, p.Results.movPath)
                end
            else
                error('specify a non-zero radius!')
            end
            
            if obj.fast
                mov = cropRectRoiFast(p.Results.movPath, obj);
            else
                mov = readTifSelected(p.Results.movPath);
            end
            obj.pixels = getPixDistr(mov, obj.mask, obj.stoptime);
            
            if ~isempty(p.Results.out)
                obj.mask_outline(mov, p.Results.out)
            end
            
            if nargout > 0 
                varargout = {obj.pixels};
            end
        end
        %% visualize
        function varargout = plot_pixels(obj,varargin)            
            if isempty(obj.pixels)
                obj.apply_mask(varargin{:})
            end
            f = figure('name', 'pixel intensities');
            spl(1) = subplot(2,1,1);
            imagesc(obj.pixels')
            ylabel('pixel index')
            title('pixel intensities within the mask')
            spl(2) = subplot(2,1,2);
            yy = obj.median();
            plot(1:numel(yy), yy)            
            ylabel('median intensity')
            xlabel('time (frames)')
            set(spl, 'xlim', [1, obj.T])
            if nargout > 0 
                varargout = {f, obj.pixels};
            end
        end
        %% STATISTICS
        function y = median(obj, varargin)            
            %%
            if isempty(obj.pixels)
                obj.apply_mask(varargin{:})
            end
            y = nanmedian(obj.pixels, 2);
        end
        function y = mean(obj, varargin)            
            %%
            if isempty(obj.pixels)
                obj.apply_mask(varargin{:})
            end
            y = nanmean(obj.pixels, 2);
        end
        function y = std(obj, varargin)            
            %%
            if isempty(obj.pixels)
                obj.apply_mask(varargin{:})
            end
            y = nanstd(obj.pixels, 2);
        end
        function y = var(obj, varargin)            
            %%
            if isempty(obj.pixels)
                obj.apply_mask(varargin{:})
            end
            y = nanvar(obj.pixels, 2);
        end
        function y = quantile(obj, p, varargin)            
            %%
            if isempty(obj.pixels)
                obj.apply_mask(varargin{:})
            end
            y = quantile(obj.pixels, p, 2);
        end
    end
    
end

