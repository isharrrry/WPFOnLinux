# `P1-tail2` `TASK-0302` · native「文本行模型」入口 —— 实现报告（`T-A26`）

- **读时**：`2026-09-30T14:5x–15:0x+0800`（本席现取）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=b2ead11`（`T-A25` 落地后；现取）。
- **现件代**：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`3795777128d29995`**（430240 B；改前 **`744fb3affd107bf0`**／425640 B）；`bin/exports.txt` ＝ **677 行**（改前 674）。
- **件指纹（现取；`sha256` 前 16 位）**：`win32_pts.c`＝**`22a3503e37a703b6`**（改前 `a799e9f0f94e7ea4`）｜`pts-gap-decl.txt`＝**`af577ccfad68672e`**（改前 `0b024313f968ddb9`）｜`docs/ROUTES.md`＝`58e1724437112f88`｜`README.md`＝`4efa42b41f27b259`｜`docs/unimplemented.md`＝`41cffa501ebb55f2`｜`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`＝`915f9498a272620c`｜`build/MilBridge/HANDOFF-NEXT.md`＝`2925d9178ef2ac8f`｜`src/WpfGfx.Linux.Native/src/win32_classification.c`＝`077aaf944d7b3523`。
- **改前件备份（仓外）**：`~/tA26-work/win32_pts.c.a799e9f0.bak`／`libwpfwin32.so.744fb3af.bak`／`pts-gap-decl.txt.0b024313.bak`／`exports.txt.674.bak`（＋ 六个复述位件的 `~/tA26-work/routes-bak/`）。
- **只改**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（本增量本体）＋ `bin/exports.txt`（**构建再生成**）＋ `tools/pts-gap-decl.txt`（声明行重锚，`D-G70` 形态）＋ **复述位现值位**（`docs/ROUTES.md` 三处／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`）＋ 本载体。
- **黑名单遵守**：未动 `build/*.Linux/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`；未跑整趟 `verify-all`；重活（构建 ＋ 跑腿）全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`；进程只按 PID；写前 `cp -p` 备份。
- **行号纪律**：本件行号**仅本次有效**（内容锚原文一并给出）。

---

## §0 结论速览（自包含）

1. **现取（契约 ＋ 可得性，逐面）**：三入口 ＝ `FsQueryLineListSingle`（声明 `Pts.cs:3756-3761`；调用点 `PtsHelper.cs:652`）／`FsQueryLineListComposite`（`:3764-3769`；`:671`）／`FsQueryLineCompositeElementList`（`:3772-3777`；`:689`）。**入参可得**（`pPara` 与本侧 `N1` 身份模型同一枚）；**出参无源**（行盒要「行断器 ＋ 字符源 ＋ 度量」，本侧**一个都没有**；源在宿主侧，取它要新开与 LineServices 同规模的链 ⇒ 越级）（§1）。
2. **实现 ＝ 诚实形态**（承 `FsQueryTextDetails`）：**导出符号** ⇒ 三名离开"会 `EntryPointNotFoundException` 的缺口"名单；入参按**对象身份**认领（`pPara` 走 `wpf_pts_sub_claim`／来源证据；`pLine` 本侧无行对象 ⇒ 恒不可认领）；**出参一字不写**（**不写 0**）＋ **恒返 `-10000`** ＋ 具名 `[FS_PAGE_GAP]`（§2）。
3. **两极化（真跑）**：**正极**（主链 `.so`）三名 `rc=-10000 ∧ out 未写` ⇒ 断言 `HELD`（rc=0）；**反极**（副本 `.so` `WPF_PTS_FSQLL_FAKE=1` `700f83eaa3d76218`）三名 `rc=0 ∧ out 被写` ⇒ 断言 **`VIOLATED`（该红必红，rc=1）**（§4）。
4. **成对机读读数（改前 `744fb3affd107bf0` → 改后 `3795777128d29995`）**：`[HC-UNHANDLED]`／`did not complete formatting operation` **113 → 113**；`reason=no-text-line-model` **109 → 109**；`reason=unclaimable-para`／`-subtrack` **0/0 → 0/0**；三入口在产品路径调用数 **0 → 0**（`FsQueryTextDetails` 恒拒 ⇒ 托管走不到它们）；**缺口名单内三名 3 → 0**；`exports 674 → 677`；`tool/dead/artifact/ops/impl 85/11/1/73/76 → 82/11/1/70/73`（§3）。
5. **帧面成对（如实报红，不把空白读成绿）**：`boot.png` `b21eb530afd3c66c`、`k23/k24/last.png` 恒 `ef3fd6765f18f51b` —— **改前后逐字节相同**；`AE(boot,k24)=15386`、`AE(boot,k23)=0`；**具名色锚全 0** ⇒ 两页内容区**没有出现任何非空态像素**（§3.3）。
6. **门禁**：`PTSGAP=PASS`（rc=0、零 `SITE-DRIFT`）｜`DEFREG=PASS declared=225 route_ids=225`（rc=0；⚠️ `DEFREG_DECLDRIFT=1 keys=KD` ⇒ **路由件 `KNOWN-DEFECTS.md` 已改，须主控同趟重发 `declared.tsv`**，纪律 15）｜`REPORTID=PASS files=… declared=225`（rc=0）｜`nm==exports`（677==677、逐名零差异）。
7. **射程边界（如实划界，防被读宽）**：本增量**只**把"缺符号"变成"**有符号的诚实拒绝**"。它**不**声称"文本行模型可得"、**不**声称"页会可见变化"、**更不**构成"排版前进"的证据（`P1-ptsname-result.md` 裁定：**"`ENFE` 归零"本身不构成任何证据**）。**文本行模型本侧仍无源** ⇒ 两页仍**未绘出内容**；这是**合法终点**（具名前置见 §1.3）。

---

## §1 现取：三入口契约与入参/出参可得性

### 1.1 签名/语义契约（上游逐字）

| 入口 | 声明（`Pts.cs`） | 签名（逐字） | 调用点（`PtsHelper.cs`） |
|---|---|---|---|
| `FsQueryLineListSingle` | `:3756-3761` | `int(IntPtr pfsContext, IntPtr pPara, int cLines, FSLINEDESCRIPTIONSINGLE* rgLineDesc, out int cLineDesc)` | `:652` `LineListSimpleFromTextPara` |
| `FsQueryLineListComposite` | `:3764-3769` | `int(IntPtr pfsContext, IntPtr pPara, int cElements, FSLINEDESCRIPTIONCOMPOSITE* rgLineDescription, out int cLineElements)` | `:671` `LineListCompositeFromTextPara` |
| `FsQueryLineCompositeElementList` | `:3772-3777` | `int(IntPtr pfsContext, IntPtr pLine, int cElements, FSLINEELEMENT* rgLineElement, out int cLineElements)` | `:689` `LineElementListFromCompositeLine` |

**调用条件（语义契约）**：三处**均以 `FsQueryTextDetails` 成功为前提**（消费者 `TextParaClient.cs` 的 `_paraHandle`）：先由 `FSTEXTDETAILS`（判别联合）给出 `cLines`／`fLinesComposite`，再按 `fLinesComposite` 走 `LineListSingle`（非复合）或 `LineListComposite`（复合）；对每个 composite line 再调 `LineElementListFromCompositeLine`。

**出参结构（行盒，逐字段；`Pts.cs`）**：`FSLINEDESCRIPTIONSINGLE`（`:1396-1414`：`pfslineclient`／`pfsbreakreclineclient`／`dcpFirst`／`dcpLim`／`urStart`／`dur`／`urBBox`／`durBBox`／`vrStart`／`dvrAscent`／`dvrDescent`／clear/treated 标志）｜`FSLINEDESCRIPTIONCOMPOSITE`（`:1382-1394`：`pline`／`cElements`／`vrStart`／聚合 `dvrAscent`／`dvrDescent`…）｜`FSLINEELEMENT`（`:1359-1380`：`pfslineclient`／`dcpFirst`／`dcpLim`／`urStart`／`dur`／`urBBox`／`dvrAscent`／`dvrDescent`…）。

### 1.2 入参/出参可得性（本席现取，逐面）

- **入参 `pPara`（文本段落句柄）**：**可得** —— 与本侧 `N1` 身份模型**同一枚**（＝ `FsQuerySubtrackParaList` 交回的 `pfspara`；`wpf_pts_sub_claim` 可按对象身份认领；本增量沿用"认领只用于**分离失败原因**、**不**用于伪造成功"的口径）。
- **入参 `pLine`（composite line 句柄）**：**不可得** —— 本侧**无行对象台账**（`win32_pts.c` 内没有 line 表；`grep` 现取 0）⇒ 恒不可认领 ⇒ 具名 `unclaimable-line`（与 `unclaimable-para` **分立**）。
- **出参（行盒 ＋ 计数）**：**无源** —— 行盒要三样本侧**都没有**的东西：**① 行断器**（LS 族 27 入口现取 22 缺、本侧 0 实现）／**② 字符源**（`dcp`↔字符；内容在宿主侧）／**③ 度量**（字宽/字体；对应 LS 回调面 **30 槽**，本侧一槽未接）。⇒ 填任何行盒数都是**自造**（判据件 `build/MilBridge/P1-layout-content-criteria.md` §3.3／§4.1；`T-A25` 载体 §5-3 同结论）。
- ⇒ **结论**：三入口的**诚实形态**只能是"**有符号的诚实拒绝**"；`rc=0` 只在**反腿**出现。

### 1.3 具名前置（合法终点；**越级**，另派）

- **`NOINFO-text-line-model-source`**（射程＝**行盒这一面没源**；入参面已认领）。
- 要取源，须**新开一条与 LineServices 同规模的链**：LS 族 **27 入口**（22 缺）＋ **回调面 30 槽**＋ **字符源入站**＋ **文本段落进链** —— 属 `P1-layout-content-criteria.md` 的**越级**判断（`PRECOND-NEW-CALLBACK-FACE`／`NO-TEXT-SOURCE`／`NO-LINE-BREAKER`／`NO-TEXT-PARA-IN-CHAIN`）。**本增量不触此越级。**

---

## §2 实现（`win32_pts.c`，诚实形态）

### 2.1 落点（逐处）

| 落点 | 内容 |
|---|---|
| `wpf_pts_line_reject`（新，静态） | 三入口共用的**诚实拒绝**实现：①`null-count-out`（出参 NULL）②`null-para`／`null-line`（对象 NULL）③`wpf_pts_sub_claim` 认领失败 ⇒ 追加来源证据认领：认出 ⇒ `claimed-by-provenance-no-text-line-model`，认不出 ⇒ `unclaimable-para`／`unclaimable-line` ④ `unknown-ctx` ⑤ 认领成功 ⇒ **`no-text-line-model`**（出参无源）。**任一路径：出参（行盒数组 ＋ 计数字段）一字不写 ＋ 恒返 `-10000` ＋ 具名 `[FS_PAGE_GAP]`**。 |
| `FsQueryLineListSingle`（新导出） | 调 `wpf_pts_line_reject(..., "para", ...)`；`rgLineDesc` 刻意只收不用。 |
| `FsQueryLineListComposite`（新导出） | 同上（`"para"`）。 |
| `FsQueryLineCompositeElementList`（新导出） | 同上，`objkind="line"`（`pLine` 本侧无行对象 ⇒ 恒拒）。 |
| 反腿开关 `WPF_PTS_FSQLL_FAKE` | 缺省 `0`（主链零影响）；`1` ⇒ 三名**假成功**（返 `0` 并把计数出参写成入参）—— **只在副本**编译。 |
| 计数面 `g_pts_fsqll_*` | `calls`／`gap`／`nullout`／`nullobj`／`unclaim`／`unknownctx`／`nomodel`（诊断口，随 `[FS_PAGE_GAP]` 逐行给出）。 |

### 2.2 🔴 无假值／无假成功（硬边界逐条）

1. **出参一字不写**：行盒数组与 `cLineDesc`／`cLineElements` **绝不触碰** —— 特别注意 **不写 0**：写 0 会被消费者读成"**0 行**"，`TextParaClient` 走**空行分支** ⇒ **静默丢整段文本**（`P8` 恒绿陷阱，`P1-ptsname-result.md` 裁定四十八 (c)）。
2. **无成功分支**：主链**恒返 `-10000`**；`rc=0` 的出现**只能**来自反腿。
3. **失败必留痕**：每趟一行具名 `[FS_PAGE_GAP]`（含 `reason=`／`entry=`／逐路计数）。
4. **不伪造身份**：`pLine` 恒不可认领（本侧无行对象）⇒ 判词与 `pPara` **分立**为 `unclaimable-line`。

---

## §3 成对机读读数（改前腿 `~/tA25-work/evidence-after` vs 改后腿 `~/tA26-work/evidence-after`）

同一跑器 `run-pts-pages-legs.sh`（`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=962fec114b2d0692`）、同一显示流程（A 臂 = 现权威件；`:231`；1280x1024x24）。

### 3.1 装配自证（改后趟，现取）

```
APPSYNC:  SYNC-APPLOCAL=PASS target=/home/links-dev/w67-work/app items=5 ok=5 synced=0 created=0 drift=0 noauth=0 same=0 rc=0
AUTHORITY: shim=3795777128d29995 pf=1757d610a687777c ｜ APPDIR: shim=3795777128d29995 pf=1757d610a687777c
X_UP=yes display=:231 ｜ POSTSHIM: shim=3795777128d29995 pf=1757d610a687777c（== authority ⇒ 读数可归因）
LEGSCOUNT requested=2 obtained=2 refused=0 reasons=none display=:231 rc=0 session_rc=0 conv_rc=0
LEGS_RUNNER=PASS requested=2 obtained=2 refused=0 display=:231
```

### 3.2 靶面成对（改前 → 改后）

| 面（现取 `app_g1.log` 逐字计数） | 改前 `744fb3affd107bf0` | 改后 `3795777128d29995` |
|---|---|---|
| `[HC-UNHANDLED]` | **113** | **113** |
| `did not complete formatting operation` | **113** | **113** |
| `[FS_PAGE_GAP] reason=no-text-line-model` | **109** | **109** |
| `reason=unclaimable-para` ｜ `…-subtrack` | 0 ｜ 0 | 0 ｜ 0 |
| `reason=unclaimable-line` | 0 | 0 |
| 三入口在产品路径的调用数（`FsQueryLineListSingle`／`…Composite`／`…CompositeElementList`） | 0／0／0 | 0／0／0 |
| `EntryPointNotFoundException` | 0 | 0 |
| **缺口名单内三名（`check-shim-coverage.py`）** | **3**（名单逐名在册） | **0** |
| `tool`／`dead`／`artifact`／`ops`／`impl` | 85／11／1／73／76 | **82／11／1／70／73** |
| `exports`／`nm -D --defined-only` | 674／674 | **677／677** |

> ⚠️ **"三名在产品路径调用数 0 → 0"是结构性的、如实记**：`FsQueryTextDetails` 恒拒（`no-text-line-model`）⇒ 托管侧**走不到**三入口（三入口的前置 `cLines` 拿不到）。⇒ 本增量**不改变**产品运行期行为（`[HC-UNHANDLED]`／`no-text-line-model` 逐字不变）；三入口的**诚实拒绝行为**由 §4 的**直接调用探针**证明（不靠产品腿）。

### 3.3 帧面成对（**不把空白读成绿**）

| 面 | 改前 | 改后 |
|---|---|---|
| `boot.png` `sha16` | `b21eb530afd3c66c` | **同**（逐字节相同） |
| `k24.png`／`k23.png`／`last.png` `sha16` | `ef3fd6765f18f51b` | **同**（三者恒同） |
| `AE(boot,k24)`／`AE(boot,k23)` | 15386／0 | **15386／0** |
| 具名色锚（`GhostWhite/Beige/DarkGreen/LightGoldenrodYellow`） | 0/0/0/0 | **0/0/0/0** |

⇒ **两页内容区没有出现任何非空态像素**（改前后**逐字节相同**）；本件**明确判红**，并**不以"帧没变"读成绿**。

### 3.4 症状门成对（同一跑器、相邻代、同一显示流程）

| 面 | 改前 | 改后 |
|---|---|---|
| leg24 `alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`／`fr_sha` | `yes`／`143`／`0`／`383`／`480000`／`…FlowDocumentDemo`／`ef3fd6765f18f51b` | **同** |
| leg23 `alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`／`fr_sha` | `yes`／`143`／`0`／`383`／`480000`／`…RichTextBoxDemo`／`ef3fd6765f18f51b` | **同** |
| `CLICK` 的 `guard=`（`[HC-UNHANDLED]` 计数，k24/k23） | `27`／`92` | **`27`／`92`** |
| `fatal`／`unh` | `0`／`0` | `0`／`0` |
| `five_stable`／`x_up` | `yes`／`yes` | `yes`／`yes` |

### 3.5 复述位随动（`PTSGAP=PASS`）

`bash build/MilBridge/tools/pts-gap-count-check.sh` 现取：`LIVE tool=82 dead=11 artifact=1 ops=70 impl=73 so16=3795777128d29995 exports=677` ⇒ `PTSGAP=PASS`（零 `SITE-DRIFT`）。随动件：`docs/ROUTES.md`（三处：TASK-0302 树行／TASK-0720 现值位／§13 行）／`README.md`／`build/MilBridge/HANDOFF-NEXT.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`docs/unimplemented.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`。

