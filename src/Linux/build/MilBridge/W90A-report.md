# W90A 报告 —— `TASK-0208`：**加强 `R-GATE` 的 `c06` 读数**（让 `D-G85` 的残余红**因为读数变对**而消失，不是判据变松）

> lane **W90A**｜`TASK-0208`｜缺陷 **`D-G85`**（余项）｜2026-09-22 10:19 → 10:41 +0800｜kernel `6.8.0-138-generic`｜`nproc=3`
> 复现器 = **现成**判据件 `R-GATE`（`verify-all` 第 `[26]` 步，`bash build/MilBridge/tools/r-gate-step.sh`），一趟 ≈ 40 s（不含 pc 重建）
> 依据（**未重新侦察**）：`build/MilBridge/W88A-report.md`（**口径 `head -n -2 | sha256sum | cut -c1-16` = `97c03dbc26eefe80`**；整份 `3c4274a323de40c6`）§②③⑦；`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2363` 的 `D-G85`
> 全部读数落 `$HOME/w90a/**`（**四趟**证据目录 ＋ 三个自有工具）；**零 `pkill`**；装置自带私有 Xvfb（`:88`），跑完自收（收工 `pgrep` 无 `:88`）
> 头号结论：**`R_GATE=PASS crit=13/13 red=0`**（两趟独立复现），而判据的**阈值/三态/豁免规则一字未改**。

---

## §0 判据（**先写死，后取读数**；原文见 `$HOME/w90a/criteria.md`，写于 10:21:40，早于任何一趟重活）

| 编号 | 判据 | 本件实测 | 判定 |
|---|---|---|---|
| **J1** | 必须在**本件自己的输出目录**指出 `c06` 在 `L8` 实际读的是哪一行（行号＋原文），并给出"mouse-up 之后一条 `EVT move` 都没有"的机器读数 | §1：切片内唯一 move = `abs=578`（**点击之前**），mouse-up 在 `abs=595`；切片内 `EVT move` 计数 = **1**，其中 mouse-up 之后 = **0** | ✅ |
| **J2** | 阈值/三态/豁免**一字不动**；取数从"最后一条 `EVT move`"换成"**最后一条 `captured=`**"；**读不到 ⇒ 仍红** | §2：`CRIT_TOTAL` 仍 13、`L8` **零新豁免**、`stuck` 名单文字形状未变；新增 `nosrc` 分支＝**一条 `captured=` 都没有 ⇒ 红** | ✅ |
| **J3** | 防假绿：还原修法那一趟里直读行**必须**读到 `ComboBox`（不是恒 `null`） | §3：`~/w90a/rgate-neg/app.log:637  EVT capture at=combo.closed captured=ComboBox` | ✅ |
| 预期①正极性 | `R_GATE=PASS crit=13/13` | 实测 **两趟**（`pos`、`pos2`）都是 `PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0` | ✅ |
| 预期②反极性 | `variant=none` ⇒ `FAIL crit=11/13 red=2`，红格**逐字相同** | 实测 `FAIL crit=11/13 red=2`，`fails=` 与 W88A 的 `#0 baseline`/`leg-none` **逐字节相同**（§3.2） | ✅ |
| 预期③`--selftest` | **21/21 不变** | `R_GATE_SELFTEST=PASS cases=21 pass=21 fail=0 crit_total=13` | ✅ |
| 预期④`grep -c 'captured=ComboBox'` | 任务书写"应从 8 **降**到合法残留" | **实测仍为 8**（加打印不可能删行）⇒ **任务书该前提不成立**，逐条归因见 §4.3 | ⚠️ 如实报 |
| 预期⑤`inputs_fp` | **逐位不变** | **它变了**（`679ec2ddfeda8c97…` → `a816bb4773bc3b5a…`）—— 原因**不是本件**（§6，别的车道改 `win32_x11.c`） | ⚠️ 如实报 |

**偏离预测的两条**：④ 与 ⑤，都在 §4.3 / §6 给机器证；**没有第三条**（`pc`/`hbtextline`/反极性/防假绿/零回归全部命中预测）。

---

## §1 ⚠️ 空洞证据（①：`c06` 为什么在 `L8` 上"读不到"）

**复算目录** = `$HOME/w90a/rgate-0-baseline/`（**本件自己跑的**，不是抄 W88A 的）：仪器 = **旧**版（未加强），产品 = **`D-G85` 修法在**（`pc=5aa6361a5ba02991`），机读行：
```
R_GATE=FAIL crit=12/13 clicks=11 ok=12 red=1 noinfo=0 … fails=c06(鼠标抬起后捕获没释放的腿：L8_comboitem1,…)
```
⇒ 复现出任务书描述的那个"唯一残余红"。

### 1.1 判据读的到底是哪一行

