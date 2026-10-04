# P1-W85 · E2（**副本专用驱动格**）：驱动 `FSIMETHODS` 槽 3，让引擎侧造型产出 `pfspara`

> **本件是 `t165`（runner）的交付**：执行 `t164` 侦察件 `build/MilBridge/P1-format-frame-recon.md`（241 行／末行自证 `9440f52aaecb1304`）§8 的「最小可证伪设计」＋ 队长裁定（**副本驱动合法**；`PRECOND-NO-ENGINE-FORMAT-FRAME` 改判 **`PRECOND-NO-ENGINE-DRIVER`**）。
> **写域**：`src/WpfGfx.Linux.Native/**` ＋本载体。**未碰** `build/MilBridge/tools/**`／`tests/**`／`docs/**`／任何 `.cs`／哨兵／`HANDOFF-NEXT.md` 的 `cell=#1`（**有意未登记**）。
> **相位位 `degraded` 未动**；探针闸／强度旋钮／T3 门变量**缺省路径不变**；未跑整趟门禁；未 `git add/commit/push`。

## §0 开工现取（**跑前**）

| 项 | 现取 |
|---|---|
| `win32_pts.c` | **`6ac4272b031edbbc`**／298065 B／mtime `18:23:05`（与 `t164` 读到的**同一版**；HEAD＝`1ca5c28` 裁定五十一） |
| `libwpfwin32.so`／`exports.txt`／`pts-gap-decl.txt` | `291ef08a33f9b6e4`／`15cb72a3abdadabb`（665 行）／`3a923ffba99361cb` |
| 页几何（本侧真值） | `768×576`（`win32_pts.c:290`／`:352`／`:3052`，`t164` 现取转引） |
| 槽 1 契约 | `Pts.cs:2699-2705 ObjCreateContext(pfsclient, pfsc, pfscbkobj, uint ffi, int idobj, out pfssobjc)`；托管实现 `PtsHost.SubtrackCreateContext`（`PtsHost.cs:2644-2654`）**只算 `pfssobjc = idobj + 10`、入参一个都不读** |
| 槽 3 契约 | `Pts.cs:2708+ ObjFormatParaFinite(...)`；托管实现 `PtsHost.SubtrackFormatParaFinite`（`PtsHost.cs:2662+`）：读 `nmp`（`as ContainerParagraph`）、`pfsparaclient`（`as ContainerParaClient`）、`pmcsclientIn`（0 允许），其余转交 `ContainerParagraph.FormatParaFinite(...)` |
| 资源／显示位 | `MemAvailable 8993396 kB`／`SwapFree 1368316 kB`；`/tmp/.X11-unix/` 仅 `X0 X1` |

## §1 ④ⓐ 预登记：**作者性逐项表**（**跑前写死**；铁律＝「准入 ＝ 本侧是该值的作者」）

| 形参 | 族 | 本件用什么值 | 作者性声明（**依据**） | 若不能声明 ⇒ |
|---|---|---|---|---|
| `pfssobjc` | **E** | **调槽 1 现取**（`idobj` 由本侧自选） | 槽 1 是它的**唯一产生处**（`Pts.cs:2699-2705`；托管 `idobj+10`）⇒ **引擎调槽 1 即合法获得** | — |
| `idobj` | I | 本侧自选（本侧对象序号） | **引擎自选**（`PtsHost.cs:2644-2654` 只把它算进 `pfssobjc`）⇒ 本侧就是作者 | — |
| `ffi` | I | 本侧自选（格式化标志） | 槽 1 的入参、宿主不读 ⇒ **引擎自选** | — |
| `pfscbkobj` | P? | **NULL** | ⚠️ 宿主**不读**⇒「NULL 是否合法」**无仓内依据** ⇒ 记 **`NOINFO-FSCBKOBJ-CONTRACT`**，本件**只做实验、不断言** | 不断言 |
| `pfsgeom` | **E** | **本侧自定形状的缓冲区**（自定布局） | `t164`：它是**宿主回调的 IN 参数**、托管侧**只中转不解引用**（`PtsHost.cs:2705 → ContainerParagraph.cs:789 → 回引擎`）⇒ **引擎是作者**；⚠️ 仓内 `FSGEOMETRY` **0 命中** ⇒ 记 **`NOINFO-FSGEOMETRY-LAYOUT`**（自定后**与上游 ABI 不可比**） | 若实验显示托管侧真读它 ⇒ 立即停用并改判 |
| `fsrcToFill` | **E** | 本侧矩形（页几何 `768×576` 内的一个 rect） | **引擎自选**（要填的矩形）⇒ 本侧作者 | — |
| `fswdir` | I | 本侧自选（方向常量） | 引擎自选 | — |
| `fEmptyOk` / `fSuppressTopSpace` / `fskclearIn` / `iArea` / `fBreakInside` / `fBreakRecordFromPreviousPage` / `fsksuppresshardbreakbeforefirstparaIn` | I | 本侧自选常量 | 全是**引擎自己的格式化决定** | — |
| `nmp` | **H** | 本 run 由托管 `+136` 产出的段落句柄 | 托管产出（本侧只认领） | — |
| `pfsparaclient` | **H** | 本 run 由托管 `+176` 产出的客户端句柄 | 同上 | — |
| `pfsobjbrk` | S | **NULL** | **契约允许**（`Pts.cs:2711` 原文「IN: break record---**use if !NULL**」）⇒ **NULL 是契约取值，不是伪造** | — |
| `pmcsclientIn` | H | `0` | 托管实现显式允许 `IntPtr.Zero`（`if (pmcsclientIn != IntPtr.Zero)`） | — |
| `pftnrej` | ? | `0` | ⚠️ 仓内未见 NULL 合法性依据 ⇒ 与 `pfsgeom` 一样**只做实验、不断言**（若被 deref ⇒ 期望**可捕获**异常） | 不断言 |

