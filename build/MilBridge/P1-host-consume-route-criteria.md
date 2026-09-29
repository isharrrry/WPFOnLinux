# P1-W105 只读侦察＋判据草案：`LM-1` 第 4 条「宿主消费」三条路线的代价与形态（给队长择一）

本件是**只读侦察＋判据草案**：**不改任何件**（csproj／upstream／`.cs`／`tools/**` 一件未动），**不接实现**；产出**给队长择一**的依据。
行号一律整行取；引他人读数带代际并标「未独立复算」；读数来自**读取**。

---

## §0 身份、边界与在飞件

- 载体：`build/MilBridge/P1-host-consume-route-criteria.md`（**新建**，`temp+rename`）。写入面**仅本件**。
- 读取时刻：**2026-09-29 22:40–22:52**；HEAD＝`d7830c9`；`src/WpfGfx.Linux.Native/src/win32_pts.c` 现取 **`02d4c89fa432d4d2`**。
- ⚠️ 本件为 **attempt 2**；落盘前现取确认载体**不存在**（attempt 1 未留件）⇒ 本件为**全新产出**，未复用任何旧件内容。

---

## §1 台账（件＋sha16／行数，全部现取）

| 件 | sha16／行数 | 用途 |
|---|---|---|
| `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj` | `e22a7457dc4a8010`／1562 行 | `Compile Remove`／`Include` 形制与规模 |
| `build/PresentationFramework.Linux/reapply-patches.py` | `1769524cac043730`／777 行 | **生成器**（needle 校验 + csproj 覆盖块内嵌） |
| `build/port-lib.py` | 37751 B | 会**整份重写 csproj** 的上游转换器 |
| `upstream/…/PtsHost/PtsHelper.cs` | `f2ed9552e983fed1`／**963 行** | 路线 (b) 的复制对象（`internal static class PtsHelper` `:22`，**29 个方法**） |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `02d4c89fa432d4d2`／330477 B | 路线 (c) 的既有见证口 |
| `build/MilBridge/P1-handle-count-report.md`（`t172`） | 88 行／自证 `3862c1b4165ba872`（**引自其复核件 `P1-count-m1-verify.md:4`，本席未独立复算**） | `t172` 计数口 |
| `build/MilBridge/HANDOFF-NEXT.md` | — | 冻结口径（§1 九位／托管哈希＝**路径承载体**） |

---

## §2 路线 (b) 本侧替身：逐项现取 + 量化改动面

### §2.1 形制现状（`PtsCache` 的方子，已被用过 **11** 次）
- `csproj:322` `<Compile Include="$(UpstreamWpfRoot)…/PtsCache.cs" />`；`csproj:1516` `<Compile Remove="…/PtsCache.cs" />`；`csproj:1517` `<Compile Include="$(WpfLinuxRoot)build/PresentationFramework.Linux/PtsCache.Linux.cs" />`；紧接 `:1518-1519` 同一方子给 `FlowDocumentView`。
- **规模现取**：`csproj` 内 `<Compile Remove=` **11 条**、`*.Linux.cs"` 出现 **11 次**；`build/PresentationFramework.Linux/*.Linux.cs` **11 件**（`DeferredTextReference`／`FlowDocumentView`／`FrameworkElement`／`PtsCache`／`SystemResources`／`TextBlock`／`TextBoxBase`／`TextBox`／`TextContainer`／`TextEditorTyping`／`Window`）。
- ✅ **`PtsHelper.cs` 不在其中**（11 条 Remove 清单逐条现取，无 `PtsHelper`）⇒ 它是**尚未被替换**的上游件（`csproj:324` 只有 `Include`、无 `Remove`）。

### §2.2 要动什么（三条）
1. **生成器**：`reapply-patches.py`（777 行）——其机制是 `:179-192 def _apply_edits(upstream_rel, out_name, edits)`：**从上游重读、逐处 needle 替换、命中数不符即抛**（原文 `:190` 「上游变了或本脚本过期，**拒绝产出**」）；现有批次 `:201 ── PtsCache.Linux.cs 的三处改动`、`:495 ── FlowDocumentView.Linux.cs 的四处改动`、`:734 def materialize_derived()`。⇒ 新增一个 `PtsHelper` 批次（**1 处 needle**：在 `PtsHelper.cs:177` 前后插入只读打印）＋ 在**内嵌 csproj 覆盖块**（脚本 `:115-118`）追加 2 行。
   🔴 **必须改脚本、不能手工改 csproj**：脚本自陈 `:110-112`／`:149` —— 生成物由脚本产出，且 **`port-lib.py PresentationFramework` 会整份重写 csproj**（把手工接线抹掉）。
