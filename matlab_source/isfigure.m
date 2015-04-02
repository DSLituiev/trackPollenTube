function [ out ] = isfigure( h )
%find if the argument is a valid figure handle
out = ~isempty(h) && ishandle(h) && (findobj(h,'type','figure')==h);
end

