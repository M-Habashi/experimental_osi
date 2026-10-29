# SP2 offline plasticity replay — 28 October 2026

Both the numerical substructure and full reference yield in tests 3–5 under the saved inputs. Tests 1–2 remain elastic. The earlier 26.4 kN m estimate concerned only the physical specimen and did not screen the numerical frame.

## Results

Elastic demand divided by nominal plastic moment capacity, maximized over **all member ends**, not just the experimental column:

| Viewer test | Saved intensity multiplier | Numerical max M/Mp | Reference max M/Mp | Interpretation |
|---|---:|---:|---:|---|
| sp2_test1 | 0.18 | 0.085 | 0.085 | Elastic |
| sp2_test2 | 1 | 0.567 | 0.475 | Elastic |
| sp2_test3 | 4 | 2.072 | 1.887 | Clear hinge formation |
| sp2_test4 | 8 | 4.139 | 3.774 | Extensive yielding; severe deformation |
| sp2_test5 | 12 | 6.203 | 5.660 | Extensive yielding; severe deformation |

The critical elastic-demand member is the first-floor center-bay W8x24 beam. Its first-yield moment Fy*S is 117.83 kN m and plastic moment Fy*Z is 130.50 kN m. First yield and a fully plastic idealized hinge are distinct thresholds. Elastic ratios above one are demand screens, not the actual redistributed nonlinear moment.

The nonlinear replay uses the recorded force as prescribed input to the numerical substructure. The full reference receives the same ground acceleration but no measured interface force.

| Test | First hinge, numerical / reference (earthquake seconds) | Member-end hinges ever formed, numerical / reference | Peak plastic rotation, numerical / reference |
|---|---|---|---|
| 3 | 6.638 / 6.649 | 21 / 22 | 0.0331 / 0.0298 rad |
| 4 | 6.286 / 6.286 | 33 / 32 | Outside useful small-deformation range |
| 5 | 5.934 / 5.938 | 36 / 38 | Outside useful small-deformation range |

Counts mean individual member ends that plastified at some time, not simultaneously active hinges or a proven collapse mechanism. Counts for tests 4–5 are outputs of an extrapolated idealization, not reliable final damage predictions.

### Test 3 progression

1. Around 6.64 s: both ends of the first-floor center beam; the other first-floor beam ends follow.
2. Around 7.00 s: second-floor beam ends begin hinging.
3. Around 7.01–7.03 s: the two interior column bases yield, then exterior base locations present in each model. The numerical model excludes the physical lower-left column/base.
4. Some second-story column tops also yield (about 7.03 s numerical, 7.43 s reference); later roof-beam hinging is listed in the CSVs.

These are earthquake-record seconds. Tests 3–5 used a time scale of 20, so 6.64 record seconds corresponds to about 133 active integration seconds, excluding pauses.

Test 3 predicts approximately 4.61% / 4.14% peak story drift (numerical / reference), already substantial. Its approximate plastic rotations are useful for comparing hinge progression, not connection qualification. Tests 4–5 produce rotations above 1 rad and story drifts above 100%; those late values violate the small-deformation assumptions and must not be interpreted as credible physical deformations or proof of collapse.

## Model and assumptions

