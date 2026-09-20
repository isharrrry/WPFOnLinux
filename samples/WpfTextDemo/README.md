# WpfTextDemo —— 「默认配置门禁」的第二个真 WPF 样例

> 建立：2026-09-11 ｜ 车道：本目录 + `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo*.sh`
> 目的：**把"真应用拿到的默认配置"变成可自动判真的验收面**（过去只有"一个样例 × 带字体 env"）。

## 一行命令

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux

# 门禁（验收两档 × 3 次）：default = 默认配置（主）/ env = 带字体覆盖（对照）
$R/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 45

# 最小复现矩阵（4 档 × 3 次：default / env / degraded / minimal）
$R/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo-minrepro.sh 45 3

# 单独复现某一种形态
$R/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 45 --tier degraded
$R/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 45 --tier minimal
```

机读行：`WPTD_TIER=… RESULT=… blocker=… shot=…`、`WPTD_TIER_SUMMARY=<档> passed=k/N`、
`WPTD_SUMMARY=PASS|FAIL`（**只看验收档**）、`WPTD_DEGRADED=…`（应用自报降级项）。

## 档位语义（**验收 ≠ 诊断**）

| 档 | 类别 | 含义 | 参与门禁结论 |
|---|---|---|---|
| `default` | 验收·主 | 清空**所有** `WPF_LINUX_*`/`HLWPF_*` 后的默认配置 | ✅ |
| `env` | 验收·对照 | 复刻 M2 验收配置（`fc-scan` 读族 + `WPF_LINUX_FONT_DIR`/`WPF_LINUX_UI_FONT`） | ✅ |
| `degraded` | 诊断 | 应用侧关掉折行/省略号/对齐/列表项（`--diagnostic-degraded`，会打印降级清单） | ❌ |
| `minimal` | 诊断 | 代码构造最小可视树（3 个短 TextBlock，`--minimal`） | ❌ |

判据（每档四条）：① 进程存活且退出码 143 ② `未画种类 0` **且呈现帧非空**（空帧下 `未画种类 0` 是空真）
③ 截图非空非纯色（不同颜色数 ≥ 阈） ④ **每个可见特性色**都有 ≥ 阈像素（不是白像素总数）。

## 样例覆盖的可见特性

折行中英混排 / `TextTrimming` 省略号 / `TextAlignment` 三档 / 数据绑定 + `ListBox` + `ScrollViewer` /
程序生成位图（`BitmapSource.Create`，失败则**大声降级**为矢量 `DrawingImage`）/ 圆角 `Border` +
`DropShadowEffect` / 鼠标命中（`MouseEnter`/`Leave`/`LeftButtonDown` 改可见状态 + 台账）。

用 `--minimal` / `--diagnostic-degraded` 可把这些特性按需缩小或关掉（**仅供诊断**）。

## 垫片卡 + 判据⑥ 的**假红**修复（2026-09-13，波 9 配置）

### 为什么左列多了一张"⑥ 滚动垫片"卡（**别当装饰删掉**）
判据⑥ 的标准是"**真的有东西可滚，且滚动真的改变了画面**"——标准没错，但它原先的隐含前提
"左列内容必然高于视口"**依赖另一条车道的行高**：波 8 让每段文本少算一行 ⇒ 内容 806.4→649.2
**不再溢出**（视口 717.1）⇒ `ScrollableHeight=0` ⇒ 判据⑥ 变成**不可满足**（红得没错，红因却不是被测对象）。
垫片卡 `Canvas Height=220`（**高度写死、只用已验证能画的 `Rectangle`**、三条同色横杠做位移标记）
把"溢出"变成**构造保证** ⇒ 判据⑥ **一个字不放宽**，也不再被别人的改动牵动。

### 常开读数（**不是诊断开关**，验收档也打）
```
WPTD_SCROLL_RANGE=extent=… viewport=… scrollable=… bar=… offset=…     ← 首绘后
WPTD_SCROLL_MOVED=offset=… delta=… scrollable=…                       ← 偏移真变了时（最多 5 行）
```
波 9 实测：`WPTD_SCROLL_MOVED=offset=48→96→144→192→209.2 delta=48 scrollable=209.2`（滚到底）。
⇒ "内容不再溢出"从"只能靠 AE=0 反推"变成**一眼可见的事实**。

### ⚠️ 判据⑥ 曾经**假红**：`before/after` 取样自同一个"最佳帧"指针
- 旧代码：`[ -s "$shot" ] && cp -f "$shot" "$after_shot"`，而 `$shot` **只在第二趟颜色数更高时**才更新
  ⇒ 只要第二趟色数不高于第一趟（默认档 `4114 → 3913` 就是这样），`after` 就成了 `before` 的副本
  ⇒ `AE=0` ⇒ 报"滚动没有改变画面"。**现场**：`before.png` 与 `after.png` **md5 完全相同**
  （都等于 `burst-default-r1-1.png`），而同一趟 `burst1 ↔ burst2` 首帧差 **AE=141605**（env 档 135468）。
- 现在：`shot2` = **第二趟自己的最佳帧**（与"全程最佳"解耦），判据⑥ 一律取它；日志里打出取样行
  `判据⑥ 取样：before=第一趟最佳（色数 …）、after=第二趟最佳（色数 …）` ⇒ 读者能核 AE 是拿**一对真帧**算的。
- 诚实附注：波 8 那次 `AE=0` 的**结论**（没东西可滚）当时是对的，但**理由**是错的（仪器拿 before 比自己）
  —— "结论对、判据错"的成员同样要修，否则它迟早给出假红/假绿。

## 基线冻结状态：**未冻**（等集成波把 shim 编进 PC）

当前值（**每次读数以运行时 `WPTD_ARTIFACTS` 为准**；下面这些是"等待期实读"）：
```
pc=(待集成波重建；此前 684424fea3a0812a)   bridge=e0d01832a3efea53（4,937,968 B / 16:11:04 重发，含 T2b 类名后缀）
pf=9f0f4332e0b34214   provider=71ba86c6495347fe
win32shim=e1691fd8440da926（269,616 B，全仓 4 份同 sha）   wic_shim=03b67fbcd7c385b6
hbtextline=(待 PC 重建后重取；此前 ebccdb1ee65e6f76 且 stale=yes)
```
**桥契约（T2b 新格式，两个 runner 都已加检查）**：`未画种类 0` 必须**逐字节无 `[]`**；
非 0 时必须带条款表（形如 `未画种类 1 [MilPushOpacityMask×1]`）。
⇒ **数值对但没有条款表** ⇒ 判"**取到旧桥/旧件**"，**不是**类名逻辑错。runner 会打
`桥契约 ✅ …` 或 `⚠️ 桥契约：… 疑取到旧桥/旧件`（探针 runner 另有 `WFP_DIAG tag=… bridge_contract=…`）。
- `bridge` **必变**（只重发一次）⇒ 变后重跑 1 趟门禁确认"未画种类"与渐变三块像素，才可冻；
- `hbtextline` 已变且 `stale=yes`（**权威 PC 比 shim 源旧** ⇒ 跑的是旧文本栈）⇒ PC 重建后**必须重冻**，
  并重测判据④/⑦ 的行高相关读数；
- `hbtextline_shim_stale` 从 2026-09-13 起是**真值位**（原来按构造恒 `no`；修复依据与自测见 runner 内注释）。

## 波 8 二次集成（`.wave-done` 23:35，PC `fb28ecd58aa868e2` / 桥 `e57da6e5d04d5d20`）：判据⑥ 的红因 = **栈侧文本行度量变化**

**门禁读数**：`WPTD_SUMMARY=FAIL tiers_passed=0/2 failed: default env`（exit 1）

- `default` ×3：`exit=143 drawn=246 notdrawn=0 frames 14/14 capture=ok scroll=no-change colors=3935 cross_ae=0`
  ⇒ 判据 ① ② ③ ⑤/⑤b 全绿，**唯一红 = ⑥（滚动前后 AE=0）**
- `env` ×3：rep1 **启动期** `exit=134`（栈见下），rep2/3 `exit=143 scroll=no-change`
- 判据⑦ 仍绿：`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 runs=164`（上一轮 runs=131）

`env rep1` 的崩溃栈（**窗口都没出来，frames=0**；当时 Xvfb 活着 —— 同 tier 的 rep2/3 在同一 display 上正常出窗）：

```
System.ComponentModel.Win32Exception (1400) ← MS.Win32.UnsafeNativeMethods.CreateWindowEx
  ← MS.Win32.HwndWrapper..ctor ← MS.Win32.MessageOnlyHwndWrapper..ctor
  ← System.Windows.Threading.Dispatcher..ctor (Dispatcher.cs:1737) ← System.Windows.Application..ctor
