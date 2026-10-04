# P1-tail2 · `TASK-0302` 增量 · `FsQuerySubtrackDetails` **诚实拒绝导出**（native 主链实现）

> **本件 `T-A4`（writer）交付**。写域：`src/WpfGfx.Linux.Native/src/win32_pts.c` ＋ 其登记面（`bin/exports.txt`／`tools/pts-gap-decl.txt`／`bin/libwpfwin32.so` 重建产物）＋ 本载体。**未碰** `build/close-wave.sh`／`verify-all.sh`／`build/MilBridge/tools/**`／`docs/**`／`samples/**`／`build-shim.sh`／任何 `.cs`。未 `git add/commit/push`。
> **判据载体**：`build/MilBridge/P1-tail2-fsqsub-recon.md`（`T-A3`）§3.3／§4／§5.3（本件照其 §4 `D1–D6` ＋ §5.3 最小落地）。
> **行号纪律**：本件所有行号**仅本次有效**；引件一律给内容锚。

## §0 结论速览（自包含）

1. **做了什么**：在 native 手写源 `win32_pts.c` **新增导出** `FsQuerySubtrackDetails`，形态**只有三条**（照判据 §5.3）：
   - **① 导出符号**（使 CLR 不再抛 `EntryPointNotFoundException`；`ENFE` 对该名归零）；
   - **② 入参按对象身份认领**（`pSubTrack` 经 `wpf_pts_sub_claim` **唯一认领**；NULL／栈地址／外来值**必被拒**）；
   - **③ 出参一字不写**（`FSSUBTRACKDETAILS{fsupdinf;nms;fsrc;cParas}` **全部不动**）＋ **失败必留痕**（具名 `[FSQSTD]` 台账）＋ **永不返 0**。
2. **诚实上界（照 `T-A3` 现取，未越）**：出参面 `cParas`（内容层 `S-2b`，无源）与 `nms`（需托管句柄，native 无合法来源）**都无源** ⇒ **`rc=0` 永不可给**。故**没有成功分支** —— `g_pts_fsqstd_ok` 结构性恒 0。
3. **闸关与闸开分开报**（判据 §4 `D5`）：缺省路径（`FSPARALIST.pfspara` 的填充整块只在 `wpf_pts_drive_probe_enabled()` 内、缺省关）⇒ 入参 `pSubTrack=NULL` ⇒ `reason=null-subtrack`；认领成功但未造型 ⇒ `reason=no-layout-content-model`。**两路判词不同**。
4. **验收全绿**（逐条证据见 §2）：
   - ① `.so` 重建成功：`nm` 命中 `FsQuerySubtrackDetails` **1**；`nm -D --defined-only` 行数 **670** == `exports.txt` **670**；`exports.txt` 逐名**仅 +1**（无导出消失）。
   - ② `ENFE` 归零（**成对**，同装置单变量）：原主链 `.so` ⇒ `named 'FsQuerySubtrackDetails'` **1177** 行；新主链 `.so` ⇒ **0** 行（并伴随 `[FSQSTD]` **1002** 行，证明调用**真的进入**本侧入口）。
   - ③ 拒绝语义：`rc=-10000`（非 0）＋ 具名 `[FSQSTD]` 行原文 ＋ **出参字节读回证未写**（探针：缓冲保持 `0xAA/0x55/0x0F`）。
   - ④ `pts-gap-decl.txt` 同趟更新（声明行 vs 现算**逐字段相等**）；`DEFREG` `rc=0`；`REPORTID` `rc=0`。
   - ⑤ 主链其余不变：`win32_x11.c` `sha16` 不变；`PtsCache.Linux.cs` 未碰；症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）**逐字段与改前同**。
5. **主动披露（待裁决）**：`tool/ops/impl` 各 **−1**（`89/77/80`）⇒ 在册数声明的**正文复述位**（`docs/ROUTES.md` 等，仍写 `78/81`）与现算不一致 ⇒ `pts-gap-count-check.sh` 报 `SITE-DRIFT`（**只**是正文位未同改，非声明白相矛盾）。那些件在 `T-A4` 写域（黑名单 `docs/**`）之外 ⇒ 本件**只更新** `pts-gap-decl.txt` 的**声明行**，正文位留待持有它们的写者同趟改（见 §5）。

