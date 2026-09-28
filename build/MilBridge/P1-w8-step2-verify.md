# P1-W8-STEP2-VERIFY（`t98` 独立复核 · W8 第二步「`LoAcquirePenaltyModule` 真实现」· `t97` 的件）

> **本席只读仓树、只写本件。** 对拍标准 ＝ **先写好的判据件** `build/MilBridge/P1-w8-step2-criteria.md`（`a6d514a6bb39a5e9`／304 行，本席现取；其自证行 `427cc82e166f1a48` 未复算）。
> **复核对象** ＝ **入账面** `b7e38ab`（`feat(#81): t97 W8 第二步落地 …`，`2026-09-29T00:59:50+08:00`）＋ `e528f53`（`docs(#81): t99 最终对齐判定 + t97 那趟在册腿证据入账`，`01:00:05`）；`HEAD=e528f53`。`b7e38ab` 面（`numstat` 现取）：`src/WpfGfx.Linux.Native/src/win32_pts.c +202/−9`、`tools/pts-gap-decl.txt 1/1`、`src/win32_classification.c 1/1`、`P1-w8-step2-report.md +263`、`P1-ptsname-result.md +8`、`HANDOFF-NEXT.md 2/1`、`README.md 1/1`、`docs/ROUTES.md 9/9`、`docs/unimplemented.md 1/1`、`KNOWN-DEFECTS.md 1/1`。
> **本席现取（`ts=2026-09-29 01:01:00.758278074 +0800`）**：`win32_pts.c` **`f34cb7c37c3cc61d`**（mtime `00:52:14`）｜`libwpfwin32.so` **`461e5557bd7dd571`**（mtime `00:52:20`；**仓内＋部署件同值**）｜`exports.txt` `b81706ac335f5321`／**565** 行｜`P1-w8-step2-report.md` `5cc90e8aa63acaf4`｜`pts-pages-guard.sh` `944e61f39f24631c`｜`pts-gap-count-check.sh` `e490ab4ea9fea678`。**复核窗口内复核件无在飞改动**（`porcelain` 现取只剩 `?? arm_A/**`＋`?? src/tests/`，均他人在飞）。
> **仪器全部本席自造、仓外、零构建**：`python3`＋`ctypes` 直读现盘 `.so`（`LoCreateContext`／`LoAcquirePenaltyModule`／新只读口／自检／`mmap(PROT_NONE)` 反 deref 夹具）；判据侧只跑**纯读**自检器（`pts-gap-count-check.sh`／`check-shim-coverage.py`／`pts-pages-guard.sh --legs|--g10-name`），反腿一律跑**仓外副本文档**。

---

## ① 诚实性：真按 `ploc` 绑定 ＋ 出参真落盘 ＋ **构造不出「假装成功」路径**（**成立**）

**第二实现（`ctypes` 直读，仓外）现取**：

| 面 | 读数 |
|---|---|
| 两上下文 | `c1 ploc=0x64ed06601a20`、`c2 ploc=0x64ed0669a2a0`（**不同**） |
| 出参真落盘 | 先投毒 `out=0x91`／`0x92` ⇒ `LoAcquirePenaltyModule` 后 `out=0x64ed06601a60`／`0x64ed0669a2e0`（**毒值被覆写**，非 NULL、非常量） |
| **与对象绑定** | `out1 − ploc1 = 0x40`、`out2 − ploc2 = 0x40`（**同一结构内同一字段偏移**）⇒ 是"该对象字段的地址"，**不是**进程级全局单例（两值不同） |
| **独立读取面**（不经过出参） | `WpfLinuxWin32_PtsPenaltyModuleHandleAt(0) == out1`、`(1) == out2`（`True/True`；交换序 `False`）⇒ 状态**真落在对象上** |
| **镜像对拍** | `PtsJmpProbe("LoAcquirePenaltyModule", c1, …)` ⇒ `rc=1`、`addr_ok=1`；`PtsJmpProbePtr(...)` ⇒ `rc=1`、`ptr0 == out1`、`ptr1 = 0`（指针专用域未被误用） |
| 计数与调用序吻合 | `PtsPenaltyModuleAcquisitions()` 终值 **8** ＝ 我成功的 2 次 ＋ 自检 2 次×3（见 `F-2`）⇒ 逐项对得上 |
| 拒绝面（全 `-10000` 且**清空出参**） | 未知 `0xdeadbeef` ⇒ `-10000`，`out` 由 `0x91` → **NULL**；`ploc=NULL` ⇒ 同；**已销毁句柄** ⇒ 同；`out_ptr=NULL` ⇒ `-10000`（不崩） |
| **不 deref（强判据）** | `mmap(PROT_NONE)` 页地址当 `ploc` ⇒ `rc=-10000`、`out=NULL`、**进程存活** ⇒ 一个字节都没读 |

