# P1-W55 · 测量小单 —— `FSCONTEXTINFO.fscbk` 与 `FSCBKGEN` 槽偏移的**实测**（托管侧仪器 ＋ native 只读回读 ＋ 两极化）

> **本件是 `t133`（runner）的交付**：把 `t132` 判为"钥匙是一个死角"的那一步**破掉** —— 给出 `FSCONTEXTINFO.fscbk` 与 `FSCBKGEN` 各槽的**实测偏移**（可复核的机器证据），并同趟修正 `t132` 登记的 `F-3` 错注释。
> **边界（硬）**：写域 ＝ `build/PresentationFramework.Linux/**`（canary 侧）／`src/WpfGfx.Linux.Native/**`（**只读回读 ＋ `:1480` 注释修正**）／本件／`build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` 行。未改上游、`build/MilBridge/tools/**`、装置本体、生成件、判据件、哨兵、`docs/ROUTES.md`、`samples/**`；**未动相位位**；未跑整趟门禁；未 `git add/commit/push`。
> **契约引用（不是证据）**：`build/MilBridge/P1-managed-handle-criteria.md`（`9abff3628f7188ea`）／`build/MilBridge/P1-managed-handle-report.md`（`t131`）／`build/MilBridge/P1-native-para-model-report.md`（`t132`，本件直接执行它的"建议排期第①步"）。**它们的读数一条未抄**——本件所有值**现取**。
> **表述纪律（写死）**：本件的绿**只准**读成「**偏移测量有了可复核的机器证据**」；**不许**读成"驱动链已通"，**不许**读成"排版打通"。
> **读取时刻**：`ts=2026-09-29T13:44:59+08:00`（起点）→ 末取见 §5／§8。

---

## §0 判词（写死）

**死角破了。** 三条独立证据（全部现取、全部**只读**）：

1. **托管侧仪器（运行期布局 API）**：在**真产物** `PresentationFramework.dll`（`2988f5154ecac5dd…`）上反射取出 `PTS/FSCONTEXTINFO`、`PTS/FSCBK`、`PTS/FSCBKGEN` 等内部类型，用 `Marshal.OffsetOf`／`Marshal.SizeOf` 取值 ⇒
   `sizeof(FSCONTEXTINFO)=872`、`sizeof(FSCBK)=824`（＝**103 槽 × 8 B**）、`fscbk=+40`、`cbkgen=0`／`cbktxt=256`／`cbkobj=504`／`cbkfig=568`／`cbkwrd=592`（相对 `FSCBK`）；目标槽绝对偏移：`pfnGetNextSection=56`／`pfnGetMainTextSegment=80`／`pfnGetFirstPara=136`／`pfnGetNextPara=144`／`pfnGetParaProperties=168`／`pfnCreateParaclient=**176**`／`pfnDestroyParaclient=192`。
2. **native 只读回读（跨边界、现场字节）**：在 app 进程里、对**真实**（CLR 封送出来的）`FSCONTEXTINFO` 按①的偏移逐 8 B 字回读 ⇒ 「**观测到的空槽位置**」与「**由托管侧源码预言的空槽位置**」逐项相符（`cbkobj` 前三槽 ＋ `cbkwrd` 全部 29 槽为空，合计 **32** 空槽）⇒ `fingerprint=PASS`。
3. **两极化**（充分证明分辨力）：**对**的偏移 ⇒ 该槽读到非零且**恰好等于托管侧交出的 canary**；**±8／±16** 的偏移 ⇒ 读到的是**别的槽**（或空槽），**不崩**且**明显不是**该 canary ⇒ 见 §3 的逐槽成对读数；另有**夹具反腿**（把空槽块整体错位 ⇒ `fingerprint=FAIL`）证明该指纹**不是恒绿**。

