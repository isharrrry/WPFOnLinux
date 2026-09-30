# P1-tail2 `T-A14` · 新读数定位：`ArgumentOutOfRangeException` 561 ＋ 下一步选靶 —— 只读侦察

- **读时**：`2026-09-30T~12:5x+0800`（本席现取）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，`HEAD=c5049a6`（现取）；`git status --porcelain` 现取仅两处 `??`（`tasks-tail2/T-A14.md` 任务书 ＋ 在册既有 `tests/PtsPagesProbe/evidence/arm_A/app_g1.log`）—— **均先于本件存在**，本件**未改任何仓内文件**（唯一写入＝本载体）。
- **件指纹（现取，`sha256` 前 16 位）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`＝`a1820ad87bd63b79`｜`bin/libwpfwin32.so`＝**`e887b27a86b275ff`**｜`upstream/…/PtsHost/Pts.cs`＝`1a8575a18767a956`｜`PtsHelper.cs`＝`f2ed9552e983fed1`｜`PtsPage.cs`＝`70be7828e8f9650d`｜`ContainerParaClient.cs`＝`0d2e6aa79fdc035a`｜`TextParaClient.cs`＝`be3e7a145113dca5`｜`FlowDocumentPage.cs`＝`cd4d1c09c3edef3f`｜`PresentationCore/…/Media/VisualCollection.cs`＝`59e38ae69c8e8b1d`。
- **读数来源（如实划界）**：**改前**＝在册 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2/app_g1.log`（`log_sha16=5533298d4dc75eab`，**非本席同趟重取**）；**改后**＝`T-A12` 落地的三条缺省腿证据 `/home/links-dev/tA12-work/evidence-default{,2,3}/app_g1.log`（`evidence-default` `log_sha16=157ce8df7a1c4a63`）＋反腿 `evidence-off`／`evidence-rev-fake999`／`evidence-rev-zero`。**装置／腿器／`pf=1757d610a687777c` 两侧一致**。
- **行号纪律**：本件所有行号**仅本次有效**（内容锚原文一并给出）。
- **边界**：**只读**；未构建、未跑腿、未占显示位、未跑整趟 `verify-all`、未跑 `static-jaws-check.sh`；大文件只用 `wc/head/tail/grep/awk`；进程只按 PID（未起进程）。

---

## §0 结论速览（自包含）

1. **出处链（现取＋源码闭合）**：AOOORE 的抛出点＝`PresentationCore` **`System.Windows.Media.VisualCollection.this[int index].get`**（`VisualCollection.cs:316-317` 的 `ThrowIfGreaterThanOrEqual(index, _size)`），**调用它的那一句**＝`PresentationFramework` **`MS.Internal.PtsHost.PtsPage.UpdatePageVisuals`**（`PtsPage.cs:1042` `ContainerVisual trackVisual = (ContainerVisual)visualChildren[0];`），此时 `visualChildren`（＝`pageContentVisual.Children`）**为空集合**（`_size==0`、`index==0`）。
2. **触发者（我方返回值）**：**`FsQueryPageDetails`** 的 `FSPAGEDETAILS.fskupd` 恒写 **`0`＝`fskupdInherited`**（该结构**整体 `memset` 后从不再写这一格**，`win32_pts.c:3513-3519`）——而上游 `Pts.cs:1695` 的原文注释写死该格**只可能是** `fskupdNew/fskupdChangeInside/fskupdNoChange`。⇒ `PtsPage.cs:1029` 的 `fskupd == fskupdNew` 判否 ⇒ 永不建轨视觉 ⇒ `:1042` 对**空** `VisualCollection` 取 `[0]` ⇒ 抛。
3. **`T-A12` 的角色＝"使能"而非"造错"**：承重格放行（`FsQuerySubtrackDetails` 返 `rc=0`）让**排布帧**首次**不抛** ⇒ **同一趟的页视觉帧**首次被走到 `:1042`。**独立佐证（现取）**：`rev-fake999`（`FsQuerySubtrackParaList` 拒 ⇒ 排布帧抛 `PtsException`）AOOORE **0**；`rev-zero`（`cParas=0` ⇒ 排布帧不抛且**根本没有** `[FSQSPL]`）AOOORE **2**、且紧跟在 `[FSQSTD]` 之后 ⇒ **AOOORE 与 `[FSQSPL]`／`ValidateVisual` 无关**，只与"排布帧是否抛"有关。
4. **性质判定**：**「前进（更深消费者被走到）」×「旧有缺陷被首次暴露」**；**否决**「新缺陷（我方返回值越界）」与「`T-A12` 造错」。逐条依据见 §2。
5. **`[FSQSPL]` 面**：调用点＝`PtsHelper.ParaListFromSubtrack`（`PtsHelper.cs:623-637`，**唯一** `PtsHelper.cs:633`），排布帧调用者＝`ContainerParaClient.OnArrange:70`；入参 `(ctx, subtrack, subtrackDetails.cParas, rgParaDesc, out paraCount)`；我方返 `rc=0` ＋ 逐槽 `{pfspara=children[i], pfsparaclient=child_clients[i], nmp=children[i], dvr*=0, bbox=0, fsupdinf.fskupd=0}`；消费者期望＝`new FSPARADESCRIPTION[subtrackDetails.cParas]`（`:629`）＋ `ErrorHandler.Assert(cParas == paraCount)`（`:636`）。见 §3。
6. **唯一选靶**：**修 `FsQueryPageDetails` 的 `FSPAGEDETAILS.fskupd` 语义**（首次 `fskupdNew`／稳态 `fskupdNoChange`，**不得**再写 `fskupdInherited`）＋ 同趟加**机读留痕**，使 AOOORE 归零**可现取**。判据草案 `D1–D5` 见 §4（逐条带反极性）。
7. **具名 `NOINFO`**（逐条给消掉条件）见 §6。

