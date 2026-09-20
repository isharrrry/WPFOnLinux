# 波 `#46` 收尾手册（`WAVE46-CLOSEOUT-RUNBOOK`）—— 照着敲就能走完

> **本文件的性质**：**只读准备**的产物，不是判据、不是登记处。它把收尾链上每一颗牙、每一个常量、
> 每一条命令从**仓内实际文件里读出来**（凡有行号的一律现场核过），目的是让"照着敲"就能走完
> 「整波重建 → 重取臂 → 重钉 → 闸门 ×2 → `verify-all` → 重冻 `#46` → 冻后 ×2」。
>
> **采集时间**：`2026-09-19T20:07:51+08:00`（本文件里所有"现场读数"都是这一刻实测的；
> **引用前请重算** —— 本仓纪律 49：数一律现场算）。
>
> **不写什么**：本文件**不**替你登记缺陷、**不**替代预登记 `docs/WAVE46-PREREGISTRATION.md`、
> **不**声明任何判据。凡"应该写死的判据"都在预登记里；本文件只讲**怎么把它们跑出来**。

---

## 0 全链速查（30 秒版）

```
① 前置检查（§1）   → ⑧ 必须全绿；DEFREG 现在是 FAIL（见 §1-P7）
② 整波重建（§2）   WAVE_OWNER=主控 bash build/integration-wave.sh          rc=0
                    ＋ native shim（源比权威新才建）＋ 桥（源指纹不一致才发）
③ 重取五臂（§3）   ARMS_OUT=$HOME/w46-arms bash build/MilBridge/tools/retake-arms-w23.sh
④ 重钉（§4）       python3 build/MilBridge/tools/repin-generation.py --why '…'  → --check rc=0
⑤ 闸门 ×2（§5.4）  WPTD_RUN_DIR=… WPTD_BASELINE_OUT=$HOME/w46-gate-rows.txt bash …/run-wpftextdemo.sh 60 --tier both
⑥ verify-all（§5）  bash verify-all.sh   （读 ~23 min；**预期 1 项声明类红 = COLUMN-FLOOR**）
⑦ 重冻 #46（§6）   python3 $HOME/w21-verify/w27-freeze.py <va 日志> <门禁行文件> '#46'
⑧ 冻后 ×2（§7）    bash verify-all.sh  ×2（两趟 25/25 全绿、`rc=0`、四项自报逐字相同）
```

**时长预算（实测，不是估计）**：整波重建 ≈ **13 min**（`$HOME/w44-wave.log` 15:05→15:18）｜
重取五臂 ≈ **10 min**｜`verify-all` 一趟 **≈ 23 min**（`$HOME/w44-close.log`：`real 22m48.547s`）｜
闸门一趟 ≈ 4 min。⇒ **全链 ≈ 90 min**（含冻后两趟）。

---

## 0.1 🔴 采集时的**在飞状态**（读这份手册之前必读）

本文件是**只读准备**的产物，采集期间**另一条车道正在落 `D-G54` 的修法** ⇒ 下面的"现场读数"
是**某一刻的快照**，**引用前一律重算**。实测到的位移（`20:07` → `20:09`）：

| 项 | `20:07` | `20:09`（重读） | 含义 |
|---|---|---|---|
| `inputs_fp` | `3a4b6cf1…` | **`0551ce17…`** | 覆盖面里的 `src/WpfGfx.Linux/**/*.cs` 被改了 |
| `BRIDGE_SRC_FP`（现树） | `794ea22406cc88ab` | **`85e9afa176d60cd1`**（`BRIDGE_SRC_N=78`） | 桥的源变了 |
| 桥**发布记录**（`bridge-src-fp.txt`） | `794ea22406cc88ab` | **仍是 `794ea22406cc88ab`** | ⚠️ **两侧不一致** |
| `bridge` 位 | `496951adff86a557` | **`58a7abfeda93e662`** | 已变（`#44` 冻结值是 `496951adff86a557`） |

被改的四个源件（`mtime` 20:07:31 – 20:09:05，全部在 `src/WpfGfx.Linux/**`）：
```
src/WpfGfx.Linux/Windowing/X11Window.cs
src/WpfGfx.Linux/Interop/MilNative.cs
src/WpfGfx.Linux/Interop/MilPresentation.cs
src/WpfGfx.Linux/Resources/MilChannel.cs
```

**⇒ 三条结论（直接改掉下面的待填项）**

1. **`D-G54` 的修法确实落在 `src/WpfGfx.Linux/**`（`bridge` 位）** ⇒ `GENS['#46']['allow_changed']`
   **必须**含 **`'bridge'`**（预测集合由 `{'pc','pf','win32shim'}` 改成
   `{'bridge','pc','pf','win32shim'}`，并在记录里给出"为什么 bridge 动"的读数）；
   `GENS['#46']['bs_fp']` 必须填**冻结当时现算**的值（现树 `85e9afa176d60cd1` 只是 20:09 的值）。
2. **那一趟必须重发桥**（`bash build/publish-milbridge.sh`）。否则闸门会给
   `WPTD_BRIDGE_SRC_STALE=yes`（"本趟读数作废"）而**仍然 `WPTD_GATE=PASS`**（见 §9-R6）。
3. **现树此刻就会让 `close-wave.sh` 的桥身份自检 `exit 5`** —— 这是"必须重发桥"的**机器证据**，
   也是最好的前置检查：
   ```bash
   FP_NOW=$(bash build/bridge-src-fp.sh | sed -n 's/.*BRIDGE_SRC_FP=\([0-9a-f]\{16\}\).*/\1/p')
   FP_REC=$(sed -n 's/.*BRIDGE_SRC_FP=\([0-9a-f]\{16\}\).*/\1/p' \
     build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/bridge-src-fp.txt | head -1)
   echo "现树=$FP_NOW 记录=${FP_REC:-无}"   # 期望（收尾那一刻）：两侧相等
   ```
   （口径逐字来自 `build/close-wave.sh:301-304`；不等 ⇒ 那里 `exit 5`、报"事故 D 形态"。）

⚠️ **`pc` 侧的 `D-G54` 插桩也已经在树里**：`src/WpfGfx.Linux.Native/tools/patch-presentationcore-hwndtarget-trace.py`
（`20:03`，10,261 B）＋ `pc = b1d3d5f33618a3d7`（≠ `#44` 冻结值 `45e7e0a46f5912c0`）
⇒ §1-P5 的 `inputs_fp` 位移**至少**有这一个可归因来源。

---

## 1 前置检查（每条：命令 + 期望输出 + 不符时怎么办）

> 所有命令都在 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux` 下、且**先**：
> ```bash
> cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
> export PATH="$HOME/.dotnet:$PATH"
> ```

### P0 环境

```bash
nproc                                      # 期望：3
awk '/MemAvailable/{print int($2/1024)}' /proc/meminfo   # 期望：> 1200（MB）
pgrep -c -x dotnet                         # 期望：0（**别用 pgrep -f，会自匹配**）
xdpyinfo -display :97 >/dev/null 2>&1 && echo UP || echo DOWN   # 期望：UP（重取臂 5/5 需要它）
```
`2026-09-19T20:07` 实测：`nproc=3`、`MemAvailable=2336 MB`、`dotnet=0`、`:97 = UP`。
`:97` **DOWN 时**：`run-wpftextdemo.sh:332-424` 会自己起一个 Xvfb（`WPTD_DISPLAY`，默认 `:97`）；
但 `retake-arms-w23.sh` 第 5 步写死 `DISPLAY=:97`（`:95` 那一行），**DOWN 就该停**。

### P1 配置唯一声明

```bash
bash build/selfbuilt-config.sh            # 期望：Release
bash build/selfbuilt-config.sh --check    # 期望：SELFCONFIG_CHECK=PASS（两颗牙）
bash build/selfbuilt-config.sh --debt-check  # 期望：SELFCONFIG_DEBT_CHECK=PASS live=N max=167
```
**为什么必须先看这一条**：九位里有六位的**路径**跟着它走（`w27-freeze.py:323-341`）。
切了配置而没收尾链跟随 ⇒ 冻结器会去读**另一个配置的陈旧件**并当权威（`#40` 实测事故）。
`2026-09-19` 实测：`Release`。

### P2 两颗牙（基线）

```bash
bash build/MilBridge/tools/baseline-sha-check.sh
# 期望：
#   BASELINESHA=PASS live=ff3990dafa582831 decl=ff3990dafa582831
#   BASELINEGEN=PASS decl_gen=#44 file_newest_gen=#44
#   BASELINE_BYTES=500687
#   BASELINEDUP=PASS n=0
```
`BASELINEGEN` 是重冻的前提：`w27-freeze.py:243-247` 断言「树上当前冻结世代 == `GENS['#46']['prev']`」。
**`decl_gen` 现在必须是 `#44`**；若不是 ⇒ 停下来核（说明有人已经冻过或改了 `docs/CURRENT-STATE.md:9`）。
`BASELINEDUP` 是「整份 sha 只许有一处机器声明」（`ACCEPTANCE-BASELINE.md` 别处不许重述值）。

### P3 其余三颗牙

```bash
bash build/MilBridge/tools/arm-log-sha-check.sh   # 期望：ARMLOG_SHA=PASS … required=5 declared=5 pass=5 fail=0 noinfo=0
bash build/MilBridge/tools/column-floor-check.sh | grep '^COLUMN_FLOOR='
# 期望：COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS \
#        reg=7deadeac97659e46 base=ff3990dafa582831 corpus=0cebc0afd5142fbf
bash build/MilBridge/tools/defect-registry-check.sh | tail -3   # 见 P7（**现在是 FAIL**）
```
`ARM-LOG-SHA` / `COLUMN-FLOOR` 在**波内**会因为「臂已重钉、基线块还没换」而红 —— 那是
`D-G44` 的**声明类两极**（`w27-freeze.py:237-291`），**冻前红、冻后必须绿**；不要提前把它们压绿。

### P4 当前九位指纹（照抄 `close-wave.sh` 的 `fp_inputs()` 口径，**别自己发明**）

