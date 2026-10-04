# W20A —— `D-T6` **定性**：严格档腿那族 `行#1 i=0 取不到字符边界` = **臂/装置（读法口径）**，不是产品缺陷

> **lane = W20A**（纪律 32：谁跑的这趟 + 件 sha + 时刻）
> **时刻（开工）**：`2026-09-16 16:14:30 +0800`｜`uname -r = 6.8.0-138-generic`｜`loadavg = 0.47 0.23 0.60`｜`MemAvailable = 3,730,468 kB`（`free -m` 口径）
> **时刻（收尾）**：`2026-09-16 16:31:39 +0800`｜`uname -r = 6.8.0-138-generic`｜`loadavg = 2.13 1.74 1.30`｜`MemAvailable = 2,971,592 kB`
> **被测件（全趟逐位不变）**：`build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` = **`f4a454c8fe69cdfe`**，4,196,864 B，mtime `2026-09-16 15:40:28.680874 +0800`（`#19` 冻结产物）
> **写域**：`build/MilBridge/tests/PcLineOracle/**`（改了 `Program.cs`）、**新建**探针 `build/MilBridge/tests/StrictTierProbe/**`、本文件、`$HOME/wfp-runs/w20-laneW20A/`
> **未改**：`build/shims/**`、`build/MilBridge/run.sh`、`HbTextLineParity/Program.cs`、`known-red.json`、`tline-gate.sh`、`verify-all.sh`、`docs/**`、`samples/**`、`tests/**`、别的车道的 `TextLineProto*`/`HbTextLineParity*` csproj、任何 `build/*.Linux/**` 权威产物。**未跑 `verify-all.sh`**（那是主控收官步骤，本车道只取本项的读数）。
> **纪律 11**：未用 `pkill -f` / `pgrep -f`；全程无止损需求。

---

## 1. 判决（预登记要求三格之一）

> ## **`ARM/DEVICE`** —— 这族红是**臂的读法**造成的，不是产品的几何红。

**机制（一句话）**：`PcLineOracle` 读逐字 x 用的是 `line.GetTextBounds(j, 1)`，`j` 是**行内**下标；而 `GetTextBounds` 的第一个参数在**真机**上、以及**严格档**里，都是**段落系**下标 —— 该传 `cpFirst + j`。严格档交回的行**带段落系帧**（`HbTextLine._lineStart` = 段落系起点），于是第 2 行起 `localFirst = j − _lineStart < 0` ⇒ `GetTextBounds` 返回空 ⇒ 臂记 `NaN` ⇒ 失配词 `行#1 i=0 取不到字符边界`（第 1 行帧=0，所以恰好是"从 `行#1 i=0` 起"）。宽松档**把每一行重新起段**（`WpfLinuxLenientTextFallback.TryFormatLine` 从 `cpFirst` 重新收集并 `return lines[0]`）⇒ 交回的行帧**恒 0** ⇒ 行内下标**恰好**能用 ⇒ 这就是"跨档反极性"的全部来源。

**决定性读数的形态**（同一份 pc、同一条用例、只换档，`A-anchor/lat-a-t-b@w96@LTR@i0@default`）：

| 档 | 帧原点（逐行扫描） | `GetTextBounds(0,1)`（臂今天的口径）→ 第 2 行 | `GetTextBounds(cpFirst+0,1)`（**真机宿主**口径）→ 第 2 行 | 与真值 |
|---|---|---|---|---|
| **严格档** | `0,1,2` | `count=0`（**取不到**） | `count=1 X=0.000000 W=96.000000 trb[0]=1..2` | **Δ=0.000000** ✅ |
| 宽松档 | `0,0,0` | `count=1 X=0.000000 W=96.000000 trb[0]=0..1` | `count=1 X=96.000000 W=0.000000 trb[0]=1..1` | **Δ=+96.000000** ❌ |

⇒ 两档**交回的行逐位相同**（行数/Length/Width/可见文本全同），差别只在**帧**；而**哪一个帧是对的，有真机锚点**（§4）⇒ 严格档是对的，臂的读法是错的。

**另外推翻三条既有陈述**（§7）：① `缓存复用=18 例` **不是**严格档 `ParaCache` 的读数（那是**臂自己的测量缓存**）；② 预登记指望 `GetCharacterHitFromDistance(0)` 当判别量 —— 它是**欠账成员**，两档都返回常量 `CharacterHit(0,0)`，**零判别力**；③ "行起点映射不同 ⇒ 产品"这条**判据措辞**在本题上是陷阱（见 §4.2）。

---

## 2. 成员用例与精确命令

### 2.1 成员用例（≥3 条，覆盖"带缩进/零缩进"，全部取自本趟严格档腿的**实测**家族名单）

| # | id | `Indent` | `ParagraphIndent` | 真值行数 | 真值 `startChar` | 在本趟严格档腿的形态 |
|---|---|---|---|---|---|---|
| C1 | `A-anchor/lat-a-t-b@w96@LTR@i0@default` | 0 | 0 | 3 | `0,1,2` | 零缩进 · 未登记红（家族） |
| C2 | `B-indent/lead-tab-a@w40@LTR@i24@default` | 24 | 0 | 2 | `0,1` | 带缩进 · 未登记红（家族） |
| C3 | `D-paraindent/lead-tab-a@w100@LTR@i0p24@default` | 0 | 24 | 2 | `0,1` | 段落缩进 · 未登记红（家族） |
| C4 | `B-indent-extra/lead-tab-a@w40@LTR@i24p24@default` | 24 | 24 | 2 | `0,1` | 两者都有 · 未登记红（家族） |

（本趟严格档腿**实测**家族名单 = **67 条**：`A-anchor` 4 + `B-indent` 31 + `B-indent-extra` 24 + `D-paraindent` 8；另有 **7 条 `@tab0`** 同失配词但已登记。见 §8.3 的普查命令。）

### 2.2 决定性实验的命令

