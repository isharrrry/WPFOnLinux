#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# geom-revert-beat-check —— **事件锚定**的「WM 真还原 → 桥把它顶回」时序牙
#                          （`TASK-0110` 改题后：**第一块**）
#
# 【它挡的是什么】现行"两拍"（`~/w89a/bin/hc-arm-inner.sh:126` / `:135`，`sleep 4.5` / `sleep 4.5`）
#   把拍位放在**事件之后 ~4.5 s / ~9.0 s**，而「真还原 → 被顶回」的驻留实测只有 **41–86 ms**
#   ⇒ 错位 **约 100 倍** ⇒ 一对事件被整对吞掉 ⇒ 把 **"WM 已经收回了"** 读成 **"WM 没收回"**
#   （该假结论曾在 `W89A → W105A → W111A → W112A → W114A → W116A` 六条车道的登记里存活，
#    并先后生出三个错误假设；见 `~/w148a/report.md` §1.5 的 `RECON-R2` 血案，与本件的 `C6`）。
#   ⇒ 本牙把拍位改成**由事件定义**，并把"frame/client 分离"判在 **时刻** 上、**不判在值上**
#     （值上判不到：还原那一跳 `client` 与 `frame` 在同一批里改完）。
#
# ─────────────────────────────────────────────────────────────────────────────
# 【判据（**先写死**；方向由主控 2026-09-23 23:36 裁定冻结，理由见下）】
#
#   `B2`（`B_link`，还原锚）= `M_land` 之后**首次** `EVT ConfigureNotify(send_event=0)` 且尺寸 == 基准
#   `B3`（推回锚）          = `B2` 之后**首次**同型事件且尺寸 == 屏尺寸
#   `Δ_push = B3 − B2`（ms）—— **只作诊断列**
#
#   🔴 **承重判词 = `B3` 的有无**（**不是** `Δ_push` 的大小）：
#       `B3` 出现                          ⇒ **FAIL（红）**：桥在还原之后把几何推回屏尺寸 = 缺陷签名
#       `B3` 全程 `NONE` ∧ 覆盖 ≥ 4500 ms  ⇒ **PASS（绿）**：还原被保持住
#       `B3` 全程 `NONE` ∧ 覆盖 <  4500 ms  ⇒ **NOINFO**（否定断言不成立）
#   `RED_WINDOW_MS = 200` **只用于给诊断列贴标签**（`IN_RED_WINDOW` / `LATE_PUSH`），**不参与判词**。
#
#   ⚠️ **为什么 `200 ms` 这个数字的方向"不得取反"（逐字给反证）**
#      —— 曾有一条父注写「`Δ_push > 200 ms` ⇒ 必红；`Δ_push = 60 ms` ⇒ 必绿」。**该方向已作废**：
#        · **反证（本牙在既有 39 腿台账上现场现算）**：**修前件** `feef049e9d0e313a`（= 缺陷在场）的
#          16 条红腿 `Δ_push` **全部落在 64.4–104.3 ms（median 76.2）**，**没有一条 > 200 ms**
#          ⇒ 若按"慢 ⇒ 红"的方向，**修前件会 16/16 判绿** ⇒ 该方向**必造假绿**（正是要抓的行为被放过）。
#        · 机制侧同源：缺陷 = 桥在还原后 **+85 ms** 的**快**顶回（`WC03` 归因终局／`TASK-0210` 修法），
#          `200 ms` 这个界是给 **85 ms 留 2.3× 余量**（"围住快区"），不是"越慢越是缺陷"。
#        · 因此本牙**不提供反向开关**（能造出假绿的口径不许留旋钮）；`Δ_push` 降为诊断列。
#   **假绿探测器（反向自证）**：若**修前臂**（`feef049e9d0e313a`）在语料里**一条红都没有**
#      ⇒ 顶层判 `FAIL reason=FALSE_GREEN`，并声明"**判据作废、须重写**"（不许把全绿当 PASS）。
#
#   **三态**：`NOINFO` **既不算绿也不算红**（原话照此执行）。
#
# ─────────────────────────────────────────────────────────────────────────────
# 【为什么必须有 `C4`／`C6` 两条自检】
#   `C4`（装置有牙）：负结论之前必须有正对照 —— 台账里**一条变化行都没有**时，"几何没变"可能只是
#                    `仪器钝` ⇒ 该格**只在绿判词上**阻断（红判词自带证据，不阻断）。
#   `C6`（分辨率）：**事件锚定**下采样周期不参与判据本身；要求
#       ① 余量**诊断**（`|Δ_push − 200| < 2·T` ⇒ 打 `near_red_boundary=YES`，**只标注、不判词**）；
#       ② 窗完整性 `cover ≥ GREEN_WIN_MS`（否则绿判词不成立）。
#       ⚠️ **口径更正（就地记明）**：`T` 取**声明值** `T_DECL_MS = 5.0`
#       （源引 `~/wc03/bin/xobs.c:92` `hz = 200.0`；腿脚本未传 `--hz`）。
#       台账是"**变更即打**"⇒ 相邻行距**不是**采样周期 ⇒ 不能用行距当 `T`
#       （本车道 `criteria.md` 初稿写的"相邻行中位差"口径在此**就地更正**：该量在变更触发式台账里不可测）。
#       同时打印 `line_gap_med_ms` 仅作**诊断**，**不参与**任何判词。
#
# 【旁证格（**不承重、永不相加、不进判词**）】
#   `P1`（真·分离）= `SEG` 行里 `cgeo` 尺寸 != `fgeo` 尺寸；`rel < 2.0 s` 的记 `P1_startup`
#   （= WM 尚未 reparent 的**陈旧父窗**伪读数，`frame=0x50d` 那类），`rel ≥ 2.0 s` 的记 `P1_true`。
#   `P2` = `SEG` 行 `state` 含 `MAXIMIZED` 而 `client` 未到屏尺寸。
#   ⚠️ `P1` 与 `P2` **分开打、永不相加**；`Δ_lead` 只作**旁证**，**不承重**（承重只有 `B3`）。
#   ⚠️ `_NET_FRAME_EXTENTS` **本牙根本不读**（既有台账 233/233 = `0,0,0,0` 恒真谓词 ⇒ 进判据即假牙）。
#
# 【用法】
#   bash build/MilBridge/tools/geom-revert-beat-check.sh --selftest
#   bash build/MilBridge/tools/geom-revert-beat-check.sh --corpus="$HOME/w134a/run"
#   bash build/MilBridge/tools/geom-revert-beat-check.sh --leg="$HOME/w134a/run/W134A-A1-OLD-1"
#   bash build/MilBridge/tools/geom-revert-beat-check.sh --live-selftest     # 真事件锚定（私有 :227）
#   新增一格 **`GEOMCORPUS=`**（`#59` 主控裁定 ③）：在 `--corpus=` 模式下把**现场语料聚合**
#   与 `known-red.json` 的 `generation.geom_corpus.sha256` **全 64 位逐字**比，**不等 ⇒ `NOINFO`**
#   （点名 `geom-corpus-declared-mismatch`）⇒ **顶层 `GEOMBEAT=NOINFO`**（rc=2）。
#   `--leg=` 模式（逐腿诊断 / `--live-selftest`）**[W153A-#61 改] 也真判**：把「该腿所属语料」取为
#   **腿目录的父目录**，对它算聚合与声明比；**对得上 ⇒ `GEOMCORPUS=PASS`**（顶层仍走臂判词），
#   **对不上 / 派生不出来（多个不同父目录 / 件数超限）⇒ `NOINFO` 且传染顶层**
#   （`GEOMBEAT=NOINFO reason=corpus-anchor（leg-mode-corpus-unresolved…）`）——
#   **修前那条「顶层 PASS 而锚未行使」的旁路因此不存在**（`D-G114`）。
#   `--pair=yes|no` **保留兼容，但不改变顶层口径**：顶层**恒为成对制**（缺任一臂 ⇒ `NOINFO single-arm`）；
#   `--pair=no` 只用于"单腿/单臂读取"的场景，逐腿 `BEAT` 行与臂级 `ARM` 行不受影响。
#
# 【机制】本件**只读**既有台账（`xobs.log` ＋ `probe.txt`）：**不跑**应用腿、**不跑** `dotnet`、
#   不改任何产品件；`--live-selftest` 只起**私有** `Xvfb :227` ＋ 一个**自写的极小 X 客户端**
#   （无 `dotnet`、无产品件），用于验证"真 `ConfigureNotify` 也能事件锚定"。
#   仪器件（只读复用，一个字节不改）：`~/wc03/bin/xobs` `fb3fe379eb943994`（`xobs.c:92` `hz=200`）。
# ═══════════════════════════════════════════════════════════════════════════════
set -u
SELF="$0"
MODE=analyze
for a in "$@"; do
  case "$a" in
    --selftest) MODE=selftest ;;
    --live-selftest) MODE=live ;;
  esac
