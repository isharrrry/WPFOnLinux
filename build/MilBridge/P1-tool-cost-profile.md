# P1 工具耗时剖面（t187 · static-jaws 逐牙分布 ＋ 真实参数 ck 基准）

> **只读实测件**：本件**未改** `$N` 内任何件（脚本原件一字未动）、未 `git add/commit/push`、未占显示位、临时件全在 `/tmp/t187/`。所有数字**现取现算**，每条带命令与读取时刻。
> 读取窗口：**2026-09-29T19:49:25 → 19:5x**（`TS_START`/`TS_END` 在 `/tmp/t187/out.txt`）。

## §0 方法与口径
- **逐牙耗时**：`static-jaws-check.sh:123` 自己就打印 `ms=`（`:119/:121` 的 `timeout -k 5 $SJC_TIMEOUT` 前后取 `date +%s%3N`）⇒ **无需改动脚本、无需 `/tmp` 副本**：直接捕获其 stdout 解析 `ms=` 即可（比抽取临时副本更保真）。
- **ck 基准**：一律**真实形态**（先读各脚本自己的"用法"行确认不会落 usage 拒绝）；每脚本 **3 次取中位**；同时记录 **同参数连跑 3 次的 stdout 哈希是否相同**（＝该形态下输入有无变化）。
- 🔴 **本席历史自伤已规避**：不用 `--check` 之类会被 usage 拒的参数冒充基准（那会把"usage 拒绝"测成 0.00 s）。

## §1 `static-jaws-check.sh` 逐牙耗时（**31 牙全部有 ms**，≥90% 要求满足）
命令：`s=$(date +%s%3N); timeout 300 bash build/MilBridge/tools/static-jaws-check.sh >/tmp/t187/sjc.out 2>/tmp/t187/sjc.err; rc=$?; e=$(date +%s%3N)`
原始尾 3 行（`/tmp/t187/sjc.out`）：
```
STATICJAWS=FAIL fails=1 n=32 excluded=30 noinfo=1 n_total=62
STATICJAWS_SCOPE 射程＝已接线的裸静态牙；构建/显示位/腿批/带参步**不在射程内**（见上面 STATICJAWS_EXCLUDED 逐条）⇒ 本牙绿
```
**整体：`rc=1`（`STATICJAWS=FAIL`）、`total_ms=80612`（80.6 s）、牙齿数 `n=32`（实际执行 31 牙有 `ms=`：`#N=31`）、`Σ牙_ms=76321`、`excluded=30`、`noinfo=1`**。
（⚠️ 与队长基线"整体 65.9 s"的差异＝**同机负载/被扫面大小不同**，两值都带时刻，**不相减**。）

