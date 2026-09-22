# W95A 报告 —— 波 `#50` 收尾链**后半段（步骤 5–9）**：**全部完成**（⑤门禁×2 → ⑥冻前 `verify-all` → ⑦冻结 `#50` → ⑧冻后×2 → ⑨记录·推送·app-local）

> 车道 **W95A** ｜ 2026-09-22 **15:36 → 17:5x +0800** ｜ kernel 6.8.0-138-generic ｜ `nproc=3`
> 仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（全程绝对路径；**本机 `R` 不是 git 仓库**）
> 上游：步骤 1–4 由车道 **W94A** 跑完（`build/MilBridge/W94A-report.md` = `9357566278d1cf7b`，`~/w94a/STATUS.md`）。
> 判据**先写、读数后取**：本车道全部预测写在 `~/w95a/STATUS.md`（追加式、逐条带时刻）**先于**对应读数；三处"先写后取"的预测都**成立**（见 §4.4／§5.2／§8.3）。
> 原始日志：`~/w95a/logs/`。**零 `pkill -f`**（全部按 PID / 由 runner 自收）。

---

## §0 结论摘要（先看这八条）

1. **五步全部跑完**：⑤门禁 ×2（各 `rc=0`、机读行 **6/6 `result=PASS`**）→ ⑥冻前 `verify-all` → ⑦**冻结 `#50`**（`1f4189c1257737a9`）→ ⑧冻后 `verify-all` **×2 全绿**（各 `26 ✅ / 0 ❌`、`rc=0`）→ ⑨记录 ＋ 推送 ＋ app-local 刷新。
2. 🔴 **中途出现第 2 处红（`PIPEFAIL-SIGPIPE`），我按纪律停手报主控**；主控裁定 **"(a) 修那 9 处、否决(b) 声明掉"** ⇒ 修完重跑冻前 `verify-all` **恰好剩 1 处声明类红** ⇒ 才继续冻结。
3. **那 9 处全在本波自建件里**（`r-gate-step.sh` 8 处 ＋ `run-w81a-legs.sh:255` 1 处），**方向 = 假 FAIL**，且 `c11` 是**承载 `D-G55`** 的那一格 ⇒ 属**判据脆弱性**，已修（判据文本一字未动）。
4. **两极化（本缺陷的真证明）**：私有副本把 `c11` 载荷换成 ≈250 KB ⇒ **旧写法 `R_GATE=FAIL crit=12/13`（假红）／新写法 `PASS crit=13/13`**，且**阴性对照不放松**（真的缺 `seq-combo` 时两版都 `FAIL`）。
5. **`pf` 那一格不是构建身份**已逐字写进冻结块（四条成对读数 ＋ 源指纹四趟相同 ＋ 72 字节差异簇）；**冻前刻／冻后刻九位成对读数 = 逐位相同**（含 `pf`，先写后取的预测**成立**）。
6. **`inputs_fp` 因修 `r-gate-step.sh`（在覆盖面内）必变**：`f3fb5db8…`（作废）→ **`ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48`**。
7. **登记**：该族**已有编号 `D-G42`** ⇒ **不新增编号**（`DEFREG=PASS declared=126 route_ids=126` 不变、`DECLDRIFT=0`），只在 `D-G42` 条目里加一条 bullet（含"**禁止用 `DECL` 表转绿 = 压绿**"）。
8. **app-local**：仓内 `STALE=0 / DIVERGENT=0`（刷 1 份）；仓外 hc 应用目录刷 **3 份**（`SYNC-APPLOCAL=PASS`、逐件回读断言通过）；两本登记册按自己的口径**删掉 50 条已转绿**、保留 **1 条仍红**。

---

## §1 步骤 ⑤ 应用门禁 ×2 —— `rc = 0 / 0`，机读行 **6/6 PASS ×2**

```bash
export PATH="$HOME/.dotnet:$PATH"; export DOTNET_gcServer=0
# 第 1 趟（写 rows）
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1200 --wait 900 -- timeout 900 env \
  WPTD_RUN_DIR=$HOME/w95a/gate-e WPTD_BASELINE_OUT=$HOME/w95a/gate-rows.txt \
  bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both \
  > ~/w95a/logs/05-gate-e.log 2>&1                                       # rc=0
# 第 2 趟（写另一本；--no-build）
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1200 --wait 900 -- timeout 900 env \
  WPTD_RUN_DIR=$HOME/w95a/gate-f WPTD_BASELINE_OUT=$HOME/w95a/gate-rows-f.txt \
  bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both --no-build \
  > ~/w95a/logs/05-gate-f.log 2>&1                                       # rc=0
```

| | 第 1 趟 | 第 2 趟 |
|---|---|---|
| `HEAVYSLOT=` | `ACQUIRED waited=0s`／`MEMOK avail=2818MB min_avail=1500MB`／**`RELEASED rc=0 held=161s max_hold=1200s`** | `ACQUIRED waited=0s`／**`RELEASED rc=0 held=157s max_hold=1200s`** |
| 机读行 | **`WPTD_TIER=default rep=1/2/3 RESULT=PASS`** ＋ **`env rep=1/2/3 RESULT=PASS`** ⇒ **6/6** | 同（逐字相同） |
| rows 文件 | `~/w95a/gate-rows.txt` sha16 **`4a7fad3a66f527fe`**（6 行 / `result=FAIL` **0**） | `~/w95a/gate-rows-f.txt` sha16 **`abbb0cc925d50e6e`**（6 行 / 0 FAIL） |
| X | 自起 `Xvfb :97`（PID 2352477），收工无孤儿 | 自起 `Xvfb :97`，收工无孤儿 |

两趟逐字相同的三条汇总行：

```
WPTD_SUMMARY=PASS tiers_passed=2/2
WPTD_GATE=PASS acceptance=2/2 line_advance=PASS
WPTD_BRIDGE_SRC_STALE=no basis=pub=0a8f69b3c5fabd43 now=0a8f69b3c5fabd43 so_file_match=yes
```

rows 六行的 config（**就是冻结器要断言的终态**）：

```
config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:f34bc297d19778fd,provider:1f9511a7ef395bfe,
       win32shim:33352e5797031999,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no)
```

