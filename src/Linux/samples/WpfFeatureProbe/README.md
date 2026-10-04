# WpfFeatureProbe —— **功能广度样例**（用真 WPF 功能面去撞）

> 车道：`samples/WpfFeatureProbe/**` + `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh`
> 与 `HelloWpf` / `WpfTextDemo` 的区别：那两个覆盖的是**我们自己挑的功能**；
> 本样例刻意去撞**已知薄弱、且过去从未被触发过**的功能面（独立 HWND 的 Popup、动画命令族、
> `OpacityMask`、未验证的 `BlurEffect`、虚拟化、编辑态输入…）。

## 判定形状（**每个功能块都能单独判红/绿**）

- 应用侧：每块**自报一行**台账
  ```
  [feat] <名称> OK|FAIL|INCONCLUSIVE <一句证据>
  ```
  块级 **try/catch** 包住构造与核对 ⇒ 一块抛异常不带走整个应用（否则台账只出一半，分不清"这块坏了"与"全崩了"）。
- runner 侧（`run-wpfprobe.sh`）：
  - 逐块汇总 `WFP_SUMMARY blocks=N ok=… fail=… inconclusive=…`；
  - **像素核对**：每块有自己的**测试色**，在所有帧（滚动前+后）的**并集**上核对 ——
    "没抛异常" ≠ "画出来了"；`opacitymask` 是**负向**判据（黑遮罩 ⇒ 测试色**必须不可见**）；
  - **崩溃分诊**：块级 try/catch 抓不到**原生级崩溃** ⇒ 若有块**没自报**，自动 `--only=<块名>` 逐块复跑，
    把"崩在谁身上"钉出来（分诊结果**单独标注**，不混进主台账）；
  - 三态口径与样例 runner 一致：`PASS` / `FAIL` / `INCONCLUSIVE`（**不把"没自报/抓不到"混成 FAIL**）。

## 判据与仪器：2026-09-13 这一轮改了什么（**每条都带现场证据**）

### 1. `textbox-edit`：精确色对抗锯齿文字**天然不可满足** ⇒ 改近色 + census + 键入腿
- 现场：读图确认 TextBox 内容**就在屏上**（`seed-文本`），但 `#F97316` 的**精确色**像素
  实测 **wave 8 = 16、wave 9 = 0**，两者都 < `MINPX=20` ⇒ 旧判据是**假红**（笔画抗锯齿后
  几乎没有像素恰好等于前景色）。
- 现在三条腿一起判（`EXPECT` 里的 `textbox-edit:F97316:near:input`）：
  - **近色**（`count_color_near`，默认 fuzz 12%）判"颜色对不对"——实测 **8958**（老写法 0）；
  - **census `GlyphRun×N`** 判"字形到底有没有提交给渲染器"——实测 `GlyphRun×7≥1`；
    `NA`（没抓到 census 行）**不据此判红**，避免把"仪器没开"误报成"没画"；
  - **键入腿 `:input`**：`changes>0` 才算"编辑得了"。实测 `changes=0` ⇒ 该块记
    **INCONCLUSIVE**（不是 OK、也不是 FAIL），证据里写明原因 ⇒ **不许用"画得对"冒充"编辑态可用"**（假绿防线）。
- **能红的牙**：把 `Foreground` 改成一个不会出现的颜色 ⇒ 近色计数必须掉到 0 ⇒ 判红（突变自测，见 runner 注释）。

### 2. `anim`：判据去抖（**我自己先造了一个假红，修好了**）
- 老现象：同一配置两次跑，`[feat] anim` 一次 OK、一次 INCONCLUSIVE，日志两行**顺序还相反** ⇒
  机制是"6s 延迟核对在窗口首绘很慢时**先于** `Verify` 触发"，后写的早采判定**覆盖**了晚采的结论。
- 现在：**判定只由 `LateVerify` 一处给出**（与钩子顺序无关），用 `From*/Target*` 常量算
  **推进百分比**（三条腿 ≥80% ⇒ OK；三条 ≤2% ⇒ FAIL"时钟完全没推进"；半途 ⇒ FAIL），
  **NaN/∞ 单列 INCONCLUSIVE**。
- ⚠️ **我改的第一版自己造成了假红**：拿"`BeginAnimation` 之前的属性值"当起点，而
  `Border.Opacity` **默认就是 1.0**、动画是 `0.0→1.0` ⇒ `(1-1)/(1-1)=NaN` ⇒ 掉进"停在半途" ⇒
  `FAIL … (NaN)`。教训一句话：**"仪器算不出" ≠ "被测对象错了"**。修后 3/3 稳定：
  `opacity 0.00→1.00(100%) xform 0.0→40.0(100%) width 40.0→120.0(100%)`。

### 3. `hbtextline_shim_stale` 曾经**按构造恒 `no`**（主控查出的第 17 个"恒真/恒假"）
- 旧写法比的是 `$OUT/PresentationCore.dll`——**刚 cp 的副本**，mtime = 拷贝时刻 ⇒ 源永远"比它旧"。
- 现在对着**权威 PC**（`build/PresentationCore.Linux/bin/Debug/`）比，并在 ARTIFACTS 行**尾部**追加
  `hbtextline_stale_basis=auth|applocal hbtextline_src_mtime=… pc_compare_mtime=…`（前缀字段顺序不动）。
- **牙**：`HBT_STALE_SELFTEST=1` 同时验证两极性（临时文件造，不碰别人的文件）⇒ `PASS`；
  现场真值也是**真能变红**：`stale=yes`（源 `00:36:31` > 权威 PC `00:00:23`）⇒ **应用跑的是旧文本栈**，
  应用级颜色/文本结论只能算临时判定。

### 4. `--only=X` 趟的汇总语义（原来会误导）
- 旧写法把**没被构建**的 8 块记成 `INCONCLUSIVE` ⇒ 汇总行 `ok=1 inconclusive=8`，读起来像"仪器抓不到 8 块"。
  现在记 `skipped`（**不计入 ok/fail/inconclusive**），汇总行加 `skipped=N`；**且 `--only` 趟默认不再逐块分诊**
  （旧行为会白跑 8 次应用、还会把无关块的结论混进同一份日志）⇒ 单块趟从 ~2.5 分钟降到 ~32 秒。

### 5. 站点 D（`HBLINE D#`）：当时"读不到"是因为 PC 里还没有它 —— **但我的查法是错的**
- 当时（2026-09-13 中午）两趟 `HBLINE` 计数 `A=12 C=12 **D=0**`，且 shim 源（`00:36:31`）比权威 PC（`00:00:23`）新
  ⇒ 结论"**D 还没编进产物**"成立。
- ⚠️ **但主控纠正了我的查法**：ASCII `strings … | grep -c 'HBLINE D#'` 对**托管字面量恒为 0**
  （.NET 元数据里的字符串是 **UTF-16LE**）⇒ 必须用 **`strings -el`**。
  同一份产物实测对照：ASCII = **0**、`-el` = **1`。**凡核"某个托管字符串/仪表是否在产物里"，一律 `-el`**
  （`WPF_LINUX_INPUT_TRACE` 同理：当前产物 `-el` 命中 3 处）。
- 集成波重建后（`pc=3479253784172bd4`，`16:16:53`）：`-el` 命中 **1** ⇒ **站点 D 首次进产物**，
  与 `stale=no`（PC `16:16:53` > 源 `00:36:31`）互相印证。

### 6. 撤回一条我自己报的观察：**"同一 TextBox 内拉丁橙 / CJK 蓝"不成立**
- 原始分辨率裁图（像素复制放大，不插值）对照**两趟**：Latin 与 CJK **同为橙色**（存在精确 `(249,115,22)`），
  底是**浅灰选中底** `srgb(199,202,204)`；"蓝"是 800px 预览把细笔画 CJK 下采样后的观感。
- ⇒ H1/H3 无证据、H2（蓝=高亮）也不成立。**教训**：判颜色必须**原始分辨率**裁图，预览图不能当证据。


## ⑩ 纯 RTL（`text-rtl-pure`）：判「双反演还是正确」—— **结论：判不了（缺字形序读数）**

**块的存在理由**：T1d 的只读评估指出 shim 整段一个 HarfBuzz buffer、方向靠 `guess_segment_properties`
猜、`GlyphRun.BidiLevel` 恒 0，而 `'שלום עולם'` 的 `glyphIds` 还原字符是逻辑序的整体反序
⇒ 字形序**已经是 HB 视觉序**。于是：宿主若**又镜像一次**（`Line.cs:79 _mirror=… → InvertAxes`）就是
**甲（双重反演 ⇒ 纯 RTL 也是错的）**；宿主不再镜像就是 **乙（纯 RTL 恰好正确）**。

**这一轮加了什么**（`PureRtlBlock`，**追加为第 10 块，⑨ 的既有读数一个都没动**）：
纯希伯来 `שלום עולם`（`#FF2D95`）、纯阿拉伯 `مرحبا بالعالم`（`#00E5FF`）、带数字 `שלום 123 עולם`（`#ADFF2F`）、
带标点+数字 `مرحبا، 123`（`#C084FC`），外加一条**同字符串、`FlowDirection=LeftToRight`** 的对照行（`#00FF7F`）
—— 它的用途是给「甲/乙」一个**机器判据**：甲 ⇒ RTL 行与 LTR 行**渲染相同**；乙 ⇒ RTL 行是 LTR 行的**水平镜像**。

