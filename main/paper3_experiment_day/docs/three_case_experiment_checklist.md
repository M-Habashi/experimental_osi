# Paper 3 story: SP4 cases, checklist and files

Updated 20 November 2026. Paper 3 compares the outer PID controller `C`, the
notched controller `N*C`, and both with OSI-driven adaptation while the SP4
specimen softens. Numbers below are recreated by
[`paper3_case_parameters.m`](../results_analysis/paper3_case_parameters.m); the
method and parameters are in [Paper 3 case parameters](paper3_case_parameters.md).

Fixed rule: one diagnostic gain (3.5 during all shaking) and one numerical
substructure and lead for every case. Only the PID notch (`hs.notch`, line 64
of `main_ColumnSetup.m`) and OSI adaptation change.

## Results

### Notch, OSI adaptation off

| Specimen state | Notch off | Notch on |
| --- | --- | --- |
| Stiff (intensity 0.075) | stable, tracking 5.20% (stiff pair) | stable, tracking 5.14% (stiff pair) |
| Softened (intensity 0.5) | **unstable** at 38.9 Hz, 159.6 s, 2.58 kN/mm (Case 1) | stable to 1.84 kN/mm, tracking 3.82% (Case 2) |

The notch removes the softening instability and does not change stiff-state
tracking. Paper 1 predicted the notch-off instability at 37.7 Hz (alpha_cr
0.857) and no boundary with the notch; the measured 38.9 Hz agrees within
about 1 Hz.

### OSI adaptation on (intensity 0.5)

| | Notch off (Case 4) | Notch on (Case 3) | Reference: Case 2 (notch, OSI off) |
| --- | --- | --- | --- |
| Result | stable | stable | stable |
| Authority minimum | 0.33 at 542 s | 0.43 at 184 s | 1 |
| Lowest 2 s slope | 1.77 kN/mm | 1.82 kN/mm | 1.84 kN/mm |
| Tracking | 7.99% | 4.64% | 3.82% |
| Max 30-50 Hz `dm` | 0.012 mm | 0.009 mm | 0.009 mm |

Without the notch, OSI alone also prevents the Case 1 instability, but only by
cutting authority further, with about 1.7 times the tracking error of Case 3. With the notch,
OSI adapts less and tracking stays close to the non-adaptive notch case.

### Stiff-range pair: performance with and without the notch

| Measure | Notch off | Notch on |
| --- | --- | --- |
| Max 1 s RMS of 30-50 Hz `dm` | 0.0099 mm | 0.0085 mm |
| 2 s secant slope, median (min) | 7.40 (6.09) kN/mm | 7.40 (6.17) kN/mm |
| Peak abs(`dm`) | 0.67 mm | 0.66 mm |
| Tracking, first 30 s excluded | **5.20%** | **5.14%** |
| Tracking, nothing excluded | 28.7% | 11.5% |
| Unfiltered RMS(dd-dm)/RMS(dd) | 46.7% | 45.6% |

Both runs stayed on the stiff branch (identified 7.58 kN/mm).

### Metric definitions and the exclusion rule

- Active window: from the first to the last sample where abs(`dd - dd(1)`)
  exceeds 2% of its peak. Identical rule for all runs.
- Tracking: RMS(`dd - dm`)/RMS(`dd`) after a 0.02-10 Hz zero-phase band-pass,
  which holds the earthquake content at time scale 20.
- Exclusion rule: the first 30 s of the active window are excluded from
  tracking. Both small runs start with a transient unrelated to the notch
  (peak abs(`dc - dd`) about 0.4 mm while abs(`dd`) is about 0.02 mm), which
  dominates their RMS (28.7% and 11.5% without exclusion). At intensity 0.5 the
  exclusion changes tracking by at most 0.11 percentage point.
- Unfiltered error at intensity 0.075 (about 46%) is measurement noise above
  10 Hz, equal in both runs.
- Stability: maximum 1 s RMS of 30-50 Hz `dm`; about 0.01 mm is noise level,
  Case 1 reached 1.42 mm.

## How the setup was reached

1. 16 Nov: SP4 healthy and second-branch identification, repetition proof,
   PID notch at the observed 35.3 Hz oscillation.
2. 16-19 Nov: with the original numerical FEM the HS loop went unstable while
   stiff (gains 2-4). Cause: the force path `fm -> FEM -> dd`, amplified by the
   lead, is strongest when the specimen is stiff, so softening raised stability.
3. 19 Nov: numerical interface rotation fixed (K_ii x4.6), 10% Rayleigh
   damping, linear model, lead with a 28 Hz band-stop. The HS limit now equals
   the outer-loop limit (3.85 off / 5.23 on). Cost: ideal-HS J4 about 14%.
