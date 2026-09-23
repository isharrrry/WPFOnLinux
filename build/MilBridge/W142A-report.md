# W142A 报告 —— 波 `#56`（**仪器波** · `TASK-0708`：四件新牙接线）收尾链 ①–⑨

> 车道 **W142A**｜2026-09-23 22:25 – 2026-09-24 00:2x +0800｜`R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**不是 git 仓库**；推送在 `~/netTest/GitProj/WPFOnLinux` 的 `feat-Linux`）
> 判据先写：`~/w142a/criteria.md`（sha16 **`e4611d42fd8254d6`**，开工前落盘）｜台账 `~/w142a/STATUS.md`（逐步追加）
> **冻结结果：`#56` 整份 sha16 = `8edaf4f8c1e93eb0`**（`docs/CURRENT-STATE.md:9` = `gen=#56`）

## ① 判据（先写；摘录，全文见 `criteria.md`）
- **C1 九位**：本波零产品改动 ⇒ 九位应与 `#55` 逐位相同；**唯一例外 = 环成员 `pf`**（`D-G92`「整波重建必换身份字节、**同尺寸**」）⇒ 只它变记**机械位移**；**其它任一位变 ⇒ 停手报主控**。
- **C2 四处声明同趟改**：`names=31 decl=31 gen=#56`；头注释**逐字**含 `` **`#56` 收官起 = 31 步** ``（冻结器 `w27-freeze.py` 硬断言；`nstep=31`）。
- **C3 空盘/可写预检**：每条重活趟前 `df --output=avail /` ≥ 5 GiB ＋ `/tmp` 可写。
- **C4 冻前 `verify-all`**：**恰好 1 处声明类红 = `COLUMN-FLOOR`**；`用例通过 875`；`X_STATE=available`；`[0] X-REUSE=reused` 几何 1280x1024；**出现第 2 处红 ⇒ 先看有无「设备上没有空间」**（有 ⇒ 作废重跑；无 ⇒ **停手报主控**）。
- **C5 冻后 ×2**：各 `31 ✅ / 0 ❌` ＋ `结论：✅ 全部通过`；**两趟之间不许换件**。
- **C6 在册红**：只 `arm=uia-door`（`rc_tooth=1`，`[30]` 走消费者 ⇒ 该步 `rc=0`）；`IME-LANDING` 绿**不登记**；牙回 `NOINFO` ⇒ 该步必须 `rc=2`。
- **C7 tsv 处置**：读 ⇒ 进 `fp_inputs()`；不读 ⇒ 给"命中 0"机械证。
- **C8** `NOINFO` 既不算绿也不算红｜**C9** 推送逐径 `git add` ＋ 逐件字节核对。

## ② 空盘预检（判据 C3）
| 时点 | `df --output=avail /`（KB） | `/tmp` 可写 | `MemAvailable`（KB） |
|---|---|---|---|
| 开工 | 70435920 | ✅ | 3866 MB 级（`free` 口径） |
| 整波前（槽内 `MEMOK`） | 70375372 | ✅ | 4617 MB |
| 冻前 verify-all 前 | 68147604 | ✅ | 4591 MB |
| 冻前重跑前 | 67094296 | ✅ | 4334 MB |
| 冻后 ×2 前 | 65698464 | ✅ | 5784 MB |

## ③ 落件（**并发写者与偏差，如实记**）
- **22:25:45–22:26:47 主控侧已把本波落件做完**（本车道前两轮误回 GUI 卡片、被判故障）：`verify-all.sh` `80455e8d5eb92cb3 → eb29ced9d81b2345`｜`known-red.json` `433d2d371787c004 → 453d17ca981d3116`｜`close-wave.sh` `c757fd5058f1bfd4 → 027e1551b148c29e`（+5 件）；消费者／tsv／预登记三件 17:20:04 已在仓内。
- **本车道唯一的落件动作 = `regression-decision-cases.tsv` 进 `fp_inputs()`**（主控逐条批准）：
  - **机械证（两向）**：`verify-all.sh:959` 把 `--cases build/MilBridge/tools/regression-decision-cases.tsv` 交给第 `[29]` 步的牙（**读**）；`grep -c 'regression-decision' build/MilBridge/tools/tline-gate.sh` = **0**（五臂门禁不读）⇒ 按纪律「**判据件改它必须看得见**」纳入。
  - `build/close-wave.sh`：`027e1551b148c29e → 0cf2ea72bdee142c`（`bash -n` rc=0；`grep -c 'regression-decision-cases.tsv'` = 2）
  - `inputs_fp`（真函数算）：改前 `929cb1b7f2db5fb40f54415dd49ac40a4dc1c778e566ae8f3d42971e2c4b38d9` → 改后 `e1e4a5f2aa7635cf30a1663d3500ab2590eebfaf01898b92442e52b914c3f646`
    ⚠️ 主控给的 before `ee02808d…` 与现算不同 ⇒ **归因 = 覆盖面自含 `close-wave.sh` 且含 `known-red.json`（主控 22:26:38／22:26:47 改过）** ⇒ 值随时刻变；本车道口径与主控同族（`~/w137a/fp-probe.sh` 复算 before 逐位相同）。