**读数**（`--only=text-rtl-pure --app-env=WPF_LINUX_HBLINE_TRACE=1`，桥 `e0d01832…` / PC `3479253784172bd4`）
- 站 D（每行**单个** run，face 全为 `DejaVuSans.ttf`，`chars=` 是**逻辑序**）：
  `brush=#FFFF2D95 glyphRuns=1 [r0 … glyphs=9 chars="שלום עולם"]`、`#FF00E5FF … glyphs=13 chars="مرحبا بالعالم"`、
  `#FFADFF2F … glyphs=13 chars="שלום 123 עולם"`、`#FFC084FC … glyphs=10 chars="مرحبا، 123"`。
- 自报：`heW=65.3 heH=16.3 dir=RightToLeft`、`heLTR(w=65.3)` ⇒ **同串同字号，布局宽度一致**。
- **像素实测（精确色）**：RTL 行 `#FF2D95` 只有 **22 px**、x∈[13,35]（**23 px 宽**）；
  LTR 对照行 `#00FF7F` **44 px**、x∈[24,81]（**58 px 宽**）⇒ **同一字符串，RTL 只画出 LTR 的约 40% 宽**。
- 列轮廓比对：`RTL vs LTR` 逐列相同 12/23；`RTL vs flop(LTR)` 6/23 ⇒ **两个签名都不成立**。
- 顺带一条**新异常**（供 RTL 车道）：该块 `WFP_BOXID`（`TransformToAncestor`）报 `65x16+86+39`，
  而**实际字形画在 x=13..35**（那个框内 1040 px **全是底色**）⇒ **布局坐标与绘制坐标差 +73 px**。
  ⇒ 本块像素判据因此改用 `:norect`（整帧计数；它的 5 个色**全局唯一**）。

**结论（三选一，写死）：`判不了`** —— 缺的读数很具体：
1. **shim 输出的字形序**（census `first16` 的 glyphId 序列，或 `A#` 站的逐 run origin/advance）；
2. 或一份**独立整形器参照**（`hb-shape --direction=rtl`；本机现在**没有** `hb-shape`/`pango-view`）。

**不能**写成「看起来还行」：RTL 行的**绘制宽度显著短于**同串 LTR 行（23 vs 58 px），
既不是「相同」（甲）也不是「镜像」（乙），**本身就是需要解释的异常**。


## ⑪ `DispatcherPriority` 四格自测：**"Background 操作不执行"这个假设被读数否掉**

**背景**：输入链已钉到 `ScheduleInput → TextContainer` 插入（见 `textbox-edit` 的 P6a–P6d 读数）。
上游 `TextEditorTyping.ScheduleInput`（`:1569-1591`）在 TextBox（非 RichContent）这一支里，插入挂在
**`Dispatcher.CurrentDispatcher.BeginInvoke(DispatcherPriority.Background, …)`** 上。
主控据"实跑 `pop` 里只见过 `0x8000`/`0x8009`、从没见过 `0x8004`"提出假设：
**Background 优先级的操作在这套 Dispatcher/消息泵上从不执行**。

**做法**（样例自报，不需要任何新开关）：`TextBoxBlock` 在 `Verify()` 里对
`Normal / Input / Background / ContextIdle` 各 `BeginInvoke` 一个置位动作，`LateVerify()`（6s 后）报一行
`WFP_DISPATCH_PRIO normal=… input=… background=… contextidle=…`。

**实测（`--only=textbox-edit --app-env=WPF_LINUX_MSGFLOW_TRACE=1`，pc `f5bb25827621865a` / pf `8c801a3f5ee67f0b` / shim `f84d65a62e0c7fa4`）**
```
WFP_DISPATCH_PRIO normal=True input=True background=True contextidle=True
```
⇒ **四个优先级全都执行了**（连最低的 `ContextIdle` 都跑了 ⇒ 队列根本没有"哪一级饿死"这回事）
⇒ **假设否掉**：不是"Background 操作不执行"，而是**"操作跑了、插入本身失败"**（转 PF 侧的
`BackgroundInputCallback` / `_FlushPendingInputItems` / `TextInputItem.Do` / `DoTextInput` 探针）。

**顺带纠正一条推断链（重要）**：本趟把 `0x8000…0x800f` 逐个计数（托管 `[msg]` 与原生 `[MSGFLOW] pop` 两路）：
```
托管[msg]:       0x8000=74 0x8009=5  其余(含 0x8004)=0
原生[MSGFLOW]pop:0x8000=36 0x8009=5  其余(含 0x8004)=0
```
⇒ shim 的进程队列通知**只用 `0x8000` 一个号**（不是 `WM_APP + priority`），
所以 **"没有 0x8004" 并不能推出"Background 没被投递"** —— 这条推断链本身不成立；
`0x8004` 的缺席是**编码方式**使然，与优先级是否执行无关。**该格由四格标志位直接判，不用消息号猜。**

**下一步往哪查（按读数收窄后的候选）**：① `ScheduleInput` 里那次 `BeginInvoke` **到底发了没有**
（`threadLocalStore.PendingInputItems == null` 分支是否命中；若已非 null，则只 `Add` 而不 `BeginInvoke`
⇒ 没人 flush，这是一个能解释现象的强候选）；② 发了但 `BackgroundInputCallback`/`_FlushPendingInputItems`
没插；③ `TextInputItem.Do`/`DoTextInput` 跑了但 `TextContainer` 插入被前置条件挡掉。


## ⑫ 【重大更正】键入**确实进了 TextBox**（屏幕上就是 `AB`）—— 坏的是 `Text` DP/`TextChanged` 这条**可观测链**

**怎么发现的**（本节的仪器修正 + 读数）：
1. **先修仪器**：探针 runner 原先两趟 burst（`b-*`/`b2-*`）**都在输入注入之前**（源码里 burst 循环在 316/334 行、注入在 347 行）
   ⇒ 我差点用"注入后的帧还是 `seed-文本`"去判"写入被撤销"——**那批帧根本没有证据力**。已加**注入后第三趟 `b3-*`**
   （只存档 + 记颜色数，**不并入 `frame_files`**，不动既有判据）。
2. **`_tb.Text` 时间线**（样例新增 `WFP_TEXTWATCH`，400ms 一 tick，18 条）：
```
WFP_TEXTWATCH t=3738 text='seed-文本' len=7 sel=0,0 changes=0 focused=False
WFP_TEXTWATCH t=4140 text='seed-文本' len=7 sel=0,7 changes=0 focused=True
…（t=10551 之前每 400ms 一条，**全部** text='seed-文本' len=7 changes=0）…
```
3. **注入后帧（原始分辨率读图）**：TextBox 里显示的是 **`AB` + 光标**（不是 `seed-文本`）——
   即 `Ctrl+A` 全选后 `AB` 覆盖了选区，**输入在"用户可见层面"完全生效**。
   同趟证据链齐全：托管出队 `0x0102` ×2、`Q0a/Q0i`（**立即执行支路**，不经 Background 投递）、
   `Q3 TextInputItem.Do() … UiScope=TextBox#2ce2184`、`Q4d SetSelectedText 返回后 len=1 text="A"`、
   `Q3c … 正常返回 len=2 text="AB"`、`P6d 已 ScheduleInput 排队插入`。

**⇒ 结论（更正）**：`TextEditor` 的容器被正确改写（Q3c：`len=2 text="AB"`）且**渲染也跟着变了**（注入后帧 = `AB`），
**唯独 `TextBox.Text`（DP）与 `TextChanged` 一直是旧值**（同一时刻 18 条时间线全是 `'seed-文本'`/`changes=0`）。
⇒ 缺陷位置 = **容器 → `TextBox.Text` DP / `TextChanged` 的通知链**（不是"插入失败"，也不是"打字没到"）。

