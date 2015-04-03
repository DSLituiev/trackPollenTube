
kymo = single(pt.kymogram);
clear opt
opt.nPoints = numel(pt.rt_roi.x0);
opt.Verbose = true; % p.Results.visualize
opt.Beta = 0;
opt.Gamma = 0.8;
opt.Sigma1 = 10;
opt.Sigma2 = 1;
opt.Sigma3 = 1;
opt.Iterations = 500;
opt.Kappa = 1;
opt.Closed= false;
opt.AbsTol = 1e-1;
opt.Norm = Inf;
opt.Fixed = false(size(pt.rt_roi.x0));
opt.Fixed(1,2) = true;
opt.Fixed(end,2) = true;
Snake2D(kymo, fliplr(pt.rt_roi.mnCoordinates), opt)
return

T = size(kymo, 2);
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
input_image = -paddedConv2(k_dir ,conv2(bf, bf')).^2;
s = sort(round(fminsearch(@(y)kymo_fit_energy(y, input_image), pt.rt_roi.mnCoordinates)));
t = s(:,1);
r = s(:,2);

figure
imagesc(input_image)
hold all
plot(pt.rt_roi.x0, pt.rt_roi.y0, 'rx', 'linewidth', 2)
plot(t,r, 'w-', 'linewidth', 2)
