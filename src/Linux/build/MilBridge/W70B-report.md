# `W70B` 报告 —— `TASK-1002`：把「只经 `build/third-party/WpfLinux.props` 接线的样例」纳入应用门禁的**声明式期望模型**

> 仓根 `$R = /home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（全程绝对路径）。
> **先写判据、后动代码**：§1 是**改前**写下的判据与预判（预判后来逐格对照，**对不对都留档**，见 §4 的对照列）。
> 纪律：`NOINFO` 既不算绿也不算红；结论一律 `artifact ＋ 字段 ＋ sha16`；改既有文件前 `cp -p` 备份并报 before/after sha16；**未**手抄任何哈希（全部现场 `sha256sum` 取前 16 位）；**未**跑 `integration-wave.sh` / `close-wave.sh` / `verify-all.sh`；**未**改任何路由件（证据见 §3.5）；**未**起 `dotnet`/应用（全程纯 shell/python ⇒ 未用 `~/heavy-slot.sh`）；**未** `pkill -f`。

---

## §0 环境与冻结值

| 项 | 值 | 取法 |
|---|---|---|
| 仓根 `$R` | `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux` | `pwd` |
| 声明配置 | `SELFBUILT_CONFIG=`**Release** | `build/SelfBuiltConfig.props:28` |
| 时间窗 | 本件开工 `2026-09-21 12:13` → 取证结束 `12:26`（+0800） | `before.txt` 生成时刻 ／ `date -Is` |
| 内存 | 纯 shell/python，**零** `dotnet`、零应用 ⇒ 未进 `~/heavy-slot.sh` | `free -m` |

### §0.1 本次涉及的既有件 before/after sha16（**改前先 `cp -p` 备份**）

| 文件 | before sha16 | after sha16 | 动作 |
|---|---|---|---|
| `build/DirectWrite.Linux/wic-shim/applocal-expect.py` | `5d27dcdc54d90a78` | **`b5dccf135afd6de4`** | **改**（修法本体：显式 `<Import>` 闭包）。备份 `$HOME/w70b/backup/applocal-expect.py.before`（sha256 与改前逐字相同） |
| `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | `40c3b35cf4ec7fc1` | **`97d547551846fd13`** | **改**（**只**把新通道的输入**显示**出来 ＋ 一句覆盖面自认；判据／计数器／判定式／`rc` 一字未动）。备份 `$HOME/w70b/backup/check-applocal-sync.sh.before` |
| `build/third-party/WpfLinux.props` | `bdc3954b4a129112` | `bdc3954b4a129112` | **只读，未改** —— 本件**不动产品接线** |
| `samples/ThirdPartyMini/ThirdPartyMini.csproj` | `bea59353c18ac8ab` | `bea59353c18ac8ab` | **只读，真树未改**（反极性腿在**硬链接副本**上做，见 §4.2；副本内临时撤行 → 副本 `3c5dbe7016c52dc1` → 整份还原为 `bea59353c18ac8ab`） |

### §0.2 改前基线（**自己复算**，不信转述）

```
$ bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh          # 12:13
rc=1
计数：OK=128  MISMATCH=52（STALE=51  NEWER-DIFF=1）  MISSING=0  UNEXPECTED=16[DECL-GAP-EQ=16 DECL-GAP-DIFF=0]
      DIVERGENT=9  CROSS-CONFIG=101  LIB-COPY=23  SKIP(obj)=14  SKIP(stub)=20  SKIP(ref)=12  RETIRED=0
      AUTH-MISSING=0  BRIDGE-ANCHOR=2  BRIDGE-NOINFO=0
APPSYNC=MISMATCH
# 模型侧（applocal-expect.py，改前件 5d27dcdc54d90a78）：
#SUMMARY|refdirs=23|expect=190|projects=86|unknown=1|unresolved_hintpath=34|…
```
留档：`$HOME/w70b/evidence/before.txt`。

**与派单转述的差异（如实报）**：派单写 `MISMATCH=52[STALE=52]`，现场实得 **`MISMATCH=52（STALE=51 NEWER-DIFF=1）`** ⇒ `STALE` 那一格我不复现转述值（合计 52 一致；主控 12:18 的独立复算与我逐字同）。`UNEXPECTED=16[DECL-GAP-EQ=16 DECL-GAP-DIFF=0]`、`DIVERGENT=9`、`MISSING=0` 与转述一致。

`UNEXPECTED-EQ` **16 条按目录归并**（现场 `grep`）：

| 目录 | 条数 | 件 |
|---|---|---|
| `samples/ThirdPartyMini/bin/Debug/net10.0` | **5** | `DirectWrite.Linux.Provider.dll` / `ReachFramework.dll` / `PresentationCore.dll` / `PresentationFramework.dll` / `WindowsBase.dll` |
| `samples/ThirdPartyMini/bin/Release/net10.0` | **5** | 同上 5 件 |
| `build/MilBridge/tests/{ResolverGuardProbe,IcuBreakParity,BboxProbe,InputTraceProbe}/bin/Release[/net10.0]` | 4 | `DirectWrite.Linux.Provider.dll` |
| `build/MilBridge/.artifacts/bin/ClosedLoop/release` | 1 | `DirectWrite.Linux.Provider.dll` |
| `build/DirectWrite.Linux/FallbackCriteria/bin/Debug` | 1 | `WpfGfx.Linux.dll` |

⇒ `ThirdPartyMini` 独占 **10/16**（正是 `TASK-1002` 的对象）；其余 **6 条不是同族**（§5）。

### §0.3 ⚠️ 环境位移（**不是我改的，也不是我能控的**）——必须先说明，否则后面的计数会被误读

**另一条车道在本件取证期间反复重建 `PresentationCore.dll` 权威件**：

| 时刻 | PC 权威 sha16 |
|---|---|
| 12:13（改前基线） | `9465f9dce39e2dfc` |
| 12:19:18（重建） | `21e3e88a5090cd3b` |
| 12:26:53 | `0d8993521d5517d0` |