---

## §1 出处链现取（③ 抛出点 ／ 触发者）

### 1.1 抛出点：`VisualCollection` 索引器（**可由抛出原文唯一确定**）

现取逐字（`evidence-default/app_g1.log:5021-5022`，`#428`，**仅本次有效**）：
```
[HC-UNHANDLED] #428 ArgumentOutOfRangeException: index ('0') must be less than '0'. (Parameter 'index')
Actual value was 0. ｜ 首帧 at System.ArgumentOutOfRangeException.ThrowGreaterEqual[T](T value, T other, String paramName)
```
- **栈顶**（现取逐字，第三方钩子只记 `StackTrace` 首帧）＝`System.ArgumentOutOfRangeException.ThrowGreaterEqual[T](T value, T other, String paramName)`。
- **异常原文**＝`index ('0') must be less than '0'. (Parameter 'index')` ＋ `Actual value was 0.`。
- `.NET 9+` 里 `ThrowGreaterEqual(value, other, paramName)` 的语义＝"`value >= other` 则抛"，报文 `"{paramName} ('{value}') must be less than '{other}'."`；`paramName` 来自 `CallerArgumentExpression` ⇒ **实参表达式就叫 `index`**。⇒ 现取三个常量**全部钉死**：`index=0`、`other(_size)=0`、`paramName="index"`。

**唯一定位**（`upstream/…/PresentationCore/System/Windows/Media/VisualCollection.cs`，`sha16=59e38ae69c8e8b1d`，`:308-319` 逐字）：
```csharp
public Visual this[int index]
{
    get
    {
        // We should likely skip the context checks here for performance reasons.
        // The guy who gets the Visual won't be able to access the Visual anyway if he is in the wrong context.
        // MediaSystem.VerifyContext(_owner);

        ArgumentOutOfRangeException.ThrowIfNegative(index);
        ArgumentOutOfRangeException.ThrowIfGreaterThanOrEqual(index, _size);   // ← :317 抛出点
        return _items[index];
    }
```
⇒ `VisualCollection` 的 **`get` 访问器**在 `_size==0` 时对 `index==0` 抛**正是**该报文（`set` 访问器 `:324-325` 同形，但本链无"赋值越界"证据）。**件:行 ＝ `PresentationCore/System/Windows/Media/VisualCollection.cs:316-317`**。

> 候选排除：仓内**没有**任何 `ThrowGreaterEqual`／`ThrowGreaterThanOrEqual` 的**调用点**写在 `build/**`／`src/**`／`shims/**`（现取 `grep -rn` 命中 0，除 `build/PresentationFramework.Linux/TextBox.Linux.cs:248` 等 4 处 `ThrowIfGreaterThanOrEqual(lineIndex, LineCount)`——`paramName` 会是 `lineIndex`，报文不符）；上游 `GetVisualChild(int index)` 类候选（如 `MS/Internal/documents/TextBoxView.cs:503` 的 `ThrowIfGreaterThanOrEqual(index, this.VisualChildrenCount)`）**同形可抛**，故"件:行"的**最终定钉靠 §1.2 的调用相邻性**，不靠报文本身。

### 1.2 调用者：`PtsPage.UpdatePageVisuals`（**由"零中间日志"的相邻性定钉**）

现取：`[FSQSPL]` 行与 AOOORE **逐条紧邻、中间无任何其它行**（`awk` 全域核过：988 条 `[FSQSPL]` 中 561 条后随 AOOORE、427 条后随 `[FSQSTD] unclaimable-subtrack`；**从不夹带别行**）：
```
$ awk '/^\[FSQSPL\]/{getline n; if(n ~ /HC-UNHANDLED/) t++; else o++} END{print "throw="t" other="o}' evidence-default/app_g1.log
throw=561 other=427
```
⇒ 抛点必落在"**在 `[FSQSPL]` 之后、下一条被插桩的 native 调用之前**"的托管代码里。逐行核 `ContainerParaClient.ValidateVisual`／`OnArrange` 两条同形前驱之后的**全部**语句（`ContainerParaClient.cs:41-74`／`:173-206`），只有一处对 `VisualCollection` 取下标，且**只有它在"排布帧成功"时才可达**（§1.2.2 的反腿独立佐证）。

