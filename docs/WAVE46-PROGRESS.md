# 波 `#46` 进行中 —— 状态板（给下一轮/并行车道看，别凭印象）

> 世代：冻结仍是 `#44`（`BASELINESHA=PASS live=ff3990dafa582831`、`BASELINEGEN=PASS decl_gen=#44`）。
> `#46` 收尾时必须**重冻**；收尾手册见 `docs/WAVE46-CLOSEOUT-RUNBOOK.md`（车道 W46B 产出）。

## 已落仓（`#46` 的产品改动）
| 件 | 文件 | 说明 | sha16 |
|---|---|---|---|
| `win32shim` | `src/WpfGfx.Linux.Native/src/win32_x11.c` | **焦点回送**识别并吃掉（`SetFocus` 已同步派发过，X 的回送不再重复翻译）＋建窗/映射腿 env 门控诊断 | `e700c383ec1ecdc8` |
| `pc` | `build/PresentationCore.Linux/HwndTarget.Linux.cs`（生成）＋新 applier `tools/patch-presentationcore-hwndtarget-trace.py` | `HwndTarget` 设根链**只读**插桩（`WPF_LINUX_HT_TRACE=1`）；applier 自带锚点/`throw`/大括号/结构断言 | 生成物已接线 |
| `bridge` | `src/WpfGfx.Linux/Resources/MilChannel.cs` | 命令层台账（`WPF_LINUX_CMDLOG=1`）：`EndCommand`/`派发`/`E_UNEXPECTED` 路径 | 待重建 |

## `D-G54`（组合框弹窗内容零渲染）当前定位
**已证伪的假设**（逐条留档在 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`）：
1. ❌ 弹窗不建窗／不出画；2. ❌ 透明填充不可命中（`D-G52`）；3. ❌ 层窗口呈现腿（剥 `WS_EX_LAYERED`）；
4. ❌ `UsesPerPixelOpacity`；5. ❌ 闪屏线程污染通道；6. ❌ **managed 没走到 `SetRoot`**（`[HT]` 证明**两次都走到了**）。

**当前嫌疑（三条并行）**：
- **A（桥侧）**：`ConfigureNotify` 没按 XID 归属 ⇒ 弹窗 resize 记到主窗口（`NOTE X11 Resize 生效：HWND 0x200004 800x600 → 413x274`）。车道 **W46A** 在修。
- **B（命令丢失）**：managed 发了**两次** `MilCmdTargetSetRoot`，桥 preflight 只见**一条** ⇒ 命令在哪一跳丢的。车道 **W46C** 在测（`[CMD]` 台账）。
- **C（架构）**：桥按**通道**存根（`IMilChannel.Root`），上游是**每个 `HwndTarget` 一棵根** ⇒ 一个通道挂两个窗口时表示不了。

**判据（修好后必须同时成立）**：弹窗下半区 `色数 > 1`；该区 `AE ≫ 3779`；`post.png` 肉眼见列表；
**反面判据**：只画一整块纯色不算过（说明见 `docs/WAVE46-DG54-CRITERIA.md`，车道 W46D）。
复采脚本：`$HOME/w46-popup-verify.sh`（W46D 产出）。


## 收尾前置件（本轮已办，全部不撞构建）
| # | 事项 | 读数/证据 |
|---|---|---|
| 1 | **5 份 `libwpfwin32.so` 同步到权威件** | 全部 `e700c383ec1ecdc8`（改前 3 份停在 `11f81eb9dfc60a12`）⇒ 消掉"探针测旧件"的现场（W46B R5） |
| 2 | **新 applier 同趟登记** | `build/integration-wave.sh`（`APPLIERS_EXPLICIT`，`57216e26e2f11749→709b0a63528ad06c`）＋ `build/MilBridge/tools/applier-audit-expected.txt`（38→39 行，`6b7afa663f5f3c9e→3b031d92df5ea62d`）⇒ 消掉 R2「被摘掉零红」 |
| 3 | **`verify-all` 同趟三处改到 `#46`** | DECL 首行 `gen=#46` ＋ 口径句 `**\`#46\` 收官起 = 25 步**` ＋ 预登记标题；`verify-all.sh` `26cd2f7a45745f11→87d2e05c92ac0c35`；仓内自查牙 **`VERIFYALL_SELF=PASS names=25 decl=25 gen=#46 prose=OK prereg=PASS`** |
| 4 | **冻结工具加 `#46` 项** | `$HOME/w21-verify/w27-freeze.py`（备份 `$HOME/w45-backup/w27-freeze.py.before46`）：`prev='#44'`、`infp=None`、`prev_infp='493551db…'`、`prev_wsh='11f81eb9dfc60a12'`、`allow_changed={'bridge','pc','pf','win32shim'}`、`bs_fp` 冻结当时现算；语法 OK、参数纪律仍在 |
| 5 | 仓内第二载体旁证焦点修复 | `$HOME/w46-inrepo-a`：`DropDownOpened` ×2 / `DropDownClosed` ×2，闭合由驱动腿（`LeftAlt`/`Escape`）触发 ⇒ **与"开了立刻被关"不同形**（吻合，非证明） |