2. **生成物**：`build/PresentationFramework.Linux/PtsHelper.Linux.cs` ＝ **上游 963 行逐字复制 + 1 处改写**（`internal static class PtsHelper` `:22`；29 个方法，其中 `ArrangeParaList` `:145`、`ParaListFromTrack` `:604`、`ParaListFromSubtrack` `:623`…）。
   ⇒ **"963 行里哪些是必须的"＝全部 963 行**：该类是 `internal static`，方法被 `PtsHost` 一族广泛调用；**删方法会破坏编译**，且与"逐字复制 + needle 改写"的形制相冲突。
3. **csproj**：由脚本重写 ⇒ 手工面 **0 行**（但仍要跑脚本 + 重建）。

### §2.3 量化改动面与代价
| 维度 | 量 |
|---|---|
| 改的**件数** | **2 件**（`reapply-patches.py` ＋ 生成物 `PtsHelper.Linux.cs`）＋ `csproj` 由脚本写出 |
| 手写行数 | ≈ **15–25 行**（needle 编辑 + 2 行覆盖块） |
| 生成行数 | **963 行**（全件复制，自动） |
| 是否需重建 | ✅ 需重建 `PresentationFramework`（托管件） |
| 是否影响冻结 | 🔴 **会**：冻结九位（现取 `HANDOFF-NEXT.md:12`：`bridge 4e25e4b27d4d5ae1`／**`pf 4fcd2ca021c39064`**／`pc 53fd7fffcdb30243`…）中 **`pf` 会移动** ⇒ **须走新冻结**（不是"零代价"）。⚠️ 该件同时给出**读法口径**（`:14`）：**"托管程序集的哈希是路径承载体；凡跨树位置比较产物哈希，先问『它是在哪个树里产出的』"** ⇒ 跨树比较无意义，**同树新冻结才有效**。 |
| 是否影响主链 `.so` | ❌ 不影响（模板 §A-4 的"主链 `.so` 逐字节不变"只覆盖 **native**） |
| 风险 | needle 失效 ⇒ **报错退出**（安全）；重复执行幂等（脚本自陈 `:3`） |

---

## §3 路线 (a) upstream 打点：代价对比

**`upstream/wpf` 在本仓的地位（现取）**：**被 git 跟踪的普通目录** —— `git ls-files upstream/wpf | wc -l` ＝ **6415** 件；**无 `.gitmodules`**（`ls .gitmodules` ⇒ 不存在）⇒ **不是子模块**。
⇒ 在它里面打点 ＝ **改仓内被跟踪件** ⇒ ① 进 `git diff`／`porcelain`；② 与既有形制**正面冲突**（本仓对上游的既定做法是"**上游逐字 + 脚本改写生成 `.Linux.cs`**"，脚本注释 `:110-112` 逐字在册）；③ 触碰模板 §A-11 写域（**不碰 `.cs`**）⇒ **纪律面最差**。

**代价对比表（(b) 本侧替身 vs (a) 上游打点）**

| 维度 | (b) 本侧替身 | (a) 上游打点 |
|---|---|---|
| 机械代价 | 2 件／≈20 手写行／963 生成行 | **1 行**（最省） |
| 纪律 | ✅ 沿用 11 次既有方子 | 🔴 改 `upstream/**` 被跟踪件（与"逐字 + 脚本改写"冲突；涉 §A-11） |
| 上游漂移时 | ✅ needle 校验**报错退出**（防静默） | 🔴 上游更新会**冲突/覆盖**，且无 needle 保护 |
| 冻结 | 需新冻结（`pf` 动） | 同（且 additionally 上游件被改） |
| 可复核性 | ✅ 生成物可 diff 上游 | ⚠️ 需人工比对 |
| 结论 | **正规、可复核、代价小** | **不建议** |

