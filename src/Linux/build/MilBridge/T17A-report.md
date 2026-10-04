# `#17` 产物侧 shim 证据（**机械化 + 两极化红证**）—— 车道 **T17A**

> 件：`build/MilBridge/tools/shim-in-artifact.sh`（新，`e2e1a42b5f0e5b45`，16,612 B）
> 证据目录：`$HOME/wfp-runs/w17-laneA/evidence/`（仓外）
> 全部命令都是**只读**的；本报告里每条读数都带"哪一份件 + 怎么重跑"。
> 本次运行：**2026-09-15 18:43–18:48 (+0800)**｜`lane=T17A`｜kernel `6.8.0-138-generic`｜
> 运行时刻 `loadavg` 见 §6（`1.48 → 3.05`）｜`MemAvailable` **3076 → 3473 MB**｜
> 被测件 `pc c0763fc10173e7ff`（4,194,816 B，`2026-09-15 18:38:14.829263117 +0800`）｜
> shim `bc04c05ab6d8d82a`（275,765 B，`2026-09-15 18:25:25.142184898 +0800`）。

---

## 1. 结论（一行）

```
SHIM_IN_ARTIFACT=PASS artifact=c0763fc10173e7ff artifact_bytes=4194816 shim=bc04c05ab6d8d82a new=2/2 stable=14/14 missing=- recent=2/2 refs=23
```

⇒ **产物 `PresentationCore.dll`（`c0763fc10173e7ff`）里确实含有现树 shim（`bc04c05ab6d8d82a`）本版**新增**代码的标识符**（`_boxOriginX`/`boxOriginX`，23/23 个历史修订中一个都没有），且 14 个**长期**标识符全部在位。**rc=0**。
⇒ 反极性实测可红：同一脚本对三份更旧的 `PresentationCore.dll` 全部 `MISMATCH rc=1` 并**逐名点名**缺失 token（§5）。
⇒ 缺件/不可读/非托管 PE/根定不出 ⇒ **`NOINFO rc=2`**（不是绿）。

---

## 2. 这条检查**证明了什么** / **明确没有证明什么**

### 2.1 证明了（可复算）

| # | 命题 | 依据 |
|---|---|---|
| P1 | `c0763fc10173e7ff` 的托管元数据 `#Strings` 堆里**含有** `_boxOriginX` | `#Strings@0x2adbb0+0x18d9c = 0x2b694c` 处，UTF-8 字节出现 **1** 次；全文件也**只有**这 1 次（`grep -a -c -F _boxOriginX` = 1） |
| P2 | `_boxOriginX` 这个**标识符名字**在 `bc04c05ab6d8d82a` **之前**的所有 shim 修订里**不存在** | 23 份"真的是本 shim 的历史修订"的文件（`$HOME/t1d-backups/*.cs`，逐个按"≥100 KB ∧ 含 `class HbTextLine`"筛过）里 `absent_in_refs = 23/23` |
| P3 | 因此该产物**不可能**是"比 `bc04c05ab6d8d82a` 更旧的 shim 编出来的" | P1∧P2：旧修订没有这个名字可供 C# 编译器写进 `#Strings`（字段名必然进 `#Strings`）；只有 `≥` 该修订的源码才可能产生它 |
| P4 | 该产物**不是**任何一份"比 `bc04c05ab6d8d82a` 旧"的既存产物 | §5 的负极性：三份更旧的 DLL（含 `9adac6b8d8e285c3`、`684424fea3a0812a`、`530d76bd4327873e`）上同一检查全部 `MISMATCH` |
| P5 | 14 个长期标识符全在位 ⇒ 产物里**仍是同一个 `HbTextLine`/`HbShaper`/`HbFaceCache` 家族的代码**，不是"碰巧含两个新名字的别的程序集" | §3 表 STABLE 行，`absent_in_refs=0/23` |
| P6 | `ARTIFACT-SRC-FP.txt` 里那行 `file=bc04c05ab6d8d82a  build/shims/PresentationCore.HbTextLine.cs`（`ARTIFACT-SRC-FP.txt` = `f19778e90190abcf`，第 43 行）**不再是一条孤证** | 它答"源树里是哪个"，本检查答"产物里有没有这个源的代码"；两者现在**互相独立且同时成立** |

### 2.2 **没有**证明（不许读成绿）

