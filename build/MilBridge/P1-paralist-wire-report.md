# P1-W80 · 把 `pfsparaclient` 接进段落列表（`FsQueryTrackParaList` ← 托管 `+176`）

> **本件是 `t160`（runner）的交付**：执行判据件 `build/MilBridge/P1-paralist-wire-criteria.md`（289 行／full sha256 `dfe64c004a914a93…`／末行自证 `2e7c9d4613e7d658`）—— **先完整读了它的 §1–§10**。
> **写域**：`src/WpfGfx.Linux.Native/**`（`src/win32_pts.c`／`bin/exports.txt`／`tools/pts-gap-decl.txt`）＋本载体。**未碰** `build/MilBridge/tools/**`／`build/MilBridge/tests/**`／`docs/**`／任何 `.cs`／两枚哨兵／`HANDOFF-NEXT.md` 的 `cell=#1`（**队长收口** ⇒ 本件**有意未登记**）。**相位位 `phase=degraded` 未动**；探针闸／强度旋钮**缺省路径未变**；未跑整趟门禁；未 `git add/commit/push`。
> **纪律 28**：改了覆盖面内件 ⇒ 触发成立；`cell=#1` 有意未登记。

---

## §0 现取快照（开工／收尾）

| 项 | 开工现取 | 收尾现取 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | **`6d967d8843bd902b`**／**256008 B**／mtime `17:48:56`（＝判据件 §1 读到的同一版） | **`c90a78af8bc9499c`**（276434 B）；**t160 专属 `numstat` ＝ `289 6`**（＋289 ／ −6） |
| `bin/libwpfwin32.so`（权威） | `99093641234bcb81`（t156 后） | **`ca97eacb8bb123f1`** |
| `bin/exports.txt` | 640 行 | **651 行**（`163c231022c4d088`） |
| `tools/pts-gap-decl.txt` | `7244338a6fa04564` | **`087da7987fed5c6c`** |
| 托管权威件 | `pf16=0b4b65f2c6c7ffd4` | **同**（本件未动） |
| 资源／显示位 | `MemAvailable 4.26 GB`／`SwapFree 1.38 GB`／`df` 余 71 GB；`/tmp/.X11-unix/` 仅 `X0 X1` | 同量级；跑后仅 `X0 X1` |

**代际声明（纪律 30／31）**：本件一切读数都在 **`so16=ca97eacb8bb123f1`／`pf16=0b4b65f2c6c7ffd4`** 这一代上；**跨代只并列不相减**。

---

## §1 判据四个设计问 → 本实现的落地（逐条对应）

| 判据判词 | 本实现的落地（`win32_pts.c`） |
|---|---|
| ① **持有期 ＝ 托管对象生存期**（可跨调用持有） | 句柄由**托管 `+176`** 现造（`src=managed-176`），**填进列表后不回收**；**跨调用持有**（同一代服务 `gen_size=32` 次填充），**回收推迟到下一次调用**（`fsp_pl_prev`）⇒ **绝不"返回前回收"** |
| ② **窗口非必要非充分 ⇒ 两腿实验** | **W-1**：第一代由**窗内**探针（`FsCreatePageBottomless`）造出并保留（`site=probe-in`）；**W-2**：`WPF_PTS_FSP_PL_WIN=out` ⇒ 第一代由**窗外**腿（`FsQueryTrackParaList` OOW，`t151`/`t156` 在册）造出并保留（`site=probe-out`） |
| ③ **回收责任在托管 `Dispose()`／触发点 `+192`** | 本入口**不回收本次要交出去的代**；只在下一次调用里回收**上一代**（`[FSPARALIST-CONSUME] … via=+192-deferred-prev-gen`）⇒ **P4 反腿**（副本）证明"返回前回收"必红 |
| ④ **索引复用 ⇒ 静默错对象** | **ABA 反腿**（副本）现场造出该条件并给出**机制证明**：`rc=0` 而对象已换（见 §7） |

---

## §2 ② 七条合取逐条（主表 ＝ **W-1 两独立样本**，同闸开 `WPF_PTS_DRIVE_PROBE=1`／`_N=16`）

