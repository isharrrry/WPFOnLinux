# P1-W13 · W8 第一步实现报告（`t81`）—— `LoSetDoc` ＋ `LoSetBreaking` 诚实实现

> 车道：`runner`（重活/产品增量执行者）｜载体：`build/MilBridge/P1-w8-step1-report.md`（新建）
> 契约：`build/MilBridge/P1-w8-step1-criteria.md`（306 行，sha16 `40d8460366461d02`；**只当契约引用，不当证据**）—— 本件逐条按它的 **C1–C6** 与 **P1–P6** 执行。
> 本件**所有读数为本趟现取**，命令与输出原样入件。读时 `HEAD=a8b8acd`。

---

## 0. 一句话结论

**补了两条入口（`LoSetDoc`＋`LoSetBreaking`），都是"真收参数 ＋ 句柄身份校验 ＋ 按对象落盘 ＋ 计数 ＋ 可独立读取 ＋ 能证伪的自检"。台账**真非零**（`native_gap 0 → 1`）、前沿**真位移**（`PTSGAP_FRONTIER` 具名 `LoCreateContext → LoSetDoc`）、判据 `PTSGAP` 由 `FAIL` 转 **`PASS`**。**
**但两条 C 判据在本件语境下拿不到**：**C4 ＝ `NOINFO`**（应用侧此刻自报 `entry=dll:NotImplemented`，**在上游回溯不到任何声明**⇒按 C4 自己的口径就是红，不是绿）；**C5 的 `rc=0` 与 C5 的 `native_gap>0` 自相矛盾**（前者是 `degraded` 相位下"要求台账为 0"那条既在红，后者要求台账 >0）⇒ 按实报，**不动判据、不放宽阈值**。**P4/P6 在判据里没有落地的检测器/调用点** ⇒ 也如实报 `NOINFO`。

---

## 1. 补了什么（可逐行对拍）

### 1.1 件位与指纹（写前 → 写后）

| 件 | 写前 sha16 | 写后 sha16 | 说明 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `bdf6e9f8a1b61eae` | **`ddc21eb68d2d67e8`** | 481 行 → **878 行**；`git diff --numstat` ＝ **`427 30`** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `2a5165700a8c8579` | **`3bd193e54785b5db`** | 337,240 B → **346,032 B**（`build-shim.sh --symbols` 现取） |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `1ccaeb8c96eb1abf` | **`71d651b16c6d9d6e`** | 557 → **561** 行（**由 `--symbols` 从 `nm -D` 现生成**，不是我手写） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `52ab7d8a7fb401ce` | **`aa006983db912eaa`** | 见 §5（同趟对账） |

### 1.2 六项内容（`C6` 的"最小可辩护"逐条对上）

1. **`LoSetDoc`（四参，签名逐字照 `LineServices.cs:1470`）**：`(void *ploc, int isDisplay, int isReferencePresentationEqual, const void *deviceInfo)`。
   ① **句柄身份校验**：`wpf_pts_loc_find()` 只按**指针身份**在登记表里查（LIFO 紧凑表）；查不到 ⇒ 返回 `-10000` 且**一个字节都不读**（与 `LoDestroyContext` 四条拒绝面同形）。
   ② **参数真落盘**：`isDisplay`／`is_ref_equal`＋四个 `uint` **落进该 `ploc` 的对象**（新增字段 `doc_is_display`／`doc_is_ref_equal`／`dev_dxp_inch…dev_dyr_inch`／`doc_sets`）——**不是**进程级单例。
   ③ **计数**：`g_pts_doc_sets`／`g_pts_doc_rejected`（＋按对象的 `doc_sets`）。
   ④ **可独立读取**：`WpfLinuxWin32_PtsJmpProbe()`（观测镜，**有界 4 条环形**）＋ `WpfLinuxWin32_PtsGapReport()` 的行尾四格。
