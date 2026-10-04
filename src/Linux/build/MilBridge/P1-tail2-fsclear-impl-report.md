# P1-tail2 · `T-A16` · 新增导出 `FsClearUpdateInfoInPage`（诚实形态）＋ 复述位随动 —— native 主链实现（`TASK-0302` 增量）

> **本件 `T-A16`（writer；本轮唯一写者）交付**。写域：`src/WpfGfx.Linux.Native/src/win32_pts.c`（手写源）＋ 其**登记面**（`tools/pts-gap-decl.txt` 声明行 ＋ dated 重锚注释；`bin/exports.txt`／`bin/libwpfwin32.so` 由重建刷新）＋ **复述位现值位**（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`）＋ 本载体。
> **未碰**：`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（牙本体）／`build/*.Linux/**`（生成件）／任何 `.cs`；`git add/commit/push` **未做**。
> **上游契约**：声明 `Pts.cs:3142-3144`；调用点 `PtsPage.cs:593-600`（`ClearUpdateInfo()`）／`FlowDocumentPage.cs:250,871,886`。
> **行号纪律**：本件所有行号**仅本次有效**；引件一律给内容锚。
> **重活**：构建 ＋ 跑腿**全部**走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- …`；进程只按 PID；显示位只用空闲 `:231`；**未跑**整趟 `verify-all`；写前 `cp -p` 备份；模式守恒（`%a` 逐件见 §4）。

---

## §0 结论速览（自包含）

1. **做了什么**：native 新增**导出** `FsClearUpdateInfoInPage`（`Pts.cs:3142`；本轮之前**本侧未导出**）。
   - **导出符号 ⇒ `ENFE` 归零**：`EntryPointNotFoundException … 'FsClearUpdateInfoInPage'` 现取 **`532 → 0`**（§2 ①）。
   - **入参按对象身份认领**：`pfspage` 必须**在册**（`g_pts_fsp_live[]`，**指针值比较、不 deref**）；`pfscontext` 非空时必须**在册**（与 `FsQueryPageDetails`／`FsDestroyPage` **同办**；`ctx=NULL` 但页在册 ⇒ **认领**）。
   - **无出参** ⇒ "出参不伪造"**平凡成立**（声明只有两个 `IN` 参数）。
   - **永不假成功**：只有**真清掉**该页**本模块自持的增量更新状态**（`qpd_vis_built`／`qpd_new_pending`／`qpd_fstd_since` 归 0 ＋ 断开"查询组"毗邻位）才返 `0`；`NULL`／未知上下文／不在册的页 ⇒ 返 `-10000` ＋ 具名 `[FS_PAGE_GAP]` 留痕，且**一个字节也不改**。
   - **同趟机读留痕**：成功 `[CLRUPD]`（**清前的值先取**，逐趟可对拍）；失败 `[FS_PAGE_GAP] entry=FsClearUpdateInfoInPage`。
2. **验收（逐条见 §2／§3）**：
   - ① 该名 `ENFE 532 → 0`；导出面 `nm -D --defined-only` **672** == `bin/exports.txt` **672**（vs 改前 **逐名 +1、无消失**）。✅
   - ② 行为：**接受面**（`[CLRUPD] rc=0`）／**拒绝面**（三种伪值/空值 ⇒ 各 `-10000` ＋ 留痕）／**反极性**（假成功副本 ⇒ 断言必红）。✅
   - ③ **`PTSGAP=PASS`**（`rc=0`、**零 `SITE-DRIFT`**；`tool 88→87`／`ops 76→75`／`impl 79→78`／`exports 671→672`／`so16 3cb3ad48ef27d13d→63f0eb7c4d2fc8cd`）。✅
   - ④ 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）与改前**成对**读数 —— ⚠️ **本件使症状门变化（回归）**：两腿 `app_rc 143 → 134`（**不可捕获 `FailFast`**）。**归因已定钉**（§2 ④ 四条件表）：**不是本席语义所致** —— ⓐ 假成功副本（返 0 但**不清**）⇒ **同样崩**；ⓑ 本件＋`WPF_PTS_DRIVE_PROBE=0` ⇒ **逐字段回到改前**。真因 ＝ **本仓驱动探针的"窗外腿"在 `FsDestroyPage` 用了一个已被释放的 `nms` 句柄**（§6-3）。⇒ **如实记，不读成"修好了"**。
   - ⑤ `DEFREG` **rc=0**；`REPORTID` **rc=0**。✅（⚠️ `DEFREG_DECLDRIFT=1 keys=KD` —— 见 §6-5）
3. **下一站（具名，防被读成"没做完"）**：本增量把"缺符号"变成"有符号"，页**仍未绘出内容**；新暴露的 ENFE 两名 ＝ **`FsUpdateBottomlessPage`**／**`FsQueryTextDetails`**；**唯一阻塞项** ＝ §6-3 的探针陈旧句柄 `FailFast`（**先于**上面两名发生）。
4. **口径重申**：**"计数下降 ≠ 能力前进"**（缺口计数 `impl 79→78` 只是"缺符号"变"有符号"）；**"新异常类别 ≠ 本件造错"**（同 `T-A15` §6-3）。

---

## §1 实现（件:行 ＋ 原文；行号仅本次有效）

> 改动规模：`git diff --numstat src/WpfGfx.Linux.Native/src/win32_pts.c` = **`92 0`**；`tools/pts-gap-decl.txt` = **`17 1`**。无"顺手优化"。

### 1.1 登记表 ＋ 计数（内容锚：`k_pts_entries[]` 尾；`g_pts_fsp_vis_ok` 之下的新增块）

- `k_pts_entries[]` 尾追加 `"FsClearUpdateInfoInPage"`（该表的**唯一作用**＝让台账/报告给出**名字**，不参与"缺口数"语义）。
- 新增两个**只读口**（**不新增导出** —— 缺省路径下计数只在 `[CLRUPD]`／`[FS_PAGE_GAP]` 行上现算）：
  `g_pts_fsp_clr_ok`（真清次数）／`g_pts_fsp_clr_gap`（返非 0 次数）。
- 新增**反腿开关**（默认 `0` ⇒ 主链产物零影响）：`WPF_PTS_CLRUPD_FAKE`，`1` ⇒ **假成功**（返 0、**一个字节都不清**）。

### 1.2 `FsClearUpdateInfoInPage`（**语义本体**）

```c
int FsClearUpdateInfoInPage(void *pfscontext, void *pfspage)
{
    const char *reason = NULL;
    if (!pfspage)                    reason = "null-page";
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) reason = "unknown-ctx";
    else {
        wpf_pts_fsp *pg = NULL;
        for (int i = 0; i < g_pts_fsp_live_n; i++) {      /* **指针值比较**，不 deref 未知句柄 */
            if (g_pts_fsp_live[i]->magic != WPF_PTS_FSP_MAGIC) continue;
            if ((void *)g_pts_fsp_live[i] == pfspage) { pg = g_pts_fsp_live[i]; break; }
        }
        if (!pg) reason = "unknown-page";
        else {
            const int vis_before  = pg->qpd_vis_built;
            const int pend_before = pg->qpd_new_pending;
            const int fstd_before = pg->qpd_fstd_since;
            const int grp_before  = ((const void *)g_pts_qpd_prev_page == (const void *)pfspage) ? 1 : 0;
            pg->qpd_vis_built = 0; pg->qpd_new_pending = 0; pg->qpd_fstd_since = 0;
            g_pts_qpd_prev_page = NULL;                  /* 断开"查询组"毗邻位 ⇒ 下一次查询给 New */
            g_pts_fsp_clr_ok++;
            { int _i = wpf_pts_index("FsClearUpdateInfoInPage"); if (_i >= 0) g_pts_seen[_i]++; }
            fprintf(stderr, "[CLRUPD] rc=0 page=%p vis_built_before=%d new_pending_before=%d "
                            "fstd_since_before=%d group_adjacent_before=%d page_qpd=%d "
                            "clr_ok=%d clr_gap=%d seq=%d basis=%s "
                            "NOINFO=fsclearupdateinfo-scope-native-owned-state\n", …);
            return 0;                                     /* ← 只有**真清掉**才到这里 */
        }
    }
    g_pts_fsp_clr_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsClearUpdateInfoInPage ctx=%p page=%p "
                    "clr_ok=%d clr_gap=%d\n", WPF_PTS_ERR_NOT_IMPLEMENTED, reason, …);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}
