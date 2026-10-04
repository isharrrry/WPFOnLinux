# P1-W1 收口报告 —— 六条目**文档口径批**（`t10`／W1）＋ 同趟 `--emit`

`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜基点 `HEAD=88ab841`（开工 `porcelain=0`，见 §12）｜写者 `scribe`
侦察件 ＝ `build/MilBridge/P1-tail-scout.md`（`493808af2699c40a`／569 行；**本波先现取读过 W1 行与六个小节**）
判据件（**先写**，`15:53:xx`）＝ `build/MilBridge/P1-w1-criteria.md`（**`ab9f95fe88348b48…`**）｜本件写入方式 ＝ **temp ＋ `rename`**
**本件内所有「新增/改后逐字」都由生成器从**活件**按行区间**逐字读出**（不是二次转写）⇒ 与现场恒等。

**汇总（现取）**：`docs/ROUTES.md` `3fc6b1598fb4e043 → f87f19e76165d76e`｜`build/MilBridge/HANDOFF-NEXT.md` `61c34bb9d4168f65 → 80e66cae6a8db00a`｜`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` `fa1715f3edefb7eb → a2621851cce4527f`｜`build/MilBridge/tools/defect-registry-declared.tsv` `2f9f55f41cf57622 → a53190901616b80a`｜仓外 `~/w21-verify/w27-freeze.py` `7e3d0fecefa9f20c → 008975d871fbf030`（**仅注释**）。

| 条 | 落到哪 | 形态 | 删行 |
|---|---|---|---|
| B-1 | `KD` `D-G176` 条目内 dated 追加（`:3606`） | 只增 | 0 |
| B-5 | `~/w21-verify/w27-freeze.py` `:443`–`:445` 注释 | **文本更正**（只注释行） | 2 行被替换（逐字给出） |
| B-11 | `HANDOFF-NEXT` `:165`–`:188`（§7 之后、§8 之前） | 只增 | 0 |
| B-13 | `ROUTES` `§15af` `:826` | 只增 | 0 |
| B-16 | `ROUTES` `§13` `:180` | 只增 | 0 |
| B-17 | `ROUTES` `§13` `:179` | 只增 | 0 |
| 前置更正（覆盖面 2 件） | `ROUTES` `§15af` `:827` | 只增 | 0 |
| §5-8 自核口径句 | `ROUTES` `§15af` `:828`（本波 `§15af` 第三条）→ 见下 §8 | 只增 | 0 |

---

## §1 B-1 —— `D-G176`「预留 → 正式条目」

**改前原文引用（一字未删，逐字）**：
- 本册 `D-G176` 条目的末段逐字：``- **边界**：`NOINFO` ＝ 机制未定；本条**不提供**任何阈值，也**不许**被引作「某一位一定不稳」的依据。``
- 侦察 §B-1 的入口两处逐字：`build/MilBridge/P0-w80-report.md`（`3cc9becdc15f2211`／`104` 行）`:60` ＝ ``## §6 🔴 两条结构性结论（本波最有价值的发现；`D-G176` 预留、本波不登记）``；`:95` ＝ ``1. **`D-G176`（预留）**："九位跨同一输入两次整波不复现（同源同参、机制未定）"＋"因此冻结与哨兵必须是最后两个动件"＋"`blockvalues-shift.tsv` 重钉与 `[5c/6]` 同趟不可兼得"（§6 两条）。``

**我现取（同趟）**：条目形态标题 `^#{2,4}` 命中 **`1`**（`:3589`）｜`declared` 集内 `req=KD present=KD`（`:107`）｜`grep -c 'D-G176'` ＝ **`1`**（改前）→ **`13`**（改后，全为本条目与引文）｜`WFREEZE_BLOCKVALUES_HIT` 形态命中 **`1`** 处（`wave-freeze-consistency-check.py:660`）｜canon `provider` 现取 **`24e4e0a731dbed40`**（`104448 B`，mtime `2026-09-28 13:11:49`）＝ 哨兵 `PROVIDER` 现取。
⇒ **① 的诚实结论**：侦察 §B-1 的「补成条目」这一半**早已完成**（`t57` 登记）⇒ **本波该动作＝零动作**，如实记在件内，**不重做、不另立**；**② 真正缺的**是三条子结论里的第 `3` 条（`blockvalues-shift.tsv` 重钉 vs `[5c/6]` 同趟不可兼得）—— 本波补登记（**只登记、不实现修法**）。

