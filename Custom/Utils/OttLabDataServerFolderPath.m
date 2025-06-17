% function that returns the path for the data server based on the OS of the
% user.
% Victoria Vega, Nov 2023

function ServerPath = OttLabDataServerFolderPath()
if ispc %Windows OS
    ServerPath = '\\ottfs\ott\data\';
elseif isunix && ~ismac %Linux OS
    ServerPath = '/media/ott/data/';
elseif isunix && ismac %Mac OS
    ServerPath = '/Volumes/ott/data/';
else
    ServerPath = '';
    disp('Error: Unknown operating system')
end

if ~isfolder(ServerPath)
    warning('Lab server not accessible.  Check your connection.')
end
