function out = vrths_robin(ns, hs, prm, cases, opts)
%VRTHS_ROBIN Virtual RTHS of conventional and Robin-Dirichlet coupling from the pretest.
%   out = vrths_robin(ns, hs, prm, cases)
%   out = vrths_robin(ns, hs, prm, cases, opts)
%
%   ns     robin_nominal_state of the pretest (test configuration).
%   hs     time [s], ag [m/s^2], time_scale_factor of the test.
%   prm    step_HS_robin('params', ...) of the test (numerical substructure).
%   cases  struct array with fields name and override (step_HS_robin
%          parameter fields applied to prm); eta_M = eta_C = eta_K = 0 with
%          adapt_K = false is conventional coupling.
%   opts   duration [s] (record length + 5 s), fit_band [Hz] ([0.3 8]),
%          k_factor (1; scales the specimen stiffness, e.g. 0.5 for a
%          softened specimen), divergence_mm (50).
%
%   Tracking: a gain, a delay, and a second-order low-pass fitted over
%   fit_band to the measured tracking ns.T of the test configuration (lead
%   filter and command gain included); it is valid in the response band.
%   Stability above that band follows from the pretest conditions of
%   design_robin_fixed and design_robin_adaptive (measured up to 80 Hz).
%   Specimen: linear, ns.m a + ns.c v + k_factor ns.k0 u. Reference: the
%   numerical substructure with the same specimen, integrated as one
%   structure (Robin operator equal to the specimen, zero residual).
%   out.<case>: J_N [%] (RMS of u_I^N - u_ref over RMS of u_ref), J_floors
%   [%], peak_mm, diverged, and the histories; out.tracking: fitted model.

if nargin < 5, opts = struct(); end
dt = prm.dt;
fs = 1/dt;
duration = option(opts, 'duration', hs.time(end)*hs.time_scale_factor + 5);
fit_band = option(opts, 'fit_band', [0.3 8]);
k_factor = option(opts, 'k_factor', 1);
limit = option(opts, 'divergence_mm', 50);
n = round(duration/dt);
ag = interp1(hs.time, hs.ag, (1:n)'*dt/hs.time_scale_factor, 'linear', 0);
m = ns.m; c = ns.c; k = k_factor*ns.k0;

%% Tracking model fitted to the measured tracking of the test configuration
band = ns.f >= fit_band(1) & ns.f <= fit_band(2);
f = ns.f(band);
target = ns.T(band);
z = exp(2i*pi*f*dt);
model = @(x) trackingModel(x, fs);
response = @(x) freqOf(model(x), z);
residual = @(x) [real(response(x) - target); imag(response(x) - target)];
x = lsqnonlin(residual, [1 0.02 15 0.7], [0.5 1/fs 2 0.1], ...
    [1.5 0.1 300 10], optimoptions('lsqnonlin', 'Display', 'off'));
tm = model(x);
out.tracking = struct('gain', x(1), 'delay_s', x(2), 'f_n_hz', x(3), ...
    'zeta', x(4), 'max_error', max(abs(response(x) - target)), 'band_hz', fit_band);

%% Reference structure
prm_ref = prm;
[prm_ref.M0, prm_ref.C0, prm_ref.K_cal] = deal(m, c, k);
[prm_ref.eta_M, prm_ref.eta_C, prm_ref.eta_K] = deal(1, 1, 1);
[prm_ref.adapt_M, prm_ref.adapt_K] = deal(false);
state = step_HS_robin('state', prm_ref);
u_ref = zeros(n, 1);
x_ref = zeros(n, prm.n);
for j = 1:n
    [u_ref(j), state] = step_HS_robin(0, 0, 0, 0, ag(j), NaN, state, prm_ref);
    x_ref(j, :) = state.x(1:prm.n)';
end
out.reference = struct('u_mm', u_ref, 'x_m', x_ref, 'peak_mm', max(abs(u_ref)));
rms_ratio = @(a, b) 100*sqrt(mean((a - b).^2))/sqrt(mean(b.^2));

%% Hybrid loops
for i = 1:numel(cases)
    p = prm;
    names = fieldnames(cases(i).override);
    for j = 1:numel(names)
        p.(names{j}) = cases(i).override.(names{j});
    end
    state = step_HS_robin('state', p);
    hist = zeros(tm.d + 2, 1);                % past u_I^N [m], most recent first
    zi = zeros(max(numel(tm.a), numel(tm.b)) - 1, 1);
    [u_prev, u_prev2] = deal(0);
    [u_n, u_m, K_R] = deal(NaN(n, 1));
    x_n = NaN(n, prm.n);
    diverged = false;
    for j = 1:n
        [um, zi] = filter(tm.b, tm.a, (1 - tm.fr)*hist(tm.d) + tm.fr*hist(tm.d + 1), zi);
        vm = (um - u_prev)/dt;
        am = (um - 2*u_prev + u_prev2)/dt^2;
        fm = m*am + c*vm + k*um;
        [dd, state] = step_HS_robin(fm, um, vm, am, ag(j), NaN, state, p);
        hist = [dd/1000; hist(1:end-1)];
        [u_n(j), u_m(j), K_R(j)] = deal(dd, 1000*um, state.K_R);
        x_n(j, :) = state.x(1:prm.n)';
        [u_prev2, u_prev] = deal(u_prev, um);
        if ~isfinite(dd) || abs(dd) > limit
            diverged = true;
            break
        end
    end
    r = struct('u_n_mm', u_n, 'u_m_mm', u_m, 'K_R', K_R, 'x_m', x_n, ...
        'diverged', diverged, 'peak_mm', max(abs(u_n)));
    if ~diverged
        r.J_N = rms_ratio(u_n, u_ref);
        r.J_floors = arrayfun(@(q) rms_ratio(x_n(:, q), x_ref(:, q)), 1:prm.n);
        r.J_P = rms_ratio(u_m, u_ref);
    end
    out.(matlab.lang.makeValidName(cases(i).name)) = r;
end
if option(opts, 'verbose', true)
    fprintf('\nvRTHS (tracking: gain %.3f, delay %.1f ms, low-pass %.0f Hz/%.2f; specimen k = %.3f kN/mm)\n', ...
        x(1), 1e3*x(2), x(3), x(4), k/1e6)
    fprintf('  reference peak u_I %.3f mm\n', out.reference.peak_mm)
    for i = 1:numel(cases)
        r = out.(matlab.lang.makeValidName(cases(i).name));
        if r.diverged
            fprintf('  %-12s DIVERGED (|u_I^N| > %g mm)\n', cases(i).name, limit)
        else
            fprintf('  %-12s bounded: peak u_I^N %.3f mm, J_N %.1f%%, floors %.1f-%.1f%%\n', ...
                cases(i).name, r.peak_mm, r.J_N, min(r.J_floors), max(r.J_floors))
        end
    end
end
end

function tm = trackingModel(x, fs)
wn = 2*pi*x(3);
[b, a] = bilinear(x(1)*wn^2, [1 2*x(4)*wn wn^2], fs);
d = floor(x(2)*fs);
tm = struct('b', b, 'a', a, 'd', max(d, 1), 'fr', x(2)*fs - d);
if d < 1, tm.fr = 0; end
end

function H = freqOf(tm, z)
H = polyval(tm.b, z)./polyval(tm.a, z).*z.^(-(tm.d + tm.fr));
end

function v = option(s, name, default)
if isfield(s, name) && ~isempty(s.(name)), v = s.(name); else, v = default; end
end