2. **`LoSetBreaking`（两参，签名逐字照 `LineServices.cs:1464`）**：`(void *ploc, int strategy)`；同形（`break_strategy`／`break_sets`／`g_pts_break_sets`／`g_pts_break_rejected`）。
3. **`g_pts_seen[]`（新，"被问过"的统一口径）**：见 §3.3 —— 这是本趟**必须**加的一格（原因见 §3.2 的踩坑记录）。
4. **`k_pts_entries[]` 的注释按实改写**（队长追加②③）：表**现盘 12 名**；注释原文「6 个入口的名字 ＋ 各自被调次数」已过时 ⇒ 改成"本文件登记入口的名字表 ＋ 真实现入口进表只为**给名字** ＋ `g_pts_calls` 只对缺口 stub 涨（**给出现场读数**：`calls=… 6:0 … 10:0 11:0`，而三条**真被调过**由 `g_pts_seen[]` 承担）"。
5. **报告行的两处口径/长度调整**（`first=`/`last=` → `anchor=`；`io_*`／`loc_*` 压形）：见 §3.4。
6. **不返 `-10000`**：两条真实现成功路径都 `return 0`，失败路径都 `return -10000` 且**对象不改**、**出参不写**。

---

## 2. C1–C6 逐条成对读数

### C1 构建与生效面 ✅
```
$ bash src/WpfGfx.Linux.Native/build-shim.sh --symbols   → rc=0
== 产物：bin/libwpfwin32.so（346032 字节）
== 导出符号总数：561
   Win32 API 名（含 A/W 变体）: 519 ｜ 托管侧 PresentationNative *Wrapper: 14 ｜ M7c 桥接（WpfLinuxWin32_*）: 28
$ nm -D --defined-only … | awk '{print $3}' | grep -c .   ⇒ 561
$ wc -l < bin/exports.txt                                  ⇒ 561
⇒ nm == exports（相等 ✔）∧ 两值都 > 557（before 557）✔ ∧ .so sha16 与 before 不同 ✔
```
**九位（现取 `bash build/MilBridge/tools/wave-push.sh --dry-run`，只读）**：`SHA=4e25e4b27d4d5ae1`｜`FP=d697b1e10ff48881`｜`PC=5b6cfda3e12b84fc`｜`PF=8ef62d37e7c2ce2e`｜`WB=9e860cbeecb352e1`｜**`WIN32SHIM=2a5165700a8c8579 → 3bd193e54785b5db`**｜`HBTL=…9e9fb3be`｜`WIC=f7b3026c8c019be2`｜`PROVIDER=24e4e0a731dbed40`｜`DWF=c83be96f18759edc`。
⇒ **只有 `win32shim` 一位位移**（产品改动，本增量唯一动的那位）；其余八位逐位点名：`bridge/pc/pf/windowsbase/hbtextline/wic_shim/dwf` 本趟未重新生成、`provider` 本趟未构建（只重建了 native shim）。⚠️ 哨兵自报 `WAVE=w80-freeze`／`BASELINE=#80`（**与 `#81` 的 HEAD 不一致，属既在的哨兵陈旧**；按派单由队长决定要不要重写，我**未**动哨兵）。

### C2 缺口面位移 ✅
```
$ python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier mapped   → rc=0
before: 135:  PresentationNative_cor3.dll  LoSetBreaking … LineServices.cs:1464
        136:  PresentationNative_cor3.dll  LoSetDoc      … LineServices.cs:1470
          [PresentationNative_cor3.dll] 99 条
after :  （两条明细**均已消失**）⇒ grep -cE '^  PresentationNative_cor3\.dll  (LoSetDoc|LoSetBreaking) ' ⇒ **0**
          [PresentationNative_cor3.dll] 97 条
```
⇒ **99 → 97**，减幅 **恰等于真补入口数 2** ✔（C2 的 acceptance 逐字满足）。

### C3 台账面 ✅（`PTSGAP=PASS`）
```
$ bash build/MilBridge/tools/pts-gap-count-check.sh
before: PTSGAP=FAIL tool=99 dead=11 artifact=1 ops=87 impl=93 so16=2a5165700a8c8579 exports=557
after : PTSGAP=PASS tool=97 dead=11 artifact=1 ops=85 impl=91 so16=3bd193e54785b5db exports=561 root=/home/links-dev/netTest/GitProj/WPFOnLinux
        PTSGAP_FRONTIER before=LoCreateContext@3 after=LoSetDoc@2 carrier_sha16=3729b8b5aa6b3f8d carrier_mtime=2026-09-28 23:04:36
        PTSGAP_FRONTIER_STATE=NAMED frontier=LoSetDoc（具名前沿成立）
        PTSGAP_CITED=PASS refs=1 strict=1
```
⇒ **三格成对**（`tool 99→97`／`ops 87→85`／`impl 93→91`）、`FRONTIER_STATE ≠ UNNAMED` ✔；`dead`／`artifact` **不变** ✔。
⚠️ **`impl` 下降是"前进"而不是"退化"**（口径写死：`impl` 是**缺口计数** ⇒ 真进步让它下降）——两条入口从"导出但恒 `-10000`"变成真实现 ⇒ `ops −2`、`impl −2`。