## §2 ④ⓑ 预登记：**投毒 ＋ 四条断言**（照 `[DRIVE-PROBE3] out_pre_h1` 体例）

1. **全部 out 参数调前置毒**：`pfssobjc`、`fsfmtr`、`pfspara`、`pbrkrecpara`、`dvrUsed`、`fsbbox`、`pmcsclientOut`、`fskclearOut`、`dvrTopSpace`、`fBreakInsidePossible` 一律先写**哨兵毒值**并留痕。
2. 断言 A：`rc == 0`；断言 B：`pfspara` **被改写**（≠ 毒值）；断言 C：`pfspara` **身份可认领**（指针 ＝ **本侧对象字段地址**，与 `t162` 台账对得上）；断言 D：**只增一条**记账（`created` ＋1、`live` ＋1）。
3. `cParas` 语义**必须现取判定**（**不沿用**任何前跳结论：`+176` 非幂等／`+80` 懒建都不适用于本格）。
4. **④ 断页记录「内容诚实性」（`t163` 新格子）**：本侧页级断页记录今天＝**字段地址别名**（`*ppfsBRPageOut = &p->c_paras`）⇒ 本件**如实记它今天是什么（别名 or 内容）**；**不许**让"地址非零"冒充"内容正确"。

## §3 ④ⓒ 预登记：**反腿一对 ＋ 族匹配**（承裁定五十 (d)）

- 族定义：**H** 托管句柄／**E** 引擎自有（本侧对象字段地址）／**P** 伪指针（栈地址等）／**S** 结构指针／**I** 整数。
- **反腿 ①**：给 **NULL** ⇒ **必须被拒且留痕**；**反腿 ②**：给**栈地址**（"看似真实则伪"）⇒ **必须被拒且留痕**。
- **族匹配铁律**：驱动格**必须先做族分类**，**跨族值一律不喂**（`t162` 已用一次 `app_rc=134` 换来此教训）；判别器与被判别物**族必须匹配**。

## §4 预登记：**"得／不得"的裁决条件**（照 `t164` §8）

**得（E2 成立）**＝ ①–④ 全中（副本专用＋作者性逐项声明＋投毒四断言＋两条反腿都红）**且** `pfspara` 真被引擎产出、身份可认领。
**不得（合法终点）**＝ 任一断言不成立 ⇒ 记 **`PRECOND-NO-ENGINE-DRIVER`**（其现状句：本侧无真造型帧实物），并**逐条给出是哪一格断的**（例如"引擎被驱动了但它回头要调尚未实现的 native 造型入口"）。
**无论得／不得**：`pfspara` 的**内容**面与 `cParas` 的**真值**一律 `NOINFO`（本件只证机制）。

---

## §5 ① 副本专用 ＋「主链产物零影响」的**成对证据**

