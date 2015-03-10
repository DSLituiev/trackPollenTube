function varargout = createKymoMask(movieDimension, path, varargin)
%== creates a mask from the x&y coordinates of the object path and the r(t)
% curve trace of the object movement
%
% requires the "rot90_3D" function

frame = [ floor([min(path.x), min(path.y)]) - path.R, 1;
    ceil([max(path.x), max(path.y)]) + path.R, path.eruptionT];

% [mov, varargout] = cropRectROI(movPath, frame)

z = path.z + path.offset;

if nargin>2 && ischar(varargin{1}) && strcmpi(varargin{1}, 'lag')
    z = bsxfun(@max, z+path.lag , 1+path.lag ); 
    z = bsxfun(@min, z, path.L);    
    lagflag = z > (1 + path.lag);
else
    z = bsxfun(@min, z, path.L);
    z = bsxfun(@max, z, 1);
end

%
% figure
% plot(x, y, 'o-')
% axis equal
% %

% [XX, YY, ~] = ndgrid(1:movieDimension(1), 1:movieDimension(2), 1:movieDimension(3));

% mask = bsxfun(@minus, XX, permute(x(z0), [3,2,1]) ).^2 +...
%     bsxfun(@minus, YY, permute(y(z0), [3,2,1]) ).^2 < R^2;

% [XX, YY, ~] = ndgrid(1:diff(frame(:,1)), 1:movieDimension(2), 1:movieDimension(3));

% [XX, ~, ~ ] = ndgrid(1:diff(frame(:,1)), 1, 1:eruptionT);
% [ ~, YY, ~] = ndgrid(1, 1:diff(frame(:,2)), 1:eruptionT);

[YY, ~, ~ ] = ndgrid(1:double(movieDimension(1)), 1, 1:path.eruptionT);
[ ~, XX, ~] = ndgrid(1, 1:double(movieDimension(2)), 1:path.eruptionT);

mask =  bsxfun(@plus, ...
    bsxfun(@minus, XX, permute( path.x(z(1:path.eruptionT)) , [3,2,1]) ).^2 ,...
    bsxfun(@minus, YY, permute( path.y(z(1:path.eruptionT)) , [3,2,1]) ).^2) < path.R^2;

mask = cat(3, mask, repmat(mask(:,:, path.eruptionT), [1,1, numel(z)-path.eruptionT]));
% mask = rot90_3D(mask, 3,2);

if exist( 'lagflag', 'var' )
    mask = bsxfun(@and, mask,  permute(lagflag, [3,2,1] ) );
end


varargout{1} = mask;
varargout{2} = frame;
% varargout{3} = eruptionT;