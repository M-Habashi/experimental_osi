function [dd, state] = hybrid_simulation_robin_runtime(fm, dm_m, am, ...
        m_hat, pause_enable, prm, time, ag, time_scale_factor)
%HYBRID_SIMULATION_ROBIN_RUNTIME Robin-Dirichlet HS step for Simulink.
% Called by the Hybrid Simulation R-D block in model_ColumnSetup_00.
% prm = step_HS_robin('params'/'design', ...). Earthquake clock and pause
% as in step_HS. um = measured displacement, vm = its backward difference,
% am = measured acceleration (accelerometer channel); no filter.
% state: step_HS_robin state (desktop checks; the block uses dd only).
% Units: fm [N], dm_m [m], am [m/s^2], m_hat [kg], time [s], ag [m/s^2],
% dd [mm].
%#codegen

persistent rd_state tau dd_hold x_prev
if isempty(rd_state)
    rd_state = step_HS_robin('state', prm);
    tau = 0;
    dd_hold = 0;
    x_prev = dm_m;
end

vm = (dm_m - x_prev)/prm.dt;    % every sample, also while paused
x_prev = dm_m;

state = rd_state;
if pause_enable ~= 0
    dd = dd_hold;
    return
end
tau = tau + prm.dt/time_scale_factor;
[dd, rd_state] = step_HS_robin(fm, dm_m, vm, am, ...
    interp1(time, ag, tau, 'linear', 0), m_hat, rd_state, prm);
state = rd_state;
dd_hold = dd;
end
