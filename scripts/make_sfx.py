#!/usr/bin/env python3
"""Synthesize simple, royalty-free game sound effects (no samples, no licenses needed).

Usage: python3 scripts/make_sfx.py <output_dir>
Writes .wav files and, if ffmpeg is installed, .ogg versions (Roblox accepts both).
"""

import subprocess
import shutil
import sys
import wave
from pathlib import Path

import numpy as np

RATE = 44100


def tone(freq, dur, harmonics=(1.0, 0.35, 0.15), attack=0.005, release=0.25, vibrato=0.0):
    t = np.arange(int(RATE * dur)) / RATE
    phase_mod = vibrato * np.sin(2 * np.pi * 6 * t)
    wave_ = sum(a * np.sin(2 * np.pi * freq * (i + 1) * t + phase_mod) for i, a in enumerate(harmonics))
    env = np.minimum(1.0, t / attack) * np.exp(-t / release)
    return wave_ * env


def glide(f_start, f_end, dur, release=0.3, square=False):
    t = np.arange(int(RATE * dur)) / RATE
    freq = f_start * (f_end / f_start) ** (t / dur)  # exponential pitch sweep
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    wave_ = np.sign(np.sin(phase)) * 0.5 if square else np.sin(phase)
    env = np.minimum(1.0, t / 0.005) * np.exp(-t / release)
    return wave_ * env


def noise(dur, start_cut=0.05, end_cut=0.6):
    """Filtered noise 'whoosh' with a moving one-pole low-pass."""
    n = int(RATE * dur)
    rng = np.random.default_rng(7)
    white = rng.uniform(-1, 1, n)
    out = np.zeros(n)
    acc = 0.0
    for i in range(n):
        k = start_cut + (end_cut - start_cut) * (1 - abs(2 * i / n - 1))  # opens then closes
        acc += k * (white[i] - acc)
        out[i] = acc
    env = np.sin(np.pi * np.arange(n) / n) ** 2
    return out * env


def sequence(notes, gap):
    """notes: list of (freq, dur); each note starts `gap` seconds after the previous one."""
    total = int(RATE * (gap * (len(notes) - 1) + max(d for _, d in notes))) + 1
    out = np.zeros(total)
    for i, (f, d) in enumerate(notes):
        s = tone(f, d)
        start = int(RATE * gap * i)
        out[start : start + len(s)] += s
    return out


def reverb(x, delays=(0.031, 0.047, 0.071), decay=0.35):
    out = np.concatenate([x, np.zeros(int(RATE * 0.4))])
    for d in delays:
        k = int(RATE * d)
        for rep in range(1, 6):
            shifted = np.zeros_like(out)
            shifted[k * rep :] = out[: len(out) - k * rep] * decay**rep
            out = out + shifted * 0.5
    return out


def normalize(x, peak=0.8):
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def write(path: Path, x):
    data = (normalize(x) * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data.tobytes())
    if shutil.which("ffmpeg"):
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", str(path), "-c:a", "libvorbis", "-q:a", "5",
             str(path.with_suffix(".ogg"))],
            check=True,
        )


C5, E5, G5, C6, E6, G6 = 523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0

SOUNDS = {
    # Bright rising arpeggio: reached a checkpoint
    "checkpoint": lambda: reverb(sequence([(C5, 0.35), (E5, 0.35), (G5, 0.35), (C6, 0.6)], gap=0.07)),
    # Descending square "bwoop": fell into lava
    "death": lambda: glide(440, 110, 0.45, release=0.25, square=True) * 0.6,
    # Short fanfare: finished the course
    "finish": lambda: reverb(
        sequence([(G5, 0.18), (G5, 0.18), (G5, 0.18), (C6, 0.5), (G5, 0.2), (C6, 0.9)], gap=0.13)
        + np.pad(sequence([(E6, 0.9)], gap=0), (int(RATE * 0.65), 0))[: int(RATE * (0.13 * 5 + 0.9)) + 1]
    ),
    # Soft UI click
    "click": lambda: tone(1800, 0.06, harmonics=(1.0, 0.2), release=0.015),
    # Airy whoosh: platform disappears
    "disappear": lambda: noise(0.5) * 0.8 + glide(900, 300, 0.5, release=0.3) * 0.15,
}


def main():
    out_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "sfx")
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, make in SOUNDS.items():
        write(out_dir / f"{name}.wav", make())
        print(f"wrote {out_dir / name}.wav")


if __name__ == "__main__":
    main()
