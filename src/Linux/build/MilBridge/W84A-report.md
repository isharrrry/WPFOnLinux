# W84A 报告 —— `TASK-0702` / `R-GATE`：把「连续点击/交互响应」从**仓外仪器**收编进仓并接进 `verify-all`

> 车道 **W84A**（`TASK-0702` 的**重派**）。起点现场已核：`build/MilBridge/W80A-report.md` **不存在**、`~/w80a` **空**、
> `verify-all.sh` 里 `grep -c 'R_GATE\|r-gate' = 0`、步数声明仍是 `25` ⇒ **从零开始**（没有半截改动要接）。
> 判据**先写**（`docs/WAVE50-PREREGISTRATION.md`，本车道建立）**后取读数**；本报告所有读数都带**件 sha16**（本波树在动，见 §6）。

---

## §0 一句话结论（**先说不好听的**）

**收编与接线都成了**（判据件自测 21/21 绿、`VERIFYALL_SELF=PASS names=26 decl=26 gen=#50`、装置在真机上 11 下点击全部落到窗口），
但**正极性没有拿到 `PASS`**：门禁第一次跑就抓到一条**真缺陷** ——

> **点选下拉项之后（下拉已关）`Mouse.Captured` 恒为 `ComboBox` ⇒ 之后每一次点击都被路由到 `ComboBox`**，
> ListBox/TextBox 收不到任何事件（`EVT combo.down` 顶替了 `EVT lst.down`）。这正是用户报的那一族症状（"点了没反应"）。

⇒ `R_GATE=FAIL crit=11/13 fails=c06(L8_comboitem1,SEQ_lst0,SEQ_tb),c11(seq-lst0,seq-tb)`。
**这不是仪器假红**：同一台仪器、同一套判据在**修前件**上红 6 格（`e700c383` 那趟 ⑥ 全红）、在**故意破坏**那趟红 10 格、
在**内存门槛**那趟如实 `NOINFO`（§4 两极化表）。我**没有**为了让这一步变绿而放宽任何判据（那是本工程最忌的形态）。

---

## §1 收编件路径与理由（③ 之前先交代"东西放哪、为什么"）

| 件 | 路径 | 角色 | 为什么放这 |
|---|---|---|---|
| **装置** | `build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh`（`93f914d6c041c88d`） | 起**私有 Xvfb** ＋ 私有 app 目录 ＋ `xdotool` 真实节奏点击（`mousedown`→停 150 ms→`mouseup`），**只落证据** | 与 `build/MilBridge/tests/**Probe/` 的既有惯例同形（`W81AWindowProbe`/`W82AMinMaxProbe` 都在这里）；**纯 bash ＋ X 工具，无 csproj、无 dotnet** ⇒ 不引入新构建面 |
| **判据唯一实现** | `build/MilBridge/tools/r-gate-step.sh`（`f263341ad376d51f`） | 13 格判据 ＋ 三态 ＋ 机读行 `R_GATE=`；`--selftest` 21 例（**零 X、零 dotnet**） | 与 `product-entry-step.sh`/`frame-presence-check.sh` 同层：**判据件放 `tools/`**（`verify-all` 只调这一层） |
| **接线** | `verify-all.sh` 第 `[26]` 步 | 见 §2 | —— |
| **预登记** | `docs/WAVE50-PREREGISTRATION.md`（`1a43a6d21dc03336`） | 判据先写（继承 `#49` §3 B3 六格表） | 声明链第四处（`prereg=PASS` 要求本代 H1 出现在 `docs/WAVE#NN-PREREGISTRATION.md`；`#50` 此前**没有**这个文件） |

**为什么拆两层**（不是重复造轮子）：判据必须能在**无 X、无 dotnet** 的机器上自测 —— 装置只能在有 X 的机器上跑；
`--selftest` 21 例全部跑在合成的 `evidence.txt` ＋ `app.log` 上（`mktemp -d`），**前提自持**（不读冻结基线/世代号）。
生产路径**不传** `--judge-dir`；一旦传了（复核已落盘证据），机读行里带 `src=external`（**永远可见，不会静默**）。

