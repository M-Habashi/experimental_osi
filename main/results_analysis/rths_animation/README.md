# RTHS animation videos

Each `vN_*` folder is a self-contained version: its own scripts, the replay
data it rendered from, and the finished videos. Older versions are never
edited, so you can always re-render or compare them.

| Folder | Physical substructure | Videos |
|---|---|---|
| `v1_drawn_specimen` | drawn cantilever driven by `dm` | `sp3_r_2`, `20261111_1851` |
| `v2_camera_specimen` | lab camera in a soft magnifier lens (real lab, mirrored so it moves with the drawing, flat members); after the camera stopped, real frames with the same `dm`. `make_trials` renders the other style options | `sp3_r_2` |

- Rebuild a version: open its folder in MATLAB and run `make_videos`.
- `v2_camera_specimen/videos/index.html`: web player (play, speed, frame steps, scrub on the ground motion, jump to hinge formation). It loads the video as parts `sp3_r_2_rths_camera.mp4.0` to `.4` (4.8 MB each, for the 5 MB file cap of Cloudflare temporary deploys); publish it from a folder holding the page and the parts.
- `data/*_anim_data.mat`: numerical substructure replayed from the logged `fm`, sampled on the earthquake clock (from `prepare_rths_animation_data`).
- `footage/`: raw lab camera recordings (large, not in git). `sp3_r_2_specimen_camera.MOV` (1080x1920 portrait, 30 fps, 412.7 s) is the SP3 test `sp3_r_2`, filmed in lab time (20x slower than the earthquake clock).
  - Sync from the tracked column motion against the logged `dm` (correlation 0.9998, no clock drift): video time = lab time - 178.64 s. The video covers earthquake time 4.96 to 25.59 s of 37.52 s.
  - At the actuator pin (748, 297 px) the column moves 1.28 px per mm of `dm`, matching the geometric scale (base to pin 1288 px = 1.016 m). Positive `dm` moves left in the picture (actuator on the right). The camera is rolled 0.92 deg.
- Git tag `rths-animation-v1` marks the v1 state.
