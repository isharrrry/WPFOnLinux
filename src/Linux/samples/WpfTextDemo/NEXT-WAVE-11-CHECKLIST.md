# **#11 验收清单（预备稿，未执行）** — T1d 的 `D-T1`（Tab 的 Wrap 断行钳位语义）

**锚 = `#10`**（现行冻结件）：`bridge 759a322431f1e457` ｜ `pc 628e741681ecb048` ｜ `pf 967c79c18dbfaac2` ｜
`wb e6216fe961a2bfb9` ｜ `provider 71ba86c6495347fe` ｜ `win32shim 0098234982391bbf` ｜ `wic 03b67fbcd7c385b6` ｜
`hbtextline 7c2e0107a9c86180(stale=no)` ｜ `dwf 2f77dbdf5e7e2cd5` ｜ fp `705ed5ccd0c498a1`。
**状态：只读预备** —— 本文件只写命令与判据；**等主控一声令下再跑**（不跑构建、不跑应用、不开波、不冻基线）。

## 0｜读数纪律（先写死，避免事后找补）

### 0.1 位对照表（本波预期）
| 位 | 预期 | 依据 / 处置 |
|---|---|---|
| `pc` | **会变** | 本波在 PC 里（`hbtextline` 源编进 PC）⇒ 必变，**不改判据** |
| `hbtextline`（源） | **会变** | T1d 落 `D-T1` 改的就是这个源 |
| `hbtextline_shim_stale` | **必须 `no`** | 变 `yes` ⇒ 源比权威 PC 新 ⇒ **说明 PC 没重编** ⇒ 该趟读数作废（先找主控，不自行重编） |
| `pf` | 会变（**环成员，每波必变，属预期**） | 不因它变化而怀疑回归 |
| `bridge` | **不该变** | 本波不动桥源码；变了 ⇒ 有人重发了桥 ⇒ 先问 |
| `win32shim` | **不该变** | 本波是托管 shim 口径，不涉 native；变了 ⇒ 先问 |
| `windowsbase` / `provider` / `wic_shim` / `dwf` | 不该变 | 同上 |
| `bridge` fp | 必须 **== 现树** | 由 `WPTD_BRIDGE_SRC_STALE` 位给（`yes` ⇒ 本趟读数作废） |
| `WPTD_ARTIFACTS_EXT`（可见位） | 允许变 | 按口径：**不自动作废基线，但必须在 #11 表头登记** |

### 0.2 三条铁律
1. **不许跨波比绝对值**：#10 → #11 之间 `pc`/`hbtextline`/`pf` 都变 ⇒ 只比"判据是否仍全绿"，不比 sha、不比像素绝对值（门禁读数**应当逐值相同**，若不同按"先给原文、再定性"处理）。
2. **每条数字带口径名**（`记账结构全等` / `宽度分桶` / `Extent 行级` / `Extent 余差清单` / `折叠明细` / `行度量` / `T2b` / `T2c`）—— 上一轮的教训：同一个 ❌ 行里粘着两个不同桶。
3. **clamp/断行判据一律用 U1 的默认配置 oracle（`tab` 57 可判 + `tab-zero` 86 结构），不用 `layout-b34`**（口径由 T1d 档 §10.1 写死）。

## 1｜官方门禁（第一件，先跑）
```bash
D="$HOME/wfp-runs/go-freeze11"; L="$HOME/wfp-runs/go-freeze11.stdout.log"; mkdir -p "$D"; rm -f "$L" "$D/baseline.md"
WPTD_RUN_DIR="$D" WPTD_BASELINE_OUT="$D/baseline.md" \
  bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 90 --tier both 2>&1 | tee "$L"
```
**判据（全部逐字抄进 #11 表头）**：`WPTD_GATE=PASS acceptance=2/2`｜`WPTD_TIER_SUMMARY=default passed=3/3`｜`=env passed=3/3`｜
`inconclusive=0`｜`WPTD_SUMMARY=PASS tiers_passed=2/2`｜`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 threshold=10 runs=167`｜
**`runner exit=0`**｜6 条 `BASELINE … result=PASS`｜`leftover_after=0`×6｜`REAPED_ORPHANS total=0`｜
`WPTD_BRIDGE_SRC_STALE=no`（basis 两值相等、`so_file_match=yes`）｜桥契约 `ok(0 且无条款表)`｜判据⑥ `after=第二趟最佳` + `AE=141605`。
**附加**：`WPTD_ARTIFACTS` 九位**逐字**进表头；`WPTD_ARTIFACTS_EXT` 变化按口径登记。
⚠️ 日志放在 `$OUT` **之外**（L13）；一次只跑一个应用；`:97`。

