# 任务：WPFOnLinux 结构上游化 · 阶段 3（根目录瘦身 ＋ 全仓路径重写；**一个 subagent**）★ 整波 · 风险最高

> 你**一个人**做完本阶段。先读：`docs/UPSTREAM-ALIGN-PLAN.md`（§2.2、§2.5、§5 阶段 3、§6.11、§6.13）与
> `docs.Linux/design/_PHASE0-NAMING-CONVENTION.md`。
> 本阶段是**全仓最大的一次搬动**；**做不干净就必须回退**（见 §⑤），不许留下半搬状态。

---

## ① 目标与移动映射（唯一权威）

| 旧（仓根） | 新 |
|---|---|
| `build/` | `src.Linux/build/` |
| `tests/` | `src.Linux/tests/` |
| `samples/` | `src.Linux/samples/` |
| `tools/` | `src.Linux/tools/` |
| `wpf-linux.sln` | `src.Linux/wpf-linux.sln` |
| `verify-all.sh` | `Guide.Linux/verify-all.sh` |

搬完后**仓根只剩**：`src/`、`src.Linux/`、`Guide/`、`Guide.Linux/`、`docs/`、`docs.Linux/`、`README*.md`、`LICENSE.TXT`、
`SECURITY.md`、`CODEOWNERS`、`CODE_OF_CONDUCT.md`、`THIRD-PARTY-NOTICES.TXT`、`global.json`、`BuildHygiene.props`、`home`、
`.github/`、`.gitignore`、`.gitattributes`、`upstream/`（阶段 4 才动）、`handoff.md`（阶段 2 已裁定留原位）。

**必须是真搬家**（`mv` / `git mv`），**不许**用符号链接 —— GNU `find` 对 symlink 起点**不下钻**，会直接打穿 `fp_inputs()`。

---

## ② 动手前（快照与回退装置）

1. `cd /home/links-dev/netTest/GitProj/WPFOnLinux && git status --short > /tmp/stage3-pre-status.txt`
2. 记下**当前基线**：`bash src/WpfGfx.Linux.Native/…` 不必；只要记这几条：
   ```bash
   bash build/MilBridge/tools/root-entries-allowlist-check.sh | tail -1
   bash build/MilBridge/tools/handoff-machine-values-check.sh | tail -1
   bash build/MilBridge/tools/verify-all-step-check.sh >/dev/null; echo rc=$?
   bash build/MilBridge/tools/fp-inputs-hygiene-check.sh | tail -1
   bash build/MilBridge/tools/pts-gap-count-check.sh | tail -1
   bash ~/w153a/bin/infp.sh fp; bash ~/w153a/bin/infp.sh list | wc -l
   ```
3. **断言面免改清单（先建）**：这些件被 `sha16`／内容断言，**内容一字不改**；
   先跑一遍全部牙，把"改了它就红"的件逐个补进这份清单（经验起点）：
   `docs/WAVE66-PREREGISTRATION.md`、`docs/PORT-SPEC.md`、`docs/INDEX.md`、`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`、
   `build/MilBridge/*-report.md`、`handoff.md`、`docs/ROUTES.md`、`docs/CURRENT-STATE.md`(除第 9 行的**路径**)、
   `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`、`docs/unimplemented.md`、`src/WpfGfx.Linux.Native/src/win32_classification.c`。
4. 回退装置：搬家前 `mkdir -p /tmp/stage3-rollback && git status --porcelain > /tmp/stage3-rollback/status.txt`；
   你编辑过的每个 tracked 件都记进 `/tmp/stage3-rollback/edited.txt`（回退时 `git checkout -- $(cat edited.txt)`）。

---

## ③ 步骤

**Step 1 — 搬家**
```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
mkdir -p src.Linux Guide.Linux
mv build src.Linux/build
mv tests src.Linux/tests
mv samples src.Linux/samples
mv tools src.Linux/tools
mv wpf-linux.sln src.Linux/wpf-linux.sln
mv verify-all.sh Guide.Linux/verify-all.sh
git add -A        # ★ 只暂存、不提交；不 add 则 git ls-files 仍报旧根条目 ⇒ 根级允许清单牙必红
```