---

## §4 路线 (c) native 等价见证（重点）：逐条现取 + 可证伪性

### §4.1 今天已有的三个面
1. **消费者解析/回收计数口**（原生自记，**本侧为作者**）：`win32_pts.c:1117 static int g_pts_fsp_pl_consumes = 0;   /* 延迟回收（`+192`）次数 ⇒ 也＝"消费解析"次数 */`、`:1118 g_pts_fsp_pl_resolve_ok`；只读导出 `:1129 int WpfLinuxWin32_PtsFsParaListConsumes(void)`、`:1130 …ResolveOk(void)`；增点 `:3575 g_pts_fsp_pl_consumes++;`、`:3577 if (is_ok) g_pts_fsp_pl_resolve_ok++;`、`:3597`。
   - 能**成对**吗？❌ **弱**：M2 开/关都可能产生同样的"解析/回收"次数 ⇒ **不能单独证明 `rcPara.dv>0` 被当真值用**。
   - 本侧为作者？✅（数我们自己的回调）。代价：**0**（已存在）。
2. **`FsQuerySubtrackDetails` 一族**（`t169`/`t173` 链）：native 现取**未实现**（`grep -c 'FsQuerySubtrackDetails'` ＝ **1**，且那是注释引用）⇒ 要用它当见证**必须先实现**（成本 + 它属 `S-2b` 一族，越级边缘）。即便实现，它由 `ContainerParaClient.OnArrange`（`ContainerParaClient.cs:82` ← `BaseParaClient.cs:82`）与 `GetTextContentRange`（`:271`）调用 ⇒ **是"到达 `Arrange` 之后"的见证**，**不直接依赖 `rcPara.dv`**。
3. **段落/页几何只读口**（`FsQueryPageDetails` 的 `trackdescr.fsrc` 等）：❌ **不能作见证** —— 那些值**本侧就是作者**（自造值自证不算消费）。
4. **`t172` 活条目计数**（`P1-handle-count-report.md`，88 行/自证 `3862c1b4165ba872`，**引自其复核件，本席未独立复算**）：同为**本侧自记**，同上。

### §4.2 🔴 核心洞察（本件的结论性发现）
第 4 条要证的是"**宿主把本侧的 `dvrUsed` 当真值用了**"。今天所有可得面要么是**"到达"见证**（消费者/解析/回收被走到），要么是**"自陈"见证**（本侧自造值）——**没有一个是"成对可区分"的**（M2 开/关读数不同）。
⇒ **但"`rcPara.dv > 0`"这个结论不必直读**：上游那一行是**确定的算术**
`PtsHelper.cs:177 rcPara.dv = arrayParaDesc[index].dvrUsed - dvrTopSpace;`
而 `dvrUsed`/`dvrTopSpace` **都是本侧作者**（`LM-1` 现取 `dvrUsed=16`、`dvrTopSpace=0`）⇒ **`rcPara.dv = 16 > 0` 由算术唯一确定**，无需观测宿主局部变量。
⇒ 于是第 4 条剩下来**唯一真正需要观测**的事实是：「**宿主确实执行到了 `:174-180` 这一段**」。而 `:179` 的下一步是 `paraClient.Arrange(...)` → `BaseParaClient.Arrange` → `OnArrange()` ⇒ **`OnArrange` 内的入口调用就是"执行到 `:179` 之后"的见证**——**但**它今天**未实现**（§4.1-2）。
⇒ **三条可选的"到达"见证**（按可用性）：**(i)** `+192` 回收计数（**已存在**，弱：销毁期，晚于 `:179`）；**(ii)** `OnArrange` 内的 `FsQuerySubtrackDetails`（**最强**，但**未实现** ⇒ 需新实现）；**(iii)** `+176` 造客户端计数（已存在，更弱：可能早于 `Arrange`）。

