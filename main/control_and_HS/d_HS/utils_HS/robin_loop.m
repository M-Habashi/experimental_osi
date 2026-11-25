function g = robin_loop(ns, K_R, dZ)
%ROBIN_LOOP Loop transfer functions of stiffness-only Robin-Dirichlet coupling.
%   g = robin_loop(ns, K_R)       measured nominal state (robin_nominal_state)
%   g = robin_loop(ns, K_R, dZ)   specimen Z0 + dZ [N/m], reached through
%                                 T = T0/(1 + C0 dZ) (dZ scalar or on ns.f)
%
%   With Z_R = K_R on both sides (M_R = C_R = 0, no force or residual filter):
%     L    open-loop interface transfer function T (Z0 - K_R)/(Z_N + K_R)
%     Gu   force deviation -> measured displacement; dZ* = 1/Gu [N/m]
%     Guw, Gep, Gew   remaining entries of the mixed loop of the adaptive
%                     Robin stiffness (nonlinear R-D paper, Eq. robin_mimo)

if nargin < 3, dZ = 0; end
T = ns.T./(1 + ns.C0.*dZ);
C0 = ns.C0./(1 + ns.C0.*dZ);
Z0 = ns.Z0 + dZ;
D = ns.ZN + K_R + T.*(Z0 - K_R);
g = struct('L', T.*(Z0 - K_R)./(ns.ZN + K_R), ...
    'Gu', -(T + C0.*(ns.ZN + K_R))./D, 'Guw', T./D, ...
    'Gep', (T - 1 + C0.*(ns.ZN + Z0))./D, 'Gew', (1 - T)./D);
end