`r-gate-step.sh` 的 `L8` 步骤记录（`evidence.txt`）与切片：
```
EVID step id=L8_comboitem1 kind=click x=301 y=226 inside=1 appline_from=574 appline_to=621 down_delta=1 up_delta=1
```
旧表达式（**逐字**）：
```bash
printf '%s' "$S" | grep -aE '^EVT move ' | tail -1 | grep -q 'captured=null'
```
**把这条表达式原样在 `L8` 切片上复算，它打印出的就是它读的那一行**：
```
$ id=L8_comboitem1; f=574; t=621; S="$(sed -n "$(( f + 1 )),${t}p" app.log)"
$ printf '%s' "$S" | grep -aE '^EVT move ' | tail -1
EVT move root=124,35 src=Border directlyover=Border freshhit=Border captured=ComboBox      ← 就是这一行
$ … | grep -q 'captured=null'  ⇒ RED(stuck)
```
它的绝对行号 = **`app.log:578`**。

### 1.2 为什么读不到 mouse-up 之后那 2px 挪动（`app.log` 原文，行号 = 本趟）

| abs | 原文（节选） | 说明 |
|---|---|---|
| 576 | `[msg] hwnd=0x200008 … msg=0x0200 … lp=0x250082` | 挪进弹窗项：WM_MOUSEMOVE 发往 **弹窗窗口 `0x200008`** |
| **578** | **`EVT move root=124,35 src=Border … captured=ComboBox`** | 卡片 `MouseMove` 打的行 ——**能打到，只因为**当时下拉开着、`ComboBox` **持有捕获**（合法） |
| 590 | `[msg] hwnd=0x200008 … msg=0x0201 …` | 按下（在**弹窗**上） |
| 595 | `[msg] hwnd=0x200008 … msg=0x0202 …` | **抬起（mouse-up）** |
| 598 | `[msg] hwnd=0x200005 … msg=0x0215 wp=0x0 lp=0x0` | **释放回声**（`0x0215` 唯一来源＝shim 的 `ReleaseCapture()`）⇒ 捕获已清 |
| **603** | **`[msg] hwnd=0x200008 … msg=0x0200 … lp=0x250084`** | **就是那 2px 挪动**（`0x250082`→`0x250084`，x 130→132）——**发往弹窗窗口**；捕获已空 ⇒ **不再被强行路由回主窗口** ⇒ 卡片**不打 `EVT move`** |
| 607 | `[msg] hwnd=0x200005 … msg=0x0200 … lp=0xe2012f` | 主窗口也收到一条 motion（x=0x012f=303,y=0x00e2=226＝挪动后的屏幕点），但命中面在弹窗上 ⇒ 卡片**同样不打** |
| 615 | `EVT combo.closed` | 下拉关闭 |

**机器读数**：切片 `(574,621]` 内 `EVT move` 计数 = **1**（即 578），其中 **mouse-up（595）之后 = 0**。

### 1.3 正控：同一个 "读不到" 在**未修**的树上会变成"读得到，但读到的是错的"

`~/w90a/rgate-neg/app.log`（`pc=56ee75ced8d6aece`＝**还原修法**）同一腿：
```
abs=595  EVT move root=124,35 src=Border … captured=ComboBox          ← 点击前（合法：下拉开着）
abs=623  EVT move root=126,35 src=ComboBox … captured=ComboBox        ← **那 2px 挪动**（124→126）被【强行路由】给主窗口 ComboBox
abs=628  EVT move root=290,216 src=ComboBox … freshhit=null captured=ComboBox   ← 那个点下面**没有任何视觉**，照样打进 ComboBox（D-G85 签名）
abs=637  EVT capture at=combo.closed captured=ComboBox                ← 新直读行（**防假绿**，见 §3.3）
```
⇒ **判据隐含的前提**（"每条非豁免腿 mouse-up 之后都有一条**主窗口卡片看得见**的 move"）**恰好在"点弹窗项"这条腿上不成立**；修前它成立，只是因为**缺陷本身**把 move 强行路由给了主窗口的 `ComboBox`。**换句话说：这一格是"修好之后才变得看不见"的。**

### 1.4 判定
> `c06` 的 `L8` 残余红 = **判据/装置域的读数空洞**（"读不到"），**不是"捕获仍粘在 `ComboBox`"**。
> ⇒ 正当的修法是**让读数变对**（给同一时刻一次 `Mouse.Captured` 直读），**不是**放宽判据、也不是给 `L8` 开豁免。

---

## §2 加强逐处 ＋ before/after sha16（②）

### 2.1 改动清单（**仓内只动两件**；`cp -p` 备份在 `$HOME/w90a-backup/`，纪律 65）

| # | 件 | before sha16 | after sha16 | 行数 | diff |
|---|---|---|---|---|---|
| A | `samples/WpfFeatureProbe/FeatureBlocks.cs`（**仪器**） | `1e8512c0692f350d` | **`2dc0f945b2d87ebb`** | 1326 → 1342 | `+18 / -2` |
| B | `build/MilBridge/tools/r-gate-step.sh`（**判据**） | `f263341ad376d51f` | **`23b6ee91a4a8dc9b`** | 546 → 578 | `+41 / -9` |

### 2.2 A：探针补一条**直读**（`FeatureBlocks.cs:1198` 处，逐字）

```diff
-            _combo.DropDownClosed += (_, __) => Ev("combo.closed");
+            _combo.DropDownClosed += (_, __) =>
+            {
+                Ev("combo.closed");
+                Ev("capture at=combo.closed captured=" + (Mouse.Captured?.GetType().Name ?? "null"));
+            };
```
（另附 13 行注释说明为什么必须补、以及两条"不许"；见生成物原文）