```bash
CFG=$(bash build/selfbuilt-config.sh)
for p in \
  build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so \
  build/PresentationCore.Linux/bin/$CFG/PresentationCore.dll \
  build/PresentationFramework.Linux/bin/$CFG/PresentationFramework.dll \
  build/WindowsBase.Linux/bin/$CFG/WindowsBase.dll \
  build/DirectWrite.Linux/Provider/bin/$CFG/DirectWrite.Linux.Provider.dll \
  src/WpfGfx.Linux.Native/bin/libwpfwin32.so \
  build/DirectWrite.Linux/wic-shim/libwpfwic.so \
  build/shims/PresentationCore.HbTextLine.cs \
  build/DirectWriteForwarder.Linux/bin/$CFG/DirectWriteForwarder.dll ; do
  printf '%s %s %s\n' "$(sha256sum "$p" | cut -c1-16)" "$(stat -c%s "$p")" "$p"
done
```
路径口径 = `$HOME/w21-verify/w27-freeze.py:333-341` 的 `NINE`（**逐字相同**）。
`2026-09-19T20:07` 实测：

| 位 | 现树 | vs `#44` 冻结值 | 字节 |
|---|---|---|---|
| `bridge` | `496951adff86a557` | 未变 | 4,991,984 |
| `pc` | `b1d3d5f33618a3d7` | **变了**（`45e7e0a46f5912c0`） | 3,601,408 |
| `pf` | `a93097f7a918597f` | 未变 | 6,119,424 |
| `windowsbase` | `84a2826c471e60ea` | 未变 | 1,111,552 |
| `provider` | `1f9511a7ef395bfe` | 未变 | 103,936 |
| `win32shim` | `e700c383ec1ecdc8` | **变了**（`11f81eb9dfc60a12`） | 299,040 |
| `wic_shim` | `56278c14b4ecd672` | 未变 | 70,728 |
| `hbtextline` | `e89fed55fd8e32bc` | 未变 | 290,825 |
| `dwf` | `de2d555105b7d04b` | 未变 | 39,936 |

⇒ 现在**只有 `pc` 与 `win32shim` 两位**离开 `#44` 冻结值。
⚠️ **本表是 `20:07` 的快照**：`20:09` 重读时 `bridge` 已变成 `58a7abfeda93e662`（`D-G54` 修法落桥侧）
—— **见 §0.1，引用前重算**。

### P5 `inputs_fp` 与 `BRIDGE_SRC_FP`（**照抄真函数，不许复制函数体**）

```bash
bash -c 'source <(sed -n "/^fp_inputs()/,/^}/p" build/close-wave.sh); fp_inputs'
bash build/bridge-src-fp.sh          # 期望：BRIDGE_SRC_FP=<16hex> BRIDGE_SRC_N=<n>
```
`2026-09-19T20:07` 实测：
```
inputs_fp      = 3a4b6cf1796b0c825767dc310e5370ffe92fa85eb39417dee21cbe474e51359c
BRIDGE_SRC_FP  = 794ea22406cc88ab   BRIDGE_SRC_N=78
```
`#44` 冻结块（`ACCEPTANCE-BASELINE.md:25`）记的是
`inputs_fp = 493551dbffb1a937297bcb222389690c6df9bafa0c5c468a19e31a07b32c2f5f`
⇒ **已经变了**。⚠️ **本表是 `20:07` 的快照**：`20:09` 重读 `inputs_fp = 0551ce17…`、
`BRIDGE_SRC_FP(现树) = 85e9afa176d60cd1`（见 §0.1）。原因**可归因**：`src/WpfGfx.Linux.Native/tools/patch-presentationcore-hwndtarget-trace.py`
（`2026-09-19 20:03`，10,261 B）是**本波新增的应用器**，而 `fp_inputs()` 的覆盖面里有
`find src/WpfGfx.Linux.Native/tools … -name 'patch-*.py'`（`build/close-wave.sh:104-107`）
⇒ **设计性变更**（"改判定输入必须看得见"是设计，不是缺陷）。重钉 `known-red.json` 会**再变一次**
（`known-red.json` 是覆盖面的点名成员，`build/close-wave.sh:179-180`）。

### P6 native shim / 桥 的**新鲜度**（**本波最容易"看起来绿"的两格**）

```bash
# native：源码是否比权威件新（照抄 close-wave.sh:255-256 的口径）
NEWEST=$(find src/WpfGfx.Linux.Native \( -name '*.c' -o -name '*.h' \) -printf '%T@\n' | sort -rn | head -1 | cut -d. -f1)
AUTH=$(stat -c %Y src/WpfGfx.Linux.Native/bin/libwpfwin32.so)
echo "newest_src=$NEWEST auth=$AUTH  ⇒ $([ "$NEWEST" -gt "$AUTH" ] && echo '需要重建 native' || echo '可跳过重建')"
# native：全仓 5 份副本是否同 sha（权威 1 份 + 副本 4 份）
find . -name 'libwpfwin32.so' -not -path './upstream/*' -not -path '*/.artifacts/*' \
  | while read f; do echo "$(sha256sum "$f"|cut -c1-16) $f"; done
# 桥：现树指纹 vs 发布记录（照抄 close-wave.sh:260-262）
sed -n 's/.*BRIDGE_SRC_FP=\([0-9a-f]\{16\}\).*/\1/p' \
  build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/bridge-src-fp.txt
```
`2026-09-19T20:07` 实测：
```
newest_src=1789818462  auth=1789818464  ⇒ 可跳过重建（**权威件不比源旧**）
e700c383ec1ecdc8  ./src/WpfGfx.Linux.Native/bin/libwpfwin32.so          ← 权威（19:47）
11f81eb9dfc60a12  ./build/MilBridge/tests/CompositeFontProbe/bin/Release/libwpfwin32.so   ← 旧代！（15:10）
11f81eb9dfc60a12  ./build/MilBridge/tests/ContractProbe/bin/Release/libwpfwin32.so        ← 旧代！（15:18）
11f81eb9dfc60a12  ./build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/libwpfwin32.so     ← 旧代！（15:10）
11f81eb9dfc60a12  ./samples/WpfFeatureProbe/bin/Release/net10.0/libwpfwin32.so            ← 旧代！（18:21）
```
🔴 **四份副本全部落后于权威件**（`11f81eb9…` = `#44` 冻结值），而 `#46` 的**产品修复就在这一位**。
- `run.sh:97` / `run.sh:230` 会替 `CompositeFontProbe`/`ContractProbe` 现场 `cp` 权威件
  ⇒ 这两份在重取臂时会自动跟上；
- **`SystemFontsProbe/bin/Debug` 与 `samples/WpfFeatureProbe/bin/Release/net10.0` 没有任何机制跟上**
  ⇒ 谁在它们上面取读数，谁测的就是**旧一代 shim**（这正是 `#44` §6 ④ 记的那类"仪器自伤"）。
- ⇒ **收尾必须做一次全副本同步**（`close-wave.sh:274-287` 的 [2/6] 就是干这个的：`cp -f` 全部副本
  并**逐份断言 sha == 权威**）；§2 给了两条路。

桥的两侧**在 `20:07` 那一刻**（现树 `794ea22406cc88ab` vs 发布记录 `794ea22406cc88ab`）是一致的。
🔴 **但 `20:09` 重读已经不一致了**：现树 `85e9afa176d60cd1` ≠ 发布记录 `794ea22406cc88ab`
（§0.1 实测）—— 因为 `D-G54` 的修法**确实落到了 `src/WpfGfx.Linux/**`**（`bridge` 位，
部署件 `496951adff86a557 → 58a7abfeda93e662`）。
⇒ 那一趟**必须**用 `bash build/publish-milbridge.sh` 重发；否则闸门会打
`WPTD_BRIDGE_SRC_STALE=yes`（**advisory，不单判红** —— 见 §9-R6），而 `close-wave.sh:301-304`
的桥身份自检会直接 `exit 5`（这正是它该做的）。

### P7 🔴 `DEFECT-REGISTRY` 现在是 **FAIL**（收尾前必须处理）

```bash
bash build/MilBridge/tools/defect-registry-check.sh | tail -4
```
`2026-09-19T20:07` 实测：
```
DEFREG_DECL=n=89 route_ids=90 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=df62bcf5563e686b CS=765ec7cd73fefca9 HO=7e9658ae6d5a8195 AB=ff3990dafa582831
DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN
DEFREG=FAIL reason=undeclared-id-in-route
  D-G54 first-seen=KD:1808 route=…/samples/WpfFeatureProbe/KNOWN-DEFECTS.md
```
`D-G54` 已写进 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（route 键 `KD`，`2026-09-19 19:59`），
但**没有**进声明表 ⇒ 判据 ④ 命中（`defect-registry-check.sh:215-222`）。

**处理**（**这是主控写域**，`build/MilBridge/tools/*.tsv`）：
```bash
bash build/MilBridge/tools/defect-registry-check.sh --emit \
  > build/MilBridge/tools/defect-registry-declared.tsv      # 语义见 :403 / :122-123
bash build/MilBridge/tools/defect-registry-check.sh | tail -1   # 期望：DEFREG=PASS declared=N route_ids=N
```
**为什么必须在收尾链之前做**：`DEFECT-REGISTRY` 在 `w27-freeze.py` 的
`green` 名单里，而它**不在** `DECLARATION_CHECKS`（`:237`）⇒ **冻前必须绿**，
否则 `w27-freeze.py:283` 的 `assert _ok` 当场 `AssertionError`。
⚠️ `DEFREG_DECLDRIFT` 只是**诊断行**，不参与 rc（判定顺序见 `:238-245`）—— 它变 1 不是红。

### P8 应用器审计（在飞的新应用器**不在覆盖面内**）

```bash
python3 build/MilBridge/tools/applier-audit.py | tail -1
# 期望：APPLIER_AUDIT_SUMMARY appliers=24 ok=83 miss=0 red=0 rc=0
```
`2026-09-19T20:07` 实测就是这一行。⚠️ **24 个里没有 `patch-presentationcore-hwndtarget-trace`**
（见 §9-R2）。

### P9 哨兵与并发

```bash
[ -e /tmp/bridge-republish.lock ] && echo '有重发锁 ⇒ 停' || echo '无重发锁'
pgrep -af -- 'run-wpftextdemo|run-wpfprobe|WpfTextDemo|WpfFeatureProbe' | grep -v pgrep || echo '无应用/探针在跑'
```
`close-wave.sh:214-238` 用的就是这条正则与"剔掉本调用者祖先链"的做法
（**别用 `pgrep -f` 直接下结论** —— `D-G34` 的自匹配洞，`close-wave.sh:196-213`）。

---

## 2 整波重建

### 2.1 必需环境变量（去源码核实的**完整**清单）

`build/integration-wave.sh` **只认一个**环境变量：**`WAVE_OWNER`**（等价命令行 `--owner=<名字>`）。

