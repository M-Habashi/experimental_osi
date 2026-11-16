# Repeatability range and vHS intensity estimate

16 November 2026. Source: `SP4_sine_repetitve_proof.mat`, active loading from
72.1006 to 362.646 s. Initial paused/measurement-zeroing samples are excluded.

| Recorded quantity | Minimum | Maximum |
| --- | ---: | ---: |
| Desired displacement dd | -2.750 mm | +2.750 mm |
| Measured displacement dm | -2.90525 mm | +2.92290 mm |
| Measured force fm | -9.35533 kN | +9.84717 kN |

The measured displacement span is 5.82815 mm. Force extrema occur at 341.6714 s
(negative) and 326.6260 s (positive). Authority varies from 0.3345 to 1 during
the active sine test.

## Offline vHS sizing

The full current `main/control_and_HS/d_HS/vHS.m` was run at two intensities,
with plotting disabled and these explicit selections:

| Setting | Value |
| --- | --- |
| Earthquake | El Centro |
| Time scale factor | 20 |
| Sample rate | 2048 Hz |
| Structural model | bilinear_hinges |
| Experimental specimen | sp4.mat, initial stiffness 9.48318 MN/m |
| Actuator identification | tf_sp4_20261116_130910.mat |
| FEM | fem_sp3_1o.mat |
| Phase lead | pl_sp3_3.mat |
| PID / N | [0.12, 12, 0.0012] / 512 |
| Authority | Fixed at 1; online adaptation is not simulated |

| El Centro intensity factor | vHS minimum dm | vHS maximum dm |
| --- | ---: | ---: |
| 3.5 (script default) | -13.82384 mm | +13.37376 mm |
| 0.75 (verified sizing case) | -3.00380 mm | +2.84022 mm |

**El Centro x0.75, stretched x20, gives a comparable approximately +/-3 mm
interface response.** PGA is 0.23976 g; 0.75 is the input multiplier, not PGA in g.
The native 41.18 s record becomes approximately 823.6 s of real-time excitation.

This is displacement sizing for the stated model/controller. The experimental
substructure in vHS remains an elastic spring using the initial SP4 stiffness;
the bilinear hinges are in the numerical FEM. Consequently its virtual force
range (-28.486 to +26.934 kN) does not reproduce the measured bilinear specimen
force range. The newly designed notch and adaptation may change the response.

Outputs: [default case](../outputs/vhs_sp4_intensity_3p5.mat),
[sizing case](../outputs/vhs_sp4_intensity_0p75.mat),
[range summary](../outputs/repeatability_vhs_range_comparison.mat), and
[figure](../outputs/repeatability_vhs_range_comparison.png).
The [summary script](summarize_repeatability_range.py) reads the archived sine
record and completed sizing case. The earthquake input is archived under
`input_signals/earthquakes.mat`; vHS source references are under `references/vhs/`.
Rerunning the complete vHS requires the main project's shared helpers.
