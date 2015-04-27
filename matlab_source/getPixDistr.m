function maskedPixels_t = getPixDistr(mov, mask, varargin)
% applies a binary mask onto a movie and returns the list of intensities of
% the masked points for each frame (i.e. time point)
%
% === Inputs ===
% - mov  -- the movie
% - mask -- the binary mask to be applied
%               ->  with some maximal number of points per frame  'maxNumPointsPerFrame'
% - endT = varargin{1} -- the time to stop the recording
%
% === Output ===
% - maskedPixels_t -- a [T, maxNumPointsPerFrame]
%                   or [endT ,  maxNumPointsPerFrame] matrix with the pixel
%                   intensities taken from the masked regions for each time
%                   frame
%
movDim = single(size(mov));
maskDim = single(size(mask));
T = movDim(end);
if numel(movDim) == 4
    C = movDim(3);
else
    C = 1;
end

if ~islogical(mask)
    warning('getPixDistr:NonLogicalMask', 'the mask must be of logical/boolean format')
end

delta_t = maskDim(3) - T;
if delta_t > 0
    if delta_t > 3
        warning('time dimension mismatch')
    else
        mask = mask(:,:, 1:T);
        maskDim = single(size(mask));
    end
end

if  numel(maskDim) == numel(movDim) && all(movDim([1,2]) == maskDim([1,2])) ||...
        (numel(movDim) == 4 && numel(maskDim) == 3)
    reshMask = reshape( mask, prod(movDim([1,2])), T );
elseif   numel(maskDim) < numel(movDim) && all(maskDim == movDim(1:numel(maskDim)))
    reshMask = repmat(mask(:), [1 T]);
    % mask = repmat(mask, [1,1, T]);
else
    error('getPixDistr:DimensionMisMatch', 'the mask does not match the dimension of the movie')
end


% reshMask = reshape( mask, prod(movDim([1,2])), T );
numPointsPerFrame = sum(reshMask, 1)';
maxNumPointsPerFrame = max(numPointsPerFrame);

    function maskedPixels_t = get_pix_3d(mov, reshMask)
        
        reshMov = reshape( mov, prod(single(movDim([1,2]))), T);
        maskedPixels_t = NaN(T, maxNumPointsPerFrame);
        
        for tt = 1:varargin{1}; % eruptionT = varargin{1}
            if numPointsPerFrame(tt)>0
                maskedPixels_t(tt, 1:numPointsPerFrame(tt)) = reshMov(reshMask(:,tt), tt)';
            end
        end
    end

if C > 1
    for cc = C:-1:1
        maskedPixels_t(:,:,cc) = get_pix_3d(mov(:,:,cc,:), reshMask);
    end
else
    maskedPixels_t = get_pix_3d(mov, reshMask);
end
end
%== after eruption there is nothing to trace:
%     maskedPixels_t(:, eruptionT:T) = NaN;
%    Inds = sub2ind([rmax, T], ndgrid(1:numPointsPerFrame(eruptionT), eruptionT:T) );
%    maskedPixels_t(Inds) = ...
%         reshMov(reshMask(:,eruptionT:T));
% else
%
%     for tt = 1:T
%         maskedPixels_t(tt, 1:numPointsPerFrame(tt)) = reshMov(reshMask(:,tt),tt)';
%     end
%
% end


%===