| 位置 | 原文 |
|---|---|
| `build/integration-wave.sh:36-38` | `if [ -z "${WAVE_OWNER:-}" ]; then for a in "$@"; do case "$a" in --owner=*) WAVE_OWNER="${a#--owner=}" ;; esac; done; fi` |
| `build/integration-wave.sh:57-72` | 未设 ⇒ 打印两种正确用法并 **`exit 9`** |
| `build/close-wave.sh:58` | `export WAVE_OWNER="${WAVE_OWNER:-close-wave:$(id -un)}"`（**走 `close-wave` 就自动认领**） |

其余"输入"全部来自仓内：`build/selfbuilt-config.sh`（`:17`，给出 `SELFBUILT_CONFIG`）、
`build/SelfBuiltConfig.props`、`build/wave-audit.log`（`:39`，每趟追加一行审计）。
`ARMS_OUT`/`CLOSE_WAVE_OUT`/`CLOSE_WAVE_FLAG` 是**别的脚本**的量，不是 `integration-wave.sh` 的。

### 2.2 两条路（**推荐 A**）

**路 A（推荐）：`close-wave.sh` 的"跳 verify-all"变体** —— 它一次把 [2/6] native 重建＋副本同步、
[3/6] 桥重发、[4/6] 身份四件套都做了：

```bash
bash build/close-wave.sh --native --bridge --skip-verify-all \
  > "$HOME/w46-close-pre.log" 2>&1 ; echo "rc=$?"
```
- `--native` **强制**重建 native shim 并同步**全部**副本（`close-wave.sh:274-287`）；
- `--bridge` **强制**重发桥（`:293-297`）；
- `--skip-verify-all` 因为**冻前的 `verify-all` 必然有声明类红**（见下）。
- ⚠️ 它的 [5/6] 要是没跳过，会因 `verify-all` 的 `rc=1` 直接 `exit`（`close-wave.sh:62-68`）。

**路 B（`#44` 的原路，成本最低）：直调 `integration-wave.sh` ＋ 手工补 native/桥**：

```bash
WAVE_OWNER=主控 bash build/integration-wave.sh > "$HOME/w46-wave.log" 2>&1 ; echo "WAVE_RC=$?"
# 若 P6 说"需要重建 native"：bash src/WpfGfx.Linux.Native/build-shim.sh --all
# 并**手工**同步全部副本（照 close-wave.sh:277-286 的循环），逐份断言 sha == 权威。
# 若 P6 说桥指纹不一致：bash build/publish-milbridge.sh
```
`#44` 用的就是这条（`build/wave-audit.log:446-447` 逐字留着那次调用），随后
`ARMS_OUT=$HOME/w44-arms bash build/MilBridge/tools/retake-arms-w23.sh`。
⚠️ **路 B 的漏点**：`integration-wave.sh` **不重建 native shim、不重发桥**
（第 4 步的 `bin/Debug` 也只是自检，见 §9-R1）⇒ 忘了手工补 = 后面整条链拿旧件读数。

### 2.3 rc≠0 时怎么读日志

`integration-wave.sh` 的退出码语义：

| rc | 含义 | 出处 |
|---|---|---|
| `9` | **没有责任人**（不是构建失败） | `:71` |
| `1` | 「失败步骤 N ≠ 0」；**应用器审计 RED** 也直接 `exit 1` | `:521`；`:379` |
| `2` | `cd` 失败（正常不会） | `:18` 一带 |

读法：
```bash
grep -nE '❌|⚠ |失败步骤|APPLIER_AUDIT_SUMMARY|输入稳定性|波前指纹|波后指纹' "$HOME/w46-wave.log" | head -40
tail -3 "$HOME/w46-wave.log"       # 期望：=== 集成波结束：失败步骤 0 ===
```
**必看两行**：
- `APPLIER_AUDIT_SUMMARY appliers=N ok=M miss=0 red=0 rc=0`（`:373` 那一步；miss≠0 ⇒ 先修接线再重建）；
- 第 5 步 `波前指纹 == 波后指纹`（`:511-520`）—— 不等 ⇒ 说明**波期间有人改了 `src/**` 或应用器**，
  本次产物与"波后树"对不上，**必须重跑本波**（不是"下次注意"）。

---

## 3 重取臂

**脚本**：`build/MilBridge/tools/retake-arms-w23.sh`（`#23` 立、`#31` 加 `ARMS_OUT`）。

| 环境变量 | 必需？ | 语义（源码位置） |
|---|---|---|
| `ARMS_OUT` | **必需（实践上）** | 日志落盘目录；不设 ⇒ 默认 `$HOME/wfp-runs/arms23`（`:16`） |
| `SELFBUILT_CONFIG` | 由脚本自己 `source build/selfbuilt-config.sh` 得到（`:10`） | 它印 `pc` 的 sha 用它（`:69`） |

**纪律 59 的硬要求**：**先换 `OUT` 并归档**，且 `$OUT` 不得与 `build/MilBridge/arm-logs/` 同 inode。
脚本自带守卫（`:37-53`）：任一臂的写入目标与归档源件**同 inode** ⇒ 打点全部冲突支并
**`exit 4`（"一个字节都还没写"）**。

```bash
ARMS_OUT="$HOME/w46-arms" bash build/MilBridge/tools/retake-arms-w23.sh \
  > "$HOME/w46-arms.log" 2>&1 ; echo "ARMS_RC=$?"
tail -20 "$HOME/w46-arms.log"      # 期望：[5] 段 5 行 ln -f … (links=2)，[6] 段 5 行 sha16
```
`2026-09-19` 实测 `:97 = UP` ⇒ 第 5 步 `textlineproto` 不会缺 X 假红。

**产出落在哪 + 怎么核对**：
1. 工作副本：`$ARMS_OUT/{tline,tab-zero,tab-anchor,tab-rtl,textlineproto}.log`；
2. 第 5 步用 **`ln -f`** 硬链接进 `build/MilBridge/arm-logs/`（`:96-103`）
   —— **绝不 `cp`**（顶 mtime ⇒ 架空弱配对判据）、**绝不 `ln -s`**（门禁 `find -type f` 会漏 ⇒ 全臂 NOINFO）；
   空日志时**不覆盖**归档件（保留旧世代读数，好过静默换空）。
3. 核对：
```bash
for f in tline tab-zero tab-anchor tab-rtl textlineproto; do
  printf '%-16s %s links=%s %s\n' "$f" \
    "$(sha256sum build/MilBridge/arm-logs/$f.log | cut -c1-16)" \
    "$(stat -c %h build/MilBridge/arm-logs/$f.log)" \
    "$(stat -c %y build/MilBridge/arm-logs/$f.log | cut -c1-19)"
done
find build/MilBridge/arm-logs -type f -name '*.log' | wc -l   # 期望 ≥ 5（不许是 0）
bash build/MilBridge/tools/arm-log-sha-check.sh | tail -1     # **此时必然 FAIL**（还没重钉）—— 正常
```
4. **本波预测（写死，跑完对账）**：只有 **`tline`** 一支内容会变 —— 它自报权威
   `PresentationCore.dll` 的 sha16（`build/MilBridge/arm-logs/tline.log:6`
   `[applocal] PresentationCore.dll：已与权威一致（<pc16>）`），而 `pc` 变了；
   三支 `tab-*` 只自报 `CoverageProbe/Program.cs` 的 sha（`tab-zero.log:1`，本波没动它）
   ⇒ 应**逐位不变**；`textlineproto` 本波实测不含 `pc` 的 sha ⇒ 预测也不变。
   **任一支与预测不符 ⇒ 记下来再判**（`#44` 的实测正是"只有 `tline` 变"）。

---

## 4 重钉

**脚本**：`build/MilBridge/tools/repin-generation.py`（`#40` 波立，`#44` 用过）。

| 参数 | 语义（源码位置） |
|---|---|
| `--check` | **只核对不写**；0 = 四处一致；1 = 有分叉并**逐处点名**（`:68-89`） |
| `--why '<一句话>'` | **不带 `--check` 时**才是"就地钉齐（写文件）"；`--why` 的值追加进 `generation.arms_retaken.history`（**只追加、不覆盖历史**，`:104-111`） |
| 都不给 | **也会写盘**（`:91-113`），只是不追加 history 条目 ⇒ **会留下"重钉了但没人知道为什么"** |

`--why` 与 `--check` 的**确切语义**：`--why` 是"这次重钉的理由"，**只有写盘那一趟才会被记录**；
`--check` 是"四处一致"的只读核对。**先 `--why` 写、后 `--check` 读**，两条都要。

要钉齐的**四处**（`:3-16`）：
1. `generation.{instr_run_sh,instr_program_cs,instr_shim}`（`GEN_KEYS`，`:31-36`）；
2. `generation.arm_logs{5 臂}` ＋ `generation.evidence_log_sha256`（`:37`、`:94-96`）；
3. **`entries[*].caliber.{同样三项}`**（门禁 `tline-gate.sh:505` 的 `entry_gen_bad` 判据比的就是这里；
   漏改 ⇒ `GATE_REASON=registry-generation-inconsistent`）；
4. `generation.arms_retaken`（人类可读；**如实追加**）。

```bash
python3 build/MilBridge/tools/repin-generation.py \
  --why '波 #46：win32shim 位变（焦点回送＋有界诊断）＋ pc 位变（D-G54 的 hwndtarget 插桩/修法）⇒ 重取五臂后按纪律四处处同趟钉齐；tline 臂日志 <旧16>→<新16>' \
  > "$HOME/w46-repin.log" 2>&1 ; echo "repin_rc=$?"
python3 build/MilBridge/tools/repin-generation.py --check > "$HOME/w46-repin-check.log" 2>&1 ; echo "repin_check_rc=$?"
tail -4 "$HOME/w46-repin-check.log"   # 期望：REPIN_GENERATION=PASS（世代三项 + 五臂 + 证据日志 + N 条 entries 的 caliber 全部一致）
```

### ⚠️ 重钉**一定**会改 `build/MilBridge/known-red.json`，而它是**覆盖面成员**

- 它会**写盘**（`:112-113`，`json.dump` 整份重写 + 补一个换行）；
- `known-red.json` 在 `fp_inputs()` 的点名清单里（`build/close-wave.sh:179-180`）
  ⇒ **`inputs_fp` 必变**（`#44` 现场：`ee98113b… → 493551db…`，`ACCEPTANCE-BASELINE.md:25` 逐字记着）；