两本 rows 的 `BASELINE` 六行 **config/result/drawn/colors/frames 读数逐项相同**（只有 header 的 `date`/`loadavg`/`mem` 与 `run_dir` 不同 ⇒ 两本 sha16 不同）。
`D-G79`（窗口认领）**未再触发**（`no-window` 0 次）⇒ 本波门禁合计 **12/12 PASS**。

---

## §2 步骤 ⑥ 冻前 `verify-all` —— **两趟**（第 1 趟出第 2 处红 ⇒ 停手；第 2 趟才是冻结输入）

命令（两趟逐字相同）：

```bash
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1500 --wait 900 -- timeout 1450 bash verify-all.sh
```

| 趟 | 日志 | `HEAVYSLOT=` | 汇总 | 失败项 |
|---|---|---|---|---|
| **第 1 趟**（出第 2 处红） | `06-verify-all-pre.log` | `RELEASED rc=1 held=874s` | `步骤通过 24 ❌ 失败 2`／`用例通过 875 跳过 2` | **`COLUMN-FLOOR PIPEFAIL-SIGPIPE`** |
| **第 2 趟**（**冻结输入**） | `06b-verify-all-pre2.log` | `RELEASED rc=1 held=867s` | **`步骤通过 25 ❌ 失败 1`**／`用例通过 875 跳过 2` | **`COLUMN-FLOOR`（恰好 1 处、且是声明类 ⇒ 预期达成）** |

两趟的 `[0]` 段都是**自起** `Xvfb :99`、`X_STATE=available`；`SKIP_GUARD=PASS x_state=available violations=none`（零静默跳过）。

### §2.1 第 2 趟（冻结输入）的逐项结果（26 个 `run_step` ＋ `[0]`）

| 组 | 步 | 结果 |
|---|---|---|
| `[0]` | Xvfb | ✅ 自起 `:99` |
| `[1]` | 主工程 WpfGfx.Linux ／ wpf-linux.sln | ✅ ／ ✅ |
| `[2]` | Commands 562／Rendering 166(跳2)／Windowing 44／HelloMil 19／ManagedLayer 76／Presentation 8 | ✅ ×6 |
| `[3]` | verify-cmd-layout.py | ✅ |
| `[4]` | tline-gate（五臂） | ✅ `TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK tree_gen=same saved_shim=921ba9c65e9fb3be` |
| `[5]` | PcLineOracle·Start 列 | ✅ `红=0 绿=421 判定行=421 NOINFO=0` |
| `[6]` | FrameProbe-frame | ✅ 三腿 `帧红=0`（结构族红 3 已登记，本步不判） |
| `[7]` | BASELINE-SHA | ✅ `BASELINESHA=PASS live=f1d340d66c7c6ba3 decl=f1d340d66c7c6ba3`／`BASELINEGEN=PASS decl_gen=#49`／`BASELINEDUP=PASS n=0` |
| `[8]` | ARM-LOG-SHA | ✅ `pass=5 fail=0 noinfo=0` |
| `[9]` | BUILD-HYGIENE | ✅ `reason=ok files=41 undeclared=0 witness_expired=0` |
| `[10]` | DEFECT-REGISTRY | ✅ **`DEFREG=PASS declared=126 route_ids=126`** |
| `[11]` | VERIFYALL-SELF | ✅ **`names=26 decl=26 gen=#50 dup=0 order=OK prose=OK prereg=PASS vfile_sha16=227623000850ca5d`** |
| `[12]` | FP-INPUTS-HYGIENE | ✅ `reason=clean coverage_n=147 artifact_n=0` |
| `[13]` | HIDDEN-ONLY | ✅ `判定例=32/32` |
| `[14]` | **COLUMN-FLOOR** | ❌ **设计内**（§2.2） |
| `[15]` | QUOTE-TRAP | ✅ `traps=0 files=150` |
| `[16]` | PRODUCT-ENTRY | ✅ `判定例=8/8 判据格=147/147 在册已知红 5/5 noinfo=0` |
| `[17]` | FRAME-PRESENCE | ✅ `frames=80 max_colors=4113 magenta_frames=40` |
| `[17]` | **PIPEFAIL-SIGPIPE** | ✅ **`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=1 files=67 sites=81 hit=1 low=10 diag=2 safe=68 runs=12`**（第 1 趟是 ❌，见 §2.3） |
| `[17]` | THIRD-PARTY | ✅ `frames=41 max_colors=1642 min_colors=800` |
| `[26]` | **R-GATE（连续交互）** | ✅ **`R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938`** |

### §2.2 那一处**设计内**的声明类红（逐字原文，两趟相同）

```
  COLUMN-FLOOR                 ❌  (rc=1)
      COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline
      COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0 selfreport=PASS reg=8a0c0f221e35f42b base=f1d340d66c7c6ba3 corpus=0cebc0afd5142fbf
```

形态**逐字命中** `w27-freeze.py:_is_declaration_class()`（`COLUMN_FLOOR_ARMLOG=FAIL` ∧ `selfreport=PASS`）。
⚠️ **任务书写的是 `n_ok=3`；现场是 `n_ok=4`** —— 四次独立复算同值（只读一趟／第 1 趟内／第 2 趟内／冻结器内）⇒ 以现场为准（主控已确认其任务书那一栏是抄错）。

### §2.3 🔴 **第 1 趟那第 2 处红：`PIPEFAIL-SIGPIPE`（我按纪律停手报主控）**

```
  PIPEFAIL-SIGPIPE             ❌  (rc=1)
      PIPEFAIL_SIGPIPE=FAIL undeclared_hit=9 decl_stale=0 files=67 sites=92 hit=12 low=10 diag=2 safe=68 runs=12
```

**9 条 `UNDECLARED_HIT` 全量**：`build/MilBridge/tools/r-gate-step.sh`（**本波 `TASK-0702` 的判据唯一实现**，mtime 09-22 10:24，修前 sha16 `23b6ee91a4a8dc9b`）`:164 :167 :197 :201 :301 :302 :303 :308` 共 **8** 处
＋ `build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh:255`（本波 W81A 新装置，09-21 18:41）**1** 处
⇒ **全部落在本波新建件里**（`#49` 冻后、我开工前落盘）⇒ **不是我造成的、也不是陈旧红**（`decl_stale=0`）。

