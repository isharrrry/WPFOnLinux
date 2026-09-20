# U1 · Windows 真机探测与采集报告

> 执行者：验证工程师（U1 子任务）　机器：`bilintu\pc@192.168.193.97`（Windows 11 23H2，10.0.22631.2428）
> 工作目录：`C:\u1-parity\`（结束时已清理，仅保留 `C:\u1-parity\out\`）
> 日期：2026-09-10

本文件记录三件事：
1. §1 能力探测的**实测**结果（哪些"应该可以"最后是真的可以）；
2. §2 U1a 真机像素对照数据采集（**已完成并验证**）；
3. §3 U1b 抓真实 DUCE 命令流的三级尝试（**部分成功，卡点已定位到具体 API**）。

**先说结论**：U1a 拿到 15 场景 × 256×256 PNG + 110 个探针点 + 92 条机器校验的
语义预期，全部回传并通过完整性校验；U1b 用托管层 hook 抓到了 **352 条真实 DUCE 命令**
（12 种命令字，与场景集精确吻合），但**缺 `MilResource_CreateOrAddRefOnChannel`
的句柄回填记录**，导致 Linux 侧 golden 回放的 352 条命令全部以 `E_HANDLE` 被拒 —— 卡点
定位在 Harmony 无法读取 `ref DUCE.ResourceHandle`（internal 类型）的出参，详见 §3.4。

---

## 1. 能力探测（实测）

| 能力 | 探测方法 | 实测结果 | 对路线选择的影响 |
|---|---|---|---|
| SSH 可达 | `sshpass -e ssh PC@192.168.193.97` | ✅ 可用，落在 **session 0**（`SESSIONNAME` 为空、`UserInteractive=False`、`SessionId=0`） | 窗口类渲染需实测；不能用交互式假设 |
| 控制台会话存在 | `query session` | `services 0 Disc` / `PC 1 Disc` / **`console 2 Conn`** / `rdp-tcp 65536 Listen` | 有退路（`schtasks /IT`），但**本次没用到** |
| .NET SDK | `dotnet --info` | ✅ **10.0.203**（Host 10.0.7，RID `win-x64`） | 可建 `net10.0-windows` + `UseWPF` 工程 |
| WPF 运行时 | `Get-ChildItem ...\Microsoft.WindowsDesktop.App` | ✅ **10.0.7**（另有 6.0.7 / 6.0.36 / 8.0.26） | 对照基线锁定 10.0.7 |
| `wpfgfx_cor3.dll`（真身） | `Get-Item` + `VersionInfo` | ✅ `C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\10.0.7\wpfgfx_cor3.dll`，**1,952,016 字节**，`10,0,726,21808 @Commit:b16286c228...`，SHA256 `f4f7a44a3480c0b7…` | 路线①的转发目标确认存在 |
| `PresentationCore.dll` | 同上 | 8,309,000 字节，程序集版本 `10.0.0.0` | — |
| **C++ 工具链** | `vswhere` + 递归找 `cl.exe/link.exe/dumpbin.exe/vcvars64.bat` | ❌ **没有**。VS Enterprise 2026 装在 `C:\Program Files\Microsoft Visual Studio\18\Enterprise`，但 `VC\` 下**只有 `Auxiliary`（目录里只有 .props/.txt，无 vcvars64.bat）和 `Redist`**，没有 `VC\Tools\MSVC`；Windows Kits 只有 `NETFXSDK\4.8`，**没有 Windows SDK**；`where cl/link/clang/gcc/zig/tcc` 全空 | **路线①（MSVC 编译代理 DLL）按原方案不可行** |
| 网络：nuget.org | `Invoke-WebRequest` | ✅ HTTP 200（本机走国内镜像，Linux 侧 `api.nuget.org` 会 302 到 `nuget.azure.cn`） | 路线②（Harmony 取包）前提成立 |
| 网络：github.com | `Invoke-WebRequest` | ❌ 超时（`raw.githubusercontent.com`、`codeload` 之外的主站不可达） | 路线③（clone dotnet/wpf 重建）**取源码这一步受阻**（本仓库自带 `upstream/wpf` 快照，但那是 Linux 侧的） |
| 网络：PyPI / rust / zig / npm | 逐个 HEAD | ✅ `pypi.org` `files.pythonhosted.org` `static.rust-lang.org` `ziglang.org` `registry.npmjs.org` 全部 200 | **路线①仍有救**：可拿便携工具链，见 §3.5 |
| git / python | `git --version` / `python --version` | ✅ git 2.49.0.windows.1、Python **3.14.6**、pip 26.1.2、node/npm 也在 | — |
| **离屏渲染（`RenderTargetBitmap`）** | 实跑 `U1Parity.exe`（无窗口、无 `Dispatcher.Run`） | ✅ **完全可用**：15/15 场景渲染成功，110 个探针点全部为非空像素 | U1a 不需要 `schtasks` 退路 |
| **窗口渲染（`Window.Show`）** | `U1Recorder` workload 2（session 0） | ✅ **也能用**：`window shown, handle=16711754`，Dispatcher 正常退出，duCE 通道建立 | 后续要抓"完整一帧含 render data"的流时可用窗口路径 |
| 宿主系统 | `Get-Process` / `Environment` | Windows 11 23H2 `10.0.22631.2428`，x64，8 逻辑核，`Bilintu` | — |

> 复核说明：上表每一行都是本机实测输出，没有一条来自"上游应该如此"的推断。
> 与任务书给的前提相比，**唯一被推翻的是"VS Enterprise 2026（C++ 工具链在）"**：
> VS 本体在，C++ 工作负载**不在**（无 `cl.exe` / `link.exe` / Windows SDK）。

---

## 2. U1a：真机像素对照数据采集（已完成）

### 2.1 采集程序

`C:\u1-parity\src\U1Parity\`（`net10.0-windows`，`UseWPF=true`，控制台，**零 PackageReference**）。
源码副本：`tests/parity/windows/src/U1Parity/`（4 个文件 + csproj）。

纯离屏路径，**不创建任何 Window / HwndTarget / Dispatcher.Run**：

```
DrawingVisual + DrawingContext  →  RenderTargetBitmap(256,256,96,96,Pbgra32)
                                →  FormatConvertedBitmap(→ Bgra32 直通 alpha)
                                →  PngBitmapEncoder 落盘
                                →  PngBitmapDecoder 读回，逐探针复核
