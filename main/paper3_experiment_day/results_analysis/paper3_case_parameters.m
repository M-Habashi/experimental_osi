function result = paper3_case_parameters
%PAPER3_CASE_PARAMETERS Recreate the Paper 3 case parameters and predictions.
% Uses only files inside this folder (saved_results/paper3_cases and the
% 16 Nov exp_tf snapshot used as the fit starting point). Prints the tables
% in docs/paper3_case_parameters.md and saves outputs/paper3_case_parameters.mat.
% Units: dd/dc/dm [mm], fm [N], k [N/m], m [kg], c [N*s/m], frequency [Hz].
package = fileparts(fileparts(mfilename('fullpath')));
data = fullfile(package, 'saved_results', 'paper3_cases');
id = load(fullfile(data, 'id_healthy_gain1_20261119_2009_t085_218s.mat')); id = id.result;
c1 = load(fullfile(data, 'case1_notch_off_gain3p5_20261119_2052.mat')); c1 = c1.result;
fem = load(fullfile(data, 'fem_numerical_rotation_fixed_damping10.mat')); fem = fem.fem;
lead = load(fullfile(data, 'lead_numerical_sp4_bandstop28hz.mat'));
nt = load(fullfile(data, 'notch_pid_35p3hz.mat')); nt = nt.result;
start = load(fullfile(package, 'saved_results', 'exp_tf', 'tf_sp4_20261116_130910.mat'), ...
    'beta1', 'beta2', 'a2', 'a3', 'Kp', 'Ki');
dt = id.dt; fs = id.fs; pv = lead.pid_values; g_case = 3.5;

%% 1) Healthy identification: dd as instrument (removes feedback bias)
x = detrend(id.dd); u = detrend(id.dc); y = detrend(id.dm); F = detrend(id.fm);
win = hann(8192); ov = 4096; nf = 8192;
[Sxu, f] = cpsd(x, u, win, ov, nf, fs); Sxy = cpsd(x, y, win, ov, nf, fs); Sxf = cpsd(x, F, win, ov, nf, fs);
H = conj(Sxy./Sxu); Z = conj(Sxf./Sxy)*1e3;      % cpsd returns conj(X)Y; Z [N/m]
cu = mscohere(x, u, win, ov, nf, fs); cy = mscohere(x, y, win, ov, nf, fs); cf = mscohere(x, F, win, ov, nf, fs);
w = 2*pi*f;

%% 2) Specimen m, c, k from Z = k - m w^2 + j c w, 2-50 Hz
s1 = f >= 2 & f <= 50 & cf > 0.8 & cy > 0.8;
mk = [ones(sum(s1),1) -w(s1).^2]\real(Z(s1)); k = mk(1); m = mk(2); c = w(s1)\imag(Z(s1));
zeta = c/(2*sqrt(m*k));

%% 3) Paper 1 actuator structure fitted to measured H, plus input delay
s2 = f >= 2 & f <= 70 & cy > 0.85 & cu > 0.85; wt = sqrt(cy(s2));
x0 = log([start.beta1 start.beta2 start.a2 start.a3 start.Kp start.Ki 0.005]);
opt = optimoptions('lsqnonlin', 'Display', 'off', 'MaxFunctionEvaluations', 2e4, 'MaxIterations', 2e3);
rng(1); best = x0; bestCost = inf;
for trial = 1:6
    [xh, cost] = lsqnonlin(@(q) fitError(q, m, c, k, w(s2), H(s2), wt), ...
        x0 + 0.3*randn(size(x0))*(trial > 1), [], [], opt);
    if cost < bestCost, bestCost = cost; best = xh; end
end
p = params(best); Hfit = actuatorH(p, m, c, k, w);
fitErr = abs(Hfit(s2) - H(s2))./abs(H(s2));

%% 4) Stiff critical gains from measured H and Z (10-70 Hz)
s3 = f >= 10 & f <= 70 & cy > 0.8 & cu > 0.8;
Cz = pid(pv.P, pv.I, pv.D, 1/pv.derivative_filter_N, dt, 'IFormula', 'ForwardEuler', 'DFormula', 'ForwardEuler');
Cv = resp(Cz, w); wn = 2*pi*nt.frequency_hz;
Nc = tf([1 2*nt.zeta_zero*wn wn^2], [1 2*nt.zeta_pole*wn wn^2]); Nz = c2d(Nc, dt, 'tustin'); Nv = resp(Nz, w);
PLv = resp(c2d(lead.common_phase_lead_tf, dt, 'tustin'), w); G = femCompliance(fem, w, dt);
Lout = Cv.*H; Lhs = Lout.*(1 - PLv.*G.*Z/1e3);
stiff = [boundary(f(s3), Lout(s3)), boundary(f(s3), Lout(s3).*Nv(s3)); ...
         boundary(f(s3), Lhs(s3)),  boundary(f(s3), Lhs(s3).*Nv(s3))];