**`PtsPage.UpdatePageVisuals`**（`PtsPage.cs`，`sha16=70be7828e8f9650d`，`:989-1043` 逐字摘）：
```csharp
private void UpdatePageVisuals(Size arrangeSize)
{
    Invariant.Assert(!IsEmpty);
    VisualCollection visualChildren;

    // Get page details
    PTS.FSPAGEDETAILS pageDetails;
    PTS.Validate(PTS.FsQueryPageDetails(PtsContext.Context, _ptsPage, out pageDetails));   // :996  ← 我方入口

    // If there is no change, visual information is valid
    if (pageDetails.fskupd == PTS.FSKUPDATE.fskupdNoChange) { return; }                    // :999  ← 0 != NoChange(1) ⇒ 不返回
    ErrorHandler.Assert(pageDetails.fskupd != PTS.FSKUPDATE.fskupdShifted, ...);           // :1000 ← 0 != Shifted(4) ⇒ 不报

    if(_visual.Children.Count != 2) { _visual.Children.Clear(); _visual.Children.Add(new ContainerVisual()); _visual.Children.Add(new ContainerVisual()); }   // :1005-1010
    pageContentVisual = (ContainerVisual)_visual.Children[0];                              // :1012  ← Count==2，安全
    floatingElementsVisual = (ContainerVisual)_visual.Children[1];                         // :1013  ← 安全

    if (PTS.ToBoolean(pageDetails.fSimple))                                               // :1019  ← 我方 fSimple=1 ⇒ 真
    {
        PTS.FSKUPDATE fskupd = pageDetails.u.simple.trackdescr.fsupdinf.fskupd;            // :1023  ← 同趟 memset ⇒ 0
        if (fskupd == PTS.FSKUPDATE.fskupdInherited) { fskupd = pageDetails.fskupd; }       // :1024-1027 ← 0==Inherited ⇒ fskupd=0
        visualChildren = pageContentVisual.Children;
        if (fskupd == PTS.FSKUPDATE.fskupdNew) { visualChildren.Clear(); visualChildren.Add(new ContainerVisual()); }  // :1029-1033 ← 0 != New(2) ⇒ **不建轨视觉**
        else if (visualChildren.Count == 1 && visualChildren[0] is SectionVisual) { ... }   // :1036 ← Count==0 ⇒ 短路，安全
        Debug.Assert(visualChildren.Count == 1 && visualChildren[0] is ContainerVisual);   // :1041 ← release 下**无效**
        ContainerVisual trackVisual = (ContainerVisual)visualChildren[0];                  // :1042 ← **空集合取 [0] ⇒ AOOORE**
        PtsHelper.UpdateTrackVisuals(PtsContext, trackVisual.Children, pageDetails.fskupd, ref pageDetails.u.simple.trackdescr);  // :1043 ← 本该是下一条 native 调用（`FsQueryTrackParaList`）
    }
```
⇒ **抛出点调用行 ＝ `PtsPage.cs:1042`**（`_size==0`、`index==0` 与 §1.1 的现取三常量**逐字相符**；`:1012/1013` 有 `Count==2` 前置守卫、`:1036` 有 `Count==1` 前置守卫 ⇒ 全不可抛；`:1041` 的 `Debug.Assert` 在 release **不生效**）。

**它为什么会"零中间日志"**：`:1043` 之前**唯一**的 native 调用是 `:996` 的 `FsQueryPageDetails`，而它**成功路径不打印**（只在失败打 `[FS_PAGE_GAP]`，`win32_pts.c:3527`）⇒ 页视觉帧在 `:1042` 抛出时**不产生任何日志行** ⇒ 日志上只看到"上一趟排布帧的 `[FSQSPL]` → 紧接 AOOORE"。**这不是推理缺口，而是"守卫行 + 零日志"共同定钉的**。

**上层入口（现取链）**：`PtsPage.GetPageVisual()`（`PtsPage.cs:605-613`，`:613` 调 `UpdatePageVisuals(_calculatedSize)`）← `FlowDocumentPage.UpdateVisual()`（`FlowDocumentPage.cs:842`，`:857` `pageVisual = _ptsPage.GetPageVisual();`）← `FlowDocumentPage.EnsureValidVisuals()`（`:607-611`）← 视图侧 `TextDocumentView.cs:67/94/120/238` 与 `FlowDocumentFormatter.cs:82/121`（`TextDocumentView(FlowDocumentPage owner, …)` ⇒ **RichTextBox 走的就是这条路**）。

### 1.3 触发者：我方 `FsQueryPageDetails` 的 `fskupd`（**契约非法值**，恒 0）

现取我方实现（`win32_pts.c:3499-3523`，`sha16=a1820ad87bd63b79`）：
```c
int FsQueryPageDetails(void *pfscontext, void *pPage, void *pPageDetails)
{   ...
        wpf_pts_fspagedetails_head *d = (wpf_pts_fspagedetails_head *)pPageDetails;
        memset(d, 0, sizeof(*d));                 /* 先清（**不留残留**），再逐字段填 */
        d->fSimple    = 1;                        /* 简单页 ⇒ 托管侧只读 trackdescr 两格 */
        d->r_u = 0;  d->r_v = 0;  d->r_du = pg->pg_w; d->r_dv = pg->pg_h;
        d->td_pfstrack = (void *)&pg->c_paras;
        d->b_defined = pg->bbox_defined; ...
        return 0;                                 /* ⇒ 成功，且**不打印** */
```
而结构首格注释写死（`win32_pts.c:3472`）：`unsigned int pad0; /* fskupd（FSPAGEDETAILS.fskupd，4 B） */` ⇒ **`memset` 之后从不再写 ⇒ `fskupd ≡ 0`**。同趟 `pre[8]`（＝`trackdescr.fsupdinf`）也被 `memset` 成 0 ⇒ `:1023` 读到的也是 `0`。

**契约原文**（`Pts.cs:1693-1696`，逐字）：
```csharp
internal struct FSPAGEDETAILS
{
    internal FSKUPDATE fskupd; // only fskupdNew/fskupdChangeInside/fskupdNoChange are possible
    internal int fSimple;
```
枚举（`Pts.cs:1934-1941`）：`fskupdInherited=0, fskupdNoChange=1, fskupdNew=2, fskupdChangeInside=3, fskupdShifted=4`。
⇒ 我方写的是 **`fskupdInherited`(0)——上游明确排除的那个值**；且 `:1024-1027` 的"继承"分支把它**原样传下去** ⇒ `:1029` 永不成立 ⇒ `pageContentVisual.Children` **恒空** ⇒ `:1042` 必抛。

### 1.4 因果链（一环一现取）

