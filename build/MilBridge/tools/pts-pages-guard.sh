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

# ── ⏪ `t124`（`t118` 的 `N1`）**空态参照集**（帧 `sha256` 前 16 位；**唯一登记处**）──────────────────
#   语义（逐字）：集合里的值 ＝ **已登记**的「空态回退画面」的**帧身份**（`k23.png`／`k24.png`／`last.png`
#   三帧**同值**时的那一枚）；`realized` 期帧身份**落在这个集合里** ⇒ 该腿**必红**（`N1` 要件①）。
#   现值 `1a76488aa4a790b3` ＝ `t122` **重登记**值（`t122` 现取：三帧同值）；**旧登记 `ef3fd6765f18f51b` 作废**
#   （屏幕换代 ⇒ 同值不再表示同一画面）。
#   重登记触发（照 `t122` 的归属建议）：① 相位翻转包执行；② 三帧 `sha256` 任一变化 ⇒ **本件写者（守卫写者）**重登记。
#   **不设 env 旋钮**（判据只许收紧：不给"把现帧写进集合即绿"的路子）；合成夹具靠**取值**两极化。
# ── ⏪ `t136`（`t120` 的 `F-3`；**方向＝收紧**）**空态参照集：累积登记 ＋ 作废纪律**（帧 `sha256` 前 16 位）──
#   **逐枚给来源与时刻（可复核）**：
#     · `1a76488aa4a790b3` —— 出处 `build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/{k23,k24,last}.png`
#       三帧同值；读时 `2026-09-29T04:1x+0800`（`t122` 重登记；本行**原样保留**其来源）。
#     · `ef3fd6765f18f51b` —— 出处同路径三帧同值（`t119` 那趟 00:52 代照进在册证据；本席 `t136` 现取：
#       两腿 `FRAME` 行 `fr_sha=ef3fd6765f18f51b`、三帧 `sha256` 前 16 位同为它、各 `189716` B）。
#   ⚠️ **口径更正（dated，`t136`；上面 `t124` 段写的"旧登记 `ef3fd6765f18f51b` 作废"按 `F-3` 收回）**：
#     它是**已发生**的空态回退指纹，**必须留在集合里**（**累积登记**）。上面 `t124` 那几句**原文一字未删**，
#     以本段为准。
#   ⚠️ **作废纪律（写死）**：**把一枚帧身份从本集合里"作废／移出"这个动作本身是危险的** ——
#     **只有拿到 `N4` 正身份或内容锚正证据才准移出；只凭"换了一版画面"不得移出。**
#     （依据 `t120` 现取：实况帧恰是被"作废"的那一枚 ⇒ `∉ 参照集` 被读成绿 ⇒ **假绿形态**。）
#   **不设 env 旋钮**（判据只许收紧）；合成夹具靠**取值**两极化。
#   ⏪ `t144`（`t139` `F-3`）**逐枚出处可复现性**（**取（乙）**：只登记出处、**不**往装置证据面塞非装置产物；理由见载体）：
#     · `ef3fd6765f18f51b` —— **仓内可复现** ✓：`build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/k23.png`
#       现势与 `git show HEAD:<同路径>` **同为**该值、各 `189716` B（本席 `2026-09-29T15:0x+0800` 现算）。
#     · `1a76488aa4a790b3` —— ⚠️ **仓内不可复现**（该路径**仓内可达史 8 版均非它**，本席现算命中 **0**）；
#       真实载体在**仓外**：`~/t119-runner/bak/run-N3-runner-shots/g1/{k23,k24,last}.png`
#       （三枚同值 `1a76488aa4a790b3`、各 `189742` B；本席现算）。⇒ **引用该成员时必须连带写明"仓外载体"**，
#       不得当成"仓内可查"；复核命令：`sha256sum ~/t119-runner/bak/run-N3-runner-shots/g1/k23.png | cut -c1-16`。
# ── ⏪ `t157`（依据 `t152` 主表；**方向＝收紧**）**第三枚并入：β `b273ebecc332fc03`**（帧 `sha256` 前 16 位）──
#   事实出处：`build/MilBridge/P1-frame-determinism2-report.md`（**本席 `t157` 现取**：247 行、
#   件 `sha16=7bc694c16ecd0167`、末行自证复算 `0f0819a68e617710` ＝ 该行自declared 值 ⇒ 件完整）。
#   单代 24 样本、零被拒零作废 ⇒ 帧面有**两个变体**（该件 `:98` 原文）：
#     · **α** ＝ `ef3fd6765f18f51b`（`colors 383`／`ae_boot 15386`）—— 17/24（Wilson95 `[0.508,0.851]`）
#     · **β** ＝ `b273ebecc332fc03`（`391`／`14775`）—— 7/24（`[0.149,0.492]`）
#   且 β 与显示号、次序·时间、机械负载、探针闸**全无关**；`boot` 面 24/24 恒定 `b21eb530afd3c66c`
#   ⇒ 变体**只出现在 `k23`／`k24` 那一面**（本席现取：该件 `:102/:104/:106` 三行 β 样本 `fr_sha` 同值）。
#   🔴 **为什么必须并入（第三条假绿通道的具体路径）**：旧集 `{1a76488aa4a790b3,ef3fd6765f18f51b}` 里没有 β
#     ⇒ **落在 β 的趟** `in_empty_set=no` ⇒ `N1` 要件①「帧身份 ∉ 空态参照集」被读成"成立"，
#     **而 β 同样是空态画面** ⇒ 这正是裁定三十九第 (c) 条（"帧面不可复现 ⇒ `fr_sha` 类要件不可归因"）
#     的实现路径。**现成读数**：`t152` 主表那三行 β 样本（`:102/:104/:106`）判词列原文＝ **`全绿`**
#     ⇒ 假绿**已经发生过**，不是设想。
#   **逐枚出处 ＋ 读时戳（三成员）**：
#     · `1a76488aa4a790b3` —— 出处按 `t144` 已登记口径：⚠️ **仓内不可复现**，真实载体在**仓外**
#       `~/t119-runner/bak/run-N3-runner-shots/g1/{k23,k24,last}.png`（**本席 `t157` 现取**：`k23.png`
#       `sha16=1a76488aa4a790b3`、`189742` B；`t144` 读时 `2026-09-29T15:0x+0800`）。
#       ⇒ **引用本成员时必须连带写"仓外载体"**，不得当成"仓内可查"。
#     · `ef3fd6765f18f51b` —— 出处 `build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/{k23,k24,last}.png`
#       三帧同值（**本席 `t157` 现取**：`k23.png`／`k24.png` 各 `sha16=ef3fd6765f18f51b`、各 `189716` B）；
#       `t136` 读时 `2026-09-29T0x+0800`。
#     · `b273ebecc332fc03` —— 出处 `build/MilBridge/P1-frame-determinism2-report.md`（`t152` 主表 7/24 样本
#       的 `FRAME` 行同值；**本席 `t157` 现取**该件 `sha16=7bc694c16ecd0167`，读时 `2026-09-29T17:4x+0800`）。
#   ⚠️ **不放松**（逐字）：`t136` 的「**必要非充分、永不单独发绿**」与 `t145` 的「**登记须附独立支撑**」照旧；
#     **作废纪律**照旧（只有拿到 `N4` 正身份／内容锚正证据才准移出；"换了一版画面"不是理由）；
#     **不设 env 旋钮**（判据只许收紧 ⇒ 不给"把现帧写进集合即绿"的路子；合成夹具靠**取值**两极化）。
#   ⏪ `t157`**只增不改**：旧两成员行的**原文一字未删**（见上面 `t124`／`t136` 两段），**以本行为准**：
#     旧值原文：`FRAME_EMPTY_SET="1a76488aa4a790b3,ef3fd6765f18f51b"`
FRAME_EMPTY_SET="1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03"

# ── ⏪ `t145`（`t142` 的 `C-A`）**色锚（颜色正身份）**：具名色 ＋ 定值 RGB ＋ 逐色出处 ─────────────
#   出处（内容锚）：hc UI 定义 `FlowDocumentDemo.xaml` 的**具名色行**（`Background=GhostWhite`／`Paragraph Background=Beige
#   Foreground=DarkGreen`／`Floater Background=GhostWhite`）⇒ WPF 具名色 ⇒ **定值 RGB**（逐色写在登记值里）。
#   ⚠️ **阈值由反极标定**（不是"看起来该是 0"）：**现盘空态帧**（`shots/g1/{boot,k23,k24,last}.png`）上四色
#   **实算全 0** 而同帧 `LightGray` **实算 44/51 px** ⇒ 该计数**是活的**（能分开"有该色/没该色"）⇒ 判据取
#   `>= COLOR_ANCHOR_MIN`（硬写 200，**不设 env 旋钮**：旋钮只会被用来放松）。
#   ⚠️ **`LightGray` 不入锚集**：它在空态帧里已有 44/51 px ＝ **死锚**（只有实测才知道，算不出来）。
#   ⚠️ **`k=23` 无锚**（`RichTextBoxDemo.xaml` 只有 `Margin/Width/Height` 与三段 `Paragraph`，无具名色）
#   ⇒ `k=23` 记具名 `NOINFO`，**严禁**用"k=24 有锚"推广过去。
# ⏪ `t147`（P1-W67）：**判词文本里的反引号一律经本变量进双引号串** —— 直接写「双引号内裸反引号」会被 bash 当命令替换（`DQ-BACKTICK` 族）；
#   本行是**单引号**变量，持有一个反引号字符；`"…${BT}x${BT}…"` 展开后与原来**逐字节相同**。
BT='`'
COLOR_ANCHOR_K24="GhostWhite=248,248,255 Beige=245,245,220 DarkGreen=0,100,0 LightGoldenrodYellow=250,250,210"
COLOR_ANCHOR_MIN=200
COLOR_ANCHOR_BASE_FRAME="boot.png"

