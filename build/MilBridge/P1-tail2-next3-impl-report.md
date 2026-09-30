# P1-tail2 · `T-A20` · 选靶 ＋ 诚实实现（`FsQueryTextDetails`）＋ 复述位随动 —— native 主链实现（`TASK-0302` 增量）

> **本件 `T-A20`（实现子代理；本轮唯一写者）交付**。**写域**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（手写源）＋ 其**登记面**（`tools/pts-gap-decl.txt` 声明行 ＋ dated 重锚注释；`bin/exports.txt`／`bin/libwpfwin32.so` 由重建刷新）＋ **复述位现值位**（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`）＋ 本载体。
> **未碰**：`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（牙本体）／`build/*.Linux/**`（生成件）／任何 `.cs`；`git add/commit/push` **未做**。
> **上游契约**：声明 `Pts.cs:3749-3753`；调用点 `TextParaClient.cs` 十余处（首个 `ValidateVisual:56`）。
> **行号纪律**：本件所有行号**仅本次有效**；引件一律给内容锚。
> **重活**：构建 ＋ 跑腿**全部**走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- …`；进程只按 PID；显示位只用空闲 `:231`（装置自配）；**未跑**整趟 `verify-all`；写前 `cp -p` 备份；模式守恒（`%a` 逐件见 §9）。
> **⚠️ 派单件 `T-A20` 的"现读前言"是 `T-A19` 的**输入态**（`.so 9c19dc0fef35cf4a`／`ENFE=2`／`[HC-UNHANDLED]=904`）** —— 而 `T-A19` **已落地并冻结**（`HEAD=0125024`，`.so 43ec9cd1bbd96582`／`exports 673`）。**本件一律以现场为准**（照 `HANDOFF-NEXT` §7 现取纪律）：现件代 ＝ **`43ec9cd1bbd96582`**，前沿 ＝ **`FsQuerySubtrackDetails` 409 ＋ `FsQueryTextDetails` 53**（§1）。**改前读数全部本趟现取**（不照抄 `T-A19` 载体）。

---

## §0 结论速览（自包含）

1. **选靶（现读前沿按入口名分类，本趟现取）**：`409 FsQuerySubtrackDetails`（`PtsException(-10000)`）｜`53 FsQueryTextDetails`（`ENFE`）。**有源/无源判定**（§1.2）⇒ 最高计数项 `FsQuerySubtrackDetails`：**入参无源**（托管传 `psub=0x4`，**托管句柄**，本侧不可认领）∧ **已有成功分支**（非"缺实现"）⇒ **不可做**；余下 `FsQueryTextDetails`：**是唯一"可做"项**（`ENFE` ⇒ 符号不在位是**绑定期失败**，本侧**没有**任何实现；导出即可让该名离开缺符号名单）。**选靶 ＝ `FsQueryTextDetails`**。
2. **做了什么**：native 新增**导出** `FsQueryTextDetails`（**诚实导出面**：入参按对象身份认领以**分离失败原因**；出参 `FSTEXTDETAILS` **本侧无源** ⇒ **恒返 `-10000` ＋ 具名留痕 ＋ 出参一字不写**；`rc=0` **一次都不给**）。
   - **该靶 `ENFE` 归零**：`entry point named 'FsQueryTextDetails'` **`53 → 0`**（同趟 A/B，§3）。
   - **同趟新事实（本件最有价值的读数）**：真腿里 `pPara` **恒为 `0x4`** —— 与同侪 `FsQuerySubtrackDetails` 的 `psub=0x4` **同形**（`T-A49(b)`：小整数 `0x1..0x5` 是**托管句柄的真值形态**，非可疑特征）⇒ **本入口的入参也是托管句柄**，本侧**不可认领** ⇒ 现场判词 **`reason=unclaimable-para`（52 条）**。**⇒ 入参面与出参面都"本侧无源"**（§1.2 现取更正）。
3. **验收（逐条见 §3–§9）**：
   - ② 该靶 ENFE **成对 `53 → 0`**；`[HC-UNHANDLED]` 面 **`462 → 468`**（同趟 A/B，§3）。
   - ③ 导出面：`nm -D --defined-only` **674** == `bin/exports.txt` **674**（vs 改前 673：**逐名 +1、无消失**）。
   - ④ **`PTSGAP=PASS`**（`rc=0`、**零 `SITE-DRIFT`**）；逐处 before→after 见 §5。
   - ⑤ 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）**逐字段成对不变**；四帧 `sha256` **逐字节不变**（`boot b21eb530afd3c66c`；`k23=k24=last=ef3fd6765f18f51b`；`AE(k23,k24)=0`）；`DEFREG` **rc=0**；`REPORTID` **rc=0**。
4. **口径重申（防过读）**：**"该靶 ENFE 归零" ≠ "能力前进"**。`P1-ptsname-result.md` 裁定（现取）：**符号不存在时失败发生在封送阶段 ⇒ 「`ENFE` 归零」本身**不构成任何证据**；`N2` 面（缺符号）≠ 内容面（行为对不对）**。本增量把"**缺符号**"变成"**有符号的诚实拒绝**" ⇒ **帧面一格未动、两页仍未真排版**。**总 `[HC-UNHANDLED]` 仍非零（`462 → 468`）** ⇒ **"计数下降/上升都 ≠ 能力进/退"**（照 `pts-gap-count-check.sh` 件头第 ① 条）。
5. **下一站（具名，防被读成"没做完"）**：现读具名前沿 ＝ **`FsQuerySubtrackDetails`（`416` 次拒绝，`reason=unclaimable-subtrack`，`psub=0x4`）** —— 其**入参是托管句柄**（本侧不可认领）；**唯一可做路径**＝解除 `PRECOND-MANAGED-HANDLE-TABLE`（**托管侧**给 native 一个可反查的句柄表索引）⇒ **超本侧写域**。**本件未做**（§8-7 具名 `NOINFO`）。
6. **⚠️ 主动披露（judgment 分歧，供队长裁）**：`T-A19` §1.2 把本入口预判为「**可做**（仅诚实导出面）」并具名"属下一增量选靶对象"；而 `P1-tail2-next-recon.md` §3.1 的 `T-A6 ②` 立判「**不得把"再写一个拒绝 stub"当进展**」。**本件按前者执行**（理由：本项是 `ENFE`＝**绑定期失败**，不是"已导出的拒绝项再写一遍"；且 `T-A19` §0.5 具名为下一站）。**但现取事实（§1.2／§3）显示：本入口的入参面与出参面**都**本侧无源 ⇒ 本增量**确实不带来能力前进**。⇒ **如实上报，请队长裁定**该形态（"ENFE → 诚实拒绝"的导出）**是否计入下一轮"有源可做"池**。

---

## §1 ① 选靶清单（现取）

### 1.1 分类方法（可复跑）

`[HC-UNHANDLED]` 行的"入口名"＝该异常行**之前最近一条带具名 `entry=` 的 native 台账行**（`[FS_PAGE_GAP]`／`[FSQSTD]`／`[FSQSPL]`）的 `entry=`；`EntryPointNotFoundException` 行直接取 `entry point named '<名>'`。取数件＝**本趟现跑**的改前腿 `build/MilBridge/tests/PtsPagesProbe` 口径的私有副本 `/home/links-dev/tA20-work/evidence-before/app_g1.log`（`sha16=bb086d0ab66c893d`／**7037 行**；**＝现件代 `.so 43ec9cd1bbd96582` 的腿**）。

```
$ python3 /tmp/classify19.py /home/links-dev/tA20-work/evidence-before/app_g1.log
   409  PtsException(-10000)::FsQuerySubtrackDetails
    53  ENFE::FsQueryTextDetails
