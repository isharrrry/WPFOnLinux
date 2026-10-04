# P1-tail2 · `T-A17` · 修 `PRECOND-DRIVEPROBE-OOW-STALE-HANDLE-FAILFAST`（症状门回归 → `app_rc=143`）

> **本件 `T-A17`（writer；本轮唯一写者）交付**。写域：`src/WpfGfx.Linux.Native/src/win32_pts.c`（手写源）＋ 其**登记面**（`tools/pts-gap-decl.txt` 的 `so16` 内容锚 ＋ dated 重锚注释；`bin/exports.txt`／`bin/libwpfwin32.so` 由重建刷新）＋ 本载体 `build/MilBridge/P1-tail2-oow-fix-report.md`。
> **未碰**：`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（牙本体）／`build/*.Linux/**`（生成件）／任何 `.cs`／任何复述位正文件（`ops`／`impl`／`tool` 三字段**未动** ⇒ 无随动需要）；`git add/commit/push` **未做**。
> **行号纪律**：本件所有行号**仅本次有效**；引件一律给内容锚。
> **重活**：构建 ＋ 跑腿**全部**走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- …`；进程只按 PID；显示位只用空闲 `:231`（`legs-to-env` 分配器复算）；**未跑**整趟 `verify-all`；写前 `cp -p` 备份；模式守恒。

---

## §0 结论速览（自包含）

1. **做了什么**：`win32_pts.c` 的**驱动探针**新增**句柄 liveness 判据**（`WPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD`，缺省 `1`）：
   - 该判据＝一个 **doc 级状态位** `wpf_pts_doc.drive_handles_live`（该 doc 缓存的**驱动衍生托管句柄**——`drive_nmseg`／`drive_nmp`／`sub_children[]`——是否仍可信）；
   - **置 0 的唯一时机 ＝ `FsDestroyPage`**（页销毁 ⇒ 该页的托管段落实例句柄**已先**被释放）；
   - **置 1 的唯一时机 ＝ 窗内首次取到 `drive_nmseg`**（`wpf_pts_drive_probe` 的 `+80` 支）；
   - 判据生效时，**页销毁之后**三处使用驱动句柄调托管回调的路径**一律拒**（出参一字不写 ＋ 具名留痕）：
     ① `wpf_pts_drive_probe2_oow`（窗外腿 `+136 pfnGetFirstPara`）⇒ `v136=REFUSED-NONLIVE-HANDLE`；
     ② `FsQueryTrackParaList` 的填充分支（`+176 CreateParaclient(dp->drive_nmp,…)`）⇒ `reason=drive-handles-released(page-destroyed)`；
     ③ `FsQuerySubtrackParaList` 的造客户端分支（`+176 CreateParaclient(obj->children[i],…)`）⇒ 同上。
2. **为什么必须拒**（现取因果，**崩因已定钉**）：页销毁后这些句柄已被托管释放 ⇒ 再用它们调 `+136`／`+176` 会撞
   `PtsContext.HandleToObject` 的 `Invariant.Assert("Handle has been already released.")` ⇒ **不可捕获 `FailFast`**（`app_rc=134`）。
   `T-A16` 让页视觉帧首次走通后，应用进入**页拆除→重建**路径，把这条**既有的探针缺陷**从"不可达"变成"必达"。
3. **验收结果（逐条见 §2／§3）**：
   - ① **症状门成对读数**：改前两腿 `app_rc=134`（`FailFast`，`k=23` 崩）**→ 改后两腿 `app_rc=143`**；其余字段与**在册基线**（`T-A15`）**逐字段成对**。✅
   - ② **反极性**：判据去掉（副本 `-DWPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD=0`）⇒ **必回 `134`**（且崩点栈与 `T-A16` **同形**）。✅
   - ③ 导出面：`nm -D --defined-only` 行数 **672** == `bin/exports.txt` 行数 **672**（**导出面一字未动**，无新增/无消失）；`PTSGAP=PASS`（零 `SITE-DRIFT`）。✅
   - ④ 其余症状门字段（`alive`／`magenta`／`colors`／`ink`／`ns`）与改前**成对**（`k=24` 逐字段相等；`k=23` 由「崩·空态」恢复为改前值）。✅
   - ⑤ `DEFREG` **rc=0**（`DEFREG_DECLDRIFT=0`）；`REPORTID` **rc=0**。✅
4. **口径重申**：**"计数未动 ≠ 能力未动"**（本增量不动缺口条数）；**"新异常类别 ≠ 本件造错"**——改后 k=23 仍会有**被捕获**的 `PtsException … Error code: '-10000'`（＝本侧**诚实拒绝**的**下游可见后果**，非崩溃）；**"不崩 ≠ 渲染正确"**（页仍未绘出内容）。
5. **`SELF-SHA16`（报告自指纹）＝ 见文末**。

---

## §1 实现（件:行 ＋ 原文；行号仅本次有效）

> 改动规模：`git diff --numstat src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`62 4`**；`tools/pts-gap-decl.txt` ＝ **`14 1`**。无"顺手优化"。

### 1.1 判据总闸（编译期宏；内容锚 `WPF_PTS_DRIVE_PROBE_FAKE_NMS` 之下）

```c
/* ⏪ `T-A17`：驱动探针**第二跳窗外腿**（`+136 pfnGetFirstPara`）前的**句柄 liveness 判据**总闸。
   缺省 `1` ＝判据生效（页销毁语境下**拒驱**）；`-DWPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD=0`
   （**只允许在应用副本上**单独编译）＝判据失效 ⇒ **复现旧序列** ⇒ 必回 `app_rc=134`（反极性腿）。
   ⚠️ **绝不许**把 `0` 编进主链产物。 */
