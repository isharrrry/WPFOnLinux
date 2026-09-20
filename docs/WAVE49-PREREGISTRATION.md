# 波 `#49` —— 收掉 `#48` 冻后剩下的**六条已登记项** ＋ 三条**覆盖率缺口**（`PF`/`WB` 进校验器表、`R-GATE` 正向接线、`W1` 自动同步链）

> 本文件是**落地前写死**的预登记（纪律：判据先写、读数后取；改了判据必须在本文件里留痕，不许"事后对齐"）。
> 起点世代：**`#48`（`gen=#48 sha16=540725342059b820`，593,971 B，冻后 `verify-all` ×2 全绿）**。
> 本波**会动 `verify-all.sh` 与 `build/integration-wave.sh`** ⇒ `inputs_fp` **必变**（见 §4，这是预期位移，不是事故）。

---

## §0 起点现场（可复算）

| 量 | 值 | 来源 |
|---|---|---|
| 冻结世代 | `gen=#48 sha16=540725342059b820` | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` ＋ `docs/CURRENT-STATE.md:9` |
| 桶（五件）现盘 | `libwpfwin32.so abf6879c027c5e73`／`wpfgfx_cor3.so e3ea092010734f44`／`pc 9465f9dce39e2dfc`／`pf 1011da6390c3bf1e`／`wb 79740e9ba7fbf9ca` | `bash build/MilBridge/tools/sync-applocal.sh --list` |
| 冻后两趟 | `25 ✅ / 0 ❌`、871 pass / 2 skip、`COLUMN_FLOOR=PASS reg=25c21ca0f33208ae base=540725342059b820` | `$HOME/w50a/06-verify-all-pre.log`（`944d341a8d7460ef`） |
| 四颗牙 | `BASELINEGEN=PASS decl_gen=#48`｜`ARMLOG_SHA=PASS 5/5`｜`COLUMN_FLOOR=PASS`｜`DEFREG=PASS declared=97 route_ids=97` | 本文件写作时现跑 |

**交互验收（MVP 面）已完成**：`D-G56`（`NameScope`）×`D-G55`（捕获释放）在冻结件上**行为面 + 反极性 + 产品级第二腿**三项全绿（车道 W51B `e0880bf44c189b31`）⇒ 用户报的「输入框与列表项点击无反应」**已闭合**。

---

## §1 剩余必做清单（**ASCII 树 —— 这是"还缺什么"的唯一入口**）

```
剩余必做（起点 #48，2026-09-20）
│
├── A 产品面（用户可见；不修掉就不算"完整 MVP"）
│   ├── A1 D-G57  页签标题 + 「实用示例」按钮**文字零墨**（页签可点、点了真换页 ⇒ 不是命中问题）
│   │             ✅ **收窄**（W52A）：**整块零绘制** —— 连选中页签那 2px 下划线都没落屏（74x27 全 1 色）、
│   │                Placeholder 也无字；74px = Padding×2 ＋ **内容 54px** ⇒ **排除**空串/零宽裁剪
│   │                仍二选一：**(a) 子树画刷解析成白 ／ (b) 子树绘制指令未进通道** ⇒ 先加一格只读探针劈开（§7.4）
│   ├── A2 D-G58  「工具」页 item#2 `Effects` 加载即 `NotImplementedException`（栈顶 `MediaContext.CommitChannel`）
│   │             ✅ **根因已确证**（W52A）：首个（唯一失败原因）= **`0x6c MilCmdPixelShader`**（243 条批里排 #55）
│   │                ＋同批 **7× `0x70 MilCmdShaderEffect`**；桥侧**没有这两个 `case`**（`MilCommandLayout.cs:216/:217`
│   │                登记在 `s_notImpl`、`MilCommandDispatcher.cs:38` 短路、`MilResourceTable.cs:244` 缺两个 `TYPE_*`）
│   │                ⇒ 判据与"不许静默 no-op"的要求见 §7.4
│   └── A3 D-G61  `[GEO]` 仪器 ＋ 点下拉项 ⇒ **静默 SIGSEGV**（仪器先崩、读数作废）
│                 先修仪器（`is Visual` + try/catch，与 `Describe()` 同款，已修一半）；
│                 若根因落在端口（弹窗的 PresentationSource 生命周期）⇒ **升级为产品缺陷**另行登记
│
├── B 读数可信度（工具/门禁自身的洞；不修则"绿"不可信）
│   ├── B1 D-G59  `verify-all.sh` 选 X 显示：候选用**字符串序最小**且选定后**整趟不复核**
│   │             现场代价：`#47` 冻后 run2 选中 `:66`（run1 是 `:97`），该显示在 `[2]` 前已死
│   │             ⇒ `XState=available` 却 47 例 X 用例静默跳过（`SKIP_GUARD=FAIL` 才抓住）
│   ├── B2 D-G60  `ARTIFACT_SRC_FP` 的**身份记录一出生就是陈旧的**（`integration-wave.sh` 段 3.5/3.6 倒置）
│   │             机制：3.5 先写身份记录、3.6 才刷新 app-local 副本 ⇒ 记录描述的是"刷新前"的树
│   ├── B3 R-GATE 「连续点击」只有**负向** `EXPECT=(… "clickprobe:!22D3EE")`；正向判据**没接门禁**
│   │             载体已建（⑬ `clickprobe` 块自报 `EVT`/`POS`），但块自己如实写 `INCONCLUSIVE`
│   │             ⇒ 点击判据今天**由仓外临时仪器驱动**（`$HOME/w47b-click.sh`）⇒ 不可复算、没人看着
│   └── B4 R-CSRC `src/WpfGfx.Linux.Native/src/**` **不在 `fp_inputs()`** ⇒ 改原生源（含 `win32_x11.c` 的
│                 `D-G50`/`D-G55` 修法）**不动 `inputs_fp`** ⇒ 「输入稳定性 波前==波后」对它是**空成立**
│
└── C 覆盖率缺口（"检查器没说话"被读成绿）
    ├── C1 PF/WB 两份权威**不在** `check-applocal-sync.sh` 的 `ITEMS`（`:160-168`）
    │          ⇒ 删掉任何一份 `PresentationFramework.dll`/`WindowsBase.dll` 副本**连 `MISSING` 都不报**
    │          （`D-A2` 同族：PC 那一格 `#23` 才补上；PF/WB 至今空着）
    │          **本文件写作时实测的现场规模**（同配置口径比对；排除 `CycleStub.*` 桩件）：
    │            PF：19 份副本（宿主目录 11）⇒ **与 Debug 权威不同的宿主副本 5 份**、Release 口径 3 份
    │            WB：56 份副本（宿主目录 34）⇒ **与 Debug 权威不同的宿主副本 19 份**、Release 口径 9 份
    │            典型落后件：`build/PresentationFramework.Linux/bin/Debug/WindowsBase.dll b39730566b1b480f`
    │              ≠ `build/WindowsBase.Linux/bin/Debug/WindowsBase.dll 19de048ecb968daa`（**连"框架件自己的输出目录"都落后**）
    │            ⇒ Debug 口径 **24 份**（PF 5 ＋ WB 19）今天**没有任何门在看**（Release 口径另 12 份按
    │              `NO-AUTHORITY` 只提示）—— 这就是 `W1` 的真实规模
    │          ✅ **已落地**（车道 W52C `2d13cae7b56242d1`）：覆盖面 6→8、`expect 125→190`、自检 18/18、
    │             两极化齐（改前删副本**完全静默**／改后具名 `MISSING=2` rc=1）；真实树新增
    │             34 `STALE` ＋ 4 `UNEXPECTED-DIFF` ＋ 4 `DIVERGENT` 组，**全部逐条登记**（见 §10）
    │          └── C1b `applocal-expect.py` 读不到声明件时**静默回退 Debug** ⇒ 合成权威根里假红（§10 裁定 ③）
    │          └── C1c `samples/ThirdPartyMini` 的 4 条 `UNEXPECTED-DIFF`：补声明图 or 刷新（§10 裁定 ⑤）
    │          └── C1d **`D-G62`**：`NO-AUTHORITY` 在"声明配置=Release"下**结构性不可达**（恒 0 的死格，
    │                  读起来像"跨配置已被处理"）＋ 旧口径句方向已反 ⇒ 改具名 `CROSS-CONFIG` 诊断格（§10 裁定 ②）
    │          └── C6  切权威配置**必须同趟重跑** `--selftest`（`#39` 切配置后 4 例已红、无人知道）（§10 裁定 ④）
    ├── C2 W1   app-local 副本**没有自动同步链**（`libwpfwin32.so` 只经 `close-wave.sh [2/6]`；
    │          `wpfgfx_cor3.so` **一条链都没有**）⇒ 冻结件与探针实跑件可能不同代
    │          注：本轮已补**手工可复算**的一件 `build/MilBridge/tools/sync-applocal.sh`（`9805a0123770416c`），
    │          但**门禁里仍没有它** ⇒ 仍是债（本波接线，见 §3 C2）
    ├── C4 「判据件不在覆盖面」同族（本文件写作时**新发现**）：`build/DirectWrite.Linux/wic-shim/` 三件
    │          `check-applocal-sync.sh`（决定 `APPSYNC=`）／`applocal-expect.py`（决定**期望副本集合**）／
    │          `sync-applocal-authority.sh`（**真的写副本**）**一件都不在** `fp_inputs()`，也不在 `GEN_KEYS`
    │          —— 而 `build/close-wave.sh:309` 的 `[4/6] 身份自检` **正在执行**第一件
    │          ⇒ 今天"把判据放松/把某件从 `ITEMS` 里删掉"**零机器红**（与 `tline-gate.sh` 在 `#28` 之前同族）
    └── C3 残余登记（**本波不做**，只保留在册）：`P3` 阈值重标定、`tline.log` 不可程序化复现
              （只余 run 相关字段）⇒ 需要"能做/不能做"的明确裁定，不许静默留着