| # | 未证明的事 | 为什么 | 现缺口 |
|---|---|---|---|
| N1 | **"产物 == 现树这一版的逐字内容"** | 只找到 **2 个** "仅现版新增"的 token（`_boxOriginX`/`boxOriginX`，同一处 D-O1 改动）。token 检查是**存在性**，不是**全等性**；本版其余改动（注释改写、`_startPenX` 语义注释）**不产生任何新符号** ⇒ 不可检 | 缺"内容哈希进产物"的仪器（见 §7-A） |
| N2 | **"产物里没有更晚的改动"** | `_boxOriginX` 在**将来**的修订里仍然存在 ⇒ PASS 只能读成"**≥ `bc04c05ab6d8d82a`**"，**不是"== `bc04c05ab6d8d82a`"** | 同 N1 |
| N3 | 编译用哪一份 `.cs` **文件名/路径** | 元数据不记源路径（记在 PDB）。本检查只能说"这些名字在"，不能说"来自 `build/shims/…` 那一份" | 见 §7-B（PDB checksum） |
| N4 | **注释**是否编进产物 | 实测：注释**根本不进**托管元数据（§4 对照：`行盒远缘` 在 `#Strings`/`#US`/全文件里命中 **0**）⇒ 任何"靠注释区分版本"的思路无效 | 无缺口，这是**结论**：本版 5 处改动里**只有带新符号的那 1 处可检出** |
| N5 | 方法**局部变量**名、`#if` 未定义分支的代码 | 实测：`penLine`（局部变量）作为 UNEMITTED 对照命中 **0**（局部名只进 PDB） | 见 §7-B |
| N6 | **STABLE token 的存在性本身几乎没有信息量** | 14 个 STABLE 在**所有** 23 份历史修订里都在 ⇒ 它们对"哪一版"**零分辨力**；只能用来否掉"产物是这个 DLL 家族的别的分支/已被整体替换" | 这是**明确声明的弱证据**，不参与"哪一版"的推断 |

---

## 3. Token 表 + 唯一性论证（每个 token 逐条）

**唯一性判据（脚本每次运行都自证，不自证就 `NOINFO rc=2`）**：
- `NEW`：现树出现 ≥1 次 ∧ 在 **23/23** 份历史修订里出现 **0** 次（`absent_in_refs == refs`）。
- `STABLE`：现树出现 ≥1 次 ∧ 历史修订里 **0 份**缺它（`absent == 0`）。
- `UNEMITTED`：在产物里的命中**必须 == 0**（否则判 `token-claim-invalid`）。
- 若某个 `NEW`/`STABLE` 的声明在参考集上不成立 ⇒ **脚本拒绝出结论**（我**实际撞到过**：第一版把 `HasOverflowed`/`_paragraphWidth`/`_width`/`TryGetGlyphTypeface` 标成 STABLE，被自检判 `NOINFO`——原因见下"参考集污染"）。

**参考集**：`$HOME/t1d-backups/*.cs`，共 **26** 个文件；其中 **3** 个**不是**本 shim 的修订（`20260914-2213-probe-before-rcfix.cs` 80,622 B、`20260915-1025-probe-before-armB.cs` 89,579 B、`20260915-1049-TextLineProto-before.cs` 19,561 B——都是**探针**的快照）⇒ 按"≥100 KB ∧ 含 `class HbTextLine`"剔除，**有效参考 = 23 份**。
> ⚠️ **这一条是现场抓出来的**：`HasOverflowed`/`TryGetGlyphTypeface` 在 `…TextLineProto-before.cs` 里缺（那个探针里没有这两个名字）、`_paragraphWidth`/`_width` 在那两份探针里也缺 ⇒ 若不过滤，`absent_in_refs` 会变成 1/26、3/26，**声明与事实不符**而脚本不会察觉。⇒ 现版本把"哪些文件算修订"变成**可审计的一条判据**并在 `--detail` 里逐条印出被跳过的文件与理由。

### 3.1 `NEW`（**当前修订新增**——判定的唯一有效信息源）

| token | 声明类别 | 现树 | 历史 23 份 | 编码 | 产物堆 | 堆内命中 | 全文件 ASCII 命中 | 堆内文件偏移 |
|---|---|---|---|---|---|---|---|---|
| `_boxOriginX` | 私有只读字段（D-O1 新增） | 4 | **absent 23/23** | UTF-8 | `#Strings` | **1** | 1 | `0x2b694c` |
| `boxOriginX` | 构造函数**形参**名（D-O1 新增） | 2 | **absent 23/23** | UTF-8 | `#Strings` | **1** | 1 | `0x2b694d` |

