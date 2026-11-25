function prm = robin_params_of_result(result, hs, project_folder)
%ROBIN_PARAMS_OF_RESULT Robin operator of a saved test ([] if conventional).
%   prm = robin_params_of_result(result, hs, project_folder)
%
%   Tests saved after this change store the operator as result.hs_robin.
%   For older tests it is rebuilt from result.hs (robin_enable,
%   robin_specimen_file, robin_override) and the sampling period, exactly
%   as main_ColumnSetup.m built it. Returns [] when the Robin-Dirichlet
%   block was not enabled.

if isfield(result, 'hs_robin_enable') && ~result.hs_robin_enable
    prm = [];
    return
end
if isfield(result, 'hs_robin') && ~isempty(result.hs_robin)
    prm = result.hs_robin;
    return
end
if ~isfield(hs, 'robin_enable') || ~hs.robin_enable
    prm = [];
    return
end
if isfield(result, 'dt'), dt = result.dt; else, dt = mean(diff(result.t(:))); end
specimen = load(fullfile(project_folder, 'saved_results', 'specimens', ...
    hs.robin_specimen_file));
override = struct();
if isfield(hs, 'robin_override'), override = hs.robin_override; end
prm = step_HS_robin('params', hs, dt, specimen_params_si(specimen), override);
end