**⇒ 对我自己判据的更正（必须记）**：`textbox-edit` 的"键入腿"原先用 **`changes>0`**（`TextChanged` 计数）判，
这条**测的是可观测模型、不是"键有没有到控件"**；本次实测它给出的是**假红**（用户看得见 `AB`，判据说"未到达"）。
建议改法（待主控点头）：键入腿改为**像素证据**——比较**注入前后** `WFP_BOXID` 矩形内的字形/内容差异
（例如注入后矩形内出现与注入前不同的字形，或出现光标），`changes>0` 降级为**旁证**而不是判据。


### ⑫ 后续：新口径已落地 + **三极性牙**（实跑读数）

**新口径**（runner 已改）：`textbox-edit` 的键入腿 = **注入前后 `WFP_BOXID` 矩形内"测试色混合线字形像素"
是否变化**（注入后帧 = runner 注入之后补抓的 `b3-*`）；`changes` **只作旁证打印**。
**并且在"像素腿 PASS 但 `Text` DP 陈旧"时该块记 `INCONCLUSIVE`**（不是 PASS）——真应用读 `Text`/绑定 `Text`
会**静默拿旧值**，那是缺陷不是通过。

**实跑（`run-wpfprobe-inputleg-tooth.sh`，三极性一次跑完）**：
```
[empty-rect] 键入腿(像素)=FAIL：FAIL(矩形 240x24+600+600 内字形像素 注入前=0 → 注入后=0：**矩形内没有出现新字形** ⇒ 注入没生效)
[inject]     键入腿(像素)=PASS：PASS(矩形 240x24+21+39 内字形像素 注入前=947 → 注入后=153)
[no-inject]  键入腿(像素)=INCONCLUSIVE(没有注入后帧 b3-* ⇒ 仪器未采样，不能判键入有没有生效)
WFP_INPUTLEG_SELFTEST=PASS（极性①红、极性②绿、极性③ INCONCLUSIVE）
```
**第三极性是这一轮自己抓出来的假红**：我第一版把"没有注入后帧（`WFP_INPUT=0`）"也算成
`g_after=0 ⇒ FAIL` ⇒ **"仪器没采到"被当成"没键入"**。现在这种情形一律 `INCONCLUSIVE`。
（牙的两个负面极性因此改成：**把矩形挪到空白处**（`WFP_BOXID_OVERRIDE` 仅自测用）⇒ FAIL；注入关掉 ⇒ INCONCLUSIVE。）


## ⑬ 纯 RTL 的**干净几何基线**（修法① 的验收对象）—— 判定：**丙（都不是）**

**为什么重做这一格**：上一轮"23 px vs 58 px"是**精确色计数在镜像 CTM 下的抗锯齿产物**，不能当几何结论。
这次用**墨迹口径**（与底色欧氏距离 >40，**不看是否等于测试色**）在**原始分辨率**上量每行的**包络 + 列轮廓**。
方法/工具：`tests/WpfGfx.Linux.Tests/Presentation.Tests/rtl-ink-profile.py`；
机读数据（含元组头）：`samples/WpfFeatureProbe/rtl-baseline-20260913.json`。

**元组（该数据文件头逐字）**：`bridge=e0d01832a3efea53 pc=29a7939cb37152a9 pf=d7e48055e0b98b8a provider=71ba86c6495347fe win32shim=f84d65a62e0c7fa4 wic=03b67fbcd7c385b6 hbtextline=ebccdb1ee65e6f76(stale=no)`
裁图：从 root 连拍帧按窗口几何裁剪，本分析再裁 `470x400+0+0`（即**窗口左上角为原点**）；底色 `#1B2436`。

| 行（同一张卡、同字号、同对齐） | 墨迹包络 | 宽 | 墨迹像素 | 布局框 x | **墨迹 − 布局框 Δx** |
|---|---|---|---|---|---|
| `he_pure_RTL`（`שלום עולם`，RTL） | [12,42] | **31** | 130 | 86 | **−74** |
| `he_same_string_LTR`（**同串**、LTR 对照） | [23,88] | **66** | 260 | 21 | **+2** ✅ |
| `ar_pure_RTL`（`مرحبا بالعالم`） | [18,49] | 32 | 134 | 95 | −77 |
| `he_with_digits_RTL`（`שלום 123 עולם`） | [12,73] | 62 | 253 | 117 | −105 |
| `ar_with_punct_digits_RTL`（`مرحبا، 123`） | [14,45] | 32 | 132 | 89 | −75 |

**判据（主控写死的三选一，同一字符串 RTL vs LTR 对照）**：
```
直接比（RTL vs LTR）        : 逐列相同 1/4   绝对差和 12
翻转后比（RTL vs flop(LTR)）: 逐列相同 0/4   绝对差和 44     ← 翻转**更差**
宽度比                      : RTL 31 / LTR 66 = **0.47**
8 列合并轮廓：
  RTL  [39, 28, 33, 30]
  LTR  [40, 31, 33, 22, 22, 34, 31, 37, 10]
  前 16 列原始值：RTL [8,8,2,2,2,3,8,6,…] ｜ LTR [8,8,2,2,2,3,8,7,…]   ← **前段几乎逐列一致**
```
⇒ **丙（都不是）**：既不是 `RTL ≈ flop(LTR)`（翻转比直接更差），也不是 `RTL ≈ LTR`（宽度只有 47%）。
**差在哪（可复算）**：RTL 那行的墨迹 = **LTR 渲染的前 ~半段**（前 3 个 8 列桶 `39/28/33` vs `40/31/33` 几乎相同，之后 LTR 还有 6 个桶、RTL 没有了）。
旁证很强的一条：`ar_pure_RTL` 与 `ar_with_punct_digits_RTL` 的**列轮廓逐桶相同**（`[44,32,27,31]` vs `[43,32,26,31]`、首末 8 列也同）
——**后加的 `، 123` 一点墨迹都没多** ⇒ 不是"压缩"，而是**只画到某个宽度就停**（≈前半段）。

**另一条独立结论（回答"+73 px 布局↔绘制"到底是不是坐标基问题）**：**不是坐标基问题**。
同一张卡、同一次采样里：**LTR 对照行 Δx = +2 px**（布局框与墨迹吻合），而**四条 RTL 行 Δx = −74…−105 px**
⇒ 偏移**只出现在 RTL 行上**，所以它是 **RTL 专有的"布局位置≠绘制位置"**，不能用"裁图原点/非客户区偏移"解释。
（y 方向五行都是 ≈+11 px 的固定偏移 ⇒ 那一维是**共同**的基线差，另论。）

**对照组（修法① 不会修好，留档防误读）**：`text-rtl`（混合方向那块）现在的墨迹包络：
`y=[42,57] x=[13,152] 宽140`、`y=[62,91] x=[150,460] 宽311`、`y=[130,143] x=[150,415] 宽266`、`y=[146,159] x=[150,200] 宽51`。
⇒ 混合方向仍需要**段落级 UBA**，修法①（纯 RTL 改逻辑序 + `BidiLevel=1`）**不会**把它变对；这一格留档，避免"RTL 全好了"的误读。

**这一格能当修法①的验收基线吗**：**能**。判据对象就是**列轮廓/包络本身**（可复算、与抗锯齿无关、与被测实现无关）：
修法① 落地后预期 `he_pure_RTL` 的包络宽度从 31 → ≈66（与同串 LTR 对照同宽）、`Δx` 从 −74 → ≈+2、
且 `ar_with_punct_digits_RTL` 的轮廓**不再**与 `ar_pure_RTL` 逐桶相同（后加的标点/数字应当产生墨迹）。


### ⑬ 追加：**修法① 之后**的实测与逐条判定（2026-09-13 晚，`pc=6dfacf822e4163bb`）

**元组（数据文件头逐字）**：`bridge=e0d01832a3efea53 pc=6dfacf822e4163bb pf=c08ac77204cc5b80 provider=71ba86c6495347fe win32shim=f84d65a62e0c7fa4 wic=03b67fbcd7c385b6 hbtextline=d116bcb8a34769d8(stale=no)`
数据：`samples/WpfFeatureProbe/rtl-after-fix1-20260913.json`（与修法①前的 `rtl-baseline-20260913.json` **两者都留**）。
⚠️ **本波 `hbtextline` 也变了**（`ebccdb1e… → d116bcb8…`，3816 行）⇒ **跨波比"绝对数值"不等价**：证据是**同串 LTR 对照行自己的轮廓也变了**
（修法①前 `[40,31,33,22,22,34,31,37,10]` → 之后 `[37,35,22,40,21,26,33,28,18]`）⇒ 下面的判定**以同趟对照为准**（宽度比 / Δx），不拿跨波绝对值当依据。