```

**口径**：A 类修完 ⇒ MVP 面闭合；B/C 类修完 ⇒ **"绿"可复算**。本波目标 = **A1/A2/A3 修完 ＋ B1–B4 修完 ＋ C1/C2/C4 接线**；C3 只出裁定。

---

## §2 判定点（代码级，落地前已闭合到行）

| 编号 | 判定点（现盘） | 事实 |
|---|---|---|
| B1 | `verify-all.sh:366-373` | 候选 = `pgrep -a Xvfb \| grep -oE ' :[0-9]+' \| tr -d ' :' \| sort -u` ⇒ **字符串序**（`:10 < :66 < :97`）；选定后只在 `[0]` 段内 `xdpyinfo` 验一次，`X_STATE`（`:399-403`）之后**再也不复核** |
| B2 | `build/integration-wave.sh:456-461`（段 3.5）／`:463-475`（段 3.6） | 段序 = 3.5 写 `ARTIFACT_SRC_FP` 身份记录、**然后** 3.6 才 `sync-applocal-authority.sh --apply` 刷新副本 ⇒ 记录里的 sha 是**刷新前**的 |
| B3 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh:325`（`BLOCKS`）／`:609`（`EXPECT`） | 只有 `clickprobe:!22D3EE` 一条**负向**判据；块本体（`samples/WpfFeatureProbe/FeatureBlocks.cs:1296-1305`）自报 `STATE`/`EVT`/`POS` 但**自己写 `INCONCLUSIVE`** |
| B4 | `build/close-wave.sh:104-188`（`fp_inputs()`） | 覆盖面 = `src/WpfGfx.Linux.Native/tools` 的 `patch-*.py` ＋ `build` 的 4 个具名件 ＋ `build/shims/*.cs` ＋ `src/WpfGfx.Linux/**/*.cs` ＋ 具名判据件清单 ⇒ **`src/WpfGfx.Linux.Native/src/**`（C 源）不在内** |
| C1 | `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh:160-168` | `ITEMS` 6 条具名权威：`libwpfwic.so`／`libwpfwin32.so`／Provider／`WpfGfx.Linux.dll`／`ReachFramework.dll`／`PresentationCore.dll` ⇒ **无 PF、无 WB** |
| C2 | `build/close-wave.sh:130`（`libwpfwin32.so`）／无（`wpfgfx_cor3.so`） | `wpfgfx_cor3.so` 的 app-local 副本**没有任何拷贝链**；两件的副本都**无判据** |
| A1/A2 | 见 §7 | 由车道 W52A 取证后回填（本波**先把判据写死**，取证结论一到即替换 §7 占位） |

---

## §3 判据（**落地前写死**；每条都给两极对照）

### B1 `D-G59` —— X 显示：**选定后必须整趟复核**（不许只验一次）
- 修法两条，**都做**：① 候选取值改**数值序**（`sort -n`）⇒ 同一台机器上跨趟**可复算**（`#47`/`#48` 的"字符串序"会让 `:10` 抢在 `:97` 前）；② **选定不是终局** —— 在 `[0]` 段选定之后、以及每条依赖 X 的用例之前，用 `xdpyinfo` 复核 `$DISPLAY`；死了就**按数值序重取**一个活显示并重定 `X_STATE`；一个活的都没有 ⇒ `X_STATE=unavailable` ＋ **具名** `X_DIED=1`（不许把跳过读成通过）。
- 判据（成对）：`Xvfb :171` 起好后选到它 ⇒ `[0]` 印 `chosen=:171` 且用例真跑；**中途 `kill` 掉 :171** ⇒ 必须出现具名 `X_DIED=1`（或重取到另一活显示并把 `chosen=` 换成它），且**不许**再出现"`X_STATE=available` 而 X 用例静默跳过"。
- 反极性（**必须实测**）：`SKIP_GUARD` 必须红（`#47` run2 的现场就是它红的）。

### B2 `D-G60` —— 身份记录必须描述**刷新后**的树
- 修法：把段 **3.5 挪到 3.6 之后**（或 3.6 之后**再**跑一次 `build/artifact-src-fp.py --write`）。**两条都做**：顺序修正 ＋ 记录里带 `at=` 与"本记录写于 app-local 刷新之后"的自述句（后者的意义：读者不必去猜段序）。
- 判据（成对）：故意把某份 app-local 副本换成旧 sha ⇒ 跑波 ⇒ 记录里的身份指纹必须与**刷新后的现盘**一致（`artifact-src-fp.py --check` 当场 `rc=0`）；**顺序修正前**同一实验必须 `stale`（现状即反极性现场，已实测 `#48` 波内复现）。

### B3 `R-GATE` —— 「连续点击」从**仓外仪器**收编成**门禁判据**
- 修法：把 `$HOME/w47b-click.sh` 收编进仓（`tests/WpfGfx.Linux.Tests/Presentation.Tests/run-clickprobe.sh`），给它**机器裁决**（rc + 机读行），判据**逐条写死**（全部读 `app.log` 的 `EVT` 行，**不读末态字段**）：

| # | 正向判据 | 反极性判据（同趟必须一起跑） |
|---|---|---|
| ① | 点 ListBox item[0] ⇒ `EVT lst.selection=1` | 点卡片右侧空白（控件之外）⇒ **新增 `EVT` 行 = 0** |
| ② | 点 TextBox ⇒ `EVT tb.focus` ≥ 1 | 点窗口外 ⇒ 无新 `EVT` |
| ③ | 点后键入 3 字符 ⇒ `EVT tb.text=` 行数 ≥ 3 且长度单调增 | 未点击就键入 ⇒ `tb.focus` 不增 |
| ④ | 点 ComboBox ⇒ `EVT combo.opened` = 1 ＋ 弹窗窗口出现（`IsViewable`） | 点下拉外空白 ⇒ 不得出现 `combo.selection` |
| ⑤ | 点弹窗 item[1] ⇒ `EVT combo.selection=1` ＋ `combo.closed` = 1 | — |
| ⑥ | 每次 mouse-up 之后 `cap=none`（`D-G55` 的机器指纹） | 修前件（`libwpfwin32.so e700c383…`）必须**红**：`cap=导航` 长期不释放 |

- 接线方式：**并进既有门禁步**（`verify-all` 步数保持 **25**，不动那条"25 步"声明链）；新脚本进 `fp_inputs()` 的具名判据件清单（**与 `tline-gate.sh` 同一条流程代价**：改它必须安排在 `IN_FP_0` 采样之前）。
- 判据（成对）：修后件 ⇒ 六格全绿；**只换回 `libwpfwin32.so e700c383ec1ecdc8`** ⇒ ①②③④⑤ 红、⑥ 红（`#48` 冻前已在 hc 上实测过这张表，见 `W48B-report.md`）。

### B4 `R-CSRC` —— 原生源进 `fp_inputs()`
- 修法：`fp_inputs()` 增一行 `find src/WpfGfx.Linux.Native -type f \( -name '*.c' -o -name '*.h' \) -not -path '*/obj/*' -not -path '*/bin/*'`（**必须带排除**，理由同 `#29` 的 `D-G31`：覆盖面不许吃构建产物）。
- 判据（四极性，与 `fp-inputs-hygiene-check.sh` 同法）：① 改 `win32_x11.c` 的注释 ⇒ `inputs_fp` **必变**；② 逐字还原 ⇒ **逐位回绿**；③ 只在 `src/WpfGfx.Linux.Native/obj/` 加一个 `.c` ⇒ **不变**；④ 只在 `bin/` 加一个 `.c` ⇒ **不变**。
- ⚠️ 流程代价（写进预登记）：从此**改原生源必须安排在 `IN_FP_0` 采样之前**（否则 `close-wave.sh [4/6]` 自报 `IN_FP_0 != IN_FP_1`）。

### C1 —— PF/WB 进校验器的权威表
- 修法：`check-applocal-sync.sh` 的 `ITEMS` 增两条（`build/PresentationFramework.Linux/bin/$SELFBUILT_CONFIG/PresentationFramework.dll`、`build/WindowsBase.Linux/bin/$SELFBUILT_CONFIG/WindowsBase.dll`），并同步 `applocal-expect.py` 的 `ITEMS`（**两处必须一致**，这是它自己的文件头纪律）。
- 判据（成对）：① 删掉任一份 PF 副本 ⇒ 必须**具名** `MISSING` 且 rc≠0（现状：**静默**）；② 整份 `cp -p` 还原 ⇒ 回绿。
- ⚠️ 预期副作用（**本文件写作时已实测规模，免得冻后读成事故**）：同配置口径下与权威不同的**宿主副本** —— PF **Debug 5 份**／Release 3 份，WB **Debug 19 份**／Release 9 份（已扣 `CycleStub.*` 桩件）。其中一条特别值得看：`build/PresentationFramework.Linux/bin/Debug/WindowsBase.dll b39730566b1b480f` ≠ 权威 `19de048ecb968daa`⇒ 连"框架件自己的输出目录"都是陈旧的。
  ⇒ 纳入后这些会**首次进入判定**：`mtime` 早于权威的会被波尾 3.6 **刷成权威**（这正是要的收敛），刷不掉的（`NEWER-DIFF`）**只告警不许盲拷**；若出现"刷不掉且不该刷"的条目 ⇒ **逐条登记**（照 PC 的 `known-red-PC-copies.md` 先例），**不许为了让树变绿而改判据**。
- 附带判据（**新发现，同趟一起做**）：`build/PresentationFramework.Linux/bin/$cfg/WindowsBase.dll` 与 `build/WindowsBase.Linux/bin/$cfg/WindowsBase.dll` 的 sha 差异 ⇒ **措辞已按现场更正**（W52C 实测）：`$cfg=Release`（= 现行声明配置）**两处相同**（都 `79740e9ba7fbf9ca`、均 OK）；只有 `$cfg=Debug` 不同（`b39730566b1b480f` vs `19de048ecb968daa`）。该条要**具名报出**这件事**已成立**：`WindowsBase.dll [Debug]` 组的成员清单里两处都在（见 `known-red-PFWB-copies.md` 表 D）。

### C2 `W1` —— app-local 自动同步链
- 修法：把 `build/MilBridge/tools/sync-applocal.sh`（`9805a0123770416c`）接进波尾（`close-wave.sh` 的 `[2/6]` 段旁）与 `integration-wave.sh` 段 3.6 之后，**对"五件"逐件刷新 + 回读断言 + manifest**；`wpfgfx_cor3.so` 的副本**必须与发布记录的 `BRIDGE_SO_SHA256` 同源**（不许只看 mtime）。
- 判据（成对）：① 把 `wpfgfx_cor3.so` 的某份 app-local 副本换成旧 sha ⇒ 波尾必须把它刷成权威并在 manifest 里留行；② 修前同一实验**静默**（现状）；③ manifest 0 行时**不许**当成"已核对"（它自己已实现"拒绝写空 manifest"）。
- ⚠️ 流程代价：`sync-applocal.sh` 从此**是判据件** ⇒ 必须同时进 `fp_inputs()` 与 `GEN_KEYS`（改它要安排在 `IN_FP_0` 之前）。

### C4 —— 「决定 `APPSYNC` 与"期望副本集合"的三件」进覆盖面
- 现场（**本文件写作时实测**）：`build/close-wave.sh:309` 的 `[4/6] 身份自检` **执行** `check-applocal-sync.sh` 并用它的 rc 决定印 `✅ APPSYNC=PASS` 还是告警；而这三件
  ① `check-applocal-sync.sh`（判据本体）② `applocal-expect.py`（**期望副本集合**的声明式来源，由它产 `#EXPECT|` 行）③ `sync-applocal-authority.sh`（**真写副本**的执行者）
  **一件都不在** `fp_inputs()`、也不在 `GEN_KEYS`（实测：`grep -n 'applocal' build/close-wave.sh` 只命中 `:309` 那一行**调用**）。
  ⇒ 今天"把 `ITEMS` 里某件删掉"／"把某类口径从判红改成告警"／"改期望集合的推导" **零机器红** ⇒ 与 `tline-gate.sh` 在 `#28` 之前、四个核对器在 `#31` 之前**同族**。
