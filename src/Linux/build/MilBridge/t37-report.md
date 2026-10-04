# `t37` 独立复验 —— `t36` 对 `t22` 四条 high 的关账

> **车道** `t37`（成员 `pts`）｜`attempt_id 263a11a5-a24f-4edf-af41-83e7e62c3e6e`
> **对象** `t36`（`waveman`）｜**立场**：我上一趟（`t22`）就是找出这些缺陷的人 ⇒ 本趟**只判"修得对不对、有没有把判据放松"**，形态**全部自造**（不跑它的 `--selftest` 当证据）。
> **纪律**：进程只按 PID；未 `pkill`／`pgrep -f`；未跑应用、未构建、未起显示；**未改任何被测件**；仓内唯一写入 = 本文件。
> **资源闸**（现取 `2026-09-28T02:02:18+08:00`）：`df avail_kb=91676448`｜`available_mb=5017`｜`swap_free_mb=1510`（均高于 512 MB／2000 MB）。
> 我的沙箱：`~/w302-pts/t37/`（夹具 ＋ 冻结副本 ＋ 证据目录 `ev/`）。

---

## 0. 判词

**`verdict = pass`** —— `t22` 的四条 high **逐条真的关掉了**（每条我都用**自造夹具**现跑出读数，见 §1），`X-CENSUS` 更正**落在对的位置且只增不改**（§2），报告三处更正到位（§3），`leg79c.sh` 零命中单行化（§4）。**判据没有被放松**（§5：收紧版仍归一化真路径、空域改 `NOINFO` 不再假绿、`LABEL` 恢复可达、无新豁免）。

**残余 findings（4 条，均为本趟我新发现／新判定，非四条 high 的复开）**：
- 🟠 **G1**：`diffclass.sh:18` 按 **basename** 命名证据件 ⇒ A／B **同名**时 `$ea == $eb`，B **覆盖** A ⇒ 两侧读同一份文件 ⇒ **对真实不同的输入静默判 `identical`**（我复现：`same=95 label=0 reading=0`）。**false-green 通道**（当前记录里的用法都是不同名，故未触发）。
- 🟡 **G2**：**等长但错位**的行集按位置配对、**不**打 `TRUNCATED_PAIRING` ⇒ 我造出 80 条**伪读数**（`same=15 reading=80`）。方向是**假红**（不是放宽），但判词不可归因且**静默**。
- 🟡 **G3**：`:34` 的字段名抽取只认 `· 自报口径 [A-Z_]+`（别的域名字为空）；`:39` 的读数明细只收**数值**值 ⇒ 字符串型读数差异会打出一个**空明细**的 `READING`（我复现 `src2=alpha↔beta`）。
- 🟡 **G5**：域② 的**全量真输入**不在车道录里（在 `~/w79-close/logs/`），也未在 `~/w79c` 记其路径／sha16（0 命中）⇒ 可复算成立、**「在车道录里」不成立**（依赖他目录存活）。

---

## 1. 四条 high —— **自造夹具逐条复跑**（`artifact + field + sha16` ＋ 读取时刻）

**被测件**：`~/w79c/bin/diffclass.sh` ＝ **`04f388daeeea00cc`**（50 行／3054 B／mtime `2026-09-28 01:58:46`，读取时刻 `02:02:18`）—— 与 `t36` 声称**逐位相同**。我的冻结副本 `~/w302-pts/t37/diffclass-v2-frozen.sh` 与之 `cmp` **IDENTICAL**。

**输入**（我自己取的**真日志**，不引用它的件）：`/home/links-dev/w79-close/logs/w79-post1-20260928-011239.log` ＝ **`581363df2e2c950e`**（240 行）／`…post2-20260928-012847.log` ＝ **`906e3ccc7c3b7cfa`**（240 行）。

