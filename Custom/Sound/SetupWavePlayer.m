function [Player,fs]=SetupWavePlayer(fs)
%{
Setup for BpodWavePlayer to produce sounds.

See also: https://sites.google.com/site/bpoddocumentation/user-guide/function-reference/bpodwaveplayer

Author: gregory@bccn-berlin.de
%}

global BpodSystem

if nargin < 1
    fs = 25000;
end

%{
---------------------------------------------------------------------------
                                SETUP
---------------------------------------------------------------------------
You will need:
- A Bpod state machine v0.7+
- A Bpod analog output module, loaded with Bpod BpodWavePlayer firmware.

- Connect the analog output module's State Machine port to Bpod.
- Connect channel 1 (or ch1+2) of the analog output module to speaker(s).
- Plug in the analog otuput module to the computer via USB and start Bpod
  in Matlab.  From the Bpod console, pfsair the serial port (left) module 
  with its USB serial port (right).
%}

%--------------------------------------------------------------------------
% Instantiate waveplayer and set parameters
%--------------------------------------------------------------------------
% Check that the Analog Output Module hardware has been assigned a USB port
if (isfield(BpodSystem.ModuleUSB, 'WavePlayer1'))
    WavePlayerUSB = BpodSystem.ModuleUSB.WavePlayer1;
else
    error('Error: To run this protocol, you must first pair the Analog Output Module (hardware) with its USB port. Click the USB config button on the Bpod console.')
end

% Instantiate BpodWavePlayer object
Player = BpodWavePlayer(WavePlayerUSB);
Player.Port  % Prints the port to the Command Window

%fs = 25000 % Use max (25kHz; 50kHz if Channels 5-8 are disabled, see below) supported sampling rate (fs = sampling freq)
Player.SamplingRate = fs;
Player.BpodEvents = {'On', 'On', 'Off', 'Off', 'Off', 'Off', 'Off', 'Off'}; % for 8-channel hardware
%{
% TriggerMode describes the response to a trigger event 
if playback is in progress: 
 -Master = Replace waveform
 -Normal = Ignore trigger
 -Toggle = Stop playback
%}
Player.TriggerMode = 'Master'; 
Player.OutputRange = '-5V:5V';

end % SetupWavePlayer