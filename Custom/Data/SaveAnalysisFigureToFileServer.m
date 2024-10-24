function SaveAnalysisFigureToFileServer()
global BpodSystem
%The function Analysis should be inside the folder of protocol!

FigureFolder = 'O:\data\session_figures'; %fullfile(fileparts(fileparts(BpodSystem.DataPath)),'Session Figures');
[~, FigureName] = fileparts(BpodSystem.Path.CurrentDataFile);

FigAnalysis = Analysis();
FigurePathAnalysis = fullfile(FigureFolder,[FigureName,'_Analysis.png']);
saveas(FigAnalysis,FigurePathAnalysis,'png');
close(FigAnalysis);

end