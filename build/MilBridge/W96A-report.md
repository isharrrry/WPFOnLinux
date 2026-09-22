# W96A · 登记车道 —— 把 W93A 的三份读数登记进**册与地图**（纯文本编辑；零 `dotnet`／零应用／零重活／不占槽）

> `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
> 来源 = 车道 W93A 报告 `build/MilBridge/W93A-report.md` ＋ 缺陷草案 `~/w93a/defect-draft.md`（`6c67bff3e7d5b785`）。
> **本件不做任何取证**，只把 W93A 的读数**逐字**登记；判据（"什么算登记好"）先写如下。

## §0 判据（先写，后取读数）

| # | 子项 | 判据 | 结果 |
|---|---|---|---|
| 1 | 新号连续 | 取现场最后一号的**下一个**（不许猜） | ✅ 现场末号 = `D-G87` ⇒ 新号 `D-G88`/`D-G89`/`D-G90` |
| 2 | 体例一致 | 照抄既有 17 号（`D-G71`…`D-G87`）的写法：`### \`D-GNN\`（**类型**）：**标题**` ＋ `- 现象`/`- 判定点`/`- 处置`/`- 边界` | ✅ 见 §1 |
| 3 | 只做加法 | 不删既有号、不改既有号的值与判词、不把红改绿 | ✅ 机证见 §3.3（`diff` 只有 3 行新增） |
| 4 | 册与地图自洽 | `DEFREG=PASS` ＋ `DEFREG_DECLDRIFT=0`（现场跑，机读行入报告） | ✅ 见 §3 |
| 5 | 不撞收尾链 | 若 `~/w94a/STATUS.md` 已到"重取五臂"或更后 ⇒ **立即停手** | ✅ 未到（见 §4.4） |
| 6 | 现状核查（不许想当然） | 先搜"40 行截断"是否**已登记**再决定给不给新号 | ✅ 未登记 ⇒ 给新号 `D-G90`（见 §6） |

⚠️ **本车的判据只能证明"登记动作合规"，不能证明"读数正确"** —— 读数正确性归 W93A 的判据与主控的独立复核。

---

## §1 新号的编号与判词

三个新号，全部落在权威册 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`4234508f811bd9ba` → **`aec62c485d5010b9`**，2382 → 2407 行）。

### 1.1 `D-G88`（**产品缺陷**）— `H2` 本体

**`### \`D-G88\`（**产品缺陷**）：**运行期改尺寸提示（\`MinWidth/MaxWidth/MinHeight/MaxHeight\`）到不了 X** —— \`H2\` 本体（\`D-G83\` 的后续：终态死锁 ＋ 预算**计"问"不计"改"**）`**（`:2384`）

逐字要点（**全部来自 W93A 报告，未加戏**）：

| 项 | 内容 |
|---|---|
| 现象 | 三窗一台、14 stage、两条腿（裸 `Xvfb :181` ／ `Xvfb :182`＋`xfwm4`）**判据输入列逐格相同** ⇒ `SUMMARY A1_informative=29 PASS=5 FAIL=4 VACUOUS=20`；**4 个 `FAIL` 全是运行期改动格**（`W1-TIGHTEN`／`W2-DECLARE`／`W2-TIGHTEN`／`W3-DECLARE`）；X 侧恒停 `667 by 500` |
| 缺什么 | 应用侧每格**都答对** ⇒ **缺的不是值，是触发器** |
| 最值钱一格 | `W2-DECLARE`：应用**自己**缩窗 `625x521→521x417`，而 X 侧**连 `maximum size` 都没有** |
| 正对照 | `W2-TOGGLE`（**全仓唯一**运行期触发器 = `win32_core.c:1074`，`ShowWindow` 内 `WM_SHOWWINDOW` 之后）一按即正确落 `521 by 417` ⇒ **通道没坏** |
| 机制 | **唯一**写 `WM_NORMAL_HINTS` 处 = `win32_core.c:714-748`；两停止条件 = `:763` `WPF_HINTS_REASK_MAX 3` ＋ `:765-790` 的 `hints_map_declared`（**终态**）与 `hints_map_asks<3`；`MoveWindow :1078-1100`／`SetWindowPos :1108-1172` **都不重发**；上游 `Window.cs:5864-5889` **只在缩小时动**、**调高时什么也不做** |
| 上限 `3` 的后果 | 两种吞法**都取到读数**：①已声明终态（`W1`，`hints_map_declared=1` 死锁）②预算耗尽（`W3`，4 次无意义 `HIDE/SHOW` ⇒ **第一次真声明也永久发不出**）；钩子 `W1[shim=0] W2[shim=1] W3[shim=2]` 与 `diag_aftermap=6` 加法一致 |
| 反极性 | 按**先写死的口径**判 **`VACUOUS`**（提示在 14 stage 里**一次都没移动过** ⇒ "回到旧值"与"从来没跟过"**不可分**）⇒ **不当绿** |
| 有 WM 时更重 | WM **真执行**一份**过期**约束：客户请求 `1000x800→667x500`／`300x200→521x417`；拖边框**对照窗** `667x500→937x692`、**受限窗纹丝不动**（`W3` 声明 450 却被放任到 `1000x800`） |
| 处置 | **本波只登记**；落地 = `TASK-0108`（波 `#51`），草案 `P1`–`P4` 见 W93A §5 |

