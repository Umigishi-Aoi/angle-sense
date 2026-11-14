"""ピタッとアングルの効果音を合成して WAV で書き出す（標準ライブラリのみ）。

使い方:
    python3 tool/gen_sfx.py <出力フォルダ>

soft=ベル・チャイム系 / retro=ゲーム機の電子音系 / retro_reverb=retro に残響を足したもの（アプリで使う版）
の 3 系統 × 10 種類を出力する。
録音素材・フリー素材を使わず数式だけで作るので権利の問題がない。
"""

import math
import random
import struct
import sys
import wave
from pathlib import Path

SR = 44100  # サンプリング周波数
random.seed(7)  # ノイズを毎回同じにする（作り直しても同じ音になる）


def note(name: str) -> float:
    """'C6' などの音名 → 周波数。"""
    names = {'C': -9, 'C#': -8, 'D': -7, 'D#': -6, 'E': -5, 'F': -4, 'F#': -3,
             'G': -2, 'G#': -1, 'A': 0, 'A#': 1, 'B': 2}
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[pitch] + (octave - 4) * 12) / 12)


def silence(sec: float) -> list[float]:
    return [0.0] * int(SR * sec)


def env(i: int, n: int, attack: float, decay: float) -> float:
    """立ち上がり attack 秒、その後 decay の速さで指数的に減衰。最後の 5ms はフェードアウト。"""
    t = i / SR
    a = min(1.0, t / attack) if attack > 0 else 1.0
    d = math.exp(-t * decay)
    tail = min(1.0, (n - i) / (SR * 0.005))
    return a * d * tail


def bell(freq: float, sec: float, decay: float = 6.0, amp: float = 0.5) -> list[float]:
    """やわらかいベル: 基音＋わずかにずれた倍音。"""
    n = int(SR * sec)
    partials = [(1.0, 1.0), (2.0, 0.35), (3.01, 0.12), (4.2, 0.05)]
    out = []
    for i in range(n):
        t = i / SR
        s = sum(a * math.sin(2 * math.pi * freq * m * t) for m, a in partials)
        out.append(amp * s / 1.52 * env(i, n, 0.004, decay))
    return out


def square(freq: float, sec: float, decay: float = 8.0, amp: float = 0.35, duty_harmonics: int = 9) -> list[float]:
    """電子音: 奇数倍音を足した矩形波（倍音を有限にして耳に痛い折り返しを抑える）。"""
    n = int(SR * sec)
    out = []
    for i in range(n):
        t = i / SR
        s = sum(math.sin(2 * math.pi * freq * k * t) / k for k in range(1, duty_harmonics + 1, 2))
        out.append(amp * s * env(i, n, 0.002, decay))
    return out


def noise(sec: float, cutoff: float, decay: float, amp: float = 0.5) -> list[float]:
    """ローパスを通したノイズ（「フッ」「カチッ」の素材）。"""
    n = int(SR * sec)
    k = 1 - math.exp(-2 * math.pi * cutoff / SR)
    y = 0.0
    out = []
    for i in range(n):
        y += k * (random.uniform(-1, 1) - y)
        out.append(amp * y * env(i, n, 0.003, decay))
    return out


def sweep(f0: float, f1: float, sec: float, wave_fn: str = 'sine', decay: float = 4.0, amp: float = 0.4) -> list[float]:
    """周波数を f0→f1 に滑らせる。"""
    n = int(SR * sec)
    out = []
    phase = 0.0
    for i in range(n):
        f = f0 * (f1 / f0) ** (i / n)
        phase += 2 * math.pi * f / SR
        if wave_fn == 'sine':
            s = math.sin(phase)
        else:
            s = sum(math.sin(phase * k) / k for k in range(1, 8, 2))
        out.append(amp * s * env(i, n, 0.005, decay))
    return out


def mix(*tracks: tuple[float, list[float]]) -> list[float]:
    """(開始秒, 波形) を重ねる。"""
    length = max(int(SR * start) + len(t) for start, t in tracks)
    out = [0.0] * length
    for start, t in tracks:
        o = int(SR * start)
        for i, v in enumerate(t):
            out[o + i] += v
    return out


def seq(notes: list[str], gap: float, fn, sec: float, **kw) -> list[float]:
    return mix(*[(i * gap, fn(note(n), sec, **kw)) for i, n in enumerate(notes)])


