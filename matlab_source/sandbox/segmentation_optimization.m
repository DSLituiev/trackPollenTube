addpath('..');
addpath('../../dependencies/')
addpath('../../dependencies/ImageJROI/')
kymo = single(pt.kymogram);
% clear opt
% opt.nPoints = numel(pt.rt_roi.x0);
% opt.Verbose = true; % p.Results.visualize
% opt.Beta = 0;
% opt.Gamma = 0.8;
% opt.Sigma1 = 10;
% opt.Sigma2 = 1;
% opt.Sigma3 = 1;
% opt.Iterations = 500;
% opt.Kappa = 1;
% opt.Closed= false;
% opt.AbsTol = 1e-1;
% opt.Norm = Inf;
% opt.Fixed = false(size(pt.rt_roi.x0));
% opt.Fixed(1,2) = true;
% opt.Fixed(end,2) = true;
% Snake2D(kymo, fliplr(pt.rt_roi.mnCoordinates), opt)

% figure
% [xs, ys] = snake_iterate(double(pt.kymogram), pt.rt_roi.x0, pt.rt_roi.y0, .2, 0, 1, .1, .1, 1, .01, 200);


T = size(kymo, 2);
r0 = pt.xyt.r + 2*rand(pt.xyt.T,1);% R*rand(T,1);

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

alpha_ = 0.1;
q = quantile(k_dir(:), alpha_);
k_dir(k_dir<q) = q;

R = 50;
bf = binomialFilter(R);
input_image = -paddedConv2(k_dir ,conv2(bf, bf')).^2;

%%
addpath('../../dependencies/BasicSnake/')
kymo = single(pt.kymogram);
[ tt0, rr0 ] = segment_snake( kymo, pt.rt_roi.x0, pt.rt_roi.y0 );
pt.rt_roi.x0 = tt0;
pt.rt_roi.y0 = rr0;
figure
pt.rt_roi.plot()
%%
x0 = pt.xy_roi.x0;
y0 = pt.xy_roi.y0;
dE_dc = curvewise_edge_energy([x0, y0], k2);


%%
Iterations = 200;

figure
spl = axes();
imagesc(-input_image)
colormap(gray)

hold all
li = zeros(Iterations,1);
li(1) = plot(pt.rt_roi.x0, pt.rt_roi.y0 ,'-','Color',[0 1 0]);
h = scatter(pt.rt_roi.x0, pt.rt_roi.y0,100*pi,'r','.');

opt = optimset('TolX', 1e-3, 'MaxIter', Iterations, 'OutputFcn', @(x,y,z)upd_snake_plot(x,y,z, spl, h, Iterations));

pt.rt_roi.mnCoordinates(end, 1) = T;
s0 =  pt.rt_roi.mnCoordinates;

fixed = false(size(s0));
fixed(1,2) = 1;
fixed(end, 2) = 1;
s = s0;
for ii = 1:1    
%     e0 = kymo_fit_energy(s0, input_image, [], fixed, s0);
%     tobereplaced = false(size(s0,1),1);
%     for jj = 1:size(s0,1)
%         s1 = s;
%         s1(jj,:) = s1(jj,:) + 10*rand(1, 2);
%         s1(s1<1) = 1;
%         e1 = kymo_fit_energy(s0, input_image, [], fixed, s0);
%         if e0>e1
%             tobereplaced(jj) = true;
%         end
%         s0 = s;
%         if fixed(jj,2)
%             s0(jj,1) = s1(jj,1);
%         else
%             s0(jj,:) = s1(jj,:);
%         end
%     end
    
    s = sort(round(fminsearch(@(y)kymo_fit_energy(y,  input_image, kymo, fixed, s0), s0, opt )));
end

t = s(:,1);
r = s(:,2);

figure
imagesc(-input_image)
colormap(gray)
hold all
plot(t,r, 'g-', 'linewidth', 2)
plot(t, r, 'rx', 'linewidth', 2)