- ⇒ **流程代价**：**重钉必须安排在两次 `IN_FP_0`/`IN_FP_1` 采样之外**
  （即**不要**把它塞进同一趟 `close-wave.sh` 里跑 —— `close-wave.sh:315-317` 会 `exit 5`）。
  §2 的路 A 用 `--skip-verify-all` 仍然会采 `IN_FP_0/IN_FP_1`（`:241`/`:315`）
  ⇒ **重钉放在路 A 之后**是对的；
- ⇒ 也正因如此，`GENS['#46']['infp']` 应写 **`None`**（见 §6）。

### 反向陷阱：**重钉会把"陈旧的臂日志"洗成绿**

`repin-generation.py:94-96` 只是"读盘上那份日志的 sha 并登记"，**不做任何新鲜度检查**；
`arm-log-sha-check.sh` 也只会说"声明 == 现场"（自指）。
⇒ 若重取臂那一步**静默失败**（空日志 ⇒ `:99-100` 不覆盖，保留旧世代日志），
**重钉会把旧世代的日志 sha 钉成新世代的声明，而三道相关牙全绿**。
**对策**（写进记录）：重钉前用 §3 的"逐臂 sha + mtime + links"表**人工对一眼**
`mtime` 必须晚于本次重取的开始时刻；`tline.log` 里的 `<pc16>` 必须 == §1-P4 的 `pc`。

---

## 5 `verify-all` 的"同趟多处"（**实测是 5 处，不是 3 处**）

### 5.0 先更正路径

任务书里写的 `tests/WpfGfx.Linux.Tests/**/verify-all.sh` **不存在**。全仓只有**一个**
`verify-all.sh`，在**仓根**：`$R/verify-all.sh`（891 行）。`tests/` 下只有
`tests/WpfGfx.Linux.Tests/**` 的测试工程。⇒ 下面所有行号都是 `$R/verify-all.sh` 的。

### 5.1 五处同趟位（**逐条原文 + 行号**，现场读出）

**① 机器读声明块（步数 + 世代号）—— `verify-all.sh:44`（**必须是该块的第一行**）**
```text
# VERIFYALL-STEPS-DECL: 25 gen=#44   ← `#44` **不动步数**（修 `D-G49`：shim 的**鼠标五键 `GetKeyState`** —— 只动 `win32shim` 一位）
```
`#46` 收尾要**在它上面插一行**（`#46` 那行），并**保留 `#44` 行原样**（史实行只许追加，`:58`）：
```text
# VERIFYALL-STEPS-DECL: 25 gen=#46   ← `#46` **不动步数**（修 `D-G50` 焦点回送＋`D-G54`；只动 `win32shim`／`pc`）
```

**② 步名清单（机器读）—— `verify-all.sh:59`**
```text
# VERIFYALL-STEP-NAMES: 主工程 WpfGfx.Linux | wpf-linux.sln | Commands.Tests | Rendering.Tests | Windowing.Tests | HelloMil.Tests | ManagedLayer.Tests | Presentation.Tests | verify-cmd-layout.py | tline-gate（五臂） | PcLineOracle·Start 列 | FrameProbe-frame | BASELINE-SHA | ARM-LOG-SHA | BUILD-HYGIENE | DEFECT-REGISTRY | VERIFYALL-SELF | FP-INPUTS-HYGIENE | HIDDEN-ONLY | COLUMN-FLOOR | QUOTE-TRAP | PRODUCT-ENTRY | FRAME-PRESENCE | PIPEFAIL-SIGPIPE | THIRD-PARTY
```
本波**不动步数** ⇒ 这一行**一个字都不许改**（25 个名字）。

**③ 头注释口径句（人读，但被机器 `grep -qF`）—— `verify-all.sh:69-73`（`#44` 那段的开头）**
```text
#   **`#44` 收官起 = 25 步**（**不动步数**：修 **`D-G49`** —— 上游 `Win32MouseDevice:45,61` 判按钮状态**只看**
```
`#46` 要**逐字**出现（含反引号与 `**`）：
```text
#   **`#46` 收官起 = 25 步**（**不动步数**：…
```

**④ 现场 `run_step "` 调用点（**25** 处，行号现场算出）—— 这才是"现场条数"的来源**

| # | 行号 | 步名 |
|---|---|---|
| 1 | `403` | `主工程 WpfGfx.Linux` |
| 2 | `417` | `wpf-linux.sln` |
| 3 | `424` | `Commands.Tests` |
| 4 | `425` | `Rendering.Tests` |
| 5 | `426` | `Windowing.Tests` |
| 6 | `427` | `HelloMil.Tests` |
| 7 | `434` | `ManagedLayer.Tests` |
| 8 | `436` | `Presentation.Tests` |
| 9 | `443` | `verify-cmd-layout.py` |
| 10 | `465` | `tline-gate（五臂）` |
| 11 | `487` | `PcLineOracle·Start 列` |
| 12 | `509` | `FrameProbe-frame` |
| 13 | `532` | `BASELINE-SHA` |
| 14 | `536` | `ARM-LOG-SHA` |
| 15 | `608` | `BUILD-HYGIENE` |
| 16 | `648` | `DEFECT-REGISTRY` |
| 17 | `669` | `VERIFYALL-SELF` |
| 18 | `696` | `FP-INPUTS-HYGIENE` |
| 19 | `714` | `HIDDEN-ONLY` |
| 20 | `735` | `COLUMN-FLOOR` |
| 21 | `752` | `QUOTE-TRAP` |
| 22 | `771` | `PRODUCT-ENTRY` |
| 23 | `800` | `FRAME-PRESENCE` |
| 24 | `801` | `PIPEFAIL-SIGPIPE` |
| 25 | `805` | `THIRD-PARTY` |

机器证（**引用前自己重算**）：`grep -c '^run_step "' verify-all.sh` ⇒ `25`。
⚠️ **不带锚的 `grep -c run_step` 会数到函数定义与注释**（`:27-30` 明确警告过），别用它。

**⑤ 预登记标题行（`#46` 必须出现在某件 `docs/WAVE*-PREREGISTRATION.md` 的标题行里）**

读者：`build/MilBridge/tools/verify-all-step-check.sh:207-219`（`grep -qE "^#+ .*${gen_decl}"`）。
现场已满足：
```text
docs/WAVE46-PREREGISTRATION.md:1:# 波 `#46` —— **抓取伪焦点事件**把 WPF 键盘焦点清空 ⇒ `ComboBox` 下拉"弹出即被关掉"（`D-G50` 产品修复）
```
⚠️ 注意它**判的是 `gen_decl`**（= ①那行的世代号）⇒ ①没改成 `#46` 时它照样绿（见 §9-R3）。

### 5.2 改错会怎样红（读者 `verify-all-step-check.sh` 的判定表）

| 改错形态 | 读数 | 出处 |
|---|---|---|
| ① 的**数**改了、②的名数没跟上 | `VERIFYALL_SELF=FAIL … decl-self-inconsistent(DECL=25 但列了 24 个名字)` | `:118-120` |
| ① 的数 ≠ 现场 `run_step` 条数 | `FAIL … count-mismatch(现场 26 ≠ 声明 25)` | `:122-124` |
| ② 少/多一个名字 | `FAIL … name-set-differs(现场独有=[…] 声明独有=[…])` | `:144-146` |
| ② 换了次序 | `FAIL … name-order-differs(第 N 位 …)` | `:148-155` |
| ② 里重名（且把 DECL 也 +1 掩盖） | `FAIL … duplicate-step-name(…)`（**只有这条能抓**） | `:157-164` |
| ③ 写了 `#46` 但数字 ≠ 现场 | `FAIL … prose-mismatch(头注释「#46 收官起」后来跟的数 ≠ 现场 25)` | `:171-172` |
| ③ **整句缺** | `VERIFYALL_SELF=NOINFO reason=header-prose-absent …`，**`rc=2`** | `:174` |
| ① **整行缺** | `NOINFO reason=decl-absent`（`rc=2`） | `:90` |
| ② **整行缺** | `NOINFO reason=names-absent`（`rc=2`） | `:100` |
| ⑤ `#46` 没出现在任何预登记标题行 | `NOINFO reason=prereg-absent`（`rc=2`） | `:215-218` |

⚠️ **`NOINFO` 是 `rc=2`，在 `verify-all.sh` 里算失败**（这一步的 rc 被计入 `fail`）——
"没声明"**不许当绿**（`:40`）。

### 5.3 冻结器**另外**有两颗牙盯着同两处

`$HOME/w21-verify/w27-freeze.py:295-299`：
```python
n_rs = len(re.findall(r'^run_step "', open(V, encoding='utf-8').read(), re.M))
assert n_rs == nstep, f'`verify-all.sh` 的 `^run_step "` 行数 {n_rs} ≠ 现场步数 {nstep}'
assert re.search(r'\*\*`' + re.escape(gen) + r'` 收官起 = ' + str(nstep) + r' 步\*\*', vh), …
```
⇒ ③ 必须**逐字**含 `` **`#46` 收官起 = 25 步** ``，否则**冻结器直接 `AssertionError`**。

### 5.4 闸门 ×2（应用门禁）—— 冻结器要的 6 条机读行从这里来

```bash
G=tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh
rm -f "$HOME/w46-gate-rows.txt"
WPTD_RUN_DIR="$HOME/w46-gate-e" WPTD_BASELINE_OUT="$HOME/w46-gate-rows.txt" \
  timeout 900 bash "$G" 60 --tier both > "$HOME/w46-gate-e.log" 2>&1 ; echo "gate_e_rc=$?"
WPTD_RUN_DIR="$HOME/w46-gate-f" \
  timeout 900 bash "$G" 60 --tier both --no-build > "$HOME/w46-gate-f.log" 2>&1 ; echo "gate_f_rc=$?"
grep -c '^BASELINE ' "$HOME/w46-gate-rows.txt"                      # 期望：6
grep -o 'result=[A-Z]*' "$HOME/w46-gate-rows.txt" | sort | uniq -c  # 期望：6 result=PASS
```
（`#44` 的原样命令见 `build/wave-audit.log` / `$HOME/w44-close.sh:14-18`。）
相关 env（`run-wpftextdemo.sh`）：`WPTD_DISPLAY`（默认 `:97`，`:317`）、`WPTD_RUN_DIR`（默认带 `$$`）、
`WPTD_BASELINE_OUT`（`:456`）、以及阈值 `WPTD_MIN_COLORS`(`:731`)/`WPTD_MIN_TEXT_PX`(`:735`)。
**冻结器硬要求**（`w27-freeze.py:398-402`）：行数 == 6、全部 `result=PASS`、
**每一行都含终态的 `pc:<新pc>` 与 `pf:<新pf>`** ⇒ 门禁行**必须在整波重建之后重新生成**
（拿 `#44` 那份旧行会被这两条 `assert` 当场拦下）。