4. 19 Nov: healthy re-identification at gain 1 (the 16 Nov fit underestimated
   abs(H) about 2x at 30-45 Hz), Paper 1 prediction, then Cases 1-4 and the
   stiff pair.

## Checklist

- [x] Paper 1 characteristic equation and alpha-critical derivation located
  ([equations](paper1_stability_equations.md)).
- [x] SP4 healthy and second-branch identification (16 Nov).
- [x] Repeatability: clean repeated-sine hysteresis (operator-confirmed).
- [x] PID notch switch in the main script and Simulink model
  ([implementation](pid_notch_implementation.md), [parameters](notch_parameters.md)).
- [x] Diagnose and remove the numerical-loop masking (rotation-fixed FEM, lead
  with 28 Hz band-stop).
- [x] Healthy re-identification at gain 1 and Paper 1 prediction.
- [x] Case 1: notch off, OSI off: unstable after softening.
- [x] Case 2: notch on, OSI off: stable.
- [x] Case 3: notch on, OSI on: stable, authority minimum 0.43.
- [x] Case 4: notch off, OSI on: stable, authority minimum 0.33.
- [x] Stiff-range pair: notch has no stiff-state performance cost.
- [ ] Assemble response, hysteresis, margin and authority figures for the paper.
- [ ] Correct the pause/resume authority reset
  ([diagnosis](../results_analysis/pause_incident_20261116_1314.md)).

## Recordings

Full recordings are under this folder's `saved_results/tests/` (git-ignored,
local only; checksums in [data_inventory.json](../data_inventory.json)).
Trimmed copies used by the scripts are committed in `saved_results/paper3_cases/`.

| Role | Full recording (original name) | Trimmed copy |
| --- | --- | --- |
| Healthy re-identification, gain 1 | [`20261119/id_healthy_gain1_20261119_2009.mat`](../saved_results/tests/20261119/id_healthy_gain1_20261119_2009.mat) (`20261119_2009_testing_OSI.mat`) | [`id_healthy_gain1_20261119_2009_t085_218s.mat`](../saved_results/paper3_cases/id_healthy_gain1_20261119_2009_t085_218s.mat) (85-218 s) |
| Case 1: notch off, OSI off, unstable | [`20261119/case1_notch_off_unstable_gain3p5_20261119_2052.mat`](../saved_results/tests/20261119/case1_notch_off_unstable_gain3p5_20261119_2052.mat) (`20261119_2052_testing_OSI.mat`) | [`case1_notch_off_gain3p5_20261119_2052.mat`](../saved_results/paper3_cases/case1_notch_off_gain3p5_20261119_2052.mat) |
| Case 2: notch on, OSI off, stable | [`20261120/case2_notch_on_stable_gain3p5_20261120_1035.mat`](../saved_results/tests/20261120/case2_notch_on_stable_gain3p5_20261120_1035.mat) (`20261120_1035_testing_OSI.mat`) | [`case2_notch_on_gain3p5_20261120_1035.mat`](../saved_results/paper3_cases/case2_notch_on_gain3p5_20261120_1035.mat) |
| Case 3: notch on, OSI on, stable | [`20261120/case3_notch_on_osi_on_stable_gain3p5_20261120_1052.mat`](../saved_results/tests/20261120/case3_notch_on_osi_on_stable_gain3p5_20261120_1052.mat) (`20261120_1052_testing_OSI.mat`) | [`case3_notch_on_osi_on_gain3p5_20261120_1052.mat`](../saved_results/paper3_cases/case3_notch_on_osi_on_gain3p5_20261120_1052.mat) |
| Case 4: notch off, OSI on, stable | [`20261120/case4_notch_off_osi_on_stable_gain3p5_20261120_1248.mat`](../saved_results/tests/20261120/case4_notch_off_osi_on_stable_gain3p5_20261120_1248.mat) (`20261120_1248_testing_OSI.mat`) | [`case4_notch_off_osi_on_gain3p5_20261120_1248.mat`](../saved_results/paper3_cases/case4_notch_off_osi_on_gain3p5_20261120_1248.mat) |
| Stiff pair, notch off | [`20261120/stiff_notch_off_stable_gain3p5_i0p075_20261120_1125.mat`](../saved_results/tests/20261120/stiff_notch_off_stable_gain3p5_i0p075_20261120_1125.mat) (`20261120_1125_testing_OSI.mat`) | [`stiff_notch_off_gain3p5_i0p075_20261120_1125.mat`](../saved_results/paper3_cases/stiff_notch_off_gain3p5_i0p075_20261120_1125.mat) |
| Stiff pair, notch on | [`20261120/stiff_notch_on_stable_gain3p5_i0p075_20261120_1142.mat`](../saved_results/tests/20261120/stiff_notch_on_stable_gain3p5_i0p075_20261120_1142.mat) (`20261120_1142_testing_OSI.mat`) | [`stiff_notch_on_gain3p5_i0p075_20261120_1142.mat`](../saved_results/paper3_cases/stiff_notch_on_gain3p5_i0p075_20261120_1142.mat) |

