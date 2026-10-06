function pf = DetectPokeFailures(SessionData, trialIdx, params)
% DetectPokeFailures  Retroactively flag trials affected by nose-poke sensor failures.
%
%   pf = DetectPokeFailures(SessionData)
%   pf = DetectPokeFailures(SessionData, trialIdx)
%   pf = DetectPokeFailures(SessionData, trialIdx, params)
%
% Works on any Bpod protocol: it only uses SessionData.RawEvents (PortNIn /
% PortNOut events), TrialStartTimestamp / TrialEndTimestamp and
% SettingsFile.GUI.Ports_LMR (only for labelling). Detection always runs on
% the WHOLE session (so an episode that starts before trialIdx is still seen);
% per-trial outputs are then returned for trialIdx only.
%
% FAILURE MODES
%   Mode 1 (dead / silent port): the port registers no events at all for many
%       consecutive trials while the rat is active on the other ports.
%   Mode 2 (stuck "in"): the port reports a continuous "in" while the rat
%       makes a complete poke (In and Out) in another port (physically
%       impossible), or one continuous bout lasts longer than
%       params.maxBoutDuration. Once stuck, Bpod sees no further events from
%       that port, so the episode is extended until the port's next event.
%   Mode 3 (flicker): repeated In/Out transitions faster than
%       params.flickerMaxInterval, in several trials close together.
%
% IMPORTANT: Bpod records nothing in the ~1-2 s gap between trials, so port
%   events are often lost at trial boundaries. Durations are therefore only
%   measured WITHIN a trial; nothing is stitched across trial boundaries.
%
% INPUTS
%   SessionData : Bpod SessionData struct
%   trialIdx    : trials to return flags for (default 1:nTrials), e.g.
%                 firstTrialIdx:lastTrialIdx in LoadSingleSessionVars
%   params      : struct overriding any default below (see "Defaults")
%
% OUTPUT (struct pf)
%   pf.exclude    1 x numel(trialIdx) logical, true = trial lies in a
%                 poke-failure episode on any port
%   pf.mode1/2/3  3 x numel(trialIdx) logical, row k = Port k, trials that
%                 directly met each mode's criterion (before merging)
%   pf.episodes   struct array, one element per episode: port, physicalSide,
%                 logicalSide, firstTrial, lastTrial (ABSOLUTE trial numbers),
%                 nTrials, modes, evidence
%   pf.trial      per-trial features for ALL trials (3 x nTrialsAll each)
%   pf.portMap, pf.params, pf.trialIdx, pf.summary (one-line text)
%
% Use PlotPokeFailures(SessionData, pf) to inspect the result visually.
%
% E. Lonergan / Ott lab, HU Berlin. Written with Claude, Oct 2026.

%% Defaults
defaults = struct( ...
    'ports',                 [1 2 3], ... % hardware ports to check (Port1 = left, Port2 = centre, Port3 = right)
    'physicalSide',          {{'left', 'centre', 'right'}}, ... % physical position of Port1..Port3
    'intrusionLead',         0.5, ...  % s a port must already be "in" before another port's In counts as impossible
    'minIntrusionDuration',  0.02, ... % s minimum duration of the intruding poke (ignores flicker blips)
    'maxBoutDuration',       20, ...   % s single within-trial bout longer than this = stuck
    'silenceMinActiveTrials', 20, ...  % mode 1: >= this many consecutive ACTIVE trials with no event on the port
    'flickerMaxInterval',    0.005, ...% s transitions closer than this count as "fast"
    'flickerMinTransitions', 3, ...    % a trial with >= this many fast transitions is a flicker trial
    'flickerMinTrials',      3, ...    % mode 3: >= this many flicker trials ...
    'flickerWindow',         10, ...   % ... within this many consecutive trials
    'mergeGap',              5, ...    % merge flagged trials on the same port separated by <= this many trials
    'padTrials',             0, ...    % extra trials excluded before/after each episode
    'verbose',               true);

