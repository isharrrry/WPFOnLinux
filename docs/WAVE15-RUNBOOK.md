# 波 `#15` 执行手册（runbook）—— 主控专用，**发波前后照着做**

> ## ✅ **2026-09-15 13:0x 状态：本波已收官（这份手册的"发波"部分已完成，保留作回溯与复用）**
> - **波**：`WAVE_OWNER=主控 bash build/close-wave.sh`，`OUT=$HOME/wfp-runs/close-wave-w15`，**12:53:19 → 12:59:25，序列 `rc=0`**；`verify-all` **9 步 0 失败**；`native_rebuilt=0 / bridge_republished=0`。
> - **九位**：`bridge caf7baf9e67719aa`｜`pc 532c7f54f7573070`｜`pf 06b12fb74fb50c96`｜`wb e6216fe961a2bfb9`｜`provider 9aa0d744802aaa31`｜`win32shim 0098234982391bbf`｜`wic_shim 03b67fbcd7c385b6`｜`hbtextline b5118424dc977aef`｜`dwf b6743030ff1eb907`｜`BRIDGE_SRC_FP=0b7c5a54267064fc`｜`inputs_fp=ac90d784…a74a`。
> - **基线已重冻**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 新 `#15` 表头（文件 `c931c8b03e720890`；`#14` 表头整段保留在文件下半部并标注"已被取代"）。门禁 `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS` + 6 条 `BASELINE … result=PASS`。
> - **§0 先决条件逐条结果**：#1 `D-F1c`①**三条待 T2 波后复取**（本波只达成"单位判据"与"能在有界资源下跑完"）；#2 系统档**只要求无 ×faces 乘法**（地板读数待复取）；#3 不许变的项**波后复取代做**；#4 三个宿主编译 `error CS = 0` ✓；#5 应用路径未中招 ✓；#6 静树 ✓（`loadavg=1.02`，波内记了 `loadavg`/`mem_available`）；#7 渲染侧 `WpfGfx.Linux.dll` **未随波重建**（`0c597fb6ec1eec70`，`error CS = 0`）。
> - **§2 三项"本波特有"检查结果**：① `ARTIFACT-SRC-FP` **两极化 ✅**（正极性：FP 里 shim 行 == 现树 `b5118424dc977aef`；负极性：除该行外其余 `file=` 行与波前存档逐位不变）—— 仪器 `build/check-fp-polarity.sh`（本波新写，**19 用例红证已做**，含"不给存档时静默只做正极性"这一**已知沉默降级**）；② 新鲜度三位：`BRIDGE_SRC_STALE=no`、`hbtextline_shim_stale=no(basis=auth)`、`WFP_SRC_STALE` 由波内输入稳定性位覆盖（`inputs_fp` 波前==波后）；③ app-local 刷新覆盖 `HelloWpf` Release 那个 refdir ✓（波内 `step 3.6` 刷了 **36 份**副本），**但 `APPSYNC` 仍判 `MISMATCH`** —— **唯一原因 = 1 处未声明的传递依赖副本**（`build/DirectWrite.Linux/FallbackCriteria/bin/Debug/WpfGfx.Linux.dll`，内容 == 权威 `0c597fb6ec1eec70`）⇒ 新登记 **`D-A1`**（**不是陈旧件、也不许当绿**）。
> - **⚠️ 发波过程中新发现两件（都已入档）**：① **门禁第一趟 `default rep=1` 假红** —— runner 自起 `Xvfb` 的**就绪竞态**（应用自报 `XOpenDisplay(":97") 失败` ⇒ `exit=134`），同配置其余 5 趟全 PASS ⇒ **装置竞态**；处置 = 起**常驻** `:97`（第二趟 6/6 PASS）；**教训写成纪律 30**（`docs/CURRENT-STATE.md`）。② **门禁首次以"五臂"运行 ⇒ 立刻抓出 `tab-anchor`（436 例，有史以来第一次真实运行）132 结构败** + `tab-zero` 老红 1 条 ⇒ `TLINE_GATE=FAIL … unregistered=179`（3 条在册红形状全对、`drift=0 gone=0`）⇒ **179 条裁定与登记是 `verify-all` 第 10 步的前置**。**这两件都不属于原手册的检查项 —— 手册的价值恰好在于"它没拦住这两件"这件事本身值得记下来。**

