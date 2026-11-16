% Shift of the column left edge at several heights and of the actuator clevis.
v = VideoReader('C:\Users\BOWN1111PC1\Documents\Mohamed\experimental_osi\main\results_analysis\rths_animation\footage\sp3_r_2_specimen_camera.MOV');
yc = [120 300 500 700 900 1100 1300 1500];
bands = [arrayfun(@(y) {y + (-15:15), 320:440}, yc, 'UniformOutput', false), {{280:320, 640:720}}];
nb = numel(bands); n = v.NumFrames; sh = nan(ceil(n/5), nb); tv = nan(ceil(n/5), 1);
prof = @(I, b) diff(mean(double(I(bands{b}{1}, bands{b}{2}, 2)), 1));
I = readFrame(v); ref = cell(nb, 1); for b = 1:nb, ref{b} = prof(I, b); end
v.CurrentTime = 0; k = 0; j = 0;
while hasFrame(v)
    t = v.CurrentTime; I = readFrame(v); j = j + 1;
    if mod(j - 1, 5), continue; end
    k = k + 1; tv(k) = t;
    for b = 1:nb
        [c, lags] = xcorr(prof(I, b), ref{b}, 50); [~, i] = max(c); i = min(max(i, 2), numel(c) - 1);
        sh(k, b) = lags(i) + (c(i-1) - c(i+1))/(2*(c(i-1) - 2*c(i) + c(i+1)));
    end
end
sh = sh(1:k, :); tv = tv(1:k); load calib.mat; load candidates.mat; r = c(2);
dm = interp1(r.t, r.dm, tv - b);
for q = 1:nb
    P = polyfit(dm, sh(:, q), 1);
    if q <= numel(yc), fprintf('column y %4d: %.3f px/mm\n', yc(q), P(1)); else, fprintf('clevis     : %.3f px/mm\n', P(1)); end
end
save('shape.mat', 'sh', 'tv', 'yc')
