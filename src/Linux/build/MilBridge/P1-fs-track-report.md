# P1-W48 · `FsQueryTrackDetails`（＋同趟 `FsCreatePageFinite`）—— **落盘中的「清单 ＋ 现状」最小载体**（先落盘，防整件凭空消失）

> **本件先落盘**（队长明令：「若推进不动，先落一份含『清单＋现状』的最小载体再报」）。**届时会就地追加**实现读数（只增不改）。
> **前序**：`t125`（我上趟 in-flight 补充）已入库（`38541c1`），回归已解；本件是**下一站**。
> **读取时刻**：`ts=2026-09-29T13:2x`（起）。

---

## §0 现状（现取，可复算）

```
HEAD           = 38541c1（t125 已入库）
so16           = e08167eef3c4a14e   exports = 584   ^Fs = 3
  FsCreatePageBottomless  nm=1      FsQueryPageDetails nm=1      FsDestroyPage nm=1
  FsQueryTrackDetails     nm=0  ← **本件靶心①**   FsCreatePageFinite nm=0 ← **本件靶心②**
真腿 ENFE（上一趟现取）：ENFE_TOTAL = 1102 = **1101×FsQueryTrackDetails** + 1×FsCreatePageFinite
```

## §1 队长点名的「钥匙 vs 其后要撞的」现取分析（本件第一产出）

**靶心① `FsQueryTrackDetails`（1101 次）＝ 当前挡住链的那一步**。调用点全集（现取去重）：
`PtsHelper.cs`×5／`SubpageParaClient.cs`×3／`FlowDocumentPage.cs`×3／`FloaterParaClient.cs`×2／`FigureParaClient.cs`×2。

**关键现取（`FlowDocumentPage.cs:425-450`，逐字）**——这是"1101 次"的来源：
```
PTS.FSPAGEDETAILS pageDetails;
PTS.Validate(PTS.FsQueryPageDetails(…, _ptsPage.PageHandle, out pageDetails));      // 我们已实现
if (PTS.ToBoolean(pageDetails.fSimple))                                            // 我们回填 fSimple=1
{
    PTS.FSTRACKDETAILS trackDetails;
    PTS.Validate(PTS.FsQueryTrackDetails(…, pageDetails.u.simple.trackdescr.pfstrack, out trackDetails));  // ← 1101 次
    if (trackDetails.cParas > 0) { …建立 ColumnResult… }
}
```
⇒ **两个现取结论**：
1. **`FsQueryTrackDetails` 的入参 `pTrack` 就是我们在 `FSPAGEDETAILS.u.simple.trackdescr.pfstrack` 里给的那个字段**；
2. **而我们上一步 `memset(d,0,…)` 之后没有填 `pfstrack`** ⇒ 传下去的是 **`NULL`**；
   ⇒ 所以**只补 `FsQueryTrackDetails` 而不管 `pfstrack`** 的话，它会**必然收到 NULL** —— 而"对 NULL 返 0"就是**假成功**（判据最忌讳），"对 NULL 返非 0"则等同**没修**。
   ⇒ **「钥匙」＝ 让 `pfstrack` 真的指向一个**我方可识别的 track 对象**（在 `FsQueryPageDetails` 里回填）＋ `FsQueryTrackDetails` 按该句柄回答 `cParas`**；**「其后要撞的」＝ `FsCreatePageFinite`（1 次，`PtsPage.cs:397` 的整页路径）**。
3. `FSTRACKDETAILS` **只有一个字段 `int cParas`**（现取 `Pts.cs:1512-1515`）⇒ 本步可给的**最小可辩护**语义 ＝ "该 track 里有几段"；且只有 `cParas > 0` 时下游才会继续建列。

## §2 本件的实现计划（写死，随后逐条落读数）

