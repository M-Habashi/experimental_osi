# Active notch parameters

The controller notch is now located experimentally at **35.3 Hz**, the
oscillation observed in `20261116_1644_testing_OSI.mat`. Diagnostic gain is
excluded from the design calculations. The independent original theoretical
critical frequency remains 26.62 Hz; the degraded identification resonance is
28.20 Hz. These are different quantities.

The single editable parameter file is:
`main/saved_results/controller_notch/notch_sp4.mat`.
It contains one `result` struct:

```matlab
result.frequency_hz = 35.3;
result.zeta_zero = 0.10;
result.zeta_pole = 0.20;
```

The main script loads this file, computes the same second-order Tustin
coefficients, and supplies `pid_notch_num` and `pid_notch_den` to
`controller/Outer PID notch`. Set `hs.notch` true to enable, false to bypass.

For a future redesign, from `main`:

```matlab
notch_file = fullfile('saved_results','controller_notch','notch_sp4.mat');
load(notch_file,'result')
result.frequency_hz = 35.3; % Edit this and/or the two damping ratios.
save(notch_file,'result')
```

Rerun the setup and rebuild/load after changing the MAT file. No block edits
are needed. Saved physical results retain the loaded values in `result.hs`.

This design has about 6.02 dB center attenuation, maximum magnitude deviation
0.049 dB through 10 Hz, and 3.50 degrees of lag at 10 Hz. It remains second
order. Physical stabilization and performance are not yet verified.

Deployment: the 35.3 Hz application was built and loaded on target IISL, and
the numerator/denominator were read back and matched to the MAT-derived
coefficients. The application is loaded but was not started. Rerun the main
setup in the operator's MATLAB session before a new build/test so the current
parameter file and recording metadata are refreshed. Deployment evidence is
under `.codex/verification/notch_35p3_deployment_20261116/deployment.mat`.