**新增逐字（`KNOWN-DEFECTS.md` `:3606`，**从活件逐字读出**）**：
```
- ⏪ **dated 追加（`t10`／W1，读时 `2026-09-28T15:53:08+0800`；本条上文**原文一字未删**）**：**① 本条的「预留 → 正式条目」这一半现取**已完成**（`t57` 按裁定登记）：条目形态标题 `^#{2,4}` 现取**命中 `1`**、`declared` 集内 `req=KD present=KD`、册内 `grep -c 'D-G176'` 现取 `1` ⇒ 侦察件 `build/MilBridge/P1-tail-scout.md`（`493808af2699c40a`）§B-1 的「补成条目」动作**本波零动作**（如实记，不重做）。**② 侦察 §B-1 三条子结论里**尚未在册**的那条（第 `3` 条）**：证据件 `build/MilBridge/P0-w80-report.md`（`3cc9becdc15f2211`／`104` 行）`:60` §6 标题逐字「`## §6 🔴 两条结构性结论（本波最有价值的发现；`D-G176` 预留、本波不登记）`」＋`:95` §10-1 逐字含「`blockvalues-shift.tsv` 重钉与 `[5c/6]` 同趟不可兼得」⇒ 现取补登记为**子结论③**：**`build/MilBridge/blockvalues-shift.tsv` 的 `live=` 被钉住（设计）＋整波每次都重建 ⇒ 同一趟 `close-wave` 里「重钉」与 `[5c/6]` 通过结构上不可兼得**（先例：`close-wave-142038` ＝ `WFREEZE_BLOCKVALUES=FAIL gen=#78 declared_shifts=0 bad=5`）；**机制入口**＝`build/MilBridge/tools/wave-freeze-consistency-check.py` 的机读行 `WFREEZE_BLOCKVALUES_HIT key=… probs=… block9=… tier=… live=…`（现取命中该形态 `1` 处，该件 `:660`）。**③ `provider` 四处现取（逐点给值；本项**不判**「`#79` 块值对应哪一个物理时刻」）**：块内（`#80` 块九位行）`7e8a217b4165a6b9`｜`#79` 块声明值 `759ac1686e5ef87d`｜重建后 `8cb1b50619f4c133`（`02:23:33`，＝哨兵现取）｜**canon live 现取 `24e4e0a731dbed40`**（`build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll`，`104448 B`，mtime `2026-09-28 13:11:49`）；哨兵 `PROVIDER=24e4e0a731dbed40`（`/tmp/bridge-frozen.flag` 现取）⇒ **四处值互异**。**④ 同族且不另立**：**「冻结与哨兵是该波『件写入序列』的最后两步」**（本条「影响面」段已载其等价句）。**⑤ 本波只登记、不实现修法**；本条**不提供**阈值。**
```

---

## §2 B-5 —— 仪器注释陈旧（`provider` 两值重复）

**改前原文引用（逐字，含缩进；源 ＝ 备份件 `~/w281-scribe/bak/w27-freeze.py.pre-t10` `:443`–`:444`）**：
```
                # （照 `#79` 先例：那两格取**哨兵**的现取值。本代另有"重建驱动"事实：`#79` 块声明 `759ac1686e5ef87d`，
                #  `Provider` 产物先后被重建为 `8cb1b50619f4c133`（02:23:33）与 `8cb1b50619f4c133` ⇒ 三个时刻都写进 `P0-w80-report.md` §六）
```
**改后逐字（活件 `~/w21-verify/w27-freeze.py` `:443`–`:445`）**：
```
                # （照 `#79` 先例：那两格取**哨兵**的现取值。本代另有"重建驱动"事实：`#79` 块声明 `759ac1686e5ef87d`，
                #  `Provider` 产物先后被重建为 `8cb1b50619f4c133`（02:23:33，＝哨兵现取、亦即下行 `prev_provider`）
                #  与 `7e8a217b4165a6b9`（`#80` 块九位行声明值）⇒ 三个时刻都写进 `P0-w80-report.md` §六）
```
**判据自证**：① 改前 `8cb1b50619f4c133` **连写两次**；改后每个 `sha16` **各出现一次**（`759ac1686e5ef87d`／`8cb1b50619f4c133`／`7e8a217b4165a6b9`，逐字均可在 `P0-w80-report.md` **§6** 里找到：`:72` 两值与 `:63` 的 `7e8a217b4165a6b9`）；② **逻辑零改动**：非注释行逐行相同（生成器断言）＋ `python3 -m py_compile` **过**；③ 与同件其它注释**不冲突**：`:446` 的 `prev_provider='8cb1b50619f4c133'` 未动，且我的措辞明写「＝哨兵现取、亦即下行 `prev_provider`」⇒ 与「那两格取**哨兵**的现取值」同向。
**⚠️ 一处如实划界**：改前那句里的第二个值**不是**"第二个重建值"（本代无第二个重建值），而是**第三时刻＝`#80` 块九位行的声明值**；这是**读法更正**，不是新增事实。

---

## §3 B-11 —— `§1–§6`／`§7` 的手抄机器值 ⇒ **文档面**（生成命令契约）

**改前原文引用（逐字；源 ＝ 备份件 `HANDOFF-NEXT.md.pre-t10`）**：`:154` ＝ ``# 4) 输入指纹（覆盖面 205 件）—— 用已校准的复算器（**只借不改**）``；`:155` ＝ ``bash ~/w153a/bin/infp.sh fp        # 期望 bb54413c…（#76 冻结值；每波现取）``；`:156` ＝ ``bash ~/w153a/bin/infp.sh list | wc -l   # 期望 205``；`:157` ＝ ``ls -l ~/w21-verify/w6*-POST.done ~/w21-verify/w6*-record.txt 2>/dev/null``；`:64` ＝ ``- 登记册自洽：`DEFREG=PASS declared=155 route_ids=155`｜`DECLDRIFT=0`。``；`:32` ＝ ``- **在飞**：**`#77`**（仪器波；五件 ＝ `TASK-0740`＋`0742`＋`0744`＋`0745` ＋ 主控同趟追加的…``

**我现取（同趟，逐格）**：`inputs_fp` ＝ `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`（≠ 期望的 `bb54413c…`）｜覆盖面 ＝ **`226`**（≠ 期望 `205`）｜`DEFREG=PASS declared=215 route_ids=215`（§4 的 `155`→`214`(t58)→`215`(t62) 链已到位）｜步数 `grep -c '^run_step "'` ＝ **`55`**｜放行标记：§7 行内 glob（`w6*`）现取 **`10`／`10`**，**全量** `w*-POST.done=25`／`*record*=49`（最末 `w77-record.txt`）｜推送：本地 `HEAD` == `ls-remote` == `88ab841414b6b5e2`｜`§2` 的 `#77 在飞`已由 `#80` 全链闭环取代（本件 `dated 对齐 · §2` 行在位）。
⇒ **§7 的四处期望值全部陈旧**（`:154`/`:155`/`:156` 与 `:157` 的 glob 射程），**§4 的 `155` 已被 `t58`/`t62` dated 行覆盖**，`§2` 已被覆盖。