## ④ 四步逐件读数（判据 C6；日志 `~/w142a/logs/step28..31*.log`）
| 步 | rc | 机读行 |
|---|---|---|
| `[28] HYGIENE` | **0** | `HYGIENE_TOOTH=PASS roots=PASS evidence=PASS inode=PASS scope=REPORT semantic_undecidable=7 multilink=0 cross_region=0 ext_ext_hits=0 ext_strict=0 code_files=73` |
| `[29] REGRESSION-DECISION` | **0** | `REGRESSION_LEDGER=PASS rows=7 pass=7 fail=0` |
| `[30] UIA-DOOR`（该步跑的 = **消费者**） | **0** | `KNOWN_RED_ARMS=PASS arms=1 ok=1 fail=0 noinfo=0 registered_red=uia-door` |
| `[31] IME-LANDING` | **0** | `IME_LANDING=PASS landings=0 declared=yes ctrl=5 sm82_nonzero=0 shim_map=0 so_syms=0 decl_hits=2` |
| 消费者自检 | **0** | `KRA_SELFTEST=PASS total=10 pass=10 fail=0 target_untouched=yes` |
| 牙本体**直跑**（反极性参考） | **1**（设计内红） | `UIA_DOOR=FAIL prod=0 consume=1 core_shim=0 uia_syms=0 ctrl_syms=8 live_calls=2 (all=69) libs=1`（与在册 `expected_shape` **逐字相符**） |

口径步：`VERIFYALL_SELF=PASS names=31 decl=31 gen=#56 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=eb29ced9d81b2345`

⚠️ **`[29]` 的绿的射程（主控 23:2x 裁定的口径句，逐字）**：`[29] REGRESSION-DECISION ✅` 只指**本步的行式径通过**；该牙 `--old-repro yes` 支路**缺 ④ 检查（假绿，已登记 `D-G99` 追加位点）**，本波**不修**、随 `#58` 修。

## ⑤ 整波（**偏差如实记**）
- 主控给的命令 = `bash build/integration-wave.sh`；**本车道实际走 `close-wave.sh --skip-verify-all`**（主控批准）：它的 `[1/6]` **就是** `integration-wave.sh`（同一条 `appliers=28 ok=95 miss=0 red=0` 读数），另含 `[2/6]` native／`[3/6]` 桥／`[4/6]` 身份自检／`[6/6]` **哨兵刷新**（裸跑**不刷哨兵**，而开工时哨兵仍是 20:57 旧版 ⇒ 必须刷）。
- 槽：`HEAVYSLOT=ACQUIRED waited=0s`／`MEMOK avail=4617MB`／**`RELEASED rc=0 held=242s`**／`max_hold=1200s`
- `[0/6]` 波前输入指纹 = `e1e4a5f2aa7635cf30a1663d3500ab2590eebfaf01898b92442e52b914c3f646`
- `[1/6]` **`APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0`** ＋ **`=== 集成波结束：失败步骤 0 ===`**
- `[2/6]` native `源码不比权威件新 ⇒ 跳过重建`｜`[3/6]` 桥 `源指纹一致（d697b1e10ff48881 == d697b1e10ff48881）⇒ 无需重发`
- `[4/6]` 桥源 fp 两侧一致 ✓／生成物指纹 `state=ok` ✓／应用器审计 `miss=0` ✓／**输入稳定性：波前==波后 == `e1e4a5f2…c3f646`**（预测命中）
- `[6/6]` 哨兵已刷新｜`OUT=/home/links-dev/wfp-runs/close-wave-223105`｜`CLOSEWAVE_OUTER_RC=0`
- **两刻 `pf` 并列（`D-G92`）**：整波前 `f2df3c2b464b7f00` → 整波后 `b4c81eb3f1376f86`（**同尺寸**）；其余八位两刻逐位相同。

