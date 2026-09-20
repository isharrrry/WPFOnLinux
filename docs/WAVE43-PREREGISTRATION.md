# 波 `#43` 预登记（`D-G48` 去混淆 ＋ 两条登记/文档更正 ＋ 仪器修）

> **落地时机（有记录的原因）**：本件在上一代（`#40`）**冻结后复核 ×2 跑完之前**先以草稿写在 `$HOME`，
> 因为 `verify-all.sh` 第 `[11]` 步的预登记牙 = 「遍历 `docs/WAVE*-PREREGISTRATION.md`、`grep -qE "^#+ .*<当前代号>"`、`break` 在第一个命中」
> （`build/MilBridge/tools/verify-all-step-check.sh:207-218`）⇒ **复核期间**落地新件、而它**标题**里又带 `#40`，
> 那一步就会**在错的文件上**打 `prereg=PASS` ⇒ 污染那次复核。
> ⇒ 先草稿、**复核 ×2 全绿之后才落盘**（本文件即那次落地；`#40` 两趟 rc 均为 `0`）。
> 落地自检：本件**标题行里 `#40` 命中数 = 0**（`grep -cE '^#+ .*#40' docs/WAVE43-PREREGISTRATION.md`）；
> 正文提到 `#40` 不影响任何牙（牙只看标题行）。

---

## §0 本波要回答的一句话

`D-G48` 登记的两个触发条件 —— ①`DefaultIncrementalTab = 0`、②**tab 步长 > 容器宽** ——
**是不是真的由 tab 值引起的**？

**怀疑的来由（现盘可复算）**：`#42` 全部**有效**读数都取自**无 DISPLAY** 环境
⇒ "tab 值"与"有没有 X"这两个因子**完全混杂**；而 `D-G48` 的措辞把因果**全记在 tab 值**上。

---

## §1 证据（已经拿在手里，且已脱离 `/tmp`）

`/tmp` 里的 `#42` 探针日志已备份（`/tmp` 易失）：

```
$HOME/w21-verify/w43-tabgap-logs/*.probe.log|*.build.log   +   SHA256SUMS
```

| 日志 | 有判词（`TABGAP_RESPONSIVE=`） | 无 DISPLAY 迹象（`XOpenDisplay` 行） | `EXCEPTION` 行数 |
|---|---|---|---|
| `tabgap.f908Jv.probe.log` | 有 | **2** | 6 |
| `tabgap.Atoz0H.probe.log` | 有 | **2** | 6 |
| `tabgap.WHvOfw.probe.log` | 有 | **2** | 2 |
| `tabgap.xQvMPK.probe.log` | **无** | 0 | 0 |
| `tabgap.LSzQXV.probe.log` | **无** | 0 | 0 |
| `tabgap.o82GkH.probe.log` | **无** | 2 | 0 |

复算：`grep -c XOpenDisplay` / `grep -c EXCEPTION` / `grep -c '^TABGAP_RESPONSIVE='`。

**三条结论**：

1. **所有有效读数都是无 X 的**（3/3 有判词的日志都带 `XOpenDisplay` 失败行）；
2. 有 X 的两组（`xQvMPK`/`LSzQXV`）**根本没有判词** —— 它们死在
   `libhostpolicy.so` 找不到（`tab-gap-check.sh:26` 把 `obj/Debug` 当成了输出目录）⇒ **不能**用来反驳或支持任何事；
3. ⇒ `#42` 记录的"两个触发条件"是**无 X 下的观测**；**有 X 时从未测过**。

---

## §2 第一动作：**先测量，不动产品**（去混淆实验）

两个臂，**同一个二进制**（先构建一次，两个臂只换环境）：

| 臂 | 环境 | 目的 |
|---|---|---|
| **A** | `DISPLAY=:96`（**自起 Xvfb**，按 PID 收尸；禁 `pkill -f`；可用 `W43_DISPLAY` 换号） | "有 X"这一因子 |
| **B** | `env -u DISPLAY` | 复现 `#42` 的原条件 |

两臂都开诊断（取真因，不靠猜）：