- 修法：三件按**具名件**进 `fp_inputs()` 的 `printf` 清单（照 `tline-gate.sh` 那一段的写法；**别塞进续行链** —— `close-wave.sh:176-178` 记着"`#` 注释会把续行链尾吃掉"的血泪）。
- 判据（四极性，与 `#28`/`#31` 同法）：① 给 `check-applocal-sync.sh` 加一行注释 ⇒ `inputs_fp` **必变**；② 逐字还原 ⇒ **逐位回绿**；③ 改 `applocal-expect.py` 的 `PROPS` 里某个值 ⇒ **必变**；④ 改 `build/DirectWrite.Linux/wic-shim/` 下的**非这三件**（如 `wic_proxy.c`）⇒ 由 C4 之外的覆盖面决定（本波**不**顺手扩大**，如实划界**）。
- ⚠️ 流程代价与 B3/C2 相同：从此改这三件必须安排在 `IN_FP_0` 采样之前。

### A1/A2/A3 —— 判据待 §7 回填后写死
- A3 先行可写的部分：修**仪器**（`[GEO]` 走 `VisualTreeHelper` 前判 `is Visual`、`PointToScreen` 与 `CurrentSources` 枚举都包 `try/catch`），判据 = 「`HC_GEO_EVERY=2` ＋ 点下拉项 ⇒ `alive=yes`」，反极性 = 「修前 ⇒ `alive=no` 且无异常文本（**静默** SIGSEGV）」。
- A1/A2 的判据必须等 W52A 的根因（§7）落地后再写 —— **不许先写一个"看起来能过"的判据**。

---

## §4 九位与 `inputs_fp` 的**预期位移**（先声明，免得冻后读成事故）

| 位 | 本波预期 | 理由 |
|---|---|---|
| `bridge`（`wpfgfx_cor3.so`） | **变** | 若 A2 的 `E_NOTIMPL` 落在桥侧命令 ⇒ 必须补实现 |
| `pc` / `pf` / `windowsbase` | **大概率变** | A1（零墨）若落在 `TextBlock`/`TabItem` 呈现路径 ⇒ 动 PF；A2 若落在 `MilChannel`/`MilPresentation` ⇒ 动 `WpfGfx.Linux.dll`（**不在五件里**，但进波） |
| `win32shim` | 可能变 | A3 若根因在弹窗 PresentationSource ⇒ 动 `src/WpfGfx.Linux.Native/src/**` |
| `provider` / `wic_shim` / `hbtextline` / `dwf` | **不变（预测）** | 本波不碰字体/图像/转发器 |
| `inputs_fp` | **必变** | B1/B3/B4/C2/C4 都要改 `verify-all.sh` / `close-wave.sh` / 新增或纳入判据件 ⇒ **这是设计使然**（`fp_inputs()` 自含 `close-wave.sh`） |
| `known-red.json` | 可能变 | C1 纳入 PF/WB 后可能出现新增在册红 |
| `GEN_KEYS` / 声明表 | 变 | B3/C2 的新判据件必须进 `GEN_KEYS`；`verify-all.sh` 的 `gen=#49` 四处同改（DECL 首行、散文行、步名清单、本文件 H1） |

**步数**：除非另有裁定，**保持 25 步**（B3 并进既有门禁步；若确实必须新增步骤，则四处声明 + 步名清单同趟改，且 `VERIFYALL-STEP-CHECK` 必须绿）。

---

## §5 写域与不撞车

- 主控写域：`verify-all.sh`（B1/B4）、`build/close-wave.sh`（fp_inputs/B4/C2）、`build/integration-wave.sh`（B2）、`build/DirectWrite.Linux/wic-shim/{check-applocal-sync.sh,applocal-expect.py}`（C1）、`build/MilBridge/tools/**`（B3/C2 脚本）、`docs/**`、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`。
- 车道写域（互斥，一次一条重活）：A1、A2、A3 各一条只读取证 → 修法落地时按文件排他（A1 与 A2 大概率改**同一个** `pf` ⇒ **必须串行**，不许并行编）。
- **纪律**：验证运行期间**不许**改 route 件（`KNOWN-DEFECTS.md`/`CURRENT-STATE.md`/`handoff.md`）与声明表 `defect-registry-declared.tsv` —— `#47`（改 `verify-all.sh` 本体 ⇒ 整趟作废）与 `#48`（改 route 件 ⇒ `declared 96→97` 漂移）两次事故都留档在册。

---

## §6 收尾链（与 `#46`/`#47`/`#48` 同一条）

```
① 本文件（预登记）落在 docs/ 且 H1 含 `#49`
② WAVE_OWNER=… bash build/integration-wave.sh          # 缺 OWNER ⇒ rc=9
③ ARMS_OUT=… bash build/MilBridge/tools/retake-arms-w23.sh
④ python3 build/MilBridge/tools/repin-generation.py --why '…'   # 之后 --check
⑤ 门禁 ×2（WPTD_BASELINE_OUT=… ；先 rm -f 输出；预期 6 行 result=PASS）
⑥ 冻前 verify-all（~14 min，预期**恰好 1 处**声明类红 = COLUMN-FLOOR 未重冻）
⑦ python3 $HOME/w21-verify/w27-freeze.py <valog> <rows> '#49'
⑧ 冻后 verify-all ×2（两趟都必须 rc=0 且 25 ✅ / 0 ❌）
⑨ 收尾记录（banner / frozen / record 三段）＋ `docs/CURRENT-STATE.md` 机器行 + `handoff.md` 速览
```

**本波特有的顺序约束**：B4/C2 一落地就改 `inputs_fp` ⇒ 这两条必须**在 `IN_FP_0` 采样之前**完成（即"独立准备趟"），否则 `close-wave.sh [4/6]` 会自报 `IN_FP_0 != IN_FP_1` 而 `exit 5`。

---

## §7 A 类取证结论（车道 W52A，`build/MilBridge/W52A-report.md` `8387bde7f9a3fdae`）——**判据按此写死**

```
§7.1 A2（D-G58）= 根因**已确证**（不是 NOINFO）
     首个（也是唯一失败原因）返回 E_NOTIMPL 的命令 = id=0x6c  MilCmdPixelShader
        · 位置：「工具」页 #2 `Effects` 加载那次 Commit() 的 **243 条批**里排 #55（len=240 handle=0x4a4）
        · 同批另有 **7× 0x70 MilCmdShaderEffect**（形状 = 每个效果先 PixelShader 再 ShaderEffect，
          与 HandyControl 六个 ShaderEffect 子类逐条吻合）
     发送点（上游）= Effects/PixelShader.cs:171/:180-191（入口 Generated/PixelShader.cs:140）
                     Effects/ShaderEffect.cs:545/:559-589（入口 Generated/ShaderEffect.cs:162）
     异常栈       = exports.cs:376 HRESULT.Check(…) ← MediaContext.cs:2151 Channel.Commit();
     桥侧缺的 case = src/WpfGfx.Linux/Commands/MilCommandLayout.cs:216/:217（s_notImpl）
                     ＋ MilCommandDispatcher.cs:38 短路 ⇒ DispatchCore 里**根本没有**这两个 case
                     ＋ MilResourceTable.cs:244 缺两个 TYPE_*
                     ＋ 桥/原生侧（build/MilBridge/src、src/WpfGfx.Linux.Native/src）**shader 命中 0 件**（无渲染入口）
     最小复现     = bash $HOME/w52a/dg58.sh r1
                    （env：WPF_LINUX_MIL_LOG / MIL_TRACE=1 / CMDLOG=1 / PREFLIGHT_BUDGET=200000
                      / 复核趟 CMDLOG_ID=0x6c,0x70）
     成对读数     = 同趟 #0/#1 页 notImpl **0** 且存活 ｜ #2 notImpl **12** 且 alive=no unhandled=1
                    （白名单趟用**另一台仪器**（命令层台账）给出同样 12 条，id/len/handle/顺序逐条相同）

§7.2 A1（D-G57）= 收窄到「**整块零绘制**」，最后一格仍 NOINFO
     确定性复现，四区读数与 W47A **逐位相同**（页签 1 色/0.00%、按钮 8/0.15%、搜索框 19/2.71%、导航项 69/10.47%）
     新读数（三条，都指向"不是字没画"）：
       ① 选中页签**整块**（74x27）也是 1 色 ⇒ **连模板里那条 2px 选中下划线都没落屏**；27 行逐行非众数像素全 0
       ② 搜索框只有放大镜图标，**Placeholder 也没字**
       ③ 页签 74 px = Padding 10,5 ×2 ＋ **内容 54 px** ⇒ **排除**"空串"与"ActualWidth=0 被裁剪"
          （现场读过 Sizes.xaml:7 / TabControlBaseStyle.xaml:3）
     同一 XAML 四处 {ex:Lang}：页签 TextBlock.Text ／ Button.Content ／ SearchBar.Placeholder **三处无字**，
       HighlightTextBlock.SourceText（导航项）**有字**，且键都存在（LangProvider.cs:1041/:1026）
     仍 NOINFO 的**一格** = (a) 该子树画刷解析成白 ／ (b) 该子树绘制指令**未进通道**（二选一）
     **差的那一步** = 进程内读子件 IsVisible/ActualWidth/Text/Foreground ＋ 该子树的通道指令计数
     ⚠️ 本报告如实标注：**翻极性对照未做**；`D-G58` 的"放行后不再 abort"是**方案不是读数**

§7.3 A3（D-G61）= 仍**未取**（本轮车道未覆盖）⇒ 保持 `NOINFO` + 已排除清单（`[GEO]`+点下拉项 ⇒ 静默 SIGSEGV）
```

### §7.4 由此**写死**的 A 类判据（取代 §3 里的"待回填"占位）

**A2（`D-G58` 修法）**——修法本体（波内落地，形态待定，但**判据先写死**）：
- 方向两条（择一或并用，落地时写明）：① 给 `0x6c`/`0x70` 补 `DispatchCore` 的 `case`（PixelShader 存字节码返 `S_OK`；ShaderEffect 按**恒等效果**）＋ `MilResourceTable` 补两个 `TYPE_*`；② 从 `s_notImpl` 移出这两条。
- 判据（成对）：① 「工具」页 #2 `Effects` ⇒ **`alive=yes`、`unhandled=0`、该页 `notImpl` 计数 = 0**；② **反极性**（现状即现场）：不补 `case` ⇒ 回到 `alive=no` ＋ `NotImplementedException`（12 条 notImpl）；③ 同趟 `#0/#1` 两页仍 `alive=yes`（防"修 A 页坏 B 页"）。
- 🔴 **不许静默**：本次是"**不 abort 但不渲染效果**"⇒ 必须**具名留痕**（一条只读日志 ＋ 在册登记写清"效果未实现/按恒等处理"）。**静默 no-op 是"假装实现"，本仓禁止**（纪律 47 族）。
- ⚠️ 该修法动 `src/WpfGfx.Linux/**` ⇒ 落在 `fp_inputs()` 覆盖面里 ⇒ **必须发波重建 + 重取臂 + 重钉 + 重冻**。

