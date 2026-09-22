# W104A 报告 —— 登记 `D-G95`（恒真谓词反用 ＝ 反向恒假）＋ 更正 `W53A` 路径笔误 ＋ 拆两条新 TASK ＋ 第四笔文档推送

车道 `W104A`｜`2026-09-22 19:29 → 19:45 (+0800)`｜**纯文本编辑 ＋ 一次推送**（零重活、不占槽）
仓 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`｜fork 克隆 `~/netTest/GitProj/WPFOnLinux`
冻结基线 `#50 1f4189c1257737a9`｜**零 `dotnet`／零构建／零应用／零门禁**（只跑只读核对器 `defect-registry-check.sh`）
判据先写：`~/w104a/criteria.md`（**`01f86149a8496dde`**），**写它的时刻早于本车道对 `$R` 任何文件的第一次编辑**

---

## §0 结论速览（先看这里）

1. **新号 = `D-G95`**（现场核末号 = `D-G94`，连续取下一个；改前 `grep -c 'D-G95'` = **0**）：**装置缺陷 · 恒真谓词用在 `if !` 上 ⇒ 反向恒假**。
2. **两条新 TASK**：`TASK-0704` [Next] 🔴（修**仓外** 4 处 ＋ **复核被污染臂的结论**；**进行中 = 车道 W103A**）｜`TASK-0109` [Next] 🔴（产品侧 `wpf_x11_has_ewmh_wm()` 的"死 WM 残留"边界）。
3. **路径笔误更正 5 处**（任务书点名的 4 处 ＋ 册里那条**原始出处** ⇒ 第 5 处是我自己加的，理由见 §3）：`build/MilBridge/W53A/` **仓内不存在** ⇒ 真身 = **仓外** `~/w53a/cell3.sh`。**只追加 dated 更正 bullet，原文一字未动**。
4. **`DEFREG=PASS declared=131 route_ids=131`、`DEFREG_DECLDRIFT=0`、`rc=0`**（连跑两遍逐字相同）；声明表**只 ＋1 行、0 删、0 改**（新号 `req=KD` ⇒ **未动** CS/HO/AB）。
5. **推送成功**：`90d50c4ec34a2fda02f3577d38a6aaf9282fd4f9 → 312e2524f83dcdff5b99742fb23004a0c762722c`（`local == remote`，`--symref` 仍 `feat-Linux`）；`BYTECHECK ok=7 mismatch=0 nobody=1`（那 1 件 = `W103A-report.md`：**它在盘上还不存在**，见 §5.3）。
6. ⚠️ **一处必须点名的读数**：本车道开工/收工的 `inputs_fp` = **`c138491c611de7d5…`**，**≠ `#50` 冻结值 `ee543f44b1090c74…`** —— 机械归因（§6.2）：覆盖面里**与 HEAD 内容不同**的件**恰好 2 件**，都是**车道 W101A 正在改它自己写域里的 `win32_core.c`／`win32_internal.h`**（mtime `19:20:26`／`19:20:03`，**早于**本车道任何编辑）⇒ **与本件无关**；但"**收尾态 ≠ 冻结态**"这件事**必须记在册上**（本件贡献本身**为零**，见 §6.1）。
7. ⚠️ **本件**没有**动 `TASK-0703` 的状态位**（它仍是 `🔴`）：装置侧已由 W102A 交件，但该行正文还含"**盘点全仓同类写法**"那一半，而仓外 4 处**仍未修**（已拆 `TASK-0704`）⇒ **改不改状态位留主控一句话裁定**（§7 第 4 条）。

---

## §1 新号的编号与判词（**逐字**，从册上抽）

**编号现场核法**（判据 `~/w104a/criteria.md` §1）：`grep -o 'D-G[0-9]\+' samples/WpfFeatureProbe/KNOWN-DEFECTS.md | sort -u -V | tail -1` ⇒ **`D-G94`**；`grep -c 'D-G95'`（改前）= **0** ⇒ 新号 = **`D-G95`**（**不是**照抄任务书的"建议值"）。落点 = 册末（既有 `D-G93`/`D-G94` 之后），式样照抄同两号。

### 1.1 册里新增的完整条目（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2487-2508`）

### `D-G95`（**装置缺陷 · 恒真谓词用在 `if !` 上 ⇒ 反向恒假**）：同一个 `D-G89` 谓词被用来**决定"要不要起 WM"** ⇒ 那个分支**永远进不去** ⇒ 自称"WM 腿"的那一趟**其实跑在无 WM 上**

- 现象（车道 W102A，报告 `build/MilBridge/W102A-report.md` `387599041ff1abb0` §8.3；**判据先写**于 `~/w102a/criteria.md` `f0cc9ca03fd610aa` §5.3）：`~/w63a/bin/wm-leg.sh:19` **逐字**为
  `if ! DISPLAY=$D xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q window; then`
  —— 与 `D-G89` **同一个恒真谓词**，但用在 `if !` 上 ⇒ `!` **恒假** ⇒ `then` 体（起 `xfwm4`）**永远进不去**。
