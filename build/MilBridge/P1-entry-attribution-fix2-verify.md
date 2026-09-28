# P1-ENTRY-ATTRIBUTION-FIX2-VERIFY（`t91` 独立复核 · W19「`t88` 余项处置」· `t90` 的件）

> **本席只读仓树、只写本件。** 复核对象＝**入账面**：`e5327ab`（`fix(#81): t90 t88 余项处置 …`，`2026-09-29T00:30:05+08:00`），面 = `PtsCache.Linux.cs +92/−21`／`P1-entry-attribution-fix2-report.md +179`／`P1-entry-attribution-verify.md +141`／`HANDOFF-NEXT.md +1`（`git show e5327ab --numstat` 现取，**无 `src/**`**）。
> **本席现取（`ts=2026-09-29 00:33:21.556379119 +0800`，`HEAD=e5327ab`）**：`build/PresentationFramework.Linux/PtsCache.Linux.cs` `6c4913b9ef462294`（1307 行／83583 B／mtime `00:22:44`）｜`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` ＝ **部署件** `/home/links-dev/w67-work/app/PresentationFramework.dll` **两件同值** `83ba5884bb603296`（6125056 B／mtime `00:23:19`）｜`build/MilBridge/tools/pts-pages-guard.sh` `944e61f39f24631c`｜`P1-entry-attribution-fix2-report.md` `b3c5f2cfc1336e4c`｜`HANDOFF-NEXT.md` `400171e13c4cc307`。
> ⚠️ **native 极的钉法（本席自己决定并写清理由）**：本件复核的是**托管侧**处置，而 `src/**` 正在被**另一个写者（`t92`／W20）现场改**（`win32_pts.c` `M`、`+130/−2`，`libwpfwin32.so` 于 `00:31:07`→`00:32:02` 连改两次：`8b984cd395a0537e`→`657f448c2077ba1f`）⇒ 本席把 native 极**钉在被部署的 `3bd193e54785b5db`**（`/home/links-dev/w67-work/app/libwpfwin32.so`，mtime `2026-09-28 23:15:23`，＝`t86` 在册证据的 `DEV shim`）上跑夹具；这也是 `t90` 提 F-3 时的那版裸口。**非部署极的一次旁读**单独标注（见 `O-2`）。
> **仪器全部本席自造、仓外、零构建**：夹具 M＝`pwsh 7.6.6` **反射**现成产物（`Assembly.LoadFrom` ＋ `DllImportResolver` 指向钉住的 `.so` ＋ `Reflection.Emit` 造原生调用委托）；夹具 O＝按 `git show 9d8a0af:` 原文字面的**等价模型**（已标"非产物读数"）；夹具 G＝`pts-pages-guard.sh --g10-name <仓外目录>`。

---

## ① `F-1` 库名形状：**扩到刚好覆盖真件**，且**没有宽到吃任何带点串**（成立）

**真件名形来源（本席自己取）**：在册证据 `evidence/five_pre_g1.txt`（`b4cd0fc5799063b7`）现取第二行为 `wpfgfx_cor3.so=4e25e4b27d4d5ae1`；`libwpfwin32.so=3bd193e54785b5db` 同件第一行；`libfoo.so.1.2` 为本席自造的"带多段版号的 .so"形。

**A/B（旧极 ＝ 按 `git show 9d8a0af:` 原文字面的等价模型，⚠️非产物读数；新极 ＝ 现盘产物 `83ba5884bb603296` 的 `IsLibraryNameShape`/`EntryNameFromException` 现取）45 格，20 格变**：

