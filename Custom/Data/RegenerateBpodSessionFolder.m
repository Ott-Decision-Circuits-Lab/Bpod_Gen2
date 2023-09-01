data_path = OttLabDataServerFolderPath();
data_path_dir = dir(data_path);

for idx = 1: length(data_path_dir)
    if data_path_dir(idx).isdir == 0 || isempty(str2num(data_path_dir(idx).name))
        continue
    end
    
    animal_folder = fullfile(data_path, data_path_dir(idx).name);
    animal_folder_dir = dir(animal_folder);
    
    bpod_session_exist = false;
    for jdx = 1:length(animal_folder_dir)
        if strcmp(animal_folder_dir(jdx).name, 'bpod_session')
            bpod_session_exist = true;
            break
        end
    end
    
    if ~bpod_session_exist
        continue
    end
    
    for jdx = 1:length(animal_folder_dir)
        if length(animal_folder_dir(jdx).name) < 4
            continue
        end

        if strcmp(animal_folder_dir(jdx).name(end-3:end), '.mat')
            session_start_time = animal_folder_dir(jdx).name(end-18:end-4);
            session_folder_path = fullfile(animal_folder, 'bpod_session', session_start_time);
            status = mkdir(session_folder_path);

            session_file_path = fullfile(animal_folder, animal_folder_dir(jdx).name);
            movefile(session_file_path, session_folder_path);
        elseif strcmp(animal_folder_dir(jdx).name(end-3:end), '.csv')
            session_start_time = animal_folder_dir(jdx).name(end-47:end-33);
            session_folder_path = fullfile(animal_folder, 'bpod_session', session_start_time);

            session_file_path = fullfile(animal_folder, animal_folder_dir(jdx).name);
            movefile(session_file_path, session_folder_path);
        end
    end

end