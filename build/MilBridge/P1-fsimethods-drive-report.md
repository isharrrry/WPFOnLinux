# P1-W88 · 重判 `D2`（窗内读数即"有效副本"）＋ 用**值化副本**做 `D3` 调槽 3

> **本件是 `t168`（runner）的交付**，执行队长裁定（三处口径）＋`t166` 判据 §7 的升级路径。**槽号一律 1-based 叙述，打印时 `idx0=`／`slotN=` 双口径都给。**
> **写域**：`src/WpfGfx.Linux.Native/**` ＋本载体。**未碰** `tools/**`／`tests/**`／`docs/**`／任何 `.cs`／哨兵／`cell=#1`（**有意未登记**）。`phase=degraded` 未动；未 `git add/commit/push`。

## §0 开工现取
`win32_pts.c` 现取 **sha16 见本件 §6**（`t167` 交出 `2ba175a41ff7855b`／316474 B；开工复核）｜`so=291ef08a33f9b6e4`｜`exports=665` 行。

## §A **预登记**（**跑腿前先落**，本件不重复 `t167` 的偏离）

| # | 预登记项 | 判定规则（写死） |
|---|---|---|
| R1 | **"有效副本"的定义**（队长口径二） | ＝**窗内值化成功的那份拷贝**（`state=VALUE`、`nonzero>0`）；**不是**"`d1_same=1`"。`D1` 的 `same=0` **正是悬垂的预期结果**，与副本有效性**无关** |
| R2 | **`D2` 重判** | 在**有效副本**上数零位：**零位恰一处** ∧ 该位＝**1-based 第 15 槽**（`slotN=15`，即 `idx0=14`）⇒ `SLOT-ORDER-OK`（与 `PtsCache.cs:617` 未装配槽吻合）；否则 `SLOT-ORDER-MISMATCH`（给列位逐格） |
| R3 | **`D3` 门** | 仅当 `D2=SLOT-ORDER-OK` 才发调用；否则打 `v=D3-NOT-ATTEMPTED(reason=slot-order-mismatch)` |
| R4 | **`D3` 调用源（队长口径三）** | **必须是被值化的副本**（`methods_snap` 内的 17 个指针值），**不是**悬垂指针、**不是**原始缓冲 ⇒ `THUNK-LIVENESS` 由"判定"升"读数" |
| R5 | **投毒＋四断言** | 全部 out 先置毒；断言 `rc=0` ∧ `pfspara` 被改写 ∧ 身份可认领 ∧ 只增一条记账 |
| R6 | **族匹配** | 先分类再喂、非 `H` 一律拒；`nmp`／`pfsparaclient` 恒为族 `H`（**照 `t167` 的完整集合：`drive_nmp`／`fsp_pl_cur`／`fsp_pl_src_in`／`fsp_pl_src_out`**） |
| R7 | **副本专用** | 主链 `.so` **重建前后逐字节不变**；主链回归腿 `FSPARAMETH*`／`[FSPARALIST-EDRIVE]` 行 ＝ 0 |
| R8 | **`calls` 分开报** | `calls=0`（没发出去）与 `calls>0`（发出去后的结果）**必须分开**；≥2 独立样本判词一致 |
| R9 | **三态 `NONE`/`ALLZERO` 与 gap 行** | 若本件能用**注入开关**触发就给读数；不能 ⇒ 具名 `NOINFO`（不许沉默） |

## §1 ② `D2` **重判**（队长口径二：有效副本 ＝ 窗内值化成功的那份拷贝）