**机制与危险方向**：`r-gate-step.sh:46` 是 `set -uo pipefail`，那 8 处是 `printf '%s' "$S" | grep -qE PAT`
⇒ `grep -q` 命中即早退 ⇒ `printf` 吃 **SIGPIPE(141)** ⇒ **pipefail 把"命中"读成 `rc≠0`** ⇒ `if` 走 `else`、`||` 触发 ⇒ **假 FAIL**。
牙的动态探针逐格：`dyn_big=12/12 dyn_off=0/12 dyn_small=0/12`（**载荷 > 64 KiB 管道缓冲才翻**）。
⇒ **本趟 `R_GATE=PASS crit=13/13` 的读数仍然成立**（现场切片都小、不触发），**不是假绿**；但 `:301-303` 的 `c11` 正是**承载 `D-G55`** 的那一格 ⇒ 属**判据脆弱性**。

**为什么它挡死冻结（机械原因）**：它在 `GENS['#50']['green']` 里，而 `_is_declaration_class()` 不认它 ⇒ **非声明类红** ⇒ 冻结器 `assert _ok` 必失败 ⇒ **冻结器跑不起来**（我没有跑、也没有试图绕过）。**处置按任务书"出现第 2 处红 ⇒ 停手报主控"**（`~/w95a/STATUS.md` 有完整停手记录），主控裁定 **(a) 修那 9 处、(b) 否决**。

---

## §3 步骤 ⑥→⑦ 之间的修复（主控裁定后执行）

### §3.1 修法（**判据文本一字未动，只换喂法**）

| 件 | 修前 sha16 | 修后 sha16 | 改了什么 |
|---|---|---|---|
| `build/MilBridge/tools/r-gate-step.sh` | `23b6ee91a4a8dc9b` | **`aa9d7188b6b01a2f`** | 8 处 `printf '%s' "$S" \| grep -qE PAT` → **`grep -qE PAT <<<"$S"`** |
| `build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh` | `5691050c5c67cf1d` | **`08b917a54b18b965`** | `grep … \| head -8 \| sed … \|\| echo "（无）"` → 先把 `head -8` 的结果收进 `_exc8`，再按有无内容分两路印（原写法在**有**异常原文时印"（无）"） |

两件 `bash -n` 都 `rc=0`；备份 `cp -p` 在 `~/w95a/backup/*.before`。`diff` 逐行已留档（`~/w95a/logs/` 与 `STATUS.md`）。
`set -uo pipefail` 未动、判据阈值未动、`EXPECT_*` 常量未动、`fails=` 文案未动。

### §3.2 三件必做证（逐条读数）

**证① 牙本身转绿**（`~/w95a/logs/10-pipefail-after-fix.log`）：

```
PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=1 files=67 sites=81 hit=1 low=10 diag=2 safe=68 runs=12      rc=0
```
（唯一剩下的 `HIT` = **已声明**的写域外站点 `run-wpfprobe.sh:568`；`decl_stale=0`）

**证② 判据件自测**（`~/w95a/logs/11-rgate-selftest.log`）：

```
R_GATE_SELFTEST=PASS cases=21 pass=21 fail=0 crit_total=13                                                   rc=0
ST_ATTEST=PASS self=…/r-gate-step.sh sha16=aa9d7188b6b01a2f（自测期间本件未变 ⇒ 读数可归因）
```

**证③ 两极化（本缺陷的**真**证明；私有副本 `~/w95a/polarity/`，把 `c11` 三格的载荷换成 ≈250 KB = `pad.txt` 250,000 B）**：

| | `S1 正极性（全绿）` | `S11`（阴性对照：真的缺 `seq-combo`） | 整件 |
|---|---|---|---|
| **旧写法** `judge-old.sh` | **`=> NO  want rc=0/R_GATE=PASS got rc=1`**，失败格点名 `c11(连续腿缺格：seq-lst0,seq-tb,seq-combo,…)` | `=> yes rc=1 FAIL fails=c11(…seq-combo…)` | **`R_GATE_SELFTEST=FAIL cases=21 pass=18 fail=3`** |
| **新写法** `judge-new.sh`（同载荷） | **`=> yes rc=0  R_GATE=PASS crit=13/13`** | 同（仍 `FAIL fails=c11(…seq-combo…)`） | **`R_GATE_SELFTEST=PASS cases=21 pass=21 fail=0`** |

⇒ **同一份证据、同一份判据文本，只换"喂法"**：旧写法把它判成假红、新写法判对；**阳性/阴性两侧都做**（阴性不放松）。
日志：`12a-polarity-old.log`／`12b-polarity-new.log`。**实验只在私有副本里做**，仓内两件停的是**修后端**（未处于实验态）。

### §3.3 顺带机械核（`| grep -q` 同族写法）

`grep -rn '| *grep -q' build samples src` ⇒ **本波新建件已 0 命中**。
**既有件里仍有**（按主控"既有件只报不动"，**一处未动**）：`run-wpftextdemo.sh` 4｜`defect-registry-check.sh` 3｜`frame-presence-check.sh` 2｜`build-hygiene-import-check.sh` 2｜`integration-wave.sh` 2｜`run-wpfprobe.sh` 1｜`run-wpfprobe-1400rate.sh` 1｜`run-hellowpf.sh` 1｜`t1b-ls-tripwire.sh` 1。
它们在牙的现场分类里是 `SAFE/LOW/DECLARED`（牙 `rc=0` 可证）⇒ 如实列此，**不扩大改面**。

### §3.4 登记（**不新增编号**）

`KNOWN-DEFECTS.md` 里该族**已有编号 `D-G42`**（`:1453`，"`pipefail` ＋ 管道左侧被 SIGPIPE 杀死 ⇒ 判据错"）⇒ 只在**那一条**里加一条 bullet：
本波 `r-gate-step.sh`（8 处）＋`run-w81a-legs.sh:255` 被同一族命中、**方向=假 FAIL**、**`c11` 承载 `D-G55` ⇒ 证据超 64 KiB 缓冲即假红**、本波已修 ＋ 两极化读数；
并写明 **"该族禁止用写进 `DECL` 声明表的方式转绿（`DECL` 口径只许写不在本车道写域的真 HIT；对本波自建件用它 = 压绿）"**。

| 件 | 改前 → 改后 |
|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `aec62c485d5010b9` → **`368b293d4ef7f1cb`** |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `bdf95e0c8bc191f0` → `8b9907e9480812c6`（登记后 `--emit`）→ **`53fb33701da1c395`**（app-local 删表后再次 `--emit`，见 §8.2） |