**探针（新建，`build/MilBridge/tests/StrictTierProbe/`；不判分，只 dump）**
```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"      # ⚠️ SDK 不在默认 PATH（rc=127 = 没跑）
dotnet build -m:1 -c Release build/MilBridge/tests/StrictTierProbe/StrictTierProbe.csproj   # 0 error
cd build/MilBridge/tests/StrictTierProbe/bin/Release
C=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json
dotnet PresentationCore.Tests.dll --corpus $C --case "A-anchor/lat-a-t-b@w96@LTR@i0@default" --tier strict
dotnet PresentationCore.Tests.dll --corpus $C --case "A-anchor/lat-a-t-b@w96@LTR@i0@default" --tier lenient
# 缓存专项（§5）：同一条命令 + --fresh-source
dotnet PresentationCore.Tests.dll --corpus $C --case "A-anchor/lat-a-t-b@w96@LTR@i0@default" --tier strict --fresh-source
```
**臂（`PcLineOracle`，加守卫后的形态）**
```bash
dotnet build -m:1 -c Release build/MilBridge/tests/PcLineOracle/PcLineOracle.csproj   # 0 error
cd build/MilBridge/tests/PcLineOracle/bin/Release
dotnet PresentationCore.Tests.dll --pc-lines-oracle $C --leg b --tier strict --guard label \
  --known-red $HOME/wfp-runs/w17-laneW17B/pc-line-oracle-known-red.txt
```
**`pc` 归因**（等号读者，W17C 的 `ShimShaReader`）：
```
SHIM_SHA=no reason=content-compare artifact=f4a454c8fe69cdfe artifact_bytes=4196864 … shim=fe1b7ed8fa3ed231
product_sha16=fe1b7ed8fa3ed231 tree_sha16=fe1b7ed8fa3ed231 asm=PresentationCore cmp=full64   rc=0
```
⇒ 本车道量的 `pc` 里编的 shim = **`fe1b7ed8fa3ed231`**（`#19` 修后那版），与**现树**逐位相同（`tree_gen=same`）。

---

## 3. 两档返回的行：逐行 dump 对拍（决定性实验 ①）

### 3.1 C1 `A-anchor/lat-a-t-b@w96@LTR@i0@default`（零缩进，3 行）

真值（语料）：`line0 startChar=0 len=1 w=13.346667 "a" x=0`｜`line1 startChar=1 len=1 w=96 "\t" x=0`｜`line2 startChar=2 len=2 w=13.346667 "b" x=0`

| | li | `cpFirst` | `type` | `Length` | `Width` | 可见文本 | **帧原点（扫描）** | `_lineStart`(反射) | `GetTextBounds(0,1)` 行内口径 | `GetTextBounds(cpFirst,1)` **段落系口径** |
|---|---|---|---|---|---|---|---|---|---|---|
| **严格** | 0 | 0 | `…HbTextLine` | 1 | 14.707031 | `a` | 0 | 0 | `count=1 X=0.000000 W=14.707031 trb[0]=0..1` | 同左 |
| **严格** | 1 | 1 | `…HbTextLine` | 1 | 96.000000 | `\t` | **1** | **1** | **`count=0`** ← 失配词的来源 | `count=1 X=0.000000 W=96.000000 trb[0]=1..2` |
| **严格** | 2 | 2 | `…HbTextLine` | 2 | 15.234375 | `b` | **2** | **2** | **`count=0`** | `count=1 X=0.000000 W=15.234375 trb[0]=2..3` |
| **宽松** | 0 | 0 | `…HbTextLine` | 1 | 14.707031 | `a` | 0 | 0 | `count=1 …` | 同左 |
| **宽松** | 1 | 1 | `…HbTextLine` | 1 | 96.000000 | `\t` | **0** | **0** | `count=1 X=0.000000 W=96.000000 trb[0]=0..1` | `count=1 X=96.000000 W=0.000000 trb[0]=1..1`（**错**） |
| **宽松** | 2 | 2 | `…HbTextLine` | 2 | 15.234375 | `b` | **0** | **0** | `count=1 …` | `count=0`（取不到） |

逐行总结（探针原文，`$HOME/wfp-runs/w20-laneW20A/probe/{strict,lenient}-A-anchor-lat-a-t-b/out.txt`）：
```
[strict]  PROBE SUMMARY 行指纹(li:Length:Width:vis)=0:1:14.707031:a|1:1:96.000000:\t|2:2:15.234375:b|
[strict]  PROBE SUMMARY 行类型=WpfLinux.Shims.PresentationCore.HbTextLine
[strict]  PROBE SUMMARY 帧原点(扫描)=0,1,2
[strict]  PROBE SUMMARY 逐字: 总字=3 行内读法取不到=2 段落系读法取不到=0 段落系 vs 真值 |Δ|>0.05 的字=0 Δmax=0.000000 @-
[lenient] PROBE SUMMARY 行指纹(li:Length:Width:vis)=0:1:14.707031:a|1:1:96.000000:\t|2:2:15.234375:b|
[lenient] PROBE SUMMARY 帧原点(扫描)=0,0,0
[lenient] PROBE SUMMARY 逐字: 总字=3 行内读法取不到=0 段落系读法取不到=1 段落系 vs 真值 |Δ|>0.05 的字=1 Δmax=96.000000 @li=1 j=0
```
⇒ **行指纹两档逐位相同**（`diff` 那两行：无差异）；`GetIndexedGlyphRuns()` 的段落系起点也随帧变化（严格 `[1+1] [2+1]` / 宽松 `[0+1] [0+1]`）。

### 3.2 C2/C3/C4（带缩进、段落缩进、两者都有）

| 用例 | 档 | 行指纹（li:Length:Width:vis） | 帧原点 | 行内读法取不到 | 段落系读法取不到 | 段落系 vs 真值 |
|---|---|---|---|---|---|---|
| C2 `B-indent/…@i24` | 严格 | `0:1:40.000000:\t\|1:2:38.707031:a` | `0,1` | **1** | 0 | **Δmax=0.000000** |
| C2 | 宽松 | **同上（逐位相同）** | `0,0` | 0 | 0 | **Δmax=14.707031**（错） |
| C3 `D-paraindent/…@i0p24` | 严格 | `0:1:76.000000:\t\|1:2:14.707031:a` | `0,1` | **1** | 0 | **Δmax=0.000000** |
| C3 | 宽松 | **同上** | `0,0` | 0 | 0 | **Δmax=14.707031**（错） |
| C4 `B-indent-extra/…@i24p24` | 严格 | `0:1:24.000000:\t\|1:2:38.707031:a` | `0,1` | **1** | 0 | **Δmax=0.000000** |
| C4 | 宽松 | **同上** | `0,0` | 0 | 0 | **Δmax=14.707031**（错） |

**四条用例、两种档、同一条规律**：行本身逐位相同；**帧**不同；**段落系读法**在严格档下**全字与真值 Δ=0**，在宽松档下**读错或读空**。

---

## 4. 判据结论（预登记 §1 的"决定性实验"判据）

### 4.1 判据的**前半句**成立：两档交回的行**逐位相同**

