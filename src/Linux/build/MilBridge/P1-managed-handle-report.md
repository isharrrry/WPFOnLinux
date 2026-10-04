# P1-W53 · 托管侧「让 `ParaListFromTrack` 拿到真段落客户端句柄」—— 判词：**不能在本件写域内被诚实满足**（三段具名前置 ＋ 同组读数）

> **本件是 `t131`（runner）的交付**：先判「能不能**在不实现整条托管排版链的前提下**被诚实满足」，再把判词、具名前置与读数落盘。
> **边界（硬）**：写域 ＝ `build/PresentationFramework.Linux/**`（M1／M2）／本件／`build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` 行。**本件未改任何产品件**（判词本身即"保持现状"）；未改 `src/WpfGfx.Linux.Native/**`、上游 `upstream/**`、`build/MilBridge/tools/**`、装置本体、生成件、判据件、哨兵、`docs/ROUTES.md`、`samples/**`；未跑整趟门禁；未 `git add/commit/push`。
> **契约引用（不是证据）**：`build/MilBridge/P1-managed-handle-criteria.md`（`9abff3628f7188ea`，387 行）的 `C1–C12`／`P1–P9`／两极化 `a/b/c` 由本件**逐条执行**；队长裁定二十一～三十（`build/MilBridge/P1-ptsname-result.md`）作口径引用。**它们的读数一条未抄**——本件所有值**现取**。
> **读取时刻**：`ts=2026-09-29T13:30:31+08:00`（起点）→ 末取见 §4 各格。
> **落盘顺序（照本会话成功做法）**：**先落最小载体**（本节 ＋ §1 ＋ §2 ＋ 自报口径行）⇒ 其后**原地追加**读数（§3 起）。

---

## §0 判词（写死）

**不能诚实满足。** 而且不止「托管排版链未打通」——**承重的障碍在 native 侧**，我现取的链条是三跳：

1. **值的唯一合法产地 ＝ 托管回调**：`FSPARADESCRIPTION.pfsparaclient` 的可用值只能来自 `PtsContext.CreateHandle`（句柄＝**该上下文表内**的槽号），而它只被 `UnmanagedHandle` 的基类构造调用 ⇒ 只被 `new *ParaClient(...)` 触发 ⇒ 只在 `*Paragraph.CreateParaclient(...)` 里发生。
2. **值的唯一"交车"处 ＝ native 的回调表槽 `pfnCreateParaclient`**：托管侧把它装配在 `PtsCache.Linux.cs:620`，实现是 `PtsHost.CreateParaclient`（`PtsHost.cs:724`），它 `para.CreateParaclient(out pfsparaclient)`（`:734`）把真句柄**交给 native**。⇒ 句柄是**托管产出、native 持有**。
3. **值的唯一"装车"处 ＝ native 自己的簿记**，而 **native 今天既不发车、也没有车厢**：全 `src/WpfGfx.Linux.Native/src/**` 里 `pfnCreate` **命中 0**（回调表地址只在 `:1480` 作为**占位字段**存下，`:618` 的注释亦明说它是占位，"保证前面各指针的偏移"）；而它的"track"**不是真 track**，只是本仓页对象里 `c_paras` 那个 `int` 字段的**地址**（`wpf_pts_track_owned()`，`:1699`：`(const void *)&g_pts_fsp_live[i]->c_paras == track`）⇒ **native 没有段落模型**，也就**没有任何字段**能承载 `pfsparaclient`。

⇒ 合起来：**`FsQueryTrackParaList` 的输出数组只有 native 能写，而要写的值必须靠 native 先把托管回调叫起来并记在段落上——两步都在 native 写域（本件禁改），且第二步在 native 现有模型里"无字段可记"。** ⇒ **托管侧（M1／M2）单独做不到**：不是"难"，是**车不在托管侧**。

⇒ 因此本件的正确动作 ＝ **保持现状**：native 侧维持"**永不假成功**"（`win32_pts.c:1802` 恒返 `WPF_PTS_ERR_NOT_IMPLEMENTED`、出参清 0、数组不写、具名留痕），托管侧**不动**（它该配的都配齐了：`pfnCreateParaclient` 已装配、五处 `CreateParaclient` 已把 `paraClient.Handle` 交回）。**现状 ＝ 诚实失败、不欠账**；本件**不硬凑、不假成功、不交出无法校验的值**。

---

## §1 「钥匙 vs 其后」——五跳现取链（每跳都带现取位）