**A1（`D-G57`）第一步 —— 先取证、后修法**：
- 先加**一格只读探针**（hc 侧仪器，仓外；或进程内 dump）劈开 (a)/(b)：读该子树每个子件的 `IsVisible`/`ActualWidth`/`ActualHeight`/`Text`/`Foreground`（含解析后的画刷颜色）＋ 该子树的**通道绘制指令计数**。
- 判据：① 若 `Foreground` 解析成白/透明 ⇒ 归 (a)，**点名**画刷解析链的 `文件:行`；② 若子树**零绘制指令进通道** ⇒ 归 (b)，点名布局/呈现链的 `文件:行`；③ 两者都不是 ⇒ `NOINFO` ＋ 已排除清单（**不许**先写修法再补读数）。
- 修法落地后判据（写死备用）：页签行 `colors > 1`、按钮文字可辨、搜索框 `Placeholder` 有墨；**反极性** = 修前读数（1 色/0.00%）必须能被同一脚本复现。
---

## §8 本波**不做**（如实划界）

- `P3` 阈值重标定、`tline.log` 的可复现化 ⇒ 只出**裁定**（"做/不做 + 理由"），不动判据（避免与本波的多处判据改动互相掩盖）。
- `#47` 冻后只跑了 **1 趟有效 `verify-all`**（×2 规则的一次已登记偏差）⇒ 该偏差**不能补做**（树已前移），**保持留档**，不粉饰。
- 任何"为了让树变绿而放松判据"的改动：**不许**（纪律 47/21/27/28）。

---

## §9 准备趟**已落**（本文件写作当趟完成的、与 A 类取证无依赖的部分）

> 口径：本波的多处改动会移动 `inputs_fp`，因此凡"必须安排在 `IN_FP_0` 之前"的条目，都在**独立准备趟**先落地并各自验完（避免与 A 类取证互相掩盖）。

### §9.1 新工具（`#49` 前件，`C2` 的可执行体）
`build/MilBridge/tools/sync-applocal.sh` —— 「五件」权威件 ⇒ **任意目标目录**（可多目录、可仓外）的同步器：`--check`（只读核对，漂移 ⇒ rc=3）／`--dry-run`／`--list`／`--sweep`／`--with-aliases`／`--manifest`／`--selftest`；写盘用**临时件 + 同目录 `mv`**（不就地截断），每件**拷后回读并断言 == 权威**，每目标写 `.applocal-sync.tsv` manifest（**0 行拒绝写**）。
- `--selftest` **12/12 PASS**（陈旧⇒`SYNCED`／幂等⇒`ok=5`／`--check` 抓漂移 rc=3／缺权威 rc=1／`--dry-run` 不动盘／非宿主目录 rc=2 而 `--force` rc=0／自拷贝 `SAME`／`--list`）。
- 真实树两极对照（临时目录）：把 `PresentationCore.dll` 换旧 ⇒ `--check` `drift=1 rc=3`；同步 ⇒ `⟳ 6808cabe7955e99b → 9465f9dce39e2dfc（回读断言通过）`；再 `--check` ⇒ `ok=5 rc=0`。
- hc 应用目录（`/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`）实跑：`SYNC-APPLOCAL=PASS items=5 ok=5 rc=0` ＋ manifest 5 行（五件 sha 全命中 `#48` 冻结值）。
- **自伤与自纠（如实入册）**：首版在 `say "…# path：\`path\` 是…"`（双引号里裸反引号）踩了本仓**第 5 次**同款陷阱 —— `verify-all` 第 `[15]` 步 `SHELL-QUOTE-TRAP` 当场点名 `line=334 traps=4`（**该牙真的在工作**）；manifest 表头那几个词被命令替换吃掉（实测：写成 `# path： 是**目标目录下的文件名**； 是…`）。改法 = 换掉反引号；复跑 ⇒ `SHELL_QUOTE_TRAP=PASS traps=0 files=141`。
- 与既有两件的分工已写进文件头（**更正一次口径**）：`check-applocal-sync.sh` = **判据唯一实现**；`sync-applocal-authority.sh` = 执行该判据、刷**仓内** `SCAN_ROOTS` 的落后副本（**无目标目录参数、不服务仓外**）；本件 = **任意目录** ＋ 只保证"这五件与权威逐位一致" ＋ manifest。**本件不做判据**。

### §9.2 B4（`R-CSRC`）＋ C4 已落 `build/close-wave.sh` 的 `fp_inputs()`
- B4：新增 `find src/WpfGfx.Linux.Native -type f \( -name '*.c' -o -name '*.h' \) -not -path '*/obj/*' -not -path '*/bin/*' -not -path '*/.artifacts/*'`（现盘 **13 件**：`src/**` 11 ＋ `tests/**` 2）。
- C4：`printf` 清单新增三件 —— `build/MilBridge/tools/sync-applocal.sh`、`build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh`、`build/DirectWrite.Linux/wic-shim/applocal-expect.py`。
  **有意不纳入** `sync-applocal-authority.sh`（波尾真刷副本 ⇒ 会把"输入稳定性"自己搞成噪音，同 `arm-logs/` 的裁定）——**这是登记下来的边界，不是遗漏**。
- `inputs_fp`：`cad0801cf1dff2fdf1600b803315d1c57b0d2afcc9ebf45e170f2b3885677da4` → **`9e442a58f1a86598950f05bcb0595fac7777bec36b622717de571474e6c24585`**（**预期位移**，见 §4）。
- **八条极性腿全部 PASS**（判据见 §3 B4/C4）：① 给 `win32_x11.c` 加注释 ⇒ 变；② 逐字还原 ⇒ **逐位回绿**（`e3e1b3e10c88f6fe` 复原校验通过）；③ 只在 `src/WpfGfx.Linux.Native/obj/` 加 `.c` ⇒ **不变**；④ 只在 `bin/` 加 `.c` ⇒ **不变**；⑤ 给 `check-applocal-sync.sh` 加注释 ⇒ 变；⑥ 还原 ⇒ 回绿；⑦ 给 `applocal-expect.py` 加注释 ⇒ 变；⑧ 还原 ⇒ 回绿。
- 牙复核：`FP_INPUTS_HYGIENE=PASS coverage_n=142 artifact_n=0`（第 `[12]` 步口径："覆盖面里不许有产物路径"）｜`SHELL_QUOTE_TRAP=PASS traps=0`｜`PIPEFAIL_SIGPIPE=PASS`｜`VERIFYALL_SELF=PASS names=25 gen=#48 prereg=PASS`｜`BASELINESHA`/`BASELINEGEN`/`ARMLOG_SHA`/`COLUMN_FLOOR`/`DEFREG` 全 PASS（**冻结 `#48` 的四颗牙未受影响**）。

### §9.3 仍未动（留给波内，理由）
`B1`（`verify-all.sh` 选显示）／`B2`（`integration-wave.sh` 段序）／`B3`（收编点击驱动器进门禁）／`C1`（PF/WB 进 `ITEMS`，**含它自己的 17 例 `--selftest` 夹具要同趟补 PF/WB**）／`A1`–`A3`（等车道 W52A 的 §7 结论）。

### §9.4 B2（`D-G60`）已落 `build/integration-wave.sh`：段序对调（**带受控复现实验**）
- 改动：**先刷新产物副本（新 `3.5/5`）、再写身份记录（新 `3.6/5`）**（两段整体对调）；两段的编号口径在文件里显式声明：
  **`#48` 及以前** `3.5=身份记录`／`3.6=副本刷新`；**`#49` 起** `3.5=副本刷新`／`3.6=身份记录`（旧报告的引文按旧编号读，历史留档一字不动）。
- **受控复现实验**（全程**无构建、无重编**；日志 `$HOME/w52b/dg60-experiment.log` sha16=`7d97f3c995afccf0`）：
  1. 造"待刷新"现场：把 `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` 换成旧内容 `043eff4b1d8ecd7d` ＋旧 mtime。
     该件**是 PF 身份记录维度 B（peer）之一** —— `artifact-src-fp.py --peers PresentationFramework` 实测在列。
  2. **分类证明**：刷新器干跑把它列为 `REFRESH build/PresentationCore.Linux/bin/Debug/PresentationCore.dll 043eff4b1d8ecd7d → 9465f9dce39e2dfc`
     ⇒ 3.6 确实会改掉 3.5 覆盖面里的**被引件** —— **W50A 的机制在受控条件下复现**（不是转述）。
  3. **旧序（记录 → 刷新）**：`--write` 记下 `peer_fp=7c79696509b6cf09` ⇒ 刷新 ⇒ 紧接着 `--check` ⇒
     **`state=stale note=kind=peer；被引产物变了：build/PresentationCore.Linux/bin/Debug/PresentationCore.dll 043eff4b1d8ecd7d→9465f9dce39e2dfc`（rc=2）**
     —— 这正是 `#48` 冻后现场那条"**身份记录一出生就是陈旧的**"。
  4. **新序（刷新 → 记录）**：刷新（幂等，`refreshed=0`）⇒ `--write` ⇒ 紧接着 `--check` ⇒ **三件全 `state=ok`（pc/wb/pf），rc=0**。
- 附带收敛（实验的副作用；方向正确、逐件已核）：三份原本陈旧的 app-local 副本回到权威 ——
  `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll 043eff4b→9465f9dc`、
  `samples/ThirdPartyMini/bin/Debug/net10.0/PresentationCore.dll 043eff4b→9465f9dc`、
  `samples/ThirdPartyMini/bin/Debug/net10.0/ReachFramework.dll f4836ae3→be2d69ba`。
- **五件（`#48` 冻结值）逐件复核未变**：`abf6879c027c5e73`／`e3ea092010734f44`／`9465f9dce39e2dfc`／`1011da6390c3bf1e`／`79740e9ba7fbf9ca`。
- 牙：`SHELL_QUOTE_TRAP=PASS traps=0`｜`PIPEFAIL_SIGPIPE=PASS`｜`FP_INPUTS_HYGIENE=PASS coverage_n=142 artifact_n=0`。
  `#49` 起 `inputs_fp` 现值 = **`35ca3108d519aa5b8a17609f11f9b5b661ede91a9f5cb2eca99b83a7e03402b5`**（预登记 §4 已先写明"必变"）。
- ⚠️ 如实划界：本实验证明的是"**段序**是成因"（受控两序对照），**不是**"整波跑一遍就收敛" —— 后者由波内
  `integration-wave.sh` 第 `[4/6]` 的 `artifact-src-fp.py --check` 在**真波**里再证一次（判据：波尾 `state=ok`）。
- ⚠️ 自伤一处（如实入册）：本轮首次追加本节时，我自己的 `cat >> … <<MD`（**未加引号的 heredoc**）把正文里的反引号当成了命令替换
  ⇒ 正文里所有反引号跨度**被吃掉**、stderr 一堆"未找到命令"。已改用 python 写入重做本节。
  （这与 `close-wave.sh:176-178` 记的血泪同族：**别在未引用的 heredoc 里写反引号**。）

---

## §10 `C1` 落地读数（车道 W52C，`build/MilBridge/W52C-report.md` `2d13cae7b56242d1`）与**主控裁定**