⇒ **`MISMATCH` / `STALE` / `OK` 三格会在两次运行之间漂移**（12:18 `MISMATCH=52` → 12:23 `88` → 12:26 `89`）。
⇒ 因此本件的**判据量**刻意选在**不受该位移影响**的格上：`UNEXPECTED` / `DECL-GAP-EQ` / `DECL-GAP-DIFF` / `MISSING` / 模型侧 `#EXPECT` 基数 —— 它们在整个窗口内**稳定**（§4）。
⇒ 唯一被它沾到的格 = §4.2 的 `DECL-GAP-EQ/DIFF` **分裂**（14/2），成因已定死到 sha。

---

## §1 判据（**改前写下**；以下全部是当时的"预期"，§4 逐格对照）

### §1.1 判定点（"为什么算不出"）——文件:行级（行号 = **改前件** `5d27dcdc54d90a78`，现场读过）

- `P0a`：`build/DirectWrite.Linux/wic-shim/applocal-expect.py` 的 `project_refs()`（`:153-165`）、`refs_of()`（`:168-178`）、`outdirs()`（`:181-186`）**只解析调用方传进来的那一份 `text`**；而 `main()`（`:392-412`，`projs[p] = dict(… text=text …)` 在 `:405`）喂进去的**只有工程自己的 csproj 文本**（`:394` 只 `open(p)`）⇒ **`<Import>` 声明的接线对模型完全不可见**。第三条入口 `E()` 同样：`refdirs` 扫描在 `:421`、`E()` 里的 `<HintPath>` 扫描在 `:468`，都是 `d["text"]`。
- `P0b`：`samples/ThirdPartyMini/ThirdPartyMini.csproj` **一条 `<Reference>` / `<ProjectReference>` / `<HintPath>` 都没有**；它第 **29** 行是 `<Import Project="$(WpfLinuxRoot)/build/third-party/WpfLinux.props" />`，而自产件引用**全部**写在被导入件的 `build/third-party/WpfLinux.props:76-117`（`WindowsBase:77`、`PresentationCore:85`、`PresentationFramework:89`、`DirectWrite.Linux.Provider:113`…）。⇒ `E(ThirdPartyMini)` 只剩"自身产出的程序集"，而 `ThirdPartyMini` **不是** `ITEMS`（`:95-114`）里的任何一件 ⇒ `E` 为空 ⇒ `main():489-490` 的 `if not e: continue` **直接跳过整个工程** ⇒ 它的输出目录**一条期望都不产生** ⇒ 那 10 份副本落进 `check-applocal-sync.sh:432-445` 的 `UNEXPECTED` 分支（内容==权威 ⇒ `UNEXPECTED-EQ`，即 `DECL-GAP-EQ`；`CNT_UNEXPECTED` 在 `:434` 计入、进 `:1117` 的最终判定 ⇒ **红**）。
- `P0c`（**第二条缺口，容易漏**）：`$(TargetFramework)` 也声明在**被导入件**里（`WpfLinux.props:48`），而 `outdirs()`（`:181-186`）的正则是 `r"<TargetFramework>([^<]+)</TargetFramework>"` —— **只认"无属性形态"**；现场那行是 `<TargetFramework Condition="'$(TargetFramework)' == ''">net10.0</TargetFramework>` ⇒ 即使把 import 跟进去也抓不到 `net10.0` ⇒ 期望目录会被算成 `samples/ThirdPartyMini/bin/Debug`，而真副本在 `…/bin/Debug/net10.0` ⇒ **仍然 `UNEXPECTED`**。

### §1.2 修法（判据 = 跟着**真实接线**走，**不是**白名单）

- `F1`：给期望模型加**显式 `<Import>` 闭包**：解析 `<Import Project="…">` → 仓内、存在、后缀 ∈ {`.props`,`.targets`} ⇒ **把该文件文本并入工程文本**（递归、visited 去重、深度上限 8）；解析出的声明（`<Reference>` / `<ProjectReference>` / `<HintPath>` / `<TargetFramework>` / `<AppendTargetFrameworkToOutputPath>`）与工程自写的**一视同仁**。
  - `F1a`：被导入件文本**先剥 XML 注释**再解析 —— 否则 `WpfLinux.props:8-15` 的**用法模板注释**里那行 `<Import Project="WpfLinux.props" />` 会被当成真 import（自指环）。
  - `F1b`：属性代入覆盖真实接线用到的三个形态：`$([MSBuild]::GetPathOfFileAbove('X'))`（全仓 42 处）、`$(MSBuildThisFileDirectory)`（**按"声明所在文件"的目录**代入）、以及 `WpfLinux.props:46` **自己声明**的别名 `WpfLinuxBuildConfiguration ← $(WpfLinuxSelfBuiltConfiguration)`（**不是**新造语义）。
- `F2`：**未解析的 import 必须自报**（`#UNRESOLVED-IMPORT` ＋ 摘要格），且**分桶** `sdk`（SDK 侧，`Sdk.props` / `$(MSBuildSDKsPath)/…`，按构造不在本仓 import 图里）与 `repo`（**真缺口**）。
- **硬红线自查**：① `ITEMS` 9 项前后**逐字未动**（`--list-items` 仍 `ITEMS_SYNC=YES`）；② 未调小任何计数、未改判定式；③ **未写任何副本白名单**；④ 只碰"期望集合"这一侧，未动 `sync-applocal-authority.sh` 的写路径。

### §1.3 预判（改前写下的期望读数）与**实测对照**

