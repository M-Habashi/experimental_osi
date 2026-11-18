%% VIRTUAL ROBIN-DIRICHLET HYBRID SIMULATION CHECK
% Check of step_HS_robin (fixed and adaptive Robin-Dirichlet).
% A virtual specimen tracks the command with a pure delay and loses 30% of
% its stiffness at mid-record. 
% Conventional step_HS coupling, fixed R-D (L = 0.9 Z0 and the selected L*), 
% and adaptive R-D starting from L* are compared with the monolithic reference. 
% Z0 = nominal specimen m, c, k.
% Units: SI, except dd/d_n/d_p [mm].

clear; clc
project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(project_root);
addpaths();

fem = loadFemDefinition(project_root, false, ...
    fullfile(project_root, 'saved_results', 'fem', 'fem_sp1_7000.mat'));
specimen = specimen_params_si(load(fullfile(project_root, ...
    'saved_results', 'specimens', 'sp1_7000.mat')));

% Same condensed numerical substructure as main_ColumnSetup.m.
num = fem.num;
f = num.floor_dofs(:)';
i = num.interface_dof;
hs = struct('n_floor', numel(f), 'M', num.M(f, f), ...
    'K_if', num.K(i, f), 'K_ii', num.K(i, i), ...
    'force_sign', 1, 'time_scale_factor', 1);
hs.K = num.K(f, f) - num.K(f, i)*(hs.K_ii\hs.K_if);
hs.force_to_floor = num.K(f, i)/hs.K_ii;
hs.interface_from_floor = -hs.K_ii\hs.K_if;
hs.interface_from_force = -1/hs.K_ii;
hs.ground_force_gain = -(hs.M*num.influence(f));
hs.C = femDampingMatrix(fem.ref, fem);
eq = load(fullfile(project_root, 'input_signals', 'earthquakes.mat'), ...
    'el_centro');
hs.time = eq.el_centro(:, 1) - eq.el_centro(1, 1);
hs.ag = eq.el_centro(:, 2);

dt = 1/2048;
t = (0:dt:12-dt)';
ag = interp1(hs.time, hs.ag, t, 'linear', 0);
delay_n = 8;                                    % 3.9 ms tracking delay
m_p = specimen.mass;
c_p = specimen.damping;
k_p = specimen.stiffness*(1 - 0.3*(t >= t(end)/2));
post = t >= t(end)/2;

%% 1) With L = 0, step_HS_robin reproduces step_HS
prm0 = step_HS_robin('params', hs, dt, ...
    struct('mass', 0, 'damping', 0, 'stiffness', 0), ...
    struct('adapt_K', false));
rng(1)
fm_test = 1e4*randn(4000, 1);
x = [];
s = step_HS_robin('state', prm0);
clear hybrid_simulation_robin_runtime         % Simulink block runtime
err0 = 0;
for j = 2:numel(fm_test)
    [d1, x] = step_HS(fm_test(j), 0, dt, hs, x);
    [d2, s] = step_HS_robin(fm_test(j), 0, 0, 0, ag(j), NaN, s, prm0);
    d3 = hybrid_simulation_robin_runtime(fm_test(j), 0, 0, NaN, 0, ...
        prm0, hs.time, hs.ag, hs.time_scale_factor);
    err0 = max([err0 abs(d1 - d2) abs(d1 - d3)]);
end
fprintf('L = 0 vs step_HS: max |dd difference| = %.3e mm\n', err0);
assert(err0 < 1e-9, 'step_HS_robin with L = 0 does not match step_HS.')

%% 2) Monolithic reference: L = true specimen and zero residual
prm_ref = step_HS_robin('params', hs, dt, specimen, ...
    struct('eta_C', 1, 'adapt_K', false));
s = step_HS_robin('state', prm_ref);
d_ref = zeros(size(t));
x1_ref = d_ref;
for j = 2:numel(t)
    s.K_R = k_p(j);
    [d_ref(j), s] = step_HS_robin(0, 0, 0, 0, ag(j), NaN, s, prm_ref);
    x1_ref(j) = s.x(1);
end

%% 3) Conventional, fixed R-D, and adaptive R-D coupling
% Selected L* (linear paper, Section 6.4 settings): 0.5-25 Hz, nominal
% delay, max|E^N| <= 2%, 0 <= eta <= 1. Designed on the undamaged specimen.
prm_star = step_HS_robin('design', step_HS_robin('params', hs, dt, ...
    specimen, struct('adapt_K', false)), tf(1, [1 zeros(1, delay_n)], dt), ...
    [0.5 25], 0.02);
