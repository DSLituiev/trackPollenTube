function  out = replace_extension(path, new_ext)

[pathstr,name, ~] = fileparts(path);
if any(new_ext == '.')
    out = fullfile(pathstr, [name, new_ext]);
else
    out = fullfile(pathstr, [name, '.', new_ext]);
end
end