| # | 判据 | 预判 | **实测对照** |
|---|---|---|---|
| `P1` | 正极性：`ThirdPartyMini` 那 10 条由 `UNEXPECTED-EQ` 转为**声明内** | `UNEXPECTED` 16→6、`DECL-GAP-EQ` 16→6、`DIFF` 仍 0 | **✅ 逐字命中**（§4.1；`OK 128→138`） |
| `P2` | 不倒退：`MISSING` 不得因"凭空造期望"而涨；别的红不动 | `MISSING` 仍 0；`APPSYNC` 仍 `MISMATCH` | **✅**（`MISSING=0`；`APPSYNC=MISMATCH`） |
| `P3` | 反极性：撤掉那行 `<Import>` ⇒ 必须**回到 16** | `UNEXPECTED=16[DECL-GAP-EQ=16]` | **✅ 总量 16 命中**；但 EQ/DIFF 分裂 = **14/2** —— 成因是 §0.3 的**并发重建**（2 份 PC 副本 sha ≠ 新权威 ⇒ 落 `DIFF`，而 `DIFF` **更红不是更绿**）；分桶证据见 §4.2 |
| `P4` | `--selftest` 仍全绿 | `SELFTEST=PASS`、`rc=0`（18 例） | **✅**（§6：18 例逐例 PASS、`rc=0`） |
| `P5` | 模型自证：`#EXPECT` 新增 10 行且来源链**点名** `WpfLinux.props` | `expect` 190→**200** | **✅ 基数命中**，点名亦命中（`（**经 \`<Import>\` 带入**：build/third-party/WpfLinux.props）`）；**但**传递来的那一条（`ReachFramework.dll`）链上不标 —— 已知显示边界，见 §4.1 |
| `P6` | 覆盖边界自报：`repo` 桶 = **0** | 0（`>0` 则逐条列） | **✅ 最终 0**；但**第一版自造了 5 条假 `repo`**（已自纠，见 §4.3 —— 这是我自己的缺陷，留档） |
| `P7` | 旁证：全仓只有**一个** csproj 只经 `WpfLinux.props` 接线 | `grep -rl` = 1 | **✅ = 1**（`samples/ThirdPartyMini/ThirdPartyMini.csproj`）⇒ 本修法**位移面 = 该工程** |
| `P8` | 其余 6 条 `DECL-GAP-EQ` **不是同族** | 读数不变 | **✅**（§5：逐条分族，且**不**因本修法消失） |
| `P9` | `inputs_fp` **会变**（两份件都在 `close-wave.sh` 的 `fp_inputs()` 里） | 如实写明 | **✅**（§3.4 给静态论证与逐件 sha256） |

---

## §2 判定点（**现场确认**：`P0a`/`P0b`/`P0c` 三条全部成立）

| 判定点 | 文件:行（改前件 `5d27dcdc54d90a78`） | 现场证据 |
|---|---|---|
| **① 模型只读"工程自己那一份文本"** | `applocal-expect.py:392-412`（`main()` 只 `open(p)`）、`:405`（`text=text`）、`:153-165` `project_refs()`、`:168-178` `refs_of()`、`:181-186` `outdirs()`、`:421` 与 `:468`（`d["text"]` 的两处 `<HintPath>` 扫描） | 把 import 跟进去后 `#EXPECT` 190→200、`#REFDIR` 23→24，**其余逐字不变**（A/B diff 见 §4.3） |
| **② 该工程的引用全在被导入件里** | `samples/ThirdPartyMini/ThirdPartyMini.csproj:29`（`<Import>`）＋`build/third-party/WpfLinux.props:76-117`（十条 `<Reference>`） | `grep -c '<Reference ' ThirdPartyMini.csproj` = **0**；`grep -rl 'WpfLinux.props' --include='*.csproj'` = **1** |
| **③ 空闭包被 `if not e: continue` 整段跳过** | `applocal-expect.py:483-494`（跳过在 `:489-490`） | 改前 `APEXPECT_DEBUG=ThirdPartyMini` 打出的 `DEBUG …` 行数 = **0**（模型对该工程零输出）；改后 = **10** |
| **④ 副本被报 `UNEXPECTED-EQ` 并计红** | `check-applocal-sync.sh:432-445`（分支）、`:434`（`CNT_UNEXPECTED`）、`:436-438`（`UNEXPECTED-EQ`／`CNT_DECLGAP_EQ`）、`:1117`（最终判定） | 改前该 10 行行首标签 = `UNEXPECTED-EQ`，`APPSYNC=MISMATCH`、`rc=1` |
| **⑤ 第二条缺口：`<TargetFramework>` 的属性形态** | `applocal-expect.py:182`（改前正则）＋`build/third-party/WpfLinux.props:48` | 只补 ① 而不放宽 ② ⇒ 期望目录算成 `…/bin/Debug`、真副本在 `…/bin/Debug/net10.0` ⇒ **仍 `UNEXPECTED`**（本缺陷"看着只差一处、其实差两处"）。放宽的**零位移证明**见 §3.2 |
| **⑥ 别名未代入会把真·未解析项挤出清单** | `build/third-party/WpfLinux.props:46`（声明别名）＋`applocal-expect.py:115-131`（`PROPS`）、`:561-563`（只印前 10 条 `#UNRESOLVED`） | 不补别名 ⇒ 该 props 的 11 条 `<HintPath>` 全落 `UNRESOLVED`，工具只印 10 条 ⇒ 真·未解析项被挤出 |

**逐条可核的原始输出**：`$HOME/w70b/evidence/before.txt`、`final_chk.txt`、`after_tool4.txt`。

---

## §3 修法（最小 diff）

### §3.1 `applocal-expect.py`（`5d27dcdc54d90a78` → `b5dccf135afd6de4`）

五组改动，**按锚文本可定位**（行号会随后续编辑漂移，故给锚）：

