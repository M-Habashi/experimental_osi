# SP4 degraded identification versus Paper 1 prediction

16 November 2026. The degraded recording is `SP4_plasticRange_id.mat`: BLWN
about a physical setpoint approximately 2 mm from origin, identifying the
second branch of the bilinear specimen response. Saved displacement signals
are offset-referenced. `_dmgd` denotes this locally degraded operating branch;
it does not imply irreversible cumulative damage.

Healthy inputs: `specimens/sp4.mat` and `exp_tf/tf_sp4_20261116_130910.mat`.
Degraded inputs: `specimens/SP4_dmgd.mat` and
`exp_tf/tf_SP4_dmgd_20261116_142110.mat`, both linked to the degraded recording.
All these paths are relative to this experiment-day folder's `saved_results/`
snapshot; canonical originals remain in the project's `main/saved_results/`.

## Results

| Quantity | Value | Meaning |
| --- | ---: | --- |
| Initial stiffness | 9.48318 MN/m | Identified first branch |
| Degraded tangent stiffness | 3.72835 MN/m | Identified second branch |
| Measured stiffness ratio | 0.39315 | Branch ratio; not an observed critical ratio |
| Continuous predicted alpha-critical | 0.63887 | Healthy-model, stiffness-only extrapolation |
| Continuous predicted critical frequency | 26.620 Hz | Physical imaginary-axis boundary root |
| Sampled predicted alpha-critical | 0.63736 | ZOH plant and actual Forward-Euler PID at 2048 Hz |
| Sampled predicted critical frequency | 26.576 Hz | Unit-circle crossing |
| Degraded fitted resonance | 28.203 Hz | Dominant local peak of identified H_dd_dm in 5-80 Hz |
| Continuous frequency difference | -5.61% | (Predicted critical frequency - fitted resonance) / fitted resonance |
| Experimental alpha-critical / critical frequency | Not established | No observed marginal-stability event in this BLWN identification |

## Interpretation

The frequency localization is encouraging: prediction identifies the 27-28 Hz
region to within about 6% of the fitted degraded resonance. The measured FRF
points are scattered; the selected points' largest local-band value is at
29.5625 Hz, so the 28.203 Hz figure is a fitted resonance, not an exact
experimental instability frequency.

Agreement of the critical stiffness threshold is not demonstrated. The model
predicts loss of stability at alpha about 0.639, yet the measured branch ratio
is about 0.393 and the recorded BLWN response remains bounded with authority 1.
The identified H_dd_dm fit is stable. At that branch stiffness, the frozen
healthy-parameter prediction instead has a pole real part +49.07 1/s.

The extrapolation assumptions need attention: identified damping ratio changes
from 0.2123 to 0.07369 and mass estimates differ by 5.4%; the independently
fitted transfer-system coefficients also change. The healthy parametric fit
places a2 at its lower bound. A good fit at one operating point therefore does
not establish accurate extrapolation with stiffness alone.

The controller configuration is comparable: spectral estimates of dc/(dd-dm)
over the two identification windows match the saved Forward-Euler PID with
median magnitude ratios 0.99999 (healthy) and 1.00000 (degraded) over 2-60 Hz,
using bins with coherence above 0.95. Authority is 1 in the degraded ID window.

This calculation concerns the PID/actuator loop excited by BLWN or sine input.
The numerical FEM and HS phase-lead path are not included. It uses the saved
actual PID [0.12, 12, 0.0012], derivative filter N=512, and healthy identified
hydraulic/inner-loop parameters. The continuous calculation holds mass and
damping ratio fixed and checks the unsquared imaginary equation when selecting
the physical boundary root; the original benchmark's preferred root is not used.

Reproduce with [compare_sp4_degraded_identification.m](compare_sp4_degraded_identification.m).
Numeric output: [result MAT](../outputs/sp4_degraded_identification_comparison.mat).
Figure: [frequency comparison](../outputs/sp4_degraded_identification_comparison.png).
