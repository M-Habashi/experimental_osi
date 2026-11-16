% Logged dm [m] at 100 Hz on lab time [s] plus earthquake-active flag for
% candidate tests, so the camera motion can be matched to one of them.
d = 'C:\Users\BOWN1111PC1\Documents\Mohamed\experimental_osi\main\saved_results\tests\20261111';
names = {'20261111_1851_testing_OSI', 'sp3_r_2', 'sp3_r_1', '20261111_1657_testing_OSI', '20261111_1619_testing_OSI'};
c = struct();
for i = 1:numel(names)
    s = load(fullfile(d, [names{i} '.mat']), 'result'); r = s.result;
    k = 1:round(r.fs/100):numel(r.t);
    c(i).name = names{i}; c(i).t = r.t(k); c(i).dm = r.dm(k); c(i).fm = r.fm(k);
    c(i).eq = r.dd_pause_enable_log(k) == 0; c(i).start = r.runStartTime;
    fprintf('%s: %.1f s, eq %.1f..%.1f s, dm %.1f..%.1f mm, start %s\n', names{i}, r.t(end), ...
        min(c(i).t(c(i).eq)), max(c(i).t(c(i).eq)), 1e3*min(r.dm), 1e3*max(r.dm), string(r.runStartTime));
end
save('candidates.mat', 'c')