1. **`PROPS` 表**（锚 `"WpfLinuxSelfBuiltConfiguration": CFG,`）后加一行 `"WpfLinuxBuildConfiguration": CFG` —— 依据是 `build/third-party/WpfLinux.props:46` **自己声明**的那条别名；不代入它会让那份 props 的 11 条 `<HintPath>` 全落 `UNRESOLVED`，把真·未解析项挤出只印 10 条的清单（判定点 ⑥）。
2. **新增"显式 `<Import>` 闭包"**（锚 `def subst(text, projdir):` 之后）：`strip_xml_comments()` / `literal_props()` / `_file_above()` / `resolve_msbuild_path()` / `import_closure()` ＋ 模块级 `IMPORT_UNRESOLVED` / `IMPORT_EDGES` / `IMPORT_MAX_DEPTH`。**这不是白名单**：判据是"显式 `<Import>` 图"这一条通用规则。
3. **`outdirs()` 放宽 `<TargetFramework>` 正则**（`r"<TargetFramework>([^<]+)</…>"` → `r"<TargetFramework\b[^>]*>…"`）；`\b` 天然排除 `<TargetFrameworks>`／`<TargetFrameworkVersion>`（'k' 后接词字符 ⇒ 无词边界）。
4. **`main()` 把 import 闭包并入工程文本**（锚 `projs[p] = dict(dir=…`）：`eff = "\n".join([text] + [被导入件文本…])`，`refs_of`/`project_refs`/`outdirs` 全部改用 `eff`；另加 `ownnames` / `refsrc` —— **只为让来源链说真话**（`ThirdPartyMini.csproj` 一条 `<Reference>` 都没有，不标注会让读者以为引用写在那里）。
5. **输出**：新增 `#IMPORT|工程|被导入件|深度` 与 `#UNRESOLVED-IMPORT|工程|表达式|桶`；`#SUMMARY` **末尾追加**三格 `import_edges` / `import_unresolved_repo` / `import_unresolved_sdk`（**只追加** ⇒ 旧消费者按位置读前 12 格不受影响）。

### §3.2 三条"零位移"实证（说明改动面确实被限住）

- **工程自己的文本不剥注释**（改动面只落在**新增的 import 通道**上）；剥注释只作用于被导入件 —— 而被导入件里的注释**确实有陷阱**：`WpfLinux.props:8-15` 的用法模板注释含一行 `<Import Project="WpfLinux.props" />`（不剥 ⇒ 自指），`SelfBuiltConfig.props:9` 与 `Directory.Upstream.props:46` 的注释各含一处 `<HintPath>` 字样。
- **放宽 `<TargetFramework>` 正则对既有读数零位移**：`grep -rl '<TargetFramework ' --include='*.csproj'` 在仓内 = **0 个** ⇒ 属性形态只存在于被导入的 props 里 ⇒ 放宽前后 86 个工程的匹配集逐字相同。
- **`WpfLinuxBuildConfiguration` 别名不是新语义**：`WpfLinux.props:46` 逐字声明 `← $(WpfLinuxSelfBuiltConfiguration)`；且改后 `unresolved_hintpath` 仍 **34**（与改前**逐字相同**）⇒ 别名只把"本该解析的"解析掉，没有新增或吞掉任何一条。

### §3.3 `check-applocal-sync.sh`（`40c3b35cf4ec7fc1` → `97d547551846fd13`）—— **只显示，不判定**

- 新增两格解析（锚 `'#UNRESOLVED')`）：`'#IMPORT'`→`IMPORT_EDGES_N`；`'#UNRESOLVED-IMPORT'`→按第三列分桶（`repo` 入数组、`sdk` 计数）。
- 在"期望集合 vs 现场"段打印：**跟随的边 N 条**（全清单给 `grep '^#IMPORT'` 的取法，与 `#INVISIBLE-*` 同款）＋ **`repo` 桶逐条点名**（`=0` 时明确写"本趟没有接线被模型漏掉的 import"）＋ 覆盖面自认（**只跟显式 `<Import>`；隐式 `Directory.Build.props/.targets` 不跟**）。
- **`rc` / 判定式 / 全部 `CNT_*` / `ITEMS` 一字未动**；两格与既有的 `HINTPATH_UNRESOLVED` 同口径（**登记、不静默、不进判定**），但打印里明写 **`repo>0` 不是绿**。
- **自纠**：第一版这一段的 echo 里有一处**反引号未转义**（`` `ITEMS` ``）⇒ 被 shell 当命令替换，屏上出现 `ITEMS: 未找到命令`（**只污染显示，不动任何计数**）。已修（`\`ITEMS\``）；最终读数 `stderr` 字节数 = **0**。

### §3.4 ⚠️ `inputs_fp` **会变**，原因 = **本件**（派单要求显式写明）

- 静态证据（`build/close-wave.sh:214` 是 `fp_inputs()` 的合成式，输入清单里**逐字列出**了这两件）：
  ```
  build/close-wave.sh:211  build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh
  build/close-wave.sh:212  build/DirectWrite.Linux/wic-shim/applocal-expect.py
  ```
  ⇒ 合成式 = `{ 输入清单 … } | LC_ALL=C sort | xargs sha256sum | sha256sum | cut -d' ' -f1`，而这两条输入行的 sha256 变了：
  ```
  applocal-expect.py     5d27dcdc54d90a7842a73a60b8c42672d6f65f03ac7183a86f71cb5034a0f0cb
                      →  b5dccf135afd6de4df61a3d793a10ec288a8a5715d37fef84498787598afdad8
  check-applocal-sync.sh 40c3b35cf4ec7fc1750203368a08ac5cc0c48f291ff236cf8d93b1cb68c66507
                      →  97d547551846fd138d5ad7185b5eb08e4b7ad7e3776545415f3321d6c41e2c7e
  ```
  ⇒ **`inputs_fp` 必变**（排序后那两行文本变了 ⇒ 末级摘要必不同），**原因 = `W70B`／`TASK-1002`**。按派单，波内改动由收尾的 `repin-generation --why` 记账。
- `inputs_fp` 的**前后数值**这里**不给**（`NOINFO(未取)`）：算它要跑 `close-wave.sh`（本件被明令禁止），自己复刻一份 `fp_inputs()` 等于在本仓再立"第二处逻辑" —— 见 §8 第 1 条。

### §3.5 路由件"未触碰"的证据（**用 mtime，不用自称**）

