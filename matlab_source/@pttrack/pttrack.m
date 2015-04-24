classdef pttrack < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mov;
        cropped_mov;
        cropping = false;
        xy_roi;
        rt_roi;
        xyt
        kymogram;
        mov_filename;
        fig_kymo
        fig_pix
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
    end
    
    methods        
        function obj = pttrack(varargin)            
            obj.mov_filename = varargin{1};
            [obj.kymogram, obj.mov, obj.xy_roi, obj.roiPath, ...
                obj.kymoPath, obj.movPath, obj.kymo_interp, obj.m4epsilon] = ...
                movie2kymo( varargin{:} );
        end
        %%
        function plot(obj, varargin)
            obj.xy_roi.plot(obj.mov);
            addlistener( obj.xy_roi.img, 'Scroll', @(x,y)cb_scroll(obj,x,y) );
            addlistener( obj.xy_roi, 'Saving', @(x,y)cb_xy_save(obj,x,y) );
            
            obj.xy_pos_marker = scatter([], [], pi*100, 'wo', 'linewidth', 2);
            uistack(obj.xy_pos_marker,'bottom');
            uistack(obj.xy_roi.img.im,'bottom');
            
            btn_kymo = uicontrol('Style', 'pushbutton', 'String', 'Kymo(f)',...
                'TooltipString', ['Show the kymogram for current ROI', char(10) , ...
                ''],...
                'Units','normalized', ...
                'Position', obj.xy_roi.button_slots(5,:),...
                'Callback', {@cb_plot_kymo, obj, true});
            
            btn_kymo = uicontrol('Style', 'pushbutton', 'String', 'Kymo(s)',...
                'TooltipString', ['Show the kymogram for current ROI', char(10) , ...
                ''],...
                'Units','normalized', ...
                'Position', obj.xy_roi.button_slots(6,:),...
                'Callback', {@cb_plot_kymo, obj, false});
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
            if isempty(obj.xyt)
                obj.kymo2roi('heuristic', p.Results.heuristic_flag);
            end
            
            if feval(@(h)(~isempty(h) && ishandle(h) && findobj(h,'type','figure')==h), obj.fig_kymo)
                obj.xyt.rt_roi.unbackup();
                close(obj.fig_kymo)
            end
            
            obj.fig_kymo = figure;
            obj.xyt.rt_roi.plot(obj.kymogram, 'keepcurve', p.Results.keepcurve_flag);
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
            btn_kymo = uicontrol(obj.fig_kymo, 'Style', 'pushbutton', 'String', 'Refine',...
                'TooltipString', ['Show the pixel intensities', char(10) , ...
                ''],...
                'Units','normalized', ...
                'Position', obj.xy_roi.button_slots(7,:),...
                'Callback', {@cb_refine, obj});
        end
        %%
        function cb_refine(~,~,obj)
%             obj.xyt.refine_path(obj.mov);
            
%             [~, grdiff] = raw_kymo_edge(single(obj.kymogram), 8, []);            
%             [ t0, x0 ] = segment_snake([ grdiff; double(quantile(grdiff(:), 0.05)) * ones(5, size(grdiff,2) )],  obj.xyt.rt_roi.x0, obj.xyt.rt_roi.y0, 'useAsEnergy', true );
%             [ t0, x0 ] = segment_snake( [obj.kymogram; double(quantile(obj.kymogram(:), 0.05)) * ones(5, size(obj.kymogram,2) )],  obj.xyt.rt_roi.x0, obj.xyt.rt_roi.y0 );
%             obj.xyt.rt_roi.x0 = round(t0);
%             obj.xyt.rt_roi.y0 = round(x0);
%             obj.xyt.rt_roi.replot_all()         
            obj.kymogram = obj.xyt.refine_path(obj.mov, 'visualize', true);
            
            obj.xy_roi = obj.xyt.xy_roi;
%             delete(obj.xyt);
%             obj.kymo2roi('heuristic', true);
            
%             obj.fig_kymo = figure;
%             obj.xyt.rt_roi.plot(obj.kymogram, 'm+', 'keepcurve', true);
            cb_plot_kymo([],[],obj, true, true);
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
        function varargout = draw_pixels(obj)            
            if isempty(obj.xyt)
                cb_track(obj);
            end
            if isfigure(obj.fig_pix)
                close(obj.fig_pix)
            end
            obj.xyt.fast = false;
%             obj.xyt.calc_coordinates()
            obj.xyt.apply_mask(obj.xy_roi.img.mov, obj.xyt.radius);
            obj.fig_pix = obj.xyt.plot_pixels(obj.fig_pix, 'movPath', obj.xy_roi.img.mov, 'radius', obj.xyt.radius);
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
        end
        %%
        function out = kymo(obj,varargin)
            out = obj.kymogram; % alias
        end
        %%
        function out = pixels(obj,varargin)
            out = obj.xyt.pixels(varargin{:});
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
            [rt_roi, status] = kymo2roi( obj.kymogram, replace_extension(obj.mov_filename, '-kymo.roi'),  0, varargin{:});            
            obj.xyt = path_xyt( obj.xy_roi, rt_roi);
        end
        %%
        function cb_xy_save(obj, ~, varargin)
            obj.kymo2roi();
            obj.upd_kymo();
            cb_track(obj)
            if isfigure(obj.fig_kymo)                
                obj.xyt.rt_roi.unbackup;
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
%                 'ydata', obj.xyt.yt(obj.xy_roi.img.tt), ...
%                 'SizeData', pi * obj.xyt.radius^2)            
        end
        
        function cb_radius(H,~, obj)
            obj.xyt.radius = str2double(get(H,'string'));
            obj.xyt.calc_coordinates()
            set(obj.xy_pos_marker, 'SizeData', pi * obj.xyt.radius^2)
        end
        function cb_visualize3d(~,~,obj)
            ff = visualize_kymo3D(obj.mov, obj.kymogram, obj.xy_roi, obj.xyt.rt_roi, obj.xy_roi.img.tt);
        end
    end
    
end

