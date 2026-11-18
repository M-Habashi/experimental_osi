# SP4 experiment checklist and file index

Updated 16 November 2026. Goal: compare outer PID controller `C`, controller
`N*C`, and `N*C` with OSI-driven adaptation during nonlinear specimen response.
The reference phase lead is held fixed, not used as the paper's variable.

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
- [ ] Compare initial performance with this actual setup, keeping the same
  reference phase lead in both tests.
- [ ] Case 1: no notch, adaptation off; assess PID–actuator margin loss and
  possible instability. Numerical/FEM margin may increase with degradation.
- [ ] Case 2: notch, adaptation off; assess stability, margin loss, and performance.
- [ ] Case 3: notch, adaptation on; assess the required margin and performance.
- [ ] Assemble response, hysteresis, inner/outer margins, and authority traces;
  retain indicator logs with adaptation off.
- [ ] Correct the pause/resume authority reset for the adaptation comparisons.

## Files and purpose

Paths below are relative to this folder's `saved_results/` snapshot. Original
files remain under the project's canonical `main/saved_results/`.

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
| `fem/fem_sp3_1o.mat` | Existing numerical/reference FEM; establish its use for the SP4 comparison. |
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

Next: establish the controller comparison using SP4 identification. Experimental
validation of alpha-critical and a separate progression-documentation task are
not required for the current plan. The notch location follows the theoretical
critical frequency.