| # | 合取条件（判据 §2.4 逐字） | **L1**（`app_pid=4088295`，`18:03:35`） | **L2**（`app_pid=4090054`，`18:04:06`） | 判 |
|---|---|---|---|---|
| 1 | `rc=0` | `rc=0`（**1085/1085** 条 FILL 行皆为 0） | `rc=0`（**1113/1113**） | ✅ |
| 2 | `n >= 1 ∧ n == cParas` | `cParas=1 n=1` ×1085 | `cParas=1 n=1` ×1113 | ✅ |
| 3 | `src=managed-176` | 每条 FILL 行都是 `src=managed-176` | 同 | ✅ |
| 4 | 消费者行 `resolve=ok` ∧ `h0` 与**同 run** 的 `+176` 产出**同值** | `resolve=ok` ×**33**；`h0=0x5` ＝ 同 run `[DRIVE-PROBE3] … keep=0x5 keeprc=0` | `resolve=ok` ×**33**；`h0=0x5` ＝ `keep=0x5 keeprc=0` | ✅ |
| 5 | `resolve=wrong-object`／`resolve=failfast`／`rc=-100002`／`rc=-10000` **各 0 次** | **各 0**（`GAP_rc10000=0`、`GAP_rc100002=0`、`wrong_object=0`、`failfast_resolve=0`） | **各 0**（同上） | ✅ |
| 6 | **≥2 独立样本**判定一致 | — | **判词与逐格值相同** | ✅ |
| 7 | 每条读数带纪律 30 三格 ＋ 门状态 | 见下 | 同 | ✅ |

**逐字读数（L1，其余趟同形）**
```
[FSPARALIST-FILL] rc=0 reason=ok entry=FsQueryTrackParaList cParas=1 n=1 h0=0x5 src=managed-176 run=site=probe-in win=in gen=1 quad=1 hold=0 off16=16 bytes0_32=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 05 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00  ok=1 gap=0
[FSPARALIST-CONSUME] i=0 h=0x5 resolve=ok type=BaseParaClient via=+192-deferred-prev-gen rc=0 consumes=1
[FSPARALIST-FILL] … h0=0x4 src=managed-176 run=site=query-frame win=in gen=22 quad=8 hold=0 off16=16 … ok=1085 gap=0
```
**纪律 30 三格**：① **进程新鲜度**：`app_pid=4088295`（`GROUP 1 arm=A clicks=[24,23] 18:03:35`）／`4090054`（`18:04:06`），命令行＝`dotnet HandyControlDemo.dll`（`env DISPLAY=:231 …`，由装置闸自证 `X_UP=yes`）；② **所依赖计数器**：`ok=1085 gap=0`／`ok=1113 gap=0`（`WpfLinuxWin32_PtsFsParaList{Ok,Gap}`＋本件新增 `Fills/Consumes` 读数口）；门三变量 `WPF_PTS_DRIVE_PROBE=1`／`_N=16`／`_FAKE_NMS=未设`；③ **`rc`·`diag` 原文**：上面三行逐字（非转述）。

---

## §3 ③ 两腿实验（W-1 窗内／W-2 窗外）＋ 判定

| 腿 | 第一代来源（`site`） | `win` | 填充数 | `resolve=ok` | 该腿 `rc=-10000` | 判 |
|---|---|---|---|---|---|---|
| **W-1**（L1／L2） | **`probe-in`**（窗内 `FsCreatePageBottomless` 探针造出并保留） | `in` | **1085／1113** | 33／33 | **0** | **真填全绿** |
| **W-2**（L3，`WPF_PTS_FSP_PL_WIN=out`） | **`probe-out`**（**窗外**腿造出并保留） | `out` | **403** | 12 | **712**（`reason=no-out-of-window-client-yet`） | **填充面全绿**（403/403，`h0=0x4`、`src=managed-176`）；**该腿整体含 712 条诚实拒绝** ⇒ **按判据第 5 条该腿不判绿** |