TOTAL 462
$ grep -c '\[HC-UNHANDLED\]' …/evidence-before/app_g1.log                       # ⇒ 462
$ grep -o '\[FSQSTD\] rc=[-0-9]* reason=[a-z-]*' … | sort | uniq -c
   570 [FSQSTD] rc=0 reason=ok
     2 [FSQSTD] rc=-10000 reason=null-subtrack
   407 [FSQSTD] rc=-10000 reason=unclaimable-subtrack
```
（`407 ＋ 2 = 409` ＝ 具名属 `FsQuerySubtrackDetails` 的 `[HC-UNHANDLED]` 数，**逐值闭合**。）

### 1.2 清单（入口名 ／ 计数 ／ 类别 ／ 有源判定）

| # | 入口名 | 计数 | 类别（现取） | 入参有源？ | **出参有源？** | 判 |
|---|---|---|---|---|---|---|
| 1 | `FsQuerySubtrackDetails` | **409** | `PtsException(-10000)`；`[FSQSTD] reason=unclaimable-subtrack`（**407/409**）＋ `reason=null-subtrack`（**2/409**） | **无**（托管侧传 `psub=0x4`：**小整数＝托管句柄**（`P1-ptsname-result.md` 裁定四十九 (b)：`PtsCache.Linux.cs:523 InitGenericInfo(ptsHost, (IntPtr)(index+1),…)` ⇒ 句柄就是托管表下标）⇒ 与 `wpf_pts_sub_claim` 的"**指针等值**"判据**结构不符**，**只能拒**） | 有（`cParas` 取自 `[SUBENUM]` 枚举计数；`T-A12` 已落） | **不可做**（入参无源；且该入口**已有成功分支**——现取 `[FSQSTD] rc=0` **570** 次 ⇒ 非"缺实现"） |
| 2 | `FsQueryTextDetails` | **53** | `ENFE`（`entry point named 'FsQueryTextDetails'`；`[HC-UNHANDLED]` **现面唯一**的 ENFE 名） | **无**（现场 `para=0x4` —— **与 #1 同形的托管句柄**；`wpf_pts_sub_claim` 不可认领 ⇒ 现取改后判词 `reason=unclaimable-para` **52** 条） | **无**（`FSTEXTDETAILS` 是 `fsktdFull`／`fsktdCached` 判别联合（`Pts.cs:1486-1498`）：`cLines`／`dcpFirst`／`dcpLim`／`cAttachedObjects`／逐行 dvr 等 **需文本行模型**；本侧**没有**该层） | **可做（仅"诚实导出"面）**：**符号不在位＝绑定期失败**（本侧零实现）⇒ 导出后该名**离开缺符号名单**；出参按语义**拒绝**（**绝不写**） |

### 1.3 选靶结论（逐字）

> **取最高计数且"入参/出参有源"者 —— 现读只剩一名"可做" ＝ `FsQueryTextDetails`。**
> 依据三条现取：① 计数最高项（`409`）的**入参无源**（`psub=0x4`＝托管句柄）且**已有成功分支**（`rc=0` 570 次）⇒ 补它**只能改判词**＝零能力前进（`T-A6 ②` 已立判）；② 余下唯一项 `FsQueryTextDetails` 是**`ENFE`** —— 与 #1 不同，本侧**连符号都没有**，导出是**真实变化**（绑定期失败 → 具名运行期拒绝）；③ 它按 `Pts.cs:3750` 声明 ＋ `TextParaClient.cs` 十余处调用**真会撞到**（本趟现取 `[HC-UNHANDLED]` 中 **53/462** 条同名）。
> ⚠️ **射程（照 `P9`：否定性结论必须写清射程）**：本条判"可做"的**射程仅限"缺符号面"** —— **不**主张"出参能算出来"（**出参面本侧无源**，具名 `NOINFO-fsquerytextdetails-out-param-source`）。**入参面**的"无源"射程 ＝ "**本侧不可认领**（托管句柄）"，**不是**"这个东西没有源"。

---

## §2 实现（件:行 ＋ 原文；行号仅本次有效）

> 改动规模：`git diff --numstat src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`80 0`**；`tools/pts-gap-decl.txt` ＝ **`19 1`**。无"顺手优化"。

