% This script goes through the database and adds "supplement" to each day
% where rats have consumed less than 9 mL. 
% Eric Lonergan, 2022

% Database fields. Enter your data accordingly.

%rat_id = [50, 51, 52, 53]; % Must be run for each cage separately
rat_id = [32];
cage_number = 7;
water_scheduling = 'supplement'; % String to be added in water_scheduling column
reported_by = 'Eric Lonergan'; % Caretaker
license = 'G0011/22';
min_water = 9000; % Define the minimum amount of water rats should consume in µL

for i = 1:length(rat_id)
    % Define a fixed time of supplementation for each rat based on the rat_id
    base_time = datetime('19:00:00');
    time_of_supplement = base_time + seconds(rat_id(i));
    time_of_supplement_string = datestr(time_of_supplement, 'HH:MM:SS');
    
    % Connect to the PostgreSQL database
    conn = ConnectToSQL();
    
    query = ['SELECT "timestamp", rat_id, experimental_treatment, water_scheduling ' ...
             'FROM public.husbandry_log ' ...
             'WHERE rat_id = ' , num2str(rat_id(i))];
    
    data = fetch(conn, query); % Table queried from database
    data = sortrows(data, "timestamp", "ascend"); % Makes checks easier
    
    % Get start and end dates of water restriction periods
    start_indices = find(data.water_scheduling == "start");
    end_indices = find(data.water_scheduling == "end");
    
    % Allow for a mismatch in start and end events
    if length(start_indices) > length(end_indices)
        % Add the current date as a provisional end date
        end_indices = [end_indices; height(data) + 1];
        data = [data; table(datetime('now'), rat_id(i), {''}, {''}, 'VariableNames', {'timestamp', 'rat_id', 'experimental_treatment', 'water_scheduling'})];
    end
    
    % Create a list of all dates within the water restriction periods
    restricted_dates = [];
    for j = 1:length(start_indices)
        start_date = data.timestamp(start_indices(j));
        end_date = data.timestamp(end_indices(j));
        period_dates = start_date:end_date;
        restricted_dates = [restricted_dates, period_dates];
    end
    
    % Remove duplicates
    restricted_dates = unique(restricted_dates);
    
    % Already Supplemented Table
    AST = data(data.water_scheduling == "supplement", :);
    AST.timestamp = datetime(year(AST.timestamp), month(AST.timestamp), day(AST.timestamp));
    
    % Table to be written to database
    SupplementTable = [];
    
    % Loop through each date in the restricted_dates
    for curr_date = restricted_dates
        curr_date = datetime(curr_date, 'Format', 'yyyy-MM-dd');
        curr_date = datetime(year(curr_date), month(curr_date), day(curr_date)); % required for comparison between datetimes
        dataTableDates = datetime(year(data.timestamp), month(data.timestamp), day(data.timestamp));
        
        % Get all records for the current date
        day_records = data(dataTableDates == curr_date, :);
        
        % If current date has a start or end event, no supplementation is needed, so skip
        if any(strcmp(day_records.water_scheduling, "start")) || any(strcmp(day_records.water_scheduling, "end"))
            continue
        end

        % Sum the water consumed on that day
        if isempty(day_records)
            total_water = 0;
        else
            day_records.water_scheduling_int = str2double(regexprep(day_records.water_scheduling, '[^\d]', ''));
            total_water = sum(day_records.water_scheduling_int, 'omitnan');
        end
        
        % Skip if 'supplement' entry already in the database for that particular day
        if ismember(curr_date, AST.timestamp)
            continue
        end
        
        % Check if the rats have consumed at least 9000 µL on current date
        if total_water >= min_water
            % Rats have consumed at least 9000 µL, no changes needed
            continue
        else
            % Rats have not consumed at least 9000 µL, requires "supplement"
            date_string = string(curr_date, 'yyyyMMdd');
            time_of_supplement_string_NoColon = regexprep(time_of_supplement_string, ':', '');
            timestamp = strcat(date_string, '_', time_of_supplement_string_NoColon);
            
            if isempty(SupplementTable) % Create table with data relevant to supplementation
                SupplementTable = table(timestamp, rat_id(i), cage_number, {license}, {water_scheduling}, {reported_by});
                SupplementTable.Properties.VariableNames = {'timestamp', 'rat_id', 'cage_number', 'license', 'water_scheduling', 'reported_by'};
            else % Table already exists -> append new values to table
                SupplementTable = [SupplementTable; {timestamp}, rat_id(i), cage_number, {license}, {water_scheduling}, {reported_by}];
            end
        end
    end
    
    % Check SupplementTable
    SupplementTable
    
    if isempty(SupplementTable)
        disp("All 'supplement' entries up to date, no additional entries made.")
    else
        % Write Supplement Table to database
        tablename = "husbandry_log";
        sqlwrite(conn, tablename, SupplementTable);
        disp(num2str(height(SupplementTable)) + " entries made, check database for consistency.")
    end
end
