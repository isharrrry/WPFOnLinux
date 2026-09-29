# P1-W44 · `FsCreatePageBottomless`（＋`FsCreatePageFinite` 是否同趟）预登记判据 —— 域定位／签名语义／诚实边界／按 `N1–N4` 立判据

> **本件是判据件（先写），不是实现件**：本件**不做**实现、**不构建**、**不跑腿**、**不占显示位**，供随后的**实现件**与**独立复核件**当契约用。
> **一切读数由我现取**（命令与输出原样贴出）；**未引任何既有报告当证据**（`P1-realized-criteria-report.md` 只作**判据口径引用**（`N1–N4` 的定义），其**读数一条未抄**；`t119` 的载体只作**任务来源**）。
> **边界（硬）**：只读仓树；唯一写入 ＝ 本件；**未** `dotnet build`、**未**跑腿、**未**占显示位、**未**跑整趟门禁、**未** `git add/commit/push`；未改任何判据件／产品件／装置件／`ROUTES.md`／`HANDOFF-NEXT.md`／`tools/**`／`src/**`。
> **读取时刻**：`ts=2026-09-29T11:27:58.038+0800`（起点）→ `2026-09-29T11:29:08.243+0800`（末取）。

---

## §0 快照与现取读数

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | **`aa7a6d9`**（`docs(#81): t118 N1-N4 落成可执行判据 + 截图同趟自证要件 + 新定靶口径 + 相位翻转包入账`） | `git log --oneline -6` |
| 工作树 | 16 项（`M` 10 ＋ `??` 6）—— **全属他人**（`t119` 那趟腿证据 ＋ `P1-realized-probe-report.md` ＋ `arm_A/**` ＋ `src/tests/`） | `git status --porcelain` |
| 导出面 | `nm … \| grep -c .` ＝ **572** ＝ `wc -l …/exports.txt` ＝ **572** | `nm`／`wc -l` |
| 权威 `.so` | `a131ea4e6f5cc4f5`；`src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ `ec5c877c897d2b7f` | `sha256sum` |
| **ENFE 面（`N2`）** | `grep -c 'HC-UNHANDLED'` ＝ **1152**；按入口名：**1151×`FsCreatePageBottomless`**、**1×`FsCreatePageFinite`**；异常族：**1152 全 `EntryPointNotFoundException`**；`nm` 里 `^Fs` 命中 **0** | `grep -c`／`grep -o … \| sort \| uniq -c` |
| 两页症状（在册腿，`clicks=[23,24]`） | `leg_23.env`（`70b5a72f1be9feae`）：`LEG k=23 alive=yes app_rc=143 magenta=0 colors=384 ns=…RichTextBoxDemo ae=15385 ink=480000`｜`leg_24.env`（`4f99a32ceb0b4c44`）：`… k=24 … colors=384 ns=…FlowDocumentDemo ae=0 ink=480000`｜两腿 `NAMED managed_unavail=0 err=- native_gap=0 native_err=-`｜两腿 `DEV … shim=a131ea4e6f5cc4f5 pf=2988f5154ecac5dd`｜两腿新增 `FAILLINE k=… failfast=0 unrec=0 src=app_g1.log:FailFast\|Unrecoverable` | `cat`／`sha256sum` |
| 帧面（**`N1`／`N3`**） | `k23.png` ＝ `k24.png` ＝ `last.png` ＝ **`1a76488aa4a790b3`**（各 189742 B）⇒ **去重计数 ＝ 1**；`boot.png` ＝ `b21eb530afd3c66c`；`shotstat` 现跑：`boot 386/0/480000`、`k23 384/0/480000`、`k24 384/0/480000`、`last 384/0/480000`（`colors/magenta/ink`） | `sha256sum`／现跑 |
| **`AE` 面** | `compare -metric AE k23.png k24.png null:` ⇒ **`0`**（rc=0）；`compare -metric AE boot.png k24.png null:` ⇒ **`15385`**（rc=1） | 现跑 |
| 会话面板 | `GROUP 1 arm=A clicks=[23,24] 11:25:21`｜`shim_sha16=a131ea4e6f5cc4f5 pf_sha16=2988f5154ecac5dd`｜`CLICK k=23 … AE=15385 … ns_last=…RichTextBoxDemo`｜`CLICK k=24 … AE=0 … ns_last=…FlowDocumentDemo`｜`APP_RC=143` | `grep`（`session.txt`，`31e2884bcf85e101`） |
| 台账面 | `^PTS_GAP entry=` ＝ **0**；`PTS-UNAVAILABLE` ＝ **0**；`Invariant.FailFast` ＝ **0** | `grep -c` |
| 三格 | `PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=87 so16=a131ea4e6f5cc4f5 exports=572`；`PTSGAP_FRONTIER before=LoCreateContext@3 after=@0 carrier_sha16=191ec68127c588de` | 现跑 |
| 守卫 | `rc=1`；`PTS_GUARD=FAIL legs=2/2 fails=leg24/leg23-placeholder-missing(magenta=0<20000),leg24/leg23-named-line,native-ledger-absent(PTS_GAP n=0) … diag=leg24-colors-out-of-band=384,leg24-AE=0,leg23-colors-out-of-band=384 direction=in-file phase=degraded` | 现跑 |
| 覆盖面 A（`fp_inputs()`） | 活清单 **234** 件（现算） | 现算（§1.4） |
| 覆盖面 B（`ARTIFACT-SRC-FP`） | 三工程现跑：`PresentationCore fp=2f3e458da268e872 n=1374`／`WindowsBase fp=d8e289bb176fed09 n=327`／`PresentationFramework fp=611e5304aa3dcb6b n=1363` | 现跑 |

✅ **本趟截图**同趟三格**成立**（照 `P1-realized-criteria-report.md` §2 的要件）：`shotstat(k24.png)` ＝ **`colors=384 magenta=0 ink=480000`** ＝ `leg_24.env` 的 `colors=384 … magenta=0 … ink=480000` ＝ `session.txt` 帧行 `colors=384 magenta=0 total=1310720 ink=480000` ⇒ **三处逐格相等**，且两腿 `DEV … shim=a131ea4e6f5cc4f5` ＝ 现盘 `.so`。

---

## §1 ① 域定位（本件第一产出）

### 1.1 上游声明面（现取原文）

```
upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:3106
        // ------------------------------------------------------------------
        // fscrpage.h
        // ------------------------------------------------------------------
3109:        [DllImport(DllImport.PresentationNative)]
3110:        internal static extern int FsCreatePageFinite(
3111:            IntPtr pfscontext,                  // IN:  ptr to FS context
3112:            IntPtr pfsBRPageStart,              // IN:  ptr to brk record of prev. page
3113:            IntPtr fsnmSectStart,               // IN:  name of the section to start from, if pointer to break rec is NULL
3114:            out FSFMTR pfsfmtrOut,              // OUT: formatting result
3115:            out IntPtr ppfsPageOut,             // OUT: ptr to page, opaque to client
3116:            out IntPtr ppfsBRPageOut);          // OUT: break record of the page
…
3127:        [DllImport(DllImport.PresentationNative)]
3128:        internal static extern int FsCreatePageBottomless(
3129:            IntPtr pfscontext,                  // IN:  ptr to FS context
3130:            IntPtr fsnmsect,                    // IN:  name of the section to start from
3131:            out FSFMTRBL pfsfmtrbl,             // OUT: formatting result
3132:            out IntPtr ppfspage);               // OUT: ptr to page, opaque to client
```
**这一族有多大（现取）**：`check-shim-coverage.py --tier mapped` 的 `[PresentationNative_cor3.dll] 96 条` 里 **`Fs*` ＝ 66 条**（明细行逐条带声明位，例如 `… FsCreatePageBottomless  探测 FsCreatePageBottomless/FsCreatePageBottomlessA  src/…/PtsHost/Pts.cs:3127`、`… FsCreatePageFinite … Pts.cs:3109`）。

### 1.2 `DllImport` 的模块名 → **它该由谁提供**（现取，三跳）

| 跳 | 现取原文 | 结论 |
|---|---|---|
| ① 属性实参是什么 | `Pts.cs:25 using DllImport = MS.Internal.PresentationFramework.DllImport;` ＋ `[DllImport(DllImport.PresentationNative)]` | 模块名常量在 `MS.Internal.PresentationFramework.DllImport` |
| ② 该常量是什么 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/Shared/RefAssemblyAttrs.cs:69 internal const string PresentationNative = $"PresentationNative{BuildInfo.WCP_VERSION_SUFFIX}.dll";`（另见 `Shared/MS/Win32/ExternDll.cs:34 public const string PresentationNativeDll = "PresentationNative_cor3.dll";`） | 运行期名 ＝ **`PresentationNative_cor3.dll`**（与实测异常文本里的 `in shared library 'PresentationNative_cor3.dll'` **逐字相符**） |
| ③ 本移植上这个名字被谁接手 | `build/shims/Win32ShimResolver.cs:60 internal const string ShimFileName = "libwpfwin32.so";` ＋ `:92` 的映射表里含 **`"PresentationNative_cor3.dll"`** | ⇒ **`PresentationNative_cor3.dll` → `libwpfwin32.so`** |

