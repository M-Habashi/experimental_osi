%% PREPARE A ROBIN-DIRICHLET TEST FROM THE PRETEST OF A NEW SPECIMEN
% Order of the day for a new specimen:
%   1. Pretest: band-limited white noise on the PID reference dd, specimen
%      attached, HS off, command gain 1 (main_ColumnSetup.m test signal).
%   2. create_specimen_mat.m on the pretest      -> saved_results/specimens
%   3. sys_id.m on the pretest (with that specimen file) -> saved_results/exp_tf
%   4. build_fem_3.m with the new specimen file (5% Rayleigh damping by
%      default; damping_ratio_override to change it) -> saved_results/fem
%   5. This script: measured nominal state, fixed and adaptive Robin design
%      (nonlinear R-D paper), the sweep of fixed and adaptive Robin tests
%      (design_robin_sweep; K_R/k0 below and above the identified stiffness,
%      including the specimen-file and 2-50 Hz fit stiffnesses), and a vRTHS
%      of every sweep case. Run only admitted cases that do not diverge.
%   6. main_ColumnSetup.m with fem_file, exp_tf_file, robin_specimen_file,
%      robin_pretest_file (+ window, gain), robin_design, and robin_ratio of
%      the sweep case. It recomputes the same design at start-up.
% Units: SI unless stated; displacements in the records are in mm.

clearvars -except prepare_overrides
script_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(fileparts(script_dir));
addpath(project_root);
addpaths();

%% INPUTS (file names under saved_results/<folder>)
pretest_file = '';            % tests/<date>/<pretest>.mat (white noise, gain 1)
pretest_window = [];          % [t0 t1] s of its stationary part; [] = all
pretest_gain = 1.0;           % command gain during the pretest
specimen_file = '';           % specimens/<new specimen>.mat (create_specimen_mat)
exp_tf_file = '';             % exp_tf/<model>.mat (sys_id on the pretest)
fem_file = '';                % fem/<model>.mat (build_fem_3, new specimen)
phase_lead_file = 'pl_sp4_codesign.mat';   % phase_lead/<file> of the test
command_gain = 2.0;           % command gain of the test
earthquake_type = 'el_centro';
intensity_factor = 0.25;
time_scale_factor = 1.0;
force_sign = 1.0;
admitted = [];                % tangent range admitted before the test [N/m]; [] = [0 1.3]*k0
ratios = [0.3 1 1.4];         % fixed K_R/k0 of the sweep besides 0, the design, and the estimates
if exist('prepare_overrides', 'var')  % struct of the inputs above (scripted runs)
    names = fieldnames(prepare_overrides);
    for i = 1:numel(names), eval([names{i} ' = prepare_overrides.(names{i});']); end
end

assert(~isempty(pretest_file) && ~isempty(specimen_file) && ...
    ~isempty(exp_tf_file) && ~isempty(fem_file), ...
    'Set pretest_file, specimen_file, exp_tf_file, and fem_file.')
saved = @(folder, name) savedFile(project_root, folder, name);
dt = 1/2048;

%% MODELS OF THE TEST
fem = loadFemDefinition(project_root, false, saved('fem', fem_file));
hs = build_hs_model(fem, earthquake_type, intensity_factor, ...
    time_scale_factor, force_sign, project_root);
specimen_si = specimen_params_si(load(saved('specimens', specimen_file)));
prm = step_HS_robin('params', hs, dt, specimen_si, ...
    struct('eta_M', 0, 'eta_C', 0, 'eta_K', 0, 'adapt_M', false, 'adapt_K', false));
