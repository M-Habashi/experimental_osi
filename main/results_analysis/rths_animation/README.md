# RTHS animation videos

Each `vN_*` folder is a self-contained version: its own scripts, the replay
data it rendered from, and the finished videos. Older versions are never
edited, so you can always re-render or compare them.

| Folder | Physical substructure | Videos |
|---|---|---|
| `v1_drawn_specimen` | drawn cantilever driven by `dm` | `sp3_r_2`, `20261111_1851` |

- Rebuild a version: open its folder in MATLAB and run `make_videos`.
- `data/*_anim_data.mat`: numerical substructure replayed from the logged `fm`, sampled on the earthquake clock (from `prepare_rths_animation_data`).
- `footage/`: raw lab camera recordings (large, not in git). `sp3_r_2_specimen_camera.MOV` (1080x1920 portrait, 30 fps, 412.7 s) is the SP3 test `sp3_r_2`, filmed in lab time (20x slower than the earthquake clock).
  - Sync from the tracked column motion against the logged `dm` (correlation 0.9998, no clock drift): video time = lab time - 178.64 s. The video covers earthquake time 4.96 to 25.59 s of 37.52 s.
  - Column edge at the actuator height moves 1.070 px per mm of `dm`; positive `dm` moves left in the picture (actuator on the right).
- Git tag `rths-animation-v1` marks the v1 state.
