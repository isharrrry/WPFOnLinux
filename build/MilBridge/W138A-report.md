# W138A 报告 —— 登记批：两条 `TASK` 收口（🟡→✅）＋ 一条地图指针 ＋ 一次推送

- 车道 **W138A**｜日期 **2026-09-23**｜类型 = **登记批（纯文本 ＋ 一次推送；零 `dotnet`／零构建／零门禁重跑／零应用／不占槽）**
- `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**不是 git 仓库**）｜fork 克隆 `~/netTest/GitProj/WPFOnLinux`（`feat-Linux`）
- 判据先写：`~/w138a/criteria.md`（写入时刻早于任何 `ROUTES.md` 改动）｜工作日志 `~/w138a/STATUS.md`
- 改动集合 = **3 件**：`docs/ROUTES.md`（改）＋ `build/MilBridge/tools/defect-registry-declared.tsv`（`--emit` 重生成）＋ 本报告（新）
- **零新缺陷号**（本批不写 `D-G112`；现场核 `grep -c 'D-G112' docs/ROUTES.md` = **0**）

---

## ① 两条收口段逐字（含引用到的原始读数行）

### ①-a `TASK-0303` 🟡 → ✅

**收口前现场核（三条前提全成立，才动手）**：

| 项 | 现场读数 | 取法 |
|---|---|---|
| `TASK-0304` | `[Next] ✅ **已办（`#50`，车道 W86A）**`（改前 `:347`） | `grep -n 'TASK-0304' docs/ROUTES.md` |
| `TASK-0305` | `[Next] ✅ **已办**`（改前 `:348`） | 同上 |
| `TASK-0306` | `[Next] ✅ **已办（`A3` 同趟做了）**`（改前 `:349`） | 同上 |
| 读取出处 | 三条全在 **`§14` 波 `#50` 的 `[Next]` 清单**（改前 `:347-354`），下文 `:350-354` 为其成对／反极性／零回归子条 | 现场 |

**被逐字引用的原始读数行（原文，不是我概括的）**：

> `TASK-0304` [Next] ✅ **已办（`#50`，车道 W86A）**：`A1` 新 `src/WpfGfx.Linux.Native/src/win32_pts.c` 导出 PTS 上下文族 **6 入口 ＋ 5 个机读面**，**恒返回 `-10000`（`tserrNotImplemented`）**、出参清空、具名台账 `PTS_GAP entry=… seq=… err=-10000 calls=…`（有界 64 行）；自检导出 `PTS_GAP selfcheck`＝**1（真 stub）/0（假 stub）**；导出 535→546（另被迫改 `build-shim.sh` 的 `SRCS` 一行，已登记）

> `TASK-0305` [Next] ✅ **已办**：PF 注入面＝`build/PresentationFramework.Linux/reapply-patches.py`（每波必重放）⇒ 从上游**逐字复制＋needle 校验**产出 `PtsCache.Linux.cs`(5 处)＋`FlowDocumentView.Linux.cs`(8 处)；毒池项**按对象身份**移除＋具名闩＋`PtsUnavailableException`；**`Invariant.Assert` 一个没删**

> `TASK-0306` [Next] ✅ **已办（`A3` 同趟做了）**：第 24 项「流文档」⇒ **`alive=yes`、`rc=143`（仪器自发的 SIGTERM ⇒ 进程从没死）、`fatal=0`**，**页级可见**：洋红占位 **54,454 px**（真拍图：洋红矩形＋黑边＋"此页不支持…NOT SUPPORTED…entry=CreateInstalledObjectsInfo err=-10000"）＋台账 `PTS_GAP … seq=1 err=-10000`＋`[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage`；第 23 项同样可见降级（49,864 px）。**修前同一点击 = `rc=134`**

**落笔后（改后 `docs/ROUTES.md:216`，状态位 `🟡`→`✅`，**原判词一字不动**）**：

```
│   ├─ TASK-0303 [Next] ✅ **只读侦察＋最小第一步设计已完成**（车道 W78A，报告 `build/MilBridge/W78A-report.md` `0dbc62b1d1cf86ee`，568 行；零 `dotnet`/零应用/零构建）
```

**同趟追加的收口 bullet（改后 `:226`，**全部新增，不改任何旧字**）**：