if nargin < 3 || isempty(params)
    params = struct();
end
p = defaults;
fn = fieldnames(params);
for i = 1:numel(fn)
    if ~isfield(defaults, fn{i})
        warning('DetectPokeFailures:unknownParam', 'Unknown parameter "%s" ignored.', fn{i});
    else
        p.(fn{i}) = params.(fn{i});
    end
end

%% Session basics
rawTrials = SessionData.RawEvents.Trial;
nAll = numel(rawTrials);
if isfield(SessionData, 'TrialEndTimestamp') && isfield(SessionData, 'TrialStartTimestamp')
    nTs = min([nAll, numel(SessionData.TrialStartTimestamp), numel(SessionData.TrialEndTimestamp)]);
    trialDur = nan(1, nAll);
    trialDur(1:nTs) = SessionData.TrialEndTimestamp(1:nTs) - SessionData.TrialStartTimestamp(1:nTs);
else
    trialDur = nan(1, nAll);
end
if nargin < 2 || isempty(trialIdx)
    trialIdx = 1:nAll;
end
trialIdx = trialIdx(:)';
if any(trialIdx < 1 | trialIdx > nAll)
    error('DetectPokeFailures:trialIdx', 'trialIdx must lie within 1..%d.', nAll);
end

portMap = getPortMap(SessionData);
allPorts = 1:3;

%% A. Per-trial, per-port features (within-trial only)
hasEvents  = false(3, nAll);   % any In or Out on this port in this trial
nFast      = zeros(3, nAll);   % transitions closer than flickerMaxInterval
nIntrusion = zeros(3, nAll);   % other-port pokes that started while this port was "in"
longBout   = false(3, nAll);   % a within-trial bout >= maxBoutDuration
endsIn     = false(3, nAll);   % port is "in" at the end of the trial
maxBout    = zeros(3, nAll);   % longest within-trial bout (s)
stuckAtEnd = false(3, nAll);   % a flagged (intruded or overlong) bout is still open at trial end

for n = 1:nAll
    ev = rawTrials{n}.Events;
    tEnd = trialDur(n);
    iv = cell(1, 3); carry = cell(1, 3); isOpen = cell(1, 3);
    % Last event time as a fallback trial end
    if isnan(tEnd)
        tEnd = lastEventTime(ev);
    end
    for k = allPorts
        inT  = getEventTimes(ev, sprintf('Port%dIn', k));
        outT = getEventTimes(ev, sprintf('Port%dOut', k));
        hasEvents(k, n) = ~isempty(inT) || ~isempty(outT);
        allT = sort([inT, outT]);
        nFast(k, n) = sum(diff(allT) < p.flickerMaxInterval);
        [iv{k}, carry{k}, isOpen{k}] = getIntervals(inT, outT, tEnd);
        if ~isempty(iv{k})
            d = iv{k}(:, 2) - iv{k}(:, 1);
            maxBout(k, n) = max(d);
            longBout(k, n) = any(d >= p.maxBoutDuration);
            endsIn(k, n) = isOpen{k}(end);
        end
    end
    % Impossible overlaps: while port k reports a continuous "in" (for >= intrusionLead already),
    % the rat makes a COMPLETE poke (In and Out) in another port. Partial overlaps are ignored:
    % the centre port often reads "in" for a few hundred ms after the rat has reached a side port.
    for k = allPorts
        for b = 1:size(iv{k}, 1)
            s0 = iv{k}(b, 1); s1 = iv{k}(b, 2);
            nHit = 0;
            for q = setdiff(allPorts, k)
                if isempty(iv{q}), continue; end
                qs = iv{q}(:, 1); qe = iv{q}(:, 2); qd = qe - qs;
                hit = ~carry{q} & ~isOpen{q} & qs > s0 + p.intrusionLead & qe < s1 & qd >= p.minIntrusionDuration;
                nHit = nHit + sum(hit);
            end
            nIntrusion(k, n) = nIntrusion(k, n) + nHit;
            % A flagged bout that is still open at trial end means the port may stay stuck
            if isOpen{k}(b) && (nHit > 0 || (s1 - s0) >= p.maxBoutDuration)
                stuckAtEnd(k, n) = true;
            end
        end
    end