# 逐色 px 扫描器（纯读；PIL 不在 ⇒ rc=1 空输出 ⇒ 调用方按"读不到"处理，绝不当 0）
color_px_scan() {   # color_px_scan <png> "<Name=r,g,b …>"
  [ -s "$1" ] || return 1
  python3 - "$1" "$2" <<'PYAC'
import sys, collections
try:
    from PIL import Image
except Exception:
    sys.exit(3)
p, spec = sys.argv[1], sys.argv[2]
anch = {}
for tok in spec.split():
    n, rgb = tok.split("=")
    anch[n] = tuple(int(x) for x in rgb.split(","))
im = Image.open(p).convert("RGB")
c = collections.Counter(im.getdata())
print(" ".join("%s=%d" % (n, c.get(v, 0)) for n, v in anch.items()))
PYAC
}

# 数"达到下限的锚色个数"；$1 ＝ 扫描输出
color_anchor_hits() { local n=0 v; for pair in $1; do v="${pair#*=}"; case "$v" in ''|*[!0-9]*) continue;; esac; [ "$v" -ge "$COLOR_ANCHOR_MIN" ] && n=$((n+1)); done; printf '%s' "$n"; }

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
  # ⏪ `t136`：`N1` 正证据闸的 per-leg 取值载体（每趟判读复位；**新闸只在 realized 期生效**）
  N1_SHA_23=''; N1_SHA_24=''; N1_INK_23=''; N1_INK_24=''; N1_NECMISS=''
  # ⏪ `t144`（`t139` `F-1`）：**per-leg 必要件位**（要件① ∉ 参照集 ∧ 要件② 位移>0 ∧ 取值在位）—— 新闸的 FAIL 支拿它当前置
  N1_NEC_23=''; N1_NEC_24=''
  local ev
  for k in 24 23; do
    ev="$dir/leg_$k.env"
    if [ ! -s "$ev" ]; then
      cannot+=("leg$k(env-absent)")
      # ⏪ `t144`（`t139` `F-1`）：**缺整条 env** 也要让循环后的新闸知道"本腿必要件不可判"（否则新闸会拿默认值继续判 ⇒ 理由与事实相反）
      N1_NECMISS="${N1_NECMISS:+$N1_NECMISS,}leg$k(env-absent)"
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

    # ── ⏪ `t124`（`t118` 的 `N1`；**方向＝收紧**）：**帧身份 ＋ 帧位移** —— "两页停在同一张空态回退画面"不得读成绿 ──
    #   依据：`t119` 现取 —— 两页**停在同一次回退渲染**（`k23=k24=last` 同值）而当时的 realized 四要件
    #   （`magenta=0` ∧ 无具名行 ∧ `ink>0` ∧ `native_gap=0`）**全成立** ⇒ 旧判据会 `PASS`；`t122` 的 `N2` 只堵了
    #   "入口缺失（`ENFE`）"那一面，**帧身份**这一面当时**没有装置侧取值格**（`t124` 第一件就是补它）。
    #   口径（逐字）：取值来自 `leg_<k>.env` 的 `FRAME` 行（`t124` 新增段；键名不含数字 —— region 扫描词法所限）；
    #     · **要件①（帧身份）**：`fr_sha` ∉ `FRAME_EMPTY_SET`（**已登记**空态帧身份集合，登记处见件头）；
    #     · **要件②（帧位移）**：`fr_ae_boot` > 0（该帧相对 `boot` 的像素位移非零）；
    #     · **`realized` 期**：任一不满足 ⇒ **红并点名**（点名**哪一帧／哪个要件／实测值／参照集**）；
    #     · **`degraded` 期**：只印 `PTS_N1=INFO …`（**照 `t122` 的做法**：**不动**本相位判词 —— 止损期的绿语义
    #       是"占位还在"，与帧身份不冲突）；
    #     · 取值缺／不可解析（旧格式腿、截图没落、`-`）⇒ `PTS_N1=NOINFO` ＋ `cannot+=`（**绝不当绿**）。
    #   ⏪ **`t136`（`t120` 的 `F-1`／`F-3`／`O-2`；方向＝收紧）**：
    #     · **要件①（`fr_sha` ∉ `FRAME_EMPTY_SET`）只是必要条件** —— 判词写死：**「∉ 参照集」不得单独作为
    #       排版绿的依据**；它的绿必须**同时**附**正证据**（下列任一，且**必须点名是哪一种**）：
    #         (a) `N4` **正身份**证据在场（今天 `NOINFO` ⇒ 不得给绿）；
    #         (b) **内容锚**（`$PTS_CONTENT_ANCHOR_RE` 在 `<dir>/app_g1.log` 的命中数 `>0`）；
    #         (c) **`AE(k23,k24) > 0`**（两页帧**真不同**：两腿 `fr_sha` 不等，或 `compare` 实测 `>0`）。
    #     · **`N3` 例外支条件（写死）**：例外**仅当两页「内容定义」相同**（`$PTS_N3_SAME_CONTENT_PROOF` 非空
    #       ＝该相同的**正证据声明**）**且两页都确已绘出内容**（两腿 `ink>0`）；**「两页都没绘出内容」不构成例外**
    #       ⇒ **必红**。例外成立只**免红**（`PTS_N1_GATE=EXCEPTION`），**不冒充**排版正身份。
    #     · **`O-2`（写死）**：凡引用 `N1` 的结论**必须写明相位** —— 本段每条判词行都带 `phase=`；
    #       `degraded` 期只印 `INFO`、**不进 `rc`**。
    #     · 今天三项正证据**一个都不在场**（现取：两腿 `fr_sha` 同值、`neptune` 类命中 `0`、`N4` 无载体）
    #       ⇒ `realized` 期本闸**必须判红并点名**：`reason=only-necessary-condition-no-positive-evidence`。
    #   ⚠️ **只增不减**：不改任何既有要件、三态语义、阈值（`t136` 只把"单独发绿"这一路堵死）。
    local ln1 fsha fae ffile in_set n1bad n1f
    ln1="$(grep -m1 '^FRAME ' "$ev" 2>/dev/null)"
    ffile="$(field "${ln1:-}" fr_file)"; fsha="$(field "${ln1:-}" fr_sha)"
    fae="$(field "${ln1:-}" fr_ae_boot)"
    n1bad=""
    case "${fsha:-}" in ''|'-'|*[!0-9a-fA-F]*) n1bad="${n1bad:+$n1bad,}fr_sha";; esac
    case "${fae:-}"  in ''|'-'|*[!0-9]*)          n1bad="${n1bad:+$n1bad,}fr_ae_boot";; esac
    in_set=no; case ",$FRAME_EMPTY_SET," in *",${fsha:-},"*) in_set=yes;; esac
    # ⏪ `t136`：把本腿取值交给循环后的正证据闸（`N1` 必要件是否齐、两腿帧是否真不同、ink 是否 >0）
    case $k in 23) N1_SHA_23="${fsha:-}"; N1_INK_23="${ink:-}";; 24) N1_SHA_24="${fsha:-}"; N1_INK_24="${ink:-}";; esac
    case "${fsha:-}" in ''|'-') N1_NECMISS="${N1_NECMISS:+$N1_NECMISS,}leg$k";; esac
    # ⏪ `t144`（`t139` `F-1`）：本腿**必要件是否真的成立**（= 要件① ∉ `FRAME_EMPTY_SET` ∧ 要件② `fr_ae_boot>0`）
    _nec=no
    case "${fsha:-}" in ''|'-') _nec=no;; *) [ "$in_set" = no ] && [ "${fae:-0}" -gt 0 ] 2>/dev/null && _nec=yes;; esac
    case $k in 23) N1_NEC_23="$_nec";; 24) N1_NEC_24="$_nec";; esac
    if [ -n "$n1bad" ]; then
      echo "PTS_N1=NOINFO k=$k phase=$PHASE reason=frame-cell-missing-or-unparsable(missing=$n1bad file=${ffile:-none} fr_sha=${fsha:-none} fr_ae_boot=${fae:-none}) frame_line=${ln1:-absent}（旧格式腿／截图没落 ⇒ 帧身份与帧位移**不可算** ⇒ 绝不当绿；相位写明口径见 t136 O-2 段）"
      cannot+=("leg$k(n1-frame-cell-missing=$n1bad)")
    elif [ "$PHASE" = realized ]; then
      n1f=""
      if [ "$in_set" = yes ]; then
        echo "  N1-EMPTY-FRAME k=$k file=${ffile:-none} fr_sha=$fsha in_empty_set=yes set={$FRAME_EMPTY_SET}（realized 期**这一帧还在已登记空态参照集里** ⇒ 不许给排版绿） reason=frame-identity-in-empty-state-set"
        n1f="frame-identity(sha16=$fsha∈{$FRAME_EMPTY_SET})"
      fi
      if [ "$fae" -eq 0 ]; then
        echo "  N1-NO-DISPLACEMENT k=$k file=${ffile:-none} fr_ae_boot=0（realized 期**该帧相对 boot 无任何像素位移** ⇒ 不许给排版绿） reason=frame-displacement-zero"
        n1f="${n1f:+$n1f,}frame-displacement(ae_boot=0)"
      fi
      if [ -n "$n1f" ]; then
        echo "PTS_N1=FAIL k=$k file=${ffile:-none} fr_sha=$fsha in_empty_set=$in_set fr_ae_boot=$fae set={$FRAME_EMPTY_SET} criterion=$n1f phase=realized reason=frame-identity-not-established"
        fails+=("leg$k-n1-frame-unestablished($n1f)")
      else
        echo "PTS_N1=NECESSARY k=$k file=${ffile:-none} fr_sha=$fsha in_empty_set=no fr_ae_boot=$fae set={$FRAME_EMPTY_SET} criteria-satisfied=frame-identity,frame-displacement phase=realized（⏪ t136：**必要非充分** —— 「∉ 参照集 ∧ 位移>0」**不得单独作为排版绿的依据**；本腿是否给绿由循环后的**正证据闸**裁定）"
      fi
    else
      echo "PTS_N1=INFO k=$k file=${ffile:-none} fr_sha=$fsha in_empty_set=$in_set fr_ae_boot=$fae set={$FRAME_EMPTY_SET} phase=degraded（止损期不据此判红；相位翻转后本条生效 —— 口径见 t124 段）"
    fi
  done

  # ── ⏪ `t136`（`t120` 的 `F-1`／`F-3`／`O-2`；**方向＝收紧**）：**`N1` 正证据闸 ＋ `N3` 例外支** ────────
  #   为什么有这一段：`t124` 的 `N1` 段把「必要件（∉ 参照集 ∧ `AE(boot,帧)>0`）都成立」直接印成 `PASS`
  #   ⇒ 这正是 `t120` 现取的**假绿形态**（实况帧恰是"曾被作废"的空态指纹；两页帧逐字节相同）。
  #   口径（逐字）：
  #     · **正证据三源**（互不替代；`PTS_N1_POS=` 行**点名是哪一种**）：
  #         `n4`     ＝ env `PTS_N4_POSITIVE_FP="<k23 sha16>,<k24 sha16>"` 与两腿 `fr_sha` **逐位相同**
  #                    （＝`N4` 正身份的**登记载体**；**未登记** ⇒ `NOINFO(no-registered-positive-identity)`，不给绿）；
  #         `anchor` ＝ `$PTS_CONTENT_ANCHOR_RE`（默认 `[Nn]eptune`）在 `<dir>/app_g1.log` 的命中数 `>0`；
  #         `differ` ＝ 两页帧**真不同**：两侧 `shots/g1/k23.png`／`k24.png` **都在** ⇒ `compare -metric AE`
  #                    实测 `>0`（`via=compare`）；文件不在 ⇒ 两腿 `fr_sha` **不等**（`via=fr-sha-inequality`）。
  #     · **`realized` 期**：两腿必要件齐（`N1_SHA_*` 可用、均 ∉ 参照集、`fr_ae_boot>0`）∧ **正证据为空**
  #       ∧ **例外不成立** ⇒ **红并点名** `reason=only-necessary-condition-no-positive-evidence`。
  #     · **`N3` 例外支（写死）**：**仅当两页「内容定义」相同**（`$PTS_N3_SAME_CONTENT_PROOF` 非空 ＝ 该相同的
  #       **正证据声明**）**且两腿 `ink>0`**（＝**两页都确已绘出内容**）⇒ 才准免 `N3` 的"两页必须不同"红；
  #       **「两页都没绘出内容」不构成例外**（⇒ 必红）。
  #     · **`degraded` 期**：本闸**不参与**（只印 `PTS_N1_POS=` 由 `INFO` 行带出）；
  #     · 取值缺（`N1_NECMISS` 非空）⇒ 本闸判 `NOINFO`（**绝不当绿**）。
  #     · ⏪ **`t145` dated 追加（`t142` 的 `C-C`／`C-A`）**：
  #       — **`n4` 源必须带独立可证伪支撑**：登记指纹与两腿 `fr_sha` 逐位相同**之外**，还要**守卫自己现算**的
  #         色锚读数（`color_px_scan`，`>=COLOR_ANCHOR_MIN` 的色数 `>=2`）**成片**；否则印
  #         `PTS_N4=DECLARED-ONLY reason=n4-registration-without-independent-support` 并折 `cannot`（**只登记不给绿**）。
  #       — **色锚面（`C-A`）两相位都跑**（预先就位、不等相位翻转）：基线帧四色实算**必须全 0**（否则 `NOINFO anchor-dead-in-base`）；
  #         `k=24` 缺席即红（点名色／期望／实测／基线）；`k=23` **无锚** ⇒ `NOINFO no-anchor-registered-for-k23`。
  #     · ⏪ **`t144`（`t139` `F-1`）dated 追加**：**`FAIL` 支加了前置** —— 只有**两腿必要件都真的成立**
  #       （per-leg `N1_NEC_23/24=yes`：要件① ∉ 参照集 ∧ 要件② 位移>0 ∧ 取值在位）**才**印
  #       `reason=only-necessary-condition-no-positive-evidence`；**否则**印
  #       `PTS_N1_GATE=NOINFO reason=necessary-not-satisfied(nec23=…,nec24=…)` 并折 `cannot`
  #       （**不得**再出现「必要件未成立却以"只有必要条件"为由」的**机读理由与事实相反**；缺整条 `leg_*.env` 走
  #       `N1_NECMISS` 支 ⇒ `reason=necessary-input-missing(leg…(env-absent))`，与前者**形态可分**）。
  if [ "$PHASE" = realized ]; then
    local _pos="" _n4miss=0 _anchor=0 _differ=0 _via="" _exproof="${PTS_N3_SAME_CONTENT_PROOF:-}" _exgo=0
    # (a) N4 正身份登记载体
    # ⏪ `t145`（`t142` 的 `C-C`；**堵"登记即算"的声明式假绿通道**）：`n4` 源**只有指纹对拍**是不够的 ——
    #   登记位**必须再带一条独立可证伪读数**（守卫**自己现算**的色锚 px：读什么＝该页帧四色 px；命令＝`color_px_scan`；值＝逐色 px）。
    #   ⇒ 登记匹配 ∧ 支撑成片 才计入 `n4`；**只登记、无支撑** ⇒ `N4-DECLARED-ONLY`、**不给绿**（折 `cannot`）。
    if [ -n "${PTS_N4_POSITIVE_FP:-}" ]; then
      if [ "${PTS_N4_POSITIVE_FP}" = "${N1_SHA_23},${N1_SHA_24}" ]; then
        _n4sup="$(color_px_scan "$dir/shots/g1/k24.png" "$COLOR_ANCHOR_K24" 2>/dev/null || true)"
        _n4hit="$(color_anchor_hits "${_n4sup:-}")"
        if [ "${_n4hit:-0}" -ge 2 ]; then
          _pos="${_pos:+$_pos,}n4(support=color-anchor:${_n4hit}colors>=${COLOR_ANCHOR_MIN})"
        else
          echo "  N4-DECLARED-ONLY declaration=${PTS_N4_POSITIVE_FP}（**登记位没有独立可证伪支撑** ⇒ 不算正身份证据、**不给绿**）support=color-anchor 现算=${_n4sup:-unreadable} min=${COLOR_ANCHOR_MIN} 反极基线=现盘空态帧四色全 0"
          echo "PTS_N4=DECLARED-ONLY phase=$PHASE reason=n4-registration-without-independent-support declaration=${PTS_N4_POSITIVE_FP} support_hits=${_n4hit:-0} support_scan=${_n4sup:-none} support_min=${COLOR_ANCHOR_MIN}"
          cannot+=("n4-declared-only(no-independent-support)")
        fi
      else
        _n4miss=1
      fi
    else
      _n4miss=1
    fi
    # (b) 内容锚
    _anchor="$(grep -c -E "${PTS_CONTENT_ANCHOR_RE:-[Nn]eptune}" "$dir/app_g1.log" 2>/dev/null || true)"
    case "${_anchor:-}" in ''|*[!0-9]*) _anchor=0;; esac
    [ "$_anchor" -gt 0 ] && _pos="${_pos:+$_pos,}anchor(hits=$_anchor)"
    # (c) 两页帧真不同
    if [ -s "$dir/shots/g1/k23.png" ] && [ -s "$dir/shots/g1/k24.png" ] && command -v compare >/dev/null 2>&1; then
      _ae="$(compare -metric AE "$dir/shots/g1/k23.png" "$dir/shots/g1/k24.png" null: 2>&1 | tr -dc '0-9' | head -c 9)"
      _via="compare"; [ -n "${_ae:-}" ] && [ "$_ae" -gt 0 ] && _differ=1
    elif [ -n "${N1_SHA_23:-}" ] && [ -n "${N1_SHA_24:-}" ] && [ "${N1_SHA_23}" != "${N1_SHA_24}" ]; then
      _differ=1; _via="fr-sha-inequality"
    fi
    [ "$_differ" = 1 ] && _pos="${_pos:+$_pos,}differ(via=$_via)"
    # N3 例外支：声明 ＋ 两页都确已绘出内容
    if [ -n "$_exproof" ] && [ "${N1_INK_23:-}" -gt 0 ] 2>/dev/null && [ "${N1_INK_24:-}" -gt 0 ] 2>/dev/null; then _exgo=1; fi
    echo "PTS_N1_POS=phase=$PHASE positive=${_pos:-none} n4=${PTS_N4_POSITIVE_FP:-absent} anchor_hits=$_anchor differ=$_differ via=${_via:-none} n4_unregistered=$_n4miss exception_proof=${_exproof:+declared} exception_applies=$_exgo（三源口径见 t136 段；「∉ 参照集」单独**不给绿**）"
    if [ -n "${N1_NECMISS:-}" ]; then
      echo "PTS_N1_GATE=NOINFO phase=$PHASE reason=necessary-input-missing($N1_NECMISS)（必要件取值缺 ⇒ 本闸不可算 ⇒ 绝不当绿）"
      cannot+=("n1-gate(necessary-input-missing=$N1_NECMISS)")
    elif [ -n "$_pos" ]; then
      echo "PTS_N1_GATE=PASS phase=$PHASE positive=$_pos necessary=frame-identity,frame-displacement（正证据在场 ⇒ 必要件之上**重新**成立；这不改变既有四要件）"
    elif [ "$_exgo" = 1 ]; then
      echo "PTS_N1_GATE=EXCEPTION phase=$PHASE reason=n3-same-content-definition-declared（N3 例外支成立 ⇒ **免红**；⚠️ 这只是"不据此判红"，**不冒充**排版正身份）"
    elif [ "${N1_NEC_23:-no}" = yes ] && [ "${N1_NEC_24:-no}" = yes ]; then
      echo "  N1-ONLY-NECESSARY positive=none n4=absent anchor_hits=$_anchor differ=0 reason=only-necessary-condition-no-positive-evidence（realized 期**两腿必要件都成立**、**只有必要条件、缺正证据** ⇒ 不许给排版绿）"
      echo "PTS_N1_GATE=FAIL phase=$PHASE positive=none sha23=${N1_SHA_23:-none} sha24=${N1_SHA_24:-none} nec23=yes nec24=yes reason=only-necessary-condition-no-positive-evidence"
      fails+=("n1-only-necessary-condition-no-positive-evidence(sha23=${N1_SHA_23:-none},sha24=${N1_SHA_24:-none},anchor=0,n4=absent)")
    else
      # ⏪ `t144`（`t139` `F-1`；**加前置、消「机读理由与事实相反」**）：两腿**必要件并未成立**（要件① ∈ 参照集／要件② 位移=0／取值不在位）
      #   ⇒ 本闸**不可算** ⇒ 印 `NOINFO reason=necessary-not-satisfied` 并折 `cannot`；
      #   **不得**印 `only-necessary-condition-no-positive-evidence`（那句的前提是"必要件成立"，此处与事实相反）。
      echo "  N1-NECESSARY-NOT-SATISFIED nec23=${N1_NEC_23:-absent} nec24=${N1_NEC_24:-absent} sha23=${N1_SHA_23:-none} sha24=${N1_SHA_24:-none}（realized 期**必要件并未成立** ⇒ 本闸**不可算** ⇒ 不得以"只有必要条件"为由判红/判绿）"
      echo "PTS_N1_GATE=NOINFO phase=$PHASE reason=necessary-not-satisfied(nec23=${N1_NEC_23:-absent},nec24=${N1_NEC_24:-absent}) sha23=${N1_SHA_23:-none} sha24=${N1_SHA_24:-none}"
      cannot+=("n1-gate(necessary-not-satisfied=nec23:${N1_NEC_23:-absent},nec24:${N1_NEC_24:-absent})")
    fi
  fi

  # ── ⏪ `t145`（`t142` 的 `C-A`）**色锚读数**（**预先就位、不等相位翻转；两相位都跑**） ────────────────────
  #   判据（逐字）：
  #     · **基线标定**：`$COLOR_ANCHOR_BASE_FRAME`（默认 `boot.png`，现盘空态帧）上四色**实算必须全 0** ——
  #       有任一枚 >0 ⇒ 该色**在本帧不可判别**（死锚，同 `LightGray`）⇒ 本面 `NOINFO reason=anchor-dead-in-base(...)`（**不给绿**）；
  #     · **缺席即红**：`k=24` 该帧里四色**达到下限的个数 < 2** ⇒ **必红并点名**（哪几个色／期望 `>=${COLOR_ANCHOR_MIN}`／实测 px／基线值）；
  #     · **`k=23` 无登记锚** ⇒ `NOINFO reason=no-anchor-registered-for-k23`（**严禁**拿 k=24 推广）；
  #     · 帧不在 ⇒ `NOINFO reason=frame-absent`（**绝不当 0、绝不当绿**）。
  #   ⚠️ **今天必红是预期结果**（两页今天都没绘出内容）—— 本块**如实把它跑成红**，**不放松阈值**。
  local _ca_base _ca_base_out _ca_dead="" _ca_out _ca_hit _caf
  _ca_base="$dir/shots/g1/$COLOR_ANCHOR_BASE_FRAME"
  _ca_base_out="$(color_px_scan "$_ca_base" "$COLOR_ANCHOR_K24" 2>/dev/null || true)"
  for pair in $_ca_base_out; do v="${pair#*=}"; case "$v" in ''|*[!0-9]*) continue;; esac; [ "$v" -gt 0 ] && _ca_dead="${_ca_dead}${_ca_dead:+,}${pair%%=*}"; done
  echo "PTS_COLORANCHOR_BASE=frame=$COLOR_ANCHOR_BASE_FRAME scan=${_ca_base_out:-unreadable} min=$COLOR_ANCHOR_MIN all_zero=$([ -z "$_ca_dead" ] && echo yes || echo no) dead=${_ca_dead:-none}（**阈值由本基线标定**：基线全 0 ⇒ 该计数能分开"有该色/没该色"；${BT}LightGray${BT} 不入集——它在空态帧里已有 44/51 px）"
  for _caf in 24 23; do
    if [ "$_caf" = 23 ]; then
      echo "PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=$PHASE（${BT}RichTextBoxDemo.xaml${BT} 无具名色 ⇒ **本页无锚**；**严禁**用 k=24 的锚推广。⏪ ${BT}t145${BT}：本支**只印具名 NOINFO 行、不折 ${BT}cannot${BT}** —— 否则任何"没有 k=24 帧"的证据目录都会被整体读成不可判；**本面不给绿**这一点不变）"
      continue
    fi
    if [ -n "$_ca_dead" ]; then
      echo "PTS_COLORANCHOR=NOINFO k=24 reason=anchor-dead-in-base(${_ca_dead}) phase=$PHASE（基线帧上该色已 >0 ⇒ 不可判别 ⇒ 绝不当绿）"
      cannot+=("color-anchor(anchor-dead-in-base=${_ca_dead})")
      continue
    fi
    if [ ! -s "$dir/shots/g1/k24.png" ]; then
      echo "PTS_COLORANCHOR=NOINFO k=24 reason=frame-absent($dir/shots/g1/k24.png) phase=$PHASE（帧不在 ⇒ 本面不可算 ⇒ **不给绿**；⏪ ${BT}t145${BT}：本支**不折 ${BT}cannot${BT}**，理由同 k=23 支——而"登记即算"那条假绿通道**照样堵住**：没有帧 ⇒ ${BT}n4${BT} 的**独立支撑**也取不到 ⇒ ${BT}n4${BT} 不计证据）"
      continue
    fi
    _ca_out="$(color_px_scan "$dir/shots/g1/k24.png" "$COLOR_ANCHOR_K24" 2>/dev/null || true)"
    if [ -z "$_ca_out" ]; then
      echo "PTS_COLORANCHOR=NOINFO k=24 reason=scan-unreadable phase=$PHASE（扫描器读不到 ⇒ 不可算 ⇒ 绝不当绿）"
      cannot+=("color-anchor(scan-unreadable)")
      continue
    fi
    _ca_hit="$(color_anchor_hits "$_ca_out")"
    if [ "${_ca_hit:-0}" -ge 2 ]; then
      echo "PTS_COLORANCHOR=PASS k=24 scan=$_ca_out hits=$_ca_hit min=$COLOR_ANCHOR_MIN base=${_ca_base_out:-unreadable} phase=$PHASE（该页**具名色成片出现** ⇒ 该页内容至少部分真绘出；⚠️ **只准读成这一件事**，不得替代 ${BT}N1${BT}/${BT}N3${BT}）"
    else
      echo "  COLOR-ANCHOR-ABSENT k=24 expect>=${COLOR_ANCHOR_MIN}px&hits>=2 measured=$_ca_out hits=$_ca_hit baseline($COLOR_ANCHOR_BASE_FRAME)=${_ca_base_out:-unreadable} phase=$PHASE（${BT}FlowDocumentDemo${BT} 的具名色**应有而未现** ⇒ 该页**没绘出内容**）"
      echo "PTS_COLORANCHOR=FAIL k=24 scan=$_ca_out hits=$_ca_hit expect_min=$COLOR_ANCHOR_MIN expect_hits=2 baseline=${_ca_base_out:-unreadable} phase=$PHASE reason=declared-color-anchor-absent"
      fails+=("leg24-color-anchor-absent(hits=$_ca_hit<2,scan=$_ca_out)")
    fi
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

  # ── ⏪ `t122`（`t118` 的 `N2` 接线；**方向＝收紧**）：**ENFE 面** —— "内容没画出来"不得读成"排版绿" ────────────
  #   口径（逐字）：`ENFE_TOTAL` ＝ `$dir/app_g1.log` 里 **`entry point named '<名>'`** 的**行数**
  #   （来源＝**应用日志**；与 `[HC-UNHANDLED]` 行**同源** —— 现取：二者计数相等）；`ENFE_BY_NAME` ＝ 按**入口名**直方图。
  #   ⏪ **dated 更正（`t144`／`t139` `F-2`；上句**原文保留**，以本行为准）**：该「同源／计数相等」**今天已解耦** ——
  #     两个量**各自定义、不得互相折算**：`ENFE_TOTAL` ＝ 日志里 `entry point named '<名>'` 的**行数**（**缺符号面**）；`[HC-UNHANDLED]`
  #     ＝ 同名标记的行数（**托管未处理异常面**）。现取实况：`ENFE_TOTAL=0` 而 `[HC-UNHANDLED]` 族 **1123**（内容为 `PtsException: Page formatting
  #     engine did not complete formatting operation …`）⇒ 二者**不可互折**。口径与 `build/MilBridge/P1-realized-criteria-report.md` 的 `t136` 段（`O-1`）**一致**。
  #   **非目标 allowlist** ＝ `PTS_ENFE_ALLOWLIST`（**逗号分隔的入口名**；**默认空** ⇒ "一个都不许"）；
  #   allowlist 里的名**逐名可核**（判词行打印 `allow=` 与 `non_allow=`，且红行**点名每一个** non_allow 名与计数）。
  #   **判据**：**`realized` 期**，`ENFE_TOTAL>0` ∧ `non_allow` 非空 ⇒ **红并点名**（名＋计数）；
  #   `degraded` 期**不据此判红**（止损期的绿语义是"占位还在"，与 ENFE 不冲突）⇒ 只印 `PTS_ENFE=INFO …`（**可见**）。
  #   日志取不到 ⇒ `PTS_ENFE=NOINFO` ＋ `cannot+=`（**绝不当绿**）。
  #   ⚠️ 本条的**依据**：`t119` 现取 —— 渲染循环每次布局都抛 `FsCreatePageBottomless`，两页停在同一回退画面，
  #   而当时的 `realized` 四要件（`magenta=0` ∧ 无具名行 ∧ `ink>0` ∧ `native_gap=0`）**全成立** ⇒ 会 `PASS`。
  #   本接线**只增不减**：既不放松任何既有要件，也不改三态语义（`PASS`／`FAIL`／`NOINFO`）。
  _elog="$dir/app_g1.log"; _etot=0; _enames=""; _enallow="${PTS_ENFE_ALLOWLIST:-}"; _enonallow=""
  if [ -s "$_elog" ]; then
    _etot="$(grep -c 'entry point named ' "$_elog" 2>/dev/null || true)"; _etot="${_etot:-0}"
    _enames="$(grep -o "entry point named '[A-Za-z0-9_]*'" "$_elog" 2>/dev/null \
                | sed "s/.*named '//;s/'$//" | LC_ALL=C sort | uniq -c | sort -rn | awk '{printf "%s:%s,", $2, $1}')"
    for _n in $(grep -o "entry point named '[A-Za-z0-9_]*'" "$_elog" 2>/dev/null | sed "s/.*named '//;s/'$//" | LC_ALL=C sort -u); do
      case ",$_enallow," in
        *",$_n,"*) ;;                                   # 在 allowlist（非目标）里 ⇒ 不计入 non_allow
        *) _enonallow="${_enonallow}${_n}," ;;
      esac
    done
    # ⏪ `t136`（`t120` 的 `F-2`）：**`ENFE_TOTAL` 的任何引用必须绑「哪一份日志 ＋ `sha16`」** ⇒ 每条判词行带 `log=`／`log_sha16=`
    _esha="$(sha256sum "$_elog" 2>/dev/null | cut -c1-16)"; [ -n "${_esha:-}" ] || _esha='-'
    if [ "$PHASE" = realized ]; then
      if [ "$_etot" -gt 0 ] && [ -n "$_enonallow" ]; then
        echo "  ENFE-UNHANDLED total=$_etot non_allow=${_enonallow%,}（realized 期**内容没画出来** ⇒ **不许给排版绿**） reason=enfe-present-after-phase-realized by_name=$_enames log=${_elog} log_sha16=$_esha"
        echo "PTS_ENFE=FAIL total=$_etot by_name=${_enames:-none} allow=${_enallow:-none} non_allow=${_enonallow%,} phase=realized log=${_elog} log_sha16=$_esha reason=enfe-present-after-phase-realized"
        fails+=("enfe-unhandled(total=$_etot,non_allow=${_enonallow%,})")
      else
        echo "PTS_ENFE=PASS total=$_etot by_name=${_enames:-none} allow=${_enallow:-none} non_allow=none phase=realized log=${_elog} log_sha16=$_esha"
      fi
    else
      echo "PTS_ENFE=INFO total=$_etot by_name=${_enames:-none} allow=${_enallow:-none} non_allow=${_enonallow:-none} phase=degraded log=${_elog} log_sha16=$_esha（止损期不据此判红；相位翻转后本条生效 —— 口径见 t122 段；**引用必须连 log ＋ log_sha16 一起引**，见 t136 F-2）"
    fi
  else
    echo "PTS_ENFE=NOINFO reason=enfe-log-absent($_elog)（日志不在 ⇒ ENFE 面**不可算** ⇒ 绝不当绿）"
    cannot+=("enfe-log-absent")
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
    # ⏪ `t124`（`N1` 接线）：夹具的 `FRAME` 行（**第五段**）。第 14 位 ＝ `fr_sha`（**缺省＝不在参照集里的一枚
    #   形状合法 `sha16`** ⇒ 既有腿**不被 `N1` 扰动**）、第 15 位 ＝ `fr_ae_boot`（缺省 12345>0）。两条腿各自一条。
    printf 'FRAME k=%s fr_file=k%s.png fr_sha=%s fr_lsha=%s fr_ae_boot=%s\n' \
      "$2" "$2" "${14:-cafebabe12345678}" "${14:-cafebabe12345678}" "${15:-12345}" >> "$d/leg_$2.env"
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
  mkdir -p "$T/c10"
  # ⏪ `t122`：**夹具的 app 日志**由 `mk()` 自带的 `TAB entry=<在册名>` 行提供（`ENFE_TOTAL=0`）⇒ 既有腿的期望不受 `N2` 接线影响。
                                        chk NOINFO "$(out "$(judge_legs "$T/c10")")" "空证据目录"
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
                  # ⏪ `t136`：期望由 `PASS` 收紧为 `FAIL`（必要件齐但**无正证据** ⇒ 不许给排版绿）
                  rz c15 FAIL "realized·真实形态（必要件齐但无正证据 ⇒ 必红）"
  # ⑯ realized 期：**缺 ink 证据位** ⇒ NOINFO（不许因 magenta=0 判绿）
  rm -rf "$T/c16"; mk c16 24 yes 143 0 900 HandyControlDemo.UserControl.FlowDocumentDemo - 0 - yes yes
                  mk c16 23 yes 143 0 880 HandyControlDemo.UserControl.RichTextBoxDemo  - 0 - yes yes
                  # ⏪ `t136`：期望由 `NOINFO` 收紧为 `FAIL`（同上；`cannot=` 仍印缺 ink 那一格）
                  rz c16 FAIL "realized·缺 ink（且无正证据）⇒ 必红"
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

  # ── ⏪ `t122`（`N2` 接线）三条极性腿：**有 ENFE ⇒ 红并点名**／**干净 ⇒ 不因该条红**／**allowlist ⇒ 放行且逐名可核** ──
  _nfe="$T/c32"; rm -rf "$_nfe"
  mk c32 24 yes 143 0 900 HandyControlDemo.UserControl.FlowDocumentDemo - 0 - yes yes 12345
  mk c32 23 yes 143 0 880 HandyControlDemo.UserControl.RichTextBoxDemo  - 0 - yes yes 12001
  cat >>"$_nfe/app_g1.log" <<'ENFE_EOF'
