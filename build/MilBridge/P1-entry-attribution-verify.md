# P1-ENTRY-ATTRIBUTION-VERIFY（`t88` 独立复核 · W17「`entry=` 归因退化」修复 · `t87` 的件）

> **本席只读仓树、只写本件。** 复核对象＝**入账面**，不是未提交件：`git diff -- build/PresentationFramework.Linux/PtsCache.Linux.cs` 现取**空**（0 行）⇒ 复审的源码就是 `640065b`（`fix(#81): t87 修 entry= 归因退化`，`2026-09-29T00:10:10+08:00`，面 = `PtsCache.Linux.cs +179/−23`、`P1-entry-attribution-report.md +92`、`HANDOFF-NEXT.md +1`）。
> **本席现取（`ts=2026-09-29 00:15:55.887593318 +0800`，`HEAD=ac29ff1`）**：`build/PresentationFramework.Linux/PtsCache.Linux.cs` `ab5851116641cc5c`｜`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll`（＝**部署件** `/home/links-dev/w67-work/app/PresentationFramework.dll`，两件同值）`b3f0d129f0234b58`｜`src/WpfGfx.Linux.Native/src/win32_pts.c` `ddc21eb68d2d67e8`｜`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` `3bd193e54785b5db`（mtime `23:15:23.450709987`）｜`build/MilBridge/tools/pts-pages-guard.sh` `944e61f39f24631c`｜在册 `evidence/app_g1.log` `e348b4ef70ab521e`（mtime `00:09:11.828693542`）｜`evidence/leg_23.env` `5b245a02ae5df8a8`／`leg_24.env` `5cf62452cd3d4fb7`｜`P1-entry-attribution-report.md` `4fcc3dddfa8a3625`。
> **仪器全部本席自造、仓外、零构建**：夹具 N/N2＝Python＋`ctypes` 直调现盘 `.so`；夹具 M＝`pwsh 7.6.6` **反射**现成产物（`Assembly.LoadFrom` ＋ `DllImportResolver` 指向现盘 `.so` ＋ `Reflection.Emit` 造原生调用委托），**不编译任何件**；夹具 O＝按 `git show 2364821:` 原文**字面等价模型**（已标"非产物读数"）。

---

## ① 缓冲：真读得全，且是**按 `-1` 信号递增重试**（不是"把一个数改大"）

- **native 约定（我自己读原文）**：`win32_pts.c` `:610` ＝ `if (n < 0 || n >= cap) { buf[cap - 1] = '\0'; return -1; }`、`:611` ＝ `return n;`（`:578` 函数头）。⇒ **`>0` ＝ 写入长度；`-1` ＝ 写不下**。
- **我的 cap 扫描（夹具 N，现盘 `.so`，`ts≈00:10`）**：全新进程 `rc=250 len=250`；6 名缺口态 `rc=286 len=286`；二分求界得 `min_cap_ok == len+1`（`286→287`、`250→251`）；`CAP 250/251/256/285/286 ⇒ rc=-1`（且 `buf[cap-1]` 均为 `0`）；`CAP 287/4096 ⇒ rc=286`。**加宽态**（同名缺口打 300k 次，`calls=300000`）：`len=302`，`CAP 256 ⇒ rc=-1`、`CAP 4096 ⇒ rc=302`。⇒ **生产态（台账有行）的串 >256 B**，旧定长 `byte[256]` **当场必 -1**。
- **托管侧同进程实测（夹具 M `rawcaps`，同一 dlopen 句柄把台账打起来后）**：`RAWCAP cap=64/250/251/256 ⇒ rc=-1`、`cap=4096 ⇒ rc=292`；紧接着 `NativeReport()` **返回 292 字符**。⇒ 第一档 `256` 必 -1 ⇒ **放大重试那一步真被走到**，且返回的是**完整串**（不是截断、不是空）。
- **判**：**成立**。实现是 `for (cap = 256; cap <= 65536; cap *= 16)` ＋ `rc <= 0 ⇒ continue` ⇒ **由 `-1` 这个"读不全"的唯一信号驱动递增**（不是"把 256 换成一个固定大数"）；三档 `256→4096→65536` 足以覆盖可达长度（下条）。
- **同形洞（我自己算上界）**：格式串字面 **219 B** ＋ 12 个计数 ≤10 位 ＋ `anchor` ≤63 ＋ `frontier` ≤63 ⇒ **≤465 B** ≪ 65536；实测最大 302 B。⇒ `64 KiB` 天花板**不可达**；即便可达，那一支返回 `string.Empty`（如实"读不到"，不猜）⇒ **无同形洞**。
- **正极（同一进程、同趟台账）**：`PTS_GAP entry=LoAcquirePenaltyModule seq=1..3 err=-10000 calls=3` ⇒ `NATIVE_ENTRY=LoAcquirePenaltyModule`（**台账里的真名**，不是 `unknown`）；对照全新进程 `NATIVE_ENTRY=unknown`（`GAP_COUNT=0`）。**这是"假绿"与"真名"两态的同趟对拍。**

