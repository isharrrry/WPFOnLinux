# `P1-freeze82` 报告 —— 波 `#82` 重冻入册（`T-B22`）· 装置/收尾趟 —— ⛔ **未冻（前置门禁非绿）**

**车道**：`T-B22`（本轮唯一写者）｜**车道目录**：`~/w21-verify/w82/`（`bin/`＝链脚本、`logs/`＝链条日志、`gate/`＝门禁 rows、`freeze/`＝沙箱副本与记录模板）｜**全程 `temp+rename`**（基线由冻结器写；**本轮**冻结器**未写盘**）｜**重活全走 `~/heavy-slot.sh --min-avail 2500 --max-hold 7200 --wait 3600`**｜**进程只按 PID**｜**未 `git add`／`commit`／`push`**

**结论一句话**：**冻结未执行**。派单前提「`verify-all` `64 ✅ / 0 ❌`」**被现场推翻** —— 本趟独立跑 `verify-all` **两趟**，分别 `59 ✅ / 5 ❌` 与 `60 ✅ / 4 ❌`；**四红两趟复现**（`R-GATE（连续交互）`／`FP-MANIFEST-TEETH`／`ROOT-ENTRIES`／`STATIC-JAWS`）。冻结器**结构上要求**冻前日志 `nfail == 0`（或只余声明类红）⇒ **本状态下任何一代都冻不成**；且四红的根因**逐条落在本趟写域之外**（`verify-all.sh`／`build/MilBridge/tools/**`／`src/**` 均在黑名单）⇒ **按硬边界「任何断言失败即如实报停止，绝不放宽/绕过」停手**，**未改任何黑名单件**。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| ① 前置排练（沙箱副本） | ✅ `PREVCHECK=PASS gen=#82 keys=7 checked=7 skipped=0`／错值档 `PREVCHECK=REFUSE`（`rc=2`）／沙箱基线**零字节改动** |
| ② 新一代常数（只追加） | ✅ `GENS['#82']` 已**追加**（`~/w21-verify/w27-freeze.py`；老代一字未改）＋ `w82-pre.sha` 已建 |
| ③ 应用门禁 ×2 | ✅ 各 `rows=6` 全 `result=PASS`、`WPTD_GATE=PASS acceptance=2/2`、判词行 `GATE_LINES_IDENTICAL=yes` |
| ④ 冻前 `verify-all` ×2 | ⛔ **`59✅/5❌`**（`17:23:55` 起）／**`60✅/4❌`**（`17:43:49` 起）—— **非绿** |
| ⑤ 冻结（写盘） | ⛔ **未执行**（前置不满足；冻结器必 `AssertionError` 于 `结论：✅ 全部通过` 那条断言） |
| ⑥ 其余六闸（现取 `rc`） | ✅ `SSC`／`HANDOFF_MV`／`DEFREG`／`REPORTID`／`COLUMN_FLOOR`／`ARMLOG_SHA` **全 `0`** |

---

## §1 已完成的三件事（**证据现取**）

### 1.1 前置排练（`--prev-check-only`，沙箱副本，**不写任何文件**）
- 沙箱：`~/w21-verify/w82/freeze/baseline-sandbox.md`（`cp -p` 自真基线，`sha16 = 7cd1bc5c37a74e8d`，与真基线逐字节相同）。
- **正常档**：`python3 ~/w21-verify/w27-freeze.py --prev-check-only '#82' --baseline <沙箱>` ⇒ 七个 `prev_*` 每个 `hits=1` 且与表项逐位相符、`TIERCROSS` 三条 `agree=yes` ⇒ `PREVCHECK=PASS gen=#82 keys=7 checked=7 skipped=0`（`rc=0`）。
- **错值档**：把沙箱副本 `# RE-FROZEN #81` 块九位行的 `pf` 改 `deadbeefdeadbeef` ⇒ `PREVCHECK=REFUSE MISMATCH key=prev_pf 表项=1c6c58df6d757f3f 基线块=deadbeefdeadbeef（src=九位行:pf）`（`rc=2`）⇒ **该红必红**。
- **零字节改动**：排练前后真基线 `sha16` 恒为 `7cd1bc5c37a74e8d`；正常档沙箱 `sha16` 亦 `7cd1bc5c37a74e8d`（副本忠实）。

