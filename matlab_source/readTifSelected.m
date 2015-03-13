function FinalImage = readTifSelected(FileTif, rowRange, colRange)
InfoImage    = imfinfo(FileTif);
NumberImages = length(InfoImage);

warning('off','MATLAB:imagesci:Tiff:libraryWarning')

FileID = Tiff(FileTif, 'r');
rows_per_strip          = FileID.getTag('RowsPerStrip');
rows_per_strip          = min(rows_per_strip, InfoImage(1).Height);

%== include the path or copy the compiled tifflib :
%  addpath('C:\Program Files\MATLAB\R2012a\toolbox\matlab\imagesci\private')

rowStart =  max(rowRange(1), 1);
rowEnd   =  min(rowRange(2), InfoImage(1).Height);
colStart =  max(colRange(1), 1);
colEnd   =  min(colRange(2), InfoImage(1).Width);

rowStartRound = rows_per_strip * floor((rowStart-1)/rows_per_strip)+1;
rowEndRound   = rows_per_strip * ceil(rowEnd/rows_per_strip);

FinalImage   = zeros(rowEndRound-rowStartRound+1, colEnd-colStart+1, NumberImages,'uint16');

%== create a column cropping structure for 'subsref' function
S.type = '()';
S.subs = {':',colStart:1:colEnd};

for zz = 1:NumberImages
    FileID.setDirectory(zz);
    %= Go through each strip of data.
    for r = rowStartRound:rows_per_strip:rowEndRound
        row_inds = (r:min(rowEndRound, r+rows_per_strip-1))-rowStartRound+1;
        stripNum = FileID.computeStrip(r);
        FinalImage(row_inds,:,zz) = subsref( FileID.readEncodedStrip(stripNum), S );
    end
end

%== crop more precisely the rows
FinalImage = FinalImage( rowStart-rowStartRound+1:end-(rowEndRound-rowEnd),:,:);

%== check the row size
if size(FinalImage,1) ~= diff(rowRange)+1
    warning('readTifSelected:DimensionMismatch', 'Row number mismatch while reading\t%s!\n',FileTif)
end
%== check the col size
if size(FinalImage,2) ~= diff(colRange)+1
    warning('readTifSelected:DimensionMismatch', 'Column number mismatch while reading\t%s!\n',FileTif)
end
    
FileID.close();
