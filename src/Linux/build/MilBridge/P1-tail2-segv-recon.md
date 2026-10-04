# P1-tail2-segv-recon —— `TASK-0201` 静默 `rc=139` 功效重取：**只读侦察 ＋ 判据预登记**

> **一句话**：为 `docs/ROUTES.md §13` 的 `TASK-0212`（现件代功效重取）做侦察：现取 `SILENT_SEGV_HIT` 逐字判别式与出处、现算 `k=0`／`k>0` 两支上界算式与所需腿数、现取装置代际与证据面、现取基线率闸判词；判据预登记草案供实现件照抄。
> **读取时刻**：全部读数现取于 **2026-09-30T00:26:51+0800**（`READ_TIME`，落盘前现取）。
> **本件零足迹**：**未起 X、未起应用、未跑门禁、未占槽、零 `dotnet`**；只用只读命令；进程只按 PID（未用 `pkill`／`pgrep -f`）；未 `sleep` 轮询。
> **载体**＝本文件（**本件唯一可写文件**）；其余仓内件**一字未改**（勘误见 §6）。
> **报告自报 sha16**：见末行 `SELF-SHA16`（口径＝`head -n -1 | sha256sum | cut -c1-16`）。
> ⚠️ **本件内一切行号仅对本次写入时刻有效**（`ROUTES.md` 现取 **1054 行**／`P0-mvp-segv-report.md` 现取 **545 行**）。

---

## §0 四个问题的答案（自包含结论）

| # | 问题 | 现取结论 | 落到 |
|---|---|---|---|
| ① | `SILENT_SEGV_HIT` 逐字判别式现取原文＋出处 | **在册有两条形态**：**散文形态**在 `docs/ROUTES.md`（口径句，逐字，**含四支**）＋ **机读形态**在 `P0-mvp-segv-report.md`（`TRIMMED==0 ∧ STACKOVF==0 ∧ SEGV_BRANCH!=none`）＋ **实现本体**在仓内牙 `silent-hit-v2-check.sh` 的 `judge()` | §1 |
| ② | `≥131 腿`／`≥299 腿` 的算法与出处；现件代所需 `N` | 算法 ＝ **`ub(0/N) = 1 − 0.05^(1/N)`**（`k=0` 支）；`131 ⇒ 2.2609%`／`299 ⇒ 0.9969%`；**在册锚**在 `P0-mvp-segv-report.md:92-100`（§4②）。`k>0` 支必须走 **Clopper–Pearson 单侧 95%**（`TASK-0719`／`D-G121`）。现件代 `0/N` 的上界：`N=59 ⇒ 4.95%`／`131 ⇒ 2.26%`／`149 ⇒ 1.99%`／`175 ⇒ 1.70%`／`299 ⇒ 1.00%` | §2 |
| ③ | 现件代 `.so` 与 `pf` 现取 sha16；腿跑器入口与证据目录 | `.so`＝**`26da177686acb1f0`**｜`pf`(Release)＝**`0b4b65f2c6c7ffd4`**；入口＝`build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh`（`64574cfe296dac19`）＋ 剔除集 `silenthit-trim.tsv`（`4270ab3da7a1d6d8`）；证据面逐件 sha16 见 §3 | §3 |
| ④ | `BASELINERATE` 现取判词与 `reason`；时间窗字段来源 | **现取两次**（在册基线／成对基线）**都 `FAIL` ＋ `REASON=VOID-PREMISE`**；缺窗 ⇒ **`NOINFO` ＋ `NOINFO-NO-WINDOW rc=3`**。时间窗字段 ＝ 跑批台账 `runs.tsv` 的 `ts_start..ts_end` ＋ `display` 号，拼成 `R/N@窗+display` | §4 |

---

## §1 ① `SILENT_SEGV_HIT` 逐字判别式（**现取原文**，**仅本次有效**）

