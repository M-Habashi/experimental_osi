function [override, report] = design_robin_adaptive(ns, K_R0, opts)
%DESIGN_ROBIN_ADAPTIVE Settings of the adaptive Robin stiffness from the pretest.
%   [override, report] = design_robin_adaptive(ns, K_R0)
%   [override, report] = design_robin_adaptive(ns, K_R0, opts)
%
%   Nonlinear R-D paper, Section "Stability requirements and Robin-stiffness
%   design", for the update law of step_HS_robin (regularized affine EW-LS
%   slope scaled by eta_K and limited to [K_min, K_max]):
%     eta_K = 1        K_R follows the estimated stiffness;
%     K_cal = K_R0/eta_K   the law returns to the fixed design K_R0
%                      (design_robin_fixed) whenever the motion is small;
%     K_max = 1.25 k0  not narrowed for stability;
%     K_min            smallest value for which the scaled small-gain
%                      condition holds (gamma < 1) for the admitted tangent
%                      range, or 0 if it holds without a lower bound.
%   gamma is the peak over frequency of the largest singular value of the
%   scaled 2x2 loop of the tangent and Robin-stiffness channels (Eq.
%   mixed_condition), evaluated at the parametric nominal m s^2 + c s + k_mid
%   reached from the measured state, minimized over the channel scaling, and
%   maximized over the viscous damping c in opts.c_visc. The report also
%   gives the smallest |1 + L_R| along the path from the measured to the
%   parametric nominal state (no root crossing when it stays above zero).
%
%   opts: eta_K (1), K_max_factor (1.25), admitted [N/m] ([0 1.3]*ns.k0),
%   c_visc [N*s/m] ([0 ns.c]), m [kg] (ns.m), tol [N/m] (0.0025*ns.k0),
%   verbose (true).
%   override: fields for step_HS_robin('params', ..., override), adaptive.

if nargin < 3, opts = struct(); end
eta_K = option(opts, 'eta_K', 1);
K_max = option(opts, 'K_max_factor', 1.25)*ns.k0;
admitted = option(opts, 'admitted', [0 1.3]*ns.k0);
c_visc = option(opts, 'c_visc', [0 ns.c]);
m = option(opts, 'm', ns.m);
tol = option(opts, 'tol', 0.0025*ns.k0);

gam = @(K_min) gammaWorst(ns, admitted, K_min, K_max, c_visc, m);
gamma_zero = gam(0);
if gamma_zero < 1
    K_min = 0;
else
    a = 0;
    b = K_R0;
    assert(gam(b) < 1, 'design_robin_adaptive:Infeasible', ...
        'gamma >= 1 for every lower bound up to the fixed design K_R0.')
    while b - a > tol
        c = (a + b)/2;
        if gam(c) < 1, b = c; else, a = c; end
    end
    K_min = b;
end
gamma_design = gam(K_min);
path = pathMin(ns, admitted, K_min, K_max, c_visc, m);

override = struct('eta_M', 0, 'eta_C', 0, 'eta_K', eta_K, ...
    'adapt_M', false, 'adapt_K', true, 'K_cal', K_R0/eta_K, ...
    'K_min', K_min, 'K_max', K_max, 'M0', ns.m, 'C0', ns.c, ...
    'M_phys', [0.65 1.35]*ns.m, 'M_bounds', [1 1]*ns.m);
report = struct('gamma', gamma_design, 'gamma_without_lower_bound', gamma_zero, ...
    'path_min_abs_1_plus_L', path, 'admitted', admitted, 'c_visc', c_visc, 'k0', ns.k0);
if option(opts, 'verbose', true)
    fprintf('\nAdaptive Robin stiffness from the pretest (k0 = %.3f kN/mm)\n', ns.k0/1e6)
    fprintf('  eta_K = %.3g, K_cal = %.3f kN/mm (stiffness at rest)\n', eta_K, K_R0/eta_K/1e6)
    fprintf('  interval [K_min, K_max] = [%.3f, %.3f] kN/mm\n', K_min/1e6, K_max/1e6)
    fprintf('  gamma = %.3f for tangents %.2f to %.2f kN/mm (%.3f without a lower bound)\n', ...
        gamma_design, admitted/1e6, gamma_zero)
    fprintf('  min |1 + L_R| along the path to the parametric nominal state = %.3f\n', path)
end
end

function g = gammaWorst(ns, admitted, K_lo, K_hi, c_visc, m)
s = 2i*pi*ns.f;
r1 = diff(admitted)/2;
r2 = max((K_hi - K_lo)/2, 1);
sd = (1 - exp(-s*ns.dt))/ns.dt;                % sampled difference of d/dt
g = -Inf;
for c = c_visc
    L = robin_loop(ns, (K_lo + K_hi)/2, m*s.^2 + c*s + mean(admitted) - ns.Z0);
    peak = @(ld) max(sigmaMax(r1*L.Gu, exp(ld)*r2*sd.*L.Guw, ...
        r1*L.Gep./(sd*exp(ld)), r2*L.Gew));
    [~, val] = fminbnd(peak, -30, 30);
    g = max(g, val);
end
end

function s = sigmaMax(a, b, c, d)
% Largest singular value of [a b; c d] at each frequency.
q = abs(a).^2 + abs(b).^2 + abs(c).^2 + abs(d).^2;
s = sqrt((q + sqrt(max(q.^2 - 4*abs(a.*d - b.*c).^2, 0)))/2);
end

function p = pathMin(ns, admitted, K_lo, K_hi, c_visc, m)
% Smallest |1 + L_R| for blends of the measured and parametric dynamic parts,
% specimen stiffnesses from the lower admitted tangent to k0, and K_R in the interval.
s = 2i*pi*ns.f;
p = Inf;
for c = c_visc
    for q = linspace(0, 1, 6)
        for k = linspace(admitted(1), max(ns.k0, admitted(1)), 9)
            for K = linspace(K_lo, K_hi, 11)
                L = robin_loop(ns, K, q*(m*s.^2 + c*s + ns.k0 - ns.Z0) + k - ns.k0);
                p = min(p, min(abs(1 + L.L)));
            end
        end
    end
end
end

function v = option(s, name, default)
if isfield(s, name) && ~isempty(s.(name)), v = s.(name); else, v = default; end
end