---

## §1 实现（件:行 ＋ 原文；行号仅本次有效）

### 1.1 登记面：`k_pts_entries[]` 加名（`win32_pts.c`，内容锚＝表末）

现状（表在 `"FsQueryTrackParaList",` 后追加一行，**不改动现有索引**）：

```c
    "FsQueryTrackParaList",
    "FsQuerySubtrackDetails",
};
#define WPF_PTS_ENTRY_COUNT ((int)(sizeof(k_pts_entries) / sizeof(k_pts_entries[0])))
```

⇒ 新入口索引 19；`g_pts_seen[]`／`g_pts_calls[]` 各 +1 元素；**报告行 `calls=` 域只列 `0..11`**（`WpfLinuxWin32_PtsGapReport` 现取）⇒ **报告行长度不变**（不影响自检的长度纪律）。

### 1.2 出参结构自证（`_Static_assert`）

```c
typedef struct {                              /* FSSUBTRACKDETAILS 镜像（**只用于尺寸/偏移自证**；不 deref 托管结构） */
    int   fskupd;        /* FSUPDATEINFO.fskupd（FSKUPDATGE : int）        @ +0  */
    int   dvr_shifted;   /* FSUPDATEINFO.dvrShifted                        @ +4  */
    void *nms;           /* nms                                            @ +8  */
    int   u, v, du, dv;  /* FSRECT{u,v,du,dv}                              @ +16 */
    int   c_paras;       /* cParas                                         @ +32 */
} wpf_pts_fssubtrackdetails;
_Static_assert(sizeof(wpf_pts_fssubtrackdetails) == 40, "sizeof(FSSUBTRACKDETAILS) != 40");
_Static_assert(offsetof(wpf_pts_fssubtrackdetails, nms)     ==  8, "FSSUBTRACKDETAILS.nms 偏移 != +8");
_Static_assert(offsetof(wpf_pts_fssubtrackdetails, u)       == 16, "FSSUBTRACKDETAILS.fsrc 偏移 != +16");
_Static_assert(offsetof(wpf_pts_fssubtrackdetails, c_paras) == 32, "FSSUBTRACKDETAILS.cParas 偏移 != +32");
```

出处：`Pts.cs:1527-1533`（`FSSUBTRACKDETAILS`）＋ `Pts.cs:849-855`（`FSRECT{u,v,du,dv}`）＋ `Pts.cs:1942-1947`（`FSUPDATEINFO`）⇒ `sizeof=40`（`IntPtr` 对齐）。

### 1.3 入口本体（三路拒绝 ＋ 出参零写入 ＋ 具名留痕）

```c
int FsQuerySubtrackDetails(void *pfscontext, void *pSubTrack, void *pSubTrackDetails)
{
    /* 🔴 D1：本入口**绝不触碰** `pSubTrackDetails` —— 一个字节都不写 */
    g_pts_fsqstd_calls++;
    { int _i = wpf_pts_index("FsQuerySubtrackDetails"); if (_i >= 0) g_pts_seen[_i]++; }
    const char *reason = NULL;
    wpf_pts_subtrack *obj = NULL;
    if (!pSubTrack)                               { reason = "null-subtrack";           g_pts_fsqstd_null++; }
    else if (!wpf_pts_sub_claim(pSubTrack, &obj)) { reason = "unclaimable-subtrack";    g_pts_fsqstd_unclaim++; }
    else                                          { reason = "no-layout-content-model"; g_pts_fsqstd_unformatted++; }
    /* ⚠️ **没有成功分支**：`cParas`／`nms` 无源 ⇒ `rc=0` 永不可给 ⇒ `g_pts_fsqstd_ok` 恒 0。 */
    (void)pfscontext; (void)pSubTrackDetails; (void)obj;
    g_pts_fsqstd_gap++;
    g_pts_fsqstd_last_reason = reason;
    fprintf(stderr, "[FSQSTD] rc=%d reason=%s entry=FsQuerySubtrackDetails ctx=%p psub=%p "
                    "calls=%d ok=%d gap=%d null=%d unclaim=%d unformatted=%d out=UNWRITTEN bytes=0\n", ...);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;      /* ← 改成 0 就是制造静默半通／伪成功（D2） */
}
```

