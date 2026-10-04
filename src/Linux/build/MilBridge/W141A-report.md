# W141A 报告 —— 波 `#55` 收尾链 **①–⑫** 一步到底

**车道** W141A ｜ **开工** 2026-09-23 21:1x +0800 ｜ **机器** `nproc=4` ｜ `MemAvailable` 开工 **4,260 MB**
**交付** 本报告 ｜ 判据 `~/w141a/criteria.md`（**先写**，`97b2e9825040a061`）｜ 台账 `~/w141a/STATUS.md`
**模板** `~/w129a/dispatch-CLOSE-54.md`（11 步清单）＋ `build/MilBridge/W140A-report.md`（`#54` ⑨–⑫）＋ `~/w139a/STATUS.md`（`#54` ①–⑧）
**本波产品改动** = `TASK-0209`（修 `win32_msg.c:57-82` 队列链遍历 ＋ 给"写坏者"取证），判 **`D-G109`** 静默 SEGV；
**只冻结不改**：本车道**一个字节都没改 `src/**`**（产品件由车道 W136A 落仓，主控已复核五格）。

---

## ① 判据（**先写**；含本波新增的「空盘预检」）

件：`~/w141a/criteria.md`（写定 2026-09-23 21:1x，sha16 **`97b2e9825040a061`**，**早于任何重活**）。
**如实声明**：本车道**不新发明波级判据** —— 波级判据先写于车道 W136A 的 `~/w136a/criteria.md`（`ea19ce8d7b008b0c`，17:14）。
**本车道自己写的第一条 = `C0` 空盘/可写预检**（本波新增入册的方法学），写进 `STATUS.md` 的 `[H0]`，**早于**任何重活。

| # | 判据 | 绿 | 红 / 停手 |
|---|---|---|---|
| **C0** | 空盘/可写预检（**本波新增**） | `df --output=avail /` ≥ 5 GiB **且** `/tmp` 可写自检 | 不满足 ⇒ **停下报主控，不许硬跑** |
| **C1** | 九位位移 = 只有两位 | `changed == {win32shim, pf}`；`bridge` **仍 `4e25e4b27d4d5ae1`**；其余六位逐位不变 | **任何第三位变 ⇒ 停手报主控** |
| **C2** | `win32shim` 件级 | 整波/`build-shim --all` 前后都是 `2067cb1c97728791`（**逐字节复现**）；导出仍 **547** | 不符 ⇒ 停手 |
| **C3** | 冻前 `verify-all` | **恰好 1 处声明类红 = `COLUMN-FLOOR`**；`用例通过 875`；`X_STATE=available`；`[0]` 段 `X-REUSE=reused` 且几何 `1280x1024` | 第 2 处**非声明类**红 ⇒ 先按 `C6` 判 `ENOSPC`，否则停手 |
| **C4** | 两趟之间不许换件 | 冻后两趟 `[26] R-GATE` 的 `win32shim=` 逐字相同 | 不同 ⇒ 该趟作废 |
| **C5** | 五臂重取 | **先写预测**再取；判词与 `#54` 冻结块逐字同形；`ARMLOG_SHA=PASS pass=5 fail=0` | 不符 ⇒ 点名 |
| **C6** | `ENOSPC` 作废趟的记法 | 记「作废（环境成因，非读数）」并与有效趟**并列**；`rc=2` 是 `NOINFO` **不是** `FAIL` | 当红或隐瞒 |
| **C7** | 冻结 `#55` | 四颗牙全 PASS（`BASELINESHA`／`BASELINEGEN decl_gen=#55`／`BASELINE_BYTES`／`BASELINEDUP n=0`）；`FREEZE_RC=0` | 任一 FAIL ⇒ 停 |
| **C8** | 冻后 `verify-all` ×2 | 两趟均 `27 ✅ / 0 ❌` ＋ `结论：✅ 全部通过` ＋ `用例通过 875 跳过 2`；判据行逐字同形，运行期差异**逐条点名** | 任一不成立 |
| **C9** | 推送（逐径） | `porcelain` 行数 == `--cached` 件数；**逐径 `git add`（绝不 `-A`）**；push 后**重新 `fetch`** ＋ `HEAD == origin/feat-Linux == ls-remote`；`--symref` 仍 `feat-Linux`；`BYTECHECK mismatch=0` | 任一不成立 ⇒ 停 |
| **C10** | 推送边界 | 登记三件（`ROUTES.md`／`KNOWN-DEFECTS.md`／`declared.tsv`）**一件不 add**；`$R` 独有件单列「本地领先」 | 混入其一 |
| **C11** | app-local | `STALE=0 DIVERGENT=0 MISMATCH=0 MISSING=0`；**`APP_ART win32shim=2067cb1c97728791`** | 计数器非 0（在册缺口除外） |
| **C12** | 哨兵两处 | 两处 `cmp` `IDENTICAL`；**`WIN32SHIM=2067cb1c97728791`** | 不一致 / 旧值 |
| **C13** | 方法学留痕 | `ENOSPC ⇒ rc=2 NOINFO 被汇总计成 ❌` 这条**逐字**进记录与报告 | 未写 |
| **C14** | 写域 | 只写任务书列出的件；**不许改 `src/**`**；他车道目录只读 | 越界 |
| **C15** | `NOINFO` 口径 | `NOINFO` **既不算绿也不算红**，逐条登记、不猜 | 拿 `NOINFO` 当绿 |

**两条"预授权"件**（主控已批，同 `#53`/`#54`/`#56` 先例）：`verify-all.sh` 两处声明改 `gen=#55`（**步名/步数一字不动，仍 27**）；
**新建** `docs/WAVE55-PREREGISTRATION.md`（**标题行必须含 `#55`**）。

---

## ② 空盘/可写预检读数（判据 `C0`）—— **每条重活趟之前都做**