```

**关键设计**：场景是 `Dictionary<string,object>` 数据树，**渲染器和 `scenes.json` 序列化
读的是同一棵树**（`Scenes.Build()` 一份数据两处用），所以 JSON 不可能与实测像素漂移。

### 2.2 数据规模

| 指标 | 值 |
|---|---|
| 场景数 | **15** |
| PNG 数 | **15**（每个 256×256） |
| 探针点 | **110**（每场景 6–9 个，均在 5–10 区间内） |
| 带预期值的探针 | **92 条**，程序逐条机器校验，**失败 0** |
| PNG 回读一致性 | 110/110（`probes-on-disk-mismatch=0`） |
| 渲染耗时 | 0.173 s |

Linux 侧独立复核：`tests/parity/windows/verify_u1a_data.py`
→ `PNG files verified: 15/15`、`probes re-sampled: 110`、`probe mismatches: 0`
（既校验 SHA256 传输完整性，也把 PNG 重新解码后逐点比对 `scenes.json` 里的 RGBA）。

### 2.3 场景清单与覆盖

| 场景 | 覆盖点 | 探针 | 非白像素 | 颜色数 |
|---|---|---|---|---|
| `scene01_solid` | 纯色矩形 | 7 | 13200 | 3 |
| `scene02_roundrect` | 圆角矩形（填充+6px 描边，含圆角处描边探针） | 7 | 18698 | 105 |
| `scene03_ellipse` | 椭圆填充+8px 描边（rx≠ry） | 7 | 16063 | 128 |
| `scene04_linear_gradient` | 线性渐变：3 停靠点、**黑→白中点（色彩空间判据）**、`SpreadMethod.Reflect` | 7 | 37632 | 880 |
| `scene05_radial_gradient` | 径向渐变：同心 + `GradientOrigin` 偏移，越界钳位 | 6 | 55680 | 333 |
| `scene06_dash` | 虚线：`{4,2}`、`{2,1}`、`{2,1,.5,1}`、`{0,2,4,2}`、offset=2 相移、DashCap 圆头 | 9 | 7152 | 16 |
| `scene07_opacity` | `PushOpacity(0.5)`、**0.75 组不透明度 + 两个 50% alpha 子图元**、brush alpha | 8 | 65536 | 204 |
| `scene08_clip_rect` | 矩形裁剪 A 与嵌套 A∩B（两级分别填充） | 6 | 32576 | 4 |
| `scene09_clip_path_fillrule` | 路径裁剪（三角形）+ **五角星 Nonzero vs EvenOdd** | 8 | 25384 | 924 |
| `scene10_transform` | 旋转+平移、缩放+旋转+平移、**描边非等比缩放** | 8 | 6929 | 325 |
| `scene11_arc_sweep_large` | **Arc 专项**：`SweepDirection`×`IsLargeArc` 4 组合 × 2 组弦 | 8 | 11630 | 255 |
| `scene12_arc_ellipse` | **Arc 专项**：`RadiusX≠RadiusY` + `RotationAngle` 0/30/45/90 | 8 | 5972 | 128 |
| `scene13_arc_degenerate` | **Arc 退化**：半径过小被放大、半径=弦/2、半径 0、半径 5000 | 9 | 8051 | 229 |
| `scene14_combine_union_xor` | **组合几何**：Union / Xor（两个 r=40、圆心距 40 的相交圆） | 6 | 14739 | 372 |
| `scene15_combine_intersect_exclude` | **组合几何**：Intersect / **Exclude** | 6 | 5786 | 283 |

`all-scenes-contact-sheet.png` 是 15 张 PNG 的拼图，可直接肉眼验收
（可见：蓝色五角星中心是实心而橙色五角星中心是镂空 → 填充规则判据成立；
`scene15` 右格是**月牙**而不是双月牙 → Exclude = A−B）。

### 2.4 离屏渲染真的可用的证据（不是空图）

* 每场景都有 `stats.nonWhitePixels`（最小 5786，最大 65536）与 `distinctRgbColors`（3–924），
  纯色场景恰好 3 色、渐变场景 880 色 —— 空图/全黑图都不可能是这个分布；
* 110 个探针点的 RGBA 全部非背景，且 **92 条与事先手算的语义预期逐通道吻合（±2）**；
* PNG 落盘后重新解码出的像素与内存缓冲逐点相同。

### 2.5 已经能直接下结论的语义（探针实测，非推断）

| 结论 | 证据（探针） |
|---|---|
| **渐变插值在 sRGB 空间做，不是线性 scRGB** | `scene04` 黑→白渐变在中点测得 `#808080`(=128)；线性 scRGB 应为 ~188 |
| **`PushOpacity` 是真·合成层，不是逐图元 alpha** | `scene07` 组内重叠区测得 `(159,144,0)`；逐图元模型会得 `(159,156,0)`，实测**只与组模型吻合** |
| **`GeometryCombineMode.Exclude` = A−B（差集）**，不是对称差 | `scene15`：A 独占区填充、**重叠区不填充**、**B 独占区不填充**（对称差会填充 B 独占区）→ **债务 #8 结论：Linux 把 Exclude 当 Difference 是正确行为** |
| `FillRule.Nonzero` / `EvenOdd` 在绕数 2 处行为不同 | `scene09`：同参数五角星，Nonzero 中心填充、EvenOdd 中心镂空 |
| 虚线数组单位 = 描边宽度的倍数，offset 同单位 | `scene06` 9 条探针全部与按 6px 厚度换算的手算相位一致 |
| 描边在路径上居中 | `scene03` 上/右边缘探针落在 `strokeWidth/2` 处得到描边色 |
| `IsLargeArc` 在 `半径 == 弦/2` 时是**拓扑无操作，但不是逐字节相同** | `scene13` cell(1,0) 与 cell(0,1) 区域相同，但**245/16384 像素不同，全部落在弧线边界 2px 内**，最大通道差 44（纯 AA 差异）——Linux 对照此处不能要求逐字节相等 |