[HC-UNHANDLED] #1 EntryPointNotFoundException: Unable to find an entry point named 'FsCreatePageBottomless' in shared library 'libwpfwin32.so'.
[HC-UNHANDLED] #2 EntryPointNotFoundException: Unable to find an entry point named 'FsCreatePageBottomless' in shared library 'libwpfwin32.so'.
[HC-UNHANDLED] #3 EntryPointNotFoundException: Unable to find an entry point named 'FsCreatePageFinite' in shared library 'libwpfwin32.so'.
ENFE_EOF
  _o="$(bash "$_rz" --legs "$_nfe" 2>&1 || true)"
  chk FAIL "$(out "$_o")" "realized·ENFE>0 ⇒ 必红"
  if grep -qF 'non_allow=FsCreatePageBottomless,FsCreatePageFinite' <<<"$_o" && grep -qF 'total=3' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "realized·ENFE 点名(名+计数)" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "realized·ENFE 点名(名+计数)" "no" "non_allow=…,total=3"
  fi
  _nfe2="$T/c33"; rm -rf "$_nfe2"; cp -a "$_nfe" "$_nfe2"
  _o="$(PTS_ENFE_ALLOWLIST=FsCreatePageBottomless,FsCreatePageFinite bash "$_rz" --legs "$_nfe2" 2>&1 || true)"
  # ⏪ `t136`：期望由 `PASS` 收紧为 `FAIL`（该夹具亦无 `N1` 正证据 ⇒ 由新闸点红；ENFE 那一条本身仍不红）
  chk FAIL "$(out "$_o")" "realized·ENFE 全在 allowlist（但无 N1 正证据 ⇒ 整步红）"
  if grep -qF 'allow=FsCreatePageBottomless,FsCreatePageFinite' <<<"$_o" && grep -qF 'non_allow=none' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "allowlist 逐名可核" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "allowlist 逐名可核" "no" "allow=… 且 non_allow=none"
  fi
  _nfe3="$T/c34"; rm -rf "$_nfe3"; cp -a "$_nfe" "$_nfe3"
  _o="$(bash "$0" --legs "$_nfe3" 2>&1 || true)"      # degraded 期：不据此判红（只印 INFO）
  if grep -qF 'PTS_ENFE=INFO' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "degraded·ENFE 只印 INFO" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "degraded·ENFE 只印 INFO" "no" "PTS_ENFE=INFO"
  fi
  # 反腿：**删掉 app 日志** ⇒ ENFE 面 NOINFO（**不当绿**）
  _nfe4="$T/c35"; rm -rf "$_nfe4"; cp -a "$_nfe" "$_nfe4"; rm -f "$_nfe4/app_g1.log"
  _o="$(bash "$_rz" --legs "$_nfe4" 2>&1 || true)"
  if grep -qF 'PTS_ENFE=NOINFO reason=enfe-log-absent' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "日志缺 ⇒ ENFE 面 NOINFO" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "日志缺 ⇒ ENFE 面 NOINFO" "no" "PTS_ENFE=NOINFO"
  fi

  # ── ⏪ `t124`（`N1` 接线）四条极性腿 ＋ 一条 `degraded` 反腿：**帧∈空态集 ⇒ 红点名**／**帧∉集∧位移>0 ⇒ 本条不红**／
  #    **位移=0 ⇒ 红点名**／**取值缺 ⇒ NOINFO（不当绿）**／**`degraded` 期只印 `INFO` 且不判红** ──
  #    夹具缺省（`mk` 第 14/15 位）＝ 不在参照集里的一枚形状合法 `sha16` ＋ `ae_boot=12345` ⇒ 既有腿**不被 `N1` 扰动**；
  #    下面四条腿**只改 `FRAME` 行的取值**（`c36 → c37` 只动 `fr_sha` ⇒ **因果证明**：判词由 `FAIL` 翻成 `PASS`）。
  _f1="$T/c36"; rm -rf "$_f1"
  mk c36 24 yes 143 0 900 HandyControlDemo.UserControl.FlowDocumentDemo - 0 - yes yes 12345 1a76488aa4a790b3 15385
  mk c36 23 yes 143 0 880 HandyControlDemo.UserControl.RichTextBoxDemo  - 0 - yes yes 12001 1a76488aa4a790b3 15385
  _o="$(bash "$_rz" --legs "$_f1" 2>&1 || true)"
  chk FAIL "$(out "$_o")" "realized·帧∈空态集 ⇒ 必红"
  # ⏪ `t157`：期望串里的**参照集文本从唯一登记处（`$FRAME_EMPTY_SET`）现取**（原来硬写两成员字面）
  #   —— 判据本身**一字未松**：仍是"帧∈集 ⇒ 必红 **并点名**"的逐字子串断言，只是不再会随集合登记漂移。
  if grep -qF 'criterion=frame-identity' <<<"$_o" && grep -qF "sha16=1a76488aa4a790b3∈{${FRAME_EMPTY_SET}}" <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "N1·点名(帧+要件+参照集)" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "N1·点名(帧+要件+参照集)" "no" "criterion=frame-identity…∈{…}"
  fi
  _f2="$T/c37"; rm -rf "$_f2"; cp -a "$_f1" "$_f2"
  sed -i 's/fr_sha=1a76488aa4a790b3/fr_sha=c0ffee1234abcd99/' "$_f2/leg_23.env" "$_f2/leg_24.env"
  _o="$(bash "$_rz" --legs "$_f2" 2>&1 || true)"
  # ⏪ `t136`：期望由 `PASS` 收紧为 `FAIL`（该腿原意＝"必要件齐即不红"，正是 `t120` 的**假绿形态**）
  chk FAIL "$(out "$_o")" "realized·帧∉集∧位移>0 **但只有必要件** ⇒ 必红"
  if [ "$(diff <(sort "$_f1/leg_24.env") <(sort "$_f2/leg_24.env") | grep -c '^[<>]')" = 2 ]; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "N1·因果(只 fr_sha 变)" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "N1·因果(只 fr_sha 变)" "no" "2 行差(每腿 1 行)"
  fi
  _f3="$T/c38"; rm -rf "$_f3"; cp -a "$_f2" "$_f3"
  sed -i 's/fr_ae_boot=[0-9][0-9]*/fr_ae_boot=0/' "$_f3/leg_23.env" "$_f3/leg_24.env"
  _o="$(bash "$_rz" --legs "$_f3" 2>&1 || true)"
  chk FAIL "$(out "$_o")" "realized·位移=0 ⇒ 红"
  if grep -qF 'criterion=frame-displacement(ae_boot=0)' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "N1·位移 0 点名" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "N1·位移 0 点名" "no" "criterion=frame-displacement(ae_boot=0)"
  fi
  _f4="$T/c39"; rm -rf "$_f4"; cp -a "$_f2" "$_f4"
  sed -i '/^FRAME k=/d' "$_f4/leg_23.env" "$_f4/leg_24.env"
  _o="$(bash "$_rz" --legs "$_f4" 2>&1 || true)"
  chk NOINFO "$(out "$_o")" "realized·取值缺 ⇒ NOINFO"
  if grep -qF 'reason=frame-cell-missing-or-unparsable' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "N1·缺格 ⇒ NOINFO(不当绿)" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "N1·缺格 ⇒ NOINFO(不当绿)" "no" "PTS_N1=NOINFO reason=frame-cell-missing"
  fi
  _o="$(bash "$0" --legs "$_f1" 2>&1 || true)"
  if grep -qF 'PTS_N1=INFO' <<<"$_o" && ! grep -qF 'criterion=frame-identity' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "degraded·N1 只印 INFO" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "degraded·N1 只印 INFO" "no" "PTS_N1=INFO 且无 criterion=frame-identity"
  fi
  # ── ⏪ `t136` 新极性腿：**累积登记集成员 ⇒ 红**／**只有必要件 ⇒ 红**／**例外支成立 ⇒ 不红**／
  #    **同夹具去掉例外声明 ⇒ 红（因果对）**／**内容锚 ⇒ 正证据**／**`N4` 登记匹配 ⇒ 正证据** ──
  _g1="$T/c40"; rm -rf "$_g1"     # (a) 新登记的成员 `ef3fd6765f18f51b`（旧"作废"值）⇒ 必红
  mk c40 24 yes 143 0 900 HandyControlDemo.UserControl.FlowDocumentDemo - 0 - yes yes 12345 ef3fd6765f18f51b 15386
  mk c40 23 yes 143 0 880 HandyControlDemo.UserControl.RichTextBoxDemo  - 0 - yes yes 12001 ef3fd6765f18f51b 15386
  _o="$(bash "$_rz" --legs "$_g1" 2>&1 || true)"
  chk FAIL "$(out "$_o")" "realized·累积集新成员 ⇒ 必红"
  if grep -qF "sha16=ef3fd6765f18f51b∈{${FRAME_EMPTY_SET}}" <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t136·新成员点名(累积集)" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t136·新成员点名(累积集)" "no" "sha16=ef3f…∈{1a76…,ef3f…}"
  fi
  # ── ⏪ `t157` 新极性腿：**第三成员 β `b273ebecc332fc03`（本件并入）⇒ 必红并点名**（三成员**逐枚**都在 selftest 里成腿）──
  _g1b="$T/c44"; rm -rf "$_g1b"     # (a') β 形状（`colors 391`／`ae_boot 14775`）的 `FRAME` 行 ⇒ 必红
  mk c44 24 yes 143 0 391 HandyControlDemo.UserControl.FlowDocumentDemo - 0 - yes yes 14775 b273ebecc332fc03 14775
  mk c44 23 yes 143 0 391 HandyControlDemo.UserControl.RichTextBoxDemo  - 0 - yes yes 12001 b273ebecc332fc03 14775
  _o="$(bash "$_rz" --legs "$_g1b" 2>&1 || true)"
  chk FAIL "$(out "$_o")" "t157·β(第三成员)∈集 ⇒ 必红"
  if grep -qF "sha16=b273ebecc332fc03∈{${FRAME_EMPTY_SET}}" <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t157·β 点名(三成员集)" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t157·β 点名(三成员集)" "no" "sha16=b273…∈{…}"
  fi

  _g2="$T/c41"; rm -rf "$_g2"     # (b) 只有必要件（两腿同帧 ⇒ 无 differ、无锚、无 N4）⇒ 必红并点名 reason
  mk c41 24 yes 143 0 900 HandyControlDemo.UserControl.FlowDocumentDemo - 0 - yes yes 12345 c0ffee1234abcd99 1234
  mk c41 23 yes 143 0 880 HandyControlDemo.UserControl.RichTextBoxDemo  - 0 - yes yes 12001 c0ffee1234abcd99 1234
  _o="$(bash "$_rz" --legs "$_g2" 2>&1 || true)"
  chk FAIL "$(out "$_o")" "realized·只有必要件 ⇒ 必红"
  if grep -qF 'PTS_N1_GATE=FAIL' <<<"$_o" && grep -qF 'reason=only-necessary-condition-no-positive-evidence' <<<"$_o"      && grep -qF 'PTS_N1_POS=phase=realized positive=none' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t136·缺正证据点名" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t136·缺正证据点名" "no" "PTS_N1_GATE=FAIL+reason=only-necessary…"
  fi
  _g3="$T/c42"; rm -rf "$_g3"     # (c) 例外支成立（声明 ＋ 两腿 ink>0）⇒ **不红**（正极）
  mk c42 24 yes 143 0 900 HandyControlDemo.UserControl.FlowDocumentDemo - 0 - yes yes 12345 c0ffee1234abcd99 1234
  mk c42 23 yes 143 0 880 HandyControlDemo.UserControl.RichTextBoxDemo  - 0 - yes yes 12001 c0ffee1234abcd99 1234
  _o="$(PTS_N3_SAME_CONTENT_PROOF='两页均为同一类型且内容定义相同（夹具声明）' bash "$_rz" --legs "$_g3" 2>&1 || true)"
  chk PASS "$(out "$_o")" "t136·例外支成立 ⇒ 不红（正极）"
  if grep -qF 'PTS_N1_GATE=EXCEPTION' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t136·例外支点名" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t136·例外支点名" "no" "PTS_N1_GATE=EXCEPTION"
  fi
  _o="$(bash "$_rz" --legs "$_g3" 2>&1 || true)"     # (因果对) 同一夹具**去掉**例外声明 ⇒ 必红
  chk FAIL "$(out "$_o")" "t136·同夹具无例外声明 ⇒ 必红（因果对）"
  _g4="$T/c44"; rm -rf "$_g4"     # (b′) 内容锚命中 >0 ⇒ 正证据 `anchor`
  mk c44 24 yes 143 0 900 HandyControlDemo.UserControl.FlowDocumentDemo - 0 - yes yes 12345 c0ffee1234abcd99 1234
  mk c44 23 yes 143 0 880 HandyControlDemo.UserControl.RichTextBoxDemo  - 0 - yes yes 12001 c0ffee1234abcd99 1234
  printf 'neptune-anchor: content drawn (夹具在册锚)\n' >> "$_g4/app_g1.log"
  _o="$(bash "$_rz" --legs "$_g4" 2>&1 || true)"
  chk PASS "$(out "$_o")" "t136·内容锚 >0 ⇒ 正证据 anchor"
  if grep -qF 'positive=anchor(hits=1)' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t136·anchor 点名" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t136·anchor 点名" "no" "positive=anchor(hits=1)"
  fi
  _g5="$T/c45"; rm -rf "$_g5"     # (a′) `N4` 正身份登记匹配 ⇒ 正证据 `n4`
  mk c45 24 yes 143 0 900 HandyControlDemo.UserControl.FlowDocumentDemo - 0 - yes yes 12345 0a0b0c0d0e0f1011 1234
  mk c45 23 yes 143 0 880 HandyControlDemo.UserControl.RichTextBoxDemo  - 0 - yes yes 12001 1213141516171819 1234
  _o="$(PTS_N4_POSITIVE_FP='1213141516171819,0a0b0c0d0e0f1011' bash "$_rz" --legs "$_g5" 2>&1 || true)"
  # ⏪ `t145`（`C-C`）：期望由 `PASS` **收紧**为 `NOINFO` —— 该夹具**没有帧** ⇒ 登记位**拿不到独立支撑** ⇒ 不算正身份证据
  chk NOINFO "$(out "$_o")" "t136·N4 登记匹配但无支撑 ⇒ 不给绿（t145 收紧）"
  # ⏪ `t145`（`C-C`）：该夹具**没有帧** ⇒ 登记位拿不到独立支撑 ⇒ `positive` 里**不应**再出现 `n4`（只剩 `differ`）——**方向只有收紧**
  if grep -qF 'positive=differ' <<<"$_o" && ! grep -qE 'positive=[^ ]*n4' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t136/t145·无支撑 ⇒ positive 不含 n4" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t136/t145·无支撑 ⇒ positive 不含 n4" "no" "positive=differ 且无 n4"
  fi

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
  # ── ⏪ `t144`（`t139` `F-1`）三条腿：**必要件成立 ⇒ 仍红（保持）**／**必要件不成立 ⇒ 闸 NOINFO 且 fails= 无相反 reason**／
  #    **缺整条 leg_*.env ⇒ 第三态（形态可分）**；另给"拆掉新逻辑 ⇒ 该腿必 ✗"的**承重证明**（见载体）。 ──
  _h7="$T/c46"; rm -rf "$_h7"
  mk c46 24 yes 143 0 900 HandyControlDemo.UserControl.FlowDocumentDemo - 0 - yes yes 12345 c0ffee1234abcd99 1234
  mk c46 23 yes 143 0 880 HandyControlDemo.UserControl.RichTextBoxDemo  - 0 - yes yes 12001 c0ffee1234abcd99 1234
  _o="$(bash "$_rz" --legs "$_h7" 2>&1 || true)"
  chk FAIL "$(out "$_o")" "t144·(a) 必要件成立＋无正证据 ⇒ 红（保持）"
  if grep -qF 'PTS_N1_GATE=FAIL' <<<"$_o" && grep -qF 'nec23=yes nec24=yes' <<<"$_o" && grep -qF 'reason=only-necessary-condition-no-positive-evidence' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t144·(a) 前置在成立时放行" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t144·(a) 前置在成立时放行" "no" "GATE=FAIL+nec23=yes nec24=yes"
  fi
  _h8="$T/c47"; rm -rf "$_h8"
  mk c47 24 yes 143 0 900 HandyControlDemo.UserControl.FlowDocumentDemo - 0 - yes yes 12345 1a76488aa4a790b3 15386
  mk c47 23 yes 143 0 880 HandyControlDemo.UserControl.RichTextBoxDemo  - 0 - yes yes 12001 1a76488aa4a790b3 15386
  _o="$(bash "$_rz" --legs "$_h8" 2>&1 || true)"
  if grep -qF 'PTS_N1_GATE=NOINFO' <<<"$_o" && grep -qF 'reason=necessary-not-satisfied(nec23=no,nec24=no)' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t144·(b) 要件①不成立 ⇒ 闸 NOINFO 具名" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t144·(b) 要件①不成立 ⇒ 闸 NOINFO 具名" "no" "GATE=NOINFO+necessary-not-satisfied"
  fi
  if ! grep -qF 'only-necessary-condition-no-positive-evidence' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t144·(b) fails= 无相反 reason" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t144·(b) fails= 无相反 reason" "no" "不出现 only-necessary…"
  fi
  chk FAIL "$(out "$_o")" "t144·(b) 整步仍红（因 ∈ 参照集的腿级红）"
  _h9="$T/c48"; rm -rf "$_h9"; cp -a "$_h7" "$_h9"; rm -f "$_h9/leg_23.env"
  _o="$(bash "$_rz" --legs "$_h9" 2>&1 || true)"
  if grep -qF 'reason=necessary-input-missing(leg23(env-absent))' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t144·(c) 缺整条 env ⇒ 第三态可分" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t144·(c) 缺整条 env ⇒ 第三态可分" "no" "reason=necessary-input-missing(leg23(env-absent))"
  fi
  # ── ⏪ `t145`（`t142` 的 `C-C`／`C-A`）四条腿：**登记无支撑 ⇒ N4-DECLARED-ONLY／不给绿**／
  #    **登记＋支撑成片 ⇒ `n4` 计证据（正极）**／**色锚缺席 ⇒ 必红点名**／**`k=23` 无锚 ⇒ 具名 NOINFO** ──
  _n4a="$T/c50"; rm -rf "$_n4a"
  mk c50 24 yes 143 0 900 HandyControlDemo.UserControl.FlowDocumentDemo - 0 - yes yes 12345 0a0b0c0d0e0f1011 1234
  mk c50 23 yes 143 0 880 HandyControlDemo.UserControl.RichTextBoxDemo  - 0 - yes yes 12001 1213141516171819 1234
  _o="$(PTS_N4_POSITIVE_FP='1213141516171819,0a0b0c0d0e0f1011' bash "$_rz" --legs "$_n4a" 2>&1 || true)"
  if grep -qF 'PTS_N4=DECLARED-ONLY' <<<"$_o" && grep -qF 'reason=n4-registration-without-independent-support' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t145·(a) 登记无支撑 ⇒ DECLARED-ONLY" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t145·(a) 登记无支撑 ⇒ DECLARED-ONLY" "no" "PTS_N4=DECLARED-ONLY+reason"
  fi
  if ! grep -qE '^PTS_N1_POS=.*positive=[^ ]*n4' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t145·(a) positive 不含 n4" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t145·(a) positive 不含 n4" "no" "positive= 里不出现 n4"
  fi
  _n4b="$T/c51"; rm -rf "$_n4b"; cp -a "$_n4a" "$_n4b"; mkdir -p "$_n4b/shots/g1"
  python3 - "$_n4b/shots/g1" <<'PYIMG'