**⇒ 域判定（写死）：本步与前三步（`CreateDocContext`／LS 族）是**同一个域** —— **native shim `src/WpfGfx.Linux.Native/**`**，**不是** managed 侧。**
**现取旁证（三条，独立）**：
1. `nm -D --defined-only …/libwpfwin32.so | awk '{print $3}' | grep -c '^Fs'` ⇒ **0**；
2. `grep -rn 'FsCreatePage\|FsDestroyPage' src/` ⇒ **0 命中** ⇒ **本地一件都没有**；
3. 该 shim 的构建源清单现取：`src/WpfGfx.Linux.Native/build-shim.sh:34 SRCS=(src/win32_core.c src/win32_msg.c src/win32_x11.c src/win32_misc.c src/win32_exports.c src/win32_unicode_tables.c src/win32_classification.c src/win32_oem.c src/win32_gdiplus.c src/win32_pts.c)` ⇒ `Fs*` 若实现，**要么进 `win32_pts.c`，要么新增 `.c` 并登记进这一行**。

⚠️ **一个必须点名的坑**：**`build-shim.sh` 本身不在 `fp_inputs()` 覆盖面内**（现取 `in_fp=0`，见 §1.4）⇒ **"新增了一个 `.c` 却忘了登记 `SRCS`"这件事，`inputs_fp` 上完全看不见**（症状是"源在库里、符号不在 `.so` 里"）。判据必须自带这一格（C1③）。

### 1.3 拟改件清单（＋两面覆盖面）