```
df --output=avail / | tail -1      ⇒  74,679,264 – 77,808,952 KB（≈ 71.2 – 74.2 GiB）   （判据 ≥ 5 GiB ⇒ 通过）
printf x > /tmp/w141-$$.t && rm -f ⇒  TMP_WRITE=OK
PRECHECK=PASS df_avail_kb=… min_kb=5242880 tmp_write=OK
```
**本波零 `ENOSPC` 趟**。**背景（为什么加这条）**：`#54` 冻后第 2 趟就是被**瞬时 `ENOSPC`** 毁掉的 ——
`THIRD-PARTY`／`R-GATE`／`NUL-BYTES` 三步报 **`rc=2 NOINFO`**（仪器日志写不出），而 `verify-all` 汇总把它计成
**`❌ 失败项`** ⇒ **那是环境成因、不是回归**；正确处置 = 记「**作废（环境成因，非读数）**」＋ **重跑**。

---

## ③ 整波 / 五臂 / 重钉 逐件 before→after

### ③.1 ① native 复现 ＋ 整波重建（槽 `waited=0s`／`held=2s`／`max_hold=600`；整波 `held=210s`／`max_hold=1200`）

- **native**：`cd src/WpfGfx.Linux.Native && ./build-shim.sh --all` ⇒ 产物 `bin/libwpfwin32.so`
  **重建前后 sha16 都是 `2067cb1c97728791`**（327,672 B）⇒ **逐字节复现**（判据 `C2` ✓）；
  `== 导出符号总数：547`（**不变**）；ABI 段 `结果：全部一致（编译期 _Static_assert 亦已通过）`。
  ⚠️ 一条**既有**告警如实记：`src/win32_misc.c:224 -Wmisleading-indentation`（`GetDpiForMonitor`）——**不是本波落点**，**未处置、只报**。
- **整波**：`WAVE_OWNER=W141A bash build/close-wave.sh --skip-verify-all` ⇒ **`CLOSEWAVE_RC=0`**
  ｜`OUT=/home/links-dev/wfp-runs/close-wave-205345`
  ｜`[1/6]` **`rc=0`**｜**`APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0`**
  ｜**`=== 集成波结束：失败步骤 0 ===`**（`close-wave.log:179`）
  ｜`[2/6]` native `源码不比权威件新 ⇒ 跳过重建`｜`[3/6]` 桥 `源指纹一致（d697b1e10ff48881 == d697b1e10ff48881）⇒ 无需重发`
  ｜`[4/6]` 桥源指纹两侧一致 ✓／生成物指纹 `state=ok` ✓／应用器审计 `miss=0` ✓
  ｜**`输入稳定性：波前==波后 == 1344571ddaafcf2f143fd3a8f06ee0c795c93df9ab53e9716a4d0c0ee4b70cca`**
  ｜`[6/6]` 哨兵已同步（`/tmp` ＋ 镜像）
- **波后九位**（`close-wave-summary.txt`）：`bridge=4e25e4b27d4d5ae1`｜`pc=722e0ab8205b7c3f`｜
  **`pf=f2df3c2b464b7f00`**（`ec570d30f6754631` → 变）｜`windowsbase=2e4e46e539a72cd7`｜`provider=1f9511a7ef395bfe`｜
  **`win32shim=2067cb1c97728791`**｜`wic_shim=f7b3026c8c019be2`｜`hbtextline_shim=921ba9c65e9fb3be`｜`dwf=ce3469f49efcbcfa`
  ⇒ **`changed = {win32shim, pf}`**、**`bridge` 逐位不变** ⇒ **逐字命中判据 `C1`**（**无第三位变**）。
- ⚠️ **如实记**（`#54` 同形已有前例，**不是本波位移、不是停条件**）：波内 `[4/6]` 的 `APPSYNC` 报
  `⚠️ APPSYNC 非 PASS`（在册 `UNEXPECTED=6[DECL-GAP-EQ=6]` 告警语义，见 ⑨）。

### ③.2 ② 五臂重取（`retake-arms-w23.sh`，`ARMS_OUT=$HOME/wfp-runs/arms23`；槽 `held=348s`／`max_hold=1200`）

**预测（取数之前写定）= 只有 `tline` 会变**，依据 = 现场 `grep -c 'win32shim\|libwpfwin32' build/MilBridge/arm-logs/*.log` = **0/0/0/0/0**
（五臂日志**都不含权威件 sha**）⇒ 本波唯一产品位移（`win32shim`）**不进任何臂日志**。**实测命中**：

| 臂 | before（`#54` 冻结点） | after | 结果 |
|---|---|---|---|
| `tline` | `664a0c048a1ed3a1` | **`a46cb0b4e853fa1f`** | **变**（该日志含 app-local 同步行／耗时／日期戳／上一趟 artifact mtime）✓ |
| `tab-zero` | `9150c3a26a3cb789` | `9150c3a26a3cb789` | 逐位不变 ✓ |
| `tab-anchor` | `1c43a12dcaa5718a` | `1c43a12dcaa5718a` | 逐位不变 ✓ |
| `tab-rtl` | `92570318851ca7e8` | `92570318851ca7e8` | 逐位不变 ✓ |
| `textlineproto` | `4bceceeed570ba70` | `4bceceeed570ba70` | 逐位不变 ✓ |

**五臂判词与 `#54` 冻结块逐字相同**：`tline 通过 22 / 失败 2`（rc=1）｜`tab-zero 退出码=1`
（未登记失败 1/共 1，唯一 = `notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白 期望=0 实得=1`）｜
`tab-anchor 退出码=0`（`START 红=0 绿=615 判定行=615`／`OVERFLOWED 红=0 绿=421 判定行=421`／字形释放行=194）｜
`tab-rtl 退出码=0`（`红=0 绿=0 判定行=0 NOINFO=163`）｜`textlineproto rc=0`（`通过 4 / 失败 2`）。
`ARMS_DISPLAY=:97 source=reused`（**复用**已存在的 `:97`，**未自起、未碰任何人的 X**）；
取臂前自证：`shim=921ba9c65e9fb3be`｜`pc=722e0ab8205b7c3f`｜`run.sh=711f39f468f61cc8`｜`Parity.cs=149dd986a642fdfc`。