| 跳 | 现取事实 | 现取位（我自己读的原文） |
|---|---|---|
| **H1** 消费面：谁要用这个句柄 | `PtsHelper.ParaListFromTrack` **只**经 `PTS.FsQueryTrackParaList(...)` 填数组；返回后由调用方（`ContainerParaClient.cs:289/:342/:386` 等）用 `HandleToObject(arrayParaDesc[i].pfsparaclient) as BaseParaClient` 反查 | `PtsHelper.cs:604-620`（调用在 `:614`）；`ContainerParaClient.cs:289/:342/:386` |
| **H2** 写入面：谁**唯一**能写这个字段 | **托管侧全树零处写** `.pfsparaclient`（`grep -rn '\.pfsparaclient *=[^=]' …` **命中 0**）⇒ 唯一写入者 ＝ native `FsQueryTrackParaList`；而它今天**一个字节都不写**（源内 `rgParaDesc` 只出现在注释 `:1790`、签名 `:1802`、参数校验 `:1811`，函数体恒返非 0） | `src/WpfGfx.Linux.Native/src/win32_pts.c:1802-1821` |
| **H3** 产地：合法值从哪来 | 句柄 ＝ `PtsContext.CreateHandle(obj)` 的返回（**该上下文表内的槽号**）⇒ 只有 `new *ParaClient(...)` 会触发（`BaseParaClient : UnmanagedHandle`，基类构造登记）⇒ 只有 `*Paragraph.CreateParaclient` 会触发 | `PtsContext.cs:175-196`；`UnmanagedHandle.cs:25-29`；`BaseParaClient.cs:21/:34`；`ContainerParagraph.cs:424/:431-432` |
| **H4** 交车：谁把值给 native | 托管**已装配**回调槽：`contextInfo.fscbk.cbkgen.pfnCreateParaclient = new PTS.CreateParaclient(ptsHost.CreateParaclient)`；实现 `PtsHost.CreateParaclient(IntPtr pfsclient, IntPtr nmp, out IntPtr pfsparaclient)` → `para.CreateParaclient(out pfsparaclient)` | `build/PresentationFramework.Linux/PtsCache.Linux.cs:620`；`PtsHost.cs:724`／`:734`；委托声明 `Pts.cs:2128`，槽位 `Pts.cs:619` |
| **H5** 发车与车厢：native 侧现状 | ① **不发车**：`src/WpfGfx.Linux.Native/src/**` 里 `pfnCreate` **命中 0**；`fscbk` 只在 `:618`（注释）与 `:1480`（**占位字段**，注释写明"真身是委托（8 B）⇒ 保证前面各指针的偏移"）出现。② **无车厢**：native 的 "track"＝`&g_pts_fsp_live[i]->c_paras`（`wpf_pts_track_owned()`，`:1699`），**没有段落模型**、没有承载 `pfsparaclient` 的字段（`grep -n 'paraclient' …` 在 native 源内只命中 `:1791` 的注释） | `win32_pts.c:1699-1706`／`:1480`／`:618`；`grep` 现取 |

**⇒ 判词**：**钥匙**（挡住后续的那一步）＝ **H4/H5 的接头**，而它的两端**都在 native 写域**：native 必须先 **调起** `pfnCreateParaclient`（发车），再**按段落记下**返回的句柄（装车）。**其后要撞的**＝ `FsQueryTrackParaList` 按 track 内段落序回填 `rgParaDesc[i].pfsparaclient` ＋ `*cParaDesc ＝ 真条数`（并在失败时清出参、留痕）。

**与 `t130` 的一处更正（如实记）**：`t130` 把该族的"谁给"写成「**托管排版链**」（其 §2.2）。按本件现取，**这不完整**：托管侧那半**已经就绪**（H4 已装配、五处已交回），**链条根本起不来的原因是 native 从不调那个回调**（H5①），且 native **没有承载位置**（H5②）。⇒ 具名前置须**拆成三段**，**承重两段属 native**（§2）。

---

## §2 具名前置（写成可判形态；本件不改任何产品件）

> **`PRECOND-NATIVE-INVOKES-CREATEPARACLIENT`（承重·native 写域）**
> 要求：native 在需要某段落的客户端时**真的调用**回调槽 `pfnCreateParaclient(pfsclient, nmp, out pfsparaclient)`（装配位 `PtsCache.Linux.cs:620`；实现 `PtsHost.cs:724`），并检查返回的 `fserr`。
> 今天的读数：**从不调用**（native 源内 `pfnCreate` 命中 0）。
> **可核证据**：native 侧一条**具名留痕**（"调用次数／成功次数／返回句柄非零次数"），同趟给出。
> **谁给**：native（`src/WpfGfx.Linux.Native/**`）。

