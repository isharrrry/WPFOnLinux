# P1-tail2 · `T-A19` · 选靶 ＋ 诚实实现（`FsUpdateBottomlessPage`）＋ 复述位随动 —— native 主链实现（`TASK-0302` 增量）

> **本件 `T-A19`（实现子代理；本轮唯一写者）交付**。**写域**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（手写源）＋ 其**登记面**（`tools/pts-gap-decl.txt` 声明行 ＋ dated 重锚注释；`bin/exports.txt`／`bin/libwpfwin32.so` 由重建刷新）＋ **复述位现值位**（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`）＋ 本载体。
> **未碰**：`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（牙本体）／`build/*.Linux/**`（生成件）／任何 `.cs`；`git add/commit/push` **未做**。
> **上游契约**：声明 `Pts.cs:3135-3139`；调用点 `PtsPage.cs:347`（`PtsPage.UpdateBottomlessPage()`）。
> **行号纪律**：本件所有行号**仅本次有效**；引件一律给内容锚。
> **重活**：构建 ＋ 跑腿**全部**走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- …`；进程只按 PID；显示位只用空闲 `:231`（装置自配）；**未跑**整趟 `verify-all`；写前 `cp -p` 备份；模式守恒（`%a` 逐件见 §5-6）。
> **⚠️ 本件有一处**同趟 A/B**：为拿"同装置/同会话/同腿器/同 `pf`"的成对读数，**临时**把权威 `.so` 换回**改前件**跑一趟（`evidence-beforenow/`），随后**逐字节还原**新件（`cmp` 现取 `RESTORED-IDENTICAL`）—— 见 §6-1。

---

## §0 结论速览（自包含）

1. **选靶（`[HC-UNHANDLED] 904` 按入口名分类，现取）**：`550 FsQueryTrackParaList`｜`352 FsQuerySubtrackDetails`｜`1 FsQueryTextDetails`｜`1 FsUpdateBottomlessPage`。**有源/无源判定**（§1）⇒ 两个高计数项**出参/入参无源**（只能诚实拒绝，且**已是**诚实拒绝）⇒ **最高计数且有源者 ＝ ENFE 对照的两名（并列 `1`）**；按"出参有源"细分取 **`FsUpdateBottomlessPage`**（其出参 `FSFMTRBL` 与**同侪** `FsCreatePageBottomless` **同类型同源**；`FsQueryTextDetails` 的出参 `FSTEXTDETAILS` 需文本行模型 ⇒ 本侧无源）。**选靶 ＝ `FsUpdateBottomlessPage`**。
2. **做了什么**：native 新增**导出** `FsUpdateBottomlessPage`（诚实形态；`rc=0` 只在**页在册**时给；失败必留痕；出参按语义先清"未达成"）。
   - **该靶 `ENFE` 归零**：`entry point named 'FsUpdateBottomlessPage'` **`1 → 0`**（同趟 A/B，`§3`）。
   - **它真被用到且真成功**：`[FSUPDFSP] rc=0 … basis=refresh-page-owned-bottomless-state` **`0 → 55`**（**同一趟单变量 A/B**）。
3. **验收（逐条见 §3–§8）**：
   - ② 该靶 ENFE **成对 `1 → 0`**；`[HC-UNHANDLED]` 面 **`913 → 433`**（同趟 A/B，`§3`）。
   - ③ 导出面：`nm -D --defined-only` **673** == `bin/exports.txt` **673**（vs 改前 672：**逐名 +1、无消失**）。
   - ④ **`PTSGAP=PASS`**（`rc=0`、**零 `SITE-DRIFT`**）；逐处 before→after 见 §5。
   - ⑤ 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）**逐字段成对不变**；三帧 `sha256` **逐字节不变**（`ef3fd6765f18f51b`；`AE(k23,k24)=0`）；`DEFREG` **rc=0**；`REPORTID` **rc=0**。
4. **口径重申（防过读）**：**"该靶 ENFE 归零" ≠ "两页真排版"** —— 本增量把"缺符号"变成"有符号"，并把"页对象自持状态的刷新"落成**可现取**；**帧面一格未动**。**总 `ENFE` 反而 `<2 → 53>`**（＝链**驱得更深**，暴露**新前沿 `FsQueryTextDetails`**）⇒ **"计数下降/上升都 ≠ 能力进/退"**（照 `pts-gap-count-check.sh` 件头第 ① 条）。
5. **下一站（具名，防被读成"没做完"）**：现读具名新前沿 ＝ **`FsQueryTextDetails`**（`ENFE 1 → 53`；其出参 `FSTEXTDETAILS` **本侧无源** ⇒ 只能诚实拒绝，属**下一增量**的选靶对象）；`FsQuerySubtrackDetails` 仍在册 `380` 次拒绝（`unclaimable-subtrack`，入参无源）。

---

## §1 ① 选靶清单（现取）

### 1.1 分类方法（可复跑）

`[HC-UNHANDLED]` 行的"入口名"＝该异常行**之前最近一条带具名 `entry=` 的 native 台账行**（`[FS_PAGE_GAP]`／`[FSQSTD]`／`[FSQSPL]`）的 `entry=`；`EntryPointNotFoundException` 行直接取 `entry point named '<名>'`。取数件＝在册证据 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2b/app_g1.log`（`sha16=156e9e9a6e1d9c9a`／`1259182 B`；**＝现件代 `.so 9c19dc0fef35cf4a` 的腿**）。

