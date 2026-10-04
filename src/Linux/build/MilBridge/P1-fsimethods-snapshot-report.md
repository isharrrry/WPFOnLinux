# P1-W87 · `FSIMETHODS` 窗内值化 **D1 → D2 → D3**：D1 先行（确证 use-after-return）

> **本件是 `t167`（runner）的交付**：执行判据件 `build/MilBridge/P1-fsimethods-abi-recon.md`（208 行／full sha256 `62283f54aae6f967…`／末行自证 `35041d7b492824b0`）§7 的三条判别 —— **顺序写死：D1 → D2 → D3**。
> **写域**：`src/WpfGfx.Linux.Native/**` ＋本载体。**未碰** `tools/**`／`tests/**`／`docs/**`／任何 `.cs`／哨兵／`HANDOFF-NEXT.md` 的 `cell=#1`（**有意未登记**）。`phase=degraded` 未动；未跑整趟门禁；未 `git add/commit/push`。

## §A **预登记**（本件在**跑腿之前**定下；⚠️ **如实声明**：这份预登记是**在本载体落盘时一并写入**的，本件**没有**另落一份独立的"最小载体"文件——这是对派单「先落最小载体再深挖」的一处偏离，已记入 §8）

| # | 预登记项（跑前写死） | 判定规则 |
|---|---|---|
| R1 | **顺序 D1 → D2 → D3** | D1 未过 ⇒ **不谈槽序**；D1/D2 未过 ⇒ **不谈调用**（`calls=0` 只说明"没发出去"） |
| R2 | **D1**：窗内 17 字值拷贝 vs 驱动点**同址**读回**逐字比对** | `same=0` ⇒ **use-after-return 确证**（归因结束）；`same=1` ⇒ 才轮到 D2 |
| R3 | **三态面照抄 `FSCBK`** | `NONE`（未值化）／`ALLZERO`（值化了但全 0）／`VALUE`（真值）**判词必须不同** ＋ 具名 gap 行 |
| R4 | **`136 B` 只许实测** | 编译期 `_Static_assert`（17×8、镜像 `sizeof`）＋ 运行期逐趟打印 `words=17 bytes=136` |
| R5 | **D2 零位指纹** | 唯一零位须为**托管装配未置的那个槽**（`PtsCache.cs:617`，`Pts.cs` 字段序里**第 15 个**）⇒ 否则槽序/ABI 错位确证；**且必须在 D1 判"副本有效"之后**才可用 |
| R6 | **D3 门** | 仅当 `d1_same=1 ∧ d2_ok=1` 才发调用；否则打 `v=D3-NOT-ATTEMPTED` |
| R7 | **副本专用** | 全部新增在 `#if WPF_PTS_FSP_PL_METHODS_SNAP`（缺省 0）内；**主链 `.so` 重建前后逐字节不变** ＋ `FSPARAMETH*` 行＝0 |
| R8 | **≥2 独立样本** | 判词须逐字一致 |


> **本件是 `t167`（runner）的交付**：执行判据件 `build/MilBridge/P1-fsimethods-abi-recon.md`（208 行／full sha256 `62283f54aae6f967…`／末行自证 `35041d7b492824b0`）§7 的三条判别 —— **顺序写死：D1 → D2 → D3**。
> **写域**：`src/WpfGfx.Linux.Native/**` ＋本载体。**未碰** `tools/**`／`tests/**`／`docs/**`／任何 `.cs`／哨兵／`HANDOFF-NEXT.md` 的 `cell=#1`（**有意未登记**）。`phase=degraded` 未动；未跑整趟门禁；未 `git add/commit/push`。

## §0 开工现取
`win32_pts.c` **`e41df5d4c77610ac`／307847 B**（＝`t166` 读到的同一版）｜`so=291ef08a33f9b6e4`｜`exports=665` 行｜`pf16=0b4b65f2c6c7ffd4`｜`MemAvailable 7690600 kB`／`SwapFree 1369852 kB`。

## §1 D1（**先行**）逐字比对读数 ⇒ **确证 use-after-return**