> **`PRECOND-NATIVE-OWNS-A-PARAGRAPH-MODEL`（承重·native 写域）**
> 要求：native 为 track 内的**每个段落**建立条目，并把该段落收到的 `pfsparaclient` 记在条目上。
> 今天的读数：**没有段落模型** —— `c_paras` 只是一个 `int`，"track" 是它的地址（`:1699`）；`paraclient` 在 native 源内**无字段**。
> **可核证据**：`FsQueryTrackDetails` 的 `cParas` 与实际回填条数**同源**（同一批条目），同趟给出。
> **谁给**：native。

> **`PRECOND-NATIVE-CARRIES-PFSPARACLIENT`（承重·native 写域）**
> 要求：`FsQueryTrackParaList` 成功路径**按段落序**把记下的句柄写进 `rgParaDesc[i].pfsparaclient`，并 `*cParaDesc ＝ 真条数`；失败路径**清出参 ＋ 留痕**（今天的形态，不许退化）。
> 今天的读数：**永不写数组**（H2）。
> **可核证据**：字段级诚实性谓词（`t130` §C2 四项，**由表主判**）正腿 `usable=1`／反腿 `usable=0` **按项点名**。
> **谁给**：native。

> **`PRECOND-MANAGED-PARACLIENT-LIVE`（`t130` 立；本件把它**归位为前两段的"效果"**）**
> 要求：同一个 `PtsContext` 的 `_unmanagedHandles` 里存在 ≥1 个 live `BaseParaClient`。
> 今天的读数：**结构性为 0** —— 五处 `new *ParaClient` 的**唯一**触发链是 `PtsHost.CreateParaclient`（H4），而它的**唯一**引用是那条回调装配（全树现取：`Pts.cs:619/:2128` ＋ `PtsHost.cs:724` ＋ `PtsCache.Linux.cs:620`），**没有第二个调用者**；native **从不调用**该槽（H5①）⇒ 该构造链今天**不可能**被执行。
> **谁给**：它**不是**独立动作，而是上两段的**后果**（native 调起回调 ⇒ 托管构造 ⇒ 句柄入表）。
> ⚠️ 进程内实测（"表里到底几个 live 客户端"）本件**取不到**（见 §7-2）⇒ 记为 `NOINFO`，并**不以静态论证冒充实测**。

**托管侧半件：已就绪、无需改**（本件因此**不改 M1／M2**）：
- 回调装配在位（`PtsCache.Linux.cs:620`／`:622`），且**与上游同一集合**（现取：上游 `PtsCache.cs` 与 `PtsCache.Linux.cs` 的 `pfn* =` 赋值名集合**逐名相同**，各 **146** 名，`comm -3` 差集 **0**）。
- 五处 `CreateParaclient` 都把句柄交回（`ContainerParagraph.cs:431-432` 原文：`ContainerParaClient paraClient = new ContainerParaClient(this); paraClientHandle = paraClient.Handle;`）。

---

## §3 为什么 M1／M2（托管侧）单独做不到 —— 三条候选路逐条封死（现取）

**路①「托管侧自己造一个值」** —— 封死（两条）：
- **(a) 造出来必红**：`PtsContext.HandleToObject`（`PtsContext.cs:243-249`）把值当**表索引**：`:247` 断言 `handleLong > 0 && handleLong < _unmanagedHandles.Length`、`:248` 断言槽 live ⇒ 交指针／交 `0` ⇒ **`Invariant.FailFast`（不可捕获）**；交"域内 live 但类型不对"的槽 ⇒ `as` 得 `null` ⇒ 下游 `PTS.ValidateHandle(null)` 抛**可捕获**异常，而无校验站点 ⇒ **NRE**。
- **(b) 到不了数组**：`rgParaDesc` 是 `ParaListFromTrack` 内的 `fixed` 局部指针，**只有 native 能写**（H2）⇒ 托管侧就算"手里有值"也无处落笔。

**路②「托管侧先把句柄备好、请 native 回填」** —— 封死：native 今天**不读**任何"托管侧准备好的句柄"来源（它连回调表都**一次不调**：H5①，`pfnCreate` 命中 0）；本件**禁改** `src/WpfGfx.Linux.Native/**` ⇒ 没有可用接口。