| 行 | 包络 | 宽 | Δx（墨迹−布局框） |
|---|---|---|---|
| `he_pure_RTL` | [13,42] | **30** | **−73** |
| `he_same_string_LTR`（同串对照） | [22,88] | **67** | **+1** ✅ |
| `ar_pure_RTL` | [13,52] | 40 | −82 |
| `he_with_digits_RTL` | [12,73] | 62 | −105 |
| `ar_with_punct_digits_RTL` | [12,46] | 35 | −77 |

**逐条判定（通过/不通过/判不了，三选一）**
| # | 判据（修法①前的预期） | 实测 | 判定 |
|---|---|---|---|
| ① | `he_pure_RTL` 包络宽 **31 → ≈66** | **30**（同趟 LTR 对照 67 ⇒ 比 **0.45**） | **不通过** |
| ② | 其 **Δx −74 → ≈+2** | **−73**（LTR 对照 +1） | **不通过** |
| ③ | `ar_with_punct_digits_RTL` **不再**与 `ar_pure_RTL` 逐桶相同 | 现在**不同**（`[40,53,46,49,31]` vs `[8,33,41,20,21]`）且 ar 宽 32→40、墨迹 134→219 | **通过** |
| ④ | 六项 tline 逐位不变（LTR 语料） | 由 T1d harness 侧给出，实测"逐项相同" | （其侧）通过 |

⇒ **结论：修法① 在"纯希伯来"这条上未达验收（①②不通过：宽度仍是同串 LTR 的 ~45%，Δx 仍 ≈−73 px）；阿拉伯那条有变化（③通过）。**
**不能写"看起来好了"**：`he_pure_RTL` 与同串 LTR 对照在**同一趟、同一帧**里的宽度比 0.45 是硬读数。
**旁证（`HBLINE D#` 原文，字形序/face/brush）**：
```
HBLINE D#0 cpFirst=0 brush=#FFFF2D95 glyphRuns=1 [r0 face=DejaVuSans.ttf glyphs=9  chars="שלום עולם"]
HBLINE D#0 cpFirst=0 brush=#FF00FF7F glyphRuns=1 [r0 face=DejaVuSans.ttf glyphs=9  chars="שלום עולם"]
HBLINE D#0 cpFirst=0 brush=#FF00E5FF glyphRuns=1 [r0 face=DejaVuSans.ttf glyphs=13 chars="مرحبا بالعالم"]
HBLINE D#0 cpFirst=0 brush=#FFADFF2F glyphRuns=1 [r0 face=DejaVuSans.ttf glyphs=13 chars="שלום 123 עולם"]
HBLINE D#0 cpFirst=0 brush=#FFC084FC glyphRuns=1 [r0 face=DejaVuSans.ttf glyphs=10 chars="مرحبا، 123"]
```
**混合方向块（`text-rtl`）现状（对照，修法① 不修它）**：包络 `y=42..57 [12,153] 宽142`、`y=62..91 [150,460] 宽311`、`y=130..143 [150,415] 宽266`、`y=146..159 [150,200] 宽51`。


### ⑬ 再追加：**按 T1d §10.5 新判据重测 + 44 px 定位**（2026-09-13 20:4x，`pc=c43d351639856680`）

数据：`samples/WpfFeatureProbe/rtl-after-fix1b-20260913.json`（含 `slot/t0/t1`、`HBLINE B#` 原文、两趟一致性）。**前两份数据保留**。

**① 噪声底（两次采样）**：rep-a 与 rep-b **逐行完全一致**（包络/宽度/墨迹/8 列轮廓全同）⇒ **噪声底 = 0**。
⇒ 所以上一轮"LTR 对照行的轮廓分布变了"**不是采样噪声**，是那一波（`hbtextline` 变）带来的**真实变化** —— 该口径成立。

**② 44 px 位移的定位（`slot` / `t0` / `t1` 三格，逐字）**
```
text-rtl-pure/he    x=86 y=198 w=65 h=16  slot=0.0,18.0,546.5,20.3   t0=86.3,198.0  t1=21.0,198.0   ← RTL：t0>t1 ⇒ **视觉框被镜像**
text-rtl-pure/heLTR x=21 y=218 w=65 h=16  slot=0.0,38.3,546.5,20.3   t0=21.0,218.3  t1=86.3,218.3   ← LTR 对照：t0<t1 ⇒ 未镜像
```
- **arrange 的槽对两行完全相同**（`slot=0.0,…,546.5`，即被拉伸到整个面板宽）⇒ **槽这一格在本样例里不能区分**（T1d 预设的"槽说 ≈21"不成立）；
- **视觉变换**对 RTL 行确实**镜像**（`t0=86.3 → t1=21.0`，跨度 65.3 与 LTR 相同）⇒ 宿主镜像由我这侧独立复核 ✓；
- 而 RTL 的**墨迹 `[13,42]`（宽 30）落在它自己的视觉框 `[21.0,86.3]` 之外**（左移 8 px 且只有 46% 宽）；
  LTR 对照的墨迹 `[22,88]` **恰好落在**其视觉框 `[21.0,86.3]` 内。
⇒ **位移发生在"绘制/视觉层"（不是 arrange）**：槽相同、视觉框跨度相同且已镜像，但 RTL 的字形没有按它自己的盒子落位。

**③ 新四条判据（写死，替换被证伪的旧①②）**
| # | 判据 | 实测 | 判定 |
|---|---|---|---|
| 1 | 同串 `|Δright| ≤ 2`、`|Δw| ≤ 3`、墨迹比 ∈[0.9,1.1] | `Δright = 42−88 = **−46**`、`Δw = 30−67 = **−37**`、比 **0.46** | **不通过** |
| 2 | `profile(RTL) ≈ reverse(profile(LTR))` 且正序相等不成立（判据1绿后才判） | 判据1未绿 ⇒ **不判** | **未判（前提未满足）** |
| 3 | 整帧非 RTL 行包络/墨迹逐行相同（容差=噪声底） | 两趟逐行全同；跨波差异=真实变化（噪声底 0） | **通过** |
| 4 | 契约离线机读：`ClusterMap` 计数/首值/非降/上界 + 数字锚 | T1d harness 侧（9/9 ✓、数字锚证明数组=逻辑序） | （其侧）通过 |
（**重复采样两趟定噪声底**：0 px —— 已在 ① 写明。）

**④ `HBLINE B#` 的 `pw=/W=/pw-W=` 实测（复核 T1d §10 的静态估计）**
```
len=10 … w=65.2559 inv=1 pw=65.2559 W=65.2559 pw-W=0.0000    ← 纯希伯来（RTL）
len=10 … w=65.2559 inv=0 pw=65.2559 W=65.2559 pw-W=0.0000    ← 同串 LTR 对照
len=14 …             inv=1 pw=73.8486 W=73.8486 pw-W=0.0000   ← 纯阿拉伯（RTL）
len=12 …             inv=1 pw=68.0586 W=68.0586 pw-W=0.0000   ← 阿拉伯+标点数字（RTL）
len=30 … w=546.4800 inv=1 pw=546.4800 W=192.5342 pw-W=353.9458  ← 混合方向那行（pw=整段宽）
```
⇒ **纯 RTL 行 `pw == W` 且 `pw-W = 0.0000`**（不是 T1d 静态估的 `+0.04…+0.55`；那个小正差出现在**别的**行上），
且 `inv=1` 出现在 RTL 行 ✓ ⇒ 反演**确实在下发**，且偏移量=行宽。


## ⑭ `D-P1` 的**最小复现**（`text-dp-min`，**不注入 X 输入**）—— 判定：**`Text` 会更新 ⇒ 现象只在输入链那条路上**

**为什么换仪器**：主控读码后判定 DP 引擎里"三个探针互相矛盾"继续钻性价比低；
先做**不依赖输入注入**的可重复实验，再决定要不要回 DP 引擎。

**块做的事（`samples/WpfFeatureProbe/FeatureBlocks.cs` 的 `TextDpMinBlock`，追加为第 11 块）**：
构造 TextBox → `Text="seed-文本"` → 入树布局 → 等一个 `Dispatcher` 回合 → 记 t1 →
`SelectAll(); SelectedText="A"`（**正是 `DoTextInput` 走的那两个调用**）→ 立刻记 t2 →
再等一个 `Background` 回合记 t3 → 再等 500ms 记 t4。
`sel=`（`_tb.SelectedText`）与 `line0=`（`_tb.GetLineText(0)`）是**容器侧**读数（不读 `Text` DP）。

