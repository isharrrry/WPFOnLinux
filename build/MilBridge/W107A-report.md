# W107A 报告 —— 收口 `TASK-0703`／`TASK-0704` ＋ 更正一处错误归因 ＋ 新登记 `D-G96` ＋ 全域重盘 ＋ 第五笔文档推送

车道 `W107A`｜`2026-09-22 19:40 → 19:52 (+0800)`｜**纯文本编辑 ＋ 一次推送**（**零 `dotnet`／零构建／零门禁／零应用／不占重活槽**；只跑只读核对器 `defect-registry-check.sh`）
仓 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`｜fork 克隆 `~/netTest/GitProj/WPFOnLinux`
冻结基线 `#50 1f4189c1257737a9`（本件**未动** `ACCEPTANCE-BASELINE.md`，其锚 `AB=1f4189c1257737a9` 逐字未变）
**判据先写**：`~/w107a/criteria.md` `d06b1e48ec062ca1` —— **写它的时刻（19:40:20）早于本车道对 `$R`／`~/w63a/REPORT.md` 的任何一次编辑**（首次编辑 = `REPORT.md`，`19:44`）

---

## §0 结论速览（先看这里）

1. **归因更正已落地**：`~/w63a/REPORT.md` 在 `:279` 之后**追加** dated 更正块（**原文 `:278-279` 一字未动**），件 `c837e102c8ada0f1 → 4d3746698860e12b`；把"WM 没起来"的原因从"`xfwm4` **调用形式**写错"更正为"**`bin/wm-leg.sh:19` 的恒真谓词用在 `if !` 上 ⇒ 起 WM 的分支从未执行**"。
2. **新登记 `D-G96`（装置缺陷 · 证据保全）**已落地（册 `:2529` 起）：`~/w63a/bin/wm-leg.sh:13` ＝ `: > "$PROG"`（**截断**）⇒ **任何一次重跑都会抹掉 `D-G95` 引用的唯一证据行**。
3. **`D-G95` 的 `NOINFO` 已收口 = 0 条受影响**（依据 W103A §4 的 12 条逐条复核 ＋ 册内交叉引用现场核）；**仍保留**两条 `NOINFO`。
4. **全域重盘（本件的机器牙）结果**：`P-A` 命中 **20**（**可执行 7**／注释 13）｜`P-B` **82**（可执行 61／注释 21）｜`P-C` **0**。
   ⇒ 🔴 **7 处可执行命中里有 1 处是"活的"、且是本次新发现**：`~/w63a/bin/wm-leg198.sh:17` 的 `case "$wm" in *window*)`（**glob 形态**，前两条盘点的 `grep -q window` 口径**机械上看不见**）。
5. **`TASK-0704 → ✅`**（判据三条全满足：四处 sha16 **现场重算与 W103A 报告逐字相同** ＋ 两极化有读数 ＋ 复核有结论）；**`TASK-0703 → 🟡`（不是 ✅）** —— 先写判据第 1 条"`P-A` 可执行命中必须 = 0"**未满足**，且原因是**真命中**。
6. **`DEFREG=PASS declared=132 route_ids=132`、`DEFREG_DECLDRIFT=0`、`rc=0`**（连跑两遍逐字相同）；声明表**只 ＋1 行 ID（`D-G96`），0 删 0 改**。
7. **第五笔推送成功**：`080af718a1c22597947ac7d9fcad2d449a3baebe → 5d14a9c43f5f76fc9733ba7b602c91cdba8d681b`（`local == remote`、`--symref` 仍 `feat-Linux`）；见 §8 的 `BYTECHECK`。
8. ⚠️ **两处自伤（如实留档）**：① 全域重盘 v1 的**仪器**有两处缺陷（正则误命中 `window id #`；`P-C` 判据实现与口径无关）⇒ 已修仪器**未放宽判据**（§5.2）；② `ROUTES.md` 第一次改状态位时我的 `edit` 把下一行**吞掉了** ⇒ 已从 **HEAD blob 逐字节复原**（`sha16` 复核 = 改前值）后改用行锚定改法（§7.3）；③ 册初稿写了"尚不存在的编号"的字面量 ⇒ `--emit` **多出一行幻影声明**，已改写并重生成（§6.4）。

---

## §1 判据（**先写**于 `~/w107a/criteria.md` `d06b1e48ec062ca1`；此处摘要，逐字见该件）

| # | 判据 | 关键点 |
|---|---|---|
| 1 | **结论三样齐** | artifact ＋ field ＋ **现算 sha16**（不许手抄） |
| 2 | **两极化** | 说"收口"必须给成对读数；给不出 ⇒ `NOINFO`（既不算绿也不算红） |
| 3 | **不许放宽** | 判据写死后改动只能**追加** dated 更正 |
| 4 | **加注不覆盖** | 改任何人（含自己）已落盘的文本 ⇒ 只追加，原文**一字不动** |
| 5 | **引文核对** | 必须 `grep -Fxq -e "$line" -- "$file"`（W104A 踩过 `-` 开头行的假 MISS） |
| 6 | **写域** | 册／地图／声明表／本报告／转推 2 件 ＋ 仓外**只** `~/w63a/REPORT.md` |
| 7 | **归因更正判据** | `N1`（`wm-leg.sh:19-22` 原文）∧ `N2`（`xfwm197.log` mtime 停 `00:24`）∧ `N3`（块级复现）**三条全要** |
| 8 | **`D-G96` 立号判据** | `A1`（`:13` 是 `: > "$PROG"`）∧ `A2`（`D-G95` 引用的证据行在同文件）⇒ **反极性** = 证据件 mtime 若不晚于脚本 mtime 则**证伪** |
| 9 | **重盘口径** | 扫哪些扩展名／排除哪些目录**先写死**；**注释命中与可执行命中分开计**；硬条 = `P-A` 可执行 **0** ∧ `P-C` **0** |
| 10 | **`TASK-0703` 判定规则** | 上述硬条满足 ⇒ ✅；**不满足 ⇒ 🟡 并逐处点名**（**先写，后按读数执行**） |
| 11 | **推送** | 逐径 `git add`；`nobody` 定义写死；`mismatch` 必须 0 |

---

## §2 更正 `~/w63a/REPORT.md` 的错误归因（**第 1 条**）

### 2.1 目标原文（**改前逐字，原文一字未动**）

```
:278  > 配方：`env DISPLAY=:198 xfwm4 --display=:198 --compositor=off`（我第一版写成
:279  > `DISPLAY=x xfwm4 --replace`，**WM 没起来**，`W101` 因此是无 WM 的一趟，已在表里标明）。
```