---

## 6 重冻 `#46`

**脚本**：`$HOME/w21-verify/w27-freeze.py`（`#27` 立的通用版；`#44` 用它冻过）。
**用法**（`:1-3`、`:231-234`）：
```bash
python3 $HOME/w21-verify/w27-freeze.py <verify-all 日志> <应用门禁 baseline 行文件> '#46'
```
**世代号必须显式给**（`:231-233`：原先默认 `#27` 会把一个**过去**的世代写成默认 ⇒ 漏给参数会去重冻 `#27`）。

### 6.1 要先加的一张表项

`w27-freeze.py:26-229` 是 `GENS` 常量表；**只许追加、不许改老代**（`:25`）。要**新增**：

```python
'#46': dict(TXT='/home/links-dev/w21-verify/w46-record.txt',
            PRE='/home/links-dev/w46-pre.sha',
            prev='#44', nstep=25, prev_pf='<见下表>', prev_pc='<见下表>',
            infp=None,
            prev_infp='493551dbffb1a937297bcb222389690c6df9bafa0c5c468a19e31a07b32c2f5f',
            hb='e89fed55fd8e32bc', bs_fp='<见下表>', prev_bsfp='794ea22406cc88ab',
            allow_changed={'pc', 'pf', 'win32shim'},
            pf_required=False,
            prev_wb='84a2826c471e60ea', prev_wsh='11f81eb9dfc60a12', prev_dwf='de2d555105b7d04b',
            green=['BASELINE-SHA','ARM-LOG-SHA','BUILD-HYGIENE','DEFECT-REGISTRY','VERIFYALL-SELF',
                   'FP-INPUTS-HYGIENE','HIDDEN-ONLY','COLUMN-FLOOR','QUOTE-TRAP','PRODUCT-ENTRY',
                   'FRAME-PRESENCE','PIPEFAIL-SIGPIPE','THIRD-PARTY']),
```

### 6.2 每一格为什么这么填 + 待填值清单

| 字段 | `#46` 的填法 | 为什么（逐条给源码位置与依据读数） |
|---|---|---|
| `TXT` | `/home/links-dev/w21-verify/w46-record.txt` → 见 §6.3 | `:404-408` 要求**三段式**（`===BANNER===`/`===FROZEN===`/`===RECORD===`）。**NOINFO（文件尚未写）** |
| `PRE` | `/home/links-dev/w46-pre.sha` → 见 §6.4 | `:344`/`:351` 用它算 `changed`，并**断言快照覆盖全部九位**。**NOINFO（尚未采）** |
| `prev` | `'#44'` | `#44` 的 `prev='#40'` 同形；`:243-247` 会现场断言「树上 `> BASELINE-FROZEN gen=` == 本值」⇒ **必须 `#44`**（实测 `BASELINEGEN=PASS decl_gen=#44`） |
| `nstep` | `25` | `:257` 由日志现算（`npass+nfail`），`:296` 再与 `^run_step "` 行数对账；本波**不动步数**（实测 25） |
| `prev_pf` | **`a93097f7a918597f`**（= 现树 `pf`） | `:368`/`:371`/`:419` 只在 `pf_required=True` 时参与断言；本代 `False` ⇒ 只进记录文本。若 `PRE` 在**重建之后**才采，这里应是 `PRE` 里的值 ⇒ **以 `w46-pre.sha` 的行为准**（NOINFO 项取决于采样时刻） |
| `prev_pc` | **`b1d3d5f33618a3d7`**（= 现树 `pc`，已含在飞改动） | 只进记录文本 `{PC_PREV}`；`#44` 填的是它当时的 `pc` |
| `infp` | **`None`** | `:392-395`：`None` ⇒ **不断言旧值**，只打印"本代设计性变更"。本波**符合**这个条件（新应用器进覆盖面 ＋ 重钉改 `known-red.json`）⇒ 与 `#44`/`#39`/`#40` 同形 |
| `prev_infp` | `493551dbffb1a937297bcb222389690c6df9bafa0c5c468a19e31a07b32c2f5f` | 出处 = `ACCEPTANCE-BASELINE.md:25`（`#44` 冻结块）**逐字**。**注意它与现树实测 `3a4b6cf1…` 不同**（见 §1-P5） |
| `hb` | `e89fed55fd8e32bc` | `:358` **硬断言**：`build/shims/PresentationCore.HbTextLine.cs` 本波**一个字节都不该动**（本波改的是 `src/WpfGfx.Linux.Native/src/*.c` 与 `pc` 侧）。**不满足 ⇒ 停条件③** |
| `bs_fp` | **冻结当时现算**（`20:09` 实测 `85e9afa176d60cd1`；`#44` 值 `794ea22406cc88ab`） | `:396` `assert BSFP == G['bs_fp']`。⚠️ **§0.1 已证 `D-G54` 修法落在 `src/WpfGfx.Linux/**`** ⇒ 该值**必换**，且换完必须**重发桥**使"现树 == 发布记录" |
| `prev_bsfp` | `794ea22406cc88ab` | 只用于记录文本 `{BSFP_PREV}`；`#44` 填的是它当时的 `bs_fp` |
| `allow_changed` | **`{'bridge','pc','pf','win32shim'}`**（依 §0.1 更正） | `:359-360` `assert set(changed) <= allow`，**表外位移即停（停条件①）**。依据：`#44` 冻结值 ⇒ 现树 `pc`/`win32shim`/`bridge` 三位已离开；`pf` 是"环成员"，按 `#31` 起的惯例允许动。⚠️ **绝不许为了过断言把 `allow` 放宽成"九位全给"**（那会把停条件①变成真空，见 §9-R9）；加了 `'bridge'` 就**必须**在记录里给出"为什么 bridge 动"的读数（§0.1 那四个 `src/WpfGfx.Linux/**` 源件） |
| `pf_required` | `False` | `#31`（`:191-198`）立的规则：`pf` **变或不变都如实记**，**不许为凑 `changed==['pf']` 去动产品件** |
| `prev_wb` / `prev_wsh` / `prev_dwf` | `84a2826c471e60ea` / **`11f81eb9dfc60a12`** / `de2d555105b7d04b` | `:422-424` 只进记录文本。`prev_wsh` 取 **`#44` 冻结值**（= 本波产品改动的"真·改前"），**不要**取 `w46-pre.sha`（那份是"已改后"）—— 并在记录里写清这个区别 |
| `green` | 与 `#44` **逐字相同的 13 个名字** | `:274-283`：声明类之外**必须✅**。本波 25 步未变 ⇒ 名单不变。⚠️ 名单外的步（前 12 步：构建/六个测试套件/命令线格/tline 门禁/`PcLineOracle`/`FrameProbe`）**不被这层看**，靠 `nstep==25` ＋ `结论：` 行兜（`:287-289`） |

### 6.3 `TXT`（`w46-record.txt`）要写什么、有哪些占位符

结构（`w27-freeze.py:404-408`）：文件必须能按 `===BANNER===\n`、`===FROZEN===\n`、`===RECORD===\n`
切成三段；**顺序即"贴着文件顶端写"**（`:453`：`banner + frozen + record + rows + 旧块`）。

**可用占位符**（`fill()` 在 `:417-437` 只认 `{全大写}`；**拼错一个名字当场红**，
"还有未替换占位符"也当场红）：`{GEN} {PREV} {PC} {PC_PREV} {PCSZ} {PF} {PF_PREV} {PFSZ} {HB} {HBSZ}
{BR} {BRSZ} {WB} {WB_PREV} {WSH} {WSH_PREV} {DWF} {DWF_PREV} {INFP} {INFP_PREV} {BSFP} {BSFP_PREV}
{NSTEP} {NCASE} {NSKIP} {ARMAGG_CAT} {ARMAGG_FIND}`。
`#44` 实际用了：`{BR} {BSFP} {DWF} {GEN} {HB} {INFP} {INFP_PREV} {PC} {PC_PREV} {PCSZ} {PF} {PF_PREV}
{PFSZ} {WB} {WSH}`（现算：`grep -o '{[A-Z][A-Z0-9_]*}' $HOME/w21-verify/w44-record.txt | sort -u`）。
⇒ **最省事的做法**：`cp -p $HOME/w21-verify/w44-record.txt $HOME/w21-verify/w46-record.txt` 后**逐段改写**
（三段式与占位符天然保留）。

🔴 **`FROZEN` 段里必须自带这几行**（它们是**别的牙的输入**，漏了就红）：
```text
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=<现算>
# ARM-LOG-SHA arm=tab-anchor    sha16=<现算>
# ARM-LOG-SHA arm=tab-zero      sha16=<现算>
# ARM-LOG-SHA arm=tab-rtl       sha16=<现算>
# ARM-LOG-SHA arm=tline         sha16=<现算>
# ARM-LOG-SHA arm=textlineproto sha16=<现算>
```
读它们的是：`column-floor-check.sh` 的判据 ①/③/④/⑤（`:12-24`）与 `arm-log-sha-check.sh`。
`ARM-LOG-SHA` 的 5 个 16 位值 **= 重取后 5 支臂日志 `sha256sum | cut -c1-16`**（§3 那张表直接照抄）。
⚠️ `column-floor-check.sh` 判据 ⑤（`# ARM-LOG-SHA` 行）是**刻意设计成"缺行不判"**（`NOTDECLARED`，**不并入 rc**）
—— 缺了它 `COLUMN_FLOOR` 仍会 `PASS`，而 `D-G9` 的"`arm_logs` 自指"残差**就还活着**。

### 6.4 `PRE`（`w46-pre.sha`）怎么采