### 2.1 登记表 ＋ 计数（内容锚：`k_pts_entries[]` 尾；`FsUpdateBottomlessPage` 之后）

- `k_pts_entries[]` 尾追加 `"FsQueryTextDetails"`（该表的**唯一作用**＝让台账/报告给出**名字**，不参与"缺口数"语义 ⇒ `g_pts_calls[]` 对它恒 `0`，只有 `g_pts_seen[]` 会涨）。
- 新增**只读口**：`g_pts_fsqtd_calls`／`_gap`／`_nullout`／`_nullpara`／`_unclaim`／`_unknown_ctx`／`_nomodel`（**判词可分离**）。
- 新增**反腿开关**（默认 `0` ⇒ 主链产物零影响）：`WPF_PTS_FSQTD_FAKE`，`1` ⇒ **假成功**（返 0 ＋ 把出参写成**捏造的** `fsktdCached`）。

### 2.2 `FsQueryTextDetails`（**诚实形态本体**）

```c
int FsQueryTextDetails(void *pfscontext, void *pPara, void *pTextDetails)
{
    g_pts_fsqtd_calls++;
    { int _i = wpf_pts_index("FsQueryTextDetails"); if (_i >= 0) g_pts_seen[_i]++; }
    g_pts_qpd_prev_page = NULL;              /* 下游入口 ⇒ 断开"查询组"毗邻位 */
#if WPF_PTS_FSQTD_FAKE == 1
    if (pTextDetails) ((int *)pTextDetails)[0] = 0;   /* fsktd=fsktdCached（**捏造**） */
    fprintf(stderr, "[FSQTD] rc=0 para=%p out=FAKE-WRITTEN basis=FAKE-UNCHECKED-PARA …\n", pPara);
    return 0;
#else
    const char *reason = NULL;
    wpf_pts_subtrack *obj = NULL;
    if (!pTextDetails)                        { reason = "null-details-out";   … }
    else if (!pPara)                          { reason = "null-para";          … }
    else if (!wpf_pts_sub_claim(pPara, &obj)) { reason = "unclaimable-para";   … }
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext))
                                              { reason = "unknown-ctx";        … }
    else                                      { reason = "no-text-line-model"; … }
    (void)obj; (void)pTextDetails;           /* 认领只用来**分离原因**；出参**零写入** */
    g_pts_fsqtd_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryTextDetails ctx=%p para=%p "
                    "calls=%d gap=%d nullout=%d nullpara=%d unclaim=%d unknown_ctx=%d nomodel=%d "
                    "out=UNWRITTEN bytes=0\n", WPF_PTS_ERR_NOT_IMPLEMENTED, reason, …);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;      /* ← **无成功分支**：本入口恒返非 0 */
#endif
}
```