```
│   │   └─ ✅ **收口（车道 W138A，2026-09-23；本行上面各条登记**一字未动**，本条只补状态与出处）**：本行"下一步 `A1`/`A2`（产品改动）"**已由 `TASK-0304`／`TASK-0305`／`TASK-0306` 落地并各自 ✅** —— 三条的状态位现场核过（都在 `§14`），读数**逐字引用**：`TASK-0304` ✅ 载「`A1` 新 `src/WpfGfx.Linux.Native/src/win32_pts.c` 导出 PTS 上下文族 **6 入口 ＋ 5 个机读面**，**恒返回 `-10000`（`tserrNotImplemented`）**、出参清空、具名台账 `PTS_GAP entry=… seq=… err=-10000 calls=…`（有界 64 行）」；`TASK-0305` ✅ 载「毒池项**按对象身份**移除＋具名闩＋`PtsUnavailableException`；**`Invariant.Assert` 一个没删**」；`TASK-0306` ✅ 载「**页级可见**：洋红占位 **54,454 px**…第 23 项同样可见降级（49,864 px）。**修前同一点击 = `rc=134`**」。⛔ **本收口只指"最小可见边界（`A1`＋`A2`＋`A3`）已落地"**（`A3` = 页级**可见降级**，`TASK-0306` 的 `N2-b` 牙：**不许把空白读成绿**）；**`TASK-0302`（PTS / 原生 LineServices 真实现，111 条 `Fs*`/`Lo*` 缺口，`D-G70`）仍 🔴 长线、不在本收口范围内**。
```

**`§13` 的 `[Next]` 清单行同趟改（改后 `:299-300`）**：

```
- `TASK-0303` ✅ 设计已交（W78A）＋ `A0` 实测已做（W81A）；下一步 `A1`/`A2`（产品改动）
  - `TASK-0303` ✅ **收口（车道 W138A，2026-09-23；上一行原判词**一字未动**，本条只补状态与出处）**：其"下一步 `A1`/`A2`"**已由 `TASK-0304`／`TASK-0305`／`TASK-0306` 落地并各自 ✅**（三条读数在 `§14` `:347-354`：`A1` = `win32_pts.c` 6 入口 stub ＋具名台账；`A2` = PF 毒池项按对象身份移除＋闩；`A3` = 页级**可见降级**：第 23/24 项洋红 **49,864 px／54,454 px**、`PTS_GAP … err=-10000`、`[PTS-UNAVAILABLE]`，**修前同一点击 = `rc=134`**）。⛔ **本收口只指"最小可见边界已落地"**；**`TASK-0302`（PTS 真实现）仍 🔴 长线**。
```

⛔ **本收口的边界（同趟写清，逐字）**：`TASK-0302`（PTS / 原生 LineServices **真实现**）**仍 🔴 长线**；本收口**只指"最小可见边界已落地"**。

### ①-b `TASK-0501` 🟡 → ✅

**收口前现场核（两条前提全成立）**：`TASK-0502` ✅ 在位（改前 `:236`）｜活 `sha256sum build/DirectWrite.Linux/wic-shim/libwpfwic.so` 前 16 位 = **`f7b3026c8c019be2`**（`74984 B`）= 判词所载**修后**值（修前 `56278c14b4ecd672`）⇒ **不是"文档说已修、树里没修"**。

**被逐字引用的原始读数行（`§13` 的 `TASK-0502` 子树，改前 `:238`／`:243`）**：

> **读数**：3 帧 GIF `COUNT=1 → 3`、4 帧 `→ 4`，逐帧 `CopyPixels` 与真值**逐字节相同**；帧延迟 `/grctlext/Delay` 由 `UNSUPPORTEDOPERATION` → **`VT_UI2` 逐帧相符**（10/20/30、5/10/15/20 cs）

> `NOINFO`：`disposal=2` 的后续帧 —— **Skia 自己返 `kInvalidConversion(3)`**（四种选帧变体全 res=3）⇒ 我们**如实失败 `E_UNEXPECTED`、不假装成功**；托管级端到端**未跑**（本轮零 `dotnet`，samples 无 GIF 载体）⇒ 代理级契约已证、PC 侧后续行为 `NOINFO`。

**落笔后（改后 `:236`，`🟡`→`✅`，判词含判定点 `wic_proxy.c:1030-1035` **一字不动**）**：