⚠️ `ln -f` 造出 `nlink=2`（仓内既定机制）⇒ 按 **`TASK-0502` 波尾必做②**把**别名侧** `~/wfp-runs/arms23/*.log`
改成**真副本**（`cp -p` 同目录临时名 ＋ `mv -f`；**只动 `~/wfp-runs/arms23/**`**）：五件 `nlink 2 → 1`、
inode 互不相同（`5136074`–`5136078`）、逐件 `cmp` = **IDENTICAL**，**权威侧 `arm-logs/*.log` 五个 sha16 逐位未变**。
**`TASK-0502` 波尾必做①** = `sync-applocal-authority.sh --apply`（见 ⑨）。

### ③.3 ③ 重钉世代（`repin-generation.py`）

- `--check` **前**：**`REPIN_GENERATION=FAIL n=2`**（`generation.arm_logs.tline` 不一致；`evidence_log_sha256 声明=664a0c048a1ed3a1 现场=a46cb0b4e853fa1f`）`rc=1`
  —— **顺序不是矛盾**（`#54` 先例逐字同形）。
- `--why '<五条理由>'` ⇒ **`REPIN_GENERATION=APPLIED`**（`rc=0`）：`instr_run_sh=711f39f468f61cc8`｜
  `instr_program_cs=149dd986a642fdfc`｜`instr_shim=921ba9c65e9fb3be`｜**`evidence_log_sha256=a46cb0b4e853fa1f`**
  ｜**`entries[*].caliber 改动字段数 = 0`**（**只动世代记账，没碰任何判据口径**）。
- `--check` **后**：**`REPIN_GENERATION=PASS`** `rc=0`。件：`build/MilBridge/known-red.json` **`47554efd60b4554f` → `433d2d371787c004`**。
- **`inputs_fp`**（**真函数**现算 —— 从 `build/close-wave.sh` 就地抽 `fp_inputs()` 的**逐字文本**再 `eval`，**不复制函数体**）：
  `1344571ddaafcf2f143fd3a8f06ee0c795c93df9ab53e9716a4d0c0ee4b70cca` → **`ca0a768162af87f88d8b84d777a66b769da8a74ea3e5ab273741f781c0e50e20`**（两趟现算**逐位相同**）。
  **归因（机械，不是推理）**：`fp_inputs()` 覆盖面现场 = **149 件**，与 `#54` 的覆盖面清单（`~/w139a/logs/14-coverage-list.txt`）**逐行 IDENTICAL**；
  其中 **mtime 晚于整波开工（`2026-09-23 20:53:45`）的件恰 1 件 = `build/MilBridge/known-red.json`（mtime 21:04:34 = 本次重钉）**
  ⇒ **这一跳唯一可归因到重钉**。
  ⚠️ **另记一条如实**：本代开工时的 `1344571d…` **已 ≠ `#54` 冻结点声明值 `5ba63099…`** —— 成因 = W136A 落仓时对
  `known-red.json` 的**自动重钉**（`4e9c2dbe…`）与主控现算，**都发生在本车道开工之前**，与本车道无关。
- **冻结器 `GENS['#55']` 已追加**（`~/w21-verify/w27-freeze.py` `57ab388eefcbd227` → **`1dda5297af0c8e2d`**，`py_compile` rc=0，老代一字未动）；
  `PRE=/home/links-dev/w141a/w55-pre.sha`（`5d490dfca04f507f`，9 行）、`prev='#54'`、`allow_changed={'win32shim','pf'}`、`pf_required=False`、
  `infp=ca0a7681…0e50e20`（**收紧为精确值，未放宽**）、`prev_infp=5ba63099…7365`、`bs_fp=d697b1e10ff48881`。

---

## ④ ④ 门禁 ×2（**两趟各 rc=0**；槽 `waited=13s`／`held=336s`／`max_hold=800`）

| 趟 | 显示 | 读数 |
|---|---|---|
| 1 | `WPTD_DISPLAY=:213` ⇒ `== 启动自己的 Xvfb :213（1280x1024x24）` | **`GATE1_OUTER_RC=0`**｜rows = `~/w141a/gate-rows.txt`（**`d23f36b3b535d229`**） |
| 2（`--no-build`） | `WPTD_DISPLAY=:214` ⇒ `== 启动自己的 Xvfb :214（1280x1024x24）` | **`GATE2_OUTER_RC=0`**｜rows = `~/w141a/gate-rows-f.txt`（**`c68021075a54a9f9`**） |

- **两趟各 6 条 `BASELINE` 行／6 个 `result=PASS`／0 个 `result=FAIL`**（`default 3/3` ＋ `env 3/3`）⇒ **门禁本波 12/12 PASS**；
  `WPTD_SUMMARY=PASS tiers_passed=2/2`｜`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`｜
  `WPTD_BRIDGE_SRC_STALE=no basis=pub=d697b1e10ff48881 now=d697b1e10ff48881 so_file_match=yes`。
- **两本 `config=` 段逐字相同**（`diff` 空 ⇒ `CONFIG_IDENTICAL`）=
  `pc:722e0ab8205b7c3f`／**`bridge:4e25e4b27d4d5ae1`**／**`pf:f2df3c2b464b7f00`**／`provider:1f9511a7ef395bfe`／
  **`win32shim:2067cb1c97728791`**／`wic_shim:f7b3026c8c019be2`／`hbtextline_shim:921ba9c65e9fb3be(stale:no)`
- ⚠️ 两趟**各自自起** `1280x1024x24`（**只用空闲 `:2xx`**，不依赖别人的 X、**没杀任何人的 X**）；收工后 `/tmp/.X11-unix/` 只剩 `X0/X1/X92/X97/X99` ⇒ **本车道零残留**。