| 面 | 现取 | 判 |
|---|---|---|
| 主链 `.so` 重建前后 | `pre_authority=**291ef08a33f9b6e4**` → `post_authority=**291ef08a33f9b6e4**`（`MAIN_BYTE_IDENTICAL=yes`） | ✅ **逐字节不变**（比"nm 不变"更强） |
| `exports.txt` | 665 行 → **665 行**（逐行不变） | ✅ |
| `^Fs=` | **6**（未变） | ✅ |
| 主链回归腿（闸开 `N=16`，装置自分配 `:231`） | `LEGS_RUNNER=PASS obtained=2 refused=0`；`fill=1117`、`para=1117`、**`FSPARALIST-EDRIVE` 行 = 0**、`failfast=0`；`alive=yes app_rc=143 magenta=0 colors=383`、`managed_unavail=0 native_gap=0` | ✅ 主链**完全未受影响**，且**驱动格一行都没出现**（编译期 `#if` 未进主链） |
| 驱动格的存在形式 | 全部代码（含类型/函数/调用点）在 `#if WPF_PTS_FSP_PL_ENGINE_DRIVE` 内，**缺省 0**；三个副本产物：`a9968c81db88bc57`（正）／`b6ab4c925f64dddf`（NULL 反腿）／`83dd7ebefbcfaf28`（STACK 反腿） | ✅（照 `#if WPF_PTS_FSP_PL_SELFRECYCLE` 先例） |

## §6 ② 作者性逐项声明（**跑前写死**，见 §1；下表给"实际用了什么"的对照）

| 形参 | 实际用值 | 作者性 | 现取结果 |
|---|---|---|---|
| `pfssobjc` | 由**槽 1** 现取 | **E（引擎产出）** | ⚠️ **未取到**：驱动在**首个回调**处即 `SIGSEGV`（见 §7），`[FSPARALIST-EDRIVE] phase=slot1` 行未打出 |
| `idobj`／`ffi` | `7000+seq`／`0x1` | **I（本侧自选）** | 同上（未发出） |
| `pfscbkobj` | `NULL` | — | 具名 `NOINFO-FSCBKOBJ-CONTRACT`（宿主不读 ⇒ 无仓内依据 ⇒ 只做实验、不断言） |
| `pfsgeom` | 自定形状缓冲（64 B，本侧页几何 `768×576`） | **E（本侧即作者）** | 具名 `NOINFO-FSGEOMETRY-LAYOUT`（仓内 `FSGEOMETRY` 0 命中 ⇒ 与上游 ABI **不可比**） |
| `fsrcToFill` | `{0,0,768,576}` | **E（本侧矩形）** | 未发出 |
| `fswdir`／`fEmptyOk`／`fSuppressTopSpace`／`fskclearIn`／`iArea`／`fBreakInside`／`fBreakRecordFromPreviousPage`／`fsksuppress…` | 本侧自选常量（`0/1/0/0/0/0/0/0`） | **I（引擎自己的格式化决定）** | 未发出 |
| `nmp` | `drive_nmp=0x3`（族 **H**，本 run 托管 `+136` 产出） | **H** | 族检查通过（`fam_nmp=H`） |
| `pfsparaclient` | `fsp_pl_src_in=0x5`（族 **H**，本 run 托管 `+176` 产出） | **H** | 族检查通过（`fam_client=H`） |
| `pfsobjbrk` | `NULL` | **S** | **契约允许**（`Pts.cs:2711`「use if !NULL」）⇒ NULL 是契约取值、不是伪造 |
| `pmcsclientIn` | `0` | **H** | 托管实现显式允许 `IntPtr.Zero` |
| `pftnrej` | `0` | ? | 与 `pfsgeom` 同：**只做实验、不断言** |

## §7 ③ 投毒 ＋ 四条断言（**逐条读数**）＋ ④ 断页记录内容诚实性

