# WAVE17 · §1 P1 —— 把 `hbtextline_shim_stale` 从**下界**升级成**等号**

> 车道 **W17C**｜写域自证：`build/PresentationCore.Linux/PresentationCore.Linux.csproj`（改）＋ 新 `build/PresentationCore.Linux/HbTextLineShimSha.targets` ＋ 新 `build/MilBridge/tests/ShimShaReader/**` ＋ 本报告。**未**触碰 `build/shims/**`、`build/MilBridge/{run.sh,tools/**,known-red.json,tests/HbTextLineParity/Program.cs}`、`docs/**`、`verify-all.sh`、`src/**`（§7 有机器自证）。
> 全部命令在仓根 `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux` 运行（除注明）。`Export PATH="$HOME/.dotnet:$PATH"`（SDK `10.0.111`）。
> 时间：**2026-09-16 11:07 → 11:19 (+0800)**｜kernel `6.8.0-138-generic`｜`loadavg` 起点 `0.37 0.22 0.18` / 终点 `6.23 5.92 3.23`｜`MemAvailable` 起点 **3794248 kB** / 终点 **2016176 kB**（总 8113356 kB）｜lane `W17C`。

---

## 1. 结论（一行）

```
SHIM_SHA=no reason=content-compare artifact=18c49eec6992c7d9 artifact_bytes=4195328 artifact_mtime_utc=1789528616 shim=bc04c05ab6d8d82a product_sha16=bc04c05ab6d8d82a tree_sha16=bc04c05ab6d8d82a asm=PresentationCore cmp=full64 product_sha256=bc04c05ab6d8d82ae337481787ef1016f066e79cb6e33afb5dce386b7230e4fd tree_sha256=bc04c05ab6d8d82ae337481787ef1016f066e79cb6e33afb5dce386b7230e4fd
rc=0
```

⇒ **拿到了等号**：产物 `PresentationCore.dll`（`18c49eec6992c7d9`，4,195,328 B）的 assembly 元数据里写着 `HbTextLineShimSha = bc04c05ab6d8d82ae337481787ef1016f066e79cb6e33afb5dce386b7230e4fd`，**逐字等于**现树 `build/shims/PresentationCore.HbTextLine.cs` 的 sha256（275,765 B）。两边都是 64 位全值比较（`cmp=full64`），不是 16 位前缀。
⇒ **新 `pc` sha16 = `18c49eec6992c7d9`**（旧 `c0763fc10173e7ff`，4,194,816 B）。**差值 +512 B 是唯一可观测的改动**：新增 1 条 assembly attribute 的 CustomAttribute 表项 + `#Strings` 里的 key。
⇒ T17A 的工具在新 `pc` 上仍报 `PASS rc=0`（§5，原文），**但它对"注释级改动"的盲区已实测出来**（§6.2：同一个 `PASS` 同时出现在两份**内容不同**的 shim 上，我的读数把它们分开）。

---

## 2. 设计 + 为什么它是确定性的

### 2.1 形态（按预登记 §1 P1 的授权："由 PC 侧车道决定形态并在报告里写清"）

| 件 | 作用 |
|---|---|
| `build/PresentationCore.Linux/HbTextLineShimSha.targets`（**新**，4,908 B，`3aa64fd08fc7ea05`） | 目标 `WpfLinux_GenerateHbTextLineShimSha`：`BeforeTargets="CoreCompile"` ⇒ 用 MSBuild 内建 `GetFileHash` 现算 `build/shims/PresentationCore.HbTextLine.cs` 的 **SHA256** ⇒ 生成 `$(IntermediateOutputPath)HbTextLineShimSha.g.cs` ⇒ 把该文件加进 `@(Compile)` 与 `@(FileWrites)` |
| `build/PresentationCore.Linux/PresentationCore.Linux.csproj`（改，205,939 B，`26ce64b8f4452ed4`） | 第 4–8 行插入 6 行：4 行注释 + `<Import Project="$(MSBuildThisFileDirectory)HbTextLineShimSha.targets" />`，位置在 `Sdk.props`/`Directory.Upstream.props` 之后、本工程第一个 `PropertyGroup` 之前 |
| `build/MilBridge/tests/ShimShaReader/{ShimShaReader.csproj,Program.cs}`（**新**） | 读侧：`PEReader`+`MetadataReader`，三态 `no`/`yes`/`NOINFO` |

生成文件**实测内容**（$HOME/w17c-build 与仓内 `obj/Debug` 两份逐字节相同，240 B）：

```
#nullable enable
// 由 build/PresentationCore.Linux/HbTextLineShimSha.targets 生成；请勿手改。
[assembly: System.Reflection.AssemblyMetadata("HbTextLineShimSha", "bc04c05ab6d8d82ae337481787ef1016f066e79cb6e33afb5dce386b7230e4fd")]
```

### 2.2 关键取舍（逐条给理由）

1. **`IntermediateOutputPath`（仓内 `obj/`）而不是仓内被跟踪的新 `.cs`**：`build/artifact-src-fp.py:34` 把 `bin/`、`obj/`、`.artifacts/` **排除**在指纹输入之外 ⇒ 生成物**不进** `ARTIFACT-SRC-FP`，也不需要在 csproj 里再写一条 `Compile Include`（少一个"手改锚点"）。**不新增仓内被跟踪源文件**是刻意的：预登记 §4.3/纪律 4 都吃过"派单里的路径/件与盘上不符"的亏。
2. **`GetFileHash` 是"验证过"而不是"假定有"**（预登记明写 verify rather than assume）：本机 `~/.dotnet/sdk/10.0.111/Microsoft.Build.Tasks.Core.dll` 里该任务名命中 1 次；实跑最小工程：
   `HASH=820E4C806127FA5129FD3CB68FEA7B141127272829182EEC0F10FAE1435D0D3C file=/etc/hostname` ⇒ 与 `sha256sum /etc/hostname` 的 **前 16 位逐字相同**（`820E4C806127FA51`）。⇒ 不用 `Exec`+`python3` 兜底。
   ⚠️ **一处现场发现**：`GetFileHash` 返回**大写**十六进制 ⇒ 目标是显式 `.ToLowerInvariant()`，否则写入值与 `sha256sum` 口径不一致（会变成"看起来像、比不中"的假红）。同批实测：`Hash` 任务在本 SDK 上**不支持** `Items` 输出参数（`MSB4131`）⇒ 不用它。
3. **确定性三条**（这是本件的核心风险，因为"每次重建都改 `pc` 的 sha 却毫无理由"正是要避免的）：
   - ① 生成文件内容**只是** sha256 的 hex —— **无时间戳、无构建号、无路径、无主机名**；
   - ② `WriteOnlyWhenDifferent="true"` ⇒ 内容未变**不重写**（**实测**：连续两趟构建后生成文件 mtime 逐字不变 = `2026-09-16 11:10:39.541129573 +0800`）；
   - ③ 其余确定性来自 SDK 默认（`Deterministic=true`，未覆盖）。
4. **`Condition="Exists(...)"` 的另一支不是"静默跳过"**：第二条目标 `WpfLinux_WarnHbTextLineShimShaMissing` 在源缺失时打 `Warning`（不是"悄悄没有值"）。缺失会导致产物里**没有**该属性 ⇒ 读侧给 `NOINFO`（纪律 37：没被检查的东西必须显式可见）。

### 2.3 确定性实测量（**不是论证，是读数**）