**两条硬约束（都已实测，不是猜）**：
1. **不许**把 `captured=` 直接缀到 `combo.closed` 那一行上 —— `c05`（`^EVT combo\.closed[[:space:]]*$`）与 `c06` 的豁免计数（`^EVT combo\.opened$` / `^EVT combo\.closed$`）**都锚定整行** ⇒ 缀上去会把 `c05` 与豁免计数一起打红。⇒ **另起一行**。
2. 新行**不许**以 `EVT lst.` / `EVT tb.` / `EVT combo.` 开头 —— `c07`/`c08` 用 `^EVT (lst|tb|combo)\.` 数"控件级 EVT" ⇒ 那会污染反极性格的判据面。⇒ 用 `EVT capture at=…`。
   **实测旁证**：加强后 `c07`/`c08`/`c10` 仍 PASS（§5）。

### 2.3 B：`c06` 取数换源（**阈值/语义/豁免一字不动**）

```diff
-    if printf '%s' "$S" | grep -aE '^EVT move ' | tail -1 | grep -q 'captured=null'; then ncap=$((ncap + 1)); else stuck="${stuck}${id} "; fi
+    local lastcap
+    lastcap="$(printf '%s' "$S" | grep -aoE 'captured=[A-Za-z_.]+' | tail -1)"
+    reads="${reads}${id}=${lastcap:-<无读数>} "
+    if [ -z "$lastcap" ]; then nosrc="${nosrc}${id} "; continue; fi          # 读不到 ⇒ 仍红（不许当绿）
+    if [ "$lastcap" = "captured=null" ]; then ncap=$((ncap + 1)); else stuck="${stuck}${id} "; fi
```
＋ 三态分支加一条 `nosrc`（"一条 `captured=` 都没有 ⇒ **红**"）、＋ 一行**可审读数行**（逐腿印出"判据实际读到的最后一条 `captured=`"）、＋ 注释块更新为三条口径。

**"换源 ≠ 放宽"的两条硬界线（本件成对读数已证）**：
* **(a) 旧读数是新读数的子集**：腿里有 `EVT move` 时，旧读的是"最后一条 move 的 `captured=`"，新读的是"**时间上最晚**的一条 `captured=`"——后者只会**更晚或同一条** ⇒ 只有"旧件**无数据可读**"的那一格才可能翻转。
* **(b) 无数据 ⇒ 仍红**：`nosrc` 分支把"读不到"**继续判红**（旧件在 `L8` 那格正是这种"读不到"）。⇒ **不许**出现"读不到当绿"。
* **`L8` 零新豁免**：豁免规则（`combo.opened` > `combo.closed`）一字未动；§5 的反极性里 `L8` 照样红。
* **`stuck` 名单文字形状一字未动**（仍 `"<id> "` 空格分隔）⇒ 反极性那趟 `fails=` 与基线**逐字节相同**（§3.2）。

### 2.4 夹具（`--selftest`）同趟改（**例数不变、只加严**）
`mkfix` 的 `L8` 腿**照现实改**：**删掉**那条 `EVT move`（＝修好之后主窗口卡片真的打不出它），改由新直读行决定该格；直读值跟着同一个档位走（新增 `CAPD`：`good` ⇒ `null`，`cap-stuck-after-close` ⇒ `ComboBox`）。
**为什么这是加严**：旧读法在这一腿**无数据可读** ⇒ 旧的 `c06` 只能判红；新读法必须**真的读到 `null`** 才允许绿。
**机器证（本件实测，见 §4.1）**：把**新夹具**喂给**旧读法**（自建副本 `$HOME/w90a/tools/r-gate-oldread.sh` `dd2dddf22b85f653`，只把取数换回旧表达式）⇒ `R_GATE_SELFTEST=FAIL cases=21 pass=18 fail=3`（`S1`/`S10`/`S16` 全因 `L8` 的 `c06` 变红）⇒ **新夹具只有新读法能过**。

---

## §3 两极化三侧读数（③）

### 3.1 一趟一行的机读表（**同一命令**，全部在 `bash ~/heavy-slot.sh --min-avail 1500 --max-hold 220 --wait 1200 -- timeout 210 …` 内）

| # | tag | 仪器 | 产品 | `pc` before → after | `R_GATE=` 机读行 |
|---|---|---|---|---|---|
| 0 | `rgate-0-baseline` | **旧** | `D-G85` 修在 | 未重建（`5aa6361a5ba02991`） | `FAIL crit=12/13 … red=1 … fails=c06(…L8_comboitem1…)` |
| 1 | **`rgate-pos`** | **新** | `D-G85` 修在 | `5aa6361a5ba02991` → `5aa6361a5ba02991` | **`PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449`** |
| 2 | **`rgate-neg`** | **新** | **`--variant=none`**（还原修法） | `5aa6361a5ba02991` → **`56ee75ced8d6aece`** | **`FAIL crit=11/13 … red=2 … fails=c06(…L8_comboitem1,SEQ_lst0,SEQ_tb…),c11(…seq-lst0,seq-tb…)`** |
| 3 | **`rgate-pos2`** | **新** | 修法复原 | `56ee75ced8d6aece` → **`5aa6361a5ba02991`（逐字节）** | **`PASS crit=13/13 … red=0`** |

