# T1b3 · 文本 harness「在册红登记制」门禁 —— 交付报告（rev 3）

- 日期：2026-09-15
- 轨道：T1b3（唯一写者范围：只新增 3 个文件：`tline-gate.sh` / `known-red.json` / 本报告）
- 判据口径版本：**`t1b3-tline-gate/2`**
- 登记表 schema：**`tline-known-red/3`**；绑定世代：**`#13-legA`**
- 一句话：门禁是**只读读者**（不跑 harness、不构建、不写别人的产物）；在册红 6 条重钉到
  **有完整读数的 `#13-legA`**；三极自检 `0/1/1/2` + 三项附加测试全部实测通过。

---

## 1. 交付物

| 文件 | sha256 前 16 |
|---|---|
| `build/MilBridge/tools/tline-gate.sh` | `b8863c8d9f8ea59b` |
| `build/MilBridge/known-red.json` | 见最终消息 |
| `build/MilBridge/T1b3-tline-gate-report.md`（本文件） | 见最终消息 |

一条命令（**只认日志**）：
```bash
bash build/MilBridge/tools/tline-gate.sh --log <日志> [--log <日志> ...]
bash build/MilBridge/tools/tline-gate.sh --logdir <目录>      # 扫 *.log，按内容自动识别臂
```
⛔ **跑的能力已彻底删除**（主控裁定 ③）。没有 `--log`/`--logdir` ⇒ `NOINFO` + 退出码 2。

### 门禁的**唯一**两个写入点（自证无越界的基础）

```
$ grep -n 'open(.*"w"\|>>' build/MilBridge/tools/tline-gate.sh
  181:  printf '%s\t%s\t%s\t%s\n' … >> "$ARMS_TSV"                          # = $OUTDIR/arms.tsv
  605:    with open(os.path.join(outdir, "gate-readings.json"), "w", …)     # = $OUTDIR/gate-readings.json
```
两处**都在 `--outdir` 之下**（默认 `$HOME/wfp-runs/tline-gate-<ts>`），**一处都不在仓库里**。

---

## 2. `#13-legA` 的腿判定（**从日志本身读，不靠猜**）

> **结论：`#13-legA`** —— `T1B_MODIFIER_META` **未设** ⇒ 传 modifier meta = **出货行为**。

| 判别量 | `tline-wave13.log` | 腿B（`tline-wave13-B-nometa.log`） |
|---|---|---|
| `[口径·宽度分桶]` | `0=168 / ≤0.34DIP=1096 / >0.34DIP=34` | `0=168 / ≤0.34DIP=1089 / >0.34DIP=41` |
| 最大差 | `6.716667 @ A1_nbsp_zwsp_w120` | `282.219333 @ M_modifier_winf` |

与项目自己的 A/B 权威表逐字一致（`docs/CURRENT-STATE.md:18`、`WAVE25-FINAL-ROUND.md:39`、
`NEXT-WAVE-13-CHECKLIST.md:151`）。依据写进 `known-red.json` 的
`generation.leg_resolution{conclusion,how,cross_check}`。

| 世代 | 值 |
|---|---|
| generation | `#13-legA` |
| `instr_run_sh` | `3e513e88a4fa4ec96433ad722ca9c668b757f14d5e26b0e046a8356ec2e4b53e` |
| `instr_program_cs` | `2e458928fc1577c2c52562cd96ae519dfec1fbcc7dd2a9b0b2fb87cbaf8a87b1` |
| `instr_shim` | `fde9e511e8443cf28a95ff73d36c3c36ccb77b138244f25cb079d56c3e71f2d6` |
| 证据日志 | `/home/links-dev/wfp-runs/tline-wave13.log` |

**树一直在动**：本趟交付期间树上的 shim 从 `17b2cdfe`（#14）变成了 `16db2d61`（11:35:56，别的车道）。
门禁对此**只作信息报出**（`tree_gen=advanced`），**不阻断**判读一个**自报属于 `#13-legA`** 的日志
—— 这正是"登记表绑世代而不是绑当前树"的目的。

---

## 3. 登记内容（6 条，全部与真实日志逐条对账）