### 2.2 追加的更正块（**逐字，落在 `:279` 之后**）

> ⚠️ **归因更正（车道 W107A，2026-09-22；结论不动、原文一字未动，只更正"原因"）**
> 上面那句"**WM 没起来**"的**原因**不是"`xfwm4` 调用形式写错了"，而是 **`bin/wm-leg.sh:19` 的谓词恒真、又被用在 `if !` 上 ⇒ 那个"起 WM"的分支从未执行**（编号 `D-G95`；`#50` 冻后已登记在 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`）。
> - **原文保留**：上方 `:278-279` **一字未动**（本更正只**追加**，不覆盖）；`W101` = 无 WM 一趟这个**结论本来就是对的**（本报告自己在表里标明了）。
> - **依据（三件，全部现场核过）**：
>   ① `~/w63a/bin/wm-leg.sh:19-22` 修前原文 = `if ! DISPLAY=$D xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q window; then` ＋ 起 `xfwm4` ＋ `sleep 3` ＋ `fi`（`#50` 冻后该原文由车道 W103A 逐字留在 `:19-23` 的注释块里，可逐字核）；
>   ② **11:35 那一趟根本没执行过那次调用**：`~/w63a/logs/xfwm197.log` 的 mtime 逐字 `2026-09-21 00:24:03.084538636`（`>` 重定向**没有发生** ⇒ 没有产生新日志），而同一趟的进度行 `~/w63a/logs/wm.progress:1` 时刻是 `11:35:25` ⇒ 两者相差 11 小时；
>   ③ **块级复现**（车道 W102A，`~/w102a/logs/w63a-form-demo.txt` 逐字）：把同一段文本放到一块**无 WM** 的私有屏上跑 ⇒ `W63A_FORM: **没进 if 体**`，而同刻的**真判据**形态给出 `TRUE_CRITERIA_FORM: 进了 if 体`（正确：确实没 WM）。
> - **为什么这条更正不只是"文字洁癖"**：**照错的归因去修，会去改 `xfwm4` 的调用形式**（本报告上方那句"配方"改成的正是 `env DISPLAY=:198 xfwm4 --display=:198 --compositor=off`），**而那个恒真谓词仍然留在原位 ⇒ 分支仍然不可达 ⇒ 下一次"WM 腿"仍然静默跑在无 WM 上**。`D-G95` 的要害正是"**静默跑错腿**"：调用失败**会报错**，分支不可达**什么都不报**，输出看起来完全正常。
> - ⚠️ **不许读宽（边界，如实划）**：本更正**只**证两件事 —— "那个分支不可达" ＋ "11:35 那趟没执行过该调用"。**"00:24 那一版（`~/w63a/xfwm197.pid` mtime `00:24:02`）的谓词是不是本来就对"仍未读到原文 ⇒ 那一格仍是 `NOINFO`**（车道 W103A §4.3-2 同判；本行不把它升格成读数）。

### 2.3 before / after 与成对读数

| 项 | 值 |
|---|---|
| `~/w63a/REPORT.md` | `c837e102c8ada0f1` → **`4d3746698860e12b`**（465 → 475 行） |
| **正极性** | `:278-279` 原文在**改后**文件里 `grep -Fxq -e` **仍命中**（`OK`）⇒ 没被覆盖 |
| **反极性** | `grep -c '我第一版写成'` **改前 = 1、改后 = 1**（不是 0 ⇒ 不是"删了重写"）；`sha16` 已变（⇒ 真的落盘） |
| **写域纪律** | `find ~/w63a -newermt '2026-09-22 19:35' -type f` ⇒ **只列出 `REPORT.md`**（`logs/**`、`bin/**` 一个字节未写） |
| **证据存活** | `logs/wm.progress` mtime 仍 `2026-09-21 11:37:08.087448586`｜`logs/xfwm197.log` 仍 `00:24:03.084538636`｜`logs/xfwm198.log` 仍 `11:37:44.003582440` ⇒ **未被毁**（这正是 `D-G96` 要求的操作顺序） |

---

## §3 新登记 `D-G96`（**第 2 条**）

**编号现场核**：`grep -o 'D-G[0-9]\+' … | sort -u -V | tail -1` ⇒ 末号 = **`D-G95`**（与任务书一致）；改前 `grep -c 'D-G96'` = **0** ⇒ 新号 = **`D-G96`**。

### 3.1 册里新增的完整条目（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2529` 起）

### `D-G96`（**装置缺陷 · 证据保全**）：`wm-leg.sh` **每次运行都截断自己的进度日志** ⇒ **为复核而重跑，就把要复核的证据毁了**
- 现象（车道 W107A，2026-09-22；来源 = 车道 W103A 报告 `build/MilBridge/W103A-report.md` `d92f0ede166268a7` §5.3 的建议 ＋ 本车道现场核）：`~/w63a/bin/wm-leg.sh:13` **逐字** = `: > "$PROG"`，而 `:11` = `PROG="$HOME/w63a/logs/wm.progress"` ⇒ **脚本一启动就把该日志清零**。
- 判定点：`~/w63a/bin/wm-leg.sh:13`（**仓外**装置；仓内不存在此件）＋ 同类第二处 `~/w63a/bin/wm-leg198.sh:12`（`PROG="$HOME/w63a/logs/wm198.progress"`，`:10`）。
- **承重关系（为什么这是一条缺陷而不是"卫生问题"）**：`D-G95` 引用的**唯一现场证据行**就是 `~/w63a/logs/wm.progress:1` 那一行（`2026-09-21 11:35:25 DISPLAY=:197 wm=_NET_SUPPORTING_WM_CHECK:  no such atom on any window. geom=1024x768`）—— 它与 `:13` 指向**同一个文件** ⇒ **任何一次"修好后重跑一遍"都会当场抹掉该证据**。
- **性质（与同族三条判词不同，这是本条的要害）**：**既不是假红也不是假绿**，而是"**证据保全**"缺陷 —— 坏法是"**你为了复核去重跑，就把要复核的证据毁了**" ⇒ 复核这类腿的**正确顺序 = 先 `cp -p` 冻结日志，再做任何重跑**（这条已在现场被执行：`D-G95` 的证据行 mtime 至今仍是 `2026-09-21 11:37:08.087448586`，本车道**一个字节都没写它**）。
- **机械支持（成对）**：