### 1.1 在册散文形态（**含四支**，逐字）
- **出处 A（`docs/ROUTES.md`，现取 `:241`）**：
  > `SILENT_SEGV_HIT ⇔ 应用输出 == 0 B（剔 `timeout:` 行）∧ STACKOVF == 0 ∧ 死于 SIGSEGV（`RC==139` ∨ `APP_FATE` 含 SIGSEGV ∨ `gdb.txt` 含 "Program terminated with signal SIGSEGV" ∨ `gdb.txt` 存在 `W118A-STOP-N`(N≥1) 且 `signo=11`）`
  —— 末支**抗收尾截断**；该句在 `D-G109` 内已逐字在册，ROUTES **只引用、不重写**。
- **出处 B（`build/MilBridge/P0-mvp-segv-report.md`，现取 `:90`，§4①）**：
  > `应用输出 == 0 B（剔 timeout: 行 ∧ 剔应用自报插桩行 [HC-UNHANDLED] #N）∧ STACKOVF == 0 ∧ 死于 SIGSEGV`
  —— 与 A 的差别：**多一个剔除项 `[HC-UNHANDLED] #N`**（`D-G123` 修法），并把"死于 SIGSEGV"压缩成一句。
- **出处 C（同一行 `docs/ROUTES.md:229`，`TASK-0201` 行内机读形态）**：
  > `SILENT_SEGV_HIT ⇔ APP_TEXT_BYTES_TRIMMED==0 ∧ STACKOVF==0 ∧ SEGV_BRANCH!=none`

### 1.2 机读形态（**产出端/判据端实际实现**，逐字）
- **`build/MilBridge/P0-mvp-segv-report.md`，现取 `:330`**：
  > `口径（一字未动）：SILENT_SEGV_HIT ⇔ APP_TEXT_BYTES_TRIMMED==0 ∧ STACKOVF==0 ∧ SEGV_BRANCH!=none`
- **仓内牙（唯一实现）`build/MilBridge/tools/silent-hit-v2-check.sh`**，现取 `judge()`（`:85-105`）**逐字三支**：
  ```
  c1 = (trimmed == 0); c2 = (so == 0); c3 = (br in BRANCHES)      # :95
  BRANCHES = ("rc139", "fate", "term", "stop-signo11")            # :48
  ```
  两条**前置闸**（现取 `:89-92`）：`undeclared != 0 ⇒ NOINFO(undeclared-instrumentation)`／`phase == "teardown" ⇒ NOINFO(teardown-death-not-a-hit)`。
- **产出端 `run-silenthit-legs.sh` 自述（现取 `:7`）**：
  > `它判 SILENT_SEGV_HIT ⇔ APP_TEXT_BYTES_TRIMMED == 0 ∧ STACKOVF == 0 ∧ 死于 SIGSEGV`

### 1.3 三条口径必须**同读**（防后人只抄一条）
- **分母**：`SILENT_SEGV_HIT` **为 yes 才计命中**；`NOINFO`（`undeclared>0`／`teardown`／`TRIM_GATE!=ok`）**不进分母**（`D-G94`）。
- **两个数都印**：`APP_TEXT_BYTES`（原始）＋ `APP_TEXT_BYTES_TRIMMED`（剔除后），缺一 ⇒ `FAIL reason=producer-absent-or-stale`。
- **跨件代不混比**：分母按 **件代（`shim` sha16）** 分开，禁合池（`--denom`）。

> ⚠️ **本件只引用、不重写** 上述判别式；实现件若需改动，**唯一实现是 `silent-hit-v2-check.sh` 的 `judge()`**，判据件与之**不得打架**。

---

## §2 ② 腿数 → 上界算式（`k=0` / `k>0` 两支）＋ 现件代所需 `N`