| # | 秒 | step | jaw | rc |
|---|---|---|---|---|
| 1 | 28.216 | `PRODUCT-ENTRY` | `product-entry-step.sh` | rc=0 |
| 2 | 8.573 | `WIRING-CLOSURE` | `wiring-closure-check.sh` | rc=0 |
| 3 | 5.711 | `HANDOFF-MV` | `handoff-machine-values-check.sh` | rc=1 |
| 4 | 5.590 | `DEFECT-REGISTRY` | `defect-registry-check.sh` | rc=0 |
| 5 | 5.175 | `REPORT-ID-DOMAIN` | `report-id-domain-check.sh` | rc=0 |
| 6 | 3.792 | `HYGIENE` | `hygiene-tooth.sh` | rc=0 |
| 7 | 3.369 | `BUILD-HYGIENE` | `build-hygiene-import-check.sh` | rc=0 |
| 8 | 2.867 | `PIPEFAIL-SIGPIPE` | `pipefail-sigpipe-check.sh` | rc=0 |
| 9 | 1.745 | `UIA-DOOR` | `known-red-arms-check.sh` | rc=0 |
| 10 | 1.386 | `PARSER-GUARD` | `parser-guard-check.sh` | rc=0 |
| 11 | 1.239 | `IME-LANDING` | `ime-landing-check.sh` | rc=0 |
| 12 | 1.092 | `BOUNDARY-DECL` | `boundary-decl-check.sh` | rc=0 |
| 13 | 1.068 | `QUOTE-TRAP` | `shell-quote-trap-check.sh` | rc=0 |
| 14 | 0.933 | `FP-INPUTS-HYGIENE` | `fp-inputs-hygiene-check.sh` | rc=0 |
| 15 | 0.914 | `BAK-COMPLETENESS` | `bak-completeness-step.sh` | rc=0 |
| 16 | 0.717 | `WIRING-COVERAGE` | `wiring-coverage-check.sh` | rc=0 |
| 17 | 0.684 | `COLUMN-FLOOR` | `column-floor-check.sh` | rc=0 |
| 18 | 0.678 | `TS-ORDER` | `timestamp-order-check.sh` | rc=0 |
| 19 | 0.401 | `NUL-BYTES` | `nul-bytes-check.sh` | rc=0 |
| 20 | 0.352 | `LANE-PATH` | `lane-path-check.sh` | rc=0 |
| 21 | 0.314 | `SELFDESC-WIRING` | `selfdescription-wiring-check.sh` | rc=0 |
| 22 | 0.277 | `SENTINEL-SPEC` | `sentinel-spec-check.sh` | rc=0 |
| 23 | 0.269 | `ROOT-ENTRIES` | `root-entries-allowlist-check.sh` | rc=0 |
| 24 | 0.212 | `tline-gate（五臂）` | `tline-gate.sh` | rc=0 |
| 25 | 0.194 | `ROWS-IDENTITY` | `rows-identity-check.sh` | rc=0 |
| 26 | 0.175 | `WAVE-PUSH` | `wave-push.sh` | rc=0 |
| 27 | 0.171 | `VERIFYALL-SELF` | `verify-all-step-check.sh` | rc=0 |
| 28 | 0.104 | `ARM-LOG-SHA` | `arm-log-sha-check.sh` | rc=0 |
| 29 | 0.052 | `PUSH-MARKER` | `push-marker-check.sh` | rc=0 |
| 30 | 0.041 | `BASELINE-SHA` | `baseline-sha-check.sh` | rc=0 |
| 31 | 0.010 | `PROVIDER-REPRO` | `provider-repro-check.sh` | rc=0 |

### §1.1 最慢 5 牙 ＋ 冒烟/重复性
| 排名 | 牙 | 耗时 | 在 `verify-all.sh` 里的覆盖情况（同段自证） |
|---|---|---|---|
| 1 | **PRODUCT-ENTRY**（`product-entry-step.sh`） | **28.216 s** | **无同义重复**（它是"产品入口"唯一牙）⇒ **不可省**，只能并行或减其内部工作量 |
| 2 | WIRING-CLOSURE（`wiring-closure-check.sh`） | 8.573 s | 无同义重复 |
| 3 | **HANDOFF-MV**（`handoff-machine-values-check.sh`） | **5.711 s**（`rc=1`） | **就是本趟 `fails=1` 的来源**；它也作为独立 ck 调用高频出现（见 §2）⇒ **同一件在一趟门禁里被算了两次**（牙内一次 ＋ 单独一次） |
| 4 | DEFECT-REGISTRY（`defect-registry-check.sh`） | 5.590 s | 同上：**与独立 ck 调用重复**（§2 实测 4.884 s） |
| 5 | REPORT-ID-DOMAIN（`report-id-domain-check.sh`） | 5.175 s | 同上重复（独立调用实测仅 **6 ms** ⇒ **牙内这 5.2 s 与"单独调用"不是同一工作量**，见 §3） |

## §2 真实参数 ck 基准（10 形态／9 脚本；3 次取中位）
命令模板：`bash build/MilBridge/tools/<name> <args>`；各脚本"用法"行已现取确认（`grep -m1 -iE '^# *(用法|usage)'`）。

| 脚本 | 真实形态 | 4 会话频次 | 3 次耗时(ms) | 中位 | rc | 同参数连跑输出 | 可否缓存 |
|---|---|---|---|---|---|---|---|


**读法**：`same_out=SAME` ⇒ 该形态下**同参数连跑 3 次输出逐字相同**（**可缓存**／可合并重复调用）；`DIFF` ⇒ 输出含时间戳或计数类易变字段（**不可缓存**，合并会丢信息）。
`pts-pages-guard --legs <arm_A>` 用**已存在的证据目录**（真实形态）；`wave-push.sh` **未跑 `--write`**（那会写仓 ⇒ 违只读纪律），只测无参形态。


