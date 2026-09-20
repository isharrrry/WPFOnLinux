#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""T1b · 从 `feat-lines.txt` 里**按时间点**取"注入之后"的读数（修 `tail -1` 的时间点型假阳）。

    python3 build/MilBridge/tools/pick-feat-line.py --file F --after-line N --keys changes,text
        ⇒ 打印一行（TAB 分隔）： <status>\t<changes>\t<text>
           status = AFTER（取到了晚于注入的行） | NOINFO（没有晚于注入的行 ⇒ **无信息**）
    python3 build/MilBridge/tools/pick-feat-line.py --self-test
        ⇒ 牙：构造假日志证明"late 行早于 OK 行"时报 NOINFO、"晚于注入且陈旧"时报 AFTER+changes=0；**能变红**

【被证伪的旧口径（2026-09-13 主控/T1c 实测）】
  runner 原来用 `grep … "$OUT/feat-lines.txt" | tail -1` 取**最后一行**。
  但该文件里 `late:`（LateVerify，焦点/键入注入之前跑的）**可能排在 `OK`（Verify）之后**
  —— 样例的 `Loaded→BeginInvoke(ContextIdle, VerifyAll)` 被 ~10s 首帧拖后 ⇒ **`tail -1` 取到的是"注入之前"的读数**，
  再把它当成"注入之后"的结论 ⇒ 写出"**但可观测模型陈旧**：changes=0 ⇒ 读 Text 的真应用会静默拿旧值"。
  两条独立反证：同应用 `--only=text-dp-min` 趟本来就有写后读数（`t2='A' c2=1`）；装置 12 例在"写后读"下全绿。
  ⇒ 这是**时间点型假阳**：注入前的读数被当成注入后的结论。

【正确口径（本工具）】
  · 排序前提：`feat-lines.txt` 是**追加写**的（行号 = 写入时刻序），但**同一逻辑事件可能有 late/OK 两个变体**，
    因此"最后一行"**不等于**"注入之后那一行"。
  · 唯一可靠的下界 = **注入时刻的行号**（runner 在 `xdotool key/type` **之前**记下 `wc -l < feat-lines.txt`）。
    只接受**行号 > 该下界**的行；取不到 ⇒ **NOINFO**（无信息），**不许**降级成"陈旧"。
  · 仍在多个候选里选"最晚的"（行号最大），这是 append-only 文件里的正确选择。
"""

import argparse
import io
import os
import re
import sys
import tempfile

KEYS = ("changes", "text")


def parse_rows(path):
    """返回 [(lineno, text)]（1 基行号）。"""
    rows = []
    if not os.path.exists(path):
        return rows
    with io.open(path, encoding="utf-8", errors="replace") as f:
        for i, line in enumerate(f, 1):
            rows.append((i, line.rstrip("\n")))
    return rows


def pick(path, after_line, keys=KEYS):
    """返回 (status, {key: value})。只取行号 > after_line 的行。"""
    rows = parse_rows(path)
    after = [r for r in rows if r[0] > after_line]
    if not after:
        return "NOINFO", {}
    later = [r for r in rows if r[0] <= after_line]
    # 诊断：注入之前有没有被误当成"之后"的行（正是旧 tail -1 会取的那种）
    _, chosen = max(after, key=lambda r: r[0])
    out = {}
    for key in keys:
        if key == "changes":
            m = re.search(r"changes=([0-9]+|NA)", chosen)
            out["changes"] = m.group(1) if m else "NA"
        elif key == "text":
            m = re.search(r"text='([^']*)'", chosen)
            out["text"] = ("text='" + m.group(1) + "'") if m else ""
    out["_chosen_line"] = str(chosen_line_of(chosen))
    out["_pre_lines"] = str(len(later))
    return "AFTER", out


def chosen_line_of(line):
    """从行内 `[feat] <name> <VERDICT>` 里取 verdict 之后的内容做证据摘要。"""
    m = re.match(r"\[feat\]\s+\S+\s+(\S+)", line)
    return m.group(1) if m else "?"


def selftest():
    """牙：三种假日志。必须 —— (a) late 早于 OK 且**都在注入前** ⇒ NOINFO；(b) 有晚于注入且 changes=0 ⇒ AFTER/陈旧；
    (c) 晚于注入且 changes=3 ⇒ AFTER/非陈旧。"""
    ok = True
    d = tempfile.mkdtemp(prefix="t1b-pick-")
    late = "[feat] textbox-edit INCONCLUSIVE late: focus=False caret=0 selLen=0 text='seed' changes=0\n"
    okrow = "[feat] textbox-edit OK focus=True caret=0 selLen=7 text='seed' changes=0\n"
    after_stale = "[feat] textbox-edit OK focus=True caret=0 selLen=7 text='seed' changes=0 （注入后）\n"
    after_new = "[feat] textbox-edit OK focus=True caret=0 selLen=7 text='seedAB' changes=3 （注入后）\n"

    cases = [
        # (名字, 文件内容, 注入行号, 期望 status, 期望 changes, 说明)
        ("late 早于 OK、且都在注入之前（旧 tail -1 会取到 OK=注入前读数）",
         late + okrow, 2, "NOINFO", None, "必须 NOINFO —— 不许写成'陈旧'"),
        ("注入之后仍是 changes=0（真·写后陈旧）",
         late + okrow + after_stale, 2, "AFTER", "0", "必须 AFTER + changes=0 ⇒ 才允许记'陈旧'"),
        ("注入之后 changes=3（写后已更新）",
         late + okrow + after_new, 2, "AFTER", "3", "必须 AFTER + changes=3"),
        ("late 行排在 OK **之后**（L599<L734 那种形态）、都在注入前 ⇒ 仍 NOINFO",
         okrow + late, 2, "NOINFO", None, "顺序颠倒不影响结论：没有晚于注入的行就是无信息"),
    ]
    for name, content, after, want_status, want_changes, why in cases:
        p = os.path.join(d, re.sub(r"\W+", "_", name)[:40] + ".txt")
        with io.open(p, "w", encoding="utf-8") as f:
            f.write(content)
        status, vals = pick(p, after)
        got_changes = vals.get("changes")
        good = (status == want_status) and (want_changes is None or got_changes == want_changes)
        ok = ok and good
        print(("   ✅ " if good else "   ❌ ") + f"{status}/{got_changes}（期望 {want_status}/{want_changes}）"
              + f" —— {name}｜{why}")
    print(("[自检] 牙能变红 ✅" if ok else "[自检] 牙**不能**变红 ❌") + f"（假日志目录 {d}）")
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file")
    ap.add_argument("--after-line", type=int, default=0)
    ap.add_argument("--keys", default=",".join(KEYS))
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()

    if a.self_test:
        return selftest()
    if not a.file:
        print("用法：--file F --after-line N [--keys changes,text]  |  --self-test", file=sys.stderr)
        return 2

    keys = [k.strip() for k in a.keys.split(",") if k.strip()]
    status, vals = pick(a.file, a.after_line, keys)
    cells = [status] + [vals.get(k, "NA" if k == "changes" else "") for k in keys]
    print("\t".join(cells))
    return 0


if __name__ == "__main__":
    sys.exit(main())