### 1.2 `D-G89`（**装置缺陷 · 判据恒真**）

**`### \`D-G89\`（**装置缺陷 · 判据恒真**）：\`xprop -root _NET_SUPPORTING_WM_CHECK | grep -q window\` **恒真** ⇒ 任何"等 WM 起来"的等待**等于没等**`**（`:2394`）

- 根因：`xprop` 的失败文案 `no such atom on any **window**.` 里的 `window` 被 `grep -q window` 匹配 ⇒ **谓词恒真**。
- 现场：逐 0.25 s 计时 ⇒ `atom appeared at iteration 1`（≈0.25 s 就 `break`），**同刻** `xprop` 仍是 `no such atom`；真上位要 ~1–5 s。
- 既有实例：`build/MilBridge/W53A/cell3.sh:26`；`W54A` 的 WM 腿同源。
- 后果：**方向安全但会骗人** —— 之后**立刻**取的自证行可能是**假阴性**（WM 其实在场）。
- 处置：**本波只登记**；落地 = `TASK-0703`。修法一行：`grep -q 'window id #'`。
- 留了**可反驳性**：若某 WM 给不含 `window id #` 的合法值，此判据需重写。

### 1.3 `D-G90`（**仪器局限 · 判据认错对象**）

**`### \`D-G90\`（**仪器局限 · 判据认错对象**）：\`wpf_wmsize_diag\` **每进程 40 行硬截断** ⇒ \`[WMSIZE_DIAG]\` **不能当"派发总数"**用`**（`:2402`）

- 判定点：`src/WpfGfx.Linux.Native/src/win32_core.c:475-484` 的 `if (n++ >= 40) return;`。
- 现场：两趟腿 `[WMSIZE_DIAG]` **恰好 40 行**，末行在日志第 **189／248** 行 ⇒ 尾段无 diag 行，**不能**据此断言"尾段没有派发"。
- 结论：**"看不见"与"没发生"分不开**（本仓明令禁止的那一族）⇒ 必须**与不受截断的计数互印**；`W93A_ASKS diag_aftermap=6` 只当**旁证**。
- 承重用法（登记它在册的理由）：`build/MilBridge/W82A-report.md` §3.3（"补问 5 行"）＋ W93A §2.4/§2.5（"逐窗归因"）。
- 处置：**本波只登记**；建议修法（**未落**）＝ 抬高上限并把"已截断"**打出来**（`[WMSIZE_DIAG] TRUNCATED n>=40`）。
- 边界：**不改**现有截断值（改它会影响既有判据读数）。

> **§2173 的分节标题**也同趟扩写了（**加法**）：
> `## \`#49\` 波前新登记（\`D-G62\` … \`D-G70\`）＋ 波中新登记（\`D-G71\`…\`D-G87\`，2026-09-21/22）＋ \`#50\` 波尾新登记（\`D-G88\`…\`D-G90\`，2026-09-22）`

---

## §2 四个路由件各改了哪几行

**先说一条与任务书不符的现场事实（重要）**：`DEFREG` 的 route 键**只有 `KD`/`CS`/`HO`/`AB`**（`defect-registry-check.sh:75-76`、`:90` 的 `ALLKEYS='KD CS HO AB KRJ KRF KRP'`）—— **`docs/ROUTES.md` 根本不在 DEFREG 键集里**。且 `docs/CURRENT-STATE.md` 的 `D-G` 覆盖**只到 `D-G61`**、`handoff.md` 同理 ⇒ `D-G62`…`D-G87` 全部是 **`req=KD`**。本件三个新号**沿用同一约定**（`req=KD`），故 **CS/HO/AB 三个件一字未改**。

