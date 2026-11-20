# SP4 experiment checklist and file index

Updated 19 November 2026. Goal: compare outer PID controller `C`, controller
`N*C`, and `N*C` with OSI-driven adaptation during nonlinear specimen response.
The reference phase lead is held fixed, not used as the paper's variable.

Fixed rule: one diagnostic gain and one numerical-path lead for all cases; only
`hs.notch` changes. Without the notch: stable stiff, unstable soft. With the
notch: stable in both.

## Checklist

- [x] Locate Paper 1's characteristic equation and alpha-critical derivation.
- [x] Consolidate the checklist, file descriptions, findings, calculation,
  figures, and supporting data in `paper3_experiment_day/`.
- [x] Complete and locate SP4 linear-range specimen and system identification.
- [x] Complete and locate degraded/second-branch identification: BLWN about a
  physical setpoint approximately 2 mm from origin; corresponding outputs use
  `_dmgd`. This identifies the local second branch of the bilinear behavior.
- [x] Record repeatability: clean repeated-sine hysteresis and return to the
  same starting condition (operator-confirmed). No cumulative-damage adjustment
  is planned for the demonstrated loading protocol.
- [x] Calculate the preliminary Paper 1 boundary and compare its frequency with
  the degraded identification for context.
- [x] Retain the independent theoretical critical frequency 26.62 Hz. Per the
  latest operator instruction, locate the active notch at the observed
  oscillation, 35.3 Hz; diagnostic gain is excluded from design calculations.
- [x] Load the notch's three parameters from `saved_results/controller_notch/notch_sp4.mat`.
  Current second-order design stays within 0.049 dB of unity through 10 Hz.
- [x] Retain previous phase-lead designs as legacy options; the previous J4
  6.85%/6.93% study is historical context rather than the current paper case.
- [x] Add independent `notch = true/false` beside intensity on branch `Paper-3`'s
  main script and an inline PID-error notch in its actual Simulink model.
  Both settings passed offline controller and full Simulink update checks.
- [x] Include the enabled notch in the indicator's nominal loop through the
  existing configuration equations, without editing helpers.
- [x] Diagnose why the numerical loop masked degradation (16-19 Nov): the
  force path fm -> FEM -> dd, amplified by the reference lead, is strongest
  when the specimen is stiff, so softening raised HS stability.
- [x] Re-identify the healthy actuator plant at diagnostic gain 1
  (`20261119_2009`): the 16 Nov healthy fit underestimated |H| about 2x at
  30-45 Hz. Measured stiff outer-loop limit 3.83 at 38 Hz.
- [x] Make the numerical loop negligible: `fem_sp3_1o_rotfix.mat` (numerical
  interface rotation fixed, K_ii x4.6, 10% Rayleigh damping, linear model) with
  lead `pl_sp4_codesign.mat`. HS limit equals the outer-loop limit. Cost: ideal
  HS J4 about 14% versus 4% with `fem_sp3_1o.mat`.
- [x] Paper 1 prediction from the 20:09 healthy identification (gain 3.5):
  notch off alpha_cr 0.857 at 37.7 Hz, discrete check unstable for
  alpha <= 0.8 at 37.3-38.5 Hz; notch on, no boundary down to alpha 0.2. See
  [case parameters](paper3_case_parameters.md), recreated by
  `results_analysis/paper3_case_parameters.m`.
- [x] Case 1: no notch, adaptation off (`20261119_2052`, gain 3.5): stable
  while stiff; unstable at 159.6 s, 38.9 Hz, softened (~2.6 kN/mm).