**路③「用 M2 新件顶掉上游 `Pts.cs`／`PtsHelper.cs`／`PtsContext.cs`，在托管侧重写这条链」** —— 封死（**语义层**，不是越域层）：这三件现在都是**直编的上游件**（现取 `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj:321` `Pts.cs`／`:323` `PtsContext.cs`；全 csproj 里**只有** `PtsCache.cs` 在 `:1516` 被 `Remove` 换成本移植件）⇒ M2 技术上**能**顶掉它们。**但顶掉也改不动语义**：要填进 `rgParaDesc[i]` 的必须是**该 track 内第 i 段**对应的那个客户端句柄，而
- 托管侧的表只记「**槽 ↔ 对象**」（`PtsContext.cs:47` 分配／`:558` 字段／`:641-648` `HandleIndex{Index,Obj}`），**没有**「轨道 → 段落序」的映射（现取：`MS/Internal/PtsHost/` 内**无**以 `IntPtr` 为键的字典；`pfstrack` 在托管侧共 **73** 处，**全部**是"从 native 填过的结构里取出、再原样传回 native"的不透明 `IntPtr`）；
- **「轨道内第 i 段是谁」只存在于 native**（PTS 引擎按 `nmp` 名把段落编入轨道；托管侧的 `GetFirstPara`／`GetNextPara` 只提供**名字**，不持有轨道）。

⇒ **托管侧无从查出该填哪个值** —— 路③在**语义上**不通。**⇒ 三条候选路全封死：托管侧单独做不到**，本件写域（M1／M2）**够不着**承重链条的任何一环。

---

## §4 读数（逐条 C1–C12；全部现取；读数批 `ts=2026-09-29T13:30:31` → `13:32:53 +0800`，收尾状态 `13:36:22 +0800`）

**C1 域与产物面** —— **不适用（本件无产品改动；不是绿）**
- `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` ＝ **`2988f5154ecac5dd`**（`mtime 9月 29 02:38`，**早于本件 ts**），本件**前后同值**；Debug 件 `b9a4f3a0e48e688d`（同未动）。⇒ C1 的"改动真进了产物"**无对象**，如实记「**本件改动集 ＝ 空**」。
- 覆盖面两面现取：`fp_inputs()` **n＝234**；其中 M1 `build/PresentationFramework.Linux/PtsCache.Linux.cs` **in_fp=0**、本载体 **in_fp=0**、`build/MilBridge/HANDOFF-NEXT.md` **in_fp=0**；`ARTIFACT_SRC_FP proj=PresentationFramework fp=611e5304aa3dcb6b n=1363 peer_fp=06a6823a65ccb9b7 peer_n=9`。
- ⇒ **明写（判据 C1 已判死的通道）**：本件**不**用"`inputs_fp` 不动"当任何证据；"改真进了产物"这条**本件无读数**。
- UTF-16 双查（.NET 元数据串）**不适用**：无改动 ⇒ 无串可查 ⇒ 记 `NOINFO(reason=本件无改动)`。

**C2 字段级诚实性谓词** —— **`NOINFO`**（正反腿**都跑不了**）
- 正腿要求「同一 `PtsContext` 表内 ≥1 live `BaseParaClient`」＝ §2 末项（今天**结构性为 0**）；反腿要求一个**注入点** ＝ "写 `pfsparaclient` 的地方" ＝ native 的输出数组（本件**禁改**；且托管侧**根本没有**写这个字段的语句，现取命中 0）⇒ 四条反腿**一条都跑不了**。
- **消掉需要**：先满足 §2 两段承重前置（**native 写域**），再按该谓词给成对读数。
- ⚠️ **本件补一条"方法读数"（现取、可用、非结论）**：托管侧**已存在全域安全**的判定基础 —— `PtsContext.IsValidHandle(IntPtr)`（`PtsContext.cs:224-233`）**对越界不 assert**（`:228 if (handleLong < 0 || handleLong >= _unmanagedHandles.Length) return false;`），in-range 时返回 `_unmanagedHandles[h].IsHandle()`（`IsHandle()` ＝ `Obj != null && Index == 0`，`:645-648`）⇒ **四项谓词的前两项可在托管侧无 `FailFast` 地求值**；后两项在 `IsValidHandle == true` 之后调 `HandleToObject`（此时 `:247/:248` 两条断言必过）＋ `is BaseParaClient`。⇒ 这**修正** `t130` §C2 的一句可行性口径：该谓词**能**在托管侧实现，**且不必新增上游 API**（两者同为 PresentationFramework 程序集内的 `internal`）。
  （⚠️ 边界：`v=0` 时 `IsValidHandle` 只看 `_unmanagedHandles[0].IsHandle()`；现取**源码**：槽 0 是空闲头、`Obj` 恒 `null` ⇒ 结果为 `false`。**这是源码结论，不是实测**，故不写进"四项谓词已可求值"之外的任何结论。）

