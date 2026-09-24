# W152A 报告（波 `#60`：仪器波 · 装置/判据欠账批 A）

车道 **W152A**｜仓 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**不是 git 仓**）
基线上代 `#59` = `02f80e388d308c4d`／846,233 B｜判据 `~/w152a/criteria.md`（**判据先写**）
本报告 **APPEND_ONLY**（逐段追加，不覆盖既有段落）。

---

## §0 开工闸（四条 ＋ **"排除自身"的口径**）

| # | 判据 | 现场值 | 判 |
|---|---|---|---|
| ① | `sed -n '9p' $R/docs/CURRENT-STATE.md` | `BASELINE-FROZEN gen=#59 sha16=02f80e388d308c4d …` | ✓ |
| ② | `~/w21-verify/w59-POST.done` | mtime `2026-09-24 04:29:47` | ✓ |
| ③ | 现场无收尾/构建链在跑 | 见下 | ✓ |
| ④ | `flock -n ~/heavy.lock -c 'echo FREE'` | `FREE` | ✓ |

**③ 的"排除自身"口径（本波留档，供 `TASK-0714` 当样本）**：
逐 pid 读 `/proc/<pid>/cmdline`，**显式排除 `$$`／`$PPID` 及其祖孙链**（沿 `/proc/<pid>/stat` 的 ppid 上溯到 `1`）。
**实测事故（真发生）**：不改口径时，我自己那条 `bash -c '… wpf-linux …'` 的命令行**命中了扫描模式**
（PID=3098942）⇒ 若照此停手就是**误停**。⇒ **判"有链在跑"必须有非自身的证据。**
本波用的两条非自身证据：① 无任何 `dotnet`／`msbuild` 进程；② `~/heavy.lock` 无持有者。

---

## §1 本波三件（落地清单）

| 件 | 入口件 | 修前 → 修后 |
|---|---|---|
| A `TASK-0709` | `build/MilBridge/tools/prereg-four-requirements-check.sh` | `b436ae561ae1f396`（319 行）→ **`235d76b61cdc46a4`**（443 行） |
| B `TASK-0713` | `build/MilBridge/tools/shell-quote-trap-check.sh` | `e5d4cf05ef5fc2ea`（840 行）→ **`d4317aa7605a31e1`**（907 行） |
| C `D-G114` | 同上（与 B 同件） | 同上 |
| 接线 | `verify-all.sh` | `ec29c571be6b19da`（1103 行／`run_step=33`）→ **`970bb48ba8ebd384`**（1114 行／`run_step=34`） |
| 预登记 | `docs/WAVE60-PREREGISTRATION.md` | **新建**（H1 含 `#60`） |

全部 `temp ＋ rename`；落前 `cp -p` 备份到 `~/w152a/backups/`；**前后 sha 双断言**（暂存件 sha == 已测 sha，且落盘后 sha == 暂存 sha）。

---

## §2 件 A（`TASK-0709`）：`N/A` 语义 ＋ 接线 `[34]`

### 2.1 新增 `PREREG4=NA`（`rc=0`）

**充要两条**：① **判据节内**逐字有「本波 … 不做任何回归判定」（或机读行 `PREREG-NO-REGRESSION-DECISION:`）；
② **全文无回归判定证据**（判定工件自己印的机读判词行／回归判定台账文件名）。
⇒ 四要件**对本波不适用**，**与 `PASS` 分开计数**（`--glob` 汇总新增独立一格 `na=`）＋ 逐件点名 `PREREG4_NA …`。

- **缺声明** ⇒ 走正常路径（该 `FAIL` 就 `FAIL`）。
- **留声明却引用了证据** ⇒ **仍 `FAIL`**（声明**不许**当免死金牌）。
- **格式声明不算证据**：`PREREG-REGRESSION-FOUR:` 那一行只是格式承诺 —— `docs/WAVE59-PREREGISTRATION.md:47-50`
  **自己逐字写着**「**是"这一刻不适用"的声明，不是"我已经做过"的声明**。**不许**把本节读成本波做过四要件。」
  ⇒ 若把那一行算成证据，`#59` 仍会被逼着抄四要件 ＝ **正是本任务要治的病**。

### 2.2 `--selftest` 12/12 → **18/18**（既有 12 例**逐字未变**，只增 6 例）

