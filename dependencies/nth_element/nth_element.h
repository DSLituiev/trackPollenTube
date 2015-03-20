/* nth_element.h
 * Ver 0.83
 * Peter H. Li 2011 FreeBSD License
 */
#ifndef ALGORITHM_H
  #include <algorithm>
  #define ALGORITHM_H
#endif

#ifndef MEX_H
  #include "mex.h"
  #define MEX_H
#endif

        
// This runs on data inplace!
template <typename T> void nth_element_cols(T *data, mwIndex rank, mwSize ncols, mwSize nrows) {
  mwIndex start, thisRank, end;
  for (mwIndex i = 0; i < ncols; i++) {
    // Figure out linear indices into this column
    start = i * nrows;
    thisRank = start + rank;
    end = (i + 1) * nrows;

    // Run nth_element to iteratively partition to the specified rank
    std::nth_element(data + start, data + thisRank, data + end);
  }
}



// Determine type of data, run
// This runs on data inplace!
void run_nth_element(mxArray *inarr, mwIndex rank, mwSize ncols, mwSize nrows) {
  void *indata = mxGetData(inarr);

  switch (mxGetClassID(inarr)) {
    case mxDOUBLE_CLASS:
      nth_element_cols((double *) indata, rank, ncols, nrows);
      break;

    case mxSINGLE_CLASS:
      nth_element_cols((float *) indata, rank, ncols, nrows);
      break;

    case mxINT8_CLASS:
      nth_element_cols((signed char *) indata, rank, ncols, nrows);
      break;

    case mxUINT8_CLASS:
      nth_element_cols((unsigned char *) indata, rank, ncols, nrows);
      break;

    case mxINT16_CLASS:
      nth_element_cols((signed short *) indata, rank, ncols, nrows);
      break;

    case mxUINT16_CLASS:
      nth_element_cols((unsigned short *) indata, rank, ncols, nrows);
      break;

    case mxINT32_CLASS:
      nth_element_cols((signed int *) indata, rank, ncols, nrows);
      break;

    case mxUINT32_CLASS:
      nth_element_cols((unsigned int *) indata, rank, ncols, nrows);
      break;

    // Uncomment these if int64 is needed, but note that on some compilers
    // it's called "__int64" instead of "long long"
    //case mxINT64_CLASS:
      //nth_element_cols((signed long long *) indata, rank, ncols, nrows);
      //break;

    //case mxUINT64_CLASS:
      //nth_element_cols((unsigned long long *) indata, rank, ncols, nrows);
      //break;

    default:
      mexErrMsgIdAndTxt("Numerical:nth_element:prhs", "Unrecognized numeric array type.");
  }
}