---

## ⑤ 冻前 `verify-all`（判据 `C3`／`C6`／`C13`）—— **一条作废趟 ＋ 一条有效趟并列**

### ⑤.1 ⚠️ 作废趟（**会话工具链中断 ⇒ 环境成因，不是读数**）

本车道第 1 次冻前 `verify-all` 是**前台**跑的：本会话工具链有 **600 s 前台上限**，`timeout 1450 bash verify-all.sh`
当时仍在跑（PID 1683127）⇒ 被 **SIGTERM** 中断 ⇒ **输出管道已断、读数不可用**。
**处置**：记「**作废（会话工具链中断，环境成因，非读数）**」；**按 PID** 收掉残留（`kill 1683127` ＋ 三个 MSBuild node；
**全程未用 `pkill`／`killall`／`pgrep -f`**）；改为**后台**重跑（有效趟见 ⑤.2）。

### ⑤.2 有效趟（后台；槽 `--min-avail 1500 --max-hold 1500 --wait 1800`）

日志 `~/w141a/logs/16-verify-pre.log`（**`58a674720987dabc`**，118 行）｜槽 **`RELEASED rc=1 held=1030s`**｜**`PRE_OUTER_RC=1`**

```
  [0] Xvfb（目标 :99）
    ✅ X-REUSE=reused display=:99（:99 上已有可用 X server，几何 1280x1024 相符而复用）
    X_STATE=available（判据：xdpyinfo 对 DISPLAY=:99 成功 ⇒ available）
  …
  COLUMN-FLOOR                 ❌  (rc=1)
      COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline
      COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0 selfreport=PASS reg=433d2d371787c004 base=f9948196858bc9db corpus=0cebc0afd5142fbf
  …
 步骤通过 26  ❌ 失败 1
 用例通过 875  跳过 2
 SKIP_GUARD=PASS x_state=available x_died=0 x_suite_skipped=0 x_suite_units=0 x_suite_corpus_max=0 total_skipped=2 violations=none reason=none
 结论：❌ 失败项：COLUMN-FLOOR
```

⇒ **恰好 1 处红、且是设计内的声明类红**（`COLUMN_FLOOR_ARMLOG=FAIL … bad= tline` ∧ `selfreport=PASS`）⇒ **判据 `C3` 逐字命中**。
其余关键机读行：`BASELINESHA=PASS live=f9948196858bc9db decl=f9948196858bc9db`｜`BASELINEGEN=PASS decl_gen=#54 file_newest_gen=#54`｜
**`ARMLOG_SHA=PASS shape=flat … required=5 declared=5 pass=5 fail=0`**（③ 重钉已让它转绿）｜`DEFREG=PASS declared=147 route_ids=147`｜
**`VERIFYALL_SELF=PASS names=27 decl=27 gen=#55 dup=0 order=OK prose=OK prereg=PASS vfile_sha16=80455e8d5eb92cb3`**｜
`FP_INPUTS_HYGIENE=PASS coverage_n=149 artifact_n=0`｜**`R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938 mem_mb=4607 win32shim=2067cb1c97728791 pc=722e0ab8205b7c3f src=device`**｜
`NULBYTES=PASS files=1231 hits=0 bytes=252906199 canary=ok`｜`THIRDPARTY=PASS frames=40 max_colors=1642 min_colors=800`｜
`SHELL_QUOTE_TRAP=PASS traps=0`｜`PIPEFAIL_SIGPIPE=PASS hit=0`。

**预授权两件现场读数**：`verify-all.sh 4bcc0cf7aab10bb5 → 80455e8d5eb92cb3`（**只加两行**；`bash -n` rc=0；`^run_step "` **27→27**）；
**新建** `docs/WAVE55-PREREGISTRATION.md`（`5c062a33a2b0eb17`）—— **补建前**实测第 `[11]` 步
`VERIFYALL_SELF=NOINFO reason=prereg-absent gen=#55 扫了 35 件 docs/WAVE*-PREREGISTRATION.md，本代号没出现在任何标题行里`（`rc=2`），
**补建后** `prereg=PASS`。两件**都不在** `fp_inputs()` 覆盖面内 ⇒ **不动 `inputs_fp`**。

---

## ⑥ 冻结 `#55`（判据 `C7`；`FREEZE_RC=0`，**一次成功**）

`python3 ~/w21-verify/w27-freeze.py ~/w141a/logs/16-verify-pre.log ~/w141a/gate-rows.txt '#55'`（槽内 `held=1s`）：

```
世代交叉断言通过：树上 #54 == GENS[#55][prev]
  · 冻前声明类红项 = ['COLUMN-FLOOR']（冻后必须转绿）
verify-all = 27 步（通过 26 / 失败 1；其中声明类 ['BASELINE-SHA', 'ARM-LOG-SHA'] 应为红、其余全绿） / 875 通过 2 跳过
牙齿②：`verify-all.sh` 的 `^run_step "` = 27 == 步数 27，且头注释逐字声明了同一数字
  冻结器读的九位路径配置 = Release（来自唯一声明 build/SelfBuiltConfig.props）
九位 = {'bridge': '4e25e4b27d4d5ae1', 'pc': '722e0ab8205b7c3f', 'pf': 'f2df3c2b464b7f00',
        'windowsbase': '2e4e46e539a72cd7', 'provider': '1f9511a7ef395bfe', 'win32shim': '2067cb1c97728791',
        'wic_shim': 'f7b3026c8c019be2', 'hbtextline': '921ba9c65e9fb3be', 'dwf': 'ce3469f49efcbcfa'}
