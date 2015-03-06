function Array = unpad(Array, Padding)

if numel(Padding)==3
    Array = Array(Padding(1)+1:end-Padding(1), Padding(2)+1:end-Padding(2), Padding(3)+1:end-Padding(3));
elseif numel(Padding)==2
    Array = Array(Padding(1)+1:end-Padding(1), Padding(2)+1:end-Padding(2));
elseif numel(Padding)==1
    Array = Array(Padding(1)+1:end-Padding(1), Padding(2)+1:end-Padding(2));