| 腿 | 我的夹具（自造） | **我实跑的原始输出** | 判定 |
|---|---|---|---|
| **① `LABEL` 可达** | A 与「A 只改**一处 `outdir=`**」 | `LABEL   TLINE_GATE  标签/环境类（键级归一化后相等）` ＋ `COUNTS same=94 label=1 reading=0 paired=95` ＋ `VERDICT=label-only（读数类 0）`，**rc=0** | ✅ **关掉**（不再是「零差异」+ `exit 0`；**原始输出在**，点名字段 `TLINE_GATE`） |
| **② 空域 `NOINFO`** | 正则 `ZZZ_NO_SUCH_TOKEN`（两侧都零命中） | `NOINFO reason=domain-empty A_lines=0 B_lines=0 ⇒ **零命中不许当"零差异"**`，**rc=3** | ✅ **关掉**（零命中不再打印"零差异"；退出码 3 独立于 0/1） |
| **③ 白名单键上的**读数**不被吃** | A 行尾加 `file=97`、B 行尾加 `file=96`（**唯一差异**） | `READING DISK_HEADROOM   file=97↔96` ＋ `COUNTS same=94 label=0 reading=1` ＋ `VERDICT=reading-diff n=1`，**rc=1** | ✅ **关掉** |
| **③ 对照（防过窄）** | 同一位放**真路径** `file=/x/97` vs `file=/x/96` | `LABEL   DISK_HEADROOM` ＋ `label=1 reading=0`，**rc=0** | ✅ **正确**：收紧版仍归一化"白名单键 ∧ 值以 `/` 开头"的**真路径**（不是把该键一律关掉） |
| **④ 域② 真输入可复算** | 全量日志 ＋ 正则 `步骤通过\|结论：` | `EVIDENCE_A … sha16=933ce933ae8b8631 lines=2`／`EVIDENCE_B … lines=2` ＋ `COUNTS same=2 label=0 reading=0 paired=2` ＋ `VERDICT=identical`，rc=0 | ⚠️ **实质关掉**（**`lines 2/2` 逐字复现** `t21` 声称而我上趟复现不出的那个数）；**但输入不在车道录里** ⇒ 见 **G5** |
| **④ 交叉核对** | 我把 `t36` 落盘的域①抽证件与**我用同一命令现取**的结果比 | `~/w79c/evidence/t36/real/w79-post1-….domain.txt` ＝ **`c3856a2b759310ec`**（95 行）＝ 我现取的 `A.log.domain.txt` **同值** | ✅ 证据抽取**逐位可复算** |
| **头条数复核** | 真域① A vs B | `LABEL` ×5（`TLINE_GATE`／`COLUMN_FLOOR_SELFREPORT`／`THIRDPARTY_BUILD`／`THIRDPARTY_IMAGE`／`THIRDPARTY`）＋ `READING` ×5（`FRAMEPRESENCE`／`DISK_HEADROOM`／`R_GATE`／`NULBYTES`／`ALIAS`）＋ `COUNTS same=85 label=5 reading=5 paired=95`，rc=1 | ✅ **与 `t36` 的 `same=85 label=5 reading=5 paired=95` 逐字同值** |

> **判据有没有被放松**（本趟核心问句）：**没有**。空域从"假绿"变成 `NOINFO`+`rc=3`；`LABEL` 从"结构不可达"变成可达；归一化从"整键吞掉"收紧为"白名单键 ∧ 值以 `/` 开头"（我用**同一位置的两种值**做了成对对照，证明它精确到值形态，而不是靠关掉某个键）；`exit` 语义固定为 `0/1/3` 且与判词一致。

---

## 2. 四条 high 之 F4 —— **`X-CENSUS` 手写判词的两份文档更正**

