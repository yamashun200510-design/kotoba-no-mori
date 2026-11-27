"""Generate the small, original looping BGM assets used by the Android app.

Only Python's standard library is required. Run from the repository root.
"""

import math
import os
import struct
import wave


RATE = 22050
HOME_BPM = 80
PUZZLE_BPM = 84


def frequency(note):
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def add_note(buffer, start, length, midi, level, kind="plucked"):
    first = max(0, int(start * RATE))
    count = min(int(length * RATE), len(buffer) - first)
    base = frequency(midi)
    for i in range(count):
        t = i / RATE
        if kind == "pad":
            attack = min(1.0, t / 0.32)
            release = min(1.0, max(0.0, (length - t) / 0.48))
            envelope = attack * release
            tone = math.sin(2 * math.pi * base * t)
            tone += 0.16 * math.sin(2 * math.pi * base * 2.0 * t)
        else:
            envelope = (1 - math.exp(-t * 85)) * math.exp(-t * 2.15)
            tone = 0.78 * math.sin(2 * math.pi * base * t)
            tone += 0.17 * math.sin(2 * math.pi * base * 2.01 * t)
            tone += 0.05 * math.sin(2 * math.pi * base * 3.98 * t)
        buffer[first + i] += level * envelope * tone


def write_track(path, buffer, seconds):
    # Leave both ends at near-zero amplitude so the looping seam is unobtrusive.
    edge = int(0.18 * RATE)
    for i in range(min(edge, len(buffer))):
        buffer[i] *= i / edge
        buffer[-1 - i] *= i / edge
    peak = max(abs(sample) for sample in buffer) or 1.0
    gain = min(0.82 / peak, 1.0)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        frames = bytearray()
        for sample in buffer:
            value = max(-1.0, min(1.0, sample * gain))
            frames.extend(struct.pack("<h", int(value * 32767)))
        out.writeframes(frames)


def home_track():
    beat = 60.0 / HOME_BPM
    bar = beat * 4
    chords = [
        (53, 57, 60),  # F
        (52, 55, 60),  # C/E
        (50, 53, 57),  # Dm
        (46, 50, 53),  # Bb
        (53, 57, 60),  # F
        (48, 52, 55),  # C
        (45, 48, 52),  # Am
        (48, 52, 55),  # C, returning gently to F
    ]
    melody = [
        72, 77, 76, 72, 72, 76, 74, 72,
        69, 74, 72, 69, 70, 74, 72, 70,
        72, 77, 76, 72, 67, 72, 76, 74,
        69, 72, 76, 72, 74, 72, 69, 72,
    ]
    seconds = bar * len(chords)
    audio = [0.0] * int(seconds * RATE)
    for b, chord in enumerate(chords):
        start = b * bar
        for note in chord:
            add_note(audio, start, bar, note, 0.012, "pad")
        arp = (chord[0] + 12, chord[2] + 12, chord[1] + 12, chord[2] + 12)
        for beat_index, note in enumerate(arp):
            add_note(audio, start + beat_index * beat, 1.05, note, 0.038)
        for beat_index in range(4):
            add_note(
                audio,
                start + beat_index * beat + 0.06,
                1.35,
                melody[b * 4 + beat_index],
                0.052,
            )
    return audio, seconds


def puzzle_track():
    beat = 60.0 / PUZZLE_BPM
    bar = beat * 4
    chords = [
        (48, 52, 55),  # C
        (45, 48, 52),  # Am
        (41, 45, 48),  # F
        (43, 47, 50),  # G
        (48, 52, 55),
        (45, 48, 52),
        (41, 45, 48),
        (43, 47, 50),
    ]
    melody = [72, 76, 74, 71, 72, 69, 67, 71] * 2
    seconds = bar * len(chords)
    audio = [0.0] * int(seconds * RATE)
    for b, chord in enumerate(chords):
        start = b * bar
        for note in chord:
            add_note(audio, start, bar, note, 0.007, "pad")
        for beat_index in (0, 2):
            add_note(
                audio,
                start + beat_index * beat + 0.05,
                1.65,
                melody[b * 2 + beat_index // 2],
                0.026,
            )
    return audio, seconds


if __name__ == "__main__":
    root = os.path.join(os.path.dirname(__file__), "..", "assets", "music")
    audio, duration = home_track()
    write_track(os.path.join(root, "home_loop.wav"), audio, duration)
    audio, duration = puzzle_track()
    write_track(os.path.join(root, "puzzle_loop.wav"), audio, duration)
