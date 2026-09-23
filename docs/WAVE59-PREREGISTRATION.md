
# 波 `#59` 预登记（`TASK-0110` **改题后**：frame/client 时序牙 ＋ 桥侧几何重发确定性回归牙 —— **接线并冻结**）

> ⚠️ **本件由车道 W151A 在接线前预备（骨架）；判据先写于 `~/w151a/criteria.md`（写定 2026-09-24 00:22:00 +0800）
> 与 `~/w149a/criteria.md`（`f1be8bf475d33583`；其 §7.1 为主控对极性方向的裁定）。
> **本件不发明新判据。** 主控 2026-09-24 的四条裁定（语料落仓内／`fp_inputs` 纳入／世代锚本波就做／
> `[27]` 注释只登记不改）已逐条落进下面的 §3、§4、§6。

## §1 本波是什么

**只做接线，零产品改动**（`src/**` 不动 ⇒ 世代绑定九位不动）。
两件牙由车道 W149A 于 `#56` 收官后落地，并各自登记为「未接线」。

| 步 | 牙 | sha16 | 建牙车道 | 未接线登记处 |
|---|---|---|---|---|
| `[32]` `GEOM-BEAT` | `build/MilBridge/tools/geom-revert-beat-check.sh` | **`9412ec0149111348` → `ee43a703736489a3`**（`#59` 本波**加严**：长出一格语料锚读者，见 §4.7；511 → 701 行；自测 12/12 → **19/19**） | W149A 建牙 ／ **`#59` 加读者** | `~/w149a/report.md` §5 ／ 本件 §4.7 |
| `[33]` `GEOM-RESEND` | `build/MilBridge/tools/geom-resend-regression-check.sh` | `cd375326b62f7982` | W149A | `~/w149a/report.md` §5 |

**步数 `31 → 33`**；四处声明（`DECL`／`STEP-NAMES`／口径句／**本件标题行的 `#59`**）**同趟**改。

## §2 承重判据（**继承**，不发明）

### 2.1 `[32]` 事件锚定时序牙（`D-G112`）
承重 = **`B3` 的有无**（`B2`（frame 回到基准）之后**出现**「`EVT ConfigureNotify` ∧ `send_event=0` ∧
尺寸 == 屏尺寸」⇒ **红**；`B3` 全程 `NONE` ∧ `B2` 后覆盖 ≥ 4500 ms ⇒ **绿**）。
`Δ_push` **只作诊断列**；`200 ms` **只**用于贴 `IN_RED_WINDOW`/`LATE_PUSH` 标签。
**禁止**写成「`Δ>200 ⇒ 红」—— 修前臂 `Δ_push` 实测 **64.4–104.3 ms（median 76.25）全部 ≤ 200 ms**
⇒ 那条方向**必造假绿**（现场已证；牙里反向开关**已删**，并内置**假绿探测器**）。
**边界例** `W134A-B1-M1R2-2`（修前臂 16/17 里那条绿）**必须单列、不许静默剔除**。

### 2.2 `[33]` 桥侧几何重发的确定性回归牙（`TASK-0210`）
修后臂 `4e25e4b27d4d5ae1`：**每腿** `CFG_HIT=0 ∧ GEOWRITE≥1 ∧ r_ok=1`；
修前臂 `feef049e9d0e313a`：**只判「回升 ＋ 成对」**（回升率 ≥ **0.70** 且严格大于修后臂 ∧ 正控全 0）。
**禁止「每腿必命中」**；分组**只认趟印 `BRIDGE=`**，腿名与 `BRIDGE` 冲突只打 `NAMETRAP`（检测 ≠ 判红）；
`COUNTEREXAMPLE`／`EXCLUDED` **逐条列名、不许静默丢弃**。

### 2.3 两块**各自成对**，**禁止**合并判一次，**禁止**把两块的腿数/命中数相加。
### 2.4 `C6` 分辨率自检（`D-G112` 口径）：`T ≤ D_ref/4`（`D_ref=41 ms` ⇒ `T ≤ 10.25 ms`）**或事件锚定**；不达标 ⇒ `NOINFO` 且点名。**176 ms 级口径一律 `NOINFO`**。
### 2.5 **恒真谓词禁入**：`_NET_FRAME_EXTENTS` 在 70 腿台账上 `233/233 = 0,0,0,0` ⇒ **不许**进任何判据（牙里只作 `frame_extents=NOT_READ` 留档）。
### 2.6 三态：`PASS`/`FAIL`/`NOINFO`，**`NOINFO` 既不算绿也不算红**；出口码 `0/1/2`。

### 2.7 回归判定四要件 —— **本波按条件句声明（`#59` 不做任何回归判定）**

