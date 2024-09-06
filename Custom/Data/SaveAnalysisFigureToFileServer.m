function SaveAnalysisFigureToFileServer()
global BpodSystem
%The function Analysis should be inside the folder of protocol!

%% check if there is protocol-specific analysis
if isfile('Analysis.m') == 0
    disp('Warning: No protocol-specific Analysis.m is found. No analysis figure is  saved in the file server.')
    return
end

%% check if a corresponding session data and info is created
try
    Info = BpodSystem.Data.Info;
catch
    disp('Warning: No data info found. Analysis figure not saved to server!');
    return
end

try
    [~, FigureName, ~] = fileparts(BpodSystem.Path.CurrentDataFile);
catch
    disp('Warning: No data file found. Analysis figure not saved to server!');
    return
end

%% plot protocol-specific analysis graph
try
    FigAnalysis = Analysis();
catch
    disp('Warning: No analysis figure is made. Analysis figure not saved to server!');
    return
end

%% check or else create folders for saving in bpod_graph (duplicated copy for cross-session view)
DataFolderPath = OttLabDataServerFolderPath();
try
    FigureFolder = strcat(DataFolderPath, Info.Subject, '\bpod_graph\');
catch
    disp('Warning: Not enough data info for path definition. Analysis figure not saved to server!');
    return
end

if ~isfolder(FigureFolder)
    disp('-> bpod_graph is not a directory. A folder is created.')
    mkdir(FigureFolder);
end

FigurePathAnalysis = fullfile(FigureFolder, [FigureName, '_Analysis.png']);
try
    saveas(FigAnalysis, FigurePathAnalysis, 'png');
    disp('-> Analysis figure is  successfully saved in the bpod_graph folder in the file server.')
catch
    disp('Warning: Analysis figure not saved to bpod_graph folder!');
end

%% check or else create folders for saving in bpod_session
TimestampStr = FigureName(end-14:end);
try
    SessionFolder = strcat(DataFolderPath, Info.Subject, '\bpod_session\', TimestampStr);
catch
    disp('Warning: Not enough data info for path definition. Analysis figure not saved to server!');
    return
end

if ~isfolder(SessionFolder)
    disp('-> Session folder is not a directory. A folder is created.')
    mkdir(SessionFolder);
end

FigurePath = fullfile(SessionFolder, [FigureName, '_Analysis.png']);
try
    saveas(FigAnalysis, FigurePath, 'png');
    disp('-> Analysis figure is  successfully saved in the bpod_session folder in the file server.')
catch
    disp('Warning: Analysis figure not saved to bpod_session folder!');
end

close(FigAnalysis);
end