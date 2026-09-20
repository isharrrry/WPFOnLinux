# W46H2 —— `ManagedLayer.Tests` 非声明类红的解红 ＋ 冻前 `verify-all` 重跑

> 车道：`W46H`（同一车位续做）｜执行窗口：`2026-09-19T21:31:50+08:00` → `2026-09-19T21:52:16+08:00`（**约 20.5 min**）
> 前一份报告：`build/MilBridge/W46H-report.md`（sha16 `7fa30d7fd839b49b`，569 行；**本文件不改动它**）。
> **本趟只做三件事**：① 同步 2 份陈旧 `wpfgfx_cor3.so`；② 重跑冻前 `verify-all`（新日志，不覆盖）；③ 本报告。
> 纪律：未跑 `w27-freeze.py`；未改 `verify-all.sh`／`known-red.json`／`arm-logs/**`／任何 `*.sh` 判定件；
> 未 `pkill -f`；`samples/**` **只做"`cp -p` 权威 `.so` 覆盖"**（主控本趟显式授权，属真同步、非改判据）。

## 0 结果一句话

**解红成功。** 新 `verify-all` = **`步骤通过 24 ❌ 失败 1`**，`rc=1`，失败步名**只有 `COLUMN-FLOOR`**（声明类，冻后必绿）；
**没有新的非声明类红**。冻结所需的两件（新日志 ＋ 门禁行文件）**绝对路径与 sha16 见 §3**，
且我已用 `w27-freeze.py:279-307` 的口径**模拟过全部相关断言，逐条为真**（§4）。

---

## 1 同步明细（`wpfgfx_cor3.so` 4 份；`libwpfwin32.so` 5 份）

**权威件**（`build/publish-milbridge.sh:81` 写进发布记录的绝对锚 `BRIDGE_SO_SHA256`）：
```
e3ea092010734f44  build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so   (5,019,968 B)
```

### 1.1 同步前（4 份，全仓恰 4 份，无第五份）

| sha16 | 大小 | 路径 | 判定 |
|---|---|---|---|
| `e3ea092010734f44` | 5,019,968 | `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` | 权威 |
| `e3ea092010734f44` | 5,019,968 | `build/MilBridge/.artifacts/bin/MilBridge.Linux/release_linux-x64/native/wpfgfx_cor3.so` | OK |
| **`6fac9e722299a768`** | 5,000,192 | `samples/WpfFeatureProbe/bin/Release/net10.0/wpfgfx_cor3.so` | **陈旧** |
| **`496951adff86a557`** | 4,991,984 | `samples/ThirdPartyMini/bin/Debug/net10.0/wpfgfx_cor3.so` | **陈旧** |

### 1.2 备份（`cp -p`，先备份后覆盖）

| 备份件 | sha16 | 大小 | mtime（保留原样）|
|---|---|---|---|
| `$HOME/w46h-backup/wpfgfx_cor3.so.WpfFeatureProbe.before` | `6fac9e722299a768` | 5,000,192 | `2026-09-19 20:10:15` |
| `$HOME/w46h-backup/wpfgfx_cor3.so.ThirdPartyMini.before` | `496951adff86a557` | 4,991,984 | `2026-09-19 05:27:49` |

### 1.3 同步动作（逐字命令与输出）

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
AUTH=build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so
ASHA=$(sha256sum "$AUTH"|cut -c1-16)          # e3ea092010734f44
find samples -name 'wpfgfx_cor3.so' | LC_ALL=C sort | while read f; do
  if [ "$(sha256sum "$f"|cut -c1-16)" != "$ASHA" ]; then cp -p "$AUTH" "$f"; printf 'SYNCED %s %s\n' "$(sha256sum "$f"|cut -c1-16)" "$f"; fi