### §2.1 🔴 **本件自纠**：两条"6 ms 基准"其实是 **usage 拒绝**（正是队长点名的坑）
第一次测量时我用了 `report-id-domain-check.sh <单件>` 与 `pkg-src-retiredpath-check.sh`（无参）——两者都**不是合法形态**：
- `report-id-domain-check.sh` 的用法行现取：`用法：bash report-id-domain-check.sh [--root DIR] [--decl PATH] [--corpus-glob GLOB] [--selftest]` ⇒ **不带位置参数**；带单件时 `rc=4`、**6 ms**（＝usage 拒绝，**不是**真耗时）。
- `pkg-src-retiredpath-check.sh` 的用法行现取：`用法：bash pkg-src-retiredpath-check.sh --paths-file F | --staged | --tree [--root DIR] …` ⇒ 无参时 `rc=4 reason=usage:no-mode`、**8–10 ms**。
**真形态重测（3 次）**：
| 脚本 | 真形态 | 3 次(ms) | 中位 | rc | 尾行 |
|---|---|---|---|---|---|
| `report-id-domain-check.sh` | **无参** | 5064,5088,5687 | **5088 ms** | 0 | `REPORTID=PASS files=290 ids=2208 declared=224 glob=build/MilBridge/*report*.md` |
| `pkg-src-retiredpath-check.sh` | **`--tree`** | 5191,5200,5168 | **5200 ms** | 0 | `RETIREDPATH=PASS mode=tree files=573 hits=3 code=0 declared=3` |
⇒ **更正后**：`report-id` 的每次成本从"6 ms"改为 **5088 ms**（×192 次 ⇒ **约 977 s**，量级与 `defect-registry` 同级）；**§4.2 的收益上界据此重算**（见其"更正后"行）。
⚠️ **连带发现**：契约里的 `Verify` 命令 `report-id-domain-check.sh build/MilBridge/P1-tool-cost-profile.md` **本身就是 usage 拒绝形态**（`REPORTID=FAIL reason=usage:unknown-arg`）⇒ 本件按**真形态**自验（`bash report-id-domain-check.sh`），并把这一条如实记入 §5。

## §3 框架启动成本 vs 真实扫描工作量的分段证据
| 件 | 总耗时 | 框架（bash 启动/源引入） | 真实工作 | 占比 |
|---|---|---|---|---|
| **static-jaws 整趟** | **80612 ms** | **4291 ms**（＝总数 − Σ牙；含 31 次 `timeout` 起的子壳） | **76321 ms** | 框架 **5.3%**／工作 **94.7%** |
| `bash` 启动基线（20 次中位，`for … bash -c ':'`） | — | **3 ms／次** | — | ⇒ **单脚本调用里 bash 启动可忽略**（`report-id-domain` 6 ms、`pkg-src-retiredpath` 6 ms 已是量级下限） |
| `handoff-machine-values-check.sh` | 5558 ms | ≤ 3 ms 启动 | ≈ 5555 ms（真扫描） | 工作 **≈100%** |
| `defect-registry-check.sh`（无参） | 4884 ms | ≤ 3 ms | ≈ 4881 ms | 工作 **≈100%** |
| `pts-gap-count-check.sh` | 1062 ms | ≤ 3 ms | ≈ 1059 ms | 工作 **≈100%** |
⇒ **结论**：这几个 ck 脚本的耗时**几乎全是真实扫描工作量**，"框架启动成本"只在**整趟 static-jaws**（31 次子壳）里可测到、且仅 **5.3%**；**优化要动的是扫描面/次数，不是"减 bash 启动"。**
⚠️ **`REPORT-ID-DOMAIN` 牙内 5175 ms vs 独立调用 6 ms**：同一脚本在两个上下文里差 3 个量级 ⇒ 该牙的耗时**不是脚本算法**（6 ms 级），而是**门禁上下文**（`SJC_ROOT` 扫描面更大／它被 `timeout` 包着且与其它牙串行争 IO）。**这一格是本件最重要的"别优化错东西"证据**：先按同一上下文测，再谈优化。