### §4.3 **明确回答：路线 (c) 能否替代第 4 条？**
- **不能完整替代**（缺"成对可区分"的直读见证）；
- **但能给出一个可辩护的降级见证**：`到达见证（c-4.1-1，已存在）` ∧ `上游公式针（PtsHelper.cs:177 逐字现取）` ∧ `本侧作者性（dvrUsed/dvrTopSpace 由本侧给定）` ⇒ 判词可写为「**宿主侧的 `rcPara.dv = dvrUsed - dvrTopSpace` 由算术唯一确定为 >0，且宿主已走到消费该段落的路径**」，**粒度＝到达＋算术（非直读）**。
- **最小判据草案（可写成必红反腿）**：
  - `objective`：在**副本**腿内，证明宿主**执行**了 `PtsHelper.ArrangeParaList` 的 `:174-180` 段，且其中的 `dvrUsed`/`dvrTopSpace` 是本侧当次给定；
  - `acceptance`：① `calls>0`（本侧入口被真调，`P10`）；② `dvrUsed>0 ∧ dvrUsed ≥ dvrTopSpace`（本侧给定，逐值可核）；③ **上游针**：现取 `PtsHelper.cs:177` 逐字等于 `rcPara.dv = arrayParaDesc[index].dvrUsed - dvrTopSpace;`（若上游改了这一行 ⇒ **本见证立即失效**，须重判）；④ **到达**：至少一项**晚于 `:179`** 的本侧可见事件（首选 `OnArrange` 内的入口调用；次选 `+192` 回收计数）；⑤ ≥2 独立样本同判 ＋ 纪律三十三格；
  - **反腿（必红）**：**(a)** 把 `dvrUsed` 设为 0 ⇒ 该腿必须**不能**判绿（即判据必须能区分）；**(b)** 到达见证计数为 0（没发出去）时 ⇒ **不许**判绿（`P10`）。
  ⚠️ **诚实边界**：反腿 (a) 若**同样**能让 ①②④ 通过（因为 `dvrUsed=0` 时宿主仍会走 `Arrange`），则**本降级见证的判别力有限** ⇒ 该限制必须写进判词（**不得**把它说成"宿主消费的直读证据"）。

---

## §5 判词与推荐（给队长择一）

### §5.1 三路线排序

| 序 | 路线 | 代价 | 可证伪性 | 是否只能本波做 | 判词 |
|---|---|---|---|---|---|
| **1** | **(c) 降级见证**（到达＋算术，复用已有计数口） | **最低**（0 新件；只写读数与判据） | **中**（能证"到达＋算术确定"，**不能**直读其局部） | ✅ 可本波做（纯 native 读数面） | **推荐（本波）** |
| **2** | **(b) 本侧替身**（`PtsHelper.Linux.cs` + 生成器批次） | **中**（2 件／≈20 手写行／963 生成行 ＋ **新冻结**） | **高**（可在 `:177` 处直读 `rcPara.dv`） | ⚠️ 需新冻结（`pf` 动）⇒ **不只是"本波技术问题"** | **若队长要"直读"，选它**（最省的正规路） |
| **3** | **(a) upstream 打点** | 机械最低（1 行）／**纪律最高** | 同 (b) | 🔴 与"上游逐字 + 脚本改写"形制冲突；涉 §A-11 | **不建议** |

### §5.2 推荐与理由
**推荐路线 (c)（降级见证）**：本波目标是"3 条未绿 `[MVP]`"，`LM-1` 第 4 条的作用是**把 `S-2a` 从 7/8 补到 8/8**；用"**到达 ＋ 上游算术针 ＋ 本侧作者性**"已足以把 `rcPara.dv>0` 这一结论**钉在可复核的基础上**，且**零新件、零新冻结**。**同时**把 (b) 作为**备选**列出：若队长认为"必须直读宿主局部"才算数，则 (b) 是正规且代价可控的路（脚本生成、needle 保护、只需一次新冻结）。

### §5.3 若采纳 (c)：判据草案（写全，供队长直接用）
- **objective**：证明 `PtsHelper.ArrangeParaList` 的 `:174-180` 段被**执行**，且其中垂直量由**本侧**给定、算术上必然产出 `rcPara.dv>0`。
- **acceptance**：同 §4.3 的 ①–⑤。
- **verify**：`<leg> >out 2>err; echo $?`（**不许从管道尾巴取 `rc`**）；`grep -c` 出具名行计数；**上游针**用 `awk 'NR==177'` 现取逐字比对并**记 sha16**；两样本逐格比对。
- **inScope**：本侧读数面（`win32_pts.c` 的既有计数口 + 只读导出）＋本件载体。
- **outOfScope**：任何 csproj／`upstream/**`／`.cs`／`tools/**` 改动；任何"直读宿主局部变量"的主张（**留给路线 (b)**）。
- **反腿（必红）**：`dvrUsed=0` 腿**不得**判绿；到达见证为 0 时**不得**判绿。
- **判词粒度（写死）**：**"到达＋算术"**，**不是**"直读"；`S-2a` 由 7/8 → 8/8 时，**判词须写明这是降级见证**，并**不得**据此宣布"整页排版成功"（`t179` 明禁）。