**判定（照判据 §2.2 逐字）**：**两腿都跑到了**；**窗内造出的第一代**（W-1）与**窗外造出的第一代**（W-2）**都被列表交给消费者并解析成功**（`resolve=ok`），**逐字差异只有 `win=in|out` 与 `site=probe-in|probe-out`** ⇒ **结论「窗口无关」有据**（**不是**单腿读数）。
**诚实边界（照判据）**：本件只观察了**本跳的填充＋消费者解析**；**未**证明全部调用链的窗口状态（判据 §2.2 的边界照抄）。**W-2 的 712 条拒绝**来自「窗外腿的第一代还没造出来时的先到调用」⇒ 该腿的**填充面**证据成立，**整体绿**不成立（**不缩窄判据**）。

---

## §4 ④ `R-1`–`R-4` 回收判据 ＋ 两条反腿（**都是副本产物**）

| 判据 | 现取读数 | 判 |
|---|---|---|
| **R-1 单次性**（同一 `h` 的 `+192` 只许成功一次；第二次 ⇒ `ReleaseHandle:211` Assert ⇒ **不可捕获 `FailFast`**） | 主表：**每个 `h` 恰好被 `+192` 一次**（`consumes=33`，每次 `rc=0`；**无第二次**） | ✅ |
| **R-2 不晚于上下文销毁** | 本件所有 `+192` 都在该 doc **仍在册**（`ctx_live=1` 族读数）期间发出；**本应用从不走 `DestroyDocContext`**（`t156` 现取四趟全 0）⇒ 无"上下文已 dispose 后回收" | ✅（附 `NOINFO`：见 §10-4） |
| **R-3 与那一次 `+176` 绑定** | 每一代都由**本 run 的 `+176`** 现造；`h0` 与同 run 的 `keep=` **同值**（L1/L2：`0x5`）；**未**把上一轮的**已回收**值留到下一轮（ABA 反腿**专测这条**，见下） | ✅ |
| **R-4 回收正确性不可由 native 单侧证明** | 自由链在托管 `_unmanagedHandles[0].Index` 内 ⇒ 本件**不**声称"回收正确"；只给 `+192` 的**接受**读数；**具名 `PRECOND-NO-HANDLE-ACCOUNTING`** | **`NOINFO`**（**严禁**用 `rc=0` 冒充） |
| **反腿 P1（`WPF_PTS_FSP_PL_SELFRECYCLE=1`，副本 `ab14734e5fb749a0`）** | 本入口**返回前回收** ⇒ 第 2 次填充后交出去的是**死句柄** ⇒ 消费者侧：**`Unrecoverable system error.: Handle has been already released.`** ×2、`failfast=1`、**`app_rc=134`**（core dump，`procs 4092608 已中止`） | 🔴 **必红成立**（判据 §5-P4 现证） |
| **反腿 P2（`WPF_PTS_FSP_PL_ABA=1`，副本 `edff7a3cab64ff31`）** | 现场造 ABA：回收 `h` → 再 `+176` ⇒ 槽被复用 ⇒ 拿**同一数值**去解析 ⇒ **`rc=0`**（**静默**） | 🔴 见 §7（机制证明） |

**"不许自回收/返回前回收"的证明形态**：本条**不能**靠"主链没崩"成立（P8）—— 它的证明是**反腿真的红了**（`SELFRECYCLE` 腿：`failfast=1`＋`app_rc=134`＋具名 Assert 文本），且主链**恰恰**是"推迟到下一次调用"因此没有出现它。

---

## §5 ⑤ `+16` 的实测（三形态）＋ `_Static_assert`

1. **计算值（预期）**：`Pts.cs:1500-1510` 字段序 ⇒ `FSUPDATEINFO 8B` ＋ `pfspara 8B` ⇒ **`pfsparaclient @ +16`**、`nmp @ +24`、`sizeof = 64`。
2. **编译期钉死**：`win32_pts.c` 里新增镜像结构 `wpf_pts_fsparadesc` ＋ **`_Static_assert(offsetof(…,pfsparaclient)==16)`**（另有 `pfspara==8`、`nmp==24`、`sizeof==64`、`FSUPDATEINFO==8`、`FSBBOX==20` 共 6 条）。
3. **运行期实测（字节级读回）**：每条 FILL 行带 `off16=16` ＋ `bytes0_32=<hex>`；L1 首填现取：
   `… 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 **05 00 00 00 00 00 00 00** **03 00 00 00 00 00 00 00**`
   ⇒ **`+16..+23` ＝ `h0`（`0x5`）**、**`+24..+31` ＝ `nmp`（`0x3`）** 逐字节可见（其余字节 0＝本件显式 `memset` 后只写这两格＋`pfspara` 留 0）。
