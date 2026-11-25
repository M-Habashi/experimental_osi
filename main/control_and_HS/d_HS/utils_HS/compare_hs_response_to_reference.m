function [metric_table, comparison] = compare_hs_response_to_reference( ...
        fem, recorded_data, earthquake_type, intensity_factor, ...
        time_scale_factor, force_sign, options)
%COMPARE_HS_RESPONSE_TO_REFERENCE Compare HS data with the reference structure.
% The test is replayed with its own coupling: step_HS for conventional
% coupling, the Robin-Dirichlet block (replay_hs_robin) otherwise. For the
% linear structural model, the reference is the hybrid partition integrated
% as one structure: the numerical substructure with the specimen
% m s^2 + c s + k at the interface (the pretest values saved with the run,
% the specimen file, or options.reference_specimen with fields mass,
% damping, stiffness). It is exact for a linear specimen; for a nonlinear
% specimen the post-test reference needs a fitted specimen law.
% Units:
%   recorded data: t [s], dm [mm], fm [N].
%   FEM/reference displacements are compared in [m].
%   J1 [ms]; J2-J7 [%].

project_folder = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(fullfile(project_folder, 'helpers', 'utils'));
addpath(fullfile(project_folder, 'control_and_HS', 'd_HS', 'utils_HS'));
addpath(fullfile(project_folder, 'control_and_HS', 'c_fem_modeling', ...
    'utils_fem'));
addpath(fullfile(project_folder, 'results_analysis'));

if nargin < 2
    recorded_data = [];
end
if nargin < 1
    fem = [];
end
if nargin < 3
    earthquake_type = [];
end
if nargin < 4
    intensity_factor = [];
end
if nargin < 5
    time_scale_factor = [];
end
if nargin < 6
    force_sign = [];
end
if nargin < 7 || isempty(options)
    options = struct();
end
plot_enabled = getOption(options, 'plot', true);

data = loadRecordedData(recorded_data, project_folder);
fem = loadFemData(fem, data, project_folder);
[earthquake_type, intensity_factor, time_scale_factor, force_sign] = ...
    getComparisonInputs(data, min(nargin, 6), earthquake_type, ...
    intensity_factor, time_scale_factor, force_sign);

t = data.t(:);
dm = data.dm(:);
fm = data.fm(:);
if isfield(data, 'dt')
    dt = data.dt;
else
    dt = mean(diff(t));
end
if isfield(data, 'fs')
    fs = data.fs;
else
    fs = 1/dt;
end
pause_enable = getPauseEnable(data, numel(t));
n = min([numel(t), numel(dm), numel(fm), numel(pause_enable)]);
t = t(1:n);
dm = dm(1:n);
dm_filtfilt = filtfiltDm(dm, fs, 20, 6);
fm = fm(1:n);
pause_enable = pause_enable(1:n);

hs = buildHsModel(fem, earthquake_type, intensity_factor, ...
    time_scale_factor, force_sign, project_folder);
if isfield(data, 'hs') && isfield(data.hs, 'structural_model')
    hs.structural_model = data.hs.structural_model;
end
for name = {'robin_enable', 'robin_specimen_file', 'robin_override'}
    if isfield(data, 'hs') && isfield(data.hs, name{1})
        hs.(name{1}) = data.hs.(name{1});
    end
end
prm = robin_params_of_result(data, hs, project_folder);
if isempty(prm)
    [u_test, u_control_test_mm, effective_time, a_test, hinges_test] = replayRecordedHs( ...
        fm, pause_enable, dt, hs);
else
    replay = replay_hs_robin(data, hs, prm);
    [u_test, u_control_test_mm, effective_time, a_test] = deal(replay.x_n_m(1:n, :), ...
        replay.d_n_mm(1:n), replay.effective_time(1:n), replay.a_n(1:n, :));
    hinges_test = elastic_hs_hinges(hs.fem.num, true, u_test, u_control_test_mm, ...
        effective_time/hs.time_scale_factor);
