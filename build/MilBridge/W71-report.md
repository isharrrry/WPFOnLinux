# W71-report.md —— 波 `#71`（`TASK-0729` ＋ `TASK-0727`）落仓报告（车道 **W169A**）

> 判据先写：车道侧 `criteria.md`（`e9bbbac657f44802`，落仓前封存）→ 逐字搬进仓内
> `docs/WAVE71-PREREGISTRATION.md`（`c41d0a362ba6eec9`）。两极化设计在**跑任何腿之前**写死。
> ⚠️ 本波**落仓件不含车道路径**（`D-G137`）：`build/close-wave.sh`／`verify-all.sh` 里本波新增文本 `grep -cE '$HOME/w|~/w'` = **0**
> （两件里原有的 1／6 条命中**全在历史注释**，且**改前改后同数** —— 配对读数）。

## §0 结论

- **`gen=#71`｜基线 `83f6f475c9395e72` → `cc814b708c141ae8`**（`FREEZE_RC=0`；`# RE-FROZEN #71` 命中 1；残留占位符 0）。
- **不加步**（`42 → 42`）：首行 `DECL` 42 == 现取 `grep -c '^run_step "'` 42。
- **覆盖面 `172 → 192`**（`fp_inputs()` **+20 行**，逐件归因）。
- **零产品位移**：九位只有**环成员** `pf` 变（`bea7e47e42fd4e01 → e9fe77a43f950f2c`，**同尺寸 6,123,520 B**）；其余八位逐位未变。
- 落仓 3 件（`%h==1` 逐件断言、temp ＋ `mv` 原子替换）：`build/close-wave.sh` **`6297e03253232b39` → `247cb3d16e2a5392`**（41,471 → 52,186 B）／
  `verify-all.sh` **`93ae21cdaf712567` → `d5829ded84c7adb3`**（147,267 → 149,949 B）／`docs/WAVE71-PREREGISTRATION.md`（**新建** `c41d0a362ba6eec9`）。

## §1 `TASK-0729`：覆盖面 172 → 192（**这一对数怎么来的、怎么被钉住的**）

**现场（`TASK-0729` 原话）**：`fp_inputs()` 原先只显式收录 `pts-pages-guard.sh`（判据件）与
`run-pts-pages-legs.sh`（装置入口）**两件** ⇒ `PtsPagesProbe` 的**装置 4 件 ＋ `evidence/` 16 件**全在覆盖面之外
⇒ **改了它们（含 `leg_*.env` 证据）第 `[38]` 步照样绿** ⇒ 判据的输入**不受指纹保护**（`D-G122` 形态）。

**转移算式**：`172（`#70` 收官值，现取成员表 172 行）＋ 20 ＝ 192`。20 件逐件 `sha16` 见预登记 §5。

**怎么被钉住的**（全部现跑，日志 `logs/polarity-fp.log`）：

1. **影子保真**（先证"影子是现树的忠实影子"，否则后面的腿没有意义）：影子沙箱＝**真拷贝**（禁硬链接，
   `find -links +1` 实测 **0** 件）；装**改前** `close-wave.sh` ＋**退回这 20 件** ⇒ 指纹**逐位 `== 0e8254f8cf842836…`**
   （＝现树值）∧ 成员 **172** ⇒ ✅。
2. **逐件成对归因 20/20**：每件 `去 ⇒ 指纹必变`／`还原 ⇒ 逐位回到前值` ⇒ **没有第三隐形位移**。
3. **覆盖面内改动必变**：新收件（`session_inner.sh`）与原有件（`nl-intent-check.sh`）**都必变**，还原均回原值。
4. **覆盖面外新增不变**：在 `PtsPagesProbe/` 下新建一件不被任何 `find` 模式命中的件 ⇒ 指纹**逐位不变**、成员仍 192。
5. **病／修成对（只换本波改动）**——本件最值钱的一条（`FPHYG` 牙在**沙箱**上跑，真树白名单一字未改）：

   | 配置 | 同一条腿：删掉 `evidence/leg_23.env` | 读数 |
   |---|---|---|
   | **改前**（20 件在树上但**不在**白名单） | 证据件消失 ⇒ | `FP_INPUTS_HYGIENE=PASS reason=clean coverage_n=172 missing_n=0`（**看不见 ＝ 病**） |
   | **改后**（收进白名单） | 同一腿 ⇒ | `FP_INPUTS_HYGIENE=FAIL reason=coverage-member-missing missing_n=1 coverage_n=192`（**看见并点名 ＝ 修**） |
   | 还原 | — | 回绿（`PASS coverage_n=192`） |