**候选值 vs 实测值**：`t132` 只能"算"的四个值（`fscbk=+40`／`pfnGetNextSection=+56`／`pfnGetFirstPara=+136`／`pfnCreateParaclient=+176`）**实测逐项相同** ⇒ 此前只能"算"的东西现在**有实测背书**（**注意**：这不改变"偏移必须实测、不许算"的纪律；它只是说明那次推导恰好正确）。

**同趟的第二项**：`t132` 登记的 `F-3`（夹具结构处"真身是委托（8 B）"的错注释）已按 **dated 只增不改**更正（原文一字未删），**纯注释修正、不动任何行为**（证据见 §6）。

**未做的通道（如实记）**：本件的"恰好等于 canary"是**封送指针**这一路的对拍；**未**做"托管侧按候选偏移读回 **native 侧**已知值"的反向通道（那需要 native 侧写结构，属行为改动）⇒ 记 `NOINFO`（§7）。

---

## §1 实测偏移表（本件主产出）

| 量 | 实测值 | 取法（现取） | `t132` 的候选值 | 相同? |
|---|---|---|---|---|
| `sizeof(FSCONTEXTINFO)` | **872** | `Marshal.SizeOf` | — | — |
| `sizeof(FSCBK)` | **824**（＝103×8） | `Marshal.SizeOf` | （`t132` 记为"103 槽"） | 与槽数一致 |
| `sizeof(FSCBKGEN)` / `FSCBKTXT` / `FSCBKOBJ` / `FSCBKFIG` / `FSCBKWRD` | **256／248／64／24／232** | `Marshal.SizeOf` | 32／31／8／3／29 槽 | 一致（×8） |
| `offsetof(FSCONTEXTINFO, fscbk)` | **+40** | `Marshal.OffsetOf` | +40 | **相同** |
| `offsetof(FSCBK, cbkgen/cbktxt/cbkobj/cbkfig/cbkwrd)` | **0／256／504／568／592** | `Marshal.OffsetOf` | — | — |
| `cbkgen.pfnGetNextSection`（绝对） | **+56** | 40+0+16 | +56 | **相同** |
| `cbkgen.pfnGetSectionProperties`（绝对） | **+64** | 40+0+24 | — | — |
| `cbkgen.pfnGetMainTextSegment`（绝对） | **+80** | 40+0+40 | — | — |
| `cbkgen.pfnGetFirstPara`（绝对） | **+136** | 40+0+96 | +136 | **相同** |
| `cbkgen.pfnGetNextPara`（绝对） | **+144** | 40+0+104 | — | — |
| `cbkgen.pfnGetParaProperties`（绝对） | **+168** | 40+0+128 | — | — |
| `cbkgen.pfnCreateParaclient`（绝对） | **+176** | 40+0+136 | +176 | **相同** |
| `cbkgen.pfnTransferDisplayInfo`（绝对） | **+184** | 40+0+144 | — | — |
| `cbkgen.pfnDestroyParaclient`（绝对） | **+192** | 40+0+152 | — | — |
| `cbkobj.pfnNewPtr／pfnDisposePtr／pfnReallocPtr`（绝对） | **+544／+552／+560** | 40+504+0/8/16 | — | — | 声明为 `IntPtr` 且**未接线** ⇒ 现场应为 **0** |
| `cbkwrd` 全组（绝对） | **+632 … +856** | 40+592+8k | — | — | **29 槽全部未接线** ⇒ 现场应为 **0** |

**编译期钉死（`t127` 形制）**：`src/WpfGfx.Linux.Native/src/win32_pts.c` 里新增 **13 条 `_Static_assert`** —— 组基址必须互为累加（`cbktxt == cbkgen + 32*8`、…、`cbkwrd == cbkfig + 3*8`）、`FSCBK` 大小必须等于 `103*8`、`fscbk` 必须 8 字节对齐、以及**七个目标槽的绝对偏移逐一钉死**（`56/80/136/144/168/176/192`）。**错一个就编不过**。

