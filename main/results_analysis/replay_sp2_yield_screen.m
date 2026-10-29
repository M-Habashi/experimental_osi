function result = replay_sp2_yield_screen(test_ids)
% Offline elastic first-yield screen using each saved FEM and recorded fm.
% Units: N, m, s, rad. Does not operate hardware or change original data.
if nargin == 0, test_ids = 1:5; end
main = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(main,'control_and_HS','d_HS','utils_HS'));
out = fullfile(fileparts(main),'.codex','verification','sp2_plasticity');
if ~isfolder(out), mkdir(out); end
old = 'C:\Users\BOWN1111PC1\Documents\Mohamed\ColumnSetup_gaurav\main';
files = {'20260731/sp2_RTHS_linear_10x.mat','20260801/SP2_HS.mat', ...
    '20260826/20260826_1601_testing_OSI.mat', ...
    '20260826/20260826_1652_testing_OSI.mat', ...
    '20260826/20260826_1732_testing_OSI.mat'};
result = struct();
for id = test_ids
    fprintf('Test %d: loading raw record\n',id);
    data = load(fullfile(old,'saved_results','tests',files{id}));
    if isfield(data,'result'), data = data.result; end
    hs = data.hs;
    active = data.dd_pause_enable_log(:)==0;
    active(1) = false; % Same initial sample convention as step_HS replay.
    fm = data.fm(active)*hs.force_sign;
    h = data.dt;
    time = (1:numel(fm))'*h;
    ag = interp1(hs.time,hs.ag,time/hs.time_scale_factor,'linear',0);
    entry = struct('test',id,'source',files{id},'hs',hs,'dt',h, ...
        'fm',fm,'ag',ag,'time',time);
    clear data
    for kind = {'num','ref'}
        key = kind{1};
        fem = hs.fem.(key);
        model = sp2_member_model(fem,strcmp(key,'num'));
        if strcmp(key,'num')
            force = hs.ground_force_gain*ag' + hs.force_to_floor*fm';
            K = hs.K; M = hs.M;
        else
            M = fem.M; K = fem.K;
            force = -(M*fem.influence)*ag';
        end
        u = integrate(M,hs.C,K,force,h);
        if strcmp(key,'num')
            ui = hs.interface_from_floor*u + hs.interface_from_force*fm';
            retained = [u;ui];
            % Independent check against the production stepping routine.
            state = []; check = 0;
            for j=1:min(4096,numel(fm))
                [dd,state] = step_HS(fm(j)/hs.force_sign,0,h,hs,state);
                check = max(check,abs(dd-1000*ui(j)));
            end
            entry.step_HS_max_difference_mm = check;
            assert(check<1e-5,'Replay differs from step_HS.');
        else
            retained = u;
        end
        a = fem.assembly; T = zeros(size(a.K_full,1),size(retained,1));
        T(a.retained_dofs,:) = eye(size(retained,1));
        T(a.internal_dofs,:) = -a.K_full(a.internal_dofs,a.internal_dofs) ...
            \a.K_full(a.internal_dofs,a.retained_dofs);
        R = model.D*model.B*T;
        peaks = zeros(size(R,1),1); peak_step = peaks;
        first_y = nan(size(peaks)); first_p = first_y;
        for start=1:50000:size(retained,2)
            inds=start:min(start+49999,size(retained,2));
            moments=abs(R*retained(:,inds));
            [p,idx]=max(moments,[],2); changed=p>peaks;
            peaks(changed)=p(changed); peak_step(changed)=inds(idx(changed));
            for e=1:numel(peaks)
                if isnan(first_y(e))
                    j=find(moments(e,:)>=model.My(e),1);
                    if ~isempty(j),first_y(e)=time(inds(j))/hs.time_scale_factor;end
                end
                if isnan(first_p(e))
                    j=find(moments(e,:)>=model.Mp(e),1);
                    if ~isempty(j),first_p(e)=time(inds(j))/hs.time_scale_factor;end
                end
            end
        end
        summary=table(model.labels,model.sections,peaks/1000,model.My/1000, ...
            model.Mp/1000,peaks./model.My,peaks./model.Mp,first_y,first_p, ...
            'VariableNames',{'End','Section','Peak_kNm','My_kNm','Mp_kNm', ...
            'Ratio_My','Ratio_Mp','First_My_eq_s','First_Mp_eq_s'});
        entry.(key)=summary;
        writetable(summary,fullfile(out,sprintf('test%d_%s_elastic.csv',id,key)));
        fprintf('Test %d %s: max M/My %.4f; max M/Mp %.4f; ends over My %d, Mp %d\n', ...
            id,key,max(summary.Ratio_My),max(summary.Ratio_Mp),sum(peaks>=model.My),sum(peaks>=model.Mp));
        ranked=sortrows(summary,'Ratio_My','descend');
        disp(ranked(1:min(4,height(summary)),:));
    end
    result=entry;
    save(fullfile(out,sprintf('test%d_screen.mat',id)),'result','-v7.3');
end
end

function u=integrate(M,C,K,F,h)
% Constant-step Newmark average acceleration, zero initial state.
n=size(M,1); u=zeros(n,size(F,2)); x=zeros(n,1); v=x; a=x;
A=K+4/h^2*M+2/h*C;
for i=1:size(F,2)
    next=A\(F(:,i)+M*(4/h^2*x+4/h*v+a)+C*(2/h*x+v));
    an=4/h^2*(next-x)-4/h*v-a;
    v=v+h/2*(a+an); a=an; x=next; u(:,i)=x;
end
end