| # | 环 | 现取证据 |
|---|---|---|
| ① | 排布帧：`ArrangeTrack`（`PtsHelper.cs:134`）→ `ParaListFromTrack` | `[FSPARALIST-FILL] … entry=FsQueryTrackParaList`（988 条／改前 1217 条） |
| ② | → `ContainerParaClient.OnArrange:47`：`FsQuerySubtrackDetails` | `[FSQSTD] rc=0 reason=ok … cParas=1 true_cParas=1 … out=WRITTEN bytes=40 src=SUBENUM(+136/+144)`（**`T-A12` 的成功分支**；改前同点为 `rc=-10000 reason=no-layout-content-model`） |
| ③ | → `:70`：`ParaListFromSubtrack` → `FsQuerySubtrackParaList` | `[FSQSPL] rc=0 reason=ok … cParas=1 made=1 cli_total=7 src=SUBENUM(+136/+144)+managed-176` |
| ④ | → `:72`：`ArrangeParaList` → 子段 `TextParaClient.Arrange` → `OnArrange` **早退** | `TextParaClient.cs:1226-1234`：`if(!TextParagraph.HasFiguresFloatersOrInlineObjects()) return;`（`TextParagraph.cs:1352-1360` 纯判空，**不抛**）⇒ **排布帧无异常** |
| ⑤ | 同趟页视觉帧：`EnsureValidVisuals` → `FlowDocumentPage.UpdateVisual:857` → `GetPageVisual:613` → `PtsPage.UpdatePageVisuals:996` | `FsQueryPageDetails` **成功且不打印**（现取：全日志 `^\[FS_PAGE_GAP\]` 命中 **0**） |
| ⑥ | → `:1029` 判否（`fskupd=0`）⇒ `:1042` 空 `visualChildren[0]` | AOOORE 原文（§1.1）＋ `must be less than '0'` ⇒ `_size==0` |

**"同一趟"的证据强度**：日志上 AOOORE **永远**紧跟在排布帧四行（FILL／FSQSTD／FSQSTD-SRC／FSQSPL）之后、**从无一次**孤立出现或夹带别行；改前（排布帧抛）AOOORE **0 条**。两帧是否属**同一 dispatcher 操作**未直接可读 ⇒ 具名 `NOINFO(FRAME-BOUNDARY)`（§6），但**因果链不受其影响**（见 §2.2 反腿）。

---

## §2 性质判定：**「前进」×「旧有（首次可达）」**（逐条依据）

### 2.1 判「前进（更深的消费者被走到）」✅

依据 ①：**计数位移＝"排布帧首次成功"**。改前 `FsQuerySubtrackDetails` **1217／1217 全拒**（`reason=no-layout-content-model`）、`[FSQSPL]` **0 条**、AOOORE **0 条**；改后 `rc=0` **988**、`[FSQSPL]` **988**、AOOORE **561**。
依据 ②：**AOOORE 的条数可逐项配平**：`988 = 561 + 427`；`561`＝排布帧成功**且**子段为 `TextParagraph`（无异常 ⇒ 走到视觉帧）；`427`＝排布帧成功**但**子段句柄 `0x4` 不可认领 ⇒ **在排布帧内**抛 `PtsException`（`[FSQSTD] rc=-10000 reason=unclaimable-subtrack psub=0x4`，**427 条**）⇒ 视觉帧走不到。两条腿**互不重叠、合计＝全部成功数**。
依据 ③：**改前该点根本不可达**——改前 1217 条失败**全在** `FsQuerySubtrackDetails` 这一步（`ContainerParaClient.OnArrange:47` 的 `PTS.Validate` 抛）⇒ 同趟的 `EnsureValidVisuals` 从未被走到 ⇒ `PtsPage.cs:1042` 从未执行。⇒ AOOORE 是**更深一层**的产物，判"前进"。

### 2.2 判「**不是**新缺陷（**不是我方返回值越界**）」✅（含**现成反证**）

依据 ①：AOOORE 的三个常量（`index=0`／`_size=0`／`paramName=index`）全部指向**消费者侧**的 `VisualCollection` 空集合，与我方出参无关——我方两个入口的成功出参**逐格可核**：`[FSQSTD] … cParas=1 true_cParas=1 out=WRITTEN bytes=40`（`cParas` 与真值**相等**）；`[FSQSPL] … cParas=1 made=1 cli_total=7`（数组按 `cParas` 逐槽清零后填，`*cParaDesc=cParas`）。
依据 ②：**"我方为伪值 ⇒ 必红"的牙在册且现取有效**（`cparas-mismatch`）：`rev-fake999`（`cParas≡999`）⇒ `[FSQSPL] rc=-10000 reason=cparas-mismatch … out=UNWRITTEN` **1015 条**、`[HC-UNHANDLED]` **1015 全 `PtsException`**、**AOOORE 0 条** ⇒ 伪值走的是**另一条症状**，不是本条。
依据 ③：**反腿独立把"与 `[FSQSPL]`／`ValidateVisual` 无关"钉死**——`rev-zero`（`-DWPF_PTS_SUB_CPARAS_FAKE=2`，`cParas≡0`，`[FSQSPL]` **0 条**）现取：
```
[FSQSTD] rc=0 reason=ok entry=FsQuerySubtrackDetails ctx=0x64e72df09440 psub=0x64e72df60fd4 calls=1 ok=1 gap=0 null=0 unclaim=0 unformatted=0 out=WRITTEN bytes=40 cParas=0 true_cParas=3 nms=0x2 src=SUBENUM(+136/+144)
[FSQSTD-SRC] cParas=0 src=subenum(+136/+144) du=768 dv=576 nms=0x2 NOINFO=fsupdinf(no-source),fsrc(declared-geometry)
[HC-UNHANDLED] #1 ArgumentOutOfRangeException: index ('0') must be less than '0'. (Parameter 'index')
```
⇒ **"`[FSQSTD] rc=0` 与 AOOORE 之间**没有 `[FSQSPL]`**"也能抛** ⇒ AOOORE **不是** `ContainerParaClient.ValidateVisual → UpdateParaListVisuals`（那条路**必**先过 `[FSQSPL]`）的产物，而是"**排布帧不抛 ⇒ 页视觉帧就被走到**"的产物 ⇒ 与 §1.2 的 `:1042` 落点**互相印证**。

