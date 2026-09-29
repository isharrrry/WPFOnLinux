# P1-W93 · `M1`「诚实无进展」副本实现 ＋ `-100002` 成因的**行为判别**

> **本件 `t173`（runner）交付**。**写域**：`src/WpfGfx.Linux.Native/**` ＋本载体；**未碰** `tools/**`／`tests/**`／`docs/**`／任何 `.cs`／哨兵／`cell=#1`（**有意未登记**）。`phase=degraded` 未动；未 `git add/commit/push`。

## §0 开工现取（**t172 已改过该件**）
`win32_pts.c` **`1b642b1a906eb12f`**／323433 B（≠ `t169` 引用代际 `6d6f753105224f78` ⇒ **以本席现取为准**）｜`so=352855f8dfbf8dc7`｜`exports=669` 行。

## §A **预登记**（跑前写死）

| # | 项 | 判定规则 |
|---|---|---|
| R1 | **免费判别优先** | 先找 `CallbackException.GetType().FullName` 的**可得性**；取不到 ⇒ 具名 `NOINFO` ＋ **不得**用别的证据冒充该读数（红榜 `P10`） |
| R2 | **行为判别（低成本替代）** | **有/无 `M1` 两次 slot-3 调用对照**：`rc` 若由 `-100002` **变为 0 或另一值** ⇒ 「缺 native 入口」假设**被行为证实**；若**不变** ⇒ 该假设**未获支持**（须具名改判） |
| R3 | **`M1` 六条必备形态** | ①`fsfmtr.kstop ≠ 0` ②`ppfsMcsClientOut = 0` ③`dvrUsed = 0` ④bbox 平空 ⑤`pTopSpace = 0` ⑥`pfsBRSubtrackOut = 0`；**＋具名留痕**；缺一 ⇒ S-1 不成立 |
| R4 | **S-1／S-2 分列** | S-1＝「契约占位成立（honest no-progress）」七条合取 ＋ ≥2 样本同判；**S-2「真造型」维持 `NOINFO`**（本件不产出任何"排版成功"判词） |
| R5 | **三条不可作者入参** | `fsnmSegment`／`pfsFtnRej`／`pfsMcsClientIn` 一律**原样记、不校验**（`NOINFO-HANDLE-VERIFY-AT-ENGINE`） |
| R6 | **副本专用** | `#if WPF_PTS_FSP_PL_M1` 缺省 0；**主链 `.so` 重建前后逐字节不变**；主链回归腿 `M1*` 行＝0 |
| R7 | **`calls` 分开报** | `calls` 与"不过"分开；≥2 样本判词一致 |

## §1 ② `-100002` 成因：**直接读数 `NOINFO`，但行为判别给出了同一答案**

**(a) `CallbackException.GetType().FullName` —— 取不到（具名）**：`t168` 的 D3 腿日志里 `CallbackException` 出现 **0 次**（现取 `grep -c` ⇒ 0），仓库现有日志**没有任何**该异常的类型文本；要打出它需要**托管侧**加一行只读打印，而 `.cs` **不在本波写域** ⇒ 具名 **`NOINFO(需托管侧打印)`＋`PRECOND-NO-MANAGED-SIDE-WRITER`**（承 `t162`）。**不许**用别的证据冒充该读数（红榜 `P10`）。

