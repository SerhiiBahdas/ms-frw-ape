% FIG1  Panel c of Figure 1: one test movement simulated by the APE and by
% the direct mapping model, without (left) and with (right) a torque
% perturbation, against the physics engine.
%
% Regenerates the panel from the packaged data archive FIG1.zip (or the
% extracted folder FIG1), which must be in the same folder as this script.
% Panels a and b of Figure 1 are schematics and are provided in the rendered
% figure only.
%
% The two columns share each y axis, so the unperturbed and the perturbed
% trial can be compared directly. The shaded band marks the torque pulse,
% found from the difference between the perturbed and the unperturbed
% torques. The RMSE of this movement is printed in each panel in the colour
% of its model (blue, direct mapping; red, APE).
%
% Tested with MATLAB R2026a. Requires the Arial font.
%
% Outputs, written beside this script:
%   FIG1c.pdf, FIG1c.svg, FIG1c.png

close all; clear;

%% ------------------------- SETTINGS -------------------------
trial = 'move_4_to_8';          % movement packaged in FIG1.zip

here = fileparts(mfilename('fullpath'));
if isempty(here); here = pwd; end
outName = 'FIG1c';
conditions = {'unperturbed', 'perturbed'};
joints = {'shoulder', 'elbow'};

colDirect = [0 114 178]/255;    % blue
colAPE    = [178 24 43]/255;    % red
colRef    = [0.25 0.25 0.25];   % dark grey
colBand   = [0.90 0.90 0.90];
figW = 2.69; figH = 2.53;       % inches (68.3 x 64.3 mm, the panel c slot of the 183 mm figure)
fsLabel = 7; fsTick = 6; fsPanel = 10;
plotStep = 64;                  % curves are drawn from every 64th sample (6.4 ms), which keeps each curve
                                % a single path with regular dashes in vector output; errors use every sample
fontName = 'Arial';
if ~any(strcmp(listfonts, fontName)); warning('Font %s is not installed.', fontName); end

%% ------------------------- LOAD -------------------------
[dataDir, isTemp] = unpackData(here, 'FIG1');
r2d = 180/pi;
cond = struct('name', conditions);
for c = 1:2
    D = readtable(fullfile(dataDir, sprintf('fig1_%s_%s.csv', trial, conditions{c})));
    cond(c).t    = D.time_s;
    cond(c).qRef = [D.q_sh_ref,    D.q_el_ref   ] * r2d;
    cond(c).qAPE = [D.q_sh_ape,    D.q_el_ape   ] * r2d;
    cond(c).qDir = [D.q_sh_direct, D.q_el_direct] * r2d;
    cond(c).tau  = [D.tau_sh, D.tau_el];
    % RMSE over the whole movement, as in FIG2
    cond(c).rmseAPE = sqrt(mean((cond(c).qRef - cond(c).qAPE).^2, 1, 'omitnan'));
    cond(c).rmseDir = sqrt(mean((cond(c).qRef - cond(c).qDir).^2, 1, 'omitnan'));
    fprintf('%s, %s: RMSE APE %.2f / %.2f deg, direct %.2f / %.2f deg (shoulder / elbow)\n', ...
        trial, cond(c).name, cond(c).rmseAPE, cond(c).rmseDir);
end
if isTemp; rmdir(dataDir, 's'); end

% Torque pulse: where the perturbed torque differs from the unperturbed one
n = min(size(cond(1).tau,1), size(cond(2).tau,1));
dTau = cond(2).tau(1:n,:) - cond(1).tau(1:n,:);
[~, jPert] = max(max(abs(dTau), [], 1));
on = find(abs(dTau(:,jPert)) > 1e-9*max(abs(dTau(:,jPert))));
tPulse = cond(2).t([on(1) on(end)]);
fprintf('Torque pulse at the %s from %.3f to %.3f s\n', joints{jPert}, tPulse);

%% ------------------------- FIGURE -------------------------
fig = figure('Units','inches', 'Position',[1 1 figW figH], 'Color','w', ...
    'PaperUnits','inches', 'PaperSize',[figW figH], 'PaperPosition',[0 0 figW figH]);

left = 0.185; right = 0.025; gapX = 0.05; bottom = 0.135; gapY = 0.085; top = 0.16;
width  = (1 - left - right - gapX)/2;
height = (1 - bottom - top - gapY)/2;

tMax = max(cond(1).t(end), cond(2).t(end));
[xLim, xTick] = niceAxis(0, tMax, 0.2);