end
if is_hs_nonlinear(hs)
    [u_reference, u_control_reference, a_reference, hinges_reference] = fullReferenceAtEffectiveTime( ...
        fem.ref, hs, effective_time, dt);
else
    [u_reference, u_control_reference, a_reference, hinges_reference] = hybridReferenceAtEffectiveTime( ...
        hs, referenceSpecimen(data, hs, fem, options, project_folder), effective_time, dt);
end
ag = interp1(hs.time, hs.ag, effective_time/hs.time_scale_factor, 'linear', 0);
base_shear_test = hs_base_shear(hs.M, ...
    fem.num.influence(fem.num.floor_dofs), a_test, ag);
base_shear_reference = hs_base_shear(hs.M, ...
    fem.num.influence(fem.num.floor_dofs), a_reference, ag);
if plot_enabled
    plotStructuralReferenceComparison(effective_time, u_test, u_reference, ...
        pause_enable, dm, dm_filtfilt, u_control_test_mm, ...
        u_control_reference, base_shear_test, base_shear_reference);
    plotResponseFrequencyContent(hs, fem.num, u_test, effective_time, ...
        pause_enable, dt);
    plot_hs_plastic_hinges(hs, hinges_test, hinges_reference);
    active = pause_enable == 0;
    if ~any(active), active = true(size(pause_enable)); end
    plot_hs_roof_hysteresis([u_reference(active, end), u_test(active, end)], ...
        [base_shear_reference(active), base_shear_test(active)], ...
        {'Reference', 'HS (reconstructed)'});
end

running = pause_enable == 0;
metric = validation_metrics();
u_control_reference_mm = 1000*u_control_reference;
% J1-J3 compare measured dm to d_n from the numerical sub.
% J4-J6 compare x1_n/x2_n/x3_n numerical sub floors to x1_r/x2_r/x3_r.
% J7 compares measured dm to the reference interface displacement d_r as NMSE.
values = [ ...
    metric.J1(dm_filtfilt(running), u_control_test_mm(running), dt); ...
    metric.J2(dm_filtfilt(running), u_control_test_mm(running)); ...
    metric.J3(dm_filtfilt(running), u_control_test_mm(running)); ...
    metric.J4(u_test(running, 1), u_reference(running, 1)); ...
    metric.J5(u_test(running, 2), u_reference(running, 2)); ...
    metric.J6(u_test(running, 3), u_reference(running, 3)); ...
    metric.J7(dm_filtfilt(running), u_control_reference_mm(running))];

metric_table = table( ...
    ["finddelay(d_n, dm_filtfilt)*dt"; ...
     "100*std(dm_filtfilt - d_n)/std(d_n)"; ...
     "100*max(abs(dm_filtfilt - d_n))/max(abs(d_n))"; ...
     "100*std(x1_n - x1_r)/std(x1_r)"; ...
     "100*std(x2_n - x2_r)/std(x2_r)"; ...
     "100*std(x3_n - x3_r)/std(x3_r)"; ...
     "100*mean((dm_filtfilt - d_r)^2)/mean(d_r^2)"], ...
    ["ms"; "%"; "%"; "%"; "%"; "%"; "%"], ...
    values, ...
    'RowNames', {'J1', 'J2', 'J3', 'J4', 'J5', 'J6', 'J7'}, ...
    'VariableNames', {'Description', 'Unit', 'Value'});

if nargout == 0
    disp('Hybrid Simulation Reference Comparison')
    disp(metric_table)
end

if nargout > 1
    comparison = struct('t', t, 'effective_time', effective_time, ...
        'pause_enable', pause_enable, 'u_test', u_test, ...
        'u_reference', u_reference, ...
        'dm_filtfilt', dm_filtfilt, ...
        'u_control_test_mm', u_control_test_mm, ...
        'u_control_reference', u_control_reference, ...
        'base_shear_test_N', base_shear_test, ...
        'base_shear_reference_N', base_shear_reference, ...
        'hinges_test', hinges_test, 'hinges_reference', hinges_reference);
