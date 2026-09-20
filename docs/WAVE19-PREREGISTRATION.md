# WAVE19 预登记（`#19` 波）—— **`P4` 注释 + 严格档的 indent 缺口**（两件都动**时代绑定**的 shim）

日期：2026-09-16（主控）。被 `#18` 冻结为基线：九位见 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `#18` 表头（`0d0f1134d34c5ef8`）。

## 0. 本波与 `#17`/`#18` 的**关键差别：会换世代**

两件都要改 **`build/shims/PresentationCore.HbTextLine.cs`** —— 而它**正是在册红门禁世代绑定的三项之一**（已核 `tline-gate.sh:137` 的 `SH_SHIM` 只绑这一个文件）。
⇒ **本波必须付那笔成本**：**重取五臂 + 重钉 `known-red.json`（`generation.id` `#16` → `#19`）**，且**门禁的 `tree_gen` 在重取之前必然是 `advanced`（这是设计，不是缺陷）**。

## 0.0 ⚠️ 修订 **v2**（2026-09-16 15:3x，主控）—— 车道 W19A 的落地带出**一条口径更正 + 两条牙齿/仪器留档**

报告：`build/MilBridge/W19A-report.md`（**`699cc39187268297`**，517 行）。**v1 原文保留**，更正如下：

| # | v1 写的 | 实测/更正 | 处置 |
|---|---|---|---|
| **F1** | §1 A 的判据写成"`shim` 的 sha 变、`pc` 因重建而变；**所有判据读数逐位不变**"，并引 `#16`/`#17` 的"注释不进元数据" | **那两句是两个层面的事，必须拆开写**：`#16` 的 P1 把 **shim 整文件的内容 sha** 编进了 `AssemblyMetadata`（`HbTextLineShimSha.targets:58`）⇒ **改一句注释就会改 `pc` 的字节**（W19A 实测：**同 obj 路径、只差一句注释**，私生 pc `32533cae` → `4fb7baad`）。"注释不进元数据"说的是**标识符/字面量**层面（`#Strings`/`#US` 里找不到注释），**不是**"注释不影响产物字节" | **口径（立即生效）**：本波 A 的判据拆成两层 —— **① 行为读数逐位不变**（应用门禁 `drawn/colors/frames`、五臂、`tline` 六项）；**② 产物 sha **一定**变**（因为 P1 注入了整文件 sha）。⇒ **"`pc` sha 变了"不许读成"行为被改了"**；反之 `ShimShaReader` 报"与产物一致（`no`）"才对。**这条对所有后续波都适用**，已写进 `#18` 表头之上的"在飞"横幅 |
| **F2** | （未预见）应用器里 P2 的**来源计数牙齿**要求 `1/1` | 本件加了严格档调用点后**必然变 `2/2`** ⇒ 那条牙齿**当场 `rc=1` 拦下了 W19A**（**它是对的**） | W19A **按设计改口径为 `(1,1,2,2)` 并写明理由，没有删牙齿** ⇒ 采纳（**判据只许变强**：口径放宽的是"几处"，但每一处仍要求存在） |
| **F3** | （未预见）W19A **自己的牙齿连错三版**：v1 **恒绿假牙齿**、v2/v3 **假红**（一次因宽松档结尾逐字相同、一次因 `LineHeight,` 实际 1 处不是 2）；另有一处**仪器事故**（注错失败却继续跑 ⇒ **陈旧突变被当结果**）；两次作废的负控尝试（`nc2`/`nc3`：`PcPath` 手法不可靠、手工 Copy 的 provider 不在 `deps.json`） | **都留在报告里，并明确"别拿它们的输出当证据"** | **采纳为纪律形态**：牙齿写完**必须做两极化实测**（不注错 `rc=0` / 注错 `rc=1`），且**注错失败要停**，不许把上一次的产物当本次结果 |

**另记一条与主控下一步直接相关的现场事实（**预测已成立**）**：shim 一改，门禁**逐字**变成
`TLINE_GATE=NOINFO arms=5 red=1 green=0 noinfo_arm=4 registered=3 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#16 tree_gen=advanced saved_shim=fe1b7ed8fa3ed231`、`GATE_REASON=noinfo-arms`、**`rc=2`**
（`$HOME/wfp-runs/w19-pre/gate-before-retake`）⇒ 与本文件 §1「世代与登记表」那条**逐字一致**（**设计，不是缺陷**）。**重取五臂 + 重钉表之前，第 10 步必然 `NOINFO`。**

## 0.1 两件的内容（**代码事实已现场重读，非凭记忆**）

### A · `P4`：`HasOverflowed` 上方的文档注释仍写"本实现恒 false"
- `#16` 的 `D-O1` 已把它改成**三分支真实现**，而它**上方那段文档注释没改**（`D-O1` 落地时顺手更正过 `_startPenX` 的注释，这一处漏了）⇒ **注释与实现相反**。
- **改什么**：**只改注释文字**，不许夹带任何语义改动。