```
$ python3 /tmp/classify19.py build/MilBridge/tests/PtsPagesProbe/evidence-tail2b/app_g1.log
   550  PtsException(-10000)::FsQueryTrackParaList
   352  PtsException(-10000)::FsQuerySubtrackDetails
     1  ENFE::FsQueryTextDetails
     1  ENFE::FsUpdateBottomlessPage
TOTAL 904
$ grep -c '\[HC-UNHANDLED\]' …/evidence-tail2b/app_g1.log     # ⇒ 904
```

### 1.2 清单（入口名 ／ 计数 ／ 类别 ／ **有源判定**）

| # | 入口名 | 计数 | 类别（现取） | 入参有源？ | **出参有源？** | 判 |
|---|---|---|---|---|---|---|
| 1 | `FsQueryTrackParaList` | **550** | `PtsException(-10000)`；`[FS_PAGE_GAP] reason=drive-handles-released(page-destroyed)`（**550/550 同一 reason**） | **有**（`pfscontext` 在册／`pTrack` 由 `wpf_pts_track_owned` 认领／`cParas`；`owned=1` 现取） | **无**（`rgParaDesc[].pfsparaclient`／`nmp` 需**托管句柄表**索引，本侧无合法来源 —— 件内 `win32_pts.c` 诚实上界注释逐字；`P1-tail2-next-recon.md` §2 同判） | **不可做**（返 0 ＝ 假成功；且其 550 次拒绝是 `T-A17` 的**诚实终态**：页销毁后句柄已释放，改回"继续驱"⇒ 重引入不可捕获 `FailFast`） |
| 2 | `FsQuerySubtrackDetails` | **352** | `PtsException(-10000)`；`[FSQSTD] rc=-10000 reason=unclaimable-subtrack out=UNWRITTEN`（352/352 同一 reason；`psub=0x4`，**非本侧自有的子轨对象地址**） | **无**（`pSubTrack` 认领失败：托管侧传 `0x4`，与 `wpf_pts_sub_claim` 的"指针等值"判据不符 ⇒ 只能拒） | 有（`cParas` 取自 `[SUBENUM]` 枚举计数；`T-A12` 已落） | **不可做**（入参无源；且该入口**已有成功分支**，非"缺实现"） |
| 3 | `FsQueryTextDetails` | **1** | `ENFE`（`entry point named 'FsQueryTextDetails'`） | 有（`Pts.cs:3750` 声明；`TextParaClient.cs` 多处调用） | **无**（出参 `FSTEXTDETAILS` 是 `fsktdFull`／`fsktdCached` 判别联合，含 `dcpFirst`／`dcpLim`／`cLines`／逐行 dvr 等 —— **需文本行模型**，本侧无该源） | **可做**（仅"诚实导出"面：符号在位 ⇒ `ENFE` 归零；出参按语义**拒绝**） |
| 4 | `FsUpdateBottomlessPage` | **1** | `ENFE`（`entry point named 'FsUpdateBottomlessPage'`；`[HC-UNHANDLED] #354`） | 有（`Pts.cs:3135` 声明；`PtsPage.cs:347` 调用） | **有**（出参 `FSFMTRBL` ＝ `int` 枚举，3 值（`Pts.cs:1147-1152`）；**与已实现的同侪 `FsCreatePageBottomless` 同类型、同源**（该页对象自持的 `result`）） | **可做**（且**能落真实现**，不只诚实拒绝） |

### 1.3 选靶结论（逐字）

> **取最高计数且"入参/出参有源"者 ＝ `FsUpdateBottomlessPage`。**
> 依据三条现取：① 计数最高两席（`550`／`352`）的**出参/入参无源**（上表 `#1`／`#2`），且它们的非零 `rc` 是**已实现的诚实拒绝**（补它＝零能力前进，`T-A6` ② 已立判）；② 余下两名**并列计数 `1`**，按"**出参有源**"细分 ⇒ `FsUpdateBottomlessPage` 胜出（`FsQueryTextDetails` 出参需文本行模型 ⇒ 本侧无源）；③ 它按 `Pts.cs:3135` 声明 ＋ `PtsPage.cs:347` 调用**真会撞到**（现取 `[HC-UNHANDLED] #354`）。

