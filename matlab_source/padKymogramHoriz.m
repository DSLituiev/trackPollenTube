function out_k = padKymogramHoriz(kymogram, MARGIN_WIDTH, varargin)

leftMargin =   bsxfun(@times, nanmedian(kymogram(:,1:3), 2),      ones(1, MARGIN_WIDTH) );
rightMargin =  bsxfun(@times, nanmedian(kymogram(:,end-3:end),2), ones(1, MARGIN_WIDTH) );

if nargin<3 || varargin{1}
    out_k = [leftMargin, kymogram, rightMargin];
else
    out_k = kymogram(:, MARGIN_WIDTH+1:end-MARGIN_WIDTH);
end
