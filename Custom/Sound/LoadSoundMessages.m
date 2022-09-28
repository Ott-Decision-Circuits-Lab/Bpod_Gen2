function LoadSoundMessages(SoundChannels)

global BpodSystem

%{
---------------------------------------------------------------------------
                 Set up Bpod serial message library 
---------------------------------------------------------------------------
 (see
 https://sites.google.com/site/bpoddocumentation/user-guide/
                           function-reference/waveplayerserialinterface)
 sets correct codes to trigger sounds 1-4 on analog output channels 1-2

'P' (ASCII 80): Plays a waveform. 

    In standard trigger mode (default), 'P' (Byte 0) must be followed by two bytes:
        Byte 1: A byte whose bits indicate which channels to trigger (i.e. byte 5 = bits: 00000101 = channels 1 and 3). 
        Byte 2: A byte indicating the waveform to play on the channels specified by Byte 1 (zero-indexed).

    In trigger profile mode, 'P' (Byte 0) must be followed by 1 byte:
        Byte 1: The trigger profile to play (1-64)
%}
analogPortIndex = find(strcmp(BpodSystem.Modules.Name, 'WavePlayer1'));
if isempty(analogPortIndex)
    error('Error: Bpod WavePlayer module not found. If you just plugged it in, please restart Bpod.')
end
playMessages = {};
for i=1:size(SoundChannels,2)
    i
    playMessages{i} = ['P', SoundChannels(i), i-1];
end
LoadSerialMessages('WavePlayer1', playMessages);  




end %LoadSoundMessages