承重面（逐条对应判据）：
- **D1**：函数体内**没有任何**对 `pSubTrackDetails` 的读写（`(void)pSubTrackDetails;` 是"参数在册、零写入"的机器可读形态）。
- **D2**：**没有 `return 0` 路径**（`g_pts_fsqstd_ok` 恒 0）。
- **D3**：返非 0 **必**打具名 `[FSQSTD]` 行（含 `reason=`／`calls=`／`ok=`／`gap=`）。
- **D4**：身份**只**靠 `wpf_pts_sub_claim`（指针等值于在册对象字段地址），不靠 `rc`／数值。
- **D5**：`null-subtrack` 与 `no-layout-content-model` **分开报**。
- 出口码沿用 `WPF_PTS_ERR_NOT_IMPLEMENTED`（`tserrNotImplemented` `-10000`），与全族一条口径。

---

## §2 验收项 → 证据映射（可复跑单行命令原文 ＋ 原始输出）

> 所有证据脚本落在**仓外私有目录** `/home/links-dev/tA4-fsqstd/`（不写仓内，除 `pts-gap-decl.txt` 的声明行与本载体）。显示号只用空闲 `:23x`；重活全走 `heavy-slot`。

### ②① 构建（走槽）＋ 导出面

```
$ bash /home/links-dev/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- \
    bash -c 'cd /home/links-dev/netTest/GitProj/WPFOnLinux/src/WpfGfx.Linux.Native && bash build-shim.sh --symbols'
HEAVYSLOT=ACQUIRED waited=0s cmd=bash build-shim.sh --symbols
HEAVYSLOT=MEMOK avail=24857MB min_avail=2500MB
== 链接 -shared -Wl,--no-undefined
== 产物：bin/libwpfwin32.so（406872 字节）
== 导出符号总数：670
```

```
$ cd /home/links-dev/netTest/GitProj/WPFOnLinux/src/WpfGfx.Linux.Native
$ nm -D --defined-only bin/libwpfwin32.so | grep -c '^[0-9a-f]* T FsQuerySubtrackDetails$'   # ⇒ 1
$ nm -D --defined-only bin/libwpfwin32.so | wc -l                                            # ⇒ 670
$ wc -l < bin/exports.txt                                                                    # ⇒ 670
$ diff /home/links-dev/tA4-fsqstd/bak/exports.txt.orig bin/exports.txt
104a105
> FsQuerySubtrackDetails
```

⇒ 验收① **成立**：命中 **1**；`nm` 行数 **670** == `exports` 行数 **670**；逐名**仅 +1**（`FsQuerySubtrackDetails`，零消失）。

### ②③ 拒绝语义（探针：出参**字节读回**证未写）

```
$ bash /home/links-dev/tA4-fsqstd/run_probe.sh
=== 探针标准输出（读回证据） ===
dlsym_ok=1
case=null-subtrack rc=-10000 out_untouched=1 bytes0_8=aaaaaaaaaaaaaaaa
case=unclaimable-stack rc=-10000 out_untouched=1 bytes0_8=5555555555555555
case=unclaimable-global rc=-10000 out_untouched=1
VERDICT rc_all_nonzero=1 out_written_any=0
[stderr]
[FSQSTD] rc=-10000 reason=null-subtrack entry=FsQuerySubtrackDetails ctx=0x1234 psub=(nil) calls=1 ok=0 gap=1 null=1 unclaim=0 unformatted=0 out=UNWRITTEN bytes=0
[FSQSTD] rc=-10000 reason=unclaimable-subtrack entry=FsQuerySubtrackDetails ctx=0x1234 psub=0x7ffefbe81c1c calls=2 ok=0 gap=2 null=1 unclaim=1 unformatted=0 out=UNWRITTEN bytes=0
[FSQSTD] rc=-10000 reason=unclaimable-subtrack entry=FsQuerySubtrackDetails ctx=0x1234 psub=0x5b30d0d4c010 calls=3 ok=0 gap=3 null=1 unclaim=2 unformatted=0 out=UNWRITTEN bytes=0
```

