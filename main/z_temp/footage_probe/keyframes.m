load calib.mat; load candidates.mat; r = c(2); load track.mat
dmv = interp1(r.t, r.dm, (tv - b)/a); [~, i] = max(abs(dmv)); fprintf('peak dm %.2f mm at video %.2f s\n', dmv(i), tv(i));
v = VideoReader('C:\Users\BOWN1111PC1\Downloads\experiment_video.MOV');
v.CurrentTime = 1; I0 = readFrame(v); v.CurrentTime = tv(i); I1 = readFrame(v);
imwrite(I0, 'rest_full.png'); imwrite(I1, 'peak_full.png');
imwrite([I0(1:700, 250:1080, :), I1(1:700, 250:1080, :)], 'top_pair.png');
imwrite(imresize([I0(1300:1700, :, :); I1(1300:1700, :, :)], 0.6), 'base_pair.png');
d = abs(double(I1) - double(I0)); imwrite(uint8(min(255, 3*sum(d, 3)/3)), 'diff.png');