---

## §6 纪律落地与验收

- 🔴 **`P9`**：不把"本侧观测不到宿主局部"推广成"宿主没消费" —— 本件给出的正是**替代观测路径**（到达＋算术）。
- 🔴 **`P10`**：每条"不能/未实现"判定均附前置与射程（`FsQuerySubtrackDetails` native `grep -c`＝1 且为注释引用；11 条 `Compile Remove` 清单逐条现取且无 `PtsHelper`；`git ls-files upstream/wpf`＝6415 件；无 `.gitmodules`）。
- 🔴 **恒真断言族**：本件读数全来自**读取**；**未**使用"两样本一致"类证据；凡"计数为 0"的读法（如到达见证）已明写**只能说明"没发出去"**。
- **验收**：新件、`mode 644`、首记号 `# P1-W105 `、末行自证并当场复算 MATCH、`temp+rename` 落盘、未 `git add/commit/push`。

---

## §7 附录：现取原文摘录（整行取，仅本次有效）

`PresentationFramework.Linux.csproj`（sha16 `e22a7457dc4a8010`）：
```
:322    <Compile Include="$(UpstreamWpfRoot)src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/PtsCache.cs" />
:324    <Compile Include="$(UpstreamWpfRoot)src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/PtsHelper.cs" />
:1516    <Compile Remove="$(UpstreamWpfRoot)src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/PtsCache.cs" />
:1517    <Compile Include="$(WpfLinuxRoot)build/PresentationFramework.Linux/PtsCache.Linux.cs" />
```
`reapply-patches.py`（sha16 `1769524cac043730`）：
```
:110        ⚠️ 生成物（`*.Linux.cs`）由本脚本从**上游逐字复制 + needle 校验后改写**：
:111           锚点找不到 / 命中数不符 ⇒ **报错退出**（绝不静默产出未打补丁的副本）。
:112        ⚠️ 本块**必须排在 port-lib 之后**（`port-lib.py PresentationFramework` 会整份重写 csproj）。
:179 def _apply_edits(upstream_rel, out_name, edits):
:190                 "%s：第 %d 处 needle 命中 %d 次（期望 %d）—— 上游变了或本脚本过期，**拒绝产出**"
```
`upstream/…/PtsHelper.cs`（sha16 `f2ed9552e983fed1`，963 行）：
```
:22    internal static class PtsHelper
:145        internal static void ArrangeParaList(
:177                rcPara.dv = arrayParaDesc[index].dvrUsed - dvrTopSpace;
:179                paraClient.Arrange(arrayParaDesc[index].pfspara, rcPara, dvrTopSpace, fswdirTrack);
```
`win32_pts.c`（sha16 `02d4c89fa432d4d2`）：
```
:1117 static int          g_pts_fsp_pl_consumes     = 0;   /* 延迟回收（`+192`）次数 ⇒ 也＝"消费解析"次数 */
:1129 int WpfLinuxWin32_PtsFsParaListConsumes(void)   { return g_pts_fsp_pl_consumes; }
:3575                     g_pts_fsp_pl_consumes++;
```

---

