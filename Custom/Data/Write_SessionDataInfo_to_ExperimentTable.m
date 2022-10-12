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
    % clear experimental_results;
    Info.Subject = -1;
end

[filepath, name, ext] = fileparts(BpodSystem.Path.CurrentDataFile);

experimental_results(1).experiment_id = string(strcat(name, ext));
experimental_results(1).session_start_time = datestr(strcat(Info.SessionDate, '-', Info.SessionStartTime_UTC));
experimental_results(1).rat_id = Info.Subject;
experimental_results(1).experimenter = string(Info.Experimenter);
experimental_results(1).session_description = strjoin(Info.SessionDescription, '; ');
experimental_results(1).rig_computer_id = string(strtrim(Info.Rig));
experimental_results(1).bpod_version = string(Info.StateMachineVersion);
experimental_results(1).bpod_branch_name = string(Info.BpodBranchName);
experimental_results(1).bpod_branch_hash = string(Info.BpodBranchHash);
experimental_results(1).bpod_branch_url = string(Info.BpodBranchURL);
experimental_results(1).protocol_branch_name = string(Info.SessionProtocolBranchName);
experimental_results(1).protocol_branch_hash = string(Info.SessionProtocolBranchHash);
experimental_results(1).protocol_branch_url = string(Info.SessionProtocolBranchURL);

trial_len = BpodSystem.Data.TrialEndTimestamp(end) - BpodSystem.Data.TrialStartTimestamp(1);
experimental_results(1).session_length = string(trial_len / 1000);
experimental_results(1).raw_data_file_path = "O:\data\";
experimental_results(1).preprocessed_trial_data_file_path = string(strcat(name, "_trial_custom_data_and_params.tsv"));
experimental_results(1).metadata_file_path = string(strcat(name, "_session_metadata.tsv"));


experimental_results_table = struct2table(experimental_results);
sqlwrite(conn,tablename,experimental_results_table)

end  % Write_SessionDataInfo_to_ExperimentTable()