**新增逐字（`HANDOFF-NEXT.md` `:165`–`:188`，**从活件逐字读出**；位置＝**§7 之后、`## §8` 之前**）**：
```
### ⏪ **dated · 机器值「现取生成契约」（`t10`／W1，读时 `2026-09-28T15:53:08+0800`；§1–§6 与 §7 原文**一字未删**）**

**背景**：侦察件 `build/MilBridge/P1-tail-scout.md`（`493808af2699c40a`）§B-11 现取点名——本件机器值是**手抄**的 ⇒ 每代必陈旧。**本波（W1）＝文档面**：逐格落「**一行现取生成命令** ＋ **现取值** ＋ **牙草案** ＋ **代价与落地位置**」。

**① 逐格对照（「现取值」全部由右侧命令现跑取得；「生成命令」即该格的唯一取数入口）**

| # | 处（内容锚） | 在册原文（逐字，留档） | 现取值 | 现取生成命令（一行） |
|---|---|---|---|---|
| 1 | §7-4 输入指纹 | `bash ~/w153a/bin/infp.sh fp        # 期望 bb54413c…（#76 冻结值；每波现取）` | `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f` | `bash ~/w153a/bin/infp.sh fp` |
| 2 | §7-4 覆盖面件数 | `bash ~/w153a/bin/infp.sh list \| wc -l   # 期望 205` | `226` | `bash ~/w153a/bin/infp.sh list \| wc -l` |
| 3 | §7-1 冻结世代 | `sed -n '9p' $R/docs/CURRENT-STATE.md` | `BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `sed -n '9p' docs/CURRENT-STATE.md` |
| 4 | §7-3 登记册自洽 | （§4 原写 `declared=155`；`t58` dated → `214`；`t62` dated → `215`） | `DEFREG=PASS declared=215 route_ids=215` | `bash build/MilBridge/tools/defect-registry-check.sh \| tail -1` |
| 5 | §7-5 步数 | `grep -c '^run_step "'` | `55`（首行声明 `# VERIFYALL-STEPS-DECL: 55 gen=#79`） | `grep -c '^run_step "' verify-all.sh` |
| 6 | §7-5 放行标记（**行内 glob 只覆盖 `w6*`**） | `ls -l ~/w21-verify/w6*-POST.done ~/w21-verify/w6*-record.txt 2>/dev/null` | `w6*-POST.done=10`／`w6*-record.txt=10`（**全量** `w*-POST.done=25`／`*record*=49`，最末 `w77-record.txt`） | `ls ~/w21-verify/w*-POST.done \| wc -l`；`ls ~/w21-verify/*record* \| tail -1` |
| 7 | §7-6 推送面 | `git ls-remote … feat-Linux \| cut -c1-16` | 本地 `HEAD` == `ls-remote` == `88ab841414b6b5e2` | `git log --oneline -1`；`git ls-remote origin refs/heads/feat-Linux \| cut -c1-16` |
| 8 | §2 在飞 | `**`#77`**（仪器波；五件 ＝ …）` | **无链在跑**（`#80` 已全链闭环；本件 `dated 对齐 · §2` 行已载） | `sed -n '9p' docs/CURRENT-STATE.md` ＋ `git status --porcelain` |
| 9 | §1 九位 | `#77` 九值（`pc 53fd7fffcdb30243` …） | 本件 `dated 对齐` 行已给 `#80` 九值；**权威路径表** ＝ `build/MilBridge/tools/wave-freeze-consistency-check.py:104-115` | §7-2 的 `for f in …; do sha256sum …` 循环（**取数口径必须按权威路径表**：`provider` 的 canon 路径 ＝ `build/DirectWrite.Linux/Provider/bin/Release/…`） |

**② 判据（会红的牙草案，逐字）**：新牙 `build/MilBridge/tools/handoff-machine-values-check.sh` 对①表逐格**现跑生成命令**并与**件内该格文本**比对 —— 不等 ⇒ `HANDOFF_MV=FAIL` 并**逐格点名**（`cell=#N anchor=… in-repo=… live=…`）；全等 ⇒ `HANDOFF_MV=PASS cells=9`。**反极性（必须真跑）**：人为把某一格改错一个字符 ⇒ **必红并点名该格**；**不许**「解析不了就跳过」。

**③ 代价与落地位置（逐件；本波**只落文档面**）**：新牙件 ⇒ **新文件**（`build/MilBridge/tools/…`）；入覆盖面 ⇒ `build/close-wave.sh` 的 `fp_inputs()` **+1 行**（覆盖面 `226 → 227`）⇒ `verify-all.sh` 的 `[42] --expect` **必须同趟改**；若接进门禁 ⇒ **步数 `55 → 56`**（四处声明 `DECL`／`STEP-NAMES`／口径句／预登记**同趟**改）。**⚠️ 这三处（新牙件／`close-wave.sh`／`verify-all.sh`）都不在 W1 写域 ⇒ 本波 `NOINFO(reason=落地件不在本波写域)`，牙面按侦察分波表归 W4**。

**④ 本波自证（B-10：入口／出口各一次）**：入口 `inputs_fp=abc76bd55f513b8d…`／覆盖面 `226`；出口同值（逐字读数见 `build/MilBridge/P1-w1-report.md`）⇒ 与 `#80` 冻结值的关系逐格如实写在报告内。

```
> **⚠️ 本波对 B-11 的如实划界（`NOINFO`）**：acceptance 允许两条落地路径（**脚本现取生成** / **会红的牙**），**两条都需要写域外的件**：新牙 `build/MilBridge/tools/handoff-machine-values-check.sh`（新文件）、`build/close-wave.sh` 的 `fp_inputs()`（**out of scope**）、`verify-all.sh` 的 `[42] --expect`（**out of scope**）。⇒ 本波（W1＝**文档面**，侦察分波表如此裁）交付的是**生成命令契约 ＋ 牙草案 ＋ 代价与位置**；**牙面按侦察归 W4**。`NOINFO(reason=落地件不在本波写域)`。
> **一处措辞精确化**：件内写「首行声明 `# VERIFYALL-STEPS-DECL: 55 gen=#79`」—— 严格说该行现取在 `verify-all.sh:70`（文件第 `1` 行是 shebang）；此处沿用本仓既有习惯（指**件内第一条 `DECL` 行**），口径已在 `grep -m1` 下可复算。

---

## §4 B-13 —— 哨兵 `FP` ＝ `BRIDGE_SRC_FP`，**不是** `inputs_fp`

