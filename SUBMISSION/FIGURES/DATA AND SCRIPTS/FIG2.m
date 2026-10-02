% FIG2  Joint-angle error of the APE and the direct mapping model.
%
% Regenerates Figure 2 from the packaged data archive FIG2.zip (or the
% extracted folder FIG2), which must be in the same folder as this script.
%
% Panel a: 90 unperturbed test movements. Panel b: the same 90 movements
% with a torque perturbation. Each dot is the RMSE of one movement between
% the predicted and the reference joint angle. Boxes show the median and
% quartiles, whiskers the 5th and 95th percentiles. The sentence beside each
% APE box gives the ratio of mean RMSE, direct mapping over APE.
%
% Statistics: normality of each group by the Lilliefors test; for each
% joint, a Kruskal-Wallis test across the four groups (2 models x 2
% conditions), then pairwise comparisons with the Dunn-Sidak correction.
% An asterisk marks p < 0.05 between the two models.
%
% Tested with MATLAB R2026a. Requires the Statistics and Machine Learning
% Toolbox and the Arial font.
%
% Outputs, written beside this script:
%   FIG2.pdf, FIG2.svg, FIG2.png
%   FIG2_rmse_per_trial.csv, FIG2_summary.csv, FIG2_statistics.csv

close all; clear;

%% ------------------------- SETTINGS -------------------------
here = fileparts(mfilename('fullpath'));
if isempty(here); here = pwd; end
outName = 'FIG2';
conditions = {'unperturbed', 'perturbed'};
joints = {'shoulder', 'elbow'};
models = {'direct', 'APE'};

alpha = 0.05;                   % significance level
colDirect = [0 114 178]/255;    % blue
colAPE    = [178 24 43]/255;    % red
figW = 3.5; figH = 3.0;         % inches (single column, 89 mm)
fsLabel = 7; fsTick = 6; fsPanel = 10;
fontName = 'Arial';
if ~any(strcmp(listfonts, fontName)); warning('Font %s is not installed.', fontName); end

%% ------------------------- RMSE PER TRIAL -------------------------
[dataDir, isTemp] = unpackData(here, 'FIG2');
r2d = 180/pi;
T = table();
for c = 1:2
    files = dir(fullfile(dataDir, conditions{c}, 'move_*.csv'));
    for i = 1:numel(files)
        D = readtable(fullfile(files(i).folder, files(i).name));
        ref = [D.q_sh_ref, D.q_el_ref];
        eA = sqrt(mean((ref - [D.q_sh_ape,    D.q_el_ape   ]).^2, 1, 'omitnan')) * r2d;
        eD = sqrt(mean((ref - [D.q_sh_direct, D.q_el_direct]).^2, 1, 'omitnan')) * r2d;
        T = [T; table(string(erase(files(i).name, '.csv')), string(conditions{c}), ...
            eD(1), eA(1), eD(2), eA(2), ...
            'VariableNames', {'trial','condition','direct_shoulder_deg','APE_shoulder_deg', ...
                              'direct_elbow_deg','APE_elbow_deg'})]; %#ok<AGROW>
    end
end
if isTemp; rmdir(dataDir, 's'); end
writetable(T, fullfile(here, 'FIG2_rmse_per_trial.csv'));

