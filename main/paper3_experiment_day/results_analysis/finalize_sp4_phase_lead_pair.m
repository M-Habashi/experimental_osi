function result = finalize_sp4_phase_lead_pair(candidate_id)
% Save a matched pair and evaluate it with unchanged project calculations.
package = fileparts(fileparts(mfilename('fullpath')));
project = fileparts(package);
addpath(genpath(fullfile(project,'helpers')));
addpath(genpath(fullfile(project,'control_and_HS')));
h = optimize_vHS_phase_lead_v2('helpers');
loaded = load(fullfile(package,'outputs/sp4_pair_prepared_models.mat'),'problems');
problems = loaded.problems;
candidates = jsondecode(fileread(fullfile(package,'outputs/sp4_phase_lead_selected_design.json')));
c = candidates(candidate_id);
names = {'pl_sp3_3','pl_sp3_4','pl_sp4_noNotch','pl_sp4_withNotch'};
filters = cell(1,4);
designs = cell(1,4);
authority = [1 1 c.authority c.authority];
for j = 1:2
    old = load(fullfile(package,'saved_results/phase_lead',[names{j} '.mat']));
    filters{j} = old.phase_lead_tf;
    designs{j} = normalizePhaseLeadConfig(old.phase_lead);
end
base = normalizePhaseLeadConfig(struct('gain',c.gain, ...
    'zero_hz',c.zero_hz,'pole_hz',c.pole_hz));
common_phase_lead_tf = base.gain*tf(poly(-base.zero_rad_s),poly(-base.pole_rad_s));
w = 2*pi*c.notch_hz;
feedback_notch_tf = tf([1 2*c.notch_zeta_zero*w w*w], ...
    [1 2*c.notch_zeta_pole*w w*w]);
for j = 3:4
    phase_lead = base;
    if j == 4
        phase_lead.notch_sections = [c.notch_hz c.notch_zeta_zero c.notch_zeta_pole];
        phase_lead = normalizePhaseLeadConfig(phase_lead);
    end
    designs{j} = phase_lead;
    phase_lead_tf = phase_lead.gain*tf(poly(-phase_lead.zero_rad_s),poly(-phase_lead.pole_rad_s));
    for row = 1:size(phase_lead.notch_sections,1)
        w = 2*pi*phase_lead.notch_sections(row,1);
        phase_lead_tf = phase_lead_tf*tf([1 2*phase_lead.notch_sections(row,2)*w w*w], ...
            [1 2*phase_lead.notch_sections(row,3)*w w*w]);
    end
    filters{j} = phase_lead_tf;
    pid_values = problems{1}.pid_values;
    notch_tf = tf(1);
    if j==4, notch_tf=feedback_notch_tf; end
    implementation_note = ['phase_lead_tf is the combined filter product for comparison/legacy reference use. ' ...
        'For the reported PID-loop benefit use common_phase_lead_tf in the HS reference path and ' ...
        'notch_tf after the PID error summation, in series with PID. Paper-3 main_ColumnSetup ' ...
        'implements this split with hs.notch; older setup scripts do not.'];
    design_name = names{j};
    save(fullfile(package,'saved_results/phase_lead',[design_name '.mat']), ...
        'phase_lead_tf','phase_lead','pid_values','design_name', ...
        'common_phase_lead_tf','notch_tf','implementation_note');
end
result = struct('candidate',c,'names',{names},'designs',{designs}, ...
    'authority',authority,'ncf',zeros(2,4),'inner_ncf',zeros(2,4), ...
    'max_pole',zeros(2,4),'stable',false(2,4));