| 路由件 | 现场 mtime | 结论 |
|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `2026-09-21 12:12:46` | 早于本件首次落盘（`12:19:49`）⇒ **本件未触碰** |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `2026-09-21 12:12:46` | 同上 |
| `docs/CURRENT-STATE.md` | `2026-09-20 01:25:17` | 同上 |
| `handoff.md` | `2026-09-20 01:05:33` | 同上 |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `2026-09-20 00:51:46` | 同上 |

---

## §4 两极化读数

### §4.1 窗口 W1（**真树、改前／改后同一窗口**，`12:13` vs `12:18`；PC 权威两次都是 `9465f9dce39e2dfc` ⇒ **无位移**）

| 格 | 改前 | 改后 | 差 |
|---|---|---|---|
| `rc` | 1 | 1 | — |
| `APPSYNC` | `MISMATCH` | `MISMATCH` | **未变**（没借本件洗别的红） |
| **`UNEXPECTED`** | **16** | **6** | **−10** |
| **`DECL-GAP-EQ`** | **16** | **6** | **−10** |
| `DECL-GAP-DIFF` | 0 | 0 | 未变 |
| `MISSING` | 0 | 0 | **未变**（没有凭空造出不存在的期望） |
| `OK` | 128 | **138** | **+10**（恰为该样例的 10 份） |
| `MISMATCH（STALE/NEWER）` | 52（51/1） | 52（51/1） | 未变 |
| `DIVERGENT`／`CROSS-CONFIG`／`LIB-COPY`／`AUTH-MISSING`／`BRIDGE-*` | 9／101／23／0／2·0 | 同 | 未变 |
| 模型 `#SUMMARY` | `refdirs=23 expect=190 … unresolved_hintpath=34` | `refdirs=24 expect=200 … unresolved_hintpath=34` | `+1／+10`；`unresolved_hintpath` **未变** |

**逐条证据（改后那 10 行由 `UNEXPECTED-EQ` → `OK`）**：
```
OK  samples/ThirdPartyMini/bin/{Debug,Release}/net10.0/DirectWrite.Linux.Provider.dll  1f9511a7ef395bfe
OK  samples/ThirdPartyMini/bin/{Debug,Release}/net10.0/ReachFramework.dll              be2d69ba02c76ef9
OK  samples/ThirdPartyMini/bin/{Debug,Release}/net10.0/PresentationCore.dll             9465f9dce39e2dfc
OK  samples/ThirdPartyMini/bin/{Debug,Release}/net10.0/PresentationFramework.dll        1011da6390c3bf1e
OK  samples/ThirdPartyMini/bin/{Debug,Release}/net10.0/WindowsBase.dll                  2e4e46e539a72cd7
```
**来源链（改后，逐字）**：
```
#EXPECT|…/samples/ThirdPartyMini/bin/Debug/net10.0|PresentationCore.dll|
   samples/ThirdPartyMini/ThirdPartyMini.csproj 的 <Reference Include="PresentationCore">（**经 `<Import>` 带入**：build/third-party/WpfLinux.props）
#EXPECT|…|ReachFramework.dll|
   samples/ThirdPartyMini/ThirdPartyMini.csproj →(引用 PresentationFramework)→ build/PresentationFramework.Linux/PresentationFramework.Linux.csproj 的 <Reference Include="ReachFramework">
```
⚠️ **如实标注一条显示边界**：`ReachFramework.dll` 那条链**不**标"经 import 带入"（它是**传递**来的：走 `PresentationFramework` 的闭包），而 `PresentationFramework` 本身在同一工程里是 import 带入的 ⇒ 链上**只有直连那一段**带 import 标注。`#IMPORT|samples/ThirdPartyMini/ThirdPartyMini.csproj|build/third-party/WpfLinux.props|0` 是这条标注的完整输入。

留档：`$HOME/w70b/evidence/before.txt`（改前）、`after_chk.txt`（改后）。

### §4.2 窗口 W2（**冻结副本**，`12:21-12:22`）—— 反极性腿，**真树零改动**

做法（**按主控裁定**）：`cp -al $R /tmp/w70b/neg` 造**整树硬链接副本**（15611 项），在**副本内**用"写新文件 + `mv` 覆盖"（**不写穿硬链接**）撤掉 `<Import>` 行；两腿跑的**都是副本自己**的 `AUTH_ROOT=/tmp/w70b/neg`（扫描根、权威表、期望目录全落在副本内 ⇒ `#EXPECT|<dir>` 与 `SCAN_ROOTS` 的**绝对路径天然对齐**）。
**为什么不用浅副本**：只把 `HINTPATH_ROOTS` 指向浅副本，会让期望目录变成副本路径、被 `in_scan_roots()` 全部滤掉 ⇒ 那是**假反极性**（读的是"换了路径"而不是"撤了声明"）。

| 腿 | 副本 csproj sha16 | `rc` | `OK` | `MISMATCH` | `MISSING` | **`UNEXPECTED`** | `EQ`/`DIFF` |
|---|---|---|---|---|---|---|---|
| **N0 声明在** | `bea59353c18ac8ab` | 1 | 100 | 90（89/1） | 0 | **6** | **6 / 0** |
| **N1 声明撤** | `3c5dbe7016c52dc1` | 1 | 92 | 88（87/1） | 0 | **16** | **14 / 2** |

⇒ **总量判据命中**：撤掉声明 ⇒ `UNEXPECTED` **6 → 16**，那 10 份**全部回到未声明**（逐条行首标签见 `$HOME/w70b/evidence/neg_N1.txt`）。
⇒ **`EQ/DIFF` 分裂 = 14/2，不是 16/0**，成因**已定死**：那 2 条是 `samples/ThirdPartyMini/bin/{Debug,Release}/net10.0/PresentationCore.dll`（副本 `9465f9dce39e2dfc`），而 PC 权威在 `12:19:18` 被**另一条车道**重建为 `21e3e88a5090cd3b` ⇒ 副本 ≠ 权威 ⇒ 按 `check-applocal-sync.sh:440-443` 落 `UNEXPECTED-DIFF`（**更红，不是更绿**）。这是 §0.3 的**环境位移**，不是"撤声明"这个动作的属性；在**无位移**的窗口 W1 里，同一族的改前形态是 `16[EQ=16 DIFF=0]`。
⇒ **副本整份还原**：副本 csproj 由 `cp -p` 覆盖回 `bea59353c18ac8ab`；**真树全程 `bea59353c18ac8ab` 未变**（撤行前后各验一次）。
⇒ 证据留档：`neg_N0.txt` / `neg_N1.txt`；硬链接副本已删除（它与活树共享 inode ⇒ 留着就是"看着像活件的陈旧副本"陷阱），复算命令见 §7.5。