done

# ── 真装置自测：私有 :227 ＋ 自写极小 X 客户端（**无 dotnet**；跑不成 ⇒ 记 NOINFO 并点名）────
if [ "$MODE" = live ]; then
  SANDBOX="${GEOMBEAT_LIVE_DIR:-$HOME/w149a/live-$(date +%H%M%S)}"
  SRC="$SANDBOX/genbeat.c"; BIN="$SANDBOX/genbeat"
  XOBS="${W149A_XOBS:-$HOME/wc03/bin/xobs}"
  mkdir -p "$SANDBOX" || { echo "GEOMBEAT=NOINFO reason=sandbox-unwritable"; exit 2; }
  if ! command -v gcc >/dev/null 2>&1; then echo "GEOMBEAT=NOINFO reason=no-gcc（真装置自测缺编译器）"; exit 2; fi
  if [ ! -x "$XOBS" ]; then echo "GEOMBEAT=NOINFO reason=no-xobs path=$XOBS"; exit 2; fi
  cat > "$SRC" <<'CEOF'
/* 极小 X 客户端：base(800x600@+240+212) → 最大化(1280x1024@+0+0) → 还原(base) →[可选] → 顶回(屏) */
#include <X11/Xlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
static void ms(int m){ usleep((useconds_t)m*1000); }
int main(int argc, char **argv)
{
    const char *name = "W149APROBE";
    int delta = -1;                                  /* <0 = 不顶回 */
    for (int i = 1; i < argc; i++) {
        if (!strncmp(argv[i], "--delta=", 8)) delta = atoi(argv[i] + 8);
        else if (!strncmp(argv[i], "--name=", 7)) name = argv[i] + 7;
    }
    Display *d = XOpenDisplay(NULL);
    if (!d) { printf("XOPEN_FAIL\n"); return 5; }
    int s = DefaultScreen(d);
    Window w = XCreateSimpleWindow(d, RootWindow(d, s), 240, 212, 800, 600, 0, 0, 0);
    XStoreName(d, w, name);
    XMapWindow(d, w);
    XFlush(d);
    ms(1500);                                         /* 让观测器找到并记录基准 */
    XMoveResizeWindow(d, w, 0, 0, 1280, 1024);        /* 最大化落地 */
    XFlush(d); ms(800);
    XMoveResizeWindow(d, w, 240, 212, 800, 600);      /* B2：真还原 */
    XFlush(d);
    if (delta >= 0) { ms(delta); XMoveResizeWindow(d, w, 0, 0, 1280, 1024); XFlush(d); }  /* B3：顶回 */
    ms(5200);                                         /* 还原之后**活满 >4.5s** 的观测窗（否则绿判词只能 NOINFO） */
    XCloseDisplay(d);
    return 0;
}
CEOF
  gcc -O0 -o "$BIN" "$SRC" -lX11 2>"$SANDBOX/gcc.log" || {
    echo "GEOMBEAT=NOINFO reason=gcc-failed log=$SANDBOX/gcc.log"; exit 2; }
  XVFB_PID=""
  # 本车道私有显示 = :227（判据 §4 白名单）。**先探活**（不许用 `pgrep -f`：按 /proc/*/cmdline 读）
  if ! DISPLAY=:227 xdpyinfo >/dev/null 2>&1; then
    OWNER=""
    # ⚠️ **不许按整条 cmdline 子串匹配** —— 本件自己那条扫描命令的 cmdline 里就含 "Xvfb" 与 ":227"
    #    ⇒ 会**自匹配**并伪报"display busy"（本车道 23:38 现场踩过一次，如实记；`D-G103` 家族）。
    #    正确判法：**argv0 的基名必须是 Xvfb**，且**某个 argv 恰好等于 ":227"**。
    for p in $(ls /proc 2>/dev/null | grep -E '^[0-9]+$'); do
      [ "$p" = "$$" ] && continue
      [ "$p" = "${PPID:-0}" ] && continue
      a0="$(tr '\0' '\n' < /proc/$p/cmdline 2>/dev/null | head -1)"
      case "${a0##*/}" in Xvfb) ;; *) continue;; esac
      if tr '\0' '\n' < /proc/$p/cmdline 2>/dev/null | grep -qx ':227'; then OWNER="$p"; fi
    done
    if [ -n "$OWNER" ]; then
      echo "GEOMBEAT=NOINFO reason=display-227-busy owner_pid=$OWNER（:227 有活的 Xvfb 但不是本趟起的 ⇒ 不抢）"
      exit 2
    fi
    # 无活主 ⇒ 上次 **SIGKILL** 留下的**陈旧** socket/lock（本车道自己的）必须清掉，否则 Xvfb 起不来
    if [ -e /tmp/.X11-unix/X227 ] || [ -e /tmp/.X227-lock ]; then
      echo "NOTE 清理本车道 :227 的陈旧 socket/lock（前一趟 SIGKILL 的遗留；已确认无活主）"
      rm -f /tmp/.X11-unix/X227 /tmp/.X227-lock 2>/dev/null
    fi
    Xvfb :227 -screen 0 1280x1024x24 >"$SANDBOX/xvfb.log" 2>&1 &
    XVFB_PID=$!
    for _ in $(seq 1 20); do DISPLAY=:227 xdpyinfo >/dev/null 2>&1 && break; sleep 0.5; done
  fi
  if ! DISPLAY=:227 xdpyinfo >/dev/null 2>&1; then
    echo "GEOMBEAT=NOINFO reason=display-227-unavailable log=$SANDBOX/xvfb.log"
    [ -n "$XVFB_PID" ] && kill -TERM "$XVFB_PID" 2>/dev/null
    exit 2
  fi
  pass=0; total=0
  for case in "push_none:-1:PASS" "push_060:60:FAIL" "push_400:400:FAIL" "push_085:85:FAIL"; do
    IFS=: read -r tag delta want <<<"$case"
    D="$SANDBOX/$tag"; mkdir -p "$D"; rm -f "$D"/*
    ( DISPLAY=:227 "$XOBS" --name=W149APROBE --timeout=14 >"$D/xobs.log" 2>&1 ) &
    OBS=$!
    sleep 0.6
    DISPLAY=:227 timeout 14 "$BIN" --delta="$delta" --name=W149APROBE >"$D/client.log" 2>&1
    wait "$OBS" 2>/dev/null
    printf 'TAG=%s\nRESULT tag=%s M=M1 R=R2 START_MAX=0 BASE=800x600@+240+212 BRIDGE=synthetic-live SHIM=none\n' \
      "$tag" "$tag" > "$D/probe.txt"
    line="$(bash "$SELF" --leg="$D" --screen=1280x1024 --pair=no 2>/dev/null | awk '/^BEAT /{print}')"
    got="$(printf '%s\n' "$line" | sed 's/.*verdict=//')"
    dp="$(printf '%s\n' "$line" | sed -n 's/.*d_push_ms=\([^ ]*\).*/\1/p')"
    total=$((total+1)); [ "$got" = "$want" ] && pass=$((pass+1))
    printf 'LIVE case=%-10s delta=%-4s d_push_ms=%-8s want=%-6s got=%-6s %s\n' \
      "$tag" "$delta" "$dp" "$want" "$got" "$([ "$got" = "$want" ] && echo OK || echo MISMATCH)"
  done
  echo "GEOMBEAT_LIVE=$pass/$total sandbox=$SANDBOX xobs=$XOBS"
  # **先 SIGTERM 再 SIGKILL**：SIGKILL 会让 Xvfb 留下陈旧 socket/lock（本车道踩过一次，如实记）
  if [ -n "$XVFB_PID" ]; then
    kill -TERM "$XVFB_PID" 2>/dev/null
    for _ in $(seq 1 20); do kill -0 "$XVFB_PID" 2>/dev/null || break; sleep 0.2; done
    kill -KILL "$XVFB_PID" 2>/dev/null
  fi
  [ "$pass" = "$total" ] || exit 1
  exit 0