**判词（本席）**：① **路线 (b)**（本侧替身）＝**正规且代价可控**：只需动 **2 件**（`reapply-patches.py` 加一个 needle 批次 ＋ 生成物 `PtsHelper.Linux.cs`＝**上游 963 行全件复制**、仅 `:177` 处 1 处改写），`csproj` **由脚本重写**（**不许手工改**：`port-lib.py` 会整份覆盖）；但**托管件重建会移动冻结九位的 `pf`**（现取 `pf 4fcd2ca021c39064`）⇒ **须走新冻结**，不是零代价。② **路线 (a)**（upstream 打点）＝**不建议**：`upstream/wpf` 是**被跟踪的普通目录**（`git ls-files` **6415 件**、无 `.gitmodules`），改它与"上游逐字 + 脚本改写生成 `.Linux.cs`"的既有形制正面冲突，且涉模板 §A-11。③ **路线 (c)**＝**本波推荐**：可得的面里**没有**"成对可区分"的直读见证（`g_pts_fsp_pl_consumes`／`resolve_ok` 是**到达**见证、页几何是**自陈**），**但第 4 条未必需要直读** —— 因为 `rcPara.dv = dvrUsed - dvrTopSpace`（`PtsHelper.cs:177` 逐字）而两个操作数**都是本侧作者** ⇒ `>0` **由算术唯一确定**；剩下的"宿主确实执行到 `:174-180`"可由**到达见证**承担 ⇒ **判词可写成「到达＋算术」的降级见证，粒度写明，且不得据此宣布整页排版成功**。④ **给队长的择一建议**：**本波采纳 (c)**（零新件、零新冻结，把 `S-2a` 由 7/8 补到 8/8 并在判词里标明降级）；**若队长口径要求"必须直读宿主局部变量"**，则改采 **(b)** 并排入**下一次冻结**。
`P1-host-consume-route-criteria 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 519fb73ec4b95780（末行＝本行）`

---

## ⏪ `t200` dated 收窄 · `t195` 判词（`needs_revision`）三条入册 ＋ 一条纪律（读时 `2026-09-29T22:55:15+0800`；**只增不改**、删行数 0、行号「仅本次有效」）

**来源**：`build/MilBridge/P1-lm-consume2-verify.md`（**本席现取**：110 行／`sha16=31dfda00ef739289`／末行自证 `59095ac60f913ea5`），判词 **`needs_revision`**；其中 `W-2`／`W-3`／`W-4` 的读数**照引并标"本席未独立复算"**，`W-1` 的**关键面本席自己现取复核**（见下）。**本段不改它的判词，只按它更正本件；上面原文一字未删。**

### `W-1`（high）「两个操作数都是本侧作者 ⇒ `rcPara.dv` 由**算术唯一确定**」—— **dated 收窄为：不成立**
- **被更正原句**在场（本席现取）：本件写「`dvrUsed`/`dvrTopSpace` **都是本侧作者**（`LM-1` 现取 `dvrUsed=16`、`dvrTopSpace=0`）⇒ **`rcPara.dv = 16 > 0` 由算术唯一确定**」。
- **更正（逐字）**：`PtsHelper.cs:177` 读的是 **`arrayParaDesc[index]`** 的两个字段，而该数组的**唯一填写者**是 `PtsHelper.cs:633 PTS.FsQuerySubtrackParaList(...)`；该入口 native 侧**未实现** —— **本席现取**（`src/WpfGfx.Linux.Native/src/win32_pts.c` 现代 **4506 行／`sha16=7212969f6e2cbb9f`／`mtime 2026-09-29 22:54:13`；行号「仅本次有效」）该件**第 3803 行**自陈：「与 `FsQuerySubtrackParaList`（`PtsHelper.cs:633`），二者都属 **(b)**、**尚未实现**」；且**本席现取** `nm -D --defined-only`（`.so` `352855f8dfbf8dc7`／`exports=669`）：**`FsQuerySubtrackParaList` ＝ 0 命中**（同趟 `FsQuerySubtrackDetails` ＝ 0、`FsFormatSubtrackFinite` ＝ 0）。
  ⇒ **`PtsHelper.cs:174-180` 今天不可达、两个操作数无源**；本件所引 `dvrUsed=16`／`dvrTopSpace=0` 属**格式化出参**（**另一界面**，不是 `arrayParaDesc`）⇒ **「算术唯一确定」不成立**。
- **新前置入册**：**`PRECOND-PARADESC-SOURCE-MISSING`**（**段落描述数组 `arrayParaDesc` 无源**：唯一填写者 `PTS.FsQuerySubtrackParaList` native 未实现；射程＝`PtsHelper.cs:174-180` 那条 `rcPara.dv` 计算；粒度＝单次 `ArrangeParaList` 调用）。

