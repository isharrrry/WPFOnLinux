# W24C · `#24` P3 —— `hasOverflowed` 判据接线（`CoverageProbe --tab-lines-oracle`）

> **lane = W24C**｜起止 **2026-09-17 09:30:53 → 09:47 +0800**｜`kernel` **6.8.0-138-generic**｜`nproc` **3**｜`DISPLAY=:97` = **UP**（未自起 Xvfb，本件也不需要 X）｜全程**未** `pkill -f`（按 PID 止损）。
> **一句话结论**：新列**接线后全绿**（`TAB_LINES OVERFLOWED 红=0 绿=421 判定行=421 NOINFO=194`，分母 = `script==latin` 的 **288 例 / 421 行**），与预登记 §3.2「预测红 = 0 行 / 0 例」**逐位兑现**；**四档反极性全部拿到**（22/8、79/48、399/280、58/47，全部与 W23D 的 latin 列预测**逐位吻合**）⇒ **本列不是恒绿**；既有判据行**一个字节未动**（`cmp` 证）；**门禁仍 `PASS`**；**九位与 `inputs_fp` 逐位不变**；**`pc` 全程未变**。
> **本件的性质**：接线 + 读数（纪律 41 的第三种强度：**在被门禁读到的臂上**）。**`NOINFO` 一处不省**（§9）。

---

## §0 硬性结论速查

| 项 | 实测 |
|---|---|
| 新列修后形态 | **红 = 0 行 / 0 例**｜绿 421｜判定行 **421**｜NOINFO **194 行 / 148 例**（分母 latin 288 例） |
| 与预测对照 | 预登记 §3.2「接线后预测红 = 0 行 / 0 例」⇒ **逐位兑现** |
| 正控（真值非恒定） | 判定集内 **真值 True = 22 行 / 8 例**、False = 399 ⇒ 列**有判别力**（纪律 3/25/27） |
| 反极性档数 | **4 档全部拿到**：`=>false` **22/8**｜错驱动量 **79/48**｜`=>true` **399/280**｜去掉严格性 `>=` **58/47** |
| 发丝边界诊断 | `诊断发丝边界行=58`（独立现算 = 58 行 / 47 例）—— **与 (e) 档的红数逐位相同**（见 §4.5） |
| 既有判据行 | **逐字节未动**：剥掉 `^TAB_LINES OVERFLOWED` 行后与 `#23` 原日志 **`cmp` 逐字节相同**（三支臂全过） |
| 门禁 | `TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc`、**rc=0** |
| 九位 / `inputs_fp` | **逐位不变**（§7） |
| `pc` | 全程 **`7b47a7b3d69ad62f`**（本件每一次构建与每一次运行的前后复取**全同**、**未被 W24A 改过**） |
| `hbtextline` | **`e89fed55fd8e32bc` 未变**（本件**未碰 `build/shims/**`**） |
| §5 表外位移 | **无**（本件的预期位移 = 三支 tab 臂日志 + 仪器，均在 §5/§3.3 之内） |

---

## §1 新列的确切语义（**只增一列**）

### 1.1 口径（逐字写清，含"必须写死严格 `>`"）