done
```
输出：
```
SYNCED e3ea092010734f44 samples/ThirdPartyMini/bin/Debug/net10.0/wpfgfx_cor3.so
SYNCED e3ea092010734f44 samples/WpfFeatureProbe/bin/Release/net10.0/wpfgfx_cor3.so
```
（**用 `cp -p`**：保留权威件的 mtime；本仓 `D-A2-r` 的判据只看 sha，不看 mtime。）

### 1.4 同步后复算（4 份必须全等 ⇒ **实测全等，唯一值 1 个**）

```
e3ea092010734f44 5019968  build/MilBridge/.artifacts/bin/MilBridge.Linux/release_linux-x64/native/wpfgfx_cor3.so
e3ea092010734f44 5019968  build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so
e3ea092010734f44 5019968  samples/ThirdPartyMini/bin/Debug/net10.0/wpfgfx_cor3.so
e3ea092010734f44 5019968  samples/WpfFeatureProbe/bin/Release/net10.0/wpfgfx_cor3.so
find . -name 'wpfgfx_cor3.so' -not -path './upstream/*' | xargs sha256sum | awk '{print $1}' | cut -c1-16 | sort -u
  ⇒ e3ea092010734f44        （**去重后 1 个值**）
```

### 1.5 旁证牙（`check-applocal-sync.sh`，**只读**）

```
同步前：BRIDGE-ANCHOR=2  → APPSYNC=MISMATCH
同步后：ANCHOR-OK  build/MilBridge/.artifacts/publish/…/wpfgfx_cor3.so          e3ea092010734f44（== 发布记录）
        ANCHOR-OK  build/MilBridge/.artifacts/bin/…/native/wpfgfx_cor3.so        e3ea092010734f44（== 发布记录）
        ANCHOR-OK  samples/WpfFeatureProbe/bin/Release/net10.0/wpfgfx_cor3.so    e3ea092010734f44（== 发布记录）
        ANCHOR-OK  samples/ThirdPartyMini/bin/Debug/net10.0/wpfgfx_cor3.so       e3ea092010734f44（== 发布记录）
        ⇒ BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0
其余仍有的红（**与本次无关、登记在册**）：MISMATCH=1[STALE=1]（`tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll`，
        在册红 13 条里"仍红 1"，处置=重编 `tools/GeometryOracle`）、UNEXPECTED=12[DECL-GAP-EQ=9 DECL-GAP-DIFF=3]、DIVERGENT=3
        ⇒ 所以 `APPSYNC` 整体仍是 `MISMATCH`（那是 APPSYNC 的**登记在册告警语义**，不是本趟引入）。
```

### 1.6 顺手做的**机制证**：先单跑那颗牙（不等整趟 `verify-all`）

```bash
dotnet test tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj -c Release --no-build -m:1 \
  -v n --filter 'FullyQualifiedName~闸门_win32shim'      > $HOME/w46h/08-managedlayer-gate-after-sync.log 2>&1
