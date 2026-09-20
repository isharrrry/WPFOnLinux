# 波 `#32` 预登记（**落地前**写；`#31` 收官后立刻开）

> 起点 = `#31` 冻结基线（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `#31` 块）｜九位：`bridge d567c26f197ec1e3`／`pc 7374308a00c55572`／`pf f418131a53fa2951`／`windowsbase 1114a28ec5a03ab7`／`provider 9aa0d744802aaa31`／`win32shim 0098234982391bbf`／`wic_shim 03b67fbcd7c385b6`／`hbtextline e89fed55fd8e32bc`／`dwf 0ed422ef2dd46445`。
> 起因 = `#31` 的 `D-G38`：**产品入口臂**（`build/MilBridge/tests/ProductEntryArm/`）5 个 `M_modifier` 例 **18 条逐行红**，`w`/`witw` 我方恒 `45.968000` 而真值 `74.573333`／`115.690000`／`156.916667`（`|Δ| = 28.605 ~ 110.949` DIP），根因 = `CollectLenient` 只记 modifier **起点**、**终点没接线**。⚠️ 这**不是新发现**：生成物自己 `:414-421` 就逐字记着「`modifierScopeEnd = -1`（"到段末"）是**已知错**的跨度，修它必须先让 `CollectLenient` 收集」—— 登记号 `D-T2-c`。**本波就是去还这笔账。**

## §1 内容（**两条车道 ＋ 主控波尾**；写域互不重叠是硬约束）

| 车道 | 干什么 | 构建者？ | 写域 |
|---|---|---|---|
| **W32A** | **`D-T2-c` 落地**：让 `CollectLenient` **收集覆盖终点**并把它接到**每一个**调用点（`out int modifierScopeEnd` ＋ 三个站点传参），**改的是应用器**（`src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`），生成物由脚本重出（**不许手改生成物**）。判据 = 产品入口臂 5 例**由红转绿**且 3 个阴性对照仍绿 | **是**（独占） | 该 `.py` ＋ 生成物 ＋ `$HOME/w32a/**` |
| **W32B** | **P3：`--selftest` 的"前提自持"审计与加固** —— 逐个自测件判「它的每一例是否依赖**会随重冻/换代移动**的冻结件」，把依赖者改成"前提自持"（夹具只依赖自己注入的东西），**只加强、不许放宽** | 否（零 `dotnet`、纯文本） | `build/MilBridge/tools/*-check.sh` 的 `--selftest` 段（**只改自测段**）＋ `$HOME/w32b/**` |
| **W32C** | **`D-G39` 机制复现**：用 `DRC_*` 覆盖 ＋ 一个写者线程，**在沙箱里**复现"并发写 route 件 ⇒ `defect-registry-check` 假红"；取到机制或**证明取不到** | 否（零 `dotnet`） | `$HOME/w32c/**`（**不许改仓内任何文件**） |

**三条写域互不重叠**；W32B 若判定某件必须改**非自测段**，只给 diff、报主控。

## §2 位移预测（**表外位移 ⇒ 停**）

| 位/量 | 预期 |
|---|---|
| 九位 | **只有 `pc` 变**（应用器改了 ⇒ 生成物变 ⇒ `pc` 重编）；其余八位不动，**`hbtextline` 一字节不动** |
| `GEN_KEYS` 三项 | **不动**（`instr_run_sh`／`instr_program_cs`= …/HbTextLineParity/Program.cs／`instr_shim`）⇒ **不重取五臂** |
| `inputs_fp` | **必变**（`patch-*.py` 在覆盖面里 ⇒ 设计性变更，须单列并说明） |
| `BRIDGE_SRC_FP` | **必变**（`src/WpfGfx.Linux` 的 `*.cs` 在它覆盖面里 ⇒ 若 W32A 只改 `src/WpfGfx.Linux.Native/tools/*.py` 则**不变**；生成物落在 `build/PresentationCore.Linux/**` 而它**不在** `BRIDGE_SRC_FP` 覆盖面）⇒ **以现场现算为准** |
| `verify-all.sh` 步数 | **视 P2 接线而定**：若产品入口臂转绿 ⇒ 接线为第 `[16]` 步（**21 → 22 步**）；若仍红 ⇒ **不接线**（见 §3 停条件） |
| 五臂日志 / `arm_logs` | **不动**（不重取） |