**为什么这两个的"唯一性"站得住**（逐条把话说清，不夸大）：
1. **证据边界 = 我们手上有的件**：这是**缺失前缀论证**（absence of evidence over a 23-revision prefix），**不是**"数学上只可能存在于这一版"。
2. **为什么缺失前缀在这里可信**：shim 的改动方式是**增量补丁**（`#16` 全程 12 轮都是 `+n/−m` 小 hunk，见 `WAVE16-PREREGISTRATION.md` §4.6.1），**没有发生过重写/revert-then-readd**；23 份修订**时间连续覆盖** `09-14 22:13 → 09-15 18:25`。
3. **为什么编译器一定写它**：`_boxOriginX` 是**字段**（不是局部变量）⇒ 字段名必然进 `#Strings`；`boxOriginX` 是**形参**名 ⇒ 进 Param 表并引用 `#Strings`。**两者都实测命中 1 次**（不是"应该会"）。
4. **为什么 `_boxOriginX` 不会撞车**：全文件字节搜索命中**恰好 1** 次，位置落在 `#Strings` 区间内（`0x2adbb0 ≤ 0x2b694c < 0x3171f4`）⇒ 不存在"别的堆/别的东西碰巧含这串"的可能。
5. **允许被推翻的方式（可证伪）**：① 若在更旧产物上找到 `_boxOriginX` ⇒ 本论证错（现已对 4 份旧产物实测为 0，见 §5）；② 若未来某版**删掉**该字段而产物仍含它 ⇒ PASS 失去意义（那时应换 token；脚本的自检会在"现树里没有该 token"时立刻 `NOINFO`，**不会**静默通过）。

### 3.2 `STABLE`（**长期存在**——弱证据，明确声明）

| token | 声明类别 | 现树 | 历史 23 份 | 堆 | 堆内命中 |
|---|---|---|---|---|---|
| `HbTextLineScaffold` | public static 类名 | 51 | 0/23 缺 | `#Strings` | 1 |
| `HbShaper` | internal static 类名 | 55 | 0/23 缺 | `#Strings` | 1 |
| `HasOverflowed` | public override 属性名（D-O1 重写的就是它） | 4 | 0/23 缺 | `#Strings` | 1 |
| `HbShapedRun` | internal sealed 类名 | 25 | 0/23 缺 | `#Strings` | 1 |
| `HbFontPlan` | internal sealed 类名 | 19 | 0/23 缺 | `#Strings` | 2 |
| `HbRunProperties` | internal sealed 类名 | 5 | 0/23 缺 | `#Strings` | 1 |
| `GetTextBounds` | 方法名 + 计数属性名 | 2 | 0/23 缺 | `#Strings` | 2 |
| `GetTextRunSpans` | 方法名 + 计数属性名 | 5 | 0/23 缺 | `#Strings` | 2 |
| `_paragraphWidth` | 私有只读字段（D-O1 分支读它） | 10 | 0/23 缺 | `#Strings` | 1 |
| `_width` | 私有只读字段（D-O1 分支读它） | 7 | 0/23 缺 | `#Strings` | 4 |
| `_keepState` | 私有只读字段（折叠闸门） | 5 | 0/23 缺 | `#Strings` | 1 |
| `_hasEop` | 私有只读字段 | 5 | 0/23 缺 | `#Strings` | 1 |
| `GlyphCount` | 标识符（亦是测试用例结构体字段） | 4 | 0/23 缺 | `#Strings` | **9** |
| `TryGetGlyphTypeface` | 标识符（亦出现在字面量里） | 7 | 0/23 缺 | `#Strings` | 1 |

> **弱证据声明**：这 14 条**全都在 23 份历史修订里**⇒**它们对"是哪一版"没有分辨力**。命中的意义只有两条：① 产物**属于这个家族**；② 反过来说，**如果连它们都缺**，那产物根本不是这个 DLL（见 §5 的失败形态诊断）。命中数 >1 的是**预期**（同名标识符在多个类/多个表里），**不是异常**。
> **被我否掉的一条**：`GlyphCount` 命中 9 次已核（多类同名 + 用例结构体字段），若把它当"唯一"来用会**假绿**——故它只在 STABLE 列。

### 3.3 `RECENT`（**新增但不是本版独有**——如实标注，不参与判定）

| token | 引入版本 | 历史缺它 | 编码 | 堆 | 本产物命中 | 全文件 ASCII 命中 |
|---|---|---|---|---|---|---|
| `[LIVEBLOBS] ` | `ac4104d67687c2c9`（12:26） | 10/23 | **UTF-16LE** | `#US` | 1 | **0** |
| `TryGetGlyphTypeface 失败（族 ` | D-F1b（`16db2d6194edc1f5` 起） | 0/23 | **UTF-16LE** | `#US` | 1 | **0** |

> ⚠️ 这两条**不能**用来判"是不是本版"（`LIVEBLOBS` 在 `#15`/`#16` 大半修订里都有）。它们的作用是**编码对照**：证明"字符串字面量只以 UTF-16LE 存在于 `#US`"，因此 **ASCII `strings`/`grep -a` 对它们必然漏检**（全文件 ASCII 命中 **0**）。
> **额外读数（很有用）**：`TryGetGlyphTypeface 失败（族 ` 在**文件时间更早**的 `t1c-16-build`（`530d76bd4327873e`，17:11）里**存在**，而 `[LIVEBLOBS] ` 在 `expA`（`9adac6b8d8e285c3`，10:58）与 `keydiag`（`684424fea3a0812a`，09-13）里**也**存在 ⇒ 该 token 集合里**只有 `_boxOriginX`/`boxOriginX` 有旧/新分辨力**，这与 §3.1 的结论一致（`neg-old-t1c16` 的 `recent=2/2`，另两份是 `recent=1/2`）。