## 还没办（依赖 A/C 落地）
`defect-registry --emit`（D-G54 进声明表）｜`publish-milbridge.sh` 重发桥（`BRIDGE_SRC_FP` 现 `85e9afa176d60cd1` ≠ 发布记录 `794ea22406cc88ab`）｜整波 `WAVE_OWNER=… integration-wave.sh`｜`ARMS_OUT=… retake-arms-w23.sh`｜`repin-generation.py --why`｜闸门 ×2｜冻前 `verify-all`（**必 rc≠0**：声明类 `COLUMN-FLOOR`）｜`w27-freeze.py … '#46'`｜冻后 ×2。

## 并行车道与写域（避免互撞）
| 车道 | 写域 | 是否重构建 |
|---|---|---|
| W46A | `src/WpfGfx.Linux/Windowing/**`、`Interop/MilPresentation.cs`、报告 `build/MilBridge/W46A-report.md` | 是（桥） |
| W46C | 只加日志（`Interop/MilNative.cs` 如需）、报告 `build/MilBridge/W46C-report.md` | 是（桥，**必须与 A 串行**） |
| W46B | 只写 `docs/WAVE46-CLOSEOUT-RUNBOOK.md` | 否 |
| W46D | 只写 `$HOME/w46-popup-verify.sh`、`docs/WAVE46-DG54-CRITERIA.md` | 否 |
| 主控 | 收尾（整波/重取臂/重钉/闸门/verify-all/重冻/冻后×2） | 是 |

## 纪律事故（如实入册，车道自报）
- **共享件并发污染**：`hc` 应用目录（含 `wpfgfx_cor3.so`/`libwpfwin32.so`/`PresentationCore.dll`）被多车道**并发重装**，
  同时还有别人的 `dotnet HandyControlDemo.dll` 在跑 ⇒ W46A 那两趟"改后停摆"（`[SHOW_DIAG] SetWindowPos` 后 4 行 + `XIO: fatal IO error`）
  是**污染**而非修法；历史 60 份 `hc-*/app.log` 有 6 份同款，隔离下 2/2 不复现。
- **可能误杀邻居进程**：W46A 的 hang 探针曾用 `pgrep -x dotnet | head -1` 取 PID，当时机器上有别人（W46C）的 dotnet
  ⇒ **可能误杀过邻道 app**；此后改为"私有 app 目录 ＋ 开跑前 `dotnet` 计数为 0"。
- **本波规则（后补，后续车道照此）**：跑 hc 一律用**私有 app 目录**（`cp -p` 出整套件）＋**私有 display**；
  绝不 `pgrep/pkill` 取别人的 PID；重构建前后各记一次产物 sha，读数只认"跑前=跑后"的那些趟。

## `D-G54` 机制定案（W46C）＋ 修法
- **弹窗内容确实渲染了，但被呈现到主窗口 HWND `0x200004`**（一帧 413×274/439 条 skia 指令）；**弹窗 HWND `0x200008` 从未当过呈现目标**（`已呈现.*0x200008` = 0）。
- 因：`TryResolveTarget`（`MilPresentation.cs:745-772`）取**第一个**带 `NativeWindow` 的目标 ＋ `IMilChannel.Root` 是**通道级单槽**（被弹窗覆盖）。
- 修法：**根＋呈现目标下沉到 target/HWND 级**（设计稿 W46F）＋ 同趟补 `preflight` 台账的两条盲路（`MilNative.cs:143/:261`）。
- 我已更正的两处自家错读：「只有一条 SetRoot」（preflight 盲区）、以及早期 `[mil]` 预算在弹窗打开前就用尽导致的行数计数无效。
- **本波新规则**：桥侧的诊断预算必须**按 id 过滤**（`WPF_LINUX_CMDLOG_ID=0x35`），否则启动期就烧光；app-local `.so` 会被 `dotnet publish` 自动刷新 ⇒ **每趟跑前现场 `sha256sum`**（W46C 发现）。