| 件 | before sha16 | after sha16 | 改动 | 行数 |
|---|---|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `4234508f811bd9ba` | **`aec62c485d5010b9`** | ＋3 个条目（`:2384`/`:2394`/`:2402`）＋ 分节标题（`:2173`） | 2382 → 2407 |
| `docs/ROUTES.md` | `8212fa9d68a78687` | **`9ee84087206fc1a3`** | 见 §5（5 处） | 339 → 355 |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `e18eaf6c9b37518a` | **`bdf95e0c8bc191f0`** | `--emit` 重生成：**只有 ＋3 行** | 132 → 135 |
| `docs/CURRENT-STATE.md` | `85c37415df1eafea` | `85c37415df1eafea` | **未动** | — |
| `handoff.md` | `e4dc264200b421d0` | `e4dc264200b421d0` | **未动** | — |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `f1d340d66c7c6ba3` | `f1d340d66c7c6ba3` | **未动** | — |

**没碰的**（现场 sha16 复核不变）：`build/close-wave.sh` `f440ccdb4e29a942`（＝**与 W94A 勘察自报值逐位相同**，独立佐证我没碰它）、`verify-all.sh`、`build/MilBridge/tools/r-gate-step.sh`、`known-red.json` `a747b713532e7631`、任何产品件、`~/w94a/**`、`~/w93a/**`。

---

## §3 两条 DEFREG 机读行（现场跑，未手抄）

```
$ bash build/MilBridge/tools/defect-registry-check.sh
DEFREG_DECL=n=126 route_ids=126 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=aec62c485d5010b9 CS=85c37415df1eafea HO=e4dc264200b421d0 AB=f1d340d66c7c6ba3
DEFREG_EXTRA=KRJ=a747b713532e7631 KRF=ab09235afd949bc2 KRP=8497a0ca1689cf90
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=126 route_ids=126（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
rc=0
```

**① `DEFREG=PASS declared=126 route_ids=126`** ✓ **② `DEFREG_DECLDRIFT=0`** ✓

- **改动前**基线（开工时现场跑）：`DEFREG=PASS declared=123 route_ids=123`、`DEFREG_DECLDRIFT=0`、`rc=0` ⇒ 净增 **3** 号，判据未被削弱。
- 连跑**两趟**逐字相同（幂等）。
- **顺序有讲究**：必须先改 route 件、**最后**才 `--emit`（`--emit` 会把当时的 route 件 sha16 写进 `DECL-ANCHORS`；先 emit 后改件 ⇒ `DECLDRIFT` 非 0）。

### 3.1 "只做加法"的机器证

`--emit` 重生成的声明文件，**去掉时间戳/锚点两行后**与改前逐行 `diff`：

```
106a107,108
> ID	D-G88	req=KD	present=KD
> ID	D-G89	req=KD	present=KD
107a110
> ID	D-G90	req=KD	present=KD
```

⇒ **只有 3 行新增、0 行删除、0 行修改**；既有 123 条的 `req=`/`present=` **一字未变**（`present` 本来就是 `KD`）。

---

## §4 `inputs_fp` 影响判断（**哪几件在其中**）

**结论：本车道的编辑对 `inputs_fp` 零影响 —— 现场实测逐位不变。**

- **判据**：不看注释、**真调用** `build/close-wave.sh` 的 `fp_inputs()`（机械抽出函数体后调用；`close-wave.sh` 顶层会一路跑到 `exit 0`，**故绝不可 `source` 整个文件**）。
- **读数**：`fp_inputs()` = `84294170b97488e36e2d2f6c60bb7a25aa05a827af9b81a01807b5b0c66afbcd`，**开工 = 收工，逐位相同**。
- **覆盖面大小**：**147 件**。逐件核我在编辑清单里的**每一件**：

| 我编辑的件 | 在 `fp_inputs()` 覆盖面里的命中数 |
|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | **0** |
| `docs/CURRENT-STATE.md` | **0** |
| `handoff.md` | **0** |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | **0** |
| `docs/ROUTES.md` | **0** |
| `build/MilBridge/tools/defect-registry-declared.tsv` | **0** |
| `build/MilBridge/W96A-report.md` | **0** |