**C3 `N2`（ENFE 归零 ＋ 不得被吞）** —— **成立（两格都现取）**
- ENFE 面：`enfe=0 epne=0 failfast=0 unrec=0`（`app_g1.log`）。
- 留痕面：`[FS_PAGE_GAP]` **1123** 行，`reason=` 直方图唯一项 ＝ **`1123 paraclient-table-not-native`**；`[HC-UNHANDLED]` **1123**（一一对应）；首行原样：`[FS_PAGE_GAP] rc=-10000 reason=paraclient-table-not-native entry=FsQueryTrackParaList ctx=0x5a49fb9390c0 track=0x5a49f6bf3e68 cParas=1 owned=1 ok=0 gap=1`；末行 `ok=0 gap=1123`。
- **表述纪律**：本条**只准**读成「该入口不再缺符号、且失败可读」，**不许**读成"排版打通"。

**C4 `N1`（帧身份 ＋ 帧位移）** —— 形式成立，但 `ink` 已降级
- ① 帧身份：`fr_sha=ef3fd6765f18f51b` **∉** 空态参照集 `{1a76488aa4a790b3}`（守卫现跑：`PTS_N1=INFO k=24 file=k24.png fr_sha=ef3fd6765f18f51b in_empty_set=no fr_ae_boot=15386 set={1a76488aa4a790b3} phase=degraded`，k=23 同）。
- ② 帧位移：`fr_ae_boot=15386 > 0`（两腿同值）；现算 `AE(boot,k24)=15386`。
- ③ **`ink` 无区分力（现取）**：`boot=480000`／`k23=480000`／`k24=480000` **三帧同值**（`colors`：boot 386／k23 383／k24 383）⇒ 按 `N1③` **降级为"必要不充分"**，不得单独支撑任何结论。

**C5 `N3`（两页帧去重须 ＝ 2）** —— **红**
- 去重计数 **＝ 1**（`k23 = k24 = ef3fd6765f18f51b`）、`AE(k23,k24)=0`、两腿 `ae`：k23 `0`／k24 `15386`。
- 两腿 `ns=` **不同**（`HandyControlDemo.UserControl.RichTextBoxDemo`／`…FlowDocumentDemo`）⇒ **不满足"两页同貌例外"** ⇒ 判「**没重绘**」（红）。**本条不许折绿。**

**C6 `N4`（内容身份）** —— **`NOINFO(无正身份载体)`**
- 负身份用 C4① 的帧身份；正身份（该页专属期望指纹）**今天无载体** ⇒ `NOINFO`。
- `ns=` **不承担**：现取两条反例同真（`ns=…FlowDocumentDemo` 与"回退画面"同时成立）；`grep -ci neptune app_g1.log` ＝ **0**。

**C7 裁定二十三（不许静默 stub：返非 0 必留痕、失败必清出参）** —— **成立（两格都现取）**
- ① 失败必留痕且**按 `reason=` 可分类**：见 C3 留痕面（1123 行、唯一原因）。
- ② 失败必清出参、数组不写半成品 —— **本件同趟探针**（车道内 `~/t123-runner/logs/t131/probe_t131.c`，**fresh 进程**，仓内一字未改）：
  ```
  CELL1 fresh before ok=0 gap=0
  LEG0 track=NULL           rc=-10000 cParaDesc=0 argc_out_dirty_bytes=0
    ASSERT rc_nonzero=1 cParaDesc_cleared=1 array_untouched=1
  LEG1 track=bogus-stack-addr rc=-10000 cParaDesc=0 argc_out_dirty_bytes=0
    ASSERT rc_nonzero=1 cParaDesc_cleared=1 array_untouched=1
  CELL3 after ok=0 gap=2
  VERDICT never_fake_success=1 ok_never_incremented=1
  ```
  stderr 两条具名行：`reason=null-track`（`gap=1`）／`reason=unknown-track-or-not-ours`（`gap=2`，`track=0x7ffd…` 栈地址）。
  承重点：探针把 256 B 出参缓冲区**预填 `0xAA`** ⇒ "数组一个字节都没写"是**实测**（`argc_out_dirty_bytes=0`），不是推断。
- ③ 未改上游 `ValidateAndTrace`：本件**未改任何产品件**（C1）。

**C8 native 不得制造可用值（T1／T2／T3／T3′ 成对反腿）** —— **`NOINFO`**
- 理由：反腿要在**写 `pfsparaclient` 的地方**注入（＝ native 的输出数组，**本件禁改**）；托管侧**没有**这个写入语句（命中 0）⇒ **无注入点**。
- 本件**只给源码级分类**（**明写：这不是读数**）：T1 越界／真指针／`0` ⇒ `PtsContext.cs:247` `FailFast`；T2 空闲槽 ⇒ `:248` `FailFast`；T3 live 但错类型 ⇒ `as` 得 `null` ⇒ `PTS.ValidateHandle(null)` ⇒ 可捕获异常；T3′ 无校验站点 ⇒ **NRE**。
- **消掉需要**：native 实现件落地后，用"错误值注入 ＋ 首帧／异常类型"真跑四条反腿并**按类点名**。

