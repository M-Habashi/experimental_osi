function [cases, report] = design_robin_sweep(ns, opts, varargin)
%DESIGN_ROBIN_SWEEP Fixed and adaptive Robin tests that bracket the specimen stiffness.
%   [cases, report] = design_robin_sweep(ns)
%   [cases, report] = design_robin_sweep(ns, opts)
%   c = design_robin_sweep('pick', cases, design, ratio)
%       the case of design 'fixed' or 'adaptive' with the given ratio
%       (within 0.025; [] = the designed operator, 'fixed' with 0 =
%       conventional); stops if there is none or it is not admitted.
%
%   The identified stiffness depends on the estimator and the record window,
%   and the specimen softens during a strong test. The sweep tests Robin
%   stiffnesses at ratios r = K_R/k0 below and above the specimen stiffness,
%   so the tests show how a stiffness mismatch affects R-D coupling (an
%   experimental sensitivity study; Insam and Rixen 2022, Section 4.3):
%     fixed     K_R = r k0 for r = 0 (conventional), the design of
%               design_robin_fixed, opts.ratios, and opts.estimates/k0;
%     adaptive  the design of design_robin_adaptive with the stiffness at rest
%               K_cal eta_K = r k0, limited to [K_min, K_max], for the design
%               and opts.adaptive_ratios.
%   A fixed case is admitted when, on the pretest (rows of design_robin_fixed),
%     tau_cr(K_R) >= tau_cr(0) and >= opts.added_delay, the clearance for the
%     admitted tangent range is positive, and rho(K_R) >= min(rho(0), max|k - k0|),
%   i.e. it keeps the margin of conventional coupling or a margin above the
%   largest admitted tangent change (small-gain requirement). Conventional
%   coupling is the baseline and is always listed as admitted. An adaptive
%   case is admitted when gamma < 1; its bounds do not depend on K_cal.
%
%   Run order: conventional; then the design ratio and the other ratios,
%   farthest from the design first, each with its fixed and adaptive case back
%   to back; conventional again. Specimen drift then does not line up with r,
%   each fixed/adaptive pair sees the same specimen state, and the repeated
%   conventional test gives the run-to-run scatter. Rerun the white-noise
%   pretest between tests if the specimen may have yielded.
%
%   opts: ratios (K_R/k0; [0.3 1 1.4]), estimates ([ns.k_fit]; other
%   identified stiffnesses [N/m], tested as K_R), adaptive_ratios (K_cal
%   eta_K/k0; the fixed ratios), added_delay [s] (0), verbose (true), and the
%   options of design_robin_fixed and design_robin_adaptive. Ratios closer
%   than 0.025 are merged.
%   cases: struct array in run order with name, design ('fixed' or
%   'adaptive'), ratio, K_R [N/m] (fixed K_R, or the adaptive stiffness at
%   rest), override (step_HS_robin), margin, tau_cr, clearance, peak_EN (on
%   the pretest at K_R), admitted, is_design, and note.
%   report: K_R0, fixed (design_robin_fixed report), adaptive
%   (design_robin_adaptive report), adaptive_override, required_margin.

if ischar(ns)
    assert(strcmp(ns, 'pick'), 'design_robin_sweep:Mode', 'Unknown mode ''%s''.', ns)
    cases = pickCase(opts, varargin{:});
    return
end
if nargin < 2, opts = struct(); end
k0 = ns.k0;
tol = 0.025;
ratios = option(opts, 'ratios', [0.3 1 1.4]);
if isfield(opts, 'estimates'), estimates = opts.estimates; else, estimates = ns.k_fit; end
quiet = opts;
quiet.verbose = false;
quiet.K_max_grid = max([1.5; option(opts, 'K_max_factor', 1.25); ratios(:) + tol; ...
    estimates(:)/k0 + tol])*k0;
[K_R0, fixed_report] = design_robin_fixed(ns, quiet);
[adaptive_override, adaptive_report] = design_robin_adaptive(ns, K_R0, quiet);
r_design = K_R0/k0;

r_fixed = sweepRatios([ratios(:); estimates(:)/k0], r_design, tol);
r_adaptive = sweepRatios(option(opts, 'adaptive_ratios', r_fixed), r_design, tol);
r_all = sweepRatios([r_fixed; r_adaptive], r_design, tol);
[~, i] = sort(abs(r_all - r_design), 'descend');
r_run = [r_design; r_all(i)];

conv = fixed_report.conventional;
required = min(conv.margin, max(abs(fixed_report.admitted - k0)));
tau_req = max(conv.tau_cr, option(opts, 'added_delay', 0));
off = struct('eta_M', 0, 'eta_C', 0, 'eta_K', 0, 'adapt_M', false, 'adapt_K', false);