**两独立样本逐字一致**（`app_rc=143`、`failfast=0`）：
```
[FSPARAMETH-SNAP]  entry=CreateInstalledObjectsInfo addr=0x7ffdaff32c90 words=17 bytes=136 state=VALUE nonzero=16
   zero_index_win=14 w0=0x7f63a9c4a910 w1=0x7f63a9c4a928 w14=(nil) w15=0x7f63a9c4aa60 w16=0x7f63a9c4aa78
[FSPARAMETH-SNAP]  zero_cnt_win=1 idx0_zero=14 slotN_zero=15（1-based；判据写「第 15 槽」）
[FSPARAMETH-D2]    copy_state=VALUE valid_copy=1 zero_cnt_win=1 idx0_zero=14 slotN_zero=15 expect_slotN=15
                   calib=both(idx0=0-based, slotN=1-based) nonzero_win=16 d1_same=0
                   v=SLOT-ORDER-OK(唯一零位=1-based 第 15 槽 ⇒ 与 PtsCache.cs:617 吻合)
```
| 逐格 | 现取 | 对照 `PtsCache.cs:617 subtrackParaInfo.pfnGetFootnoteInfoWord = IntPtr.Zero` |
|---|---|---|
| 副本有效性 | `state=VALUE ∧ nonzero=16` ⇒ **有效副本** | — |
| 零位**数目** | `zero_cnt_win=1`（**恰一处**） | 托管只有**一个**未装配槽 ⇒ 吻合 |
| 零位**位置**（双口径） | `idx0_zero=14`（0-based）／**`slotN_zero=15`（1-based）** | `Pts.cs:1204-1223` 字段序里 `pfnGetFootnoteInfoWord` ＝**第 15 槽** ⇒ **吻合** |
| 其余 16 槽 | `nonzero=16`（全非空） | 托管对其余 16 槽都装了委托 ⇒ 吻合 |
⇒ **`D2` 结论（重判）：`SLOT-ORDER-OK` —— 槽序指纹支持"槽序正确（未错位）"，`NOINFO-FSIMETHODS-ABI` 的"槽序"部分据此解除**（详见 §5）。
⚠️ **依据链如实**：本判据的载体是**窗内值化副本**（不是悬垂指针）；`D1` 的 `same=0`（悬垂确证）**与副本有效性无关**（队长口径二）。

## §2 ③ `D3`（**调用源＝值化副本**）＋ ④ `THUNK-LIVENESS` **由判定升读数**

**门**：`[FSPARAMETH-D3] gate=PASS（D2 slot-order ok；调用源＝值化副本）src=methods_snap d1_same=0 v=THUNK-LIVENESS-TEST` ⇒ **调用真的发出**（`calls>0`；`calls` 计数现取见下），与 `t167` 的 `calls=0` 明确区分（红榜 `P10`）。

**逐调读数（副本 `7c504cccf05d3a62`，腿 `app-snapdrive.log`）**
```
[FSPARALIST-EDRIVE] where=FsCreatePageBottomless methods=0x5a9222e46bac fam_nmp=H fam_client=H
[FSPARALIST-EDRIVE] phase=slot1 rc=0 sobjc=0x1b63 pre=0xa5a5a5a5a5a5a5a5 rewritten=1 idobj=7001 ffi=0x1
                    author=idobj,ffi(NOINFO-FSCBKOBJ-CONTRACT=pfscbkobj->NULL) v=OBJCTX-PRODUCED
[FSPARALIST-EDRIVE] phase=slot3 rc=-100002 nmp=0x3 client=0x5 geom=…(self-defined) rect=0,0,768,576
                    pfsobjbrk=NULL(contract) pmcsclientIn=0 pftnrej=0 fEmptyOk=1 fSuppressTopSpace=0
                    fswdir=0 iArea=0 pre_pfspara=0xa5a5a5a5a5a5a5a5 pfspara=(nil) rewritten=1 claim=0
                    created=1 live=0 v=CALLBACK-ERR
[FSPARALIST-EDRIVE] asserts A_rc0=0 B_rewritten=1 C_claimable=0 D_one_new_entry=0 v=E2-ASSERTS-PARTIAL
（第二驱动点 FsCreatePageFinite：slot1 再次成功 sobjc=0x1b64 idobj=7002；其后进程 FailFast ⇒ app_rc=134）
```
| 面 | 现取 | 判 |
|---|---|---|
| 🔴 **`THUNK-LIVENESS`** | **副本里的槽 1 指针真的被调用且返回 `rc=0`**，并产出 `sobjc=0x1b63`＝**7011**＝`idobj(7001)+10` —— 与托管实现 `pfssobjc = idobj + _objectContextOffset(10)` **逐值吻合** | ✅ **升级为读数：值化副本里的 thunk 指针可调用**（`t166` 的"判定"由此成立） |
| 断言 A `rc=0` | **0**（槽 3 返 `-100002`） | ❌ |
| 断言 B `pfspara` 被改写 | **1**（毒值 `0xa5a5…` → `(nil)`） | ✅（改写发生，但改写成 **0**） |
| 断言 C 身份可认领 | **0**（`claim=0`；`pfspara=(nil)`） | ❌ |
| 断言 D 只增一条记账 | **0**（`created=1 live=0`，本条无新增可认领对象） | ❌ |
| `calls` 值 | **`calls=1`（首调）／`calls=2`（第二驱动点）**；`calls=0` 仅出现在 D3 门未开的两条副本腿上 | ✅ 分开报 |
| 结论 | **`E2-ASSERTS-PARTIAL`**：槽 3 **被真正调用**（`rc=-100002`，可捕获的托管回调异常），但**未产出可认领的 `pfspara`** | ❌ **E2 的"引擎侧造型产出 `pfspara`"仍未成立** |
| 崩溃 | 第二驱动点后 `Unrecoverable system error.`＋`app_rc=134`（`failfast=1 unrec=2`）⇒ **副本调用不是无条件安全**，如实记 | 副本腿，不影响主链 |

