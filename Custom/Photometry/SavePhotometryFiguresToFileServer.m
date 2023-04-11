function SavePhotometryFiguresToFileServer()
global BpodSystem
global TaskParameters
%save figure

FigureFolder = 'O:\share\session_figure'; %fullfile(fileparts(fileparts(BpodSystem.DataPath)),'Session Figures');

if ~isdir(FigureFolder)
    disp('FigureFolder is not a directory. A folder is created.')
    mkdir(FigureFolder);
end

try
    [~, FigureName] = fileparts(BpodSystem.Path.CurrentDataFile);
catch
    warning('Error: No DataFile Found. Session figure not saved to server!\n');
    return
end

% try
    if TaskParameters.GUI.Photometry
        FigureHandleNidaq1 = BpodSystem.GUIHandles.Nidaq1.fig;
        Figure1Path = fullfile(FigureFolder,[FigureName,'_Nidaq1.png']);
%         try
            saveas(FigureHandleNidaq1,Figure1Path,'png');
%         catch
%             warning('Error: Nidaq1 figure not saved to server!\n');
%             return
%         end
        disp('-> FigNidaq1 is successfully saved in file server.')

        if TaskParameters.GUI.RedChannel
            FigureHandleNidaq2 = BpodSystem.GUIHandles.Nidaq2.fig;
            Figure2Path = fullfile(FigureFolder,[FigureName,'_Nidaq2.png']);
%             try
                saveas(FigureHandleNidaq2,Figure2Path,'png');
%             catch
%                 warning('Error: Nidaq2 figure not saved to server!\n');
%                 return
%             end
            disp('-> FigNidaq2 is successfully saved in file server.')
        end
    end
% catch
%     warning('Error: photometry figurehandles not found.  Photometry figures not saved to server!\n')
%     return
% end

end