### B · 严格档（`HbTextFallback.TryFormatLine`）的 **indent 缺口**
- **现状（现场逐行读的）**：shim `HbTextFallback.TryFormatLine` 声明在 **`:4496-4497`**：
  `internal static TextLine TryFormatLine(TextSource textSource, int cpFirst, double paragraphWidth, double pixelsPerDip, bool alwaysCollapsible, double lineHeight)`
  ⇒ **形参表里根本没有 indent**；函数体内转发到 `HbTextLineFactory.FormatParagraph(text, primaryRun.FontPath, emSize, paragraphWidth, primaryRun.Typeface, …, plan, faces, runProps)` —— **那个重载也不收 indent** ⇒ **`Indent` 与 `ParagraphIndent` 在这条路径上被整条丢掉**。
- **它在 PC 里先于宽松档被调用**（生成物 `:565`-`:572`，实参只有 `textSource/firstCharIndex/paragraphWidth/PixelsPerDip/AlwaysCollapsible/LineHeight`），宽松档在它**返回 null 之后**才试（`:575` 那条，`#17` 的 P2 修的就是**那一条**）。
  ⇒ **`#17` 的 P2 只修好了"兜底那一层"；默认配置下真正先接手的这一层仍然是丢的。**
- **改什么（与 P2 同一口径，**不要**重犯 ×300）**：给 `HbTextFallback.TryFormatLine` 加 `double indentDip = 0, double paragraphIndentDip = 0`，转发给 `FormatParagraph` 的 `indentDip:`/`paragraphIndentDip:` 槽；PC 侧调用点（生成物 `:565`，由应用器改）传 **`paragraphProperties.Indent` / `paragraphProperties.ParagraphIndent`（原始 DIP）** —— **绝不许**传 `settings.Pap.Indent`/`settings.Pap.ParagraphIndent`（那是**理想整数 ×300**，见 `WAVE17` §0.0 的 F2）。
- **⚠️ 兼容性**：新形参必须有**默认值**（`= 0`），使**既有调用点零改动也逐位等价**；这是"射程外不动"的前提。

## 1. 逐件判据

> 通用：① 每件落完**各自取一次读数**；② 改会被编进产物的源 ⇒ **落地判据必须含 `dotnet build … error CS = 0`**（纪律 33）；③ **射程外读数逐位不动**；④ **不许**用放宽/吞异常达成"不绿"。

### A 的判据（**"注释不改行为"的机器断言**）
- `shim` 的 sha **变**、`pc` 因重建而变；
- **所有判据读数逐位不变**（依据 = `#17` 的实测：**注释不进元数据** —— 纯注释短语与局部变量名在 DLL 里**处处 0 命中**）；
- ⇒ **若 `tline`/三支 tab 臂有任何读数位移 ⇒ 停**（说明位移来自别处，或注释改动夹带了语义）。

### B 的判据（**红证必须用"严格档腿"实测**）
- **红证（先修前、后修后）**：现有臂 `build/MilBridge/tests/PcLineOracle/**` 的**层级由 `WPF_LINUX_TEXTLINE_FALLBACK` 决定**（**两条腿只差 `AlwaysCollapsible`，不是层级**）⇒ **把那个 env 去掉**（默认 ⇒ **先走严格档**）就是严格档腿。**同一命令、除 env 外一字不改**：
  - **修前必须红**：非 0 缩进例应出现与 `#17` P2 修前**同形的缺口**（`Indent`/`PI` 被丢 ⇒ 网格锚与内容起点都少 indent）；
  - **修后必须绿**：非 0 缩进 `红=0`、零缩进同层对照**逐位不动**；
  - **层级来源必须自证**（否则"红"可能来自别的层）：臂要同时印**严格档**的 `Handled/Bailed` 与**宽松档**的 `Diagnostics`（后者经 IVT 读）⇒ **判据 = 本腿的接管计数来自严格档**。
- **位移预测**：应用门禁 **6/6 `result=PASS` 且 `drawn/colors/frames/cross_ae/leftover_after` 逐位不变**（前提：`samples/**` 对 `Indent`/`ParagraphIndent` **全 0 命中** —— 已在 `#17` 实测过，本波须**复读一次**）；**其余七支臂 / `tline` 六项逐位不变**。
- **"红则停"**：修前严格档腿**不红** ⇒ 说明这条路径对我来说**不可观测**（或它根本没接手）⇒ **停、撤回该结论**，不许改成"已修"。