### 3.4 `UNEMITTED`（**对照组**：证明"不进产物"的东西确实不进）

| token | 是什么 | 期望命中 | 实测（堆 / 全文件 ASCII） |
|---|---|---|---|
| `行盒远缘` | **注释**里的中文短语（现树 2 处，其中 1 处是 D-O1 新写的注释） | 0 | `#Strings` **0** / `#US` **0** / UTF-8 **0** / UTF-16LE **0** |
| `penLine` | **方法局部变量**名 | 0 | **0** / **0** |

> ⇒ 这两条是"**不许拿注释/局部名当版本证据**"的机器化对照（本项目 L10/L24 同族：`strings` 看不见 UTF-16、口径本身也会骗人）。若哪天它们变成非 0，脚本判 `token-claim-invalid` + `NOINFO`。

---

## 4. 机制：为什么"按堆找 UTF-8 / UTF-16 字节"是合法动作（**逐条实测，不是断言**）

### 4.1 `.NET 程序集 = PE 文件 + CLI 元数据根**（实测的偏移，来自本产物）

命令：`python3 $HOME/wfp-runs/w17-laneA/peheap.py build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`

```
== build/PresentationCore.Linux/bin/Debug/PresentationCore.dll size=4194816 root=0x19daac
   #~         off=0x0019db18 size=1114264   end=0x2adbb0 inside=True
   #Strings   off=0x002adbb0 size=431684    end=0x3171f4 inside=True
   #US        off=0x003171f4 size=308036    end=0x362538 inside=True
   #GUID      off=0x00362538 size=16        end=0x362548 inside=True
   #Blob      off=0x00362548 size=210652    end=0x395c24 inside=True
   #Strings blobs=22406
   #US entries=5119 first3=['wpfgfx_cor3.dll…','MILBRIDGE_MILCORE_SO…','MILBRIDGE_MILCORE_DIR…']
```

元数据根结构（**ECMA-335 II.24.2.1**）：`'BSJB' u16 major u16 minor u32 reserved u32 version_len version_string[…] u16 flags u16 nstreams` 然后是 `nstreams` 个 `u32 off(root 相对) u32 size name NUL →pad4`。
本产物实测：根 `0x19daac`、`version = v4.0.30319`（`version_len=12`）、`nstreams=5`。
⚠️ **一个我现场踩到的解析坑（写下来免得后人重踩）**：`version_string` 的 `version_len` **已经含尾部 padding**；若再自行 `align4` 一次，就会把流头起点算错 3 字节，从而读出"`nstreams=507`、堆偏移 3 GB"这类**看起来像真数据的垃圾**（我第一版就是这样，靠"堆区间必须落在文件内"这条断言才发现）。⇒ 本脚本对每个堆都要求 `off+size ≤ 文件大小`，否则 `NOINFO`。

### 4.2 三类东西各自的归宿（**这是选 token 的全部依据**）

| 源里的东西 | 进哪个堆 | 编码 | 本报告里的实测 |
|---|---|---|---|
| **字段名 / 类名 / 方法名 / 属性名 / 形参名**（标识符） | **`#Strings`** | UTF-8，NUL 分隔 | `_boxOriginX` @`0x2b694c`、`HbShaper` @`0x2f1bad`……命中 1 次/处 |
| **字符串字面量** | **`#US`** | **UTF-16LE**，前缀"压缩长度"（`#US` 是 `byte[]`，元素是 `char`） | `[LIVEBLOBS] ` 的 **UTF-16LE** 命中 1（@`0x3176ec`），**UTF-8 命中 0** |
| **方法体（IL）** | `#~`/`#Blob` | IL 里引用的是**元数据 token（4 字节索引）**，**不是名字** | ⇒ 方法体本身**没有名字可搜**；这也是为什么本检查只能靠"名字",不能靠"代码形状" |
| **注释** | **哪儿都不进** | —— | `行盒远缘`：`#Strings` 0 / `#US` 0 / UTF-8 全文件 0 / UTF-16LE 全文件 0 |
| **局部变量名** | 只进 **PDB** | —— | `penLine`：0/0 |

### 4.3 为什么"字节级 `grep -a` / `strings`"在这两类 token 上合法，以及它的**两个已知盲区**