fi

export GEOMBEAT_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
exec python3 - "$@" <<'PYEOF'
# W149A · 事件锚定时序牙（内核）。口径全部见本文件 bash 头注释（**先写死**，方向由主控裁定）。
import os, re, sys, glob, statistics, tempfile

RED_WINDOW_MS = 200.0     # **只作诊断标签**（不参与判词）
GREEN_WIN_MS  = 4500.0    # 先写死的绿窗
T_DECL_MS     = 5.0       # 声明值（xobs.c:92 hz=200.0）；台账"变更即打" ⇒ 行距不是 T
FIX_SHA = "4e25e4b27d4d5ae1"   # 修后桥件
PRE_SHA = "feef049e9d0e313a"   # 修前桥件


# ── 【`#59` 主控裁定 ③ 加严：语料世代锚的**读者**（纪律 47：没有人读的声明 = 半个牙）】──────
#   背景：`known-red.json` 的 `generation.geom_corpus.sha256` 声明的就是**本牙所读的那份冻结语料**
#   的整份聚合（相对路径口径）。**没有这一格**时，"换整套自洽语料"**零机器红** -- 判据的结论
#   取决于没人看着的输入（`D-G31` 家族）。本格把它接进判据。
#
#   **算法（与声明处 `generation.geom_corpus.note` 逐字同源，写死）**：
#       cd <语料根> && find . -type f | LC_ALL=C sort | xargs sha256sum | sha256sum
#     => 逐件 sha256 -> 按 `./相对路径` **字节序**排 -> 拼出 `<hex>   <path>\n` 流 -> 再 sha256。
#     ⚠️ 为什么在 python 里**重实现**而不再 fork 一条 shell：shell 版依赖 `xargs` 的**分词**
#        与 `sort` 的 **locale**。**等价性由自测钉死**（`anchor_alg` 例：合成语料上本法与
#        shell 版**逐字同值**）-- 本件的口径因此不随环境漂。
#     ⚠️ **路径白名单**：只接受不含空白/引号/反斜杠的相对路径 -- 含则 `NOINFO reason=anchor-path-unsupported`
#        （`xargs` 会对这类路径分词 => 两边口径不再可比；**不猜**）。
#
#   **三态**：现场 == 声明（**全 64 位逐字比**，前缀相等不算）=> `PASS`；
#            不等 => `NOINFO reason=geom-corpus-declared-mismatch`（**点名**，裁定原文）；
#            缺声明／登记表读不到／锚不是 64 位小写 hex => `NOINFO`（**缺声明 != 通过**）。
#
#   **射程（`#61` W153A 加严，就地更正；原句保留如下供对照）**：
#     〔原〕本格**只在 `--corpus=<root>` 模式**成立 —— `--leg=<dir>` 模式打 `NOT_APPLICABLE` 且**不传染**。
#     〔今〕**两种模式都真判**：`--corpus=` 比「整份语料」；`--leg=` 比「腿的**父目录**」（=该腿所属语料）。
#      `--leg=` 派生失败（多个不同父目录／父目录件数 > `LEG_CORPUS_MAX_FILES`／登记表读不到）
#      ⇒ `GEOMCORPUS=NOINFO` 且**传染顶层** ⇒ **没有任何路径能印「顶层 PASS 而锚未行使」**。
#      ⚠️ 逐腿 `BEAT` 行**一字不受影响**（锚格只动 `GEOMCORPUS=` 与顶层 `GEOMBEAT=` 两行）。
#    ⚠️ `verify-all.sh` 第 `[32]` 步**只**用 `--corpus=` 调用 => 本格在该步**必然行使**。
GEOM_REGISTRY_REL = "build/MilBridge/known-red.json"
_UNSAFE = re.compile(r"""[\s'"\\]""")

def _repo_root():
    """仓根 = **bash 侧导出的 `GEOMBEAT_REPO`**（见 B2 的理由：本内核跑在 `python3 -` 上，
    它的 `__file__` 是 `<stdin>` ⇒ 拿 `__file__` 反推会得到**静默错误的路径**）。"""
    return os.environ.get("GEOMBEAT_REPO") or os.getcwd()

def registry_path():
    """留 `GEOMBEAT_REGISTRY` 覆盖口（自测与沙箱用）-- 与仓内 `ALSC_REG`/`CFC_REG` 同一套机制。"""
    return os.environ.get("GEOMBEAT_REGISTRY") or os.path.join(_repo_root(), GEOM_REGISTRY_REL)

def corpus_aggregate(root, max_files=None):
    """-> (hex64|None, note)。口径 = 上述写死算法（python 重实现，自测与 shell 版对拍）。
    [W153A-#61] `max_files`（供 `--leg` 派生语料用）：**枚举件数超限 ⇒ 先不哈希、直接 NOINFO**
    （防「`--leg` 指到一个巨大父目录」把一次诊断变成全盘哈希）。"""
    import hashlib
    if not os.path.isdir(root):
        return None, "root-absent:" + root
    rels = []
    for dp, _dn, fns in os.walk(root):
        for fn in fns:
            p = os.path.join(dp, fn)
            if os.path.islink(p) or not os.path.isfile(p):
                continue
            rel = "./" + os.path.relpath(p, root)
            if _UNSAFE.search(rel):
                return None, "anchor-path-unsupported:" + rel
            rels.append(rel)
    if not rels:
        return None, "empty-corpus"
    if max_files is not None and len(rels) > max_files:
        return None, "too-many-files:%d>%d" % (len(rels), max_files)
    outer = hashlib.sha256()
    for rel in sorted(rels, key=lambda t: t.encode("utf-8", "surrogateescape")):
        with open(os.path.join(root, rel[2:]), "rb") as f:
            inner = hashlib.sha256(f.read()).hexdigest()
        outer.update(("%s  %s\n" % (inner, rel)).encode("utf-8", "surrogateescape"))
    return outer.hexdigest(), "files=%d" % len(rels)

def declared_corpus_anchor():
    """-> (hex64|None, why)。读 `known-red.json` 的 `generation.geom_corpus.sha256`。"""
    import json
    rp = registry_path()
    if not os.path.exists(rp):
        return None, "registry-absent:" + rp
    try:
        d = json.load(open(rp, encoding="utf-8"))
    except Exception as e:
        return None, "registry-unparsable:" + e.__class__.__name__
    v = (((d.get("generation") or {}).get("geom_corpus")) or {}).get("sha256")
    if not v:
        return None, "geom-corpus-undeclared（登记表里没有 generation.geom_corpus.sha256）"
    if not re.fullmatch(r"[0-9a-f]{64}", str(v)):
        return None, "anchor-malformed:" + str(v)[:24]
    return str(v), "declared"

