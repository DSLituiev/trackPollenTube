function [kymoGram, path] = constructKymogram(path, mov, varargin)
% constructs a kymogram given a movie and the path-ROI
%
%Input
%=====
% - path   -- the path object:
%    >- path.x and path.y  --  ROI (detailed point coordinates,
%                                 with the unit spacing between the points)
%    >- path.L             --  the length of the path
%
% - mov    -- movie (3D array, uint16)
% - (optional) interpolation mode  -- a case insensitive string;
%          possible values:
%          * L1  -- abs(x - x_{path}); the default mode
%          * L2  -- Euclidian (L_2) distance
%          * m4  -- M'_4 kernel interpolation (requires the M4prime funciton)
%
% TODO: extend to support uint8
%
if ndims(mov) == 3
    [ Y, X, T] = size(mov);
    C = 1;
elseif ndims(mov) == 4
    [ Y, X, C, T] = size(mov);
end

if isempty(varargin)
    kymoMethod = 'l1';
else
    kymoMethod = varargin{1};
end

if ~isfield(path, 'x') || ~isfield(path, 'y')|| ~isfield(path, 'L')
    if isfield(path, 'mnCoordinates')
        path.x = path.mnCoordinates(:,1);
        path.y = path.mnCoordinates(:,2);
        path.L = size(path.mnCoordinates, 1);
    end
end
if isempty(path.L)
    path.L = numel(path.x);
end

assert( all(path.x > 0) )
assert( all(path.y > 0) )

switch kymoMethod
    
    case 'l1'    %== L1 distance
        kymoGram = zeros(path.L, T, class(mov));
        yy = round(path.y);
        xx = round(path.x);
        weightMatr = 1;
    case 'l2'    %== L2 distance
        dX = bsxfun(@minus, (1:X)', permute(path.x,[2,3,1]) );
        dY = bsxfun(@minus, 1:Y, permute(path.y,[2,3,1]) );
        dR = sqrt(bsxfun(@plus, dX.^2, dY.^2));
        clear dX dY
        %== dR size: [X Y 1 L]
        
        minDistInd = zeros(path.L, 1);
        for ll = 1:path.L
            dRt = dR(:, :, ll);
            [ ~ , minDistInd(ll)] = min(dRt(:));
        end
        [xx, yy] = ind2sub([X, Y], minDistInd);
        weightMatr = 1;
        
    case 'm4'    %== M'_4 interpolation kernel
        if numel(varargin)>1
            epsilon = varargin{2};
        else
            epsilon = 1.5;
        end
        
        dX = bsxfun(@minus, (1:X)', permute(path.x,[2,3,4,1]) );
        dY = bsxfun(@minus, 1:Y, permute(path.y,[2,3,4,1]) );
        dR = sqrt(bsxfun(@plus, dX.^2, dY.^2));
        %== dR size: [X Y 1 L]
        
        clear dX dY
        
        weights = single(M4prime(dR, epsilon));
        nzwInds = find(weights); %== non-zero weights' indices
        [xx, yy, zz] = ind2sub(size(weights), nzwInds);
        weightMatr = bsxfun(@times, bsxfun( @eq, (1:path.L)', zz' ), weights(nzwInds)');
end

try
    if C>1
        indt = sub2ind(size(mov), repmat(yy,[1,T,C]), repmat(xx,[1,T,C]), ...
            repmat( permute(1:C, [1,3,2]), [numel(xx),T,1]) ,...
            repmat(1:T, [numel(xx),1,C]) );
    else
        indt = sub2ind(size(mov), repmat(yy,[1,T]), repmat(xx,[1,T]), ...
            repmat(1:T, [numel(xx),1]) );
    end
catch err
    fprintf('movie size:\t')
    disp(size(mov))    
    fprintf('max(y):\t%u\n', max(yy))
    fprintf('max(x):\t%u\n', max(xx))
    rethrow(err)
end

if strcmpi(kymoMethod, 'm4')
    mov_pix = single(mov(indt));
    for cc = C:-1:1
        kymoGram(:,:,cc) =  weightMatr * mov_pix(:,:,cc);
    end
    if isa(mov,'uint8')
        kymoGram = uint8( 2^8 * kymoGram./max(kymoGram(:)) );
    elseif isa(mov,'uint16')
        kymoGram = uint16( 2^16 * kymoGram./max(kymoGram(:)) );
    end
else
    kymoGram =  mov(indt);
end

end