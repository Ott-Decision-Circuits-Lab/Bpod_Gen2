% function that returns the path for the data server based on the OS of the
% user.
% Victoria Vega, Nov 2023

function ServerPath = OttLabDataServerFolderPath()
if ispc %Windows OS
    ServerPath = '\\ottlabfs.bccn-berlin.pri\ottlab\data\';
elseif isunix && ~ismac %Linux OS
    ServerPath = '/media/ottlab/data/';
elseif isunix && ismac %Mac OS
    ServerPath = '/Volumes/ottlab/data/';
else
    disp('Error: Unknown operating system')
end