**Step 2 — 全仓路径重写（机械，但要按清单来）**
- 覆盖类型：`*.sh *.py *.csproj *.props *.targets *.sln *.json *.tsv *.md *.yml *.yaml .gitignore`（不含 `upstream/**`）。
- 词边界要点（**用能区分前缀的替换，别用裸 `sed s|build/|src.Linux/build/|`**）：
  - `build/` → `src.Linux/build/`（注意别把 `src.Linux/build` 二次替换、别把 `buildings` 改坏）
  - `tests/` `samples/` `tools/` `wpf-linux.sln` 同理 → `src.Linux/…`
  - `verify-all.sh` → `Guide.Linux/verify-all.sh`（含 `bash verify-all.sh` 的写法）
  - `$(WpfLinuxRoot)/build/` → `$(WpfLinuxRoot)/src.Linux/build/`
- **断言面清单里的件不在替换集**（它们的旧路径由 Step 4 的 `PATH-MAP.md` 承接）。
- `Guide.Linux/verify-all.sh` 顶部（在 `set -…` 之后、任何相对路径使用之前）加一行：
  `cd "$(dirname -- "${BASH_SOURCE[0]}")/.." || exit 9`
- 替换完先自证**旧路径残留只剩断言面**：
  ```bash
  grep -rlF 'build/' --include='*.sh' --include='*.py' --include='*.csproj' --include='*.props' \
       --include='*.targets' --include='*.sln' --include='*.json' --include='*.tsv' . | grep -v '^./upstream/' | grep -v '<断言面清单>'
  # 期望：空（或仅剩确证无害的注释/历史文本，逐条点名）
  ```

**Step 3 — 同趟登记（缺一必红）**
1. `src.Linux/build/MilBridge/tools/root-entries-allowlist-check.sh` 内嵌 `ALLOWLIST`：
   **删** `build`／`tests`／`samples`／`tools`／`verify-all.sh`／`wpf-linux.sln` 六行；
   **加** `src.Linux`、`Guide.Linux`（`why` 以「移植面：」开头，**别写「fork 治理件」**以免牵动 `DOC_CAT3`）。
2. `src.Linux/build/close-wave.sh` 的 `fp_inputs()` 里所有 `build…` → `src.Linux/build…`（**必须真改**，否则覆盖面塌）。
3. `src.Linux/build/MilBridge/tools/wave-freeze-consistency-check.py` 的 `NINE_PATHS`（约 :104-115）逐路径改；
   同时检查 `SITES_TSV='build/MilBridge/wfreeze-root-sites.tsv'`、`SHIFTS_TSV='build/MilBridge/blockvalues-shift.tsv'` 两行。
4. 其它同类硬编码：`build/MilBridge/tools/*`（`product-entry-step.sh`、`frame-step.sh`、`baseline-sha-check.sh`、
   `arm-log-sha-check.sh`、`hygiene-tooth.sh`、`fp-inputs-hygiene-check.sh`…）里点名 `build/…` 的行，逐条改。
5. `docs/CURRENT-STATE.md:9`：把该行里的 `file=samples/...` 改成 `file=src.Linux/samples/...`（**只改路径、不动 `gen`/`sha16` 号值**）；
   改完 `bash src.Linux/build/MilBridge/tools/baseline-sha-check.sh` 必须 `CSDECL=PASS`。
6. `src.Linux/build/MilBridge/HANDOFF-NEXT.md`：**末行追加**一条 `⏪ **机器值契约更正 · cell=#1／cell=#2／cell=#3**：…`
   （格式照该件现有末行），`现值`＝现取的 `bash ~/w153a/bin/infp.sh fp`、`覆盖面件数`＝`bash ~/w153a/bin/infp.sh list | wc -l`，
   成因写"结构上游化阶段 3 根目录瘦身"。

**Step 4 — 旧→新对照表**
新建 `docs.Linux/evidence/PATH-MAP.md`：逐条 `旧路径 → 新路径`（6 条根映射 ＋ 常见子路径示例）＋ 一行复算命令；
并注明"**被断言的证据件内容不改**，其内旧路径请按本表换算"。