---

## §2 实现（件:行 ＋ 原文；行号仅本次有效）

> 改动规模：`git diff --numstat src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`84 0`**；`tools/pts-gap-decl.txt` ＝ **`18 1`**。无"顺手优化"。

### 2.1 登记表 ＋ 计数（内容锚：`k_pts_entries[]` 尾；`FsClearUpdateInfoInPage` 之后）

- `k_pts_entries[]` 尾追加 `"FsUpdateBottomlessPage"`（该表的**唯一作用**＝让台账/报告给出**名字**，不参与"缺口数"语义 ⇒ `g_pts_calls[]` 对它恒 `0`，只有 `g_pts_seen[]` 会涨）。
- 新增两个**只读口**：`g_pts_fsp_upd_ok`（真刷新次数）／`g_pts_fsp_upd_gap`（返非 0 次数）。
- 新增**反腿开关**（默认 `0` ⇒ 主链产物零影响）：`WPF_PTS_UPDPSP_FAKE`，`1` ⇒ **假成功**（**不校验页在册**，对任意页句柄都返 0）。

### 2.2 `FsUpdateBottomlessPage`（**语义本体**）

```c
int FsUpdateBottomlessPage(void *pfscontext, void *pfspage, const void *fsnmsect, int *pfsfmtrbl)
{
    if (pfsfmtrbl) *pfsfmtrbl = WPF_PTS_FSFMTRBL_NOT_ACHIEVED;   /* 失败面先清（不留残留/毒值） */
    const char *reason = NULL;
    if (!pfsfmtrbl)                     reason = "null-result-out";
    else if (!pfspage)                  reason = "null-page";
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) reason = "unknown-ctx";
    else {
        wpf_pts_fsp *pg = NULL;
        for (int i = 0; i < g_pts_fsp_live_n; i++) {       /* **指针值比较**，不 deref 未知句柄 */
            if (g_pts_fsp_live[i]->magic != WPF_PTS_FSP_MAGIC) continue;
            if ((const void *)g_pts_fsp_live[i] == pfspage) { pg = g_pts_fsp_live[i]; break; }
        }
        if (!pg) reason = "unknown-page";
        else {
            pg->sect = fsnmsect;          /* 本页对象自持（原样存、不 deref） */
            g_pts_fsp_upd_ok++;
            { int _i = wpf_pts_index("FsUpdateBottomlessPage"); if (_i >= 0) g_pts_seen[_i]++; }
            fprintf(stderr, "[FSUPDFSP] rc=0 page=%p sect=%p result=%d upd_ok=%d upd_gap=%d seq=%d "
                            "basis=refresh-page-owned-bottomless-state "
                            "NOINFO=fsupdatebottomlesspage-scope-native-owned-state\n", …);
            g_pts_seq++;
            *pfsfmtrbl = pg->result;      /* 出参按语义：该页对象**自持**的结果（同侪同源） */
            return 0;                     /* ← 只有**页在册**才到这里 */
        }
    }
    g_pts_fsp_upd_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsUpdateBottomlessPage ctx=%p page=%p sect=%p "
                    "upd_ok=%d upd_gap=%d\n", WPF_PTS_ERR_NOT_IMPLEMENTED, reason, …);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}
