# W26A · `D-G14` 列级覆盖闸 + `D-G12`（同一份文件、一笔构建）

**lane = W26A** ｜ 2026-09-17 14:00 → 14:55 +0800 ｜ kernel `6.8.0-138-generic` ｜ nproc = 3
`loadavg` 开工 `1.15 0.46 0.56` → 收工 `0.75 0.31 0.51` ｜ `MemAvailable` 开工 **3,211 MB** / 最低 **3,045 MB** / 收工 **3,100 MB**
`dotnet` 进程数：开工 0 / 峰值 **1**（本波唯一构建者，`-m:1` + `DOTNET_gcServer=0`，逐趟自检 ≤2）｜ 零 `pkill` ｜ 未用 `pgrep -f` 下结论（一律 `pgrep -c -x dotnet`）

---

## 0 · 一句话结论

**两件都落地并取到读数。** `D-G14` 列级闸把「整例跳过」改成「逐列判定」后，`tab-anchor` 的 `Start` 列
**判定行 `421 → 615`、`NOINFO 194 → 0`**、**红 = 0**、**RTL 非零 `Start` 实判 `33/33` 行**（真值侧可达 33 全部到手）；
`D-G12` 把 `perChar[].width` **真的接进了比较**（可判字宽 **97** 条），并**实测了它今天会不会红**：
**不红**（`pass 39 / fail 18` 与改前逐字节相同）—— 因为它**只比真测量值**，而今天真正"差得大"的字宽全部落在
**语义不可判**的两类上（`tab` 的真值宽是**网格推进量**、我方"零宽"是**根本没量到**），本件把它们**如实计为 `NOINFO` 而不是红**。
**三支 `tab-*` 臂已重取**（硬链接）且门禁 **`TLINE_GATE=PASS` 逐项不变**；九位与 `inputs_fp` **逐位未变**。

---

## 1 · 写域清单与改动 before/after sha16

### 1.1 写域（严格按派单）

| 路径 | 我做了什么 |
|---|---|
| `build/MilBridge/tests/CoverageProbe/Program.cs` | **主改动**（`D-G14` 列级闸 + `D-G12`） |
| `build/MilBridge/tests/CoverageProbe/{bin,obj}` | 重建产物（本文件的 `bin`/`obj`） |
| `build/MilBridge/arm-logs/{tab-zero,tab-anchor,tab-rtl}.log` | **重取**（`ln -f` 硬链接，见 §5） |
| `build/MilBridge/W26A-report.md` | 本报告（新建） |

**写域外零触碰（机器证）**：`find build/MilBridge/tests/CoverageProbe build/MilBridge/arm-logs -newermt '2026-09-17 13:50' -type f`
只列出 `Program.cs` + 它自己的 `bin/obj` + 三支臂日志。
`build/shims/**`、`build/PresentationCore.Linux/**`、`build/PresentationFramework.Linux/**`、`src/**`、
`known-red.json`、`verify-all.sh`、`tline-gate.sh`、`close-wave.sh`、`integration-wave.sh`、`docs/**` **一个字节都没动**。

### 1.2 sha16（现场 `sha256sum` 算，纪律 49）

| 件 | before | after |
|---|---|---|
| `build/MilBridge/tests/CoverageProbe/Program.cs` | **`dea2a02cf8bab55a`**（125,908 B） | **`2477901979795979`** |
| `build/shims/PresentationCore.HbTextLine.cs` | `e89fed55fd8e32bc` | **`e89fed55fd8e32bc`（逐字节未变）** |
| `build/MilBridge/arm-logs/tab-anchor.log` | `56abc845dbd29e93` | **`574d012a41a3db06`** |
| `build/MilBridge/arm-logs/tab-zero.log` | `424d4c6d5ab121cb` | **`78204619fa5b4eee`** |
| `build/MilBridge/arm-logs/tab-rtl.log` | `5e4d9ef3c64f7d7e` | **`cbaa579c547b4ac3`** |
| `build/MilBridge/known-red.json` | —— | `5aead470c23a99ff`（**他人写域**，mtime 14:04:22，W26D；门禁本身不因此变红） |