| | |
|---|---|
| **落点** | `build/MilBridge/tests/CoverageProbe/Program.cs` 的 `--tab-lines-oracle` 路径（= 门禁三支 tab 臂的宿主）；逐例循环 `:1343` 起，比较区 `:1349-1660`。**新块行号（改动后版本）**：列声明 **`:1318-1342`**、缺字形分支 **`:1381-1384`**、抛异常分支 **`:1417-1420`**、逐例比较 **`:1565-1612`**、汇总/对账/喂 rc **`:1641-1659`**、新 helper `OverTruthCount` **`:1683-1697`**（全文件 1,801 行） |
| **我方侧** | 逐行 `lines[k].HasOverflowed`（`bool`，**无容差**） |
| **真值侧** | `cases[].lines[].hasOverflowed`（布尔；**`tab-anchor-oracle.json` 615/615 行非 null**，本件现算复核） |
| **断言** | **布尔全等** `ours == truth`（差 1 行 ⇒ 该行红、该例点名、计入 `failures` ⇒ 影响 rc） |
| **⚡ 写死的语义** | 实现 = `shim` 的 `public override bool HasOverflowed`（`build/shims/PresentationCore.HbTextLine.cs:3515-3526`）**三分支**：① `!(_paragraphWidth > 0)` ⇒ `false`；② `_startPenX >= _paragraphWidth` ⇒ `true`；③ **严格** `_boxOriginX + _width > _paragraphWidth + 1e-9` ⇒ `true`。**本列只断言等值、不另发明容差**；"**严格 `>`、相等 ⇒ `false`**"这句话既写在**代码注释**里，也把**它翻面会红多少**做成了读数（§4.4 的 (e) 档 = **58 行 / 47 例**）⇒ **语义被机器钉住，不是被文字钉住**。 |
| **可比性闸门（三道，全部复用既有闸门，未新增口径）** | ① **覆盖闸**（面缺字形）⇒ `NOINFO=面缺字形N`；② **`TextAlignment == "Left"`**（语料头 `paragraphProperties.fixed`）⇒ 否则逐行 `NOINFO=对齐非Left(…)`；③ **行数不符** ⇒ 该行 `NOINFO=行数不符(真值行=X 我方行=Y)`（照 `Start` 列 `:1513` 的既有做法）。另加一条防御：**真值缺 `hasOverflowed`** ⇒ 该行 `NOINFO=真值缺 hasOverflowed`。 |
| **分母（纪律 39）** | 可判定集 = **`script==latin` 的 288 例 / 421 行**；**全域** 436 例 / 615 行；本列**只判 latin**（由既有覆盖闸给出，**一个字节未动**）。`hasOverflowed=True` 的真值 = **22 行 / 8 例**，**100% 在可判定集内**。 |
| **可点名计数器** | `TAB_LINES OVERFLOWED 红=<n> 绿=<m> 判定行=<k> NOINFO=<j> 红例=<e> NOINFO例=<f> 对齐=<Align> 真值True=<t> 诊断发丝边界行=<d> 量=… 真值=… 口径=…` + `TAB_LINES OVERFLOWED 对账 逐例求和 … ⇒ 与汇总一致/不一致` + 逐行 `TAB_LINES OVERFLOWED-RED <id> 行#k hasOverflowed 期望=… 实得=…` |
| **退出码** | 红 ⇒ 走**同一张** `--known-red` 表、**同一个** `failures` 通道（照 `#22` 的 `Start` 列）⇒ **未登记红必让 rc≠0**；**未自行改 `known-red.json`、未把红压成绿**。 |

### 1.2 为什么是"**只新增**"（机器证，不是声明）

1. **源级**：`diff -u` 后**删除行 = 0**（`grep -c '^-[^-]' program.diff` = **0**），**新增 109 行**，六个 hunk **全部**是"在某处之后插入"：
   `@@ -1314,6 +1314,32 @@`（列声明）、`@@ -1353,6 +1379,9 @@`（缺字形分支的 NOINFO）、`@@ -1386,6 +1415,9 @@`（抛异常分支的 NOINFO）、`@@ -1531,6 +1563,54 @@`（逐例比较 + 新计数变量）、`@@ -1559,6 +1639,21 @@`（汇总/对账/喂 rc）、`@@ -1587,6 +1682,20 @@`（新 helper `OverTruthCount`）。
2. **日志级（更硬）**：三支臂的**新日志剥掉全部 `^TAB_LINES OVERFLOWED` 行**之后，与 `#23` 的原始日志 **`cmp` 逐字节相同**：
   | 臂 | 剥掉新增行后的 sha16 | `#23` 原日志 sha16 | `cmp` |
   |---|---|---|---|
   | `tab-zero` | **`b9d81590f3fcd800`** | `b9d81590f3fcd800` | **IDENTICAL** |
   | `tab-anchor` | **`1a5bc7181d0155c3`** | `1a5bc7181d0155c3` | **IDENTICAL** |
   | `tab-rtl` | **`419e8aaa9c72a9a0`** | `419e8aaa9c72a9a0` | **IDENTICAL** |
   ⇒ **既有任何列/分桶/汇总/退出码口径都不可能是"改过的"** —— 它们的字节与 `#23` 完全一致（`diff` 的 `only-in-old = 0`、`new-not-OVERFLOWED = 0`）。
3. **退出码**：三支臂的 `TAB_LINES 退出码=` 行与 `#23` **逐字相同**（`0 / 0 / 1` —— `tab-zero` 那条 1 是既有的 `notab-control@w40@em24@RTL@tab0` 结构红，与 `#23` 一致，见 §7 门禁 `KNOWN_RED arm=tab-oracle-zero`）。

### 1.3 仪器变更披露（**纪律 40**）