### 1.2 `GENS['#82']` 追加（**只追加**；`~/w21-verify/w27-freeze.py`）
- `before → after` ＝ `1afbe72415cf2d0a → 88d1d69ceb6d00e3`（**`before` 与 `#81`（`T-A58`）交付时的 `after` 逐位相同** ⇒ 本趟**恰在 `#81` 之上加一块**）；行数 `1785 → 1818`（**+33 行，零删改**）；`ast.parse` OK。
- 备份 `w27-freeze.py.bak-tB22`（`1afbe72415cf2d0a`）。⚠️ **自伤留档**：`cp -p` 备份本应在**改之前**取，本趟**漏做**（先改了才补）；上表的 `before` 由**逆向差分重建**（重建结果与 `#81` 记录里在册的 `1afbe72415cf2d0a` **逐位相同** ⇒ 重建可核）。
- 条目常数（见 §4）：`prev='#81'`／`nstep=64`／`prev_*` 取 `#81` 冻结块现取值／`infp`／`bs_fp`／`hb`／`allow_changed` 七位／`pf_required=False`／`green` 64 项（与 `#81` 逐字相同）。
- ⚠️ **本条目未行使**（未冻结）⇒ 其 `infp`／`bs_fp`／`allow_changed` **皆为"本读数下的现取"**；若五红的修法改动覆盖面内件，**这些常数须重取**（冻结器本就会当场对拍，不符即拒冻）。

### 1.3 应用门禁 ×2（`run-wpftextdemo.sh 45`）
- `~/w21-verify/w82/logs/w82-rows-r1.txt`（`927fbe0755e8e3a2`）／`w82-rows-r2.txt`（`a012983d0e190225`）：各 `rows=6`、`result=PASS` 六条全绿；`WPTD_SUMMARY=PASS tiers_passed=2/2`／`WPTD_GATE=PASS acceptance=2/2 line_advance=NA`／`WPTD_BRIDGE_SRC_STALE=no basis=pub=546d5b8c37d1695b now=546d5b8c37d1695b so_file_match=yes`；两趟判词行**逐字 diff 相同**（`GATE_LINES_IDENTICAL=yes`）。
- 六条 `BASELINE tier=…` 机读行里的 `pc`／`pf` 与本报告 §4 的现取值**逐位相符** ⇒ **冻结器那两条门禁行断言本身是能满足的**（卡住的只有 `verify-all` 那一关）。

---

## §2 阻断项（**四红两趟复现**；逐条给现取证据）

> 两次运行：`~/w21-verify/w82/logs/w82-pre-20261003-172355.log`（`ffed136c8e6bce82`，`步骤通过 59 ❌ 失败 5`）／`.../w82-pre-20261003-174349.log`（`73df83ad3bd4f1cd`，`步骤通过 60 ❌ 失败 4`）。第一次多红的一项是 `SENTINEL-SPEC`，它在同趟末尾被 `close-wave.sh` 的哨兵自更新**顺手修绿**（第二次运行已绿）⇒ **稳定红 = 下列四条**。

