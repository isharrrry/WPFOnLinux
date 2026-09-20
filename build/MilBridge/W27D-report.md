# W27D 报告 —— `D-G15` 机器对账（**只交付、不接线**）

> lane = **W27D**｜起 2026-09-17 17:40 → 收 2026-09-17 18:0x +0800｜kernel `6.8.0-138-generic`｜`nproc=3`
> `loadavg`（收工读数）`4.09 4.50 2.74`｜`MemAvailable` 3,214,728 kB｜**零 `dotnet`**（一个都没跑）
> 写域实测：**只**新建 2 个文件（下 §1），`verify-all.sh` / `KNOWN-DEFECTS.md` / `known-red.json` **一个字节未碰**

---

## §0 一行结论

核对器**建成并当场抓到真信号**（首读就点出主控本波新登记的 `D-G18`/`D-G19`/`D-G20` 未在声明里），
声明跟上现场后 **`DEFREG=PASS`（rc=0）**、`--selftest` **10/10 PASS（rc=0）**；
派单书前提里**两条被实测推翻**：① `D-G2`/`D-G3` **不在缺陷册里**这条**今天不成立**（它们今天在 `KD:1123/1124`，
且 `grep -c 'D-G2\|D-G3' KD` = **4 不是 0**）；② CS 的 `:368/:369` 两处行号**已过期**（真值 `:384/:385`）。

---

## §1 写域与件（sha16 一律现场算）

| 件 | before | after | 说明 |
|---|---|---|---|
| `build/MilBridge/tools/defect-registry-check.sh` | —（新建） | **`35838bf64f658447`** | 核对器本体（三态 + `--selftest` + `--emit`） |
| `build/MilBridge/tools/defect-registry-declared.tsv` | —（新建） | **`18ea9c1ddcae577b`** | **权威出处声明**（63 行；`--emit` 机械生成） |
| `build/MilBridge/W27D-report.md` | —（新建） | 本文件 | —— |

