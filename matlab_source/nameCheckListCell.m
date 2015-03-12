function NamesCell = nameCheckListCell(varargin)
% generates a checklist structure 
%     needed to check if the folder contains
%     a complete set of the required data
%
%=== Input (optional) ===
% - a char:
%    * 'p' -- process the movies
%    * 'r' -- read the readily processed data

if isempty(varargin)
    varargin{1} = 'p';
end


switch varargin{1}
    case 'p' %= process movies
        NamesCell(:,1) =  {'CheckMovie'  ; 'dsRED-a.tif'; true};
        NamesCell(:,2) =  {'CheckPathROI'; 'path.roi'; true};        
        NamesCell(:,3) =  {'CustomThrKymogram';  'kymothr-c.tif'; false};
    case 'r' %= read and display the processed data
        NamesCell(:,1) =  {'Mask'       ;  'mask.mat'; true};
        NamesCell(:,2) =  {'Stats'      ;  'stats.mat'; true};
        NamesCell(:,3) =  {'RawKymogram';  'kymoraw.tif'; true};
        NamesCell(:,4) =  {'ThrKymogram';  'kymothr.tif'; true};
end

% FILE_NAMES = struct(NamesCell{1:2,:});