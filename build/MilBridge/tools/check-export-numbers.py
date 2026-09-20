#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""T1b 「一个数字两个消费者」的牙（唯一真值来源 = gen/landing-table.md）。

    python3 build/MilBridge/tools/check-export-numbers.py [--self-test]

【为什么要这把牙】
  导出深度分布（Real / NotImpl / State / Identity）与导出总数（109）在**多处硬编码**：
    · build/MilBridge/gen/landing-table.md            ← **唯一真值来源**（gen-exports.py 从 MilNative.Exports.cs 生成）
    · build/MilBridge/tests/ClosedLoop/Program.cs      A3 `n == 109`、A5 `notimpl == 27`
    · tests/WpfGfx.Linux.Tests/Commands.Tests/MilExportTests.cs   Assert.Equal(61, real) / (9, identity) / (12, state) / (27, notImpl)
  历史上已经漂过一次：`notimpl == 28` 停在 #24 之前（真值 27），而 MilExportTests 早已是 27
  ⇒ 两边各自漂移。本脚本把"清单"和"消费者"摆在一起比，**不一致就红**。

【注意：不要用 `grep -c ExportDepth.NotImpl` 当口径】
  判定语句本身（`if (pair.Value == ExportDepth.NotImpl)`）也会被数进去 ⇒ 会多 1。
  这里数的是**清单条目**（landing-table.md 的行），不是代码行。

【真值怎么来的（可重算）】
  27 = 清单表里 MilNative 实现深度为 NotImpl 的行数
     = 4 个 InteropDeviceBitmap + 22 个 MILMedia + MilResource_SendCommandMedia（见 MilNative.Exports.cs）
  61 = Real 行数；12 = State；9 = Identity；四者之和 == 109 == gen/export-symbols.txt 行数。
