function Write_to_Husbandry_Log(conn)

tablename="husbandry_log";
data=sqlread(conn,tablename);
% colnames = string(data.Properties.VariableNames)
% colnames = ["rat_id" "cage_number" "experimental_treatment"];
% colvals = [string(datestr(now,30)), string(datestr(now,30)), 0, 1, 'Ott', 'NULL', 'O', shg, 'NULL', 0, 'NULL', 'NULL', 'Done by BPod']

clear results
results(1).timestamp = string(datestr(now,30));
results(1).rat_id = 0;
results(1).cage_number = 0;
results(1).date = "";
results(1).rat_number = 0;
results_table = struct2table(results);
sqlwrite(conn,tablename,results_table)
end