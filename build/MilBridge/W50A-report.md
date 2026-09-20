# 波 `#48` · 车道 `W50A` 报告 —— 整波链（**只跑链、不冻结**）

> **任务**：产品波 `#48`（修 `D-G56`：两个 applier 把插桩横幅插在**类属性块与类声明之间** ⇒ 属性挂错类 ⇒ `NameScope` 挂不上 ⇒ BAML 页加载即 abort）的收尾链
> 「`publish` → 整波重建 → 重取臂 → 重钉 → 闸门 ×2 → 冻前 `verify-all`」，**冻结由主控做**。
> **仓库根**：`R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（全程绝对路径）。
> **本报告的性质**：本车道**执行了全链 1–7 步**（步 4 重钉按主控 00:22 回执「照原任务书跑，别收回」执行，**只跑一次 `--why`**），报告是**读数记账**，不是判据、不替代预登记 `docs/WAVE48-PREREGISTRATION.md`。
> **纪律**：SDK 走 `export PATH="$HOME/.dotnet:$PATH"`；`dotnet -m:1`、`DOTNET_gcServer=0`；`nproc=3`；
> 全程**零 `pkill -f`**、零 `pgrep -x dotnet` 取 PID、零 `w27-freeze.py`、**零对任何判定输入的手写改动**（唯一写判定输入的动作 = 设计内的步 4 重钉）。
> ⚠️ **`verify-all.sh` 我全程没碰**：跑前 `sha16=5ee3ad984ee7412d`，跑后 **`5ee3ad984ee7412d`（逐位相同）** ⇒ 本趟读数**不受** `#47` 冻后第二趟那种「边读边改」污染（见 §9-6）。

---

## 0 摘要

### 0.1 逐步结论（一句话/步）

| 步 | rc | 耗时 | 一句话 |
|---|---|---|---|
| 1 `publish-milbridge.sh` | **0** | 10 s | 桥源未动 ⇒ 产物**逐位未变**（`e3ea092010734f44`／5,019,968 B）；`BRIDGE_SRC_FP` 现树==记录==`f10b4b297b2358e6` |
| 2 `WAVE_OWNER=w50a integration-wave.sh` | **0** | **129 s** | `失败步骤 0`；`APPLIER_AUDIT_SUMMARY appliers=25 ok=86 miss=0 red=0 rc=0`；波前==波后 `d1f473a9…`；**两个生成件 sha 与 W48D 逐位相同** |
| 3 `ARMS_OUT=$HOME/w50a/arms retake-arms-w23.sh` | **0** | 338 s | **只有 `tline` 变**（`3a6eca716ada5bdb → 960e28f59ee974e5`），其余四支逐位不变 ⇒ **完全命中预测** |
| 4 `repin-generation.py --why` → `--check` | **0 / 0** | — | `REPIN_GENERATION=APPLIED` → `REPIN_GENERATION=PASS`；`known-red.json 00a75a87ec5ed0d6 → 25c21ca0f33208ae` |
| 5 闸门 ×2 | **0 / 0** | 164 s / 160 s | 两趟 `WPTD_GATE=PASS acceptance=2/2`、`WPTD_SUMMARY=PASS tiers_passed=2/2`；行文件 **6 行 6 `result=PASS`** |
| 6 冻前 `verify-all` | **1** | **850 s** | `步骤通过 24  ❌ 失败 1`／`用例通过 871 跳过 2`／`结论：❌ 失败项：COLUMN-FLOOR`（**唯一失败项 = 声明类**，与预期一致）；`SKIP_GUARD=PASS x_state=available`

### 0.2 九位哪几位变了（三位，含 `pc`/`pf`）

| 位 | `#47` 冻结值 | 我开工时（00:11） | 我的链终态（00:45） | 归因 |
|---|---|---|---|---|
| `windowsbase` | `84a2826c471e60ea` | `79740e9ba7fbf9ca` | `79740e9ba7fbf9ca` | **W48D 的改**（链外）；本链重编**字节可复现** |
| `pc` | `043eff4b1d8ecd7d` | `043eff4b1d8ecd7d` | **`9465f9dce39e2dfc`** | 本链重编 ⇒ 变（被引件字节进 Roslyn 输入哈希） |
| `pf` | `366e9486536bc291` | `bd73f9e2376d67ac` | **`1011da6390c3bf1e`** | W48D 变一次 + 本链重编再变一次（同机制） |
| `bridge`／`win32shim`／`provider`／`wic_shim`／`hbtextline`／`dwf` | — | — | 与开工时**逐位相同** | 未动 |

⇒ `GENS['#48']['allow_changed']` 含 **`{'windowsbase','pc','pf'}`** —— 与主控 00:22 回执里填的集合**逐字吻合**。

### 0.3 🔴 本链现场发现（两条头条 + 两条附带，全在 §9 给足证据）

| 编号 | 一句话 | 谁登记 |
|---|---|---|
| **`D-G59`**（复现＋两极化正控） | 车道 **W48D 的私有 Xvfb `:66`** 在 `23:48:21/23:48:53` 活着，`verify-all.sh:370` 的 `pgrep -a Xvfb … \| sort -u` **字符串序让低号胜** ⇒ w49a 那趟冻后 `[0]` 选中 `:66`；该显示随后死掉 ⇒ **21 例 X 用例静默变跳过 ＋ `ManagedLayer.Tests` 硬红**。**我这一趟 `[0]` 选中常驻 `:97`，同一批用例 21 例**全部跑起来**（`76/0`、`SKIP_GUARD=PASS`）⇒ 两极化成立，w49a 那条红是**假红** | 主控已登记；本报告补**加害者定位＋两极化正控** |
| **`D-G60`**（**推翻主控预期**） | 主控原以为「`ARTIFACT_SRC_FP` 靠整波重建收敛」。实测**不收敛**（仍 `rc=2`）：`integration-wave.sh` 的 **`3.5/5`（写身份记录 `:456-461`）排在 `3.6/5`（app-local 副本刷新 `:463-475`）之前**，而 3.6 会覆盖 3.5 覆盖面里的一个被引件 ⇒ **记录一出生就是陈旧的** | 主控 00:22 已认并登记为 `D-G60` |

---