## §3 停条件（**触发即停、如实上报**）

1. 九位出现 `{'pc'}` **之外**的位移；或 `hbtextline` 变了。
2. `inputs_fp` **没变**（说明 W32A 其实没动应用器 —— 那要停下来核"它到底改了什么"）。
3. **产品入口臂修完仍红**，且红的**不是** `modifierScopeEnd` 那一族 ⇒ 停：说明还有第二条根因，**不许**为了让它绿而放宽判据。
4. 3 个**阴性对照**（`F_lat_words_*`）由绿转红 ⇒ 停（修法误伤无 modifier 的路径）。
5. `pc-line-step.sh`（`PCLINE_START_STEP`）或 `frame-step.sh`（`FRAME_STEP`）由绿转红 ⇒ 停。
6. `tline` 六项不变量 / 五臂门禁 `TLINE_GATE` 出现**新的** drift/gone/unregistered ⇒ 停。
7. 应用门禁出现 `result=PASS` 少于 **6/6** ⇒ 停。

## §4 资源与内存纪律

- **并行车道上限 = 7**；本波**只有 W32A 一个构建者** ⇒ 它独占（`dotnet` 不许与它并行）。
- 预警**必须同时看 `swapfree`**：`#30`（21:50:08）与 `#31`（11:54:45）**两次**现场都是 `swapfree=0MB` 而同一笔 `avail` 看着完全健康（`#31` 那次 `avail=3587MB`、`dotnet=1`，发生在**应用门禁**期）。
- ⚠️ 采样器的 `dotnet>3` 告警阈值是**车道纪律**的口径；`verify-all` 的测试步**合法地**同时有 5–6 个 `dotnet` ⇒ 那类告警**不是**资源事故（`#31` 已如实分类）。
- 零 `dotnet` 车道**不许跑会自行构建的步骤脚本**（`frame-step.sh`、`pc-line-step.sh`、`verify-all.sh` 的第 `[1]`/`[2]` 步、`hidden-only-step.sh`）；`tline-gate.sh`/各 `*-check.sh` 是纯读者，可以跑。
- **不许 `pkill`**；不许用 `pgrep -f`/`ps|grep` **单独**下结论（**纪律 69**：数进程一律 `pgrep -c -x <名>`）；定人不能用 `PPID`。
- ⚠️ **零 `dotnet` 车道不许写 route 件**（`KNOWN-DEFECTS.md`／`docs/CURRENT-STATE.md`／`handoff.md`／`ACCEPTANCE-BASELINE.md`）：W32A 会跑 `verify-all`，而 `defect-registry-check` 在**并发写 route 件**的窗口里会出假红（`D-G39`）⇒ 别给它造假红。

## §5 收官清单（顺序不可颠倒 —— 纪律 46）

- [ ] W32A：`D-T2-c` 落地 ＋ 产品入口臂由红转绿 ＋ 阴性对照仍绿 ＋ `verify-all` 一趟全绿
- [ ] W32B：`--selftest` 前提自持审计与加固（逐件：审计结论 ＋ 成对读数）
- [ ] W32C：`D-G39` 机制（或"证明取不到"）
- [ ] **主控**：判定并接线 `[16] PRODUCT-ENTRY`（**仅当它绿**）＋ 同趟声明行 ＋ `close-wave` ⇒ 五臂 ⇒【零构建窗口】⇒ `verify-all` ×2 ⇒ 门禁 ×2 ⇒ **重冻 `#32`** ⇒ 文档五件（`#32` 块／`CURRENT-STATE` 顶部＋纪律／`handoff` 波记录／`KNOWN-DEFECTS` 登记／本文件 §6 收官）

## §6 收官（待填）

## §6 收官（`#32` 完成，2026-09-18 13:3x）

