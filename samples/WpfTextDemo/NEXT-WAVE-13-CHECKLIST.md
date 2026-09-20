# **#13 验收清单（预备稿，未执行）** — 波名**不等**（主控口径：看现场九位 + 仪器 sha；基线号 `#13` 由主控冻表头时写）

> **2026-09-15 刷新（只读预备，未跑任何件）**：
> ① 10:22 主控逐条答复 §10 四问 + 现场锚按**纪律 4** 重读；
> ② 10:2x **主控推翻我"零影响 A/B ⇒ 逐位相同"的期望**（那只在**参数无效**时成立）⇒ 判据改写为「**差异 100% 落在携带 modifier metadata 的用例上**」，预期读数改用 T1b2 实测的 **B 列**（§2）；
> ③ 两处口径更正已由主控照收（`E = [0,4]`；臂 A/臂 B 工具不同）；仪器 sha **第三次取样**见 §0（主控 10:24:04 那版已被 10:24:06 版取代）。
> ④ 10:2x **臂 B 命令到手**（`--modifier-rule-check`，**判据与字体、与我们实现都无关**）+ **🚩 字体口径警告**（臂 B 真值面 `Arial` 本机无该字节 ⇒ **排版档不是门禁、不许按红报缺陷**）；
> ⑤ **sha 裁决**：`#13` 仪器 = **`2e458928fc1577c2`**；探针现档 **`0046ed20d832a7ef`**；臂 A 的 rc 修 + 阳性对照**已由 T1d 实测**（§5.2(4)）。

> **通用流程仍照 `NEXT-WAVE-11-CHECKLIST.md`**（门禁 / `tline` / oracle / RTL / DP / textbox / 矩阵 / 1400 / 边界纪律）。
> 本文件只记 **#13 特有的差异**；**等主控说「#13 件已就绪」再跑**。
> ⚠️ **本文件是只读预备**：我**没有跑任何件**（下面所有 sha/读数都来自**只读实读或既有日志**，逐条标了口径）。
> ⚠️ 机器 **2026-09-14 22:1x 挂起 → 2026-09-15 10:17 恢复**（`/tmp` 又清过一轮）⇒ 我这边**任何 `/tmp` 备份都不可依赖**。

## 0｜现场锚（**已按纪律 4 刷新 3 次** · 末次实读 2026-09-15 **10:27:14** ｜ `loadavg 9.95 / 3.66 / 1.42`（**波在跑 + 外部 `wpf2web`**））

> ⚠️ **我上一版锚（10:22:00）已过期**：T1d 在 **10:25:52**（探针）、T1b2 在 **10:24:06**（仪器）、波在 **10:26:25**（PC 产物）都落了件 ⇒ **以本表为准**；开跑前**再读一遍**。
> ⚠️ **`loadavg 9.95` 那趟不能取数**（纪律 2 静树）：**波在跑时不读**；复取时记 `loadavg` + `uptime`，并确认无并发构建。

| # | 件（**全路径**） | sha16 | mtime | 与 10:18 那版比 |
|---|---|---|---|---|
| ① | `build/shims/PresentationCore.HbTextLine.cs` | **`fde9e511e8443cf2`** | 09-15 10:19:55 | **变了**（`3081d088…` → 本值）= **三参数版已落** ✓ |
| ② | `build/MilBridge/tests/HbTextLineParity/Program.cs` | **`2e458928fc1577c2`** | 09-15 **10:24:06** | **又变了**（`6652f310…` → `ae8f0341…` → **本值**）= **#13 新仪器最终版**（含 `T1B_MODIFIER_META` 开关 + **`mayChange` 已含 `M_modifier`**，见 §2/§1.4(4)） |
| ③ | `build/MilBridge/tests/CoverageProbe/Program.cs` | **`0046ed20d832a7ef`** | 09-15 10:25:52 | **又变了**（`5982ce9c` → `06da8817` → `b331c192` → **本值**）= 臂 A / 臂 B / **规则核验**三档到位 + 臂 A 的 rc 修（见 §4/§5） |
| ④ | `build/MilBridge/tests/CoverageProbe/known-red.txt` | **`e37603a8825d85ae`** | — | 上版未记，登记用 |
| ⑤ | `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` | **`5dedc21f5f372c78`** | 09-14 22:14:58 | **未变** = T1c 的 PC 半 |
| ⑥ | `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | **`d7a848dfeedcf29b`** | 09-15 **10:26:25** | **波中已重建**（取代 `293f99525f5af4f2`(09-14 20:32:04)；`pf` 还没重建）⇒ **我复取时必须重读** |

- **shim 三参数语义（只读实读 ①，行 1439 / 3435-3472）**：`modifierOpenIndex` = 覆盖起点；
  `modifierScopeEnd` = **覆盖终点（半开；`-1` ⇒ 到段末），只喂「零宽跨度」**；
  `modifierCloseIndex` = 客户端 `TextEndOfSegment` 的下标（**`-1` ⇒ 从不关闭，只喂 `lbNull`**）。
  **未给区间 ⇒ `if (modifierOpenIndex < 0) lineHasModifier = hasModifierScope;`（行 3464）= 退回今天的段落级语义 ⇒ 旧调用点逐位不变**
  ← **这就是件 2 的结构性理由**（开关没落时的备选依据）。
- **仪器 sha 的三次取样（纪律 24「取样带时刻」的又一实例）**：

| 谁 | 时刻 | 读到 | mtime | 说明 |
|---|---|---|---|---|
| 我 | 10:22:00 | `ae8f0341a3418a9b` | 10:21:49 | 写入窗口里的前一版 |
| 主控 | 10:24:04 | `814d57ae9960e590` | 10:22:11 | = **T1b2 那批 A/B 数字用的版本** |
| 我 | **10:24:44** | **`2e458928fc1577c2`** | **10:24:06** | 比主控那版**又新 2 秒** ⇒ 内容 = **`mayChange` 加进 `M_modifier`**（只读实读行 815-819：「`#13` 登记：M_modifier（modifier meta 传参）—— 主控 2026-09-15 裁定 ②」） |