| 读数 | 值 | 说明 |
|---|---|---|
| `wm-leg.sh:13` 功能 | `: > "$PROG"`（**截断**，非追加） | 与 `:12` 的 `say()` 用 `tee -a`（**追加**）**口径相反** ⇒ 同一脚本内两套写法 |
| `~/.mtime` 关系 | `wm.progress` mtime `2026-09-21 11:37:08` **晚于** 改前 `wm-leg.sh` mtime `11:35:22` 3 s | 正是"跑过一次、只剩这一行"的形态（该行由**当前那版**产生） |
| 同类件 | `wm-leg198.sh:12` 同款 `: > "$PROG"` | 它**已经**这么截断过一次 `wm198.progress`（`D-G95` 收口条款要引 `wm198.progress:1`，故该风险同样存在） |

- **反极性（本条怎样被证伪）**：若 `wm.progress` 的 mtime **不晚于** `wm-leg.sh` 的 mtime，则"重跑会截断"当场证伪。现场读数如上 ⇒ **成立**。
- **与既有号的关系（同族但判词不同，不许合并）**：同族 = `D-G93`（假死锁：装置按关键词**认错对象**）／`D-G94`（分母口径：装置把自己的**命中**从分母剔掉）／`D-G95`（反向恒假：装置**静默跑错腿**）—— 那三条坏的是"**判据/口径**"；本条坏的是"**证据的存活**"（判据本身没错，错的是它**活不过一次重跑**）⇒ **另立新号 ＋ 交叉引用**。
- 处置：**只登记，未修**（车道 W107A 的写域**不含** `~/w63a/bin/**`；且 `wm-leg.sh` 已由车道 W103A 修好 `D-G89` 那一处 —— `aec91a0827bd9cfa` —— 但 **`:13` 这一行 W103A 未改**，现场核仍在 ⇒ 本缺陷**仍然活着**）。
- 建议修法（**未落**，供 `TASK-0704` 的收尾或另立任务裁定）：`PROG` 改为**带时间戳归档**（`wm.progress.$(date +%Y%m%dT%H%M%S)`）或改为**只追加**；并在任何"为了复核而重跑装置"的纪律里**先写死**"**重跑前 `cp -p` 冻结日志**"这一步（本条的机读判据 = 重跑前后两件日志的 sha16 **都有留档**）。
- 边界 / `NOINFO`：① 该装置在**仓外** ⇒ 仓内补不出牙（同 `D-G93`／`D-G95` 的边界）；② **"全仓/全 `$HOME` 还有几处装置会截断自己引用的证据"未逐处枚举**（本车道只机械核了 `: > "$PROG"` 这一形态在 `~/w63a/bin/` 下的两处）⇒ `NOINFO`；③ 本条**不改**任何既有编号的值与判词，**未**把任何红写成绿。

### 3.2 立号判据的三条现场核（判据 §8）

```
A1  ~/w63a/bin/wm-leg.sh:13  =>  : > "$PROG"                      （逐字核）
A2  D-G95 引用的证据行 = logs/wm.progress:1，与 :13 的 $PROG 同文件 （逐字核）
A3  反极性：wm.progress mtime 11:37:08 > wm-leg.sh mtime 11:35:22  ⇒ 判据成立（未被证伪）
A4  :13 现状（W103A 修后）= 仍是 `: > "$PROG"`                      ⇒ 缺陷仍活着
```

---

## §4 `D-G95` 的 `NOINFO` 收口（**第 3 条**）

### 4.1 收口 bullet（**逐字，追加在 `D-G95` 条内**，册 `:2520`）

> - ✅ **`NOINFO` 收口（车道 W107A，2026-09-22；只追加，上文一字未动）**：上一条处置里点名要做的"**复核它那趟'WM 腿'的判词是否已影响任何已登记结论**"**已做完 = 0 条受影响**，依据（复核在车道 **W103A 报告 `build/MilBridge/W103A-report.md` `d92f0ede166268a7` §4**，**12 条逐条**给了判定与依据）：
>   - `R1` **逐条 12/12**：§4.2 表 12 行，判定分布 = **"不受影响" 11 条 ＋ "结论正确但机制归因错" 1 条**（那 1 条 = `~/w63a/REPORT.md:279`，**已由本车道追加更正块**）⇒ **"受影响" 0 条** ⇒ 按本条处置的措辞，**不需要**"按无 WM 口径重取"、**不需要**降级 `NOINFO`。
>   - `R2` **那条腿的结论本来就标了"无 WM"**：`~/w63a/REPORT.md:279` 逐字自报"**WM 没起来**，`W101` 因此是无 WM 的一趟，**已在表里标明**"，且 `:309-311` §4.1 频率表把 `W101` 记在"**无 WM**"那一格、把 `W301-303` 记在"**有 WM**"那一格 ⇒ **没有把污染腿当 WM 腿算**。
>   - `R3` **WM 结论的来源不是被污染的 `:197`**：`W301/302/303` 取自 **`:198`**；现场核 `~/w63a/logs/xfwm198.log` **存在、非空、169 B** 且逐字含 `(xfwm4:231209): xfwm4-WARNING **: 11:37:44.004: Failed to connect to session manager…` ⇒ **真有 xfwm4 进程起来过**。
>   - `R4` **册内交叉引用干净**：`D-G64`／`D-G66`／`D-G69` 三条条目正文里**零 `W63A` 引用**（大写口径 `grep -c 'W63A'` 全册 = **2**，分别在 `D-G87` 条与本条内）。
>   - ⚠️ **仍然保留的 `NOINFO`（本收口**不**清掉它们）**：① **`:198` 当时未取 `C2`/`C4`**（只有 `C1` ＋ 启动日志）⇒ 按本册 `D-G89` 的"三条件全要"口径，"那一刻 WM 一直活着并接管客户窗"仍记 `NOINFO`；② **"00:24 那一版脚本的谓词是否本来就对"仍未读到原文** ⇒ 不当结论。
>   - 🆕 **收口时的追加发现（车道 W107A 全域重盘）**：`:198` 那趟**自身的"前提守卫"也是恒真的**（`~/w63a/bin/wm-leg198.sh:17` 的 `case "$wm" in *window*)`，是**另一种形态**）⇒ 它**不能**被当作"当时确认过有 WM"的证据；**"当时有 WM"这句话的证据强度仍然只有 `C1` ＋ 启动日志**（= 上面 `NOINFO` ①，**未变**）。

### 4.2 三条收口判据的现场核（判据 §4）

| 判据 | 现场读数 | 判定 |
|---|---|---|
| `R1` 12 条逐条 | `grep -c` W103A 报告 §4.2 表行 = **12**；汇总行逐字"**12 条里 0 条"受影响"**" | 通过 |
| `R2` 自报无 WM | `REPORT.md:279` 逐字含"**WM 没起来**"＋"**已在表里标明**" | 通过 |
| `R3` 来源是 `:198` | `logs/xfwm198.log` 存在、`169 B`、含 `xfwm4-WARNING … 11:37:44.004`；`wm198.progress:1` 含 `window id # 0x2000ae` | 通过 |
| `R4` 交叉引用 | `D-G64`（`@2204`）／`D-G66`（`@2218`）／`D-G69`（`@2235`）正文 0 处 `W63A` | 通过 |

