# Steps for a new specimen

Robin-Dirichlet (R-D) coupling exists only on branch `tao_remote`. The steps
below are what to run, and what to update, once the new specimen is mounted.
Paths are relative to `main`.

## 1. Pretest (identification)
- Run `main_ColumnSetup.m` with the Hybrid Simulation off and the
  band-limited white-noise (BLWN) signal on `dd`, specimen attached.
- Command gain 1 (`hs.command_gain = 1` for this run), no static offset,
  displacement within about +-0.4 mm, at least 130 s, excitation flat up to
  80 Hz (as the SP4 pretest of 19 Nov 2026).
- Note the file name (`saved_results/tests/<date>/<file>.mat`) and the
  stationary window `[t0 t1]`.
- Repeat the pretest after any change to the specimen or its fixtures
  (re-tightened bolts changed the SP4 stiffness from 9.48 to 6.77 kN/mm).

## 2. Specimen file
- `control_and_HS/a_specimen_id/create_specimen_mat.m` on the pretest
  -> `saved_results/specimens/<specimen>.mat` (m, c, k).

## 3. Transfer-system model
- `control_and_HS/b_system_id/sys_id.m` with `data_file` = the pretest and
  `specimen_file` = the new specimen file -> `saved_results/exp_tf/<model>.mat`.
- The Robin design takes the force path of the transfer system from this
  model, so it must be fitted to the same pretest. A model of another
  identification gives a wrong force path (the design then stops with a
  negative clearance of conventional coupling).

## 4. Numerical substructure (FEM)
- `control_and_HS/c_fem_modeling/build_fem_3.m` with
  `specimen_file_override = '<full path>/saved_results/specimens/<specimen>.mat'`
  and `fem_model_name_override = 'fem_<specimen>_roller'`
  -> `saved_results/fem/fem_<specimen>_roller.mat`.
- Damping: 5% Rayleigh in modes 1-2 (default; `damping_ratio_override` to
  change). With the SP4 loop, 3% left conventional coupling a critical time
  delay of about 11 ms and 2% about 1 ms.
- Check the printout: interface moment about 0, natural frequencies, modal
  damping 5, 5, and about 9%. The frame itself (story height, frequencies)
  is recalibrated to the specimen stiffness.

## 5. Robin design and vRTHS
- `control_and_HS/d_HS/prepare_robin_test.m`: set the INPUTS block
  (`pretest_file`, `pretest_window`, `pretest_gain` = 1, `specimen_file`,
  `exp_tf_file`, `fem_file`, `phase_lead_file`, test `command_gain`,
  earthquake, intensity, time scale) and run it.
- It prints the fixed design (with the margin rule used), the adaptive
  settings, and the sweep of Robin tests (`design_robin_sweep`), with a vRTHS
  of every case at the nominal and at half the specimen stiffness, then saves
  `saved_results/robin_designs/<pretest>_robin_design.mat` (`cases` holds
  the sweep table).
- Sweep: the identified stiffness depends on the estimator and the record
  window, so the tests use Robin stiffnesses below and above it, r = K_R/k0:
  0 (conventional), the fixed design, `ratios` (default 0.3, 1, 1.4), and the
  2-50 Hz fit and specimen-file stiffnesses; each fixed case has an adaptive
  case with the same stiffness at rest (`K_cal` eta_K = r k0, limited to
  [K_min, K_max]). A fixed case is admitted if its critical time delay is at
  least that of conventional coupling, its clearance > 0, and its margin is
  at least that of conventional coupling or above the largest admitted
  tangent change. The table is in run order: conventional; the design, then
  the other ratios farthest from the design first, fixed and adaptive back to
  back; conventional again (run-to-run scatter). Drop cases from the end of
  the list if time is short; rerun the pretest between tests if the specimen
  may have yielded.
- Go only if: adaptive `gamma` < 1, the fixed clearance > 0, and no vRTHS
  case diverges. Run only sweep cases marked admitted. Run a conventional test only if its critical time delay is
  at least about 50 ms and its clearance > 0 (a warning is printed
  otherwise).
- Design rules (from the pretest only): the fixed `K_R` minimizes the linear
  numerical error over 0.5-25 Hz subject to a robust margin at least that of
  conventional coupling (if that admits no positive `K_R`: a margin above the
  largest admitted tangent change), a critical time delay at least that of
  conventional coupling, and a positive circle clearance for the admitted
  tangent range (0 to 1.3 k0). Adaptive: `eta_K` = 1, `K_cal` = fixed design
  (stiffness at rest), `K_max` = 1.25 k0, `K_min` from the scaled small-gain
  condition. No low-pass filter on the Robin term; the adaptive interval is
  not narrowed for stability.

## 6. Hardware tests (`main_ColumnSetup.m` on `tao_remote`)
Update the `hs` struct:
- `fem_file` -> the new FEM; `exp_tf_file` -> the new `sys_id` model;
  `phase_lead_file` if a new lead filter is used.
- `robin_specimen_file` -> the new specimen file.
- `robin_pretest_file` -> the pretest (under `saved_results/tests`),
  `robin_pretest_window`, `robin_pretest_gain` = 1.
- Conventional test: `robin_enable` = 0. Robin tests: `robin_enable` = 1,
  `robin_design` = `'fixed'` or `'adaptive'`, and `robin_ratio` = r of the
  sweep case ([] = the designed operator; `'fixed'` with 0 = conventional
  through the Robin block). main_ColumnSetup stops if the case is not
  admitted.
- `command_gain`, `earthquake_type`, `intensity_factor`, `time_scale_factor`,
  `structural_model` = `'linear'`.
At start-up the script recomputes the design and the sweep from the pretest,
prints "Robin case of this test" and "Robin stiffness: K_cal, initial K_R,
adaptive range"; they must match step 5.
Then follow `test_procedure.md`. Use the same earthquake and intensity for every
sweep case, run them in the order of the sweep table, and note the loading
history of the specimen.

## 7. After each test
- `plot_test_result` runs automatically. Robin tests are replayed with their
  own block (`replay_hs_robin`), which also gives `u_I^N` and `K_R`.
- The saved `result` now contains `hs_robin`, `hs_robin_enable`,
  `robin_nominal` (pretest k0, m, c), and `robin_design` (with `case`, the
  sweep case of the test).
- J4-J7 use the hybrid reference with the linear pretest specimen. For a
  nonlinear specimen, the paper reference uses a specimen law fitted after
  the test (RTHS-Nonlinear-Robin-Dirichlet repository, `analysis/`).

## 8. After any change to the R-D code
- Run `control_and_HS/d_HS/check_robin_tools.m`; it must end with
  "All checks passed" (replay of the 20 Nov adaptive test to about 1e-10 mm,
  the analysis functions, and a synthetic vRTHS).

## 9. Paper analysis (RTHS-Nonlinear-Robin-Dirichlet repository)
- `analysis/hardware_tests.py`: `FOLDER`, `TESTS`, `SPEC` (new specimen
  file), `ETA_K`/`RULE` of the new runs; rerun `export`.
- `analysis/impedance.py`: the pretest record (`ID19`) and the
  transfer-system model fitted to it (`MODEL`).
- Rerun `robin_design.py`, `loop_sim.py`, `impedance.py`, and update the
  numbers in `sections/hardware.tex`.
