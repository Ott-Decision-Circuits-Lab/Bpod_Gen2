function ClickTrain = GenerateRegularClickTrain(ClickRate, Duration, SamplingRate, ClickLength)
% ClickTrain = a vector of relative amplitude of a click train
% ClickRate = mean click rate in Hz
% Duration = click train duration in seconds
% SamplingRate = sampling rate of the analogue module, in Hz
% ClickLength = how many frame does a click occupy


if nargin<4
    ClickLength = 1;
end
if nargin<3
    SamplingRate = 25000; % in Hz
end
if nargin<2
    Duration = 1; % in seconds
end

ClickTime = zeros(1,round(ClickRate*Duration*2)); % in sampling frame scale

N = 1;
ClickTime(N) = 1; % "starting" click to indicate the start of stimuli

%--------------------------------------------------------------------------
% make sure last click fit within the duration, e.g. duration 500, click
% length 2, then ClickTime at 499th should still be accepted, but not 500th
%--------------------------------------------------------------------------
while ClickTime(N) <= SamplingRate*Duration - ClickLength +1
    N = N+1;
    next_t_in = SamplingRate ./ ClickRate;
    ClickTime(N) = ClickTime(N-1) + next_t_in;
end
ClickTime = ClickTime(1:N-1); % Remove unallocate slots and the last one larger than duration

ClickTrain = zeros(1, SamplingRate*Duration);
for i = 1:ClickLength
    ClickTrain(ClickTime + i-1) = 1;
end

end