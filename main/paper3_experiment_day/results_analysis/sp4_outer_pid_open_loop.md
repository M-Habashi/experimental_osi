# Outer PID loop: four SP4 cases

> Status 20 Nov: historical 16 Nov study (superseded healthy fit and original FEM).
> Current results: [Paper 3 story](../docs/three_case_experiment_checklist.md).

The independent switch is now implemented in the Paper 3 worktree's actual
main script and model; see [setup and verification](../docs/pid_notch_implementation.md).

The notch belongs to the outer PID controller: `C` without the notch and
`N*C` with it. The reference phase lead is unchanged and excluded from this
return ratio. The numerical/FEM feedback loop is also excluded.

The four plotted open-loop return ratios are `C*H_undamaged`,
`N*C*H_undamaged`, `C*H_damaged`, and `N*C*H_damaged`.
They describe the signal returning around the opened PID feedback loop;
they are not closed-loop desired-to-measured displacement responses.

PID `[P I D N_filter] = [0.12 12 0.0012 512]`, authority 1, adaptation off.
The unchanged saved notch has theoretical center 26.62044547 Hz and damping
parameters 0.0750194510 / 0.1500487888. Plant models are the saved healthy
`tf_sp4_20261116_130910.mat` and second-branch
`tf_SP4_dmgd_20261116_142110.mat`, discretized by ZOH at 2048 Hz;
the notch uses the existing Tustin convention.

| Case | NCF | Gain margin (dB) | Phase margin (deg) |
| --- | ---: | ---: | ---: |
| Undamaged, no notch | 0.54887 | 14.784 | 87.955 |
| Undamaged, with notch | 0.56654 | 17.007 | 87.408 |
| Damaged, no notch | 0.48290 | 11.588 | 88.315 |
| Damaged, with notch | 0.53536 | 13.330 | 87.673 |

Margins use the existing helper unchanged over the identification band
0.1–80 Hz. All four sampled PID closed loops are stable in these fits.
The notch improves the damaged NCF and gain margin; phase margin decreases
slightly, so not every margin improves together. The plot's third panel shows
the same normalized Nyquist distance used by the existing NCF calculation.

[Plot](../outputs/sp4_outer_pid_open_loop.png),
[numeric result](../outputs/sp4_outer_pid_open_loop.mat),
[reproduction script](plot_sp4_outer_pid_open_loop.m).
Dashed lines mean no notch; solid lines mean with notch. Blue is undamaged,
Copperwood is damaged. These results were calculated offline. The subsequent
implementation adds only the independent main-script switch and PID notch
block; existing helper equations remain unchanged.
