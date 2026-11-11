# Optional nonlinear HS test — revised after Opus review

## Implementation status (29 October 2026)

Implemented and verified offline and on Speedgoat (no actuator motion). Evidence is in `.codex/verification/hs_nonlinear/`; visualization: `docs/nonlinear_hs_models.html`.

- Solver: `prepare_hs_nonlinear.m`, `step_HS_nonlinear.m` (plus `replay_hs_nonlinear.m`, `is_hs_nonlinear.m`). Matches `step_HS` below yield (8e-10 mm over SP2 test 2) and the research replay at 2.5x (same hinges and first-hinge times, floors within 1.4e-9 m). Pause/resume and failure holds keep the state exactly.
- vHS: nonlinear reference, nonlinear spring check and controller path. Linear mode reproduces the previous vHS exactly. At SP2, El Centro 2.5x, time scale 20: 5 numerical and 6 reference hinges, all first-floor beam ends, no column hinges.
- Simulink: `Signal Generation/Hybrid Simulation` has non-tunable `hs_nl_enable`/`hs_nl` and a separate fixed-size state; `main_ColumnSetup.m` sets `hs.structural_model` (default `'linear'`).
- Speedgoat smoke test (`run_hs_nonlinear_speedgoat_smoke.m`, 125 s, OSI on, HS unpaused, El Centro 12x at time scale 1, `sat_limit` 0.01 mm): nonlinear TETMax 96.9 us (19.8% of 488.28 us), linear 73.0 us (14.9%). At 12x the active set needs at most 4 iterations, with 28 simultaneously active hinges; the 30-iteration cap is estimated at about 260 us.
- Simplifications kept: no hinge histories or `ok` flag are logged and no `hs.nl` copy is saved. Replays rebuild the configuration from the saved FEM and reproduce failure holds deterministically. A failure hold freezes the replay clock.

## Keep it simple

Compact direct MATLAB, minimal changes, ordinary MATLAB errors for ordinary invalid inputs. No validation framework, speculative edge cases, generic fault system or controller redesign. Only numerical correctness, preservation of linear behavior and real-time timing need focused checks.

## One user setting

```matlab
hs.structural_model = 'linear'; % or 'bilinear_hinges'
```

Select before building/loading the target; no switching during a run. Missing mode in old saved recordings means linear. The explicit mode is authoritative: configuration presence alone must not enable nonlinearity. Intensity and time scaling remain independent settings; the initial proposed example is El Centro 2.5x with time scale 20.

## Exact proposed files and block

| File/block | Change |
|---|---|
| `control_and_HS/d_HS/utils_HS/step_HS.m` | None: keep the existing linear solver and state unchanged. |
| New `control_and_HS/d_HS/utils_HS/prepare_hs_nonlinear.m` | Build member B, D, Mp, H, load vectors and constant Newmark/elimination matrices from the selected saved FEM. Keep Fy=344.738 MPa and hardening fraction 0.01 as clearly named constants here; save their actual values in the configuration. Retain the small section-property switch rather than creating a material database. Store dt in the configuration. |
| New `control_and_HS/d_HS/utils_HS/step_HS_nonlinear.m` | One shared sample-step implementation for numerical and reference configurations: trial step, bounded fixed-size active-set plasticity solve, pause/hold, and convergence flag. Signature `[dd,state,ok] = step_HS_nonlinear(fm,pause_enable,cfg,state)`. No separate `step_frame_hinges.m` is needed. |
| `main_ColumnSetup.m` | Select mode; prepare/save `hs.nl` for nonlinear mode; expose non-tunable mode and fixed-shape nonlinear configuration to Simulink. Existing linear setup stays intact. |
| `model_ColumnSetup_00.slx`: `Signal Generation/Hybrid Simulation` | Keep the existing linear call/state; add the nonlinear branch and its own fixed-size state. Existing fm/pause inputs and dd [mm] output retain their meanings. Add one logged `ok` output; linear mode reports true. |
| `control_and_HS/d_HS/vHS.m` | Its actuator/controller loop already steps sample by sample. Add the nonlinear structural step inside that loop; keep existing lead/actuator/controller updates. Keep the ideal spring check in nonlinear form (see "Ideal checks in nonlinear mode"). Leave linear mode as-is. |
| `helpers/utils/recompute_numerical_sub_response.m` | Dispatch using saved mode/configuration and replay the actual pause/failure-hold history. Preserve existing response fields and units. |
| `control_and_HS/d_HS/utils_HS/compare_hs_response_to_reference.m` | Carry saved mode and `hs.nl` through `buildHsModel`; select the appropriate numerical/reference solver. Nonlinear full reference is offline, receives ground motion and fm=0, and reconstructs its control displacement from full state with plastic rotations removed from elastic end slopes. Keep the unit-time-scale frequency curve through the nonlinear `hybrid_response_at_time_scale.m`. |
| `control_and_HS/d_HS/utils_HS/hybrid_response_at_time_scale.m` | In nonlinear mode, replace the condensed linear spring reference with the nonlinear spring configuration below, restarted from zero at the requested time scale. Both callers (`vHS.m` and `compare_hs_response_to_reference.m`) then keep their curve. |
| `control_and_HS/c_fem_modeling/build_fem_3.m` | No required change: saved FEM already has full assembly and geometry. |

## Ideal checks in nonlinear mode

Keep both ideal checks instead of skipping them; only their source of the ideal `fm` changes.