备份：`$HOME/w26a-backups/Program.cs.before`（= `dea2a02cf8bab55a`）、`$HOME/w26a-backups/PresentationCore.HbTextLine.cs.orig`（= `e89fed55fd8e32bc`）。

### 1.3 `D-G14` 的施工件与施加

施工件照 `#25` W25I：`$HOME/w25i/column-gate.diff`（`sha16 9340d85dfcf91fc0`）。
**本件自证**（纪律 4：不引述、现场重跑）：

```
$ cp build/MilBridge/tests/CoverageProbe/Program.cs $HOME/w26a-verify/a/build/MilBridge/tests/CoverageProbe/
$ cd $HOME/w26a-verify/a && patch -p1 --dry-run < $HOME/w25i/column-gate.diff   # rc=0
$ patch -p1 < $HOME/w25i/column-gate.diff                                       # rc=0
$ cmp build/…/Program.cs $HOME/w25i/Program.cs.patched                          # IDENTICAL ⇒ 51f50350994ca672
$ cd $R && patch -p1 < $HOME/w25i/column-gate.diff                              # rc=0 ⇒ 仓内 Program.cs = 51f50350994ca672
```

### 1.4 `D-G12` 的两处改动（行号 = **最终件** `2477901979795979`）

| # | 位置 | 改了什么 | 为什么 |
|---|---|---|---|
| ① | `:756-768`（插入） | 声明 `posRedX / posRedW / posRedBoth / posRedTot / posRedCmp / posRedNonCmp / wSkip / wSkipTab / wSkipZero / wTruthCh / wNoise*` + `OurW(...)` 取宽函数 | 让 `D-G12` 的红**可归因**（"只宽红 / 只位置红 / 两者都红"），并把"不可判"与"红"分开数 |
| ② | `:830-885`（改 `RunTabOracle` 的逐字比较循环） | 把**已读未用**的 `exp[k].w`（`:793` 读入）接进比较：`dW = |OurW(ours[k,1]) − wTruth|`，容差 **0.05**（与 `xFromLeftDip` **同一个**口径） | 缺口本体 |
| ③ | `:909` | `bool ok = … && posRedCmp == 0;` | **只加严**：`posRedCmp` 只统计**可判**字宽，不改变既有两项 |
| ④ | `:918-923` | 新增 `TAB_ORACLE D-G12 …` 一行 | 本件的机读读数载体 |
| ⑤ | `:912-916` | `❌` 行**追加** `；\`D-G12\` 逐字宽红=… 逐字位置红=… 共红字符=…`（前缀逐字节未动） | 归因 |

⚠️ **`D-G12` 的口径边界（本件踩过一次、如实登记）**：逐字宽**只在四个条件同时成立时**才是"真比较"：
**非 `\t`** ∧ 我方 `have[k]`（真有 `GetTextBounds`）∧ **我方宽 ≠ 0** ∧ 该字符在我方行内。
理由不是"这样能过"，而是**那三类根本不是字宽测量值**：

* **`\t` 的真值宽 = 网格推进量**（实测 `tab-two-mid@w40@LTR` 的 `\t` 宽 = **82.653333** = 96 − 13.346667），
  **不是字形宽** ⇒ 与我们的 tab 区间比是**语义错配**；
* **我方宽 = 0** ⇒ `GetTextBounds` 给了退化/零宽区间，**我们根本没量到** ⇒ 拿"没量到"当"量到 0"是假红；
* **无 bounds** ⇒ 无测量（探针本来就声明"用邻居插值参与对拍"，那是**估计值**不是测量值）。

⇒ 这三类**一律计 `NOINFO`**（`wSkip=64`：`tab=61` + 我方零宽 3），**不报红也不报绿**。
**第一版没有这些边界**，读数留档如下（这是本件最值钱的一条自证）：

| 版本 | `逐字宽红字符` | `pass/fail` | 结论 |
|---|---|---|---|
| 第一版（只加 `have[k]` 守卫） | **22** | `0 / 57` | **会把 39 例绿洗成红** —— 归因显示 22 条里 **19 条是 `\t`**、**16 条我方宽 = 0** |
| 最终版（四条边界） | **0** | **39 / 18（与改前逐字节同）** | 接线在、牙齿在（§4.4）、**今天不红** |

