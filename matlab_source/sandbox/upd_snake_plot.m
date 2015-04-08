function stop = upd_snake_plot(r, optimValues, state, varargin)
spl = varargin{1};
h = varargin{2};
Iterations = varargin{3};
% Show current contour
c = (1+optimValues.iteration)/(Iterations+1);
%         set(li, 'xdata',x_, 'ydata', y_, 'Color',[c 1-c 0])

% li(optimValues.iteration+1) =

[x_, y_] = interp_implicit( r(:,1), r(:,2));
line(x_, y_, 'LineStyle', '-','Color', [c, 0.2, 1-c], 'Parent', spl);
set( h , 'xdata', r(:,1), 'ydata', r(:,2), 'zdata', 2*ones(size(r,1),1));
drawnow;
stop = false;
end