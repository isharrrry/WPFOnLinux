# 任务：WPFOnLinux 结构上游化 · **合并波（阶段 3+4+5）** —— 一次落位 ＋ 一次路径重写 ＋ 一笔提交 ＋ 一次重冻

> 你**一个人**做完。这是全仓最大、风险最高的一波；**做不干净必须回退**（§⑦）。
> **先读**（按序）：`docs/UPSTREAM-ALIGN-PLAN.md`（§2.2/§2.5/§5 合并波/§6）→
> `docs.Linux/evidence/STAGE3-SCOPE-REPORT.md`（**上一轮 21 次尝试的实测清单，必读，含七类路径语义**）→
> `docs.Linux/design/_PHASE0-NAMING-CONVENTION.md` → `docs.Linux/evidence/_PHASE0-READERS-INVENTORY.md`。

---

## ① 目标（最终落点，唯一权威）

| 旧（仓根） | 最终落点 | 内容 |
|---|---|---|
| （取回） | `src/Microsoft.DotNet.Wpf/` | Windows 上游源：`git archive a394a4792 src/Microsoft.DotNet.Wpf`。**绝不要带上游仓根的 `Directory.Build.props`/`.targets`**（会 MSB4236） |
| `build/<工程>.Linux/`、`build/shims/`、`build/DirectWrite.Linux/`、`src/WpfGfx.Linux/**` | `src/Microsoft.DotNet.Wpf.Linux/src/<工程>/` | Linux 覆盖层（`<工程>.Linux.csproj` ＋ `*.Linux.cs` ＋ 应用器接线） |
| `build/` 其余（脚本·门禁·MilBridge·third-party·fonts 等）、`tests/`、`samples/`、`tools/`、`wpf-linux.sln` | `src/Linux/{build,tests,samples,tools,wpf-linux.sln}` | Linux 侧仓内设施 |
| `verify-all.sh` | `Guide.Linux/verify-all.sh` | 一键入口 |
| （取回）上游仓根脚本 `build.cmd`/`build.sh`/`Restore.cmd`/`test.cmd`/`start-vs.cmd`/`dotnet-test-install.ps1` | `Guide/` | win 侧根脚本（只归档，不执行） |
| `upstream/wpf/` | **最后一步才删**；改由 `docs.Linux/evidence/UPSTREAM-MANIFEST.tsv`（逐件 `sha256\t路径`）承担校验 | C2 收法 |

**最终仓根只剩**：`src/`、`Guide/`、`Guide.Linux/`、`docs/`、`docs.Linux/`、`README{.md,.zh-CN.md,.es.md}`、`README-Window.md`、
`LICENSE.TXT`、`SECURITY.md`、`CODEOWNERS`、`CODE_OF_CONDUCT.md`、`THIRD-PARTY-NOTICES.TXT`、`global.json`、
`BuildHygiene.props`、`home`、`.github/`、`.gitignore`、`.gitattributes`。**没有 `src.Linux/`、没有 `upstream/`、没有 `build|tests|samples|tools`、没有 `verify-all.sh`、没有 `wpf-linux.sln`。**

⚠️ **禁止符号链接**（GNU `find` 不下钻 symlink 起点 ⇒ 打穿 `fp_inputs()`）。

---

## ② 动手前（装置）

1. **清 `/tmp`**：`R-GATE` 要求 `DISK_HEADROOM avail_gb ≥ 5`；上一轮因 3.9 G 判红。先 `df -Pk /tmp` 确认 ≥15 G，不足则清历史临时件（**只清你自己的与公认陈旧件，别删别人的在跑装置**）。
2. `git status --short`（应为**空**，上一波已提交 `07a0099d2`）＋ `git rev-parse --short HEAD` 记档。
3. 记基线五读数：`infp=$(bash ~/w153a/bin/infp.sh fp)`、`bash src/…/root-entries-allowlist-check.sh | tail -1`、
   `handoff-machine-values-check.sh | tail -1`、`fp-inputs-hygiene-check.sh | tail -1`、`pts-gap-count-check.sh | tail -1`。