- **Spring configuration:** numerical full-DOF assembly plus `k_experimental` on the interface diagonal, advanced by `step_HS_nonlinear` with ground motion and external `fm=0`. Ideal force `fm = k_experimental*x_I`, the same convention as `vHS.m:181`.
- **Replay:** feed that `fm` history into the uncoupled numerical configuration with `step_HS_nonlinear`; compare floors with the spring configuration (step check) and with the full reference (J4-J6). This is the nonlinear equivalent of `vHS.m:164-191` and needs no second solver.
- **Do not replay full-reference shear as the ideal `fm`:** the numerical interface releases rotation (`assembleNumericalSubstructureStiffness.m:4-6`), while the continuous reference column carries moment at that cut, so the replay would include partition differences.
- **Agreement is within solver/active-set tolerance, not machine precision.** Match initial state (existing Newmark starts acceleration from the initial load, `step_HS` from zero), current-step force, real-time `dt`, earthquake clock and hold history.
- **Time scaling stretches excitation only;** do not rescale `M` or `C`. The unit-scale curve is a valid nonlinear frequency comparison, but at a different loading rate it can have a different yielding history.
- The spring configuration and the controller path (`hybridResponseWithPidHdcDm`) both assume an elastic physical specimen.

## Numerical details worth keeping

- State can be `[x_full; v_full; a_full; p; tau]`; keep floor DOFs first. For the numerical model, paused dd is `1000*x(interface_dof)`, so a second stored dd is unnecessary. The reference configuration needs its own control-displacement expression; it has no numerical interface DOF.
- Obtain earthquake acceleration with a codegen-supported linear interpolator and the stored clock; confirm endpoint and clock advancement match the old stepping convention. A separate saved interpolation index is optional, not a requirement.
- Initial elastic matrices and the plastic Schur matrix are constant and can be prepared once. The active-set plasticity solve is still iterative. Retain the research tolerances initially and an explicit iteration cap; evaluate actual iterations/timing rather than adding a tolerance-tuning framework.
- Use genuinely fixed-size masking. With numeric 0/1 vector `a`, a candidate matrix is `Sa = S.*(a*a') + diag(1-a)`, and rhs is `a.*(xi-sg.*Mp)`. This avoids variable-size `eye(nnz(...))` and variable-size active submatrix allocations.
- The studied numerical FEM has 20 structural DOFs and 42 candidate member-end hinges; the reference has 19 DOFs and 42 hinges. Do not use the review's approximate 30x30 timing estimate as evidence. Measure the compiled code together with OSI against the 0.488 ms budget.
- On nonconvergence, do not commit the trial state: hold previous state/command and return `ok=false`. There is no assumed automatic controlled-stop path. Existing operator pause/smooth-stop remains. Holding the numerical state alone is not proof that the evolving actuator/controller is safe; do not claim it is. Retain the logged failure hold so offline replay/reference use the same effective clock.
- Do not log every hinge at full sample rate initially. Existing fm/pause recordings plus saved model/configuration and the new convergence flag permit offline reconstruction. Preserve the solver version through existing provenance. A runtime residual calculation and runtime My warning are unnecessary for the first implementation; column first-yield assessment can stay offline.
- In the virtual-loop simplification, `fm = k_mm*actuator.C*actuator.x` assumes zero actuator direct feedthrough D. Check that assumption for the actual chosen discretization once; a nonzero D requires resolving the current-step coupling, not silently adding a sample delay.
- Reference control point: for the first-story left column, use `u_ctrl = N3*x_floor1 - N2*(theta_base-p_bottom) - N4*(theta_floor1-p_top)`, with the existing Hermite coefficients and sign convention. This avoids linear static condensation and includes any column plasticity consistently.
- A scalar dummy `hs_nl=0` in linear mode is not assumed to compile. Use a constant-pruned branch with a compatible configuration shape; verify one linear build. No nonlinear solve should execute per tick in linear mode.

## Model scope

Elastic interiors plus concentrated plastic end rotations, nominal Mp=Fy*Z, linear kinematic hardening H=0.01*diag(D), and calibrated elastic base springs. Candidate column hinges remain present, although the 2.5x replay predicts no column yielding. No hinge length, P-Delta, axial interaction, fracture or deterioration is introduced. The full reference includes the physical-column equivalent; the numerical model excludes the physical lower-left segment. Initial-reference damping remains fixed.

## Focused verification before implementation is used physically

1. Preserve the current linear response and legacy saved-result handling.
2. Compare the nonlinear sample-step with the existing research solver at 2048 Hz, including ordinary pause/reset behavior and the below-yield case.
3. Run the existing coupled virtual loop with the nonlinear structural branch. Keep phase-lead optimization linear-only; initial-stiffness stability metrics are local linear diagnostics, not nonlinear stability guarantees.
4. Compile and measure worst-case execution with OSI enabled. Prior offline 256/512 Hz results do not establish target timing.

This review/proposal does not authorize a physical run. Live feedback in an eventual experiment will differ from the prescribed-force exploratory replay.

## Assessment of Opus's suggestions

Adopt: two new helpers rather than three; reuse the existing virtual sample loop; keep the ideal and unit-scale plots in nonlinear form rather than skipping them; retain saved mode; correct reference interior slopes; save configuration and reconstruct hinge histories offline; simplify state and settings.

Qualify or reject: the claim that holding alone is inherently safe; the unmeasured claim that execution should be far below the sample budget; variable-size identity construction described as codegen-safe; assuming a scalar dummy configuration compiles; ignoring the explicit selected mode just because an nl field exists. The useful corrections are retained without adding a general fault or validation framework.
