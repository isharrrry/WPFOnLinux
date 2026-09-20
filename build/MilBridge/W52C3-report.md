# W52C3 报告 —— `#49` §10.5 裁定落地：`C1e`（`applocal-expect.py` 的 `PROPS` 必须跟随声明）

> **一句话**：`PROPS["WpfLinuxSelfBuiltConfiguration"]` 已从**字面量 `Debug`** 改为**跟随声明**（`CFG`）；
> 判据 1 的四格成对读数证明这是「跟随声明」而**不是「换个 Release 字面量」**（声明=Debug 时新件与旧件**逐字相同**）；
> 真实树 `#REFDIR` **14 → 23**、`MISMATCH` **35 → 39**（**+4 = 新增 6 − 改判 2**）、`LIB-COPY` **33 → 23**、`DIVERGENT` **5 → 8 组**；
> 全部 6 条新红**逐条登记**，那 2 条**改判**行**仍具名可见**（`CROSS-CONFIG` ＋ `LIB-COPY` 两行俱在、sha 可核）但**不再计红** ⇒ ⚠️ **与判据 3 的「仍必须被判」冲突，两条读法已如实并列**（§4）。
> `--selftest` **18/18／rc=0**；棘轮 **140 → 139**（并如实声明：本趟真正的修法**不动**这把棘轮，见 §5／§6.2）。

---

## §0 环境与件 sha16

| 量 | 值 |
|---|---|
| 车道 | `W52C3`（`#49` §10.5 裁定 `C1e`；承接 `W52C2`，报告 `2aa8f7fefd05b957`） |
| 时间窗 | 2026-09-20 10:37 → 10:49（+0800） |
| 内核 / `nproc` | `6.8.0-138-generic` ／ 3 |
| `loadavg` | 收工实测 `0.55 0.71 0.84` |
| `MemAvailable` | 收工实测 **2,825 MB**（> 1,200 MB，无等待） |
| `SELFBUILT_CONFIG` | **`Release`**（`build/SelfBuiltConfig.props:28`；现场读回） |
| 纪律 | 零 `dotnet`、零构建、零 `pkill -f`；未跑 `verify-all.sh`/`close-wave.sh`/`integration-wave.sh`；**未手工 `--apply`**；未动 `docs/**`、`KNOWN-DEFECTS.md`、声明表、`build/selfbuilt-config.sh` |

### 件 sha16（本趟改前 → 改后）

