function fig = plot_hs_roof_hysteresis(roof, shear, labels)
%PLOT_HS_ROOF_HYSTERESIS Total base shear versus relative roof displacement.
% Inputs: roof [m], shear [N] (plotted in kip); rows = matched samples, columns = models.
fig = figure('Color', 'w', 'Name', 'HS roof displacement vs base shear', ...
    'Position', [100 100 950 600]);
ax = axes('Parent', fig); hold(ax, 'on');
colors = [116 5 138; 116 5 138; 57 191 94]/255;
styles = {'--', '-', ':'};
widths = [2.2 1.2 1.1];
for j = 1:size(roof, 2)
    plot(ax, 1000*roof(:, j), shear(:, j)/4448.2216152605, styles{j}, ...
        'Color', colors(j, :), 'LineWidth', widths(j), 'DisplayName', labels{j});
end
hold(ax, 'off'); grid(ax, 'on');
xlabel(ax, 'Roof displacement (mm)');
ylabel(ax, 'Total base shear (kip)');
title(ax, 'Roof displacement vs total base shear');
lgd = legend(ax, 'Location', 'best');
lgd.ItemHitFcn = @toggleCurve;
end

function toggleCurve(~, event)
if strcmp(event.Peer.Visible, 'on')
    event.Peer.Visible = 'off';
else
    event.Peer.Visible = 'on';
end
end