4. 回退装置：备份到 `/tmp/mw-rollback/`（**同时**用 `commit 07a0099d2` 作代码复原基准 —— 这比上一轮更省事）。

---

## ③ 施工顺序（一步不可省）

**Step 0 · D3 门槛（先跑，不过就降级）**
在 `/tmp` 影子树里验"Windows 源搬回后"的命门：`src/Microsoft.DotNet.Wpf/src/<工程>/*.csproj` 存在时，
`verify-all` 第 `[9]` 步 `BHYGIENE-IMPORT` 是否 `undeclared=0`/`reason=ok`（把它们登记进 hygiene roster）。
**不过 ⇒ 降级为"只做 `src/Linux/` 瘦身 ＋ 提交 ＋ 重冻"，不搬 Windows 源**，并如实上报。

**Step 1 · 取回 Windows 源 ＋ win 根脚本**
```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
mkdir -p /tmp/mw-win && git archive a394a4792 src/Microsoft.DotNet.Wpf | tar -x -C /tmp/mw-win
mkdir -p src/Microsoft.DotNet.Wpf && cp -a /tmp/mw-win/src/Microsoft.DotNet.Wpf/. src/Microsoft.DotNet.Wpf/
# 上游仓根脚本（若 a394a4792 里存在）→ Guide/
mkdir -p Guide && git archive a394a4792 build.cmd build.sh Restore.cmd test.cmd start-vs.cmd dotnet-test-install.ps1 2>/dev/null | tar -x -C Guide 2>/dev/null || true
# ★ 校验：绝不带 Directory.Build.props/.targets
test ! -e src/Microsoft.DotNet.Wpf/Directory.Build.props && test ! -e Directory.Build.props && echo OK-NO-ROOT-PROPS
```

**Step 2 · 一次搬到位（真 mv）**
```bash
mkdir -p src/Linux Guide.Linux src/Microsoft.DotNet.Wpf.Linux/src
mv build  src/Linux/build
mv tests  src/Linux/tests
mv samples src/Linux/samples
mv tools  src/Linux/tools
mv wpf-linux.sln src/Linux/wpf-linux.sln
mv verify-all.sh Guide.Linux/verify-all.sh
# 再把"生成出来的工程 + Linux 覆盖件"从 src/Linux/build 落到 src/Microsoft.DotNet.Wpf.Linux/src/<工程>/
#   源：src/Linux/build/<工程>.Linux/、src/Linux/build/shims/、src/Linux/build/DirectWrite.Linux/、原 src/WpfGfx.Linux/**
#   ⚠️ 这一步的粒度参照 STAGE3-SCOPE-REPORT §2/§6 与 §6.7（功能目录→上游工程 映射）；
#   ⚠️ 先把上一轮 `/tmp/stage3-rollback/files` 与 `07a0099d2` 当参考，别凭记忆。
git add -A     # 只暂存；提交在 Step 5
```

**Step 3 · 全仓路径重写（七类语义，逐类做，每类 dry-run 后审查）**
- **七类**（前六类见 `STAGE3-SCOPE-REPORT §2`，第七类见 §6）：① 词边界 `seg/`；② `dirname(SELF)` 上溯层数随落点改变；
  ③ 仓根变量 `$VAR/seg/`；④ 引号/分段/`:-` 默认值；⑤ `.csproj/.props/.targets` 相对链与 `GetFullPath`；
  ⑥ `.sln` 以自身为基准；⑦ **引号内空格分隔的裸目录名列表**（`UIAD_SRC_ROOTS='build src samples'` —— 唯一已知处
  `src/Linux/build/MilBridge/tools/uia-door-check.sh:93`，新值应为 `'src/Linux/build src src/Linux/samples'`）。
