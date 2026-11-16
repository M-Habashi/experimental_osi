% Fine sync (video t = a*lab t + b), px/mm scale, windowed drift check.
load track.mat; load candidates.mat; r = c(2);
s = sh(:, 1) - sh(:, 2);
best = [-inf 0 0];
for a = 0.997:0.0002:1.003
    for b = -180.5:0.02:-176.5
        dm = interp1(r.t, r.dm, (tv - b)/a, 'linear', nan); ok = ~isnan(dm);
        q = corr(s(ok), dm(ok));
        if -q > best(1), best = [-q a b]; end
    end
end
a = best(2); b = best(3);
dm = interp1(r.t, r.dm, (tv - b)/a); ok = ~isnan(dm);
P = polyfit(dm(ok), s(ok), 1); res = s(ok) - polyval(P, dm(ok));
fprintf('corr %.4f  a %.5f  b %.2f s  scale %.3f px/mm  offset %.2f px  resid RMS %.2f px\n', ...
    best(1), a, b, P(1), P(2), rms(res));
for w = 0:60:360
    k = tv >= w & tv < w + 60 & ok; L = -3:0.02:3; q = zeros(size(L));
    for i = 1:numel(L), q(i) = -corr(s(k), interp1(r.t, r.dm, (tv(k) - b)/a + L(i))); end
    [m, i] = max(q); fprintf('window %3d-%3d s: corr %.3f, extra lag %+.2f s\n', w, w + 60, m, L(i));
end
eq0 = r.t(find(r.eq, 1)); tsf = 20;
fprintf('video covers lab %.1f..%.1f s = tau %.2f..%.2f s; eq ends lab %.1f (tau %.2f)\n', ...
    (tv(1) - b)/a, (tv(end) - b)/a, ((tv(1) - b)/a - eq0)/tsf, ((tv(end) - b)/a - eq0)/tsf, ...
    r.t(find(r.eq, 1, 'last')), (r.t(find(r.eq, 1, 'last')) - eq0)/tsf);
pre = r.eq & r.t < (tv(1) - b)/a; post = r.eq & r.t > (tv(end) - b)/a;
fprintf('|dm| before camera max %.2f mm, after camera max %.2f mm\n', max(abs(r.dm(pre))), max(abs(r.dm(post))));
save('calib.mat', 'a', 'b', 'P')
