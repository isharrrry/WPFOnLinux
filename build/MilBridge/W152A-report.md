# W152A 报告（波 `#63`：判据／显示层批 D）

> ⚠️ **本文件是车道 W152A 的当前报告（波 `#63`）**。上一代（波 `#60`，仪器波 · 装置/判据欠账批 A）的版本
> 在 commit **`6f2b482`**：`git show 6f2b482:build/MilBridge/W152A-report.md`。
> 仓 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**不是 git 仓**）｜基线上代 `#62` = `845219762aa61fb8`／903,901 B
> 判据 `~/w152a/criteria63.md`（**判据先写**，写定于取任何"修后"读数之前）｜本报告 `APPEND_ONLY`

---

## §0 开工闸（四条）

| # | 判据 | 现场值 | 判 |
|---|---|---|---|
| ① | `~/w21-verify/w62-POST.done`（**真 `stat`**） | `2026-09-24 13:09:14.404562549 +0800` | ✓ |
| ② | `docs/CURRENT-STATE.md:9` | `gen=#62 sha16=845219762aa61fb8`（件 903,901 B） | ✓ |
| ③ | 现场无链在跑 | **none** | ✓ |
| ④ | `flock -n ~/heavy.lock` | `FREE` | ✓ |

### §0.1 闸③ 的"排除自身"口径——本波**又逮到第二种变体**
逐 pid 读 `/proc/<pid>/cmdline`，排除 `$$` ∧ `$PPID` ∧ 沿 `/proc/<pid>/stat` 上溯到 `1` 的祖先链。
⚠️ **第一版只排了 `$PPID` 的祖孙链、漏排 `$$` 自己** ⇒ **把自己的扫描进程判成"非自身进程"**。
⇒ 口径订正为**显式列出 `$$`**。**这是 `TASK-0714` 那条纪律的第二个活样本**（自匹配族：
① 漏排 `$$` ② `NEW` 逐字包含 `OLD` ③ 空集恒相等 ④ 读 `/proc` 被当枚举…）。

---

## §1 四项改动（落地清单）

| 件 | 入口件 | 修前 → 修后 |
|---|---|---|
| ① `D-G115` | `build/MilBridge/tools/regression-decision.py` | `71734fce77842478`（1003 行）→ **`6a0e8ccc0c6cb5d7`**（1058 行） |
| ①b 台账 | `build/MilBridge/tools/regression-decision-cases.tsv` | `5d3c26a1c8d83688`（13 行）→ **`de6290cfad8892a1`**（15 行） |
| ② `D-G116` | `build/MilBridge/tools/regime-identity-check.sh` | **新建** → **`97cfab155dfa9bce`**（284 行） |
| ③ `D-G117` | `build/MilBridge/tools/prereg-four-requirements-check.sh` | `235d76b61cdc46a4`（443 行）→ **`a40aac9031304a8f`**（459 行） |
| ③b `D-G117` | `verify-all.sh` | `58422c5f1f2c5682`（1122 行／`run_step=35`）→ **`2819b5990e74cc80`**（1139 行／`run_step=36`） |
| ④ `why` | `build/MilBridge/known-red.json` | **`b3f264bbf43dbd61`**（`#62` 真值，`HEAD:` 复核）→ **`2209966ee1d2c5cc`** |
| ④b 名单 | `build/close-wave.sh`（新牙入覆盖面） | `07ee249b8f570895` → **`9ee0c2488d25f6f6`** |
| 接线 | `docs/WAVE63-PREREGISTRATION.md` | **新建**（H1 含字面 `#63`） |

全部 `temp ＋ rename`；落前 `cp -p` 备份到 `~/w152a/backups/`；**前后 sha 双断言**。

---

## §2 件①：`D-G115` 判词补「方向」

### 2.1 机制与修法
`fisher_2x2` 是**双尾** ⇒ `p ≤ alpha` 只说"两臂速率**有**显著差别"、**不说朝哪边**。
旧件在 `p ≤ alpha ∧ 旧件也红` 时**无条件**印 `rate-aggravated`（源码里**没有任何方向判定**）。