| 名 | 旧字面 | 新产物 | 新产物 `entry=` 值 |
|---|---|---|---|
| `wpfgfx_cor3.so`（**本栈真件**） | False ⇒ `unknown` | **True** | `dll:wpfgfx_cor3.so` |
| `libfoo.so.1.2` | False ⇒ `unknown` | **True** | `dll:libfoo.so.1.2` |
| `wpfgfx_cor3.so.1` / `WPFGFX_COR3.SO` / `/opt/x/y/wpfgfx_cor3.so` | False | **True** | `dll:wpfgfx_cor3.so.1` / `dll:WPFGFX_COR3.SO` / `dll:wpfgfx_cor3.so`（去目录） |
| `lib.so`／`x.so`／`a.so`／`a.b.so`／`a+b.so`／`a-b.so`／`a_b.so`／`x.so.1`／`x.so.01` | False | **True** | `dll:<名>` |
| `libwpfgfx.so`／`libfoo.so.1`／`x.dll`／`PresentationNative_cor3.dll`／`NotImplemented.dll` | True | True | `dll:<名>`（未变） |
| **收紧 3 格**：`lib foo.so`／`lib:1.so`／`lib=1.so` | **True**（旧码真收） | **False** | `unknown` |
| **仍拒（25 格）**：`NotImplemented`／`foo.bar`／`v1.2`／`x.txt`／`unknown`／`dll`／`.`／`..`／`..so`／`.so`／`.dll`／`foo.sox`／`a.so.`／`a.so..1`／`wpfgfx_cor3.so.x`／`libfoo.so.1.beta`／`a b.so`／`a\b.so` … | False | False | `unknown` |
| `a/b.so` | False | False（整串） | `dll:b.so`（先取 basename 再判形，正确） |

- **判**：**成立**。放宽的落点**恰是本栈真件名形**（`wpfgfx_cor3.so` 一族、`lib` 前缀不再必需、多段版号）；同时**新增字符面收紧**（空格／`:`／`=`／控制字符一律拒）⇒ **不是"含点即收"**：45 格里 **25 格**仍判 `unknown`，且**所有无 `.so`/`.dll` 后缀者全拒**（`foo.bar`／`v1.2`／`x.txt`）。
- **过宽候选（本席点名，见 `G-3`）**：`a..so`（空段）、`-x.so`／`+x.so`（前导符号）新收 ⇒ 与注释里"茎非空"的说法不完全一致；但**不影响判据面**（`G10` 的绿仍要求名字**在册**，形状只决定字段文本，见 ④）。

## ② `F-3` 长度纪律：**真落地**，且**截断名到不了判据端**（成立）

**夹具 M `gapcaps`（同一进程、同一台账：先打一次 `LoAcquirePenaltyModule`，`GAPCOUNT=1`，真名 `len=22`）**，两列都现取：

| `cap` | native 裸口 `WpfLinuxWin32_PtsGapEntryName` | 托管新读口 `GapEntryNameAt` |
|---|---|---|
| 4 | **rc=1** name=`LoA`（截断却成功） | **`<null>`** |
| 5 | **rc=1** `LoAc` | **`<null>`** |
| 7 / 8 / 9 | **rc=1** `LoAcqu` / `LoAcqui` / `LoAcquir` | **`<null>`** |
| 12 | **rc=1** `LoAcquirePe` | **`<null>`** |
| 21 / 22 | **rc=1** `LoAcquirePenaltyModu` / `…Modul` | **`<null>`** |
| **23（＝`len+1`，裸口已给全名）** | rc=1 `LoAcquirePenaltyModule` | **`<null>`**（保守判，见 `G-5`） |
| 24 / 25 / 31 / 32 / 33 / 64 / 127 / 128 / 129 | rc=1 全名 | **`LoAcquirePenaltyModule`** |

