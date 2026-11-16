# Paper 3: outer-controller notch switch

Use `main/main_ColumnSetup.m` and `main/model_ColumnSetup_00.slx` in the primary
checkout on branch **`Paper-3`**. This branch contains the authorized setup
and Simulink integration; helper equations are unchanged.

Beside earthquake intensity in the main script:

```matlab
'notch', true, ... % true: notch on PID error; false: bypass.
```

Set `false` for the no-notch test, `true` for the notched test, then rerun the
setup and rebuild/load the target as usual. This is a setup-time choice.

The actual model contains `controller/Outer PID notch`, wired inline:
error dead zone -> notch -> PID. Off uses unity coefficients; on uses the
previously evaluated 26.62044547 Hz notch, unchanged. The flag and notch
design are retained in the saved `result.hs` configuration.

The reference lead is held fixed between the cases. The default is the common
SP4 base from `pl_sp4_withNotch.mat`; selecting either new SP4 file uses its
`common_phase_lead_tf`, not the combined product. Thus `hs.notch` controls the
PID notch independently and the notch is not applied twice. The default plant
identification is the healthy SP4 fit. No PID gain or authority retuning was made. The approximately
0.483 damaged no-notch margin remains the starting design for physical tests.

Offline verification copied the actual controller subsystem into a normal
Simulink simulation: notch off matched the original PID to 3.73e-15 mm,
and notch on matched the digital notch/PID cascade to 4.58e-14 mm.
The layout was visually inspected: one inline block, orthogonal connections,
and unchanged surrounding blocks. No physical run or target build was done.

[Controller layout](../outputs/controller_with_pid_notch.png).
The earlier J4 values belong to the prior matched-reference-lead study;
performance of this actual setup still needs the planned physical comparison.
Both notch settings passed actual main-setup and full Simulink update checks.
The enabled notch is included in the OSI nominal loop using the existing
`sol_osi('config',...)` equations; the fixed-size nominal and frequency-response
parameters are refreshed in the main script. Adaptive-case experiments and the
pause/resume issue remain pending. The operator's intensity 1 is retained;
the earlier J4 comparison used intensity 0.75.