> ⚠️ **`_Static_assert` 只能钉"本文件自己的声明"**（编译期），**不能**证明托管侧/封送方的布局 —— 证明"封送方的布局确实如此"靠的是 §2／§3 的**现场只读回读**（跨边界）。

---

## §2 三个仪器与取法（**只读、不试调**）

| # | 仪器 | 位置（车道内／仓内） | 干什么 | **保证** |
|---|---|---|---|---|
| ① | **托管侧测量器**（运行期布局 API） | 车道 `~/t123-runner/logs/t133/offprobe/`（`offprobe.csproj` ＋ `Program.cs`；**不写仓**） | 反射取出真产物里的 `PTS/FSCONTEXTINFO`／`FSCBK`／`FSCBKGEN`… ⇒ `Marshal.OffsetOf`／`SizeOf` 现值 ＋ 反腿（错声明 `WrongCtx`） | **只读元数据**：既不实例化、也不调用任何回调 |
| ② | **托管侧 canary**（在仓内、**只打印**） | `build/PresentationFramework.Linux/PtsCache.Linux.cs`（`T133DumpFscbkCanary`，在 `InitGenericInfo` 装配**完成后**调用一次） | 打 `[FSCBK-CANARY] sizeof…` 头行 ＋ 每槽 `slot=<名> abs=<绝对偏移> fp=0x<16hex>\|NULL\|raw=0x…` | **只打印**：不写 `contextInfo` 任何字段、**不调用**任何回调、不改 `return`；异常只打 `NOINFO` 行 |
| ③ | **native 只读回读**（跨边界、现场字节） | `src/WpfGfx.Linux.Native/src/win32_pts.c`（`wpf_pts_fscbk_probe`，在 `CreateDocContext` 里调用） | 按实测偏移把 `FSCBK` 的 **103 个 8 B 字**逐字读出并打 `[FSCBK-WORD] off=… val=…`；打 9 个目标槽的 `[FSCBK-SLOT] … val/val_m8/val_p8`；与"预言的空槽位置"比对后打 `[FSCBK-PROBE] … fingerprint=PASS\|FAIL\|NOINFO` | **一个回调都不调**（试调错槽会崩；伪造 `nms`/`nmp` 会让托管 `HandleToObject` ⇒ `FailFast`）。窗口 `40..864` 对真结构（872 B）在界内；夹具结构已按同窗口**加宽** |

**对拍器（车道内）**：`~/t123-runner/logs/t133/join_check.py` —— 把①②③合到"同一绝对偏移"上判三条（EXACT／POLARITY／UNWIRED）＋ 第四条（native 的 `fingerprint=`）。**它自己带反腿**（`--shift ±8/±16`）。

**夹具反腿（车道内）**：`~/t123-runner/logs/t133/fixture_polarity.c` —— 直接 `dlopen` 新 `.so`，造**合成**结构跑四例（正控／错位／单槽污染／全零），**每个 `CreateDocContext` 都配一次 `DestroyDocContext`**（回收出参，不漏在 `g_pts_doc_live[]` 里）。

---

## §3 两极化读数（本件主证据）

### 3.1 夹具对**仪器**的两极化（`fixture_polarity`，现跑）

| 例 | 构造 | `[FSCBK-PROBE]` 实测行 | 判词 |
|---|---|---|---|
| **A 正控** | 按预言的空槽位置造（cbkobj 前三槽 0、cbkwrd 全 0、其余非 0） | `nulls=32 nonnull=71 pred_nulls=32 fingerprint=PASS` | **PASS**（观测 == 预言） |
| **B 反腿** | 空槽块**整体错位 +8** | `nulls=31 nonnull=72 pred_nulls=32 fingerprint=FAIL` | **FAIL**（且**不崩**） |
| **C 反腿** | 把一个"预言为空"的槽（`+552`）填成非 0 | `nulls=31 nonnull=72 fingerprint=FAIL` | **FAIL** |
| **D 反腿** | **全零**窗口 | `shape=synthetic-all-zero … fingerprint=NOINFO reason=synthetic-struct` | **NOINFO**（**不许**当 PASS） |