| 项 | 内容 |
|---|---|
| `FsQueryPageDetails` **补回填** | 在 `trackdescr` 里再回填 **`pfstrack ＝ 该页对象上一个真字段的地址`**（与 `penalty_module_handle` 同形制：字段在对象里 ⇒ 句柄＝该字段地址 ⇒ **身份可逐位核**，无需偏移推算） |
| **靶心①** `FsQueryTrackDetails` | `int FsQueryTrackDetails(void *pfscontext, void *pTrack, void *pDetails)`；按**指针身份**认 track（不 deref 未知句柄）⇒ 回填 `cParas`（**按对象/按页存的值**，非全局常量）；失败留痕 `[FS_PAGE_GAP]`；**NULL／未知 ⇒ 拒**（不许假成功） |
| **靶心②** `FsCreatePageFinite` | `int FsCreatePageFinite(void*, void *brIn, const void *sect, void *pFSFMTRout, void **ppPageOut, void **ppBRPageOut)`；成功 ⇒ 真页对象（与 `FsQueryPageDetails`／`FsDestroyPage` **同一张表** ⇒ 生命周期可收）＋ `FSFMTR`（**struct**：3 个 int 宽）；失败 ⇒ 清三个出参＋留痕 |
| 新格 | 格 `89`（旧格号 0–88 一个未动）；夹具**自建自收**（含 `FsDestroyPage` 回收）⇒ 幂等、上限足够大 |
| 铁律 | 不静默 stub；返非 0 native 侧留痕；**未新增源件 ⇒ `SRCS` 无需改**（完整性仍现核）；导出**逐名点名**；`N1–N4` 口径；逐腿 `DEV shim=` 同趟；截图三格；纪律 30 三格（含"净腿不崩＝假绿"）；UTF-16 元数据双查 |

## §3 未做项（此刻）
- `FsQuerySubpageDetails`：**不补**（队长明令；我上趟已现取判明其调用者只有 `FigureParaClient`，不在销毁路径）。
- 「两页真排版」：**本步不承诺**（沿用 `N1–N4` 口径；帧去重仍须现取）。

---


---

## §4 「**字段级诚实性**」判据（裁定二十七 追加要求②）＋ 一对反腿

**族属（队长要求写明，不另开一套）**：本判据与**裁定二十三「不许静默 stub」同族** —— 两者都是
「**账面（返回值／计数器／台账行）对了，而交出去的东西没用**」。裁定二十三管**入口面**（返 `0` 却
什么都不做）；本判据把同一族的口径推到**数据字段面**（字段非空、却不是"我们自己的、可身份校验的"那个）。

**判据（两条并列，缺一即红）**：
1. **可身份校验**：该句柄**等于我们登记表里某个对象内那个字段的地址**（只做**指针值比较**，**不 deref
   未知指针** ⇒ 全局常量／栈地址／伪造地址**必然不满足**）；
2. **非空可用**：句柄 ≠ `NULL` **且**它真能驱动下游（本条＝`FsQueryTrackDetails` **认**它）。

**一对反腿（共用同一个谓词 `wpf_pts_track_owned()`，格 `89` 内现取）**：
| 腿 | 构造 | 现取 | 点名 |
|---|---|---|---|
| **a)** 交 `NULL` | `wpf_pts_track_owned(NULL)==0` ∧ `FsQueryTrackDetails(ctx,NULL,…)` 必被拒 ∧ 出参清 0 | **红并点名** | 字段 `td_pfstrack`／`track` |
| **b)** 交**看似真、实则伪**（栈上局部变量地址 `&fake_paras`） | `wpf_pts_track_owned(&fake_paras)==0` ∧ 必被拒 | **红并点名** | 同上（⇒ **全局常量/栈地址一律不可用**） |
⇒ 两腿**同一谓词**判，不达标即红 —— 与"只堵入口面"的老口径相比，这一格**多了"是不是我们的"这一问**。

## §5 🔴 真缺陷登记（裁定二十七 追加要求①）—— **上一手的实现不完整**

**事实（现取，可复算）**：`t125` 那一手（`FsQueryPageDetails` 真实现）**只填了部分字段**：
它回填了 `fSimple=1`／`fsrc`／`fsbbox`，**但没填 `u.simple.trackdescr.pfstrack`**（`memset` 之后
该字段一直是 `0`）。而托管侧正是拿**这一个字段**去调 `FsQueryTrackDetails`
（`FlowDocumentPage.cs:440`）⇒ **1101 次调用全部被喂了 `NULL`**。