- 判定点：`~/w63a/bin/wm-leg.sh:19`（**仓外**装置；仓内不存在此件）。承重点 = 该 `if` 体是**这一趟唯一的起 WM 路径**（其后 `sleep 3` 就往下走）。
- **机械证**（私有 `:188`、**无 WM**、脚本**同款文本**，`~/w102a/logs/w63a-form-demo.txt` 逐字）：
  ```
  W63A_FORM: **没进 if 体**（＝永远起不了 WM）
  TRUE_CRITERIA_FORM: 进了 if 体（正确：确实没 WM）
  _NET_SUPPORTING_WM_CHECK:  no such atom on any window.      ← 现场原文
  xprop rc=0
  ```
- **现场读数支持（"那一刻的那一版"）**：`~/w63a/logs/wm.progress:1` 逐字
  `2026-09-21 11:35:25 DISPLAY=:197 wm=_NET_SUPPORTING_WM_CHECK:  no such atom on any window. geom=1024x768`
  ⇒ 那一趟**自称"WM 腿"**（该脚本头部还引 `D-G64`「无 WM 的验收装置永远复现不出一整类缺陷」）却**跑在无 WM 上**。
  本车道现场重算：`~/w63a/bin/wm-leg.sh` mtime = `2026-09-21 11:35:22`（**早于**那条读数 3 s ⇒ 该读数由**当前这版**产生）、`~/w63a/logs/wm.progress` mtime = `2026-09-21 11:37:08`。
- **危险方向（与 `D-G89` 不同，这是本条的要害）**：`D-G89` 的坏法是"**等待等于没等**"⇒ 取样太早、自证行**假阴性**（方向安全但会骗人）；本条是"**分支等于没有**"⇒ **静默跑错腿** —— **既不是假红也不是假绿**，而是"**你以为在测有 WM 的世界，其实没有**"⇒ 该腿对 WM 相关的那一整类缺陷**检测力为 0**，而它的输出**看起来完全正常**。
- ⚠️ **不确定项（如实划，不许当读数）**：`~/w63a/xfwm197.pid` mtime = `2026-09-21 00:24:02`（**早于** `11:35`）⇒ 那是**更早一版**同一脚本留下的（说明**当时**进得去该分支）；**本车道未读到那一版的原文** ⇒「当时判据是好的」只是**推断**。**能机械证的只有**：**当前这版文本下该分支不可达**。
- 交叉引用：`D-G89`（同族本体，其现场实例 `~/w53a/cell3.sh:26` 已由 `TASK-0703`／车道 W102A 修掉）｜`D-G77`／`D-G59`（"装置假设某状态成立却不在用之前验证"同族；`D-G77` 是**已修好的样板**：先验 → 自起 → 起不来就非零退出）。W102A §8 的**仓内盘点结果 = 活的恒真判据 0 处**；仓外**同类 5 处**（`cell3.sh` 已修，其余 4 处未修，本条是其中最坏的一处）。
- 处置：**本波只登记**（`#50` 冻后；车道 W104A 只写**册／地图／报告**，**不改任何装置** —— 那 4 处**全在仓外**，且其中 3 处属**车道 W103A 的写域**）。落地 = 新任务 **`TASK-0704`**（4 处：`~/w53a/cell.sh:26`／`~/w53a/cell2.sh:26`／`~/w76a/bin/ab.sh:26`／`~/w63a/bin/wm-leg.sh:19`），**正在由 W103A 做**；其中 `w63a` 那处**还要复核它那趟"WM 腿"的判词是否已影响任何已登记结论**（W102A §11.2 记：只证"当前版不可达 ＋ 11:35 那趟无 WM"，**未重跑/未重判**它的臂）⇒ 若影响，相关结论须按"无 WM 口径"重取或降级为 `NOINFO`。
- 边界 / `NOINFO`：① 那 4 处**在仓外** ⇒ 仓内补不出牙（同 `D-G93` 的边界），本条**只登记**；② 全仓"**恒真谓词反用**"的同类写法**未逐处枚举**（已知仅 `w63a/bin/wm-leg.sh:19` 这一处**带现场读数**的支持）；③ **未改**任何既有编号的值与判词，**未**把任何红写成绿。

### 1.2 同趟在 `D-G89` 条下追加的 dated 路径更正（**原文一字未动**，`KNOWN-DEFECTS.md:2412-2413`）