- ⇒ **纪律成立**：`cap` 从 4 到 23（含恰好放得下那一档）**一律不给名**，只从 `cap=24`（＝真长＋2）起给真名；**没有任何 `cap` 能让托管侧返回截断名**。
- **判据端认不认得？** 它**不需要**认新标记：`GapEntryNameAt` 取不到 ⇒ `null` ⇒ `NativeEntryName()` 落入既有 ③/④ 路（`anchor=`／`frontier=`／`unknown`），**没有引入任何新 token** ⇒ 判据端（`pts-pages-guard.sh`、`pts-gap-count-check.sh`）逐字未变、无需改判。**不存在"判据端认不得的标记"** ⇒ 不判红。
- **端到端"骗判据"夹具（夹具 G，仓外 `--g10-name`，现取）**：`entry=LoAc`（**真截断产物**）⇒ `PTS_G10_NAME=FAIL frontier=LoAc off-roster=LoAc roster=12 domains=unattributable` **`rc=1`**；`entry=LoNotARegisteredEntZZ`（伪造）⇒ 同**红** `rc=1`；`entry=LoSetDoc`（**是**在册真名、非截断产物）⇒ `PASS … domains=pts-declared` **`rc=0`**；`entry=LoAcquirePenaltyModule`（真名）⇒ `PASS … domains=pts-declared` **`rc=0`**。
- **"假绿是否可达"我自己算**：名册 12 名**前缀包含对 ＝ 0**（有序对全枚举）；最长名 `LoGetPenaltyModuleInternalHandle` ＝ **32 B**，`GapNameCap=128` ⇒ 富余 **95 B**。⇒ 今日截断名**无路**落进在册（只会**假红**），假绿只是潜在面、由两侧纪律一起关掉。
- **调用点自证**：托管件里 `PtsGapEntryNameNative` 只出现在**声明处**（`:975`）与 `GapEntryNameAt` 内（`:1071`），`NativeEntryName()` 走的是 `GapEntryNameAt`（`:1012`）⇒ **没有漏网的裸调用点**。

## ③ `F-2`／`F-4`／`F-5`／`O-1`：逐条"改实现 vs 写口径句"

| 条 | `t90` 落法（我现取判） | 本席读数 | 判 |
|---|---|---|---|
| **`F-2`** 措辞短路 | **改实现**：`libWording` 循环里 `return "unknown";` → **`continue;`**（代码：`:1127-1134` 现取） | `C05`＝`'NotImplemented'` 在前段命中、同串后段 `in DLL 'x.dll'` 合法 ⇒ 现取 **`dll:x.dll`**（修前为 `unknown`）；`C14`（两条措辞都不合法→第二条合法）⇒ **`dll:y.dll`**；`C16`（两条都非法）⇒ `unknown`；`C15`（闭合引号缺失）⇒ `unknown` | **成立**（行为面＋代码面两证） |
| **`F-4`** 注释与实现不符 | **只改注释**（实现仍取在册表序末名） | 多缺口态（夹具 M `multigap`：先调 idx7 `LoAcquirePenaltyModule`、后调 idx4 `GetFloaterHandlerInfo`）：`COUNT=2`；`GapEntryNameAt(0)=GetFloaterHandlerInfo`（表序首）／`(1)=LoAcquirePenaltyModule`（表序末）／`(2)` 越界；报表 `anchor=GetFloaterHandlerInfo frontier=LoAcquirePenaltyModule`；**`NATIVE_ENTRY=LoAcquirePenaltyModule`** —— 而**最近被调**的是 `GetFloaterHandlerInfo` ⇒ 实现**确非 recency**，与新注释「**在册表序**最后一个…」**一致** | **成立**（改注释比假称改了实现诚实；且注释现与实现同义） |
| **`F-5`** `A1_STUB_ERR` 与真值同值 | **只登记不改值**（注释明说"本件不改值…需另派单"） | `A1_STUB_ERR=` 现取 **`-10000`**（反射读常量）；`NativeError()`：全新进程 **-10000**（`report_len=250`）、台账打起来后 **-10000**（`report_len=292`）⇒ `err=` 面**仍无法自证读到没读到** | **诚实**（改值会动在册判据面 `native_err=`；登记＋另派单是对的处置） |
| **`O-1`** `-1` 时 native 已写 `buf[cap-1]='\0'` | **写口径句**（native 未改；现取 `RAWREPORT cap=250/251/256 ⇒ rc=-1`，`cap=300 ⇒ 292`） | 托管侧 `NativeReport()` 一律 `rc <= 0 ⇒ continue`（代码 `:1214-1220` 现取），**先看 `rc` 再看 `buf`** ⇒ 口径与实现一致 | **成立**（口径句＋实现已符合该口径；`t92` 正在 native 侧把它变成机器可读断言，见 `O-2`） |

## ④ 不许放宽：PTS 域唯一绿门**仍是** `k_pts_entries[]`；例数**未下降**；判据件**未被本件改动**

