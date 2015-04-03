function sqddx = sum_square_ddx(ddx, bnd)
sqddx = zeros(size(bnd));
l_midpoint =  [0; floor((bnd(1:end-2) + bnd(2:end-1))/2);0];
r_midpoint =  [0; floor((bnd(2:end-1) + bnd(3:end))/2); 0];
r_midpoint(r_midpoint> numel(ddx)) = numel(ddx);
for ii = 2:numel(bnd)-1
    %             l_midpoint =  floor((bnd(ii-1) + bnd(ii))/2);
    %             r_midpoint = floor((bnd(ii) + bnd(ii+1))/2);
    sqddx(ii) = sum(ddx(l_midpoint(ii):r_midpoint(ii)).^2);
end
end