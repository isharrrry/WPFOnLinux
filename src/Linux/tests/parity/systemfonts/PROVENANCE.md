# SystemFonts / SPI 真机 oracle（Windows WPF）

> **这批数据要回答的问题**：Linux 侧默认配置下**文字整段不画**，怀疑根因是"**字形 id 的面
> ≠ 光栅化的面**"（渲染器硬编码兜底族名，而该族在 `/usr/share/fonts` 里根本不存在）。
> 我们不知道 Windows 上 `SystemFonts.*` → 族名 → **实际字体文件** 这条链的正确关系，
> 之前只能猜。本目录把这条链**逐项 dump 下来**，并且每条都带文件路径 + SHA256。
>
> 全部读操作：只调用 `SPI_GET*`、只读注册表、只读主题文件；**没有改任何系统设置、
> 没有装字体、没有写注册表**。数据来自 `C:\wpf-oracle-systemfonts\`（与 layout agent 的
> `C:\wpf-oracle-layout\`、brush oracle 的 `C:\wpf-oracle-brush\` 分离）。

---

## 1. 环境留痕

| 项 | 值 |
|---|---|
| 机器 / 会话 | `Bilintu`，Windows 10.0.22631，x64，**SessionId = 0**（`UserInteractive=False`） |
| .NET | `.NET 10.0.7`，SDK `10.0.203` |
| `PresentationCore.dll` | **10.0.726.21808**（SHA256 见 JSON 的 `environment`） |
| `wpfgfx_cor3.dll` | 与 U1a `probe.json` 同一份二进制（10,0,726,21808 @ b16286c…） |
| Windows 字体目录 | `C:\Windows\Fonts` |
| 系统区域 | `environment.userCulture` / `systemCulture`（见 JSON；本机为 zh 系 + en-US UI 混合） |
| `TextFormattingMode` 默认 | **`Ideal`**（新建 `DependencyObject` 与新建 `TextBlock` 都读到 `Ideal`） |
| `TextRenderingMode` / `TextHintingMode` 默认 | `Auto` / `Auto` |
| DPI | `dpiScale = 1`（96 DPI） |

### ⚠️ 踩到的坑（写字体工具的人必看）

`<InvariantGlobalization>true</InvariantGlobalization>`（U1a 采集程序用过）会让
**WPF 字体 API 直接抛异常**：

```
System.Globalization.CultureNotFoundException: Only the invariant culture is supported
in globalization-invariant mode. ... en-us is an invalid culture identifier.
   at MS.Internal.FontFace.PhysicalFontFamily.ConvertDictionary(...)
   at System.Windows.Media.FontFamily.get_FamilyNames()
