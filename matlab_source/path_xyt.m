classdef path_xyt<handle
    %PATH_XYT( xy_roi, rt_roi ) -- constructs (x,y,t) ROI and mask from (x,y) and (r,t) ROIs
    
    properties
        xt
        yt
        x2d
        y2d
        r
        r_raw
        t
        radius = 10;
        lag
        L
        T
        stoptime
        mov_dims
        mask_dims
        mask
        pixels
        rt_roi
        xy_roi
        pix_color_plot
        pix_median_marker
        pix_median
    end
    
    properties
        vnRectBounds
        strType = 'PolyLine';
        fast
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
        function obj = path_xyt( xy_roi, rt_roi, varargin )
            if nargin == 1 && isa(xy_roi, 'path_xyt')
                obj.copy_fields(xy_roi)
                return
            end
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            addRequired(p, 'xy_roi', @(x)(readable(x) || isobject(x) ) );
            addRequired(p, 'rt_roi', @(x)(readable(x) || isobject(x) ) );
            addOptional(p, 'interp1', 'pchip', @(x)any( strcmpi(x, {'linear','pchip'})) );
            addOptional(p, 'lag', 0, @isscalar );
            parse(p, xy_roi, rt_roi, varargin{:});
            %
            obj.lag = p.Results.lag;
            %%
            if readable(xy_roi)
                obj.xy_roi = CurveROI(xy_roi);
            else
                obj.xy_roi = xy_roi;
            end
            
            if readable(rt_roi)
                obj.rt_roi = CurveROI(rt_roi, p.Results.interp1 );
            else
                obj.rt_roi = rt_roi;
            end
            %             if abs(numel(xy_roi.x) - max(rt_roi.x)) > 2
            %                 warning('dimension mismatch between the (x,y) and (r,t) kymograms')
            %             end
            
            obj.T = round(max(obj.rt_roi.x));
            obj.t = (1:obj.T)';
            
            obj.calc_coordinates();
        end
        function calc_coordinates(obj, varargin)
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            addOptional(p, 'lag', 0, @isscalar );
            addOptional(p, 'interp1', 'pchip', @(x)any( strcmpi(x, {'linear','pchip'})) );
            parse(p, varargin{:});
            %
            obj.lag = p.Results.lag;
            %%
            obj.r_raw = round( interp1(  1 +double(obj.rt_roi.x),  1 + double(obj.rt_roi.y), double(obj.t), p.Results.interp1, 'extrap') );
            obj.L = max(obj.r_raw);
            %%
            obj.r = obj.r_raw - obj.lag  - obj.radius;
            obj.r(obj.r<1) = 1;
            obj.r(obj.r>obj.L) = obj.L;
            obj.r(obj.r > numel(obj.xy_roi.x) ) = numel(obj.xy_roi.x);
            
            obj.xt = obj.xy_roi.x(obj.r);
            obj.yt = obj.xy_roi.y(obj.r);
            obj.x2d = obj.xy_roi.x;
            obj.y2d = obj.xy_roi.y;
            
            obj.calc_bounds();
        end
        function [theta_normal, x0, y0] = normal(obj, tt, offset)
            tt = max(2,tt);
            r0  = min(numel(obj.xy_roi.x) -1, max(2, obj.r(tt)   - offset));
            %             rbk = max(1, obj.r(tt-1) - offset);
            %             rfw = max(1, obj.r(tt+1) - offset);
            
            x0 = obj.xy_roi.x(r0);
            y0 = obj.xy_roi.y(r0);
            
            dx = [obj.xy_roi.x(r0-1) - x0,    x0 - obj.xy_roi.x(r0+1) ];
            dy = [obj.xy_roi.y(r0-1) - y0,    y0 - obj.xy_roi.y(r0+1)];
            
            theta_normal = mean(atan2(dx, dy)) + pi/4;
            %             k_tangent = mean(dx./dy);
            %             k_normal = -1/k_tangent;
            %             b_normal = obj.yt(r0) - k_normal * obj.xt(r0);
        end
        
        function varargout = refine_path(obj, varargin)
        end
        
        function varargout = refine_xy(obj, varargin)
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            addRequired(p, 'obj', @isobject);
            addRequired(p, 'movPath', @(x)( readable(x)) || (is3dstack(x)) ) ;
            addOptional(p, 'filter_radius', 15, @isscalar );
            addOptional(p, 'tangent_radius', 0.5, @isscalar );
            addOptional(p, 'norm_radius_coef', 2, @isscalar );
            addParamValue(p, 'visualize', false, @isscalar);
            parse(p, obj, varargin{:});
            %% arguments
            RRt = ceil(p.Results.tangent_radius * obj.radius);
            drt = (-RRt:1:RRt)';
            
            RRn = ceil(p.Results.norm_radius_coef * obj.radius);
            dr = permute( -RRn:1:RRn, [1,3,2]);
            cc0 = [bsxfun(@mtimes, ones(size(drt)), dr), bsxfun(@plus, drt, ones(size(dr)))];
            
            
            if feval( @(x)(ischar(x) && exist(x, 'file')), p.Results.movPath)
                mov = crop_movie(p.Results.movPath, obj, 2 * obj.radius);
            else
                mov = p.Results.movPath;
            end
            %%
            obj.xy_roi.calc_theta();
            %%
            function R = rotation_matrix(ang)
                R = [cos(ang), -sin(ang); sin(ang), cos(ang)];
            end
            %%
            secant_adjustment_t = zeros(obj.T,1);
            secant_adjustment = NaN(numel(obj.xy_roi.x),1);
            theta_tmp = fastmedfilt1d(unwrap(obj.xy_roi.theta), 2 * p.Results.filter_radius+1,...
                obj.xy_roi.theta(1)*ones(p.Results.filter_radius), obj.xy_roi.theta(end)*ones(p.Results.filter_radius));
            theta_t =  theta_tmp(obj.r(obj.t));

            weights = binomialFilter(4*RRt +1)';
            weights = fliplr(weights(1:2*RRt +1));
            weights = weights./sum(weights);