---

## 2 · 正向读数（`D-G14`）：列级账，改前 vs 改后

**命令**（每趟都现场跑；探针构建 `-m:1` + `DOTNET_gcServer=0`）：

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; cd "$R"; export PATH="$HOME/.dotnet:$PATH"
dotnet build build/MilBridge/tests/CoverageProbe/CoverageProbe.csproj -c Release -m:1 --nologo -v q   # 0 error 0 warning
for arm in tab-zero tab-anchor tab-rtl; do
  ( cd build/MilBridge/tests/CoverageProbe/bin/Release && \
    timeout 3600 dotnet PresentationCore.Tests.dll --tab-lines-oracle "$R/tests/parity/windows/$arm/out/$arm-oracle.json" )
done
```

### 2.1 `tab-anchor` 的逐列账（`red + green + NOINFO == 615` 全列成立）

| 列 | 改前 判定行 / NOINFO | **改后 判定行 / NOINFO** | 改后红 |
|---|---|---|---|
| 结构列（行数/width/tws/nl） | 288 例 / 148 例 | **288 例 / 148 例（不变）** | 0（`结构败=0`） |
| 位置列（`perChar[].xFromLeftDip`） | 421 / 194 | **421 / 194（不变）** | 0（`位置=FAIL` 0） |
| **`Start` 列（本件新增判定面）** | **421 / 194** | **615 / 0** | **0** |
| `HasOverflowed` 列 | 421 / 194 | **421 / 194（不变）** | 0 |

**逐字读数（原文照录）**：

```
改前 TAB_LINES START 红=0 绿=421 判定行=421 NOINFO=194 红例=0 NOINFO例=148 对齐=Left …
改后 TAB_LINES START 红=0 绿=615 判定行=615 NOINFO=0 NOINFO字形=0(构造性:本列不经字形) 字形释放行=194 非零真值行判定=171 红例=0 NOINFO例=0 对齐=Left …
     TAB_LINES START 对账 逐例求和 红=0 绿=615 NOINFO=0 ⇒ 与汇总一致