* **`pc` 往返闭合**：`5aa6361a5ba02991` →（还原）`56ee75ced8d6aece` →（复原）**逐字节回到 `5aa6361a5ba02991`** ⇒ "**是 `D-G85` 修法（不是别的什么）造成了这一格的差异**"被机器证明。
* **正极性有两趟**（`pos` 与 `pos2`，两次独立重建＋两次独立应用运行）⇒ 不是单趟侥幸。
* `pos` 与 `pos2` 的 `c06` 逐腿读数行**逐字相同**：8 条非豁免腿全 `captured=null`，3 条豁免（`L6_combo` / `L6b_combo_reopen` / `SEQ_combo`）。

### 3.2 反极性：**红格逐字节相同**（与 W88A 的原始读数比，不是我自说自话）

```
W88A  ~/w88a/logs/leg-none.out  (pc=56ee75ced8d6aece, variant=none)
W90A  ~/w90a/logs/leg2-neg.out  (pc=56ee75ced8d6aece, variant=none)
$ A=$(grep -h '^R_GATE=' ~/w88a/logs/leg-none.out | sed 's/.*fails=//')
$ B=$(grep -h '^R_GATE=' ~/w90a/logs/leg2-neg.out | sed 's/.*fails=//')
$ [ "$A" = "$B" ]  ⇒  逐字相同 ✅
fails=c06(鼠标抬起后捕获没释放的腿：L8_comboitem1,SEQ_lst0,SEQ_tb,（下拉**已关**却仍,captured≠null；D-G55,指纹,——,之后所有点击都会被路由到那个控件）),c11(连续腿缺格：seq-lst0,seq-tb,（**这一格是,D-G55,的判据**,——,单发点击会假绿）)
```
⇒ **判据的取数来源换了，红格却一个字节都没变** —— 这正是"加强而不是放宽"的最硬证据（若新读法把 `L8` 变成恒绿，这一趟的 `c06` 名单就会少一项）。

### 3.3 防假绿：新读数**真的在咬**（不是恒 `null`）
* `~/w90a/rgate-neg/app.log:637` = **`EVT capture at=combo.closed captured=ComboBox`** ⇒ 还原修法之后，**同一条直读行**读到的是 `ComboBox`。
* `~/w90a/rgate-pos/app.log:664` = `EVT capture at=combo.closed captured=null`（`L8`）／`:560`（`L7`）。
* **同一腿、两棵树、同一条读数**（`L8` 切片，new 表达式逐腿读数行原文）：
  * `pos`：`L8_comboitem1=captured=null` ⇒ 绿
  * `neg`：`L8_comboitem1=captured=ComboBox` ⇒ **红**
  ⇒ 新读数在"健康树"给 `null`、在"坏树"给 `ComboBox`；**两侧的判据是同一条式子**。
* **决定性来源的隔离**：`L8` 切片里那条**点击前** move 在**两棵树里都**是 `captured=ComboBox`（下拉正开着 ⇒ 合法）。
  * `pos` 绿 ⇒ 说明决定这一格的是**直读行**（时间更晚），不是那条 move；
  * `neg` 红 ⇒ 说明直读行变 `ComboBox` 时它**立刻**变红。
  ⇒ **直读行是这一格的唯一决定者**，而它两向都动。

### 3.4 `c06` 逐腿读数（机读行的旁证，**新增的可审行**原文）

| 腿 | `pos`（修在） | `neg`（还原） | `#0` 旧仪器（用**新**表达式**复算**旧日志） |
|---|---|---|---|
| `L1_outside` / `L2_blank` / `L3_lst1` / `L4_tb` | `null` | `null` | `null` |
| `L6_combo` / `L6b_combo_reopen` / `SEQ_combo` | **豁免**（下拉仍开） | **豁免** | 豁免（注：旧件对 `L6b` 也豁免） |
| `L7_combo_blank` | `null` | `null` | `null` |
| **`L8_comboitem1`** | **`null`** ✅ | **`ComboBox`** ❌ | **`ComboBox`**（旧件无直读行 ⇒ 最后一条 `captured=` 就是"点击前"那条） |
| `SEQ_lst0` / `SEQ_tb` | `null` | `ComboBox` | `null`（旧仪器·修在：`SEQ` 两腿已释放） |

---

## §4 `--selftest`、`captured` 普查、`grep -c` 读数（④）

### 4.1 `--selftest`：**例数不变、结果全绿；且新夹具只有新读法能过**