end
end

function value = getOption(options, name, default_value)
if isfield(options, name)
    value = options.(name);
else
    value = default_value;
end
end

function data = loadRecordedData(recorded_data, project_folder)
if nargin < 1 || isempty(recorded_data) ...
        || ((ischar(recorded_data) || isstring(recorded_data)) ...
        && ~isfile(recorded_data))
    if nargin >= 1 && ~isempty(recorded_data)
        fprintf('Recorded data file not found: %s\n', recorded_data)
    end
    [data, recorded_data] = load_saved_result_file(project_folder, ...
        'tests', true);
    fprintf('Loaded recorded data: %s\n', recorded_data)
elseif ischar(recorded_data) || isstring(recorded_data)
    data = load(recorded_data);
    if isfield(data, 'result') && isstruct(data.result)
        data = data.result;
    end
else
    data = recorded_data;
    if isfield(data, 'result') && isstruct(data.result)
        data = data.result;
    end
end
end

function fem = loadFemData(fem, data, project_folder)
if isstruct(fem) && isfield(fem, 'num') && isfield(fem, 'ref')
    return
end

if ischar(fem) || isstring(fem)
    if isfile(fem)
        fem_data = load(fem, 'fem');
        fem = fem_data.fem;
        return
    end
    fprintf('FEM file not found: %s\n', fem)
end

if isfield(data, 'hs') && isfield(data.hs, 'fem')
    fem = data.hs.fem;
    return
end

fem_data = load_saved_result_file(project_folder, 'fem', true);
assert(isfield(fem_data, 'fem'), 'Selected FEM file does not contain fem.')
fem = fem_data.fem;
end

function [earthquake_type, intensity_factor, time_scale_factor, force_sign] = ...
        getComparisonInputs(data, n_input, earthquake_type, intensity_factor, ...
        time_scale_factor, force_sign)
if n_input < 3 || isempty(earthquake_type)
    assert(isfield(data, 'hs') && isfield(data.hs, 'earthquake_type'), ...
        'earthquake_type must be passed or stored in recorded data hs.')
    earthquake_type = data.hs.earthquake_type;
end
if n_input < 4 || isempty(intensity_factor)
    assert(isfield(data, 'hs') && isfield(data.hs, 'intensity_factor'), ...
        'intensity_factor must be passed or stored in recorded data hs.')
    intensity_factor = data.hs.intensity_factor;
end
if n_input < 5 || isempty(time_scale_factor)
    assert(isfield(data, 'hs') && isfield(data.hs, 'time_scale_factor'), ...
        'time_scale_factor must be passed or stored in recorded data hs.')
    time_scale_factor = data.hs.time_scale_factor;
end
if n_input < 6 || isempty(force_sign)
    if isfield(data, 'hs') && isfield(data.hs, 'force_sign')
        force_sign = data.hs.force_sign;
    else
        force_sign = 1.0;
    end
end
end

function pause_enable = getPauseEnable(data, n)
if isfield(data, 'dd_pause_enable_log') && ~isempty(data.dd_pause_enable_log)
    pause_enable = data.dd_pause_enable_log(:);
elseif isfield(data, 'dd_pause_enable') && ~isempty(data.dd_pause_enable)
    pause_enable = data.dd_pause_enable(:);
elseif isfield(data, 'Results') && numel(data.Results) >= 1 ...
        && size(data.Results{1}, 2) >= 10
    pause_enable = data.Results{1}(:, 10);
else
    pause_enable = zeros(n, 1);
end
end

function hs = buildHsModel(fem, earthquake_type, intensity_factor, ...
        time_scale_factor, force_sign, project_folder)
fem_num = fem.num;
fem_ref = fem.ref;
floor_dofs = fem_num.floor_dofs(:)';
interface_dof = fem_num.interface_dof;
K_num = fem_num.K;
K_ff = K_num(floor_dofs, floor_dofs);
K_fi = K_num(floor_dofs, interface_dof);
K_if = K_num(interface_dof, floor_dofs);
K_ii = K_num(interface_dof, interface_dof);

