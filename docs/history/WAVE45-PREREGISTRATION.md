# 波 `#45` —— **`D-G50` 的判别仪器**（`nativecombo` 块）＋ 判词记录

> **本波性质**：**仪器波**。只动 `samples/WpfFeatureProbe/**`（新增第 ⑫ 块）与
> `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh`（块名单 ＋ 像素期望）⇒
> **不翻九位、不重冻**（`BASELINESHA=PASS live=ff3990dafa582831` 未动，`#44` 冻结仍有效）。
>
> ⚠️ **落地顺序如实记**：设计判据与决策表**先**写在 `$HOME/w45-prereg-draft.md`（预登记内容逐字见该件），
> 但**落地在探针调试过程中完成**（本波是仪器波，且判据是"读事件行"这一条，不含任何产品行为改动）。
> 这条不按"预登记先落仓"的常规走法**如实声明**，不掩盖。

---

## §1 要回答什么

`D-G50`：真实第三方应用（仓外 hc demo）的"组合框"页**点不开下拉**（鼠标、键盘都不开；无新 X 窗口；箭头不旋转）。
被测件已澄清：该页是 `NativeComboBoxDemo` ⇒ **标准 WPF `ComboBox`**（HandyControl 只套模板）。
⇒ 要分清：**是我方移植的 ComboBox 路径不行**，还是 **HandyControl 套上去的那一层不行**。

**仪器**（仓内、可复算）：`samples/WpfFeatureProbe` 第 ⑫ 块 `nativecombo` —— 标准 `ComboBox` ＋
`DropDownOpened/DropDownClosed/SelectionChanged/KeyDown` 各打一行 `EVT …`（**逐行 flush**）＋
下拉项容器用测试色（关着时屏上没有该色）；外部用 `xdotool` 驱动（`$HOME/w45-nativecombo.sh`）。
块自报：`[feat] nativecombo OK …`；runner 的 `EXPECT` 加 `nativecombo:!7C3AED`（**无人点击时该色不应出现**）。

**判据（先写死）**：点控件中心后若出现 `EVT nativecombo.DropDownOpened` ⇒ **移植的 ComboBox 路径是好的**，
缺口在 HandyControl 的模板/样式层；若一个事件都不出现 ⇒ 缺口在**移植**（回到输入/命中那条线）。

---

## §2 记录（判词）

```
EVT nativecombo.DropDownOpened  ×3        ← 点控件中心 ⇒ **下拉真的开了**
EVT nativecombo.DropDownClosed  ×2
EVT nativecombo.KeyDown=LeftAlt / Escape / Space      ← `Alt+Down` 那条腿也到了控件
EVT nativecombo.SelectionChanged=0
```

**判词：缺口不在 WPF/移植的 ComboBox 路径**（标准 ComboBox 在权威件上点击/键盘都能开下拉），
**在 HandyControl 套上去的那一层**：`ComboBoxBaseStyle.xaml` 的模板（`hc:ToggleBlock` 透明覆盖层 ＋ `TemplatedParent` 双向绑 `IsDropDownOpen`）
＋ `hc:DropDownElement`/`ComboBoxExtend` 样式。

**⏪ 同日更正（复刻组实测）**：上面的判词**只对了一半** —— 复刻 HandyControl 那条模式（透明覆盖层 ＋ `IsHitTestVisible=false` 的 ContentPresenter ＋ `Popup`）后，实测
`EVT hit border` ＋ `overlay=0` ⇒ **点击穿透了那层透明 `Control`** ⇒ 根因是**我方命中测试把"透明填充"判成不命中**（新登记 **`D-G52`**），
而 HandyControl 的 ComboBox 下拉**正是靠那层透明覆盖层**去开的 ⇒ `D-G50` 的根因 = `D-G52`。
（标准 `ComboBox` 能开下拉，是因为它默认模板里的开关是 `ToggleButton` 而不是透明覆盖层 —— 这解释了为什么同一控件"有的能开、有的不能"。）

**下一步（已写进 `KNOWN-DEFECTS.md` 的 `D-G50`）**：在块 ⑫ 里再加一个套上**复刻版 HandyControl 模板**的 ComboBox
（透明 `Control` 覆盖层 ＋ `OnMouseDown`→`IsDropDownOpen` ＋ `Popup` 绑同一 DP），**两极化**判它是模板链还是样式/附加属性。

---

## §3 本波的自伤（全部留档，都不是产品缺陷）

1. **块首版漏 `host.Children.Add(card)`** ⇒ ComboBox 从没被排版（`w=0 h=0`）⇒ 点击无处可落；
   而块照样自报 `OK`、`!7C3AED` 期望也**平凡通过** ⇒ **"自报绿"掩盖了"根本没有载体"**（同族教训第 N 例）。
2. 拿控件坐标连撞三条（已一并登记）：`PointToScreen` 抛 `InvalidOperationException`；`Window.GetWindow(_combo)` 返回 **null**；
   `TransformToAncestor(MainWindow)` 抛 `InvalidOperationException`（`MainWindow` 不是它的祖先）⇒ 最终**逐级向上累加偏移**才算出来。
3. C# 里写了**嵌套双引号**字符串 ⇒ 编译错（与 bash/python 同族陷阱，本波各犯一次）。
4. 构建档与运行档不一致：`dotnet build`（无 `-c`）落 `bin/Debug/net10.0`，而驱动从 `bin/Release/net10.0` 取**旧件** ⇒ 一度以为"块没注册"。
5. 把 **bash 脚本喂给 `python3`**（登记表 `--emit`）⇒ 写出**空文件** ⇒ `DEFREG=NOINFO`；已改回 `bash` 并复绿。

---

## §4 顺带产出的一条读数（缺口代价）

第一次**完整**跑探针（12 块）⇒ `WFP_SUMMARY blocks=12 ok=9 **fail=3**`：`textbox-edit`（键入腿像素 `#F97316=0`）、
`transforms`（`#94A3B8=0`）、`text-rtl`（`#A855F7=0`）⇒ 三块**一直在红而没有任何门禁会喊**
（本波只在末尾追加块 ⇒ 前面块的裁剪框不变 ⇒ **非本波引入**）。已记进 `KNOWN-DEFECTS.md` 的"探针不在门禁里"条目。