## ② 异常取数：两极化成立，且**再也不出现 `dll:`＋非库名**

- **两极（夹具 M `matrix`，23 格，现盘 Release 件 `b3f0d129f0234b58`）**：
  - ①入口名措辞 ⇒ 入口名原样：`M01 'LoSetDoc' in DLL …` ⇒ `LoSetDoc`；`M02 …named 'LoAcquirePenaltyModule' in shared library 'libwpfwin32.so'` ⇒ `LoAcquirePenaltyModule`；`M20 '_LoSetDoc'` ⇒ `_LoSetDoc`。
  - ②库名措辞 ⇒ `dll:<真库名>`：`M03` ⇒ `dll:libwpfwin32.so`；`M04` ⇒ `dll:PresentationNative_cor3.dll`；`M10 '/usr/lib/…/libfoo.so.1'` ⇒ `dll:libfoo.so.1`；`M19 'LIBFOO.SO'` ⇒ `dll:LIBFOO.SO`；`M21 '/opt/x/y/libbar.so'` ⇒ `dll:libbar.so`。
  - ③伪消息 ⇒ **`unknown`**：`M05`（真实 `DllNotFoundException` 长措辞 ＋ `'NotImplemented'`）、`M06 System.NotImplementedException: 'NotImplemented'`、`M07 'NotImplemented'`、`M23` 日志行形、`M08` 空串、`M09 null`。
- **全量不变式（夹具 M `invariant`，6 措辞 × 14 名/库名 ＝ 84 格）**：`dll_prefix=12 unknown=58 c_ident=14 violations=0`，判式＝「以 `dll:` 开头 ⇒ 库名必匹配**独立**正则 `^(lib[^/]*\.so(\.[0-9]+)*|[^/]+\.dll)$`；否则必须是 C 标识符或 `unknown`」。⇒ **合成名在 84 格扫描里 0 例**。
- **代码面（我自己 grep）**：全件可执行位 `"dll:"` **只有 1 处**（`:1091` `if (IsLibraryNameShape(baseName)) return "dll:" + baseName;`），其余 5 处命中全在注释里。
- **产物面（现盘在册件）**：`evidence/app_g1.log` 现取 `3 entry=LoAcquirePenaltyModule`，**`dll:` 形 0 例**（旧态同件曾是 `2 entry=LoSetDoc`；`t81` 那趟仓外日志是 `entry=dll:NotImplemented`）。
- **旧字面为什么必然那样（夹具 O；⚠️ 非产物读数）**：我把 `git show 2364821:…PtsCache.Linux.cs` 里 `EntryNameFromException` 的**字面**重实现后跑同一批输入 ⇒ `M05/M06/M07/M23/M11` 五格**都**给 `dll:NotImplemented`／`dll:wpfgfx_cor3.so`（判式：末个引号串无形状校验即加前缀）。现场那条由此可解释；`M22 '/x/LoSetDoc'` 在旧字面下返回**带路径的入口名**（新件给 `unknown`）。
- **产物侧修前 A/B ＝ `NOINFO`**（见末）：修前 Release 件 `8ef62d37e7c2ce2e` 已不在盘（全盘 `6124544` 字节同名件只剩 1 份＝新件）。可得的**唯一旧件** `b9a4f3a0e48e688d`（`2026-09-28 10:28`）**早于**引入该异常的 `2364821`：其 `WpfLinuxPtsGap` 方法表现取只有 `{Describe, IsPtsUnavailable, NativeCalls, NativeEntryName, NativeError, NativeReport, PtsGapCallsNative, PtsGapReportNative}` ⇒ 我实测它对伪消息给 `unknown`（即"**unknown → 合成名 → unknown**"的三段史，中段是 `2364821` 引入、`640065b` 修掉）。

