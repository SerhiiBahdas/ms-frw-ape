% FIG3  The APE predicts the acceleration that a torque pulse at one joint
% produces at the other joint (intersegmental dynamics), shown for one
% perturbed test movement.
%
% Regenerates Figure 3 from the packaged data archive FIG3.zip (or the
% extracted folder FIG3), which must be in the same folder as this script.
%
% Left: joint accelerations over the whole movement. Right: the interval
% around the torque pulse, expanded in a grey frame with scale bars. The
% pulse was applied to one joint only, so the response of the other joint
% arises from inertial coupling.
%
% Tested with MATLAB R2026a. Requires the Arial font.
%
% Outputs, written beside this script:
%   FIG3.pdf, FIG3.svg, FIG3.png

close all; clear;

%% ------------------------- SETTINGS -------------------------
trial = 'move_8_to_6';          % movement packaged in FIG3.zip

here = fileparts(mfilename('fullpath'));
if isempty(here); here = pwd; end
outName = 'FIG3';

colAPE  = [178 24 43]/255;      % red
colRef  = [0 0 0];
colUnp  = [0.45 0.45 0.45];
colBand = [0.90 0.90 0.90];
colFrame = [0.55 0.55 0.55];
figW = 120/25.4; figH = 3.1;    % inches (1.5 columns, 120 mm)
fsLabel = 7; fsTick = 6;
dashStep = 10;                  % samples between points of a dashed line, so that vector output keeps the dashes
fontName = 'Arial';
if ~any(strcmp(listfonts, fontName)); warning('Font %s is not installed.', fontName); end
joints = {'shoulder','elbow'};
sup2 = char(178); sup3 = char(179);       % superscripts as single characters

%% ------------------------- LOAD -------------------------
[dataDir, isTemp] = unpackData(here, 'FIG3');
D = readtable(fullfile(dataDir, sprintf('fig3_%s.csv', trial)));
if isTemp; rmdir(dataDir, 's'); end
D = D(~any(ismissing(D), 2), :);        % samples present in all four simulations
r2d = 180/pi;
t     = D.time_s;
accU  = [D.qdd_sh_ref_unperturbed, D.qdd_el_ref_unperturbed] * r2d;   % unperturbed, physics engine
accP  = [D.qdd_sh_ref_perturbed,   D.qdd_el_ref_perturbed  ] * r2d;   % perturbed, physics engine
accA  = [D.qdd_sh_ape_perturbed,   D.qdd_el_ape_perturbed  ] * r2d;   % perturbed, APE
accA0 = [D.qdd_sh_ape_unperturbed, D.qdd_el_ape_unperturbed] * r2d;   % unperturbed, APE (printed summary only)

% Torque pulse: where the perturbed torque differs from the unperturbed one
dTau = [D.tau_sh_perturbed - D.tau_sh_unperturbed, D.tau_el_perturbed - D.tau_el_unperturbed];
[~, jPert] = max(max(abs(dTau), [], 1));
on = find(abs(dTau(:,jPert)) > 1e-9*max(abs(dTau(:,jPert))));
tPulse = t([on(1) on(end)]);
[~, kTau] = max(abs(dTau(:,jPert)));
fprintf('%s: torque pulse at the %s from %.3f to %.3f s, peak %+.2f N m\n', ...
    trial, joints{jPert}, tPulse, dTau(kTau,jPert));

% Response of each joint (perturbed minus unperturbed) at the peak of the
% physics-engine response; the APE response uses its own unperturbed run
win = on(1):on(end);
for j = 1:2
    dRef = accP(win,j) - accU(win,j);
    [~, k] = max(abs(dRef));
    fprintf('  %-8s response at %.3f s: physics engine %+.0f deg/s^2, APE %+.0f deg/s^2\n', ...
        joints{j}, t(win(k)), dRef(k), accA(win(k),j) - accA0(win(k),j));
end

%% ------------------------- FIGURE -------------------------
fig = figure('Units','inches', 'Position',[1 1 figW figH], 'Color','w', ...
    'PaperUnits','inches', 'PaperSize',[figW figH], 'PaperPosition',[0 0 figW figH]);

left = 0.115; widthL = 0.50; gapX = 0.075; widthR = 0.27;
bottom = 0.125; gapY = 0.085; top = 0.115;
height = (1 - bottom - top - gapY)/2;

[xLim, xTick] = niceAxis(0, t(end), 0.1);
pad = 0.4*diff(tPulse);
xZoom = [tPulse(1) - pad, tPulse(2) + pad];
inZoom = t >= xZoom(1) & t <= xZoom(2);
rowTitle = {'coupled response', 'response to the pulse'};
if jPert == 1; rowTitle = fliplr(rowTitle); end