### 2.3 判「旧有（两支，均已先于 `T-A12` 存在）」✅

- **支 A（我方，`t125` 起）**：`FsQueryPageDetails` 写 `fskupd=fskupdInherited`，**违反** `Pts.cs:1695` 的契约值域。该行**未被** `T-A12` 触碰（`T-A12` 的 `git diff` 只动 `win32_pts.c` 的四项：`wpf_pts_sub_enum`／子轨对象绑定／`FsQuerySubtrackDetails` 成功分支／`FsQuerySubtrackParaList`；`FsQueryPageDetails` 现取与 `t125` 同形）⇒ **旧有**。
- **支 B（上游）**：`PtsPage.cs:1042` 对 `visualChildren[0]` **无守卫**（`:1041` 只有 `Debug.Assert`，release 无效；`:1036` 的守卫**先短路**）⇒ 一旦"未建轨视觉"就**必抛**。上游既有代码，本件**未改**（`PtsPage.cs` 不在本仓写域）⇒ **旧有**。
- **为何"旧有"到 `T-A12` 才现**：两者**此前不同时可达**（改前 1217 条全卡在 `FsQuerySubtrackDetails` 的 `-10000`，同趟视觉帧从未被走到）⇒ **`T-A12` 的承重格放行是"使能"条件，不是"造错"条件**。**这条与 `T-A12` §6-3 的口径一致**（"承重格放行 ⇒ 消费者继续往下走才暴露的下一跳缺口"），本件**把它从"未定位"推进到"件:行定钉"**。

### 2.4 顺带**更正一条在册断言**（`T-A11`／`T-A12` 的 `NOINFO-FSUPDINF-CONSUMER`）

`T-A11`（`P1-tail2-fsqstd2-recon.md` §6.2）与 `T-A12`（`P1-tail2-cparas-impl-report.md` §6-4）写"`fsupdinf` **全树 0 消费者**"。**现取反证**：
- `FSPARADESCRIPTION.fsupdinf.fskupd` **有**消费者：`PtsHelper.UpdateParaListVisuals`（`PtsHelper.cs:259-263`）`PTS.FSKUPDATE fskupd = arrayParaDesc[index].fsupdinf.fskupd; if (fskupd == fskupdInherited) fskupd = fskupdInherited;`；
- `FSPAGEDETAILS.fskupd` **有**消费者：`PtsPage.UpdatePageVisuals`（`:999`／`:1026`／`:1029`，本件抛出点的上游）。
⇒ `NOINFO-FSUPDINF-CONSUMER` **撤销**（消掉条件已满足：消费者现取到 `:259`／`:999`）。**不改判词句原文**，只在本件**具名更正**。

---

## §3 `[FSQSPL]`（`FsQuerySubtrackParaList`）现取面（③）

### 3.1 声明与调用点（现取）

声明（`Pts.cs:3741-3748`，逐字）：
```csharp
[DllImport(DllImport.PresentationNative)]
internal static extern unsafe int FsQuerySubtrackParaList(
    IntPtr pfsContext,                  // IN:  ptr to FS context
    IntPtr pSubTrack,                   // IN:  ptr to subtrack
    int cParas,                         // IN:  size of array of para descriptions
    FSPARADESCRIPTION* rgParaDesc,      // OUT: array of para descriptions
    out int cParaDesc);                 // OUT: actual number of paragraphs
```
托管包装（`PtsHelper.cs:623-637`，逐字；**唯一**调用点 `:633`）：
```csharp
internal static unsafe void ParaListFromSubtrack(
    PtsContext ptsContext, IntPtr subtrack, ref PTS.FSSUBTRACKDETAILS subtrackDetails,
    out PTS.FSPARADESCRIPTION [] arrayParaDesc)
{
    arrayParaDesc = new PTS.FSPARADESCRIPTION [subtrackDetails.cParas];   // :629  ← **消费者用 cParas 开数组**
    int paraCount;
    fixed (PTS.FSPARADESCRIPTION* rgParaDesc = arrayParaDesc)             // :631
    {
        PTS.Validate(PTS.FsQuerySubtrackParaList(ptsContext.Context, subtrack, subtrackDetails.cParas,
            rgParaDesc, out paraCount));                                   // :633  ← 唯一调用点
    }
    ErrorHandler.Assert(subtrackDetails.cParas == paraCount, ErrorHandler.PTSObjectsCountMismatch);  // :636
}
```
`ParaListFromSubtrack` 的调用者（现取 `grep -n`）：`ContainerParaClient.cs:70/99/151/197/225/247/283/337/384`（9 处）＋ `ListParaClient.cs:68`（1 处）= **10 处**。**本链那一处＝`ContainerParaClient.cs:70`（`OnArrange`，排布帧）**——由 §1.4 ①-③ 的相邻性与"`OnArrange` 之后即 `ArrangeParaList`"定。

### 3.2 入参（现取，两种 `psub` 各有样本）

| 入参 | 现取 | 说明 |
|---|---|---|
| `pfsContext` | `ctx=0x604fde8665d0`（RichTextBox 文档）／`ctx=0x604fde836300`（FlowDocument 文档） | 本 run 在册 doc 指针 |
| `pSubTrack` | `psub=0x604fe2bb5ad4`（`cParas=1`）／`psub=0x604fddf9a224`（`cParas=3`） | 均为**本侧自有子轨对象字段地址**（`[FSPARALIST-PARA] … src=native-owned-subtrack claim=ok claims=N rejected=0`） |
| `cParas` | `1` ／ `3` | ＝上一步 `[FSQSTD]` 成功分支写出的 `cParas`（承重格） |
| `rgParaDesc` | 托管 `fixed` 数组（`new FSPARADESCRIPTION[cParas]`，64 B/槽） | `bytes0_32` 现取可见前 32 B |
| `cParaDesc`(out) | 成功 `*cParaDesc = cParas`；失败**先清 0** | 拒绝面 `out=UNWRITTEN` |