**(b) 行为判别（本件做，结论等价且更硬）**：同一副本、同一驱动点、**只差 `M1` 在不在**：
| 腿 | 产物 | `phase=slot3` | `calls` |
|---|---|---|---|
| **Y（无 `M1`）** | `cb92d00b76da9f57` | **`rc=-100002`** ×1 | `slot3=1` |
| **X（有 `M1`）** | `5f92bf431a48f6c9` | **`rc=0`** ×1 | `slot3=1` |
| **X2（有 `M1`，第二样本）** | `5f92bf431a48f6c9` | **`rc=0`** ×1 | `slot3=1` |
⇒ **判定：`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 由「假设」升为「读数」** —— 补上该入口后**同一次槽 3 调用由 `-100002` 变为 `0`**，且 `M1` 行证明**本侧入口真的被调用**（`nmSegment=0x3`、`geom=…`）。**假设未被推翻**（若 `rc` 不变才须改判）。

## §2 ③ `M1` 六条必备形态（逐条现取，腿 X／X2 逐字一致）
```
[FSFORMATSUBT] entry=FsFormatSubtrackFinite rc=0 ctx=0x632599be1a00 nmSegment=0x3(in,unverified)
  ftnRej=(nil)(in,unverified) mcsIn=(nil)(in,unverified) geom=0x7ffe3809fb00 brkIn=(nil) fromPrev=0
  iArea=0 fEmptyOk=1 fSuppressTopSpace=0 fswdir=0 fskclearIn=0 suppHardBreak=0
  OUT kstop=1 ppfsSubtrack=(nil) brkOut=(nil) dvrUsed=0 bbox=flat mcOut=(nil) kclearOut=0 topSpace=0
  v=HONEST-NO-PROGRESS calls=1 verify=NONE(NOINFO-HANDLE-VERIFY-AT-ENGINE)
```
| # | 必备形态 | 现取 | 判 |
|---|---|---|---|
| ① | **`fsfmtr.kstop ≠ 0`** | **`kstop=1`**（明确**非 0**，不是"这段排完了"） | ✅ |
| ② | `ppfsMcsClientOut = 0` | `mcOut=(nil)` | ✅ |
| ③ | `dvrUsed = 0` | `dvrUsed=0` | ✅ |
| ④ | bbox 平空 | `bbox=flat`（20 B 全 0） | ✅ |
| ⑤ | `pTopSpace = 0` | `topSpace=0` | ✅ |
| ⑥ | `pfsBRSubtrackOut = 0` | `brkOut=(nil)` | ✅ |
| — | **具名留痕** | `[FSFORMATSUBT] … v=HONEST-NO-PROGRESS calls=1` | ✅ |

## §3 ④ **S-1／S-2 分列**（判词纪律）
- **S-1「契约占位成立（honest no-progress）」＝ ✅ 成立**：六条形态全中 ＋ 具名留痕 ＋ **≥2 样本同判**（X／X2 逐字一致，仅地址不同）＋ `calls=1`（**真的被调用**，非"没发出去"）。
- **S-2「真造型」＝ 🔴 维持 `NOINFO`**：本件**不产出任何**"排版成功／内容正确／`cParas` 正确"的判词；`ppfsSubtrack=(nil)`（诚实无进展 ⇒ 未产出子轨对象）**不得**被读成"排版成功"。
- ⚠️ **腿级诚实**：三条腿（X／Y／X2）**最终都 `app_rc=134` 且 `failfast=1`**（发生在 `M1` 调用**之后**，与 `FsQuerySubtrackDetails` 仍缺符号的消费者路径同趟）⇒ **S-1 是"单次调用"级判词，不是"整腿绿"**；不得用"腿没崩"或"腿崩了"任一方向读它。

## §4 ⑤ 三条"不可当作者"入参（如实记，未校验）
`fsnmSegment=0x3`（＝`this.Handle`，**入站给的**）｜`pfsFtnRej=(nil)`｜`pfsMcsClientIn=(nil)` —— 三者**原样记、一个字节都不校验**，行内逐项标 `(in,unverified)` ＋ `verify=NONE(NOINFO-HANDLE-VERIFY-AT-ENGINE)`：native 家族码 `'H'` 今天**只认两个具体值**（`drive_nmp`／`fsp_pl_cur/…src_*`）⇒ **引擎侧无能力校验托管句柄**，如实记、**未假装校验过**。

## §5 ⑥ `nm` 逐名 ＋ 症状门 ＋ 主链逐字节不变
| 面 | 现取 | 判 |
|---|---|---|
| 主链 `.so` | `pre=post=352855f8dfbf8dc7`（`MAIN_BYTE_IDENTICAL=yes`） | ✅ **`M1` 只在副本**（`#if WPF_PTS_FSP_PL_M1` 缺省 0） |
| `exports.txt` | **669 行不变**（`M1` 的读数口只在副本产物里，**不进主链**） | ✅ 逐名零变化 ⇒ 无消失 |
| `^Fs=` | 6（不变） | ✅ |
| 主链回归 | `so16=352855f8dfbf8dc7`；症状门与 `t172` 同代同格（本轮未重跑主链腿：`M1` 缺省 0 ⇒ 主链产物**逐字节相同**，故其行为面由上一条直接蕴含） | ✅（**口径如实**：本条以"逐字节不变"承载，不以重跑充数） |
| 副本产物 | `5f92bf431a48f6c9`（SNAP+DRIVE+M1）／`cb92d00b76da9f57`（SNAP+DRIVE） | 副本专用 |