修后新增：
```
REGDEC_DIRECTION=A高于B | B高于A | 无显著差      ← 由 p 与两臂**点估计现算**
REGDEC_DIRECTION_LEGEND A=new(被试件) B=old(对照件) new_rate=… old_rate=…
判词按方向选词：上行 ⇒ rate-aggravated（既有口径**逐字保留**）｜下行 ⇒ rate-mitigated ＋「**这不是本波引入**」
显著 ∧ 两臂点估计相等 ⇒ 方向算不出来 ⇒ NOINFO（**不许印任何方向词**）
```

### 2.2 成对现场（同一命令、只换被测件）

命令 = `--old 24/27 --new 0/40 --same-time --old-sha16 feef049e9d0e313a --new-sha16 4e25e4b27d4d5ae1 --pairs 40 --pair-old-only 24 --old-repro yes --planned-legs 40 --planned-power 0.80`

| | 读数 |
|---|---|
| **修前** | `REGDEC_SUBKIND=rate-aggravated`｜`reason=rate-aggravated(fisher_p=3.006e-15≤alpha 且旧件也红 ⇒ …本波把速率**显著加重**…)` ⇒ **印反**（事实 = 旧臂 `24/27 = 88.9%` 红、新臂 `0/40 = 0%` ⇒ **降到 0**） |
| **修后** | `REGDEC_DIRECTION=B高于A`｜`LEGEND … new_rate=0.0000 old_rate=0.8889`｜`REGDEC_SUBKIND=rate-mitigated`｜`reason=…本波把速率**显著降低**…⚠️**这不是本波引入** —— 本波做的是把它**压下去**` |

**上行真例**（`--old 10/40 --new 35/40`）⇒ `REGDEC_DIRECTION=A高于B` ＋ `rate-aggravated` ⇒ **既有口径逐字保留** ✓

### 2.3 自测与台账
`--selftest` **26/26 → 28/28**（既有例**判据文本一字未改**，只增 `DG115-downward-rate-mitigated`／`DG115-upward-rate-aggravated` 两例）。
真台账 `--cases` ⇒ `REGRESSION_LEDGER=PASS rows=9 pass=9 fail=0`。

**⚠️ 与派单措辞的一处分叉（如实记）**：派单写"上行例 `24/27` vs `0/40` 的既有口径**逐字保留**"，但**同一份派单引的 `D-G115` 台账原文**把这个组算作"**判词方向印反**"的现场物 ⇒ 我按**事实方向**落（`B高于A` ⇒ `rate-mitigated`），把"逐字保留"理解为**格式/字段形状**不变（`REGDEC_TABLE`／`REGDEC_FISHER`／`REGDEC_REASON` 的形状与字段一字未动）。

---

## §3 件②：`D-G116` 跨臂体制同一性（新牙）

### 3.1 ★ 范畴订正（**派单的规格错误，主控已裁定采纳车道方案**）
`D-G116` 的字段表原写「`BASE`／最大化几何／**`frame` 几何**／`START_MAX`／`m_ok` 逐项相同」。
**现场 39 腿 / 6 pair 逐腿现算**：

| pair | 臂 | 腿 | **输入侧四列** | `AFTER_R2_SETTLED` 的 `fgeom` |
|---|---|---|---|---|
| **A1** | NEW,OLD | 24 | **逐项相同 ✓** | NEW `800x600@+0+0` vs OLD `1280x1024@+0+0` **不等** |
| **POL2** | NEW,OLD | 3 | **逐项相同 ✓** | 同上 **不等** |
| B1／D1／F1／POL | 单臂 | 3/3/4/2 | 相同 | — |