## 1 前置检查（P0–P9，全部现场重算）

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux; export PATH="$HOME/.dotnet:$PATH"
```

### P0 环境
`nproc=3`；`kernel=6.8.0-138-generic`（`uname -r`）；`host=linksdev-VirtualBox`。
**开工前的并发闸门**（任务书要求「每 60 s 查一次，空且持续 60 s 才开工，最多等 40 分钟」）：
我于 `23:53:37` 起用**独立脚本文件**（`$HOME/w50a/wait-quiet.sh`，判据正则与 `close-wave.sh:214-238`/runbook P9 同族；**以文件路径调用 ⇒ 自身 cmdline 不含判据词 ⇒ 无 `D-G34` 自匹配洞**）轮询：

```
23:54:20 busy n=2 memavail=2235MB      ← 别的车道在跑冻后 verify-all（$HOME/w49a/ 第二趟）
00:08:20 busy n=2 memavail=2722MB
00:09:20 QUIET#1 memavail=2748MB
00:10:20 QUIET#2 memavail=2755MB
QUIET_CONFIRMED 2026-09-20 00:10:20
```
⇒ **等满 16 min 43 s，静默 ≥60 s 且 `MemAvailable=2755 MB ≥ 1500` 才起跑**。全链期间我**没有再起第二个重活**（每步串行）。
`Xvfb`：开工前后**只有常驻 `68922 Xvfb :97 -screen 0 1280x1024x24`**（`Sep 18 23:13:36` 起，`etime` 已 1 天）；`:95` DOWN。

### P1 配置唯一声明
```
Release
SELFCONFIG_MSBUILD_自产件图=PASS shell=Release msbuild=Release proj=build/System.Xaml.Linux/System.Xaml.Linux.csproj
SELFCONFIG_MSBUILD_样本图=PASS shell=Release msbuild=Release proj=samples/WpfTextDemo/WpfTextDemo.csproj
SELFCONFIG_CHECK=PASS
```

### P2 两颗基线牙（开工那一刻，`00:12` 前后）
```
BASELINESHA=PASS live=9b9e3cb7bcb8280b decl=9b9e3cb7bcb8280b
BASELINEGEN=PASS decl_gen=#47 file_newest_gen=#47
BASELINE_BYTES=553550
BASELINEDUP=PASS n=0
```
⇒ 树上当前冻结世代仍是 **`#47`**（`#48` 尚未冻），这是 `COLUMN-FLOOR` 冻前必红的**结构性原因**（§7）。

### P3 其余三颗牙（**开工那一刻**）
```
ARMLOG_SHA=PASS shape=flat logdir=…/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0
COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS \
  reg=00a75a87ec5ed0d6 base=9b9e3cb7bcb8280b corpus=0cebc0afd5142fbf
DEFREG=PASS declared=94 route_ids=94（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
```
（`DEFREG` 已由主控收敛为 **PASS**；`#46` 手册 P7 记的那个 `DEFREG=FAIL` 不再是现场。）

### P4 当前九位（口径逐字照 `close-wave.sh` 的 `NINE`／`$HOME/w21-verify/w27-freeze.py:333-341`）
见 §0.2 表。开工时（`00:11:39`）九位现场值：
```
e3ea092010734f44 5019968 …/wpfgfx_cor3.so
043eff4b1d8ecd7d 3601408 build/PresentationCore.Linux/bin/Release/PresentationCore.dll
bd73f9e2376d67ac 6119424 build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll
79740e9ba7fbf9ca 1111552 build/WindowsBase.Linux/bin/Release/WindowsBase.dll
1f9511a7ef395bfe  103936 build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll
abf6879c027c5e73  299040 src/WpfGfx.Linux.Native/bin/libwpfwin32.so
56278c14b4ecd672   70728 build/DirectWrite.Linux/wic-shim/libwpfwic.so
e89fed55fd8e32bc  290825 build/shims/PresentationCore.HbTextLine.cs
de2d555105b7d04b   39936 build/DirectWriteForwarder.Linux/bin/Release/DirectWriteForwarder.dll
```

### P5 `inputs_fp` 与 `BRIDGE_SRC_FP`
`inputs_fp` **照抄真函数**（`sed -n '70,189p' build/close-wave.sh` 抽成 `$HOME/w50a/fp_inputs_body.sh` 现场跑，**未手抄、未复制函数体到别处**）：
```
开工时 (00:11)  b983d9bee6c36b5e88dd1a3587d8724c3680479e521cb5c1531c0fc1b868c9bf
波后   (00:14)  b983d9bee6c36b5e88dd1a3587d8724c3680479e521cb5c1531c0fc1b868c9bf   ← 与开工时逐位相同（波中无人手写覆盖面）
重钉后 (00:24)  cad0801cf1dff2fdf1600b803315d1c57b0d2afcc9ebf45e170f2b3885677da4
终态   (00:45)  cad0801cf1dff2fdf1600b803315d1c57b0d2afcc9ebf45e170f2b3885677da4   ← verify-all 不改它
```
（`#47` 冻结块记的是 `8a8661b926e47489b9840736992209d3977ab10429e42dcdcbe9df1a5a0ddeaf`。）
`BRIDGE_SRC_FP`：现树 `f10b4b297b2358e6 BRIDGE_SRC_N=78` == 发布记录 ⇒ 桥身份自检不会 `exit 5`。

### P6 native／桥 新鲜度
`newest_src` 早于权威件 ⇒ 可跳过 native 重建（**我确实没重建 native**，`win32shim` 逐位未变可作旁证）。
桥：源指纹两侧一致（P5）⇒ **重发是"设计内保留动作"，不是必需**；我仍按任务书跑了步 1，产物**逐位未变**（§2）。

### P7 缺陷编号对账 ⇒ **PASS declared=94**（见 P3）

### P8 应用器审计（开工那一刻）
```
APPLIER_AUDIT_SUMMARY appliers=25 ok=86 miss=0 red=0 rc=0
```
⇒ `#46` 手册 §1-P8 记的 `appliers=24 ok=83` 已过期，现为 **25/86**（含 `patch-presentationcore-hwndtarget-trace`）。

### P9 哨兵与并发
```
[ -e /tmp/bridge-republish.lock ]  ⇒ 无重发锁
pgrep -af -- 'verify-all|run-wpftextdemo|integration-wave|retake-arms|publish-milbridge|dotnet build' | grep -v pgrep
  （00:10:20 起全链期间一律为空；唯一的例外是起跑前那条别的车道的 verify-all，已被闸门等到退出）
```

### 1.1 `D-G56` 的**产品形状**我自己独立核过（不只信 W48D）

```bash
grep -n 'class DependencyObject' build/WindowsBase.Linux/DependencyObject.Linux.cs   # :614
grep -n 'class FrameworkElement' build/PresentationFramework.Linux/FrameworkElement.Linux.cs  # :306
```
```
:613    [System.Windows.Markup.NameScopeProperty("NameScope", typeof(System.Windows.NameScope))]
:614    public class DependencyObject : DispatcherObject          ← 属性**紧贴**类声明 ✅

:303    [StyleTypedProperty(Property = "FocusVisualStyle", StyleTargetType = typeof(Control))]
:304    [XmlLangProperty("Language")]
:305    [UsableDuringInitialization(true)]
:306    public partial class FrameworkElement : …               ← 三条属性**紧贴**类声明 ✅
```
**修前的同一处**（备份 `$HOME/w48d-backup/build/…`，`sha16 cdd5867fc742ffee`／`61a5f1e45e6017fb`）：
```
[System.Windows.Markup.NameScopeProperty(…)]        ← :52
// =====================================================================================   ← :53 插桩横幅**插在属性块与类声明之间**（缺陷现场）
internal static class WpfLinuxDpValueTrace …
public class DependencyObject : DispatcherObject    ← :614
```
两个 applier 的**新锚**（现件）：
- `src/WpfGfx.Linux.Native/tools/patch-windowsbase-dpvalue-trace.py:643` `WB_TYPE_HEAD_ANCHOR = ('    /// <summary>\n' '    ///     DependencyObject is an object that participates in the property dependency system\n')`，由 `:848-849` 的 `("W0 插桩类本体（**插在 doc 注释之前** ⇒ 属性块＋类声明保持紧贴，`D-G56`）", WB_TYPE_HEAD_ANCHOR, TRACE_CLASS + WB_TYPE_HEAD_ANCHOR)` 使用；
- `…/patch-presentationframework-mirror-trace.py:263` `FE_TYPE_HEAD_ANCHOR = ('    /// <summary>\n' '    ///     The base object for the Frameworks\n')`，由 `:295-296` 使用。
- 两者的**防复发判据**（`guard_wb` `:938-968`／`guard_relapse` `:358-390`）跟着 `--check` 一起跑：① 任何 `[Attr]` 行的**下一非空行**不得是插桩横幅；② 紧贴属性行数 ≥ 下限（`WB_ATTR_MIN=2`／`FrameworkElement=3`）。

