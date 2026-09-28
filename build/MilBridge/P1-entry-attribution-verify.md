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

---

## ⏪ `t90` dated 追加（2026-09-29T00:27+0800；处置本件五 `low` ＋ 一观察；**只增不改**，本件原有文字一字未删）

写者 `scribe`（`t90`／P1-W19）｜**一切读数现取自算**（含对 `t87` 的件做 A/B 时都重跑了自己的夹具）｜仪器仓外、零构建（`pwsh 7.6.6` 反射现盘 Release 件 ＋ `Marshal.GetDelegateForFunctionPointer` 直调现盘 `.so`）。

**处置表**

| 项 | 处置 | 落点（现取） | 读数小节 |
|---|---|---|---|
| `F-1` 库名形状过窄 | **修**（放宽到本栈真件名形，**同时收紧字符面**） | `PtsCache.Linux.cs` `IsLibraryNameShape()` | §`F-1` |
| `F-3` 读口无长度纪律 | **托管侧修**（纪律落在判据实际消费的读口）＋ native 真修法**入册未改**（`src/**` 不在本件写域，给建议补丁） | `GapEntryNameAt()`／`GapNameCap` | §`F-3` |
| `F-2` 四措辞短路 | **修**（形状不合改 `continue` 续扫） | `EntryNameFromException()` ②路 | §`F-2` |
| `F-4` 注释与实现不符 | **改注释**（实现**不动**：多缺口读数两代逐字同） | `NativeEntryName()` 注释 ＋ ②路口径块 | §`F-4` |
| `F-5` `err=` 不可自证 | **只落口径句**（**值不改**，理由在册） | `A1_STUB_ERR` 上方 | §`F-5` |
| `O-1` `-1` 已写 `buf[cap-1]` | **只落口径句** | `NativeReport()` 的 `-1` 口径块 | §`O-1` |
| 队长派单错前提 | **更正入册（队长认账）** | §前提更正 | 我自算双锚 |

**改动面（逐件现取；`ts=2026-09-29T00:26`）**

- `build/PresentationFramework.Linux/PtsCache.Linux.cs`：本件头所载 `ab5851116641cc5c`（1236 行）→ **`6c4913b9ef462294`（1307 行／83583 B／mode 644）**；`git diff --numstat` ＝ **`92 21`**。那 **21 个删行全在下列 5 处改写点上**（逐条点名，无一处是"顺手删"）：①`NativeEntryName()` 的 XML 注释 1 行 ＋ ②路 6 行旧读法；②`EntryNameFromException()` ①路下**那句错位的重复 `<summary>`**（是 `NativeError` 的注释**串了行**，属注释面缺陷，一并更正）＋ ②路承重注释 1 行 ＋ ②路循环里 `return "unknown"` 1 行；③`IsLibraryNameShape()` 旧实现 10 行（旧：`StartsWith("lib")` 前缀硬条件）。**正文/判据/口径句无一处删除。**
- Release／部署件：`b3f0d129f0234b58` → **`83ba5884bb603296`**（`dotnet build … -c Release` 经重活槽，`0 警告 0 错误`；两条腿 `POSTSHIM shim=3bd193e54785b5db pf=83ba5884bb603296 == authority`）。`libwpfwin32.so` **未动**（仍 `3bd193e54785b5db`）。

### `F-1` 库名形状（修）—— 33 格 A/B，**7 格放宽 ＋ 3 格收紧**，其余 23 格逐字不变

**新口径（逐字，已写进代码）**：基名（先去掉目录）必须 ① 只用 `[A-Za-z0-9_.+-]`、不以 `.` 起头；② `*.dll` 茎非空；③ `*.so` 茎非空（**不要求 `lib` 前缀**）；④ `*.so.<纯数字段>(.<纯数字段>)…`；⑤ 其余 **false**。**没有**放宽到"任何带点的串"（后缀＋字符面双判）。

A/B 两代都是**真产物**：**旧** ＝ 部署件 `~/w67-work/app/PresentationFramework.dll`（现取 `b3f0d129f0234b58` ＝ 本件头所载那一代，**与在册腿证据同一件**）；**新** ＝ `build/…/bin/Release/PresentationFramework.dll` `83ba5884bb603296`。夹具原文见载体 `P1-entry-attribution-fix2-report.md` §仪器（全部仓外）。