**C9 两页症状面** —— **达标，但单独不得当证据**
- 两腿：`LEG k=23 alive=yes app_rc=143 magenta=0 colors=383 ns=…RichTextBoxDemo ae=0 ink=480000`；`k=24 alive=yes app_rc=143 magenta=0 colors=383 ns=…FlowDocumentDemo ae=15386 ink=480000`；`NAMED managed_unavail=0 err=- native_gap=0 native_err=-`；`FAILLINE k=.. failfast=0 unrec=0`。
- **反过读（写死）**：本会话已有**三例硬实证**"净腿不崩／占位消失＝假绿" ⇒ 本格**单独绝不构成**本步任何结论。

**C10 同趟与截图** —— **四值同 ＋ 三格齐；但如实记"非本件同趟重取"**
- 逐腿：`disk_so16=a4bf2c47f8efb521` ＝ 两腿 `DEV … shim=` ＝ `session.txt shim_sha16`；`disk_pf16=2988f5154ecac5dd` ＝ 两腿 `DEV … pf=` ＝ `session.txt pf_sha16` ＝ **第三方口径**：`sync-applocal.sh --check ~/w67-work/app` 的 `✓ PresentationFramework.dll：已与权威一致 2988f5154ecac5dd`（`SYNC-APPLOCAL=PASS items=5 ok=5 drift=0`）。
- 截图同趟三格：`shotstat(k24) = colors=383 magenta=0 ink=480000` ＝ `leg_24.env` 的 `colors／magenta／ink` **逐格相等**；`FRAME k=24 … fr_sha=ef3fd6765f18f51b` ＝ `sha256sum shots/g1/k24.png` **实测值**（两腿 `fr_sha` 同值）。
- **明写**：`legs=2/2` **不是**同趟证据（守卫 `--legs` 的活腿解析段**不读** `DEV` ⇒ 它对跨代拼盘照样报 `2/2`）。
- 🔴 **限制（如实记）**：**本件未重跑腿**。理由：本件未改任何产品件（C1）⇒ 在册 `evidence/**` 与现盘**同一代**（上列四值已逐格核过）；而**覆盖 `evidence/**` 会让判据件 `t130` 里引用的那批 sha256 失效**。⇒ 上列读数的性质是「**在册证据的现核**」，**不是本件同趟重取** —— 记为**限制**，**不得当同趟绿**。

**C11 导出/接口面** —— 达标（本步**未靠加导出**收尾）
- `nm=594＝exports`（`equal=yes`）、`^Fs=6`、`FsQueryTrackParaList` 的 `nm` 裸名命中 **1**；逐名：`FsCreatePageBottomless`／`FsCreatePageFinite`／`FsDestroyPage`／`FsQueryPageDetails`／`FsQueryTrackDetails`／`FsQueryTrackParaList`。本件**未增/删任何导出**（无产品改动）。

**C12 回归面** —— 达标
- `failfast=0 unrec=0 ptsgap=0 unavail=0 fontfb=6`；`reason` 集合 ＝ {`paraclient-table-not-native`}（⊆ 允许集）；`^Fs=6` 不降；两腿 `alive=yes`／`app_rc=143`。

---

## §5 「假进度必红」P1–P9 逐条处置

| # | 假形式 | 本件处置 |
|---|---|---|
| **P1** | 只改计数/声明 | **不适用**：本件未改声明件、未改产品件；本件**不**以任何声明件为据 |
| **P2** | `return 0` 无副作用 | **已证伪（现取）**：探针两条路径均 `rc=-10000`、`ok` 恒 0、`gap` 递增（`0→2`）⇒ **没有**"返 0"发生 |
| **P3** | 吞 `ENFE` | **两格都给**（C3）：`ENFE=0` **且** 留痕 **1123** 行 ⇒ **未吞** |
| **P4** | 交伪句柄 | **无对象**：本件**不交任何值**（native 不写数组）；机理分类见 C8（**已注明非读数**） |
| **P5** | 两页帧相同却报绿 | **如实判红**（C5） |
| **P6** | 拿 `ink>0` 当内容证据 | **降级**（C4③：`boot/k23/k24` 三帧同值 `480000` ⇒ 反例现取） |
| **P7** | 拿 `ns=` 当身份 | **不使用**（C6；两条反例） |
| **P8** | 跨趟/跨代拼读数 | 本件给**载体＋`ts`＋代际**三元组；**不做跨代相减**：`1085`（`t129` 那一代）与 `1123`（本代）**并列**，差**不解释** |
| **P9** | 恒绿自检 | 本件未新增自检；**"守卫有牙"的现取佐证**：`PTS_GUARD=FAIL`（`rc=1`）—— 若恒绿，它必 `PASS` |