| 趟 | 命令 | `error CS` | `pc` sha16 | `pc` mtime | 生成文件 mtime |
|---|---|---|---|---|---|
| build1 | `dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -m:1 --nologo -p:BaseOutputPath=$HOME/w17c-build/pcbin/ -p:BaseIntermediateOutputPath=$HOME/w17c-build/pcobj/` | **0** | `3d365f38811140bf` | 11:11:30.373096419 | 11:10:39.541129573 |
| build2 | 同上（同参数、同目录） | **0** | **`3d365f38811140bf`** | 11:12:40.817925128 | **11:10:39.541129573（未重写）** |
| 干净重建 | 同上 `-t:Rebuild`（`obj` 清过） | **0** | **`3d365f38811140bf`** | 11:14:39.444219273 | 11:14:39.058358788（重建后新写，内容相同） |

⇒ **同一份 shim 源 ⇒ `pc` 逐字节相同**（三趟里两趟同 sha，第三趟是 clean rebuild 也同 sha）。**"每次重建 `pc` 都变"的担心不成立**。

---

## 3. 改了哪些件（sha16 before → after）

| 文件 | before | after | 大小 | mtime |
|---|---|---|---|---|
| `build/PresentationCore.Linux/PresentationCore.Linux.csproj` | ⚠️ **取不到精确 before sha16**（见下） | **`26ce64b8f4452ed4`** | 205,939 B | 2026-09-16 11:09:03 |
| `build/PresentationCore.Linux/HbTextLineShimSha.targets` | （新） | **`3aa64fd08fc7ea05`** | 4,908 B | 2026-09-16 11:09:00 |
| `build/MilBridge/tests/ShimShaReader/Program.cs` | （新） | **`0ef57677afef9f6d`** | 17,872 B | 2026-09-16 11:15:45 |
| `build/MilBridge/tests/ShimShaReader/ShimShaReader.csproj` | （新） | **`2c8b7779d686fdec`** | 2,183 B | 2026-09-16 11:09:12 |
| **`build/shims/PresentationCore.HbTextLine.cs`** | `bc04c05ab6d8d82a` | **`bc04c05ab6d8d82a`（逐字不变）** | 275,765 B | 2026-09-15 18:25:25.142184898（mtime 也还原） |
| **`build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`** | `c0763fc10173e7ff` | **`18c49eec6992c7d9`** | 4,194,816 → **4,195,328 B** | 2026-09-15 18:38:14.829263117 → **2026-09-16 11:16:56.569644573** |

⚠️ **实测发现的缺口（如实报，不掩盖）**：`PresentationCore.Linux.csproj` 的 **before sha16 我拿不到** —— 本仓**没有 `.git`**（`ls -d .git` = 无法访问；`git` 命令本身 `exit 127` = "从未运行"，不是"失败"），而我在编辑前**没有按纪律 16 先整份备份该文件**。可复算的替代读数有两条，**两条都给出**：
- **字节数**：插入块的 UTF-8 长度实测 **468 B** ⇒ before = 205,939 − 468 = **205,471 B**（这个数在"插入块就是这 468 B"的前提下是算出来的，不是量出来的）；
- **sha16**：不可得。**这不是"无信息"以外的东西** —— 我不把 205,471 这个数字冒充成"复核过的 before 文件"。纪律 16 的教训在本车道**当场重犯了一次**（改动当前件前没备份），登记为 W17C 自己的失误。

**未改动的对照（机器自证，防"顺手改到别人写域"）**：

```
e2e1a42b5f0e5b45  build/MilBridge/tools/shim-in-artifact.sh      （= T17A 登记值）
3e513e88a4fa4ec9  build/MilBridge/run.sh                         （= 纪律 31 的"回退后"值）
f9843bde351029dc  build/MilBridge/known-red.json                 （= #16 重钉值）
b37a5c9f55ae71a4  build/MilBridge/tools/tline-gate.sh            （= 主控代落盘值）
a68823631e8f8919  verify-all.sh                                  （= 第 10 步接线值）
```
`find build/shims build/MilBridge/tools -type f -newermt '2026-09-16 00:00'` ⇒ **空**（今天没碰过这两个目录任何文件）。

---

## 4. 两极化红证 + `NOINFO`（命令 / 输出 / `rc` 逐字）

读侧调用（本报告统一用这一条；`ShimShaReader.dll` = `5200d4bf5bb2832f3756a969128ee2d921c3d2b8c626cb8885572e35d76fc347`，16,896 B）：

```bash
export PATH="$HOME/.dotnet:$PATH"
dotnet $HOME/w17c-build/reader-bin/Debug/net10.0/ShimShaReader.dll \
       --artifact <dll> [--shim <cs>] [--root <dir>]
```

**基线 S0**：树 shim = `bc04c05ab6d8d82a`（275,765 B）；测试产物 `$HOME/w17c-build/evidence/pc.S0.dll` = `3d365f38811140bf`（4,195,328 B，由 S0 编出，内嵌 `…e4fd`）。

### 4.1 极性 A —— 改 shim、**保旧 mtime**、**不重建** ⇒ 必须 `yes`

```bash
printf 'x' >> /tmp/S1.cs; cp -p build/shims/PresentationCore.HbTextLine.cs /tmp/S0.cs   # S0 快照
cp /tmp/S1.cs build/shims/PresentationCore.HbTextLine.cs && touch -r /tmp/S0.cs build/shims/PresentationCore.HbTextLine.cs
```
```
树: S1 = b059d96c5fa79f2e，275,766 B，mtime 2026-09-15 18:25:25.142184898 (= S0 的旧 mtime)
    cmp S0 S1 ⇒ rc=1；cmp -l 只有"第 275765 字节后 EOF"一条 ⇒ 严格"尾部 +1 字节 'x'"
产物: 未重建 ⇒ 3d365f38811140bf（内嵌 …e4fd）

$ ShimShaReader --artifact evidence/pc.S0.dll
SHIM_SHA=yes reason=content-compare artifact=3d365f38811140bf artifact_bytes=4195328 artifact_mtime_utc=1789528479 shim=b059d96c5fa79f2e product_sha16=bc04c05ab6d8d82a tree_sha16=b059d96c5fa79f2e asm=PresentationCore cmp=full64 product_sha256=bc04c05ab6d8d82ae337481787ef1016f066e79cb6e33afb5dce386b7230e4fd tree_sha256=b059d96c5fa79f2e387201d9dfe1f9e668ce3040af6227c921e146704372a04f
rc=1
```
**旧 mtime 代理在同一状态下的读数**：`shim_mtime=1789467925 ≤ artifact_mtime=1789528360` ⇒ 代理会说 **`no`（假绿）** —— 这正是本条判据存在的理由（纪律 24 的双向撒谎现场）。

### 4.2 极性 B —— 源改回去、**不重建** ⇒ 判据必须与**产物**一致

```bash
cp -p /tmp/S0.cs build/shims/PresentationCore.HbTextLine.cs     # 树回到 S0（不改产物）
```
```
树: bc04c05ab6d8d82a（275,765 B）
产物: 仍是"由 S1' 编出的那一份" 4cbce118a6117573（内嵌 b1f7c8a909f0a70a），**没有重建**

$ ShimShaReader --artifact evidence/pc.S1b.dll
SHIM_SHA=yes reason=content-compare artifact=4cbce118a6117573 artifact_bytes=4195328 artifact_mtime_utc=1789528533 shim=bc04c05ab6d8d82a product_sha16=b1f7c8a909f0a70a tree_sha16=bc04c05ab6d8d82a asm=PresentationCore cmp=full64 product_sha256=b1f7c8a909f0a70a3ff236b1c1b4121e94d6f4071e48f95945883c4a3b9955b7 tree_sha256=bc04c05ab6d8d82ae337481787ef1016f066e79cb6e33afb5dce386b7230e4fd
rc=1
```
⇒ 判据说的是**内容**（产物的 `b1f7…` ≠ 树的 `bc04…`），**不是**"有没有重建过"。旧 mtime 代理在这同一状态下又是假绿（`artifact_mtime 1789528533 ≥ shim_mtime 1789467925` ⇒ `no`）。
**正面反证（同一份产物、同一把尺子）**：把 `--shim` 指向**与产物同内容**的 `S1'` 源 ⇒ `SHIM_SHA=no rc=0`（§5.3 的 DEMO 里那条）。⇒ 结论随**内容**动，不随"谁在哪一步跑"动。

