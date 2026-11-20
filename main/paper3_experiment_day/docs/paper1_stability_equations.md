# Paper 1 stability equations

Source located from the user's reference on 16 November 2026:
[Paper 1 package](https://github.com/M-Habashi/ColumnSetup_gaurav/tree/master/main/paper1).

The manuscript is *An Online Stability Indicator for Real-Time Hybrid Simulation
Emphasizing Physical Substructure Degradation*.

## Sources

Local source copies are under `references/paper1/` in this experiment-day
folder: [manuscript](../references/paper1/manuscript/paper1.md),
[packaged equation script](../references/paper1/simulation/scripted/theoretical.m),
and [original derivation](../references/paper1/simulation/Stability%20Analysis/theoritical_alpha.m).

- [Manuscript, Sections 3 and 3.1](https://github.com/M-Habashi/ColumnSetup_gaurav/blob/master/main/paper1/manuscript/paper1.md#3-stability-analysis-of-rths-under-structural-degradation):
  characteristic equation (23), boundary definition (24), and equations
  (26)-(31) for critical stiffness and frequency.
- [Packaged implementation: theoretical.m](https://github.com/M-Habashi/ColumnSetup_gaurav/blob/master/main/paper1/simulation/scripted/theoretical.m).
- [Original derivation: theoritical_alpha.m](https://github.com/M-Habashi/ColumnSetup_gaurav/blob/master/main/paper1/simulation/Stability%20Analysis/theoritical_alpha.m).

Inspected Git blob SHAs: manuscript Markdown
`b8c99c1e96ba92581564da94e249db2221932381`; packaged implementation
`acfe7984cc4da15f0772bdc1778a46466d7230e8`; original derivation
`0df63e19d00d1ae2bf6eb87d5513e75dffb877c4`.

## Governing equations

Here alpha is residual specimen stiffness, `alpha = k_current/k_initial`.
It is distinct from the authority factor applied by the online controller.
The paper assumes constant specimen mass, constant damping ratio, and an
equivalent linear specimen within a short time window.

Equation (20) separates the specimen from the remaining transfer-system dynamics:

\[
Y(s)=G_{a3}(s)\left[G_{a2}(s)+C_{\mathrm{in}}(s)G_{a1}(s)
\left(C_{\mathrm{out}}(s)+1\right)\right].
\]

Equation (23) is

\[
CE(s,\alpha)=ms^2+2\zeta\sqrt{m\alpha k}\,s+\alpha k+Y(s)=0.
\]

At a candidate stability boundary, set `s = j*omega` and satisfy both equations:

\[
-m\omega^2+\alpha k+\operatorname{Re}Y(j\omega)=0,
\qquad
2\zeta\omega\sqrt{m\alpha k}+\operatorname{Im}Y(j\omega)=0.
\]

The implementation solves the equivalent scalar frequency equation

\[
\frac{m\omega^2-\operatorname{Re}Y(j\omega)}{k}
-\frac{[\operatorname{Im}Y(j\omega)]^2}
{4\zeta^2\omega^2mk}=0,
\]

then evaluates

\[
\alpha_{\mathrm{cr}}=
\frac{[\operatorname{Im}Y(j\omega_{\mathrm{cr}})]^2}
{4\zeta^2\omega_{\mathrm{cr}}^2mk},
\qquad f_{\mathrm{cr}}=\frac{\omega_{\mathrm{cr}}}{2\pi}.
\]

## Application to the planned experiment

Use the fresh linear identification to establish a specimen/transfer-system
model consistent with this decomposition. A single fitted `H_dc_dm` alone does
not establish how its components change with specimen stiffness. The current
lead after numerical `dd` also needs to be included in the actual coupled-loop
equation; it cannot automatically be substituted for the paper's outer controller.

The packaged code selects the root nearest `282.2 rad/s`. For the new model,
inspect the candidate roots, retain physical residual stiffness fractions, and
check the original unsquared imaginary equation. For positive damping and
positive frequency, it requires `Im(Y) < 0` when `alpha > 0`. Confirm the
healthy system is stable and identify the first loss of stability as alpha
decreases, consistent with the paper's maximum-alpha boundary definition.

The derivation is continuous-time. Check the sampled coupled model separately
with the actual controller, lead/notch, and implementation timing, and retain
the paper's assumption that the inner loops remain stable.

The predicted frequency is a candidate band for notch design. It predicts an
instability boundary and oscillation frequency; a finite response-peak amplitude
or the time required to reach that degradation level needs additional evidence.
The notch center and width still need assessment over the expected degradation
range.

Applied 19 November with the gain-1 re-identification and the fitted actuator
plus 6.64 ms delay: at diagnostic gain 3.5, notch off alpha_cr 0.857 at
37.7 Hz; notch on, no physical root. Case 1 went unstable at 38.9 Hz. See
[case parameters](paper3_case_parameters.md).