axL = gobjects(1,2); axR = gobjects(1,2); zoomBox = zeros(2,4);
for j = 1:2                                   % rows: shoulder, elbow
    y0 = bottom + (2-j)*(height+gapY);

    % ---- whole movement ----
    axL(j) = axes(fig, 'Position', [left, y0, widthL, height]);
    ax = axL(j); hold(ax, 'on');
    allY = [accU(:,j); accP(:,j); accA(:,j)] / 1e3;
    [yLim, yTick] = niceAxis(min(allY), max(allY), 0.5);
    assert(all(allY >= yLim(1) & allY <= yLim(2)), 'A value lies outside the y axis.');
    patch(ax, tPulse([1 2 2 1]), yLim([1 1 2 2]), colBand, 'EdgeColor','none');
    plot(ax, xLim, [0 0], '-', 'Color',[0.75 0.75 0.75], 'LineWidth',0.4);
    plot(ax, t, accP(:,j)/1e3, '-',  'Color',colRef, 'LineWidth',1.5);
    k = [1:dashStep:numel(t), numel(t)];                 % dashed line from every 10th sample
    plot(ax, t(k), accU(k,j)/1e3, '--', 'Color',colUnp, 'LineWidth',0.9);
    plot(ax, t, accA(:,j)/1e3, '-',  'Color',colAPE, 'LineWidth',0.9);
    % the interval that is expanded on the right, with room for the scale
    % bars below the traces
    yz = [accU(inZoom,j); accP(inZoom,j); accA(inZoom,j)];
    yRange = max(yz) - min(yz);
    yZoom = [min(yz) - 0.55*yRange, max(yz) + 0.30*yRange];
    zoomBox(j,:) = [xZoom(1), yZoom(1)/1e3, diff(xZoom), diff(yZoom)/1e3];
    rectangle(ax, 'Position',zoomBox(j,:), 'EdgeColor',colFrame, 'LineWidth',0.5);
    set(ax, 'XLim',xLim, 'XTick',xTick, 'YLim',yLim, 'YTick',yTick, ...
        'TickDir','out', 'TickLength',[0.018 0.018], 'Box','off', 'LineWidth',0.5, ...
        'FontName',fontName, 'FontSize',fsTick, 'XColor','k', 'YColor','k', ...
        'Layer','top', 'Color','none', 'TickLabelInterpreter','none');
    ylabel(ax, sprintf('%s accel., 10%c deg/s%c', joints{j}, sup3, sup2), 'Interpreter','none', ...
        'FontName',fontName, 'FontSize',fsLabel, 'Color','k');
    if j == 1
        ax.XAxis.Visible = 'off';
        text(ax, mean(tPulse), yLim(2), sprintf('%s torque pulse', joints{jPert}), ...
            'FontName',fontName, 'FontSize',fsTick, 'Color',[0.4 0.4 0.4], ...
            'HorizontalAlignment','center', 'VerticalAlignment','bottom');
    else
        xlabel(ax, 'time, s', 'FontName',fontName, 'FontSize',fsLabel, 'Color','k');
    end

    % ---- expanded view ----
    axR(j) = axes(fig, 'Position', [left + widthL + gapX, y0, widthR, height]);
    ax = axR(j); hold(ax, 'on');
    patch(ax, tPulse([1 2 2 1]), yZoom([1 1 2 2]), colBand, 'EdgeColor','none');
    plot(ax, t(inZoom), accP(inZoom,j), '-',  'Color',colRef, 'LineWidth',1.5);
    kz = find(inZoom); kz = kz([1:dashStep:numel(kz), numel(kz)]);
    plot(ax, t(kz), accU(kz,j), '--', 'Color',colUnp, 'LineWidth',0.9);
    plot(ax, t(inZoom), accA(inZoom,j), '-',  'Color',colAPE, 'LineWidth',0.9);
    set(ax, 'XLim',xZoom, 'YLim',yZoom, 'XTick',[], 'YTick',[], 'Box','on', ...
        'XColor',colFrame, 'YColor',colFrame, 'LineWidth',0.75, 'Layer','top', 'Color','none');
    title(ax, sprintf('%s, %s', joints{j}, rowTitle{j}), 'FontName',fontName, ...
        'FontSize',fsTick, 'FontWeight','normal', 'Color','k');
    % scale bars, inside the band and below the traces
    tBar = 0.02;                                          % 20 ms
    aBar = niceBar(0.18*diff(yZoom));
    xb = tPulse(1) + 0.03*diff(xZoom);
    yb = yZoom(1) + 0.11*diff(yZoom);
    plot(ax, [xb xb+tBar], [yb yb], 'k-', 'LineWidth',1.0);
    plot(ax, [xb xb], [yb yb+aBar], 'k-', 'LineWidth',1.0);
    text(ax, xb + tBar/2, yb - 0.02*diff(yZoom), '20 ms', 'FontName',fontName, 'FontSize',fsTick, ...
        'Color','k', 'HorizontalAlignment','center', 'VerticalAlignment','top');
    text(ax, xb + 0.03*diff(xZoom), yb + aBar/2, sprintf('%g deg/s%c', aBar, sup2), ...
        'Interpreter','none', 'FontName',fontName, 'FontSize',fsTick, 'Color','k', ...
        'HorizontalAlignment','left', 'VerticalAlignment','middle');