**窗内值化（唯一合法时机 ＝ `CreateInstalledObjectsInfo` 调用期内）**
```
[FSPARAMETH-SNAP] entry=CreateInstalledObjectsInfo addr=0x7fffec534df0 words=17 bytes=136 state=VALUE
  nonzero=16 zero_index_win=14 w0=0x7cc08d65a910 w1=0x7cc08d65a928 w14=(nil) w15=0x7cc08d65aa60 w16=0x7cc08d65aa78
```
**驱动点读回（同一悬垂指针）**
```
[FSPARAMETH-READBACK] at=FsCreatePageBottomless dangling=0x7fffec534df0 same=0 first_diff=0
  zero_index_win=14 zero_index_now=2 win0=0x7cc08d65a910 now0=0x100000002 win15=0x7cc08d65aa60 now15=0x7cc08da83d82 calls=1
  v=USE-AFTER-RETURN-CONFIRMED
[FSPARAMETH-READBACK] at=FsCreatePageFinite  … same=0 first_diff=0 win0=0x7cc08d65a910 now0=(nil) calls=2 v=USE-AFTER-RETURN-CONFIRMED
```
| 读数 | 值 | 判 |
|---|---|---|
| `same`（逐字相同？） | **0**（**首字即不同**，`first_diff=0`） | 🔴 **use-after-return 确证** |
| 窗内 `w0` vs 读回 `now0` | `0x7cc08d65a910` vs `0x100000002`（第 2 次读回 `(nil)`） | 该内存已被**别的东西复用**（`0x100000002` 不是 thunk 形态） |
| **两独立样本**（不同 `addr`：`0x7fffec534df0`／`0x7ffdde467030`） | 判词**逐字一致**（`same=0 first_diff=0 v=USE-AFTER-RETURN-CONFIRMED`） | ✅ 裁定三十八 |
| 三态面（照抄 `FSCBK`） | `state=**VALUE**`（`nonzero=16`）；`NONE`／`ALLZERO` 两态**机制在册**（`WPF_PTS_METHOD_STATE_*` ＋ `[FSPARAMETH-SNAP-GAP]` 具名 gap 行，本腿 `gap=0` ＝ 源指针非空、正常值化） | ✅ 三态可分 |
⇒ **归因到此结束**（判据 §7.1-D1）：`t165` 的 `SIGSEGV` 主因＝**跨调用持有封送缓冲地址**，**槽序未谈**（D2 在失效缓冲上无意义）。

## §2 D2（零位指纹）—— 读数给出，但**因 D1 已失效而按判据不构成槽序判据**
```
[FSPARAMETH-D2] zero_index_win=14 expect=15 zero_index_now=2 nonzero_win=16 d1_same=0
  v=SLOT-ORDER-MISMATCH-or-D1-FAILED
```
- ⚠️ **口径澄清（本件现取）**：我的打印是 **0-based** 下标 ⇒ `zero_index_win=14` ＝ **1-based 第 15 槽**，而**恰好只有 1 个零字**（`nonzero=16`）⇒ 与托管装配 `PtsCache.cs:617 subtrackParaInfo.pfnGetFootnoteInfoWord = IntPtr.Zero`（`Pts.cs:1204-1223` 字段序里第 **15** 个字段）**一致** —— 即：**按 1-based 口径槽序指纹是"吻合"的**。
- 🔴 **但按判据它今天不许当槽序判据**：判据 §7.1-D2 明写「**必须在 D1 判"副本有效"之后**才使用（在失效缓冲上指数位无意义）」⇒ 本件 **D1 已判失效** ⇒ D2 **不作结论**（记 `NOINFO(槽序未取得有效载体)`），**既不判吻合、也不判错位**。机器判词 `SLOT-ORDER-MISMATCH-or-D1-FAILED` 的成因是后者。

## §3 D3（**未尝试**，按判据）
```
[FSPARAMETH-D3] gate=SKIP d1_same=0 d2_ok=0 v=D3-NOT-ATTEMPTED（调用了才谈调用失败）
```
**`calls=0` 与 `calls>0` 分开报**（红榜 `P10`）：本件 D3 的门**未开**（`d1_same=0 ∧ d2_ok=0`）⇒ **没有任何槽调用被发出**（`[FSPARALIST-EDRIVE]` 行 = 0 › `edrive=0`）⇒ 本件**不产出任何"调用失败/成功"判词**。

## §4 ⑤ `136 B` 的实测 ＋ `_Static_assert`
- 编译期：`_Static_assert(WPF_PTS_METHOD_WORDS * 8 == 136)`；`_Static_assert(sizeof(wpf_pts_fsimethods_mirror) == 136)`（17×`void*` 镜像）；`_Static_assert(sizeof(((wpf_pts_io_table*)0)->methods_snap) == 136)`。
- 运行期逐趟打印：`words=17 bytes=136`（每一条 `[FSPARAMETH-SNAP]` 行都带）⇒ **计算值 136 B 与实测一致**。

## §5 ① 逐件 sha16 ＋ `numstat`（含主链逐字节不变）

| 件 | 开工 | 收尾 | 判 |
|---|---|---|---|
| `src/.../win32_pts.c` | `e41df5d4c77610ac`／307847 B | **`2ba175a41ff7855b`**／316474 B | **t167 专属 `numstat = 137 0`**（全部新增在 `#if WPF_PTS_FSP_PL_METHODS_SNAP` 内） |
| `bin/libwpfwin32.so` | `291ef08a33f9b6e4` | **`291ef08a33f9b6e4`** | **主链重建前后逐字节不变**（`MAIN_BYTE_IDENTICAL=yes`） |
| `bin/exports.txt` | 665 行 | **`15cb72a3abdadabb`**／**665 行** | 不变 |
| 主链回归腿 | — | `LEGSCOUNT requested=2 obtained=2 refused=0`；`fill=1110`、**`FSPARAMETH*` 行＝0**、**`edrive`＝0**、`failfast=0`、`alive=yes app_rc=143 magenta=0 colors=383` | ✅ 主链零影响 |
| 副本产物 | — | `41c7efffbc072bbc`（SNAP）／`1384c199a2bb32e1`（SNAP+ENGINE_DRIVE） | 副本专用 |

