# SP3 virtual linear-range study — 9 November 2026

For the configuration below, use 0.5–1.0x for initial commissioning and 1.5x as a conservative model-based elastic ceiling. The elastic demand screen predicts first material yield at 1.957x. A fully plastic hinge starts later than first material yield; absence of a plastic hinge alone does not establish elasticity.

## Configuration

| Setting | Value |
|---|---|
| Specimen | `sp3_1o.mat`, stiffness 6.06052066 kN/mm |
| New calibrated FEM | `fem_sp3_1o.mat` |
| Experimental plant | `sp3_tf_1o_20261109_113345.mat` |
| Compensation filter | Baseline `sp2_correct_pl.mat`; zero 2.5 Hz, pole 0.1 Hz, DC gain 1 |
| Digital PID | P 0.12, I 12, D 0.0012; N 512; scale 1 |
| Earthquake | El Centro, entire 41.18-second record |
| Time stretch | 20, about 823.6 active real-time seconds |
| Integration | 2048 Hz, 1,686,734 samples per run |
| Damping | Rayleigh, 3% in modes 1 and 2 |
| Material/hinges | Nominal 50 ksi steel; concentrated hinges at Mp; kinematic hardening 0.01 times basic stiffness |
| Virtual specimen | Elastic spring, measured stiffness; identified actuator/controller dynamics |

The new FEM follows `build_fem_3.m`: calibrated exterior base springs, doubled inner base springs, W12x40 interior columns, W8x28 exterior columns and W8x24 beams. Story height is 2.024535645 m; first-mode frequency is 2.20209943 Hz.

## Full-record simulations actually run

| Intensity | Structural solver | Largest numerical / reference M/My | Plastic ends: numerical / reference | Peak virtual dm | Peak virtual fm |
|---|---|---|---|---|---|
| 1.0 | Linear | 0.511 / 0.444 | 0 / 0 | 3.53 mm | 21.39 kN |
| 1.5 | Nonlinear | 0.766 / 0.666 | 0 / 0 | 5.29 mm | 32.09 kN |
| 2.5 | Nonlinear | 1.109 / 1.108 | 4 / 2 | 8.82 mm | 53.48 kN |

The 1.5x nonlinear run remained below first material yield everywhere. At 2.5x, both ends of first-floor beams B2 and B3 plastified in the numerical frame, starting near earthquake time 7.419 s (148.38 active real-time seconds). The full reference formed two hinges at the ends of first-floor beam B2 near 7.422 s. No modeled column hinges formed.

## Elastic demand screen

These rows are exact amplitude scaling of the 1.0x **linear** vHS, not additional nonlinear simulations. At intensities above first yield the elastic extrapolation is a screen, not the redistributed nonlinear response.

| Intensity | Largest numerical M/My | Largest reference M/My |
|---|---|---|
| 0.5 | 0.255 | 0.222 |
| 1.0 | 0.511 | 0.444 |
| 1.5 | 0.766 | 0.666 |
| 1.9 | 0.971 | 0.843 |
| 2.0 | 1.022 | 0.887 |
| 2.5 | 1.277 | 1.109 |

The controlling elastic end is B2-F1-left. At 1.5x the simple physical-column base moment estimate, |fm| times specimen height, is about 0.237 of nominal section My. This does not characterize connection slip or base-connection yielding.

## Limits and current defaults

The baseline compensation filter gives poor displacement tracking with the new plant (J2 about 82%, J1 about 788 ms), despite a stable initial linear loop. Reassess compensation before relying on experimental accuracy. The amplitude recommendation is conditional on this exact configuration; changing the filter, PID, time stretch, FEM or earthquake requires a new screen.

These virtual loops have no OSI gain adaptation or command saturation. Nominal material properties and elastic base springs do not establish the physical specimen's connection limits or actual damage state. No physical target was operated for this study.

`main_ColumnSetup.m` and `vHS.m` now default to the SP3 files, `bilinear_hinges`, intensity 1.5 and time stretch 20. The historical fixed baseline in `experiment_baseline.md` is unchanged.

Both vHS and `plot_test_result` now create **HS plastic hinges**, showing numerical reconstruction and full-reference prediction. Green means below My, copper means My exceeded without a formed plastic hinge, and red means a plastic hinge formed. Linear-mode records show only an elastic demand screen. Physical specimen hinges are not measured by this figure.

Offline verification covered below-yield agreement (base-shear difference 1.78e-8 N; member-moment difference 1.01e-9 Nm), pause behavior, a yielding case, and the exact post-test `plot_test_result` path. MATLAB also checked that main and vHS defaults match and their referenced files exist.

Evidence and reproducible verification scripts: repository-level `.codex/verification/sp3_linear_range/`, including `study_summary.mat` (one top-level `result`), `virtual_runs.csv`, `elastic_screen.csv`, `intensity_screen.png`, `hinges_1p5.png` and `hinges_2p5.png`.
