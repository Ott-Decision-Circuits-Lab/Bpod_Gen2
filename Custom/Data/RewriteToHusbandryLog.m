function RewriteToHusbandryLog(SessionData, ProtocolName)
%{
Function to re-register in the database's husbandry log
that a procedure was undertaken.

Author: Antonio Lee
Date: January 13, 2026
%}

tablename = "husbandry_log";
if isempty(ProtocolName)
    ProtocolName = "TwoArmBanditVariant";
end

Info = SessionData.Info;
Custom = SessionData.Custom;
SessionMeta = SessionData.Custom.SessionMeta;
GUI = SessionData.SettingsFile.GUI;

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
    
    hubby_info.cage_number = str2num(SessionMeta.CageNumber);
    if isempty(hubby_info.cage_number)
        hubby_info.cage_numer = -1;
    end
    hubby_info.rat_location = string("ZH191");
    hubby_info.license = "G0011/22";
    hubby_info.score = "O";
    
    if sum(strcmp(fieldnames(GUI), 'PharmacologyOn')) == 1 && GUI.PharmacologyOn
        drug_info = Custom.Pharmacology;
        ExperimentalTreatment = strcat("Bpod experiment:", ProtocolName, " Pharmacology:", drug_info(1), " ", drug_info(2), " ", drug_info(3));
    else
        ExperimentalTreatment = strcat("Bpod experiment:", ProtocolName);
    end
    
    if isfield(GUI, 'Photometry') && GUI.Photometry
        ExperimentalTreatment = strcat(ExperimentalTreatment, " & photometry");
    end

    if sum(strcmp(fieldnames(GUI), 'EphysSession')) == 1 && GUI.EphysSession
        ExperimentalTreatment = strcat(ExperimentalTreatment, " & ephys measurement");
    end

    if isfield(GUI, 'LaserTrials') && GUI.LaserTrials == 1
        ExperimentalTreatment = strcat(ExperimentalTreatment, " & optogenetics");
    end

    hubby_info.experimental_treatment = string(ExperimentalTreatment);

    reward_total = RecalculateCumulativeReward(SessionData);
    reward_string = sprintf("%4.0fuL", reward_total);
    hubby_info.water_scheduling = string(reward_string);

    hubby_info.weight = str2num(SessionMeta.Weight); % non-essential
    if isempty(hubby_info.weight)
        hubby_info.weight = nan;
    end

    hubby_info.reported_by = string(SessionMeta.ReportBy);
    
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