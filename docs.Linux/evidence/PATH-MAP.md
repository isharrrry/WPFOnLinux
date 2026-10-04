# 路径映射表（旧 → 新）· 结构上游化·合并波

> 生成于 2026-10-04 18:09:16。**旧路径仅存于断言面清单件/历史台账**（其内容一字不改，旧路径由本表承担）。
> 复算命令逐条给在末列（在本仓根执行）。

| 旧路径（仓根） | 新落点 | 复算命令 |
|---|---|---|
| `build/` | `src/Linux/build/` | `test -d src/Linux/build` |
| `tests/` | `src/Linux/tests/` | `test -d src/Linux/tests` |
| `samples/` | `src/Linux/samples/` | `test -d src/Linux/samples` |
| `tools/` | `src/Linux/tools/` | `test -d src/Linux/tools` |
| `wpf-linux.sln` | `src/Linux/wpf-linux.sln` | `test -f src/Linux/wpf-linux.sln` |
| `verify-all.sh` | `Guide.Linux/verify-all.sh` | `test -f Guide.Linux/verify-all.sh` |
| `build/<工程>.Linux/` | `src/Microsoft.DotNet.Wpf.Linux/src/<工程>/` | `ls src/Microsoft.DotNet.Wpf.Linux/src` |
| `build/shims/` | `src/Microsoft.DotNet.Wpf.Linux/src/shims/` | `test -d src/Microsoft.DotNet.Wpf.Linux/src/shims` |
| `build/DirectWrite.Linux/` | `src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/` | `test -d src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite` |
| `build/DirectWriteForwarder.Linux/` | `src/Microsoft.DotNet.Wpf.Linux/src/DirectWriteForwarder/` | `test -d src/Microsoft.DotNet.Wpf.Linux/src/DirectWriteForwarder` |
| `src/WpfGfx.Linux/` | `src/Microsoft.DotNet.Wpf.Linux/src/WpfGfx/` | `test -d src/Microsoft.DotNet.Wpf.Linux/src/WpfGfx` |
| （取回） | `src/Microsoft.DotNet.Wpf/` | `git archive a394a4792 src/Microsoft.DotNet.Wpf` |
| （取回）上游仓根脚本 | `Guide/` | `ls Guide` |
| `upstream/wpf/` | **最后一步删除**，改由 `docs.Linux/evidence/UPSTREAM-MANIFEST.tsv` 校验 | `wc -l docs.Linux/evidence/UPSTREAM-MANIFEST.tsv` |

## 各 \<工程\>（17 份）

- `build/CycleStub.PresentationFramework.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/CycleStub.PresentationFramework/`
- `build/CycleStub.PresentationUI.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/CycleStub.PresentationUI/`
- `build/CycleStub.ReachFramework.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/CycleStub.ReachFramework/`
- `build/DirectWriteForwarder.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/DirectWriteForwarder/`
- `build/DirectWrite.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/`
- `build/PresentationBuildTasks.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/PresentationBuildTasks/`
- `build/PresentationCore.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/PresentationCore/`
- `build/PresentationFramework.Classic.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/PresentationFramework.Classic/`
- `build/PresentationFramework.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/PresentationFramework/`
- `build/ReachFramework.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/ReachFramework/`
- `build/System.Printing.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/System.Printing/`
- `build/System.Windows.Extensions.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/System.Windows.Extensions/`
- `build/System.Windows.Input.Manipulations.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/System.Windows.Input.Manipulations/`
- `build/System.Xaml.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/System.Xaml/`
- `build/UIAutomationProvider.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/UIAutomationProvider/`
- `build/UIAutomationTypes.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/UIAutomationTypes/`
- `build/WindowsBase.Linux/` → `src/Microsoft.DotNet.Wpf.Linux/src/WindowsBase/`
