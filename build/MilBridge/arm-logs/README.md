# `build/MilBridge/arm-logs/` —— 在册红门禁（`tline-gate.sh`）的**五臂日志**约定

**这里的 `*.log` 是硬链接（`ln`），不是拷贝、也不是符号链接。** 为什么：
1. **拷贝**会把 mtime 顶到拷贝那一刻 ⇒ **架空**门禁对**弱配对**臂（三支 tab oracle 与 `textlineproto` —— 它们的日志**不自报被测件 sha**）的判据 **「树 == 世代」∧「日志 mtime ≥ 该世代被测件的 mtime」**（"日志不可能早于它应当练过的那个仪器"）。
2. **符号链接**也不行：门禁的 `--logdir` 用 `find "$LOGDIR" -maxdepth 1 -type f -name '*.log'`，而 `-type f` **不匹配符号链接本身** ⇒ 一个日志都扫不到 ⇒ 全臂 `NOINFO`（实测 `rc=2`）。
3. **硬链接**两头都对：mtime 是**原始文件的**（判据有效），而 `find` 看到的是**普通文件**（能扫到）。

**重取新世代读数时**：先 `rm -f` 旧的硬链接，再 `ln <新日志> <臂名>.log`。**不要**用 `cp`、也不要用 `ln -s`。

## 五臂与文件名（`--logdir` 按内容自动识别臂，文件名只是给人看的）

| 文件 | 臂 | 怎么产出 |
|---|---|---|
| `tline.log` | `tline` | `bash build/MilBridge/run.sh tline`（**强配对**：日志自报被测 shim sha；长趟须有界 + 按 PID 止损） |
| `tab-zero.log` | `tab-oracle-zero` | `(cd build/MilBridge/tests/CoverageProbe/bin/Release && dotnet PresentationCore.Tests.dll --tab-lines-oracle <repo>/tests/parity/windows/tab-zero/out/tab-zero-oracle.json)` |
| `tab-anchor.log` | `tab-oracle-anchor` | 同上，换成 `tab-anchor/out/tab-anchor-oracle.json` |
| `tab-rtl.log` | `tab-oracle-rtl` | 同上，换成 `tab-rtl/out/tab-rtl-oracle.json` |
| `textlineproto.log` | `textlineproto` | `DISPLAY=:97 bash build/MilBridge/run.sh textline`（⚠️ 会写 `build/MilBridge/gen/textline-proto.png`；**没有 `DISPLAY` 时 `ContractProbe` 段会因缺 X 假红**） |

## 新世代怎么重绿（顺序不能颠倒）

1. **重建会编进 shim 的探针/宿主**：`CoverageProbe`（`-c Release`）、`TextLineProto`、`HbTextLineParity`
   —— 它们的 csproj 把 `build/shims/PresentationCore.HbTextLine.cs` **编进去** ⇒ 不重建就是**在量旧 shim**。
2. **跑五臂**并把日志**硬链接**到本目录（`ln -f <新日志> arm-logs/<臂名>.log`，覆盖旧的链接即可）。
   ⚠️ **不是"软链"** —— 本文件 `:3-8` 与 `:60-64` 已用实测定死：**`cp` 会顶 mtime 从而架空"弱配对"判据**，**`ln -s` 会被门禁的 `find -type f` 漏掉 ⇒ 全臂 `NOINFO rc=2`**。此处原写"**软链**"是错字，**主控 `#21` 波更正**（纪律 4：引注前现场重读；本行以外全文逐字未改）。
3. **重钉 `build/MilBridge/known-red.json`** 的 `generation`（三项仪器 sha + 世代标签 + `evidence_log`）
   与 `entries`（读数漂移 ⇒ `drift`；某条不再红 ⇒ `gone` ⇒ **门禁判 FAIL 且原因写"登记表过期"**，
   这是**设计**、不是缺陷）；`changelog` 必须写清"为什么重钉"。
4. 自检：`bash build/MilBridge/tools/tline-gate.sh --logdir build/MilBridge/arm-logs`
   ⇒ 目标形态 `TLINE_GATE=PASS … drift=0 gone=0 unregistered=0`（`unlocated>0` 允许且应当点名）。

## 三态（**都不许读成绿**）

| 形态 | rc | 含义 |
|---|---|---|
| `TLINE_GATE=PASS` | 0 | 五臂都有读数 **且** 每一处红都在册（含 `KNOWN_RED_UNLOCATED` 点名） |
| `TLINE_GATE=FAIL` | 1 | `unregistered>0`（**未登记的失败**＝新问题）或 `GATE_REASON=registry-stale(...)`（**登记表过期**：`drift`/`gone`） |
| `TLINE_GATE=NOINFO` | 2 | 缺臂 / 口径不一致 / **算不出** —— `NOINFO ≠ 通过`（本目录是空的、或日志早于该世代被测件时就会是这个） |

