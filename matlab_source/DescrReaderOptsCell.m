function FolderListing = DescrReaderOptsCell(SourceDir, varargin)
FolderListing = dir(SourceDir);
FolderListing = FolderListing(3:end);

if isempty(varargin)
    %== Constants: file names
    CheckList = nameCheckListCell();
else
    CheckList = varargin{1};
end

% FILE_NAMES = struct(CheckList{1:2,:});
for nn = 1:size(CheckList,2)
    [FolderListing(:).(CheckList{1, nn})] = deal(false);
end

nonFolders = false(length(FolderListing),1);

for ff = 1:length(FolderListing)
    Subdir = FolderListing(ff).name;
    if isdir(fullfile(SourceDir,  FolderListing(ff).name))&&(length(FolderListing(ff).name)>=3)
        flag = true;
        SubFolderListing = dir(fullfile(SourceDir,Subdir));
        for jj = 1:length(SubFolderListing)
            for nn = 1:size(CheckList,2)
                name = regexp( CheckList{2, nn} , '(\w+\-*\w*)\.(\w+)', 'tokens');
                searchStr = strcat( name{1}{1}, '?\-(?<flag>[\w\-]+)\.',  name{1}{2}, '|',  name{1}{1}, '\.',  name{1}{2});
                [mat, fileFlag] = regexpi( {SubFolderListing(3:end).name} , searchStr, 'start', 'tokens');
                matches =  ~cellfun(@isempty, mat);
                fileFlag  =  [fileFlag{:}]; fileFlag  =  vertcat(fileFlag{:} );
                if any( matches )
                    FolderListing(ff).(CheckList{1, nn}) = true;
                    if ~isempty(fileFlag)
                        FolderListing(ff).(strcat(CheckList{1, nn}, 'Flag')) = fileFlag;
                        if size( FolderListing(ff).(strcat(CheckList{1, nn}, 'Flag')), 1) < sum(matches)
                            FolderListing(ff).(strcat(CheckList{1, nn}, 'Flag')){ sum(matches) } = '';
                        end
                    end
                elseif CheckList{3, nn}
                    flag = false;
                end
            end
        end
        FolderListing(ff).Complete = flag;
    else
        nonFolders(ff) = true;
        FolderListing(ff).Complete = false;
    end
end

% fN = fieldnames(FolderListing);
% for nn = 1:numel(fN)
%     if all(cellfun(@isempty, {FolderListing(:).(fN{nn})} ))
%         FolderListing = rmfield(FolderListing, fN{nn});
%     end
% end

FolderListing(nonFolders) = [];
if isempty(FolderListing)
    warning('DescrReader:NoFoldersFound', 'No folders have been found within the source folder!')
end

if any(strcmpi(varargin, 'full'))    
    FieldNs = fieldnames(FolderListing);
     
    fprintf('following sub-folders found within the %s :\n', SourceDir)
    fprintf('#\tName\t')
    for jj = 6:numel(FieldNs)
             fprintf('%s\t', FieldNs{jj} )
    end         
   
    for ii = 1:numel(FolderListing)
         fprintf('\n%2u\t%s\t', ii,  FolderListing(ii).name )
         for jj = 6:numel(FieldNs)
             if ~iscell(FolderListing(ii).(FieldNs{jj}))
                 fprintf('%u\t', FolderListing(ii).(FieldNs{jj}) )
             else
                  fprintf('%u elements\t', numel(FolderListing(ii).(FieldNs{jj})) )                              
             end
         end          
    end
    fprintf('\n' )
end

% _2nd
 if any(strcmpi(varargin, 'unique'))
     FolderListing = FolderListing( cellfun(@isempty, regexpi({FolderListing.name}', '.*_2nd$','end', 'once') ) );
 end

if ~any(strcmpi(varargin, 'raw'))&& numel(FolderListing)>0
    %= leave only the folders containig all the neccessary files.
    CompelteInd = [FolderListing(:).Complete]';
    FolderListing = FolderListing(CompelteInd);
    if  ~any(strcmpi(varargin, 'silent'))
        %= display the folders
        fprintf('reading the following sub-folders within the %s :\n', SourceDir)
        for ii = 1:numel(FolderListing)
            fprintf('%u:\t%s\n', ii, FolderListing(ii).name)  % disp({Listing(:).name}')
        end
    end
else
    if  ~any(strcmpi(varargin, 'silent'))
        %= display the folders
        fprintf('following sub-folders found in the %s :\n', SourceDir)
        for ii = 1:numel(FolderListing)
            fprintf('%u:\t%s\n', ii, FolderListing(ii).name)  % disp({Listing(:).name}')
        end
    end
    
end



end