相对开工前变化的位 = ['pf', 'win32shim'] ｜inputs_fp = ca0a768162af87f88d8b84d777a66b769da8a74ea3e5ab273741f781c0e50e20 ｜BRIDGE_SRC_FP = d697b1e10ff48881
本波位移 = ['pf', 'win32shim']（在本代声明的允许集合 ['pf', 'win32shim'] 内，且不是"只有 pf"那一种）⇒ 如实记录
本代声明允许位移、且真的动了的位 = ['win32shim']（其余八位逐位与开工前相同）
门禁 6 条机读行 OK（pc:722e0ab8205b7c3f pf:f2df3c2b464b7f00）
基线已重冻为 #55；整份 sha16 = 38320d5e377a0dc8
BASELINESHA=PASS live=38320d5e377a0dc8 decl=38320d5e377a0dc8
BASELINEGEN=PASS decl_gen=#55 file_newest_gen=#55
BASELINE_BYTES=785675
BASELINEDUP=PASS n=0
✅ 机器行 gen=#55 sha16=38320d5e377a0dc8 已对上，核对器 rc=0
ARMLOG_SHA=PASS shape=flat … required=5 declared=5 pass=5 fail=0 noinfo=0
COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=433d2d371787c004 base=38320d5e377a0dc8 corpus=0cebc0afd5142fbf
✅ 两极化齐：冻前 BASELINE-SHA/ARM-LOG-SHA/COLUMN-FLOOR(ARMLOG) 红 ⇒ 冻后同一批检查器都绿
```

**四颗牙**：`BASELINESHA=PASS`／`BASELINEGEN=PASS decl_gen=#55`／`BASELINE_BYTES=785675`／`BASELINEDUP=PASS n=0` ⇒ 全 PASS。
`ACCEPTANCE-BASELINE.md`：`f9948196858bc9db`（767,600 B）→ **`38320d5e377a0dc8`（785,675 B）**；
`# RE-FROZEN #55` 成为文件首块，`#54` 块降级为 `# ⏪ **（历史，已被 `#55` 取代）**`。
`docs/CURRENT-STATE.md:9` ⇒ `BASELINE-FROZEN gen=#55 sha16=38320d5e377a0dc8`。
记录件 `~/w21-verify/w55-record.txt`（生成器 `~/w141a/bin/make-record-w55.py`；落盘前机械自检：三段标记齐全／
**8 条外挂声明行全带 `# ` 前缀且在 `===FROZEN===` 段里**／无"连续两个 `@`"残留／占位符名合法）。

### ⑥.1 与 `#54` 逐位比（**预期只有 `win32shim` ＋ `pf` 变**）

| 位 | `#54` 冻结点 | `#55` 冻结点 | 位移 |
|---|---|---|---|
| `bridge` | `4e25e4b27d4d5ae1` | `4e25e4b27d4d5ae1` | **不动** ✓（本波产品改动全在 native shim） |
| `pc` | `722e0ab8205b7c3f` | `722e0ab8205b7c3f` | 不动 ✓ |
| `pf` | `ec570d30f6754631` | **`f2df3c2b464b7f00`** | **变**（`D-G92`：不是构建身份；同尺寸 6,123,520 B） |
| `windowsbase` | `2e4e46e539a72cd7` | `2e4e46e539a72cd7` | 不动 ✓ |
| `provider` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | 不动 ✓ |
| **`win32shim`** | `a6365183fa6d26b9` | **`2067cb1c97728791`** | **变**（`TASK-0209`，产品位移；327,512 → 327,672 B） |
| `wic_shim` | `f7b3026c8c019be2` | `f7b3026c8c019be2` | 不动 ✓ |
| `hbtextline` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | 不动 ✓ |
| `dwf` | `ce3469f49efcbcfa` | `ce3469f49efcbcfa` | 不动 ✓ |

⇒ **`changed = {win32shim, pf}` 逐位命中判据 `C1`**（**无第三位变**）。`bridge-src-fp` = `d697b1e10ff48881`（**与 `#54` 逐位相同** —— 桥源一行未改）。

---

## ⑦ 冻后 `verify-all` ×2（判据 `C8`／`C4`）—— **两趟都 27 ✅ / 0 ❌**

| 趟 | 日志 | 槽 | 结论 |
|---|---|---|---|
| 1 | `~/w141a/logs/18-verify-post1.log`（**`a905bf3c041bd382`**） | `RELEASED rc=0 held=927s`（`max_hold=1500`） | **`步骤通过 27  ❌ 失败 0`**／`用例通过 875  跳过 2`／**`结论：✅ 全部通过`**／`POST1_OUTER_RC=0` |
| 2 | `~/w141a/logs/19-verify-post2.log`（**`d27486bddc3c118e`**） | `RELEASED rc=0 held=1000s`（`max_hold=1500`） | **`步骤通过 27  ❌ 失败 0`**／`用例通过 875  跳过 2`／**`结论：✅ 全部通过`**／`POST2_OUTER_RC=0` |

- **两趟之间未换件（判据 `C4`）**：`NOFILE_SWAP=YES before=2067cb1c97728791 after=2067cb1c97728791`（脚本在趟间**机械断言**）。
- 两趟 `[0]` 段**逐字相同**：`✅ X-REUSE=reused display=:99（几何 1280x1024 相符而复用）`／`X_STATE=available`；
  两趟 `SKIP_GUARD=PASS x_state=available … total_skipped=2 violations=none`。
- **判词层对照**：两趟各 **32** 条 `自报口径` 行，**25 条逐字相同**；差异 **7 条全是运行期读数**，**逐条点名**：