- 既有实例：`build/MilBridge/W53A/cell3.sh:26` 就是这一行；`W54A` 的 WM 腿同源。
  - ⚠️ **路径笔误更正（车道 W104A，2026-09-22）**：上一行那个 `build/MilBridge/W53A/` **仓内不存在**（`ls -d` 报"没有那个文件或目录"、`rc=2`；fork 克隆 `git ls-files | grep -i W53A` **只有 `build/MilBridge/W53A-report.md`**，没有那个目录）⇒ **真身 = 仓外 `~/w53a/cell3.sh:26`**（`find $HOME -maxdepth 3 -name cell3.sh` 命中 **1 件**；`#50` 冻后由车道 W102A 修为 **`a358f6fd38b3b387`**，修前 `06c6d17fa9906761`）。**上一行原文一字未动**（加注不覆盖）。
  - 🆕 **同族新实例（第四处，且是"反向恒假"新形态）＝ `D-G95`**（见下条）：同一个恒真谓词用在 `if !` 上 ⇒ **分支永远进不去**。

---

## §2 两条新 TASK（**逐字**，从地图上抽）

### 2.1 `TASK-0109` [Next] 🔴（`docs/ROUTES.md:370-374`，**核实未被占用**：改前 `grep -c 'TASK-0109' docs/ROUTES.md` = 0）

- `TASK-0109` [Next] 🔴 **产品侧 `wpf_x11_has_ewmh_wm()` 的残留边界：`WM` 已死而 EWMH 属性残留时，可能**静默丢一次移动**（来源 = W102A 报告 §8.5 记的 `NOINFO`；与 `D-G88`／`H2` 相邻但**不同因**）：
  - 判定点：`src/WpfGfx.Linux.Native/src/win32_x11.c` 的 `:1659 wpf_x11_has_ewmh_wm()`（`_NET_SUPPORTING_WM_CHECK` 的 intern 在 `:198`）＋ `:1780 wpf_x11_moveresize()`；声明在 `src/WpfGfx.Linux.Native/src/win32_internal.h:590`。
  - 现象与推因（**未实测产品面**）：`has_ewmh_wm()` 用的是**真** `XGetWindowProperty`（**不是**恒真谓词 ⇒ **不属 `D-G89` 族**），但它**只查"属性在不在"，不查"那个窗还在不在"**；而既有留档已证 **WM 死后 EWMH 属性会残留**（`build/MilBridge/W54A-report.md` §0.4(1) 逐字 `WMPROOF_AFTER: … window id # 0x2000ae  xfwm4_alive=no`；同一现象另见 `~/w53a/logs/WFP3-wm-killwm/report.txt:9`）⇒ `wpf_x11_moveresize()` 在"**WM 已死但属性残留**"时会**走 EWMH 分支**（`XSendEvent` 给 root，无人处理）而**不走兜底 `XMoveResizeWindow`** ⇒ **可能静默丢一次移动**。
  - 要建的场景（**判据先写**）：起 WM ⇒ 用 `TASK-0703` 的真判据确认三条件在场 ⇒ **杀 WM 但保留属性** ⇒ 请求一次移动/改尺寸 ⇒ 期望 = **兜底路径生效（窗口真的动了）**或**大声失败**；**取不到读数 ⇒ `NOINFO`**（既不算绿也不算红，不许猜）。
  - 边界：本行**只立号，未建探针**（W102A 因"跑应用"违其纪律未测 ⇒ `NOINFO`）。

### 2.2 `TASK-0704` [Next] 🔴（`docs/ROUTES.md:381-385`，**核实未被占用**：改前 `grep -c 'TASK-0704' docs/ROUTES.md` = 0）

- `TASK-0704` [Next] 🔴 **修仓外 4 处同类"等 WM 起来"恒真谓词 ＋ 复核被污染臂的结论**（`D-G89`／`D-G95` 的落地；**进行中（车道 W103A）**）：
  - 判定点（4 处，**全在仓外**）：`~/w53a/cell.sh:26`｜`~/w53a/cell2.sh:26`｜`~/w76a/bin/ab.sh:26`（这三处与已修的 `cell3.sh` 原第 26 行**逐字相同**）｜`~/w63a/bin/wm-leg.sh:19`（**`if !` 形态 = 反向恒假**，即 `D-G95`）。
  - 修法形状（照 `D-G77` 这个**已修样板**／`TASK-0703`）：**先验 → 起不来就非零退出 ＋ 逐条打读数**，或最小改 `grep -q 'window id #'`；**不许**静默放行，**不许**为了让某条腿变绿而放宽判据。
  - ⚠️ **附加任务（不许省）**：`~/w63a/bin/wm-leg.sh` 那趟自称"WM 腿"的运行（`~/w63a/logs/wm.progress:1`，`2026-09-21 11:35:25`）**实际跑在无 WM 上** ⇒ 必须**复核它的判词是否已影响任何已登记结论**；若影响，相关结论按"无 WM 口径"**重取或降级为 `NOINFO`**（W102A §11.2 记：它**未**重跑/未重判那一趟的臂）。
  - 边界：**仓内补不出牙**（装置在仓外 ⇒ 同 `D-G93` 的边界）；落地后"在册结论要不要重取"由主控裁定。`NOINFO`：那 4 处改完后**是否还有同类写法**未逐处枚举。

### 2.3 另加的 `TASK-0703` 子行（`docs/ROUTES.md:376-380`）

