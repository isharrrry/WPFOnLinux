# ThirdPartyMini —— **第三方形态**的最小 WPF 应用（仓内判据）

> **它存在的唯一理由**：让"第三方 WPF 应用能在 Linux 上编译并渲染"这句话**在本仓内可复算**。
> 在那之前，这条结论只有**仓外**证据（HandyControl 示例工程 ＋ 它的探针，两者都不在本仓）
> ⇒ 它**不构成仓内判据**。本样本把同一件事搬进仓里，并接成 `verify-all` 的第 `[19]` 步。

---

## 它"第三方"在哪里（不是又一个自建样本）

| 维度 | 本样本 | 仓内其它样本（`HelloWpf` / `WpfTextDemo`） |
|---|---|---|
| 接线方式 | **只经** `build/third-party/WpfLinux.props`（发给第三方的配方） | 各自手写完整引用清单 |
| 仓卫生 | **不** `import` 仓内 `BuildHygiene.props`（真实外部工程没有它），用 `EnableDefaultCompileItems=false` 显式列清单 ⇒ 名册里是 `notneeded` ＋ 见证 `no-compile-glob` | `wired`（恰好 1 行规范 Import） |
| 解决方案 | **不进** `wpf-linux.sln` | 在 sln 里 |
| 运行位置 | **复制到仓外**再跑（`$TPM_RUN_DIR/app`）—— 因为"第三方应用在仓外" | 原地跑 |
| 覆盖的东西 | `WindowChrome` 自定义 chrome ／ **图片解码**（WIC → Skia）／ 中文与图标字形 ／ 数据绑定列表 ／ BAML | 各自不同 |

---

## 运行

```bash
# 判据自测（不跑应用；两极化）
bash samples/ThirdPartyMini/run-thirdparty-mini.sh --selftest

# 完整一趟：构建 → 复制到仓外 → 部署四个 .so → 起 Xvfb → 时间分辨采样 → 判据
bash samples/ThirdPartyMini/run-thirdparty-mini.sh 25

# 复用已构建产物 / 反极性（故意不部署 libwpfwin32.so）
bash samples/ThirdPartyMini/run-thirdparty-mini.sh 15 --no-build
bash samples/ThirdPartyMini/run-thirdparty-mini.sh 15 --no-build --hide-shim

# 并发时各用各的
TPM_RUN_DIR=/tmp/tpm-a TPM_DISPLAY=:95 bash samples/ThirdPartyMini/run-thirdparty-mini.sh 25
```

`--selftest` 之外都不需要参数；全部产物落在 `$TPM_RUN_DIR`（默认 `$HOME/w37-tpm-<HHMMSS>`）。

## 判据（三态；`NOINFO` 不许当绿）

```
THIRDPARTY=PASS    采样窗口内**至少一帧**的（根窗口）颜色数 ≥ --min-colors（默认 800）
THIRDPARTY=FAIL    采到帧但一帧都不达标 **或** 应用崩了（app-exit=134/139…）
THIRDPARTY=NOINFO  一帧都没采到而应用是正常收尾的（仪器没跑起来）⇒ 与 FAIL 分开报
```

配套机读行（都可复算）：`THIRDPARTY_BUILD`、`THIRDPARTY_LAYOUT`（必须是 `OUT-OF-REPO`）、
`THIRDPARTY_DEPLOY=<每个 .so 的 sha16>`、`THIRDPARTY_TESTIMAGE`、`THIRDPARTY_APP=exit=… frames=…`、
`THIRDPARTY_IMAGE=`（由**应用自己**打印的解码结果）、`THIRDPARTY=`（总判）。

**阈值 800 的来历**：第三方实证（HandyControl）窗口内实测 **1275** 色、仓内样本 **3960 / 2828**
⇒ 800 留足余量，而**低于它一定是坏了**（空白窗口只有 1 色）。

