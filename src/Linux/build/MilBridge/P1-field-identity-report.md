# P1 字段身份表（描述符 `dvr_used` vs 子轨出参 `out_dvr_used`）＋同名不同物清单（`t197`）

> **只读资产件**（`t197`，runner）：未改任何 `src/**`、未构建、未跑腿、未占显示、未 `git add/commit/push`；**未碰** `build/MilBridge/P1-lm-consume2-report.md` 及其它人载体。所有读数**现取现算**，行号一律整行取。
> **读取时刻**：`2026-09-29T22:50:12+08:00`（同批）；**件 sha16**：`win32_pts.c`＝`27b023609512f74f`｜`upstream/…/Pts.cs`＝`1a8575a18767a956`｜`upstream/…/PtsHelper.cs`＝`f2ed9552e983fed1`。
> **不重复复核** `t194` 的判词（那一格已转 `t195`／`verifier`）；本件做的是**可长期复用的身份表资产**。

## §1 `FSPARADESCRIPTION` 逐字段身份表（镜像 `src/WpfGfx.Linux.Native/src/win32_pts.c:1091-1106` ＋ 上游 `Pts.cs:1500-1509`）
镜像整行（现取）：`1091: typedef struct { /* 共 64 B */`｜`1093: void *pfspara; /* +8 */`｜`1094: void *pfsparaclient; /* +16 ← 本跳要填的字段 */`｜`1095: void *nmp; /* +24 */`｜`1096: int idobj; /* +32 */`｜`1097: int dvr_used; /* +36 */`｜`1098: wpf_pts_fsbbox_t fsbbox; /* +40（20 B） */`｜`1099: int dvr_top_space; /* +60 */`
断言整行：`1101-1104` 四条（`pfspara==8`／`pfsparaclient==16`／`nmp==24`／`sizeof==64`）＋`1105-1106`（`FSUPDATEINFO==8`／`FSBBOX==20`）—— **共 6 条**。

| 偏移 | 类型 | 名称 | 本侧**写过**？ | 本侧**读过**？ | 宿主是否读它（现取证据） |
|---|---|---|---|---|---|
| +0 | `FSUPDATEINFO`(8B) | `fsupdinf` | ❌（`memset` 后未写） | ❌ | `NOINFO(未查)` |
| **+8** | `void *` | **`pfspara`** | ✅ **`:3713 rg[i].pfspara = (void *)para_val;`** | ❌ | ✅ 上游 `PtsHelper.cs:179 paraClient.Arrange(arrayParaDesc[index].pfspara, …)` |
| **+16** | `void *` | **`pfsparaclient`** | ✅ **`:3714 rg[i].pfsparaclient = (void *)dp->fsp_pl_cur;`** | ❌ | ✅ `PtsHelper.cs:158`（`HandleToObject(...) as BaseParaClient`，同段现取） |
| **+24** | `void *` | **`nmp`** | ✅ **`:3715 rg[i].nmp = (void *)dp->drive_nmp;`** | ❌ | `NOINFO(未查)` |
| +32 | `int` | `idobj` | ❌ | ❌ | `NOINFO(未查)` |
| **+36** | `int` | **`dvr_used`** | 🔴 **0 命中**（见 §1.1） | 🔴 0 命中 | ✅ **上游 `PtsHelper.cs:174/177/180`** 三处读它 |
| +40 | `FSBBOX`(20B) | `fsbbox` | ❌ | ❌ | `NOINFO(未查)` |
| **+60** | `int` | **`dvr_top_space`** | 🔴 **0 命中**（见 §1.1） | 🔴 0 命中 | ✅ **上游 `PtsHelper.cs:174/176/177/179`** 四处读它 |

### §1.1 「写过/读过」的**命中数与射程**（`P10`：0 命中必须带射程）
- 命令：`grep -c 'rg\[i\]\.dvr_used\|rg\[i\]\.dvr_top_space' src/WpfGfx.Linux.Native/src/win32_pts.c` ⇒ **命中 ＝ 0**。
  **射程**：本文件对 `rg[i]` 的写入**全部**在填充路径 `:3710-3715`（三行见上表），**该路径只写 `pfspara`／`pfsparaclient`／`nmp`**；同段 `:3712 memset((void *)&rg[i], 0, sizeof(rg[i]))` ⇒ **`+36`／`+60` 交回宿主时恒 0**。