> 写于 **2026-09-15 12:3x**。判据口径与"红则停"条件在 `docs/WAVE15-PREREGISTRATION.md`（那份是**预登记**，这份是**操作步骤**）。
> 一句话状态：`#15` 的内容 = **`D-F1c`（回退路径的内存）+ `D-F1b`（回退 run 的面身份）**。`D-F1b` **已达成**；`D-F1c` 的内存半边**未达成**，真因已拆成**两条独立来源**（① Skia 逐面整文件映射〔修法已由 B1/B2 证实〕② PC 侧族查找/集合枚举逐次建映射）⇒ **两条都落并且读数进判据，才发波**。

## 0. 发波的先决条件（**全绿才发**；任一条不绿 ⇒ 不发、先修）

| # | 条件 | 判据（读数形态） |
|---|---|---|
| 1 | `D-F1c` 内存进判据 | 1CJK 档（`WPF_LINUX_FONT_DIR=$HOME/wfp-runs/fontdir-1`、`--mode=null --para=b34`）**权威峰值 ≤300 MB**（硬线 1 GB），且该 `.ttc` **映射段数 12 → 1–2**、**Σ虚拟 ≈ 19–37 MB**（**主判据是段数/Σ虚拟，RSS 只作旁证**） |
| 2 | **系统档：只要求"无 ×faces 乘法"** | 系统 371 面同命令 ⇒ **字体段数 117 → ≈被加载文件数**（**不要求 ≤300 MB** —— 那条被 `D-F3`（集合全量预载）的架构地板挡住，见预登记 ⑧）；报告须给**地板读数与致因**（`shared_clean`/`priv_dirty`/`anon` + 被加载文件数 + Σ这些文件大小） |
| 3 | 不许变的都不许变 | `candidates`（10/45/371）、`Scans=1`、**面选择普查逐格相同**、`LINE_W=16.0000`/`CR_W=3.3440`/`GID=9498`/`ADV_DIP=16.0000`、`CRITERIA=PASS`（`C1` 两条路 + `C2/C3` + `TOOTH-D-F1b-ABSENT`） |
| 4 | 三个宿主编译 | `CoverageProbe` / `TextLineProto` / `HbTextLineParity` 用 `-p:HbShimSrc=…` ⇒ **`grep -c 'error CS'` = 0** |
| 5 | 应用路径不中招 | `Rendering.Tests`/`Windowing.Tests` 的 golden **零变化** |
| 6 | 静树 | `pgrep` 无其它读数/构建在跑；记 `loadavg` + `free -m` |
| 7 | **渲染侧重建（本波新增）** | `dotnet build src/WpfGfx.Linux/WpfGfx.Linux.csproj` ⇒ **`error CS` = 0**；记 **`src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll` 的 sha16**（**注意 TFM 子目录**；今天 `b280168cef9689d0`）并写进 `#15` 表头（扩展可见位）；`Rendering.Tests` + golden **零变化** |

## 1. 发波（一条命令）

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"
WAVE_OWNER=主控 bash build/close-wave.sh          # 自动判定该重建什么（#15 必然要重建 PC：shim 编在 PC 里）
# 若汇总里 BRIDGE_SRC_STALE=yes ⇒ 追加 --bridge 重发桥；native 未动则不必 --native
```
- 波会写 `/tmp/bridge-frozen.flag` **与 `$HOME/wfp-runs/bridge-frozen.flag`**（我加的镜像；写失败它会明说"不要当成功"）。
- 波内 **`step 2.5/3.5/3.6`** 三道自动检查 + **`verify-all`（本波起仍是 9 步）**；任一步 rc≠0 ⇒ **停**。

## 2. 波内的三项"本波特有"检查（缺一不算过）

1. **`ARTIFACT-SRC-FP` 两极化（免费获得）**：shim 必变 ⇒ `build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt` 里
   - **正极性**：`file=<新 sha16>  build/shims/PresentationCore.HbTextLine.cs` 那一行**必须变**；
   - **负极性**：**其余 `file=` 行与 `peer=`/`fp=`/`n=` 段逐位不变**（除环成员 `pf`/`reach` 的 `peer` 位）。
   - 做法：波前存一份 FP 文件到 `$HOME`，波后 `diff` 只看该行是否变、其余是否为空 diff。
2. **新鲜度三位**：`hbtextline_shim_stale=no`（对权威 PC 比）、`BRIDGE_SRC_STALE=no`、`WFP_SRC_STALE=no`；**答不出来要报"无信息"，不许报绿**。
3. **app-local 刷新覆盖到 `HelloWpf` Release 那个 refdir**（今天刚关掉的 `APPSYNC` 红就出在这里）：波后跑
   ```bash
   timeout 300 bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | tail -3
   ```
   ⇒ 期望 **`APPSYNC=PASS`**（`MISMATCH/MISSING/DIVERGENT/UNEXPECTED` 全 0）。**若某目录是 `-c Release` 构建产物，它的 `Provider.dll` 会与权威不同 ⇒ 按全仓模型把权威 Debug 副本同步进去**。

## 3. 冻基线（波后，两步）

```bash
WPTD_RUN_DIR=$HOME/wfp-runs/mygate15 WPTD_BASELINE_OUT=$HOME/wfp-runs/mygate15/baseline.md \
  bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 90 --tier both   # 期望 WPTD_GATE=PASS（两档 3/3）
