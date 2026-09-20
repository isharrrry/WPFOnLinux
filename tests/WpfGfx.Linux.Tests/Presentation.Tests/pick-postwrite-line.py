#!/usr/bin/env python3
"""从**应用原始日志**里取"注入之后"的**末条写后读数**（L23 的修法件，T3 车道）

用法：
    pick-postwrite-line.py --file <应用日志> --after-line <N> [--key changes,text]
    pick-postwrite-line.py --selftest          # 3 极性离线牙（不启应用）

为什么要这个（L23「读数早于事件」）：
    `run-wpfprobe.sh` 的 `textbox-edit` **键入腿**原先读 `$OUT/feat-lines.txt`（**应用自报台账**）里
    "晚于注入"的 `changes`。实测（#13，2026-09-15）：台账里的那条读数取自**注入之前**的自报快照
    ⇒ `changes=0` ⇒ 旧文案直接写成"**可观测模型陈旧（缺陷）**"；而**应用原始日志**里
    `WFP_POSTWRITE t=11047 变更 text='AB' len=2 sel=2,0 changes=2` 明明在注入之后。
    ⇒ 读点必须落在**被判决事件真正被写入的那份日志**上（"一个事件两份日志"，与 L18 同源）。

口径（三态，**只换读点、不改判据**）：
    · 锚点行之后**有** `WFP_POSTWRITE … changes=N`（N>0） ⇒ `AFTER` + `N`（证据如实写）
    · 锚点行之后有该行但 `changes=0`                             ⇒ `AFTER` + `0`（**真**陈旧）
    · 锚点行之后**没有**该行                                      ⇒ `NOINFO`（**不许**写"陈旧"）
    锚点 = runner 在**注入前**记下的应用日志**行数**（免时钟对齐；与 `INJECT_AT_LINE` 同一手法）。

输出（stdout，TSV 一行）：`<status>\t<changes>\t<text>`
退出码：0 = 有结论（AFTER/NOINFO 都算 0，判定在 status 字段）；2 = 用法/读档错；1 = 牙失败。
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile

RE_CHANGES = re.compile(r"\bchanges=(\d+)")
RE_TEXT = re.compile(r"\btext='([^']*)'")


def parse(path, after_line, want=("changes", "text")):
    """返回 (status, changes, text)。status ∈ {AFTER, NOINFO}。"""
    last = None
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            for lineno, line in enumerate(fh, 1):
                if lineno <= after_line:
                    continue
                # 只认**带 `changes=` 的** `WFP_POSTWRITE` 行；
                # `WFP_POSTWRITE-EVENT TextChanged #1 …` 无 `changes=` ⇒ 不是读数，跳过。
                if "WFP_POSTWRITE" not in line or "changes=" not in line:
                    continue
                last = line
    except OSError:
        return ("NOINFO", "NA", "")
    if last is None:
        return ("NOINFO", "NA", "")
    mc = RE_CHANGES.search(last)
    mt = RE_TEXT.search(last)
    return ("AFTER", mc.group(1) if mc else "NA", mt.group(1) if mt else "")


# ── 3 极性离线牙（不启应用、不碰显示、不编 shim）──────────────────────────────
SYNTH_HEAD = "WFP_POSTWRITE t=3827 变更 text='seed-文本' len=7 sel=0,0 changes=0\n"
SYNTH_MID = "WFP_POSTWRITE t=10445 心跳 text='seed-文本' len=7 sel=0,7 changes=0\n"


def _selftest():
    cases = [
        # (名字, 日志内容, 锚点行, 期望 status, 期望 changes)
        # ⚠️ 锚点语义 = "只看**行号 > after** 的行" ⇒ ②④ 的锚点必须落在最后一条读数**之后**，
        #    第一版我把锚点写成 1/0 ⇒ 牙报了 2/4 的**假红**（牙自己的测试数据写错，不是工具错）。
        ("①锚点后 changes=2",
         SYNTH_HEAD + SYNTH_MID + "WFP_POSTWRITE-EVENT TextChanged #1 text='A' len=1\n"
         + "WFP_POSTWRITE t=11047 变更 text='AB' len=2 sel=2,0 changes=2\n",
         2, "AFTER", "2"),
        ("②只有锚点前的读数",
         SYNTH_HEAD + SYNTH_MID,
         2, "NOINFO", "NA"),
        ("③锚点后 changes=0（真陈旧）",
         SYNTH_HEAD + SYNTH_MID + "WFP_POSTWRITE t=11047 变更 text='seed-文本' len=7 changes=0\n",
         2, "AFTER", "0"),
        ("④EVENT 行不许当读数（全文只剩 EVENT 行）",
         "WFP_POSTWRITE-EVENT TextChanged #1 text='A' len=1\n",
         0, "NOINFO", "NA"),
        ("⑤EVENT 行之后才是读数（EVENT 不得抢先）",
         "WFP_POSTWRITE-EVENT TextChanged #1 text='A' len=1\n"
         + "WFP_POSTWRITE-EVENT TextChanged #2 text='AB' len=2\n"
         + "WFP_POSTWRITE t=11047 变更 text='AB' len=2 sel=2,0 changes=2\n",
         0, "AFTER", "2"),
    ]
    ok = 0
    with tempfile.TemporaryDirectory() as td:
        for i, (name, body, after, exp_status, exp_ch) in enumerate(cases):
            p = os.path.join(td, f"case{i}.log")
            with open(p, "w", encoding="utf-8") as fh:
                fh.write(body)
            st, ch, tx = parse(p, after)
            good = (st == exp_status and ch == exp_ch)
            ok += good
            print(f"   {'✅' if good else '❌'} {name}: status={st} changes={ch}（期望 {exp_status}/{exp_ch}）")
    print(f"PICKPOSTWRITE_SELFTEST {ok}/{len(cases)}")
    return 0 if ok == len(cases) else 1


def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--file")
    ap.add_argument("--after-line", type=int, default=0)
    ap.add_argument("--selftest", action="store_true")
    a, _ = ap.parse_known_args()
    if a.selftest:
        return _selftest()
    if not a.file:
        print(__doc__)
        return 2
    st, ch, tx = parse(a.file, a.after_line)
    print(f"{st}\t{ch}\t{tx}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