⇒ 验收③ **成立**：三路 `rc=-10000`（非 0）＋ 出参缓冲**保持原毒值**（`out_untouched=1`；`out_written_any=0`）＋ 具名 `[FSQSTD]` 行原文如上。探针源码 `/home/links-dev/tA4-fsqstd/c_probe.c`（把出参缓冲填毒值，调用后**读回**逐字节比对 —— 只有"读回"能证明"未写"）。

### ② `ENFE` 归零（**成对**：同装置、同条件、单变量＝shim；探针路径）

```
$ bash /home/links-dev/tA4-fsqstd/compare_enfe_slot.sh
### 腿 OLD（原主链 .so 26da177686acb1f0）
  navclick_rc=0
  alive_during=yes
  app_rc=143
  shim=26da177686acb1f0
  ENFE_FsQuerySubtrackDetails=1177
  FSPARALIST_PARA=1177
  FSQSTD=0
### 腿 NEW（新主链 .so a1403ea71c2bf487）
  navclick_rc=0
  alive_during=yes
  app_rc=143
  shim=a1403ea71c2bf487
  ENFE_FsQuerySubtrackDetails=0
  FSPARALIST_PARA=1002
  FSQSTD=1002
  FSQSTDROW=[FSQSTD] rc=-10000 reason=no-layout-content-model entry=FsQuerySubtrackDetails ctx=0x563425241b50 psub=0x56342a7099f4 calls=1 ok=0 gap=1 null=0 unclaim=0 unformatted=1 out=UNWRITTEN bytes=0
```

⇒ 验收② **成立**：`1177 → 0`。且新腿 `[FSQSTD]` **1002** 行，`reason=no-layout-content-model`（**认领成功但未造型**）⇒ 调用**真的进入**本侧入口，且闸开路径判词与判据 §4 `D5` 一致。

> **口径如实（附加）**：本节两腿都在 `WPF_PTS_DRIVE_PROBE=1`（探针路径）下跑 —— 因为**缺省路径下 `pfspara` 恒 0**，`FsQuerySubtrackParaList` 拒绝 ⇒ 该入口**在缺省路径下改前/改后都不会被走到**（无判别力）⇒ 探针路径才是**有判别力**的成对读数（`T-A3` §3.2 `PRECOND-PFSPARA-ONLY-IN-PROBE` 的现场印证）。缺省路径（无探针）的 `ENFE` 亦为 **0**（新主链规范腿，见下），但**不单独充当判别证据**。

### ③ 规范腿器（仓内 canonical）＋ ⑤ 症状门（缺省路径）

规范腿器 `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh`（A 臂 k=24/k=23）：

```
$ bash /home/links-dev/tA4-fsqstd/legs_slot.sh
shim_sha16=a1403ea71c2bf487 pf_sha16=1757d610a687777c
LEG k=24 alive=yes app_rc=143 magenta=0 colors=383 ns=HandyControlDemo.UserControl.FlowDocumentDemo ae=15386 ink=480000
LEG k=23 alive=yes app_rc=143 magenta=0 colors=383 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae=0 ink=480000
LEGS_RUNNER=PASS requested=2 obtained=2 refused=0 display=:231
```

症状门**成对**（同装置单变量，缺省路径）：

```
$ bash /home/links-dev/tA4-fsqstd/compare_symptom_slot.sh
### 腿 OLD（原主链 .so 26da177686acb1f0，缺省路径）
  alive_during=yes  app_rc=143  SHOT=FILE=…/k24.png 1280x1024 colors=383 magenta=0 total=1310720 ink=480000  NS=[NS] loaded …FlowDocumentDemo
### 腿 NEW（新主链 .so a1403ea71c2bf487，缺省路径）
  alive_during=yes  app_rc=143  SHOT=FILE=…/k24.png 1280x1024 colors=383 magenta=0 total=1310720 ink=480000  NS=[NS] loaded …FlowDocumentDemo
```

⇒ 验收⑤ **成立**：症状门（`alive=yes`／`app_rc=143`／`magenta=0`／`colors=383`／`ink=480000`／`ns=FlowDocumentDemo`）**逐字段与改前同**（另与仓内在册 `evidence/leg_24.env`／`leg_23.env` 亦逐字段相同）。

### ④ 在册数／两道牙

```
$ bash /home/links-dev/tA4-fsqstd/calc_gap.sh
LIVE tool=89 dead=11 artifact=1 ops=77 impl=80 stubs=3 so16=a1403ea71c2bf487 exports=670 w66pre16=bf6b683d94549087
```

