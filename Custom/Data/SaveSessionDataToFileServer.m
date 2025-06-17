function SaveSessionDataToFileServer()
% Saves a copy of SessionData in a new folder in file server
% 
% Created by Antonio Lee
% On 2022-10-05

global BpodSystem
global TaskParameters

try
    if isempty(BpodSystem) || ~isfield(BpodSystem.Data, 'Custom') || BpodSystem.EmulatorMode || isempty(TaskParameters)
        disp('-> Not an experimental session. No need to save Session data to server.')
        return
    end
catch
    disp('Error: Logic check. No Session data will be saved.')
    return
end

%% look for current data file
try
    [filepath, name, ext] = fileparts(BpodSystem.Path.CurrentDataFile);
catch
    disp('Warning: No data file found. Session data not saved to server!');
    return
end

%% define paths
try
    Info = BpodSystem.Data.Info;
catch
    disp('Warning: No data info found. Session data not saved to server!');
    return
end

TimestampStr = name(end-14:end);
DataFolderPath = OttLabDataServerFolderPath();
try
    SessionFolder = strcat(DataFolderPath, Info.Subject, '\bpod_session\', TimestampStr);
catch
    disp('Warning: Not enough data info for path definition. Session data not saved to server!');
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