| # | 行 | 第 1 趟 | 第 2 趟 | 性质 |
|---|---|---|---|---|
| 1 | `TLINE_GATE … outdir=` | `…-214618` | `…-220210` | 时间戳目录 |
| 2 | `COLUMN_FLOOR_SELFREPORT … outdir=` | `/tmp/column-floor.f9dENm` | `/tmp/column-floor.sskh09` | `mktemp` |
| 3 | `FRAMEPRESENCE … dir=`＋`magenta_frames=` | `…-215610`／**40** | `…-221319`／**39** | 时间戳 ＋ **本质可变** |
| 4 | `THIRDPARTY_BUILD log=` | `w37-tpm-215830` | `w37-tpm-221545` | 时间戳 |
| 5 | `THIRDPARTY_IMAGE path=` | 同上 | 同上 | 时间戳 |
| 6 | `THIRDPARTY dir=`＋**`frames=`** | 同上／**42** | 同上／**41** | 时间戳 ＋ **本质可变**（`#54` 已记同族：四趟 41/42/43 ⇒ `NOINFO`） |
| 7 | **`R_GATE … mem_mb=`** | **4526** | **3041** | 运行期内存 |

⇒ **判据内容**（`PASS`／`crit=13/13`／`files=1231`／`hits=0`／**`win32shim=2067cb1c97728791`**／`pc=722e0ab8205b7c3f`／
`COLUMN_FLOOR=PASS`／`ARMLOG_SHA=PASS pass=5 fail=0`／`DEFREG=PASS declared=147`）**逐字相同** ⇒ **判据 `C8` 绿**。

---

## ⑧ 推送（逐径）（判据 `C9`／`C10`；`D-G108` 纪律：**绝不 `-A`**）

**机制**：fork 克隆 `~/netTest/GitProj/WPFOnLinux` 是**独立检出、不自动跟随 `$R`** ⇒ 必须先 `cp -p` 真件。

**开工读数**：`porcelain` **0 行**（工作树干净）＝ `HEAD 0de067cf49709b075781df6ed66c754b7b7f19aa`，
`ls-remote --symref origin HEAD` = `ref: refs/heads/feat-Linux`（**两者一致**）。

**待推清单求法（机械，不靠记忆）**：`~/w141a/bin/scan-push-set.py` —— 克隆 `git ls-files` **15,288** 件逐件 `sha256` 比 `$R`
⇒ **14 件 DIFF**；其中 **3 件是登记车道在办件**（`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／
`build/MilBridge/tools/defect-registry-declared.tsv`）⇒ **一件未 add**（判据 `C10`）；**实推 13 件**（11 `M` ＋ 2 `??`）。

| # | 件 | before | after |
|---|---|---|---|
| 1 | `build/MilBridge/arm-logs/tline.log` | `664a0c048a1ed3a1` | **`a46cb0b4e853fa1f`** |
| 2 | `build/MilBridge/gen/t2d-family-baseline.txt` | `8b54486413d7ee76` | **`b9e1774f1fab660f`** |
| 3 | `build/MilBridge/gen/t2d-family-matrix.txt` | `61c817d836462306` | **`2a449a648f37b286`** |
| 4 | `build/MilBridge/gen/tline-ledger-lines-20260923-2100.txt`（本波账页） | —（新建） | **`81880ac3d10638a4`** |
| 5 | `build/MilBridge/known-red.json` | `9a26c67a6f9fe1e4` | **`433d2d371787c004`** |
| 6 | `build/wave-audit.log` | `dc8d29d810d279f0` | **`47c29557f29e2fda`** |
| 7 | `docs/CURRENT-STATE.md` | `65010285095beb10` | **`a67e269711686275`** |
| 8 | `docs/WAVE55-PREREGISTRATION.md`（新建） | — | **`5c062a33a2b0eb17`** |
| 9 | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `f9948196858bc9db` | **`38320d5e377a0dc8`** |
| 10 | `src/WpfGfx.Linux.Native/src/win32_core.c` | `a9cc8762908b417a` | **`c66528843de4a370`** |
| 11 | `src/WpfGfx.Linux.Native/src/win32_internal.h` | `4e1880e6054635ff` | **`c13390de6f870999`** |
| 12 | `src/WpfGfx.Linux.Native/src/win32_msg.c` | `4ad790f4c26a907c` | **`12175591b736bb3f`** |
| 13 | `verify-all.sh` | `4bcc0cf7aab10bb5` | **`80455e8d5eb92cb3`** |

（before 逐位 == `#54` 那笔推送时的 after ⇒ **断代连续**。）

**计数对账（防 `#52` 那次 `add -A` 夹带事故的同族纪律）**：`git status --porcelain` **13 行**（11 `M` ＋ 2 `??`）
**＝** `git diff --cached --name-only` **13 件** ⇒ **"本笔恰好 13 件、无夹带"**。

**推送三件套**：
- commit = **`ef1dc8f18156d40cf56f6409a691cb992fb89a6f`**
- `git push origin feat-Linux` ⇒ `0de067c..ef1dc8f  feat-Linux -> feat-Linux`
- **push 之后重新 `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`**（**refspec 陷阱**：默认跟踪 ref **不会**更新 ⇒ 假 MISMATCH）
  ＋ 与 `git ls-remote` **交叉核** ⇒ **`local == remote-tracking == ls-remote == ef1dc8f18156d40cf56f6409a691cb992fb89a6f`（三者一致）**
- `git ls-remote --symref origin HEAD` ⇒ **`ref: refs/heads/feat-Linux`** ✓
- **逐件字节核对**（`git cat-file blob origin/feat-Linux:<path>` vs `$R` 磁盘，rev = push 之后重新 fetch）
  ⇒ **`BYTECHECK ok=13 mismatch=0 nobody=0`**（13 件逐位相同，与上表 after 列一致）

**⛔ 刻意未推的件（判据 `C10`）**：

| 类 | 件 | 理由 |
|---|---|---|
| **在办他车道（登记）** | `docs/ROUTES.md`（`ef376b7b3458b3a6`）／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`133af9645842c9d3`）／`build/MilBridge/tools/defect-registry-declared.tsv`（`2d36bf918db0f5dd`） | **登记归主控**，推它 = 推半成品 |
| **本地领先（未推，交主控裁）** | `build/MilBridge/gen/tline-ledger-lines-{20260921-1224,-1231,-1540,-1623,-1629,20260923-0926,20260923-1245}.txt` **7 件** | 在 `$R`、不在远端；仓内先例是**每波只推该波自己产出的一件账页** ⇒ 属**历史遗留**，**不擅自补推** |
| **不存在** | `build/MilBridge/W136A-report.md` | `#55` 产品车道的报告实在 **`~/w136a-report.md`（仓外）**，**不在本车道写域** ⇒ **未搬入仓内、未推**（交主控裁） |