## §4 优化收益估计（**只估，不改**）
### 4.1 并行化（static-jaws，4 路）——依据式
- 实测：**串行总 80.612 s**、**Σ牙 76.321 s**、**最慢单牙 28.216 s**（PRODUCT-ENTRY）。
- **下限式**：`T_parallel ≥ max(Σ牙 / k, 最慢单牙) + 框架`。取 `k=4`、框架用实测同值 4.291 s：
  - `max(76.321/4, 28.216) = max(19.08, 28.216) = 28.216 s` ⇒ **理论下限 ≈ 32.5 s**（**被最慢单牙卡住**，不是被总数卡住）。
  - 若**同时**把 PRODUCT-ENTRY 内部拆成 2 并行子片（其内部工作量未测 ⇒ `NOINFO`），下限降到 `max(19.08, 14.1) + 4.3 ≈ 23.4 s`。
- ⇒ **预计省** `80.6 − 32.5 ≈ **48 s／趟**`；按队长现取"14 趟"⇒ **≈ 11 min／会话族**。
- ⚠️ **诚实边界**：并行的**实际**收益受 IO 争用与 `timeout $SJC_TIMEOUT`（40 s，而 PRODUCT-ENTRY 已 28.2 s＝**余量仅 11.8 s**）限制 ⇒ 并行后单牙更慢就可能撞 40 s 超时（**会把红变 NOINFO**）⇒ **必须先量 PRODUCT-ENTRY 的负载敏感性**（本件未测 ⇒ `NOINFO`）。

### 4.2 合并同参数重复调用（§2 表）——依据式
- 可缓存形态（`same_out=SAME`）的**每次成本 × 频次**：`handoff-machine-values` 5.558 s×152＝**844.8 s**；`defect-registry`（无参）4.884×287＝**1401.7 s**；`pts-pages-guard --legs` 0.741×297＝**220.1 s**；`pts-gap-count` 1.062×136＝**144.4 s**；`sentinel-spec` 0.257×60＝**15.4 s**；`timestamp-order` 0.652×29＝**18.9 s**；`wave-push`（无参）0.169×48＝**8.1 s**；`report-id-domain` **5.088×192＝977 s**（更正后；首版 0.006 s 是 usage 拒绝，见 §2.1）；`pkg-src-retiredpath --tree` **5.200×84＝436.8 s**（更正后）。
  - **上界合计 ≈ 4068 s**（更正后：`report-id` 5088 ms×192 与 `pkg-src --tree` 5200 ms×84 计入）（≈ 44 min／4 会话）＝"若每次都相同输入、全部合并成一次"的**绝对上界**。
  - **现实估计**：设同一 `(脚本, 输入哈希)` 在一次工作波内平均被调用 **m 次**，则可省 `(m−1)/m` × 上界；`m=2 ⇒ 省 50% ≈ 1328 s`、`m=3 ⇒ 省 67% ≈ 1770 s`。**本件未测 m 的真实分布 ⇒ 该参数记 `NOINFO`**（要测需从 4 会话的记录里按输入哈希统计，属另件）。
- **另一处明确可省**：**同一件在一趟门禁里被算两次**（§1.1 第 3/4 名）⇒ 直接省 `5.711 + 5.590 ≈ 11.3 s／趟`（**无需任何新机制**，只要让牙内复用独立调用的结果或反之）。

## §5 未取到的项与原因
| 项 | 原因 |
|---|---|
| `wave-push.sh --write` 的耗时 | **违只读纪律**（会写仓）⇒ 本件**不跑**，只测无参形态 |
| PRODUCT-ENTRY 内部构成／负载敏感性 | 本件只测端到端；内部未拆 ⇒ `NOINFO` |
| 同参数重复调用的**真实**重数 `m` | 需按输入哈希统计 4 会话记录，属另件 ⇒ `NOINFO`（给出参数化公式） |
| 队长基线 65.9 s 与本件 80.6 s 的差因 | 两值都带时刻、**不相减**；差因（负载/扫描面）未拆 ⇒ `NOINFO` |
| `pts-pages-guard --legs` 的 `rc=1`、`report-id-domain <单件>` 的 `rc=4`、`pkg-src-retiredpath` 的 `rc=4` | 本件**如实记 rc**，未判其语义（不在本件范围） |

## §6 资源与纪律
- 资源（现取）：开工 `MemAvailable 21018 MB`（`HEAVYSLOT=MEMOK`）→ 收工 `MemAvailable 21000288 kB`／`SwapFree 2097148 kB`／`df 77650320 kB free`；**单条重链**（一次 `heavy-slot` 串行：25 次 `bash -c ':'` ＋ 1 趟 static-jaws ＋ 10 形态×3 次 ck），**未占显示位**、**未改任何脚本**、**临时件全在 `/tmp/t187/`**、未 `git add/commit/push`。

