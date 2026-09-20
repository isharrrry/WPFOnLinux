# U1 · 真实 WPF 命令流 golden binary 比对 —— 规格与现状

> 状态：**✅ 已闭环（2026-09-10）**。本文件保留为"抓流 + 比对"的规格与操作手册；
> 实际执行结果见 `docs/U1-windows-probe.md`（附录 A）与 handoff 的「U1a / U1b」两节。

## 0. 闭环结论（2026-09-10，实测）

| 项 | 结果 |
|---|---|
| **U1a 真机像素对照** | 15 场景 / 110 探针**全中**；全图差异 1.104%，其中**仅 0.012% 不在真机边缘 1px 内**。过程中抓到并修掉一个真 bug（`SkiaBrush.MappingMatrix` 的 `Concat` 参数写反 → 所有 `RelativeToBoundingBox` 渐变失效）；**债务 #8 销账**（`Exclude = A−B` 真机判定） |
| **U1b 命令流抓取** | 代理 `wpfgfx_cor3.dll`（**208,384 B**，真身 106 导出**全在**）——因 Windows 侧 360 杀毒封 `zig.exe`，改为**在 Linux 用 zig 交叉编译 PE**；app-local 不生效 → 用 `SetDllImportResolver` 重定向。抓到 **op5 = 641 条**（托管 hook 拿不到的那一项） |
| 回放门禁 | **逐字节原样流 552 通过 / 0 失败**（`tests/U1-golden/u1b-scenes-rtb-raw.stream`）；`GoldenBinaryReplayTests` 从 Skip 转为**实测** |
| 关键修法 | 原样流最初 FAIL（51 × `E_HANDLE`）——归因**不是解码器缺陷**，而是回放器的资源生命周期模型：原生把删除**推迟到批次下发后**。**主控给回放器实现"延迟释放"**（release 只标记 → Commit 之后 + 流末尾才摘除）⇒ **不再需要任何数据侧改动** |
| 仍缺 | ch2 有跨通道句柄引用（29 创建 / 31 释放），未入 golden；文本/位图/效果/3D/动画未覆盖（`scenes.json` 的 `notCovered`） |

> 下面 §1–§6 是当初的规格与操作手册，保留供复现与后续扩展（例如把 `notCovered` 的场景补上）。

## 1. 为什么是"全工程最大的未验证风险"

命令解码（110/118 命令、103 个线格结构体）的正确性目前只建立在：
1. 读上游源码（`Generated/wgx_commands.cs` 的 `FieldOffset`）；
2. `verify-cmd-layout.py` 与上游逐 `FieldOffset` 机械比对；
3. 自编 round-trip 测试（构造→编码→解码→断言，编解码同源，有假绿灯风险）。

**没有真实 WPF 进程产生的命令流兜底。** 上游任何一处我们读漏的布局细节（对齐、填充、
枚举宽度），round-trip 都测不出来。真机抓流 = 用真实流量对解码器做黑盒验收。

## 2. Windows 侧 recorder 规格

### 2.1 抓流点（唯一侵入点 = handoff 决策 3 的 `Common/Graphics/exports.cs`）

在 Windows 机器上检出 dotnet/wpf 源码，只改 `exports.cs`（13 个导出函数的实现处）：
在 `MilChannel_BeginCommand` / `MilChannel_AppendCommandData` / `MilChannel_EndCommand` /
`MilConnection_CommitChannel` / `MilResource_CreateOrAddRefOnChannel` /
`MilResource_ReleaseOnChannel` 六个函数入口追加写日志（用 `std::fstream` 追加写二进制，
文件名取自环境变量 `WPF_STREAM_LOG`，未设则不写——**零行为改变**）。

### 2.2 运行载体

`samples/HelloWpf`（与 Linux 侧同源的最小 WPF 程序，App.xaml + MainWindow.xaml），
以及一个覆盖更多命令的小场景：渐变、圆角矩形、椭圆、路径、虚线、文本、位图（ImageSource）、
裁剪、嵌套变换、Blur/DropShadow。**一次完整运行（窗口出现后按任意键退出）抓一帧的
完整命令流**：从 CreateChannel 到 CommitChannel 为止。