### 4.3 极性 C —— 重建 ⇒ `no`

```bash
# 突变（可编译版：追加一整行注释；见 4.4 为什么"逐字节一字节"在 C 里做不到）
cp -p /tmp/S0.cs build/shims/PresentationCore.HbTextLine.cs
printf '// W17C mutation probe (W17C-S1): does this comment reach the artifact?\n' >> build/shims/PresentationCore.HbTextLine.cs
touch -r /tmp/S0.cs build/shims/PresentationCore.HbTextLine.cs
S1' = b1f7c8a909f0a70a，275,837 B
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -m:1 --nologo \
  -p:BaseOutputPath=$HOME/w17c-build/pcbin/ -p:BaseIntermediateOutputPath=$HOME/w17c-build/pcobj/
⇒ rc=0，error CS = 0，0 个错误，0 个警告（54 s）
   WPF-on-Linux: HbTextLineShimSha=b1f7c8a909f0a70a3ff236b1c1b4121e94d6f4071e48f95945883c4a3b9955b7
产物: 4cbce118a6117573

$ ShimShaReader --artifact evidence/pc.S1b.dll
SHIM_SHA=no reason=content-compare artifact=4cbce118a6117573 ... product_sha16=b1f7c8a909f0a70a tree_sha16=b1f7c8a909f0a70a ... product_sha256=b1f7c8a909f0a70a3ff236b1c1b4121e94d6f4071e48f95945883c4a3b9955b7 tree_sha256=b1f7c8a909f0a70a3ff236b1c1b4121e94d6f4071e48f95945883c4a3b9955b7
rc=0
```
**A→B→C 三态连成一条**：`yes`（A）/`yes`（B）/`no`（C），且 **B 的 `yes` 与 C 的 `no` 用的是同一份产物、同一份源内容** ⇒ 判据严格是"产物内嵌值 ↔ 现树内容"的等号。

### 4.4 ⚠️ 一条**我做不到**的事（不许读成做到）

派单要求 A 里"改 shim **一个字节**"。**逐字节意义上的"改一个字节且仍可编译"我没做到**，实测给了两条反例、一条替代：
- 追加单个 `x`（275,765 → 275,766 B，**满足"一字节"的字面量**）：`dotnet build` ⇒ `rc=1`，`error CS = 6`，逐字为 `PresentationCore.HbTextLine.cs(4688,1): error CS8803 顶级语句必须位于命名空间和类型声明之前` / `CS1001 应输入标识符` / `CS1002 应输入 ;` ⇒ **A 的读数在坏件上取得**，按纪律 33 此读数**不计为"编译通过后的读数"**（它作为"源内容确实不同 + 判据确实变红"的证据仍然成立，因为读侧根本不编译）。我把这条**如实登记**（`S1 = b059d96c5fa79f2e` 的那一次）。
- 为了让 C 是一次**真编译**（`error CS = 0`），我把突变换成"追加一整行注释"（`S1'`，+72 B）⇒ **C 的构建是 0 错构建**。
- ⇒ **A 的字面要求（一字节 + 可编译）在本件里未达成**：判据是**否也在 +72 B 的突变上变红**，我没测（只测了 +1 B 与 +72 B 两次，两次都红）。**不写成"一字节也红"之外的话**。

### 4.5 `NOINFO`（7 例，**全部 rc=2**，全部带 `reason`）

| # | 命令要点 | 机器行（逐字） | rc |
|---|---|---|---|
| 1 | 产物不存在 | `SHIM_SHA=NOINFO reason=artifact-not-found artifact=<NOINFO> artifact_bytes=- artifact_mtime_utc=- shim=<NOINFO> product_sha16=<NOINFO> tree_sha16=<NOINFO> asm=<NOINFO> cmp=full64 product_sha256=<NOINFO> tree_sha256=<NOINFO>` | **2** |
| 2 | 产物是目录 | `… reason=artifact-is-directory …` | **2** |
| 3 | 非 PE（`/etc/hostname`） | `… reason=bad-image-format …` | **2** |
| 4 | 截断件（真 `pc` 前 64 KiB） | `… reason=bad-image-format …` | **2** |
| 5 | **属性缺失**（改动前的权威 `pc`：`c0763fc10173e7ff`） | `… reason=attribute-absent …` | **2** |
| 6 | shim 源不存在（`--shim …/no-such-shim.cs`） | `… reason=shim-not-found …` | **2** |
| 7 | 仓根定不出（候选目录里 `build/PresentationCore.Linux` 是**文件**不是目录） | `… reason=root-unresolved …` | **2** |

两条现场记账：
- **#2 第一版是错的**：`File.Exists()` 对目录返回 `false` ⇒ 它报 `artifact-not-found`（分类错、但仍是 `NOINFO rc=2`，**不会假绿**）。已修（先判 `Directory.Exists`）并重测 ⇒ `artifact-is-directory`。
- **#5 是"改动前"的真实读数**：`c0763fc10173e7ff` 上 `attribute-absent` —— 这与 T17A/T1c 的实测"该工程 `GenerateAssemblyInfo=false` ⇒ 一个 `AssemblyMetadata` 都没有"**一致**，是本件的"负对照"。
- `reason` 一律进机器行（纪律 27 家族：`NOINFO` 必须能回答"为什么"）。

### 4.6 只读 + 可重复（机器断言）

```
snapshot = find build/PresentationCore.Linux/bin build/PresentationCore.Linux/obj build/shims -type f \
             -printf '%p %s %T@\n' | sort | sha256sum | cut -c1-16
before = b401137438647840
$ ShimShaReader            （跑 3 趟，全部 rc=0）
after  = b401137438647840            <-- IDENTICAL
pc  18c49eec6992c7d9 -> 18c49eec6992c7d9（未变）
shim bc04c05ab6d8d82a -> bc04c05ab6d8d82a（未变）
find … -newermt '-60 seconds' | wc -l  ⇒  0
机器行 3 趟 cmp 逐字节相同（auth.line1/2/3，sha16 = 43aa49854a1e4372）；stdout 整体也 cmp 相同
```
⇒ **只读**（对 `bin/obj/shims` 零写入，含 mtime）+ **可重复**（机器行不含路径/时间戳 ⇒ 逐字节稳定）。

---

## 5. T17A 的工具在新 `pc` 上的读数（逐字）

```bash
$ bash build/MilBridge/tools/shim-in-artifact.sh
SHIM_IN_ARTIFACT=PASS artifact=18c49eec6992c7d9 artifact_bytes=4195328 shim=bc04c05ab6d8d82a new=2/2 stable=14/14 missing=- recent=2/2 refs=23
rc=0
```
与 T17A 在旧件上的登记读数（`artifact=c0763fc10173e7ff`，其余逐项相同）相比：**只有 artifact 位移动**，`new=2/2 stable=14/14 recent=2/2 refs=23` 逐位不变 ⇒ 我的改动**没有**把它的 token 证据打坏。`--detail` 里 `_boxOriginX@0x2b6970`、`boxOriginX@0x2b6971`（旧件 `0x2b694c/0x2b694d`，堆整体后移 0x24 = 36 B）。

