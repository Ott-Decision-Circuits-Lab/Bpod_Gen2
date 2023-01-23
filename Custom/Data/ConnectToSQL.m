function conn=ConnectToSQL()
global BpodSystem

datasource = "OttDataServer";
username="lab_member";
password="TorbenOtt!2022?Database";

try
    conn = postgresql(datasource,username,password);
catch
    return
end

disp('Successful connection to ott_lab.');
end