| artifact | before | after | 字节 |
|---|---|---|---|
| `build/MilBridge/tests/CoverageProbe/Program.cs` | **`421fe394bea93fe2`**（116,496 B，mtime 09-16 19:44:36） | **`dea2a02cf8bab55a`**（125,908 B，mtime 09-17 09:32:34） | +9,412 |
| `.../bin/Release/PresentationCore.Tests.dll` | **`ec490a628beef3d5`** | **`1c112f42e9708638`** | —— |
| `build/shims/PresentationCore.HbTextLine.cs` | `e89fed55fd8e32bc` | **`e89fed55fd8e32bc`（未变）** | 290,825 B |
| 备份 | `$HOME/w24c-laneW24C/backup/Program.cs.before`（`421fe394bea93fe2`，`cp -p`） | —— | —— |
| 反极性构建产物（**均在 `$HOME`，树里零残留**） | —— | (a) `b81a463b4f2f2f8f`｜(b) `24978493a9a1ef8e`｜(c) `d99c41008023210e`｜(e) `ca3717695ccbe19a` | —— |

**⚠️ 下游读数因此改变**：三支 tab 臂的日志**新增行**（`tab-zero` **+88**、`tab-anchor` **+438**、`tab-rtl` **+86**，**`removed` 全为 0**）。**门禁读的是新日志，仍 `PASS`**（§7）。

---

## §2 计数器与逐例点名的对账（**与计数能对上**）

`tab-anchor`（修后绿跑）逐行现算复核对账（脚本现算，**不看任何汇总行**）：

```
TAB_LINES OVERFLOWED 红=0 绿=421 判定行=421 NOINFO=194 红例=0 NOINFO例=148 对齐=Left 真值True=22 诊断发丝边界行=58 量=我方 line.HasOverflowed 真值=lines[k].hasOverflowed 口径=盒原点+行宽 > 段落宽（**严格 >**，相等⇒false；无容差；布尔全等）
TAB_LINES OVERFLOWED 对账 逐例求和 红=0 绿=421 NOINFO=194 ⇒ 与汇总一致
```

| 对账项 | 逐例求和 | 汇总行 | 一致？ |
|---|---|---|---|
| 红 | **0** | 0 | ✅ |
| 绿 | **421** | 421 | ✅ |
| NOINFO | **194** | 194 | ✅ |
| 逐例行（436 条 `TAB_LINES OVERFLOWED <id> 行=…`） | 判定例 **288** + NOINFO 例 **148** = **436** | 语料 **436 例** | ✅ |
| 红明细行 `TAB_LINES OVERFLOWED-RED` | **0** 条 | 红 = 0 | ✅ |

**独立现算复核（python 直读语料，不经过本仪器）**：latin **421 行 / 288 例**；`hasOverflowed=True` **22 行 / 8 例**；`paragraphStartOffsetDip + width == paragraphWidthDip`（余量 ≤ 1e-6）**58 行 / 47 例**；真值侧规律 `paragraphStartOffsetDip + width > paragraphWidthDip` ⇒ **命中 22 / 假阳 0 / 漏 0**（与 W23D §2.3 的 615/615 现算一致，本件只在 latin 上复核）。

**反极性跑的对账（红例必须点名到例）**：

| 档 | 计数器 | `OVERFLOWED-RED` 明细行 | `TAB_LINES UNREGISTERED` 例级行 | 对账 |
|---|---|---|---|---|
| (a) `=>false` | `红=22 … 红例=8` | **22** | **8** | ✅ |
| (b) 错驱动量 | `红=79 … 红例=48` | **79** | **48** | ✅ |
| (c) `=>true` | `红=399 … 红例=280` | **399** | **280** | ✅ |
| (e) 去严格性 | `红=58 … 红例=47` | **58** | **47** | ✅ |
每档 `对账 逐例求和 … ⇒ 与汇总一致`。**rc 全部 = 1**（未登记失败 = 红例数）⇒ **rc 如实反映**。

---

## §3 修后读数 vs 预测

### 3.1 三支臂的修后读数（**门禁原命令形态**，`--known-red` **不给**，与 `#23` 的调用逐字一致）

命令（`build/MilBridge/arm-logs/README.md:15-17` 的形态；**绝对路径语料**）：
```
cd build/MilBridge/tests/CoverageProbe/bin/Release && dotnet PresentationCore.Tests.dll --tab-lines-oracle <$R>/tests/parity/windows/tab-<臂>/out/tab-<臂>-oracle.json
```

| 臂 | `TAB_LINES OVERFLOWED` 汇总 | rc | 判决 |
|---|---|---|---|
| `tab-anchor` | **红=0 绿=421 判定行=421 NOINFO=194 红例=0 NOINFO例=148 对齐=Left 真值True=22 诊断发丝边界行=58** | 0 | **绿（0 未登记红）** |
| `tab-zero` | 红=0 绿=0 **判定行=0** NOINFO=138 红例=0 NOINFO例=86 **对齐=NOINFO** 真值True=0 | 1（**既有**结构红 1 条，与 `#23` 同） | **全 NOINFO**（见 §9-1） |
| `tab-rtl` | 红=0 绿=0 **判定行=0** NOINFO=163 红例=0 NOINFO例=84 **对齐=NOINFO** 真值True=0 | 0 | **全 NOINFO**（见 §9-1） |

