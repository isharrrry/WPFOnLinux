# PORT-SPEC —— 本仓的工程规范（**并行车道必须逐条遵守**）

> 这份文件是**规范**（normative）。它规定了"在这个仓里做移植"的**判据纪律、取证纪律、写域纪律、发波纪律**。
> 每一轮/每条车道的产出，只要与它冲突，**以它为准**；若你认为它错了 ⇒ 走"推翻"流程（见 §7），**不许默默绕过**。
> 配套：**现读入口**（以现场为准）= `docs/CURRENT-STATE.md:9`（世代＋冻结）｜`../build/MilBridge/HANDOFF-NEXT.md`（现场交接）｜[`ROUTES.md`](ROUTES.md) §13（任务树）；路线划分见 [`ROUTES.md`](ROUTES.md)｜文档地图见 [`INDEX.md`](INDEX.md)｜上游 README 见 [`../README-Window.md`](../README-Window.md)。
> ⚠️ **历史件的读法**：`§15x+` 逐波记录、旧交接件 `../handoff.md`（`HO` 路由键，**正文原文保留、不许删行**）、各波 `WAVE*-PREREGISTRATION.md` 都是**证据**，**不是**现行判据。

---

## §0 这个项目在做什么（一句话 + 边界）

**替换式移植（substitution port）**：让 WPF 应用**在 Linux 上从源码编译、开窗、真的画出来、并且能用鼠标键盘操作**。
- 边界：**不**要求"在 Windows 上编译好的 WPF 二进制"能在 Linux 跑（砍掉整条二进制兼容路线）。
- 手段：`upstream/wpf/**` **只读**；Linux 版由 `build/*.Linux/*.csproj` 剔除 Windows-only 源、加入生成的 `*.Linux.cs`；原生面由自建 `libwpfwin32.so`（win32 shim）、`libwpfwic.so`（WIC shim）、`wpfgfx_cor3.so`（AOT milcore 桥）补齐。

---

## §1 判据纪律（**本仓的核心资产**）

1. **判据先写死，再取读数**：任何"修好了"的声称，必须在动手前把**判据 + 反极性**写进 `docs/WAVE*-PREREGISTRATION.md`（或本轮的预登记节）。事后对齐（先看到读数再定判据）**一律不接受**。
   - 预登记四要件（**回归判定**：① 两臂同刻 ② 成对归因臂 ③ 复现性 ④ Fisher 精确检验**双尾**）的**权威处** = [`PREREG-TEMPLATE.md`](PREREG-TEMPLATE.md)（`TASK-0705`；含判定依据、可抄的判据节骨架与现算样本量参考；牙 = `build/MilBridge/tools/regression-decision.py`）。
2. **两极化（成对读数）是硬要求**：说"X 是原因/修法有效"，必须给出
   - **正极性**：修后 ⇒ 现象消失（给出机读行/事件行原文）；
   - **反极性**：修前（或把改动还原）⇒ 现象复现（同一脚本、同一坐标/输入、同一显示）。
   只给一侧 ⇒ 该结论**不算成立**。
3. **`NOINFO` 不许当绿，也不许当红**：算不出来就写 `NOINFO` + "差哪一步"，**不许猜**、**不许用默认值兜底**、**不许把"没测到"写成"没问题"**。
4. **恒 0 的格子要当心**：一个"永远是 0/永远命中不了"的判据格，读起来像"这一档已经被处理" ⇒ 必须**显式化或删掉**（本仓已有两个实例被登记为缺陷）。
5. **"检查器没说话"≠"绿"**：任何检查器都必须自己声明**覆盖面与看不见的部分**（"本校验器看不见的拷贝点 N 处"这类行是**必需**的）。
6. **不许为了让树变绿而放松判据**。修不了就**登记**（见 §4），登记 ≠ 容忍 —— 登记册里的每一条都必须带**处置**与**复算命令**。
7. **判据件本身要被看着**：决定"判什么/门槛多高"的脚本必须进 `fp_inputs()`（`build/close-wave.sh`）与世代绑定，否则"改判据零机器红"。

---

## §2 取证纪律（怎么算"发生了"）