⇒ 三种判词**都可达** ⇒ 该指纹**不是恒绿**。四例 `CreateDocContext rc=0` ＋ `DestroyDocContext rc=0` ⇒ **无泄漏**。

### 3.2 对**真实结构**的两极化（app 内、同趟；`FSCBK_JOIN=PASS`）

`[FSCBK-WORD]`（native 按实测偏移读到的字节）与 `[FSCBK-CANARY]`（托管侧交出的**真实封送指针**）逐槽对拍 —— **`exact=10/10`（逐位相等）**；每槽的 `±8` 邻居**既不等于该槽、也不为 0** ⇒ `polarity=10/10`（分辨力）；未接线槽两侧都是 0 ⇒ `unwired_zero=4/4`：

| 槽（`cbkgen.`） | `abs` | native `val`（现场字节） | 托管 `fp` | EXACT | `val_m8`／`val_p8`（**两极化**） |
|---|---|---|---|---|---|
| `pfnFSkipPage` | 40 | `0x0000716ba50d10b0` | 同值 | ✓ | `-`（窗口下缘）／`0x…1410` ≠ |
| `pfnGetNextSection` | 56 | `0x0000716ba50d10c8` | 同值 | ✓ | `0x…1410`／`0x…10e0` |
| `pfnGetSectionProperties` | 64 | `0x0000716ba50d10e0` | 同值 | ✓ | `0x…10c8`／`0x…1428` |
| `pfnGetMainTextSegment` | 80 | `0x0000716ba50d10f8` | 同值 | ✓ | `0x…1428`／`0x…1440` |
| `pfnGetFirstPara` | 136 | `0x0000716ba50d1110` | 同值 | ✓ | `0x…14b8`／`0x…1128` |
| `pfnGetNextPara` | 144 | `0x0000716ba50d1128` | 同值 | ✓ | `0x…1110`／`0x…14d0` |
| `pfnGetParaProperties` | 168 | `0x0000716ba50d1140` | 同值 | ✓ | `0x…14e8`／`0x…1158` |
| **`pfnCreateParaclient`** | **176** | `0x0000716ba50d1158` | 同值 | ✓ | `0x…1140`／`0x…1170` |
| `pfnTransferDisplayInfo` | 184 | `0x0000716ba50d1170` | 同值 | ✓ | `0x…1158`／`0x…1188` |
| `pfnDestroyParaclient` | 192 | `0x0000716ba50d1188` | 同值 | ✓ | `0x…1170`／`0x…1500` |

未接线（应 0，实测 0）：`cbkobj.pfnNewPtr abs=544`／`pfnDisposePtr 552`／`pfnReallocPtr 560`／`cbkwrd.pfnGetSectionHorizMargins 632`。
整窗指纹（native 自判）：`nulls=32 nonnull=71 pred_nulls=32 fingerprint=PASS`（**3 个真实 doc 上下文各一次，全部 PASS**，`probes=3 pass=3 fail=0 synth=0`）。

### 3.3 对拍器自身的两极化（`join_check.py`）

| 腿 | 命令 | 结果 |
|---|---|---|
| 正腿 | `python3 join_check.py <app_g1.log>` | `rc=0` **`FSCBK_JOIN=PASS exact=10/10 polarity=10/10 unwired_zero=4/4 native_fingerprint=PASS`** |
| 反腿 +8 | `… --shift 8` | `rc=1` `FSCBK_JOIN=FAIL exact=0/10`（**必须红**） |
| 反腿 −8 | `… --shift -8` | `rc=1` `FSCBK_JOIN=FAIL exact=0/10` |
| 反腿 +16 | `… --shift 16` | `rc=1` `FSCBK_JOIN=FAIL exact=0/10` |
| 空日志 | `python3 join_check.py empty.log` | `rc=2` `FSCBK_JOIN=NOINFO reason=missing-lines`（**不许** PASS） |