含**任务书第 4 项要求的那行附注**（逐字口径）：

> ⚠️ **`wm-awaited.sh` 「未接线」**：它**未**进 `verify-all`／任何门禁，也**未**进 `fp_inputs()` 覆盖面（机械现场：覆盖面 **147 件**里 `grep wm-awaited` **0 命中**）。⚠️ **若主控把它接进任何在仓调用方，按仓内纪律必须同趟把它纳入 `fp_inputs()` 覆盖面**（"判据改了自己没人看着"同族欠账，与 `TASK-9907` 的接线口径同源）。

另记了 W102A 的装置侧交件读数（工具 sha16 ＋ `--selftest 11/11` ＋ 三条腿两极化 ＋ `~/w53a/cell3.sh` 修前修后 sha16），**逐字见地图**（本报告不重抄，避免两处措辞分叉）。

---

## §3 路径笔误更正（**逐处**：改了哪一行、追加了什么）

**判据（`~/w104a/criteria.md` §2，三条独立证据全真才叫"笔误"）**：

| 代号 | 机读读数（本车道现场） |
|---|---|
| `B1 DIR_ABSENT` | `ls -d build/MilBridge/W53A/` ⇒ `ls: 无法访问 'build/MilBridge/W53A/': 没有那个文件或目录`、**`rc=2`** |
| `B2 TRUEBODY_EXISTS` | `ls -l ~/w53a/cell3.sh` ⇒ `-rwx--x--x 1 links-dev links-dev 10335  9月 22 19:20`；`find $HOME -maxdepth 3 -name cell3.sh` ⇒ **命中 1 件** |
| `B3 NOT_IN_REPO` | fork 克隆 `git ls-files \| grep -i W53A` ⇒ **只有 `build/MilBridge/W53A-report.md`**（**从来**没有那个目录） |

**追加的更正句（同一口径，5 处）**：

> ⚠️ **路径笔误更正（W104A，2026-09-22）**：`build/MilBridge/W53A/` **仓内不存在**（`ls -d` 报"没有那个文件或目录"、`rc=2`；fork 克隆 `git ls-files | grep -i W53A` **只有 `build/MilBridge/W53A-report.md`**）⇒ **真身 = 仓外 `~/w53a/cell3.sh`**（`#50` 冻后由车道 W102A 修为 **`a358f6fd38b3b387`**，修前 `06c6d17fa9906761`）。**原文一字未动**（加注不覆盖）。

| # | 处 | 改后位置 | 原文里写的是 | 处理 |
|---|---|---|---|---|
| 1 | `docs/ROUTES.md` | `TASK-0703` 行下的新子行（`:380`） | `build/MilBridge/W53A/cell3.sh:26` | 追加更正 bullet，**正文未动** |
| 2 | `build/MilBridge/W93A-report.md` | §8 表格**之后**（`:350-351`） | 表格第 1 行写 `` `W53A/cell3.sh:26` `` | 追加 blockquote，**表格未动** |
| 3 | `build/MilBridge/W96A-report.md` | §1.2（`:51`） | `build/MilBridge/W53A/cell3.sh:26` | 追加子行，**上一行未动** |
| 4 | `build/MilBridge/W96A-report.md` | §5.4 引文之后（`:185`） | 引文里 `build/MilBridge/W53A/cell3.sh:26` | 追加 blockquote，**引文未动** |
| 5 | **`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`**（册里那条**原始出处**，任务书**未点名**） | `D-G89` 条下（`:2412-2413`） | `build/MilBridge/W53A/cell3.sh:26` 就是这一行 | 追加子行 ＋ 指向 `D-G95`，**该行未动** |

> ⚠️ **第 5 处是我自己加的**（任务书只点了 4 处）：它是**在册的原始出处**；只改地图与两份报告而留着册里那条，正好犯本仓"**同一事实两处必然分叉**"（`D-G31`／`D-G13` 族）⇒ 一并追加，**只追加、未改原文**。
> ⚠️ **`build/MilBridge/W102A-report.md` 里那 4 处 `build/MilBridge/W53A/cell3.sh`（`:13`／`:67`／`:254`／`:351`）我**没有**加更正**：那几行**本身就是"这是笔误"的判定句**（W102A 把笔误写出来并纠正它）；在它们上面再加一条"更正"只会制造混乱。**如实记，供主控裁**。

---

## §4 `DEFREG` 两条机读行（**连跑两遍逐字相同**，`rc=0/0`，`~/w104a/logs/defreg.txt`）

```
DEFREG_DECL=n=131 route_ids=131 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=395cc255b95cc125 CS=1ff381a9be8c3c7a HO=e4dc264200b421d0 AB=1f4189c1257737a9
DEFREG_EXTRA=KRJ=8a0c0f221e35f42b KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=131 route_ids=131（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
rc=0
```

（两趟的这 6 行**逐字节相同**；开工基线是任务书给的 `declared=130` ⇒ **＋1** 正是 `D-G95`。）