---

## 2 步 1 `bash build/publish-milbridge.sh` —— rc = **0**（10 s）

```bash
cd $R; export PATH="$HOME/.dotnet:$PATH"; export DOTNET_gcServer=0
PRE:  2026-09-20 00:11:39  loadavg=0.61 0.90 1.34  memavail=2740MB
bash build/publish-milbridge.sh > $HOME/w50a/01-publish.log 2>&1 ; # rc=0
POST: 2026-09-20 00:11:49  loadavg=0.99 0.97 1.35  memavail=2699MB
```
关键原文（`$HOME/w50a/01-publish.log`）：
```
== 指纹（供核对/记档）
  wpfgfx_cor3.so        5019968 B  e3ea092010734f4441e3d091
  libwpfwic.so            70728 B  56278c14b4ecd6722f4cddf0
  BRIDGE_SRC_FP=f10b4b297b2358e6 BRIDGE_SRC_N=78
```
- 产物 `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` = **`e3ea092010734f44`／5,019,968 B**，**与开工前逐位相同**（mtime 仍是 `9月19 20:33` ⇒ 增量发布没有重写它）。
- 桥源两侧一致：`现树=f10b4b297b2358e6 记录=f10b4b297b2358e6`。
- ⚠️ 同趟 `APPSYNC=MISMATCH`（**登记在册的**长期红，不是本波引入，且**本脚本不改写任何目录**）：
  ```
  计数：OK=116  MISMATCH=1（STALE=1  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=12[DECL-GAP-EQ=12 DECL-GAP-DIFF=0]
        DIVERGENT=1  NO-AUTHORITY=0  LIB-COPY=21  SKIP(obj)=10  SKIP(stub)=12  SKIP(ref)=12
        RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0
  APPSYNC=MISMATCH（…）
  ```
  ★ **桥的绝对锚是干净的**：`BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`（发布记录 `BRIDGE_SO_SHA256=e3ea092010734f4441e3d091…` 与副本一致）。
  同一条检查器**独立重跑**（`00:33`，波**之后**）给出**不同**的展开：`DIVERGENT=3`、`UNEXPECTED=12[DECL-GAP-EQ=10 DECL-GAP-DIFF=2]`，多出的两条是**未声明副本**（`samples/ThirdPartyMini/bin/Debug/net10.0/{ReachFramework,PresentationCore}.dll` = `f4836ae36cbe80e1`／`043eff4b1d8ecd7d`，即旧代）。⇒ 3.6 只刷**声明图内**的副本 ⇒ 波后**未声明副本的散度变大**（见 §9-7）。

---

## 3 步 2 `WAVE_OWNER=w50a bash build/integration-wave.sh` —— rc = **0**（**129 s**）

```bash
PRE:  2026-09-20 00:11:55  loadavg=1.07 0.98 1.36  memavail=2720MB
WAVE_OWNER=w50a bash build/integration-wave.sh > $HOME/w50a/02-integration-wave.log 2>&1 ; # rc=0  129s
POST: 2026-09-20 00:14:04  loadavg=4.26 2.55 1.90  memavail=1597MB
```
关键原文：
```
APPLIER_AUDIT_SUMMARY appliers=25 ok=86 miss=0 red=0 rc=0
=== 3.5/5 生成物身份指纹（PC/WindowsBase/PF 的源身份；债务 #20 同族） ===
ARTIFACT_SRC_FP proj=PresentationCore     fp=4298d1b991bdfea7 n=1373 peer_fp=4e434fab7468feeb peer_n=8 state=written
ARTIFACT_SRC_FP proj=WindowsBase          fp=3ba6fbd4e99387e9  n=326 peer_fp=2a2ed993f748365d peer_n=2 state=written
ARTIFACT_SRC_FP proj=PresentationFramework fp=76cd3743d1b7a56b n=1362 peer_fp=7c79696509b6cf09 peer_n=9 state=written
  波前指纹 d1f473a9021278c3ed70925ff0de09d3bdc39050914d70f5850216433c2eaff3
  波后指纹 d1f473a9021278c3ed70925ff0de09d3bdc39050914d70f5850216433c2eaff3
  ✅ 一致 ⇒ 本轮构建结果与"波后树"对得上（没有编辑竞态）
=== 集成波结束：失败步骤 0 ===
```
（`波前/波后指纹` = `integration-wave.sh:515` 自印的**它自己**的输入指纹函数，**不是** `close-wave.sh` 的 `fp_inputs()`；两者别混。`fp_inputs()` 的现场值见 §1-P5。）

### 3.1 🔴 生成件 sha 复核（**主控点名的那两条**）—— ✅ 通过
```bash
sha256sum build/WindowsBase.Linux/DependencyObject.Linux.cs        # 期望 2985c671c57c7775
sha256sum build/PresentationFramework.Linux/FrameworkElement.Linux.cs  # 期望 3af06981155e89aa
```
```
2985c671c57c7775  184597 B  build/WindowsBase.Linux/DependencyObject.Linux.cs
3af06981155e89aa  292005 B  build/PresentationFramework.Linux/FrameworkElement.Linux.cs
```
⇒ **与 W48D 的 sha 逐位相同**，**没有被刷回旧值** ⇒ 两个 applier 的**新锚**确实被 integration-wave 调用到了（applier 现件 `5203f958c234882f`／`1b9852b037da70f1`，与任务书给的值一致）。
（对照：修前的生成件是 `cdd5867fc742ffee`／`61a5f1e45e6017fb` ⇒ 本波**确实改了这两个生成件**，不是"恰好没跑"。）

---

## 4 步 3 重取五臂 —— rc = **0**（338 s）

```bash
PRE:  2026-09-20 00:15:39  loadavg=1.19 1.98 1.76  memavail=2474MB
ARMS_OUT=$HOME/w50a/arms bash build/MilBridge/tools/retake-arms-w23.sh > $HOME/w50a/03-retake-arms.log 2>&1
ARMS_RC=0  elapsed=338s
POST: 2026-09-20 00:21:17  loadavg=1.27 1.59 1.66  memavail=2459MB
```
子臂 rc（脚本自印）：`tline rc=1`／`tab-zero rc=1`／`tab-anchor rc=0`／`tab-rtl rc=0`／`textlineproto rc=0`（与 `#47`/`#48` 同形；`rc=1` 是这些臂**自己的判定面本来就有在册红**，不是仪器失败）。

### 4.1 逐支读数（**稳态值 ＋ 复读两遍**）

按 runbook §13-1（并跑时脚本自印的 sha 是**写中途值**）我做了**静默后两次复读**：

