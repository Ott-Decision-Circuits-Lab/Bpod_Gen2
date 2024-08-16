% Script to stitch two .mat SessionData files together. Requires updated struct with .Custom.TrialData
% Eric Lonergan Oct 2023

dirName = '\\ottlabfs.bccn-berlin.pri\ottlab\data\52\bpod_session\20240611';

% Load first file
firstFileName = '52_DetectionConfidence_20240611_114040.mat';
firstFileFullDir = fullfile(dirName, firstFileName);
firstFile = load(firstFileFullDir);

% Load second file
secondFileName = '52_DetectionConfidence_20240611_131432.mat';
secondFileFullDir = fullfile(dirName, secondFileName);
secondFile = load(secondFileFullDir);

first_nTrialsMinusAborted = firstFile.SessionData.nTrials-1; % Aborted trial from first file will be aborted in this script

firstFile.SessionData.nTrials = first_nTrialsMinusAborted + secondFile.SessionData.nTrials; % Aborted trial from second file will be aborted in main analysis script

firstFile.SessionData.TrialSettings = horzcat(firstFile.SessionData.TrialSettings(:, 1:first_nTrialsMinusAborted), secondFile.SessionData.TrialSettings);

firstFile.SessionData.RawEvents.Trial = horzcat(firstFile.SessionData.RawEvents.Trial(1:first_nTrialsMinusAborted), secondFile.SessionData.RawEvents.Trial);

RawDataFieldnames = fieldnames(firstFile.SessionData.RawData);
for i=1:numel(RawDataFieldnames)
    firstFile.SessionData.RawData.(RawDataFieldnames{i}) = horzcat(firstFile.SessionData.RawData.(RawDataFieldnames{i})(1:first_nTrialsMinusAborted), secondFile.SessionData.RawData.(RawDataFieldnames{i}));
end

TrialDataFieldnames = fieldnames(firstFile.SessionData.Custom.TrialData);
for i=1:numel(TrialDataFieldnames)
    try
        firstFile.SessionData.Custom.TrialData.(TrialDataFieldnames{i}) = horzcat(firstFile.SessionData.Custom.TrialData.(TrialDataFieldnames{i})(1:first_nTrialsMinusAborted), secondFile.SessionData.Custom.TrialData.(TrialDataFieldnames{i}));
    catch
        continue
    end
end

firstFileLastStartTimestamp = firstFile.SessionData.TrialStartTimestamp(first_nTrialsMinusAborted);
firstFile.SessionData.TrialStartTimestamp = horzcat(firstFile.SessionData.TrialStartTimestamp(1:first_nTrialsMinusAborted), (secondFile.SessionData.TrialStartTimestamp+firstFileLastStartTimestamp));

firstFileLastEndTimestamp = firstFile.SessionData.TrialEndTimestamp(first_nTrialsMinusAborted);
firstFile.SessionData.TrialEndTimestamp = horzcat(firstFile.SessionData.TrialEndTimestamp(1:first_nTrialsMinusAborted), (secondFile.SessionData.TrialEndTimestamp+firstFileLastEndTimestamp));

if contains(firstFileName, 'stitched')
    newFilePath = strrep(fullfile(dirName, firstFileName), 'stitched', 'full_stitched');
else
    newFilePath = strrep(fullfile(dirName, firstFileName), 'newstruct', 'stitched');
end
save(newFilePath, '-struct', 'firstFile')