%% ------------------------- STATISTICS -------------------------
groupNames = ["direct unperturbed","APE unperturbed","direct perturbed","APE perturbed"];
warnState = warning('off', 'stats:lillietest:OutOfRangePLow');
S = table(); G = table();
pModels = nan(2,2);      % (condition, joint): direct vs APE
foldMean = nan(2,2);     % ratio of mean RMSE, direct / APE
for j = 1:2
    x = []; g = [];
    for c = 1:2
        rows = T.condition == conditions{c};
        v = cell(1,2);
        for m = 1:2
            v{m} = T.(sprintf('%s_%s_deg', models{m}, joints{j}))(rows);
            x = [x; v{m}];                                   %#ok<AGROW>
            g = [g; repmat(2*(c-1)+m, numel(v{m}), 1)];      %#ok<AGROW>
        end
        foldMean(c,j) = mean(v{1})/mean(v{2});
        for m = 1:2
            q = prctile(v{m}, [5 25 50 75 95]);
            [~, pLillie] = lillietest(v{m});     % normality; p is reported within 0.001 to 0.5
            G = [G; table(string(joints{j}), string(conditions{c}), string(models{m}), numel(v{m}), ...
                mean(v{m}), std(v{m}), q(3), q(2), q(4), q(1), q(5), min(v{m}), max(v{m}), ...
                foldMean(c,j), median(v{1})/median(v{2}), pLillie, ...
                'VariableNames', {'joint','condition','model','n','mean_deg','sd_deg','median_deg', ...
                'q1_deg','q3_deg','p5_deg','p95_deg','min_deg','max_deg', ...
                'fold_of_means_direct_over_APE','fold_of_medians_direct_over_APE','p_Lilliefors'})]; %#ok<AGROW>
        end
    end
    [pKW, tblKW, st] = kruskalwallis(x, g, 'off');
    cmp = multcompare(st, 'CType', 'dunn-sidak', 'Display', 'off');
    % Dunn-Sidak p values computed from the mean ranks, without underflow
    N = sum(st.n); nCmp = size(cmp,1);
    varRank = N*(N+1)/12 - st.sumt/(12*(N-1));
    for k = 1:nCmp
        a = cmp(k,1); b = cmp(k,2);
        z = abs(st.meanranks(a) - st.meanranks(b)) / sqrt(varRank*(1/st.n(a) + 1/st.n(b)));
        pRaw = erfc(z/sqrt(2));
        pAdj = -expm1(nCmp*log1p(-pRaw));
        S = [S; table(string(joints{j}), groupNames(a), groupNames(b), tblKW{2,5}, pKW, z, pRaw, pAdj, ...
            'VariableNames', {'joint','group1','group2','H_KruskalWallis','p_KruskalWallis', ...
                              'z_Dunn','p_Dunn_raw','p_DunnSidak'})]; %#ok<AGROW>
        if mod(a,2) == 1 && b == a + 1           % direct vs APE, same condition
            pModels((a+1)/2, j) = pAdj;
        end
    end
end
warning(warnState);
writetable(G, fullfile(here, 'FIG2_summary.csv'));
writetable(S, fullfile(here, 'FIG2_statistics.csv'));
disp(G(:, {'joint','condition','model','n','mean_deg','sd_deg','median_deg','fold_of_means_direct_over_APE'}));
disp(S(:, {'joint','group1','group2','p_DunnSidak'}));

%% ------------------------- FIGURE -------------------------
fig = figure('Units','inches', 'Position',[1 1 figW figH], 'Color','w', ...
    'PaperUnits','inches', 'PaperSize',[figW figH], 'PaperPosition',[0 0 figW figH]);

left = 0.155; right = 0.02; gap = 0.035; bottom = 0.10; height = 0.73;
width = (1 - left - right - gap)/2;
xDirect = [1 3.3]; xAPE = [2 4.3];          % shoulder, elbow
xLim = [0.35 4.95];
allV = T{:, 3:6};
yBracket = 1.45*max(allV(:));                % significance bracket, above every point
yLim = 10.^[floor(log10(min(allV(:)))), ceil(log10(1.3*yBracket))];   % whole decades
assert(all(allV(:) > yLim(1) & allV(:) < yLim(2)), 'A value lies outside the y axis.');
rng(1);                                      % reproducible jitter

ax = gobjects(1,2);
for c = 1:2
    ax(c) = axes(fig, 'Position', [left + (c-1)*(width+gap), bottom, width, height]);
    hold(ax(c), 'on');
    rows = T.condition == conditions{c};
    for j = 1:2
        d = T.(sprintf('direct_%s_deg', joints{j}))(rows);
        a = T.(sprintf('APE_%s_deg',    joints{j}))(rows);
        drawBox(ax(c), xDirect(j), d, colDirect);
        drawBox(ax(c), xAPE(j),    a, colAPE);
        if pModels(c,j) < alpha
            plot(ax(c), [xDirect(j) xDirect(j) xAPE(j) xAPE(j)], ...
                [yBracket/1.18 yBracket yBracket yBracket/1.18], 'k-', 'LineWidth', 0.5);
            text(ax(c), mean([xDirect(j) xAPE(j)]), yBracket*0.98, '*', 'FontName',fontName, ...
                'FontSize', fsLabel, 'Color','k', 'HorizontalAlignment','center', ...
                'VerticalAlignment','baseline');
        end
        % the result in words: ratio of mean RMSE
        text(ax(c), xAPE(j), max(a)*1.35, sprintf('mean error\n%.0f-fold lower', foldMean(c,j)), ...
            'FontName',fontName, 'FontSize',fsTick, 'Color',colAPE, ...
            'HorizontalAlignment','center', 'VerticalAlignment','bottom');
    end
    decades = log10(yLim(1)):log10(yLim(2));
    set(ax(c), 'YScale','log', 'YLim',yLim, 'YTick',10.^decades, ...
        'YTickLabel',arrayfun(@(e) sprintf('%g', 10^e), decades, 'UniformOutput',false), ...
        'YMinorTick','on', 'XLim',xLim, 'TickDir','out', 'TickLength',[0.02 0.02], ...
        'Box','off', 'LineWidth',0.5, 'FontName',fontName, 'FontSize',fsTick, ...
        'XColor','k', 'YColor','k', 'Layer','top', 'Color','none');
    ax(c).XAxis.Visible = 'off';
    if c == 1
        ylabel(ax(c), 'joint angle error (RMSE), deg', 'FontName',fontName, ...
            'FontSize',fsLabel, 'Color','k');
    else
        ax(c).YAxis.Visible = 'off';
    end
    title(ax(c), sprintf('%s trials (n = %d)', conditions{c}, nnz(rows)), ...
        'FontName',fontName, 'FontSize',fsLabel, 'FontWeight','normal', 'Color','k');
