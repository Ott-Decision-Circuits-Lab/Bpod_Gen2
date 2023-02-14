function WriteToHusbandryLog()
%{
Function to register in the database's husbandry log
that a procedure was undertaken.

Author: Greg Knoll
Date: October 12, 2022
%}

global BpodSystem

try
    conn = ConnectToSQL();
catch
    warning('Error: Connection to ott_lab database is not sucessful. Husbandry data not saved to database!')
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
    warning('Error: BpodSystem Info not found. Husbandry data not saved to database!')
    close(conn)
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
    
    hubby_info.cage_number = -1;
    hubby_info.license = "TVA 0011/22";
    
    protocol_name = BpodSystem.GUIData.ProtocolName;
    hubby_info.experimental_treatment = string(strcat("Bpod experiment:", protocol_name));
    
    reward_total = CalculateCumulativeReward();
    reward_string = strcat(num2str(reward_total), "uL");
    hubby_info.water_scheduling = string(reward_string);
    
    hubby_info_table = struct2table(hubby_info);
catch
    warning('Error: Insufficient experiment info for creating table.')
    close(conn)
    return
end

try
    sqlwrite(conn, tablename, hubby_info_table)
catch
    warning('Error: Unsuccessful writing to husbandry_log.')
    close(conn)
    return
end
close(conn)
disp('HusbandryData is successfully written to husbandry_log.')
end