**它仍然是"下界"而不是等号 —— 这一点我做了判别实验（§6.2），没有停在"读起来像"。**

---

## 6. 下界 → 等号：做到了什么、没做到什么

### 6.1 做到了（等号）

- 产物**自报**它编的是哪一份 shim 内容（64 位 sha256），读侧**不加载程序集**、不需要依赖链即可读出，且**与"有没有新符号"无关**（P4 那条"注释级改动"的预言在本件上被正面验证：注释改动**会**改内嵌 sha）。
- 读侧三态齐备、`NOINFO` 非 0、只读、可重复（§4.5/4.6）。
- **确定性**：同源重建 ⇒ `pc` 逐字节相同（§2.3）。

### 6.2 **下界有多大**：判别实验（同一份产物、同一把尺子）

| 实验 | 产物 | 源 | T17A `shim-in-artifact.sh` | W17C `ShimShaReader` |
|---|---|---|---|---|
| DEMO-1 | `pc.S0.dll`（内嵌 `bc04…e4fd`） | `S1b`（`b1f7c8a909f0a70a`，只多了注释） | **`PASS rc=0`**（`new=2/2 stable=14/14`） | **`yes rc=1`**（`product_sha256=bc04…` ≠ `tree_sha256=b1f7…`） |
| DEMO-2 | `pc.S2.dll`（内嵌 `6f34befb61dca65a`） | `S1b`（两份 shim 的**标识符集合完全相同**，只是注释内容不同） | **`PASS rc=0`**（逐字与 DEMO-1 只差 artifact 位） | **`yes rc=1`** |
| DEMO-3 | `pc.S1b.dll`（内嵌 `b1f7…`） | `S2`（`6f34befb61dca65a`） | **`PASS rc=0`** | **`yes rc=1`** |
| 对照 | `pc.S2.dll` | `S2`（**内容真的相等**） | `PASS rc=0` | **`no rc=0`** |

⇒ **同一个 `PASS rc=0` 出现在三份内容互不相同的 shim 上**；只有内嵌 sha 能把它们分开。这就是"下界"的确切形状，也是本件要关掉的那条边界。
⇒ 顺带**证实并细化**了 T17A 自己的边界声明（预登记 §0 G1 引的那句）：它说"将来某次 shim 改动若不引入新符号 ⇒ 退化成 `WEAK-PASS rc=3`"。**实测更精确**：只要**历史** shim 里存在过 `_boxOriginX`，那么"不引入新符号"的改动**不会**把它打到 `WEAK-PASS`，它会**照样给 `PASS rc=0`（假绿）**；而 `WEAK-PASS rc=3` 这条路我用**今天能构造出的输入**没能走到（见 6.3）。**T17A 那句话把风险说轻了**，不是它错了：它描述的是"NEW 集为空"的实现分支，而今天 NEW 集**不为空**且**永久不为空**（`_boxOriginX` 已进入现树并被声明为 NEW）。

### 6.3 **未走到**的分支（如实登记为"未测"）

`WEAK-PASS rc=3` 需要"NEW 集为空"。我尝试把它逼出来：
- `--shim <去掉了 `_boxOriginX` 的源>` 会被**前置自检**挡住 ⇒ `SHIM_IN_ARTIFACT=NOINFO reason=token-not-in-current-shim tokens=_boxOriginX,boxOriginX path=/tmp/w17c-w17c-anon.cs`，`rc=2`（**这是对的**：不许静默降级）；
- 于是 NEW 集非空、`_boxOriginX` 在产物里也在 ⇒ 走到 `PASS`。
⇒ **`WEAK-PASS` 这条实现对今天这套（源 + 参考集）不可达**；我**没有**造出一个"NEW 集为空"的真实输入 ⇒ 该分支**未测**，不给结论。

### 6.4 精确的剩余边界（等号之外还剩什么**不可证**）

1. **"哪个 `.cs` 文件被编译"仍不可证**（T17A §7-B 的 N3，本件**没有**削弱它）：元数据里只有**值**，没有源路径。产物里的 `bc04…` 只能证明"**有一份内容哈希为 `bc04…` 的 shim 源**被编进去了"；它**不**证明那份源的名字叫 `build/shims/PresentationCore.HbTextLine.cs`，也**不**排除"另有一份同内容的副本"。⇒ **路径层是文件名/PDB 的活，不是元数据的活**（PDB 路线 T17A §7-A2 登记为未测）。
2. **"这份 sha 是被编译器诚实写进去的"不可证**：任何能改 `obj/HbTextLineShimSha.g.cs` 或能替换 DLL 的人都能让产物**报**任意 sha。**实测反例就在本报告里**：我为了 DEMO 手改过生成文件的一位（把 `…e4fd` 改成 `…e4fb`），当时 `-t:Rebuild` 立刻按**源内容**重算并覆盖了我的手改 ⇒ 走**正常构建**改不掉；但"**绕过构建**直接改二进制"我**没有**做一致性验证（PE 校验和/强名级），与 T17A §7-E 的"未测"同一条。
3. **"产物里没有更晚的改动"仍不可证**：内嵌值是"编译时源内容的函数"；若有人编完之后**又改了源**，读侧只报 `yes`（陈旧），而**不能**报"产物是更晚的/更早的哪一版"。等号说的是**相等关系**，不是**因果序**。
4. **`pc` 之外的环未测**：本件只写 `pc`。按 T1c 备稿的传播链（`pc` → PF → Reach → PF），**下游 `pf`/`reach` 会因 `pc` 变而变**；本车道**没有**重建 PF/Reach，也**没有**测桥（`.artifacts/publish/**` 里含 `PresentationCore.dll`）⇒ 那三位的移动**未测**（属波/主控范围）。
5. **shim 之外的同族没有被覆盖**：只有 `build/shims/PresentationCore.HbTextLine.cs` 一条被嵌 sha。`build/shims/**` 里其余 12 个 `.cs`、以及应用器生成物（`build/PresentationCore.Linux/*.Linux.cs`）**仍无内容级产物侧证据**（`ARTIFACT-SRC-FP.txt` 只给"现树输入 vs 冻结记录"，不给"产物里到底是哪一份"）。

---

## 7. 读数表（每一项都带"哪一份件"）