- **DLL**：T1b2 那批 A/B 用的是 `build/MilBridge/tests/HbTextLineParity/bin/Release/MilBridge.HbTextLineParity.dll = 7a3a916c80aa7e74`（10:22:30）；
  **现已是 `63d71c6922b79879`（10:24:21）⇒ 两者不同** ⇒ **那批 A/B 数字 = 期望列，不是我可以直接引用的读数**（复取时以当场 DLL sha 记账）。
- ⇒ **主控 09-15 已裁决：`#13` 的仪器版本 = `2e458928fc1577c2`**（"你对"）；`build/MilBridge/run.sh = 3e513e88a4fa4ec9`（未变）。
  **复取时仍以当场读到的 sha + 时刻为准**（纪律 4/24）；差异一律写进报告。
- 哨兵 `/tmp/bridge-frozen.flag`（mtime `09-14 22:02:14`）**仍是** `BASELINE=12` / `WAVE=close-wave-203111`。
  **主控 09-15 口径**：波由 `bash build/close-wave.sh` 发起（自动认领 + `integration-wave.sh` + native/桥判定 + 身份自检 + `verify-all`），
  **哨兵由它在末段自动改写**；**若它在 `[5/6] verify-all` 处中止，哨兵就不会更新**（上一趟发生过，主控手工补过）
  ⇒ **我不等"波名"**：看**现场九位 + 仪器 sha** 即可；**基线号 `#13` 由主控冻表头时写**（表头我**不碰**）。
- 显示 `:97` **不可达**（`xdpyinfo` 失败、无 `Xvfb`/无 app 残留）⇒ **干净起点**。
  > 又踩到老坑：`pgrep -f` 把我**自己的 `bash -c` 命令行**匹配成了"Xvfb/app 进程" ⇒ 边界一律以 **`xdpyinfo` + `/proc/<pid>/cmdline`** 为准，不认 `pgrep -f` 的行。

---

## 1｜（件 1）本波特有判据 = **`M_modifier` 收敛到真值**

语料（**只读实读**）：`tests/parity/windows/layout-b34/cases.json` 的 `M_modifier_*`，5 例；真值（同源 compact）在
`build/MilBridge/gen/layout-b34-compact.json`。**五例同文本**：62 字符
`'alpha bravo charlie delta echo foxtrot golf hotel india juliet'`、`fontSize=16`、**`modifierStart=6` → `modifierEnd=45`（区间长 = 39）**，
被修饰子串 = `'bravo charlie delta echo foxtrot golf h'`；`maxWidth` = `80 / 120 / 200 / 320 / 1000000`。

### 1.1 真值（**口径甲**：`tline` 那套「不一致用例 / 折叠明细」行里的 `真机 Len/W/cr`，与 #12 日志逐字一致）
| 用例 | 真机行数 | 真机行#0（与 #12 日志逐字） |
|---|---|---|
| `M_modifier_w80` | 2 | `Len=50 W=35.6000 cr=[3,47) W=38.9733` |
| `M_modifier_w120` | 2 | `Len=56 W=54.4633 cr=[6,50) W=61.2267` |
| `M_modifier_w200` | 1 | **`Len=63 W=74.0800 cr=[47,16) W=82.8367`** |
| `M_modifier_w320` | 1 | **`Len=63 W=74.0800 cr=[47,16) W=82.8367`** |
| `M_modifier_winf` | 1 | **`Len=63 W=74.0800 cr=[47,16) W=82.8367`** |

### 1.2 真值（**口径乙**：`--modifier-check` 读的 `gen/layout-b34-compact.json` 的 `lines[].len/w/ws/ext/lbNull`）
| 用例 | 真值行（逐字实读） |
|---|---|
| `M_modifier_w80` | 行#0 `len=50 w=74.5733 ws=1 ext=18.00 lbNull=False`（行文本 `…golf hotel `）／行#1 `len=13 w=78.1833 ws=1 ext=18.00 lbNull=True`（`india juliet`） |
| `M_modifier_w120` | 行#0 `len=56 w=115.6900 ws=1 ext=18.00 lbNull=False`（`…india `）／行#1 `len=7 w=37.0667 ws=1 ext=18.00 lbNull=True`（`juliet`） |
| `M_modifier_w200` / `w320` / `winf` | 行#0 **`len=63 w=156.9167 ws=1 ext=18.00 lbNull=True`**（整段 62 字符） |

> ⚠️ **纪律 18（读数 = 四元组）**：口径甲 `W=74.0800 ≠ 口径乙 w=156.9167`，**是两条口径的两个字段**，
> **不许混着比**、**不许互相换算**；引用时必须连 **artifact 名 + 字段名** 一起写。
> 我**不自己补字段名**（纪律 22 同族）：口径甲的字段名等与 T1b2 的对照表对齐后再落报告，现在只按日志原样引。

