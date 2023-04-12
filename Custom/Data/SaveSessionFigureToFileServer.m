function SaveSessionFigureToFileServer()
global BpodSystem
%save figure

%% check if outcome plot is created
try
    FigureHandle = BpodSystem.GUIHandles.OutcomePlot.HandleOutcome.Parent; %FigureString = get(FigureHandle,'Name');
catch
    warning('Error: No FigureHandle Found. Session figure not saved to server!\n');
    return
end

%% check if a corresponding session data is created
try
    [~, FigureName] = fileparts(BpodSystem.Path.CurrentDataFile);
catch
    warning('Error: No DataFile Found. Session figure not saved to server!\n');
    return
end

%% check or else create folders for saving
Info = BpodSystem.Data.Info;

try
    exp_info.rat_id = str2num(Info.Subject);
catch
    if Info.Subject == "FakeSubject"  % For testing
        % clear exp_info;
        exp_info.rat_id = -1;
    elseif isempty(exp_info.rat_id)
        exp_info.rat_id = -2;
    else
        exp_info.rat_id = 0
    end
    
end

SessionFolder = strcat('\\ottlabfs.bccn-berlin.pri\ottlab\data\', Info.Subject, '\bpod_session\',...
                        Info.SessionDate, '_', Info.SessionStartTime_UTC);
if ~isdir(SessionFolder)
    disp('SessionFolder is not a directory. A folder is created.')
    mkdir(SessionFolder);
end

FigureFolder = strcat('\\ottlabfs.bccn-berlin.pri\ottlab\data\', Info.Subject, '\bpod_graph\');
if ~isdir(FigureFolder)
    disp('FigureFolder is not a directory. A folder is created.')
    mkdir(FigureFolder);
end

%% save outcome plot in the two folders
FigurePath = fullfile(SessionFolder, [FigureName, '.png']);
try
    saveas(FigureHandle, FigurePath, 'png');
    disp('-> SessionFigure is  successfully saved in the session folder in the file server.')
catch
    warning('Error: Session figure not saved to bpod_session folder!\n');
end

FigurePath = fullfile(FigureFolder, [FigureName, '.png']);
try
    saveas(FigureHandle, FigurePath, 'png');
    disp('-> SessionFigure is  successfully saved in the graph folder in the file server.')
catch
    warning('Error: Session figure not saved to bpod_graph folder!\n');
end
end % function