```
WPF_LINUX_TEXTLINE_DIAG=1        # 脚手架各计数 + 前 8 条附加诊断（见下）
WPF_LINUX_TEXTLINE_LINEDIAG=1    # 逐段接手行（段起点/行数/宽高基线）
```

⚠️ **兜底链"为什么"交回 LS 就在 stderr 上**：`Bail()` 打
`LS_FALLBACK 交回 LS（前3条无条件|DIAG）：<真因>` —— **前 3 条无条件**，`DIAG=1` 再给 **8 条**预算
（`build/shims/PresentationCore.HbTextLine.cs:4510,4522-4528`）⇒ 本探针 6 个异常例**全在预算内**，
不必改产品就能拿到真因。

**判据表（三态，先写好，防"事后解释"）**：

| 观测 | 裁定 | 走哪条 |
|---|---|---|
| A 无 `EXCEPTION` 且 B 有 ⇒ 真因 = **无 DISPLAY 时的兜底链** | `D-G48` 的"tab 触发"措辞**被推翻**（须同趟改登记册）；产品**不改** | §3-I |
| A 与 B **都**在 `tab=0` / 窄容器 `tab=24\|48` 上 `EXCEPTION` ⇒ 真因在 tab 几何 | `D-G48` **成立**、且与 DISPLAY 无关 | §3-II |
| A 或 B 跑不出判词 | `NOINFO`（不许当绿）⇒ 先修仪器（§3-I 前三件）再重测 | §3-I |
| A 无 `EXCEPTION`，**但**窄档 `24/48` 的宽度与窄档 `4` **相同**（都等于兜底默认 `4×em`） | **不崩 ≠ 对**：兜底路径**丢 tab 参数**这一面显形（= `D-T4` 的残余）⇒ 仍需"透参"修法 | §3-II |

---

## §2.5 开工前的**预测**与依据（先写死，再去测）

**预测：`W43_VERDICT=X-CONFOUNDED-TRIGGERS-REFUTED`。** 依据三条（都可复算，且互不依赖）：

| # | 依据 | 读数/位置 |
|---|---|---|
| **P0** | **上游自己就把这两类输入判出"简单路径"**：判据 `CanProcessTabsInSimpleShapingPath` = `Tabs == null && DefaultIncrementalTab > 0`（注释逐字：*whether the conditions are met to make it possible to process tabs in the **simple** shaping path*）⇒ `DefaultIncrementalTab = 0` **必然**走复杂路径（真机上是 LS） | `build/PresentationCore.Linux/SimpleTextLine.Linux.cs:1779-1785`；调用点 `:1619` |
| **P0b** | 且 **tab 的理想宽 = "到下一个停靠位的距离"**：`run.IdealWidth = idealNextTabStopUnRounded - idealRunOffsetUnRounded` ⇒ 容器（40 DIP）窄于停靠位（24/48）时该 run 的理想宽超出行内剩余宽 ⇒ 命中下面 P1 的 `return null` | 同文件 `:1764-1771` |
| P1 | **快路径只在"不需要断行"时接活**：`SimpleTextLine.Create` 里 `if (!run.EOT && run.IdealWidth > widthLeft) return null;` —— 注释逐字写着 *linebreaking required … we'll now let **LS** handle this line* | `build/PresentationCore.Linux/SimpleTextLine.Linux.cs:278-283` |
| P2 | 探针的成败**与"是否需要断行"逐例吻合**：宽容器（120 DIP）`tab=4/24/48` 理想宽 ≤120 ⇒ **快路径自己接了**（所以它们正常）；窄容器（40 DIP）`tab=24/48` 理想宽 >40 ⇒ **必须断行** ⇒ 落到兜底（所以它们崩）；窄容器 `tab=4` 理想宽 32.797 ≤40 ⇒ 快路径接了（所以正常） | `#42` 探针日志：宽 4/24/48 = 32.797/56.797/104.797 正常；窄 24/48 崩、窄 4 正常 |
| P3 | **兜底链在无 DISPLAY 时"每次抛"**（既有在册陈述，与本波要测的东西独立）：`本机无 X/DISPLAY ⇒ TypeInitializationException ⇒ 宽松档 TryFormatLine 每次抛` | `build/MilBridge/tests/ProductEntryArm/Program.cs:147` |