import sys, os
from PIL import Image
d = sys.argv[1]
def mk(name, spec):
    im = Image.new("RGB", (40, 40), (0, 0, 0))
    px = im.load(); i = 0
    for rgb, n in spec:
        for _ in range(n):
            px[i % 40, (i // 40) % 40] = rgb; i += 1
    im.save(os.path.join(d, name))
mk("boot.png", [((0, 0, 0), 1600)])                                     # 基线帧：四色全 0 ⇒ 标定成立
mk("k24.png", [((248, 248, 255), 300), ((245, 245, 220), 300), ((0, 0, 0), 1000)])
PYIMG
  _o="$(PTS_N4_POSITIVE_FP='1213141516171819,0a0b0c0d0e0f1011' bash "$_rz" --legs "$_n4b" 2>&1 || true)"
  if grep -qE 'positive=n4\(support=color-anchor' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t145·(b) 登记＋支撑成片 ⇒ n4 计证据" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t145·(b) 登记＋支撑成片 ⇒ n4 计证据" "no" "positive=n4(support=color-anchor:…)"
  fi
  chk PASS "$(out "$_o")" "t145·(b) 有支撑 ⇒ 正极 PASS"
  _n4c="$T/c52"; rm -rf "$_n4c"; cp -a "$_n4a" "$_n4c"; mkdir -p "$_n4c/shots/g1"
  python3 - "$_n4c/shots/g1" <<'PYIMG2'
import sys, os
from PIL import Image
d = sys.argv[1]
Image.new("RGB", (40, 40), (0, 0, 0)).save(os.path.join(d, "boot.png"))
Image.new("RGB", (40, 40), (250, 250, 250)).save(os.path.join(d, "k24.png"))   # 帧在、四色仍缺
PYIMG2
  _o="$(bash "$_rz" --legs "$_n4c" 2>&1 || true)"
  chk FAIL "$(out "$_o")" "t145·(c) 色锚缺席 ⇒ 必红（今天形态）"
  if grep -qF 'PTS_COLORANCHOR=FAIL' <<<"$_o" && grep -qF 'reason=declared-color-anchor-absent' <<<"$_o" && grep -qF 'expect_min=200' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t145·(c) 点名色/期望/实测/基线" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t145·(c) 点名色/期望/实测/基线" "no" "PTS_COLORANCHOR=FAIL+expect_min=200"
  fi
  if grep -qF 'PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t145·(d) k=23 无锚 ⇒ 具名 NOINFO" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t145·(d) k=23 无锚 ⇒ 具名 NOINFO" "no" "NOINFO no-anchor-registered-for-k23"
  fi
  if grep -qF 'PTS_COLORANCHOR_BASE=frame=boot.png' <<<"$_o" && grep -qF 'all_zero=yes' <<<"$_o"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "t145·(d) 基线标定 all_zero=yes" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "t145·(d) 基线标定 all_zero=yes" "no" "BASE…all_zero=yes"
  fi
  rm -rf "$T"
  printf 'PTS_GUARD_SELFTEST=%s pass=%d fail=%d\n' "$([ "$nfail" = 0 ] && echo PASS || echo FAIL)" "$npass" "$nfail"
  [ "$nfail" = 0 ]
}


# ══ ⏪ `t122`（`t118` 的 `N2`）**ENFE 面**：`realized` 期 `ENFE_TOTAL>0`（且不在 `PTS_ENFE_ALLOWLIST`）⇒ **红并点名**；
#    口径：`ENFE_TOTAL` ＝ `<证据目录>/app_g1.log` 里 `entry point named '<名>'` 的行数（与 `[HC-UNHANDLED]` 同源）；
#    ⏪ **dated 更正（`t144`／`t139` `F-2`；上句**原文保留**，以本行为准）**：**「同源」不等于"计数相等"** —— 两个量**各自定义、不得互相折算**
#      （`ENFE_TOTAL`＝缺符号面；`[HC-UNHANDLED]`＝托管未处理异常面）；现取：**0** vs **1123**；与判据件 `P1-realized-criteria-report.md` 的 `t136` 段（`O-1`）**一致**。
#    `degraded` 期只印 `PTS_ENFE=INFO`；日志缺 ⇒ `PTS_ENFE=NOINFO`（**绝不当绿**）。**只增不减、不动三态。**
# ══ ⏪ `t124`（`t118` 的 `N1`）**帧身份 ＋ 帧位移**：`realized` 期「`fr_sha` ∉ `FRAME_EMPTY_SET`（件头**唯一登记处**）
#     ∧ `fr_ae_boot>0`」两条**都要成立** ⇒ 任一不成立**红并点名**（哪一帧／哪个要件／实测值／参照集）；
#    `degraded` 期只印 `PTS_N1=INFO`；`FRAME` 行缺／值不可解析 ⇒ `PTS_N1=NOINFO` ＋ `cannot`（**绝不当绿**）。
#    装置侧取值格（`build/MilBridge/tests/PtsPagesProbe/session_inner.sh` 的 `FRAME` 行 → `legs-to-env.py` 的**第五段**）
#    与判据**同趟**建立：`fr_file`／`fr_sha`／`fr_lsha`／`fr_ae_boot` 的口径见那两件的注释。**只增不减、不动三态。**
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