### 1.3 现状（#12 趟，**逐字**取自 `~/wfp-runs/tline-wave12.log`）
| 用例 | 实得 | 与真值差 |
|---|---|---|
| `w80` 行#0 | `Len=6 W=21.6320 cr=[1,5) W=20.1760` | — |
| `w80` 行#1 | `Len=6 W=22.4960 cr=[7,5) W=20.4160` | — |
| `w120` 行#0 | `Len=12 W=35.6000 cr=[3,9) W=53.2800` | — |
| `w120` 行#1 | `Len=14 W=45.8080 cr=[16,10) W=46.5280` | — |
| `w200` 行#0 | `Len=26 W=91.8560 cr=[10,16) W=93.5200` | ← 要收敛到 `Len=63 W=74.0800 cr=[47,16) W=82.8367` |
| `w320` 行#0 | `Len=44 W=156.1280 cr=[19,25) W=158.0000` | ← 同上 |
| `winf` 行#0 | `Len=63 W=218.8960 cr=[28,35) W=220.2400` | ← **`Len` 巧合相等、`W`/`cr` 都不对**（不许把 `Len=63` 当已修） |
| 行数 | `w80 7≠2`｜`w120 5≠2`｜`w200 3≠1`｜`w320 2≠1`｜`winf` 行#0 折叠明细不符 | 全部要回到**真机行数** |

### 1.4 判据（**本波特有的那一条**）
1. **收敛到真值**：`w200 / w320 / winf` 行#0 达到口径甲的 `Len=63 W=74.0800 cr=[47,16) W=82.8367`
   且**行数 = 真机行数**（`2/2/1/1/1`）；容差沿用既有口径（`|W−真机| < 0.34`、`cr` 起止 == 真机、`|cr.Width−真机| < 0.34`）。
   口径乙上同时要 `MODCHK 合计 … 行宽≤0.34 / len / ws / Extent / lbNull` **五项全中**（见 §5.2 的读数行）。
2. **`len` 仍包含 39 个字符**（**主控原话**）：修饰区间 `modifierStart=6 → modifierEnd=45`（**区间长 = 39**）
   **必须仍然生效** ⇒ **不许靠"缩区间 / 把被修饰字符排除出长度"把 `Len` 凑成 63**。
   > 我的读法：39 = `modifierEnd − modifierStart`（只读实读 = 39，被修饰子串 39 字符）。
   > **主控 09-15 确认："你理解正确"** ⇒ 39 字符**仍在 `len` 里（只是 advance 被置零）**、`Len=63` **必须由内容取得、不许靠缩区间凑**；
   > **判据 = `len` == 真值 且 `cr`（折叠区间）与宽度收敛到真值**。
3. **红→绿必须可归因**：`M_modifier` 族从 #12 的 **5 例不一致**（`F_lat_words 1 + F_nbsp_zwsp 8 + M_modifier 5 = 14`）里变绿；
   `F_*` 族（9 例）**不在本波射程** ⇒ 它们**不动**才对（**动了一位就报**）。B 列余下的一致/不一致见 §2.1。
4. **`T2-iso` 隔离矩阵**：`M_modifier` 已由主控裁定**登记为 `#13` 的目标族**，且**只读实读已落**进
   `mayChangeArr`（`HbTextLineParity/Program.cs` `2e458928fc1577c2` 行 **815-819**，注释写明「`#13` 登记：M_modifier（modifier meta 传参）—— 主控 2026-09-15 裁定 ②」）
   ⇒ 届时 `T2-iso` **两腿都应 ✅**（`各和 == 总数` + 其它族一位不动）。
   **若仍报冲突 ⇒ 立刻报主控**（主控口径；可能是版本混淆 —— 主控 10:24:04 读到的还是**未含 `M_modifier`** 的那版）。

---

## 2｜（件 2）A/B（不传 vs 显式传）—— 判据 = **差异 100% 落在携带 modifier metadata 的用例上**

> ⚠️ **主控 09-15 更正**：我原来的"**逐位相同**"期望**是错的** —— 它**只在参数无效时**才成立。
> T1b2 实测（**同一份 DLL `7a3a916c80aa7e74`、同一仪器 sha `814d57ae9960e590`、只切 `T1B_MODIFIER_META`**）推翻了它，而且**是更好的那种**：

| 项（**口径名逐字**） | A 不传 | **B 传（= #13 出货行为）** |
|---|---|---|
| 逐行记账·结构全等 | `1292 / 1298` | **`1298 / 1298`** |
| 宽度分桶 `0/≤0.34/>0.34` | `168 / 1089 / 41` | **`168 / 1096 / 34`** |
| 折叠明细全等 | `219 / 236` | **`225 / 236`** |
| `T2b` 行级；用例级 | `972/972`；`213/213` | **0 差（不动）** |
| 不一致用例数 | `14` | **`10`** |
| 折叠不符条数 | `17` | **`11`** |
| `T2d` 行级 Extent | `1260` | **`1259`（−1）** ← **未结清**，见 §3 |
| Extent 余差条数 | `58` | **`59`（+1）** ← **未结清**，见 §3 |
| 三份明细差异行 | — | `tline-detail 27 / t2d-width 20 / t2d-extent 7`，**全部是 `M_modifier_*`；非 `M_modifier` 差异行 = 0** |

**修复幅度（同一批读数）**：`M_modifier_winf 行#0` `439.1360 → 156.9280`（真值 `156.9167`，差 `282.2193 → 0.0113`）；
族内 `>0.34` 红数 **`7 → 0`**；**#12 那条"最大差 `282.219333`"消失**。

