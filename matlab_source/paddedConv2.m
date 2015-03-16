function smoothZ = paddedConv2( kymogram , filterMask )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
EDGE_SIGMA_X = size(filterMask,1);
EDGE_SIGMA_Y = size(filterMask,2);

padx = bsxfun(@times, kymogram(1,:), ones(EDGE_SIGMA_X+1,1,'uint16'));
padded_kymogram = [padx; kymogram; padx];
pady = bsxfun(@times, padded_kymogram(:,1), ones(1,EDGE_SIGMA_Y+1,'uint16'));
padded_kymogram = [pady, padded_kymogram, pady];

smoothZ = conv2( padded_kymogram, filterMask, 'same' );
smoothZ = smoothZ(EDGE_SIGMA_X+1:end-EDGE_SIGMA_X-1, EDGE_SIGMA_Y+1:end-EDGE_SIGMA_Y-1);

end

