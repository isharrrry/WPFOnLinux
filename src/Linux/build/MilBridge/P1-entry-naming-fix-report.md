# P1-W34 · 托管 `entry=` 多缺口态定名修复 ＋ 判据 C4 改台账口径 ＋ 回溯形态补支 ＋ token 载体（`t109`／`scribe`）

写者 `scribe`（`t109` attempt 1／`04d47e92-903c-4eea-921d-4e469cf490b4`）｜仓根 `/home/links-dev/netTest/GitProj/WPFOnLinux`（分支 `feat-Linux`）｜读时 `2026-09-29T02:3x–02:4x+0800`
**一切读数现取自算**（`t105` 的复核只当线索；`P1-ptsname-result.md` §8 **裁定十二 ＋ 其补**已先读）。本件**不跑整趟门禁、不 `git add/commit/push`**；夹具全在**仓外**、**用完删**。
**写域** ＝ `build/PresentationFramework.Linux/PtsCache.Linux.cs`（托管取名口径）＋ `build/MilBridge/tools/pts-pages-guard.sh`（判据侧）＋ 本载体（新建）＋ `build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` 行。

## §0 一句话

**`F-1`（medium）修毕，两处同趟**：① **托管侧**取值口径从「在册表序**末**名」改为「在册表序**首**个有缺口计数的入口名」（＝**链上最早那一站**＝台账口径下的「下一跳」）——**成对读数**：两条缺口同在时 `entry=` 由 `LoDisposePenaltyModule` ⇒ **`CreateDocContext`**（真腿同向：`entry=` 直方图由 `1 CreateDocContext ＋ 3 LoDisposePenaltyModule` ⇒ **`3 CreateDocContext ＋ 1 LoDisposePenaltyModule`**），单缺口／零缺口三态**逐字不变**；② **判据侧**新增 `--c4-ledger <dir>`：定名**以台账为准**（`^PTS_GAP entry=` 行按 `seq=` 排序，**最早**＝下一跳、**最晚**＝最近一次缺口调用），两个直方图**分开印、绝不合并**，两口径不一致时印 `PTS_C4_NAME=LEDGER-OVERRIDE`，台账缺／空 ⇒ **`NOINFO`（rc=3，绝不当绿）**。**`F-2`** 给 `decl_hit()` 补「**方法名约定**」形态（`FsCreatePageFinite` 修前不可回溯 ⇒ 修后 `PASS domains=dllimport-entry decl=…Pts.cs:3109`；**注释假声明仍必红**）。**`F-3`** 给「不可归因」红补上 `P4` 期望的 token 载体；其余六个 token 的发射端**不在本件写域** ⇒ 具名 `NOINFO` ＋ 移交建议。

## §1 `F-1`① 托管侧取名口径（`PtsCache.Linux.cs`）

**改动（逐字口径，已写进代码注释）**：取值顺序 ＝ ① 旧形 `last=` → ② **`anchor=`（表序首个有缺口计数的入口名）** → ③ **`GapEntryNameAt(0)`**（老 shim 无 `anchor=` 时同义；仍走 `t90` 的长度纪律）→ ④ 表序末名 `GapEntryNameAt(count-1)`（**仅当**②③都取不到时**兜底**，保持旧行为）→ ⑤ `frontier=`（`g_pts_seen[]` 的**被问过**口径，**不是缺口名**）→ ⑥ `unknown`（不猜）。**放大缓冲重试（`t87`）与长度纪律（`t90`）一字未动**。
**理由（结构事实）**：`k_pts_entries[]` **本身按调用链次序排列**（installed-objects → doc-context → floater/table → `Lo*` 族 → dispose）⇒ 「表序首」＝**链上最早那一站**＝台账口径（按 `seq=` 取最早）下的「**下一跳**」。⚠️ **限制如实记**：native 报表**不暴露 recency**（现取字段只有 `anchor=`／`frontier=`／逐条 `calls=`），且 `src/**` 不在本件写域 ⇒ 托管侧**无法**按"最近一次调用"取名；而"最近一次"在本现场**恰是另一站**（`LoDisposePenaltyModule`）⇒ 若取它，`CreateDocContext` 仍永远不会被点名，`F-1` 的病没治。

**成对读数（真产物，同一 `.so` `a2de5ff2b667f33f`；夹具＝仓外 `pwsh` 反射 ＋ 直调诚实 stub 造缺口态）**：