---

## §4 反极性（**副本**上真跑，该红必红）

**探针**（仓外 `~/tA26-work/probe.c`，`dlopen` ＋ `dlsym` 后**直接调用**三入口）：`pPara=0x4`（**不可认领**的非本侧值）；出参先投毒 `0x5A5A`；断言 ＝ **「不可认领必被拒 ∧ 出参一字不写」**。

```
=== 正极：主链 .so（3795777128d29995）===
PROBE FsQueryLineListSingle rc=-10000 out=0x5A5A out_written=0
PROBE FsQueryLineListComposite rc=-10000 out=0x5A5A out_written=0
PROBE FsQueryLineCompositeElementList rc=-10000 out=0x5A5A out_written=0
ASSERTION HELD(拒 ∧ 未写)                                  rc=0

=== 反极：副本 .so（WPF_PTS_FSQLL_FAKE=1；700f83eaa3d76218）===
PROBE FsQueryLineListSingle rc=0 out=0x3 out_written=1
PROBE FsQueryLineListComposite rc=0 out=0x3 out_written=1
PROBE FsQueryLineCompositeElementList rc=0 out=0x3 out_written=1
ASSERTION VIOLATED(必红)                                    rc=1
```

**具名留痕（主链 .so，stderr 逐字）**：
```
[FS_PAGE_GAP] rc=-10000 reason=unclaimable-para entry=FsQueryLineListSingle ctx=(nil) obj=0x4 c=3 … unclaim=1 … out=UNWRITTEN bytes=0
[FS_PAGE_GAP] rc=-10000 reason=unclaimable-para entry=FsQueryLineListComposite ctx=(nil) obj=0x4 c=3 … unclaim=2 … out=UNWRITTEN bytes=0
[FS_PAGE_GAP] rc=-10000 reason=unclaimable-line entry=FsQueryLineCompositeElementList ctx=(nil) obj=0x4 c=3 … unclaim=3 … out=UNWRITTEN bytes=0
```