```
SELFTEST NA-1-declared-no-rd            want_rc=0 got_rc=0 = OK
SELFTEST NA-2-decl-removed-fails        want_rc=1 got_rc=1 = OK
SELFTEST NA-3-decl-plus-evidence-fails  want_rc=1 got_rc=1 = OK
SELFTEST NA-4-wave58-stays-pass         want_rc=0 got_rc=0 = OK
SELFTEST NA-5-gate-batch-form           rc=0 ＋ 出射程件逐件点名 ＋ out_of_scope 计数 = OK
SELFTEST NA-6-gate-batch-fails-when-broken rc=1 = OK
PREREG4_SELFTEST=PASS total=18 pass=18 fail=0
```

### 2.3 真实件读数（`--glob docs/WAVE*-PREREGISTRATION.md`，41 件）

| 形态 | 读数 | rc |
|---|---|---|
| 逐件形态 | `files=41 pass=1(W58) fail=0 na=2(W59,W60) skip=38 noinfo=0 out_of_scope=0` | `3`（`SKIP` 语义**一字未动**） |
| **批次门禁形态 `--gate`**（接线用） | `files=41 pass=1 fail=0 na=2 skip=0 noinfo=0 out_of_scope=38` | **`0`** |

**`WAVE58` 仍 `PASS 4/4`**（**不许**被降级成 `NA` ✓）｜**`WAVE59` `PASS → NA`**（**设计性位移**，逐件记账）｜
**`WAVE60` `NA`**。stderr **0 字节**（见 §3 的 `:313` 真陷阱）。

### 2.4 为什么接线必须走 `--gate`（**不是放宽**）

`verify-all.sh` 的 `run_step` 把**任何 `rc≠0`** 判 `❌`，而逐件形态下「波次早于生效边界 ⇒ `SKIP` ⇒ `rc=3`」
⇒ 裸 `--glob` **每趟都会多一个 ❌**、门禁**永远接不上**。批次形态下那些件**不判但逐件点名**
（`PREREG4_OUT-OF-SCOPE` ＋ `out_of_scope=`，**永不静默**），批次 `rc` 只由**违规**与**查不动**决定
（`fail>0 ⇒ 1`／`noinfo>0 ⇒ 3`），`na`／`out_of_scope` 是**适用性/射程**声明、**不进 `rc`**。
**理由**：射程边界 `REQ_EFFECTIVE_WAVE=58` 是**版本受控的常量**，`<#58` 的件按"只加不改"**永远**出射程
⇒ 该集合**永不增长、永不包含当前波**；它与 `NOINFO`（查不动）不是一回事。
把 `SKIP` 也算进批次 `rc` ⇒ 批次**永不为 0** ⇒ 只会把人推向"**吞掉 rc**"（**真**假绿，比这个洞更坏）。
**逐件形态的 `SKIP ⇒ rc=3` 一字未动**（W151A 的读法逐位保留）。
**被否决的备选**：只判当波那一份（射程 → 1 件，明显更弱）。

---

## §3 件 B（`TASK-0713`）＋ 件 C（`D-G114`）：同一颗牙

### 3.1 件 B：`*/bin/*` **静默出射程**（成对实测）

| 输入 | 修前 | 修后 |
|---|---|---|
| **同一颗真陷阱**放 `*/bin/*` | `PASS traps=0`（**静默出射程 ＝ 假绿方向**） | **`FAIL traps=2` 逐条点名** |
| **同一份样本**挪到 `build/MilBridge/tools/` | `FAIL traps=2` | `FAIL traps=2`（成对对照） |
| `*/bin/*` 下的**干净**件 | `PASS` | `PASS traps=0`（不许因为"扫了 bin"就多红） |

修法 = **`bin/` 纳入扫描**（真判）＋ 每次跑印射程行：

```
QUOTE_TRAP_SCOPE root=… files=161 sh=76 py=85 included=*.sh,*.py bin=INCLUDED excluded=upstream:1 obj:0 .artifacts:0 __pycache__:0
```

⇒ **"没扫什么"永不许静默**（`upstream/` 刻意保留排除**并点名**）。
今天实测全树 `*/bin/*` 下的 `*.sh|*.py` = **0 件** ⇒ **读数零位移**（`files=161` 不变）；它治的是**将来**有件落进 `bin/` 时"牙看不见"。

