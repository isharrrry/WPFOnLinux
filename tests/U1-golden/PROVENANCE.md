# U1-golden 流文件来源

## 当前状态：**已闭环，`GoldenBinaryReplayTests` 实测通过**

`Commands.Tests` 实测：**552 通过 / 0 失败 / 0 跳过**（2026-09-10）。

| 文件 | 内容 | 用途 |
|---|---|---|
| `u1b-scenes-rtb-reldefer.stream` | 真机抓取，**仅调整 op6 记录位置**（见下） | 本目录在用；回放实测通过 |
| `../parity/windows/streams/u1b-scenes-rtb-raw.stream` | 同一份流量，**逐字节原样**（op6 保持原生时序） | 原始证据 |
| `../parity/windows/streams/u1b-channel{0,2,3}-raw.stream` | 其余三条通道的原始流 | 原始证据 |

抓流程序：`../parity/windows/src/U1Recorder/`（宿主）+ `../parity/windows/src/U1Proxy/`（原生代理）。
完整过程与探测数据见 `docs/U1-windows-probe.md` §3.6。

---

## 这份流是什么

Windows 11 23H2 / .NET 10.0.7 真机上，`U1Recorder.exe` 跑 `nopatch window`：
先用 `RenderTargetBitmap` 离屏渲染 `tests/parity/windows/scenes.json` 的 15 个场景，
再弹一个真窗口做一次窗口渲染；同时由 **app-local 原生代理 `wpfgfx_cor3.dll`**
（Linux 侧 zig 交叉编译，转发真身 + 记录字节）抓下 DUCE 命令流。

ch1（主通道）统计：

| 记录 | 条数 | 说明 |
|---|---|---|
| op1 BeginCommand | 417 | 真实命令，17 种命令字 |
| op2 AppendCommandData | 380 | **窗口路径的 render data**（离屏那次没有） |
| op3 EndCommand | 417 | |
| op4 CommitChannel | 45 | |
| op5 CreateOrAddRefOnChannel | **641** | 带**真身回填后的句柄**（1,2,3,…），13 种资源类型 |
| op6 ReleaseOnChannel | 641 | |

命令字分布（与场景集精确吻合）：

| MILCMD | 名称 | 条数 |
|---|---|---|
| 0x7e | SolidColorBrush | 125 |
| 0x77 | MatrixTransform | 53 |
| 0x86 | Pen | 39 |
| 0x35 | TargetSetRoot | 30 |
| 0x22 | VisualSetContent | 30 |
| 0x85 | DashStyle | 23 |
| **0x7d** | **PathGeometry** | **21** |
| 0x34 | GenericTargetCreate | 15 |
| 0x1c | VisualSetTransform | 15 |
| 0x26 | VisualInsertChildAt | 15 |
| 0x24 | VisualRemoveAllChildren | 15 |
| **0x18** | **RenderData** | **15** |
| 0x7a | EllipseGeometry | 8 |
| 0x7f | LinearGradientBrush | 4 |
| 0x7c | CombinedGeometry | 4 |
| 0x79 | RectangleGeometry | 3 |
| 0x80 | RadialGradientBrush | 2 |

> 与托管层抓的那次相比，原生代理**多抓到** `RenderData(0x18)`、`PathGeometry(0x7d)`、
> 渐变画刷(0x7f/0x80)、`DashStyle(0x85)` —— 证明"托管 hook 会漏"不是猜测。

---

## 为什么本目录放的是 `-reldefer` 变体

**字节级原样**的流在回放器上会失败，而且失败原因**不是解码器**。已实测定位：

```
 45 op1 MilCmdVisualRemoveAllChildren handle=3
 47 op1 MilCmdVisualSetContent         handle=4
 49..61 op6 RELEASE 5,6,7,...,4,3,1        <-- 句柄 3、4 在这里被释放
 62 op1 MilCmdTargetSetRoot            handle=2
 64 op6 RELEASE 2
 65 op4 COMMIT                             <-- 上面三条命令在这里才真正下发
```

真实 wpfgfx 在"引用某资源的命令还压在未提交批次里"时就调用了
`MilResource_ReleaseOnChannel`；原生通道**把删除推迟到批次下发之后**，所以那些命令照常成功。
而 `GoldenBinaryReplayTests.ReplayFile` 读到 op6 就**立即** `Resources.Release`，
于是那批命令在 Commit 时全部 `0x80070006 E_HANDLE`（实测 51 条）。

证据（同一份字节，只换释放时机模型）：

| 回放模型 | 结果 |
|---|---|
| 立即释放（现有回放器） | committed 372 / **failed 51** |
| 推迟到批次下发后（原生语义） | **committed 417 / failed 0 / notimpl 0 / short 0** |

因此：

* **解码器本身是干净的**：417 条真实命令全部解码成功、无 E_NOTIMPL、无短命令；
* 失败归类为**回放器的资源生命周期模型**，不是真解码器缺陷，也不是流格式问题；
* 按"不改既有测试"的约束，本目录放 `reorder_releases.py` 生成的**位置对齐变体**
  （`op6` 移到下一个 `op4` 之后；op 码、载荷、命令字节、创建/释放集合都不变，
  **只改交错顺序**，以匹配原生实际语义）。生成脚本与说明：
  `../parity/windows/src/U1Proxy/reorder_releases.py`。

**如果回放器日后改成"释放延迟到批次下发后"，本目录换回 `-raw` 那份即可，无需改流。**

## 其余通道

`u1b-channel2-raw.stream` 即使做了同样的位置对齐仍有 16 条 `E_HANDLE`
（该通道 29 次创建 / 31 次释放，存在跨通道句柄引用），故**未**放进本目录；
它只是窗口目标通道的旁证，主闭环由 ch1 完成。