**合法的理由**：元数据堆是**按原样存进文件**的（不进 PE 节、不压缩、不加密、不做名字混淆）⇒ ASCII 标识符在文件里就是它的 ASCII 字节；字符串字面量在文件里就是它的 UTF-16LE 字节。**实测验证了这一点**：所有 `#Strings` 命中都落在 `#Strings` 的文件区间内（用 `--detail` 的 `heap` + `file_off` 两列可直接核），全文件计数与堆内计数相等（`file_ascii_hits` 列）⇒ **不存在"在别的堆里碰巧命中"的假阳性**。

**盲区一（本项目 L10 的老账）**：**ASCII `strings` 看不见 UTF-16**。实测：`[LIVEBLOBS] ` 在产物里 UTF-16LE 命中 1、ASCII 命中 **0** ⇒ 谁要是用 `strings dll | grep LIVEBLOBS` 来"复核"这条检查，会得到**假红**。
**盲区二**：**中文（非 ASCII）token 必须按 UTF-16LE 搜**（若在字面量里）或**根本搜不到**（若在注释里）。本脚本对 `enc=utf16` 的 token 一律搜 UTF-16LE，对注释/局部名一律**期望 0**。

**结论**：本检查的 token 全部落在 `#Strings`(UTF-8) 与 `#US`(UTF-16LE) 两个堆里，**两种编码都显式指定**；"全文件字节搜索"只作为交叉证（`file_ascii_hits` 列），**不是**判据本身。

---

## 5. 两极化证据（**精确命令 + 精确输出 + `rc`**）

脚本：`S=build/MilBridge/tools/shim-in-artifact.sh`（`e2e1a42b5f0e5b45`）。全部命令在仓根运行；输出原样贴。证据文件在 `$HOME/wfp-runs/w17-laneA/evidence/`（含 sha16）。

### 5.1 正极性 —— 现树产物

```
$ bash build/MilBridge/tools/shim-in-artifact.sh
SHIM_IN_ARTIFACT=PASS artifact=c0763fc10173e7ff artifact_bytes=4194816 shim=bc04c05ab6d8d82a new=2/2 stable=14/14 missing=- recent=2/2 refs=23
rc=0
```
逐 token 版（`--detail`，完整输出见 `evidence/pos-current-detail.out`，`3abbe4a5b38160b6`；机器行 = `evidence/pos-current.out`，`de30dd018abf0899`）：
```
# token                               bucket     enc    src_occ  absent_in_refs  heap        heap_hits  file_ascii_hits  file_off
# _boxOriginX                         NEW        utf8   4        23/23           #Strings    1          1                0x2b694c
# boxOriginX                          NEW        utf8   2        23/23           #Strings    1          1                0x2b694d
# HbTextLineScaffold                  STABLE     utf8   51       0/23            #Strings    1          1                0x2c2f12
# …（14 条 STABLE 全 0/23）…
# [LIVEBLOBS]                         RECENT     utf16  1        10/23           #US         1          0                0x3176ec
# TryGetGlyphTypeface 失败（族            RECENT     utf16  1        0/23            #US         1          0                0x3190d3
# 行盒远缘                                UNEMITTED  utf16  2        0/23            #US         0          0                -
# penLine                             UNEMITTED  utf8   4        22/23           #Strings    0          0                -
# heaps: #Strings@0x2adbb0(431684) #US@0x3171f4(308036)
# reference revisions used for the uniqueness argument: 23 (skipped: 3 …)
# control: '行盒远缘' heap_hits=0 file_ascii_hits=0
# control: 'penLine'  heap_hits=0 file_ascii_hits=0
```

### 5.2 **负极性 A（关键）** —— 更旧的产物 ⇒ 必须红，并点名缺谁

```
$ bash build/MilBridge/tools/shim-in-artifact.sh --artifact "$HOME/wfp-runs/expA/bin/Release/net10.0/PresentationCore.dll"
SHIM_IN_ARTIFACT=MISMATCH artifact=9adac6b8d8e285c3 artifact_bytes=4188672 shim=bc04c05ab6d8d82a new=0/2 stable=14/14 missing=_boxOriginX,boxOriginX recent=1/2 refs=23
rc=1
```
**"红得对"的三条佐证**（同一份旧件上逐条复算，`--detail` 全文 = `evidence/neg-old-expA-detail.out`，`a4c4d68f0c8e859d`）：
- `_boxOriginX` 堆内命中 **0**、全文件 0；`boxOriginX` 同样 **0** ⇒ 缺失**就是**"这两个符号不存在"；
- 14 条 STABLE **全部在位**（`heap_hits=1/2/4/9…`）⇒ 红**不是**因为"读了个别的文件"；
- `[LIVEBLOBS] ` 也缺（`recent=1/2`）⇒ 与"该件是 `#15` 时代产物"一致（可交叉验证时间序）。