**只加法机器证**（`--emit` 前后比对，**去掉生成器自己那两行 `# DECL-*`**）：

```
diff（去 `# DECL-*` 头）⇒ 删行 = 0   增行 = 1
> ID	D-G95	req=KD	present=KD
```

- **`req=KD`** ⇒ 按 `D-G62+` 一贯口径**只需改册 ＋ 地图** ⇒ **未动** `CURRENT-STATE.md`／`handoff.md`／`ACCEPTANCE-BASELINE.md`（后者 = 冻结基线 `1f4189c1257737a9`，**一字节未碰**）。
- `# DECL-ANCHORS` 里 `KD=` 从 `be6203dce80e9b81` 变成 `395cc255b95cc125`（= 册的新 sha16，生成器的预期产物）；其余六个锚点（`CS`/`HO`/`AB`/`KRJ`/`KRF`/`KRP`）**逐位未变**。

**"只加法"在四个文本件上的逐件机证**（与推送前 head `90d50c4` 的 blob 比）：

| 件 | 删行 | 增行 |
|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | **0** | 25 |
| `docs/ROUTES.md` | **0** | 25 |
| `build/MilBridge/W93A-report.md` | **0** | 2 |
| `build/MilBridge/W96A-report.md` | **0** | 3 |
| `build/MilBridge/tools/defect-registry-declared.tsv`（去 `# DECL-*`） | **0** | 1 |

⇒ **没有任何既有编号的值与判词被改写**，也没有任何红被改成绿。

---

## §5 推送（第四笔，文档）

### 5.1 head 三条 ＋ refspec

```
推送前：local =90d50c4ec34a2fda02f3577d38a6aaf9282fd4f9
        remote=90d50c4ec34a2fda02f3577d38a6aaf9282fd4f9   （== 任务书给的 HEAD）
        git ls-remote --symref origin HEAD ⇒ ref: refs/heads/feat-Linux
fetch  ：git fetch origin feat-Linux:refs/remotes/origin/feat-Linux ⇒ e671f74..90d50c4 feat-Linux -> origin/feat-Linux
        （⚠️ refspec 陷阱现场：本地 `origin/feat-Linux` 原先停在 `e671f74`（= W99A 那笔），**不 fetch 就会误判"远端落后"**）
push   ：90d50c4..312e252  feat-Linux -> feat-Linux
推送后：local =312e2524f83dcdff5b99742fb23004a0c762722c
        remote=312e2524f83dcdff5b99742fb23004a0c762722c   ⇒ **相等**
        git ls-remote --symref origin HEAD ⇒ ref: refs/heads/feat-Linux （仍是默认分支）
```

**逐径 `git add`（**未用** `-A`／`--force`）** ⇒ 暂存区**恰好 7 件**：

```
A	build/MilBridge/W102A-report.md
M	build/MilBridge/W93A-report.md
M	build/MilBridge/W96A-report.md
M	build/MilBridge/tools/defect-registry-declared.tsv
A	build/MilBridge/tools/wm-awaited.sh
M	docs/ROUTES.md
M	samples/WpfFeatureProbe/KNOWN-DEFECTS.md
```

提交信息：`docs(#50): 登记 D-G95（恒真谓词反用=反向恒假）＋更正 W53A 路径笔误＋拆 TASK-0704/0109＋补推 W102A 件`
`wm-awaited.sh` 以 **`100755`** 入册（可执行位保留）；`W102A-report.md` 为 `100644`。
⚠️ **本件的前置态是"仓内只有这一份 7 件的改动"**：全量比对（克隆 `git ls-files` 逐件 `cmp`，15234 件）显示与 HEAD 不同的**只有 7 件** = 本件这 5 改 ＋ **车道 W101A 的 `win32_core.c`／`win32_internal.h` 两件**（那两件**故意没进本笔**，见 §5.3 与 §6.2）。

### 5.2 `BYTECHECK`（`git cat-file blob <rev>:<path>` 与磁盘 `cmp`，**逐件**）

```
REV=312e2524f83dcdff5b99742fb23004a0c762722c
  ok       samples/WpfFeatureProbe/KNOWN-DEFECTS.md                   395cc255b95cc125
  ok       docs/ROUTES.md                                             c9bb57e49345739b
  ok       build/MilBridge/tools/defect-registry-declared.tsv         0d230bf39f34b9ef
  ok       build/MilBridge/W93A-report.md                             8228314623797d43
  ok       build/MilBridge/W96A-report.md                             582fb4d82568c507
  ok       build/MilBridge/W102A-report.md                            387599041ff1abb0
  ok       build/MilBridge/tools/wm-awaited.sh                        57a852f6948e1c67
  nobody   build/MilBridge/W103A-report.md
BYTECHECK ok=7 mismatch=0 nobody=1
```