```
| 时点 | rc | 逐字 |
|---|---|---|
| 同步**前**（`$HOME/w46h/07b-managedlayer-gate-verbose.log`）| **1** | `**测的是旧件**：以下桥副本与权威不同 sha ⇒ 先同步再跑本套件：` ＋ 逐条列出 `6fac9e722299a768 samples/WpfFeatureProbe/…`、`496951adff86a557 samples/ThirdPartyMini/…` |
| 同步**后**（`08-…log:9`）| **0** | `已通过 WpfGfx.Linux.Tests.ManagedLayer.DP1ReproTests.闸门_win32shim被测件与权威件同sha [188 ms]` |

⇒ **成因闭环**：该红的唯一成因就是那两份副本；同步即绿（这条单跑**不是**替代 `verify-all`，只是"先证机制、再花 15 min"）。

### 1.7 `libwpfwin32.so` 5 份复算（应全等 `e700c383ec1ecdc8`）

```
e700c383ec1ecdc8  build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/libwpfwin32.so
e700c383ec1ecdc8  build/MilBridge/tests/CompositeFontProbe/bin/Release/libwpfwin32.so
e700c383ec1ecdc8  build/MilBridge/tests/ContractProbe/bin/Release/libwpfwin32.so
e700c383ec1ecdc8  samples/WpfFeatureProbe/bin/Release/net10.0/libwpfwin32.so
e700c383ec1ecdc8  src/WpfGfx.Linux.Native/bin/libwpfwin32.so          ← 权威
去重后 1 个值 ⇒ e700c383ec1ecdc8      （**5/5 全等**，本趟未动它）
```

---

## 2 新 `verify-all` 的 rc / 通过数 / 失败步名 / 耗时

```bash
bash verify-all.sh > /home/links-dev/w46h/06-verify-all-pre2.log 2>&1      # 不覆盖第一份
```
| 项 | 读数 |
|---|---|
| rc | **1**（`21:32:21` → `21:46:44`，**863 s ≈ 14 min 23 s**）|
| 步骤 | **`步骤通过 24  ❌ 失败 1`** |
| 用例 | `用例通过 871  跳过 2`（`SKIP_GUARD=PASS x_state=available violations=none`）|
| 结论行 | `结论：❌ 失败项：COLUMN-FLOOR` |
| 失败步名 | **只有 `COLUMN-FLOOR`** ✅（= 主控的期望）|
| 失败明细 | `COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline` ／ `COLUMN_FLOOR=FAIL … selfreport=PASS reg=1fa4c4540fe1b69f base=ff3990dafa582831 corpus=0cebc0afd5142fbf` |
| `ManagedLayer.Tests` | **`✅ 通过 76  跳过 0  合计 76`**（第一份日志里是 `❌ (rc=1)`）|
| 前置条件 | 开跑前 `pgrep -a dotnet` = 空（无别人的构建）、`MemAvailable=3148 MB`（≥1500）✅ |

**与第一份日志（`06-verify-all-pre.log`）的逐项对照**

| 步 | pre1（同步前）| pre2（同步后）|
|---|---|---|
| 失败数 | `2` | **`1`** |
| `ManagedLayer.Tests` | ❌ 失败 1/76 | **✅ 76/76** |
| `COLUMN-FLOOR` | ❌ | ❌（不变，设计内）|
| 用例通过 | 795 | **871**（+76 = 那一个套件恢复满跑）|
| 其余 23 步 | 全 ✅ | 全 ✅（逐项口径值未变：`GATE_COLUMN`/`GATE_COLUMN_EXTRA`/`TLINE_GATE`/`PCLINE_START_STEP`/`FRAME_STEP`/`BASELINESHA`/`ARMLOG_SHA`/`BHYGIENE`/`DEFREG declared=90`/`VERIFYALL_SELF gen=#46`/`FP_INPUTS_HYGIENE coverage_n=126`/`HIDDEN_ONLY`/`QUOTE_TRAP`/`PRODUCT_ENTRY`/`PIPEFAIL_SIGPIPE`/`THIRDPARTY`）|

⚠️ 一处**如实记的差异**：`FRAME_PRESENCE` 自报 `magenta_frames=41`（pre1 是 `42`）、`THIRDPARTY frames=42`（pre1 是 `43`）——
这是**时间分辨**采样的正常抖动（两趟各自的 `dir=` 不同：`w34-framepresence-214356` vs `…-212226`），
两趟的判据（`max_colors` / `min_colors` 阈值）都 `PASS`。

---

## 3 冻结要用的两件（**绝对路径 ＋ sha16**）

| 用途 | 绝对路径 | sha16 | 备注 |
|---|---|---|---|
| **冻前 `verify-all` 日志**（用这份！）| `/home/links-dev/w46h/06-verify-all-pre2.log` | **`d17c114b20345183`** | 106 行；`步骤通过 24 ❌ 失败 1`，唯一失败 `COLUMN-FLOOR` |
| （对照，勿用于冻结）| `/home/links-dev/w46h/06-verify-all-pre.log` | `496c48fc6ecdbde4` | 同步**前**那趟，`23/2`；**保留未覆盖** |
| **应用门禁 6 行机读行文件** | `/home/links-dev/w46h/gate-rows.txt` | **`c656913130d4ff2b`** | **已重生成**（`21:46:57`–`21:52:16`），6 行 `^BASELINE `、6 `result=PASS` |

**门禁重生成的方法与读数**（主控要求"若因重跑而变化，也重生成一次并给 sha16"）：