hs.fem = fem;
hs.n_floor = numel(floor_dofs);
hs.M = fem_num.M(floor_dofs, floor_dofs);
hs.K = K_ff - K_fi*(K_ii\K_if);
hs.K_if = K_if;
hs.K_ii = K_ii;
hs.force_to_floor = K_fi/K_ii;
hs.interface_from_floor = -K_ii\K_if;
hs.interface_from_force = -1/K_ii;
hs.ground_force_gain = -(hs.M*fem_num.influence(floor_dofs(:)));
[hs.C, hs.damping] = femDampingMatrix(fem_ref, fem);
hs.damping_ratio = hs.damping.target_ratio;
hs.earthquake_type = earthquake_type;
hs.intensity_factor = intensity_factor;

earthquakes = load(fullfile(project_folder, 'input_signals', ...
    'earthquakes.mat'), earthquake_type);
earthquake = earthquakes.(earthquake_type);
hs.time = earthquake(:, 1) - earthquake(1, 1);
hs.ag = intensity_factor*earthquake(:, 2);
hs.time_scale_factor = time_scale_factor;
hs.force_sign = force_sign;
end

function [u_test, u_control_test_mm, effective_time, a_test, hinges] = replayRecordedHs( ...
        fm, pause_enable, dt, hs)
n = numel(fm);
state = [];
u_test = zeros(n, hs.n_floor);
a_test = zeros(n, hs.n_floor);
u_control_test_mm = zeros(n, 1);
effective_time = zeros(n, 1);
nonlinear = is_hs_nonlinear(hs);
if nonlinear
    cfg = prepare_hs_nonlinear(hs, dt, 'num');
    nd = size(cfg.K, 1);
else
    nd = hs.n_floor;
end
ok = true;
hinges = [];
for step = 2:n
    if nonlinear
        [u_control_test_mm(step), state, ok] = step_HS_nonlinear( ...
            fm(step), pause_enable(step), cfg, state);
    else
        [u_control_test_mm(step), state] = step_HS( ...
            fm(step), pause_enable(step), dt, hs, state);
    end
    u_test(step, :) = state(1:hs.n_floor)';
    a_test(step, :) = state(2*nd+(1:hs.n_floor))';
    effective_time(step) = effective_time(step - 1);
    if pause_enable(step) == 0 && ok % failure holds freeze the clock
        effective_time(step) = effective_time(step) + dt;
    end
    if nonlinear
        hinges = hs_hinge_summary(hinges, cfg, state(1:nd), ...
            state(3*nd+(1:numel(cfg.Mp))), effective_time(step)/hs.time_scale_factor);
    end
end
if ~nonlinear
    hinges = elastic_hs_hinges(hs.fem.num, true, u_test, u_control_test_mm, ...
        effective_time/hs.time_scale_factor);
end
end

function specimen = referenceSpecimen(data, hs, fem, options, project_folder)
% Specimen of the reference: options, the pretest of the run, the specimen
% file of the run, or the stiffness the FEM was calibrated to.
if isfield(options, 'reference_specimen')
    specimen = options.reference_specimen;
elseif isfield(data, 'robin_nominal')
    specimen = struct('mass', data.robin_nominal.m, ...
        'damping', data.robin_nominal.c, 'stiffness', data.robin_nominal.k0);
elseif isfield(hs, 'robin_specimen_file') && ~isempty(hs.robin_specimen_file)
    specimen = specimen_params_si(load(fullfile(project_folder, ...
        'saved_results', 'specimens', hs.robin_specimen_file)));
else
    specimen = struct('mass', 0, 'damping', 0, ...
        'stiffness', fem.num.experimental_k);
end
end

function [u_reference, u_control_reference, a_reference, hinges] = hybridReferenceAtEffectiveTime(hs, ...
        specimen, effective_time, dt)
