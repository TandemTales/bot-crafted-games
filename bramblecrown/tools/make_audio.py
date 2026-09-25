"""Synthesize Bramblecrown's original SFX and ambient music beds into assets/audio/*.wav.

    python tools/make_audio.py

Everything is generated from oscillators and filtered noise (no samples), so the audio is
original to this project. Deterministic: fixed RNG seeds.
"""
import os
import wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(1234)


def t(d, sr=SR):
    return np.arange(int(d * sr)) / sr


def env(n, a=0.005, r=0.2, sr=SR, curve=3.0):
    x = np.ones(n)
    ai = max(1, int(a * sr))
    x[:ai] = np.linspace(0, 1, ai)
    tail = np.linspace(1, 0, n - ai) ** curve
    x[ai:] = tail
    return x


def lowpass(x, cutoff, sr=SR):
    # One-pole low-pass, cutoff may be an array.
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    a = np.exp(-2 * np.pi * cutoff / sr)
    y = np.zeros_like(x)
    prev = 0.0
    for i in range(len(x)):
        prev = (1 - a[i]) * x[i] + a[i] * prev
        y[i] = prev
    return y


def highpass(x, cutoff, sr=SR):
    return x - lowpass(x, cutoff, sr)


def noise(n):
    return rng.uniform(-1, 1, n)


def save(name, x, sr=SR, stereo=False):
    x = np.asarray(x, dtype=float)
    peak = np.max(np.abs(x)) + 1e-9
    x = x / peak * 0.89
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(2 if stereo else 1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())
    print("[audio]", name, f"{len(x) / sr / (2 if stereo else 1):.2f}s")


def pluck(freq, dur, sr=SR, bright=0.5):
    """Karplus-Strong plucked string."""
    n = int(dur * sr)
    period = int(sr / freq)
    buf = rng.uniform(-1, 1, period) * bright
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % period]
        buf[i % period] = 0.5 * (buf[i % period] + buf[(i + 1) % period]) * 0.996
    return out


# ------------------------------------------------------------------ SFX

def sfx():
    d = 0.22
    n = int(d * SR)
    x = lowpass(highpass(noise(n), 900), np.linspace(6000, 1500, n)) * env(n, 0.01, d, curve=2)
    save("card", x)

    d = 0.7
    tt = t(d)
    rustle = lowpass(noise(len(tt)), 2500) * env(len(tt), 0.02, d, curve=2) * 0.5
    chime = sum(np.sin(2 * np.pi * f * tt) * env(len(tt), 0.005, d, curve=4) * (0.3 / k) for k, f in enumerate([660, 880, 1320], 1))
    rise = np.sin(2 * np.pi * (300 + 500 * tt) * tt) * env(len(tt), 0.05, d, curve=3) * 0.3
    save("grow", rustle + chime + rise)

    d = 0.8
    tt = t(d)
    f = 140 * np.exp(-tt * 1.8)
    squelch = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(tt), 0.01, d, curve=2)
    bubbles = lowpass(noise(len(tt)), 600) * env(len(tt), 0.05, d) * 0.8
    save("blight", squelch + bubbles)

    d = 0.35
    tt = t(d)
    thump = np.sin(2 * np.pi * 90 * tt * np.exp(-tt * 6)) * env(len(tt), 0.002, d, curve=4)
    crack = highpass(noise(len(tt)), 2000) * env(len(tt), 0.001, 0.08, curve=6) * 0.8
    save("hit", thump + crack)

    d = 0.5
    tt = t(d)
    save("hurt", np.sin(2 * np.pi * 70 * tt) * env(len(tt), 0.003, d, curve=3) + lowpass(noise(len(tt)), 400) * env(len(tt), 0.001, 0.2) * 0.6)

    d = 0.6
    tt = t(d)
    shimmer = sum(np.sin(2 * np.pi * f * tt + k) for k, f in enumerate([1046, 1318, 1568, 2093])) * env(len(tt), 0.02, d, curve=3)
    save("ward", shimmer * (1 + 0.3 * np.sin(2 * np.pi * 12 * tt)))

    d = 0.12
    tt = t(d)
    save("step", lowpass(noise(len(tt)), 700) * env(len(tt), 0.002, d, curve=3) + np.sin(2 * np.pi * 110 * tt) * env(len(tt), 0.002, d, curve=5) * 0.5)

    d = 1.0
    tt = t(d)
    f = 220 * np.exp(-tt * 2.5)
    groan = np.sign(np.sin(2 * np.pi * np.cumsum(f) / SR)) * 0.3 * env(len(tt), 0.01, d, curve=2)
    save("death", lowpass(groan, 900) + lowpass(noise(len(tt)), 500) * env(len(tt), 0.01, d) * 0.5)

    d = 0.05
    tt = t(d)
    save("click", np.sin(2 * np.pi * 1800 * tt) * env(len(tt), 0.001, d, curve=6))

    d = 1.2
    tt = t(d)
    gong = sum(np.sin(2 * np.pi * f * tt) * (0.5 / k) for k, f in enumerate([98, 196.5, 247, 392.3], 1)) * env(len(tt), 0.005, d, curve=2.5)
    save("turn", gong)

    d = 1.6
    tt = t(d)
    out = np.zeros(len(tt))
    for i, f in enumerate([392, 494, 587, 784]):
        s = int(i * 0.12 * SR)
        p = pluck(f, d - i * 0.12)
        out[s:s + len(p)] += p[: len(out) - s]
    save("win", out)

    d = 2.0
    tt = t(d)
    out = np.zeros(len(tt))
    for i, f in enumerate([330, 311, 262, 196]):
        s = int(i * 0.28 * SR)
        seg = np.sin(2 * np.pi * f * t(d - i * 0.28)) * env(int((d - i * 0.28) * SR), 0.02, d, curve=2)
        out[s:s + len(seg)] += seg[: len(out) - s] * 0.5
    save("lose", lowpass(out, 1500))

    d = 0.9
    tt = t(d)
    out = np.zeros(len(tt))
    for k in range(9):
        s = int(rng.uniform(0, 0.6) * SR)
        bd = 0.12
        bt = t(bd)
        b = np.sin(2 * np.pi * (300 + 900 * bt) * rng.uniform(0.6, 1.4) * bt) * env(len(bt), 0.005, bd, curve=3)
        out[s:s + len(b)] += b
    save("summon", out + lowpass(noise(len(tt)), 300) * env(len(tt), 0.1, d) * 0.4)

    d = 1.0
    tt = t(d)
    crackle = np.zeros(len(tt))
    idx = rng.integers(0, len(tt), 180)
    crackle[idx] = rng.uniform(-1, 1, len(idx))
    roar = lowpass(noise(len(tt)), np.linspace(3000, 600, len(tt))) * env(len(tt), 0.05, d, curve=1.5)
    save("burn", lowpass(crackle, 4000) * 2 + roar)


