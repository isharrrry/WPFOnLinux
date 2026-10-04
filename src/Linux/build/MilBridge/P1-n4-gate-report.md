# P1-N4-GATE（`t145` · W65：堵 `N4` 的「登记即算」声明式假绿通道（`C-C`）＋ 色锚 `C-A` 落成「今天就能跑、今天必红」的读数）

> **来源**：`t142` 载体 `build/MilBridge/P1-n4-identity-criteria.md`（205 行／sha256 `a361b07ab72d8dbe096d319ce8e4d4d2b594bb5d99affb7769a2b59845db33b7`）的 `C-C`／`C-A` 经队长裁定三十五判**必修**。**本席先完整读了该载体的 §1／§2／§3 再动手**：`§1.2`（`PTS_N4_POSITIVE_FP` 的现行语义：**全部判定 ＝ 声明值 == 实测两腿 `fr_sha`**）／`§2.1 a1`（色锚：四色现取 0 px、`LightGray` 死锚、`k=23` 无锚）／`§2.2`（无已知良好帧）／`§2.3`（`ink` 恒真／行带数 1／区域限制）／`§2.4 d2`（`[GEO]`）／`§2.5`（外部工具 ABSENT）／`§3 C-A`（逐色 RGB 与"基线全 0、真帧 ≥200"的期望形状）。
> **写域**：`build/MilBridge/tools/pts-pages-guard.sh`（含 `--selftest`）＋ `build/MilBridge/P1-realized-criteria-report.md`（`N4` 段 dated 追加）＋ 本件。**未碰** `HANDOFF-NEXT.md` 的 `cell=#1`（**有意未登记**，见 §6）／`src/**`（`t141` 在飞）／任何 `.cs`／两枚哨兵；**相位位 `degraded` 未翻**；未跑整趟门禁／构建／跑腿／显示位（`PIL`/`numpy` 只用于**纯读**像素计数）；未 `git add/commit/push`。

## §1 收尾必交①：逐件改前/改后

| 件 | 改前 sha16 / 行数 | 改后 sha16 / 行数 | `numstat` | 删行逐条（5 行，全部可追溯） |
|---|---|---|---|---|
| `build/MilBridge/tools/pts-pages-guard.sh` | `a1f192aa760e418a` / 1136 | **`265b9d6b72853749`** / 1301 | **`170 5`**（删行 **5**） | ① `if [ "${PTS_N4_POSITIVE_FP}" = … ]; then _pos=…,n4; else _n4miss=1; fi`（**旧 n4 判定本体 ＝ 病灶**：只有指纹对拍）② `chk PASS … "t136·N4 正身份登记匹配 ⇒ 正证据 n4"`（旧期望，按 `C-C` **收紧**）③–⑤ 旧断言块三行（`positive=n4,differ` → 改为"无支撑 ⇒ `positive` 不含 `n4`"） |
| `build/MilBridge/P1-realized-criteria-report.md` | `281b40613d6f1f34` / 214 | **`f4c6f9a1afacb28b`** / 224 | **`10 0`**（**删行 0**——纯插入） | —（`N4` 段 dated 追加，插在 `### 空态参照集：**重登记**…` 之前，原句一字未动） |

**写前像**：`~/w281-scribe/t145/bak/pts-pages-guard.sh.pre-t145`（`a1f192aa760e418a`／1136 行）与 `…/P1-realized-criteria-report.md.pre-t145`（`281b40613d6f1f34`／214 行）；两件写前 `stat -c %h` ＝ 1、改后 `h=1`；守卫 `mode 755`、判据件 `mode 644`（不变）。

## §2 收尾必交②：`--selftest` 成对读数 ＋ 承重证明

