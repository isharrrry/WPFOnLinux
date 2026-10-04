# P1-W54 · native 侧三段前置 —— 判词：**不能在本件内诚实完成**（「最小可辩护段落模型」＝**引擎驱动链本身**；附测量死角、规模读数与建议排期）

> **本件是 `t132`（runner）的交付**：先判「最小可辩护的段落模型」是什么、规模多大、能不能在本件内诚实完成；不能则落具名前置链并**保持现状**。
> **边界（硬）**：写域 ＝ `src/WpfGfx.Linux.Native/**`（含 `build-shim.sh` 的 `SRCS`／`bin/exports.txt`／`tools/pts-gap-decl.txt`）／本件／`build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` 行。**本件未改任何产品件**（判词即"保持现状"）：`win32_pts.c`／`.so`／`exports.txt`／`pts-gap-decl.txt` 的 sha16 **前后同值**（§8）。未改 `build/PresentationFramework.Linux/**`、上游、`build/MilBridge/tools/**`、装置本体、生成件、判据件、哨兵、`docs/ROUTES.md`、`samples/**`；**未动相位位**（队长裁定：`degraded→realized` 本轮不排）；未跑整趟门禁；未 `git add/commit/push`。
> **契约引用（不是证据）**：`build/MilBridge/P1-managed-handle-criteria.md`（`9abff3628f7188ea`）的 `C1–C12`／`P1–P9`／两极化由本件逐条执行；`build/MilBridge/P1-managed-handle-report.md`（`t131`，`812b0c760543f3a0`）作**前置链的归位依据**；队长裁定二十一～三十一作口径。**它们的读数一条未抄** —— 本件所有值**现取**。
> **读取时刻**：`ts=2026-09-29T13:38:34+08:00`（起点）→ 末取见 §4／§9。
> **落盘顺序**：**先落最小载体**（§0 ＋ §1 ＋ §2 ＋ §3 ＋ 自报口径行）⇒ 其后**原地追加**读数（§4 起）。

---

## §0 判词（写死）

**不能。** 理由不是"工作量大"，而是两条**现取的硬障**：

- **B1（结构 · 决定性的那条）**：所谓「最小可辩护的段落模型」**不是一个可以新增的数据结构，而是 native 必须自己驱动的一条托管回调链**。现取因果：**段句柄 `nms` 是在被调时才创建的** —— `Section.GetMainTextSegment(out IntPtr nmSegment)` 的原文是 `if (_mainTextSegment == null) { _mainTextSegment = new ContainerParagraph(Element, _structuralCache); } nmSegment = _mainTextSegment.Handle;`（`Section.cs:234-242`）⇒ **段对象、以及段落对象本身，都诞生在这条回调里**。往上：`nms` → `nmp`（`PtsHost.GetFirstPara` 现取先 `HandleToObject(nms) as ISegment` ＋ `PTS.ValidateHandle`）→ `pfsparaclient`（`PtsHost.CreateParaclient` → `para.CreateParaclient`）。三级**全部**由 native 发起才存在。而 **native 今天一次回调都不调**（`grep -c pfn win32_pts.c` ＝ **1**，且那一处是夹具占位字段 `:1481`），`c_paras` 是**硬编码 1**（`:248`／`:1771`）。⇒ 今天native 里**没有任何段落、任何段、任何 `nmp`** ⇒ 「track → 段落序」**连一条真数据都不存在**；`FsQueryTrackParaList` 拿到的 `cParas=1` 是**合成值**。⇒ 要建模型，**先得把 native 变成 PTS 引擎的文档走查驱动者**。
- **B2（本件内的死角）**：要发起**任意**回调，先要 `FSCBK` 各槽的**实测**偏移。托管侧把整张回调表**按值**塞在 `FSCONTEXTINFO` 里（现取声明序：`version(4) fsffi(4) drMinColumnBalancingStep(4) cInstalledObjects(4) pInstalledObjects(8) pfsclient(8) ptsPenaltyModule(8) fscbk …`；`FSCBK{cbkgen, cbktxt, cbkobj, cbkfig, cbkwrd}`）。**候选值我"算"得出来**（`fscbk` **+40**；`cbkgen` 内 `pfnGetNextSection` 第 3 槽 ⇒ +16 ⇒ 绝对 **+56**、`pfnGetFirstPara` 第 13 槽 ⇒ +96 ⇒ **+136**、`pfnCreateParaclient` 第 18 槽 ⇒ +136 ⇒ 绝对 **+176**），**但纪律明禁把算出来的当测量**；而**本件写域（native）没有任何仪器能测它**：native 夹具造的结构是**自证循环**（同一声明读写在两侧一起错）；`dladdr` 只能说明"像代码指针"、**分不出是哪个槽**；**试调错槽** ⇒ 参数表不匹配 ⇒ 崩；**用伪造 `nms`/`nmp` 调真槽** ⇒ 托管 `PtsContext.HandleToObject` 的三条断言 ⇒ **`Invariant.FailFast`（不可捕获，直接杀进程）**。⇒ **该偏移的测量仪器必须落在本件写域之外**（托管侧一行 canary 或等效）⇒ **必配同伴**。

