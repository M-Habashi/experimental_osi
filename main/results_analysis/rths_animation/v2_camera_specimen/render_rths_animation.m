function render_rths_animation(data_file, video_file, preview_tau, opt)
%RENDER_RTHS_ANIMATION Real-time (earthquake clock) RTHS animation, 1920x1080.
% data_file from prepare_rths_animation_data. preview_tau (optional) writes
% PNG stills at those earthquake times instead of the video.
% opt.camera (lab camera struct, see make_trials) shows the real specimen in
% a magnifier lens instead of the drawn one; opt.background 'lab'|'cutout',
% opt.edge 'feather'|'card', opt.members 'flat'|'steel'. No opt = v1 look.
% Units: earthquake time [s], displacement [mm], force [kip], ag [g].
if nargin < 3, preview_tau = []; end
if nargin < 4, opt = struct('camera', []); end
opt = setDefaults(opt, struct('camera', [], 'background', 'lab', 'edge', 'feather', ...
    'members', 'flat', 'tags', false)); % tags: note when the camera was not recording
cam = opt.camera; hasCam = ~isempty(cam);
d = load(data_file); tr = d.tr; fr = d.fr; meta = d.meta; M = d.model;
[~, run_name] = fileparts(data_file); run_name = strrep(run_name, '_anim_data', '');
kip = 4448.2216152605; fps = meta.fps;

C.bg = [0.953 0.953 0.945]; C.edge = [0.878 0.878 0.867];
C.ink = [0.11 0.11 0.11]; C.ink2 = [0.33 0.33 0.33]; C.muted = [0.53 0.53 0.52];
C.grid = [0.925 0.925 0.918]; C.steel = [0.22 0.24 0.27]; C.ghost = [0.80 0.80 0.78];
C.blue = [0 124 168]/255; C.purple = [116 5 138]/255; C.copper = [172 100 32]/255;
C.green = [57 191 94]/255; C.red = [144 21 0]/255;
tint = @(c, a) a*c + (1 - a)*[1 1 1];
rgb = @(c) sprintf('\\color[rgb]{%.3f %.3f %.3f}', c);
FN = 'Segoe UI'; dot = char(9679); dia = char(9670); mid = char(183);
tau_end = fr.tau(end);

%% Geometry and scale
F = M.frame; W = F.bay_width; H = F.story_height; nb = F.n_bay; ns = F.n_story;
he = M.h_exp; A = M.assembly; J = A.joint_rotation_dofs; nh = numel(M.labels);
u_max = max(abs(fr.x(:, 1:ns)), [], 'all');
scales = [5 10 15 20 25 30 40 50 75 100];
adaptive = 5*u_max > 0.8; % runaway response: auto-zoom with look-ahead
if adaptive, sc = 5; else, sc = scales(find(scales*u_max <= 0.8, 1, 'last')); end
nk = numel(fr.tau); look = round(0.3*fps); sck = sc*ones(nk, 1); tau_u = inf;
if adaptive
    sck = min(5, 0.8./easeEnv(max(abs(fr.x(:, 1:ns)), [], 2), 0.16, look));
    tau_u = tr.tau(find(abs(tr.dn) > 1.12*max(abs(tr.dm)), 1));
end
fmtd = @(v) fmtDisp(v);
xi = [0 0.07 linspace(0.12, 0.88, 14) 0.93 1];
N1 = 1 - 3*xi.^2 + 2*xi.^3; N2 = xi - 2*xi.^2 + xi.^3;
N3 = 3*xi.^2 - 2*xi.^3; N4 = -xi.^2 + xi.^3;
idx = containers.Map(M.labels, num2cell(1:nh));
fp = M.first_plastic; fy = M.first_yield;
p_peak = cummax(abs(fr.p), 1); p_ref = max(p_peak(:));

%% Figure and cards
f = figure('Visible', 'off', 'Units', 'pixels', 'Position', [0 0 1920 1080], ...
    'Color', C.bg, 'InvertHardcopy', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
    'Renderer', 'opengl');
bg = axes(f, 'Units', 'pixels', 'Position', [0 0 1920 1080], 'XLim', [0 1920], ...
    'YLim', [0 1080], 'Visible', 'off'); hold(bg, 'on')
cards = [24 372 1080 584; 24 24 1080 324; 1128 500 768 456; 1128 24 768 452];
for c = 1:size(cards, 1)
    w = cards(c, 3); h = cards(c, 4);
    rectangle(bg, 'Position', cards(c, :), 'Curvature', [28/w 28/h], ...
        'FaceColor', 'w', 'EdgeColor', C.edge, 'LineWidth', 1);
end
T = @(ax, x, y, s, sz, col, varargin) text(ax, x, y, s, 'FontName', FN, ...
    'FontSize', sz, 'Color', col, 'Clipping', 'off', varargin{:});

%% Header
T(bg, 24, 1038, 'SP3  Real-time hybrid simulation', 22, C.ink, 'FontWeight', 'bold');
T(bg, 26, 1003, sprintf('%s  %s  %s  %s  El Centro %s%.1f  %s  numerical 3-story frame with bilinear plastic hinges  +  physical W8x28 column', ...
    run_name, mid, datestr(meta.runStartTime, 'dd mmm yyyy, HH:MM'), mid, char(215), ...
    meta.intensity, mid), 11, C.ink2, 'Interpreter', 'none');
