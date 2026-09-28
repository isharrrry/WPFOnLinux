#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# pts-pages-guard.sh —— `D-G122`（止损无守卫）的牙：**PTS 两页（23/24）的页级降级必须还在**。
#
# 【为什么存在】`#50` 的 `A1`＋`A2`＋`A3` 把「切富文本 23／流文档 24 必死 rc=134」降级成
#   「页级可见降级（洋红占位）＋ 具名行 ＋ 进程不死」。**但这两页不在任何在跑门禁里**
#   （现场机械核：`grep -rn 'FlowDocument|RichTextBox|TASK-0007' verify-all.sh
#     build/integration-wave.sh` = 0 命中；`known-red.json` 5 条无一条相关）
#   ⇒ 该修法**不可回归**：将来谁"顺手"把 A2/A3 改回/删掉，**没有任何自动读数会响**。
#   本牙就是那条"能把它咬回来"的读数（口径句见 `D-G122`）。
#
# 【判据（逐条）】—— **承重**（进 rc）：
#   G1  leg 24 `alive=yes`                      否 ⇒ FAIL
#   G2  leg 23 `alive=yes`                      否 ⇒ FAIL
#   G3  两腿 `app_rc ∉ {134,139}`               否 ⇒ FAIL（134 = `D-G70` 族 abort；139 = 静默 SEGV）
#   G4  leg 24 `magenta ≥ 20000`                否 ⇒ FAIL（页级占位没画出来 / 空白）
#   G5  leg 23 `magenta ≥ 20000`                否 ⇒ FAIL
#   G6  leg 24 `ns == HandyControlDemo.UserControl.FlowDocumentDemo`   否 ⇒ NOINFO
#   G7  leg 23 `ns == HandyControlDemo.UserControl.RichTextBoxDemo`    否 ⇒ NOINFO
#   G8  leg 24 托管侧具名行 `[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage` ∧ `err≠0`  否 ⇒ FAIL
#   G9  leg 23 同上                                                         否 ⇒ FAIL
#   G10（⏪ 2026-09-28 改形态）具名 `entry=` 在位（`unknown` 不算）       否 ⇒ NOINFO(frontier-unnamed)（**不进 rc**；判据文本见 `g10_name_check()` 块内注释）
#   G10b（⏪ `t73`／scribe 2026-09-28 加牙）具名 `entry=` **在在册名单内**（名单源＝native `k_pts_entries[]`，内容锚）  否 ⇒ FAIL(off-roster)（**红并点名、进 rc**）
#   ⏪（`t73`／scribe，2026-09-28；**已按队长 `ts=2026-09-28T21:54` 裁定回正**）`G10` 那句的「**不进 rc**」按**成型口径**读，三支定型：
#     · **无名**（应用侧只记 `entry=unknown`）⇒ `PTS_G10_NAME=PASS form=unnamed` —— 无名是**算出来的状态**，**不是"算不出"** ⇒ **不进 `fails` 也不进 `cannot`**（判词不受扰动）；
#     · **名单源不可读**（`roster_names` 取不到表／表头锚失效）⇒ `NOINFO reason=roster-source-unreadable` ⇒ **折进 `cannot`**（`PTS_GUARD=NOINFO`，rc=2）；
#     · **具名但不在册** ⇒ `FAIL frontier=… off-roster=…` ⇒ **折进 `fails`**（`PTS_GUARD=FAIL`，rc=1）。
#   （本行初版曾把「无名」写成折 `cannot`；按裁定改判 `PASS`，理由＝`NOINFO` 在门禁里同样是 ❌，而「前沿无名」在 `PTS` 长线上是**长期常态** ⇒ 那等于用 `NOINFO` 造长期红。）
#   G10c（⏪ `t76`／scribe 2026-09-28 **域前提修正**）具名 `entry=` **按其域归因**（判序：① PTS 在册表 `k_pts_entries[]` ⇒ `pts-declared`；② 声明树 `upstream/wpf/**/*.cs` 的 `DllImport … EntryPoint="<名>"` 行 ⇒ `dllimport-entry`）  两级都不命中 ⇒ **FAIL(unattributable)**（红并点名、进 `rc`）；声明树不在 ⇒ `NOINFO(decl-tree-absent)`（折 `cannot`）
#   ⏪ 依据（`t76` 现取）：`entry=` 在 native 台账零行时取自**内层异常的入口名**（`PtsCache.Linux.cs` 的 `Describe()`）⇒ 取值域 ＝ **DllImport 入口名**、**不必属 PTS**（实测 `LoSetDoc` ＝ LineServices 族）⇒ `G10b` 的「拿 PTS 名册对拍」**只对 PTS 域成立**；**PTS 域一格不放**（在册表命中即可，未命中就落到 ②③ 两格照判）。
#   G11 `DEV x_up=yes`                          否 ⇒ NOINFO（装置没起来 ⇒ 读数无效，不是红）
#   G12 两腿 `five_stable=yes`                  否 ⇒ NOINFO（跑的过程中件被换）
#
# 【诊断（**不进 rc**）】
#   D1/D2 `colors` 参考带 `800–1200`（实测 851/843）；出带只打 `DIAG`
#   D3    native `err=0` ⇒ 打 `DIAG fake-stub-suspected`（**不判红**：`W86A` §5.1 实测
#         「假 stub 也不能让判据变绿」—— 链上下一个真缺口 `LoCreateContext` 仍在 ⇒ 降级仍是真的）
#   D4    `AE`（点击前后像素差）、D5 `pts_gap_seq`、D6 `log_bytes`
#
# 【三态与判序（与仓内 `r-gate-step.sh` 同款）】
#   rc=0 `PTS_GUARD=PASS` ｜ rc=1 `PTS_GUARD=FAIL` ｜ rc=2 `PTS_GUARD=NOINFO`
#   ⚠️ **判序：有红先红**（`NOINFO` 比 `FAIL` 弱，先用弱结论会把真红洗成"算不出"）；
#      无红但有"判不了" ⇒ `NOINFO`。**`NOINFO` 在门禁里同样是 ❌**。
#
# 【方向口径（`D-G142`／`TASK-0741`）】**口径文本必须在判据件自身**，不许只活在别处的历史 `DECL` 行里：
#   · 洋红（`magenta`）= `0` ⇒ **页级占位缺席**（该页没画出来 ⇒ **未修方向**）；
#   · 洋红 ≥ `20000` ⇒ **占位已画出**（**修复方向**）；
#   · 红条件（方向的**反面**，逐字）：`magenta=0 ∧ 无具名行 ∧ native_gap=0`；**反转必须成对**。
#   · 下面这一行是**唯一机读声明行**；判词行**行尾**带 `direction=` 标记（**前缀语义一字不改**）；
#     本行缺失／与编译常量不符 ⇒ `PTS_DIRECTION=FAIL` ＋ 本步**当场红**（**不许静默绿**）。
# PTS-DIRECTION: absent="magenta=0" present-floor=20000 red-when="magenta=0 AND no-named-line AND native_gap=0" source=TASK-0741 phase=degraded
#   ⚠️【`t12` 的**判据反转**】`phase=degraded`（今天）＝ 上面那套绿条件（降级还在）；
#     `phase=realized`（`TASK-0302` 真实现落地后**同趟**改）＝ 绿条件**反转**为
#     `洋红 = 0 ∧ 无具名行 ∧ native_gap = 0 ∧ 真实排版证据（`ink` > 0）`；
#     两期**共用**不可变量 `I1`（三态完备性）：`(magenta>0 ∧ 具名行在位)` ∨ `(magenta==0 ∧ 无具名行 ∧ ink>0)`；
#     **第三态必红**（"只降级不画"＝空白，不许读成绿 —— 那是 `N2-b`）。
#     `realized` 期缺 `ink` 证据位 ⇒ `NOINFO reason=no-real-layout-evidence`（**永不当绿**）。

# 【反例牙】**本脚本的绿必须能被两极化证伪**，配方（三臂 × 5 腿）见
#   `~/w156a/w67guard/polarity-recipe.md`：
#     ① `A`（现权威五件）⇒ 必 `PASS`  ② `B`（修前成对件 `shim 3e4390c9ec07f621` ＋
#     `pf 6375fabf89ac7fef`）⇒ 必 **`FAIL`**（`app_rc=134` ∧ `alive=no`）
#     ③ `C`（只撤"画占位"：`shim 24e906c194903c8b` ＋ `pf 0018b509567434df`）⇒ 必 **`FAIL`**
#     （`alive=yes` 但 `magenta=0`）。`--selftest` 用**合成用例**跑这三态（不需要 X、不需要应用）。
#
# 【成本（实测，`~/w156a/w67guard/report.md` §5）】跑腿 ≈ 27 s/腿（应用冷启 8 s ＋ 点击 ≈3 s ＋
#   收尾），`--legs`（只判已落盘证据）**< 0.2 s**、零 `dotnet`。
#
# 【用法】
#   bash pts-pages-guard.sh --legs <dir>      # 只判（纯读、无 X、<0.2 s）—— 门禁里用这一支
#   bash pts-pages-guard.sh --selftest        # 合成用例两极化（无 X、无应用）
#   bash pts-pages-guard.sh --c4-ledger <dir> # `t109`：C4 定名**以台账为准**（两直方图分开印；台账缺 ⇒ NOINFO）
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