```

### 1.3 **为什么语义是"清 ⇒ 下一次 = 全量（`fskupdNew`）"**（逐字引上游，防后人改读法）

- `PtsPage.cs:593-600`（`ClearUpdateInfo()`，**唯一调用封套**）注释逐字：**"Clear any incremental update state accumulated during update process."**
- `FlowDocumentPage.cs:240-253`（`ForceReformat()`）**给出因果**，逐字：
  > *"Page update may be requested more than once before rendering is done. But PTS is not able to merge update info. To protect against loosing incremental changes delta, need to force full formatting for the conent."*（原文拼写 `conent`）＋ `:250` 就调 `_ptsPage.ClearUpdateInfo()`。
- 消费者两处（`PtsPage.cs:999`／`PtsHelper.cs:210`）**一律** `fskupdNoChange ⇒ 提前返回（视觉仍有效）`；建视觉只在 `== fskupdNew`（`PtsPage.cs:1029`）。
  ⇒ **"清增量"若不让下一次回到 `New`，本入口就是"什么都没做的假成功"**（裁定二十三「不许静默 stub」／`t127`「字段级诚实性」两条都在禁的形态）。

### 1.4 `FSCONTEXTINFO` 无关面（如实划界）

本入口**不** deref `pfscontext`／`pfspage`（只做指针值比较）⇒ 与 `CreateDocContext` 的 `FSCBK` 快照面无交互。

---

## §2 验收标准 ①–⑤ → 证据映射（可复跑命令原文 ＋ 原始输出）

> 证据落**仓外私有目录** `/home/links-dev/tA16-work/`；腿器＝仓内 `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh`（A 臂，`k=24`／`k=23`）；装置 `:231`；`LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`（四趟全）。

### ①② 构建（走槽）＋ 导出面

```
$ bash /home/links-dev/tA16-work/build.sh
== 链接 -shared -Wl,--no-undefined
== 产物：bin/libwpfwin32.so（415752 字节）
== 导出符号总数：672
$ nm -D --defined-only bin/libwpfwin32.so | wc -l      # ⇒ 672
$ wc -l < bin/exports.txt                              # ⇒ 672
$ diff /home/links-dev/tA16-work/bak/exports.txt.orig bin/exports.txt
100a101
> FsClearUpdateInfoInPage                               # ⇒ **逐名 +1、无消失**
$ sha256sum bin/libwpfwin32.so | cut -c1-16            # ⇒ 63f0eb7c4d2fc8cd（415752 B；%a=775）
```

### ① `FsClearUpdateInfoInPage` 的 `ENFE` 归零（腿日志计数）

```
$ f=/home/links-dev/tA16-work/evidence-main/app_g1.log
$ grep -c "entry point named 'FsClearUpdateInfoInPage'" $f     # ⇒ 0     （改前：T-A15 在册 532）
$ grep -c 'EntryPointNotFoundException' $f                    # ⇒ 2
$ grep -o "entry point named '[A-Za-z0-9_]*'" $f | sort | uniq -c
      1 entry point named 'FsUpdateBottomlessPage'            # ← **新前沿①**（本增量后才到达）
      1 entry point named 'FsQueryTextDetails'                # ← **新前沿②**
