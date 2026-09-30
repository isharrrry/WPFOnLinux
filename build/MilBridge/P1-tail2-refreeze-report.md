# T-A50 · P1 尾波2 `#82` · 重冻结 `# ARM-LOG-SHA` 五行（`COLUMN-FLOOR` 转绿）—— 完成报告

> 车道：**实现/装置（本轮唯一写者）**。载体本件 = `build/MilBridge/P1-tail2-refreeze-report.md`。
> 写域（逐字）：冻结块所在基线件 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 5 行 `# ARM-LOG-SHA`／`docs/CURRENT-STATE.md:9`／`build/MilBridge/HANDOFF-NEXT.md`（`cell=#3` 复述位）／新建本载体。
> **未改**：`build/MilBridge/tools/**`（黑名单）／`verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`upstream/**`／`known-red.json`（`T-A49` 已同趟改齐，本趟无需再动）／`build/MilBridge/arm-logs/**`（本趟不改声明、不重取）。

---

## 0. 一句话结论

**目标达成**：把冻结块 `# RE-FROZEN #80` 内 **5 行 `# ARM-LOG-SHA`** 的 sha16 按**现盘值**逐行重钉（只改 token）⇒ `column-floor-check.sh` 由 **`COLUMN_FLOOR=FAIL`** 转 **`COLUMN_FLOOR=PASS`（`rc=0`）**；`arm-log-sha-check.sh` 仍 **`ARMLOG_SHA=PASS`（`rc=0`）**；反极（某行改回旧值）⇒ **`COLUMN_FLOOR=FAIL`（`rc=1`）**。**世代号 `#80` 不变**（本次只重钉臂日志派生声明，九位未动）。

⚠️ **开工期有一次自伤事故（意外执行整趟波），已当场全量复原并逐件核过** —— 见 §7；**如实披露、零隐藏**。

---

## 1. 起手现取（before：不改动前的真实读数）

```
$ bash build/MilBridge/tools/column-floor-check.sh --outdir /tmp/cfc-before     # rc=1
COLUMN_FLOOR_OVERFLOWED_JUDGED_MIN=PASS arm=tab-oracle-anchor col=OVERFLOWED key=judged_min decl=421 frozen=421 corpus_min=421
COLUMN_FLOOR_START_JUDGED_MIN=PASS     arm=tab-oracle-anchor col=START      key=judged_min decl=615 frozen=615 corpus_min=615
COLUMN_FLOOR_START_RELEASED_MIN=PASS   arm=tab-oracle-anchor col=START      key=released_min decl=194 frozen=194 corpus_min=194
COLUMN_FLOOR_CORPUS=PASS … live=0cebc0afd5142fbf decl=0cebc0afd5142fbf
  [COLUMN_FLOOR_ARMLOG] arm=tab-anchor    **MISMATCH** 冻结块声明=2e62d68ed5edd5e7 登记表=e11255665d711ea6
  [COLUMN_FLOOR_ARMLOG] arm=tab-zero      **MISMATCH** 冻结块声明=b5239c4e5b95fa56 登记表=baa3b212fc8395cf
  [COLUMN_FLOOR_ARMLOG] arm=tab-rtl       **MISMATCH** 冻结块声明=70feb4b5d4ab80f7 登记表=ae1983717152ae02
  [COLUMN_FLOOR_ARMLOG] arm=tline         **MISMATCH** 冻结块声明=0153827e9c590d1e 登记表=e1cdf3628952f5c5
  [COLUMN_FLOOR_ARMLOG] arm=textlineproto **MISMATCH** 冻结块声明=c537f0c007a6c922 登记表=ef314d4e4a4dbc68
COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=0 bad= tab-anchor tab-zero tab-rtl tline textlineproto
COLUMN_FLOOR_SELFREPORT=PASS gate=747c078dbf040862
COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0 selfreport=PASS reg=dcc22fd3c80cfcac base=b27ff6332f263495 corpus=0cebc0afd5142fbf
```

- **唯一红 = `COLUMN_FLOOR_ARMLOG`**（冻结块 `#80` 的 5 行 ⇔ 登记表 `known-red.json` 的臂日志派生声明三角未对齐）；**下限三条 + 语料 + 门禁自报全 PASS**（不是下限被下调、不是产品回归）。
- **成因具名**：`T-A49` 换代（五臂重取）已把登记表 `generation.arm_logs` 改为现盘值（`known-red.json` sha16 `29219b6f071c6361` → `dcc22fd3c80cfcac`），而冻结块 5 行仍是 `09-28`（`t67`）世代 sha16。

```
$ bash build/MilBridge/tools/arm-log-sha-check.sh                               # rc=0
ARMLOG_SHA=PASS shape=flat logdir=…/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0
$ bash build/MilBridge/tools/defect-registry-check.sh                           # rc=0（起手 DECLDRIFT=1 keys=KRJ）
$ bash build/MilBridge/tools/report-id-domain-check.sh                          # rc=0
$ git rev-parse --short HEAD  ⇒  9c99cb0（T-A49 已提交）
```

**现盘五臂 sha16（现算）**：`tab-anchor e11255665d711ea6`／`tab-zero baa3b212fc8395cf`／`tab-rtl ae1983717152ae02`／`tline e1cdf3628952f5c5`／`textlineproto ef314d4e4a4dbc68`。

---

## 2. ① 冻结构 5 行 before → after（逐行 sha16，**只改 token**）

`# RE-FROZEN #80` 块内（现取 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:61–:65`）：

| # | 行 | before sha16 | after sha16 |
|---|---|---|---|
| 1 | `# ARM-LOG-SHA arm=tab-anchor    ` | `2e62d68ed5edd5e7` | **`e11255665d711ea6`** |
| 2 | `# ARM-LOG-SHA arm=tab-zero      ` | `b5239c4e5b95fa56` | **`baa3b212fc8395cf`** |
| 3 | `# ARM-LOG-SHA arm=tab-rtl       ` | `70feb4b5d4ab80f7` | **`ae1983717152ae02`** |
| 4 | `# ARM-LOG-SHA arm=tline         ` | `0153827e9c590d1e` | **`e1cdf3628952f5c5`** |
| 5 | `# ARM-LOG-SHA arm=textlineproto ` | `c537f0c007a6c922` | **`ef314d4e4a4dbc68`** |

- `after` 五值 = **现盘五臂日志 sha 前 16 位**，且 = 登记表 `generation.arm_logs` 前 16 位（§1 起手现算）。
- 落盘方式：`temp` ＋ `os.replace`（`python3`），**恰命中 5 处**（脚本内 `assert cnt==5`）；**模式守恒** `644`；**行数守恒** `4606`；**除这 5 个 token 外一个字符未动**（`git diff` 逐行见 §4）。

---

## 3. ② 同趟耦合（按在册体例对齐「相邻声明」；逐件 sha16 前后对账）

| # | 件 | 改动（内容锚） | before sha16 | after sha16 | `git diff --numstat` |
|---|---|---|---|---|---|
| ① | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `#80` 块内 5 行 `# ARM-LOG-SHA` 的 sha16 换现盘值（`:61–:65`） | `b27ff6332f263495`／4606 | **`bd64f2c1a3eaaa05`**／4606 | `5 5` |
| ② | `docs/CURRENT-STATE.md` | 第 `9` 行机读行 `sha16=b27ff6332f263495` → `bd64f2c1a3eaaa05`（**`gen=#80` 未变**） | `a055826ed52fd67b`／943 | **`80affe4fabcad6ef`**／943 | `1 1` |
| ③ | `build/MilBridge/HANDOFF-NEXT.md` | 追加 1 行 `机器值契约更正 · cell=#3`（值 = 现行第 `9` 行原文，命令 = `sed -n '9p' docs/CURRENT-STATE.md`） | `80540bc49b29702c`／730 | **`17990edc02f39165`**／731 | `1 0` |

**未动（如实）**：`build/MilBridge/known-red.json`（`T-A49` 已把 `arm_logs` 五值改为现盘全 64 位；本趟复核见 §5，**无需再动**）。

逐件落盘方式：① ② `temp+os.replace`＋模式守恒；③ **纯 `>>` 追加**（保 `664`）。写前均 `cp -p` 备份（见 §9）。

---

## 4. 复核读数（after：全部现取）

```
$ bash build/MilBridge/tools/column-floor-check.sh --outdir /tmp/cfc-after                    # rc=0
  [COLUMN_FLOOR_ARMLOG] arm=tab-anchor    OK decl=e11255665d711ea6 reg=e11255665d711ea6
  [COLUMN_FLOOR_ARMLOG] arm=tab-zero      OK decl=baa3b212fc8395cf reg=baa3b212fc8395cf
  [COLUMN_FLOOR_ARMLOG] arm=tab-rtl       OK decl=ae1983717152ae02 reg=ae1983717152ae02
  [COLUMN_FLOOR_ARMLOG] arm=tline         OK decl=e1cdf3628952f5c5 reg=e1cdf3628952f5c5
  [COLUMN_FLOOR_ARMLOG] arm=textlineproto OK decl=ef314d4e4a4dbc68 reg=ef314d4e4a4dbc68
COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无
COLUMN_FLOOR_SELFREPORT=PASS gate=747c078dbf040862
COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=dcc22fd3c80cfcac base=bd64f2c1a3eaaa05 corpus=0cebc0afd5142fbf

$ bash build/MilBridge/tools/arm-log-sha-check.sh                                             # rc=0
ARMLOG_SHA=PASS shape=flat required=5 declared=5 pass=5 fail=0 noinfo=0

$ bash build/MilBridge/tools/defect-registry-check.sh                                         # rc=0
DEFREG=PASS declared=225 route_ids=225（…无未声明编号）
DEFREG_DECLDRIFT=2 changed-route-files-since-DECL-GEN keys=CS,AB,KRJ   # 诊断行，不判红（见 §8）

$ bash build/MilBridge/tools/report-id-domain-check.sh                                        # rc=0
REPORTID=PASS files=328 ids=… declared=225 glob=build/MilBridge/*report*.md

$ bash build/MilBridge/tools/baseline-sha-check.sh                                            # rc=0
BASELINESHA=PASS live=bd64f2c1a3eaaa05 decl=bd64f2c1a3eaaa05
BASELINEGEN=PASS decl_gen=#80 file_newest_gen=#80
CSDECL=PASS n_decl_lines=1 auth_line=8

$ bash build/MilBridge/tools/handoff-machine-values-check.sh                                  # rc=0
HANDOFF_MV_CELL cell=#3 … state=equal corrected=…bd64f2c1a3eaaa05… live=…bd64f2c1a3eaaa05…
HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none

$ git diff --numstat -- samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
5	5	samples/WpfTextDemo/ACCEPTANCE-BASELINE.md      # **删行数 = 5**（仅这 5 行整行替换）
```

**⑥ 基线件逐行 diff（逐字，证明只换 5 个 token）**：
```
-# ARM-LOG-SHA arm=tab-anchor    sha16=2e62d68ed5edd5e7
-# ARM-LOG-SHA arm=tab-zero      sha16=b5239c4e5b95fa56
-# ARM-LOG-SHA arm=tab-rtl       sha16=70feb4b5d4ab80f7
-# ARM-LOG-SHA arm=tline         sha16=0153827e9c590d1e
-# ARM-LOG-SHA arm=textlineproto sha16=c537f0c007a6c922
+# ARM-LOG-SHA arm=tab-anchor    sha16=e11255665d711ea6
+# ARM-LOG-SHA arm=tab-zero      sha16=baa3b212fc8395cf
+# ARM-LOG-SHA arm=tab-rtl       sha16=ae1983717152ae02
+# ARM-LOG-SHA arm=tline         sha16=e1cdf3628952f5c5
+# ARM-LOG-SHA arm=textlineproto sha16=ef314d4e4a4dbc68
```

---

## 5. ④ 反极性（**必红**；在 `/tmp` 副本上做，不碰真表）

| 极性 | 动作 | 现取 |
|---|---|---|
| 正 | 真件（5 行 = 现盘值） | `COLUMN_FLOOR=PASS` rc=0（§4） |
| 反 | 副本把 `arm=tab-anchor` 一行**改回旧值** `2e62d68ed5edd5e7` ⇒ `CFC_BASE=<副本>` | `COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tab-anchor`；`COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1`；**rc=1** |

⇒ 该牙**不是恒绿通道**：把冻结块某行撤回旧值 ⇒ 必红并逐臂点名。`arm-log-sha-check.sh` 的 `--selftest`（B 扰动一位／D 前缀补零／E 件缺失／H 现场换日志）为其自身反极性，本趟未改该件、**未借它变绿**。

---

## 6. 世代判断（复核：**`#80` 不变**；四条依据现取）

- (a) `docs/CURRENT-STATE.md:9` 仍 **`gen=#80`**（只换 `sha16=`）；
- (b) 基线件头段块头仍 `# RE-FROZEN #80 —— ✅ **当前冻结基线**`（**无新块**落地）；
- (c) 本次改动面 = **臂日志派生声明**（冻结块 5 行）及其两处复述位（`CURRENT-STATE.md:9`／`HANDOFF cell=#3`）⇒ **九位未随本次动作变动**（`BASELINE tier=` 机读行与九位行原样）；
- (d) 权威路径表 `NINE_PATHS`（`wave-freeze-consistency-check.py:104-115`）**未动**（本件在黑名单 `tools/**` 内，未触碰）。

⇒ 「只重钉臂日志派生声明」不构成新世代冻结；`BASELINE-FROZEN gen=#80` 保持不变，只更新其 `sha16=`（因基线件内容变）。**该判断具名在册，供复核者推翻。**

---

## 7. ⚠️ 诚实事故披露（开工期一次自伤，**已当场全量复原**）

**发生了什么**：起手侦察 `fp_inputs()` 是否含基线件时，我误用 `bash -c 'source build/close-wave.sh'` 去读该函数体 —— 而 `close-wave.sh` **无「只读」短路**（`source` = 执行其主流程）⇒ **整趟波被意外触发**（`[0/6]`→`[1/6] integration-wave.sh`，`21:40:13` 起），在 Shell 工具的 120 s 超时被终止。

**它改了什么（现取证据，全部 mtime 落在 `21:40:13–21:42:12` 窗口内）**：6 件**已跟踪**的构建派生件被写/删 ——
`M build/.applocal-selftest.log`／`M build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt`／`M build/PresentationFramework.Linux/ARTIFACT-SRC-FP.txt`／`M build/PresentationFramework.Linux/PresentationFramework.Linux.csproj`（`reapply-patches.py` 重写了补丁段）／`M build/wave-audit.log`（`+7` 行）／`D build/.wave-done`（空跟踪件被删）。另重建了若干**未跟踪**托管 dll（`bin/Release/*.dll`，均 gitignore）。

**复原动作**：先 `cp -p` 备份当前脏件到 `/tmp/t-a50-accident-backup/`，再 `git checkout --` 把上述 6 件**逐一还原到 `HEAD`（`9c99cb0`）**；复核 `git status --porcelain` 仅剩 `?? build/MilBridge/tasks-tail2/T-A50.md`（本轮任务书）＋我本趟的 3 件写域内改动（§3）。

**残余影响（如实划界，不夸大也不掩盖）**：
- **跟踪件已 100% 复原**（§7 上句的 `git status` 即证据）。`build/.wave-done` 空件已回；`wave-audit.log` 追加的 7 行已回退。
- **未跟踪的托管 dll 被重建**：`close-wave.sh` 的计划为「native 重建=否｜桥重发=否」（现取原文），故 `.so`／`win32shim` 未动；但 `PresentationCore/PresentationFramework/WindowsBase/…` 等**托管 dll** 被重编（源树 = `HEAD` 源）。**九位里的权威 dll**（`pc`／`pf`／`windowsbase`／`provider`／`dwf`／`bridge`／`wic_shim`／`win32shim`／`hbtextline`）现取 sha16 与 `#80` 冻结值**本就不同**（`T-A49` 已证树 `tree_gen=advanced`：`hbtextline` 源 `e2fa9ec9be1a6cf1` ≠ 登记世代 `921ba9c65e9fb3be`）⇒ **这不是本趟新造的位移**，且 dll 属**未跟踪构建产物**，任何下一趟波会**重新生成**。
- **本趟任务面未受影响**：`column-floor-check`／`arm-log-sha-check`／`defect-registry-check`／`report-id-domain-check`／`baseline-sha-check`／`handoff-machine-values-check` **六牙读数均现取自真件**，不读上述事故件。
- **教训（登记建议）**：`build/close-wave.sh` 缺「`--dry-run`／只读短路」，`source` 它 = 触发整趟波；**读 `fp_inputs()` 函数体应用 `sed -n '/^fp_inputs()/,/^}/p'` 而非 `source`**。此教训建议按 `D-G163`（只读/干跑分支必须先于任何写动作 `exit`）同族登记。

---

## 8. 未闭项 / 边界（如实）

1. **`DEFREG_DECLDRIFT=2 keys=CS,AB,KRJ`（诊断行，`DEFREG` 仍 `PASS rc=0`）**：本趟改了 `CS`（`CURRENT-STATE.md`）与 `AB`（基线件）两 route 件、`T-A49` 改了 `KRJ`（`known-red.json`）⇒ `build/MilBridge/tools/defect-registry-declared.tsv` 的 `# DECL-ANCHORS` 三键锚陈旧。**该声明件在**黑名单 `build/MilBridge/tools/**`（「不改判据」）**内 ⇒ 本车道不触碰**；漂移**不判红**（`defect-registry-check.sh` 明确注释：`DECL-ANCHORS` 漂移只诊断、不改三态判据）。**归队长/在册 `--emit` 同趟刷新**。
2. **未跑整趟门禁**（会构建 ⇒ 可能动九位／`inputs_fp`）：本趟只验**牙本体**与**判据面**（六牙现取全绿），**不声称** `verify-all` 全绿。
3. **未采纳「覆盖面件数／步数」类声明**：本趟不改覆盖面、不改步数（`#80` 收官口径不动）。
4. **`HANDOFF` 只追写 `cell=#3`**：`cell=#1`（覆盖面指纹）本趟**未变**（未碰任何覆盖面内件）⇒ 无需追写；`cell=#2/#4/#5…#9` 现取与件内一致（`HANDOFF_MV=PASS cells=9`）。
5. **本件不声称**「两页可用」等产品级结论（不在本任务射程）。

---

## 9. 复算命令（逐条可重跑）

```bash
R=/home/links-dev/netTest/GitProj/WPFOnLinux ; cd "$R"
# 起手（before）
bash build/MilBridge/tools/column-floor-check.sh --outdir /tmp/cfc-before   # 期望 FAIL rc=1
bash build/MilBridge/tools/arm-log-sha-check.sh                            # 期望 PASS
bash build/MilBridge/tools/defect-registry-check.sh                        # rc=0（漂移诊断 keys=KRJ）
bash build/MilBridge/tools/report-id-domain-check.sh                       # rc=0
# 复核（after）
bash build/MilBridge/tools/column-floor-check.sh --outdir /tmp/cfc-after   # 期望 PASS rc=0
bash build/MilBridge/tools/arm-log-sha-check.sh                            # 期望 PASS
bash build/MilBridge/tools/baseline-sha-check.sh                           # 期望 PASS（第 9 行已随件重算）
bash build/MilBridge/tools/defect-registry-check.sh                        # rc=0
bash build/MilBridge/tools/report-id-domain-check.sh                       # rc=0
bash build/MilBridge/tools/handoff-machine-values-check.sh                 # 期望 PASS cells=9
git diff --numstat -- samples/WpfTextDemo/ACCEPTANCE-BASELINE.md           # 期望 5 5
# 反极（仓外副本）
T=$(mktemp -d); cp -p samples/WpfTextDemo/ACCEPTANCE-BASELINE.md "$T/b.md"
sed -i 's/sha16=e11255665d711ea6/sha16=2e62d68ed5edd5e7/' "$T/b.md"
CFC_BASE="$T/b.md" bash build/MilBridge/tools/column-floor-check.sh         # 期望 FAIL rc=1（点名 tab-anchor）
```

**备份**：写前 `cp -p` 三件到 `$HOME/t-a50-backup/{ACCEPTANCE-BASELINE.md,CURRENT-STATE.md,HANDOFF-NEXT.md}.before`；事故件另存 `/tmp/t-a50-accident-backup/`。
**写入面**：3 件（§3）＋ 本载体；**模式守恒** 基线件/`CURRENT-STATE` `644`、`HANDOFF` `664`。