- **判据件逐位对拍（现取）**：`pts-pages-guard.sh` `944e61f39f24631c`（＝`t88` 时同值）｜`P1-ptsname-criteria.md` `aa72a215d411e806`（＝`t88` 时同值）｜`P1-w8-step1-criteria.md` `40d8460366461d02`（＝`t88` 时同值）；且 `git show e5327ab --numstat` 现取**只有 4 件**（`HANDOFF-NEXT.md`／`fix2-report.md`／`verify.md`／`PtsCache.Linux.cs`）⇒ **判据件本件零改动**。
- **`--selftest` 现取**：`PTS_GUARD_SELFTEST=PASS pass=40 fail=0`（`rc=0`）。⚠️ **"例数不得下降"的严格比较 ＝ `NOINFO`**（本席**从未**有余） —— 但**等价证明成立**：`pts-pages-guard.sh` 本件**逐位未改**（上条 hash ＋ 未列入 `numstat`）⇒ 例数**不可能**因 `t90` 下降。
- **PTS 域唯一绿门未放宽（三格我自己造）**：真名 ⇒ `PASS … roster=12 domains=pts-declared rc=0`；伪造名 ⇒ `FAIL … off-roster=… domains=unattributable rc=1`；非 PTS 声明形（`AbortPrinter`，声明在 `.hpp`）⇒ `FAIL … unattributable rc=1`（`decl_hit()` 域是 `--include='*.cs'`，`:151` 现取）。判序仍是「① 在册表 ⇒ `pts-declared`；② 声明树 ⇒ `dllimport-entry`；③ 都不中 ⇒ 红」，**①「先在册表」未动**。

## ⑤ 现树正极 ＋ 零回归（＋ ⚠️ 同趟性断裂，见 `G-1`）

- **正极（现取）**：`bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` ⇒ **`rc=0`**；
  `PTS_G10_NAME=PASS observed=LoAcquirePenaltyModule names=1 roster=12 domains=pts-declared（形态判据：具名行**在在册名单内**；PTS 域不写死任何名字）`；
  `PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded`。在册 `app_g1.log`（`e348b4ef70ab521e`）现取 **`3 entry=LoAcquirePenaltyModule`**。
- **零回归成对（现取 `git diff ac29ff1^ ac29ff1 -- evidence/leg_2*.env`）**：

| 面 | k=23 | k=24 |
|---|---|---|
| `alive` | `yes → yes` | `yes → yes` |
| `app_rc` | `143 → 143`（∉{134,139}） | `143 → 143` |
| `magenta` | `50461 → 49943` | `55051 → 54533` |
| `ink` / `colors` / `ns` / `ae` | `428004→428456`／`844→844`／逐字同／`140247→141283` | `423346→423798`／`851→852`／逐字同／`221246→221857` |
| `native_gap` / `native_err` | `0 → 1` / `- → -10000`（degraded 期设计内） | 同 |
| `DEV shim` / `pf` | `2a5165700a8c8579→3bd193e54785b5db` / `8ef62d37e7c2ce2e→b3f0d129f0234b58` | 同 |

  同一趟 runner 日志现取：`2 unh=0`，`CLICK k=24 … AE=221857 … pts_unavail=1 pts_gap=1 guard=1 fatal=0 unh=0`、`CLICK k=23 … AE=141283 … pts_unavail=2 … unh=0`（两个 `AE=` 与本件在册 `ae=` **逐位相同** ⇒ 同一趟）。⇒ **无 134/139、两页 alive、`unh=0`**。
- ⚠️ **`G-1`（medium）同趟性（`pf` 轴）已断**：在册 `DEV … shim=3bd193e54785b5db pf=b3f0d129f0234b58`（`t86` 重取时的部署件），而**现盘 Release ＋ 部署件 ＝ `83ba5884bb603296`**（`t90` 于 `00:23:19` 重建）⇒ 门禁真读的证据与**现树产品件不同趟**（`shim` 轴仍同）。**本席现取全仓无判据读 `DEV shim`/`pf`**（只有 `pts-pages-guard.sh:456` 在自检夹具里**写**一条假 `DEV` 行）⇒ 今日不构成红，但 `t86` 挣来的"同趟可归因"只维持到 `t90` 重建之前 ⇒ 收尾前需一次**换代（重跑腿，写者域）**。