```
│   ├─ TASK-0501 [MVP] ✅ GIF 只有第 0 帧（`wic_proxy.c:1030-1035`）
```

**同趟追加的收口 bullet（改后 `:237`）**：

```
│   │   └─ ✅ **收口（车道 W138A，2026-09-23；本行判词**一字未动**，本条只补状态与出处）**：本行所述缺口——`build/DirectWrite.Linux/wic-shim/wic_proxy.c:1034` 的 `*pFrameCount = 1;`——**已由 `TASK-0502` 修掉**（§13 该子树**逐字**：「3 帧 GIF `COUNT=1 → 3`、4 帧 `→ 4`，逐帧 `CopyPixels` 与真值**逐字节相同**」；「帧延迟 `/grctlext/Delay` 由 `UNSUPPORTEDOPERATION` → **`VT_UI2` 逐帧相符**」）；**世代位现场现算**：活 `build/DirectWrite.Linux/wic-shim/libwpfwic.so`（`74984 B`）前 16 位 = **`f7b3026c8c019be2`** = `TASK-0502` 判词所载**修后**值（修前 `56278c14b4ecd672` ⇒ 修复件确实在位、不是"文档说已修、树里没修"）。⚠️ **残留（不许当绿）**：`disposal=2` 的后续帧 —— **Skia 自己返 `kInvalidConversion(3)`** ⇒ 我们**如实失败、不假装成功**；托管级端到端**未跑** ⇒ 那一格 `NOINFO`（见 §13 该子树的 `NOINFO` 条）。
```

⚠️ **残留（同趟写清，逐字）**：`disposal=2` 的后续帧 ⇒ **如实失败**；**托管级端到端未跑 ⇒ 那一格 `NOINFO`**。

---

## ② `TASK-0111` 指针行逐字（**新增一行，不改任何状态位**）

插入位置：`§13` 树里 `TASK-0111` 块的**最后一条子 bullet 之后**（改后 `:423`），即 `TASK-0210` 行（改后 `:424`）**之前**，缩进与既有子 bullet 一致（`  - `）。

```
  - 🗺️ **地图事实 · 指针（车道 W138A，2026-09-23；本条**只加指针** —— 本行状态位与 `§15i`／`§15k`／`§15m`／`§15r`／`§15t` 的登记**一字未动**）**：本行的"**下一步**"**已由 `TASK-0210` 接管、且该任务已开工** —— 波 **`#54`**、车道 **W134A** 在办（`TASK-0210` 本体 = 本行**下一条**）；`D-G98` 的 **`N3` 归因终局**（发起方 = MIL 桥 `wpfgfx_cor3.so` 在**自己那条 X 连接**上用**裸 `ConfigureWindow`** 重发最大化几何、WM 真还原之后 **`+85 ms`**）**见 `§15t`**。⚠️ **本行状态位仍 `🔴`**（产品侧未修）；本条**不改变**任何任务的状态位。
```

**硬约束复核（全部成立）**：

| 约束 | 现场读数 |
|---|---|
| `TASK-0111` 状态位**仍 `🔴`** | 改后 `:414` = ``- `TASK-0111` [Next] 🔴 **`_MOTIF_WM_HINTS` 那一跳的落地` `` ✔ |
| `TASK-0210` 状态位**不动** | 改后 `:424` = ``- `TASK-0210` [Next] 🔴 **桥侧几何重发／接管` `` ✔ |
| `§15i/§15k/§15m/§15r/§15t` **一字未动** | `diff` 只命中 4 处修改 ＋ 4 处新增，**无一在 `§15` 区域内** ✔ |

---

## ③ 状态位改动前后（`wc -l` 复核）

| 项 | 改前 | 改后 | 说明 |
|---|---|---|---|
| `docs/ROUTES.md` 行数 | **744** | **748** | 净 **+4**（**无吞行**） |
| sha256 前 16 位 | `0cba40fe79f52333` | `cf7221b6e907a67e` | 全值见 §⑤ |
| `TASK-0303` 徽标 | `🟡`（`:216` ＋ `:297`） | `✅`（`:216` ＋ `:299`） | **两处都改**；两行**其余文字零改动** |
| `TASK-0501` 徽标 | `🟡`（`:235`） | `✅`（`:236`） | 一处 |
| `TASK-0111` 徽标 | `🔴` | `🔴` | **未动**（核对见 §②） |

**`diff` 形状（逐行机械核）**：`diff 改前 改后` 输出 **`<` 4 行、`>` 8 行** ⇒ **4 处修改 ＋ 4 处新增**，与"净 +4 行"逐位相符。

**★ 唯一一处箱线符号例外（主控批准的"追加子行所必需"形状修正；同行文字零改动）**

- 位置 = 改前 `:225` → 改后 `:225`（`TASK-0303` 的 `NOINFO` 子 bullet，追加后它不再是最后一条）
- 改前（原文，前 20 字符）：`│   │   └─ \`NOINFO\`：\`A0\` 需…`
- 改后（原文，前 20 字符）：`│   │   ├─ \`NOINFO\`：\`A0\` 需…`
- **文字零改动的机械证**：脚本把两侧前导箱线字符集 `[│ ├└─]+` 全部剥掉后逐字比对 ⇒ **`text-identical(除箱线): True`**（`python3` 现场跑，见 §④ 复核命令留痕）