```

（件内另有 `WPF_PTS_UPDPSP_FAKE==1` 的反腿分支：**不校验页在册** ⇒ 伪页句柄亦返 `0` ⇒ §7 的断言当场红。）

### 2.3 **为什么语义是"刷新本页自持状态"**（逐字引上游，防后人改读法）

- 上游声明（`Pts.cs:3135-3139`，逐字）：`FsUpdateBottomlessPage(IntPtr pfscontext, IntPtr pfspage, IntPtr fsnmsect, out FSFMTRBL pfsfmtrbl)` —— `pfspage` ＝ **要更新的页**，`fsnmsect` ＝ 起始节名，出参 ＝ **排版结果**。
- 调用点（`PtsPage.cs:326-360`，`UpdateBottomlessPage()`）：`PTS.FsUpdateBottomlessPage(PtsContext.Context, _ptsPage, _section.Handle, out formattingResult)`；失败 ⇒ `DestroyPage()` ＋ `PTS.ValidateAndTrace(fserr, …)`；随后 `formattingResult == fmtrblInterrupted` 才 `DeferFormattingToBackground()`。
- 同侪 `FsCreatePageBottomless`（本文件已实现）**同形**：`p->result = 0`（`fmtrblGoalReached`）＋ 出参回写 ⇒ 本入口照**同一体例**（出参值**取自页对象自持字段**，非全局常量）。
- ⚠️ **射程边界（如实划界）**：本入口**不调用任何驱动探针**、只刷新**本模块自持**的页对象（`sect` ＋ 复用 `result`），**不**声称"页已重排/页会可见变化" ⇒ 具名 `NOINFO-fsupdatebottomlesspage-scope-native-owned-state`（同 `FsClearUpdateInfoInPage` 的射程口径）。

---

## §3 ② `ENFE`／`[HC-UNHANDLED]` **成对**读数（同趟单变量 A/B）

**成对口径**：同装置（`:231`，`Xvfb 1280x1024x24` ＋ `xfwm4`）／同腿器（`run-pts-pages-legs.sh`，`sha16=330a90f1f0ac28e4`）／同 `pf`（`1757d610a687777c`）／同 `app` 目录（私有 `W=/home/links-dev/tA19-work/app`）／**唯一变量 ＝ 权威 `.so`**：

| 腿 | 权威 `.so`（`shim16`） | 证据目录 | `app_g1.log`（`sha16`／行） |
|---|---|---|---|
| **改前**（同趟 A/B；临时换回改前件） | `9c19dc0fef35cf4a` | `…/tA19-work/evidence-beforenow/` | `6dc88a55ea63daa6`／`7162` |
| **改后**（本轮新件） | `43ec9cd1bbd96582` | `…/tA19-work/evidence-after/` | `c69ef0acdf85cece`／`6604` |

| 面 | 改前 | 改后 | 判 |
|---|---|---|---|
| **`entry point named 'FsUpdateBottomlessPage'`**（**靶**） | **`1`** | **`0`** | ✅ **归零** |
| `entry point named 'FsQueryTextDetails'` | `1` | `53` | 变（链驱更深，暴露新前沿） |
| `ENFE` 总数（`entry point named`） | `2` | `53` | 变（**升**） |
| `[HC-UNHANDLED]` 总数 | `913` | `433` | 变（**降**） |
| — 其中有源属 `FsQueryTrackParaList` | `557` | `0` | 变（**降**） |
| — 其中有源属 `FsQuerySubtrackDetails` | `354` | `380` | 变 |
| — 其中 `ENFE` 两名 | `2` | `53` | 变 |
| `[FSUPDFSP]`（**靶真被用**） | `0` | **`55`**（**全部 `rc=0`**） | ✅ 变（真实现生效） |
| `[CLRUPD]` | `1` | `55` | 变（链驱更深） |
| `[VIS]` | `3` | `56` | 变 |
| `[QPD]` | `923` | `714` | 变 |
| `[FSQSTD]` | `711` | `921` | 变 |
| `[FSQSPL]` | `357` | `541` | 变 |
| `[FS_PAGE_GAP]` | `557` | `0` | 变 |

**靶的机读原文（改后，现取首行）**：
```
[FSUPDFSP] rc=0 page=0x556a1858ba90 sect=0x1 result=0 upd_ok=1 upd_gap=0 seq=789 basis=refresh-page-owned-bottomless-state NOINFO=fsupdatebottomlesspage-scope-native-owned-state
```
⇒ **靶 `ENFE 1 → 0`**（判据 ② 满足）；且它**真被调用 55 次、全部成功**（`upd_ok=55`、`upd_gap=0`、`[FS_PAGE_GAP] entry=FsUpdateBottomlessPage` ＝ **0**）。
⚠️ **如实划界**：`ENFE` **总数升**到 `53`（＝链**驱得更深**、暴露新前沿 `FsQueryTextDetails`）；`[HC-UNHANDLED]` **总数降** `913→433`。两者**都不是**"排版前进了"（帧面见 §6-3）。

---

## §4 ③ 导出面（现取，一次性命令原文）

```
$ nm -D --defined-only bin/libwpfwin32.so | wc -l      # ⇒ 673
$ wc -l < bin/exports.txt                              # ⇒ 673
$ diff /home/links-dev/tA19-work/bak/exports.txt.orig bin/exports.txt
109a110
> FsUpdateBottomlessPage                               # ⇒ **逐名 +1、无消失**
$ sha256sum bin/libwpfwin32.so | cut -c1-16            # ⇒ 43ec9cd1bbd96582（415928 B；%a=775）
```

---

## §5 ④ `PTSGAP` 对账 ＋ 复述位随动（**逐处 before→after**）

```
$ bash build/MilBridge/tools/pts-gap-count-check.sh | tail -2
PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTrackParaList（具名前沿成立）
PTSGAP=PASS tool=86 dead=11 artifact=1 ops=74 impl=77 so16=43ec9cd1bbd96582 exports=673 root=/home/links-dev/netTest/GitProj/WPFOnLinux
$ echo $?                                               # ⇒ 0（**零 `SITE-DRIFT`**）
$ shasum 声明行：src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt
# PTSGAP-DECL: tool=86 dead=11 artifact=1 ops=74 impl=77 so16=43ec9cd1bbd96582 exports=673 w66pre16=bf6b683d94549087
```

**计数因果（可复算）**：新增**导出**（非 `wpf_pts_gap` stub）⇒ `check-shim-coverage.py --tier all` 的 `[PresentationNative_cor3.dll]` 缺口名单**少一名** ⇒ `tool 87→86`；`dead=11`／`artifact=1` 未动 ⇒ `ops 75→74`；`stubs`（`grep -cE 'return wpf_pts_gap\("'`）＝ **3 未动** ⇒ `impl = ops + stubs = 77`；`so16`／`exports` 跟权威件换。

| # | 处（件:**内容锚**） | 前 | 后 |
|---|---|---|---|
| 1 | `docs/ROUTES.md`（`TASK-0720` 行） | `工具口径 **87**` ／ `**可操作 75**（` ／ `｜**实现口径 78**` ／ `**现算**：可操作 75 ＋` | `工具口径 **86**` ／ `**可操作 74**（` ／ `｜**实现口径 77**` ／ `**现算**：可操作 74 ＋` |
| 2 | `docs/ROUTES.md`（`TASK-0302 [MVP]` 行） | `可操作缺口 75 条／实现口径 78 条` | `可操作缺口 74 条／实现口径 77 条` |
| 3 | `docs/ROUTES.md`（`TASK-0302` 收尾行） | `**可操作 75 条／实现口径 78 条` | `**可操作 74 条／实现口径 77 条` |
| 4 | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（口径分歧行） | `工具口径 **87**` | `工具口径 **86**` |
| 5 | `README.md` | `**可操作 75／实现口径 78**` | `**可操作 74／实现口径 77**` |
| 6 | `build/MilBridge/HANDOFF-NEXT.md` | `**可操作 75／实现口径 78**` | `**可操作 74／实现口径 77**` |
| 7 | `src/WpfGfx.Linux.Native/src/win32_classification.c` | `可操作 75／实现口径 78 条` | `可操作 74／实现口径 77 条` |
| 8 | `docs/unimplemented.md` | `工具报缺 **87**` ／ `⇒ **可操作 75**` | `工具报缺 **86**` ／ `⇒ **可操作 74**` |
| 9 | `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（`# PTSGAP-DECL` 首行 ＋ 尾部 dated 重锚块） | `tool=87 … ops=75 impl=78 so16=9c19dc0fef35cf4a exports=672` | `tool=86 … ops=74 impl=77 so16=43ec9cd1bbd96582 exports=673` |