### §10.1 落地与读数（原文照录，两趟同一形态命令）

| 量 | 改前 | 改后 |
|---|---|---|
| `APPSYNC` | `MISMATCH`，`rc=1`（那 1 条是 PC 册表 B 的 `tools/GeometryOracle`，与本任务无关） | `MISMATCH`，**`rc=1`（rc 不变）** |
| 计数行 | `OK=116 MISMATCH=1(STALE=1) MISSING=0 UNEXPECTED=12[EQ=12 DIFF=0] DIVERGENT=1 NO-AUTHORITY=0 LIB-COPY=21 SKIP(obj)=10 SKIP(stub)=12` | `OK=135 MISMATCH=35(STALE=35) MISSING=0 UNEXPECTED=16[EQ=12 DIFF=4] DIVERGENT=5 NO-AUTHORITY=0 LIB-COPY=33 SKIP(obj)=14 SKIP(stub)=20` |
| 期望集合 | `expect=125` | `expect=190`（+65 = 各工程对 PF/WB 的 `<Reference>` 闭包） |
| 生效声明 | — | `ITEMS_SYNC=YES`（两处 `ITEMS` 6→8 同趟改；`applocal-expect.py` 的 `ITEMS` 同源） |
| 自检 | **改前 `D/E/O/P` 四例就已红**（`#39` 于 09-19 11:11 切权威配置，晚于该件最后一次改动 11:03 ⇒ 没人重跑过 selftest；实测首红 `SELFTEST_D rc=1`、其后 14 例根本没跑到） | **18/18 全 PASS、rc=0**（实测是 **18 例**，我上一版写 17 是**少算**） |
| 两极化 | 删 `samples/HelloWpf/bin/Debug/net10.0/{PresentationFramework,WindowsBase}.dll` ⇒ 计数行**逐字不变（完全静默）** | 同一实验 ⇒ 具名 `MISSING=2` ＋ `rc=1`（含期望来源原文）；`cp -p` 整份还原 ⇒ sha16 回到 `68d31452be50a89c`/`1b4ef36832ddca03`、`cmp` OK、复跑回基线 |
| 登记 | — | 新建 `build/DirectWrite.Linux/wic-shim/known-red-PFWB-copies.md`（`7b113a11934c54c4`）：表 A PF `STALE` **7** ／ 表 B WB `STALE` **27** ／ 表 C `UNEXPECTED-DIFF` **4** ／ 表 D `DIVERGENT` 组 4（信息性）⇒ 检查器回读「在册 **38** 条：仍红 38」（登记段**不进判定**，`APPSYNC` 仍 `MISMATCH`） |
| 收敛 | 刷新器**干跑**：`REFRESH ×34 ＋ REFRESH(group) ×4 = refreshed=38 newer=0 applied=0`（落点 `…/Debug/…` **31** ／ `…/Release/…` **7**） | **故意未 `--apply`**（车道三条理由：写域外／跨配置改写／"该不该红"待裁定） |

**车道自证没放松判据**：阈值、分类规则、`NO-AUTHORITY`/`SKIP` 口径、`APPSYNC` 判定式、退出码**一字未改**；它改的是**覆盖面（`ITEMS` 6→8）**与**自检夹具**（夹具随 6→8 件 ＋ `SELFBUILT_CONFIG` 配置化；含 `SELFTEST_D` 用一张临时声明件如实造出"权威配置 ≠ 副本配置"）。牙：`SHELL_QUOTE_TRAP=PASS traps=0`、`PIPEFAIL_SIGPIPE=PASS`、`SELFCONFIG_DEBT_CHECK=PASS live=141（改前 163，棘轮只减不增）`。

### §10.2 主控**裁定**（W52C 上交的两问 + 三条独立发现）

**裁定 ①（配置口径 —— 回答"那 38 份该不该刷"）：口径 = "权威即声明配置，副本必须与权威同代"。34 条 `STALE` 是**真红且应刷**；处置时机 = **波的 `3.5`**（`sync-applocal-authority.sh --apply`），**不许车道手工 `--apply` 越过波序**。**
- 依据（不是口味）：PC 那本册子（`known-red-PC-copies.md`）**已经**把 12 份"Debug 目录里装着 Release 内容"的副本读成 **`[在册红·已转绿]`＋"应从登记表移除"**（例：`build/DirectWrite.Linux/WiringSmoke/bin/Debug/PresentationCore.dll 9465f9dc`、`samples/HelloWpf/bin/Debug/net10.0/PresentationCore.dll`）⇒ **"收敛到声明配置"是本仓既成口径**；`#49` 只是把它延伸到 PF/WB。
- **可反驳条件（写死，便于将来翻案）**：若将来裁定"`…/bin/Debug/…` 目录必须保 Debug 件"，则本裁定**与 PC 那 12 条要一起翻转**（那时改的是 `3.5` 的口径与 `ITEMS` 的配置维度，不是这一份预登记）。
- ⇒ 因此 W52C 的"不 `--apply`"**判对了**（理由 1 成立；理由 2 由本裁定取代：跨配置**正是要收敛**的对象；理由 3 由裁定 ② 处理），但**必须**在波里执行、并留 `REFRESH` 行证据。

**裁定 ②（新登记项 `D-G62`，回答"`NO-AUTHORITY` 方向性是不是 bug"）：它不是"豁免这 34 条"的理由，而是一条**死格**，必须显式化。**
- 现场：`check-applocal-sync.sh:369` 的 `if is_release_path "$f" && is_debug_auth "$exp"` 在 `$SELFBUILT_CONFIG=Release` 下**恒 false**（`is_debug_auth` 匹配**权威**路径 `*/bin/debug/*`）⇒ `NO-AUTHORITY=0` **结构性不可达**。后果两条：① 一个**恒 0** 的格子**读起来像"跨配置已被处理"**（假保证族，同 `D-R4`/`D-G22`）；② 旧口径句"Release 副本按 `NO-AUTHORITY` 只提示"**方向已反**（今天 Release **才是**权威）。
- 修法（`#49` §3 `C1d`，**同趟连同口径句一起改**）：把该格改为**具名诊断格** `CROSS-CONFIG=<n>`（条件 = **副本路径的配置 ≠ 声明配置**），**仍不判红**；⚠️ 但**跨配置副本照样计入 `STALE`**（按裁定 ① 它是要被刷的，不是被豁免的）⇒ 这一格**只增加可见性，不放松任何一条**。
- 判据（成对）：① 造一份 Debug 目录里 sha≠权威的副本 ⇒ 计数行必须出现 `CROSS-CONFIG≥1` **且该份仍在 `MISMATCH/STALE` 里**；② 同配置陈旧副本 ⇒ `CROSS-CONFIG=0`、仍 `STALE`。③ 口径句必须与现场一致（`VERIFYALL-STEP` 那种"两处声明必须逐字一致"的体检法：把摘要格与散文句**同趟**对账）。

**裁定 ③（`C1b` / W52C §6.3）：`applocal-expect.py` 读不到声明件时**静默回退 `Debug`** ⇒ 与"静默默认值"同族，必须改成显式失败。**
- 现场：`check-applocal-sync.sh:150` 读 `$(dirname "$0")/../../../build/SelfBuiltConfig.props`（**脚本相对**），读不到时 `selfbuilt-config.sh` **报错退出**；`applocal-expect.py:48` 读 `<argv[1]>/build/SelfBuiltConfig.props`（**AUTH_ROOT 相对**），读不到时 **静默回退 `Debug`** ⇒ 合成权威根里一侧 Release、一侧 Debug ⇒ `MISSING=5` **假红**（已在夹具层消掉，工具语义**未改**）。
- 修法：两处**同源**读同一份声明；读不到 ⇒ **`NOINFO` 且非 0**（不许有默认值）。
- 判据（成对）：① 把声明件挪走 ⇒ 必须 `NOINFO`/非 0（现状：**静默 Debug**）；② 放回 ⇒ 回绿。

**裁定 ④（流程项 `C6` / W52C §6.4）：**"切权威配置"必须同趟重跑检查器 `--selftest`。**
- 现场：`#39` 在 09-19 11:11 把权威切到 Release，而 `check-applocal-sync.sh` 最后一次改动是 11:03 ⇒ **`D/E/O/P` 四例当场变红、无人知道**（本趟才发现）。检查器的自检是它自己"读数可信"的前提（`:144-145` 自己写着"必须在静树上跑"）。
- 修法：在波尾（`integration-wave.sh` 的 `3.5` 之后）加一条**只读**自检：跑一次 `--selftest`，`SELFTEST_*` 汇总行**进日志并 `fail+1` 计红**（"检查器的自检红了"必须停，不许当告警）。
- 判据（成对）：① 故意把夹具里某件权威路径改回 Debug ⇒ 该步必须红并点名 `SELFTEST_D`；② 还原 ⇒ 回绿。

**裁定 ⑤（`C1c` / W52C §6.5.2，本波只登记、处置留待查）**：`samples/ThirdPartyMini` 的 4 条 `UNEXPECTED-DIFF`（PF/WB × Debug/Release）⇒ **该样例是否应随包带 PF/WB** 取决于它的部署意图（查 `run-thirdparty-mini.sh`）⇒ 处置二选一：**补声明图** 或 **刷新**。**不许**为了让 `UNEXPECTED` 归零而删 `ITEMS`。**不在本文件里替它下结论。**

### §10.3 对 §1 树的更新（`#49` 起生效）

- `C1` 已落地（覆盖面 6→8，`expect 125→190`）；残余 = `C1b`（静默回退）、`C1c`（第三方的 4 条处置）、`C1d`（`D-G62` 死格显式化）、`C6`（切配置必跑 selftest）。
- 新增 **`D-G62`**：`NO-AUTHORITY` 死格 ＋ 旧口径句方向已反（**登记动作放在波内**：现在只写进本预登记，**不动** `KNOWN-DEFECTS.md`/声明表 —— 那三者是在册判定的输入，冻后擅自改会重演 `#48` 那次 `declared 96→97` 的漂移）。
- `A1`–`A3`、`B1`、`B3` 状态不变（`B2`/`B4`/`C4` 见 §9）。

### §10.4 `C6` 已落 `build/integration-wave.sh`：新增 `3.7/5 判据件自检`
- 改动：在 `3.6/5`（身份记录）之后新增一步 `3.7/5 判据件自检（app-local 校验器 --selftest；#49 C6）`：跑
  `check-applocal-sync.sh --selftest`（日志 `build/.applocal-selftest.log`），**`rc≠0` ⇒ 计红（`fail+1`）并点名首几条 `SELFTEST_*`**；
  `rc=0` ⇒ 印最终汇总行。三态照旧：`SELFTEST=PASS` 绿 ／ `SELFTEST=NOINFO`（rc=3）**不许当绿**（同样计红）。
  段序：`3/4 重建` → `3.5/5 刷新` → `3.6/5 身份记录` → **`3.7/5 自检`** → `4/4 身份自检` → `5/5 输入稳定性`。