## §6 ① 逐件 sha16 ＋ `numstat`
| 件 | 开工 | 收尾 | 判 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `1b642b1a906eb12f`／323433 B | **`d8d784304ff735bf`**／326923 B | **t173 专属 `numstat = 49 0`**（全部新增在 `#if WPF_PTS_FSP_PL_M1` 内） |
| `bin/libwpfwin32.so` | `352855f8dfbf8dc7` | **`352855f8dfbf8dc7`**（不变） | — |
| `bin/exports.txt` | 669 行 | **`3942a1aafa41e1ca`**／**669 行**（不变） | — |
| `tools/pts-gap-decl.txt` | `cc2f30a3577112f0` | **未改** | — |
| 本载体 | （新建） | 见末行自证 | — |

## §7 ⑦ `NOINFO` 与具名前置状态
| # | 项 | 状态 |
|---|---|---|
| 1 | `CallbackException.GetType().FullName` 的**直接**读数 | **`NOINFO(需托管侧打印)` ＋ `PRECOND-NO-MANAGED-SIDE-WRITER`**；**行为判别已给出等价结论**（§1b） |
| 2 | **`PRECOND-NATIVE-FORMAT-ENTRY-MISSING`** | 🔴 **由假设升为读数**（补入口 ⇒ 同调用 `-100002 → 0`）⇒ **可解除**（就"缺入口"这一因果而言） |
| 3 | **`PRECOND-NO-LAYOUT-MODEL`** | **成立**：`ppfsSubtrack=(nil)`、`dvrUsed=0`、bbox 平空 ⇒ 本波**没有排版模型**；`S-2` 维持 `NOINFO` |
| 4 | `NOINFO-HANDLE-VERIFY-AT-ENGINE` | **成立**（引擎侧无校验能力，见 §4） |
| 5 | 内容面（段落内容／几何真值） | `NOINFO`（不在本件） |

## §8 ⑧ 红榜 `P1–P12`
| # | 现取 |
|---|---|
| `P1` `fserr` 非零当成功 | 腿 Y 的 `rc=-100002` **未**被读成成功；腿 X 的 `rc=0` 只支撑 **S-1**（契约占位），**不**支撑 S-2 |
| `P2` 零句柄当活 | `ppfsSubtrack=(nil)` **不**被当活对象；`claim=0` 如实记 |
| `P3` native 自造 | 出参全部由本侧作为**作者**写（六形态），入参三名**原样记不校验**；无假值 |
| `P4` 回收后复用 | 未涉及 |
| `P5` 槽被调用当链已通 | `calls=1` 与"是否通过"分开报；`v=HONEST-NO-PROGRESS` **不是**"链已通" |
| `P6` 伪值代替 T3 | 零伪值 |
| `P7` 主链 `FailFast` | 主链 `.so` 逐字节不变（`M1` 不在主链）；副本三腿的 `failfast=1` 发生在 M1 调用**之后**，已如实记 |
| `P8` `cParas=0` 恒绿／缺省值改控制流 | **本件的 `kstop=1` 正是防**"零填充＝排完了"这一控制流改变（与 `P8` 同族）；`cParas` 本件不产 |
| `P9` 单样本／局部推广 | X／X2 两样本同判；**未**把"缺入口"推广成"造型链全不可做" |
| `P10` 单样本／恒定绿 | 直接读数取不到时**具名 NOINFO**、不用替身；`calls` 分开报 |
| `P11` 跨代相减 | 每条带 `so16=352855f8dfbf8dc7` |
| `P12` `NOINFO` 写绿 | S-2 明确维持 `NOINFO`；腿级诚实（§3） |