#ifndef WPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD
#define WPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD 1
#endif
```

### 1.2 doc 级状态位（内容锚：`wpf_pts_doc.drive_nmseg` 字段之下的新增块，`:242`）

```c
    const void  *drive_nmseg;
    /* ⏪ `T-A17`：**该缓存句柄的 liveness 位** —— 1 ＝仍可信；0 ＝**已释放/销毁语境** ⇒ 窗外腿**拒驱**。
       置 1：窗内**首次**取到 `drive_nmseg` 时（见 `wpf_pts_drive_probe` 的 `+80` 支）；
       置 0：`FsDestroyPage`（页销毁 ⇒ 该页的托管段落实例句柄**已先**被释放）。
       `calloc` ⇒ 初值 0（在取到句柄之前无窗口可驱，故 0 不产生假拒）。 */
    int          drive_handles_live;
```

### 1.3 置 1（内容锚：`wpf_pts_drive_probe` 的 `+80` 支，`:2070`）

```c
if (!((const void *)d->drive_nmseg)) { d->drive_nmseg = (const void *)nmSeg1; d->drive_handles_live = 1; }
```

### 1.4 置 0（内容锚：`FsDestroyPage` 首句，`:3676`）

```c
int FsDestroyPage(void *pfscontext, void *pfspage)
{
    const char *reason = NULL;
    /* ⏪ `t151` … ⏪ `T-A17`：**置该 doc 的句柄 liveness = 0（释放后拒驱）** —— … */
    { wpf_pts_doc *ddp = wpf_pts_doc_ptr(pfscontext); if (ddp) ddp->drive_handles_live = 0; }
    wpf_pts_drive_probe2_oow(pfscontext, "FsDestroyPage");
```

### 1.5 判据点 ①：窗外腿 `+136`（`wpf_pts_drive_probe2_oow`，`:1653`）

```c
#if WPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD
    if (!dp->drive_handles_live) {
        g_pts_dp2_oow_refused++;
        fprintf(stderr, "[DRIVE-PROBE2-OOW] where=%s window=out nms136=%p rc136=- fSucc=- nmp=(nil) "
                        "idem136=- v136=REFUSED-NONLIVE-HANDLE calls=%d refused=%d "
                        "NOINFO=oow-nms-liveness-judge-native-selfrecorded-not-managed-read\n",
                where, dp->drive_nmseg, g_pts_dp2_oow_calls, g_pts_dp2_oow_refused);
        return;
    }
#endif
```

### 1.6 判据点 ②：`FsQueryTrackParaList`（`:4003`）

```c
            if (!dp || !fp176f || !fp192f)                    reason = "no-slot-or-doc";
            /* ⏪ `T-A17`：**句柄 liveness 判据** —— 页销毁后（`drive_handles_live==0`）该 doc 的
               `drive_nmp`（以及复用的 `fsp_pl_cur`）均已被托管释放 ⇒ … ⇒ **拒填**（出参一字不写 ＋ 具名 `reason`）。 */
            else if (WPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD && !dp->drive_handles_live) reason = "drive-handles-released(page-destroyed)";
            else if (!dp->drive_nmp)                          reason = "no-legal-nmp-in-this-run";
```

### 1.7 判据点 ③：`FsQuerySubtrackParaList`（`:4447`）

```c
        if (!fp176)                        reason = "no-slot-176";
        else if (!wpf_pts_ctx_is_live(dp)) reason = "ctx-not-live";
        /* ⏪ `T-A17`：**句柄 liveness 判据** —— 页销毁后 `obj->children[]` … 已被托管释放 ⇒ **拒填**。 */
        else if (WPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD && !dp->drive_handles_live)  reason = "drive-handles-released(page-destroyed)";
        else { /* 客户端：**只造缺的那些** … */ }
```

### 1.8 两只计数器（内部，**不新增导出**）

```c
static int          g_pts_dp2_oow_refused = 0;  /* ⏪ `T-A17`：因 liveness 判据被**拒驱**的次数（只计数，不新增导出） */
```
`FsQueryTrackParaList` 的拒绝走既有 `[FS_PAGE_GAP]` 具名行（`gap` 恰涨 1）；`FsQuerySubtrackParaList` 走既有 `[FSQSPL] out=UNWRITTEN` 行。

### 1.9 **为什么"判据要覆盖三处"**（中间尝试的现取教训，不掩盖）

- **尝试 ①（只改调用点 ①语境）**：`FsDestroyPage` 的窗外腿改为**按调用点**拒驱 ⇒ 崩点**转移**到
  `FsQueryTrackParaList` 的 `+176 CreateParaclient`（栈：`PtsPage.ArrangePage` ⇒ `FsQueryTrackParaList` ⇒ `PtsHost.CreateParaclient` ⇒ `HandleToObject` ⇒ `FailFast`）；读数仍 `134`（`evidence-after`／`evidence-after2`）。
- ⇒ **归因修正**：`drive_nmseg`／`drive_nmp`／`sub_children[]` 三者**同源**（都取自产生它们的那个 `FsCreatePage*` 页对象）
  ⇒ 判据必须是**doc 级**的（一个位），而非"某一调用点的语境"。**尝试 ②（本交付）**＝ doc 级位 ＋ 三处判据 ⇒ `143`。

---

## §2 验收标准 ①–⑤ → 证据映射（可复跑命令原文 ＋ 原始输出）

> 证据落**仓外私有目录** `/home/links-dev/tA17-work/evidence-*`；腿器 ＝ 仓内 `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh`（A 臂，`k=24`／`k=23`）；装置 `:231`；同 `pf`（`1757d610a687777c`）；`LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`（四趟＋反腿全）。

### ①② 构建（走槽）＋ 导出面（`evidence-after3`）

```
$ bash /home/links-dev/tA17-work/rebuild.sh
BUILD-RC=0
== 产物：bin/libwpfwin32.so（415792 字节）
== 导出符号总数：672
HEAVYSLOT=RELEASED rc=0 held=3s max_hold=1800s
--- 导出面现取 ---
so16=9c19dc0fef35cf4a
nm_D_defined=672
exports_lines=672
--- exports.txt diff vs 开工备份（应为空：导出面一字未动）---
EXPORTS-UNCHANGED(no-diff)
```

### ① 症状门**成对读数**（四条件表；同装置／同腿器／同 `pf`）

| 条件 | 主链 `.so` sha16 | 探针 | `k=24` | `k=23` | 判 |
|---|---|---|---|---|---|
| **改前**（`T-A16` 在册；探针缺省开） | `63f0eb7c4d2fc8cd` | 开 | `alive=yes app_rc=134 magenta=0 colors=383 ink=480000 ns=…FlowDocumentDemo ae=15386 fr=ef3fd6765f18f51b` | `alive=no app_rc=134 magenta=0 colors=1 ink=0 failfast=4 unrec=2 ns=…RichTextBoxDemo ae=480000 fr=2a60a00fc582e97d` | ⚠️ 回归基线 |
| **本件**（判据在位） | `9c19dc0fef35cf4a` | 开 | `alive=yes app_rc=143 magenta=0 colors=383 ink=480000 ae=15386 fr=ef3fd6765f18f51b` | `alive=yes app_rc=143 magenta=0 colors=383 ink=480000 ae=0 fr=ef3fd6765f18f51b` | ✅ **目标达成** |
| **反极性**（判据去·副本） | `b3fa1398879c226c` | 开 | `alive=yes app_rc=134 colors=383 ink=480000 ae=15386 fr=ef3fd6765f18f51b` | `alive=no app_rc=134 colors=1 ink=0 failfast=4 unrec=2 ae=480000 fr=2a60a00fc582e97d` | ⚠️ **该红必红** |
| **关探针**（`WPF_PTS_DRIVE_PROBE=0`） | `9c19dc0fef35cf4a` | 关 | `alive=yes app_rc=143 colors=383 ink=480000 ae=15386 fr=ef3fd6765f18f51b` | `alive=yes app_rc=143 colors=383 ink=480000 ae=0 fr=ef3fd6765f18f51b` | ✅ 探针为**必因** |

⇒ **成对口径**：改前两腿 `134` → 改后两腿 `143`（本件）；**且改后读数与在册 `T-A15` 基线**（`T-A16` §2④ 第一行：`k=24 143/383/480000/15386/ef3fd67`；`k=23 143/383/480000/0/ef3fd67`）**逐字段相等**。

**崩点原文（改前 `evidence-before/app_g1.log`，内容锚 `Handle has been already released`）**：
```
Unrecoverable system error.: Handle has been already released.
Process terminated.
   at MS.Internal.Invariant.FailFast(System.String, System.String)
   at MS.Internal.PtsHost.PtsHost.GetFirstPara(IntPtr, IntPtr, Int32 ByRef, IntPtr ByRef)
   at MS.Internal.PtsHost.PtsCache+<>c__DisplayClass16_0.<InitGenericInfo>b__0(IntPtr, IntPtr, Int32 ByRef, IntPtr ByRef)
   at MS.Internal.PtsHost.UnsafeNativeMethods.PTS.FsDestroyPage(IntPtr, IntPtr)
   at MS.Internal.PtsHost.PtsContext.OnDestroyPage(IntPtr, Boolean)
   at MS.Internal.PtsHost.PtsPage.DestroyPage()
```

**改后（本件）无崩点**（机读配对；`evidence-after3` / `evidence-before`）：
```
$ grep -c 'Handle has been already released' evidence-after3/app_g1.log     # ⇒ 0
$ grep -c 'Unrecoverable'                   evidence-after3/app_g1.log     # ⇒ 0
$ grep -c 'Handle has been already released' evidence-before/app_g1.log    # ⇒ 2
```
**改后拒驱／拒填的留痕原文**（`evidence-after3`）：
```
[DRIVE-PROBE2-OOW] where=FsQueryTrackParaList window=out nms136=0x2 rc136=- fSucc=- nmp=(nil) idem136=- v136=REFUSED-NONLIVE-HANDLE calls=392 refused=638 NOINFO=oow-nms-liveness-judge-native-selfrecorded-not-managed-read
[FS_PAGE_GAP] rc=-10000 reason=drive-handles-released(page-destroyed) entry=FsQueryTrackParaList ctx=0x… track=0x… cParas=1 owned=1 ok=392 gap=636
[HC-UNHANDLED] #1027 PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'. （**被捕获**；应用存活）
```
⇒ **失败必留痕**（拒驱＝计数＋具名行；拒填＝既有 `[FS_PAGE_GAP]` `gap` 恰涨 1）。

**逐日志（机读配对；`§` 见 `/home/links-dev/tA17-work/collect.sh`）**：

| 证据目录 | `app_g1.log` sha16 | 行数 | `OOW`(`FsDestroyPage`) | `OOW`(`FsQueryTrackParaList`) | `REFUSED` | `drive-handles-released` | 崩点数 |
|---|---|---|---|---|---|---|---|
| `before`（改前，`63f0eb7c`） | `6d850b332fc07131` | 5582 | 1 | 446 | 0 | 0 | 2 |
| `after`（尝试①，判据仅调用点①） | `5807ed39f629268e` | 5467 | 2 | 434 | 2 | 0 | 2 |
| `after2`（尝试①＋调用点②，仍缺 `FsQuerySubtrackParaList`） | `9e1cdd2a24b5fb3b` | 5079 | 11 | 384 | 41 | 0 | 2 |
| `after3`（**本交付**） | `35fe17b80e6578a4` | 7909 | 2 | 1028 | 638 | 636 | **0** |
| `rev0`（反极性副本 `b3fa1398`） | `c476606824f66ccd` | 4792 | 1 | 359 | 0 | 0 | 2 |
| `noprobe`（关探针） | `7a30a1a814a52991` | 4788 | 0 | 0 | 0 | 0 | 0 |

### ② 反极性（**实跑**；见 §3）

### ③ `PTSGAP` 对账 ＋ 导出面

```
$ bash build/MilBridge/tools/pts-gap-count-check.sh | tail -2
PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTrackParaList（具名前沿成立）
PTSGAP=PASS tool=87 dead=11 artifact=1 ops=75 impl=78 so16=9c19dc0fef35cf4a exports=672 root=/home/links-dev/netTest/GitProj/WPFOnLinux
$ echo $?                                               # ⇒ 0（**零 `SITE-DRIFT`**）
```
- `pts-gap-decl.txt` 的 `# PTSGAP-DECL:` 行**同趟**只改 `so16` 一个 token：`63f0eb7c4d2fc8cd` → `9c19dc0fef35cf4a`；并追加**一条 dated 重锚注释**（`tool/dead/artifact/ops/impl/exports/w66pre16` **全等**）。
- `nm -D --defined-only bin/libwpfwin32.so | wc -l` ＝ **672** ＝ `wc -l < bin/exports.txt`（**导出面一字未动**；`diff` vs 开工备份 ⇒ `EXPORTS-UNCHANGED(no-diff)`）。

### ④ 其余症状门字段（成对）

见 §2 ① 四条件表：`k=24` 改前／改后**逐字段相等**（`colors=383`／`ink=480000`／`magenta=0`／`ns=FlowDocumentDemo`／`ae=15386`／`fr=ef3fd6765f18f51b`）；`k=23` 由「崩·`colors=1`／`ink=0`」恢复为改前值「`colors=383`／`ink=480000`／`ae=0`／`fr=ef3fd6765f18f51b`」。

### ⑤ 两道牙 ＋ 自检面

```
$ bash build/MilBridge/tools/defect-registry-check.sh | tail -1
DEFREG=PASS declared=225 route_ids=225（…无未声明编号）          # rc=0；DEFREG_DECLDRIFT=0
$ bash build/MilBridge/tools/report-id-domain-check.sh | tail -1
REPORTID=PASS files=307 ids=2216 declared=225 glob=build/MilBridge/*report*.md   # rc=0
```

---

## §3 反极性（"该红必红"，**实跑**）

**载体**：副本 `.so`（`/home/links-dev/tA17-work/copy/libwpfwin32.unguarded.so`，`so16=b3fa1398879c226c`；**只在副本**以 `-DWPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD=0` 单独编译；`UNGUARDED-EXPORTS=672`）。

| 腿 | `.so sha16` | 判据 | `k=24 app_rc` | `k=23 app_rc` | 崩点栈 | `REFUSED`／`drive-handles-released` |
|---|---|---|---|---|---|---|
| **正**（本件） | `9c19dc0fef35cf4a` | 在位 | **`143`** ✅ | **`143`** ✅ | 无 | `638`／`636` |
| **反**（判据去） | `b3fa1398879c226c` | 失效 | `134` | `134`（崩） ❌（期望） | `FsDestroyPage`⇒`GetFirstPara`⇒`FailFast`（**与 `T-A16` 同形**） | `0`／`0` |

```
$ bash /home/links-dev/tA17-work/rev-legs.sh /home/links-dev/tA17-work/copy/libwpfwin32.unguarded.so rev0
REV-SWAP main_bak16=9c19dc0fef35cf4a -> fake16=b3fa1398879c226c tag=rev0
SWAPPED so16=b3fa1398879c226c
…
WROTE …/evidence-rev0/arm_A/leg_24.env k=24 arm=A alive=yes app_rc=134 magenta=0 colors=383
WROTE …/evidence-rev0/arm_A/leg_23.env k=23 arm=A alive=no  app_rc=134 magenta=0 colors=1
HEAVYSLOT=RELEASED rc=0 held=33s max_hold=1800s
RESTORED so16=9c19dc0fef35cf4a（对照备份 9c19dc0fef35cf4a）
```
⇒ **"把那一处 liveness 去掉 ⇒ 必回 `134`"成立**（可证伪）；且反腿崩点栈与改前**逐句同形**（`FsDestroyPage` ⇒ `PtsHost.GetFirstPara` ⇒ `FailFast`），反腿里 `REFUSED`／`drive-handles-released` **均为 0**（判据确已失效）。
**主链还原（逐字节）**：`RESTORED so16=9c19dc0fef35cf4a`（回读 == 备份）。

---

## §4 件级前后对账

| 件 | 开工（`cp -p` 备份）`sha16` | 收尾（现取）`sha16` | `%a` | 判 |
|---|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `435f74395c5bc6a5`（5035 行） | **`1121f032913c1582`**（5093 行） | 644 | `git diff --numstat = 62 4` |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `c5c4d1297c72f2a6` | **`0a35461707068aac`** | 644 | `git diff --numstat = 14 1`（声明行 1 ＋ dated 重锚注释 13） |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `9e416ff90c402671`（672 行） | **`9e416ff90c402671`**（672 行） | 644 | **不变**（`diff` 空：导出面一字未动） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `63f0eb7c4d2fc8cd`（415752 B） | **`9c19dc0fef35cf4a`**（415792 B） | 775 | 重建产物（gitignored）；反腿后**逐字节还原**（回读 == 备份） |

**备份路径**：`/home/links-dev/tA17-work/bak/{win32_pts.c,pts-gap-decl.txt,exports.txt,libwpfwin32.so}.orig` ＋ `copy/main-backup.so`（反腿期间的主链件备份）＋ `copy/libwpfwin32.unguarded.so`（反腿副本）。

**`git status --porcelain`（现取）**：
```
 M src/WpfGfx.Linux.Native/src/win32_pts.c
 M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt
?? build/MilBridge/tasks-tail2/T-A17.md                              ← 派单件（非本席所改）
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log     ← **先于本件存在**（非本席所改）
```
⚠️ `src/WpfGfx.Linux.Native/bin/**` **不入 `git status`** —— 该目录在 `.gitignore`（`git check-ignore` 现取命中）⇒ `exports.txt`／`.so` 只存在于工作树（交接靠**重建**）。

---

## §5 边界 · 纪律 · 口径

- **写域**：仅 `win32_pts.c`（手写源）＋ `tools/pts-gap-decl.txt`（`so16` token ＋ dated 注释）＋ `bin/*`（重建刷新）＋ 本载体。**未碰** `verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`build/*.Linux/**`／`docs/**`／任何复述位正文件／任何 `.cs`。
- **模式守恒**：逐件 `%a` 见 §4（`win32_pts.c`／`pts-gap-decl.txt`／`exports.txt` 644；`.so` 775）。
- **备份取在任何写之前**：§4 的"开工"值即 `cp -p` 备份件现取。
- **反腿产物**：`-DWPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD=0` **只在副本**编译（`copy/`，**绝不进主链**）；跑真应用时**临时**把主链 `.so` 换成副本（`b3fa1398879c226c`），跑完**逐字节还原**为 `9c19dc0fef35cf4a`（§3 末行）。
- **重活**：`bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- …`；六趟腿＋两次重建槽 `HEAVYSLOT=ACQUIRED/MEMOK…RELEASED`（held 2–37 s）。进程只按 PID；显示位 `:231`（分配器 `DISPLAY_PICK`／`DISPLAY_HANDOFF` 单向下传）。
- **未跑**整趟 `verify-all`（任务明禁）；**未** `git add/commit/push`。

---

## §6 主动披露（待裁决）／具名 `NOINFO`／告警

1. **✅ 回归已修（症状门 `134 → 143`，两腿）**，且**与在册 `T-A15` 基线逐字段成对**。修法**不是**掩盖：判据＝**doc 级 liveness 位**，只在**页销毁之后**拒；**页销毁之前**所有探针读数**照旧**（`evidence-after3` 仍 638 条 `REFUSED` 之外有 1028 条正常窗外腿行）。
2. **`NOINFO-OOW-NMS-LIVENESS-JUDGE-NATIVE-SELFRECORDED-NOT-MANAGED-READ`（具名，射程边界）**：`drive_handles_live` 是 **native 侧自记状态**，**不是**托管句柄的 liveness 读数（native 侧无该观测口）⇒ 判据只能"在**已知会释放**的语境（`FsDestroyPage`）翻位"。它**不**声称"任何时刻的句柄有效性都已判准"。
3. **🟡 下游可见后果（如实记，非崩溃）**：改后 `k=23` 仍会出现**被捕获的** `[HC-UNHANDLED] PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'.`（＝本侧**诚实拒绝** `FsQueryTrackParaList` 后，托管 `PTS.Error(-10000)` 的必然反映）⇒ 计数增长（`k=23 unh` 由 `0` 升），但**应用存活**（`app_rc=143`）、症状门成对。⇒ **"拒"的形态是"报告失败"而非"崩"**，符合本仓"永不假成功／失败必留痕"。
4. **⚠️ 归因修正（本件现取）**：`T-A16` §6-3 把 `PRECOND-DRIVEPROBE-OOW-STALE-HANDLE-FAILFAST` 定钉在"`FsDestroyPage` 的窗外腿"。本件现取证明：**同一根源（页销毁后托管句柄被释放）还有两处消费**（`FsQueryTrackParaList`／`FsQuerySubtrackParaList` 的 `+176 CreateParaclient`）。⇒ 只堵 `FsDestroyPage`（尝试①）**不够，崩点会转移**（`evidence-after`／`evidence-after2` 即为证）。本件把判据提升为 **doc 级**。
5. **`g_pts_dp2_oow_refused` 是内部计数器，不新增导出**（故导出面 `672` 不变、`PTSGAP`／`DEFREG` 零漂移）。若主控要机读口，可后续增量加 `WpfLinuxWin32_PtsDriveProbe2OowRefused`（届时需同趟刷 `exports.txt`）。
6. **`DEFREG_DECLDRIFT=0`**（与 `T-A16` 的 `DEFREG_DECLDRIFT=1 keys=KD` 不同）：本件**未碰** `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`，故与已声明表的**路由快照无漂移**。
7. **未做**：`git add/commit/push`；未跑整趟 `verify-all`／`static-jaws-check.sh`；未动任何牙本体；未动任何复述位正文件（**无随动需要**：`tool/ops/impl` 三字段未动）。
SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-oow-fix-report.md | sha256sum | cut -c1-16`）= 4bde7dc1d9e00e99