格式 = 每行 `<仓内相对路径> <16位sha16>`（`w27-freeze.py:344`：`l.split()[0] / [1]`），
**路径必须与 `NINE`（`:333-341`）逐字相同**，九行一个不缺（`:351-352` 会断言）。
```bash
CFG=$(bash build/selfbuilt-config.sh); : > "$HOME/w46-pre.sha"
for p in build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so \
         build/PresentationCore.Linux/bin/$CFG/PresentationCore.dll \
         build/PresentationFramework.Linux/bin/$CFG/PresentationFramework.dll \
         build/WindowsBase.Linux/bin/$CFG/WindowsBase.dll \
         build/DirectWrite.Linux/Provider/bin/$CFG/DirectWrite.Linux.Provider.dll \
         src/WpfGfx.Linux.Native/bin/libwpfwin32.so \
         build/DirectWrite.Linux/wic-shim/libwpfwic.so \
         build/shims/PresentationCore.HbTextLine.cs \
         build/DirectWriteForwarder.Linux/bin/$CFG/DirectWriteForwarder.dll ; do
  printf '%s %s\n' "$p" "$(sha256sum "$p" | cut -c1-16)" >> "$HOME/w46-pre.sha"
done
wc -l "$HOME/w46-pre.sha"     # 期望：9
```
⚠️ **口径要诚实写进记录**：本波的 `PRE` **不可能**在"产品改动之前"采了（`pc`/`win32shim`
已经离开 `#44` 冻结值）⇒ `changed` 只反映**波内重建位移**；
**产品位移要用 `#44` 冻结值另立一栏对账**（`prev_pc`/`prev_wsh`/`prev_pf` + `prev_wb/wsh/dwf` 就是为此）。

### 6.5 冻完脚本自己会做的三件事（**别抢在它前面做**）

`w27-freeze.py:455-474`：
1. 重写 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（新块插在最前、旧块加 `⏪ **（历史，已被 #46 取代）**` 前缀）；
2. 改 `docs/CURRENT-STATE.md` 的**唯一**机器行 `> BASELINE-FROZEN gen=#46 sha16=<新16>`（`:459-461`）；
3. 跑 `baseline-sha-check.sh`（断言 `BASELINEGEN=PASS`）、`arm-log-sha-check.sh`（断言 `ARMLOG_SHA=PASS`）、
   `column-floor-check.sh`（断言 `COLUMN_FLOOR=PASS`）—— 这就是 **`D-G44` 两极化的后半**：
   **冻前红 ⇒ 冻后必须绿**。任一不过 ⇒ 脚本 `AssertionError`。

---

## 7 冻后两趟

确切两条命令（`#44` 原样，见 `$HOME/w44-verifyall-post1.log` / `post2.log`）：
```bash
bash verify-all.sh > "$HOME/w46-verifyall-post1.log" 2>&1 ; echo "VA_POST1_RC=$?"
bash verify-all.sh > "$HOME/w46-verifyall-post2.log" 2>&1 ; echo "VA_POST2_RC=$?"
```
判据（两趟都要）：
```bash
grep -aE '步骤通过|❌ 失败|结论：' "$HOME/w46-verifyall-post1.log" | tail -2
# 期望： 步骤通过 25  ❌ 失败 0   ／   结论：✅ 全部通过
grep -aE '步骤通过|结论：' "$HOME/w46-verifyall-post2.log" | tail -2
# 四项声明类自报**两趟逐字相同**：
for f in post1 post2; do grep -aoE '(BASELINESHA|ARMLOG_SHA|COLUMN_FLOOR|VERIFYALL_SELF)=[A-Z]+' \
  "$HOME/w46-verifyall-$f.log" | sort -u | tr '\n' ' '; echo; done
```
⚠️ **跑之前先冻**：第 `[7]` 步 `BASELINE-SHA` 在冻前**必然红**（声明类），冻后必须绿。
`#44` 的实测：`post1 = 25 步 / 通过 25 / 失败 0 / rc=0`，`post2` 同（`docs/CURRENT-STATE.md:79` 那套口径）。
⚠️ **两趟之间不许改仓内任何件**：`#44` 曾因"预计还要改产品件"**主动停掉第一趟**并按 PID 止损
（`docs/WAVE44-PREREGISTRATION.md:172`）—— 如实记这种过程，不要把它当失败。

---

## 8 回滚（哪一步失败退回到什么状态）

| 失败点 | 退回状态 | 具体动作 |
|---|---|---|
| §2 波内 `APPLIER_AUDIT` miss≠0 | **不动**（还没重建出坏件） | 修应用器接线后**重跑整波**；`build/.wave-done` 由 `trap` 保证存在（`:85`） |
| §2 波中途发现输入被改（`波前≠波后`） | 重跑整波 | 先让改件的人停手，再 `WAVE_OWNER=主控 bash build/integration-wave.sh` |
| §3 守卫 `exit 4`（同 inode） | **一个字节都没写** | 换一个与 `arm-logs/` 不同 inode 的 `ARMS_OUT` 重跑（`:37-53`） |
| §4 `repin --check` 分叉 | **只改 `known-red.json`**（已是改后态） | 按点名逐处补齐（`entries[*].caliber` 最常漏）；**别急着冻** |
| §5 `verify-all` 出现**非**声明类红 | 停 | 那不是两极化该有的形态 ⇒ 先定性（是产品回归还是判据问题），**不许压绿** |
| §6 冻结器 `AssertionError`（`表外位移` / `hb` 变 / `inputs_fp` 不匹配 / 门禁行 `pc`/`pf` 不终态） | **基线未写**（断言全过才写盘，`:1` 承诺） | 按报错逐条核；**最常见两条**：门禁行没重生成（§5.4）、`allow_changed` 与现场位移不符 |
| §7 冻后某趟有红 | **基线已写，但"当前件"没变** | 先 `BASELINESHA`/`BASELINEGEN` 两颗牙看是不是声明层；**改到一半的九位**见下 |

### 「改到一半的九位」怎么办（**这是最需要预演的一种**）

判据：**九位不是一成不变的集合，而是一个"必须自洽"的元组** —— 自洽的定义写在
`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的最新块里（`#46` 冻完就是 `#46` 那块）。

1. **先别慌、先读哨兵**：`/tmp/bridge-frozen.flag`（＋镜像 `$HOME/wfp-runs/bridge-frozen.flag`，
   `close-wave.sh:350-374` 自动更新；**`/tmp` 被整盘清过**，见 `:365-368`）会告诉你
   "产生当前件的那条命令"报的九位是什么。
2. **重建出来的半成品是"可恢复"的**：`integration-wave.sh` 的产物全部能从源重放
   （`port-lib.py` → 应用器 → 构建），**没有"不可逆"步骤**。⇒ 正道是**把波跑完**
   （`WAVE_OWNER=主控 bash build/integration-wave.sh`），而不是手工拼回去。
3. **不可逆的只有两件（要小心）**：
   - `repin-generation.py` **整份重写** `known-red.json`（`:112`）⇒ 先 `cp -p` 备份到 `$HOME/w46-backups/`；
   - `w27-freeze.py` **整份重写** `ACCEPTANCE-BASELINE.md` 与 `docs/CURRENT-STATE.md` 的机器行。
     它**没有 `--dry-run`** ⇒ 冻前务必 `cp -p samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
     $HOME/w46-backups/ACCEPTANCE-BASELINE.md.pre46`（`#37` 就有 `$HOME/w37-backup-CURRENT-STATE.beforefreeze.md` 这个先例）。
4. **回退到"上一个自洽元组"**：把 `docs/CURRENT-STATE.md:9` 的机器行改回 `gen=#44 sha16=ff3990dafa582831`，
   并让九位回到 `#44` 冻结值（`pc 45e7e0a46f5912c0`、`win32shim 11f81eb9dfc60a12`，其余七位本来就未变）。
   ⚠️ `pc`/`win32shim` 的**旧字节没有仓内备份** ⇒ 只能靠"还原源 + 重跑整波"逼近；
   **若逼近不出来，如实记"元组已前进、`#44` 不再可复现"**（`BASELINESHA` 会红，那是**诚实的红**）。
5. **绝不许做的事**：手改 `BASELINE-FROZEN` 的 sha16 去"对上"一个半成品元组
   （`BASELINEDUP`/`BASELINESHA` 就是为这件事存在的：`:718` 明说"整份 sha 只许脚本算"）。

---

## 9 🔴 假绿风险清单（读完源码点名的，逐条给 `文件:行`）

> 判据：**"看起来绿其实没生效"** —— 即某个环节退化了，而收尾链上**没有任何东西会红**。
> 每条给：机制、现场证据（若有）、收尾时的对策。

**R1 · `integration-wave.sh` 第 4 步读的是 `bin/Debug`（而权威件是 `Release`）**
- 现场：`build/integration-wave.sh:493` 逐字 `dll="build/$d/bin/Debug/$want"`；
  判定只有 `:498-506` 一个字符串包含检查（"已签名(带公钥)"）。
- 机制：`#40` 起 `SELFBUILT_CONFIG=Release`，但这一行**写死 Debug**。仓里 Debug 件**确实存在**
  （实测 `PresentationCore.Linux/bin/Debug` 9 个 dll、`PresentationFramework.Linux/bin/Debug` 13 个）
  ⇒ 这一步**永远绿**，而它**从来没看过**本次真正产出的 Release 权威件。
  日志证据：`$HOME/w44-wave.log` 尾部那 5 行 `已签名(带公钥)` 全是 Debug 副本。
- 对策：① 别把这一步当"产物身份已核"；真正的产物身份靠 §1-P4 九位 ＋ `close-wave.sh:303-307`
  的桥指纹/生成物指纹；② 建议**另立一趟**把 `:493` 改成 `$SELFBUILT_CONFIG`（**本波不做**，
  因为改它要排在 `IN_FP_0` 采样之前，属独立准备趟 —— `close-wave.sh:125-126` 的流程代价）。

**R2 · 新增的应用器 `patch-presentationcore-hwndtarget-trace.py` **不在任何审计覆盖面内****
- 现场：`build/integration-wave.sh` 里 `grep -c hwndtarget` == **0**；
  `build/MilBridge/tools/applier-audit-expected.txt` 里也 **0** 命中（24 条登记里没有它）。
- 机制：它靠 `build/integration-wave.sh:302-307` 的 **glob 兜底**被执行（`patch-presentation*.py`），
  但 `applier-audit.py:398-402` **只报"清单里有、wave 里没有"**（`missing_reg`），
  **从不报"wave 里有、清单里没有"** ⇒ 这个应用器**被摘掉/改坏都不会红**（正是 `#38` 记录的那类
  "静默漏掉"事故的同一形态）。
- 对策：收尾前把它**同时**登记进 `APPLIERS_EXPLICIT`（顺序确定）与 `applier-audit-expected.txt`；
  并注意：**`applier-audit-expected.txt` 与 `integration-wave.sh` 都在 `fp_inputs()` 覆盖/点名里** ⇒
  这两处改动会**再动一次 `inputs_fp`** ⇒ 必须排在 `IN_FP_0` 采样之前（独立准备趟）。

