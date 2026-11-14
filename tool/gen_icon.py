"""アプリアイコン（ドット絵）を作り、iOS の AppIcon.appiconset の全サイズに書き出す。

絵柄: 答え合わせの図と同じ「横から見た折りたたみ」。左の面は平ら、右の面が持ち上がり、間に角度の弧。
使い方: python3 -I tool/gen_icon.py
"""
import json
import os

from PIL import Image

GRID = 16
BG = (0x14, 0x18, 0x2E)
COLORS = {
    "W": (0xE8, 0xE8, 0xF0),  # 平らな面
    "C": (0x4F, 0xD1, 0xC5),  # 持ち上がる面
    "Y": (0xF7, 0xC9, 0x48),  # 角度の弧
}

# 16x16 の手置きドット（. = 背景）
PIXELS = """
................
................
................
................
.............CC.
............CC..
...........CC...
..........CC....
.........CC.....
........CC..Y...
.......CC....Y..
..WWWWWC.....Y..
..WWWWWW........
................
................
................
"""

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONSET = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")


def draw():
    rows = [r for r in PIXELS.strip("\n").split("\n")]
    assert len(rows) == GRID and all(len(r) == GRID for r in rows)
    img = Image.new("RGB", (GRID, GRID), BG)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in COLORS:
                img.putpixel((x, y), COLORS[ch])
    return img


def main():
    small = draw()
    with open(os.path.join(ICONSET, "Contents.json"), encoding="utf-8") as f:
        contents = json.load(f)
    written = 0
    for entry in contents["images"]:
        name = entry.get("filename")
        if not name:
            continue
        base = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].rstrip("x"))
        size = int(round(base * scale))
        # 一度大きく（整数倍）してから縮めると、どのサイズでもドットが均等に近くなる。
        big = small.resize((GRID * 64, GRID * 64), Image.NEAREST)
        big.resize((size, size), Image.NEAREST).save(os.path.join(ICONSET, name))
        written += 1
    big = small.resize((1024, 1024), Image.NEAREST)
    big.save(os.path.join(ROOT, "tool", "icon_preview.png"))
    print(f"wrote {written} icons")


if __name__ == "__main__":
    main()
