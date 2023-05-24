function WriteEphysDataToDatabase()
%{
Function to register in the database's husbandry log
that a procedure was undertaken.

Author: Greg Knoll
Date: October 12, 2022
%}

global BpodSystem
global TaskParameters

if sum(strcmp(fieldnames(TaskParameters.GUI), 'EphysSession')) == 1 && TaskParameters.GUI.EphysSession

    try
        conn = ConnectToSQL();
    catch
        warning('Unable to connect to ott_lab database: Ephys data not saved to database!')
        return
    end
    
    tablename = "ephys_experiment";
    
    try
        Info = BpodSystem.Data.Info;
    catch
        warning('BpodSystem Info not found. Ephys data not saved to database!')
        close(conn)
        return
    end

    try
        [filepath, name, ext] = fileparts(BpodSystem.Path.CurrentDataFile);
    catch
        warning('CurrentDataFile not found. Session info not saved to database!')
        close(conn)
        return
    end
    
    try
        ephys_info.bpod_experiment_id = string(strcat(name, ext));
        
        ephys_info.rat_id = str2num(Info.Subject);
        if Info.Subject == "FakeSubject"  % For testing
            % clear ephys_info;
            ephys_info.rat_id = -1;
        elseif isempty(ephys_info.rat_id)
            ephys_info.rat_id = -2;
        end
        
        
        
        protocol = BpodSystem.GUIData.ProtocolName;

        if protocol == 'DiscriminationConfidence'
            if TaskParameters.GUI.FeedbackDelaySelection == 1  % reward-bias task
               ephys_info.task = "reward-bias";
            elseif TaskParameters.GUI.FeedbackDelaySelection == 3 % time-investment task
               ephys_info.task = "time-investment";
            end
        elseif protocol == 'TwoArmBanditVariant'
            ephys_info.task = 'matching';
        end

        ephys_info.results_file_path = string(strcat('\\ottlabfs.bccn-berlin.pri\ottlab\data\', Info.Subject, '\ephys\'));

        ephys_info_table = struct2table(ephys_info);
    catch
        warning('Error in creating ephys table.')
        close(conn)
        return
    end
    
    try
        sqlwrite(conn, tablename, ephys_info_table)
    catch
        warning('Error writing to ephys_experiment.')
        close(conn)
        return
    end
    
    close(conn)
    disp('-> Ephys data written to database.')
end % If Ephys
end