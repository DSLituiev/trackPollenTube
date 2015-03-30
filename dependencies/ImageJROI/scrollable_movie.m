classdef scrollable_movie
    %SCROLLABLE_MOVIE a class for movie display with a scroll bar
    % redefines methods:
    % - imagesc
    % - size
    % - ndims    
    
    properties
        mov
        mov_size
        T
        im
        figure
        axes
        slider;
        color = false;
    end
    
    methods
        function out = ndims(obj)
            out = ndims(obj.mov);
        end
        function out = size(obj, varargin)
            out = size(obj.mov, varargin{:});
        end
        %         function out = isnumeric(obj)
        %             out = true;
        %         end
        function obj = copy_fields(obj, inobj)
            if isstruct(inobj)
                rf = fieldnames(inobj);
            elseif isobject(inobj)
                rf = properties(inobj);
            end
            for ii = 1:numel(rf)
                if isprop(obj, rf{ii})
                    obj.(rf{ii}) = inobj.(rf{ii});
                else
                    warning('ImageJROI:unknownPropery' ,'omitting a property: %s', rf{ii})
                end
            end
        end
        function obj = scrollable_movie(movPath, varargin)
            %% check the input parameters
            %             p = inputParser;
            %             p.KeepUnmatched = true;
            %             addRequired(p, 'movPath', @(x)( (readable(x) ) || ( isnumeric(x) && ( numel(size(x))==3 ) ) ) );
            %             parse(p, movPath, varargin{:});
            %%
            if readable(movPath)
                obj.mov = readTifSelected( movPath );
                obj.mov_size = get_tiff_size( movPath );
            elseif strcmpi(class(movPath), class(obj))
                obj = obj.copy_fields(movPath);
            elseif feval( @(x)(isnumeric(x) && ( numel(size(x))>=3 ) ), movPath )
                obj.mov = movPath;
                obj.mov_size = size(obj.mov);
            end
            
            obj.T = obj.mov_size(end);
            if ndims(obj.mov)> 3
                obj.color = true;
            end
        end
        
        function replot_(obj, tt, varargin)
            if obj.color
                set(obj.im, 'CData', obj.mov(:,:, :,tt)) ;
            else
                set(obj.im, 'CData', obj.mov(:,:,tt)) ;
            end
            title(obj.axes, sprintf('frame %u', tt))
            % set(obj.figure, 'name', sprintf('frame %u', tt))
        end
        
        function setframe_(obj, tt)
            if obj.color
                set(obj.im, 'CData', obj.mov(:,:,:, tt)) ;
            else
                set(obj.im, 'CData', obj.mov(:,:,tt)) ;
            end
        end
        
        function setframe_slide(cobj, ~, obj, varargin)
            tt = round(get(cobj, 'Value'));
            obj.setframe_(tt);
        end
        
        function setframe_wheel(cobj, eventdata, obj, varargin)            
            type = get(gco, 'type');
            uicontr_flag = strcmp(type, 'uicontrol');
            if uicontr_flag
                steps = get(gco, 'SliderStep');
                step =  round( steps(2)*obj.T );
            else
                step = 1;
            end
%             if (strcmp(type, 'image') || uicontr_flag)
                tt = round(get(obj.slider, 'Value'));
                if eventdata.VerticalScrollCount > 0
                    tt = max(1, tt - step);
                else
                    tt = min(obj.T, tt + step);
                end
                set(obj.slider, 'Value', tt)
                obj.setframe_(tt);
%             end
        end
        
        function imagesc(obj)
            tt = 1;
            obj.im = imagesc(obj.mov(:,:,tt));
            axis equal
            hold on
            obj.figure = gcf();
            obj.axes = gca();
            obj.slider = uicontrol('Style', 'slider',...
                'Min',1,'Max',obj.T,'Value',tt,...
                'SliderStep', [1/obj.T, 10/obj.T], ...
                'Units','normalized', ...
                'Position', [0.95 0.11 0.03 0.75],...
                'Callback', {@setframe_slide, obj},...
                'TooltipString',['Scroll through movie frames', char(10),...
                '[also works with mouse wheel]' ]);
            set(obj.figure, 'WindowScrollWheelFcn', {@setframe_wheel, obj})
        end
        
%         function WindowButtonMotionFcn(hObject, ~, obj, varargin)
%             % get position information of the uicontrol
%             pos = get(hObject, 'currentpoint'); % get mouse location on figure
%             x = pos(1); y = pos(2); % assign locations to x and y
%             set(obj.slider, 'units', 'pixel')
%             bounds = get(obj.slider,'position');
%             set(obj.slider, 'units', 'normalized')
%             lx = bounds(1); ly = bounds(2);
%             lw = bounds(3); lh = bounds(4);
%             % test to see if mouse is within the uicontrol.
%             if x >= lx && x <= (lx + lw) && y >= ly && y <= (ly + lh)
%                 set(obj.slider, 'backgroundcolor', 'red');
%             else
%                 set(obj.slider, 'backgroundcolor', [1,1,1]*0.5);
%             end
%         end
    end
    
end

