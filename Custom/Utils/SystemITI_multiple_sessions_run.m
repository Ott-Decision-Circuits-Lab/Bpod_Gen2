%% Batch compute and compare ITI across recent RC-08 sessions by task
% Task-specific logic:
% - AuditoryTuning:
%       actualITI   = ITI_state_duration + next-trial overhead
%       intendedITI = SessionData.Settings(i).ITI
% - DetectionConfidence / DiscriminationConfidence:
%       actualITI   = TrialStart(i+1) - TrialEnd(i)
%       intendedITI = 1.0
% - Other:
%       actualITI   = TrialStart(i+1) - TrialEnd(i)
%       intendedITI = NaN
%
% Overlay plots are now for ITI ERROR:
%       itiError = actualITI - intendedITI
%
% Outputs:
% - Per-session plots of actual ITI
% - Task-specific overlay plots of ITI error
% - Task-specific summary plots of actual ITI
% - Task-specific summary plots of ITI error
% - CSVs

clear; clc;
close all;

%% Settings
RootDir   = 'O:\data\112\bpod_session';   % <-- change if needed
SaveDir   = fullfile(RootDir, 'SystemITI_plots_recent_RC08_byTask');
DaysBack  = 60;
WantedRig = 'RC-08';

SmoothWinDefault  = 20;
SmoothWinAuditory = 60;   % stronger smoothing for AuditoryTuning

if ~exist(SaveDir, 'dir')
    mkdir(SaveDir);
end

%% Find all session folders
d = dir(RootDir);
isSubfolder = [d.isdir] & ~ismember({d.name}, {'.', '..'});
sessionFolders = d(isSubfolder);

%% Parse folder names as datetimes
folderNames = {sessionFolders.name};
folderDateTime = NaT(size(folderNames));
isValidName = false(size(folderNames));

for i = 1:numel(folderNames)
    try
        folderDateTime(i) = datetime(folderNames{i}, 'InputFormat', 'yyyyMMdd_HHmmss');
        isValidName(i) = true;
    catch
        isValidName(i) = false;
    end
end

sessionFolders = sessionFolders(isValidName);
folderDateTime = folderDateTime(isValidName);

%% Keep only recent sessions
cutoffDate = datetime('today') - days(DaysBack);
keepRecent = folderDateTime >= cutoffDate;

sessionFolders = sessionFolders(keepRecent);
folderDateTime = folderDateTime(keepRecent);

%% Sort chronologically
[folderDateTime, sortIdx] = sort(folderDateTime);
sessionFolders = sessionFolders(sortIdx);

fprintf('Found %d recent session folders in the last %d days.\n', numel(sessionFolders), DaysBack);

if isempty(sessionFolders)
    error('No recent session folders found.');
end

%% Task names
taskList = {'AuditoryTuning', 'DetectionConfidence', 'DiscriminationConfidence', 'Other'};

%% Initialize task-wise containers
taskData = struct();

for t = 1:numel(taskList)
    taskName = taskList{t};

    if strcmp(taskName, 'AuditoryTuning')
        smoothWinThisTask = SmoothWinAuditory;
    else
        smoothWinThisTask = SmoothWinDefault;
    end

    % Overlay raw error
    taskData.(taskName).figRawErr = figure('Color', 'w', 'Visible', 'off');
    hold on; grid on; box off;
    title(sprintf('Raw ITI error over time: %s (%s)', taskName, WantedRig), 'Interpreter', 'none');
    xlabel('Time in session (s)');
    ylabel('ITI error = actual - intended (s)');
    yline(0, '--k');

    % Overlay smoothed error
    taskData.(taskName).figSmoothErr = figure('Color', 'w', 'Visible', 'off');
    hold on; grid on; box off;
    title(sprintf('Smoothed ITI error over time: %s (%s)', taskName, WantedRig), 'Interpreter', 'none');
    xlabel('Time in session (s)');
    ylabel(sprintf('ITI error (moving median, win = %d)', smoothWinThisTask));
    yline(0, '--k');

    taskData.(taskName).smoothWin = smoothWinThisTask;
    taskData.(taskName).labels = {};
    taskData.(taskName).count = 0;

    taskData.(taskName).sessionNames = {};
    taskData.(taskName).sessionDates = {};
    taskData.(taskName).animals = {};
    taskData.(taskName).rigs = {};
    taskData.(taskName).methods = {};

    taskData.(taskName).medianITI = [];
    taskData.(taskName).meanITI = [];
    taskData.(taskName).stdITI = [];
    taskData.(taskName).nITI = [];

    taskData.(taskName).medianITIError = [];
    taskData.(taskName).meanITIError = [];
    taskData.(taskName).medianAbsITIError = [];