## 2｜`tline` 六项 + 三份明细条数（第二件）
```bash
export PATH="$HOME/.dotnet:$PATH"
bash build/MilBridge/run.sh tline 2>&1 | tee "$HOME/wfp-runs/tline-wave24.log"
```
**判据（带口径名；括号内 = #10 基准，**除 `D-T1` 射程外应逐项不变**）**：
| 口径 | 期望 |
|---|---|
| 记账结构全等 | **`1286/1298`（不等 12；子桶 ①286/286 ②68/68 ③984/988）** |
| 宽度分桶 | **`0=167 / ≤0.34DIP=1084 / >0.34DIP=47`（三桶和==1298 机检 OK）** |
| Extent 行级 | **`1260/1298`** |
| Extent 余差清单 | **`58` 条（主对拍 38 + LH 组 20）** |
| 折叠明细 | **`218/236`**（判定一致 `1298/1298`） |
| 行度量 | **Height `1298/1298`、Baseline `1298/1298`、Extent `1260/1298`** |
| `T2b` A 组 | **行级 `972/972`；用例级 `213/213`** |
| `T2c` Tab | **34 可比例，不一致 `0`** |
| 结论 | **`通过 20 / 失败 2`**（两红仍是已登记未实现项）｜不一致用例 **`17`** |

**三份明细条数（T1b 的"不得因本波而变"不变式）**：折叠 **`18`** / Extent **`58`** / 记账 **`17`**。
复算入口（T1b 给的）：`build/MilBridge/T1b-family-ledger.md`；落地后**逐项对照**，任一条**变了** ⇒ 立刻把原文给主控、**不自行放宽**。

## 3｜★ `D-T1` 本体：`tab-zero` 臂 **射程内 12（结构败 13 → 1）**（第三件，本波的关键判据）
```bash
# 复现入口（T1d 档 §10.1 现成，只读）
bash -lc 'cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux && \
  dotnet build build/MilBridge/tests/CoverageProbe -c Release -p:HbShimSrc="$PWD/build/shims/PresentationCore.HbTextLine.cs" -v q --nologo && \
  dotnet build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.Tests.dll \
    --tab-lines-oracle tests/parity/windows/tab-zero/out/tab-zero-oracle.json'
```
**判据**：
- **目标**：`tab-zero`(86) **结构败 13 → 1**，即**射程内 12 例 ⇒ 0**（落前实测 **13/86**，其中 **12 例 = `b34-tabs` w40/w80/w160@em24 与 `tab-only` w40/w80/w160@em24 的 LTR+RTL 各 3**；**LTR 6 例也错 ⇒ 方向无关**）。
- **第 13 例**（`notab-control@w40@em24@RTL@tab0` 的 `tws`）**不在 `D-T1` 射程内**（归 §9.4(C)）⇒ 允许仍为 1，**但必须在报告里点名**，不许当成"12 ⇒ 0"的一部分含糊过去。
- **顺带**：`tab` 臂（U1 默认配置）**57 可判**应保持一致；`tab-anchor`（U1 新臂 **436 例**）与 `tab-rtl`（84）**按主控口径决定是否本轮就判**（新臂首跑若报差异，先给原文）。
- **牙（第二方向，必做）**：把"行中越界不钳"改回去（`IsLineStartTab` 恒 `true`）⇒ **12 例必须复现**（预期 `tab-zero` 结构败由 **1 回到 13/86**）。**牙不成立 ⇒ 这个判据是假的**（本项目老病）。
  ⚠️ 牙要改 T1d 的源 ⇒ **只在主控批准并明确"谁改、改哪一行、谁还原"之后做**；我这轮**只写、不做**。