### C4 冷启腿的 `entry=` 面 ❌→`NOINFO`（**如实报，不许当绿**）
```
$ grep -o 'entry=[A-Za-z0-9_:]*' <腿目录>/app_g1.log | sort | uniq -c
      2 entry=dll:NotImplemented
      1 entry=LoAcquirePenaltyModule
$ grep -n 'EntryPoint="NotImplemented"' upstream/wpf/**  ⇒ 0 命中（现取）
```
**判定（逐条对 C4 的 acceptance）**：
- ① `unknown` 计数**不增**（before 2 → after **0**）✔；
- ② 具名集合**变了**（`unknown`／`LoSetDoc` → `dll:NotImplemented`＋`LoAcquirePenaltyModule`）✔ **但**；
- ③ 那两条具名**回溯不到任何声明**（`dll:NotImplemented` 里的 `dll:` 前缀是 `PtsCache.Linux.cs:1008` 的**兜底分支**产物、`NotImplemented` 在上游 `EntryPoint=` 里 **0 命中**）⇒ **按 C4 自己的判法就是红**。
⇒ **C4 ＝ `NOINFO(reason=现行仪器把"取不到的入口名"记成不可回溯的占位串)`**。**消掉需要**：`PtsCache.Linux.cs` 的 `Describe()`（**不在本件写域**：`build/PresentationFramework.Linux/**` 明列为禁）区分"**没取到名字**"与"取到的名字"，或让唯一具名来源回到 native 台账（本趟台账**确实有行**：`PTS_GAP entry=LoAcquirePenaltyModule seq=3 err=-10000 calls=1`，见 §3.5）。

### C5 两页症状面（`alive`／`app_rc`／`magenta`／台账列）
```
LEG k=24 alive=yes app_rc=143 magenta=54684 colors=851 ns=HandyControlDemo.UserControl.FlowDocumentDemo ae=221857 ink=423683
NAMED managed_unavail=1 err=-10000 native_gap=1 native_err=-10000
DEV x_up=yes five_stable=yes shim=3bd193e54785b5db pf=8ef62d37e7c2ce2e
LEG k=23 alive=yes app_rc=143 magenta=50094 colors=843 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae=140971 ink=428341
NAMED managed_unavail=1 err=-10000 native_gap=1 native_err=-10000
```
**不劣化 ✔**：两腿 `alive=yes`、`app_rc=143 ∉ {134,139}`、`magenta` 远高于门禁阈值（现取 `PTS_GUARD_MAGENTA_FLOOR` 默认 20000 ⇒ 2.5× 余量）、`native_gap` **0 → 1**（**台账被点亮**，正是 C5 要的那一格）✔。
**但 C5 的 `rc=0` 拿不到**，因为判据此刻给的是：
```
$ bash build/MilBridge/tools/pts-pages-guard.sh --legs <腿目录>   → rc=1
PTS_G10_NAME=FAIL frontier=dll off-roster=dll roster=12 domains=pts-declared,unattributable decl=none（域归因失败：该名既不在 PTS 在册表、也无「DllImport…EntryPoint=」声明位 ⇒ 红并点名）
PTS_GUARD=FAIL legs=2/2 fails=g10-name-off-roster(dll) cannot=- diag=- direction=in-file phase=degraded
```
⚠️ **C5 内部自相矛盾（如实报，交队长）**：`C5` 同时要求 `rc=0` ∧ `native_gap > 0`。而**同一相位**（`degraded`）下判据把 `native_gap=0` 当**真红**（`native-ledger-absent(PTS_GAP n=0)`，队长已裁定"保留为真红"）—— 也就是说：**台账为 0 判红、台账非零则 `rc` 仍可以是 1**（本趟就是：`G10` 那条新红顶上来了）。⇒ **本件不声称 C5 的 `rc=0`**；`alive`／`app_rc`／`magenta`／`native_gap>0` 四条**逐条达标**，`rc` 那一条**取决于 `G10` 那条红**（§3.5 追因）。
⚠️ **`G10` 那条红不是我改判据、也不是我改仪表**：`entry=dll:NotImplemented` 是 C4 那条**现行仪器缺陷**的同一个产物（`dll:` 前缀 → `roster_names` 匹配不上）；`t76` 的判序是"**先在册表、后声明树**"，所以一旦值带 `dll:` 前缀就必然落 `unattributable`。**未动判据**（`pts-pages-guard.sh` 本趟只读）。

