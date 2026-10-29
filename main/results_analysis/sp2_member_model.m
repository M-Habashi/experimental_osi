function model=sp2_member_model(fem,isnum)
% Member-end bending operators and nominal capacities for SP2 offline replay.

f=fem.frame; a=fem.assembly; nd=size(a.K_full,1);
B=zeros(0,nd); D=zeros(0); labels={}; sections={}; My=[]; Mp=[];
inner='W8x35'; if isfield(f.section,'inner_column'),inner=f.section.inner_column;end
outer='W8x28'; if isfield(f.section,'exterior_column'),outer=f.section.exterior_column;end
for c=1:f.n_bay+1
    sec=inner; if c==1 || c==f.n_bay+1,sec=outer;end
    for s=1:f.n_story
        L=f.story_height; lower=s-1; rot=a.joint_rotation_dofs(c,s);
        if isnum && c==1 && s==1
            L=L-fem.experimental_column.height;
            lower=a.interface_dof; rot=a.interface_rotation_dof;
        end
        b=zeros(2,nd);
        if lower>0,b(:,lower)=-1/L;end
        b(:,s)=1/L;
        if rot>0,b(1,rot)=1;end
        b(2,a.joint_rotation_dofs(c,s+1))=1;
        append(b,L,sec,{sprintf('C%d-S%d-bottom',c,s);sprintf('C%d-S%d-top',c,s)});
    end
end
for s=1:f.n_story
    for bay=1:f.n_bay
        b=zeros(2,nd); b(1,a.beam_rotation_dofs(s,2*bay-1))=1;
        b(2,a.beam_rotation_dofs(s,2*bay))=1;
        append(b,f.bay_width,'W8x24', ...
            {sprintf('B%d-F%d-left',bay,s);sprintf('B%d-F%d-right',bay,s)});
    end
end
model=struct('B',B,'D',D,'labels',{labels},'sections',{sections},'My',My,'Mp',Mp);
% Only base springs remain after subtracting member stiffness for these FEMs.
model.Kspring=a.K_full-B'*D*B;
assert(norm(model.Kspring-diag(diag(model.Kspring)),'fro')<1e-6*norm(a.K_full,'fro'));
    function append(b,L,sec,names)
        B=[B;b]; D=blkdiag(D,f.E*f.section.(sec).Ix/L*[4 2;2 4]);
        labels=[labels;names]; sections=[sections;{sec;sec}];
        % Strong-axis S and Z: SAP template export for W8s. W12x40:
        % nominal 11.9-in depth gives S=2I/d; Z=57 in^3 (AISC).
        switch sec
            case 'W8x24', S=0.0003417932338277422; Z=0.00037854118465116874;
            case 'W8x28', S=0.00039849433955150377; Z=0.0004457281533023376;
            case 'W8x35', S=0.0005126002850569516; Z=0.0005686311333023376;
            case 'W12x40', S=2*f.section.(sec).Ix/(11.9*0.0254); Z=57*0.0254^3;
        end
        Fy=344737894.475789; % STEEL_E200, SAP export: 50 ksi.
        My=[My;Fy*S;Fy*S]; Mp=[Mp;Fy*Z;Fy*Z];
    end
end
