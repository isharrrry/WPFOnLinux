# P1-W92 · 活条目数只读口（消 `PRECOND-NO-HANDLE-ACCOUNTING`）

> **本件是 `t172`（runner）的交付**。**写域**：`src/WpfGfx.Linux.Native/**` ＋本载体。**未碰** `tools/**`／`tests/**`／`docs/**`／任何 `.cs`／哨兵／`HANDOFF-NEXT.md` 的 `cell=#1`（**有意未登记**）。`phase=degraded` 未动；未 `git add/commit/push`。

## §0 开工现取
`win32_pts.c` **`6d6f753105224f78`**／319005 B（`t168` 交出后以本席现取为准）｜`so=291ef08a33f9b6e4`｜`exports=665` 行。
**已核现状（t162 台账能否外读）**：`WpfLinuxWin32_PtsSub{Live,Created,Destroyed,ClaimOk,ClaimBad}` **全部已在导出表**（逐名现取）⇒ **"外读"这一半已在**；本件要补的是 **①"0 vs 没取到"的区分**＋**②成对可证伪的两腿夹具读数**。

## §A **预登记**（**跑腿前先落**）

| # | 预登记项 | 判定规则（写死） |
|---|---|---|
| R1 | **独立于 `rc`** | 计数口只读**台账本体**（`g_pts_sub_live_n`／`g_pts_sub_created`／`g_pts_sub_destroyed`），**任何 `rc` 都不参与**；判词里不得出现"由 `rc=0` 推得" |
| R2 | **成对可证伪（两腿）** | 腿 A「**只建不回收**」`n` 条 ⇒ `live_after = live_before + n`；腿 B「**建后回收**」`n` 条 ⇒ `live_after = live_before`；**两腿的 `live` 读数必须不同**（否则＝报常量 ⇒ 判红） |
| R3 | **三式自洽** | 每一步都必须满足 `live = created − destroyed` |
| R4 | **红榜 `P8`「0 vs 没取到」** | 未初始化时端口**不得返回 0**：返回 `-1` 且 `state=NO-READING`；初始化后 `state=READING` ⇒ 两者判词不同 |
| R5 | **红榜 `P10`（先证被读到）** | 结论必须附**原始读数行**（`[HCOUNTLEDGER] …`） |
| R6 | **≥2 独立样本** | 判词一致；不许用"腿没崩"或"`rc=0`"代替计数读数 |
| R7 | **零行为改动面** | `nm` 逐名前后对拍（**无消失**、新增逐名列出）、`^Fs=` 不变、症状门逐格 |

## §1 ② 计数口的**原始读数行**（红榜 `P10`：先证"真的被读到"）

**两独立样本逐字相同**（`s1`／`s2`，同代 `so16=352855f8dfbf8dc7`）：
```
[HCOUNTLEDGER] read#0 state=NO-READING live=-1 created=-1 destroyed=-1 v=NO-READING-DISTINCT-FROM-ZERO
[HCOUNTLEDGER] leg=A_only-create   n=3 live_before=0 live_after=3 delta=3  created_before=1 created_after=4 destroyed=1 eq_live_eq_created_minus_destroyed=1 state=READING v=COUNTS-UP
[HCOUNTLEDGER] leg=B_create+destroy n=3 live_before=3 live_after=0 delta=-3 created_after=4 destroyed_after=4 eq_live_eq_created_minus_destroyed=1 state=READING v=RETURNS-TO-BASE
[HCOUNTLEDGER] pair=distinct live_A_after=3 live_B_after=0 distinct=1 v=PAIR-DISTINCT-AND-SELF-CONSISTENT
```
**只读口（逐名，全部已在导出表）**：`WpfLinuxWin32_PtsHandleLiveCount`／`…CreatedCount`／`…DestroyedCount`／`…ReadingState`（新增 4 名，见 §4）＋ `t162` 既有的 `PtsSubLive`／`PtsSubCreated`／`PtsSubDestroyed`／`PtsSubClaimOk`／`PtsSubClaimBad`。
**独立于 `rc`**：四条读数**全部**取自台账本体（`g_pts_sub_live_n`／`g_pts_sub_created`／`g_pts_sub_destroyed`）；本件的所有行**没有一处**引用任何 `rc`（红榜 `P10`／`t158` R-4 原文照守）。

## §2 ③ 三条自洽等式（现取）
| 步 | 现取 | `live = created − destroyed` |
|---|---|---|
| 腿 A 后 | `live_after=3 created_after=4 destroyed=1` | **3 = 4 − 1** ✓（`eq…=1`） |
| 腿 B 后 | `live_after=0 created_after=4 destroyed_after=4` | **0 = 4 − 4** ✓（`eq…=1`） |
| 起点 | `read#0`（未初始化）→ 首次建表后 `created=1 destroyed=1` | 自检自身那一只建后又销毁 ⇒ 「活的 0」也**由台账算出**（非缺省） |

## §3 ④ 两腿夹具（**成对可证伪**）
| 腿 | 现取 | 判 |
|---|---|---|
| **A「只建不回收」** `n=3` | `live: 0 → 3`（`delta=+3`＝`n`） | ✅ `COUNTS-UP` |
| **B「建后回收」** `n=3` | `live: 3 → 0`（`delta=−3`，**回到基线**） | ✅ `RETURNS-TO-BASE` |
| **成对** | `live_A_after=3` **≠** `live_B_after=0`（`distinct=1`） | ✅ **两腿读数必须不同** ⇒ **计数口真的在数，不是报常量** |
| ⚠️ 不许用"腿没崩"或"`rc=0`"代替 | 本件**未**使用任何 `rc` 或症状门作为计数结论（症状门只作"门"记在 §5） | ✅ |

