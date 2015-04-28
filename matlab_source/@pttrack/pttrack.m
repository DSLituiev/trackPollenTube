classdef pttrack < handle
    %the main class of pollen tube tracking GUI
    %
    %call:
    %    pt = pttrack(path_to_movie)
    %    pt.plot()
    %
    %this will return a plot of the movie (which can be scrolled)
    %Now you can draw a ROI and save it.
    %
    %Press 'Kymo' button to see a kymogram.
    %Now you can correct the ROI on the kymogram.
    %You also can use 'Refine' button, to automatically refine the ROI
    %(though it is not recommended for short movies).
    %
    %Now you can view the pixel intensities.
    %If the movie had two colour channels, the ratio of median pixel
    %values will be displayed in the lowest pane.
    %
    %Now you can retrieve the pixel intensity values and their statistics
    %with commands:
    %
    %   pixs = pt.pixels()
    %
    %or various statistics (for each time point and channel):
    %
    %   pt.mean()
    %   pt.var
    %   pt.std()
    %   pt.median()
    %   pt.quantile(0.05)
    %
    %For ratiometric data (with two channels) you can retrieve the
    %intensity ratio (or other formula, which has to be provided during the
    %object instantiation, or set later:
    %
    %   % default:
    %   pt.plot('ratio_formula', @(x,y)(y./x) )  
    %   %  ... provide manual input ...
    %   pt.ratio
    %
    %   % reset the formula:
    %   pt.ratio_formula = @(x,y)(x./y);    
    %   pt.ratio
    %
    
    properties
        mov;
        cropped_mov;
        cropping = false;
        xy_roi;
        rt_roi;
        xyt
        kymogram;
        mov_filename;
        mov2_filename;
        fig_xy
        fig_kymo
        fig_pix
        btn_refine_xy
        ls_xy_saving;
        xy_pos_marker;
        rt_pos_marker_bg;
        rt_pos_marker;
        roiPath
        kymoPath 
        movPath
        kymo_interp
        m4epsilon
        radius_field = [];
        draw_pix_mode = false;
        ratio_formula
        ref_ch = 1; % reference (most static) channel
        mov_final_ = [];
    end
    
    methods        
        function obj = pttrack(varargin)    
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            addRequired(p, 'mov1_filename', @ischar);
%             addParamValue(p, 'mov2_filename', '', @ischar);
            addParamValue(p, 'ratio_formula', @(x,y)(y./x), @(x)isa(x, 'function_handle'));
            addParamValue(p, 'filter_radius', 3, @isscalar);
            parse(p,  varargin{:});
            %%         
            obj.mov_filename = p.Results.mov1_filename;

            obj.ratio_formula = p.Results.ratio_formula;
            [obj.kymogram, obj.mov, obj.xy_roi, obj.roiPath, ...
                obj.kymoPath, obj.movPath, obj.kymo_interp, obj.m4epsilon] = ...
                movie2kymo( obj.mov_filename, '', '', p.Unmatched );
            if ndims(obj.mov) == 4
                filter_kernel = min(9, p.Results.filter_radius )*[1,1];
                m1 = medfilt3( squeeze(obj.mov(:,:,1,:)), filter_kernel );
                m2 = medfilt3( squeeze(obj.mov(:,:,2,:)), filter_kernel);
                obj.mov_final_ = obj.ratio_formula(single(m1), single(m2));
                obj.mov_final_(isinf(obj.mov_final_)) = NaN;
                clear m1 m2                
            end
        end
        %%
        function plot(obj, varargin)
            
            obj.fig_xy = figure;
            obj.xy_roi.plot(obj.mov);
            axis equal 
            axis tight
            hold on
            addlistener( obj.xy_roi.img, 'Scroll', @(x,y)cb_scroll(obj,x,y) );
            addlistener( obj.xy_roi, 'Saving', @(x,y)cb_xy_save(obj,x,y) );
            
            obj.xy_pos_marker = scatter([], [], pi*100, 'wo', 'linewidth', 2);
            uistack(obj.xy_pos_marker,'bottom');
            uistack(obj.xy_roi.img.im,'bottom');
            
            btn_kymo = uicontrol('Style', 'pushbutton', 'String', 'Kymo',...
                'TooltipString', ['Show the kymogram for current ROI', char(10) , ...
                ''],...
                'Units','normalized', ...
                'Position', obj.xy_roi.button_slots(5,:),...
                'Callback', {@cb_plot_kymo, obj, true});
            

            obj.btn_refine_xy = uicontrol(obj.fig_xy, 'Style', 'pushbutton', 'String', 'Refine',...
                'TooltipString', ['Show the pixel intensities', char(10) , ...
                ''],...
                'Units','normalized', ...
                'Position', obj.xy_roi.button_slots(6,:),...
                'Callback', {@cb_refine_xy, obj}, 'enable','off');
            
        end
        %%
        function cb_plot_kymo(~,~,obj, varargin)
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            addRequired(p, 'obj', @isobject);
            addOptional(p, 'heuristic_flag', true, @islogical ) ;
            addOptional(p, 'keepcurve_flag', false, @islogical );
            parse(p, obj, varargin{:});
            %% arguments
%             if isempty(obj.xyt) || isempty(obj.xyt.rt_roi)
                obj.kymo2roi('heuristic', p.Results.heuristic_flag);
%             end
            
            if feval(@(h)(~isempty(h) && ishandle(h) && findobj(h,'type','figure')==h), obj.fig_kymo)
                obj.xyt.rt_roi.unbackup();
                close(obj.fig_kymo)
            end
            
            obj.fig_kymo = figure;
            obj.xyt.rt_roi.plot(obj.kymogram, 'keepcurve', p.Results.keepcurve_flag);
            axis equal 
            axis tight
            hold on
            addlistener( obj.xyt.rt_roi, 'Saving', @(x,y)cb_rt_save(obj,x,y) );
            set(obj.fig_kymo, 'WindowScrollWheelFcn', {@setframe_wheel, obj.xy_roi.img})
                
            obj.rt_pos_marker_bg = line(0, 0, 'Marker','x', 'color','w', 'markersize', 5, 'linewidth', 2.4);
            obj.rt_pos_marker = line(0, 0, 'Marker', 'x', 'color', obj.xyt.rt_roi.clr_, 'markersize', 5, 'linewidth', 2);            
            
            cb_track(obj, p.Results.keepcurve_flag)
            
            btn_3dvis = uicontrol(obj.fig_kymo, 'Style', 'pushbutton', 'String', '3D',...
                'TooltipString', ['Visualize the kymogram and slices in 3D', char(10) , ...
                ''],...
                'Units','normalized', ...
                'Position', obj.xyt.rt_roi.button_slots(5,:),...
                'Callback', {@cb_visualize3d, obj});
            btn_kymo = uicontrol(obj.fig_kymo, 'Style', 'togglebutton', 'String', 'Pixels',...
                'TooltipString', ['Show the pixel intensities', char(10) , ...
                ''],...
                'Units','normalized', ...
                'Position', obj.xy_roi.button_slots(6,:),...
                'Callback', {@cb_plot_pix, obj});
             btn_refine_rt = uicontrol(obj.fig_kymo, 'Style', 'pushbutton', 'String', 'Refine',...
                'TooltipString', ['Show the pixel intensities', char(10) , ...
                ''],...
                'Units','normalized', ...
                'Position', obj.xy_roi.button_slots(7,:),...
                'Callback', {@cb_refine_rt, obj}, 'enable','on');
            
            set(obj.btn_refine_xy, 'enable','on');
        end
        %%
        function cb_refine_xy(~,~,obj)
%             obj.xyt.refine_path(obj.mov);
            
%             [~, grdiff] = raw_kymo_edge(single(obj.kymogram), 8, []);            
%             [ t0, x0 ] = segment_snake([ grdiff; double(quantile(grdiff(:), 0.05)) * ones(5, size(grdiff,2) )],  obj.xyt.rt_roi.x0, obj.xyt.rt_roi.y0, 'useAsEnergy', true );
%             [ t0, x0 ] = segment_snake( [obj.kymogram; double(quantile(obj.kymogram(:), 0.05)) * ones(5, size(obj.kymogram,2) )],  obj.xyt.rt_roi.x0, obj.xyt.rt_roi.y0 );
%             obj.xyt.rt_roi.x0 = round(t0);
%             obj.xyt.rt_roi.y0 = round(x0);
%             obj.xyt.rt_roi.replot_all()         
            if ndims(obj.mov)>3
                obj.xyt.refine_xy( squeeze(obj.mov(:,:,obj.ref_ch,:)), 'visualize', true);
            else
                obj.xyt.refine_xy(obj.mov, 'visualize', true);
            end
            
            obj.kymogram = constructKymogram(obj.xyt.xy_roi, obj.mov);
            obj.xy_roi = obj.xyt.xy_roi;
            obj.xy_roi.replot();
%             delete(obj.xyt);
%             obj.kymo2roi('heuristic', true);
            
%             obj.fig_kymo = figure;
%             obj.xyt.rt_roi.plot(obj.kymogram, 'm+', 'keepcurve', true);
%             cb_plot_kymo([],[],obj, true, true);
        end
         %%
        function cb_refine_rt(~,~,obj)
%             obj.xyt.refine_path(obj.mov);
            
            [~, grdiff] = raw_kymo_edge(single(obj.kymogram(:,:,obj.ref_ch)), 1, []);   
            gr_padded = [ grdiff; double(quantile(grdiff(:), 3/8)) * ones(5, size(grdiff,2) )];
            [ t0, x0 ] = segment_snake(gr_padded,  obj.xyt.rt_roi.x0, obj.xyt.rt_roi.y0,...
                'useAsEnergy', true, 'Delta',0, 'Wline', 1);
%             [ t0, x0 ] = segment_snake( [obj.kymogram; double(quantile(obj.kymogram(:), 0.05)) * ones(5, size(obj.kymogram,2) )],  obj.xyt.rt_roi.x0, obj.xyt.rt_roi.y0 );
            obj.xyt.rt_roi.x0 = round(t0);
            obj.xyt.rt_roi.y0 = round(x0);
            obj.xyt.rt_roi.replot_all()
%             delete(obj.xyt);
%             obj.kymo2roi('heuristic', true);
            
%             obj.fig_kymo = figure;
%             obj.xyt.rt_roi.plot(obj.kymogram, 'm+', 'keepcurve', true);
%             cb_plot_kymo([],[],obj, true, true);
        end
        %%
        function cb_plot_pix(but_obj,~,obj)
           obj.draw_pix_mode = get(but_obj, 'Value');  
            % plot intensities of pixel within the circular ROI
            if obj.draw_pix_mode
                obj.draw_pixels();
            else
                if isfigure(obj.fig_pix)
                    close(obj.fig_pix)
                end
            end
        end
        function varargout = draw_pixels(obj, varargin)            
            if isempty(obj.xyt)
                cb_track(obj);
            end
            if isfigure(obj.fig_pix)
                close(obj.fig_pix)
            end
            obj.xyt.fast = false;

%             obj.xyt.apply_mask(obj.mov_final, obj.xyt.radius);
            obj.xyt.apply_mask(obj.mov, obj.xyt.radius);
            
            obj.fig_pix = obj.xyt.plot_pixels(obj.fig_pix, 'movPath', obj.mov, 'radius', obj.xyt.radius, 'ratio_formula', obj.ratio_formula);
            obj.cb_scroll(obj.xy_roi.img)
            set(obj.fig_pix, 'WindowScrollWheelFcn', {@setframe_wheel, obj.xy_roi.img})
            varargout{1} = obj.fig_pix;
        end
        %%
        function cb_rt_save(obj, ~, varargin)
            cb_track(obj);
            obj.xyt.rt_roi.replot_all()
            obj.xyt.calc_coordinates()
            if obj.draw_pix_mode
                obj.xyt.xyt_mask(obj.xy_roi.img.mov, obj.xyt.radius)
                obj.draw_pixels();
            end
            obj.cb_scroll(obj.xy_roi.img)
        end
        %%
        function out = kymo(obj,varargin)
            out = obj.kymogram; % alias
        end
        %%
        function upd_kymo(obj)
            obj.kymogram = constructKymogram(obj.xy_roi, obj.mov, obj.kymo_interp, obj.m4epsilon);
        end
        %%
        function status = kymo2roi(obj, varargin)
            if isempty(obj.kymogram)
                obj.upd_kymo();
            end
            [rt_roi, status] = kymo2roi( obj.kymogram(:,:, obj.xy_roi.img.channel), replace_extension(obj.mov_filename, '-kymo.roi'),  0, varargin{:});
            rt_roi.backup();
            obj.xyt = path_xyt( obj.xy_roi, rt_roi);
        end
        %%
        function cb_xy_save(obj, ~, varargin)
%             [FileName,PathName] = uiputfile;
            obj.kymo2roi();
            obj.upd_kymo();
            cb_track(obj)
            if isfigure(obj.fig_kymo)                
%                 obj.xyt.rt_roi.unbackup;
                close(obj.fig_kymo)
                obj.xyt.rt_roi = [];
                cb_plot_kymo([],[], obj)
            end
        end
        %%
        function cb_scroll(obj, scr_mov, varargin)
            if ~isempty(obj.xyt)
%                 if scr_mov.tt <= obj.xyt.T
%                     scr_mov.tt = obj.xyt.T;
%                 end
                set(obj.xy_pos_marker, 'xdata', obj.xyt.xt(scr_mov.tt), 'ydata', obj.xyt.yt(scr_mov.tt))
                if  ~isempty(obj.xyt.rt_roi.figure) && ishandle(obj.xyt.rt_roi.figure)
                    set(obj.rt_pos_marker_bg, 'xdata', scr_mov.tt*[1,1], 'ydata', obj.xyt.r(scr_mov.tt) + obj.xyt.radius*[-1, 1])
                    set(obj.rt_pos_marker, 'xdata', scr_mov.tt*[1,1], 'ydata', obj.xyt.r(scr_mov.tt) + obj.xyt.radius*[-1, 1])
                    
                    uistack(obj.rt_pos_marker, 'bottom')                    
                    uistack(obj.rt_pos_marker_bg, 'bottom')
                    uistack(obj.rt_pos_marker, 'up')
                    uistack(obj.rt_pos_marker_bg, 'up')
                end
                if ~isempty(obj.fig_pix) && ishandle(obj.fig_pix) && any(ishandle(obj.xyt.pix_median_marker))
                    set(obj.xyt.pix_median_marker, 'xdata', scr_mov.tt*[1,1] )
                end
            end
        end
        function cb_track(obj, varargin)
            % reconstruct the x,y,t-track
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;            
            addRequired(p, 'obj', @isobject);
            addOptional(p, 'keepcurve_flag', false, @islogical );
            parse(p, obj, varargin{:});
            %%            
            if isempty(obj.xyt.rt_roi) || isempty(obj.xyt.rt_roi.x0) 
                obj.kymo2roi();
            else
                if obj.xyt.rt_roi.x0(end) ~= size(obj.kymogram, 2)
                    obj.xyt.rt_roi.L = interp1(obj.xyt.rt_roi.x0, obj.xyt.rt_roi.r0, size(obj.kymogram, 2), 'pchip');
                    obj.xyt.rt_roi.x0(end) = size(obj.kymogram, 2);
                    obj.xyt.rt_roi.y0(end) = round(interp1( obj.xyt.rt_roi.r0, obj.xyt.rt_roi.y0, obj.xyt.rt_roi.L, 'pchip'));                    
                end
            end
            if isempty(obj.radius_field) || ~ishandle(obj.radius_field)
            obj.radius_field = uicontrol(obj.xy_roi.figure, 'style','edit',...         
                'callback',{@cb_radius, obj},...
                'String', obj.xyt.radius,...
                'Units','normalized', ...
                'Position', obj.xyt.rt_roi.button_slots(7,:),...
                'TooltipString',['Scroll through movie frames', char(10),...
                '[also works with mouse wheel]' ]); 
            end
            if ~p.Results.keepcurve_flag
                obj.xyt.calc_coordinates()
            end
            cb_scroll(obj, obj.xy_roi.img)
%             set(obj.xy_pos_marker, 'xdata', obj.xyt.xt(obj.xy_roi.img.tt), ...
%                 'ydata', obj.xyt.yt(obj.xy_roi.img.tt) ...
%                 'SizeData', pi * obj.xyt.radius^2)            
        end
        
        function cb_radius(H,~, obj)
            obj.xyt.radius = str2double(get(H,'string'));
            obj.xyt.calc_coordinates()
            set(obj.xy_pos_marker, 'SizeData', pi * obj.xyt.radius^2)
        end
        function ff = cb_visualize3d(~,~,obj)
            ff = visualize_kymo3D(obj.mov, obj.kymogram, obj.xy_roi, obj.xyt.rt_roi, obj.xy_roi.img.tt);
        end
        function varargout = subsref(obj, S)
            switch S(1).type
                case '()'
                    error('() indexing not supported');
                case '{}'
                    error('{} indexing not supported');
                case '.'                    
                    
                    if any( strcmpi(S(1).subs, {'mean','median', 'std', 'var', 'quantile'} ))
                        S(2).type = '()';
                        S(2).subs = [{obj.mov}, S(2).subs];
                        [varargout{1:nargout}] = builtin('subsref', obj.xyt, S);  % as per documentation
                        return
                    end
                    
                    objs = {obj, obj.xyt, obj.xy_roi.img};
                    
                    errs = '';
                    for ii = 1:numel(objs)
                        try
                            [varargout{1:nargout}] = builtin('subsref', objs{ii}, S);  % as per documentation
                            break
                        catch err
                            errs{ii} = err;
                        end
                    end
                    if ii == numel(objs) && ~isempty(errs)
                        rethrow(errs{1})
                    end
            end
        end
        function out = mov_final(obj)
           if ndims(obj.mov) == 3
               out = obj.mov;
           elseif ndims(obj.mov) == 4
               out = obj.mov_final_;
           else
               error('movie dimension is neither 3 nor 4.')
           end
        end
        
        function out = ratio(obj, varargin)
            out = obj.xyt.median(obj.mov);
            if size(out,2)>1
                out = obj.ratio_formula( out(:,1), out(:,2) );
            end
        end
    end
    
end