## `D-G54` 修法：设计评审已到（W46F，`docs/WAVE46-PERTARGET-PRESENT-DESIGN.md` `9486f38c9a3d4898`）
- **关键纠偏**：存储**本来就是每目标一棵根**（`MilTarget.Root`，`MilCommandDispatcher.cs:349`）；按通道的只有**读者**
  ⇒ 改动 = 改那个读者 ＋ 补一笔"**根句柄的通道归属**"（句柄是每通道槽号 ⇒ 跨通道投影会静默画错树）。
- **上游模型**：`SetRoot` 每目标各一条、发在**主通道**；**OOB 从不在设根** ⇒ 「通道 3 无根」是**合规状态**（已从缺陷表述里撤回）。
- **7 处缺口 G1–G7 已转给实现车道 W46G**：排序｜**返回码聚合**（多目标"全部失败才带出失败"，否则弹窗关闭后主通道每次 Commit E_FAIL ⇒ managed 抛异常）｜
  尺寸逐目标＋打来源（弹窗目标 `Width/Height` = **1×1**，首帧有假阴性陷阱）｜进程级静态统计不能当逐目标判据｜
  "不是纯色"要有机器判据（`WPFGFX_ROOTDIAG=1` ＋ 从根可达 > 1）｜文档口径（本节）｜预检日志预算。
- **争议待判别**：W46C「弹窗内容被画进主窗」 vs W46F「那是主窗的树被按弹窗尺寸画（＝缺陷 A）」；
  判别判据 = **修后主窗指令数回到 ≈443**，骤降才是反证。

## 独立复验（W46I，`build/MilBridge/W46I-report.md` `9d4246598fbac9ef`）——**支持核心声称，推翻两处口径**
- **支持**：三趟独立复跑（:71/:73/:75/:79，各自私有副本）⇒ `HWND 0x200008 已呈现` = **2**（旧桥 0；含 `1x1/0 条` 与 `413x274/29 条` 两行）；`HWND 0x200004 已呈现 413x274` = **0**；`派发 id=0x35` = 2；preflight `id=0x35` = **2（旧桥 1）**；`被拒` = 0。
- **看图**：弹窗矩形色数 **206**、非白 **14.31%**、直方图 `白/#326CF3 蓝条 11196/#5E5E5E`；逐行 **10 段**（蓝条高 29 ＋ **8 条文本行**，峰值每行 **+17**）⇒ **完整 9 项列表**（选中 `正文1` ＋ `正文正文2…9`）。旧桥同区域 **1 色 / 0 非白**。
- **推翻①**：`已呈现.*0x200008` **词序敏感、恒 0**，不能当判据（W46G 已自陈，此处独立证实）。
- **推翻②（更值钱）**：`P2` 与 `P3` 有**互不重叠的盲区** —— 纯黑块 `P2=FAIL` 但 **`P3=PASS 103250`**；"窗口在、几何对、一像素不画" **`P2=PASS 色数=66`** 而只有 `P3=AE=0` 抓得住 ⇒ **承重的是 `P2 ∧ P3`**；`P3` 阈值须下调到能抓 AE=0（建议 `2000`）。已写入 `docs/WAVE46-DG54-CRITERIA.md` §8。
- **口径陷阱**：同时开 `MIL_TRACE=1` 时 **stderr 的 preflight 只有 1 条**（`诊断预算用尽（已打 400 条）`）⇒ 判据**必须读 `WPF_LINUX_MIL_LOG` 文件汇**；`从根可达=57` 是**呈现后稳态**（首次 ROOTDIAG 是 `=1`）。
- **单窗口回归**：行为 14 项与冻结基线 `:58-63` **逐字段相同**；但 `config` 有 **4 位**不同（`pc 45e7e0a4→043eff4b`、`pf a93097f7→366e9486`、`bridge 496951ad→e3ea0920`、`win32shim 11f81eb9→e700c383`）—— 因为**整波在复验期间重建了 pc/pf**（mtime 20:50:22 / 20:51:29）⇒ **冻结点四位一起重钉**（与冻结项 `allow_changed` 一致）。
- 我的判据臂已修：`settle_shot` 调用处不再 `>/dev/null`（保留 `HC_PV SETTLE …` 收敛行）。