MAGENTA_FLOOR="${PTS_GUARD_MAGENTA_FLOOR:-20000}"

# ── 小工具 ───────────────────────────────────────────────────────────────────
field() { printf '%s' "$1" | grep -o -m1 "[[:space:]]$2=[^[:space:]]*" | head -1 | sed "s/^[[:space:]]$2=//"; }

# ── native 在册名单（**内容锚**；`t73` 加牙：`g10_name_check` 的名单源）──────────────
#   ⚠️ 名单**不写死任何单个名字**：现取 native 在册表 `k_pts_entries[]`。
#      **内容锚** = 该表的表头行 → 紧随的首个 `};`（无行号、无字面名字）。
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROSTER_SRC="${PTS_G10_ROSTER_SRC:-$(cd "$SELF_DIR/../../.." && pwd)/src/WpfGfx.Linux.Native/src/win32_pts.c}"
roster_names() {   # 印在册名（每行一个）；源缺失／表头锚取不到 ⇒ 空输出 ＋ rc=1（调用方**不许当绿**）
  [ -f "$ROSTER_SRC" ] || return 1
  sed -n '/^static const char \*const k_pts_entries\[\] = {/,/^};/p' "$ROSTER_SRC" \
    | sed -n 's/^[[:space:]]*"\([A-Za-z0-9_]*\)",\{0,1\}[[:space:]]*$/\1/p'
}