```
- 门禁 **`WPTD_GATE=PASS`** + 6 条 `BASELINE … result=PASS` + `WPTD_LINE_ADVANCE=PASS` ⇒ 才把九位写进 **`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（新 `#15` 表头）**；
- 表头必须逐字取自那趟 `WPTD_ARTIFACTS`，并记 `inputs_fp`、`loadavg`、`mem_available`、`run_dir`；**表头里要写清本波"改了什么 + 哪条判据成立 + 哪条仍不成立"**（照 `#14` 表头的体例）。

## 4. 波后的收尾清单（**每件都要留 sha**）

1. **`docs/CURRENT-STATE.md`**：§1 九位 → `#15`；§4 里 `D-F1c`（内存）改成"已达成 + 判据读数"或如实保留；`D-F1b`/`D-F2` 状态句更新；"在飞"块清空。
2. **`handoff.md`**：把"`#15` 阶段一（窗口 1–N）"那段补成**完整波记录**（件链 + 各窗读数 + 判据 + 未做项 + 自我更正）。
3. **`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（T3 写）**：`L25`（判据层空集当通过，附 T2 两支正控原文 + 判据层 sha）、`L26`（判据存在但没人跑）、`L27`（门禁绿 ≠ 没自旋/没爆内存；`rc=124/143` 记无信息）、`L28`（门禁绿 ≠ 默认配置下没问题）、`D-F1` 状态句、`D-F1b`、`D-F1c`（**不许写成"已修"**，按当时读数）、`D-F2`。
4. **T1b3 的门禁**：用**新世代的完整 `tline` 读数**按它报告 §7 三步 + **第 0 步门禁**（缺结论行 / `rc>128` ⇒ 不许钉）重钉 `known-red.json` 的 `generation` ⇒ `--logdir` 自检 `PASS` 且 `gone/drift==0` ⇒ **再由我**接成 `verify-all` **第 10 步**（届时 `verify-all` 从 9 步变 10 步，表头要记"步数与口径已变"）。
5. **T3 的有界 `run.sh tline`**（若内存已进判据）：`timeout 1200` + 5 s RSS 采样 + **超 2 GB 按 PID 止损**；跑完交 `rc`/六项/`+CJK` 集合与计数/产物 sha ⇒ **34 条 `+CJK` 对比**交给 T2 收口。**`rc=124/143` 记无信息、不重试**。
6. **`D-R2` 计数**：本波 `verify-all` 是第 N 趟干净（关闭判据 = 连续 5 趟）。
7. **下一波预告**（写进 `#15` 表头）：`#16` = `D-T2`（Tab 缩进，shim + PC 半）+ `D-O1`（`HasOverflowed`，**会打开折叠路径**）；`#17` = 产物侧 shim sha（改 `pc` 并经环传播动 `pf`/`reach`）。

## 5. 回滚（任一步踩空时）

- **shim**：`~/t1d-backups/` 里每一步都有整份副本（文件名带 `sha16`），`cp` 回去后**必须** `cmp`/`sha256sum` 自证 + **强制重编**（`touch` 源或清 `obj`）—— 纪律 24：`cp -p` 保留旧 mtime 会让增量构建跳过重编，读出"假红/假绿"。
- **`src/WpfGfx.Linux/**`（M7b）**：按其报告里的备份/还原协议；**pc/pf/bridge 三者任一变了 ⇒ 波作废、重跑波**。
- 波中若 `verify-all` 失败：**不要**改判据让它变绿；先把 rc 与失败项原文留档（`~/wfp-runs/close-wave-*/`），再决定回滚哪一件。

## 6. 这份手册自己的口径

- 凡引用"某读数 = 某值"，必须连 **件 sha + 仪器 sha + 判据口径 + artifact/字段** 一起写（纪律 15/18/26）。
- **主判据是"段数 / Σ虚拟"**（`D-F1c` 内存），**RSS 只是旁证**；理由：`mmap` 后未被触碰的页不计 RSS（实测 B1：RSS 13 MB vs 虚拟 191 MB）。
- 本手册若与 `docs/WAVE15-PREREGISTRATION.md` 冲突 ⇒ **以预登记为准**，并当场改本手册。