# ------------------------------------------------------------------ music beds

def drone(freqs, d, sr, detune=0.3):
    tt = t(d, sr)
    out = np.zeros(len(tt))
    for f in freqs:
        for dt in (-detune, 0, detune):
            out += np.sin(2 * np.pi * (f + dt) * tt + rng.uniform(0, 6.28))
    return out / (len(freqs) * 3)


def music(name, root, scale, bpm, d, dark=0.0, pulse=False):
    sr = 22050
    tt = t(d, sr)
    n = len(tt)
    pad = drone([root / 2, root * 0.75, root], d, sr) * (0.6 + 0.4 * np.sin(2 * np.pi * tt / d * 2) ** 2)
    pad = lowpass(pad, 900 - dark * 400, sr)
    wind = lowpass(noise(n), 350, sr) * (0.25 + 0.2 * np.sin(2 * np.pi * tt / d * 3))
    out = pad * 0.7 + wind * 0.35
    beat = 60.0 / bpm
    step = 0
    tpos = 0.0
    while tpos < d - 2.0:
        if rng.uniform() < 0.55:
            deg = rng.choice(scale)
            octave = rng.choice([1, 2])
            f = root * (2 ** (deg / 12)) * octave
            dur = beat * rng.choice([1, 2, 3])
            p = pluck(f, min(dur * 2, 2.5), sr, bright=0.35)
            s = int(tpos * sr)
            out[s:s + len(p)] += p[: n - s] * 0.35
        if pulse and step % 2 == 0:
            pd = 0.4
            pt = t(pd, sr)
            k = np.sin(2 * np.pi * 55 * pt * np.exp(-pt * 4)) * env(len(pt), 0.002, pd, sr, curve=4) * 0.5
            s = int(tpos * sr)
            out[s:s + len(k)] += k[: n - s]
        tpos += beat
        step += 1
    # Seamless loop: crossfade the tail into the head.
    fade = int(2.0 * sr)
    head = out[:fade].copy()
    out[:fade] = head * np.linspace(0, 1, fade) + out[-fade:] * np.linspace(1, 0, fade)
    out = out[:-fade]
    save(name, out, sr)


if __name__ == "__main__":
    sfx()
    minor_pent = [0, 3, 5, 7, 10]
    dorian = [0, 2, 3, 5, 7, 9, 10]
    music("title", 110.0, dorian, 56, 44)
    music("map", 98.0, minor_pent, 64, 40)
    music("battle", 87.3, minor_pent, 84, 40, dark=0.4, pulse=True)
    music("battle_boss", 73.4, [0, 1, 5, 7, 8], 96, 40, dark=0.8, pulse=True)