⇒ **该红必红**（两条独立证据）：① 机械面 **`rc=0 ≠ -10000` ∧ `out_written=1`**（假成功当场可见）；② 判词面 **`unclaimable-para` 与 `unclaimable-line` 分立**（`pLine` 无源 vs `pPara` 无源的**对称性**被证明是**按对象**判的，不是常量）。

> ⚠️ **装置如实记**：反腿副本 `700f83eaa3d76218` 的编译期告警 `wpf_pts_line_reject defined but not used`（`FAKE=1` 时该助手被 `#if` 排除）—— 这是**预期**（副本形态），**不是**主链产物的问题。

---

## §5 验收逐条

- **① 三入口签名/语义与入参/出参可得性现取**：§1（含逐字段结构 ＋ 调用条件 ＋ 可得性三面）。
- **② 靶 `ENFE`／`no-text-line-model` 计数成对；`[HC-UNHANDLED]` 成对**：§3.2（`no-text-line-model 109→109`；`[HC-UNHANDLED] 113→113`；缺口名单内三名 **3→0**）。
- **③ 帧面成对（不把空白读成绿）**：§3.3（`boot`／`k23`／`k24` 逐字节相同；色锚全 0 ⇒ **如实判红**）。
- **④ 导出面 `nm==exports`；`PTSGAP=PASS`；`DEFREG`/`REPORTID` rc=0**：`nm -D --defined-only` 行数 == `exports.txt` 行数 == **677**（逐名零差异；三名**新增**、无消失）；`PTSGAP=PASS`（§3.5）；`DEFREG=PASS declared=225 route_ids=225`（rc=0）；`REPORTID=PASS declared=225`（rc=0）。
- **⑤ 症状门成对**：§3.4（六项逐字相同）。

