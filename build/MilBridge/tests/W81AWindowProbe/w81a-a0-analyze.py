#!/usr/bin/env python3
# ============================================================================
# w81a-a0-analyze.py —— `W81A` 的 `A0` 腿分析器（**只读**）
# ============================================================================
#  输入：$1 = `LD_DEBUG_OUTPUT` 目录（含 `ld.*`，每进程一份）；$2 = 本腿的输出目录
#        （里面应有 `tripwire/cmd.out`、`tripwire/cmd.err`、`run.log`）
#  真值：**ld.so 自己写的符号查找日志**（不经过我们任何代码）
#  输出（机读 + 人读）：
#    · 选定哪一份 `ld.*`（= 那个真的加载了 shim 的进程），为什么选它
#    · PTS/LS 家族符号的**按日志先后**清单：序号 / 符号 / 被查找行数 / FOUND|MISS / 首次出现行号
#    · 与 `build/MilBridge/W78A-report.md` §2.2 的 **27 条**静态闭包逐条对表
#    · 第一条 MISS 的完整查找链（证据）、以及应用的最后几拍 `step=` 标记
#    · 末行：`W81A_A0=MEASURED|NOINFO …`
#
#  ⚠️ 口径边界（如实划）：
#   ① 顺序 = **该进程日志里的行序**。ld.so 按查找发生时刻逐行写；若进程有多线程同时解析符号，
#      行序会交错 ⇒ "顺序"只保证"日志顺序"，不保证"单线程调用顺序"（本报告按此口径写）。
#   ② FOUND/MISS 的判据 = **符号是否在本移植唯一可能提供它的库（shim）的导出表里**（`nm -D`），
#      并用「被查找行数」交叉核对（= 1 ⇒ 第一站就命中；≥ 6 ⇒ 整条依赖链翻遍）。
#      两者分叉 ⇒ 本脚本打 `CONFLICT` 并点名（不许悄悄取一个）。
# ============================================================================
import os
import re
import subprocess
import sys
import glob

_ROOT77 = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))   # 波 `#77` 旧路径重指向：由仓根现推
SHIM = os.path.join(_ROOT77, "src/WpfGfx.Linux.Native/bin/libwpfwin32.so")

# `W78A-report.md` §2.2 的 27 条静态闭包（**逐字抄自该报告的分组**）
CLOSURE = [
    ("A 上下文创建期（无条件）", [
        "CreateInstalledObjectsInfo", "GetFloaterHandlerInfo", "GetTableObjHandlerInfo",
        "CreateDocContext", "DestroyInstalledObjectsInfo", "DestroyDocContext"]),
    ("B 构造期 LS 罚分模块（无条件）", [
        "LoCreateContext", "LoAcquirePenaltyModule", "LoGetPenaltyModuleInternalHandle",
        "LoDisposePenaltyModule", "LoDestroyContext"]),
    ("C 页/节/道/子道结构", [
        "FsCreatePageFinite", "FsUpdateFinitePage", "FsQueryPageDetails", "FsQuerySectionDetails",
        "FsQueryTrackDetails", "FsQuerySubtrackDetails", "FsQuerySectionBasicColumnList"]),
    ("D 文本段→行", [
        "FsQueryTextDetails", "FsQueryLineListSingle", "FsQueryLineListComposite",
        "FsQueryLineCompositeElementList", "FsQueryAttachedObjectList", "FsTransformRectangle",
        "FsTransformBbox"]),
    ("E 拆卸", ["FsDestroyPage", "FsDestroyPageBreakRecord"]),
]
CLOSURE_NAMES = {n for _, ns in CLOSURE for n in ns}

# 家族判据：`Fs*`/`Lo*`/`Ls*`/`Nl*`（绊线同口径）**或** 27 条清单里的非前缀名（PTS 对象族）
FAMILY_RE = re.compile(r"^(Fs|Lo|Ls|Nl)[A-Za-z]")
LINE_RE = re.compile(r"^\s*\d+:\s+symbol=([A-Za-z_0-9]+);\s+lookup in file=(\S+)")


