# VPts-R — `t53` 独立复核：`t52`（PTS 腿跑器装配口径 ＋ 硬闸 ＋ 两页可归因 ＋ 在册数同趟改齐）

**判词：`pass`**（三条验收逐条**我自己现跑/现算**通过；另附一条**低危观察**：显示旋钮不传播，见 §4）。
- 车道 `verifier`（`t53`，attempt `8af30c97-4033-48db-b344-a9620dfdb351`）；读时刻 `2026-09-28T09:46:50 … 09:49:23+08:00`。
- 重活：`~/heavy-slot.sh --min-avail 1500 --max-hold 900`（两趟，槽内 `30 s`／`17 s`；跑前现取 `df_avail_kB=85,561,752`、`mem_avail_MB=8737`）。**只读 `$N`**；私有 app 副本与证据全在 `~/w30x/`。

---

## §1 硬闸真判（验收①）—— 两条极性腿**我自己造**

**腿①a（旧代装配，门 1 在序）**：
```
$ PTS_GUARD_APPDIR=~/w30x/app-stale PTS_GUARD_DISPLAY=:238 \
    bash build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh ~/w30x/legs-pol1
POL1_RC=2
APPSYNC: SYNC-APPLOCAL=DRIFT target=/home/links-dev/w30x/app-stale items=5 ok=3 synced=0 created=0 drift=2 noauth=0 same=0 rc=3
device=NOINFO reason=app-stale detail=SYNC-APPLOCAL=DRIFT … drift=2 … rc=3
```
**腿①b（把门 1 用我车道的替身放行，专测 `t52` 那道门 1b 的判词）**：
```
$ PTS_GUARD_REPO=~/w30x/repo-stub PTS_GUARD_APPDIR=~/w30x/app-stale PTS_GUARD_DISPLAY=:236 bash ~/w30x/repo-stub/run-pts53.sh ~/w30x/legs-pol1b
POL1B_RC=2
APPSYNC: SYNC-APPLOCAL=OK target=…/app-stale items=5 ok=5 … drift=0 rc=0        ← 替身（只输出 drift=0）
AUTHORITY: shim=6825dd7071387a46 pf=876f70dd7c0cbf7a ｜ APPDIR: shim=fc60c34d51fd9247 pf=cbd1884faeb4837e
device=NOINFO reason=app-stale-vs-authority app_shim=fc60c34d51fd9247 auth_shim=6825dd7071387a46 app_pf=cbd1884faeb4837e auth_pf=876f70dd7c0cbf7a
  ∟ 装配口径坏 ⇒ 跑腿会产出**旧世界读数** ⇒ **拒跑**
```
⇒ **拒跑 ＋ `device=NOINFO reason=app-stale-vs-authority` ＋ rc=2 逐字成立** ✓。
注（口径）：真实门序下先撞**门 1**（`reason=app-stale`，同一份漂移被 `sync-applocal --check` 抓到，同样 rc=2）；门 1b 是**纵深**那一层 ⇒ 我把它单独测（§上）。

**腿②（现件口径 ⇒ 正常跑）**：见 §2／§3（同一趟）。

## §2 装配口径可证（验收②）—— 我自跑 `sha256sum`，不看它的自印

```
$ bash build/MilBridge/tools/sync-applocal.sh ~/w30x/app-auth        # SYNC_RC=0
$ sha256sum ~/w30x/app-auth/libwpfwin32.so ~/w30x/app-auth/PresentationFramework.dll | cut -c1-16
6825dd7071387a46        ← == authority（src/WpfGfx.Linux.Native/bin/libwpfwin32.so）
876f70dd7c0cbf7a        ← == authority（build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll）
```
跑腿器自己的前置印（我现读其输出）：`AUTHORITY: shim=6825dd7071387a46 pf=876f70dd7c0cbf7a ｜ APPDIR: shim=6825dd7071387a46 pf=876f70dd7c0cbf7a` ✓。
**跑完一次之后**（关键：今天坏就坏在"跑到一半被换回"）我**自己再算一遍**：
```
POSTSHIM: shim=6825dd7071387a46 pf=876f70dd7c0cbf7a（== authority ⇒ 读数可归因）
$ sha256sum ~/w30x/app-auth/libwpfwin32.so …/PresentationFramework.dll | cut -c1-16
6825dd7071387a46
876f70dd7c0cbf7a
```
⇒ **跑前==authority ∧ 跑后==authority** ✓（旧世界 `fc60c34d51fd9247`／`cbd1884faeb4837e` 已不再出现）。