4. **消费者行为（真正的"托管侧按它自己的布局读"实测）**：托管 `ParaListFromTrack`（`PtsHelper.cs:604-616`）在 `rc=0` 后继续执行并做 `ErrorHandler.Assert(cParas == paraCount)`，随后 `ContainerParaClient`／`FlowDocumentPage` 族按**它自己的** `+16` 取 `pfsparaclient` 反查 —— 本件两样本里**消费者侧零新异常类**（`failfast=0 unrec=0`、`ENFE` 只有下一条缺失入口的名字，见 §8）。**若 `+16` 错位**，托管侧读到的会是 `pfspara`（0）或 `nmp`（`0x3`，`ContainerParagraph`）⇒ `as BaseParaClient` 落空 ⇒ 消费者侧异常 ⇒ **绝不会**是本样本形态。

---

## §6 ⑥ 「假进度必红 `P1–P10`」逐条

| # | 判据要求 | 本件现取 |
|---|---|---|
| `P1` 假成功 | 返 0 必须伴随 **7 条** | ✅ 1085/1113 条 FILL 全带 `n=cParas=1` ＋ `h0` ＋ `src` ＋ CONSUME |
| `P2` 先置条数/不填 | `*cParaDesc` **只在真填完成后**置，且＝**实际**条数 | ✅ 代码位序＋读数 `n=1=cParas`；每条目先 `memset` 再写（未初始化内存不交给上级） |
| `P3` native 自造句柄 | 唯一合法来源＝本 run 托管 `+176` | ✅ `src=managed-176`；`h0` 与同 run `keep=` 同值；本件**从不**造句柄值（只有 `wpf_pts_fsp_pl_is_sentinel` 作**具名**用） |
| `P4` use-after-recycle | 见 §4／§7 | ✅ 主链无；反腿现证 |
| `P5` "句柄非零＝可用" | 必须证**内容侧** | ✅ **解析成功**（`resolve=ok`）＋**身份与 `+176` 同值**＋**承接者真走到**（`ParaListFromTrack` 之后的效应＝`FsQuerySubtrackDetails` 被调用 1085 次，证明托管侧确实消费了这份列表并往下走） |
| `P6` 跨代相减 | 每条带当次三格 | ✅ 全部 `so16=ca97eacb8bb123f1`／`pf16=0b4b65f2c6c7ffd4` |
| `P7` 用失败行缺席当"没被调用" | 本件用**成功行计数**证被调用 | ✅ `fill=1085/1113/403` |
| `P8` 采今天已满足的网症格 | 不作证据 | ✅ 症状门只作**门**（`alive=yes`／`magenta=0` 不当证据）；证据是 FILL／CONSUME 行 |
| `P9` 常量绿／单腿 | 两腿都跑（§3）；禁用件未用（`+200`／`+56`／`fsbbox`／`dvrTopSpace` 一个没进判据） | ✅ |
| `P10` 单样本 | **两独立样本**一致 | ✅ |

---

## §7 ⑦ `resolve=wrong-object` **一票红**：机制证明（ABA 反腿逐字）