$ grep -c 'ArgumentOutOfRangeException: index' $f              # ⇒ 0     （T-A15 已归零，保持）
```

### ② 行为 —— **真跑出来的** `[CLRUPD]` 原文（真应用腿，非夹具）

```
$ grep -m1 '^\[CLRUPD\]' $f
[CLRUPD] rc=0 page=0x5975fc397c20 vis_built_before=1 new_pending_before=0 fstd_since_before=0 group_adjacent_before=1 page_qpd=6 clr_ok=1 clr_gap=0 seq=810 basis=reset-page-owned-incremental-state NOINFO=fsclearupdateinfo-scope-native-owned-state
$ grep -c '^\[CLRUPD\]' $f                                     # ⇒ 1（真应用只走到一次 ClearUpdateInfo）
$ grep -c '^\[FS_PAGE_GAP\]' $f                               # ⇒ 0（真应用**无**拒绝）
```
⇒ `vis_built_before=1`（**清之前确有增量状态**）⇒ 这次调用**真的清掉了东西**（不是空转）。

### ② 行为 —— ctypes 夹具（**接受面／拒绝面／反极性**；`HARNESS …` 行）

夹具 `/home/links-dev/tA16-work/harness.py`：`dlopen` 仓内 `.so`，只用**已导出**入口
（`CreateDocContext`／`FsCreatePageBottomless`／`FsQueryPageDetails`／`FsClearUpdateInfoInPage`／`FsDestroyPage`／`DestroyDocContext`）。
**单变量设计**：控制臂（**不调** clear）与实验臂（**中间插一次** clear）走**同一个页对象**、同样三次查询 ⇒ 差异只能是"clear 这一次调用"。

```
$ bash /home/links-dev/tA16-work/run-harness.sh      # .so = 主链 63f0eb7c4d2fc8cd
HARNESS main create_ctx_rc 0
HARNESS main create_page_rc 0
HARNESS main ctrl_fskupd 2,1,1        # 控制臂：首查 New(2)，其后 NoChange(1)、NoChange(1)（**不调 clear** ⇒ 一直 NoChange）
HARNESS main exp_pre_fskupd 1         # 实验臂：clear 前一查 = NoChange(1)
HARNESS main exp_clear_rc 0           # **接受面**：页在册、ctx 在册 ⇒ 0
HARNESS main exp_post_fskupd 2        # **清之后 ⇒ 回到 New(2)**（＝全量重排被重新武装）
HARNESS main rej_bad_ctx_rc -10000    # **拒绝面①**（未知上下文）
HARNESS main rej_null_page_rc -10000  # **拒绝面②**（空页句柄）
HARNESS main rej_bad_page_rc -10000   # **拒绝面③**（伪值 0xbad）
HARNESS main post_rej_fskupd 1        # **拒绝不改状态**（与上一条查询相邻 ⇒ 仍是 NoChange）
HARNESS main null_ctx_rc 0            # **与同侪同办**：ctx=NULL 但页在册 ⇒ 认领（不是拒绝面）
HARNESS main post_nullctx_fskupd 2
HARNESS main destroy_page_rc 0
HARNESS main destroy_ctx_rc 0
HARNESS main VERDICT PASS
```
失败的**具名留痕**（同趟 stderr）：
```
[FS_PAGE_GAP] rc=-10000 reason=unknown-ctx  entry=FsClearUpdateInfoInPage ctx=0xdead page=0x… clr_ok=1 clr_gap=1
[FS_PAGE_GAP] rc=-10000 reason=null-page    entry=FsClearUpdateInfoInPage ctx=0x… page=(nil) clr_ok=1 clr_gap=2
[FS_PAGE_GAP] rc=-10000 reason=unknown-page entry=FsClearUpdateInfoInPage ctx=0x… page=0xbad clr_ok=1 clr_gap=3
```

### ③ `PTSGAP` 对账 ＋ 复述位随动（**逐处 before→after**）

```
$ bash build/MilBridge/tools/pts-gap-count-check.sh | tail -3
LIVE  tool=87 dead=11 artifact=1 ops=75 impl=78 so16=63f0eb7c4d2fc8cd exports=672 root=/home/links-dev/netTest/GitProj/WPFOnLinux
PTSGAP=PASS tool=87 dead=11 artifact=1 ops=75 impl=78 so16=63f0eb7c4d2fc8cd exports=672 root=/home/links-dev/netTest/GitProj/WPFOnLinux
$ echo $?                                               # ⇒ 0（**零 `SITE-DRIFT`**；`SITE-HISTORICAL-ONLY` 两行＝告示、非红）
```

| # | 处（件:`行`，**仅本次有效**） | 前 | 后 |
|---|---|---|---|
| 1 | `docs/ROUTES.md:261` | `可操作缺口 76 条／实现口径 79 条` | `可操作缺口 75 条／实现口径 78 条` |
| 2 | `docs/ROUTES.md:373` | `工具口径 **88**` ／ `**可操作 76**（` ／ `｜**实现口径 79**（**现算**：可操作 76 ＋` | `工具口径 **87**` ／ `**可操作 75**（` ／ `｜**实现口径 78**（**现算**：可操作 75 ＋` |
| 3 | `docs/ROUTES.md:520` | `可操作 76 条／实现口径 79 条` | `可操作 75 条／实现口径 78 条` |
| 4 | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2258` | `工具口径 **88**` | `工具口径 **87**` |
| 5 | `README.md:23` | `可操作 76／实现口径 79` | `可操作 75／实现口径 78` |
| 6 | `build/MilBridge/HANDOFF-NEXT.md:47` | `可操作 76／实现口径 79` | `可操作 75／实现口径 78` |
| 7 | `src/WpfGfx.Linux.Native/src/win32_classification.c:52` | `可操作 76／实现口径 79 条` | `可操作 75／实现口径 78 条` |
| 8 | `docs/unimplemented.md:555` | `工具报缺 **88**` ／ `⇒ **可操作 76**` | `工具报缺 **87**` ／ `⇒ **可操作 75**` |