**未碰**（实测 sha 与我读到时一致，见 §7 表）：`verify-all.sh`、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`、
`docs/CURRENT-STATE.md`、`handoff.md`、`build/MilBridge/known-red.json`。
`--selftest` 全程在 `mktemp -d` 沙箱 + **合成 fixture** 上跑，**不改仓内任何件**（沙箱内硬链接已改为 `--emit` 派生 fixture）。

---

## §2 为什么要两个文件（设计取舍，直接回答任务书那一问）

任务书问：声明放哪、会不会变成"又一份手工清单"。**我的选择 = 核对器旁挂一个 `.tsv`**，理由与反坑措施：

1. **为什么不放进 `KNOWN-DEFECTS.md`**：那是**主控写域**（派单书明令我不许改）；且该文件正是 `D-G15` 的**当事件**，
   把判据塞进被判处 = **自指**（声明一改，被量件 sha 也改，判据无法自证）。
2. **为什么不是脚本内 heredoc**（我第一版）：`--emit` 的输出无法 `diff` ack，且改声明要动 `.sh` ⇒ 与执行逻辑同一个 sha，**不好审**。
   旁挂 `.tsv` 让"声明"与"读它的代码"各自有独立 sha。
3. **它会不会退化成"又一份手工清单"**：**不会**，三条机械保障写进了本体 ——
   - `--emit` 从现场树**一键重生成**（`load_maps` 扫 7 个登记件 → 每个编号的 `req=`/`present=` 现场算）；
   - 声明里**每条都能判红**：声明说"它在 KD 里"而 KD 没有 ⇒ `FAIL` 点名（`--selftest` case B/G/I）；
   - **`DECL-ANCHORS` + `DEFREG_DECLDRIFT=<n>`**：声明写在哪一版树上（7 件 sha16）→ 树一变就出声（首读实测 `=2`）。
   ⇒ 它是**判据**（会红、会 NOINFO），不是文档。

### 声明格式（逐字）

```
# DECL-GEN = (--emit) 2026-09-17 18:00:04 +0800
# DECL-ANCHORS = KD=4368028ae291b5ea CS=78381a775e904e30 HO=ab2a3a804306a47f AB=d6821406b349dfcb KRJ=b7a4ad0907f9d76b KRF=db3b449112daedd1 KRP=8497a0ca1689cf90
# grammar: D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
# fields:  ID<TAB><id><TAB>req=<key,key,...|-><TAB>present=<key,key,...>
ID	D-A1	req=KD,CS,HO,AB	present=KD,CS,HO,AB
ID	D-A3	req=KD,HO,AB	present=KD,HO,AB
ID	D-G18	req=KD	present=KD
...
ID	D-U1	req=KD,CS,HO	present=KD,CS,HO
```
（键 = `KD`=`KNOWN-DEFECTS.md`｜`CS`=`docs/CURRENT-STATE.md`｜`HO`=`handoff.md`｜`AB`=`ACCEPTANCE-BASELINE.md`｜
`KRJ`/`KRF`/`KRP` = 三个 `known-red*` 登记件，**只许出现在 `present=`**。共 **56** 条。）

---

## §3 判据（三态；三态与 rc 的对应）

| # | 条件 | 判词 | rc |
|---|---|---|---|
| ① | 声明文件缺失 / 解析后 0 行 | `DEFREG=NOINFO reason=no-declaration` | 2 |
| ② | 声明里有畸形行（非注释非空、非 `ID<TAB>…`、编号不合词法、`req=` 含非键） | `DEFREG=NOINFO reason=decl-unparsable` | 2 |
| ③ | `req=K1,K2` 的编号在某一个 K 的 route 件里**一次都没出现** | `DEFREG=FAIL reason=declared-id-missing-in-route`（逐个点名） | 1 |
| ④ | route 件里出现、声明里没有的编号 | `DEFREG=FAIL reason=undeclared-id-in-route`（逐个点名） | 1 |
| ⑤ | 只在 route **之外**（`known-red*`）出现的未声明编号 | `DEFREG=NOINFO reason=id-only-outside-registry` | 2 |
| ⑥ | 全过 | `DEFREG=PASS` | 0 |

**判定顺序是判据的一部分**：`③ > ④ > ⑤`（③④ 都命中时报 ③，不许依赖"恰好命中哪条"）。

### 抄了 `baseline-sha-check.sh`（`5836b8296b2e4245`）哪些设计（带行号）

| 抄自 | 它的原文 | 本件对应 |
|---|---|---|
| `:19` | `set -uo pipefail`（**不用 `-e`**） | 本件 `:55` 同法；全程**不用** `printf\|grep -q` 形态（避开 `#26` W26C 那条"自称 SIGPIPE 假红"同族陷阱） |
| `:21-25` | `HERE`/`R` 由脚本自身位置推仓根；`BSC_BASE`/`BSC_STATE` 环境变量做沙箱替换 | 本件 `:57-69` `R` + `DRC_DECL`/`DRC_KD`…`DRC_KRP` |
| `:29-31` | 三态变量先置 `NOINFO`；**输入件缺失立刻出 NOINFO 并 `return 1`** | 本件 `run_check()` 首行 `load_decl` 失败 ⇒ `NOINFO`+`return 2` |
| `:36-51` | `grep -m1` 取机器行；取不到 ⇒ NOINFO；解析不出 ⇒ NOINFO；值不等 ⇒ FAIL | 本件 `ID<TAB>` 行同三段式 |
| `:62-64` | **自吐 `KEY=VALUE` 结论行**（`BASELINESHA=`/`BASELINEGEN=`/`BASELINE_BYTES=`） | 本件 `DEFREG=`/`DEFREG_DECL=`/`DEFREG_ROUTES=`/`DEFREG_EXTRA=`/`DEFREG_DECLDRIFT=`/`DEFREG_UNREG=` |
| `:79-80` | 只有全部子项 PASS 才 `return 0` | 本件 `run_check()` 末段同法 |
| `:83-134` | `--selftest`：`mktemp -d` + `trap rm -rf`；**每例含反极性**；只在全过时 `exit 0` | 本件 `--selftest` 同法（10 例：2 PASS / 5 FAIL / 3 NOINFO） |
| `:115-119` | 反极性构造必须**"必然不同"**（旧构造只有 15 位 ⇒ 只证出 NOINFO） | 本件反极性**在件里真删/真加编号**，可重放 |