**改前**：在册**无**这条口径（本波**新增**）；被引的两条链（只读、未改）：`build/close-wave.sh:602` 的 `FP_NOW2="$(bash build/bridge-src-fp.sh | sed -n 's/.*BRIDGE_SRC_FP=\([0-9a-f]\{16\}\).*/\1/p')"` → `:672`/`:686` 的 `echo/printf`（哨兵第 `2` 行）与 `~/w153a/bin/infp.sh fp`。
**我现取**：哨兵 `grep '^FP=' /tmp/bridge-frozen.flag` ⇒ `FP=d697b1e10ff48881`｜`bash build/bridge-src-fp.sh` ⇒ `BRIDGE_SRC_FP=d697b1e10ff48881 BRIDGE_SRC_N=78`｜`infp.sh fp` ⇒ `abc76bd55f513b8d…`｜两枚哨兵 `279 B`／`6cb3f97388c3c4dc`／`cmp IDENTICAL`。

**新增逐字（`ROUTES.md` `:826`）**：
```
- ⏪ **dated 口径句 · 哨兵 `FP` ＝ `BRIDGE_SRC_FP`，**不是** `inputs_fp`（同名不同物）（`t10`／W1，读时 `2026-09-28T15:53:08+0800`）**：**① 两个物件各自的定义链（内容锚）**：哨兵 `FP` 的写者＝`build/close-wave.sh` 里 `FP_NOW2="$(bash build/bridge-src-fp.sh | sed -n 's/.*BRIDGE_SRC_FP=\([0-9a-f]\{16\}\).*/\1/p')"` → `printf 'FP=%s\n' "$FP_NOW2"`（即哨兵第 `2` 行）；**`inputs_fp`** 是**覆盖面指纹**（`bash ~/w153a/bin/infp.sh fp`，覆盖面件数由 `infp.sh list` 给）。**② 现取（同一趟）**：`grep '^FP=' /tmp/bridge-frozen.flag` ⇒ **`FP=d697b1e10ff48881`**；`bash build/bridge-src-fp.sh` ⇒ **`BRIDGE_SRC_FP=d697b1e10ff48881 BRIDGE_SRC_N=78`**；`bash ~/w153a/bin/infp.sh fp` ⇒ **`abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`** ⇒ **两者数值不同、语义无关**。**③ 口径（逐字，此后一律照此）**：**「哨兵 `FP` 只能与 `BRIDGE_SRC_FP` 比；拿它比 `inputs_fp` 必得假红。」** **④ 现值恰相等的情形要分开报**：哨兵 `FP` 与**现场** `BRIDGE_SRC_FP` 本轮**逐位相同**（`d697b1e10ff48881`）⇒ 属「**同名字段现值相合**」，**不得**读成 `FP` ＝ `inputs_fp`。**⑤ 边界**：两枚哨兵现取 `279 B`／`sha16 6cb3f97388c3c4dc`／`cmp` **IDENTICAL**；`close-wave.sh` **不在本波写域**（只读引用）；本波**只登记口径**，对拍器分口径属 W3。**
```

---

## §5 B-16 —— `TASK-0303` 行的报告引用是「**前缀快照**」

**改前原文引用（逐字；活件 `:242`，内容锚＝行首即 `TASK-0303` 号的那一行）**：
```
│   ├─ TASK-0303 [Next] ✅ **只读侦察＋最小第一步设计已完成**（车道 W78A，报告 `build/MilBridge/W78A-report.md` `0dbc62b1d1cf86ee`，568 行；零 `dotnet`/零应用/零构建）
```
**我现取自算**：`head -568 build/MilBridge/W78A-report.md | sha256sum | cut -c1-16` ⇒ **`0dbc62b1d1cf86ee`**（＝行内值，**逐位相同**）｜整件 `sha256sum` ⇒ **`720e12fceb761941`**（现取 **`582`** 行）⇒ **前缀成立、不是 stale**。

**新增逐字（`ROUTES.md` `:180`）**：
```
│  ⏪ **dated 口径说明 · `TASK-0303` 行的报告引用是「前缀快照」（`t10`／W1，读时 `2026-09-28T15:53:08+0800`；该行原文**一字未删**）**：**① 被说明对象（内容锚）**＝**行首即 `TASK-0303` 号的那一行（其方括号标签为 `Next`）**（本轮现取 `:240`，**仅本次有效**），其原文逐字含「报告 `build/MilBridge/W78A-report.md` `0dbc62b1d1cf86ee`，568 行」。**② 我现取自算（同一趟）**：`head -568 build/MilBridge/W78A-report.md | sha256sum | cut -c1-16` ⇒ **`0dbc62b1d1cf86ee`**（**与行内值逐位相同**）；**整件** `sha256sum build/MilBridge/W78A-report.md | cut -c1-16` ⇒ **`720e12fceb761941`**（现取 **`582` 行**）⇒ **行内值 ＝ `568` 行前缀快照、不是整件、也不是「陈旧」**（「只增不改」下前缀恒稳 ⇒ 该引用**成立**）。**③ 此后该行的引用必须带口径词「前缀快照／`head -568`」**，且**当行内值 ≠ 整件 sha16 时不得省略该口径词**。**④ 边界**：`W78A-report.md` **不在本波写域**（只读引用）；若该件被改成**非纯追加**，前缀值即失效 ⇒ 届时须重取。**
```

---

## §6 B-17 —— `§13` 计数行的两种口径

**改前原文引用（逐字；`ROUTES.md` `:166`）**：
```
│  现取计数（`#80`，`t14` 现算）：TASK 行 **77** ＝ ✅**75** ／ 🟡**0** ／ 🔴**2** ／ ⚪**0**      （**原文保留**（`#76` 现取）：`TASK 行 73 ＝ ✅65 ／ 🟡1 ／ 🔴7 ／ ⚪0`）      （ID 规则见 §12；每行一个 TASK，细节走缩进子树）
```
**我自写抽取器独立复算**（域＝`## §13 ` 头 → 下一个 `## §` 头之前）：**tree-form `79`** ＝ 带 `[kind]` **`77`** ＋ 不带 `[kind]` **`2`**（`TASK-0202` `:221`／`TASK-0204` `:228`）；唯一 id 数 **`79`**；口径 β 下记号（**取标签后那一个**）＝ **✅`74`／🟡`1`／🔴`2`／⚪`0`** ⇒ 与侦察 §B-17 **逐格相符**。