T(bg, 1330, 1052, 'EARTHQUAKE TIME (REAL SPEED)', 9, C.muted, 'FontWeight', 'bold');
hClock = T(bg, 1330, 1018, '0.00 s', 30, C.ink, 'FontWeight', 'bold');
hLab = T(bg, 1332, 988, '', 10, C.muted);
plot(bg, [1640 1640], [986 1056], 'Color', C.edge, 'LineWidth', 1)
T(bg, 1664, 1052, 'PLASTIC HINGES', 9, C.muted, 'FontWeight', 'bold');
hCount = T(bg, 1664, 1018, '0', 30, C.ink, 'FontWeight', 'bold');
T(bg, 1720, 1014, sprintf('of %d member ends', nh), 10, C.muted);
hFirst = T(bg, 1666, 988, '', 10, C.muted);
patch(bg, [24 1896 1896 24], [966 966 970 970], C.grid, 'EdgeColor', 'none');
hProg = patch(bg, [24 24 24 24], [966 966 970 970], C.ink, 'EdgeColor', 'none');
px = @(t) 24 + (1896 - 24)*t/tau_end;
hProgTicks = plot(bg, nan, nan, '-', 'Color', C.red, 'LineWidth', 2);

%% Structure card
T(bg, 48, 930, 'Hybrid structure', 15, C.ink, 'FontWeight', 'bold');
hScale = T(bg, 216, 930, '', 11, C.muted);
hLatest = T(bg, 1080, 930, '', 11, C.ink2, 'HorizontalAlignment', 'right');
sp = [44 392 1040 508]; xl = [-2.75 11.85]; xg = [-2.7 10.7]; xfl = 10.25; ifp = [-2.68 2.45];
if hasCam, sp = [356 392 736 508]; xl = [-1.75 11.4]; xg = [-0.75 9.6]; xfl = 9.4; ifp = [-1.7 7.6]; end
st = axes(f, 'Units', 'pixels', 'Position', sp);
yl = -0.62 + [0 diff(xl)*sp(4)/sp(3)];
set(st, 'XLim', xl, 'YLim', yl, 'DataAspectRatio', [1 1 1], 'Visible', 'off');
hold(st, 'on')
plot(st, xg, [0 0], 'Color', C.ink2, 'LineWidth', 1.4)
for xh = xg(1) + 0.15:0.26:xg(2) - 0.1
    plot(st, [xh xh - 0.16], [0 -0.16], 'Color', C.ghost, 'LineWidth', 0.8)