| 判据件 | 夹具 | 结果 |
|---|---|---|
| **新件** `23b6ee91a4a8dc9b` | **新**夹具 | **`R_GATE_SELFTEST=PASS cases=21 pass=21 fail=0 crit_total=13`**；`ST_ATTEST=PASS … sha16=23b6ee91a4a8dc9b` |
| 自建副本 `~/w90a/tools/r-gate-oldread.sh` `dd2dddf22b85f653`（**只**把取数换回旧表达式） | **新**夹具 | `R_GATE_SELFTEST=FAIL cases=21 **pass=18 fail=3**` ⇒ `S1 正极性（全绿）` **NO**（`c06` 红 `L8_comboitem1`）、`S10` NO、`S16` NO |
| 开工前备份 `~/w90a-backup/r-gate-step.sh.before90` `f263341ad376d51f` | **旧**夹具（件内自带） | `PASS cases=21 pass=21` |

* ⚠️ **第三行不是证据**（旧件自带旧夹具，当然过）—— 我把它列出来正是为了划清"这一行什么也证明不了"。
* 第二行才是证据：**把新夹具喂给旧读法 ⇒ 3 例当场红** ⇒ 夹具改动是**加严**，新读法**必须**存在。
* `S7b c06 下拉关了仍抓捕获` 的 `fails=` 里 **`L8_comboitem1` 在列**，而新夹具的 `L8` 腿**没有 move 行** ⇒ 它红**只能**来自直读行。

### 4.2 四腿 `captured=` ＋ 全量普查（口径同 W88A §3.2：`grep -ao 'captured=[A-Za-z_.]*' app.log | sort | uniq -c`）

| 量 | `#0` 旧仪器·修在 | **`#1` 新仪器·修在（`pos`）** | `#2` 新仪器·还原（`neg`） |
|---|---|---|---|
| `captured=ComboBox` | **8** | **8** | 16 |
| `captured=null` | 17 | **19**（＝17＋**2 条新直读**） | 12 |
| `captured=TextBox` | 2 | 2 | 1 |
| **`captured=PopupRoot`** | **0** | **0** | **0** |

**四腿口径**（任务书要的那一句）：`SEQ_lst0=null` ✅｜`SEQ_tb=null` ✅｜`SEQ_combo=ComboBox`（本腿点开下拉 ⇒ **合法捕获**，`c06` 自己豁免它）✅｜`L8`：`pos` = **`null`（直读）**、`neg` = `ComboBox`。
**`captured=PopupRoot` 仍 0** ⇒ 没有变成"粘在已销毁弹窗"（`D-G86` 那条风险本现场仍不成立）。

### 4.3 ⚠️ `grep -c 'captured=ComboBox'`：**没有从 8 降下来**（任务书前提不成立）＋ 8 条逐条归因

**机器读数**：`pos` 实测 = **8**（与 W88A 的 8 相同）。
**机制**：本次加强**只新增一行打印**，**不可能删掉任何既有行** ⇒ 计数只可能"不变或变大"。任务书那句"应从 8 **降到**合法残留"在机制上不成立。

**8 条逐条归因（本件现场按腿切片机器归因，不是目测）** —— **全部 8 条都落在"下拉开着的那一刻"⇒ 全是合法捕获，一条也不是"关了还粘着"**：

| 腿 | 条数 | 绝对行号 | 那一刻下拉 | 合法？ |
|---|---|---|---|---|
| `L6_combo` | 2 | 480, 521 | 本腿点开、腿末仍开 ⇒ **豁免** | ✅ |
| `L7_combo_blank` | 1 | 536 | **点之前**（下拉仍开）；本腿关闭在 559 | ✅ |
| `L6b_combo_reopen` | 2 | 577, 613 | 本腿重开、腿末仍开 ⇒ **豁免** | ✅ |
| **`L8_comboitem1`** | 1 | **624** | **点击之前**（下拉仍开）——**不是残留**！`L8` 的判定改由 `:664` 的直读行（`null`）承担 | ✅ |
| `SEQ_combo` | 2 | 840, 877 | 本腿点开、腿末仍开 ⇒ **豁免**（**任务书点名的那一条**） | ✅ |
| 合计 | **8** | | | **8/8 合法** |

⇒ 结论：`8` **就是这个现场的正确读数**（"下拉开着时的合法捕获"共 8 次），它**不该**降；`c06` 之所以曾是红，从来不是这 8 条里的任何一条，而是**判据在 `L8` 上读错了行**。**"降到合法残留"若被当成验收条件，会误伤 8 条合法读数中的 7 条**（只剩 `L8` 那条"点击前"的会消失，而那需要改动行为、不是加强读数）。

---

## §5 零回归（⑤）