- **为什么**（逐条读 `fp_inputs()` 的覆盖面）：四条 `find` 链分别只收 `src/WpfGfx.Linux.Native/tools`、`build`（生效 `-maxdepth 1`，且只认 `patch-*.py`/`port-lib.py`/`integration-wave.sh`/`close-wave.sh` 四个名字）、`build/shims/**/*.cs`、`src/WpfGfx.Linux/**/*.cs`、`src/WpfGfx.Linux.Native/**/*.{c,h}`；末尾那个 `printf` 白名单**收的是 `defect-registry-check.sh` 本身（不是 `declared.tsv`）**，且四条链**都带** `-not -path '*/obj/*' -not -path '*/bin/*' -not -path '*/.artifacts/*'`。⇒ `samples/**`、`docs/**`、仓根 `handoff.md`、`declared.tsv` **一律不在覆盖面内**。
- ⇒ **本次不是设计性变更，`inputs_fp` 不该动、也确实没动**；**无须**在 `IN_FP_0` 采样之前安排本件（但 W94A 的重钉会**读**登记与路由件 —— 这正是本件抢在它前面完成的原因）。

---

## §5 四处地图改动逐字（`docs/ROUTES.md`）

### 5.1 `TASK-0107` → ✅（§14 附录 `:342` ＋ **新增** §13 树行 `:190`）

⚠️ **与任务书不符的现场事实**：任务书写"§13 树 ＋ §14 附录"，但编辑前 `grep -n 'TASK-0107' docs/ROUTES.md` **只命中 `:338` 一处（§14）** —— **§13 树里根本没有 `TASK-0107` 这一行**。我按判据 #3（只做加法）**新增**了一条 §13 树行（作为 `TASK-0106` 的兄弟，插在它子块之后、`02xx` 之前），使树与附录一致。

- **§13 树新增**（`:190`）：
  `│   ├─ TASK-0107 [Next] ✅ **已办（\`#50\` 波尾，车道 W93A，报告 \`build/MilBridge/W93A-report.md\`）** —— \`D-G83\` 后续 \`H2\`：**两个问题都有读数**：\`H2-a\` **运行期不跟随**（4 格 \`FAIL\`，全是运行期改动格；正对照 \`W2-TOGGLE\` 一按即正确落 \`521 by 417\` ⇒ **通道没坏、缺的是触发器**）＋ \`H2-b\` 本机**有** WM（私有 \`Xvfb :182\`＋\`xfwm4\`）且约束**真生效**（客户请求 \`1000x800→667x500\`／\`300x200→521x417\`；拖边框**对照窗** \`667x500→937x692\`、**受限窗纹丝不动**）`
  - 子行 `:191`：`│   │   ├─ ⚠️ **反极性 = \`VACUOUS\`**（按**先写死**的口径，如实报）：\`W1\` 的 X 侧提示在 14 个 stage 里**一次都没移动过** ⇒ "回到旧值"与"从来没跟过"**不可分** ⇒ **不构成反极性证据，不许当绿**`
  - 子行 `:192`：`│   │   ├─ 🆕 **同趟新登记**：\`D-G88\`（\`H2\` 本体 = 运行期改提示到不了 X；终态死锁 ＋ 预算**计"问"不计"改"**）、\`D-G89\`（\`xprop … | grep -q window\` **恒真** ⇒ "等 WM 起来"等于没等）、\`D-G90\`（\`[WMSIZE_DIAG]\` **每进程 40 行硬截断** ⇒ 不能当派发总数）`
  - 子行 `:193`：`│   │   └─ **落地拆新号**（本件**零产品改动**，探针在仓外）：\`TASK-0108\`（\`H2\` 修法 \`P1\`–\`P4\`）／\`TASK-0703\`（恒真判定修法）—— 均属波 \`#51\``

- **§14 附录改写**（`:342`，**🔴 → ✅**，原判词保留并扩写）：
  `- \`TASK-0107\` [Next] ✅ **已办（\`#50\` 波尾，车道 W93A，报告 \`build/MilBridge/W93A-report.md\`；**主控独立复核**：报告 sha 一致、仓内只这一个文件被动过）** —— \`D-G83\` 后续 \`H2\`，**两个问题都有读数**：`
  子行 `:343`（`H2-a`）、`:344`（`H2-b`）、`:345`（反极性 `VACUOUS`）、`:346`（上限 `3` 的两种吞法）、`:347`（新登记 ＋ 落地拆新号）—— 内容与 §1.1 同源，`H2-a` 内含 `SUMMARY A1_informative=29 PASS=5 FAIL=4 VACUOUS=20` 与四格名，`H2-b` 内含 `_NET_SUPPORTING_WM_CHECK window id # 0x4000ae`／`_NET_SUPPORTED n=75`／**重定父**／`1000x800→667x500`／`300x200→521x417`／对照窗 `667x500→937x692`。

