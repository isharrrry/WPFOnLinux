#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成"派生 UI 字体"：剥离 OpenType 布局表的 Noto Sans（供 WPF 默认 UI 字体使用）。

    python3 build/gen-ui-font.py                    # 默认：build/fonts/NotoSans-Regular.ttf → build/fonts/UI-NoLayout.ttf
    python3 build/gen-ui-font.py --check            # 只校验已存在的产物（不重新生成）
    python3 build/gen-ui-font.py --src X --dst Y    # 自定义输入/输出

============================================================================
为什么剥掉 GSUB / GPOS（**这不是"绕过闸门"，是让能力与假设一致**）
============================================================================
WPF 的 `Typeface.CheckFastPathNominalGlyphs`（PresentationCore/System/Windows/Media/Typeface.cs:520-562）
在"全是 fast-text 字符"时会读 `FontFaceLayoutInfo.TypographyAvailabilities`：

    if ((typography & (FastTextTypographyAvailable | FastTextMajorLanguageLocalizedFormAvailable)) != 0)
        return false;                       // ← 闸门 2：拒掉名义字形快路径

而 `FastTextTypographyAvailable` 的算法（FontFaceLayoutInfo.cs:387-545）是：
用 `{ccmp,rlig,liga,clig,calt,kern,mark,mkmk}` 去查 GSUB/GPOS，只要其中一个特性的 lookups
**覆盖到 fast-text 字形范围**就置位。Noto Sans 真的带 `ccmp`/`liga`（GSUB）与
`kern`/`mark`/`mkmk`（GPOS），覆盖区间与 Latin 字形相交 —— 所以该位是**测出来的事实**，
不是解析 bug（详见 build/DirectWrite.Linux/REPORT.md §10）。

快路径被拒 ⇒ 落到 LineServices 复杂路径；而 Linux 侧那 110 条 `Lo*/Fs*/Nl*` 未实现
（独立里程碑）⇒ `TextBlock` 会异常退出。于是两条路：

  · 实现 shaping/LineServices（正解，本轮不做）；
  · 或让**默认 UI 字体**不再带这些布局特性 —— 即本脚本。

**为什么这是诚实的**：fast path 的语义本来就是**名义字形** ——
不做 kerning、不做连字、不做 locl 替换。把 GSUB/GPOS 去掉并不会让渲染比快路径**更**差，
它恰恰等于快路径会画出来的东西。剥离后掩码为 0 是**用 PC 的真实代码测出来的**（REPORT.md §10.7），
不是把算法改成 0 骗闸门。