| 缺口态（驱动序） | `GAPCOUNT` | 修前（`pf=6893d1d3fb1ee110`） | 修后（`pf=2988f5154ecacdd`） |
|---|---|---|---|
| **两条**：`CreateDocContext`(idx2) → `LoDisposePenaltyModule`(idx12) | 2 | `entry=` ＝ **`LoDisposePenaltyModule`** ✗（`F-1` 现场） | **`CreateDocContext`** ✓（`report anchor=CreateDocContext`） |
| 只有 idx12 | 1 | `LoDisposePenaltyModule` | `LoDisposePenaltyModule`（**回归**：逐字不变） |
| 只有 idx2 | 1 | `CreateDocContext` | `CreateDocContext`（**回归**：逐字不变） |
| 无缺口（fresh） | 0 | `unknown` | `unknown`（**回归**：逐字不变） |

**真腿（同一件、同一显示位 `:237`、重活槽后台；腿目录在仓外）**：`POSTSHIM shim=a2de5ff2b667f33f pf=2988f5154ecacdd（== authority ⇒ 读数可归因）`；两腿 `alive=yes app_rc=143`、`native_gap=2`；**`entry=` 直方图**：修前（在册证据 `bf59ef38f5b8be55`）＝ `1 CreateDocContext ＋ 3 LoDisposePenaltyModule` ⇒ 修后（本趟腿）＝ **`3 CreateDocContext ＋ 1 LoDisposePenaltyModule`** ✓；台账两行**逐字不变**（`PTS_GAP entry=CreateDocContext seq=5`／`… LoDisposePenaltyModule seq=6`）⇒ **改的是托管取名，不是台账**。

## §2 `F-1`② 判据侧：`--c4-ledger <dir>`（C4 定名改用台账口径）

**口径句（已写进牙）**：判「**被撞入口／下一跳是谁**」**以台账为准** —— 现取 `<dir>/app_g1.log` 里 `^PTS_GAP entry=<名>` 行，`seq=` 排序后**最早**那条 ＝ **下一跳**（链上最早那一站）、**最晚**那条 ＝ **最近一次缺口调用**；托管 `entry=` 面**只作「具名位移」的粗证**（证"名字从无到有"），**不作定名依据**；判词里**两个直方图分开印、绝不合并**（`t105` 的病灶正是"混在一张直方图"）。

**四条夹具读数（仓外；用完删）**：

```
real（在册证据副本）：rc=0
  PTS_C4_LEDGER=PASS lines=2 distinct=2 next=CreateDocContext next_seq=5 bumped=LoDisposePenaltyModule bumped_seq=6
  PTS_C4_SOURCE=ledger（定名以台账为准；托管 entry= 面只作具名位移的粗证，不作定名依据 —— 裁定十二补）
  PTS_C4_HISTO=mode=separate ledger: 1 CreateDocContext; 1 LoDisposePenaltyModule;
  PTS_C4_HISTO_MANAGED=separate managed: 1 CreateDocContext; 3 LoDisposePenaltyModule;
  PTS_C4_NAME=LEDGER-OVERRIDE managed=LoDisposePenaltyModule ledger_next=CreateDocContext（两口径不一致 ⇒ **以台账为准**）
agree（两口径同指）：PTS_C4_NAME=AGREE managed=CreateDocContext ledger_next=CreateDocContext   ⇒ rc=0
noledger（有托管行、无台账行）：PTS_C4_LEDGER=NOINFO reason=ledger-empty(0 行 ^PTS_GAP entry=)   ⇒ rc=3（不当绿）
nolog（连 app_g1.log 都没有）：PTS_C4_LEDGER=NOINFO reason=ledger-absent(<path>)                ⇒ rc=3（不当绿）
```
**本趟真腿上同支现取**：`next=CreateDocContext next_seq=5 bumped=LoDisposePenaltyModule bumped_seq=6` ＋ `PTS_C4_NAME=AGREE managed=CreateDocContext ledger_next=CreateDocContext` ⇒ 修好①之后**两口径同指**（互为佐证）；而 `real` 那条夹具（修①之前的证据）恰好演示「不一致 ⇒ 以台账为准」✓。

## §3 `F-2` 回溯形态补支（`decl_hit()`）

**新增支（逐字）**：**仅当**该 `[DllImport(…)]` 属性块内**没有** `EntryPoint=` 时 —— 要求 ①**属性起始行**（同 `t82` 口径：`^[[:space:]]*\[[[:space:]]*DllImport[[:space:]]*\(`）＋ ②其后 ≤3 个非空行内真的 `extern` ＋ ③**成员名（`(` 前那个标识符）逐字等于入口名** ⇒ 命中并印声明位。**不放松**第一支（显式 `EntryPoint=`）的任何形态要求，**树射程不动**。

**成对读数（`--g10-name <夹具目录>`；`PTS_G10_DECL_TREE` 指现盘 `upstream/wpf`；`PTS_G10_ROSTER_SRC` 为便于定位而指现盘名册或"去掉该名的名册副本"）**：

