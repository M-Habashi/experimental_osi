function result = plot_sp4_outer_pid_open_loop()
% Outer PID return ratios, excluding the reference phase lead and FEM loop.
package = fileparts(fileparts(mfilename('fullpath')));
project = fileparts(package);
addpath(fullfile(project,'control_and_HS/b_system_id/id_utils'));
design = load(fullfile(package,'saved_results/phase_lead/pl_sp4_withNotch.mat'));
pv = design.pid_values;
dt = pv.dt;
C = pid(pv.P,pv.I,pv.D,1/pv.derivative_filter_N,dt, ...
    'IFormula','ForwardEuler','DFormula','ForwardEuler');
N = c2d(design.notch_tf,dt,'tustin');
files = {'tf_sp4_20261116_130910.mat','tf_SP4_dmgd_20261116_142110.mat'};
names = {'Undamaged, no notch','Undamaged, with notch', ...
    'Damaged, no notch','Damaged, with notch'};
f = logspace(-1,log10(80),10000).';
result = struct('frequency_hz',f,'case_names',{names}, ...
    'pid_values',pv,'notch_tf',design.notch_tf,'authority',1, ...
    'loop_definition','L=C*H or L=N*C*H; reference lead and numerical/FEM feedback excluded', ...
    'loop_tf',{cell(1,4)},'response',zeros(numel(f),4), ...
    'gain_margin_db',zeros(1,4),'phase_margin_deg',zeros(1,4), ...
    'ncf_margin',zeros(1,4),'max_closed_loop_pole',zeros(1,4));
for endpoint=1:2
    data=load(fullfile(package,'saved_results/exp_tf',files{endpoint}),'H_dc_dm');
    H=c2d(data.H_dc_dm,dt,'zoh');
    for notched=0:1
        j=2*endpoint-1+notched;
        L=C*H;
        if notched, L=N*L; end
        result.loop_tf{j}=L;
        result.response(:,j)=squeeze(freqresp(L,2*pi*f));
        [result.gain_margin_db(j),result.phase_margin_deg(j),result.ncf_margin(j)] ...
            =custom_stability_margins(L,[.1 80]);
        result.max_closed_loop_pole(j)=max(abs(pole(feedback(L,1))));
    end
end
% Same normalized-distance expression as the unchanged margin helper.
result.normalized_distance=abs(1+result.response)./sqrt(2*(1+abs(result.response).^2));
fig=figure('Visible','off','Color','w','Position',[100 100 900 900]);
tiledlayout(3,1,'TileSpacing','compact','Padding','compact');
colors=[0 .486 .659;0 .486 .659;.6745 .3922 .1255;.6745 .3922 .1255];
for panel=1:3
    ax=nexttile; hold(ax,'on');
    for j=1:4
        if panel==1
            y=20*log10(abs(result.response(:,j)));
        elseif panel==2
            y=unwrap(angle(result.response(:,j)))*180/pi;
        else
            y=result.normalized_distance(:,j);
        end
        style='--'; if mod(j,2)==0,style='-';end
        semilogx(ax,f,y,style,'Color',colors(j,:),'LineWidth',1.8);
        if panel==3
            [value,index]=min(y);
            plot(ax,f(index),value,'o','Color',colors(j,:), ...
                'MarkerFaceColor',colors(j,:),'HandleVisibility','off');
        end
    end
    set(ax,'XScale','log','FontSize',12);grid(ax,'on');xlim(ax,[.1 80]);
    xline(ax,26.620445471325,'k:','26.62 Hz','HandleVisibility','off');
    if panel==1
        ylabel(ax,'Magnitude (dB)');
        yline(ax,0,':','HandleVisibility','off');
        title(ax,{'Outer PID loop: undamaged and damaged'; ...
            'L = C H or N C H; reference phase lead excluded'},'FontSize',12);
        legend(ax,names,'Location','southwest','FontSize',11);
    elseif panel==2
        ylabel(ax,'Phase (degrees)');
        yline(ax,-180,':','HandleVisibility','off');
    else
        ylabel(ax,{'Normalized Nyquist';'distance (minimum = NCF)'});
        xlabel(ax,'Frequency (Hz)');
    end
end
exportgraphics(fig,fullfile(package,'outputs/sp4_outer_pid_open_loop.png'),'Resolution',170);
savefig(fig,fullfile(package,'outputs/sp4_outer_pid_open_loop.fig'));
close(fig);
save(fullfile(package,'outputs/sp4_outer_pid_open_loop.mat'),'result');
disp(table(string(names(:)),result.ncf_margin(:),result.gain_margin_db(:), ...
    result.phase_margin_deg(:),result.max_closed_loop_pole(:), ...
    'VariableNames',{'Case','NCF','GM_dB','PM_deg','MaxClosedLoopPole'}));
end