def shim_exports():
    out = subprocess.run(["nm", "-D", "--defined-only", SHIM], capture_output=True, text=True).stdout
    return {ln.split()[-1] for ln in out.splitlines() if ln.strip()}


def main():
    lddir, outdir = sys.argv[1], sys.argv[2]
    files = sorted(glob.glob(os.path.join(lddir, "ld.*")))
    if not files:
        print(f"W81A_A0=NOINFO reason=no-ld-logs dir={lddir}")
        return 2

    info = []
    for f in files:
        try:
            txt = open(f, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        n_lines = txt.count("\n")
        shim_lookups = len(re.findall(r"lookup in file=\S*libwpfwin32\.so", txt))
        info.append((f, n_lines, shim_lookups))
    print("-- ld.* 候选（每进程一份；选定判据 = 该进程**真的按名字找过 shim 里的符号**）--")
    for f, n, s in info:
        print(f"   {os.path.basename(f):16s} lines={n:<9d} shim_lookups={s}")
    cand = [x for x in info if x[2] > 0]
    if not cand:
        print("W81A_A0=NOINFO reason=no-process-looked-up-shim-symbols（应用没加载 shim ⇒ 本趟无信息）")
        return 2
    cand.sort(key=lambda x: -x[2])
    chosen, n_lines, n_shim = cand[0]
    print(f"   选定 = {os.path.basename(chosen)}（shim_lookups={n_shim}，行数={n_lines}）")

    exports = shim_exports()
    seq = []            # [(lineno, symbol)]
    per = {}            # symbol -> [n, first_line, files]
    for i, ln in enumerate(open(chosen, encoding="utf-8", errors="replace"), 1):
        m = LINE_RE.match(ln)
        if not m:
            continue
        sym, lib = m.group(1), m.group(2)
        if not (FAMILY_RE.match(sym) or sym in CLOSURE_NAMES):
            continue
        seq.append((i, sym))
        d = per.setdefault(sym, [0, i, []])
        d[0] += 1
        d[2].append(lib)

    if not seq:
        print("W81A_A0=NOINFO reason=no-pts-ls-family-lookup（这一趟没有任何 Fs*/Lo*/Ls*/Nl*/PTS 查找）")
        return 2

    print()
    print("-- PTS/LS 家族符号（**按日志先后**；一个符号只在其**首次**出现处列出）--")
    print(f"   {'#':>3} {'符号':42s} {'查找行数':>6} {'判定':7s} {'首次行':>8}")
    first_seen_order = []
    seen = set()
    for ln, sym in seq:
        if sym in seen:
            continue
        seen.add(sym)
        first_seen_order.append(sym)
        n, fl, libs = per[sym]
        if sym in exports:
            verdict = "FOUND" if n <= 2 else "FOUND?"
        else:
            verdict = "MISS" if n >= 2 else "MISS?"
        if sym in exports and n >= 6:
            verdict = "CONFLICT"
        if sym not in exports and n == 1:
            verdict = "CONFLICT"
        print(f"   {len(first_seen_order):>3} {sym:42s} {n:>6} {verdict:7s} {fl:>8}")

    print()
    print("-- 与 `W78A-report.md` §2.2 的 **27 条**静态闭包对表 --")
    hit = miss = notseen = 0
    rows = []
    for grp, names in CLOSURE:
        for nm in names:
            if nm in per:
                n = per[nm][0]
                v = "FOUND" if nm in exports else "MISS"
                if nm in exports:
                    hit += 1
                else:
                    miss += 1
                order = first_seen_order.index(nm) + 1
            else:
                v = "未出现"; notseen += 1; n = 0; order = "-"
            rows.append((grp, nm, v, n, order))
    print(f"   {'组':34s} {'符号':40s} {'判定':8s} {'查找行数':>6} {'家族序':>6}")
    for grp, nm, v, n, order in rows:
        print(f"   {grp:34s} {nm:40s} {v:8s} {n:>6} {str(order):>6}")
    print(f"   ⇒ 27 条里：**被查找过 {hit + miss} 条**（其中 shim 已导出 FOUND={hit}、缺符号 MISS={miss}）、"
          f"一次都没被要求过 {notseen} 条（进程死在第一条缺符号上 ⇒ 后面的需求在本移植里**测不到**）")

    # 第一条 MISS 的证据链
    miss_syms = [s for s in first_seen_order if s in per and s not in exports]
    if miss_syms:
        fm = miss_syms[0]
        print()
        print(f"-- 第一条**缺符号**（= 本趟进程死在这条上的那个）= `{fm}`；完整查找链 --")
        for lib in per[fm][2]:
            print(f"     {lib}")

    # ── 附带读数：本次运行**真正按名字要过**的 shim 符号里，除首缺之外还有哪些是缺的 ──────
    #   口径：**查找链的第一个库就是 shim** = 这次查找是冲着 shim 去的（P/Invoke 解析）；
    #         链尾才出现 shim 的（例：`LoadCursorA`）是**全局作用域**查找，不能与前者混在一起算。
    #   ⚠️ 这条口径是**本趟实测逼出来的**：绊线自带的规则是「查找行数 = 1 ⇒ 第一站命中；≥ 6 ⇒ MISS」，
    #      而本日志里 `LoadCursorA` 有 **9 行**链，末行正是 shim，且 `nm -D` 说 shim 定义了它
    #      ⇒ **「行数 ≥ 6 ⇒ MISS」不成立**（反例就在本趟日志里）。所以本脚本一律以
    #      `nm -D` 的**导出成员关系**为判据，行数只作旁证。
    first_is_shim = {}
    for ln, sym in seq:
        if sym in first_is_shim:
            continue
        first_is_shim[sym] = per[sym][2][0].endswith("libwpfwin32.so")
    req = [s for s in first_seen_order if first_is_shim.get(s)]
    req_missing = [s for s in req if s not in exports]
    print()
    print("-- 附带：**家族符号**里**冲着 shim 去**的那些（链首 = shim；家族 = Fs*/Lo*/Ls*/Nl* ∪ 27 条清单）--")
    for s in req:
        print(f"     {s:44s} n={per[s][0]:<4d} {'FOUND' if s in exports else '**缺**'}")
    print(f"   ⇒ 家族里冲着 shim 去的共 {len(req)} 条，其中**缺** {len(req_missing)} 条："
          + (", ".join(req_missing) if req_missing else "<无>"))
    print(f"   （另有全局作用域查找 {len(first_seen_order) - len(req)} 条 —— 例：`LoadCursorA`，"
          f"链尾命中 shim，属另一类，不计入需求）")

    # 应用自己走到哪一步 + 异常原文
    print()
    print("-- 应用侧痕迹（`step=` 标记 + 异常原文）--")
    for rel in ("tripwire/cmd.out", "tripwire/cmd.err", "run.log"):
        p = os.path.join(outdir, rel)
        if not os.path.exists(p):
            continue
        keep = []
        for ln in open(p, encoding="utf-8", errors="replace"):
            if ln.startswith("W81A_") or "EntryPointNotFoundException" in ln \
               or "Unable to find an entry point" in ln or "Process terminated" in ln \
               or "Invariant" in ln or "失败" in ln and "断言" in ln:
                keep.append(ln.rstrip())
        if keep:
            print(f"   [{rel}]")
            for ln in keep[:40]:
                print("     " + ln)

    print()
    print(f"W81A_A0=MEASURED family_symbols={len(first_seen_order)} closure_hit={hit + miss} "
          f"closure_found={hit} closure_missing={miss} closure_notseen={notseen} "
          f"first_miss={miss_syms[0] if miss_syms else '<none>'} app_log={os.path.basename(chosen)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
