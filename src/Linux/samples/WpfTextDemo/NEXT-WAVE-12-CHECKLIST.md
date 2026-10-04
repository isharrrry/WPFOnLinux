# **#12 验收清单（预备稿，未执行）** — 波 `close-wave-203111`

> **通用流程仍照 `NEXT-WAVE-11-CHECKLIST.md`**（门禁 / `tline` / oracle / RTL / DP / textbox / 矩阵 / 1400 / 边界纪律）。
> 本文件只记 **#12 特有的差异**；**等主控说"门禁绿"再跑**。当前官方门禁正在 `:97` 上重跑（我这边**不碰 `:97`**）。

## 0｜件与哨兵（已核对）
哨兵 `/tmp/bridge-frozen.flag`（重启后由主控据 `close-wave-203111/close-wave-summary.txt` 重建）：
`BASELINE=12(未冻)`｜`PC=293f99525f5af4f2`｜`PF=11791727d682e119`｜`HBTL=3081d088cda0431c`｜
`WB=e6216fe961a2bfb9`｜`WIN32SHIM=0098234982391bbf`｜`WIC=03b67fbcd7c385b6`｜`PROVIDER=71ba86c6495347fe`｜
`DWF=2f77dbdf5e7e2cd5`｜`SHA=759a322431f1e457`｜`FP=705ed5ccd0c498a1`｜`WAVE=close-wave-203111`。
**我独立实读**：`pc`/`pf`/`hbtextline` **三位与哨兵逐位相符** ✓；`bridge`/`win32shim`/`wb`/`provider`/`wic`/`dwf` **未变** ✓。

| 位 | 预期 | 说明 |
|---|---|---|
| `pc 293f99525f5af4f2` | **变** | 本波内容（`IsTrailingWhitespace` 排除 `U+00A0`） |
| `hbtextline 3081d088cda0431c` | **变** | 同上（机制一） |
| `pf 11791727d682e119` | 变（环成员，预期） | — |
| `bridge` / `win32shim` | **不该变** | 变了先问（`native_rebuilt=0`、`bridge_republished=0` 已由主控报） |
| `wb`/`provider`/`wic`/`dwf` | 不该变 | — |
| `hbtextline_shim_stale` | **必须 `no`** | `yes` ⇒ 源比权威 PC 新 ⇒ 先找主控（#11 那次是"mtime 假警报"，处置见 #11 报告） |

**环境（事故后）**：机器 **21:5x 重启**（`up` 仅数分钟、`/tmp` 被清空）⇒ 第一趟门禁 `exit=134`(SIGABRT)+0 字节产物**判为环境事故、非缺陷**。
⇒ 我这轮读数的前置：**记录 `uptime`/`loadavg`**；若出现异常，先看是否"静树"（`verify-all`/其他车道是否在跑）。

## 1｜`tline` 六项 —— **本波预期变化点（与 #11 比）**
| 口径名 | #12 期望 | #11 实测 | 说明 |
|---|---|---|---|
| 记账结构全等 | **`1292/1298`（不等 6）** | 1286/1298（不等 12） | **变好**：本波机制一所致 |
| 宽度分桶 | **`168 / 1089 / 41`** | 167/1084/47 | `>0.34DIP` **由 47 → 41** |
| Extent 行级 | **`1260/1298`** | 同 | **不动** |
| `T2b` A 组 | **`972/972、213/213`** | 同 | **不动** |
| `T2c` Tab | **不一致 `0`**（34 可比例） | 同 | **不动** |
| Extent 余差清单 | `58（38+20）` | 同 | 不变式 |
| **折叠 / `T3` 明细 / `T3b` / 通过数** | **不与 #11 直接比绝对值** | — | **仪器版本变了**（T1b2 对照表已结清）；且本版含 5/1 条**假红**（见 §1.2） |

### 1.1 纪律 18：**仪器 sha 与件 sha 一起记**（⚠️ 同名不同件，**必须写全路径**）
主控 2026-09-14 澄清：仓里有**两个都叫 `Program.cs` 的仪器**，用途不同 —— 我上一版只写了一个，**是"同名件"坑**（与 `CycleStub` 5120 B 桩那次同族；本仓纪律 4）：

| 仪器（**全路径**） | sha16 | 用途 |
|---|---|---|
| `build/MilBridge/tests/**HbTextLineParity**/Program.cs` | **`0d45032b20cfbfee`** = 主控报的、= **#12 表头读数用的那一版**；**现已是 `6e077361609f02ad`**（20:34:47 起，判别式版，**#13 用**） | `bash build/MilBridge/run.sh tline` |
| `build/MilBridge/tests/**CoverageProbe**/Program.cs` | **`cc61299d6dc72277`**（= 我实读，mtime 20:24:57） | `--tab-lines-oracle` / `--known-red` |

⇒ 本轮读数**两个 sha 都记**：`tline` 那套属 `HbTextLineParity`（**本波读数对应 `0d45032b…`**；`6e077361…` 是 #13 的），oracle 那套属 `CoverageProbe`（`cc61299d…`）。