**归因（现取，具名）**：槽 3 的托管实现 `PtsHost.SubtrackFormatParaFinite` 会走到 `ContainerParagraph.FormatParaFinite(...)`，该链回头要调 **native 的造型入口 `FsFormatSubtrackFinite`**（本波**未实现**；`t160` 的 ENFE 计数与 `t165` 的预测同族）⇒ 异常被 `catch` 成 `-100002` ⇒ `pfspara` 未被真造型产出。⇒ **新前置（具名）`PRECOND-NATIVE-FORMAT-ENTRY-MISSING`**：在 native 侧实现造型入口之前，`(b)` 的 `cParas` 与 `pfspara` 都拿不到。

## §3 ⑤ 三态 `NONE`／`ALLZERO` 与 gap 行的**触发手段（本件已给读数）**

本件新增两个**编译期注入开关**（只在副本，缺省 0）⇒ 两态**现取**：
| 态 | 开关 | 逐字读数 |
|---|---|---|
| **`NONE`**（未值化） | `-DWPF_PTS_FSP_PL_METH_NULL=1`（把源指针当 NULL） | `snap=0 gap=2`；`[FSPARAMETH-SNAP-GAP] rc=-10000 reason=null-methods entry=CreateInstalledObjectsInfo addr=(nil) state=NONE`；`[FSPARAMETH-D2] copy_state=NONE valid_copy=0 … v=NO-VALID-COPY` |
| **`ALLZERO`**（值化了但全 0） | `-DWPF_PTS_FSP_PL_METH_ALLZERO=1`（值化后清 0） | `state=ALLZERO nonzero=0 zero_cnt_win=17`；`v=NO-VALID-COPY` |
| **`VALUE`**（真值） | 正常 | `state=VALUE nonzero=16 zero_cnt_win=1 slotN_zero=15` ⇒ `SLOT-ORDER-OK` |
⇒ **三态判词互不相同**（照 `FSCBK` 判据面）＋ **gap 行现取在场**（`t167` 记的"机制在册未触发"本件已闭环）。

## §4 ① 逐件 sha16 ＋ `numstat`（主链逐字节不变）

