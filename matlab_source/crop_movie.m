classdef crop_movie
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mov
        roi
        padding
        mov_size
        vnRectBounds
    end
    
    methods
        function obj = crop_movie(varargin)
            %% check the input parameters
            p = inputParser;
            p.KeepUnmatched = true;
            addRequired(p, 'movPath', @(x)( readable(x) || is3dstack(x) ) );
            addRequired(p, 'roiPath', @(x)( readable(x) || ( isobject(x) ) || ( isstruct(x) ) ) ); %
            addOptional(p, 'padding', 0, @isscalar );
            parse(p, varargin{:});
            %%
            obj.padding = p.Results.padding;
            obj.mov_size = get_tiff_size( p.Results.movPath );
            [obj.mov, obj.roi] = cropRectRoiFast(p.Results.movPath, p.Results.roiPath, p.Results.padding);
            obj.vnRectBounds = [max(1, obj.roi.vnRectBounds(1) - obj.padding),...
                                max(1, obj.roi.vnRectBounds(2) - obj.padding),...
                                min(obj.mov_size(1), obj.roi.vnRectBounds(3) + obj.padding),...
                                min(obj.mov_size(2), obj.roi.vnRectBounds(4) + obj.padding)];
        end
        
        function out = sub2ind(obj, y0, x0, z)
            out = get_values_sub2ind(obj.mov, y0, x0, z, obj.vnRectBounds);
        end
        
        function [x,y] = xycropped(obj,x,y)
            x = x - obj.roi.vnRectBounds(1);
            y = y - obj.roi.vnRectBounds(2);
        end
        
        function varargout = subsref(obj, s)
            % obj(i) is equivalent to obj.Data(i)
            switch s(1).type
                case '.'
                    [varargout{1:nargout}] = builtin('subsref',obj, s);
                case '()'
                    if length(s) < 2
                        
                        fprintf('referencing: '); disp(s.subs)
                        
                        s.subs{1} = s.subs{1} - obj.roi.vnRectBounds(1);
                        s.subs{2} = s.subs{2} - obj.roi.vnRectBounds(2);
                        disp(s.subs)
                        
                        if isscalar(s.subs{1}) &&  isscalar(s.subs{1}) && (s.subs{1} < 1 || s.subs{2} < 1 )
                             [varargout{1:nargout}] = NaN;
                            return
                        end
                        
                        if  numel(s.subs{1}) == numel(s.subs{2}) && ...
                                isnumeric( s.subs{1} ) && isnumeric(s.subs{2} )
                            
                            outliers_x = s.subs{1} < 1 | s.subs{1} > obj.roi.vnRectBounds(3) - obj.roi.vnRectBounds(1);
                            outliers_y = s.subs{2} < 1 | s.subs{1} > obj.roi.vnRectBounds(4) - obj.roi.vnRectBounds(2);
                            outliers = outliers_x | outliers_y;
                            
                            if any(outliers)
                                svalid = s;
                                svalid.subs{1} = s.subs{1}(~outliers);
                                svalid.subs{2} = s.subs{2}(~outliers);
                                sref = NaN(size(outliers));
                                sref(~outliers) = builtin('subsref',obj.mov, svalid);
                                varargout{1} = sref;
                                return
                            else
                                sref = builtin('subsref',obj.mov, s);
                                varargout{1} = sref;
                                return
                            end
                            
                        end
                        sref = builtin('subsref',obj.mov, s);
                        varargout{1} = sref;
                        return
                    else
                        sref = builtin('subsref',obj, s);
                        varargout{1} = sref;
                    end
                case '{}'
                    error('MYDataClass:subsref',...
                        'Not a supported subscripted reference')
            end
        end
        
        function fullframe(tt)
            
        end
        
        %         function ind = subsindex(obj)
        %             ind = obj.mov;
        %         end
    end
    
end