def corpus_anchor_state(corpus_roots, max_files=None):
    """-> (state, detail)。[W153A-#61] **只**负责「给了一组语料根」这一种形态（`--corpus=` 与
    `--leg=` 派生后的父目录都归它判）；「没有任何输入」时才返回 `NOT_APPLICABLE`（**不传染**）。"""
    if not corpus_roots:
        return "NOT_APPLICABLE", "no-input（既没给 `--corpus=` 也没给 `--leg=` ⇒ 本格未行使）"
    if len(corpus_roots) != 1:
        return "NOINFO", "multi-corpus-unsupported（给了 %d 个 `--corpus` => 聚合口径未定义）" % len(corpus_roots)
    live, note = corpus_aggregate(corpus_roots[0], max_files=max_files)
    if live is None:
        return "NOINFO", "anchor-uncomputable:%s" % note
    want, why = declared_corpus_anchor()
    if want is None:
        return "NOINFO", "%s（**缺声明 => 不许当绿**）" % why
    if live != want:
        return "NOINFO", "geom-corpus-declared-mismatch（现场=%s 声明=%s）" % (live, want)
    return "PASS", "files=%s live=%s == declared" % (note.split("=")[-1], live)

LEG_CORPUS_MAX_FILES = 4000   # [W153A-#61] `--leg=` 派生语料时的**件数上限**（先写死；超限 ⇒ NOINFO，不哈希）

def leg_mode_corpus_roots(legs):
    """`--leg=` 模式：「该腿**所属语料**」= **腿目录的父目录**（口径先写死，**不许猜**）。
    → (roots|None, why)：多个 `--leg` 的父目录不唯一 ⇒ (None, 具名理由)。"""
    roots = sorted({os.path.dirname(os.path.abspath(p)) for p in legs})
    if len(roots) == 1:
        return roots, ""
    return None, ("multi-leg-parent（%d 个不同的父目录 ⇒ 「该腿所属语料」不唯一：%s）"
                  % (len(roots), ",".join(os.path.basename(r) for r in roots[:3])))

def anchor_for_inputs(corpus_roots, legs):
    """**唯一入口**（[W153A-#61]）：`--corpus=` ⇒ 整份语料；`--leg=` ⇒ 腿的**父目录**（**真判**）。
    ⚠️ 修前 `--leg=` 走 `NOT_APPLICABLE` 且**不传染** ⇒ 顶层可印 `PASS` 而锚从未行使
      （`#59` 预登记 §5.7 自述的「声明过的旁路」）。修后：**派生得出来就真判**，
      派生不出来 ⇒ `NOINFO` ＋ **传染顶层** ⇒ 「锚未行使却顶层绿」这条路径被删掉。
    ⚠️ 只有「聚合 == 声明（全 64 位）」才给 `PASS` ⇒ **派生错永远不会变成绿**。"""
    if corpus_roots:                      # `--corpus=` 优先（与修前的次序语义一致）
        return corpus_anchor_state(corpus_roots)
    if not legs:
        return "NOT_APPLICABLE", "no-input（既没给 `--corpus=` 也没给 `--leg=` ⇒ 本格未行使）"
    roots, why = leg_mode_corpus_roots(legs)
    if roots is None:
        return "NOINFO", "leg-mode-corpus-unresolved（%s）" % why
    st, det = corpus_anchor_state(roots, max_files=LEG_CORPUS_MAX_FILES)
    if st == "PASS":
        return "PASS", "leg-mode（父目录=%s）：%s" % (os.path.basename(roots[0]), det)
    return "NOINFO", "leg-mode-corpus-unresolved（父目录=%s；%s）" % (os.path.basename(roots[0]), det)

TANY  = re.compile(r"^T (\d+) ")
RELRE = re.compile(r"\brel=([0-9.]+)")
EVTRE = re.compile(r"EVT ConfigureNotify win=0x[0-9a-f]+ send_event=(\d) (\d+)x(\d+)@")
SEGRE = re.compile(r"SEG cgeo=(\d+)x(\d+)@")
WIDRE = re.compile(r"WID=0x[0-9a-f]+ name_pattern=\S+ cgeo=(\d+)x(\d+)@")
FGEORE = re.compile(r"fgeo=(\d+)x(\d+)@")
STATERE = re.compile(r"state=\[([^\]]*)\]")
TERM_TOKENS = ("GONE", "OBS_TIMEOUT", "EVT DestroyNotify", "NO_WINDOW")

def parse_ledger(path):
    """→ list[(ep, rel|None, kind, send_event|None, (w,h)|None, raw, (fw,fh)|None, state)]"""
    out = []
    for ln in open(path, errors="replace"):
        m = TANY.match(ln)
        if not m:
            continue
        ep = int(m.group(1)); r = RELRE.search(ln)
        rel = float(r.group(1)) if r else None
        me, ms, mw = EVTRE.search(ln), SEGRE.search(ln), WIDRE.search(ln)
        if me:
            out.append((ep, rel, "EVT", int(me.group(1)), (int(me.group(2)), int(me.group(3))), ln.strip(), None, ""))
        elif ms:
            mf, mst = FGEORE.search(ln), STATERE.search(ln)
            out.append((ep, rel, "SEG", None, (int(ms.group(1)), int(ms.group(2))), ln.strip(),
                        (int(mf.group(1)), int(mf.group(2))) if mf else None, (mst.group(1) if mst else "")))
        elif mw:
            out.append((ep, rel, "WID", None, (int(mw.group(1)), int(mw.group(2))), ln.strip(), None, ""))
        else:
            out.append((ep, rel, "OTH", None, None, ln.strip(), None, ""))
    return out

def read_probe(d):
    p = os.path.join(d, "probe.txt")
    bridge, base, r_ok = "?", None, None
    if not os.path.exists(p):
        return bridge, base, r_ok
    for ln in open(p, errors="replace"):
        if ln.startswith("RESULT "):
            m = re.search(r"\bBRIDGE=(\S+)", ln)
            if m: bridge = m.group(1)
            m = re.search(r"\bBASE=(\d+)x(\d+)@", ln)
            if m: base = (int(m.group(1)), int(m.group(2)))
            m = re.search(r"\br_ok=(\d)", ln)
            if m: r_ok = m.group(1)
    return bridge, base, r_ok

def parse_screen(s):
    m = re.match(r"^(\d+)x(\d+)$", s or "")
    if not m: raise SystemExit("bad --screen=%s（应为 WxH）" % s)
    return (int(m.group(1)), int(m.group(2)))

