function out = replay_hs_robin(data, hs, prm)
%REPLAY_HS_ROBIN Offline replay of the Robin-Dirichlet HS block of a test.
%   out = replay_hs_robin(data, hs, prm)
%
%   The Simulink block logs only the command after the lead filter, not the
%   numerical interface displacement u_I^N, the floor displacements, or the
%   Robin stiffness K_R. This replay steps the block function itself,
%   hybrid_simulation_robin_runtime, with the logged fm, dm, am, m_hat, and
%   pause flag, so it reproduces the run sample by sample.
%
%   data  test result: fm [N], dm [mm], am [g], m_hat [kg] (optional),
%         dd_pause_enable_log (or dd_pause_enable).
%   hs    time [s], ag [m/s^2], time_scale_factor of the run.
%   prm   step_HS_robin('params', ...) of the run (result.hs_robin, or
%         robin_params_of_result for older results).
%   out   d_n_mm (u_I^N), x_n_m and a_n (floors), K_R [N/m], effective_time.

fm = data.fm(:);
dm = data.dm(:);
am = zeros(size(fm));
if isfield(data, 'am') && ~isempty(data.am), am = data.am(:); end
m_hat = NaN(size(fm));
if isfield(data, 'm_hat') && ~isempty(data.m_hat), m_hat = data.m_hat(:); end
pause_enable = zeros(size(fm));
if isfield(data, 'dd_pause_enable_log') && ~isempty(data.dd_pause_enable_log)
    pause_enable = data.dd_pause_enable_log(:);
elseif isfield(data, 'dd_pause_enable') && ~isempty(data.dd_pause_enable)
    pause_enable = data.dd_pause_enable(:);
end
n = min([numel(fm), numel(dm), numel(am), numel(m_hat), numel(pause_enable)]);
n_floor = prm.n;
n_dof = size(prm.K, 1);

clear hybrid_simulation_robin_runtime          % persistent block state
reset = onCleanup(@() clear('hybrid_simulation_robin_runtime'));
d_n = zeros(n, 1);
x_n = zeros(n, n_floor);
a_n = zeros(n, n_floor);
K_R = zeros(n, 1);
effective_time = zeros(n, 1);
for k = 1:n
    [d_n(k), state] = hybrid_simulation_robin_runtime(fm(k), dm(k)/1000, ...
        9.80665*am(k), m_hat(k), pause_enable(k), prm, hs.time, hs.ag, ...
        hs.time_scale_factor);
    x_n(k, :) = state.x(1:n_floor)';
    a_n(k, :) = state.x(2*n_dof + (1:n_floor))';
    K_R(k) = state.K_R;
    if k > 1
        effective_time(k) = effective_time(k - 1) + prm.dt*(pause_enable(k) == 0);
    end
end
out = struct('d_n_mm', d_n, 'x_n_m', x_n, 'a_n', a_n, 'K_R', K_R, ...
    'effective_time', effective_time, 'pause_enable', pause_enable(1:n));
end
