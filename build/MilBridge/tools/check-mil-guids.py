#!/usr/bin/env python3
# T1/M7c6 —— **GUID 漂移检查**：本工程里的 MIL GUID 常量必须与上游 PC 的源码逐字一致。
#
# 【为什么需要它】
#   `MILQueryInterface` 要认 `IID_IWICBitmapSource`。那个 GUID 的权威定义是
#   PresentationCore 里的 `MILGuidData.IID_IWICBitmapSource`
#   （`internal static readonly Guid`），**WpfGfx.Linux 在编译期拿不到它**：
#     · 引用 PresentationCore 会把整个 PC 拉进 AOT 镜像 —— 绝不可行；
#     · AOT 运行时里也没有 PC 可反射（镜像里只有 WpfGfx.Linux）。
#   所以在 `MilNative.Misc.cs` 里**逐字抄写**了一份。本脚本把这个"抄写"变成
#   **机械核对**：上游一改，这里立刻红。比"手抄一份没人管"可靠，
#   又不必为此在上游只读树上加生成步骤（也不会往 src/ 里塞生成文件）。
#
# 用法：python3 build/MilBridge/tools/check-mil-guids.py
# 退出码：0 = 一致；1 = 漂移（会打印两侧的值）

import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))

# 权威来源（两份副本必须一致）
UPSTREAM_SOURCES = [
    "upstream/wpf/src/Microsoft.DotNet.Wpf/src/Common/Graphics/wgx_exports.cs",
    "upstream/wpf/src/Microsoft.DotNet.Wpf/src/WpfGfx/include/wgx_exports.cs",
]

# 我们的抄写处
OUR_SOURCE = "src/WpfGfx.Linux/Interop/MilNative.Misc.cs"

# PC 里 IWICBitmapSource 的 [Guid(...)] 特性（第三处独立证据）
PC_BITMAPSOURCE = ("upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/"
                   "System/Windows/Media/Imaging/BitmapSource.cs")

NAME = "IID_IWICBitmapSource"

# upstream:  internal static readonly Guid IID_IWICBitmapSource = new Guid(0x00000120, 0xa8f2, 0x4877, 0xba, 0x0a, 0xfd, 0x2b, 0x66, 0x45, 0xfb, 0x94);
UPSTREAM_RE = re.compile(
    r"static\s+readonly\s+Guid\s+" + NAME +
    r"\s*=\s*new\s+Guid\(\s*(0x[0-9a-fA-F]+)\s*,\s*(0x[0-9a-fA-F]+)\s*,\s*(0x[0-9a-fA-F]+)\s*,"
    r"\s*(0x[0-9a-fA-F]+)\s*,\s*(0x[0-9a-fA-F]+)\s*,\s*(0x[0-9a-fA-F]+)\s*,\s*(0x[0-9a-fA-F]+)\s*,"
    r"\s*(0x[0-9a-fA-F]+)\s*,\s*(0x[0-9a-fA-F]+)\s*,\s*(0x[0-9a-fA-F]+)\s*,\s*(0x[0-9a-fA-F]+)\s*\)")

# ours: 同形，但前面是 public static readonly
OURS_RE = UPSTREAM_RE

PC_GUID_RE = re.compile(r'Guid\("([0-9a-fA-F\-]{36})"\)')


def guid_of(nums):
    a, b, c = nums[0], nums[1], nums[2]
    d = "".join("%02X" % n for n in nums[3:])
    return "%08X-%04X-%04X-%s-%s" % (a, b, c, d[:4], d[4:])


def parse_static_guid(path, regex):
    full = os.path.join(REPO, path)
    if not os.path.exists(full):
        return None, "文件不存在: " + path
    text = open(full, encoding="utf-8-sig").read()
    m = regex.search(text)
    if not m:
        return None, "在 %s 里找不到 %s 的 new Guid(...) 字面量" % (path, NAME)
    nums = [int(g, 16) for g in m.groups()]
    return guid_of(nums), None


def main():
    ok = True

    ours, err = parse_static_guid(OUR_SOURCE, OURS_RE)
    if err:
        print("[失败] " + err)
        return 1
    print("本工程   %s = %s   (%s)" % (NAME, ours, OUR_SOURCE))

    for src in UPSTREAM_SOURCES:
        val, err = parse_static_guid(src, UPSTREAM_RE)
        if err:
            print("[失败] " + err)
            ok = False
            continue
        mark = "一致" if val == ours else "**漂移**"
        print("上游     %s = %s   (%s)  %s" % (NAME, val, src, mark))
        if val != ours:
            ok = False

    # 第三处独立证据：PC 里 IWICBitmapSource 接口的 [Guid("...")] 特性
    full = os.path.join(REPO, PC_BITMAPSOURCE)
    if os.path.exists(full):
        text = open(full, encoding="utf-8-sig").read()
        # 取 IWICBitmapSource 接口声明前面那个 Guid 特性
        idx = text.find("interface IWICBitmapSource")
        window = text[max(0, idx - 400):idx] if idx > 0 else ""
        m = None
        for m2 in PC_GUID_RE.finditer(window):
            m = m2
        if m:
            val = m.group(1).upper()
            mark = "一致" if val == ours else "**漂移**"
            print("PC       IWICBitmapSource [Guid]      = %s   (%s)  %s"
                  % (val, PC_BITMAPSOURCE, mark))
            if val != ours:
                ok = False
        else:
            print("[注意] 在 PC 的 BitmapSource.cs 里没找到 IWICBitmapSource 的 [Guid] 特性（跳过该项）")
    else:
        print("[注意] 找不到 %s（跳过该项）" % PC_BITMAPSOURCE)

    print()
    print("GUID 漂移检查：" + ("通过（三处一致）" if ok else "**失败**"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
