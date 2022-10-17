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
    tablename="test_husbandry_log";
else
    tablename="husbandry_log";
end


Info = BpodSystem.Data.Info;
if Info.Subject == "FakeSubject"  % For testing
    % clear hubby_info;
    Info.Subject = -1;
end

hubby_info.timestamp = datestr(now,30);
hubby_info.rat_id = Info.Subject;
hubby_info.cage_number = -1;

protocol_name = BpodSystem.GUIData.ProtocolName;

if protocol_name == 'NosePoke'
    reward_total = calculate_cumulative_reward();
    reward_string = strcat(": ", num2str(reward_total));
    reward_string = strcat(reward_string, "uL water administered");
    protocol_name = strcat(protocol_name, reward_string);
end

hubby_info.experimental_treatment = string(protocol_name);

hubby_info_table = struct2table(hubby_info);
sqlwrite(conn, tablename, hubby_info_table)

end