- **步骤体单独验证**（把该段原样抽出、`step()` 打桩后在真树上跑，`REPO=$PWD`）：红侧成立 ——
  输出 `❌ 判据件自检未 PASS（rc=1；汇总行：<未印>）` ＋ 点名 `SELFTEST_*(=FAIL)`，`C6_STEP_FAIL=1`（`fail` 确实 +1）。
- ⚠️ **本轮我自己的纪律事故（如实入册）**：我在**车道 W52C 正在改 `check-applocal-sync.sh` 的同一时间**跑了它的
  `--selftest` ⇒ 读到 `rc=1`／`SELFTEST_D=FAIL`／`SELFTEST_K=FAIL` 等**中途态**。**这不是树的读数，是"文件正在被写"的读数** ——
  本仓纪律"自检必须在**静树**上跑"（`check-applocal-sync.sh:144-145`）正是为这一刻写的。⇒ 处置：**该红侧读数只用于验证"步骤逻辑"**（它与红因无关），
  **绿侧（`SELFTEST=PASS` rc=0）等 W52C2 收工后在静树上重取**，取到之前**不得**把 `C6` 记为"已验证"。
- 余下按 §10.2 裁定 ④：这一步只保证"检查器自证"，**它自己不判 app-local**（判据仍唯一归校验器）。

### §10.5 `C1d`/`C1b` 已落（车道 W52C2，`build/MilBridge/W52C2-report.md` `2aa8f7fefd05b957`）＋ 主控在**静树**上的独立复核

| 项 | 读数（主控独立复跑，静树） |
|---|---|
| 检查器自检（**C6 的绿侧，本趟补齐**） | `rc=0`、`SELFTEST=PASS`、`^SELFTEST[A-Z0-9_]*=PASS` 计数 **18**（＋末行汇总 = 19 行匹配）—— 车队 W52C2 收工后取的，**不再是中途态** |
| 检查器本体 | `rc=1`；`OK=135 MISMATCH=35(STALE=35) MISSING=0 UNEXPECTED=16[EQ=12 DIFF=4] DIVERGENT=5 CROSS-CONFIG=101 LIB-COPY=33`；`APPSYNC=MISMATCH(…)` 与 `C1d` 之前**逐字相同**（= "只增可见性"的机器证） |
| 件 sha16（W52C2 改前→改后） | `check-applocal-sync.sh` `d82e920b49bb0f0f`→`40c3b35cf4ec7fc1`；`applocal-expect.py` `a7e05921b77524c2`→`dff2d29c800e4ba4`；`known-red-PFWB-copies.md` `7b113a11934c54c4`→`2a584c547247c3fc` |
| 全仓扫描器（静树复跑） | `SHELL_QUOTE_TRAP=PASS traps=0`（**证实我上轮读到的 `traps=2` 是 W52C2 的中途态**）｜`PIPEFAIL_SIGPIPE=PASS`（sites 75→77、safe 62→64）｜`FP_INPUTS_HYGIENE=PASS coverage_n=142` |
| 棘轮 | `SELFCONFIG_DEBT_CHECK=PASS live=140 max=167`（W52C2 起点 141 ⇒ **净减 1**） |
| 牙 / 记录 | `BASELINESHA`/`DEFREG`/`ARMLOG_SHA`/`COLUMN_FLOOR`/`VERIFYALL_SELF` 全 PASS；`REPIN_GENERATION=PASS`（**冻结 `#48` 记录仍自洽**） |

**裁定 ②/③ 的成对判据均已由车道实测**：`CROSS-CONFIG` —— (a) 跨配置目录里 sha≠权威 ⇒ `CROSS-CONFIG=1` 且**同一路径同时**印 `STALE`（**跨配置不是免红券**）；(b) 挪进声明配置目录 ⇒ `CROSS-CONFIG=0`、仍 `STALE=1`。`NOINFO` —— (a) 两处声明候选都缺 ⇒ 改前件 `rc=0` **静默**并拼 `…/bin/Debug/…`，新件 `rc=2` ＋ `#NOINFO|config-decl|…`、`#EXPECT` **0 条（不猜）**；(b) 放回 ⇒ `rc=0` 且按声明拼 `…/bin/Release/…`；调用方后果实测 = `APPSYNC=NOINFO` ＋ **`rc=3`**（工具级无信息 ⇒ 不许当绿）。
**⚠️ 旧网格已删**：`NO-AUTHORITY`／`is_debug_auth`／`CNT_NOAUTH` 在本件里 `grep -c` = 0 ⇒ **`build/MilBridge/W52C-report.md` 里所有 `NO-AUTHORITY` 字样已过期**，以 W52C2 报告与现场为准（历史留档不改）。
**车道自报自伤一处（已修，留档）**：它一度把 `ITEMS` 的 Provider 注记写成含 `"…"` 与一对反引号 ⇒ 双引号提前闭合 ＋ 命令替换 ⇒ `ITEMS` 被拆出 3 条垃圾项、`ITEMS_SYNC=NO`、`SHELL_QUOTE_TRAP=FAIL traps=2`（`:176 col 260/264`）。**读数当时未受影响**（垃圾元素无 `|` ⇒ `continue`），是**本仓两颗牙先于读数**发现了它 ⇒ 这正是"判据件必须在覆盖面里 ＋ 全仓扫描器要看它"的价值。

### §10.6 新增项 `C1e`（主控裁定：**接受为独立一项**，波内落地）
- 现场：`applocal-expect.py:121` 的 `PROPS["WpfLinuxSelfBuiltConfiguration"] = "Debug"` —— 同一个文件**已经在 `:75-78` 正确读出声明**（`CFG`），却在**属性替换**里把 `$(WpfLinuxSelfBuiltConfiguration)` 换成**字面 `Debug`** ⇒ **同一份文件里两处口径必然分叉**（本仓反复付过学费的那一族）。它是全仓**唯一**残留的这类硬编码（`grep -rn 'WpfLinuxSelfBuiltConfiguration' build/` 只命中这一处 + 读取处）。
- 方向（车道量化，本文件采信）：跟随声明 ⇒ `#REFDIR` **14→23**、`#EXPECT` **不变（190）**、新增 10 个 `build/*/bin/Release` 解析源 ⇒ **加严**（解析源目录要被逐份判），34 条 `STALE` 里只有 **2 条**（`build/PresentationFramework.Classic.Linux/bin/Debug/{PF,WB}.dll`）只因该行才被判。
- **判据（写死；成对）**：① **跟随声明而不是"改成 Release 字面量"** —— 造一个声明为 `Debug` 的沙箱/临时树 ⇒ `#REFDIR` 必须按 **Debug** 拼（这一条是把"修法"与"换个字面量"分开的关键，**必须实测**）；② 真树（声明 = Release）⇒ `#REFDIR` 14→23、`#EXPECT` 仍 190，且那 2 条仍被判（不许因换基准而漏判）；③ **逐格 delta**：重跑检查器，给出 `APPSYNC` 计数行的**逐格**变化，**每一条新红逐条登记**（照 `C1` 先例，登记 ≠ 容忍）；④ 棘轮 `--debt-check` 由 140 ⇒ **≤139**；⑤ `--selftest` 保持 **18/18**（`SELFTEST=PASS`）、`SHELL_QUOTE_TRAP=PASS traps=0`。
- ⚠️ 时序：`applocal-expect.py` **已在 `fp_inputs()` 覆盖面里**（§9.2 C4）⇒ 改它移动 `inputs_fp` ⇒ **必须安排在波的 `IN_FP_0` 之前**（与本文件 §6 的准备趟约束同一条）。

### §10.7 `C1e` 落地（车道 W52C3，`build/MilBridge/W52C3-report.md` `924b33fbb574a9c6`）＋ 主控**静树**复核与两条裁定

**独立复核（主控现跑，静树，与车道读数逐格一致）**：检查器 `rc=1`（`OK=141 MISMATCH=39(STALE=39) MISSING=0 UNEXPECTED=16[EQ=12 DIFF=4] DIVERGENT=8 CROSS-CONFIG=101 LIB-COPY=23`）｜`--selftest` `rc=0`／末行 `SELFTEST=PASS`／18 例｜`SELFCONFIG_DEBT_CHECK=PASS live=139`｜`applocal-expect.py #SUMMARY|refdirs=23|expect=190`。
**判据 1 的成对读数（车道，采信）**：改前件 `@Debug` = 18 条全 Debug **且 `@Release` 仍 18 条全 Debug ⇒ 声明被忽略**（硬编码的机器证）；改后件 `@Debug` 与改前件 `@Debug` **逐字相同（清单 sha12 `068b2c684d27`）⇒ 不是"换成 Release 字面量"**；改后件 `@Release` = 30 条（16 Debug ＋ 14 Release）⇒ **声明生效**。真树 `#REFDIR` **14→23**、`expect=190` 不变。逐格 delta：`OK 135→141`、`STALE 35→39`、`DIVERGENT 5→8 组`、`LIB-COPY 33→23`、其余逐字不变；新登记 6 条 ＋ 3 组 ⇒ 检查器回读 **在册 42 条：仍红 42**（登记不进判定）。

**裁定 ⑥（`C1e` 判据 3 未按字面满足 —— 车道如实上交，我裁定"接受 `LIB-COPY`"）**
- 现场：`build/PresentationFramework.Classic.Linux/bin/Debug/{PresentationFramework,WindowsBase}.dll` 改后**退出 `MISMATCH/STALE`**，但**仍具名可见**（`CROSS-CONFIG …` ＋ `LIB-COPY …与权威不同，但不是加载源`，sha 在行内）。
- 根因（车道的措辞，我采信）：这两份改前**之所以被判，唯一原因就是那条 Debug 口径的 `REFDIR`** ⇒ **判据 1（跟随声明）与判据 3（那 2 条仍判红）互斥**；要两者兼得**必须新增口径**（"跨配置副本即便落在库输出目录也照判"）= **判据变更**。
- **裁定**：**接受 `LIB-COPY`（判据 1 优先），不为让 2 行变红而新增口径**。理由三条：① `LIB-COPY` 的定义就是"库输出目录不是加载源"⇒ 用 Release 权威去判它，正是刚从 `D-G62` 澄清掉的**跨配置混淆**；② 那两件是**另一个构建**（`PresentationFramework.Classic.Linux`）的产物；③ **可见性没有丢**（`CROSS-CONFIG` 具名 ＋ `LIB-COPY` 行内带 sha）。
- **可反驳条件（写死）**：若将来裁定"跨配置副本即便在库输出目录也要照判"，则要**同趟改口径 + 重新登记**，并说明这会不会把"库输出目录"这一类整体拉进判定面（那是一次判据扩张，须单独出证据）。