---

## §6 两极化 a／b／c

| 腿 | 本件读数 | 判词 |
|---|---|---|
| **a**（受控"托管表未登记"） | 可按名过滤的留痕 **1123 × `reason=paraclient-table-not-native entry=FsQueryTrackParaList`**；进程不崩（`alive=yes app_rc=143`、`failfast=0`） | **成立**（今天**就是** a：native 从不调回调 ⇒ 表内无客户端） |
| **b**（受控"表已登记"） | —— | **`NOINFO(reason=承重前置属 native 写域：native 既不调 `pfnCreateParaclient` 也无承载字段)`** |
| **c**（交伪句柄，必红并**按类点名**） | —— | **`NOINFO(reason=无注入点；不分类的红不算成立)`**；机理分类见 C8（**已注明非读数**） |

---

## §7 `NOINFO` 清册（逐条给"消掉需要什么"）

| # | 项 | 为什么取不到 | 消掉需要 |
|---|---|---|---|
| 1 | **b 腿读数** | 承重前置未满足 | §2 两段前置落地后跑一趟：成功次数 ≥1 ＋ `*cParaDesc` ＝ 真条数 ＋ C2 四项 |
| 2 | **表内 live 客户端数（进程内实测）** | 它是进程内状态，本件不起腿（**只给静态结论"结构性为 0"**，§2 末项） | 在 M1 内加**只读**观测面（**现取可行**：`IsValidHandle` ＋ `HandleToObject`）并同趟给三格 |
| 3 | **`T3′` 本链上会不会被走到** | 本件**未复核** `t130` 的"217 处／172 处"计数（不引他人读数） | 一趟带栈读数，或把"错类型槽"反腿真跑出来看首帧 |
| 4 | **`FSPARADESCRIPTION` 真语义**（`fsupdinf`／`pfspara`／`nmp`／`idobj`／`fsbbox` 各该填什么） | 本仓只有托管侧声明（`Pts.cs:1500-1510`），无 native 侧规格 | 具名布局/语义声明，或"逐字段读回"成对读数 |
| 5 | **`FSPARADESCRIPTION` 八字段实测偏移 ＋ `_Static_assert` 钉死** | **本件没有测量仪器**（托管侧工件无法引用该 `internal` 类型；native 侧有禁改令） | **native 侧实现件**用 `t127` 同款探针**实测**（运行时取偏移）＋ `_Static_assert` 钉死；**禁**按字段类型"数出来"当结论 |
| 6 | **`t127` 的"错 8 B ⇒ 1129 次 `unknown-track-or-not-ours`"细节** | 本件**未现取**（不引他人读数当我的读数） | 用自己的台账/日志复现一次 |
| 7 | **应用 `[HC-UNHANDLED]` 钩子的捕获语义** | 发射方在第三方应用、不在我方写域 | 读该件捕获分支原文，或我方自加计数器（本件只取到 `1123 ↔ 1123` 一一对应） |
| 8 | **`N4` 正身份** | 今天无该登记载体 | 登记一次已知良好渲染的帧 `sha256`（或该页专属结构读数）——另派单 |
| 9 | **`check-applocal-sync.sh` 的 `APPSYNC=MISMATCH`** | **非本件所改**（本件未碰 `~/w67-work/app`）；现取 `MISMATCH=113[STALE=113] MISSING=0 UNEXPECTED=6[DECL-GAP-DIFF=6] DIVERGENT=5 …`、`rc=1` | 与 `sync-applocal.sh --check` 的**另一口径**（`items=5 ok=5 drift=0 PASS`）**并列**；**不作相减、不作归因** ⇒ 本件记 `NOINFO(reason=两口径不同且非本件射程)` |
| 10 | **本件读数的"同趟"性质** | 未重跑腿 | `NOINFO(reason=本件未重跑腿；在册证据与现盘同代已逐格核过，但那是"现核"不是"同趟重取")` |

---

## §8 纪律与边界自证