**驱动格实际发出的两次调用迹（逐字）**
```
[FSPARALIST-EDRIVE] where=FsCreatePageBottomless methods=0x7ffd… fam_nmp=H fam_client=H      ← 族检查**通过**
（随后进程 SIGSEGV：run3.sh 报告「4134231 段错误」，app_rc=139，edrive=1、fill=0）
```
| 断言 | 读数 | 判 |
|---|---|---|
| **投毒** | 代码已对所有 out 参数置毒（`pfssobjc=0xA5A5…`、`pfspara=0xA5A5…`、`fsbbox` 20 B 全 `0xA5`、`fsfmtr/dvrUsed/dvrTopSpace/breakpos=-0x5A5A`）**并留痕 `pre_*`** | ✅ 机制在册（**读数为 `NOINFO`：调用未返回**） |
| **A `rc==0`** | **未取到**（进程在首个回调处崩溃） | **`NOINFO`** |
| **B `pfspara` 被改写** | **未取到** | **`NOINFO`** |
| **C 身份可认领**（＝本侧对象字段地址，与 `t162` 台账对上） | **未取到** | **`NOINFO`** |
| **D 只增一条记账** | **未取到**（`created` 在崩溃前后未变：`g_pts_sub_created` 只由自检贡献） | **`NOINFO`** |
| **`cParas` 现取判定** | 本侧自有对象的 `c_paras` 字段；`[FSPARALIST-PARA] … formatted=0` 逐趟在册 ⇒ **今天它是"未造型"的占位**，**不是"0 个孩子"的断言** | ✅ 现取判定在册（**不得**读成 0 个孩子） |
| **④ 断页记录内容诚实性** | **别名（address-alias）**：页级断页记录＝`(void *)&p->c_paras`（本对象内字段地址，可身份认领），**不承载任何"断页状态"内容** ⇒ `brk_content=alias(not content)` 逐趟打在本件行内 | ✅ 如实记（**不许**让"地址非零"冒充"内容正确"） |

## §8 ⑤ 反腿一对（＋族匹配声明）—— **两腿都红且留痕**

| 腿 | 产物 | 逐字读数 | 判 |
|---|---|---|---|
| **① NULL** | `b6ab4c925f64dddf` | `[FSPARALIST-EDRIVE] v=FAMILY-REFUSED reason=nmp-not-H nmp=(nil)(fam=N) client=0x5(fam=H) calls=0` | ✅ **拒发**（未进回调）、`app_rc=143` 未崩 |
| **② 栈地址（"看似真实则伪"）** | `83dd7ebefbcfaf28` | `v=FAMILY-REFUSED reason=nmp-not-H nmp=0x77069e7d3740(fam=X) client=0x5(fam=H) calls=0` | ✅ 同上 |
| **族匹配声明（裁定五十 (d)）** | — | 族定义 **H**（托管句柄）／**E**（引擎自有＝本侧对象字段地址）／**P**／**S**（结构指针）／**I**（整数）／**N**（NULL）；**驱动格先分类再喂**，`nmp`／`pfsparaclient` 非 **H** 一律拒发 | ✅ |

🔴 **本件两次自伤（如实入册，都已修）**：① 客户端来源首版取 `fsp_pl_cur`，而它在**探针时刻尚未赋值** ⇒ 首轮三腿全被 `reason=client-not-H` 拒（**该拒本身是真读数**）；改取探针在窗内保留的 `fsp_pl_src_in` 后 `fam_client=H` ✓。② 族集合首版漏了 `fsp_pl_src_in`／`fsp_pl_src_out` ⇒ `keep=0x5` 被误判成族 **X**（**误判本身也是真读数**）；补齐后 `fam_client=H` ✓。

## §9 ⑥ 红榜 `P1–P12`

| # | 本件现取 |
|---|---|
| `P1` `fserr` 非零当成功 | 无成功判词（"得"未成立） |
| `P2` 零句柄当活 | 反腿 `nmp=(nil)` 被**拒发**并留痕 |
| `P3` native 自造 | 逐项作者性表；不能声明作者性的**不用**；`NULL` 只用于契约允许处 |
| `P4` 回收后/复用后用 | 族检查按"本 run 产出的族 H"判，非 H 一律拒 |
| `P5` 槽被调用当链已通 | 明确记 `calls=0` 的拒发 vs `calls` 发生但**崩溃**；**未**把"发出了调用"当"链已通" |
| `P6` 伪值代替 T3 | 零伪值；栈地址只作**反腿**输入且被拒 |
| `P7` 主链 `FailFast` | 主链两样本 `failfast=0`；崩溃发生在**副本**（`app_rc=139`），如实记 |
| `P8` `cParas=0` 恒绿 | `formatted=0` 逐趟在册（本件未产生任何 `cParas` 判词） |
| `P9` 单样本/局部否定推广 | 单腿读数**已标注**；**不**把"槽表不可 deref"推广成"引擎侧全不可用" |
| `P10` 恒定绿判别器 | 未用 `+200`／`+56` |
| `P11` 跨代相减 | 每条带 `so16=291ef08a33f9b6e4`／`pf16=0b4b65f2c6c7ffd4` |
| `P12` `NOINFO` 写绿 | 四断言全记 `NOINFO`，**未**把任何一格写成绿 |