%             fgx = figure;
            for tt = 2:(numel(obj.t)-1)
                if obj.r(tt) < p.Results.norm_radius_coef * obj.radius+1
                    continue
                end
                cc = round(bsxfun(@plus, mtimesx(cc0, rotation_matrix(theta_t(tt))), [obj.xt(tt), obj.yt(tt)]));
                
                xx = squeeze(cc(:,1,:));
                yy = squeeze(cc(:,2,:));
                if isobject(mov) && strcmpi(class(mov), 'crop_movie')
                    pix = mov.sub2ind(yy, xx, tt);
                else
                    pix = get_values_sub2ind(mov, yy, xx, tt);
                end
                mfr = mov(:,:,tt);
                bg = quantile(mfr(:), 1/2);
                pix_smooth = conv2(pix, binomialFilter(obj.radius)', 'same');
%                 figure; imagesc(pix_smooth)
                
%                 pix_bw = double(pix_smooth>bg);
                
%                 secant_adjustment_t(tt) = weights * ( pix_smooth* dr(:)./sum(pix_smooth, 2));
                [~, cntr] = max(sum(pix_smooth,1));
                secant_adjustment_t(tt) = - (cntr - RRn);
                
%                 figure(fgx);
%                 imagesc( dr(:), drt(:), pix_smooth); axis equal; axis tight; hold all;
%                 plot(-secant_adjustment_t(tt)*[1,1], drt([1,end]), 'w-', 'linewidth', 2)
                
%                 figure(fgx); plot(dr(:), sum(pix_smooth,1))
                
%                 if p.Results.visualize
%                     figure
%                     imagesc(mov(:,:,tt)); axis equal; hold all; scatter(xx(:),yy(:),pi,'w')
%                     drawnow
%                 end
                
            end
            
            prev = 0;
            ii = 1;
            t_prev = obj.r(1);
            while ii < numel(obj.xy_roi.x)
               rinds = (obj.r == ii);
               if (t_prev + 1 >= numel(obj.r))
                   secant_adjustment(ii) = prev;
               elseif ~any(rinds) 
                   secant_adjustment(ii) = (prev + secant_adjustment_t(t_prev+1))/2;
               else
                   secant_adjustment(ii) = nanmedian(secant_adjustment_t(rinds) );
                   t_prev = find(rinds, 1, 'last');
               end
               prev = secant_adjustment(ii);
               ii = ii +1;
            end
            %             secant_adjustment(isnan(secant_adjustment))  = 0;
            smooth_sc_adj = zeros(size(secant_adjustment));
            
            smooth_sc_adj(obj.r(1):obj.r(end)) = ...
                fastmedfilt1d(secant_adjustment(obj.r(1):obj.r(end)), 2 * p.Results.filter_radius+1, ...
                flipud(secant_adjustment(obj.r(1):obj.r(1)-1+p.Results.filter_radius)), ...
                flipud(secant_adjustment(obj.r(end)+1-p.Results.filter_radius:obj.r(end))));
            smooth_sc_adj(isnan(smooth_sc_adj))  = 0;
            
            x_adjustment = smooth_sc_adj .* cos(obj.xy_roi.theta + pi);
            y_adjustment = smooth_sc_adj .* -sin(obj.xy_roi.theta + pi);
            %%
            smooth_sc_adj_t = ...
                fastmedfilt1d(secant_adjustment_t, 2 * p.Results.filter_radius+1, ...
                flipud(secant_adjustment_t(1:p.Results.filter_radius)), ...
                flipud(secant_adjustment_t(end+1-p.Results.filter_radius:end)));
            smooth_sc_adj_t(isnan(smooth_sc_adj_t))  = 0;
            xt_adjustment = smooth_sc_adj_t .* cos(theta_t + pi);
            yt_adjustment = smooth_sc_adj_t .* -sin(theta_t + pi);
            
            if p.Results.visualize
                
                figure
                subplot(2,1,1);plot( theta_t ); ylabel('theta')
                subplot(2,1,2); plot(secant_adjustment_t, 'rx'); ylabel('normal correction'); xlabel('time, frames')
                hold all; plot(smooth_sc_adj_t, 'b-')
                
                figure
                subplot(2,1,1);plot( theta_tmp ); ylabel('theta')
                subplot(2,1,2); plot(secant_adjustment, 'rx'); ylabel('normal correction'); xlabel('time, frames')
                hold all; plot(smooth_sc_adj, 'b-')
                
                figure;
%                 plot(obj.xy_roi.x, obj.xy_roi.y, 'b.-');
%                 axis equal; hold all
%                 plot(obj.xy_roi.x + x_adjustment, obj.xy_roi.y + y_adjustment, 'r.-')
%                 set(gca, 'ydir', 'reverse')
%                 legend({'before', 'after'})
                
%                 figure;
                plot(obj.xt, obj.yt, 'g.-');
                axis equal; hold all
                plot(obj.xt + xt_adjustment, obj.yt + yt_adjustment, 'm.-')
                set(gca, 'ydir', 'reverse')
                legend({'before', 'after', 'before(t)', 'after(t)'})

%                 figure; 
%                 plot(theta_normal)
%                 hold all;
%                 plot(obj.xy_roi.theta + pi/4)
            end
            obj.xy_roi.x = obj.xy_roi.x + x_adjustment;
            obj.xy_roi.y = obj.xy_roi.y + y_adjustment;
            obj.xy_roi.calc_theta();
            obj.calc_coordinates();
            
            if p.Results.visualize
                plot(obj.xt, obj.yt, 'b.-');
                set(gca, 'ydir', 'reverse')
                legend({'before(t)', 'after(t)', 'after(t, interp)'})
            end
            %%
            for ii = 1:numel(obj.xy_roi.r0)
                [~, ind] = min((obj.xy_roi.x0(ii) - obj.xy_roi.x).^2 + (obj.xy_roi.y0(ii) - obj.xy_roi.y).^2);
                obj.xy_roi.x0(ii) = obj.xy_roi.x(ind);
                obj.xy_roi.y0(ii) = obj.xy_roi.y(ind);
            end
            
%             if p.Results.visualize
%                 figure; obj.xy_roi.plot([],'keepcurve',true)
%             end
            if nargout>0
                varargout{1} = constructKymogram(obj.xy_roi, mov);
            end            
        end
        function refine_rt(obj, varargin)
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            addRequired(p, 'obj', @isobject);
            addRequired(p, 'movPath', @(x)( readable(x)) || (is3dstack(x)) ) ;
            addOptional(p, 'filter_radius', 15, @isscalar );
            addOptional(p, 'tangent_radius', 2, @isscalar );
            addOptional(p, 'norm_radius_coef', 1.5, @isscalar );
            addParamValue(p, 'visualize', false, @isscalar);
            parse(p, obj, varargin{:});
            %% arguments
            RRt = p.Results.tangent_radius;
            drt = (-RRt:1:RRt)';
            
            RRn = ceil(p.Results.norm_radius_coef * obj.radius);
            dr = permute( -RRn:1:RRn, [1,3,2]);
            cc0 = [bsxfun(@mtimes, ones(size(drt)), dr), bsxfun(@plus, drt, ones(size(dr)))];
            
            if feval( @(x)(ischar(x) && exist(x, 'file')), p.Results.movPath)
                mov = crop_movie(p.Results.movPath, obj, 2 * obj.radius);
            else
                mov = p.Results.movPath;
            end
            %% coordinates for tangent tracking
            tt = 1;
            
            cc = round(bsxfun(@plus, mtimesx(cc0, rotation_matrix(theta_normal(tt) + pi/2)),[obj.xt(tt), obj.yt(tt)]));
            xx_ = squeeze(cc(:,1,:));
            yy_ = squeeze(cc(:,2,:));
            
            if p.Results.visualize
            figure
            obj.xy_roi.plot()
%             obj.xy_roi.img.setframe_slide(tt)
            obj.xy_roi.img.tt = tt;
            hold all
%             imagesc(mov(:,:,tt));
            axis equal; hold all; scatter(xx_(:),yy_(:),pi,'k')
            end
%             fxc = figure();
            %% tangent correction
            tanget_displacement = zeros(size(obj.t));
            for tt = 2:(numel(obj.t)-1)
                cc = round(bsxfun(@plus, mtimesx(cc0, rotation_matrix(theta_normal(tt) + pi/2)),[obj.xt(tt), obj.yt(tt)]));                
                xx = squeeze(cc(:,1,:));                
                yy = squeeze(cc(:,2,:));
                
                if isobject(mov) && strcmpi(class(mov), 'crop_movie')
                    pix = mov.sub2ind(yy, xx, tt);
                    pix_ = mov.sub2ind(yy_, xx_, tt-1);
                else
                    pix = get_values_sub2ind(mov, yy, xx, tt);
                    pix_ = get_values_sub2ind(mov, yy_, xx_, tt-1);
                end
                xx_ = xx;
                yy_ = yy;
                figure(fxc); plot(sum(pix,1), 'b-'); hold on;plot( sum(pix_,1) , 'r-'); legend({'tt', 'tt-1'})
                
                xci = xcov( sum(pix,1), sum(pix_,1) , RRn, 'unbiased');
                [~, dr_] = max(xci(1:RRn));
                tanget_displacement(tt) = dr_ - RRn;
%                  figure(fxc); plot(dr(:), xci)
%                 tanget_displacement(tt) = xci *  dr(:) / sum(xci);
            end
            smooth_tg_adj = fastmedfilt1d(tanget_displacement, 2 * p.Results.filter_radius+1,...
                flipud(tanget_displacement(1:p.Results.filter_radius)),  flipud(tanget_displacement(end+1-p.Results.filter_radius:end)));
            %           smooth_r_adj = conv( r_adjustment, binomialFilter(2* p.Results.filter_radius + 1), 'same');
            smooth_tg_adj(isnan(smooth_tg_adj))  = 0;
            if p.Results.visualize
                figure;
                plot(tanget_displacement, 'r.'); hold all
                plot(secant_adjustment_t, 'b.')
                plot(smooth_tg_adj, 'r-')
                plot(smooth_sc_adj(obj.r), 'b-')                
                legend({'tanget', 'secant'})                
            end            
            
            valid_inds = [diff(round(obj.r + smooth_tg_adj)) > 0; true];
            obj.r(valid_inds) = round(obj.r(valid_inds) + smooth_tg_adj(valid_inds));
            %%
            obj.r_raw = obj.r + obj.lag + obj.radius;
            obj.rt_roi.x = obj.t;
            obj.rt_roi.y = obj.r_raw;
            %%
            obj.calc_coordinates();
            
            if ~(numel(size(obj.mask)) == 3)
                obj.xyt_mask( p.Results.movPath, p.Results.filter_radius)
            end
        end
        
        function calc_bounds(obj)
            obj.vnRectBounds = 1+[ max(0, floor(min(obj.xy_roi.y0)) - obj.radius), max(0, floor(min(obj.xy_roi.x0)) - obj.radius),  ...
                ceil(max(obj.xy_roi.y0)) + obj.radius, ceil(max(obj.xy_roi.x0)) + obj.radius];
        end
        
        function varargout = xyt_mask(obj, varargin)
            % XYT_MASK -- creates a mask from the internally stored (x,y,t)-path
            
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            addRequired(p, 'obj', @isobject);
            addRequired(p, 'movPath', @(x)( readable(x) || is3dstack(x) || numel(x) == 3 ) );
            addRequired(p, 'radius', @isscalar );
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
            if numel(p.Results.movPath) == 3
                obj.mov_dims = p.Results.movPath;
            else
                obj.mov_dims = get_tiff_size( p.Results.movPath );
            end
            
            obj.stoptime = min(obj.T, min(obj.mov_dims(3), obj.stoptime));
            assert( abs(obj.mov_dims(3) - obj.T) < 3 )
            obj.T = obj.mov_dims(3);
            
            %             delta_t = obj.T - size(obj.mask, 3);
            %             if delta_t > 0
            %                 if delta_t > 3
            %                     warning('time dimension mismatch')
            %                 end
            %                 obj.t = 1:obj.T;
            %                 obj.r = obj.r(obj.t);
            %                 obj.xt = obj.xt(obj.t);
            %                 obj.yt = obj.yt(obj.t);
            %                 if ~isempty(obj.mask)
            %                     obj.mask = obj.mask(:,:, obj.t);
            %                     %                         obj.mask_dims(3) = obj.T;
            %                 end
            %             end
            
            %             if obj.fast
            %                 % [y x t]
            %                 obj.mask_dims = [ diff(reshape(obj.vnRectBounds, [2,2]),1,2)'+1, obj.stoptime];
            %                 x_m = obj.xt(1:obj.stoptime) - obj.vnRectBounds(2);
            %                 y_m = obj.yt(1:obj.stoptime) - obj.vnRectBounds(1);
            %             else
            obj.mask_dims = obj.mov_dims;
            x_m = obj.xt(1:obj.stoptime) ;
            y_m = obj.yt(1:obj.stoptime) ;
            %             end
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
            addRequired(p, 'movPath', @(x)( readable(x) || ( isnumeric(x) && ( numel(size(x))==3 ) ) ) );
            addOptional(p, 'outPath', '', @writeable );
            parse(p, obj, varargin{:});
            %%
            if ~(numel(size(obj.mask)) == 3)
                error('mask has not been calculated yet!')
                % obj.xyt_mask( varargin{:} )
            end
            
            if readable(p.Results.movPath)
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
        
        function f = visualize_mask(obj, movMasked, tt, varargin)
            lw = 2;
            if nargin>3
                f = figure(varargin{1});
            else
                f = figure;
            end
            ax = subplot(1,1,1);
            if obj.fast
                obj.xy_roi.img = zeros(obj.mov_dims(1:2));
                if ndims(movMasked) == 3
                    obj.xy_roi.img(obj.vnRectBounds(1):obj.vnRectBounds(3),...
                        obj.vnRectBounds(2):obj.vnRectBounds(4) ) = movMasked(:,:,tt);
                elseif ndims(movMasked) == 4
                    obj.xy_roi.img(obj.vnRectBounds(1):obj.vnRectBounds(3),...
                        obj.vnRectBounds(2):obj.vnRectBounds(4), 1:3 ) = movMasked(:,:,1:3,tt);
                end
            else
                obj.xy_roi.img = movMasked(:,:,:,tt);
            end
            obj.xy_roi.plot();
            %             imagesc(movMasked(:,:,:,tt))
            %             axis(ax, 'equal', 'tight')
            %             if obj.fast
            %                 hold all;
            %                 plot(obj.xt-obj.vnRectBounds(2) , obj.yt-obj.vnRectBounds(1), 'g-', 'linewidth', lw)
            %             else
            %                 hold all;
            % %                 plot(obj.xt, obj.yt, 'b-', 'linewidth', lw)
            %             end
        end
        
        function varargout = apply_mask(obj, movPath, varargin)
            %APPLY_MASK -- applies the mask on the movie and returns the
            %intensities of the masked pixels
            
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            addRequired(p, 'obj', @isobject);
            addRequired(p, 'movPath', @(x)(readable(x) || is3dstack(x)) );
            addOptional(p, 'radius', 0, @isscalar );
            addOptional(p, 'lag', 0, @isscalar );
            addOptional(p, 'stoptime', Inf, @isscalar );
            %             addParamValue(p, 'fast', true, @islogical);
            addParamValue(p, 'out', '', @writeable );
            parse(p, obj, movPath, varargin{:});
            %%
            recalculate = true;
            if ~isempty(p.Results.radius) && (p.Results.radius > 0)
                obj.radius = p.Results.radius;
            end
            
            if obj.fast
                mov = cropRectRoiFast(movPath, obj.xy_roi);
            else
                if readable(movPath)
                    mov = readTifSelected(movPath);
                else
                    mov = movPath;
                end
            end
            
            if recalculate || ~(is3dstack(obj.mask)) || ~all(size(mov) == size(obj.mask))
                if obj.radius > 0
                    if ~isempty(fieldnames(p.Unmatched))
                        obj.xyt_mask( mov, obj.radius, p.Results.lag, p.Results.stoptime, p.Unmatched )
                    else
                        obj.xyt_mask( mov, obj.radius)
                    end
                else
                    error('specify a non-zero, positive radius!')
                end
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
        function varargout = plot_pixels(obj, varargin)
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            addRequired(p, 'obj', @isobject);
            addOptional(p, 'figure', [], @(x)(isscalar(x) || isempty(x)) );
            parse(p, obj, varargin{:});
            %%
            if isempty(obj.pixels)
                obj.apply_mask(p.Unmatched)
            end
            if ~isempty(p.Results.figure) && isfigure(p.Results.figure)
                f = p.Results.figure;
            else
                f = figure('name', 'pixel intensities');
            end
            spl(1) = subplot(2,1,1);
            obj.pix_color_plot = imagesc(obj.pixels');
            ylabel('pixel index')
            title('pixel intensities within the mask')
            spl(2) = subplot(2,1,2);
            obj.pix_median = obj.median();
            plot(1:numel(obj.pix_median), obj.pix_median);
            hold on
            obj.pix_median_marker = plot(1, obj.pix_median(1), 'r.', 'markersize', pi*9);
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

