function [ t0, x0 ] = segment_snake( kymo, varargin )

%% check the input parameters
inp_opt = inputParser;
inp_opt.KeepUnmatched = true;

addRequired(inp_opt, 'kymo', @(x)isnumeric(x) );
addOptional(inp_opt, 't', 0, @isnumeric  );
addOptional(inp_opt, 'x',  0, @isnumeric);
addParamValue(inp_opt, 'Alpha', 3e-2, @isscalar);
addParamValue(inp_opt, 'Beta',  1e-6, @isscalar);
addParamValue(inp_opt, 'Gamma', .5, @isscalar);
addParamValue(inp_opt, 'Delta', 1e-1, @isscalar);
addParamValue(inp_opt, 'Sigma3', 5, @isscalar);
addParamValue(inp_opt, 'Iterations', 200, @isscalar);
addParamValue(inp_opt, 'AbsTol',  2e-2, @isscalar);
addParamValue(inp_opt, 'Norm',  Inf, @isscalar);
addParamValue(inp_opt, 'Closed',  false, @isscalar);
addParamValue(inp_opt, 'Wline',  0.001, @isscalar);
addParamValue(inp_opt, 'Wedge',  .2, @isscalar);
addParamValue(inp_opt, 'Wterm',  -.005, @isscalar);
addParamValue(inp_opt, 'useAsEnergy',  false, @isscalar);

parse(inp_opt, kymo, varargin{:});
%%
opt = struct(inp_opt.Results);
opt.forceActsUpon = 'points'; % 'curve'; % 

%%
kymo = kymo(:,:,1);
[X, T] = size(kymo);

if numel(inp_opt.Results.t) > 1 && numel(inp_opt.Results.t) == numel(inp_opt.Results.x)
    t0 = inp_opt.Results.t;
    x0 = inp_opt.Results.x;
else
    x_shift = floor(X/4);
    
    radius_ = 80;
    t0 = (1:radius_:T)';
    x0 = x_shift + round(t0*((X-x_shift)/T));
end

ff = figure;
opt.figure = ff;

if opt.useAsEnergy
    if ~opt.Wline
        opt.Wline = 1;
%     else
%         opt.Wline = opt.Wline/ abs(opt.Wline);
    end
    opt.Wedge = -0.005;
    opt.Wterm = 0;
end

Radii = [16, 8, 4, 3 ]; %[80, 40, 20, 10]; %
% opt.nPoints = numel(t0);
% opt.Fixed = false(opt.nPoints, 2);
% opt.Fixed(1,2) = true;
% opt.Fixed(end,2) = true;
%%
opt.Verbose = true; % p.Results.visualize


for radius_ = Radii    
    opt.Sigma1 = radius_;
    opt.Sigma2 = radius_/1;
    opt.Kappa = 2*(radius_/8).^2;
    %% remove points that are too close
    data = [x0, t0];
    seglen = sqrt(sum(diff(data,1,1).^2,2));
    data = data( [seglen>1; true], :);
    opt.nPoints = size(data,1);
    opt.Fixed = false(opt.nPoints, 2);
    opt.Fixed(1,2) = true;
    opt.Fixed(end,2) = true;
    %%
    tmp_ = Snake2D(kymo, data, opt);
% tmp_ = Snake2D_ode_solver(kymo, data, opt);
    t0 = (round(tmp_(:,2)));
    x0 = (round(tmp_(:,1)));
end

end

