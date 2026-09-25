# 波 `#71` 预登记 —— 「覆盖面与前置检查」（`TASK-0729` ＋ `TASK-0727`）

> 车道 **W169A**。判据**先写**（车道侧原件 `criteria.md` —— 判据与两极化设计在跑任何腿之前封存，
> 随本波报告留档；⚠️ 落仓件**不含车道路径**，`D-G137`）；
> 本件与判据同趟落仓，**读数之后再改即事故**。

## §1 本波做什么（范围画死）

| # | 任务 | 落点 | 形状 |
|---|---|---|---|
| 1 | **`TASK-0729`** | `build/close-wave.sh` 的 `fp_inputs()` | **加 20 行**（`PtsPagesProbe` 装置 4 件 ＋ `evidence/` 16 件）⇒ 覆盖面 **172 → 192**；**逐件归因**见 §5 |
| 2 | `TASK-0729` 的**同趟必改** | `verify-all.sh` 步本体 | 第 `[42]` 步 `FP-MANIFEST-TEETH` 的 `--expect 172` ⇒ **`192`**（**声明常数**，见 §6） |
| 3 | **`TASK-0727`** | `build/close-wave.sh` 的 `[0/6]` 前置检查 | 从「**按命令行文本匹配**」（`pgrep -af "$APP_PROBE_RE"`）改成「**按可执行件名**」的**三面**判据（§2.3） |
| 4 | **四处声明**（"不动步数"形态） | `verify-all.sh` | 新 `DECL` 行（`42 gen=#71`，插在现第一行之前）＋ 口径句 ``**`#71` 收官起 = 42 步**`` ＋ `STEP-NAMES` **一字不改**（不加步）＋ 本件 |

**不加步**：`42 → 42`。**零 `dotnet`／零产品改动** ⇒ 九位里**只允许环成员 `pf`** 位移。
**范围守卫**：`build/DirectWrite.Linux/evidence`（13 件）**不在本波射程**（主控明令）；`run-pts-pages-legs.sh`
**已在覆盖面**（`close-wave.sh:271`）⇒ 只加**未覆盖的 20 件**。

## §2 判据（落地前写死）

### 2.0 本波**不做**回归判定（**机读行**；纪律 45）

```
PREREG-NO-REGRESSION-DECISION: yes
```

**本波不做任何回归判定** —— 本波全部判据都是**确定性量**（件数、`rc`、`sha256`、进程分类判词、
`grep -c` 计数），**没有任何"两臂对照 ⇒ 比出一个率"的设计**。因此"回归判定四要件"对本波**逐条 `N/A`**
（**不是"已满足"，是"不适用"**）。全文**没有**引用任何判定工件。

### 2.1 输入来源（纪律 36：**判据的输入必须声明**）

| 输入 | 来源（现取） |
|---|---|
| 覆盖面成员表（**权威**） | `build/close-wave.sh` 的 `fp_inputs()` —— **同码路径**抽出（内容锚 `sed -n '/^fp_inputs()/,/^}/p'`，**不写行号**）后**原样执行**，用 `PATH` 前置同名 `sha256sum` shim 收 `argv` |
| 指纹 | 同一函数经**生产同形**管道（`LC_ALL=C sort \| xargs sha256sum \| sha256sum`）自印 |
| 进程判据（`0727`） | **`/proc`**：`/proc/<pid>/exe`（只读符号链接）＋ `/proc/<pid>/cmdline`（NUL 分隔 `argv`）。**不读** `pgrep`／`ps` 的文本匹配结果；本判据**不使用** `pgrep`／`pkill`（那正是缺陷根因家族，`D-G103`） |
| `--expect N` | `verify-all.sh` 步本体里的**显式常数**（本波 `192`）—— **声明常数**，见 §6 |
| 判词件 | `build/MilBridge/tools/fp-inputs-hygiene-check.sh`（`#70` 折叠的逐行存在性/stderr）／`fp-manifest-step.sh`（件数对账）／`proc-pattern-guard.sh`（第 `[27]` 步） |
| 世代 | `docs/CURRENT-STATE.md` 第 9 行的 `BASELINE-FROZEN gen=#71`（**主控派单字符串**；禁自行推断） |

### 2.2 `TASK-0729` 判据（`J1`–`J7`；三态，**`NOINFO` 不算绿**）