### 2.1 两支算式（**照 `TASK-0719` 口径**）
- **`k=0` 支（功效表口径／rule-of-three）**：`ub(0/N) = 1 − 0.05^(1/N)`（`α=0.05`）。**只许用于 `k=0`**。
- **`k>0` 支**：**Clopper–Pearson 单侧 95% 上界**（解 `P(X≤k; N, p) = 0.05`）。
- 🔴 **口径句（`TASK-0719`／`D-G121`，逐字）**：
  > **『登记速率必须同时登记时间窗与口径名（哪公式／哪侧／`k` 是几）；缺任一项 ⇒ 只能记 `NOINFO`；先写判据里每个算术结果都必须能被牙现算复算。』**
- **`k>0` 而套 `k=0` 式 ⇒ 低报**；基线率闸的 `--decl-formula` 会判 `zero-hit-formula-on-nonzero-sample` **FAIL 点名**（现取 `baseline-rate-gate.sh:203-209`）。
- **上界必须并列两口径**（`D-G104` 第三条）：**单侧 95%** ＋ **`α=0.025` 双侧**。

### 2.2 现算表（本件自算，`2026-09-30T00:26:51+0800`；可复算命令见 §7）
**`k=0` 支 `1 − 0.05^(1/N)`：**

| 目标上界 | 最少腿数 `N` | 该 `N` 的 `ub` | 在册锚 |
|---|---|---|---|
| `≤5%` | **59** | **4.9508%** | — |
| `≤2.26%` | **131** | **2.2609%** | **在册 `≥131 腿` = 2.26%** ✓ |
| `≤2%` | **149** | **1.9905%** | — |
| （现状=175） | 175 | **1.6973%** | 在册 `0/175 ⇒ 1.6973%` ✓ |
| **`≤1.0%`** | **299** | **0.9969%** | **在册 `≥299 腿` = 1.00%** ✓ |
| `≤0.5%` | **598** | **0.4997%** | 在册"598 趟 ≈ 5.3 槽小时" ✓ |

**`k>0` 支 Clopper–Pearson 单侧 95%（本件自算）：**

| 样本 | CP 单侧 95% | ⚠️ 误用 `k=0` 式会报 |
|---|---|---|
| `1/77` | **6.013095%** | `1−0.05^(1/77) = 3.815851%`（**低报 2.20 pp**，`D-G121`） |
| `1/140` | **3.343503%** | `2.117077%`（在册 `t7` 已点名该陷阱） |
| `2/175` | **3.553694%** | `1.697278%` |

### 2.3 出处
- **算法与腿数表**：`build/MilBridge/P0-mvp-segv-report.md` **现取 `:92-100`**（§4②，逐字：`ub(0/N) = 1 − 0.05^(1/N)`）。
- **在册锚**：`ROUTES.md` 现取 `:231`（"`≥131 腿/臂` 的功效口径（`D-G99` 追加位点的 `131(alt)/133(des)`）"）／`:357`（`TASK-0719` 行）。
- **两种上界口径必须并列**：`P0-mvp-segv-report.md` 现取 `:445-446`（功效表口径 `1.697278%` vs 闸口径 Wilson 单侧 `1.522487%`）。

### 2.4 ⇒ **现件代所需 `N`**
- 现件代已读数为 `0/175 ⇒ 1.6973%`（在册，车道 `t44`／`t7`）。
- **若目标是 `≤1.00%` 在册门 ⇒ 需 `N=299`**（现件代再加 **124 腿**）；若要 `≤2%` ⇒ **149**（再加 **−26**，即**已足**）；若要 `≤5%` ⇒ **59**（已足）。
- ⇒ **`TASK-0212` 若要以"在册 `≥299 腿` = 1.00%"口径发新上界 ⇒ 主档 `N=299`**（可选 `175` 同 `N` 对照，但 `175` 只能给 `1.70%`，**达不到 1% 门**）。

---

## §3 ③ 装置代际 ＋ 入口/证据面清单（**逐件路径 ＋ 现取 sha16**）

