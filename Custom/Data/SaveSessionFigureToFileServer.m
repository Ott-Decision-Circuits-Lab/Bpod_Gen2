function SaveSessionFigureToFileServer()
global BpodSystem
%save figure

FigureFolder = 'O:\share\session_figure'; %fullfile(fileparts(fileparts(BpodSystem.DataPath)),'Session Figures');

if ~isdir(FigureFolder)
    disp('FigureFolder is not a directory. A folder is created.')
    mkdir(FigureFolder);
end

try
    FigureHandle = BpodSystem.GUIHandles.OutcomePlot.HandleOutcome.Parent; %FigureString = get(FigureHandle,'Name');
catch
    warning('Error: No FigureHandle Found. Session figure not saved to server!\n');
    return
end

try
    [~, FigureName] = fileparts(BpodSystem.Path.CurrentDataFile);
catch
    warning('Error: No DataFile Found. Session figure not saved to server!\n');
    return
end


FigurePath = fullfile(FigureFolder,[FigureName,'.png']);
try
    saveas(FigureHandle,FigurePath,'png');
catch
    warning('Error: Session figure not saved to server!\n');
    return
end

disp('SessionFigure is successfully saved in file server.')
end