```

### ⑥ 的真因（**同一支样例 + 同一支仪器**在两个栈上 A/B，不是拿新旧日志互比）

把同一支 dll 铺进**旧栈的运行目录**再跑一遍同一探针 ⇒ 差异只可能来自栈：

| 跳 | 旧栈 `wpfgfx 177a07a6…` / `pc 0fad3c19…` | 新栈 `e57da6e5…` / `fb28ecd5…` |
|---|---|---|
| hwnd 收到滚轮 | ✓ `msg=0x020a` ×8 | ✓ ×8 |
| WPF `PreviewMouseWheel` | ✓ delta=−120 | ✓ delta=−120 |
| `ScrollViewer.MouseWheel` | ✓ handled=True | ✓ handled=True |
| **`ScrollChanged`** | ✓ vo 0→48→96→118.4 | **从不触发** |
| `ExtentHeight` / `ViewportHeight` | **806.4 / 688.0** | **649.2 / 717.1** |
| `ScrollableHeight` / 滚动条 | **118.4 / Visible** | **0.0 / Collapsed** |
| 滚动前后帧差 | **AE=122459**（差异区 445×718 @(37,110)，整列位移） | AE=0 |

⇒ 滚轮链路**一跳没断**，是"内容比视口矮了 68 px"，ScrollViewer **正确地什么都没做**。
判据⑥ 因此在当前布局下**不可满足**（不是把标准放宽：是前提没了）。

**这笔账分摊到卡片上**（同一探针读 `ActualHeight`）：左列 5 张卡
`176.3→144.9 / 127.5→96.0 / 160.0→96.0 / 160.3→145.1 / 132.3→117.1`；
`WrapText 114.1→97.8`（宽 380、字体都没动 ⇒ **7 行→6 行，行高 16.3 一模一样**）、
`TrimText 65.2→48.9`（4→3 行）、`HitCard 56.3→41.1`、`ItemsList 563.5→636.9`、ScrollViewer 自身 `688.0→717.1`。
**每张卡的减少量都是行高的整数倍**（单行 TextBlock −15.2，折行段落 −16.3）⇒ 新栈每段文本少算了一行"幻影行"。
读图对照（两张 938×938 实拍）：文字内容与折行位置**没变**、无裁切、⑤ 形状卡从"被视口裁掉"变成完整可见、
右列 ListBox 可见项 13→18；旧图每张卡底部有空余、新图贴合 ⇒ **方向上趋近 Windows**，副作用是本样例左列不再溢出。

> ⚠️ 这条**只说明"度量变了"，不判定"变好还是变坏"**：幻影行该不该算，属文本/布局车道的读数
> （`Extent` 在 shim 车道的 `build/MilBridge/run.sh tline` 里量，我这边**不转录、不代替**）。
> 本样例侧的处置（是否加定高垫片卡让"溢出"与文本度量解耦）**等主控裁决**，不擅自改判据。

### 诊断开关 `WPTD_INPUT_DIAG=1`（**默认关**：没设开关时一行日志都不加，主档读数不受影响）

打开后逐跳打点，把"消息到了 hwnd / WPF 输入系统收到 / ScrollViewer 收到 / 偏移真变了 / 布局各元素多高"分开：

- `① PreviewMouseWheel …`（隧道事件，`handledEventsToo`）、`③ ScrollViewer.MouseWheel … handled(收到时)=…`、
  `④ ScrollChanged vo …（Δ…）`、`② ScrollViewer 初值：extent/viewport/scrollable/滚动条`
- `⑤⑥⑦`：ScrollViewer 自身与各级 `ActualHeight`（含左列 5 张卡逐个），用于把"内容总高变了"分摊到具体卡片

```bash
# 自起 Xvfb（按 PID 收尾）+ 默认档清空全部字体 env，只加诊断开关
Xvfb :97 -screen 0 1280x1024x24 -nolisten tcp & XPID=$!
export DISPLAY=:97
( exec env -u WPF_LINUX_FONT_DIR -u WPF_LINUX_UI_FONT WPTD_INPUT_DIAG=1 dotnet WpfTextDemo.dll > app.log 2>&1 ) & APID=$!
# 等窗口 → 注入滚轮（XTest：绝对坐标 + 不带 --window）→ 读 app.log 的四跳 → kill -TERM $APID / $XPID
```

## 波 8（`.wave-done` 16:46）之后的实测读数

```
minrepro（4 档 × 2 次，超时 40s）→ 退出码 1
  default  0/2  blocker=lineservices:LoCreateContext
  env      0/2  blocker=lineservices:LoCreateContext
  degraded 0/2  blocker=lineservices:LoCreateContext（修掉 ItemsSource 触发点之后；此前是 uia:com-marshal）
  minimal  0/2  blocker=lineservices:LoCreateContext（代码构造的 3 个短 TextBlock 也崩）