### 3.1 装置代际（现件代）
| 件 | 路径 | 现取 sha16 |
|---|---|---|
| `.so`（`win32shim`，九位之一） | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **`26da177686acb1f0`** |
| `pf`（九位之一） | `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | **`0b4b65f2c6c7ffd4`** |

- `SELFBUILT_CONFIG` 现取 ＝ **`Release`**（`bash build/selfbuilt-config.sh`）。
- 🔴 **哨兵落后（如实记）**：`/tmp/bridge-frozen.flag` 现取 `WAVE=w80-freeze`／`BASELINE=#80`／`WIN32SHIM=**352855f8dfbf8dc7**`／`PF=0b4b65f2c6c7ffd4`。⇒ **`WIN32SHIM` 哨兵值 ≠ 现取 `.so` 值**（`352855f8dfbf8dc7` ≠ `26da177686acb1f0`）⇒ **件已换代、`#80` 哨兵未跟**；`pf` 两值一致。
- **⇒ 实现件起跑前必须现取 `.so`／`pf` sha16，不许照抄本件或哨兵**（`D-G104` 同族："别把上一代的数当现数"）。

### 3.2 腿跑器入口（`build/MilBridge/tests/SilentHitProbe/**`）
| 件 | 路径 | 现取 sha16 |
|---|---|---|
| **产出端（仓内唯一）** | `build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh` | **`64574cfe296dac19`** |
| **剔除集（唯一来源）** | `build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv` | **`4270ab3da7a1d6d8`**（**24 行**，`needle/trail_sp/trimmed/tag/surface/provenance`） |

- **用法（现取 `:14-20`）**：`--pair <A> <B>`／`--only-shim <BASE> <SO>`／`--only-app <BASE> <DLL>`／`--app-cmd '<CMD>'`（极化形态）／`--replay <RUNDIR>`（**零进程**重算机读行）；公共参数 `--tag`／`--out`／`--to`／`--mode start|click`／`--selftest`。
- **必需环境（现取 `:22-25`）**：`DISPLAY`（**白名单 `:23[0-9]`**）＋ `WPF_PROBE_TAG` ＋ `WPF_PROBE_RUNDIR`，三条**各自单独打印**，缺一 ⇒ `rc=9`。
- **机读末行**：`SILENTHIT_LEGS state=<DONE|NOINFO|FAIL> legs=<n> hits=<n> diff_n=<n> only=<rel|none> ledger=<path>`。
- ⚠️ **射程（现取 `:41-42`）**：**现场形态不跑 gdb** ⇒ 现场可观测第三支只有 `rc139`／`fate`；`term`／`stop-signo11` **只在 `--replay`** 可判。

### 3.3 判据端与台账（**仓内**）
| 件 | 路径 | 现取 sha16 |
|---|---|---|
| 判据牙（`judge()` 唯一实现） | `build/MilBridge/tools/silent-hit-v2-check.sh` | **`9eccf056bf2d7417`** |
| 基线率闸 | `build/MilBridge/tools/baseline-rate-gate.sh` | **`1bad58c07a8264e6`** |
| 基线率闸台账 | `build/MilBridge/tools/baseline-rate-cases.tsv` | **`1a2df056f5677344`** |

### 3.4 证据面：`build/MilBridge/tests/PtsPagesProbe/evidence/**`（现取，逐件）
| 路径（相对仓根） | 现取 sha16 |
|---|---|
| `…/PtsPagesProbe/evidence/app_g1.log` | **`84db0eb62d15e0b2`** |
| `…/PtsPagesProbe/evidence/leg_23.env` | **`285913567aad8516`** |
| `…/PtsPagesProbe/evidence/leg_24.env` | **`f89dac2796faa25d`** |
| `…/PtsPagesProbe/evidence/device.txt` | **`6d2cf7572e7323b7`** |
| `…/PtsPagesProbe/evidence/session.txt` | **`f29093f89eda4f4f`** |
| `…/PtsPagesProbe/evidence/{five_pre_g1.txt,five_post_g1.txt,arm_A/**,device/**}` | （未逐件取；实现件若引用须现取） |

