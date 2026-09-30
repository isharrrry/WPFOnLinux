# P1-tail2 `TASK-0302` · 托管侧「会话句柄面／段落模型」可提供性 —— 只读侦察 ＋ 设计（`T-A21`）

- **读时**：`2026-09-30T14:1x+0800`（本席现取；§6 收尾再取）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=ba7187c6b18cc011d774f48050dec62919d0296e`（现取）。
- **现件代**：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`51fe76de3d8613de`**（416272 B）；`bin/exports.txt` ＝ **674** 行（现取 `nm` 逐名见 §6）。
- **件指纹（现取；`sha256` 前 16 位）**：
  `upstream/…/PtsHost/Pts.cs`＝`1a8575a18767a956`｜`PtsContext.cs`＝`c91e3f94d1188ece`｜`PtsHost.cs`＝`d1976dcc8362c8f9`｜`PtsHelper.cs`＝`f2ed9552e983fed1`｜`UnmanagedHandle.cs`＝`824adb562d83f63c`｜`BaseParaClient.cs`＝`e48fc11de3f65d09`｜`ContainerParagraph.cs`＝`1d0128592496706d`｜`ContainerParaClient.cs`＝`0d2e6aa79fdc035a`｜`ListParaClient.cs`＝`d3de181c357a9458`｜`TextParaClient.cs`＝`be3e7a145113dca5`｜`build/PresentationFramework.Linux/PtsCache.Linux.cs`＝`e5b399fdb8742092`（生成件）｜`build/PresentationFramework.Linux/reapply-patches.py`＝`0f9aec35f8e61582`（生成器）｜`src/WpfGfx.Linux.Native/src/win32_pts.c`＝`681bd74cd62fc287`。
- **边界（照 `T-A21` ②）**：**只读**；除本载体外**未改任何仓内文件**；**未改 `src/**`／`build/**`**（除本件）、**未构建**、**未跑整趟 `verify-all`**、**未跑 `static-jaws-check.sh`**；进程只按 PID；**未占任何显示位**；大件只用 `wc`／`head`／`tail`／`grep`；未 `git add/commit/push`。
- **行号纪律**：本件所有行号**仅本次有效**（内容锚原文一并给出，供下一位现取复核）。引他人读数**一律标注「未独立复算」**。
- **两条现取更正（先写在前面）**：① 派单 ① 写「`para=0x4` 到底是谁产出的（`PtsHost.CreateHandle`？）」—— **现取：`PtsHost` 里没有 `CreateHandle`**（全树 `grep` 命中 0）；唯一产地是 **`PtsContext.CreateHandle`**（`PtsContext.cs:175`，由 `UnmanagedHandle` 构造器 `:28` 调用）。② 派单 ① 写「`build/PresentationFramework.Linux/**` 的 `.cs` 调用点」—— **现取：该目录下这三个入口名命中 0**；全部调用点在 **`upstream/wpf/**`**（见 §1）。

---

## §0 结论速览（自包含）

1. **三入口的托管调用点全部在 `upstream/wpf/**`（`build/PresentationFramework.Linux/**` 命中 0）**；实参一律 `_paraHandle`（`BaseParaClient.cs:65`：`_paraHandle = pfspara;`）。`FsQueryTrackParaList` 的实参是 `trackDesc.pfstrack`（§1.4）。
2. **`para=0x4` 的产出链已现取闭合（8 跳）**：它是一个**托管句柄**（＝ `PtsContext._unmanagedHandles` 的**槽位下标**），源头是 `PtsContext.CreateHandle`（`PtsContext.cs:175`，由 `UnmanagedHandle` 构造器 `:28` 调）；**经已有回调 `+136 pfnGetFirstPara`／`+144 pfnGetNextPara` 的 OUT 参数交到 native**，再由 native 写回 `FSPARADESCRIPTION.pfspara`（`win32_pts.c:4629`），托管取回为 `_paraHandle`，最后**原样送回** native 当 `pSubTrack`／`pPara`。⇒ **这不是"托管没给"，是"native 收回了自己刚拿到的托管句柄、却用'本侧指针等值'去认它"**（§2、§3）。
3. **托管侧的「句柄 → 对象」反查面确实存在（只读）**：`PtsContext.HandleToObject`（`:243`）／`IsValidHandle`（`:224`）；**但它 `internal`、无 P/Invoke／无导出** ⇒ native 只能**经既有 `FSCBK` 槽**间接使用它（`+136`／`+144`／`+168`／`+176`／`+192`，§3.1）。**native 拿到句柄「能否合法使用」＝能**：持有期＝**托管对象生存期**（照裁定四十五 (a)：(a)＝已入册的 `Case I` 可跨调用持有），**但可调用性受"造型窗"约束**（§3.3）。
4. **甲／乙／丙逐条**（§4）：**(甲)** 可及（句柄已在位）∧ **不可行当"只读消费出内容"**（要暴露新反查槽 ⇒ 破 `FSCBK` 的 `824 B／103 字` 布局）∧ 代价高 ∧ `P8` 落点＝**改生成器 `PTSCACHE_EDITS`（且另需改上游 `Pts.cs`）**；**(乙)** 可及（槽 13／14／17／18 已在 native 的快照内）∧ **窗内可行／窗外不可行**（实测同族 `+136` 窗外 `rc=-100002` **×576**）∧ 代价中 ∧ `P8` 落点＝`win32_pts.c`（**不涉生成件**）；**(丙)** 「让 native 把 `pfspara` 交回本侧自有子轨对象／扩展身份模型」可及∧可行∧代价中∧ `P8` 落点＝`win32_pts.c`。
5. **结论 ＝ 判「托管侧无可做项（不可行）」＋ 合法终点**：三个入口的**入参面**（托管句柄）**不是**托管侧的缺口 —— **托管侧已经把句柄产出并交出**；真正缺的两条**全在 native 写域**：**(N1) 身份模型**（`wpf_pts_sub_claim` 只认本侧指针，不认"回调交回的托管句柄"）、**(N2) 窗内枚举 vs 窗外汇总分离**（内容模型必须在 `FsCreatePage*` 窗内建、三入口却在查询期被调）。⇒ 具名前置清单 ＋ 合法终点（§5）。
6. **本件自带的两条反腿**（§5-P）：① 不把「闸/窗内可得」读成「缺省/调用期可得」（`P13` 及其新面）；② 不把「`0x4` 数值相同」读成「同一个对象」（裁定四十五 (b)／四十七 (c)：**索引复用 ⇒ 静默错对象**；本趟日志实证 `0x4` 同趟**先后**当过段句柄与客户端句柄，§2.3）。

---

## §1 ① 三入口的托管调用点 ＋ 实参来源（件:行 ＋ 原文）

### 1.0 现取口径（可复跑）

```
$ grep -rln "FsQuerySubtrackDetails\|FsQueryTrackParaList\|FsQueryTextDetails" --include=*.cs .
./upstream/wpf/src/…/MS/Internal/PtsHost/ListParaClient.cs
./upstream/wpf/src/…/MS/Internal/PtsHost/ContainerParaClient.cs
./upstream/wpf/src/…/MS/Internal/PtsHost/Pts.cs              ← 声明件
./upstream/wpf/src/…/MS/Internal/PtsHost/TextParaClient.cs
./upstream/wpf/src/…/MS/Internal/PtsHost/PtsHelper.cs
$ grep -rn "FsQuerySubtrackDetails\|FsQueryTrackParaList\|FsQueryTextDetails" build/PresentationFramework.Linux/
（无输出 ⇒ 0 命中）
```
⇒ **调用点全部在 `upstream/wpf/**`**；`build/PresentationFramework.Linux/**`（含生成件 `PtsCache.Linux.cs`）**一个都不调**。

### 1.1 入口声明（唯一声明件 `PtsHost/Pts.cs`）

`Pts.cs:3690-3701`（**现取逐字**）：
```
        internal static extern int FsQueryTrackDetails(
            IntPtr pfsContext,                  // IN:  ptr to FS context
            IntPtr pTrack,                      // IN:  ptr to track
            out FSTRACKDETAILS pTrackDetails);  // OUT: track details

        [DllImport(DllImport.PresentationNative)]
        internal static extern unsafe int FsQueryTrackParaList(
            IntPtr pfsContext,                  // IN:  ptr to FS context
            IntPtr pTrack,                      // IN:  ptr to track
            int cParas,                         // IN:  size of array of para descriptions
            FSPARADESCRIPTION* rgParaDesc,      // OUT: array of para descriptions
            out int cParaDesc);                 // OUT: actual number of paragraphs
```
`Pts.cs:3735-3739`：
```
        internal static extern int FsQuerySubtrackDetails(
            IntPtr pfsContext,                  // IN:  ptr to FS context
            IntPtr pSubTrack,                   // IN:  ptr to subtrack
            out FSSUBTRACKDETAILS pSubTrackDetails);// OUT: subpage details
```
`Pts.cs:3749-3753`：
```
        internal static extern int FsQueryTextDetails(
            IntPtr pfsContext,                  // IN:  ptr to FS context
            IntPtr pPara,                       // IN:  ptr to text para
            out FSTEXTDETAILS pTextDetails);    // OUT: text details
```

### 1.2 调用点 × 实参（逐条：件:行 ＋ 原文）

**（a）`FsQuerySubtrackDetails` —— 10 处，实参一律 `_paraHandle`**：

| # | 件:行 | 原文 | 所属 body |
|---|---|---|---|
| 1 | `ContainerParaClient.cs:47` | `PTS.Validate(PTS.FsQuerySubtrackDetails(PtsContext.Context, _paraHandle, out subtrackDetails));` | `OnArrange()` |
| 2 | `ContainerParaClient.cs:89` | 同形 | `InputHitTest` |
| 3 | `ContainerParaClient.cs:142` | 同形 | `GetRectangles` |
| 4 | `ContainerParaClient.cs:177` | 同形 | `ValidateVisual` |
| 5 | `ContainerParaClient.cs:218` | 同形 | `UpdateViewport` |
| 6 | `ContainerParaClient.cs:240` | 同形（**在 `/* … */` 注释块内** ⇒ 死码；且 `ParaListFromSubtrack` 掉参，见 `:247`） | `CreateParagraphResult`（注释块） |
| 7 | `ContainerParaClient.cs:271` | 同形 | `GetTextContentRange()` |
| 8 | `ContainerParaClient.cs:325` | 同形 | `GetChildrenParagraphResults` |
| 9 | `ContainerParaClient.cs:375` | 同形 | `GetFirstTextLineBaseline` |
| 10 | `ListParaClient.cs:46` | `PTS.Validate(PTS.FsQuerySubtrackDetails(PtsContext.Context, _paraHandle, out subtrackDetails));` | `ValidateVisual` |

`ContainerParaClient.cs:277／283／289`（**该入口的"其后"＋消费者**）：
```
            if (subtrackDetails.cParas == 0 || (_isFirstChunk && _isLastChunk))
            {
                textContentRange = TextContainerHelper.GetTextContentRangeForTextElement(elementOwner);
            }
            else
            {
                PtsHelper.ParaListFromSubtrack(PtsContext, _paraHandle, ref subtrackDetails, out arrayParaDesc);
                …
                    paraClient = Paragraph.StructuralCache.PtsContext.HandleToObject(arrayParaDesc[i].pfsparaclient) as BaseParaClient;
```

**（b）`FsQueryTrackParaList` —— 唯一调用点 1 处**：

`PtsHelper.cs:604-618`（`ParaListFromTrack`）：
```
        internal static unsafe void ParaListFromTrack(
            PtsContext ptsContext, IntPtr track, ref PTS.FSTRACKDETAILS trackDetails,
            out PTS.FSPARADESCRIPTION [] arrayParaDesc)
        {
            arrayParaDesc = new PTS.FSPARADESCRIPTION [trackDetails.cParas];
            int paraCount;
            fixed (PTS.FSPARADESCRIPTION* rgParaDesc = arrayParaDesc)
            {
                PTS.Validate(PTS.FsQueryTrackParaList(ptsContext.Context, track, trackDetails.cParas,
                    rgParaDesc, out paraCount));       // ← 唯一调用点 :614
            }
            ErrorHandler.Assert(trackDetails.cParas == paraCount, ErrorHandler.PTSObjectsCountMismatch);
        }
```
⇒ 该入口的**实参 `track` 来自 `trackDesc.pfstrack`**（`PtsHelper.cs:134`：`ParaListFromTrack(ptsContext, trackDesc.pfstrack, …)`），**不是 `_paraHandle`**；其**出参** `pfsparaclient`／`pfspara` 才是句柄面（§2）。

**（c）`FsQueryTextDetails` —— 20 处，实参一律 `_paraHandle`**（`grep -c` 现取 ＝ **20**）：
`TextParaClient.cs:56`（首，`ValidateVisual`）原文：
```
            PTS.Validate(PTS.FsQueryTextDetails(PtsContext.Context, _paraHandle, out textDetails));
```
其余 19 处在 `TextParaClient.cs` 的 `:149／:194／:253／:345／:386／:424／:461／:517／:632／:685／:763／:831／:881／:924／:971…`（同形）。

### 1.3 实参 `_paraHandle` 的来源（唯一赋值点）

`BaseParaClient.cs:21／36-40／61-65／252`（现取逐字）：
```
    internal abstract class BaseParaClient : UnmanagedHandle
        protected BaseParaClient(BaseParagraph paragraph) : base(paragraph.PtsContext)
        {
            _paraHandle = IntPtr.Zero;
            _paragraph = paragraph;
        }
        internal void Arrange(IntPtr pfspara, PTS.FSRECT rcPara, int dvrTopSpace, uint fswdirParent)
        {
            // Make sure that paragraph handle (PFSPARA) is set. It is required to query paragraph content.
            Debug.Assert(_paraHandle == IntPtr.Zero || _paraHandle == pfspara);
            _paraHandle = pfspara;
        …
        protected IntPtr _paraHandle;      // :252
```
⇒ **全树唯一赋值点 ＝ `:65`**（`_paraHandle = pfspara`）。而**全树唯一调用 `Arrange(pfspara,…)` 的地方 ＝ `PtsHelper.cs:179`**（`grep -rn '\.Arrange(' …` 现取：`BaseParaClient.Arrange` 仅此一处；另两处 `TextParaClient.cs:1270/:1303` 是 `UIElement.Arrange`，`TableParaClient.cs:144` 是表格重载）：

`PtsHelper.cs:155-179`（`ArrangeParaList`）：
```
            for (int index = 0; index < arrayParaDesc.Length; index++)
            {
                BaseParaClient paraClient = ptsContext.HandleToObject(arrayParaDesc[index].pfsparaclient) as BaseParaClient;   // :158
                …
                paraClient.Arrange(arrayParaDesc[index].pfspara, rcPara, dvrTopSpace, fswdirTrack);                            // :179
            }
```
⇒ **`_paraHandle ＝ `FSPARADESCRIPTION.pfspara`（native 填的那一列）**。

### 1.4 三入口「实参面」小结（现取）

| 入口 | 实参 | 来源 | 现值形态（本趟真腿，§2.4） |
|---|---|---|---|
| `FsQuerySubtrackDetails` | `pSubTrack ← _paraHandle ← FSPARADESCRIPTION.pfspara` | native 填（`win32_pts.c:4321`＝**本侧自有子轨对象字段地址**；`win32_pts.c:4629`＝**窗内枚举出的子段句柄**） | 两形态**并存**：`0x5bdbff1b1054`（native 指针，可认领，`rc=0`）／`0x4`（**托管句柄**，不可认领，`rc=-10000`） |
| `FsQueryTextDetails` | `pPara ← _paraHandle ← FSPARADESCRIPTION.pfspara` | 同上 | 现场 **`para=0x4`（52/52 同值）** |
| `FsQueryTrackParaList` | `pTrack ← trackDesc.pfstrack` | `FsQueryTrackDetails` 出参（native 自有对象 `&pg->c_paras`，**可认领**） | 入参有源 ⇒ **不在本件"入参面"缺口内**；其缺口是**出参** `pfsparaclient` 的**托管句柄**（由 native 调 `+176` 现造） |

---

## §2 ② `para=0x4` 产出链现取（8 跳，件:行 ＋ 原文 ＋ 运行期证据）

> **总判词**：`0x4` 是**托管句柄**（＝ `PtsContext._unmanagedHandles` 的**槽位下标**，**可复用、非稳定身份**）；**由托管产出（`PtsContext.CreateHandle`）、经既有回调交给 native、native 再原样交回托管、托管又送回 native**。

### 2.1 产出链（逐跳，含现取原文）

| 跳 | 现取事实 | 现取位（原文） |
|---|---|---|
| **H1 唯一产地** | `PtsContext.CreateHandle(object obj)` 从 `_unmanagedHandles[0].Index` 取**空闲槽号**＝返回值 | `PtsContext.cs:175-195`：`long handle = _unmanagedHandles[0].Index; … return (IntPtr)handle;` |
| **H2 触发者** | `UnmanagedHandle` 构造器：`_handle = ptsContext.CreateHandle(this);` ⇒ **每个 `UnmanagedHandle` 派生对象（含 `BaseParagraph`／`BaseParaClient`）一诞生就占一个槽** | `UnmanagedHandle.cs:25-29`；`BaseParagraph.cs:22 class BaseParagraph : UnmanagedHandle`；`ContainerParagraph.cs:19 class ContainerParagraph : BaseParagraph, ISegment` |
| **H3 释放** | `UnmanagedHandle.Dispose()` → `ReleaseHandle(_handle)`（把槽号**压回自由链**） | `UnmanagedHandle.cs:34-45`；`PtsContext.cs:206-215`（`:213 _unmanagedHandles[handleLong].Index = _unmanagedHandles[0].Index;`） |
| **H4 第一次"交车"** | native 调 `+136 pfnGetFirstPara(pfsclient, nms, out fSuccessful, out nmp)`；托管实现 `Para.GetFirstPara` 把 **`nmp = _firstChild.Handle`** 交回 | native 驱动 `win32_pts.c:1611`；托管 `PtsHost.cs:586-611`（`ISegment segment = HandleToObject(nms) as ISegment; … segment.GetFirstPara(out fSuccessful, out nmp);`）；`ContainerParagraph.cs:159`：`firstParaName = (_firstChild != null) ? _firstChild.Handle : IntPtr.Zero;` |
| **H5 native 记住它** | native 把 `nmp` 收进本 doc 的**枚举账** `d->sub_children[]`，并记账 `sub_cparas` | `win32_pts.c:1617-1618`：`first = (const void *)nmp; d->sub_children[n++] = first;`（`+144` 循环在 `:1619-1636`） |
| **H6 native 又把它交回托管** | `FsQuerySubtrackParaList` 真填：`rg[i].pfspara = obj->children[i]`（＝H5 记下的托管句柄） | `win32_pts.c:4627-4631`：`rg[i].pfspara = (void *)obj->children[i]; rg[i].pfsparaclient = (void *)obj->child_clients[i]; rg[i].nmp = (void *)obj->children[i];` |
| **H7 托管收下 → `_paraHandle`** | `ParaListFromSubtrack`（`PtsHelper.cs:633`）填数组 → `ArrangeParaList`（`ContainerParaClient.cs:72`）→ `Arrange(arrayParaDesc[i].pfspara)`（`PtsHelper.cs:179`）→ `_paraHandle = pfspara` | `PtsHelper.cs:623-637`；`ContainerParaClient.cs:70-72`；`BaseParaClient.cs:65` |
| **H8 托管又送回 native** | `ContainerParaClient.cs:271`／`ListParaClient.cs:46` 用 `_paraHandle` 调 `FsQuerySubtrackDetails`；`TextParaClient.cs:56` 等用 `_paraHandle` 调 `FsQueryTextDetails` | §1.2 |

### 2.2 运行期证据（现取；件＝T‑A20 改后腿日志，**与现件代同代**）

**证据件**：`/home/links-dev/tA20-work/evidence-after/app_g1.log`（该腿 `DEV … shim=51fe76de3d8613de pf=1757d610a687777c` ＝ **现件代**；落**仓外**，非本席所写；**本席只读**）。
> ⚠️ 该目录是 `T-A20` 的车道产物；本席**未独立复算**其"同趟/同代"性质，只现取 `session.txt`／`leg_24.env` 的 `shim_sha16` 与现盘一致（＝`51fe76de3d8613de`）。

```
$ grep -m1 '^DEV' leg_24.env
DEV x_up=yes five_stable=yes shim=51fe76de3d8613de pf=1757d610a687777c
$ grep -c '\[SUBENUM\]' app_g1.log            # ⇒ 3
$ grep '\[SUBENUM\]' app_g1.log
[SUBENUM] where=FsCreatePageBottomless container=0x3 first=0x4 cparas=3 ok=1 rc136=0 rc144=0 child_max=32 v=ENUM-OK calls=1 ok_n=1 gap=0 window=in
（另两条同形：`cparas=3`／`cparas=1`，均 `v=ENUM-OK window=in`）
$ grep '\[FSQSTD\] rc=0 reason=ok' app_g1.log | head -1
[FSQSTD] rc=0 reason=ok entry=FsQuerySubtrackDetails ctx=0x5bdbfef49020 psub=0x5bdbff1b1054 calls=1 ok=1 gap=0 … out=WRITTEN bytes=40 cParas=3 true_cParas=3 nms=0x2 src=SUBENUM(+136/+144)
$ grep '\[FSQSTD\]' app_g1.log | sed 's/.*reason=\([a-z-]*\).*/\1/' | sort | uniq -c
    574 reason=ok
    414 reason=unclaimable-subtrack      ← psub=0x4（414/414）
      2 reason=null-subtrack
$ grep 'entry=FsQueryTextDetails' app_g1.log | sed 's/.*reason=\([a-z-]*\).*/\1/' | sort | uniq -c
     52 reason=unclaimable-para          ← para=0x4（52/52）
$ grep '\[FSPARALIST-FILL\]' app_g1.log | grep -o 'h0=0x[0-9a-f]*' | sort | uniq -c
    318 h0=0x5
     66 h0=0x7
    192 h0=0xb
$ grep -m1 '\[FSPARALIST-FILL\]' app_g1.log
[FSPARALIST-FILL] rc=0 reason=ok entry=FsQueryTrackParaList cParas=1 n=1 h0=0x5 src=managed-176 … off16=16 bytes0_32=00 00 00 00 00 00 00 00 54 10 1b ff db 5b 00 00 05 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00 …
                                               ↑+8 = pfspara = 0x5bdbff1b1054            ↑+16 = pfsparaclient = 0x5   ↑+24 = nmp = 0x3
```
⇒ **逐值闭合**：`[SUBENUM] first=0x4`（H4/H5）→ `FsQuerySubtrackParaList` 把 `0x4` 写进 `pfspara`（H6）→ 托管 `_paraHandle=0x4`（H7）→ `FsQuerySubtrackDetails psub=0x4` **414 次**、`FsQueryTextDetails para=0x4` **52 次**（H8）。

### 2.3 ⚠️ `0x4` **不是稳定身份**（现取实证；反腿 ②）

同一趟腿、同一 doc 内，**同一个数值 `0x4` 先后充当两种东西**：
```
$ grep -n 'nmp=0x4\|h1=0x4' app_g1.log | head
661:[NMP-TYPE] slot=GetFirstPara fserr=0 fSucc=1 nms=0x3 … nmp=0x4 TYPE=…ContainerParagraph …
666:[DRIVE-PROBE3] where=FsCreatePageBottomless window=in nmp176=0x3 … rc176a=0 h1=0x4 rc176b=0 h2=0x5 h2_ne_h1=1 … v176=PARACLIENT-NEW-PER-CALL(h1,h2)
```
⇒ `0x4` **先**是 `nmp`（段句柄，`.Handle` 产物），**后**是 `h1`（客户端句柄，`+176 CreateParaclient` 产物）⇒ **该数值是"槽位下标"（可复用），不是对象身份**。⇒ 任何人若按"数值相等"认对象，即落裁定四十五 (b)「**索引复用 ⇒ 静默错对象**」／裁定四十七 (c)「身份类判据不得依赖 `rc`／返回值形状」。

### 2.4 三入口的现件代真实面（现取收口）

| 面 | 值（现取） |
|---|---|
| `FsQuerySubtrackDetails` | `rc=0` **574**（`psub=`native 指针）／`rc=-10000 reason=unclaimable-subtrack` **414**（`psub=0x4`）／`null-subtrack` **2** |
| `FsQueryTextDetails` | `rc=-10000 reason=unclaimable-para` **52**（`para=0x4` **52/52**） |
| `FsQueryTrackParaList` | `[FSPARALIST-FILL] rc=0` **576**（`h0∈{0x5,0x7,0xb}`）；`[DRIVE-PROBE2-OOW]` 窗外腿 **577** 行（其中 `where=FsQueryTrackParaList` **576**，`v136=CALLBACK-ERR(-100002)` **576**；`where=FsDestroyPage` **1**，`REFUSED-NONLIVE-HANDLE`） |
| `[HC-UNHANDLED]` | **468** |

---

## §3 ② `PtsHost`／`PtsCache` 的句柄面（反查／导出面；合法使用性）

### 3.1 托管侧**已有**「句柄 → 对象」反查面（只读），但**不可从 native 直接调用**

`PtsContext.cs` 现取（**逐字**）：
```
:175  internal IntPtr CreateHandle(object obj)          // 正向：对象 → 句柄（唯一产地；只被 UnmanagedHandle :28 调）
:206  internal void    ReleaseHandle(IntPtr handle)     // 释放（唯一调用点：UnmanagedHandle :38）
:224  internal bool    IsValidHandle(IntPtr handle)     // 反查（**越界不 assert**，安全）
:228      if (handleLong < 0 || handleLong >= _unmanagedHandles.Length) { return false; }
:232      return _unmanagedHandles[handleLong].IsHandle();
:243  internal object  HandleToObject(IntPtr handle)    // 反查（越界/已释放 ⇒ Invariant.Assert ⇒ FailFast）
:247      Invariant.Assert(handleLong > 0 && handleLong < _unmanagedHandles.Length, "Invalid object handle.");
:248      Invariant.Assert(_unmanagedHandles[handleLong].IsHandle(), "Handle has been already released.");
:249      return _unmanagedHandles[handleLong].Obj;
:641  private struct HandleIndex { internal long Index; internal object Obj;
:645      internal bool IsHandle() { return (Obj != null && Index == 0); } }
:558  private HandleIndex[] _unmanagedHandles;          // 表本体（每 PtsContext 一张）
```
**结论（3.1）**：反查面＝**有**（`HandleToObject`／`IsValidHandle`）；但两者皆 **`internal`（PresentationFramework 程序集内）且无 P/Invoke、无 native 导出** ⇒ **native 只能经 `FSCBK` 回调槽间接使用它**。native 可达的、**吃托管句柄**的槽（现取 `Pts.cs` 的 `FSCBKGEN` 字段序 ＋ native 的 `_Static_assert` 绝对偏移；槽号**一律 1‑based**，照裁定五十四 (b)）：

| 槽（1‑based） | 名 | 绝对偏移 | 吃/吐的句柄 | 托管实现（现取） |
|---|---|---|---|---|
| cbkgen 第 13 槽 | `pfnGetFirstPara` | `+136` | 吃 `nms`（ISegment）／吐 `nmp` | `PtsHost.cs:586` |
| cbkgen 第 14 槽 | `pfnGetNextPara` | `+144` | 吃 `nms`＋`nmpCur`／吐 `nmp` | `PtsHost.cs:613` |
| cbkgen 第 17 槽 | `pfnGetParaProperties` | `+168` | 吃 `nmp` | `PtsHost.cs:700`（`HandleToObject(nmp) as BaseParagraph`） |
| cbkgen 第 18 槽 | `pfnCreateParaclient` | `+176` | 吃 `nmp`／吐 `pfsparaclient` | `PtsHost.cs:724` |
| cbkgen 第 20 槽 | `pfnDestroyParaclient` | `+192` | 吃 `pfsparaclient` | `PtsHost.cs:776` |
| cbkgen 第 21 槽 | `pfnFInterruptFormattingAfterPara` | `+200` | 吃 `pfsparaclient` | **禁用为判别器**（裁定四十五 (d)／`t156`：不读字段的恒绿 stub） |

装车/交车位现取：`build/PresentationFramework.Linux/PtsCache.Linux.cs:617-627`（`pfnGetFirstPara`／`pfnGetNextPara`／`pfnGetParaProperties`／`pfnCreateParaclient`／`pfnDestroyParaclient` 五个 `= new PTS.…(ptsHost.…)`）。

### 3.2 native 侧**已在用**这个句柄面（不是"没用过"）

`win32_pts.c` 现取：native 把 `FSCBK` **值拷贝**成快照（`:931-958`，`824 B／103 字`；`_Static_assert` 钉死 `+56/+80/+136/+144/+168/+176/+192/+200`），并**真调**其中若干槽：`wpf_pts_sub_enum`（`:1597-1647`，调 `+136`／`+144`）、`wpf_pts_drive_probe2`（`+136`／`+168`）、`wpf_pts_drive_probe3`（`+176`／`+192`）、`FsQuerySubtrackParaList`（`+176`，`:4616`）。
⇒ **native 已经"拿到句柄并合法使用过"**（`[SUBENUM] v=ENUM-OK`、`[DRIVE-PROBE3] v176=PARACLIENT-HANDLE`）。缺的**不是**访问面。

### 3.3 native 拿到句柄「能否合法使用」—— 照裁定四十五 (a)：**能跨调用持有**，但**可调用性受"造型窗"约束**

（i）**持有期（照裁定四十五 (a)，现取其链）**：`BaseParaClient.cs:21 (: UnmanagedHandle)` → `UnmanagedHandle.cs:28 (CreateHandle)` → `:38 (Dispose→ReleaseHandle)` → `PtsHost.cs:785 (DestroyParaclient 内 paraClient.Dispose())` ⇒ **`Case I`（持有期＝托管对象生存期）成立，可跨调用持有**；`Case II`（调用期有效）**判红**。
（ii）🔴 **可调用性 ≠ 可持有**：`pfnGetFirstPara` 的实现**读 `StructuralCache.CurrentFormatContext`** ⇒ **只在造型窗（`FsCreatePage*` 调用期）内可调**：
`ContainerParagraph.cs` 现取：`:105 StructuralCache.CurrentFormatContext.IncrementalUpdate`／`:112 …CurrentFormatContext.FinitePage`／`:151 if (StructuralCache.CurrentFormatContext.IncrementalUpdate)`。
**运行期实证（现取）**：
```
$ grep 'DRIVE-PROBE2-OOW.*where=FsQueryTrackParaList' app_g1.log | grep -o 'v136=[A-Za-z0-9()^-]*' | sort | uniq -c
    576 v136=CALLBACK-ERR(-100002)        ← nms136=0x2（窗内合法交出的段句柄），窗外调 +136 ⇒ -100002（callback-exception）
$ grep 'DRIVE-PROBE3-OOW' app_g1.log | head -1
[DRIVE-PROBE3-OOW] where=FsQueryTrackParaList window=out nmp176=0x3 pfsclient=0x1 rc176=0 h=0xb rc192=0 ctx_live=1 v=PARACLIENT-HANDLE(窗外)
```
⇒ **同族两个槽、同一窗外时刻**：`+136`（读 `CurrentFormatContext`）**失败**；`+176`（不读 format context）**成功**。⇒ **「窗口敏感性」在句柄面上是逐槽不同的**（这不是"句柄失效"，是**回调实现依赖窗内状态**）。

> ⚠️ **射程（照 `P9`：否定性结论必须写清射程）**：`-100002 ×576` 的读数**取自 `FsQueryTrackParaList` 内的窗外腿**（native 主动插桩），**不是**在 `FsQuerySubtrackDetails` 调用点直接插桩 ⇒ "三入口在调用期不可枚举"是**推断**（judgment，`NOINFO-HOSTFACE-WINDOW-AT-GAP-SITE`），**不是**实测；但它与本件所有调用点同属「**查询期**」（`GetTextContentRange`／`ValidateVisual`／`GetRectangles`／… 均非 `FsCreatePage*` 调用期）。

### 3.4 `PtsCache`（生成件）与 `P8` 落点

`build/PresentationFramework.Linux/PtsCache.Linux.cs` 是**生成件**（`reapply-patches.py:116` `Compile Include=…PtsCache.Linux.cs`；`csproj:1516` `Compile Remove=…PtsHost/PtsCache.cs` ＋ `:1517` `Include=…PtsCache.Linux.cs`）。其改动集**只**由生成器的 `PTSCACHE_EDITS` 施加（`reapply-patches.py:1101-1110`，八个编辑 `E0/E1/E2/E3/E4/E5/E5B/E6`）。⇒ **任何涉及 `PtsCache.Linux.cs` 的设计，落点一律写「改生成器 `PTSCACHE_EDITS`」（铁律 `P8`）**。
另：`Pts.cs`／`PtsContext.cs`／`PtsHelper.cs`／`ContainerParaClient.cs`／`TextParaClient.cs` 现取**都是直编的上游件**（`csproj:290/321/322/323/324/340`；**只有** `PtsCache.cs` 被 `Remove` 换成移植件）⇒ **改 `FSCBK` 布局要动上游 `Pts.cs`**，不在本仓移植写域内。

---

## §4 ③ 候选路（甲／乙／丙）逐条：可及 ∧ 可行 ∧ 代价 ∧ `P8` 落点

> 逐条给"**该路要求谁改什么**"，并在末尾给**判定**。

### （甲）托管侧**把所需句柄／表备好**（native 只读消费）

| 维度 | 现取判词 |
|---|---|
| **可及性** | **已可及** —— 句柄**已在位**（`PtsContext.CreateHandle` 产出，经 `+136/+144/+176` 的 OUT 参数交给 native；`[SUBENUM] v=ENUM-OK`／`[FSPARALIST-FILL] h0=0x5` 现取）。 |
| **可行性** | 🔴 **作为"只读消费出内容"不可行**：native **不能**读托管内存（GC 可搬移；`win32_pts.c:120-131` 自陈 `use-after-return` 纪律）；要 native 能"只读消费出 `cParas/nms/fsrc`"，只能**新增一个"句柄→信息"的 `FSCBK` 槽** ⇒ ① 改结构体要动**上游 `Pts.cs` 的 `FSCBKGEN`**（直编件）；② 增槽会**平移后续槽偏移** ⇒ 破 native 的 `824 B／103 字` 与 `+136/+144/+168/+176/+192/+200` 全套 `_Static_assert`（`:1093-1131`）；③ 且**语义上是把 native 该算的东西挪给托管算**（与裁定五十一 (b)「准入 ＝ 本侧是该值的作者」相冲：`cParas` 的作者应是**本侧枚举驱动**）。 |
| **代价** | **高**（上游 `Pts.cs` ＋ 生成器 ＋ native 快照索引/断言 三处联动；且并未消掉 `N2` 的窗口约束 —— 仍得在窗内才拿得到）。 |
| **`P8` 落点** | `PtsCache.Linux.cs` 是生成件 ⇒ **改生成器 `PTSCACHE_EDITS`**（`reapply-patches.py:1101`）；**另需**改上游 `Pts.cs`（**非生成件、非本仓移植写域**）。 |
| **判定** | **不可取**（非必要 —— 已有 乙 的同义信道；且触及上游 ABI）。 |

### （乙）native 经**已有回调**（`fscbk` 槽）主动获得句柄／信息

| 维度 | 现取判词 |
|---|---|
| **可及性** | **可及** —— `+136`／`+144`／`+168`／`+176`／`+192` **已在 native 快照内**（`_Static_assert` 就位），且 **native 已真调**（`[SUBENUM]`／`[DRIVE-PROBE3]`）。 |
| **可行性** | **窗内可行／窗外不可行**（现取：`+136` 窗外 `rc=-100002` **×576**，`+176` 窗外**成功**）⇒ 对**三入口**（查询期调用）**当前不可行**；若把"枚举/内容模型"提前到**窗内**建好并缓存，则**可行**——但那正是 `N2`，**属 native 写域**。 |
| **代价** | **中**（native 侧：窗内递归枚举 ＋ 台账；`win32_pts.c` 已有 `SUBENUM` 骨架可扩）。 |
| **`P8` 落点** | **不涉生成件** —— `src/WpfGfx.Linux.Native/src/win32_pts.c`（＋ `bin/exports.txt` 若增导出）。 |
| **判定** | **唯一有合法信道且零托管改动的路**；**其解除条件全在 native 写域**。 |

### （丙）其它

| 候选 | 可及 | 可行 | 代价 | `P8` 落点 | 判 |
|---|---|---|---|---|---|
| **(丙‑1)** 让 `FsQuerySubtrackParaList` 的 `pfspara` 改填**本侧自有的子轨对象**（对每个子段现造一个 `wpf_pts_sub_new`），使 `_paraHandle` **成为本侧可认领的指针**（承 `FsQueryTrackDetails` 范式） | 是（`win32_pts.c:4267-4288` 已有 `wpf_pts_sub_new` 范式） | **是**（`_paraHandle` 变 native 指针 ⇒ `wpf_pts_sub_claim` 通过） | **中**（native 侧：每子段一个在册对象 ＋ 计数/回收口径） | `win32_pts.c` | **可行（native 侧）** |
| **(丙‑2)** 扩展 `wpf_pts_sub_claim` 身份模型：接受「**本 run 由 `+136/+144` 枚举交回的句柄**」（native 自记 `sub_children[]`） | 是 | **部分**（能认身份；但**认出来也算不出该段自己的 `cParas`** —— 仍需它的子段 ⇒ 回到窗内枚举） | 中 | `win32_pts.c` | **不足**（认身份 ≠ 有内容） |
| **(丙‑3)** 请托管在窗内**主动把 `cParas/nms/fsrc` 经既有 OUT 参数捎出**（改上游 delegate 签名） | 是 | 需改上游 `Pts.cs` 签名 ＋ 生成器 ＋ native 调用点 | 高 | `PTSCACHE_EDITS` ＋ 上游 `Pts.cs` | **不可取** |

---

## §5 ④ 结论 ＝ 判「托管侧无可做项（不可行）」＋ 合法终点 ＋ 具名前置清单

### 5.1 判词（写死）

> **就「托管侧能否提供」作答：托管侧的句柄面**已经完备**——它**产出了**句柄（`PtsContext.CreateHandle`）、**交出了**句柄（经 `+136/+144/+176` 的 OUT 参数）、**并已提供了**反查面（`HandleToObject`／`IsValidHandle`，经既有槽可达）。⇒ 本任务在托管侧**无新工作可做**（**不是**"托管侧不能提供"）。
> 三个入口的入参面**不可认领**的**真正原因有两条，均在 native 写域**：
> **`(N1)` 身份模型**：`wpf_pts_sub_claim` 只认「**本侧对象字段地址等值**」，不认「**回调刚交回、native 又交回托管的托管句柄**」。
> **`(N2)` 窗内枚举 vs 窗外汇总分离**：内容模型（子段序／计数）**只能在 `FsCreatePage*` 造型窗内建**（`pfnGetFirstPara` 读 `StructuralCache.CurrentFormatContext`；窗外实测 `-100002`），而三入口**在查询期**被调。
> ⇒ **判定：托管侧不可行 ⇒ 合法终点（不落地、不改托管）**；解除条件见 §5.2。

### 5.2 具名前置清单（因判"托管侧无可做项"）

| 前置 | 射程 | 状态／归属（现取） |
|---|---|---|
| **`PRECOND-NATIVE-CLAIMS-CALLBACK-HANDLES`** | `wpf_pts_sub_claim` 的**身份模型**：需接受「本 run 由 `+136/+144` 枚举交回、并由本侧写进 `FSPARADESCRIPTION.pfspara` 的托管句柄」（＝ `sub_children[]` 在册值） | **成立**（现取 `win32_pts.c:4303 wpf_pts_sub_claim(para_val,…)` 对 `0x4` 返 0）。**归属＝native 写域** |
| **`PRECOND-MANAGED-HANDLE-TABLE`**（承 `P1-tail2-next-recon.md` §5） | 出参 `pfsparaclient`／`nmp` 需可经 `HandleToObject` 反查 | **已满足**（托管**已**产出并交出；反查面在位，§3.1）⇒ **本件把它归位为"已解决"**（与既载"成立：native 无合法来源"**更新**：native**有**合法**取得**渠道，缺的是**认领**） |
| **`PRECOND-WINDOW-SEPARATION`** | 内容模型须在**窗内**建、三入口在**窗外**调用 | **成立**（`+136` 窗外 `-100002` ×576 现取；§3.3）。**归属＝native 写域**（窗内预枚举＋缓存 ⇒ 即"native 自有段落模型"） |
| **`PRECOND-NATIVE-OWNS-A-PARAGRAPH-MODEL`**（承 `P1-native-para-model-report.md` §3） | 窗内递归枚举（每段自己的子段序）＋ 台账 | **未解除**；**归属＝native 写域** |
| `PRECOND-NO-MANAGED-SIDE-WRITER`（承 `P1-paralist-wire-report.md`／裁定四十七 (e)） | 托管 `.cs`；粒度＝单次调用 | **未解除**（托管侧协作者无落点） |
| `PRECOND-FRAME-DETERMINISM` | 帧面类要件 | **未满足**（冻结令维持，裁定四十二 (b)） |

### 5.3 若日后做（**本波不做，仅登记供排期；属 native 写域**）—— 设计草案 ＋ 判据草案

> ⚠️ 本节**不是**本任务的落地提议（本任务只读）。它只是把 §4 的 `(乙)＋(丙‑1)` 合起来写成**可判形态**，供 native 写者取用。

**设计草案（3 步，一步一判）**
1. **窗内建账**：在 `FsCreatePage*` 窗内（`wpf_pts_sub_enum` 现成骨架）**递归**枚举：对每个枚举出的子段句柄 `H`，再以 `H` 为 `nms` 调 `+136/+144`，得 `H` 的子段序 ⇒ 存进 doc 台账（有界 ＋ 成环守卫，照 `:1593-1636`）。
2. **交回本侧对象**：`FsQuerySubtrackParaList` 的 `pfspara` 改填**本侧自有子轨对象**（`(丙‑1)`，`wpf_pts_sub_new` 范式），使 `_paraHandle` 成为本侧可认领指针。
3. **窗外汇总**：`FsQuerySubtrackDetails`／`FsQueryTextDetails` 在外层查询期**只读本侧台账**回答（**零回调**）；未造型/未建账 ⇒ **拒**。

**判据草案（≥3 条可证伪 ＋ 反极性）**

| # | 判据（可证伪） | 反极性（必红腿） |
|---|---|---|
| **D1 零假值／出参纪律** | 拒绝路径出参**一字不写**（照 `FsQueryTextDetails` 现状 `out=UNWRITTEN bytes=0`）。 | 为让 `rc=0` 好看写常量 `cParas` ⇒ **必红**（`P8` 恒绿陷阱：`cParas=0` 会走 `ContainerParaClient.cs:277` 叶子分支、静默丢整棵嵌套内容）。 |
| **D2 永不假成功** | `rc=0` **仅当**：`cParas`＝窗内枚举真值 ∧ `nms` 可认领 ∧ `fsrc` 有几何源。今天不满足 ⇒ **必须返非 0**。 | 返 `rc=0` ＋ 常量 ⇒ 伪成功 ⇒ **必红**。 |
| **D3 失败必留痕** | 任何拒绝**必**打具名行（`entry=` ＋ `reason=` ＋ `calls/ok/gap`）且 `gap` **恰涨 1**（照 `[FSQSTD]`／`[FSQSPL]` 现状）。 | 静默 stub（返非 0 零痕迹）⇒ 与"真 0 次调用"不可分 ⇒ **必红**（裁定二十三 ①）。 |
| **D4 身份只许靠来源证据** | `pSubTrack`／`pPara` 必须能被**本侧台账唯一认领**，且与同 run 产出行**同值**。 | 按**数值相等**认对象 ⇒ **必红**（§2.3 现取：`0x4` 同趟先后当过段句柄与客户端句柄；裁定四十五 (b)／四十七 (c)）。 |
| **D5 窗内/窗外分开报** | **窗内建账数**与**窗外汇总数**分开判词；**不**把"窗内可得"读成"调用期可得"。 | 把窗内 `[SUBENUM] ENUM-OK` 读成"查询期已可答" ⇒ **必红**（本件 `P13` 新面）。 |
| **D6 ≥2 独立样本** | ≥2 独立 PID／启动时刻，判词**相同**（裁定三十八）。 | 单样本当机制 ⇒ **必红**（`P9`）。 |

---

## §6 边界 · `NOINFO` · 主动披露

1. **未改任何仓内文件（除本载体）**；**未构建**；**未跑整趟 `verify-all`**／`static-jaws-check.sh`；**未占显示位**；未 `git add/commit/push`。现取 `git status --porcelain`（**仅两项 untracked，均先于本件**）：
```
?? build/MilBridge/tasks-tail2/T-A21.md
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log
```
2. **引他人读数（标「未独立复算」）**：§2.2 的运行期计数取自 `T-A20` 车道产物 `/home/links-dev/tA20-work/evidence-after/app_g1.log`（**仓外**；本席**只**现取它的 `sha16`／`grep -c` 输出，**未复跑腿**）；裁定四十五 (a) 的持有期链**引自 `P1-ptsname-result.md`** 与 `P1-paralist-wire-report.md` 判据（**未独立复算其探针读数**）。**本席自算**的只有：§1／§2／§3 的 `grep`／`sed`／`sha256sum` 现取 ＋ §2.2 的计数。
3. **`NOINFO`（逐条给消掉条件）**：
   - `NOINFO-HOSTFACE-WINDOW-AT-GAP-SITE`：**在 `FsQuerySubtrackDetails`/`FsQueryTextDetails` 调用点**直接插桩测"窗外 `+136` 是否失败"的读数（今天只有**同族** `FsQueryTrackParaList` 的窗外腿 `-100002 ×576`）⇒ 消掉需 native 侧在**该调用点**加一趟具名腿。
   - `NOINFO-HOSTFACE-HANDLE-ALIVE-AT-GAP`：`_paraHandle=0x4` 在**调用那一刻**是否仍是**live** 槽（本席只有"它当次可用"的间接证据 —— `[SUBENUM] first=0x4` + 后续 414 次同值；**无**进程内 liveness 实测）⇒ 消掉需托管侧只读观测面（`IsValidHandle`，`P1-managed-handle-report.md` §C2 已给可行路径，**未独立复算**）。
   - `NOINFO-MANAGED-TABLE-INTERNAL-EXPORT`：托管句柄表**能否**在不破 `FSCBK` 布局的前提下导出（本席只给"现有导出面＝0"的静态判词）⇒ 消掉需一次真正的托管改动试验（**不在本件写域**）。
4. **前提不符（如实记）**：派单 ① 的两处文字与现取不符（`PtsHost.CreateHandle` **不存在**；`build/PresentationFramework.Linux/**` **无调用点**）⇒ 本件在 §0／§1.0 现取更正。
5. **代际**：`.so`＝`51fe76de3d8613de`；`win32_pts.c`＝`681bd74cd62fc287`；`PtsCache.Linux.cs`＝`e5b399fdb8742092`；全部托管上游件指纹见件头（**本件未改它们**）。
6. **本件自带的两条反腿**：① §3.3 —— 不把"窗内可得"读成"调用期可得"；② §2.3 —— 不把"数值相同"读成"同一个对象"。
7. **未做**：未判相位；未动任何牙本体；未跑任何门禁。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-hostface-recon.md | sha256sum | cut -c1-16`）= `b654a72300c2782b`
