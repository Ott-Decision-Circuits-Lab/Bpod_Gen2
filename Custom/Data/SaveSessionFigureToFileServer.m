function SaveSessionFigureToFileServer()
global BpodSystem
%save figure

FigureFolder = 'O:\data\session_figures'; %fullfile(fileparts(fileparts(BpodSystem.DataPath)),'Session Figures');
FigureHandle = BpodSystem.GUIHandles.OutcomePlot.HandleOutcome.Parent; %FigureString = get(FigureHandle,'Name');
[~, FigureName] = fileparts(BpodSystem.Path.CurrentDataFile);

if ~isdir(FigureFolder)
    mkdir(FigureFolder);
end

FigurePath = fullfile(FigureFolder,[FigureName,'.png']);
saveas(FigureHandle,FigurePath,'png');

end