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

tablename="bpod_experiment";

Info = BpodSystem.Data.Info;
if Info.Subject == "FakeSubject"  % For testing
    % clear exp_info;
    Info.Subject = -1;
end

[filepath, name, ext] = fileparts(BpodSystem.Path.CurrentDataFile);
exp_info(1).experiment_id = string(strcat(name, ext));

session_start = strcat(Info.SessionDate, '-', Info.SessionStartTime_UTC);
exp_info(1).session_start_time = datestr(session_start);

exp_info(1).rat_id = Info.Subject;
exp_info(1).experimenter = string(Info.Experimenter);
exp_info(1).session_description = strjoin(Info.SessionDescription, '; ');
exp_info(1).rig_computer_id = string(strtrim(Info.Rig));
exp_info(1).bpod_version = string(Info.StateMachineVersion);
exp_info(1).bpod_branch_name = string(Info.BpodBranchName);
exp_info(1).bpod_branch_hash = string(Info.BpodBranchHash);
exp_info(1).bpod_branch_url = string(Info.BpodBranchURL);
exp_info(1).protocol_branch_name = string(Info.SessionProtocolBranchName);
exp_info(1).protocol_branch_hash = string(Info.SessionProtocolBranchHash);
exp_info(1).protocol_branch_url = string(Info.SessionProtocolBranchURL);

first_trial_start = BpodSystem.Data.TrialStartTimestamp(1);
last_trial_end = BpodSystem.Data.TrialEndTimestamp(end);
session_len = last_trial_end - first_trial_start;
exp_info(1).session_length = string(session_len / 1000);
exp_info(1).raw_data_file_path = "O:\data\";

trial_path = string(strcat(name, "_trial_custom_data_and_params.tsv"));
exp_info(1).preprocessed_trial_data_file_path = trial_path;
metadata_path = string(strcat(name, "_session_metadata.tsv"));
exp_info(1).metadata_file_path = metadata_path;


exp_info_table = struct2table(exp_info);
sqlwrite(conn, tablename, exp_info_table)

end  % Write_SessionDataInfo_to_ExperimentTable()