### 世代与登记表（**本波特有，不许省**）
- shim 一变 ⇒ **五项**：① 重建 pc；② **重取五臂**（`ln -f` 硬链接，绝不 `cp`）；③ 逐条裁定位移（登记表的 `drift`/`gone`）；④ **重钉 `known-red.json`** 到 `generation.id=#19`（`changelog` 写明**为什么**重钉）；⑤ 门禁**两极化重做**（删 1 条 ⇒ `rc=1`；恢复 ⇒ `rc=0`）。
- **门禁在重取之前的形态**：`tree_gen=advanced` + 弱配对四臂 `caliber=UNVERIFIABLE` + `rc=2`（**这是设计**，不是缺陷 —— 纪律 31 的现场）。

## 2. 本波**不做**的
- **不碰** `bridge` 相关（`src/WpfGfx.Linux/**` 本波不动 ⇒ 预期**桥不重发**）；
- **不修** `D-T5`/`D-T4`/`D-T2-c`/`D-F2`/`D-E1`（只登记）；
- **不接**任何新判据进 `verify-all.sh`；
- **不许**为了让门禁变绿而放宽口径。

## 3. 波形态
1. 两件落地（A 只改注释；B 加默认形参 + 转发 + PC 调用点）。
2. `close-wave.sh`（预期 `native_rebuilt=0`、**`bridge_republished=0`**）。
3. **重取五臂**（`PcLineOracle` 的层级腿不是门禁臂，不进 `arm-logs/`；要重取的是 `tline`/`tab-zero`/`tab-anchor`/`tab-rtl`/`textlineproto`）。
4. **重钉登记表** → **两极化**。
5. 应用门禁两趟（常驻 `:97`，第 2 趟带 `WPTD_BASELINE_OUT`）⇒ 与 `#18` **逐位对照**。
6. `verify-all`（10 步）。
7. 等号读者（应仍 `SHIM_SHA=no`；**注意**：shim 内容变了 ⇒ 读者会报 `no` 说明**产物与源一致**，这正说明 P1 的机制跟着重建走）。
8. 重冻 `#19` + 文档收尾。

## 4. 先决条件
1. 静树；2. **常驻 `Xvfb :97` 必须在**（不在就先起 —— `#17` 我在这上面踩过一次）；3. 写域先宣告；4. 开工前**现场重读**所有 `:NNNN` 锚点（行号会漂）。

## 5. 本预登记自己的口径
- 读数 = **件 sha + 仪器 sha + 判据口径 + artifact/字段名**；红检测只许加强；缺数据 ⇒ `NOINFO` 不许报绿；非 0 退出码先分类（`127`/`MSB1009`/`rc=134` = 装置/命令问题）。
- 与 `WAVE18-PREREGISTRATION.md` 冲突时**以本文件为准**。

## 8. `#19` 收官（2026-09-16 15:5x，主控）

### 8.1 两件落地
**A（`P4`）**：`HasOverflowed` 上方那段过时注释拆成两个命题（**语料分布 ≠ 取值域**）并对上 `D-O1` 的三分支；**零代码改动**经"剔 `///` 行后 `diff` 为空"机器证过。**B（严格档 indent）**：`HbTextFallback.TryFormatLine` 加**带默认值**的 `indentDip`/`paragraphIndentDip`（既有调用点**逐位等价**，两重证据：工厂内 5 处用法全是加法/直接赋值；元数据实测私生 pc 读回 **8 形参 `optional=True default=0`**、权威修前 pc 读回 **6 形参无缩进形参**（负控））＋ PC 严格档调用点（生成物 `:565`）传 **`paragraphProperties.Indent`/`.ParagraphIndent`（原始 DIP）**。
件：shim **`fe1b7ed8fa3ed231`**（275,765 → 278,692 B）｜应用器 **`daa1fe2a32d454cf`** ⇒ 生成物 **`799e0366b312ec65`**（只 1 处 hunk）｜臂 **`a46e5e046583f69a`**（加 `--tier auto|strict|lenient` + 档位感知正控 + 逐例层级归因）。

### 8.2 波（两段式）与九位
`close-wave.sh --skip-verify-all`（`15:41:17`）：**`native_rebuilt=0`、`bridge_republished=0`**（**桥未重发，与预测一致**）、输入稳定 `288447d98d255f4c56ce04300a6fbe7977a62940e45f78617cd1d44873668d39`。**新九位**：`bridge d567c26f197ec1e3`｜**`pc f4a454c8fe69cdfe`**｜**`pf bd4e28e6a6f8b0e5`**｜`windowsbase 1114a28ec5a03ab7`｜`provider 9aa0d744802aaa31`｜`win32shim 0098234982391bbf`｜`wic_shim 03b67fbcd7c385b6`｜**`hbtextline fe1b7ed8fa3ed231`**｜`dwf 0ed422ef2dd46445`。**相对 `#18` 只动三位**（`hbtextline`/`pc`/`pf`）。