⇒ P1+P2+P3 合起来读出的机制是：**"崩"的真触发条件是「该行需要断行 ⇒ 必须走兜底」；而在无 X 的环境里兜底 100% 失败**
⇒ `tab=0`（宽容器也崩）大概率**不是**因为"tab 值为 0"，而是因为 `DefaultIncrementalTab=0` 让该段也落进了"需要断行/需要分类"的那条路
（`SimpleTextLine` 的 `IdealWidth` 判据随 tab 语义变化）。**这一点必须由 `lastBail` 证实或推翻，不许由本推测代替。**

**若预测成立，`D-G48` 的正确措辞应是**（供同趟落盘）：
> 需要断行的文本必须由托管兜底接手；**在无 DISPLAY 的环境里兜底链必然失败**（宽松档每次抛），
> 于是落到 Linux 上**不存在**的原生 LineServices ⇒ `EntryPointNotFoundException` ⇒ 应用终止。
> **触发条件不是 tab 值**；tab 值只是"是否落进需要断行的那条路"的间接因素。
> 另有**独立**的真缺陷（`D-G47` 同族）：**最后一跳不该去够一个不存在的原生库** —— 应给出可诊断的失败。

---

## §3 两条修法分支（含**连带代价**，开工前先认账）

### I. 仪器 + 登记册（不碰产品位）

`tab-gap-check.sh` 有**三处已知仪器缺陷**（都在 `#42` 现场撞到过，其中 (b) 造出了两具"无判词"日志）：

| # | 现场 | 缺陷 |
|---|---|---|
| a | `:19` `dotnet build "$PROJ" -c Debug` | **硬写 Debug**，而 `:17` 把 `cfg` 印成 `selfbuilt-config.sh` 的**声明档**（今天是 **Release**）⇒ **印出来的 `cfg=` 与实际构建档不符**（自造的假声明） |
| b | `:26` `for cand in bin/*/TabGapProbe.dll` | 通配会取到 **`obj/Debug`** ⇒ `libhostpolicy.so` 找不到、**没有判词**（`xQvMPK`/`LSzQXV` 两具日志即此） |
| c | 全程不自起 X | 读数默认落在**无 DISPLAY** 档 ⇒ 与 (a)(b) 一起把"产品入口读数"变成"无 X 读数" |

修法（照 `w40-hc-polarity.sh` 已验证的形状）：① 自起 Xvfb 并按 **PID** 收尸；② 用**声明档**构建
（`-c "$SELFBUILT_CONFIG"`）；③ **只认** `bin/$SELFBUILT_CONFIG/`（写死，不用通配）；
④ 结论行里**同时**印 `DISPLAY=` 与**实际**构建档；⑤ 三态判据一字不改（`PASS`/`KNOWN-RED`/`NOINFO`，任一 `EXCEPTION` ⇒ `FAIL`）。

登记册更正：`D-G48` 的"两个触发条件"**同趟**改成**实测**结论，并把"`#42` 读数取自无 X 环境"写成**自认**；
`--emit` 重出登记表；`CAND_MIN`/roster 若因此变动则同趟更新。

> ⚠️ **本分支不动 `GEN_KEYS`、不动 `pc`/`pf`** ⇒ **不需**重取五臂。
> 但若将来把 `tab-gap-check.sh` 纳入 `fp_inputs` 覆盖面，则**改它必须安排在 `IN_FP_0` 采样之前**（独立准备趟）。

### II. 产品修（真因在 HB 兜底层）

**先取 `lastBail`，再决定动哪一层**：