<!-- PREREG-REGRESSION-FOUR: same-time=yes paired=yes reproducibility=yes fisher-two-tailed=yes tool=build/MilBridge/tools/regression-decision.py -->
**机器声明**：本波**凡称"做过回归判定"处**，`PREREG-REGRESSION-FOUR` **四键全 `yes`**（`same-time`／`paired`／`reproducibility`／`fisher-two-tailed`），**判据件** = `build/MilBridge/tools/regression-decision.py`。

⚠️ **本波（`#59`）不做任何回归判定** —— 它是**仪器接线波**（只加两步 ＋ 换两件牙 ＋ 加语料锚 ＋ 改生效边界），**没有**任何"两臂对拍得出结论"的主张。
⇒ 本条**按条件句读**：它声明的是「**如果**本波在别处声称做过回归判定，**那么**四件必须同时在位」——
**是"这一刻不适用"的声明，不是"我已经做过"的声明**。**不许**把本节读成本波做过四要件。
⇒ 四要件的**判词三态**（`REGRESSION` ／ `NOINFO` ／ `OK`）只在**真做判定的波**（`#55`／`#58`）承重；`#59` 只保证上面那句**承诺**成立。

1. **两臂同刻**：同一装置／同一会话／只换一个文件；两臂**交替**取读数；**禁止跨时刻拼接**。工具侧 = `--same-time`。
2. **成对归因臂**：`--pairs N`（同腿旧/新交替）；`--pair-both`／`--pair-old-only`／`--pair-new-only` 只做**一致性核对**，**不参与判词**。
3. **复现性**：`--old-repro yes|no` **必须与旧臂红数自洽**（`yes ⇒ 旧臂红数 > 0`、`no ⇒ 旧臂红数 == 0`）；**违反 ⇒ `rc=2`**。
4. **Fisher 精确检验双尾**：**分母只算真尝试过的趟**；`p` 与所需趟数**照印留档**，**计划不合规时不许据此下判词**（记 `NOINFO`）。

## §3 反极性（≥5 必红 ＋ ≥2 必 `NOINFO` ＋ 1 阴性对照）

### 3.1 声明面（**已实测**，阴性对照 = 现盘真件必须仍 `PASS`）
| 档 | 扰动 | 期望 |
|---|---|---|
| X1 | 删两行 `run_step`、声明不动 | `FAIL`（`count-mismatch` ＋ `name-set-differs` ＋ `prose-mismatch`） |
| X2 | `DECL` 数字 33 → 31 | `FAIL`（`decl-self-inconsistent` ＋ `count-mismatch`） |
| X3 | `gen` `#59` → `#58` | `NOINFO`（`header-prose-absent`，**不许当绿**） |
| X4 | `STEP-NAMES` 少两个新名 | `FAIL`（`decl-self-inconsistent` ＋ `name-set-differs`） |
| X5 | 预登记缺席 | `NOINFO`（`prereg-absent`） |
| X6 | 两步次序颠倒 | `FAIL`（`name-order-differs` 点名第 32 位） |

### 3.2 牙面（**已实测**，全在仓外副本上）
| 档 | 扰动 | 期望 |
|---|---|---|
| Y1 | 牙1 承重改成「只判 `Δ>200` ⇒ 红」 | 顶层仍 `FAIL reason=FALSE_GREEN` ⇒ **假绿探测器咬住** |
| Y2 | 牙1 删掉 `B3` 判据（恒判绿） | 同上 ⇒ 探测器**不是装饰** |
| Y3 | 牙2 `RISEUP_MIN 0.70 → 1.00`（＝"每腿必命中"） | `FAIL reason=pre_arm=回升率 0.94 < 先写界 1.00` |
| Y4 | 牙2 `FIX_SHA` 常量改成修前件 | 该臂 `FAIL`（三条子判据并行点名）；顶层 `NOINFO single-arm` ⇒ **`NOINFO` 优先于 `FAIL`** |

## §4 设计性变更（**必须写，否则下一趟当漂移**）

1. **语料入仓**：`build/MilBridge/geom-corpus/**` **新建**，**39 腿 / 234 件 / 34 MiB**；
   聚合 sha256（相对路径口径）`0f702ccd8eb3938a03be55e17e0c978013d73eb37485847fcaad6f88b1bb9fe2`。
   **不进** `fp_inputs()`（同 `arm-logs` 裁定：派生件 + 重取是合规动作）。
