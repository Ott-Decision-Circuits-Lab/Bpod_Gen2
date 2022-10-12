function conn=ConnectToSQL()
global BpodSystem
datasource = "OttDataServer";
username="lab_member";
password="TorbenOtt!2022?Database";
conn = postgresql(datasource,username,password);
end