end
if hasCam
    % lab camera lens: crop of the real specimen, linked to its true-scale box
    lp = cam.lens; sv = lp(3)/cam.crop(3); ppm = sp(3)/diff(xl);
    toBg = @(x, y) [sp(1) + (x - xl(1))*ppm, sp(2) + (y - yl(1))*ppm];
    R = @(p) [cam.ctr(1) + (p(1) - cam.ctr(1))*cosd(cam.roll) + (p(2) - cam.ctr(2))*sind(cam.roll), ...
        cam.ctr(2) - (p(1) - cam.ctr(1))*sind(cam.roll) + (p(2) - cam.ctr(2))*cosd(cam.roll)];
    toLens = @(p) [cam.mirror*lp(3) + (1 - 2*cam.mirror)*(p(1) - cam.crop(1))*sv, (p(2) - cam.crop(2))*sv];
    pin0 = toLens(R(cam.pin)); base0 = toLens(R(cam.base));
    [LX, LY] = meshgrid(1:lp(3), 1:lp(4)); % inverse map lens px -> leveled -> raw px
    Xl = cam.crop(1) + (cam.mirror*lp(3) + (1 - 2*cam.mirror)*LX)/sv - cam.ctr(1);
    Yl = cam.crop(2) + LY/sv - cam.ctr(2);
    Xs = cam.ctr(1) + Xl*cosd(cam.roll) - Yl*sind(cam.roll);
    Ys = cam.ctr(2) + Xl*sind(cam.roll) + Yl*cosd(cam.roll);
    sgn = 1 - 2*~cam.mirror; % +dm moves left in the raw picture
    box = [-base0(1), base0(2) - lp(4), lp(3), lp(4)]/(sv*cam.px_m);
    if strcmp(opt.edge, 'feather')
        c1 = toBg(box(1), box(2)); c2 = toBg(box(1), box(2) + box(4)); xe = lp(1) + lp(3) - 6;
        patch(bg, [xe c2(1) c1(1) xe], [lp(2) + lp(4) - 40, c2(2), c1(2), lp(2) + 40], ...
            tint(C.blue, 0.07), 'EdgeColor', 'none');
        plot(bg, [xe c2(1)], [lp(2) + lp(4) - 40, c2(2)], 'Color', tint(C.blue, 0.35), 'LineWidth', 0.8)
        plot(bg, [xe c1(1)], [lp(2) + 40, c1(2)], 'Color', tint(C.blue, 0.35), 'LineWidth', 0.8)
    else
        c1 = toBg(box(1), box(2)); c2 = toBg(box(1), box(2) + box(4)); xe = lp(1) + lp(3);
        plot(bg, [xe c2(1)], [lp(2) + lp(4) - 24, c2(2)], ':', 'Color', C.blue, 'LineWidth', 1)
        plot(bg, [xe c1(1)], [lp(2) + 24, c1(2)], ':', 'Color', C.blue, 'LineWidth', 1)
    end
    rectangle(st, 'Position', box, 'Curvature', 0.1, 'FaceColor', tint(C.blue, 0.08), ...
        'EdgeColor', tint(C.blue, 0.6), 'LineWidth', 1);
    ln = axes(f, 'Units', 'pixels', 'Position', lp, 'XLim', [0.5 lp(3) + 0.5], ...
        'YLim', [0.5 lp(4) + 0.5], 'YDir', 'reverse', 'Visible', 'off'); hold(ln, 'on')
    hImg = image(ln, zeros(lp(4), lp(3), 3, 'uint8'));
    if strcmp(opt.edge, 'feather')
        A0 = smooth01(min(LX - 1, lp(3) - LX)/44).*smooth01(min(LY - 1, lp(4) - LY)/44);
    else
        r = 22; dx = max(0, max(r - LX, LX - (lp(3) - r))); dy = max(0, max(r - LY, LY - (lp(4) - r)));
        A0 = double(dx.^2 + dy.^2 <= r^2);
        rectangle(bg, 'Position', lp, 'Curvature', [2*r/lp(3) 2*r/lp(4)], 'EdgeColor', C.edge, ...
            'LineWidth', 1.5);
    end
    cut = strcmp(opt.background, 'cutout');
    if cut % column outline and actuator silhouette from the rest frame
        colL = cell2mat(arrayfun(@(y) toLens(R([polyval(cam.edgeL, y) y])), cam.yc(:), 'UniformOutput', false));
        colR = cell2mat(arrayfun(@(y) toLens(R([polyval(cam.edgeR, y) y])), cam.yc(:), 'UniformOutput', false));
        ab = cell2mat(arrayfun(@(i) toLens(R(cam.actPoly(i, :))), (1:size(cam.actPoly, 1))', 'UniformOutput', false));
        act = conv2([1 2 1]/4, [1 2 1]/4, double(inpolygon(LX, LY, ab(:, 1), ab(:, 2))), 'same');
        plot(ln, [1 lp(3)], base0(2)*[1 1], 'Color', C.ink2, 'LineWidth', 1.4)
        for xh = 8:12:lp(3) - 4
            plot(ln, [xh xh - 7], base0(2) + [0 7], 'Color', C.ghost, 'LineWidth', 0.8)
        end
        uistack(hImg, 'top')
    end
    T(ln, 10, lp(4) - 14, sprintf('LAB CAMERA  %s  real specimen', mid), 9, C.ink2, ...
        'FontWeight', 'bold', 'BackgroundColor', 'w', 'Margin', 2);
    hTag = T(ln, lp(3)/2, 30, '', 9, C.ink2, 'HorizontalAlignment', 'center', ...
        'BackgroundColor', 'w', 'Margin', 2);
    hPin = plot(ln, nan, nan, 'o', 'MarkerSize', 8, 'MarkerFaceColor', C.blue, ...
        'MarkerEdgeColor', 'w', 'LineWidth', 1.5);
    hPinTxt = T(ln, nan, nan, 'd_m', 11, C.blue, 'FontWeight', 'bold');
    hRod = plot(st, [nan nan], [nan nan]);
    T(st, box(1) + box(3)/2, -0.40, 'physical specimen', 10, C.ink2, 'HorizontalAlignment', 'center');
    % camera frame for each animation frame: real while recording, first frame
    % before (specimen at rest), afterwards the real frame with the closest dm
    vr = VideoReader(cam.file); nv = vr.NumFrames; tvid = (0:nv - 1)'/cam.fps;
    dmv = interp1(tr.lab_t, tr.dm, tvid - cam.b, 'linear', 0);
    src.t = fr.lab_t + cam.b; src.type = ones(size(fr.tau));
    pre = src.t < 0; src.t(pre) = 0; src.type(pre) = 0;
    src.dm = interp1(tvid, dmv, src.t); jp = 1;
    for k = find(src.t > tvid(end))'
        [~, j] = min(abs(dmv - fr.dm(k)) + 1e-5*abs((1:nv)' - jp - 20));
        src.t(k) = tvid(j); src.dm(k) = dmv(j); src.type(k) = 2; jp = j;
    end
    cam_t1 = fr.tau(find(src.type == 1, 1, 'last'));
else
    rectangle(st, 'Position', [-0.62 0.02 1.24 he + 0.3], 'Curvature', 0.12, ...
        'FaceColor', tint(C.blue, 0.08), 'EdgeColor', 'none');
    patch(st, [-2.48 -2.22 -2.22 -2.48], [0 0 1.62 1.62], [0.87 0.87 0.85], 'EdgeColor', 'none');
    for yh = 0.12:0.22:1.5
        plot(st, [-2.48 -2.22], [yh yh + 0.16], 'Color', [0.76 0.76 0.74], 'LineWidth', 0.8)
    end
    patch(st, [-2.22 -1.18 -1.18 -2.22], he + [-0.11 -0.11 0.11 0.11], [0.60 0.62 0.65], ...
        'EdgeColor', 'none');
    T(st, -1.70, he - 0.24, 'actuator', 9, C.muted, 'HorizontalAlignment', 'center');
    hRod = plot(st, [-1.18 0], [he he], '-', 'Color', [0.45 0.47 0.50], 'LineWidth', 3.5);
    T(st, 0, -0.40, 'physical specimen (lab)', 10, C.ink2, 'HorizontalAlignment', 'center');
end
hNumLbl = T(st, 0.5*nb*W, ns*H + 0.28, sprintf('numerical substructure %s FE model, interface at mid-height of first-story column', mid), ...
    10, C.ink2, 'HorizontalAlignment', 'center');
lx = [3.0 4.65 6.6]; lm = {'o', 'd', 'o'}; lc = {C.green, C.copper, C.red};
ls = {'below M_y', 'M_y exceeded', 'plastic hinge'}; lsz = [34 70 70];
for q = 1:3
    scatter(st, lx(q), -0.40, lsz(q), lc{q}, 'filled', lm{q}, 'MarkerEdgeColor', 'w', 'LineWidth', 1);
    T(st, lx(q) + 0.16, -0.40, ls{q}, 10, C.ink2, 'VerticalAlignment', 'middle');
end
% undeformed ghost
for c = 1:nb + 1
    y0 = 0; if c == 1, y0 = he; end
    plot(st, (c - 1)*W*[1 1], [y0 ns*H], ':', 'Color', C.ghost, 'LineWidth', 1)
end
plot(st, [0 0], [0 he], ':', 'Color', tint(C.blue, 0.4), 'LineWidth', 1)
for s = 1:ns
    plot(st, [0 nb*W], s*H*[1 1], ':', 'Color', C.ghost, 'LineWidth', 1)
end
mw = 3.2; mc = {C.steel}; % flat members; 'steel': dark flanges, lighter web, highlight
if strcmp(opt.members, 'steel'), mw = [7 4.4 1.2]; mc = {[0.17 0.18 0.20], [0.36 0.38 0.41], [0.60 0.62 0.65]}; end
hCol = gobjects(nb + 1, ns, numel(mw)); hBeam = gobjects(ns, nb, numel(mw));
for q = 1:numel(mw)
    for c = 1:nb + 1
        for s = 1:ns
            hCol(c, s, q) = plot(st, nan, nan, '-', 'Color', mc{q}, 'LineWidth', mw(q));
        end
    end
    for s = 1:ns
        for b = 1:nb
            hBeam(s, b, q) = plot(st, nan, nan, '-', 'Color', mc{q}, 'LineWidth', 1.19*mw(q));
        end
    end
end
hSpec = plot(st, nan, nan, '-', 'Color', C.blue, 'LineWidth', 6.5 - 2.5*hasCam);
ha = st; if hasCam, ha = ln; end % f_m arrow on the real actuator when filmed
hArrow = plot(ha, nan, nan, '-', 'Color', C.purple, 'LineWidth', 3);
hHead = patch(ha, nan, nan, C.purple, 'EdgeColor', 'none');
hArrowTxt = T(ha, nan, nan, 'f_m', 11, C.purple, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
hDm = plot(st, nan, nan, 'o', 'MarkerSize', 8, 'MarkerFaceColor', C.blue, ...
    'MarkerEdgeColor', 'w', 'LineWidth', 1.5);
hDn = plot(st, nan, nan, 'o', 'MarkerSize', 12, 'MarkerFaceColor', 'none', ...
    'MarkerEdgeColor', C.ink, 'LineWidth', 1.8);
sEl = scatter(st, nan, nan, 34, C.green, 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 1);
sYi = scatter(st, nan, nan, 70, C.copper, 'filled', 'd', 'MarkerEdgeColor', 'w', 'LineWidth', 1);
sPl = scatter(st, nan, nan, 60, C.red, 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 1.2);
sPu = scatter(st, nan, nan, 60, C.red, 'LineWidth', 2);
hFloorTxt = gobjects(ns, 1);
for s = 1:ns
    hFloorTxt(s) = T(st, xfl, s*H, '', 11, C.ink2, 'VerticalAlignment', 'middle');
end
hIfTxt = T(st, ifp(1), ifp(2), '', 11, C.ink2, 'VerticalAlignment', 'middle');

%% Time histories card
T(bg, 48, 320, 'Time histories', 15, C.ink, 'FontWeight', 'bold');
T(bg, 192, 320, 'earthquake time, real speed', 11, C.muted);
T(bg, 1080, 320, sprintf('%s%s %sa_g ground      %s- - %sd_n numerical command      %s%s %sd_m measured      %s| %splastic hinge formed', ...
    rgb(C.ink2), char(8212), rgb(C.ink2), rgb(C.ink), rgb(C.ink2), rgb(C.blue), char(8212), rgb(C.ink2), ...
    rgb(C.red), rgb(C.ink2)), 10, C.ink2, 'HorizontalAlignment', 'right');
sty = @(ax) set(ax, 'Color', 'w', 'XColor', C.muted, 'YColor', C.muted, ...
    'GridColor', C.grid, 'GridAlpha', 1, 'XGrid', 'on', 'YGrid', 'on', 'Box', 'off', ...
    'TickDir', 'out', 'TickLength', [0.004 0.004], 'FontName', FN, 'FontSize', 10, ...
    'LineWidth', 0.8);
thh = axes(f, 'Units', 'pixels', 'Position', [112 282 968 14]); hold(thh, 'on')
set(thh, 'XLim', [0 tau_end], 'YLim', [0 1], 'Visible', 'off')
plot(thh, [0 tau_end], [0.5 0.5], 'Color', C.grid, 'LineWidth', 1)
T(bg, 104, 289, 'hinges', 10, C.muted, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
hHingeTicks = plot(thh, nan, nan, '-', 'Color', C.red, 'LineWidth', 2);
ta = axes(f, 'Units', 'pixels', 'Position', [112 178 968 92]); hold(ta, 'on'); sty(ta)
ag_lim = 1.12*max(abs(tr.ag_g));
set(ta, 'XLim', [0 tau_end], 'YLim', ag_lim*[-1 1], 'XTickLabel', []);
ylabel(ta, 'a_g (g)', 'Color', C.ink2, 'FontSize', 10);
keep = d.ag_full.tau <= tau_end;
plot(ta, d.ag_full.tau(keep), d.ag_full.ag_g(keep), '-', 'Color', tint(C.ink2, 0.22), 'LineWidth', 0.9)
hAg = plot(ta, nan, nan, '-', 'Color', C.ink2, 'LineWidth', 1.1);
hAgDot = plot(ta, nan, nan, 'o', 'MarkerSize', 6, 'MarkerFaceColor', C.ink2, 'MarkerEdgeColor', 'w');
td = axes(f, 'Units', 'pixels', 'Position', [112 66 968 100]); hold(td, 'on'); sty(td)
d_lim = 1.12*max(abs([tr.dn; tr.dm]));
set(td, 'XLim', [0 tau_end], 'YLim', d_lim*[-1 1]);
ylabel(td, 'interface (mm)', 'Color', C.ink2, 'FontSize', 10);
xlabel(td, 'earthquake time (s)', 'Color', C.ink2, 'FontSize', 10);
hDnT = plot(td, nan, nan, '--', 'Color', C.ink, 'LineWidth', 2.0);
hDmT = plot(td, nan, nan, '-', 'Color', C.blue, 'LineWidth', 1.3);
hDmDot = plot(td, nan, nan, 'o', 'MarkerSize', 6, 'MarkerFaceColor', C.blue, 'MarkerEdgeColor', 'w');
hPlay = [plot(ta, [0 0], ag_lim*[-1 1], '-', 'Color', C.ink, 'LineWidth', 0.8), ...
    plot(td, [0 0], d_lim*[-1 1], '-', 'Color', C.ink, 'LineWidth', 0.8)];
dlimk = d_lim*ones(nk, 1);
if adaptive
    dlimk = 1.12*easeEnv(max(abs([fr.dn fr.dm]), [], 2), max(abs(tr.dm)), look);
end

%% Hysteresis cards
hy = struct('x', {tr.dm, 1000*tr.u(:, ns)}, 'y', {tr.fm/kip, tr.base_shear/kip}, ...
    'pos', {[1212 560 652 312], [1212 84 652 312]}, 'top', {936, 456}, ...
    'kicker', {'SPECIMEN  /  PHYSICAL SUBSTRUCTURE', 'SYSTEM  /  HYBRID STRUCTURE'}, ...
    'title', {'Measured force vs interface displacement', 'Total base shear vs roof displacement'}, ...
    'xl', {'interface displacement  d_m  (mm)', 'roof displacement  x_{3,n}  (mm)'}, ...
    'yl', {'measured force  f_m  (kip)', 'base shear  V_b  (kip)'}, ...
    'xs', {'d_m', 'x_{3,n}'}, 'ys', {'f_m', 'V_b'});
for k = 1:2
    T(bg, 1152, hy(k).top, hy(k).kicker, 9, C.muted, 'FontWeight', 'bold');
    T(bg, 1152, hy(k).top - 24, hy(k).title, 14, C.ink, 'FontWeight', 'bold');
    hy(k).txt = T(bg, 1872, hy(k).top - 24, '', 11, C.ink2, 'HorizontalAlignment', 'right');
    ax = axes(f, 'Units', 'pixels', 'Position', hy(k).pos); hold(ax, 'on'); sty(ax)
    xr = [min(hy(k).x) max(hy(k).x)]; yr = [min(hy(k).y) max(hy(k).y)];
    set(ax, 'XLim', xr + 0.08*diff(xr)*[-1 1], 'YLim', yr + 0.1*diff(yr)*[-1 1]);
    hy(k).ax = ax; hy(k).lim = [];
    if adaptive && k == 2
        pre = tr.tau < tau_u;
        hy(k).lim = [1.08*easeEnv(abs(1000*fr.x(:, ns)), max(abs(hy(k).x(pre))), look), ...
            1.1*easeEnv(abs(fr.base_shear/kip), max(abs(hy(k).y(pre))), look)];
    end
    plot(ax, [-1e9 1e9], [0 0], 'Color', C.edge, 'LineWidth', 1)
    plot(ax, [0 0], [-1e9 1e9], 'Color', C.edge, 'LineWidth', 1)
    xlabel(ax, hy(k).xl, 'Color', C.ink2, 'FontSize', 10);
    ylabel(ax, hy(k).yl, 'Color', C.ink2, 'FontSize', 10);
    hy(k).hist = plot(ax, nan, nan, '-', 'Color', tint(C.purple, 0.26), 'LineWidth', 1);
    hy(k).trail = plot(ax, nan, nan, '-', 'Color', C.purple, 'LineWidth', 2.2);
    hy(k).head = plot(ax, nan, nan, 'o', 'MarkerSize', 9, 'MarkerFaceColor', C.purple, ...
        'MarkerEdgeColor', 'w', 'LineWidth', 1.8);
end

%% Hinge label parsing
hinfo = zeros(nh, 4); % [is_column, member col/bay, story/floor, is_far_end]
for j = 1:nh
    t = regexp(M.labels{j}, '^C(\d+)-S(\d+)-(bottom|top)$', 'tokens', 'once');
    if ~isempty(t)
        hinfo(j, :) = [1 str2double(t{1}) str2double(t{2}) strcmp(t{3}, 'top')];
    else
        t = regexp(M.labels{j}, '^B(\d+)-F(\d+)-(left|right)$', 'tokens', 'once');
        hinfo(j, :) = [0 str2double(t{1}) str2double(t{2}) strcmp(t{3}, 'right')];
    end
end
nice = @(j) niceLabel(hinfo(j, :));

%% Scale the 1920x1080 design onto a 1280x720 figure printed at 144 dpi
z = 2/3; set(f, 'Position', [0 0 1280 720]);
for o = findall(f, 'Type', 'axes')'
    o.Position = o.Position*z; o.FontSize = o.FontSize*z; o.LineWidth = o.LineWidth*z;
end
for o = findall(f, 'Type', 'text')', o.FontSize = o.FontSize*z; end
for o = [findall(f, 'Type', 'line'); findall(f, 'Type', 'rectangle')]'
    o.LineWidth = o.LineWidth*z;
    if isprop(o, 'MarkerSize'), o.MarkerSize = o.MarkerSize*z; end
end
for o = findall(f, 'Type', 'scatter')'
    o.LineWidth = o.LineWidth*z; o.SizeData = o.SizeData*z^2;
end

lab_t0 = fr.lab_t(2) - fr.tau(2)*meta.tsf; % lab time at earthquake start

%% Frames
if isempty(preview_tau)
    order = [ones(1, round(1.0*fps)), 1:numel(fr.tau), numel(fr.tau)*ones(1, round(3*fps))];
    v = VideoWriter(video_file, 'MPEG-4'); v.FrameRate = fps; v.Quality = 95; open(v)
else
    order = arrayfun(@(t) find(fr.tau >= t, 1), preview_tau);
end
tic
for n = 1:numel(order)
    k = order(n); drawFrame(k);
    img = print(f, '-RGBImage', '-r144');
    if n == 1, fprintf('frame size %dx%d\n', size(img, 2), size(img, 1)); end
    if size(img, 1) ~= 1080 || size(img, 2) ~= 1920
        img = imresize(img, [1080 1920]);
    end
    if isempty(preview_tau)
        writeVideo(v, img);
        if mod(n, 150) == 0, fprintf('%d/%d frames, %.0f s\n', n, numel(order), toc); end
    else
        imwrite(img, sprintf('%s_%05.2fs.png', video_file, fr.tau(k)));
    end
end
if isempty(preview_tau), close(v); end
fprintf('done in %.0f s\n', toc)

    function drawFrame(k)
        tau = fr.tau(k); x = fr.x(k, :)'; p = fr.p(k, :)'; sc = sck(k);
        zoom_txt = ''; if adaptive, zoom_txt = '  (auto-zoom)'; end
        set(hScale, 'String', sprintf('deformed shape from all 20 DOFs %s displacements %s%.2g%s', ...
            mid, char(215), sc, zoom_txt));
        if tau >= tau_u
            set(hNumLbl, 'String', sprintf(['%s%s  %sNumerical substructure unstable from %.2f s: collapse mechanism, ' ...
                'response beyond the small-displacement model'], rgb(C.red), char(9650), rgb(C.ink), tau_u), ...
                'FontWeight', 'bold');
        end
        set(td, 'YLim', dlimk(k)*[-1 1]); set(hPlay(2), 'YData', dlimk(k)*[-1 1]);
        if ~isempty(hy(2).lim)
            set(hy(2).ax, 'XLim', hy(2).lim(k, 1)*[-1 1], 'YLim', hy(2).lim(k, 2)*[-1 1]);
        end
        hpos = nan(nh, 2);
        % columns
        for c = 1:nb + 1
            for s = 1:ns
                yb = (s - 1)*H; ub = 0; if s > 1, ub = x(s - 1); end
                tb = 0; if J(c, s) > 0, tb = x(J(c, s)); end
                if c == 1 && s == 1
                    yb = he; ub = x(A.interface_dof); tb = x(A.interface_rotation_dof);
                end
                jb = idx(sprintf('C%d-S%d-bottom', c, s)); jt = idx(sprintf('C%d-S%d-top', c, s));
                L = s*H - yb;
                u = N1*ub + N3*x(s) - L*N2*(tb - p(jb)) - L*N4*(x(J(c, s + 1)) - p(jt));
                X = (c - 1)*W + sc*u; Y = yb + xi*L;
                set(hCol(c, s, :), 'XData', X, 'YData', Y);
                hpos(jb, :) = [X(2) Y(2)]; hpos(jt, :) = [X(end-1) Y(end-1)];
            end
        end
        % beams
        for s = 1:ns
            for b = 1:nb
                jl = idx(sprintf('B%d-F%d-left', b, s)); jr = idx(sprintf('B%d-F%d-right', b, s));
                vb = W*N2*(x(J(b, s + 1)) - p(jl)) + W*N4*(x(J(b + 1, s + 1)) - p(jr));
                X = (b - 1)*W + xi*W + sc*x(s); Y = s*H + sc*vb;
                set(hBeam(s, b, :), 'XData', X, 'YData', Y);
                hpos(jl, :) = [X(2) Y(2)]; hpos(jr, :) = [X(end-1) Y(end-1)];
            end
        end
        % physical specimen (fixed base, actuator pin at the interface)
        dm_k = fr.dm(k)/1000; dn_k = fr.dn(k)/1000;
        eta = linspace(0, 1, 18);
        set(hSpec, 'XData', sc*dm_k*(3*eta.^2 - eta.^3)/2, 'YData', eta*he);
        set(hDm, 'XData', sc*dm_k, 'YData', he); set(hDn, 'XData', sc*dn_k, 'YData', he);
        set(hRod, 'XData', [-1.18 sc*dm_k]);
        fm_k = fr.fm(k)/kip; Lf = 1.1*fm_k/max(abs(tr.fm/kip)); ya = he + 0.36;
        x0 = sc*dm_k; x1 = x0 + Lf; hl = 0.16*sign(Lf); hw = 0.09; lmin = 0.12;
        if hasCam % camera lens: real frame, pin marker and f_m arrow in lens pixels
            I = prepFrame(readAt(src.t(k)));
            us = sgn*sv*src.dm(k)*interp1(cam.shape(:, 1), cam.shape(:, 2), [cam.yc(:); cam.pin(2)], 'linear', 'extrap');
            Al = A0;
            if cut
                yy = (1:lp(4))'; % column: per-row strip between its moving edges
                xa = interp1(colL(:, 2), colL(:, 1) + us(1:end-1), yy);
                xb = interp1(colR(:, 2), colR(:, 1) + us(1:end-1), yy);
                mk = min(1, max(0, min(LX - min(xa, xb), max(xa, xb) - LX) + 0.5)); mk(isnan(mk)) = 0;
                Al = A0.*max(mk, interp2(act, LX - us(end), LY, 'linear', 0));
            end
            set(hImg, 'CData', I, 'AlphaData', Al);
            pk = pin0 + [us(end) 0];
            set(hPin, 'XData', pk(1), 'YData', pk(2));
            set(hPinTxt, 'Position', [pk(1) - 30*cam.mirror + 8*~cam.mirror, pk(2) + 22, 0]);
            Lf = sgn*0.32*lp(3)*fm_k/max(abs(tr.fm/kip)); x0 = pk(1); x1 = x0 + Lf; ya = pk(2) - 34;
            hl = 12*sign(Lf); hw = 7; lmin = 22;
            tags = {{sprintf('camera starts at %.2f s', fr.tau(find(src.type == 1, 1))), 'specimen at rest until then'}, '', ...
                {sprintf('camera stopped at %.2f s', cam_t1), 'real frames with the same d_m'}};
            set(hTag, 'String', tags{src.type(k) + 1}, 'Visible', onoff(opt.tags && src.type(k) ~= 1));
        end
        if abs(Lf) < lmin/3, hl = 0; end
        set(hArrow, 'XData', [x0 x1 - hl], 'YData', [ya ya]);
        set(hHead, 'XData', [x1 x1 - hl x1 - hl], 'YData', ya + [0 hw -hw]);
        if abs(Lf) < lmin
            set(hArrowTxt, 'Visible', 'off');
        else
            al = {'left', 'right'};
            set(hArrowTxt, 'Visible', 'on', 'Position', [x1 + lmin/1.2*sign(Lf), ya, 0], ...
                'HorizontalAlignment', al{1 + (Lf < 0)}, 'VerticalAlignment', 'middle');
        end
        % hinges
        plastic = fp <= tau; yielded = fy <= tau & ~plastic; elastic = ~plastic & ~yielded;
        set(sEl, 'XData', hpos(elastic, 1), 'YData', hpos(elastic, 2));
        set(sYi, 'XData', hpos(yielded, 1), 'YData', hpos(yielded, 2));
        sz = z^2*(70 + 230*min(1, p_peak(k, plastic)'/p_ref)); if isempty(sz), sz = 60*z^2; end
        set(sPl, 'XData', hpos(plastic, 1), 'YData', hpos(plastic, 2), 'SizeData', sz);
        age = tau - fp; pulse = age >= 0 & age < 0.9;
        if any(pulse)
            a = age(pulse)/0.9;
            set(sPu, 'XData', hpos(pulse, 1), 'YData', hpos(pulse, 2), ...
                'SizeData', z^2*(10 + 46*a).^2, 'CData', tint(C.red, 1 - a), 'Visible', 'on');
        else
            set(sPu, 'Visible', 'off');
        end
        % readouts
        for s = 1:ns
            set(hFloorTxt(s), 'Position', [xfl, s*H, 0], ...
                'String', sprintf('x_{%d,n}  %s', s, fmtd(1000*x(s))));
        end
        set(hIfTxt, 'String', {sprintf('%s- -  %sd_n  %s', rgb(C.ink), rgb(C.ink2), fmtd(fr.dn(k))), ...
            sprintf('%s%s  %sd_m  %s', rgb(C.blue), dot, rgb(C.ink2), fmtd(fr.dm(k))), ...
            sprintf('%s%s  %sf_m  %+6.2f kip', rgb(C.purple), char(8594), rgb(C.ink2), fm_k)});
        % header
        set(hClock, 'String', sprintf('%5.2f s', tau));
        set(hLab, 'String', sprintf('lab clock %.1f s  %s  test ran %s%g slower', ...
            max(0, fr.lab_t(k) - lab_t0), mid, char(215), meta.tsf));
        set(hCount, 'String', sprintf('%d', sum(plastic)));
        if any(plastic)
            set(hFirst, 'String', sprintf('first at %.2f s', min(fp)));
            [~, j] = max(fp.*(plastic) - 1e9*(~plastic));
            set(hLatest, 'String', sprintf('%s%s  %slatest plastic hinge  %.2f s  %s  %s', ...
                rgb(C.red), dot, rgb(C.ink2), fp(j), mid, nice(j)));
        end
        set(hProg, 'XData', [24 px(tau) px(tau) 24]);
        ft = fp(plastic)';
        set(hProgTicks, 'XData', reshape([px(ft); px(ft); nan(size(ft))], 1, []), ...
            'YData', reshape([963 + 0*ft; 973 + 0*ft; nan(size(ft))], 1, []));
        set(hHingeTicks, 'XData', reshape([ft; ft; nan(size(ft))], 1, []), ...
            'YData', reshape([0*ft; 1 + 0*ft; nan(size(ft))], 1, []));
        % traces
        it = find(tr.tau <= tau, 1, 'last'); rng = 1:it;
        set(hAg, 'XData', tr.tau(rng), 'YData', tr.ag_g(rng));
        set(hAgDot, 'XData', tr.tau(it), 'YData', tr.ag_g(it));
        set(hDnT, 'XData', tr.tau(rng), 'YData', tr.dn(rng));
        set(hDmT, 'XData', tr.tau(rng), 'YData', tr.dm(rng));
        set(hDmDot, 'XData', tr.tau(it), 'YData', tr.dm(it));
        set(hPlay, 'XData', [tau tau]);
        recent = max(1, it - round(1.2*meta.trace_hz)):it;
        for q = 1:2
            set(hy(q).hist, 'XData', hy(q).x(rng), 'YData', hy(q).y(rng));
            set(hy(q).trail, 'XData', hy(q).x(recent), 'YData', hy(q).y(recent));
            set(hy(q).head, 'XData', hy(q).x(it), 'YData', hy(q).y(it));
            set(hy(q).txt, 'String', sprintf('%s %s    %s %+5.2f kip', ...
                hy(q).xs, fmtd(hy(q).x(it)), hy(q).ys, hy(q).y(it)));
        end
    end

    function I = readAt(t)
        vr.CurrentTime = min(t, vr.Duration - 1/cam.fps); I = readFrame(vr);
    end

    function J = prepFrame(I)
        % hide the mirrored stencil, then level, crop, mirror and scale in one
        % resampling (Xs, Ys: raw px for each lens px) after an anti-alias blur
        if cam.mirror
            s = cam.stencil; rr = s(2):s(2) + s(4); cc = s(1):s(1) + s(3);
            a = double(median(I(s(2) - 14:s(2) - 4, cc, :), 1));
            b = double(median(I(rr(end) + 4:rr(end) + 14, cc, :), 1));
            w = linspace(0, 1, numel(rr))';
            I(rr, cc, :) = uint8((1 - w).*a + w.*b);
        end
        J = zeros(lp(4), lp(3), 3, 'uint8'); g = [1 4 6 4 1]/16;
        for ch = 1:3
            J(:, :, ch) = uint8(interp2(conv2(g, g, double(I(:, :, ch)), 'same'), Xs, Ys, 'linear', 255));
        end
    end
end

function o = setDefaults(o, def)
for f = fieldnames(def)'
    if ~isfield(o, f{1}), o.(f{1}) = def.(f{1}); end
end
end

function y = smooth01(x)
x = min(1, max(0, x)); y = x.^2.*(3 - 2*x);
end

function s = onoff(b)
s = 'off'; if b, s = 'on'; end
end

function s = niceLabel(h)
if h(1)
    ends = {'bottom', 'top'};
    s = sprintf('column %d, story %d, %s', h(2), h(3), ends{h(4) + 1});
else
    ends = {'left', 'right'};
    s = sprintf('beam bay %d, floor %d, %s end', h(2), h(3), ends{h(4) + 1});
end
end

function e = easeEnv(v, base, look)
% Monotone envelope with look-ahead and easing, never below the current value.
c = cummax(v(:)); n = numel(c);
t = max(base, c(min((1:n)' + look, n)));
e = t;
for k = 2:n, e(k) = e(k - 1) + 0.3*(t(k) - e(k - 1)); end
e = max(e, c);
end

function s = fmtDisp(v)
if abs(v) < 1000, s = sprintf('%+6.1f mm', v); else, s = sprintf('%+6.2f m', v/1000); end
end
