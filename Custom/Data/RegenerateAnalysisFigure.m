DataFolderPath = OttLabDataServerFolderPath();
RatID = '29';
ProtocolName = 'TwoArmBanditVariant';
sessions_path = [DataFolderPath RatID '\bpod_session'];
session_folders = ls(sessions_path);
for session_idx = 1:height(session_folders)
    session_date = session_folders(session_idx, :);
    if any(session_date(1:8) ~= '20230929')
        continue
    end
    
    data_folder = fullfile(sessions_path, session_date);
    files_in_data_folder = ls(data_folder);
    target_data_name = strcat(RatID, '_', ProtocolName, '_', session_date, '.mat');
    string_length = length(target_data_name);
    
    file_path = '';
    for file_idx = 1:height(files_in_data_folder)
        if strcmpi(files_in_data_folder(file_idx, 1:string_length), target_data_name)
            file_path = fullfile(data_folder, files_in_data_folder(file_idx, 1:string_length));
            continue
        end
    end
    
    if isempty(file_path)
        continue
    end
    
    FigHandle = Analysis(file_path);
    if isempty(FigHandle)
        continue
    end

    FigurePathAnalysis = fullfile(data_folder, [target_data_name(1:end-4), '_Analysis.png']);
    saveas(FigHandle, FigurePathAnalysis, 'png');

    sessions_graph_path = [DataFolderPath RatID '\bpod_graph'];
    saveas(FigHandle, sessions_graph_path, 'png');

end