预登记原文（`docs/WAVE20-PREREGISTRATION.md:19`）：「若两档对同一条用例返回的 `List<HbTextLine>`（行数 / 每行长度 / 每行起点）**逐位相同**，而只有**严格档腿**的**读法**报错 ⇒ **臂/装置侧**」。
⇒ **行数 / 每行 `Length` / 每行 `Width` / 每行可见文本 / 行类型全部逐位相同**（§3），差别**只在**"该行的帧原点"。**而行起点（客户端口径）= `cpFirst` 两档也一样**（严格 `0,1,2`、宽松 `0,1,2`，见 §3.1 表格的 `cpFirst` 列）—— 不同的是**行对象内部记账的那个原点**。

### 4.2 判据的**后半句**需要真机锚点才能落地（本车道补上的就是它）

"行起点/`cpFirst` 映射不同 ⇒ 产品侧"这句话**默认**了"臂的读法即正确口径"。本题里这个默认**不成立**，因为真机 WPF 的口径**有实测锚点**：

| # | 锚点（文件 + 行 + 逐字原文） | 说明 |
|---|---|---|
| A1 | `tests/parity/windows/tab-anchor/src/Program.cs:504-514`（**产出本臂所用语料的那个 Windows oracle 宿主**）：`// NOTE: TextLine.Start is a DOUBLE distance …` ／ `int gi = lineStart + i;` ／ `IList<TextBounds> b = line.GetTextBounds(gi, 1);` | **真机宿主自己传的是 `lineStart + i` = 段落系下标**（`lineStart` 由客户端按 `Length` 累加） |
| A2 | `tests/parity/windows/layout-b34/src/LayoutOracle/Runner.cs:96`：`["GetTextBounds_firstArg"] = "段落系索引；传 0 只有行起点=0 的行有结果"` | 真机注解：**传 0 只有行起点=0 的行有结果** —— 与严格档逐位同形 |
| A3 | 同文件 `:395` 现场注释：`// ⚠️ GetTextBounds 的第一个参数是**段落系**（text source）索引，不是行内偏移。` ／ `// 第一版传 0，于是只有"行起点=0"的行拿得到 run 范围，其它行的 inner TextRunBounds 为 null。` | 真机上**已经栽过一次同样的坑**（第一版传 0） |
| A4 | `build/shims/PresentationCore.HbTextLine.cs:3020-3023`：`// ⭐ 真机口径（oracle indexFrames.GetTextBounds_firstArg）：第一个参数是**段落系**索引，` `// 不是行内偏移 …` `int localFirst = firstTextSourceCharacterIndex - _lineStart; if (localFirst < 0 …) return new List<TextBounds>();` | 严格档**按 A1/A2 实现**（如实：它这里是对的） |
| A5 | `build/PresentationCore.Linux/SimpleTextLine.Linux.cs:930-940`：`if (firstTextSourceCharacterIndex < _cpFirst) { … }` | 上游忠实移植版 `SimpleTextLine` **也是段落系**（`_cpFirst`）—— 独立于 shim 的第二份实现 |

**⇒ 严格档的帧 = 段落系（与真机一致，A1/A2/A5 三重旁证）；宽松档的帧 = 每行归零（与真机不一致）；臂的读法 = 行内（与真机不一致）。**
**⇒ `D-T6` 家族（严格档腿的位置红）= 臂的读法，`ARM/DEVICE`。**

### 4.3 交叉证据：真值自己的 `startChar` 就是客户端累加值

语料每条用例的每行都有 `startChar`（真机测的段落系起点）：C1 = `0,1,2`、C2/C3/C4 = `0,1`，与**臂的 `CpFirst`（按 `Length` 累加）逐位相同** ⇒ "客户端累加得到段落系索引"这条在真机上被语料**独立证实**，`cpFirst + j` 是**可复算**的、不是猜的。

### 4.4 跨档反极性（预登记 §1 实验 3 的复测）

- 严格档腿：C1 的 CASE 行 = `… 结构=PASS 位置=FAIL :: 行#1 i=0 取不到字符边界`（**出现**该词）。
- 宽松档腿：同一例 = `… 结构=PASS 位置=PASS`（**不出现**该词）。
- 两趟 `pc` 前=后=`f4a454c8fe69cdfe`；`--guard-off-lenient` / `--tier strict` 两趟 stderr 均 **0 字节**。
- **并且反极性是"翻转"的，不只是"消失"**：宽松档用**真机口径**反而读错（Δ=+96.000000 / 取不到），见 §3.1 表 —— 这比"该词不出现"更强，它说明**两档在帧这件事上互为反面**。

---

## 5. 缓存专项（决定性实验 ②）

预登记的怀疑（原文 `:15` / `:20`）：「严格档自己的 `ParaCache`（按 `(textSource, cpFirst)` 缓存）本趟报 `缓存复用=18 例`（首要怀疑方向，未验证）」；实验 = 「把严格档的 `ParaCache` 关掉（或让每例用**新的 `TextSource`** 使缓存必不命中）再跑同一条用例 ⇒ 若该失配词**消失** ⇒ 坐实 = 缓存键/命中与 `cpFirst` 的对应问题」。

**不碰 shim 的做法**：严格档缓存的命中条件是 `ReferenceEquals(c.Source, textSource) && c.Contains(cpFirst)`（shim `:4531-4536`）⇒ **每次 `FormatLine` 都新建 `TextSource`** 即可让它**必不命中**（探针的 `--fresh-source`）。

| 趟（C1，严格档） | 帧原点 | `cache` 内部整段行表（IVT `HbTextFallback.CacheInfo()`） | 行内读法取不到 | 段落系读法取不到 | 段落系 vs 真值 |
|---|---|---|---|---|---|
| 同一 `TextSource`（默认） | `0,1,2` | `cache=段起点0 行数3 总Length4` | **2** | 0 | Δmax=0.000000 |
| **`--fresh-source`** | **`0,0,0`** | `cache=段起点2 行数1 总Length2`（末次调用后只剩一行） | **0** | 1 | Δmax=96.000000（错） |

**读法**：
1. 缓存**确实是机制的一部分**：命中缓存 ⇒ 交回的行是"整段行表里的第 k 行" ⇒ 带**段落系帧**；不命中 ⇒ 每行**重新起段** ⇒ 帧归零 ⇒ 该词**消失**（正是预登记说的"消失"）。
2. **但这不是产品缺陷**：重新起段后的帧与真机口径**相反**（A1/A2），而缓存那条路给出的是**与真机一致**的帧 ⇒ 缓存是**保持正确帧**的一方。
3. ⇒ 预登记的怀疑方向**只对了一半**：与缓存相关的是"帧从哪来"，而红本身来自**臂的读法**（同一份数据的两种读法，§4）。

