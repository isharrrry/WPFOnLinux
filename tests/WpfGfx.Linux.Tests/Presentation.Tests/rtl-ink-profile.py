#!/usr/bin/env python3
"""RTL 墨迹包络 / 列轮廓（**不用精确色计数**）—— 2026-09-13 主控派的"纯 RTL 干净读数"工具

用法：
    rtl-ink-profile.py <帧.png> <crop: WxH+X+Y> [--out <数据文件>]

方法（对每一行文本）：
  1. 用 ImageMagick `txt:` 把裁剪区逐像素读进来（**原始分辨率，不缩放**）；
  2. **底色** = 裁剪区里出现次数最多的颜色；
  3. **墨迹** = 与底色的欧氏距离 > 阈值（默认 40）的像素 —— 不依赖"是否恰好等于测试色"，
     因此**对镜像 CTM 下的抗锯齿产物免疫**（这正是上一轮 23px vs 58px 那次的教训）；
  4. 按 y 聚成"行"（连续的有墨迹行，隙 ≥2 行算换行）；
  5. 每行给出：墨迹包络 `[x_min,x_max]` 与宽度、逐列轮廓（每列墨迹计数）、
     并按"墨迹指向哪个测试色"给该行贴一个颜色标签（用于把包络对到具体那一行文本）。

判据（主控写死的三选一）在调用方（runner/人）按 `RTL ≈ flop(LTR)` / `RTL ≈ LTR` / 都不是 判。
"""
import subprocess
import sys
import os
import json
from collections import Counter


def load_pixels(png, crop):
    out = subprocess.run(["convert", png, "-crop", crop, "+repage", "txt:-"],
                         capture_output=True, text=True).stdout
    px = {}
    for line in out.splitlines():
        if line.startswith("#") or ":" not in line:
            continue
        coord, rest = line.split(":", 1)
        try:
            x, y = (int(v) for v in coord.split(","))
        except ValueError:
            continue
        hexcol = None
        for tok in rest.replace("(", " ").replace(")", " ").split():
            if tok.startswith("#") and len(tok) >= 7:
                hexcol = tok[1:7]
                break
        if not hexcol:
            continue
        px[(x, y)] = (int(hexcol[0:2], 16), int(hexcol[2:4], 16), int(hexcol[4:6], 16))
    return px


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    png, crop = sys.argv[1], sys.argv[2]
    outfile = None
    if "--out" in sys.argv:
        outfile = sys.argv[sys.argv.index("--out") + 1]
    px = load_pixels(png, crop)
    if not px:
        print("no pixels", file=sys.stderr)
        return 1
    bg, bgn = Counter(px.values()).most_common(1)[0]
    xs = [p[0] for p in px]
    ys = [p[1] for p in px]
    W = max(xs) + 1
    H = max(ys) + 1

    def dist(c):
        return sum((a - b) ** 2 for a, b in zip(c, bg)) ** 0.5

    ink = {p: c for p, c in px.items() if dist(c) > 40}
    rows = sorted({p[1] for p in ink})
    lines, cur = [], []
    for y in rows:
        if cur and y - cur[-1] > 2:
            lines.append(cur)
            cur = []
        cur.append(y)
    if cur:
        lines.append(cur)

    TEST = {"FF2D95": (255, 45, 149), "00E5FF": (0, 229, 255), "ADFF2F": (173, 255, 47),
            "C084FC": (192, 132, 252), "00FF7F": (0, 255, 127), "A855F7": (168, 85, 247),
            "9FB4D0": (159, 180, 208), "E9F1FF": (233, 241, 255)}
    report = {"frame": png, "crop": crop, "crop_size": f"{W}x{H}", "background": "#%02X%02X%02X" % bg,
              "ink_threshold_dist": 40, "lines": []}

    for idx, yb in enumerate(lines):
        cols = {}
        dirs = Counter()
        for (x, y), c in ink.items():
            if y in yb:
                cols[x] = cols.get(x, 0) + 1
                # 该像素"指向哪个测试色"：取底色→测试色方向上的最近者
                v = tuple(c[i] - bg[i] for i in range(3))
                best, bestd = None, None
                for name, tc in TEST.items():
                    d = tuple(tc[i] - bg[i] for i in range(3))
                    n1 = sum(a * a for a in v) ** 0.5
                    n2 = sum(a * a for a in d) ** 0.5
                    if n1 == 0 or n2 == 0:
                        continue
                    cos = sum(v[i] * d[i] for i in range(3)) / (n1 * n2)
                    if bestd is None or cos > bestd:
                        best, bestd = name, cos
                dirs[best] += 1
        if not cols:
            continue
        x0, x1 = min(cols), max(cols)
        prof = [cols.get(x, 0) for x in range(x0, x1 + 1)]
        # 8 列合并直方图 + 首末各 16 列原始值
        binned = [sum(prof[i:i + 8]) for i in range(0, len(prof), 8)]
        report["lines"].append({
            "line_index": idx,
            "y_range": [min(yb), max(yb)],
            "colour_label": dirs.most_common(1)[0][0],
            "envelope_x": [x0, x1],
            "width_px": x1 - x0 + 1,
            "ink_px": sum(prof),
            "profile_binned8": binned,
            "profile_first16": prof[:16],
            "profile_last16": prof[-16:],
        })

    txt = json.dumps(report, ensure_ascii=False, indent=1)
    print(txt)
    if outfile:
        os.makedirs(os.path.dirname(outfile), exist_ok=True)
        with open(outfile, "w", encoding="utf-8") as f:
            f.write(txt + "\n")
        print(f"\n[written] {outfile}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