### 3.1 🚨 收货闸门（主控 2026-09-14 口径）
- **若 T1d 报"结构败 `0/86`" ⇒ 先不收货，回来找主控** —— 那意味着**射程被偷偷扩大**或**判据被动过**。
  正确读数 = **结构败 `13 → 1`**、**射程内 12 例 ⇒ 0**、**第 13 例 `notab-control@w40@em24@RTL@tab0` 的 `tws` 点名保留**（仍红属**已知**，归 §9.4(C)）。
- 判据口径基线（同步给 T1d 的同一套）：`tab-zero`(86) 结构败基线 = **13**；牙的预期读数 = **回到 `13/86`**。

### 3.2 牙的归属与我的核对（`build/shims/**` 单写者 = **T1d**）
- **改由 T1d 改、由 T1d 还原**（它手上有 `/tmp` 整份备份与 sha）；**我只跑读数**，
  **绝不自己动 `build/shims/PresentationCore.HbTextLine.cs`**。
- **我要核对的**：**改前 / 牙中（`IsLineStartTab` 恒 `true` 时）/ 还原后** 三次 `hbtextline` **源 sha**，
  并确认 **还原后的 sha == `D-T1` 定稿那一版**（该 sha 由 T1d 报给我；我另与 `WPTD_ARTIFACTS` 的
  `hbtextline_shim_sha` 和 `hbtextline_shim_stale=no` 交叉核对）。
- 任一次对不上 ⇒ **停止判读、把三个 sha 原文给主控**（这正是"仪器必须先证明自己"那条）。

## 4｜RTL 三条 / `text-dp-min` / `textbox-edit` / 全块矩阵（第四件，按时间与负载）
```bash
# RTL 三条（判据：Δright=1、Δw=0、比 0.97；镜像 k=71、mean|Δ|=0.736 vs 正序 1.958；块区 AE=0；census 50/50 报「无」）
WFP_RUN_DIR=$HOME/wfp-runs/go-rtl-wave24 bash tests/…/run-wpfprobe.sh 90 --only=text-rtl-pure,text-rtl \
  --app-env=WPF_LINUX_GLYPH_CENSUS=1,WPF_LINUX_DRAW_CENSUS=1,WPF_LINUX_VISTRANS_TRACE=1
# text-dp-min（判据：t2='A' c2=1 sel='A' line0='A'；KEY_DIAG=0、push=0）
WFP_RUN_DIR=$HOME/wfp-runs/go-dpmin-wave24 bash tests/…/run-wpfprobe.sh 90 --only=text-dp-min
# textbox-edit（判据：DP1_LEG state=closed rc=0 且 first_inject 有值；Ctrl 生效 ⇒ 替换语义 len=1 'A'；PERLINE 全 eop=1）
WFP_RUN_DIR=$HOME/wfp-runs/go-textbox-wave24 bash tests/…/run-wpfprobe.sh 90 --only=textbox-edit \
  --app-env=WFP_POSTWRITE=1,WPF_LINUX_TEXTLINE_PERLINE=1,WPF_LINUX_INPUT_TRACE=1,WPF_LINUX_MSGFLOW_TRACE=1,WPF_LINUX_KEY_DIAG=1
python3 build/MilBridge/tools/t1c-dp1-leg-audit.py --log <该趟 probe-only.log>
# 全块矩阵（判据：registry=ok(count=11)、端到端 11==11；预期 ok=8 fail=3，
#   三个 FAIL 必须**先帧穷举**（两色 0/18 帧、#F97316 18/18 帧）**再**放最上面重跑证伪 —— L20）
WFP_RUN_DIR=$HOME/wfp-runs/go-matrix11 bash tests/…/run-wpfprobe.sh 120
```
（所有 `$OUT` 之外另存 stdout/stderr；每趟一次一个应用；`:97`；跑完核对 `leftover_after=0`。）