## ③ 现树正极：`rc=0`／PASS；域判定＝`pts-declared` 且**该名有双锚**（背景里"上游无声明"的前提不成立）

- **现取（`--legs` 在册目录，`ts≈00:15`）**：`rc=0`；
  `PTS_G10_NAME=PASS observed=LoAcquirePenaltyModule names=1 roster=12 domains=pts-declared（形态判据：具名行**在在册名单内**；PTS 域不写死任何名字）`；
  `PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded`。
- **名册面（我自己读）**：`win32_pts.c:70` `static const char *const k_pts_entries[] = {`，其中 `:78` ＝ `"LoAcquirePenaltyModule",` ⇒ **确在册**，名册共 **12** 名（与判据 `roster=12` 相符）。
- **声明面（我自己找）**：`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs:1569` ＝ `[DllImport(DllImport.PresentationNative, EntryPoint = "LoAcquirePenaltyModule")]` ⇒ **双锚**。⇒ 任务背景里「它是 native 侧 stub、上游**无** `DllImport` 声明」**与现取不符**（`grep -rn 'LoAcquirePenaltyModule' upstream/wpf` 命中 2 个 `.cs`）。
- **域判据三格（我自己的仓外夹具，`--g10-name`）**：真名 `LoAcquirePenaltyModule` ⇒ `PASS … domains=pts-declared` `rc=0`；伪造名 `LoNotARegisteredEntZZ` ⇒ `FAIL frontier=… off-roster=… roster=12 domains=unattributable decl=none` `rc=1`（红极有效）；非 PTS 名 `AbortPrinter` ⇒ 同**红** `rc=1`，**但这不是缺陷**：它的声明在 `upstream/wpf/…/System.Printing/CPP/inc/InteropWin32ApiThunk.hpp:216`（`.hpp`），而 `decl_hit()` 的域现取是 `--include='*.cs'`（`pts-pages-guard.sh:151`）⇒ 域边界所致、判词如实。
- **判**：**归因恢复了**，且这一格是**真绿**（理由＝在册表命中，不是"算式凑的"）；本案**不存在**"域定义不完整"所致的假红。**不替队长裁任何事**，只给上述可复现读数与夹具。

## ④ 零症状回归：成对**通过**（不逐位相等）

成对取法：**before** ＝ `HEAD^`（`640065b` 之前一代）在册 `leg_*.env`；**after** ＝ `ac29ff1` 入账的现盘 `leg_*.env`（`git diff HEAD^ HEAD -- evidence/leg_23.env evidence/leg_24.env`，本席现取）。

| 面 | k=23 before → after | k=24 before → after |
|---|---|---|
| `alive` | `yes → yes` | `yes → yes` |
| `app_rc` | `143 → 143`（SIGTERM＝仪器收的，∉{134,139}） | `143 → 143` |
| `magenta` | `50461 → 49943`（−518） | `55051 → 54533`（−518） |
| `ink` | `428004 → 428456`（+452） | `423346 → 423798`（+452） |
| `colors` | `844 → 844` | `851 → 852` |
| `ns` | 逐字同 | 逐字同 |
| `ae` | `140247 → 141283` | `221246 → 221857` |
| `native_gap` | `0 → 1` | `0 → 1` |
| `native_err` | `- → -10000` | `- → -10000` |
| `DEV shim` | `2a5165700a8c8579 → 3bd193e54785b5db`（**＝现盘 `.so` ✓**） | 同 |
| `DEV pf` | `8ef62d37e7c2ce2e → b3f0d129f0234b58`（**＝现盘 Release 件/部署件 ✓**） | 同 |

- **`unh=0`**：产该在册证据的同一趟 runner 日志现取 `2 unh=0`，且 `CLICK k=24 … AE=221857 … unh=0`、`CLICK k=23 … AE=141283 … unh=0` —— 两个 `AE=` 与本件在册 `ae=` **逐位相同** ⇒ **同一趟**，不是拼接。
- **判**：**成立**（`alive`／`app_rc`／`unh` 逐位相等；`magenta`±518、`ink`±452、`ae` 微差 ⇒ 重跑抖动，成对但**不逐位相等**，如实记）；`native_gap=1` 是 degraded 期的**设计内**要求（判据 `ngap_total ≥ 1`），非回归。

## ⑤ 不变量 / 指纹 / 判据件