### C6 自检面 ✅（**数字与两态都给**）
```
$ grep -c 'WpfLinuxWin32_.*SelfCheck' src/WpfGfx.Linux.Native/bin/exports.txt   ⇒ 4（before 3）✔
$ grep -n 'WpfLinuxWin32_.*SelfCheck' …  ⇒ 481 ClassificationSelfCheck ｜ 483 EscStringSelfCheck ｜
                                            497 PtsGapSelfCheck ｜ 498 PtsGapSelfCheckDiag
$ <探针>  POL selcheck=1 diag=0 create=0 setdoc=0 setbrk=0 setdoc_unknown=-10000
```
**两态可区分（不是恒绿）**：
- **正腿**：`WpfLinuxWin32_PtsGapSelfCheck() = 1`，`SelfCheckDiag() = 0`（全过）；**连跑两次都是 1**（自检保存/复原 ⇒ 可重复跑、不改可观测状态）。
- **反腿（§4-P2）**：把两条真实现改成"只 `return 0;`"⇒ 自检**必红**并**点名格号 `47`**（"B 的 `dev` 落盘不对"），且**未知句柄不再被拒**（`setdoc_unknown=0`，真实现是 `-10000`）。
- **自检的"两态"另有独立一腿**（`wpf_pts_neg_polarity()`，格号 `65/66/67`）：① 同一 `(entry,ploc)` 组合**只换 `ploc` 变量** ⇒ 观测镜**必须不命中且出参清零**；② `dev` 指向**栈上同形结构**（不在册）⇒ 值照样落盘但 `addr_ok` **必须 0**，换成**在册对象自己的**字段地址 ⇒ `addr_ok` **必须 1**。
⚠️ **调用路径仍是 `NOINFO`**（判据 §5-NOINFO-4 那一条今天**仍未消**）：我现取 `grep -rn 'PtsGapSelfCheck' build/ src/ --include='*.cs' --include='*.sh'` 只在 `win32_pts.c` 自身与 `exports.txt` 命中 ⇒ **仓内没有调用点**；本趟的调用点是**仓外探针**（`~/t81-runner/bin/probe-*.c`，`gcc` 直连该件并与 `win32_pts.c` 同源编译）。

---

## 3. 诚实性自证（我踩到的四个坑，全部留档）

### 3.1 「真落盘」不是"存指针" —— 读的是调用方**此刻**的内存
`ref LsDevRes` 在托管侧是**16 字节值类型**、以**指向该结构的指针**过边界。本层`逐字段按真实类型读`（`const unsigned int *`），**读到的值落进上下文对象** ⇒ 调用返回后**仍可独立读取**（这正是 `t80` §1.2 要的那条："与该 `ploc` 绑定的状态变化"）。

### 3.2 ⚠️ 踩坑 1：负极性断言**结构性恒假**（格号 `65` 连红两轮）
我最初把"镜里不该有 B 的 `LoSetBreaking` 条目"当负腿 —— **错**：镜是**有界环形**，而 `LoSetBreaking(loc_b, 1)` 那条**成功**推送**仍在环里** ⇒ 必命中 ⇒ 报红的是**断言**、不是实现。修法：改成**位置性单变量**（同一 `(entry,ploc)` 组合**只换 `ploc`**；`dev` 只换**在册/不在册**）。

### 3.3 ⚠️ 踩坑 2：真实现对 `frontier()` **结构性不可见**（格号 `23`）
`wpf_pts_frontier()` 原先按 `g_pts_calls[]`（**只对走 `wpf_pts_gap()` 的 stub 涨**）取"调用序上第一个被问过的入口" ⇒ **真实现**（连 `CreateInstalledObjectsInfo`、`LoCreateContext`）在它眼里**等于没被问过** ⇒ 前沿会报成一个**还没轮到的 stub**（实测 `LoAcquirePenaltyModule`）。
修法：新增 `g_pts_seen[]`（**stub 与真实现同权**，各自被调就 +1），前沿按它取。**`g_pts_calls[]` 语义一字不改**（缺口计数仍只由 stub 涨）。
⇒ 这一格**同时**是本趟"前沿真位移"的**机械证据**：`PTSGAP_FRONTIER before=LoCreateContext@3 after=LoSetDoc@2`（`LoCreateContext` 那次也进 `seen` 了）。