end

%% Combined summary storage
allSessionNames = {};
allSessionDates = {};
allAnimals = {};
allRigs = {};
allTaskNames = {};
allITIMethods = {};

nITI_all = [];
medianITI_all = [];
meanITI_all = [];
stdITI_all = [];

medianITIError_all = [];
meanITIError_all = [];
medianAbsITIError_all = [];

cmap = lines(max(numel(sessionFolders), 7));

%% Loop over sessions
for k = 1:numel(sessionFolders)

    sessionFolderName = sessionFolders(k).name;
    sessionFolderPath = fullfile(RootDir, sessionFolderName);

    fprintf('\nProcessing %s\n', sessionFolderName);

    %% Find .mat file
    matFiles = dir(fullfile(sessionFolderPath, '*.mat'));
    if isempty(matFiles)
        warning('No .mat file found in folder: %s', sessionFolderPath);
        continue
    end

    matPath = fullfile(sessionFolderPath, matFiles(1).name);
    matName = matFiles(1).name;
    matNameLower = lower(matName);

    %% Load SessionData
    S = load(matPath);

    if ~isfield(S, 'SessionData')
        warning('No SessionData struct found in file: %s', matPath);
        continue
    end

    SessionData = S.SessionData;

    %% Check required fields
    if ~isfield(SessionData, 'TrialStartTimestamp') || ~isfield(SessionData, 'TrialEndTimestamp')
        warning('Missing TrialStartTimestamp or TrialEndTimestamp in: %s', matPath);
        continue
    end

    tsStart = SessionData.TrialStartTimestamp(:);
    tsEnd   = SessionData.TrialEndTimestamp(:);

    if numel(tsStart) < 2 || numel(tsEnd) < 1
        warning('Not enough trial timestamps in: %s', matPath);
        continue
    end

    %% Metadata
    Animal = 'NA';
    SessionDate = sessionFolderName;
    Rig = 'NA';

    if isfield(SessionData, 'Info')
        if isfield(SessionData.Info, 'Subject')
            Animal = SessionData.Info.Subject;
        end
        if isfield(SessionData.Info, 'SessionDate')
            SessionDate = SessionData.Info.SessionDate;
        end
        if isfield(SessionData.Info, 'Rig')
            Rig = SessionData.Info.Rig;
        end
    end

    AnimalStr = char(string(Animal));
    SessionDateStr = char(string(SessionDate));
    RigStr = char(string(Rig));

    %% Rig filter
    if ~isempty(WantedRig) && ~strcmpi(strtrim(RigStr), strtrim(WantedRig))
        fprintf('Skipping %s because rig is %s\n', sessionFolderName, RigStr);
        continue
    end

    %% Classify task from mat file name
    if contains(matNameLower, 'auditorytuning')
        TaskName = 'AuditoryTuning';
    elseif contains(matNameLower, 'detectionconfidence')
        TaskName = 'DetectionConfidence';
    elseif contains(matNameLower, 'discriminationconfidence')
        TaskName = 'DiscriminationConfidence';
    else
        TaskName = 'Other';
    end

    smoothWinThisTask = taskData.(TaskName).smoothWin;

    %% Default components
    overheadITI = tsStart(2:end) - tsEnd(1:end-1);
    ITI_time = tsStart(2:end);

    %% Compute task-specific actual and intended ITI
    switch TaskName

        case 'AuditoryTuning'
            if ~isfield(SessionData, 'RawEvents') || ~isfield(SessionData.RawEvents, 'Trial')
                warning('AuditoryTuning file missing RawEvents.Trial: %s', matPath);
                continue
            end
            if ~isfield(SessionData, 'Settings')
                warning('AuditoryTuning file missing SessionData.Settings: %s', matPath);
                continue
            end

            nTrials = numel(SessionData.RawEvents.Trial);
            itiStateDur = nan(nTrials,1);
            intendedITI_full = nan(nTrials,1);

            for t = 1:nTrials
                if numel(SessionData.Settings) >= t && isfield(SessionData.Settings(t), 'ITI')
                    intendedITI_full(t) = SessionData.Settings(t).ITI;
                end

                try
                    if isfield(SessionData.RawEvents.Trial{t}, 'States') && ...
                            isfield(SessionData.RawEvents.Trial{t}.States, 'ITI')
                        itiWin = SessionData.RawEvents.Trial{t}.States.ITI;
                        if ~isempty(itiWin) && size(itiWin,2) >= 2
                            itiStateDur(t) = sum(itiWin(:,2) - itiWin(:,1), 'omitnan');
                        end
                    end
                catch
                    itiStateDur(t) = NaN;
                end
            end

            nCommon = min([numel(overheadITI), numel(itiStateDur), numel(intendedITI_full)]);
            itiStateDur = itiStateDur(1:nCommon);
            intendedITI = intendedITI_full(1:nCommon);
            overheadITI = overheadITI(1:nCommon);
            ITI_time    = ITI_time(1:nCommon);

            actualITI = itiStateDur + overheadITI;
            methodStr = 'AuditoryTuning: actual = ITI state + overhead; intended = Settings.ITI';

        case {'DetectionConfidence', 'DiscriminationConfidence'}
            actualITI = overheadITI;
            intendedITI = ones(size(actualITI));
            methodStr = 'Detection/Discrimination: actual = next TrialStart - previous TrialEnd; intended = 1 s';

        otherwise
            actualITI = overheadITI;
            intendedITI = nan(size(actualITI));
            methodStr = 'Other: actual = next TrialStart - previous TrialEnd; intended = unknown';
    end

    %% Remove invalid values
    validIdx = isfinite(actualITI) & isfinite(ITI_time);
    if any(isfinite(intendedITI))
        validIdx = validIdx & isfinite(intendedITI);
    end

    actualITI   = actualITI(validIdx);
    intendedITI = intendedITI(validIdx);
    ITI_time    = ITI_time(validIdx);

    if isempty(actualITI)
        warning('No valid ITI values in session: %s', sessionFolderName);
        continue
    end

    itiError = actualITI - intendedITI;
    absItiError = abs(itiError);

    %% Per-session plot 1: actual ITI vs trial transition
    fig1 = figure('Visible', 'off', 'Color', 'w');
    scatter(1:numel(actualITI), actualITI, 16, 'filled', ...
        'MarkerFaceAlpha', 0.4, 'MarkerFaceColor', [0.2 0.4 0.8]);
    hold on;
    yline(median(actualITI, 'omitnan'), '--r', 'LineWidth', 1.5);
    yline(mean(actualITI, 'omitnan'), '--k', 'LineWidth', 1.5);
    xlabel('Trial transition');
    ylabel('Actual ITI (s)');
    title(sprintf('%s actual ITI vs trial: Animal %s | %s | Rig %s', ...
        TaskName, AnimalStr, SessionDateStr, RigStr), 'Interpreter', 'none');
    subtitle(methodStr, 'Interpreter', 'none');
    grid on; box off;

    figName1 = sprintf('R%s_%s_%s_ActualITI_vsTrial.png', AnimalStr, sessionFolderName, TaskName);
    saveas(fig1, fullfile(SaveDir, figName1));
    close(fig1);

    %% Per-session plot 2: actual ITI vs time in session
    fig2 = figure('Visible', 'off', 'Color', 'w');
    scatter(ITI_time, actualITI, 16, 'filled', ...
        'MarkerFaceAlpha', 0.35, 'MarkerFaceColor', [0.2 0.4 0.8]);
    hold on;

    if numel(actualITI) >= smoothWinThisTask
        smoothedITI = movmedian(actualITI, smoothWinThisTask, 'omitnan');
        plot(ITI_time, smoothedITI, 'r-', 'LineWidth', 2);
    else
        smoothedITI = actualITI;
        plot(ITI_time, smoothedITI, 'r-', 'LineWidth', 1.5);
    end

    xlabel('Time in session (s)');
    ylabel('Actual ITI (s)');
    title(sprintf('%s actual ITI vs time: Animal %s | %s | Rig %s', ...
        TaskName, AnimalStr, SessionDateStr, RigStr), 'Interpreter', 'none');
    subtitle(sprintf('%s | smoothing win = %d', methodStr, smoothWinThisTask), 'Interpreter', 'none');
    grid on; box off;

    figName2 = sprintf('R%s_%s_%s_ActualITI_vsTime.png', AnimalStr, sessionFolderName, TaskName);
    saveas(fig2, fullfile(SaveDir, figName2));
    close(fig2);

    %% Add to task-specific overlay ERROR figures
    taskData.(TaskName).count = taskData.(TaskName).count + 1;
    idx = taskData.(TaskName).count;
    thisColor = cmap(mod(idx-1, size(cmap,1)) + 1, :);

    figure(taskData.(TaskName).figRawErr);
    plot(ITI_time, itiError, '-', 'Color', thisColor, 'LineWidth', 1.0);

    figure(taskData.(TaskName).figSmoothErr);
    if numel(itiError) >= smoothWinThisTask
        smoothedErr = movmedian(itiError, smoothWinThisTask, 'omitnan');
    else
        smoothedErr = itiError;
    end
    plot(ITI_time, smoothedErr, '-', 'Color', thisColor, 'LineWidth', 2);

    taskData.(TaskName).labels{idx} = sessionFolderName;

    %% Store task-specific summaries
    taskData.(TaskName).sessionNames{end+1,1} = sessionFolderName;
    taskData.(TaskName).sessionDates{end+1,1} = SessionDateStr;
    taskData.(TaskName).animals{end+1,1} = AnimalStr;
    taskData.(TaskName).rigs{end+1,1} = RigStr;
    taskData.(TaskName).methods{end+1,1} = methodStr;

    taskData.(TaskName).nITI(end+1,1) = numel(actualITI);
    taskData.(TaskName).medianITI(end+1,1) = median(actualITI, 'omitnan');
    taskData.(TaskName).meanITI(end+1,1) = mean(actualITI, 'omitnan');
    taskData.(TaskName).stdITI(end+1,1) = std(actualITI, 'omitnan');

    taskData.(TaskName).medianITIError(end+1,1) = median(itiError, 'omitnan');
    taskData.(TaskName).meanITIError(end+1,1) = mean(itiError, 'omitnan');
    taskData.(TaskName).medianAbsITIError(end+1,1) = median(absItiError, 'omitnan');

    %% Store combined summaries
    allSessionNames{end+1,1} = sessionFolderName;
    allSessionDates{end+1,1} = SessionDateStr;
    allAnimals{end+1,1} = AnimalStr;
    allRigs{end+1,1} = RigStr;
    allTaskNames{end+1,1} = TaskName;
    allITIMethods{end+1,1} = methodStr;

    nITI_all(end+1,1) = numel(actualITI);
    medianITI_all(end+1,1) = median(actualITI, 'omitnan');
    meanITI_all(end+1,1) = mean(actualITI, 'omitnan');
    stdITI_all(end+1,1) = std(actualITI, 'omitnan');

    medianITIError_all(end+1,1) = median(itiError, 'omitnan');
    meanITIError_all(end+1,1) = mean(itiError, 'omitnan');
    medianAbsITIError_all(end+1,1) = median(absItiError, 'omitnan');