| 支 | 重取前（备份） | 重取后 稳态 | 位移 | `links` | mtime | 预测 | 命中 |
|---|---|---|---|---|---|---|---|
| **`tline`** | `3a6eca716ada5bdb` | **`960e28f59ee974e5`** | **变了** | 2 | 00:17:57 | 变 | ✅ |
| `tab-zero` | `9150c3a26a3cb789` | `9150c3a26a3cb789` | 未变 | 2 | 00:18:30 | 不变 | ✅ |
| `tab-anchor` | `1c43a12dcaa5718a` | `1c43a12dcaa5718a` | 未变 | 2 | 00:21:02 | 不变 | ✅ |
| `tab-rtl` | `92570318851ca7e8` | `92570318851ca7e8` | 未变 | 2 | 00:21:08 | 不变 | ✅ |
| `textlineproto` | `4bceceeed570ba70` | `4bceceeed570ba70` | 未变 | 2 | 00:21:17 | 不变 | ✅ |

复读 #1 `00:24:26`、复读 #2 `00:24:32` **逐位相同**；且**各臂 mtime（00:17:57–00:21:17）全部晚于重取开始时刻 `00:15:39`** ⇒ 不是陈旧日志（runbook §4「反向陷阱」的机器判据）。
`find build/MilBridge/arm-logs -type f -name '*.log' | wc -l` = **5**（不是 0）。

### 4.2 为什么只有 `tline` 变（机制钉死，不靠信 runbook §3）
`build/MilBridge/arm-logs/tline.log:6-9` 自报权威件 sha，**逐字**：
```
  [applocal] DirectWriteForwarder.dll：已与权威一致（de2d555105b7d04b）
  [applocal] DirectWrite.Linux.Provider.dll：已与权威一致（1f9511a7ef395bfe）
  [applocal] PresentationCore.dll：已与权威一致（9465f9dce39e2dfc）          ← == §0.2 的 pc ≈ 新值
  [applocal] WindowsBase.dll：**陈旧 84a2826c471e60ea → 已同步为权威 79740e9ba7fbf9ca**
```
⇒ `tline` 自报 **`pc` 与 `windowsbase` 两个位移位**，而 `pc` 本波**确实变了字节** ⇒ 命中。
另：`tline` 的 `[T0.7]` 段也自报 `一致 4/4（权威 PC=9465F9DCE39E2DFC cfg=Release）`。
逐行 `diff`（重取前备份 vs 重取后）**共 32 行 / 8 个 hunk**，**全部**是运行相关字段：`pc`/`windowsbase` 自报值、`已用时间 00:00:01.41→00:00:01.54`、**上一趟自产 artifact 的 sha/mtime（自指）**、带日期戳的输出名（`tline-ledger-lines-20260919-2307.txt → …-20260920-0017.txt`）、`mktemp` 路径（`/tmp/tmp.E3Mn6Bgryz → /tmp/tmp.gfcyEdX4x5`）。
⇒ 与 `#47` 车道记的「`tline.log` 程序上**不可复算**」**逐条同形**，**无一处是产品位移信号**。而三支 `tab-*` 只自报 `CoverageProbe/Program.cs`（`run.sh = 711f39f468f61cc8`、`Parity.cs = 149dd986a642fdfc`，本波没动）⇒ 逐位不变。

---

## 5 步 4 重钉（`--why` → `--check`）—— rc = **0 / 0**

主控 `00:22` 回执：「步 4 重钉：照原任务书跑，别收回」⇒ **我执行，且只跑一次 `--why` 那趟**（重钉不幂等）。

```bash
python3 build/MilBridge/tools/repin-generation.py \
  --why '波48：修 D-G56（applier 插桩锚上移到属性块之外 ⇒ windowsbase/pf 生成件变）＋整波重建 ⇒ pc 可能变字节；重取五臂后同趟钉齐' \
  > $HOME/w50a/04-repin.log 2>&1 ; # REPIN_RC=0
```
```
REPIN_GENERATION=APPLIED
  generation.instr_run_sh = 711f39f468f61cc8
  generation.instr_program_cs = 149dd986a642fdfc
  generation.instr_shim = e89fed55fd8e32bc
  generation.evidence_log_sha256 = 960e28f59ee974e5
  entries[*].caliber 改动字段数 = 0
```
```bash
python3 build/MilBridge/tools/repin-generation.py --check > $HOME/w50a/04-repin-check.log 2>&1 ; # REPIN_CHECK_RC=0
```
```
REPIN_GENERATION=PASS（世代三项 + 五臂 + 证据日志 + 4 条 entries 的 caliber 全部一致）
```

### 5.1 `known-red.json` before/after

| 项 | before | after |
|---|---|---|
| 件 sha16 | **`00a75a87ec5ed0d6`** | **`25c21ca0f33208ae`** |
| 字节 | 61,554 B | 61,815 B |
| `generation.evidence_log_sha256` | `3a6eca716ada5bdb` | **`960e28f59ee974e5`** |
| `generation.arm_logs.tline` | `3a6eca716ada5bdb27a5e5def916c6d54b01f0efe7c75c5f4c42a7b5b4d49183` | `960e28f59ee974e58348e7b22690cdccb89f57ce825f866f4019f2060a73ca22` |
| `arm_logs.tab-zero/tab-rtl/tab-anchor/textlineproto` | — | **逐字未变** |
| `generation.instr_run_sh / instr_program_cs / instr_shim` | `711f39f468f61cc8` / `149dd986a642fdfc` / `e89fed55fd8e32bc` | **同**（三项本来就没动） |
| `entries[]` 条数 | 4 | **4**（未增减） |
| `arms_retaken.history` | 末条 `when=2026-09-19 23:11:54`（波47 的 why） | 追加 `when=2026-09-20 00:24:34`（我的 why，**只追加不覆盖**） |

逐行 `diff`（`$HOME/w50a-backup/known-red.json.pre-repin` vs 现场）**共 19 行 / 3 组**：① `evidence_log_sha256`；② `arm_logs.tline`；③ `arms_retaken` 的 `when/why`（同一 `why` 落在两处：`generation.arms_retaken` 与 `_FIELDTABLE`/changelog 段）。**没有任何 `entries[*]` 或 `caliber` 主动改**（`改动字段数 = 0`）⇒ 与 runbook §4「要钉齐的四处」逐条对上。
备份：`$HOME/w50a-backup/known-red.json.pre-repin`（sha16 `00a75a87ec5ed0d6`，与 before 逐位相同 ⇒ 备份有效）。

---

## 6 步 5 闸门 ×2 —— rc = **0 / 0**

