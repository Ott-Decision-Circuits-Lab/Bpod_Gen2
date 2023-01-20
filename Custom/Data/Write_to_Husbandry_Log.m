function Write_to_Husbandry_Log()
%{
Function to register in the database's husbandry log
that a procedure was undertaken.

Author: Greg Knoll
Date: October 12, 2022
%}

global BpodSystem

conn = ConnectToSQL();

if BpodSystem.EmulatorMode
    tablename = "test_husbandry_log";
else
    tablename = "husbandry_log";
end

try
    Info = BpodSystem.Data.Info;
catch
    warning('Error: BpodSystem Info not found. No writing to husbandry_log.')
    return
end

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
hubby_info.experimental_treatment = str(strcat("Bpod experiment:", protocol_name));

reward_total = calculate_cumulative_reward();
reward_string = strcat(num2str(reward_total), "uL water administered in experiment.");
hubby_info.husbandry_treatment = str(reward_string);

hubby_info_table = struct2table(hubby_info);
sqlwrite(conn, tablename, hubby_info_table)

end