### 3.5 装置入口：`build/MilBridge/tests/PtsPagesProbe/**`（顶层，现取）
| 件 | 现取 sha16 |
|---|---|
| `…/PtsPagesProbe/run-pts-pages-legs.sh` | **`330a90f1f0ac28e4`** |
| `…/PtsPagesProbe/session_inner.sh` | **`f1a582d9ea9788c9`** |
| `…/PtsPagesProbe/legs-to-env.py` | **`ed290f41e5ae6432`** |
| `…/PtsPagesProbe/navclick.py` | **`e3d8b6ec4f5a4f6a`** |
| `…/PtsPagesProbe/shotstat.py` | **`cc1ca161504ef1dc`** |

### 3.6 🔴 覆盖面（现取，**与在册一句不符**）
- `bash ~/w153a/bin/infp.sh list | wc -l` ⇒ **`234`**（`fp_inputs()` 覆盖面）。
- **`build/MilBridge/tests/**` 现取命中 `24` 件**，其中**含** `SilentHitProbe/{run-silenthit-legs.sh,silenthit-trim.tsv}` 与 `PtsPagesProbe/**` 的**具名件**（现取 `close-wave.sh` 的 `fp_inputs()` 显式清单 `:176-296`，**按件路径身份、无 glob**）。
- **⇒ `P0-mvp-segv-report.md` §4⑤「`tests/**` **不在** `fp_inputs()` 覆盖面」现取不成立**（`#71`／`#73` 之后，`tests/` 里的具名件已入名单）。
  ⚠️ **但**：`fp_inputs()` 是**显式清单** ⇒ **新增未列名的 `tests/` 件仍不在覆盖面** ⇒ "改产出端要显式声明"的纪律**仍然成立**（`D-G108`／`D-G120`）。
- **`fp_inputs` 指纹（现取）**：`bash ~/w153a/bin/infp.sh fp` ⇒ **`9a8768f680566966b3c3f3deeb7ffbd84d4ea7e6545bf05e5c80b283434204cd`**。

### 3.7 世代与仓库位（现取，供实现件对拍）
- `git rev-parse HEAD` ⇒ **`14f542115c494cbc8a76802852719b3a4aaac76b`**（分支 `feat-Linux`）。
- `docs/ROUTES.md` 现取 **`3c43663b8adb7165`**／**1054 行**；`build/MilBridge/P0-mvp-segv-report.md` 现取 **`903bb184fcbfc453`**／**545 行**；`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 现取 **`3d96ed2ce8102869`**。

---

## §4 ④ 基线率闸 `BASELINERATE` 现取判词（**现取、逐字**）

### 4.1 现取 A —— 在册注册基线 `2/175`（`gdb` 臂口径 `:185`）vs 现件 `0/175`
```
$ bash build/MilBridge/tools/baseline-rate-gate.sh \
    --registered '2/175@2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185' \
    --observed 0/175 --gate 0.035537 --effect 0.011429
BASELINERATE=FAIL
BASELINERATE_REASON=VOID-PREMISE ① ci_upper(0.0152) < gate(0.0355);以② observed(0.0000) < effect(0.0114) ⇒ 该效应在现世界不可发生
registered=2/175  window=2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185  observed=0/175
ci_upper=0.0152  ci_upper_2s=0.0215  cp_upper=0.0170  fisher_p=0.4986
registered_in_observed_ci=1  gate_closed=1  effect_impossible=1  caliber_disagreement=0
gate_verdict_1s=closed  gate_verdict_2s=closed  required_n=NONE
BASELINERATE_RC=1
```

### 4.2 现取 B —— 成对修前基线 `1/140`（`:238`）vs 现件 `0/175`
```
$ bash build/MilBridge/tools/baseline-rate-gate.sh \
    --registered '1/140@2026-09-28T18:39:39..2026-09-28T20:11:55+display=:238' \
    --observed 0/175 --gate 0.033435 --effect 0.007143
