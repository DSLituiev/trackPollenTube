function [ z ] = edge2path_makeshift( kymoEdge, MEDIAN_RADIUS )
% Constructs a tube path (position of t) given the kymogram edge.
% Uses present & future neighbourghs joining

T = size(kymoEdge, 2);
L = size(kymoEdge, 1);
    
kymoThrBool = kymoEdge>0;
clear kymoThrInt


[edgeL, edgeT] = find(kymoThrBool);
%== Construct the path using the thresholded kymogram
z = ones(T, 1);
S.type = '()';

BINOM_FILTER = [1 4 6 4 1]';
% BINOM_FILTER = [1, 6, 15, 20, 15, 6, 1]';
BINOM_FILTER = BINOM_FILTER./sum(BINOM_FILTER(:));


MARGIN = numel(BINOM_FILTER);

% figure
% imagesc( diff(double(kymoThr), 2))

% kymoThrBool = padKymogramHoriz(conv2(1, BINOM_FILTER,  double(padKymogramHoriz(kymoThrBool, MARGIN)), 'same'), MARGIN, false);

L = size(kymoEdge, 1);
for ll = 1:L
    kymoEdge(ll, :) = fastmedfilt1d(kymoEdge(ll, :), 7);
end
kymoEdgeBool = kymoEdge>0;


diffImage = diff(  kymoEdgeBool, 1)  ;

MAXPIXINT = double(max(kymoEdge(:)));

% figure
% imagesc(kymoEdgeBool)

% figure
% imagesc(diffImage)

tt = 1;
partSep = find( diffImage(:, tt)<0 );
% partSep = [1; partSep; size(kymoEdge,1)];
for ii = numel(partSep):-1:1
    partPixSum(ii) = mean(kymoEdge(1:partSep(ii), tt ), 1 )   + ...
        mean(MAXPIXINT - kymoEdge(partSep(ii):end, tt ), 1 );
end

[~ , biggestPart ]= max(partPixSum);
z(tt) = partSep(biggestPart);

for tt = 2:4
    % a_max = (find(kymoEdge(:,tt), 5, 'first'));
    [~, a_max] = mink(kymoEdge(:,tt), 5);
    if ~isempty(a_max)
        [~, closestInd] = nanmin(abs( a_max - z( tt-1) ) );
        z(tt) = a_max(closestInd);
        %         if (L - z(tt)) < (z(tt) - 1)
        %             z(tt) = 1;
        %         end
    end
end

for tt = 5:T % T
    %= find the closest points in the present and future
    
    [~, a] = mink( abs( edgeL(edgeT>=tt)-z(tt-1) ) +  abs( edgeT(edgeT>=tt)-tt)  , N_CLOSEST_POINTS );
    % currIndFlag = edgeT>=tt ;
    % [li, ti ] = ind2sub( [L,T], a);
    S.subs = {a};
    z_vars = subsref( edgeL(edgeT>=tt), S);
    %= assign the present position the value of the median of the position
    %= of N_CLOSEST_POINTS points
    z(tt) = ceil(median(z_vars));
    
    if ~isnan(z(tt))
        for kk = z(tt):L
            if ~kymoEdge( kk, tt)
                z(tt) = kk;
                break
            end
        end
    end
    %     kk = 0;
    %     if ~isnan(z(tt))
    %         while kymoEdge( min(floor(z(tt))+kk, L) , tt)
    %             kk = kk +1;
    %         end
    %     end
    %     z(tt) = z(tt) + kk;
    
end


%== filtering
z = (fastmedfilt1d(z, 1 + 2*MEDIAN_RADIUS, ones(MEDIAN_RADIUS,1),...
    size(kymoEdge,1)*ones(MEDIAN_RADIUS,1) ));

% diffZ = medfilt1(diff(z), 1 + 2*MEDIAN_RADIUS);

% % figure; plot(1:T-1, diffZ)
%
% figure('name', 'before')
% phandle = pcolor( double(kymoEdge ) );
% set( phandle , 'linestyle', 'none');
% set(gca, 'yDir', 'reverse');
% hold on
% plot(z, 'k-', 'linewidth',2)

%== make z non-decreasing
minlevel = z(1);
for ii = 3:(numel(z) - 1)
    if  z(ii+1) > minlevel
        % minlevel = z( ii );
        minlevel = median( [ z( ii ); 2*z(ii-1) - z(ii-2); z(ii-1) ] );
        % minlevel = median( z( ii + 1 -(min(ii, 1:3) ) ) );
    else
        z(ii+1) = minlevel;
    end
end

%== filtering
z = round(smoothn(z, 1 + 2*GAUSS_1D_RADIUS, 'gauss', GAUSS_1D_SIGMA));
z(z<0) = 0;

end