### 1.2 本版 `tline` 里的**已知假红**（主控 2026-09-14 口径）
本版读数中 **`折叠 23` 与 `记账用例 18` 里含 5/1 条假红** —— 根因是**裸断言 `cr.Width>=0` 过宽**（**真机自己 430 条里就有 7 条负宽度**）。
判别式 **`ours<0 ⇒ truth<0`** 已落进 `HbTextLineParity/Program.cs = 6e077361609f02ad`，**属 #13** ⇒ **本轮不要把这些条数当缺陷**，也不与 #11 直接比。

## 2｜★ `--known-red` 已落地 —— **调用必须带表**（否则假红）
- 表：`build/MilBridge/tests/CoverageProbe/known-red.txt`（实读 579 B，1 条已登记：
  `notab-control@w40@em24@RTL@tab0::尾部空白` —— **正是 `D-T1` 点名保留的第 13 例**）。
- 语义（`Program.cs` 原文）：**未给表 ⇒ 任何失败都算未登记 ⇒ `rc=1`**（旧行为是恒 `rc=0`，**已改**）；
  已登记的失败只点名 `KNOWN-RED`、**不改退出码**；表文件不存在 ⇒ 视作空表。
- **本清单的调用（更新版，逐字）**：
```bash
export PATH="$HOME/.dotnet:$PATH"
dotnet build build/MilBridge/tests/CoverageProbe -c Release -p:HbShimSrc="$PWD/build/shims/PresentationCore.HbTextLine.cs" -v q --nologo
dotnet build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.Tests.dll \
  --tab-lines-oracle tests/parity/windows/tab-zero/out/tab-zero-oracle.json \
  --known-red build/MilBridge/tests/CoverageProbe/known-red.txt
# 判据（不看退出码也要看）：TAB_LINES 合计 … 结构败=N  +  该次 rc 与 KNOWN-RED 行
```
- **喂错臂的 JSON 现在报 `rc=2` + 形状不符 + 指路 `--tab-oracle`（不再 core dump）** ⇒ 若看到 `rc=2` 是**我用错档**，不是产物问题（#11 我踩过一次，已记）。

## 3｜★ `D-T1` 的判据（本波**不该**动）—— 变了立刻报
`tab-zero`(86) 结构败 **`13 → 1`**（**射程内 12 ⇒ 0**、**第 13 例 `notab-control@w40@em24@RTL@tab0` 点名保留**）；
`判定过 = 85`、`Q3 clamp 28/28`；默认档 `--tab-oracle` = `cases=114 pass=57 fail=0`（最大逐字差 `0.0053`）。
**`0/86` ⇒ 先不收货、回报主控**（射程被扩大或判据被动过）。

## 4｜其余各件的判据（与 #11 相同，逐条照旧）
- **门禁**：`WPTD_GATE=PASS`、两档 3/3、`runner exit=0`、6 条 `result=PASS`、`leftover_after=0`×6、`BRIDGE_SRC_STALE=no`、桥契约 `ok(0 且无条款表)`、判据⑤ 与 判据⑥ 原文；
- **RTL 三条**：`Δright=1 / Δw=0 / 0.97`；镜像 `k=71`、`0.736` vs 正序 `1.958`；块区 `AE=0`；census `50/50 报「无」`；
- **`text-dp-min`**：`t2='A' c2=1 sel='A' line0='A'`（零注入）；
- **`textbox-edit`**：`DP1_LEG state=closed rc=0`（`first_inject` 有值）＋Ctrl 生效 ⇒ 替换语义＋`PERLINE` 全 `eop=1`；
- **全块矩阵**：`registry=ok(count=11)`、端到端 `11==11`；FAIL 先**帧穷举**再**放最上面重跑**（L20）；
- **`1400`**：门禁口径 `#11`=**156** → 本趟 **+6 ⇒ 162**；每次启动口径 `#11` 后 **174** → 再加（门禁 6 + 探针 N）。**两口径都须 0 次**；
- **`APPSYNC` 既存红**（`HelloWpf` Release 缺件）照 #11 措辞写：**仪器首次抓到 · 既存 · 非本波引入**；
- **`D-R2`**（testhost 间歇崩溃）本波绿，但**读数只在静树上取**。

## 4.5｜牙（主控 2026-09-14 裁定：**本波不做**）
T1d 的 `before` 侧本身就是"NBSP 算回行尾空白"的**复现**，已起牙的作用 ⇒ **本轮不加牙**。
若我要额外做，**必须先报主控**，且**牙中 sha 要在动手前报出**（#11 那次的口径教训）。

## 5｜边界
`:97` 现在被**主控的门禁重跑**占着（`run-wpftextdemo.sh` PID 3288 + `Xvfb :97` PID 3297）⇒ 我**不碰**；等我自己的趟时**一次一个应用**、日志放 `$OUT` 之外；**不动任何源**、**不开波**、**不冻基线**（#12 表头归主控）。