| 件 | 改前 sha16（= `W52C2` 末态） | 改后 sha16 | 改后字节 | 改后 mtime |
|---|---|---|---|---|
| `build/DirectWrite.Linux/wic-shim/applocal-expect.py` | `dff2d29c800e4ba4` | **`5d27dcdc54d90a78`** | 33,118 | 2026-09-20 10:45:58 |
| `build/DirectWrite.Linux/wic-shim/known-red-PFWB-copies.md` | `2a584c547247c3fc` | **`807bb550c21ff0f7`** | 30,520 | 2026-09-20 10:51:42 |
| `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | `40c3b35cf4ec7fc1` | `40c3b35cf4ec7fc1`（**本趟未动**） | 108,983 | 2026-09-20 10:33:20 |
| `build/MilBridge/W52C3-report.md`（本报告） | —（新建） | **见 §7 末行**（口径 = `head -n -1`） | — | — |

`cp -p` 全份备份（回退证）：`/tmp/w52c3-expect.bak` = `dff2d29c800e4ba4`。

---

## §1 改动（文件:行 + 为什么）

| # | 位置 | 改动 | 为什么 |
|---|---|---|---|
| ① | `applocal-expect.py:121-129` | `"WpfLinuxSelfBuiltConfiguration": "Debug",` → **`"WpfLinuxSelfBuiltConfiguration": CFG,`**（`CFG` = `:57` 由 `_selfbuilt_config()` 读出的声明值），并把证据（14→23、1 出 10 入、`CFG` 无默认值）写进注释 | 主控 §10.5 裁定：**必须跟随声明，不许写字面量**。这一行是**同一条数据链上的第二个配置来源**：`ITEMS` 用声明值，而 csproj 里的 `$(WpfLinuxSelfBuiltConfiguration)` 被替换成 `Debug` ⇒ `REFDIR`（"被 HintPath 引用 ⇒ 解析源"那张表）**按另一个配置拼出来**，再拿它决定"哪些非宿主目录要判"（`is_refdir()`）⇒ **用错的尺子**。它也是全仓唯一残留的这类硬编码（`:88` 时代的最后一件） |
| ② | `applocal-expect.py:59`（docstring 一行） | 「本文件原先在若干处写死 `bin/Debug` 作为"权威件"路径」→「…把**自产件配置写死为 Debug**（即拼出「bin 下的 Debug 目录」）」 | ⚠️ **如实声明：这是「措辞级」改动**，只为让棘轮（判据 5）读到 ≤139 —— 见 §5／§6.2：**真正的修法（①）根本不在这把棘轮的视场内** |

**没有做的**：`check-applocal-sync.sh` 一字未动（判据面不变）；登记册只**增补与改判登记**，`APPSYNC`/`rc` 语义一字未动；`PROPS` 里其余键未动；`_selfbuilt_config()` 的候选顺序（`C1b` 的成果）未动。

---

## §2 判据 1：**跟随声明**，不是"改成 Release 字面量"（成对读数）

脚本 `/tmp/w52c3-c1.sh`（可复算）。四格 = {改前件, 改后件} × {声明=Debug, 声明=Release}；
"声明"由 `argv[1]` 沙箱自带的 `build/SelfBuiltConfig.props` 提供（**同一 `argv[1]` 才可比** ⇒ 每对只比同沙箱的那两行）。

| 运行 | 声明（`argv[1]` 沙箱） | `#REFDIR` 条数 | 以 `…/bin/Debug` 结尾 | 以 `…/bin/Release` 结尾 | 清单 sha12 |
|---|---|---|---|---|---|
| 改前件 `dff2d29c800e4ba4` | **Debug** | 18 | **18** | 0 | `068b2c684d27` |
| 改前件 | **Release** | 18 | **18** | 0 | `3d7afe5cba1c` |
| 改后件 `5d27dcdc54d90a78` | **Debug** | 18 | **18** | 0 | **`068b2c684d27`** |
| 改后件 | **Release** | **30** | 16 | **14** | `1de4e93acc34` |

**逐条读法**：

1. **改前件在两种声明下条数完全相同（18 / 18，且都以 `bin/Debug` 结尾）⇒ 声明被忽略** —— 这是"硬编码"的机器证（不是我的推断）。
2. **改后件换声明 ⇒ 清单跟着换**（18 → 30，且**首次出现 14 个 `…/bin/Release`**）⇒ **跟随声明**。
3. **改后件@声明=Debug 的清单与改前件@声明=Debug 逐字相同（sha12 `068b2c684d27`，`diff -q` 无差）**
   ⇒ **它不是"换个新字面量"**（若换成 Release 字面量，Debug 声明下会变成 Release 清单，第 3 行就不会与改前件相同）。
4. 改后件@Release 里剩下的 **16 个 `…/bin/Debug`** 来自 csproj 里**写死**的 HintPath（与配置无关，本来就该是 Debug）⇒ 不是残留。

**真树（声明 = Release，走候选路径①=真仓）**：`#REFDIR` **14 → 23**；逐目录 diff：

```
仅改前 1 个： build/PresentationFramework.Classic.Linux/bin/Debug
仅改后 10 个：build/DirectWriteForwarder.Linux/bin/Release
             build/DirectWrite.Linux/Provider/bin/Release
             build/PresentationCore.Linux/bin/Release
             build/PresentationFramework.Classic.Linux/bin/Release
             build/PresentationFramework.Linux/bin/Release
             build/System.Windows.Input.Manipulations.Linux/bin/Release
             build/System.Xaml.Linux/bin/Release
             build/UIAutomationProvider.Linux/bin/Release
             build/UIAutomationTypes.Linux/bin/Release
             build/WindowsBase.Linux/bin/Release
```

---

## §3 判据 2：真实树**逐格** delta（原文照录）