- 三条硬约束（裁定十一）**逐条成立**：① **只改数字 token**（`git diff --numstat` 逐件 `1 1`／`3 3`，**无删句、无动结构**）；② **历史行一字不动**（`SITE-HISTORICAL-ONLY` 命中行**不在本次改动内**；`w66pre16` 锚件 `docs/WAVE66-PREREGISTRATION.md` **未碰**，现取仍 `bf6b683d94549087`）；③ 逐件点名 ＋ 逐处 before→after 见上表。
- **第 2 行"同形位"**：`T-A4` 先例（`0aab811`）在**同一行**把 `**现算**：可操作 78 ＋` 与 `｜**实现口径 80**` **一并**随动 ⇒ 本趟照办（`… 76 ＋` → `… 75 ＋`）。
- ⚠️ **`docs/unimplemented.md:555` 无 `impl` 抽取式**（本牙对 `unimplemented.md` 只抽 `tool`／`ops`）⇒ 该件只在两格随动。
- ⚠️ **`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `ops`／`impl` 两字段只剩历史行**（`SITE-HISTORICAL-ONLY`）⇒ 现值位在别件（本牙**全树逐字段**判定，故 `PTSGAP=PASS`）。

### ④ 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）**成对**读数 ＋ **四条件**归因

**成对口径**：同装置（`:231`）／同腿器／同 `pf`（`1757d610a687777c`）／同两条腿（`k=24`／`k=23`）。

| 条件 | 主链 `.so` | `k=24` | `k=23` | 判 |
|---|---|---|---|---|
| **改前**（`T-A15` 在册；探针缺省开） | `3cb3ad48ef27d13d` | `alive=yes app_rc=143 magenta=0 colors=383 ink=480000 ns=…FlowDocumentDemo ae=15386 fr=ef3fd6765f18f51b` | `alive=yes app_rc=143 magenta=0 colors=383 ink=480000 ns=…RichTextBoxDemo ae=0 fr=ef3fd6765f18f51b` | 基线 |
| **本件**（导出 ＋ **真清**；探针开） | `63f0eb7c4d2fc8cd` | `alive=yes app_rc=134 colors=391 ink=480000 ae=14775 fr=b273ebecc332fc03` | `alive=no app_rc=134 colors=1 ink=0 ae=480000 failfast=4 unrec=2 fr=2a60a00fc582e97d` | ⚠️ **回归** |
| 控制①（导出在位但 **假成功·不清**；探针开） | `cf4613dad2fc015f` | `alive=yes app_rc=134 colors=383 ink=480000 ae=15386 fr=ef3fd6765f18f51b` | `alive=no app_rc=134 colors=1 ink=0 failfast=4` | ⚠️ **同样崩** ⇒ **不是本席"清"的语义所致** |
| 控制②（**本件** ＋ `WPF_PTS_DRIVE_PROBE=0`） | `63f0eb7c4d2fc8cd` | `alive=yes app_rc=143 magenta=0 colors=383 ink=480000 ae=15386 fr=ef3fd6765f18f51b` | `alive=yes app_rc=143 magenta=0 colors=383 ink=480000 ae=0 fr=ef3fd6765f18f51b` | ✅ **逐字段回到改前** |

⇒ **归因（可复算）**：崩**需要两个条件同时成立** ——「该符号在位且返 0」（控制①）∧「驱动探针开」（控制②）。**本席的状态复位只在"探针开"时才影响帧**（`colors 383→391`）⇒ 它不是崩溃的成因。

**崩点原文（`evidence-main/app_g1.log:5017-5032`；控制① `evidence-fake/app_g1.log:5555-5570` 同形）**：
```
[CLRUPD] rc=0 page=0x5975fc397c20 vis_built_before=1 … basis=reset-page-owned-incremental-state …
[HC-UNHANDLED] #391 EntryPointNotFoundException: … 'FsUpdateBottomlessPage' …
Unrecoverable system error.: Handle has been already released.
Process terminated.
   at MS.Internal.Invariant.FailFast(System.String, System.String)
   at MS.Internal.PtsHost.PtsHost.GetFirstPara(IntPtr, IntPtr, Int32 ByRef, IntPtr ByRef)
   at MS.Internal.PtsHost.PtsCache+<>c__DisplayClass16_0.<InitGenericInfo>b__0(IntPtr, IntPtr, Int32 ByRef, IntPtr ByRef)
   at MS.Internal.PtsHost.UnsafeNativeMethods.PTS.FsDestroyPage(IntPtr, IntPtr)
   at MS.Internal.PtsHost.PtsContext.OnDestroyPage(IntPtr, Boolean)
   at MS.Internal.PtsHost.PtsPage.DestroyPage()
   at MS.Internal.PtsHost.PtsPage.OnBeforeFormatPage(Boolean, Boolean)
   at MS.Internal.PtsHost.PtsPage.CreateBottomlessPage()
   at MS.Internal.PtsHost.FlowDocumentPage.FormatBottomless(…)
   …