## 整波链（W46H）落地状态（只读观测）
`build/.wave-done` = 20:51｜`pc` = `043eff4b1d8ecd7d`（20:50:22）｜发布桥 = `e3ea092010734f44`（20:33:12）｜
`build/MilBridge/arm-logs/*` 仍是 15:xx（**重取臂尚未落**）⇒ 链在跑（重取臂 → 重钉 → 闸门 ×2 → 冻前 `verify-all`）。

## 磁盘纪律（主控本轮实测，后续车道照此）
- **`.xwd` 是空间黑洞**：旧世代闸门目录里 **3804 个 = 15.6 GB**（单个 ~4.5 MB），而 `.png`（真正的视觉证据）每目录仅 ~17 MB。
  ⇒ 已删 `.xwd`、**保留全部 `.png/.log/.txt/.tsv`**（含 `ACCEPTANCE-BASELINE.md` 等文档引用过的读数与截图）⇒ `df` 从 **26G 可用/76%** 回到 **42G 可用/60%**。
- 记录：`$HOME/w46-evidence/CLEANUP.txt`（删了什么、多少、范围）；被报告引用的小件统一副本在 `$HOME/w46-evidence/`（5 MB，含 `MANIFEST.txt` 带 sha16）。
- **规则**：① 跑完即删 `.xwd`（png 已足够）；② 私有 app 副本（~113 MB/份）用完即删，用时现 `cp -p`；③ 只有**报告引用过**的小件才拷进 `$HOME/w46-evidence/`；④ 在飞的目录（如 `$HOME/w46h`）不碰，等车道收工后再剪。

## 冻结点现场读数（2026-09-19 21:3x，冻结前）
| 位 | 本波冻结前值（= `#44` 冻结） | 现值 | 变？ |
|---|---|---|---|
| `bridge` | `496951adff86a557` | **`e3ea092010734f44`**（5,019,968 B） | ✅ |
| `pc` | `45e7e0a46f5912c0` | **`043eff4b1d8ecd7d`**（3,601,408 B） | ✅ |
| `pf` | `a93097f7a918597f` | **`366e9486536bc291`**（6,119,424 B） | ✅ |
| `win32shim` | `11f81eb9dfc60a12` | **`e700c383ec1ecdc8`**（299,040 B） | ✅ |
| `windowsbase` `84a2826c471e60ea`／`provider` `1f9511a7ef395bfe`／`wic_shim` `56278c14b4ecd672`／`hbtextline` `e89fed55fd8e32bc`／`dwf` `de2d555105b7d04b` | — | 逐位未变 | — |

⇒ 与冻结项 `allow_changed={'bridge','pc','pf','win32shim'}` **一致**；`PRE=/home/links-dev/w46-pre.sha`（9 行，`069e6693d4c2d3d5`）已按"`#44` 冻结值"写好。
牙齿：`BASELINESHA=PASS live=ff3990dafa582831`、`BASELINEGEN=PASS decl_gen=#44`（**重冻前仍应是 #44**）。
链内部位移：`inputs_fp 4d7c973a… → 279a4790…（重钉后）→ a47546ec…（终态）`；`BRIDGE_SRC_FP` 两侧 `f10b4b297b2358e6`；`known-red.json 7deadeac97659e46 → 1fa4c4540fe1b69f`。
重取臂：**只有 `tline` 变**（`928b79e6a300cea0 → e061054f73c9a2e7`），三支 `tab-*` ＋ `textproto` 逐位不变（mtime 全晚于重取开始 ⇒ 非陈旧日志洗绿）—— 完全命中 runbook §3 预测。
闸门 ×2：`WPTD_GATE=PASS acceptance=2/2`、`BRIDGE_SRC_STALE=no`，行文件 `$HOME/w46h/gate-rows.txt`（`ab14f107c3b46908`，6 行 6 PASS）。

## 🆕 W1 —— `wpfgfx_cor3.so` 的 app-local 副本**没有任何链同步**（新风险，本波被真牙咬到）
- 现场：`publish-milbridge.sh`、`integration-wave.sh`（3.6 步）、`close-wave.sh:277`（**只 `find libwpfwin32.so`**）三条链**都不管桥副本** ⇒
  `samples/WpfFeatureProbe/bin/Release/net10.0/wpfgfx_cor3.so` 停在 `6fac9e722299a768`、`samples/ThirdPartyMini/bin/Debug/net10.0/wpfgfx_cor3.so` 停在 `496951adff86a557`；
  于是 `verify-all` 的 `ManagedLayer.Tests`（逐字断言 `DP1ReproTests.cs:154`）**非声明类红**，`check-applocal-sync.sh` 同趟报 `BRIDGE-ANCHOR=2 APPSYNC=MISMATCH`。
  `#44` 那趟之所以绿是因为当时权威**恰好**就是 `496951adff86a557`。
