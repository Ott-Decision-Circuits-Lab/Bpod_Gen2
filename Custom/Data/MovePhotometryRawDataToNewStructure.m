function MovePhotometryRawDataToNewStructure(RatID)
% construct FolderPath to bpod_session
DataFolder = OttLabDataServerFolderPath;
BpodSessionFolderPath = fullfile(DataFolder, num2str(RatID), 'bpod_session');

BpodSessions = dir(BpodSessionFolderPath);
for iBpodSession = 1:length(BpodSessions)
    DateTime = [];
    try
        SessionDateTime = BpodSessions(iBpodSession).name;
        DateTime = datetime(SessionDateTime, 'InputFormat', 'yyyyMMdd_HHmmSS');
    catch
    end

    if isempty(DateTime)
        % disp('') <- for \. and \..
        continue
    end
    
    SessionDataFolderPath = fullfile(BpodSessionFolderPath, SessionDateTime);
    SessionData = dir(SessionDataFolderPath);
    for iSessionData = 1:length(SessionData)
        SessionDataFileName = SessionData(iSessionData).name;
        NameSplit = split(SessionDataFileName, '_');

        if strcmpi(NameSplit{end}, 'Photometry')
            disp(strcat('Found a raw photometry data folder for R', num2str(RatID), ' at T', SessionDateTime))
            RawPhotometryDataFolderPath = fullfile(SessionDataFolderPath, SessionDataFileName);

            NewRawPhotometryDataFoldersPath = fullfile(DataFolder, num2str(RatID), 'photometry', 'raw_data');
            if ~isfolder(NewRawPhotometryDataFoldersPath)
                mkdir(NewRawPhotometryDataFoldersPath);
            end

            NewRawPhotometryDataFolderPath = fullfile(NewRawPhotometryDataFoldersPath, SessionDataFileName);
            Status = movefile(RawPhotometryDataFolderPath, NewRawPhotometryDataFolderPath);

            if ~Status
                disp(strcat('Error: fail to transfer raw photometry data folder for R', num2str(RatID), ' at T', SessionDateTime))
            end
            
            break
        end
    end
end % end for
end % end function