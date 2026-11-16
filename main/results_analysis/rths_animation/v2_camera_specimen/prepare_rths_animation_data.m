function prepare_rths_animation_data(result_file, out_file)
%PREPARE_RTHS_ANIMATION_DATA Replay the numerical substructure from logged fm
% and sample every DOF, hinge and trace on the earthquake (record) clock.
% Units: time [s, earthquake record], displacement [m] (states) / [mm]
% (traces), force [N], ag [g], rotations [rad].
main_dir = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(fullfile(main_dir, 'control_and_HS', 'd_HS', 'utils_HS'))
addpath(fullfile(main_dir, 'results_analysis'))
s = load(result_file, 'result'); r = s.result;
hs = r.hs; dt = r.dt; fs = r.fs; tsf = hs.time_scale_factor;
pe = r.dd_pause_enable_log(:); fm = r.fm(:); n = numel(fm);
[b, a] = butter(4, 4/(fs/2), 'low'); % 4 Hz lab = 80 Hz earthquake time
dm_f = filtfilt(b, a, r.dm(:) - r.dm(1)) + r.dm(1);
fm_f = filtfilt(b, a, fm - fm(1)) + fm(1);

cfg = prepare_hs_nonlinear(hs, dt, 'num');
nd = size(cfg.K, 1); nh = numel(cfg.Mp); nf = hs.n_floor;
fps = 30; trace_hz = 200;
tau_end = sum(pe == 0)*dt/tsf;
nt = floor(tau_end*trace_hz) + 1; nk = floor(tau_end*fps) + 1;
tr = struct('tau', (0:nt-1)'/trace_hz, 'dn', zeros(nt, 1), ...
    'dd_log', zeros(nt, 1), 'dm', zeros(nt, 1), 'fm', zeros(nt, 1), ...
    'u', zeros(nt, nf), 'acc', zeros(nt, nf), 'lab_t', zeros(nt, 1));
fr = struct('tau', (0:nk-1)'/fps, 'x', zeros(nk, nd), 'p', zeros(nk, nh), ...
    'dn', zeros(nk, 1), 'dm', zeros(nk, 1), 'fm', zeros(nk, 1), ...
    'lab_t', zeros(nk, 1));
first_plastic = nan(nh, 1); first_yield = nan(nh, 1);
first_run = find(pe == 0, 1) - 1;
state = []; it = 1; ik = 1; tau = 0; fails = 0; dn = 0;
x = zeros(nd, 1); p = zeros(nh, 1); acc = zeros(nf, 1);
for step = 1:n
    if step > 1
        [dn, state, ok] = step_HS_nonlinear(fm(step), pe(step), cfg, state);
        fails = fails + ~ok;
        x = state(1:nd); p = state(3*nd+(1:nh)); tau = state(3*nd+nh+1);
        acc = state(2*nd+(1:nf));
        hit = isnan(first_plastic) & abs(p) > 1e-10; first_plastic(hit) = tau;
        hit = isnan(first_yield) & abs(cfg.DB*x - cfg.D*p) >= cfg.My;
        first_yield(hit) = tau;
    end
    if step < first_run, continue; end % sample from the earthquake start only
    while it <= nt && tau >= tr.tau(it)
        tr.dn(it) = dn; tr.dd_log(it) = r.dd(step); tr.dm(it) = dm_f(step);
        tr.fm(it) = fm_f(step); tr.u(it, :) = x(1:nf)'; tr.acc(it, :) = acc';
        tr.lab_t(it) = r.t(step); it = it + 1;
    end
    while ik <= nk && tau >= fr.tau(ik)
        fr.x(ik, :) = x'; fr.p(ik, :) = p'; fr.dn(ik) = dn;
        fr.dm(ik) = dm_f(step); fr.fm(ik) = fm_f(step); fr.lab_t(ik) = r.t(step);
        ik = ik + 1;
    end
end
tr = trimStruct(tr, it - 1); fr = trimStruct(fr, ik - 1);
ag = interp1(hs.time, hs.ag, tr.tau, 'linear', 0);
fem = hs.fem.num;
tr.ag_g = ag/9.80665;
tr.base_shear = hs_base_shear(hs.M, fem.influence(fem.floor_dofs), tr.acc, ag);
fr.base_shear = interp1(tr.tau, tr.base_shear, fr.tau, 'linear', 'extrap');
fr.ag_g = interp1(tr.tau, tr.ag_g, fr.tau, 'linear', 'extrap');
fr.moment = (cfg.DB*fr.x' - cfg.D*fr.p')';
ag_full = struct('tau', hs.time, 'ag_g', hs.ag/9.80665);
meta = struct('testname', r.testname, 'file', r.file, ...
    'runStartTime', r.runStartTime, 'earthquake', hs.earthquake_type, ...
    'intensity', hs.intensity_factor, 'tsf', tsf, 'fps', fps, ...
    'trace_hz', trace_hz, 'fails', fails, 'model', hs.structural_model, ...
    'rms_dn_vs_logged_mm', sqrt(mean((tr.dn - tr.dd_log).^2)));
model = struct('frame', fem.frame, 'h_exp', fem.experimental_column.height, ...
    'assembly', rmfield(fem.assembly, 'K_full'), 'labels', {cfg.labels}, ...
    'My', cfg.My, 'Mp', cfg.Mp, 'first_plastic', first_plastic, ...
    'first_yield', first_yield);
save(out_file, 'tr', 'fr', 'meta', 'model', 'ag_full')
fprintf('frames %d, traces %d, tau_end %.3f s, fails %d, RMS(dn replay - dd logged) %.4f mm\n', ...
    numel(fr.tau), numel(tr.tau), tr.tau(end), fails, meta.rms_dn_vs_logged_mm);
fprintf('plastic hinges %d of %d, first at %.3f s\n', sum(~isnan(first_plastic)), nh, min(first_plastic));
end

function s = trimStruct(s, n)
for f = fieldnames(s)'
    s.(f{1}) = s.(f{1})(1:n, :);
end
end
