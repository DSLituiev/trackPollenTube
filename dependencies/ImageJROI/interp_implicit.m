function [x,y,r,r0, arc_length, dr0] = interp_implicit(x0, y0, varargin)
% interpolates implicit curves parametrized by arc length
% varargin{1} -- interpolation method 
%                as specified in `interp1` documentation

%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;
addRequired(p, 'x0', @isnumeric);
addRequired(p, 'y0', @isnumeric);
addOptional(p, 'interp1', 'pchip', @(x) any(strcmpi(x, {'linear','pchip', 'spline'})) );
parse(p, x0, y0, varargin{:});
%% 
if isempty(x0) || isempty(y0)
    x = [];
    y = [];
    r = [];
    r0 = [];
    arc_length = 0;
    dr0 = 0;
    return
end
x0 = double(x0);
y0 = double(y0);
[arc_length, dr0] = arclength(x0 , y0, p.Results.interp1);

r0 = (1+[0;cumsum(dr0)] );
r = 1+(0:1:round(arc_length))';

xy = interp1(r0', [x0(:), y0(:)], r,  p.Results.interp1, 'extrap');
x = xy(:,1);
y = xy(:,2);
end