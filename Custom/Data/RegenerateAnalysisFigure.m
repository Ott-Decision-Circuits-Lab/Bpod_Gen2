sessions_path = '\\ottlabfs.bccn-berlin.pri\ottlab\data\1\bpod_session';
session_folders = ls(sessions_path);
for session_idx = 1: height(session_folders)
    session_date = session_folders(session_idx, :);
    if any(session_date(1:4) ~= '2023')
        continue
    end
    
    data_folder = fullfile(sessions_path, session_date);
    files_in_data_folder = ls(data_folder);
    target_data_name = strcat('1_TwoArmBanditVariant_', session_date, '.mat');
    string_length = length(target_data_name);
    
    file_path = '';
    for file_idx = 1:height(files_in_data_folder)
        if all(files_in_data_folder(file_idx, 1:string_length) == target_data_name)
            file_path = fullfile(data_folder, files_in_data_folder(file_idx, 1:string_length));
        end
    end
    
    if isempty(file_path)
        continue
    end
    
    FigHandle = Analysis(file_path);
    FigurePathAnalysis = fullfile(data_folder, [target_data_name(1:end-4), '_Analysis.png']);
    saveas(FigHandle, FigurePathAnalysis, 'png');

    sessions_path = '\\ottlabfs.bccn-berlin.pri\ottlab\data\1\bpod_graph';
    saveas(FigHandle, sessions_path, 'png');

end