| `lastBail` / 计数 | 出手的件 | 连带 |
|---|---|---|
| `缓存里没有该行` / `bailEmpty` / `bailRunType` / `bailFont` | `build/shims/PresentationCore.HbTextLine.cs`（`GEN_KEYS` 三件之一） | **取消五臂 + 重钉四处**（`repin-generation.py`） |
| 宽松档 `CollectLenient` 返回 false | `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（进 `pc`） | 臂日志内含 `pc` sha ⇒ **同样重取五臂**，且 `displacement` 须声明 `pc` |

两条都要顺带把 `D-G47` 同族那条**最后一跳**立住：Linux 上没有 LineServices，
`TextMetrics.FullTextLine` 那条路必须给出**可诊断的**失败（而不是 `EntryPointNotFoundException` 冒到应用）。

**⚠️ 关键代价（已逐行核实）—— 两条兜底入口现在都拿不到 tab 值**：

| 入口 | 形参里有没有 tab |
|---|---|
| 严格档 `HbTextFallback.TryFormatLine` | **没有**（`build/shims/PresentationCore.HbTextLine.cs:4634` 的形参表：textSource/cpFirst/paragraphWidth/pixelsPerDip/alwaysCollapsible/lineHeight/indentDip/paragraphIndentDip） |
| 宽松档 `WpfLinuxLenientTextFallback.TryFormatLine` | **没有**（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:344-347`，只有 indent/paragraphIndent/paragraphDefault） |
| **工厂**（两者的下游） | **早就有**：`double defaultIncrementalTab = double.NaN`（shim `:3959`；注释：`NaN ⇒ 框架默认 4×em；<=0 ⇒ 显式无停靠位`） |
| 两处调用点 | `TextFormatterImp.Linux.cs:692`（严格档）、`:723`（宽松档）—— **都没传** |

⇒ 读出的结论是：**`D-T4` 与 `D-G48` 很可能是同一个洞的两面** ——
**有 X 时**兜底静默用 4×em 默认值 ⇒ "tab 值不生效"（`D-T4`）；
**无 X 时**兜底整条抛 ⇒ 落到不存在的原生 LS ⇒ 崩（`D-G48`）。
若如此，**一个修法同时治两条**（把 `paragraphProperties.DefaultIncrementalTab` 从两处调用点透进两级兜底），
代价 = 动 **`pc`＋shim（`GEN_KEYS`）** ⇒ 五臂重取 + 重钉四处，`displacement` 须声明 `pc` 与 `hbtextline`。
⚠️ 但**先测后修**：`D-T4` 的"136 条真值"里到底有多少条会因为这次透参而**位移**，必须先拿读数（§5 第 3 条）。

---

## §4 本波**不做**的事（写清楚，防顺手）

1. 不改 `D-T4` 的 `tab0`/`default` **136 条真值口径**（真值锚点在 `tests/parity/windows/tab-anchor`，是真 Windows 录制）；
2. 不改 `DefaultIncrementalTab` 的语义（含 `<0`/`NaN`/`=0` 三档的既有约定）；
3. **不**在本波顺手改已入 `fp_inputs` 覆盖面的判据件（那是独立准备趟的事）。

---

## §5 本波"完成"的定义（冻结前必须拿到的读数）

1. 去混淆 **A/B 两臂原始日志**：含 `DISPLAY` 值、**实际构建档**、判词、`EXCEPTION` 数、`lastBail`；
2. `tab-gap-check.sh` 修后，在**声明档 + 有 X** 下至少一次**三态**读数；
3. 若动了产品 ⇒ 五臂重取 + 重钉 + 门禁 ×2 全 `result=PASS` + `verify-all` ×2；
4. `D-G48`（与必要时 `D-T4`）登记册措辞与**实测**逐字一致 ⇒ `DEFREG=PASS`；
5. 新基线（`#43`）＋（若覆盖面动过）`inputs_fp` 的**新值**，并声明为**设计性变更**；
6. §6 那条更正落盘：`CURRENT-STATE` 的推论句换成**证据句**（含 `AE=0` 与 60 具归档帧的读数）、
   `THIRD-PARTY-APPS` 的 `1275` 标为**待复现口径**、仪器增印 **`AE`** 与**同刻两法互证**。

---