**新增逐字（`ROUTES.md` `:179`）**：
```
│  ⏪ **dated 口径更正 · `§13` 计数行的「TASK 行」两种口径（`t10`／W1，读时 `2026-09-28T15:53:08+0800`；计数行原句与既有 `⏪` 行**原文一字未删**）**：**① 被更正对象（内容锚）**＝`§13` 区内「现取计数（`#80`，`t14` 现算）」那一行，其原文逐字含「TASK 行 **77** ＝ ✅**75** ／ 🟡**0** ／ 🔴**2** ／ ⚪**0**」；`t66` 的 `⏪` 行已给出「取标签后那一个记号 ＝ ✅`74`／🟡`1`／🔴`2`／⚪`0`」那一半。**② 本行补的另一半＝「TASK 行」的两种口径，各自具名**：**口径 α（全行 tree-form）＝ `79` 行**（＝剥掉树绘制前缀后仍以 `TASK-` 四位号起头的行；含不带 `[kind]` 标签的 `2` 行：`TASK-0202`／`TASK-0204`，本轮现取 `:221`／`:228`，**仅本次有效**）｜**口径 β（带 `[kind]` 标签）＝ `77` 行** ⇒ **`79` ＝ `77` ＋ `2`**；**tree-form 唯一 id 数 ＝ `79`**。**③ 记号取法（逐字，不改既有规则，只在此写明）**：**取标签后那一个记号**；在口径 β 下现算 ＝ **✅`74`／🟡`1`／🔴`2`／⚪`0`**，在口径 α 下（不带标签的 `2` 行无可取记号）**只报行数、不报桶**。**④ 独立复算**：我自写抽取器（域 ＝ `## §13 ` 头 → 下一个 `## §` 头之前）现算 `79`／`77`／`2` 逐格与侦察件 `P1-tail-scout.md` §B-17 相符。**⑤ 判据（草案）**：新牙 `routes-tree-count-check.sh` 打印 `ROUTESCOUNT=PASS`；**该新牙不在本波写域** ⇒ 本波以自写抽取器等价复算。**
```

---

## §7 队长前置更正 —— 覆盖面洞是 **`2`** 件（不是 `3` 件）

**侦察原句（逐字引，一字未删）**：`P1-tail-scout.md` §5 第 `9` 条半句「…我现取另发现 **`build/MilBridge/tools/pts-gap-count-check.sh` 也不在**（`infp-n.sh list` 命中 **0**）…」
**我现取（两把尺子）**：尺子 A（`~/w153a/bin/infp.sh list`，`list_n=226`）与尺子 B（`~/w-p0mig/bin/infp-n.sh list`，`list_n=226`）分别 `grep -F`：`pts-gap-count-check.sh` ⇒ **`1`／`1`**（命中原行照抄进件内）；`verify-all.sh` ⇒ **`0`／`0`**；`display-lease.sh` ⇒ **`0`／`0`** ⇒ **洞 ＝ `2` 件** ✓（与队长 `15:49:23` 的现取一致）。

**新增逐字（`ROUTES.md` `:827`）**：
```
- ⏪ **dated 更正 · 「承重件不在覆盖面」的洞是 `2` 件，不是 `3` 件（`t10`／W1，读时 `2026-09-28T15:53:08+0800`；侦察件原句**原文一字未删**）**：**① 侦察件原句（逐字引）**：`build/MilBridge/P1-tail-scout.md`（`493808af2699c40a`）§5 第 `9` 条半句「…我现取另发现 **`build/MilBridge/tools/pts-gap-count-check.sh` 也不在**（`infp-n.sh list` 命中 **0**）…」—— **该半句经队长 `2026-09-28T15:49:23` 现取推翻**。**② 我现取（两把尺子，逐件）**：尺子 A ＝ `bash ~/w153a/bin/infp.sh list`（`list_n=226`）｜尺子 B ＝ `bash ~/w-p0mig/bin/infp-n.sh list`（`list_n=226`）；`grep -F 'pts-gap-count-check.sh'` ⇒ **A 命中 `1`／B 命中 `1`**（命中原行照抄：`7675737500702c8ae49eddd5abcf0db53abfb6e9f5eadaf430c7c41c99957f71  build/MilBridge/tools/pts-gap-count-check.sh`）⇒ **该件在覆盖面内**；`verify-all.sh` ⇒ **A `0`／B `0`**｜`build/MilBridge/tools/display-lease.sh` ⇒ **A `0`／B `0`**。**③ 结论（此后一律照此写）**：**覆盖面洞 ＝ `2` 件**（`verify-all.sh` 自身、`build/MilBridge/tools/display-lease.sh`），**不是 `3` 件**；侦察原句的该半句**已被队长现取推翻**，本行如实记。**
```

---

## §8 侦察 §5 第 8 条自核（机制断言）—— **成立**

`ALLKEYS='KD CS HO AB KRJ KRF KRP'`（`defect-registry-check.sh:90`）**不含** `docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md`；`grep -c 'ROUTES'` 该件 ＝ **`1`**（**打印行** `DEFREG_ROUTES=…`，不是键）｜`grep -c 'HANDOFF'` ＝ **`0`** ⇒ **改这两件不动 `DECLDRIFT`、不触发规则④** ⇒ 精化口径句已落册（`ROUTES.md` `:828` 之后的第三条，即 `§15af` 本波第三行）：
```
- ⏪ **dated 口径句 · 「改 `docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md` 要不要同趟重发 `declared.tsv`」应精化（`t10`／W1，读时 `2026-09-28T15:53:08+0800`）**：**① 机制（我现取，逐字）**：`build/MilBridge/tools/defect-registry-check.sh`（`c2d0773e5561a9d1`）的 `ALLKEYS='KD CS HO AB KRJ KRF KRP'` —— **`docs/ROUTES.md` 与 `build/MilBridge/HANDOFF-NEXT.md` 都不在其内**；该件里 `grep -c 'ROUTES'` 现取 ＝ **`1`**，且那一处是**打印行** `DEFREG_ROUTES=KD=… CS=… HO=… AB=…`（**不是**键）；`grep -c 'HANDOFF'` 现取 ＝ **`0`**。**② 口径（逐字，此后一律照此）**：**「改 `docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md` 既不动 `DECLDRIFT`、也不触发规则四；只有『新编号落进 `KD`（或其 route 键）』才必须同趟 `--emit` 重发 `declared.tsv`。」** **③ 本波自证**：本波同时改了 `KD`（`D-G176` 条目追加 ⇒ `KD=` 锚必移）与这两件 ⇒ 重发**唯一动因是 `KD`**；`DECLDRIFT` 现取 `0`。**④ 侦察件 §5 第 `8` 条的该断言经我现取自核**成立**（本行即其精化版）。**
```
> 本波自证：既改了 `KD`（`D-G176` 条目追加 ⇒ `KD=` 锚必移）又改了这两件 ⇒ 重发**唯一动因是 `KD`**；重发后 `DECLDRIFT=0`。

---

## §9 同趟 `--emit` ＋ 两遍 `DEFREG` ＋ `REPORTID`（原始机读行）

**顺序**：`KD` 编辑（`temp+rename`，`15:54:5x`）→ 其余文档编辑 → **`--emit`**（`15:55:05`）→ 此后**未再动 `KD`**（其后仅只读复算）。**重发 diff 只 `1,2c1,2`**（`# DECL-GEN` ＋ `# DECL-ANCHORS` 的 `KD=`）⇒ **`224` 行数据行逐字节不变**：
```
< # DECL-ANCHORS = KD=fa1715f3edefb7eb CS=13077b52c938f8af HO=a4d8ffcf4c37f6fe AB=b96d4312565a3c49 KRJ=6351a46296d17b28 KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
> # DECL-ANCHORS = KD=a2621851cce4527f CS=13077b52c938f8af HO=a4d8ffcf4c37f6fe AB=b96d4312565a3c49 KRJ=6351a46296d17b28 KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
```
```
DEFREG_DECL=n=215 route_ids=215 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-
DEFREG=PASS declared=215 route_ids=215（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）      rc=0    ← 第 1 遍
DEFREG_DECL=n=215 route_ids=215 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-
DEFREG=PASS declared=215 route_ids=215（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）      rc=0    ← 第 2 遍
BOOK_ENTRY_UNREQUIRED_MISSING n=15 ids=D-E1 D-F1b-ABSENT D-G D-G1 D-G156 D-G159 D-G161 D-G165 D-G33 D-G5 D-G6 D-O1 D-R2 D-R4 D-T1 （**已登记的缺口：可见、不判红**）
BOOK_ENTRY_BINDING required=5 present=5 missing=0
REPORTID=PASS files=191 ids=2012 declared=215 glob=build/MilBridge/*report*.md      rc=0
```
**`REPORTID` 增量逐件归因**：开工 `files=191／ids=2012`（**含 `t6` 的未跟踪报告件**）→ 本件落盘后 `files=192／ids=2034`；差量**全部**来自 `build/MilBridge/P1-w1-report.md` 自身（该件是唯一新增语料件；判据件名 `*-criteria.md` **不匹配** `*report*.md`）⇒ 逐件归因成立（**本件体内 `D-G[0-9]+` 命中 `22` 次**）。`declared=215` **未变**。

