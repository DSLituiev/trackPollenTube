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
            
            obj.interp;
            
            obj.llbg = plot(obj.x, obj.y, lst, 'marker', 'none', 'color', 'w', 'linewidth', p.Results.linewidth + 1, p.Unmatched );
            hold all
            obj.ll   = plot(obj.x, obj.y,  lst, 'color', clr, 'linewidth', p.Results.linewidth, 'marker', 'none', p.Unmatched);
            
            obj.f = gcf;
            set(obj.f, 'WindowButtonUpFcn', {@stopDragFcn, obj})
            
            obj.ssbg = scatter(obj.x0, obj.y0, p.Results.markersize + 1, 'w', p.Results.markertype, 'linewidth', p.Results.linewidth * 1.2);
            obj.ss = scatter(obj.x0, obj.y0,  p.Results.markersize, clr, p.Results.markertype);
            
            set(get(obj.ss, 'Children'), 'HitTest','on', 'ButtonDownFcn', {@startDragFcn, obj})
            varargout = {obj.f};
        end
        
        function stopDragFcn(~,~, obj, varargin)
            set(obj.f, 'WindowButtonMotionFcn','')
        end
        
        function startDragFcn(~, ~, obj, varargin)
            rightClick = strcmp(get(obj.f, 'SelectionType'), 'alt');
            
            set(obj.f, 'WindowButtonMotionFcn', {@dragginFcn, obj, rightClick, varargin{:}})
        end
        
        function dragginFcn(~,~,obj, rightClick, varargin)
            pt = get(gca, 'CurrentPoint');
            chldrn = get(obj.ss, 'children');
            logInd = flipud( chldrn == gco) ;
            
            if ~rightClick
                x_ = get(gco, 'xData');
                y_ = get(gco, 'yData');
                
                obj.x0(logInd) = x_;
                obj.y0(logInd) = y_;
                
                set(gco, 'xData', pt(1,1))
                set(gco, 'yData', pt(1,2))
                
                obj.interp;
                
                fprintf('x:\t%f\t%f\t', obj.x0(logInd), x_ )
                fprintf('y:\t%f\t%f\n', obj.y0(logInd), y_ )
            else
                obj.x0 = obj.x0(~logInd);
                obj.y0 = obj.y0(~logInd);
                delete(gco);  
%                 set(obj.ss,'children', chldrn(flipud(logInd)) );
            end
            
            set(obj.ll,   'xData', obj.x, 'yData', obj.y)
            set(obj.llbg, 'xData', obj.x, 'yData', obj.y)
            set(obj.ssbg, 'xData', obj.x0, 'yData', obj.y0)
            
        end
        
        function interp(obj)
            if strcmpi(obj.interp1, 'none')
                obj.x = obj.x0;
                obj.y = obj.y0;
            else
                [obj.x, obj.y] = interp_implicit(obj.x0, obj.y0, obj.interp1);
            end
        end
        
    end
    
end