### 3.2 与预测的对照表

| 量 | 预登记/W23D 预测 | 本件实测 | 判 |
|---|---|---|---|
| 接线后红（latin 288 例 / 421 行） | **0 行 / 0 例** | **0 行 / 0 例** | ✅ **逐位兑现** |
| `hasOverflowed=True` 真值 | 22 行 / 8 例（全在可判定集内） | **22 行 / 8 例** | ✅ |
| 发丝边界行（latin） | 58 行 / 47 例（W23D §2.4(e)） | 诊断计数器 **58**；独立现算 **58 行 / 47 例** | ✅ |
| 真值侧规律 假阳/漏 | 0 / 0 | **0 / 0** | ✅ |
| 反极性 (a) | 22 / 8 | **22 / 8** | ✅ |
| 反极性 (b) | **89 / 54（全域）**、**79 / 48（latin）** | **79 / 48**（本臂只判 latin） | ✅（**但派单把全域数当成了本臂的预期数，见 §8-1**） |
| 反极性 (c) | 399 / 280（latin） | **399 / 280** | ✅ |
| 反极性 (e) | 58 / 47（latin） | **58 / 47** | ✅ |

---

## §4 反极性（**四档全部实测**）+ 复原证明

**方法**（照 `#22`/`#23` 的旋钮，**原地取**）：把一份**只改了 `HasOverflowed` getter** 的 shim 副本放 `$HOME/w24c-laneW24C/mut/`，用 `-p:HbShimSrc=<副本>` 构建 `CoverageProbe`。
**⛔ 树里的 `build/shims/**` 全程一个字节未动**（`e89fed55fd8e32bc` 在每一步前后复取，**全同**）。
**⚠️ 采用"原地构建"而非隔离输出路径** —— `W22B` §4 已实测隔离输出会拷进陈旧 `pc` 导致全 `NOINFO`；本件**每一步都断言 `bin/Release/PresentationCore.dll == 权威件`**：四次运行前该副本 **全部 = `7b47a7b3d69ad62f` = 权威**。

### 4.1 四档读数（逐字）

| 档 | 突变（只在 `$HOME` 副本里） | 副本 sha16 | 构建产物 dll | 读数 | rc |
|---|---|---|---|---|---|
| **(a)** | `HasOverflowed` ⇒ **恒 `false`**（`D-O1` 修前形态） | `82ee27cc9ad24d65` | `b81a463b4f2f2f8f` | **红=22 绿=399 判定行=421 NOINFO=194 红例=8** | **1** |
| **(b)** | **错驱动量**：`_startPenX + _width > W + 1e-9`（内容起点替盒原点） | `a8288ee52bdd9b28` | `24978493a9a1ef8e` | **红=79 绿=342 判定行=421 NOINFO=194 红例=48** | **1** |
| **(c)** | 恒 `true`（防"恒真"作弊） | `0e1284a3bea71b72` | `d99c41008023210e` | **红=399 绿=22 判定行=421 NOINFO=194 红例=280** | **1** |
| **(e)** | **去掉严格性**：`_boxOriginX + _width >= _paragraphWidth`（去掉 `+1e-9`） | `693d283aa0bdcf9f` | `ca3717695ccbe19a` | **红=58 绿=363 判定行=421 NOINFO=194 红例=47** | **1** |

每档的 `对账 逐例求和` 均 **⇒ 与汇总一致**，`退出码=1（未登记失败 N / 失败共 N）`，`N` = 红例数。

### 4.2 (a) 档逐字摘录（首选反极性）
```
TAB_LINES OVERFLOWED-RED B-indent-extra/lead-tab-a@w40@LTR@i24p24@default 行#0 hasOverflowed 期望=true 实得=false
TAB_LINES OVERFLOWED-RED B-indent-extra/lead-tab-a@w40@LTR@i24p24@default 行#1 hasOverflowed 期望=true 实得=false
TAB_LINES OVERFLOWED-RED B-indent-extra/lead-tab-a@w40@LTR@i24p24@tab0 行#0 hasOverflowed 期望=true 实得=false
```
8 个 `UNREGISTERED` 例级行 = `B-indent-extra/{lead-tab-a, lead-tab-b-t-c, mid-tab-a-t-b, notab-control}@w40@LTR@i24p24@{default,tab0}` ⇒ **与 §2 现算的 8 个真值 True 例完全同一批**。

