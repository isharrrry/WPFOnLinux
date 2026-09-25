# 波 `#69` 预登记 —— `TASK-0725`（把两条"**会红的牙**"接进仓并接线：`D-G126` 前半句 ＋ `D-G127`）

> **判据先写**：本文件在**任何落仓动作之前**写定（`CRITERIA_FIRST=yes`；车道 W167A，2026-09-25）。
> 权威树 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**非 git 仓**）。
> 波名：`#69`｜owner：**W167A**（独立拥有本波落仓与收尾链）｜上一代：`#68`（基线 `a51071d05d6d7896`）。

## §1 本波做什么（范围画死）

`D-G126`（回复点缺陷 · 备份集在落地集之外冻结）与 `D-G127`（装置缺陷 · 只读车道的影子树与权威树同
inode ⇒ 一次原地写就**写穿**产品件）**两处都不响**。本波把两条牙**落仓 ＋ 接线**，**零产品改动**。

| # | 落点 | 来源／sha16 |
|---|---|---|
| 1 | `build/MilBridge/tools/backup-completeness-gate.sh` | 实件 `cb0246aab85af2b9` ＋ **去车道名落仓补丁** ⇒ **`ab73167a2427cbdf`** |
| 2 | `build/MilBridge/tools/repo-alias-check.sh` | 实件 `eccf5dadb4df5861` ＋ `--allow` 补丁 ⇒ **`b11e13f8bb024abc`** |
| 3 | `build/MilBridge/repo-alias-allow.tsv` | 新写（**逐行带"为什么允许"**） |
| 4 | `build/MilBridge/tools/bak-completeness-step.sh` | 新写（第 `[40]` 步驱动：牙自测 ＋ **UNWIRED 谓词**） |
| 5 | `docs/WAVE69-PREREGISTRATION.md` | 本文件 |

> 🔴 **开工时的真漂移（以实件为准）**：产源车道留下的描述件声称牙带 `--allow` 白名单，但**实件
> `eccf5dadb4df5861` 里 `--allow` 命中 = 0**。照描述件接线 ⇒ `[41]` 在真树上**必红**（现算
> `aliased_out=6417 rc=1`）⇒ 本波**永远冻不了**。落仓版 = **实件 ＋ 可复现补丁**。
> 口径：**描述件不是证据；以「实件 ＋ 补丁 rc=0 ＋ 现场读数」为准。**

**步数**：首行 `DECL` 声明的步数 **39 → 41（+2）**；`[40] BAK-COMPLETENESS`｜`[41] REPO-ALIAS`。
**覆盖面**：`fp_inputs()` 显式清单 **+4 行**（落点 1–4；`docs/**` 不在覆盖面）⇒ `coverage_n` 167 → 171。
**不碰**：`integration-wave.sh`｜`known-red.json`｜主控五件（`KNOWN-DEFECTS.md`／`ROUTES.md`／
`HANDOFF-NEXT.md`／`FORK-AND-PUSH.md`／`defect-registry-declared.tsv`）｜任何产品件。

## §2 判据（落地前写死；读数之后再改即事故）

### 2.0 本波**不做**回归判定（**机读行**；纪律 45，`#69` 起生效）

```
PREREG-NO-REGRESSION-DECISION: yes
```

**本波不做任何回归判定** —— 本波全部判据都是**确定性量**（件数、`%h>1` 计数、`rc`、覆盖面件数、
白名单上限比较、`run_step` 代码形状计数），**没有任何"两臂对照 ⇒ 比出一个率"的设计**。
因此"回归判定四要件"对本波**逐条 `N/A`**（**不是"已满足"，是"不适用"**）：

| 要件 | 对本波的状态 | 逐条理由 |
|---|---|---|
| ① 两臂同刻 | **N/A** | 本波无"两臂"：判据读的是**同一棵树同一刻**的确定性量，不存在跨时刻拼接 |
| ② 成对归因臂 | **N/A** | 本波有**成对归因**（只换被判件／只换白名单），但它服务的是"牙会不会红"，**不是**两臂率差 |
| ③ 复现性 | **N/A** | 本波不判"复现／不复现"：牙的三态是**确定性**判词，同一输入必得同一判词 |
| ④ Fisher 检验 | **N/A** | 本波**无率**可检：`aliased_out`／`n_wired` 是**计数**，不是频次 |

⚠️ **本声明只在它落在本节（判据节）之内时有效**，且**不是免死金牌**：本波若**事后**想加任何率比较
（例如"改前红率 vs 改后红率"）⇒ 本声明**当场失效** ⇒ 必须按 `PREREG-TEMPLATE §1` 补写四要件
**重开**预登记。

### 2.1 输入来源（纪律 36：**判据的输入必须声明**）

判据的输入 = ① **权威树现读**（`verify-all.sh`／`build/close-wave.sh`／`fp_inputs()` 覆盖面／
`docs/CURRENT-STATE.md:9` 的 `gen=`）；② **真树别名景观**（本车道现扫，全量成员表落**仓外**）；
③ **两牙实件 sha16 ＋ 落仓补丁**；④ **沙箱人造反例**（`~/w167a/w69/pol/`）。
**不用**任何记忆值；**不采**死车道的描述件当证据。

### 2.2 全波判据（`J1`–`J6`，三态 `PASS=rc0`／`FAIL=rc1`／`NOINFO=rc3`，**`NOINFO` 不算绿**）

- **`J1` 步数真不变量**：**首行 `DECL` 声明的步数 == 现取 `grep -c '^run_step "'`** ⇒ 落地后 **41 == 41**。
  ⚠️ **`DECL` 行数 ≠ 步数**（现场 `35 vs 39`）—— 本波**不**写"`DECL` 行数 == `run_step` 数"这条断言。