eta = [prm_star.eta_M prm_star.eta_C prm_star.eta_K];
fprintf('L* = (%.4f M0, %.4f C0, %.4f K0)\n', eta);
prm_K = prm_star;
prm_K.adapt_K = true;
specimen_high = specimen;
specimen_high.mass = 1.15*m_p;                  % mass identified 15% high
names = {'N-D (step_HS)'; 'Fixed R-D, L = 0.9 Z0'; 'Fixed R-D, L = L*'; ...
    'Adaptive R-D from L*, K'; 'Adaptive R-D from L*, MK, M0 = 1.15 m'; ...
    'Simulink runtime, adaptive K from L*'};
prm = {[], ...
    step_HS_robin('params', hs, dt, specimen, struct('adapt_K', false, ...
    'eta_M', 0.9, 'eta_C', 0.9, 'eta_K', 0.9)), ...
    prm_star, prm_K, ...
    step_HS_robin('params', hs, dt, specimen_high, struct('adapt_M', true, ...
    'eta_M', eta(1), 'eta_C', eta(2), 'eta_K', eta(3), ...
    'M_bounds', [eta(1) 1.25]*m_p)), prm_K};    % box checked at 3.9 ms
m_hat = [NaN NaN NaN NaN m_p NaN];
runtime = (1:numel(names)) == 6;
nrmse = @(y, r) 100*rms(y - r)/rms(r);
[d_n_NRMSE_pct, d_p_NRMSE_pct, x1_NRMSE_pct, K_R_end_over_k, ...
    M_R_end_over_m] = deal(NaN(numel(names), 1));
for c = 1:numel(names)
    [dd, x1, K_R, M_R, u] = runHybrid(hs, prm{c}, ag, k_p, m_p, c_p, ...
        delay_n, dt, m_hat(c), runtime(c));
    d_n_NRMSE_pct(c) = nrmse(dd(post), d_ref(post));
    d_p_NRMSE_pct(c) = nrmse(1000*u(post), d_ref(post));
    x1_NRMSE_pct(c) = nrmse(x1(post), x1_ref(post));
    K_R_end_over_k(c) = K_R(end)/k_p(end);
    M_R_end_over_m(c) = M_R(end)/m_p;
end
fprintf(['El Centro, %.1f ms delay, specimen stiffness -30%% at %.0f s; ' ...
    'errors after damage (NaN = unstable):\n'], 1e3*delay_n*dt, t(end)/2);
disp(table(d_n_NRMSE_pct, d_p_NRMSE_pct, x1_NRMSE_pct, K_R_end_over_k, ...
    M_R_end_over_m, 'RowNames', names))

assert(all(isfinite(d_n_NRMSE_pct(3:5))), 'An R-D case became unstable.')
assert(abs(d_n_NRMSE_pct(6) - d_n_NRMSE_pct(4)) < 1e-9, ...
    'The Simulink runtime does not match step_HS_robin.')
assert(d_n_NRMSE_pct(4) < d_n_NRMSE_pct(3), ...
    'Adaptive R-D did not improve on fixed R-D after damage.')
assert(abs(K_R_end_over_k(4) - eta(3)) < 0.05, 'K_R did not track the damage.')
assert(abs(M_R_end_over_m(5) - eta(1)) < 0.01, 'M_R did not converge to m_hat.')
disp('vHS_robin checks passed.')

function [dd, x1, K_R, M_R, u] = runHybrid(hs, prm, ag, k_p, m_p, c_p, ...
        delay_n, dt, m_hat, runtime)
% Virtual specimen under pure delay; kinematics by backward differences
% (runtime: the Simulink block function, a = accelerometer).
dd = zeros(size(ag));
[x1, K_R, M_R, u, v] = deal(dd);
x = [];
if ~isempty(prm), s = step_HS_robin('state', prm); end
clear hybrid_simulation_robin_runtime
for j = 2:numel(ag)
    if j > delay_n, u(j) = dd(j - delay_n)/1000; end
    v(j) = (u(j) - u(j-1))/dt;
    a = (v(j) - v(j-1))/dt;
    fm = m_p*a + c_p*v(j) + k_p(j)*u(j);
    if isempty(prm)
        [dd(j), x] = step_HS(fm, 0, dt, hs, x);
        x1(j) = x(1);
    else
        if runtime
            [dd(j), s] = hybrid_simulation_robin_runtime(fm, u(j), a, ...
                m_hat, 0, prm, hs.time, hs.ag, hs.time_scale_factor);
        else
            [dd(j), s] = step_HS_robin(fm, u(j), v(j), a, ag(j), m_hat, s, prm);
        end
        x1(j) = s.x(1);
        K_R(j) = s.K_R;
        M_R(j) = s.M_R;
    end
    if ~isfinite(dd(j)) || abs(dd(j)) > 1e4
        [dd(:), x1(:), K_R(:), M_R(:), u(:)] = deal(NaN);
        return
    end
end
end
