function [Player, fs] = SetupWavePlayer(ChannelNumber)
%{
Setup for BpodWavePlayer to produce sounds.

See also: https://sites.google.com/site/bpoddocumentation/user-guide/function-reference/bpodwaveplayer

Author: gregory@bccn-berlin.de

2022-10-20: by Antonio Lee, adjust setup to be in TriggerProfile mode
%}

global BpodSystem

% Use max (8 Channels: 25kHz; 4 Channels: 50kHz; 2 Channels: 100kHz)
if nargin < 1
    ChannelNumber = 2; % default if no input
end

if ChannelNumber <= 2
    fs = 100000;
elseif ChannelNumber <= 4
    fs = 50000;
elseif ChannelNumber <= 8
    fs = 25000;
else
    error('Error: The input ChannelNumber is larger than the supported configuration. Please correct the protocol.')
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
BpodSystem.assertModule('WavePlayer', 1); % The second argument (1) indicates that the HiFi module must be paired with its USB serial port

% Instantiate BpodWavePlayer object
Player = BpodWavePlayer(BpodSystem.ModuleUSB.WavePlayer1);
Player.Port  % Prints the port to the Command Window

Player.SamplingRate = fs;
Player.BpodEvents(:) = {'Off'};
Player.BpodEvents(1:ChannelNumber) = {'On'}; % regardless of channel size, first two turn on
%{
% TriggerMode describes the response to a trigger event 
if playback is in progress: 
 -Master = Replace waveform
 -Normal = Ignore trigger
 -Toggle = Stop playback
%}
Player.TriggerMode = 'Master'; 
Player.OutputRange = '-5V:5V';
Player.TriggerProfileEnable = 'On';
BpodSystem.Data.Custom.SessionMeta.AOModule = true;
end % SetupWavePlayer