result.gain_screen = zeros(2,2,3);
result.gain_screen_multipliers = [.9 1 1.1];
for endpoint = 1:2
    for j = 1:4
        p = problems{endpoint};
        forward = authority(j)*p.actuator_open_loop;
        reference_filter = c2d(filters{j},p.sample_dt,'tustin');
        if j>=3
            reference_filter = c2d(common_phase_lead_tf,p.sample_dt,'tustin');
            if j==4
                forward = forward*c2d(feedback_notch_tf,p.sample_dt,'tustin');
            end
        end
        p.PID_H_dc_dm = feedback(forward,1);
        p.actuator_ss = h.discrete_siso(p.PID_H_dc_dm,p.sample_dt);
        discrete_filter = reference_filter;
        loop = h.build_closed_loop(p,h.discrete_siso(discrete_filter,p.sample_dt));
        result.max_pole(endpoint,j) = max(abs(eig(loop.A)));
        result.stable(endpoint,j) = result.max_pole(endpoint,j)<1;
        [~,~,result.ncf(endpoint,j)] = custom_stability_margins( ...
            -p.num_tf*p.k_mm*discrete_filter*p.PID_H_dc_dm,[.1 80]);
        [~,~,result.inner_ncf(endpoint,j)] = custom_stability_margins( ...
            forward,[.1 80]);
        if j>=3
            for g=1:3
                perturbed=p;
                perturbed.PID_H_dc_dm=feedback(result.gain_screen_multipliers(g)*forward,1);
                perturbed.actuator_ss=h.discrete_siso(perturbed.PID_H_dc_dm,p.sample_dt);
                gain_loop=h.build_closed_loop(perturbed,h.discrete_siso(discrete_filter,p.sample_dt));
                result.gain_screen(endpoint,j-2,g)=max(abs(eig(gain_loop.A)));
            end
        end
    end
end
assert(all(all(result.stable(:,3:4))), 'New pair must be stable at both endpoints.');
assert(all(result.gain_screen(:)<1), 'New pair must pass the +/-10 percent gain screen.');
% Healthy initial performance: latest offline earthquake settings.
p = problems{1};
config = p.config;
config.earthquake_data = [];
config.intensity_factor = .75;
config.time_scale_factor = 20;
config.phase_lead_section_count = base.section_count;
p = h.prepare(package,config,1);
result.performance = struct([]);
for j = 3:4
    forward = c.authority*p.actuator_open_loop;
    controller = c.authority*pid(.12,12,.0012,1/512,p.sample_dt, ...
        'IFormula','ForwardEuler','DFormula','ForwardEuler');
    if j==4
        forward=forward*c2d(feedback_notch_tf,p.sample_dt,'tustin');
        controller=controller*c2d(feedback_notch_tf,p.sample_dt,'tustin');
    end
    p.PID_H_dc_dm=feedback(forward,1);
    p.actuator_ss=h.discrete_siso(p.PID_H_dc_dm,p.sample_dt);
    p.controller_ss=h.discrete_siso(controller,p.sample_dt);
    evaluated = h.evaluate(p,base);
    result.performance(j-2).name = names{j};
    result.performance(j-2).j4_percent = evaluated.metrics.j4_percent;
    result.performance(j-2).tracking_nrmse_percent = evaluated.metrics.tracking_nrmse_percent;
    result.performance(j-2).dm_range_mm = [min(evaluated.signals.dm_sample),max(evaluated.signals.dm_sample)];
end
f = logspace(-1,log10(150),3000);
fig = figure('Color','w','Visible','off','Position',[100 100 900 700]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
colors = [0 .486 .659; .6745 .3922 .1255; .6745 .3922 .1255; 0 .486 .659];
for panel = 1:2
    ax = nexttile; hold(ax,'on');
    for j = 1:4
        response = squeeze(freqresp(c2d(filters{j},1/2048,'tustin'),2*pi*f));
        if panel==1, values=20*log10(abs(response)); else, values=unwrap(angle(response))*180/pi; end
        style='-'; if j<=2, style=':'; end
        semilogx(ax,f,values,style,'Color',colors(j,:),'LineWidth',2);
    end
    set(ax,'XScale','log','FontSize',12); grid(ax,'on'); xlim(ax,[.1 150]);
    xline(ax,c.notch_hz,'--','26.62 Hz','HandleVisibility','off','Color',[.45 .45 .45]);
    if panel==1
        ylabel(ax,'Magnitude (dB)');
        legend(ax,names,'Interpreter','none','Location','northwest');
        title(ax,{'SP4: old dotted, new solid';'Filter products; new notch implemented inside PID loop'},'FontSize',12);
    else
        ylabel(ax,'Phase (degrees)'); xlabel(ax,'Frequency (Hz)');
    end
end
exportgraphics(fig,fullfile(package,'outputs/sp4_phase_lead_overlay.png'),'Resolution',170);
savefig(fig,fullfile(package,'outputs/sp4_phase_lead_overlay.fig'));
close(fig);
save(fullfile(package,'outputs/sp4_phase_lead_pair.mat'),'result');
fid=fopen(fullfile(package,'outputs/sp4_phase_lead_pair_summary.json'),'w');
fprintf(fid,'%s',jsonencode(result));
fclose(fid);
disp(result.ncf); disp(result.max_pole); disp(result.performance);
end
