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
            obj.set_backup();
        end
        function set_backup(obj)
            obj.x0_bu = obj.x0; % back up
            obj.y0_bu = obj.y0; % back up
        end
        
        function varargout = plot(obj, varargin)
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
                clr = p.Results.color;
            elseif feval(@(x)( any(strcmpi(x, {'y', 'm', 'c', 'r', 'g', 'b', 'w', 'k'}))),  p.Results.linespec(1))
                clr = p.Results.linespec(1);
            end
            
            obj.set_backup();
            obj.interp;
            
            obj.llbg = plot(obj.x, obj.y, lst, 'marker', 'none', 'color', 'w', 'linewidth', p.Results.linewidth + 1, p.Unmatched );
            hold all
            obj.ll   = plot(obj.x, obj.y,  lst, 'color', clr, 'linewidth', p.Results.linewidth, 'marker', 'none', p.Unmatched);
            
            obj.f = gcf;
            set(obj.f, 'WindowButtonUpFcn', {@stopDragFcn, obj})
            
            obj.ssbg = scatter(obj.x0, obj.y0, p.Results.markersize + 1, 'w', p.Results.markertype, 'linewidth', p.Results.linewidth * 1.2);
            obj.ss = scatter(obj.x0, obj.y0,  p.Results.markersize, clr, p.Results.markertype);
            
            set(get(obj.ss, 'Children'), 'HitTest','on', 'ButtonDownFcn', {@startDragFcn, obj})
            
            set(obj.ll, 'HitTest','on', 'ButtonDownFcn', {@addPointFcn, obj})
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
        
        function save(inpobj, ~, obj, varargin)
            obj.set_backup();
            %             fprintf('saving function has not been implemented in the subclass `%s`\n', class(obj) );
        end
        
        function reset(inpobj, ~, obj, varargin)
            obj.x0 = obj.x0_bu; % back up
            obj.y0 = obj.y0_bu; % back up
            obj.redraw();
            set(obj.ss, 'xData', obj.x0, 'yData', obj.y0)
            % fprintf(' reset function has not been implemented in the subclass `%s`\n', class(obj) );
        end
        
        function addPointFcn(~,~, obj, varargin)
            rightClick = strcmp(get(obj.f, 'SelectionType'), 'alt');
            if rightClick
                pt = get(gca, 'CurrentPoint');
                x_ = pt(1,1);
                y_ = pt(1,2);
                
                obj.x0 = sort([obj.x0; x_]);
                obj.y0 = sort([obj.y0; y_]);
                set([obj.ss, obj.ssbg],'XData', obj.x0);
                set([obj.ss, obj.ssbg],'YData', obj.y0);
                set(get(obj.ss, 'Children'), 'HitTest','on', 'ButtonDownFcn', {@startDragFcn, obj})
                drawnow
            end
        end
        
        function stopDragFcn(~,~, obj, varargin)
            set(obj.f, 'WindowButtonMotionFcn','')
        end
        
        function startDragFcn(~, ~, obj, varargin)
            rightClick = strcmp(get(obj.f, 'SelectionType'), 'alt');
            if ~rightClick
                set(obj.f, 'WindowButtonMotionFcn', {@dragginFcn, obj, varargin{:}})
            else
                chldrn = get(obj.ss, 'children');
                logInd = flipud( chldrn == gco) ;
                obj.x0 = obj.x0(~logInd);
                obj.y0 = obj.y0(~logInd);
                delete(gco);
                obj.redraw();
            end
        end
        
        function dragginFcn(~,~,obj, varargin)
            pt = get(gca, 'CurrentPoint');
            chldrn = get(obj.ss, 'children');
            logInd = flipud( chldrn == gco) ;
            x_ = get(gco, 'xData');
            y_ = get(gco, 'yData');
            
            obj.x0(logInd) = x_;
            obj.y0(logInd) = y_;
            
            set(gco, 'xData', pt(1,1))
            set(gco, 'yData', pt(1,2))
            
            
            fprintf('x:\t%f\t%f\t', obj.x0(logInd), x_ )
            fprintf('y:\t%f\t%f\n', obj.y0(logInd), y_ )
            
            obj.redraw();
        end
        
        function interp(obj)
            if strcmpi(obj.interp1, 'none')
                obj.x = obj.x0;
                obj.y = obj.y0;
            else
                [obj.x, obj.y] = interp_implicit(obj.x0, obj.y0, obj.interp1);
            end
        end
        function redraw(obj)
            set(obj.ssbg, 'xData', obj.x0, 'yData', obj.y0)
            
            obj.interp;
            set(obj.ll,   'xData', obj.x, 'yData', obj.y)
            set(obj.llbg, 'xData', obj.x, 'yData', obj.y)
        end
        
    end
    
end