## ⑥ 五臂重取（预测先写、事后命中）
- **预测（早于取数）**：判词应与 `#55` 逐字相同；`tline` 那支 sha **可能变**；四支 tab/proto 臂 sha 预期不变（`grep -c 'PresentationFramework\|pf=' arm-logs/*.log` = 0/0/0/0/0）。
- 槽 `RELEASED rc=0 held=492s`｜`ARMS_OUT=~/wfp-runs/arms56`（新目录，与 `arm-logs/` 不同 inode）｜`ARMS_DISPLAY=:97 source=reused`（**复用已存在的 `:97`，未自起、未碰任何人的 X**）
- 自证行：`shim=921ba9c65e9fb3be pc=722e0ab8205b7c3f run.sh=711f39f468f61cc8 Parity.cs=149dd986a642fdfc`
- sha：`tline a46cb0b4e853fa1f → 69b070d4fe25877d`（**变，预测内**）｜`tab-zero 9150c3a26a3cb789`／`tab-anchor 1c43a12dcaa5718a`／`tab-rtl 92570318851ca7e8`／`textlineproto 4bceceeed570ba70`（**四臂逐位不变**）
- 判词（**与 `#55` 逐字相同**）：`tline 通过 22 / 失败 2`｜`tab-zero 退出码=1`（唯一 = `notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白 期望=0 实得=1`）｜`tab-anchor START 红=0 绿=615 判定行=615／OVERFLOWED 红=0 绿=421 判定行=421／字形释放行=194`｜`tab-rtl 红=0 绿=0 判定行=0 NOINFO=163`｜`textlineproto 探针 通过 4 / 失败 2`
- 别名侧 `nlink 2 → 1`（`TASK-0502` 波尾必做②）：五件 `cmp IDENTICAL`、inode 互异；**权威侧 `arm-logs/*.log` sha 逐位未变**。

## ⑦ 重钉世代
- 重钉前 `--check` = **`REPIN_GENERATION=FAIL n=2`**（`arm_logs.tline`／`evidence_log_sha256 声明=a46cb0b4e853fa1f 现场=69b070d4fe25877d`）＝**声明类红**，由本步转绿。
- `--why '…'` ⇒ **`REPIN_GENERATION=APPLIED`**（`instr_run_sh=711f39f468f61cc8`／`instr_program_cs=149dd986a642fdfc`／`instr_shim=921ba9c65e9fb3be`／`evidence_log_sha256=69b070d4fe25877d`／**`entries[*].caliber 改动字段数 = 0`**）⇒ `--check` **`PASS`**
- `known-red.json`：`453d17ca981d3116 → 102a883d91b9c41c`｜`arm-log-sha-check.sh` ⇒ `ARMLOG_SHA=PASS shape=flat required=5 declared=5 pass=5 fail=0 noinfo=0`

## ⑧ 门禁 ×2
- `:215`：`GATE1_OUTER_RC=0`｜`WPTD_SUMMARY=PASS tiers_passed=2/2`｜`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`｜rows `~/w142a/gate-rows.txt` `9b360369765f2934`｜**6 条 `result=PASS`／0 FAIL**
- `:216`（`--no-build`）：`GATE2_OUTER_RC=0`｜rows `~/w142a/gate-rows-f.txt` `90663773755e893c`｜**6 条 `result=PASS`／0 FAIL**
- 两本 `config=` 段 **`CONFIG_IDENTICAL`**：`pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:b4c81eb3f1376f86,provider:1f9511a7ef395bfe,win32shim:2067cb1c97728791,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no)`
- ⚠️ **偏差**：本步**裸跑**（未走槽）；主控现场核过当时槽 `flock` FREE、空闲内存 4082 MB、`:215`/`:216` 空闲 ⇒ **读数有效**；⑥⑧ 起改回**槽内**。

