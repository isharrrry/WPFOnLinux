# 任务 T-B5 · `WIN-INTEROP.md` §7.5 **L2**：身份抬到 `10.0.0.0` ＋ 令牌对齐 —— 实现

## ① 任务目标
你是本项目的**实现**子代理（写者；本轮唯一写者）。照 `/home/links-dev/netTest/GitProj/WIN-INTEROP.md` **§7.5 的 L2** 与 **§7.3**（已由 `T-B2` 做完 L1 路线①）：
**把自产件的 `AssemblyVersion` 抬到官方对齐的 `10.0.0.0`（＋令牌对齐）**，使 **Windows 编的「库包」能绑上**。

必做（逐条现取）：
1. **唯一功能性读者**：`build/DirectWrite.Linux/WiringSmoke/fix-deps.py:13`（硬编码 `WindowsBase/4.0.0.1` 的 deps 键）⇒ **同趟同步**，否则必红。
2. **不变量复核**：「自产版本 > 框架门面 `4.0.0.0`」在 `10.0.0.0` 下**仍成立**；`build/Directory.Upstream.props` 的「丢弃同名门面引用」逻辑**仍需要**（按"同名"触发，与数值无关）⇒ 逐条给现取。
3. **影响面**：`grep -rn "4\.0\.0\.1" --include=*.py --include=*.sh --include=*.props --include=*.csproj . | grep -v upstream/ | wc -l` 的**逐件**清单与处置（§7.5 说 77 处文字）；**一处判据**须同趟改。
4. **令牌对齐**：按官方件对齐 `PublicKeyToken`（给官方对照取值 ＋ 自产取值前后对拍）。
5. **全面回归**：L1 的 e2e（框架目录 `verify` ＋ `dotnet WpfTextDemo.dll`）**仍须成立**；**反极性**（回 `4.0.0.1`）⇒ 库包绑定失败形态复现（`FileNotFoundException 0x80070002`）。

**硬边界**：永不假成功/零假值；**不许**改 `upstream/**`；`P8`；副本先行；写前 `cp -p`；两极化。

## ② 边界条款
- 只改：`build/**`（`Directory.*.props`／csproj／脚本／判据）／`docs/**`／`src/**` 的版本声明面（如必须）／仓外框架目录（重装）／新建载体 `build/MilBridge/P1-wininteropL2-impl-report.md`。
- 黑名单：`upstream/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`。
- 重活走槽；进程只按 PID；禁 sleep 轮询；temp+rename；模式守恒。不要跑整趟 verify-all。

## ③ 验收标准（可计算）
- ① 影响面逐件清单（`grep` 计数前后 ＋ 逐件处置）；② 自产 `AssemblyVersion` 现取 ＝ `10.0.0.0`（逐件 sha16）；③ 令牌现取（官方对照）；④ **库包绑定**：构造一个**请求低版本**的消费例 ⇒ **绑上**（给现取）；⑤ 反极性 ⇒ `FileNotFoundException 0x80070002`；⑥ L1 e2e 仍成立（`verify 25/25` ＋ 起窗渲染）；⑦ `DEFREG`/`REPORTID` rc=0。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有。