| # | arm | case_id | field | expected_shape | carrier（这条红当前由谁承载） |
|---|---|---|---|---|---|
| 1 | tline | `T2-记账结构` | `逐行记账·结构` | `1298/1298` | **widthDeltaLarge**（子项已全绿，红由宽度承载） |
| 2 | tline | `T2-宽度超差` | `宽度超差行数` | `count==34` | 本条读数本身 |
| 3 | tline | `T3-Collapse明细` | `Collapse明细全等` | `225/236` | 本条读数本身（折后明细） |
| 4 | tline | `T2d-Extent余差` | `Extent余差条数` | `count==59` | 本条读数本身（0.01 紧口径残差） |
| 5 | tab-oracle-zero | `notab-control@w40@em24@RTL@tab0` | `结构败` | `count==1` | 本条读数本身（该 case 结构=FAIL） |
| 6 | tline | **`T3b`** | `判据状态` | `❌` | **T3b 判据本身（根因未定位）** ← `unlocated: true` |

- 字段表已写进 `known-red.json` 的 **`_FIELDTABLE`**（= 文件头注释；JSON 无注释语法，故用数组）。
  含 `generation{}` / `carrier` / `expected_shape` / `instr_*` / `reason` / `owner` / `date` /
  `unlocated` / `red_authority` 全部字段的语义。
- 头部 `note` 明写：**这份表本身会陈旧、它绑的是 `#13-legA` 而不是当前树**；新世代
  **一个数字都没登记（不许编）**。

### 3.1 第 6 条 `T3b`：**未定位的在册红**（主控裁点 A）

- `unlocated: true` ⇒ 门禁打 **`KNOWN_RED_UNLOCATED`**（与普通 `KNOWN_RED` **不同的 marker**，
  **逐趟点名**），并在机器行给出 `unlocated=1` 计数。
- `reason` 逐字写明：『该世代已存在的 harness 判据失败，**含义/根因未定位**（不装作已容忍）』。
- `owner` = `T1b2/T3 待派`。
- **登记 ≠ 已理解、更 ≠ 已容忍** —— 它只为让门禁在 `#13-legA` 这一世代**可判**。
- **免费的正向信号已验证**：夹具 `t3bgreen`（把 T3b 改成 ✅）⇒
  `KNOWN_RED_GONE tline/T3b :: 登记形状='❌' 实得='✅'` + `GATE_REASON=registry-stale(gone)`，
  退出码 **1**。⇒ 新世代 T3b 若转绿，`gone` 机制会**自动点出来**。

### 3.2 `carrier`（主控裁点 B 的补充字段）

每条都有 `carrier`，且门禁把它印在**点名行**里，例如：
```
  KNOWN_RED          tline/T2-宽度超差 :: 实得='34'（形状如登记）
                       carrier: **本条的读数本身**（`widthDeltaLarge = 34 > 0`）。它就是 T2 判据在 #13-legA 报红的唯一原因。
  KNOWN_RED_UNLOCATED tline/T3b :: 实得='❌'（形状如登记）
                       carrier: **T3b 判据本身**（`Check("T3b", …)`）。**承载细节未见 —— 根因未定位。**
```
红条件语义（裁点 B，已按裁定实现）：**红 = 该 field 的读数红 或 它的归属判据报 FAIL**；
`gone` 只在**判据整体转绿**时才报。第 1 条即为此例，门禁对它打
`READING_GREEN_BUT_JUDGE_RED`（读数 `1298/1298` 已绿，红由 T2 承载）。

---

## 4. 测试矩阵（**全部用最终版** `gate=b8863c8d9f8ea59b`；原样输出在 `$HOME/t1b3/evidence3/`）

| 场景 | 期望 | 机器行要点 | 退出码 |
|---|---|---|---|
| 正对照 `base`（忠实 #13-legA，含 ❌ T3b） | PASS | `PASS registered=6 unlocated=1` | **0** ✅ |
| **①** 在册红变绿 `gone` | FAIL+报消失 | `FAIL gone=1 unlocated=1` / `registry-stale(gone)` | **1** ✅ |
| **②** 未登记失败 `unreg` | FAIL | `FAIL unregistered=2` / `unregistered-failure` | **1** ✅ |
| **③** 缺数据/空输入 `empty` | NOINFO | `NOINFO noinfo_arm=5` / `noinfo-arms` | **2** ✅ |
| 附加 `t3bgreen`（T3b 转绿） | FAIL+报消失 | `FAIL gone=1 unlocated=0` / `registry-stale(gone)` | **1** ✅ |
| 附加 `drift` | FAIL+报漂移 | `FAIL drift=1` / `registry-stale(drift)` | **1** ✅ |
| 附加 `absorbed`（探针自带表吸收，rc=0） | 仍报 KNOWN_RED | `PASS registered=6 gone=0`（**没被 rc=0 骗**） | **0** ✅ |

