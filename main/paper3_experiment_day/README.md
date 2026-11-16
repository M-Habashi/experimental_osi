# Paper 3 experiment day — SP4, 16 November 2026

Start with the [checklist and file descriptions](docs/three_case_experiment_checklist.md).
Current implementation: [outer-PID notch toggle and Simulink block](docs/pid_notch_implementation.md).
Controller comparison: [four outer-PID open-loop cases, with/without notch](results_analysis/sp4_outer_pid_open_loop.md).
Earlier reference-lead study: [SP4 matched pair](results_analysis/sp4_phase_lead_pair.md).
Use branch `Paper-3` in the primary checkout. The main script and actual
Simulink model include the independent PID notch; helper equations are unchanged.
This folder collects the experiment-day notes, findings, figures, calculation,
and copies of the supporting data. The original recordings and identification
files remain in the project's canonical `main/saved_results/` directories.

## Contents

| Location | Purpose |
| --- | --- |
| [Checklist and file index](docs/three_case_experiment_checklist.md) | Completed work, remaining paper cases, and the purpose of each data file. |
| [Prediction versus degraded identification](results_analysis/sp4_degraded_identification_comparison.md) | Boundary calculation, measured resonance, agreement, and assumptions. |
| [Repeatability ranges and vHS intensity](results_analysis/repeatability_range_vhs_target.md) | Measured displacement/force extrema and a verified El Centro sizing case. |
| [Pause-incident findings](results_analysis/pause_incident_20261116_1314.md) | Recorded authority reset on pause and its command transient. |
| [Paper 1 equation notes](docs/paper1_stability_equations.md) | Governing equations and their application to SP4. |
| `saved_results/` | 14 supporting input snapshots plus the two new SP4 controller files. |
| [Data inventory](data_inventory.json) | File sizes and SHA-256 checksums, verified against the canonical originals. |
| `outputs/` | Comparison figures and numerical comparison `result` struct. |
| [Calculation](results_analysis/compare_sp4_degraded_identification.m) | Reproduces the SP4 prediction/identification comparison using this folder's data. |
| `references/paper1/` | Copies of the manuscript Markdown and two equation-source scripts; reference material, not a full runnable Paper 1 package. |
| `references/runtime/` | Pause/authority source snapshots supporting the incident diagnosis. |
| `input_signals/`, `references/vhs/` | Earthquake input and vHS source references for the intensity estimate. |

## Findings to retain

- Repeatability and clean hysteresis were confirmed by the operator for the
  demonstrated sine protocol; no cumulative-damage adjustment is planned for it.
- `SP4_plasticRange_id.mat` is the degraded identification: BLWN around a
  physical setpoint approximately 2 mm from origin, probing the second bilinear
  branch. Its identification outputs use `_dmgd`.
- The measured second-branch stiffness ratio is 0.39315.
- Paper 1 predicts a critical frequency of 26.62 Hz; the degraded fitted
  resonance is 28.20 Hz, a 5.6% difference. This supports frequency localization.
- Predicted alpha-critical is 0.6389, but an experimental instability threshold
  has not been established. The stable branch identification does not validate
  the stiffness-only boundary prediction.
- The user does not require experimental validation of alpha-critical for this
  comparison. Notch design/location follows the theoretical critical frequency;
  the experimental resonance is contextual evidence.
- Paper 3 now compares outer controller `C` versus `N*C`, with the reference
  phase lead held fixed. The previous phase-lead files remain legacy options.
- The main script has `hs.notch = true/false` beside intensity.
  It controls the inline `controller/Outer PID notch` block. Both settings
  passed offline controller checks and Simulink update. The nominal OSI loop
  also includes the enabled notch through the existing configuration equations.
- Both cases load the common SP4 reference lead, without applying the
  combined file's notch twice. PID and authority settings are unchanged.
- The damaged no-notch NCF remains about 0.483; no retuning for instability
  was made. Earlier J4 6.85%/6.93% results belong to the previous reference-lead
  study, not a verified physical comparison of the current setup.
- Pause reset authority from about 0.249 to 1 during the incident. Its
  correction remains open; no existing runtime helper was changed.

## Reproduce the comparison

From this folder in MATLAB:

```matlab
addpath('results_analysis')
result = compare_sp4_degraded_identification;
```

Requires Control System Toolbox; computes offline and writes the result to
`outputs/sp4_degraded_identification_comparison.mat`.