⚠️ **不许读宽**：本收口**只**说"**没有任何已登记结论受这处缺陷污染**"；它**不**说"`:198` 那趟当时确实有 WM"（那一条仍是 `NOINFO`，理由见上）。

---

## §5 全域重盘（**第 4 条** · 本件的机器牙）

### 5.1 口径（**先写**于判据 §5）与可复算命令

```bash
# 仪器（本车道私有）：~/w107a/resurvey.sh（v1，含两处仪器缺陷 ⇒ 留档）
#                      ~/w107a/resurvey2.sh（v2，修正后 = 本次采用）
bash ~/w107a/resurvey2.sh > ~/w107a/resurvey.txt 2>&1          # 原始输出留档
```
- **根**：`$R`（仓内）＋ `$HOME`（仓外脚本域）；**排除 fork 克隆**（= `$R` 的第二份副本，不排除会双算）。
- **扩展名**：`*.sh` `*.bash` `*.py` `*.pl`。
- **排除目录**（逐条点名）：`/logs/`、`/arm-logs/`、`/upstream/`、`/.git/`、`/node_modules/`、`/bin/Debug/`、`/bin/Release/`、`/obj/`、`/gen/`、`/.venv/`、`/site-packages/`、`/.cache/`、`/.local/`、`/.npm/`、`/.dotnet/`、`$HOME/w103a/legs/home_*`（沙箱 `HOME` 副本）。
- **三个模式**：`P-A` = 恒真谓词本体字面形态（**裸 `window`** 作匹配词，**不含** `window id #`；含 `case/[[ ]]` 的 `*window*` glob 形态）｜`P-B` = 受查对象 `_NET_SUPPORTING_WM_CHECK`｜`P-C` = **反向恒假**（`P-A` 形态与 `P-B` **同处一个 `if !` 分支**）。
- **分类规则**：去空白后行首为 `#` ⇒ **注释命中**；否则 ⇒ **可执行命中**（**分开统计**）。

### 5.2 计数（**可执行／注释分开**）

```
HOST_FILES = 2215        （仓内 152 ＋ 仓外 2063；已排除 fork 克隆）
P_A_TOTAL = 20   P_A_EXEC = 7    P_A_COMMENT = 13
P_B_TOTAL = 82   P_B_EXEC = 61   P_B_COMMENT = 21
P_C_TOTAL = 0
⇒ 判据 §5 硬条：P_A_EXEC 必须 0（**不满足**）；P_C 必须 0（**满足**）
RESURVEY=SURVEY_HITS_PRESENT
```

### 5.3 🔴 `P-A` 可执行 7 处的逐处归类（**这是本节的核心**）

| # | 命中（`文件:行`） | 归类 | 说明 |
|---|---|---|---|
| 1 | **`~/w63a/bin/wm-leg198.sh:17`** | **LIVE（活装置）** | `case "$wm" in *window*) : ;; *) say "NOINFO wm-absent…"; exit 9 ;; esac` ⇒ **恒真守卫**（详见 5.4）—— ⚠️ **本次新发现** |
| 2 | `$R/build/MilBridge/tools/wm-awaited.sh:316` | FIXTURE（负控） | 该工具 `--selftest` 的 **S2 负例 fixture**：**故意**在失败文案上跑旧谓词并断言 `rc=0`（列 `AS-EXPECTED`） |
| 3-5 | `~/w102a/old-predicate.sh:17`／`:21`／`:27` | FIXTURE（负控） | 车道 W102A 的**只读旧谓词读数器**（`D-G89` 的成对负控本体：裸／`pipefail`／计时循环三种口径） |
| 6 | `~/w103a/legs.sh:114` | FIXTURE（负控） | 车道 W103A baseline 腿的**负控读数行**（打印 `grep -q window rc=$?  <== 0 即'恒真'`） |
| 7 | `~/w107a/resurvey.sh:63` | SELF（自指） | **本重盘仪器自己的模式文本**（v1 留档件） |

**注释命中 13 处 = 全部是"加注不覆盖"留档**：`~/w53a/cell.sh:27`｜`cell2.sh:27`｜`cell3.sh:27`｜`~/w76a/bin/ab.sh:27`｜`~/w63a/bin/wm-leg.sh:20`｜`$R/build/MilBridge/tools/wm-awaited.sh:17`｜`~/w93a/run-w93a-legs.sh:60-61`｜`~/w93a/x-wm-test.sh:35`｜`~/w101a/run-w101a-legs.sh:62-63`｜`~/w102a/old-predicate.sh:16`｜`~/w107a/resurvey2.sh:51`。

**仓内（`$R`）结论**：可执行代码里"**活的**恒真 WM 判据" = **0 处**（仓内唯一 `P-A` 可执行命中是 `wm-awaited.sh:316` 的**负例 fixture**）—— 与 W102A §8 的"**仓内 0 处**"**一致**。

### 5.4 🔴 新发现：`~/w63a/bin/wm-leg198.sh:17` —— 同族**第三种形态**（glob），前面两条盘点**机械上看不见**

```
:15  wm="$(DISPLAY=$D xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | head -1)"
:17  case "$wm" in *window*) : ;; *) say "NOINFO wm-absent（WM 腿的前提不成立）"; exit 9 ;; esac
```
- **机制**：**无 WM 时**该 `xprop` 往 **stdout** 打的是**失败文案** `_NET_SUPPORTING_WM_CHECK:  no such atom on any window. `（`rc=0`，`D-G89` 现场已钉），里面的 `window` 被 **glob `*window*`** 命中 ⇒ 走 `:`（**什么都不做**）⇒ **"前提不成立"这条守卫永远不触发 = 恒真**。
- **形态核对（现场，喂入已留档的真实失败文案；不跑任何装置）**：