### 2.3 落盘格式（版本 1）

```
魔数   8 字节  "WPFST\001"（0x57 0x50 0x46 0x53 0x54 0x01）
记录   重复到 EOF，每条：
  u8   op        1=BeginCommand   2=AppendCommandData  3=EndCommand
                 4=CommitChannel  5=CreateOrAddRefOnChannel(type u32, handle u32 已回填)
                 6=ReleaseOnChannel(handle u32)
  u32  cbSize    后续载荷字节数
  u8[] payload   载荷（BeginCommand = 命令头+定长体；Append = 变长续写；其余为空/参数）
```

- 头字节序一律 little-endian（与 DUCE 字节流一致）。
- 一个 `.stream` 文件 = 一次进程运行 = 一条通道的完整生命周期。
- 抓多个程序/场景 → 多个 `.stream`，文件名自解释（如 `hellowpf-aero.stream`）。

## 3. Linux 侧比对器（已落位）

`tests/WpfGfx.Linux.Tests/Commands.Tests/GoldenBinaryReplayTests.cs`：

1. 发现期扫描 `tests/U1-golden/*.stream`；**无文件 → Skip**（理由写明怎么抓流）。
2. 有文件 → 逐条回放：`new MilChannel(null)` + `MilCommandDispatcher` →
   `BeginCommand/AppendCommandData/EndCommand/CommitChannel` 按序喂入，CreateOrAddRef /
   Release 走 `MilNative` 对应导出。
3. 断言（黑盒验收口径）：
   - `channel.FailedCommands == 0` —— 真实流量里没有任何一条命令被解码器拒绝；
   - `channel.NotImplRegistry` 的所有键 ⊆ 文档化的 7 条 E_NOTIMPL（`docs/unimplemented.md`），
     且每条的拒绝次数打印留痕；
   - `channel.CommittedCommands > 0` 且 ≥ 流里命令条数；
   - CreateOrAddRef 的 handle 回填与后续命令携带的 handle 自洽（句柄在流内闭合）。
4. 输出每条命令的解码摘要（命令字、句柄、字节数）供人工抽查。

> 注意：本比对验证"解码不炸、语义不拒"，**不是**像素级 golden（那是渲染层的事）。
> 像素级需要录视觉树快照，属后续增强，不在 U1 范围。

## 4. 操作步骤（Windows 机器上，预计 1 天内完成）

```powershell
git clone https://github.com/dotnet/wpf          # 任意近 main 的 commit
# 按 §2.1 改 exports.cs（六处追加 WPF_STREAM_LOG 日志）
set WPF_STREAM_LOG=C:\u1\hellowpf.stream
# 用仓库自带脚本构建 WPF 并跑 HelloWpf（构建方法见 wpf 仓库 README / build.cmd）
# 跑完把 .stream 拷回 Linux 机器：tests/U1-golden/
```

回到 Linux 机器：`dotnet test Commands.Tests` → `GoldenBinaryReplayTests` 自动实测。
**抓流日志仅含命令字节，不含像素/无隐私内容，可直接进仓库。**

## 5. 解除 blocked 的条件

- [ ] 一台能构建 dotnet/wpf 的 Windows 机器（或 Windows 容器）；
- [ ] 按 §2 抓 ≥ 2 个场景的 `.stream`（覆盖渐变/路径/虚线/文本/位图/裁剪/变换/效果）；
- [ ] Linux 侧 `GoldenBinaryReplayTests` 全绿（FailedCommands==0、NotImpl ⊆ 7 条文档清单）。

## 6. 相关文件

| 文件 | 角色 |
|---|---|
| `tests/U1-golden/` | 流文件存放目录（本快照为空 → 比对器 Skip） |
| `tests/.../Commands.Tests/GoldenBinaryReplayTests.cs` | Linux 侧回放比对器 |
| `docs/unimplemented.md` | 7 条 E_NOTIMPL 文档清单（比对器的允许拒绝集合） |
| `src/WpfGfx.Linux/Interop/MilNative.cs` | 13 个导出（回放走同一入口） |
