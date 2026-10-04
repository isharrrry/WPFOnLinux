# V80 · `t60` 独立复核报告（round 2）

**task `t61` / attempt `77c532c5-c4f5-46f9-bc20-871892148b09`｜lane=`janitor`｜2026-09-28 12:42:08–12:43:20（+0800）**
仓 `$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜`HEAD=9bbbf2c4dd0e0f4c87e92d4b63aca3a7910a29a0`｜`origin/feat-Linux == HEAD`｜`porcelain=0`
**立场**：不复述 `t58`／`t60` 的结论；每格我自己现取／自算。真树只读（唯一写入＝本报告）。夹具全在 `/tmp`（已删）。
**资源现取（12:42:08）**：`df -Pk /` 第 4 列 = **78,704,620 KB**（≥5 GB ✓）；`SwapFree` = **1,429 MB**（≠0 ✓）。

---

## 0. 判词

# **verdict = `needs_revision`**

**`t60` 对它被派的那一格（覆盖面 225→226）**做得**对且合规**（只增不改、原文保留、两笔推送、哨兵最后）。
**但同一件里还有一处同类陈旧计数没被它一并关掉**：`:136` 的 `declared=214 route_ids=214`（现取 **215**）—— 与 `t60` 刚更正的四处是**同一族、同一文件、同一波**，而 `t60` 的任务书恰恰要求「§1–§6 每一处改动都自己现取复核」。⇒ 1 条 finding（severity=medium）。
另：契约里「两哨兵 mtime 应 = `12:35:52`／最后一笔提交应 = `12:35:43`」**是错的**（那是 `#80` 冻结那一笔的时刻，不是本环最后一笔）—— 我按现取判定，见 §6。

---

## 1. ① §1–§6 现取对拍（逐项）

| 契约项 | **我现取**（12:42:08–12:42:50） | 件内 | 判 |
|---|---|---|---|
| `gen=#80` | `docs/CURRENT-STATE.md:9` = `> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=…` | `gen=#80` | **一致** ✅ |
| 块 sha16 | `sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = **`b96d4312565a3c49`** | `b96d4312565a3c49` | **一致** ✅ |
| 九位 9 值 | `bridge 4e25e4b27d4d5ae1`／`pc 5b6cfda3e12b84fc`／`pf b9a4f3a0e48e688d`／`windowsbase 9e860cbeecb352e1`／`provider 7e8a217b4165a6b9`／`win32shim 6825dd7071387a46`／`wic_shim f7b3026c8c019be2`／`hbtextline 921ba9c65e9fb3be`／`dwf c83be96f18759edc` | 同九值 | **逐位一致** ✅ |
| `inputs_fp` | 生产管线 `fp_inputs` = **`abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`** | 同值 | **一致** ✅ |
| 55 步 | `grep -c '^run_step "'` = **55** | `55` | **一致** ✅ |
| **覆盖面件数** | `verify-all.sh:1195` = `--expect **226**`；牙 `FP_MANIFEST_TEETH=PASS files_n=226 declared_expect=226` | **已改为 226（四处 dated 更正）** | **一致** ✅（`t60` 这一格**关掉了**） |
| **`declared`** | `DEFREG=PASS declared=**215** route_ids=215` | `:136` 写 `declared=**214** route_ids=214` | **❌ 不一致（本报告 finding）** |

### 1.1 `t60` 那四处的形态（我自己核）
`git diff --numstat 07c0a52 HEAD -- build/MilBridge/HANDOFF-NEXT.md` ⇒ **`8	0`**；`git diff` 里 **`^-` 计数 = 0**（**零删除**）、`^+` 计数 = **8**（两笔各 4 行）；hunk 头 `@@ -16,9 +16,13 @@` 与 `@@ -122,7 +126,11 @@` ⇒ **纯追加** ✅
件 sha16 链：`07c0a52` = `e236b2d38b81dab6` → `2420f28` = `20dee00047823045` → `9bbbf2c`（= 工作树）= **`ba5ae8f9049f6a92`**（271 行）⇒ 与 `t60` 自报**逐位相同** ✅
**原 `225` 四处原文仍逐字在场**（`:18`／`:23`／`:128`／`…`）+ 每处紧随两条 dated 行（`t60` 更正 ＋ 归因更正）✅；`grep -c 'gen=#77'` = **3**（留档原文未动）✅

## 2. ② 三节血逐字节未动（PRE = `t58` 落地态 `07c0a52`）

| 节 | PRE 行区间 → sha16 | NOW 行区间 → sha16 | 判 |
|---|---|---|---|
| **§绑定规则·跨会话有效** | `195–239` → **`f795c6bc7672dd9c`** | `203–247` → **`f795c6bc7672dd9c`** | **IDENTICAL** ✅ |
| **§0 队长起手页** | `180–194` → **`cb283ed2a8307843`** | `188–202` → **`cb283ed2a8307843`** | **IDENTICAL** ✅ |
| **§下一波未闭项** | `240–EOF` → **`655311b6d05fe334`** | `248–EOF` → **`655311b6d05fe334`** | **IDENTICAL** ✅ |

（行号整体平移 8 行 ＝ `t60` 两笔各 +4 行；内容三对全等。）

## 3. ③ `D-G180` 形态（我现取，`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:3666`）

- **house form 六要素齐**：现象（`README.md:180` 逐字 ＋ 两条独立机制）／根因（自动导入按搜索路径 vs 文档按目录归属）／证据（件＋字段＋sha16＋时刻）／判据（三条并列）／两极化（正极现树 vs 反极放回 ⇒ `MSB4236` ＋ 候选集 `88→180`）／口径句 ＋ 边界 ✅
- **`D-G179` 保留说明在正文**：`:3679` 逐字「**`D-G179` 已由队长保留**给另一条发现…**不是漏号**；本件按配号用 **`D-G180`**」✅
- **与相邻家族划界且未合并**：逐字列 `D-G174`／`D-G177`／`D-G136`／`D-G129` 四条并写「**本条讲的是**…不是同一件事」✅
- **既有条目零改动**：`KNOWN-DEFECTS.md` 在 `07c0a52` 的形态＝`3664a3665,3680`（纯追加 16 行）✅

## 4. ④ 两牙 ＋ 七锚 ＋ **215 的构成**（我自己跑／自算）

```
$ bash build/MilBridge/tools/defect-registry-check.sh
DEFREG_DECL=n=215 route_ids=215 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=2152460b7e412352 CS=13077b52c938f8af HO=a4d8ffcf4c37f6fe AB=b96d4312565a3c49
DEFREG_EXTRA=KRJ=6351a46296d17b28 KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-
DEFREG=PASS declared=215 route_ids=215（…无未声明编号）        rc=0