% Numerical substructure + specimen at the interface, one structure: the
% Robin operator equal to the specimen and a zero residual (vHS_robin.m).
prm = step_HS_robin('params', hs, dt, specimen, struct('eta_M', 1, ...
    'eta_C', 1, 'eta_K', 1, 'adapt_M', false, 'adapt_K', false));
reference_time = (0:round(max(effective_time)/dt))'*dt;
ag = interp1(hs.time, hs.ag, (reference_time + dt)/hs.time_scale_factor, 'linear', 0);
state = step_HS_robin('state', prm);
n = numel(reference_time);
n_dof = size(prm.K, 1);
u_grid = zeros(n, hs.n_floor);
a_grid = zeros(n, hs.n_floor);
d_grid = zeros(n, 1);
for k = 2:n
    [d_grid(k), state] = step_HS_robin(0, 0, 0, 0, ag(k - 1), NaN, state, prm);
    u_grid(k, :) = state.x(1:hs.n_floor)';
    a_grid(k, :) = state.x(2*n_dof + (1:hs.n_floor))';
end
index = round(effective_time/dt) + 1;
u_reference = u_grid(index, :);
u_control_reference = d_grid(index)/1000;
a_reference = a_grid(index, :);
hinges = elastic_hs_hinges(hs.fem.num, true, u_grid, d_grid, ...
    reference_time/hs.time_scale_factor);
end

function [u_reference, u_control_reference, a_reference, hinges] = fullReferenceAtEffectiveTime(fem_ref, hs, ...
        effective_time, dt)
reference_time = (0:round(max(effective_time)/dt))'*dt;
reference_model_time = reference_time/hs.time_scale_factor;
if is_hs_nonlinear(hs)
    [u_reference_grid, u_control_grid, ~, a_reference_grid, hinges] = replay_hs_nonlinear( ...
        prepare_hs_nonlinear(hs, dt, 'ref'), zeros(size(reference_time)));
    u_control_grid = u_control_grid/1000;
else
    ag = interp1(hs.time, hs.ag, reference_model_time, 'linear', 0);
    reference_load = -(fem_ref.M*fem_ref.influence)*ag';
    [u_reference_grid, ~, a_reference_grid] = newmarkAverageAcceleration(reference_time, ...
        fem_ref.M, hs.C, fem_ref.K, reference_load);
    u_control_grid = referenceControlDisplacement(fem_ref, u_reference_grid);
    hinges = elastic_hs_hinges(fem_ref, false, u_reference_grid, [], reference_model_time);
end
reference_index = round(effective_time/dt) + 1;
u_reference = u_reference_grid(reference_index, :);
u_control_reference = u_control_grid(reference_index);
a_reference = a_reference_grid(reference_index, :);
end

function plotStructuralReferenceComparison(effective_time, u_test, ...
        u_reference, pause_enable, dm, dm_filtfilt, ...
        u_control_test_mm, u_control_reference, base_shear_test, base_shear_reference)
active = pause_enable == 0;
if ~any(active)
    active = true(size(pause_enable));
end

x = effective_time(active);
u_test = u_test(active, :);
u_reference = u_reference(active, :);

colors = getPlotColors();
figure('Color', 'w', 'Name', 'HS structural response comparison', ...
    'Position', [80 50 1100 950]);