```
输入: [_NET_SUPPORTING_WM_CHECK:  no such atom on any window. ]
旧形态 case "$wm" in *window*)         => **命中** ⇒ 守卫不触发 ⇒ 恒真
真判据 case "$wm" in *"window id #"*)  => **未命中** ⇒ 正确判"WM 不在场"   ← 正对照
```
- ⚠️ **为什么前两条盘点看不见它**：W102A／W103A 的盘点口径是 `grep -q window`（**按 `grep` 认对象**）⇒ 对 `case` **glob** 形态**机械上不可见** ⇒ 与 `D-G84`（判据射程错）／`D-G93`（按关键词认对象）**同族**。
- ⇒ **数字更正**：W102A 记的"**仓外 5 处**"（`cell3.sh` 已修 ＋ 余 4 处）在**另算形态**后应为 **6 处**（**口径不同，引用者请指名**）。
- **后果（不夸大）**：`:198` 那趟的"前提守卫"也是恒真的 ⇒ 它**不能**被当作"当时确认过有 WM"；但**它的结论仍然成立**（`wm198.progress:1` 有 `window id # 0x2000ae`（C1）＋ `xfwm198.log` 有真实启动行）⇒ 证据强度**仍只有 C1 ＋ 启动日志**（= 既有 `NOINFO` ①，**未变**）。
- **处置**：**只报不动** —— 它在 `~/w63a/bin/**`，**不在本车道写域**。修法（**未落**）= 把 `*window*` 换成 `*"window id #"*`，或直接改调用 `wm-awaited.sh`（**建议并入 `TASK-0704` 收尾或另立一条**）。
- ⚠️ **未为它新增编号**（本车道只被授权新增 `D-G96`）⇒ **若主控判它该独立成号（下一个空闲号），拆号是单点改动**。

### 5.5 仪器自伤（**v1 → v2，如实留档**）

| # | v1 的仪器缺陷 | 后果 | 处置 |
|---|---|---|---|
| 1 | `P-A` 正则写成 `(['\"])?window(['\"])?([^a-zA-Z0-9_]\|$)` ⇒ **会误命中 `window id #`**（真判据形态） | 报出 **13 处假阳**（含 `w101a:66`／`w93a:64`／`w102a:80` 等**真判据**） | v2 加 `grep -vE "window(['\"])? +id"` ⇒ 假阳消失 |
| 2 | `P-C` 实现成"**任意** `if !` ＋ **任意** `grep -q`"，**与 `P-B` 无关** | 报出 **261 处**（口径外，含 `verify-all.sh` 的 `if ! grep -qE "error …"` 之类） | v2 要求同分支**同时**含 `P-B` 与 `grep -q`；经 6a 步再收紧"**必须是 `P-A` 形态**（裸 `window`）"⇒ **0** |

⚠️ **纪律声明**：v1 的两处是**仪器缺陷**（实现与已写口径不符），修的是**仪器**，**判据本身一个字没改**（`criteria.md` 未动，`sha16` `d06b1e48ec062ca1`）；v1 的原始输出**保留**在 `~/w107a/resurvey-v1-overshoot.txt`（465 行）供复核。

---

## §6 `TASK-0703`／`TASK-0704` 的最终状态与依据（**第 5 条**）

### 6.1 `TASK-0704 → ✅`（依据三条，全部现场核）

| 判据 | 现场读数 | 通过？ |
|---|---|---|
| 四处 after sha16 **与 W103A 报告逐字相同**（本车道**现算**） | `~/w53a/cell.sh` **`e1301e3b274d6dec`**｜`~/w53a/cell2.sh` **`208a674183825d23`**｜`~/w76a/bin/ab.sh` **`3ce92b2d8806e3d7`**｜`~/w63a/bin/wm-leg.sh` **`aec91a0827bd9cfa`** —— 与 W103A §0 表**四值逐字相同**；四处 `perm=711`；可执行代码里旧谓词命中 **4 件全 0** | ✔ |
| 两极化有读数 | 修前 `rc=0`＋`0.01/0.02/0.03/0.02 s`（第一次迭代即 `break`）vs 修后 `rc=6`＋用满 `10.05/10.17/10.32 s`＋`WM_AWAITED=FAIL`；真代码自己起 WM 后 `rc=0`＋`2.7–2.8 s`＋`WM_AWAITED=PASS`（＋独立证据：`id=0x2000ae`／`_NET_SUPPORTED n=78`／重定父 `c4=yes`） | ✔ |
| 被污染臂复核有结论 | **12/12 逐条、0 条受影响**（§4） | ✔ |

⇒ `docs/ROUTES.md:381` 状态位 `🔴 → ✅`（**只改状态字符，判词一字未动**），并在该行下追加收口 bullet（读数 ＋ 件 sha16 ＋ 三条判据 ＋ **不覆盖的尾巴**：`wm-leg198.sh:17` 仍在／`wm-leg.sh:13` 未修／四处未端到端跑）。

### 6.2 `TASK-0703 → 🟡`（**不是 ✅**），依据 = 先写判据第 1 条未满足

- **先写的判定规则（判据 §5，写在跑重盘之前）**："若 `P-A` 可执行命中 = 0 ∧ `P-C` = 0 ∧ `P-B` 每一处都是真判据 ⇒ **✅**；**否则** ⇒ **🟡** 并**逐处点名**"。
- **现场读数**：`P-A` 可执行 = **7 ≠ 0** ⇒ **按规则标 🟡**。
- **并且这不是"只剩 fixture 的伪命中"**：7 处里 **1 处是真命中、且是活装置**（`~/w63a/bin/wm-leg198.sh:17`，5.4）⇒ 标 🟡 **在本体上也是对的**。
- **我据此做的判定（明写）**：
  1. **不标 ✅** —— 先写判据不满足，且不满足处**真实存在**；**我没有**为了让这一格变绿而把判据改成"只算 `grep` 形态"或"fixture 不算"（那正是任务书禁止的放宽）。
  2. **不标 🔴** —— 该行要的那一半（"盘点全仓同类写法"）**已做完且有机器读数**；装置侧交件与两极化读数**都在**；剩下的缺口**只有 1 处**、位置与修法都已点名。
  3. **留给主控的一步**：若把 `wm-leg198.sh:17` 修掉（或裁定"fixture/自指不计入"并把口径写进册），**改判 ✅ 是单点改动**。
- 同时在该行下追加收口 bullet（重盘命令 ＋ 三个计数 ＋ 7 处归类 ＋ 判定 ＋ **仍未接线**那条尾巴）。

### 6.3 §13 树行

⚠️ **`TASK-0703`／`TASK-0704` 在 §13 任务树里本来就没有独立树行**（现场核：`grep -n 'TASK-070[0-9]' docs/ROUTES.md` 只命中 `§13` 的一处**叙述句**（`:193`，只说"落地拆新号"）与 §14／§15 的清单行）⇒ **本件只改清单行，未加树行**（同 W96A/W99A 的处置口径）。

### 6.4 🩸 幻影声明（自伤留档，已改正）

`defect-registry-check.sh` 的 `load_maps()` 用 **`grep -noE "$TOKRE"`** **全文抓编号 token**（**不是**只看 `###` 标题行）⇒ 我在 `D-G89` 的新 bullet 初稿里写了"**（如 `<候选号>`）**"这样的**编号字面量**，`--emit` **当场多出一行幻影声明**：

