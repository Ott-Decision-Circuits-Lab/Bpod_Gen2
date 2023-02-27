function RewardTotal = CalculateCumulativeReward()
global BpodSystem

TrialData = BpodSystem.Data.Custom.TrialData;
RewardTotal = 0;

SideRewardTrials = TrialData.Rewarded;

if sum(~isnan(SideRewardTrials))
    LeftChoices = TrialData.ChoiceLeft;
    NotNan = ~isnan(LeftChoices);
    LeftRewards = LeftChoices(NotNan) & SideRewardTrials(NotNan);
    TotalLeftReward = dot(TrialData.RewardMagnitudeL(NotNan), LeftRewards);

    RightChoices = ~LeftChoices(NotNan);
    RightRewards = RightChoices & SideRewardTrials(NotNan);
    TotalRightReward = dot(TrialData.RewardMagnitudeR(NotNan), RightRewards);
    
    RewardTotal = TotalLeftReward + TotalRightReward;
end

try  % not all protocols have center reward
    CenterRewardTrials = TrialData.CenterPortRewarded;
    CenterMag = TrialData.CenterPortRewAmount;

    RewardTotal = RewardTotal + dot(CenterMag, CenterRewardTrials);
end

end %function