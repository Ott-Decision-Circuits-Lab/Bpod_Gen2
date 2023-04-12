function SaveAnalysisFigureToFileServer()
global BpodSystem
%The function Analysis should be inside the folder of protocol!

%% define paths
try
    Info = BpodSystem.Data.Info;
catch
    warning('No data info found. Analysis figure not saved to server!');
    return
end

try
    SessionFolder = strcat('\\ottlabfs.bccn-berlin.pri\ottlab\data\', Info.Subject, '\bpod_session\',...
                            Info.SessionDate, '_', Info.SessionStartTime_UTC);
    FigureFolder = strcat('\\ottlabfs.bccn-berlin.pri\ottlab\data\', Info.Subject, '\bpod_graph\');
catch
    warning('Not enough data info for path definition. Analysis figure not saved to server!');
    return
end

try
    [~, FigureName] = fileparts(BpodSystem.Path.CurrentDataFile);
catch
    warning('No data file found. Analysis figure not saved to server!');
    return
end

%% plot protocol-specific analysis graph
try
    FigAnalysis = Analysis();
catch
    warning('No analysis figure is made. Analysis figure not saved to server!');
    return
end

%% save plot to paths
try
    FigurePathAnalysis = fullfile(FigureFolder, [FigureName, '_Analysis.png']);
    saveas(FigAnalysis, FigurePathAnalysis, 'png');
    
    FigurePathAnalysis = fullfile(SessionFolder, [FigureName, '_Analysis.png']);
    saveas(FigAnalysis, FigurePathAnalysis, 'png');          
catch
    warning('Analysis figure not saved to server!');
    return
end

close(FigAnalysis);
disp('-> Analysis figure saved on server.')

end