end

%% B. Detectors
mode1 = false(3, nAll); mode2 = false(3, nAll); mode3 = false(3, nAll);
flickerTrial = nFast >= p.flickerMinTransitions;
mode2Onset = (nIntrusion > 0) | longBout;
evidence = cell(3, 1);

for k = p.ports
    evid = {};
    others = setdiff(allPorts, k);
    active = any(hasEvents(others, :), 1); % rat did something on another port

    % --- Mode 1: long silent runs (counted in active trials)
    n = 1;
    while n <= nAll
        if ~hasEvents(k, n)
            runStart = n;
            while n <= nAll && ~hasEvents(k, n)
                n = n + 1;
            end
            runEnd = n - 1;
            nActive = sum(active(runStart:runEnd));
            if nActive >= p.silenceMinActiveTrials
                mode1(k, runStart:runEnd) = true;
                prevWithEvents = find(hasEvents(k, 1:runStart-1), 1, 'last');
                if isempty(prevWithEvents)
                    lastState = 'unknown';
                elseif endsIn(k, prevWithEvents)
                    lastState = 'last state "in" (stuck)';
                else
                    lastState = 'last state "out" (dead/blocked)';
                end
                evid{end+1} = sprintf('mode1: silent T%d-T%d (%d active trials, %s)', ...
                    runStart, runEnd, nActive, lastState); %#ok<AGROW>
            end
        else
            n = n + 1;
        end
    end

    % --- Mode 2: impossible overlap or overlong bout; extend while the port stays stuck
    for n0 = find(mode2Onset(k, :))
        mode2(k, n0) = true;
        lastT = n0;
        if stuckAtEnd(k, n0)
            m = n0 + 1;
            while m <= nAll && ~hasEvents(k, m)
                m = m + 1;
            end
            lastT = min(m, nAll); % first trial with an event again (the release)
            mode2(k, n0:lastT) = true;
        end
        evid{end+1} = sprintf('mode2: onset T%d (%d intrusions, longest bout %.1f s), stuck until T%d', ...
            n0, nIntrusion(k, n0), maxBout(k, n0), lastT); %#ok<AGROW>
    end

    % --- Mode 3: dense flicker
    f = find(flickerTrial(k, :));
    m = p.flickerMinTrials;
    for i = 1:(numel(f) - m + 1)
        if f(i + m - 1) - f(i) + 1 <= p.flickerWindow
            mode3(k, f(i):f(i + m - 1)) = true;
        end
    end
    if any(mode3(k, :))
        evid{end+1} = sprintf('mode3: dense flicker in T%s', rangesToStr(find(mode3(k, :) & flickerTrial(k, :)))); %#ok<AGROW>
    end
    evidence{k} = evid;
end

%% C. Build episodes per port
inEpisode = false(3, nAll);
episodes = struct('port', {}, 'physicalSide', {}, 'logicalSide', {}, 'firstTrial', {}, ...
    'lastTrial', {}, 'nTrials', {}, 'modes', {}, 'evidence', {});