end

% joint brackets, shared key and panel labels on an invisible overlay
ov = axes(fig, 'Position',[0 0 1 1], 'Visible','off', 'XLim',[0 1], 'YLim',[0 1]);
hold(ov, 'on');
for c = 1:2
    p = ax(c).Position;
    toFig = @(x) p(1) + (x - xLim(1))/diff(xLim) * p(3);
    for j = 1:2
        xb = toFig([xDirect(j) - 0.45, xAPE(j) + 0.45]);
        yb = bottom - 0.022;
        plot(ov, xb([1 1 2 2]), yb + [0.012 0 0 0.012], 'k-', 'LineWidth', 0.5);
        text(ov, mean(xb), yb - 0.008, joints{j}, 'FontName',fontName, 'FontSize',fsLabel, ...
            'Color','k', 'HorizontalAlignment','center', 'VerticalAlignment','top');
    end
end
drawKey(ov, 0.968, {'direct mapping','APE'}, {colDirect, colAPE}, fontName, fsLabel, figW/figH);
yPanel = bottom + height + 0.085;
text(ov, 0.005, yPanel, 'a.', 'FontName',fontName, 'FontSize',fsPanel, 'FontWeight','bold', ...
    'Color','k', 'VerticalAlignment','top');
text(ov, left + width + gap - 0.035, yPanel, 'b.', 'FontName',fontName, 'FontSize',fsPanel, ...
    'FontWeight','bold', 'Color','k', 'VerticalAlignment','top');

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

function drawBox(ax, x, v, col)
% All trials as light dots, with a box (median, quartiles) and whiskers
% (5th and 95th percentiles) drawn over them.
w = 0.62;
jit = (rand(size(v)) - 0.5) * w * 0.8;
scatter(ax, x + jit, v, 5, col, 'filled', 'MarkerFaceAlpha',0.28, 'MarkerEdgeColor','none');
q = prctile(v, [5 25 50 75 95]);
plot(ax, [x x], [q(1) q(2)], '-', 'Color','k', 'LineWidth',0.6);
plot(ax, [x x], [q(4) q(5)], '-', 'Color','k', 'LineWidth',0.6);
plot(ax, x + [-1 1]*w*0.2, [q(1) q(1)], '-', 'Color','k', 'LineWidth',0.6);
plot(ax, x + [-1 1]*w*0.2, [q(5) q(5)], '-', 'Color','k', 'LineWidth',0.6);
plot(ax, x + [-1 1 1 -1 -1]*w/2, [q(2) q(2) q(4) q(4) q(2)], '-', 'Color','k', 'LineWidth',0.6);
plot(ax, x + [-1 1]*w/2, [q(3) q(3)], '-', 'Color',col, 'LineWidth',1.6);
end

function drawKey(ov, y, labels, colors, fontName, fontSize, aspect)
% One row of colour squares with labels, centred over the figure.
s = 0.012; gapIn = 0.012; gapBetween = 0.06;
n = numel(labels); h = gobjects(1,n); w = zeros(1,n);
for k = 1:n
    h(k) = text(ov, 0, y, labels{k}, 'FontName',fontName, 'FontSize',fontSize, ...
        'Color','k', 'VerticalAlignment','middle');
    w(k) = h(k).Extent(3);
end
x = (1 - (sum(w) + n*(2*s + gapIn) + (n-1)*gapBetween))/2;
for k = 1:n
    patch(ov, x + [0 2*s 2*s 0], y + [-s -s s s]*aspect, colors{k}, 'EdgeColor','none');
    h(k).Position(1) = x + 2*s + gapIn;
    x = x + 2*s + gapIn + w(k) + gapBetween;
end
end