**实测原文（一趟，`--only=text-dp-min`，元组 `pc=c43d351639856680/pf=e5c6f5a7eeef9b81/wb=8c073fab0da88169/hbtextline=13992b58905d00e0`）**
```
WFP_TEXTDP t1='seed-文本' c1=0 sel=''    line0='seed-文本'
WFP_TEXTDP t2='A'        c2=1 sel='A'   line0='A'
WFP_TEXTDP t3='A'        c3=1 sel='A'   line0='A'
WFP_TEXTDP t4='A'        c4=1 sel='A'   line0='A'
[feat] text-dp-min OK WFP_TEXTDP t4='A' c4=1 sel='A' line0='A'
```
**判定（主控写死的三值）：命中第一支** —— `t2/t3/t4` 都出现 `"A"`，且 `TextChanged` 计数从 0 → 1
⇒ **`Text` DP 会更新、事件也会发** ⇒ **`D-P1` 现象无法用这条路径复现**，
它**只出现在"与输入链结合"的那条路**（即经由 `SetCurrentDeferredValue` 的那次写）。
⇒ 下一步才有意义的方向：追 `SetCurrentDeferredValue` 的**时机/条件**（而不是回 DP 引擎）。
（口径说明：本趟 runner 仍会做它自己的输入注入，但**那发生在 t4 之后**——`c4=1` 说明记录时只发生了本块自己的那次编辑。）


### ⑮ PF 侧镜像探针（M1…M6）那一趟：**命中 cell 1；`M3/M4` 没 fire；纯镜像解释被读数否掉**

元组：`pf=dee475f0bf7175cf pc=c43d351639856680 wb=8c073fab0da88169 hbtextline=13992b58905d00e0 shim=f84d65a62e0c7fa4`；
开关行（原文）：`[INPUT_TRACE] via=WPF_LINUX_INPUT_TRACE pid=835401 —— RTL 镜像读数（只对 TextBlock+RTL；≤200 行）`。
数据：`samples/WpfFeatureProbe/rtl-after-mirrorprobe-20260913.json`（含 M 系列原文；**前三份数据保留**）。

**几何复核**：本趟与上一趟（`go-rtl8a`）**逐行完全相同**（包络/宽/墨迹/轮廓）⇒ 噪声底继续为 0，且**PF 只加读数、渲染未变**。

**M 系列原文（要点）**
```
M1' **推了镜像** MatrixTransform M11=-1 M22=1 OffsetX=65.255859375 OffsetY=0（OffsetX 应当 == 当时 RenderSize.Width）
    当时 TextBlock#397a684 FlowDirection=RightToLeft RenderSize=65.256x16.297      ← 纯希伯来
M1' … OffsetX=73.8486328125 … RenderSize=73.849x16.297                            ← 纯阿拉伯
M1' … OffsetX=96.427734375  … RenderSize=96.428x16.297                            ← 希伯来+数字
M1' … OffsetX=68.05859375   … RenderSize=68.059x16.297                            ← 阿拉伯+标点数字
M1' … OffsetX=546.48        … RenderSize=546.48x16.297                            ← 混合方向那行
M2 **SetLayoutOffset** 传入 offset=(0,17.97) **oldRenderSize=0x0**｜additionalTransform=MatrixTransform M11=-1 M22=1
    OffsetX=65.2559 OffsetY=0｜TextBlock#397a684 …
M5 ApplyMirrorTransform(parentFD=LeftToRight, thisFD=RightToLeft) ⇒ True      ← ×5
M3 = **0 行**   M4 = **0 行**   M1'' = 0 行
```
**四格判定（T1c 写死，从上往下）**：**命中 cell 1** —— `M1'` 的 `OffsetX` **恰好等于当时 `RenderSize.Width`**，`M2` 传入的 `additionalTransform` 与之一致
⇒ **实推变换与报告口径相同** ⇒ 差异在**别处**。
- **cell 4a/4b 无法判**：`M3`（`InternalSetLayoutTransform`）与 `M4`（`GetLayoutClip` 的 `rtlMirror`）**各 0 行**（不是预算问题：M 系列总共只 25 行）⇒ **这两站在这些元素上没被走到 ⇒ 属读数缺口**，建议 T1c 复核站点位置/条件。
- 补充一条：`M2` 的 `oldRenderSize=**0x0**`（首次布局）⇒ 组装点看到的是"没有旧尺寸"的一次性情形，`offset.X=0`。

**"渲染等效变换"的拟合复核（你点名要的那一格）**：**不一致**。
```
LTR 对照墨迹=[22,88]（宽66）｜ RTL 实测=[13,42]（宽29）｜ M1'/B# 的 W=OffsetX=65.2559、元素框左缘 t0=21.0
解释A（元素框内镜像一次） 预测=[19.3,85.3]  ⇒ 与实测差 (6.3, 43.3)
解释B（视觉框镜像 × 局部镜像 = 两次）预测=[88.0,22.0] ⇒ 与实测天差地别
```
**更强的否证**：**RTL 墨迹总量只有 LTR 的 46%**（`119 vs 260`），而**每列墨迹密度几乎相同**（`3.97 vs 3.88 /列`）
⇒ 字形**没有重叠**、而是**整段横向被压到约 45%**（宽 30 vs 67）⇒ **纯镜像（`M11=−1`、无缩放）不可能产生这个几何**。
⇒ 结论：**镜像矩阵本身按契约在下发（M1'/M2/M5 都正常），"45% 横向压缩"来自别处**
（下一批该看的是**绘制时 glyph run 的 x 坐标/advance 与当时的 CTM**，而不是再查镜像中心）。


### ⑯ 位移在哪一层：**命中判据 1 —— `originDIP` 相同、`CTM` 不同 ⇒ 位移在 CTM/视觉层**

用法（**不需要任何产物改动**）：`--only=text-rtl-pure,text-rtl --app-env=WPF_LINUX_MIL_TRACE=1,WPF_LINUX_DRAW_CENSUS=1,WPF_LINUX_GLYPH_CENSUS=1`。
数据：`samples/WpfFeatureProbe/rtl-origin-ctm-20260913.json`（含五行 run 的普查原文）。

**纯 RTL 卡片五行的 glyph run（普查原文，按 devY 定位到那五行）**
| 行 | n | devX | devY | originDIP | CTM |
|---|---|---|---|---|---|
| `he_pure_RTL` | 9 | **−24.594** | 219.822 | **(0.000,12.995)** | [1.0417,0,0,1.0417,**−24.594**,206.286] |
| `he_same_string_LTR` | 9 | **+21.875** | 240.965 | **(0.000,12.995)** | [1.0417,0,0,1.0417,**+21.875**,227.428] |
| `ar_pure_RTL` | 13 | −24.952 | 262.107 | (0.000,12.995) | [1.0417,0,0,1.0417,−24.952,248.571] |
| `he_with_digits_RTL` | 13 | −25.893 | 283.250 | (0.000,12.995) | [1.0417,0,0,1.0417,−25.893,269.713] |
| `ar_with_punct_digits_RTL` | 10 | −24.711 | 304.393 | (0.000,12.995) | [1.0417,0,0,1.0417,−24.711,290.856] |

**判据（互斥，写死）：命中第 1 条** —— RTL 与同串 LTR 的 **`originDIP` 完全相同**（`(0.000,12.995)`，差 = 0 ≤ 2 px），
而 **`CTM` 的平移不同**：`dx = −24.594`(RTL) vs `+21.875`(LTR) ⇒ **Δ = −46.469 px**，与像素实测的 44–46 px 同量级
⇒ **位移在 CTM/视觉层**（不是 `BaselineOrigin`，也不是渲染器取用 origin 之后）。
**几何自洽校验**：用该 CTM 反推 run 的设备跨度 —— RTL：`1.0417·[0,65.256] − 24.594 = [−24.59, 43.37]`（与 T1d 反推的 `[−23.26, 42]` 差 ≈1 px）；
LTR：`1.0417·[0,65.256] + 21.875 = [21.88, 89.86]`（与其墨迹 `[22,88]` 吻合）✓

**两条额外读数（有用的旁证）**：
1. **两条同串 run（RTL 与 LTR）的 glyph id 序列逐位相同**：`first16=1344,1331,1324,1332,3,1337,1324,1331,1332`
   ⇒ **shim 交给两侧的是同一串字形**，RTL 与 LTR 的差别**只在 CTM** ⇒ 视觉顺序问题只能落在"CTM/镜像"或"shim 的序列"其中之一，不会是两者各改一半。