---

## §4 `--selftest` 读数（**逐例给值＋rc**；主控要求 10/10）

```
$ bash build/MilBridge/tools/defect-registry-check.sh --selftest
SELFTEST case=A expect=PASS   got=PASS   rc=0(want 0) value=yes rc?=yes reason=none                          reason?=-   => yes
SELFTEST case=B expect=FAIL   got=FAIL   rc=1(want 1) value=yes rc?=yes reason=declared-id-missing-in-route  reason?=yes => yes
SELFTEST case=C expect=FAIL   got=FAIL   rc=1(want 1) value=yes rc?=yes reason=undeclared-id-in-route        reason?=yes => yes
SELFTEST case=D expect=NOINFO got=NOINFO rc=2(want 2) value=yes rc?=yes reason=id-only-outside-registry…     reason?=yes => yes
SELFTEST case=E expect=NOINFO got=NOINFO rc=2(want 2) value=yes rc?=yes reason=no-declaration（…）           reason?=yes => yes
SELFTEST case=F expect=FAIL   got=FAIL   rc=1(want 1) value=yes rc?=yes reason=undeclared-id-in-route        reason?=yes => yes
SELFTEST case=G expect=FAIL   got=FAIL   rc=1(want 1) value=yes rc?=yes reason=declared-id-missing-in-route  reason?=yes => yes
SELFTEST case=H expect=NOINFO got=NOINFO rc=2(want 2) value=yes rc?=yes reason=decl-unparsable               reason?=yes => yes
SELFTEST case=I expect=FAIL   got=FAIL   rc=1(want 1) value=yes rc?=yes reason=declared-id-missing-in-route  reason?=yes => yes
SELFTEST case=J expect=PASS   got=PASS   rc=0(want 0) value=yes rc?=yes reason=none                          reason?=-   => yes
DRC_SELFTEST=PASS cases=10 pass=2 fail=5 noinfo=3 not-as-expected=0
rc=0
```

**逐例谓词只有一处**（主控要求 ②）：`chk()` 里 `ok=yes ⇔ 值==expect ∧ rc==三态对应值 ∧（若给了）reason 含该子串`；
**汇总的 `pass/fail/noinfo` 完全由同一谓词的 `ok` 与 `expect` 现算**（`not-as-expected` 单列不达标数），不再另写一遍判据。

各例断言内容：`A` 正极性｜`B` 沙箱 KD 删一个声明要求它在 KD 的编号 ⇒ ③｜`C` 沙箱 KD 加一个未声明编号 ⇒ ④｜
`D` 只在非 route 件里出现 ⇒ ⑤｜`E` 删声明 ⇒ ①｜`F` **从声明里删一条** ⇒ ④｜`G` 声明里写仓内不存在的**合法**编号 ⇒ ③｜
`H` `req=NOPE` ⇒ ②｜`I` 只要求在 HO 的编号从 HO 删掉 ⇒ ③｜`J`（**反向**）`present=` 与现场不符但 `req=` 全满足 ⇒ **必须仍 PASS**。

### §4.1 我自己抓到的 3 个仪器缺陷（**必须披露**，纪律 40）

