function [dd, state] = step_HS_robin(varargin)
%STEP_HS_ROBIN Fixed or adaptive Robin-Dirichlet Hybrid Simulation step.
%   prm = step_HS_robin('params', hs, dt, specimen_si, override)
%   prm = step_HS_robin('design', prm, T, f_band, eps_N)   % sets L*
%   prm = step_HS_robin('design', prm, T, f_band, eps_N, eta_max)
%   eta_max = [0; 0; 1] restricts the design to stiffness only.
%   state = step_HS_robin('state', prm)
%   [dd, state] = step_HS_robin(fm, um, vm, am, ag, m_hat, state, prm)
%
%   Same numerical substructure and Newmark scheme as step_HS, with the
%   Robin operator L = M_R*s^2 + C_R*s + K_R added to the interface DOF and
%   subtracted from the measured force (Robin-Dirichlet RTHS papers):
%       r = fm - M_R*am - C_R*vm - K_R*um,   load on interface = -r.
%   The operator starts at L = eta_M*M0*s^2 + eta_C*C0*s + eta_K*K0.
%     adapt_M = adapt_K = false  fixed R-D (linear paper): L is constant.
%     adapt_M and/or adapt_K  adaptive R-D (nonlinear paper, design.tex
%       Eqs. mass_update, stiffness_moments, stiffness_update): M_R and/or
%       K_R update every update_n samples. C_R is always constant.
%       K_R follows the slope of a regularized affine fit f = K*u + b over
%       the exponentially weighted recent path (RLS with forgetting): the
%       slope is invariant to force offsets and residual deformation, and
%       the regularization returns it to K_cal when the motion is small.
%   New coefficients act from the next step, so augmentation and
%   subtraction always use the same values. L = 0 reproduces step_HS.
%
%   specimen_si: output of specimen_params_si (mass, damping, stiffness).
%   m_hat: online physical-mass estimate (e.g. TSE m_hat); NaN holds M_R.
%   Units: fm [N], um [m], vm [m/s], am [m/s^2], ag [m/s^2], m_hat [kg],
%   dd [mm]. The step call is code-generation safe; Simulink calls it
%   through hybrid_simulation_robin_runtime.m.

if ischar(varargin{1}) || isstring(varargin{1})
    switch lower(char(varargin{1}))
        case 'params'
            override = struct();
            if nargin >= 5, override = varargin{5}; end
            dd = makeParams(varargin{2}, varargin{3}, varargin{4}, override);
        case 'design'
            dd = designRobin(varargin{2:end});
        case 'state'
            prm = varargin{2};
            dd = struct('x', zeros(3*size(prm.K, 1), 1), ...
                'M_R', prm.eta_M*prm.M0, 'C_R', prm.eta_C*prm.C0, ...
                'K_R', prm.eta_K*prm.K_cal, ...
                'S_1', 0, 'S_u', 0, 'S_f', 0, 'S_uf', 0, 'S_uu', 0, ...
                'power', 0, 'count', 0);
        otherwise
            error('step_HS_robin:UnknownCommand', ...
                'Use ''params'', ''state'', or a numeric step call.')
    end
    state = [];
    return
end
[dd, state] = stepRobin(varargin{:});
end