**Step 5 — 门禁全跑（判定成败）**
```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
for t in root-entries-allowlist-check handoff-machine-values-check verify-all-step-check defect-registry-check \
         fp-inputs-hygiene-check baseline-sha-check sentinel-spec-check pts-gap-count-check; do
  bash src.Linux/build/MilBridge/tools/$t.sh >/dev/null 2>&1; echo "$t rc=$?"
done
bash Guide.Linux/verify-all.sh      # 期望 64 ✅ / 0 ❌（约 37 min）
```
任一条红 ⇒ 先归因：**是我们改坏了，还是该件时效性抖动**（`static-jaws` 首趟红要复跑一次再定罪）；
改坏 ⇒ 修补；修不动 ⇒ 走 §⑤ 回退。

---

## ④ 边界条款

- **只允许**：移动上述 6 项；重写引用；改 Step 3 点名的登记件；新建 `docs.Linux/evidence/PATH-MAP.md`。
- **禁止**：改 `upstream/**` 一个字节；改断言面清单里件的内容；改任何 `.cs`/`.xaml` 的**逻辑**（只许改其中的路径字符串）；
  改 `docs/CURRENT-STATE.md` 除第 9 行路径外的任何内容；`git commit`。
- **尝试上限**：替换/修复做法最多 2～3 种；仍不能全绿 ⇒ 回退并上报。

---

## ⑤ 回退条款（硬）

若 2～3 种做法后仍不能恢复全绿：**把树移回原位**
```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
mv src.Linux/build build; mv src.Linux/tests tests; mv src.Linux/samples samples; mv src.Linux/tools tools
mv src.Linux/wpf-linux.sln wpf-linux.sln; mv Guide.Linux/verify-all.sh verify-all.sh
rmdir src.Linux Guide.Linux 2>/dev/null
git checkout -- $(cat /tmp/stage3-rollback/edited.txt)   # 复原编辑过的 tracked 件
```
回退后**必须复核**：五颗关键牙回到动手前读数（Step 0 记的那组）。然后如实上报。

---

## ⑥ 验收标准（可计算）

| # | 判据 |
|---|---|
| A | 六个新落点存在、六个旧落点**不存在**（`test -d`/`test -e` 逐条） |
| B | `bash src.Linux/build/MilBridge/tools/root-entries-allowlist-check.sh` ⇒ `ROOT_ALLOW=PASS … unknown_fs=0`；`--selftest` ⇒ `pass=18 fail=0` |
| C | `bash src.Linux/build/MilBridge/tools/handoff-machine-values-check.sh` ⇒ `HANDOFF_MV=PASS cells=9 … mismatch=0` |
| D | `bash Guide.Linux/verify-all.sh` **×2** 各 `64 ✅ / 0 ❌`（若单趟 >45 min，逐趟留原始日志） |
| E | 除断言面外，**函数面**无旧路径残留（§③ Step 2 的 `grep` 命令 ⇒ 空或逐条点名无害） |
| F | `git status --short` 里旧路径为 `D`、新路径为 `R`/`A`；既有断言面件的 `sha256` 与动手前**逐件相同** |
| G | `docs.Linux/evidence/PATH-MAP.md` 存在且 6 条根映射齐全 |

---

## ⑦ 失败报告格式

已试方案；实际命令与**输出原文**（含 `rc`）；当前怀疑；是否已回退（回退到哪一步）。

## ⑧ 完成报告格式

- 逐条判据 → 证据（命令 ＋ 原始读数）。
- 移动清单 ＋ 编辑件清单（`git status --short` 原文）。
- **断言面免改清单**（最终版）＋ 每条为什么免改（哪个牙/哪条断言）。
- 同趟登记三处（allowlist 行文本、`fp_inputs()` 改动、`HANDOFF-NEXT.md` 更正行原文）。
- `inputs_fp` 前后值、覆盖面件数前后值、九位是否位移。
- **主动披露**：还有哪些旧路径**故意留着**（断言面内）、`PATH-MAP.md` 是否覆盖全、`verify-all` 有无时效性抖动（首趟红复跑绿）。
