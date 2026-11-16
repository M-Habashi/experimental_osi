# SP4 matched comparison pair

Historical design study: Paper 3 now compares the outer PID controller with
and without its own notch. Phase-lead files are retained as legacy options.
See the [implemented independent switch](../docs/pid_notch_implementation.md).

Offline recommendation, 16 November 2026, now integrated on branch `Paper-3`.
The main script and Simulink model implement the placement below; existing
helper equations are unchanged. No physical test was run.

## Filters and placement

Files: `saved_results/phase_lead/pl_sp4_noNotch.mat` and
`saved_results/phase_lead/pl_sp4_withNotch.mat`.
Both retain PID `[P I D N] = [0.12 12 0.0012 512]`, sample rate 2048 Hz.
**Authority is 1, adaptation off. No authority adjustment is embedded.**

Let `q = s/(2*pi)`. The shared unity-DC base is

\[
B(q)=0.8674146932\frac{(q+4.209918697)(q+500)}
{(q+15.21560556)(q+120)}.
\]

The notch is centered on the **Paper 1 theoretical 26.62044547 Hz**, with
`zeta_zero = 0.0750194510`, `zeta_pole = 0.1500487888` (about 6.02 dB depth):

\[
N(q)=\frac{q^2+2(0.0750194510)(26.62044547)q+26.62044547^2}
{q^2+2(0.1500487888)(26.62044547)q+26.62044547^2}.
\]

The compared filter products are `B` and `B*N`, of degree 2 and 4.
The shared roll-off limits amplification of untrusted high-frequency fit modes.

**Placement required for the PID-loop benefit:**

| Case | HS reference path | PID forward feedback path |
| --- | --- | --- |
| No notch | `B` | Original PID |
| With notch | The same `B` | Original PID in series with `N` |

Both MAT files include `common_phase_lead_tf`, `notch_tf`, and an
`implementation_note`. `phase_lead_tf` stores the combined product for the
requested comparison and legacy reference-path use. On `Paper-3`, the main
setup reads the common base for the reference path and independently controls
the PID-path notch using `hs.notch = true/false`. Older setup scripts do not
implement this split automatically. The indicator's nominal response includes
the enabled notch using the existing configuration equations.

## Endpoint results

Margins use the existing `custom_stability_margins` formula over 0.1–80 Hz.
The PID–actuator loop is distinct from the numerical/FEM RTHS loop. The latter
uses the unreduced assembled model; full sampled closed-loop poles are checked
separately. Existing reduced vHS tables can differ; no helper was changed.

| Filter | PID NCF linear → degraded | RTHS NCF linear → degraded | Full sampled poles |
| --- | --- | --- | --- |
| Old `pl_sp3_3` | 0.549 → 0.483 | 0.260 → 0.463 | Linear stable; degraded fit unstable* |
| Old `pl_sp3_4` | 0.549 → 0.483 | 0.011 → 0.210 | Linear stable; degraded fit unstable* |
| New `pl_sp4_noNotch` | **0.549 → 0.483** | **0.281 → 0.425** | Both stable |
| New `pl_sp4_withNotch` | **0.567 → 0.535** | **0.320 → 0.456** | Both stable |

Old notches retain their original reference-path placement. Their PID-loop
margins are therefore identical. New notched results use the split placement
above. The notch approximately halves the PID-margin loss (0.066 versus
0.031); the numerical/FEM margin increases on the degraded branch, which is
acceptable for the comparison.

*The general degraded fit contains an almost undamped mode near 18.88 kHz,
outside the identification band, which affects the sampled model. Its unstable
old-filter poles are not evidence of experimental specimen instability.
The new pair remains stable at both endpoints with actuator gain multipliers
0.9, 1, and 1.1; largest checked pole modulus is 0.999921. This is a limited
gain check, not a validated uncertainty bound or nonlinear hardware proof.

Healthy initial performance uses El Centro x0.75, time scale x20, the current
FEM and initial SP4 elastic spring, through the unchanged vHS linear engine:

| New case | J4 (%) | Measured-model displacement range (mm) |
| --- | ---: | ---: |
| No notch | 6.85 | -2.99188 to +2.84133 |
| With notch | 6.93 | -2.99178 to +2.83870 |

This supports similar initial performance and a small notch trade-off.
It does not yet demonstrate nonlinear instability without the notch, or
constant required margin/performance with adaptation on.

## Sources and reproduction

Uses `specimens/sp4.mat`, `specimens/SP4_dmgd.mat`, healthy/degraded SP4
`exp_tf` fits, and `fem/fem_sp3_1o.mat` from this folder. The `_dmgd` files are
the BLWN identification about the approximately 2 mm biased second branch.

Run `finalize_sp4_phase_lead_pair(1)` after adding `results_analysis` to the
MATLAB path. It reads the selected design and prepared endpoint models in
`outputs`, calls existing helpers unchanged, and saves the two files, numerical
results, and [four-filter overlay](../outputs/sp4_phase_lead_overlay.png).
The dotted old filters are degree 3 (`_3`, with notch) and degree 1 (`_4`).
`sp4_phase_lead_selected_design.json` is the final selection. Superseded
screening drafts were removed after retaining the selected design and results.