### 4.3 (b) 档的方向
红行**全部**是 `期望=false 实得=true`（用内容起点做驱动量 ⇒ **假阳 79 行**），与 W23D §2.3 的"`perChar.x + width > W` 假阳性 89（全域）/latin 79"**同向同量**。

### 4.4 (e) 档 = **"严格 `>`"这条语义的活证据**
去掉 `+1e-9`（改成 `>=`）⇒ **红 58 行 / 47 例**，与 `诊断发丝边界行=58`**同一批量**（见 4.5）。⇒ 预登记 §3.2 那句"**必须写死严格 `>`**"在本仪器上**是可复现的机器事实**，不是告诫。

### 4.5 发丝边界诊断与 (e) 档的**独立交叉验证**
- 诊断计数器（修后绿跑，从**真值侧几何**现算）：`诊断发丝边界行=58`。
- 同一量的**独立 python 现算**（直读语料、不经仪器）：**58 行 / 47 例**，且这 58 行的真值 `hasOverflowed` **全为 `false`** ⇒ **"恰好到达边缘不算溢出"**。
- (e) 档（把 `>` 变 `>=`）实测红 = **58 行 / 47 例**。
⇒ **三处独立取值逐位相同** ⇒ 诊断计数器**确实**是这条边界的度量（不是装饰），且 **`>=` 的爆炸半径 = 58 行**（latin）。

### 4.6 复原证明（**三重**）
1. **树 shim 未动**：`sha256sum build/shims/PresentationCore.HbTextLine.cs` 在四档构建**每一步前后**均为 **`e89fed55fd8e32bc`**（与 `#23` 冻结值同）。
2. **构建复原**：末次 `dotnet build … -c Release -m:1`（**不带** `-p:HbShimSrc`）⇒ `PresentationCore.Tests.dll` = **`1c112f42e9708638`** = 本件绿跑的同一份产物（**逐位相同**）。
3. **功能复原**：复原构建后**重跑** `tab-anchor` ⇒ 日志 `sha16 = 56abc845dbd29e93`，与四档之前的绿跑日志 **`cmp` IDENTICAL**（另在 (a)(b) 之后再验一次，同样 IDENTICAL）。
⇒ **树里零残留**（临时态只存在于 `$HOME/w24c-laneW24C/mut/**`）。

---

## §5 既有判据行**逐字不动**的 `diff`/`cmp` 证据

（`#23` 原日志 = `$HOME/wfp-runs/arms23/*.log`，硬链接在 `#23` 波尾建立，**本件未触碰**；`sha256sum` 复核与 `#23` 记录一致。）

| 臂 | `#23` 行数 → 本件行数 | `diff` `only-in-old` | `diff` 新增里**非** `OVERFLOWED` 的行 | 剥掉新增行后 `cmp` |
|---|---|---|---|---|
| `tab-zero` | 121 → **209**（+88） | **0** | **0** | **IDENTICAL** |
| `tab-anchor` | 907 → **1345**（+438） | **0** | **0** | **IDENTICAL** |
| `tab-rtl` | 106 → **192**（+86） | **0** | **0** | **IDENTICAL** |

⇒ **本列是纯增量**：既有 `TAB_LINES CASE` / `START` / `START-RED` / `Q2` / `FAILCASE` / `合计` / `最大差` / `KNOWN-RED` / `UNREGISTERED` / `退出码` 每一行都**逐字节**与 `#23` 相同。

**四支无关臂**：`textlineproto.log` **`4bceceeed570ba70`**、`tline.log` **`57d752a3981a9b91`** —— sha16 **未变**，mtime（`00:38` / `00:36`）**未变** ⇒ **未重链、未触碰**。

---

## §6 三支臂的日志 sha16 与"只重链了哪几支"

**重链方式**：新日志先落 `$HOME/w24c-laneW24C/run/green/`，再 `ln -f <新日志> build/MilBridge/arm-logs/<臂名>.log`（**绝不 `cp`**：会顶 mtime 从而架空弱配对判据；**绝不 `ln -s`**：门禁 `find -type f` 会漏掉）。链接数 = **2**（现场 `ls -la` 确认）。

| 臂日志 | 旧 sha16（`#23`） | 新 sha16 | 字节 | mtime | 是否重链 |
|---|---|---|---|---|---|
| `arm-logs/tab-anchor.log` | `1a5bc7181d0155c3` | **`56abc845dbd29e93`** | 116,139 | 09:37:34 | ✅ **重链** |
| `arm-logs/tab-rtl.log` | `419e8aaa9c72a9a0` | **`5e4d9ef3c64f7d7e`** | 15,722 | 09:37:43 | ✅ **重链** |
| `arm-logs/tab-zero.log` | `b9d81590f3fcd800` | **`424d4c6d5ab121cb`** | 19,007 | 09:36:10 | ✅ **重链** |
| `arm-logs/textlineproto.log` | `4bceceeed570ba70` | `4bceceeed570ba70` | 7,926 | 00:38 | ❌ **未动** |
| `arm-logs/tline.log` | `57d752a3981a9b91` | `57d752a3981a9b91` | 21,501 | 00:36 | ❌ **未动** |

