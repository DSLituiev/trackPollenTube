function intensity = integrate_over_edge(img, x, y)
epsilon = 1.5;

maxY = size(img,1) ;
maxX = size(img,2) ;
pad_R = 2;
pad_D = pad_R*2+1;
y_base = bsxfun(@plus, round(y) , permute(-pad_R:1:pad_R,[1,3,2]) );
dX = bsxfun(@minus, y_base , y);
x_base = permute( bsxfun(@plus, round(x) , permute(-pad_R:1:pad_R,[1,3,2]) ), [1, 3, 2]);
dY = bsxfun(@minus, x_base , x);
%      dY = 0;
dR = sqrt(bsxfun(@plus, dX.^2, dY.^2));

valid = bsxfun(@and, y_base > 1 & y_base < maxY  , x_base >1 & x_base < maxX);

weights = M4prime(dR, epsilon);
weights(~valid) = NaN;

xx_b = repmat(y_base,[1,pad_D,1]);
yy_b = repmat(x_base,[1,1,pad_D]);
inds = ones(size(valid));
inds(valid) = sub2ind(size(img), xx_b(valid), yy_b(valid));

intensity = nansum(nansum( weights .* img(inds) ,2),3);
end