# ── 入口名的**声明树**（非 PTS 域的**内容锚**；`t76` 加）──────────────────────────
#   **域判定（两级，全部内容锚；不许靠猜、不许按名字形状启发式）**：
#     ① `k_pts_entries[]` 命中 ⇒ 域 ＝ `pts-declared`（PTS 在册表是 **PTS 域的定义**）；
#     ② 未命中 ⇒ 在**声明树** `upstream/wpf/**/*.cs` 里找该入口的 **P/Invoke 声明**
#        （内容锚 = **同一行**同时含 `DllImport` 与 `EntryPoint="<名>"`）⇒ 域 ＝ `dllimport-entry`；
#     ③ 两级都不命中 ⇒ 域 ＝ `unattributable` ⇒ **红并点名**。
#   ⚠️ 判序写死：**先在册表、后声明树**（一名同时在两处 ⇒ 归 **PTS 域**，按 PTS 域办）。
#   ⚠️ 声明树不在 ⇒ 非 PTS 域**判不了** ⇒ `NOINFO(reason=decl-tree-absent)`（**永不当绿**）。
#   依据（现场）：`entry=` 在 native 台账零行时取自**内层异常的入口名**
#   （`build/PresentationFramework.Linux/PtsCache.Linux.cs` 的 `Describe()`）⇒ 取值域 ＝ **DllImport 入口名**，
#   不必属 PTS（实测 `LoSetDoc` 属 LineServices 族：`upstream/…/TextFormatting/LineServices.cs` 的 `DllImport` 行）。
DECL_TREE="${PTS_G10_DECL_TREE:-$(cd "$SELF_DIR/../../.." && pwd)/upstream/wpf}"
#   ⏪ dated **收紧（`t82`／scribe，2026-09-28；`t77` 的 `F1` 真缺陷）**：旧锚只要求「同一行同时出现
#     `DllImport` 与 `EntryPoint="<名>"`」⇒ **不分辨「声明」与「注释/字面量」**：一条注释里写下这两串
#     就能把任意名字判绿（现取复现：假树只有一行注释 ⇒ `PASS observed=… domains=dllimport-entry`）。
#     新锚（**只吃真声明**，四条合取；证据＝现盘 `upstream/wpf` 全树实测 **548/548** 真声明零漏）：
#       ① **属性起始行**：`^[[:space:]]*\[[[:space:]]*DllImport[[:space:]]*\(`（⇒ 注释行 `//`／`/*`／`* `、
#          字符串字面量行**在形态上就不成立**）；
#       ② 该**属性块内**（本行起至首个 `]`，最多 6 行）含 `EntryPoint[[:space:]]*=[[:space:]]*"<名>"`；
#       ③ 属性块之后 ≤3 个**非空行**内出现 `extern`（＝真的是 P/Invoke 方法，不是孤零零一条属性）；
#       ④ **先剥注释**：行注释 `//…` 截断、块注释 `/* … */` 逐段剥掉（跨行状态 `inb`）⇒ 块注释里整段
#          「声明」不再命中（本席另造夹具真实测：修前 `PASS` ⇒ 修后 `FAIL`）。
#   ⏪ `t109`（2026-09-29）**`t105` 的 `F-2`：补第二支形态「方法名约定」** —— 现取：`CreateDocContext` 的
#     **显式** `EntryPoint = "CreateDocContext"` 在 `upstream/wpf` 全树命中 **0**；它是按**方法名约定**声明的
#     （`upstream/…/MS/Internal/PtsHost/Pts.cs:3091` `internal static extern int CreateDocContext(…)`，属性在上一行）。
#     ⇒ 本支（**仅当该属性块内没有 `EntryPoint=` 时**才走）：属性起始行（同 ①）＋ 其后 ≤3 个非空行内真的 `extern`
#     ＋ **成员名（`(` 前最后一个标识符）逐字等于入口名** ⇒ 命中并印声明位。**不放松**第一支的形态要求。
#     ⚠️ **树范围不收紧**（仍是 `upstream/wpf/**/*.cs`）：域的定义是「**该入口名在其声明树里对拍上**」，
#        按目录形状（例如只扫 `TextFormatting/**`）收窄会把这个**域定义**换成**路径启发式** ⇒ 其它族
#        （`Fs*`／`Nl*`／未来新族）的真声明会被漏掉。⇒ 只收紧**锚的形态**，不动**域的射程**。
decl_hit() {   # <名> ⇒ 印**真声明**的首个声明位 `file:line`；无命中／树不在 ⇒ 空输出 ＋ rc=1
  local nm="$1" f out=""
  [ -d "$DECL_TREE" ] || return 1
  while IFS= read -r f; do
    out="$(awk -v nm="$nm" '
      function strip(l,   p, q, head, rest, n) {
        if (inb) { if (index(l, "*/") > 0) { l = substr(l, index(l, "*/") + 2); inb = 0 } else return "" }
        n = 0
        while (index(l, "/*") > 0 && n < 8) {
          n++
          p = index(l, "/*"); head = substr(l, 1, p - 1); rest = substr(l, p + 2)
          q = index(rest, "*/")
          if (q > 0) { l = head substr(rest, q + 2) } else { l = head; inb = 1; break }
        }
        p = index(l, "//"); if (p > 0) l = substr(l, 1, p - 1)
        return l
      }
      { C[FNR] = strip($0) }
      END {
        for (i = 1; i <= FNR; i++) {
          if (C[i] !~ /^[[:space:]]*\[[[:space:]]*DllImport[[:space:]]*\(/) continue
          txt = C[i]; j = i
          while (txt !~ /\]/ && j < i + 5 && j < FNR) { j++; txt = txt " " C[j] }
          has_ep = (txt ~ /EntryPoint[[:space:]]*=/)
          if (!has_ep) {
            # ⏪ `t109`（`t105` 的 `F-2`）：**方法名约定**声明 —— `[DllImport(…)]` 块内**没有** `EntryPoint=` 时，
            #   入口名**就是紧随其后的成员名**（现场：`Pts.cs:3091` 的 `CreateDocContext`，显式 `EntryPoint=` 全树命中 0）。
            #   形态仍要求「真属性起始行」＋「≤3 个非空行内真的 `extern`」＋「成员名逐字等于该入口名」⇒ 注释骗不过（同 `t82` 口径）。
            seenx = 0
            for (k = j + 1; k <= FNR && seenx < 3; k++) {
              if (C[k] ~ /[^[:space:]]/) {
                seenx++
                if (C[k] ~ /(^|[^A-Za-z0-9_])extern([^A-Za-z0-9_]|$)/) {
                  m = C[k]
                  if (match(m, /[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(/)) {   # `(` 前那个标识符（成员名）
                    m = substr(m, RSTART, RLENGTH); sub(/[[:space:]]*\($/, "", m)
                  } else { m = "" }
                  if (m == nm) { print FILENAME ":" i; exit }
                }
              }
            }
            continue
          }
          if (txt !~ ("EntryPoint[[:space:]]*=[[:space:]]*\"[[:space:]]*" nm "[[:space:]]*\"")) continue
          seen = 0
          for (k = j + 1; k <= FNR && seen < 3; k++) {
            if (C[k] ~ /[^[:space:]]/) {
              seen++
              if (C[k] ~ /(^|[^A-Za-z0-9_])extern([^A-Za-z0-9_]|$)/) { print FILENAME ":" i; exit }
            }
          }
        }
      }
    ' "$f" 2>/dev/null)"
    [ -n "$out" ] && break
  done < <(grep -rl --include='*.cs' -E '^[[:space:]]*\[[[:space:]]*DllImport[[:space:]]*\(' "$DECL_TREE" 2>/dev/null | LC_ALL=C sort)
  [ -n "$out" ] || return 1
  printf '%s' "$out"
}

# ── 方向口径闸（`TASK-0741`：口径**自证**；坏 ⇒ 响亮）────────────────────────
DIR_TOKEN=""; DIR_RC=0
G10_RC=0; G10_TOKEN="g10-name-PASS"
direction_gate() {   # ⚠️ **绝不可用命令替换调用**（子壳里赋的 DIR_TOKEN 会丢）⇒ 直接调用后读 DIR_RC/DIR_TOKEN
  local line fl
  line="$(grep -m1 -E '^#[[:space:]]*PTS-DIRECTION:' "$0" 2>/dev/null || true)"
  DIR_TOKEN="in-file"; DIR_RC=0
  if [ -z "$line" ]; then
    DIR_TOKEN="missing"; DIR_RC=1
    echo "PTS_DIRECTION=FAIL reason=directive-absent expected=in-file-self-declared"
    echo "  ∟ \`D-G142\`：方向口径单点存在于别处 ⇒ 本件不自证 ⇒ **不许静默绿**"
    return 1
  fi
  PHASE="$(printf '%s' "$line" | sed -n 's/.*phase=\([a-z]*\).*/\1/p')"
  case "${PHASE:-}" in
    degraded|realized) ;;
    *) DIR_TOKEN="phase-missing-or-invalid"; DIR_RC=1
       echo "PTS_DIRECTION=FAIL reason=phase-missing-or-invalid got=${PHASE:-none} expected=degraded|realized（t12 判据反转的口径位）"
       return 1 ;;
  esac
  fl="$(printf '%s' "$line" | sed -n 's/.*present-floor=\([0-9][0-9]*\).*/\1/p')"
  if [ -z "$fl" ] || [ "$fl" != "$MAGENTA_FLOOR" ]; then
    DIR_TOKEN="floor-mismatch"; DIR_RC=1
    echo "PTS_DIRECTION=FAIL reason=floor-mismatch directive=${fl:-none} compiled=$MAGENTA_FLOOR"
    return 1
  fi
  return 0
}

# ── 判读一份证据目录 ─────────────────────────────────────────────────────────
#
# ⏪ **dated 口径入件（`t14`／W2·B-8，读时 2026-09-28T16:02:39+0800）**：本判据件的**射程边界**（原先只写在 `build/MilBridge/P0-mvp-pts-report.md`，现**搬进判据件自身**）：
#   · **本步只读 `leg_*.env` 的列，不读 `entry=` ⇒ 它的绿对"前沿位移"零证据力。**
#   ⏪ **dated 更正（`t73`／scribe，2026-09-28）**：上面那半句里的「**不读 `entry=`**」**与事实不符**、按实写 —— 本步**确实读** `entry=`（就是 `g10_name_check`），只是它**只报形态**（在册名单／无名／名单源不可读）、**不承担名字归因**，「其绿对前沿位移零证据力」这个**结论**仍成立（归因在 `pts-gap-count-check.sh` 的具名前沿判据）。来源＝队长 `t69` 复核入册精度（提交 `6e5cd74`）。
#   · 因此本件**自带一条具名对拍**：件头 `G10` 描述的 `entry=<名>` 与 `--legs <dir>/app_g1.log` 的**现取前沿名**必须**逐字相同** ⇒ 不同即 `FAIL` 并点名（`PTS_G10_NAME=FAIL header=… observed=…`）；算不出来（缺件/无日志）⇒ `NOINFO`，**不许当绿**。
#   · ⚠️ **`verify-all.sh` 的行号必须现取、不许写死**（历史在册句引 `:1173`，现取命中行不是它）⇒ 本件不写步号、不写行号。
# ⏪ **dated 更正（`t73`／scribe，2026-09-28；只收紧不放松）**：上面 `【t14】` 那条「件头具名 ⇔ 现取前沿**逐字相同**」的对拍**作废**（它的被比量是**写死的一个名字**；`t63` 关掉该缺口后前沿结构性无名 ⇒ 老实现**早退**、判词行缺席）。`G10` 那句里残留的旧名字**只是历史文字、零承重**（判据不再读它 —— 现场可证：把 `app_g1.log` 的具名换成**不在册**的名字，判据仍**必红**，见 `--g10-name` 腿）。现判据 = 件头 `G10`／`G10b` 两行 ＋ `g10_name_check()` 块内 ⏪ 三条。
# 【`t14`／W2·B-8】件头 G10 具名 ⇔ 现取前沿（**口径搬进判据件自身**；不符 ⇒ 红并点名；算不出 ⇒ NOINFO）
g10_name_check() {
  # ⏪ dated 更正（队长，2026-09-28；本块即判据文本，按 D-G142 口径活在本件内）：
  #   本函数**不再**从件头抓写死的名字、也不再与现取前沿做相等比对 —— 那是**自指**设计
  #   （判据从自己的注释取"期望名"），且在前沿**结构性无名**时（`t63` 把 `entry=LoCreateContext`
  #   关成 `3→0` 之后，应用侧只记 `entry=unknown`）会把一个**合法状态**判成红，并**早退**
  #   吞掉 `PTS_GUARD=` 判词行（现场：`rc=1` 且输出只有 `PTS_G10_NAME=FAIL` 一行）。
  #   新形态（**职责分离、不放宽**）：本函数只报**形态**，**不进 rc**：
  #     · 无具名 entry（只有 `unknown` / 空） ⇒ `NOINFO(reason=frontier-unnamed)`
  #     · 有具名 entry ⇒ `PASS observed=<名>`；多名字 ⇒ 附 `names=<n>`
  #   「名字是否可归因 / 是否假进度」由 `pts-gap-count-check.sh` 的具名前沿判据与它的
  #   `FAKE-PROGRESS` 腿承担（`t63` 已真跑兑现）；本函数不再重复承担那条判据。
  # ⏪ dated 更正（`t73`／scribe，2026-09-28；**只收紧、不放松**）：上面那条新形态**缺一半牙** ——
  #   它把「具名但**不在册**」也判 `PASS`（`obs` 非空即绿）⇒ 一个拼错/伪造的名字能拿到绿。
  #   本条补的正是**形态**的另一半（仍**不写死任何单个名字**）：
  #     · `obs` 非空 ∧ **在在册名单内**（`roster_names` 现取自 native `k_pts_entries[]`）⇒ `PASS`；
  #     · `obs` 非空 ∧ **不在名单内** ⇒ `PTS_G10_NAME=FAIL … off-roster=…`（**红并点名**）；
  #     · 名单源缺失／表头锚取不到 ⇒ `NOINFO reason=roster-source-unreadable`（**永不当绿**）。
  #   折 rc 口径（`judge_legs` 侧）：`FAIL` 进 `fails` ⇒ `PTS_GUARD=FAIL`；`NOINFO` 进 `cannot` ⇒
  #   `PTS_GUARD=NOINFO` —— 依据＝本件第 `32`–`35` 行自declared 的判序，**不把"判不了"读成绿**。
  #   ⏪ **`ts=2026-09-28T21:54 队长裁定（回正）**：上面队长那条的「无具名 ⇒ `NOINFO`」**改判 `PASS(form=unnamed)`**
  #     —— 无名是「**算出来的状态**」（应用侧确实没有具名 `entry=`），**不属"判不了"**；只有**名单源取不到**才是
  #     `NOINFO`。⇒ 三支定型：**无名 ⇒ `PASS`（不进 `fails`／`cannot`）｜名单源不可读 ⇒ `NOINFO`（折 `cannot`）
  #     ｜具名但名单外 ⇒ `FAIL(off-roster)`（折 `fails`）**。
  #   ⏪ dated 更正（`t76`／scribe，2026-09-28；**域前提修正，不放宽 `G10b`**）：上面那条把
  #     「名单外」一律判 `FAIL` —— 它的**域前提是**「`entry=` 恒为 PTS 名」（拿 `k_pts_entries[]` 对拍）；
  #     实测该前提**不成立**：`entry=` 取自**内层异常的入口名**（`PtsCache.Linux.cs` 的 `Describe()`）
  #     ⇒ 取值域 ＝ **DllImport 入口名**，**不必属 PTS**（现场 `LoSetDoc` ＝ LineServices 族）
  #     ⇒ 老形态会把一个**合法状态**判成**常驻红**。新形态 **按域分格**（判序写死、两级内容锚）：
  #       · ① `k_pts_entries[]` 命中 ⇒ `pts-declared`（**G10b 一格不放**：PTS 域仍只在在册表内取绿）；
  #       · ② 未命中 ∧ 声明树里命中 `DllImport … EntryPoint="<名>"` ⇒ `dllimport-entry` ⇒ 该格绿，
  #            并**点名声明的 `file:line`**（`decl=` 字段）；**不**拿 PTS 名册去判它；
  #       · ③ 两级都不命中 ⇒ `unattributable` ⇒ **红并点名**（`off-roster=` 字段原样保留）；
  #       · 声明树不在 ⇒ `NOINFO(reason=decl-tree-absent)`（**永不当绿**）。
  #     ⚠️ 只**增字段**（`domains=`／`decl=`），三态与既有字段（`frontier=`／`off-roster=`／`roster=`／
  #        `observed=`／`names=`／`form=`／`reason=`）**一个不减**。
  local dir="$1" obs names_all n_names roster n_roster off nm
  obs="$(grep -o 'entry=[A-Za-z0-9_]*' "$dir/app_g1.log" 2>/dev/null | sed 's/^entry=//' | grep -v '^unknown$' | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
  names_all="$(grep -ao 'entry=[A-Za-z0-9_]*' "$dir/app_g1.log" 2>/dev/null | sed 's/^entry=//' | grep -v '^unknown$' | LC_ALL=C sort -u)"
  n_names="$(printf '%s\n' "$names_all" | awk 'NF{n++} END{print n+0}')"
  if [ -z "$obs" ]; then
    echo "PTS_G10_NAME=PASS form=unnamed reason=frontier-unnamed（应用侧无具名 entry= ＝**算出来的形态**、不是「算不出」⇒ 本判据按形态通过；名字归因由 pts-gap-count-check.sh 的具名前沿判据承担）"
    G10_RC=0; G10_TOKEN="g10-name-form-unnamed"
    return 0
  fi
  roster="$(roster_names)"
  n_roster="$(printf '%s\n' "$roster" | awk 'NF{n++} END{print n+0}')"
  if [ "$n_roster" -eq 0 ]; then
    echo "PTS_G10_NAME=NOINFO reason=roster-source-unreadable src=$ROSTER_SRC frontier=$obs（**在册名单取不到 ⇒ 判不了 ⇒ 永不当绿**）"
    G10_RC=2; G10_TOKEN="g10-name-roster-source-unreadable"
    return 0
  fi
  # ── 按域分格（`t76`）：① 在册表 ⇒ pts-declared｜② 声明树命中 ⇒ dllimport-entry｜③ 都不命中 ⇒ unattributable
  local doms="" off="" decl="" nm2 dom hit tree_absent=0
  for nm2 in $names_all; do
    case $'\n'"$roster"$'\n' in
      *$'\n'"$nm2"$'\n'*) dom="pts-declared" ;;
      *)
        if [ ! -d "$DECL_TREE" ]; then
          dom="tree-absent"; tree_absent=1
        else
          hit="$(decl_hit "$nm2")"
          if [ -n "$hit" ]; then
            dom="dllimport-entry"; [ -n "$decl" ] || decl="$hit"
          else
            dom="unattributable"; off="$off$nm2,"
          fi
        fi ;;
    esac
    case ",$doms," in *",$dom,"*) ;; *) doms="${doms:+$doms,}$dom" ;; esac
  done
  if [ -n "$off" ]; then
    echo "PTS_G10_NAME=FAIL frontier=$obs off-roster=${off%,} roster=$n_roster domains=$doms decl=${decl:-none}（域归因**失败**：该名**既不在 PTS 在册表、也无「DllImport…EntryPoint=」声明位** ⇒ 红并点名；声明树=$DECL_TREE）"
    # ⏪ `t109`（`t105` 的 `F-3`／判据 `P4`）：**给「必红并点名」补一个可判 token 载体** ——
    #   `P4` 期望的 `reason=entry-name-not-backtraceable` 在 `tools/**` 里现取**命中 0**（只有 `ledger-nonzero-frontier-unchanged`
    #   在册）⇒ 本行**行尾追加**该 token（**判据件一字不删**：旧句仍是新行的逐字前缀）。
    echo "  reason=entry-name-not-backtraceable name=${off%,} decl_tree=$DECL_TREE（该名在声明树里**回溯不上**：既非显式 \`EntryPoint=\`，也非「DllImport 成员名」形态）"
    G10_RC=1; G10_TOKEN="g10-name-off-roster(${off%,})"
    return 0
  fi
  if [ "$tree_absent" = 1 ]; then
    echo "PTS_G10_NAME=NOINFO reason=decl-tree-absent tree=$DECL_TREE frontier=$obs roster=$n_roster（非 PTS 域的声明树不在 ⇒ **判不了** ⇒ 永不当绿）"
    G10_RC=2; G10_TOKEN="g10-name-decl-tree-absent"
    return 0
  fi
  if [ "$doms" = "pts-declared" ]; then
    echo "PTS_G10_NAME=PASS observed=$obs names=$n_names roster=$n_roster domains=$doms（形态判据：具名行**在在册名单内**；PTS 域不写死任何名字）"
  else
    echo "PTS_G10_NAME=PASS observed=$obs names=$n_names roster=$n_roster domains=$doms decl=${decl:-none}（**域前提修正**：非 PTS 域判定为**该入口名在声明树里对拍上**（内容锚「DllImport … EntryPoint=<名>」，声明位见 decl 字段）⇒ 该格绿并将名字与声明位如实点名；**不**拿 PTS 在册表判它）"
  fi
  G10_RC=0; G10_TOKEN="g10-name-PASS"
  return 0
}

