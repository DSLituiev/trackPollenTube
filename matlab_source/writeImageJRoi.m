function status = writeImageJRoi(fileName, roiType, x, y)
%WRITEIMAGEJROI(fileName, roiType, x, y)  -- writes ImageJ ROI files given coordinates and ROI type
%    INPUT:
% fileName -- file name for the ROI, e.g. 'cell.roi'
% roiType  -- type of ROI according to ImageJ specifications
%             + Use roiType = 'PolyLine' for splines
% x        -- x-coordinate positions
% y        -- y-coordinate positions
%
% Copyright: Dmytro Lituiev 2014

if numel(x)~=numel(y)
    error('writeImageJRoi:dimMismatch', 'dimension mismatch')
end

roiTypeStr = { 0, 'Polygon','';  ...
    3,  'Line','';...
    4,  'FreeLine', ''; ...
    5,  'PolyLine','';...
    6,  'NoROI', '';...
    7,  'Freehand', 'Ellipse'; ...
    8,  'Traced','';...
    9,  'Angle', '';
    10, 'Point',''};

if ~any(strcmpi(roiType, roiTypeStr(:, 2:end)))    
    error('writeImageJRoi:unknownroiType', 'unknown roiType')
end

sROI.nroiTypeID  = roiTypeStr{any(strcmpi(roiType, roiTypeStr(:, 2:end)), 2), 1};
sROI.nVersion = 223;

% ['nTop', 'nLeft', 'nBottom', 'nRight']
ROI.vnRectBounds = [ min(y), min(x), max(y), max(x)];
ROI.coordsX = x(:);
ROI.coordsY = y(:);

ROI.nNumCoords = numel(x);

fidROI = fopen(fileName, 'w', 'ieee-be');

fwrite(fidROI, zeros(256,1) , 'uint8');

frewind(fidROI)

count = 0;
count = count + fwrite(fidROI, 'Iout');
count = count + fwrite(fidROI, sROI.nVersion , 'int16');

% -- Write ROI roiType
count = count + fwrite(fidROI, sROI.nroiTypeID, 'uint8');
 fwrite(fidROI, 0, 'uint8'); % Skip a byte
 count = count + 1;

% -- Write rectangular bounds
count = count + fwrite(fidROI, ROI.vnRectBounds, 'int16');
% -- Write number of coordinates
count = count + fwrite(fidROI, ROI.nNumCoords, 'int16');

vfLinePoints = zeros(1,4);

% -- Write something (?)
fseek(fidROI, 63, 'bof');
count = count + fwrite(fidROI,  6*16^3, 'int16');
 
% -- Go after header
fseek(fidROI, 64, 'bof'); count = 64;

count = count + fwrite(fidROI, ROI.coordsX - ROI.vnRectBounds(2), 'int16');
count = count + fwrite(fidROI, ROI.coordsY - ROI.vnRectBounds(1), 'int16');

status = fclose(fidROI);