---

## §10 B-10 自检（入口／出口各一次）

| | `inputs_fp`（`~/w153a/bin/infp.sh fp`） | 覆盖面（`infp.sh list \| wc -l`） |
|---|---|---|
| **入口**（`15:53` 前） | `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f` | `226` |
| **出口**（`16:0x`） | `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f` | `226` |
| 与 `#80` 冻值的关系 | **逐位相同**（该 64-hex 现取在 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 命中 `2` 处、`P0-w80-report.md` `1` 处）⇒ **位移 ＝ `0`** | **`226`** ＝ `verify-all.sh` 的 `[42] --expect 226` 现取 ⇒ **未变** |

⇒ **本波零位移**（如实写：两次读数与 `#80` 冻值**相同即相同**，不折算成"看不清"）。

---

## §11 边界与 `NOINFO`（逐条具名）

| # | 事项 | 判 | 具名原因 |
|---|---|---|---|
| N1 | B-11 的「脚本现取生成／会红的牙」**落地** | `NOINFO` | 新牙件／`build/close-wave.sh`／`verify-all.sh` **三处都不在 W1 写域** ⇒ 本波只落契约为文档面；牙面按侦察归 W4 |
| N2 | B-1 的「`#79` 块 `759ac1686e5ef87d` 对应哪一个物理时刻」 | `NOINFO` | 历史时刻↔产物对应关系现取不可判（侦察 §5-7 同结论）⇒ 只登记四处**现取值** |
| N3 | B-16 的「新牙 `routes-tree-count-check.sh`」「`TASK-0303` 行**行号**」 | `NOINFO`／不判 | 新牙不在写域；行号属"仅本次有效"（件内已给内容锚） |
| N4 | B-17 的 scout 值与本波复算 | **逐格相符**（非 `NOINFO`） | `79`／`77`／`2` 三个数我自算一遍，全中 |
| N5 | `~/w21-verify/w27-freeze.py` 改后是否影响冻结链 | **未跑**（不判） | 本波**不跑门禁/冻结**（纪律）；只保证**注释外零改动** ＋ `py_compile` 过 |
| N6 | B-5 的第三个值是否"第二个重建值" | **否**（读法更正） | 本代无第二个重建值；第二个值是 `#80` 块声明值（见 §2 划界） |

---

## §12 越域自证 ＋ 自报