**模型侧（同一副本，与 sha／权威完全无关的因果证明）**：

| 腿 | `expect` | `import_edges` | ThirdPartyMini 的 `#EXPECT` 行数 |
|---|---|---|---|
| 声明在 | **200** | 72 | **10** |
| 声明撤 | **190** | 70（少的那 2 条 = `ThirdPartyMini→WpfLinux.props` 与其下游 `WpfLinux.props→SelfBuiltConfig.props`） | **0** |

⇒ 声明是那 10 条期望的**唯一**来源（撤掉即归零、放回即 10 条）。

### §4.3 自纠一条（**我第一版的缺陷，如实留档**）

第一版 `import_unresolved_repo=5`（`P6` 预判 0，**没命中**）。逐条看：5 条全是 `$(_WpfLinuxWinFXTargets)` / `$(_HelloWpfWinFXTargets)` / `$(_ThirdPartyWinFX)` / `$(_WfpWinFXTargets)` / `$(_WptdWinFXTargets)` —— 它们**在各自 csproj 里就定义成 `$(MSBuildSDKsPath)/…Microsoft.WinFX.targets`**（SDK 侧）。第一版把"值里含 `$` 的属性"整个排除 ⇒ 无法代入 ⇒ 冒充成"本仓接线缺口"（**假缺口**）。修法：允许值含 `$`，并把工程内中转属性**代入两趟**，代入后仍含 `$(` 的一律判"未解析"（**不猜路径**）⇒ `repo=0`、`sdk=41`。
⇒ 这一格值得记：**"自报未解析"这件事本身也会自造假红** —— 分桶错了，"缺口"就变成噪声。

**A/B 独立复核（同一棵树、同一时刻，改前件 vs 最终件）**：两边 `#REFDIR`/`#EXPECT` 投影的差**只有 11 行** ＝ `+1` 个解析源目录（`build/System.Windows.Extensions.Linux/bin/Release`，来自 `WpfLinux.props` 里被新解析的 `<HintPath>`）＋ `+10` 行 ThirdPartyMini 期望 ⇒ **其余 86 个工程的读数逐字未动**。
另：第一版件与最终件的 `#REFDIR`/`#EXPECT` 投影**逐字相同**（`diff` 空）⇒ §4.1 那次改后读数（用第一版件取得）在最终件下同样成立。

---

## §5 除 `ThirdPartyMini` 外那 6 条 `DECL-GAP-EQ`：**不是同族**，且**不因本修法消失**