## §3 两页可归因（验收③，我自己的运行）

`~/w30x/legs-pol2b/`（槽内 30 s，`X_UP=yes display=:238`，`APP_RC=143`，两页 `alive=yes`、`ns_last` 分别是 `…FlowDocumentDemo`／`…RichTextBoxDemo`）：
| 页 | `alive` | `rc` | 洋红 px（我自算 PNG） | `colors` | `ink` | 具名行 `entry=` |
|---|---|---|---|---|---|---|
| **24** `FlowDocumentDemo` | yes | 143 | **54826** | 851 | 423547 | **`LoCreateContext`**（`err=-10000`） |
| **23** `RichTextBoxDemo` | yes | 143 | **50236** | 843 | 428205 | **`LoCreateContext`**（`err=-10000`） |

- **我自己的** `app_g1.log`（112,680 B）逐字：`PTS_GAP entry=LoCreateContext seq=1 err=-10000 calls=1` ＋ 2× `[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage entry=LoCreateContext err=-10000 action=page-placeholder` ⇒ **`entry=` 从 `CreateInstalledObjectsInfo` 变成 `LoCreateContext` 这一格，由我自己的运行独立复现** ✓（旧代在册件 `3a3544fe9d6f8132` 是 `3× CreateInstalledObjectsInfo`）。
- 我用自己的 `shotstat.py` 现算我这趟 PNG：`k24 magenta=54826 ink=423547 colors=851`／`k23 magenta=50236 ink=428205 colors=843` ⇒ 与 `leg_*.env` **逐位相同** ✓；两页仍 ≥20000 ⇒ **止损仍在** ✓。
- 判据件对我自己的证据现判：`PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded` ✓。
- （旁证）在册 `evidence/app_g1.log` 现读 = `eb6af2e16ba2bcfb`／3× `entry=LoCreateContext`（`t55` 已按 `t13` F-A 走"甲"落齐，读时 `09:47:49`）⇒ **在册与车道两处逐字节同** ✓。

## §4 观察（**低危、不构成 needs_revision**）：显示旋钮**不传播** ⇒ 装置绿而应用连不上

我第一次跑腿②时把外跑器显示号改成 `:239`（`PTS_GUARD_DISPLAY=:239`），但 `session_inner.sh:18` 用的是**另一个**变量：
```
$ grep -n 'D=' build/MilBridge/tests/PtsPagesProbe/session_inner.sh
18:D="${W67_DISPLAY:-:237}"
```
⇒ Xvfb 开在 `:239`（`X_UP=yes display=:239`）而应用拿到 `DISPLAY=":237"` ⇒ 我那一趟的 app 日志逐字：
```
[WIN_DIAG] X 连接: dpy=无 x_failed=1 dpy_error="XOpenDisplay(":237") 失败：无 X server 或 DISPLAY 不可用"
Unhandled exception. System.ComponentModel.Win32Exception (1400)
APP_RC=134  alive=no   ← 判据侧会转成 FAIL（**红，不是假绿**）
```
⇒ **它不是假绿通道**（判据会红），但它是"装置自证绿、读数无效"的一族：**改动外显示号不会传到内跑器**。
`requiredFix`（低危）：在 `run-pts-pages-legs.sh` 里 `export W67_DISPLAY="$DISPLAY_NUM"`（或让 `session_inner.sh` 以 `PTS_GUARD_DISPLAY` 为先），并在门里断言两者相等。
**（这条是我自己的夹具错触发的，如实记为我的操作教训；`t52` 的默认路径不受影响。）**

## §5 在册数同趟改齐（验收④，附第 4 条）

