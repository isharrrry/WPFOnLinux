# 任务：根治"提交号载体" —— 产物不再内嵌 HEAD ＋ `close-wave` 哨兵补齐 13 键，然后重冻

> 现状：`feat-Linux = 79f4527bc`，工作区干净；`[5c/6]` 四档 `PASS`；八颗关键牙 `rc=0`。
> **已知的两个"追位"根**（`docs.Linux/evidence/STRUCTURE-UPSTREAM-WAVE-REPORT.md` §4 与
> `src/Linux/build/MilBridge/blockvalues-shift.tsv` 收尾块）：
> ① `provider` 现件内嵌 `1.0.0+<HEAD sha>`（SDK 默认行为）⇒ **提交后一重建就位移**；
> ② `close-wave [6/6]` 只写 **12 键**哨兵，而 `SENTINEL-SPEC` 要 **13 键** ⇒ 重建后必陈旧。
> **本轮把这两个根拔掉**，让"提交 → 重建 → 判据仍绿"成立。

---

## ① 任务 A：产物不再内嵌提交号（根治①）

1. **先取证**（成对，不许跳）：
   ```bash
   cd /home/links-dev/netTest/GitProj/WPFOnLinux
   # 现件是否内嵌
   grep -a -o '1\.0\.0+[0-9a-f]\{8\}' src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/Provider/bin/Release/DirectWrite.Linux.Provider.dll | head -1
   # 九位现取（含每件的 InformationalVersion 载体）
   grep -rn 'InformationalVersion\|SourceRevisionId\|IncludeSourceRevision' src/Linux/build/Directory.Upstream.props src/Linux/build/SelfBuiltConfig.props src/Linux/build/*.props 2>/dev/null | head
   ```
2. **改**：在**自产栈共用的 props**（优先 `src/Linux/build/Directory.Upstream.props`；若九位里有非托管件，另按其构建脚本处理）加：
   ```xml
   <IncludeSourceRevisionInInformationalVersion>false</IncludeSourceRevisionInInformationalVersion>
   ```
   **口径**：这一行要覆盖**九位全部**（`bridge/pc/pf/windowsbase/provider/win32shim/wic_shim/hbtextline/dwf`）。
   逐位确认（重建后 `grep -a -o '1\.0\.0+[0-9a-f]\{8\}'` 应为**空**；非托管 `.so` 用 `strings | grep` 同类判）。
3. **判据（这条是本轮的核心，必须真跑）**：
   ```
   成对读数：同一份源码，(i) 现在 HEAD 下重建 provider ⇒ sha16=A；(ii) 做一笔提交（**空提交即可**，如 git commit --allow-empty）
             ⇒ 再重建 ⇒ sha16 必须仍 == A（改前会是 ≠ A）。
   ```
   ⚠️ 用空提交做实验；实验完 `git reset --soft`/`--hard` 复原到 `79f4527bc` 或把实验提交保留成正式提交（二选一，报告里写清）。

## ② 任务 B：`close-wave` 写 13 键哨兵（根治②）

- 现在 `[6/6]`（`src/Linux/build/MilBridge/tools/wave-push.sh` 与/或 `close-wave.sh` 的调用）只写 **12 键**；
  `SENTINEL-SPEC` 的 `SPEC_KEYS` 是 **13 键**（`SHA FP PC PF WB WIN32SHIM HBTL WIC PROVIDER DWF WAVE BASELINE BASELINE_SHA16`）。
- **补齐**：让写端产出 13 键（与 `~/w21-verify/w83/bin/w83-sentinel.sh` 的现状对齐），并把两枚哨兵 `cmp` 自证保留。
- **反极性**：缺一键 ⇒ `SENTINEL-SPEC` 必红（现成判据已有；复跑确认没被弄松）。

## ③ 任务 C：重冻 ＋ 收口（做完 A/B 才做）

1. 按 `docs/PORT-SPEC.md §5` 走整波：重建全链 → **重冻**（`docs/CURRENT-STATE.md:9` 换代 `#84`、`ACCEPTANCE-BASELINE.md` 追加 `# RE-FROZEN`、
   两枚哨兵、`~/w21-verify/w84/` 记录段 ＋ `GENS['#84']`、`blockvalues-shift.tsv` 重钉 —— 原则上 `provider/pc/windowsbase/dwf` **不再需要** live= 声明，
   只留 `pf` 在 `NO_FIXED_POINT`（若实测它们真的稳定了，把多余声明**删掉**并在报告里给成对证据））。
2. **顺序（本仓铁律）**：**先把所有提交做完，再冻结，最后跑 `verify-all ×2`**；冻后不再新增提交。
3. **验收**：
   - `[5c/6]` 四档 `PASS`，且**在"提交之后重建"的语境下**仍 PASS（这是本轮存在的理由）；
   - `bash Guide.Linux/verify-all.sh` **×2** = **0 ❌**；
   - `THIRDPARTY=PASS max_colors ≥ 800`（空帧无回归）；
   - 八颗关键牙 `rc=0`；`git status --short` 干净。

## ④ 边界

- **允许**：改 `src/Linux/build/Directory.Upstream.props` 等**自产栈共用 props**、`src/Linux/build/MilBridge/tools/wave-push.sh` /
  `src/Linux/build/close-wave.sh`（哨兵键数）、`blockvalues-shift.tsv`、`docs/{CURRENT-STATE.md,ROUTES.md}`、`HANDOFF-NEXT.md`、
  `~/w21-verify/**`（外部冻结链）。
- **禁止**：改产品**逻辑**（只许加"不入提交号"这一行构建属性）、改落点、削弱任何判据、把空帧洗绿、把 `NOINFO` 当绿。
- 改判据/覆盖面内件 ⇒ 同趟登记（`HANDOFF-NEXT.md` 更正行、必要时 `inputs_fp`/`--expect` 同趟）。

## ⑤ 硬停

- A 做完若**仍有**件内嵌提交号（`grep` 非空）⇒ 逐件点名、给出你判定的原因；**不许**用 `sed` 去篡改产物二进制来"达标"。
- 若"提交 → 重建 → 判据仍绿"这条最终立不住 ⇒ 停手：保留**当前可用态**（`[5c/6]` PASS、`verify-all` 有 66/0 的既跑读数），
  输出成对读数与结论，**不许留半改状态**。

## ⑥ 报告

- A：改动行原文；`grep` 逐位成对读数（改前/改后）；**空提交实验**的成对读数（`provider` sha16 A vs A）。
- B：改了什么；13 键哨兵原文（`cmp IDENTICAL`）；缺键反极性的红。
- C：`[5c/6]` 四档原文；`verify-all` **逐趟**步骤数；`THIRDPARTY` 行；`blockvalues-shift.tsv` 最终行（哪些键还在声明、为什么）；
  `git log --oneline -5` ＋ `git status --short`；九位/`inputs_fp` 前后值。
- 结论：**达成**（并列出 `feat-Linux` 新位置、`upstream/` 状态）或 **未达 ＋ 具名残余 ＋ 推荐**。
