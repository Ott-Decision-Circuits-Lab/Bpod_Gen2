function SavePhotometryFiguresToFileServer()
global BpodSystem
global TaskParameters

%% check if there is photometry measurement
if isempty(TaskParameters)
    disp('-> No TaskParameters found. No photometry figure is  saved in the file server.')
    return
end

%% check if there is photometry measurement
if ~isfield(TaskParameters.GUI, 'Photometry') || ~TaskParameters.GUI.Photometry
    disp('-> No photometry measurement. No photometry figure is  saved in the file server.')
    return
end

%% check if photometry plot is created
FigureHandleNidaq1 = [];
try
    FigureHandleNidaq1 = BpodSystem.GUIHandles.Nidaq1.fig;
    disp('-> Nidaq1 photometry figure handle found. Trying to look for nidaq2 as well.')
catch
    disp('-> Nidaq1 photometry figure handle found.')
end

FigureHandleNidaq2 = [];
try
    FigureHandleNidaq2 = BpodSystem.GUIHandles.Nidaq2.fig; % could be only red channel is on
    disp('-> Nidaq2 photometry figure handle found.')
catch
    disp('-> No Nidaq2 photometry figure handle found.')
end 

FigureHandles = [FigureHandleNidaq1, FigureHandleNidaq2];
if isempty(FigureHandles)
    disp('-> No photometry figure is save to the server.')
    return
end

%% check if a corresponding session data and info is created
try
    Info = BpodSystem.Data.Info;
catch
    warning('No data info found. Photometry figure not saved to server!');
    return
end

try
    [~, FigureName, ~] = fileparts(BpodSystem.Path.CurrentDataFile);
catch
    warning('No data file found. Analysis figure not saved to server!');
    return
end

%% saving 1-2 photometry figure(s) with correct indexing
for i = 1:length(FigureHandles)
    idx = 1;
    if isempty(FigureHandleNidaq1) || i == 2
        idx = 2;
    end
    
    %% check or else create folders for saving in bpod_graph (duplicated copy for cross-session view)
    DataFolderPath = OttLabDataServerFolderPath();
    try
        FigureFolder = strcat(DataFolderPath, Info.Subject, '\bpod_graph\');
    catch
        warning(strcat('Not enough data info for path definition. Nidaq figure ', num2str(i),' not saved to server!'));
        break
    end

    if ~isfolder(FigureFolder)
        disp('bpod_graph is not a directory. A folder is created.')
        mkdir(FigureFolder);
    end
    
    FigurePathAnalysis = fullfile(FigureFolder, [FigureName, strcat('_Nidaq', num2str(idx), '.png')]);
    try
        saveas(FigureHandles(i), FigurePathAnalysis, 'png');
        disp(strcat('-> Nidaq',num2str(idx),' figure is  successfully saved in the bpod_graph folder in the file server.'))
    catch
        warning('Photometry figure not saved to bpod_graph folder!');
    end
    
    %% check or else create folders for saving in bpod_session
    TimestampStr = FigureName(end-14:end);
    try
        SessionFolder = strcat(DataFolderPath, Info.Subject, '\bpod_session\', TimestampStr);
    catch
        warning('Not enough data info for path definition. Analysis figure not saved to server!');
        return
    end

    if ~isfolder(SessionFolder)
        disp('bpod_session is not a directory. A folder is created.')
        mkdir(SessionFolder);
    end
    
    FigurePathAnalysis = fullfile(SessionFolder, [FigureName, strcat('_Nidaq', num2str(idx), '.png')]);
    try
        saveas(FigureHandles(i), FigurePathAnalysis, 'png');
        disp(strcat('-> Nidaq',num2str(idx),' figure is  successfully saved in the bpod_session folder in the file server.'))
    catch
        warning('Photometry figure not saved to bpod_session folder!');
    end
    
    close(FigureHandles(i));
end