**两极化都实测过**（`#37` B）：
`PASS` = 仓外 ＋ 四个 `.so`（`max_colors=1485`，图片 `96×96 Bgra32` 解码成功）；
`FAIL/rc=1` = 仓外 ＋ **不部署** `libwpfwin32.so`（应用 `exit=134`，
日志里是 `DllNotFoundException: 'kernel32.dll' 已映射到 libwpfwin32.so，但没找到可加载的 shim 库`）。

---

## ⚠️ 两条踩坑（都是本样本的**结论**，不是脚注）

### ① "把 `.so` 放到应用目录"这条部署布局，**在仓内测不出来**
`Win32ShimResolver` 的候选路径会从 **`AppContext.BaseDirectory`** 与
**`Directory.GetCurrentDirectory()`** 两条各自向上走 12 层去找仓根
（`build/shims/Win32ShimResolver.cs:524-537`）。
⇒ 只要**应用在仓内**或**cwd 是仓根**，即使你**故意不部署** `libwpfwin32.so`，
它也会被这条回退找到 —— 本波现场实测：`--hide-shim` 照样 `PASS`、**1485 色**（反极性失效）。
⇒ 所以 runner 做了两件事：**把产物复制到仓外** ＋ **启动时 `cd` 到应用目录**。
真正的第三方应用天然满足这两条，它**必须**靠"四个 `.so` 与 app 同目录"才能跑。

### ② 应用崩了 ≠ 仪器没跑
第一次实现把"一帧都没采到"一律记成 `NOINFO` ⇒ 反极性那一趟只拿到 `rc=2`，
**看起来像仪器故障**，而事实是应用 `DllNotFoundException` 崩了。
现在按**应用退出码**细分：崩 ⇒ `FAIL`（红），只有"应用正常收尾却采不到帧"才是 `NOINFO`。

---

## `#38` B4：它同时是**`XamlAccessLevel` 那条路**的探针

`MainWindow.xaml` 里引用了一个 **internal** 类型（`InternalBadge : ContentControl`，在 `MainWindow.xaml.cs`）
⇒ PBT 会给本程序集生成 `GeneratedInternalTypeHelper`（实测生成物里命中 **1** 次）
⇒ `XamlReader.LoadBaml` **必然**调 `XamlAccessLevel.AssemblyAccessTo` ——
这正是官方 `System.Windows.Extensions` 包"非 Windows 必抛"的那条路。

```bash
# 正极性（配方已接线）：应当 PASS，且窗口内有那个 internal 控件
bash samples/ThirdPartyMini/run-thirdparty-mini.sh 20
#   → THIRDPARTY=PASS … max_colors=1642

# 反极性：把配方临时换回官方包 ⇒ 必须崩（证明上面那条不是恒绿）
python3 - <<'EOF'
p='build/third-party/WpfLinux.props'; s=open(p).read()
i=s.index('    <!-- ── `System.Windows.Extensions`'); j=s.index('    </Reference>', i)+len('    </Reference>')
open(p,'w').write(s[:i] + '    <PackageReference Include="System.Windows.Extensions" Version="9.0.0" />' + s[j:])
EOF
dotnet build samples/ThirdPartyMini/ThirdPartyMini.csproj -m:1 --nologo -v q
bash samples/ThirdPartyMini/run-thirdparty-mini.sh 12 --no-build
#   → THIRDPARTY=FAIL reason=app-exit=134
#     System.PlatformNotSupportedException: System.Windows.Extensions types are not supported on this platform.
# 记得还原配方（git 或备份）
```

## 它**不**覆盖什么（边界）

- **GDI+ 图像族**（`System.Drawing` 风格的解码）：本样本走的是 WPF 的 `BitmapImage` ⇒ WIC 链；
  GDI+ 面今天只做到"应用能起来"（创建/解码类**如实失败**），是**待办**。
- **`System.Windows.Extensions` 替身**（`XamlAccessLevel` / `GeneratedInternalTypeHelper`）：
  替身已写好但**接线未打通**（登记 `D-G45`）。
- **复杂控件库**（`HandyControl` 那种 148 个 Page 的规模）：那是在**仓外**做的实证，
  本样本是"最小可判据"，不是它的替代。
