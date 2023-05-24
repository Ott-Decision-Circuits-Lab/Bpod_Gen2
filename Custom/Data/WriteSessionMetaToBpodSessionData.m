function WriteSessionMetaToBpodSessionData
% This function runs when a session is stopped and requires user to note
% down session meta of behavioural data and, if any, specific modules.
% First draft in 2023-05-08 by Antonio Lee antonio@bccn-berlin.de

global BpodSystem
global TaskParameters

try
    if isempty(BpodSystem) || ~isfield(BpodSystem.Data, 'Custom') || BpodSystem.EmulatorMode || isempty(TaskParameters)
        disp('-> Not an experimental session. No post-session questionaire is needed.')
        return
    end
catch
    disp('Error: Logic check. No SessionMeta will be written.')
    return
end

%% guideline
try
    Guideline = ['You have closed a session and are invited to insert the ', ...
                 'corresponding session metadata, including the behaviour part. ',...
                 'You may leave any field empty.'];
    
    BoxTitle = 'Guideline';
    Option1= 'Proceed';
    Option2 = 'Skip';
    Default = 'Proceed';
    
    Answer = questdlg(Guideline, BoxTitle, Option1, Option2, Default);
    
    if string(Answer) ~= string(Option1)
        return
    end
catch
    disp('Error: Metadata Guideline dialogue. No SessionMeta will be written.')
    return
end

%% behavioural session
try
    BehaviouralQuestions = {'All\bf behavioural\rm hardwares functional (t/f): ',...
                            'Any particular remarks: ',...
                            'Cage number?'};
    
    BoxTitle = 'Behavioural';
    Dims = [1 50; 1 50; 1 20];
    DefaultInput = {'t', '', '-1'};
    opts.Interpreter = 'tex';
    
    Answer = inputdlg(BehaviouralQuestions, BoxTitle, Dims, DefaultInput, opts);
    
    if isempty(Answer)
        Answer = DefaultInput;
    end
    
    BpodSystem.Data.Custom.SessionMeta.BehaviouralValidation = false;
    if ismember(cell2mat(Answer(1)), ['t', 'T', 'true', 'True', '1'])
        BpodSystem.Data.Custom.SessionMeta.BehaviouralValidation = true;
    end
    
    BpodSystem.Data.Custom.SessionMeta.BehaviouralRemarks = cell2mat(Answer(2));
    BpodSystem.Data.Custom.SessionMeta.CageNumber = cell2mat(Answer(3));
    disp('-> Writing behavioural metadata is successful')
catch
    disp('Error: Behavioural Metadata. No behavioural SessionMeta will be written.')
end

%% photometry-related meta
if isfield(TaskParameters.GUI, 'Photometry') && TaskParameters.GUI.Photometry
    PhotometryQuestions = ['All\bf photometry\rm setups functional (t/f)? ',...
                           'Any particular remarks: ',...
                           'Measured brain area: ',...
                           'Sensor on green channel: ' ...
                           'Pre-amplified voltage (V) on the green channel: ',...
                           'Sensor on red channel: ',...
                           'Pre-amplified voltage (V) on the red channel: '
                           'Patch cable ID: '];

    BoxTitle = 'Photometry';
    Dims = [1 50; 1 50; 1 20; 1 20; 1 50; 1 20; 1 50; 1 20];
    DefaultInput = {'t', '', '', '', '', 'tdTomato', '', 'T20230420'};
    opts.Interpreter = 'tex';

    Answer = inputdlg(PhotometryQuestions, BoxTitle, Dims, DefaultInput, opts);
    
    if isempty(Answer)
        Answer = DefaultInput;
    end
    
    BpodSystem.Data.Custom.SessionMeta.PhotometryValidation = false;
    if ismember(cell2mat(Answer(1)), ['t', 'T', 'true', 'True', '1'])
        BpodSystem.Data.Custom.SessionMeta.PhotometryValidation = true;
    end
    
    BpodSystem.Data.Custom.SessionMeta.PhotometryRemarks = cell2mat(Answer(2));
    BpodSystem.Data.Custom.SessionMeta.PhotometryBrainArea = cell2mat(Answer(3));
    
    BpodSystem.Data.Custom.SessionMeta.PhotometryGreenSensor = cell2mat(Answer(4));
    BpodSystem.Data.Custom.SessionMeta.PhotometryGreenAmp = cell2mat(Answer(5));
    
    BpodSystem.Data.Custom.SessionMeta.PhotometryRedSensor = cell2mat(Answer(6));
    BpodSystem.Data.Custom.SessionMeta.PhotometryRedAmp = cell2mat(Answer(7));
    
    BpodSystem.Data.Custom.SessionMeta.PhotometryPatchCableID = cell2mat(Answer(8));

    disp('-> Writing photometry metadata is successful')
end

%% Ephys-related meta
if isfield(TaskParameters.GUI, 'EphysSession') && TaskParameters.GUI.EphysSession
    EphysQuestions = ['All\bf ephys\rm setups functional (t/f)? ',...
                      'Any particular remarks: ',...
                      'Measured brain area: ',...
                      'Probe(s) type: '];
    
    BoxTitle = 'Electrophysiology';
    Dims = [1 50; 1 50; 1 20; 1 50];
    DefaultInput = {'t', '', '', 'Neuropixels 1.0'};
    opts.Interpreter = 'tex';

    Answer = inputdlg(EphysQuestions, BoxTitle, Dims, DefaultInput, opts);
    
    if isempty(Answer)
        Answer = DefaultInput;
    end
    
    BpodSystem.Data.Custom.SessionMeta.EphysValidation = false;
    if ismember(cell2mat(Answer(1)), ['t', 'T', 'true', 'True', '1'])
        BpodSystem.Data.Custom.SessionMeta.EphysValidation = true;
    end
    
    BpodSystem.Data.Custom.SessionMeta.EphysRemarks = cell2mat(Answer(2));
    BpodSystem.Data.Custom.SessionMeta.EphysBrainArea = cell2mat(Answer(3));
    BpodSystem.Data.Custom.SessionMeta.EphysProbe = cell2mat(Answer(4));

    disp('-> Writing ephys metadata is successful')
end

%% Pharm-related meta
if isfield(TaskParameters.GUI, 'PharmacologyOn') && TaskParameters.GUI.PharmacologyOn
    PharmQuestions = ['Weight of the animal: ',...
                      'Drug name: ',...
                      'Dosage (mg per kg rat): ',...
                      'Route of administration: '];

    BoxTitle = 'Pharmacology';
    Dims = [1 50; 1 50; 1 20; 1 50];
    DefaultInput = {'', 'psilocybin', '', 'i.p.'};
    opts.Interpreter = 'tex';

    Answer = inputdlg(PharmQuestions, BoxTitle, Dims, DefaultInput, opts);
    
    if isempty(Answer)
        Answer = DefaultInput;
    end
    
    BpodSystem.Data.Custom.SessionMeta.AnimalWeight = cell2mat(Answer(1));
    BpodSystem.Data.Custom.SessionMeta.AdministratedDrug = cell2mat(Answer(2));
    BpodSystem.Data.Custom.SessionMeta.AdministratedDosage = cell2mat(Answer(3));
    BpodSystem.Data.Custom.SessionMeta.AdministrationRoute = cell2mat(Answer(4));
    
    disp('-> Writing pharmacology metadata is successful')
end


end % end function