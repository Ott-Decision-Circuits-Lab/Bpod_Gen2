% Script to calculate rat mean weight and standard deviation
% Eric Lonergan, Nov 2023

ratID = "76";
DOB = datetime('2024-08-13'); % Supposed date of birth, calculated by subtracting weeks of age upon delivery from date of delivery
sex = "female";
vendor = "Janvier";

currentAge = duration(datetime("today") - DOB, 'format', 'd'); % Age in days today

%% KEY INPUTS
weight = 174; % Measured weight in grams
queryAge = duration(datetime('2024-10-21') - DOB, 'format', 'd'); % Age in days on day of measurement (usually the day the water is first removed)


%% REFERENCE TABLES AND CALCULATIONS
if vendor == "Janvier"
    ages = [21, 28, 35, 42, 49, 56, 63, 70, 77, 84];
    if sex == "male"
        meanWeights = [43.8, 74.5, 114.1, 152, 194.4, 234.1, 262.7, 286.7, 309, 332.7];
        referenceSD = [4.3, 6.3, 9, 12.1, 16, 18.2, 20.7, 23.2, 23.9, 25];
    elseif sex == "female"
        meanWeights = [43, 71.6, 103.9,  128.9, 147.9, 163.5, 177.9, 192.7, 201.7, 211.1];
        referenceSD = [3.6, 5.1, 6.8, 8.4, 9.6, 12.3, 11.8, 12.4, 12.8, 12.1];
    end
elseif vendor == "CharlesRiver"
    ages = [21, 28, 35, 42, 49, 56, 63, 70, 77, 84, 91];
    if sex == "male"
        meanWeights = [69.8, 101, 158.7, 240.2, 293.0, 345.2, 386.5, 415.7, 435.6, 464.9, 485.9];
        referenceSD = [7.1, 9.8, 13.7, 14.8, 15.0, 18.3, 19.4, 20.7, 24.5, 25.4, 25.2];
    elseif sex == "female"
        meanWeights = [66.3, 97.0, 136.8, 182, 201, 225.3, 241.9, 257, 270.1, 285.7, 302.4];
        referenceSD = [5.3, 6.8, 9.2, 11.1, 11.6, 13.1, 15.5, 15.9,  16.4, 16.7, 17.6];
    end
end

% Interpolate mean weight and SD for precise age
meanWeight = interp1(ages, meanWeights, queryAge);
SD = interp1(ages, referenceSD, queryAge);

% Calculate reference percentile
refPercentile = cdf('Normal', weight, meanWeight, SD);

% Find the expected weight and SD for twelve weeks of age
twelveWeekReferenceWeight = meanWeights(find(ages == 84));
twelveWeekReferenceSD = referenceSD(find(ages == 84));

%% Calculate current baseline weight and legal minimum weight
% "Baseline" is the expected weight for the animal after 84 days (12 weeks) of age
baseline = icdf('Normal', refPercentile, twelveWeekReferenceWeight, twelveWeekReferenceSD);
lowerLimitPercentile = 0.85; % 85%
minWeight = lowerLimitPercentile * baseline; % Weight cannot drop below this value after 12 weeks of age

%% OUTPUT
disp(strcat("Expected values for ", sex, " ", vendor, " rat of age ", string(queryAge), ": ", string(meanWeight), " grams", " ± ", string(SD), " SD"))
disp(strcat("With weight of ", string(weight), " grams at age ", string(queryAge), ", rat ", ratID, " is at percentile ", string(refPercentile), " with 12 week baseline weight of ", string(baseline), " grams."))
disp(strcat("Percentile rounded down to nearest integer = ", string(floor(refPercentile*100)/100 * 100)));
disp(strcat("Minimum weight after 12 weeks of age is ", string(minWeight), " grams"))
disp(strcat("For safety, register no less than minimum weight rounded up by 2g = ", string(ceil(minWeight) + 1), "g"));
disp(strcat("Rat ", ratID, " is currently ", string(currentAge), " (", string(floor(days(currentAge) / 7)), " weeks and ", string(rem(days(currentAge), 7)), " days) old."))

