# P1-W98 · 排版模型 `M2`（`LM-1`＝本侧段账）副本最小实现 —— 让 `S-2a` 变可判

> **本件 `t181`（runner）交付**，依赖 `t179` 判据件 `build/MilBridge/P1-layout-model-criteria.md`（226 行／末行自证 `03460258dfa88ae2`）。**写域**：`src/WpfGfx.Linux.Native/**` ＋本载体；**未碰** `tools/**`／`tests/**`／`docs/**`／`.cs`／哨兵／`cell=#1`（**有意未登记**）。`phase=degraded` 未动；未 `git add/commit/push`。

## §0 开工现取
`win32_pts.c` **`d8d784304ff735bf`**／326923 B（`t179` 现取代际，**已从 `t173` 的 `1b642b1a906eb12f` 换代**）｜资源三值见 §7。

## §A **预登记**（跑前写死；判据件 §3.2／§3.3／§4 优先）

| # | 项 | 判定规则 |
|---|---|---|
| R1 | **目标** | 在**副本**驱动格内让 `ContainerParagraph`／`PtsHelper.ArrangeParaList` 拿到**自洽段账**：`cParas`＝本侧驱动次数、每段 `dvrUsed/dvrTopSpace/fsrc/fsbbox` 满足 **I-1..I-6**、宿主可算出**非零** `rcPara.dv` |
| R2 | **判词分列** | **`S-2a`（几何/计数层，本波可判）**／**`S-2b`（内容层，维持 `NOINFO-LAYOUT-CONTENT`）**；**禁止**用 `S-2a` 绿宣布 `S-2b` 或整页"排版成功" |
| R3 | **八条合取**（判据 §3.2） | ①`rc=0 ∧ calls>0` ②`cParas≠0` 且＝本侧驱动计数 ③每段 `dvrUsed>0 ∧ ≥dvrTopSpace` ④宿主侧消费证据 ⑤`kstop` 与实际放得下**自洽**（禁恒 no-progress）⑥`brkOut` 与"是否续排"自洽 ⑦`bbox` 非空且与 `fsrc` 自洽 ⑧≥2 样本同判＋纪律三十三格 |
| R4 | **准入铁律** | `cParas`／几何／`kstop`／`brkOut`／`ppfsSubtrack` **本侧是作者**；**`pmcsclientOut` 永不能是作者** ⇒ **固定 0 ＋ `PRECOND-MCS-OWNER-HOST`**；**I-6 零托管依赖**（引入新句柄 ⇒ 越级判红） |
| R5 | **`P8`** | 凡填 0／留空**必须回答"宿主会走哪条分支"**（`cParas=0` ⇒ 叶子支 ⇒ 静默丢整棵；`brkOut=nil` ⇒ `_isLastChunk`） |
| R6 | **粒度** | 每条绿**必须带粒度**（单段／单次调用／整腿／整批）；**不得**把"单次对了"写成"整腿绿" |
| R7 | **副本最强形态** | 主链 `.so` **重建前后逐字节不变**；`#if WPF_PTS_FSP_PL_M2` 缺省 0；`calls=0` 与 `calls>0` 分开报 |
| R8 | **风险（判据 §7-1）** | `dvrUsed>0` 会让宿主**真的排布** ⇒ 可能把"空排"变成"看似有几何的空页"（假绿最高风险）⇒ **只许副本先行** |

