function cfg = prepare_hs_nonlinear(hs, dt, kind, k_spring)
%PREPARE_HS_NONLINEAR Constant matrices for step_HS_nonlinear.
% Full-DOF frame with elastic member interiors and concentrated plastic
% end rotations at Mp = Fy*Z, linear kinematic hardening H = 0.01*diag(D),
% elastic base springs. kind = 'num' (numerical substructure, dd is the
% interface displacement) or 'ref' (full reference, dd is the
% first-story left column control point). k_spring [N/m] optionally adds
% an elastic experimental spring at the numerical interface.
% Units: N, m, s, rad; dd output [mm].
if nargin < 4, k_spring = 0; end

fem = hs.fem.(kind);
a = fem.assembly;
hinge = sp2_member_model(fem, strcmp(kind, 'num'));
nd = size(a.K_full, 1);
nf = hs.n_floor;

K = a.K_full;
M = zeros(nd);
C = zeros(nd);
g = zeros(nd, 1);
M(a.retained_dofs, a.retained_dofs) = fem.M;
C(1:nf, 1:nf) = hs.C;
g(a.retained_dofs) = -fem.M*fem.influence;
f = zeros(nd, 1);
out_x = zeros(1, nd);
out_p = zeros(1, size(hinge.B, 1));
if strcmp(kind, 'num')
    K(a.interface_dof, a.interface_dof) = ...
        K(a.interface_dof, a.interface_dof) + k_spring;
    f(a.interface_dof) = -1;
    out_x(a.interface_dof) = 1;
else
    % Same Hermite interpolation as referenceControlDisplacement, using
    % elastic end slopes (joint rotation minus plastic rotation).
    L = fem.frame.story_height;
    xi = fem.experimental_column.height/L;
    N2 = L*(xi - 2*xi^2 + xi^3);
    N3 = 3*xi^2 - 2*xi^3;
    N4 = L*(-xi^2 + xi^3);
    out_x(1) = N3;
    rot = a.joint_rotation_dofs;
    if rot(1, 1) > 0, out_x(rot(1, 1)) = -N2; end
    out_x(rot(1, 2)) = -N4;
    out_p(strcmp(hinge.labels, 'C1-S1-bottom')) = N2;
    out_p(strcmp(hinge.labels, 'C1-S1-top')) = N4;
end

hardening_fraction = 0.01;
B = hinge.B;
D = hinge.D;
H = hardening_fraction*diag(D);
beta = 1/4;
gamma = 1/2;
c = [1/(beta*dt^2), gamma/(beta*dt), 1/(beta*dt), 1/(2*beta) - 1, ...
    gamma/beta - 1, dt*(gamma/(2*beta) - 1)];
Ai = (K + c(1)*M + c(2)*C)\eye(nd);
BD = B'*D;
Q = Ai*BD;
S = D + diag(H) - D*B*Q;

cfg = struct('kind', kind, 'dt', dt, 'n_floor', nf, ...
    'M', M, 'C', C, 'K', K, 'g', g, 'f', f, 'Ai', Ai, 'BD', BD, ...
    'Q', Q, 'DB', D*B, 'DH', D + diag(H), 'S', (S + S')/2, ...
    'Mp', hinge.Mp, 'My', hinge.My, 'H', H, 'B', B, 'D', D, ...
    'labels', {hinge.labels}, 'newmark', c, ...
    'out_x', out_x, 'out_p', out_p, 'k_spring', k_spring, ...
    'time', hs.time, 'ag', hs.ag, ...
    'time_scale_factor', hs.time_scale_factor, ...
    'force_sign', hs.force_sign, 'max_iter', 30, ...
    'Fy', 344737894.475789, 'hardening_fraction', hardening_fraction);
end