### 3.4 ⚠️ 踩坑 3：报告行**超长**会让应用侧整条读不到（且**本来就超**）
应用侧 `PtsCache.Linux.cs` 的 `NativeReport()` 用 `byte[256]`；`WpfLinuxWin32_PtsGapReport()` 对"写不下"**如实返回 -1**（不截断）。本格**之前那版就已经 329 B**（超），加完新字段 **370 B**。我做的两件**只压形、不丢字段**：`first=`/`last=` → `anchor=`（同一来源、不重复）、`io_*`／`loc_*` 压成自检真正用到的那几格。
**如实划界**：本行**仍 > 256**（现取自检期 `370 B`，自检内部上界钉 `340`），⇒ **应用侧那一路本来也取不到**；**未**去改应用侧件、**未**把"取不到"包装成"取到了"（不做"改仪表"）。应用侧 `entry=` 走**另一条**取数路（内层异常的入口名，`PtsCache.Linux.cs:988-1014`）⇒ 本行长度**不影响** `entry=` 面。**未**改应用侧任何件。

### 3.5 ⚠️ 踩坑 4：**结论反转** —— 台账真非零**只证明了"入了台账面"**
本趟**真的**把台账点亮了（`native_gap=1`、`PTS_GAP entry=LoAcquirePenaltyModule seq=3 err=-10000 calls=1`），但按判据 §1.5-1 的口径：**"台账非零"不构成"真前进"的证据**（存在"只把台账点亮、一步没真动"的可用形态）。
本趟的**真前进**由**另外两格**承担：① `PTSGAP_FRONTIER` 具名位移（`LoCreateContext → LoSetDoc`）；② **前沿语义**：修前第一个撞的是 `LoSetDoc`（**未导出** ⇒ `EntryPointNotFoundException` ⇒ 台账挂不上、应用侧只能靠异常文本取名），修后它**真实现**、成功；失败点**后移**到 `LoAcquirePenaltyModule`（**已导出但恒 `-10000`** ⇒ CDS 失败**留了具名台账行**）。⇒ **"下一跳被撞的入口" ＝ `LoAcquirePenaltyModule`**（这是**运行期读数**，不是预判）。

---

## 4. P1–P6 反极夹具（逐条给读数；**反腿全在副本上跑**）

| # | 反腿做法 | 期望必红点 | **实测读数** | 判据成立？ |
|---|---|---|---|---|
| **P1** | 在**副本**声明件上把 `tool` 减 2（口径漂移） | `FAIL reason=decl-vs-live-mismatch` 并点名 | `DRIFT tool decl=99 live=97` ＋ `DRIFT ops decl=87 live=85` ＋ `DRIFT impl decl=93 live=91` ＋ `DRIFT so16` ＋ `DRIFT exports`（**逐字段点名**） | ✅ 红且点名 |
| **P2** | 副本里把两条真实现改成"只 `return 0;`"（编译该副本成独立 `.o`／探针） | 自检**必红**（两态同结论）并点名 | `selcheck=0`，**`diag=47`**（点名"B 的 `dev` 落盘不对"）；同一探针里 **未知句柄 `setdoc_unknown=0`**（真实现为 `-10000`） | ✅ 红且点名 |
| **P3** | 副本里把 `entry=` 写死常量 | `FAIL reason=entry-name-not-backtraceable` | **未造反腿**：现场**已经是**"回溯不到声明"（`dll:NotImplemented`，上游 `EntryPoint=` **0 命中**）⇒ 见 §2-C4。**判据真值也在**：`pts-pages-guard.sh` 现取 `PTS_G10_NAME=FAIL … off-roster=dll`（**红并点名**） | ⚠️ 现场即反例；**未**额外造副本（`PtsCache.Linux.cs` 不在写域） |
| **P4** | 旧趟 `leg_*.env` 配本趟 `.so` | `FAIL reason=cross-run-pairing` | ⚠️ **判据此刻没有这条检测器**：`grep -n 'cross-run' pts-gap-count-check.sh` ⇒ 0 命中；它只把 `DEV … shim=` 当**被读的列**，**不**与 `so16=` 交叉断言。⇒ `NOINFO(缺检测器)`。**本件的自证另行给出**：`DEV … shim=3bd193e54785b5db` ∧ `LIVE so16=3bd193e54785b5db`（**同趟逐位相同**） | ❌ 检测器缺失（如实报） |
| **P5** | 计数下降而前沿不动 | `FAIL(ledger-nonzero-frontier-unchanged)` | 判据 `--selftest` 现取：`L8 计数下降而前沿未动（假进度**必须红**） ⇒ FAIL ok`｜`L9 计数下降且前沿真位移（**不得假红**） ⇒ PASS ok` ⇒ `PTSGAP_SELFTEST=PASS pass=9 fail=0 legs=9 must_red=6` | ✅ 已落地（L8/L9 两腿） |
| **P6** | 自检改成 `return 1;`（恒绿） | 必须由**既有探针**在同一趟报红 | ⚠️ **未红**：把自检首行改成 `return 1;`（副本）后，**同一仓外探针仍是 `selcheck=1 / diag=0`** —— 因为**自检自己没有牙**（它的牙是**被断言的行为**本身：`P2` 已证"行为坏 ⇒ 自检红"）。⇒ `NOINFO(reason=仓内无调用点；且 P6 需要"自检若恒绿则自检自己会红"这种自指牙，本增量未造)` | ⚠️ 如实报"该条不成立" |

