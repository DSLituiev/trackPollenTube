%NTH_ELEMENT wrap of C++ nth_element, an efficient rank selection algorithm
%    OUTARR = NTH_ELEMENT(INARR, RANK)
%        INARR is a 2D array of data columns
%        RANK is an integer representing the selected rank to pivot around
%
%        NTH_ELEMENT works with each column in turn and calls C++ 
%            std::nth_element to iteratively pivot until the RANK element
%            is properly placed
%
%        OUTARR is a copy of INARR with the RANK element in the proper
%            position.  All elements before RANK will be less than RANK and
%            all elements after RANK will be greater, but no further sorting
%            is guaranteed.
%
%    See C++ documentation for std::nth_element for more information.
%
%    NTH_ELEMENT will work with any numeric data type except int64.  The 
%    code has lines to handle int64 but they are commented out as the C++ 
%    datatype for int64 is not standard between different compilers.  (GCC 
%    uses "long long" while VC uses __int64.)
%
%    To compile NTH_ELEMENT, you must have MEX set up with a compiler.
%    Then go to the directory that contains nth_element.cpp and run:
%        > mex nth_element.cpp
%

% Changes (for whole package including fast_median)
%   Version 0.84 - Added in-place versions of nth_element and fast_median
%   Version 0.81 - Changed to BSD license, changed error IDs, added minor 
%                  documentation to CPP files
%   Version 0.8  - Initial release

% Version 0.83
% Peter H. Li 22-Feb-2011
% As required by MatLab Central FileExchange, licensed under the FreeBSD License