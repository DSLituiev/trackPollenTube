function f = plot_roi_on_kymo(varargin)
%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'roiPath', @(x)( (ischar(x) && exist(x, 'file')) || isobject(x) || isstruct(x) ) );
addRequired(p, 'kymoPath', @(x)( (ischar(x) && exist(x, 'file')) || ( isnumeric(x) && sum(size(x)>1))==2) );
addOptional(p, 'outImgPath', '', @(x)(ischar(x)));
addOptional(p, 'format', '', @(x)(ischar(x)));
addParamValue(p, 'rotate', false, @(x)(isscalar(x)));
parse(p, varargin{:});
%% read
if (ischar(p.Results.roiPath) && exist(p.Results.roiPath, 'file'))
    [path] = constructCurveROI(p.Results.roiPath);
elseif isstruct(p.Results.roiPath)
    path = p.Results.roiPath;
end

if (ischar(p.Results.kymoPath) && exist(p.Results.kymoPath, 'file'))
    kymo = imread(p.Results.kymoPath);
elseif isnumeric(p.Results.kymoPath)
    kymo = p.Results.kymoPath;
end
%% plot the ROI
f = figure;
imagesc(kymo)
hold all
plot( path.x, path.y, 'w-', 'linewidth',3 )
plot( path.x, path.y, 'm-', 'linewidth',2 )
plot( path.x0, path.y0, 'w+', 'markersize',13 , 'linewidth', 3)
plot( path.x0, path.y0, 'm+', 'markersize',12 , 'linewidth', 2)

set(gca, 'ydir', 'reverse')
xlabel('time')
ylabel('coordinate')
%% export
if ~isempty(p.Results.outImgPath)
    if ~isempty(p.Results.format)
        opts = {'format', p.Results.format};
    else
        opts = {};
    end
    
    
    fn = fieldnames(p.Unmatched);
    for ii = 1:numel(fn)
        opts = {opts{:}, fn{ii}, p.Unmatched.(fn{ii})};
    end
    
    exportfig(f, p.Results.outImgPath, opts{:}, 'Color' , 'rgb')
end