- 牙现读（`09:48:45`）：**`PTSGAP=PASS tool=100 dead=11 artifact=1 ops=88 impl=95 so16=6825dd7071387a46 exports=556 root=$N`** ⇒ **`FAIL` 已消** ✓（我在 `t13` 已端到端独立复算过同一条算术链）。
- `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` 的机读行 = `tool=100 dead=11 artifact=1 ops=88 impl=95 so16=6825dd7071387a46 exports=556 w66pre16=bf6b683d94549087` ✓；`:36` 那条 `#78` 注释的陈旧 `impl=97` **已由 `t55` 同趟改准**（报告 §8.4：`eae178df2bd56e04 → cb1888419575ff88`）⇒ 我现读该注释为 `impl=95` ✓。
- 复述位（我自己的口径＝**行**，读时 `09:48:45`）：含 `实现口径 95`／`95 实现口径` 的**行 9 条／4 件**（`docs/ROUTES.md` 等）；仍含 `97` 的 5 处**全部**是历史/钉住件（`report:132` 的变更记录行、`ACCEPTANCE-BASELINE.md` 的冻结原文、`WAVE66-PREREGISTRATION.md:24` 的 `C1` 钉）⇒ **不是活的陈旧复述** ✓。
  ⚠️ 口径差异如实记：`t52` 自报"**7 处复述位**（`×10`／`×1`）"，我按**行**数得 **9 行／4 件**（两者的"处/次"口径不同）；结论（都改成 95）一致。

## §6 覆盖面位移具名（验收⑤）＋ 基线/推送

- **`inputs_fp`**：`#79` 在册 `4c096e9c0705a95d…` → `t44` 后 `37d4c6ab22f9606e…` → 我 `09:42:35` 现取 `c5c032d0bc75e199…` → **`09:48:45` 现取 `5aa65b7d9d706d50d9440ff172d4069e768e5656805bfb104803d6cf2c2d2aeb`**（`t55` 报告的同一新值，其读取时刻 `09:47:25` ⇒ 与我同值，稳定）。覆盖面 **226 件**。
- **哪几件变了**（我按 mtime > `#79` 冻点 `2026-09-28 01:12:39` 现算，`09:48:45`）：**29 件**，其中在覆盖面内且属本波的具名件 = `src/WpfGfx.Linux.Native/src/win32_pts.c`／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（`09:47:11`）／`build/MilBridge/tests/PtsPagesProbe/{run-pts-pages-legs.sh,session_inner.sh,legs-to-env.py,shotstat.py,evidence/**,evidence/shots/g1/*.png}`／`build/PresentationFramework.Linux/PtsCache.Linux.cs`／`build/MilBridge/tools/pts-pages-guard.sh`／`src/WpfGfx.Linux.Native/src/win32_classification.c`（`09:36:00`）等。
- **归 `t46`**：报告逐字——`135` 行「覆盖面包位移（给 `t46`）：`win32_pts.c`（在覆盖面内）＋`pts-gap-decl.txt`＋`close-wave.sh` 白名单件均改过 ⇒ `inputs_fp` **必移**」、`138` 行「⇒ **终值请 `t46` 在 `#80` 冻结时现取并冻进九位**（本趟**不冻不推**）」✓。
- **基线/推送**（我现取 `09:49:23`）：`ACCEPTANCE-BASELINE.md = 901619543b3d913b` ✓；`HEAD = 71603bd` ＝ `git ls-remote` 远端 ✓ ⇒ **未推送、未重冻**。

## §7 边界 / `NOINFO`

- 本件**重活只在 `heavy-slot` 内**（两趟，槽内 30 s／17 s）；进程只按 PID 收（跑器自带的 Xvfb/xfwm4 由它自己收，我另核 `/tmp/.X11-unix` 无残留 `:238`／`:236`）。
- 门 1b 的**判词**我用**替身 `sync-applocal.sh`**（我车道内，只输出 `drift=0`）单独测；**真实门序**下先撞门 1（同为拒跑 rc=2）⇒ 两条都如实给。
- 我**未**重跑 `verify-all`（零需求，且其 `PTS-PAGES` 步只读在册 `evidence/`）；`t52` 报告在我复核期间被别人追加（`t55` §8，`d79a0c009515b3c4`／190 行／`mtime 09:47:26`）⇒ 我每条读数都带读时刻。

## §8 落仓与自指

车道件 `~/w30x/t53-review.md` 与仓内件 `build/MilBridge/VPts-t52-review.md`（逐字节相同、`temp+rename`、`%h=1`）。
自指口径：`head -n -1 <本件> | sha256sum | cut -c1-16`。