改后 TAB_LINES OVERFLOWED 红=0 绿=421 判定行=421 NOINFO=194 … NOINFO字形=194 NOINFO字形外=0 真值True=22 …
改后 TAB_LINES 合计 cases=436 判定过=288 结构败=0 不可比(缺字形)=148 …
改后 TAB_LINES 退出码=0（未登记失败 0 / 失败共 0 / 登记表 <未给>）
```

* `字形释放行 = 194`、`非零真值行判定 = 171`（= 语料里 `Start ≠ 0` 的真值行总数）⇒ **上界 615 与 `[162,171]` 都打满了**。
* **`NOINFO = 0`** ⇒ **没有任何一行落到 `NOINFO=行数不符`**（`grep -c 'NOINFO=行数不符' = 0`）：
  148 个缺字形例**全部**成功格式化，我方行数 **≥** 真值行数。

### 2.2 既有 288 例 / 421 行：判定逻辑一行未改（机器证）

| 检验 | 命令 | 结果 |
|---|---|---|
| `合计` 行 | `diff <(grep '^TAB_LINES 合计 ' pre.log) <(grep … confirm.log)` | **IDENTICAL** |
| `最大差=` 行 | 同上 | **IDENTICAL** |
| `跳过=面缺字形` 行数 | `grep -ac '跳过=面缺字形'` | **148 → 148** |
| `结构=PASS` 例数 | `grep -ac '结构=PASS'` | **288 → 288** |
| **436 条 `CASE` 行逐字节** | `diff <(grep '^TAB_LINES CASE ') …` | **差异 0 行** |
| 288 例的逐例 `(结构,位置)` 状态 | python 解析后比字典 | **完全相等** |
| `FAILCASE` 行数 | `grep -ac '^TAB_LINES FAILCASE'` | **0 → 0** |
| **既有 421 条 `START` 逐例行** | 剔掉 `NOINFO=面缺字形` 行后 `diff` | **差异 0 行**（逐字节相同） |
| **全日志归一化后** | `replace('(本列依赖字形)','')` 后逐行比 | 差异 **151** 行 = 148（`START` 的 194 行 `NOINFO` → 逐例判定行）＋ 3（标签化后的行） |

**列级对账（`grep`+`paste`+`bc` 现场算）**：

| 量 | 改前 | 改后 |
|---|---|---|
| `START` 逐例行求和 红 / 绿 | `0 / 421` | `0 / 615` |
| `START` 逐例行 `NOINFO=面缺字形` 行数求和 | `194` | `0` |
| `START` 新增判定行 | —— | **615 − 421 = 194** |

### 2.3 另两支臂：本件**不影响** `Start` 列（`startField=false`，构造性）

| 语料 | cases | 有 `lineStartOffsetsDip` 的例 | `startField` | 缺字形行 | 改后 `START` 计数段 |
|---|---|---|---|---|---|
| `tab-zero` | 86 | **0** | **false** | 0 | **根本不打印**（`if (startField)`） |
| `tab-rtl` | 84 | **0** | **false** | 152 | **根本不打印** |
| `tab-anchor` | 436 | **436** | **true** | 194 | 打印（§2.1） |

**实测日志 diff 规模（改前 vs 改后）**：`tab-zero` **2 行**、`tab-rtl` **154 行**、`tab-anchor` 598 行。

* `tab-zero` 的 2 行 = `OVERFLOWED` 汇总行（新增 `NOINFO字形=0 NOINFO字形外=138`）＋ 它自己的 `<`/`>` 对。
* `tab-rtl` 的 154 行 = 同一行 ＋ `76 例 × 2`（每例 `OVERFLOWED … NOINFO=面缺字形N` → `…(本列依赖字形)N`）。
* `tab-anchor` 额外多出的是 `START` 列的 194 行改写（§2.2）＋ 同上的标签行。

---

## 3 · RTL 收益（本件的核心数）

**真值侧可达 = 33 行**（`D-paraindent` 的 hebrew RTL，`PI=24` **15** 行 + `PI=48` **18** 行），**我方实判 = 33 行**。

| 量 | 值 | 来源 |
|---|---|---|
| 缺字形 194 行的 `Start` 真值分布 | `{0: 161, 24: 15, 48: 18}` | 现场 python 复算（语料 `lineStartOffsetsDip`） |
| 其中**非零**行 | **33** | 同上 |
| `D-paraindent` hebrew 非零行 | **33** | 同上（`by PI: {48: 18, 24: 15}`） |
| 这些行的**行下标**分布 | `{0: 24, 1: 6, 2: 3}` | 同上（⇒ 下界 24、上界 33） |
| **我方实判行数** | **33**（`33/33`） | 缺字形例的 `START` 逐例行**全部**为 `红=0 绿=N`、**无一例** `NOINFO=行数不符` |

⇒ **真值侧 33 与 我方实判 33 在本趟里相等**（预测区间 `[24, 33]` 的上端）。
**这不是"按构造绿"**：判据真调 `FormatParagraph`、真读 `line.Start`（`shim:3484 => _paragraphIndentDip`）；
若走"不格式化、拿 `paragraphIndentDip` 自比"的捷径则永不红 —— §4 的 `Start => 0` 档 **171 红**证明它**能红**。

---

## 4 · 反极性（三级 + `D-G12` 一级，全部实测）

**做法**：`cp -p` 原件 → 只改 `build/shims/PresentationCore.HbTextLine.cs:3484`
（`public override double Start => _paragraphIndentDip;`）的**表达式** → 重建 `CoverageProbe` → 跑 `--tab-lines-oracle` →
`cp -p` 复原并 `cmp` 证明逐字节回到 `e89fed55fd8e32bc`。**每档都复位（`cmp=IDENTICAL`）**。
驱动脚本：`$HOME/wfp-runs/w26a/polar.sh`；读数在 `$HOME/wfp-runs/w26a/pol-r*/`。

| 档 | `Start` 表达式的改法 | **预测** | **实测** | `退出码` / `UNREGISTERED` |
|---|---|---|---|---|
| ① 正极性 | 不改（`=> _paragraphIndentDip`） | 红 0 | **红=0**（绿 615 / NOINFO 0） | `rc=0` / 0 |
| ② **`D-T6-c` 复发** | `=> 0;` | **171**（138 既有 + 24~33 新释放，下界 162） | **红=171**（绿 444） | `rc=1` / **112 例** |
| ③ 偏置 | `=> _paragraphIndentDip + 24;` | **615** | **红=615**（绿 0） | `rc=1` / **436 例** |
| ④ 常数（最锋利） | `=> 24.0;` | （主控只给三级；本件补测） | **红=484**（绿 131）；对账 `484+131+0=615` ✔ | `rc=1` / 352 例 |

* **②的 171 = 138 + 33** 逐位兑现：既有 latin 非零真值行 **138** + 新释放的非零行 **33** ⇒ **两级预测都中**。
* ④ 的 484 = 真值 `{0: 444, 48: 40}`（≠24 的行）—— **`24` 与 `48` 都能被区分开**（若把 `48` 也读成 `24` 则红只有 444，实测 484 ⇒ 未被吞）。
* **`判据：红 + 绿 + NOINFO == 615` 在四档上全部成立**（②`171+444+0`、③`615+0+0`、④`484+131+0`、①`0+615+0`）。
* **行数不等的例必须走 `NOINFO=行数不符`、不误红**：本语料上**这条路径一次都没被触发**（`NOINFO=0`），
  所以"不误红"在本趟是**未被行使的通道**（构造上存在：`if (k >= gcommon)` 分支与既有 `:1545` 同形，
  只计入 `stNoinfo`、不计 `stRed`/`stGreen`）。**本件不把它读成"已证"**。

### 4.4 `D-G12` 的极性（`W26A_WSCALE` 注入，默认缺省=不生效）

`W26A_WSCALE` 把"我方字宽"按因子缩放（**判据与归因共用同一个 `OurW()`**）：

| 趟 | `逐字宽红字符` | `可判并集红字符` | `pass/fail` | 结论 |
|---|---|---|---|---|
| **缺省**（不设变量） | **0** | **0** | **39 / 18** | **今天不红** |
| `=1.0` | 0 | 0 | 39 / 18 | 与缺省趟 **逐字节相同**（`cmp` IDENTICAL）⇒ 注入本身零副作用 |
| `=2.0`（一颗牙） | **97** | **97** | **0 / 57** | **有判别力**：可判字宽 **97/97 全红**，归因行 `红面=宽` |

* `=2.0` 时 `字宽差分位(>0.5)=97` ⇒ 红**全是宏观差**（不是 0.02~0.5 的字体度量舍入）。
* 归因行**样本**（原文照录）：
  `D-G12-RED no-tab@w40@LTR k=0 i=0 字符[a] 真值宽=13.346667 我方宽=26.695312 Δ宽=13.348645 位置Δ=0.000000 可判=可判 红面=宽`
* 同时 `不可判侧位置红字符=21`、`字宽不可判字符=64（tab=61 我方零宽=3）` 在**两趟里完全相同** ⇒ 注入只动了"可判字宽"这一面。

---

## 5 · 三支 `tab-*` 臂重取（本波硬要求）

**为什么必须重取**：`CoverageProbe` 的字节变了 ⇒ 三支 arm 日志**不再是当前证据**；
而**探针不在 `GEN_KEYS`** ⇒ **没有任何机器会强制重取**（纪律 34 的**真空档**，本件如实转记）。
`GEN_KEYS` 现场重读：`build/MilBridge/tools/tline-gate.sh:234`
`GEN_KEYS = ("instr_run_sh", "instr_program_cs", "instr_shim")`
＋ `:236` `tree = {"instr_run_sh": i_run, "instr_program_cs": i_parity, "instr_shim": i_shim}`
＋ `:136-137` `SH_PARITY="$MB/tests/HbTextLineParity/Program.cs"` / `SH_SHIM="$ROOT/build/shims/PresentationCore.HbTextLine.cs"`
⇒ 三项 = `run.sh` / `HbTextLineParity/Program.cs` / `shim`，**本件一个都没动**。

**重取命令（照 `build/MilBridge/tools/retake-arms-w23.sh` 的三支子集；只重取不经 `tline`/`textlineproto` 的三支）**：

```bash
# ① 重建宿主（-c Release）→ ② 跑三支 → ③ ln -f 硬链接进 arm-logs
for f in tab-zero tab-anchor tab-rtl; do
  ln -f "$HOME/wfp-runs/w26a/final5/$f.log" "build/MilBridge/arm-logs/$f.log"