## §1 ② `S-2a` 的**可判读数**（判据 §3.3：`S-2a` 几何/计数层本波可判；`S-2b` 内容层维持 `NOINFO`）
**逐字行（副本 `6a821f262485b5f5`，腿 A／腿 B 两样本逐字一致，仅地址不同）**：
```
[LMM2] entry=FsFormatSubtrackFinite cParas=1(seg-ledger) dvrUsed=16 dvrTopSpace=0 rect=0,0,768,576 fits=1
       kstop=0 brkOut=(nil) mcout=0(NO-AUTHOR-PRECOND-MCS-OWNER-HOST) bbox_def=1 bbox_dv=16
       I1_cparas_nonzero=1 I2_dvr_ge_top=1 I3_within=1 I4_bbox_selfcons=1 I6_zero_managed_dep=1 calls=1
       gen=LM1-SEGMENT-LEDGER v=LM1-PROGRESS-SELF-CONSISTENT
       NOINFO=host-side-consumption(needs managed read),S-2b-layout-content
```
**八条合取（判据 §3.2）逐条 ＋ 粒度**：
| # | 合取 | 现取 | 粒度 | 判 |
|---|---|---|---|---|
| 1 | `rc=0 ∧ calls>0` | 驱动点 `phase=slot3 rc=0`×1；本入口 `calls=1`（**真的被调**，非"没发出去"） | 单次调用 | ✅ |
| 2 | `cParas≠0` 且＝本侧驱动计数 | `cParas=1`＝本侧驱动计数（`I1`，逐值可核） | 单段 | ✅ |
| 3 | 每段 `dvrUsed>0 ∧ ≥dvrTopSpace` | `dvrUsed=16`、`dvrTopSpace=0`（`I2=1`） | 单段 | ✅ |
| 4 | **宿主侧消费证据**（`rcPara.dv>0` 等） | **`NOINFO`** —— 需**托管侧**读数（`_rect`／`GetFirstTextLineBaseline`），`.cs` 不在本波写域 | — | **`NOINFO`** |
| 5 | `kstop` 与"是否放得下"自洽（禁恒 no-progress） | `fits=1 ⇒ kstop=0`（**goalReached**，不再恒 `no-progress`） | 单次调用 | ✅ |
| 6 | `brkOut` 与"是否续排"自洽 | 放得下 ⇒ **未续排** ⇒ `brkOut=(nil)`（自洽） | 单次调用 | ✅ |
| 7 | `bbox` 非空且与 `fsrc` 自洽 | `bbox_def=1`、`bbox_dv=16`、与 `rect` 同向且包含（`I4=1`） | 单段 | ✅ |
| 8 | ≥2 样本同判 ＋ 纪律 33 格 | 两样本（`app-m1.log`／`app-m1b.log` 的 `[LMM2]` 行）**逐字一致**（该行不含地址 ⇒ 字面相同；本席**复核过一次错误的对拍**——首版用错文件名导致"空串相等"，已改用真文件名重核）；门变量 `WPF_PTS_DRIVE_PROBE=1`／`_N=16`；副本产物 sha16 在册 | 整腿 | ✅（**除第 4 条**） |
⇒ **判词分列**：**`S-2a`「排版模型（几何/计数层）成立」＝ 7/8 条成立 ⇒ 记为 `S-2a-PARTIAL`（因第 4 条宿主侧消费读数为 `NOINFO`）**；**`S-2b`（内容层）＝ 维持 `NOINFO`**。**禁止**用 `S-2a` 绿宣布"排版成功／整页排版"。
**粒度声明（`t173` 教训）**：上表 1–7 是**单段/单次调用**粒度；**"整腿"不成立**：三条腿最终都 `app_rc=134`、`failfast=1`（发生在 LM-1 调用**之后**，与仍缺符号的 `FsQuerySubtrackDetails` 消费者路径同趟），且**消费者侧计数未取**。

## §2 ③ 形态逐条（`I-1..I-6`）
`I-1` `cParas=1≥0` 且非 0（真例存在嵌套 ⇒ 不得为 0）｜`I-2` `16 ≥ 0` ✅｜`I-3` `Σ dvrUsed(16) ≤ rect.dv(576)` ⇒ `fits=1`（放不下会走 `out-of-space` 分支，不静默截断）｜`I-4` `bbox` 与 `fsrc` 同向且包含 ✅｜`I-5` **跨调用稳定**：两样本逐字一致（幂等性**现取**，未沿用前跳结论）｜`I-6` **零托管依赖** ✅：本块**一个新句柄都不引入**（用到的三枚身份 `nms=0x2`／`nmp=0x3`／`h1=0x4` 全是**入站给的**，行内标 `(in,unverified)`）。

## §3 ④ 反腿（含 `P8` 类"缺省值改控制流"）
| 反腿 | 做法 | 现取 | 判 |
|---|---|---|---|
| **A（缺入口对照）** | 同副本**去掉 `M1`/`M2`** | `phase=slot3 **rc=-100002**`×1、`asserts A_rc0=0` | ✅ 与 `t173` 同判（**成因＝缺入口**） |
| **B（`P8`：缺省值改控制流）** | `cParas=0`（判据 §2-⑥ 现取：`_isLastChunk` 由 `brkOut==nil` 定、`cParas=0` ⇒ **叶子支、静默丢整棵**）⇒ 本件**取 `cParas=1`**；`kstop` **不恒 no-progress**（由 `fits` 决定） | `cParas=1`、`kstop=0`（`fits=1`） | ✅ 两处"缺省值"都**显式回答**了"宿主走哪条分支" |
| **C（准入：`mcout`）** | `pmcsclientOut` **固定 0**（判据 §4：本侧永不能是作者） | `mcout=0(NO-AUTHOR-PRECOND-MCS-OWNER-HOST)` | ✅ 具名 `PRECOND-MCS-OWNER-HOST` |