**R3 · `#46` 的 `STEPS-DECL` 行若插在 `#44` 行**下面**，五处里有两处会静默漏判**
- 现场：`build/MilBridge/tools/verify-all-step-check.sh:69` `decl_line()` 是
  `sed -n … | head -1` —— **只取第一条**；`:57-58` 又明说史实行只许追加。
- 机制：① 插在下面 ⇒ `gen_decl` 仍是 `#44` ⇒ ③ 的口径句去核 `**#44 收官起 = 25 步**`（历史上还在）
  ⇒ `prose=OK`；⑤ 的预登记检查也去核 `#44` ⇒ `docs/WAVE44-PREREGISTRATION.md` 标题里有 ⇒ `prereg=PASS`；
  而 `w27-freeze.py:298` 要的是 `**#46 收官起 = 25 步**`——它**恰好也存在** ⇒ **五处全绿，
  机器读的"当前世代"却还是 `#44`**。
- 对策：**`#46` 那行必须是 `VERIFYALL-STEPS-DECL` 块的第一行**；收尾后跑
  `sed -n 's/^#[[:space:]]*VERIFYALL-STEPS-DECL:[[:space:]]*//p' verify-all.sh | head -1` 确认输出以 `25 gen=#46` 开头。

**R4 · `close-wave.sh` 的 native 重建决策**完全靠 mtime****
- 现场：`build/close-wave.sh:255-256` `find … -printf '%T@\n' | sort -rn | head -1` vs `stat -c %Y "$NATIVE_AUTH"`。
- 机制：mtime **不是内容**。`#46` 的预登记 §5 记着一次"**还原 `win32_x11.c` 到冻结字节**"的动作 ——
  任何 `cp -p` / 解档 / 时间戳保留式的还原都会给源一个**旧 mtime** ⇒ `NEED_NATIVE=0` ⇒
  **权威 `.so` 停在旧世代，而整条链照跑**（`#14` 就吃过"shim 在波中途被改而未被发现"）。
- 对策：走 §2 路 A 的 `--native`（**强制**重建）；路 B 则**必须**看 §1-P6 的
  `newest_src vs auth` 与"5 份副本同 sha"两张表，**并以 `win32shim` 的 sha ≠ `11f81eb9dfc60a12` 为验收**。

**R5 · `libwpfwin32.so` 的 4 份副本全落后，而两条链都不会替其中两份跟上**
- 现场：§1-P6 实测 —— `SystemFontsProbe/bin/Debug/`（`build/DirectWrite.Linux/…`）与
  `samples/WpfFeatureProbe/bin/Release/net10.0/` 里的副本仍是 `11f81eb9dfc60a12`（`#44` 值），
  而权威件是 `e700c383ec1ecdc8`。
- 机制：只有 `build/MilBridge/run.sh:97` / `:230` 会替 `CompositeFontProbe`/`ContractProbe`
  **现场 `cp`**；`integration-wave.sh` 第 3.6 步（`:474-485`）走的是
  `sync-applocal-authority.sh`，其口径是**托管程序集**的 app-local 副本。
- 对策：收尾时做一次**全副本同步**（`close-wave.sh:274-287` 的 [2/6]，或手工同形循环），
  并用 §1-P6 那条 `find … | while read` 复算：**5 行必须同 sha**。

**R6 · 闸门的 `BRIDGE_SRC_STALE` 是 advisory，`yes` 也不判红**
- 现场：`tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh:713-728`
  （`advisory` 那句在 `:715`，判定代码在 `:717-728`）
  逐字：「这一位是 **advisory**（不单判红，主控 2026-09-14 口径）」。
- 机制：`WPTD_GATE=PASS` 可以与 `WPTD_BRIDGE_SRC_STALE=yes`（"本趟读数作废"）**同时出现**；
  冻结器**完全不看**这一位 ⇒ 一份"读数作废"的门禁行照样能进基线。
- 对策：§2 之后**必须**显式核这两行：
  `WPTD_BRIDGE_SRC_STALE=no basis=pub=<X> now=<X> so_file_match=yes`（在 gate 日志尾部）
  —— `#46` 若动了 `src/WpfGfx.Linux/**` 而没重发桥，就是 `yes`。

**R7 · `arm-log-sha-check.sh` 与 `column-floor-check.sh` 判据 ⑤ 都是"自指"**
- 现场：`arm-log-sha-check.sh` 的判据只有"现场 sha == `known-red.json` 的声明"；
  `column-floor-check.sh:20-25` 明说 ⑤（`# ARM-LOG-SHA` 行）**刻意"缺行不判"、不并入 rc**。
- 机制：**同一份 `known-red.json` 既是被审对象又是判据** ⇒ 失真日志 ＋ 同趟把 `arm_logs` 也改掉
  ⇒ `ARMLOG_SHA=PASS pass=5 fail=0`。
- 对策：§4 里那条"重钉前人工对 mtime/pc""是**唯一**的补偿；另把 5 行 `# ARM-LOG-SHA`
  写进 `#46` 冻结块（§6.3），让判据 ⑤ 的锚落在**另一份文件**上。

**R8 · `repin-generation.py` 不做任何新鲜度/原因校验**
- 现场：`:94-96` 读盘上那份日志 sha 就登记；`:104` `if args.why:` ⇒ **不给 `--why` 也照样写盘**，
  只是不追加 history。
- 机制：见 §4 的反向陷阱 + "重钉了但没人知道为什么"。
- 对策：`--why` **必给**；重钉前后各存一份 `known-red.json` 备份与 `--check` 输出。

**R9 · `w27-freeze.py` 的 `infp=None` 与 `allow_changed` 都是**可以合法变真空**的开关**
- 现场：`:392-395`（`None` ⇒ 不断言 `inputs_fp`）、`:359-360` + `:384-389`（`allow` 集合内的位
  **不再逐位断言**）。
- 机制：把 `infp` 一律写 `None`、或把 `allow_changed` 写成九位全给 ⇒ 停条件① 与 停条件② **同时失效**，
  而脚本**仍然 PASS**。
- 对策：`infp=None` 只在**真的**有覆盖面变更时用，并在记录里**点名是哪个覆盖面成员变了**
  （`#44` 就是这么做的：明写是"重钉 `known-red.json`"）；`allow_changed` **只列本波真的会动的位**
  （`#46` 预测三格：`pc`/`pf`/`win32shim`），**并且**在记录里保留 `#44` 冻结值那一栏做产品位移对账。

**R10 · `DEFECT-REGISTRY` 的 route 件与声明件**不在 `fp_inputs()` 覆盖面、也不在 `GEN_KEYS`**
- 现场：`build/close-wave.sh:104-115` 的覆盖面逐条读过 —— `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`
  与 `build/MilBridge/tools/defect-registry-declared.tsv` **都不在其中**（点名的 15 件里没有它们）。
- 机制：改 route 文件或改声明表 ⇒ **`inputs_fp` 一点不动**（"改它必须看得见"这条纪律在这两件上是欠账）；
  唯一会红的是 `defect-registry-check.sh` 自己（它在覆盖面里，所以"**改判据**"看得见，"**改被判的输入**"看不见）。
- 现场读数就是证据：`DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN`（§1-P7）——
  `KNOWN-DEFECTS.md` 在 `DECL-GEN(18:19)` 之后被改过（19:59），而**没有任何牙因此变红**（drift 只是诊断行）。
- 对策：§1-P7 的 `--emit` 是收尾前的必做项；并把"route/声明件不进覆盖面"这条欠账**写进 `#46` 记录**
  （留痕比假装没有好）。

**R11 · `verify-all.sh` 的 `tline-gate` 弱配对只对**不自报被测件**的臂生效**
- 现场：`build/MilBridge/tools/tline-gate.sh:386` `pairing = "strong" if dec_shim or (hdr_shim and fx_shim) else "weak"`；
  `:495-501` 的 `STALE-WEAK` 检查**只在"弱配对"分支里**（`else` 那半）。
- 机制：**自报**的臂（`tline` 就是：日志头就印 `sha256=…`）走"强配对"，用**内容**比世代 sha；
  这一支**不看 mtime**。⇒ 只要日志自报的 shim sha == 登记 sha，它就 `OK-declared`；
  而"这份日志是不是**这一次**跑的"只能靠 `arm_logs` 的 sha 声明（自指，见 R7）。
- 对策：同 R7；另外 §3 的"逐臂 mtime"表要**存档**（它是唯一独立于声明的新鲜度证据）。

**R12 · `verify-all.sh` 头注释里的两处"数"是**人读口径**，机器只认 ①/②**
- 现场：`verify-all.sh:22-23` 自己就警告：「`grep -c '^run_step "'` ⇒ `#31` 收官后应为 21 …
  **这一串也只是"上次现场算的结果"，引用前重算**」；`:27-30` 又说"**别把不带锚的计数当判据，
  也别引用任何写死的差额**"。
- 机制：头注释里的口径句（③）**只有 `grep -qF` 那一句**被机器核；其余散文（"第 10 步 = …"之类）
  **陈旧也不会红**。
- 对策：收尾时只信三样：`grep -c '^run_step "' verify-all.sh`（现场算）、`verify-all-step-check.sh` 的
  `VERIFYALL_SELF=` 行、`w27-freeze.py:295-299` 的两条断言。**别抄本文件里的行号当判据**（行号会随插入而移动）。

**R13 · `run-wpftextdemo.sh` 的 `WPTD_RUN_DIR` 默认带 `$$`，但 `WPTD_BASELINE_OUT` 不是"每趟清零"**
- 现场：`run-wpftextdemo.sh:28`（坑 1 逐字「`WPTD_RUN_DIR` 默认**带 `$$`**」）与 `:456`；
  `#44` 的 `$HOME/w44-close.sh:15` 有 `rm -f $HOME/w44-gate-rows.txt`。
- 机制：`WPTD_BASELINE_OUT` 是**追加**语义 ⇒ 忘了先 `rm` 就会把上一趟的行混进本趟文件，
  而冻结器只断言 `len(rows) == 6` —— 混到 7 行会红（好），但如果上一趟也是 6 行、
  且 `pc`/`pf` **恰好**相同，就会**悄悄用上一趟的读数**（`#44` 的 `--tier both` 一趟就是 6 行）。