### 3.2 件 C：`D-G114` 帧栈泄漏（**一行无关代码把整份文件的判据降级成诊断**）

**机制（定到行）**：`shell-quote-trap-check.sh:325` 的 N 态 `#` 判注释条件把 `{` 放进字符类
（`p ~ /[;|&(){}<>]/`）⇒ `${#arr[@]}` 的 `#` 因**前一字符是 `{`** 被判成"注释"⇒ `return` 到行末
⇒ `${`（`:280` 压 `b` 帧）**永远等不到 `}`**（`:301` 只有 `}` 能弹）⇒ **帧顶永久滞留 `b`**
⇒ 此后该文件**任何**双引号内裸反引号都走 `:291` 的 `emit("DIAG","DQ-BRACE-BACKTICK")` ⇒ **不进 `rc`**。

**现场实物** = `prereg-four-requirements-check.sh:313`（本波正要改的那件）的汇总 `echo` 双引号里写了反引号包着的 `SKIP`：
```
prereg-four-requirements-check.sh: 行 313: SKIP: 未找到命令      ← stderr（每趟）
PREREG4_SUMMARY … （**四态分开计数**： 超出射程 ≠ 通过 ≠ 违规）    ← 那几个字消失
```
（与该牙自己记录的第 ③ 条血案同形。）**基线 `traps=0` 是假绿。**

**两极化**（同一颗陷阱、只挪一行无关代码）：

| 输入 | 读数 |
|---|---|
| 沙箱件 A：真陷阱，**无** `${#…}` 前置 | `FAIL traps=2` |
| 沙箱件 B：**同一颗陷阱**，前面只多一行 `if [[ ${#arr[@]} -gt 0 ]]` | 旧件 **`PASS traps=0`**（假绿）｜新件 `FAIL traps=2` |

**全树量化（用 `$HOME` 补丁副本 `--root $R`，同 161 件口径）**：`traps 0→2`（两条**全指向** `:313` 那处真陷阱）、
`diag 73→71`、`--selftest` 仍 **30/30** ⇒ **只增红、零假红**（实测，非推测）。

**成对归因（同一颗新牙、只换 prereg4 一件）**：
```
修前件 ⇒ SHELL_QUOTE_TRAP=FAIL reason=dq-backtick traps=2（:313 col=147/152）
修后件 ⇒ SHELL_QUOTE_TRAP=PASS reason=ok traps=0
```
**终态全树**：`SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=161 sh=76 py=85 diag=71 allow=0`、`rc=0`。

修法 = `:325` 加 `topk() != "b"` 前置（**只修"帧顶错成 `b`"**；"**真的**在 `${ … }` 里"那一档**仍只诊断**、语义未动）
＋ 把 `:313` 那处**真陷阱**改掉。`--selftest` **30/30 → 35/35**（新增 `S30`–`S34`，**只增不减**）。

### 3.3 射程（受影响件）

全树 **12 件**含 `${#…}`：`verify-all.sh`／`tools/{prereg-four-requirements-check,r-gate-step,arm-log-sha-check,
baseline-sha-check,build-hygiene-import-check,sync-applocal}.sh`／`wic-shim/check-applocal-sync.sh`／
`FallbackCriteria/run-df1-criteria.sh`／`RGateClickProbe/run-r-gate-legs.sh`／`run-wpftextdemo.sh`
⇒ **这 12 件此后若藏真陷阱，旧牙一律看不见**（这就是 `D-G114` 的射程）。

---

## §4 接线 `verify-all.sh`（33 → 34 步）

**四处声明同趟改，插入一律用位置锚**（解析首个 `^#\s*VERIFYALL-STEPS-DECL:\s*(\d+)\s+gen=(#\d+)`
＋ **先断言 `DECL 数 == grep -c '^run_step "'`** 再插；**不照抄上一代文本**）：

1. `VERIFYALL-STEPS-DECL` 首行 → `34 gen=#60`（**插在最上面**：读者 `decl_line()` 取 `head -1`）
2. `VERIFYALL-STEP-NAMES` 尾加 `| PREREG-FOUR-REQ`
3. 头注释逐字 `**\`#60\` 收官起 = 34 步**`（冻结器 `grep -qF` **逐字**找）
4. 新建 `docs/WAVE60-PREREGISTRATION.md`（标题行含 `#60`）