```
$ bash build/MilBridge/tools/shim-in-artifact.sh --artifact "$HOME/wfp-runs/diag-keydiag/PresentationCore.dll"
SHIM_IN_ARTIFACT=MISMATCH artifact=684424fea3a0812a artifact_bytes=4169728 shim=bc04c05ab6d8d82a new=0/2 stable=14/14 missing=_boxOriginX,boxOriginX recent=1/2 refs=23
rc=1

$ bash build/MilBridge/tools/shim-in-artifact.sh --artifact "$HOME/t1c-16-build/bin/Debug/PresentationCore.dll"
SHIM_IN_ARTIFACT=MISMATCH artifact=530d76bd4327873e artifact_bytes=4194304 shim=bc04c05ab6d8d82a new=0/2 stable=14/14 missing=_boxOriginX,boxOriginX recent=2/2 refs=23
rc=1
```
> 三份被比对的旧件**都是仓外的既存副本**（不是我在 scratch 里造的）：`$HOME/wfp-runs/expA/bin/Release/net10.0/PresentationCore.dll`（09-15 10:58，`pc` 曾用值 `9adac6b8d8e285c3`）、`$HOME/wfp-runs/diag-keydiag/PresentationCore.dll`（09-13 15:59）、`$HOME/t1c-16-build/bin/Debug/PresentationCore.dll`（09-15 17:11）。**没有覆盖、没有删除任何件**。

### 5.3 `NOINFO` / `rc=2`（真缺件、真读不了 ⇒ **不许报绿**）

```
$ bash $S --artifact "$HOME/wfp-runs/w17-laneA/does-not-exist.dll"
SHIM_IN_ARTIFACT=NOINFO reason=artifact-not-found path=/home/links-dev/wfp-runs/w17-laneA/does-not-exist.dll
rc=2

$ bash $S --artifact "$HOME/wfp-runs/w17-laneA"            # 路径存在但是目录
SHIM_IN_ARTIFACT=NOINFO reason=artifact-not-found path=/home/links-dev/wfp-runs/w17-laneA
rc=2

$ bash $S --artifact /etc/hostname
SHIM_IN_ARTIFACT=NOINFO reason=not-a-managed-pe path=/etc/hostname (no usable BSJB metadata root)
rc=2

$ head -c 65536 build/PresentationCore.Linux/bin/Debug/PresentationCore.dll > $HOME/wfp-runs/w17-laneA/truncated-PresentationCore.dll
$ bash $S --artifact "$HOME/wfp-runs/w17-laneA/truncated-PresentationCore.dll"
SHIM_IN_ARTIFACT=NOINFO reason=not-a-managed-pe path=/home/links-dev/wfp-runs/w17-laneA/truncated-PresentationCore.dll (no usable BSJB metadata root)
rc=2

$ bash $S --shim "$HOME/wfp-runs/w17-laneA/nope.cs"
SHIM_IN_ARTIFACT=NOINFO reason=shim-not-found path=/home/links-dev/wfp-runs/w17-laneA/nope.cs
rc=2

$ cp $S $HOME/wfp-runs/w17-laneA/shim-in-artifact-copy.sh && (cd / && env -u WPF_LINUX_ROOT bash $HOME/wfp-runs/w17-laneA/shim-in-artifact-copy.sh)
SHIM_IN_ARTIFACT=NOINFO reason=root-unresolved (script=/home/links-dev/wfp-runs/w17-laneA --root='' cwd=/)
rc=2
```
> **"脚本不会静默跳过"的正面证据（本项目 L25/纪律 27 的老账）**：`NOINFO` 行**逐条带 reason**，且**退出码非 0**；`PASS` 行里同时印出 `new=2/2 stable=14/14 refs=23` ⇒ **零检查不可能印成 PASS**。第一版脚本里 "`token-claim-invalid`" 这条自检**真的触发过**（§3 的参考集污染），它把一次**本该假绿**的运行变成 `rc=2` —— 这是"自检不是装饰"的现场证据。

### 5.4 三次运行同一件 ⇒ **机器行逐字节相同**（可重复性）

```
$ for i in 1 2; do bash $S > evidence/pos-current.out.$i; done
$ sha256sum evidence/pos-current.out.1 evidence/pos-current.out.2 | cut -c1-16
de30dd018abf0899
de30dd018abf0899
$ cmp evidence/pos-current.out.1 evidence/pos-current.out.2 && echo IDENTICAL
IDENTICAL
```
> **口径说明**：机器行里**不含 mtime、不含时间戳**（只有 sha16/字节数/计数/名字），所以重复运行逐字节相同。`--detail` 里的 `mtime=` 是**秒级整数**且只在 `--detail` 出现，不影响机器行；`--detail` 输出亦已实测 `cmp` 两次运行相同（`pos-current-detail.out` vs `pos-current-detail.2.out` ⇒ IDENTICAL）。
> ⚠️ **读数来源声明**：§5 的全部输出取自**最终版脚本 `e2e1a42b5f0e5b45`**（16,612 B，mtime `18:47:20`）。18:43 的第一趟跑的是一份**更早的中间版本**，**不作为证据**（它连 `token-claim-invalid` 自检都还没跑过）。