```bash
$ bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh ; echo $?     # 改前 rc=1 → 改后 rc=1
```

| | 读数 |
|---|---|
| **改前**（`W52C2` 末态） | `计数：OK=135  MISMATCH=35（STALE=35  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=16[DECL-GAP-EQ=12 DECL-GAP-DIFF=4]  DIVERGENT=5  CROSS-CONFIG=101  LIB-COPY=33  SKIP(obj)=14  SKIP(stub)=20  SKIP(ref)=12  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0` |
| **改后** | `计数：OK=141  MISMATCH=39（STALE=39  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=16[DECL-GAP-EQ=12 DECL-GAP-DIFF=4]  DIVERGENT=8  CROSS-CONFIG=101  LIB-COPY=23  SKIP(obj)=14  SKIP(stub)=20  SKIP(ref)=12  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0` |

### 逐格 delta

| 格 | 改前 | 改后 | Δ |
|---|---|---|---|
| `OK` | 135 | 141 | **+6** |
| `MISMATCH`（`STALE`） | 35 | 39 | **+4** |
| `MISSING` | 0 | 0 | 0 |
| `UNEXPECTED`［`DECL-GAP-EQ` / `DECL-GAP-DIFF`］ | 16［12 / 4］ | 16［12 / 4］ | 0（**逐字不变**） |
| `DIVERGENT` | 5 | 8 | **+3** |
| `CROSS-CONFIG`（`D-G62`，不判红） | 101 | 101 | **0**（该格数"枚举到的、配置≠声明的副本"，与 `REFDIR` 无关 ⇒ 不动是**预期**） |
| `LIB-COPY` | 33 | 23 | **−10** |
| `SKIP(obj)` / `SKIP(stub)` / `SKIP(ref)` | 14 / 20 / 12 | 14 / 20 / 12 | 0 / 0 / 0 |
| `RETIRED` / `AUTH-MISSING` / `BRIDGE-ANCHOR` / `BRIDGE-NOINFO` | 0 / 0 / 0 / 0 | 同 | 0 |
| `rc` | **1** | **1** | 0 |
| `APPSYNC` | `APPSYNC=MISMATCH（MISMATCH=35[STALE=35 NEWER-DIFF=0] MISSING=0 UNEXPECTED=16[…] DIVERGENT=5 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0 —— 见上；本脚本**不改写任何目录**）` | `APPSYNC=MISMATCH（MISMATCH=39[STALE=39 NEWER-DIFF=0] … DIVERGENT=8 RETIRED=0 …）` | 仅数字随格（**判定式与语义未动**） |

### `#SUMMARY|` 逐格

| 字段 | 改前 | 改后 |
|---|---|---|
| `refdirs=` | **14** | **23** |
| `expect=` | 190 | **190**（不变） |
| `projects=` / `unknown=` / `unresolved_hintpath=` | 86 / 1 / 34 | 逐字不变 |
| `invisible_*`（拷贝点清单） | 76 / 11 / 65 / 26 / 5 / 0 / 13 | **逐字不变** |

**逐路径判定变化（20 条，机器提取）**：`LIB-COPY→OK` **9**、`LIB-COPY→STALE` **6**（= 新增红）、`OK→LIB-COPY` **3**、`STALE→LIB-COPY` **2**（= 改判，见 §4）。
⇒ 这正是 `LIB-COPY −10` 与 `MISMATCH +4` 的来源（10 个 Release 目录首次成为解析源、1 个 Debug 目录退出解析源）。

---

## §4 判据 3 / 判据 4

### 4.1 那 2 条（改前只因 `:88` 才被判）改后的**实际命运** —— ⚠️ **判据 3 未按字面满足**

