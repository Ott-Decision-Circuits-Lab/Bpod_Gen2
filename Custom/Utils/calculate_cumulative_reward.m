function RewardTotal = calculate_cumulative_reward()
global BpodSystem

TrialData = BpodSystem.Data.Custom.TrialData;

try
    reward_mag = TrialData.RewardMagnitude;
    reward_trials = TrialData.Rewarded;
    
    reward_choices = zeros(size(reward_mag)); 
    reward_choices(TrialData.ChoiceLeft==1 & reward_trials, 1) = 1; 
    reward_choices(TrialData.ChoiceLeft==0 & reward_trials, 2) = 1;
    side_reward_mat = reward_mag.*reward_choices;
    
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

end  % calculate_cumulative_reward()