现场复核（两次）：
```
DEFREG=PASS declared=126 route_ids=126        ← 编号总数不变（不新增）
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
defect-registry-check.sh rc=0
```
⚠️ `KNOWN-DEFECTS.md`／路由件／tsv **都不在 `fp_inputs()` 覆盖面内**（现场点算：登记前后 `inputs_fp` **同值**）⇒ **登记不动 `inputs_fp`**，可安排在采样之后。

### §3.5 `inputs_fp` 新旧值（**必变，可归因**）

```
修前（= W94A 步骤④重钉后终值，**作废**）= f3fb5db87480ada8fd1502148f3c889549be756c0e60912bfc38109a4a3cc730
修后（本代冻结器断言值）            = ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48
```
归因：`r-gate-step.sh` **在 `fp_inputs()` 覆盖面内**（`#50` W91A 新纳入的两件 R-GATE 判据件之一）⇒ 修它必变。
`GENS['#50']['infp']` 已同趟改成新值（**不是**看读数事后对齐：改动由裁定直接决定，改动本身写在读数之前，`STATUS.md` 有留痕）。

---

## §4 步骤 ⑦ 冻结 `#50` —— `rc=0`（**含 `pf` 警告 ＋ 成对九位**）

```bash
python3 ~/w21-verify/w27-freeze.py ~/w95a/logs/06b-verify-all-pre2.log ~/w95a/gate-rows.txt '#50'
```

冻结器逐行读数（`~/w95a/logs/07-freeze50.log`）：

```
世代交叉断言通过：树上 #49 == GENS['#50'][prev]
  · 冻前声明类红项 = ['COLUMN-FLOOR']（冻后必须转绿）
verify-all = 26 步（通过 25 / 失败 1；其中声明类 ['BASELINE-SHA','ARM-LOG-SHA'] 应为红、其余全绿） / 875 通过 2 跳过
牙齿②：`verify-all.sh` 的 `^run_step "` = 26 == 步数 26，且头注释逐字声明了同一数字
  冻结器读的九位路径配置 = Release（来自唯一声明 build/SelfBuiltConfig.props）
相对开工前变化的位 = ['pc','pf','win32shim','wic_shim','dwf'] ｜inputs_fp = ee543f44… ｜BRIDGE_SRC_FP = 0a8f69b3c5fabd43
本波位移 = ['pc','pf','win32shim','wic_shim','dwf']（在允许集合内）
门禁 6 条机读行 OK（pc:722e0ab8205b7c3f pf:f34bc297d19778fd）
基线已重冻为 #50；整份 sha16 = 1f4189c1257737a9
BASELINESHA=PASS live=1f4189c1257737a9 decl=1f4189c1257737a9
BASELINEGEN=PASS decl_gen=#50 file_newest_gen=#50
BASELINE_BYTES=644091
BASELINEDUP=PASS n=0
ARMLOG_SHA=PASS shape=flat required=5 declared=5 pass=5 fail=0 noinfo=0
COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS base=1f4189c1257737a9
✅ 两极化齐：冻前 BASELINE-SHA/ARM-LOG-SHA/COLUMN-FLOOR(ARMLOG) 红 ⇒ 冻后同一批检查器都绿
```

### §4.1 机器行（`BASELINEGEN` / `BASELINEDUP`）

| 项 | 改前 | 改后 |
|---|---|---|
| `docs/CURRENT-STATE.md:9` | `> BASELINE-FROZEN gen=#49 sha16=f1d340d66c7c6ba3 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | **`> BASELINE-FROZEN gen=#50 sha16=1f4189c1257737a9 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`** |
| `ACCEPTANCE-BASELINE.md` 整份 | `f1d340d66c7c6ba3`（615,139 B） | **`1f4189c1257737a9`**（644,091 B） |
| `BASELINEGEN` | `PASS decl_gen=#49` | **`PASS decl_gen=#50 file_newest_gen=#50`** |
| `BASELINEDUP` | `PASS n=0` | **`PASS n=0`**（全仓只许一处机器声明 ⇒ 仍只一处） |
| 备份 | — | `~/w95a/backup/{ACCEPTANCE-BASELINE.md,CURRENT-STATE.md}.before` |

### §4.2 冻结块里逐字写进的两条硬要求

① **`pf` 那一格不是构建身份**（逐字警告 ＋ 四条成对读数 `881c56e26808269f`／`decd920092287b03`／`581c864a7f2ad36c`／`f34bc297d19778fd` ＋ `ARTIFACT_SRC_FP proj=PresentationFramework fp=5b38ea7420b26377 n=1362` **四趟逐位相同** ＋ 隔离 `-t:Rebuild` 两次同值 ＋ 72 字节差异簇 = PE `TimeDateStamp`/MVID/调试目录）＋ "**本格只作当下那一刻的现场值，不许被后人当漂移/回归判据**"。
② **冻前/冻后成对九位**：**冻前刻** = 块里那一栏（写盘那一刻的 live 复算）；**冻后刻**逐位并列在**本报告 §5.2** 与 `~/w95a/STATUS.md`（命令 `bash ~/w95a/nine.sh`）。
⚠️ **一条如实登记的机械约束**：冻后刻读数**物理上不可能写进冻结块内** —— 冻结块与 `docs/CURRENT-STATE.md:9` 的机器行**同趟写盘、必须逐字自洽**（`BASELINE-SHA` 比的就是这份整份 sha16），**冻后不许再改本件**（改了立刻红）⇒ 我按"**先写死判据、后取读数**"在块里登记了**预测**（"两刻逐位相同，特别是 `pf`"）＋**失败判据**（任一位不同必须逐位并列；`pf` 不同**不算失败**）。

### §4.3 `w50-record.txt` / `w50-pre.sha` / `GENS['#50']`（冻结器的三件输入）

* `~/w21-verify/w50-record.txt`：三段（`BANNER`/`FROZEN`/`RECORD`）；占位符机器校验 `UNDEFINED=[]`、替换后 `left=[]`；`# RE-FROZEN {GEN}` 锚行在位。
* `/home/links-dev/w50-pre.sha`：9 行、键=路径。口径**逐字同 `#49` 先例**——`PRE` **不是**开工前活取，而按 **`#49` 冻结块九位逐位重建**（本波位移在我开工前已由波内车道落定）⇒ `changed` = 本波相对 `#49` 冻结点的位移 = `{pc,pf,win32shim,wic_shim,dwf}`。
  **同时在记录里并列更窄的口径**：`W94A` **活取**的"波前九位" ⇒ 相对它**本波之内**真正位移的是 `{pc,pf,dwf}`（`win32shim`/`wic_shim` 的位移在 `#49` 冻结之后、`W94A` 开工之前）。
