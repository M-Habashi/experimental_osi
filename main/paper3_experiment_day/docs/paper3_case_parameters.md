# Paper 3 case parameters (SP4, 19-20 November 2026)

All numbers below are recreated by
[`paper3_case_parameters.m`](../results_analysis/paper3_case_parameters.m)
from files in this folder only; it saves
[`outputs/paper3_case_parameters.mat`](../outputs/paper3_case_parameters.mat)
(one `result` struct). The trimmed inputs are written by
[`paper3_extract_case_data.m`](../results_analysis/paper3_extract_case_data.m)
from the full recordings. The story and file index are in
[Paper 3 story](three_case_experiment_checklist.md).

## Input files (`saved_results/paper3_cases/`)

| File | Source | Content |
| --- | --- | --- |
| [`id_healthy_gain1_20261119_2009_t085_218s.mat`](../saved_results/paper3_cases/id_healthy_gain1_20261119_2009_t085_218s.mat) | `tests/20261119/id_healthy_gain1_20261119_2009.mat`, 85-218 s | Healthy identification: gain 1, numerical substructure active, broadband command, authority 1 |
| [`case1_notch_off_gain3p5_20261119_2052.mat`](../saved_results/paper3_cases/case1_notch_off_gain3p5_20261119_2052.mat) | `tests/20261119/case1_notch_off_unstable_gain3p5_20261119_2052.mat` | Case 1: notch off, OSI off |
| [`case2_notch_on_gain3p5_20261120_1035.mat`](../saved_results/paper3_cases/case2_notch_on_gain3p5_20261120_1035.mat) | `tests/20261120/case2_notch_on_stable_gain3p5_20261120_1035.mat` | Case 2: notch on, OSI off |
| [`case3_notch_on_osi_on_gain3p5_20261120_1052.mat`](../saved_results/paper3_cases/case3_notch_on_osi_on_gain3p5_20261120_1052.mat) | `tests/20261120/case3_notch_on_osi_on_stable_gain3p5_20261120_1052.mat` | Case 3: notch on, OSI on |
| [`case4_notch_off_osi_on_gain3p5_20261120_1248.mat`](../saved_results/paper3_cases/case4_notch_off_osi_on_gain3p5_20261120_1248.mat) | `tests/20261120/case4_notch_off_osi_on_stable_gain3p5_20261120_1248.mat` | Case 4: notch off, OSI on |
| [`stiff_notch_off_gain3p5_i0p075_20261120_1125.mat`](../saved_results/paper3_cases/stiff_notch_off_gain3p5_i0p075_20261120_1125.mat) | `tests/20261120/stiff_notch_off_stable_gain3p5_i0p075_20261120_1125.mat` | Stiff pair: intensity 0.075, notch off |
| [`stiff_notch_on_gain3p5_i0p075_20261120_1142.mat`](../saved_results/paper3_cases/stiff_notch_on_gain3p5_i0p075_20261120_1142.mat) | `tests/20261120/stiff_notch_on_stable_gain3p5_i0p075_20261120_1142.mat` | Stiff pair: intensity 0.075, notch on |
| [`fem_numerical_rotation_fixed_damping10.mat`](../saved_results/paper3_cases/fem_numerical_rotation_fixed_damping10.mat) | `main/saved_results/fem/fem_sp3_1o_rotfix.mat` | Case FEM |
| [`lead_numerical_sp4_bandstop28hz.mat`](../saved_results/paper3_cases/lead_numerical_sp4_bandstop28hz.mat) | `main/saved_results/phase_lead/pl_sp4_codesign.mat` | Reference lead on `dd`, PID gains |
| [`notch_pid_35p3hz.mat`](../saved_results/paper3_cases/notch_pid_35p3hz.mat) | `main/saved_results/controller_notch/notch_sp4.mat` | PID-error notch |
| [`../exp_tf/tf_sp4_20261116_130910.mat`](../saved_results/exp_tf/tf_sp4_20261116_130910.mat) | same | Starting point only for the actuator fit |

