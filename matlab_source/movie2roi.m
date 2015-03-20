function [ kymogram, mov, xy_roi, rt_roi, status ] = movie2roi( tifPath, inRoiPath, varargin)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;
addRequired(p, 'tifPath', @(x)( (ischar(x) && exist(x, 'file') ) || isobject(x) ) );
addRequired(p, 'inRoiPath', @(x)(ischar(x) && exist(x, 'file') ) );
addOptional(p, 'outRoiPath', false, @(x)( islogical(x) || x==0 || x==1 || writable(x) )  );
addOptional(p, 'saveKymo',   false, @(x)( islogical(x) || x==0 || x==1 || writable(x) )  );
addOptional(p, 'visualize',  false, @isscalar);
%
parse(p, tifPath, inRoiPath,  varargin{:});
%% extract ROI file name base

pathstr = fileparts(p.Results.tifPath);
outKymoBase = fullfile(pathstr, 'kymo.tif');

if ischar(p.Results.outRoiPath) && ~isempty(p.Results.outRoiPath)
    pattern = '(.roi|.tif|.tiff)';
    replacement = '';
    outKymoBase = regexprep(p.Results.outRoiPath, pattern, replacement);
elseif p.Results.outRoiPath
    
else
    outKymoBase = '';
end
%% extract file name for kymogram if needed
if  ~writable(p.Results.saveKymo) && p.Results.saveKymo
    kymoPath = strcat(outKymoBase, '.tif');
elseif writable(p.Results.saveKymo)
    kymoPath = p.Results.saveKymo;
else
    kymoPath = '';
end
%%
[ kymogram, mov, xy_roi] = movie2kymo( tifPath, inRoiPath, kymoPath, p.Unmatched);

[ rt_roi, status ] = kymo2roi( kymogram, strcat(outKymoBase, '.roi'), p.Results.visualize, p.Unmatched );

end

