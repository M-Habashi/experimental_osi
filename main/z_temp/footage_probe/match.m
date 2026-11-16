% Plot camera motion and candidate dm, then find the best lag (and speed).
load track.mat; load candidates.mat
s = sh(:, 1) - sh(:, 2); % top minus base (removes camera shake)
f = figure('Visible', 'off', 'Position', [0 0 1600 1100]);
subplot(numel(c) + 1, 1, 1); plot(tv, sh(:, 1), tv, sh(:, 2), tv, sh(:, 3)); grid on
title('video shift (px): top, base, background'); xlim([0 tv(end)])
fv = 10; tq = (0:1/fv:tv(end))'; sv = interp1(tv, s, tq); sv = sv - median(sv);
for i = 1:numel(c)
    subplot(numel(c) + 1, 1, i + 1); plot(c(i).t, c(i).dm); grid on
    title(c(i).name, 'Interpreter', 'none'); xlim([0 max(tv(end), c(i).t(end))])
    best = [-inf 0 0];
    for spd = [0.5 1 2]
        tl = (0:1/fv:c(i).t(end)/spd)'; dl = interp1(c(i).t/spd, c(i).dm, tl);
        dl = dl - median(dl);
        [r, lags] = xcorr(sv, dl); r = r/(norm(sv)*norm(dl));
        [m, j] = max(abs(r));
        if m > best(1), best = [m lags(j)/fv spd*sign(r(j))]; end
    end
    fprintf('%-28s |corr| %.3f  video t = lab t/%g + %.1f s (sign %+d)\n', c(i).name, ...
        best(1), abs(best(3)), best(2), sign(best(3)));
end
exportgraphics(f, 'match.png', 'Resolution', 70)