### 2.1 ⛔（主）`R-GATE（连续交互）` `rc=2` —— 被测应用**真崩**（核心已转储）
- 判词：`R_GATE_DEVICE=NOINFO reason=window-absent pid=<…> alive=no` ⇒ `R_GATE=NOINFO reason=device-window-absent`（`rc=2`）。
- 装置行逐字：`run-r-gate-legs.sh: 第 169 行： <pid> 已中止 （核心已转储） ( cd "$APP" && exec env WPF_WIN32_MSG_TRACE=1 dotnet "$PROBE_DLL" --only=clickprobe --late-ms=3000 > "$APPLOG" 2>&1 )`。
- **三次复现**（两次 `verify-all` ＋ 一次 `--keep` 单跑；`held=4s` ⇒ 起窗后即崩）：`bash build/MilBridge/tools/r-gate-step.sh --keep` ⇒ `RGATE_RC=2`，证据目录 `/tmp/r-gate-step.DGUEAWvE/`（`app.log` `sha16=2d007fd91bf6c646`）。
- **崩溃原文（`app.log`，逐字）**：`Unhandled exception. System.Runtime.InteropServices.COMException (0x80004005): Unexpected HRESULT has been returned from a call to a COM component.` —— 栈：`DUCE.Channel.Commit()`（`upstream/…/Common/Graphics/exports.cs:376`）→ `MediaContext.CommitChannel()`／`MediaContext.Render()` → `HwndTarget.OnResize()`（`build/PresentationCore.Linux/HwndTarget.Linux.cs:1618`，`WM_SIZE`）→ `HwndWrapper.WndProc` → `HwndSubclass.SubclassWndProc`（共 `17` 帧，末帧起即未捕获 ⇒ 进程 abort）。
- **归因（现取、成对）**：本仓在册 `R_GATE=PASS crit=13/13 clicks=11 …` 的历史读数**全部**带 `pc=ba162811e97e4484`（＝`#81` 冻结位）；**本趟**带 `pc=83c71acfb20f26d7`／`win32shim=5f9ed647c68197ae` ⇒ **崩溃是 `#81` 冻结之后、`#82` 波之内引入的**（**产品面回归**，非环境噪声：同一装置在 `#81` 时代绿）。
- ⇒ **该红是产品缺陷**（提交/渲染链在 `WM_SIZE` 上 `E_FAIL`）；修法属**产品/调试**（`src/**`／`build/**/*.Linux/**` 皆黑名单）⇒ **本趟不能碰**。

### 2.2 ⛔ `FP-MANIFEST-TEETH` `rc=1` —— 覆盖面件数 `237` ≠ 声明 `--expect 236`
- 判词：`FP_MANIFEST_TEETH=FAIL reason=files-n-mismatch files_n=237 expect=236 delta=1`（两趟同）。
- 根因（机械定位）：`git diff --name-status cb2d3e134..HEAD`（`cb2d3e134` ＝ `#81` 冻结点）落进 `fp_inputs()` 覆盖面且**在 `#81` 冻结树里不存在**的件**恰一件** ＝ `src/WpfGfx.Linux/Interop/MilPresentProbe.cs`（`T-B19` 新增，`173` 行；被 `fp_inputs()` 的 `find src/WpfGfx.Linux -type f -name '*.cs'` 收进）⇒ 覆盖面 `236 → 237`。
- `verify-all.sh` 的 `--expect` 是**显式常数**（其步本体自注：「漏改 ⇒ `files-n-mismatch` 红，方向安全」），`T-B19` **没有同趟改**；`HANDOFF-NEXT.md` 的 `cell=#2` 现取 `237` 亦佐证（「契约要对拍」那条已记 `237`，但门禁侧常数没跟）。
- 修法 ＝ 把 `verify-all.sh:1204` 的 `--expect 236` 改为 `237`（＋ 口径注释）—— **`verify-all.sh` 在派单黑名单内** ⇒ 本趟不动。

### 2.3 ⛔ `ROOT-ENTRIES` `rc=1` —— 仓根两条**未跟踪**条目不在允许清单
- 判词：`ROOT_ALLOW=FAIL … examined=22 tracked_n=22 worktree_n=28 allowed_n=26 unknown_tracked=0 unknown_fs=2 unknown= .agents .tmp rc=1`。
- 两条 = `.agents`（目录；本机 **narnat 运行时**目录，`mtime 10-03 15:08`，仓内 `.gitignore` 里已有 `.agents/` 一行）与 `.tmp`（`0` 字节文件，`mtime 10-03 06:56`）—— 二者**皆非本趟所造**，是**宿主运行时残留**。
- 允许清单是**内嵌**在 `build/MilBridge/tools/root-entries-allowlist-check.sh`（`allow_src=embedded allow_file=-`）⇒ 补清单或加 `.gitignore` 豁免**都要改黑名单件**；删条目则动宿主运行时目录（**不属仓内容，且非本趟授权**）⇒ 本趟不动。

