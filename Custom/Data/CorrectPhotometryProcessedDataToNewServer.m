function CorrectPhotometryProcessedDataToNewServer(RatID)
% construct FolderPath to bpod_session
DataFolder = OttLabDataServerFolderPath;
PhotometryDataFolderPath = fullfile(DataFolder, num2str(RatID), 'photometry', 'processed_data');

PhotometryDataObjectFolders = dir(PhotometryDataFolderPath);
for iPhotometryDataObjectFolder = 1:length(PhotometryDataObjectFolders)
    try
        FolderName = PhotometryDataObjectFolders(iPhotometryDataObjectFolder).name;
        Strings = strsplit(FolderName, '_');       
    catch
    end

    if ~strcmpi(Strings{1}, num2str(RatID))
        % disp('') <- for \. and \..
        continue
    end
    
    DataObjectFilePath = fullfile(PhotometryDataFolderPath, FolderName, 'PhotometryData.mat');
    load(DataObjectFilePath);
    if strcmpi(DataObject.ProcessedPhotometryDataFolderPath(1:39), '\\ottlabfs.bccn-berlin.pri\ottlab\data\')
        DataObject.ProcessedPhotometryDataFolderPath = DataObject.ProcessedPhotometryDataFolderPath(40:end);
    end

    save(DataObjectFilePath, 'DataObject')
end % end for
end % end function