- Use the FEM, mass, damping, geometry, earthquake samples, intensity, time scaling and force sign embedded in each original result. Do not substitute a new FEM based on a specimen filename. Some saved reference metadata retain the label `sp1_5000`; the actual embedded matrices are used.
- Replay the active samples from the original 2048 Hz records; freeze the clock through pauses, as in `step_HS`. No inference from the downsampled web plots is used.
- Recover every column and beam end from the full assembled rotational DOFs. The numerical lower-left member starts at the 1.016 m force-only interface, whose rotational moment remains zero.
- Elastic member interiors plus concentrated plastic end rotations at Mp=Fy*Z. Linear kinematic hardening modulus is 0.01 times the corresponding diagonal basic member stiffness. This is a chosen approximate hardening law, not fitted specimen behavior or exactly 1% global frame stiffness.
- Steel Fy=344.738 MPa (50 ksi), from the repository SAP `STEEL_E200` definition. W8 section moduli come from that SAP export. W12x40 first-yield S uses 2I/d with nominal d=11.9 in, and Z=57 in^3. The rounded W12 first-yield threshold does not govern the initial hinges.
- Base rotational springs retain their saved **elastic** properties. No assumed base-connection yielding, axial-force interaction, gravity bending, P-Delta, local buckling, cyclic deterioration or fracture is added. Capacities are nominal material thresholds, without design resistance factors.
- Prescribed recorded fm deliberately does not change when numerical displacement changes. This is the user's exploratory assumption, not a prediction of the new closed-loop physical experiment.
- Conventional concentrated-plasticity formulation: [OpenSees documentation](https://opensees.github.io/OpenSeesDocumentation/user/manual/model/beamIntegrations/ConcentratedPlasticity.html). Section-property reference: [AISC shapes database](https://www.aisc.org/aisc/publications/steel-construction-manual/aisc-shapes-database-v160/).

## Numerical checks

- Elastic screening uses the complete original 2048 Hz force sequence.
- Nonlinear replay was run at 256 Hz and repeated at 512 Hz for tests 3–5. Hinge counts are unchanged; maximum plastic rotations change by less than 0.04%. This checks integration resolution, not physical model validity.
- The no-yield test-2 full-DOF solver agrees with the production condensed `step_HS` replay over the entire run to 3.74e-11 m at 256 Hz.
- Maximum nonlinear force/moment equilibrium residual across the 512 Hz runs is below 0.0003 in consistent N-m equation units.
- No Speedgoat, actuator, Simulink build or original recording was modified or run.

## Files and reproduction

Original recordings are in `C:\Users\BOWN1111PC1\Documents\Mohamed\ColumnSetup_gaurav\main\saved_results\tests`:

- Test 1: `20260731/sp2_RTHS_linear_10x.mat`
- Test 2: `20260801/SP2_HS.mat`
- Tests 3–5: `20260826/20260826_1601_testing_OSI.mat`, `20260826_1652_testing_OSI.mat`, `20260826_1732_testing_OSI.mat`.

From this repository's `main`:

```matlab
addpath('results_analysis')
replay_sp2_yield_screen(1:5)
replay_sp2_plastic_hinges(2:5,8) % 256 Hz
replay_sp2_plastic_hinges(3:5,4) % 512 Hz
```

Outputs are in repository-level `.codex/verification/sp2_plasticity/`: all-member CSV demand/hinge tables and MAT files containing one top-level `result` struct. `testN_screen.mat` also caches the exact active force, acceleration and FEM for reproducible nonlinear replay. Member IDs count columns and bays left to right from 1; floors/stories count upward from 1. No changes to the production real-time model are required for this analysis.

## Beam-only intensity range

Swept the **El Centro acceleration multiplier** with test 3's saved FEM, 20x time stretch, and unchanged measured force feedback. Each intensity starts from zero state; this is not a sequence of damaging runs on the same state. Both models must have at least two plastified beam ends and no column hinges anywhere during the replay.

**Recommended conservative range on the 0.1x grid: 2.2x–3.0x. Suggested starting intensity: 2.5x.** This also keeps every column below first material yield Fy*S, a stronger criterion than merely excluding fully plastic column hinges.

| Intensity | Beam hinges numerical / reference | Column hinges numerical / reference | Largest column M/My numerical / reference |
|---|---|---|---|
| 2.1x | 3 / 0 | 0 / 0 | 0.741 / 0.613 |
| 2.2x | 4 / 4 | 0 / 0 | 0.759 / 0.633 |
| 2.5x | 5 / 6 | 0 / 0 | 0.828 / 0.663 |
| 3.0x | 11 / 8 | 0 / 0 | 0.972 / 0.849 |
| 3.1x | 12 / 10 | 0 / 0 | 1.006 / 0.883 |
| 3.3x | 12 / 12 | 0 / 0 | 1.097 / 0.930 |
| 3.4x | 12 / 12 | 3 / 0 | 1.119 / 0.960 |

Strictly counting fully plastic hinges at Fy*Z gives the wider **2.2x–3.3x** range. However, the numerical columns exceed first-yield stress from 3.1x, so that wider range is not a beams-only material-plasticity range. At 3.3x the closest column is already at approximately 99.3% of Mp. The chosen lumped hinge model does not explicitly represent partial section yielding between My and Mp; the My check flags that limitation.

All grid points from 2.1x through 3.3x were simulated at 256 Hz. The boundary cases 2.2x, 3.0x, 3.1x and 3.3x were repeated at 512 Hz, retaining the classifications and counts; 3.4x was checked at 512 Hz. Grid limits are rounded inward, not outward. These ranges are conditional on the saved model, nominal 50 ksi steel, assumed hardening and fixed-force feedback, not a guarantee for a newly coupled physical run.

At 2.5x the beam hinges are on the first floor; the numerical model has five and the reference six. The controlling column for first yield is the bottom of the second-story left exterior column in the numerical substructure (C1-S2-bottom); its M/My is approximately 0.828. At 3.0x that ratio is 0.972, giving little modeling margin.

Reproduce with:

```matlab
addpath('results_analysis')
sweep_sp2_beam_hinges(2.1:0.1:3.3,8)
sweep_sp2_beam_hinges([2.2 3.0 3.1 3.3 3.4],4)
```

The sweep and original replay share `sp2_hinge_response.m`. Summary CSVs and single-struct MAT files are saved alongside the original replay outputs as `beam_only_2.1_to_3.3_256Hz` and `beam_only_2.2_to_3.4_512Hz`.

## Moment–rotation and illustrative moment–curvature plot

`sp2_hinge_curve` records the actual moment, plastic rotation and basic end rotation for B2-F1-left at 2.5x, using a 512 Hz replay. The output `hinge_curve_2p5_512Hz.mat` contains one `result` struct. The shared solver's optional `trace_ends` argument records these histories without changing the constitutive calculation.

The actual concentrated hinge law is `abs(M - H*theta_p) <= Mp`, with linear kinematic hardening. For this W8x24 beam, Mp=130.497 kN m and H=90.3473 kN m/rad. Elastic member flexibility is separate; the hinge itself has zero plastic rotation until its yield surface is reached. The hardening choice is 1% of the diagonal basic member stiffness, not 1% of material E.

The right panel of `hinge_moment_rotation_curvature.png` uses the illustrative conversion `phi_equivalent = M/(E*I) + theta_p/Lp`, with **Lp=0.10 m assumed only for visualization**. No hinge length or distributed curvature was part of the simulation. This is not a fiber-section moment–curvature analysis or a calibrated local curvature prediction. The left panel shows the actual simulated moment–plastic-rotation histories without that additional assumption.