- 覆盖扩展名：`*.sh *.py *.csproj *.props *.targets *.sln *.json *.tsv *.md *.yml *.yaml .gitignore`（**不含 `upstream/**`**）。
- **新旧落点同时存在**：本轮是"一步到位"，所以 **旧的 `build/…` 与 `build/<工程>.Linux/…` 两族都要映射到各自新落点**，
  且**顺序敏感**（先长前缀后短前缀）；每类替换后 `grep` 自证**旧路径只剩"断言面清单"内**。
- **断言面清单**（内容一字不改，旧路径交 PATH-MAP）：`docs/WAVE66-PREREGISTRATION.md`、`docs/PORT-SPEC.md`、`docs/INDEX.md`、
  `src/Linux/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`、`src/Linux/build/MilBridge/*-report.md`、`handoff.md`、`docs/ROUTES.md`。
- **落两台新牙**（本轮新增，写进 `src/Linux/build/MilBridge/tools/`，并接进 `verify-all.sh` 与覆盖面）：
  `path-map-covers-old-paths-check.sh`（扫全仓旧路径前缀，逐个断言在 `docs.Linux/evidence/PATH-MAP.md` 有映射，漏一个即红）／
  `no-internal-symlink-check.sh`（断言落点下无指向仓内的软链接）。

**Step 4 · 同趟登记**（照 `STAGE3-SCOPE-REPORT §3` 的 20 处，**逐条落实**，并据新落点改名）：
根级允许清单（删 `build tests samples tools verify-all.sh wpf-linux.sln upstream`，加 `Guide`、`Guide.Linux`）／
`fp_inputs()` 的 find 根／`wave-freeze` 的 `SELF_ROOT`·`SCAN_ROOTS`·`NINE_PATHS`·`SITES/SHIFTS_TSV`／`Directory.Upstream.props` 的 `WpfLinuxRoot`／
`sln` 相对基准／`wiring-coverage` 的 `WR_ERE`／`pkg-src` 射程＋S9／`selfdescription` glob／`verify-all-step-check` 的 `VFILE`／
`parser-guard-decl.txt`／`handoff-machine-values` 的 HANDOFF 路径／`Guide.Linux/verify-all.sh` 的 `cd "$(dirname …)/.."` ＋ `ROOT=`／
`wfreeze-root-sites.tsv` 重发／`docs/CURRENT-STATE.md:9` 路径／`HANDOFF-NEXT.md` 追加更正行／仓外 `~/w153a/bin/infp.sh` 的 `CW=` 与两枚哨兵 `FP` 键。
另落 `docs.Linux/evidence/PATH-MAP.md`（旧→新逐条 ＋ 复算命令）与 `docs.Linux/evidence/UPSTREAM-MANIFEST.tsv`（**不删 `upstream/`，先只落清单**）。

**Step 5 · D1（不提交，先看结构面）**
```
dotnet build src/Linux/wpf-linux.sln           → 期望 0 错误
dotnet test  （5 套）                          → 期望 875 用例 0 失败
13 颗结构牙 + 8 颗关键牙                       → 期望全绿
bash Guide.Linux/verify-all.sh                 → 剩余红必须逐条具名归因（只允许"未提交/未重冻/九位位移/臂滞后"）
```

**Step 6 · 一笔整波提交**
`git add -A && git commit -F -`（信息写清：落点、D1 读数、`inputs_fp` 位移、九位位移声明）。**本波只此一笔**。

**Step 7 · 就地重冻**（`PORT-SPEC §5` 整波链）
- **重取臂**：`tline-gate（五臂）` 与 `COLUMN-FLOOR` 的旧代臂日志要按新路径重取（见 `src/Linux/build/MilBridge/tools/retake-arms-*.sh` 与 `close-wave.sh` 的契约）；
- 写两枚 `bridge-frozen.flag`（`/tmp/` 与 `~/wfp-runs/`）＋ `docs/CURRENT-STATE.md:9` 新基线；
- 同步改 `docs/ROUTES.md §8`（"上游化暂缓" → "已落地"）——**该件属断言面，改动方式照其自身纪律（dated 追加、不删原文）**，改完复跑 `DEFREG`/`HYGIENE`/`PTSGAP` 确认未红。

