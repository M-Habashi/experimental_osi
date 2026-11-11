function tf = is_hs_nonlinear(hs)
%IS_HS_NONLINEAR True when hs selects the plastic-hinge structural model.
% Records without hs.structural_model are linear.
tf = isfield(hs, 'structural_model') ...
    && strcmp(hs.structural_model, 'bilinear_hinges');
end