```bash
G=tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh
cp -p $HOME/w46h/gate-rows.txt $HOME/w46h-backup/gate-rows.txt.run1     # 旧行文件归档（sha16 ab14f107c3b46908）
rm -f $HOME/w46h/gate-rows.txt                                          # R13：必须清零，防混入上一趟
WPTD_RUN_DIR=$HOME/w46h/gate-e2 WPTD_BASELINE_OUT=$HOME/w46h/gate-rows.txt timeout 900 bash "$G" 60 --tier both
WPTD_RUN_DIR=$HOME/w46h/gate-f2                                timeout 900 bash "$G" 60 --tier both --no-build
```
| 项 | 读数 |
|---|---|
| 一趟 / 二趟 rc | **0 / 0**（`21:46:57→21:49:37`，`→21:52:16`）|
| `WPTD_SUMMARY`（两趟）| `WPTD_SUMMARY=PASS tiers_passed=2/2` |
| `WPTD_GATE`（两趟）| `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS` |
| 桥陈旧位（两趟）| `WPTD_BRIDGE_SRC_STALE=no basis=pub=f10b4b297b2358e6 now=f10b4b297b2358e6 so_file_match=yes` |
| 新行文件 | **6 行 `^BASELINE `、`6 result=PASS`**；头部 `date=2026-09-19T21:46:57+08:00`、`run_dir=/home/links-dev/w46h/gate-e2`（⇒ 是本次的）|
| 行内 `config=` | 与旧行文件**逐字相同**：`pc:043eff4b1d8ecd7d,bridge:e3ea092010734f44,pf:366e9486536bc291,provider:1f9511a7ef395bfe,win32shim:e700c383ec1ecdc8,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no)` ⇒ **冻结器的"每行含终态 `pc:`/`pf:`"两条断言继续成立** |
| `drawn=`/`colors=` | `default` 档 260／3960，`env` 档 144／2828（与旧行相同）|

⚠️ **两件的时间序**：`verify-all`（`21:32→21:46`）之后才重生成门禁（`21:46:57→21:52:16`）——
两者之间**没有碰任何判定输入**（`inputs_fp` 前后同为 `a47546ec0ed887f8b344a3c8367424cbab55d87eb90dceef5cb6dd3bf3ff0807`，
`pc`/`pf` 未变），所以这个顺序**不产生**"行文件对不上树"的问题。

---

## 4 我用冻结器口径**预先模拟**了断言（逐条为真）

照抄 `$HOME/w21-verify/w27-freeze.py:279-307` 的判据口径，喂**新**日志（脚本未跑，纯静态模拟）：

```
npass/nfail/nstep = 24 1 25 ；ncase/nskip = 871 2
声明类冻前红项 _expected_red = ['COLUMN-FLOOR']            ← 其余两颗声明牙（BASELINE-SHA/ARM-LOG-SHA）本趟是 ✅
green 13 名单里非声明类 10 项全部 ✅（缺绿 = []）
结论行 = 结论：❌ 失败项：COLUMN-FLOOR
断言 `'结论：❌ 失败项' in log and nfail == len(_expected_red)` ⇒ nfail(1) == len(1) ⇒ **True**
断言 nstep == 25 ⇒ True                                          （:257 由日志现算）
断言 `len(re.findall(r'^run_step "', verify-all.sh)) == nstep` ⇒ 25 == 25 ⇒ **True**   （:295-296）
断言 头注释逐字含 `**`#46` 收官起 = 25 步**` ⇒ **True**                              （:298-299）
```
⇒ **`:305` 那个等式、牙齿② 两条断言，本趟都过**（对比：第一份日志的 `nfail(2) != len(1)` 就是当时的拦路石）。
⚠️ 模拟**不含**的项（我没跑脚本，故未验）：`PRE` 快照九行（`GENS['#46']['PRE']` 尚未采）、
`bs_fp`＝冻结当时现算、`allow_changed` 现场 `changed ⊆ allow`、门禁行数/`pc`/`pf` 两条断言（后者已按 §3 目视核对逐行为真）。

---

## 5 有没有新的非声明类红

**没有。** 逐项证据：

1. `verify-all` 唯一的 ❌ 是 `COLUMN-FLOOR`，其失败串逐字含 `COLUMN_FLOOR_ARMLOG=FAIL … selfreport=PASS`
   ⇒ 命中 `w27-freeze.py:279-282` 的**声明类**口径（允许冻前红、冻后必须绿）；
2. 其余 24 步全 ✅（含新恢复的 `ManagedLayer.Tests 76/76`）；
3. 两趟门禁 `rc=0`、6 行 `result=PASS`；
4. 三颗声明/一致性牙现状：`BASELINESHA=BASELINEGEN=PASS`、`ARMLOG_SHA=PASS pass=5`、`REPIN_GENERATION=PASS`；
5. 全副本一致性：`wpfgfx_cor3.so` **4/4 同 sha**、`libwpfwin32.so` **5/5 同 sha**、`BRIDGE-ANCHOR=0`。