---

## 6. 守卫（臂侧）—— 把这一族**明确标成装置限制**，并保持既有判据一个字节不动

### 6.1 改动清单（`build/MilBridge/tests/PcLineOracle/Program.cs`）

| 文件 | sha16 **前** | 字节 | mtime 前 | sha16 **后** | 字节 | mtime 后 |
|---|---|---|---|---|---|---|
| `Program.cs` | **`a46e5e046583f69a`** | 72,948 | 2026-09-16 15:26:10.091 | **`19f9e7e78e9bb5c7`** | 90,087 | 2026-09-16 16:24:47.005 |
| `$HOME/wfp-runs/w20-laneW20A/backup/Program.cs.before`（`cp -p` 备份） | — | 72,948 | **保留原 mtime** 15:26:10.091 | `a46e5e046583f69a`（逐位 == 改前） | 72,948 | 同左 |
| 臂产物 `…/PcLineOracle/bin/Release/PresentationCore.Tests.dll` | `de25d3e0f8a00b00` | 45,568 | 2026-09-16 15:53:38（改前臂源 `a46e5e046583f69a` 的产物；重建 `-m:1 -c Release` **0 error** 且**未重编** ⇒ 同一个 sha，证明它确实对应那份源） | **`d3ae846a9a8b4717`** | 51,200 | 2026-09-16 16:27:58 |
| `PcLineOracle.csproj`（**未动**，自证） | `b0bf270206fe9c09` | 4,380 | 11:09:12 | 同左 | 同左 | 同左 |
| `PcLineOracle/known-red.txt`（**未动**，自证） | `89324f1f643167e5` | 17,501 | 12:00:16 | 同左 | 同左 | 同左 |

`diff -u` 规模：**13 个 hunk，`<` 0 行 / `>` 211 行**（纯增量：没有任何既有行被删改 —— 落盘 diff 在 `$HOME/wfp-runs/w20-laneW20A/arm.diff`）。

**一处歧义与我的取法（派单要求记录）**：派单要求"加一条能变红的守卫"且"保持既有判据一个字节不动"，但**两者对缺省行为是有张力的** —— 贴标签必然往 stdout 里**插新行**，于是**任何照 sha 比对我的臂输出的旧配方都会失配**。我取 **缺省 `label`（照做守卫）+ `--guard off` 作为逐字节退路**，理由：① 守卫不默认生效就等于没有守卫（"没人会记得加旗标"是本项目反复栽过的形态）；② 逐字节兼容可以用 `--guard off` **机器证明**（§8.5），而不是靠"我保证没动"；③ 副作用只落在**本臂自己的 stdout sha** 上（`PcLineOracle` **不是**五臂门禁成员、不进 `verify-all`，`W19B-report.md:417` 已明写）。**要旧 sha 的复跑者请加 `--guard off`。**

**新增的东西**（4 处）：
1. `--guard off|label|enforce`（**缺省 `label`**）+ `--guard-conv abs|line`（**缺省 `abs`**）；取值非法 ⇒ `NOINFO rc=2`（实测：`--guard bogus` ⇒ rc=2、93 B、`PCLINE_EXIT=NOINFO rc=2 原因=--guard 取值非法：bogus（只接受 off|label|enforce）`；`--guard-conv bogus` ⇒ rc=2、89 B、`… 原因=--guard-conv 取值非法：bogus（只接受 abs|line）`）。
2. `OurLine` 多两个字段：`CpFirst`（本行**段落系起点** = 客户端按 `Length` 累加值）、`LineRef`（`FormatLine` 交回的**行对象本身**；缓存克隆时一并带上，保证缓存命中的例也能重读）。
3. `GuardCase(...)`：对每一例**失配词含「取不到字符边界」**的用例，用真机口径**只读重读**（不重新驱动、不碰任何计数），逐例印
   `PCLINE GUARD <id> 装置限制=字符边界读法口径（**不是产品红**）｜失配词=…｜行帧（逐行扫描）=[…]｜旧读法…｜新读法（段落系 cpFirst+j）…｜重读字数=… 取不到=… |Δ|>容差=… Δmax=…`
   腿尾印 `PCLINE LEG=B 装置限制(读法口径) 判定=N 例 ｜贴标签=… 重读仍取不到=… 重读 |Δ|>容差=… 拿不到行对象=…`。
4. `--guard enforce` 的机器强制：标签前提不成立 ⇒ 逐例 `PCLINE GUARD FAIL …` + 收尾 `PCLINE_EXIT=GUARD_FAIL rc=3`；**一例家族例都没有** ⇒ `NOINFO rc=2`（"没输入"≠通过）。

**判据（守卫的前提，两极化）**：用真机同款 `GetTextBounds(cpFirst+j, 1)` 重读该例 ⇒ ① 每一行每一个字都**取到** `TextRunBounds`；② 与真值 `xFromLeftDip` 的 **|Δ| ≤ 0.05**（与既有判据同一把尺子）。两条都成立才贴标签；否则**拒绝贴标签**（`PCLINE GUARD FAIL`，`enforce` 时 `rc=3`）。

### 6.2 全语料读数（严格档腿，`--guard label`）

```
PCLINE LEG=B 装置限制(读法口径) 判定=74 例 ｜贴标签（重读全字取到且 |Δ|≤0.050000）=74 例；重读仍取不到字符边界=0 例；重读 |Δ|>容差=0 例；拿不到行对象=0 例 ｜模式=label 读法=abs ｜判据=真机宿主同款 `GetTextBounds(cpFirst+j,1)`（`tests/parity/windows/tab-anchor/src/Program.cs:512-514`）
PCLINE 未登记失败=67
PCLINE_EXIT rc=1（未登记失败 67 / 红 190 / 绿 98 / 不可比 148）
```
- **74** 例 = 全部家族例（67 条未登记 + 7 条已登记 `@tab0`），**全部**通过前提（0 例 FAIL）⇒ 这 67 条**确实**是读法造成的。
- 帧普查（`PCLINE GUARD` 行的"行帧"字段）：`[0,1]` 27 例、`[0,1,2]` 21 例、`[0,1,2,3]` 15 例、`[0,2]` 9 例、`[0,2,3]` 2 例 —— **每一例的第 1 行帧都是 0**（所以失配词恰好是"从 `行#1 i=0` 起"，而不是 `行#0`）。
- **`rc` 口径未变**：该腿仍 `rc=1`、`未登记失败=67`（守则不把已贴标签的例从"未登记失败"里摘掉 —— 摘掉就等于**改判据口径**，本波不许）。