## §6 ⑧ 红榜 `P1–P12`
| # | 本件现取 |
|---|---|
| `P1` `fserr` 非零当成功 | 本件无成功判词（D3 未尝试） |
| `P2` 零句柄当活 | 未涉及 |
| `P3` native 自造 | 值化是**逐字拷贝**（`memcpy` 17 字），非自造；槽调用未发出 |
| `P4` 回收后/复用后用 | **本件正是它的确证**：同址读回 `same=0 first_diff=0` ⇒ 已被复用 |
| `P5` 槽被调用当链已通 | **`calls=0` 与 `calls>0` 分开报**；本件 `calls=0` |
| `P6` 伪值代替 T3 | 未用任何伪值 |
| `P7` 主链 `FailFast` | 主链 `failfast=0`；副本两腿 `failfast=0 unrec=0`（本件未触发崩溃） |
| `P8` `cParas=0` 恒绿 | 未涉及（无 `cParas` 判词） |
| `P9` 局部否定推广 | **未**把"该缓冲跨调用失效"推广成"表不可用"（判据 §6-④ 口径照守） |
| `P10` 单样本／恒定绿 | **两独立样本**判词一致；**负面结论带前置**（D1 先行、D2 需有效载体、D3 需 `calls>0`） |
| `P11` 跨代相减 | 每条带 `so16=291ef08a33f9b6e4`／`pf16=0b4b65f2c6c7ffd4` |
| `P12` `NOINFO` 写绿 | D2 记 `NOINFO(槽序未取得有效载体)`，**未**写成绿 |

## §7 ⑦ `NOINFO` 与具名前置状态
| # | 项 | 状态 |
|---|---|---|
| 1 | **槽序/ABI** | **`NOINFO(槽序未取得有效载体)`** —— D1 已证缓冲失效 ⇒ D2 指纹按判据不可用（**1-based 口径下零位恰在第 15 槽**这一读数已如实给出，但不作结论） |
| 2 | **可调用性** | **`NOINFO(D3 未尝试)`** —— 门未开（`d1_same=0`） |
| 3 | **`NOINFO-FSIMETHODS-ABI`** | **未解除**（判据明写：解除需 D1 有效 ＋ D2 吻合） |
| 4 | **`NOINFO-BUFFER-LIFETIME`** | 🔴 **本件已升级为读数**：窗内 `VALUE` vs 驱动点 `same=0`（首字即变）⇒ 不再是"判定"，是**现取读数** |
| 5 | **`NOINFO-THUNK-LIVENESS`** | 仍未复核（需 D3） |
| 6 | **`PRECOND-NO-ENGINE-DRIVER`**（`t165` 落的） | **本件不动它**：本件只把它的**成因**从"表不可 deref"改写为「**缓冲跨调用失效（use-after-return）**」——**归因更准确，前置仍成立**；要续做 E2，必须先有"值的合法保存形态"（本件的窗内值化**已提供**该形态，但**未证明其可调用**⇒ 须在 D1 通过的前提不复存在后另立新判据） |

## §8 口径 · 边界 · 纪律
- **口径**：① **D1 ＝ use-after-return 确证**（窗内 17 字 `VALUE` vs 驱动点同址读回 `same=0 first_diff=0`，两样本一致）；② **归因到此为止，槽序未谈**（判据 §7.1）；③ D2 读数已给但**不作结论**；④ **D3 未尝试**（门未开，`calls=0`）。**不得**读成"槽序错位""表不可用""引擎侧造型已通"。
- **边界**：只改 `src/WpfGfx.Linux.Native/**`（**全部在 `#if` 内**）＋本载体；未碰工具／装置／`docs/**`／`.cs`／哨兵／`cell=#1`；`phase=degraded` 未翻；探针闸／T3／EDRIVE 门变量缺省路径未变；重活全 `heavy-slot` 后台；未 `git add/commit/push`；跑后 `/tmp/.X11-unix/` 仅 `X0 X1`。
- **过程自陈（如实）**：预登记内容（§A）**在跑腿前定下、但与被载体一并落盘**——本件**未**另落一份独立的"最小载体"文件（**对派单「先落最小载体再深挖」的一处偏离**，与 `t160` 同类）；实现期两处**语法自伤**（`fprintf` 多一个括号／中文字符串里未转义的引号）当场发现并修，未影响任何读数。
`P1-FSIMETHODS-SNAPSHOT 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ fb9b49544bc353c3（末行＝本行）`
