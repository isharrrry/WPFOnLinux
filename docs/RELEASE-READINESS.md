# 发布就绪清单（准备开源时**逐条**过一遍）

> 这份清单只写**实测到的事实**与**每条事实的复算命令**；不写"大概/应该"。
> 生成时间：**2026-09-19**（`#36` 波收尾期）。⚠️ 数字会随树变化 ⇒ **引用前自己重算**。

---

## 0. 一句话结论

**可以发**，但有 **1 条硬拦路**（GitHub 单文件 100 MB 限）＋ **4 条必办**（`.gitignore`、字体许可、上游出处、第三方二进制）。
清单里的每一条都已经**在树里动手处理**，除了需要"你（发布者）做决定"的那几条（LFS / gz / 不入库）。

---

## 1. 硬拦路：**`git push` 会因为一个文件被拒**

| 文件 | 大小 | 说明 |
|---|---|---|
| `tests/parity/geometry/u14/linux-results-u14.json` | **118.2 MB** | ⚠️ **超过 GitHub 的 100 MB/文件硬限** ⇒ 推上去会被**直接拒绝** |
| `tests/parity/windows/layout-b34/windows-results.json` | **55.0 MB** | 未超限，但会把仓库拖重（且以后每次改动都进历史） |

复算：

```bash
find . -type f -size +20M -not -path "*/bin/*" -not -path "*/obj/*" -not -path "*/.artifacts/*" \
  -printf '%s\t%p\n' | sort -rn | awk -F'\t' '{printf "%8.1f MB  %s\n", $1/1048576, $2}'
```

**⭐ 结论（实测后）：**这两份都**不需要 LFS、也不需要 gzip** —— 它们都是**可再生的中间产物**，
而**当前所有判据走的都是仓内的小件**：

| 大件 | 有没有读者？ | 实测依据 | 处置 |
|---|---|---|---|
| `tests/parity/geometry/u14/linux-results-u14.json`（118.2 MB） | **没有**（唯一的引用是 `build-hygiene-import-check.sh:219` 提到 `u14/U14.csproj` **这个工程**，不是这份 JSON） | `grep -rn "u14" --include=*.sh --include=*.py --include=*.cs .` | **排除**（`.gitignore` 已写）；重算 = 跑 `tests/parity/geometry/u14/U14.csproj`（语料 `cases-u14.json`、`probe-pointsets.json` 都在仓内）⇒ **GitHub 100 MB 拦路由此消失** |
| `tests/parity/windows/layout-b34/windows-results.json`（55.0 MB） | **只作为派生件的来源**：真值读者读的是 `build/MilBridge/gen/layout-b34-compact.json`（**3.1 MB**，仓内）与 `build/MilBridge/tests/ProductEntryArm/inputs.json`（**4.7 KB**，仓内） | `grep -rn "layout-b34-compact\|inputs.json" build/MilBridge/{run.sh,tools,tests}` ⇒ `HbTextLineParity`、`ProductEntryArm`、`analyze-layout-b34.py` 全部读紧凑件（`run.sh:120` 只在**紧凑件缺失时**才从 55 MB 那份流式抽取） | **排除**（`.gitignore` 已写）；代价 = **"换字段集重新抽取"需要 Windows 侧重录**（这一点必须写进 README/发布说明，别让人以为能凭空重算） |

⇒ 净效果：**仓库不变重**（实测 `du -sh`：`--exclude=bin --exclude=obj --exclude=.artifacts .` = **382M**；再加 `--exclude=linux-results-u14.json --exclude=windows-results.json` ⇒ **202M**。⚠️ 单位 = `du -h` 的 1024 进制；文中 `%s/1048576` 算出的单文件大小与它同制）、
**没有任何现有判据失去可复算性**、**`git push` 不再被拒**。

⚠️ 那两份文件**不是**"随手产物"：`windows-results.json` 是 Windows 真机录的
（录制环境/API 序列/已知环境问题见 `tests/parity/windows/shaping/PROVENANCE.md` 一脉的做法）。
**排除 ≠ 删除**：它们在**工作树里继续存在**（`.gitignore` 只影响入库），本机的验收照旧能跑。

---

## 2. 必办：`.gitignore`（**已备**，见仓根）

- 事实：本仓**没有 git**（本机没装 git）⇒ `git add -A` 从没跑过；而树里有 **129 个**
  `bin`/`obj`/`.artifacts` 目录。