### 2.3 **为什么语义是"恒拒"**（逐字引上游，防后人改读法）

- 上游声明（`Pts.cs:3750-3753`，逐字）：`FsQueryTextDetails(IntPtr pfsContext, IntPtr pPara, out FSTEXTDETAILS pTextDetails)` —— `pPara` ＝ 文本段落句柄，出参 ＝ 文本细节（判别联合）。
- 调用点（`TextParaClient.cs:55-56`，`ValidateVisual`）：`PTS.Validate(PTS.FsQueryTextDetails(PtsContext.Context, _paraHandle, out textDetails));` ⇒ 失败**立刻抛**（`Pts.cs:40-72` 的 `PTS.Validate`）⇒ 本入口**没有"部分成功"形态**。
- **出参无源（逐字段）**：`FSTEXTDETAILSFULL`（`Pts.cs:1445-1465`）要 `fswdir`／`fsklines`／`cLines`／`cAttachedObjects`／`dcpFirst`／`dcpLim`／投落帽族／逐行 dvr；`FSTEXTDETAILSCACHED`（`:1467-1479`）要 `fsrcPara`＋同族行信息 ⇒ **两者都要文本行模型**。
- ⚠️ **射程边界（如实划界）**：本入口**恒拒**、**不写任何出参** ⇒ 具名 `NOINFO-fsquerytextdetails-out-param-source`（**射程＝"出参面本侧无源"**）。它**不**声称"文本细节已可得"、**不**声称"页会可见变化"。

---

## §3 ② `ENFE`／`[HC-UNHANDLED]` **成对**读数（同趟单变量 A/B）

**成对口径**：同装置（`:231`，`Xvfb 1280x1024x24` ＋ WM）／同腿器（`session_inner.sh sha16=f1a582d9ea9788c9`／`runner sha16=330a90f1f0ac28e4`）／同 `pf`（`1757d610a687777c`）／同 app 目录（私有 `W=/home/links-dev/tA20-work/app`）／**唯一变量 ＝ 权威 `.so`**：

| 腿 | 权威 `.so`（`shim16`） | 证据目录 | `app_g1.log`（`sha16`／行） |
|---|---|---|---|
| **改前** | `43ec9cd1bbd96582` | `/home/links-dev/tA20-work/evidence-before/` | `bb086d0ab66c893d`／`7037` |
| **改后** | `51fe76de3d8613de` | `/home/links-dev/tA20-work/evidence-after/` | `39f1aacb88d52d7f`／`6953` |

| 面 | 改前 | 改后 | 判 |
|---|---|---|---|
| **`entry point named 'FsQueryTextDetails'`**（**靶**） | **`53`** | **`0`** | ✅ **归零** |
| `entry=FsQueryTextDetails`（靶的运行期拒绝行） | `0`（绑定期就炸） | **`52`**（`reason=unclaimable-para`） | ✅ 变（**绑定期失败 → 具名运行期拒绝**） |
| `ENFE` 总数（`entry point named`） | `53` | `0` | **归零** |
| `[HC-UNHANDLED]` 总数 | `462` | `468` | 变（**升 6**；**计数 ≠ 能力**，件头第 ① 条） |
| — 其中有源属 `FsQuerySubtrackDetails` | `409` | `416` | 变（**帧/腿漂移**） |
| — 其中 `ENFE`（靶） | `53` | `0` | ✅ 归零 |
| — 其中 `PtsException` 属靶 | `0` | `52` | 变 |
| `[FSQSTD] rc=0`（同侪成功面） | `570` | `556` | 变（**腿漂移**） |
| `[PTS-UNAVAILABLE]` | `0` | `0` | **不变** |
| `FailFast`／`Unrecoverable`（`FAILLINE`） | `0`／`0` | `0`／`0` | **不变** |

**靶的机读原文（改后，现取首行／尾行）**：
```
[FS_PAGE_GAP] rc=-10000 reason=unclaimable-para entry=FsQueryTextDetails ctx=0x5bdbff02af80 para=0x4 calls=1  gap=1  … out=UNWRITTEN bytes=0
[FS_PAGE_GAP] rc=-10000 reason=unclaimable-para entry=FsQueryTextDetails ctx=0x5bdbff02af80 para=0x4 calls=52 gap=52 … out=UNWRITTEN bytes=0
```
⇒ **靶 `ENFE 53 → 0`**（判据 ② 满足）；`para=0x4` **52/52 同值**（＝**托管句柄**，与同侪 `psub=0x4` **同形**）。
⚠️ **如实划界**：`[HC-UNHANDLED]` **总数升**到 `468`（**帧/腿漂移**；靶自身由"绑定期 53"变成"运行期 52"）；**帧面一格未动**（§6-2）。**两者都不是"排版前进了"**。

---

## §4 ③ 导出面（现取，一次性命令原文）