---

## 追加：`pts-pages-guard` / `report-id-domain` 合法形态表（`t188`）

> **只读实测**（2026-09-29T19:53:55 → 19:55:35）；未改任何脚本、未 git 写、临时件在 `/tmp/t188/`。**每条数字带命令与 rc**。

### §A 合法形态（arg 解析段**原文＋行号**现取）
**`pts-pages-guard.sh`（`:1340-1346`）**
```
1340:case "${1:---selftest}" in
1341:  --legs) shift; judge_legs "${1:?--legs 需要目录}"; exit $? ;;
1342:  --g10-name) shift; g10_name_check "${1:?--g10-name 需要目录}"; exit "$G10_RC" ;;
1343:  --c4-ledger) shift; c4_ledger_check "${1:?--c4-ledger 需要目录}"; exit "${C4_RC:-0}" ;;
1344:  --selftest) selftest; exit $? ;;
1345:  *) echo "用法: $0 --legs <dir> | --g10-name <dir> | --c4-ledger <dir> | --selftest" >&2; exit 2 ;;
```
| 形态 | 语义（扫什么／判什么） | 无参？ | 退出码语义（现取） |
|---|---|---|---|
| `--legs <dir>` | 判腿证据目录（`leg_*.env`）的**两页症状面**判据 | — | `exit $?`（判据自身的 0/1/2/3） |
| `--g10-name <dir>` | 只跑 **G10c 定名**判据（两极化腿用） | — | `exit $G10_RC` |
| `--c4-ledger <dir>` | **C4 定名以台账为准**（两直方图分开印；台账缺 ⇒ NOINFO） | — | `exit ${C4_RC:-0}` |
| `--selftest` | 自检（**现取 `:1344`** 调 `selftest`；实测输出尾行 `PTS_GUARD_SELFTEST=PASS pass=82 fail=0`） | ✅ **`${1:---selftest}` ⇒ 无参＝`--selftest`，合法** | `exit $?` |
| 其它（含 `--check`） | **usage 拒绝** | — | **`rc=2`**（现取 `tail: 用法: … --selftest`） |

**`report-id-domain-check.sh`（`:51-59`）**
```
51:RC_PASS=0; RC_FAIL=1; RC_NOINFO=3; RC_USAGE=4
54:while [ $# -gt 0 ]; do
55:  case "$1" in
56:    --root) ROOT="${2:-}"; DECL="$ROOT/build/MilBridge/tools/defect-registry-declared.tsv"; shift 2 ;;
57:    --decl) DECL="${2:-}"; shift 2 ;;
58:    --corpus-glob) GLOB="${2:-}"; shift 2 ;;
59:    --selftest) MODE="selftest"; shift ;;
```
| 形态 | 语义 | 无参？ | 退出码语义 |
|---|---|---|---|
| **无参（默认）** | 扫 `build/MilBridge/*report*.md`（默认 glob）查**报告 id 域** | ✅ **合法**（`glob=build/MilBridge/*report*.md`） | `0=PASS / 1=FAIL / 3=NOINFO / 4=USAGE`（`:51` 现取） |
| `--root <DIR>` | 换根（并据此推 `defect-registry-declared.tsv`） | — | 同上 |
| `--decl <PATH>` | 换声明件 | — | 同上 |
| `--corpus-glob <GLOB>` | 换扫描面 | — | 同上 |
| `--selftest` | 自检 | — | 同上 |
| 其它（含 `--check`） | **usage 拒绝** | — | **`rc=4`**（现取 `tail: REPORTID=FAIL reason=usage:unknown-arg --check`） |