**判据（逐格继承 `#49` 预登记 §3 B3，落 `docs/WAVE50-PREREGISTRATION.md` §1）**：
① 点 ListBox item1 ⇒ `lst.selection=1`｜反：点卡片空白 ⇒ 控件级 EVT = 0（且点击确实到达窗口）
② 点 TextBox ⇒ `tb.focus`｜反：点窗口外 ⇒ 无控件级 EVT
③ 点后键入 3 字符 ⇒ `tb.text=` ≥ 3 行、长度单调不减、净增 ≥ 3｜反：**未点击就键入** ⇒ 不增（**且必须证明键真到了应用**）
④ 点 ComboBox ⇒ `combo.opened`=1 ＋ 新 X 窗口 `IsViewable`｜反：下拉开着时点下拉外 ⇒ 无 `combo.selection`
⑤ 点弹窗 item1 ⇒ `combo.selection=1` ＋ `combo.closed`=1
⑥ **mouse-up 之后 `cap=none`**（`D-G55` 指纹）
⑦ **承重连续腿**：窗口内连点三下（ListBox item0 → TextBox → ComboBox）⇒ 三下各自 EVT 都出
⑧ 像素：下拉打开时测试色 `22D3EE` > 0；＋`D-G49` 字段：`lst.down … state=Pressed` / `lst.up … state=Released`

## §2 机读行格式（②）与 `verify-all` 改动逐处（③）

**机读行**（三态，单行，`verify-all` 的绿/红分支都会把它捞上屏）：
```
R_GATE=PASS    crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938 mem_mb=2374 win32shim=<sha16> pc=<sha16> src=device
R_GATE=FAIL    crit=11/13 clicks=11 ok=11 red=2 noinfo=0 popup=1 px_open=19449 sabotage=none win=938x938 src=device fails=c06(…),c11(…)
R_GATE=NOINFO  reason=device-low-memory detail=… mem_available=2145MB < 门槛 99999MB（读数不可归因）
```
判序（**写死**）：**有红先红**（`FAIL` 压过"判不了"），无红但有格判不了才 `NOINFO`；`NOINFO` 在门禁里**同样是 ❌**。
`sabotage≠none` 却仍全格通过 ⇒ `FAIL reason=sabotage-not-caught`（装置没判别力不许当绿）。

**`verify-all.sh`（`bb416e92ab34ff64` → `227623000850ca5d`）四处同趟改**（`diff` 共 22 行增删）：

| # | 位置 | 改动 |
|---|---|---|
| 1 | 头注释口径句（`#49` 那句之前） | 新增 `**\`#50\` 收官起 = 26 步**` 整段（写明本波的装置/判据件/判据来源/与旧预登记的分叉） |
| 2 | `VERIFYALL-STEPS-DECL` **首行** | 新增 `# VERIFYALL-STEPS-DECL: 26 gen=#50 …`（**最上面那条才是当前口径**，`#49` 那行原样保留为史实） |
| 3 | `VERIFYALL-STEP-NAMES` | 末位追加 `\| R-GATE（连续交互）`（现场步名次序一致） |
| 4 | 步骤表尾（`THIRD-PARTY` 之后） | `echo "[26] …"` ＋ `run_step "R-GATE（连续交互）" bash build/MilBridge/tools/r-gate-step.sh` |

**自证**（现场重算，非手抄）：
```
$ bash build/MilBridge/tools/verify-all-step-check.sh
VERIFYALL_SELF=PASS names=26 decl=26 gen=#50 dup=0 order=OK prose=OK prereg=PASS vfile_sha16=227623000850ca5d
```
⚠️ **与 `#49` 预登记 §3 B3 的分叉（已登记，不是遗漏）**：那一节写「并进既有门禁步、**步数保持 25**」，
而本车道收到的任务书要求「作为**新一步**、声明 25→26 同趟改」⇒ **按任务书执行**，并在 `docs/WAVE50-PREREGISTRATION.md` §3
与 `verify-all.sh` 的口径句里**两处点名**这处分叉（旧那半句已被取代）。