for k = p.ports
    seed = mode1(k, :) | mode2(k, :) | mode3(k, :);
    if ~any(seed), continue; end

    % Attach isolated flicker trials that sit close to another flagged stretch
    changed = true;
    while changed
        changed = false;
        seedIdx = find(seed);
        for t = find(flickerTrial(k, :) & ~seed)
            if min(abs(seedIdx - t)) <= p.mergeGap
                seed(t) = true; changed = true;
            end
        end
    end

    % Fill small gaps
    idx = find(seed);
    gaps = diff(idx) - 1;
    for j = find(gaps > 0 & gaps <= p.mergeGap)
        seed(idx(j):idx(j+1)) = true;
    end

    % Pad
    if p.padTrials > 0
        idx = find(seed);
        for t = idx
            seed(max(1, t - p.padTrials):min(nAll, t + p.padTrials)) = true;
        end
    end
    inEpisode(k, :) = seed;

    % Segments -> episodes
    d = diff([false, seed, false]);
    starts = find(d == 1); ends = find(d == -1) - 1;
    for s = 1:numel(starts)
        tr = starts(s):ends(s);
        modes = {};
        if any(mode1(k, tr)), modes{end+1} = '1'; end %#ok<AGROW>
        if any(mode2(k, tr)), modes{end+1} = '2'; end %#ok<AGROW>
        if any(mode3(k, tr) | flickerTrial(k, tr)), modes{end+1} = '3'; end %#ok<AGROW>
        evid = evidence{k};
        keep = false(1, numel(evid));
        for e = 1:numel(evid)
            nums = sscanf(regexprep(evid{e}, '^[^T]*T', ''), '%d', 1); % first trial number in the string
            keep(e) = ~isempty(nums) && nums >= starts(s) && nums <= ends(s);
        end
        fl = find(flickerTrial(k, tr)) + starts(s) - 1;
        evidStr = strjoin(evid(keep), '; ');
        if ~isempty(fl)
            evidStr = strtrim(sprintf('%s; flicker trials T%s', evidStr, rangesToStr(fl)));
            evidStr = regexprep(evidStr, '^; ', '');
        end
        episodes(end+1) = struct( ...
            'port', k, ...
            'physicalSide', p.physicalSide{k}, ...
            'logicalSide', portMap.logicalSide{k}, ...
            'firstTrial', starts(s), ...
            'lastTrial', ends(s), ...
            'nTrials', numel(tr), ...
            'modes', strjoin(modes, ','), ...
            'evidence', evidStr); %#ok<AGROW>
    end
end

%% D. Outputs restricted to trialIdx
pf = struct();
pf.trialIdx = trialIdx;
pf.exclude  = any(inEpisode(:, trialIdx), 1);
pf.mode1    = mode1(:, trialIdx);
pf.mode2    = mode2(:, trialIdx);
pf.mode3    = mode3(:, trialIdx);
pf.episodes = episodes;
pf.trial = struct('hasEvents', hasEvents, 'nFast', nFast, 'nIntrusion', nIntrusion, ...
    'longBout', longBout, 'maxBout', maxBout, 'endsIn', endsIn, 'stuckAtEnd', stuckAtEnd, ...
    'flickerTrial', flickerTrial, 'inEpisode', inEpisode);
pf.portMap = portMap;
pf.params  = p;
pf.nExcluded = sum(pf.exclude);

% One-line summary
sessionLabel = getSessionLabel(SessionData);
if isempty(episodes)
    pf.summary = sprintf('%s: no poke failures detected.', sessionLabel);
else
    parts = cell(1, numel(episodes));
    for e = 1:numel(episodes)
        parts{e} = sprintf('Port%d (%s, logical %s) T%d-T%d [mode %s]', episodes(e).port, ...
            episodes(e).physicalSide, episodes(e).logicalSide, episodes(e).firstTrial, ...
            episodes(e).lastTrial, episodes(e).modes);
    end
    pf.summary = sprintf('%s: %d poke-failure episode(s): %s. %d of %d analysed trials excluded.', ...
        sessionLabel, numel(episodes), strjoin(parts, '; '), pf.nExcluded, numel(trialIdx));
end
if p.verbose && ~isempty(episodes)
    fprintf('%s\n', pf.summary);
end
end

%% ===================== Helper functions =====================