---

## ④ `DEFREG` 两条机读行（**现场跑两遍**）

**`--emit` 重生成（temp ＋ rename，**禁 `> 件`**，防 `D-G101` 的跨区硬链接链）**：

```
$ T=build/MilBridge/tools/defect-registry-declared.tsv
$ TMP=$(mktemp "${T}.w138a.XXXXXX")
$ bash build/MilBridge/tools/defect-registry-check.sh --emit > "$TMP"   # rc=0；156 行
$ mv -f "$TMP" "$T"
```

| 项 | 改前 | 改后 |
|---|---|---|
| inode | `4196835` | `4933604`（**新 inode ⇒ 确为 temp＋rename，不是原地改写**） |
| `nlink` | `1` | `1` |
| 大小 | `6684 B` | `6684 B` |
| 非注释非空行 | **147** | **147** |
| sha256 前 16 | `9be486681bd47451` | `e3dbabb033ad7264` |

**与上一版（远端已提交版）的差异 = 恰好 1 行**（`diff` 输出 2 行 = 1 `<` ＋ 1 `>`）：

```
< # DECL-GEN = (--emit) 2026-09-23 14:34:37 +0800
> # DECL-GEN = (--emit) 2026-09-23 17:15:29 +0800
```

⇒ **`DECL-ANCHORS` 逐位不变**（`KD=7f7770acd3ec24b9 CS=81b35c059717b7a8 HO=e4dc264200b421d0 AB=a2e49b786d0a1b02 KRJ=f108775906eac9aa KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31`）⇒ 期间**无任何 route 文件被别的车道改动**（这也是 `DECLDRIFT=0` 的直接原因）。

**两遍 `defect-registry-check.sh` 的机读行（两次输出 `cmp` 逐字节相同，`sha256` 前 20 = `ea6f924303204bc24aee`）**：

```
DEFREG_DECL=n=147 route_ids=147 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=7f7770acd3ec24b9 CS=81b35c059717b7a8 HO=e4dc264200b421d0 AB=a2e49b786d0a1b02
DEFREG_EXTRA=KRJ=f108775906eac9aa KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=147 route_ids=147（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
```

- 两遍 **`rc` 都是 `0`**；`DEFREG=PASS declared=147 route_ids=147` **逐位符合预期**（与改前基线相同）
- **`DEFREG_DECLDRIFT=0`** ✔
- **不许动的三件**（`CS`／`HO`／`AB`）**一件未动**（锚点逐位不变即其机械证）

