function out = get_values_sub2ind(mov, y0, x0, z, varargin)

if nargin>4
    vnRectBounds = varargin{1};
    vnRectBounds(vnRectBounds<1) = 1;
else
    vnRectBounds = [1,1, size(mov,1), size(mov,2)];
end
if any(isnan(y0(:))) || any(isnan(x0(:))) || any(isnan(z(:)))
    error('nan values!')
end

y = y0 - vnRectBounds(1);
x = x0 - vnRectBounds(2);

outliers_y = y <  vnRectBounds(1) | y > vnRectBounds(3);
outliers_x = x  <  vnRectBounds(2) | x > vnRectBounds(4) ;
outliers = outliers_y | outliers_x;

if size(z) == 1
    z = repmat(z, size(y));
end

if any(y(~outliers)<0) || any(x(~outliers)<0)
    error('negative values after subtracting the frame')
end

out = NaN(size(outliers));
if any(~outliers)
    linearindex =  sub2ind( size(mov), y(~outliers), x(~outliers), z(~outliers));
    out(~outliers) = mov(linearindex);
end
end