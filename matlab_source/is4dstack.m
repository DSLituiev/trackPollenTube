function out = is4dstack(x)
out = ( isnumeric(x) && (sum(size(x)>1)==4) ) ;
if ~out && isobject(x) || islogical(x)
    try
        out = (sum(size(x)>1)==4);
    catch
        out = false;
    end
end
end