**为什么它是"真缺陷"而不是"工作量"**：
- 它是**实现不完整**（字段级），而**不是**"某入口还没做"；
- 它的后果**只以"另一个名字的 ENFE"显形**：`ENFE` 面从 `1152 → 1102`，看起来像"又缺一个入口"，
  **真实原因却是上游那个入口已经存在、只是句柄字段是 `NULL`** ⇒ 若照"按 ENFE 名字逐个补入口"的
  直觉走，会**永远补不到根上**（这与前两次 `t123`／`t125` 的教训同形：**入口不是钥匙、数据字段才是**）；
- 它还**开了第二条假绿通路**：若我当时把 `FsQueryTrackDetails` 对 `NULL` 返 `0`（"无害"），
  `ENFE` 会归零、进程不崩、而**下游拿到 0 段 ⇒ 什么都排不出来** ⇒ **账面全绿而东西没用**
  （正是裁定二十三要堵的形态，只是这次发生在**字段面**）。

**建议：立号（`D-G` 族），机制与修法如下（仅供裁定，本件**未**改 `tools/**` 与 `KNOWN-DEFECTS.md`）**
- **建议号型**：`D-G`（产品缺陷族，与 `D-G70`／`D-G78` 同族：都是"PTS 面账面对而下游没用"）。
- **机制（写死）**：结构体字段**只 `memset` 不逐字段回填** ⇒ 调用方拿到**合法但无效**的句柄；
  其后果以**另一个入口的 `ENFE`** 显形 ⇒ **归因陷阱**。
- **修法（本件已落，作为修法样本）**：① 逐字段回填**所有**调用方会读的句柄/指针字段；
  ② 句柄一律取"**本对象内该字段的地址**"（⇒ **可身份校验**，且天然非空）；
  ③ 用 `_Static_assert` **把每个字段偏移钉死在编译期**；④ 加"字段级诚实性"谓词 ＋ 两条反腿（§4）。
- **⚠️ 本件自己的实证（同一族、同一趟）**：我**首版**就把 `pfstrack` 写错了偏移（把 `FSUPDATEINFO`
  当成 16 B ⇒ 整块后移 8 B）⇒ 托管侧在我以为的 `pfstrack` 处读到 `0x30000000000`
  （＝我们 `b_defined` 与 `b_du` 的合成）⇒ `FsQueryTrackDetails` 报 `unknown-track-or-not-ours`
  **× 1129**。**修法就是上面第四条**：偏移用**实测**钉死（`_Static_assert` ＋ 偏移探针），
  不靠心算。⇒ **本条本身即是"立号理由"的活证据**。

## §6 本件现取读数（成对）

### 6.1 入口面（ENFE）—— 本步两名归零，链又前进一站
```
ENFE_TOTAL = 1085        （before 1102；t123 那趟 1 —— 那是"崩在更早"的假象）
   1085  FsQueryTrackParaList   ← **下一站**（本步非目标）
  FsQueryTrackDetails      ENFE = 0   ✓ 本步靶心①（before 1101）
  FsCreatePageFinite       ENFE = 0   ✓ 本步靶心②（before 1）
  FsCreatePageBottomless / FsQueryPageDetails / FsDestroyPage  ENFE = 0  ✓（前两趟达成，未回退）
  FsQuerySubpageDetails    ENFE = 0   （未补，按队长明令；本装置未撞到）
```
### 6.2 **字段面**（本步的承重读数）—— 1129 次拒绝 → **0**
```
                修前（pfstrack 错位）        修后
FS_PAGE_GAP 行   **1129**（全 = FsQueryTrackDetails, reason=unknown-track-or-not-ours）
                                              **0**  ⇒ `FsQueryTrackDetails` **全部成功**
托管侧收到的句柄 0x30000000000（**不是我们的**）  +64 处 = 我们对象内字段地址（`owned==1`）
```
### 6.3 症状 / 回归（零回归）
```
k=23 alive=yes app_rc=143 magenta=0 colors=383 ae=0     ink=480000
k=24 alive=yes app_rc=143 magenta=0 colors=383 ae=15386 ink=480000
gap=0  unavail=0  **failfast=0**  unrec=0  fontfb=6（字体栈降级未碰坏）
```
### 6.4 同趟与截图三格
```
逐腿 DEV shim=e9b7def842982920 ＝ 现盘 .so ✓；session shim_sha16=e9b7def842982920
shotstat(k24)=383/0/480000 ＝ leg_24.env（**逐格相等** ✓）；k24.png sha256=ef3fd6765f18f51b
🔴 **帧去重仍 ＝ 1**（k23 = k24 = ef3fd6765f18f51b）⇒ 按 `N3` **判红**；本件**不给** `N1`/`C6`/`C8` 绿
   （`ink` 同值零区分力；`ns=` 不承担内容身份；正身份 **`NOINFO`**）
```
### 6.5 导出面（逐名点名）
```
so16=e9b7def842982920  exports=591  ^Fs=5  nm=exports=591（无导出消失）
新增 7 条：FsQueryTrackDetails / FsCreatePageFinite /
           WpfLinuxWin32_PtsFs{Track,Finite}{Ok,Gap} / WpfLinuxWin32_PtsTrackOwned
```
### 6.6 自检（格 `89`；fresh ＋ 带历史独立进程）
```
连跑 12 次：rc=1 diag=0  live=0（**幂等**；夹具自建自收，含 FsDestroyPage 回收 ⇒ 不逼近上限）
带历史：rc=1 diag=0
三格：① fresh（另给带历史独立进程）② 前置量 live/qpd/trk/fin/des 当时值 ③ 判词 rc/diag
```
**本件自查抓到并修掉的一处夹具缺陷（纪律 30）**：我的拒绝面调用**复用了 `pfa`/`bra`** ⇒ 把要收尾的
真页句柄覆盖成 `NULL` ⇒ 出口 `FsDestroyPage` 变成"销毁 NULL" ⇒ **对象漏在表里**（实测 `live` 每跑 +1、
`des` 恒 0）⇒ 改成**一次性局部出参**后 `live=0`、`des` 逐次 +1。⇒ **"净腿绿"再次骗人**的实例。

