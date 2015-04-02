
kymo = single(pt.kymogram);
r0 = pt.xyt.r + 2*rand(T,1);% R*rand(T,1);

kxx = diff(kymo,2,2);
kyy = diff(kymo,2,1);
padx = zeros(size(kymo,1),1);
pady = zeros(1, size(kymo,2));

k1x = [diff(kymo,1,2), padx];
k1y = [diff(kymo,1,1); pady];
k_dir = k1x - k1y;
figure
imagesc(k_dir)

k2 = cat(2, padx, kxx, padx) + ...
    cat(1, pady, kyy, pady);

figure
imagesc(k2)

alpha_ = 0.05;
q = quantile(k2(:),1 - alpha_);
k2(k2>q) = q;

T = size(kymo,2);
R = size(kymo,1);
t = (1:T)';

bf = binomialFilter(11);
k_dir_sm = paddedConv2(k_dir ,conv2(bf, bf'));
r = sort(round(fminsearch(@(y)kymo_fit_energy(y, t, -k_dir_sm), r0)));

figure
imagesc(k_dir_sm)
hold all
plot(t,r0, 'rx')
plot(t,r, 'w-')