**覆盖面 A ＝ `fp_inputs()`**（现取命令，纯读：把该函数末段的 `xargs sha256sum …` 换成 `cat`，只写 `/tmp`）：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux
sed -n '/^fp_inputs()/,/^}/p' build/close-wave.sh > /tmp/t121_fpfn_raw.sh
python3 - <<'PY'
src=open('/tmp/t121_fpfn_raw.sh',encoding='utf-8').read()
assert 'xargs sha256sum | sha256sum' in src
open('/tmp/t121_fpfn.sh','w',encoding='utf-8').write(src.replace("xargs sha256sum | sha256sum | cut -d' ' -f1","cat"))
PY
bash -c 'source /tmp/t121_fpfn.sh; fp_inputs' | LC_ALL=C sort > /tmp/t121_fp_list.txt; wc -l < /tmp/t121_fp_list.txt
```
⇒ **`n=234`**（`rc=0`）。**覆盖面 B**：`python3 build/artifact-src-fp.py`（无参）／`--list PresentationFramework`。

| # | 拟改件 | 角色 | `fp_inputs()` | `ARTIFACT-SRC-FP` |
|---|---|---|---|---|
| **M1** | `src/WpfGfx.Linux.Native/src/win32_pts.c`（现 sha16 `ec5c877c897d2b7f`） | **首选**：`Fs*` 页族新段落放这里（与既有 PTS 桩件同文件，台账/自检机制直接可用） | **在（1）**（`src/WpfGfx.Linux.Native/**/*.{c,h}` 那行） | **不在**（三工程 src 面都不收 `src/WpfGfx.Linux.Native/**`） |
| **M2** | `src/WpfGfx.Linux.Native/src/win32_page.c`（**新件**，若选分层） | 备选：新 `.c` | **在**（同一条 `find`，`*.c`） | 不在 |
| **M3** | `src/WpfGfx.Linux.Native/build-shim.sh:34`（`SRCS=(…)`） | **M2 的登记处**（漏改 ⇒ 符号不进 `.so`） | **不在（0）** | 不在 |
| **M4** | `build/shims/Win32ShimResolver.cs`（现 `125cfaa3c9851cfd` 为 `PresentationCore` 侧同名件之值；本件只读它确认映射，**不主张改它**） | **通常不改**（映射已在） | **在（1）** | —— |
| **M5** | `upstream/wpf/…/PtsHost/Pts.cs`（`1a8575a18767a956`） | **不改**（声明已在；`fserr`/`ValidateAndTrace` 语义是上游） | **不在（0）** | **在**（PF 面 `--list PresentationFramework:258`，sha 与直取逐位相同） |
| **M6** | `upstream/wpf/…/PtsHost/PtsPage.cs` | **不改**（调用点；其"失败置零 ＋ `ValidateAndTrace`"是**上游语义**） | **不在（0）** | **在**（PF 面） |
| **M7** | `build/MilBridge/tests/PtsPagesProbe/evidence/**`（腿证据） | 装置产物 | **在（1）**（`#71` 那 20 件显式名单） | —— |

⇒ **覆盖面结论（写死）**：本步**改的是 native `src/**`** ⇒ **移动 `inputs_fp`**（必须排在 `IN_FP_0` 采样之前，与 W8 前几步同款流程代价）；**M3（`SRCS`）在覆盖面之外** ⇒ 判据自带 C1③ 那一格。**M5／M6 属上游、本步不动**（动了就是越域，且会让 PF 面 `ARTIFACT_SRC_FP` 位移）。

---

## §2 ② 签名与语义

### 2.1 参数表与返回类型（现取原文）

```
FsCreatePageBottomless  （Pts.cs:3127-3132）
    int FsCreatePageBottomless(IntPtr pfscontext, IntPtr fsnmsect,
                               out FSFMTRBL pfsfmtrbl, out IntPtr ppfspage)
        pfscontext  IN  ptr to FS context（＝ CreateDocContext 那一步落下的上下文句柄）
        fsnmsect    IN  name of the section to start from
        pfsfmtrbl   OUT formatting result，**枚举** FSFMTRBL
        ppfspage    OUT ptr to page, opaque to client
FsCreatePageFinite      （Pts.cs:3109-3116）
    int FsCreatePageFinite(IntPtr pfscontext, IntPtr pfsBRPageStart, IntPtr fsnmSectStart,
                           out FSFMTR pfsfmtrOut, out IntPtr ppfsPageOut, out IntPtr ppfsBRPageOut)
```
**两个出参类型不一样（现取，直接决定"最小可辩护实现"的形状）**：
```
Pts.cs:1121  internal enum FSFMTRKSTOP : int { fmtrGoalReached = 0, fmtrBrokenOutOfSpace = 1, … }
Pts.cs:1141  internal struct FSFMTR { internal FSFMTRKSTOP kstop; internal int fContainsItemThatStoppedBeforeFootnote; internal int fForcedProgress; }
Pts.cs:1147  internal enum FSFMTRBL : int { fmtrblGoalReached = 0, fmtrblCollision = 1, fmtrblInterrupted = 2 }
```
⇒ `FSFMTRBL` 是 **`int` 枚举**（4 字节出参）；**`FSFMTR` 是 `struct`**（3 个 `int` 宽的量：枚举＋2×`int`）。**返回码 0 ＝ 成功**（`Pts.cs:422 internal const int fserrNone = tserrNone;`／`:428 internal const int tserrNone = 0;`）。

### 2.2 调用点与**两种**失败后果（本件的关键发现）

**调用点（各只此一处）**：`PtsPage.cs:295`（在 `internal void CreateBottomlessPage()`，方法起于 `:280`）／`PtsPage.cs:397`（在 finite 通路，`:380-410`）。

**形态 (a)——入口不存在（今天）**：CLR 在实参封送阶段就抛 ⇒ `int fserr = …` **这一句自己抛** ⇒ 下面的 `if (fserr != fserrNone)` **根本不执行**（`_ptsPage` **不被置零**）⇒ 异常冒到布局调用者 ⇒ 被**应用自己的钩子**记 `[HC-UNHANDLED]`（现取 1151＋1 行）⇒ **页面画不出来**。

**形态 (b)——入口存在但返非 0（补完之后的新形态）**（现取 `PtsPage.cs:295-306` 原文）：
```
            int fserr = PTS.FsCreatePageBottomless(PtsContext.Context, _section.Handle, out formattingResult, out ptsPage);
            if (fserr != PTS.fserrNone)
            {
                // Formatting failed and ptsPage may be set to a partially formatted page. Set value to IntPtr.Zero
                _ptsPage = IntPtr.Zero;
                PTS.ValidateAndTrace(fserr, PtsContext);
            }
            else
            {
                // Formatting succeeded. Set page value
                _ptsPage = ptsPage;
            }
            …
            if(formattingResult == PTS.FSFMTRBL.fmtrblInterrupted)
            {
                DeferFormattingToBackground();
            }
```
而 `ValidateAndTrace` **不是** `Validate`（现取 `Pts.cs:76-128`）：
```
: 76  internal static void ValidateAndTrace(int fserr, PtsContext ptsContext)
: 78      if (fserr != fserrNone) { ErrorTrace(fserr, ptsContext); }
: 83  private static void ErrorTrace(int fserr, PtsContext ptsContext)
: 85      switch (fserr) {
: 87          case fserrOutOfMemory: throw new OutOfMemoryException();
: 96          default:
: 97              Debug.Assert(ptsContext != null, …);
: 98              if (ptsContext != null) {
: 99                  Exception innerException = GetInnermostException(ptsContext);
:100                  if (innerException == null || innerException is SecondaryException || innerException is PtsException) {
:    // The only exceptions thrown were our own for PTS errors. We shouldn't throw in this case but should
:    // log the error if debug tracing is enabled
:100                      … if (TracePageFormatting.IsEnabled) { Trace(… PageFormattingError …); }   ← **只在 tracing 开时记一行**
:114                  } else { throw new SecondaryException(innerException); }                        ← 有第三方内层异常才抛
:122              } else { throw new Exception(SR.Format(SR.PTSError, fserr)); }
```
🔴 **⇒ 形态 (b) 的后果：`_ptsPage = IntPtr.Zero` ＋ `ValidateAndTrace` 在"`ptsContext.CallbackException` 为 `null`／只有我方 PTS 异常"时 **不抛**，且**只在 `TracePageFormatting.IsEnabled` 时**才留一行**。
⇒ **这开了一条全新的假绿通路（本判据必须关掉它）**：**把这两条做成"诚实缺口 stub（返 `-10000`）"⇒ ENFE 归零（`N2` 变绿）而排版并未发生，且很可能一行痕迹都没有**（症状从"1151 行 ENFE"变成"什么都没有"）。**⇒ 判据必须新增 C4（非零返回必须留痕）＋ P4（诚实 stub 的静默 ⇒ 必红）。**
⚠️ **不改上游**：`ValidateAndTrace` 的这套语义是**上游既有**的（`:100` 那句注释逐字在册）⇒ 正解是**在 native 侧留痕**（计数器/镜像/具名行），**不是**去改 `Pts.cs`（越域，且会动 PF 面 `ARTIFACT_SRC_FP`）。

### 2.3 分界句／最小可辩护实现／算「假成功」

> **分界句（沿用 W8 各步，逐字）**：**`return 0`（`fserrNone`）本身不是证据**；证据是「这次调用在本进程内留下了**与该对象绑定**、**可被独立读取**的状态变化」。

- **最小可辩护实现（本步四件套 ＋ 两条本族特有约束）**：
  1. **入参形状校验**：`pfscontext` 为 `NULL` ⇒ **拒绝**（返非 0、**一个字节都不读**）；且必须**按指针身份**确认它是 `CreateDocContext` 那一步真发过的、仍活着的上下文（**不 deref 未知句柄**）。
  2. **出参真落盘且与该次调用绑定**：`*ppfspage` ＝ **本次真分配**的页对象地址（两次调用的两个句柄**必须不同**，且各自等于自己对象的地址域 ⇒ **不是进程级全局单例**）；`*pfsfmtrbl` **必须写该次调用的结果**（**不许**恒 `fmtrblGoalReached`）。
  3. **计数 ＋ 可独立读取**：成功/被拒各一对计数；观测镜给出"刚才是哪个 `pfscontext`、落出了什么 `ppfspage`／结果"；**权威**是页对象本身，自检**逐字段对拍**两者。
  4. **能证伪的自检新格**（格号 ≥ 现册最大 ＋1；现册用到的最大格号以 `win32_pts.c` 现取为准）。
  - 🔴 **本族特有约束 ①（失败必清出参）**：返非 0 时 `*ppfspage` **必须置 `IntPtr.Zero`**、`*pfsfmtrbl` **必须置一个"未达成"值**（**不许**留残留/毒值）。依据：托管侧注释逐字「Formatting failed and ptsPage may be set to a partially formatted page. **Set value to IntPtr.Zero**」（`PtsPage.cs:298`／`:400`）⇒ **两端都不得留"半成品指针"**。
  - 🔴 **本族特有约束 ②（失败必留痕，`C4`）**：**返非 0 必须留下可机读痕迹**（native 计数器／镜像／具名行），**因为托管侧的 `ValidateAndTrace` 可能一个字都不记**（§2.2 形态 (b)）。
- **算「假装成功」**：返 `0` 但 `*ppfspage` 仍 `NULL`／是常量／未与本次调用绑定；`*pfsfmtrbl` 恒 `fmtrblGoalReached`；`pfscontext` 为 `NULL`／毒值仍返 `0`；"只 `return 0` 而对象一个字段都没变"；**返非 0 却不留任何可读痕迹**。

---

## §3 ③ 诚实边界与非目标

### 3.1 **不许**承诺「补了这两条两页就真排版」（本会话已有多次硬实证）
- 本会话已两次证明「账面无红 ≠ 画出来了」：① `t112`／`t114` 那轮净腿 `alive=yes ∧ magenta=0` 而两页并未画出各自内容；② `N2` 的 ENFE 面今天仍是 **1152**。⇒ **本步的绿只准读成"这一条入口不再缺 ＋ 该入口的行为与该上下文绑定、可读"。**
- **本步之后最可能的下一站（现取，静态口径）：`Fs*` 族里**还**有一大簇**。**现取**：全 PF 树 `PTS.Fs*` 调用点去重 ⇒ **56 个不同入口名**（**静态 call-site 计数**，不是运行期）：`FsQuerySubpageDetails`×23／`FsQueryTrackDetails`×22／`FsQueryTextDetails`×20／`FsTransformRectangle`×18／`FsQuerySubtrackDetails`×10／`FsDestroySubpage`×9／`FsQueryPageDetails`×8／`FsDestroySubpageBreakRecord`×8／`FsTransformBbox`×6／`FsQuerySectionDetails`×6／…（命令：`grep -rhoE 'PTS\.Fs[A-Za-z0-9_]+' --include=*.cs upstream/wpf/…/PresentationFramework/ | sort | uniq -c | sort -rn`）。
  ⇒ **`FsCreatePageBottomless` 只是第一个被撞的**；补完它，链会立刻去撞**查询/变换/销毁**那一簇，而**它们多用会抛的 `PTS.Validate`**（例如 `SubpageParagraph.cs:206` `FsCreateSubpageFinite`、`ListParaClient.cs:46` `FsQuerySubtrackDetails`）⇒ **那一簇的失败形态与形态 (b) 不同**（会真抛）。**⇒ 不许**把本步写成"打通排版"。

### 3.2 非目标（明确不做）
- **不**实现整套 `Fs*` 排版语义（**66 条缺口／56 个被调名**；本步只做被点名的 2 条，且 `FsCreatePageFinite` 是否同趟见 §4-C11 的判法）。
- **不改** `upstream/**`（`Pts.cs`／`PtsPage.cs`／`PtsContext.cs` 一个字不改）⇒ 尤其**不许**去"修 `ValidateAndTrace` 的静默"（那是**上游语义**；正解是 native 侧留痕）。
- **不动第三方**（`~/hc-linux/**` 演示应用及其 `[HC-UNHANDLED]` 钩子一律不改 —— 它只是**读数来源**）。
- **不**承诺两页真排版；**不**顺手扩 `fp_inputs()` 覆盖面；**不**动判据件／装置件。
- 不实现 `Fs*` 的**结构布局**以外的"排版算法"（断行/分栏/均衡都不在本步）。

---

## §4 ④ 判据 C1–C12

> **通用**：每条 verify **捕获式取 `rc`**（`cmd >out 2>err; echo $?`）；**不许**从管道末段取 `$?`。
> **通用反过读句**：任何"绿"都不许读成"两页真排版"；本步的绿只准读成 §3.1 那句。
> **本判据必须覆盖 `N1–N4`**（口径出处：`P1-realized-criteria-report.md` §1；本件**不重新定义**它们，只把它们**接到本步的证据面**上）。

### C1 构建面：源码改动真进了 `.so`（含 `SRCS` 登记格）
- **objective**：本增量真被编译进 `libwpfwin32.so`，且**新增源件不会漏登记**。
- **acceptance**：① `bash src/WpfGfx.Linux.Native/build-shim.sh --symbols >out 2>err` ⇒ `rc=0`；② `exports.txt` 行数 **＝** `nm … \| grep -c .`；③ **若新增/改名了源文件**，`build-shim.sh` 的 `SRCS=(…)` 里必须逐名可核（**该件不在 `fp_inputs()` 覆盖面内** ⇒ 这条只能靠判据自带）；④ `.so` 的 `sha16` **≠ before**（before ＝ `a131ea4e6f5cc4f5`）。
- **取哪个字段**：`exports.txt` 行数；`libwpfwin32.so` 的 `sha16`；`grep -n 'SRCS=' -A2 build-shim.sh`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash src/WpfGfx.Linux.Native/build-shim.sh --symbols >/tmp/fs_c1.out 2>/tmp/fs_c1.err; echo "rc=$?"; a=$(nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | grep -c .); b=$(wc -l < src/WpfGfx.Linux.Native/bin/exports.txt); echo "nm=$a exports=$b equal=$([ "$a" = "$b" ] && echo yes || echo NO)"; grep -n 'SRCS=' -A2 src/WpfGfx.Linux.Native/build-shim.sh; ls src/WpfGfx.Linux.Native/src/*.c | wc -l
```
- **期望形状**：`rc=0`；两值相等且 **≥ 572**；`SRCS` 行里的 `.c` 数 ＝ `src/*.c` 实际件数（**不等 ⇒ 红并点名差集**）。

### C2 导出面：**本族的新增导出是"正确动作"，但要逐名点名**
- **objective**：把 2 条（或按声明做的更多条）**裸名**真导出；并如实说明"新增导出"在**本族是对的**（与 W8 前几步"不靠加导出收尾"**不是同一回事**）。
- **acceptance**：`nm` 里 **`FsCreatePageBottomless` 命中 ＝ 1**、**`FsCreatePageFinite` 命中 ＝ 1**（**裸名**，与实测异常文本里的名字逐字一致）；`exports.txt` 与 `nm` **行数相等**且**比 before 至少多**新增的条数；新增的**每一个**符号逐名点名（`comm -13 before now`）。
- **取哪个字段**：`nm` 命中；`exports.txt`；两代符号集差集。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && S=src/WpfGfx.Linux.Native/bin/libwpfwin32.so; for n in FsCreatePageBottomless FsCreatePageFinite; do printf "%s nm=%s\n" "$n" "$(nm -D --defined-only $S | awk '{print $3}' | grep -cx "$n")"; done; nm -D --defined-only $S | awk '{print $3}' | grep -c '^Fs'
```
- **期望形状**：两条各 **＝1**；`^Fs` 计数 **≥ 2**（本步只要求被点名的那些）。
  ⚠️ **`A` 变体（现取，如实记）**：覆盖工具模型的探测名是 **`FsCreatePageBottomless/FsCreatePageBottomlessA`**（即"裸名 ＋ `A` 后缀"两探）⇒ 判据**只要求裸名**（实测异常文本报的就是裸名）；"只导出 `A` 变体够不够"记 `NOINFO`（见 §9-N2）。

### C3 **`N2`：ENFE 必须归零 且 不得被吞**
- **objective**：这两条入口不再以"符号不存在"的形式出现；**且**不许把它换成"静默"。
- **acceptance**：① 新腿证据里 `grep -c 'Unable to find an entry point named'` ＝ **`ENFE_TOTAL`**，**按入口名直方图**必须给出（现取 before：**1152 ＝ 1151×`FsCreatePageBottomless` ＋ 1×`FsCreatePageFinite`**）；② **`FsCreatePageBottomless` 与 `FsCreatePageFinite` 的计数各 ＝ 0**；③ **其它名**若出现，必须**逐名**归因到"本步非目标 allowlist"（allowlist 逐名可核，**不许**按总数/均值归因）。
- **取哪个字段**：`ENFE_TOTAL`（整数）＋ `ENFE_BY_NAME`（按名直方图）。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; grep -c 'Unable to find an entry point named' "$D"/app_g1.log; grep -o "entry point named '[A-Za-z0-9_]*'" "$D"/app_g1.log | sed "s/.*named '//;s/'$//" | LC_ALL=C sort | uniq -c | sort -rn
```
- **期望形状**：`ENFE_TOTAL` 与 allowlist 的差集 **＝ 0**；直方图里**没有**这两个名字。
- 🔴 **反过读（本步最要紧的一句）**：**`ENFE_TOTAL=0` 不构成"排版成功"** —— 见 C4／C6／C7／C8；它只证"符号在"。

### C4 **非零返回必须留痕**（本步新加，堵形态 (b) 的假绿通路）
- **objective**：**入口补上之后**，若 native 返非 0（含"诚实缺口 stub"），**必须留下可机读痕迹** —— 因为托管侧的 `ValidateAndTrace` 在常见情形下**不抛、且只在 tracing 开时记一行**（§2.2 现取原文）。
- **acceptance**：载体必须给出**一个**机器可读的"失败面"（native 计数器／镜像字段／具名行，字段名由实现件同趟写死），并给**成对读数**：**同一趟**里"成功次数"与"被拒/失败次数"**各自可读**；且 **"把该入口做成恒返 `-10000` 的副本"这一反腿下，该面必须非零**（P4）。
- **取哪个字段**：实现件写死的字段（本件不预判名）；要求"字段名 ＋ 该字段在两条腿上的值"同趟给出。
- **verify**（形状）：
```
# 由实现件填具体命令；必须捕获式 rc，且必须给「fresh 或已发生调用序 ＋ 依赖计数当时值 ＋ rc/diag」三格
# 形状：page_create_ok=<n> page_create_rejected=<n> page_create_gap=<n>
```
- **期望形状**：真实现 ⇒ `gap=0` 且 `ok≥1`；**诚实 stub** ⇒ `gap≥1`（**并且**此时 C6/C7/C8 不得给绿）。

### C5 出参绑定面（对象绑定，**不是**内容证明）
- **objective**：`return 0` 之外有**与该次调用绑定**的状态变化。
- **acceptance**：同一进程内**两次**独立调用：`rc=0`；两次的 `*ppfspage` **互不相等**且各自等于自己对象的地址域；`*pfsfmtrbl` **是本次调用的结果**（**不是**恒 `GoalReached`）；`pfscontext=NULL` ⇒ **返非 0** 且 `*ppfspage` 置 `NULL`（无残留）；**返非 0 时 `*ppfspage` 亦置 `NULL`**（§2.3 特有约束①）。
- **取哪个字段**：自检/探针的 `rc`／两个句柄／对拍结果／失败时的出参值。
- **verify**（形状）：`two_calls_rc=0/0  h1≠h2=1  result_is_per_call=1  null_in_rc=<非0>  fail_out_zeroed=1`
- **期望形状**：全部成立。**反过读**：两个句柄不同**只是必要条件**，"与这次调用绑定"必须由**字段读回**承担。

### C6 **`N1`**：帧身份 ＋ 帧位移（双要件；`ink>0` **降级**）
- **objective**：把"画出了内容"从粗代理升级为有区分力的读数。
- **acceptance**（照 `N1` 逐字）：① **帧身份**：该页帧 `sha256`（前16）**∉ 登记的空态参照集**；② **帧位移**：`AE(boot,该页帧) > 0` **且**每次点击后 `AE(上一帧,该页帧) > 0`（除非命中 `N3` 的同貌例外）；③ **`ink>0` 降级为"必要不充分"，不得单独满足本条**。
- **取哪个字段**：帧 `sha256`（前16）／`shotstat` 的 `colors,magenta,ink`／`AE` 整数。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; sha256sum "$D"/shots/g1/k24.png | cut -c1-16; python3 build/MilBridge/tests/PtsPagesProbe/shotstat.py "$D"/shots/g1/{boot,k23,k24}.png; compare -metric AE "$D"/shots/g1/boot.png "$D"/shots/g1/k24.png null:; echo " rc=$?"
```
- **期望形状**：`sha256 ∉` 空态参照集（**现取参照集 ＝ `{1a76488aa4a790b3}`**，即 `k23`＝`k24`＝`last` 那三帧；`boot` ＝ `b21eb530afd3c66c`）；`AE(boot,k24) > 0`（今天 **15385** ⇒ 该项**今天也满足** ⇒ 说明它**单独不够**）。⚠️ 空态换版必须**同趟重登记**。

### C7 **`N3`**：两页帧必须不同（去重计数 ＝ 2）
- **objective**：判开"两页同貌"与"第 23 页没重绘"。
- **acceptance**：同一趟里 ① 两条腿各自的帧 `sha256`；② **两帧必须不同**；**若相同** ⇒ 必须给出「两页内容确实同貌」的证据（两页 `ns=` 指向**同一 UI 且该 UI 无页别差异**）⇒ **否则判"没重绘"（红）**；③ 每次点击后 `AE(上一帧,本帧) > 0`（同上例外）。
- **取哪个字段**：帧 `sha256` 去重计数（**期望 2**）／`AE`（期望 `>0`）／两条 `LEG` 行的 `ae`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=<对照腿目录>; sha256sum "$D"/shots/g1/k23.png "$D"/shots/g1/k24.png | awk '{print $1}' | LC_ALL=C sort -u | wc -l; compare -metric AE "$D"/shots/g1/k23.png "$D"/shots/g1/k24.png null:; echo " rc=$?"; grep -E '^LEG k=2[34]' "$D"/leg_2[34].env
```
- **期望形状**：去重计数 **＝ 2**、`AE > 0`。**现取 before ＝ 去重 1、`AE=0`**（且两页 `ns=` **不同**：`…RichTextBoxDemo` ／ `…FlowDocumentDemo` ⇒ **不满足"同貌例外"**）⇒ **本条今天判"没重绘"＝ 红**。

### C8 **`N4`**：内容身份（`ns=` **不承担**；正身份**今天 `NOINFO`**）
- **objective**：证明"画面是该页**自己的内容**"。
- **acceptance**：① **负身份**（今天可达）＝ `N1①` 的帧身份；② **正身份**（**今天无载体**）＝ 该页**专属**的期望指纹（例如登记一次已知良好渲染的帧 `sha256`，或该页专属结构读数如 `TabControl` 的 tab 数）；③ **`ns=` 不得单独**承担；④ 在没有 ② 之前，本条记 **`NOINFO(无正身份载体)`**，**不得折绿**。
- **取哪个字段**：帧 `sha256`／`LEG … ns=`／内容 token 命中数。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; sha256sum "$D"/shots/g1/k24.png | cut -c1-16; grep -E '^LEG k=24' "$D"/leg_24.env; grep -ci 'neptune' "$D"/app_g1.log
```
- **期望形状**：`sha256` ＝ **登记的期望指纹**（**今天无此登记 ⇒ `NOINFO`**）；`ns=` 只作**辅助**（现取反例：`ns=…FlowDocumentDemo` 与"空态画面"**同时成立**）。

### C9 两页症状面（`alive`／`app_rc`／`magenta`／`colors`／`ae`）
- **objective**：本步不把两页推回"进程死／占位回来"，且症状面**成对**可读。
- **acceptance**：`leg_{23,24}.env`：`alive=yes` ∧ `app_rc ∉ {134,139}` ∧ `magenta = 0`（**今天 `realized` 方向**：占位不得回来）∧ `colors`／`ae`／`ink` 成对给出；`FAILLINE … failfast=0 unrec=0` 在位。
- **取哪个字段**：两腿的 `LEG`／`NAMED`／`DEV`／`FAILLINE` 四行。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; grep -hE '^(LEG|NAMED|DEV|FAILLINE) ' "$D"/leg_23.env "$D"/leg_24.env
```
- **期望形状**：`alive=yes`、`app_rc=143`、`magenta=0`、`failfast=0`、`unrec=0`。
  ⚠️ **反过读**：`magenta=0 ∧ alive=yes` **是今天就已经满足的**（现取）⇒ **它单独绝不能当本步的证据**（这正是 `P1-realized-criteria-report.md` §3 那句"净腿不崩＝假绿"的同一个坑）。

### C10 同趟与截图（`C7` 的截图版，逐腿比对，**不许**拿 `legs=2/2` 当同趟）
- **objective**：所有成对读数取自同一趟；截图与其 env 同趟。
- **acceptance**：① 两腿 `DEV … shim=`／`pf=` **逐位相同**且**等于现盘 `.so`**；② `session.txt` 的 `shim_sha16=`／`five_pre:` **同值**；③ **截图同趟三格**：截图 `sha256` ＋ `shotstat` 现读与 `leg_*.env` 的 `colors`／`magenta`／`ink` **逐格相等** ＋ `session.txt` 帧行同值；④ **明写**「`legs=2/2` 不是同趟证据」（守卫现取：活腿解析段**不读** `DEV … shim=`）。
- **取哪个字段**：两腿 `DEV` 行；`session.txt` 的 `shim_sha16`／`five_pre`／帧行；`shotstat` 现读；现盘 `.so` `sha16`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; s=$(sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16); a=$(grep -h '^DEV ' "$D"/leg_23.env | grep -o 'shim=[0-9a-f]*' | cut -d= -f2); b=$(grep -h '^DEV ' "$D"/leg_24.env | grep -o 'shim=[0-9a-f]*' | cut -d= -f2); c=$(grep -o 'shim_sha16=[0-9a-f]*' "$D"/session.txt | cut -d= -f2); echo "disk=$s leg23=$a leg24=$b session=$c same=$([ "$s" = "$a" ] && [ "$s" = "$b" ] && [ "$s" = "$c" ] && echo yes || echo NO)"; sha256sum "$D"/shots/g1/k24.png | cut -c1-16; python3 build/MilBridge/tests/PtsPagesProbe/shotstat.py "$D"/shots/g1/k24.png; grep -E '^LEG k=24' "$D"/leg_24.env; grep -E 'FILE=.*k24\.png' "$D"/session.txt
```
- **期望形状**：`same=yes`；`shotstat` 三格 ＝ `leg_24.env` 三格 ＝ `session.txt` 帧行三格。**现取 before ＝ 成立 ✓**（`384/0/480000` 三处同值）。

### C11 台账／缺口面：**本族不得"制造"台账行，也不得回退既有面**
- **objective**：本步属"**未导出 ⇒ 补导出**"族，**不是**"已导出 stub ⇒ 真实现"族 ⇒ 台账语义不同，必须写清。
- **acceptance**：① 若实现为**真实现**：`g_pts_calls[]`／`g_pts_seen[]` 对该名的语义**如实声明**（真实现按既有惯例记 `g_pts_seen` 不记 `g_pts_calls`），且 `native_gap` **不得**因本步被"制造"成非零；② 若**同趟**也补了 `FsCreatePageFinite`：逐条点名并给出它的 `nm` 命中与 `ENFE` 归零两块读数；③ **反过读**：`native_gap=0` **不构成本步的前进证据**（它今天已经是 0，且对本族结构性失明）。
- **取哪个字段**：`PTSGAP=`／`NAMED … native_gap=`；`nm` 两条命中。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/pts-gap-count-check.sh >/tmp/fs_c11.out 2>/tmp/fs_c11.err; echo "rc=$?"; grep -E '^(PTSGAP=|PTSGAP_FRONTIER )' /tmp/fs_c11.out; grep -h '^NAMED ' build/MilBridge/tests/PtsPagesProbe/evidence/leg_2[34].env
```
- **期望形状**：`rc=0`；`so16=` ＝ 现盘 `.so`；`native_gap` **如实**（不得为凑数把它做成非零）。

### C12 回归面（已落地的东西不得回退）
- **objective**：本步不动前几步的成果。
- **acceptance**：① `^PTS_GAP entry=` 仍 ＝ **0** 且 `PTS-UNAVAILABLE` 仍 ＝ **0**；② `Invariant.FailFast`／`Unrecoverable system error.` 仍 ＝ **0**；③ `FONT_FALLBACK` 行**仍在**（字体栈降级不被碰坏）；④ 收尾同侪 `DestroyDocContext`／`LoDisposePenaltyModule` **不回退**（`nm` 各 1）；⑤ `pts-gap-decl.txt` 的现值位与 `PTSGAP=` **同趟相符**。
- **取哪个字段**：证据日志三处计数；`FONT_FALLBACK` 行数；`nm` 两个命中；声明件与三格。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; echo "gap=$(grep -cE '^PTS_GAP entry=' "$D"/app_g1.log) unavail=$(grep -c 'PTS-UNAVAILABLE' "$D"/app_g1.log) failfast=$(grep -c 'Invariant.FailFast' "$D"/app_g1.log) unrec=$(grep -c 'Unrecoverable system error.' "$D"/app_g1.log) fontfb=$(grep -c 'FONT_FALLBACK' "$D"/app_g1.log)"; nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | grep -cE '^(DestroyDocContext|LoDisposePenaltyModule)$'
```
- **期望形状**：前四个计数 ＝ `0/0/0/0`；`fontfb ≥ 1`；末值 ＝ **2**。

---

## §5 ⑤ 「假进度必红 P1–P9」

> **总则（写死）**：**反腿未红、或红而不点名 ⇒ 该条判不成立**；**反腿必须在副本文档上跑**（副本落 `/tmp` 或仓外），`git status --porcelain` 不得出现被改的仓内件。
> **点名口径**：**`reason=` token 或字段名，二者之一命中即可算"点名"**（本仓多数 token 未实现 ⇒ 不许把"必红并点名"押在未存在的 token 上）。

| # | 假形式 | 正腿（必绿） | 反腿（**必红并点名**） | 必红点（字段/token 二者之一） |
|---|---|---|---|---|
| **P1** | **只改计数/声明凑数字**（改 `pts-gap-decl.txt`／白名单／`exports.txt`） | 真实现 ⇒ C2 的 `nm` 两条各 ＝ 1 | 只改声明/文件 ⇒ 必红 | `nm` 命中与 `exports.txt`／声明件**不一致** ⇒ 红 |
| **P2** | **`return 0` 无副作用** | 真实现 ⇒ C5 的两调用对拍成立 | 把该入口换成"清空出参 ＋ `return 0;`"的**副本** ⇒ 自检**必红**并点名（出参仍是毒值／结果格恒 `GoalReached`） | 返 0 时 `*ppfspage` **仍 NULL/未绑定** 或 `*pfsfmtrbl` **恒常量** ⇒ 红 |
| **P3** | **🔴 把 `ENFE` 静默吞掉**（`N2` 的教训） | 真实现 ⇒ C3 的直方图**没有**这两个名字，**且**留痕机制在位 | 副本上把"未找到符号"这一路的**留痕**去掉（或换成"无声回落"） ⇒ 必红并点名 | `ENFE_TOTAL=0` **而** C4 的失败面**不可读/缺失** ⇒ 红（`reason=enfe-swallowed` 或字段名等价物） |
| **P4** | **🔴 诚实 stub 的静默（本步新加，§2.2 形态 (b)）** | 真实现 ⇒ 成功面 `ok≥1`、失败面 `gap=0` | 把该入口做成**恒返 `-10000`** 的副本 ⇒ **托管侧 `ValidateAndTrace` 不抛**（现取原文"shouldn't throw … log … if debug tracing is enabled"）⇒ **若此时 C6/C7/C8 给绿，或 C4 的失败面读不到，必须红并点名** | "返非 0 无一字节痕迹" 或 "ENFE 归零即被读成排版成功" ⇒ 红（`reason=honest-stub-silent` 或字段名等价物） |
| **P5** | **两页帧仍相同却报绿**（`N3`） | 真实现 ⇒ C7 去重计数 ＝ 2 | 两帧仍逐字节相同 ⇒ 必红并点名 | `sha256` 去重计数 ＝ 1 ∧ 无"同貌"证据 ⇒ 红（`reason=no-repaint` 或字段名等价物） |
| **P6** | **拿 `ink>0` 当内容证据**（`N1`） | 真实现 ⇒ C6 双要件齐 | 只用 `ink>0` 就判"有内容" ⇒ 必红并点名 | 现取反例：`ink=480000` 在 `boot`／`k23`／`k24` **四帧同值** ⇒ 红（`reason=ink-no-discrimination`） |
| **P7** | **拿 `ns=` 当内容身份**（`N4`） | 真实现 ⇒ C8 有正身份（**今天 `NOINFO`**） | 只用 `ns=` 判"内容对" ⇒ 必红并点名 | 现取反例：`ns=…FlowDocumentDemo` 与"空态画面"**同时成立** ⇒ 红 |
| **P8** | **跨趟拼读数**（含截图与 env 不同趟） | C10 的 `same=yes` ＋ 截图三格 | 拿**另一趟**的帧/env 配对 ⇒ 必红并点名 | 四值不等 ∨ `shotstat` 与 `leg_*.env` 三格不等 ⇒ 红（`reason=cross-run-pairing`） |
| **P9** | **恒绿自检没有牙** | 自检能证伪（P2/P4 的副本） | 把自检改成恒 `return 1`／恒 `diag=0` ⇒ **三档探针判词全同** ⇒ 必红 | 正极/负极/边界三档的 `rc`／`diag` **完全相同** ⇒ 红 |

---

## §6 ⑥ 两极化（a／b／c）

| 腿 | 构造 | 必绿/必红 | 取哪个字段 | **点名要求** |
|---|---|---|---|---|
| **a（入口缺失）** | **受控**地把被测 `.so` 换成**不含该符号**的副本（或用一个受控假名触发同一路） | **必绿**：出现**可按名过滤**的 ENFE 留痕（`ENFE_BY_NAME` 里**有**该名）**且**进程不崩（`alive=yes`、`app_rc ∉ {134,139}`） | `ENFE_BY_NAME`；`LEG alive/app_rc` | 若进程死 ⇒ **红并点名**（`reason=process-abort`）；若无留痕 ⇒ **红并点名**（`reason=no-enfe-trace`） |
| **b（入口在）** | 现盘权威件 | **必绿**：该名 `ENFE` 计数 **＝ 0** | 同上 | 若仍有该名 ⇒ **红并点名** |
| **c（反腿：把 ENFE 吞掉）** | 副本文档上把"留痕这一环"去掉（例如用一个**不接受/不记录** ENFE 的产物组合，或把该路换成无声回落） | **必红**，且**由 C3/C4 红**（不是由 a 腿红） | C3 的 `ENFE_TOTAL`／C4 的失败面 | **必须点名**（`reason=enfe-swallowed`／字段名等价物）＋ 指出"是 C3/C4 抓的"；**若 a、b 两腿都红** ⇒ 另判（不许当"通过"） |

**「假成功」的两条必红（与 §2.3 对齐）**：**P-静默**（返非 0 而无一字节痕迹 ⇒ C4 必须红）；**P-恒定**（`pfsfmtrbl` 恒 `GoalReached`／`ppfspage` 恒常量 ⇒ C5 必须红）。

---

## §7 ⑦ 纪律第 `30` 条（在册）对本判据的硬约束

**在册确认（现取，本件自己取）**：`build/MilBridge/HANDOFF-NEXT.md` 在册块头（内容锚「dated 纪律追加 · 第 `30` 条（**进程内状态敏感仪器**的调用史约束）」，**行号仅本次有效**）；在位自检命令现跑 `grep -c '进程新鲜[度]' build/MilBridge/HANDOFF-NEXT.md` ⇒ **`3`**（≥1）。

**本判据的硬约束（写死）**
1. **凡引用自检/探针/计数器镜像/`live` 读数（含 C4 的失败面、C5 的两调用对拍、C11 的 `g_pts_seen`），同趟必须给三格**：① **进程新鲜度**（fresh 进程，**或**同进程 ＋ **已发生的关键调用序**，逐条列出：建过几个 `CreateInstalledObjectsInfo`／LS 上下文／罚分模块／**上下文**、是否调过 `CreateDocContext`／`FsCreatePageBottomless`／`FsCreatePageFinite`、是否销毁）② **关键前置量**（该读数依赖的那些计数/`live` 的**当时值**）③ **判词**（`rc`／`diag`）。**缺任一格 ⇒ 该读数不许当证据。**
2. **正腿必须在 fresh 进程里跑**；带历史腿**必须独立进程**，历史逐条可复现。
3. **两种误导形态（写清）**：
   - **带历史的红 ＝ 假红**：同一 `.so` 在 fresh 与带历史两种前置下判词不同，成因是**调用序**（本仓已有硬实证：`t110` 那趟链 push 条数 3→4 把观测镜环写满 ⇒ 夹具被覆盖 ⇒ `diag=86`）。
   - **🔴 本族的「fresh 的绿 ＝ 假绿」＝「净腿不崩就以为修好了」**（**本会话硬实证**）：现取 `alive=yes ∧ app_rc=143 ∧ magenta=0` **今天就已经成立**，而两页并未画出各自内容（帧去重 ＝ 1、`ENFE_TOTAL=1152`）。⇒ **本判据把它升为必要条款**：**凡以"净腿不崩／占位消失"为唯一证据的断言，必须再给一条"能让它变红的前置/反腿"**（＝ §6 的 **c** 与 P1–P9 的对应项），否则该断言的绿**不算证据**。
4. **多一格（本族特有）**：凡涉及"排版/内容"的判定，**必须标明取值源**（帧 `sha256`／`AE`／`shotstat`／日志 token／源码阅读 **五选一，逐字写出**）。**不写源 ⇒ 该判定不许当证据**（`N4` 就是被这条挡住才记 `NOINFO` 的）。

---

## §8 ⑧ 同趟与截图（**写死的三条**）

1. **逐腿比对，不许拿 `legs=2/2` 当同趟证据**：守卫现取**活腿解析段不读 `DEV … shim=`**（`grep -n 'shim' build/MilBridge/tools/pts-pages-guard.sh` 只命中 `--selftest` 的夹具写出行与件头注释）⇒ 它**对跨代拼盘照样报 `legs=2/2`**。判据自带 C10①②。
2. **截图承重必带"同趟三格"**（照 `P1-realized-criteria-report.md` §2）：**①** 截图 `sha256`（前16）；**②** 与所引读数同趟的证明（`DEV` 行的 `shim=`／`pf=` 与现盘 `.so`／`session.txt` 的 `shim_sha16`）；**③** `shotstat` **现读**与 `leg_*.env` 的 `colors`／`magenta`／`ink` **逐格相等**。**缺任一 ⇒ 截图只作辅助件，不得单独承重。**
3. **现取 before（本件已验）**：`shotstat(k24.png)` ＝ `384/0/480000` ＝ `leg_24.env` ＝ `session.txt` 帧行 ⇒ **成立 ✓**；但**两页帧 `sha256` 相同**（`1a76488aa4a790b3`）⇒ 按 `N3` **判"没重绘"**（不是"同貌"：两页 `ns=` **不同**）。

---

## §9 ⑨ `NOINFO` 预期（逐条给"消掉需要什么"）

1. **`N4` 的正身份（该页专属期望指纹）**：`NOINFO(reason=今天无该登记载体；ns= 已被两次反例否掉)`. **消掉需要**：登记一次**已知良好**渲染的帧 `sha256`（或该页专属结构读数，如 `TabControl` 的 tab 数）——**另派单**。
2. **`A` 后缀变体是否也需要导出**：`NOINFO(reason=覆盖工具模型探测 `FsCreatePageBottomless/FsCreatePageBottomlessA`，而实测异常文本报的是**裸名**；"只导 `A` 变体够不够"本件未验)`. **消掉需要**：一次受控实验（只导 `A` 变体 ⇒ 看是否仍 ENFE），或 CLR 探测序的具名声明。
3. **`Fs*` 族的**运行期**撞击顺序**：`NOINFO(reason=本件只拿到**静态** call-site 计数（56 个不同名）；运行期顺序只能补一跳后重跑取证)`. **消掉需要**：补完本步后一趟腿的 `ENFE_BY_NAME` 直方图（这正是 `N2` 口径的用途）。
4. **`pfscontext` 的语义**（是否就是 `CreateDocContext` 落下的那个句柄／本步要不要按身份校验它）：`NOINFO(reason=本件未取得 native 侧规格；调用点是 `PtsContext.Context`，但"它就是 `CreateDocContext` 的 out 值"这一步未逐行证)`. **消掉需要**：`PtsContext.Context` 的赋值链现取，或运行期一句"两次调用的 `pfscontext` 相同"的读数。
5. **`FSFMTR`（struct）的字节布局权威**：`NOINFO(reason=本仓只有托管侧声明（3 个 int 宽的量）；无 native 侧规格 ⇒ 与 `t110` 的 `FSCONTEXTINFO` 同族风险)`. **消掉需要**：一条"逐字段读回"的成对读数，或一份具名布局声明。
6. **形态 (b) 在本装置的腿里是否真的"静默"**（`ptsContext.CallbackException` 是否恒 `null`、`TracePageFormatting.IsEnabled` 是否开）：`NOINFO(reason=两者都是进程内状态；本件只读、未跑)`. **消掉需要**：实现件给同趟三格读数（`CallbackException` 是不是 null ＋ tracing 开关值 ＋ 判词）。
7. **应用 `[HC-UNHANDLED]` 钩子的捕获语义**（是否只记不吞／有无条数上限／是否常开）：`NOINFO(reason=发射方在第三方应用，不在我方写域；本件只现取到 1152 行的存在与分布)`. **消掉需要**：读该件的捕获分支并给出原文，或我方加一条**自己的** `ENFE` 计数器。
8. **`build-shim.sh` 为何不在 `fp_inputs()` 覆盖面**：`NOINFO(reason=本件现取到 `in_fp=0` 这一事实，未取其历史理由)`. **消掉需要**：覆盖面纳入与否由主控裁定；**本件只登记"其实现在覆盖面之外 ⇒ 新源件漏登记时 `inputs_fp` 无感"**。

---

## §10 ⑩ 载体与边界遵守自证

- **载体**：`build/MilBridge/P1-fs-page-criteria.md`（新建；UTF-8；模式 **644**；**首记号不是 `# ⏪ `**；末行自带可复算自报口径）。
- **只读**：本件全部命令为 `grep`／`sed`／`awk`／`cat`／`nm`／`sha256sum`／`wc`／`stat`／`sort`／`uniq`／`git log`／`git status` ＋ 三个**纯读**件（`check-shim-coverage.py`（`--tier mapped`）／`pts-gap-count-check.sh`／`pts-pages-guard.sh --legs`／`shotstat.py`（只读 PNG）／`compare`（只读两 PNG）／`artifact-src-fp.py`（`--list`／无参，**不 `--write`**）／`close-wave.sh` 的 `fp_inputs()`（抽到 `/tmp` 后只跑 `cat` 支））。**零 `dotnet build`、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
- **未改任何其它件**：`git status --porcelain` 原样 ——
```
 M build/MilBridge/HANDOFF-NEXT.md
 M build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log
 M build/MilBridge/tests/PtsPagesProbe/evidence/device.txt
 M build/MilBridge/tests/PtsPagesProbe/evidence/device/xfwm.log
 M build/MilBridge/tests/PtsPagesProbe/evidence/leg_23.env
 M build/MilBridge/tests/PtsPagesProbe/evidence/leg_24.env
 M build/MilBridge/tests/PtsPagesProbe/evidence/session.txt
 M build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/k23.png
 M build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/k24.png
 M build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/last.png
?? build/MilBridge/P1-realized-probe-report.md
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/device.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/leg_23.env
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/leg_24.env
?? src/tests/
```
  ⇒ **16 项全属他人**（`t119` 那趟腿的证据面 ＋ 其载体 ＋ `arm_A` 组 ＋ `src/tests/`）；**本件是本次唯一新增件**。
- **未引既有报告当证据**：`P1-realized-criteria-report.md` 只作 **`N1–N4` 与"截图同趟三格"的口径出处**（**其读数一条未抄**，本件每条都现场重取）；`t119` 的载体只作**任务来源**。
- **末行自报口径当场可复算**：见末行。

---

### 结语（自包含）

- **① 域定位（结论）**：`Fs*` 的上游声明在 **`Pts.cs:3109-3116`（finite）／`:3127-3132`（bottomless）**，`DllImport` 模块名经 `Pts.cs:25` 的别名 → `RefAssemblyAttrs.cs:69` 的 `PresentationNative…dll` ⇒ **`PresentationNative_cor3.dll`**，而它由 **`build/shims/Win32ShimResolver.cs:60/:92` 映射到 `libwpfwin32.so`** ⇒ **本步与前三步同一个域（native shim `src/WpfGfx.Linux.Native/**`），不是 managed 侧**（旁证：`nm '^Fs'`＝0、`grep -rn 'FsCreatePage' src/`＝0）。**拟改件 M1–M7 与两面覆盖面见 §1.3**，其中 **`build-shim.sh` 的 `SRCS` 不在 `fp_inputs()` 覆盖面内** ⇒ 判据自带 C1③。
- **② 签名与语义**：`FsCreatePageBottomless(IntPtr pfscontext, IntPtr fsnmsect, out FSFMTRBL, out IntPtr)`／`FsCreatePageFinite(IntPtr, IntPtr, IntPtr, out FSFMTR, out IntPtr, out IntPtr)`；`FSFMTRBL` 是**枚举**、`FSFMTR` 是 **struct**；`fserrNone = 0`。**调用点 `PtsPage.cs:295`／`:397`**，**两种失败形态**：**(a) 入口不存在** ⇒ CLR 抛 ⇒ `_ptsPage` 不置零 ⇒ 应用钩子记 ENFE（今天 1152）；**(b) 入口在而返非 0** ⇒ `_ptsPage = Zero` ＋ `ValidateAndTrace`，而后者**在常见情形下不抛、且只在 tracing 开时记一行** ⇒ **本判据据此新增 C4（返非 0 必须留痕）与 P4**。
- **③ 诚实边界**：**不承诺两页真排版**；本步之后最可能的下一站是 **`Fs*` 里那 56 个被调名**（静态计数）；**非目标**＝不做整套 `Fs*`、不改 `upstream/**`（尤其**不改 `ValidateAndTrace` 的静默**）、不动第三方、不扩覆盖面。
- **④ 判据 C1–C12**：构建（含 `SRCS` 格）／**导出面（本族"新增导出"是正确的，逐名点名）**／**`N2`：ENFE 归零且不得被吞**／**返非 0 必须留痕**／出参绑定／**`N1` 帧身份＋帧位移（`ink` 降级）**／**`N3` 两页帧必须不同**／**`N4` 内容身份（`ns=` 不承担，正身份 `NOINFO`）**／两页症状（**明写 `magenta=0 ∧ alive=yes` 今天已满足、单独不得当证据**）／同趟与截图（**不许拿 `legs=2/2` 当同趟**）／台账面（**`native_gap=0` 不是前进证据**）／回归面。
- **⑤ 假进度必红 P1–P9**：含 **静默吞 ENFE**（P3）、**诚实 stub 的静默**（P4，本步新加）、**两页帧仍相同却报绿**（P5）、**拿 `ink>0` 当内容证据**（P6）、**拿 `ns=` 当内容身份**（P7）、跨趟拼读数（P8）、恒绿自检（P9）。
- **⑥ 两极化 a／b／c**：a 受控缺符号 ⇒ **可按名过滤的 ENFE 留痕 ＋ 进程不崩**；b 现盘 ⇒ 该名 ENFE **0**；c 把留痕吞掉 ⇒ **必被 C3/C4 红并点名**。
- **⑦ 纪律第 `30` 条**：三格 ＋ 调用序 ＋ 两种误导形态；**并把「净腿不崩＝假绿」升为必要条款**（本会话硬实证：现取 `alive=yes ∧ magenta=0` 与"两页未画出内容"同时成立）；另加"排版判定必须标明取值源"。
- **⑧ 同趟与截图三条**：逐腿比对（`legs=2/2` **不是**同趟证据）／截图承重必带三格（现取 before **成立 ✓**）／两页帧 `sha256` 相同 ⇒ 按 `N3` 判**没重绘**。
- **⑨ `NOINFO` 8 条**，各带"消掉需要什么证据"。

### §10-bis 落盘期间的位移（**只增不改，如实追加**；`ts=2026-09-29T11:30:39.791212572+0800`）

- **`HEAD` 动了**：本件起点现取 `aa7a6d9`（§0 记录值）→ 落盘时 **`f86cc36`**（`docs(#81): t119 N3 对照腿判别入账 —— 判开「帧相同」两义；真相＝两页都没画出内容（ENFE_TOTAL=1152）`）。
  ⇒ **本件的全部读数取自 `aa7a6d9` 那一刻的文件内容**（`sha16` 已逐个给出）；`f86cc36` 是**文档入账**，**未改** `.so`／证据面。
- **工作树 16 → 17 项**：新增 **`M build/MilBridge/tools/pts-pages-guard.sh`**（现 sha16 **`7d5d659371befdac`**、`mtime 2026-09-29 11:30:34`）—— **另有车道在改守卫**（`N2` 的执行落点恰在守卫，见 §9-N8／`N1–N4` 口径件的 `NOINFO②`）。
  ⚠️ **引用提醒**：本件 §8-C10① 引用的那句"活腿解析段**不读** `DEV … shim=`"是**我在 11:27–11:29 对当时那一版**取的事实（`grep -n 'shim' … \| wc -l` ＝ **3**，落盘时复量**仍为 3**）⇒ **该句以现取为准**；**但该件正在动，实现件/复核件再引它时必须重取 `sha16` 并重跑该 `grep`**。
- **判据依赖的权威件未动**：`libwpfwin32.so` `a131ea4e6f5cc4f5`、`exports.txt` `572`、`win32_pts.c` `ec5c877c897d2b7f`、`Pts.cs` `1a8575a18767a956` ⇒ §0–§2 的读数**在落盘时仍成立**。
- **本件仍是本次唯一由我新增的件**。
`P1-FS-PAGE-CRITERIA 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 3d1260d86f767a2c（口径＝末行之前的全文；末行＝本行）`
