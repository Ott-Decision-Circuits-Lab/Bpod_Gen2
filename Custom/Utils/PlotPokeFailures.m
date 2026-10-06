function fig = PlotPokeFailures(SessionData, pf, trialRange, maxTime)
% PlotPokeFailures  Raster of port occupancy per trial, with detected poke-failure episodes shaded.
%
%   PlotPokeFailures(SessionData, pf)
%   PlotPokeFailures(SessionData, pf, trialRange)          e.g. 1:150
%   PlotPokeFailures(SessionData, pf, trialRange, maxTime) x-axis limit in s (default 20)
%
% One panel per port (Port1 = left, Port2 = centre, Port3 = right). Each row is
% a trial; black bars are "in" intervals within that trial (a bar starting at 0
% means the port was already "in" when the trial started). Red dots mark trials
% with fast (flicker) transitions, blue crosses mark impossible overlaps.
% Shaded rows are the episodes in pf.episodes.
%
% pf is the output of DetectPokeFailures(SessionData).

rawTrials = SessionData.RawEvents.Trial;
nAll = numel(rawTrials);
if nargin < 3 || isempty(trialRange), trialRange = 1:nAll; end
if nargin < 4 || isempty(maxTime), maxTime = 20; end
trialRange = trialRange(trialRange >= 1 & trialRange <= nAll);
trialDur = SessionData.TrialEndTimestamp - SessionData.TrialStartTimestamp;

fig = figure('Color', 'w', 'Name', 'Poke failures', 'Position', [100 100 1100 700]);
for k = 1:3
    ax = subplot(1, 3, k); hold(ax, 'on');

    % Episode shading
    for e = 1:numel(pf.episodes)
        ep = pf.episodes(e);
        if ep.port ~= k, continue; end
        y0 = ep.firstTrial - 0.5; y1 = ep.lastTrial + 0.5;
        patch(ax, [0 maxTime maxTime 0], [y0 y0 y1 y1], [1 0.8 0.8], 'EdgeColor', 'none');
    end

    % "In" intervals, drawn as one NaN-separated line for speed
    xs = []; ys = [];
    for n = trialRange
        ev = rawTrials{n}.Events;
        inT = evTimes(ev, sprintf('Port%dIn', k));
        outT = evTimes(ev, sprintf('Port%dOut', k));
        iv = intervals(inT, outT, trialDur(min(n, numel(trialDur))));
        for b = 1:size(iv, 1)
            xs = [xs, iv(b, 1), iv(b, 2), NaN]; %#ok<AGROW>
            ys = [ys, n, n, NaN]; %#ok<AGROW>
        end
    end
    if ~isempty(xs)
        plot(ax, xs, ys, 'k-', 'LineWidth', 2);
    end

    % Markers
    fl = trialRange(pf.trial.flickerTrial(k, trialRange));
    if ~isempty(fl), plot(ax, repmat(maxTime * 0.97, size(fl)), fl, 'r.', 'MarkerSize', 12); end
    ix = trialRange(pf.trial.nIntrusion(k, trialRange) > 0);
    if ~isempty(ix), plot(ax, repmat(maxTime * 0.93, size(ix)), ix, 'bx', 'MarkerSize', 6); end

    set(ax, 'YDir', 'reverse');
    xlim(ax, [0 maxTime]); ylim(ax, [min(trialRange) - 0.5, max(trialRange) + 0.5]);
    xlabel(ax, 'Time in trial (s)');
    if k == 1, ylabel(ax, 'Trial'); end
    title(ax, {sprintf('Port%d', k), sprintf('(%s, logical %s)', pf.params.physicalSide{k}, pf.portMap.logicalSide{k})});
end
% Title: summary on the first line, then nPerLine episodes per line
nPerLine = 3;
if isempty(pf.episodes)
    titleLines = {pf.summary};
else
    sessionLabel = strtok(pf.summary, ':');
    titleLines = {sprintf('%s: %d episode(s), %d of %d analysed trials excluded', ...
        sessionLabel, numel(pf.episodes), pf.nExcluded, numel(pf.trialIdx))};
    epStr = arrayfun(@(ep) sprintf('Port%d (%s) T%d-T%d [mode %s]', ep.port, ep.physicalSide, ...
        ep.firstTrial, ep.lastTrial, ep.modes), pf.episodes, 'UniformOutput', false);
    for i = 1:nPerLine:numel(epStr)
        titleLines{end+1} = strjoin(epStr(i:min(i + nPerLine - 1, numel(epStr))), ';   '); %#ok<AGROW>
    end
end
% Shrink the panels so the title lines don't overlap them
topEdge = 1 - (0.03 * numel(titleLines) + 0.08);
axList = findobj(fig, 'Type', 'axes');
for a = axList(:)'
    pos = get(a, 'Position');
    if pos(2) + pos(4) > topEdge
        set(a, 'Position', [pos(1), pos(2), pos(3), topEdge - pos(2)]);
    end
end
try
    sgtitle(titleLines, 'FontSize', 9, 'Interpreter', 'none');
catch % older MATLAB / Octave without sgtitle
    annotation('textbox', [0, topEdge + 0.06, 1, 0.94 - topEdge], 'String', titleLines, 'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'Interpreter', 'none', 'FontSize', 8);
end
end

function t = evTimes(ev, name)
if isfield(ev, name)
    t = double(ev.(name)(:)'); t = t(~isnan(t));
else
    t = [];
end
end

function iv = intervals(inT, outT, tEnd)
% Same convention as DetectPokeFailures: leading Out => "in" from 0; open In => "in" until tEnd
iv = zeros(0, 2);
if isempty(inT) && isempty(outT), return; end
times = [outT, inT]; types = [zeros(1, numel(outT)), ones(1, numel(inT))];
[times, o] = sort(times); types = types(o);
s = NaN;
if types(1) == 0, s = 0; end
for i = 1:numel(times)
    if types(i) == 1 && isnan(s)
        s = times(i);
    elseif types(i) == 0 && ~isnan(s)
        iv(end+1, :) = [s, times(i)]; s = NaN; %#ok<AGROW>
    end
end
if ~isnan(s), iv(end+1, :) = [s, max(tEnd, s)]; end
end
