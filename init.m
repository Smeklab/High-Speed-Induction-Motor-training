%Example initialization script for a project folder


%Add EMDtool folder to the Matlab search path. Could be permanently added,
%too, but this makes it easier to e.g. swap between multiple EMDtool
%versions.
%
% NOTE that the path will be different for your computer.
addpath(genpath('E:\Work\Matlab\EMDtool\Versions\3.0.2\EMDtool'));

%Add all subfolders to the search path.
addpath(genpath(cd()))