| 件 | 开工 | 收尾 | 判 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `2ba175a41ff7855b`／316474 B | **`6d6f753105224f78`**／319005 B | **t168 专属 `numstat = 48 0`**（全部在 `#if` 内） |
| `bin/libwpfwin32.so` | `291ef08a33f9b6e4` | **`291ef08a33f9b6e4`** | **重建前后逐字节不变**（`MAIN_BYTE_IDENTICAL=yes`） |
| `bin/exports.txt` | 665 行 | **`15cb72a3abdadabb`**／**665 行** | 不变 |
| 主链回归腿 | — | `LEGSCOUNT requested=2 obtained=2 refused=0`；`fill=1078`、**`FSPARAMETH*`＝0**、**`edrive`＝0**、`failfast=0`；`alive=yes app_rc=143 magenta=0 colors=383` | ✅ 主链零影响 |
| 副本产物 | — | `7c504cccf05d3a62`（SNAP+DRIVE，D3 腿）／`8ba40fe4d09d8326`（SNAP）／`496906112043310c`（NONE）／`a406eee9693ebd84`（ALLZERO） | 副本专用 |

## §5 ⑥ `NOINFO` 与具名前置状态

| # | 项 | 状态 |
|---|---|---|
| 1 | **槽序/ABI（`NOINFO-FSIMETHODS-ABI`）** | **"槽序"部分已解除**：有效副本上**唯一零位＝1-based 第 15 槽**（`PtsCache.cs:617` 吻合）⇒ `SLOT-ORDER-OK`；**仍留 `NOINFO` 的只有"槽的语义映射"**（17 槽各自职责只能按托管声明推断） |
| 2 | **`THUNK-LIVENESS`** | 🔴 **由"判定"升为"读数"**：副本指针**可调用**（槽 1 `rc=0`、`sobjc=idobj+10` 逐值吻合）；但**槽 3 路径**在第二次驱动点后崩溃 ⇒ **"可调用"成立、"可安全驱动到底"不成立** |
| 3 | **`NOINFO-BUFFER-LIFETIME`** | `t167` 已升为读数（沿用） |
| 4 | **`E2`（引擎侧造型产出 `pfspara`）** | **仍未成立**（四断言 partial：`A=0 B=1 C=0 D=0`）⇒ 阻塞点具名 ⇒ **新前置 `PRECOND-NATIVE-FORMAT-ENTRY-MISSING`**（native 造型入口 `FsFormatSubtrackFinite` 系列未实现） |
| 5 | **`PRECOND-NO-ENGINE-DRIVER`** | **已解除**（驱动者＝本件的副本驱动格，且**真的发出并返回**） |
| 6 | 内容面（`pfspara` 内容、`cParas` 真值） | **`NOINFO`**（造型未成） |

## §6 口径 · 边界 · 纪律
- **口径**：①**`D2` 重判＝`SLOT-ORDER-OK`**（窗内值化副本上唯一零位是 1-based 第 15 槽，与 `PtsCache.cs:617` 吻合；双口径都打）；②**`THUNK-LIVENESS` 升为读数＝副本 thunk 可调用**（槽 1 实证）；③**`D3` 已做但 E2 未成立**（槽 3 返 `-100002`、`pfspara` 未被可认领地产出）；④三态与 gap 行**已触发并现取**。**不得**读成"排版打通／段落模型已成／`pfspara` 已由引擎产出"。
- **边界**：只改 `src/WpfGfx.Linux.Native/**`（**全部在 `#if` 内**）＋本载体；未碰 `tools/**`／`tests/**`／`docs/**`／`.cs`／哨兵／`cell=#1`（**有意未登记**）；`phase=degraded` 未翻；门变量缺省路径未变；重活全 `heavy-slot` 后台；未 `git add/commit/push`；跑后 `/tmp/.X11-unix/` 仅 `X0 X1`。
- **过程**：**先落最小载体**（21 行、预登记 R1–R9、末行自证 `3fba3dd9066134b7` 当场复算 MATCH）**再实现**（本件**未**重复 `t167` 的偏离）；实现期一处语法自伤（中文字符串内未转义引号）当场修。
`P1-FSIMETHODS-DRIVE 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ a6d7a4bc641f3e80（末行＝本行）`