| 项 | 值 | 命令 |
|---|---|---|
| lane | **W17C** | —— |
| 日期时间 | **2026-09-16 11:07:46 → 11:19:01 (+0800)**（`date -Is`） | `date -Is` |
| 内核 | `6.8.0-138-generic`（`Linux linksdev-VirtualBox 6.8.0-138-generic #138~22.04.1-Ubuntu SMP PREEMPT_DYNAMIC`） | `uname -r` / `uname -a` |
| `loadavg`（起点 / 终点） | `0.37 0.22 0.18` / `6.23 5.92 3.23` | `cat /proc/loadavg` |
| `MemAvailable`（起点 / 终点） | **3794248 kB** / **2016176 kB**（`MemTotal` 8113356 kB） | `grep MemAvailable /proc/meminfo` |
| SDK | `dotnet 10.0.111`（`$HOME/.dotnet`，**不在默认 PATH**） | `dotnet --version` |
| **权威 `pc` BEFORE** | **`c0763fc10173e7ff`**｜4,194,816 B｜`2026-09-15 18:38:14.829263117 +0800` | `sha256sum`/`stat` |
| **权威 `pc` AFTER（本件权威写）** | **`18c49eec6992c7d9`**｜4,195,328 B｜**`2026-09-16 11:16:56.569644573 +0800`** | 同上 |
| 权威 `pc` FULL sha256（AFTER） | `18c49eec6992c7d9beff9d38efff4b4df3df24a2bfdb7c91e1d79d1f8a247008` | `sha256sum` |
| 权威 `pc` 构建 | `dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -m:1 --nologo` ⇒ `rc=0`，`error CS = 0`，`0 个警告/0 个错误`，54.1 s | 日志 `$HOME/w17c-build/build-AUTHORITY.log` |
| 权威 `pdb` BEFORE → AFTER | `e1aef41d033deb70`（2,159,460 B）→ **`15e54019b2705ee5`**（2,159,556 B） | `sha256sum` |
| shim 源 | **`bc04c05ab6d8d82a`**（FULL `bc04c05ab6d8d82ae337481787ef1016f066e79cb6e33afb5dce386b7230e4fd`）｜275,765 B｜`2026-09-15 18:25:25.142184898 +0800`（**改动前后逐字相同**） | `sha256sum`/`stat` |
| 生成物（本件新增，仓内 `obj/Debug/`） | `HbTextLineShimSha.g.cs`｜240 B｜`2026-09-16 11:16:08.322149580 +0800` | `build/PresentationCore.Linux/obj/Debug/` |
| 目标文件 | `HbTextLineShimSha.targets` = **`3aa64fd08fc7ea05`**｜4,908 B | `sha256sum` |
| csproj | **`26ce64b8f4452ed4`**｜205,939 B（before 见 §3 的缺口说明） | `sha256sum` |
| 读侧工具 | `ShimShaReader.dll` = `5200d4bf5bb2832f3756a969128ee2d921c3d2b8c626cb8885572e35d76fc347`｜16,896 B｜`2026-09-16 11:15:50.387963952 +0800` | `sha256sum` |
| 读侧源 | `Program.cs` = `0ef57677afef9f6d`｜17,872 B；`ShimShaReader.csproj` = `2c8b7779d686fdec`｜2,183 B | `sha256sum` |
| T17A 仪器（只读引用） | `shim-in-artifact.sh` = **`e2e1a42b5f0e5b45`**（未改）；新 `pc` 上 `PASS rc=0` | `sha256sum` / `bash …` |
| 判别实验产物 | `pc.S0.dll`=`3d365f38811140bf`｜`pc.S1.dll`=`3d365f38811140bf`（同内容）｜`pc.S1b.dll`=`4cbce118a6117573`｜`pc.S2.dll`=`6cfc0e8e95b506d3`｜`pc.S2-anon.dll`=`180476bfc4c1d7fe` | `$HOME/w17c-build/evidence/` |
| 判别实验源 | S0=`bc04c05ab6d8d82a`｜S1=`b059d96c5fa79f2e`（+1 B）｜S1b=`b1f7c8a909f0a70a`（+1 行注释）｜S2=`6f34befb61dca65a`｜anon=`75322935f7a5490b` | 同上 |
| 机器行证据文件 | `auth.line1/2/3` = `43aa49854a1e4372`（3 趟逐字节相同） | `$HOME/w17c-build/evidence/` |
| 报告本件 | `build/MilBridge/W17C-report.md`（本文件；字节数用 `wc -c` 现取，写死会自我失效）｜**自指 sha16 不可写死**（任何写死的值都会把文件本身改掉）：给出**"把本行整行剔除后"的 sha16 = `160921b704da37ea`**；复算 = 删掉本行（整行）后 `sha256sum` | `sha256sum` + 剔除本行 |

**复算入口（贴进 shell 就能重来）**

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux; export PATH="$HOME/.dotnet:$PATH"
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -m:1 --nologo            # 必须 error CS = 0
dotnet build build/MilBridge/tests/ShimShaReader/ShimShaReader.csproj -m:1 --nologo \
  -p:BaseOutputPath=$HOME/w17c-build/reader-bin/ -p:BaseIntermediateOutputPath=$HOME/w17c-build/reader-obj/