```
$ nm -D --defined-only bin/libwpfwin32.so | wc -l      # ⇒ 674
$ wc -l < bin/exports.txt                              # ⇒ 674
$ diff /home/links-dev/tA20-work/bak/exports.txt.orig bin/exports.txt
107a108
> FsQueryTextDetails                                   # ⇒ **逐名 +1、无消失**
$ sha256sum bin/libwpfwin32.so | cut -c1-16            # ⇒ 51fe76de3d8613de（416272 B；%a=775）
```

---

## §5 ④ `PTSGAP` 对账 ＋ 复述位随动（**逐处 before→after**）

```
$ bash build/MilBridge/tools/pts-gap-count-check.sh | tail -2        # ⇒ rc=0
PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTrackParaList（具名前沿成立）
PTSGAP=PASS tool=85 dead=11 artifact=1 ops=73 impl=76 so16=51fe76de3d8613de exports=674 root=/home/links-dev/netTest/GitProj/WPFOnLinux
$ grep -c SITE-DRIFT <out>                                           # ⇒ 0（**零 SITE-DRIFT**）
$ shasum 声明行：src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt
# PTSGAP-DECL: tool=85 dead=11 artifact=1 ops=73 impl=76 so16=51fe76de3d8613de exports=674 w66pre16=bf6b683d94549087
```

**计数因果（可复算）**：新增**导出**（非 `wpf_pts_gap` stub）⇒ `check-shim-coverage.py --tier all` 的 `[PresentationNative_cor3.dll]` 缺口名单**少一名** ⇒ `tool 86→85`；`dead=11`／`artifact=1` 未动 ⇒ `ops 74→73`；`stubs`（`grep -cE 'return wpf_pts_gap\("'`）＝ **3 未动** ⇒ `impl = ops + stubs = 76`；`so16`／`exports` 跟权威件换。

| # | 处（件:**内容锚**） | 前 | 后 |
|---|---|---|---|
| 1 | `docs/ROUTES.md`（`TASK-0302 [MVP]` 行） | `**可操作缺口 74 条／实现口径 77 条**` | `**可操作缺口 73 条／实现口径 76 条**` |
| 2 | `docs/ROUTES.md`（`TASK-0720` 行） | `工具口径 **86**` ／ `⇒ **可操作 74**（` ／ `｜**实现口径 77**（` ／ `**现算**：可操作 74 ＋` | `工具口径 **85**` ／ `⇒ **可操作 73**（` ／ `｜**实现口径 76**（` ／ `**现算**：可操作 73 ＋` |
| 3 | `docs/ROUTES.md`（`TASK-0302` 收尾行） | `**可操作 74 条／实现口径 77 条` | `**可操作 73 条／实现口径 76 条` |
| 4 | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（口径分歧行） | `工具口径 **86**` | `工具口径 **85**` |
| 5 | `README.md` | `**可操作 74／实现口径 77**` | `**可操作 73／实现口径 76**` |
| 6 | `build/MilBridge/HANDOFF-NEXT.md` | `**可操作 74／实现口径 77**` | `**可操作 73／实现口径 76**` |
| 7 | `src/WpfGfx.Linux.Native/src/win32_classification.c` | `可操作 74／实现口径 77 条` | `可操作 73／实现口径 76 条` |
| 8 | `docs/unimplemented.md` | `工具报缺 **86**` ／ `⇒ **可操作 74**` | `工具报缺 **85**` ／ `⇒ **可操作 73**` |
| 9 | `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（`# PTSGAP-DECL` 首行 ＋ 尾部 dated 重锚块） | `tool=86 … ops=74 impl=77 so16=43ec9cd1bbd96582 exports=673` | `tool=85 … ops=73 impl=76 so16=51fe76de3d8613de exports=674` |

- **三条硬约束（裁定十一）逐条成立**：① **只改数字 token/就地重锚**（`git diff --numstat` 逐件 `1 1`／`3 3`／`18 1`＋声明行 `1 1` ＝ 合计 `19 1`，**无删句、无动结构**）；② **历史行一字不动**（`PTSGAP_HISTORICAL=n=5` 与改前**同数**；`w66pre16` 锚件 `docs/WAVE66-PREREGISTRATION.md` **未碰**，现取仍 `bf6b683d94549087`）；③ 逐件点名 ＋ 逐处 before→after 见上表。
- ⚠️ **`HANDOFF-NEXT.md` 同句内 `现读 工具口径 100`**：该 token **不在**本牙的抽取域（`one build/MilBridge/HANDOFF-NEXT.md` 只抽 `可操作`／`实现口径`）⇒ **本趟未动**（照 `T-A19` 同形处置），**如实记**：该数是旧值，应另派一次口径收敛（**不在本件写域判定内**）。
- ⚠️ **`docs/ROUTES.md` 同句内 `**9** 个入口`**（在册 `impl−ops` 的旧算法）**本趟之前就已与定义不符**（现算 `impl−ops = 3`）⇒ **不擅改**该历史算术句（与 `T-A4`／`T-A19` 同形制），**具名留待队长**。
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
| `pts_unavail`／`pts_gap` | `0`／`0` | `0`／`0` | **不变** |
| `fatal`／`unh` | `0`／`0` | `0`／`0` | **不变** |
| `failfast`／`unrec`（`FAILLINE`） | `0`／`0` | `0`／`0` | **不变** |
| `guard`（仪器遥测） | `441`／`208` | `447`／`184` | 变（**仅遥测**，非判据） |
| `DEV shim` | `43ec9cd1bbd96582` | `51fe76de3d8613de` | **唯一差异 ＝ 换代** |
| `LEGS_RUNNER` | `PASS requested=2 obtained=2 refused=0` | 同 | **不变** |