新步原文：
```
echo "[34] 预登记四要件（判据节里四要件在不在；不做回归判定的波按 --gate 标 N/A；只读、零 dotnet、秒级；#60 加）"
run_step "PREREG-FOUR-REQ" bash build/MilBridge/tools/prereg-four-requirements-check.sh --gate --glob 'docs/WAVE*-PREREGISTRATION.md'
```
**检查器**：`VERIFYALL_SELF=PASS names=34 decl=34 gen=#60 dup=0 order=OK prose=OK prereg=PASS`。

---

## §5 整波（`close-wave.sh --skip-verify-all`，槽内）

```
HEAVYSLOT=ACQUIRED waited=0s cmd=bash build/close-wave.sh --skip-verify-all
HEAVYSLOT=MEMOK avail=4525MB min_avail=1500MB
[0/6] ✅ 无应用进程、无重发锁   波前输入指纹 = 5390d01e4040b5c33fd3064caac5910821aeb89850e63a92696ec7c78d43b69c
     计划：native 重建=否｜桥重发=否（现树 fp=d697b1e10ff48881 记录=d697b1e10ff48881）｜verify-all=跳过
[1/6] integration-wave.sh  rc=0
[2/6] native shim：源码不比权威件新 ⇒ 跳过重建｜d2b76a0a56a41be1
[3/6] 桥：源指纹一致 ⇒ 无需重发
[4/6] ✅ 桥源指纹两侧一致｜✅ 生成物指纹 state=ok（PC/WB/PF）｜⚠️ APPSYNC 非 PASS（继承自上一代）
     ✅ 应用器审计 miss=0｜✅ 输入稳定性：波前==波后 == 5390d01e…（期间无手写改动）
[5/6] verify-all：按要求跳过
HEAVYSLOT=RELEASED rc=0 held=192s
```

**九位位移 = 实测只有 `pf`**（`70f5fd87457ca0f3` → **`a1fbf721ae964f8e`**，**同尺寸 6,123,520 B** ⇒ 环成员 `D-G92` 机械位移）；
其余**八位逐位与 `PRE` 相同** ✓ 与预期一致。

### 5.1 `inputs_fp` 两笔 ＋ **机械归因**

```
#59 声明值            e7b94e10171b55e1786a63c30a8da568ba24da62228bfb3903eb4f46e3f9a398
本波波前/波后（真跑）  5390d01e4040b5c33fd3064caac5910821aeb89850e63a92696ec7c78d43b69c   ← [0/6] 与 [4/6] 逐位相同
归因反证（只把逐件清单里 quote-trap 那一行换回修前 sha） ⇒ e7b94e10…（**逐位回到 #59 声明值**）
```
⇒ **位移 100% 归因于 `build/MilBridge/tools/shell-quote-trap-check.sh` 一件**（覆盖面 157 件里恰好 1 件）。

⚠️ **推翻派单的一处预期（如实记）**：派单说"`verify-all.sh` 与 `prereg-four-requirements-check.sh` 也在 `fp_inputs()` 白名单内"
—— **现场 `grep` 反证：两件都不在**（`verify-all.sh` 的 4 处命中**全在注释里**；`prereg-…` 命中 **0**）。

### 5.2 五臂／重钉

**本波不改 `GEN_KEYS`**（不动 `build/MilBridge/run.sh`／`HbTextLineParity/Program.cs`／`build/shims/PresentationCore.HbTextLine.cs`）
⇒ **五臂不重取**，现场现算 **5/5 与 `#59` 逐位相同**；**`known-red.json` 本波未改** ⇒ **不需要** `repin-generation.py`。

---

## §6 门禁 ×2（槽内、严格串行）

```
RUN 1  TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 \
        caliber=OK generation=#23 tree_gen=same saved_shim=921ba9c65e9fb3be gate=747c078dbf040862 judge=t1b3-tline-gate/7   RC1=0
RUN 2  （逐字同上）                                                                                                      RC2=0
```
**判词行逐字一致** ✓（两趟落在同一秒 ⇒ `outdir=` 也相同；该项**本不参与合格线**，此处恰好相同 ⇒ 点名）。

---