## 已修的仪器缺陷（记账，免得后人以为是"设计如此"）

1. **弱配对时间洞**：原先只要"树 == 世代"就放行 ⇒ **旧日志会被洗成新世代**（实测 `#13` 的 tab 日志被当 `#15` 读）。修法 = 追加"日志 mtime ≥ 世代被测件 mtime"，不满足 ⇒ `caliber=STALE-WEAK` + `NOINFO`。
2. **`ROOT` 只看脚本位置**：拷到别处跑会**静默**算出错的 `ROOT`（仪器 sha 全空且不报错）。修法 = `脚本位置 → --root → $PWD → env` 依次尝试，定不出即 `NOINFO`，并印 `ROOT_SRC`。
3. **tab 臂"两面口径不一致"**（2026-09-15 主控修，`#15` 波后发现）：门禁的**未登记检测**取探针自报的 `TAB_LINES UNREGISTERED`（**含位置面**），而**在册红判读**只取 `结构=` 状态 ⇒ `结构=PASS 位置=FAIL` 的 case 一边算"未登记失败"、一边算"已不红" ⇒ **无论怎么登记都到不了 PASS**（实测 `unregistered=46` 或 `gone=46` 二选一）。修法 = 该 case **只要有 `FAILCASE` 行就判红**，且 `判据状态` 读数与 `judge_red` **用同一把尺子**（两处都只**加强**红检测、不放宽任何口径）。实测 `tab-anchor` 的 `FAILCASE` 行 = 178 条（= 探针自报的"未登记失败 178"），其中 `结构=FAIL` 132 / `位置=FAIL` 140 ⇒ 修前恰好漏掉 46 条纯位置面失败。

---

## 归属与交接（T1b · 2026-09-15 追加；本节之前的全部内容**逐字未改**，见 `cmp -n` 自证）

- **`build/MilBridge/arm-logs/**` 归 T1b**：产日志流程（跑五臂 → `ln -f` 硬链接 → 重钉登记表）、硬链接约定、本文件维护。
- **`build/MilBridge/known-red.json` / `build/MilBridge/tools/tline-gate.sh` / `verify-all.sh` 归主控**（全局判据与登记口径）；T1b 只读。
- **新世代"重绿"的完整步骤（不依赖对话记忆）**：
  1. 跑五臂，新日志先落临时目录；
  2. **`ln -f`** 覆盖 `arm-logs/<臂名>.log`（**绝不 `cp`**，理由见下一节）；
  3. 按门禁自己的输出 `[UNREGISTERED] arm=… id=…` **逐条重钉登记表**（该步由**主控**执行）；
  4. 复跑门禁，核对 `TLINE_GATE=… generation=#<新> tree_gen=same` 且 `rc=0`；
  5. 做两极化红证（删 1 条登记 ⇒ `rc=1`；恢复 ⇒ `rc=0`）。
- **现场锚（#15 冻结当时）**：`hbtextline b5118424dc977aef`（mtime 12:45:34）、`pc 532c7f54f7573070`、门禁仪器 `b37a5c9f55ae71a4`、登记表 `cebd534238c3b649`。
- **口径升级建议（只记录，不改代码）**：`verify-all.sh` 应同时记 `loadavg` 与 `mem_available`——波后手动 `verify-all` 曾撞上 `ManagedLayer.Tests` 测试主机崩溃，而静树单跑 **76/76 `rc=0`**；带负荷读数可把"环境压力"与"真回归"分开。

## 重生成日志时不要 `cp`，要 `ln -f`（T1b 追加）

- **必须硬链接**：`cp` 会把 mtime 顶到当下 ⇒ **架空**弱配对判据「日志 mtime ≥ 世代被测件 mtime」；**符号链接**会被门禁的 `find -type f` 漏掉（实测 `rc=2`）。
- **后果逐字写清**：顺手 `cp` 会让弱配对判据 **静默变绿** —— **比变红更危险**，因为**判据本该拦住的东西被放过了**。
- **正确做法**：`ln -f <新日志> build/MilBridge/arm-logs/<臂名>.log`（同一 inode 两个名字，链接数保持 2）。
- **禁止**：对 `arm-logs/*.log` 做 `rm` 或重写 —— 那会破坏 #15 世代的五臂读数（门禁掉 `NOINFO`）。
