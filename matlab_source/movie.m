classdef movie
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    
    properties
        mov
        mov_size
        T
        im
    end
    
    methods
        function obj = movie(movPath, varargin)
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            addRequired(p, 'movPath', @(x)( (readable(x) ) || ( isnumeric(x) && ( numel(size(x))==3 ) ) ) );
            parse(p, movPath, varargin{:});
            %%
            obj.mov_size = get_tiff_size( p.Results.movPath );
            obj.T = obj.mov_size(end);
            obj.mov = readTifSelected(p.Results.movPath);
        end
        function plot(obj)
            tt = 1;
            im = imagesc(obj.mov(:,:,tt));
            f = gcf();
            ax = gca();
            hSP = uicontrol('Style', 'slider',...
                'Min',1,'Max',obj.T,'Value',tt,...
                'Position', [400 20 120 20],...
                'Callback', @surfzlim);

%             set(hSP,'Units','normalized',...
%                 'Position',[0 .1 1 .9])
        end
        
        function surfzlim(varargin)
            tt = varargin{2};
            delete(obj.im)
            obj.im = imagesc(obj.mov(:,:,tt));
        end
    end
    
end