⇒ 因此本件的正确动作 ＝ **保持现状**（native 侧维持"永不假成功 ＋ 具名留痕 ＋ 失败必清出参"；托管侧半件已就绪），把三段前置落成 **4 段链**（§3）＋**规模读数**（§2）＋**建议排期**（§3）。**不硬凑、不假成功、不交无法校验的值**。

---

## §1 「最小可辩护的段落模型」是什么 —— 五跳现取（为什么它不是数据结构而是驱动链）

| 跳 | 现取事实 | 现取位 |
|---|---|---|
| **H1 段句柄 `nms` 从哪来** | `Section.GetMainTextSegment(out IntPtr nmSegment)`：**"if null then `new ContainerParagraph(Element, _structuralCache)`"**，随后 `nmSegment = _mainTextSegment.Handle` ⇒ **段与段落对象都在回调里才诞生**；由 `pfnGetMainTextSegment` 槽承载（`Pts.cs:607`） | `Section.cs:234-242`；`PtsHost.cs:408` 的 `GetMainTextSegment` |
| **H2 段落句柄 `nmp` 从哪来** | `PtsHost.GetFirstPara(pfsclient, nms, out fSuccessful, out nmp)` → `ISegment segment = PtsContext.HandleToObject(nms) as ISegment; PTS.ValidateHandle((object)segment); segment.GetFirstPara(out fSuccessful, out nmp);` ⇒ **没有活 `nms` 就没有 `nmp`**；伪造 `nms` ⇒ `HandleToObject` 断言 ⇒ **FailFast** | `PtsHost.cs:586-611`；`PtsContext.cs:243-249` |
| **H3 客户端句柄 `pfsparaclient` 从哪来** | `PtsHost.CreateParaclient(pfsclient, nmp, out pfsparaclient)` → `BaseParagraph para = HandleToObject(nmp) as BaseParagraph; PTS.ValidateHandle(para); para.CreateParaclient(out pfsparaclient);` ⇒ 五处 `new *ParaClient` 在此发生、并把 `Handle` 交回 | `PtsHost.cs:724-748`；`ContainerParagraph.cs:424-433` |
| **H4 谁发起** | **只有 native**：托管侧全是被调者；而 native 源内 `pfn` **只命中 1 处**（`:1481` 夹具占位字段）⇒ **0 次调用**；`c_paras` 硬编码 `1`；"track" ＝ `&fsp->c_paras`（合成身份令牌） | `grep -c pfn` ⇒ 1；`win32_pts.c:194/248/1633/1726/1771` |
| **H5 结论** | 今天**没有**段／段落／`nmp` ⇒ 「track → 段落序」**无真数据可填**；`FsQueryTrackParaList` 的 `cParas=1` 是**合成值**，它拒填是对的（填就是假成功） | §0-B1 ＋ `t131` 的五跳 |

⇒ **判词（写死）**：把这个模型做成"再加一张表 + 一个回填"是**没有内容可填**的形态 —— 那正是"不许硬凑"要挡的东西。**它的内容只能来自 native 自己驱动的走查**。

---

## §2 规模读数（现取；本件核心产出之一）

| 项 | 现取值 | 取法 |
|---|---|---|
| 托管侧（PF 全树）调用的 `PTS.Fs*` 入口名（去重） | **56** | `grep -rhoE 'PTS\.Fs[A-Za-z0-9_]+'` |
| 本 shim **导出**的 `Fs*` | **6**：`FsCreatePageBottomless`／`FsCreatePageFinite`／`FsDestroyPage`／`FsQueryPageDetails`／`FsQueryTrackDetails`／`FsQueryTrackParaList` | `nm -D --defined-only` |
| **缺口** | **50**（`comm -23`；逐名见 §4-S3） | 同上 |
| `FSCBK` 回调槽总数 | **103**（`cbkgen` **32** ／ `cbktxt` **31** ／ `cbkobj` **8** ／ `cbkfig` **3** ／ `cbkwrd` **29**） | `awk` 计数 `Pts.cs` 内各 `struct` 的 `pfn` 行 |
| native 回调**调用**次数 | **0**（源内 `pfn` 命中 1 ＝夹具占位字段） | `grep -c pfn` |
| `c_paras` | **硬编码 1**（两处） | `:248`／`:1771` |
| LS（LineServices）面 | shim 导出 **8** 个 `Lo*`：`LoCreateContext`／`LoDestroyContext`／`LoSetDoc`／`LoSetBreaking`／`LoGetEscString`／`LoAcquirePenaltyModule`／`LoDisposePenaltyModule`／`LoGetPenaltyModuleInternalHandle`；托管侧（PresentationCore）引用 **23** 个 `Lo*` token（含 `LoGetEscStringImpl` 等内部助手）⇒ **缺口约 13**（`LoCreateLine`／`LoDisplayLine`／`LoEnumLine`／`LoCreateBreaks`／`LoAcquireBreakRecord`／`LoQueryLinePointPcp`／`LoQueryLineCpPpoint`／`LoDisposeLine`／`LoCreateParaBreakingSession`／`LoDisposeParaBreakingSession`／`LoRelievePenaltyResource`／`LoSetTabs`／`LoCloneBreakRecord`） | `nm`／`grep` |
| 缺口 50 名**今天**被走到吗 | **没有**（`ENFE=0` 现取）⇒ 缺口是**潜伏**的：驱动链每前进一步就撞上一批 | 现取 |