- **`J1`**：`coverage_n == 192` ＝ `172 + 20` ∧ 20 件**逐件** `-f` 存在 ∧ `sha256sum` `stderr` 空（`missing_n=0 stderr_bytes=0 artifact_n=0`）。
- **`J2`（影子保真，**先证影子是现树的忠实影子**）**：影子沙箱（**真拷贝**，`%h==1`）里装**改前** `close-wave.sh`
  ＋**退回这 20 件** ⇒ 指纹**逐位 `== 0e8254f8cf842836…`**（＝现树值）∧ 成员 **172**。
- **`J3`（③ 逐件成对归因）**：20 件**逐件** `去一件 ⇒ 指纹必变`／`还原 ⇒ 逐位回到前值`；20/20 成立 ⇒ **没有第三隐形位移**。
- **`J4`（① 覆盖面内改动必变）**：改**新收的**任一件 ∧ 改**原有的**任一件（对照片） ⇒ 指纹必变；还原必回原值。
- **`J5`（② 覆盖面外改动不变）**：在沙箱里**新建**一件不被任何 `find` 模式命中的件 ⇒ 指纹**逐位不变**。
- **`J6`（病与修，成对）**：**只换本波改动**（改前/改后 `close-wave.sh`），同一条腿＝删掉 `evidence/leg_23.env`：
  **改前 ⇒ `FP_INPUTS_HYGIENE=PASS coverage_n=172`（证据件消失而门禁全绿 ＝ 病）**；
  **改后 ⇒ `FAIL reason=coverage-member-missing missing_n=1 coverage_n=192`（看见并点名 ＝ 修）**；还原 ⇒ 回绿。
- **`J7`（落仓后现取）**：`[12]` 机读行 `coverage_n=192 ∧ missing_n=0 ∧ stderr_bytes=0 ∧ artifact_n=0`。
- **`J0`（**落地前写死的预测**，落地后必须逐位相符）**：改后 `close-wave.sh` ＋ 192 件的整波自印
  `inputs_fp` = **`5b92204468d65d7694b0b462500287e46e6e25debf0a4d5ddb559a6295e29ea4`**
  （由影子沙箱算出；**覆盖面上 192 件与真树逐字节相同 ⇒ 这是一个可证伪的预测**）。
  ⚠️ **`J0` 有两版，两版都留档**（不许事后只留对的那个）：第一版 **`d1d2d3306a9bb39d1c11973ab5c7f58319a366f269c6a2e0e3e12f4f7969c453`**
  由**修前**补丁算出；`P2` 腿（真旁观进程）当场咬出 `close-wave.sh` 里 census 件的**一格一行 vs 一行三格**
  解析缺陷（`IFS='=' read` 会把第一格之后的内容全塞进 `v` ⇒ 机读行印成
  `examined=143 hits=0 undecidable=0 hits=0 undecidable=0` 的**畸形读数**；`D-G120` 家族：形状看着完好、内容已错位）⇒ 补丁更正（**一件一行**）后**重算**为本值。

### 2.3 `TASK-0727` 判据（三面；机读行**必须**带 `cap=1`）

- **机读行**：`APP_PROBE_GUARD=<PASS|BLOCK|NOINFO…> faces=3 face3=cap cap=1 examined=<n> hits=<n> undecidable=<n>`。
- **面①`face=exe`**：`/proc/<pid>/exe` **基名** ∈ {`WpfTextDemo`, `WpfFeatureProbe`} ⇒ **判为应用**。
- **面②`face=argv-asm`／`face=launcher`**：`argv[0]` 基名 ∈ {`dotnet`, `dotnet-<版本>`} ∧ **被执行的那一项**
  （`argv[1]`；`argv[1]=exec` 时取 `argv[2]`）基名 ∈ {`WpfTextDemo.dll`, `WpfFeatureProbe.dll`} ⇒ **判为应用**；
  或 `argv[0]` 基名 ∈ {`bash`,`sh`,`dash`,`ksh`,`zsh`} ∧ `argv[1]` 基名 ∈ {`run-wpftextdemo.sh`, `run-wpfprobe.sh`,
  `run-wpfprobe-1400rate.sh`} ⇒ **判为应用**。**命令行里只是提到**这些名字（`argv[1]` 不是它们）⇒ **不判**。
- **面③`face=cap`**：`exe` 是 `dotnet` 族而 `argv` **判不了**（为空／读不到）⇒ 记 `cap=1`／`undecidable=<n>`，
  机读行转 `NOINFO`。⚠️ **这是刻意的：判不了就不挡，但绝不冒充绿** —— 依据＝主控入库的环境读数 `K16`
  （`["dotnet","WpfFeatureProbe.dll","3"] ⇒ cmdline=[]`）。**风险方向 = 假阴**（真应用在跑却漏检 ⇒
  重建会覆盖被 mmap 的 `.so`）⇒ **如实登记；`undecidable>0` 时本步不算全绿**。
