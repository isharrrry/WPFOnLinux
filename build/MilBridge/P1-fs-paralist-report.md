# P1-W51 · `FsQueryTrackParaList`（ENFE 1085）—— **「清单＋现状＋key/next 分析＋实现计划」最小载体**（先落盘，随后原地追加读数）

> 本件先落最小载体（队长明令「先落盘再深挖」）。**随后就地追加实现与真腿读数**（只增不改）。
> **读取时刻**：`ts=2026-09-29T13:2x`（起）。

---

## §0 现状（现取，可复算）
```
HEAD   = 3797ff4（t127 已入库）        .so = e9b7def842982920      exports = 591      ^Fs = 5
真腿上一趟：ENFE_TOTAL = **1085** ⇒ 全部是 `FsQueryTrackParaList`；两页 alive=yes app_rc=143 failfast=0
前四步已闭：FsCreatePageBottomless(1151→0) / FsQueryPageDetails+FsDestroyPage(回归解) /
            FsQueryTrackDetails(1101→0) + FsCreatePageFinite(1→0)
```

## §1 「钥匙 vs 其后」现取分析（本件第一产出）

### 1.1 调用点（**唯一一处**，逐字）
`PtsHelper.cs:604-617`：
```
internal static unsafe void ParaListFromTrack(PtsContext ptsContext, IntPtr track,
                                              ref PTS.FSTRACKDETAILS trackDetails,
                                              out PTS.FSPARADESCRIPTION[] arrayParaDesc)
{
    arrayParaDesc = new PTS.FSPARADESCRIPTION[trackDetails.cParas];      // ← 用**我们上一步给的 cParas** 定数组长
    int paraCount;
    fixed (PTS.FSPARADESCRIPTION* rgParaDesc = arrayParaDesc)
    {
        PTS.Validate(PTS.FsQueryTrackParaList(ptsContext.Context, track, trackDetails.cParas,
                                              rgParaDesc, out paraCount));
    }
    ErrorHandler.Assert(trackDetails.cParas == paraCount, ErrorHandler.PTSObjectsCountMismatch);
}
```
⇒ **它依赖我们发出的两个字段**：`track`（＝`FSPAGEDETAILS.u.simple.trackdescr.pfstrack`，`t127` 已回填且可身份校验）
与 `trackDetails.cParas`（＝`FSTRACKDETAILS.cParas`，`t127` 已按对象给，本模块现给 **1**）。**这两个都已就位** ⇒ 与 `t127` 那种"字段没填"的形态**不同**。

### 1.2 🔴 **真正的钥匙不是我方能填的东西**（本件最要紧的发现）
`FSPARADESCRIPTION`（`Pts.cs:1500-1510`）要**逐个段落**填：
```
internal struct FSPARADESCRIPTION {
    internal FSUPDATEINFO fsupdinf; internal IntPtr pfspara; internal IntPtr pfsparaclient;
    internal IntPtr nmp; internal int idobj; internal int dvrUsed; internal FSBBOX fsbbox; internal int dvrTopSpace; }
```
其中 **`pfsparaclient` 会被用来反查一个托管对象**（现取，4 处）：
`ContainerParaClient.cs:249 / :289 / :342 / :386` ⇒ `PtsContext.HandleToObject(arrayParaDesc[i].pfsparaclient) as BaseParaClient`
而 `HandleToObject`（`PtsContext.cs:243-249`）实现是：
```
long handleLong = (long)handle;
Invariant.Assert(handleLong > 0 && handleLong < _unmanagedHandles.Length, "Invalid object handle.");
Invariant.Assert(_unmanagedHandles[handleLong].IsHandle(), "Handle has been already released.");
return _unmanagedHandles[handleLong].Obj;
```
`_unmanagedHandles` 是**托管侧**的 `HandleIndex[]`（`PtsContext.cs:47` 分配）⇒ **该"句柄"不是内存指针，而是该托管表的索引**（现取：表项 `Index`／`Obj` 由托管侧维护，`:184-193`）。

⇒ **三条硬结论**：
1. 若把 `pfsparaclient` 写成**指针**（我们自家对象字段地址）⇒ `handleLong` **远大于表长** ⇒ 撞
   `"Invalid object handle."` ⇒ **`Invariant.FailFast`（不可捕获）**；