%% 5) Paper 1 critical equation, Eq. (23)-(31), at the case gain
paper1 = zeros(2, 2);
for notch = 0:1
    Cg = g_case*pid(pv.P, pv.I, pv.D, 1/pv.derivative_filter_N); if notch, Cg = Cg*Nc; end
    [paper1(notch+1, 1), paper1(notch+1, 2)] = paper1Critical(p, Cg, m, k, zeta);
end

%% 6) Discrete closed loop versus residual stiffness alpha (Paper 1 scaling)
alpha = [1 .95 .9 .85 .8 .75 .7 .6 .5 .45 .4 .35 .3 .25 .2];
D = tf(1, [1 zeros(1, round(p.tau/dt))], dt); amap = zeros(2, numel(alpha), 2);
for notch = 0:1
    for j = 1:numel(alpha)
        Hd = c2d(tf([p.Kp p.Ki], actuatorDen(p, m, c*sqrt(alpha(j)), k*alpha(j))), dt, 'zoh')*D;
        L = g_case*Cz*Hd; if notch, L = L*Nz; end
        pz = pole(feedback(L, 1)); [amap(notch+1, j, 1), i] = max(abs(pz));
        amap(notch+1, j, 2) = abs(angle(pz(i)))/(2*pi*dt);
    end
end

%% 7) Case 1 measured onset (20-60 Hz dm envelope, numerical substructure active)
[b, a] = butter(3, [20 60]/(fs/2)); env = sqrt(movmean(filtfilt(b, a, c1.dm).^2, round(0.1*fs)));
active = c1.dd_pause_enable_log == 0; on = find(env > max(0.05, 5*median(env(active))) & active, 1);
ii = c1.t >= c1.t(on) & c1.t < c1.t(on) + 0.5; [Pw, Fw] = pwelch(detrend(c1.dm(ii)), [], [], 2^14, fs);
[~, jp] = max(Pw.*(Fw > 10 & Fw < 80));
[bl, al] = butter(2, 4/(fs/2)); dl = filtfilt(bl, al, c1.dm); fl = filtfilt(bl, al, c1.fm);
pre = c1.t >= c1.t(on) - 2 & c1.t < c1.t(on); slope = polyfit(dl(pre), fl(pre), 1);
case1 = struct('onset_s', c1.t(on), 'gain', c1.diagnostic_gain(on), 'frequency_hz', Fw(jp), ...
    'slope_N_per_mm', slope(1), 'alpha', slope(1)/(k/1e3));

%% 8) Measured run metrics, same definitions for every run
% Active window: abs(dd - dd(1)) above 2% of its peak (scale-invariant). Tracking band 0.02-10 Hz holds the
% earthquake content (time scale 20); its first 30 s exclude the start-up transient.
runs = {'case1_notch_off_gain3p5_20261119_2052', 'case2_notch_on_gain3p5_20261120_1035', ...
    'case3_notch_on_osi_on_gain3p5_20261120_1052', 'case4_notch_off_osi_on_gain3p5_20261120_1248', ...
    'stiff_notch_off_gain3p5_i0p075_20261120_1125', 'stiff_notch_on_gain3p5_i0p075_20261120_1142'};