## §6 第二主体：**`373` vs `1275`** 的更正（渲染完整度）

**被更正的那句话**（现盘逐字，`docs/CURRENT-STATE.md:3` 尾部）：
> ⚠️ Release 档 373 色 ≠ `#34` 的 1275 色 ⇒ 渲染完整度另立待办

**本波拿到的反证（全部可复算）**：

| # | 读数 | 命令 / 出处 |
|---|---|---|
| 1 | 今天 `#40`（Release 权威件）的 hc 帧与 `#33` 时代（**Debug** 权威件）的帧 **逐字节相同**：`AE=0`（两具独立帧都是 0） | `compare -metric AE ~/w40-hc-polarity/hc-Release-8.png ~/w33m-run/hc-win-24-12.png null:` ⇒ `0`；`…hc-win-25-12.png` ⇒ `0` |
| 2 | 同代内的瞬时抖动是 **76 像素**（光标/高亮），远小于"整帧换配置"应有的差 | `compare -metric AE ~/w33m-run/hc-win-24-11.png ~/w33m-run/hc-win-24-12.png null:` ⇒ `76`（今天帧 vs `…24-11` 也恰是 76） |
| 3 | 归档帧的**最大**颜色数就是 **373**（60 具 `~/w33m-run/hc-*.png`，含多个页面） | `for f in ~/w33m-run/hc-*.png; do identify -format '%k\n' "$f"; done \| sort -rn \| awk 'NR==1'` ⇒ `373` |
| 4 | `$HOME` 下**没有任何** `*hc*.png`（maxdepth 3）>600 色 | `find ~ -maxdepth 3 -iname '*hc*.png'` 逐具 `identify -format %k` ⇒ 全 ≤373 |
| 5 | 素材**本身就是调色板 PNG** ⇒ 373 色是"素材构造决定"的，不是"渲染丢了东西" | `Cover.png` **109 色**（1320×680 `PaletteAlpha`）／`Dance.png` 37／`cloud.png` 50／`chrome_dragon.png` 4 |
| 6 | **能复算的高色数近邻都属于别的主体**（不是 hc）：第三方 mini 应用 `~/w37-tpm-*/f*.png` ⇒ **1485**（早期批）／**1642**（后期批）；样本帧 harness（含"换 Content/加矩形"两臂）⇒ **2556–4019** | `identify -format %k` 逐帧；harness 读数出处 `docs/WAVE34-PREREGISTRATION.md:488,527-541,656` |

⇒ **裁定**：**"Release 档渲染完整度下降"不成立**。同一帧在 Debug 与 Release 权威件下 `AE=0` ⇒ 切配置**一个像素都没动**；
`373` 是这份应用在这个页面上的**正常值**（且 `#33` 时代就已经是它）。
而 `1275` **今天没有任何留存物可复算**，且可复算的高色数近邻分别属于**另外两个主体**（第三方 mini 应用 1485/1642；样本 harness 2556–4019）
⇒ 那句比较**主体与口径都没交代清楚**，不能用来支撑"完整度下降"。**本波不许顺手把它改写成另一个"确定结论"**：既然主体/口径未定，就如实写"待复现口径"。

**本波要做的（文档 + 仪器，不含产品）**：

1. **更正** `CURRENT-STATE` 里那句推论，并把上面 5 条读数写成**证据句**（同趟改，不许只改一半）；
2. `docs/THIRD-PARTY-APPS.md:6` 的「窗口内 **1275 色**」标注为 **`待复现口径`**，并写明"本仓现存最大 373（60 具归档帧）"；
3. 把这条完整度读数**做成仪器输出**：`w40-hc-polarity.sh` 现在只印 `max_colors` ⇒ 增印
   ①与历史基准帧的 `AE`、②**同刻两法互证**（裁剪帧 vs `xwd -id`，`#34` 门禁用过的那套）；
   这样"完整度"从**一个孤立的数字**变成**两条互相独立的读数**。
4. ⚠️ **若**复现出 1275 的那个口径（不同页面/抓帧法）⇒ 以那次为准**重新**写结论；**本波不许把 373 说成"就是唯一真值"**。