for j = 1:2                                   % rows: shoulder, elbow
    allT = repmat([cond(1).t; cond(2).t], 3, 1);
    allY = [cond(1).qRef(:,j); cond(2).qRef(:,j); cond(1).qAPE(:,j); cond(2).qAPE(:,j); ...
            cond(1).qDir(:,j); cond(2).qDir(:,j)];
    [yLim, yTick] = niceAxis(min(allY), max(allY), 10);
    assert(all(allY(~isnan(allY)) >= yLim(1) & allY(~isnan(allY)) <= yLim(2)), 'A value lies outside the y axis.');
    corner = freeCorner((allT - xLim(1))/diff(xLim), (allY - yLim(1))/diff(yLim), 0.30, 0.40, ...
        [1 0; 1 1; 0 1; 0 0]);
    for c = 1:2                               % columns: unperturbed, perturbed
        ax = axes(fig, 'Position', [left + (c-1)*(width+gapX), ...
            bottom + (2-j)*(height+gapY), width, height]);
        hold(ax, 'on');
        if c == 2
            patch(ax, tPulse([1 2 2 1]), yLim([1 1 2 2]), colBand, 'EdgeColor','none');
            if j == 1      % label between the two rows, under the band
                text(ax, mean(tPulse), yLim(1) - 0.03*diff(yLim), ...
                    sprintf('%s torque pulse', joints{jPert}), ...
                    'FontName',fontName, 'FontSize',fsTick, 'Color',[0.4 0.4 0.4], ...
                    'HorizontalAlignment','center', 'VerticalAlignment','top');
            end
        end
        k = [1:plotStep:numel(cond(c).t), numel(cond(c).t)];   % samples drawn
        kA = k(~isnan(cond(c).qAPE(k,j)));
        plot(ax, cond(c).t(k),  cond(c).qDir(k,j),  '-',  'Color',colDirect, 'LineWidth',1.0);
        plot(ax, cond(c).t(kA), cond(c).qAPE(kA,j), '-',  'Color',colAPE,    'LineWidth',1.4);
        plot(ax, cond(c).t(k),  cond(c).qRef(k,j),  '--', 'Color',colRef,    'LineWidth',0.8);
        set(ax, 'XLim',xLim, 'XTick',xTick, 'YLim',yLim, 'YTick',yTick, ...
            'TickDir','out', 'TickLength',[0.025 0.025], 'Box','off', 'LineWidth',0.5, ...
            'FontName',fontName, 'FontSize',fsTick, 'XColor','k', 'YColor','k', ...
            'Layer','top', 'Color','none', 'Clipping','off');
        if j == 1
            ax.XAxis.Visible = 'off';
            title(ax, sprintf('%s trial', cond(c).name), 'FontName',fontName, ...
                'FontSize',fsLabel, 'FontWeight','normal', 'Color','k');
            ax.TitleHorizontalAlignment = 'left';
        else
            xlabel(ax, 'time, s', 'FontName',fontName, 'FontSize',fsLabel, 'Color','k');
        end
        if c == 1
            ylabel(ax, sprintf('%s angle, deg', joints{j}), 'FontName',fontName, ...
                'FontSize',fsLabel, 'Color','k');
        else
            ax.YAxis.Visible = 'off';
        end
        % error of this movement, in the colour of each model, in the corner
        % that the curves of both columns leave free
        xText = xLim(1) + (0.02 + 0.96*corner(1))*diff(xLim);
        hAl = {'left','right'}; vAl = {'bottom','top'};
        lines = {'RMSE', sprintf('%.1f%c', cond(c).rmseDir(j), char(176)), ...
                 sprintf('%.1f%c', cond(c).rmseAPE(j), char(176))};
        lineCol = {[0.4 0.4 0.4], colDirect, colAPE};
        lineStep = 0.115*diff(yLim);
        for k = 1:3
            if corner(2) == 1
                yText = yLim(2) - 0.03*diff(yLim) - (k-1)*lineStep;
            else
                yText = yLim(1) + 0.03*diff(yLim) + (3-k)*lineStep;
            end
            text(ax, xText, yText, lines{k}, 'Color',lineCol{k}, 'FontName',fontName, ...
                'FontSize',fsTick, 'Interpreter','none', ...
                'HorizontalAlignment',hAl{corner(1)+1}, 'VerticalAlignment',vAl{corner(2)+1});
        end
    end
end

% shared key and panel label on an invisible overlay
ov = axes(fig, 'Position',[0 0 1 1], 'Visible','off', 'XLim',[0 1], 'YLim',[0 1]);
hold(ov, 'on');
drawKey(ov, 0.955, {'physics engine', 'APE', 'direct mapping'}, {'--', '-', '-'}, ...
    {colRef, colAPE, colDirect}, [0.8 1.4 1.0], fontName, fsLabel, 0.055);
text(ov, 0.005, 0.995, 'c.', 'FontName',fontName, 'FontSize',fsPanel, 'FontWeight','bold', ...
    'Color','k', 'VerticalAlignment','top');

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

function corner = freeCorner(xn, yn, w, h, order)
% Corner of the unit square ([0 0] bottom left ... [1 1] top right) whose
% w-by-h box holds the fewest curve samples. Ties go to the earlier row of order.
count = zeros(size(order,1), 1);
for k = 1:size(order,1)
    inX = (order(k,1) == 0 & xn <= w) | (order(k,1) == 1 & xn >= 1 - w);
    inY = (order(k,2) == 0 & yn <= h) | (order(k,2) == 1 & yn >= 1 - h);
    count(k) = nnz(inX & inY);
end
[~, k] = min(count);
corner = order(k,:);
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

function drawKey(ov, y, labels, styles, colors, widths, fontName, fontSize, sample)
% One row of line samples with labels, centred in the space right of the panel label.
gapIn = 0.015; gapBetween = 0.035; xMin = 0.085;
n = numel(labels); h = gobjects(1,n); w = zeros(1,n);
for k = 1:n
    h(k) = text(ov, 0, y, labels{k}, 'FontName',fontName, 'FontSize',fontSize, ...
        'Color','k', 'VerticalAlignment','middle');
    w(k) = h(k).Extent(3);
end
total = sum(w) + n*(sample + gapIn) + (n-1)*gapBetween;
x = xMin + max(0, (1 - xMin - total)/2);
for k = 1:n
    plot(ov, x + [0 sample], [y y], styles{k}, 'Color',colors{k}, 'LineWidth',widths(k));
    h(k).Position(1) = x + sample + gapIn;
    x = x + sample + gapIn + w(k) + gapBetween;
end
end