## ⑨ 冻前 `verify-all`（**含第 2 处红与它的修法**）
- **第 1 趟**（有效但结论 2 红）：槽 `RELEASED rc=1 held=1077s`｜日志 `~/w142a/logs/24-verify-pre.log` `76cc678cbb69a11f`（139 行）｜**`步骤通过 29 ❌ 失败 2`**｜`结论：❌ 失败项：COLUMN-FLOOR PIPEFAIL-SIGPIPE`｜`设备上没有空间` = **0**
  - ① `COLUMN-FLOOR` = **预期声明类红**（`COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad=tline`）
  - ② **`PIPEFAIL-SIGPIPE` = 未预期红**：`UNDECLARED_HIT build/MilBridge/tools/known-red-arms-check.sh:280`，逐字 `if [ "$rc" = 2 ] && printf '%s' "$got" | grep -q 'scope-below-floor'; then`
    ⇒ **本波新件带进来的真隐患**（`set -uo pipefail` 下 `printf` 可能吃 SIGPIPE ⇒ 把"命中"读成非零 ⇒ **假 FAIL**）⇒ **停手报主控**（C4 第二支）。
- **沙箱两极化（仓内零写入；整棵 73 件 `.sh` 副本 ＋ `PP_ROOT` 覆写）**：原件 ⇒ `UNDECLARED_HIT …:280` ＋ `FAIL undeclared_hit=1 sites=80`；`case` 版 ⇒ `PASS`。
- **主控裁定 A（真修；否 B「只声明」）** ⇒ 照 `TASK-9905`／`D-G42` 族先例：**判据正则一字未动，只换喂法**
  `if [ "$rc" = 2 ] && grep -q 'scope-below-floor' <<<"$got"; then`
  件：`build/MilBridge/tools/known-red-arms-check.sh` **`44d1d0ba4a706119 → 8c9aee142ebe0432`**（`bash -n` rc=0；**只改这一处**；全仓钉它 sha16 = **0 命中**）
  - ① 牙单跑：**`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=73 sites=79 hit=0 low=7 diag=2 safe=70 runs=12`**（**`sites 80 → 79`**）
  - ② 消费者自检：**`KRA_SELFTEST=PASS total=10 pass=10 fail=0 target_untouched=yes`**
  - ③ 反极性（仓内树沙箱副本、喂法放回管道）：**`UNDECLARED_HIT …:280` ＋ `PIPEFAIL_SIGPIPE=FAIL undeclared_hit=1 … sites=80 hit=1`**
  - `inputs_fp` 成对：`5cf1a730f07b600238f96b91291d795cfc9d9fbc35303b39b65c23f415c4234a` → **`1a999e79f236303891b06c54ef659fe989262cd841140641a13ad27acf12254e`**（归因 = 该件是覆盖面成员；**`close-wave.sh` 一字未动**）
  - **值得单记一笔**：**新接的牙抓出了本波自己带进来的假红** ⇒ 按"不新号"记入 **`D-G42` 追加位点**（件=`known-red-arms-check.sh:280`、成因=`set -uo pipefail` 下 `printf | grep -q`、修法=换喂法）。
- **第 2 趟（用于冻结的那趟）**：槽 `RELEASED rc=1 held=1008s`｜日志 `~/w142a/logs/24b-verify-pre2.log` **`5f7e5c70f8c06759`**（137 行）｜**`步骤通过 30 ❌ 失败 1`**｜`用例通过 875 跳过 2`｜**`结论：❌ 失败项：COLUMN-FLOOR`**（**恰好 1 处声明类红**）｜`[0]` **`X-REUSE=reused display=:99`**｜`X_STATE=available`｜`SKIP_GUARD=PASS`｜`设备上没有空间` = **0**｜四新步全绿。