def analyze_dir(d, screen):
    """→ dict(verdict, why, …)。承重 = B3 的有无（见头部注释的裁定）。"""
    xo = os.path.join(d, "xobs.log")
    bridge, base_probe, r_ok = read_probe(d)
    common = dict(bridge=bridge, r_ok=r_ok, screen=screen)
    if not os.path.exists(xo):
        return dict(common, verdict="NOINFO", why="no-ledger")
    L = parse_ledger(xo)
    if not L:
        return dict(common, verdict="NOINFO", why="empty-ledger")
    end_ep = L[-1][0]
    end_kind = ("TERM:" + L[-1][5].split()[1]) if any(t in L[-1][5] for t in TERM_TOKENS) else "OPEN"
    seg_lines = [x for x in L if x[2] == "SEG"]
    sizes = [x[4] for x in L if x[4]]
    base = base_probe or (sizes[0] if sizes else None)
    base_src = "probe.BASE" if base_probe else "first-observation"
    info = dict(common, base=base, base_src=base_src, end=end_kind,
                seg_changes=len(seg_lines), lines=len(L))
    # 旁证格（不承重、永不相加、不进判词）
    p1 = [(x[1], x[4], x[6]) for x in L if x[2] == "SEG" and x[4] and x[6] and x[4] != x[6]]
    p1_startup = [x for x in p1 if (x[0] or 0.0) < 2.0]
    p1_true = [x for x in p1 if (x[0] or 0.0) >= 2.0]
    p2 = [x for x in L if x[2] == "SEG" and "MAXIMIZED" in x[7] and x[4] != screen]
    info.update(p1_total=len(p1), p1_startup=len(p1_startup), p1_true=len(p1_true), p2_total=len(p2),
                p1_first=(("%.3f" % p1_true[0][0]) if p1_true else "NONE"))
    if base is None:
        return dict(info, verdict="NOINFO", why="no-base")
    if base == screen:
        return dict(info, verdict="NOINFO", why="base_eq_screen（语义不可判：B2/B3 锚不可分辨）")
    m_land = next((x for x in L if x[4] == screen), None)
    if m_land is None:
        return dict(info, verdict="NOINFO", why="no-max-landing（台账里从未出现屏尺寸）")
    b2 = next((x for x in L if x[0] > m_land[0] and x[2] == "EVT" and x[3] == 0 and x[4] == base), None)
    if b2 is None:
        return dict(info, verdict="NOINFO",
                    why="no-B2（无 'WM 真还原' 锚：无 send_event=0 且几何==基准的事件）")
    b3 = next((x for x in L if x[0] > b2[0] and x[2] == "EVT" and x[3] == 0 and x[4] == screen), None)
    d_push = (b3[0] - b2[0]) / 1000.0 if b3 else None
    cover_ms = (end_ep - b2[0]) / 1000.0
    gaps = [L[i][0] - L[i - 1][0] for i in range(1, len(L))]
    gap_med = statistics.median(gaps) / 1000.0 if gaps else 0.0
    info.update(m_land_us=m_land[0], b2_us=b2[0], b3_us=(b3[0] if b3 else None), b2_rel=b2[1],
                d_push_ms=d_push, cover_ms=cover_ms, gap_med_ms=gap_med, t_decl_ms=T_DECL_MS)
    # 诊断标签（**不参与判词**）
    if d_push is None:
        cls, near = "NONE", "NO"
    else:
        cls = "IN_RED_WINDOW" if d_push <= RED_WINDOW_MS else "LATE_PUSH"
        near = "YES" if abs(d_push - RED_WINDOW_MS) < 2.0 * T_DECL_MS else "NO"
    info.update(d_class=cls, near_red_boundary=near)
    # ── 承重判词：B3 的有无 ─────────────────────────────────────────────────────
    if b3 is not None:
        verdict = "FAIL"
        why = ("B3 出现：B2（还原）之后 %.1fms 处几何被推回屏尺寸 ⇒ 缺陷签名（d_class=%s）"
               % (d_push, cls))
    elif cover_ms >= GREEN_WIN_MS:
        verdict, why = "PASS", "B3 全程 NONE ∧ B2 后覆盖 %.0fms ≥ %.0fms ⇒ 还原被保持住" % (cover_ms, GREEN_WIN_MS)
    else:
        verdict, why = "NOINFO", "cover_short（B3 NONE 但 B2 后观测窗仅 %.0fms < %.0fms ⇒ 否定断言不成立）" % (cover_ms, GREEN_WIN_MS)
    # C4：**只**在绿判词上阻断（红判词自带证据，不阻断）
    if verdict == "PASS" and len(seg_lines) == 0:
        verdict, why = "NOINFO", "instrument-deaf（台账 0 条 SEG 变化行 ⇒ 负结论不可采信）"
    info.update(verdict=verdict, why=why)
    return info

# ─────────────────────────── 合成台账（两极化自测）───────────────────────────
def synth(t0=1790000000000000, d_push_ms=None, cover_s=8.6, base=(800, 600), screen=(1280, 1024),
          seg=True):
    L = []
    def T(t_us, rest):
        L.append("T %d rel=%.3f %s" % (t0 + t_us, t_us / 1e6, rest))
    hint = "hints={flags=0x10 PMinSize=1x1 PMaxSize=-1x-1}"
    if seg:
        T(100000, "SEG cgeo=%dx%d@+0+0 frame=0x200480 fgeo=%dx%d@+0+0 state=[FOCUSED] %s"
          % (base[0], base[1], base[0], base[1], hint))
    T(8000000, "EVT ConfigureNotify win=0xc00004 send_event=0 %dx%d@+0+0 above=0x20048f override=0" % screen)
    if seg:
        T(8001000, "SEG cgeo=%dx%d@+0+0 frame=0x200480 fgeo=%dx%d@+0+0 state=[FOCUSED] %s"
          % (screen[0], screen[1], screen[0], screen[1], hint))
    b2 = 13000000
    T(b2, "EVT ConfigureNotify win=0xc00004 send_event=0 %dx%d@+0+0 above=0x20048f override=0" % base)
    if seg:
        T(b2 + 1000, "SEG cgeo=%dx%d@+0+0 frame=0x200480 fgeo=%dx%d@+0+0 state=[FOCUSED] %s"
          % (base[0], base[1], base[0], base[1], hint))
    if d_push_ms is not None:
        T(b2 + int(d_push_ms * 1000), "EVT ConfigureNotify win=0xc00004 send_event=0 %dx%d@+0+0 above=0x20048f override=0" % screen)
        if seg:
            T(b2 + int(d_push_ms * 1000) + 1000, "SEG cgeo=%dx%d@+0+0 frame=0x200480 fgeo=%dx%d@+0+0 state=[FOCUSED] %s"
              % (screen[0], screen[1], screen[0], screen[1], hint))
    T(b2 + int(cover_s * 1e6), "GONE")
    return "\n".join(L) + "\n"

def write_leg(sandbox, name, text, bridge="synthetic", base_txt="800x600@+0+0"):
    d = os.path.join(sandbox, name)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "xobs.log"), "w") as f: f.write(text)
    with open(os.path.join(d, "probe.txt"), "w") as f:
        f.write("TAG=%s\nBRIDGE=%s\nRESULT tag=%s M=M1 R=R2 START_MAX=0 BASE=%s BRIDGE=%s SHIM=none\n"
                % (name, bridge, name, base_txt, bridge))
    return d

def arm_token(role, red, noi):
    """**角色感知**的臂级判词 —— 两个臂的"应有形态"不同，所以判词不同（不许用一个公式糊过去）：
       `fix`  ⇒ `PASS`（每腿无 B3）/`FAIL`（有腿有 B3）/`NOINFO`
       `pre`  ⇒ `RISEUP_OK`（有腿有 B3 = 缺陷复现，**这正是应有形态**）/`NO_RISEUP`（一条都没有 ⇒ 假绿探测器指向）
       `unknown` ⇒ `LISTED`（未分类臂：只列不判）"""
    if role == "pre":
        return "NO_RISEUP" if red == 0 else "RISEUP_OK"
    if role == "unknown":
        return "LISTED"
    return "FAIL" if red else ("NOINFO" if noi else "PASS")