1. **判"发生了没有"看事件日志**（逐条事件行/计数），**不看低频轮询 + 末态字段**。轮询会得出与事件日志相反的结论（本仓有实测）。
2. **每份结论都要能复算**：报告里给出 **artifact（路径 + sha16）+ 字段 + 复算命令**。缺一件 ⇒ 降级为 `NOINFO`。
3. **不许手抄哈希**：一律脚本现场算（本仓有"手抄漏一位字符 ⇒ 冻结基线带错哈希"的事故）。
4. **件要被钉住**：跑应用/探针前记输入件的 sha16，跑完再记一次；两趟不一致 ⇒ 该趟读数**作废**。
5. **仪器会改变时序/行为**：任何"产品行为"的结论都必须有**仪器全关**的腿；仪器腿只能用于**定位**（并且必须同时记 `alive`，否则会把"死前读数"当绿）。
6. **自伤要如实入册**：仪器崩溃、坐标量错、假零（stderr 缓冲）、`pgrep` 自匹配、`| head` 造成 SIGPIPE……踩了就写进报告，**不许粉饰**。
   - 其中「**按模式匹配命令行**收/数进程」这一族**已有牙**：`build/MilBridge/tools/proc-pattern-guard.sh`（`TASK-0714`，`#62` 起接线为 `verify-all` 的一步）。判据 = 凡按模式收/数进程**必须能证明排除了自身**（`$$` **∧** `$PPID`；`pgrep -P "$$" -f …` **不算** —— 它只是**集合限定**）。牙扫全仓 `*.sh`/`*.py`，缺证明 ⇒ `FAIL` 逐处点名 `file:line`。
7. **本机没有 core 文件**（`ulimit -c=0` + apport 管道）⇒ 需要现场就**先抓日志**（`stdout/stderr` 落文件），别指望事后从 core 里挖。

---

## §3 写域纪律（并行不互撞）

1. 每条车道**开工前声明写域**（文件/目录清单），**只写写域内**的文件；跨域需求 ⇒ 报告上交，由主控裁定。
2. **九位（九个"位"）**是产品件的身份：`bridge`（`wpfgfx_cor3.so`）／`pc`／`pf`／`windowsbase`／`provider`／`win32shim`（`libwpfwin32.so`）／`wic_shim`／`hbtextline`／`dwf`。**动哪一位就要走整波**（见 §5）。
3. **验证运行期间不许改**：`verify-all.sh` 本体、`build/close-wave.sh`、路线件（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`、`docs/CURRENT-STATE.md`、`handoff.md`）、声明表 `build/MilBridge/tools/defect-registry-declared.tsv` —— 它们是**判定输入**，改它们会打穿冻结记录（本仓已因此作废过整趟、并出现过 `declared 96→97` 的漂移）。
4. 改任何既有文件前 `cp -p` 备份，并报告 **before/after sha16**。**绝对不许 `ln`/硬链接造沙箱**（有顺着共享 inode 截断真树文件的血案）—— 一律真复制。
5. app-local 副本（应用目录里的 `*.so`/`*.dll`）**必须与权威同代**：用 `bash build/MilBridge/tools/sync-applocal.sh <目标目录>` 同步并留 manifest；**件陈旧会伪装成"修复没生效"**。

---

## §4 缺陷登记（`KNOWN-DEFECTS.md`）

1. 缺陷 id 语法：`D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*`（例 `D-G64`、`D-A2-r`）。
2. 每条至少写：**现象（带读数）→ 判定点（`文件:行`）→ 修法 → 判据（含反极性）→ 边界/未测**。
3. **推翻**已有的判据/措辞是**被鼓励**的，但必须**如实写进报告**并**同趟改登记**（不许只在聊天里说）。
4. 登记册与代码的一致性由 `bash build/MilBridge/tools/defect-registry-check.sh` 复算（`DEFREG=PASS declared=N route_ids=N`）。

---

## §5 发波纪律（动了九位就必须走完整链）

```
① 预登记 docs/WAVE<NN>-PREREGISTRATION.md（判据先写死、§4 预期位移先写死）
② WAVE_OWNER=<你> bash build/integration-wave.sh          # 整波重建（不设 OWNER ⇒ exit 9）
   ⚠️ **本脚本从不编译 native**（机械证据：件内无 `gcc`/`build-shim` 调用）⇒ 改了 `src/WpfGfx.Linux.Native/**` 的波**必须另跑**：
      `bash src/WpfGfx.Linux.Native/build-shim.sh --all`   # native 权威件入口（`close-wave.sh` 的 `[2/6]` 用的就是它）
③ ARMS_OUT=… bash build/MilBridge/tools/retake-arms-w23.sh  # 重取五臂
④ python3 build/MilBridge/tools/repin-generation.py --why '…'   # 重钉；随后 --check
⑤ 应用门禁 ×2（`WPTD_BASELINE_OUT=…`；先 rm -f 输出；期望每趟 6 行 result=PASS）
⑥ 冻前 verify-all（**声明类红照现场报**）
   · **重取了臂**的波 ⇒ 预期**恰好 1 处**声明类红（`COLUMN-FLOOR` 未重冻）；
   · **未重取臂**的波（只改判据件/仪器/登记表） ⇒ 现场可能是 **`[]`（全绿）** —— `#59` 实测就是全绿。**若全绿照实报全绿，不许为凑预期去动东西**（旧版把"恰好 1 处"写成硬预期 = 会逼出假动作）。
