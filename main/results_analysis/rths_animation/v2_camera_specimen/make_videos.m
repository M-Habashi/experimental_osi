% Render the v2 RTHS animation of sp3_r_2 with the lab camera as the physical
% substructure: soft lens with the real lab background, mirrored so the real
% column moves the same way as the drawn frame, flat members. Before the camera
% started the first frame is held (specimen at rest); after it stopped, real
% frames with the same dm are used.
here = fileparts(mfilename('fullpath')); cd(here)
if ~isfolder('videos'), mkdir('videos'); end
render_rths_animation(fullfile(here, 'data', 'sp3_r_2_anim_data.mat'), ...
    fullfile(here, 'videos', 'sp3_r_2_rths_camera.mp4'), [], struct('camera', sp3_r_2_camera(true)));
