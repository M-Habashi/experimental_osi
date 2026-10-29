function result=sweep_sp2_beam_hinges(intensities,stride)
% Vary ground acceleration only; retain test-3 recorded fm and saved FEM.
% Count member ends with plastic rotation, not distinct beams.
if nargin<1,intensities=2.1:0.1:3.3;end
if nargin<2,stride=8;end
main=fileparts(fileparts(mfilename('fullpath')));
out=fullfile(fileparts(main),'.codex','verification','sp2_plasticity');
cache=load(fullfile(out,'test3_screen.mat')); r=cache.result; hs=r.hs;
h=r.dt*stride; ix=stride:stride:numel(r.fm); teq=r.time(ix)/hs.time_scale_factor;
fm=r.fm(ix); ag_unit=r.ag(ix)/hs.intensity_factor;
rows={}; details={};
for intensity=intensities
    for kind={'num','ref'}
        key=kind{1}; fem=hs.fem.(key); mod=sp2_member_model(fem,strcmp(key,'num'));
        K=fem.assembly.K_full; nd=size(K,1); nf=hs.n_floor;
        M=zeros(nd); C=M; M(1:nf,1:nf)=hs.M; C(1:nf,1:nf)=hs.C;
        F=zeros(nd,numel(ix)); F(1:nf,:)=-(hs.M*ones(nf,1))*(intensity*ag_unit');
        if strcmp(key,'num'),F(fem.assembly.interface_dof,:)=-fm';end
        s=sp2_hinge_response(mod,M,C,K,F,h,teq);
        beam=startsWith(mod.labels,'B'); column=~beam;
        formed=isfinite(s.first_yield);
        rows(end+1,:)={intensity,key,sum(formed & beam),sum(formed & column), ...
            max(s.peak_moment(column)./mod.My(column)), ...
            max(s.peak_moment(column)./mod.Mp(column)),max(s.peak_plastic(beam))}; %#ok<AGROW>
        details{end+1}=struct('intensity',intensity,'model',key, ...
            'labels',{mod.labels},'first_hinge_eq_s',s.first_yield, ...
            'peak_moment',s.peak_moment,'peak_plastic_rad',s.peak_plastic, ...
            'max_equilibrium_residual',s.max_residual); %#ok<AGROW>
        fprintf('%.1fx %s: %d beam hinges, %d column hinges; column M/My %.5f, M/Mp %.5f\n', ...
            intensity,key,rows{end,3},rows{end,4},rows{end,5},rows{end,6});
    end
end
summary=cell2table(rows,'VariableNames',{'Intensity','Model','BeamHinges', ...
    'ColumnHinges','MaxColumn_My','MaxColumn_Mp','MaxBeamPlastic_rad'});
result=struct('baseline_test',3,'force_feedback','unchanged recorded fm', ...
    'time_scale_factor',hs.time_scale_factor,'dt',h,'summary',summary,'details',{details});
tag=sprintf('beam_only_%g_to_%g_%dHz',min(intensities),max(intensities),round(1/h));
writetable(summary,fullfile(out,[tag '.csv']));
save(fullfile(out,[tag '.mat']),'result');
end