| 缺陷 | 症状 | 根因 | 修法 |
|---|---|---|---|
| **D1｜汇总与逐例不同源** | 主控实测"逐例 7 yes/3 no，汇总却写 `pass=1 fail=6`"，且出现 `got=FAIL rc=2` 这种自相矛盾行 | 首版 `chk()` 对"不达标"**改写 `nf`**，而 `nf` 又被用来判 NOINFO 例 | 改为**单一谓词**：`ok=yes` 才记对应计数，否则只进 `not-as-expected` |
| **D2｜`present=` 判红 ⇒ 并发改仓假红** | 17:5x 首读 `FAIL reason=decl-meta-inconsistent` 点名 13 条 | `present=` 含 `known-red.json` 等**会被其它车道改**的件 ⇒ 该"不符"是**无信息**不是判据失败 | `present=` **降级为非门禁诊断行**（`DEFREG_DECLMETA=`）；判据只看 `req=` 与"未声明"。**不是**为了变绿——`③/④` 一字未放松（case B/C/F/G/I 五档反极性仍在） |
| **D3｜自测依赖活件 ⇒ 不可重放；且自测跑不完** | 沙箱硬链接活件，`#27` W27A 在窗口内改 `known-red.json`/`KD`/`CS` ⇒ 自测假红；后来 10 例超过 60 s 被 SIGTERM | ① 硬链接活件；② `line_of` 对 1 MB 的 `handoff.md` **每编号重扫一遍**（53×4×…） | ① 沙箱改**由声明派生的合成 fixture**（与仓漂移无关）；② 取数**一次性化**（`load_maps` 每件只扫一遍建 `ID2LINE`/`IDS_BY_KEY`/`KEY_SHA`）⇒ 现场检查 1.4 s、自测 15 s |

另有两个**构造错误**（首版就被 `--selftest` 自己抓到，属"用例前提错"不是逻辑错）：
`case G` 原先用的 `D-ZZZ9` **本身词法不合法** ⇒ 探针诚实地报 `decl-unparsable`（改用 `D-Z9`）；
`case F/I` 原先用 `grep -vxF <id>` 删声明行 —— **删不掉**（行是 `ID<TAB><id><TAB>…`，整行匹配永不中）⇒ 改用 `grep -vP "^ID\t$SPECIMEN\t"`。

### §4.2 词法边界（实测，写进 `--emit` 头注释）

`D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*` ⇒ **收** `D-G2 D-G14 D-F1b D-T2-c D-T5-R D-A2-r D-G`（家族名）；
**不收**：`D-PARTY-NOTICES`（段全大写无数字，全仓 338 命中，**全是许可文件名**）、`D-Bus`、`D-C`
（`upstream/…/StrokeNodeOperations2.cs:216` 的数学式 `C+s(D-C)`）、**`D-ZZ9`（多位大写 scope 不合法）**。
⇒ 若将来真需要多位大写 scope，**必须同时改 `FAMRE` 与头注释**，否则声明会被判 `decl-unparsable`（这是**故意**的：宁 NOINFO 不静默）。

---

## §5 现场正极性读数（主控要求 ④）

```
$ bash build/MilBridge/tools/defect-registry-check.sh
DEFREG_DECL=n=56 route_ids=56 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=4368028ae291b5ea CS=78381a775e904e30 HO=ab2a3a804306a47f AB=d6821406b349dfcb
DEFREG_EXTRA=KRJ=b7a4ad0907f9d76b KRF=db3b449112daedd1 KRP=8497a0ca1689cf90
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=56 route_ids=56（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
rc=0
```
两趟独立跑 stdout **逐字节相同**（sha16 **`265282b9bc9be9e2`**，`diff` 空）⇒ 可复现。
**`DEFREG_DECLDRIFT=0`** = 声明与现场 7 件同版（声明是在 `KD=4368028ae291b5ea` 上生成的）。

### §5.1 首读的**真信号**（主控已裁：真信号，不是假红）

声明生成于 `KD=bd207928c847e2b8` 时，随后主控在本波登记了 `D-G18`/`D-G19`/`D-G20` ⇒ 核对器**当场点名**：