**Step 8 · D2（终态）**
`bash Guide.Linux/verify-all.sh` **×2** 各 `64 ✅ / 0 ❌`；八颗关键牙全绿；九位/`inputs_fp`/基线**前后成对读数**。

**Step 9 ·（仅 D2 全绿后）删 `upstream/wpf/`**
先自证 `UPSTREAM-MANIFEST.tsv` 与工作树逐件相等，再 `git rm -r upstream` ＋ 一笔提交 ＋ 复跑 `verify-all` 一趟确认不新增红。

---

## ④ 边界

- **允许**：执行上述全部；改 `src/Linux/build/MilBridge/**`、`verify-all.sh`、`docs/CURRENT-STATE.md`(仅 :9 及追加)、`docs/ROUTES.md`(dated 追加)、`build/MilBridge/HANDOFF-NEXT.md`、根级允许清单。
- **禁止**：改 `upstream/wpf/**`（Step 9 的删除除外）；改断言面清单件的内容（`ROUTES.md` 只许 dated 追加）；改任何 `.cs`/`.xaml` **逻辑**（只许改路径字符串）；带进上游仓根 `Directory.Build.props`/`.targets`；**用符号链接**；多于一笔提交（Step 9 的提交除外）。
- **尝试上限**：每类替换/修复 2～3 种；仍不绿 ⇒ §⑦ 回退。

---

## ⑤ 验收

| # | 判据 |
|---|---|
| A | 最终落点逐条 `test -d/-e`；旧落点（含 `src.Linux`、`upstream`）**不存在**；根条目 == §① 清单 |
| B | `dotnet build src/Linux/wpf-linux.sln` 0 错；5 套测试 0 失败 |
| C | `bash src/Linux/build/MilBridge/tools/root-entries-allowlist-check.sh` ⇒ `ROOT_ALLOW=PASS unknown_fs=0`，`--selftest pass=18` |
| D | `handoff-machine-values-check.sh` ⇒ `HANDOFF_MV=PASS cells=9 mismatch=0` |
| E | `bash Guide.Linux/verify-all.sh` ×2 ⇒ `64 ✅ / 0 ❌` |
| F | `docs.Linux/evidence/PATH-MAP.md` ＋ `UPSTREAM-MANIFEST.tsv` 存在；两台新牙绿；断言面件 `sha256` 未变 |
| G | `inputs_fp`/九位/基线**前后成对读数**齐全；`git log --oneline -3` 本波提交数 == 1（＋Step 9 一笔） |

---

## ⑥ 报告格式

- 逐条判据 → 命令 ＋ 原始读数。
- 最终根条目清单（`ls -A`）＋ `git log --oneline -2`。
- 七类语义各自的替换条数 ＋ 残留旧路径逐条点名。
- 20 处登记逐条「改了哪行 → 新值」。
- 九位/`inputs_fp`/基线前后值；`verify-all` 两趟的步骤通过数。
- **主动披露**：降级与否（D3 结论）、还有哪些旧路径故意留着、臂重取是否成功、`static-jaws` 是否时效性抖动。

---

## ⑦ 回退条款（硬）

任一步 2～3 种做法仍不能恢复全绿 ⇒
```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
git reset -q && git checkout -- . && git clean -fdq -e /tmp   # 以 commit 07a0099d2 为基准复原
```
**并且**给出复原读数（`git status --short` 条数、`HEAD`、五颗关键牙读数、`inputs_fp`）——
**不得只写"已回退"**：上一轮有人这么写，实际仓库还在半搬状态。