- **后果**：这份 `verify-all` 日志拿去冻结会 `w27-freeze.py:305` 当场 `AssertionError`（`nfail(2) != len(_expected_red)(1)`）。
- **本轮对策**：手工同步两份副本（`samples/**` 不在 `fp_inputs()` 覆盖面 ⇒ 无指纹影响）＋重跑冻前 `verify-all`（W46H 执行中）。
- **欠账（下一波办，别在本波末尾动判定件）**：把"桥副本同步"接进某条链或立一颗牙（`libwpfwin32.so` 有 `close-wave.sh:274-287`，桥没有）。

## 冻结就绪清单（本轮已办）
- `TXT` = `/home/links-dev/w21-verify/w46-record.txt`（103 行，`ae54db8b28bc87fb`，三段式齐，占位符 24/24 全被冻结器认识、零未知）—— 车道 W46J 起草。
- `PRE` = `/home/links-dev/w46-pre.sha`（9 行，`069e6693d4c2d3d5`，按 `#44` 冻结值）。
- 冻结项两处**已修**：`bs_fp 85e9afa176d60cd1 → f10b4b297b2358e6`（不修 ⇒ `:396` 当场红）、`prev_pc b1d3d5f33618a3d7 → 45e7e0a46f5912c0`（= `#44` 冻结值，与 `PRE` 一致）。
- 冻结命令（等新 verify-all 日志）：`python3 /home/links-dev/w21-verify/w27-freeze.py /home/links-dev/w46h/06-verify-all-pre2.log /home/links-dev/w46h/gate-rows.txt '#46'`。
- 之后：冻后 `verify-all` ×2（派车道）→ `CURRENT-STATE.md`/`handoff.md`/`ACCEPTANCE-BASELINE.md` 世代行收口。

## 收尾链的两份现场记录（车道 W46H / W46H2）
- **W1 的处置（已同步，4/4 ＋ 5/5 全等）**：`samples/WpfFeatureProbe/bin/Release/net10.0/wpfgfx_cor3.so` `6fac9e722299a768→e3ea092010734f44`、
  `samples/ThirdPartyMini/bin/Debug/net10.0/wpfgfx_cor3.so` `496951adff86a557→e3ea092010734f44`（备份在 `$HOME/w46h-backup/`）；
  `check-applocal-sync.sh` 由 `BRIDGE-ANCHOR=2` 变 **4 条全 `ANCHOR-OK`**；该牙单跑由 `rc=1`（逐字"测的是旧件"）变 **`rc=0`**。
- **冻前 `verify-all` 复跑**：`24 ✅ / 1 ❌`（**只有 `COLUMN-FLOOR`**，声明类）、`用例通过 871 跳过 2`、**863 s**；
  `ManagedLayer.Tests` 由 `❌1/76` 变 **`✅76/76`**（用例总数 795→871）。
  唯一趟间差异是 `FRAME_PRESENCE magenta_frames 42→41`、`THIRDPARTY frames 43→42`（时间分辨采样抖动，判据都 PASS）。
- **门禁行文件重生成**：`c656913130d4ff2b`（6 行 6 PASS，`date=21:46:57`、`run_dir=…/gate-e2`，行内 `config=` 与旧行逐字相同）。
  ⚠️ **如实记**：我在读行文件那一刻见到的 sha 是 `814418b8159b44d1`（同样 6 行 6 PASS），冻结用的就是当时那份；冻结器已把 6 行写进冻结件并由 `BASELINESHA=PASS` 机器核对 ⇒ 后续 `gate-rows.txt` 的再写只是**工作文件**，不影响冻结件。
- **W46H2 的静态断言模拟**（照抄 `w27-freeze.py:279-307`）：`_expected_red=['COLUMN-FLOOR']`、`nfail(1)==len(1)` ✔、`nstep=25` ✔、头注释含 ``**`#46` 收官起 = 25 步**`` ✔ ⇒ 与**实际冻结成功**互相印证。
- **常设债（W1，建议下一波立牙或接链）**：`publish-milbridge.sh:39/54`、`integration-wave.sh` 第 3.6 步、`close-wave.sh:277` **三条链都不管桥副本** ⇒ 样本下次重编可能再把 `samples/**` 的两份刷回旧件。
- `NOINFO`：`FRAME_PRESENCE`/`THIRDPARTY` 帧数抖动的成因未归因；`APPSYNC` 剩的是**在册**的 `tools/GeometryOracle/bin/Debug/…WpfGfx.Linux.dll` STALE＋既有 UNEXPECTED/DIVERGENT，与 `verify-all` 无涉。