### 6.3 守卫的**两极化证明**（能变红，不是橡皮图章）

| # | 命令（`--leg b`，同一语料/同一 `pc`） | 期望 | **实测** |
|---|---|---|---|
| P1 | `--tier strict --guard label`（全语料） | 贴标签、rc 不变 | **74 例贴标签 / 0 FAIL / rc=1**（§6.2） |
| P2 | `--tier strict --guard enforce --guard-conv line --case "A-anchor/lat-a-t-b@w96@LTR@i0@default"`（**故意用错的口径**） | 前提不成立 ⇒ 变红 | **`PCLINE GUARD FAIL`+`PCLINE_EXIT=GUARD_FAIL rc=3`**：`用「line」口径重读**仍然取不到**字符边界（2/3 字）` |
| P3 | `--tier lenient --guard enforce --case <同一例>`（**没有输入**） | 没输入 ≠ 通过 | **`NOINFO rc=2`**：`--guard enforce 但本腿**没有任何**「取不到字符边界」例（判定=0）⇒ 守卫**没有输入**，不是通过` |
| P4 | `--guard off`（两腿） | 逐字节退回 W20A 之前的基线 | 见 §6.4 |

⇒ 守卫的谓词是**可证伪**的（P2 把它打红），且**空集不许读成绿**（P3）；缺 P4 就论证不了"既有判据行没被动过"。

### 6.4 **既有判据行一个字节没动**（机器证明）

四条读数，全部 `pc` 跑前=跑后=`f4a454c8fe69cdfe`、`stderr` 0 字节：

| 趟 | 命令 | rc | stdout sha16 | 字节 |
|---|---|---|---|---|
| B0s | `--tier strict --guard off` | 1 | **`005f07dfeffd11bf`** | 134,332 |
| B0l | `--tier lenient --guard off` | 0 | **`a4cd321f5699cefc`** | 124,388 |
| Gs | `--tier strict --guard label`（**缺省**） | 1 | `d0d620fd5508f835` | 181,571 |
| Gl | `--tier lenient --guard label`（缺省） | 0 | `b3fea1f8f2814c18` | 125,457 |

**B0s/B0l 是"改动前臂（源 `a46e5e046583f69a`）"的读数**，即改后 `--guard off` 必须逐字节复现它们 —— 实测结果见 §8.5（`cmp` 逐字节）。另在改后 `--guard label` 的严格档腿上，把各类判据行**整类**抽出来与改前基线逐类 `diff`：

| 抽取的模式 | 改前行数 | 改后行数 | `diff` 行数 |
|---|---|---|---|
| `^PCLINE CASE` | 436 | 436 | **0** |
| `^PCLINE NAMED` | 6 | 6 | **0** |
| `^PCLINE TWIN` | 355 | 355 | **0** |
| `^PCLINE LEG=B 合计` | 1 | 1 | **0** |
| `^PCLINE 合计` / `分桶` / `孪生` / `最大差` | 1 / 1 / 1 / 1 | 同 | **0** |
| `^PCLINE [B]`（KNOWN-RED / UNREGISTERED 逐条裁定） | 190 | 190 | **0** |
| `^PCLINE 未登记失败` / `^PCLINE_EXIT` | 1 / 1 | 同 | **0** |

⇒ 新增的只有 `GuardSelect`（2 行）、`lane(edits)`（1 行）、`PCLINE GUARD`（74 行 + 腿尾 1 行）。

---

## 7. 我推翻/更正的既有陈述（撤诉优于辩护）

| # | 谁 | 原话（逐字） | 反证 | 处置 |
|---|---|---|---|---|
| R1 | `docs/WAVE20-PREREGISTRATION.md:15` + `handoff.md:2305` | 「严格档自己的 `ParaCache`（按 `(textSource, cpFirst)` 缓存）本趟报 **`缓存复用=18 例`**（首要怀疑方向）」 | `缓存复用=18 例` **不是** shim `ParaCache` 的读数：它是本臂**自己的测量缓存** `s_measCache`（源 `Program.cs` 的 `tCached` / `CachedMeasure{Tier}`，W19B 自己在 `W19B-report.md:89` 写明"命中测量缓存（同输入键）的例**不再驱动**…不带它，缓存命中的 18 例会变成两档皆 0 的假 NOINFO"）。严格档 `ParaCache` 的状态本臂**从来不印**，只能靠 IVT 的 `HbTextFallback.CacheInfo()` 读（本车道加了这一读法：`cache=段起点0 行数3 总Length4`） | 已更正：怀疑方向"与缓存相关"**部分成立**（§5），但那个 18 是**臂的**缓存，不是产品的 |
| R2 | 本波派单 §2 第 2 点 + 预登记 §1 实验 1 | 「dump … 以及 `GetCharacterHitFromDistance(0)` 的返回」作为判别量 | 它是 shim 的**欠账成员**：`PresentationCore.HbTextLine.cs:3696-3700` `public override CharacterHit GetCharacterHitFromDistance(double distance) { Owed("GetCharacterHitFromDistance"); return new CharacterHit(0, 0); }` ⇒ 两档都返回**常量** `FirstCharacterIndex=0 TrailingLength=0`（探针实测：严格/宽松**逐字相同**，`HbTextLineScaffold.HitCount(GetCharacterHitFromDistance)` 逐次 +1） | **零判别力**；本报告如实登记，不用它下结论（它属已登记的"光标/命中 5 个欠账"，不是 `D-T6`） |
| R3 | 预登记 §1 判据后半句 | 「若两档返回的**行本身**不同（尤其**行起点/`cpFirst` 映射**不同）⇒ **产品侧**」 | 本题两档的**行内容逐位相同**、`cpFirst`（客户端口径）也相同，**只有行对象的内部帧不同**；而**帧哪一个是真机口径**有 A1/A2/A5 三重锚点 ⇒ 严格档的帧**正确**。若照字面套这句话，会把一个**臂侧读法**错误判成产品缺陷 | 该判据措辞需补一句"谁是真机口径"；本车道按锚点落判 |
| R4 | `build/shims/PresentationCore.HbTextLine.cs:3390` 的注释 + `layout-b34` 的 `indexFrames.lineStart` | `public override double Start => 0;          // 真机实测恒为 0（3222/3222），不是段落内偏移` ／ `"TextLine.Start **恒为 0**（实测 3222/3222）"` | **本臂所用语料自己**：`lineStartOffsetsDip`（= 真机逐行 `line.Start`，`tab-anchor/src/Program.cs:445` `lineIndents.Add(R(line.Start));`）在 **171 行**（全部 `PI≠0` 用例）上是 **24 / 48 = `ParagraphIndent`**，在 **444 行**（`PI=0`）上是 0（§10 第 2 条）。即"恒为 0"只在 `PI=0` 的语料上成立 | **登记为新产品偏差**（§10.2），本波**不修**（要动 shim） |
| R5 | `W19B-report.md` §3.1 表格 | 「严格档接手=270 例、宽松档接手=0 例、缓存复用=18 例」中"缓存复用"的措辞 | 同 R1：是臂的测量缓存 | 措辞更正（数值本身没错） |