def top_verdict(rows, pair=True):
    """顶层判词（**恒为成对制**：缺一臂 ⇒ `NOINFO`）。`pair` 参数保留兼容，不再改变顶层口径。"""
    from collections import defaultdict
    grp = defaultdict(list)
    for r in rows: grp[r.get("bridge", "?")].append(r)
    arms = {}
    for b, rs in grp.items():
        red = sum(1 for r in rs if r["verdict"] == "FAIL")
        grn = sum(1 for r in rs if r["verdict"] == "PASS")
        noi = len(rs) - red - grn
        role = "fix" if b == FIX_SHA else ("pre" if b == PRE_SHA else "unknown")
        arms[b] = (role, arm_token(role, red, noi), red, grn, noi, len(rs))
    roles = {v[0]: v for v in arms.values()}
    # ⚠️ 本行曾是**伪绿**：`--pair=no` 只给一条**修前臂**腿时，旧式会印出 "fix_arm 全绿 ∧ pre_arm 有回升"
    #    —— 而**压根没有 fix 臂**（本车道 23:42 抓到的自身缺陷）。现已改为**恒成对制**：
    #    缺任一臂 ⇒ 顶层 `NOINFO single-arm`（读臂级行与逐腿 `BEAT` 行）；**没有任何路径能印出"全绿"当顶层 PASS**。
    if not ("fix" in roles and "pre" in roles):
        return "NOINFO", "single-arm（成对判词需修前＋修后两臂同场；在场臂=%s）" % ",".join(sorted(roles))
    if roles["pre"][1] == "NO_RISEUP":
        return "FAIL", "FALSE_GREEN（修前臂一条红都没有 ⇒ 判据作废、须重写）"
    if roles["fix"][1] == "FAIL":
        return "FAIL", "fix_arm（n=%d,red=%d）" % (roles["fix"][5], roles["fix"][2])
    if roles["fix"][1] == "NOINFO":
        return "NOINFO", "fix_arm=NOINFO"
    return "PASS", "fix_arm 全绿 ∧ pre_arm 有回升（RISEUP_OK）"

def top_verdict_with_anchor(rows, a_state, a_detail, pair=True):
    """`top_verdict` 的**外层**：把语料锚的 `NOINFO` **传染**到顶层（`NOT_APPLICABLE` **不传染**）。
    ⚠️ `top_verdict` 本体**一字未动**（它的 12 条既有自测例仍原样跑）。"""
    v, why = top_verdict(rows, pair)
    if a_state == "NOINFO":
        return "NOINFO", "corpus-anchor（%s）｜臂判词=%s（%s）" % (a_detail.split("（")[0], v, why)
    return v, why