- **`J2` 四处声明同趟**：`DECL`（新行插在**现第一行之前**）＋`STEP-NAMES`（行尾追加）＋口径句
  （`grep -qF` 逐字命中 ``**`#69` 收官起 = 41 步**``）＋本预登记 ⇒ `[17] VERIFYALL-SELF` 应印
  `count-mismatch=0` ∧ `name-set-differs=0` ∧ `prereg=PASS`。
- **`J3` 覆盖面位移**：`[18] FP-INPUTS-HYGIENE` 印 `coverage_n` **由 167 变 171**；增量 ≠ 4 ⇒ `FAIL`。
- **`J4` 零位移**：不动产品件；`inputs_fp` **只因本波自含 `close-wave.sh`** 而变 ⇒ 必须排在 `IN_FP_0` 采样**之前**。
- **`J5` 新件 `%h==1`**：4 个落点写入前逐件 `stat -c %h` == 1，不满足 ⇒ **拒写 `exit 9`**。
- **`J6` `$R` 零污染**：本波各步产物**落仓外**（`--tsv` 落 `$HOME/.cache/wpf-linux/`）；跑完
  `find $R -newermt <步起点> -type f` **零新增**。

### 2.3 牙 1 `backup-completeness-gate.sh`（`D-G126`）

`PASS` ⇔ `BCG-SELFTEST=PASS legs=8 bad=0` ∧ `rc=0`。**零检查必红**：空 plan ⇒ `examined==0` ⇒ **必须 `FAIL`**。
**射程（如实划界）**：本步跑的是**牙的自测**（证"装置还活着 ＋ 五条负腿真会红"）；牙的**真用法**
（`--plan` 驱动的落地前完备性判定）**不在门禁里** ⇒ 见 §2.5。

### 2.4 牙 2 `repo-alias-check.sh`（`D-G127`）

`PASS` ⇔ `ALIAS=PASS … aliased_unallowed=0 reason=known-alias-trees` ∧ `rc=0`。
**零检查必红**（`examined==0 ⇒ FAIL`）｜**扫不完 ⇒ `NOINFO`**（绝不把"没扫完"当"没孪生"）｜产物不落 `$R`。

🔴 **口径句（逐字）**：**"允许清单是声明式豁免，不是把牙关掉。"**
⇒ 白名单**只降 `aliased_out` 一项**（降成 `aliased_allowed`），四项计数照打；**未被覆盖的孪生照旧
`FAIL reason=out-of-repo-alias`**；**当前件数 > 上限 ⇒ `FAIL reason=allowed-tree-grown`**（**树长大也红**）；
唯一一种"有孪生还给绿"的情形 = **全部覆盖 ∧ 各有界**。白名单件**每行带"为什么允许"**。

### 2.5 🔴 `UNWIRED` 声明的**可跑谓词**（`D-G132`：声明没有机读读者）

**声明**：`[40]` 步跑的是牙的 `--selftest`；牙的真用法（`--plan`）**未被门禁调用** ⇒ `producer=UNWIRED-IN-STEP`。

**谓词（限定到代码形状；全文命中只作旁证）**：

```
n_wired = grep -E '^[[:space:]]*run_step .*backup-completeness-gate\.sh.*--plan' <verify-all.sh> | wc -l
n_wired == 0 ⇒ 声明成立（PASS）｜ n_wired >= 1 ⇒ 声明**失效** ⇒ 本步**必须红**
```

该谓词**是 `[40]` 步的一部分**（`bak-completeness-step.sh` 内求值并把 `n_wired` 打进机读行
`BAK_COMPLETENESS=… n_wired=…`），**不是报告里的一句散文** —— 产出端哪天被接线了，**门禁当场翻红**。

## §3 两极化（**先写判据再跑；正极必现／反极必不现**）

| 判据 | 正极（必现） | 反极（必不现／必红） |
|---|---|---|
| 牙 1 备份完备性 | 备份齐、sha16 相符 ⇒ `PASS` | 备份缺失／错版本／**是硬链接**／空 plan ⇒ **`FAIL` ＋ 点名** |
| 牙 2 别名 | 全树被白名单覆盖且各有界 ⇒ `PASS known-alias-trees` | 🔴 **孪生不在清单里 ⇒ 必红 `out-of-repo-alias`**；上限 −1 ⇒ 必红 `allowed-tree-grown` |
| `UNWIRED` 谓词 | 现状 ⇒ `n_wired=0` 绿 | 🔴 **沙箱插一条真调用 `run_step` ⇒ `n_wired≥1` 必红** |

## §4 边界（**逐条 `NOINFO`／不覆盖**）

1. 牙 1 的**真用法**（落地前 `--plan` 完备性判定）**不在门禁**：`integration-wave.sh` 未授权改动 ⇒
   本波只保证"装置活着 ＋ 谓词会响"；**不**保证"落地的每件都真被查过"。
2. 牙 2 **只覆盖 inode 共享**；**同内容的独立真拷贝不报**（正确行为）；孪生在 `--roots` 外／深于
   `--maxdepth` ⇒ **不检出**；符号链接影子、**写穿已发生的历史** ⇒ **不覆盖**。
3. 白名单是**声明**：它不下调任何判据强度 —— 但**未被点名的树**一旦出现即红，**需要人复核**（这是设计意图）。
4. `docs/**` **不在** `fp_inputs()` 覆盖面 ⇒ 改本文件不动 `inputs_fp`。
5. 卫生：显示号只用 `:23x` 族 `1280x1024x24`；进程**只按 PID** 收（**禁** `pkill`／`pgrep -f`）；
   `cp -al`／`cp -l`／`ln` 不得用于任何"我要在里面写"的树（写前 `stat -c %h` 断言 1）；
   重活走 `~/heavy-slot.sh`；**零 `dotnet`**。