* `~/w21-verify/w27-freeze.py`：**只追加** `GENS['#50']`（老代 `#27`…`#49` 一字未动；`ast.parse` OK）。

### §4.4 成对九位（**先写后取的预测 ⇒ 成立**）

| 位 | **冻前刻**（写盘前 live） | **冻后刻**（写盘后零构建窗口） | **冻后刻₂**（两趟冻后 `verify-all` 之后） |
|---|---|---|---|
| `bridge` | `feef049e9d0e313a` | 同 | 同 |
| `pc` | `722e0ab8205b7c3f` | 同 | 同 |
| `pf` | `f34bc297d19778fd` | 同 | **同** |
| `windowsbase` | `2e4e46e539a72cd7` | 同 | 同 |
| `provider` | `1f9511a7ef395bfe` | 同 | 同 |
| `win32shim` | `33352e5797031999` | 同 | 同 |
| `wic_shim` | `f7b3026c8c019be2` | 同 | 同 |
| `hbtextline` | `921ba9c65e9fb3be` | 同 | 同 |
| `dwf` | `ce3469f49efcbcfa` | 同 | 同 |

⇒ **三个时刻逐位相同**（`PAIR_IDENTICAL=YES`）⇒ 块里那条预测**成立**，**`pf` 没有漂**（也印证"冻后两趟 `verify-all` 只做增量构建、PF 不重编"）。
读数文件：`~/w95a/nine-pre-freeze.txt`／`nine-post-freeze.txt`／`nine-post-verifyall.txt`。

---

## §5 步骤 ⑧ 冻后 `verify-all` ×2 —— **两趟全绿**

| 趟 | 日志 | `HEAVYSLOT=` | 汇总 | 结论 |
|---|---|---|---|---|
| 第 1 趟 | `08-verify-all-post1.log` | **`RELEASED rc=0 held=861s`** | **`步骤通过 26 ❌ 失败 0`**／`用例通过 875 跳过 2` | **`✅ 全部通过`** |
| 第 2 趟 | `08b-verify-all-post2.log` | **`RELEASED rc=0 held=853s`** | **`步骤通过 26 ❌ 失败 0`**／`用例通过 875 跳过 2` | **`✅ 全部通过`** |

**两趟的关键机读行逐字相同**（摘录，两趟各一份）：

```
BASELINEGEN=PASS decl_gen=#50 file_newest_gen=#50
ARMLOG_SHA=PASS shape=flat logdir=…/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0
DEFREG=PASS declared=126 route_ids=126（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
VERIFYALL_SELF=PASS names=26 decl=26 gen=#50 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=227623000850ca5d
COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=8a0c0f221e35f42b base=1f4189c1257737a9 corpus=0cebc0afd5142fbf
PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=1 files=67 sites=81 hit=1 low=10 diag=2 safe=68 runs=12
R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938
  （第 1 趟 mem_mb=2757／第 2 趟 mem_mb=2768 —— 唯一不同的字段，是内存瞬时读数）
```

**冻前→冻后两极化齐**（本波"声明类两极化"纪律的机器落点）：`BASELINE-SHA`／`ARM-LOG-SHA`／`COLUMN-FLOOR(ARMLOG)`／`PIPEFAIL-SIGPIPE` 四项**冻前都红、冻后都绿**。
`SKIP_GUARD=PASS x_state=available violations=none`（两趟）；**零静默跳过**、`D-G59` 未触发（`:99` 自起）。

### §5.1 `arm-log-sha-check.sh` 5/5（本报告同趟现场跑）

```
ARMLOG_ARM=tab-anchor    PASS decl=1c43a12dcaa5718a live=1c43a12dcaa5718a nlink=2
ARMLOG_ARM=tab-zero      PASS decl=9150c3a26a3cb789 live=9150c3a26a3cb789 nlink=2
ARMLOG_ARM=tab-rtl       PASS decl=92570318851ca7e8 live=92570318851ca7e8 nlink=2
ARMLOG_ARM=tline         PASS decl=6ce993ad974d32ad live=6ce993ad974d32ad nlink=2
ARMLOG_ARM=textlineproto PASS decl=4bceceeed570ba70 live=4bceceeed570ba70 nlink=2
ARMLOG_SHA=PASS shape=flat required=5 declared=5 pass=5 fail=0 noinfo=0        rc=0
```

---

## §6 步骤 ⑨ 之一：app-local 刷新（`TASK-9906`）

### §6.1 仓内（`check-applocal-sync.sh` ＋ `sync-applocal-authority.sh --apply`）

| 时刻 | `计数：`／`APPSYNC=` |
|---|---|
| 刷新前（`09a-appsync-before.log`） | `OK=199 MISMATCH=1(STALE=1) UNEXPECTED=6[DECL-GAP-EQ=6] DIVERGENT=1` ⇒ `APPSYNC=MISMATCH` rc=1 |
| 刷新后（`09d-appsync-after.log`） | **`OK=200 MISMATCH=0（STALE=0 NEWER-DIFF=0） UNEXPECTED=6[DECL-GAP-EQ=6] DIVERGENT=0`** ⇒ **`STALE=0` 达成**（rc 仍 1，**只因在册声明类缺口 `UNEXPECTED=6`，不许当绿、不许改判据**） |

刷掉的那一份（唯一 STALE）：

```
REFRESH tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll  16baacfccfcf1df0 → 374b5a538ea955aa（权威 374b5a538ea955aa；副本曾早 886261 秒）
APPSYNC-REFRESH=refreshed=1 newer=0 applied=1
```

### §6.2 仓外（`sync-applocal.sh`，hc 应用目录）

`check`（刷前）⇒ `SYNC-APPLOCAL=DRIFT … drift=3 rc=3`；`apply`（写模式）⇒

