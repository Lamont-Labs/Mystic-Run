#!/usr/bin/env python3
"""Original deterministic synthesized soundtrack and game effects; no samples."""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / 'assets/audio'


def write(name, duration, synth):
    rng = random.Random(823)
    samples = []
    for i in range(round(duration * RATE)):
        t = i / RATE
        value = max(-0.95, min(0.95, synth(t, rng)))
        samples.append(round(value * 32767))
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(struct.pack('<' + 'h' * len(samples), *samples))


def soundtrack(t, rng):
    bar = int(t / 2.4) % 8
    roots = [73.416, 73.416, 65.406, 65.406, 58.270, 58.270, 65.406, 69.296]
    root = roots[bar]
    local = t % 2.4
    envelope = min(local / 0.12, 1.0) * min((2.4 - local) / 0.22, 1.0)
    pad = sum(math.sin(2 * math.pi * root * ratio * t) * volume for ratio, volume in [(1,.09),(2,.045),(2.997,.025),(4,.012)])
    beat = t % .6
    pulse = math.sin(2 * math.pi * (43 * beat + 9 * (1-math.exp(-beat*25)))) * math.exp(-beat * 16) * .13
    chime = math.sin(2 * math.pi * root * 8 * t) * math.exp(-local * 3) * .035
    air = (rng.random() - .5) * .006
    return pad * envelope + pulse + chime + air


def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    write('city-pulse', 19.2, soundtrack)
    write('strike', .26, lambda t,r: ((r.random()-.5)*.55 + math.sin(2*math.pi*1300*t)*.07)*math.sin(min(1,t/.26)*math.pi)*math.exp(-t*9))
    write('impact', .30, lambda t,r: ((r.random()-.5)*.40 + math.sin(2*math.pi*(86*t+18*t*t))*.35)*math.exp(-t*17))
    write('spell', .42, lambda t,r: (math.sin(2*math.pi*(520*t+840*t*t))*.19+math.sin(2*math.pi*1300*t)*.055)*math.sin(t/.42*math.pi)*math.exp(-t*3))
    write('wing', .45, lambda t,r: (r.random()-.5)*.30*math.sin(t/.45*math.pi)**2)
    write('handoff', .8, lambda t,r: sum(math.sin(2*math.pi*f*t)*.09 for f in [293.665,440,587.33])*math.sin(t/.8*math.pi)*math.exp(-t*2))
    write('pickup', .16, lambda t,r: math.sin(2*math.pi*(880*t+1400*t*t))*.15*math.sin(t/.16*math.pi))
    write('hurt', .4, lambda t,r: (math.sin(2*math.pi*(66*t-18*t*t))*.4+(r.random()-.5)*.16)*math.exp(-t*11))
    write('step', .085, lambda t,r: ((r.random()-.5)*.17+math.sin(2*math.pi*90*t)*.13)*math.exp(-t*52))
    print('Created 9 original audio assets')


if __name__ == '__main__':
    main()