### 2.1 判据（**主控 09-15 改写后**）
**「差异必须 100% 落在携带 modifier metadata 的用例上；其余逐位相同（非 `M_modifier` 差异行 = 0）」**
- 我复取时**按此判**：三份明细（`tline-detail` / `t2d-width` / `t2d-extent`）的差异行**逐行点名**，**非 `M_modifier` 差异行必须 = 0**；
- **不再**要求整台仪器"逐位相同"（那是**参数无效**时的形态）；
- §1 的两套真值口径**仍然有效**；**#13 的预期读数改用上表 B 列**（`1298/1298`、`168/1096/34`、`225/236`、不一致用例 **`10`**、折叠不符 **`11`**）。
  > B 列 `不一致用例 14 → 10`：`F_lat_words 1 + F_nbsp_zwsp 8 = 9` 是**保留红** ⇒ 余下 **1 例属 `M_modifier`**；**具体哪一例以我复取的读数为准，我不猜**。

### 2.2 形式（**同一份 DLL 两趟，中间不 rebuild**）
- **唯一变量 = 一个 env 开关**（**主控 09-15 口径**，T1b2 已落）：`T1B_MODIFIER_META=0` ⇒ 调用点**不传**那三个实参（三个 meta 强制成 `-1/-1/-1`）；**不设 = 默认传（= 出货行为）**。
  **只读实读** `build/MilBridge/tests/HbTextLineParity/Program.cs`（`ae8f0341a3418a9b` 版；**现已是 `2e458928fc1577c2`，见 §0**）：
  `ModifierMetaEnabled = !string.Equals(Env("T1B_MODIFIER_META"), "0", Ordinal)`（行 86/93）；
  `if (!ModifierMetaEnabled) { modifierOpen = -1; modifierScopeEnd = -1; }`（行 430）；
  调用点 `… modifierOpenIndex: modifierOpen, modifierScopeEnd: modifierScopeEnd, modifierCloseIndex: -1`（行 461）。
- **调用（A = 出货行为 / B = 对照）**：
```bash
SHA=$(sha256sum build/shims/PresentationCore.HbTextLine.cs | cut -d' ' -f1)
cd build/MilBridge/tests/HbTextLineParity && dotnet build -c Release -m:1 --nologo -p:HbShimSrc="$PWD/../../shims/PresentationCore.HbTextLine.cs" >/dev/null
cd bin/Release
T1B_SHIM_SHA256="$SHA"                                 dotnet MilBridge.HbTextLineParity.dll   # 出货趟（传）
T1B_SHIM_SHA256="$SHA" T1B_MODIFIER_META=0             dotnet MilBridge.HbTextLineParity.dll   # 对照趟（不传）
```
  （`run.sh tline` 的 [2/3] 就是这么跑的，但它**每次都会 rebuild** ⇒ A/B 两趟**直跑同一份 DLL**，正式读数趟才走 `bash build/MilBridge/run.sh tline`。）
  **记录 DLL sha**：`build/MilBridge/tests/HbTextLineParity/bin/Release/MilBridge.HbTextLineParity.dll`（两趟之间必须不变）。
  **现锚**：T1b2 那批 A/B 用的 `7a3a916c80aa7e74`（10:22:30）→ **现已是 `63d71c6922b79879`（10:24:21）** ⇒ 复取时会再变，**以当场值为准**（见 §0）。
- **三个 oracle 臂**（`--tab-oracle`、`--tab-lines-oracle --known-red`、`tab-zero`(86) 那趟）：**各在开关两值下跑一次，输出必须逐位相同**
  —— 它们的调用点**根本不传** meta（`CoverageProbe` 不读这个 env）⇒ 这一趟是**反证**：若差异出现，说明 shim **自己**读了这个 env（那才是真缺陷）。

### 2.3 纪律
- 两趟**必须同一台仪器同一 sha**（运行**前后各记一次**仪器 sha + DLL sha + 件 sha + `uptime`/`loadavg`）；
- 只许在**同一棵静树**上做（中间若有人构建 ⇒ **两趟作废重跑**，纪律 2/23：并发构建会静默换被测件）；
- 比对**按口径名逐项比**，**不许整文件 `diff`**（日志里的 `artifact 路径/mtime` 两行天生不同 ⇒ 会造假红）；
- 若出现"读数回到修前" ⇒ **先怀疑被测件被换掉，再怀疑修法**（纪律 23）；
- **若该开关最终没落**（主控已要求 T1b2 加，我实读**已在**）⇒ 用 §0 的结构性理由（shim 行 3464：未给区间 ⇒ 退回段落级语义，旧调用点逐位不变），
  并**在报告里如实写"未能做同实例 A/B"**（**不许含糊**）。

---

## 3｜（件 3）**本波不许碰**的两处（碰了 = 越界，不是"改善"）

| 不许碰 | 现状（**同一台仪器**取的） | 判据 |
|---|---|---|
| **`Extent` 行级 / `Baseline`** | #12（不传侧）：`Extent` 行级 **`1260/1298`**、余差 **`58（主对拍集 38 + LH 组 20；容差 0.01 DIP）`**。<br>**#13 预期（B 列，T1b2 实测）**：**`1259`（−1）**、余差 **`59`（+1）** ⇒ 🚩 **未结清项** | **先当"未结清"、别当通过**（主控 09-15 口径）：主控已派 T1b2 **逐行点名归因**（哪一行、两腿值 vs 真值、方向朝/背真值）⇒ **结论到前我不下"通过/缺陷"判**；**`Baseline` 仍一位不动**；若差得更多 ⇒ 立刻报（口径乙里 `ext=18.00` 是 `≤0.34` 判据的同一字段，别混淆） |
| **`TextLineBreak` 判据** | 现判据 = **只判 `null / 非 null`**（`lbNull` = `GetTextLineBreak() != null`） | **只判 null/非 null** ⇒ **不许升级成"判其内容/属性"**（拿不到真值的列一律 `NA(source=…)`，纪律 22） |