lead_data = load(saved('phase_lead', phase_lead_file));
lead_tf = lead_data.phase_lead_tf;
if isfield(lead_data, 'common_phase_lead_tf'), lead_tf = lead_data.common_phase_lead_tf; end
[lead_num, lead_den] = tfdata(c2d(lead_tf, dt, 'tustin'), 'v');
fprintf('FEM %s: damping %.3g in modes %s (%s Hz)\n', fem_file, ...
    hs.damping.target_ratio, mat2str(hs.damping.fit_modes(:)'), ...
    mat2str(round(hs.damping.frequency_hz(:)', 3)))

%% PRETEST NOMINAL STATE AND DESIGN
pretest = load(saved('tests', pretest_file));
if isfield(pretest, 'result'), pretest = pretest.result; end
keep = true(size(pretest.t(:)));
if ~isempty(pretest_window)
    keep = pretest.t(:) >= pretest_window(1) & pretest.t(:) <= pretest_window(2);
end
record = struct('dd', pretest.dd(keep), 'dm', pretest.dm(keep), ...
    'fm', pretest.fm(keep), 't', pretest.t(keep), 'g_id', pretest_gain);
model = load(saved('exp_tf', exp_tf_file), 'parametric_identification');
ns = robin_nominal_state(record, model.parametric_identification.identified_params, ...
    prm, struct('num', lead_num, 'den', lead_den), command_gain);
fprintf('Pretest: k0 = %.3f kN/mm, m = %.1f kg, c = %.0f N s/m (specimen file k = %.3f kN/mm)\n', ...
    ns.k0/1e6, ns.m, ns.c, specimen_si.stiffness/1e6)
design_opts = struct();
if ~isempty(admitted), design_opts.admitted = admitted; end
design_opts.ratios = ratios;
design_opts.estimates = [ns.k_fit, specimen_si.stiffness];   % other identified stiffnesses
[cases, sweep] = design_robin_sweep(ns, design_opts);
[K_R0, fixed_report, adaptive_report] = deal(sweep.K_R0, sweep.fixed, sweep.adaptive);
adaptive_override = sweep.adaptive_override;

%% vRTHS of every sweep case, nominal and with the specimen stiffness halved
sim = cases(1:end-1);                                 % the last case repeats the first
for i = 1:numel(sim), sim(i).name = matlab.lang.makeValidName(sim(i).name); end
vrths = vrths_robin(ns, hs, prm, sim);
vrths_soft = vrths_robin(ns, hs, prm, sim, struct('k_factor', 0.5));
fprintf('\n  %-26s %8s %9s %11s\n', 'case', 'admitted', 'vRTHS J_N', 'J_N (0.5 k0)')
for i = 1:numel(sim)
    [cases(i).J_N_vrths, cases(i).J_N_vrths_soft] = deal(Inf);   % Inf = diverged
    if ~vrths.(sim(i).name).diverged, cases(i).J_N_vrths = vrths.(sim(i).name).J_N; end
    if ~vrths_soft.(sim(i).name).diverged
        cases(i).J_N_vrths_soft = vrths_soft.(sim(i).name).J_N;
    end
    fprintf('  %-26s %8d %8.1f%% %10.1f%%\n', cases(i).name, cases(i).admitted, ...
        cases(i).J_N_vrths, cases(i).J_N_vrths_soft)
end
[cases(end).J_N_vrths, cases(end).J_N_vrths_soft] = deal(cases(1).J_N_vrths, ...
    cases(1).J_N_vrths_soft);

%% CHECKS AND SAVE
conv = fixed_report.conventional;
checks = struct( ...
    'conventional_tau_cr_ms', 1e3*conv.tau_cr, ...
    'conventional_margin_kN_mm', conv.margin/1e6, ...
    'conventional_clearance_kN_mm', conv.clearance/1e6, ...
    'fixed_margin_kN_mm', fixed_report.design.margin/1e6, ...
    'fixed_clearance_kN_mm', fixed_report.design.clearance/1e6, ...
    'adaptive_gamma', adaptive_report.gamma, ...
    'adaptive_path_min', adaptive_report.path_min_abs_1_plus_L, ...
    'sweep_not_admitted', {{cases(~[cases.admitted]).name}}, ...
    'vrths_diverged', {{sim(~isfinite([cases(1:end-1).J_N_vrths] + ...
        [cases(1:end-1).J_N_vrths_soft])).name}});
disp(checks)
if conv.clearance <= 0 || 1e3*conv.tau_cr < 50
    warning(['Conventional coupling has a small stability reserve (critical time ' ...
        'delay %.1f ms, clearance %.2f kN/mm); consider more structural damping ' ...
        'for the conventional test.'], 1e3*conv.tau_cr, conv.clearance/1e6)
end
if ~isempty(checks.vrths_diverged) || adaptive_report.gamma >= 1
    warning('A design check failed; do not run the hardware test with this design.')
end
if ~isempty(checks.sweep_not_admitted)
    warning('Sweep cases that fail the pretest checks (do not run): %s', ...
        strjoin(checks.sweep_not_admitted, ', '))
end
[~, stem] = fileparts(pretest_file);
out_dir = fullfile(project_root, 'saved_results', 'robin_designs');
if ~isfolder(out_dir), mkdir(out_dir); end
out_file = fullfile(out_dir, [stem '_robin_design.mat']);
nominal = rmfield(ns, {'T', 'Tg', 'C0', 'Z0', 'ZN'});
save(out_file, 'pretest_file', 'pretest_window', 'pretest_gain', 'specimen_file', ...
    'exp_tf_file', 'fem_file', 'phase_lead_file', 'command_gain', 'nominal', ...
    'K_R0', 'adaptive_override', 'fixed_report', 'adaptive_report', 'cases', ...
    'checks')
fprintf('Design saved: %s\n', out_file)

function file = savedFile(project_root, folder, name)
% A full path is used as given; otherwise saved_results/<folder>/<name>.
if isfile(name), file = name; else, file = fullfile(project_root, 'saved_results', folder, name); end
end