| 夹具（`entry=`） | 修前（`pre-t109` 牙） | 修后 |
|---|---|---|
| **`CreateDocContext`（复核者点的那个名；名册副本里去掉它 ⇒ 走回溯支）** | `FAIL off-roster=CreateDocContext roster=12 domains=unattributable decl=none`（rc=1） | **`PASS observed=CreateDocContext names=1 roster=12 domains=dllimport-entry decl=…/PresentationFramework/MS/Internal/PtsHost/Pts.cs:3109`**（rc=0）✓ |
| `FsCreatePageFinite`（**另一支**方法名约定声明，名册外） | `FAIL … domains=unattributable decl=none`（rc=1） | **`PASS … domains=dllimport-entry decl=…/Pts.cs:3109`**（rc=0）✓ |
| `CreateTextAnalysisSink`（**显式** `EntryPoint=`，名册外） | `PASS … domains=dllimport-entry decl=…LineServices.cs:1589`（rc=0） | **同值**（rc=0）⇒ 第一支**未退化** ✓ |
| `FakeNameZZ`（**注释里**写属性＋extern 的假树） | `FAIL off-roster=FakeNameZZ domains=unattributable`（rc=1） | **同值**（rc=1）⇒ **牙强度未降**（注释仍骗不过）✓ |

## §4 `F-3` token 载体

- **已补（本件可落的部分）**：`P4` 期望的 **`reason=entry-name-not-backtraceable`** 现取**在位** —— 不可归因红行**行尾追加**一行（旧句仍为逐字前缀，判据件一字未删）：`reason=entry-name-not-backtraceable name=<名> decl_tree=<树>（该名在声明树里回溯不上：既非显式 EntryPoint=，也非「DllImport 成员名」形态）`。现取夹具（假树 → `FakeNameZZ`）⇒ 该 token 与其字段名同时印出 ✓。
- **`NOINFO`（其余六个 token）**：`decl-vs-live-mismatch`（`P1`）的发射端是 **`build/MilBridge/tools/pts-gap-count-check.sh`**（现取红行是 `DRIFT <字段>=… live=…`）；`internal-handle-null-after-none`（`P2`）／`null-handle-accepted`（`P3`）／`selfcheck-no-teeth`（`P7`）／`pointer-truncated-in-int-field`（`P8`）的发射端是 **native 自检面（`src/**`）**——`t105` 已记其中 `P2/P3/P7/P8` **需重编译**；`cross-run-pairing`（`P5`）的判据量（`same=yes`）来自**腿/运行器侧**。⇒ 这六个**都不在本件写域**（`pts-gap-count-check.sh` 与 `src/**` 均被派单边界排除）⇒ 本席**只如实点名**，并建议队长二选一：**(甲)** 由对应件的写者补 token；**(乙)** 把判据总则改为「**红必须点名（字段名）或给 token，二者之一**」——**总则在 `P1-w8-step3-criteria.md`（判据件，不在本件写域）**，故本席**不代改**。**本件没有**把"必红并点名"押在未实现的 token 上（`P4` 已实测在位）。

## §5 回归 / 不变量 / 指纹 / 已接线牙（现取）

```
判据件回归：`bash build/MilBridge/tools/pts-pages-guard.sh --selftest` ⇒ **`PTS_GUARD_SELFTEST=PASS pass=40 fail=0`**（含 `G10c` 三条：注释假声明**必红**／注释掉的声明**必红**／真声明**绿＋点名**）
          `--legs <仓外证据副本>` ⇒ `rc=0`／`PTS_G10_NAME=PASS observed=LoDisposePenaltyModule names=2 roster=13 domains=pts-declared`／`PTS_GUARD=PASS legs=2/2 fails=-`（**与改前逐字相同**）
          本趟真腿目录 ⇒ `--legs` `rc=0`／`observed=CreateDocContext`／`PTS_GUARD=PASS legs=2/2 fails=-`（零回归）
不变量：`^run_step "` ＝ 62 ｜ 覆盖面 ＝ 234 ｜ `VERIFYALL-STEPS-DECL: 62 gen=#81` ＝ 1 ｜ `--expect 234` ＝ 1 ⇒ 四条未变
指纹：fp 现取 81f9e0b0038dbcaca821221088059cb3d202c36e282f63d8c7a18b5d4b2fe3a1（ts=2026-09-29T02:42:21.223761981+0800）
      ⇒ 本件改了覆盖面内件 `tools/pts-pages-guard.sh` ⇒ 同趟**纯追加** `cell=#1` 一行（`HANDOFF-NEXT.md` 649→650 行；登记后 `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`）；**只登记一次、不追写**（`t103`／`t94` 亦在动本格）
