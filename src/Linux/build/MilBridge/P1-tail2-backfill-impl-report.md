# `P1-tail2` `TASK-0302` · native「查询期文本行回填」（`NATIVE-QUERY-PHASE-TEXT-LINE-BACKFILL`）—— 实现报告（`T-A33`）

- **读时**：`2026-09-30T16:4x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=0ffa69c0355ee92263c53d5d41924fd21e890a7d`（现取，**未换代**）。
- **改前件备份（仓外 `~/tA33-work/bak/`，`cp -p` 取在**任何写之前**）**：
  `win32_pts.c.d0d5f43f.bak`（`d0d5f43f7a09f2b0`／461615 B；＝ `HEAD` 版，与 `T-A31` 载体报告的改后值逐字节相同）／
  `libwpfwin32.so.ac002caa.bak`（`ac002caa324a496f`／430736 B）／
  `exports.txt.c561dda4.bak`（`c561dda4eca311c5`／677 行）／
  另各构建代 `.so` 逐代留档（`.3c631a5c`／`.b808d63e`／`.f38f2556`／`.04f6d354`）。
- **只改**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（回填 ＋ 两处回填暴露的 `FailFast` 守卫）／其登记面 `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（`PTSGAP-DECL` 的 `so16` 重锚 ＋ `T-A33` 记录块）／**复述位现值位**（`README.md`／`docs/ROUTES.md`）／本载体。**未动** `bin/exports.txt`（构建后**逐字节相同**）。
- **黑名单遵守**：未动 `build/*.Linux/**`（生成件）／`build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`；**未跑**整趟 `verify-all`；重活（4 趟构建 ＋ 7 趟腿）全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`；进程只按 PID；禁 `sleep` 轮询；写前 `cp -p` 备份；`temp+rename`；模式守恒。
- **行号纪律**：本件行号**仅本次有效**（内容锚原文一并给出）。
- **口径**：一切读数**本席现取**（`sha256sum`／`grep -c`／`nm`／`diff` ／只读 `python3`+`PIL` 解 PNG/GIF）；**未抄任何既有报告的读数**（引用他人件处逐条标「未独立复算」）。

---

## §0 结论速览（自包含）

1. **实现已落地（`win32_pts.c`，`T-A33` 指定写域）**：按 `T-A32` §4.2 判据 D1–D4 与 `T-A27` 路 (丙) 第 3 步，把**查询期**从本侧**行记录台账**（`wpf_pts_subtrack::fl_line[]`，内容**只**来自 `pfnFormatLine` 真返回值）**回填**四个入口的出参：
   `FsQueryTextDetails`（`FSTEXTDETAILS`／`fsktdFull`）／`FsQueryLineListSingle`（行盒）／`FsQueryLineListComposite`／`FsQueryLineCompositeElementList`。
   **只有台账可用**（`fl_ok ∧ fl_complete ∧ !fl_truncated ∧ fl_nlines>0`）**才写**；否则**逐字保持诚实拒绝**（出参一字不写）。
2. ✅ **产品面首次出内容（本波的核心新事实）**：改后**占位图消失**（`∈ under_construction.gif` 调色板 `129792 px → 0`）＋**内容区首次出现真实像素**（`AE(content, x>240) 0 → 203949`），两页帧 `sha16` **不再相同**。⇒ `T-A32` §4.2 **D4「帧面必须长像素」＝绿**（**不**把空白读成绿）。
3. ✅ **接口面**：`reason=no-text-line-model` **104/111 → 0**；`[HC-UNHANDLED]` **107/111 → 1**（残留 1 条＝`FsQueryTrackParaList` 的 `drive-handles-released(page-destroyed)` 诚实拒绝，**非**本增量缺口）；`PtsException … '-10000'` **107/111 → 1**；`[FSQTD] rc=0` **0 → 6080/3116**（`out=WRITTEN bytes=112`）；`[FSQLL] rc=0` **0 → 1522/781**（`out=WRITTEN bytes=576/432…`）。
4. ✅ **症状门无回归**：`alive=yes app_rc=143 failfast=0 magenta=0 ink=480000 ns=…FlowDocumentDemo`（与改前同）；`colors 383 → 654/636`（**增**，＝内容像素进场）。
5. ✅ **反极性（该红必红）**：同一 `.so` ＋ 显式 `WPF_PTS_FL_DRIVE=0` ⇒ **逐格回改前**（`no-text-line-model 111`／`out=UNWRITTEN bytes=0`／`colors=383`／占位 `129792 px` 回归／`AE(content)=0`／`FailFast 0`）。
6. ⚠️ **本趟同修两处「回填暴露的」不可捕 `FailFast`**（均在**本仓写域** `win32_pts.c`；**不是**回填本身，是回填把布局推进到下一层后**新到达**的）：
   - **(丙) 托管 `+176 CreateParaclient` 只在格式窗内发调**（`WPF_PTS_QTP_INWIN`，缺省 `1`）：实测查询期（后台分页）发调撞 `PtsHost._ptsContext == null` 的 `Invariant.FailFast` ⇒ `app_rc=134`（腿 `legs-tlb`）；
   - **(丁) `FsDestroyPage` 摘表但**不 `free`**（断页记录句柄地址永不复用）：断页记录句柄＝页对象字段地址（`&p->c_paras`）；`free` 后 `calloc` 复用地址 ⇒ 两个 `PageBreakRecord` 撞同一句柄 ⇒ 托管 `PtsContext.OnPageBreakRecordCreated` 的 `Invariant.Assert("Break record already exists.")` ⇒ `app_rc=134`（腿 `legs-tlb3`）。
7. **门禁（④）**：`nm -D --defined-only == exports.txt == 677`（逐名 `diff` 零差异；`exports.txt` 逐字节未变）；`PTSGAP=PASS tool=82 dead=11 artifact=1 ops=70 impl=73 so16=04f6d354b0a71888 exports=677`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`（rc=0）；`REPORTID=PASS`（rc=0，见 §5）。
8. **判决：成功**（回填成立 ∧ 产品面首次出内容 ∧ 症状门无回归 ∧ 反极性逐格回改前）。**如实划界**：`PTS` 本体仍是**降级实现**（页几何／附加对象／合成行等仍具名 `NOINFO`，见 §6）；本增量解的是**查询期文本行模型**这一层。

---

## §1 改动（逐处，`win32_pts.c`）

### 1.1 行记录台账扩列（回填源）

| 面 | 内容 |
|---|---|
| `wpf_pts_subtrack::fl_line[]` | 增 `const void *pbr_in;`／`const void *pbr_out;` —— 造型本行时**传入**的 `pbrlineIn`（第 0 行为 `NULL`）与**产出**的 `ppbrlineOut`（`pfnFormatLine` 真返回值）。 |
| `wpf_pts_format_one_para` 记账处 | `leaf->fl_line[i].pbr_in = pbrin;` ／ `leaf->fl_line[i].pbr_out = ppbr;`（在 `rc!=0`／`dcpLine<=0` 的**早退之后** ⇒ **只在真记账行上写**）。 |

**为什么必须扩它**：托管消费者 `TextParaClient.RenderSimpleLines`（`TextParaClient.cs:3240`）把 `FSLINEDESCRIPTIONSINGLE.pfsbreakreclineclient` **原样**送进 `TextParagraph.FormatLineCore` → `PtsContext.HandleToObject(pbrLineIn)` ⇒ 必须是**同一趟真产出的断行记录句柄**，否则取不到 ⇒ `PtsException`。

### 1.2 查询期回填（四个入口）

出参镜像结构（照上游逐字契约；**只用于尺寸/偏移自证**，`_Static_assert` 钉死）：`wpf_pts_fslds`（=72 B）／`wpf_pts_fsldc`（=48）／`wpf_pts_fslineel`（=88）／`wpf_pts_fstextdetailsfull`（=104）／`wpf_pts_fstextdetails`（=112）。各字段偏移用 `_Static_assert` 逐条钉死（与另写的 C# `Marshal.OffsetOf` 探针**逐值相同**；该探针在仓外 `~/tA33-work/`）。

- **可用性判据（唯一真值来源）**：`wpf_pts_fl_usable(o) ＝ o≠NULL ∧ magic ∧ fl_ok==1 ∧ fl_nlines>0 ∧ fl_complete ∧ !fl_truncated`。**不满足 ⇒ 不许回填**。
- **`FsQueryTextDetails`**：认领成功 ∧ `wpf_pts_fl_usable(obj)` ⇒ `wpf_pts_tlb_fill_details` 写 `FSTEXTDETAILS`（`fsktd=1`／`fsklines=0`／`fLinesComposite=0`／`cLines=fl_nlines`／`dcpFirst=fl_line[0].dcp_first`／`dcpLim=fl_line[n-1].dcp_lim`／`cAttachedObjects=0`／`fUpdateInfoForLinesPresent=0`）⇒ **返 0**；否则走**逐字保留**的诚实拒绝。
- **`FsQueryLineListSingle`**：认领 ∧ 可用 ∧ **计数自洽**（`cLines == obj->fl_nlines`）∧ `rgLineDesc≠NULL` ⇒ 写 `cLines` 条 `FSLINEDESCRIPTIONSINGLE`（`dcpFirst`／`dcpLim`／`pfsbreakreclineclient=pbr_in`／`pfslineclient=台账行句柄`／`urStart=urBBox`／`dur=WPF_PTS_FL_DU`／`vrStart`＝台账逐行 `ascent+descent` 累加／`dvrAscent`／`dvrDescent`／`fTreatedAsFirst=(i==0)`／`fForceBroken`）⇒ `*cLineDesc = cLines`，返 0。
- **`FsQueryLineListComposite`**：同形，写 `FSLINEDESCRIPTIONCOMPOSITE`（本侧一行＝一元素，`pline=台账行句柄`）。
- **`FsQueryLineCompositeElementList`**：`pLine` **按台账行句柄在册认领**（`wpf_pts_tlb_claim_line`；**唯一定位**，歧义／未命中 ⇒ 拒）∧ `cElements==1` ⇒ 写一条 `FSLINEELEMENT` ⇒ 返 0。
- **记账**：`wpf_pts_line_enter()`（`calls++` ＋ 断开"查询组"）从 `wpf_pts_line_reject` 里**提出**，使成功/拒绝两路**共用同一套 `calls=`**（不重复计、不漏计）；新增 `[FS_TLB]` 具名行。

### 1.3 两处「回填暴露的」不可捕 `FailFast` 守卫

- **(丙) `+176 CreateParaclient` 只在格式窗内发调**：新增 `wpf_pts_doc::in_win`（`wpf_pts_drive_probe` 体内置 1／出口置 0）＋ `wpf_pts_qtp_create_safe(d)`（闸变量 `WPF_PTS_QTP_INWIN`，缺省 `1`）。落点两处：`FsQueryTrackParaList` 的 **④ 查询期 `+176` 支**（窗外 ⇒ 具名 `out-of-window-create-paraclient-refused(PtsContext-null-risk)`）与 **③ 换代**（窗外**不换代** ⇒ 沿用窗内造的那一代，防其触发 ④）；`wpf_pts_drive_probe2_oow` 的**第三跳窗外 `+176`**（⇒ 具名 `OUT-OF-WINDOW-REFUSED(PtsContext-null-risk)`）。
  🔴 **判据是"窗"不是"线程"**（本席现取证伪了线程假说：`cur_tid == win_tid` 时照样撞 ⇒ 见 §6-2）。
- **(丁) 断页记录句柄地址永不复用**：`FsDestroyPage` 由 `free(g_pts_fsp_live[i])` 改为**摘表但不 `free`**（页对象内存一次性让渡）；新增只增计数 `g_pts_fsp_retired_n`。**摘表口径与 `g_pts_fsp_live_n` 计数逐字不变** ⇒ 格 8／格 9 自检的 `live_n` 断言不受影响。

### 1.4 只增留痕（诊断）

新增 `[WIN-TID]`（格式窗线程记录）／`[FS_TLB]`（回填面现取读数）；`[FSPARALIST-FILL]`／`[FS_PAGE_GAP] entry=FsQueryTrackParaList`／`[DRIVE-PROBE3-OOW]` 追加 `cur_tid`／`win_tid`／`in_win`／`retired` 字段（**只追加，不改既有字段名与形状**）。

### 1.5 构建（现取）

`bash build-shim.sh --symbols`（经 `heavy-slot`）⇒ **`0 错误`**（既有 2 条 `-W*` 警告与本次无关）；产物 `bin/libwpfwin32.so` ＝ **`04f6d354b0a71888`**（435192 B）；`bin/exports.txt` **逐字节未变**（`c561dda4eca311c5`／677 行）。

---

## §2 成对机读读数（**同一跑器**：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=962fec114b2d0692`；同一显示流程 A 臂 `:231`、`1280x1024x24`；`LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`）

**五件**（`five_pre == five_post`，跑中无漂移）：`libwpfwin32.so=04f6d354b0a71888`（改后）/`ac002caa324a496f`（改前腿）｜`wpfgfx_cor3.so=941e69902d82ef02`／`PresentationCore.dll=e47c4b4521c54cb2`／`PresentationFramework.dll=1757d610a687777c`／`WindowsBase.dll=3886f61b0251140e`。
**装置**：`AUTHORITY … == APPDIR …`；`POSTSHIM: shim=<腿件> pf=1757d610a687777c（== authority ⇒ 读数可归因）`。

| 腿 | `.so` | 闸 | 性质 |
|---|---|---|---|
| `legs-old` | `ac002caa324a496f` | 缺省 | **改前** |
| `legs-polar0` | `04f6d354b0a71888` | **显式 `WPF_PTS_FL_DRIVE=0`** | **反极性** |
| `legs-tlb4` / `legs-tlb4b` | `04f6d354b0a71888` | 缺省 | **改后 ×2 独立样本** |

### 2.1 症状门 ＋ 帧面（逐腿，现取）

| 腿 | `app_rc` | `alive` | `failfast` | `magenta` | `colors` | `ink` | `ns`(k24) | `ae`(k24／k23) | `fr_sha`(k24／k23) |
|---|---|---|---|---|---|---|---|---|---|
| `legs-old` | 143 | yes | 0 | 0 | **383** | 480000 | `…FlowDocumentDemo` | **15386／0** | `ef3fd6765f18f51b`／同 |
| `legs-polar0` | 143 | yes | 0 | 0 | **383** | 480000 | `…FlowDocumentDemo` | **15386／0** | `ef3fd6765f18f51b`／同 |
| `legs-tlb4` | 143 | yes | 0 | 0 | **654** | 480000 | `…FlowDocumentDemo` | **219340／125234** | **`fa7df9222ebb199f`／`10d0b9d54e649c10`** |
| `legs-tlb4b` | 143 | yes | 0 | 0 | **654** | 480000 | `…FlowDocumentDemo` | **219340／125234** | `fa7df9222ebb199f`／`10d0b9d54e649c10` |

`k23` 的 `ns=HandyControlDemo.UserControl.RichTextBoxDemo`（四腿同）。⇒ **症状门无回归；两独立样本逐格相同**（`D6`）。

### 2.2 计数成对（`grep -c`，现取）—— 判据 ②

| 计数 | `old` | `polar0` | `tlb4` | `tlb4b` |
|---|---|---|---|---|
| `[FSQTD] rc=0 reason=ok` | 0 | 0 | **6080** | 3116 |
| `[FSQTD] … out=WRITTEN bytes=112` | 0 | 0 | 6080 | 3116 |
| `[FSQLL] rc=0 reason=ok` | 0 | 0 | **1522** | 781 |
| `[FSQLL] … out=WRITTEN` | 0 | 0 | 1522 | 781 |
| `reason=no-text-line-model` | **104** | **111** | **0** | **0** |
| `[FS_PAGE_GAP] … out=UNWRITTEN bytes=0` | 107 | 111 | **0** | **0** |
| `[HC-UNHANDLED]` | **107** | **111** | **1** | **1** |
| `PtsException …'-10000'` | 107 | 111 | **1** | **1** |
| `[FORMATLINE-LINE]` | 42 | 0 | 42 | 42 |
| `[FORMATLINE] … v=LINES-RECORDED` | 7 | 0 | 7 | 7 |
| `FailFast` | 0 | 0 | **0** | **0** |

**残留 1 条 `[HC-UNHANDLED]` 的实名**（现取，`legs-tlb4:41458`）：`[FS_PAGE_GAP] rc=-10000 reason=drive-handles-released(page-destroyed) entry=FsQueryTrackParaList` ⇒ 是 `T-A17` 的**诚实拒绝**（页销毁后拒驱），**不是**回填缺口。

**逐字样本（`legs-tlb4`）**：
```
[FSQTD] rc=0 reason=ok entry=FsQueryTextDetails ctx=0x5a6ec90020d0 parah=0x5a6ec8547d94 calls=1 ok=1 gap=0 nomodel=0 fsktd=1 cLines=8 dcpFirst=0 dcpLim=956 fl_ok=1 out=WRITTEN bytes=112 src=ledger:fl_line[](pfnFormatLine+fsflres-end)
[FS_TLB] entry=FsQueryTextDetails parah=0x5a6ec8547d94 cLines=8 dcpFirst=0 dcpLim=956 fl_calls=8 fl_ok=1 complete=1 truncated=0 NOINFO=fsgeometry-layout(vrStart=self-accum),attached-objects(none)
[FSQLL] rc=0 reason=ok entry=FsQueryLineListSingle ctx=0x5a6ec90020d0 parah=0x5a6ec8547d94 cLines=8 calls=1 ok=1 gap=0 nomodel=0 fl_ok=1 out=WRITTEN bytes=576 src=ledger:fl_line[]←pfnFormatLine
```
对照（`legs-old:1`，逐字）：`[FS_PAGE_GAP] rc=-10000 reason=no-text-line-model entry=FsQueryTextDetails ctx=… para=… calls=1 gap=1 … nomodel=1 out=UNWRITTEN bytes=0`。

---

## §3 帧面（**本席自算**，只读 PNG/GIF；判据 ③）

| 腿 | `k24` ∈ `under_construction.gif` 调色板 | `k23` 同 | `AE(content, x>240)` k24 | k23 |
|---|---|---|---|---|
| `legs-old` | **129792 px** | **129792 px** | **0** | **0** |
| `legs-polar0` | **129792 px** | **129792 px** | **0** | **0** |
| `legs-tlb4` | **0** | **0** | **203949** | **174476** |
| `legs-tlb4b` | **0** | **0** | **203949** | **174476** |

- **占位图判据**（承 `T-A32` §2.3，本席独立复算）：`boot.png` 两态均有 `129792 px ∈ under_construction.gif` 调色板；**改后 k24/k23 ＝ 0** ⇒ **占位消失**。
- **AE(content)**：`x>240` 区域内 `boot→k24` 差异 `203949 px`（`k23` `174476`）；改前/反极性**恰 0**。
- **两页身份**：改前 `k23 ≡ k24`（同 `sha16`）；改后 `fa7df9222ebb199f ≠ 10d0b9d54e649c10` ⇒ **两页画的是各自内容**。
- ⇒ **判据 ③「内容区是否首次出现非空态像素」＝ 是（绿）**；**未**把空白读成绿（改前/反极性恰为 0）。

---

## §4 反极性（**同一构建 ＋ 同一跑器 ＋ 同一 `.so`**，只差**一个 env**：`WPF_PTS_FL_DRIVE`）

| 判据 | 改后（缺省） | **显式 `=0`（`polar0`）** | 改前（`old`） |
|---|---|---|---|
| `[FORMATLINE]` 窗级 | `gate=1 … v=DRIVEN`、`[FORMATLINE-LINE]=42` | **`gate=0 v=GATE-OFF`、`[FORMATLINE-LINE]=0`**（**回改前**） | `[FORMATLINE-LINE]=42`（改前 .so 同驱） |
| `reason=no-text-line-model` | **0** | **111** | 104 |
| `[HC-UNHANDLED]` | **1** | **111** | 107 |
| `[FSQTD] rc=0` | **6080** | **0** | 0 |
| `colors`／`ae(k24)` | **654**／**219340** | **383**／**15386** | 383／15386 |
| 占位 px／`AE(content)` | **0**／**203949** | **129792**／**0** | 129792／`AE=0` |
| 症状门六项 | `143/yes/0/0/654/480000` | `143/yes/0/0/383/480000` | 同 `polar0` |

⇒ **反极性两证**：① **机械面** —— 只加 `WPF_PTS_FL_DRIVE=0`（同一 `.so`），回填面由 `6080 → 0`、`no-text-line-model` 由 `0 → 111`、帧面由"出内容"由 `→ 占位回归`；② **判词面** —— `polar0` 与改前件 `old` 的**帧面与症状门逐格相同**。⇒「**台账空 ⟺ 回填不发生**」钉死。

**另一次反极（回填暴露的守门，如实记）**：`WPF_PTS_QTP_INWIN=0` ⇒ **回落改前**（查询期照发 `+176`）⇒ **`app_rc=134`（`FailFast`）** —— 这正是 (丙) 守卫**该红必红**的证明（另见 §6-2 的中间腿）。

---

## §5 验收逐条（对 `T-A33` ③）

- **① `A32 ③` 的 4 条判据逐条现取 ＋ 每条带反极性**：
  - **D1 零假值／出参纪律**：拒绝路径 `out=UNWRITTEN bytes=0`（`old/polar0`）；成功路径 `out=WRITTEN bytes=112/576/432…`（`tlb4*`）。**反极**：`polar0` ⇒ 全部回 `out=UNWRITTEN bytes=0`（111 条）。
  - **D2 永不假成功（账守恒）**：`rc=0` **仅当** `wpf_pts_fl_usable`（`fl_ok ∧ complete ∧ !truncated ∧ nlines>0`）；`cLines`／`dcpFirst`／`dcpLim` 逐项取自台账（现取：`cLines=8 dcpFirst=0 dcpLim=956` ↔ 台账 `[FORMATLINE] para=0x8 nlines=8 dcp_sum=956 complete=1`），末行 `fsflres=2` 收束。**反极**：闸关 ⇒ 台账空 ⇒ **恒拒**（无常量、无 `0`）。
  - **D3 失败必留痕 ＋ 计数恰涨 1**：任何拒绝**必**打具名 `[FS_PAGE_GAP]`（`entry=`／`reason=`／`calls/ok/gap/nomodel`）且 `gap` 恰涨 1（现取：`old` 的 `calls=1 gap=1 … nomodel=1` 逐条）。**反极**：`polar0` 的 `nomodel=` 由 1 递增到 111。
  - **D4 帧面必须长像素**：§3 —— 占位 `129792 → 0`、`AE(content) 0 → 203949`。**反极**：`polar0` 恰回 `129792／0`。
- **② 计数成对 ＋ `FsQueryTextDetails` `rc`／`out` 状态成对**：§2.2（`no-text-line-model` 104/111→0；`[HC-UNHANDLED]` 107/111→1；`'-10000'` 107/111→1；`[FSQTD] rc=0 out=WRITTEN` 0→6080）。
- **③ 帧面成对（首次非空态像素）**：§3（**绿**；两页帧 `sha16` 分离）。
- **④ 导出面 `nm==exports`；`PTSGAP=PASS`；`DEFREG`/`REPORTID` rc=0**：
  - `nm -D --defined-only` 行数 **677** == `exports.txt` 行数 **677**（逐名 `diff` 零差异；`exports.txt` `c561dda4eca311c5` **逐字节未变**）；
  - `PTSGAP=PASS tool=82 dead=11 artifact=1 ops=70 impl=73 so16=04f6d354b0a71888 exports=677`（rc=0；`PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTrackParaList`）；
  - `DEFREG=PASS declared=225 route_ids=225`（rc=0，`DECLDRIFT=0 keys=-`）；
  - `REPORTID=PASS`（rc=0；**本载体落地后**现取见 §6-7）。
- **⑤ 症状门成对**：§2.1（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns` 逐格现取；改后仅 `colors` **增**）。

---

## §6 边界 · `NOINFO` · 主动披露

1. **改动面（`git status --porcelain` 现取）**：`M README.md`／`M docs/ROUTES.md`／`M build/MilBridge/HANDOFF-NEXT.md`／`M src/WpfGfx.Linux.Native/src/win32_pts.c`／`M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` ＋ **本载体**（untracked）＋ **先于本件**的两项 untracked（`build/MilBridge/tasks-tail2/T-A33.md`／`build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`）＋ `T-A32` 件。`bin/libwpfwin32.so`／`bin/exports.txt` 是**构建生成件**（`git ls-files` 现取 0 ⇒ 不入库），不计入手改面。
2. 🔴 **中间腿（**如实披露**，防被读成"一次成型"）**：本席共跑 **7 趟腿 / 4 趟构建**，**三处新前沿逐个暴露并修复**（每步都从"现取读数"推进，**不是**猜测）：
   - `legs-tlb`（回填首版）：`app_rc=134`，崩于后台分页 `FsQueryTrackParaList → CreateParaclient → PtsHost.get_PtsContext()`。
   - `legs-tlb-diag`／`legs-tlb-gon`：**证伪"跨线程"假说**（`WIN-TID` 与 `[FSPARALIST-FILL] cur_tid == win_tid` 逐条现取；线程闸开了也照崩）⇒ 判据改为**"窗"**。
   - `legs-tlb2`（首版窗闸＝**毯式前置**）：**过度拒绝** —— `FsQueryTrackParaList` 1115 次全拒 ⇒ `FsQueryTextDetails` **一次都没被调**（`FSQTD=0`）⇒ 改小为**只闸两处 `+176` 发调**。
   - `legs-tlb3`：崩于 `PtsContext.OnPageBreakRecordCreated` 的 `"Break record already exists."`（断页记录句柄地址复用）⇒ 落 (丁)。
   - `legs-tlb4`／`legs-tlb4b`：✅ 成（本报告读数）。
3. **`NOINFO`（逐条给"消掉需要什么"）**：
   - `NOINFO-FSGEOMETRY-LAYOUT`（承 `T-A28`／`T-A31`，**未消**）：行盒里 `dur` ＝造型时用的页宽（`WPF_PTS_FL_DU＝180000`，**本侧约定**）、`vrStart` ＝**本侧按台账 `ascent+descent` 累加**（**非**上游 ABI 几何）⇒ `[FS_TLB]` 行内具名；消掉需一条**真机**（Windows）对拍，或在驱动点直插上游几何入站源。
   - `NOINFO-TLB-ATTACHED-OBJECTS`：`FSTEXTDETAILSFULL.cAttachedObjects` 恒 `0`（本侧**无** attached-object／floater／figure 台账）⇒ 含悬浮/图片的段落其附加对象**不产出**（不冒充"没有"）。
   - `NOINFO-TLB-RUNS`：本侧**不**产 `TextRun`／`GlyphRun`（行盒只给几何与断行记录；**字形由托管在消费者侧重排**所得，见 §1.1 的 `FormatLineCore` 链）⇒ 不在本入口的射程。
   - `NOINFO-LEDGER-PFSLINE-DEREF`（承 `T-A32` §5）：台账 `pfsline` 是**行句柄（小值）**，本侧**只当不透明标识**用于 `pLine` 认领（`wpf_pts_tlb_claim_line` 按**值唯一定位**）；**不** deref。
   - `NOINFO-QTP-PARACLIENT-REUSE`（新读出）：`FsQueryTrackParaList` 的 `pfsparaclient` 仍由**窗内**造出的一代**复用**（窗外不换代）⇒ 多段共用同一客户端句柄（承 `t160` W-1/W-2 实验的既存口径；本增量不改其语义，只去掉**窗外**发调）。
   - `NOINFO-LS-PROVENANCE-BRIDGE`／`NOINFO-HOSTLINE-NATIVE-BACKFILL-SEMANTICS`（承 `T-A27`／`T-A28`）：真机 `FsQueryTextDetails`／三入口"从行记录回填"的**确切字段映射**仍**未实测**；本增量给的是**本侧约定下自洽**的实现（`[FS_TLB]` 具名）。
4. **未做的（防被读宽）**：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；未动任何牙本体；未跑既有 parity 语料；**未**新增任何 `D-G<digits>` 登记编号。
5. **`(丁)` 的代价（如实登记）**：页对象内存**一次性让渡** ⇒ 每页约 `sizeof(wpf_pts_fsp)` 字节／**进程生命周期**（摘表口径不变 ⇒ `live_n` 不变）。**理由**：断页记录句柄＝页字段地址是**在册的"字段级诚实性"口径**（格 9 自检 `wpf_pts_track_owned(bra)` 要求），**不能**改成自造常量；让地址不复用是**在不动该口径**下消掉该 `FailFast` 的唯一最小改动。
6. **正文复述位随动面（现取）**：`README.md`（"已知问题"表 ①② 的 dated 更正，**只增不改**）／`docs/ROUTES.md`（§15x `P1-tail2` 树内的 `T-A33` dated 落地行，**只增不改**）／`build/MilBridge/HANDOFF-NEXT.md`（§3 队列的 `T-A33` dated 对齐行 ＋ `cell=#1` 输入指纹的"机器值契约更正"行——现取旧值 `5f2da4c9…`／新值 `df92d468…`；**只增不改**）⇒ `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`。**未动**：`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c` —— 现取：该三件**不含**本增量会改写的**现值位**（前者现取 `可操作 70／实现口径 73` **未变**；后两件 `grep -n "no-text-line-model|未绘出内容|占位"` 命中处均为**带代际指认的历史行**）⇒ `PTSGAP` 现取 **`PASS`（零 `SITE-DRIFT`）**。
7. **`REPORTID` 计数（**本载体落地后现取**）**：`REPORTID=PASS files=317 ids=2229 declared=225`（rc=0；`glob=build/MilBridge/*report*.md`）。本载体落地前 `files=316`（＝ `T-A31` 现取值）⇒ **+1** 即本件；`ids` 的增量**全部**来自本件对既有已声明编号（`D-G70`／`D-G56`／`D-G103`／`D-G188`）的引用（**不新增**登记编号）。
8. **侧效（如实披露，**未进仓**）**：`~/tA33-work/`（`bak/` 改前件 ＋ **7 趟腿**证据 ＋ 跑腿/汇总脚本 ＋ 仓外 C# 布局探针）；`~/w67-work/app` 现**已同步回改后权威件**（`SYNC-APPLOCAL=PASS drift=0`）。改前腿用**副本还原**：跑前把权威 `.so` 换为 `ac002caa324a496f`、跑后**逐字节复算换回** `04f6d354b0a71888`（`AUTH_AFTER=04f6d354b0a71888` 逐腿现取）。
9. **前提边界（写死）**：`PTS` 本体（`FsCreatePage*`／页几何／附加对象／合成行）仍是**占位降级**；本增量解的是**查询期"文本行模型"回填**这一层 ⇒ 帧面从"占位"变"有内容"**不等于**"PTS 真实现"（旧口径"两页未绘出内容"在**本代**已不成立，但 `TASK-0302` 长线**仍开**）。
SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-backfill-impl-report.md | sha256sum | cut -c1-16`）= `04421cf0fcbe68c0`