## §3 判据件自测与仪器自伤（**本车道抓到的 6 处自己的坑，逐条留档**）

`--selftest`：`R_GATE_SELFTEST=PASS cases=21 pass=21 fail=0 crit_total=13`（零 X、零 dotnet；每条判据一个例）。
下面 6 处**都是本车道在自测/真机对照中自己抓到并修掉的**（含三处**会产假绿/假红**的形态）：

1. **c03 的 `[` 少了 ` ]`**（`elif [ "$last" -lt $(( … ))`）：`[` 缺 `]` 恒返回非零 ⇒ "净增不足"那一支**永远走不到**
   ⇒ 那是**假绿通道**。修法：补 ` ]` ＋ 并引号；并加自测 **S4b**（3 行、长度 1/1/1 ⇒ 行数够但净增只有 1 ⇒ 必须红）。
2. **`POS` 记录前缀串键**：`grep "^EVID pos tag=combo"` 会**同时也匹配 `pos tag=comboitem1`**，再 `tail -1`
   ⇒ `combo` 那格读到 `comboitem1` 的记录。实测后果：**两趟被误判 `NOINFO pos-missing`**、一趟**假绿**（读了 comboitem1 的 `w=258`）。
   修法：精确匹配 `"^EVID pos tag=$tag "`（**带尾空格**）＋ 自测 **S17b**（删掉 combo 那行、留 comboitem1 ⇒ 必须 `NOINFO`）。
3. **装置的新窗口 diff 有 bug**：基线是**换行**分隔，而 `case " $w0 " in *" $now "*)` 只对首/末行成立
   ⇒ 主窗口与 4 个未映射的 helper 窗口被当成"新窗口"。修法：基线先 `tr '\n' ' '` 规整 ＋ `pick_popup()` **排除主窗口**、只认 `h≤400` 的 `IsViewable`。
4. **判据件的重定向早于装置执行**：`> "$OUT/device.out"` 在装置内部的 `mkdir -p` **之前**跑 ⇒ `没有那个文件或目录` ⇒
   被读成"装置异常 NOINFO"（实测那一趟 `D_rc=2`）。修法：判据件自己先 `mkdir -p`。
5. **c06 原实现是"切片里**出现过** `captured=null`"** ⇒ 会被**点击前**那条 move 满足（那时捕获还没建立）⇒ 实测报 `7/11`，
   而真值是 `5/11`（**多报的 2 格就是假绿**）。修法：改判**该腿最后一条** `EVT move`（＝ mouse-up 之后那一下挪动）。
6. **c06 一刀切会让健康的树恒红**：WPF 的 `ComboBox` 在**弹窗打开期间**本来就持有捕获（语义，不是缺陷）
   ⇒ 若要求"每下 mouse-up 后都 `cap=none`"，则点开下拉那两下必然红 ⇒ **假红侵蚀红数信任**。
   修法：**豁免"该腿切片里 `combo.opened > combo.closed`（下拉仍开着）"的腿**，并在屏上具名印出豁免；
   豁免**只覆盖"开着"**那一档 —— 下拉**已关**却仍 `captured≠null` 照样红。加自测 **S7b**（真缺陷形态 ⇒ 必须红并点名 `L8/SEQ_*`）。
   ⚠️ 这条改法是**解释**（原文是"每次 mouse-up 之后 `cap=none`"）⇒ 已写进 `docs/WAVE50-PREREGISTRATION.md` §1 的口径里，**没有静默放宽**。

## §4 三态与两极化读数（④；全部现场命令原样可复算）