## §4 ①⑤ 逐件 ＋ 主链逐字节不变 ＋ `nm`
| 面 | 现取 | 判 |
|---|---|---|
| `win32_pts.c` | `d8d784304ff735bf`／326923 B → **`02d4c89fa432d4d2`**／330477 B | **t181 专属 `numstat = 37 0`**（全部新增在 `#if WPF_PTS_FSP_PL_M2` 内） |
| **主链 `.so`** | `pre=post=**352855f8dfbf8dc7**`（`MAIN_BYTE_IDENTICAL=yes`） | ✅ **副本先行**（判据 §7-1 的最高风险项以此承载） |
| `exports.txt` | **669 行不变** ⇒ 逐名零变化（无消失）；`^Fs=6` 不变 | ✅ |
| 副本产物 | `6a821f262485b5f5`（SNAP+DRIVE+M1+M2）／`cb92d00b76da9f57`（无 M1/M2 对照） | 副本专用 |
| 症状／结局（三腿） | `app_rc=134`、`failfast=1`、`unrec=2`、ENFE 仅 `FsQuerySubtrackDetails`×2 | 如实记（**m** 与 S-1 同为调用级） |

## §5 ⑥ 前置状态（**带射程**）
| # | 项 | 状态 |
|---|---|---|
| 1 | **`PRECOND-NO-LAYOUT-MODEL`** | 🔴 **部分可解除（射程＝几何/计数层）**：本侧已能产出**自洽段账**（`cParas`＝驱动计数、`dvrUsed>0`、`bbbox` 与 `fsrc` 自洽、`kstop` 随 `fits`、`brkOut` 自洽、零托管依赖）；**未解除的部分**：**宿主侧消费读数**（第 4 条）需托管侧只读读数 ⇒ **`NOINFO`** |
| 2 | **`PRECOND-NO-LAYOUT-CONTENT-MODEL`** | **成立**（内容/行盒层本侧今天无模型）⇒ **`S-2b` 维持 `NOINFO`**；合规终点，不等于 `LM-1` 无价值（红榜 `P9`） |
| 3 | **`PRECOND-MCS-OWNER-HOST`** | **成立并按其执行**（`mcout` 固定 0） |
| 4 | `PRECOND-NATIVE-FORMAT-ENTRY-MISSING` | 沿用 `t173` 已解除 |
| 5 | **不给 `CallbackException` 类型读数** | 队长裁定：该格**由 `t177`（`scribe`）在托管侧做** ⇒ 本件**不做、不重复** |

## §6 ⑦⑧ 资源三值与 `NOINFO`
- **资源（三值现取）**：开工 `MemAvailable 23192596 kB`／`SwapFree 2097148 kB`／`df 77928856 kB free`；**最低**（重活期间未单独采样 ⇒ 本席**如实记"未采样"**，以开工/收工两值作界）；收工 `MemAvailable 23192596 kB`／`SwapFree 2097148 kB`／`df` 同上；重活**单链**（一次 `heavy-slot` 串行）（一条 `heavy-slot` 串行跑完主链重建＋两副本＋三腿），**无自留 `dotnet`/MSBuild**（收工现取 0）；显示位 `:238/:239/:236` 按 PID 收净，`/tmp/.X11-unix/` 仅 `X0 X1`。
- **`NOINFO`（具名）**：① **宿主侧消费读数**（第 4 条，需托管侧）；② **`S-2b` 内容层**（`NOINFO-LAYOUT-CONTENT`）；③ **`CallbackException` 类型**（由 `t177` 负责，本件不重复）。

## §7 红榜 `P1–P12`（摘要）
`P1` 非零 `rc` 不当成功（对照腿 `-100002` 如实记）｜`P2` 零句柄不当活｜`P3` 只写本侧为作者的字段｜`P5` `calls=1` 与"是否通过"分开｜`P7` 主链逐字节不变｜**`P8` 逐格**（`cParas`／`kstop` 两处"缺省值"都显式回答分支）｜`P9` 未用 `S-2a` 绿宣布内容层｜`P10` `calls=0/`>0 分开、`NOINFO` 不写成绿｜`P11` 每条带当次代际｜`P12` 三处 `NOINFO` 具名。
`P1-LAYOUT-MODEL 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 1b0bb252b3ad0bfb（末行＝本行）`