- **输入侧：0 个不可比**；**若把 `fgeom` 也算体制：2/2 个多臂 pair 全部不可比（100%）**。
- `fgeom` 与 `r_ok2` **39/39 同向**（NEW `800x600 ∧ r_ok2=1`；OLD `1280x1024 ∧ r_ok2=0`）⇒ 它是**动作之后**的读数 ＝ **被测结果**。
  派单引的 `D-G116` 实例 1 里的 `frame=810x634@+0+0` 是**基准时刻的装饰几何**（输入侧），与它**不是同一个量**；现台账**不记录 T0 装饰几何**。
- ⇒ 把结果算进体制，**这条牙会用「保护可比性」的名义否掉唯一真正可比的那对臂**，并在现树恒 `FAIL`。
  **口径句**：**"把结果算进体制，等于用『保护可比性』的名义否掉可比性。"**

### 3.2 落地口径
```
体制列（判用）= BASE ｜ MAXGEOM ｜ START_MAX ｜ m_ok
结果侧（只诊断 REGIME_OUTCOME_DIAG=，**不进 rc**）= after_R geom ｜ r_ok ｜ r_ok2 ｜ fgeom ｜ frame ｜ CFG_HIT ｜ GEOWRITE
PASS/FAIL/NOINFO 三态；判红 = 四件合取 START_MAX=0 ∧ m_ok=1 ∧ r_ok2=0 ∧ APP_ALIVE=yes
APP_ALIVE（声明式派生）= RESULT 行 ∧ AFTER_R2_SETTLED 行 ∧ DONE 行「三条都在」
```
⚠️ **「不进 `rc`」≠「不显示」**：结果侧差异照样逐项上屏（`REGIME_OUTCOME_DIAG`），只是不进 `rc`。

### 3.3 真语料读数
```
REGIME_IDENTITY=PASS reason=ok legs=39 pairs=6 multi_arm_pairs=2 incomparable=0 red=19 red_violations=0 unchecked=1
REGIME_PAIR pair=A1   arms=NEW,OLD legs=24 state=COMPARABLE
REGIME_PAIR pair=POL2 arms=NEW,OLD legs=3  state=COMPARABLE
REGIME_PAIR pair=B1/D1/F1/POL … state=SINGLE-ARM（无可比臂 ⇒ 本件对它不判）
REGIME_OUTCOME_DIAG pair=A1 col=fgeom values=1280x1024@+0+0,800x600@+0+0（结果侧、不得进体制、不进 rc）
REGIME_NOT_IN_LEDGER frame-at-base reason=probe-no-T0-decoration-geom（已知射程缺口）
REGIME_UNCHECKED=1 frame-at-base
```
`--selftest` **12/12**（S1 同体制 PASS／S2 结果侧差异**只作诊断**／S3–S4 换体制 FAIL＋点名＋标不可比／
S5–S6 单格判红与死腿 FAIL／S7 缺列 NOINFO／S8 空台账 NOINFO／S9 无多臂 pair NOINFO／S10 单臂不误判／S11–S12 射程缺口可见）。

---

## §4 件③：`D-G117` 自报抽取器隐去状态（**两半**）

### 4.1 半①：批次形态判词行**置顶**（`prereg-four-requirements-check.sh`）
逐件输出**先缓冲**，末尾把批次判词行印在**最前面**（**位置锚**：主循环 ＋ 汇总行两处）：
```
PREREG4=PASS files=44 pass=1 fail=0 na=5 skip=0 noinfo=0 out_of_scope=38 min_wave=#58（**批次门禁形态的判词**…）
```
**零语义改动**（判定/`rc` 一字未动）。
⚠️ **写这行时我自己踩了一次 `QUOTE-TRAP`**：`echo` 双引号里写了反引号 ⇒ stderr 打 `na: 未找到命令`、行里丢字 ⇒ 已改（现 `SHELL_QUOTE_TRAP=PASS traps=0`）。**主控在 `#60` 给的两条教训，第 ① 条当场兑现。**