| 检查 | 读数 | 判定 |
|---|---|---|
| `c01/02/03/04/05/07/08/09/10/11/12/13` | `pos`/`pos2` 两趟**全 PASS**（`ok=13`／`ok=13`） | ✅ 零回归 |
| `c06`（唯一变化格） | `L8` 由红转绿，且**反极性趟照样红** | ✅ 不是恒绿 |
| 下界（不计入判据格） | `窗口内的每一下点击都收到了 WM_LBUTTONDOWN` | ✅ |
| `--selftest` | `PASS cases=21 pass=21 fail=0 crit_total=13` | ✅ **不变** |
| `CRIT_TOTAL` / `EXPECT_CLICKS_MUST` / `EXPECT_TYPEWORDS` / `MIN_PX_OPEN` | `13` / `10` / `3` / `1` —— **一字未改** | ✅ |
| `verify-all.sh` 的步名/步数/第 `[26]` 步接线 | **未碰**（`verify-all.sh:44,64,74,869-870` 现场只读核过；步数仍 26、第 `[26]` 步 = `run_step "R-GATE（连续交互）" bash build/MilBridge/tools/r-gate-step.sh`） | ✅ |
| 四个路由件 / `defect-registry-declared.tsv` / `build/shims/**` / `build/PresentationCore.Linux/**` 源 / `build/PresentationFramework.Linux/**` / `build/DirectWrite.Linux/**` / `src/WpfGfx.Linux.Native/**` | **本件零手写改动** | ✅ |
| 变体翻转对 `D-G85` 落地的**净影响** | 复原后 `MouseDevice.Linux.cs` = `917d807f43777c49`、`PresentationCore.Linux.csproj` = `7f3c0acd40acc84b`、`pc` = `5aa6361a5ba02991` —— **与 W88A 的落地态逐字节相同**（应用器幂等） | ✅ |
| 应用器自证 | `patch-presentationcore-mousecapture-release.py --check` ⇒ **rc=0**（锚点 1/1；`throw`/`{`/`}` 计数上游==生成物） | ✅ |
| 残留进程 | 收工 `:88` Xvfb **无**、`WpfFeatureProbe` **无**；**零 `pkill`** | ✅ |

---

## §6 世代位与 `inputs_fp` 影响（⑥）

### 6.1 九位（现场算，收工值）

| 位 | 值 | 本件 |
|---|---|---|
| `pc` | **`5aa6361a5ba02991`** | 修法在＝本件**未改产品**（只做变体翻转，已复原） |
| `hbtextline_shim` | **`921ba9c65e9fb3be`** | **未变**（本件零改动） |
| `win32shim` | `58a79b913e9ed8f4` | **另一个车道改的**（§6.3），不是本件 |
| `bridge` / `windowsbase` / `provider` / `wic_shim` / `dwf` | `feef049e9d0e313a` / `2e4e46e539a72cd7` / `1f9511a7ef395bfe` / `f7b3026c8c019be2` / `de2d555105b7d04b` | 全未变 |
| `BRIDGE_SRC_FP` | `0a8f69b3c5fabd43` | 未变 |
| 探针字节 | `pos` `65f2115d444112d3`；`neg` `0b8795cb4b8bac32` | ⚠️ **两趟不同** —— 见 §7 `NOINFO` 第 5 条（**不是**本件写域问题：`pc` 是它的引用件） |

### 6.2 `inputs_fp`：**变了，但不是本件**

```
开工（10:20:45）= 679ec2ddfeda8c970c86c66ae49c0a609e3fbc41c167571ffa5bc23493cb71bd
收工（10:40）  = a816bb4773bc3b5abed37f3ae90ae8edd69c854cb11b71b2ba0bf85d0c3c8524
```
**"本件不可能动它"的机器证**（用 `close-wave.sh:70` 的 `fp_inputs()` **逐字复制**到自己的复算器 `$HOME/w90a/tools/fp.sh`，额外 dump 件清单）：
```
$ bash ~/w90a/tools/fp.sh --list
件数=145
--- r-gate / WpfFeatureProbe / samples 覆盖情况 ---
34:samples/ThirdPartyMini/run-thirdparty-mini.sh      ← 只有这一件（在 18 件**显式清单**里）
```
* `build/MilBridge/tools/r-gate-step.sh` 在 `build` 下**深度 3**，而覆盖面里 `build` 那一支只取 `-maxdepth 1`（`port-lib.py` / `integration-wave.sh` / `close-wave.sh`）＋ `src/WpfGfx.Linux.Native/tools` 的 `patch-*.py` ⇒ **0 命中**；
* `samples/WpfFeatureProbe/**` **一件都不在**覆盖面里（`grep -c 'WpfFeatureProbe'` = **0**）；
⇒ **本件改的两件都不可达 `inputs_fp`**。对照 W88A 的 `fp_inputs` 行为也一致（他们新增应用器时才动）。

**那它为什么变了？机器证（不是我做的事）**：
```
覆盖面内、mtime ≥ 2026-09-22 10:15 的件：
  2026-09-22 10:18:27  0ac2eed4c66cd43d  build/integration-wave.sh        ← 早于本件第一次采样（10:20:45）⇒ 不构成增量
  2026-09-22 10:23:52  2550042f933d48d6  src/WpfGfx.Linux.Native/src/win32_x11.c   ← ★ 唯一落在我窗口内的增量
原生 shim：src/WpfGfx.Linux.Native/bin/libwpfwin32.so  mtime 10:24:12，且
  `#0`（10:22 趟）读到 win32shim=36be8be5c2f3092f；`pos`（10:27 趟）读到 58a79b913e9ed8f4  ⇒ 有别的车道在重建它