layout = tiledlayout(5, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
dm = dm(active);
dm_filtfilt = dm_filtfilt(active);
u_control_test_mm = u_control_test_mm(active);
u_control_reference = u_control_reference(active);
ax = nexttile;
plot(ax, x, u_control_test_mm, 'k--', 'LineWidth', 2.0, ...
    'DisplayName', 'd\_n (numerical sub)');
hold(ax, 'on')
plot(ax, x, dm, '-', 'Color', colors.blue, 'LineWidth', 1.0, ...
    'DisplayName', 'dm (measured)');
plot(ax, x, dm_filtfilt, '-', 'Color', colors.blue, ...
    'LineWidth', 1.3, 'DisplayName', 'dm\_filtfilt');
plot(ax, x, 1000*u_control_reference, '-', ...
    'Color', colors.green, 'LineWidth', 1.2, ...
    'DisplayName', 'd\_r (full FEM)');
hold(ax, 'off')
grid(ax, 'on')
ylabel(ax, 'Displacement (mm)')
legend_handle = legend(ax, 'Location', 'best');
legend_handle.ItemHitFcn = @toggleSignalVisibility;

for floor_id = 1:3
    ax = nexttile;
    plot(ax, x, u_reference(:, floor_id), '--', ...
        'Color', colors.dark_green, 'LineWidth', 2.2, ...
        'DisplayName', sprintf('x%d\\_r (full FEM)', floor_id));
    hold(ax, 'on')
    plot(ax, x, u_test(:, floor_id), '-', 'Color', colors.blue, ...
        'LineWidth', 1.2, ...
        'DisplayName', sprintf('x%d\\_n (numerical sub)', floor_id));
    hold(ax, 'off')
    grid(ax, 'on')
    ylabel(ax, sprintf('Floor %d (m)', floor_id))
    legend_handle = legend(ax, 'Location', 'best');
    legend_handle.ItemHitFcn = @toggleSignalVisibility;
end
ax = nexttile;
plot(ax, x, base_shear_reference(active)/1000, '--', ...
    'Color', colors.purple, 'LineWidth', 2.2, 'DisplayName', 'Reference');
hold(ax, 'on')
plot(ax, x, base_shear_test(active)/1000, '-', ...
    'Color', colors.purple, 'LineWidth', 1.2, 'DisplayName', 'HS (reconstructed)');
hold(ax, 'off'); grid(ax, 'on')
ylabel(ax, 'Base shear (kN)')
xlabel(ax, 'Effective HS time (s)')
legend_handle = legend(ax, 'Location', 'best');
legend_handle.ItemHitFcn = @toggleSignalVisibility;
title(layout, 'Control point, floors and total base shear vs full FEM')
linkaxes(findall(gcf, 'Type', 'axes'), 'x')
end

function plotResponseFrequencyContent(hs, fem_num, u_test, effective_time, ...
        pause_enable, dt)
active = pause_enable == 0;
if ~any(active)
    active = true(size(pause_enable));
end

selected_response = u_test(active, :);
selected_time = effective_time(active);
test_duration = selected_time(end) - selected_time(1);
if test_duration <= 0
    test_duration = hs.time(end)*hs.time_scale_factor;
end
ag_sample = interp1(hs.time, hs.ag, ...
    selected_time/hs.time_scale_factor, 'linear', 0);
unit_scale_response = hybrid_response_at_time_scale( ...
    hs, fem_num, fem_num.experimental_k, dt, 1);
plot_hs_response_frequency_content(hs, selected_response, ...
    unit_scale_response, 1/dt, 100, test_duration, ag_sample);
end

function toggleSignalVisibility(~, event)
ax = ancestor(event.Peer, 'axes');
x_limits = xlim(ax);
y_limits = ylim(ax);
if strcmp(event.Peer.Visible, 'on')
    event.Peer.Visible = 'off';
else
    event.Peer.Visible = 'on';
end
xlim(ax, x_limits);
ylim(ax, y_limits);
set(ax, 'XLimMode', 'manual', 'YLimMode', 'manual')
end

function y = filtfiltDm(dm, fs, cutoff_hz, order)
[b, a] = butter(order, cutoff_hz/(fs/2), 'low');
y = filtfilt(b, a, dm - dm(1)) + dm(1);
end

function colors = getPlotColors()
colors.green = hexToRgb('39BF5E');
colors.dark_green = hexToRgb('006B2E');
colors.blue = hexToRgb('007CA8');
colors.purple = hexToRgb('74058A');
colors.copperwood = hexToRgb('AC6420');
end

function rgb = hexToRgb(hex_color)
rgb = sscanf(hex_color, '%2x%2x%2x', [1 3]) / 255;
end