- **覆盖面**：`bash ~/w153a/bin/infp.sh list` 现取 **234** 条；其中 `grep -n 'PtsCache'` 命中 **0** ⇒ **本件改动面不在覆盖面内**（故指纹不该因本件移动；与 `t87` 自述一致，但此处是我自己算的）。
- **`inputs_fp`**：现取 `5e6357364232ec49d906bf08bfccb3ceccf4aca71c7996a462684172ca0a03ff`（`ts=2026-09-29T00:15:00.929977596+0800`）。`HANDOFF-NEXT.md:609` 末条 `cell=#1` 登记值是 `b97bdecc28664139a044cd5b4cfa772d8f0d7b5d9ef74d83e4cff8f691206c08`（`ts=00:10:58`）⇒ **与最终现取不一致**；成因＝`ac29ff1`（`00:13:27`，在册证据换代）**晚于**那次登记，属"登记后被别的提交推动"，**非本件改动面所致**（上一条已证改动面不在覆盖面）。
- **两哨兵**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**；字段现取 `SHA=4e25e4b27d4d5ae1 FP=d697b1e10ff48881 PC=5b6cfda3e12b84fc PF=b3f0d129f0234b58 WB=9e860cbeecb352e1 WIN32SHIM=3bd193e54785b5db HBTL=921ba9c65e9fb3be WIC=f7b3026c8c019be2 PROVIDER=24e4e0a731dbed40 DWF=c83be96f18759edc WAVE=w80-freeze BASELINE=#80 BASELINE_SHA16=b27ff6332f263495`：`PF`／`WIN32SHIM` 与现盘两件**相符** ⇒ **不该重写哨兵**。
- **`HANDOFF_MV`**：`bash build/MilBridge/tools/handoff-machine-values-check.sh` ⇒ `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`（与我上件同值）。
- **判据件未被本件改动（逐位对拍）**：`P1-ptsname-criteria.md` `aa72a215d411e806`（`mode=644`，mtime `2026-09-28 22:33:48.718749909`，`porcelain` 无此件）；`P1-entry-attribution-report.md` `4fcc3dddfa8a3625`（`porcelain` 无此件 ⇒ 已在 `640065b` 入账）；被复核源码／二进制三件复核前后同值（见件头）。
- **并发披露（非本件，如实点名）**：复核窗口内 `porcelain` 另有 4 处**他人在飞/未入账**：`M build/MilBridge/HANDOFF-NEXT.md`、`M build/MilBridge/P1-w8-step1-verify.md`（**+38 行追加**，现 `c06b6e6d060118a1`／141 行，mtime `00:15:02.950879032`，**非本席所写**）、`M build/MilBridge/tools/pts-gap-count-check.sh`（`+7/−1`）、`M docs/ROUTES.md`；本席零碰。`HEAD` 在本席复核期间移动两次（`9239ce8`→`640065b`→`ac29ff1`），**被复核的源码与二进制未动**（件头三值在 `00:08`／`00:15:55` 两次现取同值）。
- **四条不变量**：本席现取可复算者＝覆盖面 **234**、HMVC `cells=9/equal=8`；`^run_step "` 计 **62** 与 `--expect 234`／`62 gen=#81` 这两对该时辰的**仪器本席在件内未定位到**（多轮 `grep` 命中 0）⇒ 标 **`NOINFO`（仪器未定位）**，**不当绿**。

## ⑥ 载体与边界自证

- **唯一写入** ＝ `build/MilBridge/P1-entry-attribution-verify.md`（新建，UTF-8，首记号 `# P1-ENTRY-ATTRIBUTION-VERIFY`，**非** `# ⏪ `，`mode 644`，末行自带可复算自报口径 sha16）。
- **未改任何 `t87` 件**：`P1-entry-attribution-report.md` `4fcc3dddfa8a3625`、`PtsCache.Linux.cs` `ab5851116641cc5c`、Release/部署件 `b3f0d129f0234b58`、`libwpfwin32.so` `3bd193e54785b5db` —— 复核前后同值。
- **边界**：只读仓树；**未**跑整趟门禁、**未**构建、**未**跑腿、**未**占显示位、**未** `git add/commit/push`；夹具（`native_probe.py`／`native_probe2.py`／`managed_probe.ps1`／`emit_probe.ps1`／`old_model.py`／`g10` 三格夹具目录／各 `*.out`）**全部在 `~/wv88y/t88/` 仓外**，收尾**删净**（仓内残留仅本件）。
- **判词可复现**：夹具脚本虽已删，但每条结论都带**命令原文＋读数**；①③④⑤ 的主读数全部落在**现盘可复算的件**上（`pts-pages-guard.sh --legs`、`infp.sh list|fp`、`handoff-machine-values-check.sh`、`git diff HEAD^ HEAD`、在册 `evidence/**`）。