2. **y 方向**：五行 `devY=219.822 / 240.965 / 262.107 / 283.250 / 304.393`，间隔 ≈ `20.3 DIP × 1.0417` ⇒ **无逐行异常**（`devY` 与墨迹 y 区间一一对应）⇒ 那一维是共同基线，**留档、不混进本判据** ✓


### ⑰ 变换溯源那一趟：**判不了（缺读数）—— T2b 的溯源族在当前桥里一行都没有**；全精度 `t0/t1` 已取到

用法（既有开关、无产物改动）：`--only=text-rtl-pure,text-rtl --app-env=WPF_LINUX_DRAW_CENSUS=1,WPF_LINUX_MIL_TRACE=1,WPF_LINUX_GLYPH_CENSUS=1`。
数据：`samples/WpfFeatureProbe/rtl-transformprovenance-20260913.json`（**前五份数据保留**）。

**① 主目标（变换溯源）⇒ 缺读数**：本趟日志里四类可能的名字**全 0 行**
```
TransformProvenance=0  VisualProjection=0  TransformResolver=0  offset=(=0  MilVisualNode=0
```
当前桥 sha = `e0d01832a3efea53`（本趟 `WFP_ARTIFACTS` 实测，与本工程用了很久的那份一致）
⇒ **T2b 的桥侧溯源读数没有出现在正在跑的那份桥里**（可能：开关名不同 / 还没随桥发布）
⇒ **三选一（无句柄／有句柄但静默回退 Identity／矩阵本来就不是镜像）我一条都不判** —— 不拿别的读数凑结论。
**建议**：T2b 给出该读数的**确切开关名**，或确认它是否需要**随桥重发**；开关一到我立刻重跑同一趟。

**② 全精度 `t0/t1`（我的 `ReportBox`，单位 = DIP，窗口坐标系）**
```
text-rtl-pure/he    x=86 y=198 w=65 h=16 slot=0.0000,17.9700,546.4800,20.2969 t0=86.2559,198.0343 t1=21.0000,198.0343 unit=DIP
text-rtl-pure/heLTR x=21 y=218 w=65 h=16 slot=0.0000,38.2669,546.4800,20.2969 t0=21.0000,218.3311 t1=86.2559,218.3311 unit=DIP
```
配合上一趟 `M1'` 的**全精度** `OffsetX=65.255859375`（`RenderSize=65.256x16.297`）：
`W = t1−t0 = 86.2559 − 21.0000 = 65.2559 DIP`，与 `OffsetX` 一致到 F4；
⇒ **`W − t1 = 44.255859 DIP`**（不是 44.256 的近似）⇒ **T2b 那个 0.354 DIP 的缺口不是我这边四舍五入造成的**。

**③ 单位换算与"能不能靠包络闭合"**：墨迹包络是**设备像素**，`ppd = 25/24 = 1.0416667` ⇒
RTL `[13,42] px = [12.48, 40.32] DIP`、LTR `[22,88] px = [21.12, 84.48] DIP` ⇒ 墨迹法 `Δright = 44.16 DIP`，代数值 `44.61024 DIP`。
**但像素法自身的不确定度是 ±1 px ≈ ±0.96 DIP > 0.354 DIP** ⇒ **那个缺口只能靠内部读数闭合**（run 的设备空间 origin / MIL 节点 `offset=(x,y)` 全精度），**用墨迹包络闭合不了**。

**④ 几何**：本趟与上一趟逐行相同（本趟未改任何产物；我只把自己的 `ReportBox` 精度从 F1 提到 F4）⇒ 噪声底仍为 0。


### ⑱ `[VISTRANS]` 那一趟：**命中判据 ② —— 镜像交给了 MIL，但桥没并进 `world`**

用法（既有开关）：`--only=text-rtl-pure,text-rtl --app-env=WPF_LINUX_VISTRANS_TRACE=1,WPF_LINUX_GLYPH_CENSUS=1,WPF_LINUX_DRAW_CENSUS=1`。
桥 sha 实测 **`62afae54937beb92`（4,946,224 B）** —— 与主控给的期望一致（发布目录实读 + `WFP_ARTIFACTS` 两处都对得上）。
数据：`samples/WpfFeatureProbe/rtl-vistrans-20260913.json`（含 26 行 VISTRANS 原文与五行 census）。

**`[VISTRANS]` 里与 RTL 文本相关的 `SetTransform` 行（原文节选）**
```
#5  SetTransform visual=0x20 hTransform=0x21 resKind=MilTransformGroup 原始字段=TransformGroup[children=1]
    解析矩阵=[M11=-1.0000 M12=0.0000 M21=0.0000 M22=1.0000 DX=546.4800 DY=0.0000] 镜像=是 非单位=是
#11 SetTransform visual=0x44 hTransform=0x45 resKind=MilTransformGroup 原始字段=TransformGroup[children=1]
    解析矩阵=[M11=-1.0000 M12=0.0000 M21=0.0000 M22=1.0000 DX=65.2559 DY=0.0000] 镜像=是 非单位=是     ← 纯希伯来
#14 … DX=73.8486 … 镜像=是     #16 … DX=96.4277 … 镜像=是     #18 … DX=68.0586 … 镜像=是
#1  SetTransform visual=0x2 hTransform=0x4 resKind=MilMatrixTransform
    解析矩阵=[M11=1.0417 M12=0 M21=0 M22=1.0417 DX=0 DY=0] 镜像=否        ← 全日志唯一的 MilMatrixTransform 是**纯缩放**
```
**判据（M7b 写死，三选一）：命中 ②**
- ① "该视觉从无 `SetTransform` 行" ⇒ **不成立**（五条 RTL 文本视觉都有 `SetTransform`，且 `镜像=是`）；
- **② "有 `SetTransform` 且矩阵是 `M11=−1` 而 `CTM.m11` 仍是 `+1.0417`" ⇒ 命中** ⇒ **桥收到镜像但没并进 `world` ⇒ 修 `Resources/VisualProjection.cs`**（`TransformResolver.Resolve` / 组装点 `:33-40`）；
- ③ "矩阵本就不是镜像" ⇒ 不成立（`M11=−1.0000`，`DX` 恰等于各行行宽 `65.2559/73.8486/96.4277/68.0586`，与 PF 侧 `M1'` 的 `OffsetX=65.255859375` 一致）。

**同趟复核**：
- 五行 census `CTM` 与上一趟**逐位相同**（RTL `m11=+1.0417, dx=−24.594`；LTR `m11=+1.0417, dx=+21.875`）⇒ 镜像确实**没进** `world`；
- 墨迹包络五行**与基准相同**（`[13,42]/[22,88]/[13,52]/[12,73]/[12,46]`）⇒ 几何没变。

**⚠️ 给 M7b 的一条单点线索**：镜像是以 **`resKind=MilTransformGroup`（`children=1`）** 下发的，
而全日志里唯一的 `MilMatrixTransform` 是纯缩放 ⇒ 解析器**很可能只正确处理 `MilMatrixTransform`、对 `MilTransformGroup` 静默退化**（或没解它的子节点）⇒ 这大概是"一处可修"的那一处。

**⚠️ 本轮一个前提（必须带）**：本趟 `hbtextline_shim_sha=e019db5646217ba0` 且 **`stale=yes`**（shim 源 mtime `1789305622` > 权威 PC `1789305016`）⇒ **文本栈是旧产物**；
桥侧结论不受影响（桥 `62afae54` 是新的、矩阵与 PF 侧数值一致），但**涉及文本行为/度量的读数要带这个前提**。
（`WFP_SRC_STALE=none` 是因为我的那道闸门只看 `build/*.Linux/**`；`build/shims/**` 由 `hbtextline_shim_stale` 单独管——两条互补，这次正好是后者抓到的。）


### ⑲ 新仪表那一趟：**命中甲 —— 镜像在 `累积world` 里、但字形绘制用的 `CTM` 里没有**

用法（既有开关）：`--only=text-rtl-pure,text-rtl --app-env=WPF_LINUX_VISTRANS_TRACE=1,WPF_LINUX_GLYPH_CENSUS=1,WPF_LINUX_DRAW_CENSUS=1`。
**三项校验全过**：`bridge_sha=6d6f5fb08808fede` ✓、`pc_sha=116be62bba708b77` ✓、`hbtextline_shim_stale=no` ✓（文本栈这次是新的）。
数据：`samples/WpfFeatureProbe/rtl-provenance2-20260913.json`。