---

## 8. 读数表

### 8.1 环境与件（每人每趟）

| 量 | 值 |
|---|---|
| lane | **W20A** |
| 交付读数时刻 | `2026-09-16 16:28:07 +0800`（收尾），开工 `16:14:30 +0800` |
| kernel | `6.8.0-138-generic` |
| loadavg | 开工 `0.47 0.23 0.60`；收尾 `1.12 1.26 1.08`（每趟逐条见下） |
| MemAvailable | 开工 `3,730,468 kB`；收尾 `3,354,780 kB`（每趟逐条见下） |
| **被测件 `pc`** | **`f4a454c8fe69cdfe`**，4,196,864 B，mtime `2026-09-16 15:40:28.680874 +0800` |
| **`pc` 里编进去的 shim**（等号读者） | **`fe1b7ed8fa3ed231`**（`cmp=full64`，== **现树** `build/shims/PresentationCore.HbTextLine.cs` `fe1b7ed8fa3ed231`，278,692 B，15:30:15）⇒ `tree_gen=same` |
| 语料 | `tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json` = `a31a813114256faf`，1,251,441 B，2026-09-14 19:33:26 |
| 登记表（W17B 的 136 条） | `$HOME/wfp-runs/w17-laneW17B/pc-line-oracle-known-red.txt` = `89324f1f643167e5`，17,501 B |
| 臂源 / 产物 | `Program.cs` `a46e5e046583f69a`→`19f9e7e78e9bb5c7`；`PresentationCore.Tests.dll` `d3ae846a9a8b4717`（51,200 B，16:27:58） |
| 探针源 / 产物 | `StrictTierProbe/Program.cs` `d628ce429240b37c`（23,557 B）＋ `StrictTierProbe.csproj` `df646ce6a51864ff`（3,476 B）；产物 `a7e02c620d85d0d7` |

### 8.2 每一趟（`pc` 前→后 + rc + stdout sha16/字节 + loadavg/mem）

| 趟 | 档 / 旗标 | 时刻 | rc | stdout sha16 / 字节 | `pc` 前→后 | loadavg 前→后 | MemAvail 前→后 (kB) |
|---|---|---|---|---|---|---|---|
| `base-lenient` | lenient（改前臂） | 16:18:04→16:19:57 | 0 | `a4cd321f5699cefc` / 124,388 | 同 ✅ | 1.10→2.94 | 3,509,820→3,692,636 |
| `base-strict` | strict（改前臂） | 16:19:57→16:21:22 | 1 | `005f07dfeffd11bf` / 134,332 | 同 ✅ | 2.94→1.95 | 3,692,384→3,630,592 |
| `guard-off-lenient` | lenient `--guard off`（**中间版**，多 2 行头） | 16:22:43→16:24:33 | 0 | `3882cb0a47a1cd3a` / 125,100 | 同 ✅ | 1.13→1.25 | 3,578,440→3,743,904 |
| `guard-label-strict` | strict `--guard label` | 16:24:33→16:25:53 | 1 | `d0d620fd5508f835` / 181,571 | 同 ✅ | 1.25→1.23 | 3,743,652→3,536,588 |
| `guard-label-lenient` | lenient `--guard label` | 16:25:53→16:27:36 | 0 | `b3fea1f8f2814c18` / 125,457 | 同 ✅ | 1.23→1.22 | 3,536,820→3,535,248 |
| `guard-off-lenient-2` | lenient `--guard off`（**终版**） | 16:28:01→16:29:53 | 0 | **`a4cd321f5699cefc`** / 124,388 | 同 ✅ | 1.13→2.12 | 3,734,572→3,231,972 |
| `guard-off-strict-2` | strict `--guard off`（**终版**） | 16:29:53→16:31:35 | 1 | **`005f07dfeffd11bf`** / 134,332 | 同 ✅ | 2.12→2.13 | 3,231,972→2,971,592 |
| 探针 8 趟 + 控制 4 趟 | 见 §3/§5/§6.3 | 16:19–16:27 | 全 0（`guard-enforce-lenient` = 2） | 逐趟在 `$HOME/wfp-runs/w20-laneW20A/probe|smoke|*/` | 全部前=后 ✅ | — | — |

**全部 19 趟（6 趟整腿 + 3 趟 smoke + 9 趟探针 + 1 趟 `NOINFO` 控制）`pc` 全部跑前=跑后** ⇒ 每一次读数都可归因；除 `--guard enforce` 的两趟控制（`rc=3` / `NOINFO rc=2`）外，臂 rc 与改前一致。

### 8.3 本趟严格档腿的红分布（**改前臂**，`base-strict`）

