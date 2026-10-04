# 阶段 3（根目录瘦身）· 实践结论与可复用清单

> 来源：`TASK-阶段3.md` 的 12 轮执行尝试（2026-10-04）。仓内状态**已按 §⑤ 回退**：`git status` 15 条与动手前
> 快照 IDENTICAL、六项已回原位、未 commit。本件落在**仓外**（`/tmp`），零副作用，供下一执行体直接施工。

## 1. 达到过的最好状态（可复现）

- `dotnet build src.Linux/wpf-linux.sln` → **0 个错误**；`HelloWpf` → 0 错误
- 5 套测试：**875 用例 / 2 跳过 / 0 失败**（Commands 562、Rendering 166、ManagedLayer 50、Windowing 26、HelloMil 18…）
- 结构牙全绿：ROOT-ENTRIES、VERIFYALL-SELF、DEFREG、FP-INPUTS、BASELINE-SHA、PTSGAP、WIRING-COVERAGE、PARSER-GUARD、SELFDESC、BOUNDARY-DECL、WIRING-CLOSURE、RETIRED-PATH、HYGIENE ＋ `SSC=PASS` ＋ `HANDOFF_MV=PASS`
- `verify-all`：**60 ✅ / 4 ❌**（首趟 47/17 → 61/13 → 53/11 → 59/5 → 清理磁盘后 60/4）

## 2. 路径语义六类（**少一类就构建失败**）

1. 词边界：`(?<![\w./-])seg/` → `src.Linux/seg/`（+ `Guide.Linux/verify-all.sh`、`src.Linux/wpf-linux.sln`）
2. `dirname(SELF)` 系：**上溯到仓根的层数 +1**（shell `/../..`；python `os.path.dirname` 链），不跟上就整树构建失败
3. 仓根变量：`$VAR/seg/`、`${VAR}/seg/`（需变量白名单/仓根判定）
4. 字面量：`"seg/"`、`'/seg/'`、`"seg"` 分段、`:-seg` 默认值（`"${X:-build/shims}"`）
5. `.csproj/.props/.targets`：相对链 + `$(WpfLinuxRoot)` 形态 + `GetFullPath('$(MSBuildThisFileDirectory)…build')`
6. **`.sln` 以自身为基准**：`tests\…`/`samples\…` **不加前缀**；`src\WpfGfx.Linux\…` → `..\src\WpfGfx.Linux\…`

**必改的关键单点（漏改一处即红/构建失败）**：
`Directory.Upstream.props` 的 `WpfLinuxRoot`（必须 `GetFullPath('$(MSBuildThisFileDirectory)../..')/`）、
`.sln` 的 `src\` 前缀、`close-wave.sh` 的 `find … build`（**裸目录名**）、
`ime/uia-door-check.sh` 的 `:-build/shims`、`Directory.Build.targets`/`WpfLinuxBinDir` 类相对链。

## 3. 同趟登记的 20 处

允许清单（删 `build/tests/samples/tools/verify-all.sh/wpf-linux.sln`，加 `src.Linux`/`Guide.Linux` ＋ fixture）｜
`fp_inputs()`（`find … build` → `src.Linux/build`）｜`wave-freeze` 的 `SELF_ROOT`(4 层)/`SCAN_ROOTS=['.','src.Linux','Guide.Linux','src']`/`NINE_PATHS`/`SITES·SHIFTS_TSV`/`S2·S13` 夹具｜
`wiring-coverage` 的 `WR_ERE`（需含 `(src\.Linux|Guide\.Linux)/` 可选前缀，否则 `grep -oE` 从新路径里**截出旧路径**）｜
`pkg-src` 射程目录（`src.Linux/build src.Linux/tests src src.Linux/samples src.Linux/tools`）＋ S9 断言 ＋ 夹具目录｜
`selfdescription` 的 glob 与 `va=`｜`verify-all-step-check` 的 `VFILE=` 与**预登记 glob 两处**｜
`parser-guard-decl.txt`｜`handoff-machine-values` 的 `HANDOFF-NEXT` 路径｜
`Guide.Linux/verify-all.sh` 的 `cd "$(dirname -- "${BASH_SOURCE[0]}")/.." || exit 9` ＋ `ROOT=…/..`（**步名 `wpf-linux.sln` 不改**）｜
`wfreeze-root-sites.tsv` **重发**（`--emit-roster`）｜`docs/CURRENT-STATE.md:9` 路径｜`HANDOFF-NEXT.md` 追加 `cell=#1/#2/#3/#4/#5/#9` 更正行｜
仓外：`~/w153a/bin/infp.sh` 的 `CW=`（否则 `inputs_fp` 取不到）、两枚 `bridge-frozen.flag` 的 `FP` 键。