### 4.2 半②：抽取器（`verify-all.sh`）——**只治批次形态 = 只治一处症状**
```diff
- grep -E '^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO)( |$)' "$log" | head -12 | sed 's/^/      · 自报口径 /'
+ grep -E '^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO|NA|SKIP|REPORT)( |$)|^[A-Z][A-Z0-9_]*_(SUMMARY|COUNTS|SCOPE) ' "$log" | head -16 | sed 's/^/      · 自报口径 /'
```
- **值词表纳入 `NA|SKIP|REPORT`**（本仓工具今天真会印的状态词）⇒ **下一个新状态**再不会被静默吃掉（加状态＝改这一处，**它有名字了**）。
- **汇总/计数/射程三类行**（`…_SUMMARY`／`…_COUNTS`／`…_SCOPE `）**另开出口** —— 它们**不是**"行首即 `KEY=VALUE`"形态，旧正则全吃不到。
- 显示窗 `12 → 16`：**只放宽显示窗、判定语义零改动**（与 `#31` 那次 `8 → 12` 同口径）。

### 4.3 成对现场 ＋ 阳性对照
| 档 | 读数 |
|---|---|
| 修复前 | 屏上只有 `自报口径 PREREG4=PASS`；`na=4`／`out_of_scope=38` **只在步日志** |
| 修复后 | `[34]` 上屏 8 条：批次判词行（带四态计数）＋ `PREREG4=PASS` ＋ **`PREREG4=NA` ×4** |
| 阳性对照 | 喂「**只有 `NA` 态**」的步 ⇒ `PREREG4=NA` ＋ `PREREG4_SUMMARY …` **都上屏**（否则"看不见"无法区分"没有"与"被吃掉"） |

### 4.4 自报口径窗核对表（预登记 §5 承诺；**冻前 `verify-all` 现测**）
逐步骤匹配行数：`[4]=4 [5]=1 [6]=2 [7]=3 [8..13]=1 [14]=7 [15]=2 [16]=1 [17]=5 [26]=1 [27]=2 [28]=5 [29]=1 [30]=2 [31]=2 [32]=2 [33]=1 [34]=8 [35]=2 [36]=2`
⇒ **最大 8 ＜ 窗 16**，**无步骤触窗**、**总判行全部在窗内**；三类新出口各有实际上屏条数（`PREREG4=` 7、`REGIME_IDENTITY=` 1、`REGIME_RED_COUNTS` 1、`PROCGUARD=` 1 …）。

---

## §5 件④：`known-red.json` 陈旧 `why`

现文写「本波（`#59`）只接线、**不改两件牙**……今天**没有机器读它**」——**与现场为假**：
- `#59` **实测改了牙1**（`geom-revert-beat-check.sh` `9412ec0149111348 → ee43a703736489a3`，见 `#59` 冻结块 §③）；
- **该牙就是本键的读者** —— 实际读点 = `geom-revert-beat-check.sh` 里读 `known-red.json` 的 `generation.geom_corpus.sha256` 那一句（现场 `grep -n` = **`:283`**；该件本波未改、该句唯一 ⇒ 此号可引；派单引的 `:273` 是它的文档串 `:274` 附近）。
- 另一件牙 `geom-resend-regression-check.sh` 现场 `grep` = **0 命中**（它不读本键）。

改法：**旧文逐字留档（加注不覆盖）** ＋ 更正结论「**本键有机器读者；纪律 47 那条缺口在 `#59` 落地时即已闭合**」
＋ `repin-generation.py --why` 重钉 ⇒ `REPIN_GENERATION=PASS`（`--check` 前后都 PASS），
且**世代三项／五臂／证据日志／`geom_corpus.sha256` 逐位未变**（只错在散文）。

---

## §6 接线（`verify-all.sh` 35 → 36 步）