### 2.4 ⛔ `STATIC-JAWS` `rc=1`（**派生红**，非独立缺陷）
- 判词：`STATICJAWS=FAIL fails=2 n=34 …`；两条 `STATICJAWS_HIT` 逐字 ＝ `step=ROOT-ENTRIES … rc=1` 与 `step=SENTINEL-SPEC … rc=1`（第一次运行；第二次只剩 `ROOT-ENTRIES` 一条 ⇒ 应由 §2.3 解释）。
- ⇒ 本牙**不是**新的独立缺陷：它是「把已接线的静态牙再跑一遍」，红项**就是**上面那几条的同一实例。

---

## §3 为何不能在**本趟写域**内收口（黑名单逐条）

派单 §② 写域 ＝ `~/w21-verify/w27-freeze.py`（只追加）／`~/w21-verify/w82/**`／基线件／`docs/CURRENT-STATE.md`／`README.md`／`docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md`／本载体。**黑名单** ＝ `verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`src/**`／`build/**/*.Linux/**`／`upstream/**`。

| 红 | 唯一修法落点 | 是否在黑名单 |
|---|---|---|
| `R-GATE`（产品崩溃） | `src/**` 或 `build/**/*.Linux/**`（提交/渲染链） | ✅ 在黑名单 |
| `FP-MANIFEST-TEETH` | `verify-all.sh` 的 `--expect` | ✅ 在黑名单 |
| `ROOT-ENTRIES` | `build/MilBridge/tools/root-entries-allowlist-check.sh` | ✅ 在黑名单 |
| `STATIC-JAWS` | 随 §2.2／§2.3 消 | ✅ 同上 |

⇒ **四红无一能靠本趟写域内的动作消掉**；**冻结器又结构上要求 `verify-all` 绿**（`assert '结论：✅ 全部通过' in log and nfail == 0`，声明类只豁免 `BASELINE-SHA`／`ARM-LOG-SHA`／`COLUMN-FLOOR(ARMLOG)`）⇒ **本趟的结论是：停手 ＋ 如实报告**（放行与否请主控裁）。

> 说明（**不代做，只点**）：`#81`（`T-A58`）也曾在**结构上必需**时越过黑名单 1 行（`verify-all.sh` 头注释补世代表头行），并**同趟**请主控裁。本趟与之的差别是：这里要动的**不是注明**（那**一行**），而是**一条会改变门禁判据的常数**（`--expect`）＋ **一颗牙的内嵌清单**——**尺度不同**，故本趟**不自行放行**，改为**显式请示**。

---

## §4 现取常数（**本读数下**）

- **步数**：`grep -c '^run_step "' verify-all.sh` ＝ `64`；头注释现取**已含** ``**`#82` 收官起 = 64 步**``（`T-D2` 落，`:7`）⇒ 冻结器「牙齿②」**本条能过**。
- **九位（`Release` 权威件；现取）**：`bridge e88f82233f53d1ea`（5,065,344 B）｜`pc 83c71acfb20f26d7`（3,603,456 B）｜`pf 7ef0dbb210db54e3`（6,180,352 B）｜`windowsbase 96554b5419761f0a`｜`provider fb4fa95db01945a2`｜`win32shim 5f9ed647c68197ae`（567,456 B）｜`wic_shim f7b3026c8c019be2`｜`hbtextline e2fa9ec9be1a6cf1`｜`dwf e0fcfd13ad86b2b4`。
- **对 `#81` 冻结块位移**：**动七位**（`bridge`／`pc`／`pf`／`windowsbase`／`provider`／`win32shim`／`dwf`）｜**未变两位**（`wic_shim`／`hbtextline`）⇒ `GENS['#82']['allow_changed']` 即照实声明这七位。
- **指纹**：`inputs_fp = d400153a5c8f0bf04df53b992b4d264c08e0ca7848415001cc80d1d161e03363`（覆盖面现取 `237` 件）｜`BRIDGE_SRC_FP = 546d5b8c37d1695b`（`BRIDGE_SRC_N=79`；`#81` 为 `d697b1e10ff48881`）。
- ⚠️ **`provider` 一位的动态**：`verify-all` 的 `[1] 构建` 会把 `build/DirectWrite.Linux/Provider/bin/Release/…dll` 换代（本趟实测 `617ffafa2fbac822 → fb4fa95db01945a2`；同尺寸 104,448 B）—— 这**不影响**冻结器（它只断言门禁行里的 `pc`／`pf`），但**是** §2.1 之外值得记的一条「重建位移」现场。
- **`PRE` 快照** ＝ `~/w21-verify/w82-pre.sha`（`7de2300b84e1b8d0`，9 行，键 ＝ 九位**路径**；口径 ＝ **开工前九位** ＝ `#81` 冻结块九位行逐位）。

---

## §5 写域与边界（逐件对账）

| 件 | 面 | before → after | 说明 |
|---|---|---|---|
| `~/w21-verify/w27-freeze.py` | 装置 | `1afbe72415cf2d0a → 88d1d69ceb6d00e3` | **只追加** `GENS['#82']`（**老代一字未改**）；`+33` 行、`0` 删改；备份 `w27-freeze.py.bak-tB22` |
| `~/w21-verify/w82-pre.sha` | 装置（新建） | — → `7de2300b84e1b8d0`（701 B） | 开工前九位 |
| `~/w21-verify/w82/**` | 装置（新建） | — | 链脚本／日志／门禁 rows（各 6 行全 PASS）／沙箱副本两档 |
| `build/MilBridge/P1-freeze82-report.md` | 报告（新建） | — | **本件** |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | 基线 | **`7cd1bc5c37a74e8d`（未动）** | **冻结器未写盘** ⇒ 与 `#81` 冻结态一致 |
| `docs/CURRENT-STATE.md` | 声明 | **未动** | `:9` 仍 `gen=#81 sha16=7cd1bc5c37a74e8d` |
| `README.md`／`docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md` | 复述位 | **未动** | 未冻 ⇒ 无"dated 结账"可记（避免写进过期世代值） |

**黑名单**（`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`src/**`／`build/**/*.Linux/**`／`upstream/**`）：**一字未改**（`git status --porcelain` ＝ 仅 `??` 派单件与**本载体**）。

---

## §6 建议（**供主控裁**，本趟不代做）

1. **先修 §2.1（产品崩溃）** —— 它是**唯一不可由"记账"消掉的**红：`WpfFeatureProbe --only=clickprobe` 在 `WM_SIZE` ⇒ `MediaContext.Render` ⇒ `DUCE.Channel.Commit()` `E_FAIL (0x80004005)` 未捕获崩溃。证据 `/tmp/r-gate-step.DGUEAWvE/app.log`。
2. **同趟**把 `verify-all.sh` 的 `--expect 236 → 237`（§2.2）＋ 头注释口径句改了（属 `#82` 波**欠的账**，`HANDOFF-NEXT cell=#2` 已记 `237`）。
3. **裁定 §2.3**（`.agents`／`.tmp`）：或补内嵌清单 ＋ `why`，或在冻结趟**显式授权**清这两条宿主残留。
4. 三条消掉后**重跑 `verify-all`**（应 `64 ✅ / 0 ❌`）⇒ 本趟的 `GENS['#82']`／`PRE`／`w82-record.txt` 模板可**直接复用**（常数按届时现取复核；冻结器会当场对拍）。

---

## SELF（自指口径）

本文件自指纹口径：`head -n -1 | sha256sum | cut -c1-16`（末行即本行，逐次重算）。