`pts-gap-decl.txt` 声明行**同趟更新**为（照仓内"只增不改"体例，附 dated 重锚注释）：

```
# PTSGAP-DECL: tool=89 dead=11 artifact=1 ops=77 impl=80 so16=a1403ea71c2bf487 exports=670 w66pre16=bf6b683d94549087
```

```
$ bash build/MilBridge/tools/pts-gap-count-check.sh | tail -3
PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTrackParaList（具名前沿成立）
PTSGAP=FAIL tool=89 dead=11 artifact=1 ops=77 impl=80 so16=a1403ea71c2bf487 exports=670 root=/home/links-dev/netTest/GitProj/WPFOnLinux
```

⇒ **声明行 vs 现算逐字段相等**（无 `FIELD-MISSING`／`DRIFT` 行 ⇒ 八格全等）；`PTSGAP=FAIL` 的**唯一**来源是正文复述位 `SITE-DRIFT`（`docs/unimplemented.md`／`README.md`／`handoff`／`win32_classification.c` 仍写旧数）—— 见 §5 披露。

```
$ bash build/MilBridge/tools/defect-registry-check.sh | tail -1
DEFREG=PASS declared=225 route_ids=225（…无未声明编号）              # rc=0

$ bash build/MilBridge/tools/report-id-domain-check.sh | tail -1
REPORTID=PASS files=302 ids=2215 declared=225 glob=build/MilBridge/*report*.md   # rc=0
```

⇒ 验收④ **成立**：`pts-gap-decl.txt` 同趟更新（声明 vs 现算一致）；`DEFREG` `rc=0`；`REPORTID` `rc=0`。

---

## §3 件级前后对账

| 件 | 开工（备份）`sha16` | 收尾（现取）`sha16` | 判 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `57a80e0bb51d17ea`（342451 B） | **`e0b5a3a4a21e2275`** | **`git diff --numstat = 61 0`**（全新增）；`stat %a` 前后 **644** |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `3942a1aafa41e1ca`（669 行） | **`f61b9b1e55fdc600`**（670 行） | **生成件**（`build-shim.sh --symbols` 产出）⇒ 由重建刷新；**逐名仅 +1** |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `cc2f30a3577112f0` | **`32b303148aca23a9`** | **`git diff --numstat = 11 1`**（改声明行 1 行 ＋ 追加 dated 重锚注释）；`stat %a` 前后 **644** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `26da177686acb1f0` | **`a1403ea71c2bf487`**（406872 B） | **重建产物**（gitignored） |
| `src/WpfGfx.Linux.Native/src/win32_x11.c` | `4576fc68bcbbf329` | **`4576fc68bcbbf329`** | **不变** ✅ |
| `build/PresentationFramework.Linux/PtsCache.Linux.cs` | （未触碰） | `48cf0d8d7d1a90dd`（现取） | **未碰**（不在写域） ✅ |

**备份路径**：`/home/links-dev/tA4-fsqstd/bak/{win32_pts.c.orig,exports.txt.orig,pts-gap-decl.txt.orig,libwpfwin32.so.orig}`（`cp -p`，取在**任何写之前**）。

**`git status --porcelain`（现取，本件相关）**：

```
 M src/WpfGfx.Linux.Native/src/win32_pts.c
 M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt
```

（`bin/exports.txt` 与 `bin/libwpfwin32.so` 是 **gitignored 产物** ⇒ 不出现在 `git status`；本件**未** `git add/commit/push`。另有两项**非本件**生成的 untracked：`build/MilBridge/tasks-tail2/T-A4.md` 与 `build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log` —— 均**先于**本件存在。）

---

## §4 边界 · 纪律 · 口径