function prm = makeParams(hs, dt, specimen_si, override)
% Full [floors; interface] matrices rebuilt from the condensed hs fields.
K_fi = hs.K_if.';
M0 = specimen_si.mass;
K_cal = specimen_si.stiffness;
prm = struct('dt', dt, 'n', hs.n_floor, 'M', hs.M, 'C', hs.C, ...
    'K', [hs.K + K_fi*(hs.K_ii\hs.K_if), K_fi; hs.K_if, hs.K_ii], ...
    'ground_force_gain', hs.ground_force_gain, ...
    'force_sign', hs.force_sign, ...
    'M0', M0, ...                 % nominal physical interface mass [kg]
    'C0', specimen_si.damping, ... % nominal physical damping [N*s/m]
    'K_cal', K_cal, ...           % independently fitted stiffness [N/m]
    'eta_M', 1, 'eta_C', 0, 'eta_K', 1, ...
    'adapt_M', false, 'adapt_K', true, ... % both false = fixed R-D
    ... % Robin mass box for adapt_M. Closed by default: the stable M_R
    ... % window moves with the tracking delay, so open it only after
    ... % checking its corners at the expected delay (see vHS_robin.m).
    'M_bounds', [1 1]*M0, ...
    'M_phys', [0.65 1.35]*M0, ...  % admitted physical-mass estimates
    'K_max', 1.25*K_cal, ...
    'update_n', round(0.02/dt), ... % h_R = 20 ms
    'T_M', 0.25, ...              % mass relaxation time [s]
    'Mdot_max', 0.5*M0, ...       % mass rate limit [kg/s]
    'T_K', 0.5, ...               % stiffness-fit forgetting time [s]
    'eps_u', 1e-8, ...            % fit regularization, (0.1 mm)^2 [m^2]:
    ...                           % a few displacement-noise variances
    'a_rms_min', 0.03, ...        % excitation needed to move M_R [m/s^2]
    'T_power', 0.5);              % acceleration-power window [s]
names = fieldnames(override);
for i = 1:numel(names)
    assert(isfield(prm, names{i}), 'Unknown parameter: %s', names{i})
    prm.(names{i}) = override.(names{i});
end
end

function prm = designRobin(prm, T, f_band, eps_N, eta_max)
% Selected Robin operator L* (linear paper, Eq. robin_design): minimize
% max|E^P| over f_band [Hz] subject to Schur stability and max|E^N| <=
% eps_N, with 0 <= eta <= 1. T: discrete tracking transfer dd [m] -> um [m]
% (e.g. phase lead x PID-actuator loop, or z^-d). Nominal specimen.
% fmincon from the largest allowed operator: local optimum.
bounded_design = nargin >= 5;
if ~bounded_design
    eta_max = ones(3, 1);
end
h = prm.dt;
f = linspace(f_band(1), f_band(2), 2000)';
z = exp(2i*pi*h*f);
sT = 2/h*(z - 1)./(z + 1);          % Newmark average acceleration = Tustin
sb = (1 - 1./z)/h;                  % backward-difference measured kinematics
e_n = [zeros(prm.n, 1); 1];
Zn = arrayfun(@(s) 1/(e_n'*((prm.K + s*blkdiag(prm.C, 0) ...
    + s^2*blkdiag(prm.M, 0))\e_n)), sT);  % numerical interface stiffness
Z0 = @(s, e) e(1)*prm.M0*s.^2 + e(2)*prm.C0*s + e(3)*prm.K_cal;
Tr = squeeze(freqresp(T, 2*pi*f));
EN = @(x) (Zn + Z0(sT, [1 1 1]))./(Zn + Z0(sT, x) + Tr.*Z0(sb, 1 - x)) - 1;
T = ss(T);
con = @(x) deal([abs(Tr.*(EN(x) + 1) - 1) - x(4); abs(EN(x)) - eps_N; ...
    spectralRadius(prm, x, T) - (1 - 1e-5)], []);
options = optimoptions('fmincon', 'Algorithm', 'sqp', 'Display', 'off');
[x, ~, exitflag] = fmincon(@(x) x(4), [eta_max; 1], [], [], [], [], ...
    zeros(4, 1), [eta_max; Inf], con, options);
if bounded_design
    [constraints, ~] = con(x);
    assert(exitflag > 0 && all(constraints <= options.ConstraintTolerance), ...
        'The bounded Robin design did not satisfy the stability and error constraints.');
end
[prm.eta_M, prm.eta_C, prm.eta_K] = deal(x(1), x(2), x(3));
end