2. 若写 **0** ⇒ 撞 `handleLong > 0` ⇒ **同一条 FailFast**；
3. 若随手写一个**小整数**（如 `1`）⇒ 可能**恰好落在表内**，但那个槽**不是 `BaseParaClient`** ⇒ `as BaseParaClient` 得 `null` ⇒ 后面**空引用/NRE**；
   ⇒ **"看似真、实则伪"的句柄在这一格比 `NULL` 更危险**（正是 `t127` 立的「字段级诚实性」反腿 b 的加强版：这里连"看起来合理"都做不到）。
⇒ **这一格我方**无法**诚实满足**：要让 `pfsparaclient` **可用**，必须**托管侧真的创建过那些 `BaseParaClient` 并登记进表** ——
   那是**托管侧的段落创建路径**（`BaseParagraph.Init` 出 `pfsparaclient`；其调用点属 `CellParaClient`／`ContainerParaClient` 等），
   **不是** native 侧能凭空造出来的。**我方唯一能诚实做的**：把该入口**补成"已导出且**行为可读**"**，
   即**永不假成功** + **返非 0 必留痕**；**不**填任何伪造句柄。

### 1.3 钥匙 / 其后 的判词
- **钥匙（本步之前已闭）**：`pfstrack` 与 `cParas` 两个字段 —— `t127` 已回填并钉死偏移。
- **其后要撞的**：`FsQueryTrackParaList` **本身**（本步靶心，ENFE 1085）。
- **再其后（本步会暴露的下一族）**：`FSPARADESCRIPTION.pfsparaclient` 的**托管句柄表**依赖 ⇒ 属**托管侧段落创建路径**（**非本件写域**）。
⇒ **与前四步的形态差异（必须写明）**：前四步都是"**我方数据结构缺一个字段/一条入口**"；**本步第一次遇到"该字段的可用值只能由托管侧产生"** ⇒ **本步的诚实上界 = 「入口不再缺 ＋ 行为可读」**，**给不出"段落列表可用"**。

## §2 实现计划（写死，随后逐条落读数）
| 项 | 内容 |
|---|---|
| 实现 | `FsQueryTrackParaList(void *ctx, void *pTrack, int cParas, void *rgParaDesc, int *cParaDesc)`：**按指针身份认 track**；**要么全部成功、要么全部拒绝**；**本步按"拒绝面已可判"实现** —— 见 §3 的决策 |
| 留痕 | 返非 0 打 `[FS_PAGE_GAP] rc=… reason=… entry=FsQueryTrackParaList …` ＋ 只读口计数（**不许静默 stub**） |
| 出参 | 失败 ⇒ `*cParaDesc = 0` **且不写 `rgParaDesc` 数组一个字节**（不留残留、不留半成品） |
| 新格 | 格 `90`（旧格号 0–89 一个未动）；夹具**每跑必回收到 base ⇒ `live==0`**（`t127` 的教训） |
| 偏移 | **凡碰结构体布局：实测 ＋ `_Static_assert`**，并按四格写「错偏移 ⇒ 症状 ⇒ 实测值 ⇒ 断言」 |
| `SRCS` | **不新增源件** ⇒ 无需改；仍复核 `SRCS=实际=10`、差集 0 |
| 表述 | 本步绿只准读成「该入口不再缺、且它不假成功、失败可读」；**不许**写成"打通排版" |

## §3 决策（写给复核件，避免被读成"没做完"）
本入口**不填**伪造 `pfsparaclient`（会触发**不可捕获**的 `FailFast` 或 NRE），因此**本步无法把 1085 归零**。
本件将就**两种可测形态**做现取比较并如实入册：**(A)** 保持缺符号（现状：1085 ENFE）**(B)** 补成"已导出且永不假成功"（ENFE→0，但下游走 `PtsException`）。
**判词按实测给出**，不预判哪一态更优；**若 (B) 使两页退化 ⇒ 如实记回归并上报**（不掩盖）。

---


---

## §4 实现读数（原地追加，只增不改）

### 4.1 实现（**永不假成功**）
新增 `FsQueryTrackParaList(void *ctx, void *pTrack, int cParas, void *rgParaDesc, int *cParaDesc)`：
- 拒绝面**逐条**：`cParaDesc==NULL`／`pTrack==NULL`／未知上下文／**track 不是我们的**（`wpf_pts_track_owned`，只做指针值比较）／`cParas<0`／`cParas>0 且 rgParaDesc==NULL`；
- **★ 承重拒绝**：**入参全合法、track 也确是我们自己的，仍然拒**（`reason=paraclient-table-not-native`）—— 因为"可用的 `pfsparaclient`"只能由**托管侧**产生（§1.2）；
- 失败时 `*cParaDesc = 0`，**`rgParaDesc` 一个字节都不写**（不留残留/半成品）；每次返非 0 都打
  `[FS_PAGE_GAP] rc=… reason=… entry=FsQueryTrackParaList ctx=… track=… cParas=… owned=… ok=… gap=…`；