## ⑩ 冻结 `#56`
- ⚠️ **`w27-freeze.py` 的 `GENS` 表原无 `#56` 条目**（最大 `#55`）⇒ 冻结器 `assert gen in GENS` **会当场失败**。本车道按**该表自身格式**补了一条（`~/w142a/bin/gen56-entry.py`，幂等＋`temp`/`os.replace`；`infp` **现场算**）：`~/w21-verify/w27-freeze.py` `1dda5297af0c8e2d → 57b45f24027331b3`（原件备份 `~/w142a/backup/w27-freeze.py.orig`）——**仓外工具，归主控复核**。
- 记录件 `~/w21-verify/w56-record.txt`：`84212d4b60c005e4`（212 行）→ `3425c63ba7582c8f`（225 行，含主控口径句两处）→ **`db9246857af94c63`（269 行，冻后追加）**；**`APPEND_ONLY_PROOF=PASS`**。
- `python3 ~/w21-verify/w27-freeze.py ~/w142a/logs/24b-verify-pre2.log ~/w142a/gate-rows.txt '#56'` ⇒ **`FREEZE_RC=0`**（世代交叉断言：树上 `#55` == `GENS[#56][prev]`）
- **基线重冻为 `#56`；整份 sha16 = `8edaf4f8c1e93eb0`**（`BASELINE_BYTES=807869`；`#55` = 785,675）｜`docs/CURRENT-STATE.md:9` = `gen=#56 sha16=8edaf4f8c1e93eb0`
- 四颗牙：`BASELINESHA=PASS`／`BASELINEGEN=PASS decl_gen=#56`／`BASELINE_BYTES=807869`／`BASELINEDUP=PASS n=0`｜`ARMLOG_SHA=PASS 5/5`
- **两极化齐**：冻前 `COLUMN_FLOOR=FAIL` ⇒ 冻后 **`COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=102a883d91b9c41c base=8edaf4f8c1e93eb0 corpus=0cebc0afd5142fbf`**

## ⑪ 冻后 `verify-all` ×2
| 趟 | 槽内读取 | 汇总 | 日志 sha16 |
|---|---|---|---|
| 1 | `RELEASED rc=0` | **`步骤通过 31 ❌ 失败 0`**／`用例通过 875 跳过 2`／**`结论：✅ 全部通过`**／`X-REUSE=reused display=:99`／`设备上没有空间`=0 | `~/w142a/logs/25-verify-post1.log` **`28042f57a8c00eae`**（141 行） |
| 2 | `RELEASED rc=0` | **`步骤通过 31 ❌ 失败 0`**／同上 | `~/w142a/logs/26-verify-post2.log` **`dca4a3ea9e946e85`**（141 行） |

- **逐步对拍**：24 个具名步组 **逐字相同 24／不同 0**
- **`NOFILE_SWAP=YES`**：趟间现算 `win32shim=2067cb1c97728791`／`bridge=4e25e4b27d4d5ae1` 逐位未变；基线件仍 `8edaf4f8c1e93eb0`；`verify-all.sh=eb29ced9d81b2345`／`close-wave.sh=0cf2ea72bdee142c`／`known-red.json=102a883d91b9c41c` 均未动
- **九位（冻结窗口前后各复算一次，成对）**：`bridge 4e25e4b27d4d5ae1`（5028208 B）／`pc 722e0ab8205b7c3f`／**`pf b4c81eb3f1376f86`**／`windowsbase 2e4e46e539a72cd7`／`provider 1f9511a7ef395bfe`／`win32shim 2067cb1c97728791`／`wic_shim f7b3026c8c019be2`／`hbtextline 921ba9c65e9fb3be`／`dwf ce3469f49efcbcfa`
- **放行标记**：`touch ~/w21-verify/w56-POST.done`，`mtime = 2026-09-24 00:02:05.674535952 +0800`（**两趟都绿之后**才建，size 0）
- ⚠️ **事故窗口交叉核对（主控要求；三趟逐字相同：冻前 `24b` ↔ 趟1 ↔ 趟2）**：`FP_INPUTS_HYGIENE=PASS reason=clean coverage_n=155 artifact_n=0`／`SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=158 sh=73 py=85`／`HYGIENE_TOOTH=PASS … code_files=73` ⇒ **W146A／W149A 那 2 分钟没有被任何一步读到**（主控现算：三行三趟 md5 同为 `4c812a12`）
- ⚠️ **口径如实说明**：第 `[11]` 步机读行只打印 `VERIFYALL_SELF=PASS names=31 decl=31 gen=#56 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=eb29ced9d81b2345`；"拦截指纹 == 无拦截指纹"是第 `[12]` 步那颗牙的**内部自证格**（不扰动／完备／生产者白名单，任一不满足即 `NOINFO`）—— 本趟 `PASS reason=clean` ⇒ 三格全过，脚本**不单独打印**。