judge_legs() {
  local dir="$1"
  local fails=() cannot=() diags=()
  # G10 形态三态（`t73`／scribe）：**不早退** ⇒ 判词行必在场；红进 `fails`、`NOINFO` 进 `cannot`
  g10_name_check "$dir"
  case "${G10_RC:-0}" in
    1) fails+=("$G10_TOKEN") ;;
    2) cannot+=("$G10_TOKEN") ;;
  esac
  local k alive rc mag colors ns msite merr nerr ngap ae seq logb ink
  direction_gate || true
  if [ "$DIR_RC" -ne 0 ]; then
    echo "PTS_GUARD=FAIL legs=0/2 fails=direction($DIR_TOKEN) cannot=- diag=- direction=$DIR_TOKEN"
    return 1
  fi

  [ -d "$dir" ] || { echo "PTS_GUARD=NOINFO reason=legs-dir-absent dir=$dir direction=$DIR_TOKEN"; return 2; }

  # ── 装置自证（缺失 ⇒ NOINFO，不是红）────────────────────────────────────────
  local dev="$dir/device.txt"
  local xup="-"
  if [ -f "$dev" ]; then xup="$(grep -o -m1 'X_UP=[a-z]*' "$dev" | head -1 | cut -d= -f2)"; fi
  [ -n "${xup:-}" ] || xup="-"
  if [ "$xup" != "yes" ]; then
    echo "PTS_GUARD=NOINFO reason=device-x-not-up x_up=$xup direction=$DIR_TOKEN detail=<缺 device.txt 或 X_UP≠yes ⇒ 本趟读数无效>"
    return 2
  fi

  local seen24=0 seen23=0
  local ev
  for k in 24 23; do
    ev="$dir/leg_$k.env"
    if [ ! -s "$ev" ]; then
      cannot+=("leg$k(env-absent)")
      continue
    fi
    local line; line="$(grep -m1 '^LEG ' "$ev" 2>/dev/null)"
    local nline; nline="$(grep -m1 '^NAMED ' "$ev" 2>/dev/null)"
    local dline; dline="$(grep -m1 '^DEV ' "$ev" 2>/dev/null)"
    if [ -z "$line" ]; then cannot+=("leg$k(LEG-line-absent)"); continue; fi
    [ "$k" = 24 ] && seen24=1 || seen23=1

    alive="$(field "$line" alive)"; rc="$(field "$line" app_rc)"
    mag="$(field "$line" magenta)"; colors="$(field "$line" colors)"; ns="$(field "$line" ns)"
    ae="$(field "$line" ae)"; ink="$(field "$line" ink)"
    merr="$(field "${nline:-}" err)"
    ngap="$(field "${nline:-}" native_gap)"; nerr="$(field "${nline:-}" native_err)"

    # 空侧必须响亮失败（纪律 27：解析任一侧为空 ⇒ 不许静默判等）
    case "${alive:-}" in ''|-) cannot+=("leg$k(alive-unparsable)"); continue;; esac
    case "${rc:-}"    in ''|*[!0-9]*) cannot+=("leg$k(app_rc-unparsable)"); continue;; esac
    case "${mag:-}"   in ''|*[!0-9]*) cannot+=("leg$k(magenta-unparsable)"); continue;; esac

    # G11/G12 装置自证
    local fstable; fstable="$(field "$dline" five_stable)"
    case "${fstable:-}" in yes|YES) ;; *) cannot+=("leg$k(five-stable=$fstable)");; esac

    # G6/G7 身份牙：点错对象 ⇒ 判不了（不许判绿，也不许判红）
    local exp="$k"; case "$k" in 24) exp="HandyControlDemo.UserControl.FlowDocumentDemo";; 23) exp="HandyControlDemo.UserControl.RichTextBoxDemo";; esac
    if [ "${ns:-}" != "$exp" ]; then cannot+=("leg$k(ns=$ns≠$exp)"); fi

    # G1/G2 活着
    [ "$alive" = yes ] || fails+=("leg$k-not-alive(alive=$alive)")
    # G3 退出码黑名单
    case "$rc" in 134|139) fails+=("leg$k-abort(app_rc=$rc)");; esac
    if [ "$PHASE" = realized ]; then
      # ── realized 期：绿条件**反转**（`t12`）────────────────────────────────
      [ "$mag" -eq 0 ] || fails+=("leg$k-placeholder-still-drawn(magenta=$mag≠0∧phase=realized)")
      [ "${merr:-}" = "-" ] || [ -z "${merr:-}" ] || fails+=("leg$k-named-line-still-present(err=$merr)")
      case "${ink:-}" in
        ''|'-') cannot+=("leg$k(no-real-layout-evidence)") ;;        # 证据位缺失 ⇒ NOINFO（**不是绿**）
        *[!0-9]*) cannot+=("leg$k(ink-unparsable=$ink)") ;;
        *) [ "$ink" -gt 0 ] || fails+=("leg$k-no-real-ink(ink=$ink)") ;;
      esac
    else
      # ── degraded 期（今天）：止损必须还在 ────────────────────────────────
      [ "$mag" -ge "$MAGENTA_FLOOR" ] || fails+=("leg$k-placeholder-missing(magenta=$mag<$MAGENTA_FLOOR)")
      [ "${merr:-}" = "-10000" ] || fails+=("leg$k-named-line(missing-or-err=$merr)")
    fi
    # D1/D2 诊断
    case "${colors:-}" in ''|*[!0-9]*) diags+=("leg$k-colors=$colors");;
      *) if [ "$colors" -lt 800 ] || [ "$colors" -gt 1200 ]; then diags+=("leg$k-colors-out-of-band=$colors"); fi;; esac
    if [ "${ae:-}" = "0" ]; then diags+=("leg$k-AE=0(点击前后无像素差)"); fi
  done

  # G10 native 台账（**两腿合并判**：至少一条）
  local ngap_total=0
  for k in 24 23; do
    ev="$dir/leg_$k.env"; [ -s "$ev" ] || continue
    local g; g="$(field "$(grep -m1 '^NAMED ' "$ev" 2>/dev/null)" native_gap)"
    case "${g:-}" in ''|*[!0-9]*) ;; *) ngap_total=$((ngap_total + g));; esac
  done
  if [ "$PHASE" = realized ]; then
    [ "$ngap_total" -eq 0 ] || fails+=("native-ledger-still-present(PTS_GAP n=$ngap_total∧phase=realized)")
  else
    [ "$ngap_total" -ge 1 ] || fails+=("native-ledger-absent(PTS_GAP n=0)")
  fi

  # D3 假 stub 诊断（**不判红**）
  for k in 24 23; do
    ev="$dir/leg_$k.env"; [ -s "$ev" ] || continue
    local ne; ne="$(field "$(grep -m1 '^NAMED ' "$ev" 2>/dev/null)" native_err)"
    if [ "${ne:-}" = "0" ]; then diags+=("leg$k-native-err=0(fake-stub-suspected)"); fi
  done

  # ── `I1`（`t12`）：三态完备性 —— 两期共用，**第三态必红** ──────────────────────
  #   (a) 降级形态：`magenta>0 ∧ 具名行在位`；(b) 真实形态：`magenta==0 ∧ 无具名行 ∧ ink>0`。
  #   两者都不成立（例如"只降级不画"⇒ magenta=0 但具名行仍在）⇒ 红（`N2-b`）。
  for k in 24 23; do
    ev="$dir/leg_$k.env"; [ -s "$ev" ] || continue
    local l1 n1 m1 i1
    l1="$(grep -m1 '^LEG ' "$ev" 2>/dev/null)"; n1="$(grep -m1 '^NAMED ' "$ev" 2>/dev/null)"
    m1="$(field "$l1" magenta)"; i1="$(field "$l1" ink)"
    case "${m1:-}" in ''|*[!0-9]*) continue ;; esac
    local named=0; [ "$(field "$n1" managed_unavail)" = 1 ] && named=1
    if [ "$m1" -gt 0 ] && [ "$named" = 1 ]; then :            # (a) 降级形态齐
    elif [ "$m1" -eq 0 ] && [ "$named" = 0 ]; then :          # (b) 真实形态（ink 由上面 phase 分支判）
    else fails+=("leg$k-I1-incomplete(magenta=$m1 named=$named ⇒ 既非降级也非真实：空白/半通不许读成绿)"); fi
  done
  local crit="magenta_floor=$MAGENTA_FLOOR phase=$PHASE alive24=$([ "$seen24" = 1 ] && echo ? || echo -) "
  local v
  if [ "${#fails[@]}" -gt 0 ]; then
    v="FAIL"
  elif [ "${#cannot[@]}" -gt 0 ]; then
    v="NOINFO"
  else
    v="PASS"
  fi
  printf 'PTS_GUARD=%s legs=%s/%s fails=%s cannot=%s diag=%s direction=%s phase=%s\n' \
    "$v" "$(ls "$dir"/leg_*.env 2>/dev/null | wc -l)" \
    "$((seen24 + seen23))" \
    "$( [ "${#fails[@]}" -gt 0 ] && printf '%s' "$(IFS=,; echo "${fails[*]}")" || printf '-')" \
    "$( [ "${#cannot[@]}" -gt 0 ] && printf '%s' "$(IFS=,; echo "${cannot[*]}")" || printf '-')" \
    "$( [ "${#diags[@]}" -gt 0 ] && printf '%s' "$(IFS=,; echo "${diags[*]}")" || printf '-')" \
    "$DIR_TOKEN" "$PHASE"
  case "$v" in
    PASS)   return 0 ;;
    FAIL)   return 1 ;;
    NOINFO) return 2 ;;
  esac
}