| # | 路径 | 该工程的声明式输入（现场核） | 副本从哪来（判定） |
|---|---|---|---|
| 1-4 | `build/MilBridge/tests/{ResolverGuardProbe,InputTraceProbe,IcuBreakParity,BboxProbe}/bin/Release[/net10.0]/DirectWrite.Linux.Provider.dll` | 这四个 csproj 的 `<Reference` 计数 **= 0**（无任何声明式引用） | **命令式写点**，不是声明：`build/MilBridge/tests/Directory.Build.targets:21` 的 `<Copy SourceFiles="$(ProviderAuthorityPath)" DestinationFolder="$(OutDir)" SkipUnchangedFiles="false"/>`（`AfterTargets="Build"`）⇒ 属"**拷贝点不在声明图里**"那一族（`D-A1` 的表亲），**不是**"`<Import>` 不可见" ⇒ **不在 `TASK-1002` 射程**。仪器**已经**自报它：`#INVISIBLE-EXT\|write\|build/MilBridge/tests/Directory.Build.targets:21\|<Copy SourceFiles="$(ProviderAuthorityPath)"` |
| 5 | `build/MilBridge/.artifacts/bin/ClosedLoop/release/DirectWrite.Linux.Provider.dll` | `ClosedLoop.csproj` 同样 `<Reference` = **0**；其 `OutDir` 落在 `.artifacts` 下 | 同 #1-4 的 `<Copy>`（`DestinationFolder="$(OutDir)"`） |
| 6 | `build/DirectWrite.Linux/FallbackCriteria/bin/Debug/WpfGfx.Linux.dll` | `FallbackCriteria.csproj` 只有 3 条 `<Reference>`：`PresentationCore` / `WindowsBase` / `DirectWriteForwarder`（`HintPath` 写死 `bin/Debug`） | **传递解析**：全仓**只有 1 个** csproj 声明 `WpfGfx.Linux.dll`（`tests/WpfGfx.Linux.Tests/ManagedLayer.Tests.csproj:117`），`FallbackCriteria` 不在其中 ⇒ 该副本不是它的声明式依赖。**这一条早有登记**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:623-627`（`D-A1`）逐字写着"`FallbackCriteria.csproj` 只有三条 `HintPath`（PC/WB/DWF），**没有** `WpfGfx.Linux` 引用 ⇒ 那份是**传递依赖**被拷进来的 ⇒ 模型看不见这一类"，且明示"**这不是陈旧件、也不许被洗成绿**" ⇒ **本件不碰它**（口径不变）。 |

⇒ 结论：本件把 **`TASK-1002` 那一族（10/16）**消掉；剩下 6 条属**另外两族**（命令式 `<Copy>` 5 条 ＋ 已登记的 `D-A1` 传递副本 1 条），其中 5 条**连"声明"这个语义都不存在**（写点不是声明）⇒ 正确处置是"**让写点进 manifest**"或"**显式登记**"，**不能**靠扩 import 图解决（也不该由本件解决）。
⇒ **红线自查**：本件**没有**为了让 `UNEXPECTED` 归零而扩写白名单／删 `ITEMS`／调小计数；剩下这 6 条**照样红**（`APPSYNC=MISMATCH`、`rc=1`）。

---

## §6 `--selftest` 读数（**必须仍 PASS**）

```
$ bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --selftest
SELFTEST_RC=0
SELFTEST_A=PASS … SELFTEST_P=PASS      （18 例逐例 PASS：A B C D E F G H I J K L L2 M M2 N O P）
SELFTEST=PASS
FAIL/NOINFO 命中数 = 0
```
留档 `$HOME/w70b/evidence/selftest.txt`（含 `SELFTEST_RC=0`）。
⇒ 自带 18 例（含 `D-G62` 跨配置不放行、`D-G8` 权威缺失、`D-A2-r` 桥绝对锚、`L/L2/N` 的 `UNEXPECTED` 三态、`K` 的期望基数不变性）**全部仍然 PASS**：新通道**没有**放宽任何一条既有判据（沙箱夹具都是无 `<Import>` 的合成工程 ⇒ 新通道在自检里是 no-op，这本身也是一条"没有副作用"的旁证）。

---

## §7 复算命令逐条

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; cd $R
# 7.1 声明配置 & 权威表一致性
sed -n '28p' build/SelfBuiltConfig.props
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --list-items | tail -1     # 期望 ITEMS_SYNC=YES
# 7.2 改前基线（把备份件放回即可复算改前口径）
python3 $HOME/w70b/backup/applocal-expect.py.before . . | grep '^#SUMMARY'              # expect=190 …
# 7.3 改后读数（§4.1/§4.3/§6 的现场）
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | grep -E '^计数|^APPSYNC'
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --selftest | tail -2
python3 build/DirectWrite.Linux/wic-shim/applocal-expect.py . . | grep '^#SUMMARY'
python3 build/DirectWrite.Linux/wic-shim/applocal-expect.py . . | grep -E '^#IMPORT\|samples/ThirdPartyMini|^#UNRESOLVED-IMPORT'
python3 build/DirectWrite.Linux/wic-shim/applocal-expect.py . . | grep '^#EXPECT' | grep ThirdPartyMini
APEXPECT_DEBUG=ThirdPartyMini python3 build/DirectWrite.Linux/wic-shim/applocal-expect.py . . 2>&1 >/dev/null | wc -l
# 7.4 判定点（文件:行，改前件）
grep -n 'def project_files\|def subst\|def project_refs\|def refs_of\|def outdirs\|def main\|if not e:\|for name, priv, _ in d\["refs"\]\|<TargetFramework>' $HOME/w70b/backup/applocal-expect.py.before
grep -n 'read -r tag\|EXPECT_OK. = 1 && is_managed\|CNT_DECLGAP_EQ' $HOME/w70b/backup/check-applocal-sync.sh.before
grep -n '<Reference Include' build/third-party/WpfLinux.props          # 76-117：十条 Reference
grep -n 'WpfLinuxBuildConfiguration Condition\|<TargetFramework Condition' build/third-party/WpfLinux.props
grep -n 'third-party/WpfLinux.props' samples/ThirdPartyMini/ThirdPartyMini.csproj
# 7.5 反极性腿（硬链接副本；真树零改动）
rm -rf /tmp/w70b/neg && cp -al $R /tmp/w70b/neg
AUTH_ROOT=/tmp/w70b/neg bash /tmp/w70b/neg/build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | grep -m1 '^计数'   # N0：UNEXPECTED=6[EQ=6 DIFF=0]
python3 - <<'PY'   # 只在副本里撤掉那一行（写新文件再 mv ⇒ 不写穿硬链接）
p="/tmp/w70b/neg/samples/ThirdPartyMini/ThirdPartyMini.csproj"; s=open(p,encoding="utf-8").read()
open("/tmp/w70b/tpm.neg","w",encoding="utf-8").write(s.replace('  <Import Project="$(WpfLinuxRoot)/build/third-party/WpfLinux.props" />\n',''))
PY
mv -f /tmp/w70b/tpm.neg /tmp/w70b/neg/samples/ThirdPartyMini/ThirdPartyMini.csproj
sha256sum $R/samples/ThirdPartyMini/ThirdPartyMini.csproj   # 真树必须仍为 bea59353c18ac8ab
AUTH_ROOT=/tmp/w70b/neg bash /tmp/w70b/neg/build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | grep -m1 '^计数'   # N1：UNEXPECTED=16[EQ=14 DIFF=2]
cp -p $R/samples/ThirdPartyMini/ThirdPartyMini.csproj /tmp/w70b/neg/samples/ThirdPartyMini/ThirdPartyMini.csproj        # 整份还原
rm -rf /tmp/w70b/neg
# 7.6 inputs_fp 覆盖面（静态）
grep -n 'applocal-expect.py\|check-applocal-sync.sh' build/close-wave.sh
# 7.7 本报告自身 sha16（口径 = 去掉最后一行）
cd $R && head -n -1 build/MilBridge/W70B-report.md | sha256sum | cut -c1-16
```

---

## §8 边界 / 未覆盖 / `NOINFO` 清单

**`NOINFO`（取不到就说取不到，不猜）**

1. **`inputs_fp` 的前后数值** = `NOINFO(未取)`。理由：算它要跑 `close-wave.sh`（本件被明令禁止），复刻一份 `fp_inputs()` 就是在本仓再立"第二处逻辑"。给的是**必变**的静态论证 ＋ 两个成员件 before/after sha256（§3.4）。
2. **`build/DirectWrite.Linux/FallbackCriteria/bin/Debug/WpfGfx.Linux.dll` 的写入机制** = `NOINFO(未定)`：已核事实 = 该工程只声明 PC/WB/DWF、全仓只有 `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests.csproj:117` 一处声明 `WpfGfx.Linux.dll`；**未定**的是"究竟是 RAR 传递解析写进去的，还是历史遗留副本"（要定它得跑 `dotnet build` 观测 `ResolveAssemblyReference`，本件禁止构建）。
3. **`MISMATCH/STALE` 逐趟漂移的成因** = `NOINFO(未定，且非本件)`：并发车道在 12:19–12:26 三次改变 PC 权威 sha（`9465f9dce39e2dfc → 21e3e88a5090cd3b → 0d8993521d5517d0`）⇒ 只给"位置"证据，不追到具体车道。
4. **首版 `repo` 桶 5 条**已自纠（§4.3），**当前 = 0**；若将来 `>0`，那是真缺口，`check-applocal-sync.sh` 会逐条点名且明写"不许当绿"。