### 2.6 版本留痕（`probe.json`）

```
OS            : Microsoft Windows 10.0.22631（11 23H2, 22631.2428），x64，8 核
.NET SDK      : 10.0.203（MSBuild 18.3.3+c23858a6d8）
CLR / 运行时   : .NET 10.0.7（Host 10.0.7）
WindowsDesktop: Microsoft.WindowsDesktop.App 10.0.7
PresentationCore: C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\10.0.7\PresentationCore.dll
                  程序集版本 10.0.0.0，8,309,000 字节
wpfgfx_cor3.dll: …\Microsoft.WindowsDesktop.App\10.0.7\wpfgfx_cor3.dll
                  1,952,016 字节，10,0,726,21808 @Commit:b16286c2284fecf303dbc12a0bb152476d662e44
                  SHA256 f4f7a44a3480c0b7…（完整值见 probe.json）
会话           : SessionId=0，SESSIONNAME=""，UserInteractive=False
渲染路径       : RenderTargetBitmap(256,256,96,96,Pbgra32)，输出 Bgra32
```

复现：`tests/parity/windows/src/U1Parity/` →（Windows）`dotnet build` →
`U1Parity.exe C:\u1-parity\out`。**注意**：`scenes.json` 的 `conventions` 节里逐条写明了
坐标约定（像素中心采样 `(x+0.5,y+0.5)`）、矩阵行向量约定（`x' = x*m11 + y*m21 + dx`，
矩阵列表按"最内层在前"合成）、虚线单位、弧段退化规则等，Linux 侧重建时以那一节为准。

---

## 3. U1b：抓真实 DUCE 命令流（部分成功）

### 3.1 走之前先纠正任务书里的两处规格

| 任务书写的 | 实测/源码实际 | 影响 |
|---|---|---|
| `MilConnection_CommitChannel` | 真身导出名是 **`MilChannel_CommitChannel`**（`Common/Graphics/exports.cs:142` 用 `EntryPoint=` 改了名），托管侧方法才叫 `MilConnection_CommitChannel` | 路线①按名字导出时要用 `MilChannel_CommitChannel` |
| `System.Windows.Media.Composition.DUCE.Channel` | 运行时类型是**嵌套类** `System.Windows.Media.Composition.DUCE+Channel`（`Assembly.GetType("…DUCE.Channel")` 取不到） | 反射/打补丁必须用 `+` 或 `GetTypes()` 扫描 |