### `W-2`（medium）到达见证：**既是"没读"也是"不挡在该段下游"** ⇒ 判据必须改
- ① **无读取载体**：四腿里 `consumes`／`resolve_ok` **没有任何读取载体**（`[LMWIT] part=arrival` **未打印**）⇒ 当时那个 `consumes=0 ∧ resolve_ok=0` 是**回显推断**，不是读数（**照引 `t195`，本席未独立复算**）。
- ② **事件身份不符**：该计数是 **`+192` 回收**事件（**本席现取**：`g_pts_fsp_pl_consumes` 声明在 `win32_pts.c:1141`、`g_pts_fsp_pl_resolve_ok` 在 **`:1142`**、自增点 **`:3658`**、合取判定 **`:3661`**），其前置是"客户端被创建"，**不是** `PtsHelper.cs:174-180` 被执行。
- ③ **`cParas=0` 时 `:177` 一次不跑而后代回收照旧**：`arrayParaDesc.Length == subtrackDetails.cParas`（`PtsHelper.cs:629`）而 `LM-1` 自许 `cParas=0` ⇒ 将来长腿拿到 `consumes>0` **仍可能"没走到该段却给绿"**。
  ⇒ **判据处置**：到达见证必须改为**落在 `PtsHelper.cs:174-180` 路径上的事件**；**做不到就具名**（本波做不到 ⇒ 记 `PRECOND-PARADESC-SOURCE-MISSING` 未解除）。

### `W-3`（low）自源行号属**改前代际** ⇒ 以现取为准
- 本件所写 `win32_pts.c:1117`／`:3575`／`:3577` 是**改前代际**的坐标；**本席现取**（同一现代 `7212969f6e2cbb9f`）实际为：**`:1141`**（`g_pts_fsp_pl_consumes` 声明）／**`:1142`**（`g_pts_fsp_pl_resolve_ok` 声明）／**`:3658`**（自增）／**`:3661`**（合取）。⇒ 一律以**现取**为准；行号**仅本次有效**。

### `W-4`（low）粒度越界：「A/B **逐字一致**」⇒ 收窄为「**读数行**逐字一致」
- 整腿日志**自第 138 字节起分叉**（照引 `t195`，**本席未独立复算**）⇒ 原句"逐字一致"**只**对**读数行**成立。本件此后凡写"一致"，必须限定为「**读数行逐字一致**」。

### 纪律入册（**新条款**）：**读数类打印行禁静默阈值**
- **条款**：读数类打印**要么必打**（无条件），**要么打具名缺省行** —— 必须把「**没取到**」与「**没发生**」印成**两种可区分形态**。
- **正例**：无条件打 `[FSPARALIST-FILL] … consumes=%d resolve_ok=%d`；取不到则打 `consumes=NOINFO(reason=no-arrival-leg)`（本件 `P1-lm-consume-witness-criteria.md` 已有同形正例）。
- **反例**：**仅当 `>0` 时**才打印 ⇒ 输出里看到的"没有该行"与"真 0 次"**不可分**（本波第二次咬人：`t195` `W-2①`）。
- **族属**：本条款列为「**恒真断言族**」**第六例候选**（已入册四例：`t156` `+200` 恒定绿桩／`t161`"数值无判别力"／`t163` `P9` 偷换／`t176`＋`t183` 格式串字面；**待复核确认后升格**）。

### 状态声明（写死，不得改绿）
`LM-1` 第 4 条**维持 `NOINFO`／降级见证**；`S-2a` **维持 7/8**（**不得**写成 8/8）。

`P1-HOST-CONSUME-ROUTE-CRITERIA 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 7b2ccba25d3acede`（⏪ `t200` 追加后重算；**上一条自证行原文保留在上方**）

---

## ⏪ `t202` dated 收口 · `t201`（`pass`）点名的三条 low（读时 `2026-09-29T23:01:09+0800`；**只增不改**、删行数 0、行号「仅本次有效」）

**来源**：`build/MilBridge/P1-lm-consume-close-verify.md`（**本席现取**：105 行／`sha16=de87187be8520aa4`／末行自证 `f8dda8860df4c5fe`），判词 **`pass`**；其三条 low 的读数**照引并标"本席未独立复算"**。