## §10 ⑦ `NOINFO` 清册 ＋ 具名前置状态（含 `PRECOND-NO-ENGINE-DRIVER` 是否落）

| # | 项 | 状态 |
|---|---|---|
| 1 | 四断言 A–D（投毒后读数） | **`NOINFO`**（调用未返回：首个回调处 `SIGSEGV`） |
| 2 | 槽 1 产出 `pfssobjc` | **`NOINFO`**（同上；**未**断言"槽 1 不可用"） |
| 3 | `pfsgeom` 布局 | **`NOINFO-FSGEOMETRY-LAYOUT`**（自定形状与上游 ABI 不可比） |
| 4 | `pfscbkobj` 契约 | **`NOINFO-FSCBKOBJ-CONTRACT`**（无仓内依据 ⇒ 不断言） |
| 5 | `pftnrej` 的 NULL 合法性 | **`NOINFO`**（同族，不断言） |
| 6 | `pfspara` 内容与 `cParas` 真值 | **`NOINFO`**（本件只证机制；机制未走通 ⇒ 更不涉内容） |
| **7** | **`PRECOND-NO-ENGINE-DRIVER`** | 🔴 **成立**（严格形态）—— 现状句成立：**本侧没有可用的驱动者**；本件现取把它**加强**为两条：**(i) `FSIMETHODS` 槽表只能"原样存、不许 deref"**（本件在副本上 deref 槽 1 指针即 **`SIGSEGV`／`app_rc=139`**，正是把"托管表当本地函数指针表"的代价）；**(ii) 引擎侧真正的造型驱动入口在本波不存在**（native 6 条真实现里无任何会调槽 3 的路径）。**⇒ 要真做 E2，须先有"表的合法可得形态"（如承 `fscbk` 那种**值拷贝快照**通道）或引擎侧驱动入口 —— 二者都属新前置，不在本波。** |

## §11 逐件 sha16 ＋ `numstat`

| 件 | 开工 | 收尾 | `numstat` |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | **`6ac4272b031edbbc`**／298065 B | **`e41df5d4c77610ac`**／307847 B | **`128 0`**（t165 专属；**全部新增都在 `#if` 内**） |
| `bin/libwpfwin32.so` | `291ef08a33f9b6e4` | **`291ef08a33f9b6e4`**（**逐字节不变**） | — |
| `bin/exports.txt` | 665 行 | **`15cb72a3abdadabb`**／**665 行**（不变） | — |
| `tools/pts-gap-decl.txt` | `3a923ffba99371cb` | **未改**（`so16`／`exports` 未变 ⇒ 无需改） | `0 0` |
| 副本产物 | — | `a9968c81db88bc57`（drive）／`b6ab4c925f64dddf`（NULL）／`83dd7ebefbcfaf28`（STACK） | — |
| 本载体 | （新建） | 见末行自证 | — |

**牙**：`PTSGAP=PASS`（`so16=291ef08a33f9b6e4 exports=665`）｜`REPORTID=PASS`。

## §12 口径 · 边界 · 纪律

- **口径**：本件**没有**得到"E2 成立"的判词：**驱动格能通过族检查并发出调用，但进程在首个回调处 `SIGSEGV` ⇒ 四断言无一取到 ⇒ `PRECOND-NO-ENGINE-DRIVER` 成立**。**不得**读成"引擎侧造型已通／`pfspara` 已由引擎产出／`cParas` 可得"。**得／不得的裁决条件**（§4）已按判据执行：任一断言不成立 ⇒ 判"不得"。
- **边界**：只改 `src/WpfGfx.Linux.Native/**`（且**全部在 `#if` 内**）＋本载体；未碰 `build/MilBridge/tools/**`／`tests/**`／`docs/**`／任何 `.cs`／哨兵／`cell=#1`（**有意未登记**）；`phase=degraded` 未翻；探针闸／T3 门变量缺省路径未变；重活全 `heavy-slot` 后台；未 `git add/commit/push`；跑后 `/tmp/.X11-unix/` 仅 `X0 X1`。
- **过程自陈**：**先落最小载体**（53 行、预登记作者性表＋投毒断言＋反腿＋裁决条件、末行自证 `d62136e510102617`）**再实现**；两处自伤（客户端来源／族集合漏项）如实入册。
`P1-ENGINE-DRIVE 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 091ef2cb3d5bc35f（末行＝本行）`