```bash
G=tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh
rm -f $HOME/w50a/gate-rows.txt                     # ← 先删旧行文件（任务书 §5.4 要求）
WPTD_RUN_DIR=$HOME/w50a/gate-e WPTD_BASELINE_OUT=$HOME/w50a/gate-rows.txt \
  timeout 900 bash "$G" 60 --tier both > $HOME/w50a/05-gate-e.log 2>&1     # GATE_E_RC=0  164s（00:24:40 起）
WPTD_RUN_DIR=$HOME/w50a/gate-f  timeout 900 bash "$G" 60 --tier both --no-build \
  > $HOME/w50a/05-gate-f.log 2>&1                                          # GATE_F_RC=0  160s（00:27:24 起）
```
两趟**逐字相同**的四条机读行：
```
WPTD_BRIDGE_SRC_STALE=no basis=pub=f10b4b297b2358e6 now=f10b4b297b2358e6 so_file_match=yes
WPTD_SUMMARY=PASS tiers_passed=2/2
WPTD_GATE=PASS acceptance=2/2 line_advance=PASS
（脚本收尾：无孤儿）
```
行文件 `/home/links-dev/w50a/gate-rows.txt`（**sha16 `439a9c038c476adc`**，9,298 B，mtime `00:27:23`）：
```
# BASELINE-HEADER date=2026-09-20T00:24:40+08:00 display=:97 host=linksdev-VirtualBox kernel=6.8.0-138-generic
#   loadavg=0.39 0.95 1.38  cpu=3核
#   mem_available=2527 MB  mem_total=7923 MB
#   run_dir=/home/links-dev/w50a/gate-e  repeat=3  timeout=60s  tier=both
#   git_head=(no git) samples_src=samples/WpfTextDemo  runner=run-wpftextdemo.sh
BASELINE tier=default rep=1 config=pc:9465f9dce39e2dfc,bridge:e3ea092010734f44,pf:1011da6390c3bf1e,provider:1f9511a7ef395bfe,win32shim:abf6879c027c5e73,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w50a/gate-e
BASELINE tier=default rep=2 … （同上，逐字相同）
BASELINE tier=default rep=3 … （同上，逐字相同）
BASELINE tier=env     rep=1 config=（同 config）… drawn=144 … colors=2945 … result=PASS
BASELINE tier=env     rep=2 … （同上）
BASELINE tier=env     rep=3 … （同上）
#   CENSUS…#   CWIC…#   WIC_NATIVE… refuse=0#   CENSUS_ORPHANS before=0 after=0；自起 Xvfb=无）
```
计数（现场算）：
```
grep -c '^BASELINE ' $HOME/w50a/gate-rows.txt                 ⇒ 6
grep -o 'result=[A-Z]*' … | sort | uniq -c                    ⇒ 6 result=PASS
grep -c 'pc:9465f9dce39e2dfc' …                               ⇒ 6      ← 冻结器硬要求的"终态 pc"
grep -c 'pf:1011da6390c3bf1e' …                               ⇒ 6      ← 冻结器硬要求的"终态 pf"
```
⇒ `w27-freeze.py:398-402` 的三条 assert（行数 == 6、全 `result=PASS`、每行含终态 `pc:`/`pf:`）**现场逐条满足**。

---

## 7 步 6 冻前 `bash verify-all.sh` —— rc = **1**（850 s）

```bash
PRE:  2026-09-20 00:31:27  loadavg=0.38 0.82 1.20  memavail=2514MB
bash verify-all.sh > $HOME/w50a/06-verify-all-pre.log 2>&1 ; # rc=1  850s
POST: 2026-09-20 00:45:37  loadavg=0.85 1.07 1.19
verify-all.sh sha16 跑前 = 5ee3ad984ee7412d ；跑后 = 5ee3ad984ee7412d   ← 逐位相同（无中途改动）
```

### 7.1 `[0]` 段 —— **本趟选中的显示号（主控要求写进报告）**
```
[0] Xvfb（目标 :99）
  ✅ 复用已运行的 Xvfb（实测 display :97，注意不是 :99）
  DISPLAY=:97（已用 xdpyinfo 验证可连）
  X_STATE=available（判据：xdpyinfo 对 DISPLAY=:97 成功 ⇒ available）
```
起跑前我现场核过候选集：`pgrep -a Xvfb` ⇒ **只有 `68922 Xvfb :97`**（`/tmp/.X11-unix/` 下 `X0`/`X1`/`X10` 是**无属主死 socket**，不带进程 ⇒ 不会被 `:370` 那条 `pgrep -a Xvfb` 枚举到）。⇒ 本趟**没有** `D-G59` 形态的劫持。

### 7.2 结论区（日志原文，`$HOME/w50a/06-verify-all-pre.log` 尾）
```
======================================================
 步骤通过 24  ❌ 失败 1
 用例通过 871  跳过 2
 D-G17 跳过汇总（实测/上限；上限 = 静态＋语料＋X_STATE=available 的 X 项）：Rendering.Tests=2/27
 SKIP_GUARD=PASS x_state=available x_suite_skipped=0 x_suite_units=0 x_suite_corpus_max=0 total_skipped=2 violations=none reason=none
 结论：❌ 失败项：COLUMN-FLOOR
======================================================
```
**失败步名逐个 = `COLUMN-FLOOR`（唯一一个）**，且它是**声明类**（冻前必红、冻后必绿）：步 `[14]` 原文
```
  COLUMN-FLOOR                 ❌  (rc=1)
      COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline
      COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch \
        pass=3 fail=1 noinfo=0 selfreport=PASS reg=25c21ca0f33208ae base=9b9e3cb7bcb8280b corpus=0cebc0afd5142fbf
```
`bad= tline` 的结构性原因：**基线块还是 `#47` 冻结值**（`base=9b9e3cb7bcb8280b`、`BASELINEGEN=PASS decl_gen=#47`），而 `tline` 已被重取并重钉入 `known-red.json`（`reg=25c21ca0f33208ae`）⇒ 两边必然不一致，**冻后转绿**。**主控没有别的非声明类红要处理。**

### 7.3 逐套件读数（**与 w49a 那趟的对照是本报告的关键正控**）

| 套件 | w48a（23:17，健康） | **w49a（23:48，被 `:66` 劫持）** | **w50a（00:31，本趟）** |
|---|---|---|---|
| Commands.Tests | 562 通过 / 0 跳过 | 562 / 0 | **562 / 0** |
| Rendering.Tests | 162 / 2 | 162 / 2 | **162 / 2** |
| Windowing.Tests | 44 / 0 | **26 / 13 ⚠️** | **44 / 0** |
| HelloMil.Tests | 19 / 0 | **18 / 1 ⚠️** | **19 / 0** |
| ManagedLayer.Tests | 76 / 0 | **❌ 49 / 26 ＋ 1 FAIL** | **76 / 0 ✅** |
| Presentation.Tests | 8 / 0 | **1 / 7 ⚠️** | **8 / 0** |
| 合计 | 871 通过 / 2 跳过 | 769 / 23，`SKIP_GUARD=FAIL` | **871 / 2，`SKIP_GUARD=PASS`** |

⇒ 同一棵树、只差 `[0]` 选中的显示号，`ManagedLayer.Tests` 由 **❌** 变 **✅ 76/0**、`x_suite_skipped` 由 **21** 变 **0** ⇒ §9-4 的 `D-G59` 假红判定**有两极化读数支撑**（不是"我觉得是假红"）。

### 7.4 重钉后、`verify-all` 之前/期间我另外采的三颗牙
```
ARMLOG_SHA=PASS shape=flat required=5 declared=5 pass=5 fail=0 noinfo=0        ← 重钉后它**已经绿**
COLUMN_FLOOR_ARMLOG=FAIL bad= tline   ⇒ COLUMN_FLOOR=FAIL                       ← 冻前唯一红，声明类
BASELINESHA=PASS live=9b9e3cb7bcb8280b decl=9b9e3cb7bcb8280b
BASELINEGEN=PASS decl_gen=#47 file_newest_gen=#47
```
★ 与 runbook §12-2 的现场纠正一致：**`ARM-LOG-SHA` 与 `COLUMN_FLOOR(ARMLOG)` 不是同一颗牙** —— 冻前绿的是 `ARM-LOG-SHA`，**红→绿的才是 `COLUMN_FLOOR_ARMLOG`**。别把"冻后转绿"记在 `ARM-LOG-SHA` 头上。