```
PCLINE LEG=B 合计 cases=436 判定过=98 判定红=190 不可比(缺字形)=148（其中非0缩进 40、零缩进 108） 其中 bidi 重排例=2
PCLINE LEG=B 非0缩进: 红=127 绿=57 /224；零缩进: 红=63 绿=41 /212；PI≠0: 红=64 /112
PCLINE LEG=B 层级来源 请求档=strict 生效档=严格档(HbTextFallback) ｜ 严格档接手=270 例、宽松档接手=0 例、缓存复用=18 例（层级沿用同输入键的首趟）、非生效档接手=0 例、两档皆0=0 例
PCLINE 未登记失败=67
PCLINE_EXIT rc=1（未登记失败 67 / 红 190 / 绿 98 / 不可比 148）
```
- `位置=FAIL` = **121** = 74（失配词 `行#1 i=0 取不到字符边界`）+ 47（`width` 差）。前者/后者的 `@tab0` 归属：
```bash
grep -oE "位置=FAIL :: .*" stdout.txt | sort | uniq -c | sort -rn | head -3
# ⇒ 74 位置=FAIL :: 行#1 i=0 取不到字符边界
#    13 位置=FAIL :: 行#0 width 期望=26.696667 实得=109.347656 Δ=82.650989
#     9 位置=FAIL :: 行#0 width 期望=50.696667 实得=109.347656 Δ=58.650989
awk '/^PCLINE CASE \[B\] /{ if ($0 ~ /位置=FAIL/ && $0 !~ /取不到字符边界/) print ($0 ~ /@tab0/)?"tab0":"default" }' stdout.txt | sort | uniq -c
# ⇒ 47 tab0        （⇒ 121 = 74 + 47，且 47 条**全部**是 @tab0；与预登记的 「54 tab0 = 47 + 7」一致）
```
- 那 **74** 条按"是否 `@tab0` × 是否非零缩进"普查：
```bash
grep -c "位置=FAIL :: 行#1 i=0 取不到字符边界" stdout.txt          # ⇒ 74
awk '/^PCLINE CASE \[B\] /{ if ($0 ~ /取不到字符边界/) { tab=($0 ~ /@tab0/)?"tab0":"default"; nz=($0 ~ /非0缩进=1/)?"nz":"z"; print tab, nz } }' stdout.txt | sort | uniq -c
# ⇒ 48 default nz ｜ 19 default z ｜ 7 tab0 nz
grep "^PCLINE \[B\] UNREGISTERED" stdout.txt | sed 's/.*:: //' | sed 's/行#[0-9]* i=[0-9]* 取不到字符边界/取不到字符边界/' | sort | uniq -c
# ⇒ 67 取不到字符边界   （⇒ 74 − 67 = 7 条已登记 @tab0）
```
⇒ 与 `#19` 主控的普查**逐位吻合**：**67 条非 tab0 位置红、失配词完全相同**（48 带缩进 + 19 零缩进），另 54 条 `@tab0` 位置红。**本车道给这 67 条定性 = 装置（读法）。**

### 8.4 越界自查

