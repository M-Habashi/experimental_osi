function result = check_pid_notch_switch()
% Offline simulation of the actual controller subsystem; no target connection.
package=fileparts(fileparts(mfilename('fullpath')));
project=fileparts(package);
model='paper3_pid_notch_check';
source='model_ColumnSetup_00';
load_system(fullfile(project,[source '.slx']));
new_system(model);
cleanup=onCleanup(@()close_system(model,0));
add_block([source '/controller'],[model '/Controller']);
set_param([model '/Controller/controller_enable_switch value'],'Value','1');
add_block('simulink/Sources/From Workspace',[model '/Error'], ...
    'VariableName','notch_check_input','Interpolate','on');
add_block('simulink/Sources/Constant',[model '/Reference'],'Value','0');
add_block('simulink/Sinks/To Workspace',[model '/Command'], ...
    'VariableName','notch_check_output','SaveFormat','Array');
add_line(model,'Error/1','Controller/1');
add_line(model,'Reference/1','Controller/2');
add_line(model,'Controller/1','Command/1');
set_param(model,'Solver','FixedStepDiscrete','FixedStep','dt','StopTime','2');
code=fileread(fullfile(project,'main_ColumnSetup.m'));
first=strfind(code,'% Sampling Variables');
last=strfind(code,'% phase_lead used');
parameters=code(first:last-1);
result=struct('enabled',[false true],'max_error',zeros(1,2));
for j=1:2
    hs=struct('notch',result.enabled(j));
    eval(parameters);
    t=(0:dt:2).';
    e=.2*sin(2*pi*26.62044547132503*t)+.1*sin(2*pi*2*t);
    input=Simulink.SimulationInput(model);
    values=struct('dt',dt,'pid_notch_num',pid_notch_num, ...
        'pid_notch_den',pid_notch_den,'pid_P',.12,'pid_I',12, ...
        'pid_D',.0012,'pid_N',512,'notch_check_input',[t e]);
    fields=fieldnames(values);
    for k=1:numel(fields)
        input=input.setVariable(fields{k},values.(fields{k}));
    end
    output=sim(input);
    C=pid(.12,12,.0012,1/512,dt,'IFormula','ForwardEuler','DFormula','ForwardEuler');
    expected=lsim(C,filter(pid_notch_num,pid_notch_den,e),t);
    result.max_error(j)=max(abs(output.notch_check_output-expected));
    fprintf('notch=%d: max error %.12g\n',hs.notch,result.max_error(j));
end
assert(all(result.max_error<1e-10),'PID notch/bypass differs from the expected digital filter.');
save(fullfile(package,'outputs/pid_notch_switch_check.mat'),'result');
disp(result)
end