```
- `GetFirstPara` 的断言出处现取：`PtsContext.cs:211`／`:248` `Invariant.Assert(_unmanagedHandles[handleLong].IsHandle(), "Handle has been already released.")`（`HandleToObject` 路径）。
- **`PTS.FsDestroyPage` 是本侧 native** ⇒ 栈里它之所以**回调进托管**，只因本仓 `FsDestroyPage` 首句 `wpf_pts_drive_probe2_oow(pfscontext, "FsDestroyPage")`（**缺省开**）用**缓存的 `dp->drive_nmseg`** 调 `+136 pfnGetFirstPara` ⇒ **该句柄此刻已被托管侧释放** ⇒ **不可捕获 `FailFast`**。详见 §6-3。

**其余诊断面（本件腿）**：`[QPD]` 直方图 `388×fskupd=1 adj=0`／`6×fskupd=1 adj=1`／`2×fskupd=2 adj=0`／`3×fskupd=2 first=1`（`fskupd=0` **0 次**）；`[VIS]=2`；`[FSQSTD]=781`／`[FSQSPL]=392`／`[FSPARALIST-FILL]=392`；`[HC-UNHANDLED]=391`；`PtsException=389`。

### ⑤ 两道牙 ＋ 自检面

```
$ bash build/MilBridge/tools/defect-registry-check.sh | tail -1
DEFREG=PASS declared=225 route_ids=225（…无未声明编号）          # rc=0
$ bash build/MilBridge/tools/report-id-domain-check.sh | tail -1
REPORTID=PASS files=306 ids=2215 declared=225 glob=build/MilBridge/*report*.md   # rc=0
$ python3 /home/links-dev/tA16-work/selfcheck.py            # dlopen 仓内 .so，调自检面（只读盘）
PtsGapSelfCheck     = 1        # 1 = 全过
PtsGapSelfCheckDiag = 0        # 0 = 无红格
PtsGapSelfCheck(2nd)= 1        # 幂等（自检不扰动可观测状态）
```

---

## §3 反极性（"该红必红"，**实跑**）

**载体**：副本 `.so`（`/home/links-dev/tA16-work/copy/libwpfwin32.fake.so`，`so16=cf4613dad2fc015f`；**只在副本**以 `-DWPF_PTS_CLRUPD_FAKE=1` 单独编译；`FAKE-EXPORTS=672`）。

| 腿 | `.so sha16` | `exp_clear_rc` | `exp_post_fskupd`（应当 = 2） | `[CLRUPD] basis=` | `VERDICT` |
|---|---|---|---|---|---|
| **正**（主链） | `63f0eb7c4d2fc8cd` | `0` | **`2`** ✅ | `reset-page-owned-incremental-state` | **PASS** |
| **反**（假成功·不清） | `cf4613dad2fc015f` | `0` | **`1`** ❌（**红**） | `FAKE-NO-CLEAR` | **FAIL**（期望） |

```
$ bash /home/links-dev/tA16-work/run-harness.sh /home/links-dev/tA16-work/copy/libwpfwin32.fake.so fake
HARNESS fake exp_pre_fskupd 1
HARNESS fake exp_clear_rc 0
HARNESS fake exp_post_fskupd 1        # ← **该红**：假成功不清 ⇒ 下一次仍是 NoChange
HARNESS fake rej_bad_ctx_rc -10000    # 拒绝面**不受**假腿影响（假腿只改成功支）
HARNESS fake rej_null_page_rc -10000
HARNESS fake rej_bad_page_rc -10000
HARNESS fake post_rej_fskupd 1
HARNESS fake VERDICT FAIL
[CLRUPD] rc=0 page=0x… vis_built_before=0 … basis=FAKE-NO-CLEAR NOINFO=…
```
⇒ **"永不假成功"这条断言真的会红**（可证伪）；拒绝面（伪值必拒）在三腿里**行为一致**。
⇒ 腿级反极性（`WPF_PTS_CLRUPD_FAKE=1` 换主链 `.so` 跑真应用）见 §2 ④ **控制①**（`app_rc=134`，且 `k=24` 帧 `== 基线` ⇒ 与"真清"腿**可区分**）。

**主链还原（逐字节）**：
```
REV-SWAP main_bak16=63f0eb7c4d2fc8cd -> fake16=cf4613dad2fc015f tag=fake
RESTORED so16=63f0eb7c4d2fc8cd（对照备份 63f0eb7c4d2fc8cd）
```

---

## §4 件级前后对账

| 件 | 开工（`cp -p` 备份）`sha16` | 收尾（现取）`sha16` | `%a` | 判 |
|---|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `a4072fdb0642ed01`（4943 行） | **`435f74395c5bc6a5`** | 644 | `git diff --numstat = 92 0` |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `b5b31212d395761c` | **`c5c4d1297c72f2a6`** | 644 | `git diff --numstat = 17 1`（声明行 1 ＋ dated 重锚注释 16） |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `1113e6b1d9854f78`（671 行） | **`9e416ff90c402671`**（672 行） | 644 | 重建刷新（`.gitignore:24` ⇒ **不入 git**，见 §6-6） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `3cb3ad48ef27d13d`（415616 B） | **`63f0eb7c4d2fc8cd`**（415752 B） | 775 | 重建产物（gitignored）；反腿后**逐字节还原**（回读 == 备份） |
| `docs/ROUTES.md` | `768404a817fefad6` | **`bed522748eb3cec9`** | 644 | `1/1`×3 处 token |
| `README.md` | `b3b6029c2cba9d28` | **`ef122709fea5d655`** | 644 | `1/1` |
| `build/MilBridge/HANDOFF-NEXT.md` | `a55994fb722d4bf9` | **`a213a3a6e65e23e7`** | 644 | `1/1` |
| `src/WpfGfx.Linux.Native/src/win32_classification.c` | `c945c052c54adcc9` | **`c1b084a322ad0f79`** | 644 | `1/1`（**注释**；重建后 `.so` `sha16` **逐字节不变** ⇒ 已验证） |
| `docs/unimplemented.md` | `2e21edaa30b3cbe5` | **`0517c02282d5bf69`** | 644 | `1/1` |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `3a0f800b0f2bc083` | **`e58a6b8813f441d9`** | 644 | `1/1` |

**备份路径**：`/home/links-dev/tA16-work/bak/{win32_pts.c,pts-gap-decl.txt,exports.txt,libwpfwin32.so}.orig` ＋ `bak/recast/*`（复述位六件）＋ `copy/main-backup.so`（反腿期间的主链件备份）。

**`git status --porcelain`（现取）**：
```
 M README.md
 M build/MilBridge/HANDOFF-NEXT.md
 M docs/ROUTES.md
 M docs/unimplemented.md
 M samples/WpfFeatureProbe/KNOWN-DEFECTS.md
 M src/WpfGfx.Linux.Native/src/win32_classification.c
 M src/WpfGfx.Linux.Native/src/win32_pts.c
 M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt
?? build/MilBridge/tasks-tail2/T-A16.md                                 ← 派单件（非本席所改）
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log        ← **先于本件存在**（非本席所改）
```
⚠️ `src/WpfGfx.Linux.Native/bin/**` **不入 `git status`** —— 该目录在 `.gitignore:24`（`git check-ignore` 现取命中）⇒ `exports.txt`／`.so` 只存在于工作树。

---

## §5 边界 · 纪律 · 口径

- **写域**：仅 `win32_pts.c`（手写源）＋ `tools/pts-gap-decl.txt`（声明行 ＋ dated 注释）＋ `bin/*`（重建刷新）＋ 复述位六件（**只改数字 token**）＋ 本载体。**未碰** `verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`build/*.Linux/**`／`docs/**`（除白名单两件）／任何 `.cs`。
- **模式守恒**：逐件 `%a` 见 §4（**逐件 644／`so` 775**）；写盘一律 `temp+rename`（复述位件经 `python3 os.replace`，落盘后**逐件 `chmod` 回 644** 并复核）。
- **备份取在任何写之前**：§4 的"开工"值即 `cp -p` 备份件现取。
- **反腿产物**：`-DWPF_PTS_CLRUPD_FAKE=1` **只在副本**编译（`copy/`，**绝不进主链**）；跑真应用时**临时**把主链 `.so` 换成副本（`cf4613dad2fc015f`），跑完**逐字节还原**为 `63f0eb7c4d2fc8cd`（§3 末行）。
- **`WPF_PTS_DRIVE_PROBE=0` 腿**是**诊断腿**（控制②），非交付路径；它与"现权威"口径（探针缺省开）**不同体制**，已在 §2 ④ 具名。
- **证据强度（如实划界）**："改前"读数取**在册 `T-A15` 腿**（`/home/links-dev/tA15-work/evidence-default/`，`shim=3cb3ad48ef27d13d`）＝**在册证据**，"改后"／两控制腿＝本席**同趟新取**；四者同装置／同腿器／同 `pf`。
- **重活**：`bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- …`；四趟腿槽 `HEAVYSLOT=ACQUIRED/MEMOK…RELEASED`（held 34–35 s）；构建 held 2–3 s。
- **未跑**整趟 `verify-all`（任务明禁）；**未** `git add/commit/push`。

---

## §6 主动披露（待裁决）／具名 `NOINFO`／告警

1. **🔴 告警（症状门回归，归因已定钉）**：本增量使两腿 `app_rc 143 → 134`（**不可捕获 `FailFast`**）。**四条件表**（§2 ④）把归因钉在两处**同时**成立上：「符号在位且返 0」∧「驱动探针缺省开」；**不是**本席"清"的语义（控制①假成功腿**同样崩**；控制②关探针**逐字段回改前**）。
   ⇒ **处置建议（不属本增量写域／待队长裁）**：**下一增量**修 `wpf_pts_drive_probe2_oow` 的"窗外腿"陈旧句柄面。**本件不擅自改仪器**。
2. **`NOINFO-FSCLEARUPDATEINFO-SCOPE-NATIVE-OWNED-STATE`（具名，射程边界）**：本入口清的是**本模块自持**的增量状态（"该页的轨视觉是否已建起"这一下游见证面 ＋ 查询组毗邻位），**不是**托管/LineServices 的完整增量位图 —— 本侧**没有**那个源。⇒ 它**不**声称"页内容已重排"、**不**声称"页可见变化"（可见面由 §2 ④ 腿读数给：**页仍未绘出内容**）。
3. **`PRECOND-DRIVEPROBE-OOW-STALE-HANDLE-FAILFAST`（新具名前置，**先于**下面两名发生）**：`win32_pts.c` 的 `wpf_pts_drive_probe2_oow`（件内注释自称"**绝不**跨上下文用陈旧句柄"）在 `FsDestroyPage` 调用点拿**缓存的 `dp->drive_nmseg`** 调 `+136 pfnGetFirstPara`；该句柄在托管侧**可能已被释放** ⇒ `PtsContext.HandleToObject` 的 `Invariant.Assert` ⇒ **`FailFast`（不可捕获）**。机读证据：§2 ④ 崩点栈 ＋ 四条件表 ＋ `[DRIVE-PROBE2-OOW] where=FsDestroyPage` 行**只出现 1 次而调用 ≥2 次**（崩点那次因 `FailFast` **来不及打印**）。
4. **`PRECOND-FSUPDATEBOTTOMPAGE-EXPORT`／`PRECOND-FSQUERYTEXTDETAILS-EXPORT`（新具名前沿，本增量之后才到达）**：`ENFE` 各 **1** 次（声明现取：`Pts.cs:3135` `FsUpdateBottomlessPage`；`Pts.cs:3750` `FsQueryTextDetails`）。
5. **`DEFREG_DECLDRIFT=1 keys=KD`（如实记，待主控）**：本件改了 `KD`（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 第 `2258` 行 token）⇒ 已声明表 `build/MilBridge/tools/defect-registry-declared.tsv` 的**路由快照与该件不再一致**。该件**不在本件写域**（`build/MilBridge/tools/**` 黑名单）⇒ 照纪律 15／`D-G129`：**请主控重发 `declared.tsv`**。牙本身 `DEFREG=PASS rc=0`（`declared=225/route_ids=225`）。
6. **`bin/exports.txt` 与 `bin/libwpfwin32.so` 是 gitignored 件**（`.gitignore:24`）：派单把它们列入写域，本趟确已刷新（`+1` 行／重建），但**它们不入 git** ⇒ 交接必须靠**重建**（或另备缓存）。⇒ 如实记，非疏漏。
7. **`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2258` 是**已立案的"口径分歧行"**（`dated` 但无内容锚）**：它是**历史叙述**（"本席现取发现该行**又**回到 `工具口径 **88**`…"），本牙按"现值位"抽取。照 `T-A13`／`T-A5` **先例**把 token 同步为 live（`**87**`）以使 `PTSGAP=PASS`，**并在此具名重提**：**该行语义上是历史陈述，随动会改史实** —— 请队长裁定"**保值**（加内容锚使其转历史行）vs **随动**（现状）"。
8. **`docs/ROUTES.md:373` 句内还有一处非抽取位**（`**现算**：可操作 … ＋ … 的 **9** 个入口`）：随动后 `75 ＋ 9 = 84 ≠ 78` —— 该 **`9` 在本趟之前就已与在册定义不符**（在册 `impl-opts` 差现为 **3**）。⇒ 本趟**只随动本牙抽取位与同形位**，**不擅自改**该历史算术句（与 `T-A4` 先例同形制），**具名留待队长**。
9. **未做**：`git add/commit/push`；未跑整趟 `verify-all`／`static-jaws-check.sh`；未动任何牙本体。
SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-fsclear-impl-report.md | sha256sum | cut -c1-16`）= `8bda42afdf000de9`