function t = getEventTimes(ev, name)
% Event times as a row vector without NaNs ([] if the event never happened)
if isfield(ev, name)
    t = double(ev.(name)(:)');
    t = t(~isnan(t));
else
    t = [];
end
end

function t = lastEventTime(ev)
t = 0;
f = fieldnames(ev);
for i = 1:numel(f)
    v = double(ev.(f{i})(:));
    v = v(~isnan(v));
    if ~isempty(v), t = max(t, max(v)); end
end
end

function [iv, isCarry, isOpen] = getIntervals(inT, outT, tEnd)
% Within-trial "in" intervals for one port.
%   A leading Out means the port was already "in" at trial start -> interval starts at 0 (carry-over).
%   An In without a later Out means the port is still "in" at trial end -> interval ends at tEnd.
%   Repeated In without Out keeps the earliest In.
iv = zeros(0, 2); isCarry = false(0, 1); isOpen = false(0, 1);
if isempty(inT) && isempty(outT), return; end
times = [outT, inT];
types = [zeros(1, numel(outT)), ones(1, numel(inT))]; % on ties, Out sorts before In
[times, order] = sort(times);
types = types(order);
startT = NaN; carry = false;
if types(1) == 0
    startT = 0; carry = true;
end
for i = 1:numel(times)
    if types(i) == 1
        if isnan(startT)
            startT = times(i); carry = false;
        end
    else
        if ~isnan(startT)
            iv(end+1, :) = [startT, times(i)]; %#ok<AGROW>
            isCarry(end+1, 1) = carry; isOpen(end+1, 1) = false; %#ok<AGROW>
            startT = NaN; carry = false;
        end
    end
end
if ~isnan(startT)
    iv(end+1, :) = [startT, max(tEnd, startT)];
    isCarry(end+1, 1) = carry; isOpen(end+1, 1) = true;
end
end

function portMap = getPortMap(SessionData)
% Map hardware ports to the protocol's logical L/M/R using Ports_LMR (e.g. 123 or 321)
portMap = struct('Ports_LMR', '123', 'L', 1, 'M', 2, 'R', 3, 'logicalSide', {{'L', 'M', 'R'}});
try
    v = SessionData.SettingsFile.GUI.Ports_LMR;
    if isnumeric(v)
        s = sprintf('%d', round(v));
    else
        s = char(v);
    end
    s = s(isstrprop(s, 'digit'));
    if numel(s) == 3 && all(ismember(s, '123')) && numel(unique(s)) == 3
        portMap.Ports_LMR = s;
        portMap.L = str2double(s(1)); portMap.M = str2double(s(2)); portMap.R = str2double(s(3));
        lab = {'L', 'M', 'R'};
        for k = 1:3
            portMap.logicalSide{k} = lab{s == sprintf('%d', k)};
        end
    else
        warning('DetectPokeFailures:Ports_LMR', 'Unrecognised Ports_LMR "%s"; assuming 123.', s);
    end
catch
    warning('DetectPokeFailures:Ports_LMR', 'No SettingsFile.GUI.Ports_LMR found; assuming 123.');
end
end

function s = rangesToStr(t)
% [12 13 14 20] -> '12-14,20'
if isempty(t), s = ''; return; end
t = unique(t);
d = diff([t(1) - 2, t]);
starts = t(d ~= 1);
parts = {};
for i = 1:numel(starts)
    j = starts(i);
    e = j;
    while ismember(e + 1, t), e = e + 1; end
    if e > j
        parts{end+1} = sprintf('%d-%d', j, e); %#ok<AGROW>
    else
        parts{end+1} = sprintf('%d', j); %#ok<AGROW>
    end
end
s = strjoin(parts, ',');
end

function label = getSessionLabel(SessionData)
label = 'Session';
try
    subj = char(SessionData.Info.Subject);
    date = char(SessionData.Info.SessionDate);
    label = sprintf('Rat %s, %s', subj, date);
catch
end
end