| 腿 | 命令（装置） | 件 | 机读行 | 判定 |
|---|---|---|---|---|
| **① 正极性**（现役树） | `bash build/MilBridge/tools/r-gate-step.sh`（生产路径，判据件自己起装置） | `win32shim=24e906c194903c8b` `pc=56ee75ced8d6aece` `pf=78218dd1851d41e8` `wb=2e4e46e539a72cd7` `bridge=feef049e9d0e313a` `probe=e29e08cbfc26acc8` `mem_mb=2588` | `R_GATE=FAIL crit=11/13 clicks=11 ok=11 red=2 noinfo=0 popup=1 px_open=19449 sabotage=none win=938x938 src=device fails=c06(L8_comboitem1,SEQ_lst0,SEQ_tb),c11(seq-lst0,seq-tb)` | **红 2 格 ＝ 真缺陷**（§5） |
| **② 产品级反极性**：只换回**修前件** | `…/run-r-gate-legs.sh --no-build --appdir $HOME/w47b-app2`（`#46` 冻前整套：`win32shim=e700c383ec1ecdc8` `pc=043eff4b1d8ecd7d` `pf=366e9486536bc291` `wb=84a2826c471e60ea` `bridge=e3ea092010734f44` `probe=7e3fea125e1825a8`） | 同上 | `R_GATE=FAIL crit=6/13 clicks=10 ok=6 red=6 noinfo=1 popup=0 px_open=577 fails=c02,c03,c04,c06,c11,c13` | ⑥ **全 10 下红**（`cap` 长期不释放）＝与 `#49` B3 预登记的"修前件必须红"**逐条相符** |
| **③ 仪器级反极性**：`R_GATE_SABOTAGE=windowmove`（POS 取完后把窗口挪 (+300,+250)） | 装置 `--sabotage=windowmove` | 现役树 | `R_GATE=FAIL crit=3/13 red=10 fails=…,click-not-received(L2_blank,L3_lst1,L4_tb,L6_combo,L7_combo_blank,L6b_combo_reopen,SEQ_lst0,SEQ_tb,SEQ_combo)` | 窗口内 9 下点击**全部没收到** `WM_LBUTTONDOWN` ⇒ 判据面整体翻红（**说明判据有判别力**） |
| **④ `NOINFO` 极性**：内存门槛 | `R_GATE_MIN_MB=99999` | —— | `R_GATE=NOINFO reason=device-low-memory detail=… mem_available=2145MB < 门槛 99999MB（读数不可归因）` | **既不算绿也不算红**（如实"算不出"） |
| **⑤ A/B：只把 `win32shim` 换回 `3e4390c9ec07f621`**（现盘其余件不变） | `--appdir ~/w84a/shimA` | `pf=ae101cad4a0e1bca` `probe=8e2e743c8ecf27e5` | `R_GATE=FAIL … fails=c06(L8_comboitem1,SEQ_lst0,SEQ_tb),c11(seq-lst0,seq-tb)` | **红格逐格相同** ⇒ 这条缺陷**不是**另一条车道 09:23 那次 shim 改动引入的（见 §6） |
| **⑥ 判据件自测** | `bash build/MilBridge/tools/r-gate-step.sh --selftest` | —— | `R_GATE_SELFTEST=PASS cases=21 pass=21 fail=0 crit_total=13` | 每条判据都有反极性例（含 3 处**假绿通道**的例） |

**两极化成对读数（同一台仪器、同一套判据）**：现役树 **11/13 绿** vs 修前件 **6/13 绿**（同一批格：①③④⑥⑦⑧ 从绿变红或反之）
⇒ 判据**能绿也能红**，不是恒绿也不是恒红。

## §5 抓到的真缺陷（**本步第一次跑就红，红得对**）

