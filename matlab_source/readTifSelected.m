function FinalImage = readTifSelected(FileTif, varargin)
% read a portion of a (multi-page) tiff file
%
%Inputs
%======
% - FileTif    -- file path
% - rowRange   -- x range
% - colRange   -- y range
% - frameRange -- frame (time, z-dimension, colour, etc.) range

%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;
addRequired(p, 'FileTif', @(x)(ischar(x) && exist(x, 'file')) );
addOptional(p, 'rowRange', [], @isnumeric );
addOptional(p, 'colRange', [], @isnumeric );
addOptional(p, 'frameRange', [1, Inf], @isnumeric );
parse(p, FileTif, varargin{:});
%%
InfoImage    = imfinfo(FileTif);
NumberImages = length(InfoImage);

warning('off','MATLAB:imagesci:Tiff:libraryWarning')

FileID = Tiff(FileTif, 'r');
rows_per_strip          = FileID.getTag('RowsPerStrip');
rows_per_strip          = min(rows_per_strip, InfoImage(1).Height);

try
    out = regexpi(FileID.getTag('ImageDescription'), 'channels=(\d*)\n', 'tokens');
    channels = str2double(out{1});
catch
    channels = 1;
end

if isempty(channels)
    warning('number of channels not found; setting to 1')
    channels = 1;
end
zFrames = floor(NumberImages/channels);

%== include the path or copy the compiled tifflib :
%  addpath('C:\Program Files\MATLAB\R2012a\toolbox\matlab\imagesci\private')
if ~isempty(p.Results.rowRange)
    rowStart =  max(double(p.Results.rowRange(1)), 1);
    rowEnd   =  min(double(p.Results.rowRange(2)), InfoImage(1).Height);
else
    rowStart =  1.0;
    rowEnd   =  double(InfoImage(1).Height);
end

if ~isempty(p.Results.colRange)
    colStart =  max(double(p.Results.colRange(1)), 1);
    colEnd   =  min(double(p.Results.colRange(2)), InfoImage(1).Width);
else
    colStart = 1;
    colEnd   = InfoImage(1).Width;
end

rowStartRound = rows_per_strip * floor((rowStart-1)/rows_per_strip)+1;
rowEndRound   = rows_per_strip * ceil(rowEnd/rows_per_strip);

%== create a column cropping structure for 'subsref' function
S.type = '()';
S.subs = {':',colStart:1:colEnd};

if ~isempty(p.Results.frameRange) 
    if numel(p.Results.frameRange) ==2
        fr1 = (max(1, p.Results.frameRange(1)) );
        fre = min(zFrames, p.Results.frameRange(2) );
        frames = fr1:1:(fre);
    end
else
    frames = 1:zFrames;
end

FinalImage   = zeros(rowEndRound-rowStartRound+1, colEnd-colStart+1, channels, numel(frames),'uint16');

for cc = 1:channels
for zz = double(frames(:)')
    ii = zz - min(frames)+1;
    FileID.setDirectory( (zz -1) * channels + 1 + cc- 1);
    %= Go through each strip of data.
    for r = rowStartRound:rows_per_strip:rowEndRound
        row_inds = (r:min(rowEndRound, r+rows_per_strip-1))-rowStartRound+1;
        stripNum = FileID.computeStrip(r);
        FinalImage(row_inds,:,cc, ii) = subsref( FileID.readEncodedStrip(stripNum), S );
    end
end
end
%== crop more precisely the rows
FinalImage = FinalImage( rowStart-rowStartRound+1:end-(rowEndRound-rowEnd),:,:,:);

%== check the row size
if size(FinalImage,1) ~= rowEnd - rowStart + 1
    warning('readTifSelected:DimensionMismatch', 'Row number mismatch while reading\t%s!\n',FileTif)
end
%== check the col size
if size(FinalImage,2) ~= colEnd -colStart +1
    warning('readTifSelected:DimensionMismatch', 'Column number mismatch while reading\t%s!\n',FileTif)
end
FinalImage = squeeze(FinalImage);
FileID.close();