⇒ **一句话**：本件要的不是"加一列字段"，而是**把 native 变成 PTS 引擎的驱动者**（走查 `FSCBK` 里本链相关的槽 ＋ 补齐 50 个 `Fs*` 里本链真正需要的那些 ＋ LS 面缺口）。这是**一个波**，不是一个**步**。

---

## §3 具名前置链（**4 段**）＋ 同伴要求 ＋ 建议排期

> **`PRECOND-MEASURED-FSCBK-SLOT-OFFSETS`（本件**新增**·承重·**需要写域外的同伴**）**
> **要求**：对**真实**的 `FSCONTEXTINFO` **实测** ① `fscbk` 的偏移 ② `cbkgen` 内本链需要的每个槽的偏移（`pfnGetNextSection`／`pfnGetSectionProperties`／`pfnGetMainTextSegment`／`pfnGetFirstPara`／`pfnGetNextPara`／`pfnGetParaProperties`／`pfnCreateParaclient`／`pfnDestroyParaclient`），并用 `_Static_assert` **钉死**。
> **今天的读数**：**没有仪器**（§0-B2 的四条路全封）⇒ 候选值只能"算"（+40／+56／+136／+176），**不得当结论**。
> **可核证据**：一条**跨边界**信号 —— 托管侧写下的**已知值/已知序号**被 native 读回（或 `Marshal.OffsetOf` 的打印），且**错偏移必然不匹配**。
> **谁给**：**托管写域的同伴**（`build/PresentationFramework.Linux/**` 一行 canary 或等效形态）；或一个**新的、可自证的夹具形制**（今天不存在）。

> **`PRECOND-NATIVE-INVOKES-CREATEPARACLIENT`**（原样保留；**本件现取确认它不能单独做**：见 §1-H2/H3 —— 没有 `nmp` 就没有真槽可调，用伪造 `nmp` ⇒ FailFast）
> **`PRECOND-NATIVE-OWNS-A-PARAGRAPH-MODEL`**（＝**驱动链**本身；规模见 §2）
> **`PRECOND-NATIVE-CARRIES-PFSPARACLIENT`**（回填 `rgParaDesc[i].pfsparaclient` ＋ `*cParaDesc=真条数`；含 `FSPARADESCRIPTION` 八字段**实测**偏移 ＋ `_Static_assert` —— **同样缺仪器**，见 §7-5）
> **`PRECOND-MANAGED-PARACLIENT-LIVE`**（`t130` 立；`t131` 已归位为**效果**，本件**确认**该归位）

**建议排期（三步，一步一判、一次只一个写者）**
1. **小单 · 测量（本族真正的"钥匙"）**：托管侧 canary（`Marshal.OffsetOf<FSCONTEXTINFO>("fscbk")` ＋ `("cbkgen")` ＋ 目标槽序号／值）＋ native **只读**回读 ＋ 两极化（错偏移必不匹配）。产出：一张**实测偏移表**＋`_Static_assert` 钉死。
2. **中单 · 通道**：native 真调**无副作用**的取句柄回调（建议先 `pfnGetNextSection`／`pfnGetMainTextSegment`），带 `fserr` 检查、具名留痕、**FailFast 反腿**（伪造 `nms` 必 FailFast —— 反腿在**副本文档**上跑）。
3. **大单 · 驱动 ＋ 模型**：按 §1 的链做段落走查（`nms`→`nmp`）＋ 客户端生命周期（`CreateParaclient`／`DestroyParaclient`，注意 `_defaultHandlesCapacity=16`）＋ 回填；**同趟先点清"本链真正需要哪几个" `Fs*` 缺口名**，别铺开 50 个。

**缺什么同伴（写死）**
- ① **测量仪器**：托管侧 canary（**本件禁改该域** ⇒ 必须由队长另派或授权）。
- ② **驱动链本体**：依赖 LS 面缺口里与本链相关的部分（段落格式化要行格式化）。
- ③ **一条裁定**：段／轨的语义边界 —— 我们只有**一条合成 track**（`&fsp->c_paras`），`c_paras` 该由谁定、`FsQueryTrackDetails` 与 `FsQueryTrackParaList` 的条数一致性由谁保证。