## ⑫ `inputs_fp` 三笔（**必须成对留档，否则将来会被误判成"输入漂移"**）
1. **波内稳定性** = `e1e4a5f2aa7635cf30a1663d3500ab2590eebfaf01898b92442e52b914c3f646`（`[4/6]` 自证**波前==波后**）
2. **重钉后** = `5cf1a730f07b600238f96b91291d795cfc9d9fbc35303b39b65c23f415c4234a`
3. **修 `:280` 之后（= 冻结值）** = `1a999e79f236303891b06c54ef659fe989262cd841140641a13ad27acf12254e`
⇒ 三笔**逐条可归因**：① 接线（覆盖面 +6 件 ＋ `close-wave.sh` 自含）② 重钉 `known-red.json`（覆盖面成员）③ 修 `known-red-arms-check.sh:280`（覆盖面成员）⇒ **全是设计性变更，不是漂移**。

## ⑬ 推送 / app-local / 哨兵
- **推送（逐径 `git add`；白名单 12 件，**不从 `git status` 生成清单**）**：`git fetch` 后 `local == origin == 502f3061…` ⇒ **快进**；`porcelain 12 行 == diff --cached 12 件 == 白名单`（`CACHED==WHITELIST ✓`）；commit **`6307192df4e8ffbab0a20a8c6f99a5002baf289b`**（`502f306..6307192 feat-Linux -> origin/feat-Linux`）；重新 `fetch` 后 `local == origin == ls-remote == 6307192…`、`--symref` 仍 `feat-Linux`、工作树 `porcelain=0` ⇒ **`BYTECHECK ok=12 mismatch=0 nobody=0`**（逐件 `git cat-file blob origin/feat-Linux:<path>` == `$R` 磁盘 == clone 磁盘）
- **native 一件未 add**：`git diff --name-only HEAD~1 HEAD | grep -c 'WpfGfx.Linux.Native'` = **0**（`win32_msg.c 12175591b736bb3f`／`win32_core.c c66528843de4a370`／`win32_internal.h c13390de6f870999` 与 clone **逐位相同**；`bin/libwpfwin32.so` 被 `.gitignore:24` ⇒ 非追踪件）
- **本地领先（未推，如实单列）**：`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv`（**主控与另一会话在办**）＋ 7 件往波遗留账页 `build/MilBridge/gen/tline-ledger-lines-*.txt`（`#55` 车道同样留作本地领先）
- **app-local（只核不改）**：`check-applocal-sync.sh`（**本脚本不改写任何目录**）⇒ **`计数：OK=200 MISMATCH=0（STALE=0 NEWER-DIFF=0） MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0] DIVERGENT=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`**；桥副本 4 份「与记录一致 4 份／不符 0 份」⇒ `STALE=0 DIVERGENT=0 MISMATCH=0 MISSING=0`；`$R` 与 `samples/WpfFeatureProbe/bin/Release/net10.0/libwpfwin32.so` 现算**都是 `2067cb1c97728791`** ⇒ **本波无需 `--apply`**（主控护栏：产品零改动＋避免抄到 `#57` 在飞字节）
- **哨兵两处**：`/tmp/bridge-frozen.flag` 与 `~/wfp-runs/bridge-frozen.flag` **`cmp IDENTICAL`**（size 各 332，mtime 差 4 ms）；内容 **`SHA=4e25e4b27d4d5ae1`**／`FP=d697b1e10ff48881`／`PC=722e0ab8205b7c3f`／**`PF=b4c81eb3f1376f86`**／`WB=2e4e46e539a72cd7`／**`WIN32SHIM=2067cb1c97728791`**／`HBTL=921ba9c65e9fb3be`／`WIC=f7b3026c8c019be2`／`PROVIDER=1f9511a7ef395bfe`／`DWF=ce3469f49efcbcfa`／**`WAVE=close-wave-223105`**（唯一写者是 `close-wave.sh:387-412`，**本车道未改写**）

