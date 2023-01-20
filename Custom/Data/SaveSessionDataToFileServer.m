function SaveSessionDataToFileServer()
% If there is a mapped network drive (O:\\) on the PC, it saves a copy of
% SessionData in a new folder at O:\\data\
% 
% Created by Antonio Lee
% On 2022-10-05

global BpodSystem

try 
    [filepath,name,ext] = fileparts(BpodSystem.Path.CurrentDataFile);
    oldFolder = cd(filepath);
    [status, msg] = copyfile([name ext], 'O:\data', 'f');
    msg
    cd(oldFolder);
catch
    warning('Error: Session data not saved to server!\n');
    return
end

end