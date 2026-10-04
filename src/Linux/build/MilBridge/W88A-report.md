# W88A 报告 —— `TASK-0207`：**修 `D-G85`**（点选下拉项之后捕获不释放 ⇒ 后续点击被误路由）

> 车道 **W88A**｜2026-09-22 09:52 → 10:16 +0800｜kernel `6.8.0-138-generic`｜`nproc=3`｜loadavg 开工 2.14 → 峰值 5.50 → 收工 1.94
> 复现器 = **现成**判据件 `R-GATE`（`verify-all` 第 `[26]` 步，`bash build/MilBridge/tools/r-gate-step.sh`），**一趟 ≈ 36 s**（不含 pc 重建）
> 诊断依据 = `build/MilBridge/W87A-report.md`（`f1fb2a8894486248`，只读，本件**未重新侦察**）
> 全部读数落 `$HOME/w88a/**`（六趟证据目录 ＋ 三个自有普查器）；零 `pkill`；Xvfb/app 残留 **0**（装置自带私有 Xvfb，跑完自收）

---

## §0 结论（**先说不好听的**）

| 任务书的判据 | 本件实测 | 一句话 |
|---|---|---|
| **M2 单做**是否变绿 | **没变绿**：`FAIL crit=11/13 red=2`，红格与修前**逐格相同** | ⇒ W87A 对**门(ii)** 的判读**没有被证伪**（它自己要求的证伪实验做了，预测成立） |
| **M1** 是否让 `R_GATE=PASS crit=13/13` | **`FAIL crit=12/13 red=1`**：`c11` **转绿**、`c06` 只剩 `L8_comboitem1` | ⚠️ **13/13 没拿到**；且我判定**在"现行判据 ＋ 现行装置"下拿不到**（机制见 §3.4，不是放宽判据能正当解决的） |
| 反极性（还原修法） | `pc` **逐字节回到 `56ee75ced8d6aece`**、`R_GATE` 回到 `11/13 red=2` 且**红格逐字相同** | ✅ 往返闭合 |
| `grep -c 'captured=ComboBox'` 15→**5** | 实测 15 → **8**（合法残留 8 条，逐条归因见 §3.2） | 任务书那个 **5 是算错了**：漏了 `SEQ_combo` 那 2 条与 `L8` 点击前那 1 条（**三条都是"下拉开着时的合法捕获"**） |
| 四腿 `captured=` 全 `null` | `SEQ_lst0=null` ✅｜`SEQ_tb=null` ✅｜`SEQ_combo=ComboBox`（**该腿下拉由这一下点开 ⇒ 合法捕获，c06 自己就豁免它**）｜`L8`：**点击后一条 move 都读不到**（见 §3.4） | 这条判据的**字面要求与它自己的豁免规则冲突**（详见 §3.3） |
| `pc` 必变 / `hbtextline` 必不变 / `win32shim` 不许动 | `pc` `56ee75ced8d6aece → 5aa6361a5ba02991`；`hbtextline_shim` `921ba9c65e9fb3be` 未变；`win32shim` `24e906c194903c8b` 未变 | ✅ 三条都成立 |

**修法落点（一行）**：`MouseDevice.cs` 的 `Capture(null)` 释放分支，在 `mouseInputProvider.ReleaseMouseCapture();`（上游 `:388`）之后补
`ChangeMouseCapture(null, null, CaptureMode.None, timeStamp);` —— 由**新建应用器**注入（上游源码零改动）。

**用户可见的那一半修好了，判据件自己那一格没绿**：连点三下（`SEQ_lst0 → SEQ_tb → SEQ_combo`，`D-G55` 的承重腿）**从"全被 ComboBox 吃掉"变成三下各自都出 EVT**（`c11` 11/13 → 12/13 绿）。剩下那一格是**判据的读法**问题，不是捕获还粘着（§3.4 给了原始行与正控）。

---

## §1 `M2` 单做读数（①，**可证伪实验**）