⇒ **`nobody=1` 的语义（点名，不藏）**：`build/MilBridge/W103A-report.md` **在 `$R` 与远端都不存在**（`ls` 报"没有那个文件或目录"）—— 因为 **`W103A` 还在跑**（`TASK-0704` 进行中）⇒ 这不是"漏推"，是"**还没生成**"。本笔**不推任何未完成的件**。

### 5.3 本波"还没推"的件（如实点名，**我一件都没推**）

| 件 | 类别 | 我为什么没推 |
|---|---|---|
| `docs/WAVE51-PREREGISTRATION.md`（`19:12:43`，8,049 B） | 波 `#51` 预登记（**不是本件写域**） | 它**先于**本车道存在，是**主控/别家**的件；本件写域 = 册／地图／报告 ⇒ **只报不推**（推送是它的作者/主控的事） |
| `tests/parity/geometry/u14/linux-results-u14.json`、`tests/parity/windows/layout-b34/windows-results.json` | 对账结果件 | 同上，**不在本件写域** |
| `src/WpfGfx.Linux.Native/src/win32_core.c`、`win32_internal.h` | **车道 W101A 的在飞实验改动** | 按仓内纪律"**实验装置类改动必须事后还原**" ⇒ 它们**不该**由文档车道推进上游；本件**故意隔离**（这正是本笔只 `add` 7 件的原因） |

---

## §6 `fp_inputs` 影响判断（**零影响**，机械证）

装置 = `~/w104a/fp-check.sh`（`6f8d4ba98ebde02b`）：**复用** `build/close-wave.sh` 里 `fp_inputs()` 的**原文**（`awk` 抽函数体后 `eval`，只把尾部 `| xargs sha256sum …` 换成"打印文件清单"）⇒ **不手抄覆盖面**。

### 6.1 本件贡献 = 零（机械证）

```
FP_COVERAGE_FILES=147
  grep KNOWN-DEFECTS            ⇒ 0 命中
  grep ROUTES                   ⇒ 0 命中
  grep defect-registry-declared ⇒ 0 命中
  grep W93A-report              ⇒ 0 命中
  grep W96A-report              ⇒ 0 命中
  grep W102A-report             ⇒ 0 命中
  grep wm-awaited               ⇒ 0 命中
  grep W104A                    ⇒ 0 命中
  grep cell3                    ⇒ 0 命中
  grep W53A                     ⇒ 0 命中
```

口径说明（现场读 `close-wave.sh` 的 `fp_inputs()` 原文）：覆盖面 = ①`find … build \( -maxdepth 2 -name 'patch-*.py' -o … \)`（**按名枚举**）②`build/shims/**.cs` ③`src/WpfGfx.Linux/**.cs` ④`src/WpfGfx.Linux.Native/**.{c,h}` ⑤一份 **15 件 `build/MilBridge/tools/*` 的白名单 `printf`**（现场清单：`tline-gate.sh`…`verify-all-step-check.sh`）。
⇒ `build/MilBridge/*.md`（报告）、`docs/**`、`samples/**`、`**/*.tsv` 与 **`wm-awaited.sh`（不在那份 15 件白名单里）** **一条也不匹配** ⇒ **本件 7 件全在覆盖面之外** ⇒ **在数学上不可能移动 `inputs_fp`**。

### 6.2 ⚠️ 但开工/收工指纹**≠ `#50` 冻结值** —— 归因（机械证，不是推断）

```
FP_INPUTS_1=c138491c611de7d5839964a8c17afa9121aed57af643a1896257f7d5e031e4fb
FP_INPUTS_2=c138491c611de7d5839964a8c17afa9121aed57af643a1896257f7d5e031e4fb   （两遍相同）
                                    ↑ 开工（19:30）与收工后**逐位相同** ⇒ 本件确实没动它
#50 冻结值（W99A 记）= ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48
```

**归因装置** = `~/w104a/attrib-check.sh`（`92a62ec270868387`）：对覆盖面 **147 件**逐件与 fork 克隆 **HEAD 的 blob** `cmp`，打印"内容不同"的件：

```
  DIFF    src/WpfGfx.Linux.Native/src/win32_core.c      (disk mtime 2026-09-22 19:20:26)
  DIFF    src/WpfGfx.Linux.Native/src/win32_internal.h  (disk mtime 2026-09-22 19:20:03)
FP_COVERAGE_DIFF_VS_HEAD=2
```

⇒ **偏离的制造者只有 2 件，两件都是车道 W101A 的写域**，且它们的 mtime（`19:20`）**早于**本车道对本仓的第一次编辑（`19:31`，见 §4 的 `DECL-GEN`）⇒ **归因不是本件**；`W102A` 报告 §7.2 记过同一现象（它在 `19:26` 量到 `c138491c…`、`19:29` 量到 `ee543f44…`）—— 本车道 `19:30` 起量到的是 **`c138491c…`** ⇒ **说明 W101A 又把它那两处改动写回去了**（"它在飞"，与本件无关）。