Test sources are relative to this folder's `saved_results/` (full recordings,
git-ignored, original names in the [story file index](three_case_experiment_checklist.md#recordings)).
The runs load the canonical `main/saved_results/` files through `main_ColumnSetup.m`.

## Case settings (identical in all runs except `hs.notch`, OSI adaptation and intensity)

| Parameter | Value |
| --- | --- |
| Numerical FEM | interface rotation fixed (K_ii 11,672 -> 53,777 N/mm), Rayleigh 10% on modes 1-2, `structural_model = 'linear'` |
| Reference lead | SP4 lead (gain 0.867, zeros 4.21/500 Hz, poles 15.2/120 Hz) x band-stop 28 Hz, zeta 0.03/1.2; `hs.num_notch = false` |
| PID | P 0.12, I 12, D 0.0012, N 512, forward Euler, dt 1/2048 s |
| PID notch | 35.3 Hz, zeta_zero 0.1, zeta_pole 0.2, Tustin; `hs.notch` false (Cases 1, 4, stiff off) / true (Cases 2, 3, stiff on) |
| Diagnostic gain | 3.5 during all shaking (Cases 1 and 4 start at 1.5 and switch at 26.9 s and 64.8 s, before the earthquake) |
| Excitation | El Centro, time scale 20; intensity 0.5 (Cases 1-4) or 0.075 (stiff pair) |
| OSI | Cases 1-2 and stiff pair: adaptation off, authority 1. Cases 3-4: adaptation on (initial gain 1, min 0.1, NCF target 0.4, rho_detect 1.35) |

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

Case 1 onset (`case1_notch_off_gain3p5_20261119_2052.mat`, 20-60 Hz `dm`
envelope): 159.57 s, gain 3.5, 38.9 Hz, preceding 2 s slope 2,577 N/mm
(alpha 0.34). Prediction and measurement agree to within about 1 Hz.

## Measured runs

Same definitions for every run (details in the
[story](three_case_experiment_checklist.md#metric-definitions-and-the-exclusion-rule)).
Active window: abs(`dd - dd(1)`) above 2% of its peak. Tracking:
RMS(`dd - dm`)/RMS(`dd`), 0.02-10 Hz zero-phase band-pass, first 30 s of the
active window excluded. Stability: maximum 1 s RMS of 30-50 Hz `dm`. Slope:
2 s secant `fm`/`dm` after a 10 Hz low-pass, windows with `dm` range > 0.15 mm.

| Run | Onset (s) | Tracking (%) | Tracking, none excluded (%) | Unfiltered (%) | 30-50 Hz `dm` (mm) | Slope median / min (N/mm) | Peak `dm` (mm) | Authority min (s) | First below 0.99 (s) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Case 1 | 132.5 | unstable | | | 1.42 | | 3.89 | 1 | |
| Case 2 | 212.4 | 3.82 | 3.79 | 6.98 | 0.0088 | 6,234 / 1,842 | 4.36 | 1 | |
| Case 3 | 135.6 | 4.64 | 4.59 | 7.33 | 0.0093 | 6,212 / 1,821 | 4.43 | 0.43 (184.4) | 142.6 |
| Case 4 | 216.7 | 7.99 | 7.89 | 9.53 | 0.0118 | 6,125 / 1,774 | 4.32 | 0.33 (542.0) | 217.3 |
| Stiff, notch off | 42.9 | 5.20 | 28.7 | 46.7 | 0.0099 | 7,402 / 6,090 | 0.67 | 1 | |
| Stiff, notch on | 66.1 | 5.14 | 11.5 | 45.6 | 0.0085 | 7,396 / 6,173 | 0.66 | 1 | |

Assumptions: constant mass and damping ratio, stiffness scaled by alpha,
healthy hydraulic parameters fixed. The numerical loop is excluded from the
Paper 1 model; with the case FEM and lead it changes the stiff limit by < 7%.
