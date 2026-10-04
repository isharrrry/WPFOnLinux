# V80 · `t58` 独立复核报告

**task `t59` / attempt `3cf7be93-e147-49a3-a8dd-4b0d22302f57`｜lane=`janitor`｜2026-09-28 12:36:33–12:37:30（+0800）**
仓 `$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜`HEAD=07c0a52b1892bbb5cdf07cd812f429e761f03f09`（`docs(#80): t58 关 T14-F1/F2 …`）｜`origin/feat-Linux == HEAD`｜`porcelain=0`
**立场**：不复述 `t58` 的结论；每一格我自己现取／自算。真树只读（唯一写入＝本报告）。夹具/临时件全在 `/tmp`（已删）。
**资源现取（12:36:33）**：`df -Pk /` 第 4 列 = **78,707,008 KB**（≥5 GB ✓）；`SwapFree` = **1,430 MB**（≠0 ✓）。未走槽（纯读）。

---

## 0. 判词

# **verdict = `needs_revision`**

**6 大项里 5 项通过、1 项不通过**：`HANDOFF-NEXT.md` §1 的**覆盖面件数写 225，现场是 226（4 处）**，且**同一件自身**在另一处（`:261`）已写 226 ⇒ 自相矛盾（1 条 finding，severity=medium，非产品面、非冻结面）。其余全部通过：九位 9 值逐位同、`inputs_fp` 逐位同、55 步、三节血逐字节未动、`+28/−0` 只增不改、`D-G180` house form 六要素齐＋`D-G179` 保留说明＋家族划界、两牙判词行全绿、七锚我自算逐位同、冻结面零改动、哨兵次序成立。

---

## 1. ① §1–§6 对齐：逐项现取对拍

| 契约要求的项 | **现场我自己现取**（12:36:38–12:37:00） | `t58` 在 `HANDOFF-NEXT` 里写的 | 判 |
|---|---|---|---|
| `gen=#80` | `CS:9` = `> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=…` | `gen=#80` | **一致** ✅ |
| 块 sha16 | `sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = **`b96d4312565a3c49`**（1,224,932 B） | `b96d4312565a3c49` | **一致** ✅ |
| 九位 9 值 | `bridge 4e25e4b27d4d5ae1`／`pc 5b6cfda3e12b84fc`／`pf b9a4f3a0e48e688d`／`windowsbase 9e860cbeecb352e1`／`provider 7e8a217b4165a6b9`／`win32shim 6825dd7071387a46`／`wic_shim f7b3026c8c019be2`／`hbtextline 921ba9c65e9fb3be`／`dwf c83be96f18759edc` | 同九值 | **逐位一致** ✅ |
| `inputs_fp` | 生产管线（`source <(sed -n "/^fp_inputs()/,/^}/p" build/close-wave.sh); fp_inputs`）＝ **`abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`** | 同值 | **逐位一致** ✅ |
| 55 步（真实步数） | `grep -c '^run_step "' verify-all.sh` ＝ **55** | `55` | **一致** ✅ |
| 头注释世代行 | `# VERIFYALL-STEPS-DECL: 55 gen=#79` ＋ 口径句 `**`#80` 收官起 = 55 步**`（`:8`） | 同（逐字引 `55 gen=#79`） | **一致** ✅（见 §1.1） |
| 覆盖面件数 | `run_step "FP-MANIFEST-TEETH" … --expect 226`（`:1195`）＋ 生产管线现取 **n=226** | `225 件`（`:18`／`:21`／`:124`／`:125`）；但 `:261` 写 **226** | **❌ 不一致（本报告唯一 finding）** |

### 1.1 关于 `DECL 55 gen=#79` —— **不是缺陷**（我据成文纪律判的）
§5 规则 46 逐字：「真不变量＝首行 `DECL` 声明的步数 == 现取 `run_step` 数，且**插入前**首行 `DECL` 的 `gen=` 必是**上一波**，不得与 `--wave-gen` 比」。
现场两条都满足：步数 **55 == 55**，`gen=#79` ＝ `#80` 的**上一波** ⇒ `t58` 把它**逐字引用**是**合规**的，我不记红。
（注：口径句 `**`#80` 收官起 = 55 步**` 真实在 `verify-all.sh:8`；`VERIFYALL_SELF=PASS names=55 decl=55 gen=#79 dup=0 order=OK prose=OK prereg=PASS vfile_sha16=600274f130cfe913` ⇒ `prose=OK` 点名的是**口径句**，与 `DECL` 的 `gen=` 是两件事。）

### 1.2 ❌ FINDING **F1**（severity=medium）：覆盖面件数写成 225，现场是 226
```
file: build/MilBridge/HANDOFF-NEXT.md
line: 18, 21, 124, 125        （四处同错）
problem:
  · 现场（我自己现取）：`grep -n 'run_step "FP-MANIFEST-TEETH"' verify-all.sh` ⇒ `:1195 … --expect 226`；
    生产管线 `fp_inputs` 件数 ＝ **226**；同趟 `fp-manifest-step.sh --expect 226` ⇒ `FP_MANIFEST_TEETH=PASS
    reason=ok files_n=226 files_n_uniq=226 declared_expect=226`、`rc=0`。
  · 而被复核件写：`…（**覆盖面 225 件**；…）`（:18）／`…｜覆盖面 **225 件**（[42] --expect 225）`（:21）／
    一览表 `…／225 件`（:124）／`…；覆盖面 [42] --expect 225`（:125）。
  · **同一件自相矛盾**：`:261` 逐字写「覆盖面现取 **226 件**，`#80` 冻后零改动」＋`FILES_N=226 ＝ P0-w80-report.md:77
    的 INFP_COUNT_RULER 常数 226`。⇒ 225 是**过时读数**（`t58` 自己的日志显示它用的工具报 225），226 是本代真值。
  · 违例：契约「覆盖面件数 … 逐项判与现取一致／不一致」；纪律 **46**（计数断言必须先证真相等）；`D-G131`（改覆盖面
    ⇒ `--expect` 同趟改）的**记账面**。
requiredFix:
  · 在该件 §1 四处（`:18`／`:21`／`:124`／`:125`）**追加 dated 更正行**（只增不改，保留 225 原文），写明：
    现取＝**226 件**（`[42] --expect 226`，`:1195`；`FP_MANIFEST_TEETH=PASS files_n=226 declared_expect=226`），
    并注明 225 是 `t58` 当时工具口径的过时值；或按本仓「dated 对齐」体例把四处引线与 `:261` 对齐。
  · **不要**改 `verify-all.sh`（`--expect 226` 已正确）；也**不要**改 `#80` 冻结块。
```
**注**：`t58` 任务描述自己就写着「⚠️ 一处与契约字面的偏差（请裁）：`declared=215`，不是 214」——那一格我核过**是对的**（见 §4）；但**覆盖面 226 vs 225** 这一格它**没有**自报。

## 2. ② 三节血逐字节未动（我自己算的改前/改后）

**基线取法**：`HANDOFF-NEXT.md` 在 `HEAD` 已是 `t58` 版本 ⇒ 推送前版本取 **`HEAD~1 = 8137240`**（`git diff --numstat 8137240 HEAD -- <该件>` ⇒ **`28	0`**）。

| 节 | 改前（`HEAD~1`）行区间 | 改前 sha16 | 改后（工作树）行区间 | 改后 sha16 | 判 |
|---|---|---|---|---|---|
| **§绑定规则·跨会话有效** | `167–211` | **`f795c6bc7672dd9c`** | `195–239` | **`f795c6bc7672dd9c`** | **IDENTICAL** ✅ |
| **§0 队长起手页** | `152–166` | **`cb283ed2a8307843`** | `180–194` | **`cb283ed2a8307843`** | **IDENTICAL** ✅ |
| **§下一波未闭项** | `212–EOF` | **`655311b6d05fe334`** | `240–EOF` | **`655311b6d05fe334`** | **IDENTICAL** ✅ |

⇒ **三节逐字节未动**（行区间整体平移，内容 sha16 三对全等）。段界无缺口：§0 收在 `194`、绑定规则起于 `195`。

## 3. ②′ 只增不改形态 ＋ 原值逐字仍在

```
$ git diff --numstat 8137240 HEAD -- build/MilBridge/HANDOFF-NEXT.md
28	0	build/MilBridge/HANDOFF-NEXT.md          ← 增 28 / 删 0
$ git diff 8137240 HEAD --build/MilBridge/HANDOFF-NEXT.md --numstat … （形态 hunk）
  全部 hunk 为 `a`（纯追加），无 `d`／无 `c`
```
**原值逐字仍在（从 diff 里点名验证，我现取 `grep -c`）**：
- `gen=#77` 计数 ＝ **3**（全是留档原文，每处紧随 dated 行）—— `t58` 报的 3 我复算得 3 ✅
- `b67560f2ff28932b…`（`#77` 时点 `inputs_fp`）：**在** `HANDOFF-NEXT.md`（留档行内逐字）✅
- `e3ebc811641bd467`、`fd9a9a1886d25575…`、`50 步`／`211 件` 等改前值**均以留档形态在场** ✅

## 4. ③ `D-G180` 入册形态（`KNOWN-DEFECTS.md` 首行 `:3666`）

house form **六要素齐**（逐条我现取读出）：
| 要素 | 现场 |
|---|---|
| **现象（在册读点，逐字）** | `README.md:180` 逐字 ＋ **两条独立机制**（① 根 props 被 MSBuild 自动导入 ⇒ `samples/HelloMil/HelloMil.csproj` 求值即 `error MSB4236`；② 92 个 csproj 进候选集 ⇒ `cand=88→180`／`undeclared=0→92`／`reason=drift`） ✅ |
| **根因** | 「自动导入按**搜索路径** vs 文档按**目录归属** ⇒ 不是同一件事」 ✅ |
| **证据（件＋字段＋sha16＋时刻）** | ① `grep -c MSB4236` ⇒ 0；② 根 props **工作树无且 `HEAD` 无**；③ 机制读点 `P0-migrate-report.md:132`／`ROUTES.md:83`；④ 现取两档 `BHYGIENE_IMPORT=PASS … undeclared=0`／`ROOT_ALLOW=PASS … unknown_fs=0`；牙 `d050d78198e6093c` ✅ |
| **判据（机器，三条并列）** | ①自动导入面 ②`[9]` 候选集/未声明两格 ③根级白名单牙 `unknown_fs=0 ∧ unknown_tracked=0` ✅ |
| **两极化** | 正极＝现树（PASS ＋ 整波失败步骤 0）；反极＝放回 ⇒ `MSB4236`（当趟 10 处失败）＋ `88→180`／`0→92` ✅ |
| **口径句（永久）** | 「凡对构建输入下『用不用』的结论，必须在**求值器**的行为上验证…」 ✅ |
**编号边界**：逐字「**`D-G179` 已由队长保留**给另一条发现（`defect-registry-check.sh` 的 `req` 列在自动路径上恒真…），**不是漏号**；本件按配号用 `D-G180`」⇒ **在正文里** ✅
**同族不合并**：逐字列出 `D-G174`（遍历域）／`D-G177`（射程洞）／`D-G136`（件头自述 vs 接线）／`D-G129`（状态位 vs 报告），并写明「**本条讲的是**…不是同一件事」⇒ **划界存在且未合并** ✅
**既有条目零改动**：`KNOWN-DEFECTS.md` 的 diff 形态＝`3664a3665,3680`（纯追加 16 行）✅

## 5. ④ 两牙判词行 ＋ 七锚自算（**不抄声明表**）

```
$ bash build/MilBridge/tools/defect-registry-check.sh
DEFREG_DECL=n=215 route_ids=215 grammar=…
DEFREG_ROUTES=KD=2152460b7e412352 CS=13077b52c938f8af HO=a4d8ffcf4c37f6fe AB=b96d4312565a3c49
DEFREG_EXTRA=KRJ=6351a46296d17b28 KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-
DEFREG_DECLDRIFT_KEYS=-  # 机读差集键行（零漂移给 -）
DEFREG=PASS declared=215 route_ids=215（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）   rc=0

$ bash build/MilBridge/tools/report-id-domain-check.sh
BOOK_ENTRY_UNREQUIRED_MISSING n=16 ids=… D-G179 …（**已登记的缺口：可见、不判红**）
BOOK_ENTRY_BINDING required=5 present=5 missing=0
REPORTID=PASS files=187 ids=1912 declared=215 glob=build/MilBridge/*report*.md
```
**七锚我逐件现算 vs 表头 `# DECL-ANCHORS`（`defect-registry-declared.tsv:2`）**：
```
declared : KD=2152460b7e412352 CS=13077b52c938f8af HO=a4d8ffcf4c37f6fe AB=b96d4312565a3c49 KRJ=6351a46296d17b28 KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
recomputed: KD=2152460b7e412352 CS=13077b52c938f8af HO=a4d8ffcf4c37f6fe AB=b96d4312565a3c49 KRJ=6351a46296d17b28 KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
```
⇒ **7/7 逐位相等** ✅（`KRJ` 已随本轮真实变化为 `6351a46296d17b28`，声明表同步 ⇒ `DECLDRIFT=0 keys=-` 名副其实）。
⚠️ **口径更正**：契约验收写 `DEFREG=PASS declared=214 route_ids=214`，**现场是 `declared=215`**；`t58` 已自报该偏差并请裁 —— **我现取支持 215**（`DEFREG_DECL=n=215 route_ids=215` 与判词行同值），故**不记 finding**。

## 6. ⑤ 冻结面零改动

| 项 | 现取 | 判 |
|---|---|---|
| 块件现算 | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = **`b96d4312565a3c49`**（1,224,932 B，mtime `2026-09-28 11:51:16.605`） | ✅ 与 `CS:9` 同值 |
| `CS:9` | `> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=…` | ✅ `gen=#80` 未变 |
| 块件的 git 历史 | `git log --oneline -5 -- samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` ⇒ **最新一笔 = `57cd937 t80: 波 #80 收口冻结（基线 901619543b3d913b → b96d4312565a3c49）…`**；其下是 `6a245bd`（`#78` 时代） | ✅ **冻结后无任何提交改过块件**（`t58` 那笔 `07c0a52b` **不在**该件历史里） |
| `porcelain` | **0** 行 | ✅ 干净（本报告写盘前现取） |

## 7. ⑥ 次序判词：**哨兵确是最后一个动件的动作**（成立）

| 时刻 | 事件 |
|---|---|
| **`2026-09-28T12:35:43+08:00`** | 最后一笔提交 `07c0a52b1892…`（`git log -1 --format=%cI`） |
| **`12:35:52.080397328`** | 哨兵 1 `/tmp/bridge-frozen.flag` 写入 |
| **`12:35:52.083397306`** | 哨兵 2 `~/wfp-runs/bridge-frozen.flag` 写入 |

⇒ **两哨兵 mtime 均晚于最后一笔提交 9 s** ⇒ 次序成立 ✅
**内容四键对拍**（现取）：`WAVE=w80-freeze`｜`BASELINE=#80`｜`BASELINE_SHA16=b96d4312565a3c49` ＝ **块件现算 `b96d4312565a3c49` ＝ `CS:9` 的 sha16** ⇒ **三者同一** ✅
**九位同趟对拍**：哨兵九键（`SHA/FP/PC/PF/WB/WIN32SHIM/HBTL/WIC/PROVIDER/DWF`）与 §1 我现取的九位**逐位相同**（含 `PC 5b6cfda3e12b84fc`／`PROVIDER 7e8a217b4165a6b9`／`WIN32SHIM 6825dd7071387a46`）✅
**两哨兵 `cmp`**：**IDENTICAL**（279 B，两者 sha16 均 `7e3aa8fa47fc0087`）✅
**反例判定口径（按契约要求给出，供下一代用）**：
- 若哨兵 **mtime < 最后一笔提交** ⇒ **不是最后动作**；
- 若**在哨兵之后**还有**任何**仓内写盘（`git status` 出现新 `M`／新 `??`、或覆盖面内件 mtime 后移）⇒ 该写盘即"晚于哨兵"，哨兵须**在该写盘之后重写**；
- 区分**文本写入 vs 动件写入**：文本写入（如本报告 `V80-t58-review.md`）**若发生在哨兵之后**，同样使哨兵失去"最后动作"资格 —— 但**只在被覆盖面／被门禁读取时**才有实质影响；本仓口径按契约取严：**最后动作＝重写两哨兵**。
- 本次实测：我在写本报告后**会重写两哨兵**（见文末），以保持该不变量。

---

## 8. 我的复核动作会不会破坏"哨兵最后"？（如实自报）
我这一趟是**只读**（除本报告一件）。按契约要求，我交件后**最后动作＝重写两哨兵**，两个时刻在文末给。⚠️ 边界：我**不改**块件／`CS`／任何牙判据（`out-of-scope` 逐条遵守），故重写哨兵**不涉及内容变更**，只是把"最后动作"重新落回哨兵。

## 9. 产出与自报 sha16

| 件 | sha16 | 字节 | 时刻 |
|---|---|---|---|
| `$N/build/MilBridge/V80-t58-review.md`（本件） | 自指剔除口径见 §10 | — | 2026-09-28 12:3x |

## 10. 自报 sha16
```
$ grep -v '^> SELFSHA' build/MilBridge/V80-t58-review.md | sha256sum | cut -c1-16
```
（正文不含自 sha 数字；现取值见交件回复。）