⚠️ **含义（写清，供主控处置）**：只要 W101A 的在飞改动存在，**`inputs_fp` 就不可能等于 `#50` 冻结值**；本件为此**不改任何判据**、**不放宽任何断言**，只如实记 —— `#51` 收尾时这一格由**收尾链自己**（`IN_FP_0`/`IN_FP_1` 采样）裁决。

---

## §7 `NOINFO` / 未做（**既不算绿也不算红**）

1. **`D-G95` 的"更早那一版判据"未读到原文**（`~/w63a/xfwm197.pid` mtime `00:24:02`）⇒「当时判据是好的」是**推断**，不是读数 ⇒ 已在条内如实划。
2. **仓外 4 处装置我一个字节都没改**（`~/w53a/cell.sh`／`cell2.sh`／`~/w76a/bin/ab.sh`／`~/w63a/bin/wm-leg.sh`）：它们**全在仓外**、其中 3 处是**车道 W103A 的写域** ⇒ 本件**只登记 ＋ 只立号**（`TASK-0704`）。
3. **`TASK-0704` 的"被污染臂结论"未复核**：我只登记"要复核这件事"（W102A §11.2 记它**未**重跑/未重判）⇒ **复核结果 = `NOINFO`**（等 W103A）。
4. ⚠️ **`TASK-0703` 的状态位我没动**（仍是 `🔴`）：装置侧已交件，但该行还含"盘点全仓同类写法"那一半（仓外 4 处未修）＋ `wm-awaited.sh` 未接线 ⇒「**要不要标 ✅**」我判**该由主控一句话裁**（我**不**单方面把一条挂着未修尾巴的行标绿）。**回退成本 = 单点改一个字**。
5. **未做"全仓同类写法"的新一轮枚举**：W102A §8 的枚举是我**唯一**依据（引用时逐条注明来源）；本件**没有**重跑那份 `grep -rn`（避免把 `arm-logs`/产物卷进来，且**当前有别的车道在改仓外装置**，重跑会取到"跑着的那一版"，反而更不可信）。
6. **未跑任何构建/门禁**（本件纪律）；**未跑 `bash -n`** —— 因为本件**一个脚本都没改**（7 件里 6 件是 md/tsv，另 1 件 `wm-awaited.sh` 是**原样转推** W102A 的交付件，其 `bash -n` 与 `--selftest` 由 W102A 报告 §5 自证）。
7. **未推** `docs/WAVE51-PREREGISTRATION.md` 与两个 `tests/parity/**` 结果件（**不在本件写域** ⇒ §5.3 点名，等主控）。
8. **`D-G95` 的"同类反用"未全域扫**（已知仅 `w63a/bin/wm-leg.sh:19` 一处带现场读数）。
9. 🩸 **我自己踩的仪器坑（如实留档）**：核对"本报告里的逐字引文是否与源件一致"时，首版用 `grep -Fxq "$line"` 且**没写 `--`** ⇒ 引文里那些以 `- ` 开头的行被 `grep` 当成**选项**，当场报 `grep: 无效的选项 --` 并把 **9 条正常引文误报成 MISS**（差点让我去"修"一段本来正确的引文）。⇒ 这正是**纪律 55**（`--` 之后一切皆操作数）的反面教材；改成 `grep -Fxq -e "$line" -- "$R"` 后 **33 行引文 0 缺**（21 ＋ 2 ＋ 5 ＋ 5）。

---

## §8 本件交付件总表（现算 sha16）

| 件 | before → after sha16 | 说明 |
|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `be6203dce80e9b81` → **`395cc255b95cc125`** | 新 `D-G95` ＋ `D-G89` 路径更正 |
| `docs/ROUTES.md` | `a69f0d3cbc4cfcb3` → **`c9bb57e49345739b`** | `TASK-0109`／`TASK-0704` 新增 ＋ `TASK-0703` 5 条子行 ＋ §15c |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `afab9819b82bd669` → **`0d230bf39f34b9ef`** | `--emit` 重生成（＋1 行） |
| `build/MilBridge/W93A-report.md` | `ea7eb63bed9e3f25` → **`8228314623797d43`** | 只追加路径更正 |
| `build/MilBridge/W96A-report.md` | `ff527690c35a86c6` → **`582fb4d82568c507`** | 只追加路径更正（两处） |
| `build/MilBridge/W102A-report.md` | 新建（**补推**） → **`387599041ff1abb0`** | W102A 的报告（本件转推） |
| `build/MilBridge/tools/wm-awaited.sh` | 新建（**补推**） → **`57a852f6948e1c67`** | W102A 的真判据工具（本件转推） |
| `~/w104a/criteria.md` | 新建 **`01f86149a8496dde`** | 判据（先写） |
| `~/w104a/fp-check.sh` | 新建 **`6f8d4ba98ebde02b`** | `fp_inputs` 机械核 |
| `~/w104a/attrib-check.sh` | 新建 **`92a62ec270868387`** | 偏离归因 |
| `build/MilBridge/W104A-report.md` | **本件** | 报告 |