## §7 `NOINFO` 清单（照录，不许缩小）

1. 件 A **判不了**"四要件**内容为真**"（只判"文档里在不在"）。
2. 件 A **判不了**"声明是否诚实"（声明"不做判定"却偷偷做了 ⇒ 除非留下判定工件的机读判词行）。
3. 件 A 的**证据界定是子串匹配**（全文）⇒ 一个波**仅仅在散文里提到**那些名字也会被判成"有证据"
   ＝ **假红方向**（可见、可改写法），**不是**假绿 —— 本波按"宁可假红"保留。
   **本波预登记自己就踩过这一格**：初稿 §2.1／§3／§5 逐字复现了那两个串 ⇒ 牙当场把它判成
   `有证据`（本该 `NA` 却会走 `FAIL`）⇒ 已改写措辞（用「判定工件自己印的机读判词行」指代）
   ＋ 把这条**登记成射程边界**，而不是悄悄放宽检测。
4. 件 B／C **只证**"该红处会红"；**不证**本仓今后不会出现别的帧配对形态。
5. 第 `[34]` 步**只判文档层**：不读产品件、不跑臂、不碰冻结语料。
6. `--min-wave` 仍是**仅覆盖口**（只许抬高射程起点，禁止用来放低边界换取好过）。

---

## §8 我推翻／更正的

1. **派单的 `fp_inputs` 覆盖面预期**（§5.1）：`verify-all.sh` 与 `prereg-four-requirements-check.sh` **都不在白名单内**。
2. **派单把 `TASK-0713` 的现场描述成 `scan-empty`** —— 实测**不是** `scan-empty`（扫描集非空，17 件），
   而是**静默出射程**：真陷阱放 `bin/` ⇒ `PASS traps=0`。**比派单描述的更隐蔽**。
3. **我自己引入的 `[17] PIPEFAIL-SIGPIPE` 红**（`undeclared_hit=1`）：我按 `HANDOFF-NEXT.md` 第 21 条
   把 `printf … | grep -q` 改成 `[[ =~ ]]`／`==` 子串（并实测 `=~` 的 `.` **跨行匹配**，语义与原来一致）。
   ⇒ 该族**第 4 次咬人**。
4. **`w152a` 预登记初稿触发自己的证据检测**（§7 第 3 条）。

---

---

## §9 冻前 → 冻结 → 冻后（实测，逐条）

### 9.1 冻前 `verify-all`（槽内）

```
[0] ✅ X-REUSE=reused display=:99 ｜ X_STATE=available
步骤通过 34  ❌ 失败 0 ｜ 用例通过 875  跳过 2 ｜ 结论：✅ 全部通过 ｜ rc=0
```
**声明类红项 = `[]`（全绿）** —— 本波不动臂、不改 `GEN_KEYS`、不改 `known-red.json` ⇒ 与主控的**条件式预期**一致。
**新增第 `[34]` 步 `PREREG-FOUR-REQ` 首跑即 ✅**；`QUOTE-TRAP`／`PIPEFAIL-SIGPIPE`／`VERIFYALL-SELF`／
`BASELINE-SHA`／`ARM-LOG-SHA`／`COLUMN-FLOOR`／`DEFECT-REGISTRY` **全部 ✅**。

### 9.2 应用级门禁 ×2（6 行矩阵，喂冻结器）

```
PASS 1  rc=0  rows=6  WPTD_SUMMARY=PASS tiers_passed=2/2  WPTD_GATE=PASS acceptance=2/2 line_advance=PASS
PASS 2  rc=0  rows=6  WPTD_SUMMARY=PASS tiers_passed=2/2  WPTD_GATE=PASS acceptance=2/2 line_advance=PASS
```
- 矩阵 = `tier=default rep=1..3` ＋ `tier=env rep=1..3`（**6/6 行 `result=PASS`**）
- **两趟判词行逐字一致**（剥 `rundir=` 后 `diff` = 0）
- 配置 = `pc:722e0ab8205b7c3f,pf:a1fbf721ae964f8e`（= 波后现场九位）

### 9.3 冻结 `#60`

