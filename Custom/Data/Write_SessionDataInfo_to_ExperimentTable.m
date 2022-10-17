function Write_SessionDataInfo_to_ExperimentTable()
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

conn = ConnectToSQL();

if BpodSystem.EmulatorMode
    tablename="test_bpod_experiment";
else
    tablename="bpod_experiment";
end

Info = BpodSystem.Data.Info;
if Info.Subject == "FakeSubject"  % For testing
    % clear exp_info;
    Info.Subject = -1;
end

[filepath, name, ext] = fileparts(BpodSystem.Path.CurrentDataFile);
exp_info.experiment_id = string(strcat(name, ext));

session_start = strcat(Info.SessionDate, '-', Info.SessionStartTime_UTC);
exp_info.session_start_time = datestr(session_start);

exp_info.rat_id = Info.Subject;
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
exp_info.session_length = string(session_len / 1000);
exp_info.raw_data_file_path = "O:\data\";

trial_path = string(strcat(name, "_trial_custom_data_and_params.tsv"));
exp_info.preprocessed_trial_data_file_path = trial_path;
metadata_path = string(strcat(name, "_session_metadata.tsv"));
exp_info.metadata_file_path = metadata_path;


exp_info_table = struct2table(exp_info);
sqlwrite(conn, tablename, exp_info_table)

end  % Write_SessionDataInfo_to_ExperimentTable()