**我只跑了这三支 tab 臂**（各自对应 oracle json）；**没有**跑 `tline`/`textlineproto`（那是 `run.sh` 的长趟，本件射程外）⇒ **只重链了这三支**。

**运行前断言**（`#22` 踩过"陈旧副本"那一族）：`build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.dll` = **`7b47a7b3d69ad62f`** = `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`（**逐位相等**，构建后与每次运行前后都复取）。

---

## §7 门禁 / 九位 / `inputs_fp` / `pc`

**门禁**（`bash build/MilBridge/tools/tline-gate.sh --logdir build/MilBridge/arm-logs`，共跑 **4 趟**：`09:42:13` / `09:46:43` / `09:48:09` ×2）—— **结论行逐字相同**（仅 `outdir=` 的时间戳字段不同）；`09:48:09` 连跑的两趟输出**逐字节相同**（`sha16 = 204d379e7c029c40`，rc 均 **0**）：
```
TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2 outdir=/home/links-dev/wfp-runs/tline-gate-20260917-094643
GATE_REASON=all-as-registered
```
⇒ **`PASS` / `generation=#23` / `tree_gen=same` / `drift=0 gone=0 unregistered=0`** —— **逐条满足预登记 §3.3 与 §8 的硬要求**；**未出现未登记红**（`unregistered=0`）⇒ **不触发 §6 停条件第 6 条**，也**无需重钉** `known-red.json`（本件**未碰**它）。
在册红依旧 = 4 条（3× `tline` + 1× `tab-oracle-zero/notab-control@w40@em24@RTL@tab0`），**与新日志的既有判据状态逐位相容**（该例的 `结构=FAIL` 在剥掉新增行后逐字节等于 `#23`）。

**九位 + `inputs_fp`（现场脚本复算，纪律 49 不手抄）**：

| 位 | `#23` 冻结 | 本件收工现场 | |
|---|---|---|---|
| `bridge` | `d567c26f197ec1e3` | `d567c26f197ec1e3` | ✅ |
| **`pc`** | `7b47a7b3d69ad62f` | **`7b47a7b3d69ad62f`** | ✅ **本件全程未变**（每次构建与每次运行前后复取全同） |
| `pf` | `1c3fe23261c22bc6` | `1c3fe23261c22bc6` | ✅ |
| `windowsbase` | `1114a28ec5a03ab7` | `1114a28ec5a03ab7` | ✅ |
| `provider` | `9aa0d744802aaa31` | `9aa0d744802aaa31` | ✅ |
| `win32shim` | `0098234982391bbf` | `0098234982391bbf` | ✅ |
| `wic_shim` | `03b67fbcd7c385b6` | `03b67fbcd7c385b6` | ✅ |
| **`hbtextline`** | `e89fed55fd8e32bc` | **`e89fed55fd8e32bc`** | ✅ **未变 ⇒ 世代绑定不变** |
| `dwf` | `0ed422ef2dd46445` | `0ed422ef2dd46445` | ✅ |
| `BRIDGE_SRC_FP` | `b6acdba4f01599d8` | `b6acdba4f01599d8` | ✅ |
| **`inputs_fp`** | `6146f364…ccbca0ca` | **`6146f3641b87a5a7d74e182ab9ca3f6f72299377bbfce2993843cb56ccbca0ca`** | ✅ **逐位不变** |

⇒ **§5 表外位移：无**。（本件的预期位移 = 仪器 `Program.cs` + 其产物 dll + 三支 tab 臂日志；**九位与 `inputs_fp` 本就不含它们** ⇒ 与预登记 §5 相容。）**`pc` 是否变过 = 否**（这也是"预登记 §5 预测 `pc` 变"那一条**属 P1（W24A）**，本件测到的是"**尚未变**"，见 §8-2）。

---

## §8 我推翻 / 更正了哪句话（**如实写**）

