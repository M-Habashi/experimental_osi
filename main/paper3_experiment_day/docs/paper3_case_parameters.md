# Paper 3 case parameters (SP4, 19 November 2026)

All numbers below are recreated by
[`results_analysis/paper3_case_parameters.m`](../results_analysis/paper3_case_parameters.m)
from files in this folder only. It saves `outputs/paper3_case_parameters.mat`
(one `result` struct). Inputs were copied and trimmed from the canonical project
by [`results_analysis/paper3_extract_case_data.m`](../results_analysis/paper3_extract_case_data.m).

## Input files (`saved_results/paper3_cases/`)

| File in this folder | Full recording (`saved_results/`, original name) | Content |
| --- | --- | --- |
| `id_healthy_gain1_20261119_2009_t085_218s.mat` | `tests/20261119/id_healthy_gain1_20261119_2009.mat` (was `20261119_2009_testing_OSI.mat`), 85-218 s | Healthy identification: diagnostic gain 1, numerical substructure active, broadband command, authority 1. |
| `case1_notch_off_gain3p5_20261119_2052.mat` | `tests/20261119/case1_notch_off_unstable_gain3p5_20261119_2052.mat` (was `20261119_2052_testing_OSI.mat`), full record | Case 1 run: PID notch off, diagnostic gain 3.5. |
| `case2_notch_on_gain3p5_20261120_1035.mat` | `tests/20261120/case2_notch_on_stable_gain3p5_20261120_1035.mat` (was `20261120_1035_testing_OSI.mat`), full record | Case 2 run: PID notch on, diagnostic gain 3.5. |
| `case3_notch_on_osi_on_gain3p5_20261120_1052.mat` | `tests/20261120/case3_notch_on_osi_on_stable_gain3p5_20261120_1052.mat` (was `20261120_1052_testing_OSI.mat`), full record | Case 3 run: PID notch on, OSI adaptation on, diagnostic gain 3.5. |
| `stiff_notch_off_gain3p5_i0p075_20261120_1125.mat` | `tests/20261120/stiff_notch_off_stable_gain3p5_i0p075_20261120_1125.mat` (was `20261120_1125_testing_OSI.mat`), full record | Stiff-range run: intensity 0.075, PID notch off, gain 3.5. |
| `stiff_notch_on_gain3p5_i0p075_20261120_1142.mat` | `tests/20261120/stiff_notch_on_stable_gain3p5_i0p075_20261120_1142.mat` (was `20261120_1142_testing_OSI.mat`), full record | Stiff-range run: intensity 0.075, PID notch on, gain 3.5. |
| `fem_numerical_rotation_fixed_damping10.mat` | `fem/fem_sp3_1o_rotfix.mat` | Case FEM: `fem_sp3_1o` with numerical interface rotation fixed, 10% Rayleigh damping. |
| `lead_numerical_sp4_bandstop28hz.mat` | `phase_lead/pl_sp4_codesign.mat` | Reference lead on `dd`: SP4 lead x 28 Hz band-stop. |
| `notch_pid_35p3hz.mat` | `controller_notch/notch_sp4.mat` | PID-error notch. |
| `../exp_tf/tf_sp4_20261116_130910.mat` | same | Starting point only for the actuator fit. |

The case runs load the canonical files (`fem_sp3_1o_rotfix.mat`,
`pl_sp4_codesign.mat`, `notch_sp4.mat`) through `main_ColumnSetup.m`.

## Case settings (identical in all cases except `hs.notch` and OSI adaptation)

| Parameter | Value |
| --- | --- |
| Numerical FEM | interface rotation fixed (K_ii 11,672 -> 53,777 N/mm), Rayleigh 10% on modes 1-2, `structural_model = 'linear'` |
| Reference lead | SP4 lead (gain 0.867, zeros 4.21/500 Hz, poles 15.2/120 Hz) x band-stop 28 Hz, zeta 0.03/1.2; `hs.num_notch = false` |
| PID | P 0.12, I 12, D 0.0012, N 512, forward Euler, dt 1/2048 s |
| PID notch | 35.3 Hz, zeta_zero 0.1, zeta_pole 0.2, Tustin; `hs.notch` false (Case 1) / true (Case 2) |
| Diagnostic gain | 3.5 for the whole earthquake (Case 1: 1.5 for the first 27 s of the record, before excitation; Case 2: 3.5 from the start) |
| Excitation | El Centro x 0.5, time scale 20 (stiff-range pair: x 0.075) |
| OSI | Cases 1-2: adaptation off, authority 1. Case 3: adaptation on (initial gain 1, min 0.1, NCF target 0.4, rho_detect 1.35) |

