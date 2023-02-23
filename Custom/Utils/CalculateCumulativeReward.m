function RewardTotal = CalculateCumulativeReward()
global BpodSystem

TrialData = BpodSystem.Data.Custom.TrialData;
RewardTotal = 0;

SideRewardTrials = TrialData.Rewarded;
LeftChoices = TrialData.ChoiceLeft;

if sum(SideRewardTrials)
    LeftRewardedChoices = LeftChoices & SideRewardTrials;
    TotalLeftReward = dot(TrialData.RewardMagnitudeL, LeftRewardedChoices);

    RightRewardedChoices = ~LeftChoices & SideRewardTrials;
    TotalRightReward = dot(TrialData.RewardMagnitudeR, RightRewardedChoices);
    
    RewardTotal = TotalLeftReward + TotalRightReward;
end

try  % not all protocols have center reward
    CenterRewardTrials = TrialData.CenterPortRewarded;
    CenterMag = TrialData.CenterPortRewAmount;

    RewardTotal = RewardTotal + dot(CenterMag, CenterRewardTrials);
end


end %function