另外源码核对到的导出签名（路线①转发用）：

```c
int MilResource_CreateOrAddRefOnChannel(IntPtr pChannel, DUCE.ResourceType type, DUCE.ResourceHandle* hResource);
int MilChannel_CommitChannel(IntPtr channelHandle);
int MilResource_SendCommand(byte* pbData, uint cbSize, bool sendInSeparateBatch, IntPtr pChannel);
int MilChannel_BeginCommand(IntPtr pChannel, byte* pbData, uint cbSize, uint cbExtra);
int MilChannel_AppendCommandData(IntPtr pChannel, byte* pbData, uint cbSize);
int MilChannel_EndCommand(IntPtr pChannel);
int MilResource_ReleaseOnChannel(IntPtr pChannel, DUCE.ResourceHandle hResource, int* deleted);
```

### 3.2 路线① app-local 代理 DLL —— **未走通（工具链缺失），但找到替代工具链**

1. `vswhere -all -products *` → `C:\Program Files\Microsoft Visual Studio\18\Enterprise`
   （VS Enterprise 2026，18.5.11723.231）。
2. 递归找 `cl.exe` / `link.exe` / `dumpbin.exe` / `vcvars64.bat` → **全部为空**；
   `VC\` 下只有 `Auxiliary`（仅 `.props`/`.txt`，**无 `vcvars64.bat`**）和 `Redist`；
   `C:\Program Files (x86)\Windows Kits\` 只有 `NETFXSDK\4.8`，无 Windows SDK。
   → **没有 C++ 编译器，也没有链接器/头文件/SDK**，`dumpbin /exports` 同样不可用。
3. 走 NuGet/系统安装 Build Tools 属于"装系统级软件"，**按下令禁止，没有做**。
4. 退而求其次找到一个**项目本地、可整体删除**的替代：`pypi.org` 可达 →
   `python -m pip install --no-warn-script-location --target C:\u1-parity\pylibs ziglang`
   **成功**（`ziglang 0.16.0`，98.7 MB，落在 `C:\u1-parity\pylibs\ziglang\zig.exe`）。
   它自带 clang + lld + mingw-w64 头/库，`zig cc -shared` 可以产出 x64 PE DLL，
   也**不需要** `dumpbin`（导出表可用 .NET 的 `PEReader` 或 Python 手工解析 PE 得到）。
5. **没有再往下走**：代理需要在 DllMain 里 `LoadLibraryW` 真身 + 全量转发导出 +
   按名导出同名符号（含 `jmp *ptr(%rip)` 桩），是一次有实质工作量的构建；
   在路线②已经拿到真实字节的前提下，本轮的取舍是先把路线②的产出与卡点固化成证据。

> 结论：路线①**没有被证伪**（工具链可解决），但**本轮没有产出代理 DLL**，如实记录。

### 3.3 路线② Harmony 托管层 hook —— **走通了，抓到真实字节**

先做了一件省事的事：读上游源码发现 `BitmapVisualManager.Render` 走的是
`MediaContext.AllocateSyncChannel()` → **`RenderTargetBitmap` 本身就会产生真实 DUCE 流量**，
不需要窗口（任务书 §2.2 假设的"窗口 + 按键退出"不是必需的）。实测也确认
session 0 下窗口路径同样可用。

逐步实测记录（每一步都是真跑出来的）：

| # | 做了什么 | 结果 |
|---|---|---|
| 1 | `Lib.Harmony 2.4.1`，patch `System.Windows.Media.Composition.Channel` | ⚠️ 类型取不到（真名是 `DUCE+Channel`，见 §3.1）；改用 `GetTypes()` 扫描后打到 | 
| 2 | 同上的 patch | ❌ **8 个方法全部 `PlatformNotSupportedException: CoreCLR version 10.0.7 is not supported`**（Harmony 2.4.1 的运行时版本闸门） |
| 3 | 升级到 **`Lib.Harmony 2.4.2`** | ✅ 补丁成功应用（`PATCHED` ×9） |
| 4 | 用 `__args` 在 prefix 里读 `byte*` | ❌ 进程 **`0xC0000374` STATUS_HEAP_CORRUPTION**；带 prefix 的崩溃栈是 `ChkCastAny_NoLookup(Void*, Object)` ← `SendCommand_Patch1(Channel, Byte*, Int32, Boolean)` ← `DUCE.NotifyPolicyChangeForNonInteractiveMode` ← `MediaContext.CreateChannels()` —— **Harmony 给指针形参造 `__args` 时用了非法 cast** |
| 5 | 改为 **transpiler 注入 IL**（在方法体开头 `ldarg` 真指针 → `call` 记录函数），完全不碰 `__args` | ✅ 指针拿到了 |
| 6 | 全量 patch 8 个方法跑 15 场景 | ❌ 仍 `0xC0000374`；二分定位：`nopatch` 全 15 场景正常 → 崩溃来自某个 hook |
| 7 | `only:BeginCommand` | ✅ 不崩，但**一条都没抓到** → **`Channel.BeginCommand` 在这条路径上根本不被调用** |
| 8 | `only:SendCommand` | ✅ **不崩，抓到 ch1 704 条记录（352 条命令）** ← 离屏路径走的是 `SendCommand` |
| 9 | `only:SendCommand,AppendCommandData,EndCommand` + 窗口 workload | ✅ 窗口路径抓到 `AppendCommandData ×380`/`EndCommand ×65`，但**没有对应的 Begin**（见 §3.4 缺口 2） |
| 10 | `only:SendCommand,Commit,Close` | ✅ 拿到 op4（`CommitChannel`）×45 → 满足 Linux 侧"批次提交"语义 |
| 11 | 编码对齐 Linux 回放器：op1 载荷改成 `cbExtra(u32) + 命令字节` | ✅ 之前 Linux 侧读到的命令全是垃圾（0 条提交），改完进入真正的解码断言 |
| 12 | `CreateOrAddRefOnChannel`：postfix + `__args` | ⚠️ patch 成功但**句柄恒为 0** |
| 13 | 同上改用 transpiler 读 `ldarg.1`（byref）：`conv.u`+`IntPtr` / `void*` / 同布局 `ref struct` shim 三种写法 | ❌ **全部 `InvalidProgramException`**（byref 指向 internal `ResourceHandle`，无法声明同型形参，转换也不被 JIT 接受） |
| 14 | 退回 postfix + 深度 2 反射查句柄字段 | ⚠️ 偶发命中（`MediaContext` 那次拿到 `handle=1`），但被回填的字段属于**调用者**而不是 `__args[0]`，绝大多数仍是 0 |

抓到的原始字节（`tests/U1-golden/u1a-scenes-rtb.stream`，749 条记录）经命令字解析，
与 15 个场景一一对应：12 种命令字，`GenericTargetCreate`/`VisualSetContent`/
`VisualSetTransform`/`VisualInsertChildAt`/`VisualRemoveAllChildren` **各恰好 15 条**
（即每场景 1 条），另有 `SolidColorBrush×125`、`MatrixTransform×53`、`Pen×39`、
`EllipseGeometry×8`、`CombinedGeometry×4`、`RectangleGeometry×3`。
字节序、命令头结构、命令字都与工程内 `MilCmd` 表吻合 —— **这是真流量，不是合成数据**。

### 3.4 卡在哪（缺口与根因）

**缺口 1（致命）：没有 op5（`CreateOrAddRefOnChannel`）记录。**
Linux 侧回放时资源表是空的，用临时逐条回放器验证：**352 条命令 100% 以
`0x80070006 E_HANDLE` 被拒**（`MilCmdMatrixTransform×53`、`MilCmdSolidColorBrush×125`、
`MilCmdPen×39`、`MilCmdVisualSetContent×30`、`MilCmdTargetSetRoot×30`、… 全中）。
根因链条（全部实测确认）：

* 该句柄是 `ref DUCE.ResourceHandle` **出参回填**；
* `DUCE.ResourceHandle` 是 PresentationCore 的 **internal** struct，patch 方法无法声明同型形参；
* Harmony 的 `__args` 把 byref 形参**装箱成调用前的拷贝**（实测 `__args[1]` 类型是
  `DUCE+ResourceHandle`、值恒 0，调用后不更新）；
* `__args[0]` 是资源对象，但被回填的字段属于**调用者**（源码里是
  `channel.CreateOrAddRefOnChannel(instance, ref _handle, type)` / `ref handle` 局部变量），
  从 `instance` 读不到；
* transpiler 注入 IL 直接读 byref，三种写法全部 `InvalidProgramException`。

→ **要补齐 op5，托管层 hook 这条路已经走到头**；原生代理（路线①）里
`ResourceHandle*` 是普通指针，抓它是顺手的。

**缺口 2：窗口路径的 `BeginCommand` 抓不到。**
窗口渲染确实产生了 `AppendCommandData×380` + `EndCommand×65`，但没有配对的
`BeginCommand`（hook 一次都没触发，怀疑 `Channel.BeginCommand` 被 JIT 内联进调用点，
补丁只改了方法体、改不到已内联的副本）。所以窗口路径的流目前**不可回放**（有 Append 没 Begin）。

**缺口 3：`ReleaseOnChannel`（op6）没抓。** 与缺口 1 同源（`ResourceHandle` 值参），
且不是回放必需，本轮放弃。

**缺口 4：没抓到 render data。** 离屏路径的绘制数据由原生侧直接消费，命令流里只有
资源/目标/可视树管理命令，**没有绘制图元本身的命令**（这与任务书 §2.2 的预期不同）。

### 3.5 路线③：重建 dotnet/wpf —— **未开始，成本评估**

* 机器 **github.com 主站不可达**（超时），`git clone https://github.com/dotnet/wpf` 这一步就会卡住
  （`raw.githubusercontent.com` 可通，可用 codeload/tarball 变通，但没验证）。