> U1 臂的语义（只读实读 `tests/parity/windows/modifier-scope/closeindex-addendum.md` §3）正是这条 null 判据：
> `lbNull(line) == !( !isLastLine && ∃m: m.openIndex < nextLineStart && m.endOfSegmentIndex >= nextLineStart )`。

---

## 4｜（件 4）两臂都要跑（**A = b34；B = U1**）

### 4.1 臂 A：`b34` 语料（`close = -1`）
- 调用：`bash build/MilBridge/run.sh tline`（现行）+ **`--modifier-check`**（件 1 的逐行口径）；
- `--modifier-check` 传的是 `modifierOpenIndex = cases.json 的 modifierStart`、`modifierScopeEnd = modifierEnd`、**`modifierCloseIndex = -1`**（b34 **从不发 `TextEndOfSegment`**）；
- **臂 A 的预期读数（主控 09-15 转 T1d 实测，口径 = `MODCHK` 文本行）**：
  `MODCHK 合计 用例=5 行=7｜行宽≤0.34 7/7｜len 7/7｜ws 7/7｜lbNull 7/7｜退出码=0`；
- 判据：§1.4 + 上面这一行的**五项全中**（**rc 已可判**，见 §5.2(4)）。

### 4.2 臂 B：U1 `tests/parity/windows/modifier-scope/`（**53 例**，`DETERMINISM=MATCH`）
**口径（主控 09-15）：以 oracle 的三个字段为准**（T1b2 实测 53/53）⇒ **`modifierOpenIndex` / `modifierScopeCharRange` / `modifierCloseIndex`**，
`modifierScopeEnd` 取 **`modifierScopeCharRange` 的右端（半开）**，**不是** `close` 那一列。

**逐组真值（**只读实读** `out/modifier-scope-oracle.json`，与 addendum §1 表逐位一致）**：

| 组 | 例数 | `modifierOpenIndex` | `modifierScopeCharRange` | ⇒ `modifierScopeEnd` | `modifierCloseIndex` | buffer 长度 |
|---|---|---|---|---|---|---|
| `A-scope-line0` | 3 | 0 | `[0, 4]` | **4** | **4** | 32 |
| `A-rtl-scope-line0` | 3 | 0 | `[0, 4]` | **4** | **4** | 20 |
| `B-scope-lastline` | 3 | 30 | `[30, 34]` | **34** | **34** | 35 |
| `C-scope-whole` | 3 | 0 | `[0, 37]` | **37** | **-1（从不关闭）** | 37 |
| `C2-scope-visible` | 3 | 0 | `[0, 37]` | **37** | **-1** | 37 |
| `D-nomodifier` | 3 | **-1** | （无） | — | -1 | 36 |
| `E-scope-oneline` | 3 | 0 | **`[0, 4]`** | **4** | **-1** | 4 |
| `F-pen-on-stop` | 6 | -1 | （无） | — | -1 | — |
| `F-pen-on-stop-rtl` | 2 | -1 | （无） | — | -1 | — |
| `G-rtl-indent-paraindent` | 12 | -1 | （无） | — | -1 | — |
| `H-two-tabs-line-start` | 12 | -1 | （无） | — | -1 | — |
| **合计** | **53** | | | | | |

> 🚩 **一处口径更正（只读实读；主控 09-15 已照收）**：主控原文「`C`/`C2`/`E`：`open=0`、`close=-1`、`scopeRange` 是 `[0,36)` 一类（36 字符）」
> —— **主控自认"那句是过宽的概括，作废"**。实读 oracle：**`C`/`C2` 的 `modifierScopeCharRange = [0,37]`**（buffer 37；U1 说的"36 字符"是**可见**字符数），
> **而 `E-scope-oneline` 是 `[0,4]`**（buffer 4）⇒ `modifierScopeEnd = 4`，**不是 ~36**。
> ⇒ **改口径：逐例读 oracle 三字段、不许按组概括**（主控原话）；`D/F/F-rtl/G/H` = `(-1, 无, -1)` ✓ 与主控口径一致。

- **行级真值可用字段**（同一 oracle 的 `lines[]`）：`lengthWithNewline / newlineLength / trailingWhitespaceLength / width / widthIncludingTrailingWhitespace / isLastLine / intersectsModifierScope_openInclusive_closeExclusive(…) / lineText / visibleLineText / perChar`；
  **`lbNull` 有真值字段 `lineBreaks[].isNull`** ⇒ 判据仍是 **只判 null / 非 null**（与 §3 一致，**不许**升级成判内容）。
- **判据**：53 例全跑；**逐组 `(open, scopeEnd, close)` 必须复现上表**（含 `C/C2` 用**覆盖终点**而非 close、`E` 的 4）；
  **行级判据只取与字体无关的那几项**：`isLastLine` / **`lbNull`（真值字段 `lineBreaks[].isNull`）** / 逐组区间形态；
  `width` / `widthIncludingTrailingWhitespace` / `lengthWithNewline` 等**依赖字体面 ⇒ 本机不可比**（见下面 🚩 警告），**不许按红报缺陷**。
  候选定义 `(i) open+TextModifier.Length` 与 `(ii) 段落末端` **已被既有真机数据否掉**（各 43/99、14/99 不符）⇒ **不许**用它们"解释"不符。