## ✅ 冻结完成（`#46`）
`python3 /home/links-dev/w21-verify/w27-freeze.py /home/links-dev/w46h/06-verify-all-pre2.log /home/links-dev/w46h/gate-rows.txt '#46'` ⇒
**`基线已重冻为 #46；整份 sha16 = dd31a7701fc77829`（527,577 B）**；`BASELINESHA=PASS live=dd31a7701fc77829`、`BASELINEGEN=PASS decl_gen=#46 file_newest_gen=#46`、
`ARMLOG_SHA=PASS pass=5`、`COLUMN_FLOOR=PASS selfreport=PASS`、**两极化齐**（冻前三条红 ⇒ 冻后同批绿）。
冻结器自动改写 `docs/CURRENT-STATE.md:9` 的机器行与 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`；世代叙述由主控补（`docs/CURRENT-STATE.md` `98640a27e31e1b02`、`handoff.md` `b589b22f8eb7cf0c`）。
**待**：冻后 `verify-all` ×2（车道 W46K，`$HOME/w46k/post-freeze-{1,2}.log`）。

## ✅✅ 波 `#46` 完整收尾闭合（冻后 `verify-all` ×2）
| # | 时间 | rc | 耗时 | 步骤 | 用例 |
|---|---|---|---|---|---|
| run1 | 21:52:20→22:06:28 | **0** | 848 s | **通过 25 / 失败 0** | 871 通过 / 2 跳过 |
| run2 | 22:07:45→22:21:56 | **0** | 851 s | **通过 25 / 失败 0** | 871 通过 / 2 跳过 |

两趟逐字相同的关键行：
```
COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=1fa4c4540fe1b69f base=dd31a7701fc77829 corpus=0cebc0afd5142fbf
COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无
ARMLOG_SHA=PASS required=5 declared=5 pass=5 ｜ BASELINESHA=PASS live=dd31a7701fc77829
BASELINEGEN=PASS decl_gen=#46 file_newest_gen=#46 ｜ VERIFYALL_SELF=PASS gen=#46 prose=OK prereg=PASS
结论：✅ 全部通过
```
冻前那趟（`06-verify-all-pre2.log`）= `24 ✅ / 1 ❌`，唯一红 `COLUMN-FLOOR`（`bad= tline`）⇒ **红→绿，冻结生效**。

### 两处**我任务书写错、由车道纠正**（如实入册）
1. **"冻结标记 2"（记录文件里出现 `RE-FROZEN #46`）恒不触发**：`{GEN}` 的填充只写 `ACCEPTANCE-BASELINE.md`（`w27-freeze.py:459/472`），**不回写** `$HOME/w21-verify/w46-record.txt`（该文件至今仍是 `RE-FROZEN {GEN}`，计数 1）。
   ⇒ 正确标记 = `grep -c '^# RE-FROZEN #46' samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（本波实际靠"标记 1 的合取"在 **21:50:05** 命中，等待 13 min）。
2. **"`ARM-LOG-SHA` 冻后从红转绿"不成立**：`ARM-LOG-SHA` 步**冻前就是绿的**；红→绿的是 **`COLUMN-FLOOR` 步内部**的子读数 `COLUMN_FLOOR_ARMLOG`（`bad= tline` → `bad=无`）。**两颗牙名字像但不是同一颗**（前者只查臂日志形态，后者还比冻结块逐臂 `# ARM-LOG-SHA` 声明值）。
3. 顺带：「两趟逐字相同」这个更强口径在 `FRAMEPRESENCE`/`THIRDPARTY` 两步**不成立**（抓帧时序抖动：`magenta_frames 39/40`、`THIRDPARTY frames 42/41`），但两趟都 PASS，**不读成回归**。

### 车道自报的纪律事故
W46K 首版预检把脚本正文 heredoc 内联进命令行 ⇒ **`pgrep -f` 自匹配**（自己的 cmdline 含 `run-wpftextdemo.sh`/`verify-all.sh` 字面量）⇒ 预检恒不为 0；改用扫 `/proc/*/cmdline` 并排除 `$$`/`$PPID` 后正常。与"纪律 55"同族，留档。