- **「假装成功」能不能构造**：**不能**。代码面（`:580-605` 现取）：任何失败路径都先 `*penaltyModuleHandle = NULL`，`return 0` 只出现在"身份校验通过 ⇒ 写 `c->penalty_module_handle` ⇒ 记镜像 ⇒ `*penaltyModuleHandle = c->penalty_module_handle`"这条链**末尾**；`out_ptr=NULL` 走的是**拒绝**（不是"成功但不写出参"）。行为面：上表每一次 `rc=0` 都同时满足 **出参非 NULL ∧ 出参与独立读取面相等 ∧ 镜像 `ptr0` 相等** ⇒ **没有"返 `None` 而状态没落盘"的路径**。
- **如实划界（不越读）**：句柄值＝**该对象某字段自身的地址**（自指地址），它**不是**一个真的 LineServices 罚分模块。判据件 §1.2 把"罚分模块内部算法"**明列为非目标**、§6-N3 把下游语义列为 `NOINFO` ⇒ 本席按**判据的口径**判"最小可辩护实现成立"，**不**据此说"两页真排版"。
- 载体 `5cc90e8aa63acaf4` 的"四件套"叙述与本席读数**逐条对得上**（但本件所有数值**均为我自取**）。

## ② 判据 `C1`–`C8` 逐条自算