第 `[36]` 步 `REGIME-IDENTITY`。**四处声明同趟、插入全用位置锚**（解析首个 `^#\s*VERIFYALL-STEPS-DECL:\s*(\d+)\s+gen=(#\d+)`
＋ **先断言 `DECL 数 == grep -c '^run_step "'`** 再插）：
`DECL` 首行 `36 gen=#63`／`STEP-NAMES` 尾加／口径句逐字 ``**`#63` 收官起 = 36 步**``／新建 `docs/WAVE63-PREREGISTRATION.md`（H1 含字面 `#63`）。
⇒ `VERIFYALL_SELF=PASS names=36 decl=36 gen=#63 dup=0 order=OK prose=OK prereg=PASS`。

---

## §7 成对记账（承重）：`inputs_fp` 覆盖面 158 → 159

**改 4 件／新增 1 件**：`regression-decision.py`｜`regression-decision-cases.tsv`｜`known-red.json`｜
`close-wave.sh`（**名单变更的载体 ⇒ 自含**）＋ **新牙** `regime-identity-check.sh`（入名单，与 `#62` 加 `proc-pattern-guard.sh` 同形存量惯例）。

**交叉表（16 行，全部互不相同；每行 `hits` = 实际被替换/删除的行数）** —— 摘要：

| 组合 | hits | 指纹（前 32） |
|---|---|---|
| `py=NEW tsv=NEW krj=NEW cw=NEW`（**现盘**） | 0 | `7836c5fa17cd454893f9a4101fe22101…` |
| `py=OLD tsv=OLD krj=OLD cw=OLD`（**全退**，含删新牙行） | **5** | `1ffd13f7c927dea71fd5dca866f7c6f8…` |

- **全退 ⇒ `1ffd13f7c927dea71fd5dca866f7c6f81e8efce9939c22c85d55c0a35fb20f96` ＝ `#62` 声明值（派单给的 `prev_infp`）逐位相同** ✓
  ⇒ 位移 **100% 归因**于上面这 4 改 1 增。
- **现盘 ⇒ `7836c5fa17cd454893f9a4101fe2210181217f035c306122cbbed259293a772f` ＝ `infp.sh fp` 真函数实测** ✓
- ⚠️ **本波现场栽过一次"静默 no-op"**：交叉表第一版把**绝对路径**与清单里的**相对路径**比 ⇒ **一行都没匹配上** ⇒ **8 档全部同值** ＝ 假"无位移"。**改法 = 逐档断言 `hits`**（现 0/1/2/3/4 逐档正确）后才成立。
  ⇒ 与我在 `#60` 落册的"**对拍/解析在任一侧为空时必须响亮失败**"**同族**，本波升格为：**"替换/撤销类脚本必须断言命中行数"**。
- `regime-identity-check.sh` **不在** `fp_inputs()` 原名单 → 本波**同趟纳入**（新牙在 `verify-all` 里判 ⇒ 它的字节必须被指纹看得见）。
- ⚠️ **本波的一处自伤（如实）**：我第一次取「改前快照」时，`cp -p ... known-red.json.before63` 是在**改 `why` 那一句之后**执行的
  ⇒ 该快照 = `cc0dd903972d7f73`，是个**中间态／混合态**（现场复核：它**含新文**『本键有机器读者』、**不含旧文**『本键是「声明锚」』），
  **不是** `#62` 冻后态 ⇒ **真回滚会回到混合态**。
  ⇒ 交叉表**没有**踩这个坑：它用的是 `git cat-file blob HEAD:<path>`（`HEAD` = `#62` 冻后态 = `b3f264bbf43dbd61`），**不是**我的备份件。
  **订正后的口径**：凡「改前值」一律取 **`HEAD:` 的 blob**（或冻结块原文），并在同一行**注明取数来源**；
  备份件只用于「回滚现场文件」，**不许**当「改前真值」的声明源。

---

## §8 整波／门禁／冻前／冻结

