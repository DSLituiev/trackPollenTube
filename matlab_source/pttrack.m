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
        xy_pos_marker
    end
    
    methods
        function obj = pttrack(varargin)
            obj.mov_filename = varargin{1};
            [ obj.kymogram, obj.mov, obj.xy_roi, vnRectBounds ] = movie2kymo( varargin{:} );
        end
        %%
        function plot(obj, varargin)
            obj.xy_roi.plot(obj.mov);
            
            obj.xy_pos_marker = scatter([], [], get(obj.xy_roi.ss, 'sizedata')*1.5, 'wh', 'linewidth', 2);
            scr_ls = addlistener( obj.xy_roi.img, 'Scroll', @(x,y)cb_scroll(obj,x,y) );
            btn_kymo = uicontrol('Style', 'pushbutton', 'String', 'Kymo',...
                'TooltipString', ['Show the kymogram', char(10) , ...
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
        function cb_scroll(obj, scr_mov, varargin)
            if ~isempty(obj.xyt)
                set(obj.xy_pos_marker, 'xdata', obj.xyt.x(scr_mov.tt), 'ydata', obj.xyt.y(scr_mov.tt))
            end
        end
        function cb_reconstruct(~,~,obj)
            obj.xyt = path_xyt( obj.xy_roi, obj.rt_roi );
            set(obj.xy_pos_marker, 'xdata', obj.xyt.x(scr_mov.tt), 'ydata', obj.xyt.y(scr_mov.tt))
        end
        function cb_visualize3d(~,~,obj)
            ff = visualize_kymo3D(obj.mov, obj.kymogram, obj.xy_roi, obj.rt_roi, obj.xy_roi.img.tt);
        end
    end
    
end

