function [dd, state, ok] = step_HS_nonlinear(fm, pause_enable, cfg, state)
%STEP_HS_NONLINEAR Advance one nonlinear Hybrid Simulation sample.
% Same clock, pause, force sign and Newmark average acceleration as
% step_HS, on the full-DOF frame from prepare_hs_nonlinear with
% concentrated plastic hinges (return mapping by active-set solve).
% On active-set nonconvergence the previous state and dd are held and
% ok = false. State: [x; v; a; p; tau; dd; record_index].
% Units: fm [N], state [m, rad, s], dd [mm].

nd = size(cfg.K, 1);
nh = numel(cfg.Mp);
if isempty(state)
    state = zeros(3*nd + nh + 3, 1);
end
ok = true;
dd_index = 3*nd + nh + 2;
dd = state(dd_index);
if pause_enable ~= 0
    return
end

x = state(1:nd);
v = state(nd+1:2*nd);
acc = state(2*nd+1:3*nd);
p = state(3*nd+1:3*nd+nh);
tau = state(3*nd+nh+1);
record_index = max(1, round(state(3*nd+nh+3)));

tau_next = tau + cfg.dt/cfg.time_scale_factor;
[ag, record_index] = groundAcceleration(cfg.time, cfg.ag, tau_next, ...
    record_index);
force = cfg.g*ag + cfg.f*(cfg.force_sign*fm);

c = cfg.newmark;
rhs = force + cfg.M*(c(1)*x + c(3)*v + c(4)*acc) ...
    + cfg.C*(c(2)*x + c(5)*v + c(6)*acc);
trial = cfg.Ai*(rhs + cfg.BD*p);

% Trial relative moment m - H*p; plastic increments only where it exceeds Mp.
xi = cfg.DB*trial - cfg.DH*p;
active = double(abs(xi) > cfg.Mp + 1e-7);
sg = sign(xi);
dp = zeros(nh, 1);
if any(active)
    ok = false;
    for it = 1:cfg.max_iter
        dp = (cfg.S.*(active*active') + diag(1 - active)) ...
            \(active.*(xi - sg.*cfg.Mp));
        bad = active > 0 & sg.*dp < -1e-12;
        if any(bad)
            active(bad) = 0;
            continue
        end
        corrected = xi - cfg.S*dp;
        add = active == 0 & abs(corrected) > cfg.Mp + 1e-5;
        if any(add)
            active(add) = 1;
            sg = sg + add.*(sign(corrected) - sg);
            continue
        end
        ok = true;
        break
    end
    if ~ok
        return
    end
end

x_next = trial + cfg.Q*dp;
p_next = p + dp;
a_next = c(1)*(x_next - x) - c(3)*v - c(4)*acc;
v_next = v + cfg.dt*((1 - 0.5)*acc + 0.5*a_next);
dd = 1000*(cfg.out_x*x_next + cfg.out_p*p_next);

state(1:nd) = x_next;
state(nd+1:2*nd) = v_next;
state(2*nd+1:3*nd) = a_next;
state(3*nd+1:3*nd+nh) = p_next;
state(3*nd+nh+1) = tau_next;
state(dd_index) = dd;
state(3*nd+nh+3) = record_index;
end

function [ag, record_index] = groundAcceleration(time, acceleration, ...
        tau, record_index)
% Same interpolation as step_HS. Units: time/tau [s], ag [m/s^2].
last_index = numel(time);
if tau > time(last_index)
    ag = 0.0;
    record_index = last_index;
    return
end
while record_index < last_index && time(record_index + 1) < tau
    record_index = record_index + 1;
end
if record_index >= last_index
    ag = acceleration(last_index);
else
    t0 = time(record_index);
    t1 = time(record_index + 1);
    if t1 > t0
        fraction = (tau - t0)/(t1 - t0);
    else
        fraction = 0.0;
    end
    ag = acceleration(record_index) ...
        + fraction*(acceleration(record_index + 1) - acceleration(record_index));
end
end