**必红判法核对**：P1／P2 的**反腿都真红了、且都点名**（字段名／格号）✔；P3 现场即反例且同一族判据（`PTS_G10_NAME=FAIL`）真红了并点名 ✔；**P4／P6 不成立**（缺检测器／缺调用点）——**按 `t80` 的写死条款**："反腿未红或红而不点名 ⇒ 该条判不成立" ⇒ 我**不声称**这两条成立。

**副本纪律**：全部反腿在**仓外**副本上跑（`~/t81-runner/fixtures/`：`B-notimpl.c`／`C-selfcheckconst.c`／`pts-gap-decl.P1.txt`），逐份 `gcc` 成独立 `.o` 并与仓内件分开链接 ⇒ **仓内件零改动**（`git status --porcelain` 里没有"被反腿改过的件"，§7 自证）。

---

## 5. 同趟对账与对照面（队长追加①）

### 5.1 判据 `PTSGAP` 由 `FAIL` → **`PASS`**（同趟更新，逐处点名）
**声明行（本件写域内）**：`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt:34`
`tool=99 … ops=87 impl=93 so16=2a5165700a8c8579 exports=557` → **`tool=97 dead=11 artifact=1 ops=85 impl=91 so16=3bd193e54785b5db exports=561 w66pre16=bf6b683d94549087`**（`w66pre16` **不变** ✔ —— 冻证据一字未动）。

**六个复述位（判据自己的抽取式，逐处计数现取）**：

| 件 | 改了几个 token | 现取 sha16（写后） |
|---|---|---|
| `docs/ROUTES.md` | `工具口径 99→97`×2 ｜`可操作缺口 87→85`×3 ｜`可操作 87→85`×3 ｜`实现口径 93→91`×6 | `5e3acad5dfef9636` |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `工具口径 99→97` ｜`可操作缺口 87→85` ｜`实现口径 93→91` | `a92e6e73f2a4f4a5` |
| `README.md` | `可操作 87→85` ｜`实现口径 93→91` | `2501edd12ecff48f` |
| `build/MilBridge/HANDOFF-NEXT.md` | 同上 | `b0499ce4ca39f8db` |
| `docs/unimplemented.md` | `工具报缺 99→97` ｜`⇒ 可操作 87→85` | `8f0e7e6b7f5cef9d` |
| `src/WpfGfx.Linux.Native/src/win32_classification.c` | `可操作 87→85` ｜`实现口径 93→91` | `b7862b214eb3af8c` |

⚠️ **边界例外（主动申报，请队长裁）**：派单的边界把 `docs/ROUTES.md` 列给 `scribe`，但**同一条派单**又要求"三格与 `so16`/`exports` 的在册声明要按体例同趟更新，使该牙回 `PTSGAP=PASS`" —— 而该牙的复述位**有 6 处在 `docs/ROUTES.md`** ⇒ **不碰它就拿不到 `PASS`**。我按**队长本轮显式指令**执行，改动**只是数字 token**（`99→97`／`87→85`／`93→91`），**未删任何句子**、未动 `§13`；`ROUTES.md` 的 `t69`／`§15af` 那条 dated 行**原文一字未删**（`93` 那处只**追加**了 `（\`t81\` 后现取 91 条）`）。如判为越域，回退物在 `~/t81-runner/bak/sites/docs_ROUTES.md`（写前 sha16 `be8c17ed218c0926`）。