```
  ⟳ libwpfwin32.so：已同步          24e906c194903c8b → 33352e5797031999（回读断言通过）
  ✓ wpfgfx_cor3.so：已与权威一致     feef049e9d0e313a
  ⟳ PresentationCore.dll：已同步     56ee75ced8d6aece → 722e0ab8205b7c3f（回读断言通过）
  ⟳ PresentationFramework.dll：已同步 2a5b7641f6fba0fb → f34bc297d19778fd（回读断言通过）
  ✓ WindowsBase.dll：已与权威一致     2e4e46e539a72cd7
   manifest=<目标>/.applocal-sync.tsv（5 行）
SYNC-APPLOCAL=PASS target=/home/links-dev/hc-linux/…/HandyControlDemo_Net_GE45/bin/Debug/net10.0 items=5 ok=2 synced=3 drift=0 rc=0
```
（目标 `TARGETS`＝ `/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`；每件拷后**回读 sha16 断言 == 权威**，用具名 `mv` 原子改名。）

### §6.3 ⚠️ 现场抓到的一条仪器缺口（**只报，未改**）

`sync-applocal-authority.sh:59` 的默认 `SCAN_ROOTS="$REPO/build:$REPO/tests:$REPO/samples:$REPO/src"` —— **不含 `$REPO/tools`**，而 `check-applocal-sync.sh:169` 的默认是 `build:tests:samples:src:**tools**`。
⇒ 那一份唯一的 `STALE` 恰好在 `tools/` 下 ⇒ **该刷新器用默认参数永远刷不到它**，而它自己在同趟末尾用**收窄后的根**重跑校验器 ⇒ **打出 `STALE=0` 的假绿读数**（与全文口径的校验器读数**互相矛盾**：`~/w95a/logs/09b-appsync-authority-apply.log` = `refreshed=0`＋`STALE=0`，而 `09a` 同刻 = `STALE=1`）。
⇒ **本趟按该件自己文档的承诺**（"默认与校验器一致"）显式传 `SCAN_ROOTS=…:tools` 才刷到（`09c-appsync-authority-apply-wide.log`）。
⇒ **未改那件仪器**（不在我写域）；**建议单列一题**（同族 = "同一个事实存在两份根集合 ⇒ 必然分叉"），并注意它的 `--apply` **不写回那件仪器**。

### §6.4 两本登记册（按其自己的口径删表）

| 册 | 删前 | 删后 |
|---|---|---|
| `known-red-PC-copies.md` | 13 条：**仍红 1 ｜ 已转绿 12** | **在册 1 条：仍红 1 ｜ 已转绿 0**（sh16 `8497a0ca1689cf90` → `3c9e3a309b990d31`） |
| `known-red-PFWB-copies.md` | 38 条：**仍红 0 ｜ 已转绿 38** | **在册 0 条**（sh16 `8ee55c8f01e41eb9` → `6db860f13de2ff33`） |

* 判据 = 现场 `check-applocal-sync.sh` 逐条打的 `[在册红·已转绿]`（**不是**我手列的名单）；删的是**恰好那 50 条**（12 ＋ 38）。
* **保留的那 1 条仍红**：`build/PresentationFramework.Classic.Linux/bin/Debug/PresentationCore.dll` `9465f9dce39e2dfc`（现权威 `722e0ab8205b7c3f`；类别 STALE；处置"待裁决（另一份 PC 构建，4,068,864 B）"）⇒ **在册红不许当绿**。
* 两本册子各加**一条 dated 追记**（删了几条、为什么、那个 `tools/` 缺口的来历）；**未改任何既有叙述**。删表**不参与判定**（`show_registry()` 只读只打印、`登记 ≠ 已容忍`）。
* ⚠️ **与任务书数字的差异（如实记）**：任务书说"在册 38 条：仍红 8 ｜ 已转绿 30"（那是 `W91A` **波前**勘察的读数）。**本波现场**是 **51 条：仍红 1 ｜ 已转绿 50** —— 因为**整波重建 ＋ 波尾刷新**已经把原来那 8 条红刷成了新权威。我按册子**自己的口径**执行（"已转绿 ⇒ 应从本表移除"、"在册红保留"）⇒ **删 50、留 1**，不是"删 30、留 8"。
* 删表后**重跑 `check-applocal-sync.sh`**（`09g-appsync-after-del.log`）复核：`STALE=0`／`DIVERGENT=0`／`在册 1 条：仍红 1 ｜ 已转绿 0`／`在册 0 条` ⇒ **册与现场自洽**。
* 删表改了 `known-red-PC-copies.md`（= `DEFREG` 的锚 `KRP`）⇒ 按该件的机械维护流程**再跑一次 `--emit`** ⇒ `DEFREG_DECLDRIFT` 回 **0**、`DEFREG=PASS declared=126 route_ids=126`、`rc=0`（tsv `8b9907e9480812c6 → 53fb33701da1c395`）。

---

## §7 步骤 ⑨ 之二：推送（fork 克隆）

* 差异集口径 = **克隆侧 `git ls-files` ∩ 现盘逐件 `git hash-object`**（**不用自列白名单** —— `#49` 的教训）：
  `SAME=1379 ｜ CHANGED=33 ｜ UNTRACKED=84 ｜ NEW_PUSHABLE=43`（`MISSING_ON_DISK=7366`＝`R` 是部分检出，正常）。
* **实推 69 件** = 33 改动件 ＋ 36 新建件。**排除**（逐条）：`build/.applocal-selftest.log`（selftest 临时日志）｜`build/MilBridge/src/MilBridge.Resolver/README-合并写.txt`（09-10 老件、非本波）｜`build/MilBridge/gen/tline-ledger-lines-20260921-{1224,1231,1540,1623,1629}.txt`（5 件，**早于 `#49` 冻结**）。
  **按设计不进**（`git check-ignore` 逐件确认）：`tests/parity/geometry/u14/linux-results-u14.json`（`.gitignore:47`）｜`tests/parity/windows/layout-b34/windows-results.json`（`.gitignore:51`）｜`build/DirectWrite.Linux/wic-shim/{libwpfwic.so,libSkiaSharp.so}`（`:26`／`:31`）｜`**/__pycache__/**`｜`upstream/**`。
* 纪律：逐径 `cp -p` ＋ 逐径 `git add --`（**无 `git add -A`**、**无 `--force`**、**未碰默认分支**）。

### §7.1 推送结果（**成功，一笔快进**）

```
git -C ~/netTest/GitProj/WPFOnLinux push origin feat-Linux
   7feca48..62c7a7b  feat-Linux -> feat-Linux          （69 files changed, 16,182 insertions(+), 161 deletions(-)）
```

