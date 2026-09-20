#!/usr/bin/env python3
"""从**样例源码**取出"块注册表"（唯一真值）—— 给 runner 做"块表 vs 注册表"断言用。

用法：
    probe-block-registry.py                # stdout: 每行一个块名（注册顺序）
    probe-block-registry.py --count        # stdout: 只打条目数
    probe-block-registry.py --json         # stdout: {"count":N,"names":[...]}

为什么需要它（L19 现场）：`run-wpfprobe.sh` 的 `BLOCKS` 名单曾经只有 10 个名字，而样例实际注册
**11** 块（漏了 `text-dp-min`）⇒ `--only=text-dp-min` 时那块**根本没进汇总**、全量趟里它真 FAIL
也**不会被看见**。这类"表/判据与实际对象漂移"在本项目已多次出现（L12、桥契约整行判 `[`）。
⇒ 现在把"注册表"当**直接测量**取出来，与 runner 的表比：**不一致就红，并指出缺哪个/多哪个**。

【本脚本的口径（唯一实现）】
  1. 注册表 = `samples/WpfFeatureProbe/MainWindow.xaml.cs` 里 `var all = new List<ProbeBlock> { … };`
     区块内的 `new XxxBlock()`，**按出现顺序**；
  2. 每个类名 → 它的块名：在 `samples/WpfFeatureProbe/FeatureBlocks.cs` 里找
     `class XxxBlock` 之后**同一个类体内**的 `Name => "…"`（用"下一个 class 声明"当类体边界，
     避免把兄弟类的 Name 张冠李戴）；
  3. 任一类找不到 Name ⇒ **非 0 退出并报错**（不静默跳过；"测试专用/未命名块"必须显式处理）。
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
MAIN = os.path.join(ROOT, "samples", "WpfFeatureProbe", "MainWindow.xaml.cs")
BLOCKS = os.path.join(ROOT, "samples", "WpfFeatureProbe", "FeatureBlocks.cs")


def registry_classes():
    src = open(MAIN, encoding="utf-8").read()
    m = re.search(r"var\s+all\s*=\s*new\s+List<ProbeBlock>\s*\{(.*?)\};", src, re.S)
    if not m:
        raise SystemExit("ERROR: 在 MainWindow.xaml.cs 里找不到 `var all = new List<ProbeBlock> { … };`")
    return re.findall(r"new\s+([A-Za-z_][A-Za-z0-9_]*Block)\s*\(", m.group(1))


def class_names():
    src = open(BLOCKS, encoding="utf-8").read()
    # 类声明位置（拿它当类体边界）
    decls = [(mm.start(), mm.group(1))
             for mm in re.finditer(r"class\s+([A-Za-z_][A-Za-z0-9_]*Block)\s*:", src)]
    out = {}
    for i, (pos, cls) in enumerate(decls):
        end = decls[i + 1][0] if i + 1 < len(decls) else len(src)
        body = src[pos:end]
        nm = re.search(r'Name\s*=>\s*"([^"]+)"', body)
        if nm:
            out[cls] = nm.group(1)
    return out


def main():
    cls_list = registry_classes()
    names_map = class_names()
    missing = [c for c in cls_list if c not in names_map]
    if missing:
        raise SystemExit(f"ERROR: 这些注册类在 FeatureBlocks.cs 里找不到 Name：{missing}")
    names = [names_map[c] for c in cls_list]
    if len(set(names)) != len(names):
        raise SystemExit(f"ERROR: 注册表里有重名块：{names}")
    if "--count" in sys.argv:
        print(len(names))
    elif "--json" in sys.argv:
        print(json.dumps({"count": len(names), "names": names}, ensure_ascii=False))
    else:
        print("\n".join(names))


if __name__ == "__main__":
    main()