`gone>0` 时的原话（逐字，已在 ①/附加 两处输出）：
```
  ⚠️⚠️ **在册红消失 = 读数变好或口径变了 ⇒ 必须人工裁定，不许自动放行**
```

---

## 5. 对**真实日志**实测

### 5a `tline-wave13.log`（自报 `shim=fde9e511` = 登记世代）⇒ **被判读**

```
── 臂 tline              RED  src=log  pairing=strong  caliber=OK-declared
TLINE_GATE=NOINFO arms=5 red=1 green=0 noinfo_arm=4 registered=5 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#13-legA tree_gen=advanced saved_shim=16db2d6194edc1f5
GATE_REASON=noinfo-arms    退出码 2
  KNOWN_RED          tline/T2-记账结构 :: 实得='1298/1298'（形状如登记）；READING_GREEN_BUT_JUDGE_RED（读数本身已不红，红由判据 T2 承载）
  KNOWN_RED          tline/T2-宽度超差 :: 实得='34'（形状如登记）
  KNOWN_RED          tline/T3-Collapse明细 :: 实得='225/236'（形状如登记）
  KNOWN_RED          tline/T2d-Extent余差 :: 实得='59'（形状如登记）
  KNOWN_RED_UNLOCATED tline/T3b :: 实得='❌'（形状如登记）
```
`unregistered=0` —— 加第 6 条后 T3b 不再被误报为"未登记失败"。整门仍 **NOINFO**，因为另外 4 个臂
**没有日志**（门禁是读者，不会自己去跑）。

### 5b `tline-wave14.log`
`caliber=MISMATCH`（自报 `17b2cdfe` ≠ 登记 `fde9e511`）+ 被信号杀死（rc=143）⇒ **NOINFO**。

### 5c `or13 tab-zero`
`caliber=UNVERIFIABLE`（CoverageProbe 不自报 shim sha 的**弱配对**；树已前进）⇒ **NOINFO**。

---

## 6. ⛔ L28 越界写入事故（交 T3 登记用）

### 事故原文

| 项 | 内容 |
|---|---|
| 装置 | 本门禁 rev1（已废弃语义） |
| 缺陷 | 只给一个 `--log` 时**默认会去跑**其余没给日志的臂（`DO_RUN=1`） |
| 触发 | `bash …/tline-gate.sh --log $HOME/wfp-runs/tline-20260914.log`（只想读一份旧日志） |
| 越界写入 | `run.sh textline` 被真的执行 ⇒ **重写 `build/MilBridge/gen/textline-proto.png`** |
| 证据 | mtime `11:15:13 → 11:23:06`；字节数 `4722 → 4722` |
| 无法自证 | **跑前没有备份** ⇒ **无法证明字节相同** |
| 附带 | 同批 3 个 tab 臂只失败在 `dotnet: 未找到命令`（当时没 `export PATH`）⇒ **没 build、没写任何东西** |
| 影响域 | `gen/` 是 **T3 的写域** |

**教训（一句话）**：**新装置的默认值必须先回答"它会不会写别人的文件"；越界写入即便字节相同也无法自证 ⇒ 默认必须"什么都不做"。**

### 修法（已落地）
1. **删净跑的能力**：`run_arm` / `DO_RUN` / `DO_BUILD` / `--run-missing` / `--no-run` /
   `--no-build` / 一切 `dotnet` 与 `run.sh` 调用 —— `grep -c` 全为 **0**。
2. **默认什么都不做**：无 `--log`/`--logdir` ⇒ `NOINFO` + 退出码 2。
3. **只有 2 个写入点，都在 `--outdir`**（见 §1）。
4. **牙（实测）**：见 §6.1。