| 时机 | 读数 |
|---|---|
| **开工时自己现取**的基线（**不是**派单给的 66/0） | **`PASS pass=72 fail=0`**（守卫 `a1f192aa760e418a`；`t144` 的 8 条断言已在位） |
| 改后 | **`PASS pass=80 fail=0`**（+8 条断言；**未低于基线**） |
| 过程中两处期望的**收紧**（方向表，**无一处放宽**） | ⓐ `t136·N4 正身份登记匹配` `PASS → NOINFO`（该夹具**无帧** ⇒ 登记拿不到独立支撑 ⇒ 按 `C-C` 不得给绿）ⓑ `t136·n4 点名(含 differ)` 断言改严：由"期望 `positive=n4,differ`"改为"**期望 `positive=differ` 且不含 `n4`**" ⇒ 两处都是**收紧**，且都由新逻辑**承重**（见下） |
| **承重证明**（突变体：把 `C-C` 的支撑判定拆掉——`if [ "${_n4hit:-0}" -ge 2 ]` → `if true`，现取守卫 `:571`） | **`FAIL pass=76 fail=4`**，✗ 恰为该 4 条（`t136·…无支撑 ⇒ 不给绿`／`t136/t145·无支撑 ⇒ positive 不含 n4`／`t145·(a) DECLARED-ONLY`／`t145·(a) positive 不含 n4`）⇒ **新逻辑承重、假绿通道当场复现** |
| 突变体清理 | **现取**：`ls build/MilBridge/tools/zz-t145-mutant.sh` ⇒ **无此件**；`git status --porcelain \| grep -c 'zz-t145'` ＝ **0** ⇒ **夹具已清、`tools/**` 零残留**（教训：突变体放仓外会因 `SELF_DIR/../../..` 推出的 roster 路径不可读而早退 ⇒ 只能"仓内临时件 ＋ 同命令删除"） |

**新增腿（`t145`，逐条现取）**：`(a)` 登记无支撑 ⇒ `PTS_N4=DECLARED-ONLY`＋`positive` 不含 `n4` ✓／`(b)` 登记＋支撑成片（夹具帧：`GhostWhite`300px＋`Beige`300px，基线帧四色全 0）⇒ `positive=n4(support=color-anchor:…)` 且整步 `PASS`（**正极**）✓／`(c)` 帧在但四色缺 ⇒ `PTS_COLORANCHOR=FAIL reason=declared-color-anchor-absent`＋`expect_min=200` ✓／`(d)` `k=23` ⇒ `NOINFO reason=no-anchor-registered-for-k23` ＋ 基线标定 `all_zero=yes` ✓。

## §3 收尾必交③：`C-C` 的两个方向（**真树实跑**，非沙箱）

**改动本体**：`n4` 源**不再**"指纹对拍即成立" —— 除声明值与两腿 `fr_sha` 逐位相同外，**必须**再有一条**守卫自己现算**的独立可证伪读数：色锚扫描（`color_px_scan`，`>=COLOR_ANCHOR_MIN` 的色数 `>=2`）。⇒ 否则 `PTS_N4=DECLARED-ONLY reason=n4-registration-without-independent-support` ＋ `cannot+=`（**不给绿**）。契约块同趟 dated 追加（原句未删）。

| 方向 | 构造（真树 `realized` 副本：在册证据目录） | 现取读数 |
|---|---|---|
| **反极（必须不给绿）** | `PTS_N4_POSITIVE_FP='ef3fd6765f18f51b,ef3fd6765f18f51b'` ＝ **把今天两腿的 `fr_sha` 原样登记** | `rc=1`；**`PTS_N4=DECLARED-ONLY phase=realized reason=n4-registration-without-independent-support declaration=ef3fd6765f18f51b,ef3fd6765f18f51b support_hits=0 support_scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 support_min=200`**；`PTS_N1_POS=… positive=none …`（**`n4` 不在 `positive` 里**）；`cannot` 含 `n4-declared-only(no-independent-support)` ⇒ **登记即算的假绿通道已堵** ✓ |
| **正极（按读数如实判）** | 夹具 `c51`：同样登记 ＋ **帧里色锚成片**（基线帧四色全 0） | `positive=n4(support=color-anchor:2colors>=200)`；整步 **`PASS`** ✓（`t145·(b)` 腿，现取） |
| **另一条真实读数（今天）** | 真树 `realized` 副本、**不登记** | `PTS_COLORANCHOR=FAIL …`（见 §4）⇒ 今天本面**红**，与"两页都没绘出内容"一致 |

