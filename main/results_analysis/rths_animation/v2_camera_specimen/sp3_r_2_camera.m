function cam = sp3_r_2_camera(mirror)
%SP3_R_2_CAMERA Calibration of the lab camera footage of test sp3_r_2.
% Raw video px (1080x1920 portrait, y down); time [s]; shape [px per mm of dm].
% Sync and shape were measured by tracking the column edge against logged dm.
here = fileparts(mfilename('fullpath'));
cam.file = fullfile(fileparts(here), 'footage', 'sp3_r_2_specimen_camera.MOV');
cam.fps = 30; cam.b = -178.64;           % video time = lab time + b
cam.roll = 0.92; cam.ctr = [540.5 960.5]; % level the column (deg, CCW)
cam.mirror = mirror;                      % true: actuator on the left like the drawing
cam.crop = [190 0 890 1685];              % [x y w h] after leveling
cam.lens = [44 386 280 530];              % [x y w h] design px, same aspect as crop
cam.pin = [748 297]; cam.base = [493.5 1585]; cam.px_m = 1270;
cam.stencil = [930 640 46 190];           % W14X132 lettering, hidden when mirrored
cam.yc = [62 120 300 500 700 900 1100 1300 1500 1590];
cam.shape = [62 1.283; 120 1.283; 300 1.277; 500 1.075; 700 0.871; 900 0.671; ...
    1100 0.379; 1300 0.277; 1500 0.091; 1590 0];
cam.edgeL = [-0.0110 386.9]; cam.edgeR = [-0.0209 650.5]; % column edges x(y)
cam.actPoly = [645 210; 800 210; 815 262; 905 262; 910 228; 1030 220; 1065 240; 1080 260; ...
    1080 390; 1040 415; 910 415; 905 378; 815 380; 800 400; 645 400]; % clevis, rod, load cell
end