- **三条硬约束（裁定十一）逐条成立**：① **只改数字 token/就地重锚**（`git diff --numstat` 逐件 `1 1`／`3 3`／`18 1`，**无删句、无动结构**）；② **历史行一字不动**（`SITE-HISTORICAL-ONLY` 命中行**不在本次改动内**：`PTSGAP_HISTORICAL=n=5` 与改前同数；`w66pre16` 锚件 `docs/WAVE66-PREREGISTRATION.md` **未碰**，现取仍 `bf6b683d94549087`）；③ 逐件点名 ＋ 逐处 before→after 见上表。
- **第 1 行"同形位"**：`T-A4`／`T-A16` 先例在**同一行**把 `**现算**：可操作 … ＋` 一并随动 ⇒ 本趟照办（`… 75 ＋` → `… 74 ＋`）。⚠️ 该行句内 `**9** 个入口`（在册 `impl−ops` 的旧算法）**本趟之前就已与定义不符**（现算 `impl−ops = 3`）⇒ **不擅改**该历史算术句（与 `T-A4` 同形制），**具名留待队长**。
- ⚠️ **`docs/unimplemented.md` 无 `impl` 抽取式**（本牙对 `unimplemented.md` 只抽 `tool`／`ops`）⇒ 该件只在两格随动；`KNOWN-DEFECTS.md` 的 `ops`／`impl` 两字段**只剩历史行**（`SITE-HISTORICAL-ONLY`）⇒ 现值位在别件（本牙**全树逐字段**判定，故 `PTSGAP=PASS`）。

---

## §6 ⑤ 症状门**成对** ＋ 帧面（**逐字节不变**）

### 6.1 同趟 A/B（§3 的两趟）

| 字段 | 改前 `k23`／`k24` | 改后 `k23`／`k24` | 判 |
|---|---|---|---|
| `alive` | `yes`／`yes` | `yes`／`yes` | **不变** |
| `app_rc` | `143`／`143` | `143`／`143` | **不变** |
| `magenta` | `0`／`0` | `0`／`0` | **不变** |
| `colors` | `383`／`383` | `383`／`383` | **不变** |
| `ink` | `480000`／`480000` | `480000`／`480000` | **不变** |
| `ns` | `…RichTextBoxDemo`／`…FlowDocumentDemo` | 同 | **不变** |
| `ae` | `0`／`15386` | `0`／`15386` | **不变** |
| `failfast`／`unrec`（`FAILLINE`） | `0`／`0` | `0`／`0` | **不变** |
| `DEV shim` | `9c19dc0fef35cf4a` | `43ec9cd1bbd96582` | **唯一差异 ＝ 换代** |
| `LEGS_RUNNER` | `PASS requested=2 obtained=2 refused=0` | 同 | **不变** |