```
[FSPARALIST-CONSUME] i=0 h=0x5 resolve=wrong-object type=resolved-as-other-object via=aba-leg rc=0 released_between=1 stale=0x5 fresh=0x5 same_value=1 rc_release=0 rc_recreate=0
```
**机制（逐条现取）**：① 先 `+192(h)` 回收 ⇒ `rc_release=0`（**槽被压回自由链**）；② 再 `+176` 现造 ⇒ `rc_recreate=0` 且**新对象拿到同一个索引**（`fresh=0x5 == stale=0x5`，`same_value=1`）；③ 拿**陈旧值**去解析 ⇒ **`rc=0`**（`IsHandle()` 因新对象而为真 ⇒ `HandleToObject` 静默返回**另一个对象**、`as BaseParaClient` 还成功）。
⇒ **`rc` 完全无法区分"同一个对象"与"另一个对象"** ⇒ 因此：
- **`resolve=wrong-object` 必须单列为一票红**（本件已按此实现：`WpfLinuxWin32_PtsFsParaListResolveWrong` 独立计数口）；
- **可判红的形态**＝**来源证据断裂**（`released_between=1`／`stale==fresh`／跨代复用），**不是** `rc`；
- 反腿**因此停填**（`reason=aba-leg-stopped`），**不**把死句柄交给消费者 —— 那是**另一条**反腿（`SELFRECYCLE`）的证据，两条不混。

---

## §8 ⑧ `nm` 逐名 ＋ 症状门逐格

| 面 | 现取 | 判 |
|---|---|---|
| `nm -D --defined-only \| wc -l` vs `exports.txt` 行数 | **651 ＝ 651**；`^Fs= 6` | ✅ 相等 |
| 逐名对拍（`pre-t160` 640 名 vs 现 651 名） | **消失 ＝ 无**；**＋11 名**：`PtsFsParaList{Fills,Consumes,ResolveOk,ResolveWrong,ResolveExc,SrcIn,SrcOut,TeardownRc,LastH,LastRc176,HeldAtExit}` | ✅ |
| **ENFE_TOTAL（留痕面）** | **1085／1113／403** 条，**全部同名**：`Unable to find an entry point named 'FsQuerySubtrackDetails'` —— 数量与**本腿填充数逐值相等** ⇒ 🔴 **这是本跳绿带来的**：托管侧拿到可用列表后**继续往下走**，于是暴露**下一个缺失入口**（本跳的**真实增量**证据，也是下一跳的靶心） | 如实给 |
| 两页症状门（L1／L2／L3 逐格同） | `LEG k=23/24 alive=yes app_rc=143 magenta=0 colors=383`、`ns=RichTextBoxDemo/FlowDocumentDemo ae=0/15386 ink=480000`、`NAMED managed_unavail=0 native_gap=0`、`FAILLINE failfast=0 unrec=0` | 全绿 |
| `R7` 同趟性 | `DEV shim=ca97eacb8bb123f1 pf=0b4b65f2c6c7ffd4`；`session.txt shim_sha16=ca97eacb8bb123f1`；**现盘件同值**（未拿 `legs=2/2` 当证据） | ✅ |

---

## §9 ① 逐件 sha16 ＋ `numstat`

| 件 | sha16 | 说明 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | **`c90a78af8bc9499c`** | **t160 专属 `numstat` ＝ `289 6`**（开工 `6d967d8843bd902b`／256008 B → 276434 B） |
| `bin/libwpfwin32.so` | **`ca97eacb8bb123f1`** | 生成件（`bin/` 被 `.gitignore` 忽略） |
| `bin/exports.txt` | `163c231022c4d088`（651 行） | 同上（忽略）；`nm 651` |
| `tools/pts-gap-decl.txt` | **`087da7987fed5c6c`** | `1 1`（只改 `so16=`／`exports=`） |
| 本载体 | 末行自证（见末尾） | 新建 |
| 副本产物（反腿） | `aba=edff7a3cab64ff31`／`selfrec=ab14734e5fb749a0` | **权威件跑前跑后同 `ca97eacb8bb123f1`**（未被覆盖） |

**牙**：`PTSGAP=PASS`（`so16=ca97eacb8bb123f1 exports=651`）｜`REPORTID=PASS files=281`。

---

## §10 ⑨ `NOINFO` 清册 ＋ 具名前置状态