def reverb(dry: list[float], wet: float = 0.25, room: float = 0.72, damp: float = 0.35,
           tail: float = 0.9, predelay: float = 0.015) -> list[float]:
    """簡易リバーブ（Schroeder/Freeverb 型: 並列コム4本＋直列オールパス2本）。

    wet=残響の量、room=響きの長さ（コムの帰還量）、damp=高音の減衰（大きいほどこもる）、
    tail=元の音の後ろに足す余韻の秒数。
    """
    n = len(dry) + int(SR * tail)
    x = dry + [0.0] * (n - len(dry))
    pd = int(SR * predelay)
    x = [0.0] * pd + x[: n - pd]

    def comb(sig: list[float], d: int) -> list[float]:
        buf = [0.0] * d
        out = [0.0] * len(sig)
        idx = 0
        lp = 0.0
        for i, v in enumerate(sig):
            y = buf[idx]
            lp = y * (1 - damp) + lp * damp
            buf[idx] = v + lp * room
            idx = (idx + 1) % d
            out[i] = y
        return out

    def allpass(sig: list[float], d: int, g: float = 0.5) -> list[float]:
        buf = [0.0] * d
        out = [0.0] * len(sig)
        idx = 0
        for i, v in enumerate(sig):
            b = buf[idx]
            y = -v + b
            buf[idx] = v + b * g
            idx = (idx + 1) % d
            out[i] = y
        return out

    combs = [comb(x, d) for d in (1557, 1617, 1491, 1422)]
    r = [sum(c[i] for c in combs) / 4 for i in range(n)]
    for d in (556, 225):
        r = allpass(r, d)
    full_dry = dry + [0.0] * (n - len(dry))
    out = [full_dry[i] + wet * r[i] for i in range(n)]
    # 末尾 0.1 秒で滑らかに消す
    fade = int(SR * 0.1)
    for i in range(fade):
        out[n - fade + i] *= 1 - i / fade
    return out


def write(path: Path, samples: list[float]) -> None:
    peak = max(1e-9, max(abs(v) for v in samples))
    gain = min(1.0, 0.89 / peak)  # 約 -1dBFS を超えないように
    with wave.open(str(path), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, v * gain)) * 32767)) for v in samples))


def soft() -> dict[str, list[float]]:
    return {
        'countdown': bell(note('A5'), 0.25, decay=14),
        'blind_start': mix((0, noise(0.35, 900, 9, 0.6)), (0, sweep(330, 160, 0.35, decay=8, amp=0.25))),
        'tick': bell(note('E6'), 0.06, decay=60, amp=0.25),
        'lock': mix((0, noise(0.03, 6000, 120, 0.7)), (0, bell(note('C6'), 0.12, decay=35, amp=0.4))),
        'perfect': mix((0, seq(['C6', 'E6', 'G6'], 0.07, bell, 0.6, decay=5)), (0.21, bell(note('C7'), 0.9, decay=4, amp=0.35))),
        'great': seq(['E6', 'G6'], 0.08, bell, 0.6, decay=6),
        'good': bell(note('G5'), 0.5, decay=7),
        'miss': seq(['E5', 'C5'], 0.12, bell, 0.5, decay=8, amp=0.4),
        'rank': mix(*[(i * 0.03, bell(note(n), 1.4, decay=2.5, amp=0.3)) for i, n in enumerate(['C5', 'E5', 'G5', 'C6'])]),
        'best': mix(
            (0.00, bell(note('G5'), 0.18, decay=10)),
            (0.15, bell(note('G5'), 0.18, decay=10)),
            (0.30, bell(note('G5'), 0.18, decay=10)),
            (0.45, mix(*[(0, bell(note(n), 1.2, decay=2.5, amp=0.3)) for n in ['C6', 'E6', 'G6']])),
        ),
    }


def retro() -> dict[str, list[float]]:
    return {
        'countdown': square(note('A5'), 0.09, decay=10),
        'blind_start': sweep(440, 110, 0.3, wave_fn='square', decay=5, amp=0.3),
        'tick': square(note('C7'), 0.025, decay=80, amp=0.15),
        'lock': mix((0, noise(0.04, 8000, 90, 0.6)), (0, square(note('C5'), 0.05, decay=40, amp=0.3))),
        'perfect': mix((0, seq(['C6', 'E6', 'G6'], 0.06, square, 0.08, decay=12)), (0.18, square(note('C7'), 0.35, decay=6, amp=0.3))),
        'great': seq(['E6', 'G6'], 0.07, square, 0.12, decay=12),
        'good': square(note('G5'), 0.14, decay=12),
        'miss': sweep(330, 110, 0.35, wave_fn='square', decay=4, amp=0.3),
        'rank': seq(['C5', 'E5', 'G5', 'C6'], 0.08, square, 0.3, decay=6, amp=0.28),
        'best': mix(
            (0.00, square(note('G5'), 0.1, decay=15)),
            (0.12, square(note('G5'), 0.1, decay=15)),
            (0.24, square(note('G5'), 0.1, decay=15)),
            (0.36, square(note('C6'), 0.6, decay=3, amp=0.3)),
            (0.36, square(note('E6'), 0.6, decay=3, amp=0.2)),
        ),
    }


def main() -> None:
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    out = Path(sys.argv[1])
    r = retro()
    retro_reverb = {k: reverb(v, tail=0.4 if k in ('tick', 'countdown', 'lock') else 0.9)
                    for k, v in r.items()}
    for style, sounds in (('soft', soft()), ('retro', r), ('retro_reverb', retro_reverb)):
        d = out / style
        d.mkdir(parents=True, exist_ok=True)
        for name, samples in sounds.items():
            write(d / f'{name}.wav', samples)
            print(f'{d / name}.wav  {len(samples) / SR:.2f}s')


if __name__ == '__main__':
    main()
