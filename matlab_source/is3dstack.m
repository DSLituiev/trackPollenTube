function out = is3dstack(x)
out = ( isnumeric(x) && (sum(size(x)>1)==3) ) ;
end