**现象（每一条都是 `app.log` 原文／X 服务器读数）**：
* 点弹窗项那一下是**成功**的：`EVT combo.selection=1` ＋ `EVT combo.closed`（判据⑤ **PASS**）。
* 但那一腿的 mouse-up **之后**，`EVT move … captured=ComboBox`（**下拉已经关了**，捕获没释放）。
* 之后窗口内的点击**不再落到控件**：
  * `SEQ_lst0`（点在 ListBox item0 那一行）：`EVT combo.down src=ComboBox state=Pressed` ＋ `directlyover=ComboBox` 而 **`freshhit=Border`**
    ⇒ 事件被路由给 `ComboBox`，**当场重算的命中却明明是 ListBox 那边** —— 输入路由与命中测试**分叉**。
  * `SEQ_tb`（点在 TextBox 中心）：同样 `EVT combo.down`，`freshhit=TextBoxView` ⇒ 没有 `EVT tb.focus`。
* **对照（同一趟里）**：`L7`（下拉开着时点下拉外空白）**把捕获释放了** —— `captured=null`。
  ⇒ **区别只在"下拉怎么关的"**：**点外面关 ⇒ 释放；点选项关 ⇒ 不释放**。
* `WM_CAPTURECHANGED`（`msg=0x0215`）在 **`pos1` 那趟**共派发 **4 次，全部给主窗口 `0x200005`**（`app.log` 行 221/250/534/635），
  **从未派发给弹窗窗口**（`0x200007`/`0x200008`）。
* 逐腿捕获读数（`pos1` 那趟）：`null` = L1/L2/L3/L4/L7；`ComboBox` = L6（开着，**豁免**）/L6b（开着，**豁免**）/L8/SEQ_lst0/SEQ_tb/SEQ_combo。

**判定点候选（给下一条车道，**我未改产品件**）**：
1. **弹窗路径的捕获释放**：弹窗是**独立 X 窗口**（`0x200007` `271x77` `IsViewable`）；点选项关下拉时释放走的是这套路径，
   而 `WM_CAPTURECHANGED` 只到了主窗口 ⇒ **假设**：弹窗的 `HwndSource`／其输入 provider 持有/未清的那份状态没被这条消息覆盖到
   （与 `#47` 修的 `D-G55` 同族，但走**另一个窗口**）。
   ⚠️ **另一条假设同样成立**（我**没有**排除它）：上游 `ComboBoxItem` 的"粘性捕获"（`Mouse.Capture(this)`）在关闭后没有被清 ——
   那就落在**托管侧**，不在 shim。**两条假设的分界读数我这一轮没取**（见 §7 `NOINFO`③），请下一条车道先取它再定修法。
2. 复现器**就是本步**（一条命令、≈35 s）：`bash build/MilBridge/tools/r-gate-step.sh`（红格名会写明 `L8/SEQ_lst0/SEQ_tb`）。

**为什么我不"顺手修"**：本车道的写域是**判据与接线**，产品件（`src/WpfGfx.Linux.Native/**` 或托管侧）不在我手上；
而且 §6 显示本波树**正在被别的车道改**（09:23 / 09:30 / 09:38 三处位移）⇒ 我这轮改产品件会和它们的读数互相污染。

## §6 会动哪些世代位（⑥）＋ `inputs_fp` 实测（**推翻 `#49` 预登记的预测**）

**九位产品件：本车道一个都没动**（现场核过：本步跑前跑后逐位相同）。但本波树在动，**我如实记账**：

| 件 | 我进场时（09:1x） | 现在 | mtime | 谁动的 |
|---|---|---|---|---|
| `win32shim` | `3e4390c9ec07f621` | **`24e906c194903c8b`** | 09:30:24 | **另一条车道**（09:23:10 改了 `src/WpfGfx.Linux.Native/src/win32_pts.c`） |
| `pc` | `56ee75ced8d6aece` | `56ee75ced8d6aece` | 09-21 17:20 | 未变 |
| `pf` | `6375fabf89ac7fef` | **`78218dd1851d41e8`** | 09:38:44 | **另一条车道** |
| `wb` / `bridge` | `2e4e46e539a72cd7` / `feef049e9d0e313a` | 同 | 09-21 | 未变 |
| `verify-all.sh` | `bb416e92ab34ff64` | **`227623000850ca5d`** | 本车道 | **我**（§2 四处） |
| `inputs_fp` | `963d3b6a44c22c3ddce87fdaf050a72dce9ef430116626355e313975543fe0db` | **`c3ed9925268a52101f56eb376e3ca4635eee15509dc0a515dd443a87e03af76a`** | —— | **不是我** |