| 项 | 值 |
|---|---|
| **推送前 head** | `7feca487741a8070de81615bd04de889b992766d`（= `origin/feat-Linux`，我开工时与之一致） |
| **推送后 head** | **`62c7a7b58934e1115c8b6eac7cad6e29c0793dac`** |
| 提交信息 | `sync(#50): 收尾链后半段 —— 门禁×2 与冻后 verify-all×2 全绿、冻结 #50（1f4189c1257737a9）、R-GATE 判据件 9 处 SIGPIPE 修法（D-G42 复发）、app-local 刷新与两本登记册删表` |
| 默认分支 | `git ls-remote --symref origin HEAD` = **`ref: refs/heads/feat-Linux`**（**未改**） |
| 提交前工作树 | `git status --porcelain` = **空**（干净；无夹带） |

### §7.2 逐件字节核对（**远端 blob == 现盘**）

⚠️ **先显式 `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`**（这个克隆的 fetch refspec **只跟 `main`**；不显式 fetch 会比到**推送前**的旧 ref —— `#48`/`#49` 两度踩到）⇒ 实测 `7feca48..62c7a7b feat-Linux -> origin/feat-Linux`，随后

```
BYTECHECK ok=69 mismatch=0 nobody=0        ← 逐件 `git cat-file blob origin/feat-Linux:<path> | sha256sum` vs `sha256sum $R/<path>`
```
**69/69 逐字节相同、0 不一致、0 缺 blob**（不一致清单为空）。计数器在主 shell 里累加（**没有**用 `… | tee` —— `#49` 那次计数器被关进子 shell、打出来的 `FAIL=0` 不可信）。

### §7.3 本报告自身的推送（可复算）

本报告 **§7.1／§7.2 的补记**（推送结果与逐件核对）是同趟的**第二笔**提交：`62c7a7b → e4b1cc67007abd03a76d851aa017f6c00fd04856`（**只动 `build/MilBridge/W95A-report.md` 一个文件**）。
**本行所在的这一版**由紧随其后的**第三笔**（同样只动本报告）推送 —— 它自己的 head 记在 `~/w95a/STATUS.md` 末条：
**报告正文无法自述"包含这一行的那一笔"的 sha**（自指），如实说明，不写一个会立刻作废的数。
两笔都遵守同一纪律：逐径 `git add --`、无 `--force`、不碰默认分支；第二笔的 blob 已核对（`REPORT_BLOB_IDENTICAL=YES`）。

---

## §8 `NOINFO` / 作废趟 / 纪律偏离（逐条如实）

### §8.1 `NOINFO`

1. **`pf` 不可复现的根因** —— `W94A` 已证（源指纹四趟相同、产物四趟不同、72 字节全在 `TimeDateStamp`/MVID/调试目录），主控裁定"不修、不追凶"；本件照办（**没有跑任何整波/定向重建**）。要什么样的读数见 `W94A-report.md` §7.1。
2. **`dwf` 第一趟整波为何位移** —— `NOINFO`（此后三趟稳定 ⇒ 值可用）。
3. **`PIPEFAIL-SIGPIPE` 那 9 处"在本趟真实 `R-GATE` 运行里到底有没有真的翻转"** —— **`NOINFO`**。可给的界：`dyn_small=0/12`（载荷 < 64 KiB 不翻）＋ 本趟 `R_GATE=PASS crit=13/13`（若翻转必表现为 `crit` 红）⇒ **读数成立**；但"现场切片究竟多大"没有逐格量（判据件内部行为，不在我写域）。
4. **`UNEXPECTED=6[DECL-GAP-EQ=6]`** 未逐条归因（`#49` 已认定为**在册**声明类缺口；本件只确认"不因本波变多"，且**不许**当绿、**未**改判据）。
5. **`sync-applocal-authority.sh` 的 `tools/` 缺口**（§6.3）—— **本波只报未修**（不在写域）；它是否已有编号**未查**（按主控"小改别扩大"的指示，我没有为它新增编号）。
6. **`VERIFYALL_SELF` 的 `dynamic_trace=NOINFO`** —— 既有读数，本件未追。

### §8.2 作废趟（**不入任何读数**）

1. **`sync-applocal-authority.sh --apply` 的第一个前台趟** —— 我把长步放在**前台**跑，撞上本会话工具 **60 s 上限被 SIGTERM** ⇒ 该趟**作废**（日志 `09b-…log` 只到表头）。
   **未造成写坏（现场可证）**：被刷的那一份 `tools/GeometryOracle/…/WpfGfx.Linux.dll` **sha 未变**（`16baacfccfcf1df0`）、日志里 **0 条 `REFRESH`** ⇒ 脚本在扫描阶段就被终止、**未进入写盘**。**自纠**：改后台 ＋ 轮询（照任务书纪律 2）。
2. **`sync-applocal.sh --apply <dir>` 一趟** —— 该件**没有 `--apply` 选项**（`rc=2 未知选项`）；写模式就是**不带 `--check`/`-n`**（任务书那一栏的 `--apply` 属于 `sync-applocal-authority.sh`）。该趟**零写盘**、作废后改正重跑。
3. **零** `HEAVYSLOT=NOINFO reason=low-memory`、**零** `MAXHOLD_KILL`、**零**裸跑（**八趟重活全部走 `~/heavy-slot.sh`**、全部拿到 `MEMOK`）。
4. 本件重活共 **8 趟**：门禁 ×2（161／157 s）｜应用/仓内校验 4 趟（13／12／10／24 s）｜冻前 `verify-all` ×2（874／867 s）｜冻后 `verify-all` ×2（861／853 s）｜仓外同步 2 趟（0／0 s）。**严格串行、无并发**。

### §8.3 纪律偏离（逐条写理由）