**裁定 ⑦（新项 `C1f` / 拟登记 `D-G63`：棘轮对"写死的配置值"是瞎的）**
- 现场（车道如实声明，采信）：`SELFCONFIG_DEBT_CHECK` 的图案是 `grep -rn "bin/Debug"`（**按行**），而 `applocal-expect.py:121` 写的是 `PROPS[…]= "Debug"`（**不含 `bin/Debug`**）⇒ **看不见写死的配置值**；本趟 `live 140→139` 的那 1 行来自它把该文件里唯一一处含 `bin/Debug` 字面串的**散文**改写 ⇒ **是措辞级，不是修法成效**。⇒ 那把棘轮对本族**仍有盲区**，下一个同类硬编码照样能活过 `#39`。
- 修法（波内）：把图案**扩到配置值字面量**（如 `"Debug"`/`"Release"` 赋给配置类名/键的行），**并保持"只许减少"的语义**。
- 判据（成对，且必须防"一次性调高上限"）：① 造一处写死的配置值 ⇒ 棘轮**必须加账**（`live` 增 1）且 `--debt-check` 报 `FAIL`；② 改回 ⇒ 减账回绿；③ `max` 常量**不许**为本次改动而上调（这条要同趟核对 `selfbuilt-config.sh` 的 `DEBT_MAX`）。

**登记口径（我裁定）**：允许多册并存；**每条红只能有一个"主册"**，且报告里必须指明主册归属；跨册节只作**索引**，**不重复计入判定**（检查器回读已证 `APPSYNC`/`rc` 不受登记段影响）。

---

## §11 `D-G64`（WM 下点击被吞）—— **已修并经四条腿验证**（车道 W54A `build/MilBridge/W54A-report.md` `2f3c1df6d5ad9b15`，整份 `549153f5c85694ca`）

**修法**：`src/WpfGfx.Linux.Native/src/win32_core.c` 的 `WindowFromPoint` 由"返回 root 直接子窗口"改为**逐层下沉**到"含该点且属于本进程的最深窗口"（整链无本进程窗口时**原样返回顶层**，与 Win32 同语义）；加只读诊断 `WPF_LINUX_WFP_DIAG=1`。
**件**：`win32_core.c` `4e054c88cc3f5fce → 9b1fd23be329ee6e`；`libwpfwin32.so` `abf6879c027c5e73 → 867d96e7cb0cba36`（299,040 → 299,120 B）；其余四件未动。**修前件已固化保存**：`$HOME/pre-DG64-libwpfwin32-abf6879c.so`（`abf6879c027c5e73`）——⚠️ 因为主控在 11:30 把 hc 应用目录刷成了新件，W54A 的 v1 腿链被它自己的 sha 断言拦下（`rc=2`、零读数），此后才用私有副本重跑（**这条"来源被别处覆写"的坑要记住**）。

| 腿 | `preMouseDown` | `AE` | `LB sel` | `alive` |
|---|---|---|---|---|
| ① **修后 + 有 WM**（`:152`+xfwm4） | 9 击**全 >0**（17~46），总 **273** | 7647~**232434** 全 >0 | −1 → **1/31**（→9→10→2→3） | **yes**（6 个页面真换过） |
| ② **修后 + 无 WM** | **273**（与①逐位相同） | 同① | 同① | **yes**（**无回归**） |
| ③ **修前 + 有 WM**（反极性） | **0**（7 击） | **全 0** | 恒 **−1/31** | yes（页面恒 `PracticalDemo`） |
| ④ **修前 + WM → 杀 WM**（同进程单变量） | 前 7 击 **0** → 第 8 击 **32** | 0 → **232605** | −1 → **5/31** | yes |

**shim 本体的直接机器证**（`[WFP_DIAG]` 40/40 行同值）：`top=0x400264`（WM 框架）`own_top=0` ⇒ **`ret=0x600004`（我方客户窗）`depth=2`**；`0x400264` 正是 `REPARENT_PROOF` 里的父框架。修前件**没有这段代码**（`grep -ac WFP_DIAG` 旧=0／新=2）⇒ 修前的 `TOTAL_WFP_DIAG 0` **只能读成"代码不存在"**，不是"也返回了客户窗"。
**覆盖边界（车道补的 L9）**：用复刻算法点到"链上无本进程窗口 ⇒ 原样返回顶层"那一支 —— 被我方窗遮住时 `PREFIX ret=0x400264`→`POSTFIX ret=0x600004`；被 `xmessage` 盖住时 `ret=0x4002fd`（**别人的框架，match_own=no**）⇒ 修法**不过度接线**；桌面无 root 子窗时 `ret=0x0`。
**车道推翻了 W53A §0 的"WM 在场"证法**（四格 `WMPROOF` 原文都是 `no such atom on any window`；它引的 `0x2000ae` 实为**杀掉 WM 之后**的残留属性）——**结论不变**（真证据是重定父框架），但那一句话要更正（如实入册）。

### §11.1 修法**暴露**出来的两条既有缺陷（**都不是本修法引入**，都要在本波收）

**`D-G65`（等待桩 ⇒ 闪退；用户实测）**：`src/WpfGfx.Linux.Native/src/win32_misc.c:385-386` 的 `WaitForMultipleObjectsEx` 是**失败桩**（`wpf_set_last_error(50); return WAIT_FAILED;`）。
- 用户日志 `/tmp/hc-diag.log`（11:20，**他自己的会话**）：`Unhandled exception. System.ComponentModel.Win32Exception (50): No CSI structure available` ← `UnsafeNativeMethods.WaitForMultipleObjectsEx` ← `DispatcherSynchronizationContext.Wait` ← `Monitor.Enter_Slowpath` ← `ResourceDictionary.GetValue` ← `ApplyFrame`/`UpdateLayout` ← `HwndWrapper.WndProc`。⇒ **UI 线程一旦要在锁上等，桩直接返回失败 ⇒ 未处理异常 ⇒ 进程死**（WPF 之所以走原生那一支，是因为 `_dispatcher._disableProcessingCount > 0`；见 `DispatcherSynchronizationContext.cs:91-99`：否则它走**托管**的 `WaitHelper`）。
- **W54A 给出可复现的最小触发**：**并发起两个本例 ⇒ 启动即死**（同签名），单跑正常 ⇒ 与"锁竞争"一致（主控在 `Xvfb ± xfwm4` × {仪器,无仪器} 各 3 次单跑**都没崩**，与之一致）。
- 修法方向（波内落地，判据先写）：让这一支不再致命 —— ① 首选**把 `DispatcherSynchronizationContext.Wait` 的"禁用处理"分支也走托管 `WaitHelper`**（applier 打 `WindowsBase`，动 `windowsbase` 位）；或 ② 在 shim 里把它实现为**不等待、立即返回 `WAIT_TIMEOUT`**（让 `Monitor` 慢路自己重试）。两条都要**禁止**"返回 `WAIT_FAILED`"。
- 判据（成对）：① **并发两实例** ⇒ 修前必死（签名逐字同上）／修后 `alive=yes` 且两窗口都在；② 单个实例 ⇒ 修后仍 `alive=yes`（无回归）；③ 不许把"等待"变成"忙等烧 CPU"（记录 CPU 占用作对照）。

**`D-G66`（点击真落地之后崩；既有，被本修法暴露）**：**点击真的进了 WPF 之后**，应用会在某一击崩 —— 两种签名：托管 `Stack overflow.`（`Panel.ClearChildren` ← `ItemContainerGenerator.OnRefresh` ← … ← `HwndMouseInputProvider.ReportInput`，**点页签后**）与**静默 core dump**（`preMouseDown=152` 后）。
- **关键成对读数（车道已给）**：**修前件 + 无 WM**（点击能落地）**同样崩**；**修前件 + 有 WM**（点击被吞）反而全程 `alive=yes` ⇒ **崩溃跟着"点击是否落地"走，不跟着 shim 走** ⇒ **不是 `D-G64` 引入的**。
- 驱动源（仪器 vs 产品）**未定** ⇒ `NOINFO`（车道如实记）。⚠️ 这条也解释了 W53A 早先那次 **1/3 概率的静默 SIGSEGV**。
- 本波要做：**先取证定驱动源**（仪器全关的腿必须与开仪器的腿成对），再修；判据写死时机 = 取证回来之后（与 `A1` 同规矩）。
- 侧发现两条（同趟登记）：`[GEO]` 的坐标字段会打 `scr=InvalidOperationException`（36 次）⇒ **任何"看见 `item[N]` 就当坐标"的仪器都会点到不存在的点**；并发两实例的启动死见 `D-G65`。

### §11.2 `D-G66`（点击落地后崩）—— 根因已定、**已修**、**同趟两极化验证**（车道 W55A `build/MilBridge/W55A-report.md` `5d550948ab17a55c`）

**判定点（车道给的原文）**：闭合**托管递归环**（`Repeated 3265 times:`）
`OnSetFocus ← FilterMessage ← InputFilterMessage ← WndProc ← SubclassWndProc ← NativeMethodsSetLastError.SetFocus ← TrySetFocus ← AcquireFocus ← TryChangeFocus ← Focus ← CheckForDisconnectedFocus ← PreNotifyInput ← ProcessStagingArea ← ReportInput ← OnSetFocus…`
环上**唯一原生边 = 我们的 `SetFocus`**（它**同步**回调 WndProc：`win32_msg.c:512-528` 的 `return proc(hwnd,msg,wp,lp);`）。
缺陷 = `src/WpfGfx.Linux.Native/src/win32_core.c:953` 派发 `WM_SETFOCUS` **缺 `old != hwnd` 守卫**（上一行 `WM_KILLFOCUS` **有**该守卫）⇒ 破坏上游 `HwndKeyboardInputProvider.cs:114-124` **逐字依赖**的不变式"已拥有 Win32 焦点的 HWND 不会再收到 `WM_SETFOCUS`"。正控：`SETFOCUS → XSetInputFocus` 共 358 行、**357 行是同一个窗口 `0x200004`**（诊断上限 400 打满）。
**驱动源 = 产品**（车道三腿 + 我复核）：**腿 A 不设任何 `HC_*`/`WPF_LINUX_*`，3/3 全崩**；腿 A/B/B′/C **共 13/14 趟同点同签名**；且腿 A 与腿 C **逐击 `AE` 8 击里 7 击逐位相同** ⇒ **仪器连行为都没改**（只改终止方式：`rc=134` 托管 vs `rc=139` 裸 SIGSEGV）。

**修法（主控落地）**：`win32_core.c` 的 `SetFocus` 加 `old != hwnd` 守卫 —— `if (hwnd && old != hwnd) wpf_dispatch_to_window(hwnd, WM_SETFOCUS, …)`；**X 侧 `wpf_x11_set_input_focus` 保留**（它不派发消息，且是"把 X 焦点抢回来"的唯一手段，`D-G50` 的抑制依赖它）。
**件**：`win32_core.c` `9b1fd23be329ee6e → e1edbd04113c9125`；`libwpfwin32.so` `867d96e7cb0cba36 → c2674871b09e8e0e`（299,120 B，与 D-G64 同一次重建口径）。

**两极化（主控同趟实测，用车道的最小复现 `W55A_STEPS="nav1 tab3"` = **2 击**）**：