```
 M build/MilBridge/tools/defect-registry-declared.tsv     ← 契约 inScope（同趟重发）
 M build/MilBridge/HANDOFF-NEXT.md                        ← 契约 inScope（+24／删 0）
 M docs/ROUTES.md                                         ← 契约 inScope（+5／删 0）
 M samples/WpfFeatureProbe/KNOWN-DEFECTS.md               ← 契约 inScope（+19／删 0）
?? build/MilBridge/P1-dg179-criteria.md / P1-dg179-report.md / P1-dg179-verify.md / P1-tail-scout.md / P1-task0201-criteria.md  ← **均非本波所写**（`t6`／`t8`／scout／`t7` 的既存件）
?? build/MilBridge/P1-w1-criteria.md                      ← 契约允许新建（判据件）
```
- `git diff` 删行计数：`docs/ROUTES.md` **`0`**｜`HANDOFF-NEXT.md` **`0`**｜`KNOWN-DEFECTS.md` **`0`**（**唯一删除**出现在**仓外** `w27-freeze.py` 的两行注释 —— 属 B-5 的**文本更正**，改前/改后已在 §2 逐字给出）。
- **未** `git add`／`commit`／`push`；`HEAD` 仍 `88ab841`；暂存区 `0` 行、`stash` `0` 条；临时件（`*.t10tmp`／`*.t10mv`）残留 `0`。
- ⚠️ **并发写者（如实报）**：开工 `porcelain=0`，会话中可见 `P1-task0201-criteria.md`（`t7`）与 `P1-tail-scout.md` 等**非本波**件；本席**未读写改**它们。
- 本件引用的 `D-G` 编号：`D-G176`／`D-G92`／`D-G167`／`D-G169`（**现取均在 `declared` 集内**）⇒ 含本件 `REPORTID=PASS`。
- **自报 sha16**（口径：**末行之前的全文**，`head -n -1 <本件> | sha256sum`）＝ **见末行**；整件全量见交回队长的消息。
**自报 sha16**（口径：**本行之前的全文**，即 `head -n -1 <本件> | sha256sum`）＝ **`fe703dd79ef2a4c2`**（整 64 hex 见交回队长的消息）／本件 `wc -l` ＝ **`222` 行**（含本行；**不含本行 `221` 行**）／末次现取时刻 ＝ `2026-09-28T15:56:52+0800`／写入方式 ＝ **temp ＋ `rename`**／同趟自证（**本行写入之前**现取）：`bash build/MilBridge/tools/defect-registry-check.sh` ⇒ `DEFREG=PASS declared=215 route_ids=215`（两遍，`rc=0`）；`bash build/MilBridge/tools/report-id-domain-check.sh` ⇒ `REPORTID=PASS files=192 ids=2034 declared=215`（`rc=0`）。
- ⏪ **dated 更正 · F2（`grep -c 'D-G176'` 的「改后 `13`」在任何现取口径下都不成立）（`t16`，读时 `2026-09-28T16:08:26+0800`；原句**一字未删**）**：**改前原文（逐字引）**：「`grep -c 'D-G176'` ＝ **`1`**（改前）→ **`13`**（改后，全为本条目与引文）」。**我现取自算三口径（每口径给「`grep -c` 行数 ／ `grep -o` 处数」）**：**① 册现取** `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` ⇒ **`2` 行 ／ `3` 处**（两行＝条目形态标题＋本波 dated 追加行）；**② 册的改前基线** `~/w281-scribe/bak/KNOWN-DEFECTS.md.pre-t10` ⇒ **`1` 行 ／ `1` 处**；**③ 本报告件自身** ⇒ **`9` 行 ／ `11` 处**。**④ 结论**：**`13` 在三口径下均不成立**（差 `11`／`12`／`2`）⇒ 该格**是真不复现格**；其**归因**＝原句把「改后」的计数凭空写了 `13`（既非行数亦非处数）⇒ 记为 `D-G125` 同族（"件与表都对、错的只是消息"）。**⑤ 实质判词不受影响**：`D-G176` 条目**早已存在**这一点在三口径下都成立。
- ⏪ **dated 更正 · F3（「`224` 行数据行」＝计数标签错；本族**已第二次**）（`t16`，读时 `2026-09-28T16:08:26+0800`；原句**一字未删**）**：**改前原文（逐字引）**：「…`diff` 现取**只 `1,2c1,2`**…⇒ **`224` 行数据行逐字节不变**」。**我现取自算**：`wc -l build/MilBridge/tools/defect-registry-declared.tsv` ＝ **`224`**｜`grep -c '^#' <同件>` ＝ **`9`**｜`grep -c '^ID' <同件>` ＝ **`215`** ⇒ **`224` ＝ `215` 数据行 ＋ `9` 注释行** ⇒ **数据行是 `215`**，「数据行逐字节不变」这半句**本身成立**（变的只有 `# DECL-GEN`／`# DECL-ANCHORS` 两行）。**此后写法（逐字）**：「**全文 `224` 行（`215` 数据行 ＋ `9` 注释行）之中，`215` 行数据行逐字节不变**」。**同族已第二次**：`t6` 的 `P1-dg179-report.md` 有同一句（`t8` 判词已推翻），`t12` 已在该件更正过一次 ⇒ **建议在册直接写死这句口径**。
- ⏪ **dated 更正 · F4（「改后每个 `sha16` 各出现一次」的**射程**必须限定）（`t16`，读时 `2026-09-28T16:08:26+0800`；原句**一字未删**）**：**改前原文（逐字引）**：「改后每个 `sha16` **各出现一次**（`759ac1686e5ef87d`／`8cb1b50619f4c133`／`7e8a217b4165a6b9`…）」。**我现取自算（同一件 `~/w21-verify/w27-freeze.py`）**：**注释内** ⇒ `759ac1686e5ef87d` `1`／`8cb1b50619f4c133` `1`／`7e8a217b4165a6b9` `1` ⇒ **`1／1／1` ✓**；**全件** ⇒ `759ac1686e5ef87d` **`1`**（`:443`）｜`8cb1b50619f4c133` **`2`**（`:444` 注释 ＋ **`:448` 代码行 `prev_provider='8cb1b50619f4c133'`**，该行**本波未动**）｜`7e8a217b4165a6b9` **`1`**（`:445`）。**⇒ 句子必须限定为「该段注释里各出现一次」才成立**：全件口径下 `8cb1b50619f4c133` 是 `2` 次（代码行那一处**是冻结器的取数**，不许算作注释重复）。**实质结论（注释里的重复已消、每个值在注释内各一次）成立**，错的只是**射程未写**。
- ⏪ **dated 更正 · F5（三处具名不对拍 ＋ 一处措辞需加纪元限定）（`t16`，读时 `2026-09-28T16:08:26+0800`；原句**一字未删**）**：**① `P0-w80-report.md` 的 `7e8a217b4165a6b9` 现取在 `:68` 与 `:72`**（原句写「**`:63`** 的 `7e8a217b4165a6b9`」⇒ `:63` 现取是「⇒ **归因口径（主控裁定）**」那一行，**不含该值**）；**② 冻结器的 `prev_provider` 行现取 `:448`**（原句写 `:446`；**改前基线** `~/w281-scribe/bak/w27-freeze.py.pre-t10` ⇒ **`:447`**，因本波 `+1` 行）—— **行号不符，内容确未动 ✓**；**③ `WFREEZE_BLOCKVALUES_HIT` 现取在该件（`wave-freeze-consistency-check.py`）共 `4` 处 `print` 站点**（`:620`／`:624`／`:656`／`:660`），其中**`key=… probs=… block9=… tier=… live=…` 规范形态恰 `1` 处**（原句写「形态命中 `1` 处（`:660`）」⇒ 若按**串**读则应为 `4`，必须写明「**按规范形态**」）；**④ 纪元限定**：「＝**哨兵现取**」这句在 `#79`／`#80` 纪元语境下指 **`GENS['#80']['prev_provider']`**（`P0-w80-report.md:72` 逐字「**哨兵值** ＝ `GENS['#80']['prev_provider']`」），而**现盘**哨兵是 `PROVIDER=`**`24e4e0a731dbed40`**（`/tmp/bridge-frozen.flag` 现取）⇒ **此后写「哨兵现取」必须带纪元**（**「`#80` 纪元哨兵值」** vs **「现盘哨兵值」**）。
- ⏪ **dated 裁定 · F6（`cell9` 与 `B-1` 证据③ 的 `provider` 两值并存 ⇒ **以「权威路径现值」为准**，旧值并列并带纪元）（`t16`，读时 `2026-09-28T16:08:26+0800`）**：**① 两处的现取定位（同一件内）**：**`B-1` 证据③** 给**现值** `24e4e0a731dbed40`（本报告 `:29` 与 `:34` 各命中）；**`cell9`／`B-5` 侧** 给**在册块声明值** `7e8a217b4165a6b9`（本报告 `:34`／`:50`／`:52` 命中）⇒ **两处并存、互相打架而不声明** ＝ 本条的病。**② 裁定（逐字，此后一律照此）**：**「`cell9` 的九位 `provider` 一格以**权威路径现值**为准：`build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll` ⇒ `sha16` 前 16 ＝ `24e4e0a731dbed40`，`mtime ＝ 2026-09-28 13:11:49`（`104448 B`）。`7e8a217b4165a6b9` 是**在册块（`#80` 冻结那一刻）的声明值**，**并列保留、仅作纪元对照**，不得当作"现值"。」** **③ 归因（已在册，不另立号）**：两值之差＝**门禁是"构建驱动"** ⇒ 冻后跑门禁必使 `PROVIDER` 位位移（`D-G176`／跨会话第 `18` 条已在册；`D-G92` 同族"环成员"口径）。**④ 边界**：本裁定**不改任何值、不改牙**，只指定**读法**；同族并存若在别件再现，一律按本条口径处理。