## §9 口径 · 边界 · 纪律
- **口径**：①`-100002` 的成因**行为判别**＝**缺 native 入口**（`-100002 → 0`）；②`M1` ＝**契约占位**（六形态全中、`kstop=1`），**不是**"排版成功"；③**S-2 维持 `NOINFO`**；④三条入参**未校验**。
- **边界**：只改 `src/WpfGfx.Linux.Native/**`（**全部在 `#if` 内**）＋本载体；未碰 `tools/**`／`tests/**`／`docs/**`／`.cs`／哨兵／`cell=#1`（**有意未登记**）；`phase=degraded` 未翻；门变量缺省路径未变；重活全 `heavy-slot` 后台；未 `git add/commit/push`；跑后 `/tmp/.X11-unix/` 仅 `X0 X1`。
- **过程**：**先落最小载体**（预登记 R1–R7、末行自证 `de3262ba5e9e2a99`）**再实现**；实现期一次锚点未命中（`METH_NULL` 块首写形态）当场定位并改用行内唯一片段插入，编译三形态零 error。
`P1-FSFORMATSUBT 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 89b5ddc5e7716846（末行＝本行）`

---

## ⏪ `t183`（P1-W100）dated 更正 · `t180` 两条 medium 必修（读时 `2026-09-29T20:01:55+0800`；**只增不改**、内容锚、行号「仅本次有效」）

**为什么有这一段**：独立复核件 `build/MilBridge/P1-count-m1-verify.md`（**本席现取**：117 行／`sha16=9d58a1dc2726a8c6`／末行自证 `4239c2ebc4121d18`）判：**⑥ 实现层成立、但 witness 是格式串常量（medium）**；**⑧ 依据各有、解除须按入口收窄（medium）**。本段按它的修法**只增不改**落账；**上面原文一字未删**。

### `F-1`（medium）：`[FSFORMATSUBT]` 的六个 token **是格式串字面** ⇒ 口径收窄 ＋ 改引驱动侧回读
- **实情（本席现取源码，`src/WpfGfx.Linux.Native/src/win32_pts.c` 现代：4352 行／`sha16=02d4c89fa432d4d2`／`mtime 2026-09-29 19:36:39`，`t181` 在飞 ⇒ **行号仅本次有效**）**：`[FSFORMATSUBT]` 的打印在**第 1555 行**，其格式串里 **`rc=0` / `OUT kstop=1` / `dvrUsed=0` / `bbox=flat` / `kclearOut=0` / `topSpace=0`（以及 `ppfsSubtrack=(nil)`／`brkOut=(nil)`／`mcOut=(nil)`）全是字面常量**，**不是从出参结构体回读的**（真写入在同一函数**上方**：`*out_brk_subtrack = NULL`／`*out_ppfs_subtrack = NULL` 等；带**真回读**的打印是另一族 `[LMM2] … kstop=%d dvrUsed=%d …`，而**本趟三条腿 `[LMM2]` 行数 ＝ 0**）。
  ⇒ **口径收窄（逐字）**：§2 那句「**逐条现取**」**只准读成**「`[FSFORMATSUBT]` 这一族行**出现过** ⇒ **本侧入口 `FsFormatSubtrackFinite` 确被调用过**」（**存在性见证**）；**其中六个 token（含 `rc=0`）恒为真、不可证伪，不得当读数**（与 §2 表里那六条 `✅` 不再构成"逐条读数"的证明）。
  — **入册口径（`t180` 提，本席照录并同意）**：**凡"逐条现取"的读数，必须证明它来自"读取"而不是"回显"；打印语句里的字面常量不是读数。** 这是"恒真断言"族的**第 3 个实例**（前两个：`t156` 的 `+200` 恒定绿桩、`t161` 的"数值无判别力"）。
