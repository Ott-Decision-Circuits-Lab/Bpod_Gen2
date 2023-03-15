function Sound = GetFreqStimulus(time)
StimulusSettings=struct();

StimulusSettings.SamplingRate = 192000; % Sound card sampling rate;
StimulusSettings.ramp = 0.003;
StimulusSettings.nFreq = 18; % Number of different frequencies to sample from
StimulusSettings.ToneOverlap = 0.6667;
StimulusSettings.ToneDuration = 0.03;
StimulusSettings.Noevidence=0;
StimulusSettings.minFreq = 5000 ;
StimulusSettings.maxFreq = 40000 ;
StimulusSettings.UseMiddleOctave=0;
StimulusSettings.Volume=50;
StimulusSettings.nTones = floor((time-StimulusSettings.ToneDuration*StimulusSettings.ToneOverlap)/(StimulusSettings.ToneDuration*(1-StimulusSettings.ToneOverlap))); %number of tones

newFracHigh = rand(1,1);
[Sound, ~, ~] = GenerateToneCloudDual(newFracHigh, StimulusSettings);

end