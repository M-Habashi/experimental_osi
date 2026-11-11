function shear = hs_base_shear(M, influence, acceleration, ag)
%HS_BASE_SHEAR Total horizontal ground reaction [N], including damping.
% Lumped-floor equilibrium: Vb = -1'*M*(a_relative + influence*ag).
% Includes all frame supports (and the physical specimen in hybrid runs),
% not just fm. Inputs: M [kg], acceleration and ag [m/s^2], rows = samples.
shear = -(acceleration + ag(:)*influence(:)')*sum(M, 1)';
end