`find build docs src samples tests -newermt "2026-09-16 16:14:00" -type f`（去 `bin/obj`）列出 **9** 个文件，属于**本车道写域**的只有 **3** 个：`build/MilBridge/tests/PcLineOracle/Program.cs`、`build/MilBridge/tests/StrictTierProbe/{Program.cs,StrictTierProbe.csproj}`；其余 6 个是别的车道/主控（`TextLineProto.csproj`、`HbTextLineParity.csproj`、`build/MilBridge/W20B-report.md`、`docs/CURRENT-STATE.md`、`docs/WAVE20-PREREGISTRATION.md`、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`）。
禁改件逐位未变：`build/shims/PresentationCore.HbTextLine.cs fe1b7ed8fa3ed231`、`run.sh 3e513e88a4fa4ec9`、`HbTextLineParity/Program.cs 2e458928fc1577c2`、`tline-gate.sh b37a5c9f55ae71a4`、`verify-all.sh a68823631e8f8919`、`CoverageProbe/Program.cs a8727a5bed6bf049`、`MinMaxProbe/Program.cs cfcf464457163280`、`tests/**`。
**`known-red.json` 本车道未碰**：现为 `3bf26e12f320dece`（29,546 B，15:46:02，**别人**在 `#19` 收官时改的；W19B 当时看到的是 `f9843bde351029dc`）—— **`D-T6` 的 67 条一条都没有登记进去**（"登记 ≠ 已容忍"，预登记 §1 明令）。

### 8.5 逐字节兼容的最终读数（**终版臂**，`--guard off`）

| 趟 | 命令 | rc | stdout sha16 / 字节 | 与改前基线 `cmp` |
|---|---|---|---|---|
| `guard-off-lenient-2` | `--tier lenient --guard off` | 0 | **`a4cd321f5699cefc`** / 124,388 | **`cmp` 逐字节相同**（`BYTE-IDENTICAL to base-lenient`） |
| `guard-off-strict-2` | `--tier strict --guard off` | 1 | **`005f07dfeffd11bf`** / 134,332 | **`cmp` 逐字节相同**（`BYTE-IDENTICAL to base-strict`） |

两条腿各自的 `pc` 前=后=`f4a454c8fe69cdfe`、`stderr` 0 字节。⇒ **"既有判据行一个字节没动"这句话是机器证明的**：终版臂加 `--guard off` 后，两条腿各自**逐字节**复现改动前臂（源 `a46e5e046583f69a`）的 stdout；缺省的 `--guard label` 只是在同一输出**中间插入**新行（§6.4 的整类 `diff` = 0）。

---

## 9. 我**没能**建立的东西（不许读成绿）

1. **产品侧"这一族永远不该出现"的证明**：本车道只证到"67 条家族红在真机口径下**几何全对**（74/74 全字 Δ≤0.05）"⇒ 它们不是几何红。**没有**证明"任何宿主在任何姿势下都不会读到空边界"（例如宿主真按行内下标问 `GetTextBounds` 时，产品会不会该给点东西 —— 真机 A3 的实测是**也给空**，所以按真机口径这**不是**缺陷）。
2. **宽松档丢帧这条（§10.1）在真机上的对照**：真机 A1 的宿主是**从 `cpFirst` 累加**、从不依赖行对象内部帧 ⇒ "行对象内部帧"在真机上**没有观测面**（真机 `TextLine` 是 LineServices 实现，外部只能按段落系下标问）。所以 §10.1 只能登记成"**我们两个档之间不一致，且严格档那一侧与真机锚点一致**"，**不能**说"真机也会这样"。
3. **`@tab0` 那 7 条**（同失配词、已登记）：本车道的守卫把它们**也**贴了装置限制标签（它们同时命中"帧"这一族）；但它们**另有** `DefaultIncrementalTab` 缺口（`#19` 已登记），**两件事叠在一起**，本车道**没有**把两者分开定量的读数。
4. **两档帧差异在渲染面（`Draw`）的影响**：本臂/探针只量几何（`GetTextBounds`/`Width`/`Start`），**没跑**像素或应用门禁 ⇒ 不知道该帧差异在屏幕上有没有可见后果。
5. **`SimpleTextLine` 快路径（腿 A）的帧**：腿 A 的零缩进首行会被上游快路径接走（不是同层对照），本车道**未测**。
6. **`verify-all.sh` / 五臂门禁 / 应用门禁**：本车道**未跑**（主控收官步骤；且本车道写域不许"每件事各自取一次读数"之外的东西）。本波是否 `tree_gen=same` 由主控的门禁趟给；本车道只给了"`pc` 里编的 shim == 现树"这一条。
7. **`TextLine.Start` 那条（§10.2）在严格档腿之外的形态**：只量了严格/宽松两档的 `HbTextLine`（都返回 0），**没量** `SimpleTextLine` 快路径（源码是 `_offset`，看起来是对的，但**未实测**）。
8. **家族在 `--leg a` 上的形态**：未跑。

---

## 10. 副产品（**射程外**的新发现：登记，本波**不修**）

这两条**都不是** `D-T6` 的定性结论，但都是本车道在取证路上**实测**到的、且**此前没有任何文档记载**的产品/装置偏差。按"红则停 + 登记不洗绿"处理。

### 10.1 `D-T6-b`（建议名）：**宽松档交回的行会丢段落帧**（帧恒 0）

- **读数**（同一 pc、同一条用例，§3.1）：宽松档 `帧原点(扫描)=0,0,0`，而真值 `startChar=0,1,2`；严格档 `0,1,2`。⇒ 宽松档第 2/3 行交回的 `HbTextLine` `_lineStart=0`，**它记的段落系起点不是真值那个**。
- **机制**：`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:242-264` —— `CollectLenient(textSource, cpFirst, …)` 从 `cpFirst` 重新收集文本、`FormatParagraph(text, …)`、`return lines[0]` ⇒ 每次调用都造一个"新段落"，`_lineStart` 因此从 0 起。
- **后果**：任何按**真机口径**（A1/A2：段落系下标）问 `GetTextBounds(cpFirst+j, 1)` 的宿主，在宽松档上会拿到**错的 x**（C1 第 2 行 Δ=**+96.000000**；C2/C3/C4 第 2 行 Δ=**+14.707031**）或**空**（C1 第 3 行 `count=0`）。
- **判据（给将来那一波）**：对这 4 条用例（及全语料），**两档**的"按 `cpFirst+j` 读出的逐字 x"都必须与真值 |Δ| ≤ 0.05；今天严格档 4/4 ✅、宽松档 0/4 ❌。
- **修法方向（不在本波）**：在 `TryFormatLine` 返回前把**段落系偏移**补回行对象（例如工厂按 `cpFirst` 平移 `_lineStart`／`GetIndexedGlyphRuns` 的起点，或让宽松档持有整段行表并按 `cpFirst` 取行）—— 要动 `build/PresentationCore.Linux/**` 或 shim ⇒ **另一波 + 世代成本**。
- **注意（不许夸大）**：真机**没有**"行对象内部帧"的观测面（§9.2）⇒ 这条只说明"我们两档互不一致，且严格档与真机锚点一致"，**不**说明真机会怎样。

### 10.2 `D-T6-c`（建议名）：`HbTextLine.Start` **恒为 0**，与语料真值在 **171 行**上不符

- **我们的实现**：`build/shims/PresentationCore.HbTextLine.cs:3390` `public override double Start => 0;          // 真机实测恒为 0（3222/3222），不是段落内偏移`（探针实测：C1–C4 全部 `Start=0.000000`，两档相同）。
- **真机真值（就在本臂用的语料里）**：`tests/parity/windows/tab-anchor/src/Program.cs:445` `lineIndents.Add(R(line.Start));` → 用例级 `["lineStartOffsetsDip"]`。普查（**原样命令与原样输出**）：
```bash
python3 -c "
import json,collections
d=json.load(open('tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json'))
c=collections.Counter(); ex={}
for x in d['cases']:
    for off in x['lineStartOffsetsDip']:
        c[(x['indentDip']!=0, x['paragraphIndentDip']!=0, off)] += 1
        ex.setdefault((x['indentDip']!=0,x['paragraphIndentDip']!=0,off), x['id'])
for k,v in sorted(c.items()): print('  ',k,v,ex[k])
"
# (I!=0, PI!=0, offset) -> 行数, 例
#    (False, False, 0) 277 A-anchor/lat-a-t-b@w96@LTR@i0@default
#    (False, True, 24) 71 B-indent-extra/lead-tab-a@w40@LTR@i0p24@default
#    (False, True, 48) 36 D-paraindent/lead-tab-a@w100@LTR@i0p48@default
#    (True, False, 0) 167 B-indent/lead-tab-a@w40@LTR@i24@default
#    (True, True, 24) 60 B-indent-extra/lead-tab-a@w40@LTR@i24p24@default
#    (True, True, 48) 4 D-paraindent/lead-tab-a@w220@LTR@i24p48@default
```
  ⇒ **`PI≠0` 的每一行**（71+36+60+4 = **171 行**）真机 `line.Start` = **`ParagraphIndent`（24/48）**；`PI=0` 的 444 行 = 0。
- **⇒ `Start => 0` 只在 `PI=0` 的语料上成立**；`layout-b34` 的"实测 3222/3222 恒为 0"显然是 `PI=0` 的语料（这也是`shim:3390` 注释的来源）。**独立旁证**：上游忠实移植版 `build/PresentationCore.Linux/SimpleTextLine.Linux.cs:1158-1161` `public override double Start { get { return _offset; } }` —— **不**硬编码 0。
- **判据（给将来那一波）**：全语料的逐行 `Start` 必须 == `lineStartOffsetsDip`（171 行 = PI、444 行 = 0），两档都要。
- **不要动它**：`Start` 会喂给宿主（`Line.cs` 的行原点），改动面比本项大得多；本波**只登记**。

---

## 11. 结论（对派单三格）

| 格 | 判定 |
|---|---|
| `ARM/DEVICE` | ✅ **本项** |
| `PRODUCT` | ❌（严格档这一族不是产品几何红：74/74 在真机口径下全字 Δ≤0.05、帧与真机锚点一致） |
| `UNDETERMINED` | ❌（缺的读数已补：两档行 dump、缓存专项、反极性、全语料 74 例的重读） |

**给下一波的两句话**：① 若要把这 67 条从严格档腿的"未登记失败"里**去掉**，正确做法是**修臂的读法**（改用 `cpFirst + j`，或按帧自适应），并**重新登记基线** —— 但那会**改动既有判据口径**，须主控批准；本波只**贴标签**、`rc` 口径一字不动。② `D-T6-b`（宽松档丢帧）与 `D-T6-c`（`Start` 恒 0）是**真产品偏差**，各需自己的两极化判据与波次。
