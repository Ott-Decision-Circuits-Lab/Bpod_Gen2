function WriteSessionDataInfoToExperimentTable()
%{
Function to write information about the Bpod experiment to the 
bpod_experiment table in the database.

Includes file paths for other experiment data not stored in database:
  - session metadata (e.g., stimuli) -> 
  - trial custom data and parameters -> tab separated value file (.tsv)

Author: Greg Knoll
Date: October 12, 2022
%}

global BpodSystem

try
    conn = ConnectToSQL();
catch
    warning('Connection to ott_lab database is not successful. Session info not saved to database!')
    return
end

try
    if BpodSystem.EmulatorMode
        tablename = "test_bpod_experiment";
    else
        tablename = "bpod_experiment";
    end
catch
    warning('BpodSystem not found. Session info not saved to database!')
    return
end

try
    Info = BpodSystem.Data.Info;
catch
    warning('BpodSystem Info not found. Session info not saved to database!')
    close(conn)
    return
end

try
    [filepath, name, ext] = fileparts(BpodSystem.Path.CurrentDataFile);
catch
    warning('CurrentDataFile not found. Session info not saved to database!')
    close(conn)
    return
end

try
    exp_info.experiment_id = name;
    session_start = strcat(Info.SessionDate, '-', Info.SessionStartTime_UTC);
    exp_info.session_start_time = datestr(session_start);
    
    exp_info.rat_id = str2num(Info.Subject);
    if Info.Subject == "FakeSubject"  % For testing
        % clear exp_info;
        exp_info.rat_id = -1;
    elseif isempty(exp_info.rat_id)
        exp_info.rat_id = -2;
    end

    exp_info.experimenter = string(Info.Experimenter);
    exp_info.session_description = strjoin(Info.SessionDescription, '; ');
    exp_info.rig_computer_id = string(strtrim(Info.Rig));
    exp_info.bpod_version = string(Info.StateMachineVersion);
    exp_info.bpod_branch_name = string(Info.BpodBranchName);
    exp_info.bpod_branch_hash = string(Info.BpodBranchHash);
    exp_info.bpod_branch_url = string(Info.BpodBranchURL);
    exp_info.protocol_branch_name = string(Info.SessionProtocolBranchName);
    exp_info.protocol_branch_hash = string(Info.SessionProtocolBranchHash);
    exp_info.protocol_branch_url = string(Info.SessionProtocolBranchURL);
    
    first_trial_start = BpodSystem.Data.TrialStartTimestamp(1);
    last_trial_end = BpodSystem.Data.TrialEndTimestamp(end);
    session_len = last_trial_end - first_trial_start;
    exp_info.session_length = string(session_len); % (s)
    exp_info.raw_data_file_path = strcat('\\ottlabfs.bccn-berlin.pri\ottlab\data\', num2str(exp_info.rat_id),...
                                  '\bpod_session\', Info.SessionDate, '_', Info.SessionStartTime_UTC);
    
    trial_path = string(strcat(name, "_trial_custom_data_and_params.tsv"));
    exp_info.preprocessed_trial_data_file_path = trial_path;
    metadata_path = string(strcat(name, "_session_metadata.tsv"));
    exp_info.metadata_file_path = metadata_path;
    exp_info.peripherals_validation = BpodSystem.Data.Custom.SessionMeta.BehaviouralValidation;
    
    if ~isempty(BpodSystem.Data.Custom.SessionMeta.BehaviouralRemarks)
        exp_info.remarks = string(BpodSystem.Data.Custom.SessionMeta.BehaviouralRemarks);
    end
    
    exp_info_table = struct2table(exp_info);
catch
    warning('Insufficient experiment info for creating table.')
    close(conn)
    return
end

try
    sqlwrite(conn, tablename, exp_info_table)
catch
    warning('Unable to write to bpod_experiment table.')
    close(conn)
    return
end
close(conn)
disp('-> SessionData written to bpod_experiment table in database.')
end  % Write_SessionDataInfo_to_ExperimentTable()