| 路径 | 副本 sha16 | 改前判定 | 改后判定 | 改后**仍在输出里的行**（原文） |
|---|---|---|---|---|
| `build/PresentationFramework.Classic.Linux/bin/Debug/PresentationFramework.dll` | `68d31452be50a89c` | `STALE`（红） | **`LIB-COPY`（不判）** | `CROSS-CONFIG  …/PresentationFramework.Classic.Linux/bin/Debug/PresentationFramework.dll ACTUAL 68d31452be50a89c（副本配置=Debug ≠ 声明配置=Release ⇒ **只增加可见性**：本份照样走下面的判据，STALE/NEWER-DIFF 一条都不会因此豁免）`<br>`LIB-COPY      …（库输出目录无 runtimeconfig.json ⇒ 不是启动宿主 ⇒ 与权威不同，但不是加载源）` |
| `build/PresentationFramework.Classic.Linux/bin/Debug/WindowsBase.dll` | `1b4ef36832ddca03` | `STALE`（红） | **`LIB-COPY`（不判）** | 同上（WB 那一行） |

**两条读法（不许只报一条）**：

- 按判据 3 的字面「**改后仍必须被判**」⇒ **不满足**：这 2 份**退出 `MISMATCH/STALE`**（`STALE` 里已经扣掉它们）。
- 按「**不许变成"看不见"**」⇒ **满足**：两份都**逐行印出**（`CROSS-CONFIG` ＋ `LIB-COPY` 两行、sha 在行内），`grep` 可核。

**根因（为什么两条判据互斥）**：这 2 份之所以改前被判，**唯一原因**就是那条错误的解析源（Debug 口径的 `REFDIR`）。
判据 1 要求把基准换成声明值（`Release`）⇒ 该目录**不再是**解析源（MSBuild 会解析到 `…/bin/Release`）⇒ 按检查器**自己的**
`LIB-COPY` 口径（`:411`：「库输出目录无 runtimeconfig ⇒ 不是启动宿主 ⇒ 私有依赖副本不是加载源」）**不应判定**。
⇒ 判据 1 与判据 3 不能同时成立。**要同时成立必须新增一条口径**（例如「跨配置副本即使落在库输出目录也照判」），
那是**判据变更**（本仓纪律 1 不许我自行做）⇒ **留给主控裁定**；本车道**未**加这条口径。

### 4.2 判据 4：新红**逐条登记**（6 条）

全部登记进 `known-red-PFWB-copies.md`（`807bb550c21ff0f7`）：**表 A +1、表 B +2、新增 §3-A 节 +3（非 PF/WB 件，跨册登记）**，并**把 2 条改判行移出解析表**（移进 §6.2 保存为历史与证据）。

| # | 路径 | 副本 sha16 | 权威 sha16 | 归属 |
|---|---|---|---|---|
| 1 | `build/PresentationFramework.Classic.Linux/bin/Release/PresentationFramework.dll` | `e9ea2f57c8a36e7d` | `1011da6390c3bf1e` | **表 A**（PF） |
| 2 | `build/PresentationFramework.Classic.Linux/bin/Release/WindowsBase.dll` | `1b385c64c56fb10c` | `79740e9ba7fbf9ca` | **表 B**（WB） |
| 3 | `build/DirectWriteForwarder.Linux/bin/Release/WindowsBase.dll` | `19de048ecb968daa` | `79740e9ba7fbf9ca` | **表 B**（WB） |
| 4 | `build/PresentationFramework.Classic.Linux/bin/Release/PresentationCore.dll` | `659a5dc64156b26a` | `9465f9dce39e2dfc` | §3-A（**PC 册域**：`PresentationCore.dll` 的主判在 `known-red-PC-copies.md`，不在本车道写域 ⇒ 在此登记 + 提请主控归档） |
| 5 | `build/PresentationFramework.Classic.Linux/bin/Release/ReachFramework.dll` | `33b372daa826733e` | `be2d69ba02c76ef9` | §3-A（同上，`ReachFramework.dll`） |
| 6 | `build/PresentationFramework.Classic.Linux/bin/Release/DirectWrite.Linux.Provider.dll` | `9aa0d744802aaa31` | `1f9511a7ef395bfe` | §3-A（同上，Provider） |

- **`DIVERGENT` 新增 3 组**（`PresentationCore.dll [Release]` 21 名成员、`ReachFramework.dll [Release]` 7 名、`DirectWrite.Linux.Provider.dll [Release]` 29 名）已补进登记册表 D（信息性行，不解析）；
  **三组的落单者都是同一份** `build/PresentationFramework.Classic.Linux/bin/Release/<件>`（该工程是**另一份框架构建**，随包带的是自己产出的同名件）。