6. **落仓后真树现取**：`[12]` `coverage_n=192 artifact_n=0 missing_n=0 stderr_bytes=0`；`[42]` `files_n=192 declared_expect=192`。

**`--expect` 是声明常数、与覆盖面同趟改（判据句，不许放宽）**：`verify-all.sh` **不在**覆盖面（现场 `hit=0` 机械证）
⇒ 该常数**与生产路径无关**，是牙头推荐的唯一来源。现测成对读数：`--expect 172` ⇒ `PASS`；`--expect 171` ⇒ `FAIL delta=1`；
`--expect 192`（**未同趟改覆盖面**时）⇒ `FAIL reason=files-n-mismatch files_n=172 delta=-20`；同趟改后 ⇒ `PASS files_n=192`。
⚠️ **射程（照抄 `#70` 已登记的边界，本波不放宽）**：它抓"漏改"（方向安全），**抓不到**"覆盖面与常数被同一个人同趟改成同一个错值"。

## §2 `TASK-0727`：前置检查从"按命令行文本"改成"按可执行件名"

**现场（`D-G34` 残余）**：`2026-09-24` 波 `#66` `18:42:45`，一条**推文档的 shell**（`bash -c … python3 - <<'PY' …`，
heredoc 正文里提到 `WpfFeatureProbe`／`WpfTextDemo`）被旧判据 `pgrep -af "$APP_PROBE_RE"` 判成"有应用/探针在跑"
⇒ **整波被挡一次**（0 损害，但**挡波的理由与要做的动作完全相反**）。

**修法三面（写死在 `[0/6]`；机读行 `APP_PROBE_GUARD=<PASS|BLOCK|NOINFO…> faces=3 face3=cap cap=1 examined= hits= undecidable=`）**：

- **面①`face=exe`**：`/proc/<pid>/exe` **基名** ∈ {`WpfTextDemo`, `WpfFeatureProbe`}（apphost 被直接执行）⇒ 应用。
- **面②`face=argv-asm`／`face=launcher`**：`argv[0]` 是 `dotnet` 族 ∧ **被执行的那一项**（`argv[1]`；`argv[1]=exec` 时取 `argv[2]`）
  基名 ∈ {`WpfTextDemo.dll`, `WpfFeatureProbe.dll`}；或 `argv[0]` 是 shell ∧ `argv[1]` 基名 ∈ {`run-wpftextdemo.sh`, `run-wpfprobe.sh`,
  `run-wpfprobe-1400rate.sh`} ⇒ 应用。**命令行里只是提到**这些名字（`argv[1]` 不是它们）⇒ **不判**。
  ⚠️ **波内构建**跑的是 `dotnet …/MSBuild.dll …`（`argv[1]` 是 `MSBuild.dll`）⇒ **构造上不会命中**（旧规则是**子串**，
  任何提到 `WpfFeatureProbe` 的命令行都命中）。
- **面③`face=cap`（**刻意的能力边界**）**：`exe` 是 `dotnet` 族而 `argv` **判不了**（为空／读不到）⇒ `cap=1`／`undecidable=<n>`、
  机读行转 `NOINFO`。⚠️ **判不了就不挡，但绝不冒充绿**；依据＝主控入库的环境读数 `K16`
  （`["dotnet","WpfFeatureProbe.dll","3"] ⇒ cmdline=[]`）；**风险方向＝假阴**（真应用在跑却漏检 ⇒ 重建会覆盖被 mmap 的 `.so`）。
- **顺序**：`hits>0` ⇒ `BLOCK` ＋ `exit 3` ＋ 逐条点名；否则 `undecidable>0` ⇒ `NOINFO`；否则 `PASS`。
  **纪律 5**：`census` 件读不到／`examined==0` ⇒ `NOINFO`（**零检查不许当绿**）。
- ⚠️ **为什么不把 `verify-all.sh` 也算"占用"**：它不是应用本体，**旧行为本来就不挡**它 ⇒ 纳入是**行为扩面**，
  不在本任务口径内（主控 `#71` 裁定：要它须另开任务、判据先写）。

**两极化（全部真进程，禁假进程）**：

