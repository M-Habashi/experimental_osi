function summary = elastic_hs_hinges(fem, is_num, floors, dd_mm, time)
%ELASTIC_HS_HINGES Recover elastic member-end demands from condensed DOFs.
% floors [m], dd_mm [mm], time [earthquake-record s]. No hinges are formed.
model = sp2_member_model(fem, is_num);
a = fem.assembly;
T = zeros(size(a.K_full, 1), numel(a.retained_dofs));
T(a.retained_dofs, :) = eye(numel(a.retained_dofs));
T(a.internal_dofs, :) = -a.K_full(a.internal_dofs, a.internal_dofs) ...
    \a.K_full(a.internal_dofs, a.retained_dofs);
summary = [];
for start = 1:50000:size(floors, 1)
    idx = start:min(start+49999, size(floors, 1));
    retained = floors(idx, :)';
    if is_num, retained = [retained; dd_mm(idx)'/1000]; end
    summary = hs_hinge_summary(summary, model, T*retained, [], time(idx));
end
end