- **纪律 30（三格）**：本件**唯一自起进程** ＝ C7 探针（fresh）。① **进程新鲜度** ＝ **fresh**（调用前 `ok=0 gap=0`；**未**建任何 `PtsContext`／**未**建任何 `*ParaClient`／**未**调过销毁）；② **关键前置量** ＝ `g_pts_fsp_pl_ok=0`／`gap=0→2`（经**两个只读口**现取），**表内 live 客户端数 `NOINFO`**；③ **判词** ＝ `rc=-10000`、`cParaDesc=0`、`array_untouched=1`。其余成对读数（C3–C12）**取自另一趟的在册证据** ⇒ 已在 C10 如实标注，**不当本件同趟**。
- **纪律 28（`cell=#1`）**：本件改的**覆盖面内件 ＝ 0**（现取：`fp_inputs()` 里 M1／本载体／`HANDOFF-NEXT.md` 三者 `in_fp=0`；装置件一字未动）⇒ **触发条件未成立**；现取 `bash ~/w153a/bin/infp.sh fp` ＝ `198563b4dcb4e1eb03e0bf688ee5eb87abf83e92ed023f240ae07b8208631b9e`，与**最后一格**（`t129`，`ts=2026-09-29T13:22:29`）**逐位相同**；本件仍按纪律**同趟追写一格**（纯 `>>`，如实记"**0 件改动、指纹未动**"）并复跑 `HANDOFF_MV`（见 §4-C12 与 §9）。
- **纪律 29（备份面 ≡ 改动面）**：本件**未改产品件** ⇒ 备份面为**空**；"未改"的**证据**留档 ＝ 车道 `~/t123-runner/logs/t131/pre.txt`（起点 8 件 sha16 ＋ 资源读数）。**没有 `cp -p` 回拷**（无回拷对象）⇒ **不存在** `t127` 那种"回拷使源件 mtime 反旧 ⇒ MSBuild 静默跳过编译"的风险（本件**也未构建**）。
- **边界自证**：`git status --porcelain` 前后对比 —— 唯一新增 ＝ `?? build/MilBridge/P1-managed-handle-report.md`；`HANDOFF-NEXT.md` 恰因本件追加 `cell=#1` 一行而新增一条 ` M`（**写域内**，纯 `>>`）。**未**出现任何 `src/**`／上游／`tools/**`／装置件／生成件／判据件／`docs/ROUTES.md`／`samples/**` 的改动。
- **资源线（跑前现取，铁律②）**：`MemAvailable 3989788 → 3812964 → 4108728 kB`（**均 ≫ 2000**）、`SwapFree 1396476 kB`（**≫ 512**）、`df -Pk /` 可用 **72503616 kB ≈ 69 GB**（**≫ 5 GB**）⇒ 全程未触停手线。**本件未走重活槽**（无构建、无腿、无整趟门禁；唯一编译是车道内 30 行探针，`gcc -O0`）。

---

## §9 收尾牙（受本族影响者；逐个捕获 `rc`）

| 牙 | `rc` | 现取读数 |
|---|---|---|
| `handoff-machine-values-check.sh` | **0** | `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`（＋`HANDOFF_MV_NOTE lane-activity=0`） |
| `pipefail-sigpipe-check.sh` | **0** | `PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=114 sites=105 hit=0 low=10 diag=5 safe=90 runs=12` |
| `report-id-domain-check.sh` | **0** | `REPORTID=PASS files=261 ids=2204 declared=224 glob=build/MilBridge/*report*.md`（含本件） |
| `sentinel-spec-check.sh` | **0** | `SSC=PASS lines=13 keys=13 cmp=IDENTICAL`（`SSC_VALUE=PASS key=WAVE v=w80-freeze`） |
| `static-jaws-check.sh` | **0** | `STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62`（其自带边界：射程＝已接线的裸静态牙，**不等于**整趟门禁绿） |
| `pts-gap-count-check.sh` | **1** | `PTSGAP=FAIL tool=90 dead=11 artifact=1 ops=78 impl=81 so16=a4bf2c47f8efb521 exports=594`；**唯一残留** `SITE-DRIFT docs/ROUTES.md impl want=81 got=87`（＝`t123`/`t127`/`t129` 同一条：`:247` dated 历史行缺求值锚 ⇒ 被当现值位；**本件未改牙、未改该行、未回退**） |
| `pts-pages-guard.sh --legs <证据目录>` | **1** | `PTS_G10_NAME=PASS observed=FsQueryTrackParaList`；`PTS_N1=INFO`（两腿，`phase=degraded`）；`PTS_ENFE=INFO total=0`；`PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line,native-ledger-absent(PTS_GAP n=0),leg23-… diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0 direction=in-file phase=degraded`（**degraded 期既有红，非本件引入；本件未改守卫**） |

**说明**：上表**全部是只读现跑**（本件未改 `build/MilBridge/tools/**`、未改装置件、未改哨兵）。
`P1-MANAGED-HANDLE 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 5f67b9fb0caee8c7（末行＝本行）`
