% Script to calculate mean weight and standard deviation expected at
% certain age for male rats based on Janvier data

ratID = "55";
DOB = datetime('2023-07-31'); % Date of birth
weight = 313; % Measured weight in grams

%queryAge = duration(datetime("today") - DOB, 'format', 'd'); % Age in days today
queryAge = duration(datetime('2023-10-17') - DOB, 'format', 'd'); % Age in days from time of measurement

% Reference values
ages = [21, 28, 35, 42, 49, 56, 63, 70, 77, 84];
meanWeights = [43.8, 74.5, 114.1, 152, 194.4, 234.1, 262.7, 286.7, 309, 332.7];
referenceSD = [4.3, 6.3, 9, 12.1, 16, 18.2, 20.7, 23.2, 23.9, 25];

% Calculated values
meanWeight = interp1(ages, meanWeights, queryAge);
SD = interp1(ages, referenceSD, queryAge);

% Calculate reference percentile
refPercentile = cdf('Normal', weight, meanWeight, SD);

% Calculate current baseline weight and minimum set to 85%
baseline = icdf('Normal', refPercentile, 332.7, 25);
minWeight = 0.85*baseline;

disp(strcat("Expected values for rat of age ", string(queryAge), ": ", string(meanWeight), " grams", " ± ", string(SD), " SD"))
disp(strcat("Rat ", ratID, " is at percentile ", string(refPercentile), " with baseline weight of ", string(baseline), " grams."))
disp(strcat("Minimum weight after 12 weeks of age is ", string(minWeight), " grams"))