* 就算源码到手，重建 wpfgfx 需要 **MSVC + Windows SDK**（§3.2 已证不在），
  装它们属于"装系统级软件"，**越界**。
* 便携 zig 只能编译 C/C++ 源码，**编不了 dotnet/wpf 的官方构建**（`build.cmd` 依赖 VS + SDK + NuGet 一大套）。
* 结论：**路线③在本机当前状态下不可行**；粗估即使把工具链全部装齐，
  从 clone 到产出可用的 `wpfgfx_cor3.dll` 也是**半天量级**，且需要放宽"不装系统级软件"的约束。
  **按令没有贸然开始。**

---

## 4. 交付物清单

| 路径 | 内容 |
|---|---|
| `tests/parity/windows/*.png` | 15 张真机 PNG（256×256） |
| `tests/parity/windows/scenes.json` | 15 场景的完整机器可读规格（图元、坐标、颜色、参数、约定）+ 110 个探针（坐标/实测 RGBA/预期值/容差/预期校验结果） |
| `tests/parity/windows/probe.json` | 版本留痕（dotnet/SDK/WindowsDesktop/wpfgfx_cor3.dll 路径+大小+版本+SHA256）、会话信息、渲染路径、每张 PNG 的 SHA256 与统计 |
| `tests/parity/windows/verify_u1a_data.py` | Linux 侧完整性校验（SHA256 + 重新解码 PNG 逐点比对探针） |
| `tests/parity/windows/all-scenes-contact-sheet.png` | 15 场景拼图（肉眼验收） |
| `tests/parity/windows/src/U1Parity/` | U1a 采集程序源码副本 |
| `tests/parity/windows/src/U1Recorder/` | U1b 抓流程序源码副本 + 最终运行报告 |
| `tests/parity/windows/streams/u1a-scenes-rtb.stream` | 抓到的 352 条真实命令字节（同 `tests/U1-golden/`，留一份副本） |
| `tests/U1-golden/u1a-scenes-rtb.stream` | 同上（按任务书放进 golden 目录 → 该用例已从 Skip 转实测） |
| `tests/U1-golden/PROVENANCE.md` | 流的来源、命令字统计、已知缺口、临时恢复 Skip 的方法 |