- 对策：§5.4 的命令**逐字照敲**（含 `rm -f "$HOME/w46-gate-rows.txt"`），并在跑完后核
  `head -1 "$HOME/w46-gate-rows.txt"` 的 `date=` 与 `run_dir=` 是本次的。

---

## 10 `NOINFO` 清单（收尾前填不出来、必须靠现场读数补的）

| 项 | 为什么现在填不出来 | 依据哪次读数补 |
|---|---|---|
| `GENS['#46']['TXT']` 的文件内容 | `$HOME/w21-verify/w46-record.txt` **尚未写** | 照 `$HOME/w21-verify/w44-record.txt` 的三段式改写；5 行 `# ARM-LOG-SHA` 与 3 行 `# COLUMN-FLOOR`/`# COLUMN-CORPUS` 用 §3/§5.4 的实测值 |
| `GENS['#46']['PRE']` | `$HOME/w46-pre.sha` **尚未采**（且本波已非"改动前"） | §6.4 的命令，采完 `wc -l` = 9 |
| `prev_pf` / `prev_pc` | 取决于 `PRE` 采样时刻 | 现树实测 `pf=a93097f7a918597f`、`pc=b1d3d5f33618a3d7`；**以 `PRE` 行为准** |
| `bs_fp` | **已解答（§0.1）**：修法落桥侧 ⇒ 该值必换 | 冻结当时现算；`20:09` 实测 `85e9afa176d60cd1` |
| `allow_changed` 是否要加 `'bridge'` | **已解答（§0.1）：要加** | `src/WpfGfx.Linux/{Windowing/X11Window.cs,Interop/MilNative.cs,Interop/MilPresentation.cs,Resources/MilChannel.cs}` 于 `20:07–20:09` 被改；`bridge` 位 `496951adff86a557 → 58a7abfeda93e662` |
| `inputs_fp`（记录里那一栏） | 重钉会**再改一次**（且 §0.1 已实测再改过一次） | 冻结当时 `bash -c 'source <(sed -n "/^fp_inputs()/,/^}/p" build/close-wave.sh); fp_inputs'`（`20:07`=`3a4b6cf1…`、`20:09`=`0551ce17…`） |
| `w46-record.txt` 里 `{NSTEP}/{NCASE}/{NSKIP}` | 来自 `verify-all` 日志的实测行 | 冻前那趟 `verify-all` 的 `步骤通过 N ❌ 失败 M` 与 `用例通过 N 跳过 M` |
| 闸门两趟的 `colors=`/`frames=` 具体值 | 未跑 | §5.4 |
| 在飞改动最终停下时的九位 / `PRE` 内容 | 采集期间树在动（§0.1） | **采 `PRE` 之前先确认无人再改**（`build/.wave-done` 存在、`find src -newermt` 为空） |

---

## 附录 A：一条不漏的顺序骨架（可直接存成 `$HOME/w46-close.sh` 再逐段确认后跑）

```bash
#!/usr/bin/env bash
set -u
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"
CFG=$(bash build/selfbuilt-config.sh); echo "CFG=$CFG"

echo "=== [0] 前置（任一不绿就停）==="
bash build/selfbuilt-config.sh --check            || exit 1
bash build/MilBridge/tools/baseline-sha-check.sh  | tail -4
bash build/MilBridge/tools/defect-registry-check.sh | tail -1   # 必须 DEFREG=PASS（否则先 --emit，见 §1-P7）

echo "=== [0.5] 采 PRE（在整波重建之前）==="
#   §6.4 的循环照抄到这里

echo "=== [1] 整波重建（路 A）==="
bash build/close-wave.sh --native --bridge --skip-verify-all > "$HOME/w46-close-pre.log" 2>&1
echo "close_rc=$?"; tail -20 "$HOME/w46-close-pre.log"

echo "=== [2] 重取五臂 ==="
ARMS_OUT="$HOME/w46-arms" bash build/MilBridge/tools/retake-arms-w23.sh > "$HOME/w46-arms.log" 2>&1
echo "arms_rc=$?"

echo "=== [3] 重钉 ==="
python3 build/MilBridge/tools/repin-generation.py --why '波 #46：…' > "$HOME/w46-repin.log" 2>&1; echo "repin_rc=$?"
python3 build/MilBridge/tools/repin-generation.py --check | tail -1

echo "=== [4] 闸门 ×2（先 rm 行文件）==="
G=tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh
rm -f "$HOME/w46-gate-rows.txt"
WPTD_RUN_DIR="$HOME/w46-gate-e" WPTD_BASELINE_OUT="$HOME/w46-gate-rows.txt" timeout 900 bash $G 60 --tier both > "$HOME/w46-gate-e.log" 2>&1; echo "gate_e_rc=$?"
WPTD_RUN_DIR="$HOME/w46-gate-f" timeout 900 bash $G 60 --tier both --no-build > "$HOME/w46-gate-f.log" 2>&1; echo "gate_f_rc=$?"
grep -c '^BASELINE ' "$HOME/w46-gate-rows.txt"

echo "=== [5] verify-all（冻前；预期 1 项声明类红）==="
bash verify-all.sh > "$HOME/w46-verifyall-pre.log" 2>&1; echo "va_pre_rc=$?"
grep -aE '步骤通过|结论：' "$HOME/w46-verifyall-pre.log" | tail -2

echo "=== [6] 重冻 #46 ==="
python3 $HOME/w21-verify/w27-freeze.py "$HOME/w46-verifyall-pre.log" "$HOME/w46-gate-rows.txt" '#46'

echo "=== [7] 冻后 ×2 ==="
bash verify-all.sh > "$HOME/w46-verifyall-post1.log" 2>&1; echo "VA_POST1_RC=$?"
bash verify-all.sh > "$HOME/w46-verifyall-post2.log" 2>&1; echo "VA_POST2_RC=$?"
grep -aE '步骤通过|结论：' "$HOME/w46-verifyall-post{1,2}.log" | tail -4
echo "W46_CLOSE_DONE"
```

**骨架刻意没做的事**（照 `#44` 的如实条款）：不自动改 `defect-registry-declared.tsv`、
不自动写 `w46-record.txt`、不自动改 `verify-all.sh` 的 5 处世代 ── 这三件是**判定输入**，
必须由人**在自己看清 diff 之后**落。

---

## 11 本手册的两处自纠（车道 W46J 核对后）
1. **§6.1 模板** 曾写 `allow_changed={'pc','pf','win32shim'}`（缺 `'bridge'`）—— **冻结器与本手册 §6.2 都是含 `'bridge'` 的**，
   已就地改正（冻结器为准）。
2. **§6.4 的口径句** 说"`PRE` 不可能在改动前采 ⇒ `changed` 只反映波内重建位移"——**本波实况相反**：
   `PRE=/home/links-dev/w46-pre.sha` 是**按 `#44` 冻结值**逐行写好的 ⇒ `changed` 直接就是**产品位移**（更严，非事故）。
3. 另记两条**实际填值**（冻结时已生效）：`bs_fp='f10b4b297b2358e6'`（现树＝发布记录，`85e9afa176d60cd1` 是陈旧值，
   不改正会让 `:396 assert BSFP == G['bs_fp']` 当场红）；`prev_pc='45e7e0a46f5912c0'`（= `#44` 冻结值，与 `PRE` 一致；
   原先填的 `b1d3d5f33618a3d7` 是波内中间值）。

## 12 本手册的三处**现场纠正**（波 `#46` 实战后，下一波照此）
1. **冻结标记只看冻结件**：`grep -c '^# RE-FROZEN #46' samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（`{GEN}` 只在那里被填充；
   `$HOME/w21-verify/w46-record.txt` **永远是 `RE-FROZEN {GEN}`**，拿它当标记会白等）。
2. **`ARM-LOG-SHA` 与 `COLUMN-FLOOR(ARMLOG)` 不是同一颗牙**：冻前 `ARM-LOG-SHA` 已绿；红→绿的是 `COLUMN_FLOOR_ARMLOG`
   （`bad= tline` → `bad=无`）。别把"冻后转绿"记在 `ARM-LOG-SHA` 头上。
3. **别把"冻后两趟逐字相同"当口径**：`FRAMEPRESENCE`/`THIRDPARTY` 的帧数有抓帧时序抖动（两趟都 PASS）。

## 13 波 `#47` 追加的三条现场纪律
1. **同一目录只许一个重活**：`retake-arms-w23.sh` 在**最后一个写者退出之前**就会打印 arm sha 表 ⇒ 并跑时那些 sha 是**写中途值**；读数一律以"静默后隔 ≥25 s 复读两遍一致"为准。
2. **`tline.log` 不可复算**：它自报的差异只有 4 类运行相关字段（耗时／自产 artifact 的 sha16（自指）／带日期戳的输出名／`mktemp` 路径）⇒ **"`tline` 变了"不能当作产品位移**；产品位移要看 `pc`/`pf`/`bridge`/`win32shim` 与 `# ARM-LOG-SHA` 声明的一致性。
3. **app-local 副本这一跳有两半**：`libwpfwin32.so`（`close-wave.sh [2/6]` 管，走"直调整波"时**必漏**）与 `wpfgfx_cor3.so`（**三条链都不管**，见 `W1`）⇒ 收尾前必须**现场复算去重计数**并手工同步（本波两次都靠手工）。

## 14 声明与实际的偏差（波 `#48` 现场，车道 W50B 核出）
- **`verify-all.sh` 的 DECL 文案与 `docs/WAVE48-PREREGISTRATION.md` 标题一度写"另修 `D-G57`"，而该波并未修它**（根因 `NOINFO`）⇒ **声明超出实际改动**。
  ⇒ **纪律**：`gen=` 行里列出的"本波修了什么"**必须与落地件逐条对得上**；写"另修 X"之前先确认 X 真的在树上（`grep` 证据）。
- **位移口径**：单件重建那一刻的读数**不等于**整波重建后的读数（`#48`：2 位 → 3 位，因为 `windowsbase` 变会经 Roslyn 输入哈希级联到 `pc`/`pf`）⇒ 报位移一律以**整波后现场算**为准。
- **`DEFECT-REGISTRY` 无新鲜度保证**：`#48` 期间我 `--emit` 到 `declared.tsv` 之后又新增了 `D-G59`/`D-G60` ⇒ 它**再次变红**（`undeclared-id-in-route`）⇒ **冻前必须复跑一次 `--emit` + 复读 `DEFREG=`**（它非声明类 ⇒ 冻前必须绿）。