- 复算：`find . -type d \( -name bin -o -name obj -o -name .artifacts \) | wc -l`
- 不忽略会加进去多少：`du -sh --exclude=bin --exclude=obj --exclude=.artifacts .` ⇒ **382 MB**
  （未排除时 `du -sh .` ⇒ **3.7 GB**）。
- ⚠️ 本仓有一批 **`*.log`/`*.json` 是证据件**（五臂日志的 sha 有机器声明、`build/wave-audit.log`
  是责任溯源行、`tests/parity/**` 是真值语料）⇒ **不许**写 `*.log` / `*.json` 这类"一刀切"规则。
  `.gitignore` 里已把"刻意**不**忽略的东西"逐条列出，防止后来者顺手加规则删掉证据。

---

## 3. 必办：第三方资源的许可（**已补字体，其余见下**）

| 资源 | 位置 | 状态 |
|---|---|---|
| **Noto Sans** 4 个字重（1.7 MB） | `build/fonts/*.ttf` | ✅ 已随附 **`build/fonts/LICENSE-OFL.txt`**（SIL OFL 1.1 **要求**随附）＋ 来源/sha256 记在 `build/fonts/README.md` |
| 上游 `dotnet/wpf` | `upstream/wpf/**` | ✅ 其 `LICENSE.TXT`（MIT）在库 |
| **SkiaSharp 原生库**（8.9 MB） | `build/DirectWrite.Linux/wic-shim/libSkiaSharp.so` | ✅ **不入库**（`.gitignore`）；来自 NuGet 包 `SkiaSharp.NativeAssets.Linux` 2.88.9，`dotnet restore` 时会回来 |
| 强名密钥 | `build/keys/WcpPublicKey.snk`（**160 B**） | ✅ 是**公钥**（生成物用 `PublicSign` 公开签名）⇒ 入库无险；**发布前请自己再确认一次**（`sn -tp` 或看长度分布） |
| 官方 `System.Windows.Extensions` 等 OOB 包 | 由 NuGet 还原 | ✅ 不入库（`PackageReference`） |

---

## 4. 必办：上游快照的**出处**（今天缺）

- 事实：`upstream/wpf/` 是 `dotnet/wpf` 的快照，**仓里没有任何地方记下它的 commit / 抓取时间**
  （只有 `handoff.md:5` 一句"main 分支，已下载"，指向的是**另一个路径**）。
- 为什么必办：开源后别人要能回答"你这套移植是打在**哪个上游版本**上的"。
  本仓已有同类做法的**模板**：`tests/parity/windows/shaping/PROVENANCE.md`（录制环境＋API 序列＋可复算步骤）。
- 建议落点：`upstream/UPSTREAM-PROVENANCE.md`（来源 URL、抓取时间、`upstream/wpf` 顶层文件清单的 sha256、
  以及"若要更新上游，需要重跑哪些步骤"）。⚠️ 本机**不在线可信抓取**，所以这份要由发布者在能联网的环境里补全。

---

## 5. 其他已查清、**不需要动**的东西

| 项 | 结论 |
|---|---|
| `home/links-dev/`（仓根，空目录） | 某脚本按相对路径写出来的空壳，**git 不跟踪空目录** ⇒ 无害（要么删、要么留着都行） |
| `tools/GeometryOracle/`（73 MB） | **真的工具**（`Program.cs` ＋ csproj），其中 73 MB 是 `bin/` ⇒ 已被 `.gitignore` 覆盖 |
| `__pycache__/`、`*.pyc`、`*.xwd` | 已忽略 |
| `build/MilBridge/arm-logs/*.log`、`build/wave-audit.log` | **必须保留**（证据件，见 §2） |
| 权威 `.so`/`.dll` | 全部是**构建产物**（不入库）—— 九个"权威位"由 `bash build/integration-wave.sh` 现场重建 |

---

## 6. 发布前建议再跑一遍的**验收**（不是必须，但强烈建议）

```bash
bash build/verify-env.sh          # 环境清单（依赖是否齐）
WAVE_OWNER=$(whoami) bash build/integration-wave.sh   # 从零重建（0 error）
bash verify-all.sh                # 24 步验收（含真开窗渲染）
```

⚠️ `verify-all.sh` 需要 X server（脚本自己起 `:99`；应用门禁用 `:97`）与 `xvfb`/`x11-apps`/`imagemagick`。
验收的**唯一权威基线**是 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（整份 sha 只在
`docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行里声明**一次**）。