```
$ for pat in run_arm DO_RUN DO_BUILD run-missing no-run no-build dotnet 'timeout 1200' TAB_JSON; do printf "  %-16s %s\n" "$pat" "$(grep -c -- "$pat" build/MilBridge/tools/tline-gate.sh)"; done
  run_arm 0 / DO_RUN 0 / DO_BUILD 0 / run-missing 0 / no-run 0 / no-build 0 / dotnet 0 / timeout 1200 0 / TAB_JSON 0
```

### 6.1 「无写入」原始输出

```
gen 文件数=86  全目录 sha=de09ae5747a5a2a32dbecec2d7f713a5
T0=1789443384  2026-09-15T11:36:24+08:00
loadavg 跑前 = 1.60 1.78 1.92
门禁退出码=2
  TLINE_GATE=NOINFO arms=5 red=1 green=0 noinfo_arm=4 registered=5 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#13-legA tree_gen=advanced saved_shim=16db2d6194edc1f5 gate=b8863c8d9f8ea59b judge=t1b3-tline-gate/2
gen 文件数=86  全目录 sha=de09ae5747a5a2a32dbecec2d7f713a5
loadavg 跑后 = 1.60 1.78 1.92
=== diff gen mtime BEFORE/AFTER ===  ✅ 无差异（86 个文件 mtime 逐字相同）
=== diff gen 全目录 sha  BEFORE/AFTER ===  ✅ 无差异（86 个文件 sha256 逐字相同）
```

**⚠️ 口径（**已由主控裁定写死，以后就用这两句**）—— 不许再写"整仓零改动"**：

> 在共享机上 **"整仓零改动"是不可证的主张**。任何"零改动"主张都要退化成下面两句：
> **(a) 我自己的写入点没被碰**；(b) **我关心的那个目录的 sha 未变**。

本趟按该口径自证：
- **(a)** 门禁只有 §1 那两个写入点（`$OUTDIR/arms.tsv`、`$OUTDIR/gate-readings.json`，**都在 `$HOME`**），
  仓库里**没有任何写入点** ⇒ 无被碰可能。
- **(b)** **`gen/**` 的 86 个文件 mtime + sha256 逐字不变**（那也正是 L28 的现场），
  全目录 sha 跑前 = 跑后 = `de09ae5747a5a2a32dbecec2d7f713a5`。

**同一时段的并发写入已归因（主控澄清）**：`find . -newermt @T0` 抓到的
`docs/CURRENT-STATE.md` 与 `docs/WAVE15-PREREGISTRATION.md`（mtime `11:36:24.19/.20`）
= **主控自己在同一时段并发去陈旧文档**（`#15` 重排 + `D-F1c` 落地状态），**与本门禁无关**。
⇒ 这正说明"整仓"口径不可用：共享机上**别人的写入与我的写入无法区分**。

---

## 7. 🔁 如何重钉到新世代（**三步** —— 这条流程本身就是今晚反复咬我们的那个坑的解药）

> 前置：**必须有一趟"跑完的"真实 harness 日志**（退出码 0/1，**不是 143**），
> 且它**自报**了被测件 shim sha（`run.sh tline` 的头行会报）。

**第 0 步（先确认能不能钉）—— 没有完整读数就*不许钉***：
```bash
grep -a '^通过 .* / 失败 '         <新日志>    # 缺 ⇒ 没跑到结论 ⇒ 不许钉
grep -a '→ harness 退出码 '         <新日志>    # >128（143=被信号杀死）⇒ 这趟不算读数 ⇒ 不许钉
grep -a '^\s*sha256=[0-9a-f]\{64\}' <新日志>    # 拿新世代的 shim sha（被测件）
```

> ### ⭐ 第 0 步的「`rc > 128` ⇒ 不许钉」这条判据 —— **由 `D-F1c` 事故直接催生**
>
> 它不是设计出来的，是**被事故喂出来的**：`#14` 世代 `run.sh tline` 在 T2/T3/T4 oracle 段
> 自旋/爆内存跑不完，实测 `run.sh tline rc=143`（`143 = 128+15` = 被 SIGTERM 杀死），
> 日志里**根本没有记账/宽度/Collapse 读数**，却**照样有** `→ harness 退出码 143` 这一行。
> 若无这条判据，"143" 会被当成一个普通的**非零 = 红**，于是**根本没跑完的一趟**
> 会被当成一次真实读数、并被拿去**重钉登记表** ⇒ 登记表会被钉在一堆**不存在的数字**上。
>
> 所以门禁里对应的是同一条硬规则（头部注释 + 实现）：
> **harness/探针退出码 >128 ⇒ 该臂 NOINFO，不当红也不当绿**；
> 配套的还有 **"缺结论行 ⇒ NOINFO"**（缺数据 ≠ 通过）。
> 这条**正好把 `D-F1c` 那次挂死挡在门外** —— 它是本门禁里唯一一条"从事故反向长出来"的判据。