```

即：`FontFamily.FamilyNames` / `GlyphTypeface.FamilyNames` 内部会构造 `CultureInfo("en-us")`。
本项目因此显式设 `<InvariantGlobalization>false</InvariantGlobalization>`。

---

## 2. 复现命令（Windows 侧，Linux 本地零构建）

```cmd
mkdir C:\wpf-oracle-systemfonts\src\U1SystemFontsOracle
scp tests/parity/systemfonts/src/* PC@192.168.193.97:C:/wpf-oracle-systemfonts/src/U1SystemFontsOracle/
cd /d C:\wpf-oracle-systemfonts\src\U1SystemFontsOracle
dotnet build -c Release -v q --nologo

:: 正常采集
cmd /v:on /c "bin\Release\net10.0-windows\U1SystemFontsOracle.exe C:\wpf-oracle-systemfonts\out & echo RC=!errorlevel!"
:: → RC=0，failures=0

:: 【防假绿】破坏性自检：让 MessageFontFamily 解析到一个不存在的族
cmd /v:on /c "bin\Release\net10.0-windows\U1SystemFontsOracle.exe C:\wpf-oracle-systemfonts\out-sabotage --sabotage & echo RC=!errorlevel!"
:: → SABOTAGE_RC=2，failures=1
```

---

## 3. 三个问题的答案

### Q1：每个 `SystemFonts` 属性的族名 + **解析到的实际字体文件**

`SystemFonts` 的 60 个公开静态属性全部 dump 在 `windows-results.json` 的 `systemFonts[]`
（用反射枚举，将来新增属性不会漏）。六个字体族属性的答案**完全一致**：

| 属性 | 族名（`FontFamily.Source`） | 解析到的文件（每个都带 SHA256） |
|---|---|---|
| `MessageFontFamily` | **`Microsoft YaHei UI`** | `C:\WINDOWS\FONTS\MSYHL.TTC`（Light, weight **290**）<br>`C:\WINDOWS\FONTS\MSYH.TTC`（Regular, 400）<br>`C:\WINDOWS\FONTS\MSYHBD.TTC`（Bold, 700） |
| `CaptionFontFamily` / `SmallCaptionFontFamily` / `IconFontFamily` / `MenuFontFamily` / `StatusFontFamily` | 同上 | 同上（三个文件） |

尺寸/字重/样式（六个属性全部相同）：`Size = 12`、`Weight = 400`、`Style = Normal`、
`TextDecorations = 空`。JSON 里另有 `*FontSizeKey` 等 ResourceKey 属性。

**⚠️ 一条极易踩的坑：同一个族名对应 3 个文件、6 个 face**（`MSYHL/MSYH/MSYHBD.TTC#1`，
每个都有 Normal 与 Oblique 两个 face）。**glyph id 是逐 face 的**——三个文件的
`glyphCount` 分别是 **29816 / 30202 / 29949**，不是同一张字形表。

**⚠️ 更狠的一条：同一个 face 在 DirectWrite 命名与 Win32 命名下不是同一个族名。**

| 文件 | `familyNames` (en-US) | `win32FamilyNames` (en-US) | `faceNames` | `win32FaceNames` | weight |
|---|---|---|---|---|---|
| `MSYHL.TTC#1` | `Microsoft YaHei UI` | **`Microsoft YaHei UI Light`** | `Light` | **`Regular`** | **290** |
| `MSYH.TTC#1` | `Microsoft YaHei UI` | `Microsoft YaHei UI` | `Regular` | `Regular` | 400 |
| `MSYHBD.TTC#1` | `Microsoft YaHei UI` | `Microsoft YaHei UI` | `Bold` | `Bold` | 700 |

也就是说：**按族名 "Microsoft YaHei UI" 去查、和按 Win32 族名 "Microsoft YaHei UI Light"
去查，会在同一个 face 上得到两个不同的族名**；而且 Light face 的字重是 **290**（不是常规的
300），按字重匹配也可能落到另一个 face。这正是"**字形 id 的面 ≠ 光栅化的面**"这一类 bug 的
Windows 侧形态——Windows 上用**同一个文件里的不同 face** 表现出来，Linux 上则表现为
**族名解析失败后回退到另一个族**。

好消息：本次六个属性的 `nameMatchesFileFamilyName` 全是 **`yes`**——即
"WPF 报出来的族名"确实出现在"它解析到的文件内部族名"里（Light 那条靠 `familyNames`
而非 `win32FamilyNames` 命中，所以是 `yes`，但上表的错位仍然真实存在）。

### Q2：与 `Fonts.SystemFontFamilies` 的关系

- `Fonts.SystemFontFamilies` 共 **91** 个族，**两次枚举顺序完全一致**（`orderStable=true`）。
  前 5 个顺序：**`Cascadia Code`、`Cascadia Mono`、`Arial`、`Bahnschrift`、`Calibri`**
  （注意不是字母序：用户级/应用安装的 Cascadia 排在系统字体前面）。
- **`MessageFontFamily` 在不在集合里？→ 在。** 三种比法都为真：
  `bySourceString = true`、`byLocalizedFamilyName = true`、`byEquals = true`
  （我原本预期 `byEquals` 会是 false——WPF 这里返回的是缓存实例，所以对象标识也相等）。
- 另有旁证：`Fonts.SystemTypefaces` 共 **563** 个 typeface，消息字体文件确实在其中
  （`messageFontFileInSystemTypefaces = true`）。
- **同一个文件被多个族名共用**：`MSYH*.TTC` 同时支撑 `Microsoft YaHei` 与
  `Microsoft YaHei UI` 两个族（`familiesSharingMessageFontFile` 列出 6 条，两个族名 ×3 个面）。
- **`DejaVu Sans` 不在这 91 个族里**（本机只有 `DejaVu Sans Mono`、`DejaVu Math TeX Gyre`）。
  这条对 P0 很关键：若 Linux 侧某个路径声称"WPF 侧 `MessageFontFamily` 解析出 `DejaVu Sans`"，
  那**不可能来自 WPF 的 SPI 值**——本机 SPI 值就是 `Microsoft YaHei UI`。
- 集合里还包含 WPF 的**复合字体**：`Global User Interface`、`Global Monospace`、
  `Global Sans Serif`、`Global Serif`——WPF 的字体回退链正是走这几个。

### Q3：改主题后 `MessageFontFamily` 会不会变？——**机制已证，直接实验未验证**

分开说，不含糊：

**(a) 已证：它不是编译期常量，而是"每用户设置"读出来的。**

| 读数来源 | 值 |
|---|---|
| `SystemParametersInfo(SPI_GETNONCLIENTMETRICS).lfMessageFont.lfFaceName` | `Microsoft YaHei UI` |
| `HKCU\Control Panel\Desktop\WindowMetrics\MessageFont`（92 字节 `REG_BINARY`，即 LOGFONTW） | `Microsoft YaHei UI` |
| `SystemFonts.MessageFontFamily.Source` | `Microsoft YaHei UI` |
| `SPI_GETICONTITLELOGFONT`（图标字体） | `Microsoft YaHei UI` |

三者逐字相同 ⇒ WPF 的值**来自 SPI/注册表这条数据链**，而不是硬编码常量。注册表里
`MessageFont/CaptionFont/SmCaptionFont/MenuFont/StatusFont/IconFont` 六个值**全部存在**
且都是同样的 face name。

**(b) 未验证：真的去切主题。**
切换主题属于"改系统设置"，本次明令禁止，所以**没有做**，不拿推测代替结论。

**(c) 但有一条反向证据，值得注意**：本机 7 个 `.theme` 文件
（`aero.theme`、`dark.theme`、`spotlight.theme`、`themeA/B/C/D.theme`，SHA256 见 JSON）
**没有任何一个包含 `[Control Panel\Desktop\WindowMetrics]` 段**（`hasWindowMetricsSection`
全为 false）。当前主题是 `C:\Windows\resources\Themes\aero.theme`。

⇒ 结论表述：`MessageFontFamily` **是每用户可写的设置（数据驱动，已证）**；
**"切换主题会不会改变它"未经验证**，且从本机主题文件看，主题文件本身并不携带字体行，
所以即便有关联，路径也不是"改 `.theme` 文件"，而更可能是旧式"高级外观设置"
（写 `HKCU\...\WindowMetrics`）或区域/语言设置。**不要把它当成常量，也不要断言它随主题变。**

### 顺带：`TextFormattingMode` 默认值

`TextOptions.GetTextFormattingMode(new DependencyObject())` = **`Ideal`**；
新建 `TextBlock` 上读到同样是 `Ideal`。`TextRenderingMode = Auto`、`TextHintingMode = Auto`。

---

## 4. 防假绿：断言被现场推翻过（含一次**修正自己的**过程）

| # | 断言 | 结果 |
|---|---|---|
| 1 | 每个 `SystemFonts` 字体族都必须解析到**至少一个真实存在的字体文件** | 6/6 通过 |
| 2 | 每个引用到的文件都记录 SHA256 | 全部记录（见 `typefaces[].sha256`） |
| 3 | **负控制**：不存在的族名 `__NoSuchFontFamily_U1__` 必须解析到 **0** 个文件 | `negativeControl.ok = true`、`resolvedFiles = []` |
| 4 | SPI 每个 LOGFONT 的 face name 非空 | 6/6 非空 |
| 5 | `Fonts.SystemFontFamilies` 两次枚举顺序一致 | `orderStable = true` |
| 6 | **破坏性自检**：`--sabotage` 让 `MessageFontFamily` 解析到不存在的族 | **`failures=1`、退出码 2** |

**过程留痕（这点比结果重要）**：第一版 `--sabotage` 只把**报出来的族名字符串**换成假的，
解析仍然走真对象，结果 `failures=0`、退出码 0 —— **断言当时是没牙的**。改成"破坏解析本身"
（用不存在的族去解析文件）之后才真的红：

```
SABOTAGE_RC=2
  ! SystemFonts.MessageFontFamily ('__NoSuchFontFamily_U1__') resolves to NO font file [sabotaged]
```

也就是说：**"我加了个断言" ≠ "断言有效"**，这条只有靠故意破坏才能发现。

---

## 5. 文件清单

| 路径 | 说明 |
|---|---|
| `windows-results.json` | 全部读数：`systemFonts[]`（60 属性）、`systemFontFamilies`、`rawSpi`（SPI/注册表/主题文件/字体替换表）、`textRenderingDefaults`、`negativeControl`、`failures` |
| `out/run.log` | 正常采集输出（`failures=0`，RC=0） |
| `out/run-sabotage.log` | 破坏性自检输出（`failures=1`，RC=2） |
| `src/` | Windows 侧采集程序（`Program.cs` / `Json.cs` / `U1SystemFontsOracle.csproj`） |
| `PROVENANCE.md` | 本文件 |

## 6. 未覆盖

- **切主题实测**（禁止改系统设置）——见 Q3(b)。
- 多用户/多语言环境下 `HKCU\...\WindowMetrics` 缺项时的回退行为（本机六个值都在，
  没构造出"缺项"场景）。
- 字体回退链本身（`Global User Interface` 复合字体的 `FamilyMaps` 内容）未展开——
  XML 可以读，但那属于 shaping 轨道的范围，本目录只记录"它存在于族列表里"。