- **`C1` 构建面（成立）**：`nm -D --defined-only | grep -c .` ＝ **565** ＝ `exports.txt` 行数 **565**（相等 ∧ ≥561）；`.so` `sha16` ＝ `461e5557bd7dd571` ≠ before（`657f448c2077ba1f`）。**>561 的多出者逐名点名**（vs `t92` 期 561 名基线 `pre-t92` 备份）：`LoDisposePenaltyModule`／`WpfLinuxWin32_PtsJmpProbePtr`／`WpfLinuxWin32_PtsPenaltyModuleAcquisitions`／`WpfLinuxWin32_PtsPenaltyModuleHandleAt`（**消失的符号 0 个**）。
- **`C2` 缺口面（⚠️ **不成立**，但**逐条点名归因成立**）**：现取 `[PresentationNative_cor3.dll] **96 条**`（判据 §0 事实 1 与 C2 期望形状写的是 **97→97**）；`LoAcquirePenaltyModule` 在该面命中 **0**（判据那半成立）。**归因（我自算）**：`LoDisposePenaltyModule` 现取**已导出**且上游声明在位（`LineServices.cs:1575`），而它**修前不在导出面** ⇒ 一进导出面就从缺口名单消失 ⇒ 条数 **97−1＝96**；三格同幅 `tool 97→96`、`ops 85→84`、`impl 91→90`（`dead=11`／`artifact=1` 未动）⇒ **账目自洽**。判据 §4-R2 自己写了「变了 ⇒ 需逐条点名归因」⇒ 本席判**这一偏离是"点名后的正当偏离"，但它确实是判据 §0 事实 1 / C2 的**前提失准**（判据写判据时 `LoDisposePenaltyModule` 尚未入导出面）⇒ 判据件应 dated 追加更正**（见 `F-4`）。
- **`C3` 台账/前沿（**成立**，唯一强证据）**：`rc=0`；`PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=90 so16=461e5557bd7dd571 exports=565`（`so16` ＝现盘 `.so`）；**`PTSGAP_FRONTIER before=LoCreateContext@3 after=LoGetPenaltyModuleInternalHandle@3 carrier_sha16=eed6c1558509dd94 carrier_mtime=2026-09-29 00:54:07.535719882`** ⇒ **`after ≠ LoAcquirePenaltyModule`** ✓；`PTSGAP_FRONTIER_STATE=NAMED frontier=LoGetPenaltyModuleInternalHandle`；`PTSGAP_CITED=PASS refs=1 strict=1`。
- **`C4` `entry=` 面（成立）**：现取直方图 **`1 entry=LoDisposePenaltyModule`／`3 entry=LoGetPenaltyModuleInternalHandle`**，`LoAcquirePenaltyModule` **3 → 0**；`entry=unknown` **0 → 0**（不增）；两条具名**可回溯**：`EntryPoint = "LoDisposePenaltyModule"`（`LineServices.cs:1575`）、`"LoGetPenaltyModuleInternalHandle"`（`:1580`）。
- **`C5` 两页症状（成立）**：`leg_23` `alive=yes app_rc=143 magenta=49592 colors=844 ae=141985 ink=428765`／`leg_24` `alive=yes app_rc=143 magenta=54182 colors=852 ae=221857 ink=424107`；两腿 `NAMED … native_gap=2 native_err=-10000`（**≥ before 的 1**）；`DEV … shim=461e5557bd7dd571`（＝本趟 `.so`）；守卫现取 `rc=0`＋`PTS_G10_NAME=PASS observed=LoGetPenaltyModuleInternalHandle names=2 roster=13 domains=pts-declared`＋`PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- phase=degraded`。⚠️ **`roster` 12→13**（`LoDisposePenaltyModule` 入 `k_pts_entries[]`）—— 这是"**新增一条真的缺口 stub 入册**"，不是把在册判据放宽（`G10b` 的规则原文未动：仍须 `k_pts_entries[]` 命中）。
- **`C6` 同趟性（**成立**；此前那条断代已闭）**：现盘 `.so` ＝ `pts-gap-count-check.sh` 的 `so16=` ＝ 在册 `DEV … shim=` ⇒ **三值逐位相同 `461e5557bd7dd571`**（`same=yes`）。
- **`C7` 自检面（成立；含一处口径更正）**：`exports.txt` 里 `WpfLinuxWin32_(*SelfCheck)` 族现取 **4 行**（`ClassificationSelfCheck`／`EscStringSelfCheck`／`PtsGapSelfCheck`／**`PtsGapSelfCheckDiag`**）—— 判据 §0 记的"现取 3 条"是**枚举口径**（漏算 `Diag` 兄弟）；**两种口径下 after ≥ before** ✓。两态**判词不同**：fresh ⇒ `1/0`；带历史（先建 1 个活上下文）⇒ `0/25`（我自取，见 ④）。三格我同趟给（④）。
- **`C8` stub 面（成立）**：`grep -c 'return wpf_pts_gap("LoAcquirePenaltyModule")'` ⇒ **0**（before ＝ 1 的形态见判据 §1.1）。

## ③ 假进度必红 `P1`–`P7`

