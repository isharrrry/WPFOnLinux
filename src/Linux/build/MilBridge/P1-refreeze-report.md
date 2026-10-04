# P1 重冻结批（`t74`，队长执行）—— 对齐「现盘 / 登记表 / 冻结块」三角

读时 `ts=2026-09-28T21:53:26.518+0800`｜执行者＝队长（四个成员当时全部空转，按用户指示「没完成队长要想办法完成」接管）

## 1 起因
`t67` 重建 CoverageProbe 后**重取了三支臂日志** ⇒ 现盘离开冻结 ⇒ 处置前状态：
`ARM-LOG-SHA=FAIL pass=2 fail=3`（登记表＝旧值 vs 现盘＝新值）× `COLUMN-FLOOR=PASS`（登记表旧值＝冻结块旧值）。
两牙的命门 ＝ **只剩同时绿当且仅当「现盘 ＝ 冻结块」**（`t72` 已查清并据裁定 (B) 回退过一次）。

## 2 六处耦合（全部只重钉臂日志派生声明；**世代号不变**）
| # | 件 | 改动 | 成对读数 |
|---|---|---|---|
| ① | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `#80` 块内 `ARM-LOG-SHA` 的 `tab-anchor`／`tab-zero`／`tab-rtl` 三行 sha16 换现盘值（`:61`／`:62`／`:63`）＋ 一条重钉说明（**不以 `# ⏪ ` 起头**） | 件 sha16 `b96d4312565a3c49` → `b27ff6332f263495` |
| ② | `build/MilBridge/known-red.json` | `generation.arm_logs` 三值换**全 64 位** | `6351a46296d17b28` → `29219b6f071c6361` |
| ③ | `build/MilBridge/tools/wave-freeze-consistency-check.py` | `:832` 模板里 `tab-anchor sha16=…` 换新值 | — |
| ④ | `docs/CURRENT-STATE.md` | 第 `9` 行 `sha16=` 随基线件重算 | `b96d4312565a3c49` → `b27ff6332f263495` |
| ⑤ | `build/MilBridge/HANDOFF-NEXT.md` | 第 `28` 条 `cell=#3`（`sed -n '9p'`）与 `cell=#1`（`infp` 指纹）同趟追写 | 见两份 dated 行 |
| ⑥ | `build/MilBridge/tools/defect-registry-declared.tsv` | 同趟 `--emit`（`KRJ` 锚刷新） | `DECLDRIFT=0` |

## 3 三牙读数（修后现取）
- `ARMLOG_SHA=PASS shape=flat logdir=/home/links-dev/netTest/GitProj/WPFOnLinux/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0`
- `COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=29219b6f071c6361 base=b27ff6332f263495 corpus=0cebc0afd5142fbf`
- `DEFREG=PASS declared=223 route_ids=223（每个声明编号在其 req 的每个 route 文件里都在 ∧ **现场 route 出现集未超出 req**；无未声明编号）`
- `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`（`cell=#1` 追写前为 `DIVERGED … #1:covered-file-changed-since-ts`）

## 4 世代号不变的依据（逐字）
本次**只**改「臂日志（派生件）的声明」与其两处承载（基线件 `#80` 块内三行、`known-red.json` 三值）＋ 检查器模板 1 处；
**九位未随本次动作变动**（`provider`／`win32shim` 等的位移发生在 `t63`，不是本次）⇒ 不构成新世代 ⇒
`BASELINE-FROZEN gen=#80` **保持不变**，只更新其 `sha16=`（因为基线件内容变了）。⚠️ 该判断具名在册，供复核者推翻。

## 5 自伤一条（当场修，零残留）
首次落说明行时我用了 `# ⏪ **dated 重钉…**` 起头 ⇒ 被 `column-floor-check.sh` 的块头形态判定算作**块头** ⇒
`COLUMN_FLOOR=NOINFO reason=block-header-form-mismatch hdr_forms=awk61/md60`（两种机制计数不等 ⇒ 它拒绝判）。
修法 ＝ 把该行起头改成带缩进的 `#   （重钉说明…）`（不匹配 `^# (RE-FROZEN #|⏪ )`）⇒ 复跑 `COLUMN_FLOOR=PASS`。
**教训**：在基线件的**块内**加任何行，必须避开该件自己的**块头形态**（`^# ⏪ ` 与 `^# RE-FROZEN #`）。

