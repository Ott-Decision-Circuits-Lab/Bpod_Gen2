function WritePhotometryDataToDatabase()
%{
Function to register in the database's photometry_experiment
that a procedure was undertaken.

Author: Antonio Lee
Date: 2023-06-02
%}

global BpodSystem
global TaskParameters

try
    if isempty(BpodSystem) || ~isfield(BpodSystem.Data, 'Custom') || BpodSystem.EmulatorMode || isempty(TaskParameters)
        disp('-> Not an experimental session. No need to save Session data to database.')
        return
    end
catch
    disp('Error: Logic check. No Session data will be saved.')
    return
end

try
    if ~isfield(TaskParameters.GUI, 'Photometry') || ~TaskParameters.GUI.Photometry
        disp('-> Not a photometry experiment. No writing to photometry_experiment.')
        return
    end
catch
    disp('Error: Logic check. Photometry data not saved to database!')
    return
end

try
    Info = BpodSystem.Data.Info;
catch
    disp('Error: BpodSystem Info not found. Photometry data not saved to database!')
    return
end

try
    [~, name, ~] = fileparts(BpodSystem.Path.CurrentDataFile);
catch
    disp('Error: CurrentDataFile not found. Photometry data not saved to database!')
    return
end

try
    conn = ConnectToSQL();
catch
    disp('Error: Unable to connect to ott_lab database. Photometry data not saved to database!')
    return
end

tablename = "photometry_experiment";
try
    SessionMeta = BpodSystem.Data.Custom.SessionMeta;
    photometry_info.bpod_experiment_id = string(name);
    
    photometry_info.brain_area = string(SessionMeta.PhotometryBrainArea);

    photometry_info.led1_output_power = string(SessionMeta.LED1Power);
    photometry_info.led2_output_power = string(SessionMeta.LED2Power);
    photometry_info.green_sensor = string(SessionMeta.PhotometryGreenSensor);
    photometry_info.green_amplification = SessionMeta.PhotometryGreenAmplification;
    photometry_info.red_sensor = string(SessionMeta.PhotometryRedSensor);
    photometry_info.red_amplification = SessionMeta.PhotometryRedAmplification;
    
    photometry_info.patch_cable_id = string(SessionMeta.PhotometryPatchCableID);
    photometry_info.peripherals_validation = string(SessionMeta.PhotometryValidation);
    
    DataFolderPath = OttLabDataServerFolderPath();
    photometry_info.results_file_path = string(strcat(DataFolderPath, Info.Subject, '\bpod_session\',...
                                                      name(end-14:end), '\', name, '_Photometry'));

    if ~isempty(SessionMeta.PhotometryRemarks)
        photometry_info.remarks = string(SessionMeta.PhotometryRemarks);
    end
    
    photometry_info_table = struct2table(photometry_info);
catch
    disp('Error: fail to create photometry table.')
    close(conn)
    return
end

try
    sqlwrite(conn, tablename, photometry_info_table)
catch
    disp('Error: fail to write to photometry_experiment.')
    close(conn)
    return
end

close(conn)
disp('-> Photometrys data is written to photometry_experiment.')
end % function