---

## §6 边界 · `NOINFO` · 主动披露

1. **未改任何其它仓内文件**；`git status --porcelain` 现取 ＝ `M README.md`／`M build/MilBridge/HANDOFF-NEXT.md`／`M docs/ROUTES.md`／`M docs/unimplemented.md`／`M samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`M src/WpfGfx.Linux.Native/src/win32_classification.c`／`M src/WpfGfx.Linux.Native/src/win32_pts.c`／`M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` ＋ 两项**先于本件**的 untracked（`build/MilBridge/tasks-tail2/T-A26.md`／`build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`）。**注**：`bin/libwpfwin32.so`／`bin/exports.txt` 是**构建生成件**（`git ls-files` 现取 0 ⇒ 不入库），不计入改动面。
2. **`DEFREG_DECLDRIFT=1 keys=KD`（主控待办，纪律 15）**：本次改了路由件 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` ⇒ **须主控同趟重发 `build/MilBridge/tools/defect-registry-declared.tsv`**（`DEFREG` 本体 rc=0，`declared=225 route_ids=225` 不漂）。
3. **`NOINFO-text-line-model-source`**（射程＝行盒这一面没源；§1.3）。
4. **`NOINFO-claimable-para-leg-not-run`（具名）**：`FsQueryLineList*` 的"**认领成功 ⇒ 落 `no-text-line-model`**"这一支**本趟未跑** —— 本仓**没有导出的"可认领 `pPara` 生产者"**（`wpf_pts_sub_handle` 只在 `FsQueryTrackParaList` 的探针驱动路径内产生，且需一个活的 `doc` 上下文）⇒ 该支在**探针**上不可达（**不是**"它错了"）。§4 证明的是**认领失败支**（`unclaimable-para`／`unclaimable-line`）＋ **出参零写**。
5. **`NOINFO-frontier-carrier-stale`**：`PTSGAP` 的前沿载体 `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log`（`84db0eb62d15e0b2`）**未随本趟更新**（不在本件写域）⇒ `PTSGAP_FRONTIER … after=FsQueryTrackParaList@1117` 是**上一代**读数；`PTSGAP=FAIL` 的"假进度必红"判据**未触发**（`impl 73 < 95` ∧ 前沿名 ≠ `LoCreateContext`）。**本件据此如实划界**：`PTSGAP=PASS` 的射程**不含**"前沿已位移"。
6. **未做**：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；未动任何牙本体；未 `git add/commit/push`。
7. **代际**：`.so`＝`3795777128d29995`；`win32_pts.c`＝`22a3503e37a703b6`；`pts-gap-decl.txt`＝`af577ccfad68672e`；`exports.txt`＝`c561dda4eca311c5`（677 行）；改前 `744fb3affd107bf0`／`a799e9f0f94e7ea4`／`0b024313f968ddb9`／674 行。
8. **副作用物（仓外）**：`~/tA26-work/`（改前备份 ＋ 改后证据 `evidence-after/` ＋ 反腿副本 `replica/` ＋ 探针 `probe`／`probe.c`）；`~/w67-work/app`（已刷成改后权威件，`SYNC-APPLOCAL=PASS drift=0`）。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-textline-impl-report.md | sha256sum | cut -c1-16`）= `f5fd84ecc942e817`