| # | 我的夹具（全在**仓外副本文档**上） | 读数 | 判 |
|---|---|---|---|
| **P1** | 把声明件副本的一个数字改掉（`sed 's/tool=96/tool=97/'` ⇒ 副本），`DECL=<副本>` 跑同一条纯读自检器 | 反腿 ⇒ `DRIFT tool decl=97 live=96` ＋ `PTSGAP=FAIL tool=96 …` ＋ **`rc=1`**；正腿（真声明件）⇒ `PTSGAP=PASS …` ＋ `rc=0` | **成立**（红且点名；token 是 `DRIFT <字段>=… live=…`，**不是**判据写的 `reason=decl-vs-live-mismatch` —— 点名要件满足（字段名＋两值），token 名不一致见 `F-5`） |
| **P2** | 需**重编译**"只 `return 0;`"的副本 | 未跑（禁构建） | **`NOINFO`**（消掉需要一次构建；正腿侧我已给"出参非 NULL ∧ 与读取面/镜像相等"的成对读数） |
| **P3** | 判据要求的 `reason=entry-name-not-backtraceable` **在仪器里无载体**（`grep -rl` 命中 0） | 正腿侧：两条新具名**逐条回溯到上游 `[DllImport]` 声明**（`:1575`／`:1580`） | **`NOINFO`**（无检测器；`F-5`） |
| **P4** | 手工取三值（无仪器） | 本趟三值**相同**＝`461e5557bd7dd571`；**跨趟反例**：上一代在册 `DEV … shim=657f448c2077ba1f` 配现盘 `.so 461e5557bd7dd571` ⇒ 三值不等 ⇒ 按判据文字即红 | **成立（按判据口径的手工判定）**，仪器缺位见 `F-5` |
| **P5** | 我自造 **stuck 载体**（`entry=LoCreateContext`）＋ `PTSGAP_FR_BASELINE_IMPL=999` | 反腿 ⇒ `PTSGAP_FRONTIER before=LoCreateContext@3 after=LoCreateContext@2` ＋ **`FAKE-PROGRESS impl=90 < 基线 999 而前沿仍是 LoCreateContext ⇒ …（假进度） reason=ledger-nonzero-frontier-unchanged`** ＋ `PTSGAP=FAIL` ＋ **`rc=1`**；正腿 ⇒ `PTSGAP=PASS`／`rc=0` | **成立**（红 ＋ 点名 ＋ **判据要求的 `reason=` token 逐字在位**） |
| **P6** | 需**重编译**"自检恒 `return 1`"的副本 | 未跑（禁构建）。**本席另证该形态有牙**：现盘自检在**带历史**前置下**判词不同**（`0/25`），即它不是恒绿 | **`NOINFO`**（反腿需构建；正腿侧"两态不同"已自取） |
| **P7** | 判据要求的 `reason=symptom-column-not-derived` **在仪器里无载体**（命中 0） | 正腿侧：在册 `leg_*.env` 的 `native_err=-10000` 与同趟 `app_g1.log` 的台账行 `PTS_GAP entry=… err=-10000` **自洽**（同一趟，`carrier_sha16=eed6c1558509dd94`） | **`NOINFO`**（无检测器；`F-5`） |

## ④ 纪律第 `30` 条：三格、fresh 规矩、两种误导形态

- **我的三格（自取，`ctypes` 直读现盘 `.so`）**：① **进程新鲜度/调用序** ② **依赖计数当时值**（`loc_live`／`loc_creates`／`calls`／`acquisitions`）③ **判词 `rc`／`diag`**：

| 前置 | 依赖计数当时值 | 判词 |
|---|---|---|
| **fresh 进程**（未建任何上下文） | `loc_live=0 loc_creates=0 calls=0 acq=0` | **`selfcheck=1 diag=0`** |
| 建 **1 个活上下文**（不销毁） | `loc_live=1 loc_creates=1 calls=0` | **`selfcheck=0 diag=25`**（**带历史的红**） |
| 建 1 个上下文**后销毁** | `loc_live=0 loc_creates=1 acq=3` | `selfcheck=1 diag=0` |
| 建上下文＋**取罚分模块**＋销毁 | `loc_live=0 loc_creates=1 calls=1 acq=4` | `selfcheck=1 diag=0` |

- **fresh 规矩**：**正腿绿只出现在 fresh**（或"已发生调用序可逐条列出"的独立进程）——本席上表每行都给了调用序与计数 ✓；载体 `5cc90e8aa63acaf4` 结构上也齐三格要素（`fresh`×5／`调用序`×2／`loc_live`×2／`diag=`×10／`rc=`×17／`acquisitions`×1，我 `grep -c` 现取）。
- **两种误导形态是否写清**：载体把"带历史的红＝假红（成因＝调用序/绝对断言 `live_n==1`）"与"fresh 的绿＝只证该前置下没红、**不**证真绑定（真绑定由权威对象↔镜像逐字段对拍）"都写明了 ⇒ **成立**。
- ⚠️ **但带历史那条红背后有真缺陷**：见 `F-1`（自检在带历史路径上**每次漏一个活上下文条目**，且正是这条泄漏让它**下一趟更红**）。

## ⑤ 零回归（成对＋`unh=0`）

成对取法：`git diff HEAD^ HEAD -- evidence/leg_{23,24}.env`（**before ＝ `b7e38ab` 那一代在册腿**，after ＝ 现盘）。