```
> ID	D-G96	req=KD	present=KD
> ID	D-G97	req=KD	present=KD     ← 幻影：册里并无 D-G97 条目
```
⇒ 已把该措辞改写为**不含编号字面量**（"下一个空闲号"），重生成后**幻影行消失**（新增行**只有 `D-G96`**）。这条已作为"引用者注意"写进册里该 bullet。

---

## §7 改了哪几件（before / after，**全部现算 sha16**）

| 件 | before sha16 | after sha16 | 备注 |
|---|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `395cc255b95cc125` | **`b79b8cd455746313`** | **＋36 行、0 删、0 改**（机械证：`diff` vs HEAD blob 删行数 = **0**） |
| `docs/ROUTES.md` | `c9bb57e49345739b` | **`abac9ba3103da336`** | 415 → 439 行；`diff` 只有 **2 处状态位替换**（`TASK-0703` `🔴→🟡`、`TASK-0704` `🔴→✅`）＋ 追加块 |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `0d230bf39f34b9ef` | **`5cddd9ad488e959a`** | 由 `--emit` 生成；**只 ＋1 行 ID（`D-G96`）**；⚠️ 含 `DECL-GEN` 时间戳 ⇒ 每次重生成 sha16 必变（**不是**内容漂移） |
| `~/w63a/REPORT.md`（**仓外**） | `c837e102c8ada0f1` | **`4d3746698860e12b`** | 只**追加**更正块；原文命中数不变 |
| `build/MilBridge/W107A-report.md` | — | 本件（新建；回填前 `a9b095b83f79d98a`，最终值见 §8.4） |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `1f4189c1257737a9` | **未动** | 锚 `AB=1f4189c1257737a9` 逐字未变（§6 DEFREG 行可核） |
| `docs/CURRENT-STATE.md`／`handoff.md` | — | **未动** | 锚 `CS=1ff381a9be8c3c7a`／`HO=e4dc264200b421d0` 与改前**相同** |

**本件新建的私有件（仓外，不在覆盖面）**：`~/w107a/criteria.md` `d06b1e48ec062ca1`｜`~/w107a/resurvey.sh`｜`~/w107a/resurvey2.sh`｜`~/w107a/resurvey.txt` `fc7e958874b8e57a`｜`~/w107a/resurvey-v1-overshoot.txt`｜`~/w107a/fp-check.sh` `1b3770d3b4524b40`｜`~/w107a/fp-check.txt`。

---

## §8 推送前后 head ＋ `BYTECHECK` ＋ parity 两件点名（**第 8 条**）

### 8.1 推送

```
推前 head   = 080af718a1c22597947ac7d9fcad2d449a3baebe   （== origin/feat-Linux）
第一笔 commit = 5d14a9c43f5f76fc9733ba7b602c91cdba8d681b  （5 件）
  A  build/MilBridge/W103A-report.md            （W104A 记的 nobody=1，现已存在 ⇒ 补推）
  A  docs/WAVE51-PREREGISTRATION.md             （主控裁定：要推；af21bdf95b848eb9 原样转推）
  M  build/MilBridge/tools/defect-registry-declared.tsv
  M  docs/ROUTES.md
  M  samples/WpfFeatureProbe/KNOWN-DEFECTS.md
第二笔 commit = 本报告（build/MilBridge/W107A-report.md）
fetch: git fetch origin feat-Linux:refs/remotes/origin/feat-Linux   （refspec 陷阱已避）
push : git push origin feat-Linux   ⇒  080af71..5d14a9c  feat-Linux -> feat-Linux
核对 : local == remote ✔ ；ls-remote --symref origin HEAD ⇒ `ref: refs/heads/feat-Linux  HEAD` ✔
逐径 git add（**未用 -A／--force**）；`git status --porcelain` 只有 staged 的 5 件（无夹带）
```

### 8.2 `BYTECHECK`（逐件 `git cat-file blob <rev>:<path>` 与磁盘 `cmp`，**计数器在主 shell 累加，未用 `tee`**）

```
远端 rev = 85f88adb82fc379163be782122e40a3870aec7d6
=== 本笔 6 件逐件字节核对 ===
  ok  samples/WpfFeatureProbe/KNOWN-DEFECTS.md              (disk=b79b8cd455746313)
  ok  docs/ROUTES.md                                        (disk=abac9ba3103da336)
  ok  build/MilBridge/tools/defect-registry-declared.tsv    (disk=5cddd9ad488e959a)
  ok  build/MilBridge/W103A-report.md                       (disk=d92f0ede166268a7)
  ok  docs/WAVE51-PREREGISTRATION.md                        (disk=af21bdf95b848eb9)
  ok  build/MilBridge/W107A-report.md                       (disk=a9b095b83f79d98a，本报告**回填前**版本)
=== 前一笔遗留件抽查（应已在远端）===
  ok  build/MilBridge/W102A-report.md
  ok  build/MilBridge/W104A-report.md
  ok  build/MilBridge/tools/wm-awaited.sh
BYTECHECK ok=9 mismatch=0 nobody=0
```
⇒ ✅ **`nobody=0`** —— 这一格正是 **W104A 记的 `nobody=1` 的收口**：`build/MilBridge/W103A-report.md` 当时**盘上还不存在**（W103A 还在跑），本笔它**已存在且已在远端、逐字节相同**。
⇒ **`mismatch=0`** ⇒ 本笔全部 6 件**盘上内容 == 远端 blob**。

### 8.3 ⚠️ 两个 `tests/parity/**` 结果件（**点名 ＋ 判定：不推**）