| 环节 | 读数 |
|---|---|
| 整波 | `HEAVYSLOT=RELEASED rc=0 held=255s`；`[1/6] rc=0`；`[2/6]`/`[3/6]` 跳过重建；`[4/6]` 桥源两侧一致 `d697b1e10ff48881`、应用器审计 `miss=0`、**输入稳定性 波前==波后 == `7836c5fa…`**；`APPSYNC 非 PASS`（继承 `#59`–`#62`） |
| 九位 | **只有 `pf` 动**：`3c808e94034c4514` → **`9bf76afe89944ccc`**（**同尺寸 6,123,520 B** ⇒ 环成员 `D-G92`）；其余八位逐位与 `PRE` 相同 |
| 门禁 ×2 | 两趟 `TLINE_GATE=PASS … saved_shim=921ba9c65e9fb3be gate=747c078dbf040862 judge=t1b3-tline-gate/7`，`RC1=RC2=0`，**判词行逐字一致** |
| 应用级门禁 ×2 | 两趟 `rc=0`、`rows=6/6`、`WPTD_GATE=PASS acceptance=2/2`、`WPTD_SUMMARY=PASS tiers_passed=2/2`；**逐字一致**（先断言两侧非空） |
| 冻前 `verify-all` | **`36 ✅ / 0 ❌`**、`rc=0`、`结论：✅ 全部通过`、`用例通过 875 跳过 2`；**声明类红项 = `[]`（全绿）** |
| 冻结 | `FREEZE_RC=0`｜`gen=#63 sha16=4ee96c043b472c11`｜**`BASELINE_BYTES=919687`**（上代 `#62` = `845219762aa61fb8`／903,901 B） |
| 四牙 | `BASELINESHA=PASS live=4ee96c043b472c11 decl=4ee96c043b472c11`｜`BASELINEGEN=PASS decl_gen=#63`｜`BASELINEDUP=PASS n=0`｜`ARMLOG_SHA=PASS required=5 declared=5 pass=5 fail=0`｜`COLUMN_FLOOR=PASS pass=3 fail=0 selfreport=PASS reg=2209966ee1d2c5cc base=4ee96c043b472c11 corpus=0cebc0afd5142fbf` |

⚠️ **一处行号更正（结论对、但「引行号」这件事本身错了 —— 主控裁定为纪律 31）**：`w63-pre.sha` 要对齐的九位声明行，
派单写 `:13`、`#61` 那代 W153A 写 `:13`、我现场读到 `:15` —— **三个数都对不上不是谁错了**：该句在基线里**随世代重写**、
且**同句多处出现**（现盘 `grep -n '九位（Release 权威件）'` ⇒ **`:14` 与 `:77` 两处，加上各历史块共 7 处**）
⇒ **行号天生不稳、也不唯一**。**订正口径 = 内容锚**；我对 `PRE` 的抽取**本来就是按内容**
（`九位（Release 权威件）` 那一行的**第一个**匹配 ＋ 逐键正则取 16 位）⇒ **`PRE` 与 `#62` 冻结块 9/9 相同不受影响** ✓。
**落册**：凡「随世代重写或同句多处出现」的件，**禁止引用绝对行号**；一律引内容锚，或现场 `grep -n` 取数并**同时声明取数时刻**。

---

## §9 我推翻／更正的

1. **`D-G116` 的字段表（派单规格错误）**：把 `AFTER_R2_SETTLED` 的 `fgeom`（**结果侧**）列进体制 ⇒ 会让 **A1／POL2 全对不可比**、新步恒红。**主控已裁定采纳车道方案**并改册。
2. **`D-G115` 的"上行例"措辞**：`24/27 vs 0/40` 是**下行**现场物 ⇒ 按事实方向落（见 §2.3）。
3. **`known-red.json` 读者行号**：派单写 `:273`，现场实际读点 **`:283`**（`:274` 是文档串）。
4. **`w63-pre.sha` 对齐行**：派单写 `:13`，实际 **`:15`**。
5. **闸③ 自我排除漏排 `$$`**（§0.1）—— `TASK-0714` 纪律的第 2 个活样本。
6. **`PIPEFAIL-SIGPIPE` 第 5 次咬人**：我新牙里 `printf … | grep -qE` 两处 ⇒ `undeclared_hit=2`。
   修法有坑：**`[[ "$out" =~ $pat ]]` 是整串匹配**（`^`/`$` 只在整串首尾生效）⇒ 多行里 `^REGIME_IDENTITY=PASS` 永远匹配不到（**自测当场抓到 2 例**）⇒ 必须**逐行** ＋ here-string（零管道）。