- **写域**：仅 `win32_pts.c`（手写源）＋ `exports.txt`（由重建刷新）＋ `pts-gap-decl.txt`（声明行 ＋ dated 注释）＋ `libwpfwin32.so`（重建）＋ 本载体。**未碰** `build/close-wave.sh`／`verify-all.sh`／`build/MilBridge/tools/**`／`docs/**`／`samples/**`／`build-shim.sh`／任何 `.cs`。
- **铁律（生成件）**：`exports.txt` **不手改** —— 由 `build-shim.sh --symbols`（`nm -D \| awk \| sort`）重建刷新 ⇒ 改的是**产出它的源**（`win32_pts.c` 的导出定义）。
- **重活**：全部走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- …`；进程**只按 PID**；显示号只用空闲 `:23x`；**不跑**整趟 `verify-all`；`static-jaws-check.sh` **未跑**（本任务不加牙）。
- **模式守恒**：`stat -c %a` 三件前后均 **644**。
- **探针／腿脚本**：全在仓外私有目录 `/home/links-dev/tA4-fsqstd/`（不进仓、不进 `git`）；重活产物落 `/home/links-dev/tA4-work/`（私有，不碰共享 `~/w67-work`；规范腿器经 `W67_WORK` 指向私有目录，`sync-applocal.sh` 同步权威五件到**私有 app 副本**）。
- **引用外部读数**：`build/MilBridge/P1-tail2-fsqsub-recon.md`（判据载体）为本件**照抄**的上限；其 §3.1 的 `pfspara` 运行期读数**引自该件**（本席**未**独立复算其原始载体的读数）。

---

## §5 主动披露（待裁决）

1. **`tool/ops/impl` 各 −1（`90/78/81 → 89/77/80`）＋ 正文复述位未同改 ⇒ `pts-gap-count-check.sh` 报 `SITE-DRIFT`**。
   - **机理**：`FsQuerySubtrackDetails` 由「会 `EntryPointNotFoundException` 的缺口」变为「已导出可用」⇒ `check-shim-coverage.py` 的 `[PresentationNative_cor3.dll]` 缺口数 **−1** ⇒ `ops/impl` 同步 **−1**。
   - **本件已做**：`pts-gap-decl.txt` 的**声明行**同趟更新（八格与现算**全等**），并追加 dated 重锚注释说明来由。
   - **本件未做（越域）**：正文复述位（`docs/ROUTES.md`／`README.md`／`build/MilBridge/HANDOFF-NEXT.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`docs/unimplemented.md`／`src/…/win32_classification.c`）仍写 `78/81`／`tool=90` ⇒ 那些件在 `T-A4` 写域（**黑名单 `docs/**`**）之外，**本件不得改**。⇒ 请**持有那些件的写者**或**主控**同趟改齐（或裁决"正文位以声明行为准、下一波统一重锚"）。
   - **口径句**：**"计数下降 ≠ 能力前进"** —— 本入口**永不返 0**（出参无源）⇒ 只是"缺符号"变"诚实拒绝"，不是"富文本页能排版了"。这与 `pts-gap-count-check.sh` 件头"进度 ＝ 具名前沿跳数、不是缺口条数"**同一口径**。
2. **`ENFE` 成对读数用探针路径（`WPF_PTS_DRIVE_PROBE=1`）**：缺省路径下 `pfspara` 恒 0 ⇒ 该入口在缺省路径下**改前/改后都不会被走到** ⇒ 无判别力。故成对读数取探针路径（缺省路径的 `ENFE` 亦为 0，一并给出，但不作判别证据）。**不**把"闸开时可得"读成"缺省路径已可得"（`T-A3` §4 的 `P13` 反腿，本条**未犯**）。
3. **`win32_pts.c` 的改动方式**：本件用**精确字符串替换**（原子替换写）插入两处（`k_pts_entries` 表末 ＋ `FsQuerySubtrackParaList` 之后），未走 `temp+rename` 脚本 —— 备份取在**任何写之前**（`cp -p` 四件），如实现非原子写需复核，可据 §3 备份逐位回滚。**如实披露**。
4. **`libwpfwin32.so`／`exports.txt` 是 gitignored 产物**：本件对它们的"前后 sha16"以**现取**为准（不进 `git`、不出现于 `git status`）；`bin/abi-layout` 等其它 `bin/` 件未动。
5. **未重跑整趟 `verify-all`**（任务明禁）；`static-jaws-check.sh` 未跑（不加牙）；`pts-gap-count-check.sh` 的 `PTSGAP=FAIL` **只因**正文复述位（见披露 1），**声明 vs 现算**面（八格）**全等**。

---

`P1-FSQSUB-IMPL 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 756dd674bdf85dd0（末行＝本行）`