- 只读口：`WpfLinuxWin32_PtsFsParaListOk()`／`…ParaListGap()`。

**直接探针（现取）**：先用真实现拿到真 track 与 `cParas`，再调本入口：
```
trackDetails.cParas=1（托管侧按它定数组长）
FsQueryTrackParaList rc=-10000  got=0  ok=0  gap=1
⇒ **返 0 才是假成功；此处 rc=-10000 ⇒ 永不假成功**
```

### 4.2 两态实测（**本步的判词依据**，不预判、只实测）
| 态 | 构造 | `ENFE_TOTAL` | 我们侧留痕 | 两页 |
|---|---|---|---|---|
| **(A) 缺符号**（`t127` 后现场） | `.so=e9b7def842982920` | **1085**（全为该名） | 无（符号不存在，CLR 在封送期就抛） | alive=yes / 143 |
| **(B) 已导出且永不假成功**（本步） | `.so=a4bf2c47f8efb521` | **0** | **1123 行**，全为 `reason=paraclient-table-not-native` | **alive=yes / 143** |
⇒ **(B) 严格优于 (A)**：同为零回归的前提下面，**(A) 的 1085 次是"应用侧 `[HC-UNHANDLED]` 未处理异常"**（发射方是第三方钩子、不在本仓写域），
而 **(B) 把它们变成我方 native 侧的具名留痕 + 受控的 `PtsException`（被托管的降级路径接住）**。
⚠️ **不许读成"排版前进"**：`ENFE=0` 只证"**该名不再缺符号**"；§1.2 那条**托管句柄表**依赖**仍未满足**。

### 4.3 「错偏移 ⇒ 症状 ⇒ 实测值 ⇒ 断言」四格（队长要求③；本步**未新碰**结构体布局，故此格为 `t127` 经验的**回归复核**）
| 格 | 内容 |
|---|---|
| **错偏移** | `t127` 首版把 `FSPAGEDETAILS.u.simple.trackdescr.pfstrack` 写在 +80（把 `FSUPDATEINFO` 当 16 B） |
| **症状** | 托管侧在它以为的 `pfstrack` 处读到我们别的字段 ⇒ `FsQueryTrackDetails` 报 `unknown-track-or-not-ours` **×1129** |
| **实测值** | 托管侧实收 `0x30000000000`（＝我们 `b_defined` 与 `b_du` 的合成）；正确偏移实测为 `nms`+16／`fsrc`+24／`fsbbox`+40／**`pfstrack`+64** |
| **断言** | 源码内 4 条 `_Static_assert`（`td_nms==16`／`r_u==24`／`b_defined==40`／`td_pfstrack==64`）—— **本步复跑仍全过**（改动未触碰布局） |
**本步对布局的处置**：`rgParaDesc`／`cParaDesc` 我**只当不透明句柄**（`void*`／`int*`）使用，**不写也不读**任何 `FSPARADESCRIPTION` 字段 ⇒ **本步不引入新的布局假设**（这正是 §1.2 结论的直接后果：不填就不会错填）。

