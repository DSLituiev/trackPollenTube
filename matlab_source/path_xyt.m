classdef path_xyt<handle
    %PATH_XYT( xy_roi, rt_roi ) -- constructs (x,y,t) ROI and mask from (x,y) and (r,t) ROIs
    
    properties
        x
        y
        r
        t
        radius
        lag
        L
        T
        stoptime
        mov_dims
        mask
        pixels
    end
    
    methods
        function obj = path_xyt( xy_roi, rt_roi )
            
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
            
            obj.x = xy_roi.x(obj.r);
            obj.y = xy_roi.y(obj.r);
        end
        
        function varargout = xyt_mask(obj, varargin)
            % XYT_MASK -- creates a mask from the internally stored (x,y,t)-path
            
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;            
            addRequired(p, 'obj', @isobject);
            addRequired(p, 'movPath', @(x)( (ischar(x) && exist(x, 'file')) || ( isnumeric(x) && ( numel(x)==3 ) ) ));
            addRequired(p, 'radius', @isscalar );
            addOptional(p, 'lag', 0, @isscalar );
            addOptional(p, 'stoptime', Inf, @isscalar );
            parse(p, obj, varargin{:});
            %% other argument pre-processing steps
            if feval( @(x)(ischar(x) && exist(x, 'file')), p.Results.movPath)
                obj.mov_dims = get_tiff_size( p.Results.movPath );
            else
                obj.mov_dims = p.Results.movPath;
            end
            obj.stoptime = p.Results.stoptime;
            obj.lag = p.Results.lag;
            obj.radius = p.Results.radius;
            
            assert( abs(obj.mov_dims(3) - obj.T) < 3 )
            
            obj.stoptime = min(obj.mov_dims(3), obj.stoptime);
            
            rrr = max(min(obj.r + obj.lag, 1), obj.L);
            rrr = rrr(1:obj.stoptime);
            %% compute
            [YY, ~, ~ ] = ndgrid(1:double(obj.mov_dims(1)), 1, 1:obj.stoptime );
            [ ~, XX, ~] = ndgrid(1, 1:double(obj.mov_dims(2)), 1:obj.stoptime );

            obj.mask =  bsxfun(@plus, ...
                bsxfun(@minus, XX, permute( obj.x(rrr) , [3,2,1]) ).^2 ,...
                bsxfun(@minus, YY, permute( obj.y(rrr) , [3,2,1]) ).^2) < obj.radius^2;

            obj.mask = cat(3, obj.mask, repmat(obj.mask(:,:, obj.stoptime), [1,1, obj.T - obj.stoptime]));
            % mask = rot90_3D(mask, 3,2);
            if nargout>0
                varargout{1} = obj.mask;
            end
        end
        function varargout = mask_outline(obj, varargin)
            %MASK_OUTLINE -- writes the outline of the masks onto the movie and saves it.
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
                mov = imread(p.Results.movPath);
            else
                mov = p.Results.movPath;
            end
            %%
            maskOutline = ([ zeros([1, obj.mov_dims(2:3)]); diff(int8(obj.mask),2,1); zeros([1,obj.mov_dims(2:3)])] + ...
                [zeros( obj.mov_dims(1), 1, obj.mov_dims(3) ), diff(int8(obj.mask),2,2),  zeros( obj.mov_dims(1), 1, obj.mov_dims(3) ) ])>0;
            
            movMasked = single(max(mov(:)))*single(maskOutline) + single(mov).* single(~maskOutline);
            movMasked(:,:,:,2) = single(mov).* single(~maskOutline);
            movMasked(:,:,:,3) = movMasked(:,:,:,2);
            movMasked = uint8( 2^8 * movMasked./quantile(movMasked(:), 0.99));
            movMasked = permute(movMasked , [1,2,4,3]);
            if ~isempty(p.Results.outPath)
            imwrite(movMasked, p.Results.outPath)
            end
            if nargout > 0 
                varargout = {movMasked};
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
            addOptional(p, 'stoptime', Inf, @isscalar )
            addParamValue(p, 'out', '', @writeable );
            parse(p, obj, varargin{:});
            %% 
            if ~(numel(size(obj.mask)) == 3) && p.Results.radius >0
                obj.xyt_mask( varargin{:} )
            else
                error('specify a non-zero radius!')
            end
            
            mov = readTifSelected(p.Results.movPath);
            obj.pixels = getPixDistr(mov, obj.mask, obj.stoptime);
            
            if ~isempty(p.Results.out)
                obj.mask_outline(mov, p.Results.out)
            end
            
            if nargout > 0 
                varargout = {obj.pixels};
            end
        end
        %% STATISTICS
        function y = median(obj, varargin)            
            %%
            if isempty(obj.pixels)
                obj.apply_mask(varargin)
            end
            y = median(obj.pixels, 2);
        end
        function y = mean(obj, varargin)            
            %%
            if isempty(obj.pixels)
                obj.apply_mask(varargin)
            end
            y = mean(obj.pixels, 2);
        end
        function y = std(obj, varargin)            
            %%
            if isempty(obj.pixels)
                obj.apply_mask(varargin)
            end
            y = std(obj.pixels, 2);
        end
        function y = var(obj, varargin)            
            %%
            if isempty(obj.pixels)
                obj.apply_mask(varargin)
            end
            y = var(obj.pixels, 2);
        end
        function y = quantile(obj, p, varargin)            
            %%
            if isempty(obj.pixels)
                obj.apply_mask(varargin)
            end
            y = var(obj.pixels, p, 2);
        end
    end
    
end