**`leg_<k>.env` 逐字（改后）**：
```
LEG k=23 alive=yes app_rc=143 magenta=0 colors=383 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae=0 ink=480000
LEG k=24 alive=yes app_rc=143 magenta=0 colors=383 ns=HandyControlDemo.UserControl.FlowDocumentDemo ae=15386 ink=480000
DEV x_up=yes five_stable=yes shim=43ec9cd1bbd96582 pf=1757d610a687777c
FAILLINE k=23 failfast=0 unrec=0 src=app_g1.log:FailFast|Unrecoverable
```

### 6.2 帧面（改前／改后 **逐字节相同**）

| 帧 | 改前 | 改后 |
|---|---|---|
| `boot.png` | `b21eb530afd3c66c` | `b21eb530afd3c66c` |
| `k23.png` | `ef3fd6765f18f51b` | `ef3fd6765f18f51b` |
| `k24.png` | `ef3fd6765f18f51b` | `ef3fd6765f18f51b` |
| `last.png` | `ef3fd6765f18f51b` | `ef3fd6765f18f51b` |
| `AE(k23,k24)` | `0` | `0` |
| `AE(boot,k24)` | `15386` | `15386` |

⇒ **两页仍未真排版**（帧面一格未动；`k23=k24=last` 逐字节相同、`AE=0`）。**"该靶 ENFE 归零" ≠ "可见排版前进"**。

### 6.3 两道牙 ＋ 自检面

```
$ bash build/MilBridge/tools/defect-registry-check.sh | tail -1
DEFREG=PASS declared=225 route_ids=225（…无未声明编号）          # rc=0（⚠️ DECLDRIFT=1 keys=KD，见 §8-4）
$ bash build/MilBridge/tools/report-id-domain-check.sh | tail -1
REPORTID=PASS files=309 ids=2217 declared=225 …                  # rc=0（**本载体在册后复取**；本载体落盘前一次为 files=308／ids=2216）
```

---

## §7 反极性（"该红必红" ＋ "伪值必拒"，**实跑**）

### 7.1 ctypes 夹具（接受面／拒绝面／反极性；`HARNESS …` 行；只用**已导出**入口）

夹具 `/tmp/harness19.py`（`dlopen` 仓内 `.so`，入口：`CreateDocContext`／`FsCreatePageBottomless`／`FsUpdateBottomlessPage`／`FsDestroyPage`／`DestroyDocContext`）。**单变量设计**：真页（在册）与伪页（`0xbad`）走**同一条调用** ⇒ 差异只能是"页是否在册"。

```
$ python3 harness19.py src/WpfGfx.Linux.Native/bin/libwpfwin32.so main
HARNESS main acc_page_rc 0            # 接受面：页在册
HARNESS main acc_page_out 0           # 出参 ＝ 本页自持 result(0)
HARNESS main acc_nullctx_rc 0         # 与同侪同办：ctx=NULL 但页在册 ⇒ 认领
HARNESS main rej_bad_ctx_rc -10000    # 拒绝面①：未知上下文
HARNESS main rej_bad_ctx_out 3        # 出参写"未达成"（非上游枚举值）
HARNESS main rej_null_page_rc -10000  # 拒绝面②：空页句柄
HARNESS main rej_null_page_out 3
HARNESS main rej_bad_page_rc -10000   # 拒绝面③：伪值 0xbad
HARNESS main rej_bad_page_out 3
HARNESS main rej_null_out_rc -10000   # 拒绝面④：空出参（不给"写空也算成功"）
HARNESS main after_rej_page_rc 0      # 「拒绝不改状态」：真页仍可被认领
HARNESS main VERDICT PASS
```

同趟 `stderr` 具名留痕（现取）：
```
[FSUPDFSP] rc=0 page=0x…12d0 sect=0x71 result=0 upd_ok=1 upd_gap=0 seq=2 basis=refresh-page-owned-bottomless-state …
[FS_PAGE_GAP] rc=-10000 reason=unknown-ctx  entry=FsUpdateBottomlessPage ctx=0xdead page=0x…12d0 sect=0x73 upd_ok=2 upd_gap=1
[FS_PAGE_GAP] rc=-10000 reason=null-page    entry=FsUpdateBottomlessPage ctx=0x…fac30 page=(nil) sect=0x74 upd_ok=2 upd_gap=2
[FS_PAGE_GAP] rc=-10000 reason=unknown-page entry=FsUpdateBottomlessPage ctx=0x…fac30 page=0xbad sect=0x75 upd_ok=2 upd_gap=3
[FS_PAGE_GAP] rc=-10000 reason=null-result-out entry=FsUpdateBottomlessPage ctx=0x…fac30 page=0x…12d0 sect=0x76 upd_ok=2 upd_gap=4
```

