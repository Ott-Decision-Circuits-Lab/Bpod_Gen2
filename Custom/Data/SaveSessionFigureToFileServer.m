function SaveSessionFigureToFileServer()
global BpodSystem
%save figure

%% check if outcome plot is created
try
    FigureHandle = BpodSystem.GUIHandles.OutcomePlot.HandleOutcome.Parent; %FigureString = get(FigureHandle,'Name');
catch
    warning('No figure handle found. Session figure not saved to server!');
    return
end

%% check if a corresponding session data and info is created
try
    [~, FigureName] = fileparts(BpodSystem.Path.CurrentDataFile);
catch
    warning('No data file found. Session figure not saved to server!');
    return
end

try
    Info = BpodSystem.Data.Info;
catch
    warning('No data info found. Session figure not saved to server!');
    return
end

%% check or else create folders for saving in bpod_graph (duplicated copy for cross-session view)
try
    FigureFolder = strcat('\\ottlabfs.bccn-berlin.pri\ottlab\data\', Info.Subject, '\bpod_graph\');
catch
    warning('Not enough info for path definition. Session figure not saved to server!');
    return
end

if ~isdir(FigureFolder)
    disp('bpod_graph is not a directory. A folder is created.')
    mkdir(FigureFolder);
end

FigurePath = fullfile(FigureFolder, [FigureName, '.png']);
try
    saveas(FigureHandle, FigurePath, 'png');
    disp('-> Session figure is  successfully saved in the bpod_graph folder in the file server.')
catch
    warning('Session figure not saved to bpod_graph folder!');
end

%% check or else create folders for saving in bpod_session
try
    SessionFolder = strcat('\\ottlabfs.bccn-berlin.pri\ottlab\data\', Info.Subject, '\bpod_session\',...
                        Info.SessionDate, '_', Info.SessionStartTime_UTC);
catch
    warning('Not enough data info for path definition. Session figure not saved to server!');
    return
end

if ~isdir(SessionFolder)
    disp('Session folder is not a directory. A folder is created.')
    mkdir(SessionFolder);
end

FigurePath = fullfile(SessionFolder, [FigureName, '.png']);
try
    saveas(FigureHandle, FigurePath, 'png');
    disp('-> Session figure is  successfully saved in the bpod_session folder in the file server.')
catch
    warning('Session figure not saved to bpod_session folder!');
end
end % function