## ⑭ 事故留痕（**两起越界，损伤 = 0**；主控通报，本车道独立现算）
- ① **W146A** 于 23:32–23:34 写了 `$R` 的 `src/WpfGfx.Linux.Native/src/win32_msg.c` 与 `win32_core.c`，~23:34 逐字节复原（`cp -p` 连 mtime）。
- ② **W149A** 于 23:33:5x **新建** `build/MilBridge/tools/geom-revert-beat-check.sh`（**新件、未改既有件**），23:34:5x 已 `mv` 出。
- **本车道独立现算（2026-09-24 00:0x）**：`win32_msg.c = 12175591b736bb3f`（mtime 20:49:21）｜`win32_core.c = c66528843de4a370`｜`win32_internal.h = c13390de6f870999`｜**`libwpfwin32.so = 2067cb1c97728791`（mtime 22:28:13）｜`nm -D --defined-only` = 547** ⇒ **全回冻结值**；`build/MilBridge/tools/geom*` 命中 **0** ⇒ 无残留；事故窗口（23:30–23:45）内 `$R` 的**非产物改动只有冻结链自己写的两件**（`ACCEPTANCE-BASELINE.md`、`docs/CURRENT-STATE.md`）⇒ **`src/WpfGfx.Linux.Native/**` 命中 = 0**。
- 【教训落册（逐字）】**闸门字面满足 ≠ 可以写共享 `$R`；写前必须确认 ① 收尾/构建链不在跑 ② 重活槽未被别人持 ③ 冻后链已完成。**

## ⑮ `NOINFO` 逐条
- `verify-all` 第 `[11]` 步自报 **`dynamic_trace=NOINFO`**（成因未测；`#55` 同形）。
- `tab-rtl` 臂：`红=0 绿=0 判定行=0 NOINFO=163`（面缺字形；`#55` 逐字同形）。
- `textlineproto` 臂：`探针 通过 4 / 失败 2`（在册欠账项，非本波引入）。
- `tab-zero` 臂：`退出码=1`（唯一失败 = `notab-control@w40@em24@RTL@tab0`；`#55` 同形）。
- `pf` 的非确定性（`D-G92`）：**只证"同源同命令两次重建可给不同字节"**，**成因未定**。
- `HYGIENE` 的 `scope=REPORT`／`semantic_undecidable=7`：**恒不为 PASS** ⇒ 不声称全域干净。
- app-local 的 `UNEXPECTED=6`（`DECL-GAP-EQ=6`，其 sha == 权威）与 1 条在册红：**非本波引入**，本波只记账。
- 本车道**未复测** `--old-repro yes` 假绿（主控已独立复现，登记 `D-G99`）。

## ⑯ 内存三值（`MemAvailable`）
开工 ~3.87 GB｜整波前 **4617 MB**（槽 `MEMOK`）／整波后 4759 MB｜冻前 4591 MB｜冻前重跑 4334 MB｜冻后趟1 前 5784 MB；**峰值未取到（NOINFO）**。全程 `nproc=4`、`dotnet -m:1`、`DOTNET_gcServer=0`、**同时只跑一个重活**。

## ⑰ ≤6 行小结
1. `#56` 是**仪器波**：把四件"牙已备、无人跑"的牙接进 `verify-all`（**27 → 31 步**），`src/**` 一字节未动。
2. 九位里**只有环成员 `pf`** 变（`f2df3c2b464b7f00 → b4c81eb3f1376f86`，同尺寸，`D-G92`）；其余八位逐位不动。
3. 四步逐件全绿、消费者自检 `10/10`；五臂判词与 `#55` 逐字相同；门禁 ×2 各 `6/6`。
4. 冻前第 1 趟出现**第 2 处红**（`PIPEFAIL-SIGPIPE`，**非 ENOSPC**）⇒ 停手报主控 ⇒ 按裁定 **A 真修**（**只换喂法**）⇒ 重跑 `恰好 1 处声明类红`；**新接的牙抓出了本波自己带进来的假红**（记 `D-G42` 追加位点）。
5. **冻结 `#56`**：整份 sha16 **`8edaf4f8c1e93eb0`**（807,869 B），四颗牙全 PASS、`COLUMN_FLOOR` 红→绿两极化齐；冻后 ×2 各 `31 ✅ / 0 ❌`、逐步对拍 24/24 相同、`NOFILE_SWAP=YES`。
6. 推送 `6307192…`（12 件逐径、`BYTECHECK ok=12/mismatch=0`）；app-local `STALE=0 DIVERGENT=0` 且**无需 `--apply`**；哨兵两处 `IDENTICAL`。**本车道落件 1 件**（tsv 进覆盖面），其余为复核；`w27-freeze.py` 的 `GENS` 补条目与记录件属仓外/半仓外件，**归主控复核**。