### 7.2 反腿副本（**假成功·不校验页在册**；`so16=5c97ab5464a0002d`，`FAKE-EXPORTS=673`）

| 腿 | `.so sha16` | `rej_bad_page_rc`（应当 `-10000`） | `[FSUPDFSP] basis=` | `VERDICT` |
|---|---|---|---|---|
| **正**（主链） | `43ec9cd1bbd96582` | **`-10000`** ✅ | `refresh-page-owned-bottomless-state` | **PASS** |
| **反**（假成功） | `5c97ab5464a0002d` | **`0`** ❌（**红**） | `FAKE-UNCHECKED-PAGE` | **FAIL**（期望） |

```
$ python3 harness19.py …/tA19-work/copy/libwpfwin32.fake.so fake
HARNESS fake rej_bad_page_rc 0        # ← **该红**：不校验页在册 ⇒ 伪值 0xbad 也被认领
HARNESS fake VERDICT FAIL
[FSUPDFSP] rc=0 page=0xbad sect=0x75 result=0 … basis=FAKE-UNCHECKED-PAGE …
```
⇒ **"不在册的页必被拒"这条断言真的会红**（可证伪）；接受面／其余三种拒绝面在两条腿里行为一致。

### 7.3 主链还原（逐字节）

```
$ cmp /home/links-dev/tA19-work/copy/main-new.so src/WpfGfx.Linux.Native/bin/libwpfwin32.so
RESTORED-IDENTICAL（restored_shim16=43ec9cd1bbd96582 perms=775）
```

---

## §8 边界 · 纪律 · 主动披露 ／ 具名 `NOINFO`

