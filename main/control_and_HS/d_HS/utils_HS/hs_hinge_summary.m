function summary = hs_hinge_summary(summary, model, x, p, time)
%HS_HINGE_SUMMARY Accumulate member-end demands without storing histories.
% x: full DOFs [m, rad], columns = samples; p: plastic rotations [rad],
% or [] for an elastic demand screen. time: earthquake-record seconds.
if isempty(summary)
    nh = numel(model.My);
    summary = struct('labels', {model.labels}, 'My', model.My, ...
        'Mp', model.Mp, 'peak_moment', zeros(nh, 1), ...
        'peak_rotation', zeros(nh, 1), 'first_yield_s', nan(nh, 1), ...
        'first_plastic_s', nan(nh, 1));
end
moment = model.D*(model.B*x);
if ~isempty(p)
    moment = moment - model.D*p;
    summary.peak_rotation = max(summary.peak_rotation, max(abs(p), [], 2));
    newly_plastic = isnan(summary.first_plastic_s) & any(abs(p) > 1e-10, 2);
    for j = find(newly_plastic)'
        summary.first_plastic_s(j) = time(find(abs(p(j, :)) > 1e-10, 1));
    end
end
summary.peak_moment = max(summary.peak_moment, max(abs(moment), [], 2));
newly_yielded = isnan(summary.first_yield_s) & any(abs(moment) >= model.My, 2);
for j = find(newly_yielded)'
    summary.first_yield_s(j) = time(find(abs(moment(j, :)) >= model.My(j), 1));
end
end