```
* `win32_x11.c` 是**另一条车道 W89A**（`TASK-0205` / `D-G81`）的写域：其 `criteria.md:44` 逐字写"落点 = `src/WpfGfx.Linux.Native/src/win32_x11.c`（**只此一个文件**）"，且它在 10:19:34 落了 `libwpfwin32.so.v2fix`。
* ⇒ **`inputs_fp` 的位移归因于别的车道改原生源**；本件的两件**在覆盖面之外**。
* ⚠️ **字节级完全隔离 = `NOINFO`**：我**没有**在 10:20:45 那一刻快照 `win32_x11.c`，事后用两份候选备份（`~/w89a/backup/win32_x11.c.orig` = `050f349638bbf87e`、`~/w82a/backup/win32_x11.c.pre` = 同值）代入聚合式**都复现不出旧值**（得 `b3bf5df0ee015038…`）⇒ 那一刻的中间内容已不可得，"**只有**它这一个件变了"这件事**没有**做到字节级闭合。见 §7 第 1 条。
* **`repin --why` 记账**（任务书要求）：本件**没有**跑重钉（那是主控/波尾动作），也**不要求**重钉 —— 因为 `known-red.json` 的重钉锚的是**判据/登记面**，而本件改的两件**都不在 `fp_inputs` 且都不在 `known-red.json` 的覆盖面内**；收尾链若因为别人改原生源而要重钉，**责任不在本件**。逐字建议交主控裁定（见 §9 第 6 条）。

---

## §7 `NOINFO`（⑦，**既不算绿也不算红**）

1. **`inputs_fp` 位移的字节级归因取不到**：10:20:45 那一刻 `win32_x11.c` 的内容没有快照；用 `~/w89a/backup/win32_x11.c.orig`（`050f349638bbf87e`，2026-09-21 00:23）与 `~/w82a/backup/win32_x11.c.pre`（同 sha）代入聚合式都**复现不出** `679ec2ddfeda8c97…`（得 `b3bf5df0ee015038…`）。⇒ 我只能证到"**本件两件不在覆盖面内**"＋"**窗口内变的覆盖面件只有 `win32_x11.c`**（且它是 W89A 的写域）"，**不能**证到"它一个字节一个件地解释了全部差值"（也可能有别的车道用 `cp -p` 保留了 mtime）。
2. **真机 Windows 对照不可测**（本机无 Windows）：`D-G55`/`D-G85` 语义上"点外面关 ⇒ 释放 vs 点选项关 ⇒ 不释放"的真机行为**无法直读**。
3. **`GetCapture()`（shim 侧 `g_capture_window`）没有直读**：本件只用"`0x0215` 的存在 ⇒ `ReleaseCapture()` 跑过"这条推论；要直读需给探针加 `[DllImport("user32.dll")] GetCapture()`（动共享样本**更多**）。
4. **`RawMouseInputReport.Actions` 没有直读**（W88A §7 第 2 条同款）；整趟 `verify-all` **未跑**（任务书禁止）⇒ 第 `[26]` 步在整趟里的次序/耗时只有静态保证。
5. **探针二进制 `probe=` sha16 在两趟间不同**（`65f2115d444112d3` vs `0b8795cb4b8bac32`），**原因已查明**：`samples/WpfFeatureProbe.dll` 是**对 `PresentationCore.dll` 的引用**，`pos` 趟链接 `5aa6361a5ba02991`、`neg` 趟链接 `56ee75ced8d6aece` ⇒ 重建即异（dll mtime 10:30:24＝neg 趟内）。⇒ **`probe=` 不是可用的版本锚**（本件**没有**把它当锚）；但"**同一 `pc` 下它是否稳定**"本件**未取读数**（`pos` vs `pos2` 都是 `PASS`，`pos2` 的 `probe=` 未逐字比对）。
6. **`c06` 对"弹窗窗口自己持捕获"的腿无直读**：探针只在**主窗口卡片**（`MouseMove`）与 **`DropDownClosed`** 两处读 `captured=`；若哪天下拉项被点之后捕获**粘在 `PopupRoot`**，`L8` 的既有点读不到它（`neg`/`pos` 两趟 `PopupRoot` 都是 0 ⇒ 本现场未暴露）。要覆盖它需再加读数点（**本件未加**，避免扩大改面）。
7. **`L7_combo_blank` 的直读时机**：本件只用"腿内**最后一条** `captured=`"这一条口径，**没有**单独验证"`combo.closed` 那一刻恰好是捕获释放的**分界瞬间**"（`pos` 里 545 就已是 `null`、559 才 `closed` ⇒ 本现场不是分界瞬间；若将来是，读数会偏"晚"而不是偏"松"，方向安全，但**没有独立读数**）。

---

## §8 读数表、内存三值、残留（⑧）

| 量 | 读数 |
|---|---|
| **`MemAvailable`** | **开工 `2613 MB`**（`HEAVYSLOT=MEMOK avail=2613MB`，10:22）｜**最低 `2000 MB`**（`pos2` 趟装置自报 `mem_mb=2000`，10:35）｜**收工 `1888 MB`**（10:41 `/proc/meminfo`）｜门槛 `1500 MB` |
| **`loadavg`** | 开工 `0.35 1.01 1.64`（`INNER pos` 10:27；本件第一条命令 10:19 时 ≈ `1.5x`）｜装置自报峰值 **`4.53 2.10 1.87`**（`pos2` 10:35，三条车道并发）｜收工 `2.96 2.02 1.85` |
| **重活纪律** | **四趟重活全部**包在 `bash ~/heavy-slot.sh --min-avail 1500 --max-hold 220 --wait 1200 -- timeout 210 …` 内；槽内等待 `72 s / 111 s / 163 s`（另两条车道在跑，**排队不绕槽**）；**未出现** `MAXHOLD_KILL` / `NOINFO low-memory` ⇒ 四趟都是**有效读数** |
| 残留 | 本件起的 Xvfb `:88` **0**（装置按 PID 自收）；`WpfFeatureProbe` **0**；**零 `pkill -f`**；`ps` 里剩下的 `Xvfb :99/:97/:37/:38/:39` 与两个 `heavy-slot` 持有者是**别的车道**的（W85A / W89A） |
| 本件读数件 | `$HOME/w90a/rgate-{0-baseline,pos,neg,pos2}/{app.log,evidence.txt}`｜`$HOME/w90a/logs/leg{0-baseline,1-pos,2-neg,3-pos2}.out`｜`$HOME/w90a/tools/{fp.sh,leg.sh,inner.sh,r-gate-oldread.sh}`｜`$HOME/w90a/criteria.md`（**判据先写**）｜`$HOME/w90a-backup/{FeatureBlocks.cs,r-gate-step.sh}.before90` |
| **仪器自伤（如实入册）** | ① 我第一版 `fp.sh` 的 `cd "$(dirname "$0")/../../../.."` 在 `$HOME/w90a/tools` 下**解错了根** ⇒ 输出 `e3b0c442…`（**空输入的 sha256**，一个"看起来像指纹"的假值）；当场发现并改为绝对路径 `R=…`，之后所有 `inputs_fp` 读数都用修好的那一版。② 我在 `leg3`（复原趟）**运行中途**跑了 `nine.sh`，那一格读到 `pc=56ee75ced8d6aece`（＝**负极性态**，不是终态）；**§6.1 的九位是 `leg3` 结束后重取的**，中途那一次作废。 |

---

## §9 ≤6 行大白话小结（⑨）

1. **`R_GATE` 到 `PASS 13/13 red=0` 了**（两趟独立复现），残余的 `c06` 红**消失的原因是读数变对了**，不是判据变松：`c06` 的阈值、三态、豁免规则**一字未改**，`L8` **没开豁免**，`CRIT_TOTAL` 仍 13。
2. **它原来是"读不到"**：`L8` 的切片里唯一的 `EVT move` 在 `app.log:578`（**点击之前**，那时下拉正开着、`ComboBox` 持捕获**合法**），mouse-up（`:595`）之后那 2px 挪动发往**弹窗窗口**（`:603`，`lp=0x250082→0x250084`）⇒ 主窗口卡片**打不出 move** ⇒ 判据只好回退读 `:578` ⇒ 判红。**这一格是"修好之后才变得看不见"的。**
3. **加强只有两处**：探针在 `DropDownClosed` 补一条**同一时刻的 `Mouse.Captured` 直读**（另起一行，不改 `combo.closed` 那行的形状）；`c06` 把取数从"最后一条 `EVT move`"换成"**最后一条 `captured=`**"，并新增"**一条读数都没有 ⇒ 仍红**"的分支。
4. **防假绿成立**：还原 `D-G85` 修法（`--variant=none`）那一趟里，**同一条直读行**读到 `EVT capture at=combo.closed captured=ComboBox`（`neg/app.log:637`），`R_GATE` 回到 `FAIL crit=11/13 red=2`，且 `fails=` 与 W88A 的原始基线**逐字节相同**；`pc` 也逐字节回到 `56ee75ced8d6aece` 再逐字节复原。
5. **零回归**：`--selftest` 仍 **21/21**（且"新夹具＋旧读法"实测 **18/21**（3 例红）⇒ 夹具是加严的）；`PopupRoot` 仍 0；`verify-all.sh` 与四个路由件零改动；`hbtextline` 未变。
6. **两条要请主控裁定**：① `grep -c 'captured=ComboBox'` **没有从 8 降下来**——**机制上不可能降**（加打印不删行），且那 8 条**逐条归因全是"下拉开着时的合法捕获"**（含任务书点名的 `SEQ_combo`）⇒ 建议**撤掉"降到合法残留"这条验收口径**，改判"`c06` 不再因为**读不到**而红"；② `inputs_fp` 变了但**不是本件**（本件两件都在覆盖面之外，机器证 0 命中；位移来自另一条车道 W89A 改 `src/WpfGfx.Linux.Native/src/win32_x11.c`）⇒ `repin --why` 请按**那个**变化记账，字节级闭合我这边是 `NOINFO`。

---

**本报告自身 sha16**（口径：**`head -n -2 build/MilBridge/W90A-report.md | sha256sum | cut -c1-16`** —— 即"末两行之外"的全文；读者可现场复算并必须得到同一个值）＝ **`432cde2f15aa69dc`**
⚠️ 回填这一行之后全文 sha 就变了（"报告自指"的老问题）⇒ 引用时**按上面这条命令现场重算**，别抄这个数。