- **`P1`（正极／真阳腿）**：真 apphost `samples/WpfFeatureProbe/bin/Debug/net10.0/WpfFeatureProbe` 真跑着
  （私有 `:23x`、走 `~/heavy-slot.sh`）⇒ `rc=3` ∧ **点名该 pid** ∧ `…=BLOCK`。
- **`P2`（反极／假阳腿）**：真 `bash -c` ＋ heredoc 正文里提到 `WpfFeatureProbe`／`WpfTextDemo`（`#66` 现场同形）
  ⇒ **不挡**（走到计划行）∧ `hits=0`。
- **`P3`（旧码对照腿）**：**改前副本**（`cp -a` 真拷贝）里**内容锚抽原文原样跑**的旧判据，在同一旁观进程在场时
  ⇒ **必 `exit 3`**（假阳性挡波的现场复现）。成对归因：`P2`／`P3` **只换被判件**（新判据／旧判据），
  **旁观进程与时刻不变**。
- **`P4`**：`cap=1`／`face3=cap`／`undecidable=` **必须在机读行里**（不许只活在注释里）。
- **`P5`（步数账，纪律 46 的唯一不变量）**：**首行 `DECL` 声明的步数 == 现取 `grep -c '^run_step "'` 数**
  （`42 == 42`）∧ `VERIFYALL_SELF=PASS names=42 decl=42 gen=#71 dup=0 order=OK prose=OK prereg=PASS`。
  ⚠️ **禁止**把「`DECL` 行数 == `run_step` 数」写成断言（现读 `DECL` 行数 **38** ≠ 步数 **42**）。
- **`P6`（本件自己不许被牙咬）**：改后的 `build/close-wave.sh` 必须让第 `[27]` 步 `PROC-PATTERN-GUARD` 仍 `PASS`
  —— 新的 `/proc` 枚举**写成字面路径**（`/proc/<pid>/…`）以便**被那条牙看见**，并靠 `self_chain_pids`
  的**祖先链**证明取 `full`（**宁可见而受审，不可隐而免审**）；`[21] QUOTE-TRAP` `traps=0`；`[22] PIPEFAIL-SIGPIPE` 不新增站点。

**判否条件**：任一 `J*`／`P*` 不成立 ⇒ 本波**停手**、按实报主控（**不许**改判据凑绿）。

## §3 两极化（**先写判据再跑**）

| 腿 | 只有一个变量 | 期望 |
|---|---|---|
| `J2` 影子保真 | 改前 `cw` ＋ 退回 20 件 | 指纹逐位 `== 0e8254f8…`（172 件） |
| `J3` 逐件归因 ×20 | **只换那一件**（去／还原） | 去 ⇒ 必变；还原 ⇒ 逐位回到 `J0` |
| `J4` 覆盖面内 | **只改内容** | 必变；（对照片＝原有件也必变） |
| `J5` 覆盖面外 | **只新增一件** | **逐位不变** |
| `J6` 病／修 | **只换本波改动** | 改前 `PASS 172`（看不见）／改后 `FAIL missing_n=1 192`（看见） |
| `P1` 真阳 | 真 apphost 在跑 | `BLOCK` ＋ 点名 |
| `P2` 假阳 | 真 `bash -c` heredoc 提到 | 不挡 |
| `P3` 旧码 | **只换被判件**（旧判据 vs 新判据） | 旧判据必（假）挡 |
| 面③ | `argv` 被吃掉的 `dotnet` | `cap=1`／`NOINFO`（**不挡、也不绿**） |

## §4 边界（逐条 `NOINFO`／不覆盖，如实划界）

1. **面③判不了 ⇒ 不挡**（风险方向＝**假阴**）；`undecidable=0` 是本波唯一可接受的现场读数。
2. `exe` **读不到**的进程（内核线程／僵尸）**出射程**：依据＝无用户态 mmap ⇒ 不可能持有被覆盖的 `.so`。
3. `argv[1]` 判"脚本本体"：把启动器路径**当参数传给另一个脚本**时仍会假阳（旧规则**更宽**；现场未出现过）。
4. 覆盖面**只保护"改了会被看见"**，**不判"该收的没收"**（`#70` 已登记，本波**不放宽**）。
5. 本步**只**判"无应用本体在跑"，**不**判"波次串行"（并发两条波占用 ⇒ **不在本任务口径**；主控 `#71` 裁定：
   旧行为本就不挡 `verify-all.sh`，纳入即行为扩面 ⇒ **须另开任务、判据先写**）。