## §4 收尾必交④：`C-A` 的**今天实跑**读数（活锚四色 px ／ 反极基线 ／ `k=23` 的 `NOINFO`）

**本席自算（`t145`；`PIL`＋`Counter`，纯读）**：

| 帧（`evidence/shots/g1/`） | `GhostWhite` | `Beige` | `DarkGreen` | `LightGoldenrodYellow` | `LightGray`（**不入集**） | `ink` | 行带数 | 帧 sha16 |
|---|---|---|---|---|---|---|---|---|
| `boot.png` | **0** | **0** | **0** | **0** | **44** | 480000 | 1 | `b21eb530afd3c66c` |
| `k23.png` | **0** | **0** | **0** | **0** | **51** | 480000 | 1 | `ef3fd6765f18f51b` |
| `k24.png` | **0** | **0** | **0** | **0** | **51** | 480000 | 1 | `ef3fd6765f18f51b` |
| `last.png` | **0** | **0** | **0** | **0** | **51** | 480000 | 1 | `ef3fd6765f18f51b` |

- **反极基线（阈值由此标定，不是"看起来该是 0"）**：现盘空态帧四色**实算全 0**，而同帧 `LightGray` **实算 44/51 px** ⇒ 该计数**是活的**（能把"有该色／没该色"分开）⇒ 判据取 `>= COLOR_ANCHOR_MIN`（**硬写 200、不设 env 旋钮**：旋钮只会被用来放松）✓。守卫侧现取：`PTS_COLORANCHOR_BASE=frame=boot.png scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 min=200 all_zero=yes dead=none`。
- **今天必红（如实记为红）**：`COLOR-ANCHOR-ABSENT k=24 expect>=200px&hits>=2 measured=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=0 baseline(boot.png)=…全 0…` ＋ `PTS_COLORANCHOR=FAIL k=24 scan=… hits=0 expect_min=200 expect_hits=2 … reason=declared-color-anchor-absent` ⇒ `fails+=("leg24-color-anchor-absent(hits=0<2,…)")` ⇒ 真树 `realized` 副本 `PTS_GUARD=FAIL`（除既有的两腿 `frame-identity(∈{…})` 外**新增**这一条）。
- **`k=23` 具名 `NOINFO`**：`PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23`（`RichTextBoxDemo.xaml` 无具名色）—— **严禁**用"k=24 有锚"推广 ✓；本支**只印行、不折 `cannot`**（否则任何"没有帧"的目录都会被整体读成不可判；**本面不给绿**这一点不变，且 `n4` 的支撑也取不到 ⇒ 假绿仍堵住）。
- **相位**：本面**两相位都跑**（派单：预先就位、不等相位翻转 ⇒ 今天就能跑）。**成对读数（`degraded` 主件，写前像 vs 现件）**：两侧判词均为 `PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),native-ledger-absent(PTS_GAP n=0) … phase=degraded`，**现件在该 `fails=` 里新增 `leg24-color-anchor-absent(hits=0<2,…)`** ⇒ 如实记：**这是派单要求的"今天必红"**（不是放松、也不是相位翻转）。
- **反过读（写死，照 `t142` 的通用句）**：本面的绿**只准**读成「**该页的具名色成片出现 ⇒ 该页内容至少部分真绘出**」这一件事 —— **不得**读成"两页真排版"、**不得**替代 `N1`／`N3`／`N4`。

## §5 收尾必交⑤：口径四条入册后的现取原文（`P1-realized-criteria-report.md` 的 `N4` 段，dated、只增不改）