end

%% Save task-specific overlay and summary plots
for t = 1:numel(taskList)
    taskName = taskList{t};

    if isempty(taskData.(taskName).medianITI)
        fprintf('No sessions for task: %s\n', taskName);
        continue
    end

    %% Overlay plots: raw ITI error
    figure(taskData.(taskName).figRawErr);
    legend(taskData.(taskName).labels, 'Location', 'bestoutside', 'Interpreter', 'none');
    saveas(taskData.(taskName).figRawErr, fullfile(SaveDir, sprintf('Overlay_%s_ITIError_RAW.png', taskName)));

    %% Overlay plots: smoothed ITI error
    figure(taskData.(taskName).figSmoothErr);
    legend(taskData.(taskName).labels, 'Location', 'bestoutside', 'Interpreter', 'none');
    saveas(taskData.(taskName).figSmoothErr, fullfile(SaveDir, sprintf('Overlay_%s_ITIError_SMOOTH.png', taskName)));

    %% Summary: median actual ITI
    figMed = figure('Color', 'w', 'Visible', 'off');
    plot(taskData.(taskName).medianITI, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
    xlabel('Session');
    ylabel('Median actual ITI (s)');
    title(sprintf('Median actual ITI across sessions: %s (%s)', taskName, WantedRig), 'Interpreter', 'none');
    grid on; box off;
    set(gca, 'XTick', 1:numel(taskData.(taskName).sessionNames), ...
             'XTickLabel', taskData.(taskName).sessionNames, ...
             'XTickLabelRotation', 45);
    saveas(figMed, fullfile(SaveDir, sprintf('Summary_Median_%s_ActualITI.png', taskName)));
    close(figMed);

    %% Summary: mean actual ITI
    figMean = figure('Color', 'w', 'Visible', 'off');
    plot(taskData.(taskName).meanITI, '-o', 'LineWidth', 1.5, 'MarkerSize', 6, 'Color', [0.1 0.5 0.2]);
    xlabel('Session');
    ylabel('Mean actual ITI (s)');
    title(sprintf('Mean actual ITI across sessions: %s (%s)', taskName, WantedRig), 'Interpreter', 'none');
    grid on; box off;
    set(gca, 'XTick', 1:numel(taskData.(taskName).sessionNames), ...
             'XTickLabel', taskData.(taskName).sessionNames, ...
             'XTickLabelRotation', 45);
    saveas(figMean, fullfile(SaveDir, sprintf('Summary_Mean_%s_ActualITI.png', taskName)));
    close(figMean);

    %% Summary: median signed ITI error
    figErrMed = figure('Color', 'w', 'Visible', 'off');
    plot(taskData.(taskName).medianITIError, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
    yline(0, '--k');
    xlabel('Session');
    ylabel('Median(actual - intended ITI) (s)');
    title(sprintf('Median ITI error across sessions: %s (%s)', taskName, WantedRig), 'Interpreter', 'none');
    grid on; box off;
    set(gca, 'XTick', 1:numel(taskData.(taskName).sessionNames), ...
             'XTickLabel', taskData.(taskName).sessionNames, ...
             'XTickLabelRotation', 45);
    saveas(figErrMed, fullfile(SaveDir, sprintf('Summary_MedianITIError_%s.png', taskName)));
    close(figErrMed);

    %% Summary: mean signed ITI error
    figErrMean = figure('Color', 'w', 'Visible', 'off');
    plot(taskData.(taskName).meanITIError, '-o', 'LineWidth', 1.5, 'MarkerSize', 6, 'Color', [0.8 0.2 0.2]);
    yline(0, '--k');
    xlabel('Session');
    ylabel('Mean(actual - intended ITI) (s)');
    title(sprintf('Mean ITI error across sessions: %s (%s)', taskName, WantedRig), 'Interpreter', 'none');
    grid on; box off;
    set(gca, 'XTick', 1:numel(taskData.(taskName).sessionNames), ...
             'XTickLabel', taskData.(taskName).sessionNames, ...
             'XTickLabelRotation', 45);
    saveas(figErrMean, fullfile(SaveDir, sprintf('Summary_MeanITIError_%s.png', taskName)));
    close(figErrMean);

    %% Summary: median absolute ITI error
    figErrAbs = figure('Color', 'w', 'Visible', 'off');
    plot(taskData.(taskName).medianAbsITIError, '-o', 'LineWidth', 1.5, 'MarkerSize', 6, 'Color', [0.2 0.2 0.8]);
    xlabel('Session');
    ylabel('Median |actual - intended ITI| (s)');
    title(sprintf('Median absolute ITI error across sessions: %s (%s)', taskName, WantedRig), 'Interpreter', 'none');
    grid on; box off;
    set(gca, 'XTick', 1:numel(taskData.(taskName).sessionNames), ...
             'XTickLabel', taskData.(taskName).sessionNames, ...
             'XTickLabelRotation', 45);
    saveas(figErrAbs, fullfile(SaveDir, sprintf('Summary_MedianAbsITIError_%s.png', taskName)));
    close(figErrAbs);

    %% Per-task CSV
    Ttask = table( ...
        taskData.(taskName).sessionNames, ...
        taskData.(taskName).sessionDates, ...
        taskData.(taskName).animals, ...
        taskData.(taskName).rigs, ...
        taskData.(taskName).methods, ...
        taskData.(taskName).nITI, ...
        taskData.(taskName).medianITI, ...
        taskData.(taskName).meanITI, ...
        taskData.(taskName).stdITI, ...
        taskData.(taskName).medianITIError, ...
        taskData.(taskName).meanITIError, ...
        taskData.(taskName).medianAbsITIError, ...
        'VariableNames', {'FolderName','SessionDate','Animal','Rig','ITIMethod', ...
                          'NumTransitions','MedianActualITI','MeanActualITI','StdActualITI', ...
                          'MedianITIError','MeanITIError','MedianAbsITIError'});

    writetable(Ttask, fullfile(SaveDir, sprintf('Summary_%s_ITI.csv', taskName)));
end

%% Combined CSV across all tasks
if ~isempty(allSessionNames)
    Tall = table(allSessionNames, allSessionDates, allAnimals, allRigs, allTaskNames, allITIMethods, ...
                 nITI_all, medianITI_all, meanITI_all, stdITI_all, ...
                 medianITIError_all, meanITIError_all, medianAbsITIError_all, ...
                 'VariableNames', {'FolderName','SessionDate','Animal','Rig','TaskName','ITIMethod', ...
                                   'NumTransitions','MedianActualITI','MeanActualITI','StdActualITI', ...
                                   'MedianITIError','MeanITIError','MedianAbsITIError'});

    writetable(Tall, fullfile(SaveDir, 'SystemITI_summary_allTasks_recent_RC08.csv'));
else
    warning('No sessions passed filters.');
end

%% Done
disp('Done. Outputs saved to:');
disp(SaveDir);