牙：REPORTID=PASS files=246 ids=2201 declared=224（本载体落盘前）｜SHELL_QUOTE_TRAP=PASS traps=0 ｜ PIPEFAIL_SIGPIPE=PASS undeclared_hit=0
    HANDOFF_MV=PASS cells=9 equal=8 mismatch=0 ｜ DEFREG=PASS declared=224 route_ids=224（**DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN keys=KD** 仍未闭 ⇒ 需持 `--emit` 权限者同趟刷新）
    **SENTINEL-SPEC=FAIL（rc=1）**：`SSC_VALUE=FAIL key=PF got=6893d1d3fb1ee110 want=2988f5154ecacdd`（`SSC` 12 个 key 里只此一格）——**本件 rebuild 的直接后果**（本席把 `pf` 从 `6893d1d3fb1ee110` 重建为 `2988f5154ecacdd`；`WIN32SHIM=a2de5ff2b667f33f` 与现盘相符）⇒ **哨兵需重写**（队长动作；本席**从未写哨兵**）
```
**本件 rebuild 说明**：`touch` 源件后走重活槽 `dotnet build … -c Release -m:1 -v:m`（`0 警告 0 错误`／用时 `00:00:42.69`）⇒ Release／部署件 `6893d1d3fb1ee110` ⇒ **`2988f5154ecacdd`**（`sync-applocal.sh` 至 `drift=0`）；`libwpfwin32.so` **未动**（`a2de5ff2b667f33f`）。

## §6 未做项 / `NOINFO` ＋ 边界自证 ＋ 备份面

- **未做①（其余六个 token 的载体）**：见 §4（发射端在 `pts-gap-count-check.sh`／`src/**`／腿侧 ⇒ 写域外）；**总则**（`P1-w8-step3-criteria.md`）亦不在写域。
- **未做②（native 报表的 recency 字段）**：`src/**` 越域 ⇒ 托管侧只能用「表序＝链序」这条结构事实（已如实写进代码与 §1）；若将来要在 native 侧加 `last=`／`recent=` 字段，须另派单（并须同趟跟随 `nm`／`exports.txt`／`pts-gap-decl.txt`）。
- **观察（不属本件、如实点名）**：native 报表的逐条计数仍是 `calls=0:…11:`（**12 个**），而现册已有 **13** 名（`LoDisposePenaltyModule` 是第 13 名）⇒ 第 13 名的逐条计数**未印**；托管侧本件不依赖该字段 ⇒ 不影响本件结论。
- **`NOINFO`（真腿的"两口径不一致"现场）**：修①之后我跑的腿两口径**同指**（`AGREE`）⇒ 「不一致时以台账为准」这条只在**修①之前的证据副本**（`real` 夹具）上演示过；**真实世界里"不一致"这一态的复现需回到旧托管件**（本席未为它保留旧件 ⇒ 如实记）。
- **边界自证**：`git status --porcelain` 里属于**本席**的改动只有 ` M build/PresentationFramework.Linux/PtsCache.Linux.cs`、` M build/MilBridge/tools/pts-pages-guard.sh`、` M build/MilBridge/HANDOFF-NEXT.md`（仅 `cell=#1` 一行）、`?? build/MilBridge/P1-entry-naming-fix-report.md`；`src/**`、`verify-all.sh`／`close-wave.sh`／哨兵／`docs/ROUTES.md`／`samples/**`／`tests/PtsPagesProbe/evidence/**` **零碰**；未跑整趟门禁、未 `git add/commit/push`；夹具（`/tmp/t109-g10`／`/tmp/t109-c4`／`/tmp/t109-ev`／`~/w281-scribe/t109/**`）**全在仓外、收尾删净**。
- **备份面 ≡ 改动面（第 `29` 条）**：改动面 2 件（+1 新建无前像；`HANDOFF-NEXT.md` 仅一行）≡ 备份面 `~/w281-scribe/bak/{PtsCache.Linux.cs,pts-pages-guard.sh,HANDOFF-NEXT.md}.pre-t109`（写前逐件 `stat -c %h` ＝ **1** ＋ `cp -p`；`cmp` 与写前件逐件相同）。
- **第 `30` 条**：本件引用的"缺口态读数"来自**仓外 `pwsh` 探针**（每条都写明 `GAPCOUNT`／`DRIVE`／`pf`／`shim` 四格＝进程新鲜度 ＋ 关键前置量 ＋ 判词），**不混淆 fresh 与带历史**；真腿读数带 `POSTSHIM == authority` 同趟证明。

**本件自证**：`head -n -1 build/MilBridge/P1-entry-naming-fix-report.md | sha256sum | cut -c1-16` ＝ b2fd4aa89a4f9516（本行系末行；上列各节即被哈希的全文）