| 腿 | 真进程 | 读数 |
|---|---|---|
| `P1` 真阳 | 真 apphost `samples/WpfFeatureProbe/bin/Debug/net10.0/WpfFeatureProbe`（私有 `:233`、走 `~/heavy-slot.sh`、真跑） | `rc=3`；`BLOCK faces=3 face3=cap cap=1 examined=148 hits=1 undecidable=0`；点名 `pid=285075 app face=exe exe=WpfFeatureProbe` |
| `P2` 假阳 | 真 `bash -c` ＋ heredoc 正文提到名字（`exe=bash`、`argv[1]=-c`；**形状当场断言 cmdline 含模式**） | `rc=0`；`PASS … examined=145 hits=0 undecidable=0` |
| `P3` 旧码对照 | **同一旁观进程、同一时刻**，改前副本**内容锚抽原文原样跑**的旧判据 | `rc=3` ＋ **点名该 pid**（假阳复现） |
| 面③ | 分类器单测（`exe=dotnet` ∧ `argv` 空 ⇒ `cap`） | ✅（真机未挂住活进程 ⇒ 见 §5.1） |

**本波自己那趟波的在场读数**（主控硬条件）：`APP_PROBE_GUARD=PASS faces=3 face3=cap cap=1 examined=144 hits=0 undecidable=0`
⇒ **新判据没有假挡本波**（这正是"修掉了病"的正面证据）。

⚠️ **`/proc` 枚举写成字面路径是为了被看见**：写成 `$d/cmdline` 时第 `[27]` 步 `PROC-PATTERN-GUARD` **看不见**本行
（同行内既要有 `/proc` 又要有 `cmdline`）⇒ 那是"靠看不见过关"的假绿形态。改后现取：
`PROCGUARD=PASS reason=all-hits-proved`，本行 `build/close-wave.sh:417 form=PROC verdict=full proof=ancestor-chain via-helper:self_chain_pids`。
成对读数（只换本波改动）：**改前 `form=P2 pgrep`／改后 `form=PROC`**，两臂都 `PASS`。

## §3 四处声明（**不动步数**形态）＋ 落仓后自检

- 新 `DECL`：`# VERIFYALL-STEPS-DECL: 42 gen=#71`（插在现第一行之前 = newest-first；`decl_line()` 取 `head -1`，`D-G131`）。
- 口径句：``#   **`#71` 收官起 = 42 步**``（`verify-all-step-check.sh` 用 `grep -qF` **逐字**找）。
- `STEP-NAMES`：**一字不改**（本波不加步）。
- 预登记 `docs/WAVE71-PREREGISTRATION.md`：标题含 `#71`；「判据」节内逐字声明「本波不做任何回归判定」＋ 机读行
  `PREREG-NO-REGRESSION-DECISION: yes` ⇒ 现取 `PREREG4_FILE … state=na reason=no-regression-decision-declared`（`rc=0`）。
- 落仓后现取：`[11]` `VERIFYALL_SELF=PASS names=42 decl=42 gen=#71 dup=0 order=OK prose=OK prereg=PASS`；
  `bash -n` 两件均过；`%h` 全 1；`D-G137` 新增文本 0 条。

## §4 关键读数表（三趟 `verify-all` ＋ 门禁 ＋ 冻结）

| 量 | 值 |
|---|---|
| `gate1`／`gate2`／`pre` | 各 `步骤通过 42 ❌ 失败 0` ∧ `结论：✅ 全部通过`（`用例通过 875 跳过 2`） |
| `[7]` | `BASELINESHA=PASS live=83f6f475c9395e72 decl=83f6f475c9395e72`（冻前仍是 `#70` 值） |
| `[12]` | `FP_INPUTS_HYGIENE=PASS reason=clean coverage_n=192 artifact_n=0 missing_n=0 stderr_bytes=0`（现算 `covnf=192`） |
| `[42]` | `FP_MANIFEST_TEETH=PASS reason=ok files_n=192 files_n_uniq=192 blank_n=0 declared_expect=192 declared_paths=none` |
| `[38]`／`[40]`／`[41]`／`[17]`／`[21]`／`[27]` | `PTS_GUARD=PASS legs=2/2`／`BAK_COMPLETENESS=PASS n_wired=0`／`ALIAS=PASS aliased_unallowed=0 reason=known-alias-trees`／`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0`／`SHELL_QUOTE_TRAP=PASS traps=0`／`PROCGUARD=PASS` |
| 应用门禁 ×2 | `rows=6/6 result=PASS`；`WPTD_SUMMARY=PASS tiers_passed=2/2`；`WPTD_GATE=PASS acceptance=2/2`；`GATE_LINES_IDENTICAL=yes`（口径：**归一化 `wall_s=` 计时字段**） |
| 整波 | `close-wave.sh --skip-verify-all` `rc=0`；`输入稳定性 波前==波后 == 5b922044…`；`native_rebuilt=0 bridge_republished=0` |
| **`J0` 落地前预测** | `5b92204468d65d7694b0b462500287e46e6e25debf0a4d5ddb559a6295e29ea4` **== 整波自印波前指纹**（逐位） |
| 冻结 | `FREEZE_RC=0`；`BASELINE_SHA16=cc814b708c141ae8`；`PREV=83f6f475c9395e72`；占位符 0；`# RE-FROZEN #71`=1 |