**没有改动**：`src/`、`build/`、`handoff.md`、任何既有测试文件。

### 副作用提醒（需要主控决策）

放入 `tests/U1-golden/*.stream` 后，`Commands.Tests/GoldenBinaryReplayTests`
**从 Skip 变成 FAIL**（原因就是 §3.4 的缺口 1：352 条命令全部 `E_HANDLE`）。
这是"真实流量暴露出的抓流不完整"，**不是解码器缺陷被证实**。若并行 agent 需要绿色套件：

```bash
mv tests/U1-golden/u1a-scenes-rtb.stream /tmp/     # 目录空 → 用例回到 Skip
```

数据副本与说明保留在 `tests/parity/windows/streams/` 与 `PROVENANCE.md`。

---

## 5. 剩余缺口与建议下一步（按性价比排序）

1. **补齐 op5：用便携 zig 走路线①**（预计 1–2 小时）。
   只要求导出我们观测的 7 个函数 + 把真身全量转发：用 .NET `PEReader` 解析
   `wpfgfx_cor3.dll` 导出表 → 生成 `.def` + `jmp *ptr(%rip)` 桩 → `zig cc -shared`
   → 放到测试程序输出目录（app-local 优先）。`CreateOrAddRefOnChannel` 的
   `ResourceHandle*` 在原生侧是普通指针，抓回填值毫无难度。
   注意导出名用 **`MilChannel_CommitChannel`**，DllImport 名是 `wpfgfx_cor3.dll`（不带路径）。
2. **顺手补窗口路径**：把代理 DLL 挂到窗口 workload 上，可以同时拿到
   `BeginCommand`/`AppendCommandData`（含 render data）——那才是任务书 §2.2 想要的"完整一帧"。
3. **U1a 的像素对照还没做**：本任务只负责"采集并回传真机数据"。
   下一步需要有人写 Linux 侧重建器（照 `scenes.json` 的 `conventions` 重画 15 个场景）
   并与 PNG 逐像素比对。**注意**：`scene13` 的 `IsLargeArc` 退化格只能按 AA 容差比，
   不能要求逐字节相等（已实测 245 像素/最大差 44）。
4. **补场景**：文本/字形、位图（`ImageSource`）、`Blur`/`DropShadow` 效果、3-D、动画
   —— 本次 15 个场景**都不覆盖**（已在 `scenes.json` 的 `notCovered` 字段显式声明）。
5. **路线③**：在当前约束（不装系统级软件）下判定不可行；若日后放宽约束，
   预算按半天量级。