end

% guide lines from each expanded interval to its frame, in figure units
drawnow;
for j = 1:2
    pL = axL(j).Position; pR = axR(j).Position;
    xl = axL(j).XLim; yl = axL(j).YLim;
    xFig = pL(1) + (zoomBox(j,1) + zoomBox(j,3) - xl(1))/diff(xl) * pL(3);
    yFigLo = pL(2) + (zoomBox(j,2) - yl(1))/diff(yl) * pL(4);
    yFigHi = pL(2) + (zoomBox(j,2) + zoomBox(j,4) - yl(1))/diff(yl) * pL(4);
    annotation(fig, 'line', [xFig pR(1)], [yFigHi pR(2)+pR(4)], 'Color',colFrame, 'LineWidth',0.4);
    annotation(fig, 'line', [xFig pR(1)], [yFigLo pR(2)],       'Color',colFrame, 'LineWidth',0.4);
end

% shared key on an invisible overlay
ov = axes(fig, 'Position',[0 0 1 1], 'Visible','off', 'XLim',[0 1], 'YLim',[0 1]);
hold(ov, 'on');
drawKey(ov, 0.962, {'physics engine, unperturbed', 'physics engine, perturbed', 'APE, perturbed'}, ...
    {'--', '-', '-'}, {colUnp, colRef, colAPE}, [0.9 1.5 0.9], fontName, fsLabel, 0.045);

%% ------------------------- EXPORT -------------------------
print(fig, fullfile(here, [outName '.pdf']), '-dpdf', '-vector');
print(fig, fullfile(here, [outName '.svg']), '-dsvg', '-vector');
print(fig, fullfile(here, [outName '.png']), '-dpng', '-r600');
fprintf('Saved %s.pdf, .svg and .png in %s\n', outName, here);

%% ------------------------- LOCAL FUNCTIONS -------------------------
function [dataDir, isTemp] = unpackData(here, name)
% Folder with the figure data: the extracted folder if it sits beside the
% script, otherwise the archive extracted to a temporary folder.
dataDir = fullfile(here, name); isTemp = false;
if ~isfolder(dataDir)
    archive = fullfile(here, [name '.zip']);
    if ~isfile(archive)
        error('%s.zip or the folder %s must be in the same folder as this script.', name, name);
    end
    dataDir = tempname; isTemp = true;
    unzip(archive, dataDir);
end
end

function [lim, ticks] = niceAxis(lo, hi, step)
% Axis limits that enclose [lo, hi] and end on a labelled tick.
lim = [floor(lo/step) ceil(hi/step)] * step;
while (lim(2) - lim(1))/step > 6      % keep at most seven labels
    step = step*2;
    lim = [floor(lo/step) ceil(hi/step)] * step;
end
ticks = lim(1):step:lim(2);
end

function b = niceBar(target)
% Largest of 1, 2 or 5 times a power of ten that does not exceed target.
p = 10^floor(log10(target));
c = [1 2 5] * p;
b = c(find(c <= target, 1, 'last'));
end

function drawKey(ov, y, labels, styles, colors, widths, fontName, fontSize, sample)
% One row of line samples with labels, centred over the figure.
gapIn = 0.012; gapBetween = 0.04;
n = numel(labels); h = gobjects(1,n); w = zeros(1,n);
for k = 1:n
    h(k) = text(ov, 0, y, labels{k}, 'FontName',fontName, 'FontSize',fontSize, ...
        'Color','k', 'VerticalAlignment','middle');
    w(k) = h(k).Extent(3);
end
x = (1 - (sum(w) + n*(sample + gapIn) + (n-1)*gapBetween))/2;
for k = 1:n
    plot(ov, x + [0 sample], [y y], styles{k}, 'Color',colors{k}, 'LineWidth',widths(k));
    h(k).Position(1) = x + sample + gapIn;
    x = x + sample + gapIn + w(k) + gapBetween;
end
end