- **🚩 字体口径警告（主控 09-15 转 T1d 原文，必须写进报告）**：
  **臂 B 的真值面是 `Arial`（`fontSha256=baa25152…`，本机无该字节）⇒ 臂 B 的"行宽/断行"在本机不可比（与 §9.4(B) 同因）
  ⇒ 任何排版档都不是臂 B 的门禁。**
  ⇒ 上表第 214 行的"行级 `width`/`lengthWithNewline` 逐行对拍"**在本机不适用**：**不许把那些红写成缺陷**（那是字体口径，同 §9.4(B) 家族）。
- **臂 B 的门禁 = 与字体无关的那条（主控推荐）**：
```bash
dotnet build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.Tests.dll \
       --modifier-rule-check tests/parity/windows/modifier-scope/out/modifier-scope-oracle.json
# 预期：MODRULE 用例=53（无可核 lineBreaks 的 0）行=170｜判据吻合 170/170（不符 0）｜退出码=0
```
  它用**真值自己的三字段**把 U1 判据算一遍、再与 `lineBreaks[].isNull` 对拍 ⇒ **与字体、与我们实现都无关**，核的是**"规则本身"**（T1d 实测通过、10 个族逐族 `n/n`）。
- **三条命令的分工（主控 09-15 口径）**：
  | 档 | 命令 | 判据 | 备注 |
  |---|---|---|---|
  | **臂 A** | `--modifier-check` | `MODCHK 合计 …` 五项全中 + `退出码=0` | b34 5 例 7 行（§4.1） |
  | **臂 B（门禁）** | `--modifier-rule-check <oracle.json>` | `MODRULE … 判据吻合 170/170（不符 0）` + `退出码=0` | **纯数据核验**，推荐 |
  | 臂 B（排版档） | `--modifier-armB <oracle.json>` | **登记为"本机不可比"**：`rc=1`、行宽 `0/84`（纯字体口径） ⇒ **不许写成缺陷** | 只留档 |

---

## 5｜（件 5）`--tab-oracle` **rc 修的验收** + `--tab-lines-oracle` 语义**不许破**

### 5.1 修已落（**逐字实读** `build/MilBridge/tests/CoverageProbe/Program.cs`；修落于 `5982ce9ca2d01d22`，
**现档 `0046ed20d832a7ef`（10:25:52）里 `TAB_ORACLE 退出码=` 与 `return fail == 0 ? 0 : 1` 逐字仍在**）
```
int judgeable = total - BidiSkipped;           // 可判例数（**跳过的 57 例不算判据**）
int fail = judgeable - pass;
Console.WriteLine("TAB_ORACLE: cases=" + total + " pass=" + pass + " fail=" + fail + …);
Console.WriteLine("TAB_ORACLE 退出码=" + (fail == 0 ? 0 : 1) + "（可判 … ；跳过 … 不计）");
return fail == 0 ? 0 : 1;
```
⇒ **判据口径 = "只有可判例里的失败才算红"**；修前是 `pass == total ? 0 : 1`（`total=114` 含 57 按设计跳过 ⇒ **构造性恒 rc=1**，我 #11 报的仪器缺陷）。

### 5.2 验收（**先证 rc 会非零，再看绿趟** —— 纪律 21）
1. **红极性（必做的牙）**：拿一个**必失败**的输入证明 `rc≠0`。
   - 做法（**不动仓里的件**）：把 `tests/parity/windows/tab/out/tab-oracle.json` **复制到 `/tmp`**，
     只把**一条** `perChar` 的期望宽度改大（远超 `0.01` 容差），**JSON 形状不变**；
   - 期望：`TAB_ORACLE: … fail=1`、`TAB_ORACLE 退出码=1`、**`rc=1`**；
   - ⚠️ 若报的是 **`rc=2`（形状不符/读档失败）⇒ 这次不算证明**（只是"我用错档"，#11 踩过）；
   - 若 T1d 给了自检牙（`--…-selftest` 之类）⇒ **优先用他们的**，且**牙中 sha 动手前报出**。
2. **绿极性**：默认档 `cases=114 pass=57 fail=0`、`跳过(bidi 依赖…)=57` ⇒ **`rc=0`** 且打印 `退出码=0`。
   - **判据值取 `TAB_ORACLE:` 行 + `退出码=` 行**，**不单看 rc**（rc 只是消费端）。
   - **不许**为了 rc 好看动输出格式/口径（`fail` 的定义就是判据本身）。
3. **`--tab-lines-oracle` + `--known-red` 语义保持（不许破）**：
   **不给表 ⇒ 任何失败都算未登记 ⇒ 非零**；**已登记的失败只点名 `KNOWN-RED`、不改退出码**；**表文件不存在 ⇒ 视作空表**。
   本波 `tab-zero` 期望：`rc=0`、`结构败=1`、点名且**仅**点名 `notab-control@w40@em24@RTL@tab0::尾部空白`。
4. **`--modifier-check` 的 rc 恒 0 —— "退出码不可判"家族第三例，T1d 已在同波修好**（**只读实读**：现档 `MODCHK 退出码=` + `let failA = 行失败数; return failA == 0 ? 0 : 1;`）。
   - **主控 09-15 口径**：前两例 = `--tab-lines-oracle`（改前恒 0 / 改后"不给表恒 1"）、`--tab-oracle`（构造性恒 1）⇒ **判据一律看判据行**。
   - **T1d 的阳性对照已实测**（主控转）：翻转 `/tmp` 副本里**一条 `isNull`** ⇒ **`rc=1`**、`判据吻合 169/170` 并**逐行点名**；还原 ⇒ **`rc=0` / `170/170`**。
   - **我的验收（复取时）**：① 绿趟 `rc=0` **且** `MODCHK 合计 …`／`MODRULE … 判据吻合 …` 行**逐字相符**（§4.1/§4.2 的预期行）；
     ② **阳性对照我自己重做一遍**（同构：`/tmp` 副本翻一条 ⇒ 期望 `rc≠0` + 逐行点名；**若报 `rc=2` 是"我用错档"，不算证明**，纪律 21）；
     ③ **牙的 sha 在动手前报主控**（#11 的口径教训）。