### 4.4 导出面（逐名点名）＋ `SRCS`
```
so16=a4bf2c47f8efb521  exports=594  ^Fs=6  nm=594=exports（无导出消失）
新增 3 条：FsQueryTrackParaList / WpfLinuxWin32_PtsFsParaListGap / WpfLinuxWin32_PtsFsParaListOk
SRCS 条目 10 ＝ 实际 src/*.c 10（差集 0 ⇒ 未新增源件，无需登记改动）
```
### 4.5 症状／回归／帧（本步真腿，逐腿同趟）
```
k=23 alive=yes app_rc=143 magenta=0 colors=383 ae=0     ink=480000  ns=…RichTextBoxDemo
k=24 alive=yes app_rc=143 magenta=0 colors=383 ae=15386 ink=480000  ns=…FlowDocumentDemo
gap=0  unavail=0  **failfast=0**  unrec=0  fontfb=6（字体栈降级未碰坏）⇒ **零回归**
逐腿 DEV shim=a4bf2c47f8efb521 ＝ 现盘 .so ✓；POSTSHIM 同值；shotstat(383/0/480000) ＝ leg_24.env 逐格相等
🔴 **帧去重仍 ＝ 1**（k23=k24=ef3fd6765f18f51b）⇒ 按 `N3` **判红**；`C6`/`C8` **不给绿**（ink 同值零区分力、`ns=` 不承担内容身份、正身份 `NOINFO`）
```
### 4.6 顺带补齐的两处**我自己的件**的缺陷（队长另派，归我）
① `P1-fs-destroy-report.md` 末行自证原为**字面占位符**（即未填实的占位 token） ⇒ 填 `cf6f381b985b0d33`；**随后追加 dated 更正**（§7 指针落空，见下）⇒ 按"末行不计自身"规则重算为 **`e0f529e5c35297c7`**（现末行值与 `head -n -1` 重算**一致**）。**新全文 sha256 ＝ `c5ef9d8092dca7704844bd2bcb2d098ac84cd19584ed389e91bef0ae826f72d6`**。
② 同族**第二个漏填**：`P1-fs-page-report.md`（`t123` 载体）末行也是**未填实的占位 token** ⇒ 一并填 **`3110c7003e71bc69`**（**旧全文 `f497fc1f0a62dce5` → 新全文 `5b4ad22c7167bd9a57e70af739863a781f153b6b2ece380694f29f6f391abdb7`**）。
③ `§7` **指针落空**已按 `dated` 追加更正（**上一行原文一字未删**）：原写"读数见 §8 末"，而本件 `HANDOFF-MV`／`HANDOFF_MV` 现取命中 **0**、§8 末只有载体说明段 ⇒ 改成**就地写全可核锚** `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 …`（`cell=#1` `state=equal`，`corrected` ＝ `live`）。⚠️ 另有一句我**不背书**、如实记 **`NOINFO`**：我**没有**"落盘当时该牙曾为 `DIVERGED`"的存活凭证（我车道 `logs/*handoff*.out` 现取**只有 `HANDOFF_MV=PASS` 两条**、`grep -l DIVERGED` 命中 0）⇒ 按"不许引二手话"口径记 `NOINFO(reason=当时读数未落盘)`，**消掉需要**：下次改覆盖面内件时**同趟把该牙输出落盘**。

## §5 未做项与判词
| 项 | 状态 | 缺什么 |
|---|---|---|
| **「段落列表可用」** | **做不了（结构性地）** | `FSPARADESCRIPTION.pfsparaclient` 必须是**托管句柄表**（`_unmanagedHandles`）里的有效索引 ⇒ 只能由**托管侧段落创建路径**产生（`BaseParagraph.Init` 及其调用者）——**非本件写域** |
| **ENFE 归零** | **达成** | 但这只证"该名不缺符号"，**不等于**上述依赖被满足 |
| `FsQuerySubpageDetails` | **不补**（队长明令） | 调用者只有 `FigureParaClient` |
| 「两页真排版」 | **不成立** | 帧去重＝1 |
| `PTSGAP` | **FAIL（残留 1 条）** | 与 `t123`／`t127` 同一条：`:247` dated 历史行缺 `.so` 世代锚 ⇒ 被当现值位；**本件未改牙、未改该行**；现值位已同趟同步（`tool 90`／`ops 78`／`impl 81`／`so16`／`exports=594`），涉及 `docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`src/.../win32_classification.c`／`samples/**` ⇒ **四类件越域，请裁**。 |

## §6 纪律自证
**28**：`cell=#1` 纯 `>>`（662→663）＋ `inputs_fp` 现取 ⇒ `HANDOFF_MV=PASS`｜**29**：改动前 `cp -p`（`~/t123-runner/bak/win32_pts.c.pre-t129`）＋ `evidence/**` 整目录备份 ＋ 本趟真腿产物留档 `run-t129/`｜**30**：三格＋调用序；**"净腿不崩＝假绿"**：本趟两页 `alive=yes` 但**帧仍逐字节相同**、且 `ENFE=0` 而**托管句柄表依赖未满足** ⇒ 未以"不崩/ENFE=0"当排版证据。重活全走槽后台；显示位只用 `:254`（`1280x1024x24`）按 PID 收尾、零残留、未用 `pkill`/`pgrep -f`｜`upstream/**` 只读、`tools/**` 未改、装置件未改｜未 `git add/commit/push`。
**哨兵**：`.so` 换代（`e9b7def842982920 → a4bf2c47f8efb521`）⇒ `SSC=FAIL key=WIN32SHIM got=e9b7def842982920 want=a4bf2c47f8efb521`，**如实报、未自改**（写哨兵是队长的动作）。

---

`P1-FS-PARALIST-REPORT 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 1147fb4c9d74a385（口径＝末行之前的全文；末行＝本行）`