| 面 | k=23 | k=24 |
|---|---|---|
| `alive` / `app_rc` | `yes→yes` / `143→143`（∉{134,139}） | 同 |
| `magenta` / `ink` | `49943→49592` / `428456→428765` | `54533→54182` / `423798→424107` |
| `colors` / `ns` / `ae` | `844→844` / 逐字同 / `141283→141985` | `852→852` / 逐字同 / `221857→221857` |
| `native_gap` / `native_err` | `1→2` / `-10000` | `1→2` / `-10000` |
| `DEV shim` / `pf` | `657f448c2077ba1f→461e5557bd7dd571`（＝现盘 `.so` ✓） / `6893d1d3fb1ee110`（＝现盘托管件 ✓） | 同 |

- **`unh=0`**：`t97` 那趟 runner 日志现取 `2 unh=0`、`CLICK k=23/24 … fatal=0 guard=1 pts_gap=2`、`AE=141985/221857`（**与本件在册 `ae=` 逐位相同** ⇒ 同一趟）、`POSTSHIM: shim=461e5557bd7dd571 pf=6893d1d3fb1ee110`。
- 判：**零回归成立**（`alive`／`app_rc`／`ns`／`ae`(k=24) 逐位稳；`magenta`±351、`ink` 微增＝重拍抖动；`native_gap 1→2` 是设计内增量）。

## ⑥ 不变量 / 指纹 / 哨兵 / `D-G189`

