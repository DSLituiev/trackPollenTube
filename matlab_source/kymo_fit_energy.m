function fun = kymo_fit_energy(r, t, img)

epsilon = 1.5;
R = size(img,1) ;
T = size(img,2) ;
L = T;% number of control points

length = sum(diff(r).^2);
outliers_p = r > R ;
outliers_m = r < 1 ;
length = length + 100*sum(mod(r(outliers_p|outliers_m), R).^2);
r(outliers_p) = size(img,1);
r(outliers_m) = 1;

pad_R = 2;
pad_D = pad_R*2+1;
r_base = bsxfun(@plus, round(r) , permute(-pad_R:1:pad_R,[1,3,2]) );
dX = bsxfun(@minus, r_base , r);
t_base = permute( bsxfun(@plus, round(t) , permute(-pad_R:1:pad_R,[1,3,2]) ), [1, 3, 2]);
dY = bsxfun(@minus, t_base , t);
%      dY = 0;
dR = sqrt(bsxfun(@plus, dX.^2, dY.^2));

valid = bsxfun(@and, r_base > 1 & r_base < R  , t_base >1 & t_base < T);

weights = M4prime(dR, epsilon);
weights(~valid) = NaN;

rr_b = repmat(r_base,[1,pad_D,1]);
tt_b = repmat(t_base,[1,1,pad_D]);
inds = ones(size(valid));
inds(valid) = sub2ind(size(img), rr_b(valid), tt_b(valid));


intensity = nansum(nansum( weights .* img(inds) ,2),3);

im_energy = sum(intensity);
fun =  1e-2*length + im_energy;
end