1. **写域**：仅 `win32_pts.c`（手写源）＋ `tools/pts-gap-decl.txt`（声明行 ＋ dated 注释）＋ `bin/*`（重建刷新，gitignored）＋ 复述位六件（**只改数字 token**）＋ 本载体。**未碰** `verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`build/*.Linux/**`／`docs/**`（除白名单两件）／任何 `.cs`。
2. **同趟 A/B 的`.so` 换件**：§3 的"改前腿"把权威 `.so` **临时**换成**改前件**（`cp -p` 自备份），跑完**逐字节还原**为 `43ec9cd1bbd96582`（`cmp` `RESTORED-IDENTICAL`，`%a=775`）。这一步只在**唯一写者**窗口内做，且**无其它链在跑**（`git status` 现取除本席件外只有两项 pre-existing untracked）。`exports.txt` **未**随之换（仅 `.so`），故"改前腿"仍报 `[FSUPDFSP]=0` 与 `ENFE=2` ⇒ 两趟确为单变量。
3. **模式守恒**：逐件 `%a` 见 §9（**逐件 644／`so` 775**）；写盘一律 `temp+rename`（复述位与 `pts-gap-decl.txt` 经 `python3 os.replace`，落盘后**逐件 `chmod` 回原值**并复核）；备份取在**任何写之前**（`/home/links-dev/tA19-work/bak/**`，逐件 `sha16` 与覆盖前现取相等）。
4. **`DEFREG_DECLDRIFT=1 keys=KD`（如实记，待主控）**：本件改了 `KD`（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的口径分歧行 token）⇒ 已声明表 `build/MilBridge/tools/defect-registry-declared.tsv` 的**路由快照与该件不再一致**。该件**不在本件写域**（`build/MilBridge/tools/**` 黑名单）⇒ 照纪律 15／`D-G129`：**请主控重发 `declared.tsv`**。牙本身 `DEFREG=PASS rc=0`。
5. **`bin/exports.txt` 与 `bin/libwpfwin32.so` 是 gitignored 件**（`.gitignore:24`）：派单把它们列入写域，本趟确已刷新（`+1` 行／重建），但**它们不入 git** ⇒ 交接必须靠**重建**（或另备缓存）。如实记，非疏漏。
6. **`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的"口径分歧行"**（`dated` 但**无内容锚**）**照 `T-A13`／`T-A5`／`T-A16` 先例**把 token 同步为 live（`工具口径 **87**` → `**86**`）以使 `PTSGAP=PASS`，**并在此具名重提**：**该行语义上是历史陈述，随动会改史实** —— 请队长裁定"**保值**（加内容锚使其转历史行）vs **随动**（现状）"。
7. **具名 `NOINFO`**：
   - `NOINFO-FSUPDATEBOTTOMLESSPAGE-SCOPE-NATIVE-OWNED-STATE`（**射程边界**）：本入口刷新的是**本模块自持**的页对象（`sect` ＋ 复用 `result`），**不是**托管/LineServices 的完整排版结果 —— 本侧**没有**那个源 ⇒ 它**不**声称"页内容已重排"、**不**声称"页会可见变化"（可见面由 §6 腿读数给：**页仍未绘出内容**）。
   - `NOINFO-FSQUERYTEXTDETAILS-OUT-PARAM-SOURCE`（**下一前沿的出参无源**）：新前沿 `FsQueryTextDetails` 的出参 `FSTEXTDETAILS` 需**文本行模型**（`dcpFirst`／`dcpLim`／`cLines`／逐行 dvr）⇒ 本侧**无源** ⇒ 下一增量若选它，只能落**诚实拒绝**形态。**本件未做**。
   - `NOINFO-DRIVE-PROBE-STATE`：两趟腿均在 `WPF_PTS_DRIVE_PROBE` **缺省开**下取 ⇒ 帧面读数**带探针闸状态**（裁定三十六 (c)）；**未**另跑"闸关"腿。
8. **未做**：`git add/commit/push`；未跑整趟 `verify-all`／`static-jaws-check.sh`；未动任何牙本体；未判相位（本件不涉相位）。
9. **帧面冻结令（旁引裁定三十九／四十二）**：本件**不**据任一帧面读数**单向**下判（两趟帧面**完全相同**，只报"逐字节相同"这一结果）。

---

## §9 件级前后对账（现取 `sha16` 前 16 位 ＋ `%a`）

| 件 | 开工（`cp -p` 备份） | 收尾（现取） | `%a` | 判 |
|---|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `1121f032913c1582` | **`9b1d30e87ba34c5a`**（5177 行） | 644 | `git diff --numstat = 84 0` |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `0a35461707068aac` | **`562dd1833c8a9cd0`** | 644 | `18 1`（声明行 1 ＋ dated 重锚注释 17） |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `9e416ff90c402671`（672 行） | **`732b701c2a521220`**（673 行） | 644 | 重建刷新（gitignored） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `9c19dc0fef35cf4a`（415752 B） | **`43ec9cd1bbd96582`**（415928 B） | 775 | 重建产物（gitignored）；A/B 后**逐字节还原** |
| `docs/ROUTES.md` | `58ed4968fdc03d2e` | **`61b03dbc1123b2f7`** | 644 | `3/3` token |
| `README.md` | `ef122709fea5d655` | **`d00569e2dca33c76`** | 644 | `1/1` |
| `build/MilBridge/HANDOFF-NEXT.md` | `41d57db4d59b6759` | **`07051f66d22c46fe`** | 644 | `1/1` |
| `src/WpfGfx.Linux.Native/src/win32_classification.c` | `c1b084a322ad0f79` | **`ab5950274d148905`** | 644 | `1/1`（**注释**；重建后 `.so` `sha16` **逐字节不变** ⇒ 已验证） |
| `docs/unimplemented.md` | `0517c02282d5bf69` | **`287701f92f4a7d5b`** | 644 | `1/1` |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `e58a6b8813f441d9` | **`d499b35635ee363a`** | 644 | `1/1` |
| 反腿副本（**仓外**）`…/tA19-work/copy/libwpfwin32.fake.so` | — | `5c97ab5464a0002d` | — | `-DWPF_PTS_UPDPSP_FAKE=1`，**绝不进主链** |

**备份路径**：`/home/links-dev/tA19-work/bak/{win32_pts.c,pts-gap-decl.txt,exports.txt,libwpfwin32.so}.orig` ＋ `bak/recast/*`（复述位六件）＋ `copy/main-new.so`（A/B 期间的新件备份）。

**`git status --porcelain`（现取；含本载体）**：
```
 M README.md
 M build/MilBridge/HANDOFF-NEXT.md
 M docs/ROUTES.md
 M docs/unimplemented.md
 M samples/WpfFeatureProbe/KNOWN-DEFECTS.md
 M src/WpfGfx.Linux.Native/src/win32_classification.c
 M src/WpfGfx.Linux.Native/src/win32_pts.c
 M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt
?? build/MilBridge/P1-tail2-next2-impl-report.md             ← **本载体**
?? build/MilBridge/tasks-tail2/T-A19.md                        ← 派单件（非本席所改）
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log  ← **先于本件存在**（非本席所改）
```
⚠️ `src/WpfGfx.Linux.Native/bin/**` **不入 `git status`** —— 该目录在 `.gitignore:24`（`git check-ignore` 现取命中）⇒ `exports.txt`／`.so` 只存在于工作树。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-next2-impl-report.md | sha256sum | cut -c1-16`）= `ddc1e335be747a68`