### 3.3 我方返回（现取原文）

**成功**（`calls=1 ok=1 gap=0`，`evidence-default:846`）：
```
[FSQSPL] rc=0 reason=ok entry=FsQuerySubtrackParaList ctx=0x604fde836300 psub=0x604fddf9a224 cParas=3 made=3 cli_total=3 src=SUBENUM(+136/+144)+managed-176 calls=1 ok=1 gap=0 NOINFO=subtrack-para-geometry(dvrUsed/dvrTopSpace/bbox=0)
```
**失败面**（现取 `reason` 直方图）：缺省腿 **988／988 全 `rc=0 reason=ok`**（`gap=0`）；反腿 `rev-fake999` **1015／1015 全 `rc=-10000 reason=cparas-mismatch … out=UNWRITTEN`**（`cParas=999`，与真值 3／1 不等即拒）。
出参逐槽（源件 `win32_pts.c:4200-4216`，逐字语义）：
```c
for (int i = 0; i < cParas; i++) {
    memset((void *)&rg[i], 0, sizeof(rg[i]));                 /* 未初始化内存不交上级 */
    rg[i].pfspara       = (void *)obj->children[i];            /* 窗内枚举出的子段句柄 */
    rg[i].pfsparaclient = (void *)obj->child_clients[i];       /* 本 run `+176` 真返回 */
    rg[i].nmp           = (void *)obj->children[i];
    /* dvrUsed／dvrTopSpace／bbox／idobj／**fsupdinf.fskupd**：memset 后**不再写** ⇒ 0 */
}
*cParaDesc = cParas;                                          /* 只在**真填完后**置 */
```
⇒ **现取要点**：`dvrUsed/dvrTopSpace/bbox` 与 **`fsupdinf.fskupd`** 四类格**恒 0**（前者已具名 `NOINFO-SUBTRACK-PARA-GEOMETRY`；后者**今天被证明有消费者**，见 §2.4／§4）。

### 3.4 与托管消费者的期望对拍（逐格）

| 消费者期望 | 现取 | 判 |
|---|---|---|
| `:629` `new FSPARADESCRIPTION[subtrackDetails.cParas]`（**cParas 是承重格**） | `cParas ∈ {1,3}`，与 `true_cParas` 相等 | **一致** |
| `:633` 传 `subtrackDetails.cParas` 作 `cParas` | 我侧 `cParas == obj->c_paras` 才放行（否则 `cparas-mismatch`） | **一致**（牙在册） |
| `:636` `Assert(subtrackDetails.cParas == paraCount)` | 成功路径 `*cParaDesc = cParas` | **一致** |
| 索引 `arrayParaDesc[index]`（`PtsHelper.cs:255/259/283`、`ArrangeParaList:158` 等） | 数组长度＝`cParas`，逐槽已填 | **一致** |
| `arrayParaDesc[index].fsupdinf.fskupd`（`PtsHelper.cs:259`） | **恒 0＝`fskupdInherited`**（无源） | **⚠️ 无源值，但本链**未**因它抛（`rev-zero` 证：无 `[FSQSPL]` 也抛）** |

---

## §4 唯一选靶 ＋ 判据草案（④）

### 4.1 唯一下一增量（`T-A15` 候选）

> **修 `FsQueryPageDetails` 的 `FSPAGEDETAILS.fskupd` 语义**（`win32_pts.c` 内 `d->pad0` 那一格，现取恒 `0`）：
> ① **首次**被查询（该页对象尚无"已建视觉"记录）⇒ 写 **`fskupdNew(2)`**（消费者据此走 `PtsPage.cs:1029-1032` 建轨视觉）；
> ② **此后**（页几何／内容未变）⇒ 写 **`fskupdNoChange(1)`**（消费者 `:999` 提前返回，做零工作）；
> ③ **永不再写** `fskupdInherited(0)`（上游 `Pts.cs:1695` 明示该值不可能）；
> ④ **失败必留痕**（沿用）；**成功也要留痕**：新增机读行（建议 `[QPD] fskupd=<n> first=<0|1> page=<hex> qpd_ok=<n> qpd_gap=<n>`），使 D1／D2 **可现取**而非靠推。

**为什么是它、且只能是它（三条理由）**：
1. **落点唯一性**：现取的三个常量（`index=0`／`_size=0`／`paramName=index`）只指向"空 `VisualCollection` 取 `[0]`"；本链上**唯一**可现取的空集合＝`pageContentVisual.Children`（`PtsPage.cs:1042`，其兄弟下标全有守卫），其**唯一**成因＝`:1029` 判否，`:1029` 的 `fskupd` **唯一**来源＝我方 `FsQueryPageDetails`（`:1023` 的 `trackdescr.fsupdinf.fskupd` 也来自同趟 `memset`）。⇒ 改**别的格**（如 `FsQueryTrackParaList`／`FsQuerySubtrackParaList` 的 `fsupdinf`）**不能**消除本 AOOORE（它先于 `:1043` 抛出）。**唯一**。
2. **必要性**：不修它，视觉树**永不建**（`pageContentVisual.Children` 恒空 ⇒ 页视觉根本没接上）⇒ 与现取症状门"`magenta=0`／帧 `ef3fd6765f18f51b` 逐字节不变＝页仍未绘出内容"**同源**。修它才把"排布帧已放行"接到"**页视觉帧真能执行**"。
3. **反腿已给出"该红必红／不红必因"**：排布帧一旦抛（`rev-fake999`／`off` 腿），AOOORE **0**；排布帧一旦成功（缺省腿／`rev-zero`），AOOORE **必**出现（**5 条腿 × 逐条可复现**）：`off=0／fake999=0／改前=0` vs `default=561／default2=661／default3=564／rev-zero=2`。⇒ 该判据**今天就能复跑**。