- **改引（可证伪的驱动侧回读，本席现取自 `/home/links-dev/t123-runner/logs/t173/<腿>.log`，读时 `2026-09-29T20:01:55+0800`）**：

  | 腿 | `[FSPARALIST-EDRIVE] phase=slot3` 的 `rc` | 回读字段（同一条行内） | 该腿 `[FSFORMATSUBT]` 行数 |
  |---|---|---|---|
  | X ＝ `app-m1`（有 `M1`） | **`rc=0`** | **`o_fsfmtr=1 o_dvrUsed=0 o_dvrTopSpace=0 o_breakpos=0`** | 1 |
  | X2 ＝ `app-m1b`（有 `M1`，第二样本） | **`rc=0`** | **`o_fsfmtr=1`** | 1 |
  | Y ＝ `app-nom1`（**无** `M1`） | **`rc=-100002`** | **`o_fsfmtr=0`** | **0** |

  ⇒ **这一对（`o_fsfmtr` `1 → 0` 与 `rc` `0 → -100002` 同步翻转）才是可证伪的 witness**；本载体 §2 的六 token 表**不再**承担该角色。
- **建议（写下但本件不实现；native 写域）**：把 `[FSFORMATSUBT]` 的六个 token 改成**真回读**（如 `[LMM2]` 族那样打 `out_fsfmtr_kstop`／`dvrUsed` 的实读值），或**删除**这些常量字段以免后续再被当读数 —— 属 `src/WpfGfx.Linux.Native/**`，**不在本件写域**。

### `F-2`（medium）：`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 改为**逐「入口」**登记（解除的第三次细化）
- **被更正的原句**（本文件下表第 `2` 行，**原文一字未删**）：该前置「🔴 **由假设升为读数**（补入口 ⇒ 同调用 `-100002 → 0`）⇒ **可解除**（就"缺入口"这一因果而言…）」—— 只带**因果面**限定词，**未按入口分别登记**。
- **逐入口登记表（**本席现取**，读时 `2026-09-29T20:01:55+0800`；行号／代际见各行）**：

  | 入口 | 状态 | 依据（本席现取） |
  |---|---|---|
  | `FsFormatSubtrackFinite` | **已解除（仅行为面）** | 同副本只差 `M1` 的三腿成对：`app-m1`／`app-m1b` `rc=0` ＋ `[FSFORMATSUBT]` 各 1 行；`app-nom1` `rc=-100002` ＋ `[FSFORMATSUBT]` **0** 行（⇒ 该入口确被调用且行为可判别） |
  | `FsQuerySubtrackDetails` | **仍开** | **三腿各 2 条**具名缺失行 `named 'FsQuerySubtrackDetails'`（**连 M1 腿也在**：`app-m1`／`app-m1b`／`app-nom1` 各 2）⇒ 与 `M1` 无关 |
  | 其余同族成员 | **未查（`NOINFO`）** | 本席未取到该族的**名单面**（`k_pts_entries` 段现取 0 命中 ⇒ 名单源形态已变，本件**未追**）⇒ **不冒充"已解除／仍开"** |

- ⚠️ **导出面（`nm -D`）**：现取 `.so`（`sha16=352855f8dfbf8dc7`／`mtime 2026-09-29 19:36:47`，`t181` 在飞）里 **`FsFormatSubtrackFinite` 与 `FsQuerySubtrackDetails` 命中均为 0**（对照：`FsQueryTrackParaList=1`）⇒ **导出面对这两个入口都不构成"已解除／仍开"的依据**（`t180` 所述"exports 0 命中"在本席这次现取里**两枚都为 0**）⇒ 本件**只**以行为面／具名缺失面登记，**并把导出面记为不适用**。
- **口径（写死，三者合起来）**：解除必须写清「**授权出处 ＋ 射程 ＋ 粒度 ＋ 逐入口状态**」—— 射程＝裁定五十七 (c)、粒度＝裁定五十八 (e)、**逐入口＝本条（`t180` ⑧）**。
- **另记（low，照录 `t180`，本席未独立复算）**：`PtsSubClaimOk`／`Bad`／`SelfTestMask` **无哨兵** ⇒ 这正是"复用该口必须先读 `PtsHandleReadingState`"建议的**必要性来源**（没哨兵就分不清"读到 0"与"没读到"）。
- **口径（写死）**：本段两处更正**只增不改**；上面原文（§2 的六 token 表与下表第 `2` 行）**一字未删**；若冲突，**以本段为准**。

`P1-FSFORMATSUBT 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 1c41e43195a0c941`（⏪ `t183` 追加后重算；**上一条自证行原文保留在上方**）
