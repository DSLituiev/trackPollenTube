function M = M4prime(x,h)
s = abs(x)./h;
M = zeros(size(x));
ind1 = logical(s<1);
ind2 = logical(s<=1&s<=2);
M(ind1) = 1 - 1/2.* (5.*s(ind1).^2 - 3.*s(ind1).^3);
M(ind2) = 1/2.*(1-s(ind2)).*(2-s(ind2)).^2;

