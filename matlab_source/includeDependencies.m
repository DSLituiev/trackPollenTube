function includeDependencies( )
%% include dependencies
USERFNCT_PATH = '../dependencies';
addpath(USERFNCT_PATH);
addpath(fullfile(USERFNCT_PATH, 'MinMaxSelection'));
addpath(fullfile(USERFNCT_PATH, 'fastmedfilt1d'));
addpath(fullfile(USERFNCT_PATH, 'altmany-export_fig-1524a2f'));
addpath(fullfile(USERFNCT_PATH, 'ImageJROI'));
addpath(fullfile(USERFNCT_PATH, 'saveastiff_2.51'));
addpath(fullfile(USERFNCT_PATH, 'canny'));
addpath(fullfile(USERFNCT_PATH, 'BasicSnake'));
addpath(fullfile(USERFNCT_PATH, 'mtimesx')); % 

addpath(fullfile(USERFNCT_PATH, 'nth_element')); % fast_median for visualization
end