### 7.5 跑后九位复核（`verify-all` 不改九位）
与 §0.2 终态**逐位相同**；五臂 sha/mtime/`links` 也**未变**（`tline 960e28f59ee974e5 links=2 00:17:57` … `textlineproto 4bceceeed570ba70 links=2 00:21:17`）。

---

## 8 偏离预测的位移（逐条，含"预测错了"）

| # | 位移 | 谁预测的 | 判定 |
|---|---|---|---|
| 1 | **`pc` 变了字节**（`043eff4b1d8ecd7d → 9465f9dce39e2dfc`） | 预登记 §3「`pc` **可能**（引用了被改的生成件 ⇒ 重编即变字节）」 | **命中**（"可能"→"确实"）；机制由仓内工具自己的判据文本坐实，见 #2 |
| 2 | **`pf` 变了字节**（`bd73f9e2376d67ac → 1011da6390c3bf1e`） | 预登记 §3「`pf`（必）」 | **命中**。机制**不是我推断的**，是 `build/artifact-src-fp.py --check` 的**判据原文**：<br>`state=stale note=kind=peer；**被引产物变了**（源一个字没动，但 Roslyn 会把被引件字节纳入输入哈希 ⇒ 本工程产物同样会变）：build/PresentationCore.Linux/bin/Debug/PresentationCore.dll 043eff4b1d8ecd7d→9465f9dce39e2dfc`<br>⇒ `windowsbase` 元数据变（属性搬家）⇒ `pc` 变 ⇒ `pf` 变 |
| 3 | **`windowsbase` 本链重编后逐位未变** | 预登记未直接预测"重编是否可复现" | 未见异常（`#47` 同形：`pc`/`pf`/`windowsbase` 重编字节可复现） |
| 4 | 🔴 **`ARTIFACT_SRC_FP` 不收敛（仍 `rc=2`）** | **主控预期「你的整波重建会把它收敛」** | **预测被推翻** ⇒ 主控已登记 `D-G60`，详见 §9-1 |
| 5 | 九位**只动三位**、`bridge` 未动 | 任务书「桥源未动 ⇒ 预期产物仍 `e3ea092010734f44`」/ 预登记「`bridge` 预期不变」 | **命中** |
| 6 | **主控给的 `vfile_sha16=50e8fb979a979921` 已过期** | 主控 00:19 消息 | 现场 `build/MilBridge/tools/verify-all-step-check.sh` 自报 **`VERIFYALL_SELF=PASS names=25 decl=25 gen=#48 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=5ee3ad984ee7412d`**，与我 `sha256sum verify-all.sh` 现场值**一致** ⇒ 冻结记录请用 **`5ee3ad984ee7412d`** |
| 7 | 同一条 `check-applocal-sync.sh` **两次读数不同** | 无人预测 | 见 §9-7（波 3.6 只刷声明图内的副本 ⇒ 波后**未声明**副本散度变大） |
| 8 | `integration-wave` 只要 **129 s**（手册预算 13 min 是冷值）、`retake-arms` **338 s**（手册 ~10 min） | runbook 时长预算 | 非位移，只是**手册值是冷/旧值**；与 `#47`/`#48` 的 168 s/6m22s 同量级 |
| 9 | 闸门 `colors` `3960 → 4112`（default 档）、`drawn 260 → 261` | 无人预测 | **非判定量**（门禁判的是 `result=PASS`/`frames_*`/`capture`/`scroll`/`cross_ae`）；如实记，不当作回归也不当作改善 |

---

## 9 现场发现（四条；每条都给"文件:行 + 原文"）

### 9.1 🔴 `D-G60`：`integration-wave.sh` 的 `3.5 → 3.6` **段序**让身份记录"一出生就是陈旧的"

**判据原文（仓内工具自己说的）**
```bash
python3 build/artifact-src-fp.py --check   # rc=2
```
```
ARTIFACT_SRC_FP proj=PresentationCore      fp=4298d1b991bdfea7 n=1373 peer_fp=4e434fab7468feeb peer_n=8 state=ok
ARTIFACT_SRC_FP proj=WindowsBase           fp=3ba6fbd4e99387e9  n=326 peer_fp=2a2ed993f748365d peer_n=2 state=ok
ARTIFACT_SRC_FP proj=PresentationFramework fp=76cd3743d1b7a56b n=1362 peer_fp=7b7e9645c4e6fd3e peer_n=9 state=stale \
  note=kind=peer；**被引产物变了**（源一个字没动，但 Roslyn 会把被引件字节纳入输入哈希 ⇒ 本工程产物同样会变）：
  build/PresentationCore.Linux/bin/Debug/PresentationCore.dll 043eff4b1d8ecd7d→9465f9dce39e2dfc
```

**加害者 = 段序，不是"没刷新"**（任务书/主控原判「记录文件没刷新 ⇒ 整波重建会收敛」**不成立**）：
- `build/integration-wave.sh:456` `step "3.5/5 生成物身份指纹（PC/WindowsBase/PF 的源身份；债务 #20 同族）"` → `:458` `python3 build/artifact-src-fp.py --write`；
- 紧接着 `build/integration-wave.sh:463` 起才是 `step "3.6/5 app-local 副本刷新（权威件 → 落后的加载源副本）"` → `:467` `bash "$SYNC_APPS" --apply`；
- 而 **3.6 会覆盖 3.5 覆盖面里的一个被引件** —— 它的 peer 清单里就有 `peer=043eff4b1d8ecd7d  build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`（`build/PresentationFramework.Linux/ARTIFACT-SRC-FP.txt:15`）。

**mtime 硬证据（"先写记录、后改被引件"）**
```
2026-09-20 00:13:46  build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt      ← 3.5 写的记录
2026-09-20 00:13:46  build/PresentationFramework.Linux/ARTIFACT-SRC-FP.txt
2026-09-20 00:13:46  build/WindowsBase.Linux/ARTIFACT-SRC-FP.txt
2026-09-20 00:12:56  build/PresentationCore.Linux/bin/Release/PresentationCore.dll   （Release 权威，3 段建的）
2026-09-20 00:13:55  build/PresentationCore.Linux/bin/Debug/PresentationCore.dll     ← 晚 9 秒，被 3.6 覆盖
```
且 3.6 的日志**逐字**承认了它动了 Reach 的副本（同族动作）：
```
    REFRESH         samples/WpfFeatureProbe/bin/Release/net10.0/ReachFramework.dll f4836ae36cbe80e1 → be2d69ba02c76ef9  （权威 be2d69ba02c76ef9；副本曾早 4769 秒）
```