| 格 | 输入（库名措辞） | 旧 `b3f0d129…` | 新 `83ba5884…` | 判 |
|---|---|---|---|---|
| `M11` | `'wpfgfx_cor3.so'`（**本栈真件**） | `unknown` ✗ | `dll:wpfgfx_cor3.so` ✓ | 放宽（`F-1` 正题） |
| `L7` | `'/opt/x/y/wpfgfx_cor3.so'`（去目录） | `unknown` ✗ | `dll:wpfgfx_cor3.so` ✓ | 放宽 |
| `M16` | `'lib.so'` | `unknown` ✗ | `dll:lib.so` ✓ | 放宽 |
| `M17` | `'libfoo.so.1.2'` | `unknown` ✗ | `dll:libfoo.so.1.2` ✓ | 放宽 |
| `D7` | `'a.b.so'` | `unknown` | `dll:a.b.so` | 放宽（后缀判据；见下"未放松"三条） |
| `T5` | `'NotImplemented.so'` | `unknown` | `dll:NotImplemented.so` | 放宽（**如实点名**：它**确实是**库名形状 ⇒ 形状面收；"该库是否真存在"是另一层，本件不承诺） |
| `S1` | 见 §`F-2` | `unknown` | `dll:x.dll` | 放宽（`F-2`） |
| `T1` | `'lib foo.so'`（茎含空格） | `dll:lib foo.so` ✗ | `unknown` ✓ | **收紧**（旧码无字符面判据，真收过带空格的"库名"） |
| `T2` | `'lib:1.so'` | `dll:lib:1.so` ✗ | `unknown` ✓ | **收紧** |
| `T3` | `'lib=1.so'` | `dll:lib=1.so` ✗ | `unknown` ✓ | **收紧** |

**未放松的负样例（两代同判 `unknown`，11 格）**：`U1` `'NotImplemented'`（真实 `DllNotFoundException` 长措辞）／`U2` `System.NotImplementedException: 'NotImplemented'`／`U3` 裸 `'NotImplemented'`／`U5` 日志行形／`D1` `'foo.bar'`／`D2` `'v1.2'`／`D3` `'x.txt'`／`D4` `'libfoo.so.x'`／`D5` `'.so'`（空茎）／`D6` `'libfoo.so.1.beta'`／`D9` 只有目录的串／空串／`<null>` 异常。**未变的正样例**：入口名三格（`E1`／`E2`／`E3` ⇒ 入口名原样）＋ `L1`／`L2`／`L3`／`L8`／`L9`／`D8`／`T6`／`T7` 逐字同。

**产物侧正极（同趟在册面）**：本席自己的腿目录 `five_pre_g1.txt` 现取**逐行**含 `wpfgfx_cor3.so=4e25e4b27d4d5ae1` ⇒ 「本栈真件名形」不是我编的，是**现盘五件清单里就有它**（这也正是 `F-1` 的立案依据）。

### `F-3` 长度纪律（托管侧修；native 侧真修法入册）

**① native 现约定（裸口，无纪律；两代同值——`B` 面 16 行 A/B **逐字相同**）**：`rc=1` 恒表示"idx 在册"，**不论有没有截断**。

```
B gapname idx=1(=`LoAcquirePenaltyModule`) cap=4  => rc=1 name=[LoA]
B gapname idx=1                            cap=5  => rc=1 name=[LoAc]
B gapname idx=1                            cap=12 => rc=1 name=[LoAcquirePe]
B gapname idx=1                            cap=128=> rc=1 name=[LoAcquirePenaltyModule]
B gapname idx=0(=`GetFloaterHandlerInfo`)  cap=5  => rc=1 name=[GetF]
B gapname idx=2（越界）                    cap=128=> rc=0 name=[]
```

**② 托管纪律（新增；同进程、同台账）**：`GapEntryNameAt(idx,cap)` —— 旧代 `METHOD-ABSENT`，新代：

```
C idx=1 cap=4  => <null>      C idx=0 cap=4  => <null>
C idx=1 cap=5  => <null>      C idx=0 cap=5  => <null>
C idx=1 cap=12 => <null>      C idx=0 cap=12 => <null>
C idx=1 cap=128=> LoAcquirePenaltyModule      C idx=0 cap=128=> GetFloaterHandlerInfo
```

⇒ 纪律两条（代码内逐字）：**①富余判据** `strlen < cap-1`（截断时长度恒为 `cap-1` ⇒ 不认；名字恰好 `cap-1` 长时也判 `unknown` ⇒ **宁可误报 unknown**）；**②形状判据**（入口名＝C 标识符）。生产路用 `GapNameCap=128`：现册最长名 `LoGetPenaltyModuleInternalHandle` **32 B**（名单 12 名，我自算）⇒ 富余 **95 B** ⇒ 富余判据在现册**必真**，一旦名册出现 ≥127 B 的名字则**保守判 unknown**（收紧方向）。

**③「若返回截断名会骗过判据」夹具（判据本体，跑的是在册牙 `pts-pages-guard.sh --g10-name <目录>`）**：

