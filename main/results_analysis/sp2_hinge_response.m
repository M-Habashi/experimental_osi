function result=sp2_hinge_response(mod,M,C,K,F,h,teq,trace_ends)
% Shared offline concentrated-plasticity Newmark solver; N-m-s units.
if nargin<8,trace_ends=[];end

B=mod.B; D=mod.D; nh=size(B,1); nd=size(K,1); cap=mod.Mp;
H=0.01*diag(D); A=K+4/h^2*M+2/h*C;
Ai=A\eye(nd); Q=A\(B'*D);
% Eliminate structural DOFs from the incremental plasticity equations.
S=D+diag(H)-D*B*Q; S=(S+S')/2;
x=zeros(nd,1); v=x; acc=x; p=zeros(nh,1);
first=nan(nh,1); peak=p; cumulative=p; peakM=p;
uf=zeros(3,size(F,2)); counts=zeros(1,size(F,2)); maxres=0; maxit=0;
trace_m=zeros(numel(trace_ends),size(F,2)); trace_p=trace_m; trace_q=trace_m;
for i=1:size(F,2)
    rhs=F(:,i)+M*(4/h^2*x+4/h*v+acc)+C*(2/h*x+v);
    trial=Ai*(rhs+B'*D*p);
    xi=D*(B*trial-p)-H.*p;
    active=abs(xi)>cap+1e-7; sg=sign(xi); dp=zeros(nh,1);
    for it=1:100
        dp(:)=0;
        dp(active)=S(active,active)\(xi(active)-sg(active).*cap(active));
        bad=active & sg.*dp < -1e-12;
        if any(bad),active(bad)=false;continue;end
        corrected=xi-S*dp;
        add=~active & abs(corrected)>cap+1e-5;
        if any(add),active(add)=true;sg(add)=sign(corrected(add));continue;end
        break
    end
    assert(it<100,'Plastic active set did not converge.');
    xn=trial+Q*dp; pn=p+dp;
    an=4/h^2*(xn-x)-4/h*v-acc; vn=v+h/2*(acc+an);
    moment=D*(B*xn-pn);
    if ~isempty(trace_ends)
        trace_m(:,i)=moment(trace_ends); trace_p(:,i)=pn(trace_ends);
        trace_q(:,i)=B(trace_ends,:)*xn;
    end
    residual=M*an+C*vn+mod.Kspring*xn+B'*moment-F(:,i);
    maxres=max(maxres,norm(residual,inf));maxit=max(maxit,it);
    newly=isnan(first) & abs(dp)>1e-10; first(newly)=teq(i);
    peak=max(peak,abs(pn)); cumulative=cumulative+abs(dp);
    peakM=max(peakM,abs(moment)); uf(:,i)=xn(1:3);
    counts(i)=sum(isfinite(first));
    p=pn;x=xn;v=vn;acc=an;
end
result=struct('first_yield',first,'peak_plastic',peak, ...
    'cumulative_plastic',cumulative,'final_plastic',p,'peak_moment',peakM, ...
    'floor_displacement_m',uf,'formed_hinge_count',counts, ...
    'max_residual',maxres,'max_active_set_iterations',maxit);
if ~isempty(trace_ends)
    result.trace=struct('ends',{mod.labels(trace_ends)},'moment_Nm',trace_m, ...
        'plastic_rotation_rad',trace_p,'basic_rotation_rad',trace_q);
end
end
