function RewardTotal = CalculateCumulativeReward()
global BpodSystem

TrialData = BpodSystem.Data.Custom.TrialData;

try
    RewardMag = TrialData.RewardMagnitude;
    RewardTrials = TrialData.Rewarded;
    
    RewardChoices = zeros(size(RewardMag)); 
    RewardChoices(1, TrialData.ChoiceLeft==1 & RewardTrials) = 1; 
    RewardChoices(2, TrialData.ChoiceLeft==0 & RewardTrials) = 1;
    side_reward_mat = RewardMag.*RewardChoices;
    
    try
        center_rewards = TrialData.CenterPortRewarded;
        center_mag = TrialData.CenterPortRewAmount(end);
        center_reward_mat = sum(center_rewards).* center_mag;
        RewardTotal = round(sum(side_reward_mat(:)) + sum(center_reward_mat(:)));
    catch % if no centrer port reward is found
        RewardTotal = round(sum(side_reward_mat(:)));
    end
catch  % if no reward is found, report 0uL
    RewardTotal = 0;
end
end