cases = fixedCase('conventional', 0, conv, off, true, false, 'baseline');
for r = r_run'
    is_design = r == r_design;
    if is_design || any(abs(r_fixed - r) <= tol)
        row = rowAt(fixed_report, r*k0);
        ok = row.tau_cr >= tau_req && row.clearance > 0 && ...
            row.margin >= required*(1 - 1e-9);
        override = struct('eta_M', 0, 'eta_C', 0, 'eta_K', 1, ...
            'adapt_M', false, 'adapt_K', false, 'K_cal', row.K_R);
        cases(end + 1) = fixedCase(caseName('fixed', r, is_design), r, row, ...
            override, ok, is_design, ''); %#ok<AGROW>
    end
    if is_design || any(abs(r_adaptive - r) <= tol)
        eta_K = adaptive_override.eta_K;
        K_rest = min(max(r*k0, adaptive_override.K_min), adaptive_override.K_max);
        override = adaptive_override;
        override.K_cal = K_rest/eta_K;
        row = rowAt(fixed_report, K_rest);
        note = '';
        if abs(K_rest - r*k0) > 1e-9*k0, note = 'limited to [K_min, K_max]'; end
        c = fixedCase(caseName('adaptive', r, is_design), r, row, override, ...
            adaptive_report.gamma < 1, is_design, note);
        c.design = 'adaptive';
        cases(end + 1) = c; %#ok<AGROW>
    end
end
cases(end + 1) = cases(1);
cases(end).name = 'conventional (repeat)';

report = struct('K_R0', K_R0, 'fixed', fixed_report, 'adaptive', adaptive_report, ...
    'adaptive_override', adaptive_override, 'required_margin', required, ...
    'required_tau_cr', tau_req);
if option(opts, 'verbose', true)
    fprintf('\nRobin test sweep from the pretest (k0 = %.3f kN/mm)\n', k0/1e6)
    fprintf(['  fixed design K_R = %.3f kN/mm (r = %.3f, %s); adaptive interval ' ...
        '[%.3f, %.3f] kN/mm, gamma %.3f\n'], K_R0/1e6, r_design, fixed_report.rule, ...
        adaptive_override.K_min/1e6, adaptive_override.K_max/1e6, adaptive_report.gamma)
    fprintf(['  admitted: tau_cr >= %.1f ms, clearance > 0, rho >= %.2f kN/mm ' ...
        '(tangents %.2f to %.2f kN/mm)\n'], 1e3*tau_req, required/1e6, ...
        fixed_report.admitted/1e6)
    fprintf('  %2s %-26s %6s %8s %8s %8s %8s %8s  %s\n', '#', 'case', 'r', 'K_R', ...
        'rho', 'tau_cr', 'clear.', 'max|EN|', 'admitted')
    fprintf('  %2s %-26s %6s %8s %8s %8s %8s %8s\n', '', '', '', '[kN/mm]', ...
        '[kN/mm]', '[ms]', '[kN/mm]', '[%]')
    for j = 1:numel(cases)
        c = cases(j);
        fprintf('  %2d %-26s %6.3f %8.3f %8.2f %8.1f %8.2f %8.1f  %s %s\n', j, c.name, ...
            c.ratio, c.K_R/1e6, c.margin/1e6, 1e3*c.tau_cr, c.clearance/1e6, ...
            100*c.peak_EN, yesNo(c.admitted), c.note)
    end
end
end

function c = pickCase(cases, design, ratio)
pick = find(strcmpi({cases.design}, design));
assert(~isempty(pick), 'design_robin_sweep:Design', ...
    'The Robin design must be ''fixed'' or ''adaptive''.')
if isempty(ratio)
    pick = pick([cases(pick).is_design]);
else
    [gap, j] = min(abs([cases(pick).ratio] - ratio));
    assert(gap <= 0.025, 'design_robin_sweep:Ratio', 'No %s case with ratio %.3f.', ...
        lower(design), ratio)
    pick = pick(j);
end
c = cases(pick(1));
assert(c.admitted, 'design_robin_sweep:NotAdmitted', ['Robin case "%s" fails the ' ...
    'pretest stability checks (sweep table); do not run it.'], c.name)
end

function r = sweepRatios(r, r_design, tol)
% Positive ratios, sorted, merged within tol, and not within tol of the design.
r = sort(r(:));
r = r(r > 0);
if isempty(r), return, end
r = r([true; diff(r) > tol]);
r = r(abs(r - r_design) > tol);
end

function row = rowAt(report, K)
% Pretest quantities of design_robin_fixed at the grid stiffness nearest K.
[~, i] = min(abs(report.K_grid - K));
row = report.rows(i);
end

function c = fixedCase(name, r, row, override, ok, is_design, note)
c = struct('name', name, 'design', 'fixed', 'ratio', r, 'K_R', row.K_R, ...
    'override', override, 'margin', row.margin, 'tau_cr', row.tau_cr, ...
    'clearance', row.clearance, 'peak_EN', row.peak_EN, 'admitted', ok, ...
    'is_design', is_design, 'note', note);
end

function s = caseName(kind, r, is_design)
s = sprintf('%s r=%.2f', kind, r);
if is_design, s = [s ' (design)']; end
end

function s = yesNo(b)
if b, s = 'yes'; else, s = 'NO'; end
end

function v = option(s, name, default)
if isfield(s, name) && ~isempty(s.(name)), v = s.(name); else, v = default; end
end