1. **派单 §步2 的反极性第二档预测数**："错驱动量（用内容起点 `_startPenX + _width > W`）⇒ 预测红 **89 行 / 54 例**" —— **这是全域数，而本臂只判 `script==latin`**。本件实测 **79 行 / 48 例**，与 **W23D §2.4 表里那一格的 latin 列（79/48）**逐位吻合。⇒ **生效的预测数是 79/48**；写 89/54 会让人误判为"差 10 行"。**这是纪律 39 的又一次同族错法（分母混用），不是机制错。**
2. **预登记 §5 对本波 `pc` 的位移预测与本件无关**：本件读数期间 **`pc` 一次都没变**（始终 `7b47a7b3d69ad62f`）⇒ 那一格由 **P1（W24A）** 承载；**本件不构成表外位移**（如实记录"我测到的 `pc` 未变"）。
3. **一条新事实（W23D 未覆盖）**：`tab-zero-oracle.json` 与 `tab-rtl-oracle.json` **确实带 `hasOverflowed` 真值**（138 / 163 行，**但 True 为 0**，且**没有任何 `paragraphProperties` 段、没有 `script` 字段**）⇒ 这两支臂上本列**只能全 NOINFO**（`对齐=NOINFO`）。⇒ **本列的实际判别面只在 `tab-anchor` 一支臂上**；若将来想给 `hasOverflowed` 更大的判别力，W23D 指出的 `--tab-oracle`（U1 语料，36 例 `true`）那条路**更加值钱**，而它不仅缺"接线"，U1 语料的**对齐法律是否可读**也需先核（**本件 NOINFO**）。
4. **一处口径澄清（不是推翻，是把它变成机器事实）**：W23D §2.4 的风险带"58 个 latin 零余量行"—— 本件把它做成 `诊断发丝边界行=58`，并用 (e) 档实测证明**它的爆炸半径恰好是 58 行 / 47 例**。⇒ 该风险带**今天为 0 红**（我方 `width` 在那 58 行上**没有**比真值大 ≥1e-9），但**它确实只有 1e-9 的余量**，**任何**动 `_width`/`_boxOriginX`/钳位几何的修法都可能让它翻红 ⇒ **本列的判据说明必须连这句话一起读**。

---

## §9 `NOINFO` 清单（**一条都不许读成绿**）

| # | 项 | 状态 | 卡在哪 |
|---|---|---|---|
| 1 | `tab-zero` / `tab-rtl` 上的 `hasOverflowed` 判定 | **NOINFO（138 / 163 行）** | 两份语料**无 `paragraphProperties.fixed`** ⇒ 对齐法律读不出来 ⇒ 逐行 `NOINFO=对齐非Left(NOINFO)`（**不许发明**）；且其真值 `True` = **0 行**（就算能判也零判别力） |
| 2 | `branch ②`（`_startPenX >= _paragraphWidth`）的**单独**判别力 | **NOINFO** | 本语料 `Indent ≤ 24`、`W ≥ 40` ⇒ 该分支**不可行使**（W23D 已现算；本件未另测） |
| 3 | `branch ①`（`_paragraphWidth == 0`） | **NOINFO** | 本臂**恒喂非零 `pw`**（`:1325` 取语料 `paragraphWidthDip`，该档全 > 0）⇒ ① 在本仪器上不可达 |
| 4 | `TextAlignment ∈ {Right, Center, Justify}` | **NOINFO** | 语料 **436/436 全 `Left`**（与既有 `Start` 列同一条边界） |
| 5 | 产品路径（`PcLineOracle` / `TextFormatter`）上的 `HasOverflowed` | **NOINFO** | 本件只接"`--tab-lines-oracle` 源直调层"这一条链（`PcLineOracle/**` 是**别人的写域**，本件未碰）；⚠️ 且它同时是**折叠资格闸门**的输入（`shim:3582`）⇒ 本列**只读、不改**，按构造零位移 |
| 6 | RTL 半边 | **NOINFO** | 22 个真值 `true` 行**全 latin/LTR**；`tab-rtl` 那支**整支 NOINFO**（§9-1） |
| 7 | `--prefix 40` / `FrameProbe` 侧的消费者可见面 | **NOINFO** | 属 P2（W24B）射程，本件未跑 |
| 8 | 修**前**（`D-O1` 之前）的 `tab-anchor` 读数 | **NOINFO** | `#16` 前的 shim 无本列可用形态；本件用 (a) 档**等效重现**（恒 `false`）替代，**并标注那是等效、不是史实读数** |
| 9 | `--tab-oracle`（U1 语料，36 例 `true`）这条更高判别力的路 | **NOINFO** | 它**不在任何门里**（W23D 已证）；本件未接线、未读数 |
| 10 | 并发仪器的完整隔离 | **NOINFO** | 本件读数期间另有两条车道在跑 **`D5CbrProbe` 矩阵**（W24A，PID 415166/415895/415896）与 **`FrameProbe`**（W24B，PID 459978/461879）—— **不同仪器、不同被测件**；按纪律 48 记：**本件所有读数时刻见 §1.3 的 mtime**，**未与它们并发跑同一仪器** |

