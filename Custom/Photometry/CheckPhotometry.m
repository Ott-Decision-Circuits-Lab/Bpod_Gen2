function CheckPhotometry(PhotoData, Photo2Data)

global BpodSystem
global TaskParameters


thismax=max(PhotoData(TaskParameters.GUI.NidaqSamplingRate:TaskParameters.GUI.NidaqSamplingRate*2,1))
if thismax>4 || thismax<0.3
    disp('WARNING - Something is wrong with fiber #1 - run check-up! - unpause to ignore')
    BpodSystem.Pause=1;
    HandlePauseCondition;
end
if TaskParameters.GUI.DbleFibers
thismax=max(Photo2Data(TaskParameters.GUI.NidaqSamplingRate:TaskParameters.GUI.NidaqSamplingRate*2,1))
if thismax>4 || thismax<0.3
    disp('WARNING - Something is wrong with fiber #2 - run check-up! - unpause to ignore')
    BpodSystem.Pause=1;
    HandlePauseCondition;
end
end


end