| 项 | `tests/parity/geometry/u14/linux-results-u14.json` | `tests/parity/windows/layout-b34/windows-results.json` |
|---|---|---|
| 大小 | **123,918,748 B**（118.2 MB） | **57,715,362 B**（53.0 MB） |
| mtime | `2026-09-11 09:26:07` | `2026-09-11 16:18:36` |
| `.gitignore` 命中 | **`.gitignore:47`**（`git check-ignore -v` `rc=0`） | **`.gitignore:51`**（`git check-ignore -v` `rc=0`） |
| `git ls-files` 已知？ | **否**（`--error-unmatch` 报"未匹配任何 git 已知文件"） | **否** |
| 谁读它 | **全仓 0 个读者**（`.gitignore:45` 逐字："**探针输出、且全仓没有任何读者**（只有 u14 的 *工程* 被引；JSON 本身没人读）"；重算 = 跑 `tests/parity/geometry/u14/U14.csproj`，语料 `cases-u14.json` 在仓内） | **有读者，但都走仓内派生件**：`tests/parity/windows/layout-b34/verify.py:25`（直读原件）／`build/MilBridge/tools/extract-layout-b34.py:14`（默认 `SRC`）／`build/MilBridge/tests/ProductEntryArm/extract-inputs.py` —— 而 `.gitignore:48-50` 逐字："**当前所有读者都走仓内的派生件**（`build/MilBridge/gen/layout-b34-compact.json` 3.1 MB ＋ `ProductEntryArm/inputs.json` 4.7 KB）⇒ 排除它不改变任何现有判定" |
| 是否 `gitignore` | **是** | **是** |
| **已被别的车道核过？** | W76A §（`W76A-report.md:345`）＋ W95A §（`W95A-report.md:377`）**都记"按既定口径不进"** | 同上 |
| **本件判定** | ✅ **不推** | ✅ **不推** |
| **理由** | ① `.gitignore` 明确排除 ⇒ `-f` 强推会**破坏该口径**；② **118.2 MB > GitHub 单文件 100 MB 硬限**（`.gitignore` 的"推送前硬约束"块 ＋ `README.md:203` ＋ `docs/RELEASE-READINESS.md:19` 逐字"⚠️ 超过 GitHub 的 100 MB/文件硬限 ⇒ 推上去会被**直接拒绝**"）⇒ **技术上推不上去**；③ 无读者、可重算 | ① 同（`.gitignore` 明确排除）；② 所有读者都走**仓内**派生件 ⇒ 排除不改变任何现有判定（该口径写在该件自己的注释里）；③ 它是 **Windows 侧真机 dump**（重新抽取才需要重录） |
| ⚠️ 附带观察 | `links=2` ⇒ **另有一份硬链接副本在 `$R` 之外**（`find $R -samefile` 只命中它自己）⇒ 位置**未定位**，记 `NOINFO` | 同上（`links=2`） |

⇒ **本件对这两件的处置 = "逐件点名 ＋ 不推 ＋ 理由上表"**；**若主控要推**，必须**同时**给出"为什么可以破坏 `.gitignore` 口径"的理由（且 u14 在 100 MB 硬限下**只能走** LFS 或分片，否则必被拒）。

### 8.4 收尾补记（推送后补写 · **本件共 3 笔**）

| 笔 | commit | 内容 |
|---|---|---|
| 1 | `5d14a9c43f5f76fc9733ba7b602c91cdba8d681b` | 册 ＋ 地图 ＋ 声明表 ＋ `W103A-report.md`（补推）＋ `docs/WAVE51-PREREGISTRATION.md` |
| 2 | `85f88adb82fc379163be782122e40a3870aec7d6` | 本报告首版（逐字引文核对 **17/17 OK**） |
| 3 | 本笔（§8.2／§8.4 记账 ＋ §7 自身 sha16 回填） | 本报告的记账更新 |

- **推前 head** = `080af718a1c22597947ac7d9fcad2d449a3baebe`
- **推后 head** = `85f88adb82fc379163be782122e40a3870aec7d6`（`local == remote` ✔，`--symref` 仍 `feat-Linux` ✔）
- **回填前本报告 sha16** = `a9b095b83f79d98a`（第 2 笔那个版本；`BYTECHECK` 核的就是它）
- ⚠️ **自指说明（同 W104A 的口径）**：本报告**每改一次自己的记账**，它的 sha16 就变一次（第 3 笔提交的版本 **≠** `a9b095b83f79d98a`）⇒ **最终 sha16 由主控按 `sha256sum build/MilBridge/W107A-report.md | cut -c1-16` 现算**，本件不手抄自己的哈希。

---

## §9 `fp_inputs` 影响判断（**第 9 条**）

**装置** = `~/w107a/fp-check.sh` `1b3770d3b4524b40`：**复用** `build/close-wave.sh`（`f440ccdb4e29a942`）里 `fp_inputs()` 的**原文**（`awk` 抽 160 行函数体后 `eval`，只把尾部 `| xargs sha256sum …` 换成"打印清单"）⇒ **不手抄覆盖面**。

### 9.1 本件贡献 = **零**（机械证）

```
FP_COVERAGE_FILES=147
  KNOWN-DEFECTS ⇒ 0    ROUTES ⇒ 0    defect-registry-declared ⇒ 0
  W103A-report  ⇒ 0    WAVE51-PREREGISTRATION ⇒ 0    wm-awaited ⇒ 0
  cell3 ⇒ 0            resurvey ⇒ 0   W63A-report ⇒ 0            W107A-report ⇒ 0
```
口径：覆盖面 = ① `find … build …`（**按名枚举**）② `build/shims/**.cs` ③ `src/WpfGfx.Linux/**.cs` ④ `src/WpfGfx.Linux.Native/**.{c,h}` ⑤ 一份 **15 件 `build/MilBridge/tools/*` 白名单**。
⇒ `build/MilBridge/*.md`（报告）、`docs/**`、`samples/**`、`**/*.tsv`、以及 **`wm-awaited.sh`（不在那 15 件白名单里） 一条也不匹配** ⇒ **本件全部编辑件在覆盖面之外 ⇒ 数学上不可能移动 `inputs_fp`**。

### 9.2 ⚠️ 收尾态 **≠ `#50` 冻结值**（**如实记，不当异常**）

**归因装置** = 对覆盖面 **147 件**逐件与 fork 克隆 **HEAD 的 blob** `cmp`：

```
  DIFF    src/WpfGfx.Linux.Native/src/win32_core.c      (disk mtime 2026-09-22 19:20:26)
  DIFF    src/WpfGfx.Linux.Native/src/win32_internal.h  (disk mtime 2026-09-22 19:20:03)
FP_COVERAGE_DIFF_VS_HEAD=2
```
⇒ 偏离的制造者**只有 2 件**，两件都是**在飞的产品改动**（W101A／W106A 的写域），mtime `19:20` **早于**本车道对 `$R` 的任何编辑 ⇒ **与本件无关**（与 W104A §6.2 的归因**同源同值**）。本件为此**不改任何判据、不放宽任何断言**；`#51` 收尾时这一格由**收尾链自己**裁决。

---

## §10 `NOINFO` / 未做（**既不算绿也不算红**）