- 命令：`grep -cE 'dvr_used|dvr_top_space' src/WpfGfx.Linux.Native/src/win32_pts.c` ⇒ **总命中 ＝ 15**，射程**全部**属下列四类（**无一是"描述符字段赋值"**）：
  1. **声明/镜像**：`:1097`、`:1099`；
  2. **`t194` 新增全局**：`:1128 g_pts_lmwit_dvr_used/g_pts_lmwit_dvr_top`；
  3. **子轨出参**（**另一物**，见 §2）：`:1522`、`:1529`、`:1550`、`:1554`、`:1555`、`:1611`、`:1612`；
  4. **驱动格毒值/打印**：`:1672`、`:1681`、`:1695`；**联合判词算式**：`:3606`、`:3612`。
⇒ **同名不同物在本文件里可机械分辨**：命中是否落在描述符写入面 `:3710-3715` —— 落在那里才是 `+36`／`+60`。

## §2 两条调用链证据（**这就是 `dvr_used(+36)` 与 `out_dvr_used` 的区别**）
- **链 A（描述符字段＝宿主 `:177` 读的那一对）**：托管 `PtsHelper.ParaListFromTrack` → native **`FsQueryTrackParaList`**（本侧填充 `:3710-3715`）→ 回填 `FSPARADESCRIPTION[]` → 宿主消费：
  ```
  174: int dvrTopSpace = arrayParaDesc[index].dvrTopSpace;
  176: rcPara.v += dvrPara + dvrTopSpace;
  177: rcPara.dv = arrayParaDesc[index].dvrUsed - dvrTopSpace;
  179: paraClient.Arrange(arrayParaDesc[index].pfspara, rcPara, dvrTopSpace, fswdirTrack);
  180: dvrPara += arrayParaDesc[index].dvrUsed;
  ```
  ⇒ `:177` 两个操作数**都是描述符字段**（`+36`／`+60`），而本侧对这两个字段的**赋值命中为 0**。
- **链 B（子轨出参 `out_dvr_used`）**：上游 DllImport `3318: internal static extern int FsFormatSubtrackFinite(`（其后形参含 `out int pdvrUsed`）→ **native 入口 `:1516 int FsFormatSubtrackFinite(`**（形参表 `:1522` 含 `int *out_dvr_used`）→ 本侧写点 `:1529`（0）／`:1550`（`seg_h`）／`:1554`（`dvr_u`，反腿①）。
  ⇒ 该值经**函数出参**交回调用者，**不经过** `FSPARADESCRIPTION[]` ⇒ **与宿主 `:177` 读的不是同一物**（对象不同、写点不同、通路不同）。

## §3 同名不同物清单（每条给**可机器判据**）
| # | 对子 | 为何不是同一物 | **可机器判据** | 依据 |
|---|---|---|---|---|
| 1 | 描述符 `dvr_used(+36)` ↔ 子轨出参 `out_dvr_used` | 前者**结构字段**、宿主 `:177` 读；后者**函数出参**、经调用返回 | 命中是否落在**描述符写入面**（`:3710-3715`）／行内是否带 `+36` 偏移 token | 本件 §1／§2（**自算**） |
| 2 | 描述符 `dvr_top_space(+60)` ↔ 子轨出参 `out_dvr_top_space` | 同上（`:1612` 形参 vs `:1099` 字段） | 同 #1（偏移 `+60`） | 本件 §1／§2（**自算**） |
| 3 | `pfspara(+8)`（**E**：本侧对象字段地址） ↔ `pfsparaclient(+16)`（**H**：托管句柄） | 一个是本侧自有对象指针，一个是托管表下标 | **族分类**：`E`＝`wpf_pts_sub_claim()` 命中；`H`＝本 run 托管产出行同值 | `t162`／`t181` 载体（**引自，本席未独立复算**） |
| 4 | `nms`（`+80` 产出） ↔ `nmp`（`+136` 产出） | 两个不同句柄、不同产出点 | **产出点 token**：`[DRIVE-PROBE] nms=` vs `[DRIVE-PROBE2] nmp1=` | `t151`／`t156` 载体（引自） |
| 5 | `pfsclient`（池下标+1，**I**） ↔ 任一句柄（**H**） | 同形小整数、不同语义 | **字段名分列打印**（`pfsclient=` 与句柄字段必须分开） | `t151` 载体（引自） |
| 6 | `cParas`（描述符**条数**） ↔ `cParaDesc`（**出参**条数） ↔ 本侧 `wpf_pts_sub.c_paras`（**本侧账**） | 三者同名却分别属"请求数／实际数／本侧账" | 口令：三者**必须**分别以 `cParas=`／`cParaDesc=`／`c_paras=` 打，禁合并 | `t160`／`t181` 载体（引自） |
| 7 | `idx0_zero`（0-based） ↔ `slotN_zero`（1-based） | 同一事实的两种口径（`t167` 的 14 vs 15） | **必须双口径同打**（槽号叙述一律 1-based 且标口径） | `t167`／`t168` 载体（引自） |
| 8 | `fsbbox.fsrc`（描述符 +40 内） ↔ `FSRECT fsrcToFill`（子轨入参） | 一个是**产出**、一个是**入参** | 命名区分 ＋ 通路口径（结构字段 vs `ref` 入参） | 本件 §2（**自算**） |

