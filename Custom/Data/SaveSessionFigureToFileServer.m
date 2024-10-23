function SaveSessionFigureToFileServer()

global BpodSystem
global TaskParameters

try
    if isempty(BpodSystem) || ~isfield(BpodSystem.Data, 'Custom') || BpodSystem.EmulatorMode || isempty(TaskParameters)
        disp('-> Not an experimental session. No need to save Session figure to server.')
        return
    end
catch
    disp('Error: Logic check. No Session figure will be saved.')
    return
end

%% check if outcome plot is created
try
    FigureHandle = BpodSystem.GUIHandles.OutcomePlot.HandleOutcome.Parent; %FigureString = get(FigureHandle,'Name');
catch
    disp('Warning: No figure handle found. Session figure not saved to server!');
    return
end

%% check if a corresponding session data and info is created
try
    [~, FigureName, ~] = fileparts(BpodSystem.Path.CurrentDataFile);
catch
    disp('Warning: No data file found. Session figure not saved to server!');
    return
end

try
    Info = BpodSystem.Data.Info;
catch
    disp('Warning: No data info found. Session figure not saved to server!');
    return
end

%% check or else create folders for saving in bpod_graph (duplicated copy for cross-session view)
DataFolderPath = OttLabDataServerFolderPath();
try
    FigureFolder = strcat(DataFolderPath, Info.Subject, '\bpod_graph\');
catch
    disp('Warning: Not enough info for path definition. Session figure not saved to server!');
    return
end

if ~isfolder(FigureFolder)
    disp('-> bpod_graph is not a directory. A folder is created.')
    mkdir(FigureFolder);
end

FigurePath = fullfile(FigureFolder, [FigureName, '.png']);
try
    saveas(FigureHandle, FigurePath, 'png');
    disp('-> Session figure is  successfully saved in the bpod_graph folder in the file server.')
catch
    disp('Warning: Session figure not saved to bpod_graph folder!');
end

%% check or else create folders for saving in bpod_session
TimestampStr = FigureName(end-14:end);
try
    SessionFolder = strcat(DataFolderPath, Info.Subject, '\bpod_session\', TimestampStr);
catch
    disp('Warning: Not enough data info for path definition. Session figure not saved to server!');
    return
end

if ~isfolder(SessionFolder)
    disp('-> Session folder is not a directory. A folder is created.')
    mkdir(SessionFolder);
end

FigurePath = fullfile(SessionFolder, [FigureName, '.png']);
try
    saveas(FigureHandle, FigurePath, 'png');
    disp('-> Session figure is  successfully saved in the bpod_session folder in the file server.')
catch
    disp('Warning: Session figure not saved to bpod_session folder!');
end
end % function