done
```

**硬链接三条机器证**（README 的硬要求）：

| 证 | 读数 |
|---|---|
| **不是 `cp`**（不顶 mtime） | `stat -c '%i %h %y'`：`ino=5149993/5149994/5149995`、**`links=2`**、mtime = **源文件原始 mtime**（`14:28:25` / `14:31:10` / `14:31:16`），不是 `ln` 那一刻 |
| **不是 `ln -s`**（门禁 `find -type f` 会漏） | `find build/MilBridge/arm-logs -maxdepth 1 -type f -name '*.log'` ⇒ **5 个**（三支 tab + `tline` + `textlineproto`） |
| 内容与源逐字节同 | `cmp` **三支全 IDENTICAL** |
| **弱配对判据仍成立** | 日志 mtime ≥ 世代被测件 mtime（shim `e89fed55fd8e32bc` mtime `00:12:06`）；门禁逐臂 `caliber=OK-tree`（§5.2） |

### 5.2 `TLINE_GATE=` 那一行（重取后，**逐字**）

```
TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2 outdir=/home/links-dev/wfp-runs/w26a/gate-after3
GATE_REASON=all-as-registered
```

**逐项报出**：`generation=#23`（**登记表世代未变**）｜`tree_gen=same`（树 == 世代，三项仪器零改动）｜
`drift=0`｜`gone=0`｜`unregistered=0`｜`caliber=OK`｜`noinfo_arm=0`（五臂都有读数）｜
`saved_shim=e89fed55fd8e32bc`｜`red=2 green=3`（红臂 = `tline` + `tab-oracle-zero`，**都是改前就红的在册红**）｜`unlocated=1`（`tline/T3b`，既有）。
逐臂：`tline RED strong caliber=OK-declared`｜`tab-oracle-zero RED weak caliber=OK-tree`｜
`tab-oracle-anchor GREEN weak caliber=OK-tree`｜`tab-oracle-rtl GREEN weak caliber=OK-tree`｜`textlineproto GREEN weak caliber=OK-tree`。
**重取前**同一命令（当时的 `arm-logs`）也给 `PASS`、逐项相同 ⇒ **重取不改变裁定**。