### 8.3 世代成本（本波特有，必须付）
① **五臂重取**：四支**逐字节不变**（`tab-zero`/`tab-anchor`/`tab-rtl`/`textlineproto`）⇒ 两件未进其射程；`tline` `89ad10ac614b4d3b → aa7259da9e2c77e8`（+54 B）**30 行差全是身份/管道**、**判据行逐字节相同** ⇒ 四条在册读数逐条复现。② **登记表重钉** `f9843bde351029dc → 3bf26e12f320dece`（rev 8、`generation.id=#19`、entries 仍 4、数值一字未改）。③ **门禁** `TLINE_GATE=PASS … generation=#19 tree_gen=same … drift=0 gone=0 unregistered=0`、`rc=0`；**两极化**：删 `T3b` ⇒ `rc=1`；真表 ⇒ `rc=0`。**重钉前门禁的形态已事先写死并实测吻合**：`NOINFO … tree_gen=advanced … rc=2`。

### 8.4 预测 vs 实测
| 预测 | 实测 | 判 |
|---|---|---|
| **A 的行为读数逐位不变** | 应用门禁两趟 6/6 `PASS`、`drawn=260/144`、`colors=3960/2828`、`frames=14/14`、`cross_ae=0`、`leftover_after=0` **与 `#18` 全部相同** | ✅ |
| **B 的射程外逐位不动** | 零缩进桶 `63/41` 与修前**逐位相同**（E4）；四支臂逐字节不变 | ✅ |
| **B 修后非0缩进桶"红=0"** | **⚠️ 我写错了目标**：实测 `红=127 绿=57`；但按失配词核 ⇒ `结构=FAIL` 116 条**全是 `@tab0`**、**非 tab0 结构失败 = 0**，残留 67 条非 tab0 **位置**红是同一族的另一族（`行#1 i=0 取不到字符边界`） | **判据改写**：按桶 + 按失配词读；E1 原目标作废 |
| **B 的判别例** | **E2 ✅**（tab 网格锚 `0 → 24.000000`、Δ=0.000000）、**E3 ✅**（宽 `26.695312 → 50.695312` Δ=+0.001979） | ✅ |
| **孪生恒等式（缺陷态签名）必须破裂** | 违反 `0 → 75`、最大差 `0.0020 → 24.0020` | ✅ |
| **`bridge` 不重发** | `bridge_republished=0`、`bridge` 值未变 | ✅ |
| **`pc`/`shim` 变（且 P1 的整文件 sha 会跟着变）** | `pc f4a454c8fe69cdfe`、等号读者 `no`（`product==tree==fe1b7ed8fa3ed231`，`cmp=full64`） | ✅（并产出 ③ 那条新口径） |
| **`D-R6` 类：跨 obj 路径 sha 不可比** | 车道再次自报（私有件 sha 只在同 obj 路径下可对拍） | ✅（一致） |

### 8.5 可复现性与其余读数
`verify-all` **rc=0 / 10 步 / 871 通过 2 跳过 / 第 10 步 ✅**；应用门禁两趟都在**常驻 `:97`**（复用分支）；等号读者 `no`；T17A 工具 `PASS`（**只证下界**）。**P1 的构建溯源**被当判据用：`product_sha16 == tree_sha16 == fe1b7ed8fa3ed231`。

### 8.6 本波**没能**收掉的（不许当绿）
① **`D-T6`**（`行#1 i=0 取不到字符边界`，67 非 tab0 + 54 tab0 位置红）**机制未归因** —— 严格档腿唯一残留的非 tab0 红；② **严格档腿修后 `rc` 仍为 1** ⇒ **不许**拿整腿 `rc` 读成"B 没修好"，也**不许**拿"整腿绿"当目标；③ **`D-R8`**（`TextLineProto`/`HbTextLineParity` 缺 `EnableDefaultCompileItems=false` ⇒ 私有 obj 重定向下 `16×CS0579`）**只登记未修**；④ `D-R3` 残项（真宿主可达性、AOT 镜像内 `X11Native` 静态构造）未测；⑤ `D-T5`/`D-T4`/`D-T2-c`/`D-F2`/`D-E1`/`D-A1`~`D-A3`/`D-F1c`①c/`D-F3`/`7CJK candidates=45`/MIL 侧三计数：未动或未取到读数；⑥ 新判据仍未接进 `verify-all.sh`。

### 8.7 下一波候选
① **`D-T6` 定性**（严格档腿唯一残留的非 tab0 红；线索 = 跨档差异 + 严格档自己的 `ParaCache`；**判据 = 先分成"臂/装置"还是"产品"**）；② **`D-R8`**（两个 csproj 的 `EnableDefaultCompileItems=false`，小、干净、有两极化可做）；③ `D-R3` 残项（真宿主可达性 / AOT 内 `X11Native`）。
