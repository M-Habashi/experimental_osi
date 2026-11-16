"""Shared reference lead + feedback-path notch; no authority scaling."""
from pathlib import Path
import json
import numpy as np
from scipy.io import loadmat
from scipy.optimize import minimize

package = Path(__file__).resolve().parents[1]
d = loadmat(package/'outputs/sp4_pair_search_models.mat', simplify_cells=True)['result']
f = d['frequency_hz'].ravel()
s = 2j/d['sample_dt']*np.tan(np.pi*f*d['sample_dt'])
band = (f >= .1) & (f <= 80.001)
num = d['num_response'].ravel()
controller = d['controller_response'].ravel()
plant = d['plant_response']
k = d['k_mm'].ravel()
w = 2*np.pi*d['notch_hz']

def evaluate(x):
    x = np.atleast_2d(x)
    z, ratio, q, zp, depth = np.exp(x).T
    lead = ratio*q/500*(s[:,None]+2*np.pi*z)/(s[:,None]+2*np.pi*z*ratio)
    lead *= (s[:,None]+2*np.pi*500)/(s[:,None]+2*np.pi*q)
    notch = (s[:,None]**2+2*w*s[:,None]*zp*depth+w*w)
    notch /= s[:,None]**2+2*w*s[:,None]*zp+w*w
    values, unstable = [], np.zeros(len(x))
    for j in range(2):
        for n in range(2):
            inner = controller[:,None]*plant[:,j,None]
            if n:
                inner = inner*notch
            response = -k[j]*num[:,None]*lead*inner/(1+inner)
            values.append(np.min(abs(1+response[band])/np.sqrt(2*(1+abs(response[band])**2)),axis=0))
            crossings = (response[:-1].imag*response[1:].imag < 0)
            crossings &= (response[:-1].real < -1) & (response[1:].real < -1)
            unstable += abs(np.sum(crossings*np.sign(np.diff(response.imag,axis=0)),axis=0))
    v = np.array(values).T
    penalty = np.maximum(.25-v[:,:2],0).sum(axis=1)**2
    penalty += np.maximum(.25-v[:,3],0)**2
    penalty += np.maximum(v[:,2]+.03-v[:,3],0)**2
    return 100*penalty+10*unstable-.02*v.min(axis=1), v

bounds = np.log([[.7,8],[1.3,20],[20,180],[.15,.8],[.1,.5]])
rng = np.random.default_rng(22)
samples = rng.uniform(bounds[:,0],bounds[:,1],(6000,5))
scores = np.concatenate([evaluate(b)[0] for b in np.array_split(samples,100)])
candidates = []
for j in np.argsort(scores)[:8]:
    opt = minimize(lambda x:evaluate(x)[0][0],samples[j],method='Powell',bounds=bounds,
                   options={'maxfev':650,'maxiter':40})
    x = opt.x if evaluate(opt.x)[0][0] < scores[j] else samples[j]
    z,ratio,q,zp,depth = np.exp(x)
    score, margins = evaluate(x)
    candidates.append(dict(score=float(score[0]),authority=1.0,zero_hz=[float(z),500.0],
        pole_hz=[float(z*ratio),float(q)],gain=float(ratio*q/500),notch_hz=float(d['notch_hz']),
        notch_zeta_zero=float(zp*depth),notch_zeta_pole=float(zp),ncf=margins[0].tolist(),
        placement='Base lead in HS reference path; notch inside PID forward feedback path.'))
candidates.sort(key=lambda c:c['score'])
(package/'outputs/sp4_pid_notch_candidates.json').write_text(json.dumps(candidates,indent=2)+'\n')
print(json.dumps(candidates[:3],indent=2),flush=True)