### 6.7 `PTSGAP`
`PTSGAP=FAIL`，**唯一残留仍与 `t123` 同一条**：`SITE-DRIFT docs/ROUTES.md impl`（`:247` 那条 **dated
历史行**缺 `.so` 世代锚 ⇒ 被当现值位）。本件**未改牙、未改该 dated 行**。现值位已同趟同步
（`tool 91`／`ops 79`／`impl 82`／`so16=e9b7def842982920`／`exports=591`），涉及 `docs/ROUTES.md`／
`README.md`／`docs/unimplemented.md`／`src/.../win32_classification.c`／`samples/**` ⇒ **四类件越域，请裁**。

## §7 纪律自证
**28**：`HANDOFF-NEXT.md` 纯 `>>` 追写 `cell=#1` ＋ `inputs_fp` 现取｜**29**：改动前逐件 `cp -p`
（`~/t123-runner/bak/win32_pts.c.pre-t127`）＋ `evidence/**` 整目录备份 ＋ 两趟真腿产物留档
（`run-t127/`、`run-t127b/`）｜**30**：三格＋调用序；**"净腿不崩＝假绿"本件两实证**：①夹具 `live` 漏对象
而 `rc=1`；②真腿 `alive=yes` 而帧仍逐字节相同（`ENFE=1085`）。重活全走槽后台；显示位只用 `:252`／`:253`
（`1280x1024x24`）按 PID 收尾、零残留、未用 `pkill`/`pgrep -f`；`upstream/**` 只读；**未改** `tools/**`；
未 `git add/commit/push`。**哨兵**：`.so` 两度换代（`bbd249a6…` → `e9b7def8…`）⇒ 哨兵位陈旧，**如实报、未自改**。

## §8 未做项
| 项 | 状态 | 缺什么 |
|---|---|---|
| `FsQueryTrackParaList`（ENFE 1085） | **非目标** | **下一站**（本步之后紧接要撞的） |
| `FsQuerySubpageDetails` | **不补**（队长明令） | 调用者只有 `FigureParaClient`，不在本路径 |
| 复杂页（`fSimple=0`） | **未实现** | 本模块只填简单页形态；`complex` 分支不声称支持 |
| 「两页真排版」 | **不成立** | 帧去重＝1、`ENFE_TOTAL=1085` ⇒ **本步的绿只准读成「这两个入口不再缺、且它们交出的句柄字段可身份校验且非空」** |
| `PTSGAP` | **FAIL（残留 1 条）** | §6.7 |

---

`P1-FS-TRACK-REPORT 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 344dbadf7c516682（口径＝末行之前的全文；末行＝本行）`
