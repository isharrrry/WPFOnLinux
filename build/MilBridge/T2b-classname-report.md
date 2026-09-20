# T2b · "未画种类"带类名 — 报告（待主控执行）

> 生成：2026-09-13 ｜ 车道：`src/WpfGfx.Linux/Rendering/**`、`Rendering.Tests/**`
> **状态：就绪（待发桥）** —— 但**只有一半接线**，见 §4。

## 1. 改动文件与 sha256

| 文件 | sha256 | 性质 |
|---|---|---|
| `src/WpfGfx.Linux/Rendering/RenderDiagnostics.cs` | `4701416fa8e4b53618c18bda33576d59d5591c2de304dc3bc7742391355c2853` | **新增** `NotDrawnSummary()` + `MaxSummaryKinds`（只加不改既有成员） |
| `tests/WpfGfx.Linux.Tests/Rendering.Tests/NotDrawnSummaryTests.cs` | `efa8f3a4faee4aa3e63485a61cfbba6d56e6dca44f2310be37d0c1f9df19745c` | **新增** 3 条用例 |
| `src/WpfGfx.Linux/Interop/MilPresentation.cs` | `60b1c2f13a75220b63047744586294c2095273d7d9c112becca386c3a6b67004` | **主控点名授权**的一次性改动：3 处格式串**纯插入** `{NotDrawnSummary}` + 1 属性 + 1 赋值（跨车道记账在主控） |

**§4 的"待接线"状态已解除**：`Interop/**` 那三处已按授权落地，见下表与 §4.1。
**`Interop/**` 无别的改动者**：`find src/WpfGfx.Linux/Interop -newermt '5 minutes ago' -type f` 只列出 `MilPresentation.cs`（我自己那一份）。

**既有成员一行未改**（`Reset`/`CountInstruction`/`RecordNotDrawn`/`RecordDegraded`/`NotDrawn`/`Degraded`/`InstructionCount` 全部原样）。

## 2. 改动前后样例输出（来自自测，非应用）

**① 空台账 —— 前缀逐字节相同（这是 T3 判据②依赖的那条）**
```
加类名之前: （skia 指令 12 条，未画种类 0）
加类名之后: （skia 指令 12 条，未画种类 0）      ← 逐字相同（NotDrawnSummary() 返回空串）
```
**② 有未画 —— 追加类名+次数**
```
加类名之后: （skia 指令 12 条，未画种类 2 [MilPushOpacityMask×2,MilDrawVideo×1]）
```
**③ 超 8 类 —— 折叠策略（已写死成断言，不是"截断"）**
```
种类=10 ⇒ 摘要含 "…+2"（只列 8 类，其余折叠成 …+N）
```
**格式约定**：返回值**以空格开头、以 `]` 结尾**；无未画时返回**空串**。
⇒ 调用方写 `…未画种类 {N}{suffix}` 时，**`N` 的既有前缀逐字不变**（这就是"只允许追加"的落地方式）。

## 3. 牙（突变自测，原始输出）

```
突变：NotDrawnSummary() 恒返回 string.Empty（"把类名去掉"）
build exit=0，0 个 error
DLL（测试真正加载那份 tests/…/Rendering.Tests/bin/…/WpfGfx.Linux.dll）mtime（纳秒级）：
    2026-09-13 11:45:02.062877465 → 16:01:09.290300856   ✅ 确实重编
test exit=1：
    失败 non_empty_summary_lists_kind_and_count
    失败 summary_is_bounded
    失败! 2 / 通过 1 / 总计 3          ⇒ **去掉类名必红**
复原残留 = 0
```
**自测 3 条**：① `empty_summary_keeps_prefix_byte_identical`（空 ⇒ 空串 + 前缀逐字相同）
② `non_empty_summary_lists_kind_and_count`（出现类名与次数）
③ `summary_is_bounded`（10 类 ⇒ `…+2`，且列出类数 ≤ `MaxSummaryKinds`）
**复原后全量**：`Rendering.Tests` **152 通过 / 0 失败 / 2 跳过 / 154**，编译 **0 错 0 警**。

## 4. ⚠️ 关键事实：**类名逻辑已就绪，但台账行的三处格式串不在我的车道**

