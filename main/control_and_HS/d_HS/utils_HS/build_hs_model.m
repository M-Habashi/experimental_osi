function hs = build_hs_model(fem, earthquake_type, intensity_factor, ...
        time_scale_factor, force_sign, project_folder)
%BUILD_HS_MODEL Condensed numerical substructure and ground motion of a test.
%   hs = build_hs_model(fem, earthquake_type, intensity_factor, ...
%       time_scale_factor, force_sign, project_folder)
%   The same model as main_ColumnSetup.m: floors with the massless
%   interface condensed out, Rayleigh damping from the reference FEM, and
%   the scaled earthquake record. Units: SI; time [s], ag [m/s^2].

fem_num = fem.num;
floor_dofs = fem_num.floor_dofs(:)';
interface_dof = fem_num.interface_dof;
K_num = fem_num.K;
K_ff = K_num(floor_dofs, floor_dofs);
K_fi = K_num(floor_dofs, interface_dof);
K_if = K_num(interface_dof, floor_dofs);
K_ii = K_num(interface_dof, interface_dof);

hs.fem = fem;
hs.n_floor = numel(floor_dofs);
hs.M = fem_num.M(floor_dofs, floor_dofs);
hs.K = K_ff - K_fi*(K_ii\K_if);
hs.K_if = K_if;
hs.K_ii = K_ii;
hs.force_to_floor = K_fi/K_ii;
hs.interface_from_floor = -K_ii\K_if;
hs.interface_from_force = -1/K_ii;
hs.ground_force_gain = -(hs.M*fem_num.influence(floor_dofs(:)));
[hs.C, hs.damping] = femDampingMatrix(fem.ref, fem);
hs.damping_ratio = hs.damping.target_ratio;
hs.earthquake_type = earthquake_type;
hs.intensity_factor = intensity_factor;
earthquakes = load(fullfile(project_folder, 'input_signals', ...
    'earthquakes.mat'), earthquake_type);
earthquake = earthquakes.(earthquake_type);
hs.time = earthquake(:, 1) - earthquake(1, 1);
hs.ag = intensity_factor*earthquake(:, 2);
hs.time_scale_factor = time_scale_factor;
hs.force_sign = force_sign;
end