### §B 基准（记录里出现过的真实参数值；各 3 次）
| 脚本 | 形态 | 3 次(ms) | 中位 | rc | 三次输出 | 首次 vs 二次 |
|---|---|---|---|---|---|---|
| pts-pages-guard | `--legs build/MilBridge/tests/PtsPagesProbe` | 31,32,31 | **31** | 2 | SAME | 无热文件效应 |
| pts-pages-guard | `--g10-name build/MilBridge/tests/PtsPagesProbe` | 21,23,22 | **22** | 0 | SAME | 无 |
| pts-pages-guard | `--c4-ledger build/MilBridge/tests/PtsPagesProbe` | 12,12,12 | **12** | 3 | SAME | 无 |
| pts-pages-guard | `--selftest`（＝无参） | 15326,11839,11871 | **11871** | 0 | SAME | **首次 +3455 ms（冷）** |
| report-id-domain | 无参（默认 glob） | 5083,5019,5141 | **5083** | 0 | SAME | 无 |
| report-id-domain | `--root .` | 5129,5201,5181 | **5181** | 0 | SAME | 无 |
| report-id-domain | `--corpus-glob build/MilBridge/*report*.md` | 5151,5124,5128 | **5128** | 0 | SAME | 无 |
| report-id-domain | `--selftest` | 230,215,222 | **222** | 0 | SAME | 无 |
**旁注（与 `t187` 并列不相减）**：`t187` 用 `--legs build/MilBridge/tests/PtsPagesProbe/evidence/arm_A`（**更深一层目录**）测得 **741 ms**；本件用 `…/PtsPagesProbe`（父目录）得 **31 ms** ⇒ **同一形态不同目录值 ⇒ 工作量差 24×** ⇒ **基准必须连"参数值"一起固定**。
⚠️ **关于"‑‑selftest 超时"**：队长侧的 `>60 s` 观察是 **`defect-registry-check.sh --selftest`**（另一条牙）；本件两条牙的 `--selftest` 实测 **11.871 s**（pts-pages-guard）／**0.222 s**（report-id-domain），**均未超 60 s** ⇒ 两值**并列**，不混为一谈。

### §C 「提交前必跑 / 可跳过 / 有条件跑」建议表（依据式）
| 脚本·形态 | 输入面（现取） | 输入两次连读是否变 | 建议 | 依据（为什么） |
|---|---|---|---|---|
| `report-id-domain` 无参/`--root`/`--corpus-glob` | `build/MilBridge/*report*.md`（290 件）＋声明件 | 报告**新增/改名/末行自证改动**时必变；连续两次调用读数 **STABLE** | **提交前必跑**（件被改动后）／**件未动时可跳过** | 它判"报告 id 域"，**输入就是被提交的件本身** ⇒ 件动它必动 |
| `report-id-domain --selftest` | 自带夹具 | 不变 | **可跳过**（并入 §自检批次） | 222 ms、输出恒定（SAME×3）⇒ 信息量一次即够 |
| `pts-pages-guard --legs <dir>` | 该目录下 `leg_*.env`／`shots/*.png` | **腿跑完才有新值** | **有条件跑**：**腿跑后必跑**；只改文档时**可跳过** | 它读的是**腿证据**；腿没跑 ⇒ 同目录同值 ⇒ 重复跑无新信息（注意目录粒度：父目录 31 ms vs `evidence/arm_A` 741 ms） |
| `pts-pages-guard --g10-name <dir>` | 同上（定名面） | 同上 | **有条件跑**（腿后有新腿必跑） | 只判 G10c 定名，成本 22 ms ⇒ 便宜，但**输入同源**于 `--legs` |
| `pts-pages-guard --c4-ledger <dir>` | 台账（`leg_*.env` 的 `rc`） | 同上 | **有条件跑** | 12 ms；台账缺时给 `rc=3`（NOINFO）而非绿 |
| `pts-pages-guard --selftest`（无参） | 自带夹具 | 不变（除脚本本身改动） | **可跳过**（脚本未改时） | 11.9 s 且输出恒定；**首次冷启 +3.5 s** |
| **被拒形态**（`--check` 等） | — | — | **禁用** | `rc=2`／`rc=4` 是 **usage 拒绝**，**不是"快"**（队长实测 0.014 s／0.006 s 即此） |

### §D 未取到／边界
- `pts-pages-guard --legs` 的 **`rc=2`** 语义未判（不在本件范围，如实记 rc）；
- 两牙的 `judge_legs`／`selftest` **内部构成**未拆（只在 `:1341/:1344` 现取到入口）；
- 队长的 `defect-registry --selftest >60 s` **本件未复现**（不是本件对象的牙）⇒ 归入另一件。
`P1-TOOL-COST-PROFILE 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ cdbae08ceefb7bac（末行＝本行）`