## §4 判据草案（**只写草案：不写脚本、不接线、不动他人件**）
> **草案 SJC-FIELD-ID**：**凡把某字段作为证据引用，必须先给「结构偏移 ＋ 写点」两要素**，且写点必须落在**该结构的写入面**上。两要素缺一 ⇒ 该证据**作废**；写点与偏移**对不上** ⇒ **判红**（`reason=field-identity-mismatch`）。
- **正例（现取可核）**：`t181` 的 `pfspara` 证据 —— 偏移 `+8`（`:1101 _Static_assert`）＋ 写点 `:3713 rg[i].pfspara = …` ＋ 字节级读回（`bytes0_32` 第 9–16 字节）⇒ 三要素自洽。
- **反例（现取可核）**：`t194` 的算式腿 —— 偏移标 `+36`（描述符 `dvr_used`）＋ 写点引 `:1550/:1554`（**子轨出参**，不在 `:3710-3715`）⇒ **对不上** ⇒ 按本草案该证据**判红**（不改 `t194` 结论，只判"该证据无效"）。
- **能否落成已接线牙？** **可以做，但有前置**。需要的机械面是**统一 token**：证据行须同时出现 `field=<名>`、`off=<结构偏移>`、`write=<文件:行>`（例 `field=pfspara off=+8 write=win32_pts.c:3713`）。本波已有 `off_pfspara=8`／`off16=16`／`idx0_`／`slotN_` 等**部分**形态。
  - **现在只能做弱版**：判"是否同时给了两要素"；**不能**判"对得上"（需一份机器可读的**字段→写点注册表**，本波没有）⇒ 该格记 **`NOINFO(需字段→写点注册表)`**。
  - 最小实现面（若领队要做）：一份 `field-write-registry.tsv`（`结构/字段/偏移/写点`）＋一条 grep 型装置比对证据行。

## §5 边界 · `NOINFO` · 引用纪律
- **未取到**：`fsupdinf`／`idobj`／`fsbbox`／`nmp` 的**宿主消费点**（本件只查了 `PtsHelper.cs:158` 与 `:174-180` 段）⇒ 记 `NOINFO(未查)`，不写成"宿主没读"。
- **本侧读取点**：`+8/+16/+24` 三字段在本侧除调试打印外无读；`+36/+60` 本侧 0 读写（射程见 §1.1）。
- **引用**：`t151`／`t156`／`t160`／`t162`／`t167`／`t168`／`t181` 的读数均为**引自其载体，本席未独立复算**；本件**自算**的只有 §1／§1.1／§2 的 grep 与整行现取。
- **纪律**：`P8`（"没取到"不写成 0："0 命中"已附射程）／`P9`（不把"本侧查不到"推广成"宿主没读"）／`P10`（先证被检物真被送到检查点）。
P1-FIELD-IDENTITY 自证（口径＝末行之前全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 7a824e4383e5d510，且本行＝末行。
