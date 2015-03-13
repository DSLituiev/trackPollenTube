function out = writable(filename)
% WRITEABLE -- checks if a file can be written on disk

% if isempty(filename)
%     out = true;
%     return
% end

if ~ischar(filename)
    out = false;
    return
end

pathstr = fileparts(filename);
[~, fa] = fileattrib(pathstr);
out = fa.UserWrite;

end