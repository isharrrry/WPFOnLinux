# 波 `#69`（`TASK-0725`）· 两条**会红的牙**落仓并接线｜owner **W167A**

**结论**：`FREEZE_RC=0`，基线 `a51071d05d6d7896 → c7cdcbb50e3f19a7`；`verify-all` **39 → 41 步**；覆盖面 **167 → 171**；**零产品位移**（九位只有环成员 `pf` 变：`ddb412ee7efa4b65 → 4143bf4f50a7eba1`）。

## 落仓（写前逐件 `%h==1` 断言；temp＋`os.replace`）
`verify-all.sh cc675e85d1b42c62`｜`build/close-wave.sh 3b891df8317b1f7c`｜`tools/backup-completeness-gate.sh ab73167a2427cbdf`（`D-G126`）｜`tools/repo-alias-check.sh b11e13f8bb024abc`（`D-G127`）｜`repo-alias-allow.tsv 5813863882022812`｜`tools/bak-completeness-step.sh 5489c19bf3a43c3c`｜`docs/WAVE69-PREREGISTRATION.md 24daa7c260aa32c6`

## 两个新步
`[40] BAK-COMPLETENESS`：牙自测（`legs=8 bad=0`）＋求值 `producer=UNWIRED-IN-STEP` 谓词（`n_wired = grep -E '^[[:space:]]*run_step .*backup-completeness-gate\.sh.*--plan' verify-all.sh`，**`==0` 才绿**）⇒ 产出端被接线就**当场翻红** —— `D-G132`（声明没有机读读者）本波就地供给。
`[41] REPO-ALIAS`：`$R` 内 `%h>1` 的件在**仓外**有同 inode 孪生 ⇒ `FAIL`。🔴 **允许清单是声明式豁免，不是把牙关掉**：只降 `aliased_out` 一项、四项计数照打；**未覆盖的孪生照旧红**；**超上限 ⇒ `FAIL allowed-tree-grown`**（树长大也红）；唯一"有孪生还给绿"＝全部覆盖 ∧ 各有界。

## 两极化（全真跑，成对归因）
孪生**不在**清单 ⇒ `ALIAS=FAIL aliased_unallowed=2 reason=out-of-repo-alias rc=1`｜上限==实际 ⇒ `PASS known-alias-trees`｜上限==实际−1 ⇒ `FAIL allowed-tree-grown`｜谓词现状 `n_wired=0` 绿／沙箱插真调用 ⇒ **`n_wired=1` 翻红**｜牙 1 五条负腿（备份缺失／错版本／**是硬链接**／空 plan／沙箱硬链接残留）各自 `FAIL`。

## 🔴 门禁在真树上抓到了**我自己**的缺陷（本波最有价值的现场证据）
首趟 `[21] QUOTE-TRAP` 当场红：`SHELL_QUOTE_TRAP=FAIL traps=2`，点名 `bak-completeness-step.sh:96`。根因是**真 bug**：我在**双引号里**写了反引号 ⇒ bash **真做了命令替换**、诊断文字被吃掉（正极腿输出 `谓词反证： **已失效**` 中间空了一块，我当时没看出来）。改后 `traps=0 PASS`。⇒ `inputs_fp` 由 `aa06ea91…` 移到 `9ccc8f33…`，**整条链从头重跑**（首趟读数作废）并同步 `GENS`。

## 冻前链（最终一趟）
`wave rc=0` → 应用门禁 ×2（各 `6/6 result=PASS`，`GATE_LINES_IDENTICAL=yes`）→ `gate1`／`gate2`／`pre` 三趟均 `步骤通过 41 ❌ 失败 0` ∧ `结论：✅ 全部通过`（`用例通过 875 跳过 2`），关键机读行逐字相同。`[11] names=41 decl=41 gen=#69 order=OK prose=OK prereg=PASS`｜`[34] PREREG4=NA`。

## 边界（不许读成绿）
① 牙 1 真用法（落地前 `--plan`）**不在门禁** ⇒ `[40]` 的 `PASS` 只证"装置活着＋谓词会响"，**不**证"本次落地的每件都真被查过"。② 牙 2 **只覆盖 inode 共享**：同内容真拷贝不报（正确行为）；`--roots` 外／深于 `--maxdepth` 不检出；写穿历史不覆盖。③ 白名单是**声明**：未点名的树一旦出现即红、需人复核（设计意图）。④ 两趟门禁 `BASELINE` 六行逐字段相同，仅 `rundir=` 标签不同 ⇒ `ROWS_IDENTICAL=no` 不是读数漂移。⑤ 开工时抓到真漂移：产源描述件声称牙带 `--allow`，**实件命中 0** ⇒ 照它接线本步在真树上必红、本波永远冻不了 ⇒ **以实件＋可复现补丁为准**。

W167A: state=FROZEN wave=#69 steps=41 gen=#69 sha16=c7cdcbb50e3f19a7 evidence=~/w167a/w69/logs/{chain-all-20260925-170954.log,w69-pre-20260925-170954.log,w69freeze/logs/w69-freeze.DONE}