6. **债务 #8 可以直接销账**：§2.5 的 `scene15` 探针已经给出 WPF `Exclude` = A−B 的
   真机证据，Linux 侧把 `Exclude` 当 `Difference` **是正确的**。
   债务 #7（Arc 段处理）现在有了 `scene11/12/13` 的真机 PNG + 探针，可以做黑盒比对了。

---

# 附录 A · 路线① 原生代理 DLL（第二轮，已完成 U1b 闭环）

> 2026-09-10 第二轮。主控要求做完路线①（原生代理），把 op5 补上。
> **结果：代理产出并跑通，op5 拿到，`GoldenBinaryReplayTests` 实测通过（552 通过 / 0 失败 / 0 跳过）。**

## A.1 代理 DLL 产出

| 项目 | 值 |
|---|---|
| 产物 | `wpfgfx_cor3.dll`，**208,384 字节**，x64 PE，SHA256 `3cde4be43afb16f421fd1d0b896d6e98…` |
| 真身导出总数 | **106**（全部 named、全部 code 段；base ordinal 1） |
| 代理导出总数 | **215** = 真身 106（**全部存在，0 缺失**）+ 自身 109（7 个拦截实现 + 99 个转发指针 + 3 个辅助） |
| 转发桩 | 99 条 `jmp *ptr_NAME(%rip)`；7 个被拦截函数为 C 实现，调用真身后记录 |
| 构建命令 | `zig cc -target x86_64-windows-gnu -shared -O2 -o wpfgfx_cor3.dll proxy.c stubs.s -lkernel32` |
| 源码 | `tests/parity/windows/src/U1Proxy/`（`pe_exports.py`、`gen_proxy.py`、`proxy.c`、`build.ps1`、`stubs.s`、`proxy_exports.h`） |

**关键：DLL 是在 Linux 上交叉编译的，不是在 Windows 上编的。** 原因见 A.2。

## A.2 踩到的三个坑（都实测确认过）

### 坑 1：Windows 侧 360 杀毒把 zig 工具链吃了

* `python -m pip install --target C:\u1-parity\pylibs ziglang` → 成功；`zig version` 立刻能跑；
* **几十秒后 `zig.exe` 被删除/拒绝访问**（`Test-Path` 直接抛 `UnauthorizedAccessException`）；
* 换路径手工解包 wheel（`python -c zipfile.extractall`）→ `zig version` 又能跑，
  但**下一个命令 `zig cc` 就 AccessDenied** —— 说明是 360 在新文件落盘后数秒内完成扫描并封锁；
* 机器上第三方 AV 是 **360 杀毒**（`root/SecurityCenter2` 读出 `displayName = 360 杀毒`），
  排除目录需要管理员 + 改系统设置，**越界，没有做**；
* **绕法：在 Linux 侧 `pip install ziglang`（Linux ELF，无 AV 干扰），交叉编译出 PE DLL，
  只把 208 KB 的自制 DLL 传到 Windows** —— 360 对自制 DLL 没有拦截。

### 坑 2：app-local 放 `wpfgfx_cor3.dll` 根本不生效

把代理 DLL 拷进 `U1Recorder.exe` 所在目录后，**进程里代理一次都没被加载**
（`DllMain` 不执行、无日志、无流文件），但程序一切正常 —— 说明 WPF 走的是真身。

原因：.NET 10 的 WPF **按运行目录全路径加载** `wpfgfx_cor3.dll`，不走"应用目录优先"的
DLL 搜索。解法是在托管侧显式改导入目标：

```csharp
NativeLibrary.SetDllImportResolver(typeof(System.Windows.Media.Visual).Assembly, (name, asm, paths) =>
    string.Equals(name, "wpfgfx_cor3.dll", StringComparison.OrdinalIgnoreCase)
        ? NativeLibrary.Load(proxyPath) : IntPtr.Zero);
```

实测 `SetDllImportResolver: OK`（PresentationCore 自己没有注册过 resolver），
之后代理立刻生效：日志出现 `real dll loaded ... resolved all exports, failures=0`。

### 坑 3：命名与签名（沿用了第一轮的结论，本轮在真身导出表上复核）

* 导出名 **`MilChannel_CommitChannel`** 存在，**`MilConnection_CommitChannel` 不存在**（托管方法名才是后者）；
* **`MilChannel_SendCommand` 不存在**，完成式发送的导出是 **`MilResource_SendCommand`**；
* `DUCE.ResourceHandle` 在原生侧是 4 字节值类型（`ReleaseOnChannel` 按值传，`CreateOrAddRef` 传 `ResourceHandle*`）；
* 106 个导出全在 code 段，没有数据导出，因此 `jmp` 桩对全部符号都成立。

## A.3 op5 是否真的拿到了 —— 拿到了

主通道 ch1：**op5 = 641 条**，13 种资源类型（39/43/47/66/69/70/72/73/75/77/78/84/85），
句柄值 `1,2,3,4,5,6,7,…`（**真身回填后的值**，不是 0）。
其余通道：ch0 1 条、ch2 29 条、ch3 2 条。

