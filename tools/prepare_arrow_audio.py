"""Fit the supplied launch reference to arrow flight lengths while preserving pitch.
NumPy phase vocoder, stereo linked timing; only a very small final rate correction
is needed at runtime to end on the exact animation frame.
"""
import json, wave
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
RATE=48000
DURATIONS=[.10,.12,.14,.16,.18]+[round(float(t),2) for t in np.arange(.20,1.501,.05)]+[1.6,1.8,2.,2.2,2.5,2.8,3.,3.5,4.,5.,6.,8.,12.,16.]
def stretch(x, seconds):
    nfft=1024; hop=256
    window=np.hanning(nfft)
    padded=np.pad(x,((nfft//2,nfft//2+nfft),(0,0)))
    positions=range(0,len(padded)-nfft+1,hop)
    spectra=np.stack([np.fft.rfft(padded[p:p+nfft]*window[:,None],axis=0) for p in positions],axis=1)
    expected=np.arange(nfft//2+1)[:,None]*2*np.pi*hop/nfft
    output_length=round(seconds*RATE)
    speed=len(x)/output_length
    steps=np.arange(0,(output_length+nfft)//hop+2)*speed
    phase=np.angle(spectra[:,0,:]); result=np.zeros((output_length+3*nfft,2)); weights=np.zeros(len(result))
    for j,t in enumerate(steps):
        frame=min(int(t),spectra.shape[1]-2); fraction=min(1.,t-frame)
        left=spectra[:,frame,:]; right=spectra[:,frame+1,:]
        magnitude=(1-fraction)*abs(left)+fraction*abs(right)
        value=np.fft.irfft(magnitude*np.exp(1j*phase),n=nfft,axis=0)*window[:,None]
        start=j*hop
        if start+nfft>len(result): break
        result[start:start+nfft]+=value; weights[start:start+nfft]+=window**2
        delta=np.angle(right)-np.angle(left)-expected
        delta-=2*np.pi*np.round(delta/(2*np.pi))
        phase+=expected+delta
    result/=np.maximum(weights[:,None],1e-9)
    result=result[nfft//2:nfft//2+output_length]
    # Equalize energy, never boost above the supplied reference peak.
    energy=np.sqrt(np.mean(result**2)); original=np.sqrt(np.mean(x**2))
    if energy: result*=min(original/energy,float(abs(x).max())/max(1e-9,float(abs(result).max())))
    attack=min(96,len(result)//4); release=min(576,len(result)//4)
    result[:attack]*=(np.sin(np.linspace(0,np.pi/2,attack))**2)[:,None]
    result[-release:]*=(np.sin(np.linspace(np.pi/2,0,release))**2)[:,None]
    return result

def main():
    with wave.open(str(ROOT/'audio/arrow_escape.wav'),'rb') as f:
        assert f.getframerate()==RATE and f.getnchannels()==2 and f.getsampwidth()==2
        reference=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').reshape(-1,2).astype(float)/32768
    # Keep the complete audible gesture, excluding its long near-silent file tail.
    core=reference[:round(.40*RATE)]
    directory=ROOT/'audio/arrow_flight';directory.mkdir(exist_ok=True)
    entries=[]
    for duration in DURATIONS:
        name=f'flight_{round(duration*1000):05d}.wav'; y=stretch(core,duration)
        with wave.open(str(directory/name),'wb') as f:
            f.setnchannels(2);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(np.round(np.clip(y,-1,1)*32767).astype('<i2').tobytes())
        entries.append(dict(duration=duration,path='res://audio/arrow_flight/'+name))
    (ROOT/'audio/arrow_flight.json').write_text(json.dumps(dict(version=1,reference='res://audio/arrow_escape.wav',core_seconds=.40,entries=entries),indent=2)+'\n',encoding='utf-8')
    print('PREPARED',len(entries),'pitch-preserving flight lengths')
if __name__=='__main__':main()