**弱备选（登记但不选）**：给 `PtsPage.cs:1042` 加守卫（上游件，**不在本仓写域**）；用"恒 `fskupdNew`"糊过去（＝零假值违反，**D2 反极性必红**）。
**若判"本波做不到"的合法终点**：具名 `PRECOND-FSPAGEDETAILS-PAGE-CHANGE-TRACKING`（需要"该页本轮是否变化"的可信源；缺它只能给"首次 New／此后 NoChange"的**弱语义**）——**但本席按现取判：本条**可做****（弱语义与契约值域相容，且**不**声称拥有"位移"真值）。

### 4.2 判据草案 `D1–D5`（每条 ≥1 反极性；"该红必红"）

| 判据 | 正极性（可机读） | 反极性（现取即证／可复跑） |
|---|---|---|
| **`D1` AOOORE 归零** | 缺省腿 `grep -c 'ArgumentOutOfRangeException: index' app_g1.log` **== 0** | 保持现产物（`fskupd=0`）⇒ **>0**（**现取 561／661／564**，样本 1/2/3；`log_sha16` 见页首）⇒ **该红必红** |
| **`D2` `fskupd` 契约值域** | `[QPD]` 现取：**首次 `fskupd=2`**、稳态 **`fskupd=1`**、`fskupd=0` **出现 0 次** | ① 出现 `fskupd=0` ⇒ 红并点名（上游注释逐字排除该值）；② **恒 2**（每趟都 New）⇒ **也红**（＝把"未变"谎报成"新建"，零假值违反） |
| **`D3` 视觉树真建起来** | `[VIS] children=1`（`pageContentVisual.Children.Count==1`）∧ `D1`＝0 | 保持 `Children.Count==0` ⇒ **必 AOOORE**（现取即证）；另：若 `D1=0` 而症状门 `colors/magenta/ink/帧 sha16` **全不变** ⇒ 读成"**没走到**"（红），**不许**读成"修好了"（`P13` 同族） |
| **`D4` 不开放不可捕获路** | `alive=yes ∧ app_rc=143`；`FAILLINE failfast=0 unrec=0` | 出现 `app_rc=134`／`alive=no`／`failfast>0` ⇒ 红（`t103` 教训：给托管句柄喂本侧指针 ⇒ 撞 `Invariant.Assert` ⇒ `FailFast`；`rev-zero` 现取即此类：`app_rc=134`） |
| **`D5` 承重格不回退** | `[FSQSTD] rc=0` 的 `cParas == true_cParas`（现取 988／1050／911）且 `[FSQSPL] rc=0` 计数**不减少**；`unclaimable-subtrack` 仍逐条留痕（427／389／347） | `cParas != true_cParas` 或 `[FSQSPL] rc=0` 计数下降 ⇒ 红 |

**证伪性自查**：`D1`／`D2`／`D5` 都是**纯计数/值域**判据，任一腿可独立复跑；`D3` 的"可证伪"落在"`Children` 计数"这一格（须由 `D2 ④` 的留痕提供，**否则本判据不可机读** ⇒ 这就是为什么 `[VIS]`／`[QPD]` 留痕是**选靶的一部分**，不是可选项）。

---

## §5 现取命令与读数台账（可复跑）

```
# 改后（三条缺省腿 ＋ 三条反腿；仓外私有目录）
$ cd /home/links-dev/tA12-work
$ for d in evidence-default evidence-default2 evidence-default3 evidence-off evidence-rev-fake999 evidence-rev-zero; do
    f=$d/app_g1.log
    printf "%-22s FSQSTD=%s(ok=%s gap=%s) FSQSPL=%s AOOORE=%s PtsExc=%s FILL=%s\n" "$d" \
      $(grep -c '^\[FSQSTD\]' $f) $(grep -c '^\[FSQSTD\] rc=0' $f) $(grep -c '^\[FSQSTD\] rc=-10000' $f) \
      $(grep -c '^\[FSQSPL\]' $f) $(grep -c 'ArgumentOutOfRangeException: index' $f) \
      $(grep -c 'PtsException' $f) $(grep -c '^\[FSPARALIST-FILL\]' $f)
  done
```
| 腿 | `FSQSTD`(ok/gap) | `FSQSPL` | **AOOORE** | `PtsException` | `FILL` |
|---|---|---|---|---|---|
| **改前** `evidence-tail2`（`5533298d4dc75eab`） | 1217 (**0**/1217) | **0** | **0** | 1217 | 1217 |
| `default`（`157ce8df7a1c4a63`） | 1415 (**988**/427) | 988 | **561** | 427 | 988 |
| `default2` | 1439 (**1050**/389) | 1050 | **661** | 389 | 1050 |
| `default3` | 1258 (**911**/347) | 911 | **564** | 347 | 911 |
| `off`（`WPF_PTS_DRIVE_PROBE=0`） | **0** | 0 | **0** | 861 | 0 |
| `rev-fake999`（`cParas≡999`） | 1015 (**1015**/0) | 1015（全 `cparas-mismatch`） | **0** | 1015 | 1015 |
| `rev-zero`（`cParas≡0`） | 3 (**3**/0) | **0** | **2** | 0 | 3 |