**边界（有意不覆盖，**并印在输出里**）**

- **隐式导入不跟**：MSBuild 的 `Directory.Build.props` / `Directory.Build.targets` **不跟**（只跟**显式** `<Import>`）。本仓 `build/DirectWrite.Linux/Directory.Build.props:29` 里就有一条 `<TargetFramework>`；"隐式导入要不要跟"是**另一个**语义决定（会给仓内约 120 个工程各注入一个新求值输入）⇒ 本件只把"显式 import 图"这一条做实。
- **只跟 `.props` / `.targets`、且在仓内、且存在**：SDK 侧（`Sdk.props`、`$(MSBuildSDKsPath)/…Microsoft.WinFX.targets`）**按构造不在本图**（`sdk` 桶 41 条，逐条登记、不冒充缺口）。
- **声明归属只对 `<Reference>` 做**：`#EXPECT` 的 `<HintPath>` 链**不**点名被导入件（要逐声明归属得改 `refs_of()` 的返回签名与全部调用点 ⇒ 属更大改动面）；完整、逐条可核的输入是 `#IMPORT` 边清单（72 条）。
- **`$(MSBuildThisFileDirectory)` 的两套口径**：`<Import>` 解析按**声明所在文件**的目录（正确的 MSBuild 语义）；**被并入的声明**里若出现该属性，仍按**工程目录**代入（`subst()` 未改）。实测仓内**没有**被导入件在 `<HintPath>` 里用该属性（`grep '<HintPath>.*MSBuildThisFileDirectory'` 的命中全在 csproj 自己身上）⇒ 今天**无位移**；这是**已知边界**，不是"已穷尽"。
- **模型仍不做工程内属性在"声明通道"上的代入**：`literal_props()` 只喂 `<Import>` 表达式的解析，`subst()` 一字未改 ⇒ `$(Configuration)` 这类既有的 34 条未解析 `HintPath` **原样保留**（改前改后同为 34）。

**"读数与现场相符"的自证**

- 本报告所有读数都在 `$R` 上现场取，留档 `$HOME/w70b/evidence/`（`before.txt` / `after_chk.txt` / `neg_N0.txt` / `neg_N1.txt` / `neg_tool_{present,absent}.txt` / `selftest.txt` / `after_tool4.txt` / `final_chk.txt`）。
- **修法在树上**（不是"只在副本"）：`applocal-expect.py` = `b5dccf135afd6de4`、`check-applocal-sync.sh` = `97d547551846fd13`；`ThirdPartyMini.csproj` = `bea59353c18ac8ab`（未动）、`WpfLinux.props` = `bdc3954b4a129112`（未动）。
- ⚠️ 复算注意：`OK/MISMATCH/STALE` 三格**会随并发车道重建 PC 权威件而漂移**（§0.3）；**判据格** `UNEXPECTED/DECL-GAP-*/MISSING` 与模型 `#EXPECT` 在全部读数里稳定。**跨进程比读数必须同时给时刻与件 sha**。

---

## §9 结论（大白话）

1. **缺陷在哪**：期望模型只读"工程自己那份 csproj"，`<Import>` 进来的接线它**看不见**（`applocal-expect.py` 的 `refs_of/outdirs/E/project_refs` 四处都只吃那一份文本）；`ThirdPartyMini` 恰好**一条引用都不自己写**，全靠 `build/third-party/WpfLinux.props` ⇒ 它的闭包算成空集、被 `if not e: continue` 整个跳过 ⇒ 10 份"内容跟权威一模一样"的副本被报成"多余"，**红**。还有**第二条**容易漏的缺口：连 `net10.0` 都写在被导入件里，而且写的是带条件的形态，原有正则抓不到。
2. **修法**：让模型**跟着真实接线走** —— 解析显式 `<Import>`、把被导入件（剥掉注释后）的声明与工程自写的一视同仁，并如实标出"这条引用是 import 带进来的、出自哪份 props"。**没有**白名单、**没有**删 `ITEMS`、**没有**调小任何计数。
3. **读数**：`UNEXPECTED 16→6`、`DECL-GAP-EQ 16→6`、`OK 128→138`（+10 恰为该样例的 10 份）、`MISSING` 仍 0、`APPSYNC` 仍 `MISMATCH`（别的红一格未动）；`--selftest` **18 例全 PASS、rc=0**。
4. **反极性**：在**整树硬链接副本**里撤掉那行 `<Import>` ⇒ `UNEXPECTED` **回到 16**（模型侧：期望 200→190、该工程的期望行 10→0）；真树自始至终 `bea59353c18ac8ab` 未动。`DECL-GAP-EQ/DIFF` 是 14/2 而非 16/0，成因是**另一条车道在我取证期间重建了 PC 权威件**（sha 三次变化已留档）—— 那 2 条落 `DIFF` 是**更红不是更绿**。
5. **剩下 6 条不是同族**：5 条来自 `Directory.Build.targets` 的**命令式 `<Copy>`**（写点不是声明），1 条是**已登记**的 `D-A1` 传递副本 ⇒ 本件**不碰**、它们**照样红**。
6. **`inputs_fp` 会变，原因就是本件**（改的两份件都在 `close-wave.sh:211-212` 的 `fp_inputs()` 清单里）。

---

**W70B-report.md sha16（口径 = 去掉本行）= `1322a49079f4d2c6`**
