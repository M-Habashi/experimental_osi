function result=sp2_hinge_curve()
% Actual moment/rotation histories of the first-floor center beam left end.
% Curvature is NOT a state variable of this concentrated-plasticity model.
main=fileparts(fileparts(mfilename('fullpath')));
out=fullfile(fileparts(main),'.codex','verification','sp2_plasticity');
cache=load(fullfile(out,'test3_screen.mat')); r=cache.result; hs=r.hs;
stride=4; h=r.dt*stride; ix=stride:stride:numel(r.fm);
teq=r.time(ix)/hs.time_scale_factor;
ag=2.5*r.ag(ix)/hs.intensity_factor; fm=r.fm(ix);
result=struct('intensity',2.5,'member_end','B2-F1-left','time_eq_s',teq, ...
    'hinge_length','not assigned in the replay');
for kind={'num','ref'}
    key=kind{1}; fem=hs.fem.(key); mod=sp2_member_model(fem,strcmp(key,'num'));
    K=fem.assembly.K_full; nd=size(K,1); nf=hs.n_floor;
    M=zeros(nd); C=M; M(1:nf,1:nf)=hs.M; C(1:nf,1:nf)=hs.C;
    F=zeros(nd,numel(ix)); F(1:nf,:)=-(hs.M*ones(nf,1))*ag';
    if strcmp(key,'num'),F(fem.assembly.interface_dof,:)=-fm';end
    e=find(strcmp(mod.labels,result.member_end));
    s=sp2_hinge_response(mod,M,C,K,F,h,teq,e);
    result.(key)=s.trace;
    result.(key).EI_Nm2=fem.frame.E*fem.frame.section.W8x24.Ix;
    result.(key).Mp_Nm=mod.Mp(e);
    result.(key).H_Nm_per_rad=0.01*mod.D(e,e);
    fprintf('%s: Mp %.6g kNm, H %.6g kNm/rad; peak plastic %.6g rad\n', ...
        key,mod.Mp(e)/1000,0.01*mod.D(e,e)/1000,max(abs(s.trace.plastic_rotation_rad)));
end
save(fullfile(out,'hinge_curve_2p5_512Hz.mat'),'result','-v7.3');
% Display-only decimation: full histories remain in the MAT file.
display=result; display.time_eq_s=teq(1:20:end);
for kind={'num','ref'}
    k=kind{1}; fields={'moment_Nm','plastic_rotation_rad','basic_rotation_rad'};
    for j=1:numel(fields),f=fields{j}; display.(k).(f)=result.(k).(f)(1:20:end);end
end
fid=fopen(fullfile(out,'hinge_curve_2p5.json'),'w');
fwrite(fid,jsonencode(display),'char'); fclose(fid);
end