### `F-1`（low）同源句**点名不全** ⇒ 补索引行 ＋ 优先规则行
- **本块收窄的同源原句，在本件内共 3 处 处**（**本席现取**，行号「仅本次有效」）：3 处（`:89`／`:95`／`:170`）。
  （`t201` 报的口径是"三块各只明引一处、全树同源共 7 处"；本席现取本件的 3 处 处与它给的坐标一致，**未独立复算**其全树 7 处之数。）
- **优先规则（写死，照 `P1-fsimethods-drive-report.md` 第 **150** 行「若与原文冲突，以本段为准」的形制）**：
  **本件凡"算术唯一确定／到达见证"类表述，与本段（及本段所引的 `t200` 段）冲突时，一律以本段为准**；上面原文**一字未删**。

### `F-2`（low）族谱/序号错 ⇒ **第六例候选 → 第五例候选**（并把它与"另一族先例"分开写）
- **更正（逐字）**：本文件 `t200` 段把「读数类打印行禁静默阈值」标为「恒真断言族**第六例**候选」—— **错**；按登记处 `build/MilBridge/P1-ptsname-result.md` **第 771 行**（**本席现取**：「🔴 「恒真断言」族**第 4 例**（它自陈）：两个空串比相等是假验」）⇒ **本波该条款应为「第五例候选」**。
- **两处不许混（逐个点名）**：**恒真断言族**的例 ＝ ① `t156` `+200` 恒定绿桩／② `t161`「数值无判别力」／③ `t176`＋`t183` **格式串字面**／**④ 两个空串比相等是假验**（登记处 `:771`）／**⑤ 本条款（候选）**；
  **`t163` `P9`「把『回调面没源』偷换成『没有源』」＝「对照先例（另一族）」，不是恒真断言族的例**（原段把它当"族内顶替例"写 ⇒ 本段更正）。
- **升格状态**：仍为**候选**（**待复核确认后升格**），本段不改它的强度。

### `F-3`（low）缺省行 token 两写 ⇒ **统一为既有 token `no-leg`**（旧写作废）
- **实情**：改前**既存** token 是 **`no-leg`**（在本件现取命中 `no-leg` 1 处，属 `t196` 段的 `[FSPARALIST-FILL]` 正例）；本文件 `t200` 段写的是 **`no-arrival-leg`**。
- **裁定（dated，择一）**：**统一为 `no-leg`** —— 理由：**以既存 token 为准**（少改、可与既有正例逐字对拍；`no-arrival-leg` 是本席 `t200` 新造，未在别处使用）。
- **旧写作废**：本文件 `t200` 段里 `consumes=NOINFO(reason=no-arrival-leg)` 的写法**作废**（**不在原处改字**，以此行为准）；此后缺省行一律写 **`consumes=NOINFO(reason=no-leg)`**。

### 状态声明（重申，不得改绿）
`LM-1` 第 4 条**维持 `NOINFO`／降级见证**；`S-2a` **维持 7/8**（**不得**写成 8/8）。

`P1-HOST-CONSUME-ROUTE-CRITERIA 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ d976b91e47e2cdc3`（⏪ `t202` 追加后重算；**上面两条历史自证行原文保留**）

---

## ⏪ `t207`（A-2）dated 补记 · 前置**加射程**：`PRECOND-PARADESC-SOURCE-MISSING` **`scope=subtrack-path`**（读时 `2026-09-29T23:25:07+0800`；**只增不改**、删行数 0）

**来源**：`t206` 裁决（照引，载体末行自证 `818df822191c0c31`；**本席未独立复算**）。
- 本件 `PRECOND-PARADESC-SOURCE-MISSING` 的登记处（**本席现取**，行号「仅本次有效」）：`:183`／`:189`。
- **补射程（逐字）**：该前置的有效域 ＝ **`scope=subtrack-path`**（`ContainerParaClient.cs:70→:72` 那条链）；**`track-path`（`PtsHelper.cs:134→:137`）不适用**。
- **优先规则**：本条与上面无射程的写法冲突时**以本条为准**；原文一字未删。

`P1-HOST-CONSUME-ROUTE-CRITERIA 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ a7284d083a54a3e6`（⏪ `t207` 追加后重算；**上面历史自证行原文保留**）