[zb, pb, kb] = butter(2, [0.02 10]/(fs/2)); sb = zp2sos(zb, pb, kb);
[bo, ao] = butter(4, [30 50]/(fs/2)); [bs, as] = butter(4, 10/(fs/2));
bp = @(x) flipud(sosfilt(sb, flipud(sosfilt(sb, x))));
M = zeros(numel(runs), 11);
for n = 1:numel(runs)
    r = load(fullfile(data, [runs{n} '.mat'])); r = r.result;
    u = abs(r.dd - r.dd(1)); on = find(u > 0.02*max(u)); j = on(1):on(end); j30 = j(r.t(j) >= r.t(j(1)) + 30);
    e = r.dd - r.dm; eb = bp(e); db = bp(r.dd);
    osc = sqrt(movmean(filtfilt(bo, ao, r.dm).^2, round(fs)));
    dl = filtfilt(bs, as, r.dm); fl = filtfilt(bs, as, r.fm); L = 2*fs; ks = [];
    for s = j(1):L:j(end) - L
        q = s:s + L - 1; if range(dl(q)) > 0.15, pk = polyfit(dl(q), fl(q), 1); ks(end+1) = pk(1); end %#ok<AGROW>
    end
    a1 = find(r.auth(j) < 0.99, 1); [amin, ia] = min(r.auth(j));
    M(n, :) = [r.t(j(1)), 100*rms(e(j) - mean(e(j)))/rms(r.dd(j) - mean(r.dd(j))), ...
        100*rms(eb(j30))/rms(db(j30)), 100*rms(eb(j))/rms(db(j)), max(osc(j)), median(ks), min(ks), max(abs(r.dm(j) - r.dm(j(1)))), ...
        amin, r.t(j(ia)), NaN];
    if ~isempty(a1), M(n, 11) = r.t(j(a1)); end
end
runs_table = array2table(M, 'RowNames', runs, 'VariableNames', {'onset_s', 'track_raw_pct', ...
    'track_band_excl30_pct', 'track_band_all_pct', 'osc_30_50Hz_mm', 'slope_median_N_per_mm', 'slope_min_N_per_mm', ...
    'peak_dm_mm', 'auth_min', 'auth_min_t_s', 'auth_first_below_099_s'});

%% Report
fprintf('\nIdentification: %s, %.1f-%.1f s, fs %g Hz, Hann %d, overlap %d\n', ...
    'id_healthy_gain1_20261119_2009_t085_218s.mat', id.t(1), id.t(end), fs, nf, ov);
fprintf('Specimen: k %.0f N/mm, m %.1f kg, c %.0f N s/m, zeta %.3f\n', k/1e3, m, c, zeta);
fprintf('Actuator fit: beta1 %.4g, beta2 %.4g, a2 %.4g, a3 %.4g, Kp %.4g, Ki %.4g, tau %.2f ms; |err| median %.1f%%, max %.1f%%\n', ...
    p.beta1, p.beta2, p.a2, p.a3, p.Kp, p.Ki, 1e3*p.tau, 100*median(fitErr), 100*max(fitErr));
fprintf('Stiff critical gain [g @ Hz]: outer off %.2f @ %.1f, outer on %.2f @ %.1f | HS off %.2f @ %.1f, HS on %.2f @ %.1f\n', ...
    stiff(1,1:2), stiff(1,3:4), stiff(2,1:2), stiff(2,3:4));
fprintf('Paper 1 at g = %.1f: notch off alpha_cr %.3f @ %.1f Hz; notch on %.3f @ %.1f Hz\n', g_case, paper1(1,:), paper1(2,:));
fprintf('alpha      : %s\n', sprintf('%6.2f', alpha));
for notch = 0:1
    fprintf('notch %d |z|: %s\n        Hz : %s\n', notch, sprintf('%6.3f', amap(notch+1,:,1)), sprintf('%6.1f', amap(notch+1,:,2)));
end
fprintf('Case 1: onset %.2f s, gain %.2f, %.1f Hz, slope %.0f N/mm (alpha %.2f)\n', ...
    case1.onset_s, case1.gain, case1.frequency_hz, case1.slope_N_per_mm, case1.alpha);
disp(runs_table)

result = struct('specimen', struct('k_N_per_m', k, 'm_kg', m, 'c_Ns_per_m', c, 'zeta', zeta), ...
    'actuator', p, 'fit_error_median', median(fitErr), 'fit_error_max', max(fitErr), ...
    'stiff_critical_gain', array2table(stiff, 'VariableNames', {'g_off','f_off_hz','g_on','f_on_hz'}, 'RowNames', {'outer_only','hs'}), ...
    'paper1_gain', g_case, 'paper1_alpha_f', array2table(paper1, 'VariableNames', {'alpha_cr','f_cr_hz'}, 'RowNames', {'notch_off','notch_on'}), ...
    'alpha', alpha, 'alpha_map_abs_z', squeeze(amap(:,:,1)), 'alpha_map_hz', squeeze(amap(:,:,2)), ...
    'case1', case1, 'runs', runs_table, 'f_hz', f, 'H', H, 'Z_N_per_m', Z, 'coh_dm', cy, 'coh_dc', cu, 'coh_fm', cf);