## §4 ① 逐件 sha16 ＋ `numstat` ＋ 新增导出逐名
| 件 | 开工 | 收尾 | 判 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `6d6f753105224f78`／319005 B | **`1b642b1a906eb12f`**／323433 B | **t172 专属 `numstat = 59 3`**（＋59／−3；3 处删除＝被替换掉的三个旧端口定义体） |
| `bin/libwpfwin32.so` | `291ef08a33f9b6e4` | **`352855f8dfbf8dc7`** | 生成件 |
| `bin/exports.txt` | 665 行 | **`3942a1aafa41e1ca`**／**669 行** | **+4 名** |
| `tools/pts-gap-decl.txt` | `3a923ffba99371cb` | **`cc2f30a3577112f0`** | 只改 `so16=`／`exports=` |
| 本载体 | （新建） | 见末行自证 | — |
**新增导出逐名（4）**：`WpfLinuxWin32_PtsHandleLiveCount`｜`WpfLinuxWin32_PtsHandleCreatedCount`｜`WpfLinuxWin32_PtsHandleDestroyedCount`｜`WpfLinuxWin32_PtsHandleReadingState`；**逐名对拍：无消失**（`old→new` 差集为空，见 §5）。

## §5 ⑤ `nm` 逐名 ＋ 症状门逐格
| 面 | 现取 | 判 |
|---|---|---|
| `nm -D --defined-only \| wc -l` vs `exports.txt` 行数 | **669 ＝ 669** | ✅ |
| 逐名对拍（`pre-t172` 665 名 vs 现 669 名） | **消失 ＝ 无**；＋4 名（§4 逐名） | ✅ |
| `^Fs=` | **6**（不变） | ✅ |
| 两页症状门（两样本逐格同） | `alive=yes app_rc=143 magenta=0 colors=383`、`ns=RichTextBoxDemo/FlowDocumentDemo ae=0/15386`、`NAMED managed_unavail=0 native_gap=0`、`failfast=0 unrec=0` | ✅（**只作门，不作计数证据**） |

## §6 ⑥ ≥2 样本判词一致性
| 样本 | `app_g1.log` | `live_A/live_B` | `pair` | 与样本 1 |
|---|---|---|---|---|
| **s1**（`app_pid` 见 `s1/session.txt`） | `fill=1056`、`HCOUNTLEDGER=4` | `3／0` | `PAIR-DISTINCT-AND-SELF-CONSISTENT` | — |
| **s2** | `fill=1044`、`HCOUNTLEDGER=4` | `3／0` | 同 | ✅ **逐字一致** |

## §7 ⑦ `NOINFO` 与具名前置状态
| # | 项 | 状态 |
|---|---|---|
| **1** | **`PRECOND-NO-HANDLE-ACCOUNTING`** | 🔴 **在"本侧自有对象族"范围内可解除**：活条目数有**只读口**（4 个具名导出）、**独立于 `rc`**、**成对可证伪**（两腿读数不同：`3` vs `0`）、**三式自洽**、**≥2 样本一致**。⚠️ **射程声明（不许越读）**：本条**只覆盖 native 自有台账**（`t162` 的 subtrack 对象族）；**托管侧 `PtsContext._unmanagedHandles` 的自由链**仍**没有**只读口 ⇒ 若某件要的是"**托管表**的活条目数"，那部分**仍 `NOINFO`**（缺口具名：需托管侧只读读数，超出本波写域）。 |
| 2 | `PFSPARA` 台账覆盖面 | 本件计数口覆盖**同一个** `subtrack` 对象族（`pfspara` 的值＝该族对象的字段地址 ⇒ 同一台账）⇒ 对 `t162` 的 `pfspara` 面**同样可外读**（`PtsSubClaimOk/Bad` ＋ 本件 4 名） |
| 3 | 内容面（`pfspara` 内容／`cParas` 真值） | `NOINFO`（不在本件范围） |

## §8 ⑧ "0 vs 没取到"的区分（红榜 `P8`）
逐字：`[HCOUNTLEDGER] read#0 state=NO-READING live=-1 created=-1 destroyed=-1 v=NO-READING-DISTINCT-FROM-ZERO`
⇒ **未初始化时端口返 `-1`**（不是 `0`），并带 `state=NO-READING`；初始化后同一端口返**台账真值**且 `state=READING` ⇒ **两者判词不同**；本件**没有**把任何"没取到"打成 0。
（实现面：`g_pts_hc_reading` 状态位；四个端口在 `reading==0` 时一律返 `-1`。）

## §9 口径 · 边界 · 纪律
- **口径**：本件只主张「**native 自有对象族的活条目数**有了独立、成对可证伪的只读口」；**不得**读成"托管句柄表已可读／`+192` 的回收正确性已被证明"（后者需托管侧读数）。
- **边界**：只改 `src/WpfGfx.Linux.Native/**` ＋本载体；未碰 `tools/**`／`tests/**`／`docs/**`／`.cs`／哨兵／`cell=#1`（**有意未登记**）；`phase=degraded` 未翻；探针闸／强度旋钮／T3 门变量缺省路径未变；重活全 `heavy-slot` 后台；未 `git add/commit/push`；跑后 `/tmp/.X11-unix/` 仅 `X0 X1`。
- **过程**：**先落最小载体**（19 行、预登记 R1–R7、末行自证 `6a8c8fd5590b720b` 当场复算 MATCH）**再实现**；实现期一处前向声明缺失（自检早于端口定义）当场修：加前向声明后编译零 error。
`P1-HANDLE-COUNT 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 3862c1b4165ba872（末行＝本行）`
