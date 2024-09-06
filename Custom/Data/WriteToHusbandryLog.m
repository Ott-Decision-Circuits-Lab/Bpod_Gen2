function WriteToHusbandryLog()
%{
Function to register in the database's husbandry log
that a procedure was undertaken.

Author: Greg Knoll
Date: October 12, 2022
%}

global BpodSystem
global TaskParameters

try
    if isempty(BpodSystem) || ~isfield(BpodSystem.Data, 'Custom') || BpodSystem.EmulatorMode || isempty(TaskParameters)
        disp('-> Not an experimental session. No need to save Session data to database .')
        return
    end
catch
    disp('Error: Logic check. No Session data will be saved.')
    return
end

if BpodSystem.EmulatorMode
    tablename = "test_husbandry_log";
else
    tablename = "husbandry_log";
end

try
    Info = BpodSystem.Data.Info;
catch
    disp('Warning: BpodSystem Info not found. Husbandry data not saved to database!')
    return
end

try
    conn = ConnectToSQL();
catch
    disp('Warning: Connection to ott_lab database is not sucessful. Husbandry data not saved to database!')
    return
end

try
    session_start = strcat(Info.SessionDate, '-', Info.SessionStartTime_UTC);
    hubby_info.timestamp = datestr(session_start);
    
    hubby_info.rat_id = str2num(Info.Subject);
    if Info.Subject == "FakeSubject"  % For testing
        % clear hubby_info;
        hubby_info.rat_id = -1;
    elseif isempty(hubby_info.rat_id)
        hubby_info.rat_id = -2;
    end
    
    hubby_info.cage_number = str2num(BpodSystem.Data.Custom.SessionMeta.CageNumber);
    if isempty(hubby_info.cage_number)
        hubby_info.cage_numer = -1;
    end
    hubby_info.rat_location = string("ZH191");
    hubby_info.license = "G0011/22";
    hubby_info.score = "O";
    
    if sum(strcmp(fieldnames(TaskParameters.GUI), 'PharmacologyOn')) == 1 && TaskParameters.GUI.PharmacologyOn
        drug_info = BpodSystem.Data.Custom.Pharmacology;
        ExperimentalTreatment = strcat("Bpod experiment:", BpodSystem.GUIData.ProtocolName, " Pharmacology:", drug_info(1), " ", drug_info(2), " ", drug_info(3));
    else
        ExperimentalTreatment = strcat("Bpod experiment:", BpodSystem.GUIData.ProtocolName);
    end
    
    if ~isempty(TaskParameters) && isfield(TaskParameters.GUI, 'Photometry') && TaskParameters.GUI.Photometry
        ExperimentalTreatment = strcat(ExperimentalTreatment, " & photometry");
    end

    if sum(strcmp(fieldnames(TaskParameters.GUI), 'EphysSession')) == 1 && TaskParameters.GUI.EphysSession
        ExperimentalTreatment = strcat(ExperimentalTreatment, " & ephys measurement");
    end
    hubby_info.experimental_treatment = string(ExperimentalTreatment);

    reward_total = CalculateCumulativeReward();
    reward_string = strcat(num2str(reward_total), "uL");
    hubby_info.water_scheduling = string(reward_string);

    hubby_info.weight = str2num(BpodSystem.Data.Custom.SessionMeta.Weight); % non-essential
    if isempty(hubby_info.weight)
        hubby_info.weight = nan;
    end

    hubby_info.reported_by = string(BpodSystem.Data.Custom.SessionMeta.ReportBy);
    
    hubby_info_table = struct2table(hubby_info);
catch
    disp('Warning: Insufficient experiment info for creating table.')
    close(conn)
    return
end

try
    sqlwrite(conn, tablename, hubby_info_table)
catch
    disp('Warning: Unsuccessful writing to husbandry_log.')
    close(conn)
    return
end

close(conn)
disp('-> HusbandryData written to husbandry_log table in database.')
end