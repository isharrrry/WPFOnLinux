# W113A 报告 —— 三束装置/判据卫生问题的**修法**（`D-G91` 假绿同步器 ／ `D-G96` 装置毁证 ／ `D-G42` 族 `printf|grep -q`）

- 车道：**W113A**｜日期：**2026-09-22**（22:06 开工）
- 仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**本机 `R` 不是 git 仓库**；推送不在本件）
- 冻结基线 `#51 38e67e834430d75c`
- 纪律：**零 `dotnet`／零构建／零应用**（第二束只起了一个**私有 `Xvfb :191`**，收工按 PID 收干净）
- 判据**先写**：`~/w113a/criteria.md`（三束 `C1–C4` / `E1–E4` / `F1–F4` ＋ `inputs_fp`），读数后填本节
- 状态流水：`~/w113a/STATUS.md`（每完成一束立刻追加）
- **未碰**（其余车道写域）：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`、`docs/ROUTES.md`、`docs/CURRENT-STATE.md`、
  `defect-registry-declared.tsv`（车道 W111A 正在改）、`verify-all.sh`／`close-wave.sh`／`integration-wave.sh` 的**接线**、
  `r-gate-step.sh`／`nul-bytes-check.sh`／`wm-awaited.sh`／`known-red.json`／`ACCEPTANCE-BASELINE.md`、
  `~/w105a/**`／`~/w109a/**`／`~/w110a/**`／`~/w112a/**`、任何产品件（`src/**`、`build/shims/**`、`build/Presentation*.Linux/**`）。
  **未跑** `verify-all.sh`／`close-wave.sh`。**未用** `pkill -f`。

---

## §1 三束判据（**先写**，逐条照抄 `~/w113a/criteria.md`）

### 第一束 `D-G91`
- **`C1` 根集合唯一**：同步器不再自己写死默认根集合，**从校验器派生**（新增只读 `--print-scan-roots`）。
- **`C2` 假绿不可能**：同步器实际用的根集合 ≠ 校验器默认根集合（= 调用方显式收窄）⇒ 必须印
  `APPSYNC_ROOTS=MISMATCH` ＋ `NOINFO` ＋ **`rc≠0`**，且**在打印任何 `STALE=` 汇总之前退出**。
- **`C3` 真值仍算真值**：根集合一致时行为不变；修后默认参数**必须看得见**原先只藏在 `$REPO/tools` 下的 `STALE`。
- **`C4` 判据本体不动**：十类口径仍在 `check-applocal-sync.sh` 一处；`UNEXPECTED=6[DECL-GAP-EQ=6]`（在册声明类缺口）
  **一个数都不许动**、不许洗绿；`--selftest` 必须仍 `rc=0` 全 `PASS`。

### 第二束 `D-G96`
- **`E1` 先冻结再动手**：改脚本**之前** `cp -p` 冻结两件日志 ＋ 记 sha16/mtime；**原件一字节不许动**。
- **`E2` 不毁历史**：`PROG` 由截断改**只追加** ＋ 每趟**运行独立文件名** ＋ `*.latest`；脚本头写明"引用过的证据先冻结再重跑"。
- **`E3` 两极化**：私有 `Xvfb :191` 上，修后跑两趟 ⇒ 两趟读数**并存**、原件未变；修前形态跑两趟 ⇒ 第一趟读数**消失**。
- **`E4` 不越界**：只用 `:191`；按 PID 收干净；**不跑整脚本**（它会调 `heavy-slot.sh` 起应用）⇒ 整脚本端到端 = `NOINFO`。

### 第三束 `D-G42` 族
- **口径写死** = 现成牙 `build/MilBridge/tools/pipefail-sigpipe-check.sh` 的 **`UNDECLARED_HIT`**（本束**不改它的判据**）。
- **`F1` 逐处形态核对**：任务书给的"9 件 16 处"**逐件现场重盘**，过期/抄错**如实写**（不许为凑数改计数）。
- **`F2` 行为等价**：每处只换**喂法**，**正则/判据文本一字不动**（机械 `diff` 为空）。
- **`F3` 两极化**：牙 `UNDECLARED_HIT=0`；**不许用"声明"换绿**（声明表只许**收紧**）；至少一处 >64 KiB 成对实验；
  既有检查器判决**逐字不变**。
- **`F4` 红线**：`bash -n` 全过；需要应用/显示的件只做形态核对 ＋ `bash -n`（`NOINFO`，不抢槽）。

---

## §2 逐件 before/after sha16 ＋ 逐字 diff 摘要

### §2.1 第一束（2 件；`cp -p` 备份在 `~/w113a/backup/*.before`）

| 件 | before sha16 | after sha16 | 改了什么 |
|---|---|---|---|
| `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | `97d547551846fd13` | **`346dc4e0bf6724e8`** | `:169` 那一行**提成具名常量** `SCAN_ROOTS_DEFAULT`（**同一串、一个字节未改**）＋ 新增**只读**模式 `--print-scan-roots`（打印后 `exit 0`，不扫描不写盘） |
| `build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh` | `b56a85afd70c2321` | **`ea854808dfe3450a`** | `:59` 的**自写根集合删除**，改为**从判据唯一实现派生**；新增 `norm_roots()` 集合归一（`realpath -m` ＋ 排序去重）＋ 根集合自检（不等 ⇒ `APPSYNC_ROOTS=MISMATCH`×2 ＋ `NOINFO` ＋ `rc=2`，**在任何 `STALE=` 汇总之前**）；文件头追加修复说明 |

`diff` 逐字核对（机读）：
- `check-applocal-sync.sh`：**`diff` 全文只有 `:169` 那一个块**（旧 1 行 → 新 16 行）⇒ **十类口径、`ITEMS`、任何计数器、任何判词零改动**。
- `sync-applocal-authority.sh`：旧 157 行 → 新 205 行，**全部改动落在"根集合解析"与文件头**；判据消费（`:76` awk 解析、`do_refresh`、出口 rc）**一字未动**。

### §2.2 第三束（5 件）

| 件 | before sha16 | after sha16 | 站点 | 改法（**只换喂法**） |
|---|---|---|---|---|
| `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh` | `ddb79c4843c0aa3e` | **`ca0482bda5043909`** | `:988`/`:989`/`:1290`（3） | `printf '%s' "$x" \| grep -qE PAT` → `grep -qE PAT <<<"$x"` |
| `build/integration-wave.sh` | `4d19d69c93ba5927` | **`39e52f0049373059`** | `:321`/`:354`（2） | `printf '%s\n' "${A[@]}" \| grep -qx "$name"` → `grep -qx "$name" < <(printf '%s\n' "${A[@]}")`（**grep 看到的字节逐字节相同**） |
| `build/MilBridge/tools/frame-presence-check.sh` | `03f9800aabfee460` | **`d2a1ab5bd2fb06eb`** | `:105`/`:112`（2） | 同族 here-string（**口径自认：本件无 `pipefail` ⇒ 不是候选，属预防性对齐**） |
| `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh` | `45e46a6d9d90e69b` | **`6e2e994be056ea10`** | `:568`（1，**原为声明项**） | `grep\|head\|sed` → **先收进变量 `_kd4`、再分两路印** |
| `build/MilBridge/tools/pipefail-sigpipe-check.sh` | `a7d67a7b95b08eae` | **`078e477a59765091`** | ——（**无站点**，只动**声明表 `DECL`**） | 撤掉已修站点的声明项（**留档原文**）；`UNDECLARED_HIT` 判据一字未改 |

**"判据文本一字未动"的机械证**（脚本 `~/w113a/fixture/` 现场跑，逐件把**非注释代码行**的字符串字面量取多重集比对）：

| 件 | 非注释代码行 | 字面量差（旧独有/新独有） | 唯一变化 |
|---|---|---|---|
| `integration-wave.sh` | 289→289 | **0 / 0** | 两行的喂法（`printf \| grep` → `< <(…)`），**`"$name"` 与 `-qx` 一字未动** |
| `frame-presence-check.sh` | 112→112 | 2（都是被删掉的 `'%s'`）/ 0 | 判据 `'magenta_frames=[0-9]+'` **原样保留** |
| `run-wpftextdemo.sh` | 1236→1236 | 3（`'%s'`）/ 0 | 三个判据正则 `'\(0,0,0\)\|gray\(0\)\|srgb\(0,0,0\)'`、`'image_content'` **原样保留** |
| `run-wpfprobe.sh` | 719→722 | 1（`"$log"`）/ 5（都是新变量的引用） | 判据 `'^\[KEY_DIAG\]'` 与 `sed 's/^/WFP_KEYDIAG_ROW /'` **原样保留** |
| `pipefail-sigpipe-check.sh` | 641→640 | **3 / 0**（差的全是**被撤掉的声明行**） | 唯一删除 = `run-wpfprobe.sh:568\|…` 那一**声明** |
| `check-applocal-sync.sh` | 780→784 | 1（旧 `"${SCAN_ROOTS:-…}"`）/ 6 | **只有根集合那一个块**；`ITEMS`/计数器/判词零改动 |
| `sync-applocal-authority.sh` | 95→123 | 1（旧自写根串）/ 36 | 只有根集合解析块 |

**未改但被任务书点名的件**（现场逐位核对，= 改前值）：`defect-registry-check.sh` `dc0aeba08f9a7928`｜
`build-hygiene-import-check.sh` `545f3bd1d21b6ee8`｜`t1b-ls-tripwire.sh` `82f6a05afb1f9db9`｜
`run-hellowpf.sh` `7c832278d150c3a7`（**已含 here-string 修法**，见 §3.3 `F1`）。

### §2.3 第二束（**仓外** 2 件；`cp -p` 备份在 `~/w113a/backup/*.before`）

| 件 | before sha16 | after sha16 | 改了什么 |
|---|---|---|---|
| `~/w63a/bin/wm-leg.sh` | `aec91a0827bd9cfa` | **`2b788b5a6cde9914`** | `:13` `: > "$PROG"` → `: >> "$PROG"` ＋ `RUN_STAMP`/`RUNLOG`（运行独立名）＋ `$PROG.latest` 符号链接 ＋ `say()` 双写；**修复块 ＋ 纪律写进脚本头** |
| `~/w63a/bin/wm-leg198.sh` | `80f694dc0000ab55` | **`59a326c5d477807c`** | 同款（`:12` 的截断行），并按 `D-G96` 教训写清"引用过的证据先冻结再重跑" |

两件 `bash -n` 均 `rc=0`。⚠️ 本件**只改这两件**（`~/w63a` 下其它文件一律未碰——现场 `find -newermt` 可证）。

---

## §3 三束的**两极化成对读数**

### §3.1 第一束 `D-G91` —— 私有影子仓（真树零写）

**装置**：`~/w113a/fixture/build-fixture.sh`（`before|after`）建影子仓 `~/w113a/fixture/repo`：
`AUTH_ROOT` 指它、8 件权威件用**硬链接**（零拷贝，字节相同）、种一份**只藏在 `<影子>/tools/GeometryOracle/bin/Debug/net10.0/`
下的 `WpfGfx.Linux.dll`**（`cp` 自权威 ＋ 追加标记 ⇒ sha 不同；`touch -d 2020-01-01` ⇒ mtime 早于权威；
同目录放 `GeometryOracle.runtimeconfig.json` ⇒ 是**启动宿主**，正是 `D-G91` 的史学实例形态）。
影子仓的 `EXPECT` 段算不出来（无 csproj 图）⇒ 其 `APPSYNC=` 行为 `NOINFO`（**如实记**）；
本 fixture 只用来读 **`STALE=` / `refreshed=`** 这两格。

| 趟 | 根集合 | 读数（同刻同树） |
|---|---|---|
| **修前 A**（`sync` 默认参数 = **收窄根**，无 `tools`） | `…/build:tests:samples:src` | **`refreshed=0` ＋ 无任何 `STALE` 行** ＋ 印"（没有 STALE / NEWER-DIFF / DIVERGENT 落单者：同类加载源副本都已是权威 sha）" ⇒ **假绿** |
| **修前 B**（校验器默认根，含 `tools`） | `…:src:**tools**` | `STALE         tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll  EXPECT 374b5a538ea955aa  ACTUAL 3a43e71a2ffe8613（副本早 212167958 秒）`；`计数：… MISMATCH=1（STALE=1 …）` ⇒ **真值** |
| **修前 C**（同一把尺子只换根集合 = 收窄） | 收窄 | `计数：… MISMATCH=0（STALE=0 …）` ⇒ **与 B 直接成对：同一仪器、同一棵树、同一刻，`STALE=0` vs `STALE=1`** |
| **修后 A**（默认 = **派生根**，含 `tools`） | `…:src:tools`（**派生自判据唯一实现**） | `REFRESH tools/GeometryOracle/…/WpfGfx.Linux.dll 3a43e71a2ffe8613 → 374b5a538ea955aa`；**`APPSYNC-REFRESH=refreshed=1`** |
| **修后 B**（默认 ＋ `--apply`，真刷） | 同上 | `APPSYNC-REFRESH=refreshed=1 newer=0 applied=1`；刷后副本 sha16 = **`374b5a538ea955aa` == 权威** ✅ |
| **修后 C**（**显式收窄** `SCAN_ROOTS` = 旧默认那份） | 收窄 | `APPSYNC_ROOTS=MISMATCH sync=…`／`…check=…`（**2 行**）＋ `APPSYNC_ROOTS=NOINFO reason=narrowed-scan-roots` ＋ **`rc=2`**；该趟 **`计数：`0 行、`APPSYNC-REFRESH=`0 行、`REFRESH`0 行** ⇒ **假绿出口被物理掐掉** |

**真树（只读，修后）**：`sync` 默认参数现印
`扫描根=…/build:…/tests:…/samples:…/src:…/tools（**派生自判据唯一实现**）`，
`APPSYNC=MISMATCH（MISMATCH=0[STALE=0 NEWER-DIFF=0] MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0] DIVERGENT=0 …）`；
校验器同一行**与修前逐字相同** ⇒ `C3`/`C4` 成立（`UNEXPECTED=6` **没动、没洗绿**）。

**判据件回归**：`check-applocal-sync.sh --selftest` ⇒ **`rc=0`、`SELFTEST=PASS`、18 例全 PASS**
（`grep -c 'SELFTEST_.*=PASS'` = **18**）。

### §3.2 第二束 `D-G96` —— 私有 `Xvfb :191` 上的成对实验

**装置**：`~/w113a/fixture/pol-dg96.sh before|after`——从"修前件（备份）"／"修后件（现场）"里**逐字抽取前导块**
（抽到 `run(){` 之前；**不跑整脚本**，因为 `run()` 会调 `~/heavy-slot.sh` 起应用），
副本与原件的差异**只有一处**：`D=':197'/':198'` → `D=':191'`（隔离显示，抽取件 `diff` = **2 行/件**，即那一对 `</>`）；
`$HOME` 由 env 重定向到沙箱（**不是文件差异**），沙箱日志**先种入真实冻结证据**（逐字 `cp -p`）。

| 形态 | 第 1 趟 | 第 2 趟（= "为了复核而重跑"） | 冻结证据 |
|---|---|---|---|
| **修前**（`: > "$PROG"`）`wm.progress` | 3 行 | 3 行（**line1 变成新一轮**） | line1 **不再是证据行**；**前缀测试 = 否 ❌** |
| **修前** `wm198.progress` | 2 行 | 2 行（**line1 变成新一轮**） | **前缀测试 = 否 ❌** |
| **修后** `wm.progress` | 7 行 | **10 行**（两趟并存） | line1 **仍是** `2026-09-21 11:35:25 DISPLAY=:197 wm=_NET_SUPPORTING_WM_CHECK…`；**前缀测试 = 是 ✅**（345 → 985 B） |
| **修后** `wm198.progress` | 19 行 | **21 行**（两趟并存） | 前缀测试 = 是 ✅（1195 → 1643 B） |

**"每趟独立"机证**（修后沙箱）：两个**互不覆盖**的运行日志，各 **3 行**、内容各是本趟的：
`wm.progress.20260922T141535Z-3776439`（3 行）／`wm.progress.20260922T141535Z-3776646`（3 行）；
`.latest` → `…-3776646`（最新一趟）。
**真人读数**（修后那两趟的输出）：`WM_LEG_REUSE display=:191（真判据已 PASS ⇒ 复用在场 WM，不起新的）`、
`WM_AWAITED=PASS display=:191`、`DISPLAY=:191 wm=_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x2000ae geom=1024x768`。

**原件未动（收工核对）**：`~/w63a/logs/wm.progress` `a2ee1d7ea5451489` mtime `2026-09-21 11:37:08.087448586`；
`wm198.progress` `e0eb3cb200a5b7f2` mtime `2026-09-21 11:45:07.429170410` ⇒ **与冻结件逐位相同**；
`find ~/w63a -newermt '-45 minutes'` 只命中**我改的那两个脚本**（`logs/**` **一个都没被写**）。

**收工清理（按 PID，未用 `pkill -f`）**：`kill 3774032`（`Xvfb :191`）、`kill 3774088`（`xfwm4 --compositor=off --replace`，`DISPLAY=:191`）；
**预先存在的 `xfwm4` pid `646945`（`DISPLAY=:10.0`，不是我的）全程未碰**；`:191` socket 已清。

### §3.3 第三束 `D-G42` 族

#### `F1` 逐处形态核对（**任务书那一栏与现场有出入，如实写**）

口径 = `pipefail-sigpipe-check.sh` 的 `UNDECLARED_HIT`（逐站点**抽进沙箱真跑**、用 >64 KiB 载荷放大窗口实测 rc）。

| 任务书写法 | 现场 |
|---|---|
| `build/MilBridge/tools/run-wpfprobe.sh`（1） | **该路径不存在**；真实件 = `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh` |
| `build/MilBridge/tools/run-wpfprobe-1400rate.sh`（1） | **该路径不存在**；真实件在 `tests/…/run-wpfprobe-1400rate.sh`，且**件内无 `pipefail`（`:25` = `set -u`）** ⇒ 按口径**不是候选** |
| `build/MilBridge/tools/run-hellowpf.sh`（1） | **该路径不存在**；真实件在 `tests/…/run-hellowpf.sh` |
| `build/MilBridge/tools/defect-registry-check.sh`（3） | 件在，**但早已是修后形态**（`:157`/`:160`/`:218`/`:227` 全是 `grep … <<<"$x"`；件头 `:27`–`:36` 自己记着"本件实测有 4 处 `printf|grep -q`…**修法**：全部改成 here-string"）⇒ **0 处待修** |
| `build/MilBridge/tools/build-hygiene-import-check.sh`（2） | 件在，**早已修后形态**（`:323`/`:325`/`:378`/`:384`/`:722` 都是 `<<<`）⇒ **0 处待修** |
| `build/MilBridge/tools/t1b-ls-tripwire.sh`（1） | 件在，**早已修后形态**（`:124` 留着那条纪律注释："不能写成 `nm … \| grep -q X`"；现文 `grep -c` 是**读完型**，不会早退）⇒ **0 处待修** |
| `build/MilBridge/tools/frame-presence-check.sh`（2） | 件在、形态在，**但件内无 `pipefail`**（全文件无 `set -o pipefail`）⇒ 按口径**不是候选**；本件按**同族形态预防性对齐**修掉（不改判据） |
| `build/integration-wave.sh`（2） | 件在、形态在（`:321`/`:350`）⇒ **真候选** |
| `tests/…/run-wpftextdemo.sh`（4） | 3 处真形态（`:988`/`:989`/`:1290`）＋ **1 处是自检字面量**（`:325` `printf 'grep-selfcheck\n' \| grep -q …`：左端是**单行字面量** ⇒ 结构上不可能吃 SIGPIPE，**故意不动**） |

**另两处"自检字面量"同族、故意不动**：`run-wpfprobe.sh:100`、`run-hellowpf.sh:64`（三者都是"grep 可用性自检"，
左端单行 ⇒ `dyn_small` 恒不翻）。
⇒ **本件真修 8 处 / 4 件**（`run-wpftextdemo.sh` 3 ＋ `integration-wave.sh` 2 ＋ `frame-presence-check.sh` 2 ＋ `run-wpfprobe.sh` 1）。

#### 牙读数（同一把尺子，修前/修后）

```
修前：PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=1 files=69 sites=83 hit=1 low=12 diag=2 safe=68 runs=12
      HITLIST tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh:568
修后：PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=69 sites=77 hit=0 low=7  diag=2 safe=68 runs=12
      HITLIST （空）   ｜ SUMMARY … decl_stale=0 declared_ok=0
```
⇒ ① **唯一的活动 `HIT` 被修掉**（`hit=1 → 0`）；② **声明表变成空**（`declared=1 → 0`）——**这不是放宽判据**：
本表只**豁免** HIT，撤掉一项后 `UNDECLARED_HIT` 的判据**一字未改**（任何未声明 HIT 仍 ⇒ `FAIL`）；
③ 站点总数 `83 → 77`、`low 12 → 7`（被修的站点不再是"管道候选"）。
牙本身仍活：`--selftest` **`SELFTEST=PASS total=15 pass=15 fail=0`**（含 `S13/S14` 金丝雀双例与 `S15` 假声明必红）。

#### `>64 KiB` 成对实验（挑 `run-wpftextdemo.sh:988`，**判据文本逐字抽取**）

载荷 = `gray(0)`（**首行即命中**）＋ 4000 行填充 = **208008 B > 64 KiB 管道缓冲**；沙箱两份：旧写法（修前逐字）／新写法（修后逐字）。

| 载荷 | 旧写法（`printf \| grep -qE`） | 新写法（`grep -qE <<<"$x"`） |
|---|---|---|
| **>64 KiB、命中** | **`RING_VERDICT=inside-black` ×5/5** ⇒ **判据被翻转 = 假 FAIL**（"几何互证失败"） | **`RING_VERDICT=ok` ×5/5** ✅ |
| 小载荷（8 B）、命中（阴性对照 1） | `ok` | `ok`（**判定未被改掉**） |
| >64 KiB、**不**命中（阴性对照 2） | `inside-black` | `inside-black`（**没有把红洗绿**） |

#### 同族成对实验（`run-wpfprobe.sh:568`，原**声明项**）

同一份判据（`grep -a '^\[KEY_DIAG\]'` ＋ `head -4` ＋ `sed`），载荷 = 6000 行 `[KEY_DIAG]`（`kd-big.log` 252000 B）：

| 写法 | 语句 rc | 输出 | 结论 |
|---|---|---|---|
| 旧（修前逐字，`\| head -4 \| sed`） | **`IF_RC=141` ×3/3** | **仍然照印 4 行诊断** | 真后果 = **rc 泄漏**（数据面相关：匹配输出 >64 KiB 才翻），**不是**"诊断被丢" |
| 新（修后） | **`IF_RC=0` ×3/3** | 逐字节相同的 4 行 | ✅ |
| 对照：20 行日志（匹配输出 <64 KiB） | 旧/新都 `IF_RC=0` | 相同 | ⇒ 与"数据面"这一条自洽 |

⚠️ **更正原声明判词**（`D-G42` 声明项那句"**那 4 行诊断被静默丢掉**"）：现场实测**不成立**——诊断照印；
被 SIGPIPE 影响的是 `if` 语句的 rc（本件那个位置当时无人消费 ⇒ 属**潜在**缺陷，可能被将来的消费者或 `set -e` 引爆）。
此更正已逐字写进 `pipefail-sigpipe-check.sh` 的 `DECL` 留档块。

#### 行为等价矩阵（`~/w113a/fixture/b3/equiv.sh`）

`EQUIV cases=18 fails=0 PASS` —— 覆盖：空串／单行／多行／命中/不命中／**数组**（空数组、单元素、多元素、
**前缀不得当命中** `foo` vs `foo-bar`）。⇒ `F2`（行为等价）成立。

#### 既有检查器/自检：判决逐字不变

| 检查器 | 修前 | 修后 |
|---|---|---|
| `pipefail-sigpipe-check.sh`（全仓） | `undeclared_hit=0 declared=1 hit=1 sites=83` | `undeclared_hit=0 declared=0 hit=0 sites=77`（**变的是被修站点与声明项本身，判据未动**） |
| `shell-quote-trap-check.sh`（**同 5 件夹具**：`QT_ROOT=<修前夹具>` / `<修后夹具>`，`QT_ANCHORS=off`） | `SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=5 sh=5 py=0 diag=0 allow=0` | **逐字相同** |
| `shell-quote-trap-check.sh --selftest`（全仓） | —— | `SELFTEST=PASS total=30 pass=30 fail=0` |
| `defect-registry-check.sh`（全仓） | —— | `DEFREG=PASS declared=135 route_ids=135` ＋ `DEFREG_DECLDRIFT=0`，`rc=0`（**本件未碰登记/路由件**；`135` 是车道 W111A 这期间加号的结果） |
| `build-hygiene-import-check.sh`（全仓） | —— | `BHYGIENE_IMPORT=PASS reason=ok … undeclared=0 witness_expired=0 class_conflict=0 cand=88 cand_min=88`，`rc=0`（本件未碰任何 csproj/sln/props ⇒ 其输入集与本件改动**不相交**） |

`bash -n`：**9 件全过**（第一束 2 件 ＋ 第三束 5 件 ＋ 第二束仓外 2 件），逐件 `rc=0`。

---

## §4 证据冻结清单（`~/w113a/evidence-frozen/`）

| 冻结件 | sha16 | 尺寸 | mtime（`-p` 保留） | 与原件 |
|---|---|---|---|---|
| `wm.progress` | **`a2ee1d7ea5451489`** | 345 B | `2026-09-21 11:37:08.087448586 +0800` | `cmp` **逐字节相同** ✅ |
| `wm198.progress` | **`e0eb3cb200a5b7f2`** | 1195 B | `2026-09-21 11:45:07.429170410 +0800` | `cmp` **逐字节相同** ✅ |

顺序严格遵守：**先冻结 → 再改脚本 → 再跑两极化**。收工复算：原件 sha16/mtime **与冻结值逐位相同**（§3.2）。
`wm.progress:1` 逐字 = `2026-09-21 11:35:25 DISPLAY=:197 wm=_NET_SUPPORTING_WM_CHECK:  no such atom on any window. geom=1024x768`
（= `D-G95` 引用的**唯一现场证据行**，与 `D-G96` 判定点指向同一文件）。

---

## §5 `inputs_fp` 影响（**逐件**判断）

**覆盖面**（`build/close-wave.sh` 的 `fp_inputs()`，现场现算）= **149 件**（清单留档 `~/w113a/logs/fp-coverage-list.txt`）。

| 本件改动的件 | 在覆盖面内？ |
|---|---|
| `build/integration-wave.sh` | **在**（`find build -maxdepth 1 -name 'integration-wave.sh'`） |
| `build/MilBridge/tools/pipefail-sigpipe-check.sh` | **在**（显式清单 `#33` 那一条） |
| `build/MilBridge/tools/frame-presence-check.sh` | **在**（显式清单 `#37 F2` 那一条） |
| `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | **在**（`#49 C2/C4` 那一条） |
| `build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh` | **不在**（`#49` 有意排除：它每波尾真刷副本，纳入会把"输入稳定性"搞成噪音） |
| `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh` | **不在** |
| `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh` | **不在** |

⇒ **4 件在覆盖面内**。

**值（现场取，方法可复算）**：`fp_inputs()` 只按**相对路径**读文件 ⇒ 我在 `~/w113a/fixture/fp-farm/` 建了一个
**只含那 149 件**的目录结构（硬链接）：
① 先用**修后**内容跑 ⇒ `d67880cbb8487cfd386bde0648e647624ffdf8d800a892297f93d03d6f9fefb0`，
**与真树现算值逐字符相同**（⇒ farm 方法**被验证**）；
② 把其中**在覆盖面内的 4 件**换成**改前**内容（`rm` 掉硬链接再 `cp`，**不动真树**）⇒ 得"改前"值。

| | `inputs_fp` |
|---|---|
| **改前** | `58a6c0945b7d535830ce3e3e4f25752b68f3714d3f35f540253eca6e69b3dd36` |
| **改后** | `d67880cbb8487cfd386bde0648e647624ffdf8d800a892297f93d03d6f9fefb0` |

⇒ **本件确实改变 `inputs_fp`**（差值**归因到本件的 4 件在覆盖面内的改动**）。
⚠️ 两地都**不等于 `#51` 冻结值**，这是**预期的、不是异常**：覆盖面里还有别的车道在飞的改动
（例如 W112A 改 `src/WpfGfx.Linux.Native/**` 的 `.c/.h` **就在覆盖面内**；W111A 改的登记/路由件**不在**覆盖面内）。
本件**没有**跑 `close-wave.sh`／`verify-all.sh` ⇒ `IN_FP_0/IN_FP_1` 的"波前==波后"断言**本件不代跑**（波尾由收尾链记账）。

---

## §6 `NOINFO` ／ 未端到端跑清单（**既不算绿也不算红**）

1. **第一束 fixture 的 `EXPECT` 段**：影子仓没有 csproj 引用图 ⇒ 校验器印
   `APPSYNC=NOINFO（期望集合算不出来 …）`、`rc=3`。**如实记**：本 fixture **只**用来读 `STALE=`/`refreshed=` 两格，
   `UNEXPECTED`/`MISSING` 等格在 fixture 里**不可用**；真树那两格是另测的（§3.1 末段）。
2. **第二束整脚本端到端**：**未跑** `wm-leg.sh`／`wm-leg198.sh` 整脚本 —— 硬理由两条：① 它 `run()` 会调
   `~/heavy-slot.sh` 起**应用**（本件纪律禁）；② 整脚本会走到 `run()` 去抢重活槽（槽要让给 W112A）。
   ⇒ 本件只做**逐字抽取前导块**的两极化。**取不到的读数** = "整脚本在真 WM 上跑到 `run()`"。
3. **第三束需要应用/显示的件**：`run-wpftextdemo.sh`、`run-wpfprobe.sh`（`build/MilBridge/tools/` 下那三个路径**不存在**）、
   `run-hellowpf.sh`、`run-wpfprobe-1400rate.sh`、`frame-presence-check.sh --selftest`（它要真帧目录/ImageMagick）
   ⇒ **只做 `bash -n` ＋ 逐处形态核对 ＋ 沙箱行为等价矩阵**，**未端到端跑**（不抢槽）。
4. **`integration-wave.sh` 的两处**：件本身要整波构建才能跑到 ⇒ 只做 `bash -n` ＋ 等价矩阵 ＋ 牙的静态/动态判定，
   **未在真波里跑**。
5. **`D-G42` 声明项判词的更正依据**：现场只实测到"rc=141 泄漏"（3/3 @252 KB / 0/3 @小日志）；
   "本件那个位置当时是否真的有人消费那个 rc"**未做全调用栈追证**（本件读到的位置无人消费）⇒ 结论按"潜在"记。
6. **`D-G91` 真树"修后默认参数在真树上刷到过什么"**：真树当下 `STALE=0` ⇒ 真树上**没有**可供刷的对象，
   "刷到"这条只能在 fixture 上证（已证）。真树只证"计数器逐字不变 ＋ 根集合已一致"。

---

## §7 自伤 / 作废趟（如实留档）

1. **任务书路径抄错 3 件 → 我按现场纠正**（`build/MilBridge/tools/{run-wpfprobe,run-wpfprobe-1400rate,run-hellowpf}.sh`
   都不存在，真实件在 `tests/WpfGfx.Linux.Tests/Presentation.Tests/`）。
   **同一份任务书把 `sync-applocal-authority.sh` 写在 `build/MilBridge/tools/`，现场在
   `build/DirectWrite.Linux/wic-shim/`** ⇒ 若照抄路径，三束里有两束会"打不开文件"。
2. **我修第三束时**（第一次）**没有先 `cp -p` 备份**（纪律要求"改既有文件前备份并报 before/after sha16"）——
   补救方式：before sha16 **不是手抄**，而是取自**本会话先前现场的 `sha256sum` 读数**（`ddb79c48…`／`45e46a6d…`／
   `4d19d69c…`／`03f9800a…`），并**与 fork 克隆 `~/netTest/GitProj/WPFOnLinux` 的 HEAD 件逐字节交叉证实**
   （4 件全部相同）；`pipefail-sigpipe-check.sh` 的 before 件是**从修改后的文件反向重建**得到
   （`a7d67a7b95b08eae`），也已**与克隆 HEAD 逐字节相同** ⇒ 该值可信。备份件现齐（`~/w113a/backup/*.before`）。
   ⚠️ **这是本件的流程违规，如实记**（补救后证据链闭合，但当时那一趟确实没备份）。
3. **第二束 harness 自己的探针错误**：第一版把 `wm198.progress` 的"证据行"错取成 `wm.progress:1` ⇒ 打出一条
   **假**"证据行已被抹掉 ❌"。已改成"每个日志取**自己**的第一行"＋"**前缀测试**（冻结件是否仍是当前文件的前缀）"，
   并把两种模式的沙箱分开（第一版两种模式共用一个沙箱 ⇒ before 的读数被 after 覆盖）。
   **两条读数都作废，报告里给的是更正后的读数**。
4. **第二束修法第一版有真缺陷（我自己在复跑时抓到）**：`RUN_STAMP` 只到**秒** ⇒ 同一秒内起的两趟**撞进同一个
   运行独立名**（首轮 after 跑实测：一份日志里混着两趟的 3+3 行）。已加 `-$$`（秒＋PID）并**复跑**两极化。
   ⇒ 现在的"两趟各有独立日志"读数出自**加 `-$$` 之后**的版本（`wm-leg.sh` `2b788b5a6cde9914`）。
   注：即便撞名也**不会丢数据**（只追加），只是"逐趟可分辨"这条性质不成立。
5. **`grep -Fxq -e` 引文核对**：本件所有"逐字引"都用 `grep -Fxq -e` 核过；`~/w113a` 下自查脚本一条
   `grep -c '^[<>]'` 的引号写法把 `<>` 当重定向解析 ⇒ 那一行的**计数打印不可信**（3 处），
   已改用独立命令重算（§3.2 的"抽取件 diff = 2 行/件"就是重算值）。
6. **未跑** `verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／任何构建（纪律）；**未跑** R-GATE 相关件。

---

## §8 大白话小结（≤6 行）

1. **`D-G91` 修好了**：刷新器和校验器**共用一份根集合定义**（校验器新增只读 `--print-scan-roots`，刷新器从它派生）；
   谁再收窄根，刷新器就**大声 `APPSYNC_ROOTS=MISMATCH` ＋ `rc=2` 并拒绝打印 `STALE=0`** ⇒ 假绿的路被堵死。
   影子仓成对读数：修前"收窄根 `STALE=0`"vs"全根 `STALE=1`"；修后默认参数**刷到了**那份 `STALE`，真树计数器**一字未变**。
2. **`D-G96` 修好了**：先 `cp -p` 冻结了 `wm.progress`／`wm198.progress`（逐位相同、原件全程没被写），
   再把两个脚本的 `: > "$PROG"`（截断）改成**只追加 ＋ 每趟独立文件名（秒-PID）＋ `.latest` 符号链接**。
   私有 `:191` 上：修前重跑**把证据抹掉**（前缀测试否），修后**两趟并存、证据行还在**（前缀测试是）。
3. **`D-G42` 族**：任务书的"9 件 16 处"有 3 件路径抄错、3 件早就是修后形态、2 件件内根本没 `pipefail`；
   我真修 **8 处 / 4 件**（含把牙里唯一那条**声明**也撤了 —— 撤声明不是放宽，是自洽）。
   牙读数 `hit 1→0`，`undeclared 0`，>64 KiB 成对里**旧写法判错 5/5、新写法判对 5/5**，等价矩阵 18/18。
4. 顺手**更正一条旧判词**：`run-wpfprobe.sh:568` 那句"4 行诊断被静默丢掉"**不成立**（诊断照印），
   真后果是 `if` 语句 rc=141（数据面相关、当时无人消费 ⇒ 潜在）。
5. **`inputs_fp` 会变**（4 件在覆盖面内）：`58a6c094…` → `d67880cbb8…`（用"只含覆盖面的硬链接 farm"算的，
   先验证 farm 能复现真树值）；不等于 `#51` 是**正常**的（另有车道在动覆盖面内的件）。
6. **没做**：三束都**没跑整脚本/整波端到端**（都要起应用 ⇒ 缺 `NOINFO`）；`~/w63a` 只改了两个脚本、日志一字节未动；
   X 用 PIDs 收干净（预存的 `:10.0` 上那个 `xfwm4` 全程没碰）。