# ── 合成用例两极化（无 X、无应用、秒级）───────────────────────────────────────
selftest() {
  local T; T="$(mktemp -d)"; local npass=0 nfail=0
  export PTS_G10_ROSTER_SRC="$ROSTER_SRC"   # 副本（`_sb`/`_rz`/`_pf`）也要吃同一份名单源
  export PTS_G10_DECL_TREE="$DECL_TREE"     # 同上：域判定的声明树也要传给副本
  local G10_FIX_NAME; G10_FIX_NAME="$(roster_names | head -1)"
  # ⏪ `t82` 追记：**非 PTS 域夹具名必须现取**（不许写死）。现场：`t78` 把 `LoSetDoc`／`LoSetBreaking` 提进
  #   `k_pts_entries[]`（10 → 12）⇒ 写死 `LoSetDoc` 的两条自测随世界腐坏（当时实测 `pass=38 fail=2`）。
  #   取法（内容锚）：声明树里所有 `EntryPoint="<名>"` 名 − PTS 在册表 ⇒ 第一个即「非 PTS 域真名」。
  local _ro _npts _npts_tree _save_tree
  _ro="$(roster_names)"
  _npts="$(grep -rhoE --include='*.cs' 'EntryPoint[[:space:]]*=[[:space:]]*\"[A-Za-z0-9_]+\"' "$DECL_TREE" 2>/dev/null \
          | sed 's/.*"\([A-Za-z0-9_]*\)"/\1/' | LC_ALL=C sort -u \
          | while IFS= read -r _n; do case $'\n'"$_ro"$'\n' in *$'\n'"$_n"$'\n'*) ;; *) printf '%s' "$_n"; break ;; esac; done)"
  _npts_tree="$DECL_TREE"
  if [ -z "$_npts" ]; then
    _npts="LoFakeTreeRealZZ"; _npts_tree="$T/ft-real"
    mkdir -p "$_npts_tree"
    printf '[DllImport(DllImport.PresentationNative, EntryPoint="LoFakeTreeRealZZ")]\ninternal static extern int LoFakeTreeRealZZ(IntPtr p);\n' > "$_npts_tree/A.cs"
  fi
  if [ -z "$G10_FIX_NAME" ]; then
    printf 'PTS_GUARD_SELFTEST=FAIL pass=0 fail=1 reason=roster-source-unreadable src=%s\n' "$ROSTER_SRC"
    return 1
  fi
  mk() { # mk <case> <k> <alive> <app_rc> <magenta> <colors> <ns> <err> <native_gap> <native_err> <five> <xup> [ink]
    local c="$1" k="$2" d="$T/$1"; mkdir -p "$d"
    printf 'TAB entry=%s\n' "$G10_FIX_NAME" > "$d/app_g1.log"   # `t73`：G10 形态判据的载体（在册名 ⇒ 各例不受 G10 扰动）
    printf 'X_UP=%s display=:237\n' "${12}" > "$d/device.txt"
    printf 'LEG k=%s alive=%s app_rc=%s magenta=%s colors=%s ns=%s ae=12345 ink=%s\n' "$2" "$3" "$4" "$5" "$6" "$7" "${13:-}" > "$d/leg_$2.env"
    printf 'NAMED managed_unavail=%s err=%s native_gap=%s native_err=%s\n' \
      "$([ "$8" = "-" ] && echo 0 || echo 1)" "$8" "$9" "${10}" >> "$d/leg_$2.env"
    printf 'DEV x_up=%s five_stable=%s shim=x pf=y\n' "${12}" "${11}" >> "$d/leg_$2.env"
  }
  good() { mk "$1" 24 yes 143 54454 851 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 -10000 yes yes
           mk "$1" 23 yes 143 49864 843 HandyControlDemo.UserControl.RichTextBoxDemo  -10000 0 -10000 yes yes; }
  chk() { local want="$1" got="$2" nm="$3"
    if [ "$want" = "$got" ]; then npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "$nm" "$got"
    else nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "$nm" "$got" "$want"; fi; }

  out() { printf '%s\n' "$1" | grep -o -m1 '^PTS_GUARD=[A-Z]*' | cut -d= -f2; }
  outdir() { printf '%s\n' "$1" | grep -o -m1 'direction=[a-z-]*' | cut -d= -f2; }

  # ① 全好 ⇒ PASS
  good c1;                              chk PASS "$(out "$(judge_legs "$T/c1")")" "全好(54454/49864)"
  # ② 修前成对件形态：leg24 rc=134 alive=no ⇒ FAIL
  good c2; rm -f "$T/c2/leg_24.env"; mk c2 24 no 134 0 1 HandyControlDemo.UserControl.FlowDocumentDemo -10000 0 -10000 yes yes
                                        chk FAIL "$(out "$(judge_legs "$T/c2")")" "rc=134/alive=no"
  # ③ 假修形态：alive=yes 但 magenta=0 ⇒ FAIL
  good c3; rm -f "$T/c3/leg_24.env"; mk c3 24 yes 143 0 643 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 -10000 yes yes
                                        chk FAIL "$(out "$(judge_legs "$T/c3")")" "alive 但洋红 0"
  # ④ 阈值下界 -1 ⇒ FAIL
  good c4; rm -f "$T/c4/leg_24.env"; mk c4 24 yes 143 19999 851 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 -10000 yes yes
                                        chk FAIL "$(out "$(judge_legs "$T/c4")")" "洋红 19999(<门槛)"
  # ⑤ 阈值上界（恰好 = 门槛）⇒ PASS（"≥"）
  good c5; rm -f "$T/c5/leg_24.env"; mk c5 24 yes 143 20000 851 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 -10000 yes yes
                                        chk PASS "$(out "$(judge_legs "$T/c5")")" "洋红 =20000(边界必过)"
  # ⑥ 点错对象（ns 不匹配）⇒ NOINFO
  good c6; rm -f "$T/c6/leg_24.env"; mk c6 24 yes 143 54454 851 HandyControlDemo.UserControl.BrushDemo -10000 1 -10000 yes yes
                                        chk NOINFO "$(out "$(judge_legs "$T/c6")")" "ns=B rushDemo(点错对象)"
  # ⑦ 具名行缺 ⇒ FAIL
  good c7; rm -f "$T/c7/leg_24.env"; mk c7 24 yes 143 54454 851 HandyControlDemo.UserControl.FlowDocumentDemo - 0 -10000 yes yes
                                        chk FAIL "$(out "$(judge_legs "$T/c7")")" "无具名行"
  # ⑧ native err=0（假 stub）⇒ 仍 PASS（只有 DIAG）
  good c8; rm -f "$T/c8/leg_24.env"; mk c8 24 yes 143 54454 851 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 0 yes yes
                                        chk PASS "$(out "$(judge_legs "$T/c8")")" "native err=0 ⇒ PASS+DIAG"
  # ⑨ X 没起来 ⇒ NOINFO
  good c9; rm -f "$T/c9/leg_24.env" "$T/c9/leg_23.env"
          mk c9 24 yes 143 54454 851 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 -10000 yes no
                                        chk NOINFO "$(out "$(judge_legs "$T/c9")")" "x_up=no"
  # ⑩ 证据目录空 ⇒ NOINFO（**响亮**，不许静默 PASS）
  mkdir -p "$T/c10";                    chk NOINFO "$(out "$(judge_legs "$T/c10")")" "空证据目录"
  # ⑪ 件跑动中被换 ⇒ NOINFO
  good c11; rm -f "$T/c11/leg_24.env";  mk c11 24 yes 143 54454 851 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 -10000 no yes
                                        chk NOINFO "$(out "$(judge_legs "$T/c11")")" "five_stable=no"
  # ⑫ 139（静默 SEGV）⇒ FAIL
  good c12; rm -f "$T/c12/leg_24.env";  mk c12 24 no 139 0 1 HandyControlDemo.UserControl.FlowDocumentDemo -10000 0 -10000 yes yes
                                        chk FAIL "$(out "$(judge_legs "$T/c12")")" "app_rc=139"

  # ⑬ 方向口径**在位** ⇒ 判词行尾带 `direction=in-file`（`TASK-0741`）
  good c13; chk in-file "$(outdir "$(judge_legs "$T/c13")")" "方向口径在位"
  # ⑭ **反极**：沙箱把件内那一行删掉 ⇒ `PTS_DIRECTION=FAIL` ＋ 判词**必红** ＋ rc≠0
  #    （口径只活在别处 ＝ `D-G142` 的现场形态；**不许静默绿**）
  _sb="$T/guard-nodirective.sh"
  grep -v -E '^#[[:space:]]*PTS-DIRECTION:' "$0" > "$_sb"
  mkdir -p "$T/c14"
  _sbo="$(bash "$_sb" --legs "$T/c14" 2>&1)"; _sbrc=$?
  chk FAIL "$(out "$_sbo")" "删句 ⇒ 判词必红"
  chk missing "$(outdir "$_sbo")" "删句 ⇒ direction 标记=missing"
  if grep -qF 'PTS_DIRECTION=FAIL' <<< "$_sbo"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "删句 ⇒ PTS_DIRECTION=FAIL" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 PTS_DIRECTION=FAIL\n' "删句 ⇒ PTS_DIRECTION=FAIL" "no"
  fi
  if [ "$_sbrc" -ne 0 ]; then
    npass=$((npass+1)); printf '  %-34s => rc=%-3s ok\n' "删句 ⇒ rc≠0" "$_sbrc"
  else
    nfail=$((nfail+1)); printf '  %-34s => rc=%-3s ✗ 期望非零\n' "删句 ⇒ rc≠0" "$_sbrc"
  fi
  # ── `t12`：判据反转的两极化（**realized 期**用同一件、只改口径位的副本跑）─────────
  _rz="$T/guard-realized.sh"
  sed 's/^\(# PTS-DIRECTION: .*\)phase=degraded$/\1phase=realized/' "$0" > "$_rz"
  grep -q 'phase=realized' "$_rz" || { nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "realized 副本生成" "no" "yes"; }
  rz() { local c="$1" want="$2" nm="$3" o v
         o="$(bash "$_rz" --legs "$T/$c" 2>&1 || true)"; v="$(out "$o")"
         chk "$want" "$v" "$nm"; return 0; }
  # ⑮ realized 期：真实排版形态（magenta=0 ∧ 无具名行 ∧ native_gap=0 ∧ ink>0）⇒ PASS
  rm -rf "$T/c15"; mk c15 24 yes 143 0 900 HandyControlDemo.UserControl.FlowDocumentDemo - 0 - yes yes 12345
                  mk c15 23 yes 143 0 880 HandyControlDemo.UserControl.RichTextBoxDemo  - 0 - yes yes 12001
                  rz c15 PASS "realized·真实形态"
  # ⑯ realized 期：**缺 ink 证据位** ⇒ NOINFO（不许因 magenta=0 判绿）
  rm -rf "$T/c16"; mk c16 24 yes 143 0 900 HandyControlDemo.UserControl.FlowDocumentDemo - 0 - yes yes
                  mk c16 23 yes 143 0 880 HandyControlDemo.UserControl.RichTextBoxDemo  - 0 - yes yes
                  rz c16 NOINFO "realized·缺 ink ⇒ NOINFO"
  # ⑰ realized 期：占位还在（magenta>0）⇒ FAIL
  rm -rf "$T/c17"; mk c17 24 yes 143 54454 851 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 -10000 yes yes 12345
                  mk c17 23 yes 143 49864 843 HandyControlDemo.UserControl.RichTextBoxDemo  -10000 1 -10000 yes yes 12001
                  rz c17 FAIL "realized·占位仍在 ⇒ FAIL"
  # ⑱ realized 期：具名行仍在 ⇒ FAIL
  rm -rf "$T/c18"; mk c18 24 yes 143 0 900 HandyControlDemo.UserControl.FlowDocumentDemo -10000 0 -10000 yes yes 12345
                  mk c18 23 yes 143 0 880 HandyControlDemo.UserControl.RichTextBoxDemo  -10000 0 -10000 yes yes 12001
                  rz c18 FAIL "realized·具名行仍在 ⇒ FAIL"
  # ⑲ `I1` 反极性：degraded 期「只降级不画」（magenta=0 ∧ 具名行在位）⇒ **必红**（`N2-b`）
  rm -rf "$T/c19"; mk c19 24 yes 143 0 643 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 -10000 yes yes
                  mk c19 23 yes 143 0 641 HandyControlDemo.UserControl.RichTextBoxDemo  -10000 1 -10000 yes yes
                  chk FAIL "$(out "$(judge_legs "$T/c19")")" "I1/N2-b：只降级不画 ⇒ 必红"
  # ⑳ `phase` 位自身的反极性：把 `phase=` 删掉 ⇒ `PTS_DIRECTION=FAIL` ＋ 判词必红
  _pf="$T/guard-nophase.sh"
  sed 's/^\(# PTS-DIRECTION: .*\)phase=degraded/\1phase=/' "$0" > "$_pf"
  rm -rf "$T/c20"
  _pfo="$(bash "$_pf" --legs "$T/c20" 2>&1 || true)"
  chk FAIL "$(out "$_pfo")" "phase 位缺失 ⇒ 判词必红"
  if grep -qF 'PTS_DIRECTION=FAIL' <<< "$_pfo"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "phase 位缺失 ⇒ PTS_DIRECTION=FAIL" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "phase 位缺失 ⇒ PTS_DIRECTION=FAIL" "no" "yes"
  fi
  # ── `t73`：G10 形态判据**两极化**（载体 = 真路径 `app_g1.log`；名单源 = 内容锚现取）──
  # ㉑ 具名且在册 ⇒ 判据 `PASS`、整步判词不被 G10 扰动（正极）
  good c21; chk PASS "$(out "$(judge_legs "$T/c21")")" "G10·在册名 ⇒ PASS"
  # ㉒ 具名但**不在册** ⇒ `PTS_G10_NAME=FAIL`（点名）＋ 整步 `PTS_GUARD=FAIL`（反极）
  good c22; printf 'TAB entry=NotAnEntryZZ\n' > "$T/c22/app_g1.log"
            _o22="$(judge_legs "$T/c22" 2>&1)" || true; chk FAIL "$(out "$_o22")" "G10·不在册 ⇒ 必红"
            if grep -qF 'PTS_G10_NAME=FAIL' <<< "$_o22" && grep -qF 'off-roster=NotAnEntryZZ' <<< "$_o22"; then
              npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "G10·不在册 ⇒ 点名" "yes"
            else
              nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "G10·不在册 ⇒ 点名" "no" "FAIL+off-roster"
            fi
  # ㉓ 无具名（只 `unknown`）⇒ `PTS_G10_NAME=PASS form=unnamed`（**队长 ts=21:54 裁定回正**：无名是算出来的
  #    状态、不是"算不出"）＋ 判词**不被扰动**（`PTS_GUARD=PASS`）
  good c23; printf 'TAB entry=unknown\n' > "$T/c23/app_g1.log"
            _o23="$(judge_legs "$T/c23" 2>&1)" || true; chk PASS "$(out "$_o23")" "G10·无名 ⇒ 判词 PASS"
            if grep -qF 'reason=frontier-unnamed' <<< "$_o23"; then
              npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "G10·无名 ⇒ reason 在位" "yes"
            else
              nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "G10·无名 ⇒ reason 在位" "no" "reason=frontier-unnamed"
            fi
  # ㉔ 名单源取不到（env 指空路径）⇒ `NOINFO reason=roster-source-unreadable`（**零名单不当绿**）
  _o24="$(PTS_G10_ROSTER_SRC="$T/nonexistent-pts.c" bash "$0" --g10-name "$T/c21" 2>&1)"; _rc24=$?
  if grep -qF 'roster-source-unreadable' <<< "$_o24" && [ "$_rc24" -eq 2 ]; then
    npass=$((npass+1)); printf '  %-34s => rc=%-3s ok\n' "G10·名单源不可读 ⇒ NOINFO" "$_rc24"
  else
    nfail=$((nfail+1)); printf '  %-34s => rc=%-3s ✗ 期望 %s\n' "G10·名单源不可读 ⇒ NOINFO" "$_rc24" "rc=2+reason"
  fi
  # ── `t76`：域前提修正的**三格两极化**（载体＝真路径 `app_g1.log`；域判定＝两级内容锚）──
  # ㉕ PTS 域**假名**（形状像 PTS、在册表里没有）⇒ `FAIL`（`off-roster=` 点名）
  good c25; printf 'TAB entry=LoNotARegisteredEntZZ\n' > "$T/c25/app_g1.log"
            _o25="$(judge_legs "$T/c25" 2>&1)" || true; chk FAIL "$(out "$_o25")" "G10c·PTS假名 ⇒ 必红"
            if grep -qF 'off-roster=LoNotARegisteredEntZZ' <<< "$_o25" && grep -qF 'domains=unattributable' <<< "$_o25"; then
              npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "G10c·PTS假名 ⇒ 点名" "yes"
            else
              nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "G10c·PTS假名 ⇒ 点名" "no" "off-roster+domains=unattributable"
            fi
  # ㉖ 非 PTS 域**真名**（**现取**：不在 PTS 在册表 ∧ 声明树里对拍得上）⇒ 不红，且**点名声明位**
  good c26; printf 'TAB entry=%s\n' "$_npts" > "$T/c26/app_g1.log"
            _save_tree="$DECL_TREE"; [ "$_npts_tree" = "$DECL_TREE" ] || DECL_TREE="$_npts_tree"
            _o26="$(judge_legs "$T/c26" 2>&1)" || true
            DECL_TREE="$_save_tree"
            chk PASS "$(out "$_o26")" "G10c·非PTS真名 ⇒ 不红"
            if grep -qF 'domains=dllimport-entry' <<< "$_o26" && grep -qE 'decl=[^ ]*(upstream/wpf/.*\.cs|ft-real/A\.cs):[0-9]+' <<< "$_o26"; then
              npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "G10c·非PTS真名 ⇒ 声明位点名" "yes"
            else
              nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "G10c·非PTS真名 ⇒ 声明位点名" "no" "domains=dllimport-entry+decl=<…>/(upstream/wpf|ft-real)/*.cs:<line>"
            fi
  # ㉗ 非 PTS 域**假名** ⇒ `FAIL`
  good c27; printf 'TAB entry=NoSuchDeclaredEntryZZ\n' > "$T/c27/app_g1.log"
            _o27="$(judge_legs "$T/c27" 2>&1)" || true; chk FAIL "$(out "$_o27")" "G10c·非PTS假名 ⇒ 必红"
            if grep -qF 'off-roster=NoSuchDeclaredEntryZZ' <<< "$_o27"; then
              npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "G10c·非PTS假名 ⇒ 点名" "yes"
            else
              nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "G10c·非PTS假名 ⇒ 点名" "no" "off-roster=NoSuchDeclaredEntryZZ"
            fi
  # ㉘ 声明树**不在** ⇒ 非 PTS 域判不了 ⇒ `NOINFO`（**永不当绿**；env 指空目录）
  good c28
            _o28="$(PTS_G10_DECL_TREE="$T/no-such-tree" bash "$0" --g10-name "$T/c26" 2>&1)"; _rc28=$?
            if grep -qF 'reason=decl-tree-absent' <<< "$_o28" && [ "$_rc28" -eq 2 ]; then
              npass=$((npass+1)); printf '  %-34s => rc=%-3s ok\n' "G10c·声明树缺席 ⇒ NOINFO" "$_rc28"
            else
              nfail=$((nfail+1)); printf '  %-34s => rc=%-3s ✗ 期望 %s\n' "G10c·声明树缺席 ⇒ NOINFO" "$_rc28" "rc=2+decl-tree-absent"
            fi
  # ── `t82`：**真声明锚**的三格（`t77` 的 `F1` 面）：假树自造，注释/字面量一律不吃 ──
  mkdir -p "$T/ft1" "$T/ft2" "$T/ft3"
  printf '// 本行只是注释里的示例：DllImport(Whatever, EntryPoint="LoCommentOnlyZZ") 供参考\n' > "$T/ft1/A.cs"
  printf '// [DllImport(DllImport.PresentationNative, EntryPoint="LoCommentedOutZZ")]\n// internal static extern int LoCommentedOutZZ(IntPtr p);\n' > "$T/ft2/A.cs"
  printf '[DllImport(DllImport.PresentationNative, EntryPoint="LoFakeTreeRealZZ")]\ninternal static extern int LoFakeTreeRealZZ(IntPtr p);\n' > "$T/ft3/A.cs"
  good c29; printf 'TAB entry=LoCommentOnlyZZ\n' > "$T/c29/app_g1.log"
            _o29="$(PTS_G10_DECL_TREE="$T/ft1" bash "$0" --g10-name "$T/c29" 2>&1)"; _rc29=$?
            if grep -qF 'domains=unattributable' <<< "$_o29" && [ "$_rc29" -eq 1 ]; then
              npass=$((npass+1)); printf '  %-34s => rc=%-3s ok\n' "G10c·注释假声明 ⇒ 必红" "$_rc29"
            else
              nfail=$((nfail+1)); printf '  %-34s => rc=%-3s ✗ 期望 %s\n' "G10c·注释假声明 ⇒ 必红" "$_rc29" "rc=1+domains=unattributable"
            fi
  good c30; printf 'TAB entry=LoCommentedOutZZ\n' > "$T/c30/app_g1.log"
            _o30="$(PTS_G10_DECL_TREE="$T/ft2" bash "$0" --g10-name "$T/c30" 2>&1)"; _rc30=$?
            if grep -qF 'off-roster=LoCommentedOutZZ' <<< "$_o30" && [ "$_rc30" -eq 1 ]; then
              npass=$((npass+1)); printf '  %-34s => rc=%-3s ok\n' "G10c·注释掉的声明 ⇒ 必红" "$_rc30"
            else
              nfail=$((nfail+1)); printf '  %-34s => rc=%-3s ✗ 期望 %s\n' "G10c·注释掉的声明 ⇒ 必红" "$_rc30" "rc=1+off-roster=点名"
            fi
  good c31; printf 'TAB entry=LoFakeTreeRealZZ\n' > "$T/c31/app_g1.log"
            _o31="$(PTS_G10_DECL_TREE="$T/ft3" bash "$0" --g10-name "$T/c31" 2>&1)"; _rc31=$?
            if grep -qF 'domains=dllimport-entry' <<< "$_o31" && grep -qE 'decl=[^ ]*ft3/A\.cs:1' <<< "$_o31" && [ "$_rc31" -eq 0 ]; then
              npass=$((npass+1)); printf '  %-34s => rc=%-3s ok\n' "G10c·真声明 ⇒ 绿＋点名" "$_rc31"
            else
              nfail=$((nfail+1)); printf '  %-34s => rc=%-3s ✗ 期望 %s\n' "G10c·真声明 ⇒ 绿＋点名" "$_rc31" "rc=0+dllimport-entry+decl=…"
            fi
  rm -rf "$T"
  printf 'PTS_GUARD_SELFTEST=%s pass=%d fail=%d\n' "$([ "$nfail" = 0 ] && echo PASS || echo FAIL)" "$npass" "$nfail"
  [ "$nfail" = 0 ]
}