⑦ python3 $HOME/w21-verify/w27-freeze.py <valog> <rows> '#<NN>'   # 重冻基线
⑧ 冻后 verify-all ×2（两趟都必须 rc=0）
⑨ 收尾记录：`$HOME/w21-verify/w<NN>-record.txt` 三段（`===BANNER===`／`===FROZEN===`／`===RECORD===`）＋ `docs/CURRENT-STATE.md` 机器行（`:9` 的 `BASELINE-FROZEN`）＋ `build/MilBridge/HANDOFF-NEXT.md` 刷新（**不是** `handoff.md` —— 那是 `HO` 路由键、旧交接正文、**不许删行**，只加现读指针 banner）
   ⚠️ **先建模板、再冻结**：冻结机器 `$HOME/w21-verify/w27-freeze.py` 只在**最新 `# RE-FROZEN` 块**里按 `^# COLUMN-FLOOR `/`^# ARM-LOG-SHA `/`^# COLUMN-CORPUS ` 找外挂声明 ⇒ **模板缺声明行 ⇒ `COLUMN_FLOOR=NOINFO`（缺声明 ≠ 通过）**（`#57` 为此停过一次）。
```

**为什么必须这样**：`verify-all` 里有**声明链**（**四处必须同趟一致**：`VERIFYALL-STEPS-DECL` 首行／`VERIFYALL-STEP-NAMES`／头注释口径句 `` **`#<NN>` 收官起 = <N> 步** ``／`docs/WAVE<NN>-PREREGISTRATION.md` 的标题行）与**世代绑定**（`inputs_fp`、五臂 sha、`ARTIFACT_SRC_FP`）。手改生成物、绕过波序、或"顺手"改判据件，都会让"绿"失去意义。
> **步数别在这份文档里写死**：现读（2026-09-24）= **33 步**（`#59` 收官起）；**唯一权威处 = `verify-all.sh` 首行 `VERIFYALL-STEPS-DECL`**（`build/MilBridge/tools/verify-all-step-check.sh` 用**位置锚**解析它，并在尾行印 `VERIFYALL_SELF=PASS names=<N> decl=<N> gen=<#NN> …`）。旧版此处写"25 步" ⇒ **已过时且会误导**（作者按 25 步去数，永远对不上）。

---

## §6 并行协作的实操约定

1. **一条车道 = 一个可独立验证的判据**（不是"一个功能"）。车道产出的最小集：**报告 + 判据的成对读数 + 复算命令**。
2. 报告命名：`build/MilBridge/<车道号>-report.md`（例 `W57A-report.md`）；开头写**自报 sha16**（先写正文再补最后一行）与**开工/收工件 sha16**。
3. **重活互斥**：整波重建 / `verify-all` / 冻结链**同一时刻只跑一个**（本机 `nproc=3`）。
4. 应用类实验：**每个车道自己的私有应用目录 + 自己的私有 X display**（`Xvfb :<随机>`；有 WM 的腿用 `xfwm4`），收工按 PID 收拾自己的进程，**禁止** `pkill -f`。
   - 这条**已有牙**：`build/MilBridge/tools/proc-pattern-guard.sh`（`TASK-0714`）—— 凡按模式匹配命令行收/数进程，**必须能证明排除了自身**（`$$` ∧ `$PPID`；`pgrep -P "$$" -f …` **不算证明**，它是**集合限定**）。牙自己**不用** `pkill`/`pgrep`（`--self-check` 自扫）。
5. **有 WM 与无 WM 两条腿都要有**：本工程曾有整类缺陷（点击被吞）只在有窗口管理器的会话里出现，而无 WM 的验收装置永远复现不出来（见 `ROUTES.md` 的"验收装置"一节）。
6. 语言：中文为主；**命令、路径、字段名、sha16 一律原样**，方便机器复算。

---

## §7 推翻流程（怎么合法地否定自己的/别人的结论）

1. 给出**成对读数**（同一脚本、只换被测变量）；
2. 给出**你排除掉的解释**与"为什么排除"；
3. 明确写出**被推翻的原句**（引原文）与**你实测的替代说法**；
4. 同趟改**登记与该处文档**里的原句（不许只在报告里说）；
5. 若因此产生**新缺陷** ⇒ 立新 id 并登记。
