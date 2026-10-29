function result = replay_sp2_plastic_hinges(test_ids,stride)
% Fixed-recorded-force replay with concentrated member-end plastic rotations.
% Elastic interiors, rigid-plastic hinges at Mp=Fy*Z, linear kinematic hardening.
% H=0.01*diag(D); elastic base springs; no P-Delta, axial interaction or damage.
% Reads the exact-sample elastic screening cache. No hardware operations.
if nargin<1,test_ids=3:5;end
if nargin<2,stride=8;end % 2048/8=256 Hz; keep the saved earthquake time scaling.
main=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(main,'control_and_HS','d_HS','utils_HS'));
out=fullfile(fileparts(main),'.codex','verification','sp2_plasticity');
for id=test_ids
    cache=load(fullfile(out,sprintf('test%d_screen.mat',id))); r=cache.result;
    h=r.dt*stride; ix=stride:stride:numel(r.fm);
    t=r.time(ix); fm=r.fm(ix); ag=r.ag(ix); hs=r.hs;
    result=struct('test',id,'dt',h,'stride',stride,'hardening_fraction',0.01, ...
        'time_scale_factor',hs.time_scale_factor,'source',r.source);
    for kind={'num','ref'}
        key=kind{1}; fem=hs.fem.(key); a=fem.assembly;
        mod=sp2_member_model(fem,strcmp(key,'num'));
        K=a.K_full; nd=size(K,1); nf=hs.n_floor;
        M=zeros(nd); C=M; M(1:nf,1:nf)=hs.M; C(1:nf,1:nf)=hs.C;
        F=zeros(nd,numel(t)); F(1:nf,:)=-(hs.M*ones(nf,1))*ag';
        if strcmp(key,'num'),F(a.interface_dof,:)=-fm';end
        fprintf('Test %d %s nonlinear: %d steps, dt %.8g\n',id,key,numel(t),h);
        response=sp2_hinge_response(mod,M,C,K,F,h,t/hs.time_scale_factor);
        if ~any(isfinite(response.first_yield)) && strcmp(key,'num')
            state=[]; delta=0;
            for j=1:numel(t)
                [~,state]=step_HS(fm(j)/hs.force_sign,0,h,hs,state);
                delta=max(delta,max(abs(state(1:nf)-response.floor_displacement_m(:,j))));
            end
            response.elastic_step_HS_max_difference_m=delta;
            fprintf('Elastic full-DOF versus production replay difference: %.3g m\n',delta);
            assert(delta<1e-7,'Full-DOF elastic replay differs from production.');
        end
        tab=table(mod.labels,mod.sections,response.first_yield, ...
            response.peak_plastic,response.cumulative_plastic,response.final_plastic, ...
            response.peak_moment/1000,mod.Mp/1000, ...
            'VariableNames',{'End','Section','First_hinge_eq_s','Peak_plastic_rad', ...
            'Accumulated_plastic_rad','Final_plastic_rad','Peak_kNm','Mp_kNm'});
        result.(key)=response; result.(key).hinges=tab;
        result.(key).time_eq_s=t/hs.time_scale_factor;
        writetable(tab,fullfile(out,sprintf('test%d_%s_nonlinear_%dHz.csv',id,key,round(1/h))));
        fprintf('Formed hinges: %d; max plastic rotation %.6g rad; max equilibrium residual %.3g N-equivalent\n', ...
            sum(isfinite(response.first_yield)),max(response.peak_plastic),response.max_residual);
        ranked=sortrows(tab,'First_hinge_eq_s'); disp(ranked(1:8,:));
    end
    save(fullfile(out,sprintf('test%d_nonlinear_%dHz.mat',id,round(1/h))),'result','-v7.3');
end
end