`awk` 相邻性（§1.2）：
```
$ awk '/^\[FSQSPL\]/{getline n; if(n ~ /HC-UNHANDLED/) t++; else o++} END{print "throw="t" other="o}' evidence-default/app_g1.log
throw=561 other=427
```
`rev-zero` 的"**无 `[FSQSPL]` 也抛**"（§2.2）：
```
$ grep -n 'FSQSTD\]\|FSQSPL\]\|HC-UNHANDLED' evidence-rev-zero/app_g1.log | sed -n '1,8p'
673: [FSQSTD] rc=0 … cParas=0 true_cParas=3 …
674: [FSQSTD-SRC] cParas=0 …
675: [HC-UNHANDLED] #1 ArgumentOutOfRangeException: index ('0') must be less than '0'. (Parameter 'index')
```
改后 `[FSQSPL]` `reason` 直方图（缺省腿 **988 全 `rc=0 reason=ok`**；`fake999` **1015 全 `rc=-10000 reason=cparas-mismatch`**）：
```
$ grep -o '^\[FSQSPL\] rc=[-0-9]* reason=[a-z-]*' evidence-default/app_g1.log | sort | uniq -c
    988 [FSQSPL] rc=0 reason=ok
```
`FsQueryPageDetails` 成功**不留痕**的现取（全日志 `[FS_PAGE_GAP]` 命中 **0**）：
```
$ grep -c '^\[FS_PAGE_GAP\]' evidence-default/app_g1.log        # 0
```

---

## §6 边界 · 具名 `NOINFO` · 主动披露

### 6.1 边界（照 `T-A14` ②）
**只读**：除本载体外**未改任何仓内文件**（`git status --porcelain` 现取只有两处**先于本件**的 `??`）；未构建、未跑腿、未占显示位、未跑整趟 `verify-all`、未跑 `static-jaws-check.sh`；大文件只用 `wc/head/tail/grep/awk`；未起进程；未 `git add/commit/push`。

### 6.2 具名 `NOINFO`（逐条给**消掉条件**）
1. **`NOINFO(reason=HOOK-CAPTURES-ONLY-FIRST-FRAME)`**：`[HC-UNHANDLED]` 的**发射方**＝仓外第三方 demo（`/home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/App.xaml.cs:74-76`：`var top = frames[0].Trim(); … "｜ 首帧 {top}"`）⇒ **只记 `StackTrace` 首帧**，**没有完整托管栈**。⇒ 本件"件:行"是**由抛出原文三常量 ＋ 调用相邻性 ＋ 源码守卫行**推出的**（不是栈帧直读）**。**消掉条件**：把发射方改成记 `ex.ToString()`／全栈（**该件不在本仓写域**），或我方自加"托管帧探针"。
2. **`NOINFO(reason=QPD-SUCCESS-NOT-LOGGED)`**：`FsQueryPageDetails` **成功路径不打印**（只在失败打 `[FS_PAGE_GAP]`）⇒ 本件无法从日志**直读**它当趟的 `fskupd`；`fskupd=0` 由**源件 `memset`（`win32_pts.c:3514`）＋ 抛出原文 `_size=0`（`must be less than '0'`）**两路夹出。**消掉条件**：§4.1 ④ 的 `[QPD]` 留痕（＝选靶自带）。
3. **`NOINFO(reason=NO-MANAGED-VISUAL-FRAME-COUNTER)`**：视觉帧（`ValidateVisual`／`UpdatePageVisuals`）**全树无任何计数器/留痕** ⇒ "视觉帧是否被走到"只能**间接**由 AOOORE 的存在证明；本件的"前进"判词因此建立在**计数配平（988=561+427）＋反腿（`rev-zero`）**上，而非"视觉帧计数"。**消掉条件**：`[VIS]`／`[QPD]` 留痕。
4. **`NOINFO(reason=FRAME-BOUNDARY)`**：AOOORE 与排布帧四行**逐条相邻**（从无例外），但"**排布帧与页视觉帧是否同一 dispatcher 操作**"**无边界标记可读**（`.NET` 侧无 in-repo 探针）。⇒ 本件**不**把该点写成结论；因果链只依赖"**排布帧一抛则 AOOORE=0、一成功则 AOOORE>0**"这一**双侧可复跑**事实。**消掉条件**：加帧边界留痕（同上）。
5. **`NOINFO(reason=UPSTREAM-GUARD-INTENT)`**：`PtsPage.cs:1042` 是"**上游既有的无守卫取值**"还是"上游本有更早守卫被本移植面绕开"，**本件未做上游历史比对**（只现取当前 `sha16=70be7828e8f9650d` 的逐字形态）。**消掉条件**：取上游对应 tag 的同函数 diff。

### 6.3 主动披露
1. **本件把 `T-A11`／`T-A12` 的一条在册断言更正**（`NOINFO-FSUPDINF-CONSUMER` **不成立**，§2.4）；**未改**那两件原文，只在本件具名更正（承 `T-A13` 的 `SITE-HISTORICAL-ONLY` 纪律：历史行不动、另处更正）。
2. **本件不改任何 `src/**`／`build/**` 件**；`§4` 的选靶只是**草案**（是否开单由队长裁）。
3. **读数来源划界**（§页首）：改前读数取自**在册证据的现核**（非本席同趟重取）；改后读数取自 `T-A12` 落在**仓外私有目录**的证据（`/home/links-dev/tA12-work/evidence-*`，`grep` 现核）。两侧 `pf`／装置／腿器口径一致。
4. **未做**：未复跑腿（本件纯只读）；未核 `PresentationFramework.dll` 的 IL（无 `ilspycmd`／`ikdasm`，且不构建）⇒ "件:行"的**最终形态**由源码＋现取常量定钉，若需 IL 级铁证，属**另一笔**（具名：`NOINFO(reason=NO-IL-DISASSEMBLER-IN-ENV)`）。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-aoore-recon.md | sha256sum | cut -c1-16`）= `391b285900c72101`
