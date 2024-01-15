function Sound = GenerateRiskCue(SamplingRate, StimulusTime, mode, varargin)
% This function uses a start and end frequencies to generate a waveform of
% sweep, with the duration based on SamplingRate and StimulusTime
% 
% Sound = a vector of waveform [-1,1]
% SamplingRate (in Hz) = Analog (usually 50kHz) or HiFi (usually 192kHz) Module's Sampling Rate
% StimulusTime (in s) = the length of the tone duration
% mode = a string of the style of cue generated
% Created by antonio@bccn-berlin.de 2023-01-11

switch mode
    case 'Freq'
        % varargin{1} in mode 'Freq' = StartFreq (in kHz) = The freqency of sine wave in the beginning of the waveform
        % varargin{2} in mode 'Freq' = EndFreq (in kHz) = The freqency of sine wave in the end of the waveform
        
        StartFreq = varargin{1}*1000;
        EndFreq = varargin{2}*1000;
        t = 0:(1/SamplingRate):StimulusTime;
        if StartFreq == EndFreq
            mode = 'linear';
        else
            mode = 'logarithmic';
        end
        Sound = chirp(t, StartFreq, StimulusTime, EndFreq, mode);
        
end

end