### 5.2 **新增 `TASK-0108`** [Next] 🔴（§14 `:348`；**核实未被占用**：`grep -c 'TASK-0108' docs/ROUTES.md` = **0**）

`- \`TASK-0108\` [Next] 🔴 **\`H2\` 落地：让"运行期改尺寸提示"到得了 X**（\`D-G88\`，对策 = W93A 报告 §5 的 \`P1\`–\`P4\`，波 \`#51\`）：` ＋ 四条子弹：
- `P1`（必做，`src/WpfGfx.Linux.Native/src/win32_core.c`）把"**终态 ＋ 次数上限**"换成"**缓存上次已发布值，值变了才 `XSetWMNormalHints`**" —— 幂等、无消息风暴，**删掉两个停止条件**（`hints_map_declared` 终态与 `hints_map_asks<3`）。
- `P2`（必做，**这就是"运行期改"的触发器**）在 `SetWindowPos`/`MoveWindow` 的尺寸**真变**路径上补一拍 ⇒ 改**紧**必到。
- `P3`（**需主控裁定**）改**大**那半**无触发器可打** ⇒ 需**托管侧通知**；`P3-a`（shim `OverrideMetadata` 合法性）**未验** ⇒ 落地前先建**最小探针**。⚠️ **不推荐**只把上限 `3` 改大 —— 它计"**问**"不计"**改**"，改大只是延后死锁。
- `P4`（必须与 `P1` 同趟）**重入闸** ＋ 新判据"**X 调用次数 == 值变化次数**"（不风暴的证据）。
- ⚠️ 反极性**必须重造**（本轮的 `VACUOUS` 不算）：`改紧 → 提示跟到新值 → 撤回 → 提示跟回旧值`；装置已就绪（W93A 的 `W1/W2/W3` 三窗一台 ＋ `xprop` 判据 ＋ `judge.py`）。

### 5.3 `TASK-0702` §13 树行状态修正（`:248`）

- **改前**：`│   └─ TASK-0702 [Next] 🔴 \`R-GATE\`：把"连续点击"判据收编进仓并接进 \`verify-all\``
- **改后**：`│   └─ TASK-0702 [Next] ✅ \`R-GATE\`：把"连续点击"判据收编进仓并接进 \`verify-all\``
- **只改状态位 `🔴 → ✅`，判词一字未动** —— 依据是 §14b `:292` 已写 `✅ **已办（\`#50\`，车道 W84A）**`（`R_GATE=PASS crit=13/13`）；树与附录此前**互相矛盾**，本次以附录为准对齐。

### 5.4 **新增 `TASK-0703`** [Next] 🔴（§14 `:354`；**核实未被占用**：`grep -c 'TASK-0703' docs/ROUTES.md` = **0**）

`- \`TASK-0703\` [Next] 🔴 **修掉"等 WM 起来"的恒真判定**（\`D-G89\` 的落地，波 \`#51\`）：把 \`xprop -root _NET_SUPPORTING_WM_CHECK | grep -q window\` 换成**真判据** —— \`xprop -root _NET_SUPPORTING_WM_CHECK\` 必须解析出**窗口 id**（如 \`grep -q 'window id #'\`）且 \`xprop -id <id> _NET_WM_NAME\` 可读，或直接判 \`_NET_SUPPORTED\` **非空** ＋ **重定父**；并**盘点**全仓同类写法（\`grep -rn '_NET_SUPPORTING_WM_CHECK'\` 逐处列出，已知既有实例 \`build/MilBridge/W53A/cell3.sh:26\`）。⚠️ 现状**方向安全但会骗人**：等待第一次就 \`break\` ⇒ 自证行可能打"WM 不在"而 WM 其实在场（**假阴性**）。`

> ⚠️ **§5.4 里那个"全仓盘点"是留给 `TASK-0703` 落地时做的**，本条**未执行**（本件是登记车道，跑全仓 `grep` 会把 `arm-logs`/产物一起卷进来；且已知点仅 `W53A/cell3.sh:26` 一处 —— 见 §7 未做到项）。

---

## §6 册里"40 行截断是否已登记"的核查结论

**任务要求的现状核查（先搜再决定给不给新号）—— 结论：未登记。**