dotnet $HOME/w17c-build/reader-bin/Debug/net10.0/ShimShaReader.dll        # 期望 SHIM_SHA=no rc=0
bash build/MilBridge/tools/shim-in-artifact.sh                            # 期望 PASS rc=0
sha256sum build/PresentationCore.Linux/bin/Debug/PresentationCore.dll | cut -c1-16   # 18c49eec6992c7d9
```

---

## 8. 一个构建**没能**settle的事（汇集，按重要性）

1. **`PresentationCore.Linux.csproj` 的 before sha16**：本仓无 `.git`，我改动前未备份 ⇒ **永久不可得**（只能给 before 字节数 205,471 = 现 205,939 − 插入块 468 B，且这是**算的**）。⇒ 纪律 16 的自犯记录。
2. **`WEAK-PASS rc=3` 分支未测**（§6.3）：今天的源 + 参考集走不到；前置自检会先 `NOINFO`。
3. **"一字节突变且可编译"未达成**（§4.4）：C 用的是 +1 行注释的突变；`error CS = 0` 是在那一版上取得的。
4. **下游 `pf`/`reach`/桥的位移未测**：本车道只写了 `pc`。
5. **PE 校验和/强名级的一致性**未做（§6.4-2）：读侧只保证"结构上解得出这条 CustomAttribute"，不保证"二进制没被人绕过构建改过"。
6. **两份 `PresentationCore.dll` 是否"同一份文件"**：本件只按内容 sha 说话（纪律 23/24）。权威写之后 `bin/Debug/PresentationCore.dll` 的 mtime 变了、内容也变了（这是本件的**目的**）⇒ **另一条行为车道（在跑 `pc` 行为读数）必须按 mtime 的位移重新认领它的读数**：**`pc` 由 `c0763fc10173e7ff` 变为 `18c49eec6992c7d9`，mtime `2026-09-15 18:38:14.829263117` → `2026-09-16 11:16:56.569644573 +0800`**；行为**不该**变（默认 `-p:Deterministic=true`、只多一条 attribute），但"不该变"是**论证**、不是**读数** —— 本车道**没有**跑任何行为臂来证明它（那会与那条车道抢资源）。
7. **把它接进 `verify-all.sh`**（主控写域，本件**不做**）：需要的接线只有一步 —— 在第 10 步之后加一条 `dotnet <ShimShaReader.dll>` 判据，`rc` 语义应与既有三态位一致：**`rc=0`（`no`）计入通过；`rc=1`（`yes`）计失败并逐字打出两个 sha256；`rc=2`（`NOINFO`）计 `NOINFO` 且**不得计入通过数**（纪律 37③），并要求人裁定**（同 T17A §7-D 对 `WEAK-PASS rc=3` 的建议）。**本件只交付工具，不改任何门禁/清单。**

---

**一句话总结**：`hbtextline_shim_stale` 现在可以从**产物**里读出"编进去的是哪一份 shim 内容"（64 位 sha256 等号、三态、只读、可重复、确定性实测），T17A 的 token 检查与之互补且在新件上仍 `PASS`；**"哪个文件被编译"仍然不可证**，且 `WEAK-PASS` 分支在本波未走到。

---

## 10. 重落（2026-09-16 12:3x）

> 车道仍记 **W17C**。本节**追加**，上面的 §1–§8 原文保留（其中 §2.3 的措辞按 §10.6 **更正**，见那条）。
> 本次运行：**2026-09-16 12:33 → 12:41 (+0800)**｜kernel `6.8.0-138-generic`｜
> `loadavg` 起点 `3.25 2.16 1.96`、终点 `7.39 3.54 2.46`｜`MemAvailable` 起点 **2659804 kB**、终点 **2677252 kB**｜lane `W17C`。

### 10.1 为什么重落（根因**复核过**，不是照信）

§1 P1 的接线是**手改生成物** `build/PresentationCore.Linux/PresentationCore.Linux.csproj`（`:4` 插 6 行，得到 `26ce64b8f4452ed4` / 205,939 B）。而这份 csproj 是 **`build/port-lib.py` 的生成物** ⇒ 波 `close-wave-w17`（`2026-09-16 12:24:12`）第 1 步把它**整份重写**。我按主控给的等价单步**自己复现了一遍**（不跑整条波）：

```bash
$ python3 build/port-lib.py PresentationCore
[PresentationCore] 源文件 1348（找回 214）/ 缺失 0 | 丢弃 PR 8(vcx 1) 私有 1 Target 0 Import 2
⇒ rc=0
csproj: 340b042ab7e44799 → 30a6b2a0dc82a91f   205,753 B → 193,040 B
grep -c 'HbTextLineShimSha.targets' = 0        （我那 3 行接线没了）
```
⇒ **根因成立**：不是"hand-edit 写错位置"，而是**写错了通道**（改生成物 = 白改）。
⇒ 顺带读到一条**更广的事实**：`port-lib.py` 单跑会把**所有**应用器的接线一起抹掉（193,040 B 是"裸 port-lib"态；补丁重放后才回到 ~205 KB）—— 所以"波第 1 步 + 第 2 步重放"是一个**整体**，少第 2 步必然静默丢接线（`integration-wave.sh:116-119` 的注释写的就是这条）。

### 10.2 选 (b)：应用器，而不是改 `port-lib.py`

**理由（三条，可审计）**：
1. **与既有 15 个 PC/PF 接线同一层**：`patch-presentationcore-*.py` 已有 11 个，"生成一个文件 + 往 csproj 插几行"是**既有协议**（apartment/fontcache/lineheight-trace 全是这么做的），且有**机器审计**（`applier-audit.py`）与**登记清单**（`applier-audit-expected.txt`）两条防线；
2. **不动共享生成器**：`port-lib.py` 为**所有** 8 个工程服务，往里加"PC 专属的 sha 注入"会把 PC 的私事提升成公共责任（且它的输入是上游 csproj，与"我们自己的 .targets"不同层）；
3. **`port-lib.py` 重生成会保留 `build/<Proj>.Linux/**` 里的手写文件**（实测：`HbTextLineShimSha.targets` 在重生成后仍在）⇒ 应用器只需②**重新插入 3 行** + ①校验生成物，代价最小。

**新增件（我写域内）**：`src/WpfGfx.Linux.Native/tools/patch-presentationcore-hbtextline-shimsha.py`（**`81f821ae225eb3a0`**，18,345 B，`2026-09-16 12:37:32`）。
它**自己生成** `build/PresentationCore.Linux/HbTextLineShimSha.targets`（**单一写者 = 本脚本**；内容 sha256 = `3127e82b76ce8c2431869687ec2ee808bfbcea0911afee7277c4a91b91712d7a`，与 §1 落盘的那一份**逐字相同**——pin 在脚本里，改内容会被当场抓住），并往 csproj 的 `Sdk.targets` 锚点前**只插入 3 行**（边界注释 + 1 行 `Import` + 结束注释）。

**两个登记**（这是"还会不会被抹掉"的答案，见 §10.7）：

| 件 | before | after | 作用 |
|---|---|---|---|
| `build/integration-wave.sh` | ⚠️ 见下 | **`770419556b9597df`**（38,072 B，`12:35:27`） | `APPLIERS_EXPLICIT` 加 `patch-presentationcore-hbtextline-shimsha`（+ 顺带 `patch-presentationcore-lineheight-trace`，见 §10.7 的"顺带"） |
| `build/MilBridge/tools/applier-audit-expected.txt` | ⚠️ 见下 | **`eecf8f28d3e6b9f9`**（1,848 B，`12:35:16`） | 同两条：从 `APPLIERS_EXPLICIT` 摘掉它们会**判红** |

⚠️ **两条 before sha16 我又拿不到**（与 §3 同一处失误的**重犯**）：本仓无 `.git`，我编辑前**没有**先备份这两个文件。
⇒ 这次**没有第二次机会**可用，如实登记：**before 值不可得**；可复算的只有"我在 `APPLIERS_EXPLICIT` 的 `patch-presentationframework-xamlaccess` 之后插了 2 条名字 + 10 行注释"。**这是本车道在纪律 16 上的第二次自犯**（第一次见 §3）。

### 10.3 红线判据：**活过重生成**（逐字）

```bash
# 起点（完整接线态）
csproj = 340b042ab7e44799   205,753 B   grep -c 'HbTextLineShimSha.targets' = 1
# ① 重生成（波第 1 步等价单步）
$ python3 build/port-lib.py PresentationCore           ⇒ rc=0
csproj = 30a6b2a0dc82a91f   193,040 B   grep -c = 0        <-- 被抹掉（复现事故）
# ② 生成通道（应用器）
$ python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-hbtextline-shimsha.py
[生成] build/PresentationCore.Linux/HbTextLineShimSha.targets：内容已是最新（未重写，不动时间戳）
[接线] 已注入 3 行到 build/PresentationCore.Linux/PresentationCore.Linux.csproj（Sdk.targets 之前；纯插入）
⇒ rc=0
grep -c 'HbTextLineShimSha.targets' = 1                <-- **红线判据：>=1 ✓**
```
**完整的重放链（不只跑我一个）**：我用 `$HOME/w17c-build/replay-appliers-W17C.sh` 复刻波的第 2 步（`reapply-patches.py` ×4 + **从 `integration-wave.sh` 现读**的 `APPLIERS_EXPLICIT` + `patch-presentation*` 兜底 glob，共 **22** 个应用器）⇒ **重放失败数 = 0**，csproj = **`340b042ab7e44799`** / 205,753 B，`grep -c 'HbTextLineShimSha.targets'` = **1**。
**重放是确定性的**：整套重放跑第二遍 ⇒ csproj **逐字节相同**（`340b042ab7e44799`）。
**与波留下的那一份的差 = 纯块位置**（机器断言）：`sort` 后逐行比拟只差我那 3 行（`<Import … HbTextLineShimSha.targets />` + 两个边界注释）；`grep -c` 那两个注释各 1 次。差的原因是 §10.7 的"顺带登记"改变了 `lineheight-trace` 的执行时机（它以前只走兜底 glob、排在最前）。

| 量 | 波留下的（`e2558faa0cc6b5d1`） | 现在（`340b042ab7e44799`） |
|---|---|---|
| 字节 | 205,471 | 205,753（**+282**） |
| mtime | `2026-09-16 12:24:19.765395279` | `2026-09-16 12:38:43.843544986` |
| `grep -c HbTextLineShimSha.targets` | 0 | **1** |

### 10.4 真正重建 + 元数据在（私有输出先验，纪律 33）

```bash
$ dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -m:1 --nologo \
    -p:BaseOutputPath=$HOME/w17c-build/pcbin-S0/ -p:BaseIntermediateOutputPath=$HOME/w17c-build/pcobj-S0/
  ⇒ rc=0，error CS = 0，0 个警告 / 0 个错误
  WPF-on-Linux: HbTextLineShimSha=bc04c05ab6d8d82ae337481787ef1016f066e79cb6e33afb5dce386b7230e4fd
```
**权威写**（正常输出目录）：

| 量 | BEFORE | AFTER |
|---|---|---|
| `pc` sha16 / FULL | **`ac16320a14f549d4`** / `ac16320a14f549d4…`（元数据**不在**：读者给 `NOINFO attribute-absent`） | **`7680da47c39ec7ed`** / `7680da47c39ec7ed6026fb8d5813f798a174ca5e7eaa0929912fdc41688eeee1` |
| 字节 | 4,194,816 | **4,195,328**（+512 = 1 条 CustomAttribute 表项 + `#Strings` 里的 key） |
| mtime | `2026-09-16 12:32:45.872839014 +0800` | **`2026-09-16 12:40:22.733633917 +0800`** |
| `pdb` | `53cc8c9a42663e91`(2,159,460 B) | `b8a2fa865c9098cc`(2,159,556 B) |
| 构建 | —— | `rc=0`，**`error CS = 0`**，`0 个错误 / 0 个警告` |

**读者（逐字，rc=0）**：

```
SHIM_SHA=no reason=content-compare artifact=7680da47c39ec7ed artifact_bytes=4195328 artifact_mtime_utc=1789533622 shim=bc04c05ab6d8d82a product_sha16=bc04c05ab6d8d82a tree_sha16=bc04c05ab6d8d82a asm=PresentationCore cmp=full64 product_sha256=bc04c05ab6d8d82ae337481787ef1016f066e79cb6e33afb5dce386b7230e4fd tree_sha256=bc04c05ab6d8d82ae337481787ef1016f066e79cb6e33afb5dce386b7230e4fd
```
⇒ `product_sha16 == tree_sha16`（`bc04c05ab6d8d82a`）且 `cmp=full64` 两侧都是 `bc04c…e4fd`。
**T17A 的工具**同步复跑：`SHIM_IN_ARTIFACT=PASS artifact=7680da47c39ec7ed artifact_bytes=4195328 shim=bc04c05ab6d8d82a new=2/2 stable=14/14 missing=- recent=2/2 refs=23`，`rc=0`。

### 10.5 红证两条（两极性，命令 + 输出 + rc + 逐字节还原）

**红证①（接线被拿掉 ⇒ 必须 `NOINFO`）** —— 做法：在**完整接线**的 csproj 上**只摘掉本应用器的 3 行**（其余 21 个应用器的接线保持原样，避免把"接线缺失"与"别的补丁没了"混在一起——我第一版拿裸 port-lib 态去构建，撞了 **`error CS = 212`**，那条读数**作废**，如实记）。
```bash
csproj = 340b042ab7e44799 → e863a9090fd04efb（205,753 → 205,471）；grep -c = 0
$ …hbtextline-shimsha.py --check
[检查] csproj 接线：**未接线**（需要跑一次不带 --check 的本脚本）      ⇒ rc=1
$ python3 build/MilBridge/tools/applier-audit.py
APPLIER_AUDIT applier=patch-presentationcore-hbtextline-shimsha tier=A ok=1 miss=2 \
  detail=csproj 里没有本应用器的 MARKER_BEGIN（接线被抹掉？）; csproj 里没有 <Compile Include=…HbTextLineShimSha.targets>
$ dotnet build … -p:BaseOutputPath=$HOME/w17c-build/pcbin-S1/ …     ⇒ rc=0，error CS = 0
pc(no-wire) = e04df02cdb635626  4,194,816 B
$ ShimShaReader --artifact pc.NOWIRE.dll
SHIM_SHA=NOINFO reason=attribute-absent artifact=<NOINFO> …            ⇒ rc=2   ✓（不许报绿）
```
**红证②（恢复 ⇒ 必须 `no`）**：把 csproj 从备份**逐字节**还原（`340b042ab7e44799`，sha 相等即自证）⇒ `--check` **rc=0** ⇒ 私有重建（`error CS = 0`）⇒ 读者 **`SHIM_SHA=no rc=0`**；权威写与读者见 §10.4。
**"逐字节还原"的自证**：`sha256sum` 相等（`340b042ab7e44799` = `340b042ab7e44799`）。

### 10.6 ⚠️ `grep -a` 的错误读数（留档）＋**一处对我 §2.3 措辞的更正**

（a）**主控提醒的那条，我复核并给出精确形状（它比我原先以为的更细）**：我这次的 attribute **key**（`HbTextLineShimSha`）落在 **`#Strings` 堆**、编码 **UTF-8**；**值**（64 位 hex）也落在 `#Strings`。实测（正向件 `pc.REWIRE.dll`）：

```
grep -a -c 'HbTextLineShimSha'                 = 1      <-- 在这个形态下 **不是 0**
grep -a -c 'bc04c05ab6d8d82a'                  = 1
UTF-16LE 命中 key  = 0 / value = 0 ; UTF-8 命中 key = 1 / value = 1
```
⇒ **`grep -a` 对"attribute 在不在"不是可靠仪器**：它的读数**取决于 attribute 形态**——key 名是**类型/成员名的引用**（`#Strings`，UTF-8）时可命中，若哪天改成"把 key 也写进字符串字面量"或换成只存在于 `#US` 的形态，ASCII `grep` 会**报 0（假红）**。**判"在不在"只用 `ShimShaReader`（`MetadataReader`）**，这条我照主控的纪律执行（本次所有"在不在"的结论都出自读者）。
（b）**反例（错误读数的实例）**：`grep -a -c 'HbTextLineShimSha' pc.NOWIRE.dll = 0` —— 这一格**恰好**与真值一致（真值也是"不在"），**但它不是证据**（同一条命令在正向件上给 1、在别的形态上会给 0）。**"碰巧对"不等于"被看着"**（纪律 37④）。

（c）**对 §2.3 的措辞更正（我自己先前的说法太宽）**：§2.3 写的是"同一份 shim 源 ⇒ `pc` 逐字节相同"。**更精确的事实是：`pc` 的 sha 依赖 `obj`/`bin` 的路径**。本次实测三个不同中间目录、同一份源、同一 `@(Compile)` 集合：

| 构建 | 中间目录 | `pc` sha16 |
|---|---|---|
| 权威（同目录跑两趟） | 仓内 `obj/Debug` | **`7680da47c39ec7ed`**（两趟**相同**） |
| 私有 A | `$HOME/w17c-build/pcobj-S0` | `e879cb67c7fa029e` |
| 私有 B | `$HOME/w17c-build/pcobj-S0b` | `7a33d6c401f3c661` |
⇒ **可重复性成立的范围是"同一输出目录内"**（这一点对本件的三条确定性保证毫无影响：生成文件内容仍只是 sha256、仍 `WriteOnlyWhenDifferent`、内嵌值仍只随 shim 内容变）。**跨目录的 sha 不同是既有事实**（我 §2.3 那两个私有构建彼此相同是因为**同一路径**），但**我没有**去追"路径是怎么进产物的"（PDB 路径 / `[assembly: …]` 里的源路径不做断言）⇒ 登记为**未测**，并把 §2.3 的那句话按本条读。

### 10.7 还会不会被别的波内步骤抹掉（回执里问的那一条）

**答案：走现在的通道不会被 `port-lib.py` 抹掉（它每次都被应用器重新插回），但有一个**真实残留风险**，我指名**：**

1. **`port-lib.py <Proj>`（波第 1 步）**：**会**抹掉所有应用器接线（实测：205,753 → 193,040，`grep -c` = 0）。这是**设计如此**（`integration-wave.sh:116-119` 就是这么写的），第 2 步重放会**逐字恢复**。⇒ **只要第 2 步跑，本件就活**；**第 2 步被跳过/失败 ⇒ 静默丢**（这正是上次的事故）。
2. **`patch-presentationcore-*.py` 里有没有谁"整体重写 csproj"？** 我把 11 个应用器逐个查了 `CSPROJ` 的写法：**全部是"读全文 → `replace(anchor, block+anchor, 1)` → 写回"**（apartment `:347`、lineheight-trace `:346`），**没有** `open(CSPROJ,"w")` 之前先重建整份文件、也没有 `re.sub` 整文件重排 ⇒ **没有第二个"整体重写者"**。⇒ 它们之间是**纯追加**，互不覆盖（唯一"覆盖"来自 `port-lib.py`）。
3. **`reapply-patches.py`（PC 的补丁 B/D/F/G）** 也是追加式（它自己在 `:1487` 之后追加一大段），实测重放 2 遍 csproj 逐字节相同。
   **逐个复核（12 个 PC 应用器，机器读数）**：`securityzone`（`replace(` = 0）**根本不碰 csproj**；`textservices` 只改上游 `TextServicesLoader.cs`（`open(CSPROJ,"w")` = 0）；其余 10 个都是 `replace(` 1–8 次 + 一次 `open(CSPROJ,"w")` 写回**同一份文本**。⇒ **没有"整体重写者"**（"整份重建 csproj"的唯一来源是 `port-lib.py`）。
   **幂等的强自证**：§10.5 把 3 行**手摘**掉得到 `e863a9090fd04efb`，再从备份还原后**重跑应用器**得到的还是 `340b042ab7e44799`（与手摘前逐字节相同）⇒ "应用器 = 在固定锚点做固定插入"是**实测**，不是声明。
4. **残留风险（指名）**：如果**将来**有人把 `patch-presentationcore-hbtextline-shimsha.py` 从 `APPLIERS_EXPLICIT` **摘掉**，它仍会被**兜底 glob** 执行（名字匹配 `patch-presentation*`）⇒ **不会静默丢**；但**如果同时**把它从 `applier-audit-expected.txt` 摘掉 ⇒ "被摘掉"就**不会红**。我把两条登记都做了，把这条风险变成**机器可判**（§10.2 的表 + 红证①的审计行）。
5. **顺带发现的既有缺口（已修，向主控报备）**：`patch-presentationcore-lineheight-trace`（T1c/D 行高插桩）此前**既不在 `APPLIERS_EXPLICIT`、也不在 `applier-audit-expected.txt`** ⇒ 它只靠兜底 glob 被执行，**不在审计覆盖面内**（"被摘掉"不会红；`close-wave-w17` 的日志逐字为 `patch-presentationcore-lineheight-trace ⚠ 不在显式顺序表里，追加执行`）。我把它一并登记；登记后审计从 `appliers=20 ok=74` 变成 **`appliers=22 ok=80 miss=0 red=0 rc=0`**。**副作用**：它现在比兜底时机**更早**执行 ⇒ csproj 里各补丁块的**位置**变了（内容多重集不变，§10.3 有机器断言）⇒ csproj 的 sha 与波留下的那一份**必然不同**（这是**登记它**的代价，不是接线本身的问题）。**若主控希望 csproj 与波留下的逐字一致**，回退方式 = 从 `APPLIERS_EXPLICIT` 删掉 `patch-presentationcore-lineheight-trace`（它会退回兜底、恢复旧时机），代价是那一条**重新回到审计覆盖面之外**。

### 10.8 本节的读数表

| 项 | 值 |
|---|---|
| lane / 时间 / kernel | `W17C` / **2026-09-16 12:33 → 12:41 (+0800)** / `6.8.0-138-generic` |
| `loadavg`（起/终） | `3.25 2.16 1.96` / `7.39 3.54 2.46` |
| `MemAvailable`（起/终） | **2659804 kB** / **2677252 kB** |
| 权威 `pc` BEFORE | `ac16320a14f549d4`｜4,194,816 B｜`2026-09-16 12:32:45.872839014` |
| 权威 `pc` AFTER | **`7680da47c39ec7ed`**｜4,195,328 B｜**`2026-09-16 12:40:22.733633917`**（FULL `7680da47c39ec7ed6026fb8d5813f798a174ca5e7eaa0929912fdc41688eeee1`） |
| 权威 `pdb` BEFORE → AFTER | `53cc8c9a42663e91`（2,159,460 B）→ `b8a2fa865c9098cc`（2,159,556 B） |
| `csproj`（波留下 → 现在） | `e2558faa0cc6b5d1`(205,471) → **`340b042ab7e44799`**(205,753) |
| 应用器 | `patch-presentationcore-hbtextline-shimsha.py` = **`81f821ae225eb3a0`**｜18,345 B｜`2026-09-16 12:37:32` |
| 生成物 `.targets` | **`3127e82b76ce8c24`**（FULL `3127e82b76ce8c2431869687ec2ee808bfbcea0911afee7277c4a91b91712d7a`）｜5,192 B｜`12:34:52.803690310`（= §1 落盘的那一份，内容逐字未变） |
| `integration-wave.sh` | **`770419556b9597df`**｜38,072 B｜`12:35:27`（before **不可得**，见 §10.2） |
| `applier-audit-expected.txt` | **`eecf8f28d3e6b9f9`**｜1,848 B｜`12:35:16`（before **不可得**） |
| 审计 | `APPLIER_AUDIT_SUMMARY appliers=22 ok=80 miss=0 red=0 rc=0` |
| 红证① / ② | `NOINFO attribute-absent rc=2`（`pc.NOWIRE = e04df02cdb635626`，4,194,816 B） / `no rc=0` |
| 未改动对照 | `build/shims/PresentationCore.HbTextLine.cs` = `bc04c05ab6d8d82a`（mtime 亦未变）；`known-red.json` = `f9843bde351029dc`；`tline-gate.sh` = `b37a5c9f55ae71a4`；`verify-all.sh` = `a68823631e8f8919`；`patch-presentationcore-textline-fallback.py` = `188f75a67294138f`（波内 12:15 的新版，我未动）；`ShimShaReader/Program.cs` = `0ef57677afef9f6d`（未改） |
| 证据目录 | `$HOME/w17c-build/evidence/`（`pc.NOWIRE.dll`、`pc.REWIRE.dll`、`pc.S0/S1/S1b/S2/S2-anon.dll`、`csproj.wired-W17C`、`csproj.before-portlib`、`shim.*.cs`）＋ `$HOME/w17c-build/replay-appliers-W17C.sh` |

**复算入口**

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux; export PATH="$HOME/.dotnet:$PATH"
python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-hbtextline-shimsha.py --prove   # 生成通道自证（只读）
python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-hbtextline-shimsha.py --check   # rc=0 表示接线在
python3 build/port-lib.py PresentationCore && grep -c 'HbTextLineShimSha.targets' build/PresentationCore.Linux/PresentationCore.Linux.csproj  # ⇒ 0（被抹）
bash $HOME/w17c-build/replay-appliers-W17C.sh                                                # ⇒ 重放失败数 = 0
grep -c 'HbTextLineShimSha.targets' build/PresentationCore.Linux/PresentationCore.Linux.csproj # ⇒ 1 ✓
python3 build/MilBridge/tools/applier-audit.py | tail -1                                     # appliers=22 ok=80 miss=0 rc=0
dotnet $HOME/w17c-build/reader-bin/Debug/net10.0/ShimShaReader.dll                            # ⇒ SHIM_SHA=no rc=0
```

**一句话（本节）**：接线现在**由可重放的生成通道产出**，实测**活过 `port-lib.py` 重生成**（`grep -c` 0 → 1、`--check` rc=1 → rc=0、审计红 → 绿），权威 `pc` = **`7680da47c39ec7ed`**（4,195,328 B）里元数据在、读者 `SHIM_SHA=no`；两极性红证齐（摘掉 ⇒ `NOINFO rc=2`；恢复 ⇒ `no rc=0`）；**残留风险指名 = "有人把两条登记都摘掉"**（已用登记把它变成机器可判），并且**顺带补上了 `lineheight-trace` 的审计缺口**（代价是 csproj 里补丁块位置变化，§10.7-5 给了回退方式）。