### 1.1 做法
新建应用器 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-mousecapture-release.py` 的 **`--variant=m2`**：把上游
`HwndMouseInputProvider.cs:730` 的 **门(i)** 由 `if(!IsOurWindow(lParam) && _active)` 改成 `if(!IsOurWindow(lParam))`（**只**去掉 `&& _active`，别的一字不动；原式逐字留在注释里）。生成物 `build/PresentationCore.Linux/HwndMouseInputProvider.Linux.cs` ＋ csproj 接线（`Remove` 上游那条 ＋ `Include` 生成物）。

**接线自证**（`dotnet msbuild -getItem:Compile`，**不读 XML**）：
```
"Identity": "…/upstream/wpf/src/…/InterOp/HwndMouseInputProvider.cs"     ← 上游那条【仍在】的对照：见下
"Identity": "…/build/PresentationCore.Linux/HwndMouseInputProvider.Linux.cs"
```
⚠️ 逐字读屏：M2 态下**上游那条 `HwndMouseInputProvider.cs` 已不在 Compile 项里**（列表里只剩 `IMouseInputProvider.cs`/`MouseDevice.cs`/`Win32MouseDevice.cs` 三个"名字里含 MouseDevice/MouseInputProvider"的旁证行 ＋ 生成物那一条）。

### 1.2 读数（原文）
```
PC_BEFORE=56ee75ced8d6aece      BUILD_RC=0      PC_AFTER=eb5e702a0846c633
R_GATE 仪器 件：win32shim=24e906c194903c8b pc=eb5e702a0846c633 pf=14a780572064af96 wb=2e4e46e539a72cd7 bridge=feef049e9d0e313a probe=6c7c1dd1a5e3225a mem_mb=2035 sabotage=none src=device
R_GATE=FAIL crit=11/13 clicks=11 ok=11 red=2 noinfo=0 popup=1 px_open=19449 sabotage=none win=938x938 src=device fails=c06(L8_comboitem1,SEQ_lst0,SEQ_tb,…),c11(seq-lst0,seq-tb,…)
```
`pc` **确实变了**（`eb5e702a0846c633` ⇒ M2 那段代码真的编进去了），而**红格逐格与修前相同**；普查也逐格相同：

| 量 | 修前（baseline） | M2 单做 |
|---|---|---|
| `captured=ComboBox` / `null` / `TextBox` / `PopupRoot` | 15 / 11 / 1 / **0** | **15 / 11 / 1 / 0**（逐格相同） |
| `L8` 腿（mouse-up 之后） | `ComboBox,ComboBox` | `ComboBox,ComboBox` |
| `SEQ_lst0` / `SEQ_tb`（mouse-up 之后） | `ComboBox` / `ComboBox` | `ComboBox` / `ComboBox` |

### 1.3 判定
> **M2 单做不变绿 ⇒ W87A §5.2 对门 (ii) 的判读没有被证伪。**
> 机制（W87A 已给、本件未再取新证据）：放宽门(i) 之后报出来的 `RawMouseInputReport.InputSource` 仍是**主窗口源**，而那一刻 `_inputSource` 是**弹窗源** ⇒ `MouseDevice.cs:1444-1445` 整段丢掉，`ChangeMouseCapture(null)` 根本不会跑。
> ⚠️ **边界**：本件**没有**直接读到"那条 `CancelCapture` 报告到底有没有被发出去"（那要报告级 `Actions` 插桩 —— 见 §7 `NOINFO`）。所以准确说法是"**M2 不足以修好**"，不是"门(i) 已经放行了报告"。

---

## §2 `M1` 修法逐处 ＋ before/after sha16（②）

### 2.1 落点（**唯一一处**，行号现场读过）
```
上游 upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Input/MouseDevice.cs
:386  else(new)/:387 {                                  ← 释放分支
:388      mouseInputProvider.ReleaseMouseCapture();
:390-392  // If we had capture, the input provider will release it.  That will
          // cause a RawMouseAction.CancelCapture to be processed, which will
          // update our internal states.
:393      success = true;
```
注入后（生成物 `build/PresentationCore.Linux/MouseDevice.Linux.cs`，diff 只有两个 hunk：banner ＋ 这一处 12 行）：
```csharp
                        mouseInputProvider.ReleaseMouseCapture();

                        // ── WPF-on-Linux（D-G85 修法 · 车道 W88A）：**主动要求释放时，当场清托管捕获状态**。
                        //    …（两道门的行号 ＋ 跨窗口机制，逐字见生成物）
                        ChangeMouseCapture(null, null, CaptureMode.None, timeStamp);
```
**为什么是这一处**：`:388` 是全进程**唯一**知道"我们刚刚主动要求了释放"的位置；而清状态的上游实现把它**完全托付给 `WM_CAPTURECHANGED` 回声**，回声要过两道门 —— 门(i) `HwndMouseInputProvider.cs:730`（`_active`）、门(ii) `MouseDevice.cs:1444-1445`（`report.InputSource == _inputSource`）—— **两道门都由"活跃源是弹窗"关上**（W87A §3.2 已定死）。
**语义保全（逐条核过，不是猜）**：
* **幂等**：`ChangeMouseCapture` 首行就是 `if(mouseCapture != _mouseCapture)`（上游 `:1032`）⇒ 回声若真来了，第二次调用是**空操作**；
* **不新增/不删事件**：它与回声路径**同一个函数** ⇒ 一样 `_providerCapture = null`（`:1045`）、摘/挂三个 DP 回调、发 `LostMouseCapture`/`GotMouseCapture`（`:1126`/`:1136`）、`Synchronize()`（`:1144`）；
* 用的是**同一函数作用域**里那个 `int timeStamp = Environment.TickCount;`（上游 `:275`）。

### 2.2 件账（**全部现场算，无手抄**）
| 件 | before | after | 说明 |
|---|---|---|---|
| 新建应用器 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-mousecapture-release.py` | ——（新文件） | **`b13172b944707620`**（385 行 / 20,917 B） | 本件**唯一新增的仓内源文件** |
| 生成物 `build/PresentationCore.Linux/MouseDevice.Linux.cs` | ——（新文件） | **`917d807f43777c49`**（2,340 行 / 111,691 B） | = 上游 2,318 行 **逐字复制** ＋ 12 行注入（+banner 22 行） |
| 生成物 `build/PresentationCore.Linux/HwndMouseInputProvider.Linux.cs` | ——（M2 实验期存在） | **已撤销（不存在）** | M2 只服务 §1 那一趟；缺省变体不留半件 |
| csproj `build/PresentationCore.Linux/PresentationCore.Linux.csproj` | `98d7cddb1eaa8f38`（1,673 行，接线块拆除后） | **`7f3c0acd40acc84b`**（1,679 行） | 接线块 = `:1672-1677` 六行（`Remove` 上游那条 ＋ `Include` 生成物） |
| 权威 `pc` `build/PresentationCore.Linux/bin/Release/PresentationCore.dll` | `56ee75ced8d6aece` | **`5aa6361a5ba02991`**（0 警告 0 错误） | 必变（托管改动） |

**机械证据（应用器自吐）**：锚点命中 **1/1**；生成物 `throw ` / `{` / `}` **三种计数与上游逐字相同**（注入不改控制流）；`--check` **rc=0**（只读，`内容已是最新` ＋ `csproj 已就位`）。
**幂等/往返证**：`--variant=m1` → `--variant=none` → `--variant=m1` ⇒ csproj 与生成物**逐字节回到同两个 sha16**（`7f3c0acd40acc84b` / `917d807f43777c49`）；`pc` 两趟重建（M1 三次）也逐字节相同（`eb452af9a1c1cfae` ×2、`5aa6361a5ba02991`）。
**`pc` 与当前生成物同步 ＋ 编译确定性（第三条独立证据）**：`GEN=917d807f43777c49` 的 mtime **比 `pc` 新**（`1790043115 > 1790043043`）⇒ 强制重编一趟（`0 警告 0 错误`，19.9 s）⇒ `PC_BEFORE=5aa6361a5ba02991 → PC_AFTER=5aa6361a5ba02991`（**逐字节不变**）。
**未碰**：`upstream/**`（零改动 —— 注入只发生在生成物）、`src/WpfGfx.Linux.Native/src/**`、`build/shims/**`、`build/PresentationFramework.Linux/**`、`build/DirectWrite.Linux/**`、`build/MilBridge/tools/**`、四个路由件、`defect-registry-declared.tsv`、`verify-all.sh`、`integration-wave.sh`、`close-wave.sh`。

---

## §3 成对判据读数（③）

### 3.1 六趟机读行（**同一命令**，全部在 `~/heavy-slot.sh --min-avail 1500 --max-hold 220` 内）

| # | 变体 | `pc` before → after | `R_GATE=` 机读行（红格原文） |
|---|---|---|---|
| 0 | （无变体＝上游原样，**基线**） | 未重建（`56ee75ced8d6aece`） | `FAIL crit=11/13 clicks=11 ok=11 red=2 noinfo=0 … fails=c06(L8_comboitem1,SEQ_lst0,SEQ_tb,…),c11(seq-lst0,seq-tb,…)` |
| 1 | **m2**（可证伪实验） | `56ee75ced8d6aece` → `eb5e702a0846c633` | `FAIL crit=11/13 … red=2`（与 #0 **逐格相同**） |
| 2 | **m1** | `eb5e702a0846c633` → `eb452af9a1c1cfae` | `FAIL crit=12/13 … red=1 noinfo=0 … fails=c06(L8_comboitem1,…)` |
| 3 | **none**（反极性＝还原修法） | `eb452af9a1c1cfae` → **`56ee75ced8d6aece`（逐字节）** | `FAIL crit=11/13 … red=2`（与 #0 **逐格相同**） |
| 4 | **m1 重复**（可复现性） | `56ee75ced8d6aece` → `eb452af9a1c1cfae`（逐字节） | `FAIL crit=12/13 … red=1`（与 #2 **逐格相同**） |
| 5 | **m1 终态**（生成物去掉多余空行后重建） | `eb452af9a1c1cfae` → **`5aa6361a5ba02991`** | `FAIL crit=12/13 … red=1`（与 #2/#4 **逐格相同**） |

> ⇔ **判据不是恒红、也不是恒绿**：同一趟里 `c01..c05,c07..c10,c12,c13` 恒为 PASS（#0 已 11 格），修法只把 **`c11`** 那一格翻绿。
> ⇔ **跨 `pf` 版本不变**：本件六个读数落在 **3 个 `pf` 字节版本**（`14a780572064af96` / `2a5b7641f6fba0fb`，且我开工前量到第三个 `78218dd1851d41e8`）上，**红格逐格相同**（`pf` 是**另一条车道 W86A** 在重建，不是本件动它）。

### 3.2 `captured=` 普查（任务书要的那条口径，`grep -ao 'captured=[A-Za-z_.]*' app.log | sort | uniq -c`）

| 量 | #0 基线 | #1 M2 | #2/#5 **M1** | #3 还原 |
|---|---|---|---|---|
| `captured=ComboBox` | **15** | 15 | **8** | **15** |
| `captured=null` | 11 | 11 | **17** | 11 |
| `captured=TextBox` | 1 | 1 | **2** | 1 |
| `captured=PopupRoot` | **0** | 0 | **0** | 0 |
| `EVT combo.down`（误路由的指纹） | **7** | 7 | **5** | 7 |
| `EVT lst.down` / `EVT tb.focus` | 1 / 1 | 1 / 1 | **2 / 2** | 1 / 1 |

**8 条残留逐条归因（一条不漏）** —— 判据件自己的"下拉还开着 ⇒ 豁免"口径：

| 腿 | 条数 | 那一刻下拉的状态 | 合法？ |
|---|---|---|---|
| `L6_combo` | 2 | 本腿点开、**腿末仍开着** | ✅ 合法（WPF 语义：开着时 `ComboBox` 持有捕获） |
| `L7_combo_blank` | 1 | 腿首（**点之前**）开着 | ✅ 合法 |
| `L6b_combo_reopen` | 2 | 本腿重开、腿末仍开着 | ✅ 合法 |
| `L8_comboitem1` | 1 | 腿首（**点之前**）开着 | ✅ 合法 —— **这一条正是 §3.4 的成因** |
| `SEQ_combo` | 2 | 本腿点开、腿末仍开着 | ✅ 合法（c06 也豁免它） |

⇒ **没有任何一条是"mouse-up 之后、下拉已关却仍 `captured≠null`"**（§3.3 用"mouse-up 之后"这一更贴判据意图的口径逐腿复核）。

### 3.3 `c06` 的**意图口径**逐腿复核（本件自有普查器 `~/w88a/tools/postup.sh`）

口径 = 该腿切片里**最后一条 mouse-up（`msg=0x0202`）之后**的 `captured=`（＝ c06 注释逐字写的"mouse-up **之后**那一下挪动"）：

| 腿 | #0 基线（mouse-up 之后） | **M1 终态** |
|---|---|---|
| `L1_outside` / `L2_blank` / `L3_lst1` / `L4_tb` | `null` | `null` ✅ |
| `L6_combo` | `ComboBox`（**下拉本腿内仍开 ⇒ 合法**） | `ComboBox`（同）✅ |
| `L7_combo_blank` | `null` | `null` ✅ |
| `L6b_combo_reopen` | `ComboBox`（打开着 ⇒ 合法） | `ComboBox`（同）✅ |
| **`L8_comboitem1`** | **`ComboBox` ✗（粘住）** | **⚠️ 一条 move 都读不到**（§3.4） |
| **`SEQ_lst0`** | **`ComboBox` ✗** | **`null`** ✅ |
| **`SEQ_tb`** | **`ComboBox` ✗** | **`null`** ✅ |
| `SEQ_combo` | `ComboBox`（本腿点开 ⇒ 合法） | `ComboBox`（同）✅ |

⇒ 按 c06 的**意图**，M1 之后**唯一的非绿格是 `L8`，而它是"读不到"，不是"读到了错的值"**。

### 3.4 ⚠️ `c06` 的 `L8` 残余红：**机制与原始行**（**这是本件最要紧的一节**）

**判据怎么读**（`r-gate-step.sh` 的 `c06`）：
```bash
if printf '%s' "$S" | grep -aE '^EVT move ' | tail -1 | grep -q 'captured=null'; then ncap++ else stuck="$stuck$id " fi
```
即"**该腿切片里最后一条 `EVT move`**"必须 `captured=null`。`EVT move` 是**探针挂在主窗口卡片上的 `card.MouseMove`** 打出来的（`samples/WpfFeatureProbe/FeatureBlocks.cs:1220-1227`）——**只有路由到主窗口卡片的路由事件才会打**。

**同一腿、同一装置、同一坐标，两棵树并排（`app.log` 原文，行号 = 各自那趟）**：

| | #0 基线（粘住） | #5 **M1 终态** |
|---|---|---|
| 点击【前】那条 move | `644: EVT move root=124,35 src=Border … freshhit=Border captured=ComboBox` | `585: EVT move root=124,35 src=Border … freshhit=Border captured=ComboBox`（**切片里唯一一条**） |
| 按下 / 抬起（都在**弹窗窗口**上） | `656: [msg] hwnd=0x200008 msg=0x0201` ／ `661: … msg=0x0202` | `597: [msg] hwnd=0x200008 msg=0x0201` ／ `604: … msg=0x0202` |
| 选项选中 | `662: EVT combo.selection=1` | `605: EVT combo.selection=1` |
| **释放回声**（在**本切片之内**） | `664: [msg] hwnd=0x200005 msg=0x0215 wp=0x0 lp=0x0` | `607: [msg] hwnd=0x200005 msg=0x0215 wp=0x0 lp=0x0` |
| `EVT combo.up` | `665` | `608` |
| **mouse-up 之后的 move** | `670: EVT move root=126,35 src=ComboBox … captured=ComboBox`（＝ 2px 挪动）<br>`675: EVT move root=290,216 src=ComboBox … **freshhit=null** captured=ComboBox` | **没有任何 `EVT move`** |
| `EVT combo.closed` | `683` | `624` |

**三条读数把这件事钉死**：

1. **释放确实发生在本切片之内，而且 M1 的注入行无条件跟着跑**：
   `607` 这条 `0x0215` 只可能由 shim 的 `ReleaseCapture()` 产生（`win32_core.c:1468`；W87A §2.1 已把"唯一来源"定死）⇒ `SafeNativeMethods.ReleaseCapture()`（`HwndMouseInputProvider.cs:190`）返回 ⇒ 上游 `MouseDevice.cs:388` 那句 `mouseInputProvider.ReleaseMouseCapture();` 返回 ⇒ **紧挨着的 `ChangeMouseCapture(null,…)` 执行**（同一分支、同一语句块、中间**没有**任何条件）。
   ⚠️ 注意：`mouseInputProvider` 若为 `null`，`:388` 根本不会被调用 ⇒ **这一条 `0x0215` 的存在本身就反证了 `mouseInputProvider != null`**。
2. **`L8` 腿 mouse-up 之后那条 move 在 M1 树上"读不到"，原因不是"捕获还粘着"，恰恰是"捕获不再粘着"**：
   * 那一下 2px 挪动发生在**弹窗窗口**上（弹窗此时仍映射着）；基线里它之所以能在主窗口卡片上打出 `EVT move`，**唯一原因是捕获粘在 ComboBox 上、把这次 move 强行路由给了主窗口里的 ComboBox**（`670` 的 `src=ComboBox`）；
   * 基线 `675` 给了一个**正控**：同一个物理挪动落到主窗口坐标 `root=290,216`，而**当场重算的 `freshhit=null`**（那个点下面**没有任何视觉**）—— 它在基线上**照样**被打进 ComboBox（`captured=ComboBox`），这正是 `D-G85` 的签名（**路由与命中测试分叉**）；M1 之后捕获为空 ⇒ 这个"下面没有视觉"的点**不会**路由到卡片 ⇒ `card.MouseMove` **不打** ⇒ 切片里就没有 mouse-up 之后的 `EVT move` 可读。
   * ⇒ 判据于是回退去读**点击之前**那条（`585`，`captured=ComboBox`）—— 而那条读数是**合法的**（那一刻下拉正开着、`ComboBox` 持有捕获是 WPF 语义，`c06` 的豁免规则本来就想放过这种情况）。
3. **同趟的"下游"读数全绿**：紧接着的 `SEQ_lst0`（mouse-up 之后 `null`）、`SEQ_tb`（`null`）与 `c11` 三下各自出 EVT，说明捕获**已经**清掉了。

**判定**：
> `c06` 的 `L8` 残余红 **是判据/装置域的读数空洞，不是"捕获仍粘在 ComboBox"**。判据那条规则隐含一个前提——"每条非豁免点击腿，mouse-up 之后都有一条**主窗口卡片看得见**的 move"——而这个前提**恰好在"点弹窗项"这条腿上不成立**：那一腿的挪动落在**弹窗窗口**上。**修前它成立，只是因为缺陷本身把 move 强行路由给了主窗口的 ComboBox**（换句话说：**这一格在修好之后才变得"看不见"**）。
> ⚠️ **我把"哪一侧"的诚实边界也写在这里**：`Mouse.Captured` 在 `EVT combo.closed` 那一刻的**直读**本件**没有**（探针只在 `card.MouseMove` 上打 `captured=`）⇒ 这一节是 **"原始行 ＋ 无条件顺序 ＋ 正控"三者合成的机制判定**，不是仪器直读。要把它变成直读，见 §7 `NOINFO` 第 1 条（改法一步到位）。

**`13/13` 能不能拿到？我的判断：不能（在不动判据/装置的前提下）。** 三种"能绿"的路子都不正当或不可行：
1. **放宽 c06**（例如改成"没读到 move 就当通过"）＝ 把判据改松，**明令禁止**，而且会把 `D-G55` 那族真缺陷一起放走；
2. **改判定为 `NOINFO`**：判据件的三态铁律是"无红但判不了 ⇒ `NOINFO` ⇒ rc=2"，**门禁里同样是 ❌**，拿不到 `PASS`；
3. **让 `ComboBox` 开下拉时不取捕获**（那样 `L8` 切片里点击前那条 move 也会读成 `null`）⇒ 直接**打坏 `c07/c10` 的语义**（`ComboBox.cs:1700-1703` 逐字要求"捕获期间弹窗上的点击落到弹窗"），是**反向修法**。
⇒ 要真拿到 `13/13`，必须**加强仪器**（见 §7 第 1 条：给探针补一条 mouse-up 之后的 `captured=` 直读），而不是动判据。**这超出本件写域**（探针 `samples/WpfFeatureProbe/**` 是共享装置，判据件在 `build/MilBridge/tools/**`），**我没有动它们**。

### 3.5 防过修（反向腿，逐条核过）
* `L7_combo_blank` **仍释放**（mouse-up 之后 `null`）✅；`c07/c08/c09/c10/c12/c13` **仍全 PASS** ✅；
* `EVT lst.selection=1`（1）、`EVT tb.focus`（1→**2**）、`EVT combo.opened`（3）、`EVT combo.selection=1`（1）、`EVT combo.closed`（2）**都没掉** ✅（`tb.focus` 与 `lst.down` 各 +1 正是"误路由被修好"的正向证据）；
* `captured=PopupRoot` **仍为 0**（`L8` 没有变成"捕获粘在已销毁弹窗"）✅；
* 判据件自身：`bash build/MilBridge/tools/r-gate-step.sh --selftest` ⇒ **`R_GATE_SELFTEST=PASS cases=21 pass=21 fail=0 crit_total=13`**（`ST_ATTEST=PASS … sha16=f263341ad376d51f`，与 W87A 记录同值 ⇒ 判据件**一字未动**）✅。

### 3.6 世代位
`pc` **必变**：`56ee75ced8d6aece` → **`5aa6361a5ba02991`**｜`hbtextline_shim` **未变** `921ba9c65e9fb3be`｜`win32shim` **未变** `24e906c194903c8b`（另一条车道在用它的写域，我零改动）｜`bridge feef049e9d0e313a`／`windowsbase 2e4e46e539a72cd7`／`provider 1f9511a7ef395bfe`／`wic_shim f7b3026c8c019be2`／`dwf de2d555105b7d04b` 全未变。
`inputs_fp`：`c3ed9925268a52101f56eb376e3ca4635eee15509dc0a515dd443a87e03af76a` → **`0a9cb8b7a2e2493cfa343657635169810e41835550fbf05b036c59274afc5615`**。
**唯一原因机器证**（把本件的新应用器暂时移出覆盖面，用同一 `fp_inputs()` 重算）：
```
inputs_fp(不含本件) = c3ed9925268a52101f56eb376e3ca4635eee15509dc0a515dd443a87e03af76a   ← 与开工前逐字相同
inputs_fp(含本件)   = 0a9cb8b7a2e2493cfa343657635169810e41835550fbf05b036c59274afc5615
```
⇒ 覆盖面里**只有**新增的这个应用器动了（生成物与 csproj 都**不在** `fp_inputs()` 的覆盖面内）。`pf` 的位移（`78218dd1851d41e8 → 14a780572064af96 → 2a5b7641f6fba0fb`）**不是我**：是另一条车道在重建 `PresentationFramework`（§3.1 的红格跨这三个版本逐格相同）。

---

## §4 反极性（④：还原修法 ⇒ 必须回到 `11/13`）

`--variant=none` ＝ **拆掉接线块 ＋ 删掉生成物**（回到"上游原样"，不留半件）：
```
PC_BEFORE=eb452af9a1c1cfae   BUILD_RC=0   PC_AFTER=56ee75ced8d6aece     ← 与基线【逐字节相同】
R_GATE=FAIL crit=11/13 clicks=11 ok=11 red=2 noinfo=0 … fails=c06(L8_comboitem1,SEQ_lst0,SEQ_tb,…),c11(seq-lst0,seq-tb,…)
```
* **`pc` 逐字节回到 `56ee75ced8d6aece`**（＝基线值，两次独立重建得到同一个 sha）⇒ "**是修法（不是别的什么）造成了差异**"这条被机器证明；
* 红格与基线**逐字相同**（`c06` 三条腿 ＋ `c11` 两格）；普查回到 `15/11/1/0`、`EVT combo.down` 回到 7、`lst.down`/`tb.focus` 回到 1/1；
* 往返闭合：`none` →（`m1` 重落地）⇒ `pc` 又回到 `eb452af9a1c1cfae`（再由"终态"那趟给出 `5aa6361a5ba02991`）。
* **应用器幂等**：`m1 → none → m1` 的 csproj 与生成物 sha16 **逐字节回到原值**（§2.2）。

---

## §5 同趟查（W87A 点名的两处，**只读**）

### 5.1 `Popup` 的**再捕获**支 —— **本趟实测未触发**（且机制上不会触发）
* 现场：**`captured=PopupRoot` 在 M1 三趟里 = 0/0/0**（普查口径同 §3.2）⇒ 没有"把粘在 ComboBox 换成粘在 PopupRoot"。
* 机制（上游行号现场读过）：`Popup.cs:48` 是 **`RegisterClassHandler(typeof(Popup), Mouse.LostMouseCaptureEvent, OnLostMouseCapture)`** —— **类处理器只在事件路由经过 `Popup` 元素时才跑**。M1 触发的 `LostMouseCapture` 的 `Source` 是 **`ComboBox`**（`MouseDevice.cs:1126` → `Source = oldMouseCapture`），而 `ComboBox` 的路由是**向上**走的；`Popup` 是它在模板里的**后代**、**不在路由上** ⇒ `OnLostMouseCapture` 那条 `reestablishCapture = e.OriginalSource != root && Mouse.Captured == null && GetNativeCapture() == IntPtr.Zero`（`Popup.cs:1233`）**根本不会被求值**。
* 对照条件（若真被求值会怎样，逐条读代码）：那一刻 `Mouse.Captured == null` **成立**（M1 刚清）、`GetCapture() == IntPtr.Zero` **成立**（`607` 那条 `0x0215 lp=0` 证明 shim 侧已释放）⇒ 若路由经过 `Popup`，它**会**调 `EstablishPopupCapture()`（`:1179`）而在 `StaysOpen==false` ＋ `capturedElement==null` 时 `Mouse.Capture(_popupRoot, SubTree)`（`:1168-1174`）⇒ **就会变成"粘在 PopupRoot"**。**本趟实测为 0 次 ⇒ 这条风险在本现场不成立**，但它**依赖"事件路由不经过 Popup"这件事**（上游语义，不是我们的实现）—— 若将来 `Popup` 改为订阅 `Mouse.LostMouseCaptureEvent` 且挂在更外层，这个结论要重取。
* 另外 `ReleasePopupCapture()`（`Popup.cs:1181-1202`）只在 `Mouse.Captured == _popupRoot` 时动作，而 `CaptureEngaged` 从未置位（`ComboBox.cs:220` 先拿了捕获 ⇒ `:1139/1168` 的 `capturedElement == null` 不成立）⇒ 这条支**也是空的**。

### 5.2 `DestroyWindow` 不清捕获（`D-G86`，**只读**核，未改 native）
```
src/WpfGfx.Linux.Native/src/win32_core.c:946-984  BOOL DestroyWindow(HWND hwnd)
```
通读：派发 `WM_DESTROY`(`:965`)/`WM_NCDESTROY`(`:966`) → 清定时器 → `wpf_x11_destroy_window` → `wpf_window_remove`；**既不读也不清 `g_capture_window`，也不派发 `WM_CAPTURECHANGED`**。
**它对本件的意义（如实划界）**：
* 本趟弹窗**从未持有捕获**（`g_capture_window` 全场只有主窗口；`0x0215` 全 `lp=0`；M1 之后 `PopupRoot` 0 次）⇒ **M1 没有把"粘在 ComboBox"换成"粘在已销毁弹窗"** —— 这一条**实测排除**，不是推断；
* 但**结构性欠账仍在**：若哪天弹窗真持有捕获，`DestroyWindow` 之后 `g_capture_window` 会指向已被 `wpf_window_remove` 摘掉的 XID，而 `wpf_dispatch_to_window`（`win32_msg.c:512-528`）查不到窗口就退 `DefWindowProcW` ⇒ **后续"释放回声"会静默掉进空处**。这与 `D-G86` 的登记一致；**本件按任务书只读核 ＋ 写进报告，未改 native**。

---

## §6 应用器形态、自证与**登记**（照仓内既有形态办）

### 6.1 形态（抄 `patch-presentationcore-lineheight-trace.py` 那一族的骨架，逐条对得上）
① 生成物 = 上游**逐字复制** ＋ 定点插入；② 锚点必须**恰好 1 次**，否则**报错退出**（不静默产出未打补丁的副本）；③ 无参运行 = **真落地**（写生成物 ＋ csproj 接线），**幂等**；`--check` **只读**（本件实测：`--check` 在未落地时 rc=1、已落地时 rc=0，且**不写任何文件**）；④ banner 里写明生成脚本名与理由（审计 B 级口径）；⑤ 结束打印 `dotnet msbuild -getItem:Compile` 的自证命令；⑥ **未被选中的变体一律撤销**（拆接线 ＋ 删生成物）⇒ 不留半件。

### 6.2 自证读数（全部现场跑）
```
python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-mousecapture-release.py --check        ⇒ rc=0
bash build/check-appliers.sh                                                                        ⇒ APPLIER_AUDIT_SUMMARY appliers=26 ok=89 miss=0 red=0 rc=0
bash build/MilBridge/tools/r-gate-step.sh --selftest                                                ⇒ R_GATE_SELFTEST=PASS cases=21 pass=21 fail=0
dotnet msbuild … -getItem:Compile -p:Configuration=Release                                          ⇒ 上游 MouseDevice.cs 消失、生成物那一条在（§1.1 逐字）
```

### 6.3 ⚠️ **登记：我没有登记**（**报告里给出逐字文本，请主控落**）
任务书要求"注册进 `APPLIERS_EXPLICIT` ＋ `applier-audit-expected.txt`"，但**后者位于 `build/MilBridge/tools/**`，是本件任务书明列的"不许碰"**；前者所在的 `build/integration-wave.sh` 也不在本件写域（写域 = `build/PresentationCore.Linux/**` ＋ 新建应用器 ＋ 本报告）。⇒ 我**没写这两处**，把**逐字文本**交出来：

```
# ① build/integration-wave.sh 的 APPLIERS_EXPLICIT 里（建议紧挨 patch-presentationcore-lineheight-trace 之后）：
    patch-presentationcore-mousecapture-release

# ② build/MilBridge/tools/applier-audit-expected.txt 末尾：
patch-presentationcore-mousecapture-release
```
**为什么"不登记"今天不会静默失能**（两条独立理由）：① 本应用器名字落在波脚本的 `patch-presentation*` **自动兜底 glob** 里 ⇒ 波（`port-lib` 重写 csproj 之后）**照样会执行它**并从上游重生成 ＋ 重新接线；② 我用**临时 wave 副本**（`$HOME/w88a/wave-audit-test.sh`，只把登记行加在那份副本里，**仓内文件零改动**）实测了"若登记，审计会怎么说"：
```
APPLIER_AUDIT applier=patch-presentationcore-mousecapture-release tier=A ok=3 miss=0 detail=-
APPLIER_AUDIT_SUMMARY appliers=27 ok=92 miss=0 red=0 rc=0
```
⇒ **登记之后它是 A 级、miss=0**，登记只增加"被摘掉会红"的牙，不改它的任何行为。
**但必须登记**：不登记 ⇒ 它**不在审计覆盖面内**（"被从波里摘掉"不会红），这正是 W17C 那条欠账的同款形态。
**顺带一条设计说明**：应用器的 `TARGETS`（审计读的声明表）**只声明缺省变体 `M1`**；M2 实验表放在 `TARGETS_EXPERIMENTAL`（审计不读）。理由已实测：把 M2 一起声明 ⇒ 缺省状态下审计会对**合法状态**报 `miss=3`（`缺生成物 HwndMouseInputProvider.Linux.cs; csproj 里没有本应用器的 MARKER_BEGIN; …`）。

---

## §7 `NOINFO`（⑦，**既不算绿也不算红**）

1. **"`EVT combo.closed` 那一刻 `Mouse.Captured` 到底是什么"没有直读**。探针只在**主窗口卡片**的 `MouseMove` 上打 `captured=`（`FeatureBlocks.cs:1220-1227`），而 M1 之后 `L8` 那条腿的 mouse-up 之后**卡片上没有任何 move** ⇒ 这一格**读不到**（§3.4 给的是"原始行 ＋ 无条件顺序 ＋ 正控"合成的机制判定）。
   **要哪一种读数**：`EVT combo.closed` 那一行（或每条点击腿 mouse-up 之后）**直接打一次 `Mouse.Captured?.GetType().Name`**。
   **怎么取**（最小改动，**加强**仪器、不动判据）：在 `samples/WpfFeatureProbe/FeatureBlocks.cs` 的
   `_combo.DropDownClosed += (_, __) => Ev("combo.closed");` 改成 `… => Ev("combo.closed captured=" + (Mouse.Captured?.GetType().Name ?? "null"));`
   并把 `c06` 的取数口径从"最后一条 `EVT move`"换成"该腿切片里**最后一条** `captured=`"（除 `EVT move` 外**多一个来源**）⇒ 这样 `L8` 那一格就**直接可读**，且**判据变严不变松**（原口径保留为旁证）。
   ⚠️ 它改的是**共享样本**（`samples/WpfFeatureProbe/**`，`probe=` 每趟都会漂）⇒ **本件故意没动**（不在写域，且另两条车道在用）。
2. **"门(i) 到底有没有放行那条 `CancelCapture` 报告"没有直读** ⇒ §1.3 只能写到"M2 不足以修好"。**要哪一种读数**：`RawMouseInputReport.Actions` 里有没有 `CancelCapture`。**怎么取**：W87A §6 第 1 条已给完整recipe（给 `patch-presentationcore-inputtrace.py` 的 `ReportOf()` 补 `Actions` 字段 ＋ 放开 `MaxB2OtherLines` 把 Mouse 类纳入）—— 那要改应用器 ＋ 重建 `pc`，超出本件写域。
3. **`GetCapture()`（shim 侧 `g_capture_window`）的直读**：本件用的是"`0x0215` 的存在 ⇒ `ReleaseCapture()` 跑过"这条**推论**（`0x0215` 的唯一来源是 `SetCapture`/`ReleaseCapture`）。要直读需给探针加 `[DllImport("user32.dll")] GetCapture()`（同第 1 条：动共享样本）。
4. **真机 Windows 的对照**（同一动作在真机上捕获归谁）**不可测**（本机无 Windows）。间接旁证仍是 W87A §6 第 2 条那条（上游 `EstablishPopupCapture` 被 `capturedElement == null` 门住）。
5. **整趟 `verify-all` 未跑**（任务书禁止）⇒ 第 `[26]` 步在整趟里的次序/耗时只有静态保证。
6. **`D-G86`（`DestroyWindow` 不清捕获）的修法未做**（任务书要求"同趟查"，本件只读核 ＋ 写进 §5.2）；它需要"造一个持有捕获的窗口被销毁"的用例，属于**新判据**，本件没有写。
7. **`hc` 真实应用上的同族现象仍未测**（W84A §7⑥ 的欠账，本件未接）。
8. **`c06` 的 `L8` 那一格在"现行判据＋装置"下能否绿**：本件判定"**不能**，除非改仪器"（§3.4 末），但**没有实测**过"补直读之后它会不会绿"——那要动共享样本，超出写域。

---

## §8 读数表、内存三值、残留

**lane** `W88A`｜2026-09-22 09:52 → 10:16 +0800｜kernel `6.8.0-138-generic`｜nproc `3`

| 量 | 读数 |
|---|---|
| `loadavg` | 开工 09:52 `2.14 2.15 1.99`；装置自报峰值 `5.50 2.99 2.47`（10:02，三条车道并发）；收工 10:16 `1.94 2.45 2.42` |
| `MemAvailable` | 开工 **2337 MB**｜最低 **1673 MB**（槽内 `HEAVYSLOT=MEMOK avail=1673MB`，门槛 1500 MB）｜收工 **2250 MB** |
| 重活纪律 | **六个重活全部**包在 `bash ~/heavy-slot.sh --min-avail 1500 --max-hold 220 --wait 1200 -- timeout 210 …` 内；**未出现** `MAXHOLD_KILL` / `NOINFO low-memory`（即"不是读数"的那两趟本件没有）；同一时刻**只跑一个**重活（排队不绕槽，实测等待 27–58 s） |
| 残留 | 本件起的 Xvfb/app **0**（装置私有 display `:88`，按 PID 自收）；`ps` 里剩下的 `Xvfb :99/:97/:37/:38` **是别的车道的**（etime 17h/16h/52min，非本件）；**零** `pkill -f` |

**本件自己的读数件（`$HOME/w88a/**`，现场算）**

| 件 | 内容 |
|---|---|
| `logs/leg-{baseline,m2,m1,none,m1b,m1c}.out` | 六趟完整屏输出（变体落地 ＋ msbuild 接线自证 ＋ 槽读数 ＋ `R_GATE=` 机读行） |
| `rgate-{baseline,m2,m1,none,m1b,m1c}/{app.log,evidence.txt}` | 六趟原始证据（`app.log` 757–877 行） |
| `tools/census.sh` / `logs/census-*.txt` | `captured=` 普查（含逐腿切片序列） |
| `tools/postup.sh` / `logs/postup-*.txt` | `c06` **意图口径**逐腿复核（mouse-up 之后的 `captured=`） |
| `tools/nine.sh` | 九位 ＋ `inputs_fp` 现场复算器（算法**逐字取自** `build/close-wave.sh` 的 `fp_inputs()`/汇总段，不自己发明） |
| `tools/leg.sh` / `tools/inner.sh` | 一趟腿的驱动（变体落地 → msbuild 接线自证 → 槽内：重建 pc → 跑 `R-GATE`） |
| `wave-audit-test.sh` | **临时** wave 副本（只加了一行登记）⇒ 用来实测"若登记，审计怎么说"；**仓内 `integration-wave.sh` 一字未动** |

**写域**：仓内**只新增/改动三个文件** —— 新建 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-mousecapture-release.py`、新建 `build/PresentationCore.Linux/MouseDevice.Linux.cs`、改 `build/PresentationCore.Linux/PresentationCore.Linux.csproj`（接线 6 行）＋ 重建 `build/PresentationCore.Linux/bin/Release/PresentationCore.dll`，以及本报告。**未跑** `integration-wave.sh`/`close-wave.sh`/`verify-all.sh`；**未动** `build/MilBridge/**`、`docs/**`、`upstream/**`、`build/shims/**`、`samples/**`。

> ⚠️ **划清一笔**（免得被归到本件头上）：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（09:52:34）与 `build/MilBridge/tools/defect-registry-declared.tsv`（09:53:13）在本件时间窗内**被改过**，但**不是本件** —— 本件对仓内的**全部**写操作只有上面那四处 ＋ 本报告；那两件是**主控**的 `D-G85`/`D-G86` 登记动作（`defect-registry-declared.tsv:106` 现为 `ID  D-G85  req=KD  present=KD`）。

---

## §9 ≤6 行大白话小结（⑨）

1. **M2 单做没变绿**（`11/13` 逐格不变）⇒ W87A 对门(ii) 的判读**站得住**：光放宽 `_active` 那道门，回声还是被"活跃源"那道门整段丢掉。
2. **M1（在 `MouseDevice.cs:388` 之后补一次 `ChangeMouseCapture(null,…)`）把用户看得见的那一半修好了**：连点三下从"全被 ComboBox 吃掉"变成三下各自都出事件（`c11` 转绿），`captured=ComboBox` **15→8**（8 条全是"下拉开着时"的合法捕获，逐条可数），`EVT combo.down` 7→5、`L8` 没有变成粘 `PopupRoot`。
3. **但 `R_GATE=PASS 13/13` 我没拿到：`12/13`，唯一红格是 `c06` 的 `L8`** —— 而它的成因**不是捕获还粘着**：修好之后那一腿的 2px 挪动**正确地**落到了弹窗窗口上，主窗口卡片因此**一条 move 都读不到**，判据只好回退去读**点击之前**那条（那时下拉正开着，`ComboBox` 持有捕获本来就是合法的）。
4. 三条硬证据把这句话钉住：① 切片内那条 `0x0215`（`:607`）证明释放发生了、而 M1 的注入行**无条件**紧随其后；② 基线在同一坐标给过正控——`freshhit=null`（那个点下面没有视觉）却**照样**被打进 ComboBox，那正是本缺陷的签名；③ 紧接着的 `SEQ_lst0`/`SEQ_tb` 全读成 `null`。
5. **反极性闭合**：还原修法 ⇒ `pc` **逐字节**回到 `56ee75ced8d6aece`、`R_GATE` 回到 `11/13` 且红格逐字相同；`hbtextline`/`win32shim` 未变；`inputs_fp` 变了，且**唯一原因机器证**就是新增的那个应用器。
6. **没做到的**：`13/13`（要**加强仪器**才能读——给探针在 mouse-up 之后直接打一次 `Mouse.Captured`，判据件与装置**我都没动**）；两处**登记**（`build/MilBridge/tools/**` 是本件明列的禁写域）⇒ 逐字文本已交 §6.3；直读 `Mouse.Captured`/`GetCapture()`/报告级 `Actions`（§7 三条 `NOINFO`，都要动共享样本或应用器）。

---

**本报告自身 sha16**（口径：**`head -n -2 build/MilBridge/W88A-report.md | sha256sum | cut -c1-16`** —— 即"末两行（本行 + 下一行）之外的全文"，读者可现场复算并必须得到同一个值）＝ **`97c03dbc26eefe80`**
⚠️ 回填这一行之后全文 sha 就变了（"报告自指"的老问题）⇒ 引用时**按上面这条命令现场重算**，别抄这个数。