| 夹具（`app_g1.log` 内容） | 语义 | 读数 |
|---|---|---|
| `entry=LoAc` | **裸口 cap=5 的截断值** | `PTS_G10_NAME=FAIL frontier=LoAc off-roster=LoAc roster=12 domains=unattributable` **rc=1** |
| `entry=LoAcquirePe` | 裸口 cap=12 的截断值 | `… FAIL off-roster=LoAcquirePe …` **rc=1** |
| `entry=LoAcquirePenaltyModule` | **纪律读口的真值** | `PTS_G10_NAME=PASS observed=LoAcquirePenaltyModule names=1 roster=12 domains=pts-declared` **rc=0** |
| `entry=LoSetDoc`（**构造**） | 「截断名恰好落在**另一个在册真名**上」这一情境 | `PTS_G10_NAME=PASS observed=LoSetDoc … domains=pts-declared` **rc=0** |

⇒ 三点如实：(a) 判据按**值**在册对拍 ⇒ **只要**截断值落在某个真名上就会**假绿**（第 4 行证明"值面确实收"，第 4 行的情境是**构造的**：现册 12 名**无前缀包含对**，所以今天截断只会落到**没在册**的串上 ⇒ 现实风险是**假红**（第 1／2 行），假绿是**潜在**的）；(b) 这条潜在假绿的成因**不是名册**，是**读口无纪律**；(c) 纪律把两条路一起关掉：截断值**根本到不了** `entry=`（cap=4/5/12 全 `<null>`），生产 cap 只可能给出**带富余的完整名**或 `unknown`。

**④ native 侧真修法（`F-3` 原文建议「长度不足返 0」）—— 本席未应用，给 `src/**` 持有者**（建议补丁，逐字）：

```c
/* WpfLinuxWin32_PtsGapEntryName：截断即响亮报 0，绝不回一个貌似完整的短名 */
        if (seen == idx) {
            size_t need = strlen(k_pts_entries[i]) + 1;
            if ((size_t)cap < need) { buf[0] = '\0'; return 0; }     /* 长度不足 ⇒ 0（可判） */
            memcpy(buf, k_pts_entries[i], need);
            return 1;
        }
```

配套（若采用）须同趟处理 `WpfLinuxWin32_PtsGapReport()` 的同类面（`O-1`：`-1` 时 `buf[cap-1]='\0'` 已写）与判据件里读该导出的任何地方 —— 这属于**另一次派单**，本件不越域。

### `F-2` 措辞循环短路（修）

`S1` 输入：`Unable to load DLL 'NotImplemented' or one of its dependencies: unable to find it in DLL 'x.dll'.` ⇒ 旧 `unknown`（首措辞命中、形状不合即 `return`，后段那条**合法库名**被掐掉）→ 新 **`dll:x.dll`**（`continue` 续扫四条措辞，形状校验一格未松）。**①路（入口名措辞）刻意保持短路** `return "unknown"`：那里"措辞命中而名字不是 C 标识符"说明**是入口名措辞给了个假名**，此时改去报库名会把"入口名归因"偷换成"库名归因" ⇒ 保留短路并写入代码注释（**不对称是有意的**，已逐字注明）。

### `F-4` 注释与实现不符（改注释；实现两代逐字同）

**本席自算的两缺口读数**（同一进程：**先**调 idx7 `LoAcquirePenaltyModule`、**后**调 idx4 `GetFloaterHandlerInfo`）：

```
D gap_count=2（驱动序：LoAcquirePenaltyModule idx7 → GetFloaterHandlerInfo idx4）
B gapname cap=128 idx=0 => GetFloaterHandlerInfo      ← 在册**表序**首个有计数者（= `anchor=`）
B gapname cap=128 idx=1 => LoAcquirePenaltyModule     ← 在册**表序**末个（= ②路 `idx=count-1`）
D NativeEntryName() => LoAcquirePenaltyModule         ← 托管 ②路给的是**表序末名**
D report anchor=[GetFloaterHandlerInfo] frontier=[LoAcquirePenaltyModule] report_len=291
```

⇒ **"最近调用"的是 `GetFloaterHandlerInfo`**，而 ②路/`anchor=` 给 `LoAcquirePenaltyModule` ⇒ 旧注释那句「native 台账里**最近一条缺口**的入口名」**与实现不符**（`t88` 的 `F-4` 成立，本席独立复现）。实现**不动**（native 侧根本没有 recency 字段；改实现＝改 native＝越域），改的是注释：现注释写明「**在册表序**最后一个有缺口计数的入口名（**不是**最近一次调用；与 `wpf_pts_frontier()` 的**调用序**口径不同）」。**旧代/新代 `D` 面 8 行逐字相同**（除新增的 `C` 面）⇒ 措辞更正**零行为改动**。