2. **`inputs_fp` 必变**（设计性）：覆盖面 **155 → 157**（**+2，且只有 +2**）；`geom-` 命中 **0 → 2**。
   ⚠️ `inputs_fp` 的**绝对值随时变**（`#57` 改原生 C 源就让它从 `ecaf53dd…` 变成 `abd349fd…`）⇒
   本件只登记 **delta**；落地的 before/after 由 `land.sh` 现场成对记账。
   ⚠️ 该行**必须排在 `IN_FP_0` 采样之前**。
3. **`known-red.json` 加 `generation.geom_corpus`**（主控裁定 ③）：`+9/−0`、1 个 hunk；
   `schema` 仍 `tline-known-red/4`（**未升版**）；顶层键集合不变；`generation` 键**只新增** `geom_corpus`。
   同趟 `repin-generation.py --why/--check` ⇒ **`REPIN_GENERATION=PASS`**。
4. **`[27] NUL-BYTES` 的计数会动（判词不变）**：`.log`/`.txt` **在** `NULB_EXTS` 名单里 ⇒ 语料进判覆盖面。
   真检测器对语料的读数：`files=234 bytes=34475351 .log=156 .txt=78 hits=0` ⇒ 落地后
   **`files 1243→1477`、`bytes 253,212,058→287,687,409`、`.log 14→170`、`.txt 169→247`**，
   **`NULBYTES=PASS` 不变、不加 ❌**；`tools_sh=37` 不变。
   ⚠️ `nul-bytes-check.sh:40-43` 的注释写「现场 **14** 件 `.log`」⇒ 落地后陈旧（**裁定 ④：只登记不改**——
   该件在 `fp_inputs` 白名单里，改注释会白挪一次指纹）。
5. **`[16] DEFECT-REGISTRY` 的 `DEFREG_DECLDRIFT` 由 0 翻 1**（`known-red.json` 变 ⇒ 与
   `defect-registry-declared.tsv:2` 的 `DECL-ANCHORS` 分叉）。**`DEFREG=PASS` 与 `rc` 不变**
   （该行是非门禁诊断行）。⇒ **主控同趟**更新该 TSV 的 `KRJ=` 新值即可清掉。
6. **牙1 换新版**（裁定 ③ 加严）：`9412ec0149111348` → **`ee43a703736489a3`**（511 → **701 行**，
   `+185/−3`、8 hunk；**只 3 行被替换**，且都在集成点上：`top_verdict(...)` 调用改成外层
   `top_verdict_with_anchor(...)`、`GEOMBEAT=` 的格式串与实参各一行）。自测 **12/12 → 19/19**
   （**既有 12 例逐字未变**＋新增 7 例）；真装置 `GEOMBEAT_LIVE=4/4` 未变。
7. **`[32]` 多一行机读行**：`GEOMCORPUS=PASS|NOINFO`（与 `GEOMBEAT=` 并列；两行都匹配 `run_step` 的
   显示正则）。顶层 `GEOMBEAT=` 新增自证字段 `corpus_anchor=<state>`。
8. **其余三支扫面牙零位移**（实测）：`[9] BUILD-HYGIENE`（只认 `.csproj` ＋ 脚本语料）、
   `[15] QUOTE-TRAP`（只扫 `*.sh|*.py`）、`[28] HYGIENE`（`code_exts='.sh .bash'`、`doc_exts='.md'`、证据根 `arm-logs`）。

## §5 **射程边界**（逐条写死，免得被读成本步的全域结论）

1. **这两步是"档案牙"**：它们对**冻结语料** `build/MilBridge/geom-corpus/**` 作**只读复算**，
   **不跑应用腿、不测当前桥件** ⇒ 「**桥件被改回**」**不**由这两步咬到。
2. 两步**不读** `_NET_FRAME_EXTENTS`（恒真谓词，`233/233 = 0,0,0,0`）⇒ 该属性**没有**新判据。
3. **`--corpus` 的形态已被实测锁死**（三条）：`--corpus=<不存在>` ⇒ 两件**都** `rc=2`
   （`GEOMBEAT=NOINFO reason=no-input` / `GEOMRESEND=NOINFO reason=no-input`）；
   `--corpus=<仓内 arm-logs（无腿子目录）>` ⇒ 同样 `rc=2`；**只给单臂** ⇒ `NOINFO reason=single-arm`
   （`rc=2`）。⚠️ 而 `verify-all.sh:307` 的 `run_step` **只认 `rc==0`** ⇒ **缺语料 = 该步 ❌**
   （**不是**"没信息"）⇒ 这正是**裁定 ①「语料必须收进仓」**的理由；指 `$HOME/w134a/run` 这类
   **仓外可变态**会让这两步变成**机器相关的红**（`D-G31` 家族）。