## 5｜`1400` 计数（**两个口径不混用**，沿用 #6–#10 门禁口径链）
- **门禁口径**：`#10`=**150** → **本趟 +6 ⇒ 156**。
- **每次应用启动口径**：`#10` 后累计 **163** → 本波再 +（门禁 6 + 探针 N 次）。
- **两口径都必须 0 次发生**；逐趟 grep `Win32Exception (1400)` / `CreateWindowEx.*1400`。

## 6｜#11 表头要写的四要素（照 #10 的样式）
① 本波内容 = **`D-T1` 落地**（`tab-zero`(86) **结构败 13 → 1**，即**射程内 12 例 ⇒ 0**；规则引用 §3.6/§10.1；**第 13 例 `notab-control@w40@em24@RTL@tab0` 的 `tws` 不在射程内、点名保留**）；
② `1400`（双口径）；
③ `BRIDGE_SRC_STALE` 位（逐字）；
④ **位变化说明**：`pc`/`hbtextline` 变（+`pf` 环成员）；`bridge`/`win32shim` 未变（若变了要能解释）；
⑤（新增）**`WPTD_ARTIFACTS_EXT` 变化登记**；
⑥（新增）**`APPSYNC` 那条要写成「仪器首次抓到 · 既存 · 非本波引入」**（见下）。

### 6.1 `APPSYNC` 必写的那句（主控裁定，2026-09-14）
- **仪器**：`build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh`（由 `build/close-wave.sh:152-153` 调用；
  该处原文自己就写着"**不必然是本次引入**，但**别让探针测旧件**"）。
- **被它抓到的既存缺口（我已只读核对）**：`samples/HelloWpf/bin/Release/net10.0/DirectWrite.Linux.Provider.dll`
  **MISSING**（实读：该路径**不存在**；同目录其它 DLL 在位、mtime 多为 9月10 ⇒ **老 Release bin**）。
- **#11 表头写法（不许写成 #11 的回归）**：
  「`APPSYNC` 非 PASS = **仪器首次抓到 · 既存 · 非本波引入**（`samples/HelloWpf/bin/Release/net10.0/DirectWrite.Linux.Provider.dll` 缺失）；
  主控已裁定**走修不走改口径**，排在 **#11 之后单独做**。」
- **对判读的影响**：`check-applocal-sync` 只覆盖样例 Release bin 的件同步，**不进入** `WPTD_ARTIFACTS` 九位；
  ⇒ #11 的判据链**不因它变化**，但**必须在表头如实登记**（否则下一个人会把它当成 #11 的回归）。

## 7｜#11 表头文案（**主控已批准，照抄**）
```
#   【⚠️ Tab 的覆盖面（并排说明，勿读成「Tab 全部正确」）】
#     · 本语料（`layout-b34`，`DefaultIncrementalTab=0`）上 **`T2c` 不一致 0**（**仅覆盖该套配置**）；
#     · **默认配置 + `Wrap`** 路径：**`D-T1` 已修（#11 本波）** —— `tab-zero`(86) 结构败 **13 → 1**，
#       其中**射程内 12 例 ⇒ 0**（`b34-tabs` w40/w80/w160@em24 与 `tab-only` w40/w80/w160@em24 的 LTR+RTL 各 3；**LTR 6 例也错 ⇒ 方向无关**）；
#       **第 13 例 `notab-control@w40@em24@RTL@tab0` 的 `tws` 不在 `D-T1` 射程内**（归 §9.4(C)）⇒ 仍红属**已知**；
#       规则见 `build/MilBridge/T1d-tab-and-modifier.md` §3.6/§10.1；真值来源 = U1 的 **`tab-anchor` arm（436 例，已交付）**。
#     · **`Tabs` 显式停靠位仍未实现**（如实登记）。
```
（口径变更记录：原写"12 例结构败" ⇒ **改为"射程内 12（结构败 13 → 1）"**，因为落前实测是 13/86、第 13 例不在射程内。）
