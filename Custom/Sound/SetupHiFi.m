function [Player,fs] = SetupHiFi(fs)
%{
Setup for BpodHiFi to produce sounds.

See also: https://sites.google.com/site/bpoddocumentation/user-guide/function-reference/bpodwaveplayer

Based on greg@bccn-berlin.de 's SetupWavePlayer(fs)

Author: antonio@bccn-berlin.de 2023-01-10

%}

global BpodSystem

if nargin < 1
    fs = 192000;
end

%{
---------------------------------------------------------------------------
                                SETUP
---------------------------------------------------------------------------
You will need:
- A Bpod state machine v0.7+
- A Bpod HiFi module, loaded with Bpod BpodWavePlayer firmware.

- Connect the HiFi module's State Machine port to Bpod.
- Connect channel 1 (or ch1+2) of the analog output module to speaker(s).
- Plug in the HiFi module to the computer via USB and start Bpod
  in Matlab.  From the Bpod console, pfsair the serial port (left) module 
  with its USB serial port (right).
%}

%--------------------------------------------------------------------------
% Instantiate waveplayer and set parameters
%--------------------------------------------------------------------------
% Check that the HiFi Module hardware has been assigned a USB port
BpodSystem.assertModule('HiFi', 1); % The second argument (1) indicates that the HiFi module must be paired with its USB serial port

% Instantiate BpodWavePlayer object
Player = BpodHiFi(BpodSystem.ModuleUSB.HiFi1);
Player.Port  % Prints the port to the Command Window

Player.DigitalAttenuation_dB = -10;
Player.SamplingRate = fs; %fs = 192000 % Use max (192kHz) supported sampling rate (fs = sampling freq)
BpodSystem.Data.Custom.SessionMeta.HiFiModule = true;
end % SetupWavePlayer