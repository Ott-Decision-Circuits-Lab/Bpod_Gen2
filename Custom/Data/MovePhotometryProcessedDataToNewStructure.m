function MovePhotometryProcessedDataToNewStructure(RatID)
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

        if strcmpi(NameSplit{1}, 'ProcessedPhotometry')
            disp(strcat('Found a processed photometry data folder for R', num2str(RatID), ' at T', SessionDateTime))
            ProcessedPhotometryDataFolderPath = fullfile(SessionDataFolderPath, SessionDataFileName);

            NewProcessedPhotometryDataFoldersPath = fullfile(DataFolder, num2str(RatID), 'photometry', 'processed_data');
            if ~isfolder(NewProcessedPhotometryDataFoldersPath)
                mkdir(NewProcessedPhotometryDataFoldersPath);
            end

            load(fullfile(ProcessedPhotometryDataFolderPath, 'PhotometryData.mat')); % Variable Name will be DataObject
            SessionName = DataObject.SessionName;

            NewProcessedPhotometryDataFolderPath = fullfile(NewProcessedPhotometryDataFoldersPath, strcat(SessionName, '_', SessionDataFileName));
            Status = movefile(ProcessedPhotometryDataFolderPath, NewProcessedPhotometryDataFolderPath);

            if ~Status
                disp(strcat('Error: fail to transfer processed photometry data folder for R', num2str(RatID), ' at T', SessionDateTime))
            end
            
            break
        end
    end
end % end for
end % end function