- [x] Case 2: notch, adaptation off (`20261120_1035`, gain 3.5, only
  `hs.notch = true`): stable for the whole earthquake, including softening to
  about 1.7 kN/mm (below Case 1's 2.6 kN/mm onset). Max 30-50 Hz `dm` RMS
  0.009 mm versus 1.42 mm in Case 1.
- [x] Case 3: notch, OSI adaptation on (`20261120_1052`, gain 3.5): stable;
  authority fell to 0.43 at 184 s and returned to 1. Tracking RMS(dd-dm)/RMS(dd)
  7.39% versus 7.08% in Case 2; max 30-50 Hz `dm` RMS 0.009 mm in both.
- [x] Stiff-range performance pair (intensity 0.075, gain 3.5, OSI off):
  notch off `20261120_1125`, notch on `20261120_1142`. Both stable and stiff
  (median 4 s slope 7.42/7.45 kN/mm). Tracking 0.02-10 Hz, after the first
  30 s: 5.23% / 5.21%. The notch does not change stiff-state performance.
- [ ] Assemble response, hysteresis, inner/outer margins, and authority traces;
  retain indicator logs with adaptation off.
- [ ] Correct the pause/resume authority reset for the adaptation comparisons.

## Files and purpose

Paths below are relative to this folder's `saved_results/` snapshot. Original
files remain under the project's canonical `main/saved_results/`, except the
six Paper 3 recordings (healthy re-identification, Cases 1-3, stiff-range pair), which
were moved here and renamed.

| File | Represents / needed for |
| --- | --- |
| `tests/20261116/SP4_linear_id.mat` | Linear-range recording; source of SP4 identification. |
| `specimens/sp4.mat` | Identified mass, damping, stiffness; specimen model for prediction. |
| `exp_tf/tf_sp4_20261116_130910.mat` | Latest saved system fit; transfer-system model for design. |
| `tests/20261116/SP4_plasticRange_id.mat` | Degraded identification: BLWN about the approximately 2 mm physical setpoint, probing the second bilinear branch. |
| `specimens/SP4_dmgd.mat` | Second-branch mass, damping, and tangent stiffness; measured degraded specimen model. |
| `exp_tf/tf_SP4_dmgd_20261116_142110.mat` | Degraded transfer-system fit from the same BLWN run; compare with the healthy-model prediction. |
| `tests/20261116/SP4_sine_repetitve_proof.mat` | New repeated-sine test; repeatability and clean-hysteresis evidence. |
| `tests/20261116/20261116_1326_testing_OSI.mat` | Intermediate sine run; retained run history, paper role not yet assigned. |
| `tests/20261116/20261116_1314_testing_OSI.mat` | Pause incident; separates the authority-reset transient from degradation. |
| `phase_lead/pl_sp3_3.mat`, `pl_sp3_4.mat` | Retained legacy reference-phase-lead options; no longer the paper's comparison variable. |
| `phase_lead/pl_sp4_noNotch.mat`, `pl_sp4_withNotch.mat` | Retained earlier design study; not required by the independent controller-notch switch. |
| `fem/fem_sp3_1o.mat` | Original numerical/reference FEM; masked degradation through the force path. |
| `paper3_cases/fem_numerical_rotation_fixed_damping10.mat` | Case FEM (canonical `fem/fem_sp3_1o_rotfix.mat`): interface rotation fixed, 10% damping. |
| `paper3_cases/lead_numerical_sp4_bandstop28hz.mat` | Case lead (canonical `phase_lead/pl_sp4_codesign.mat`): SP4 lead x 28 Hz band-stop. |
| `paper3_cases/notch_pid_35p3hz.mat` | Case PID notch (canonical `controller_notch/notch_sp4.mat`). |
| `paper3_cases/id_healthy_gain1_20261119_2009_t085_218s.mat` | Healthy identification, 85-218 s of full record `tests/20261119/id_healthy_gain1_20261119_2009.mat`, was `20261119_2009_testing_OSI.mat`. |
| `paper3_cases/case1_notch_off_gain3p5_20261119_2052.mat` | Case 1 run (full record `tests/20261119/case1_notch_off_unstable_gain3p5_20261119_2052.mat`, was `20261119_2052_testing_OSI.mat`). |
| `tests/20261119/id_healthy_gain1_20261119_2009.mat` | Full healthy re-identification record (moved, was `20261119_2009_testing_OSI.mat`). |
| `tests/20261119/case1_notch_off_unstable_gain3p5_20261119_2052.mat` | Full Case 1 record (moved, was `20261119_2052_testing_OSI.mat`). |
| `tests/20261120/case2_notch_on_stable_gain3p5_20261120_1035.mat` | Full Case 2 record (moved, was `20261120_1035_testing_OSI.mat`). |
| `tests/20261120/case3_notch_on_osi_on_stable_gain3p5_20261120_1052.mat` | Full Case 3 record (moved, was `20261120_1052_testing_OSI.mat`). |
| `paper3_cases/case3_notch_on_osi_on_gain3p5_20261120_1052.mat` | Case 3 run, trimmed copy of the full record above. |
| `tests/20261120/stiff_notch_off_stable_gain3p5_i0p075_20261120_1125.mat` | Full stiff-range notch-off record (moved, was `20261120_1125_testing_OSI.mat`); trimmed copy `paper3_cases/stiff_notch_off_gain3p5_i0p075_20261120_1125.mat`. |
| `tests/20261120/stiff_notch_on_stable_gain3p5_i0p075_20261120_1142.mat` | Full stiff-range notch-on record (moved, was `20261120_1142_testing_OSI.mat`); trimmed copy `paper3_cases/stiff_notch_on_gain3p5_i0p075_20261120_1142.mat`. |
| `paper3_cases/case2_notch_on_gain3p5_20261120_1035.mat` | Case 2 run (full record `tests/20261120/case2_notch_on_stable_gain3p5_20261120_1035.mat`, was `20261120_1035_testing_OSI.mat`). |
| canonical `tests/20261120/20261120_1029_testing_OSI.mat` | Shorter notch-on run before Case 2; stable (not copied). |
| canonical `tests/20261119/20261119_1851_testing_OSI.mat`, `_1904_` | Earlier lead trials with `fem_sp3_1o.mat`; stiff instability at gain 4.0 (not copied). |
| `exp_tf/sp3_tf_1o_20261109_113345.mat` | SP3 transfer-system prior recorded in the current physical tests; preserves their actual configuration. |
| `specimens/sp3_1o.mat` | Specimen definition used by the earlier SP3 vHS comparison. |

## Retained context

The degraded specimen estimate uses 105.157-174.033 s; its system fit uses
90.792-179.558 s of `SP4_plasticRange_id.mat`. The physical approximately 2 mm
bias is operator-specified; saved displacement channels are offset-referenced.
The measured tangent-stiffness ratio is `k_dmgd/k_initial = 0.39315`. This is
the identified degraded branch, not yet a measured critical stiffness ratio.
The preliminary prediction gives alpha-critical 0.6389 at 26.62 Hz; the degraded
fitted resonance is 28.20 Hz (about 6% frequency difference). The BLWN response
is bounded, so an experimental instability threshold has not been established.
See [the comparison](../results_analysis/sp4_degraded_identification_comparison.md).

The repeatability file contains approximately 363 s of recording and stepped
sine commands reaching +/-2.75 mm. During active loading, measured displacement
is -2.90525 to +2.92290 mm; measured force extrema are -9.35533 and +9.84717 kN.
These ranges exclude the initial paused/measurement-zeroing interval.
The verified vHS sizing case is El Centro x0.75, time scale x20: simulated dm
-3.00380 to +2.84022 mm. It uses the initial SP4 spring and current `_3` lead.
See [range and intensity settings](../results_analysis/repeatability_range_vhs_target.md).
Its original embedded filename is
`20261116_1337_testing_OSI.mat`. It records `pl_sp3_3.mat` and the SP3 prior
`sp3_tf_1o_20261109_113345.mat`; the SP4 fits above are separately available.

The earlier SP3 vHS calculation found `_3` stable and `_4` initially unstable.
The SP4 pair is now evaluated offline: both identified endpoints and +/-10%
actuator-gain cases are stable. PID NCF is 0.549 to 0.483 without the notch,
and 0.567 to 0.535 with the notch inside the PID forward loop. Authority is 1.
See [pair and implementation notes](../results_analysis/sp4_phase_lead_pair.md).
The pause/resume authority reset remains an open correction.

Details: [Paper 1 equations](paper1_stability_equations.md);
[pause diagnosis](../results_analysis/pause_incident_20261116_1314.md).

Next: assemble the three-case traces. The 16 Nov alpha-critical 0.6389 at 26.62 Hz used the superseded
healthy fit; the 19 Nov prediction above replaces it.