**`leg_<k>.env` 逐字（改后）**：
```
LEG k=23 alive=yes app_rc=143 magenta=0 colors=383 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae=0 ink=480000
LEG k=24 alive=yes app_rc=143 magenta=0 colors=383 ns=HandyControlDemo.UserControl.FlowDocumentDemo ae=15386 ink=480000
DEV x_up=yes five_stable=yes shim=51fe76de3d8613de pf=1757d610a687777c
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
REPORTID=PASS files=310 ids=2218 declared=225 glob=build/MilBridge/*report*.md   # rc=0（**本载体在册后复取**；本载体落盘前一次为 files=309／ids=2217）
```

---

## §7 反极性（"该红必红" ＋ "伪值必拒"，**实跑**）

### 7.1 ctypes 夹具（拒绝面／**出参零写入**／反极性；`HARNESS …` 行；只用**已导出**入口）

夹具 `/home/links-dev/tA20-work/harness20.py`（`dlopen` 仓内 `.so`；入口：`CreateDocContext`／`DestroyDocContext`／`FsQueryTextDetails`）。**单变量设计**：`NULL` para 与**伪 para**（`0x4` 现场真值形态／`0xbad`）走**同一条调用**；出参缓冲**先填 `0xAA`** ⇒ **逐字节断言"函数没写过"**。

```
$ python3 harness20.py src/WpfGfx.Linux.Native/bin/libwpfwin32.so main
HARNESS main rej_nullout_rc -10000    # NULL 出参
HARNESS main rej_nullpara_rc -10000   # NULL para
HARNESS main rej_manh4_rc -10000      # 0x4（**现场托管句柄**）
HARNESS main rej_badpara_rc -10000    # 0xbad（伪指针）
HARNESS main rej_badctx_rc -10000     # 未知上下文
HARNESS main out_untouched 1          # ✅ 出参 0xAA 缓冲**逐字节不变**
HARNESS main VERDICT PASS
```
同趟 `stderr` 具名留痕（现取）：
```
[FS_PAGE_GAP] rc=-10000 reason=null-details-out entry=FsQueryTextDetails ctx=0x… para=0x4    calls=1 gap=1 nullout=1 … out=UNWRITTEN bytes=0
[FS_PAGE_GAP] rc=-10000 reason=null-para        entry=FsQueryTextDetails ctx=0x… para=(nil) calls=2 gap=2 nullpara=1 … out=UNWRITTEN bytes=0
[FS_PAGE_GAP] rc=-10000 reason=unclaimable-para entry=FsQueryTextDetails ctx=0x… para=0x4    calls=3 gap=3 unclaim=1 … out=UNWRITTEN bytes=0
[FS_PAGE_GAP] rc=-10000 reason=unclaimable-para entry=FsQueryTextDetails ctx=0x… para=0xbad  calls=4 gap=4 unclaim=2 … out=UNWRITTEN bytes=0
[FS_PAGE_GAP] rc=-10000 reason=unclaimable-para entry=FsQueryTextDetails ctx=0xdead para=0x4 calls=5 gap=5 unclaim=3 … out=UNWRITTEN bytes=0
```

### 7.2 反腿副本（**假成功·不校验 para**；`so16=72fbf9ca7867ced5`，`exports=674`）

| 腿 | `.so sha16` | `rej_manh4_rc`／`rej_badpara_rc`（应当 `-10000`） | `out_untouched`（应当 `1`） | `[FSQTD] basis=` | `VERDICT` |
|---|---|---|---|---|---|
| **正**（主链） | `51fe76de3d8613de` | **`-10000`** ✅ | **`1`** ✅ | `[FS_PAGE_GAP] … out=UNWRITTEN` | **PASS** |
| **反**（假成功） | `72fbf9ca7867ced5` | **`0`** ❌（**红**） | **`0`** ❌（**红**） | `FAKE-UNCHECKED-PARA` | **FAIL**（期望） |