**归因唯一性（正控）**：我把三份记录里的**全部 20 条 peer**逐条与现场重算比对：
```
PC  : 8/8 OK
WB  : 2/2 OK
PF  : 8/9 OK，**唯一 CHANGED = build/PresentationCore.Linux/bin/Debug/PresentationCore.dll  rec=043eff4b1d8ecd7d live=9465f9dce39e2dfc**
      （其余 OK：CycleStub 09484aaa / Reach 33b372da / System.Printing 5ccc7622 / SWE 4499439d / System.Xaml 856b84d2 / UIAutomationProvider 76c3e977 / UIAutomationTypes 2654da31 / WindowsBase 19de048e）
```
⇒ `rc=2` **完全**由那一格造成；**不是**别的东西（例如 `ReachFramework` 或 `pwsh`）在漂。**修法（我不改，判定输入＋不在我写域）**：把 `:456-461` 的 3.5 段**挪到 3.6 之后**，或在 3.6 之后**重跑一次 `--write`**。
**射程（如实）**：`grep -rn 'ARTIFACT_SRC_FP\|artifact-src-fp' verify-all.sh build/MilBridge/tools/*.sh` = **0 命中** ⇒ 今天**没有任何已接线的读者**（它的 rc=2 不进任何判定）；它仍值得修，因为**下一次有人用它做"源变了没重建"的判据时，第一眼必然是假的 stale**。

### 9.2 `D-G59`：`verify-all.sh` 会劫持别人遗留的**低号**临时 X 显示 —— 加害者定位 + 两极化正控

**代码（现场行号）**
```
verify-all.sh:365    chosen=""
verify-all.sh:366    if DISPLAY=:$DISPLAY_NUM xdpyinfo > /dev/null 2>&1; then
verify-all.sh:367      chosen=":$DISPLAY_NUM"
verify-all.sh:370      for d in $(pgrep -a Xvfb 2>/dev/null | grep -oE ' :[0-9]+' | tr -d ' :' | sort -u); do
verify-all.sh:371        if DISPLAY=:$d xdpyinfo > /dev/null 2>&1; then chosen=":$d"; break; fi
```
`:370` 的 **`sort -u` 是字符串序** ⇒ **`66` < `97`** ⇒ 任何低号临时显示都**优先**于常驻 `:97`；选定之后**整趟不再复核**（`:403` 的 `X_STATE` 只在 `[0]` 之后那一次算）。

**加害者（我定位到的）＝ 车道 W48D 的私有 Xvfb**
```
$HOME/w48d/run.sh:12    D="$HOME/w48d-app"; OUT="${W48D_OUT:-$HOME/w48d-run}"; DISP="${W48D_DISPLAY:-:64}"
$HOME/w48d/run.sh:28    Xvfb "$DISP" -screen 0 1400x1050x24 > "$OUT/xvfb.log" 2>&1 & XPID=$!
$HOME/w48d-run/NODIAG-BEFORE/xvfb.log   mtime 2026-09-19 23:48:21
$HOME/w48d-run/NODIAG-AFTER/xvfb.log    mtime 2026-09-19 23:48:53
$HOME/w48d-run/AFTER/app.log:808        XIO:  fatal IO error 2 (No such file or directory) on X server ":66"
```
时间线：W48D 在 `23:48:21` 起了一个私有 Xvfb、`23:48:53` 另起一个（W48D 报告 §装置自述「私有 Xvfb（`:64`/`:66`）」），而 w49a 那趟 `verify-all` 起于 **`23:48:55`**（`$HOME/w49a/post-freeze-2.log:4`）；它的 `[0]` 段原文：
```
[0] Xvfb（目标 :99）
  ✅ 复用已运行的 Xvfb（实测 display :66，注意不是 :99）
  DISPLAY=:66（已用 xdpyinfo 验证可连）
  X_STATE=available（判据：xdpyinfo 对 DISPLAY=:66 成功 ⇒ available）
```
W48D 收工后按 PID 收掉自己的 Xvfb（`$HOME/w48d-run/NODIAG-AFTER` 目录 mtime `23:49:27`）⇒ 剩下 20 分钟的 `XOpenDisplay` 全 NULL。
**事后与现场**：`$HOME/w48d-run/AFTER/app.log:808` 那条 `fatal IO error … on X server ":66"` 是同一颗显示的死亡留痕；这个 socket **今天已经不在** `/tmp/.X11-unix/`（只剩 `X0`/`X1`/`X10`/`X97`）。

**两极化正控**：见 §7.3 —— 同一棵树，`DISPLAY=:66`（已死）⇒ `ManagedLayer.Tests ❌ 49/26`、`SKIP_GUARD=FAIL`、X 用例跳过 **21** 例；`DISPLAY=:97`（活着）⇒ `ManagedLayer.Tests ✅ 76/0`、`SKIP_GUARD=PASS`、X 用例跳过 **0** 例、合计回到 **871/2**。
⇒ **w49a 那趟的 `ManagedLayer.Tests SKIP-GUARD` 是 `D-G59` 的假红，不是 `#47`/`#48` 的产品回归。**
**给下一趟的最小护栏（我不改，不在我写域）**：`[0]` 选中后**在结论区回显显示号并复核一次 `xdpyinfo`**（或优先选**不落在任何车道私有目录**的那个显示 / 优先选 `etime` 最长的 Xvfb）。本趟我已按主控要求**起跑前核过只留 `:97`**（§7.1）**并把 `[0]` 的显示号写进本报告**。

### 9.3 链**中途**有别人改了判据件 —— 我核过它**没有**污染我的读数（逐条给机器证据）

我开工于 `00:10:20`。链期间（**不是我写的**）有两件被判据面点名/相关的文件发生位移：

| 件 | mtime | 是否我写 | 在 `fp_inputs()` 覆盖面里？ | 对我的读数的影响 |
|---|---|---|---|---|
| `build/MilBridge/tools/defect-registry-declared.tsv`（105 行，现 sha16 `1fb06485459e90d6`） | `00:16` | **否** | **不在** | 无 |
| `verify-all.sh`（`sha16 5ee3ad984ee7412d`，79,389 B） | `00:19:02` | **否** | **不在**（是**被审对象**） | 无 |
| `build/MilBridge/W49A-report.md` | 链中途 | **否** | 不在 | 无 |

**"不是我写"的证据**：`build/MilBridge/tools/defect-registry-check.sh:403` `if [ "${1:-}" = '--emit' ]; then emit_decl; exit 0; fi` ⇒ **只有 `--emit` 写盘**；我全程跑它时**从不带 `--emit`**（P7 那次也是裸跑）。
**"没有污染"的证据（两条）**：
1. `inputs_fp()` 的点名名单我**逐条读过**（`build/close-wave.sh:179-189`）：`build/MilBridge/tools/tline-gate.sh`、`build/MilBridge/known-red.json`、`verify-all-step-check.sh`、`fp-inputs-hygiene-check.sh`、`column-floor-check.sh`、`hidden-only-step.sh`、`shell-quote-trap-check.sh`、`product-entry-step.sh`、`defect-registry-check.sh`、`baseline-sha-check.sh`、`arm-log-sha-check.sh`、`build-hygiene-import-check.sh`、`pipefail-sigpipe-check.sh`、`frame-presence-check.sh`、`samples/ThirdPartyMini/run-thirdparty-mini.sh` —— **没有任何 `*.tsv`，也没有 `verify-all.sh`** ⇒ 那两件位移**动不了 `inputs_fp`**。这坐实了 §1-P5 里 `b983d9be… → cad0801c…` 的**唯一来源就是重钉 `known-red.json`**（它在名单里）。
2. `verify-all.sh` 的改动发生在 `00:19:02`，**早于**我起跑 `00:31:27`，且我**跑前/跑后各算一次 sha16 并要求逐位相同**（`5ee3ad984ee7412d` == `5ee3ad984ee7412d`）⇒ 我的 `verify-all` 用的是**同一个**版本、**没有** `#47` 那种"边读边改"。

