# Fixed experimental baseline

Selected by the user on 9 November 2026. Keep this baseline until the user explicitly changes it.

Source (read-only): `C:\Users\BOWN1111PC1\Documents\Mohamed\ColumnSetup_gaurav\main\saved_results\tests\20260826\20260826_1732_testing_OSI.mat`.
Physical SP2 experiment, 26 August 2026 at 17:32; viewer SP2 test 5.
Values below were read from the saved result, not current script defaults.

| Setting | Saved value |
|---|---|
| Earthquake | `el_centro` |
| Intensity multiplier | 12 |
| Time stretch | 20 |
| Structural model | Linear (legacy recording without structural_model) |
| FEM | `fem_5k.mat`; embedded metadata specimen label `sp1_5000` |
| Phase-lead file | `sp2_correct_pl.mat`, enabled |
| Filter zero / pole | 2.5 Hz / 0.1 Hz |
| Filter DC gain / gain | 1 / 0.04 |
| Experimental TF | `sp2_correct_20260826_164458.mat` |
| PID P / I / D | 0.12 / 12 / 0.0012 |
| PID scale / derivative filter N | 1 / 512 |
| Damping ratio | 0.03 |
| Sampling frequency / dt | 2048 Hz / 0.00048828125 s |
| Force sign | +1 |
| OSI target outer NCF | 0.4 |
| Recording time span | 0 to 1175.00048828125 s, including pauses |

This is a historical comparison baseline, not a starting amplitude for a replacement specimen.
For a new specimen of the same design, remeasure calibration/zero offsets and specimen properties,
identify the current experimental transfer function, and reassess PID/phase compensation.
Retain frame geometry/masses if unchanged; update specimen-dependent FEM calibration when needed.
Start with low-amplitude linear commissioning before increasing excitation.

For future fixed-baseline physical comparisons, follow `../../docs/MATLAB_MCP_TOOLING.md`:
match command signal/path first; keep this recording fixed. Report Channel,
RMS(current - baseline), and Normalized change (%) for dd, dc, vc, dm, fm, am.
Use NaN for a missing channel. Do not equate a different excitation or structural-model
configuration with a matched-command hardware comparison.