**门禁的判据解析面**（本件只改 `Program.cs`，不该影响门禁读的那几行）：门禁只读
`^TAB_LINES 文件=`(`:387`)、`^TAB_LINES 合计 cases=… 判定过=… 结构败=… 不可比(缺字形)=…`(`:389-393`)、
`^TAB_LINES 退出码=`(`:394-395`)、`^TAB_LINES UNREGISTERED`/`KNOWN-RED`(`:405-406`)、
`^TAB_LINES CASE … 结构=`(`:409`)、`^TAB_LINES FAILCASE`(`:411`)。
上述每一行**前缀逐字节不变**、`合计`/`退出码`/`CASE`/`FAILCASE` 的**值也不变**（§2.2）。
⚠️ **一条仪器局限（如实登记）**：门禁要求**五臂齐备**，所以**无法只用三支 tab 臂**做"改前 vs 改后"的门禁 A/B
（实测：只喂三支 ⇒ `TLINE_GATE=NOINFO … noinfo_arm=2`）。
⇒ 本件对"门禁面零位移"用的是**上表那几行的逐字节/逐值对比**（更强的证），不是门禁 A/B。

---

## 6 · 零位移复核（九位 + `inputs_fp`）

| 位 | 实测 | 冻结 `#25` | 判 |
|---|---|---|---|
| `bridge` | `d567c26f197ec1e3` | `d567c26f197ec1e3` | ✔ |
| `pc` | `7374308a00c55572` | `7374308a00c55572` | ✔ |
| `pf` | `eb48655d697a4188` | `eb48655d697a4188` | ✔ |
| `windowsbase` | `1114a28ec5a03ab7` | `1114a28ec5a03ab7` | ✔ |
| `provider` | `9aa0d744802aaa31` | `9aa0d744802aaa31` | ✔ |
| `win32shim` | `0098234982391bbf` | `0098234982391bbf` | ✔ |
| `wic_shim` | `03b67fbcd7c385b6` | `03b67fbcd7c385b6` | ✔ |
| `hbtextline` | `e89fed55fd8e32bc` | `e89fed55fd8e32bc` | ✔ |
| `dwf` | `0ed422ef2dd46445` | `0ed422ef2dd46445` | ✔ |
| `inputs_fp` | `0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8` | 同 | ✔ **未变** |