$ bash build/MilBridge/tools/report-id-domain-check.sh
BOOK_ENTRY_UNREQUIRED_MISSING n=16 ids=… **D-G179** …（**已登记的缺口：可见、不判红**）
BOOK_ENTRY_BINDING required=5 present=5 missing=0
REPORTID=PASS files=187 ids=1912 declared=215 glob=build/MilBridge/*report*.md
```
**七锚我逐件现算 = 表头 `# DECL-ANCHORS` 逐位相等**（7/7）✅

### 4.1 **`215` 的构成：`215 = 213 + D-G179 + D-G180`** —— 我复现并判"**预期结果**"，但 `D-G179` 那半是**具名缺口**（不是绿）
- **`215` 我现取**：`grep -c '^ID' build/MilBridge/tools/defect-registry-declared.tsv` = **215** ✅
- **`213` 我复算**：`git show 8137240:…defect-registry-declared.tsv | grep -c '^ID'` = **213**（`t58` 的**父提交**）；且该版 **`D-G179` 命中 0** ⇒ `213` 是**D-G179 与 D-G180 都还没有**时的值 ✅
- **两件都在声明表里**：`:110` = `ID	D-G179	req=KD	present=KD`｜`:112` = `ID	D-G180	req=KD	present=KD` ✅
- **条目数对拍**：`KNOWN-DEFECTS.md` 里 **`### 🆕 … D-G180` 标题 = 1**（`:3666`）；**`D-G179` 标题 = 0**（只有 `:3679` 一处**提及**）⇒ **`D-G179` 是"提及即声明"**，与契约描述一致 ✅
- **牙的处置**：`BOOK_ENTRY_UNREQUIRED_MISSING` **列了 `D-G179`**（n=16，逐字在册）⇒ 该缺口**可见、不判红** ✅
**⇒ 判定**：`215` 是**预期结果**（213 基线 ＋ 本波两号），**不是**计数缺陷；但必须写明 **`D-G179` 落在 `BOOK_ENTRY_UNREQUIRED_MISSING` 里**——它是 `D-G179` "保留号"的**第二个现成实例**：声明表里**有号**、册里**只有提及、没有成条**，牙把"要成条而没条目"**具名列出**。**不许把它读成"已入册合规"**。

## 5. ⑤ 冻结面零改动

| 项 | 现取 | 判 |
|---|---|---|
| 块件 | `sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = **`b96d4312565a3c49`** | ✅ |
| `CS:9` | `> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=…` | ✅ 仍 `gen=#80` |
| 块件 git 历史 | `git log --oneline -3 -- samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` ⇒ **最新一笔 = `57cd937 t80: 波 #80 收口冻结（基线 901619543b3d913b → b96d4312565a3c49）…`**，其下依次 `6a245bd`／`f4c93e5`（`#78` 时代） | ✅ **`#80` 冻结后无任何提交改过块件**（`t58`/`t59`/`t60` 三笔均不在该件历史里） |
| `porcelain` | **0** | ✅ |

## 6. ⑥ 次序判词：**成立** —— 但**契约预期的两个时刻是错的**，我按现取判

| 契约预期 | **我现取** | 说明 |
|---|---|---|
| 两哨兵 mtime 应 = `12:35:52` | **`/tmp/bridge-frozen.flag` = `2026-09-28 12:41:30.592134855`**｜`~/wfp-runs/bridge-frozen.flag` = **`12:41:30.594134843`** | 契约那个 `12:35:52` 是 **`#80` 冻结那一笔**（`07c0a52` @ `12:35:43`）之后的哨兵时刻；**本环最后一笔是 `t60` 的 `9bbbf2c` @ `12:41:15`**，其哨兵 = `12:41:30` ⇒ **晚 15 s** ✅ |
| 最后一笔提交应 = `12:35:43` | **`git log -1 --format=%cI` = `2026-09-28T12:41:15+08:00`**（`9bbbf2c`） | 同上，契约用的是上一环的值 |
**内容四键对拍**：`WAVE=w80-freeze`｜`BASELINE=#80`｜`BASELINE_SHA16=b96d4312565a3c49` ⇒ **＝ 块件现算 ＝ `CS:9`**（三者同一）✅
**两哨兵**：`cmp` **IDENTICAL**（均 279 B，sha16 均 **`f2ab94d32b8e1e40`**）✅
**"其后无其它动件"我做了机器核**：把 `fp_inputs()` 现取名单里的**每一件**逐件 `stat -c %Y` 与 `12:41:30` 比较 ⇒ **没有任何覆盖面内件在哨兵之后被写过** ✅（⇒ `t60` 的"哨兵是最后一个动件"**在它那一环成立**）
**反例判定口径**（按契约给出）：① 哨兵 mtime **< 最后一笔提交** ⇒ 不是最后动作；② 哨兵之后**任何**写盘（新 `M`／`??`、或覆盖面内件 mtime 后移）⇒ 哨兵须在该写盘之后重写；③ **文本写入与动件写入同等**使哨兵失去资格（本仓取严）⇒ 故**我交报告后重写两哨兵**。

## 7. 🔴 FINDING F1（severity=medium）：`:136` 的 `declared=214` 是同一族陈旧计数

```
file: build/MilBridge/HANDOFF-NEXT.md
line: 136
现取原文: | §4 登记册 | `declared=155` | **`declared=214 route_ids=214`＋`DECLDRIFT=0`** |
problem:
  · 我现取 `DEFREG=PASS declared=215 route_ids=215`（`DEFREG_DECL=n=215 route_ids=215` 同值）
    ⇒ 该行的"现值"格写 214，**差 1**。
  · 该值**不是任何历史态**：`t58` 的父提交 `8137240` 的声明表 ID 数 = **213**；
    `t58` 自己的提交 `07c0a52` = **215**。⇒ `214` **既不是改前值也不是改后值**，是**它自己算错/抄错的一个中间数**。
  · 出处：全仓 md 里只有两处 `declared=214` —— 本件 `:136` 与**我上一轮的报告**
    （`build/MilBridge/V80-t58-review.md:119`，那里我写的是"**契约**验收写 214、现场是 215"）
    ⇒ `t58` 把**自己引用的契约数**当成了"现值"填进表格。
  · 与 `t60` 被派的四处**同族同文件同波**：任务书要求「§1–§6 每一处改动都自己现取复核」，
    `:136` 属 §6 一览表、且在 `t58` 的改动集内 ⇒ **该关而未关**。
requiredFix:
  · 在 `:136` **只增不改**追加 dated 更正行（保留 `214` 原文），写明：
    现取 ＝ **`DEFREG=PASS declared=215 route_ids=215`**（`DEFREG_DECL=n=215 route_ids=215`）＋`DECLDRIFT=0 keys=-`；
    并写明 `215 = 213 + D-G179 + D-G180`（213 = `t58` 父提交 `8137240` 的 ID 数）与
    **`D-G179` 属"提及即声明"、落在 `BOOK_ENTRY_UNREQUIRED_MISSING`（可见、不判红）**。
  · 一并按同一体例复核 §6 一览表的**其余格**（至少 `declared` 与 `porcelain` 两格）是否还有同类陈旧值。
  · **不许**改 `verify-all.sh`／`#80` 冻结块／任何牙判据。
```

## 8. 我没能证明的 / 边界

1. **`t60` 的 sentinel 时刻我按 mtime 现取**（`12:41:30.592/.594`），**未**核它"写入两地的顺序是否原子"（单次事后 `stat` 不能回溯证明原子性）—— 记 `NOINFO`。
2. **`214` 的确切生成路径（谁在何时算出的）**：我只能证它**不等于任何历史态**（213／215 两个提交值都取过）＋**出处是"引用了契约数"**；**无法**回溯它是手算还是工具输出 ⇒ 归因 `NOINFO`，但"它是陈旧/错误值"**已由现取+git 历史双层证明**。
3. 契约预测的两个哨兵/提交时刻**与现场不符**（见 §6），我按**现取**判定并具名**契约那一处是缺陷**（不是被测件的缺陷）。
4. **真树只读**：我的唯一写入＝本报告；`/tmp` 夹具已删净。

## 9. 产出与自报 sha16
| 件 | sha16 | 字节 |
|---|---|---|
| `$N/build/MilBridge/V80-t60-review.md`（本件） | 见旁车件 `~/w-t61-review.sha16` | 见旁车件 |
（正文不含自 sha 数字，以免自指恒动。）