1. **两趟门禁都写 rows（任务书明示）** ⇒ 第 2 趟写到**另一本** `gate-rows-f.txt`：runner 的 `WPTD_BASELINE_OUT` 是**追加**语义，两趟写同一本会得到 12 行，而**冻结器断言"恰好 6 行"** ⇒ 那样会让冻结器红。**冻结输入仍取第 1 趟那本**（6 行）。
2. **门禁用 `--max-hold 1200`、`verify-all` 用 `--min-avail 1500 --max-hold 1500 -- timeout 1450`**（任务书明示的授权上限；实际 held 161/157/874/867/861/853 s）。**`--min-avail 1500` 一字未动**。
3. **我改了 `r-gate-step.sh` 与 `run-w81a-legs.sh`**（§3）—— 这是**主控裁定 "(a) 修那 9 处"** 的直接执行（任务书原本把这两件列为"不可自行处理"，所以我先停手、后按裁定动手）。
4. **我改了 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` ＋ 重生成 `defect-registry-declared.tsv`**（§3.4）—— 同样是主控**明确配方**的登记动作（不新增编号）。
5. **我按配方改了 app-local 两本登记册**（§6.4）—— 任务书明确要求"把已转绿的删掉、保留在册红"；**现场数字与任务书不同**，我按**册子自己的口径**执行并如实并列两套数字。
6. **登记/记录件不在 `fp_inputs()` 覆盖面内**（现场两次点算）⇒ 这些改动**不动** `inputs_fp`；唯一动它的是 §3.5 的那次修法（可归因、且改在读数之前）。

### §8.4 写域（本车道**只**写了这些）

| 件 | 动作 |
|---|---|
| `~/w95a/**`（`STATUS.md`／`nine.sh`／`nine-*.txt`／`bin-changed.sh`／`push-prep.sh`／`polarity/`／`backup/`／`logs/`） | 新建（私有大本营） |
| `build/MilBridge/W95A-report.md` | 本报告（新建） |
| `~/w21-verify/w27-freeze.py` | **追加** `GENS['#50']`（老代未动） |
| `/home/links-dev/w50-pre.sha` | 新建（9 行） |
| `~/w21-verify/w50-record.txt` | 新建（三段，**已作为冻结输入被消费**） |
| `build/MilBridge/tools/r-gate-step.sh` | **修 8 处**（主控裁定）`23b6ee91a4a8dc9b → aa9d7188b6b01a2f` |
| `build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh` | **修 1 处**（主控裁定）`5691050c5c67cf1d → 08b917a54b18b965` |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `D-G42` 加一条 bullet（不新增编号）`aec62c485d5010b9 → 368b293d4ef7f1cb` |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `--emit` ×2（机械重生成）`bdf95e0c8bc191f0 → 53fb33701da1c395` |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | **冻结器写入**（`#50` 块）`f1d340d66c7c6ba3 → 1f4189c1257737a9` |
| `docs/CURRENT-STATE.md:9` | **冻结器写入**机器行 `gen=#49 → #50` |
| `build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md` | 删 12 条已转绿 ＋ 一条追记 `8497a0ca1689cf90 → 3c9e3a309b990d31` |
| `build/DirectWrite.Linux/wic-shim/known-red-PFWB-copies.md` | 删 38 条已转绿 ＋ 一条追记 `8ee55c8f01e41eb9 → 6db860f13de2ff33` |
| app-local 副本（仓内 1 份 ＋ 仓外 hc 应用目录 3 份） | 按判据/配方刷新 |
| `~/netTest/GitProj/WPFOnLinux` | 逐径 `add` ＋ 提交 ＋ 推送（§7） |

**未动**（逐条点名）：`verify-all.sh`｜`build/close-wave.sh`｜`build/integration-wave.sh`｜`build/MilBridge/tools/{pipefail-sigpipe-check.sh,column-floor-check.sh,arm-log-sha-check.sh,baseline-sha-check.sh,defect-registry-check.sh,product-entry-step.sh,…}`｜`build/DirectWrite.Linux/wic-shim/{check-applocal-sync.sh,sync-applocal-authority.sh,applocal-expect.py}`｜`docs/ROUTES.md`（W96A 已落定）｜`handoff.md`｜五臂判据｜`build/MilBridge/known-red.json`（步骤④已重钉，本件未动）。

---

## §9 内存 / 残留 / 收工

* `MemAvailable`：开工 **~2.9 GB** → 门禁 `MEMOK avail=2818MB` → 冻前 `verify-all` `MEMOK avail=3162/3xxxMB` → 冻后 `MEMOK avail≈2900-3000MB` → 收工 **2606 MB**（`total 7923 / used 4983 / free 423`）；`oom_kill` **0**；`loadavg` 收工 `1.11 1.01 1.07`。
* **残留进程：本车道 0**（自起的 `Xvfb :97`／`:99` 都由 runner 按 PID 自收；现场 `X95/X96/X97/X99` 等 socket 属**别的车道**，我一个都没碰）。**零 `pkill -f`**。
* 报告件 sha16 见 `~/w95a/STATUS.md` 末条（写入后现场算）。

---

## §10 大白话小结（8 行）

1. **五步全跑完了**：门禁两趟都过（6/6），冻结做成了 `#50`（基线 sha `1f4189c1257737a9`），冻后门禁两趟**全绿 26/26**。
2. 中间**卡了一次**：冻前那趟 `verify-all` 冒出**第二处红**——本波新写的交互判据件里有 **9 个"管道会让命令提前退出"的写法**没登记。
3. 我**按你的规矩停手报你**，你裁定"**修**，不许声明掉"；我改了那 9 处（**判据一个字没动，只换喂法**）。
4. **证明修对了**：把证据切片撑到 250 KB，**老写法把好证据判成红、新写法判对**；而**真缺证据时两版都判红**（判据没放松）。牙本身也回到 `undeclared_hit=0`、自测 21/21。
5. 修的那两件里有件在"输入指纹"覆盖面内 ⇒ **`inputs_fp` 变成 `ee543f44…`**（旧值作废，已按新值冻结）；登记动作不在覆盖面内、**没动它**。
6. **`pf` 那一格我照你要求写死了警告**（它不是构建身份）；**冻前、冻后（含两趟 verify-all 之后）三次复算九位逐位相同**，先写的预测成立。
7. **app-local**：仓内 `STALE=0`；仓外 hc 应用目录刷了 3 件（都回读断言过）；两本登记册按自己的口径**删了 50 条已转绿、留了 1 条仍红**——注意**现场是 50/1，不是任务书写的 30/8**（整波重建已经把原来那 8 条刷绿了）。
8. 顺带抓到一条**只报未修**的仪器缺口：仓内刷新器默认的扫描根**漏了 `tools/`** ⇒ 它自己会打出"`STALE=0`"的**假绿**；我按它文档的承诺显式补上根才刷到，建议单列一题。