WPTD_SUMMARY=FAIL tiers_passed=0/2 failed: default env
```

**对照实验（同一台机、同一批产物、默认配置）**：`HelloWpf` **不崩**，有内容帧 2–4 个，
`未画种类 1`（= 已知的"默认配置文字不画"缺陷）⇒ **波 8 没有把文本渲染整体弄坏**；
本样例撞的是**更严重**的一条：部分文本行被拒于快路径 ⇒ `FullTextLine` ⇒ LS ⇒ **abort**。

> ⚠️ 未归因的数据点：波 8 之前，等价的"最小窗口"（XAML 变体）**3/3 通过**；波 8 之后
> 本样例的 `--minimal`（代码构造最小树）**2/2 崩**。两者不是同一个装置（XAML 变体 vs 代码构造），
> 所以**不能**直接判定为回归 —— 已作为数据点报给文本车道。

## P0 修复（AOT 桥重发布）之后的读数 —— 桥 sha `600c885cee03b16a…` / 4,730,864 B

**对照基线（我自己复取，非引用别人）**：默认配置、不设任何字体 env 跑 HelloWpf
→ `未画种类 0`、有内容帧 3–4 个、**PNG 55,913 B / 667×417**；`read_image` 确认
「Hello WPF on Linux」与「Rectangle / Ellipse / Path / Gradient / Transform / Text」**都在屏上**。

**门禁（验收两档 + 诊断两档 ×2）**：仍是红 ——
`default 0/2`、`env 0/2`、`degraded 0/2`、`minimal 0/2`，全部 `blocker=lineservices:LoCreateContext`。
⇒ **P0 修的是"文字不画"，D3（回落 LS → abort）没被它修掉**，两者是不同缺陷。

**边界探测**（`--tier minimal --app-args="--text-volume=N"`，每档 3 次）：

| N（最小树里的文本行数） | 结果 |
|---|---|
| **1** | ✅ **活到超时**（exit=143），有内容帧 `skia 指令 4 条，未画种类 0`，截图 + 读图确认文字在屏 |
| 2 | ❌ 3/3 `LoCreateContext` abort |
| 3 | ❌ 3/3 同上 |

⇒ **触发变量不是"文本总量"，而是"第 2 行"**：1 行能画，2 行必崩。这是给文本车道定位
"何时翻到 `FullTextLine`"的锐利边界。

**输入路径（波 8 修的鼠标崩溃）已在应用级验通**：`--minimal --text-volume=1` 的窗口活着时，
用 `xdotool` 在窗口内竖扫 3 个点各做 move+click →
**3/3 轮次进程存活**，**3/3 轮次应用侧记录到 `[wptd] 事件：MouseEnter（命中 HitCard）`**
⇒ 命中测试 + 事件派发到应用处理器这条链**通了**（完整档/degraded 档活不到注入时刻，未验）。

## 抓帧判据修复后（桥 `9eb4c88c3258307d` / PC `0fad3c19adbc9a19`）

**仪器不再说谎**：`--tier both` 两档都跑到底，`exit=143`、**有效帧 8/8**（旧版单次抓帧 3 次里 2 次全白）。

| 档 | 结果 | 台账 | 截图 |
|---|---|---|---|
| default | FAIL（**真红**） | `skia 指令 180 条`、`未画种类 0` | 938×938、2659 色、77,973 B |
| env | FAIL（**真红**） | `skia 指令 165 条`、`未画种类 0` | 938×938、2377 色 |

**当前 FAIL 的真原因**（都是渲染缺陷，不是仪器）：
- `shapes_tomato=0` —— ⑤ 卡片里那个 `Canvas` 的 `Rectangle/Ellipse/Path` **一个都没画**（卡片只有标题）；
  而 HelloWpf 里**同样的三个图形画得出来**（基线截图可见）⇒ 结构差异值得排查（本样例的图形在
  `Border > StackPanel > Canvas` 里，且在 `ScrollViewer` 内）。
- `image_content_{g,r,b}=0` —— ④ 卡片的 96×96 图**空白**：`BitmapSource.Create` 走的是已知 WIC 缺口
  （降级路径已打印），而**降级成的矢量 `DrawingImage` 同样没画出来**。
- 另有主控已登记的一条（我读图同样确认）：**CJK 全是豆腐块**（`□□□`）。

### D-c 已结案（滚动视口裁剪，**不是渲染缺陷**）—— 门禁已改为"滚动后判定"

T2b 实测（部署件）：三个图形**都在画**，`Rectangle(Tomato) 设备=(62.5,837.8,…)`、`Ellipse(渐变)`、
`Path(SeaGreen)` 三者设备 y≈837，而共同 clip 的底边是 **828** ⇒ **整块被 `ScrollViewer` 视口裁掉**；
⑤ 卡片背景 `786→922.7` 被裁得只剩 42px = **标题那一条** ⇒ 与"卡片只剩标题"完全吻合。

**门禁按主控给的"路线 2"改**（抓帧前先真滚动一次）：
- 滚动用 **XTest 真实指针事件**（`xdotool mousemove <绝对坐标>` + **不带 `--window`** 的 `click 5`）；
  ⚠️ `click --window` 是 **XSendEvent 合成事件**，会被输入路径忽略 ⇒ 表现为"滚动没反应"（实测踩到）。
- 滚动**前/后各留一帧**：`wpftextdemo-<档>-r<N>-before.png` / `-after.png`（前后对比本身就是证据）。
- 判据④ 改成在**滚动前+滚动后所有帧的并集**上判（单看一帧必然假红）；
- 新增**判据⑥"真滚动"**：要求滚动前后画面 AE>0 —— 比原来更严，不是放宽。

实测结果（桥 `0f8f9d76c3d7d259`）：`shapes_tomato=**37620**`（滚动后可见）、`判据⑥ AE=88828` ✅，
⑤ 卡片里的矩形/渐变椭圆/绿三角我**读图确认在屏上**。

### 多行段落"摞印"的准确描述（2026-09-11 主控更正 + M7b 只读测量）

**不是**"首段文字压出边框"。准确说法是：**单行文本全部正常**（`WpfTextDemo`、`Left ·`、
`Item 01`、`detail: bound via ItemsSource (7 ms)` 都清楚），**只有多行（折行）段落整体摞印 ——
行与行压在同一条基线上**（① 卡片正文、② 卡片说明、④ 卡片说明、`ListBox` 的 `detail:` 行）。
M7b 已排除"文字算宽"（行内清楚）与"框算窄"（**没有框的地方同样摞印**）⇒ 指向 **行推进 ≈ 0**。
已派文本度量链（T1b）。定位下一个人请从"行推进"入手。

## 判据（本轮的语义变更）

| 判据 | 现在的语义 |
|---|---|
| ① | 进程存活 + 退出码 143 |
| ② | **`skia 指令 > 0` 且 `未画种类 0`**（取指令数最多的那一帧；空帧下"未画种类 0"是**空真**，不算通过） |
| ③ | **抓到过有效（非单色）帧**；单色帧**只计数、不计入失败**；一张都没有 ⇒ **INCONCLUSIVE**（仪器问题，`WPTD_SUMMARY=INCONCLUSIVE`，与 FAIL 分开） |
| ④ | 逐特性色**存在性**（下限 20 px）：区分"画了/没画"，不是"画得多不多" |
| ⑤ | 裁剪几何自检 + **⑤b 两条独立互证**：①根帧取样（窗口外=根底色 / 窗口内=应用底色）②裁剪帧 vs `xwd -id` 直抓 `AE≈0` |
| ⑥ | **真滚动**：滚动前后最佳帧 `AE>0`（视口外内容必须能滚出来） |

## 本轮在仪器上又抓到的三条"工具在说谎"（都会伪装成应用问题）

1. **并集直方图太慢 ⇒ 整轮超时**：`convert … txt:-` 逐像素转文本实测 **~20 s/帧**（938×938），
   14 帧就是 5 分钟 ⇒ `timeout` 杀掉（退出码 124）。改用 `-format %c histogram:info:-`（~0.2 s/帧），**读数相同**（精确颜色计数，非量化）。
2. **`mawk` 不支持区间量词**：`match($0, /#[0-9A-Fa-f]{6}/)` 恒失败 ⇒ **所有特性色都读成 0**
   （差一点又变成一次假红）。改用 GNU `sed -nE`/`grep -oE`（支持 `{6}`）。
3. **`xdotool click --window` 是合成事件**（XSendEvent）⇒ 输入路径忽略 ⇒ 滚动"没反应"。
   改用 XTest：`mousemove <绝对坐标>` + 不带 `--window` 的 `click 5`。

### 为什么"窗口 620→900"会让 `skia 指令` 145→180（**当时没解释，现在补上**）
加高后 `ListBox` 的可见项从 6 个变成 10 个（截图可见 `Item 07…10`）⇒ 多出若干文本 run ⇒ 指令数上升。
**而"滚动"不改变指令数**（滚动前后都是 180）：`ScrollViewer` 的裁剪**不移除绘制指令**，
它只改变**哪些像素留下来** —— 这正好解释了"画面变了（AE=88828）但指令数不变"。

## `env` 档 vs `default` 档的读数差异（**未归因**）

两档**只差字体 env**（default 清空全部 `WPF_LINUX_*`/`HLWPF_*`；env 加
`WPF_LINUX_FONT_DIR`+`WPF_LINUX_UI_FONT`）。runner 现在每次把读数落盘并做最小对比：

```
default|1|180|0|2659|8|…      env|1|165|0|2377|8|…
WPTD_READINGS_DRAWN default=[180] env=[165]
⇒ 两档（只差字体 env）指令数不同
```

**能确定的只有一件事**：*字体确实影响了绘制指令数*。**不写成**"因为字体不同所以不同"（同义反复）。
可能是折行数不同 / 某段被裁掉 / 字形 run 数不同 —— 需文本车道判读，本 runner 不给因果解释。

## 新增读数（2026-09-11 晚，为"修好了没"服务）

| 读数 | 取法 | 期望 / 判读 |
|---|---|---|
| `image_content_{r,g,b}` | 判据④ 并集（滚动前+后帧） | D-d 修好后应 **> 0**；仍为 0 ⇒ 看 `[cwic-trace]` |
| `[cwic-trace]`（**WIC 路径诊断趟**） | `--wic-image=<png>` + `WPF_LINUX_CWIC_TRACE=1`（**只在诊断趟**） | 期望 `materialize尺寸=96x96 fmt=…c90f`(Bgra32)；**`1x1` + `…c910`(Pbgra32) = 修法没生效** |
| `T1C_CENSUS_SUMMARY` | 调 T1c 装置（`build/MilBridge/tools/t1c-census.sh`，**显式传自己的 DISPLAY**） | `id0≈0 / nonlatin>0 / maxid≈63151` |
| **读图（保留格）** | 人/视觉复核 `*-after.png` | **普查绿 ≠ 像素对**（T1d 已登记这条预测假绿）|
| `win32shim_sha` / `wic_shim_sha` / `hbtextline_shim_sha` | 前两者读 app-local 运行目录；第三者读 `build/shims/PresentationCore.HbTextLine.cs` + `stale` 标志 | `shim_sha` 旧名已废弃（它会让人以为是 WIC shim）；`hbtextline` 每变一次 = 文本行为变了 |

> **本 runner 的 `--wic-image` 腿的实测（当前配置，诊断趟）**：
> `materialize尺寸=1x1 … format=…c910 → SKBitmap=1x1` 而应用自报 `BitmapImage:96x96:Bgra32`
> ⇒ **D-d 在 WIC 路径上独立复现**（与 T2b 的读数一致）。

## 已登记的阻塞

**门禁红着，这是设计意图**：它是下列缺陷的探针，不是失败。

| # | 现象 | 根因（实测） | 车道 |
|---|---|---|---|
| **D3** | `EntryPointNotFoundException: LoCreateContext` → abort(134) | 文本快路径被拒 ⇒ `FullTextLine` ⇒ LineServices；**LS 110 条导出未实现、C++ 不在仓库**。文本越多越必崩，且**间歇** | 文本/PC 面（T1b） |
| **D1** | `AutomationPeer` 路径 `PresentationNative_cor3.dll` DllNotFound | `Win32ShimResolver.cs` 只编进 WindowsBase/PresentationCore，而该 P/Invoke 来自 **UIAutomationTypes**（符号 shim 里齐备）；runner 用 app-local 同名 ELF **止损**（≠修好） | M7b |
| **D2** | `UiaGetReservedMixedAttributeValue` → `MarshalDirectiveException` | COM 接口指针在 Linux 上不可封送（可照 T2 补丁 H 短路） | M7b |
| **D4** | `BitmapSource.Create` → `InvalidOperationException` | WIC / `MILQueryInterface` 墙 | T1（已登记） |
| **D-c**（门禁真红）| `shapes_tomato=0`：⑤ 卡片 `Canvas` 里的 `Rectangle`/`Ellipse`/`Path` **一个都没画**（卡片只剩标题） | **"同一图形在别处能画"**：HelloWpf 里同样的三个图形**画得出来**（`docs/T3-hellowpf-csproj.md` 同款样例基线截图可见）。本样例这三个在 `Border > StackPanel > Canvas`，且整卡在 `ScrollViewer` 内 ⇒ 结构差异是定位起点 | 渲染车道（T2b）|
| **D-d**（门禁真红，**唯一剩下的红**）| `image_content_{g,r,b}=0`：④ 卡片 96×96 图**空白**（滚动后仍然空） | **样例侧输入已自证正确**：应用打印 `WPTD_IMAGE_SOURCE=BitmapSource:**96x96**:Bgra32`（源对象自报尺寸/格式），而渲染侧量到的是 `WIC 句柄 … 物化（**1×1** Bgra8888）` ⇒ **两边读数不一致，问题在 port 的 WIC/物化路径**，不是样例输入 | M7b（已由 T2b 转）|

> 证据（可复核）：`/tmp/wptd-run-994604/wpftextdemo-default-r1.png`（938×938，sha256 `185ec44817c1961a43c71ca558dbf4849bea2ce286fbed52be4294062c21ad9c`）；
> 门禁读数 `drawn=180 notdrawn=0 colors=2659 frames_good=8/8`、`WPTD_ARTIFACTS bridge_sha=9eb4c88c3258307d pc_sha=0fad3c19adbc9a19`。

## 复现要点（别踩）

- **重复 N 次**：D3 是间歇的（小窗口 3/3 过、大窗口 3/3 崩）——单跑一次的结论不可信。
- **产物一致性**：runner 每次打印"样例 bin 快照 vs `build/*.Linux` 权威产物"的哈希表；
  不一致说明撞上了集成波中途的产物，**先等 `build/.wave-done`**。
- **不要用 `--no-build` 掩盖构建问题**；增量构建固定 `-m:1`。
- 自己的显示号：**`:97`**（M7b 用 `:99`、主控复验用 `:98`）；Xvfb 自起自灭、`kill $XPID`。
- `WPTD_RUN_DIR` 默认带 `$$`，并发跑不会互相覆盖截图。
- **每次读数必须带 `WPTD_ARTIFACTS` 行**（AOT 桥/PC/PF/shim 的 sha）——桥是别人重发布的，
  不带 sha 的读数无法与别人的结果对齐。
- **抓帧**：`xwd -root` **连拍**（默认 8 张、间隔 120ms）+ 按窗口几何裁剪 + 取颜色最多的那张；
  首绘由台账信号门控（`skia 指令 N>0`）。单色帧只计数。
- **两个"runner 自伤"已修**（都会伪装成应用崩溃）：
  1. `EXIT` trap 被**后台子 shell 继承** ⇒ 子 shell 退出时把 runner 自己起的 Xvfb 杀掉
     ⇒ 后续档位全在 `CreateWindowEx` 抛 `Win32Exception(1400)`（单跑 env 正常、`--tier both` 第二档 3/3 崩）。
     现在 trap 里加 `BASHPID != $$ 直接 return`，并在每档启动前做 X 存活自检（不可用 ⇒ `RESULT=INCONCLUSIVE`）。
  2. 判据④ 曾经"看不见滚动区外的特性"⇒ 假红：窗口高度 620 → **900**（屏幕 1280×1024），
     让 5 张卡片全在初始视口内（**特性一个没删**，XAML 里有注释说明）。