**第 1 步（跑一趟真实 harness）—— ⚠️ 这是波/维护动作，不是门禁的活**：
```bash
sha256sum build/MilBridge/run.sh \
          build/MilBridge/tests/HbTextLineParity/Program.cs \
          build/shims/PresentationCore.HbTextLine.cs        # ← 这三项 = 新世代的三项仪器
bash build/MilBridge/run.sh tline > "$HOME/wfp-runs/tline-<新世代>.log" 2>&1
echo "rc=$?"        # 必须 ≤128；跑前记 loadavg、查第二写者；它会写 gen/ ⇒ 别和 T3 撞车
```
（tab 三臂 + `textlineproto` 臂的日志另由维护动作提供 —— 门禁**不会**自己产生它们。）

**第 2 步（抄读数）—— 只抄*日志里印出来的*，不推导、不换算**：
| 字段 | 从日志里抄哪一行 | 别忘 |
|---|---|---|
| `逐行记账·结构` | `[逐行记账·结构] … 全等 X / Y` | |
| `宽度超差行数` | `[口径·宽度分桶] … >0.34DIP=N 行`（旧世代 `[宽度绝对值] … >0.34 DIP N 行`） | **只到总数**；逐族另写 `note` |
| `Collapse明细全等` | `折叠判定一致 A/B；真折叠 C 行，明细全等 D/C` | |
| `Extent余差条数` | `[② Extent 余差清单] 共 N 条` | |
| 各判据 ❌/✅ | `^  ❌ <id> ` / `^  ✅ <id> `（+ `^通过 N / 失败 M$`） | 决定 `carrier` 与覆盖 |

**第 3 步（更新 `generation` 与各条值 + *记录旧世代这条是红还是绿*）**：
1. 改 `generation{id,label,instr_run_sh,instr_program_cs,instr_shim,evidence_log}` 与
   **每条**的 `caliber.instr_*`（必须同源；门禁会查"条目与 generation 不自洽"）。
2. 逐条改 `expected_shape` / `expected_reading` / `carrier` / `reason`。
3. **对每一条都记一行**：『旧世代 `#13-legA` 这条是 **红**（实测 X） → 新世代 **红/绿**（实测 Y）』
   —— 这一步是**防止静默吸收修复**的关键；旧红新绿 = **要人裁定的"在册红消失"**，不是自动放行项。
   结论写进 `changelog`（date/rev/by/what/why）。
4. 改完**只读日志**跑一遍门禁自检：应当是 `PASS`（或只剩你**明确**要保留的红），
   且 `gone/drift` 均为 0；有 `gone/drift` ⇒ 表还没钉准。
5. 门禁**不写任何既有文件**，这一步天然安全；但**跑 harness 那一步会写 `gen/`** ⇒ 归波/维护动作。

**为什么要有这套流程**：今晚咬我们的坑就是"**判据按旧仪器版本写死 ⇒ 未改动的树也读不出旧数**"
（rev1 拿 `#12` 的数字配 `#14` 的 shim sha，自相矛盾）。三步流程把
"**世代是谁 / 读数从哪来 / 旧红新红**"三件事**强制留痕**。

---

## 8. ⚠️ 未覆盖缺口（三条）+ 一条**通用教训**（第 ㈣ 条）