---

## §10 读数表（lane / 内存 / 时间 / 进程）

| 项 | 值 |
|---|---|
| **lane** | **W24C** |
| 起止（本地） | **2026-09-17 09:30:53 → 09:47 +0800** |
| `kernel` | `6.8.0-138-generic` |
| `nproc` | **3** |
| `loadavg` | 开工 **0.39 0.14 0.06**｜收工 **6.62 5.06 3.07**（区间 0.39–6.62，**本波另有两条车道在跑**） |
| **`MemAvailable`** | **开工 3,420,132 kB**（09:30:53）｜**最低（本件采样内）2,505,392 kB**（09:46:43）｜**收工 2,857,996 kB**（09:47:57）；构建边界处采样值 = 3,061,040 / 3,231,044 / 3,085,176 / 2,969,396 / 2,852,248 kB（**9 点采样，非连续采样 —— 如实记**）。**⚠️ 全部读数已含他车道负荷**（`D5CbrProbe` 矩阵 + `FrameProbe`）⇒ **不是本件单独的内存足迹**；本件**从未触发** `< 1,200 MB` 的等待/中止条件 |
| `MemTotal` / `SwapFree` | 8,113,356 kB / **977,148 → 968,188 kB**（**他车道负荷**；本件未观察到本件引起的 swap 抖动） |
| `dotnet` 内存纪律 | **所有** `dotnet` 命令均带 **`-m:1`** + **`DOTNET_gcServer=0`**；构建前自检 `MemAvailable ≥ 1,200,000 kB`（**每次均满足，0 次重试**）；**未** `dotnet build wpf-linux.sln`、**未** `verify-all`、**未**并发两个重构建、**未**重建 `PresentationCore` |
| `dotnet`/MSBuild 残留 | **本件 0 个**：收工 `dotnet build-server shutdown` ⇒ `成功关闭 MSBuild 服务器 / VB-C# 编译器服务器`，本件启动的 `VBCSCompiler`（PID **416210**）**已消失**；剩余 `dotnet` 进程（`FrameProbe` PID **494815**、`D5CbrProbe` PID **497228/498940** 及其 `bash` 父进程，父 PID **267343**）**全是 W24A/W24B 的**，**未触碰、未 `pkill`** |
| `DISPLAY` | `:97` = **UP**（开工与收工各验一次）；本件全程**未使用**（纯托管文本排版对 JSON） |
| 语料 | `tab-anchor-oracle.json`（436/615）、`tab-zero-oracle.json`（86/138）、`tab-rtl-oracle.json`（84/163）——**只读** |
| `pc`（开工/收工） | `7b47a7b3d69ad62f` / `7b47a7b3d69ad62f`（4,197,376 B） |
| `hbtextline`（开工/收工） | `e89fed55fd8e32bc` / `e89fed55fd8e32bc` |
| **本件写过的文件** | ① `build/MilBridge/tests/CoverageProbe/Program.cs`（**唯一**源码改动）；② 三支 `build/MilBridge/arm-logs/tab-{zero,anchor,rtl}.log`（**`ln -f` 重链**）；③ 本报告；④ `$HOME/w24c-laneW24C/**`（备份 / 变异副本 / 读数 / 日志） —— **`build/shims/**`、`known-red.json`、`tline-gate.sh`、`verify-all.sh`、`PcLineOracle/**`、`FrameProbe/**`、`wic-shim/**` 全部未碰** |
| 引用的既有 artifact sha16 | `#23` 臂日志 `1a5bc7181d0155c3`/`419e8aaa9c72a9a0`/`b9d81590f3fcd800`（= `$HOME/wfp-runs/arms23/`，本件只读）｜`known-red.json` `e623d2b17d948e3b`｜`CoverageProbe/known-red.txt` `e37603a8825d85ae`｜`tline-gate.sh` `b37a5c9f55ae71a4`（门禁自报 `gate=`）｜`README.md`（arm-logs）`:` —— 见现场 `ls` |
| 反极性留档（`$HOME/w24c-laneW24C/`） | `mut/HbTextLine.mut-{a-false,b-wrongdriver,c-true,e-geq}.cs`｜`run/red-{a,b,c-true,e-geq}/tab-anchor.log`（`1c4fc042c5cfec9a` / `9fd5367980e55632` / `f7463e66c8cb2429` / `0c843c05f4ec83cc`）｜`run/green/tab-*.log` + `.stripped`｜`run/restore/*`｜`run/gate.out`｜`backup/Program.cs.before` |