save(fullfile(package, 'outputs', 'paper3_case_parameters.mat'), 'result');
end

function p = params(q)
q = exp(q); p = struct('beta1', q(1), 'beta2', q(2), 'a2', q(3), 'a3', q(4), 'Kp', q(5), 'Ki', q(6), 'tau', q(7));
end

function d = actuatorDen(p, m, c, k)
% Paper 1 analog model (as compare_sp4_degraded_identification.m).
q = [1 p.beta1 p.beta2]; d = conv([1 0], conv([1 p.a3], conv(q, [m c k])));
d(end-4:end) = d(end-4:end) + conv([p.a2 0 0], q); d(end-1:end) = d(end-1:end) + [p.Kp p.Ki];
end

function H = actuatorH(p, m, c, k, w)
s = 1i*w(:); H = polyval([p.Kp p.Ki], s)./polyval(actuatorDen(p, m, c, k), s).*exp(-s*p.tau);
end

function e = fitError(q, m, c, k, w, Hm, wt)
r = (actuatorH(params(q), m, c, k, w) - Hm)./abs(Hm).*wt; e = [real(r); imag(r)];
end

function v = resp(sys, w)
v = reshape(freqresp(sys, w), [], 1);
end

function G = femCompliance(fem, w, dt)
% Numerical interface displacement per measured force [mm/N], Newmark map.
fn = fem.num; ff = fn.floor_dofs; ii = fn.interface_dof; K = fn.K; M = fn.M(ff, ff);
Kc = K(ff, ff) - K(ff, ii)*K(ii, ff)/K(ii, ii);
[~, om2] = eig(fem.ref.K, fem.ref.M, 'vector'); om = sort(sqrt(om2));
ab = [1./(2*om(1:2)) om(1:2)/2]\(fem.damping.target_ratio*[1; 1]);
C = ab(1)*fem.ref.M + ab(2)*fem.ref.K; we = 2/dt*tan(w*dt/2); G = zeros(size(w));
for j = 1:numel(w)
    G(j) = 1000*((-K(ii, ff)/K(ii, ii))*((Kc - we(j)^2*M + 1i*we(j)*C)\(K(ff, ii)/K(ii, ii))) - 1/K(ii, ii));
end
end

function out = boundary(f, L)
% Smallest gain at which L crosses the negative real axis, and its frequency.
ix = find(imag(L(1:end-1)).*imag(L(2:end)) < 0); out = [inf NaN];
for j = ix(:)'
    u = -imag(L(j))/(imag(L(j+1)) - imag(L(j))); v = L(j) + u*(L(j+1) - L(j));
    if real(v) < 0 && -1/real(v) < out(1), out = [-1/real(v), f(j) + u*(f(j+1) - f(j))]; end
end
end

function [alpha_cr, f_cr] = paper1Critical(p, Cg, m, k, zeta)
% Paper 1: m w^2 - Re Y - (Im Y)^2/(4 zeta^2 m w^2) = 0; alpha = (Im Y)^2/(4 zeta^2 w^2 m k).
w = logspace(log10(2*pi), log10(2*pi*200), 40000).'; s = 1i*w;
Y = (p.a2*s + (p.Kp + p.Ki./s)./(s.^2 + p.beta1*s + p.beta2).*(resp(Cg, w).*exp(-s*p.tau) + 1))./(s + p.a3);
r = m*w.^2 - real(Y) - imag(Y).^2./(4*zeta^2*m*w.^2); ix = find(r(1:end-1).*r(2:end) < 0);
W = w(ix) - r(ix).*(w(ix+1) - w(ix))./(r(ix+1) - r(ix)); yW = interp1(w, Y, W);
a = imag(yW).^2./(4*zeta^2*W.^2*m*k); ok = a > 0 & a <= 1.5 & imag(yW) < 0;
fprintf('  Paper 1 roots: f %s Hz, alpha %s\n', mat2str(round(W.'/2/pi,1)), mat2str(round(a.',3)));
if ~any(ok), alpha_cr = NaN; f_cr = NaN; return, end
[alpha_cr, j] = max(a(ok)); Wk = W(ok); f_cr = Wk(j)/(2*pi);
end