---

## §7 拟落盘文本（verbatim 草稿；落地时照抄，避免二次措辞漂移）

### 7.1 `docs/CURRENT-STATE.md:3` 尾部那句（**替换**）

现文（逐字）：
> ⚠️ Release 档 373 色 ≠ `#34` 的 1275 色 ⇒ 渲染完整度另立待办

拟替换为：
> ⚠️ **`373` vs `#34` 的 `1275` 这件事已定性**：hc 的 `373` 是**正常值**（素材本身是调色板 PNG，`Cover.png` 仅 **109 色**；
> `~/w33m-run/hc-*.png` **60 具归档帧最大就是 373**），且**与切 Release 无关** ——
> 今天 `#40`（Release 权威件）的帧与 `#33` 时代（**Debug** 权威件）的帧 **`compare -metric AE` = 0**（`hc-win-24-12`/`hc-win-25-12` 两具独立帧都是 0）
> ⇒ **切配置一个像素都没动**。`1275` 今天**无任何留存物可复算**；能复算的高色数近邻属于**别的主体**
> （第三方 mini 应用 `1485`/`1642`、样本帧 harness `2556–4019`）⇒ 那句比较**主体与口径都没交代**，
> 不能支撑"完整度下降"。**hc 完整度的可复算判据**改为：`AE`（对历史基准帧）＋ `max_colors`（对素材色数上界）两条一起看。

### 7.2 `docs/THIRD-PARTY-APPS.md:6` 那句（**替换**）

现文（逐字）：
> （自定义 chrome ＋ 中文控件名 ＋ 图标 ＋ 图片；窗口内 **1275 色**，**零探针装置**）。

拟替换为：
> （自定义 chrome ＋ 中文控件名 ＋ 图标 ＋ 图片；**零探针装置**。窗口内颜色数：`#33`/`#40` 两代实测均为 **373**
> —— 与素材一致：该 demo 的图是**调色板 PNG**（`Cover.png` 109 色 / `Dance.png` 37 / `cloud.png` 50）；
> ⚠️ 旧记录里的 **`1275`** 出自**未留存的采集口径**，主体与口径**均待复现**，不作为判据）。

### 7.3 `KNOWN-DEFECTS.md:1541` 的 `D-G47` 标题（**替换**，与 `D-G48` 无关）

现文（逐字）：
> `### 🆕 \`D-G47\`：**Debug 权威件带着"活的"\`Invariant.Assert\` ⇒ 真实第三方应用被断言炸掉**（\`#38\` 实测，**未修**）`

拟替换为：
> `### ⚪ \`D-G47\`：**终止形态已治**（`#40` 权威件切 Release，双极化实测：Release `assert_hits=0` / Debug `assert_hits=1`）；**断言所指的潜在真缺陷仍未定性**（Release 只是不再报它）`

⚠️ **必须写清楚这一层**：切 Release **不是**证明那段代码对了 ——
上游那句 `Debug.Assert`（`MS/Internal/Helper.cs:591`，"DependencyProperties can only be set on DependencyObjects"）
**可能是真的在报一个真缺陷**，只是 Release 下不再有它的声音 ⇒
`D-G47` 拆成两半：**终止形态 ✅ 已治** ／ **潜在真缺陷 待定性**（定性手段见 §8 观察项）。

### 7.4 `D-G48` 条目（**待 §2 判据落定后填**）

占位：按 §2.5 的"正确措辞"模板填，且**必须**含一句自认：`#42` 的三个有效读数都取自**无 DISPLAY** 环境。

---

## §8 §7 之外**顺带发现**、需要单独立项的东西（本波只登记不做）

