#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""T1c · 把 `[GLYPH_CENSUS]` 的读数**按帧**聚合成一行机读汇总（给 R1 复测用）。

    python3 build/MilBridge/tools/t1c-census-summary.py <app.log>

【为什么需要它】
  R1（shim 按 run 取字体 + 按码点覆盖回退）落地后要答的问题有两个，而**这个脚本只做聚合**：
    ① **权威数**（CJK 修没修）：`id0` / `非拉丁(id>=0x1000)` / `maxId` / `allnotdef runs`；
    ② **形态数**（多字体整形长什么样）：**几个面**、每个面各承担多少 run/字形（"哪几段落到回退面"）。
  ① 直接取 census **自己的** `frame=` 行（它统计整帧的全部 run）；
  ② 只能从**逐 run 明细**聚合 —— 而 census 每帧最多打 40 行明细（`GlyphRunCensus.MaxDetailLines=40`）
    ⇒ 明细聚合**可能少于**整帧数，这一点**必须打印出来**（"runs_detail=40 < runs_frame=48"），
    不许让"我数到的"冒充当"整帧的"。

【纪律】
  · 只读日志；不启动应用、不写任何别的文件（汇总只写到 stdout，由调用方 tee 进读数文件）；
  · 帧选择 = **字形数最多**的那一帧（与样例 runner 的"取最佳帧"同款判据），并**把所有帧都打出来**，
    免得"选了哪一帧"变成看不见的自由度；
  · 解析不了 ⇒ 退出码 1 且**不输出**任何汇总（宁可不说话，也不说不可信的话）。
"""

import re
import sys

FRAME_RE = re.compile(
    r"\[GLYPH_CENSUS\] frame=(\d+)\s+runs\(绘制次数\)=(\d+)\s+不同句柄=(\d+)\s+全notdef的run=(\d+)\s+"
    r"glyphs=(\d+)\s+id0=(\d+)\s+maxId=(\d+)\s+非拉丁\(id>=0x1000\)=(\d+).*?不同面数=(\d+)")

RUN_RE = re.compile(
    r"\[GLYPH_CENSUS\] run#(\d+)\s+handle=0x[0-9a-fA-F]+\s+n=(\d+)\s+id0=(\d+)\s+max=(\d+)\s+pid=0x([0-9a-fA-F]+)"
    r"(\s+allnotdef)?")


def main():
    if len(sys.argv) < 2:
        print("用法: t1c-census-summary.py <app.log>", file=sys.stderr)
        return 2

    try:
        with open(sys.argv[1], encoding="utf-8", errors="replace") as f:
            lines = f.read().splitlines()
    except OSError as e:
        print("读不到日志: %s" % e, file=sys.stderr)
        return 1

    frames = []          # 每帧：dict(totals=..., runs=[...])
    current = None

    for line in lines:
        m = FRAME_RE.search(line)
        if m:
            current = {
                "frame": int(m.group(1)),
                "runs": int(m.group(2)),
                "handles": int(m.group(3)),
                "allnotdef": int(m.group(4)),
                "glyphs": int(m.group(5)),
                "id0": int(m.group(6)),
                "maxid": int(m.group(7)),
                "nonlatin": int(m.group(8)),
                "pids_summary": int(m.group(9)),
                "detail": [],
            }
            frames.append(current)
            continue

        r = RUN_RE.search(line)
        if r and current is not None:
            current["detail"].append({
                "n": int(r.group(2)),
                "id0": int(r.group(3)),
                "max": int(r.group(4)),
                "pid": int(r.group(5), 16),
                "allnotdef": bool(r.group(6)),
            })

    if not frames:
        # 没有 census 读数 ⇒ **不说话**（不是"没有豆腐块"，是"没测"）
        return 1

    best = max(frames, key=lambda f: (f["glyphs"], f["frame"]))

    # ⚠️ **空真护栏**（本项目最高频的失败族之一）：空帧下 `id0=0 / nonlatin=0` 看起来"完美"，
    #    其实"这一帧什么都没画"。必须**显式标红**，不能让 0 冒充当结论。
    if best["runs"] == 0 or best["glyphs"] == 0:
        print("T1C_CENSUS_EMPTY frame=%d runs=%d glyphs=%d —— **空帧**：本帧一个 glyph run 都没画 "
              "⇒ id0=0 / nonlatin=0 是**空真**，不能当成\"没有豆腐块\""
              % (best["frame"], best["runs"], best["glyphs"]))
        print("T1C_CENSUS_FRAMES " + " | ".join(
            "frame=%d runs=%d glyphs=%d id0=%d nonlatin=%d maxid=%d" %
            (f["frame"], f["runs"], f["glyphs"], f["id0"], f["nonlatin"], f["maxid"]) for f in frames))
        return 3

    per_pid = {}
    detail_runs = detail_glyphs = detail_id0 = 0
    detail_nonlatin_runs = 0
    detail_allnotdef = 0

    for d in best["detail"]:
        detail_runs += 1
        detail_glyphs += d["n"]
        detail_id0 += d["id0"]
        if d["max"] >= 0x1000:
            detail_nonlatin_runs += 1
        if d["allnotdef"]:
            detail_allnotdef += 1
        slot = per_pid.setdefault(d["pid"], {"runs": 0, "glyphs": 0, "id0": 0})
        slot["runs"] += 1
        slot["glyphs"] += d["n"]
        slot["id0"] += d["id0"]

    pid_txt = ",".join(
        "0x%x(%druns/%dg/id0=%d)" % (p, v["runs"], v["glyphs"], v["id0"])
        for p, v in sorted(per_pid.items()))

    # 权威数（整帧，取自 census 自己的汇总行）
    print("T1C_CENSUS_SUMMARY frame=%d runs=%d handles=%d glyphs=%d id0=%d nonlatin=%d maxid=%d "
          "allnotdefruns=%d distinctpids=%d"
          % (best["frame"], best["runs"], best["handles"], best["glyphs"], best["id0"],
             best["nonlatin"], best["maxid"], best["allnotdef"], best["pids_summary"]))

    # 形态数（逐 run 明细聚合；**明细有上限**，如实标注）
    print("T1C_CENSUS_SHAPE  detail_runs=%d(of frame runs=%d%s) detail_glyphs=%d detail_id0=%d "
          "detail_nonlatinruns=%d detail_allnotdefruns=%d pids=[%s]"
          % (detail_runs, best["runs"],
             "（明细行每帧上限 40 ⇒ 少于整帧数**不代表丢 run**）" if detail_runs < best["runs"] else "",
             detail_glyphs, detail_id0, detail_nonlatin_runs, detail_allnotdef, pid_txt))

    print("T1C_CENSUS_FRAMES " + " | ".join(
        "frame=%d runs=%d glyphs=%d id0=%d nonlatin=%d maxid=%d" %
        (f["frame"], f["runs"], f["glyphs"], f["id0"], f["nonlatin"], f["maxid"]) for f in frames))

    return 0


if __name__ == "__main__":
    sys.exit(main())