## Findings（不改 `t87` 任何件；要改的以「夹具＋读数」给出）

- **`F-1`（low）库名形状判据过窄** ⇒ 真件被判无名：`IsLibraryNameShape` 只收 `*.dll` 与 `lib*.so(\.[0-9]+)*`；夹具 `M11 'wpfgfx_cor3.so'`（本栈真件之一，`evidence/five_pre_g1.txt` 现取在列 `wpfgfx_cor3.so=4e25e4b27d4d5ae1`）⇒ **`unknown`**；`M16 'lib.so'`、`M17 'libfoo.so.1.2'` 同判无名。修法：形状放宽到「`.so` 结尾（含多段版号）」，并把这几格入册为形状判据的**正/负样例**。
- **`F-2`（low）四措辞短路**：`libWording` 循环里首个措辞命中而形状不合即 `return "unknown"`，**不再看后面的措辞**。夹具 `M12`（`'NotImplemented'` ＋ 同串后段 `in DLL 'x.dll'`）⇒ `unknown`，而后段是**合法库名** ⇒ 丢了一次可归因机会。修法：形状不合时 `continue` 而不是 `return`。
- **`F-3`（low）新读口 `WpfLinuxWin32_PtsGapEntryName` 无长度纪律**：`snprintf` 静默截断且**仍返回 1**。夹具 N2 `trunc`：`cap=5 ⇒ rc=1 name=b'LoAc'`、`cap=4 ⇒ rc=1 name=b'LoA'`（全长名 `LoAcquirePenaltyModule`）。托管侧缓冲 `new byte[128]`（`:1005`）⇒ 今日名册最长 ~32 B 无风险；一旦名册出现长名，`NativeEntryName()` 会返回**貌似真的截断名**（比 `unknown` 更坏：会骗过在册判据）。修法：长度不足返 `0`。
- **`F-4`（low）注释与口径不一致**：`NativeEntryName()` 的 XML 注释写「native 台账里**最近一条缺口**的入口名」，实现在 ②路给的是**在册表序**最后一名（`idx = count-1`）。夹具 N2 `order`：最后被调＝`LoAcquirePenaltyModule`（名册 idx 7），取回 `LoGetPenaltyModuleInternalHandle`（名册 idx 8），而 `anchor=`＝`LoAcquirePenaltyModule`。现网 `count=1` ⇒ 不可观测。修法：改措辞（或让 native 记 recency）。
- **`F-5`（low）"读不到"不可自证**：`NativeError()` 读不到时的回落常量 `A1_STUB_ERR = -10000`（`:1188`）与 native 真值 `WPF_PTS_ERR_NOT_IMPLEMENTED = -10000` **同值** ⇒ 我实测旧件（读不到）与新件（读到）都打 `err=-10000` ⇒ `err=` 面**无法**区分二者。修法：回落值改成不出现在真值域内的哨兵。
- **`O-1`（观察）`-1` 时 native 已把 `buf[cap-1]='\0'`** ⇒ 忽略 `rc` 的调用方会读到**截断行**（夹具 N 的 `CAP 250/251/256 buflast_is_nul=True`）。托管侧用 `rc <= 0 ⇒ continue` 守住（正/负两向实测）。

## `NOINFO`（不折绿、不折红）

1. **②的产物侧修前 A/B**：修前 Release 件 `8ef62d37e7c2ce2e` **已不在盘**（同尺寸全盘仅 1 份＝新件）⇒ 只能给"旧字面等价模型"；且**现场那条 `entry=dll:NotImplemented` 的原始异常文本未被任何日志记录** ⇒ 「哪条消息产出它」这一格 **`NOINFO`**。
2. **四条不变量里的 `run_step`＝62／`--expect 234`／`62 gen=#81`**：仪器未定位（`grep` 命中 0）⇒ `NOINFO`。
3. **"重编译副本"型反腿**（如"把自检改坏"）：本任务**禁构建** ⇒ 未跑。
4. **真实显示/排版面**：本任务**不许占显示位** ⇒ 未验（④只用成对读数与仪器判据）。

SELF-SHA16 （口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 9a34a170cd8482f1