```
$ python3 harness20.py …/tA20-work/copy/libwpfwin32.fake.so fake
HARNESS fake rej_manh4_rc 0           # ← **该红**：不校验入参 ⇒ 伪值 0x4 亦"过关"
HARNESS fake out_untouched 0          # ← **该红**：假腿把出参写脏（与"零写入"互斥）
HARNESS fake VERDICT FAIL
[FSQTD] rc=0 para=0x4 out=FAKE-WRITTEN basis=FAKE-UNCHECKED-PARA …
```
⇒ **"不可认领的 `pPara` 必被拒"＋"出参一字不写"这两条断言真的会红**（可证伪）。

### 7.3 主链未被污染（逐字节）

```
$ cmp /home/links-dev/tA20-work/copy/…（无换件动作）src/WpfGfx.Linux.Native/bin/libwpfwin32.so
⇒ 本趟**未**把权威 `.so` 换出（反腿件建在**仓外** `…/tA20-work/copy/`）⇒ `bin/libwpfwin32.so` 自始至终 ＝ 51fe76de3d8613de
```

### 7.4 ⚠️ **本夹具的射程边界（如实划界）**

- **可测**：五条**拒绝路径** ＋ **出参零写入**（`0xAA` 逐字节）。
- 🔴 **不可测（`NOINFO-HARNESS-CLAIMABLE-PARA`）**：**"认领成功 ⇒ 落 `no-text-line-model`"**这一支 —— 因为本仓**没有导出的"可认领 `pPara` 生产者"**（`wpf_pts_sub_handle` 只在 `FsQueryTrackParaList` 的**探针驱动**路径内产生，`T-A6` 现取该路径缺省**不驱**）。⇒ 该支**在净腿上不可达**（**不是**"它错了"）。**并且**：现场真腿的 `pPara` **恒为 `0x4`**（§3）⇒ 该支**在产品路径上也不可达**；**真实判词恒为 `reason=unclaimable-para`**。

---

## §8 边界 · 纪律 · 主动披露 ／ 具名 `NOINFO`