# ══ `t109`／`t105` `F-1`② · **C4 侧读法：定名改用「台账口径」**（与 `P1-ptsname-result.md` §8 **裁定十二补**一致）══
#   口径（逐字）：判「**被撞入口／下一跳是谁**」**以台账为准** —— 现取 `<dir>/app_g1.log` 里 `^PTS_GAP entry=<名>` 行，
#   取 `seq=` 排序后的**最早**那一条 ＝ **下一跳**（链上最早那一站）；**最晚**那一条 ＝ **最近一次缺口调用**。
#   托管 `entry=` 面**只作「具名位移」的粗证**（证"名字从无到有"），**不作定名依据** —— 两者不一致时**以台账为准**，
#   判词里**两个直方图分开印、绝不合并**（`t105` 的 `F-1` 正是「混在一张直方图」才读不出"谁撞的"）。
c4_ledger_check() {   # <dir> ⇒ 印 PTS_C4_* 三行；台账不在 ⇒ NOINFO（**绝不当绿**）
  local d="${1:?--c4-ledger 需要目录}"
  local log="$d/app_g1.log" ent seq0 seqn next bumped k
  if [ ! -s "$log" ]; then
    echo "PTS_C4_LEDGER=NOINFO reason=ledger-absent($log)（载体不在 ⇒ 「被撞入口／下一跳」**不可判** ⇒ 绝不当绿）"
    C4_RC=3; return 3
  fi
  ent=$(grep -aE '^PTS_GAP entry=[A-Za-z0-9_]+' "$log" 2>/dev/null | wc -l | tr -d ' ')
  if [ "${ent:-0}" -eq 0 ]; then
    echo "PTS_C4_LEDGER=NOINFO reason=ledger-empty(0 行 ^PTS_GAP entry=)（台账未落痕 ⇒ 不可判 ⇒ 绝不当绿）"
    C4_RC=3; return 3
  fi
  next=$(grep -aE '^PTS_GAP entry=[A-Za-z0-9_]+' "$log" 2>/dev/null | sed -n 's/.*entry=\([A-Za-z0-9_]*\).*seq=\([0-9]*\).*/\2 \1/p' | LC_ALL=C sort -n -k1,1 | head -1 | awk '{print $2}')
  seq0=$(grep -aE '^PTS_GAP entry=[A-Za-z0-9_]+' "$log" 2>/dev/null | sed -n 's/.*entry=\([A-Za-z0-9_]*\).*seq=\([0-9]*\).*/\2 \1/p' | LC_ALL=C sort -n -k1,1 | head -1 | awk '{print $1}')
  bumped=$(grep -aE '^PTS_GAP entry=[A-Za-z0-9_]+' "$log" 2>/dev/null | sed -n 's/.*entry=\([A-Za-z0-9_]*\).*seq=\([0-9]*\).*/\2 \1/p' | LC_ALL=C sort -n -k1,1 | tail -1 | awk '{print $2}')
  seqn=$(grep -aE '^PTS_GAP entry=[A-Za-z0-9_]+' "$log" 2>/dev/null | sed -n 's/.*entry=\([A-Za-z0-9_]*\).*seq=\([0-9]*\).*/\2 \1/p' | LC_ALL=C sort -n -k1,1 | tail -1 | awk '{print $1}')
  k=$(grep -aoE '^PTS_GAP entry=[A-Za-z0-9_]+' "$log" 2>/dev/null | sed 's/^PTS_GAP entry=//' | LC_ALL=C sort -u | wc -l | tr -d ' ')
  echo "PTS_C4_LEDGER=PASS lines=$ent distinct=$k next=$next next_seq=$seq0 bumped=$bumped bumped_seq=$seqn（台账口径：**next ＝ 按 seq 最早的缺口入口 ＝ 下一跳**；bumped ＝ 最近一次缺口调用）"
  echo "PTS_C4_SOURCE=ledger（定名**以台账为准**；托管 entry= 面只作具名位移的**粗证**，不作定名依据 —— 裁定十二补）"
  # —— 两直方图**分开**印（绝不合并；这正是 `t105` `F-1` 的病灶形态）
  echo "PTS_C4_HISTO=mode=separate ledger:$(grep -aoE '^PTS_GAP entry=[A-Za-z0-9_]+' "$log" 2>/dev/null | sed 's/^PTS_GAP entry=//' | LC_ALL=C sort | uniq -c | tr -s ' ' | tr '\n' ';')"
  echo "PTS_C4_HISTO_MANAGED=separate managed:$(grep -aoE 'entry=[A-Za-z0-9_]+' "$log" 2>/dev/null | sed 's/^entry=//' | LC_ALL=C sort | uniq -c | tr -s ' ' | tr '\n' ';')"
  local mgr
  mgr=$(grep -aoE 'entry=[A-Za-z0-9_]+' "$log" 2>/dev/null | sed 's/^entry=//' | LC_ALL=C sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
  if [ -n "$mgr" ] && [ "$mgr" != "$next" ]; then
    echo "PTS_C4_NAME=LEDGER-OVERRIDE managed=$mgr ledger_next=$next（两口径不一致 ⇒ **以台账为准**；托管面只算"具名位移"粗证）"
  else
    echo "PTS_C4_NAME=AGREE managed=${mgr:-none} ledger_next=$next"
  fi
  return 0
}

case "${1:---selftest}" in
  --legs) shift; judge_legs "${1:?--legs 需要目录}"; exit $? ;;
  --g10-name) shift; g10_name_check "${1:?--g10-name 需要目录}"; exit "$G10_RC" ;;   # `t73`：只跑形态判据（两极化腿用）
  --c4-ledger) shift; c4_ledger_check "${1:?--c4-ledger 需要目录}"; exit "${C4_RC:-0}" ;;   # `t109`：C4 定名改用台账口径（裁定十二补）
  --selftest) selftest; exit $? ;;
  *) echo "用法: $0 --legs <dir> | --g10-name <dir> | --c4-ledger <dir> | --selftest" >&2; exit 2 ;;
esac