## 6 `NOINFO`（具名）
① 未跑整趟门禁（会构建 ⇒ 动九位）；② 未重取任何臂日志（本次是**改声明**、不是重取）；③ 本件不声称两页可用（`TASK-0007` 与 `TASK-0201` 的终局见 `§13`／`W8`）。

## §7 ⏪ 独立复核趟（`t74` attempt 2 ＝ `scribe`，读时 `ts=2026-09-28T22:51:5x–22:54:1x+0800`；**本节为追加，§1–§6 一字未动**）

本趟把「六处耦合 ＋ 两条牙的**命门关系** ＋ 终态读数」**逐格现取自算**（不引用任何上一代列印）。
口径：**改前** ＝ `git show 335185e^:<件>`（重冻结**之前**那一笔），**改后** ＝ 工作树现取；每格给 `sha256` 前 16 位／行数。**行号一律「仅本次有效」**，必要时并列**内容锚**。

### §7.1 六处耦合逐处成对（改前 → 改后 ＋ 锚）
| # | 件 | 改前 `sha16`／行 | 改后 `sha16`／行 | `numstat` | 改动面（**内容锚**；行号仅本次有效） |
|---|---|---|---|---|---|
| ① | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `b96d4312565a3c49`／4605 | **`b27ff6332f263495`／4606** | `4 3` | `# RE-FROZEN #80`（**当前冻结基线**，块头在本件头段）块内三行 `# ARM-LOG-SHA arm=tab-anchor/tab-zero/tab-rtl`（现取 `:61–:63`）：`1c43a12dcaa5718a`→`2e62d68ed5edd5e7`／`9150c3a26a3cb789`→`b5239c4e5b95fa56`／`92570318851ca7e8`→`70feb4b5d4ab80f7`；**另加 1 行**缩进起头的「重钉说明」（现取 `:67`，**刻意不以 `# ⏪ ` 起头** —— 见 §5 自伤条） |
| ② | `build/MilBridge/tools/wave-freeze-consistency-check.py` | `e4393879eaca84f0`／918 | **`77ec0eeec0b443e2`／918** | `1 1` | 自测模板那一行（现取 `:832`）：`open(tpl2,'w').write('# template\n# ARM-LOG-SHA arm=tab-anchor sha16=1c43a12dcaa5718a\n'` ⇒ `…sha16=2e62d68ed5edd5e7` |
| ③ | `build/MilBridge/tools/defect-registry-declared.tsv` | `5ac1ffa46b1e5a59`／233 | **`9b59cdfb0232b54d`／233** | `2 2` | `# DECL-GEN`（`(--emit) 20:56:17` ⇒ `21:53:02`）＋ `# DECL-ANCHORS`：`KRJ 6351a46296d17b28→29219b6f071c6361`、`AB b96d4312565a3c49→b27ff6332f263495`、`CS 13077b52c938f8af→a055826ed52fd67b`（**同趟 `--emit`**） |
| ④ | `docs/CURRENT-STATE.md` | `13077b52c938f8af`／943 | **`a055826ed52fd67b`／943** | `1 1` | 第 `9` 行（**仅本次有效**）机读行 `> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 → b27ff6332f263495 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（**`gen=#80` 未变**） |
| ⑤ | `build/MilBridge/HANDOFF-NEXT.md` | `ece5bb8fdac0e7e5`／584 | **`affd96b95dc19edf`／591** | 该笔 `3 0`；本趟 `1 0` | 该笔新增三行：`cell=#3`（值 `> BASELINE-FROZEN gen=#80 sha16=b27ff6332f263495 …`，`ts=21:53:01.432`）＋两行 `cell=#1`；**本趟追加** `cell=#9`（见 §7.4） |
| ⑥ | `build/MilBridge/known-red.json` | `6351a46296d17b28`／509 | **`29219b6f071c6361`／509** | `3 3` | `generation.arm_logs` 三值换**全 64 位**（`tab-zero`／`tab-rtl`／`tab-anchor`） |

