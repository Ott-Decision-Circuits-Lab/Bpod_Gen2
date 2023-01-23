function conn=ConnectToSQL()
global BpodSystem
datasource = "OttDataServer";
username="lab_member";
password="TorbenOtt!2022?Database";
try
    conn = postgresql(datasource,username,password);
catch
    warning('Error: Connection to ott_lab database is not sucessful. Contact admin for support.')
    return
end
disp('Successful connection to ott_lab.');
end