| 搜索串（权威册 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`） | 命中 |
|---|---|
| `wmsize_diag` | **0** |
| `WMSIZE_DIAG` | **0** |
| `40 行` | 4 处，**全部无关**（`:671` 截断 64 KiB／`:757` 归因行按空格截断／`:1031` 候选集截断／`:1219`&`:1691`&`:1699` 的"删 40 行"与"40 行的 WPF 应用"） |
| `截断` | 7 处，**无一**指 `wpf_wmsize_diag` 的 40 行封顶 |

⇒ 它**既不在册、也不属"既有条的补充"**，且**明确属于"判据/仪器认错对象"族**（与 `D-G84`「**仪器缺陷 · 判据射程错**」同族：**仪器看不见 ≠ 事情没发生**）⇒ 按判据 #6 **给新号 `D-G90`**（不是并进别的条）。

---

## §7 大白话小结（6 行）

1. **登记完成**：权威册新增 `D-G88`（`H2` 产品缺陷：**运行期改提示到不了 X**）、`D-G89`（`xprop … | grep -q window` **恒真**）、`D-G90`（`[WMSIZE_DIAG]` **每进程 40 行截断**，不能当派发总数）；末号原为 `D-G87`，**连续取号、无跳号**。
2. **两条机读行达标**：`DEFREG=PASS declared=126 route_ids=126`（原 123）＋ `DEFREG_DECLDRIFT=0`，`rc=0`，连跑两趟逐字相同。
3. **册与地图自洽**：`--emit` 去掉时间戳/锚点后与改前 `diff` **只有 ＋3 行、0 删 0 改** ⇒ 「只做加法」有机证。
4. **四个路由件里只有两个需要动**：`KNOWN-DEFECTS.md` ＋ `docs/ROUTES.md`；`CURRENT-STATE.md`/`handoff.md`/`ACCEPTANCE-BASELINE.md` 的 `D-G` 覆盖**只到 `D-G61`**，`D-G62`+ 一贯 `req=KD` ⇒ **一字未改**（`DEFREG` 的 route 键本来也只有 `KD/CS/HO/AB`，**`ROUTES.md` 不是 DEFREG 键**）。
5. **`inputs_fp` 零影响**：真调用 `fp_inputs()` ⇒ 开工=收工 `84294170b97488e3…`（覆盖面 147 件，我编辑的 7 件**命中全 0**）⇒ 非设计性变更，**无须**抢 `IN_FP_0`。
6. **没撞收尾链**：`~/w94a/STATUS.md` 停在 **`[STEP 1] integration-wave`**（未到"重取五臂"），我改完即报；我**没碰** `close-wave.sh`（`f440ccdb4e29a942`，与它自报值一致）。

### 未做到 / 存疑（如实标）

1. **任务书两处前提与现场不符**（已按现场处置，逐条列出）：① `TASK-0107` **不在 §13 树里**（只 §14 有），我**新增**了树行；② §14 里 `TASK-0107` 的状态位是 **`🔴` 而非 `🟡`**，我按 `🔴→✅` 改。
2. **未做** `TASK-0703` 要求的"全仓 `_NET_SUPPORTING_WM_CHECK` 同类写法盘点"（本件是登记车道；已知点仅 `W53A/cell3.sh:26`，盘点留给落地车道）。
3. **未取到** W94A 的实时进度之外的任何协调读数；本件**未**与 W94A 做锁/握手（无此机制），只靠 `STATUS.md` 时间序判断 —— **存在"我读 STATUS 之后、它推进到重钉"的残余窗口**（我用时远短于该窗口的推进速度，但**不是机证**）。
4. **未跑** `verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／任何构建（重活会撞收尾链）⇒ 本件的 `DEFREG` 与 `fp_inputs` 读数**未经端到端复跑**验证。
5. **`D-G88` 的判据正确性未由我复核** —— 我只登记 W93A 的读数（其 sha16 与"仓内只动一个文件"由主控独立核过）；`092c44b3bca27cdd` 与全文件 `ea7eb63bed9e3f25` 的差异已查明是**口径不同**（W93A 末行自述用的是 `head -n -2 本文件 | sha256sum | cut -c1-16`），**不是件被改过**。
6. **未改**任何既有号的值/判词、未删任何号、未把任何红改绿；**未碰**产品件与 `known-red.json`。

---

## §8 本报告件 sha16

- `build/MilBridge/W96A-report.md` —— 现场算：`sha256sum | cut -c1-16`（见收尾消息，未手抄）。
- 本件**只写**：`build/MilBridge/W96A-report.md`（新建）＋ §2 表里列出的 3 件（`KNOWN-DEFECTS.md`／`docs/ROUTES.md`／`defect-registry-declared.tsv`）＋ `~/w96a/declared.tsv.before`（改动前备份）。**其余零写入。**