## ⑥ 不变量 / 指纹 / 哨兵 / `D-G189`

- **覆盖面**：`bash ~/w153a/bin/infp.sh list` 现取 **234** 条；**含** `src/WpfGfx.Linux.Native/src/win32_pts.c`（第 `129` 行，登记值 `823298d182c6d271851e4c871f48594fd341f7b361dd41f01b8e3e979c692835`），**不含** `build/PresentationFramework.Linux/PtsCache.Linux.cs`（`grep PtsCache` 命中 0）、不含 `HANDOFF-NEXT.md`／`fix2-report.md` ⇒ **`t90` 的四件改动面都不在覆盖面内**。
- **`inputs_fp`（写清取值时刻，且在飞）**：`ts=00:30:48` ⇒ `9e16961da6c110d135c0b2c58da2452da132cabe6f2cca02cf3ebd3939a156cd`；`ts=00:32:45`／`00:32:57`／`00:32:59`／`00:33:01` 均 ⇒ **`f4a21769b3d6399339d9ddb2dc99ec106ca6b4e345803d46b36be508abf15834`**（三连取同值 ⇒ 稳定在新的档）。
- **`HANDOFF-NEXT.md` 的 `cell=#1` 是否一致**：末条（`:627`）登记 `ts=2026-09-29T00:27:33.322097022+0800` 时现值 ＝ `18e07fc22ff246f64cd1ff20fa8b2be638f646bceee…`（`:626` 同值，`ts=00:16:25`）⇒ **与最终现取 `f4a21769…` 不一致**。**成因我自己定位**：`infp.sh list` **含** `win32_pts.c`，而该件**正在被 `t92`／W20 现场改**（`porcelain` `M`，mtime `00:31:51`）⇒ 是**在飞件**推动指纹，**不是 `t90` 的改动面**（`t90` 四件均不在覆盖面）。⇒ 按纪律：**登记值不许改写**，本次不一致如实记，需在飞者落地后再取一次。
- **两哨兵**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**（文件 sha16 `ef97d026f99ce450`）；字段现取 `PF=83ba5884bb603296`、`WIN32SHIM=3bd193e54785b5db` ⇒ **两键与现盘产品件相符**（`PF` 已随 `t90` 重建更新、`WIN32SHIM` 未动）⇒ **不该重写**。
- **`D-G189` 有无被虚假扩大**：**无**。现取 `git show e5327ab | grep -c 'D-G189'` ⇒ **0**；`git show e5327ab --numstat` 里**无** `KNOWN-DEFECTS.md` ⇒ 本件未碰注册表；注册表现取 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` `a92e6e73f2a4f4a5`（mtime `2026-09-28 23:23:19`，最近提交 `800d0e1`＝`t81` 那笔），`D-G189` 出现 **3** 次（正条 `:3860` ＋ 「第二面」`t82` 追加行 `:3872`）⇒ **面数未增**。旁证：`defect-registry-check.sh` 现取 `DEFREG=PASS declared=224 route_ids=224`（`rc=0`）、`DEFREG_ROUTES=KD=a92e6e73f2a4f4a5`（＝注册表现值，自洽）。

## ⑦ 载体与边界自证

- **唯一写入** ＝ `build/MilBridge/P1-entry-attribution-fix2-verify.md`（新建，UTF-8，首记号 `# P1-ENTRY-ATTRIBUTION-FIX2-VERIFY`，**非** `# ⏪ `，`mode 644`，末行自带可复算自报口径 sha16）。
- **未改任何 `t90` 件**：`PtsCache.Linux.cs 6c4913b9ef462294`／Release＋部署件 `83ba5884bb603296`／`P1-entry-attribution-fix2-report.md b3c5f2cfc1336e4c`／`P1-entry-attribution-verify.md b259bcb94db89ac3`／`HANDOFF-NEXT.md 400171e13c4cc307` —— 复核前后同值（件头与本条两次现取）。
- **边界**：只读仓树；**未**跑整趟门禁、**未**构建、**未**跑腿、**未**占显示位、**未** `git add/commit/push`；夹具（`mprobe.ps1`／`old_shape_model.py`／`ctypes_gapname.py`／`ft/**` 四格／各 `*.out`）**全部在 `~/wv88y/t91/` 仓外**，收尾**删净**（仓内残留仅本件）。
- **判词可复现**：夹具脚本已删，但每条结论都带**命令原文＋读数＋件 hash**；主读数落在现盘可复算的件上（`pts-pages-guard.sh --selftest|--legs|--g10-name`、`infp.sh list|fp`、`defect-registry-check.sh`、`git show/diff`、`reflection` 现取）。