⚠️ **新增（但我判定"登记在册、非本趟引入"）**：`check-applocal-sync.sh` 里 `MISMATCH=1` 指向
`tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll 16baacfccfcf1df0`（现权威 `e7a486530c6030eb`），
它**已在册**（工具自报"在册 13 条：仍红 1"，处置列写"重编 `tools/GeometryOracle` 即收敛"），
且**不被 `verify-all` 任何一步读取**。⇒ 我**没有**动它（不在本趟授权范围）。

---

## 6 `NOINFO`

| 项 | 为什么没取到 |
|---|---|
| `verify-all` **第 [1] 步构建**是否真正重编了样本工程 | 本趟**只复制 `.so`**、未重编 `samples/**`；`06-verify-all-pre2.log` 的第 [1] 步只报 `主工程`/`wpf-linux.sln` 两项 ✅。⇒ "样本 bin 里的那两份副本**在下次重编样本时会不会再被刷回旧件**"我**未验**（取决于那两个样本工程怎么拿 `wpfgfx_cor3.so`；我查到 `publish-milbridge.sh:39/54`、`integration-wave.sh` 第 3.6 步、`close-wave.sh:277` 三条链**都不管**它，`samples/ThirdPartyMini/run-thirdparty-mini.sh:124` 甚至是在仓外部署时 `rm -f`）。**建议登记为常设债**（我前一份报告 §8-W1 已点名）。 |
| `FRAME_PRESENCE magenta_frames` / `THIRDPARTY frames` 的趟间抖动成因 | 两趟值 41↔42、42↔43；判据都 `PASS`，我未做归因（时间分辨采样，不在本趟任务书内）|
| 冻后两趟 `verify-all` / `w27-freeze.py` 是否真过 | 派单明确"冻结我来"＋"不许跑 `w27-freeze.py`"⇒ 未跑；§4 只做**静态模拟** |

---

## 7 本趟写盘范围（如实列）

1. **仓内**：`samples/WpfFeatureProbe/bin/Release/net10.0/wpfgfx_cor3.so`、`samples/ThirdPartyMini/bin/Debug/net10.0/wpfgfx_cor3.so`
   （**只这两个 `.so`，`cp -p` 权威件覆盖**，主控本趟授权）＋ 本报告 `build/MilBridge/W46H2-report.md`（新增）。
   **未改**：`verify-all.sh`、`build/MilBridge/known-red.json`、`build/MilBridge/arm-logs/**`、任何 `*.sh`、任何别的源件。
2. **仓外**：`$HOME/w46h/**`（新日志：`06-verify-all-pre2.log`、`08-…log`、`09-gate-e2.log`、`09-gate-f2.log`、`gate-e2/`、`gate-f2/`、`gate-rows.txt` 重生成）、
   `$HOME/w46h-backup/**`（两份 `.so` before 备份、`gate-rows.txt.run1`）。
3. `known-red.json` 本趟 sha16 **未变**：`1fa4c4540fe1b69f`。

---

## 8 本报告的自身 sha16

**自指口径（无行数歧义、可复算）**：正文 = 本文件**从 `## 8 本报告的自身 sha16` 这一行起整段截掉**（含该行前面的分隔线），对剩下部分取 sha256 前 16 位。
```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
python3 - <<'PYEOF'
import hashlib
t=open('build/MilBridge/W46H2-report.md',encoding='utf-8').read()
m='## 8 本报告的自身 sha16'
body=t[:t.rfind(chr(10),0,t.index(m))+1]
print(hashlib.sha256(body.encode()).hexdigest()[:16])
PYEOF
```
⇒ **正文（自指口径）sha16 = `8063b57cd392f6e1`**｜正文 **231 行**／**15,508 字节**（现场算，**已复算等于本值**）。

<!-- W46H2-SELF-SHA-ANCHOR body16=8063b57cd392f6e1 lines=231 bytes=15508 -->

**整份（含本节）全量 sha16**：`sha256sum build/MilBridge/W46H2-report.md | cut -c1-16`（随本节内容而定，不在文内自指；见收尾消息）。