---

## §4 读数（同一组；全部现取；读数批 `ts=2026-09-29T13:41:01` → `13:41:58 +0800`，收尾状态 `13:42:05 +0800`）

**C1 域与产物面** —— **不适用（本件改动集 ＝ 空；不是绿）**
- 现取 `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`e4a091395a6cf63c`**、`.so` ＝ **`a4bf2c47f8efb521`**、`bin/exports.txt` ＝ **`5293609825fc3d66`**、`tools/pts-gap-decl.txt` ＝ **`ccf56fca591f3b91`** ⇒ **前后同值**；`build/PresentationFramework.Linux/PtsCache.Linux.cs` ＝ `ae43cef7f9a84aa6`（同值）；`PF Release dll` ＝ **`2988f5154ecac5dd`**（`mtime 9月 29 02:38`，早于本件）。⇒ C1 的"改动真进了产物"**无对象**。
- 覆盖面两面现取：`fp_inputs()` **n＝234**，其中 **native 域 `win32_pts.c` 在面内（`in_fp=1`）**、`bin/exports.txt` **`in_fp=0`**、本载体 **`in_fp=0`**、`HANDOFF-NEXT.md` **`in_fp=0`**、M1 `PtsCache.Linux.cs` **`in_fp=0`**；`ARTIFACT_SRC_FP proj=PresentationFramework fp=611e5304aa3dcb6b n=1363`。
- ⇒ 明写：`win32_pts.c` **在覆盖面内** ⇒ 一旦改它，纪律 28 的触发条件**成立**（本件**没改**，故未触发）；"`inputs_fp` 不动"**不**被本件当任何证据。

**C2 字段级诚实性谓词** —— **`NOINFO`**（同 `t131`，本件形态未变）
- 正腿要求"表内 ≥1 live `BaseParaClient`"（今天**结构性为 0**：§1-H1/H4）；反腿要求**注入点**（写 `pfsparaclient` 的地方 ＝ native 的输出数组；本件**未实现**该写入，故无对象）⇒ 四条反腿一条都跑不了。
- 采信 `t131` 的**方法读数**（本件未复核其行号，按契约引用）：`PtsContext.IsValidHandle`（`PtsContext.cs:224-233`）**越界不 assert** ⇒ 四项谓词前两项**可在托管侧无 `FailFast` 求值**，后两项在 `IsValidHandle==true` 后调 `HandleToObject` ＋ `is BaseParaClient` ⇒ **不必新增上游 API**。
- **明写**：`pfsparaclient` 是**托管表索引，不是指针** ⇒ 该谓词**不是指针校验**。

**C3 `N2`（ENFE 归零 ＋ 不得被吞）** —— **成立（两格都现取）**
- ENFE 面：`enfe=0 epne=0 failfast=0 unrec=0`（`app_g1.log`）。
- 留痕面：`[FS_PAGE_GAP]` **1123** 行，`reason=` 唯一项 ＝ **`1123 paraclient-table-not-native`**；`[HC-UNHANDLED]` **1123**（一一对应）；首行 `[FS_PAGE_GAP] rc=-10000 reason=paraclient-table-not-native entry=FsQueryTrackParaList ctx=0x5a49fb9390c0 track=0x5a49f6bf3e68 cParas=1 owned=1 ok=0 gap=1`；末行 `ok=0 gap=1123`。
- **表述纪律**：只准读成「该入口不再缺符号、且失败可读」，**不许**读成"排版打通"。

**C4 `N1`（帧身份 ＋ 帧位移）** —— 形式成立，`ink` 已降级
- ① `fr_sha=ef3fd6765f18f51b` **∉** 空态参照集 `{1a76488aa4a790b3}`（守卫 `PTS_N1=INFO … in_empty_set=no`）；② `fr_ae_boot=15386 > 0`（两腿同值），现算 `AE(boot,k24)=15386 > 0`；③ **`ink` 无区分力（现取）**：`boot=480000`／`k23=480000`／`k24=480000` **三帧同值**（`colors` 386／383／383）⇒ 按 `N1③` **降级为必要不充分**。

**C5 `N3`（两页帧去重须 ＝ 2）** —— **红**
- 去重 **＝ 1**（`k23 = k24 = ef3fd6765f18f51b`）、`AE(k23,k24)=0`；两腿 `ns=` **不同**（`…RichTextBoxDemo`／`…FlowDocumentDemo`）⇒ **无"两页同貌例外"** ⇒ 判「没重绘」。**不许折绿。**

**C6 `N4`（内容身份）** —— **`NOINFO(无正身份载体)`**；`ns=` 不承担（`neptune` 命中 **0**）。

**C7 裁定二十三（不许静默 stub）** —— **成立（本趟 fresh 探针重跑）**
- ① 留痕面见 C3。
- ② **本件同趟探针**（车道内 `~/t123-runner/logs/t132/probe_t132.c` ＝ `t131` 探针源码，**本趟重新编译运行、fresh 进程**，仓内一字未改）：
  ```
  CELL1 fresh before ok=0 gap=0
  LEG0 track=NULL            rc=-10000 cParaDesc=0 argc_out_dirty_bytes=0   (rc_nonzero=1 cParaDesc_cleared=1 array_untouched=1)
  LEG1 track=bogus-stack-addr rc=-10000 cParaDesc=0 argc_out_dirty_bytes=0  (rc_nonzero=1 cParaDesc_cleared=1 array_untouched=1)
  CELL3 after  ok=0 gap=2
  VERDICT never_fake_success=1 ok_never_incremented=1
  ```
  stderr 两条具名行：`reason=null-track`（`gap=1`）／`reason=unknown-track-or-not-ours`（`gap=2`）。承重点：出参缓冲区**预填 `0xAA`** ⇒ "一个字节都没写"是**实测**。
- ③ 未改上游 `ValidateAndTrace`（本件未改任何产品件）。

**C8 native 不得制造可用值（T1–T3′ 成对反腿）** —— **`NOINFO`**
- 理由与 `t131` 同（无注入点；本件未实现写入）；本件**新增一条"为什么不许试"**：用伪造 `nms`/`nmp` 去**试调**真回调槽 ⇒ 托管 `PtsContext.HandleToObject` ⇒ **`Invariant.FailFast`（不可捕获）** ⇒ 不是可接受的测量手段（§0-B2）。
- 源码级分类（**明写：不是读数**）：T1 越界/指针/0 ⇒ `PtsContext.cs:247` `FailFast`；T2 空闲槽 ⇒ `:248` `FailFast`；T3 live 但错类型 ⇒ `as` 得 null ⇒ `PTS.ValidateHandle(null)` ⇒ 可捕获异常；T3′ 无校验站点 ⇒ **NRE**。

**C9 两页症状面** —— 达标，**单独不得当证据**
- 两腿 `alive=yes app_rc=143 magenta=0 colors=383 ink=480000`；`NAMES managed_unavail=0 err=- native_gap=0 native_err=-`；`FAILLINE … failfast=0 unrec=0`。**反过读写死**："净腿不崩＝假绿"本会话已有三例硬实证。

**C10 同趟与截图** —— 四值同 ＋ 三格齐；**如实记"非本件同趟重取"**
- `disk_so16=a4bf2c47f8efb521` ＝ 两腿 `DEV … shim=` ＝ `session.txt shim_sha16`；`disk_pf16=2988f5154ecac5dd` ＝ 两腿 `DEV … pf=` ＝ `session pf_sha16` ＝ **第三方口径** `sync-applocal.sh --check ~/w67-work/app`（`SYNC-APPLOCAL=PASS items=5 ok=5 drift=0`）。
- 截图三格：`shotstat(k24)=colors 383／magenta 0／ink 480000` ＝ `leg_24.env` **逐格相等**；`FRAME k=24 fr_sha=ef3fd6765f18f51b` ＝ `sha256sum k24.png` **实测值**（两腿同值）。
- **明写**：`legs=2/2` **不是**同趟证据。
- 🔴 **限制**：**本件未重跑腿**（本件无产品改动 ⇒ 在册证据与现盘同一代，四值逐格核过；覆盖 `evidence/**` 会让判据件引用的 sha256 失效）⇒ 这些读数是「**在册证据的现核**」，**不是本件同趟重取**。本件**唯一**同趟 fresh 读数是 C7 的探针。

**C11 导出/接口面** —— 达标
- `nm=594＝exports`（`equal=yes`）、`^Fs=6`、`FsQueryTrackParaList` nm 命中 **1**；本件**未增/删任何导出**。

**C12 回归面** —— 达标
- `failfast=0 unrec=0 ptsgap=0 unavail=0 fontfb=6`；`reason` 集合 ＝ {`paraclient-table-not-native`}；`^Fs=6` 不降；两腿 `alive=yes`／`app_rc=143`。

### §4-S 规模读数原始清单（逐条带命令与结果）

| # | 命令（现跑） | 结果 |
|---|---|---|
| S1 | `grep -rhoE 'PTS\.Fs[A-Za-z0-9_]+' upstream/…/PresentationFramework/ \| sed 's/^PTS\.//' \| sort -u \| wc -l` | **56** |
| S2 | `nm -D --defined-only …/libwpfwin32.so \| awk '{print $3}' \| grep '^Fs' \| sort -u \| wc -l` | **6**（`FsCreatePageBottomless`／`FsCreatePageFinite`／`FsDestroyPage`／`FsQueryPageDetails`／`FsQueryTrackDetails`／`FsQueryTrackParaList`） |
| S3 | `comm -23`（S1 − S2） | **50**，逐名：`FsClearUpdateInfoInPage` `FsClearUpdateInfoInSubpage` `FsClearUpdateInfoInSubtrack` `FsCompareSubpages` `FsCompareSubtrack` `FsCreateSubpageBottomless` `FsCreateSubpageFinite` `FsDestroyPageBreakRecord` `FsDestroySubpage` `FsDestroySubpageBreakRecord` `FsDestroySubtrack` `FsDestroySubtrackBreakRecord` `FsDuplicateSubpageBreakRecord` `FsDuplicateSubtrackBreakRecord` `FsFormatSubtrackBottomless` `FsFormatSubtrackFinite` `FsGetNumberSubpageFootnotes` `FsGetNumberSubtrackFootnotes` `FsGetSubpageColumnBalancingInfo` `FsGetSubpageFootnoteInfo` `FsGetSubtrackColumnBalancingInfo` `FsQueryAttachedObjectList` `FsQueryFigureObjectDetails` `FsQueryFloaterDetails` `FsQueryLineCompositeElementList` `FsQueryLineListComposite` `FsQueryLineListSingle` `FsQueryPageSectionList` `FsQuerySectionBasicColumnList` `FsQuerySectionDetails` `FsQuerySubpageBasicColumnList` `FsQuerySubpageDetails` `FsQuerySubtrackDetails` `FsQuerySubtrackParaList` `FsQueryTableObjCellList` `FsQueryTableObjDetails` `FsQueryTableObjRowDetails` `FsQueryTableObjRowList` `FsQueryTableObjTableProperDetails` `FsQueryTextDetails` `FsSynchronizeBottomlessSubtrack` `FsTransferDisplayInfoSubpage` `FsTransferDisplayInfoSubtrack` `FsTransformBbox` `FsTransformRectangle` `FsUpdateBottomlessPage` `FsUpdateBottomlessSubpage` `FsUpdateBottomlessSubtrack` `FsUpdateFinitePage` `FswdirToFlowDirection` |
| S4 | `awk '/internal struct FSCBKGEN/,/^        }/' Pts.cs \| grep -c pfn`（各 `struct` 同法） | `FSCBKGEN=32`／`FSCBKTXT=31`／`FSCBKOBJ=8`／`FSCBKFIG=3`／`FSCBKWRD=29` ⇒ **合计 103** |
| S5 | `grep -c 'pfn' src/WpfGfx.Linux.Native/src/win32_pts.c` ／ `grep -n pfn …` | **1**，且唯一命中 ＝ `:1481 void *pfn_assert_failed;`（夹具占位字段）⇒ **0 次回调调用** |
| S6 | `grep -n 'c_paras' src/…/win32_pts.c` | 赋值处 **2**：`:248 p->c_paras = 1;`／`:1771 p->c_paras = 1;` ⇒ **硬编码**；"track" ＝ `:1633 d->td_pfstrack = (void *)&pg->c_paras;` |
| S7 | `nm … \| grep -E '^Lo[A-Z][a-z]+[A-Z]'` ／ `grep -rhoE '\bLo[A-Z][a-z]+[A-Z][A-Za-z0-9_]*' upstream/…/PresentationCore/ \| sort -u \| wc -l` | shim 导出 **8**；托管侧引用 **23**（含 `LoGetEscStringImpl`）；缺口 ≈ **13** |
| S8 | `grep -n 'GetMainTextSegment' Section.cs` ＋ 上下文 | `:234` 方法／`:237 if (_mainTextSegment == null)`／`:239 new ContainerParagraph(...)`／`:242 nmSegment = _mainTextSegment.Handle` |
| S9 | `grep -n 'internal int GetFirstPara\|internal int CreateParaclient' PtsHost.cs` | `:586`（`GetFirstPara`，先 `HandleToObject(nms) as ISegment` ＋ `PTS.ValidateHandle`）／`:724`（`CreateParaclient`） |
| S10 | `awk 'NR>=602 && NR<=620' Pts.cs \| grep pfn` | `:604 pfnGetNextSection`／`:605 pfnGetSectionProperties`／`:607 pfnGetMainTextSegment`／`:614 pfnGetFirstPara`／`:615 pfnGetNextPara`／`:618 pfnGetParaProperties`／`:619 pfnCreateParaclient` |
| S11 | 缺口 50 名**今天是否被走到** | **否** —— `enfe=0`（现取）⇒ 缺口**潜伏** |

---

## §5 「假进度必红」P1–P9 逐条处置

| # | 假形式 | 本件处置 |
|---|---|---|
| **P1** | 只改计数/声明 | **不适用**：本件**未改任何件**（含声明件）；本件不以声明件为据 |
| **P2** | `return 0` 无副作用 | **已证伪（本趟现取）**：探针 `rc=-10000`、`ok` 恒 0、`gap 0→2` |
| **P3** | 吞 `ENFE` | **两格都给**（C3）：`ENFE=0` **且** 留痕 1123 行 ⇒ 未吞 |
| **P4** | 交伪句柄 | **无对象**（本件未实现写入）；机理分类见 C8（**已注明非读数**） |
| **P5** | 两页帧相同却报绿 | **如实判红**（C5） |
| **P6** | 拿 `ink>0` 当内容证据 | **降级**（C4③：三帧同值） |
| **P7** | 拿 `ns=` 当身份 | **不使用**（C6；`neptune=0`） |
| **P8** | 跨趟/跨代拼读数 | 本件给**载体＋`ts`＋代际**三元组；**不做跨代相减**（`1085`（`t129` 那一代）与 `1123`（现代）并列） |
| **P9** | 恒绿自检 | 本件未新增自检；**守卫有牙的佐证**：`PTS_GUARD=FAIL`／`PTSGAP=FAIL`（恒绿则必 PASS） |

---

## §6 两极化 a／b／c

| 腿 | 本件读数 | 判词 |
|---|---|---|
| **a**（受控"托管表未登记"） | 可按名过滤的留痕 **1123 × `reason=paraclient-table-not-native`**；进程不崩（`alive=yes app_rc=143`、`failfast=0`） | **成立**（今天**就是** a，且**本件给出了它的结构性成因**：native 从不调回调 ⇒ 表内无客户端） |
| **b**（受控"表已登记"） | —— | **`NOINFO(reason=§3 的 4 段前置全未满足；其中承重两段在本件写域内也做不了，见 §0-B1/B2)`** |
| **c**（交伪句柄，必红并按类点名） | —— | **`NOINFO(reason=无注入点)`**；分类见 C8（非读数） |

---

## §7 `NOINFO` 清册（逐条给"消掉需要什么"）

| # | 项 | 为什么取不到 | 消掉需要 |
|---|---|---|---|
| 1 | **`FSCBK` 各槽的实测偏移**（本件新增·**钥匙**） | **native 侧没有仪器**（夹具＝自证循环；`dladdr` 分不出槽；试调错槽 ＝ 崩；伪造 `nms`/`nmp` 调真槽 ＝ `FailFast` 不可捕获） | **托管写域的同伴**：一行 canary（`Marshal.OffsetOf<FSCONTEXTINFO>("fscbk")` ＋ 目标槽序号／值）或等效可自证夹具形制 ＋ 两极化（错偏移必不匹配） |
| 2 | **`pfnCreateParaclient` 被真调用的读数**（`fserr`／返回句柄非零次数） | 需要活 `nmp`（§1-H2），而活 `nmp` 又需要活 `nms`（§1-H1）⇒ 依赖驱动链 | §3 排期第 2 步（通道单） |
| 3 | **「track → 段落序」的真数据** | 今天没有段／段落／`nmp`（结构性） | §3 排期第 3 步（驱动＋模型单） |
| 4 | **`FSPARADESCRIPTION` 八字段的真语义** | 本仓只有托管侧声明（`Pts.cs:1500-1510`），无 native 侧规格 | 具名布局/语义声明，或"逐字段读回"成对读数 |
| 5 | **`FSPARADESCRIPTION` 八字段的实测偏移 ＋ `_Static_assert`** | **同 #1**：本件写域没有测量仪器（托管侧工件不能引用该 `internal` 类型；native 侧无跨边界信号） | 同 #1 的同伴形态；**禁**按字段类型"数出来"当结论 |
| 6 | **`c_paras` 应由谁定**（段／轨语义边界） | 需一条裁定（我们只有一条合成 track） | 队长裁定（§3 同伴 ③） |
| 7 | **`T3′`（无校验站点）本链上会不会被走到** | 本件未复核"全树 217 处／172 处"（**不引他人读数**） | 一趟带栈读数，或"错类型槽"反腿真跑 |
| 8 | **应用 `[HC-UNHANDLED]` 钩子的捕获语义** | 发射方在第三方应用、不在我方写域 | 读该件捕获分支原文，或我方自加计数器（本件只取到 `1123 ↔ 1123`） |
| 9 | **`N4` 正身份** | 今天无登记载体 | 登记一次已知良好渲染的帧 `sha256`（另派单） |
| 10 | **本件读数的"同趟"性质** | 未重跑腿（本件无产品改动） | 产品件有改动的那一趟同趟重取；今天的 `NOINFO` 已如实标注（"现核 ≠ 同趟重取"） |

---

## §8 纪律与边界自证

- **纪律 30（三格）**：本件**唯一自起进程** ＝ C7 探针（fresh）：① **进程新鲜度** ＝ fresh（调用前 `ok=0 gap=0`；未建 `PtsContext`／未建 `*ParaClient`／未调过销毁）；② **关键前置量** ＝ `ok=0`／`gap=0→2`（两个只读口现取）、**表内 live 客户端数 `NOINFO`**；③ **判词** ＝ `rc=-10000`、`cParaDesc=0`、`array_untouched=1`。其余成对读数取自另一趟在册证据 ⇒ 已在 C10 标注，**不当本件同趟**。
- **纪律 28（`cell=#1`）**：本件改的**覆盖面内件 ＝ 0**（现取：`win32_pts.c` 虽 **`in_fp=1`**（在面内）但**一字未改**；`exports.txt`／本载体／`HANDOFF-NEXT` 均 `in_fp=0`）⇒ 触发**未成立**；`bash ~/w153a/bin/infp.sh fp` ＝ `198563b4dcb4e1eb03e0bf688ee5eb87abf83e92ed023f240ae07b8208631b9e`（与上一格**逐位相同**）；仍按纪律**同趟追写一格**（纯 `>>`，如实记"0 件改动、指纹未动"）并复跑 `HANDOFF_MV`。
- **纪律 29（备份面 ≡ 改动面）**：本件**未改产品件** ⇒ 备份面为空；"未改"证据留档 ＝ 车道 `~/t123-runner/logs/t132/pre.txt`（起点 7 件 sha16 ＋ 资源读数）与 `post.txt`（收尾同 7 件，**前后逐位相同**）。无 `cp -p` 回拷、**未构建**（本件无构建需求）。
- **边界自证**：`git status --porcelain` 前后对比 —— 唯一新增 ＝ `?? build/MilBridge/P1-native-para-model-report.md`（＋本件在 `HANDOFF-NEXT.md` 追写一行，**写域内**、纯 `>>`）。**未**出现 `src/**`（含 native）、上游、`tools/**`、装置件、生成件、判据件、`docs/ROUTES.md`、`samples/**` 的任何改动。
- **资源线（跑前／跑后现取）**：`MemAvailable 3545432 → 3753744 kB`（**≫ 2000**）、`SwapFree 1395964 kB`（**≫ 512**）、`df -Pk /` 可用 **72501352 kB ≈ 69 GB**（**≫ 5 GB**）⇒ 未触停手线。**未走重活槽**（无构建、无腿、无整趟门禁；唯一编译是车道内 46 行探针 `gcc -O0`）。
- **显示位／进程**：本件**未占任何显示位**；`/tmp/.X11-unix/` 现取仅 `X0`／`X1`（非本件所起）；`ps` 现取无 `Xvfb`／`xfwm4`／`HandyGameControl` 残留。
- **相位位**：**未动**（按队长裁定：翻转前置 ＝ 与 `N1`/`N3`/`N4` 同趟，今天 `N3` 红 ⇒ 不满足）。

---

## §9 收尾牙（受影响者；逐个捕获 `rc`）

| 牙 | `rc` | 现取读数 |
|---|---|---|
| `handoff-machine-values-check.sh` | **0** | `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none` |
| `pipefail-sigpipe-check.sh` | **0** | `PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=114 sites=105 hit=0 low=10 diag=5 safe=90 runs=12` |
| `report-id-domain-check.sh` | **0** | `REPORTID=PASS files=262 ids=2204 declared=224 glob=build/MilBridge/*report*.md`（**261→262**：本件载体入册） |
| `sentinel-spec-check.sh` | **0** | `SSC=PASS lines=13 keys=13 cmp=IDENTICAL`（`SSC_VALUE=PASS key=WAVE v=w80-freeze`） |
| `static-jaws-check.sh` | **0** | `STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62`（自带边界：射程 ＝ 已接线的裸静态牙，**不等于**整趟门禁绿） |
| `pts-gap-count-check.sh` | **1** | `PTSGAP=FAIL tool=90 dead=11 artifact=1 ops=78 impl=81 so16=a4bf2c47f8efb521 exports=594`；**唯一残留** `SITE-DRIFT docs/ROUTES.md impl want=81 got=87`（＝ `t123`/`t127`/`t129` 同一条；**本件未改牙、未改该行**） |
| `pts-pages-guard.sh --legs <证据目录>` | **1** | `PTS_G10_NAME=PASS observed=FsQueryTrackParaList`；`PTS_N1=INFO`（两腿，`phase=degraded`）；`PTS_ENFE=INFO total=0`；`PTS_GUARD=FAIL`（degraded 期既有红，**非本件引入**） |
| `sync-applocal.sh --check ~/w67-work/app` | **0** | `SYNC-APPLOCAL=PASS target=/home/links-dev/w67-work/app items=5 ok=5 synced=0 created=0 drift=0 noauth=0 same=0` |

**说明**：上表**全部只读现跑**（本件未改 `build/MilBridge/tools/**`、未改装置件、未改哨兵）。
`P1-NATIVE-PARA-MODEL 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ dc80a3cb22c9d646（末行＝本行）`