## Identification method

1. Window 85-218 s of the 20:09 record. Hann 8192, 50% overlap, nfft 8192, fs 2048 Hz.
2. Instrument-variable spectra with `dd` as instrument (removes feedback bias):
   `H = S(dd,dm)/S(dd,dc)`, `Z = S(dd,fm)/S(dd,dm)` (MATLAB `cpsd` conjugation corrected).
3. Specimen: least squares of `Z = k - m w^2 + j c w` over 2-50 Hz (coherence > 0.8).
4. Actuator: Paper 1 analog model (`compare_sp4_degraded_identification.m`) plus an input
   delay, fitted to `H` over 2-70 Hz (coherence > 0.85, weight sqrt(coherence)),
   `lsqnonlin`, `rng(1)`, 6 starts.

| Identified | Value |
| --- | --- |
| Specimen | k 7,578 N/mm, m 36.3 kg, c 1,952 N s/m, zeta 0.059 |
| Actuator | beta1 3527, beta2 5.107e5, a2 4.683e7, a3 1.161, Kp 6.327e15, Ki 5.445e16, delay 6.64 ms |
| Fit error | median 3.0%, max 10.9% (2-70 Hz) |

## Predictions and measurement

Stiff critical diagnostic gain from the measured `H` and `Z` (10-70 Hz):

| Loop | PID notch off | PID notch on |
| --- | --- | --- |
| Outer loop only | 3.83 at 38.3 Hz | 5.58 at 42.1 Hz |
| HS (case FEM and lead) | 3.85 at 39.1 Hz | 5.23 at 43.1 Hz |

Paper 1, Eq. (23)-(31), at diagnostic gain 3.5: notch off alpha_cr 0.857 at
37.7 Hz; notch on, no physical root.

Discrete closed loop versus alpha (stiffness alpha k, damping c sqrt(alpha), gain 3.5):

| alpha | 1.0 | 0.9 | 0.8 | 0.6 | 0.4 | 0.2 |
| --- | --- | --- | --- | --- | --- | --- |
| Notch off, max abs(z) | 0.999 | 1.000 | 1.001 (37.3 Hz) | 1.002 (37.7 Hz) | 1.003 (38.1 Hz) | 1.004 (38.5 Hz) |
| Notch on, max abs(z) | 0.996 | 0.996 | 0.996 | 0.996 | 0.996 | 0.996 |

Case 1 measured (`case1_notch_off_gain3p5_20261119_2052.mat`): onset 159.57 s,
gain 3.5, 38.9 Hz, preceding 2 s slope 2,577 N/mm (alpha 0.34). Prediction and
measurement agree to within about 1 Hz.

Case 2 measured (`case2_notch_on_gain3p5_20261120_1035.mat`): stable for the
whole earthquake; the 2 s slope fell to about 1,720 N/mm (alpha 0.23). Max 1 s
RMS of 30-50 Hz `dm` 0.009 mm (Case 1: 1.42 mm at onset).

Case 3 measured (`case3_notch_on_osi_on_gain3p5_20261120_1052.mat`): stable;
slope fell to about 1,770 N/mm. Authority first below 0.99 at 142.6 s, minimum
0.43 at 184.4 s, back to 1 at the end; no trips. RMS(dd-dm)/RMS(dd) over the
active earthquake: 7.39% (Case 2: 7.08%).

Stiff-range pair (intensity 0.075, gain 3.5, OSI off), notch off / on:

| Measure | Notch off (`1125`) | Notch on (`1142`) |
| --- | --- | --- |
| Stability | stable | stable |
| Max 1 s RMS of 30-50 Hz `dm` | 0.0099 mm | 0.0085 mm |
| 4 s secant slope, median (min) | 7,422 (6,429) N/mm | 7,447 (6,489) N/mm |
| Peak abs(`dm`) | 0.63 mm | 0.74 mm |
| RMS(dd-dm)/RMS(dd), 0.02-10 Hz, first 30 s excluded | 5.23% | 5.21% |
| Same, first 60 s excluded | 4.91% | 5.00% |

The first 30 s after command onset contain a start-up transient in both runs and
are excluded. Unfiltered error (about 45% in both) is dominated by measurement
noise above 10 Hz at this small amplitude.

Assumptions: constant mass and damping ratio, stiffness scaled by alpha,
healthy hydraulic parameters fixed. The numerical loop is excluded from the
Paper 1 model; with the case FEM and lead it changes the stiff limit by < 7%.