| 检查项 | 我的现取 | 判定 |
|---|---|---|
| 两份文档各含 dated 更正 | `P0-w78-report.md`（**`bdf5644f4aa51300`**／439 行／mtime `01:59:08`）第 434–439 行 `### 【dated 更正 · 2026-09-28T01:59:07+08:00（t36）】…`；`HANDOFF-NEXT.md`（**`5df978b6cd4e3647`**／148 行／同 mtime）`:144–148` 同形 | ✅ |
| **原文仍在**（不是改写） | `pre-chain-baseline-absent` 命中数：P0 **2**（`:200` 原文 ＋ 更正节）／HANDOFF **2**（`:138` 原文 ＋ `:148` 更正节） | ✅ |
| **只增不改** | P0：`head -377 \| sha256sum` ＝ **`71b264bf4c827137`**（＝ `t25` 落仓态，逐位相同）⇒ 1–377 行**一字未动**，434–439 为纯追加；`git diff --numstat` ＝ **`62 0`**；`git diff -U0 \| grep -c '^-'` ＝ **0**。HANDOFF：`git diff --numstat` ＝ **`7 0`**、删除行 **0**；HEAD 版 141 行／`1a04bf8d78c4156e` → 现 148 行 | ✅ |
| 更正的四要件齐 | 更正节逐字含：① 与同两趟自引的 `X_CENSUS=PASS leaks=0 new_orphan_sock=0 base_live=0 now_live=1 base_socks=2 now_socks=3` **矛盾**；② reason **不在器具词表**；③ 处方「链首补快照」**早已实现**（`verify-all.sh:468-473`）；④ **真缺口 = 跨整条 `close-wave` 链无基线** | ✅ |
| **真缺口独立复算** | `grep -c snapshot build/close-wave.sh` ＝ **0**（`build/close-wave.sh` ＝ `04b12127a4297434`） | ✅ 现值与它给的一致 |
| **词表独立重算** | `build/MilBridge/tools/xvfb-census-check.sh`（**`b13485e94a9c93ba`**）里 `pre-chain-baseline-absent` 命中 **0**；该件实际产出的 7 个 reason ＝ `baseline-absent`／`baseline-format-unknown`／`orphan-socket-residue`／`ps-empty-or-unreadable`／`snapshot-unwritable`／`snapshot-with-ps-file`／`sock-dir-absent` —— 与它写的**逐字相同** | ✅ |
| 额外（超出要求，正面） | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:3428-3433` 登记 **`D-G168`**「判词必须来自器具的词表；手写 `reason=` 即假账」，并把三要件与真值一并写在册 | ✅ 未留第三处未更正的假判词面 |

---

## 3. 报告三处更正（P0 更正节 ①②③，逐条现取）

| # | 要求 | 现取 | 判定 |
|---|---|---|---|
| ① | `sha16` 现读**带时刻** | 逐字：「本文曾称 `948b1f495e6701e1`／34236 B／228 行 —— **现取**（2026-09-28T01:59:07+08:00）＝ **`7131ffad2ebac068`／64963 B／432 行**」 | ✅ |
| ② | §8 根因写明**已由 `TASK-0745`／`D-G166` 补上** | 逐字：「该缺口**已由 `TASK-0745`／`D-G166` 落地补上** —— `w27-freeze.py` 的 `_FORM_NINE` **含 `provider`**（逐键 vs 现取值对拍；`prev_*` 取**哨兵**而非九位行）」 | ✅（**本趟重取，不采信**）：`~/w21-verify/w27-freeze.py` ＝ **`89cd138a89909281`**；`:1215` 逐字 `'provider':    '`provider` `([0-9a-f]{16})`'`；`:1224 _TIER_KEY` 含 `'provider'`；`check_block_values` 命中 2 处；`:1207` 注释逐字「主控 2026-09-27 · `TASK-0745` 落地／`D-G166`」 |
| ③ | `+115` 改为 `[G147_WORKAREA]` 行（114 B + LF）＋ **单变量对只有 `baseold↔ret0`** | 逐字：「差恰是一行 `[G147_WORKAREA]`（**114 B，含 LF**）；且 `absent` 比 `baseold` **多 3 个 `wpf_x11_workarea_*` 符号**（553 vs 550）⇒ **单变量对只有 `baseold↔ret0`**」 | ✅（与我 `t22` 的逐字节读数一致） |

⚠️ **一处如实补充（G4，low）**：`t22` 的三条 finding 里有两条原本落在**车道侧**的 `~/w79c/report-additions.md`（§8 根因句在 `:10`、`+115` 括注在 `:22`）。该件**至今未改**（`b0a9349ff68ef735`／85 行／mtime `2026-09-27 12:17:31`，即 `t36` 未碰）⇒ **落仓面（P0 报告）已更正，车道记录面仍带旧文本**。建议加一行指针（不必重写）。

---

## 4. `leg79c.sh:70` 零命中单行化（**成对读数**）

- 现取定义（`~/w79c/bin/leg79c.sh` ＝ **`e98e173b8bbb4d45`**／92 行／mtime `01:59:08`，`:70` 逐字）：
  `g(){ grep -ac "$1" "$OUT/app.both" 2>/dev/null || true; }`
- 我**直接用文件里那一行**做夹具（`fx0/app.both` 零命中；`fx2/app.both` 两处命中）：

| 版本 | 零命中 | 两处命中 |
|---|---|---|
| **新（`|| true`）** | 解出 **1 行**，值 `0` | 1 行，值 `2` |
| **旧（`|| echo 0`，`t22` 记的形态）** | 解出 **2 行**，值 `0\n0` | 1 行，值 `2` |

- 端到端 `result.env` 形态对照：新 ⇒ `HC_UNHANDLED_N=2 ENTRYPOINT_NOTFOUND_N=0 STACKOVF=0` **一行**；旧 ⇒ 被撕裂成 `…_N=0` ／ `0 STACKOVF=0` **两行**（我 `t22` 报的正是这个形态）⇒ ✅ **关掉**。

---

## 5. 本趟新发现（findings）

**G1（🟠 medium-high，在 `diffclass.sh` 里，本趟新发现）** —— `:18` `ea="$OUTDIR/$(basename "$A").domain.txt"` 按 **basename** 命名 ⇒ **A／B 同名时 `$ea == $eb`**，第二次写覆盖第一次 ⇒ 两侧 `while` 读**同一份文件** ⇒ **对真实不同的输入判 `identical`**。我复现（`d1/post.log` ↔ `d2/post.log`，内容分别是 post1／post2 全量日志）：两行 `EVIDENCE_*` 打印**同一路径**、**同一 sha16 `c843a82e55052531`**，判词 `COUNTS same=95 label=0 reading=0 paired=95` ＋ `VERDICT=identical` —— **input 明明不同**。这是**假绿通道**（方向最危险）。当前记录里的用法（`w79-post1-…` vs `w79-post2-…`、`lab-a`／`lab-b`、`num-a`／`num-b`）都不同名 ⇒ **未触发**，故我判 `pass`，但该通道必须关。**修法**：证据名用**绝对路径的 sha16**（或 `mktemp`）＋ 加一条断言 `[ "$ea" != "$eb" ] || { echo 'NOINFO reason=evidence-path-collision'; exit 3; }`。

**G2（🟡 low-medium）** —— **等长但错位**的行集走位置配对且**静默**：我造「域内第 3 行插一行 ＋ 删掉域内最后一行」（**域行数 95 vs 95**）⇒ 无 `TRUNCATED_PAIRING`，输出 `COUNTS same=15 label=0 reading=80`。方向是**假红**（非放宽），但 80 条读数**不可归因**且没有任何提示。**修法**：配对前先比**行集多重集**（`LC_ALL=C sort` 后 `cmp`），不等 ⇒ `ALIGNMENT=unverified`／`reason=line-set-not-aligned`；或按行键（`自报口径 <NAME>=`）配对。

**G3（🟡 low）** —— `:34` 字段名抽取只认 `· 自报口径 [A-Z_]+` ⇒ 别的域（如 `步骤通过`）的 `LABEL`／`READING` 行**名字为空**；`:39` 的读数明细只收 `[A-Za-z_]+=[0-9.]+` ⇒ **字符串型**读数差异打出**空明细**（我复现：唯一差异 `src2=alpha↔beta` ⇒ `READING DISK_HEADROOM  `，判词与 `rc=1` 正确、明细为空）。

**G5（🟡 low-medium）** —— 域② 的**全量真输入**在 `/home/links-dev/w79-close/logs/`（**他目录**），`~/w79c` 里**既无副本也无其路径／sha16**（我 grep 其 sha16 `581363df2e2c950e`／`906e3ccc7c3b7cfa` ⇒ **0 命中**；`~/w79c/evidence/t36/real/` 只落**域①抽证件**）⇒「可复算」成立（我已复算），但 **「在车道录里」不成立**，且该目录是回收候选。**修法**：把那两份全量日志（或至少其**路径＋sha16**一行）记进车道录。

**G4（🟡 low）** —— 车道侧 `~/w79c/report-additions.md` 未随更正（见 §3 末尾）。

---

## 6. 上趟 `NOINFO` 的收口（**两条必须变可判**，逐条）

| 上趟 `NOINFO` | 本趟结论 |
|---|---|
| **域② 的「零差异」（真输入未交付）** | ✅ **变可判且成立**：全量日志 ＋ `步骤通过\|结论：` ⇒ `lines 2/2`、`same=2`、`VERDICT=identical`、rc=0（正是 `t21` 声称而我上趟复现不出的那个数）。**残余**：输入未落车道录（**G5**）。 |
| **`pool-exhausted` 的池外误用** | ✅ **变可判，且判定＝不存在该缺陷**（它**没动**该件，我依纪律**不静默**、给出静态证据）：`build/MilBridge/tools/display-lease.sh` ＝ **`b12fc3c0fd3d352f`**（550 行／mtime `2026-09-26 22:56:10` ⇒ **早于 `t36` 会话**；`git status` 对该件**空**）⇒ `t36` 未改它。**静态读**：`acquire` 分支 `:378-383` 先 `pool_member "$WANT_DISP" || noinfo "pool-out-of-whitelist" …`（`:381`），**通过之后**才进候选；池耗尽分支在 `:446`／`:448` ⇒ **白名单闸先于耗尽闸** ⇒ 两个 reason **按构造互斥**，`pool-exhausted` **不可能**在池外场景产出 ⇒ 我上趟引述的"应改名为 `pool-out-of-whitelist`"**不成立**（那是 `t21` 的措辞，我上趟已标"部分不成立"），**该件无需改动** ⇒ `t36` 不动它是**正确处置**。 |

---

## 7. 落仓面自证

- 仓内唯一写入件 = 本文件 `build/MilBridge/t37-report.md`；被测件（`~/w79c/**`、`build/MilBridge/P0-w78-report.md`、`build/MilBridge/HANDOFF-NEXT.md`、`build/MilBridge/tools/display-lease.sh`、`build/close-wave.sh` 等）**一字未动**。
- 分类器与装置**只读**：我跑的是 `~/w302-pts/t37/diffclass-v2-frozen.sh`（`cmp IDENTICAL`），证据输出一律指到**我自己的** `~/w302-pts/t37/ev/`（第 4 位置实参），未写 `~/w79c/evidence/`。
- 未跑应用／未构建／未起显示；两条真日志与 `~/w79c` 侧件全程只读。
