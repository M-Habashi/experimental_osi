function result = compare_sp4_degraded_identification
%COMPARE_SP4_DEGRADED_IDENTIFICATION Paper 1 prediction versus SP4 branch ID.
% BLWN/sine PID-actuator path; the numerical FEM/HS lead is not in this loop.
project = fileparts(fileparts(mfilename('fullpath')));
hfile = fullfile(project, 'saved_results', 'exp_tf', 'tf_sp4_20261116_130910.mat');
dfile = fullfile(project, 'saved_results', 'exp_tf', 'tf_SP4_dmgd_20261116_142110.mat');
h = load(hfile);
d = load(dfile);
hp = h.specimen_params;
dp = d.specimen_params;
pv = h.pid_values;
s = tf('s');
controller = pid(pv.P, pv.I, pv.D, 1/pv.derivative_filter_N);
controller_z = pid(pv.P, pv.I, pv.D, 1/pv.derivative_filter_N, pv.dt, ...
    'IFormula', 'ForwardEuler', 'DFormula', 'ForwardEuler');
Ga1 = h.a1b0/(s^2 + h.beta1*s + h.beta2);
Ga2 = h.a2*s;
Ga3 = 1/(s + h.a3);
Cin = h.Kp + h.Ki/s;
Y = minreal(Ga3*(Ga2 + Cin*Ga1*(controller + 1)), 1e-8);
zeta = hp.c/(2*sqrt(hp.m*hp.k));
equation = @(w) criticalEquation(w, Y, hp.m, zeta);
w = logspace(-1, log10(2*pi*1000), 20000);
response = squeeze(freqresp(Y, w));
residual = hp.m*w(:).^2 - real(response(:)) ...
    - imag(response(:)).^2./(4*zeta^2*hp.m*w(:).^2);
crossings = find(residual(1:end-1).*residual(2:end) < 0);
roots_w = arrayfun(@(i) fzero(equation, w(i+[0 1])), crossings);
yr = arrayfun(@(wr) evalfr(Y, 1i*wr), roots_w);
alphas = imag(yr).^2./(4*zeta^2*roots_w.^2*hp.m*hp.k);
physical = alphas > 0 & alphas <= 1 & imag(yr) < 0;
valid_w = roots_w(physical);
[alpha_cr, selected] = max(alphas(physical));
omega_cr = valid_w(selected);

sampled_max_pole = @(a) max(abs(pole(feedback(controller_z ...
    * c2d(analogModel(h, hp.m, hp.c*sqrt(a), hp.k*a), pv.dt, 'zoh'), 1))));
alpha_sampled = fzero(@(a) sampled_max_pole(a)-1, [0.05 1]);
boundary_z = pole(feedback(controller_z*c2d(analogModel(h, hp.m, ...
    hp.c*sqrt(alpha_sampled), hp.k*alpha_sampled), pv.dt, 'zoh'), 1));
[~, dominant_z] = max(abs(boundary_z));
f_sampled = abs(angle(boundary_z(dominant_z)))/(2*pi*pv.dt);

f = linspace(0.1, 80, 30000);
mag = abs(squeeze(freqresp(d.H_dd_dm, 2*pi*f)));
mag = mag(:);
peaks = find(mag(2:end-1) > mag(1:end-2) ...
    & mag(2:end-1) > mag(3:end)) + 1;
peaks = peaks(f(peaks) >= 5);
[~, largest] = max(mag(peaks));
peak = peaks(largest);
f_res = fminbnd(@(ff) -abs(evalfr(d.H_dd_dm, 2i*pi*ff)), ...
    f(peak-1), f(peak+1));

alpha_branch = dp.k/hp.k;
predicted_branch_poles = pole(feedback(controller ...
    * analogModel(h, hp.m, hp.c*sqrt(alpha_branch), dp.k), 1));
result = struct('healthy_file', hfile, 'degraded_file', dfile, ...
    'loop', 'PID/actuator loop on BLWN or sine path; no HS lead or FEM', ...
    'healthy_mass_kg', hp.m, 'degraded_mass_kg', dp.m, ...
    'healthy_stiffness_N_m', hp.k, 'degraded_stiffness_N_m', dp.k, ...
    'healthy_damping_Ns_m', hp.c, 'degraded_damping_Ns_m', dp.c, ...
    'healthy_zeta', zeta, 'degraded_zeta', dp.c/(2*sqrt(dp.m*dp.k)), ...
    'measured_branch_stiffness_ratio', alpha_branch, ...
    'predicted_alpha_cr', alpha_cr, 'predicted_f_cr_hz', omega_cr/(2*pi), ...
    'sampled_predicted_alpha_cr', alpha_sampled, ...
    'sampled_predicted_f_cr_hz', f_sampled, ...
    'measured_degraded_resonance_hz', f_res, ...
    'frequency_difference_percent', 100*(omega_cr/(2*pi)-f_res)/f_res, ...
    'sampled_frequency_difference_percent', 100*(f_sampled-f_res)/f_res, ...
    'experimental_alpha_cr', NaN, 'experimental_f_cr_hz', NaN, ...
    'measured_H_dd_dm_max_real_pole', max(real(pole(d.H_dd_dm))), ...
    'prediction_at_branch_max_real_pole', max(real(predicted_branch_poles)), ...
    'pid_values', pv, ...
    'assumptions', 'Healthy hydraulic/inner parameters fixed; constant mass and damping ratio; stiffness scaled by alpha.', ...
    'interpretation', 'Measured branch ratio and stable resonance are not an observed instability boundary.');
save(fullfile(project, 'outputs', 'sp4_degraded_identification_comparison.mat'), 'result');
disp(result)
fprintf('SP4_COMPARISON_JSON %s\n', jsonencode(result));
end

function value = criticalEquation(w, Y, mass, zeta)
y = evalfr(Y, 1i*w);
value = mass*w^2-real(y)-imag(y)^2/(4*zeta^2*w^2*mass);
end

function H = analogModel(p, mass, damping, stiffness)
q = [1 p.beta1 p.beta2];
num = p.a1b0*[p.Kp p.Ki];
den = conv([1 0], conv([1 p.a3], conv(q, [mass damping stiffness])));
den(end-4:end) = den(end-4:end) + conv([p.a2 0 0], q);
den(end-1:end) = den(end-1:end) + num;
H = tf(num, den);
end