1. **写域**：仅 `win32_pts.c`（手写源）＋ `tools/pts-gap-decl.txt`（声明行 ＋ dated 注释）＋ `bin/*`（重建刷新，gitignored）＋ 复述位六件（**只改数字 token**）＋ 本载体。**未碰** `verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`build/*.Linux/**`／`docs/**`（除白名单两件）／任何 `.cs`。
2. **同趟 A/B 无双写者风险**：本趟**未**换权威 `.so`（改前腿跑在**改前件**上、改后腿跑在**新件**上，中间只发生"重建"）⇒ 无"临时换件"窗口。反腿 `.so` 建在**仓外** `…/tA20-work/copy/`。`git status` 现取除本席件外只有两项 pre-existing untracked（`build/MilBridge/tasks-tail2/T-A20.md` 与 `…/evidence/arm_A/app_g1.log`）。
3. **模式守恒**：逐件 `%a` 见 §9（**逐件 644／`so` 775**）；`pts-gap-decl.txt` 经 `python3 os.replace`（`temp+rename`）追加并 `chmod` 回原值；备份取在**任何写之前**（`/home/links-dev/tA20-work/bak/**`）。
4. **`DEFREG_DECLDRIFT=1 keys=KD`（如实记，待主控）**：本件改了 `KD`（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的口径分歧行 token）⇒ 已声明表 `build/MilBridge/tools/defect-registry-declared.tsv` 的**路由快照与该件不再一致**。该件**不在本件写域**（`build/MilBridge/tools/**` 黑名单）⇒ 照纪律 15／`D-G129`：**请主控重发 `declared.tsv`**。牙本身 `DEFREG=PASS rc=0`（与 `T-A19` 同形）。
5. **`bin/exports.txt` 与 `bin/libwpfwin32.so` 是 gitignored 件**（`.gitignore:24`）：派单把它们列入写域，本趟确已刷新（`+1` 行／重建），但**它们不入 git** ⇒ 交接必须靠**重建**。如实记，非疏漏。
6. **`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的"口径分歧行"**（`dated` 但**无内容锚**）**照 `T-A13`／`T-A16`／`T-A19` 先例**把 token 同步为 live（`工具口径 **86**` → `**85**`）以使 `PTSGAP=PASS`，**并在此具名重提**：**该行语义上是历史陈述，随动会改史实** —— 请队长裁定"**保值**（加内容锚使其转历史行）vs **随动**（现状）"。
7. **具名 `NOINFO`**：
   - `NOINFO-FSQUERYTEXTDETAILS-OUT-PARAM-SOURCE`（**射程＝出参面**）：`FSTEXTDETAILS` 需**文本行模型**（`cLines`／`dcpFirst`／`dcpLim`／`cAttachedObjects`／逐行 dvr）⇒ **本侧无源** ⇒ 本入口**恒拒**。**不是**"文本细节没有源"（引擎侧回调面见 `P1-ptsname-result.md` 裁定四十九 (a)：`FSIMETHODS` 槽 12 `ObjGetColumnBalancingInfo` 给 `nlines`，但**量种/口径未验** ⇒ 本件**不采用**）。
   - `NOINFO-FSQUERYTEXTDETAILS-IN-PARAM-UNCLAIMABLE`（**射程＝入参面**）：现场 `pPara=0x4` ＝ **托管句柄**（`T-A49(b)`）⇒ 本侧**不可认领**。**不是**"段落句柄没有源"，而是"**本侧没有那条反查表**"（前置 `PRECOND-MANAGED-HANDLE-TABLE`）。
   - `NOINFO-HARNESS-CLAIMABLE-PARA`（**夹具射程**）：无导出生产者 ⇒ "认领成功"支在净腿与产品路径**都不可达**（§7.4）。
   - `NOINFO-DRIVE-PROBE-STATE`：两趟腿均在 `WPF_PTS_DRIVE_PROBE` **缺省**下取 ⇒ 帧面读数**带探针闸状态**；**未**另跑"闸关"腿。
8. **未做**：`git add/commit/push`；未跑整趟 `verify-all`／`static-jaws-check.sh`；未动任何牙本体；未判相位（本件不涉相位）。
9. **帧面冻结令（旁引裁定三十九／四十二）**：本件**不**据任一帧面读数**单向**下判（两趟帧面**完全相同**，只报"逐字节相同"这一结果）。

---

## §9 件级前后对账（现取 `sha16` 前 16 位 ＋ `%a`）

| 件 | 开工（`cp -p` 备份，sha16） | 收尾（现取 sha16） | `%a` | 判 |
|---|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `9b1d30e87ba34c5a` | **`681bd74cd62fc287`**（5257 行） | 644 | `git diff --numstat = 80 0` |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `562dd1833c8a9cd0` | **`f9fa0a25c5ab844d`** | 644 | `19 1`（声明行 1 ＋ dated 重锚注释 18） |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `732b701c2a521220`（673 行） | **`6eb36656f505690e`**（674 行） | 644 | 重建刷新（gitignored） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `43ec9cd1bbd96582`（415928 B） | **`51fe76de3d8613de`**（416272 B） | 775 | 重建产物（gitignored） |
| `docs/ROUTES.md` | `57f5074b7336fdbd` | **`5bc547ba92193594`** | 644 | `3/3` token |
| `README.md` | `d00569e2dca33c76` | **`3299345c41e0c75e`** | 644 | `1/1` |
| `build/MilBridge/HANDOFF-NEXT.md` | `9cfd905c780acb31` | **`56ead33e35aca6bf`** | 644 | `1/1` |
| `src/WpfGfx.Linux.Native/src/win32_classification.c` | `ab5950274d148905` | **`2ab3c2edc10a7a76`** | 644 | `1/1`（**注释**；重建后 `.so` 与"仅注释改动"无关 ⇒ 已验证 `--symbols` 重建产物 `sha16=51fe76de3d8613de`） |
| `docs/unimplemented.md` | `287701f92f4a7d5b` | **`3773d6288a4f519e`** | 644 | `1/1` |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `d499b35635ee363a` | **`93e3f70b7ffdb06e`** | 644 | `1/1` |
| 反腿副本（**仓外**）`…/tA20-work/copy/libwpfwin32.fake.so` | — | `72fbf9ca7867ced5` | — | `-DWPF_PTS_FSQTD_FAKE=1`，**绝不进主链** |

**备份路径**：`/home/links-dev/tA20-work/bak/{win32_pts.c,pts-gap-decl.txt,exports.txt,libwpfwin32.so}.orig` ＋ `bak/recast/*`（复述位六件）。

⚠️ **开工读数的口径（如实记，一处更正）**：本表"开工"栏**一律取 `cp -p` 备份的现取 sha16**。其中 `docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md` 两格（`57f5074b7336fdbd`／`9cfd905c780acb31`）与 `T-A19` 载体 §9 记的"收尾"值（`61b03dbc1123b2f7`／`07051f66d22c46fe`）**不一致** —— 现取 `git show HEAD:<件>` 与备份**逐位相同**（`HEAD=57f5074b7336fdbd`／`9cfd905c780acb31`）⇒ 是 **`T-A19` 载体记录时点与提交后状态之间的差**（非本席所改）。⇒ **本件不照抄他件读数，一律现取**（照 `HANDOFF-NEXT` §7 纪律）。

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
?? build/MilBridge/P1-tail2-next3-impl-report.md             ← **本载体**
?? build/MilBridge/tasks-tail2/T-A20.md                        ← 派单件（非本席所改）
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log  ← **先于本件存在**（非本席所改）
```
⚠️ `src/WpfGfx.Linux.Native/bin/**` **不入 `git status`** —— 该目录在 `.gitignore:24`（`git check-ignore` 现取命中）⇒ `exports.txt`／`.so` 只存在于工作树。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-next3-impl-report.md | sha256sum | cut -c1-16`）= `422f56605dbf6285`