- **覆盖面**：`infp.sh list` 现取 **234** 条。
- **`inputs_fp`**：`ts=2026-09-29 01:00:11.892045322 +0800` ⇒ **`122b04afa7f6a1453b9f3f24d549b109666964da713a6c2cdc2dc51360c3e681`**；`HANDOFF-NEXT.md` 末条 `cell=#1`（`ts=2026-09-29T00:55:06.276907971+0800`）登记的现值 **同值** ⇒ **一致** ✓（值在 `01:00:11` 稳定；README／ROUTES／registry 等他人**已入账**，无在飞件移动指纹）。
- **两哨兵**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**；字段现取 `PF=6893d1d3fb1ee110`、**`WIN32SHIM=461e5557bd7dd571`** ⇒ **两轴都与现盘产品件逐位相符**（`.so` 换代后哨兵**已同趟更新**）⇒ **不该重写**。
- **`D-G189` 未被虚假扩大**：注册表现取 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` `0e9a090a791564e0` ＝ `git show HEAD:` 版**同值**（工作树无改动）；`D-G189` 出现 **3** 次（正条 ＋ `t82` 追加的第二面），`HEAD` 版亦 3 ⇒ **面数未增**。`b7e38ab` 在本件里只动该文件 **1 行**：把一条 **`2026-09-24`** 的"在册数"历史行里的 `97` 就地改成 `96`（见 `F-3`）。

## Findings（不改 `t97` 任何件；要改的以「夹具＋读数」给出）

- **`F-1`（medium）自检在"带历史"路径上**每次漏一个活上下文条目** ⇒ 既泄漏又喂出下一趟的假红**：现取（`ctypes`，同一进程连续三次 `PtsGapSelfCheck()`，前置＝我先建 1 个不销毁的上下文）`loc_live` **1 → 2 → 3 → 4**，而 `loc_creates=1`／`loc_destroys=0` **一动不动**，`rc=0 diag=25` 三次相同；`WPF_PTS_LOC_MAX = 8`（`win32_pts.c:295`）⇒ **再有 4 次同前置调用登记表就满**（之后 `LoCreateContext` 起开始被拒）。它违反了自检自己声明的"自检不许改变可观测状态"。修法：新格/主链的早退路径统一走**单一出口**（`goto cleanup` 或 RAII 式收尾），并把 `g_pts_loc_live_n` 的断言改成 **base 相对化**（`f4_binding` 已这么做，主链那处仍是**绝对值** `live_n == 1` ⇒ 这正是假红源头）。
- **`F-2`（medium）自检扰动新导出的计数面**：`WpfLinuxWin32_PtsPenaltyModuleAcquisitions()`（`t97` 为"计数可独立读取"新导出的判据面）**每次 `PtsGapSelfCheck()` 都被 +3**（现取 `acq` `0→3→6→9`，三次运行；源码：`f4_binding` 两次（`:898/:899`）＋ 主链一次（`:1117`）），而 `calls`／`loc_*` 都被保存/复原 ⇒ **该面不是自检不变的**。任何"成功次数＝我的调用次数"的对拍，必须先扣掉自检的 3；否则**跨自检取数即错**。修法：把 `g_pts_pen_sets` 一并纳入自检的 save/restore（与 `g_pts_calls`/`g_pts_seen`/`g_pts_jmp` 同办）。
- **`F-3`（low）一条带日期的历史读数被就地改写**：`b7e38ab` 把 `KNOWN-DEFECTS.md:2257`（`🆕 在册数更正（2026-09-24 … 主控落册）`）里的 `工具口径 **97**` 就地改成 `96`，而该行**同时引用**着一个更早的件（`libwpfwin32.so fc60c34d51fd9247`／550 导出）⇒ 改后该行**与它自己引用的件不自洽**（今天 96 属于 `461e5557bd7dd571`／565 导出）。按本项目"更正只许 **dated 追加**、原文一字不删"的惯例，应补一条 dated 更正行，而不是改历史数字。**夹具**：`git diff -U0 b7e38ab^ b7e38ab -- samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 现取（我贴的是原文）。
- **`F-4`（low）判据 §0 事实 1 / `C2` 的前提失准**：判据写"缺口面 97→97 不变"，而现取 **96**（机制：同趟补的 `LoDisposePenaltyModule` 由"未导出"变"已导出" ⇒ 离开缺口面）。`t97` 的归因正确且三格同幅（`tool 97→96`／`ops 85→84`／`impl 91→90`）⇒ 这是**点名后的正当偏离**，但**判据件本行应 dated 更正**（它现在读起来像"实现违反了判据"）。
- **`F-5`（low）`P1`–`P7` 的 token 多数无载体**：判据写的 `reason=decl-vs-live-mismatch`／`entry-name-not-backtraceable`／`cross-run-pairing`／`symptom-column-not-derived` 在 `build/MilBridge/tools/**` 里现取**命中 0**（只有 `ledger-nonzero-frontier-unchanged` 在册，`pts-gap-count-check.sh`）；`P1` 实际红是 `DRIFT <字段>=… live=…`。⇒ 按判据 §3 总则"缺 `reason=` 即判不成立"的**字面**口径，`P1/P3/P4/P7` 只能算**手工判定**（本件已给读数），`P2/P6` 需构建 ⇒ `NOINFO`。修法：要么在仪器里补这些 token，要么把总则的 token 清单改成"字段名或 token 二者之一"。
- **`F-6`（low）`PtsPenaltyModuleHandleAt(idx)` 是**位置读**、登记表会紧凑换位**：现取 `DS(c1)` 之后 `HandleAt(0)` **变成 `h2`**（`HandleAt(1)=0`）⇒ 跨"销毁"缓存 `idx` 会读到**另一个对象**的句柄。文档已写"第 idx 个**在册**对象"，但调用方须在每次销毁后重取 idx（自检里 `base=live_n` 的相对化是对的）。建议在该口注释里写明"销毁后 idx 语义会移位"。

## `NOINFO`（不折绿、不折红）

1. **`P2`／`P6` 的反腿**：需重编译副本 ⇒ **禁构建**未跑（正腿侧我已给"出参非 NULL＋读取面/镜像一致"与"两态判词不同"）。
2. **`P3`／`P7`／`P4` 的仪器**：对应 `reason` token 无载体（`F-5`）⇒ 只有手工判定。
3. **`penaltyModuleHandle` 的真实下游语义**（`DangerousGetHandle()` → `CreateDocContext` 的哪一字段）：仓内无 LS 规格/结构体定义 ⇒ 判据 §6-N3 同结论。
4. **"两页真排版"**：本增量只补一个入口；判据 §6-N7 同结论（本件**不**把任何绿读成排版成功）。
5. **整趟门禁 / 真实显示面 / 跑腿面**：本任务禁跑整趟门禁、禁占显示位、禁跑腿 ⇒ 未跑。

---

SELF-SHA16 （口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 0426cf06ea30d76d