现取落点：`### ⏪ t145 dated 追加 —— N4 正身份：四条被 t142 判死／受限的读数 ＋ 新立前置 PRECOND-KNOWN-GOOD-FRAME（只增不改）`（插在 `### 空态参照集：**重登记**…` 之前；件 `214 → 224` 行、`numstat 10 0`）。四条逐字要点：
1. **`ink` 禁用** —— 本席 `t145` 独立复算四帧**全 480000**（`dominant` 恒为黑 `830720`）⇒ 恒真量、零区分力 ⇒ 不得当身份／不得设阈值。
2. **行带数判死** —— 本席 `t145` 独立复算四帧**全 1** ⇒ 零区分力。
3. **`[GEO]` 不得当内容身份** —— 现取 `[GEO]` **927** 行；`nm=DocumentPage`／`nm=ContentControl`／`nm=Run` **各 0**；⚠️ **如实更正**：`t142` 那句"内容侧元素一个都没有"**本席复现不全**（`nm=TextBlock`／`nm=FlowDocument`／`nm=ScrollViewer` 各 **16**）⇒ 要结构化读数须新仪器 **`PRECOND-CONTENT-TREE-DUMP`**／**`PRECOND-CONTENT-DRAW-COUNTER`**。
4. **OCR 关门** —— `tesseract`／`ffmpeg`／`magick`／`gocr` 本席 `command -v` 现取**四个全 ABSENT**。
5. **新立 `PRECOND-KNOWN-GOOD-FRAME`** —— 全仓 `1280×1024` 的 PNG 现取**只有 8 枚**、全是**同一批 4 帧的两份拷贝** ⇒ 今天**无已知良好帧**；**写死：不许把「第一次恰好出现的帧」登记为「已知良好」**（任何正身份登记必须带独立可证伪支撑 ＝ `C-C` 的判据侧镜像）。

## §6 收尾必交⑥：本席主动点名的 `NOINFO` ＋ 边界

1. **覆盖面／`cell=#1`**：守卫件**在覆盖面内**（现取命中 **1**）⇒ 按第 `28` 条本应登记；派单硬约束**明令不碰** `HANDOFF-NEXT.md` 的 `cell=#1`（队长收口）⇒ **本件有意未登记**；指纹本席现取 ＝ `1e0096ba8185c22977451b57598e178886afefd9f5784edbff3ebea1c2eec93c`（成因含本席两件 ＋ 他者 `src/**` 在飞）。
2. **`t146`／后续同件写者注意**：本件交出**新基线 `PASS 80/0`**（不是 `66/0`、也不是 `72/0`）⇒ 务必自取当时值。
3. **未跑／未核（具名 `NOINFO`）**：① 未跑整趟门禁、未构建、未跑腿、未占显示位（派单禁）；② **未**在**真绘出内容**的帧上验本面**正极**（今天**不存在**这种帧 —— `PRECOND-KNOWN-GOOD-FRAME`；正极只在仓外夹具 `c51` 上跑到）⇒ 「该页真绘出时四色 ≥200」这句**今天无法在真树上验**（`NOINFO`）；③ **`k=23` 的色锚不存在**（内容侧无具名色）⇒ `NOINFO`，未用 k=24 推广；④ `[GEO]` 结构化读数的两条新仪器（`PRECOND-CONTENT-TREE-DUMP`／`PRECOND-CONTENT-DRAW-COUNTER`）**本件未实现**（不在写域）；⑤ 未复核 `t142` 除本件引到的读数以外的其它结论（我只复算了 §2.1／§2.3 的`ink`／行带／四色／`LightGray`／`[GEO]`／OCR 六项，其中 `[GEO]` 那条**发现一处与本席现取不符**并已如实更正）。
4. **残留检查**：突变体已同命令删除（零残留 ✓）；仓外 `~/w281-scribe/t145/**` 留档；**仓内** `git status` 只见 ` M build/MilBridge/tools/pts-pages-guard.sh`、` M build/MilBridge/P1-realized-criteria-report.md` 与 `?? build/MilBridge/P1-n4-gate-report.md`。
5. **本件未动**：`build/MilBridge/tests/PtsPagesProbe/**`（**未**动装置件 ⇒ 无需声明理由）；`src/**`、`.cs`、哨兵、`cell=#1`；相位位未翻。

**本件自证**：`head -n -1 build/MilBridge/P1-n4-gate-report.md | sha256sum | cut -c1-16` ＝ 722ddea75545f07b（末行不计入自身）
