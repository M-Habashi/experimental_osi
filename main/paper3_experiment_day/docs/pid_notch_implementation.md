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
35.3 Hz notch, centered on the latest observed oscillation as requested.
The main script loads `saved_results/controller_notch/notch_sp4.mat`;
edit that MAT file for future redesigns. The notch stays second order, with
zeta_zero=0.10 and zeta_pole=0.20. Diagnostic gain is excluded from design
calculations. [Parameters and editing](notch_parameters.md).
The flag and loaded design are retained in the saved `result.hs` configuration.

The reference lead is held fixed between the cases. The Paper 3 cases use
`pl_sp4_codesign.mat` (its `common_phase_lead_tf`, including a 28 Hz
band-stop) with the rotation-fixed FEM `fem_sp3_1o_rotfix.mat`; see
[case parameters](paper3_case_parameters.md). `hs.notch` controls the PID notch
independently and the notch is not applied twice. No PID gain retuning was made.

Offline verification copied the actual controller subsystem into a normal
Simulink simulation: notch off matched the original PID to 3.73e-15 mm,
and notch on matched the digital notch/PID cascade to 4.58e-14 mm.
The layout was visually inspected: one inline block, orthogonal connections,
and unchanged surrounding blocks. Those were offline checks; the current
deployment status is recorded separately in the parameter note.

[Controller layout](../outputs/controller_with_pid_notch.png).
Physical comparison done 19-20 Nov: see the [Paper 3 story](three_case_experiment_checklist.md).
Both notch settings passed actual main-setup and full Simulink update checks.
The enabled notch is included in the OSI nominal loop using the existing
`sol_osi('config',...)` equations; the fixed-size nominal and frequency-response
parameters are refreshed in the main script. Cases 3 and 4 ran with adaptation
on; the pause/resume authority reset remains open.