**托管侧测量器绑定到"出货那一代"**：本件先后在**同一个**真产物上各测一次 —— 改前 `pf_sha256=2988f5154ecac5dd…`、改后（出货代）`pf_sha256=c52d9191feb5ba7c…` ⇒ 除 `pf_sha256` 行外**逐项 IDENTICAL**（`diff` 现跑）⇒ 换代不改布局，实测值对**跑出证据的那一代**成立。

---

## §4 同趟读数（读数批 `ts=2026-09-29T14:12:43 → 14:17:54 +0800`）

**代际（四值同）**：现盘 `.so=5ddc9d63b5232f96`／`PF Release=c52d9191feb5ba7c` ＝ 两腿 `DEV … shim=/pf=` ＝ `session.txt shim_sha16/pf_sha16` ＝ `sync-applocal --check`（`items=5 ok=5 drift=0`）。⚠️ **本趟换了代**（`.so a4bf2c47f8efb521→5ddc9d63b5232f96`、`PF 2988f5154ecac5dd→c52d9191feb5ba7c`）⇒ 按新口径，**在册 `evidence/**` 已同趟重取**（旧代备份在车道 `~/t123-runner/bak/evidence.pre-t133/`）。

**C3（N2：ENFE 面 ＋ 留痕面，缺一不得判绿）**：`enfe=0 epne=0 failfast=0 unrec=0 ptsgap=0 unavail=0 fontfb=6`；留痕面 `[FS_PAGE_GAP]` **1117** 行、`reason=` 唯一项 `paraclient-table-not-native`；`[HC-UNHANDLED]` **1117**（一一对应）；`ok=0 gap=1117`。⚠️ **跨代不相减**：`1123`（`t129`/`t131`/`t132` 那一代，载体 `evidence/**` 旧代）与 `1117`（本代，载体 `evidence/app_g1.log`、`log_sha16=84db0eb62d15e0b2`）**并列**，差不解释。

**N1–N4**：`N1`：帧 `ef3fd6765f18f51b`、`fr_ae_boot=15386>0`，但守卫现取 **`in_empty_set=yes`**（空态集现含该 sha）⇒ **帧身份这一半不成立**；`ink=480000` **boot/k23/k24 三帧同值** ⇒ 仍**降级为必要不充分**。**`N3`：红**（`k23=k24=ef3fd6765f18f51b`、去重 **1**、`AE(k23,k24)=0`；两腿 `ns=` 不同 ⇒ 无"同貌例外"）。`N4`：**`NOINFO`**（无正身份载体；`neptune` 命中 **0**）。⇒ **相位位不动**（裁定：翻转前置不满足）。

**症状面（单独不得当证据）**：两腿 `alive=yes app_rc=143 magenta=0 colors=383 ink=480000`；`NAMED managed_unavail=0`；`FAILLINE failfast=0 unrec=0`；`log_bytes≈551 KB`／3815 行。**写死**："净腿不崩＝假绿"本会话已三例；本件的证据是 **§3 的逐槽对拍**，**不是**"腿没崩"。

**C11 导出面**：`nm=594 ＝ exports.txt=594`、`^Fs=6`；**本件未增/删任何导出**（`--symbols` 现跑逐名清单未变）。

**`SRCS` 登记**：`build-shim.sh:34` 的 `SRCS` 数组 **10** 条 ＝ `src/*.c` 实际 **10** 件 ⇒ **差集 0**（本件未新增源件）。

