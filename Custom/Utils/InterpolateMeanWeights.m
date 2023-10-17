% Script to calculate mean weight expected at certain age for male rats

queryAge = 78;
ages = [21, 28, 35, 42, 49, 56, 63, 70, 77, 84];
meanWeights = [43.8, 74.5, 114.1, 152, 194.4, 234.1, 262.7, 286.7, 309, 332.7];
SD = [4.3, 6.3, 9, 12.1, 16, 18.2, 20.7, 23.2, 23.9, 25];

disp(strcat(string(interp1(ages, meanWeights, queryAge)), " grams", " ± ", string(interp1(ages, SD, queryAge)), " SD"))