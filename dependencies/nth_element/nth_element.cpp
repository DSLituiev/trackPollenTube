/* nth_element.cpp
 * Ver 0.83
 * Peter H. Li 2011 FreeBSD License 
 * See nth_element.m for documentation. 
 */
#include "nth_element.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

  // Check inputs
  if (nrhs != 2) {
    mexErrMsgIdAndTxt("Numerical:nth_element:nrhs", "Arguments should be the matrix of columns and the rank of the desired element");
  }
  if (!mxIsNumeric(prhs[0])) {
    mexErrMsgIdAndTxt("nth_element:prhs", "First argument must be a numeric matrix.");
  }
  if (!mxIsNumeric(prhs[1]) || mxGetNumberOfDimensions(prhs[1]) != 2 || mxGetM(prhs[1]) != 1 || mxGetN(prhs[1]) != 1) {
    mexErrMsgIdAndTxt("nth_element:prhs", "Second argument must be a scalar.");
  }


  // Validate rank argument
  mwIndex rank = (mwIndex) mxGetScalar(prhs[1]);
  const mwSize nrows = mxGetM(prhs[0]);
  if (rank < 1) {
    mexErrMsgIdAndTxt("nth_element:prhs", "Rank cannot be less than 1.");
  }
  if (rank > nrows) {
    mexErrMsgIdAndTxt("nth_element:prhs", "Rank cannot be greater than the number of rows.");
  }

  // Convert matlab-style index (starts at 1) to C++ (starts at 0).
  rank--;
  

  // Copy input array, pass to inplace generic method
  const mwSize ncols = mxGetN(prhs[0]);
  plhs[0] = mxDuplicateArray(prhs[0]);
  run_nth_element(plhs[0], rank, ncols, nrows);
}