`inputs_fp` 用 `build/close-wave.sh:68-79` 的 `fp_inputs()` **原样照抄**（未自己发明）；
`build/shims/PresentationCore.HbTextLine.cs` **一个字节未动**（§1.2）。
⇒ **§5 停条件 1/2/3/4 全部未触发**（产品件、`inputs_fp`、shim、`generation` 三项皆未变）。

---

## 7 · 风险与裁定边界

1. **会不会让今天绿的一步变红？** **不会**。① 三支 `tab-*` 臂：`Start` 列红 **0**、`rc` 全部不变（`tab-zero rc=1` 是**既有**事实，不是本件造成）；
   ② `verify-all` 第 `[5]` 步（`pc-line-step.sh`）读的是 `^PCLINE START `（另一探针）—— 现场核：`grep -n -- 'TAB_LINES' build/MilBridge/tools/pc-line-step.sh` 命中的是**注释行**（`:6`），不是判据；
   ③ 第 `[4]` 步五臂门禁 ⇒ §5.2 实测仍 `PASS`。
2. **新红 / `UNREGISTERED`**：正极性 **0 红** ⇒ **没有未登记失败**、门禁 `unregistered=0`。
   ⇒ **§5 停条件 6 未触发**，故**不需要**主控裁定、**未登记任何东西**、**未压绿任何东西**。
3. **与在册红冲突？** 无。`known-red.json` 的 `tab-oracle-*` 只有 1 条（`tab-oracle-zero / notab-control@w40@em24@RTL@tab0 / 结构`），
   本件**没碰** `tab-zero` 的结构计数（`结构败=1` 不变、`rc=1` 不变）⇒ 该条**不会 `gone`**；
   门禁实测 `drift=0 gone=0`。
4. **本波不接线**（预登记 §3 已钉）：本件只到"探针改好 + 重取臂 + 取到读数"，**未动 `verify-all.sh` / 臂集合**。
5. **`D-G12` 今天红 = 0 的含义要读准**：它是"**在可判字宽上**没红"，**不是**"这条臂全绿"
   —— 该臂今天本来就 `pass 39 / fail 18`（`--tab-oracle` **不在任何门里**：
   `grep -rn -- '--tab-oracle' run.sh verify-all.sh tools/*.sh` = **0 命中**）⇒ 它的红绿**与门禁无关**。

---

## 8 · `NOINFO` 清单（本件证不出来的）

1. **`NOINFO=行数不符` 通道未被行使**：本语料上 148 例全部格式化成功且行数 ≥ 真值 ⇒ 该分支**零次触发** ⇒ "不误红"在本趟**未被证**（构造存在，未实测）。
2. **`HasOverflowed` 列仍全 NOINFO**（194 行）：我方量经 `_width` ⇒ 依赖字形；且 194 行真值**全 `false`** ⇒ 判别力 0。
3. **结构列 / 位置列在缺字形例上仍全 NOINFO**（148 例 / 194 行）：真值面（Arial）字节不可得。
4. **`D-G12` 的"我方零宽"3 条**：`GetTextBounds` 在**末字符**处给了零宽（`tab-head@w40@LTR` 的 `[a]`、`no-tab@w40@LTR` 的 `[d]`）
   —— 这**可能是既有仪器缺陷**（末字符区间退化），本件**只把它计为不可判、未下结论**、**未修**（不属本件写域）。