**不动的东西**：`glyf`/`loca`/`hmtx`/`cmap`/`head`/`hhea`/`OS/2`/`post`/`name`/`maxp` 一个字节不变
⇒ 字形 id、轮廓、步进、度量、码点映射**逐项不变**（Tests/TypographyGateTests.cs 有逐项断言）。
`build/fonts/NotoSans-{Regular,Bold,Italic,BoldItalic}.ttf` 四个 golden 基准字体**绝不改动**。
"""

import argparse
import hashlib
import os
import struct
import sys

# 要剥离的表（OpenType 布局表的全部：GSUB / GPOS；GDEF 也剥掉更干净，但它不影响掩码）
DEFAULT_STRIP = ("GSUB", "GPOS")

# verify-env.sh:104 用 `find ... -name 'NotoSans-*.ttf'` 数"打包测试字体"，期望正好 4 个。
# 所以派生件的名字**必须避开该通配符**（否则会破坏那项校验）。
DEFAULT_DST_NAME = "UI-NoLayout.ttf"

# ⚠ **输出目录不是 build/fonts/，而是它旁边的 build/fonts-ui/** —— 这是实测后的决定：
#   把派生件放进 build/fonts/ 会让**同族同字重**的它遮蔽基准字体 NotoSans-Regular：
#     · M1 的 FontSet / 本工程的 LinuxFontCollection 按 (族名, 字重, 斜体) 索引，
#       后加载者覆盖先加载者 ⇒ "Noto Sans 400 upright" 解析到派生件而不是基准件；
#     · 仓库既有断言（4 个打包字体、golden 基准）随即失败（T2 实测 6 条红）。
#   所以派生件独立成目录：基准资产目录保持"正好 4 个文件"不变。
DEFAULT_DST_DIR = "fonts-ui"


# ---------------------------------------------------------------------------
#  纯 Python 的 SFNT 读写（不依赖任何第三方库，任何人 clone 下来就能跑）
# ---------------------------------------------------------------------------

def read_tables(data):
    tag = data[0:4]
    if tag == b"ttcf":
        raise SystemExit("[失败] 输入是 TTC（字体集合）：本脚本只处理单面 SFNT")

    num_tables = struct.unpack(">H", data[4:6])[0]
    tables = []
    for i in range(num_tables):
        rec = 12 + i * 16
        t, checksum, offset, length = struct.unpack(">4sIII", data[rec:rec + 16])
        if offset + length > len(data):
            raise SystemExit(f"[失败] 表 {t!r} 越界（offset={offset} length={length} size={len(data)}）")
        tables.append((t.decode("latin-1"), data[offset:offset + length]))
    return tag, tables


def table_checksum(blob, zero_from=None):
    """OpenType 规范：按 4 字节大端累加，尾部补零；head 表的 checkSumAdjustment 当 0 算。"""
    padded = blob + b"\0" * ((4 - len(blob) % 4) % 4)
    total = 0
    for i in range(0, len(padded), 4):
        word = struct.unpack(">I", padded[i:i + 4])[0]
        if zero_from is not None and i == zero_from:
            word = 0
        total = (total + word) & 0xFFFFFFFF
    return total


def build_sfnt(version, tables):
    """按 tag 升序重建目录 + 数据（4 字节对齐），并重算 checksum 与 head.checkSumAdjustment。"""
    tables = sorted(tables, key=lambda kv: kv[0])
    count = len(tables)
    directory_size = 12 + count * 16

    offsets, total = [], directory_size
    for _, blob in tables:
        offsets.append(total)
        total += (len(blob) + 3) & ~3

    out = bytearray(total)

    entry_selector = max(0, count.bit_length() - 1)
    search_range = 16 * (1 << entry_selector)

    struct.pack_into(">4sHHHH", out, 0, version, count, search_range, entry_selector,
                     count * 16 - search_range)

    for i, (tag, blob) in enumerate(tables):
        out[offsets[i]:offsets[i] + len(blob)] = blob

    head_offset = None
    for i, (tag, blob) in enumerate(tables):
        rec = 12 + i * 16
        if tag == "head":
            head_offset = offsets[i]
        checksum = table_checksum(out[offsets[i]:offsets[i] + len(blob)],
                                  zero_from=8 if tag == "head" else None)
        struct.pack_into(">4sIII", out, rec, tag.encode("latin-1"), checksum,
                         offsets[i], len(blob))

    if head_offset is not None:
        struct.pack_into(">I", out, head_offset + 8, 0)
        adjustment = (0xB1B0AFBA - table_checksum(bytes(out))) & 0xFFFFFFFF
        struct.pack_into(">I", out, head_offset + 8, adjustment)

    return bytes(out)


def sha256(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def summarize(path, label):
    data = open(path, "rb").read()
    _, tables = read_tables(data)
    units_per_em = struct.unpack(">H", dict(tables)["head"][18:20])[0]
    num_glyphs = struct.unpack(">H", dict(tables)["maxp"][4:6])[0]
    print(f"  {label}: {os.path.relpath(path)}  {len(data)} 字节  sha256={sha256(path)}")
    print(f"     表({len(tables)}): {','.join(t for t, _ in tables)}")
    print(f"     upem={units_per_em} numGlyphs={num_glyphs}")
    return data


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    default_src = os.path.join(here, "fonts", "NotoSans-Regular.ttf")
    default_dst = os.path.join(here, DEFAULT_DST_DIR, DEFAULT_DST_NAME)

    ap = argparse.ArgumentParser(description="剥离 OpenType 布局表，生成派生 UI 字体")
    ap.add_argument("--src", default=default_src)
    ap.add_argument("--dst", default=default_dst)
    ap.add_argument("--strip", default=",".join(DEFAULT_STRIP))
    ap.add_argument("--check", action="store_true", help="只校验已存在的产物")
    args = ap.parse_args()

    strip = tuple(t.strip() for t in args.strip.split(",") if t.strip())

    if args.check:
        if not os.path.exists(args.dst):
            print(f"[失败] 产物不存在：{args.dst}（先跑不带 --check 的生成）")
            return 1
        print("[校验] 产物：")
        got = summarize(args.dst, "派生件")
        _, tables = read_tables(got)
        present = {t for t, _ in tables}
        bad = [t for t in strip if t in present]
        if bad:
            print(f"[失败] 产物里仍有被剥离的表：{bad}")
            return 1
        print(f"[OK] 已剥离 {strip}；其余表原样保留")
        return 0

    if not os.path.exists(args.src):
        print(f"[失败] 找不到输入字体：{args.src}")
        return 1

    print(f"[输入] {args.src}")
    src = summarize(args.src, "原始件")[0:0] or None  # 仅为打印；下面重新读
    original = open(args.src, "rb").read()
    version, tables = read_tables(original)

    kept, dropped = [], []
    for tag, blob in tables:
        (dropped if tag in strip else kept).append((tag, blob))

    missing = [t for t in strip if t not in {t for t, _ in tables}]
    print(f"[剥离] 去掉 {[t for t, _ in dropped] or '（无）'}"
          + (f"；输入里本来就没有：{missing}" if missing else ""))

    derived = build_sfnt(version, kept)

    # 自校验：重读一遍，确认结构合法 + 关键表长度一致
    _, rebuilt = read_tables(derived)
    rebuilt_map = dict(rebuilt)
    original_map = dict(tables)
    def comparable(tag, blob):
        # head 的 checkSumAdjustment（偏移 8..12）按规范必须重算 —— 那是**唯一**允许变的 4 个字节
        return blob[:8] + b"\0\0\0\0" + blob[12:] if tag == "head" else blob

    for tag in ("head", "hhea", "hmtx", "cmap", "glyf", "loca", "maxp", "name", "OS/2", "post"):
        if tag in original_map and tag in rebuilt_map:
            if comparable(tag, original_map[tag]) != comparable(tag, rebuilt_map[tag]):
                print(f"[失败] 自查不通过：表 {tag} 的字节被改动了（head 只允许 checkSumAdjustment 变）")
                return 1

    os.makedirs(os.path.dirname(args.dst), exist_ok=True)
    with open(args.dst, "wb") as f:
        f.write(derived)

    print("[输出]")
    summarize(args.dst, "派生件")
    print()
    print("[下一步（由主控执行）]")
    print(f"  1) 产物在 build/fonts-ui/（独立目录）⇒ **不需要**动 build/fonts/SHA256SUMS。")
    print(f"     若将来要把它纳入独立校验，可在 build/fonts-ui/SHA256SUMS 里写一行：")
    print(f"     {sha256(args.dst)}  {os.path.basename(args.dst)}")
    print(f"  2) 让默认 UI 字体指向它：WPF_LINUX_UI_FONT={os.path.basename(args.dst)}"
          f"（该环境变量的取值见 M7b 的 SPI 实现）")
    print(f"  3) 注意两点：**不要**改名成 NotoSans-*.ttf（verify-env.sh:104 用该通配符数")
    print(f"     '打包测试字体'并期望正好 4 个）；也**不要**放进 build/fonts/ ——")
    print(f"     同族同字重的派生件会遮蔽基准件（M1 FontSet 的索引会被后加载者覆盖）。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