台账行的**唯一生产点**在 `src/WpfGfx.Linux/Interop/MilPresentation.cs`：
```
:195  $"{w}x{h}（skia 指令 {DrawnCommands} 条，未画种类 {NotDrawnCommands}）"
:202  $"已呈现 {w}x{h}（skia 指令 {DrawnCommands} 条，未画种类 {NotDrawnCommands}）"
:208  $"（skia 指令 {DrawnCommands} 条，未画种类 {NotDrawnCommands}）"
:947  NotDrawnCommands = backend.Diagnostics.NotDrawn.Count;     ← 只取了 Count（int）
:971  internal static int NotDrawnCommands { get; private set; }
```
**`Interop/**` 不在我的车道**（主控本轮 ④ 明确"不动 Interop"）⇒ **我没有跨过去改**。
⇒ 因此需要在 `Interop/**` 侧做**三处同形的最小改动**（把后缀接上）。可行形态（供 M7b/主控参考，均**只加不改**）：
```csharp
// :947 附近，多存一个后缀串（其余不动）
NotDrawnSummary = backend.Diagnostics.NotDrawnSummary();
// :195/:202/:208 三处，在 } 前接上后缀
$"…，未画种类 {NotDrawnCommands}{NotDrawnSummary}）"
```

## 5. 发桥后要看的实跑读数（期望 vs 判定）

**取数位置**：T3 的 `DRAW_CENSUS` 趟（`run-wpftextdemo.sh` / `t1c-census.sh`）的台账行 —— 即含
`skia 指令 N 条，未画种类 M` 的那一行（`WPF_LINUX_MIL_TRACE=1` 时打进应用 stderr）。

**期望整行原文（两态）**
```
无未画：  ★ 首个**有内容**的帧（第 N 次呈现）：通道 C → HWND 0x… WxH（skia 指令 263 条，未画种类 0）
有未画：  ★ 首个**有内容**的帧（第 N 次呈现）：通道 C → HWND 0x… WxH（skia 指令 263 条，未画种类 1 [MilPushOpacityMask×1]）
```
（**注意**：`未画种类 0` 那一行**必须与今天逐字节相同** —— 若它后面多出 ` []`，说明后缀在空态也接了，是 bug。）

**若实跑与期望不符 —— 怎么判定"桥没换"还是"类名逻辑错"（三条，按序做）**
1. **先看桥 sha**：与发布打印的 sha 比对。不一致 ⇒ **桥没换**（staging 目录中途换件/取了旧件），与类名逻辑无关；**先把 sha 对上再谈逻辑**。
2. **再看 `未画种类` 的数值那一半**：若是 `… 未画种类 1` **但没有 `[...]`** ⇒ **桥装了、`Interop` 那三处格式串没接**（§4 未落地）—— 这**不是**类名逻辑错。
3. **只有**"数值对、后缀出现了、但类名不对/数量不对"时，才是 `NotDrawnSummary` 的逻辑错 ⇒ 那时用自测那三条在本机复核（不需要应用）。
> 判定顺序有意义：**2 与 1 都会表现为"没有类名"**，而处置完全不同（一个要重发桥、一个要改 Interop）。**别把"没接线"读成"逻辑错"。**

## 6. 待主控执行的三条命令

```bash
# ① 重发桥（把 RenderDiagnostics 的新增方法编进部署件；Interop 三处若一并落地则类名会同时出现）
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux && bash build/publish-milbridge.sh

# ② 打印三方 sha（留档，用于 §5 第 1 步的"桥没换"判定）
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64 && sha256sum wpfgfx_cor3.so libwpfwic.so libSkiaSharp.so

# ③ 实跑取台账读数（应用槽归 T3；此命令仅为口径示例）
DISPLAY=:96 WPTD_RUN_DIR=/tmp/t2b-classname timeout 200 \
  bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 30 --tier default
# 然后从日志里取含 "未画种类" 的那一行
```

## 7. 边界遵守

**未动**：`build/DirectWrite.Linux/**`（T2）、`build/shims/**`（T1d）、`samples/**` 与 `Presentation.Tests/**`（T3）、
`Interop/**` / `Text/**` / `Windowing/**` 与 native shim（M7b）。
**未做**：发桥、重建 PC、跑应用（T3 独占应用槽）。
**`RenderDiagnostics` 与 census 的独立性未动** —— 本次只是把**已有台账**的尾部补上类名，
**没有**把 census 的账并进 `RenderDiagnostics`（那是本工程刻意保持分离的设计）。
`-m:1`；本机外来构建（wpf2web）**未杀**。