BASELINERATE=FAIL
BASELINERATE_REASON=VOID-PREMISE ① ci_upper(0.0152) < gate(0.0334);以② observed(0.0000) < effect(0.0071) ⇒ 该效应在现世界不可发生
registered_in_observed_ci=1  gate_closed=1  effect_impossible=1  required_n=NONE
BASELINERATE_RC=1
```

### 4.3 现取 C —— **缺时间窗**（降级形态）
```
$ bash build/MilBridge/tools/baseline-rate-gate.sh --registered '2/175' --observed 0/175 --gate 0.035537 --effect 0.011429
BASELINERATE=NOINFO
BASELINERATE_REASON=NOINFO-NO-WINDOW 在册速率缺**时间窗**（形态须为 R/N@时间窗）⇒ 不许用它定 N（D-G118）
BASELINERATE_RC=3
```

### 4.4 判词要点（逐字）
- **是否 `VOID-PREMISE`：是**（**两组现取都判**）—— 两条**并列**条件同时成立：
  ① `ci_upper(0.0152) < gate`（先写的闸门被**排除**）；② `observed(0.0000) < effect`（**要排除的效应量在现世界不可发生**）。
- ⇒ **不得据此宣称改善**（`registered_in_observed_ci=1`：在册速率**落在**观测 CI 内）。
- **缺时间窗降级**：`NOINFO` ＋ `reason=NOINFO-NO-WINDOW`，`rc=3`（**不是绿**，也不许当 `0`）。
- **口径之争先于结论**：若单侧/双侧对闸结论不同 ⇒ `NOINFO reason=caliber-disagreement`（本两次现取 `caliber_disagreement=0`，无冲突）。

### 4.5 时间窗字段从哪里来（**喂入所需**）
- **`--registered` 形态 ＝ `R/N@<时间窗>+display=:<d>`**（P0 `:109`／`baseline-rate-gate.sh` 头部口径句）。
- **字段来源（现取）**：
  - `R`（命中数）／`N`（腿数）＝ 跑批**台账** `runs.tsv` 的列统计（分母按件代分开、去重后计数）。
  - **时间窗** ＝ 该批的**首腿 `ts_start` .. 末腿 `ts_end`**（`runs.tsv` 逐腿时间戳），**且必须带 `display=:` 号**（防串味）。
  - 在册两个可用窗：`2/175@2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185`（`gdb` 臂）与 `1/140@2026-09-28T18:39:39..2026-09-28T20:11:55+display=:238`（成对臂）。
- **`--gate`／`--effect`** 取该在册样本的**上界（功效表口径）**与**点估计**（如 `2/175 ⇒ gate 0.035537 / effect 0.011429`）。
- ⚠️ **无窗 ⇒ 闸响亮 `NOINFO`** ⇒ **不许拿历史速率凑功效**（`D-G118`）。

---

## §5 ⑤ 判据预登记草案（供 `TASK-0212` 实现件**照抄**）

> 以下**先写**、读数后取；每条**可证伪**，并配**反极性**。

### 5.1 可证伪判据（≥3 条）
1. **正极（现件代零命中上界）**：现件代（起跑前现取 `.so`／`pf` sha16）在**无 WM 腿**上跑 `N` 腿，`SILENT_SEGV_HIT` 命中数 `k=0` ⇒ **95% 单侧上界 `= 1 − 0.05^(1/N)` ≤ 目标门**。**证伪**：出现 **≥1** 命中即翻（须照 §2.1 走 `k>0` 支重算）。
2. **检测力自证（成对修前臂）**：同装置、同口径、**只换 `shim` 为修前件**（`abf6879c027c5e73`），修前臂**必须出 ≥1 真命中**（否则该波"零命中"读成绿 ⇒ **装置无检测力，读数作废**）。
3. **上界算程可复算**：报出的上界必须能被 `baseline-rate-gate.sh` 的 `--decl-upper`／`--decl-formula` **逐位复算**：`k=0` 用 `rule-of-three-0hit`、`k>0` 用 `cp-1s`；**混用 ⇒ `FAIL`**（`zero-hit-formula-on-nonzero-sample`／`decl-formula-value-mismatch`）。
4. **分母口径（`D-G94`）**：作废腿／跳过腿／`TRIM_GATE!=ok`／`undeclared>0`／`phase=teardown` **不入分母**；且**跨件代禁合池**（`silent-hit-v2-check.sh --denom`）。
5. **基线率闸非 `VOID-PREMISE`**：必须喂**带窗** `R/N@窗+display`；现取两组都 `VOID-PREMISE` ⇒ 若不带**可比时间窗**，**不许**在报告里写"改善/率变低"。

### 5.2 反极性（**必写，防假绿**）
- **反极 A（假绿探测）**：把现件代换成修前件 ⇒ **判据必须变红**（出命中 ⇒ `HIT=yes`）。
- **反极 B（装置造假／"一剔了之"）**：删或加宽剔除集某个 `needle` ⇒ `TRIM_GATE`／`undeclared` **必须翻转**（改前 `noinfo`／改后 `ok`，及负极腿 `neg-hit-real` 仍 `HIT=yes`／`neg-nontrimable` 仍 `HIT=no`）。
- **反极 C（上界口径）**：对 `k>0` 样本套 `k=0` 公式 ⇒ `baseline-rate-gate.sh` **必须** `FAIL reason=zero-hit-formula-on-nonzero-sample`。
- **反极 D（哨兵/代际）**：给错的世代（如照抄本件 `.so=26da177686acb1f0` 而现场已换代）⇒ **装置自检必须报红**（`shim=` 列 ≠ 现取）。

### 5.3 边界（实现件须**原样声明**）
- **只对单装置成立**（`Xvfb 1280x1024`，**无 WM**）；用户现场是 `xrdp ＋ xfwm4` ⇒ **有 WM 腿无检测力**，该腿记 `NOINFO reason=no-detection-power`。
- `0/N` **≠** 残余窄 `TOCTOU`（`TASK-0211`）已绝迹（只给它的率一个上界）。
- **命中即停**规则若行使 ⇒ 分母变小、上界变宽，须**如实并列**（`t48` / `t7` 先例：`1/77` vs `1/140`）。

---

## §6 主动披露 / `NOINFO` / 边界（逐条）

1. **🔴 我推翻了在册一句（`P0-mvp-segv-report.md` §4⑤）**：「`tests/**` 不在 `fp_inputs()` 覆盖面」**现取不成立** —— 现取覆盖面 **234** 件、`tests/` 命中 **24** 件，且 `run-silenthit-legs.sh`／`silenthit-trim.tsv` **都在**名单里（`close-wave.sh` 的 `fp_inputs()` 显式清单现取含它们）。**但**"改产出端要显式声明"**仍成立**（新增未列名件不在覆盖面）。**建议**：并入下一笔 dated 更正（**不在本件写域**）。
2. **🔴 我推翻了在册一处算术口径（`P0-mvp-segv-report.md` §14 表）**：§14 把 `1/77`（`k=1`）的"功效表口径"上界写作 **`3.815851%`**，而 `3.815851% = 1 − 0.05^(1/77)` —— 这是**把 `k=0` 公式用在 `k>0` 样本上**（**`D-G121` 那一族**，**低报**）。**正确口径（CP 单侧 95%）应为 `6.013095%`**。（§13③ 对 `2/175` 用的是 CP 值 `3.553694%` ⇒ **§13③ 与 §14 表口径不一致**。）**建议**：实现件重算上界时**一律走 CP**，并把该不一致并入 dated 更正。
3. **哨兵落后**：`/tmp/bridge-frozen.flag` 的 `WIN32SHIM=352855f8dfbf8dc7` ≠ 现取 `.so=26da177686acb1f0`（`PF` 一致）⇒ **件已换代、`#80` 哨兵未跟**。**不建议**本件改哨兵（非本件写域）。
4. **`NOINFO`（具名）**：
   - **未跑任何重活腿**（`≥131` 的整批留给实现件、走 `~/heavy-slot.sh`）⇒ 本件**无新上界**（沿用现件代 `0/175 ⇒ 1.6973%`）。
   - **`term`／`stop-signo11` 两支在现场不可达**（`nogdb` 形态无 `gdb.txt`）⇒ 那一格 `NOINFO`（`run-silenthit-legs.sh` §射程）。
   - **`TASK-0201` 的 🟡 未动**：本件只做侦察，不改任何状态记号、不改 `ROUTES.md`。
5. **边界**：本件内一切行号**仅对写入时刻有效**；引用一律以**内容锚**为准。
6. **本件零足迹**：未起 X／未起应用／未跑门禁／未占槽／零 `dotnet`；只读命令；进程未涉（未按 PID 收任何东西，因为没起进程）。

---

## §7 复算命令（逐条可重放，**零槽**）

```bash
R=/home/links-dev/netTest/GitProj/WPFOnLinux; cd "$R"
# ── 装置代际（现取）─────────────────────────────────────────────
sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16              # 26da177686acb1f0
sha256sum build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll | cut -c1-16  # 0b4b65f2c6c7ffd4
bash build/selfbuilt-config.sh                                                  # Release
cat /tmp/bridge-frozen.flag                                                     # 哨兵（WAVE=w80-freeze；WIN32SHIM 落后）
# ── 腿跑器/判据/剔除集（现取 sha16）────────────────────────────
sha256sum build/MilBridge/tests/SilentHitProbe/{run-silenthit-legs.sh,silenthit-trim.tsv} | cut -c1-16
sha256sum build/MilBridge/tools/{silent-hit-v2-check.sh,baseline-rate-gate.sh,baseline-rate-cases.tsv} | cut -c1-16
# ── 判别式现取原文（行号仅本次有效）────────────────────────────
sed -n '241p' docs/ROUTES.md
sed -n '90p;330p' build/MilBridge/P0-mvp-segv-report.md
sed -n '85,105p' build/MilBridge/tools/silent-hit-v2-check.sh    # judge() 三支
# ── 功效现算（k=0 与 k>0 两支）─────────────────────────────────
python3 -c 'print(1-0.05**(1/131), 1-0.05**(1/299), 1-0.05**(1/175))'   # 2.26% / 1.00% / 1.70%
python3 - <<'PY'
from math import comb
def cp(k,n,c=0.95):
    t=1-c; lo,hi=0.0,1.0
    for _ in range(300):
        m=(lo+hi)/2
        if sum(comb(n,i)*m**i*(1-m)**(n-i) for i in range(k+1))>t: lo=m
        else: hi=m
    print(f"CP1s k={k} n={n} = {(lo+hi)/2*100:.6f}%")
cp(1,77); cp(1,140); cp(2,175)          # 6.013095% / 3.343503% / 3.553694%
PY
# ── 基线率闸现取（两组 + 缺窗）────────────────────────────────
bash build/MilBridge/tools/baseline-rate-gate.sh \
  --registered '2/175@2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185' \
  --observed 0/175 --gate 0.035537 --effect 0.011429          # FAIL / VOID-PREMISE
bash build/MilBridge/tools/baseline-rate-gate.sh \
  --registered '1/140@2026-09-28T18:39:39..2026-09-28T20:11:55+display=:238' \
  --observed 0/175 --gate 0.033435 --effect 0.007143          # FAIL / VOID-PREMISE
bash build/MilBridge/tools/baseline-rate-gate.sh --registered '2/175' --observed 0/175 \
  --gate 0.035537 --effect 0.011429                           # NOINFO / NOINFO-NO-WINDOW rc=3
# ── 覆盖面（现取）────────────────────────────────────────────
bash ~/w153a/bin/infp.sh list | wc -l                          # 234
bash ~/w153a/bin/infp.sh list | grep -c 'MilBridge/tests'      # 24
bash ~/w153a/bin/infp.sh fp                                     # 9a8768f6…34c2e04cd
```

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-segv-recon.md | sha256sum | cut -c1-16`）= `34c10aaa0279e6f4`
