function reward_total=calculate_cumulative_reward()
global BpodSystem

trial_data = BpodSystem.Data.Custom.TrialData;

reward_mag = trial_data.RewardMagnitude;
reward_trials = trial_data.Rewarded;

reward_choices = zeros(size(reward_mag)); 
reward_choices(trial_data.ChoiceLeft==1 & reward_trials, 1) = 1; 
reward_choices(trial_data.ChoiceLeft==0 & reward_trials, 2) = 1;
side_reward_mat = reward_mag.*reward_choices;

center_rewards = trial_data.CenterPortRewarded;
center_mag = trial_data.CenterPortRewAmount(end);
center_reward_mat = sum(center_rewards).* center_mag;
reward_total = round(sum(side_reward_mat(:)) + sum(center_reward_mat(:)));

end  % calculate_cumulative_reward()