**`inputs_fp` 为什么不因我而变（机器证，不是推断）**：把 `fp_inputs()` 按 `sed "s/} | LC_ALL=C sort.*/} | LC_ALL=C sort/"`
**机械抽出**（只去掉最后那段哈希），现盘覆盖面 = **144 件**，我的四件**命中 0**：
```
$ grep -c 'r-gate\|RGateClickProbe\|verify-all.sh\|WAVE50' /tmp/w84a-covered.txt
0
$ # 覆盖面里"今天 09:10 之后被改"的只有一件：
2026-09-22 09:23:10  src/WpfGfx.Linux.Native/src/win32_pts.c
```
⇒ **`verify-all.sh` 与 `build/MilBridge/tools/*.sh`（除具名清单）都不在 `fp_inputs()` 覆盖面里**，
所以 `inputs_fp` 这次位移是**另一条车道的 C 源改动**造成的（`#49` 的 `B4` 把 `src/WpfGfx.Linux.Native/**/*.{c,h}` 纳入了覆盖面）。
**`#49` 预登记 §4 预测「B3 接线 ⇒ `inputs_fp` 必变」—— 该预测被本车道实测推翻**（原因：覆盖面不含 `verify-all.sh`）。

**同趟别的车道还改了什么（不是我的，只记账，免得后人把两份快照的差当成我的位移）**：
`build/PresentationFramework.Linux/{PresentationFramework.Linux.csproj,reapply-patches.py,PtsCache.Linux.cs,FlowDocumentView.Linux.cs}`、
`src/WpfGfx.Linux.Native/{src/win32_pts.c,build-shim.sh}`、`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`、
`build/{PresentationFramework.Linux,PresentationCore.Linux}/bin/Release/*.dll`、`docs/{ROUTES.md,WAVE49-PREREGISTRATION.md}`（今天 09:15 之后被改）。
**我这一轮只写了 §10 那 5 件。**

🔴 **登记一条新欠账（我**没有**动 `close-wave.sh`，见下）**：本步的两件**判据件不在覆盖面里** ⇒ 将来有人换掉 `r-gate-step.sh` 的判据
**零机器红**（与 `tline-gate.sh` 在 `#28` 之前、四个核对器在 `#31` 之前**同族**）。建议的补法（**一行两件，照 `printf` 清单的写法**）：
```bash
      build/MilBridge/tools/r-gate-step.sh \
      build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh \
```
⚠️ 我**故意不自己加**：`close-wave.sh` **本身在覆盖面里** ⇒ 改它**必然**移动 `inputs_fp`，而本波 `IN_FP_0` 是否已采样我看不见；
一旦已采样，盲改会让 `close-wave.sh [4/6]` 自报 `IN_FP_0 != IN_FP_1` 并 `exit 5`（`#49` 的 `C2/C4` 记着同一条流程代价）。
⇒ **请主控裁定**：在**采样之前**的专门一趟里加这两行（并顺手把 `#37` F2 那条"判据件必须进覆盖面"的账一起核）。

## §7 `NOINFO` 清单（⑦）