Gain schedules: Cases 1 and 4 start at 1.5 and switch to 3.5 at 26.9 s and
64.8 s, before the earthquake starts (132 s and 217 s); all other runs use 3.5
throughout.

## Case configuration files

| File in `saved_results/paper3_cases/` | Canonical file loaded by the main script | Content |
| --- | --- | --- |
| [`fem_numerical_rotation_fixed_damping10.mat`](../saved_results/paper3_cases/fem_numerical_rotation_fixed_damping10.mat) | `main/saved_results/fem/fem_sp3_1o_rotfix.mat` | Numerical FEM, interface rotation fixed, 10% damping |
| [`lead_numerical_sp4_bandstop28hz.mat`](../saved_results/paper3_cases/lead_numerical_sp4_bandstop28hz.mat) | `main/saved_results/phase_lead/pl_sp4_codesign.mat` | SP4 lead x 28 Hz band-stop, PID gains |
| [`notch_pid_35p3hz.mat`](../saved_results/paper3_cases/notch_pid_35p3hz.mat) | `main/saved_results/controller_notch/notch_sp4.mat` | PID-error notch, 35.3 Hz |

## 16 November supporting data

| File in `saved_results/` | Role |
| --- | --- |
| [`tests/20261116/SP4_linear_id.mat`](../saved_results/tests/20261116/SP4_linear_id.mat) | Healthy identification recording |
| [`specimens/sp4.mat`](../saved_results/specimens/sp4.mat), [`exp_tf/tf_sp4_20261116_130910.mat`](../saved_results/exp_tf/tf_sp4_20261116_130910.mat) | Healthy specimen and system fits (fit start point for the 19 Nov re-identification) |
| [`tests/20261116/SP4_plasticRange_id.mat`](../saved_results/tests/20261116/SP4_plasticRange_id.mat) | Second-branch identification: BLWN about a 2 mm setpoint |
| [`specimens/SP4_dmgd.mat`](../saved_results/specimens/SP4_dmgd.mat), [`exp_tf/tf_SP4_dmgd_20261116_142110.mat`](../saved_results/exp_tf/tf_SP4_dmgd_20261116_142110.mat) | Second-branch fits; stiffness ratio 0.39315 |
| [`tests/20261116/SP4_sine_repetitve_proof.mat`](../saved_results/tests/20261116/SP4_sine_repetitve_proof.mat) | Repetition proof ([ranges](../results_analysis/repeatability_range_vhs_target.md)) |
| [`tests/20261116/20261116_1314_testing_OSI.mat`](../saved_results/tests/20261116/20261116_1314_testing_OSI.mat) | Pause incident ([diagnosis](../results_analysis/pause_incident_20261116_1314.md)) |
| [`tests/20261116/20261116_1326_testing_OSI.mat`](../saved_results/tests/20261116/20261116_1326_testing_OSI.mat) | Intermediate sine run; no paper role |
| [`fem/fem_sp3_1o.mat`](../saved_results/fem/fem_sp3_1o.mat) | Original numerical FEM; masked degradation through the force path |
| `phase_lead/pl_sp3_3.mat`, `pl_sp3_4.mat`, `pl_sp4_noNotch.mat`, `pl_sp4_withNotch.mat` | Earlier leads ([study](../results_analysis/sp4_phase_lead_pair.md)) |
| `exp_tf/sp3_tf_1o_20261109_113345.mat`, `specimens/sp3_1o.mat` | SP3 prior and specimen used by earlier runs |

## Development runs (canonical `main/saved_results/tests/`, not copied)

| Runs | Setup | Outcome |
| --- | --- | --- |
| `20261116_1628` to `_1839` | Original FEM, bilinear hinges, earlier leads | Oscillation at gains 1.8-4 in several runs; motivated the diagnosis |
| `20261119_1851`, `_1904`, `_2022` | Original FEM with new leads | Instability at gain 3.5-4.0; motivated the rotation-fixed FEM |
| `20261120_1029` | Case 2 settings, shorter | Stable; superseded by Case 2 |

## Superseded results

The 16 Nov Paper 1 boundary (alpha_cr 0.6389 at 26.62 Hz) used the healthy fit
that underestimated abs(H); the 19 Nov prediction (0.857 at 37.7 Hz) replaces
it. The 16 Nov comparison is kept for context:
[degraded identification](../results_analysis/sp4_degraded_identification_comparison.md),
[outer PID open loop](../results_analysis/sp4_outer_pid_open_loop.md),
[lead pair](../results_analysis/sp4_phase_lead_pair.md).