### 5.3 三个 oracle 臂的调用（逐字，`PATH` 前置 `$HOME/.dotnet`；**构建与运行同一条命令**，纪律 23）
```bash
export PATH="$HOME/.dotnet:$PATH"
dotnet build build/MilBridge/tests/CoverageProbe -c Release -p:HbShimSrc="$PWD/build/shims/PresentationCore.HbTextLine.cs" -v q --nologo
dotnet build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.Tests.dll --modifier-check            # 臂 A
dotnet build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.Tests.dll \
  --modifier-rule-check tests/parity/windows/modifier-scope/out/modifier-scope-oracle.json                   # 臂 B（门禁）
dotnet build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.Tests.dll \
  --tab-oracle tests/parity/windows/tab/out/tab-oracle.json
dotnet build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.Tests.dll \
  --tab-lines-oracle tests/parity/windows/tab-zero/out/tab-zero-oracle.json \
  --known-red build/MilBridge/tests/CoverageProbe/known-red.txt
# 留档（登记"本机不可比"、不做门禁）：--modifier-armB tests/parity/windows/modifier-scope/out/modifier-scope-oracle.json
```

---

## 6｜（件 6）**仪器版本边界** + **四元组** + **前后 sha**

- **本波 `tline` 仪器已换版，主控 09-15 裁决**：`build/MilBridge/tests/HbTextLineParity/Program.cs` = **`2e458928fc1577c2`**（mtime 10:24:06）；
  `build/MilBridge/run.sh` = **`3e513e88a4fa4ec9`**（未变）；DLL 现档 **`63d71c6922b79879`**（10:24:21；T1b2 那批 A/B 用的 `7a3a916c80aa7e74` 已被取代）。
  ⇒ **与 #12 的 `tline` 读数只做"形状比对"，不做绝对值比对**（#12 那趟的仪器 sha 记在 `WAVE24-FINAL-ROUND.md` §0）；
  跨版比绝对值 = 拿两把尺子量一次（纪律 18/23 同族）。
- **探针（`CoverageProbe`）版本链**（主控 09-15 转，全是同一文件连续小修、**未碰 shim**）：
  **`cc61299d → 5982ce9c → 06da8817 → b331c192 → 0046ed20d832a7ef`（现档，10:25:52）**。
- **每条读数写全四元组**（`docs/CURRENT-STATE.md` 纪律 18 定义）：
  **`(被测件 sha, 仪器/harness 版本, 判据口径, artifact 名 + 字段名)`**。
- **同名件必须写全路径**（本仓有两个 `Program.cs`）：
  `build/MilBridge/tests/**HbTextLineParity**/Program.cs`（`tline`） vs `build/MilBridge/tests/**CoverageProbe**/Program.cs`（oracle / `--modifier-check`）。
- **前后各记一次仪器 sha + 件 sha + `uptime`/`loadavg`**（纪律 23/24）；两次数值不同 ⇒ 该趟读数**作废**。
- **构建与运行放同一条命令**（纪律 23）；**不做** `-p:OutputPath=/tmp/...` 出仓隔离（**已证不可行**：native 解析按 app 目录向上走 ⇒ `GetDC` 崩溃、两趟 core dump）。

---

## 7｜（件 7）`D-T1` 回归 —— **本波不该动**

- `tab-zero`(86)：**结构败 `13 → 1`**（射程内 **12 ⇒ 0**、**第 13 例
  `notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白 期望=0 实得=1` 点名保留**）；`判定过 = 85`；`Q3 clamp 28/28`。
- **`0/86` ⇒ 立刻停、立刻报主控**（射程被扩大或判据被动过）；**不许**把 `0` 当"变好"、**不许**继续跑后面的臂。
- 本波改的是 PC/shim 的 modifier 区间 ⇒ 该数**不该动**；动了先问"**是不是同一台仪器同一 sha**"（纪律 23）。

---

## 8｜（件 8）应用层 —— 与 #12 相同，逐条照旧

- **门禁**：`WPTD_GATE=PASS`、两档 3/3、`runner exit=0`、6 条 `result=PASS`、`leftover_after=0` ×6、
  `BRIDGE_SRC_STALE=no`（**`NOINFO`（缺 `bridge-src-fp.txt`）也算红**：不报绿）、桥契约 `ok(0 且无条款表)`、**判据⑤/⑥ 原文**；
- **九位 + `EXT` 行逐位记**：本波 `pc` **必变**、`hbtextline` **必变**（shim 半落地后）；`provider`/`pf` 若随重建变则记新值；
  **`hbtextline_shim_stale` 必须 `no`** —— `yes` 先查 **mtime 假警报**（`cp -p`/`touch -r` 的教训），再报；
  **不许**拿 #12 的九位值当对照（跨波不比绝对值）；
