function add_hs_robin_block(model_file)
%ADD_HS_ROBIN_BLOCK One-time edit: add the Robin-Dirichlet HS block.
% Run once in the lab MATLAB (R2020b, Speedgoat libraries installed) so the
% model is saved in its own release; exporting from a newer release
% rewrites library links and the model workspace. Adds to
% model_ColumnSetup_00:
%   columnSetup: global Gotos hs_dm_m (dm [m]), hs_am_g (accelerometer am
%   [g]), and hs_m_hat (TSE mass).
%   Signal Generation: MATLAB Function block 'Hybrid Simulation R-D'
%   (hybrid_simulation_robin_runtime.m) and 'HS coupling switch'. The
%   switch selects the R-D dd when enabled, or the existing HS dd otherwise.
%   Parameters hs_robin and hs_robin_enable come from main_ColumnSetup.m.

assert(strcmp(version('-release'), '2020b'), ...
    'Run this installer in MATLAB R2020b to preserve the lab model format.');
if nargin < 1
    model_file = fullfile(fileparts(fileparts(fileparts( ...
        mfilename('fullpath')))), 'model_ColumnSetup_00.slx');
end
[~, model] = fileparts(model_file);
load_system(model_file);
sg = [model '/Signal Generation'];
cs = [model '/columnSetup'];
assert(isempty(find_system(sg, 'SearchDepth', 1, 'Name', ...
    'Hybrid Simulation R-D')), 'The R-D block is already in the model.')

add_block('simulink/Signal Routing/Goto', [cs '/Goto hs_dm_m'], ...
    'GotoTag', 'hs_dm_m', 'TagVisibility', 'global', ...
    'Position', [1570 480 1660 500]);
add_line(cs, 'mm to m/1', 'Goto hs_dm_m/1', 'autorouting', 'on');
add_block('simulink/Signal Routing/Goto', [cs '/Goto hs_am_g'], ...
    'GotoTag', 'hs_am_g', 'TagVisibility', 'global', ...
    'Position', [1570 530 1660 550]);
add_line(cs, 'Measurements/3', 'Goto hs_am_g/1', 'autorouting', 'on');
add_block('simulink/Signal Routing/Goto', [cs '/Goto hs_m_hat'], ...
    'GotoTag', 'hs_m_hat', 'TagVisibility', 'global', ...
    'Position', [1860 480 1950 500]);
add_line(cs, 'Online TSE Estimator/1', 'Goto hs_m_hat/1', ...
    'autorouting', 'on');

rd = 'Hybrid Simulation R-D';
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [sg '/' rd], 'Position', [240 1580 395 1730]);
chart = find(sfroot, '-isa', 'Stateflow.EMChart', 'Path', [sg '/' rd]);
chart.Script = strjoin({
    ['function dd = hybrid_simulation_robin(fm, dm_m, am_g, m_hat, ' ...
    'pause_enable, hs_robin_enable, hs_robin, hs_time, hs_ag, hs_time_scale_factor_codegen)']
    '%#codegen'
    '% WARNING - SAFETY CRITICAL: this block sends live HS command displacement.'
    'dd = 0;'
    'if hs_robin_enable > 0.5'
    '    dd = hybrid_simulation_robin_runtime(fm, dm_m, 9.80665*am_g, m_hat, ...'
    '        pause_enable, hs_robin, hs_time, hs_ag, hs_time_scale_factor_codegen);'
    'end'
    'end'}, newline);
for p = {'hs_robin_enable', 'hs_robin', 'hs_time', 'hs_ag', 'hs_time_scale_factor_codegen'}
    d = find(chart, '-isa', 'Stateflow.Data', 'Name', p{1});
    d.Scope = 'Parameter';
end
add_line(sg, 'fm/1', [rd '/1'], 'autorouting', 'on');
tags = {'hs_dm_m', 'hs_am_g', 'hs_m_hat'};
for k = 1:numel(tags)
    from = sprintf('From %s rd', tags{k});
    add_block('simulink/Signal Routing/From', [sg '/' from], ...
        'GotoTag', tags{k}, 'Position', [60 1590+35*k 170 1610+35*k]);
    add_line(sg, [from '/1'], sprintf('%s/%d', rd, k + 1), ...
        'autorouting', 'on');
end
add_line(sg, 'From dd_pause_enable hs/1', [rd '/5'], 'autorouting', 'on');

% Both the HS Delay Compensator and OSI tap use the selected HS command.
sw = 'HS coupling switch';
add_block('simulink/Signal Routing/Switch', [sg '/' sw], ...
    'Criteria', 'u2 > Threshold', 'Threshold', '0.5', ...
    'Position', [430 1285 460 1365]);
add_block('simulink/Sources/Constant', [sg '/hs_robin_enable'], ...
    'Value', 'hs_robin_enable', 'Position', [300 1415 400 1435]);
hs_ports = get_param([sg '/Hybrid Simulation'], 'PortHandles');
hs_line = get_param(hs_ports.Outport, 'Line');
destinations = get_param(hs_line, 'DstPortHandle');
delete_line(hs_line);
add_line(sg, [rd '/1'], [sw '/1'], 'autorouting', 'on');
add_line(sg, 'hs_robin_enable/1', [sw '/2'], 'autorouting', 'on');
add_line(sg, 'Hybrid Simulation/1', [sw '/3'], 'autorouting', 'on');
sw_ports = get_param([sg '/' sw], 'PortHandles');
for p = destinations(:)'
    add_line(sg, sw_ports.Outport, p, 'autorouting', 'on');
end
save_system(model);
fprintf('Added %s and %s to %s.\n', rd, sw, model_file);
end