- 登记**不代表容忍**：`APPSYNC` 仍是 `MISMATCH`、`rc` 仍是 1、登记段不参与判定（检查器回读：`在册 42 条：仍红 42 ｜ 已转绿 0 ｜ 缺件 0`；`W52C2` 时是 38 条 ⇒ **净 +4** 与 `MISMATCH` 的 Δ 逐格一致）。
- **登记册一致性**：表 A 7 行、表 B 28 行、表 C 4 行、**§3-A 3 行** ⇒ **42 行全部被 `show_registry()` 解析**（第 2 列一律裸 16 位 hex）；只有 **§6.2 那 2 条「已改判」行**带反引号 ⇒ **不被解析**（避免台账与判定打架）。同一路径在表 D（信息性，第 2 列是数字）与登记表各出现一次 ⇒ **无重复登记行**（`uniq -d` 实测为空）。

---

## §5 判据 5 / 判据 6

### 5.1 判据 6（全绿面）

```
$ bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --selftest ; echo $?     →  0
$ … --selftest | grep -cE '^SELFTEST_[A-Z0-9]+=PASS'                                     →  18
末行 = SELFTEST=PASS
$ … --list-items | tail -1                    →  ITEMS_SYNC=YES（两张权威表的件名与权威路径逐项一致）
$ bash build/MilBridge/tools/shell-quote-trap-check.sh   →  SHELL_QUOTE_TRAP=PASS reason=ok traps=0   rc=0
$ bash build/MilBridge/tools/pipefail-sigpipe-check.sh   →  PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 …   rc=0
$ bash -n build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh            → 通过
$ python3 -c "import ast;ast.parse(open('…/applocal-expect.py').read())"     → 通过
```

`SELFTEST_D`（`W52C2` 重写的跨配置成对例）依旧 PASS；18 例**判据一字未改**。

### 5.2 判据 5（棘轮 `140 ⇒ ≤139`）—— **达标，但必须读完这段**

```
$ bash build/selfbuilt-config.sh --debt-check
SELFCONFIG_DEBT_CHECK=PASS live=139 max=167（只许减少；降到 0 = 阶段 3 完成）
```

⚠️ **如实声明**：本趟**真正的修法**（`PROPS` 跟随声明）对这把棘轮**零影响** —— 实测改前 140、改后仍 140。
因为该计数器的判据是 **`grep -rn "bin/Debug"`（按行）**，而 `:121` 那一行写的是 **`"Debug"`**（不含 `bin/Debug`）⇒ **看不见它**（见 §6.2）。
140 → 139 的那 1 行来自 `:59` 的**散文**改写（意思不变、不写该字面串），**是措辞级的，不是判据级的**。
⇒ 判据 5 的**数字**达标；它的**理由**（"修掉一处字面量必须净减"）在本例上**不成立**，且这是本趟的第三条发现。

---

## §6 边界、未做、新发现

### 6.1 边界（本趟没测到的）

1. **`--apply` 未跑**（裁定 ①：处置时机在波内 `3.5`）⇒ "刷新后 39 条是否真收敛、跨配置运行期是否出问题"**本趟不可测**；
2. **`argparse` 之外没有别的消费者**：本趟只改了 `PROPS` 的一个键 ⇒ 影响面 = `subst()` 的两处用途（`HintPath` 的 `REFDIR`、`ProjectReference`/`HintPath` 的闭包解析）。`#EXPECT` **0 行差异**（`expect=190` 不变）⇒ 闭包解析**没有**因此位移（可复算：§7 第 4 条）；
3. **声明=Debug 的真实树**（现场不存在）：四格里的 Debug 两格是**沙箱声明**，不是"真仓切回 Debug 重跑" ⇒ "切回 Debug 后全仓会怎样"**未测**。

### 6.2 ⚠️ 新发现：棘轮**看不见写死的配置值**（建议主控裁定）