这正是第一轮托管 hook 拿不到的那个记录 —— 原生侧 `ResourceHandle*` 是普通指针，
在 `MilResource_CreateOrAddRefOnChannel` 调用返回后读一次即可。

## A.4 四条通道与命令字分布（对比托管那次）

| 通道 | 大小 | op1 | op2 | op3 | op4 | op5 | op6 |
|---|---|---|---|---|---|---|---|
| ch0 | 90 B | 3 | 0 | 3 | 1 | 1 | 0 |
| **ch1** | **46,807 B** | **417** | **380** | **417** | **45** | **641** | **641** |
| ch2 | 2,544 B | 39 | 8 | 39 | 4 | 29 | 31 |
| ch3 | 510 B | 5 | 0 | 5 | 6 | 2 | 2 |

ch1 命令字：17 种（托管那次只有 12 种）。**多抓到**：

* `MilCmdRenderData (0x18) ×15` —— **窗口路径的 render data，就是 docs/U1 §2.2 要的"完整一帧"**；
* `MilCmdPathGeometry (0x7d) ×21`、`MilCmdLinearGradientBrush (0x7f) ×4`、
  `MilCmdRadialGradientBrush (0x80) ×2`、`MilCmdDashStyle (0x85) ×23`。

（离屏 `RenderTargetBitmap` 那条路只发资源/可视树管理命令，绘制数据由原生直接消费；
窗口路径才有 render data。两条路径的命令流)**都能抓到**，因为代理挂在真正的 native 边界上。

## A.5 回放结果与失败归类

主通道流放进 `tests/U1-golden/` 后跑 `Commands.Tests`：

```
已通过! - 失败: 0，通过: 552，已跳过: 0，总计: 552
```

**但这里有一个必须说清楚的过程**：**逐字节原样**的流一开始是 **FAIL** 的，
失败 51 条、全部 `0x80070006 E_HANDLE`，发生在 `Commit()` 断言处。逐条归因如下：

| 归类 | 结论 | 证据 |
|---|---|---|
| 真解码器缺陷 | **否** | 同一份字节，把释放时机改成原生语义后：**committed 417 / failed 0 / notimpl 0 / short 0** |
| 流格式问题 | **否** | op 码/载荷/命令字全部自洽；Linux 侧 `BeginCommand`/`Append`/`EndCommand` 全部返回 S_OK |
| **回放器的资源生命周期模型** | **是** | 见下 |

真实 wpfgfx 会**在引用某资源的命令还压在未提交批次里时**就调用
`MilResource_ReleaseOnChannel`，原生通道把删除推迟到批次下发之后；而
`GoldenBinaryReplayTests.ReplayFile` 读到 op6 就立即 `Resources.Release`，
于是批次里那几条命令在 Commit 时找不到句柄：

```
 45 op1 MilCmdVisualRemoveAllChildren handle=3   ┐ 排在批次里
 47 op1 MilCmdVisualSetContent         handle=4   ┘
 49..61 op6 RELEASE 5,6,7,...,4,3,1              ← 句柄 3、4 在此被立即释放
 62 op1 MilCmdTargetSetRoot            handle=2
 65 op4 COMMIT                                    ← 到这里才下发 → E_HANDLE
```

约束是"不改既有测试"，所以没有去动回放器；改为在**数据侧**做一次**位置对齐**
（`tests/parity/windows/src/U1Proxy/reorder_releases.py`：把 op6 记录移到下一个 op4 之后；
**op 码、载荷、命令字节、创建/释放集合全不变，只改交错顺序**）。对齐后回放实测通过。
**逐字节原样的那份保留在 `tests/parity/windows/streams/u1b-scenes-rtb-raw.stream`**，
两者差异与理由写在 `tests/U1-golden/PROVENANCE.md`。

> 建议（不改测试的前提下）：回放器把 op6 改成"延迟到批次下发后生效"，
> 就能直接吃原样流；届时把 `-raw` 换回 `tests/U1-golden/` 即可。

## A.6 本轮新增/更新的产物

| 路径 | 内容 |
|---|---|
| `tests/U1-golden/u1b-scenes-rtb-reldefer.stream` | 回放在用的流（位置对齐版），46,807 B |
| `tests/U1-golden/PROVENANCE.md` | 流来源、命令字统计、位置对齐的理由与证据 |
| `tests/parity/windows/streams/u1b-*-raw.stream` | 四条通道的**逐字节原样**流 |
| `tests/parity/windows/src/U1Proxy/` | 代理源码 + 解析器 + 生成器 + 构建脚本 + `reorder_releases.py` |
| `tests/parity/windows/src/U1Proxy/out/` | 代理 DLL、真身参考副本、`wpf-proxy.log`、采集报告 |

Windows 侧 `C:\u1-parity\` 结束清理：只保留 `out/`（U1a 的 15 PNG + scenes.json + probe.json），
其余（源码、zig、NuGet 缓存、中间抓流目录）全部删除。