1. **无 X / 缺工具**：`Xvfb`/`xdotool`/`xwininfo`/`xdpyinfo`/`xwd`/`convert` 任一缺席 ⇒ `R_GATE=NOINFO reason=device-tools-missing`（**不许当绿**）。
2. **内存不足**：`MemAvailable < R_GATE_MIN_MB`（默认 1000 MB）⇒ `NOINFO reason=device-low-memory`（实测读数见 §4④）。
3. **产品级缺陷的机制分界**：`WM_CAPTURECHANGED` **只到主窗口、从未到弹窗窗口**这件事，只能证"消息没到弹窗"，
   **不能**证"到底是 shim 少派发还是托管侧没清" ⇒ §5 的两条假设**都还站着**（要再取读数：弹窗 HWND 的捕获状态、
   以及 `ReleaseCapture` 调用点的 HWND）。
4. **本步在 `verify-all` 里的整趟读数**：我只跑了**本步**（≈35 s ×5 趟）与判据件自测；
   **没有**跑 `verify-all` 全趟（任务书禁止我跑收尾链；且本波树在被别的车道改，整趟读数会串味）。
   ⇒ "第 `[26]` 步在整趟里的次序/耗时"只有**静态**保证（`verify-all-step-check.sh` 绿），**动态整趟 `NOINFO`**。
5. **`--no-x` 语义**：本步**自起私有 Xvfb**，所以 `verify-all --no-x` **不缩小**本步射程（这是设计选择，已写在文件头）；
   要主动关掉它只能用 `R_GATE_*` 钩子（不提供"跳过后当绿"的口子）。
6. **hc 真实应用上的同族现象**：`hc`（仓外第三方样式）上未取 `Mouse.Captured` ⇒ 本缺陷在 hc 上的表现**`NOINFO`**（未测）。
7. **测试色通道的语义**：`closed_before=577`（关着时也有 577 px 测试色）⇒ 判据⑧只能按"开 > 关"比；
   为什么关着就有 577 我**没查**（`NOINFO`：可能是 ComboBox 自身模板的选中态色块）。

## §8 成本与内存三值（⑤⑧）

**实测新增时长**（`verify-all` 里样本已由 `[2]` 步构建，本步内部构建是空转）：

| 量 | 读数 | 口径 |
|---|---|---|
| 整步（生产路径、含槽等待） | **96 s** | `FINAL_wall_s=96`（其中 `HEAVYSLOT=ACQUIRED waited=59s`） |
| **本步自身（= 给 `verify-all` 加的时间）** | **≈37 s** | `HEAVYSLOT=RELEASED rc=1 held=37s`（另两趟 32 s／33 s） |
| 装置内部拆分 | app 装配 09:39:47 → 证据落盘 09:40:20 ＝ **33 s** | 其中 13 步点击/键入 ≈22 s、应用冷启 ≈6 s、整屏取色 2 次 ≈3 s、Xvfb ≈1 s |

**内存三值**：本步跑前 `free -m` = **1719 MB**（最紧那趟）／装置自报 `mem_mb` = **2264–2588 MB**（`pos1=2374`、`ab=2264`、`final=2588`、`neg_prod=1530`）／装置门槛 **1000 MB**；
（`1530 MB` 那趟已接近我自设的门槛，**如实记**）；`loadavg` 1.95→5.93（本波多车道并发）。
所有 `dotnet` 整条命令都包在 `~/heavy-slot.sh --min-avail 1500 --max-hold 200`（**槽内不套槽**），**未出现** `MAXHOLD_KILL`／`NOINFO low-memory` 真读数。

