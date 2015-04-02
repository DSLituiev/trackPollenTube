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
            
            btn_kymo = uicontrol('Style', 'pushbutton', 'String', 'Kymo',...
                'TooltipString', ['Show the kymogram for current ROI', char(10) , ...
                ''],...
                'Units','normalized', ...
                'Position', obj.xy_roi.button_slots(5,:),...
                'Callback', {@cb_plot_kymo, obj});
        end
        %%
        function cb_plot_kymo(~,~,obj)
            if feval(@(h)(~isempty(h) && ishandle(h) && findobj(h,'type','figure')==h), obj.fig_kymo)
                obj.rt_roi.unbackup();
                close(obj.fig_kymo)
            end
            obj.fig_kymo = figure;
            if isempty(obj.rt_roi)
                obj.kymo2roi();
            end
            obj.rt_roi.plot(obj.kymogram);
            addlistener( obj.rt_roi, 'Saving', @(x,y)cb_rt_save(obj,x,y) );
            set(obj.fig_kymo, 'WindowScrollWheelFcn', {@setframe_wheel, obj.xy_roi.img})
                
            obj.rt_pos_marker_bg = line(0, 0, 'Marker','x', 'color','w', 'markersize', 5, 'linewidth', 2.4);
            obj.rt_pos_marker = line(0, 0, 'Marker', 'x', 'color', obj.rt_roi.clr_, 'markersize', 5, 'linewidth', 2);            
            
            cb_track(obj)
            
            btn_3dvis = uicontrol('Style', 'pushbutton', 'String', '3D',...
                'TooltipString', ['Visualize the kymogram and slices in 3D', char(10) , ...
                ''],...
                'Units','normalized', ...
                'Position', obj.rt_roi.button_slots(5,:),...
                'Callback', {@cb_visualize3d, obj});
            btn_kymo = uicontrol('Style', 'pushbutton', 'String', 'Pixels',...
                'TooltipString', ['Show the pixel intensities', char(10) , ...
                ''],...
                'Units','normalized', ...
                'Position', obj.xy_roi.button_slots(6,:),...
                'Callback', {@cb_plot_pix, obj});
        end
        %%
        function cb_plot_pix(~,~,obj)
            if isempty(obj.xyt)
                cb_track(obj);
            end
            if isfigure(obj.fig_pix)
                close(obj.fig_pix)
            end
            obj.fig_pix = obj.xyt.plot_pixels(obj.xy_roi.img.mov, obj.xyt.radius);
        end
        %%
        function cb_rt_save(obj, ~, varargin)
            cb_track(obj);
            if isfigure(obj.fig_pix)
                cb_plot_pix([],[],obj)
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
        function status = kymo2roi(obj)
            if isempty(obj.kymogram)
                obj.upd_kymo();
            end
            [obj.rt_roi, status] = kymo2roi( obj.kymogram, replace_extension(obj.mov_filename, '-kymo.roi'),  0);
        end
        %%
        function cb_xy_save(obj, ~, varargin)
            obj.kymo2roi();
            obj.upd_kymo();
            cb_track(obj)
            if isfigure(obj.fig_kymo)                
                obj.rt_roi.unbackup;
                close(obj.fig_kymo)
                obj.rt_roi = [];
                cb_plot_kymo([],[], obj)
            end
        end
        %%
        function cb_scroll(obj, scr_mov, varargin)
            if ~isempty(obj.xyt)
                set(obj.xy_pos_marker, 'xdata', obj.xyt.x(scr_mov.tt), 'ydata', obj.xyt.y(scr_mov.tt))
                if  ~isempty(obj.rt_roi.figure) && ishandle(obj.rt_roi.figure)
                    set(obj.rt_pos_marker_bg, 'xdata', scr_mov.tt*[1,1], 'ydata', obj.xyt.r(scr_mov.tt) + obj.xyt.radius*[-1, 1])
                    set(obj.rt_pos_marker, 'xdata', scr_mov.tt*[1,1], 'ydata', obj.xyt.r(scr_mov.tt) + obj.xyt.radius*[-1, 1])
                end
            end
        end
        function cb_track(obj)
            % reconstruct the x,y,t-track
            if isempty(obj.rt_roi)
                obj.kymo2roi();
            end
            obj.xyt = path_xyt( obj.xy_roi, obj.rt_roi);
            if isempty(obj.radius_field) || ~ishandle(obj.radius_field)
            obj.radius_field = uicontrol(obj.xy_roi.figure, 'style','edit',...         
                'callback',{@cb_radius, obj},...
                'String', obj.xyt.radius,...
                'Units','normalized', ...
                'Position', obj.rt_roi.button_slots(7,:),...
                'TooltipString',['Scroll through movie frames', char(10),...
                '[also works with mouse wheel]' ]); 
            end
            obj.xyt.calc_coordinates(obj.xyt.radius)
            cb_scroll(obj, obj.xy_roi.img)
%             set(obj.xy_pos_marker, 'xdata', obj.xyt.x(obj.xy_roi.img.tt), ...
%                 'ydata', obj.xyt.y(obj.xy_roi.img.tt), ...
%                 'SizeData', pi * obj.xyt.radius^2)            
        end
        
        function cb_radius(H,~, obj)
            obj.xyt.radius = str2double(get(H,'string'));
            obj.xyt.calc_coordinates(obj.xyt.radius)
            set(obj.xy_pos_marker, 'SizeData', pi * obj.xyt.radius^2)
        end
        function cb_visualize3d(~,~,obj)
            ff = visualize_kymo3D(obj.mov, obj.kymogram, obj.xy_roi, obj.rt_roi, obj.xy_roi.img.tt);
        end
    end
    
end