### 5.2 队长的三点，逐条
- **①**：见 §5.1 ⇒ `PTSGAP=PASS tool=97 dead=11 artifact=1 ops=85 impl=91 so16=3bd193e54785b5db exports=561`；`nm -D --defined-only | grep -c .` ＝ **561**（与 `exports.txt` 561 **相等**）。
- **②**：**导出 +4 而入口 +2 —— 多出来的两条逐名点名**（`nm` 逐名现取）：
  ```
  00000000000207e0 T LoSetDoc                        0000000000020950 T LoSetBreaking
  0000000000020620 T WpfLinuxWin32_PtsJmpProbe       0000000000022170 T WpfLinuxWin32_PtsGapSelfCheckDiag
  ```
  ⇒ **多出的两条 = 两条自检/观测面**：`WpfLinuxWin32_PtsJmpProbe`（`C6` 的"两态可区分"探针，**实现件必须导出它**才能被独立调）＋ `WpfLinuxWin32_PtsGapSelfCheckDiag`（自检的**格号**读数：红的时候要能**点名**是哪一格，本仓纪律"不许红而不点名"）。**多出的两条都不进 C6 的自检计数**（那格数的是 `WpfLinuxWin32_.*SelfCheck` = 3→**4**）。
  ⚠️ **如实报"条目数差异 +4 vs 派单预期 +2"**：若队长要严格 `+2`，**最小改法**是把这两条**藏出动态导出面**（单独一小件 `-fvisibility=hidden`，或按 `nm` 判定移进 `libwpfwin32.a` 静态面）—— 我**未**自作主张改（现状下它们**可被门禁/复核直接 dlsym 调**，是有用的机器面）。
- **③**：`k_pts_entries[]` 的注释已按实改写（§1.2-4）：表**现盘 12 名**；表＝**本文件登记入口的名字表**；`g_pts_calls` **只对走 `wpf_pts_gap()` 的缺口 stub 涨**；真实现入口进表的**唯一作用**是"让台账/报告能**给出名字**"；并**给出读数**回答"会不会让 `g_pts_calls` 恒 0"——**会**（`calls=… 6:0 … 10:0 11:0` 现场逐字），"真的被调过"由 `g_pts_seen[]` 承担（自检格 `23`）。

---

## 6. 不变量、指纹与九位

- **步数声明**：`grep -c '^run_step "' verify-all.sh` ＝ **62**；`grep -m1 '^VERIFYALL-STEPS-DECL:'` ＝ **`62 gen=#81`**（同值 ✔，本趟**未**改 `verify-all.sh`）。
- **覆盖面**：`bash build/MilBridge/tools/fp-manifest-step.sh --expect 234` ⇒ `names_n=234 … FP_MANIFEST_TEETH=PASS`（**本趟未加/删任何覆盖面内件**；改的是 6 件**已在覆盖面内**的件的内容 ＋ 1 件 `pts-gap-decl.txt`（也在覆盖面内）⇒ **件数不变**）。
- **`inputs_fp`（纪律 28）**：写前 `4140b706b03ac78f55239206788d0460a9529018489d164837c6a39cbfa98662` → **写后 `bf1edb1bf82c15137dab0be3d62a0d7fdc05fb326f02434cda2d230ca1b074de`**（现取 `bash ~/w153a/bin/infp.sh fp`）⇒ 见 §8 的 `HANDOFF-NEXT.md` 同趟追写。
- **同趟性（R6）**：`pts-gap-count-check.sh` 的 `so16=3bd193e54785b5db` ＝ 腿 `DEV … shim=3bd193e54785b5db`（**逐位相同** ✔）；`five_pre_g1.txt` 与 `five_post_g1.txt` 同 sha16 ＋ `FIVE_STABLE_G1=YES`。
- **哨兵**：`sentinel-spec-check.sh` ⇒ `SSC=PASS lines=13 keys=13 cmp=IDENTICAL`（**未**重写；`wave-push --dry-run` 自报 `WAVE=w80-freeze`／`BASELINE=#80` 与 `#81` 不一致 ⇒ **交队长**）。
- **已接线牙（收尾前现跑，7 条全绿）**：`SHELL_QUOTE_TRAP=PASS traps=0 files=203`｜`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 sites=100`｜**`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`**｜`STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62`｜`SSC=PASS …cmp=IDENTICAL`｜`REPORTID=PASS files=233 ids=2200 declared=224`｜`DEFREG=PASS declared=224 route_ids=224`。