```
DEFREG=FAIL reason=undeclared-id-in-route
  D-G18 first-seen=KD:1114 route=…/samples/WpfFeatureProbe/KNOWN-DEFECTS.md
  D-G19 first-seen=KD:1093 route=…/samples/WpfFeatureProbe/KNOWN-DEFECTS.md
  D-G20 first-seen=KD:1098 route=…/samples/WpfFeatureProbe/KNOWN-DEFECTS.md
rc=1
```
**处置**（照主控裁定）：**声明跟上现场**，三条各写 `req=KD`、`present=KD` —— 因为**今天实测**它们
**只**在 `KNOWN-DEFECTS.md` 里出现（`grep -rn` 全仓，除 `upstream/`：`D-G18` = 1 处、`D-G19` = 1 处、`D-G20` = 1 处）。
**没有**为了让自测变绿而放宽 `req` 语义：`req` 取的是"今天实测为真的键集"，少一个键就少一条牙。

---

## §6 接线锚文本（**我不接线**；`verify-all.sh` 是主控写域，现 `ff0d3a0b636ad302`、`^run_step "` = 15）

**建议接在主控刚接的 `[9] BUILD-HYGIENE` 之后**（两件都是纯 bash、零 `dotnet`、约 1.4 s）：

```bash
# [10] 缺陷编号对账（D-G15）：声明 ⇔ 现场（route 文件）双向点名；NOINFO 不许当绿
run_step "DEFECT-REGISTRY" bash build/MilBridge/tools/defect-registry-check.sh
```
- 步名故意用 **ASCII**（否则失败日志路径会是一串下划线——`#24` 的教训）。
- **天然可被 `run_step` 的失败 grep 抓到**：判据键就是 `DEFREG=FAIL reason=…` / `DEFREG=NOINFO reason=…`，
  正是 `run_step` 那条 `[A-Z][A-Z0-9_]*=(FAIL|NOINFO)` 形态；**绿的时候**回显行是 `DEFREG=PASS …` ⇒ **不误报**。
- `rc` 语义已对齐三态：`0`=PASS｜`1`=FAIL｜`2`=NOINFO（`NOINFO` 不许当绿、也不冒充红）。
- 同步要改的文档：基线表头**步数 15 → 16**、`CURRENT-STATE.md`/`handoff.md` 的 `verify-all.sh` sha。

---

## §7 读数表（谁在什么时候读的什么）

| 项 | 值 |
|---|---|
| lane / 时间 | **W27D**｜2026-09-17 17:40 → 18:0x +0800 |
| kernel / `nproc` | `6.8.0-138-generic` / 3 |
| `MemAvailable` | 3,214,728 kB（收工） |
| `loadavg` | `4.09 4.50 2.74`（收工） |
| 核对器 sha16 | **`35838bf64f658447`**（`build/MilBridge/tools/defect-registry-check.sh`） |
| 声明 sha16 | **`18ea9c1ddcae577b`**（`build/MilBridge/tools/defect-registry-declared.tsv`，63 行） |
| `KD` | `4368028ae291b5ea`（214,465 B，mtime 17:56:00） |
| `CS` | `78381a775e904e30`（mtime 17:55:03） |
| `HO` | `ab2a3a804306a47f`（mtime 17:08:57） |
| `AB` | `d6821406b349dfcb` |
| `KRJ` | `b7a4ad0907f9d76b`（mtime 17:49:26） |
| `KRF` / `KRP` | `db3b449112daedd1` / `8497a0ca1689cf90` |
| **并发披露** | 我读数期间 `known-red.json`（17:49:26，`84fcfb4f728deead`→`b7a4ad0907f9d76b`）、`KD`（17:56）、`CS`（17:55）**被主控/其它车道改动**；本件结论**不依赖**这些取值（`DECLDRIFT` 现为 0，因声明已在改动后重生成） |
| 现场输出 sha16 | `265282b9bc9be9e2`（两趟逐字节相同） |