| # | 项 | 状态 |
|---|---|---|
| 1 | **托管侧"解析到的就是当初那个对象"的直接读数** | **`NOINFO`** —— native 只能用 `+192` 的**接受**读数；**身份**比较发生在托管消费者里（`FlowDocumentPage.cs:547`／`ContainerParaClient.cs:289`），而**托管侧在本波写域内无可写点** ⇒ 具名 **`PRECOND-NO-MANAGED-SIDE-WRITER`**（判据 §8 在册） |
| 2 | **回收正确性（自由链/句柄表）** | **`NOINFO`** ⇒ 具名 **`PRECOND-NO-HANDLE-ACCOUNTING`**（R-4；**严禁**用 `rc=0` 冒充） |
| 3 | 段落**内容/几何**是否真被排版 | **`NOINFO`**（`fsbbox`／`dvrTopSpace` 由排版方法填，本跳不负责 ⇒ 禁用为判据） |
| 4 | `DestroyDocContext` 之后回收的 `FailFast` 通路 | **`NOINFO`（本应用不可达）**：`t156` 现取四趟 `DestroyDocContext=0`（应用被 `SIGTERM` 收） |
| 5 | `W-2` 腿的**整体**绿 | **不成立**（712 × `rc=-10000`＝`no-out-of-window-client-yet`）；其**填充面**绿成立 |
| 6 | `FsQuerySubtrackDetails` 之后的链 | **`NOINFO`**（本跳到达即止；ENFE 1085 条即其边界） |

**六条 `PRECOND-*` 状态**：`PRECOND-NO-HANDLE-SOURCE` **不成立**（本 run `+176` 真被调并产出 `h0=0x5`／`0x4`）｜`PRECOND-CONSUMER-NOT-REACHED` **不成立**（消费者往下走到 `FsQuerySubtrackDetails` 1085 次）｜`PRECOND-WINDOW-LIFETIME-CONFLICT` **不成立**（两腿都成功）｜`PRECOND-DOUBLE-DESTROY` **不成立**（主链每个 `h` 恰一次 `+192`）｜**`PRECOND-NO-MANAGED-SIDE-WRITER` 成立**（见 1）｜**`PRECOND-NO-HANDLE-ACCOUNTING` 成立**（见 2）。

---

## §11 口径 · 边界 · 纪律 · 收尾

- **口径（判据逐字）**：本件绿**只准**读成「**native 能把一个由托管产出、且在持有期内有效的段落客户端句柄交给列表的消费者，且消费者解析到的是同一个对象**」（本件能证的到 `resolve=ok`＝**被接受**＋**身份与 `+176` 同值**；"同一个对象"的**最终**判据仍需托管侧读数，见 §10-1）。
- **不得**读成：❌"段落模型已成"／❌"排版打通"／❌"三级链已存在"／❌"两页能排版"／❌"`TASK-0007` 可绿"。
- **边界**：改动面 ＝ `src/WpfGfx.Linux.Native/**` ＋ 本载体；**未碰** `build/MilBridge/tools/**`／`build/MilBridge/tests/**`／`docs/**`／任何 `.cs`／哨兵／`cell=#1`（**有意未登记**）；`phase=degraded` 未翻；**探针闸缺省路径未变**（闸关 ⇒ 逐字保持 `-10000` ＋ `reason=paraclient-table-not-native`，**代码里那条 `else` 分支原样保留**）；未 `git add/commit/push`。
- **纪律**：构建 ×3（权威 ＋ 两条反腿副本）与全部腿（L1／L2／L3 ＋ 反腿 ABD／SELFRECYCLE）**全部** `heavy-slot` **后台**（日志 `build.out`／`build3.out`／`legs.out`／`legs2.out`／`rev.out`／`rev2.out`）；显示位：装置自取 `:231`（`W67_DISPLAY` 单向下传，**未手工固定** `PTS_GUARD_DISPLAY`），反腿用私有 `:238`／`:239`（**自起自收**，按 `$XP` PID）；跑后 `/tmp/.X11-unix/` 仅 `X0 X1`；**未用** `pkill`／`pgrep -f`；**未** `tee` 回灌会话。
- **过程自陈（如实）**：本件**先实现后落载体**（判据/派单要求"先落最小载体再深挖"）——实现完成后才建本载体并一次性给全读数；**未**因此放松任何判据（§2 七条与 §3 两腿均按判据原样执行）。
`P1-PARALIST-WIRE 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ b7ce3e86e3545091（末行＝本行）`