---

## 7. 未做项与原因（如实）

1. **C4 的"名字可回溯"**：`NOINFO` —— 需改 `build/PresentationFramework.Linux/**`（**禁**）。
2. **C5 的 `rc=0`**：拿不到，且与 C5 的 `native_gap>0` **互相冲突**（§2-C5）⇒ 交队长。
3. **P3 的副本反腿**：现场即反例，未另造副本（同 1 的原因）。
4. **P4 的检测器**：`pts-gap-count-check.sh` **没有**"`so16` vs 腿 `DEV shim`"这条交叉断言 ⇒ `NOINFO(缺检测器)`；本件只在**自己的载体**里给出同趟自证。
5. **P6 的"自检恒绿必红"**：**不成立**（无仓内调用点；且恒绿的自检在探针上仍报 1）⇒ `NOINFO`。
6. **`LoAcquirePenaltyModule` 不动**（诚实边界，逐字照 `t80` §1.4）；**未**顺手多补任何入口。
7. **未跑整趟门禁**（纪律禁）；未改 `verify-all.sh`／`build/close-wave.sh`／`pts-pages-guard.sh`／`build/PresentationFramework.Linux/**`；**未** `git add/commit/push`。
8. **`PTS_GAP_REPORT` 长度仍 > 256**（§3.4）：未去改应用侧 `byte[256]`（禁），也未把"取不到"写成"取到了"。

---

## 8. 边界遵守自证 ＋ 纪律 28

- **写域内我改的件**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**唯一产品源**）＋ `src/WpfGfx.Linux.Native/bin/{libwpfwin32.so,exports.txt}`（构建产物，`exports.txt` 由 `--symbols` 现生成）＋ `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（声明行）＋ 本件 ＋ `HANDOFF-NEXT.md` 的 `cell=#1` 行（`>>` 追加）＋（**§5.1 申报的例外**）6 个复述位件的**数字 token**。
- **纪律 28（同趟）**：`build/MilBridge/HANDOFF-NEXT.md` EOF 纯 `>>` 追写一行 `⏪ **机器值契约更正 · cell=#1**：…`（dated、不自指），使 `handoff-machine-values-check.sh` 回 `HANDOFF_MV=PASS`（读数见 §6）；写前备份 `~/t81-runner/bak/sites/build_MilBridge_HANDOFF-NEXT.md`，写前 sha16 与行数入本件（见 §8 末尾的成对行）。
- **腿跑纪律**：显示位 **`:237`**（`:23x` ✓；⚠️ 本趟第一次误传 `:238` ⇒ 应用侧 `XOpenDisplay(":237")` 失败、`APP_RC=134`——**这正是仪器自证在工作**，我随即改回 `:237` 重跑，失败趟的日志留在 `~/t81-runner/logs/legs.log` 可核）；进程**只按 PID** 收（装置自收 `xvfb.pid`／`xfwm.pid`；全程无 `pkill`／`killall`／`pgrep -f`）；重活**全走 `heavy-slot.sh` 后台**：构建 `HEAVYSLOT=ACQUIRED … RELEASED rc=0 held=2s`（`PID=1915009`）、同步 `held=0s`、腿 `held=30s`（`PID=1991840`）；`sync-applocal.sh --check` 前置**先 `DRIFT` ⇒ 按要求先 `sync` ⇒ `drift=0`** 才跑腿。
- **无 `git add`／`commit`／`push`**；台账在 `~/t81-runner/**`（`bin/`／`logs/`／`bak/`／`fixtures/`／`legs/`），**未落 `/tmp`**。
本件编排口径（自报可复算）：**正文**（`head -n -1`，227 行）sha16 ＝ `c67016f344e10c0d`；**`inputs_fp` 现值** ＝ `bf1edb1bf82c15137dab0be3d62a0d7fdc05fb326f02434cda2d230ca1b074de`。⚠️ **全文 sha16 是自指量、不可自报**（写下它的动作就改掉全文）⇒ 只报正文值与 `inputs_fp`，全文值由读者现算。模式 `644`。
