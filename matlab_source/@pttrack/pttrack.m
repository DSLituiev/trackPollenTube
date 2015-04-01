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
        kymo_fig
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
            scr_ls = addlistener( obj.xy_roi.img, 'Scroll', @(x,y)cb_scroll(obj,x,y) );
            save_ls = addlistener( obj.xy_roi, 'Saving', @(x,y)cb_xy_save(obj,x,y) );
            
            obj.xy_pos_marker = scatter([], [], pi*100, 'wo', 'linewidth', 2);        
            
            btn_kymo = uicontrol('Style', 'pushbutton', 'String', 'Kymo',...
                'TooltipString', ['Show the kymogram for current ROI', char(10) , ...
                ''],...
                'Units','normalized', ...
                'Position', obj.xy_roi.button_slots(5,:),...
                'Callback', {@cb_plot_kymo, obj});
        end
        
        %%
        function cb_plot_kymo(~,~,obj)
            obj.kymo_fig = figure;
            if isempty(obj.rt_roi)
                [obj.rt_roi, status] = kymo2roi( obj.kymogram, replace_extension(obj.mov_filename, '-kymo.roi'),  0);
            end
            obj.rt_roi.plot(obj.kymogram);
                
            obj.rt_pos_marker_bg = scatter([], [], 120, 'wx', 'linewidth', 2.4);
            obj.rt_pos_marker = scatter([], [], 100,  obj.rt_roi.clr_, 'x', 'linewidth', 2);            
            
            btn_3dvis = uicontrol('Style', 'pushbutton', 'String', 'Track',...
                'TooltipString', ['Reconstruct the x,y,t-path of the object tip'],...
                'Units','normalized', ...
                'Position', obj.rt_roi.button_slots(5,:),...
                'Callback', {@cb_reconstruct, obj});
            
            btn_3dvis = uicontrol('Style', 'pushbutton', 'String', '3D',...
                'TooltipString', ['Visualize the kymogram and slices in 3D', char(10) , ...
                ''],...
                'Units','normalized', ...
                'Position', obj.rt_roi.button_slots(6,:),...
                'Callback', {@cb_visualize3d, obj});
        end
        %%
        function cb_rt_save(obj, ~, varargin)            
            cb_reconstruct([],[],obj);
        end
        %%
        function cb_xy_save(obj, ~, varargin)            
            cb_reconstruct([],[],obj)
            if feval(@(h)(~isempty(h) && ishandle(h) && findobj(h,'type','figure')==h), obj.kymo_fig)
                obj.kymogram = constructKymogram(obj.xy_roi, obj.mov, obj.kymo_interp, obj.m4epsilon);
                close(obj.kymo_fig)
                obj.rt_roi = [];
                cb_plot_kymo([],[], obj)
            end
        end
        %%
        function cb_scroll(obj, scr_mov, varargin)
            if ~isempty(obj.xyt)
                set(obj.xy_pos_marker, 'xdata', obj.xyt.x(scr_mov.tt), 'ydata', obj.xyt.y(scr_mov.tt))
                if  ~isempty(obj.rt_roi.figure) && ishandle(obj.rt_roi.figure)
                    set(obj.rt_pos_marker_bg, 'xdata', scr_mov.tt, 'ydata', obj.xyt.r(scr_mov.tt))
                    set(obj.rt_pos_marker, 'xdata', scr_mov.tt, 'ydata', obj.xyt.r(scr_mov.tt))
                end
            end
        end
        function cb_reconstruct(~,~,obj)
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
            set(obj.xy_pos_marker, 'xdata', obj.xyt.x(obj.xy_roi.img.tt), ...
                'ydata', obj.xyt.y(obj.xy_roi.img.tt), ...
                'SizeData', pi * obj.xyt.radius^2)            
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

