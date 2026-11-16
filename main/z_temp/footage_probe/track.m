% Track horizontal image motion of the specimen (top, base) and a static
% background edge in every frame. Shifts in px (full-res), time in s (video).
v = VideoReader('C:\Users\BOWN1111PC1\Downloads\experiment_video.MOV');
bands = {260:340, 300:500; 1300:1400, 280:480; 700:900, 840:940}; % rows, cols
nb = size(bands, 1); n = v.NumFrames; sh = nan(n, nb); tv = nan(n, 1);
prof = @(I, b) diff(mean(double(I(bands{b, 1}, bands{b, 2}, 2)), 1));
I = readFrame(v); ref = cell(nb, 1);
for b = 1:nb, ref{b} = prof(I, b); end
k = 0; v.CurrentTime = 0;
while hasFrame(v)
    k = k + 1; tv(k) = v.CurrentTime; I = readFrame(v);
    for b = 1:nb
        [c, lags] = xcorr(prof(I, b), ref{b}, 60);
        [~, i] = max(c); i = min(max(i, 2), numel(c) - 1);
        d = (c(i-1) - c(i+1))/(2*(c(i-1) - 2*c(i) + c(i+1)));
        sh(k, b) = lags(i) + d;
    end
end
sh = sh(1:k, :); tv = tv(1:k);
save('track.mat', 'sh', 'tv')
fprintf('frames %d, top shift range %.1f..%.1f px, base %.1f..%.1f, bg %.1f..%.1f\n', ...
    k, min(sh(:,1)), max(sh(:,1)), min(sh(:,2)), max(sh(:,2)), min(sh(:,3)), max(sh(:,3)));