6. `evidence/` 进覆盖面 ⇒ **有意重产证据（重跑装置）必须安排在 `IN_FP_0` 采样之前**，否则 `close-wave.sh`
   自己的 `[4/6]` 输入稳定性检查 `exit 5`（与 `#29`／`#31` 流程代价同族）。
7. `FPHYG_*`／`FPMS_*` 派生的"影子沙箱"读数**只是预演**：权威读数是**落仓后**在真树上的 `[12]`／`[42]` 现取行。

## §5 覆盖面转移的**逐件清单**（`172 → 192`；后来者可据此复算这个 delta）

**新增 20 件**（`build/MilBridge/tests/PtsPagesProbe/`；`sha16` 现取）：

1. `session_inner.sh` `5ef538137c6700aa` ｜ 2. `navclick.py` `e3d8b6ec4f5a4f6a` ｜
3. `legs-to-env.py` `40105fec0b66d055` ｜ 4. `shotstat.py` `65dea80e885c9f37` ｜
5. `evidence/app_g1.log` `3a3544fe9d6f8132` ｜ 6. `evidence/device.txt` `2bcc511da037c43b` ｜
7. `evidence/session.txt` `aa54c327751c5666` ｜ 8. `evidence/leg_23.env` `834071a14e342f56` ｜
9. `evidence/leg_24.env` `1e950605961e45b8` ｜ 10. `evidence/arm_A/device.txt` `2bcc511da037c43b` ｜
11. `evidence/arm_A/leg_23.env` `834071a14e342f56` ｜ 12. `evidence/arm_A/leg_24.env` `1e950605961e45b8` ｜
13. `evidence/device/xvfb.log` `e3b0c44298fc1c14`（**0 B＝合法**） ｜ 14. `evidence/device/xfwm.log` `85570d5b4527e380` ｜
15. `evidence/five_pre_g1.txt` `831d879ce0abd318` ｜ 16. `evidence/five_post_g1.txt` `831d879ce0abd318` ｜
17. `evidence/shots/g1/boot.png` `4bdf761f881c8aee` ｜ 18. `evidence/shots/g1/k23.png` `21ac4fc1a859b030` ｜
19. `evidence/shots/g1/k24.png` `563ba19112b5c94e` ｜ 20. `evidence/shots/g1/last.png` `21ac4fc1a859b030`。

**转移算式**：`172（`#70` 收官值，现取成员表 172 行） + 20 = 192`；`192` 由**影子沙箱**（§2.2 `J2`）
先证保真、再由 `J2`／`J3`／`J4`／`J5` 逐条钉住；`J0` 给出**落地前写死的**整波指纹预测。
**为什么是这 20 件**（`TASK-0729` 原话）：`fp_inputs()` 原先只显式收录 `pts-pages-guard.sh`（判据件）与
`run-pts-pages-legs.sh`（装置入口）**两件** ⇒ 其余 20 件（含 `leg_*.env` 证据）**改了本步照样绿**
⇒ 第 `[38]` 步 `PTS-PAGES` 的**判据输入不受指纹保护**（`D-G122` 形态：判据的输入没人看着）。

## §6 `--expect`：**声明常数**，与覆盖面**同趟改**（判据句，**不许放宽**）

`verify-all.sh` 第 `[42]` 步 `FP-MANIFEST-TEETH` 的 `--expect N` 是**手写常数**，`verify-all.sh`
**不在** `fp_inputs()` 覆盖面 ⇒ 它与生产路径**无关**（这正是牙头推荐的唯一来源）。**覆盖面变 ⇒ 本常数必须同趟改**
（`172 → 192`），**漏改 ⇒ 当场 `FAIL reason=files-n-mismatch delta=-20`**（**方向安全**）。现测成对读数：
`--expect 172` ⇒ `PASS`；`--expect 171` ⇒ `FAIL delta=1`；`--expect 192`（未同趟改覆盖面）⇒ `FAIL delta=-20`；
同趟改后 ⇒ `PASS files_n=192`。⚠️ **射程（照抄 `#70` 已登记的边界，本波不放宽）**：它是**声明常数**，
能抓"漏改"，**抓不到**"覆盖面与常数被同一个人同趟改成同一个错值"。