**⑥ 的回环证（机器证，本席现算）**：把改后件里那三个 token **改回改前值** ⇒ `cmp` 与 `335185e^` 版 **`rc=0`（`IDENTICAL`）**，且两版**逐行只差 3 行**（＝那三行）⇒ 「**除那三个 token 外与改前逐位相同**」成立（改后 `29219b6f071c6361`／回环 `6351a46296d17b28` ＝改前 `6351a46296d17b28`）。
**同趟性**：六件对 `335185e` 现取 `git diff --numstat` **全空** ⇒ 该笔之后无人再动它们（本趟只追加 ⑤ 的 `cell=#9` 一行，见 §7.5）。

### §7.2 命门四格（**仓外**沙箱只用 `335185e^:` 的旧件副本 ＋ 现盘臂日志／语料；四格全真跑）
| 格 | 登记表 `known-red.json` | 冻结块 `ACCEPTANCE-BASELINE.md` | `ARMLOG_SHA`（步 `[14]`） | `COLUMN_FLOOR_ARMLOG`（步 `[15]`） | `COLUMN_FLOOR` |
|---|---|---|---|---|---|
| ① **改前世界** | 旧 `6351a46296d17b28` | 旧 `b96d4312565a3c49` | **`FAIL pass=2 fail=3` rc=1** | `PASS n_decl=5 n_ok=5` | `PASS` rc=0（`reg=6351a46296d17b28 base=b96d4312565a3c49`） |
| ② **只改登记表**（`t72` 的 (甲)） | 新 `29219b6f071c6361` | 旧 | `PASS pass=5 fail=0` rc=0 | **三臂 `MISMATCH`**（冻结块＝旧值 vs 登记表＝新值） | **`FAIL` rc=1**（`reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1`） |
| ③ 只改冻结块 | 旧 | 新 `b27ff6332f263495` | **`FAIL` rc=1** | **三臂 `MISMATCH`** | **`FAIL` rc=1** |
| ④ **现世界（重冻结后）** | 新 | 新 | **`PASS pass=5 fail=0` rc=0** | **`PASS n_decl=5 n_ok=5 bad=无`** | **`PASS` rc=0**（`reg=29219b6f071c6361 base=b27ff6332f263495`） |
⇒ **「两牙同时绿 ⟺ 现盘 ＝ 登记表 ＝ 冻结块」** 由四格钉住；①②③ 三格各有一种非同时绿 ⇒ **重冻结**（而不是只改登记表）是唯一真解（`t72` 的 (B) 裁定在此复现）。
**① 格的三臂 decl/live（原样）**：`tab-zero FAIL decl=9150c3a26a3cb789 live=b5239c4e5b95fa56 nlink=2`／`tab-rtl FAIL decl=92570318851ca7e8 live=70feb4b5d4ab80f7 nlink=2`／`tab-anchor FAIL decl=1c43a12dcaa5718a live=2e62d68ed5edd5e7 nlink=2`（`tline`／`textlineproto` 两臂 `PASS`）⇒ 修前 `required=5 declared=5 pass=2 fail=3`。

### §7.3 五行原样输出（本席现取，每格带亚秒 `ts=`）
```
ts=2026-09-28T22:51:57.776+0800  ARMLOG_SHA=PASS shape=flat logdir=/home/links-dev/netTest/GitProj/WPFOnLinux/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0
ts=2026-09-28T22:51:58.255+0800  COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无   ＋  COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=29219b6f071c6361 base=b27ff6332f263495 corpus=0cebc0afd5142fbf
ts=2026-09-28T22:53:0x+0800（两遍）  DEFREG=PASS declared=223 route_ids=223（…无未声明编号）
                                  DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-
ts=2026-09-28T22:53:26.788+0800  HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none
ts=2026-09-28T22:54:12.472+0800  STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62（唯一 NOINFO＝`FrameProbe-frame rc=2`，属约定；本会话另两条射程外红由 `1a46079` 的射程扩展收编）
```
**修前对照（同一批牙、沙箱 ① 格）**：`ARMLOG_SHA=FAIL … pass=2 fail=3` `rc=1`（`ts=22:52:47.998`）⇒ 本件要消的那条红**先在沙箱里被复现成红、再在现世界被验成绿**（不是「照抄一条旧读数」）。