4. **两步的形态 = 「纯读、秒级」的普通绿步**（**不**走在册红形态）：实测墙钟 **0.05 s / 0.22 s**、
   峰值 RSS **12.9 / 17.4 MB**、**无网络**（`curl|wget|http` 命中 **0**）、**无 `X`**、**无 `dotnet`**。
   `[30] UIA-DOOR` 的"在册红形态"只适用于"红 == 设计"的步，本波两件**没有**这个前提。
   ⚠️ 若某天它们变红 ⇒ **那是真红**，走登记或修，**不许**改成在册红形态洗绿。
5. `--verify-arms` 读**仓外**应用目录（`~/w89a|w134a|w114a|wc03|wc11/app`）⇒ **不进 `rc`**
   （机械证：`if verify:` 段在 `judge()` 算完**之后**只打印）⇒ 它只把"两臂件在盘上"印上屏。
6. **语料锚只证"字节没变"**，**不**证"判出来的结论对"；且**不随桥件换代而变**（见 `generation.geom_corpus.note`）。
7. **语料锚读者的射程 = 只有 `--corpus=` 模式**（**明说**）：`--leg=` 模式按定义不适用
   （它比的是"整份语料"）⇒ 打 `GEOMCORPUS=NOINFO reason=leg-mode-not-a-corpus` 且**不传染顶层**。
   ⚠️ ⇒ **`--leg=` 是一个绕过锚的入口**。两条护栏：① 第 `[32]` 步**只**用 `--corpus=` 调用；
   ② 绕行时屏上**必有一行**说"本格未行使"。**这是射程声明，不是假牙**（`D-G112` 的锚因此
   **不再**是"零机器红"：换整套自洽语料 ⇒ 现场聚合 ≠ 声明 ⇒ `NOINFO` ＋ 点名）。
8. **`Δ_push` 落在灰带（200–4500 ms）**⇒ 按裁定**一律红**（`Δ` 只贴 `LATE_PUSH`）；
   「`LATE_PUSH` 是不是另一种成因」这一格 **`NOINFO`**（本语料里 `LATE_PUSH` **0 条**，无从判）。

## §6 未接入的（**如实登记，逐条**）

1. **`generation.geom_corpus` 的读者已同趟长出**（裁定 ③ 加严，见 §4.6／§4.7）：第 `[32]` 步的牙1
   在 `--corpus=` 模式下把现场聚合与声明值**全 64 位逐字**比，不等 ⇒ `NOINFO` ＋ 点名
   `geom-corpus-declared-mismatch` ⇒ 顶层 `NOINFO`。
   **残留缺口（明说）**：`--leg=` 模式**按定义**不适用本格 ⇒ 那条路是**声明过的旁路**
   （§5.7 的两条护栏）。若要彻底关掉，下一趟可加 `--require-corpus-anchor` 之类的强制档或
   照 `arm-log-sha-check.sh` ＋ 第 `[8]` 步先例加一件**独立外挂读者**。
2. **`D-G113`（假旋钮）**：`geom-resend-regression-check.sh` 的 `--fix=`／`--pre=` 用法行声明"可换臂"，
   而 `judge(rows)` 不收它们 ⇒ 只改 `NOTE` 打印。**`#59` 不传这两个开关**；修法（① `judge()` 收参
   或 ② 删两个开关）归**下一颗仪器牙**。
3. **真 hc 应用腿上当场跑这两颗牙**：禁 `dotnet` ⇒ `NOINFO`。
4. **`--live-selftest`**（私有 `Xvfb :227` ＋ 自写极小 X 客户端）**不进** `verify-all`；该格沿用 W149A 的 `4/4`。
5. **源级反极性**（改 `src/**` 逐字节复原桥件 + 重建）：写域外 ＋ 禁 `dotnet` ⇒ `NOINFO`。
6. **端到端 `verify-all.sh` 的 33 步全绿**：由主控编排（本波只交"接线 ＋ 读数"）。