| # | 发现 | 为什么不顺手做 |
|---|---|---|
| 1 | `tab-gap-check.sh:19` 硬写 `-c Debug` 而 `:17` 印的 `cfg` 是**声明档** ⇒ 结论行里的 `cfg=` **可能是假的** | 属于 §3-I，本波做 |
| 2 | `build/PresentationCore.Linux/*.cs`（`SimpleTextLine`/`TextFormatterImp` 等**端口输入**）**不在** `inputs_fp` 覆盖面里 ⇒ 改它们**波中零机器红**（但要到冻结点才经 `pc` 的 sha 现形） | 加进覆盖面 = 改判据覆盖面 ⇒ 须独立准备趟（且要在 `IN_FP_0` 之前） |
| 3 | `TabGapProbe.csproj:38` 注释仍写"被测件 = 权威 pc（**Debug**）"，而 `HintPath` 已是 `$(WpfLinuxSelfBuiltConfiguration)` | 纯注释漂移，随本波改仪器时一并改 |
| 4 | `D-G47` 那句断言"**可能**在报真缺陷"——定性手段 = 在 **Release 件上打开那条断言的诊断**（不改语义）跑 hc，看它是否仍会命中 | 需要动产品/诊断开关 ⇒ 单独立项 |

---

## §9 诚实条款

**本波的第一产物可能是一句"上一条登记写错了"。** 那是合法结果 ——
但必须**同趟**落到登记册与记录里；不许只留在报告正文里，也不许两边措辞不一致。

**✅ 本波真的就是这么收的**：`D-G48` 的"触发条件"被推翻（见 §10 ①），
两处文档措辞与仪器判据**同趟**更正。

---

## §10 记录（`#43` 收官读数 —— 全部可复算）

### ① 去混淆判词（预先写死的三态表命中第一行）

```
TABGAP_DISPLAY_POLARITY=X-CONFOUNDED
  exc_A=0  exc_B=6  verdict_lines_A=1  verdict_lines_B=1
```

| 例（`TabGapProbe`） | 臂 A **有 X** | 臂 B **无 DISPLAY** |
|---|---|---|
| 宽档 120 DIP `tab=0/4/24/48` | `74.156 / 32.797 / 56.797 / 104.797`，**0 异常** | `tab=0` **抛**；`4/24/48` 同 |
| 窄档 40 DIP `tab=0/4/24/48` | `9.805 / 32.797 / 9.805 / 9.805`，**0 异常** | `tab=0/24/48` **各抛**；`tab=4` 同 |

兜底链自己的诊断（stderr 逐字）：
`LS_FALLBACK 交回 LS（前3条无条件）：异常 TypeInitializationException: The type initializer for 'System.Windows.Media.Brush' threw an exception.`

⇒ **`D-G48` 的"tab 触发"措辞被推翻**；真因 = 无显示 ⇒ 兜底链必抛 ⇒ 落到不存在的原生 LS。

### ② `tab-gap-check.sh` 修后（同趟新增细判据）

```
TABGAP DISPLAY=:96 ready（1280x1024）
TABGAP WIDTHS wide=74.156/32.797/56.797/104.797 narrow=9.805/32.797/9.805/9.805
TABGAP_FALLBACK_TAB_LOST=yes
TABGAP_CHECK=KNOWN-RED reason=fallback-ignores-tab（…兜底路径静默用 4×emSize、未吃 DefaultIncrementalTab）
rc=1
```
（修前同一份产品会打 `TABGAP_RESPONSIVE=yes` ⇒ **粗判据假绿**；今天被细判据拦住。）

### ③ hc 完整度定性

`compare -metric AE ~/w40-hc-polarity/hc-Release-8.png ~/w33m-run/hc-win-24-12.png null:` ⇒ **0**（`…hc-win-25-12.png` 亦 0）；
60 具归档帧最大色数 **373**；素材 `Cover.png` **109 色**（调色板 PNG）。

### ④ 位移与全部牙齿（**位移 = 空**）

