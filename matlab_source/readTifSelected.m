function FinalImage = readTifSelected(FileTif, varargin)
%% check the input parameters
p = inputParser;
p.KeepUnmatched = true;
addRequired(p, 'FileTif', @(x)(ischar(x) && exist(x, 'file')) );
addOptional(p, 'rowRange', [1, Inf], @isnumeric );
addOptional(p, 'colRange', [1, Inf], @isnumeric );
addOptional(p, 'frameRange', [1, Inf], @isnumeric );
parse(p, FileTif, varargin{:});
%%
InfoImage    = imfinfo(FileTif);
NumberImages = length(InfoImage);

warning('off','MATLAB:imagesci:Tiff:libraryWarning')

FileID = Tiff(FileTif, 'r');
rows_per_strip          = FileID.getTag('RowsPerStrip');
rows_per_strip          = min(rows_per_strip, InfoImage(1).Height);

%== include the path or copy the compiled tifflib :
%  addpath('C:\Program Files\MATLAB\R2012a\toolbox\matlab\imagesci\private')

rowStart =  max(double(p.Results.rowRange(1)), 1);
rowEnd   =  min(double(p.Results.rowRange(2)), InfoImage(1).Height);
colStart =  max(double(p.Results.colRange(1)), 1);
colEnd   =  min(double(p.Results.colRange(2)), InfoImage(1).Width);

rowStartRound = rows_per_strip * floor((rowStart-1)/rows_per_strip)+1;
rowEndRound   = rows_per_strip * ceil(rowEnd/rows_per_strip);


%== create a column cropping structure for 'subsref' function
S.type = '()';
S.subs = {':',colStart:1:colEnd};

if ~isempty(p.Results.frameRange) 
    if numel(p.Results.frameRange) ==2
        frames = max(1, p.Results.frameRange(1)):1:min(NumberImages, p.Results.frameRange(2));
    end
else
    frames = 1:NumberImages;
end

FinalImage   = zeros(rowEndRound-rowStartRound+1, colEnd-colStart+1, numel(frames),'uint16');

for zz = double(frames(:)')
    ii = zz - min(frames)+1;
    FileID.setDirectory(zz);
    %= Go through each strip of data.
    for r = rowStartRound:rows_per_strip:rowEndRound
        row_inds = (r:min(rowEndRound, r+rows_per_strip-1))-rowStartRound+1;
        stripNum = FileID.computeStrip(r);
        FinalImage(row_inds,:,ii) = subsref( FileID.readEncodedStrip(stripNum), S );
    end
end

%== crop more precisely the rows
FinalImage = FinalImage( rowStart-rowStartRound+1:end-(rowEndRound-rowEnd),:,:);

%== check the row size
if size(FinalImage,1) ~= rowEnd - rowStart + 1
    warning('readTifSelected:DimensionMismatch', 'Row number mismatch while reading\t%s!\n',FileTif)
end
%== check the col size
if size(FinalImage,2) ~= colEnd -colStart +1
    warning('readTifSelected:DimensionMismatch', 'Column number mismatch while reading\t%s!\n',FileTif)
end

FileID.close();