### §7.4 世代与四声明（复核 §4 的判断；**结论：世代不变**）
- **依据（现取）**：(a) `docs/CURRENT-STATE.md:9` 仍是 **`gen=#80`**（只换 `sha16=`）；(b) 基线件头段块头仍是 `# RE-FROZEN #80 —— ✅ **当前冻结基线**`（**没有新块落地**，本件 4606 行里仍是 47 个块）；(c) 本次改动面**只有**「臂日志派生声明」及其两处承载 ＋ 检查器自测模板 1 行 ＋ ③④⑤ 三处台账/机器值 ⇒ **九位未随本次动作变动**；(d) 权威路径表 `NINE_PATHS`（`build/MilBridge/tools/wave-freeze-consistency-check.py:104-115`，**仅本次有效**）现取两口径同值 **`f951e80b55e85782`** ⇒ 本趟**未**改它。
- **四声明现取（全部未变）**：`# VERIFYALL-STEPS-DECL: 62 gen=#81` 首行｜`# VERIFYALL-STEP-NAMES:`（62 项）｜头注释口径句（`#81` 收官起那条，本波**不加步**）｜`docs/WAVE81-PREREGISTRATION.md`（本波零产品改动 ⇒ 无新预登记；该件现取未动）。
- **`cell=#9` 同趟复核（本趟唯一追加行）**：`⏪ **机器值契约更正 · cell=#9** … 现值 ＝ f951e80b55e85782（命令：sed -n '104,115p' …）`（`ts=2026-09-28T22:53:22.291+0800`）⇒ `HANDOFF_MV` 判 `cell=#9 state=equal corrected=f951e80b55e85782 live=f951e80b55e85782`。**值不变**（九位未动）⇒ 此行是「复核过」的留痕，不是被迫刷新。

### §7.5 不变量／哨兵／模式守恒／本趟写入面
```
ts=22:53:0x  ^run_step "            = 62        （不变量①）
ts=22:53:0x  coverage(infp list)    = 234       （不变量②）
ts=22:53:0x  # VERIFYALL-STEPS-DECL: 62 gen=#81 （不变量③）
ts=22:53:0x  run_step "FP-MANIFEST-TEETH" … --expect 234   （不变量④；`verify-all.sh` 行号仅本次有效）
哨兵：cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag ⇒ IDENTICAL（两枚同值 `b26b245f75a2ea70`，mtime 22:46:49.69x，**他者**所写；本席从未写哨兵）
模式守恒（两口径成对）：`stat -c %a` 六件全 `644`、本载体 `644`；`git ls-files -s` 六件全 `100644`
本趟写入面＝**2 件**：`build/MilBridge/HANDOFF-NEXT.md`（`cell=#9` 一行，`numstat 1 0`，`590→591` 行）＋ 本载体（追加本节）
覆盖面指纹：写前后 `fp` 逐位同值 `0e64a80b99b483b15b009cf367c2f73152e604e2e632c3f145c977cbf2f852eb` ⇒ `HANDOFF-NEXT.md` **不在**覆盖面（第 `28` 条无需再追写 `cell=#1`）
```

### §7.6 `NOINFO`（具名，既不算绿也不算红）
① 本趟**未跑整趟门禁**（会构建 ⇒ 动九位／`inputs_fp`）⇒ 两条牙的**端到端门禁步**绿未验，只验**牙本体**与**判据面**；② 本趟**未重取任何臂日志**（重冻结是改声明；三份 `nlink=2` 硬链接与内容逐位未动）；③ `STATICJAWS` 唯一 `NOINFO`＝`FrameProbe-frame rc=2`（约定）；④ 本件**不**声称两页可用（`TASK-0007`／`TASK-0201` 的终局见 `§13`）；⑤ 哨兵值在他者改写中（`cmp` 恒 `IDENTICAL`，但**值**非本席可证来源）。
**本件自证**：`head -n -1 build/MilBridge/P1-refreeze-report.md | sha256sum | cut -c1-16` ＝ `14a74242e502e744`（本行系末行；上列各节即被哈希的全文）
