classdef modifiable_line < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract = true)
        x0
        y0
        x
        y
        L
    end
    properties
        r0
        r
        N
        figure
        ll
        llbg
        ss
        ssbg
        interp1 = 'pchip';
        img = [];
        im_obj;
        x0_bu % back up
        y0_bu % back up        
        button_slots = [0.02 0.02 0.12 0.04;...
            0.16 0.02 0.10 0.04;...
            0.28 0.02 0.10 0.04;...
            0.40 0.02 0.10 0.04;...
            0.52 0.02 0.10 0.04;...
            0.64 0.02 0.10 0.04;...
            0.76 0.02 0.10 0.04;...
            0.88 0.02 0.10 0.04;...
            ];
        clr_;
    end
    properties (GetAccess = private)
        markersize_;
        markertype_;
        linewidth_;
        lst_;
        unmatched_args_;

        drawmode = false;
        btn_draw;
        help_text_h
    end
    events
        Modified
    end
        
    methods
        function obj = modifiable_line(varargin)
            if nargin < 2
                N = 10;
                obj.x0 = sort(100*rand(N,1));
                obj.y0 = sort(100*rand(N,1));
            else
                obj.x0 = varargin{1};
                obj.y0 = varargin{2};
            end
            obj.backup();
        end
        %%
        function backup(obj)
            obj.x0_bu = obj.x0; % back up
            obj.y0_bu = obj.y0; % back up
        end
        %%
        function unbackup(obj)
            obj.x0 = obj.x0_bu; % back up
            obj.y0 = obj.y0_bu; % back up
        end
        
        function close_figure(~,~, obj)
            % Close request function
            % to display a question dialog box
            if numel(obj.x0) == numel(obj.x0_bu) && ...
                    numel(obj.y0) == numel(obj.y0_bu) && ...
                    ~any(obj.x0 - obj.x0_bu) && ~any(obj.y0 - obj.y0_bu)
                delete(gcf);
                return
            end
            
            selection = questdlg('Save current ROI?',...
                'Close Request Function',...
                'Yes','No','Yes');
            switch selection,
                case 'Yes',
                    obj.backup();
                    delete(gcf)
                    return
                case 'No',
                    obj.unbackup();
                    delete(gcf)
                    return
            end
        end
        
        function varargout = plot(obj, img, varargin)
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            addOptional(p, 'linespec', 'm+', @(x)(ischar(x)));
            addParamValue(p, 'markertype', '+', @(x)( any(strcmpi(x, {'o','+','*','.','x', 's', 'd', '^','v','>','<', 'p', 'h', 'none'}))));
            addParamValue(p, 'linewidth', 3, @(x)(isscalar(x)));
            addParamValue(p, 'markersize', 100, @(x)(isscalar(x)));
            addParamValue(p, 'color', '', @(x)(isscalar(x) || isnumeric(x) ));
            addParamValue(p, 'frame', 1, @(x)(isscalar(x) && isnumeric(x) ));
            parse(p, varargin{:});
            %%
            if nargin> 1
                obj.img = img;
            end
            if ~isempty(obj.img)
                if ndims(obj.img)>2
                    obj.img = scrollable_movie(obj.img);
                end
                obj.im_obj = imagesc(obj.img);
                hold all;
            end
            if ~isempty(p.Results.linespec)
                if feval(@(x)( any(strcmpi(x, {'-', '--', ':', '-.'}))), p.Results.linespec(1) )
                    lst = p.Results.linespec(1);
                elseif numel(p.Results.linespec)>1 &&...
                        feval(@(x)( any(strcmpi(x, {'-', '--', ':', '-.'}))), p.Results.linespec(2) )
                    lst = p.Results.linespec(2);
                else
                    lst = '-';
                end
            end
            if ~isempty(p.Results.color)
                obj.clr_ = p.Results.color;
            elseif feval(@(x)( any(strcmpi(x, {'y', 'm', 'c', 'r', 'g', 'b', 'w', 'k'}))),  p.Results.linespec(1))
                obj.clr_ = p.Results.linespec(1);
            end
            obj.markersize_ = p.Results.markersize;
            obj.markertype_ = p.Results.markertype;
            obj.linewidth_ = p.Results.linewidth;
            obj.lst_ = lst;
            obj.unmatched_args_ = p.Unmatched;
            %%
            obj.backup();
            if ~isempty(obj.x0)
                obj.interp;
            end
            %            
            obj.figure = gcf;
            set(obj.figure, 'WindowButtonUpFcn', {@stopDragFcn, obj}, 'CloseRequestFcn', {@close_figure, obj})
            ax = findall(obj.figure,'type','axes');
            if ~isempty(ax)
                axes(ax(1));
                hold all
            end
            
            obj.plot_lines_()
                
            obj.ssbg = scatter(obj.x0, obj.y0, obj.markersize_ * 1.2, 'w',...
                obj.markertype_, 'linewidth', obj.linewidth_ * 1.2);
            obj.scatter_();
            
            set(get(obj.ss, 'Children'), 'HitTest','on', 'ButtonDownFcn', {@startDragFcn, obj})            
            
            set(get(gca, 'Children'), 'HitTest','on', 'ButtonDownFcn', {@axes_click, obj})
            
            varargout = {obj.figure};
            %% Create push buttons
            obj.btn_draw = uicontrol('Style', 'togglebutton', 'String', 'Draw',...
                'TooltipString', ['Add points to the end of the line', char(10), 'if up, curve can be modified by pasting intermediate points'],...
                'Units','normalized', ...
                'Position', obj.button_slots(1,:),...
                'Callback', {@draw_curve, obj});
            btn_clr = uicontrol('Style', 'pushbutton', 'String', 'Clear',...
                'TooltipString', ['Clear the curve completely', char(10) , ...
                'In case, you can restore it with "Reset" button'],...
                'Units','normalized', ...
                'Position', obj.button_slots(2,:),...
                'Callback', {@clear_curve, obj});
            btn_rst = uicontrol('Style', 'pushbutton', 'String', 'Reset',...
                'TooltipString', ['Restore the saved curve'],...
                'Units','normalized', ...
                'Position', obj.button_slots(3,:),...
                'Callback', {@reset, obj});
            btn_sv = uicontrol('Style', 'pushbutton', 'String', 'Save',...
                'TooltipString', ['Save current curve', char(10), ...
                '[internally and to the file if specified]'],...
                'Units','normalized', ...
                'Position', obj.button_slots(4,:),...
                'Callback', {@save, obj});
            btn_clr = uicontrol('Style', 'togglebutton', 'String', '?',...
                'Units','normalized', ...
                'Position', [0.92 0.02 0.04 0.04],...
                'Callback', {@show_help, obj});
            
            if isempty(obj.x0)
                set(obj.btn_draw, 'Value', 1);
                draw_curve(obj.btn_draw, [], obj);
            end
        end
        %%
        function replot(obj)
            %     set(obj.ss, 'xData', obj.x0, 'yData', obj.y0)
            set(obj.ssbg, 'xData', obj.x0, 'yData', obj.y0)
                if numel(obj.x0) > 1
                    obj.interp();
                else
                    obj.x = obj.x0;
                    obj.y = obj.y0;
                end
                
            if ~isempty(obj.ll)
                set(obj.ll,   'xData', obj.x, 'yData', obj.y)
                set(obj.llbg, 'xData', obj.x, 'yData', obj.y)
            else
                obj.plot_lines_()
                uistack(obj.ssbg, 'top')
                uistack(obj.ss, 'top')
            end
        end
        %%
        function replot_all(obj)
            obj.replot();
            drawnow
            delete(obj.ss);
            obj.scatter_();
            set(get(obj.ss, 'Children'), 'HitTest','on', 'ButtonDownFcn', {@startDragFcn, obj})
        end
        
        function scatter_(obj)
            obj.ss = scatter(obj.x0, obj.y0,  obj.markersize_*0.75,  obj.clr_, ...
                obj.markertype_, 'linewidth', obj.linewidth_*0.75 );
        end
        function plot_lines_(obj)
            obj.llbg = plot(obj.x, obj.y, obj.lst_, 'marker', 'none', 'color', 'w', 'linewidth', obj.linewidth_ + 1,  obj.unmatched_args_);
            hold all
            obj.ll   = plot(obj.x, obj.y,  obj.lst_, 'color',  obj.clr_, 'linewidth', obj.linewidth_, 'marker', 'none',  obj.unmatched_args_);
            set(obj.ll, 'HitTest','on', 'ButtonDownFcn', {@addPointFcn, obj})
        end

        function check_bounds(obj)
            obj.x0(obj.x0<1) = 1;
            obj.y0(obj.y0<1) = 1;
            if ~isempty(obj.img)
                X = size(obj.img, 2);
                Y = size(obj.img, 1);
                obj.x0(obj.x0>X) = X;
                obj.y0(obj.y0>Y) = Y;
            end
        end
        %% button callback functions
        function show_help(but_obj, ~, obj)
            if get(but_obj, 'Value')
                axlims = axis;
                obj.help_text_h = text(axlims(1) + 0.05*axlims(2), axlims(3) + 0.05*axlims(4), ...
                [    'Draw:', char(10), ...
                'allows to add {\bf new control points to the end of the ROI} curve ', char(10), ...
                'on mouse clicks.', char(10),...
                'If not pressed, {\bf internal control points} can be added ', char(10),...
                'by right clicks on the ROI curve. The {\bf existing control points} ', char(10), ...
                'can be moved when clicked with the left mouse button', char(10),char(10),...
                'Clear:', char(10), ...
                'clears all control points of the ROI curve.', char(10),char(10),...                
                'Save:', char(10), ...
                'saves the ROI control points', char(10), ...
                '(1) to the internal buffer and', char(10), '(2) to a command-line specified file', char(10),char(10), ...
                'Reset:', char(10), ...
                'resets the ROI to the state saved in the internal buffer', char(10),char(10), ...
                'Help:', char(10), 'press the "?" button again to hide this message', char(10),char(10),... 
                'Movie scrolling: ',char(10), ...
                'use the side scroll bar or your mouse wheel. Click on the ',char(10), ...
                'scroll bar with the mouse to increase the wheel step',...
                ],...
                'BackgroundColor', 'w', 'VerticalAlignment', 'top', 'FontSize', 12,...
                'interpreter', 'tex', 'fontname', 'times' );
            else
                delete(obj.help_text_h)
            end
        end
        %%
        function save(~, ~, obj, varargin)
            obj.check_bounds();
            obj.backup();
            %     fprintf('saving function has not been implemented in the subclass `%s`\n', class(obj) );
        end
        
        function reset(~, ~, obj, varargin)
            obj.unbackup();
            obj.replot_all();
            % fprintf(' reset function has not been implemented in the subclass `%s`\n', class(obj) );
        end
        %%
        function clear_curve(~,~, obj)            
                obj.x0 = [];
                obj.y0 = [];
                obj.x = [];
                obj.y = [];
                %% hide
                set([obj.ss, obj.ssbg, obj.ll, obj.llbg], 'XData', obj.x0, 'YData', obj.y0);
                set(obj.btn_draw, 'Value', 1)
                draw_curve(obj.btn_draw, [], obj)
        end
        %%
        function draw_curve(but_obj, ~, obj, varargin)
            obj.drawmode = get(but_obj, 'Value');  
            if obj.drawmode
                set(but_obj,'String', 'Drawing...')
            else
                set(but_obj,'String', 'Draw')
            end
        end
        %%
        function axes_click(~,~,obj)
            rightClick = strcmp(get(obj.figure, 'SelectionType'), 'alt');
            if obj.drawmode && ~rightClick                
                pt = get(gca, 'CurrentPoint');
                x_ = pt(1,1);
                y_ = pt(1,2);
                obj.x0 = [obj.x0; x_];
                obj.y0 = [obj.y0; y_];
                %% replot
                obj.replot_all();
            elseif strcmpi(get(gco, 'type'), 'line') && rightClick
                addPointFcn(gco,[], obj);
            end
        end
        %%
        function addPointFcn(~,~, obj, varargin)
            rightClick = strcmp(get(obj.figure, 'SelectionType'), 'alt');
            if rightClick
                pt = get(gca, 'CurrentPoint');
                x_ = pt(1,1);
                y_ = pt(1,2);
                %% find location of the new point within the line
                [~, ind] = min(abs(obj.y - y_) + abs(obj.x - x_));
                before_new_point = obj.r0 < obj.r( round(ind) ) ;
                % subs = find(before_new_point, 1, 'first');
                obj.x0 = [obj.x0(before_new_point); x_; obj.x0(~before_new_point)];
                obj.y0 = [obj.y0(before_new_point); y_; obj.y0(~before_new_point)];
                obj.interp();
                %% replot
                set([obj.ss, obj.ssbg],'XData', obj.x0,'YData', obj.y0);
                set(get(obj.ss, 'Children'), 'HitTest','on', 'ButtonDownFcn', {@startDragFcn, obj})
                drawnow
            end
        end
        %%
        function stopDragFcn(~,~, obj, varargin)
            set(obj.figure, 'WindowButtonMotionFcn','')
        end
        %%
        function startDragFcn(curr_obj, ~, obj, varargin)
            rightClick = strcmp(get(obj.figure, 'SelectionType'), 'alt');
            if ~rightClick
                set(obj.figure, 'WindowButtonMotionFcn', {@dragginFcn, obj, curr_obj, varargin{:}})
            else
                chldrn = get(obj.ss, 'children');
                logInd = flipud( chldrn == gco) ;
                obj.x0 = obj.x0(~logInd);
                obj.y0 = obj.y0(~logInd);
                delete(gco);
                obj.replot();
            end
        end
        %%
        function dragginFcn(curr_obj, ~, obj, curr_obj0, varargin)
            pt = get(gca, 'CurrentPoint');
            chldrn = get(obj.ss, 'children');
            logInd = flipud( chldrn == curr_obj0) ;
            x_ = get(curr_obj0, 'xData');
            y_ = get(curr_obj0, 'yData');
            
            obj.x0(logInd) = round(x_);
            obj.y0(logInd) = round(y_);
            
            set(gco, 'xData', pt(1,1))
            set(gco, 'yData', pt(1,2))
            
            fprintf('x:\t%u\t', obj.x0(logInd) ) % , x_ )
            fprintf('y:\t%u\n', obj.y0(logInd) ) % , y_ )
            
            obj.replot();
        end
        %%
        function interp(obj)
            obj.x0 = round(obj.x0);
            obj.y0 = round(obj.y0);
            if strcmpi(obj.interp1, 'none')
                obj.x = obj.x0;
                obj.y = obj.y0;
            else
                %% an overkill safety for debugging mode
                replicates = (diff(obj.x0).^2 +diff(obj.y0).^2) == 0;
                if any(replicates)
                    obj.x0 = obj.x0(~replicates,:);
                    obj.y0 = obj.y0(~replicates,:);
                    warning('replicate control points resolved')
                end
                [obj.x, obj.y, obj.r, obj.r0] = interp_implicit(obj.x0, obj.y0, obj.interp1);
                obj.L = obj.r(end);
            end
            notify(obj, 'Modified')
        end
    end
    
end