### 5.5 只读证明（脚本没写任何东西）

```
$ A=$(sha256sum build/PresentationCore.Linux/bin/Debug/PresentationCore.dll build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt build/shims/PresentationCore.HbTextLine.cs | cut -c1-16 | tr '\n' ' ')
$ bash $S >/dev/null; bash $S --detail >/dev/null
$ B=$(sha256sum … 同上 …)
before: c0763fc10173e7ff f19778e90190abcf bc04c05ab6d8d82a
after : c0763fc10173e7ff f19778e90190abcf bc04c05ab6d8d82a
IDENTICAL: script wrote nothing to those files
files modified in the last 120 seconds under build/PresentationCore.Linux/{bin,obj} and build/shims: 0
```
（另：`build/MilBridge/tools/**` 下只**新增**了本脚本一个文件，未改动同目录任何既存文件——`tline-gate.sh` 属 T1b3 写域，本车道**只读**它，纪律 31 的世代绑定因此不受影响：本脚本**不在**门禁的三项仪器 sha 之内。）

---

## 6. 读数表（**每一格都带"哪一份件"**）

| 项 | 值 | 命令 |
|---|---|---|
| lane | **T17A** | —— |
| 日期时间（本次运行） | **2026-09-15 18:43:29 → 18:48:08 (+0800)** | `date -Is` |
| 内核 | `6.8.0-138-generic` | `uname -r` |
| `loadavg`（起点 / 终点） | `1.48 2.04 1.67` / `3.05 2.10 1.74` | `cat /proc/loadavg` |
| `MemAvailable`（起点 / 终点） | **3076 MB** / **3473 MB**（总 7923 MB） | `free -m` |
| 被测产物 `pc` | **`c0763fc10173e7ff`**（4,194,816 B；`2026-09-15 18:38:14.829263117 +0800`） | `sha256sum … \| cut -c1-16`、`stat -c '%y %s'` |
| shim 源 | **`bc04c05ab6d8d82a`**（275,765 B；`2026-09-15 18:25:25.142184898 +0800`） | 同上 |
| `ARTIFACT-SRC-FP.txt` | `f19778e90190abcf`（4,443 B；`18:39:14`），第 43 行 `file=bc04c05ab6d8d82a  build/shims/PresentationCore.HbTextLine.cs` | `grep -n HbTextLine …` |
| 本脚本 | `build/MilBridge/tools/shim-in-artifact.sh` = **`e2e1a42b5f0e5b45`**（16,612 B；`2026-09-15 18:47:20`） | `sha256sum` |
| 证据·正极性机器行 | `evidence/pos-current.out` = `de30dd018abf0899` | 运行 2 次逐字节相同（§5.4） |
| 证据·正极性明细 | `evidence/pos-current-detail.out` = `3abbe4a5b38160b6` | `--detail` |
| 证据·负极性明细 | `evidence/neg-old-expA-detail.out` = `a4c4d68f0c8e859d`（`rc=1`） | `--artifact … --detail` |
| 参考修订集 | `$HOME/t1d-backups/`：26 个 `.cs`，**有效 23**，跳过 3（探针：`…probe-before-rcfix.cs`、`…probe-before-armB.cs`、`…TextLineProto-before.cs`） | `--detail` 末段逐条印出 |
| 旧产物（负极性用） | `9adac6b8d8e285c3`（4,188,672 B）/ `684424fea3a0812a`（4,169,728 B）/ `530d76bd4327873e`（4,194,304 B） | `sha256sum` |