| 腿 | shim | 读数 |
|---|---|---|
| **修后** | `c2674871b09e8e0e` | `alive=yes rc=`（无崩溃）；`T1-nav1 AE=225596`、`T2-click-TabItem3 AE=182274`（两击**都真的换了页**）；`SIGNATURE stackoverflow=0 unhandled=0 setfocus=0` |
| **修前**（含 D-G64、无本守卫） | `867d96e7cb0cba36` | **`alive=no rc=134`**；`SIGNATURE stackoverflow=1 clearchildren=1 **setfocus=4034**`（回声爆炸的直接机器证：4034 行 vs 修后 **0** 行） |

⇒ **`D-G66` 修法有效、反极性精确**。⚠️ 边界如实记：**"有 WM + 最新 shim"那一格本趟没重跑**（本改动只是"去掉重复派发同一条消息"，与 `WindowFromPoint` 正交）⇒ 由波的冻后验证补；车道的最小复现命令 = `export PATH="$HOME/.dotnet:$PATH"; W55A_STEPS="nav1 tab3" bash $HOME/w55a/bin/leg.sh <tag> <display> A`。

**车道推翻的四处（均采信，如实入册）**：① 我/登记里引的 `Panel.ClearChildren ← ItemContainerGenerator.OnRefresh` **不是**循环（在 `Stack overflow.` 里**各只出现 1 次**，是外围入口路径）；② 我上一轮说的"腿 B 与腿 C 可分离"**错**：`App.xaml.cs:472-477` 的 `GeoEvery()` **缺省就是 2**，`DumpGeo` 无条件挂在 1 Hz 定时器里 ⇒ `HC_INPUT_DIAG=1` **同时开了 `[GEO]`@2s**（它加腿 B′ 才分开，结论：`[GEO]` 不是驱动源）；③ **`D-G65` 不是"并发两实例"专有**：~24 趟里 **2 趟单实例、仪器全关**也在启动即死（同签名）⇒ 只说"并发**非必要**"（无法回溯排除当时别的车道在跑同一应用）；④ 双实例显式实验给出的是**另一条未登记签名**：`InvalidOperationException: Cannot set ShutdownMode when application is shutting down…` @ hc `App.xaml.cs:84`（`EnsureSingleton()` 发现互斥已存在 ⇒ `Shutdown()`）⇒ **另立一条登记**（建议 `D-G67`，波内登记）。
**两条取数边界（后续车道必读）**：① `[GEO]` 的 `scr=` 会给出**数值合法但在窗口外**的坐标（同一控件在同一份日志里 `x=567`/`x=619` 两值；页内控件报 `scr=567,1345` 而窗口只有 600 px 高且 `vis=True`）⇒ 照抄字面量点击会点错控件（车道第一趟读数因此**作废**，已重取）；② `marks.txt` 里**逐击** `XBTN=0` 是 stderr 缓冲的**假零**（全量口径才对：一击一条、`win`+相对 `xy` 8/8 零误差）；③ 本机 `ulimit -c = 0` 且 `core_pattern` 是 apport 管道 ⇒ **根本没有 core 文件**，所谓"core dump"只是 `timeout` 对信号死的措辞。

### §11.3 `D-G65`（等待桩 ⇒ 启动即死）—— **已修并两极化**（车道 W56A `build/MilBridge/W56A-report.md`：回填前 `3bbeea47464cbcd6`／交付快照 `dac0e01285d03874`）

**修法 = 候选 A（托管层）**：用**新应用器** `src/WpfGfx.Linux.Native/tools/patch-windowsbase-focus-wait.py`（`e0e1966593fdde89`）把 `DispatcherSynchronizationContext.Wait` 的**两个分支合一** —— 都走托管的 `SynchronizationContext.WaitHelper`；生成物 `build/WindowsBase.Linux/DispatcherSynchronizationContext.Linux.cs`（`c96e768c84026759`）＋ csproj 接线；注册同趟进 `build/integration-wave.sh` 的 `APPLIERS_EXPLICIT` 与 `build/MilBridge/tools/applier-audit-expected.txt`（`miss=0 red=0 rc=0`）。
**件**：`windowsbase 79740e9ba7fbf9ca → 2e4e46e539a72cd7`（**主控独立复核：仓内 `build/WindowsBase.Linux/bin/Release/WindowsBase.dll` 现盘即此值**）；**`win32shim` 未变 `c2674871b09e8e0e`** ⇒ 九位只动一位。已同步进 hc 应用目录。

**🔴 候选 B 被**否证**（我上一轮的建议是错的，如实入册）**：
- 机制级否证（车道探针）：CLR 传进 `Wait` 的是**等待子系统内部对象 id**（`handle[0]=0xf0`，**不是 Win32 HANDLE**）⇒ **那条 Win32 路在原理上修不好**，只能别走它。
- **B 的 `WAIT_TIMEOUT` = 契约违规**（实测）：CLR 的契约是"`Wait` 一返回就当作你替我拿到了" ⇒ 返回非 `WAIT_OBJECT_0` 时 `ENTER RETURNED taken=True elapsed_ms=5` 而**持有者仍在锁内** ⇒ **临界区无互斥执行** ＋ `Monitor.Exit` 抛 `SynchronizationLockException`。⇒ **这条不但没修好，还会制造更难查的并发错**。
- **B′ 的 `WAIT_OBJECT_0`** 能过契约但**是忙等**：同样 2.5 s 争用，A 烧 `user+sys 0.03 s`，B′ 烧 **2.50 s**（满核）⇒ 撞本波判据③（"不许把等待变成忙等烧 CPU"）⇒ 不落地。shim 已 `cp -p` 复原并重建，**sha16 逐字节回到 `b09058febe5954e4`／`c2674871b09e8e0e`**。

**两极化（仪器全关；签名是判据不是 rc）**：

| 项 | 修前 | 修后 |
|---|---|---|
| **单实例 ≥20 趟** | **7/38 ≈ 18%** 启动即死（两套装置 12.5%／20.0%，死亡全在 **1.5–2.0 s**，栈逐帧同用户日志） | **0/30**（30/30 活到 30 s 截止，日志 0 行） |
| **确定性站点探针（站点①）** | `disp`：`THREW Win32Exception(50)` @ 0 ms | **`ACQUIRED elapsed_ms=2498`** |
| 并发两实例 ×3 | 3 趟里 1 趟**两个实例都死于 `D-G65`**（另 2 趟 inst2 死于下面那条另一缺陷） | **6 次启动 `Win32Exception(50)` = 0** |

**更正判据措辞（采纳车道）**：`D-G65` 的判据是「**`D-G65` 签名计数 = 0**」，**不是**"`alive=yes` 且两窗口都在" —— 后者**任何 `D-G65` 修法都达不到**（第二实例确定性死于另一条缺陷，见下）。

**主控裁定（回应车道两问）**：
- **裁定 ⑧（站点②）**：`upstream/…/Shared/MS/Internal/ReaderWriterLockWrapper.cs:287-290` 的 `NonPumpingSynchronizationContext.Wait` 是**同族第二个、无条件**的原生等待调用点（由 `CallWithNonPumpingWait` 在 `WeakEventTable` 每次读写锁进出装上）⇒ **本波同趟修**（同一应用器家族；判据 = 站点级"**不抛 `Win32Exception`**"，产品级可达性**保持 `NOINFO`** —— 36 趟修前死亡无一趟落在它），并**单独登记**（拟 `D-G68`）。理由：同一根因留一条已知致命路径不修，等于把"绿"建在"恰好没走到"上。
- **裁定 ⑨（纪律 38 红线）**：`port-lib.py WindowsBase` 重生成后"注入仍在"这一条 = **波内动作**（车道按纪律没跑，判 `NOINFO` 正确）⇒ 写进 §6 收尾链的准备项：重生成后必须 `patcher --check` rc=0 **且**注入块仍在（与既有的纪律 38 红线同形）。
- **裁定 ⑩（双实例那条新签名）**：`InvalidOperationException: Cannot set ShutdownMode when application is shutting down…` @ hc `App.xaml.cs:84`（`EnsureSingleton()` 发现互斥已存在 ⇒ `Shutdown()`）⇒ **单独登记**（拟 `D-G67`），**不塞进 `D-G65`**；判据 = "起第二个实例 ⇒ 必须给出可解释的退出（而不是未处理异常）"。

---

## §12 用户实测新报两条（2026-09-20，**最高优先**）—— 取证中

**用户原话（逐字）**：「`run-hc` 我运行了几次，**点击有反应了**，但好像**直接全屏没办法调节窗口形态大小和拖动位置**，另外**还会出现崩溃**。」

**已确认好的那一半**：`run-hc.sh` 走的链路 = 同步五件（`sync-applocal.sh`，逐件印 sha16）→ `dotnet HandyControlDemo.dll`；点击已恢复（`D-G64` 修法在件里）⇒ 用户的"点击有反应了"与四腿验证一致。

**新报两条**（**本波必须收**，判据先占位、取证回来即写死）：

**N1 · 窗口形态（"直接全屏、不能调大小、不能拖"）** —— 路线 `ROUTES.md` R1。
- 待测四项（车道 W57A 在取）：`WM_NORMAL_HINTS`（有没有 `PMinSize==PMaxSize` ⇒ WM 不许缩放）／`_MOTIF_WM_HINTS`（有没有 `MWM_DECOR=0` ⇒ WM 不装饰）／`_NET_WM_STATE`（有没有 `MAXIMIZED_*`/`FULLSCREEN`）／`xwininfo` 的 `Override Redirect`（true ⇒ WM 根本不管它）；并与同显示上一个**已知正常**的 X 客户端逐字段对照。
- 判据（取证回来写死）：① 有 WM 腿里我们的窗**有框架父窗**、`_NET_WM_STATE` 无 `MAXIMIZED/FULLSCREEN`（除非应用自己要）、`Override Redirect=False`；② `xdotool` 拖标题栏 ⇒ 窗口原点变；③ 拖边框 ⇒ 宽高变且内容跟着变（`ConfigureNotify` 生效）；④ **反极性** = 修前必须复现用户那三条"不能"。

**N2 · 仍会崩溃（签名未定）** —— 路线 `ROUTES.md` R2。
- 已知两条已修（`D-G65` 启动等待桩、`D-G66` `SetFocus` 回声环），且 `D-G66` 在**只点 2 击**（导航 + 页签）的最小复现下修前必崩 ⇒ **用户很可能就是撞在它上面**（他跑的件在本次修复之前）。
- 判据（取证回来写死）：① **仪器全关**、≥10 趟压力序列（逐页导航 ≥8 页 + 页签 + 下拉 + 列表 + 打字，≥20 击/趟）⇒ **崩溃趟数 = 0**；② 每一类签名给"修前必现/修后不现"的成对读数；③ 已登记的 `D-G67`（第二实例 `ShutdownMode` 异常）必须变成**可解释退出**而非未处理异常；④ 若 10 趟 0 崩 ⇒ **如实写 0 崩**并加长腿再取一次（不许把"不崩"写崩、也不许把"崩"写不崩）。

**同时落地的取数工程改动**：`~/run-hc.sh` 现在会把应用的 `stdout+stderr` **落到 `/tmp/hc-run-<时刻>.log`** 并在退出时打印末 20 行 ⇒ **下一次崩溃的现场不用再靠人转述**（本机无 core 文件，日志是唯一现场）。
