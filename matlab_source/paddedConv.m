function smoothZ = paddedConv( z , filterMask )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

smoothZ = conv( [z(1)*ones(numel(filterMask),1) ; z; z(end)*ones(numel(filterMask),1) ], filterMask, 'same' );
smoothZ = smoothZ(numel(filterMask)+1: end - numel(filterMask));

end