**`F-3` 注释修正（同趟）**：`src/WpfGfx.Linux.Native/src/win32_pts.c` sha16 **`e4a091395a6cf63c → 26af5a26b984b99e`**；改法＝**只增不改**（原句 `void *fscbk; /* 占位：真身是委托（8 B）⇒ … */` **一字未删**，其后追加 dated 更正行：真身 ＝ `PTS.FSCBK` ＝ `{cbkgen 32／cbktxt 31／cbkobj 8／cbkfig 3／cbkwrd 29}` ＝ **103 槽按值 ＝ 824 B**，整结构 **872 B**；并写明"本占位只保证**前缀**偏移、`fscbk` 之后字段不能按它定位"）。**"纯注释、不动行为"的读数**：① 导出面 `nm=exports=594` 逐名未变、`^Fs=6`；② 两页症状面与上一代**逐格相同**（`alive=yes app_rc=143 magenta=0 colors=383`）；③ `ENFE=0`（未引发新的缺符号）；④ 唯一"行为性"改动是**只打印**的仪器及其**只读**窗口。

---

## §5 失效面与 `NOINFO`（逐条给"消掉需要什么"）

| # | 项 | 状态 | 消掉需要 |
|---|---|---|---|
| 1 | **反向通道**（托管侧按候选偏移读回 **native 写入**的已知值） | **`NOINFO(未做)`** —— 那需要 native 侧**写**结构（行为改动），本件守"只读" | 若队长要双通道：另开一件，写侧必须是"先证明该字段可写且不改变语义"的形态 |
| 2 | **`cbkfig`／`cbktxt` 全部槽**的逐槽 canary | 本件只对 **cbkgen 10 槽**做了 fp 对拍（其余由**整窗 103 字**的 `[FSCBK-WORD]` 覆盖：可事后按绝对偏移复核任一槽） | 直接读 §3.2 的 `[FSCBK-WORD]` 现册读数即可（**不需要**改件） |
| 3 | **`IntPtr` 型槽**（`cbkobj` 前三 ＋ `cbkwrd` 29）的"真实用途" | 只证"现场为 0／未接线" | 读上游语义（`Pts.cs` 只给声明）或等驱动链落地 |
| 4 | `N4` 正身份（该页专属期望指纹） | `NOINFO` | 登记一次已知良好渲染的帧 `sha256`（另派单） |
| 5 | **`t132` 的规模缺口**（50 个 `Fs*`／LS 13 个） | 本件**未动**（不是本件射程） | 驱动链单（`t132` §3 的第②③步） |

---

## §6 「假进度必红」P1–P9 处置（本件形态）

| # | 假形式 | 本件处置 |
|---|---|---|
| **P1** | 只改计数/声明 | **不适用**：本件改的是**真仪器**（托管 canary ＋ native 回读），读数来自现场字节 |
| **P2** | `return 0` 无副作用 | **不适用**（本件未动任何 `return`）；仪器对**每次**调用都留痕（`[FSCBK-PROBE]` 计数 `probes=…`） |
| **P3** | 吞 `ENFE` | **两格都给**（C3） |
| **P4** | 交伪句柄 | 本件**不交值**；且**明禁**试调（§2 保证栏） |
| **P5** | 两页帧相同却报绿 | **如实判红**（`N3`） |
| **P6** | `ink>0` 当内容证据 | **降级**（三帧同值） |
| **P7** | `ns=` 当身份 | **不使用**（`N4` 记 `NOINFO`） |
| **P8** | 跨趟/跨代拼读数 | 本件给**载体＋`ts`＋代际**三元组；**跨代不相减**（`1117` vs `1123` 并列） |
| **P9** | 恒绿自检 | **本件正面回答**：仪器三种判词全部可达（§3.1 A/B/C/D）＋ 对拍器三条反腿必红（§3.3）＋ 空日志必 `NOINFO` |

---

## §7 纪律与边界自证

