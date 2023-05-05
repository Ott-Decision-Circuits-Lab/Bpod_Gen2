% This script goes through the database and adds "supplement" to each day
% where rats have consumed less than 9 mL. 
% 
% Note: This script works by checking existing entries in the database. If
% there are no entries on a particular day, the script ignores that day.
% This means that if you are skipping training, the script will miss that
% day, such that you must enter "supplement" manually into the database.

% Database fields. Enter your data accordingly.

rat_id = 12; % Must be run for each rat separately
water_scheduling = 'supplement'; % String to be added in water_scheduling column
reported_by = 'Eric Lonergan'; % Caretaker
cage_number = 6;
license = 'G0011/22';
min_water = 9000; % Define the minimum amount of water rats should consume in µL

% Define a fixed time of supplementation for each rat
if rat_id == 12
    time_of_supplement_string = '18:00:00';
elseif rat_id == 13
    time_of_supplement_string = '19:00:00';
elseif rat_id == 1
    time_of_supplement_string = '19:00:01';
elseif rat_id == 2
    time_of_supplement_string = '19:00:02';
elseif rat_id == 3
    time_of_supplement_string = '19:00:03';
elseif rat_id == 4
    time_of_supplement_string = '19:00:04';
elseif rat_id == 21
    time_of_supplement_string = '19:00:21';
elseif rat_id == 22
    time_of_supplement_string = '19:00:22';
elseif rat_id == 23
    time_of_supplement_string = '19:00:23';
elseif rat_id == 24
    time_of_supplement_string = '19:00:24';
end

% Connect to the PostgreSQL database
conn = ConnectToSQL();

query = ['SELECT "timestamp", rat_id, experimental_treatment, water_scheduling ' ...
    'FROM public.husbandry_log ' ...
    'WHERE rat_id = ' , num2str(rat_id)];

data = fetch(conn, query); % Table queried from database
data = sortrows(data,"timestamp","ascend"); % Makes checks easier

% Drop rows from data with water scheduling starts
WaterSchedulingStart = (data.water_scheduling == "start");
data = data(~(WaterSchedulingStart), :);

% Drop rows from data if water_scheduling is missing
NoWaterSched = ismissing(data.water_scheduling);
data = data(~(NoWaterSched), :);

% Insert new column with µL water amount as integer
data.water_scheduling = strip(data.water_scheduling,'right','l');
data.water_scheduling = strip(data.water_scheduling,'right','L');
data.water_scheduling = strip(data.water_scheduling,'right','u');
data.water_scheduling_int = str2double(data.water_scheduling);

% Get UniqueDates and total_water for each date in data
AllDates = datetime(year(data.timestamp),month(data.timestamp),day(data.timestamp));
[UniqueDates,~,jj] = unique(AllDates); % get unique dates
% Sum water from each date. % can't use @sum, because int + NaN = NaN
total_water = groupsummary(data.water_scheduling_int,jj,"sum");

% Already Supplemented Table
AST = data(data.water_scheduling == "supplement", :);
AST.timestamp = datetime(year(AST.timestamp),month(AST.timestamp),day(AST.timestamp));

% Make TotalWaterTable
TotalWaterTable = table(UniqueDates,total_water); % create table

% Supplementation usually does not occur on Friday, Saturday, and Sunday
[DayNumber] = weekday(TotalWaterTable.UniqueDates);
Fri = (DayNumber == 6);
Sat = (DayNumber == 7);
Sun = (DayNumber == 1);
TotalWaterTable = TotalWaterTable(~(Fri | Sat | Sun), :);

% Table to be written to database
SupplementTable = [];

% Loop through the dates in TotalWaterTable, add values to SupplementTable
for i = 1:height(TotalWaterTable)

    % Extract total water consumed
    water_consumed = TotalWaterTable.total_water(i);

    % Extract date
    curr_date = TotalWaterTable.UniqueDates(i); % e.g. 06-Dec-2022
    date = datetime(curr_date, 'Format', 'yyyyMMdd'); % e.g. 20221206 (datetime class)
    date_string = string(date); % e.g. "20221206"

    % Convert time of supplementation to format compatible with database
    time_of_supplement_string_NoColon = time_of_supplement_string(~ismember(time_of_supplement_string, ':'));
    timestamp = strcat(date_string, ['_', time_of_supplement_string_NoColon]);
    
    % Skip if timestamp already in the database (no longer necessary)
    % for comparison with pre-existing entries e.g. 06-Dec-2022 18:00:00
    %supplement_datetime = datetime(strcat(datestr(curr_date), " ", time_of_supplement_string), 'InputFormat', 'dd-MMM-yyyy HH:mm:ss' );
    %if any(strcmp(string(datestr(data.timestamp)), string(supplement_datetime)))
    %    continue
    %end

    % Skip if 'supplement' entry already in the database for that particular day
    if ismember(curr_date, AST.timestamp)
        continue
    end
    
    % Check if the rats have consumed at least 9000 µL on current date
    if water_consumed >= min_water
        % Rats have consumed at least 9000 µL, no changes needed
        continue
    else
        % Rats have not consumed at least 9000 µL, requires "supplement"
        if isempty(SupplementTable) % Create table with data relevant to supplementation
            SupplementTable = table(timestamp,rat_id,cage_number,{license},{water_scheduling},{reported_by});
            SupplementTable.Properties.VariableNames = {'timestamp','rat_id','cage_number','license','water_scheduling','reported_by'};
        else % Table already exists -> append new values to table
            SupplementTable = [SupplementTable;{timestamp},rat_id,cage_number,{license},{water_scheduling},{reported_by}];
        end
    end
end

% Check SupplementTable
SupplementTable

if isempty(SupplementTable)
    disp("All 'supplement' entries up to date, no additional entries made.")
else
    % Write Supplement Table to database
    % -----------------------------------------------------------------%
    % Add breakpoint here if you want to test before writing to database
    % -----------------------------------------------------------------%
    tablename="husbandry_log";
    sqlwrite(conn, tablename, SupplementTable);
    disp(num2str(height(SupplementTable)) + " entries made, check database for consistency.")
end