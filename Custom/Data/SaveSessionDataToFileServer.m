function SaveSessionDataToFileServer()
% Saves a copy of SessionData in a new folder in file server
% 
% Created by Antonio Lee
% On 2022-10-05

global BpodSystem

%% look for current data file
try
    [filepath, name, ext] = fileparts(BpodSystem.Path.CurrentDataFile);
catch
    warning('No data file found. Session data not saved to server!');
    return
end

%% define paths
try
    Info = BpodSystem.Data.Info;
catch
    warning('No data info found. Analysis figure not saved to server!');
    return
end

TimestampStr = name(end-14:end);
try
    SessionFolder = strcat('\\ottlabfs.bccn-berlin.pri\ottlab\data\', Info.Subject, '\bpod_session\',...
                           TimestampStr);
catch
    warning('Not enough data info for path definition. Analysis figure not saved to server!');
    return
end

if ~isfolder(SessionFolder)
    disp('bpod_session is not a directory. A folder is created.')
    mkdir(SessionFolder);
end

%% copy file
OldFolder = cd(filepath);
[status, msg] = copyfile([name ext], SessionFolder, 'f');

if status
    disp('-> SessionData saved as .mat on file server.')
else
    warning(strcat(msg, ' Session data not saved to server!'))
end

cd(OldFolder);
end % function