- **纪律 30（三格 ＋ 调用序）**：测量仪器的三格 —— ① **进程/调用史**：app 侧 native 计数 `probes=3 pass=3 fail=0 synth=0`（＝3 个**真实** doc 上下文，全在界内、全 PASS）、托管 canary **3** 个头行 ＋ **42** 条槽行；夹具侧 **4** 例（各自 `create/destroy` 成对）。② **关键前置量**：`fscbk_off=40 window=824`、`nulls=32 nonnull=71 pred_nulls=32`、3 个 `info` 地址各不相同。③ **判词**：`FSCBK_JOIN=PASS exact=10/10 polarity=10/10 unwired_zero=4/4 native_fingerprint=PASS`。
- **纪律 28（`cell=#1`）**：本件**改了覆盖面内件**（`win32_pts.c` `in_fp=1`、`tools/pts-gap-decl.txt` `in_fp=1`、`evidence/**` `in_fp=1`）⇒ 触发**成立** ⇒ 纯 `>>` 追写 `cell=#1`。**两次登记的如实记**：第 1 次 `ts=14:14:20` 值 `6d3ac906…`（取值在**本席最后一次自改覆盖面件**之后）；其后**他者**又动了覆盖面内件（现取 `build/MilBridge/tools/pts-pages-guard.sh` `mtime=14:14:30`，**晚于**本席 ts；该件属 `tools/**`、不在本席写域）⇒ `HANDOFF_MV` 一度 `DIVERGED #1:covered-file-changed-since-ts`；第 2 次按契约**再登记一次**（`ts=14:15:3x`）⇒ **复跑 `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`**。⚠️ 第 1 次记录被**内层双引号未转义**的追加命令拆成 6 行（**机器值部分有效**，已用 python 追加**单行完整补记**；此后本席**不再追写**，移动靶位移归其所有）。
- **纪律 29（备份面 ≡ 改动面）**：改动面 5 件 ＋ 载体 ＋ `HANDOFF-NEXT`；备份面 ＝ `~/t123-runner/bak/{PtsCache.Linux.cs.pre-t133, win32_pts.c.pre-t133, pts-gap-decl.txt.pre-t133}` ＋ **整个旧代证据目录** `~/t123-runner/bak/evidence.pre-t133/`（`app_g1.log 27f8a56e3960ff76`／`leg_23.env 575e3b5896d4fb67`／`leg_24.env d216b2a984968bc6`／`session.txt f56d401c189a0b1d`）。**无 `cp -p` 回拷**（无回拷对象）；重建按 build-shim／dotnet build 正常路径。
- **重活走槽**：三次重活全部 `bash ~/heavy-slot.sh … -- <cmd>`（构建 `held=47s`、重建+同步 `held=3s`、腿 `held=30s`），日志 `logs/t133/{build,rebuild_sync,legs}.out`；**未 `tee` 回灌**。
- **资源线**：跑前 `MemAvailable 3545432 kB`（另一次 7390036）／跑后 `6154440 kB`，`SwapFree ≥ 1391100 kB`，`df` 可用 **≈69 GB** ⇒ 全程 ≫ 停手线。
- **显示位／进程**：只用 `:237`（本趟 `W67_DISPLAY=:237`），**未 pkill／pgrep -f**；`/tmp/.X11-unix/` 现取仅 `X0`／`X1`（非本件所起）⇒ 腿自起的 X 已按其自身 PID 收净。
- **相位位**：**未动**（`N1` 半要件不成立 ＋ `N3` 红 ⇒ 翻转前置不满足）。
- **边界**：改动面 ＝ `src/WpfGfx.Linux.Native/src/win32_pts.c`、`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（**只改 `so16=` token**）、`build/PresentationFramework.Linux/PtsCache.Linux.cs`（canary 侧）、`build/MilBridge/tests/PtsPagesProbe/evidence/**`（同趟重取）、本件、`HANDOFF-NEXT.md` 的 `cell=#1` 行 ⇒ **全部在写域内**；**未**改上游／`tools/**`／装置本体／生成件／判据件／哨兵／`docs/ROUTES.md`／`samples/**`；未跑整趟门禁；未 `git add/commit/push`。

---

## §8 收尾牙（受影响者；逐个捕获 `rc`）

| 牙 | `rc` | 现取读数 |
|---|---|---|
| `handoff-machine-values-check.sh` | **0** | `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none` |
| `sync-applocal.sh --check ~/w67-work/app` | **0** | `SYNC-APPLOCAL=PASS items=5 ok=5 synced=0 created=0 drift=0` |
| `report-id-domain-check.sh` | **0** | `REPORTID=PASS files=264 ids=2207 declared=224` |
| `sentinel-spec-check.sh` | **0** | `SSC=PASS lines=13 keys=13 cmp=IDENTICAL`（`SSC_VALUE=PASS key=WAVE v=w80-freeze`） |
| `pipefail-sigpipe-check.sh` | **0** | `PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 files=114 sites=105 hit=0` |
| `static-jaws-check.sh` | **0** | `STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62` |
| `check-export-numbers.py` | **0** | `[绿] 清单表与所有消费点一致` |
| `pts-gap-count-check.sh` | **1** | `PTSGAP=FAIL tool=90 dead=11 artifact=1 ops=78 impl=81 **so16=5ddc9d63b5232f96** exports=594`；**`so16` 的那条 `DRIFT` 已由本件同步消掉**（`decl a4bf2c47f8efb521→5ddc9d63b5232f96`）；**唯一残留** ＝ `SITE-DRIFT docs/ROUTES.md impl want=81 got=87`（`t123`/`t127`/`t129` 同一条，**不在本件写域**） |
| `pts-pages-guard.sh --legs <D>` | **1** | `PTS_G10_NAME=PASS observed=FsQueryTrackParaList`；`PTS_N1=INFO`（两腿，`in_empty_set=yes`）；`PTS_ENFE=INFO total=0`；`PTS_GUARD=FAIL`（degraded 期既有红，**非本件引入**） |

**说明**：上表全部只读现跑；`pts-pages-guard.sh` 的 `FAIL` 项与本件无关（degraded 期既有 fail 集），但其中的 **`PTS_N1 … in_empty_set=yes`** 是本趟**新出现**的收紧（空态参照集现含 `ef3fd6765f18f51b`，**非本件所改**），已如实登记。

---

## §9 追记（同趟末采；append-only）

本件主体写完后**又现一次覆盖面位移**，如实登记、**不追写**：

- 现取 `inputs_fp`（本件交付时刻）＝ `6d64b0821de1234ad19ca52d4e03c380e9f2addebfd60bae0f166c64f6c1291a`。
- **本席自己**最后改的覆盖面内件 ＝ `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（现取 `mtime=2026-09-29 14:14:13`）；其后的两次 `cell=#1` 登记（`ts=14:14:20` 值 `6d3ac906703055f9c64518f7871c76051c9155bd38ffb5bd2ad66821bfd9c1b3`；`ts=14:15:3x` 值 `0d4ba945fd210893e6a4c5b7cd0b8a67d71df828e87711bb023674376c24583b`，**复跑 `HANDOFF_MV=PASS`**）**在各自取值时刻都正确**。
- 其后**他者**又改了覆盖面内件（现取 mtime：`build/MilBridge/tools/pts-pages-guard.sh` **14:14:30**、`build/MilBridge/tools/pts-gap-count-check.sh` **14:19:21**；两者均属 `tools/**`、**不在本席写域**）⇒ `HANDOFF_MV` 现势 `DIVERGED reason=cell-mismatch #1:covered-file-changed-since-ts`。
- **本席不再追写**（移动靶：位移归其所有，收口对齐由队长统一做）。
- 载体与 `build/MilBridge/HANDOFF-NEXT.md` 均**不在** `fp_inputs()` 覆盖面内（现取 `in_fp=0`）⇒ 本件对载体的收尾写入**不会**再动指纹。

**表述纪律再申**：以上全部只支持「**偏移测量有了可复核的机器证据**」；**不**推出"驱动链已通"，**不**推出"排版打通"。

`P1-FSCBK-OFFSETS 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ a919bea0ef82ad53（末行＝本行）`