**"改 `ROUTES.md` 为何不动 `DEFREG`"的结构性依据（现场读过源码，不是推断）**：`defect-registry-check.sh:59-65` 的 route 文件 = `KD=samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`CS=docs/CURRENT-STATE.md`／`HO=handoff.md`／`AB=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` ⇒ **`docs/ROUTES.md` 不在其中**。

---

## ⑤ 推送前后 head ＋ `BYTECHECK` ＋ 件对账

**改动前后 sha256（全值，现场现算）**：

| 件 | 改前 | 改后 |
|---|---|---|
| `docs/ROUTES.md` | `0cba40fe79f523336fac4568541c2a53eeacaad3958d8d1ab6e0e34d53a90a55` | `cf7221b6e907a67e…`（前 16，见 `BYTECHECK` 行） |
| `…defect-registry-declared.tsv` | `9be486681bd47451…` | `e3dbabb033ad7264…` |

**件对账（改了几件 ↔ 推了几件）**：改 **3 件**（`docs/ROUTES.md`／`declared.tsv`／本报告）⇒ **本笔推 2 件**（`docs/ROUTES.md`／`declared.tsv`）＋ **报告为第二笔**（见文末"本件自身的推送"）。推前 `git status --porcelain | wc -l` = **2** == 本笔件数 **2** ✔（**逐径 `git add`，全程未用 `-A`／`--force`／`git add .`**）。

```
$ git push origin feat-Linux
   84f98a9..fff2ba3  feat-Linux -> feat-Linux        [rc=0]