| # | 缺口 | 现状 / 风险 | 何时能补 |
|---|---|---|---|
| ㈠ | **`tab-oracle-anchor` / `tab-oracle-rtl` / `textlineproto` 三臂从未见过真实日志** | 抽取正则只按源码字面写（`TAB_LINES 文件=tab-anchor-oracle.json` / `tab-rtl-oracle.json`；textlineproto 取 TextLineProto 段的 `== 通过 N / 失败 M ==`）。**端到端未验** | 主控 `#15`：`D-F1c` 修好、harness 能跑完后，用 **5 臂真实日志复跑门禁** |
| ㈡ | **`textlineproto` 臂的 ContractProbe 段（P1/P4/P6）不在射程** | 只作 `【范围外·诚实披露】` note，不据此判绿也不据此判红 ⇒ 那 3 个 FAIL 是**未覆盖**的 | 待定 |
| ㈢ | **宽度"逐族"细分未覆盖（只到总数）** | 日志只印总数（两种印法都认）；逐族只在人工小结里；`gen/t2d-width-diff.txt` 是**第二消费者**且自身陈旧 ⇒ 门禁**只判总数**，逐族写进 `note` | 主控已裁定**接受"只到总数"** |
| ㈣ | **（通用教训，非本门禁特有）"零改动"主张在共享机上不可证** | 见下方 callout | 口径已写死，全项目适用 |

### ㈣ 通用教训：**共享机上任何"零改动"主张都要退化成两句可证的话**

> **在共享机上，"整仓零改动"是不可证的主张** —— 别人的写入与我的写入在同一时间线上**无法区分**。
> 任何"我没动任何东西 / 零改动"的主张都必须退化成：
> **(a) 我自己的写入点没被碰**；(b) **我关心的那个目录的 sha 未变**。
> **不要再写"整仓零改动"。**

**为什么会被咬**：本趟我在门禁跑的同时用 `find . -newermt @T0` 做全仓检查，抓到
`docs/CURRENT-STATE.md` 与 `docs/WAVE15-PREREGISTRATION.md` 被改动（mtime `11:36:24.19/.20`）。
若我当时的结论写成"**整仓零文件被改动**"，那会是**假的**—— 那只是**恰好没有并发写**的那一次。
**主控已澄清**：那两个文件是**主控自己**在同一时段并发去陈旧文档（`#15` 重排 + `D-F1c` 落地状态），
**与本门禁无关**。

**本门禁按新口径的自证方式（以后照此写）**：
1. **枚举自己的写入点，并证明它们都在仓库之外** ——
   `grep -n 'open(.*"w"\|>>' build/MilBridge/tools/tline-gate.sh` ⇒ 只有
   `$OUTDIR/arms.tsv` 与 `$OUTDIR/gate-readings.json`，两处都在 `$HOME`。
2. **证明关心的目录逐字未变** —— `gen/**` 86 个文件的 **mtime 列表 + sha256 列表**
   `diff` 跑前/跑后为空，且全目录 sha（`sha256sum < 排序后的清单`）**跑前 = 跑后**
   = `de09ae5747a5a2a32dbecec2d7f713a5`（= L28 的现场）。

**这条对全项目都有用**：任何"我只新增了文件、没动既有文件"的自证，都该按 (a)+(b) 写，
而不是按"整仓"写。

---

## 9. 我**没做** / **不确定** 的事

1. **没有跑过任何臂**（裁定 ③）。⇒ 三臂抽取路径**从未在真实日志上验过**（缺口 ㈠）。
2. **`run.sh tline` 在新世代疑似仍跑不完**（`#14`：T2/T3/T4 oracle 段卡 ≈20 min、≈978 s CPU、
   `state=R`，被别的车道 SIGTERM，`rc=143`）。**我没复现、没定位**（会写 `gen/`，越界）。归 `D-F1c`。
3. **新世代（shim `16db2d61`，11:35:56 出现）没有任何登记数字** —— 刻意的；等有完整读数再重钉（§7）。
4. **`T3b` 仍未定位**：只是**登记**了、门禁**逐趟点名**（`KNOWN_RED_UNLOCATED`），
   **含义/根因没有任何结论**。定位归 `T1b2/T3 待派`。
5. **`tab-zero` 条的世代标 `#13` 是按 mtime 推断**（CoverageProbe 不自报 shim sha ⇒ 弱配对），
   已在条目 `note` 与门禁输出里显式标注，**不是自证**。
6. **"零改动"只能按 §8㈣ 的两句自证**：(a) 我的写入点没被碰（门禁只有 2 个，都在 `$HOME`）；
   (b) `gen/**` 86 文件 mtime+sha 逐字不变。"**整仓零改动**"是**不可证的主张**，本报告不再使用。
7. 未跑 `verify-all.sh`、未发波（按纪律）；**门禁尚未接进 `verify-all`**（主控已定：等新世代重钉后再接第 10 步）。