"""

import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MB = os.path.normpath(os.path.join(HERE, ".."))
ROOT = os.path.normpath(os.path.join(MB, "..", ".."))
TABLE = os.path.join(MB, "gen", "landing-table.md")
SYMBOLS = os.path.join(MB, "gen", "export-symbols.txt")
CLOSED_LOOP = os.path.join(MB, "tests", "ClosedLoop", "Program.cs")
MIL_EXPORT_TESTS = os.path.join(ROOT, "tests", "WpfGfx.Linux.Tests", "Commands.Tests", "MilExportTests.cs")

DEPTHS = ("Real", "State", "NotImpl", "Identity")


def truth():
    """唯一真值来源：清单表 + 符号清单。"""
    with open(TABLE, encoding="utf-8") as f:
        lines = f.read().splitlines()
    rows = [l for l in lines if l.startswith("|") and not re.match(r"^\|[\s\-:|]+\|$", l)]
    header, body = rows[0], rows[1:]
    depth_count = {}
    for line in body:
        cells = [c.strip() for c in line.strip("|").split("|")]
        depth = cells[1].strip("`").strip()
        depth_count[depth] = depth_count.get(depth, 0) + 1
    with open(SYMBOLS, encoding="utf-8") as f:
        symbols = [l for l in f.read().splitlines() if l.strip()]

    return {
        "table_rows": len(body),
        "symbols": len(symbols),
        "depths": depth_count,
    }


def consumers():
    """各消费点硬编码的数字（正则取出来，改了就跟着变）。"""
    out = {}
    with open(CLOSED_LOOP, encoding="utf-8") as f:
        s = f.read()
    m = re.search(r"n == (\d+), \$\"got \{n\}\"", s)
    out["ClosedLoop.A3.total"] = int(m.group(1)) if m else None
    m = re.search(r"notimpl == (\d+), \$\"got \{notimpl\}\"", s)
    out["ClosedLoop.A5.notImpl"] = int(m.group(1)) if m else None

    with open(MIL_EXPORT_TESTS, encoding="utf-8") as f:
        t = f.read()
    for key, pattern in (("CommandsTests.real", r"Assert\.Equal\((\d+), real\)"),
                         ("CommandsTests.identity", r"Assert\.Equal\((\d+), identity\)"),
                         ("CommandsTests.state", r"Assert\.Equal\((\d+), state\)"),
                         ("CommandsTests.notImpl", r"Assert\.Equal\((\d+), notImpl\)")):
        m = re.search(pattern, t)
        out[key] = int(m.group(1)) if m else None
    return out


def compare(t, c):
    """返回 (问题列表, 说明列表)。"""
    problems, notes = [], []
    total = t["symbols"]
    notes.append(f"真值来源 {os.path.relpath(TABLE, ROOT)}：合计 {t['table_rows']} 行；"
                 f"{os.path.relpath(SYMBOLS, ROOT)}：{total} 个导出名")
    notes.append("深度分布（清单表实测）：" + "  ".join(f"{d}={t['depths'].get(d, 0)}" for d in DEPTHS))

    if t["table_rows"] != total:
        problems.append(f"清单表行数 {t['table_rows']} != 符号清单 {total}")

    s = sum(t["depths"].get(d, 0) for d in DEPTHS)
    if s != total:
        problems.append(f"四类深度之和 {s} != 导出总数 {total}")

    if c["ClosedLoop.A3.total"] != total:
        problems.append(f"ClosedLoop.A3 写的是 {c['ClosedLoop.A3.total']}，真值 {total}")
    if c["ClosedLoop.A5.notImpl"] != t["depths"].get("NotImpl", 0):
        problems.append(f"ClosedLoop.A5 写的是 {c['ClosedLoop.A5.notImpl']}，真值 {t['depths'].get('NotImpl', 0)}")

    for key, depth in (("CommandsTests.real", "Real"), ("CommandsTests.identity", "Identity"),
                       ("CommandsTests.state", "State"), ("CommandsTests.notImpl", "NotImpl")):
        want = t["depths"].get(depth, 0)
        if c[key] != want:
            problems.append(f"{key} 写的是 {c[key]}，真值 {want}")

    csum = (c["CommandsTests.real"] or 0) + (c["CommandsTests.identity"] or 0) \
         + (c["CommandsTests.state"] or 0) + (c["CommandsTests.notImpl"] or 0)
    if csum != total:
        problems.append(f"MilExportTests 四个断言之和 {csum} != 导出总数 {total}"
                        "（NotImpl→Real 这类改动必须成对改，正是这条在拦）")
    else:
        notes.append(f"MilExportTests 四个断言之和 = {csum} == 导出总数 {total} ✅")
    return problems, notes


def self_test(t):
    """这把牙**能变红**的自检：把真值故意改错 ⇒ 必须报问题；改回 ⇒ 必须无问题。"""
    good = {"ClosedLoop.A3.total": t["symbols"], "ClosedLoop.A5.notImpl": t["depths"].get("NotImpl", 0),
            "CommandsTests.real": t["depths"].get("Real", 0),
            "CommandsTests.identity": t["depths"].get("Identity", 0),
            "CommandsTests.state": t["depths"].get("State", 0),
            "CommandsTests.notImpl": t["depths"].get("NotImpl", 0)}
    bad = dict(good)
    bad["ClosedLoop.A5.notImpl"] = good["ClosedLoop.A5.notImpl"] + 1     # 复现当年那个 stale 28
    p_bad, _ = compare(t, bad)
    p_good, _ = compare(t, good)
    ok = bool(p_bad) and not p_good
    print(("[自检] 牙能变红 ✅" if ok else "[自检] 牙**不能**变红 ❌")
          + f"：真值改错 ⇒ {len(p_bad)} 个问题（{p_bad[0] if p_bad else '-'}）；改回 ⇒ {len(p_good)} 个问题")
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--self-test", action="store_true", help="自检：证明这把牙能变红")
    args = ap.parse_args()

    t = truth()
    if args.self_test:
        return self_test(t)

    c = consumers()
    problems, notes = compare(t, c)
    for n in notes:
        print("  " + n)
    print("  消费点：ClosedLoop.A3.total=%s A5.notImpl=%s | CommandsTests real=%s identity=%s state=%s notImpl=%s"
          % (c["ClosedLoop.A3.total"], c["ClosedLoop.A5.notImpl"],
             c["CommandsTests.real"], c["CommandsTests.identity"], c["CommandsTests.state"], c["CommandsTests.notImpl"]))
    if problems:
        print("\n[红] 「一个数字两个消费者」不一致：")
        for p in problems:
            print("   ❌ " + p)
        return 1
    print("\n[绿] 清单表与所有消费点一致（唯一真值来源：gen/landing-table.md）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
