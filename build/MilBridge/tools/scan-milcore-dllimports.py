#!/usr/bin/env python3
# T1 / MilBridge：扫描上游托管层全部 [DllImport(DllImport.MilCore)] 声明，
# 产出结构化清单（导出名 / 方法名 / 宿主文件 / PreserveSig / 参数与返回类型原文）。
#
# 只读 upstream/，不写任何上游文件。
#
# 用法：python3 build/MilBridge/tools/scan-milcore-dllimports.py [--json 输出路径]

import json
import os
import re
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
UP = os.path.join(REPO, "upstream", "wpf", "src", "Microsoft.DotNet.Wpf", "src")

# 扫描集合：M7a 固化的 8 个 in-tree 文件 + Common/Graphics 2 个
FILES = [
    "PresentationCore/System/Windows/Media/UnsafeNativeMethodsMilCoreApi.cs",
    "PresentationCore/System/Windows/Media/SafeNativeMethodsMilCoreApi.cs",
    "PresentationCore/System/Windows/Media/Composition.cs",
    "PresentationCore/System/Windows/Media/MILUtilities.cs",
    "PresentationCore/System/Windows/Media/MediaContextNotificationWindow.cs",
    "PresentationCore/System/Windows/InterOp/HwndTarget.cs",
    "PresentationCore/System/Windows/Media/StreamAsIStream.cs",
    "PresentationCore/System/Windows/Media/EventProxy.cs",
    "Common/Graphics/exports.cs",
    "Common/Graphics/wgx_exports.cs",
]


def strip_comments(text):
    """剥掉块注释与行注释；顺带记录每行是否落在注释里（用于定位属性行）。"""
    out = []
    i = 0
    n = len(text)
    in_block = False
    in_line = False
    in_str = False
    while i < n:
        c = text[i]
        nxt = text[i + 1] if i + 1 < n else ""
        if in_line:
            if c == "\n":
                in_line = False
                out.append("\n")
            else:
                out.append(" ")
            i += 1
            continue
        if in_block:
            if c == "*" and nxt == "/":
                in_block = False
                out.append("  ")
                i += 2
                continue
            out.append("\n" if c == "\n" else " ")
            i += 1
            continue
        if in_str:
            out.append(c)
            if c == "\\":
                if nxt:
                    out.append(nxt)
                    i += 2
                    continue
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == "/" and nxt == "*":
            in_block = True
            out.append("  ")
            i += 2
            continue
        if c == "/" and nxt == "/":
            in_line = True
            out.append("  ")
            i += 2
            continue
        if c == '"':
            in_str = True
        out.append(c)
        i += 1
    return "".join(out)


ATTR_RE = re.compile(
    r"\[DllImport\s*\(\s*DllImport\.MilCore\s*(?P<args>[^\]]*)\)\s*\]",
    re.S,
)
DECL_RE = re.compile(
    r"(?P<mods>(?:\b(?:internal|public|private|protected|static|extern|unsafe|partial)\b\s*)*)"
    r"(?P<ret>[A-Za-z_][\w\.\<\>\*\?\[\]]*)\s+"
    r"(?P<name>[A-Za-z_]\w*)\s*"
    # 参数表按"到第一个分号为止"取：里面有 [MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 2)]
    # 这种带括号的属性，用 [^;{)]* 会提前截断（StreamAsIStream.cs:666 就是这样漏掉的）。
    r"\((?P<params>[^;]*)\)\s*;",
    re.S,
)


def parse(path):
    full = os.path.join(UP, path)
    with open(full, "r", encoding="utf-8-sig") as f:
        raw = f.read()
    text = strip_comments(raw)
    entries = []
    for m in ATTR_RE.finditer(text):
        args = m.group("args")
        entry_point = None
        preserve_sig = None
        ep = re.search(r'EntryPoint\s*=\s*"([^"]+)"', args)
        if ep:
            entry_point = ep.group(1)
        ps = re.search(r"PreserveSig\s*=\s*(true|false)", args)
        if ps:
            preserve_sig = ps.group(1) == "true"
        # 声明紧随其后
        tail = text[m.end():m.end() + 1200]
        d = DECL_RE.search(tail)
        if not d:
            entries.append({
                "file": path, "entry_point_declared": entry_point,
                "error": "decl not parsed",
            })
            continue
        name = d.group("name")
        params_raw = " ".join(d.group("params").split())
        entries.append({
            "file": path,
            "method": name,
            "entry_point": entry_point or name,
            "entry_point_declared": entry_point,
            "preserve_sig": preserve_sig if preserve_sig is not None else True,
            "return": d.group("ret"),
            "params_raw": params_raw,
        })
    return entries


def main():
    all_entries = []
    for p in FILES:
        all_entries.extend(parse(p))

    by_name = {}
    for e in all_entries:
        by_name.setdefault(e.get("entry_point", "?"), []).append(e)

    print(f"属性条数: {len(all_entries)}")
    print(f"去重导出名: {len(by_name)}")
    print(f"方法名: {len(set(e.get('method') for e in all_entries))}")
    print()
    print("按文件:")
    counts = {}
    for e in all_entries:
        counts[e["file"]] = counts.get(e["file"], 0) + 1
    for k in FILES:
        print(f"  {counts.get(k, 0):3d}  {k}")
    print()
    print("PreserveSig=false 的条目:")
    for e in all_entries:
        if not e.get("preserve_sig", True):
            print(f"  {e['entry_point']:55s} -> {e['return']} {e['method']}({e['params_raw']})")
    print()
    print("返回类型分布:")
    rc = {}
    for e in all_entries:
        rc[e.get("return")] = rc.get(e.get("return"), 0) + 1
    for k, v in sorted(rc.items(), key=lambda kv: -kv[1]):
        print(f"  {v:3d}  {k}")
    print()
    print("重名（同一导出名多个声明）:")
    for k, v in sorted(by_name.items()):
        if len(v) > 1:
            print(f"  {k}: " + ", ".join(f"{x['file'].split('/')[-1]}.{x['method']}" for x in v))

    out = os.environ.get("MB_JSON")
    if out:
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with open(out, "w", encoding="utf-8") as f:
            json.dump({"entries": all_entries, "by_entry_point": by_name}, f,
                      ensure_ascii=False, indent=1)
        print(f"\nJSON 已写: {out}")


if __name__ == "__main__":
    main()