1. **`D-G95` 仍保留的两条 `NOINFO`**（**未清**）：① `:198` 当时未取 `C2`/`C4`（只有 `C1` ＋ 启动日志）；② **"00:24 那一版脚本的谓词是否本来就对"未读到原文**（本车道也未找到旧副本；`~/w63a` 不是 git 仓库）。
2. **`wm-leg198.sh:17` 那一处活实例：只报不动**（在 `~/w63a/bin/**`，**不在本车道写域**）⇒ 它**未修**，`TASK-0703` 因此**留 🟡**。
3. **"恒真谓词"之外的其他"永不失败的守卫"形态未枚举**（例如 `[ -n "$(cmd)" ]`、`grep -q ''`）⇒ 重盘的**射程边界**，如实记。
4. **未做"修掉后重盘"的成对读数**（本件不改任何装置 ⇒ 没有"修后"那一半）。
5. **`D-G96` 的"全域还有几处装置会截断自己引用的证据"未逐处枚举**（只机械核了 `~/w63a/bin/` 下 `: > "$PROG"` 两处）。
6. **两个 `tests/parity/**` 大件的硬链接副本位置未定位**（`links=2`，`find $R -samefile` 只命中自身）⇒ `NOINFO`。
7. **未跑任何构建/门禁/应用**（本件纪律；槽让给 W105A／W106A）⇒ 本件的读数**未经端到端复跑**。
8. **未改 `handoff.md`／`CURRENT-STATE.md`**（`D-G62+` 的 `req=KD` 一贯口径；且改它们会动锚 ⇒ 本件**选择不做**）。
9. **未推** `src/WpfGfx.Linux.Native/**` 与 `build/PresentationFramework.Linux/**`（**在飞的产品改动**，按纪律"实验装置类改动必须事后还原"⇒ **故意隔离**，这正是本笔只 `add` 5 件的原因）。
10. 🩸 **三处自伤**已逐条留档并改正：① 重盘 v1 的**仪器**两处缺陷（§5.5）；② 我第一次改 `ROUTES.md` 状态位时 `edit` **吞掉了下一行**（`TASK-0703` 的 W102A 交件 bullet）⇒ 已用 **HEAD blob（`c9bb57e49345739b`，与改前磁盘值逐字相同）逐字节复原**核对后，改用**行锚定**改法（`python3` 断言行号 ＋ 替换状态字符），最终 `diff` 只有 2 处状态位替换；③ 册初稿的**幻影编号字面量**（§6.4）。

---

## §11 大白话小结（≤6 行）

1. **归因改了，结论没动**：`w63a` 报告里"WM 没起来是因为我 `xfwm4` 调用形式写错"这句**原因写错了** —— 真原因是那个"要不要起 WM"的判断**永远是假的**，所以那段起 WM 的代码**从来没跑过**。照错的归因去修，只会去改调用形式，**把真正的病根留在原地**。
2. **新登记 `D-G96`**：那个脚本**每次一跑就把自己的进度日志清空**，而 `D-G95` 唯一的现场证据就在那份日志里 —— 也就是说，**你为了复核去重跑，证据当场就没了**（所以复核这类腿必须**先备份日志**）。
3. **全域重盘做完了**：`P-A` 命中 20 处（**可执行 7**／注释 13）、`P-C` **0**。7 处可执行里 **6 处是"故意留着的负控 fixture 或我自己的仪器"**，**1 处是活的**。
4. **那 1 处活的是这次新发现的**：`~/w63a/bin/wm-leg198.sh:17` 用 `case "$wm" in *window*)` 判"WM 在不在"，而 xprop 的**失败文案里也有 `window`** ⇒ 这条守卫**永远为真**。前面两条盘点用的是 `grep -q window`，对这种 `case` 写法**根本看不见** —— 所以 `TASK-0703` 我**只能标 🟡，不能标 ✅**（先写的判据没过，而且没过的地方是真的）。
5. **`TASK-0704` 标 ✅**：四处都修好了，我**自己重算的四个 sha16 与 W103A 报告逐字一样**，两极化有读数，被污染的那趟复核了 **12 条、0 条受影响**。
6. **牙口**：`DEFREG=PASS declared=132 route_ids=132`、`DECLDRIFT=0`；推送 `080af71 → 5d14a9c`（`local == remote`，仍是 `feat-Linux`）；两个 `tests/parity` 大件**按设计不推**（`.gitignore:47/:51` 明确排除，u14 还超 GitHub 的 100 MB 硬限）。

---

## §12 复算命令（逐条可跑）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
# 1) 判据件与私有件哈希
sha256sum ~/w107a/criteria.md ~/w107a/resurvey.txt ~/w107a/fp-check.sh | cut -c1-16
# 2) 全域重盘（只读；输出留档）
bash ~/w107a/resurvey2.sh | tee /tmp/resurvey_now.txt
grep -E 'P_A_EXEC=|P_C_TOTAL=|VERDICT|RESURVEY=' /tmp/resurvey_now.txt
# 3) 唯一那处"活的"命中（形态核对，不跑装置）
sed -n '15p;17p' ~/w63a/bin/wm-leg198.sh
REC='_NET_SUPPORTING_WM_CHECK:  no such atom on any window. '; case "$REC" in *window*) echo 恒真;; esac
# 4) 归因更正的三件证据
sed -n '278,300p' ~/w63a/REPORT.md                  # 原文保留 + 追加块
stat -c '%y %n' ~/w63a/logs/xfwm197.log ~/w63a/logs/wm.progress   # 00:24:03 / 11:37:08（未动）
grep -Fxq -e '> `DISPLAY=x xfwm4 --replace`，**WM 没起来**，`W101` 因此是无 WM 的一趟，已在表里标明）。' -- ~/w63a/REPORT.md && echo 原文仍在
# 5) 四处 after 哈希（应与 W103A 报告逐字相同）
for f in ~/w53a/cell.sh ~/w53a/cell2.sh ~/w76a/bin/ab.sh ~/w63a/bin/wm-leg.sh; do
  printf '%s perm=%s %s\n' "$(sha256sum "$f"|cut -c1-16)" "$(stat -c %a "$f")" "$f"; done
# 6) DEFREG（两遍应逐字相同、rc=0）
cd $R && bash build/MilBridge/tools/defect-registry-check.sh; echo "rc=$?"
bash build/MilBridge/tools/defect-registry-check.sh --emit > build/MilBridge/tools/defect-registry-declared.tsv
# 7) fp_inputs（本件贡献应为 0）
bash ~/w107a/fp-check.sh | grep -E 'FP_COVERAGE_FILES|命中|FP_COVERAGE_DIFF'
# 8) 推送核对
cd ~/netTest/GitProj/WPFOnLinux && git rev-parse HEAD && git ls-remote origin HEAD && git ls-remote --symref origin HEAD | head -2
# 9) parity 两件"按设计不推"
git check-ignore -v tests/parity/geometry/u14/linux-results-u14.json tests/parity/windows/layout-b34/windows-results.json
```
