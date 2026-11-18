"""Export the existing nonlinear SP3 animation replay for the browser."""
import json
from pathlib import Path

import numpy as np
from scipy.io import loadmat

project = Path(__file__).resolve().parents[1]
source = project.parent / "v2_camera_specimen/data/sp3_r_2_anim_data.mat"
output = project / "public/data"
replay = loadmat(source, simplify_cells=True)
tr, fr, model, meta = (replay[k] for k in ("tr", "fr", "model", "meta"))
frame, assembly = model["frame"], model["assembly"]
kip = 4448.2216152605
# Row-major Float32 in display units. Keep every saved 200 Hz trace sample.
signals = np.column_stack((tr["dm"], tr["dn"], tr["fm"] / kip, tr["ag_g"],
                           tr["u"] * 1000, tr["base_shear"] / kip, tr["lab_t"]))
signals.astype("<f4").tofile(output / "signals.bin")
np.column_stack((fr["x"], fr["p"])).astype("<f4").tofile(output / "frame.bin")

def events(values):
    return [None if np.isnan(t) else round(float(t), 7) for t in values]

peak = int(np.argmax(abs(tr["dm"])))
info = {
    "test": "sp3_r_2", "source": meta["file"], "earthquake": "El Centro",
    "intensity": meta["intensity"], "timeScale": meta["tsf"], "height": model["h_exp"],
    "duration": float(tr["tau"][-1]), "hz": meta["trace_hz"], "samples": len(signals),
    "channels": ["dm", "dn", "fm", "ag", "x1", "x2", "x3", "baseShear", "labTime"],
    "frameHz": meta["fps"], "frameCount": len(fr["x"]), "dofs": fr["x"].shape[1],
    "labels": model["labels"].tolist(), "firstYield": events(model["first_yield"]),
    "firstPlastic": events(model["first_plastic"]), "bays": frame["n_bay"], "stories": frame["n_story"],
    "bayWidth": frame["bay_width"], "storyHeight": frame["story_height"],
    "jointRotation": assembly["joint_rotation_dofs"].tolist(),
    "interfaceDof": assembly["interface_dof"], "interfaceRotation": assembly["interface_rotation_dof"],
    "peakTime": float(tr["tau"][peak]), "cameraLabStart": 178.64, "cameraSeconds": 412.68,
    "labStart": float(tr["lab_t"][0]), "firstHinge": float(np.nanmin(model["first_plastic"])),
    "lastHinge": float(np.nanmax(model["first_plastic"]))
}
(output / "run.json").write_text(json.dumps(info, indent=2, allow_nan=False) + "\n", encoding="utf-8")