7. **`QUOTE-TRAP` 咬了我一次**（§4.1）。
8. **交叉表第一版静默匹配 0 行**（§7）。
9. **「改前快照」取在第一次写之后**（§7 自伤）⇒ 备份件是**混合态**、不是 `#62` 真值。
10. **引绝对行号本身**（`:13`/`:15`）在随世代重写、同句多处出现的件上**不成立** ⇒ 改内容锚（§8）。

---

## §10 `NOINFO` 清单（照录，不许缩小）

1. 新牙**只判可比性**：不重判 `GEOM-BEAT`/`GEOM-RESEND` 的结论、不测当前桥件、**不**主张"体制同一 ⇒ 结论正确"。
2. **`frame-at-base`（T0 装饰几何）未查**：现台账不记录 ⇒ `REGIME_NOT_IN_LEDGER` ＋ `REGIME_UNCHECKED=1`（**不冒充"装饰也查过了"**）。
3. **单臂 pair 不判**（`B1`/`D1`/`F1`/`POL`）⇒ 逐条 `SINGLE-ARM`。
4. `APP_ALIVE` 是**声明式派生**（三行都在），**不是**对进程的直接观测。
5. `D-G117` 的**显示窗仍有限**（16 行）⇒ 单步骤匹配行数若超窗仍可能截「总判」（本波实测最大 8 ⇒ 未触窗，但**边界是真的**）。
6. `D-G115` 只改**判词**：`state`/`rc`/FISHER 表语义未动；**不判**"这个差是不是本波引入的"（那要机制）。
7. 不给探针加 T0 装饰几何记录（建议后续波）。
8. 不动 `docs/ROUTES.md`／`KNOWN-DEFECTS.md`／`defect-registry-declared.tsv`／`HANDOFF-NEXT.md`（主控写域）；不动臂、不动冻结语料。

---

## §11 冻后 ×2 ＋ 放行标记

```
空盘预检  df: /dev/sda2 187G 用 147G 可用 31G (83%)
post1  13:50:36→14:05:06  slot_rc=0  步骤通过 36 ❌ 失败 0 ｜ 用例通过 875 跳过 2 ｜ 结论：✅ 全部通过 ｜「设备上没有空间」命中=0
post2  14:05:06→14:19:23  slot_rc=0  步骤通过 36 ❌ 失败 0 ｜ 用例通过 875 跳过 2 ｜ 结论：✅ 全部通过 ｜「设备上没有空间」命中=0
```
- **步判词行（37 行 = 36 步 ＋ 结论行）三趟（冻前/post1/post2）逐字一致**；
  ⚠️ 抽取**先断言行数 == 37**（我在 `#60` 栽过"空集恒相等 ⇒ `diff` 假报 IDENTICAL"，本波把该断言写进流程）。
- **不参与合格线、但必须点名的仪器漂移**（两趟互不相同）：`FRAMEPRESENCE magenta_frames 38/40`｜
  `THIRDPARTY frames 43/…`｜`R_GATE mem_mb`（两趟不同值）。
- **`NOFILE_SWAP` 证据**：两趟 `saved_shim=921ba9c65e9fb3be` 相同、`BASELINESHA=PASS live=4ee96c043b472c11` 相同。
- **放行标记**：`touch ~/w21-verify/w63-POST.done` ⇒ **真 `stat` mtime = `2026-09-24 14:19:54.616048853 +0800`**、0 B（`#64` 的入口信号）。

## §12 交付：推送／app-local／哨兵（**待追加**）
