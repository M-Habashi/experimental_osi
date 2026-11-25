function [K_R, report] = design_robin_fixed(ns, opts)
%DESIGN_ROBIN_FIXED Fixed (initial) Robin stiffness from the pretest alone.
%   [K_R, report] = design_robin_fixed(ns)
%   [K_R, report] = design_robin_fixed(ns, opts)
%
%   Nonlinear R-D paper, Section "Stability requirements and Robin-stiffness
%   design". For each constant K_R (M_R = C_R = 0) the measured nominal state
%   ns (robin_nominal_state) gives
%     - the critical time delay tau_cr from the delay crossings |L_R| = 1
%       (the measured T already contains the hardware delay, so tau_cr is
%       the time delay that can be added to the measured loop),
%     - the robust stability margin rho = min |dZ*| over the measured band,
%     - the circle-condition clearance for the admitted tangent range,
%   and the accuracy criterion of the linear R-D design,
%     max |E^N| over the design band, E^N = (Z_N + Z0)/(Z_N + K_R + T (Z0 - K_R)) - 1.
%   K_R minimizes max|E^N| subject to
%     (1) rho(K_R) >= rho(0)        (Robin must not lower the margin of
%                                    conventional coupling),
%     (2) tau_cr(K_R) >= tau_cr(0) and >= opts.added_delay (any delay
%         expected to be added to the measured loop),
%     (3) a positive clearance for the admitted tangent range.
%
%   opts: band [Hz] ([0.5 25]), admitted [N/m] ([0 1.3]*ns.k0), c_visc
%   [N*s/m] ([0 ns.c]), m [kg] (ns.m), added_delay [s] (0), K_max_grid [N/m]
%   (1.5*ns.k0), dK [N/m] (0.0025*ns.k0), verbose (true).
%   K_R [N/m]; report: grid values, the conventional loop, the unconstrained
%   minimizer, and the design.

if nargin < 2, opts = struct(); end
band = option(opts, 'band', [0.5 25]);
admitted = option(opts, 'admitted', [0 1.3]*ns.k0);
c_visc = option(opts, 'c_visc', [0 ns.c]);
m = option(opts, 'm', ns.m);
added_delay = option(opts, 'added_delay', 0);
K_grid = (0:option(opts, 'dK', 0.0025*ns.k0):option(opts, 'K_max_grid', 1.5*ns.k0))';

rows = arrayfun(@(K) evaluate(ns, K, band, admitted, c_visc, m), K_grid);
conv = rows(1);
ok = [rows.margin]' >= conv.margin*(1 - 1e-9) & ...
    [rows.tau_cr]' >= max(conv.tau_cr, added_delay) & [rows.clearance]' > 0;
assert(any(ok), 'design_robin_fixed:Infeasible', ['No Robin stiffness satisfies ' ...
    'the stability requirements. Conventional coupling: rho %.2f kN/mm, tau_cr %.1f ms, ' ...
    'clearance %.2f kN/mm for tangents %.2f to %.2f kN/mm. A negative clearance means ' ...
    'that the admitted tangent range is too wide for this loop, or that the transfer-system ' ...
    'model (force path) does not belong to the pretest.'], conv.margin/1e6, ...
    1e3*conv.tau_cr, conv.clearance/1e6, admitted(1)/1e6, admitted(2)/1e6)
peak = [rows.peak_EN]';
peak_ok = peak;
peak_ok(~ok) = Inf;
[~, i_design] = min(peak_ok);
[~, i_free] = min(peak);
K_R = K_grid(i_design);
report = struct('K_grid', K_grid, 'rows', rows, 'admissible', ok, ...
    'conventional', conv, 'unconstrained', rows(i_free), 'design', rows(i_design), ...
    'band', band, 'admitted', admitted, 'c_visc', c_visc, 'k0', ns.k0);
if option(opts, 'verbose', true)
    fprintf('\nFixed Robin stiffness from the pretest (k0 = %.3f kN/mm)\n', ns.k0/1e6)
    fprintf('  admitted tangent range %.2f to %.2f kN/mm, design band %.3g-%.3g Hz\n', ...
        admitted/1e6, band)
    fprintf('  %-26s %9s %9s %10s %10s %9s\n', '', 'K_R', 'rho', 'tau_cr', ...
        'clearance', 'max|EN|')
    fprintf('  %-26s %9s %9s %10s %10s %9s\n', '', '[kN/mm]', '[kN/mm]', '[ms]', ...
        '[kN/mm]', '[%]')
    show('conventional (K_R = 0)', conv)
    show('unconstrained minimizer', rows(i_free))
    show('design', rows(i_design))
end
end

function r = evaluate(ns, K, band, admitted, c_visc, m)
g = robin_loop(ns, K);
dz = 1./g.Gu;
mid = mean(admitted);
rad = diff(admitted)/2;
s = 2i*pi*ns.f;
clear_c = arrayfun(@(c) min(abs(dz + ns.Z0 - (m*s.^2 + c*s) - mid) - rad), c_visc);
in_band = ns.f >= band(1) & ns.f <= band(2);
EN = (ns.ZN + ns.Z0)./(ns.ZN + K + ns.T.*(ns.Z0 - K)) - 1;
r = struct('K_R', K, 'margin', min(abs(dz)), 'tau_cr', delayCrossing(ns.f, g.L), ...
    'softening', softening(ns.f, dz), 'clearance', min(clear_c), ...
    'peak_EN', max(abs(EN(in_band))));
end

function tau = delayCrossing(f, L)
% Critical time delay: smallest delay at a delay crossing |L| = 1 (Inf if none) [s].
a = abs(L);
j = find(diff(sign(a - 1)) ~= 0);
tau = Inf;
for i = j'
    x = (1 - a(i))/(a(i + 1) - a(i));
    fc = f(i) + x*(f(i + 1) - f(i));
    ph = angle(L(i) + x*(L(i + 1) - L(i)));
    tau = min(tau, mod(ph + pi, 2*pi)/(2*pi*fc));
end
end

function v = softening(f, dz)
% Negative real-axis crossing of dZ* nearest to zero above 10 Hz [N/m].
j = find(sign(imag(dz(1:end-1))) ~= sign(imag(dz(2:end))));
x = imag(dz(j))./(imag(dz(j)) - imag(dz(j + 1)));
fc = f(j) + x.*(f(j + 1) - f(j));
re = real(dz(j)) + x.*(real(dz(j + 1)) - real(dz(j)));
v = max(re(re < 0 & fc >= 10));
if isempty(v), v = -Inf; end
end

function show(label, r)
fprintf('  %-26s %9.3f %9.2f %10.1f %10.2f %9.1f\n', label, r.K_R/1e6, ...
    r.margin/1e6, 1e3*r.tau_cr, r.clearance/1e6, 100*r.peak_EN)
end

function v = option(s, name, default)
if isfield(s, name) && ~isempty(s.(name)), v = s.(name); else, v = default; end
end