**① 五行 census 完整行（新增三格逐字）**
```
run#16 n=9  … CTM=[1.0417,0,0,1.0417,-24.594,206.286] 来源=visual=0x00000044 本节点Transform=[-1.00,0.00,0.00,1.00,65.3,0.0] 累积world=[-1.04,0.00,0.00,1.04,89.8,206.3] PushTransform=0x00000048   ← 纯希伯来 RTL
run#17 n=9  … CTM=[1.0417,0,0,1.0417, 21.875,227.428] 来源=visual=0x0000004b 本节点Transform=[ 1.00,0.00,0.00,1.00, 0.0,0.0] 累积world=[ 1.04,0.00,0.00,1.04,21.9,227.4] PushTransform=0x00000048   ← 同串 LTR 对照
run#18 n=13 … CTM=[1.0417,0,0,1.0417,-24.952,248.571] 来源=visual=0x0000004f 本节点Transform=[-1.00,0,0,1.00,73.8,0.0] 累积world=[-1.04,0,0,1.04, 98.8,248.6] PushTransform=0x00000053
run#19 n=13 … CTM=[1.0417,0,0,1.0417,-25.893,269.713] 来源=visual=0x00000056 本节点Transform=[-1.00,0,0,1.00,96.4,0.0] 累积world=[-1.04,0,0,1.04,122.3,269.7] PushTransform=0x0000005a
run#20 n=10 … CTM=[1.0417,0,0,1.0417,-24.711,290.856] 来源=visual=0x0000005d 本节点Transform=[-1.00,0,0,1.00,68.1,0.0] 累积world=[-1.04,0,0,1.04, 92.8,290.9] PushTransform=0x00000061
```
**② VISTRANS 的镜像行**（与上面 `来源=` 逐一对上）：`#11 visual=0x44 … DX=65.2559 镜像=是`、`#14 visual=0x4f … 73.8486`、`#16 visual=0x56 … 96.4277`、`#18 visual=0x5d … 68.0586`（另 `#5 visual=0x20 … 546.48` = 混合方向那行）。

**判据（T2b 写死，三选一）：命中 甲**
- 甲 "`来源=visual=0x44 … 累积world=[-1.00,…]` 而同行 `CTM=[+1.0417,…]`" ⇒ **命中**（四条 RTL run 全部如此）
  ⇒ **丢失在字形绘制路径**：画布矩阵被重设、或字形被画到另一张画布上。
- 乙（来源不是那五个镜像视觉 / world 也无镜像）⇒ 不成立：`来源=` 恰好是 `0x44/0x4f/0x56/0x5d`，与 VISTRANS 的镜像视觉一致，且 `world` 含 `-1.04`。
- 丙（投影时刻 `Resolve` 静默回退单位阵）⇒ 不成立：`本节点Transform` 已是 `[-1,0,0,1,<行宽>,0]`，即投影时刻**解出来了**。

**③ 一条可疑点（给 T2b 的入口）**：五条 run 的 `PushTransform` 句柄里，**LTR 对照与纯希伯来 RTL 都是 `0x48`**
⇒ **同一个 push 句柄却得到不同的 `CTM`** ⇒ 值得从 `PushTransform 0x48` 的 **push/pop 配对**（或"用错画布"）查起。

**④ 几何复核**：五行墨迹包络与基准**逐行相同**（`[13,42]/[22,88]/[13,52]/[12,73]/[12,46]`）⇒ 这次读数没有改变渲染，噪声底 0。

**⚠️ 仪器口径**：主控提到的新缝读数里，census 的 `来源=/本节点Transform=/累积world=` **确实出现（58 行）**；
但 `TransformProvenance`/`子类型=`/`含镜像=` 这三类名字**各 0 行**（可能名字不同、或那一处未随桥发布）⇒ 记在这里，免得下一轮以为"没发生"。

### ⑳ 修法② 验收那一趟：**判据 1 绿 / 判据 2 绿 / 判据 3 绿（无旁及）**

用法：`--only=text-rtl-pure,text-rtl --app-env=WPF_LINUX_GLYPH_CENSUS=1,WPF_LINUX_DRAW_CENSUS=1,WPF_LINUX_VISTRANS_TRACE=1`。
**元组实读**（app-local 发布目录，不誊抄）：`bridge_sha=7dfe964828908437`(4,950,336 B) ✓、`pc_sha=23567d420f0dbbaa` ✓、
`pf_sha=bfb10fe2a01a986b`、`hbtextline_shim_sha=5a04875ae87a294d stale=no`（权威 PC mtime 22:23:05 > shim 源 22:17:44）✓、
`windowsbase_sha=8c073fab0da88169`（= 基线 #5 的 wb，未动）；`exit=143`（runner 主动 kill）、`frames_good=14/14`。
数据：`samples/WpfFeatureProbe/rtl-after-fix2-20260913.json`。

**① 镜像这次进了 `CTM`**（⑲ 时是 `CTM=[+1.0417,…]` 而 `累积world=[−1.04,…]`）
```
run#16 纯希伯来 RTL  devX=89.850  CTM=[-1.0417,0,0,1.0417, 89.850,206.286]  本节点Transform=[-1,…,65.3,0]  累积world=[-1.04,…,89.8,…]
run#17 同串 LTR 对照 devX=21.875  CTM=[ 1.0417,0,0,1.0417, 21.875,227.428]  本节点Transform=[ 1,…, 0.0,0]
run#18 纯阿拉伯 RTL  devX=98.801  CTM=[-1.0417,0,0,1.0417, 98.801,248.571]  本节点Transform=[-1,…,73.8,0]
run#19 希伯来+数字   devX=122.321 CTM=[-1.0417,0,0,1.0417,122.321,269.713]  本节点Transform=[-1,…,96.4,0]
run#20 阿拉伯+标点数字 devX=92.769 CTM=[-1.0417,0,0,1.0417, 92.769,290.856]  本节点Transform=[-1,…,68.1,0]
```
`CTM == 累积world` ✓，且四条 RTL run 都满足 `devX == CTM.dx == 运行框右沿`（左沿 21.831 + 行宽）；⑲ 的 `+1.0417 / −24.594` 那一族**消失** ✓。
`[VISTRANS]` 侧照旧五条 `MilTransformGroup / M11=−1 / DX=546.48, 65.2559, 73.8486, 96.4277, 68.0586`。

**② 判据 1（位置/宽度）绿**：`Δright = 89−88 = 1`（≤2 ✓）、`Δw = 0`（≤3 ✓）、墨迹比 `251/260 = 0.97`（∈[0.9,1.1] ✓）。
T1d 静态预测 `[22.1,90.2]` vs 实测 `[23,89]`（差 ≤1 px）✓；对照行预测 `[21.5,89.6]` vs 实测 `[22,88]` ✓。
（修法① 时是 `Δright=−46, Δw=−37, 比 0.46` —— 红。）

**③ 判据 2（镜像）绿 —— 而且镜像轴是 CTM 先预测、实测落进去的**
- 预测：镜像轴 `x' = 111.75 − x` ⇒ 列坐标 `k = 71.75`。
- 实测（**两侧都允许 ±3 列配准的公平搜索**）：镜像假设 `R[i]↔L[k−i]` 最优 `k=71`，`mean|Δ| = 0.736`（≤1.0 ✓）；
  正序假设 `R[i]↔L[i+m]` 最优 `m=+1`，`mean|Δ| = 1.958` ⇒ **正序相等不成立** ✓（分离 2.7×）。
- 紧裁逐列复核：pink 行 vs **翻转后** green 行 = `0.791`、**46/67 列完全相同**；vs 原样 green 行 = `3.985`、9/67 ⇒ 分离 5.0×。
- ⇒ 胜出的 `k=71` 与预测的 `71.75` 在 ±1 列内一致，**是预测被证实，不是自由拟合**。

**④ 判据 3（旁及）绿 —— 先把"非确定区域"摘出去，再看差异**
- 同串 LTR 对照行（x20-92, y228-243）**逐像素 AE = 0** ✓；混合块全部拉丁/CJK 行 AE = 0 ✓。
- 全窗口逐带 AE（基准 vs 本趟）：只有 `y38-60=2843`、`y60-100=582`、`y205-240=366`、`y240-320=1473` 非 0。
- **同趟内两帧** AE：`y38-60=1477`、`y60-100=582`，其余全 0 ⇒ 这两个带里有一部分是**内容自身就不稳**；
  差异定位到 `x624-721, y72-98` 的**右栏面板**，`y60-100` 的跨趟 582 与趟内 582 相等 ⇒ 该带差异 **100% 是面板**，与修法② 无关。
