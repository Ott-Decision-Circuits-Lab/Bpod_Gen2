TimeStart = '20251008_000000';
TimeEnd = '20260108_000000';
RatName = '108';

% main script
TimeStart = datetime(TimeStart, 'InputFormat', 'yyyyMMdd_HHmmss');
TimeEnd = datetime(TimeEnd, 'InputFormat', 'yyyyMMdd_HHmmss');

DataServerFolderPath = OttLabDataServerFolderPath;
BpodSessionDir = fullfile(DataServerFolderPath, RatName, 'bpod_session');
BpodSessionFolderPath = ls(BpodSessionDir);

for iSession = 1:height(BpodSessionFolderPath)
    SessionDateTimeString = BpodSessionFolderPath(iSession, :);

    % check if is '.' or '..'
    try
        SessionDateTime = datetime(SessionDateTimeString, 'InputFormat', 'yyyyMMdd_HHmmss');
    catch
        disp(strcat(SessionDateTimeString, ' is not a bpod session folder'))
        continue
    end
    
    % check if out of range
    if SessionDateTime < TimeStart || SessionDateTime > TimeEnd
        disp(strcat(SessionDateTimeString, ' is out of range'))
        continue
    end
    
    % load data
    BpodDataList = dir(fullfile(BpodSessionDir, SessionDateTimeString));
    for iBpodData = 1:length(BpodDataList)
        BpodData = BpodDataList(iBpodData);
        if BpodData.isdir
            % disp()
            continue
        end

        if ~contains(BpodData.name, '.mat')
            % disp()
            continue
        end

        try
            load(fullfile(BpodSessionDir, SessionDateTimeString, BpodData.name));
        catch
            % disp()
            continue
        end
        
        if ~exist('SessionData', 'var')
            continue
        end
        
        NameSplit = split(BpodData.name, '_');
        ProtocolName = NameSplit{2};
        RewriteToHusbandryLog(SessionData, ProtocolName)
    end

end