5. **`D-G12` 的"真值 `\t` 宽 = 网格推进量"**这一语义**只在本语料的三例上实测**（`tab-two-mid@w40@LTR` 等），
   未在 Windows 真机源码里取证。
6. `--tab-oracle` 臂的 `pass/fail` 与门禁的关系：**无关系**（不在臂集合里）。
7. **六条 `BASELINE`/应用门禁**：不属本件（主控波尾动作），未跑。

---

## 9 · 我推翻 / 修正的三处（含我自己的）

1. **W25I 报告 §2.1 的"上界 615 / 判定行 `[569,615]`"** ⇒ 本件实测**打满上界 615**、`NOINFO=0`；
   `非零真值行判定=171` 也**打满上界**。**下界 569 未被用到**（因为没有任何一例行数不足）。
2. **本件第一版 `D-G12` 会把 39 例绿洗成红**（§1.4 表）：我**自己抓出并修正**，并把两次读数都留档。
   根因不是"边界太松/太严"，而是**我没有先问"这个量是不是测量值"**。
3. **`--tab-oracle` 今天本来就 `pass 39 / fail 18`（`rc=1`）** —— 派单书说它"读了不用 356 条"，
   但**没说它现在是红的**。⇒ `D-G12` 的收益要按"**可判字宽 97 条**"读，不是按 `356`。
   **356 的完整对账**（现场 python，`line 793` 的 `--tab-oracle` 只跑 114 例中的**判定集 57 例**，
   因为探针按 `Program.cs:757-760` 跳过"纯拉丁内容 + RTL 段落"的另外 57 例）：

   | 构成 | 条数 | 依据 |
   |---|---|---|
   | 全语料 `cases[].perChar` | **356** | 语料（114 例；实测 57 LTR + 57 RTL，两侧 perChar 各 178，**恰好对称**） |
   | 其中**跳过集**（57 例） | 178 | 探针 `BidiSkipped=57`；判据侧**根本看不到** |
   | 其中**判定集**（57 例） | 178 | `tab=66` / 非 tab `112` |
   | 判定集里**可判字宽** | **97** | 本件实测 `真值宽>0.05者=97`（= 四条边界都过的那批） |
   | 判定集里**字宽不可判** | **64** | `tab=61` + 我方零宽 `3`（一律 `NOINFO`） |
   | 判定集里**因无 bounds 未进任何计数** | **12** | 探针自报 `无 GetTextBounds 的字符=17`（含跳过集的部分） |
   | 校验 | `66+3+97+12 = 178` ✔ | 正好等于判定集 |

---

## 10 · 产物与读数位置

| 件 | 路径 | sha16 |
|---|---|---|
| 主改动 | `build/MilBridge/tests/CoverageProbe/Program.cs` | **`2477901979795979`** |
| 重取臂 | `build/MilBridge/arm-logs/tab-{zero,anchor,rtl}.log` | `78204619fa5b4eee` / `574d012a41a3db06` / `cbaa579c547b4ac3` |
| 备份 | `$HOME/w26a-backups/Program.cs.before`、`…HbTextLine.cs.orig` | `dea2a02cf8bab55a` / `e89fed55fd8e32bc` |
| 驱动脚本 | `$HOME/wfp-runs/w26a/{runprobe.sh,polar.sh,dg12.sh}` | —— |
| 读数 | `$HOME/wfp-runs/w26a/{pre,colgate,final5,confirm,pol-r1,pol-r2,pol-r3b,dg12-*,gate-*}/` | —— |
| 本报告 | `build/MilBridge/W26A-report.md` | 自指件（sha16 在车道最终回复里给） |

**lane = W26A** ｜ 2026-09-17 14:00 → 14:55 +0800 ｜ `loadavg` `1.15 → 0.75` ｜ `MemAvailable` `3211 / 3045 / 3100 MB` ｜ kernel `6.8.0-138-generic`
