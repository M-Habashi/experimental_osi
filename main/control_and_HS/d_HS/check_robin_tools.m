%% CHECK THE ROBIN-DIRICHLET ANALYSIS TOOLS
% Run once after updating the branch (R2020b or later).
% 1) replay_hs_robin reproduces a recorded Robin-Dirichlet test: the
%    replayed u_I^N through the lead filter must equal the logged command.
% 2) recompute_numerical_sub_response and compare_hs_response_to_reference
%    run on that test with the Robin replay and the hybrid reference.
% 3) vrths_robin runs on a small synthetic pretest (a linear specimen
%    tracked through a 27 ms delay), and conventional coupling with zero
%    Robin operator equals step_HS.
% 4) main_ColumnSetup picks the requested sweep case and refuses cases that
%    fail the pretest checks.

clearvars -except test_file_override
script_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(fileparts(script_dir));
addpath(project_root);
addpaths();
test_file = fullfile(project_root, 'saved_results', 'tests', '20261118', ...
    'tao-tests-20261120', '20261120_1623_Tao_Adaptive.mat');
if exist('test_file_override', 'var'), test_file = test_file_override; end

%% 1-2) Recorded adaptive test of 20 Nov 2026
if isfile(test_file)
    S = load(test_file);
    r = S.result;
    prm = robin_params_of_result(r, r.hs, project_root);
    assert(~isempty(prm), 'The test should use the Robin-Dirichlet block.')
    replay = replay_hs_robin(r, r.hs, prm);
    [~, lead_name] = fileparts(r.phase_lead_name);
    lead = load(fullfile(project_root, 'saved_results', 'phase_lead', ...
        [lead_name '.mat']));
    lead_tf = lead.phase_lead_tf;
    if isfield(lead, 'common_phase_lead_tf'), lead_tf = lead.common_phase_lead_tf; end
    [num, den] = tfdata(c2d(lead_tf, prm.dt, 'tustin'), 'v');
    dd = filter(num, den, replay.d_n_mm);
    active = replay.pause_enable == 0;
    logged = r.dd(:);
    err = max(abs(dd(active) - logged(active)));
    fprintf('Replay: max |lead(u_I^N) - logged dd| = %.3e mm; K_R %.3f to %.3f kN/mm\n', ...
        err, min(replay.K_R(active))/1e6, max(replay.K_R(active))/1e6)
    assert(err < 1e-6, 'The replay does not reproduce the logged command.')
    sub = recompute_numerical_sub_response(r);
    assert(sub.robin && max(abs(sub.d_n_mm - replay.d_n_mm(1:numel(sub.d_n_mm)))) < 1e-12)
    metric_table = compare_hs_response_to_reference(r.hs.fem, r, [], [], [], [], ...
        struct('plot', false));
    disp(metric_table)
else
    fprintf('Recorded test not found (%s); replay check skipped.\n', test_file)
end

%% 3) Synthetic pretest and vRTHS
fem = loadFemDefinition(project_root, false, fullfile(project_root, ...
    'saved_results', 'fem', 'fem_sp3_1o_roller.mat'));
hs = build_hs_model(fem, 'el_centro', 0.25, 1, 1, project_root);
dt = 1/2048;
specimen = struct('mass', 36, 'damping', 2000, 'stiffness', 6.8e6);
prm = step_HS_robin('params', hs, dt, specimen, struct('eta_M', 0, ...
    'eta_C', 0, 'eta_K', 0, 'adapt_M', false, 'adapt_K', false));
x = [];
s = step_HS_robin('state', prm);
rng(1)
err0 = 0;
for j = 2:2000
    fm = 1e3*randn;
    [d1, x] = step_HS(fm, 0, dt, hs, x);
    [d2, s] = step_HS_robin(fm, 0, 0, 0, 0, NaN, s, prm);
    err0 = max(err0, abs(d1 - d2));
end
assert(err0 < 1e-9, 'Zero Robin operator differs from step_HS.')
f = (0.5:0.0125:80)';
z = exp(2i*pi*f*dt);
s_ = 2i*pi*f;
ns = struct('f', f, 'T', exp(-s_*0.027), 'Tg', exp(-s_*0.027), ...
    'C0', zeros(size(f)), 'Z0', specimen.mass*s_.^2 + specimen.damping*s_ + specimen.stiffness, ...
    'ZN', zeros(size(f)), 'k0', specimen.stiffness, 'm', specimen.mass, ...
    'c', specimen.damping, 'dt', dt);
cases = struct('name', {'conventional', 'fixed'}, 'override', ...
    {struct(), struct('eta_K', 1, 'K_cal', 0.9*specimen.stiffness)});
out = vrths_robin(ns, hs, prm, cases, struct('duration', 20));
assert(~out.conventional.diverged && ~out.fixed.diverged)
assert(out.tracking.max_error < 0.05, 'The tracking fit should match a pure delay.')

%% 4) Choice of a sweep case in main_ColumnSetup (design_robin_sweep 'pick')
c = struct('name', {'conventional', 'fixed r=0.60 (design)', 'adaptive r=0.60 (design)', ...
    'fixed r=1.40'}, 'design', {'fixed', 'fixed', 'adaptive', 'fixed'}, ...
    'ratio', {0, 0.6, 0.6, 1.4}, 'admitted', {true, true, true, false}, ...
    'is_design', {false, true, true, false});
assert(strcmp(pickName(c, 'fixed', []), 'fixed r=0.60 (design)'))
assert(strcmp(pickName(c, 'Adaptive', []), 'adaptive r=0.60 (design)'))
assert(strcmp(pickName(c, 'fixed', 0), 'conventional'))
assert(strcmp(pickName(c, 'fixed', 0.61), 'fixed r=0.60 (design)'))
for bad = {{'fixed', 1.4, 'NotAdmitted'}, {'adaptive', 1.0, 'Ratio'}, {'robin', [], 'Design'}}
    try
        pickName(c, bad{1}{1}, bad{1}{2});
        error('check:NoError', 'pick should have stopped.')
    catch e
        assert(strcmp(e.identifier, ['design_robin_sweep:' bad{1}{3}]), e.message)
    end
end
fprintf('All checks passed.\n')

function name = pickName(cases, design, ratio)
picked = design_robin_sweep('pick', cases, design, ratio);
name = picked.name;
end
