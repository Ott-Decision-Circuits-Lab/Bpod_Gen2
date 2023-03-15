function InitiatePsychtoolbox()
global BpodSystem
global TaskParameters
if TaskParameters.GUI.PlayStimulus == 3 && ~BpodSystem.Data.Custom.SessionMeta.PsychtoolboxStartup
    PsychToolboxSoundServer('init');
    BpodSystem.Data.Custom.SessionMeta.PsychtoolboxStartup = true;
end