**本报告自身那一笔会让 head 再前进** ⇒ 本报告**不写死"最终 head"**，以现场 `ls-remote` 读数为准。

---

## ⑨ app-local（判据 `C11`）

**命令**（**显式补根**，`D-G91`：默认根漏 `$REPO/tools` ⇒ 会打 `STALE=0` **假绿**）：
```
AUTH_ROOT=$R SCAN_ROOTS=$R/build:$R/tests:$R/samples:$R/src:$R/tools \
  bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh --apply   # ~/w141a/logs/20-appsync-apply.log
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh                 # ~/w141a/logs/21-appsync-check.log
```
**读数**：
- `APPLY_RC=0`｜**`APPSYNC-REFRESH=refreshed=0 newer=0 applied=1`**｜脚本自印
  「（没有 STALE / NEWER-DIFF / DIVERGENT 落单者：同类加载源副本都已是权威 sha）」
- `CHECK_RC=1`（**由在册 `UNEXPECTED` 引起**）：
  **`计数：OK=200  MISMATCH=0（STALE=0  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0]  DIVERGENT=0  CROSS-CONFIG=101  LIB-COPY=23  …  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0`**
  ⇒ **`STALE=0 DIVERGENT=0 MISMATCH=0 MISSING=0`** ⇒ **判据 `C11` 绿**
- **桥副本 4 份全 `ANCHOR-OK 4e25e4b27d4d5ae1`**（含 `samples/**/bin/**` 两份派生副本）
- **`APP_ART win32shim=2067cb1c97728791 pc=722e0ab8205b7c3f pf=f2df3c2b464b7f00 wb=2e4e46e539a72cd7 bridge=4e25e4b27d4d5ae1`**
  （R-GATE 应用目录 `/tmp/r-gate-step-1863536/device.log`）⇒ **`win32shim` 命中判据要求的新值** ✓
- ⚠️ `UNEXPECTED=6[DECL-GAP-EQ=6]` = **在册**声明类缺口（`#49` 认定），与 `#52`/`#53`/`#54` **逐字同形** ⇒ **不当绿、不改判据**；
  `APPSYNC` 整体 `MISMATCH` 是**告警语义**（非硬闸），校验器 `rc=1` 即由此而来。
- **`TASK-0502` 的两条波尾必做**：① = 本步（`applied=1`）✓；② 别名侧硬链接已断（见 ③.2）✓。

---

## ⑩ 哨兵两处（判据 `C12`）

| 处 | 路径 | 读数 |
|---|---|---|
| 主 | `/tmp/bridge-frozen.flag`（**唯一写者** = `build/close-wave.sh:387-412`） | mtime `2026-09-23 20:57:15.682748620` |
| 镜像 | `~/wfp-runs/bridge-frozen.flag` | mtime `2026-09-23 20:57:15.687751094` |

`cmp` ⇒ **`IDENTICAL`**（差 **5 ms** ⇒ 同一趟写出）。两处逐字：
**`SHA=4e25e4b27d4d5ae1`**（= 本波 `bridge`，判据要求命中 ✓）／**`WIN32SHIM=2067cb1c97728791`**（= 本波新件，**判据要求命中** ✓）／
`FP=d697b1e10ff48881`／`PC=722e0ab8205b7c3f`／`PF=f2df3c2b464b7f00`／`WAVE=close-wave-205345`。
（本车道**未写**哨兵 —— 唯一写者是 `close-wave.sh`，**只读复核**。）

---

## ⑪ `NOINFO` / 未做（**逐条，不猜**）

1. **托管侧（.NET/WPF）对 `PostMessageW` 返回 0 的反应未验证**（W136A 零 `dotnet`，只到 native 层）⇒ `NOINFO`。
2. **`[POSTMSG_DEAD_TARGET]` 在真应用中的出现率未取到**（只在构造腿上 1 行）⇒ `NOINFO`。
3. **定时器那一半（`g_wpf.timers` 的 `owner_thread`）仍无读数**（静态改动，未造场景）⇒ `NOINFO`。
4. **`DeadThread` 场景（线程先死、窗口还活着）在真应用中的出现率未取到** ⇒ `NOINFO`。
5. **两样本（`W071`/`W077`）为何都在第 7 击 `nav2`**（时序耦合）⇒ `NOINFO`。
6. **`THIRDPARTY frames=` 的逐趟差异不可归因**（本波两趟 42/41；`#54` 四趟 41/42/43 本质可变）⇒ `NOINFO`。
7. **`siaddr=0x0` 不作为判据**（与指令语义不符；`D-G109` 判词不依赖它）⇒ 该格 `NOINFO`。
8. **`UNEXPECTED=6[DECL-GAP-EQ=6]` 未逐条归因**（`#49` 认定在册）；本件只确认「**不因本波变多**」⇒ `NOINFO`。
9. **登记三件的推送未做**（在办他车道）⇒ 交主控。
10. **`build/MilBridge/W136A-report.md` 未建/未推**（`#55` 产品报告在 `~/w136a-report.md`，**仓外**、不属本车道写域）⇒ 交主控裁。
11. **7 件历史遗留账页的归属未定**（`$R` 有、远端无）⇒ 不擅自补推，交主控裁。
12. **`TASK-0209` 的现场命中率未重测**（本车道**零应用趟**；`D-G109` 的 `2/175 ⇒ 3.55%` 是 W128A 的读数，本波未复测）⇒ `NOINFO`。
13. **本报告自身那一笔会让 head 再前进**（结构性）⇒ 不写死"最终 head"。
14. **`nproc` 现场 4**（派单书未写上限）⇒ 如实记；本车道重活**全走槽**、**同时只有一个**。

