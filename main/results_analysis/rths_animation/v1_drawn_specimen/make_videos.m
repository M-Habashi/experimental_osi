% Rebuild the v1 (drawn specimen) RTHS animations: test file -> data/*.mat
% (replayed numerical substructure) -> videos/*.mp4. Delete a data file to
% force its replay again.
here = fileparts(mfilename('fullpath')); cd(here)
tests = fullfile(fileparts(fileparts(fileparts(here))), 'saved_results', 'tests', '20261111');
runs = {'sp3_r_2', 'sp3_r_2'; '20261111_1851_testing_OSI', '20261111_1851'}; % test file, video name
for i = 1:size(runs, 1)
    data = fullfile(here, 'data', [runs{i, 1} '_anim_data.mat']);
    if ~isfile(data), prepare_rths_animation_data(fullfile(tests, [runs{i, 1} '.mat']), data); end
    render_rths_animation(data, fullfile(here, 'videos', [runs{i, 2} '_rths_animation.mp4']));
end