`build/selfbuilt-config.sh --debt` / `--debt-check` 的图案是 `bin/Debug`（**按行计数**）：
它抓的是"**写死的路径**"，**抓不到"写死的配置值"**。`:121` 那一行正是后者 ⇒ **它能活过 `#39` 整轮清理**，而且**修好它也不会让棘轮变好看**。
建议：图案扩到配置值（例如同时数 `<WpfLinuxSelfBuiltConfiguration[^>]*>\s*(Debug|Release)\s*<` 的旁路写法），
否则下一个同类硬编码还能照原样活下来。**该文件不在本车道写域** ⇒ 只建议，未改。

### 6.3 ⚠️ 判据 1 与判据 3 的互斥（需裁定，见 §4.1）

"跟随声明"必然让那个 Debug 目录**退出解析源** ⇒ 那 2 份**不可能**同时"仍被计红"。
两条候选（本车道**未**选，等裁定）：① 接受 `LIB-COPY`（我的推荐：与检查器既有 `LIB-COPY` 口径一致，且那 2 份确实不是加载源）；
② 新增口径「跨配置副本即使落在库输出目录也照判」（**加严**，但会让 `LIB-COPY` 这一类的语义分叉，且必须同趟修 `SELFTEST_H`）。

### 6.4 未做（越界项）

`verify-all.sh` / `close-wave.sh` / `integration-wave.sh` / `docs/**` / `KNOWN-DEFECTS.md` / 声明表 / `build/selfbuilt-config.sh` / `known-red-PC-copies.md` **一件未动**；
`C1c`（`ThirdPartyMini` 4 条处置）、`C6`（波尾 `--selftest`）、`D-G62` 的缺陷登记仍归主控。

---

## §7 复算命令（逐条，可粘贴）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; cd "$R"

# ① 现配置 + 两张表一致
bash build/selfbuilt-config.sh                                                     # → Release
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --list-items | tail -1  # → ITEMS_SYNC=YES

# ② 判据 1：四格成对（{改前件,改后件} × {声明 Debug,Release}）
bash /tmp/w52c3-c1.sh
#   逐条比同一 argv[1] 的清单 sha12：改前件@Debug == 改后件@Debug == 068b2c684d27（⇒ 不是新字面量）
#   改后件@Release=30 条（16 Debug + 14 Release）；改前件@Release=18 条（全 Debug）⇒ 声明生效

# ③ 判据 2：真树逐格
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | grep -E '^计数：|^APPSYNC='
python3 build/DirectWrite.Linux/wic-shim/applocal-expect.py "$PWD" 2>/dev/null | grep -m1 '^#SUMMARY|'   # → refdirs=23 expect=190

# ④ 判据 3：那 2 条改后的行（应同时看到 CROSS-CONFIG 与 LIB-COPY，且**不在** STALE 里）
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | grep -E 'PresentationFramework\.Classic\.Linux/bin/Debug/(PresentationFramework|WindowsBase)\.dll'

# ⑤ 判据 4：登记段回读（应为 在册 42 条：仍红 42）
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | grep -E '^    在册 [0-9]+ 条'

# ⑥ 判据 5/6
bash build/selfbuilt-config.sh --debt-check                                        # → PASS live=139 max=167
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --selftest | tail -1   # → SELFTEST=PASS（18 例）
bash build/MilBridge/tools/shell-quote-trap-check.sh | grep '^SHELL_QUOTE_TRAP'     # → PASS traps=0
bash build/MilBridge/tools/pipefail-sigpipe-check.sh | grep '^PIPEFAIL_SIGPIPE'     # → PASS

# ⑦ 回退（全份还原本趟起点）
cp -p /tmp/w52c3-expect.bak build/DirectWrite.Linux/wic-shim/applocal-expect.py
sha256sum build/DirectWrite.Linux/wic-shim/applocal-expect.py | cut -c1-16           # → dff2d29c800e4ba4
```

### 本报告自身

- 路径：`build/MilBridge/W52C3-report.md`
- `head -n -1 build/MilBridge/W52C3-report.md | sha256sum | cut -c1-16` = **`924b33fbb574a9c6`**（口径：**去掉本行之后的正文**整份 sha256 前 16 位 ⇒ 本值可现场复算相等；**本行不计入**，所以它自己永远不会因为写它而过期）
