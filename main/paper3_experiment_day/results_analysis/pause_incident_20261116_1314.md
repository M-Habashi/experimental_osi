# Sine-wave pause incident, 16 November 2026

Recording: `saved_results/tests/20261116/20261116_1314_testing_OSI.mat`.
This path is relative to the experiment-day folder. Runtime source snapshots
are in `references/runtime/`; canonical project source paths are cited below.
Analysis reads the saved HDF5 arrays and the current runtime/generated source;
no physical system operation or controller change was performed.

## Confirmed event

At 283.752441 s, `dd_pause_enable_log` changes from 0 to 1. The desired sine
command freezes at -1.081261 mm and remains exactly constant for the rest of
the recording. At the same sample, authority jumps from 0.249083574 to 1,
and `dc` jumps from -0.914442 to -3.646648 mm. The applied multiplier increases
by 4.01472 times.

Measured displacement reaches -4.948481 mm at 283.774902 s and force reaches
-11.483561 kN at 283.771973 s. The measured response subsequently moves toward
zero while the desired position remains held. Controller command continues
negative and first reaches the -70 mm saturation limit at 290.958008 s.
This later command growth is consistent with integrator windup after loss of
tracking. The available channels do not distinguish a hydraulic interruption
from physical loss of specimen resistance.

## Cause of the command discontinuity

`control_and_HS/OSI/sol_osi_runtime.m`, pause branch at lines 52-88, clears
the estimator, resets `a_state`/`out_auth` to `osiauth(8)`, disarms adaptation,
and immediately returns that initial authority. Here the initial value is 1.
The generated code contains the same reset. Authority multiplies the PID
output before the final actuator-command saturation.

The sine generator's pause behavior is a hold of its previous output; the
logged constant `dd` confirms that behavior during this event. The authority
reset prevents the complete command path from holding its operating point.

In the preceding `SP4_linear_id.mat` recording, the pause at 513.539062 s
occurred with authority already equal to 1, so the same reset produced no
authority step. The earlier pause at 43.274902 s in this recording also has
authority 1 before and after. This explains why the behavior can appear only
after adaptation has reduced authority.

The required correction is to preserve the applied authority through pause
and arrange a continuous resume; resetting estimator buffers must not restore
full controller authority. The resume/arming path also needs to retain this
behavior. No fix has been applied in this investigation.

The run used `pl_sp3_3.mat`, `sp3_tf_1o_20261109_113345.mat`, PID
`[0.12, 12, 0.0012]`, derivative filter N=512, and sampling at 2048 Hz.
Its recorded Git commit is `a65e81c53d3fbcfa73b9b7b88fc1a50ecd6bd386`, captured
at save time; this does not prove the identity of every built or unsaved file.
