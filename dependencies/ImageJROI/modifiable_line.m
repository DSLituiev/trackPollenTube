classdef modifiable_line < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract = true)
        x0
        y0
        x
        y
    end
    properties
        r0
        r
        N
        f
        ll
        llbg
        ss
        ssbg
        interp1 = 'pchip';
        img = [];
        x0_bu % back up
        y0_bu % back up
        markersize;
        markertype;
        linewidth;
        clr;
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
        
        function varargout = plot(obj, img, varargin)
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            addOptional(p, 'linespec', 'm+', @(x)(ischar(x)));
            addParamValue(p, 'markertype', '+', @(x)( any(strcmpi(x, {'o','+','*','.','x', 's', 'd', '^','v','>','<', 'p', 'h', 'none'}))));
            addParamValue(p, 'linewidth', 3, @(x)(isscalar(x)));
            addParamValue(p, 'markersize', 100, @(x)(isscalar(x)));
            addParamValue(p, 'color', '', @(x)(isscalar(x) || isnumeric(x) ));
            parse(p, varargin{:});
            %%
            if nargin> 1
                obj.img = img;
            end
            if ~isempty(obj.img)
                imagesc(obj.img)
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
                obj.clr = p.Results.color;
            elseif feval(@(x)( any(strcmpi(x, {'y', 'm', 'c', 'r', 'g', 'b', 'w', 'k'}))),  p.Results.linespec(1))
                obj.clr = p.Results.linespec(1);
            end
            obj.markersize = p.Results.markersize;
            obj.markertype = p.Results.markertype;
            obj.linewidth = p.Results.linewidth;
            %%
            
            obj.backup();
            obj.interp;
            
            obj.llbg = plot(obj.x, obj.y, lst, 'marker', 'none', 'color', 'w', 'linewidth', p.Results.linewidth + 1, p.Unmatched );
            hold all
            obj.ll   = plot(obj.x, obj.y,  lst, 'color',  obj.clr, 'linewidth', p.Results.linewidth, 'marker', 'none', p.Unmatched);
            set(obj.ll, 'HitTest','on', 'ButtonDownFcn', {@addPointFcn, obj})
            
            obj.f = gcf;
            set(obj.f, 'WindowButtonUpFcn', {@stopDragFcn, obj})
            
            obj.ssbg = scatter(obj.x0, obj.y0, p.Results.markersize * 1.2, 'w',...
                p.Results.markertype, 'linewidth', p.Results.linewidth * 1.2);
            obj.scatter_();
            
            set(get(obj.ss, 'Children'), 'HitTest','on', 'ButtonDownFcn', {@startDragFcn, obj})
            
            varargout = {obj.f};
            % Create push button
            btn_sv = uicontrol('Style', 'pushbutton', 'String', 'Save',...
                'Units','normalized', ...
                'Position', [0.02 0.02 0.12 0.04],...
                'Callback', {@save, obj});
            btn_rst = uicontrol('Style', 'pushbutton', 'String', 'Reset',...
                'Units','normalized', ...
                'Position', [0.20 0.02 0.12 0.04],...
                'Callback', {@reset, obj});
        end
        %%
        function redraw(obj)
            %     set(obj.ss, 'xData', obj.x0, 'yData', obj.y0)
            set(obj.ssbg, 'xData', obj.x0, 'yData', obj.y0)
            obj.interp;
            set(obj.ll,   'xData', obj.x, 'yData', obj.y)
            set(obj.llbg, 'xData', obj.x, 'yData', obj.y)
        end
        %%
        function redraw_all(obj)
            obj.redraw();
            drawnow
            delete(obj.ss);
            obj.scatter_();
            set(get(obj.ss, 'Children'), 'HitTest','on', 'ButtonDownFcn', {@startDragFcn, obj})
        end
        
        function scatter_(obj)
            obj.ss = scatter(obj.x0, obj.y0,  obj.markersize*0.75,  obj.clr, ...
                obj.markertype, 'linewidth', obj.linewidth*0.75 );
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
        function save(~, ~, obj, varargin)
            obj.check_bounds();
            obj.backup();
            %     fprintf('saving function has not been implemented in the subclass `%s`\n', class(obj) );
        end
        
        function reset(~, ~, obj, varargin)
            obj.unbackup();
            obj.redraw_all();
            % fprintf(' reset function has not been implemented in the subclass `%s`\n', class(obj) );
        end
        %%
        function addPointFcn(~,~, obj, varargin)
            rightClick = strcmp(get(obj.f, 'SelectionType'), 'alt');
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
                set([obj.ss, obj.ssbg],'XData', obj.x0);
                set([obj.ss, obj.ssbg],'YData', obj.y0);
                set(get(obj.ss, 'Children'), 'HitTest','on', 'ButtonDownFcn', {@startDragFcn, obj})
                drawnow
            end
        end
        %%
        function stopDragFcn(~,~, obj, varargin)
            set(obj.f, 'WindowButtonMotionFcn','')
        end
        %%
        function startDragFcn(curr_obj, ~, obj, varargin)
            rightClick = strcmp(get(obj.f, 'SelectionType'), 'alt');
            if ~rightClick
                set(obj.f, 'WindowButtonMotionFcn', {@dragginFcn, obj, curr_obj, varargin{:}})
            else
                chldrn = get(obj.ss, 'children');
                logInd = flipud( chldrn == gco) ;
                obj.x0 = obj.x0(~logInd);
                obj.y0 = obj.y0(~logInd);
                delete(gco);
                obj.redraw();
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
            
            obj.redraw();
        end
        %%
        function interp(obj)
            if strcmpi(obj.interp1, 'none')
                obj.x = obj.x0;
                obj.y = obj.y0;
            else
                [obj.x, obj.y, obj.r, obj.r0] = interp_implicit(obj.x0, obj.y0, obj.interp1);
            end
        end
    end
    
end

