# P1-W32 · W8 进度盘点（**只读**）—— 三本账 / 本会话净进展 / 下三跳候选 / 里程碑面

> **本件是盘点件**：**不做实现、不构建、不跑腿、不占显示位、不跑整趟门禁**。全部读数**我现取**，命令与输出原样贴出。
> `build/MilBridge/P1-ls-family-recon.md`（我自己的 `t75` 旧件）**只作候选底本引用**，其状态**全部现取重判**（并在 §1.5 点名一处**口径差异**）；**未引任何既有报告当证据**。
> **边界（硬）**：只读仓树；唯一写入 ＝ 本件；**未** `dotnet build`、**未**跑腿、**未**占显示位、**未**跑整趟门禁、**未** `git add/commit/push`；未改任何其它件。
> **读数时刻**：`ts=2026-09-29T02:27:29.315+0800`（起点）→ **`2026-09-29T02:31:00.231654385+0800`**（`pts-gap-count-check.sh` 末取）。**③ 以落盘这一刻的现取为准**。

---

## §0 快照

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | **`03d12ac`**（`docs(#81): t104 文档面更正（F-3 恢复历史行 + F-4 判据 C2 前提 dated 更正）+ 队长裁定九/十`） | `git log --oneline -1` |
| 工作树 | 有 `M`（`README.md`／`build/MilBridge/HANDOFF-NEXT.md`／`build/MilBridge/tests/PtsPagesProbe/evidence/{app_g1.log,leg_23.env,leg_24.env,device.txt,device/xfwm.log,five_pre_g1.txt,five_post_g1.txt,arm_A/*}`）⇒ **另一条车道正在写**（`t103` 在册证据入账面）；**我一个未动** | `git status --porcelain` |
| 权威 `.so` | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`a2de5ff2b667f33f`** | `sha256sum` |
| **导出面** | `nm -D --defined-only … \| grep -c .` ＝ **567** ＝ `wc -l src/WpfGfx.Linux.Native/bin/exports.txt` ＝ **567**（`exports.txt` ＝ `1a6a415f28c6308d`） | `nm`／`wc -l` |
| PTS 桩件 | `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`80b5786aef1cc823`** | `sha256sum` |
| 在册缺口声明件 | `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` ＝ **`e30fdadde58774e1`**；其 `PTSGAP-DECL:` 行现取 ＝ `tool=96 dead=11 artifact=1 ops=84 impl=89 so16=a2de5ff2b667f33f exports=567 w66pre16=bf6b683d94549087` | `grep` |
| 缺口面（工具） | `check-shim-coverage.py --tier mapped` ⇒ `扫描到 423 条`；**`[PresentationNative_cor3.dll] 96 条`**；分解 **`Lo=15 Fs=66 Nl=6 Wrapper=5 other=4 total=96`** | 现跑 |
| 缺口三格（工具跑） | `PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=89 so16=a2de5ff2b667f33f exports=567` | 现跑 |
| **前沿（工具自报）** | `PTSGAP_FRONTIER before=LoCreateContext@3 after=LoDisposePenaltyModule@3 carrier_sha16=bf59ef38f5b8be55 carrier_mtime=2026-09-29 02:20:33.053874571 +0800`｜`PTSGAP_FRONTIER_STATE=NAMED frontier=LoDisposePenaltyModule（具名前沿成立）` | 同上 |
| **运行期 `entry=` 面（应用侧）** | 载体 `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` ＝ **`bf59ef38f5b8be55`**／mtime `2026-09-29 02:20:33`：**`1 entry=CreateDocContext` ＋ `3 entry=LoDisposePenaltyModule`**（`unknown` ＝ **0**） | `grep -o` |
| **台账行** | `:511 PTS_GAP entry=CreateDocContext seq=5 err=-10000 calls=1`｜`:512 PTS_GAP entry=LoDisposePenaltyModule seq=6 err=-10000 calls=1` | `grep -n` |
| 两页症状 | `leg_23.env`（`alive=yes app_rc=143 magenta=49923 colors=844 ns=…RichTextBoxDemo ae=141323 ink=428491`）／`leg_24.env`（`magenta=54513 colors=852 ns=…FlowDocumentDemo ae=221857 ink=423833`）；两腿 `NAMED managed_unavail=1 err=-10000 native_gap=2 native_err=-10000`；两腿 `DEV x_up=yes five_stable=yes shim=a2de5ff2b667f33f pf=6893d1d3fb1ee110` | `cat` |
| 守卫 | `pts-pages-guard.sh --legs <证据目录>` ⇒ `rc=0`；`PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded`｜`PTS_G10_NAME=PASS observed=LoDisposePenaltyModule names=2 roster=13 domains=pts-declared` | 现跑 |

✅ **同趟性现取 ＝ `yes`**：`so16=a2de5ff2b667f33f` ＝ `DEV … shim=a2de5ff2b667f33f` ＝ 现盘 `.so`；`carrier_sha16=bf59ef38f5b8be55` ＝ `app_g1.log` 实值。

---

## §1 ① 链上已补 / 剩余 —— **三本账**

### 1.1 判定口径（**写死**，含命令、射程与反例）

**候选底本**（`t75` 的 LS 族 ＋ `Pts.cs`）——我按**声明总数**重建，而不是照抄旧件的子集数：
```
$ grep -oE 'EntryPoint *= *"[A-Za-z0-9_]+"' <LineServices.cs> | sed 's/.*"\(.*\)"/\1/' | sort -u | wc -l   ⇒ 27
$ （Pts.cs 的 DllImport **不带 EntryPoint**，入口名 ＝ 方法名）⇒ 用「[DllImport( 之后的第一个 internal static extern <ret> <Name>(」抽取
  ⇒ Pts.cs 声明名 70 个（现取；脚本口径见下）
$ cat <两者> | sort -u | wc -l                                                                          ⇒ 97
```
**抽名命令（`Pts.cs` 面，可重跑）**：
```
python3 - <<'PY'
import re
p='upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs'
L=open(p,encoding='utf-8').read().split('\n'); out=[]
for i,l in enumerate(L):
    if re.match(r'^\s*\[DllImport\(', l):
        for j in range(i+1, min(i+6, len(L))):
            m=re.search(r'internal\s+static\s+extern\s+(?:unsafe\s+)?[\w\.\*\[\]<>]+\s+(\w+)\s*\(', L[j])
            if m: out.append(m.group(1)); break
print('\n'.join(sorted(set(out))))
PY
```
**三分类口径（写死）**：
1. **仍未导出** ⇔ `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}'` **不含**该名。
2. **诚实 stub** ⇔ 已导出 ∧ `src/WpfGfx.Linux.Native/src/win32_pts.c` 里命中 **`wpf_pts_gap("<名>")`** 字面。
3. **真实现** ⇔ 已导出 ∧ **无**该字面。
```
$ nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | sort > /tmp/nm.txt      # 567 行
$ grep -oE 'wpf_pts_gap\("[A-Za-z0-9_]+"\)' src/WpfGfx.Linux.Native/src/win32_pts.c | sed 's/.*"\(.*\)".*/\1/' | sort -u   # 5 行
CreateDocContext  DestroyDocContext  GetFloaterHandlerInfo  GetTableObjHandlerInfo  LoDisposePenaltyModule
```
**射程与反例（如实写）**：
- **口径 2 是"字面"口径**：若有人把 stub 写成 `wpf_pts_gap(entry)`（**变量**）或经统一派发表调用，字面命中会**漏判**。**现取反例**：`wpf_pts_gap()` 内部对传入名做 `wpf_pts_index(entry)`（`win32_pts.c` 的 `wpf_pts_index`），**调用方目前一律传字面**（我现取 5 处字面、0 处变量调用）⇒ 今天不漏；但**口径本身**要求"调用方传字面"，这是一个**隐含前提**。
- **口径 1 是"符号"口径**：`nm` 只证"该名在导出表里"，**不证**其实现正确（`nm` 命中的 stub 就是"已导出但诚实拒绝"）。
- **口径 3 是"排除法"**：真实现 ＝ 已导出 ∧ 非字面 stub。**反例**：某入口若"已导出、无 `wpf_pts_gap` 字面、但实现了空转（`return 0;`）"⇒ 会被误判成**真实现** ⇒ 本口径**不判诚实性**，诚实性由各自检/反腿负责（本件只做**状态**分类）。

### 1.2 **三本账**（现取，`ts` 见 §0）

| 域 | 条数 | **真实现** | **诚实 stub** | **仍未导出** |
|---|---|---|---|---|
| **`LineServices.cs`（LS 族）** | **27** | **7** | **1** | **19** |
| **`Pts.cs`（PTS 族，创建链＋回调族）** | **70** | **2** | **4** | **64** |
| **合计（候选底本并集，去重后 97）** | **97** | **9** | **5** | **83** |

### 1.3 LS 族逐条（27 条，现取）

| 状态 | 入口名（`LineServices.cs` 声明件） |
|---|---|
| **真实现（7）** | `LoAcquirePenaltyModule`｜`LoCreateContext`｜`LoDestroyContext`｜`LoGetEscString`｜`LoGetPenaltyModuleInternalHandle`｜`LoSetBreaking`｜`LoSetDoc` |
| **诚实 stub（1）** | `LoDisposePenaltyModule` |
| **仍未导出（19）** | `CreateTextAnalysisSink`｜`CreateTextAnalysisSource`｜`GetNumberSubstitutionList`｜`GetScriptAnalysisList`｜`LoAcquireBreakRecord`｜`LoCloneBreakRecord`｜`LoCreateBreaks`｜`LoCreateLine`｜`LoCreateParaBreakingSession`｜`LoDisplayLine`｜`LoDisposeBreakRecord`｜`LoDisposeLine`｜`LoDisposeParaBreakingSession`｜`LoEnumLine`｜`LoQueryLineCpPpoint`｜`LoQueryLinePointPcp`｜`LoRelievePenaltyResource`｜`LoSetTabs`｜`LocbkGetObjectHandlerInfo` |

### 1.4 PTS 族（`Pts.cs` 70 条）——**只给四类计数与"创建链"那几条**

- **真实现（2）**：`CreateInstalledObjectsInfo`／`DestroyInstalledObjectsInfo`。
- **诚实 stub（4）**：`CreateDocContext`｜`DestroyDocContext`｜`GetFloaterHandlerInfo`｜`GetTableObjHandlerInfo`。
- **仍未导出（64）**：其余 `Fs*` 族（现取缺口面分解里 `Fs=66`；66 与 64 的差 ＝ 上面那 2 条真实现 ⇒ **两口径自洽**）。
- **⚠️ 射程**：`Pts.cs` 的 70 条我**只做状态分类**，未逐条给上游声明行（70 行表格对"进度面"无用且易错）；需要逐条时按 §1.1 的抽名命令复算。

### 1.5 🔴 与 `t75` 旧件的**口径差异**（点名，不是矛盾）

- `t75` 说「**LS 族缺口面 ＝ 22 条**」——那是**当时的 ENFE（会抛 `EntryPointNotFoundException`）子集**，**不是声明总数**。
- 本件按**声明总数**取：`LineServices.cs` 共 **27** 条；其中此刻 **7 真实现 / 1 stub / 19 未导出**。⇒ `22` 与 `19+1=20`（现在的 LN 面）**不是同一个量**。**两种口径都对，但不可互相换算**：22 是"当时会 ENFE 的"，27 是"文件里声明的"。**引用时必须写明取哪一种**（本件此后一律用**声明总数**口径）。

---

## §2 ② 本会话的净进展（**提交级成对读数**）

**基线取法（写死）**：**`800d0e1^`** ＝ `t81`（W8 第一步）那一笔的**父提交** ⇒ 即"W8 开始前"。
```
$ git show 800d0e1^:<路径>   # 与现盘同路径对拍
```
| # | 面 | 命令 | **基线（`800d0e1^`）** | **现在** | 净变化 |
|---|---|---|---|---|---|
| N1 | `k_pts_entries[]` 名册条数 | `git show 800d0e1^:src/WpfGfx.Linux.Native/src/win32_pts.c \| awk '/k_pts_entries\[\] = \{/,/\};/' \| grep -cE '^[[:space:]]*"'` ↔ 同法取现盘 | **10** | **13** | **+3** |
| N2 | 名册内 **真实现** 条数（＝名册 ∩ 有函数定义 ∧ 非 stub 字面） | 见 §2.1 的两行脚本 | **4** | **8** | **+4** |
| N3 | **stub 字面数**（`wpf_pts_gap("…")` 去重） | `… \| grep -oE 'wpf_pts_gap\("[A-Za-z0-9_]+"\)' \| sed … \| sort -u \| wc -l` | **6** | **5** | **−1** |
| N4 | **导出数**（`exports=`） | ⚠️ **`bin/exports.txt` 与 `.so` 都不入 git**（`git ls-files --error-unmatch …` ⇒ 非跟踪）⇒ 基线**只能取"在册声明行"**：`git show 800d0e1^:src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt \| grep 'PTSGAP-DECL:'` | 声明行 `exports=`**557** | 现取 `nm`＝`exports.txt`＝**567**；声明行 `exports=`**567** | **+10** |
| N5 | **工具口径缺口 `tool`** | 同 N4 的声明行 ↔ 现跑 `pts-gap-count-check.sh` | **99** | **96** | **−3** |
| N6 | **`ops`** | 同上 | **87** | **84** | **−3** |
| N7 | **`impl`** | 同上 | **93** | **89** | **−4** |
| N8 | `dead` / `artifact` | 同上 | **11** / **1** | **11** / **1** | **0 / 0** |
| N9 | `so16` | 同上 | **`2a5165700a8c8579`** | **`a2de5ff2b667f33f`** | 换代（产品件位移） |

**两条口径边界（如实写，防过读）**
- **N4 的基线是"声明值"、不是"当时的 `nm` 现取"** —— 因为导出清单不入 git，**历史 nm 不可复算**。现取值**双证**：`nm` 与 `exports.txt` 同为 **567**，且与声明行一致。
- **N5–N7 的现取值双证**：现跑工具的输出 ＝ 声明行（同值）。

### 2.1 N2 的复算脚本（原样）
```
python3 - <<'PY'
import subprocess,re
def read(src):
    if src=='now': return open('src/WpfGfx.Linux.Native/src/win32_pts.c',encoding='utf-8').read()
    return subprocess.run(['git','show','800d0e1^:src/WpfGfx.Linux.Native/src/win32_pts.c'],capture_output=True,text=True).stdout
def roster(t): m=re.search(r'k_pts_entries\[\] = \{(.*?)\};', t, re.S); return re.findall(r'"([A-Za-z0-9_]+)"', m.group(1))
def stubs(t): return set(re.findall(r'wpf_pts_gap\("([A-Za-z0-9_]+)"\)', t))
def defined(t): return set(re.findall(r'^\s*int\s+([A-Za-z0-9_]+)\s*\(', t, re.M))
for label,t in (('BASELINE 800d0e1^', read('base')), ('NOW 03d12ac', read('now'))):
    r=roster(t); s=stubs(t); d=defined(t)
    real=[n for n in r if n not in s and n in d]
    print(f"{label}: roster={len(r)} stublits={len(s)} 名册内真实现={len(real)}")
PY
# 现取输出：
BASELINE 800d0e1^: roster=10 stublits=6 名册内真实现=4
NOW 03d12ac:      roster=13 stublits=5 名册内真实现=8
```
**净进展口径句（写死）**：本会话在**功能链**上的净推进 ＝ **名册内真实现 4 → 8（+4）**、**名册 10 → 13（+3）**、**stub 字面 6 → 5（−1：−2 转真实现 ＋1 新增诚实 stub）**；**导出面 557 → 567（+10，含只读口与自检面）**；**缺口三格 `tool/ops/impl` 99/87/93 → 96/84/89**（⚠️ `impl` 降 4 而 `ops` 降 3 ⇒ 差 1 是 **`STUB` 计数 6→5** 的事实，**不是**"进度倒退"）。

---

## §3 ③ 下三跳候选（**按链上调用序**；取值时刻 ＝ §0 的 `ts`）

### 3.1 链序的**权威现取**：native 里写死的"真实调用序"注释
`src/WpfGfx.Linux.Native/src/win32_pts.c`（现取，**逐字**）：
```
// 【**表序 ≠ 调用序**】`CreatePTSContext`（`PtsCache.cs:433-462`）的实际调用顺序是
//   `0 → 6 → 7 → 8 → 2`；而销毁项（`1`,`3`）与浮动/表格项（`4`,`5`）**不在**创建链上
//   （`4`/`5` 只在 native→managed 回调里被调：`PtsHost.cs:1094/1098` → `PtsCache.cs:259/278`）。
```
名册索引（现取，13 名）：`0`CreateInstalledObjectsInfo｜`1`DestroyInstalledObjectsInfo｜`2`CreateDocContext｜`3`DestroyDocContext｜`4`GetFloaterHandlerInfo｜`5`GetTableObjHandlerInfo｜`6`LoCreateContext｜`7`LoAcquirePenaltyModule｜`8`LoGetPenaltyModuleInternalHandle｜`9`LoDestroyContext｜`10`LoSetDoc｜`11`LoSetBreaking｜`12`LoDisposePenaltyModule。
⇒ **创建链现取 ＝ `0 → 6 → 7 → 8 → 2`**，其中 `6`/`7`/`8` 已成真实现 ⇒ **链现在停在 `2`（`CreateDocContext`）**（§0 运行期：`1 entry=CreateDocContext`、台账 `seq=5`、`err=-10000`）。

### 3.2 **下三跳候选**（每跳给：入口名／上游声明位／本地现状／一被补会首次打开哪条托管侧路径）

| 序 | 入口名 | 上游声明位（现取） | 本地现状（现取） | 一被补会**首次打开**哪条托管侧路径 |
|---|---|---|---|---|
| **①** | **`CreateDocContext`** | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:3091`（`internal static extern int CreateDocContext(`） | **诚实 stub**（名册 `idx 2`；stub 字面命中；本趟被走到 **1** 次） | `build/PresentationFramework.Linux/PtsCache.Linux.cs:548` 的 `PTS.Validate(PTS.CreateDocContext(...))` **不再抛** ⇒ `CreatePTSContext` **首次返回真 context** ⇒ 下游 PTS 站开始被走到。**"下一站具体是谁"＝ `NOINFO`**（见 §5-N1，需运行期证据） |
| **②** | **`DestroyDocContext`**（**收尾同伴**，按 W8-1／W8-2 的成对纪律） | `Pts.cs:3097`（`internal static extern int DestroyDocContext(`） | **诚实 stub**（名册 `idx 3`） | 两个调用点现取：`PtsCache.Linux.cs:416`＝`PTS.IgnoreError(PTS.DestroyDocContext(...))`（**不抛**）／**`:488`＝`PTS.Validate(PTS.DestroyDocContext(...))`（会抛）** ⇒ 若 ① 成功而它仍是 stub，**`:488` 那条路会抛**（`IgnoreError` 那条不会） |
| **③** | **`LoDisposePenaltyModule`** | `upstream/…/PresentationCore/MS/internal/TextFormatting/LineServices.cs:1575` | **诚实 stub**（名册 `idx 12`；**本趟被调 3 次**，在**功能路径**上） | 托管侧 `TextPenaltyModule.cs:59` **丢弃返回值** ⇒ **今天不阻塞**；**升级为真实现**时**必须同时覆盖终结器路径与显式 `Dispose` 路径**（`PtsCache.Linux.cs:421`／`:493`） |

**备选（链序上更靠后／未到，如实列出但不进前三）**：`GetFloaterHandlerInfo`（`Pts.cs:3065`）／`GetTableObjHandlerInfo`（`Pts.cs:3071`）—— 名册内诚实 stub，**但注释现取逐字说明它们"不在创建链上"**（只在 native→managed 回调里被调），且**本趟 `entry=` 面命中 0 次** ⇒ 不是此刻的下一跳。

### 3.3 ⚠️ 两条**必须写明的边界**（防后人误读）

1. **工具自报的 `frontier=` 与本件给的"链上下一跳"取值面不同**：§0 的 `PTSGAP_FRONTIER after=LoDisposePenaltyModule@3` 是 **`pts-gap-count-check.sh` 在其探针进程内**、按 native 的 `k_pts_call_order[]` 与 `g_pts_seen[]` 算出来的（`wpf_pts_frontier()` 现取：取"调用序上第一个 `g_pts_seen>0` 的入口"）；而 **W8 一贯的定靶面是应用侧运行期**（`app_g1.log` 的 `entry=` ＋ `PTS_GAP` 行）。**两者本趟不一致**（工具说 `LoDisposePenaltyModule`，运行期说链停在 `CreateDocContext`）⇒ **本件以运行期面排序**，并把"为什么工具的前沿是 `LoDisposePenaltyModule`"记为 **`NOINFO`**（§5-N2）。
2. **`k_pts_call_order[]` 是"声明序"、不是"实测序"**：它现取 ＝ `{0,6,7,8,9,10,2,1,3,4,5,11,12}`，与上面那条**注释**写的真实创建链 `0→6→7→8→2` **并不完全同形**（数组中 `9`/`10` 排在 `2` 之前）⇒ **引用调用序时以 §3.1 的注释为准**；数组只作 native 内部判词用。

---

## §4 ④ 里程碑面（**只给结构**，不给日历时间／趟数）

| 面 | 现取"已推进到哪一格" | 距可判还缺什么证据 |
|---|---|---|
| **PTS 创建链**（名册 `0→6→7→8→2`） | `0`/`6`/`7`/`8` ＝ **真实现**；**`2 CreateDocContext` 本趟首次被走到**（`entry=` 1 次、台账 `seq=5`、`err=-10000`）⇒ 链停在 `2` | `2` 的真实现 ＋ 它成功之后**第一站是谁**的运行期 `entry=`/台账行（§5-N1） |
| **销毁／收尾族**（`1`/`3`/`12`） | `1 DestroyInstalledObjectsInfo` ＝ 真实现；`3 DestroyDocContext` ＝ **stub**（本趟 `entry=` 0 次）；`12 LoDisposePenaltyModule` ＝ **stub**，**但本趟被调 3 次**（功能路径） | `:488` 那条 `PTS.Validate` 路径**首次被执行**时的读数；以及"终结器 vs 显式 Dispose"两路的机器证据（§5-N3） |
| **罚分模块族**（`7`/`8`/`12`） | `7 LoAcquirePenaltyModule` ＝ 真实现；`8 LoGetPenaltyModuleInternalHandle` ＝ 真实现（本会话）；`12 LoDisposePenaltyModule` ＝ stub | `12` 升级前后的**释放幂等**与两路径覆盖证据；以及"真资源"是否存在（今天 stub 注释逐字："本层没有需要释放的真资源"） |
| **LS 排版族**（`LineServices.cs` 其余 **19** 条未导出） | **本会话 0 推进**（19 条 `notexported` 一条未动；含 `LoCreateLine`／`LoCreateBreaks`／`LoEnumLine`／`LoDisplayLine`／`LoSetTabs`／`LoQueryLine*`…） | 每一条的"是否在链上会被走到"的运行期证据；今天只能给**静态调用点**（`t75` 旧件的表，须现取重判） |
| **分析器／本地化族**（缺口面 `Nl=6` ＋ `other=4`＝文本分析 4） | **本会话 0 推进** | 同上：需运行期证据证明"链上会走到" |
| **窗口-委托族**（缺口面 `Wrapper=5`） | **本会话 0 推进** | 同上 |
| **两页症状面**（里程碑的判词面） | 两腿 `alive=yes app_rc=143`、`magenta=49923/54513`、`native_gap=2`、`PTS_GUARD=PASS` ⇒ **仍是页级可见降级（洋红占位）** | 「真排版」判据本身**尚未立**（今天的绿只证"止损还在"）⇒ 需要一条**明确**的"真排版"机读判据（洋红＝0 ∧ 无 `[PTS-UNAVAILABLE]` ∧ 真实排版面） |
| **台账面**（进度载体） | 台账首次真非零（W8-1）→ 现取 `native_gap=2`、前沿具名 `NAMED` | 「台账非零 ≠ 真前进」已在判据里写死（W8-2 的 P5）⇒ 每跳都必须给**行为面**成对读数 |

**⚠️ 不许给的东西（边界）**：本件**不给**任何"还差几跳/几天/几趟"的预测。上面每一格都是**可判子面 + 缺什么证据**，不是工期。

---

## §5 `NOINFO`（具名；逐条给"消掉需要什么证据"）

1. **N1：`CreateDocContext` 成功之后"链上下一个被撞入口"的具体名字**：`NOINFO(reason=只能由运行期逐步取证；本件不跑腿、不预判名字)`. **消掉需要**：`2` 真实现后跑一趟冷启腿，读 `app_g1.log` 的 `entry=` 面与新台账行。
2. **N2：为什么工具的 `frontier=` 报 `LoDisposePenaltyModule`（而不是链序更靠前的站）**：`NOINFO(reason=这是探针进程内的 `g_pts_seen[]` ＋ `k_pts_call_order[]` 的函数，与"应用侧运行期链"是两个面；本件不跑探针，无法把探针那一段的调用序复现出来)`. **消掉需要**：把探针那一段的调用序（它先调谁后调谁）机器记录下来，或给出"探针序 vs 应用序"的对拍表。
3. **N3：`LoDisposePenaltyModule` 今天到底由哪条路径调**（终结器 vs 显式 `Dispose`）：`NOINFO(reason=应用侧只记"被调了几次/名字"，不记路径；本件不跑腿)`。**消掉需要**：`GC.SuppressFinalize` 是否执行的机器证据（计数器/具名行），或两条路径各自带名的观测。
4. **N4：`Pts.cs` 那 64 条未导出 `Fs*` 里"哪些真会在链上被走到"**：`NOINFO(reason=需要运行期证据；静态调用点不足判"会走到")}. **消掉需要**：逐跳落地后的 `entry=`/台账行。
5. **N5：`exports` 的**历史**现取值（基线 nm）**：`NOINFO(reason=`.so` 与 `exports.txt` 都不入 git（现取 `git ls-files --error-unmatch` ⇒ 非跟踪）⇒ 基线只能取在册声明行的 `exports=`，不是当时的 `nm` 现取)`。**消掉需要**：把导出清单纳入入库面（或每波留档 `exports.txt`）。
6. **N6：`t75` 旧件的 22 条与今天 27 条之间的**逐条**差集**：`NOINFO(reason=旧件是当时 ENFE 子集、本件是声明总数；两者域不同，不可直接相减)`。**消掉需要**：以本件 §1.3 的 27 条为唯一底本重算（已给命令）。

---

## §6 边界遵守自证

- **只读**：本件全部命令为 `grep`／`sed`／`awk`／`cat`／`python3`（纯文本抽取）／`nm`／`sha256sum`／`wc`／`git log`／`git show`／`git status` ＋ 三个**纯读**自检器（`check-shim-coverage.py`／`pts-gap-count-check.sh`／`pts-pages-guard.sh --legs`）。**零 `dotnet`、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
- **唯一写入 ＝ 本件**：档 A `git status --porcelain` 逐行原样 ——
```
# ts=2026-09-29T02:27:29.315+0800
 M README.md
 M build/MilBridge/HANDOFF-NEXT.md
 M build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log
 M build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/device.txt
 M build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/leg_23.env
 M build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/leg_24.env
 M build/MilBridge/tests/PtsPagesProbe/evidence/device.txt
 M build/MilBridge/tests/PtsPagesProbe/evidence/device/xfwm.log
 M build/MilBridge/tests/PtsPagesProbe/evidence/five_post_g1.txt
 M build/MilBridge/tests/PtsPagesProbe/evidence/five_pre_g1.txt
```
⇒ 上述 `M` **全部是另一条车道**（`t103` 的在册证据入账面）正在写的件，**我一个未动**；本件是本次**唯一新增**件。
- **未引既有报告当证据**：`t75` 的载体只作**候选底本**（其"22 条"口径差异已在 §1.5 点名，状态**全部现取重判**）；本件所有读数（`.so`／`exports.txt`／`nm`／名册 13 与索引／stub 字面 5／声明名 27 与 70／缺口面 96 与 `Lo=15 Fs=66 Nl=6 Wrapper=5 other=4`／三格 96-11-1-84-89／前沿与 `carrier_sha16`／`entry=` 面与两行台账／两腿 `LEG`·`NAMED`·`DEV`／守卫两行／`k_pts_call_order[]` 与链序注释／`Pts.cs` 四条的声明行／`PtsCache.Linux.cs:416/488/548` 三个调用点／基线 `800d0e1^` 的名册·stub·声明行）**都是本趟现取**。
- **末行自报口径当场可复算**：见末行。

---

### 结语（自包含）

- **① 三本账**（候选底本 ＝ `LineServices.cs` 27 ＋ `Pts.cs` 70，去重 **97**）：**真实现 9 ／ 诚实 stub 5 ／ 仍未导出 83**；LS 族 27 ⇒ 7/1/19，PTS 族 70 ⇒ 2/4/64。口径写死（nm ⇒ 已导出；`wpf_pts_gap("名")` 字面 ⇒ stub；两者都不 ⇒ 未导出），并给了射程与反例（字面口径依赖"调用方传字面"，今天 5/5 字面；排除法口径**不判诚实性**）。**§1.5 点名 `t75` 的 22 条是"当时的 ENFE 子集"、与今天的"声明总数 27"不是同一个量。**
- **② 本会话净进展（`800d0e1^` → 现在）**：名册 **10 → 13**；名册内真实现 **4 → 8**；stub 字面 **6 → 5**；导出面 **557 → 567**（声明行口径，现取 `nm`＝`exports.txt`＝567 双证）；缺口三格 **99/87/93 → 96/84/89**（`dead 11`／`artifact 1` 不变）；`so16 2a5165700a8c8579 → a2de5ff2b667f33f`。
- **③ 下三跳（按链上调用序）**：**① `CreateDocContext`**（`Pts.cs:3091`，诚实 stub，本趟首次被走到 ⇒ 链停在它）→ **② `DestroyDocContext`**（`Pts.cs:3097`，**收尾同伴**；`:488` 的 `PTS.Validate` 会抛）→ **③ `LoDisposePenaltyModule`**（`LineServices.cs:1575`，stub，本趟功能路径被调 3 次，升级须覆盖两条路径）。备选 `GetFloaterHandlerInfo`／`GetTableObjHandlerInfo` **不在创建链上**且本趟 0 命中。**边界两条**：工具 `frontier=` 与运行期链面**本趟不一致**（本件以运行期面排序，机制记 `NOINFO`）；`k_pts_call_order[]` 是**声明序**、与注释写的实测链 `0→6→7→8→2` 不同形。
- **④ 里程碑面**：只给**可判子面 ＋ 缺什么证据**（PTS 创建链／销毁-收尾族／罚分模块族／LS 排版族 19 条／分析器族 10／窗口-委托族 5／两页症状面／台账面），**不给工期**。
- **⑥ `NOINFO` 6 条**，各带"消掉需要什么证据"。

---

`P1-W8-PROGRESS-RECON 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ fb5b5e3f361e1bfa（口径＝末行之前的全文；末行＝本行）`