## 4. 达到 60/4 后剩下的 4 项（**与"结构未改"无关**）

| 项 | 实测 | 处置 |
|---|---|---|
| `TS-ORDER` | `NOINFO reason=no-first-commit`（`git log -S"<整行>" -- <件>`，新路径未入库） | **必须 commit**（§④ 禁止）或改用该牙 `--assume-first-commit`（削弱判据） |
| `tline-gate（五臂）` | `GATE_PROBE=NOINFO state=DECL-GAP … 自报=-` | **整波重取臂**（臂日志为旧代）＋ 同趟重冻 |
| `COLUMN-FLOOR` | `…gate-selfreport-mismatch pass=3 fail=1` | 同上 |
| `UIA-DOOR` | `--selftest 15/38 fail=23`、真树 `CANARY=BLIND prod=0` | **专项**对齐其沙箱夹具 38 例 |
| （已解）`R-GATE` | `DISK_HEADROOM=FAIL avail_gb=3 min_gb=5` | 清 `/tmp` 历史临时件（3.9G→15G）后单跑 `R_GATE=PASS crit=13/13` |

## 5. 安全施工顺序（建议）

`git status --short > /tmp/pre.txt` → 备份编辑件 → `mv` 六项（**真 mv，禁 symlink**）→ 按 §2 六类逐类重写（
脚本化 + 每类 dry-run 审查）→ 按 §3 登记 → `git add -A` → 快速验证（`dotnet build src.Linux/wpf-linux.sln`、
`HelloWpf`、5 套测试）→ 关键牙 → `bash Guide.Linux/verify-all.sh` ×2 → 若仍有红先归因（改坏 vs 证据/冻结点滞后）。

**回退装置**：备份在 `/tmp/stage3-rollback/files`（搬迁后、改动前的逐件副本），恢复脚本
`/tmp/r3_restore.py`（含 `maprel` 与 flatten），回退后务必复核 `git status` 与五牙读数。

## 6. 第 7 类遗漏形态（第 14/15 轮新发现，**必须补进替换集**）

**空格分隔的多值路径常量**——引号内以空格分隔的**裸目录名列表**，如：

```bash
UIAD_SRC_ROOTS='build src samples'      # build/MilBridge/tools/uia-door-check.sh:93
UIAD_SKIP_PREFIXES='build/MilBridge'    # 单值，带斜杠 ⇒ 常规规则可覆盖
```

凡 `'seg seg seg'` / `"seg seg"`（元素**不带** `/`）都不被"词边界 `seg/`"规则命中 ⇒ 漏改 ⇒ 该牙的
覆盖面仍指向旧目录 ⇒ 在搬迁树上表现为 **`--selftest` 从 38/38 掉到 15/38**、真树 `CANARY=BLIND prod=0`。
第 14 轮已成对取证：

```
原始树：UIA_DOOR_SELFTEST=PASS total=38 pass=38 fail=0
搬迁树：UIA_DOOR_SELFTEST=FAIL total=38 pass=15 fail=23；真树 UIA_DOOR=NOINFO reason=canary-blind prod=0
```

⇒ 结论：`UIA-DOOR` 的红**是搬迁引入、且只差这一处**（把 `UIAD_SRC_ROOTS` 改成
`'src.Linux/build src src.Linux/samples'` 即可）；它**不是**既有缺陷，也**不需要**重取臂。

**推广**：搬迁替换集应再加一类正则——引号内、以空白分隔、元素为裸 `(build|tests|samples|tools)` 的值。
本轮全仓扫得该形态**仅此 1 处**（其余 28 处命中都是 `dotnet build build/xxx` 之类**带斜杠**的完整路径，常规规则已覆盖）。