## §9 复算命令逐条

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; cd $R
# 判据件自测（零 X、零 dotnet）
bash build/MilBridge/tools/r-gate-step.sh --selftest
# 整步（生产路径；判据件自己起装置）—— 重活纪律：整条包进机级重活槽
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 200 -- timeout 260 bash build/MilBridge/tools/r-gate-step.sh
# 复核已落盘证据（不重跑装置；机读行带 src=external）
bash build/MilBridge/tools/r-gate-step.sh --judge-dir ~/w84a/final_prod
# 反极性①产品级（只换回修前件；**只读**别人的历史目录，绝不改仓内权威件）
bash build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh --no-build --appdir $HOME/w47b-app2 --out ~/w84a/neg_prod
bash build/MilBridge/tools/r-gate-step.sh --judge-dir ~/w84a/neg_prod
# 反极性②仪器级（挪走窗口 ⇒ 点击目标不存在）
env R_GATE_SABOTAGE=windowmove bash build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh --no-build --out ~/w84a/neg_sab
bash build/MilBridge/tools/r-gate-step.sh --judge-dir ~/w84a/neg_sab
# 声明链自证
bash build/MilBridge/tools/verify-all-step-check.sh        # 期望 names=26 decl=26 gen=#50 prose=OK prereg=PASS
# 覆盖面实测（机械抽掉哈希段，再列件）
sed "s/} | LC_ALL=C sort.*/} | LC_ALL=C sort/" <(sed -n '/^fp_inputs() {/,/^}/p' build/close-wave.sh) > /tmp/fplist.sh
bash -c '. /tmp/fplist.sh; fp_inputs' | grep -c 'r-gate\|RGateClickProbe\|verify-all.sh\|WAVE50'   # 期望 0
```

## §10 本车道的件与备份

| 件 | before | after |
|---|---|---|
| `verify-all.sh` | `bb416e92ab34ff64`（`cp -p` 备份 `~/w84a/backup/verify-all.sh.before`，逐位相同） | **`227623000850ca5d`** |
| `build/MilBridge/tools/r-gate-step.sh` | 新建 | `f263341ad376d51f` |
| `build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh` | 新建 | `93f914d6c041c88d` |
| `docs/WAVE50-PREREGISTRATION.md` | 新建 | `1a43a6d21dc03336` |
| `build/MilBridge/W84A-report.md` | 新建 | 本文件（回填前 sha16 见文末） |

仓内写入**只有这 5 件**；写域外一字节未碰（`~/w47b-app2`、`~/w85a/app` 都是**只读**拷源，**没有**对 `$HOME/w53a|w54a|w55a/app` 跑任何同步器或改件）；全程**零 `pkill -f`**（Xvfb/应用按 PID 收尾）。

## §11 ≤6 行中文大白话小结（⑨）

1. 仓外那支点击脚本我**搬进仓**了：装置一个、判据一个，门禁里加了**第 26 步**，声明链四处同趟改好、自查绿。
2. 判据**先写**（继承 `#49` 预登记那六格）＋ 我补的"连点三下"和"下拉真上屏"两格；判据件自测 **21/21**。
3. 真机上装置跑得动：11 下点击全部落到窗口、下拉真开了（测试色 19449 px）、选项真选中了。
4. **但正极性是红的** —— 门禁第一次跑就抓到：**点完下拉项之后鼠标捕获不释放**，接下来点 ListBox/TextBox 全被路由给 ComboBox（"点了没反应"就是这么来的）。
5. 这台仪器**能绿也能红**：同一套判据在修前件上红 6 格、在故意挪走窗口那趟红 10 格、内存不够那趟如实说"算不出"；我没为让它变绿放宽一个字。
6. 我没做到的：**没修产品件**（缺陷的机制分界只到"消息没到弹窗"，两条假设都还站着）、**没跑整趟 verify-all**、**没把新判据件加进 `fp_inputs()` 覆盖面**（那要主控在采样前裁定）。

**给主控的裁定项（两条）**：
① 这条缺陷**修不修**（建议修：它就是用户报的那一族；复现器 = 本步一条命令）；② 两件新判据件**加不加进 `fp_inputs()`**（§6 的一行补法）。

---

**本报告自身 sha16**（口径：`sha256sum build/MilBridge/W84A-report.md | cut -c1-16`，**回填本行之前**）＝ **`f797e6f2c2d79009`**（247 行）。
⚠️ 回填这一行之后全文 sha16 就变了（"报告自指"的老问题）⇒ 引用时**按上面这条命令现场重算**，别抄我这个数。

