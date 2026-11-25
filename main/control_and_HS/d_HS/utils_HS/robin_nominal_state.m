function ns = robin_nominal_state(rec, tsm, prm, lead, command_gain, opts)
%ROBIN_NOMINAL_STATE Measured nominal state of the RTHS loop from a pretest.
%   ns = robin_nominal_state(rec, tsm, prm, lead, command_gain)
%   ns = robin_nominal_state(..., opts)
%
%   Pretest: band-limited white noise on the PID reference dd with the
%   specimen attached and no numerical substructure (companion stability
%   study, Sections 5.1 and 6.2). With dd as the instrumental variable,
%   Welch estimates (Hann segments, 50% overlap) give the tracking response
%   dd -> dm and the specimen dynamic stiffness Z0 = S_dd,fm/S_dd,dm. They
%   are interpolated onto a fine grid on which the numerical substructure and
%   the lead filter of the test are evaluated exactly. The measured loop gain
%   T/(1 - T) of the pretest (PID times plant) converts the tracking to the
%   command gain of the test, so the PID controller of the pretest and the
%   test must be the same.
%
%   rec          pretest record: dd [mm], dm [mm], fm [N], and fs [Hz] or
%                t [s]; optional g_id, the command gain of the pretest
%                (default 1). Trim the record to its stationary part first.
%   tsm          transfer-system model u = G_a v - H_a f, fields beta1,
%                beta2, a2, a3, Kp, Ki (SI): parametric_identification.
%                identified_params of the exp_tf file fitted to the pretest.
%   prm          step_HS_robin('params', ...) of the test (numerical
%                substructure and time step).
%   lead         lead filter of the test: struct with num and den of the
%                discrete transfer function (phase_lead_num, phase_lead_den).
%   command_gain command gain of the test.
%   opts         f_max [Hz] (80), df [Hz] (0.0125), segment_s [s] (8).
%
%   ns fields (column vectors on ns.f): T (test tracking, lead included),
%   Tg (without lead), C0 [m/N], Z0 [N/m], ZN [N/m]; scalars k0 [N/m] (mean
%   of Re Z0 over 0.5-2 Hz), m [kg], c [N*s/m], k_fit [N/m] (fit of
%   m s^2 + c s + k to Z0 over 2-50 Hz), dt [s].

if nargin < 6, opts = struct(); end
f_max = option(opts, 'f_max', 80);
df = option(opts, 'df', 0.0125);
seg_s = option(opts, 'segment_s', 8);
g_id = option(rec, 'g_id', 1);
if isfield(rec, 'fs'), fs = rec.fs; else, fs = 1/mean(diff(rec.t(:))); end

%% Welch estimates with dd as the instrumental variable
n_seg = round(seg_s*fs);
hop = n_seg/2;
win = hann(n_seg, 'periodic');
x = [rec.dd(:), rec.dm(:), rec.fm(:)];
n_avg = floor((size(x, 1) - n_seg)/hop) + 1;
assert(n_avg >= 4, 'robin_nominal_state:ShortRecord', ...
    'The pretest record holds fewer than four %g s segments.', seg_s)
f_bin = (0:n_seg/2)'*fs/n_seg;
keep = f_bin >= 0.4 & f_bin <= f_max + 1;
S = zeros(nnz(keep), 3);                       % S_dd,dd, S_dd,dm, S_dd,fm
for i = 1:n_avg
    seg = x((i - 1)*hop + (1:n_seg), :);
    X = fft((seg - mean(seg, 1)).*win);
    X = X(keep, :);
    S = S + conj(X(:, 1)).*X;
end
f = (0.5:df:f_max)';
ip = @(y) interp1(f_bin(keep), real(y), f) + 1i*interp1(f_bin(keep), imag(y), f);
T1 = ip(S(:, 2)./S(:, 1));                     % dd -> dm at the pretest gain
Z0 = ip(1e3*S(:, 3)./S(:, 2));                 % [N/m]

%% Test configuration: command gain, lead filter, numerical substructure
h = prm.dt;
z = exp(2i*pi*f*h);
L1 = T1./(1 - T1);                             % g_id*PID*G_p
L = command_gain/g_id*L1;                      % command_gain*PID*G_p
Tg = L./(1 + L);
W = polyval(lead.num, z)./polyval(lead.den, z);
s = 2i*pi*f;
q = s.^2 + tsm.beta1*s + tsm.beta2;
Ha = s.*(s + tsm.a3).*q./(tsm.a2*s.^2.*q + tsm.Kp*s + tsm.Ki);   % [m/N]
C0 = Ha./((1 + Ha.*Z0).*(1 + L));

n = size(prm.K, 1);
e = [zeros(n - 1, 1); 1];
M = blkdiag(prm.M, 0);
Cn = blkdiag(prm.C, 0);
sT = 2/h*(z - 1)./(z + 1);                     % Newmark average acceleration
ZN = zeros(size(f));
for j = 1:numel(f)
    ZN(j) = 1/(e'*((prm.K + sT(j)*Cn + sT(j)^2*M)\e));
end

%% Nominal stiffness, mass, and damping
k0 = mean(real(Z0(f <= 2)));
fit = f >= 2 & f <= 50;
w = 2*pi*f(fit);
km = [ones(nnz(fit), 1), -w.^2]\real(Z0(fit));
c = w\imag(Z0(fit));

ns = struct('f', f, 'T', W.*Tg, 'Tg', Tg, 'C0', C0, 'Z0', Z0, 'ZN', ZN, ...
    'k0', k0, 'm', km(2), 'c', c, 'k_fit', km(1), 'dt', h, ...
    'command_gain', command_gain, 'segments', n_avg);
end

function v = option(s, name, default)
if isfield(s, name) && ~isempty(s.(name)), v = s.(name); else, v = default; end
end
