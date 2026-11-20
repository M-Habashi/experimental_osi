# Paper 3 experiments — SP4, 16-20 November 2026

Start with the [Paper 3 story](docs/three_case_experiment_checklist.md): results,
metric definitions, checklist and every recording used. Parameters,
identification and predictions: [Paper 3 case parameters](docs/paper3_case_parameters.md).

Branch `Paper-3`. All cases use diagnostic gain 3.5 during shaking and the same
numerical substructure and lead; only the PID notch (`hs.notch`) and OSI
adaptation change.

| | Notch off | Notch on |
| --- | --- | --- |
| Stiff (intensity 0.075) | stable, tracking 5.20% | stable, tracking 5.14% |
| Softened (intensity 0.5), OSI off | unstable at 38.9 Hz (Case 1) | stable, tracking 3.82% (Case 2) |
| Softened (intensity 0.5), OSI on | stable, authority 0.33, tracking 7.99% (Case 4) | stable, authority 0.43, tracking 4.64% (Case 3) |

Paper 1 predicted the notch-off instability at 37.7 Hz and none with the notch.

## Reproduce

From this folder in MATLAB (Control System and Optimization Toolboxes):

```matlab
addpath('results_analysis')
result = paper3_case_parameters;   % all Paper 3 numbers, from saved_results/paper3_cases
```

`paper3_extract_case_data` rewrites the trimmed copies from the full
recordings in `saved_results/tests/` (git-ignored, local only).

## Contents

| Location | Purpose |
| --- | --- |
| [Paper 3 story](docs/three_case_experiment_checklist.md) | Results, exclusion rule, checklist, recordings and file roles |
| [Case parameters](docs/paper3_case_parameters.md) | Settings, identification method, predictions, per-run metrics |
| [`paper3_case_parameters.m`](results_analysis/paper3_case_parameters.m) | Recreates all numbers; writes [`outputs/paper3_case_parameters.mat`](outputs/paper3_case_parameters.mat) |
| [`paper3_extract_case_data.m`](results_analysis/paper3_extract_case_data.m) | Writes the trimmed, renamed inputs in `saved_results/paper3_cases/` |
| [Paper 1 equations](docs/paper1_stability_equations.md) | Characteristic equation and alpha-critical, applied to SP4 |
| [PID notch implementation](docs/pid_notch_implementation.md), [notch parameters](docs/notch_parameters.md) | Simulink block, switch and editable MAT file |
| [Pause incident](results_analysis/pause_incident_20261116_1314.md) | Authority reset on pause/resume (open correction) |
| [Repeatability ranges](results_analysis/repeatability_range_vhs_target.md) | Repetition-proof displacement and force ranges |
| [Degraded identification](results_analysis/sp4_degraded_identification_comparison.md), [outer PID open loop](results_analysis/sp4_outer_pid_open_loop.md), [lead pair](results_analysis/sp4_phase_lead_pair.md) | 16 Nov studies, superseded by the 19 Nov re-identification |
| [Data inventory](data_inventory.json) | File sizes and SHA-256 checksums |
| `references/` | Paper 1 manuscript and source copies, runtime snapshots, vHS references |
| `saved_results/` | Recordings, fits, FEM, leads and Paper 3 case inputs |
| `outputs/` | Figures and numeric results |