```
FREEZE_RC=0
BASELINE-FROZEN gen=#60 sha16=da24cb43d2123612 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
BASELINE_BYTES=864300        （上代 #59 = 02f80e388d308c4d／846,233 B）
四牙：BASELINESHA=PASS live=da24cb43d2123612 decl=da24cb43d2123612
      BASELINEGEN=PASS decl_gen=#60 ｜ BASELINEDUP=PASS n=0
      ARMLOG_SHA=PASS required=5 declared=5 pass=5 fail=0
      COLUMN_FLOOR=PASS pass=3 fail=0 selfreport=PASS reg=b3f264bbf43dbd61 base=da24cb43d2123612
世代交叉断言：树上 #59 == GENS[#60][prev]
牙齿②：^run_step " = 34 == 步数 34，且头注释逐字声明了同一数字
```
九位终态：位移**只有** `pf`（`70f5fd87457ca0f3 → a1fbf721ae964f8e`，同尺寸 6,123,520 B）。

### 9.4 冻后 ×2（槽内、严格串行、空盘预检）

```
空盘预检  df: /dev/sda2 187G 用 132G 可用 47G (74%)
post1  10:11:50→10:27:02  slot_rc=0  步骤通过 34 ❌ 失败 0 ｜ 用例通过 875 跳过 2 ｜ 结论：✅ 全部通过 ｜ VERIFYALL_RC=0 ｜「设备上没有空间」命中=0
post2  10:27:02→10:42:03  slot_rc=0  步骤通过 34 ❌ 失败 0 ｜ 用例通过 875 跳过 2 ｜ 结论：✅ 全部通过 ｜ VERIFYALL_RC=0 ｜「设备上没有空间」命中=0
```
- **两趟步判词行（34 行 ＋ 结论行）逐字一致**；**冻前 vs 冻后也逐字一致**
  （⚠️ 我第一版抽取脚本用了非法字符类 ⇒ 两个文件都**空** ⇒ `diff` **假报 IDENTICAL**；已改用
  `awk '/^  [^ ]/ && (/✅/ || /❌/)'` 重取，**35 行**才是真读数。**"空集恒相等"是判据陷阱**，留档。）
- **不参与合格线、但必须点名的仪器漂移**（两趟各不相同，逐项点名）：
  `FRAMEPRESENCE frames=80/79` ＋ `dir=…-102324/-103838`｜`THIRDPARTY frames=41/42` ＋ `dir=…-102540/-104050`｜
  `R_GATE mem_mb=4009/4298`。（`px_open/px_closed/win/win32shim/pc` 两趟**相同**。）
- **`NOFILE_SWAP` 证据**：两趟 `saved_shim=921ba9c65e9fb3be` 相同、`BASELINESHA=PASS live=da24cb43d2123612` 相同。

### 9.5 放行标记

`touch ~/w21-verify/w60-POST.done` ⇒ mtime **`2026-09-24 10:43:04`**、0 B（**唯一**放行信号，`#61` 的入口）。

### 9.6 ⚠️ 一处**主控需知**的表面缺口（我**没有**擅自改，因为改了要重跑冻后 ×2）

`verify-all.sh:355` 的「自报口径」抽取器 = `grep -E '^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO)( |$)' | head -12`：

- 我这条步的**逐件判词行**里，只有 `PREREG4=PASS`（`WAVE58`）匹配该正则；
  `PREREG4=NA` **不匹配**（`NA` 不在那个择一表里）、`PREREG4_OUT-OF-SCOPE …`／`PREREG4_SUMMARY …` **也不匹配**
  （它们不是 `行首即 KEY=VALUE` 形态）。
- ⇒ 屏上只见 `自报口径 PREREG4=PASS`，而**四态计数（`pass=1 fail=0 na=2 out_of_scope=38`）没有上屏**
  （它们**在步日志里**，`head -12` 只是没抽到）。
- **建议（留给主控裁定）**：批次形态下**在最前面**多印一行
  `PREREG4=<批次判词> files=… pass=… fail=… na=… noinfo=… out_of_scope=…` —— 它**逐字匹配**上面那个正则
  ⇒ 屏上立刻带上四态计数，**不需要**动 `verify-all.sh` 的抽取器、也**不改**任何判定语义。
  **本波不擅自改**：改它就得重跑冻后 ×2 才配得上"冻后读数"这句话。

---


---

---

## §10 ⑧ 推送／app-local／哨兵（实测）

