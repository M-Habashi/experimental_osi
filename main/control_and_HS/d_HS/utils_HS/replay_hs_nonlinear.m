function [u_floors, dd, fails, a_floors, hinges] = replay_hs_nonlinear(cfg, fm)
%REPLAY_HS_NONLINEAR Step a prepare_hs_nonlinear configuration from rest.
% Sample 1 is the initial state, matching the step_HS loops in vHS.
% Units: fm [N], u_floors [m], dd [mm].
% Optional a_floors contains relative floor accelerations [m/s^2].
n = numel(fm);
state = [];
u_floors = zeros(n, cfg.n_floor);
dd = zeros(n, 1);
fails = 0;
if nargout > 3, a_floors = zeros(n, cfg.n_floor); end
nd = size(cfg.K, 1);
hinges = [];
for step = 2:n
    [dd(step), state, ok] = step_HS_nonlinear(fm(step), 0, cfg, state);
    u_floors(step, :) = state(1:cfg.n_floor)';
    if nargout > 3
        a_floors(step, :) = state(2*nd+(1:cfg.n_floor))';
    end
    if nargout > 4
        hinges = hs_hinge_summary(hinges, cfg, state(1:nd), ...
            state(3*nd+(1:numel(cfg.Mp))), state(3*nd+numel(cfg.Mp)+1));
    end
    fails = fails + ~ok;
end
end