## Findings（不改 `t90` 任何件；要改的以「夹具＋读数」给出）

- **`G-1`（medium）同趟性（`pf` 轴）断裂**：在册 `DEV … pf=b3f0d129f0234b58` vs 现盘 Release/部署件 `83ba5884bb603296`（`t90` 重建）⇒ 门禁真读的证据**不**与现树产品件同趟（`shim` 轴仍同）。今日无判据读该字段（我 grep 过全仓）⇒ 不是红，但收尾前需一次**在册证据换代**（写者域）。
- **`G-2`（low）①路仍短路**：入口名措辞命中而**入口名形状不合**时直接 `unknown`，**不再看**后面的 `in DLL 'x.dll'` 这种合法库名措辞（夹具 M `C12`：`"… named 'Lo Ac' in DLL 'x.dll'."` ⇒ **`unknown`**）。与 `F-2` 的新口径（②路 `continue`）**不对称**；修法同 `F-2`（形状不合 ⇒ `continue`），但需先确认不会把"真入口名被误当库名"。
- **`G-3`（low）两处过宽**：`a..so`（空段）、`-x.so`／`+x.so`（前导符号）现判 **True**。不影响判据面（`G10` 绿需在册命中），但与注释「茎非空」的字面不符。
- **`G-4`（low）注释数字错**：`GapNameCap` 的注释写「现册最长名 `LoGetPenaltyModuleInternalHandle` ＝ **31 B**，…有 **96 B** 富余」；我现取该名 **32 B** ⇒ 富余 **95 B**（结论不变，数字需正）。
- **`G-5`（low／保守）富余判据多收一档**：`nm.Length >= cap-1` ⇒ **`cap == 名长+1`（native 恰好放得下、且已给出全名）也被判 `null`**（实测 `cap=23 ⇒ <null>`、`cap=24` 才给名）。生产 `cap=128` ⇒ 无实际影响；但它让"恰好放得下"与"被截断"**不可区分**（属收紧，不是放松）。若要与 `t92` 的 native 新语义对齐（native 放不下 ⇒ `0`＋空串），托管侧可改为"native 返回 1 ⇒ 即真名"。

## `NOINFO`（不折绿、不折红）

1. **①的修前产物读数**：旧 Release 件 `b3f0d129f0234b58` **已不在盘**（全深度同名件只剩现盘 1 份）⇒ 旧极只能给**字面等价模型**（已逐格标注"非产物读数"）。
2. **④"例数不得下降"的跨代比较**：本席此前**从未**跑过 `pts-pages-guard.sh --selftest`，无自有前值 ⇒ 严格比较 `NOINFO`（以"判据件逐位未改"作等价证明）。
3. **`O-2`（并发观察，非本件缺陷）**：`t92`／W20 正在 `src/**` 落 native 侧 `F-3`／`O-1` 真修（`win32_pts.c +130/−2`；`libwpfwin32.so` `00:31:07`→`00:32:02` 两改：`8b984cd395a0537e`→`657f448c2077ba1f`）。**非部署极旁读一次**（用未部署的新 `.so`）：同一夹具 `gapcaps` 下裸口对 `cap=4/5/12/22` ⇒ **rc=0 ＋ 空名**（＝"放不下就不给名"），托管侧同档仍 `<null>` ⇒ 两侧纪律**相容**、不冲突。该极**不在本件复核范围**（属 W20）。
4. **重编译副本型反腿 / 整趟门禁 / 真实显示面**：本任务禁构建、禁跑整趟门禁、禁占显示位 ⇒ 未跑（⑤只用现盘判据与成对读数）。

SELF-SHA16 （口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 9a40cc8ff36b6cae