| 格 | 读数 |
|---|---|
| `inputs_fp` | `ee98113baa280482491cdaceba76404a8d57517bffab9ec55ce5c7674d5fe812`（**与冻结声明逐位相同**） |
| `BASELINE-SHA` | `BASELINEGEN=PASS decl_gen=#40 file_newest_gen=#40`；`BASELINEDUP=PASS n=0`；`BASELINE_BYTES=491143` |
| `ARM-LOG-SHA` | `PASS shape=flat required=5 declared=5 pass=5 fail=0` |
| `COLUMN-FLOOR` | `PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0`；`reg=916998e1d429ce46 base=6ebabe39e5552300 corpus=0cebc0afd5142fbf` |
| `DEFECT-REGISTRY` | `PASS declared=84 route_ids=84`；`DECLDRIFT=0`（声明表已 `--emit` 重出：`DECL-ANCHORS KD=e1083ca2dfdc9ce5 CS=2f12e247a518da24 HO=dd82228c71c42272 AB=6ebabe39e5552300`） |
| `VERIFYALL-SELF` | `PASS names=25 decl=25 gen=#40 dup=0 order=OK prose=OK prereg=PASS` |
| `FP-INPUTS-HYGIENE` | `PASS reason=clean coverage_n=125 artifact_n=0` |
| `PIPEFAIL-SIGPIPE` | `PASS undeclared_hit=0 declared=1 files=62 sites=75 hit=1 runs=12` |
| `SHELL-QUOTE-TRAP` | `PASS reason=ok traps=0 files=139 sh=62 py=77` |

⇒ **不重冻**（基线一字未动）；`#40` 的 post-freeze ×2 已全绿（`VA_POST1_RC=0`／`VA_POST2_RC=0`）。

**收官完整 `verify-all`（本波只跑一趟，理由写死）**：`W43_VERIFYALL_RC=0`、`结论：✅ 全部通过`、`用例通过 871 跳过 2`（日志 `$HOME/w43-verifyall.log`）。
⚠️ **为什么只一趟**：本波**位移 = 空** —— `inputs_fp` 与九位**逐位未变**（上面那格已机器证明）⇒
**`#40` 的 post-freeze ×2 复核的正是同一份代码状态**，所以"两趟"这件事已经由那两趟承担；
本趟的作用是**在文档/仪器改完之后**再整体过一遍 25 步（含 `SIGPIPE`/`QUOTE-TRAP` 等会被"新增 `.sh`"影响的普查）。
**这一句不许当成"省略了两趟"的借口**：若将来本波动了任何一位或覆盖面成员，**必须**回到 ×2 ＋ 静树窗口。

### ⑤ 自伤（如实记，三条都在仪器侧）

1. 新工具第一版 `DISPLAY=x "${ARR[@]}" cmd` —— 那个**数组展开不是赋值前缀**（被当成命令名）⇒ `rc=127 未找到命令`、日志只有一行错；
   **好在本件的三态设计把它变成 `NOINFO` 而不是假绿**（这正是不许二态的理由）。
2. **最小复现（本仓在册"双引号里的引号"家族的新形态）**：
   `echo "prefix（$(DISPLAY="$D" cmd)）suffix"` ⇒ **`bash -n` 报未闭合引号**；两种合法写法 = 先把命令替换算进变量、或整条右值 `VAR="$(DISPLAY="$D" cmd)"`。
3. `n_exc="$(grep -c … || echo 0)"` 在**命中 0 次**时打两行（`grep -c` 印 `0` 且 rc=1 ⇒ 又补一个）⇒ `[ … -gt 0 ]` 报"需要整数表达式"；改用 `awk` 数。

### ⑥ 未做（写清楚，留给下一波）

1. **"透参"产品修**（本波**只立判据、不动产品**）：代价账见 §3-II；
2. `D-G47` 的**潜在真缺陷定性**（在 Release 件上打开那条断言诊断跑 hc）；
3. `build/PresentationCore.Linux/*.cs` 纳入 `inputs_fp` 覆盖面（**须独立准备趟**，且要在 `IN_FP_0` 之前）；
4. 无 DISPLAY 档的"最后一跳可诊断"（`D-G47` 同族）；
5. `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 里那句 `#42` 描述**刻意不改**（其 sha16 是**冻结声明** ⇒ 改它会把 `BASELINE-SHA` 打红；更正写在 `CURRENT-STATE` 与 `KNOWN-DEFECTS`）。