```

| 项 | 读数 |
|---|---|
| **推送前** head | `84f98a971d0059e7796924a263c5d9560bcc1a6b`（= 派单书所述远端 head，现场 `git ls-remote --symref` 复核一致） |
| **推送后** head | **`fff2ba38c35deeb6ce493a9277ed1f7763486f74`** |
| 提交 | `fff2ba3 docs(#54): W138A 登记批 —— …`；**父 = `84f98a9`（旧的推送前 head）⇒ 纯快进** |
| **`BYTECHECK`** | **`ok=2 mismatch=0`** —— `docs/ROUTES.md` `cf7221b6e907a67e` ✔ ／ `declared.tsv` `e3dbabb033ad7264` ✔（两侧都 = 远端 blob `git cat-file blob origin/feat-Linux:<path>` 的 sha16） |
| 默认分支复核 | `ref: refs/heads/feat-Linux\tHEAD` ⇒ **仍是 `feat-Linux`**（**只读它，未改远端设置**） |

**⚠️ 途中踩到并处置的"假 MISMATCH"陷阱（如实记）**：`git fetch origin feat-Linux` **不会**更新 `refs/remotes/origin/feat-Linux`（该克隆的 fetch refspec 只跟 `main`）⇒ 第一次算 `rev-parse origin/feat-Linux` 仍得 **旧值 `84f98a971d…`**，若直接拿它算 `BYTECHECK` 会得到**全表 MISMATCH 的假红**。处置：显式 `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`（**只写本地 `refs/remotes/`**）⇒ 跟踪 ref 变为 `fff2ba38c35deeb6…` == `HEAD`，`git status -sb` = `## feat-Linux`。`BYTECHECK` 是**在跟踪 ref 修正之后**算的。

---

## ⑥ `$R` 与远端不同的件单列（**"本地领先"**）

**核法**：取克隆 `git ls-files` 全表（**15283** 行），逐件 `cmp` `$R/<path>` vs 克隆磁盘（`xargs -P3`，耗时 **12.4 s**）。

| 类别 | 件数 | 内容 |
|---|---|---|
| **`DIFF`（= `$R` 领先远端）** | **2** | `docs/ROUTES.md`、`build/MilBridge/tools/defect-registry-declared.tsv` —— **两件都是本批的件**（即在 `BYTECHECK` 之前是领先件，现已推送并逐字节对齐） |
| `NOINFO_MISSING_IN_R`（克隆有、`$R` 无） | 7366 | **既有结构性差**（不是别人的在办件）：克隆保留上游快照（`Documentation/**`、`eng/**`、`build.sh`、`azure-pipelines*.yml` …）＋被裁剪的部分，而 `$R` 是**裁剪过的工作树**（见 `docs/UPSTREAM-PROVENANCE.md`） |
| **别人的在办件（W134A／W136A／W137A）** | **0** | **现场实测：`src/**`、`verify-all.sh`、`close-wave.sh` 与远端逐字节相同** |

**⚠️ 如实记一条与派单书预期不符的事实**：派单书写"现在应有 W134A／W136A／W137A 的在办件 ⇒ 写'本地领先'"；**现场扫描结果 = 这三条车道目前在 `$R` 里没有任何与远端不同的件**（0 命中）。**最可能的原因** = 它们按车道纪律在**私有目录**（`~/w13*a/**`）里干活、产物**尚未落到 `$R`**；⚠️ 本条只覆盖**克隆 `git ls-files` 里被跟踪的件** ⇒ "未跟踪的新件／私有目录里的在办件"**不在本扫描射程内** ⇒ 该子问题记 **`NOINFO`**。
**处置**：本批**一件别人的件都没 `add`**（`git status --porcelain` 自始至终只有本批那 2 行；push 后 `git status --porcelain` 为空）。

---

## ⑦ `NOINFO` ／ 未做（逐条，不猜）

1. **`NOINFO`｜"W134A／W136A／W137A 的在办件"清单** —— 本件扫描的是**克隆被跟踪的件**，只找到本批 2 件 `DIFF`（见 §⑥）。**未跟踪件／私有目录（`~/w13*a/**`）未扫** ⇒ 若它们在私有目录里已改了东西，本件**看不见**。
2. **`NOINFO`｜`TASK-0210` 的真实进度** —— 本件只按派单书写"波 `#54`、车道 W134A 在办"（这是**主控口径**）；**W134A 的报告在现场不存在** ⇒ "已开工到哪一步"本件**没有读数**、不去编。
3. **未做｜报告自身的推送** —— 本报告成文于第一笔之后 ⇒ **本件是第二笔**（见文末）。
4. **未做（按任务书范围）** —— 本批**零 `dotnet`／零构建／零门禁重跑／零应用／未占 `heavy-slot`**；`git` 与 `sha256sum`／`cmp`／`diff` 之外没跑任何重活。
5. **未做｜`TASK-0302` 的 PTS 真实现** —— **仍 🔴 长线**，本收口**不碰**（同趟写进 `ROUTES.md` 两处）。
6. **未做｜`TASK-0502` 的两条波尾必做** —— `sync-applocal-authority.sh --apply`（4 份 app-local 副本）与"修前件 2 硬链接已断"的处置：**本批未做**（属波尾收尾链，且**需构建/应用环境**，本件按纪律不占槽）⇒ 仍挂在 `TASK-0502` 子树上**未动**。
7. **`TASK-0501`／`TASK-0303` 的收口依据均引"别人已落地的读数"** —— 本件**没有重跑**那些读数（`rc=134`／洋红像素数／`COUNT=1→3` 等），而是**逐字引用在册判词 ＋ 现场只核"状态位与世代位是否在位"**。这是本批（登记批）的既定射程；⚠️ **若那些读数本身有误，本件不构成对其独立复核**。

---

## ⑧ ≤5 行小结（中文大白话）

1. **两条挂在 🟡 的 `TASK` 收口了**：`TASK-0303`（PTS 最小边界）与 `TASK-0501`（GIF 只有第 0 帧）——它们的活**早就被后续任务干完了**，只是状态位没跟上；这次**只换徽标、原文一字不动**，新内容全走"追加 bullet"。
2. **该说清的边界都写进去了**：`TASK-0302`（PTS 真实现）**仍 🔴 长线**；GIF 的 `disposal=2` 后续帧 **Skia 自己返错、我们如实失败**、托管级端到端**那一格仍是 `NOINFO`** ⇒ **没把"没做到的"写成绿**。
3. **地图补了一行**：`TASK-0111` 的"下一步"已被 **`TASK-0210`（波 `#54`、车道 W134A）** 接管，`D-G98` 的 `N3` 归因终局指向 `§15t`；**`TASK-0111` 状态位仍 `🔴`**（产品侧没修，不许写成 ✅）。
4. **门禁两遍全绿**：`DEFREG=PASS declared=147 route_ids=147`、`DECLDRIFT=0`、`rc=0`，两遍输出**逐字节相同**；声明件重生成后**只差一行时间戳**、锚点逐位不变 ⇒ 期间没人动过别人的 route 文件。
5. **推送干净**：`84f98a971d0059e7 → fff2ba38c35deeb6`（纯快进），2 件 `BYTECHECK ok=2 mismatch=0`、默认分支仍 `feat-Linux`；**逐径 `git add`、一件别人的在办件都没碰**（现场实测 `src/**`／`verify-all.sh`／`close-wave.sh` 与远端逐字节相同）。

---

**本件自身的推送**：本报告为**第二笔**（只含本件）. 第一笔的 head ＝ **`fff2ba38c35deeb6ce493a9277ed1f7763486f74`**、`BYTECHECK ok=2 mismatch=0`（见 §⑤）；本笔推送后的 head 与逐字节核对结果见收工消息。