function rho = spectralRadius(prm, eta, T)
% Schur radius of the closed loop with a nominal specimen tracking through
% T (state space, no feedthrough), assembled column by column from
% stepRobin itself. Extra states: T states, um[k-1], um[k-2].
[prm.eta_M, prm.eta_C, prm.eta_K] = deal(eta(1), eta(2), eta(3));
[prm.adapt_M, prm.adapt_K] = deal(false);
s0 = step_HS_robin('state', prm);
nx = numel(s0.x);
nt = size(T.A, 1);
A = zeros(nx + nt + 2);
for j = 1:size(A, 1)
    X = zeros(size(A, 1), 1);
    X(j) = 1;
    xt = X(nx+1:nx+nt);
    u = T.C*xt;
    v = (u - X(end-1))/prm.dt;
    a = (v - (X(end-1) - X(end))/prm.dt)/prm.dt;
    s = s0;
    s.x = X(1:nx);
    [dd, s] = stepRobin(prm.M0*a + prm.C0*v + prm.K_cal*u, u, v, a, ...
        0, NaN, s, prm);
    A(:, j) = [s.x; T.A*xt + T.B*dd/1000; u; X(end-1)];
end
rho = max(abs(eig(A)));
end

function [dd, state] = stepRobin(fm, um, vm, am, ag, m_hat, state, prm)
n = size(prm.K, 1);
x = state.x;
u = x(1:n);
v = x(n+1:2*n);
a = x(2*n+1:3*n);

f = prm.force_sign*fm;
r = f - state.M_R*am - state.C_R*vm - state.K_R*um;
M = blkdiag(prm.M, state.M_R);
C = blkdiag(prm.C, state.C_R);
K = prm.K;
K(n, n) = K(n, n) + state.K_R;
force = [prm.ground_force_gain*ag; -r];

h = prm.dt;
beta = 1/4;
gamma = 1/2;
a0 = 1/(beta*h^2);
a1 = gamma/(beta*h);
a2 = 1/(beta*h);
a3 = 1/(2*beta) - 1;
a4 = gamma/beta - 1;
a5 = h*(gamma/(2*beta) - 1);
u_next = (K + a0*M + a1*C)\(force ...
    + M*(a0*u + a2*v + a3*a) + C*(a1*u + a4*v + a5*a));
a_next = a0*(u_next - u) - a2*v - a3*a;
v_next = v + h*((1 - gamma)*a + gamma*a_next);
if state.M_R == 0 && state.C_R == 0 && ~prm.adapt_M
    % The interface is algebraic. Its derivative history does not enter the solve.
    v_next(n) = 0;
    a_next(n) = 0;
end
state.x = [u_next; v_next; a_next];
dd = 1000*u_next(n);

% Adaptive R-D coefficient update, active from the next step.
state.power = state.power + (1 - exp(-h/prm.T_power))*(am^2 - state.power);
state.count = state.count + 1;
if mod(state.count, prm.update_n) ~= 0, return, end
h_R = prm.update_n*h;
mass_ok = m_hat >= prm.M_phys(1) && m_hat <= prm.M_phys(2); % NaN fails
if prm.adapt_M && mass_ok && state.power >= prm.a_rms_min^2
    target = min(max(prm.eta_M*m_hat, prm.M_bounds(1)), prm.M_bounds(2));
    dM = (1 - exp(-h_R/prm.T_M))*(target - state.M_R);
    state.M_R = state.M_R + min(max(dM, -prm.Mdot_max*h_R), ...
        prm.Mdot_max*h_R);
end
if prm.adapt_K
    m_fit = prm.M0;
    if mass_ok, m_fit = m_hat; end
    f_int = f - m_fit*am;
    b = 1 - exp(-h_R/prm.T_K);
    state.S_1 = state.S_1 + b*(1 - state.S_1);
    state.S_u = state.S_u + b*(um - state.S_u);
    state.S_f = state.S_f + b*(f_int - state.S_f);
    state.S_uf = state.S_uf + b*(um*f_int - state.S_uf);
    state.S_uu = state.S_uu + b*(um^2 - state.S_uu);
    % Weighted covariance and variance (times S_1 > 0) of the recent path.
    c_uf = state.S_uf - state.S_u*state.S_f/state.S_1;
    v_uu = state.S_uu - state.S_u^2/state.S_1;
    state.K_R = min(max(prm.eta_K*(c_uf + prm.eps_u*state.S_1*prm.K_cal) ...
        /(v_uu + prm.eps_u*state.S_1), 0), prm.K_max);
end
end