### `F-5` `err=` 不可自证（口径句，值不改）

我自算：native `win32_pts.c` `#define WPF_PTS_ERR_NOT_IMPLEMENTED (-10000)`；托管 `A1_STUB_ERR = -10000` ⇒ **同值** ⇒ `NativeError()` 读不到与读到时**都打 `err=-10000`** ⇒ `err=` 面**不能**用来判"到底读到没有"（旧件/新件的 `err` 面实测也确实同值）。**本件不改值**：`-10000` 是在册面（`leg_*.env` 的 `native_err=-10000`、台账行 `err=-10000`、判据件对拍都用它）⇒ 换"域外哨兵"会**改动判据面**，属另一次派单（须同趟与判据件＋在册证据对齐）。口径句已写进 `A1_STUB_ERR` 上方注释：**判"读到没读到"只许看旁边那几格**（`entry=`／`native_gap=`／`PTS_GAP entry=…` 台账行）。

### `O-1` `-1` 已终结缓冲（口径句）

我自算 native 原文：`if (n < 0 || n >= cap) { buf[cap - 1] = '\0'; return -1; }` ⇒ "写不下"时 `buf` 是一条**被截断且以 nul 结尾的行**（`t88` 的夹具读数 `CAP 250/251/256 buflast_is_nul=True` 与本席对 `-1` 那一支的原文读数一致）⇒ **忽略 `rc` 的读者会读到貌似完整的短行**（与 `F-3` 同族）。托管侧守法是 `rc <= 0 ⇒ continue`（**先看 `rc`，再看 `buf`**），口径句已写进 `NativeReport()` —— 并写明"**绝不许**把 `buf` 的 nul 结尾当作'读到了一条完整行'的证据"。

### 前提更正（**队长认账**）

`t88` 派单背景里那句「该名不在声明树（上游无 `DllImport` 声明）」**与现取不符** —— **队长已认账**。本席自算双锚：`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs:1569` ＝ `[DllImport(DllImport.PresentationNative, EntryPoint = "LoAcquirePenaltyModule")]`（`:1570` 是它的 `extern LsErr` 声明；`grep -rl 'LoAcquirePenaltyModule' upstream/wpf --include=*.cs | wc -l` ＝ **2**）＋ `src/WpfGfx.Linux.Native/src/win32_pts.c:78` ＝ 在册表 `"LoAcquirePenaltyModule",`。⇒ 「native 侧 stub」**不等于**「上游无声明」：它是**双锚**名（在册表 ＋ 上游声明）⇒ 后人**不得**沿用错误前提去弱化 `G10_NAME` 的域判据。

### 现树正极 ＋ 零症状回归（新代 `pf=83ba5884bb603296`）

```
正极（本席自己的腿目录 ~/w281-scribe/t90/legs-after，`ts=00:25`）：bash build/MilBridge/tools/pts-pages-guard.sh --legs …
  rc=0  PTS_G10_NAME=PASS observed=LoAcquirePenaltyModule names=1 roster=12 domains=pts-declared
        PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded
  `app_g1.log` 现取 `3 entry=LoAcquirePenaltyModule`；`HC-UNHANDLED` **1**（设计内闩）；`five_pre == five_post`（cmp 同）
零回归（成对，**不逐位相等**）：leg_23 alive yes→yes／app_rc 143→143／magenta 49943→49943／colors 844→844／ae 141283→141283／ink 428456→428456／ns 逐字同／native_gap 1→1／native_err -10000→-10000
                    leg_24 alive yes→yes／app_rc 143→143／magenta 54533→54533／colors 852→**851**／ae 221857→**221246**／ink 423798→423798／ns 逐字同
  成对取法：**旧极** ＝ 在册 `evidence/leg_*.env`（载 `pf=b3f0d129f0234b58`，与部署件同值）；**新极** ＝ 本席本趟重跑（载 `pf=83ba5884bb603296`）。
```

⚠️ 本席**只**在 `C`／`D` 面上做了产物 A/B；`entry=` 的旧极用的是**在册证据**（同一 `pf` 的那一代腿），新极是我自己跑的 ⇒ 「零症状回归」是**成对通过**，**不宣称**逐位相等（leg_24 的 `colors −1`／`ae −611` 与 `t88` 记的 ±518／±452 同量级，属重跑抖动）。

**SELF-SHA16**（口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`）＝ cd25a41c0b651a62 —— ⚠️ 本块**之上**原末行 `SELF-SHA16 ＝ 9a34a170cd8482f1` 是**本块加入之前**全文的自报值 ⇒ **保留不改**（只增不改）；**本行**才是**现全文**的自报值（本行不参与自身取值，故重算稳定）。