## §5 如实划界（`NOINFO`／未做）

1. **面③只在单测里被触发**：没能真机挂住"`exe=dotnet` 而 `argv` 为空"的**活**进程（无参 `dotnet` 立即退出）⇒
   三趟现场 `undecidable=0` 是**"没观察到"**，**不是**"证不存在"。
2. `argv[1]` 判"脚本本体"：把启动器路径**当参数传给另一个脚本**时仍会假阳（旧规则**更宽**）；该反例**未真机演示**。
3. 覆盖面**只保护"改了会被看见"**，**不判"该收的没收"**；`TASK-0729` 的第 (ii) 候选（`[38]` 升级为"自己跑腿"）**未实现**（原话"本波只声明不扩"）。
4. `exe` 读不到的进程（内核线程／僵尸）**出射程**（无用户态 mmap ⇒ 不可能持有被覆盖的 `.so`）—— 口径已写进预登记。
5. 两趟 `verify-all` 的"判词行相同"口径 = **归一化 `wall_s=`**；其余 per-run 字段（`outdir=`／`mem_mb=`／`magenta_frames=`／
   运行目录时间戳）**确实每次不同** ⇒ 不冒充"逐字相同"。
6. `[42]` 驱动行**不在** `verify-all` 自报口径面 ⇒ 判据 = "步标记 ✅ ＋ 牙判词逐格"（同 `#70`）。
7. 旧码对照腿用**归档真拷贝**的**内容锚原文**（真树已落仓，旧件不在树上）。

## §6 三处自伤（都被我自己的腿／守卫当场抓住；如实留档）

1. **`census` 件格式错**：计数原写成**一行三格**（`examined=… hits=… undecidable=…`），读取端是 `IFS='=' read -r k v`
   ⇒ `v` 被塞成 `"143 hits=0 undecidable=0"`、机读行印成 `examined=143 hits=0 undecidable=0 hits=0 undecidable=0`（**畸形读数**）。
   **被本波自己的 `P2` 腿当场咬到** ⇒ 改**一件一行**并**重算 `J0`**（两版都留档在预登记 §2.2）。
   教训：**机读行要当场读一遍**，不能只信"变量算对了"（`D-G120` 家族）。
2. **旁观进程形状假**：`nohup bash -c '…'; sleep 300` 时 bash 把最后一条命令 **exec** 掉 ⇒ 进程映像变成 `sleep 300`、
   cmdline 里**没有** heredoc 正文 ⇒ `P3` 一度判成"旧码没假阳"（**假读数**）。修法＝尾随**内建命令**（`:`）阻断 exec 优化，
   并在起进程后**当场断言 cmdline 含模式**。教训：**"用真进程演示"必须核进程形状**。
3. **冻结器相对路径**：我先用相对日志路径 ⇒ 冻结器 `cd $R` 后 `FileNotFoundError` ⇒ `FREEZE_RC=1`；
   守卫**当场 `STOP`、不写 `DONE`、未动盘**（当时基线仍 `83f6f475c9395e72`、`CURRENT-STATE` 仍 `gen=#70`）
   ⇒ 改 `readlink -f` 转绝对路径后 `RC=0`。**这是"守卫有效性"的正面证据**（同 `#70` 的范式）。

## §7 推送／app-local／哨兵

逐径 `git add`（**绝不** `-A`／不从 `git status` 生成清单）；**必须排除主控五件**（`KNOWN-DEFECTS.md`／`ROUTES.md`／
`HANDOFF-NEXT.md`／`FORK-AND-PUSH.md`／`defect-registry-declared.tsv`）；推后 `ls-remote` ＋ **逐件 `HEAD:` 字节核**
（`BYTECHECK ok=N mismatch=0`）；app-local 合格线 `STALE=0 ∧ DIVERGENT=0`；两哨兵（`/tmp/bridge-frozen.flag` ＋
`~/wfp-runs/bridge-frozen.flag`）补 `BASELINE=#71` ＋ `BASELINE_SHA16=cc814b708c141ae8` 并 `cmp` **IDENTICAL**。