def selftest():
    screen = (1280, 1024)
    sb = tempfile.mkdtemp(prefix="geombeat-selftest-")
    cases = [
        ("b3_060",  dict(d_push_ms=60),                   "FAIL",   "B3 出现（Δ=60ms）：派单书父注说'必绿' —— **该方向已作废**，裁定后必红"),
        ("b3_400",  dict(d_push_ms=400),                  "FAIL",   "B3 出现（Δ=400ms）：派单书父注说'必红'，与裁定同向"),
        ("b3_085",  dict(d_push_ms=85),                   "FAIL",   "Δ=85ms：实测缺陷签名（修前臂 64.4–104.3ms 同族）"),
        ("b3_201",  dict(d_push_ms=201),                  "FAIL",   "Δ=201ms：贴红界但 B3 出现即红（Δ 只作诊断）"),
        ("none_ok", dict(d_push_ms=None, cover_s=8.6),    "PASS",   "B3 全程 NONE ∧ 覆盖 8.6s ⇒ 绿"),
        ("none_short", dict(d_push_ms=None, cover_s=1.2), "NOINFO", "B3 NONE 但覆盖仅 1.2s ⇒ 否定断言不成立"),
        ("deaf",    dict(d_push_ms=None, cover_s=8.6, seg=False), "NOINFO", "0 条 SEG 变化行 ⇒ instrument-deaf（C4）"),
        ("basescreen", dict(d_push_ms=None, base=(1280, 1024)), "NOINFO", "BASE==SCREEN ⇒ 语义不可判"),
    ]
    ok = 0; tot = 0
    print("== 单腿两极化自测（合成台账；行格式与真 xobs 逐字同形）")
    for name, kw, want, note in cases:
        d = write_leg(sb, name, synth(**kw), base_txt="%dx%d@+0+0" % kw.get("base", (800, 600)))
        r = analyze_dir(d, screen)
        good = r["verdict"] == want
        tot += 1; ok += 1 if good else 0
        print("   %-12s want=%-7s got=%-7s %-9s %s" % (name, want, r["verdict"], "OK" if good else "MISMATCH", note))
        if r["verdict"] == "NOINFO": print("        why=%s" % r["why"])
    import shutil
    # ① 语料级：修前臂 2 红 + 1 绿（边界例）＋ 修后臂 2 绿 ⇒ 顶层 PASS，且必须登记边界例
    sb2 = tempfile.mkdtemp(prefix="geombeat-corpus-")
    write_leg(sb2, "L-OLD-1", synth(d_push_ms=70),  bridge=PRE_SHA)
    write_leg(sb2, "L-OLD-2", synth(d_push_ms=90),  bridge=PRE_SHA)
    write_leg(sb2, "L-OLD-3", synth(d_push_ms=None), bridge=PRE_SHA)
    write_leg(sb2, "L-NEW-1", synth(d_push_ms=None), bridge=FIX_SHA)
    write_leg(sb2, "L-NEW-2", synth(d_push_ms=None), bridge=FIX_SHA)
    rows = [dict(analyze_dir(os.path.join(sb2, n), screen), leg=n) for n in sorted(os.listdir(sb2))]
    v, why = top_verdict(rows)
    tot += 1; ok += 1 if v == "PASS" else 0
    print("   语料[边界例]  want=PASS    got=%-7s %-9s 修前臂 2 红 1 绿 ⇒ **回升成立**（不许要求'每腿必红'）"
          % (v, "OK" if v == "PASS" else "MISMATCH"))
    # ② 假绿探测器：修前臂全绿 ⇒ 必须 FAIL(FALSE_GREEN)
    sb3 = tempfile.mkdtemp(prefix="geombeat-fakegreen-")
    write_leg(sb3, "L-OLD-1", synth(d_push_ms=None), bridge=PRE_SHA)
    write_leg(sb3, "L-OLD-2", synth(d_push_ms=None), bridge=PRE_SHA)
    write_leg(sb3, "L-NEW-1", synth(d_push_ms=None), bridge=FIX_SHA)
    rows3 = [dict(analyze_dir(os.path.join(sb3, n), screen), leg=n) for n in sorted(os.listdir(sb3))]
    v3, why3 = top_verdict(rows3)
    good3 = (v3 == "FAIL" and "FALSE_GREEN" in why3)
    tot += 1; ok += 1 if good3 else 0
    print("   语料[假绿探测] want=FAIL/FALSE_GREEN got=%s/%s %-9s 修前件全绿 ⇒ 判据作废"
          % (v3, why3.split("（")[0], "OK" if good3 else "MISMATCH"))
    # ③ **单臂不许伪绿**（本车道 23:42 抓到的自身缺陷）：只有修前臂（哪怕它红）⇒ 顶层必须 NOINFO，
    #    且 reason 里**不许**出现"全绿"这类"没在场却声称在场"的措辞。
    sb4 = tempfile.mkdtemp(prefix="geombeat-singlearm-")
    write_leg(sb4, "L-OLD-1", synth(d_push_ms=80), bridge=PRE_SHA)
    rows4 = [dict(analyze_dir(os.path.join(sb4, n), screen), leg=n) for n in sorted(os.listdir(sb4))]
    for pv in (True, False):                       # `pair` 两档都必须 NOINFO（恒成对制）
        v4, why4 = top_verdict(rows4, pair=pv)
        good4 = (v4 == "NOINFO" and "single-arm" in why4 and "全绿" not in why4)
        tot += 1; ok += 1 if good4 else 0
        print("   语料[单臂 pair=%-5s] want=NOINFO got=%-7s %-9s 缺一臂 ⇒ 只给 NOINFO；**不许**印出'全绿'的伪绿"
              % (pv, v4, "OK" if good4 else "MISMATCH"))
    shutil.rmtree(sb2, ignore_errors=True); shutil.rmtree(sb3, ignore_errors=True); shutil.rmtree(sb4, ignore_errors=True)
    # ── 【`#59` 主控裁定 ③ 加严】语料锚的**两极化自测**（5 例；含"python 重实现 == shell 定义"的对拍）──
    #   ⚠️ 这 5 例**独立于**上面 12 例：本格是**新加的判据**，它自己必须能造红、能造绿、能造 NOINFO。
    import json as _json, subprocess as _sp
    sbA = tempfile.mkdtemp(prefix="geombeat-anchor-")
    #   语料 = **真判据可以出 PASS 的三腿**（2 修前红 + 1 修后绿）—— 这样"锚失配 ⇒ 顶层被传染"
    #   才是**真的覆盖了**一个本来会绿的判词（而不是在一个本来 NOINFO 的语料上打转）。
    _leg_a = write_leg(sbA, "L-OLD-1", synth(d_push_ms=70),    bridge=PRE_SHA)
    _leg_b = write_leg(sbA, "L-OLD-2", synth(d_push_ms=90),    bridge=PRE_SHA)
    _leg_c = write_leg(sbA, "L-NEW-1", synth(d_push_ms=None),  bridge=FIX_SHA)
    _rowsA = [dict(analyze_dir(p, screen), leg=os.path.basename(p)) for p in (_leg_a, _leg_b, _leg_c)]
    _base_v, _ = top_verdict(_rowsA)
    good = (_base_v == "PASS")
    tot += 1; ok += 1 if good else 0
    print("   %-16s want=%-9s got=%-9s %-9s（这 3 腿是后 3 例的**基座**：它必须先能 PASS）"
          % ("anchor_base", "PASS", _base_v, "OK" if good else "MISMATCH"))
    live, _n = corpus_aggregate(sbA)
    # ① **python 重实现 == 冻结的 shell 口径**（本格可信的根：口径不许随实现漂）
    sh = _sp.run(["bash", "-c",
                  'cd "%s" && find . -type f | LC_ALL=C sort | xargs sha256sum | sha256sum | cut -d" " -f1' % sbA],
                 capture_output=True, text=True).stdout.strip()
    good = (sh == live and bool(live))
    tot += 1; ok += 1 if good else 0
    print("   %-16s want=%-9s got=%-9s %-9s shell=%s python=%s"
          % ("anchor_alg", "同值", "同值" if good else "DIFF", "OK" if good else "MISMATCH", sh[:16], str(live)[:16]))
    #   ⚠️ **登记表必须放在语料根之外**：本车道第一版把 `reg.json` 写进 `sbA` ⇒ 那个文件**自己**
    #   改变了语料聚合 ⇒ `anchor_ok` 当场判 NOINFO（**是新格自己的自测把它抓出来的**）。已改。
    sbR = tempfile.mkdtemp(prefix="geombeat-reg-")
    regp = os.path.join(sbR, "reg.json")
    def _mkreg(sha):
        _json.dump({"generation": ({} if sha is None else {"geom_corpus": {"sha256": sha}})},
                   open(regp, "w"))
    _old = os.environ.get("GEOMBEAT_REGISTRY")
    try:
        # ② 声明 == 现场 ⇒ PASS ⇒ **不传染**（顶层仍走臂判词）
        _mkreg(live); os.environ["GEOMBEAT_REGISTRY"] = regp
        a1, d1 = corpus_anchor_state([sbA])
        v1, _w1 = top_verdict_with_anchor(_rowsA, a1, d1)
        good = (a1 == "PASS" and v1 == _base_v)
        tot += 1; ok += 1 if good else 0
        print("   %-16s want=%-9s got=%-9s %-9s 顶层=%s（不传染）"
              % ("anchor_ok", "PASS", a1, "OK" if good else "MISMATCH", v1))
        # ③ 声明 ≠ 现场 ⇒ NOINFO ＋ **点名** ＋ **顶层被传染**（PASS → NOINFO）
        _mkreg("0" * 64); os.environ["GEOMBEAT_REGISTRY"] = regp
        a2, d2 = corpus_anchor_state([sbA])
        v2, _w2 = top_verdict_with_anchor(_rowsA, a2, d2)
        good = (a2 == "NOINFO" and "geom-corpus-declared-mismatch" in d2
                and _base_v == "PASS" and v2 == "NOINFO")
        tot += 1; ok += 1 if good else 0
        print("   %-16s want=%-9s got=%-9s %-9s 点名=%s 顶层 %s→%s"
              % ("anchor_mismatch", "NOINFO", a2, "OK" if good else "MISMATCH",
                 "yes" if "geom-corpus-declared-mismatch" in d2 else "NO", _base_v, v2))
        # ④ 缺声明 ⇒ NOINFO（**缺声明 ≠ 通过**）
        _mkreg(None); os.environ["GEOMBEAT_REGISTRY"] = regp
        a3, d3 = corpus_anchor_state([sbA])
        good = (a3 == "NOINFO" and "geom-corpus-undeclared" in d3)
        tot += 1; ok += 1 if good else 0
        print("   %-16s want=%-9s got=%-9s %-9s" % ("anchor_undeclared", "NOINFO", a3, "OK" if good else "MISMATCH"))
        # ⑤ **无输入档** ⇒ NOT_APPLICABLE 且**不传染**（`#61` 改：原例名 `anchor_legmode`，
        #    它断言的是「`--leg` 一律不传染」——那条**已被 `#61` 删掉**，例名与语义就地更正）
        a4, d4 = anchor_for_inputs([], [])
        v4, _w4 = top_verdict_with_anchor(_rowsA, a4, d4)
        good = (a4 == "NOT_APPLICABLE" and "no-input" in d4 and v4 == _base_v)
        tot += 1; ok += 1 if good else 0
        print("   %-16s want=%-9s got=%-9s %-9s 顶层=%s（不传染：两种输入都没给，本格没机会行使）"
              % ("anchor_noinput", "N/A", a4, "OK" if good else "MISMATCH", v4))
        # ⑥ **`--leg=` 真判**（腿的父目录 == 语料根 `sbA`）⇒ PASS，顶层**不受影响**
        _mkreg(live); os.environ["GEOMBEAT_REGISTRY"] = regp   # ⚠️ ④ 刚把登记表改成「缺锚」⇒ 这里必须改回来
        a5, d5 = anchor_for_inputs([], [_leg_a])
        v5, _w5 = top_verdict_with_anchor(_rowsA, a5, d5)
        good = (a5 == "PASS" and "leg-mode" in d5 and v5 == _base_v)
        tot += 1; ok += 1 if good else 0
        print("   %-16s want=%-9s got=%-9s %-9s 顶层=%s（派生语料真判 ⇒ 不传染掉）"
              % ("anchor_leg_ok", "PASS", a5, "OK" if good else "MISMATCH", v5))
        # ⑦ **`--leg=` 派生失败** ⇒ NOINFO ＋ 点名 ＋ **顶层被传染**（PASS → NOINFO）
        #    （登记表此刻是 ⑥ 重新装好的 `live` ⇒ 失败**只能**来自「父目录不是那个语料」）
        _sbX = tempfile.mkdtemp(prefix="geombeat-legsolo-")
        try:
            _leg_x = write_leg(_sbX, "L-OLD-1", synth(d_push_ms=70), bridge=PRE_SHA)
            _rowsX = [dict(analyze_dir(_leg_x, screen), leg="L-OLD-1")]
            a6, d6 = anchor_for_inputs([], [_leg_x])
            good = (a6 == "NOINFO" and "leg-mode-corpus-unresolved" in d6)
            tot += 1; ok += 1 if good else 0
            print("   %-16s want=%-9s got=%-9s %-9s 点名=%s"
                  % ("anchor_leg_unres", "NOINFO", a6, "OK" if good else "MISMATCH",
                     "yes" if "leg-mode-corpus-unresolved" in d6 else "NO"))
            v6, _w6 = top_verdict_with_anchor(_rowsA, a6, d6)
            good = (v6 == "NOINFO" and "corpus-anchor" in _w6)
            tot += 1; ok += 1 if good else 0
            print("   %-16s want=%-9s got=%-9s %-9s 顶层 %s→%s（**旁路已封**）"
                  % ("anchor_leg_prop", "NOINFO", v6, "OK" if good else "MISMATCH", _base_v, v6))
        finally:
            shutil.rmtree(_sbX, ignore_errors=True)
    finally:
        if _old is None: os.environ.pop("GEOMBEAT_REGISTRY", None)
        else: os.environ["GEOMBEAT_REGISTRY"] = _old
        shutil.rmtree(sbA, ignore_errors=True); shutil.rmtree(sbR, ignore_errors=True)
    # ⑥ **真调用形态**：仓根必须来自 bash 侧导出的 `GEOMBEAT_REPO`。
    #   为什么单列一例：本内核跑在 `python3 -` 的 heredoc 上，`__file__` 是 **`<stdin>`** ⇒
    #   若用 `__file__` 反推仓根，跑出来的登记表路径是**静默错的**（本车道实测：
    #   `registry-absent:/home/build/MilBridge/known-red.json`）—— **不报错、只判错**。
    _rr = _repo_root()
    _envrr = os.environ.get("GEOMBEAT_REPO")
    good = (bool(_envrr) and _rr == _envrr and "<stdin>" not in _rr)
    tot += 1; ok += 1 if good else 0
    print("   %-16s want=%-9s got=%-9s %-9s GEOMBEAT_REPO=%s"
          % ("anchor_reporoot", "==bash侧", "==bash侧" if good else "DIFF", "OK" if good else "MISMATCH", str(_envrr)[:40]))
    print("   —— 上面 10 例 = **语料锚格**（`#61` 由 7 例增至 10 例：`anchor_legmode`→`anchor_noinput` ＋"
          + " 新增 `anchor_leg_ok`／`anchor_leg_unres`／`anchor_leg_prop`）；与文件开头的 12 例**分开计**（总数 = 两者之和）——")
    print("GEOMBEAT_SELFTEST=%d/%d" % (ok, tot))
    return 0 if ok == tot else 1

