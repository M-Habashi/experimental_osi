function fig = plot_hs_plastic_hinges(hs, numerical, reference)
%PLOT_HS_PLASTIC_HINGES Map member ends that yielded or formed plastic hinges.
% Numerical hinges are model reconstructions, not measured specimen damage.
fig = figure('Color', 'w', 'Name', 'HS plastic hinges', ...
    'Position', [80 100 1250 600]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
summaries = {numerical, reference};
kinds = {'num', 'ref'};
names = {'Numerical frame (reconstructed)', 'Full FEM reference (predicted)'};
green = [57 191 94]/255; copper = [172 100 32]/255; red = [144 21 0]/255;
mode = 'Linear elastic screen';
if is_hs_nonlinear(hs), mode = 'Nonlinear'; end
for k = 1:2
    fem = hs.fem.(kinds{k}); f = fem.frame; s = summaries{k};
    ax = nexttile; hold(ax, 'on');
    for c = 1:f.n_bay+1
        x = (c-1)*f.bay_width;
        y0 = 0;
        if k == 1 && c == 1
            y0 = fem.experimental_column.height;
            plot(ax, [x x], [0 y0], '--', 'Color', [.65 .65 .65], ...
                'HandleVisibility', 'off');
        end
        plot(ax, [x x], [y0 f.n_story*f.story_height], '-', ...
            'Color', [.35 .35 .35], 'HandleVisibility', 'off');
    end
    for floor = 1:f.n_story
        plot(ax, [0 f.n_bay*f.bay_width], floor*f.story_height*[1 1], ...
            '-', 'Color', [.35 .35 .35], 'HandleVisibility', 'off');
    end
    plastic = s.peak_rotation > 1e-10;
    yielded = s.peak_moment >= s.My;
    for j = 1:numel(s.labels)
        label = s.labels{j};
        token = regexp(label, '^C(\d+)-S(\d+)-(bottom|top)$', 'tokens', 'once');
        if ~isempty(token)
            is_column = true;
            c = str2double(token{1}); story = str2double(token{2});
            x = (c-1)*f.bay_width; lo = (story-1)*f.story_height;
            if k == 1 && c == 1 && story == 1, lo = fem.experimental_column.height; end
            hi = story*f.story_height; y = lo + .08*(hi-lo);
            if strcmp(token{3}, 'top'), y = hi - .08*(hi-lo); end
        else
            is_column = false;
            token = regexp(label, '^B(\d+)-F(\d+)-(left|right)$', 'tokens', 'once');
            bay = str2double(token{1}); floor = str2double(token{2});
            x = (bay-1+.08)*f.bay_width;
            if strcmp(token{3}, 'right'), x = (bay-.08)*f.bay_width; end
            y = floor*f.story_height;
        end
        color = green; marker = 'o';
        if yielded(j), color = copper; marker = 'd'; end
        if plastic(j), color = red; marker = 'o'; end
        plot(ax, x, y, marker, 'MarkerFaceColor', color, 'Color', color, ...
            'MarkerSize', 7, 'HandleVisibility', 'off');
        if plastic(j)
            tx = x; ty = y+.12; horizontal = 'left'; vertical = 'bottom';
            if is_column
                tx = x+.08; ty = y-.12; vertical = 'top';
            elseif strcmp(token{3}, 'right')
                horizontal = 'right';
            end
            text(ax, tx, ty, sprintf('%s\n%.2f eq s', label, s.first_plastic_s(j)), ...
                'FontSize', 7, 'Interpreter', 'none', ...
                'HorizontalAlignment', horizontal, 'VerticalAlignment', vertical);
        end
    end
    h(1) = plot(ax, nan, nan, 'o', 'Color', green, 'MarkerFaceColor', green);
    h(2) = plot(ax, nan, nan, 'd', 'Color', copper, 'MarkerFaceColor', copper);
    h(3) = plot(ax, nan, nan, 'o', 'Color', red, 'MarkerFaceColor', red);
    legend(ax, h, {'Below My', 'My exceeded; no plastic hinge', 'Plastic hinge formed'}, ...
        'Location', 'southoutside');
    axis(ax, 'equal'); xlim(ax, [-.4 f.n_bay*f.bay_width+.7]);
    ylim(ax, [-.2 f.n_story*f.story_height+.7]);
    xlabel(ax, 'Frame width (m)'); ylabel(ax, 'Height (m)');
    title(ax, sprintf('%s (%.2gx): %s\n%d plastic ends; max |M|/My = %.3f', ...
        mode, hs.intensity_factor, names{k}, sum(plastic), ...
        max(s.peak_moment./s.My)), 'FontSize', 11);
end
end