---

## ⑫ 内存三值与纪律

| 量 | 值 |
|---|---|
| `MemAvailable` **开工** | **4,260 MB** |
| `MemAvailable` **槽内最低已记录** | **3,220 MB**（`HEAVYSLOT=MEMOK avail=3220MB min_avail=1500MB`，app-local 步） |
| `MemAvailable` **收工** | **3,300,884 KB ≈ 3,224 MB** |
| `loadavg`（收工） | `0.91 1.99 2.31` |
| `/proc/vmstat oom_kill` | **0** |
| 磁盘（收工） | `df --output=avail /` = **70,452,832 KB ≈ 67.2 GiB**（开工 77.8 GiB） |

**纪律执行（逐条）**：① 重活**全走槽**（9 次 `ACQUIRED`／`MEMOK`／`RELEASED`，逐条读数见下）；
② **零 `MAXHOLD_KILL`、零 `low-memory`**（`grep -c 'MAXHOLD_KILL\|low-memory' ~/w141a/logs/*.log` = 0）；
③ **零 `pkill`／`killall`／`pgrep -f`**（收进程**只按 PID**、读 `/proc/*/cmdline` 探活）；
④ 显示号只用 `:97`（**复用**）／`:99`（**复用**）／`:213`／`:214`（**门禁自起并自收**）
   —— **绝未碰** `:0`／`:1`／`:92`（他车道）／`:185`／`:188`／`:221`／`:222`；收工 `/tmp/.X11-unix/` 无本车道残留；
⑤ **落盘 `temp ＋ os.replace`**（补丁／记录／报告生成器）；⑥ **未手抄哈希**（所有 sha16 现场现算，生成器逐条 `assert`）；
⑦ `export PATH="$HOME/.dotnet:$PATH"`、`dotnet -m:1`、`DOTNET_gcServer=0`（重活内建）；
⑧ **每完成一步立刻追加** `~/w141a/STATUS.md`。

**槽逐条**：

| 步 | `ACQUIRED waited` | `MEMOK avail` | `RELEASED rc / held` | `max_hold` |
|---|---|---|---|---|
| ① native | `0s` | 4868 MB | `0 / 2s` | 600 |
| ① 整波 | `0s` | 4820 MB | `0 / 210s` | 1200 |
| ② 五臂 | `0s` | 4280 MB | `0 / 348s` | 1200 |
| ③ 重钉 | `5s` | 4374 MB | `0 / 0s` | 300 |
| ④ 门禁 ×2 | `13s` | 4616 MB | `0 / 336s` | 800 |
| ⑤ 冻前 `verify-all` | `25s` | 4008 MB | **`1 / 1030s`**（设计内：1 处声明类红） | 1500 |
| ⑥ 冻结 | `5s` | 4948 MB | `0 / 1s` | 300 |
| ⑦ 冻后 §1 | `19s` | 4870 MB | `0 / 927s` | 1500 |
| ⑦ 冻后 §2 | `35s` | 4759 MB | `0 / 1000s` | 1500 |
| ⑨ app-local | `34s` | 3220 MB | `0 / 23s` | 300 |

---

## ⑬ 小结（大白话，≤6 行）

1. **走通了**：`#55` 的 11 步我一步到底 —— 整波 `rc=0`、五臂重取（预测命中：只有 `tline` 变）、重钉 `PASS`、
   门禁 ×2 各 6/6、冻前 `verify-all` **恰好 1 处声明类红**、**冻结 `#55`（`38320d5e377a0dc8`）一次成功**、冻后 ×2 各 `27 ✅ / 0 ❌`。
2. **位移干净**：九位只有 **`win32shim`（产品：`TASK-0209`）＋ `pf`（`D-G92` 非确定性）** 变，**`bridge` 一动不动**
   —— 逐字命中判据，**没有第三个位动**（动了就该停手）。
3. **推了一笔干净的**：13 件**逐径 `git add`**（**绝不 `-A`**），`porcelain` 13 行 == `--cached` 13 件、
   `BYTECHECK ok=13 mismatch=0`、三方 head 一致（`ef1dc8f`）；**登记三件一件未碰**，7 件历史账页**不擅自补推**。
4. **新入册的方法学**：**每条重活趟之前先做空盘/可写预检**（`#54` 就是被瞬时 `ENOSPC` 把 `rc=2 NOINFO` 变成汇总里的 `❌` 的）；
   本波**零 `ENOSPC` 趟**。
5. **一条作废趟我如实并列留档**：第 1 次冻前 `verify-all` 是本会话工具链 **600 s 前台上限** SIGTERM 打断的
   ⇒ 记「作废（环境成因，非读数）」＋ **按 PID** 收残留（**没用 `pkill`**）＋ **后台重跑**出有效趟。
6. **没做完的交主控**：`build/MilBridge/W136A-report.md`（`#55` 产品报告在 `~/w136a-report.md`，**仓外**）未搬入仓；
   登记三件未推；12 条 `NOINFO` 逐条在 ⑪。

---

# 本报告自述口径（**机械、不循环**）：
#   · **口径乙**（去末行）＝ `head -n -1 build/MilBridge/W141A-report.md | sha256sum | cut -c1-16`
#     —— 上式**不含本末行**（本末行就是那个值）⇒ 自洽、可当场复算：见本文件**最后一行**。
#   · **口径甲**（整份 FULL ＝ `sha256sum build/MilBridge/W141A-report.md`）**含本末行** ⇒ 天然循环，
#     故**不写进本文件**，只在 `~/w141a/STATUS.md` 与最终回复里给出现场现算值。
# 口径乙（去末行，现场现算）＝ **7b445ef1f5af1a06**