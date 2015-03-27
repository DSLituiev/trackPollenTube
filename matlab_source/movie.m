classdef movie
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    
    properties
        mov
        mov_size
        T
        im
        figure
        color = false;
    end
    
    methods
        function out = ndims(obj)
            out = ndims(obj.mov);
        end        
        function out = size(obj)
            out = size(obj.mov);
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
        function obj = movie(movPath, varargin)
            %% check the input parameters
%             p = inputParser;
%             p.KeepUnmatched = true;
%             addRequired(p, 'movPath', @(x)( (readable(x) ) || ( isnumeric(x) && ( numel(size(x))==3 ) ) ) );
%             parse(p, movPath, varargin{:});
            %%
            if readable(movPath)
                obj.mov = readTifSelected( movPath );
                obj.mov_size = get_tiff_size( movPath );
            elseif strcmpi(class(movPath), 'movie')
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
        
        function setframe(cobj, ~, obj, varargin)
            tt = round(get(cobj, 'Value'));
            set(obj.im, 'CData', obj.mov(:,:,tt)) ;
            set(obj.figure, 'name', sprintf('frame %u', tt))
%             delete(obj.im)
%             obj.im = imagesc(obj.mov(:,:,tt));
        end
        
        function imagesc(obj)
            tt = 1;
            obj.im = imagesc(obj.mov(:,:,tt));
            obj.figure = gcf();
%             ax = gca();
            sliderbar = uicontrol('Style', 'slider',...
                'Min',1,'Max',obj.T,'Value',tt,...
                 'SliderStep', [1/obj.T, 5/obj.T], ...
                'Units','normalized', ...
                'Position', [0.70 0.02 0.28 0.04],...
                'Callback', {@setframe, obj} );

%             set(hSP,'Units','normalized',...
%                 'Position',[0 .1 1 .9])
        end
        
    end
    
end