⏪ **dated 追加 · V1 关账（自指计数格 ⇒ 版本三元组）（`t27`，读时 2026-09-28T16:25:52.678+0800；`t17` §5-V1 点名的 low）** —— 被更正对象 ＝ `:223`（**仅本次有效**）里那句 **`③ 本报告件自身 ⇒ `9` 行 ／ `11` 处**`；`t16` 取的是**「本笔追加之前」**那一刻的版本，原文**一字未删**（此处只补口径＋现值）。
⏪ **版本三元组（本席现算；口径 ＝ `grep -c` 得**行数**、`grep -o … | wc -l` 得**处数**）**：① **`4a97a0d^` 版（`222` 行）＝ `9` 行 ／ `11` 处** ⇒ **＝ `t16` 的 `③` 值** ⇒ 故 `③` 的口径**写死为「`t16` 本笔追加之前（`222` 行版）」**；② **`4a97a0d` 版（`227` 行）＝ `11` 行 ／ `15` 处** ⇒ **＝ `t17` 现取**（逐格相同）；③ **本笔追加之后（现盘）＝ `13` 行 ／ `17` 处**（含本条自身对 `D-G176` 的引用 ⇒ **自指**：写下本行这个动作**又把该数改了**）。
⏪ **读法（此后一律照此）**：凡引用「**本件自身**」的计数（`D-G176` 一行尤甚），**必须**同时写「**哪个版本**（提交版／「本笔追加之前」／「本笔追加之后」）＋ **该版总行数**」；只给一个数 ⇒ **不可对拍**（`D-G125`／`D-G130` 同族）。
⏪ **实质结论不变**：`13` 在**四种口径**（`2/3`／`1/1`／`9/11`／`11/15`）下**都不成立** ⇒ `t16` F2 的**结论仍成立**，本笔只补口径与现值。
⏪ **本件自报值的时效**：`:222` 的自报 sha16 `fe703dd79ef2a4c2` 是**其写入时刻**的口径；**本笔追加前**（`227` 行）全文 ＝ `c01e2e92449e659e`；**本笔追加后**的全文 sha16 与 `head -n -1` 值由 `build/MilBridge/P1-v-close-report.md` **现算登记**（本件末行不带自指值 ⇒ 不存在自指矛盾）。