**收尾 head**（本报告自己那一笔推送之后）：`312e2524f83dcdff5b99742fb23004a0c762722c` → **见文末"收尾补记"**（自指哈希的记账口径：报告不可能写自己的 blob sha16，故把**它自己那一笔**的 head 记在 `~/w104a/STATUS.md`）。

---

## §9 大白话小结（6 行）

1. **同一个坏谓词，换个用法就更坏**：`xprop … | grep -q window` 恒真 ⇒ 上次的坏法是"**等 WM 等于没等**"；这次它被写在 `if !` 里 ⇒ `!` 恒假 ⇒ **"起 WM"那段代码从来没执行过**。
2. 所以 `~/w63a/bin/wm-leg.sh` 那趟**自称"WM 腿"**的运行，**其实跑在无 WM 上**（日志第一行就是"没有这个 atom"）—— **不是假红也不是假绿，是你以为在测有 WM 的世界、其实没有**，检测力为 0 而输出看着正常。
3. 我把它登记为 **`D-G95`**，并把它与 `D-G89`（等待恒真）、`D-G77`（已修好的样板）串起来；**仓外还有 4 处没修**（最坏的就是这一处）⇒ 拆了 **`TASK-0704`**，**正在由 W103A 做**（还要求复核那趟被污染的臂结论）。
4. 顺手把 **`TASK-0703` 的说明补齐**（W102A 的工具 `wm-awaited.sh` 交件读数、**未接线**、路径笔误更正），并新立 **`TASK-0109`**：产品侧 `has_ewmh_wm()` **只查属性不查窗还在不在** ⇒ WM 死了但属性残留时**可能静默丢一次移动**（等建场景验）。
5. 那条"`build/MilBridge/W53A/cell3.sh`"是**笔误**（那个目录**仓里根本没存在过**）⇒ 真身是**仓外** `~/w53a/cell3.sh`；我在 **5 处**都**只追加**更正行，**原文一字没动**。
6. 门禁与推送都干净：`DEFREG=PASS declared=131`（＋1 = 新号）、`DECLDRIFT=0`；推送到 **`312e252`**、`BYTECHECK ok=7 mismatch=0`；**本件对 `fp_inputs` 贡献为零**（7 件全在覆盖面外），⚠️ 但**当前指纹 `c138491c…` ≠ `#50` 冻结值** —— 机证归因是**车道 W101A 在飞的 `win32_core.c`／`win32_internal.h`**，不是本件。

---

## §10 收尾补记（推完之后复跑，**读数带 head**）

本件共 **2 笔**（第 1 笔 = 数据/登记；第 2 笔 = 本报告；**报告自身 sha16 不可能写进报告自身** ⇒ 自指那一笔的 head 记在 `~/w104a/STATUS.md`）：

```
第 1 笔  90d50c4..312e252  feat-Linux -> feat-Linux   （7 件：册／地图／声明表／W93A／W96A／W102A报告／wm-awaited.sh）
第 2 笔  312e252..4869397  feat-Linux -> feat-Linux   （1 件：build/MilBridge/W104A-report.md）
推送前 90d50c4ec34a2fda02f3577d38a6aaf9282fd4f9（== 任务书给的 HEAD）→ 收尾 486939773cd185efedf17bff0277fab9401279c4
local == remote（两条命令同值）｜ls-remote --symref origin HEAD ⇒ ref: refs/heads/feat-Linux
```

**收尾 `BYTECHECK`（`REV=486939773cd185efedf17bff0277fab9401279c4`，逐件 `git cat-file blob` 与磁盘 `cmp`）**：

```
  ok       samples/WpfFeatureProbe/KNOWN-DEFECTS.md                   395cc255b95cc125
  ok       docs/ROUTES.md                                             c9bb57e49345739b
  ok       build/MilBridge/tools/defect-registry-declared.tsv         0d230bf39f34b9ef
  ok       build/MilBridge/W93A-report.md                             8228314623797d43
  ok       build/MilBridge/W96A-report.md                             582fb4d82568c507
  ok       build/MilBridge/W102A-report.md                            387599041ff1abb0
  ok       build/MilBridge/tools/wm-awaited.sh                        57a852f6948e1c67
  ok       build/MilBridge/W104A-report.md                            3a9a383c06577372
  nobody   build/MilBridge/W103A-report.md                            （在盘上还不存在 = W103A 仍在跑）
BYTECHECK ok=8 mismatch=0 nobody=1
```

⚠️ `build/MilBridge/W104A-report.md` 那一格是**本报告 §10 之前的版本**（`3a9a383c06577372`）：追加本节后本件变新 sha16（现算见 `~/w104a/STATUS.md`），**§10 这一节由第 3 笔单独推**（§7.9 那条"我自己踩的仪器坑"也在同笔）。**"报告的 sha16 改一次就换一个"是本仓既有现象（见 `D-G92` 那条"哈希别当身份"），这里如实记，不假装它稳定。**