---

## §8 测绘：`D-` 编号登记现状（任务书要求 ①）

**机器统计**（脚本 `python3` 全仓 + 7 件；词法 = §4.2 的 `FAMRE`；排除 `upstream/`）：

| 量 | 值 |
|---|---|
| route 件（KD/CS/HO/AB）里的编号 | **56** |
| 7 个登记件里的编号（并集） | **59**（含 `D-G` 家族名） |
| 只在 **1 件**出现的 | **3**（见下） |
| 只在 **2 件**出现的 | **5** |
| **一个 route 件都没有**的（只在报告/波预登记/代码注释里） | **5**：`D-G12-CH`、`D-G12-RED`、`D-T2-a`、`D-T2-b`、`D-T2-d` |

### 8.1 "只在 1 个文件里"的编号（**3 条**，任务书要的正是这个）

| 编号 | 唯一出处 | 说明 |
|---|---|---|
| **`D-G19`** | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:1093` | 主控本波新登记；`CURRENT-STATE.md`/`handoff.md` **今天没有** |
| **`D-G20`** | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:1098` | 同上 |
| **`D-G18`** | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:1114` | 同上 |

> ⚠️ 这三条**就是"没有单一权威"的活样本**：读者拿 `D-G19` 去 `CURRENT-STATE.md` 找**找不到**。
> 另**5 条只在 2 件**（`D-G4`/`D-G5`/`D-G6` = KD+CS｜`D-R1` = KD+HO｜`D-G` = KD+AB）。

### 8.2 ✅ 真正的"无单一权威"名单（**KD 里根本没有**，3 条）

| 编号 | 出现在 | 后果 |
|---|---|---|
| **`D-E1`** | `CS:319`、`HO:2174`、`AB:204` | 按"缺陷册即权威"去 `KNOWN-DEFECTS.md` 找 ⇒ **找不到**（`grep` 0 命中） |
| **`D-F3`** | `CS:319`、`HO:2111`、`AB:204` | 同上 |
| **`D-R4`** | `CS:126`、`HO:2221`、`AB:201` | 同上 |
（反向：`D-A3`、`D-R1`、`D-G18/19/20`、`D-G` **不在 `CS` 里**——读者拿 `CURRENT-STATE.md` 当权威也找不到。）

---

## §9 🔴 我推翻的两句话（派单书 `D-G15` 记载）

**① `grep -c 'D-G2\|D-G3' samples/WpfFeatureProbe/KNOWN-DEFECTS.md` = 0 —— 今天不成立，实测 = 4。**
```
$ grep -c 'D-G2\|D-G3' samples/WpfFeatureProbe/KNOWN-DEFECTS.md
4
$ grep -n 'D-G2\|D-G3' samples/WpfFeatureProbe/KNOWN-DEFECTS.md | cut -c1-90
1098:### 🆕 `D-G20`：门禁**不读**探针自带的逐例对账行 ⇒ "**汇总行与逐例行不一致**"抓不到   ← "D-G2" 是 "D-G20" 的前缀
1123:### 🆕 `D-G15`：**缺陷登记地点分散，没有单一权威** —— `D-G2`/`D-G3` **只在 `CURRENT-STATE.m…  ← D-G15 条目正文自己
1124:- **现场（主控复核）**：`grep -c 'D-G2\|D-G3' …` = **0**；而它们在 **`docs/CURRENT-STATE.md:368`…      ← 自己引自己的查询串
1131:- **`D-R8` 的补法…`这一招可直接复用到 `D-G3`/`D-G9`/`D-F1b`。`                                  ← 另一条的正文
```
⇒ **成因（本件最有价值的一条机制）**：`D-G2`/`D-G3` 是**其它编号的前缀**（`D-G20`），而 `D-G15` 条目**正文自己引了那个查询串**、
又**点名了 `D-G3`** ⇒ **一旦 `D-G15` 被登记进 `KNOWN-DEFECTS.md`，同一条 `grep` 就永远不再返回 0**。
即：**该证据是"自我 disqualifying"的 —— 登记这个缺陷的动作本身就破坏了它的现场证据。**
⇒ 正确的读法（也是本核对器采用的）：**按编号词法精确匹配**（`\bD-G2\b`），并**钉住读的是哪一版树**（`DECLDRIFT`/sha16）。
**这不否定 `D-G15` 的结论**（`D-G2`/`D-G3` 确实没有自己的缺陷册条目 —— 它们今天只作为"被提及的字符串"
出现在 `D-G15`/数字口径块里）；**否定的是那个查询串作为证据**，而这一条恰恰更重要：
**按字面照抄那条 `grep` 的任何人，今天都会得到 ≠0 的读数（4），并因此以为 `D-G15` 的现场是错的。**

**② `docs/CURRENT-STATE.md:368`（`D-G2`）/`:369`（`D-G3`）行号已过期。**
```
$ sed -n '368,369p' docs/CURRENT-STATE.md | cut -c1-60
| **拷贝点枚举器自身漏报（`#16` 新立，TAPPS 车道）** …       ← 不是 D-G2
| **PC 侧缩进接线不对称（`#16` 新立，主控读码；**本波明确不修**）…  ← 不是 D-G3
$ grep -n '`D-G2`\|`D-G3`' docs/CURRENT-STATE.md | cut -c1-40
384:| **`D-G2` 产品级文本路径在冻树回路里没有自动红/绿** …
385:| **`D-G3` 非九位"可见位"漂了没有任何东西会红** …
```
（另有 `CS:210`/`:250`/`:251`/`:17` 三处"提及式"出现。）⇒ **真值 `:384`/`:385`**；这本身就是 `D-G15` 说的病。

**③（顺带）"两文件 `D-G` 条目数 = 10 vs 14"我复算不出来。** 今天实测：
`KD` 标题形态 `D-G` 条目 **18**｜`CS` 表格行形态 `D-G` **6**｜"任何出现"形态 `KD` **20** vs `CS` **17**。
差额（CS-only）的确切成员是 **`D-G1`/`D-G5`/`D-G6`**（`D-G2`/`D-G3`/`D-G4` 两处都有）。
⇒ 我**不改写**那句话，只标**"口径未重现"**并给出今天的三个形态读数（不硬凑成 10/14）。

---

## §10 未达成 / `NOINFO` 清单（如实）

1. **未接线**（按派单书）：`verify-all.sh` 一行未动；锚文本见 §6，由主控落。
2. **`DECL-ANCHORS` 会随波漂移**：本波每有车道改 `KD`/`CS`/`known-red.json`，`DEFREG_DECLDRIFT` 就会非 0。
   这是**设计**（它就是"该重生成声明了"的信号），但**意味着主控波尾要跑一次 `--emit` 重生成**（否则下一波首读会 `FAIL`）。
   我**没有**把它做成自动重写（那会让核对器有写权 ⇒ 违反"只读"）。
3. **射程之外**（明确不覆盖）：① 编号的**语义**是否重复/矛盾（只对账"出现在哪"）；② `docs/WAVE*-PREREGISTRATION.md` 历史存档
   （按 `baseline-sha-check.sh:66-68` 的同一裁定：存档不是活声明，**只在"编号只存在于存档"时出 NOINFO**）；
   ③ `build/**/*.md` 里的车道报告（太多、且是历史件）；④ 编号**定义内容**是否与正文一致。
4. **本件不判"该编号是否已修"** —— 那是各步/门禁的事。
5. 首版三个仪器缺陷（§4.1）**已修**，但**未做**：把 `present=` 的诊断做成"必填 + 断言"，因为那会重新引入
   `known-red.json` 的假红（D2）；如需，**由主控裁定**（我建议保持诊断态）。