- **RTL 三条**：`Δright=1 / Δw=0 / 0.97`；镜像 `k=71`、`0.736` vs 正序 `1.958`；块区 `AE=0`；census `50/50 报「无」`；
- **`text-dp-min`**：`t2='A' c2=1 sel='A' line0='A'`（零注入）；
- **`textbox-edit`**：`DP1_LEG state=closed rc=0`（`first_inject` 有值）＋ Ctrl 生效 ⇒ 替换语义 + `PERLINE` 全 `eop=1`；
- **全块矩阵**：`registry=ok(count=11)`、端到端 `11==11`；FAIL **先做帧穷举、再把该块放最上面 `--only` 重跑**（L20）
  ——**没做 L20 就不许把它写成缺陷**；
- **`1400` 两口径各自现数**（**永不混用**）：门禁口径 #12 = **162**、每次启动口径 #12 后 = **185** ⇒ 本趟**两口径都必须 0 次**；
- **`APPSYNC` 既存红**（`samples/HelloWpf/bin/Release/net10.0/DirectWrite.Linux.Provider.dll` 缺件）照 #11 措辞：
  **仪器首次抓到 · 既存 · 非本波引入**。

---

## 9｜边界与纪律（每趟照做）

- `:97` **一次只跑一个应用**；开跑前 **`xdpyinfo -display :97` 预检**；只按 **PID** 杀；跑完记 `leftover_after` + `loadavg` + `uptime`；
- **日志一律放 `$OUT` 之外**（L13：runner 会 `rm -rf "$OUT"`，我被删过两次）；
- **不动**：`src/**`、`build/shims/**`（T1d）、`build/MilBridge/**`（T1b/T1c）、`build/*.Linux/**` 的 applier、T2 的 checker；
  `:99` 不碰；`:96` 是 M7b 的；
- **不冻基线、不开波、不动 `ACCEPTANCE-BASELINE.md`**（#12 表头 = 主控 09-14 22:02:14 冻的，含"行尾 NBSP 口径"；**不许给冻表头补追记**）；
- 每个数字**带口径名**；**不跨波比绝对值**；牙/自检**动手前先报 sha**；
- 外部载荷：另一项目 `wpf2web`（`tools/locked.sh build`）会把 `loadavg` 拉到 6.7–8.2（已测**不扰**我们读数）⇒ **照记 `loadavg`**；异常先看是不是"静树"被破。

---

## 10｜开工前的问题 —— **主控 09-15 已逐条答**（登记）+ 仍待 2 项

| # | 我问的 | 主控答复（**已落进本清单**） |
|---|---|---|
| **Q1** | #13 的波名与哨兵时机 | **不等波名**：波由 `bash build/close-wave.sh` 发起、**哨兵由它末段自动改写**（在 `[5/6] verify-all` 中止就不会更新 —— 上一趟发生过）；**我看现场九位 + 仪器 sha 即可**；**基线号 `#13` 由主控冻表头时写** ⇒ §0 |
| **Q2** | 新仪器 sha + 零影响 A/B 的确切形式 | 仪器 sha 由主控转；**A/B = 同一份 DLL、同一仪器 sha、只切 `T1B_MODIFIER_META=0` 两趟**；没落开关 ⇒ 用结构性理由 + **如实写"未能做同实例 A/B"**。**⚠️ 判据已被主控改写**（见 §2：**差异 100% 落在携带 modifier metadata 的用例上**，非 `M_modifier` 差异行 = 0 —— 原"逐位相同"期望**作废**） ⇒ §2 |
| **Q3** | 臂 B 的调用形式 + `C/C2/E` 指哪一列 | **口径以 oracle 三字段为准**：`modifierOpenIndex` / `modifierScopeCharRange` / `modifierCloseIndex`，**`scopeEnd` 取 `scopeRange` 右端（半开）**、**不是 `close`**；**臂 A/臂 B 的工具不是同一个**（主控自认"我说 `--modifier-check` 就是臂 B"是错的），**臂 B 命令主控向 T1d 要后转我** ⇒ §4.2（附口径更正：实读 `C/C2 = [0,37]`、**`E = [0,4]`**，**主控已照收并作废其"一类 `[0,36)`"那句**） |
| **Q4** | 「`len` 仍包含 39 个字符」的读法 | **我的理解正确**：`modifierStart=6 → modifierEnd=45` = **39 字符仍在 `len` 里**（只是 advance 被置零）⇒ 真值 `Len=63` **必须由内容取得、不许靠缩区间凑**；**判据 = `len` == 真值 且 `cr`（折叠区间）与宽度收敛到真值** ⇒ §1.4 |

**仍待（拿到我才动手）**：
1. **「件已就绪」信号** —— 主控说：波正在跑（PC 产物 `d7a848dfeedcf29b` 10:26:25、`pf` 未重建、随后身份自检 + `verify-all`）；**说"件已就绪"我就按本清单复取**
   （门禁 + `tline` + **三支 oracle** + 应用级），并**记 `HbTextLineParity/Program.cs` 与 `CoverageProbe/Program.cs` 的跑前/跑后 sha**；
2. **`Extent +1`（`1260 → 1259`、余差 `58 → 59`）的逐行归因** —— 主控已派 T1b2（哪一行、两腿值 vs 真值、方向朝/背真值）⇒ **结论到前算"未结清项"，不算通过**（§2 表 / §3）。
   （外加：`--modifier-check` 的 rc 修 + 阳性对照 T1d 已做 ⇒ §5.2(4) 我只**复做一遍**同构阳性对照。）

**已答/已消除**：① 臂 B 命令（`--modifier-rule-check`，含 Arial 口径警告）✓；② 仪器 sha 裁决 = **`2e458928fc1577c2`** ✓；③ `mayChange` 加 `M_modifier` ✓（那版正是 10:24:06 的仪器版）。
