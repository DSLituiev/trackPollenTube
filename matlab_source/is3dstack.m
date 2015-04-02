function out = is3dstack(x)
out = ( isnumeric(x) && (sum(size(x)>1)==3) ) ;
if ~out && isobject(x) || islogical(x)
    try
        out = (sum(size(x)>1)==3);
    catch
        out = false;
    end
end
end