### 9.4 顺带证实：`#47` 冻后第二趟日志自相矛盾的原因（主控自陈已认）
`$HOME/w49a/post-freeze-2.log` 里 `[6] 帧列` **出现两次**，中间夹着
```
verify-all.sh: 行 517: 帧红=0: 未找到命令
verify-all.sh: 行 517: 判定行=421: 未找到命令
verify-all.sh: 行 517: /: 是一个目录
```
⇒ bash 在 `:517` 解析到一半时文件被**替换**（主控当时正在改 `verify-all.sh` 到 `gen=#48`）⇒ **那趟读数作废**。本趟我把 `sha256sum verify-all.sh` **跑前/跑后各算一次并要求逐位相同**（`5ee3ad984ee7412d` == `5ee3ad984ee7412d`）⇒ 结构上排掉了这种污染。

---

## 10 `NOINFO`（没取到的，逐条如实标）

1. **`windowsbase`/`pf` 在"自己源变了"时是否字节可复现**：本波我只观测到 **peer 字节链**机制（§9.1），**没有**观测到"自身源变 ⇒ 产物确定"这一半 —— `未取到`。
2. **`publish` 内嵌的 app-local 检查 vs 独立跑的同一检查，为什么摘要不同**（`DIVERGENT=1/DECL-GAP-DIFF=0` vs `DIVERGENT=3/DECL-GAP-DIFF=2`）：我**只逐字记了两条读数**，**没有**去读 `publish-milbridge.sh` 里那次调用的扫描根/参数差异 ⇒ `未取到`（已按"两次读数 + 时间戳"如实并列在 §2）。
3. **`ARTIFACT_SRC_FP` 是否有已接线的读者**：我只做了 `grep -rn 'ARTIFACT_SRC_FP\|artifact-src-fp' verify-all.sh build/MilBridge/tools/*.sh`（0 命中）⇒ **"今天没读者"这句的射程只到这两个搜索面**，全仓普查 `未取到`。
4. **`retake-arms` 里 `tline` 与 `tab-zero` 的 `rc=1` 具体是哪几条在册红**：我只记了脚本自印的 per-arm rc，**没有**逐条读这两支的判定明细 ⇒ `未取到`（与 `#47`/`#48` 同形，非本波位移）。
5. **闸门 `colors 3960→4112` 的成因**：只记读数，**没有**归因（未比截图/未做像素对拍）⇒ `未取到`。
6. **本波的"产品级"BAML/`NameScope` 读数**（`[NS] ATTRCOUNT DependencyObject ≥ 2`、`FindName(ControlMain)` 非 null、点「工具」页第 2 项不崩）：那是 **W48D 的取证面**，我**没有重跑 hc 应用**（任务书只要我跑"整波链"）⇒ `NOINFO`，本报告只背书**静态形状**（§1.1：属性紧贴类声明）与**生成件 sha 对上**。
7. **`GENS['#48']` 的 `bs_fp`/`infp`/`allow_changed` 我按只读核过 `allow_changed` 与实测吻合**，但**冻结器本身我没跑也没读全**（纪律：不许跑 `w27-freeze.py`）⇒ 冻结侧的一切由主控裁定。

---

## 11 纪律与自伤记账

- **零 `pkill -f`**、零 `pgrep -x dotnet` 取 PID；自起的东西为 **0**（我没起 Xvfb、没起 app）；收尾 `Xvfb` 只剩常驻 `:97`，与开工前**同一 PID `68922`**。
- **同一时刻只有一个重活**：步 1→6 严格串行；起跑前等满 16 min 43 s 等到静默（§1-P0）。
- **动件前备份**（`cp -p`，逐件核 sha16）：`$HOME/w50a-backup/` 下有 `known-red.json.pre-repin`（`00a75a87ec5ed0d6`）、五支 `*.log.pre-retake`、两个 applier `.pre50a`、两个生成件 `.pre50a`。
- **我只在仓内新增了 1 个文件**：`build/MilBridge/W50A-report.md`（本文件）。其余写入全部落在 `$HOME/w50a/**`（日志）与设计内的 `known-red.json`（步 4）＋ `build/MilBridge/arm-logs/*.log`（步 3 的 `ln -f`，纪律 34/59 的合规动作）。
- **`verify-all.sh` 我一个字节没改**（跑前/跑后 sha16 相同，§7）。
- 本报告**没有**把"仪器口径读数"读成"产品结论"：九位/生成件/臂日志是**文件 sha 事实**；`D-G56` 的**行为面**（不 abort）我**没有**重验（§10-6）。

---

## 12 交付路径与 sha16（冻结要用）

| 件 | 绝对路径 | 大小 | sha16 |
|---|---|---|---|
| 冻前 `verify-all` 日志 | **`/home/links-dev/w50a/06-verify-all-pre.log`** | 8,664 B | **`944d341a8d7460ef`** |
| 应用门禁行文件（6 行） | **`/home/links-dev/w50a/gate-rows.txt`** | 9,298 B | **`439a9c038c476adc`** |
| 本报告 | `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/W50A-report.md` | — | **见交付消息**（本仓惯例：报告**不自指 sha** —— 把"本文件的 sha"写进本文件会产生不动点，改一次就自相矛盾；权威值由交付消息给出） |
| 步 1 日志 | `/home/links-dev/w50a/01-publish.log` | | |
| 步 2 日志 | `/home/links-dev/w50a/02-integration-wave.log` | | |
| 步 3 日志 | `/home/links-dev/w50a/03-retake-arms.log` | | |
| 步 4 日志（写 / 只读核对） | `/home/links-dev/w50a/04-repin.log` ／ `04-repin-check.log` | | |
| 步 5 两趟日志 | `/home/links-dev/w50a/05-gate-e.log` ／ `05-gate-f.log` | | |
| 五臂工作副本 | `/home/links-dev/w50a/arms/*.log` | | |
| 重钉前备份 | `/home/links-dev/w50a-backup/known-red.json.pre-repin` | 61,554 B | `00a75a87ec5ed0d6` |

**run 元数据**：`lane=W50A`｜日期时间 `2026-09-19T23:53 – 2026-09-20T00:49 +0800`｜`kernel=6.8.0-138-generic`｜`nproc=3`｜`host=linksdev-VirtualBox`｜步 1/2/3/5/6 起跑 `loadavg` 与 `mem_available` 见各章 🡒（最小 `MemAvailable` = **1597 MB**，出现在步 2 收尾的构建峰值；闸门那两条硬要求 `MemAvailable ≥ 1500` **未被击穿**）。

---

**本报告不自指 sha16**（自指 = 不动点，写一次就自相矛盾）⇒ 权威值见交付消息；量法：
`sha256sum /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/W50A-report.md | cut -c1-16`