- 纯 RTL 区（y205-320）趟内 AE=0 ⇒ 那里的读数是确定性的，跨趟差异可归因。
- 混合块里**唯一变化**的行是 RTL 段行（y39-60, x<600, AE=856），变化像素的颜色是 `#A855F7` = **该行自身前景色**（墨迹 107→136 px）
  ⇒ 属修法② 的预期作用面，不是旁及。

**⑤ 混合块（`text-rtl`）现状**：RTL 段行**变了**（预期：修法② 作用在 RTL run 上，不区分块），拉丁/CJK 行未动。
但该行含 LTR 片段（`— RTL `），"混合方向整体正确性"要先有 bidi 分段才能定义 ⇒ **本趟不作正确性声明**（登记，不判缺陷）。
**→ 交叉引用**：用户 2026-09-14 已决定**不开混合方向专项**，该边界登记为 **`KNOWN-DEFECTS.md` D-B1**（状态=范围外/已知边界，含"将来算修好"的判据与红旗）。

**⚠️ 仪器口径（三条，防下一轮误判）**
1. **我自己的判据脚本先造了一个假红**：把 `binned8` 数组用 `v//8*8` 展开 ⇒ 数值全塌成 0/8，打印出 `forward==backward==0.78` 的"判据 2 不成立"。
   改用全分辨率逐列轮廓重算后是 `0.736 vs 1.958` ⇒ **假红来自我的判据代码，不是产物**。
2. 470 宽裁剪对纯 RTL 行够用，但**混合块行被截断**（原来报的 `[393,469]` 里 `469` 就是裁剪右沿）⇒ 混合块一律改 600 宽/全宽口径重测。
3. 本趟 census 行**没有 `PushTransform=` 字段**（全日志 0 行），而 ⑲ 那趟有（`PushTransform=0x48`）⇒ ⑲ 提的"LTR 与 RTL 共用同一个 push 句柄"入口**本趟无法复核**；
   另 `来源=visual=0x43/0x49/…` 是**趟内分配序**，跨趟不可比（⑲ 同位置是 `0x44/0x4b`）。
   **主控裁决（2026-09-13 夜）**：**不为该字段单开一轮** —— 它只是"顺带线索"，`甲/乙/丙` 的判定**不依赖**它（本轮改由 `CTM vs 累积world` 直接判死）；
   由 T2b 在**下一次动那台仪表时顺便恢复**。本条如实记"该入口本轮无法复核、且跨趟 `来源=` 句柄不可比"。
4. 基准趟（`go-rtl8a`）与本趟**不止 PC 变了**（bridge `e0d01832→7dfe9648`、PF `e5c6f5a7→bfb10fe2`）⇒ 跨趟比较只做定性归属。

## 功能块清单（按"最可能撞缺口"排序）

| # | 名称 | 撞什么 | 测试色 | 应用侧证据 | 像素判据 |
|---|---|---|---|---|---|
| ① | `popup` | **独立 HWND**：`Popup` / `ContextMenu` / `ToolTip`（本工程窗口胶水的薄弱处）| `#E5484D` | `IsOpen` / `Child.ActualSize` / `Items.Count` | 主窗口里 anchor 的色 + **runner 记"新增 X 窗口数"**（popup 本体在**另一个窗口**，主窗截图看不到）|
| ② | `anim` | `DoubleAnimation`（`Opacity`/`RenderTransform.X`/`Width`）⇒ `MilCmd*Animate` 一族（**已知有"只解码不渲染"风险**）| `#F5A524` | 动画前后三者的**实测值**（托管时钟是否推进）| 终态可见（色在屏）|
| ③ | `opacitymask` | `PushOpacityMask` | `#8B5CF6`（应**不可见**）/ `#22C55E` | 两个 mask 的挂载 | **正负双向**：`#8B5CF6` 必须 ~0、`#22C55E` 必须 >0 |
| ④ | `effects` | `DropShadowEffect`（已知能画）+ **`BlurEffect`（未验证）** | `#0EA5E9` / `#EC4899` | 两个 Effect 类型 | 两色都在屏 |
| ⑤ | `controls` | `TabControl` / `TreeView` / **`DataGrid`**（容器生成、模板、虚拟化）| `#14B8A6` | items/cols/rows + **容器是否已生成** | tab 内容色在屏 |
| ⑥ | `textbox-edit` | `TextBox` **编辑态**：焦点/光标/选区/`Ctrl+A`/真输入（**输入路径**）| `#F97316` | `IsKeyboardFocused`/`CaretIndex`/`SelectionLength`/`TextChanged` 计数（**含延迟第二次自报**）| 文本色在屏 |
| ⑦ | `virtualize` | `ListBox` 200 项 + `VirtualizingStackPanel`（滚动时容器回收）| `#64748B` | **已实现容器数 ≪ items**（延迟再看一次）| 列表项前景色在屏 |
| ⑧ | `transforms` | `RenderTransform` / `LayoutTransform` / `Clip` / `BitmapCache` | `#EAB308` / `#94A3B8` | 属性类型 | 两色都在屏 |
| ⑩ | `text-rtl-pure` | **纯 RTL**（希伯来/阿拉伯 + 数字/标点）+ 同串 LTR 对照 ⇒ 判双反演 | `#FF2D95`/`#00E5FF`/`#ADFF2F`/`#C084FC`/`#00FF7F` | 四条 RTL 行 + 一条 LTR 对照的文本与宽度 | 五色（`:norect` 整帧；结论见上文「判不了」）|
| ⑨ | `text-rtl` | `FlowDirection=RTL` + 折行 + `TextTrimming`（刚修过的文本链，值得再撞）| `#A855F7` | 属性值 + `ActualHeight`（折行段应 ≈ N 倍行高）| 文本色在屏 |

## 一行命令

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
$R/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh 60                 # 默认档（清空字体 env）
$R/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh 60 --tier both     # 顺带跑字体 env 档
$R/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh 60 --only=popup,anim   # 分诊/单块复现
```

产出：`WFP_ARTIFACTS`（七列配置）、`WFP_RUN …`（逐次读数）、`WFP_SUMMARY`、`WFP_GATE`（0/1/2 = PASS/FAIL/INCONCLUSIVE）、
`WFP_TRIAGE block=… verdict=…`（分诊）、`REAPED_ORPHANS`；截图与逐块表在运行目录（`$OUT/blocks.txt`、`probe-*.png`）。

## 判红之后的**归属裁决**（主控要求：别把样例 bug 记成移植缺陷）

任何一块判红，**先做这三问**，再写结论：

1. **"这段 XAML/C# 在 Windows 上也会这样吗？"** —— 会 ⇒ 是**样例写法问题**（例如我误用了某个 API、
   尺寸给成 0、把控件放在不该放的地方），**记 `ATTRIB=sample`**，并顺手修样例；
2. **"它是不是依赖了我没搭好的前提？"** —— 例如 `TextBox` 要真输入才有 `changes>0`、
   `virtualize` 要滚动后容器才回收、`popup` 需要**独立窗口**这条胶水 —— 前提没搭好 ⇒
   **记 `INCONCLUSIVE reason=…`**（**不许**当成缺陷，也不许当成通过）；
3. 三问都排除了，才记 **`ATTRIB=ours`**（我们的移植缺陷），并附**证据原文**
   （异常类型/日志行/测试色"检出/未检出"的计数）。

**唯一例外（优先级最高）**：**某块能把进程打死**（原生级崩溃，块级 try/catch 抓不到）——
runner 会单独打 `⛔⛔ WFP_CRASH_BLOCK=<块名>`，并附复现命令；**这一类单独醒目报出**，
比"没画出来"严重（它会让**整个应用**不可用）。

## 纪律（与既有 runner 同源，**没有另起一套**）

- 配置七元组**实读 app-local**；判据/INCONCLUSIVE/按 PID 收尾/孤儿精确回收/`root` 连拍+按几何裁剪 —— 与
  `run-wpftextdemo.sh` 同一套做法（那个 runner 已冻结为交付基线，本文件**不改动它**）。
- **只按 PID 收尾**，全文无 `pkill`/`killall`/`kill -f`，并有启动自查（出现即退 2）。
- **测试色只出现在"功能内容"上**，卡片边框一律中性色 —— 否则"测试色"恒在 ⇒ 像素判据变成**恒真的假判据**。
- 失败块必须带证据（异常类型/日志原文/像素读数），**不许只写"不行"**。
- **配置表头与 `run-wpftextdemo.sh` 逐字段逐顺序一致**（`bridge_sha bridge_bytes pc_sha pf_sha provider_sha
  win32shim_sha wic_shim_sha hbtextline_shim_sha hbtextline_shim_stale`）—— 两份读数要能并排放在一起。
