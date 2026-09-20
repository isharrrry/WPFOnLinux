#!/usr/bin/env python3
"""对比上游 Generated/wgx_commands.cs 与移植版 Commands/MilCommandStructs.cs 的 FieldOffset。

只做机械比对，不做任何人工判断：
  - 结构名（去掉 MILCMD_ 前缀后大写比较）
  - 每个字段的 FieldOffset 数值序列
  - 字段类型的字节宽度（按已知宽度表换算）

用法： python3 build/verify-cmd-layout.py
退出码 0 = 完全一致；1 = 有差异（差异打印到 stdout）。
"""
import os
import re
import sys
from pathlib import Path

# 路径推导：本脚本位于 <repo>/tests/WpfGfx.Linux.Tests/Commands.Tests/tools/，
# 仓库根 = 向上找到含 handoff.md 的目录；上游根优先读环境变量。
_SCRIPT = Path(__file__).resolve()
_REPO = next((p for p in _SCRIPT.parents if (p / "handoff.md").exists()), _SCRIPT.parents[4])
_UPSTREAM_ROOT = Path(os.environ.get("UPSTREAM_WPF_ROOT") or os.environ.get("UpstreamWpfRoot")
                      or (_REPO / "upstream" / "wpf"))
UPSTREAM = _UPSTREAM_ROOT / "src/Microsoft.DotNet.Wpf/src/Common/Graphics/Generated/wgx_commands.cs"
PORTED = _REPO / "src/WpfGfx.Linux/Commands/MilCommandStructs.cs"

# 字节宽度表。上游名 -> 宽度；移植名 -> 宽度。
WIDTH = {
    # 上游类型
    "MILCMD": 4, "BOOL": 4, "UInt64": 8, "UInt32": 4, "UInt16": 2, "int": 4,
    "double": 8, "float": 4,
    "DUCE.ResourceHandle": 4, "MilColorF": 16, "MilPoint2F": 8, "MilPoint3F": 12,
    "MilQuaternionF": 16, "MilMatrix3x2D": 48, "MilRenderOptions": 28,
    "Point": 16, "Rect": 32, "Size": 16, "D3DMATRIX": 64,
    "MS.Win32.NativeMethods.RECT": 16,
    "byte": 1,
    # 上游枚举（全部 4 字节）
    "MILWindowLayerType": 4, "MILTransparencyFlags": 4, "ShaderRenderMode": 4,
    "KernelType": 4, "RenderingBias": 4, "FillRule": 4, "GeometryCombineMode": 4,
    "ColorInterpolationMode": 4, "BrushMappingMode": 4, "GradientSpreadMethod": 4,
    "Stretch": 4, "TileMode": 4, "AlignmentX": 4, "AlignmentY": 4, "CachingHint": 4,
    "PenLineCap": 4, "PenLineJoin": 4, "EdgeMode": 4, "BitmapScalingMode": 4,
    "ClearTypeHint": 4,
    # 移植侧类型
    "uint": 4, "ulong": 8, "ushort": 2,
    "MilRectI": 16, "MilPoint": 16, "MilRect": 32, "MilSize": 16,
    "MilCmd": 4,
    # 上游 D3DMATRIX（16 × float = 64）在移植侧叫 MilMatrix4x4F，宽度必须同为 64。
    # 名字里的 D3D 是历史包袱：wgx_core_types.cs:963 里它就是纯数值矩阵，不含 COM 引用。
    "MilMatrix4x4F": 64,
    "MilWindowLayerType": 4, "MilTransparencyFlags": 4,
    "MilFillRule": 4, "MilGeometryCombineMode": 4, "MilColorInterpolationMode": 4,
    "MilBrushMappingMode": 4, "MilGradientSpreadMethod": 4, "MilStretch": 4,
    "MilTileMode": 4, "MilAlignmentX": 4, "MilAlignmentY": 4, "MilCachingHint": 4,
    "MilPenLineCap": 4, "MilPenLineJoin": 4, "MilEdgeMode": 4,
    "MilBitmapScalingMode": 4, "MilClearTypeHint": 4,
    "MilKernelType": 4, "MilRenderingBias": 4,
}

STRUCT_RE = re.compile(r"(?:internal|public)\s+struct\s+(MILCMD_\w+)")
FIELD_RE = re.compile(
    r"\[FieldOffset\((\d+)\)\]\s*(?:internal|public|private)\s+([\w\.]+)\s+(\w+)\s*;")


def parse(path):
    """返回 {结构名: [(offset, width, 字段名), ...]}。"""
    text = path.read_text()
    out, cur = {}, None
    for line in text.splitlines():
        m = STRUCT_RE.search(line)
        if m:
            cur = m.group(1)
            out[cur] = []
            continue
        m = FIELD_RE.search(line)
        if m and cur:
            off, typ, name = int(m.group(1)), m.group(2), m.group(3)
            if typ not in WIDTH:
                print(f"!! 未知类型宽度: {typ} （{cur}.{name}）")
                sys.exit(2)
            out[cur].append((off, WIDTH[typ], name))
    return out


def main():
    up, po = parse(UPSTREAM), parse(PORTED)
    problems = []

    missing = sorted(set(up) - set(po))
    extra = sorted(set(po) - set(up))

    for name in sorted(set(up) & set(po)):
        u, p = up[name], po[name]
        # 只比对 (offset, width) 序列；字段名允许大小写差异
        us = [(o, w) for o, w, _ in u]
        ps = [(o, w) for o, w, _ in p]
        if us != ps:
            problems.append((name, u, p))

    print(f"上游结构 {len(up)} 个，移植 {len(po)} 个，共有 {len(set(up) & set(po))} 个")
    print(f"移植侧缺失 {len(missing)} 个（M1 未实现的 3D/D3D 属预期）")
    if extra:
        print(f"移植侧多出（上游无）: {extra}")

    if problems:
        print(f"\n=== {len(problems)} 个结构布局不一致 ===")
        for name, u, p in problems:
            print(f"\n[{name}]")
            print(f"  上游: {[(o, w, n) for o, w, n in u]}")
            print(f"  移植: {[(o, w, n) for o, w, n in p]}")
    else:
        print("\n共有结构的 FieldOffset 与字段宽度全部一致 ✓")

    print(f"\n缺失清单: {missing}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