# ─────────────────────────────── 主流程 ─────────────────────────────────────
def main(argv):
    corpus, legs, screen, pair = [], [], (1280, 1024), True
    for a in argv:
        if a == "--selftest": return selftest()
        elif a.startswith("--corpus="): corpus.append(os.path.expanduser(a.split("=", 1)[1]))
        elif a.startswith("--leg="): legs.append(os.path.expanduser(a.split("=", 1)[1]))
        elif a.startswith("--screen="): screen = parse_screen(a.split("=", 1)[1])
        elif a.startswith("--pair="): pair = (a.split("=", 1)[1] != "no")
        elif a in ("-h", "--help"): print("见本文件头注释【用法】"); return 0
    a_state, a_detail = anchor_for_inputs(corpus, legs)   # [W153A-#61] `--leg=` 不再绕行
    if a_state == "PASS":
        print("GEOMCORPUS=PASS %s（现场聚合 == known-red.json 的 generation.geom_corpus.sha256，全 64 位逐字）" % a_detail)
    else:
        print("GEOMCORPUS=NOINFO reason=%s" % a_detail)
    for c in corpus:
        legs += sorted(p for p in glob.glob(os.path.join(c, "*")) if os.path.isdir(p))
    if not legs:
        print("GEOMBEAT=NOINFO reason=no-input（给 --corpus=<root> 或 --leg=<dir>）")
        return 2
    rows = []
    for d in legs:
        r = analyze_dir(d, screen); r["leg"] = os.path.basename(d.rstrip("/"))
        rows.append(r)
        print("BEAT leg=%-24s bridge=%-18s base=%-9s B2_us=%-18s B3_us=%-18s d_push_ms=%-9s d_class=%-14s cover_ms=%-9.1f end=%-22s seg_changes=%-3d verdict=%s"
              % (r["leg"], r.get("bridge", "?"),
                 ("%dx%d" % r["base"]) if r.get("base") else "?",
                 r.get("b2_us", "NONE"), r.get("b3_us") or "NONE",
                 ("%.1f" % r["d_push_ms"]) if r.get("d_push_ms") is not None else "NONE",
                 r.get("d_class", "NONE"), r.get("cover_ms", 0.0), r.get("end", "?"),
                 r.get("seg_changes", 0), r["verdict"]))
        if r["verdict"] == "NOINFO": print("     NOINFO why=%s" % r["why"])
        if r.get("p1_true") or r.get("p2_total"):
            print("     LEAD leg=%s P1_true=%d first_rel=%s P2=%d（**旁证格：不承重、P1 与 P2 永不相加、不进判词**）"
                  % (r["leg"], r.get("p1_true", 0), r.get("p1_first", "NONE"), r.get("p2_total", 0)))
    from collections import defaultdict
    grp = defaultdict(list)
    for r in rows: grp[r.get("bridge", "?")].append(r)
    arm_verdict = {}
    for b, rs in sorted(grp.items()):
        red = sum(1 for r in rs if r["verdict"] == "FAIL")
        grn = sum(1 for r in rs if r["verdict"] == "PASS")
        noi = len(rs) - red - grn
        role = "fix" if b == FIX_SHA else ("pre" if b == PRE_SHA else "unknown")
        v = arm_token(role, red, noi)
        arm_verdict[b] = (role, v, red, grn, noi, len(rs))
        print("ARM bridge=%-18s role=%-8s n=%-3d red=%-3d green=%-3d noinfo=%-3d verdict=%s"
              % (b, role, len(rs), red, grn, noi, v))
        for r in rs:
            if role == "pre" and r["verdict"] == "PASS":
                print("   PRE_ARM_GREEN leg=%s BOUNDARY_CASE=1（修前臂上'无顶回'的腿 —— **边界例，如实登记、不许静默剔除**，也不据此判红）" % r["leg"])
    verdict, reason = top_verdict_with_anchor(rows, a_state, a_detail, pair)
    for b, v in sorted(arm_verdict.items()):
        if v[0] == "unknown" and v[2]:
            print("NOTE unclassified_arm=%s red=%d（**未分类臂**：不参与成对判词，但如实列出、不许静默丢弃）" % (b, v[2]))
    print("LEADSUM P1_total=%d P1_startup=%d P1_true=%d P2_total=%d note=旁证-不承重-永不相加-不进判词 frame_extents=NOT_READ"
          % (sum(r.get("p1_total", 0) for r in rows), sum(r.get("p1_startup", 0) for r in rows),
             sum(r.get("p1_true", 0) for r in rows), sum(r.get("p2_total", 0) for r in rows)))
    tot = len(rows)
    red = sum(1 for r in rows if r["verdict"] == "FAIL")
    grn = sum(1 for r in rows if r["verdict"] == "PASS")
    noi = tot - red - grn
    print("GEOMBEAT=%s reason=%s legs=%d red=%d green=%d noinfo=%d arms=%d load_bearing=B3_presence red_window_ms=%.0f green_win_ms=%.0f t_decl_ms=%.1f pair=%s corpus_anchor=%s"
          % (verdict, reason, tot, red, grn, noi, len(grp), RED_WINDOW_MS, GREEN_WIN_MS, T_DECL_MS, pair, a_state))
    return 0 if verdict == "PASS" else (1 if verdict == "FAIL" else 2)

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
PYEOF
