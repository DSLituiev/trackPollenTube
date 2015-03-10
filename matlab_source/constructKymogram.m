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

[ Y, X, T] = size(mov);

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

switch kymoMethod
    
    case 'l1'    %== L1 distance 
        kymoGram = zeros(path.L, T, class(mov));
        for tt=1:T
            indt = sub2ind(size(mov), round(path.y), round(path.x), repmat( tt, [path.L,1]) );
            kymoGram(:,tt) = mov(indt);
        end
        
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
        [xl, yl] = ind2sub([X, Y], minDistInd);
        
        kymoGram = zeros(path.L, T, class(mov));
        for tt = 1:T
            indt = sub2ind(size(mov), yl, xl, repmat( tt, [path.L, 1]) );
            kymoGram(:,tt) = mov(indt);
        end
        
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
        [wiX, wiY, wiZ] = ind2sub(size(weights), nzwInds);
        weightMatr = bsxfun(@times, bsxfun( @eq, (1:path.L)', wiZ' ), weights(nzwInds)');
               
        indAll = sub2ind(size(mov), repmat(wiY,[1,T]), repmat(wiX,[1,T]), repmat(1:T, [numel(nzwInds),1]) );
                
        kymoGram = weightMatr * single(mov(indAll));
        
        if isa(mov,'uint8')
        kymoGram = uint8( 2^8 * kymoGram./max(kymoGram(:)) );
        elseif isa(mov,'uint16')
        kymoGram = uint16( 2^16 * kymoGram./max(kymoGram(:)) );
        end
end