**复算入口（把这四条贴进 shell 就能重来）**：

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
bash build/MilBridge/tools/shim-in-artifact.sh --detail                     # 期望 PASS rc=0
bash build/MilBridge/tools/shim-in-artifact.sh --artifact "$HOME/wfp-runs/expA/bin/Release/net10.0/PresentationCore.dll"   # 期望 MISMATCH rc=1
python3 "$HOME/wfp-runs/w17-laneA/peheap.py" build/PresentationCore.Linux/bin/Debug/PresentationCore.dll                   # 堆偏移
sha256sum build/MilBridge/tools/shim-in-artifact.sh | cut -c1-16            # e2e1a42b5f0e5b45
```

---

## 7. 仍然没做到的 / 未来仪器需要什么

**A（最重要）：缺"产物内容 = 源内容"的**全等**证据。**
现状只能给**下界**（"≥ `bc04c05ab6d8d82a`"），因为 `#16` 这一版的 5 处改动里**只有 1 处产生新符号**（D-O1 的 `_boxOriginX`/`boxOriginX`），其余是**注释改写**（`_startPenX` 语义注释改正）与**已有符号内的逻辑变化**——**注释不进元数据**（§4.2 实测），**逻辑变化不改变名字**。
⇒ 需要的仪器（**两条独立路线，任一条都能把"下界"变成"等号"**）：
1. **`[assembly: AssemblyMetadata("HbTextLineShimSha", "<sha16>")]`**：T1c 的备稿（`$HOME/wfp-runs/draft-shimsha/`，CURRENT-STATE §4 已登记为 `#17` 的判据）**已经是这条路**。它与本检查**互补**：它给"等号"，本检查给"**不加载程序集、不信任 attribute 也能读出事实**"的独立旁路（两者不一致本身就是报警）。
   ⚠️ 前提已实测：`PresentationCore.Linux` 是 `GenerateAssemblyInfo=false` ⇒ **现在一个 `AssemblyMetadata` 都没有**；且该路线**会改 `pc` 的 sha** ⇒ 必须单独一波（不能与本检查同波，否则别的车道的读数作废）。
2. **PDB 的 document checksum**：`PresentationCore.pdb`（2,159,460 B）里 `#US`/Document 表应含源文件的**内容哈希**（`EmbedAllSources`/`ChecksumAlgorithm`）。**未测**：我没有验证该 PDB 是否带了 `build/shims/PresentationCore.HbTextLine.cs` 的 document 记录及其 checksum 算法 ⇒ **登记为未测**，不给结论。若成立，它可在**不改产物**的前提下给出"源内容 ↔ 编译输入"的等号证据（但 PDB 可被单独替换 ⇒ 仍需与产物交叉）。
3. **确定性构建比对**：`-p:Deterministic=true` 下同一源码重编应逐字节相同；若把现树 shim 编到**私有输出目录**（`-p:BaseOutputPath=$HOME/...`，纪律 33 的"只用于编"口径）得到**同一个 sha**，那也是等号证据。**未测**（要跑一次构建 ⇒ 有资源与"中间态"风险，本车道不做）。

**B：token 分辨力的天花板。** 本检查的强度**随每次修订产生的新符号数量**变化：
- 只有注释/逻辑改动的修订 ⇒ **`NEW` 集为空** ⇒ 脚本给 **`WEAK-PASS rc=3`**（明确不是 PASS）；**这时若有人只看"没红"就放行，就是假绿** ⇒ 我把它做成**非 0 退出码**正是为了挡住这个。
- 新符号被**删除**（回退） ⇒ 脚本在"现树里没这个 token"时立刻 `NOINFO rc=2`（不静默降级）。
- 建议（给主控）：把"**本版新增标识符数 = 0 ⇒ WEAK-PASS**"这条**写进波次收尾清单**——即"改 shim 的那一波必须能回答'本版新增了哪个可检出符号'，答不出来就必须走路线 A1/A3"。

**C：`#US` 的"共享后缀"陷阱（未完全展开）。** 元数据 `#US` 允许**后缀共享**（一个字面量可能是另一个的尾巴）。我用的是**子串搜索** ⇒ 共享不影响"命中/不命中"的判定，但**"命中 1 次"≠"该字面量独立存在"**。⇒ 本报告对 `#US` 的 token 只用来做**编码对照**（`RECENT` 列），**不参与 PASS/FAIL**，因此这个陷阱不影响结论（登记，不夸大）。

**D：本检查**不进**门禁的世代绑定。** `tline-gate.sh` 的 `generation` 绑定的是 `run.sh`/`HbTextLineParity/Program.cs`/shim **三项**（纪律 34 的真空档）。本脚本**没有**被绑进去，也**不应该**在本波改动（改它不影响任何臂日志的判读）。⇒ **建议（登记，不擅自做）**：把本脚本**当 `verify-all` 的一条新判据**（例如第 11 步：`rc ∈ {0}`；`rc=3` 记 `WEAK-PASS` 并要求人裁定），但**接线属于主控写域**（`verify-all.sh` 是主控的）。**本车道不改 `verify-all.sh`。**

**E：未测项（如实列）**：
- 旧产物**内部**是否"其实是更新源码编的、只是放了很久"——**不可测**（本检查只读内容，不读因果）；我用的是**内容**判据而非 mtime（纪律 24 的口径）。
- `#Strings` 里是否存在**其它**同族 DLL 的误报——**已测**：`_boxOriginX` 全文件恰好 1 次且落在 `#Strings` 区间内（§3.1 第 4 条）。
- 产物是否**被后续手工改写**过（绕过编译）——本检查对此**部分**敏感（改写会破坏 PE/元数据一致性 ⇒ 更可能 `NOINFO`），但**没有**做"PE 校验和 / 强名"级的一致性验证 ⇒ **未测**。
