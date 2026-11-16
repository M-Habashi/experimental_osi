"""Summarize active sine loading and the completed vHS sizing case."""
from pathlib import Path

import h5py
import numpy as np
from scipy.io import loadmat, savemat

package = Path(__file__).resolve().parents[1]
source = package / "saved_results/tests/20261116/SP4_sine_repetitve_proof.mat"
with h5py.File(source, "r") as f:
    r = f["result"]
    time = r["t"][()].ravel()
    indices = np.flatnonzero(r["dd_pause_enable_log"][()].ravel() == 0)
    experimental = {"active_time_s": time[indices[[0, -1]]],
                    "source": str(source.relative_to(package))}
    for channel in ["dd", "dm", "fm", "auth"]:
        values = r[channel][()].ravel()
        i_min = indices[np.argmin(values[indices])]
        i_max = indices[np.argmax(values[indices])]
        experimental[channel + "_range"] = values[[i_min, i_max]]
        experimental[channel + "_extrema_time_s"] = time[[i_min, i_max]]

case = loadmat(package / "outputs/vhs_sp4_intensity_0p75.mat",
               simplify_cells=True)["result"]
result = {
    "experimental": experimental,
    "vhs_intensity_factor": case["intensity_factor"],
    "vhs_earthquake_type": case["earthquake_type"],
    "vhs_time_scale_factor": case["time_scale_factor"],
    "vhs_dm_range_mm": case["dm_range_mm"],
    "vhs_force_range_N": case["force_range_N"],
    "vhs_pga_g": case["peak_ground_acceleration_g"],
    "vhs_virtual_specimen_model": case["virtual_specimen_model"],
    "vhs_authority_factor": case["authority_factor"],
}
savemat(package / "outputs/repeatability_vhs_range_comparison.mat",
        {"result": result}, do_compression=True)
print(result)
