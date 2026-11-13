root = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'saved_results', 'tests');
out = fileparts(mfilename('fullpath'));
files = {fullfile('20261109', 'sp3_or2.mat'), fullfile('20261111', 'sp3_r_2.mat')};
names = {'sp3_or2 (09 Nov)', 'sp3_r_2 (11 Nov 18:10)'};
cols = {[0 0 0], [0 0.4863 0.6588]};
f1 = figure('Color', 'w', 'Position', [100 100 900 650]); ax1 = axes(f1); hold(ax1, 'on'); grid(ax1, 'on')
f2 = figure('Color', 'w', 'Position', [100 100 1200 750]); tl = tiledlayout(f2, 2, 1, 'TileSpacing', 'compact'); ax2 = nexttile(tl); hold(ax2, 'on'); grid(ax2, 'on'); ax3 = nexttile(tl); hold(ax3, 'on'); grid(ax3, 'on')
for k = 1:2
    s = load(fullfile(root, files{k}), 'result'); r = s.result;
    n = min([numel(r.dm), numel(r.fm), numel(r.dd_pause_enable_log)]);
    a = find(r.dd_pause_enable_log(1:n) == 0);
    dm = r.dm(a); fm = r.fm(a)/4448.2216152605; t = r.t(a) - r.t(a(1));
    plot(ax1, dm, fm, '-', 'Color', cols{k}, 'LineWidth', 1.0, 'DisplayName', names{k});
    plot(ax2, t, dm, '-', 'Color', cols{k}, 'LineWidth', 1.0, 'DisplayName', names{k});
    plot(ax3, t, fm, '-', 'Color', cols{k}, 'LineWidth', 1.0, 'DisplayName', names{k});
    fprintf('%s: EQ %.2f s, dm [%.2f %.2f] mm, fm [%.3f %.3f] kip\n', files{k}, t(end), min(dm), max(dm), min(fm), max(fm));
end
xlabel(ax1, 'Measured displacement dm (mm)'); ylabel(ax1, 'Measured force fm (kip)')
title(ax1, 'SP3 hysteresis (earthquake window)'); legend(ax1, 'Location', 'best', 'Interpreter', 'none')
xlabel(ax3, 'Time from earthquake start (s)'); ylabel(ax3, 'Measured force fm (kip)'); legend(ax3, 'Location', 'best', 'Interpreter', 'none'); linkaxes([ax2 ax3], 'x')
ylabel(ax2, 'Measured displacement dm (mm)')
title(tl, 'SP3 time series (earthquake window)'); legend(ax2, 'Location', 'best', 'Interpreter', 'none')
exportgraphics(f1, fullfile(out, 'sp3_r_2_hysteresis_overlay.png'), 'Resolution', 150)
exportgraphics(f2, fullfile(out, 'sp3_r_2_time_series.png'), 'Resolution', 150)
