%% Compute and visualize SystemITIs %%
SaveDir = '/Users/lilly/PhD/Time_value_task/Behavior/Plots/';
SessionDate = SessionData.Info.SessionDate;
Animal = SessionData.Info.Subject;
Rig = SessionData.Info.Rig;

FigName = ['R', num2str(Animal),'_', SessionDate, '_SystemITIs_'];

systemITI = zeros(length(SessionData.TrialStartTimestamp) - 1, 1);

for i = 1:length(SessionData.TrialStartTimestamp) - 1
    systemITI(i) = SessionData.TrialStartTimestamp(i+1) - SessionData.TrialEndTimestamp(i);
end

scatter(1:length(systemITI), systemITI, 10, 'filled', 'MarkerFaceAlpha', 0.4)
xlabel('Trial')
ylabel('System ITI (s)')
title(sprintf(['SystemITI distribution: R%s, %s, rig %s'], Animal, SessionDate, Rig))
saveas(gcf, fullfile(SaveDir, FigName), 'png');