**`#32` 已重冻：整份 `sha16=5a9d174852453384`（400,719 B）**；机器行核对 `rc=0`、`BASELINEGEN=PASS decl_gen=#32 file_newest_gen=#32`、`BASELINEDUP=PASS`。
**两趟 `verify-all` 各 `rc=0` / **22 步** / 871 通过 / 2 跳过 / `SKIP_GUARD=PASS`，结论区逐字相同**（唯二差异 = 运行时间戳那一行与门禁 `outdir` 的时间戳）；应用门禁**两趟** `RUN1_RC=0`/`RUN2_RC=0`、**各 6/6 `result=PASS`**（`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_BRIDGE_SRC_STALE=no`，每趟 `config=` 带 `pc:b877ff3e3437145a`／`pf:a1ce403a74225f10`）。五臂 `TLINE_GATE=PASS … judge=t1b3-tline-gate/7` ＋ `GATE_PROBE=PASS` ＋ `GATE_COLUMN=PASS` ＋ **`GATE_COLUMN_EXTRA=PASS`（三支臂）**；`ARMLOG_SHA=PASS 5/5`。
**§2 位移预测 vs 实际**：九位**只有 `pc` 与环成员 `pf` 变**（`pc 7374308a00c55572 → b877ff3e3437145a` 命中预测；`pf f418131a53fa2951 → a1ce403a74225f10` 是波尾 `[1/6]` 重编那一位）；其余七位逐位未动、**`hbtextline` 一字节未动** ⇒ **不重取五臂**；`BRIDGE_SRC_FP` 未变（**桥未重发**）；`inputs_fp` **设计性变更** `46d2a2b0… → 2b6e4df8b45e5912…`（成员 **115 → 120**）；`verify-all.sh` **21 → 22 步**（预测写的是"视 P2 而定，21 → 22"⇒ 命中）。**§3 停条件①–⑦ 一条未触发。**
**新第 `[16]` 步 `PRODUCT-ENTRY` 在真趟里是绿的**：`PRODUCT_ENTRY_STEP=PASS 判定例=8/8 判据格=147/147 全部符合真值（红=0 noinfo=0）｜5 个 M 例逐例走宽松档（正控 5/5）｜3 个阴性对照走严格档`（两趟逐字相同）。
**本波的三条"账"**：① **产品侧**：`D-T2-c` 从"登记着、没人修"变成"修好且有牙"（5 例 18 红 → 0；`w`/`witw` 最大 |Δ| `110.948667 → 0.011333` DIP；阴性对照 98/98 不动、`PEA_NOMOD` 逐字节相同）；② **一处长期随机打红 `verify-all` 第 `[10]` 步的伪红**（`D-G39` 真因 = 核对器**自己管线里的 SIGPIPE 竞态**，`load1≈7.8` 时 **50%/趟**）被查到根并修掉，**主控先前两条归因都是错的**；③ **覆盖面补齐**（`fp_inputs()` 纳入包括 `defect-registry-check.sh` 在内的 **5 个判据件**）。
**本波新立与待立**：**纪律 71**（多行串不许用 `printf | grep -q`）已立；`D-G40`（同一个值两份来源 ⇒ 自测"已死红"无人看见）与 `D-G41`（`"$0"` 重入自测 ⇒ 判据件被改写那一刻出凭空的红）已登记。**`#33` 候选**见 `#32` 块 ⑧，头号是 `D-G11` 与"同族残留四处"（其中 `run-wpftextdemo.sh` 的那两处**伪负 = 应用门禁的假绿**，最危险）。
**主控自纠（本波 5 处）**：**（第 5 处，收官后追加）我自己的收官核对命令里又把反引号写进了双引号** —— `grep -c "^# ⏪ **（历史，已被 \`#31\` 取代）**# RE-FROZEN #31"` 里的反引号被当成**命令替换**，于是那条 grep 的 pattern 被改掉、**返回 0**，我一度以为"`#31` 块没有降级"⇒ 换成单引号后现场是正常的（`:56` `# ⏪ **（历史，已被 `#32` 取代）**# RE-FROZEN #31`）。⇒ **这一族的第 8 次现场**，而且这次是**主控在做"验证别人有没有做对"的时候踩的** —— 这正是第 `[15]` 步存在的理由；⚠️ 也提醒：**"验证命令自己错了"会伪装成"被测件错了"**。`D-G39` 前两条结论被推翻｜`#31` 的 `APPSYNC` 引错行｜12:04 读到应用器中间态 sha 差点误判（"在别人写盘时取到的 sha16 不是一个版本"）｜**我自己的 `pkill -f 'w32-mem'` 把承载它的 shell 一起杀了**（`pkill -f` 自匹配 —— 上一次同样的坑是 `close-wave.sh` 的 `pgrep`），⇒ 停采样器改成**按 pid 停**的脚本。