### 10.1 推送（逐径 `git add`，**绝不** `git add -A`）

```
远端实况（ls-remote；⚠️ **不用**陈旧跟踪引用 origin/feat-Linux —— 它停在 636a3e7）：
  推送前 remote = 32eaaf06f53c6215ef0bc92c24cb643afaad1667 == local ⇒ ✅ 快进（**无 --force**）
  推送     32eaaf0..332d503  feat-Linux -> feat-Linux
  推送后 remote head = 332d5032472c899d2e846cad1e53e172e604bdf3（== local HEAD）
  远端默认分支：ref: refs/heads/feat-Linux	HEAD  ⇒ **仍是 feat-Linux**（只读它，未改设置）
commit 变更件数 = 8（porcelain 计数 = 8，全部显式列入白名单）
```

白名单 8 件：`verify-all.sh`／`build/MilBridge/tools/shell-quote-trap-check.sh`／
`build/MilBridge/tools/prereg-four-requirements-check.sh`／`docs/WAVE60-PREREGISTRATION.md`（新）／
`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`／`docs/CURRENT-STATE.md`／`build/wave-audit.log`／
`build/MilBridge/W152A-report.md`（新）。

**主控四件**（`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／
`build/MilBridge/tools/defect-registry-declared.tsv`／`build/MilBridge/HANDOFF-NEXT.md`）
**逐字不在变更集里**（现场 `git show --stat` 核过）。

### 10.2 字节核对（口径：`$R` 磁盘 vs **`HEAD:`** 的 blob）

```
BYTECHECK ok=8 mismatch=0
970bb48ba8ebd384  verify-all.sh                         2b9eb8c1426735c2  docs/WAVE60-PREREGISTRATION.md
d4317aa7605a31e1  …/shell-quote-trap-check.sh           da24cb43d2123612  samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
235d76b61cdc46a4  …/prereg-four-requirements-check.sh   1ef2cb91160b5d4d  docs/CURRENT-STATE.md
9fdac186592676bc  build/wave-audit.log                   1dff6ed003d50a4d  build/MilBridge/W152A-report.md
```

CRLF 口径（`FORK-AND-PUSH.md` §7 教训）：`git check-attr text eol` 全 `text: unset`（本仓刻意 `* -text`）、
`core.autocrlf=false`、`git add` **零 CRLF 告警**。

### 10.3 app-local

```
APPSYNC=MISMATCH（MISMATCH=0[STALE=0 NEWER-DIFF=0] MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0]
                 DIVERGENT=0 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0）
```

⇒ **`STALE=0`／`DIVERGENT=0`**；`UNEXPECTED=6[DECL-GAP-EQ=6]` 与 `#59` 的读数**形态逐字相同**
⇒ **继承自上一代、非本波引入**（`close-wave.sh` `[4/6]` 那句 `APPSYNC 非 PASS` 由此解释）。

### 10.4 两处哨兵（`/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag`）

- 逐位复核 close-wave 写下的**九位**：**9/9 相符**（`SHA`/`PC`/`PF`/`WB`/`WIN32SHIM`/`HBTL`/`WIC`/`PROVIDER`/`DWF`）。
- 按 `NOTE=` 的指示**手工补** `BASELINE=#60 sha16=da24cb43d2123612 bytes=864300`（两处，`temp ＋ rename`）。
- 两处 `cmp` = **IDENTICAL** ✓。

---

## §11 机读摘要（末行）


`W152A=DONE wave=#60 baseline=da24cb43d2123612/864300 steps=33→34 tooth=235d76b61cdc46a4,d4317aa7605a31e1 verify_all=970bb48ba8ebd384 gate_x2=PASS pre=34✅/0❌ post_x2=34✅/0❌ marker=2026-09-24T10:43:04 push=32eaaf0..332d503(remote head 332d5032472c899d2e846cad1e53e172e604bdf3,分支 feat-Linux) R_touched=verify-all.sh,build/MilBridge/tools/shell-quote-trap-check.sh,build/MilBridge/tools/prereg-four-requirements-check.sh,docs/WAVE60-PREREGISTRATION.md,samples/WpfTextDemo/ACCEPTANCE-BASELINE.md,docs/CURRENT-STATE.md,build/wave-audit.log,build/MilBridge/W152A-report.md heavy=YES(slot)
