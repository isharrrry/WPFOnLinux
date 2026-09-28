# P1 尾盘侦察 —— 22 项剩余未闭项逐条可执行清单 ＋ 串行分波建议

> **本件性质**：**只读侦察 ＋ 判据先写**。唯一写入仓内的件就是本件；`$N` 内其余件**一个字节都没改**（`git status` 的改动项**全部**属于**另一条在飞车道**，见 §0-4 与 §5-1，并已逐件取 mtime 与我无关地取证）。
> **自报 sha16 口径（逐字）**：`head -n -1 <本件> | sha256sum | cut -c1-16`（末行即自指行，逐次重算）。
> **读取时刻**：`2026-09-28T15:42:48+08:00`（首取）→ `2026-09-28T15:46:2x+08:00`（末取）；**逐条另注**。凡未注时刻的数一律取「§0-1 那一趟」。
> **纪律 31**：本件**不引行号作正文判据**，一律内容锚；行号只作「仅本次有效」旁注。

---

## §0 现取基线（读时 `2026-09-28T15:42:48–15:46:2x+08:00`；`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`）

### 0-1 结构面（一条命令现取，逐字）

| 量 | 现取值 | 命令 |
|---|---|---|
| `HEAD` | `88ab841`（`88ab841414b6b5e2…`） | `git log --oneline -1` |
| 远端 `origin/feat-Linux` | `88ab841414b6b5e2…`（**本地 == 远端**） | `git ls-remote origin refs/heads/feat-Linux \| cut -c1-16` |
| 冻结哨兵（`docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 行） | `gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `sed -n '9p' docs/CURRENT-STATE.md` |
| 基线件 | `b96d4312565a3c49`／**1,224,932 B** | `sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` |
| `verify-all.sh` 步数 | **55**（`grep -c '^run_step "'` = 55；首行 `DECL` ＝ `# VERIFYALL-STEPS-DECL: 55 gen=#79`） | `grep -c '^run_step "' verify-all.sh` |
| 覆盖面 | **226** 件（`[42]` ＝ `run_step "FP-MANIFEST-TEETH" … --expect 226`） | `grep -n 'run_step "FP-MANIFEST-TEETH"' verify-all.sh` |
| `inputs_fp` | `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`（连算两遍同值；`~/w153a/bin/infp.sh fp` 与 `~/w-p0mig/bin/infp-n.sh fp` **同值**） | 两件复算器各跑一遍 |
| `docs/ROUTES.md` | `3fc6b1598fb4e043`／**823 行** | `sha256sum`；`wc -l` |
| `build/MilBridge/HANDOFF-NEXT.md` | `61c34bb9d4168f65`／**289 行** | `sha256sum`；`wc -l` |
| `§下一波未闭项` 条目数 | **18**（用本任务 `Verify` 段给出的 `awk` 原样跑） | `awk '/^## §下一波未闭项/{f=1} f&&/^[0-9]+\. \*\*/{c++} f&&/^> \*\*本节与/{f=0} END{print "unclosed_items=" c+0}' build/MilBridge/HANDOFF-NEXT.md` |
| `DEFREG` | `DEFREG=PASS declared=215 route_ids=215`；`DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-` | `bash build/MilBridge/tools/defect-registry-check.sh \| tail -3` |
| `REPORTID` | `REPORTID=PASS files=190 ids=1957 declared=215 glob=build/MilBridge/*report*.md`；`BOOK_ENTRY_UNREQUIRED_MISSING n=15`（**`n=16` → `n=15`，名单里 `D-G179` 已消失**） | `bash build/MilBridge/tools/report-id-domain-check.sh \| tail -3` |
| `ALIAS` | `ALIAS=PASS examined=18042 linked_gt1=0 aliased_out=0 aliased_allowed=0 aliased_unallowed=0 roots=1 maxdepth=16 wall_s=12.06 rc=0 reason=no-out-of-repo-alias` | `bash build/MilBridge/tools/repo-alias-check.sh --allow build/MilBridge/repo-alias-allow.tsv` |
| `§13` 树内 TASK 行（我独立抽取） | **tree-form 79 行** ＝ 带 `[kind]` **77** ＋ 不带 `[kind]` **2**（`TASK-0202`／`TASK-0204`）；带 `[kind]` 的 77 行按「取标签后那一个记号」＝ **✅74／🟡1／🔴2／⚪0**；按「整行任一命中」＝ ✅75／🟡2／🔴5 | 自写抽取器（本趟现算，§5-6） |
| `~/w21-verify/w*-POST.done` | **25** 件（`w56`…`w80`）；`w80-POST.done` ＝ `0 B`／mtime `2026-09-28T11:51:17.112475971+08:00` | `ls ~/w21-verify/w*-POST.done \| wc -l` |
| `~/w21-verify/*record*` | 现取 **`w56`…`w77`**（**无 `w80-record.txt`**） | `ls ~/w21-verify/*record*` |
| 两哨兵 | `/tmp/bridge-frozen.flag` 与 `~/wfp-runs/bridge-frozen.flag`：各 **279 B**／`sha16=6cb3f97388c3c4dc`／mtime `2026-09-28T13:48`／**`cmp` IDENTICAL** | `cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` |

### 0-2 本任务的 `Verify` 三条（原样真跑，逐条读数）

```
$ cd /home/links-dev/netTest/GitProj/WPFOnLinux && test -s build/MilBridge/P1-tail-scout.md && wc -l build/MilBridge/P1-tail-scout.md && sha256sum build/MilBridge/P1-tail-scout.md | cut -c1-16
$ bash build/MilBridge/tools/defect-registry-check.sh 2>&1 | tail -1 && git status --porcelain
$ awk '/^## §下一波未闭项/{f=1} f&&/^[0-9]+\. \*\*/{c++} f&&/^> \*\*本节与/{f=0} END{print "unclosed_items=" c+0}' build/MilBridge/HANDOFF-NEXT.md
```
- 第 2 条的 `defect-registry-check.sh` 末行现取 ＝ `DEFREG=PASS declared=215 route_ids=215（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）`。
- 第 2 条的 `git status --porcelain`：**15:42:48 现取 ＝ `0`；15:45:16 现取 ＝ `3`**（详见 §0-4）。⇒ **`porcelain=0` 不是不变量**。

### 0-3 关键仪器的现取 sha16（逐件现算；凡与在册/派单值不同者加 `⚡`）

| 件 | 现取 sha16 | 在册值 | 判 |
|---|---|---|---|
| `build/MilBridge/tools/pts-pages-guard.sh` | `bfa6414eb7104f85` | `bfa6414eb7104f85`（HANDOFF 第 8 条） | 同 |
| `build/MilBridge/tests/PtsPagesProbe/session_inner.sh` | `f687ad65fd05f6e2` | `f687ad65fd05f6e2`（HANDOFF 第 9 条） | 同 |
| `build/MilBridge/tools/pkg-src-retiredpath-check.sh` | `d54a5a14c1934bac` | `d54a5a14c1934bac`（HANDOFF 第 4 条） | 同 |
| `build/MilBridge/tools/defect-registry-check.sh` | `c2d0773e5561a9d1` | `c2d0773e5561a9d1`（HANDOFF 第 12 条） | 同 |
| `build/MilBridge/P0-w80-report.md` | `3cc9becdc15f2211`／104 行 | `3cc9becdc15f2211`／104 行（HANDOFF 第 1/2/3/5/6/7 条） | 同 |
| `build/MilBridge/P0-mvp-pts-report.md` | `d79a0c009515b3c4`／190 行 | `d79a0c009515b3c4`／190 行（HANDOFF 第 8 条） | 同 |
| `build/MilBridge/P0-mvp-segv-report.md` | `dc3bc81f737a2268`／535 行 | 在册多处引 §11／§13／§14 | 现取 |
| `build/MilBridge/repo-alias-allow.tsv` | `5813863882022812` | 未在册 | 现取 |
| `build/MilBridge/book-entry-required.tsv` | 1633 B／16 行（含 6 行表头注释） | `t19` 建 | 现取 |
| `~/w21-verify/w27-freeze.py` | `7e3d0fecefa9f20c`／149,935 B | `7e3d0fecefa9f20c`（HANDOFF 第 5 条） | 同 |
| `~/w79c/bin/w79-freeze2end.sh` | `a9f0de4cfc39a0b2` | `a9f0de4cfc39a0b2`（§绑定规则 A 表 #1） | 同 |
| `~/w79c/bin/w79-push.sh` | **`5015004b0f0d917e`**／23,251 B／mtime `2026-09-28 12:54` | `fb46d69e6a5cd78a`（§绑定规则 A 表 #5） | **`⚡` 已变** |
| `~/w79c/bin/diffclass.sh` | `0b9d9c41e983a930` | `0b9d9c41e983a930`（§绑定规则 A 表 #8） | 同 |
| `~/heavy-slot.sh` | `963987607f95d591`；`:92 min_avail="${HEAVY_MINAVAIL:-1200}"` | `963987607f95d591`；默认 **1200**（§绑定规则 B 表 #15） | 同 |
| `build/MilBridge/tools/fp-manifest-step.sh` | `db4a2d9856534aba` | `db4a2d9856534aba`（§绑定规则 A 表 #4） | 同 |
| `build/MilBridge/tools/fp-manifest-teeth-check.sh` | `be19edddf7f02797` | `be19edddf7f02797`（§绑定规则 A 表 #4） | 同 |
| `build/MilBridge/tools/nul-bytes-check.sh` | `2902c14fa1081a5c` | `2902c14fa1081a5c`（§绑定规则 A 表 #7） | 同 |
| `build/MilBridge/W78A-report.md` | `720e12fceb761941`／**582** 行；`head -568` ＝ **`0dbc62b1d1cf86ee`** | 引用＝`0dbc62b1d1cf86ee`／568 行（HANDOFF 第 16 条） | **前缀口径成立** |

### 0-4 ⚡ 现取发现：**`$N` 里此刻另有在飞写者**（`porcelain` `0 → 3`）

```
$ date '+%F %T.%3N' ; git status --porcelain
2026-09-28 15:45:16.920
 M build/MilBridge/tools/defect-registry-declared.tsv
 M samples/WpfFeatureProbe/KNOWN-DEFECTS.md
?? build/MilBridge/P1-dg179-criteria.md
```
逐件 mtime（现取）：`P1-dg179-criteria.md` `15:44:06.153013319`／`KNOWN-DEFECTS.md` `15:44:34.595902646`／`defect-registry-declared.tsv` `15:44:51.954839295`。
`git diff --stat` ＝ `defect-registry-declared.tsv | 4 ++--` ＋ `KNOWN-DEFECTS.md | 18 ++++++++++++++++++`（`2 files changed, 20 insertions(+), 2 deletions(-)`）。
`KNOWN-DEFECTS.md` 现取 `sha16=fa1715f3edefb7eb`（`grep -c 'D-G179'` ＝ **7**）；新增段落的锚句逐字 ＝ `## P1-W1 登记批（2026-09-28；**一条入册**：把「提及即声明、册内无条目」的候选补成**正式条目**`；declared.tsv 的 `DECL-GEN` 由 `2026-09-28 14:29:00 +0800` 刷成 **`15:44:51 +0800`**、`DECL-ANCHORS` 的 `KD=` 由 `2152460b7e412352` 刷成 **`fa1715f3edefb7eb`**。
⇒ **结论**：这**不是我在写**（本件此前的 `porcelain` 现取为 `0`）；是**另一条车道**（`D-G179` 条目化）在 `15:44:06–15:44:51` 三件落地。**本件全部读数因此分两档**：`15:42:48` 档（`porcelain=0`）与 `15:45:16` 档（`porcelain=3`），**逐条注明用哪一档**。

---

## §1 A 组 · 3 条未绿 `[MVP]`

### A-1 `TASK-0007` —— 切「富文本」23／「流文档」24

**① 现状现取读数**（读时 `2026-09-28T15:43:0x+08:00`）
- 判据件 `build/MilBridge/tools/pts-pages-guard.sh` ＝ `bfa6414eb7104f85`；现跑 `bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` ⇒ `PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded`（`rc=0`）。
  ⚠️ **`direction=in-file` 与 `phase=degraded`**：这条绿是「**止损还在**」，**不是**「两页排版正确」。
- 逐腿机读行（**现取整行照抄**）：
  - `build/MilBridge/tests/PtsPagesProbe/evidence/leg_23.env`（`9fb8af8d6fdebb45`）＝ `LEG k=23 alive=yes app_rc=143 magenta=50236 colors=843 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae=140697 ink=428205`
  - `build/MilBridge/tests/PtsPagesProbe/evidence/leg_24.env`（`afb1081916bd0d0d`）＝ `LEG k=24 alive=yes app_rc=143 magenta=54826 colors=851 ns=HandyControlDemo.UserControl.FlowDocumentDemo ae=221857 ink=423547`
  - `evidence/app_g1.log` ＝ `eb6af2e16ba2bcfb`／116,911 B／mtime `09:32`；`grep -c 'entry=LoCreateContext'` ＝ **3**、`grep -c 'entry=CreateInstalledObjectsInfo'` ＝ **0**。
- `docs/ROUTES.md` 树内该行仍印刷旧判词：`切「富文本」23／「流文档」24 **必死 rc=134**`（内容锚：行首即 `TASK-0007 [MVP] 🔴` 的那一行）；其后 dated 加注行逐字为 `**该形态在 gen=#63 上已不成立**`。
- `ROUTES.md §15af` 的未绿三行句：`未绿 [MVP] 三条（现取，不许折算成绿）`。

**② 入口（原文照抄）**
```
bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence
```
装置（重活那一半，**不在门禁里同步跑**）＝ `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh`（在覆盖面内，现取命中 1）。

**③ 判据草案**
- objective：`TASK-0302` 真实现落地后，把「23／24 两页」的绿条件**成对反转**（本仓既有做法：绿条件与红条件同趟改）。
- acceptance：**反转后**绿 ＝ `洋红 = 0 ∧ 无具名行 ∧ native 真实排版 ∧ alive=yes`；红条件同趟写死为「洋红 ≥ 20000 ∨ 具名行在位 ∨ native_gap ≥ 1」。**不许**在 `TASK-0302` 未落地时给本件发绿。
- verify（单一命令、可重跑、`rc=0`）：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence 2>&1 | grep -q '^PTS_GUARD=PASS' && echo A1_VERIFY_OK
```
（反转落地后，同一命令的合格判据改为 `grep -q '^PTS_GUARD=PASS'` ∧ `grep -c 'magenta=0' evidence/leg_23.env evidence/leg_24.env` ＝ 2。）

**④ 归属与代价**：改仓件＝是（`build/MilBridge/tools/pts-pages-guard.sh`；反转文本本仓做法是**写进判据件自身**）。`DEFREG` route 件＝**否**（route 键只有 `KD/CS/HO/AB`，见 §5-8）。触 `fp_inputs()`＝**是**（该件现取在覆盖面内 ⇒ `inputs_fp` 必移；**覆盖面件数不变** ⇒ `[42] --expect 226` 不动）。**重活＝是**（需 Xvfb ＋ 应用冷启 ＋ 真实点击；A 臂 2 腿 ≈ 45 s／腿，须走 `~/heavy-slot.sh` ＋ 后台作业）。

**⑤ 依赖**：**硬依赖 A-3（`TASK-0302`）落地**（否则反转即造「用旧判据给真因发绿灯」的假绿）。与 A-2 **无**依赖，但**不得同波**（两者都要显示位与槽）。

**⑥ 分波建议**：见 §4 **W8**（单独成波，且必须排在 W7 之后）。

---

### A-2 `TASK-0201` —— 静默 `rc=139` ＋ 0 字节日志

**① 现状现取读数**（读时 `2026-09-28T15:43:2x+08:00`）
- 装置件 `build/MilBridge/tools/silent-hit-v2-check.sh`（在覆盖面内，现取命中 1）；台账 `build/MilBridge/tools/silent-hit-v2-cases.tsv` ＝ `7bc8a739cb66927c`／13 行（1 表头 ＋ 12 用例）；剔除集唯一来源 `build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv` ＝ `4270ab3da7a1d6d8`（**与在册值逐位相同**）。
- 现跑（`rc=0`）逐行照抄：
  - `SILENTHIT_CASES file=silent-hit-v2-cases.tsv rows=12 examined=12 hits=6 nothit=4 noinfo=2 mismatch=0 posctl=2/2 expect=12`
  - `SILENTHIT=PASS` ／ `SILENTHIT_RC=0`
- 在册读数（`docs/ROUTES.md` 树内该行的 dated 追加，逐字）：**现件代 `0/175` 命中 ⇒ 95% 单侧上界 `1.6973%`**（点估计 `0.0000%`）；修前成对臂 `1/77 ⇒ ≤3.815851%`；率差 `+1.298701%`，**Newcombe 95% CI `[−1.100611%, +6.996199%]`（含 0）**、Fisher 单侧 `p=0.3056`；基线率闸 `BASELINERATE=FAIL reason=VOID-PREMISE`（`ci_upper(0.0152) < gate(0.0382)` ∧ `observed(0.0000) < effect(0.0130)`，`registered_in_observed_ci=1`）。
- 报告载体：`build/MilBridge/P0-mvp-segv-report.md` ＝ `dc3bc81f737a2268`／535 行（在册引 §11／§13／§14）。

**② 入口（原文照抄）**
```
bash build/MilBridge/tools/silent-hit-v2-check.sh --cases build/MilBridge/tools/silent-hit-v2-cases.tsv --expect 12
```
重活那一半（**产出端**）＝ `build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh`（**在仓内但 `UNWIRED`**：`grep -cE '^[[:space:]]*run_step .*silenthit' verify-all.sh` ＝ 0）。

**③ 判据草案**
- objective：在**先写死趟数与功效**的前提下重测「现件代静默 SEGV 命中率」，并把**基线率闸**的 `VOID-PREMISE` 归因（缺时间窗）补齐。
- acceptance：**可判真假的三条并列** —— ① 每条腿的 `SILENT_SEGV_HIT` 按在册口径求值（`APP_TEXT_BYTES_TRIMMED==0 ∧ STACKOVF==0 ∧ SEGV_BRANCH!=none`）；② 分母按**件代**分开（跨件代**禁止合池**）；③ 报上界必须**同时**报 `registered=<R>/<n>@<时间窗>` 与 `gate=`／`effect=`，且 `REGDEC_DIRECTION=` 必须由器具打印（`D-G115`）。
- verify（单一命令、可重跑、`rc=0`）：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/silent-hit-v2-check.sh --cases build/MilBridge/tools/silent-hit-v2-cases.tsv --expect 12 2>&1 | grep -q '^SILENTHIT=PASS' && echo A2_VERIFY_OK
```
（**这条只判「判据装置还活着 ∧ 不许把不可判当零命中」**；它**不**判该 SEGV 已清零 —— 与 `#68` 口径逐字同。）

**④ 归属与代价**：改仓件＝是（`docs/ROUTES.md` 的结账行 ＋ `build/MilBridge/P0-mvp-segv-report.md`；若重测采新口径还要动 `silent-hit-v2-cases.tsv`）。`DEFREG` route 件＝**否**（ROUTES 不在 `ALLKEYS`，见 §5-8）。触 `inputs_fp()`＝**是**（两件在覆盖面内 ⇒ 必移；件数不变 ⇒ `--expect 226` 不动）。**重活＝是（本件最重的活）**：现件代要跑满功效口径趟数（在册 `≥131 腿`（2.26%）／`≥299 腿`（1.00%）），**必须走 `~/heavy-slot.sh --min-avail 1500 --max-hold 1800 --wait 1800 --` ＋ 后台作业**，跑前现取 `df -Pk` 第 4 列与 `free -m` 的 `avail`／`swapfree`。

**⑤ 依赖**：无先决（材料齐）；但**必须独占显示位与槽** ⇒ 与 A-1／A-3／B-9 的腿批**互斥**。

**⑥ 分波建议**：见 §4 **W6**（单独成波，重活独占）。

---

### A-3 `TASK-0302` —— PTS ／ 原生 LineServices

**① 现状现取读数**（读时 `2026-09-28T15:43:1x+08:00`）
- 复算器 `build/MilBridge/tools/pts-gap-count-check.sh` ＝ `7675737500702c8a`（**不在覆盖面内** —— 现取 `infp-n.sh list` 命中 **0**；这是一个**独立发现**，见 §5-9）。
- 现跑（`rc=0`）逐行照抄：
  - `DISK_HEADROOM=PASS avail_kb=77852988`
  - `LIVE  tool=100 dead=11 artifact=1 ops=88 impl=95 so16=6825dd7071387a46 exports=556 root=/home/links-dev/netTest/GitProj/WPFOnLinux`
  - `W66PRE16 live=bf6b683d94549087`
  - `PTSGAP_CITED=PASS refs=1 strict=1`
  - `PTSGAP=PASS tool=100 dead=11 artifact=1 ops=88 impl=95 so16=6825dd7071387a46 exports=556`
- 九位之一 `win32shim` 现取 ＝ `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`6825dd7071387a46`**／336,984 B（与哨兵 `WIN32SHIM=` 逐位相同）。
- 导出面三口径（`ROUTES.md §15af` 末段口径句）：`wc -l < src/WpfGfx.Linux.Native/bin/exports.txt` ＝ **556**（我现取复算）。
- 前沿（**唯一**载体，逐字）：`evidence/app_g1.log`（`eb6af2e16ba2bcfb`）`3× entry=LoCreateContext`、`0× entry=CreateInstalledObjectsInfo` ⇒ 前沿 `CreateInstalledObjectsInfo → LoCreateContext`（跳数 0 → 1）。
- 门禁步 `PTS-PAGES` **只读 `leg_*.env` 的列、不读 `entry=`** ⇒ 它的绿对「前沿位移」**零证据力**；而 `pts-pages-guard.sh` 件头 G10 描述里具名的仍是**旧前沿** `CreateInstalledObjectsInfo`（现取行首原文：`#   G10 至少一条 native \`PTS_GAP entry=CreateInstalledObjectsInfo\`           否 ⇒ FAIL`）。

**② 入口（原文照抄）**
```
bash build/MilBridge/tools/pts-gap-count-check.sh
```
（在册判据句：**「进度 ＝ 具名前沿跳数，不是缺口条数」**；零证据力口径句：**「门禁步 `PTS-PAGES` …只读 `leg_*.env` 的列，不读 `entry=` ⇒ 它的绿对"前沿位移"零证据力」**。）

**③ 判据草案**
- objective：把 `PTS`／原生 `LineServices` 的缺口从「计数下降」改成**具名前沿位移**（每增量一个可判真假的前沿跳数）。
- acceptance：**三条并列** —— ① `PTSGAP=PASS` 且 `ops=`／`impl=`／`tool=` 三口径**同时**印且**逐条口径写明**；② 前沿以 `app_g1.log` 的**具名行**为准，跳数必须**成对**（前 → 后）；③ **「3 个 `Lo*` 名字离开名单而能力为 0 ＝ 假进度」**必须由装置自身判红（`#66` 的 `P03` 实证的反退化腿）。
- verify（单一命令、可重跑、`rc=0`）：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/pts-gap-count-check.sh 2>&1 | grep -q '^PTSGAP=PASS' && echo A3_VERIFY_OK
```

**④ 归属与代价**：改仓件＝**是，且是产品面**（`src/WpfGfx.Linux.Native/src/win32_pts.c` 及其余 `win32_*.c`／`win32_internal.h`；`src/WpfGfx.Linux.Native/bin/*` 是**本地物件、被 `.gitignore` 忽略**，不进 git）。`DEFREG` route 件＝**否**。触 `fp_inputs()`＝**是**（`src/WpfGfx.Linux.Native/**/*.{c,h}` 已在白名单内 ⇒ `inputs_fp` **必移**；件数不变 ⇒ `--expect` 不动）。**重活＝是**（`dotnet build` ＋ 应用 ＋ 显示位 ＋ 槽；且**每次构建都会让 `provider` 位位移**，见 B-18）。

**⑤ 依赖**：无先决（可立刻起）；但**它是 A-1 的硬先决**，且**每次产品增量都会动九位**（`win32shim` 必动）⇒ 必须**独占一整波**，不许与仪器波并行。

**⑥ 分波建议**：见 §4 **W7**（长线，**逐增量各成一波**）。

---

## §2 B 组 · `HANDOFF-NEXT.md §下一波未闭项` 现取 **18** 条

> 现取条目数 `unclosed_items=18`（§0-1 的 `awk` 原样跑）。**逐条以我现取为准**；条目编号 ＝ 该节内 `^[0-9]+\. \*\*` 的序数。

### B-1 · `D-G176` 预留：九位跨同一输入两次整波不复现

1. **现状现取读数**：证据件 `build/MilBridge/P0-w80-report.md` ＝ `3cc9becdc15f2211`／104 行；其 `§6` 标题逐字 ＝ `## §6 🔴 两条结构性结论（本波最有价值的发现；`D-G176` 预留、本波不登记）`；`§10-1` 逐字 ＝ `1. **\`D-G176\`（预留）**："九位跨同一输入两次整波不复现（同源同参、机制未定）"`。现取九位值的四个不同取值点：块内 `provider` `7e8a217b4165a6b9`｜`#77` 块声明 `759ac1686e5ef87d`｜重建 `8cb1b50619f4c133`｜**canon live 现取 `24e4e0a731dbed40`**（`build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll`，104,448 B，mtime `2026-09-28 13:11:49`）。
2. **入口**：`build/MilBridge/P0-w80-report.md` 内容锚 `## §6 🔴 两条结构性结论` ＋ 同件内容锚 `1. **\`D-G176\`（预留）**`；机器面入口 ＝ `bash build/MilBridge/tools/wave-freeze-consistency-check.py` 的 `WFREEZE_BLOCKVALUES_HIT` 行。
3. **判据草案**：
   - objective：把「同源同参两次整波产出不同字节（机制未定）」＋「冻结与哨兵是该波**件写入序列**的最后两步」＋「`blockvalues-shift.tsv` 重钉与 `[5c/6]` 同趟不可兼得」登记为**正式条目**。
   - acceptance：册内出现 `^#{2,4}` 条目形态标题 ∧ 该编号进 `declared` 集 ∧ 册内**至少出现一次**（三条合取，`book-entry-required.tsv` 语义）。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/defect-registry-check.sh 2>&1 | grep -q '^DEFREG=PASS' && grep -q '^## .*D-G176' samples/WpfFeatureProbe/KNOWN-DEFECTS.md`
4. **归属与代价**：改仓件＝是（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` ＝ route 键 **`KD`** ⇒ **同趟必须 `--emit` 重发 `declared.tsv`**，否则规则④ `undeclared-id-in-route` 判红）。触 `fp_inputs()`＝**否**（`KD`／`declared.tsv` 现取命中 **0／0**）。**重活＝否**（纯文本 ＋ 秒级工具）。
5. **依赖**：无。**可与 B-3..B-9 之外的任一条同波**；但**必须与 B-12 的「同趟重发」合并**（两者改同一件 `KD` ＋ 同一件 `declared.tsv`）。
6. **分波建议**：**W1**。

### B-2 · `D-G178`（候选）＋ 车道侧同族：冻后 `--prev-check-only` 假红

1. **现状现取读数**：`~/w21-verify/w27-freeze.py` ＝ `7e3d0fecefa9f20c`／149,935 B／mtime `2026-09-28 11:50`。现取三条关键实现位逐字：`_BLK_HDR = re.compile(r'^# (?:RE-FROZEN #\d+\b|⏪ \*\*（历史[^）]*）\*\*# RE-FROZEN #\d+\b)')`；`if l.startswith('# RE-FROZEN ' + prev):`；`return None, 'baseline-has-no-RE-FROZEN-%s-block' % prev` ⇒ **入口锚仍是严格行首 `startswith`**，出口锚仍容忍装饰（正则）。⇒ `D-G178` 的机制**现取仍在位**。车道侧载体 `~/w79c/bin/w79-push.sh` ＝ **`5015004b0f0d917e`**（**不在仓内**）。
2. **入口（原文照抄）**：`python3 ~/w21-verify/w27-freeze.py --prev-check-only <世代> [--baseline <基线件>]`；车道侧内容锚 ＝ `~/w79c/bin/w79-push.sh` 里取块的那一段（在册引作「按 `^# RE-FROZEN #79` 严格行首」）。
3. **判据草案**：
   - objective：把「冻结器入口锚严格行首 vs 出口锚容忍装饰 ⇒ 冻后假红」登记为**正式条目**，并把**仓外**推牙搬进仓内（锚改内容锚）。
   - acceptance：**两极化真跑** —— 正极＝冻后块未被加装饰 ⇒ `--prev-check-only` 返回 `PASS`（`rc=0`）；反极＝块头**被加装饰** ⇒ **必须真红并点名**（不是取空拦停）。搬入的仓内件必须在 `fp_inputs()` 白名单内。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && python3 -c "import re;L=open('/home/links-dev/w21-verify/w27-freeze.py',encoding='utf-8').read();print('BLK_HDR' if '_BLK_HDR' in L else 'MISS')" && grep -q '^D-G178' samples/WpfFeatureProbe/KNOWN-DEFECTS.md`
4. **归属与代价**：改仓件＝是（`KD` ＋ 新仓件 `build/MilBridge/tools/wave-push.sh` 之类；**加新件 ⇒ 覆盖面 +1 ⇒ `[42] --expect` 同趟改**）。`KD` 是 route 件 ⇒ 同趟 `--emit`。**重活＝否**。
5. **依赖**：与 **B-6** 同源同件（`~/w79c/bin/w79-push.sh`）⇒ 建议**合波**；与 **B-14 / C-1**（哨兵搬仓内）**同族**，但可分开落地。
6. **分波建议**：**W3**（与 B-6 合波）。

### B-3 · 三条死根面（`unused`／`unused`／`used` ＋ 死根面 `NOINFO`）＋ 六件字面残留

1. **现状现取读数**（读时 `2026-09-28T15:44:2x+08:00`；**我按「仓内 `.cs` 里出现退役路径」独立复扫，得 9 件**，与 `P0-w80-report §9` 的「九件现存 ＋ `HbTextLineParity` 本波已修」**逐数吻合**）：

   | 件 | 现取 sha16 | 命中行（**仅本次有效**） | 原文摘要 | 报告结论 |
   |---|---|---|---|---|
   | `build/MilBridge/tests/T2eLineHeight/Program.cs` | `26abfba8bbd1ac17` | `24` | `private const string Root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";` | `unused` |
   | `build/MilBridge/tests/PcLineOracle/Program.cs` | `a787a9db23c3302c` | `171` | 同形常量 | `unused` |
   | `build/MilBridge/tests/CoverageProbe/Program.cs` | `a6d0352b86467111` | `88`／`1028`／`1159`／`1240` | 常量 ＋ 三处 `const string root` | `used`（三支 tab 臂宿主）＋ 常量本身 `unused`；**死根面 `NOINFO(臂日志零签名)`** |
   | `build/MilBridge/tests/FrameProbe/Program.cs` | `503e6ebd86d70303` | `309` | `string authPc = "…/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll";` | `NOINFO(未做活/死判定)` |
   | `build/MilBridge/tests/ResolverGuardProbe/Program.cs` | `76caccc4693bf4a1` | `40` | `string shim = TakeOption(rest, "--shim") ?? "…/src/WpfGfx.Linux.Native/bin/libwpfwin32.so";` | 同上 |
   | `build/MilBridge/tests/LsProbe/Program.cs` | `b8dba8fbbc05a327` | `9` | `const string shim = "…";` | 同上 |
   | `build/MilBridge/tests/BboxProbe/Program.cs` | `c06f605002cb5d48` | `23` | `string font = argv.Length > 0 ? argv[0] : "…/build/fonts/NotoSans-Regular.ttf";` | 同上 |
   | `build/MilBridge/tests/IcuBreakParity/Program.cs` | `1b2815e197638a23` | `62` | `_root = "…";` | 同上 |
   | `build/DirectWrite.Linux/WicSeamProbe/Program.cs` | `08f7bd96d1c33f22` | `15` | `: "…/samples/HelloMil/screenshot.png";` | 同上 |

   已修的反证：`build/MilBridge/tests/HbTextLineParity/Program.cs` **现取 0 命中**（`grep -c 'wpf-linux-20260906'` ＝ 0）。

2. **入口（原文照抄）**：`build/MilBridge/P0-w80-report.md` 内容锚 `### §9` 表行 ＋ 判据命令 `git ls-files '*.cs' | while read -r f; do grep -q 'wpf-linux-20260906' "$f" && echo "$f"; done`；`T2e` 的「无运行期调用者」判据逐字 ＝ `grep -c 'T2e' verify-all.sh` = **0**（我现取复算：**0**）。
3. **判据草案**：
   - objective：把九件 `.cs` 的**死根面**逐件判「活/死」并清掉死根（活根改为**环境变量或参数注入**，缺则**响亮失败**）。
   - acceptance：① 九件 `.cs` 的退役路径字面量**归零**（`git ls-files '*.cs' \| xargs grep -l 'wpf-linux-20260906' \| wc -l` ＝ **0**）；② **`CoverageProbe` 的「死根面」必须判到底** —— `NOINFO(臂日志零签名)` **不许当绿**，判法＝让三支臂真跑一轮并断言日志里**有**目标路径签名（有 ⇒ `used`；无 ⇒ 该面判死并清根）；③ **两极化**：任一被清件重新塞回死根 ⇒ 牙**必红并点名**。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && test "$(git ls-files '*.cs' | xargs grep -l 'wpf-linux-20260906' 2>/dev/null | wc -l)" = 0 && echo B3_VERIFY_OK`
4. **归属与代价**：改仓件＝是（**9 件 `.cs`**；若①`P0-w80-report §9` 的结论要写回在册还要改 `KD`）。`KD` 是 route 件 ⇒ 同趟 `--emit`。触 `fp_inputs()`＝**是**（这些 `.cs` 在覆盖面内 ⇒ `inputs_fp` 必移；件数不变 ⇒ `--expect 226` 不动）。**重活＝部分**（`CoverageProbe` 的三支臂要真跑 ⇒ **需槽 ＋ 显示位**；其余八件是纯文本改动）。
5. **依赖**：**B-3 必须先行于 B-4** —— 若先扩 B-4 的扫描域到 `*.cs`，9 件死根**当场判红**（这是**正确的红**，但会把两件事搅成一波返工）。二者**同波、同波内先 `.cs` 后牙**。
6. **分波建议**：**W2**（与 B-4／B-7／B-8／B-9 同波；`CoverageProbe` 那条腿走槽）。

### B-4 · 守卫射程洞：`pkg-src-retiredpath-check.sh` 的 `tree` 面不扫 `*.cs`

1. **现状现取读数**：`build/MilBridge/tools/pkg-src-retiredpath-check.sh` ＝ **`d54a5a14c1934bac`**（与在册同值）；`collect_corpus()` 的 `tree` 分支**现取原文**：
   ```
   find "$ROOT" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \) 2>/dev/null
   find "$ROOT/build" "$ROOT/tests" "$ROOT/src" -type f \
        \( -name '*.sh' -o -name '*.py' -o -name '*.c' -o -name '*.h' \) 2>/dev/null
   ```
   ⇒ **无 `*.cs`**。现跑 `bash build/MilBridge/tools/pkg-src-retiredpath-check.sh --tree` 末行照抄：`RETIREDPATH=PASS mode=tree files=229 hits=3 code=0 declared=3 self_skip=1 needle=wpf-linux-20260906` —— 而**同一个 needle 在 `*.cs` 里现取命中 9 件**（§B-3 表）⇒ **守卫全绿而九件带死根** ＝ 射程洞**现取成立**。
2. **入口（原文照抄）**：`bash build/MilBridge/tools/pkg-src-retiredpath-check.sh --tree`；豁免通道 ＝ `build/MilBridge/retired-path-provenance.tsv`（`kind=code` **永不豁免**）。
3. **判据草案**：
   - objective：把 `*.cs` 纳入 `tree` 面扫描域（射程与 `src/`／`tests/`／`build/` 下的真源件一致）。
   - acceptance：**两极化真跑** —— 正极＝9 件清根后 ⇒ `RETIREDPATH=PASS mode=tree … code=0`；反极＝**故意在任一 `.cs` 里塞回退役路径** ⇒ **`FAIL` 并点名 `file` ＋ `line`**；且 `files=` 读数必须**真的变大**（证明域变了，不是只改了打印）。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/pkg-src-retiredpath-check.sh --tree 2>&1 | grep -q 'RETIREDPATH=PASS mode=tree' && bash build/MilBridge/tools/pkg-src-retiredpath-check.sh --tree 2>&1 | grep -o 'files=[0-9]*'`
4. **归属与代价**：改仓件＝是（该牙 ＋ 可能要动 `retired-path-provenance.tsv`）。route 件＝否。触 `fp_inputs()`＝**是**（两件都在覆盖面内 ⇒ 必移；件数不变）。**重活＝否**（秒级）。
5. **依赖**：**依赖 B-3 先落**（见 B-3-⑤）。
6. **分波建议**：**W2**。

### B-5 · 仪器注释陈旧（`provider` 两值重复）

1. **现状现取读数**：`~/w21-verify/w27-freeze.py` ＝ `7e3d0fecefa9f20c`；现取该段原文（**逐字，含排版**）：
   ```
   # （照 `#79` 先例：那两格取**哨兵**的现取值。本代另有"重建驱动"事实：`#79` 块声明 `759ac1686e5ef87d`，
   #  `Provider` 产物先后被重建为 `8cb1b50619f4c133`（02:23:33）与 `8cb1b50619f4c133` ⇒ 三个时刻都写进 `P0-w80-report.md` §六）
   ```
   ⇒ **`8cb1b50619f4c133` 连写两次**（§B-1 的现取：`provider` 现取已到**第 4 个值** `24e4e0a731dbed40`）⇒ 注释与事实不符，**现取仍成立**。
2. **入口（原文照抄）**：`grep -n '被重建为' ~/w21-verify/w27-freeze.py`（该件**仓外**、队长写域）。
3. **判据草案**：
   - objective：把该注释改成与事实一致（第二个值应为第三时刻的真值，或注明「第二次同值」）。
   - acceptance：注释里出现的每个 `sha16` 都能在 `P0-w80-report.md §6/§10` 里**逐字找到**，且**同一值不重复出现两次**（除非显式注明）。
   - verify：`grep -c '8cb1b50619f4c133（02:23:33）与 `8cb1b50619f4c133`' /home/links-dev/w21-verify/w27-freeze.py` ⇒ 期望 **0**。
4. **归属与代价**：改仓件＝**否**（`~/w21-verify/w27-freeze.py` 在**仓外**）。`DEFREG`＝否。触 `fp_inputs()`＝**否**。**重活＝否**。
5. **依赖**：无（可与任一条并行，因为不碰仓件）。
6. **分波建议**：**W1**（作为「仓外件顺手修」附项；**不占仓内写者位**，但**仍须记入 W1 的交付**）。

### B-6 · `FILES` 累积语义

1. **现状现取读数**：`~/w79c/bin/w79-push.sh` ＝ **`5015004b0f0d917e`**／23,251 B／248 行／mtime `2026-09-28 12:54`。现取结构：`FILES="…"` 是**一个字面量累积清单**（`grep -c 'FILES+=' ` ＝ **0** ⇒ 没有动态追加，全是**手工累积的同一份字面量**），其行数已长到**单行超 2000 字符**（`:179` 一行内含数十件）。
   在册读数（`P0-w80-report §10-6` 逐字）：`6. **\`FILES\` 累积语义**：\`~/w79c/bin/w79-push.sh\` 的清单是**累积**的（本笔 **121 件** vs 本笔入笔 **61 件**）`。
   ⚠️ **NOINFO**：那对「`121` vs `61`」我**无法在本件现取独立复算** —— 复算它必须**执行** `w79-push.sh`（会真推送）⇒ 按纪律不跑。**我现取能证的是结构**（单一手工累积字面量、无追加语句），**不是**那两个数。
2. **入口（原文照抄）**：`PUSH_LIST="${W78_PUSH_LIST_OVERRIDE:-$FILES}"`（该件 `:180`，**仅本次有效**）＋ 其上的 `FILES="src/WpfGfx.Linux.Native/src/win32_oem.c …"` 字面量块。
3. **判据草案**：
   - objective：把「每波一份清单 ＋ 逐件归宿」替换掉「跨波累积字面量」。
   - acceptance：**两极化** —— ① 清单里每件的「入笔来源波」可机器读出（逐件一个字段），② **故意把一件不属于本波的件塞进清单** ⇒ 牙**必红并点名**（证明清单真的绑定到本波的脏件集合，而不是"能推就行"）。既有的 `PUSH_LIST_GAP` 判据（现取原文：`PUSH_LIST_GAP=FAIL dirty-covered-files-not-in-list:$missing ⇒ 停手，不推送`）**方向相反**，两条必须成对保留。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && grep -q 'PUSH_LIST_GAP=FAIL' build/MilBridge/tools/wave-push.sh && grep -c '^# wave=' build/MilBridge/tools/wave-push.sh`（搬入后路径）
4. **归属与代价**：改仓件＝是（**前提 ＝ B-2 的搬仓**）。route 件＝否。触 `fp_inputs()`＝**是**（新件入白名单 ⇒ `inputs_fp` 必移、覆盖面 **226 → 227** ⇒ `[42] --expect` **同趟**改）。**重活＝否**。
5. **依赖**：**与 B-2 同一件、同一波**（搬仓时一并改语义，避免「先搬后改」两趟动同一件）。
6. **分波建议**：**W3**（与 B-2 合波，**一次改完**）。

### B-7 · `arm-logs` 硬链接形态的两种处置

1. **现状现取读数**（读时 `2026-09-28T15:44:4x+08:00`）：**问题已消失，但白名单条目残留**。
   - `bash build/MilBridge/tools/repo-alias-check.sh --allow build/MilBridge/repo-alias-allow.tsv` ⇒ `ALIAS=PASS examined=18042 linked_gt1=0 aliased_out=0 aliased_allowed=0 aliased_unallowed=0 roots=1 maxdepth=16 wall_s=12.06 rc=0 reason=no-out-of-repo-alias`。
   - `~/wfp-runs/arms23/` 现取**只有 2 件**（`build-coverage.log`／`xvfb.log`），`find … -printf '%n'` 去重 ＝ **`1`**（**无硬链接孪生**）。
   - 白名单件 `build/MilBridge/repo-alias-allow.tsv` ＝ `5813863882022812`；其唯一数据行逐字：`/home/links-dev/w62a/negrepo	6417	W62A 负例仓（\`cp -al\` 造的影子树…` ⇒ **上限 6417 对着一个现取 0 件的树** ⇒ 「`allowed-tree-grown`」这条红**恒不触发**（上限远大于现值）。
2. **入口（原文照抄）**：`bash build/MilBridge/tools/repo-alias-check.sh --allow build/MilBridge/repo-alias-allow.tsv`；口径句逐字 ＝ `🔴 口径句（逐字，不得改写）：**"允许清单是声明式豁免，不是把牙关掉。"**`。
3. **判据草案**：
   - objective：把「两案择一」收敛为**一项决定**：白名单那行是**保留**（并写明它今天就该是 0 件）还是**删除**（删 ⇒ 牙回到「有孪生就红」的最严档）。
   - acceptance：**两极化真跑** —— ① 白名单存在且现读件数 == 0 ⇒ `ALIAS=PASS reason=no-out-of-repo-alias`；② **故意在白名单里把上限写成 `-1`／删掉那行** ⇒ `FAIL reason=out-of-repo-alias`（若确无孪生则 `PASS`；两种结果都**必须**由同一趟的两条腿分别展示，**不许**用"反正 0 件"跳过反极）。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/repo-alias-check.sh --allow build/MilBridge/repo-alias-allow.tsv 2>&1 | grep -q '^ALIAS=PASS' && echo B7_VERIFY_OK`
4. **归属与代价**：改仓件＝是（`build/MilBridge/repo-alias-allow.tsv`，**很可能只改注释**）。route 件＝否（`KRF`／`KRP` 不是 route 键 —— 且该件现取在覆盖面内）。触 `fp_inputs()`＝**是**（在覆盖面内 ⇒ 必移；件数不变）。**重活＝部分**（`repo-alias-check` 现测 `wall_s=12.06`、`examined=18042` ⇒ **<120 s**，但两极化要跑两趟 ⇒ 合计仍小；**不需槽**）。
5. **依赖**：无。可与 B-8 同件域并行（都是秒级牙）。
6. **分波建议**：**W2**。

### B-8 · `PTS-PAGES` 的「零证据力」射程句仍只在报告里、未入判据件自身

1. **现状现取读数**：
   - `build/MilBridge/tools/pts-pages-guard.sh` ＝ `bfa6414eb7104f85`；`grep -c '零证据力' <该件>` ＝ **0** ⇒ **现取仍不在判据件自身**（成立）。
   - 载体句（`build/MilBridge/P0-mvp-pts-report.md` ＝ `d79a0c009515b3c4`／190 行）逐字：`门禁步 \`PTS-PAGES\`（\`verify-all.sh:1173\`…）**只读 \`leg_*.env\` 的列，不读 \`entry=\`** ⇒ **它的绿对"前沿位移"零证据力**`。
   - ⚠️ **该句引的行号现取已变**：`grep -n 'run_step "PTS-PAGES"' verify-all.sh` 的命中行**不是** `:1173`（`HANDOFF` 第 8 条自己也写着「`verify-all.sh:1174`，**不是** `:1173`」）⇒ **行号必须现取**。
   - 件头 G10 描述现取原文（**旧前沿**）：`#   G10 至少一条 native \`PTS_GAP entry=CreateInstalledObjectsInfo\`           否 ⇒ FAIL` —— 而**现取前沿是 `LoCreateContext`**（`app_g1.log` `3×`）。
   - `pts-pages-guard.sh` 现取**在覆盖面内**（`infp-n.sh list` 命中 1）。
2. **入口（原文照抄）**：`bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence`；口径句原句见上。
3. **判据草案**：
   - objective：把「只读 `leg_*.env` 的列、不读 `entry=` ⇒ 绿对前沿位移零证据力」这句**搬进判据件自身**（本仓既有做法：口径搬进判据件），并**同趟**修正 G10 描述里的具名（`CreateInstalledObjectsInfo` → `LoCreateContext`）。
   - acceptance：① `grep -c '零证据力' <该件>` ≥ **1**；② 件头 G10 描述里出现的 `entry=` 名字**必须**与现取前沿**逐字相同**（不一致 ⇒ 红）；③ **两极化**：把前沿**人为改回旧名**（只改 `app_g1.log` 的副本）⇒ ②那条牙**必红并点名**。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && test "$(grep -c '零证据力' build/MilBridge/tools/pts-pages-guard.sh)" -ge 1 && echo B8_VERIFY_OK`
4. **归属与代价**：改仓件＝是（`build/MilBridge/tools/pts-pages-guard.sh`）。route 件＝否。触 `fp_inputs()`＝**是**（在覆盖面内 ⇒ 必移；件数不变 ⇒ `--expect 226` 不动）。**重活＝否**（纯读、秒级）。
5. **依赖**：与 **A-1** 同件 ⇒ **A-1 落地时同趟改，或 A-1 之前先落本条**（两条**不许**在两个波里各改一次这件 —— 会返工）。建议**本条先落**（它是口径/描述），A-1 后续只在同件上做反转。
6. **分波建议**：**W2**（先落），A-1 的 W8 **复用同一件**。

### B-9 · `session_inner.sh:18` 的显示号缺占用断言

1. **现状现取读数**：`build/MilBridge/tests/PtsPagesProbe/session_inner.sh` ＝ `f687ad65fd05f6e2`；现取该行原文：`D="${W67_DISPLAY:-:237}"` ⇒ **默认值没有「该号是否已被占用」的断言**（成立）。`evidence/device.txt` 现取 ＝ `X_UP=yes display=:237`（**现读现场确实用了 `:237`**）。该件现取**在覆盖面内**（命中 1）。
2. **入口（原文照抄）**：`D="${W67_DISPLAY:-:237}"`（该件 `:18`，**仅本次有效**）；同件 `:19` `export PATH="$HOME/.dotnet:$PATH"; export DOTNET_gcServer=0`。
3. **判据草案**：
   - objective：给默认显示号加**占用探测**（或改成「现取空闲号」），缺判 ⇒ 拒跑。
   - acceptance：**两极化真跑** —— ① 正极＝号空闲 ⇒ 正常起（打出自证行 `DISPLAY_LEASE=…`）；② 反极＝**先占住 `:237`**（起一个同号 `Xvfb`，按 PID 收）⇒ **`rc≠0` ＋ 具名拒跑**（**不许**静默复用别人的号）。本仓既有同族实现可直接抄：`D-G139` 的「按 PID 收」＋ `display-lease.sh` 的租借语义（但那两件**不在覆盖面**，见 §5-9/§5-10）。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && grep -qE 'X11-unix|xdpyinfo|display-lease|占用' build/MilBridge/tests/PtsPagesProbe/session_inner.sh && echo B9_VERIFY_OK`
4. **归属与代价**：改仓件＝是。route 件＝否。触 `fp_inputs()`＝**是**（在覆盖面内 ⇒ 必移；件数不变）。**重活＝是**（反极腿要起第二个 `Xvfb` ⇒ **需槽 ＋ 私有 `:2xx` 显示位**；`D-G105` 口径：只用 `:2xx` 空闲号、几何 `1280x1024x24`）。
5. **依赖**：与 **A-1／A-2／A-3** 争显示位与槽 ⇒ **不得与它们的腿批同波**。
6. **分波建议**：**W2**（但**其反极腿单独走槽、串行**）。

### B-10 · `inputs_fp` 相对 `#80` 冻结值的漂移 ＝ 0

1. **现状现取读数**（读时 `2026-09-28T15:43:1x+08:00`）：`bash ~/w153a/bin/infp.sh fp` ＝ `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`；`bash ~/w-p0mig/bin/infp-n.sh fp` **同值**（两个独立复算器互证）；`bash ~/w1ke152/bin/infp.sh list | wc -l` 与 `infp-n.sh list | wc -l` **均为 226** ⇒ 与 `#80` 冻结值**逐位相同**、覆盖面 **226**（＝ `[42] --expect 226`）。
2. **入口（原文照抄）**：`bash ~/w153a/bin/infp.sh fp`（对照源＝块内 `inputs_fp` 行，逐字 `**\`inputs_fp\` = \`abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f\`**`）。
3. **判据草案**：
   - objective：把「本批零位移」当**每波入口自检**（不是一波的待办）。
   - acceptance：任一写波**开跑前**与**收口后**各取一次 `inputs_fp`＋覆盖面行数；**未声明位移而值变了 ⇒ 必须停手**；声明过位移（新增覆盖面件）⇒ `[42] --expect` **同趟**改。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && a=$(bash ~/w153a/bin/infp.sh fp); b=$(bash ~/w153a/bin/infp.sh fp); [ "$a" = "$b" ] && grep -q "$a" samples/WpfTextDemo/ACCEPTANCE-BASELINE.md && echo B10_INFP_STABLE`
4. **归属与代价**：改仓件＝**否**（纯读数）。**重活＝否**（秒级）。
5. **依赖**：无；**是所有波的前置自检**。
6. **分波建议**：**不占波位** —— 降为 **W1–W8 每波的入口/出口自检**（这是对在册排期的一处**结构性更正**，见 §5-7）。

### B-11 · `§1–§6` 的机器值是**手抄**的 ⇒ 每代必陈旧

1. **现状现取读数**（读时 `2026-09-28T15:43:5x+08:00`）：`build/MilBridge/HANDOFF-NEXT.md` ＝ `61c34bb9d4168f65`／289 行。**现取仍陈旧的手抄机器值（逐条点名，含机器证）**：

   | 处（内容锚） | 在册原文（逐字） | 现取 | 机器证 |
   |---|---|---|---|
   | `§7 七条命令·第 4 条` | `bash ~/w153a/bin/infp.sh fp        # 期望 bb54413c…（#76 冻结值；每波现取）` | 现取 **`abc76bd55f513b8d…`** | 现跑该命令 |
   | 同上 | `bash ~/w153a/bin/infp.sh list \| wc -l   # 期望 205` | 现取 **`226`** | 现跑该命令 |
   | `§7·第 5 条` | `ls -l ~/w21-verify/w6*-POST.done ~/w21-verify/w6*-record.txt 2>/dev/null` | 现取 `w*-POST.done` **25** 件（`w56`…`w80`）、`*record*` 只到 **`w77`** | `ls` 现取 |
   | `§2 在飞` | `**\`#77\`**（仪器波；五件 ＝ …）` | 现取 `#80` 已全链闭环、无链在跑（同件 dated 行已自述） | `sed -n '9p' docs/CURRENT-STATE.md` |
   | `§1 九位` | `#77` 九值 | `#80` 九值（同件 dated 行已给） | `BASELINE tier=` 机读行 |
   | `§4 登记册` | `DEFREG=PASS declared=155 route_ids=155` | 现取 **`215/215`** | 现跑 `defect-registry-check.sh` |

2. **入口（原文照抄）**：上表逐条即入口原文（一律内容锚，**不引行号** —— 该件自己写着 `⚠️ **不引行号**（纪律 31）`）。
3. **判据草案**：
   - objective：把该节机器值改为**由脚本现取生成**（或至少加一颗牙：该节现值格 vs 现场不一致 ⇒ 红）。
   - acceptance：**两极化** —— ① 现取生成 ⇒ 与现场逐字相同（`rc=0`）；② **人为把某一格改错一个字符** ⇒ 牙**必红并点名该格**（不许用「解析不了就跳过」洗绿）。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/handoff-machine-values-check.sh 2>&1 | grep -q '^HANDOFF_MV=PASS'`（新牙落地后的形态）
4. **归属与代价**：改仓件＝是（`build/MilBridge/HANDOFF-NEXT.md` ＋ **新牙**）。route 件＝**否**（现取 `grep -n 'ROUTES' defect-registry-check.sh` 只在该件的**打印行**里命中一次，`ROUTES.md`／`HANDOFF-NEXT.md` **都不在** `ALLKEYS`）。触 `fp_inputs()`＝**是**（新牙入白名单 ⇒ `inputs_fp` 必移、覆盖面 **226 → 227** ⇒ `[42] --expect` 同趟改）。若牙接进门禁 ⇒ **步数 55 → 56**（四处声明 `DECL`／`STEP-NAMES`／口径句／预登记 **同趟**改）。**重活＝否**。
5. **依赖**：**与 B-18／B-15 争同一条「加牙＋加步」的窗口**（步数与 `DECL` 属同一处声明）⇒ 三条**必须合波**，不许各加一步。
6. **分波建议**：**W4**（与 B-15／B-18 合波）。

### B-12 · `D-G179` 候选：声明表 `req` 列在自动路径上恒真

1. **现状现取读数**（读时 `2026-09-28T15:45:2x+08:00`）：**条目已被在飞车道落册（见 §0-4）**。
   - `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 现取 `fa1715f3edefb7eb`（`git` 基线侧为 `b003e59` 索引对象）；`grep -c 'D-G179'` ＝ **7**；新增段锚句逐字 ＝ `## P1-W1 登记批（2026-09-28；**一条入册**：把「提及即声明、册内无条目」的候选补成**正式条目**`。
   - `build/MilBridge/tools/report-id-domain-check.sh`（`e1ed9a71200a20a9`）现跑末三行照抄：`BOOK_ENTRY_UNREQUIRED_MISSING n=15 ids=D-E1 D-F1b-ABSENT D-G D-G1 D-G156 D-G159 D-G161 D-G165 D-G33 D-G5 D-G6 D-O1 D-R2 D-R4 D-T1`（**`n` 由 `16` 降到 `15`、名单里 `D-G179` 已消失**）｜`BOOK_ENTRY_BINDING required=5 present=5 missing=0`｜`REPORTID=PASS files=190 ids=1957 declared=215`。
   - `declared.tsv` 现取工作树版 `e242e3fbc5f76d77`，`DECL-GEN = (--emit) 2026-09-28 15:44:51 +0800`。
   - **`req` 恒真的机制（我独立复核，逐字引实现）**：`defect-registry-check.sh` 现取 `c2d0773e5561a9d1`，`emit_decl()` 里 `for k in KD CS HO AB; do [ -n "${ID2LINE["$k:$id"]:-}" ] && req="$req${req:+,}$k"; done` ⇒ `req` ＝ **出现集**；`run_check()` 的规则③又拿**同一张表**的 `req` 去核「每个 route 件各至少出现一次」⇒ **同一份数据既生成又据以判** ⇒ 自动路径上恒真（**现取成立**）。
2. **入口（原文照抄）**：`bash build/MilBridge/tools/defect-registry-check.sh --emit > build/MilBridge/tools/defect-registry-declared.tsv`（纪律 10 逐字：`\`--emit\` 是把声明表打到 stdout`）。
3. **判据草案**：
   - objective：`req` 语义改成「**要求集**」（与 `present` 的出现集分离），或校验侧改判「**出现集之外的空集**」。
   - acceptance：**三条并列** —— ① 同趟 `--emit` 后 `DEFREG=PASS declared=215 route_ids=215` 三态不变；② **手工**把 `req` 加宽到命中 `0` 的 route 键 ⇒ **必须 `FAIL` 并点名**该号与该键；③ `req` **收窄**成子集的情形**不许**静默 `PASS`（现取在册：收窄 ⇒ `PASS`＝**欠报不可见**，这是本条要修的那一半）。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/defect-registry-check.sh 2>&1 | grep -q '^DEFREG=PASS' && grep -q '^## .*D-G179' samples/WpfFeatureProbe/KNOWN-DEFECTS.md && echo B12_PART1_OK`
4. **归属与代价**：改仓件＝是（**修法面**＝`build/MilBridge/tools/defect-registry-check.sh`；**登记面已完成**）。route 件＝**是**（`KD` 已改、`declared.tsv` 已同趟重发 ⇒ **在飞车道已办**）。触 `fp_inputs()`＝**是**（该工具在覆盖面内 ⇒ 必移；件数不变）。**重活＝否**（秒级 ＋ `--selftest`）。
5. **依赖**：**先决 ＝ §0-4 那条在飞车道落仓并推送**（它现占 `KD` ＋ `declared.tsv` 两个写者位）。**不得与它同波**。
6. **分波建议**：**W5**（条目已在飞 ⇒ 本波**只做修法** ＋ 修订登记文本）。

### B-13 · 哨兵同名字段 `FP` ＝ `BRIDGE_SRC_FP`，**不是** `inputs_fp`

1. **现状现取读数**（读时 `2026-09-28T15:44:0x+08:00`）：哨兵两枚各 279 B／`sha16=6cb3f97388c3c4dc`／`cmp` **IDENTICAL**；`grep '^FP=' /tmp/bridge-frozen.flag` ⇒ `FP=d697b1e10ff48881`；`bash build/bridge-src-fp.sh` ⇒ `BRIDGE_SRC_FP=d697b1e10ff48881 BRIDGE_SRC_N=78`；而 `bash ~/w153a/bin/infp.sh fp` ⇒ `abc76bd55f513b8d…`。
   ⇒ **拿 `infp` 比哨兵 `FP` 即假红**（`d697b1e1…` vs `abc76bd55…`）—— **现取成立**。哨兵**13 行**（我现取 `cat` 计数）：`SHA/FP/PC/PF/WB/WIN32SHIM/HBTL/WIC/PROVIDER/DWF/WAVE/BASELINE/BASELINE_SHA16`。
2. **入口（原文照抄）**：`/tmp/bridge-frozen.flag:2` 的 `FP=d697b1e10ff48881`；定义链 `build/close-wave.sh`（`f9a2ee3ee35baff8`）里的 `FP_NOW2="$(bash build/bridge-src-fp.sh …)"` → `printf 'FP=%s\n' "$FP_NOW2"`。
3. **判据草案**：
   - objective：把「哨兵 `FP` ≠ `inputs_fp`」这条口径**写成机读的对照声明**（或让对拍器**先分口径**再比）。
   - acceptance：对拍器读到哨兵 `FP` 与 `inputs_fp` **同时**存在时，**必须**打印 `CALIBER_SPLIT fp=BRIDGE_SRC_FP infp=inputs_fp` ∧ **不改 `rc`**；若值**恰相等**则打印 `CALIBER_COINCIDENCE`（可见，不判红）。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && grep -q 'FP=' /tmp/bridge-frozen.flag && grep -q 'BRIDGE_SRC_FP=' <(bash build/bridge-src-fp.sh) && echo B13_CALIBER_SPLIT_OK`
4. **归属与代价**：改仓件＝是（判据/文档面；若加进 `ROWS-IDENTITY` 之类的既有步 ⇒ **不动步数**）。route 件＝否。触 `fp_inputs()`＝**是**（若改到覆盖面内的件 ⇒ 必移；件数不变）。**重活＝否**。
5. **依赖**：与 **B-14 / C-1** 同源（都在说哨兵），但**本条是纯口径**、那两条是**写者搬仓** ⇒ 建议**同波但不同件**。
6. **分波建议**：**W3**（与 B-14／C-1 同波）。

### B-14 · 哨兵是**仓外仪器**写的（仓内没有写者、也没有读者）

1. **现状现取读数**（读时 `2026-09-28T15:44:3x+08:00`）：`grep -rln 'BASELINE_SHA16' --include='*.sh' --include='*.py' .` ⇒ **仓内 0 命中**（**现取复算，成立**）。哨兵写者链在仓外：`~/w79c/bin/w79-push.sh`（现取 **`5015004b0f0d917e`**，**注意在册值 `fb46d69e6a5cd78a` 已过期**，见 §5-2）／`~/w79c/bin/w79-chain.sh`。两枚哨兵 mtime `2026-09-28 13:48`。
2. **入口（原文照抄）**：`/tmp/bridge-frozen.flag` 与 `~/wfp-runs/bridge-frozen.flag`；写者段＝`~/w79c/bin/w79-push.sh` 尾部 `install -m 644` 两地。
3. **判据草案**：
   - objective：把写哨兵的那一小段**搬进仓内**（否则清一次车道目录 ⇒ 哨兵成孤儿）。
   - acceptance：**两极化** —— ① 仓内写者跑出的两枚哨兵 `cmp IDENTICAL` ∧ 13 键齐全 ∧ 每键值 == 该键权威路径的现取值（**逐键给权威路径**）；② **故意把某键写空** ⇒ **必红**（依据 §绑定规则 A 表 #2 逐字：`标记里任何字段都不许为空；取不到 ⇒ \`none(<reason>)\``）。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/bridge-flag-write.sh --dry-run 2>&1 | grep -c '=' | grep -q '^13$' && echo B14_VERIFY_OK`
4. **归属与代价**：改仓件＝是（`build/close-wave.sh` 或新件 ＋ 新牙）。route 件＝否。触 `fp_inputs()`＝**是**（新件入白名单 ⇒ `inputs_fp` 必移、覆盖面 **226 → 227** ⇒ `[42] --expect` 同趟改）。**重活＝否**。
5. **依赖**：与 **C-1** 是**同一缺口的两半**（本条＝「谁写」，`C-1`＝「什么格式」）⇒ **必须同波、同趟**；与 **B-2／B-6** 也是同一段仓外代码 ⇒ **强烈建议三条合波**（一次搬完，免得同一段代码搬两次）。
6. **分波建议**：**W3**。

### B-15 · 推送标记（`.done`）适用面与命名不统一，且仓内没有强制读者

1. **现状现取读数**（读时 `2026-09-28T15:44:5x+08:00`）：
   - `grep -rIl '\.done' build/MilBridge/tools verify-all.sh build/close-wave.sh` ⇒ **0 命中** ⇒ **仓内零读者**（现取复算，成立）。
   - 全 `~` `maxdepth 3` 的 `*.done` ＝ **47** 枚（**在册写 41 ⇒ 已陈旧**，见 §5-3）。
   - `~/w14a/` 现取 **9 枚** `W80_*.done`：`W80_DOCSCLOSE`／`W80_T58`／`W80_T60`／`W80_T62`／`W80_T66`／`W80_T68`／`W80_T70`／`W80_T71FIX`／`W80_T72CLOSE`（**在册写"只有四枚" ⇒ 已陈旧**）。
   - `~/w21-verify/w*-POST.done` ＝ **25** 枚（`w56`…`w80`）；`w80-POST.done` 为 `0 B`／mtime `11:51:17`；`~/w21-verify/*record*` 只到 **`w77`**（**无 `w80-record.txt`**）。
2. **入口（原文照抄）**：`ls -l ~/w21-verify/w*-POST.done`；`~/w14a/W80_*.done`（三字段 `push_rc=`／`stop_line=`／`remote=`）。
3. **判据草案**：
   - objective：两案择一 —— （甲）规定「所有推送必须有标记 ＋ 至少一名**仓内**读者」；（乙）把标记搬进仓内（那时「字段不许为空」才有牙）。
   - acceptance：选（乙）时 —— ① 仓内出现写标记的件且在 `fp_inputs()` 内；② **两极化**：字段取不到 ⇒ 写 `none(<reason>)`（**不许空**），且把字段人为清空 ⇒ 牙**必红**。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && grep -rIl '\.done' build/MilBridge/tools verify-all.sh build/close-wave.sh | wc -l` ⇒ 期望 ≥ 1。
4. **归属与代价**：改仓件＝是（新件 ＋ 可能加步）。route 件＝否。触 `fp_inputs()`＝**是**。**重活＝否**。⚠️ **NOINFO**：在册那句「`t64` 两次推送零标记（\`find ~ -maxdepth 3 -name '*T64*'\` ⇒ 命中 0）」**我无法现取复算**（它是对**过去某时刻**的存在性断言，`find` 现在给 0 不能区分"从未有"与"已被删"）⇒ 记 `NOINFO(reason=对过去时刻的存在性断言不可现取；现取 find 命中 0 不构成证据)`。
5. **依赖**：与 **B-11／B-18** 争「加步」窗口 ⇒ **必须合波**。
6. **分波建议**：**W4**。

### B-16 · `docs/ROUTES.md` 的 `TASK-0303` 行引用形态需写明「前缀口径」（**不是**「陈旧」）

1. **现状现取读数**（读时 `2026-09-28T15:44:2x+08:00`）：
   - 该行现取原文（内容锚：行首即 `TASK-0303 [Next] ✅` 的那一行）逐字片段：`报告 \`build/MilBridge/W78A-report.md\` \`0dbc62b1d1cf86ee\`，568 行`。
   - 现取整件 `build/MilBridge/W78A-report.md` ＝ `720e12fceb761941`／**582 行**；**我自算 `head -568` ⇒ `0dbc62b1d1cf86ee`（逐位相同）** ⇒ **引用成立**（＝「只增不改」下的**前缀快照**），**不是 stale**。
   - ⚠️ **行号已失效**：在册把该行写作 `docs/ROUTES.md:228`，而 **`:228` 现取是 `TASK-0204` 行**；`TASK-0303` 行现取在 **`:240`**（仅本次有效）。该条**自己**主张「行号仅本次有效」，此处正是又一实例。
2. **入口（原文照抄）**：内容锚 ＝ `行首即 \`TASK-0303 [Next] ✅\` 的那一行`；前缀证据命令 ＝ `head -568 build/MilBridge/W78A-report.md | sha256sum | cut -c1-16`。
3. **判据草案**：
   - objective：把该行的引用**写明口径**（如「`568` 行前缀快照」），或直接改成**内容锚引用**。
   - acceptance：该行文本含口径词（`前缀`／`前缀快照` 之一），且同行的引用值**不等于**整件 sha16 时**必须**带该口径词；把口径词删掉 ⇒ 牙**必红**（若做成牙）。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && test "$(head -568 build/MilBridge/W78A-report.md | sha256sum | cut -c1-16)" = "0dbc62b1d1cf86ee" && echo B16_PREFIX_OK`
4. **归属与代价**：改仓件＝是（`docs/ROUTES.md`）。route 件＝**否**（现取机制证：`defect-registry-check.sh` 的 `ALLKEYS='KD CS HO AB KRJ KRF KRP'` **不含** `ROUTES.md`）；但若该行的文本**引入新编号**，规则④不查 ROUTES ⇒ 亦不红。触 `fp_inputs()`＝**否**（`docs/ROUTES.md` 现取命中 **0**）。**重活＝否**。
5. **依赖**：无。与 B-17 同件 ⇒ **必须同波**。
6. **分波建议**：**W1**。

### B-17 · `docs/ROUTES.md` 的 `§13` 计数行与**它自己那棵树**不符

1. **现状现取读数**（读时 `2026-09-28T15:43:5x+08:00`；**用我自写的抽取器现算**）：
   - 计数行现取原文逐字：`现取计数（\`#80\`，\`t14\` 现算）：TASK 行 **77** ＝ ✅**75** ／ 🟡**0** ／ 🔴**2** ／ ⚪**0**`（该行**现取在 `:166`**，仅本次有效）。
   - **我独立抽取**（域＝`## §13` 头到 `## §14` 头；行首剥掉树绘制前缀后仍以 `TASK-\d{4}` 起头＝「tree-form」）：**tree-form 79 行** ＝ 带 `[kind]` **77** ＋ 不带 `[kind]` **2**（`TASK-0202` 现取 `:221`／`TASK-0204` 现取 `:228`，两者**同为 tree-form**）；**tree-form 唯一 id 数 ＝ 79**。
   - 带 `[kind]` 的 77 行按「**取标签后那一个记号**」＝ **✅74／🟡1／🔴2／⚪0**；按「整行任一命中」＝ **✅75／🟡2／🔴5／⚪0**。⇒ **计数行的 `✅75／🟡0／🔴2／⚪0` 在两种口径下都不成立**（`🟡0` 应为 `1`）。
   - **但 dated 更正已落**：紧随该行之后的 `⏪` 行逐字给出 `口径①「取标签 \`TASK-NNNN [kind]\` 之后的那一个记号」＝ ✅\`74\`／🟡\`1\`／🔴\`2\`／⚪\`0\`` ⇒ **「下一波做 dated 更正（🟡0→1、✅75→74）」这一半已完成**（`t66`，读时 `2026-09-28T13:17+08:00`）。
2. **入口（原文照抄）**：内容锚 `现取计数（\`#80\`，\`t14\` 现算）` 那一行 ＋ 紧随其后的 `⏪` 更正行。
3. **判据草案**：
   - objective：**只做剩下的那一半** —— 在册写明「TASK 行」的**两种口径**（全行 `79`／带标记 `77`）并把「状态记号取**标签后**那一个」写进抽取口径。
   - acceptance：文本同时出现 `79` 与 `77` 两个口径并**各自具名**；抽取口径句含「取标签后」；**机器证**＝抽取器在两种口径下分别复算出 `79／77`。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/routes-tree-count-check.sh 2>&1 | grep -q '^ROUTESCOUNT=PASS'`（新牙形态；未落地前用 §0-1 的自写抽取器等价复算）
4. **归属与代价**：改仓件＝是（`docs/ROUTES.md`；若加牙 ⇒ 新件 ＋ 覆盖面 +1）。route 件＝否（同 B-16-④）。触 `fp_inputs()`＝**仅在新牙时**为是。**重活＝否**。
5. **依赖**：与 B-16 同件 ⇒ **必须同波**。
6. **分波建议**：**W1**。

### B-18 · 门禁是「构建驱动」⇒ 冻后跑门禁必使 `PROVIDER` 位位移

1. **现状现取读数**（读时 `2026-09-28T15:45:0x+08:00`）：
   - 权威路径 `build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll` ＝ **`24e4e0a731dbed40`**／104,448 B／mtime `2026-09-28 13:11:49`；
   - 副本 `build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll` ＝ `7e8a217b4165a6b9`／104,448 B／mtime `2026-09-28 10:24:21`；
   - `#80` 块九位行 `provider` ＝ `7e8a217b4165a6b9`；`BASELINE tier=` 六行 `config=…provider:7e8a217b4165a6b9…`；哨兵 `PROVIDER=` ＝ **`24e4e0a731dbed40`**。
   - 现跑 `python3 build/MilBridge/tools/wave-freeze-consistency-check.py`（`e4393879eaca84f0`）尾部逐行照抄：
     ```
     WFREEZE_ROOTDEFAULT=PASS exprs=168 files=136 ok=35 bad=0 root_n=35 benign=133 consume=5 consume_ok=5 t17=22 t17_lost=0 t17_val_bad=0 cwd_dep=0 anchor=content
     WFREEZE_DECL=PASS gen=#80 allow_changed_decl=dwf,pc,pf,provider,win32shim,windowsbase …
     WFREEZE_NINEAUTH_HIT kind=diverged canon=build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll=24e4e0a731dbed40 copy=build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll=7e8a217b4165a6b9（**同名产物的两条「权威」路径分叉**）
     WFREEZE_NINEAUTH=FAIL pairs=1 ok=0 bad=1
     WFREEZE_BLOCKVALUES_HIT key=provider probs=nine-vs-live,tier-vs-live block9=7e8a217b4165a6b9 tier=7e8a217b4165a6b9 live=24e4e0a731dbed40（块里的值与现取不符／块内两个授权来源互相矛盾）
     WFREEZE_BLOCKVALUES=FAIL gen=#80 keys=9 declared_shifts=0 bad=1 noinfo=0 cfg=Release
     WFREEZE_CONSISTENCY=FAIL rootdefault=PASS decl=PASS nineauth=FAIL blockvalues=FAIL（四档互不代偿）
     ```
     ⇒ **`WFREEZE_CONSISTENCY=FAIL` 是现取的、可重跑的红**；根因是 `provider` **构建驱动位**（在册最小复现逐字：单工程一次 `dotnet build` `4.35 s` 即换值）。
2. **入口（原文照抄）**：`python3 build/MilBridge/tools/wave-freeze-consistency-check.py`；最小复现（在册逐字）：`dotnet build build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj -c Release -m:1 --nologo -v q`。
3. **判据草案**：
   - objective：**定则** —— `provider` 是否允许「位位移」免钉／门禁是否必须**冻前**跑／或给 `provider` 加一颗「**同输入复现性**」牙。
   - acceptance：**两条并列可判真假** —— ① **同输入复现性牙**：对同一工程连跑两次 `dotnet build`，两次产物 sha16 若不同 ⇒ **必须**打印 `PROVIDER_REPRODUCIBLE=no` 并**点名两个值**（可见、按本仓惯例可**不判红**，但**不许静默**）；② **冻后跑门禁**这一动作**必须**留下「谁的副作用让哪一位位移」的机器行（不许靠人回忆）。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && python3 build/MilBridge/tools/wave-freeze-consistency-check.py 2>&1 | grep -q '^WFREEZE_ROOTDEFAULT=PASS' && echo B18_BASELINE_OK`
     （⚠️ 这条**只判** §B-18 的**基线面**仍被牙看着；`nineauth=FAIL`／`blockvalues=FAIL` 是**在册已知**设计态，**不许**把它们当本条的红。）
4. **归属与代价**：改仓件＝是（`build/close-wave.sh`／`wave-freeze-consistency-check.py`／`verify-all.sh`／`docs/WAVE*-PREREGISTRATION.md`）。route 件＝否。触 `fp_inputs()`＝**是**（前三件都在覆盖面内 —— `close-wave.sh` 与 `wave-freeze-consistency-check.py` 现取命中 1／1；**`verify-all.sh` 现取命中 0**，见 §5-9）。**重活＝是**（两次 `dotnet build` 各 ≈ 4.35 s 属秒级，但**「整波重跑」属重活**；若牙要真判「整波复现性」⇒ 必须走槽 ＋ 后台作业）。
5. **依赖**：与 **B-1**（`D-G176` 同一现象的另一面）**同根** ⇒ 建议**同波**，避免两处各自描述同一现象。
6. **分波建议**：**W4**（与 B-11／B-15 合波；加步窗口共享）。

---

## §3 C 组 · `docs/ROUTES.md §15af` 的「第 `19` 条」等价物

### C-1 · 哨兵的**键序／字节格式无规范** ⇒ 同一「哨兵内容」可用不同字节表达 ⇒ `sha16` 不可对拍

1. **现状现取读数**（读时 `2026-09-28T15:44:3x+08:00`）：
   - 在册落点（`docs/ROUTES.md §15af` 内，两行；作废声明后的**唯一在册落点**）逐字片段：`**哨兵的键序／字节格式无规范 ⇒ 同一"哨兵内容"可用不同字节表达 ⇒ \`sha16\` 不可对拍**`；同段逐字给出「**下一波两选**：(甲) 把哨兵**写者与格式**搬进仓内（并给 `--selftest`）；(乙) **至少声明键序与字节规范**（键序＝十键固定序、行尾单个 `\n`、无空行）并在件内写死。」
   - 同段的作废句逐字：`上句尾那句「已同时登记到 \`HANDOFF-NEXT.md\`…第 \`19\` 条」**作废** —— \`build/MilBridge/HANDOFF-NEXT.md\` **在本件契约的 \`outOfScope\` 里**…⇒ 那条追加**已整件回退**（该件现取 sha16 ＝ \`61c34bb9d4168f65\`，＝ 追加前原值）` ⇒ **我现取复算：`HANDOFF-NEXT.md` ＝ `61c34bb9d4168f65`（逐位相同）**，即**回退确实生效、该缺口确实只在本段**。
   - 现取哨兵实际形态：**13 行**（不是 10 键）、行尾单个 `\n`、无空行、键序＝`SHA/FP/PC/PF/WB/WIN32SHIM/HBTL/WIC/PROVIDER/DWF/WAVE/BASELINE/BASELINE_SHA16`。`sha16=6cb3f97388c3c4dc`。而在这段历史里：冻结 `PROVIDER` 版 ⇒ `f2ab94d32b8e1e40`、现取 `PROVIDER` 版 ⇒ `6cb3f97388c3c4dc`、`t15` 记的 `c6ee190ed289455c` ⇒ **复现不出**（在册：`t68` 试了 **16 个变体全不中**）。
   - ⚠️ **在册句说「键序＝十键固定序」，而现取哨兵是 13 行** ⇒ **该处方自身与现场不符**（十键 vs 十三行）。这是一个**现取可证的内部矛盾**。
2. **入口（原文照抄）**：`cat /tmp/bridge-frozen.flag`；作废声明内容锚 ＝ `上句尾那句「已同时登记到 \`HANDOFF-NEXT.md\`…第 \`19\` 条」**作废**`。
3. **判据草案**：
   - objective：两选之一落地 —— （甲）把哨兵**写者与格式搬进仓内** ＋ `--selftest`；（乙）**至少声明键序与字节规范**并在件内写死。
   - acceptance：**两极化** —— ① 正极＝按规范重建的哨兵与现场 `sha16` **逐位相同**（键序固定、行尾单个 `\n`、无空行、**键数＝13**并**逐键给权威路径**）；② 反极＝键序打乱 **或** 加一个空行 **或** 尾加 `\n` ⇒ 重建器**必须**给出**不同** `sha16` 并被牙**判为格式违规**（**不许**"反正哈希比的是内容"洗过去）。
   - verify：`cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/bridge-flag-format-check.sh 2>&1 | grep -q '^FLAGFORMAT=PASS keys=13'`（新牙形态）
4. **归属与代价**：改仓件＝是（与 **B-14** 同件域）。route 件＝否。触 `fp_inputs()`＝**是**（新件入白名单 ⇒ 覆盖面 **226 → 227** ⇒ `[42] --expect` 同趟改）。**重活＝否**。
5. **依赖**：**与 B-14 是同一缺口的两半，必须同波、同趟**（B-14＝写者搬仓；C-1＝格式规范）。
6. **分波建议**：**W3**（与 B-2／B-6／B-13／B-14 合波）。

---

## §4 分波表（**串行**；本仓硬约束：同一时刻只有一个改仓件的写者）

> **W0 前置（必做，不占波位）**：① 等 **§0-4 那条在飞车道**（`D-G179` 条目化：`KD` ＋ `declared.tsv`）**落仓并推送**，`porcelain` 回到该车道**自己公布的**值；② 每波开跑前现取 `df -Pk` 第 4 列（≥ 5 GB）、`free -m` 的 `avail`／`swapfree`、`flock -n ~/heavy.lock`；③ 每波**入口/出口各取一次** `inputs_fp`＋覆盖面件数（**B-10 的自检**）。
> **每波的独立复核节点写法**＝「复核谁 ＋ 判什么」；**复核者不得是写者本人**（本仓口径：不许自审自）。

| 波 | 写者域（件清单） | 条目 | 依赖 | 独立复核节点 | 重活 |
|---|---|---|---|---|---|
| **W1** | `docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv`（同趟 `--emit`）｜**仓外附项**：`~/w21-verify/w27-freeze.py` | B-1、B-5、B-11（**文档面**）、B-13（**文本面**）、B-16、B-17 | W0 | 复核**写者域全部四件的现取值**：从零复算 `§13` 树内两种口径（`79／77`）＋ `--emit` 输出与现场逐件比 ＋ `DECLDRIFT=0` ＋ `BOOK_ENTRY_*` 三行；**判**「该节的每个机器值都能被现取复现」 | 否 |
| **W2** | 9 件 `.cs`（B-3 表）／`build/MilBridge/tools/pkg-src-retiredpath-check.sh`／`build/MilBridge/tools/retired-path-provenance.tsv`／`build/MilBridge/tools/pts-pages-guard.sh`／`build/MilBridge/tests/PtsPagesProbe/session_inner.sh`／`build/MilBridge/repo-alias-allow.tsv` | B-3、B-4、B-7、B-8、B-9 | W1；**波内顺序：先 `.cs`（B-3）后牙（B-4）** | 复核**两极化**：① 任一 `.cs` 塞回退役路径 ⇒ `RETIREDPATH` **必红点名 `file`＋`line`**；② 白名单上限人为改小 ⇒ `REPO_ALIAS` **必红**；③ `:237` 被占用 ⇒ `session_inner` **必拒跑**；④ `pts-pages-guard` 的 G10 具名被人为改回旧名 ⇒ **必红** | **部分**（`CoverageProbe` 三支臂 ＋ B-9 反极腿走 `~/heavy-slot.sh` ＋ 私有 `:2xx`） |
| **W3** | `build/close-wave.sh`／新件 `build/MilBridge/tools/wave-push.sh`／`build/MilBridge/HANDOFF-NEXT.md`／`docs/ROUTES.md`／`KD`（同趟 `--emit`） | B-2、B-6、B-13（**口径面**）、B-14、**C-1** | W2 | 复核**仓外→仓内**的等价性：① 同一趟清单件数**逐件**可比（搬仓前后**同一波**的脏件集合相同）；② 两枚哨兵 `cmp IDENTICAL`、**13 键**逐键 == 权威路径现取值；③ **正反两极化**：键序打乱／字段清空 ⇒ 牙**必红** | 否 |
| **W4** | `build/close-wave.sh`／`build/MilBridge/tools/wave-freeze-consistency-check.py`／`verify-all.sh`／`docs/WAVE*-PREREGISTRATION.md`／`build/MilBridge/HANDOFF-NEXT.md`／新牙 | B-11（**牙面**）、B-15、B-18 | W3 | 复核**入口/出口步数与声明**：`grep -c '^run_step "'` == 首行 `DECL` 声明的数；四处声明**逐字**一致；新牙的 `--selftest` 两极化真跑；**判**「`provider` 位移是否有机器行留痕」 | **是**（任何整波重跑走槽＋后台作业） |
| **W5** | `build/MilBridge/tools/defect-registry-check.sh`／`docs/CURRENT-STATE.md`／`KD`（同趟 `--emit`） | B-12（**只做修法**） | W4；**且 §0-4 在飞车道已推送** | 复核 `req` 语义的两极化：加宽到命中 `0` 的键 ⇒ **必红点名**；**收窄** ⇒ **不许**静默 `PASS`；同趟 `DEFREG=PASS declared=… route_ids=…` 三态不变 | 否 |
| **W6** | `docs/ROUTES.md`（结账行）／`build/MilBridge/P0-mvp-segv-report.md`／（若采新口径）`build/MilBridge/tools/silent-hit-v2-cases.tsv` | **A-2** | W5；**独占显示位与槽** | 复核**统计口径**：Wilson 单侧上界、Newcombe CI、Fisher 单侧 `p`、`required_n` **四条独立复算**；分母**按件代分开**；`REGDEC_DIRECTION=` 必须由器具打印；**判**「不许宣称率显著变低」 | **是（本件最重）**：`≥131／≥299` 腿走槽＋后台作业 |
| **W7** | `src/WpfGfx.Linux.Native/src/**`（产品）／`docs/ROUTES.md`／`build/MilBridge/P0-mvp-pts-report.md`／在册清单件 | **A-3**（**逐增量各成一波**） | W6 | 复核**前沿位移**：`entry=` 具名行**成对**（前 → 后）＋ `ops/impl/tool` 三口径同时印 ＋ **反退化腿**（名字离开名单而能力为 0 ⇒ 必红点名）；**判**「九位 `win32shim` 位位移是否已逐条点名」 | **是**（构建 ＋ 应用 ＋ 显示位） |
| **W8** | `build/MilBridge/tools/pts-pages-guard.sh`／`docs/ROUTES.md` | **A-1**（**判据反转**） | **W7**（`TASK-0302` 已落地） | 复核**成对反转**：绿条件与红条件**同趟**改；改后绿 ＝ `洋红=0 ∧ 无具名行 ∧ native 真实排版`；**两极化**：换回修前成对件 ⇒ **必红 `rc=134`**；只撤"画占位" ⇒ **必红**（`alive=yes` 但洋红 `0`） | **是**（起 X ＋ 真实点击） |

**并入/剥离规则（逐字）**
- **可并入**：B-1＋B-5＋B-11(文本)＋B-13(文本)＋B-16＋B-17 ⇒ **W1**（全是文本面、全不触覆盖面）。
- **可并入**：B-3＋B-4 ⇒ **同波、波内有序**（顺序错了会把正确的红读成回归）。
- **可并入**：B-2＋B-6＋B-14＋C-1 ⇒ **必须同波**（同一段仓外代码，搬两次＝同一件写两遍）。
- **必须剥离**：**A-1 必须晚于 A-3**（否则是「用旧判据给真因发绿灯」的假绿）；**A-2 必须单独成波**（重活独占、分母按件代分开）；**A-3 的每个产品增量各成一波**（每次构建都动九位）；**B-12 必须晚于 §0-4 那条在飞车道**（同一件 `KD` 的写者位）。

---

## §5 我推翻了在册/派单哪句话（逐条给机器证）

1. **「`porcelain=0`」是被引用的点读数，不是不变量。** 派单给的是 `15:41:02` 的 `0`；我 `15:42:48` 现取亦为 `0`，但 **`15:45:16` 现取 ＝ `3`**（` M build/MilBridge/tools/defect-registry-declared.tsv`／` M samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`?? build/MilBridge/P1-dg179-criteria.md`，mtime `15:44:06–15:44:51`）⇒ **`$N` 里现另有在飞写者**。⇒ **一切以「22 项全未闭」为前提取的排期必须先过 W0。**
2. **§绑定规则 A 表 #5 的「现取 `sha16`」已陈旧。** 该表写 `~/w79c/bin/w79-push.sh` ＝ `fb46d69e6a5cd78a`；**现取 `5015004b0f0d917e`**（23,251 B／mtime `2026-09-28 12:54`，**晚于**该表的取数时刻 `12:22:32`）⇒ 该表自称「逐条按现取重算」，但没有**再取机制**，于是在写下之后 32 分钟就失效。（我逐件复算该表 8 条牙的其余 7 条 **全部同值** —— 只有这一条漂了。）
3. **`§下一波未闭项` 第 15 条的「现取事实」已陈旧两处**：① `~/w14a/` 现取 **9 枚** `W80_*.done`（在册写「只有四枚」）；② 全 `~` `maxdepth 3` 的 `*.done` 现取 **47**（在册写 **41**）。
4. **第 16 条自己用了它反对的东西**：该条把 `TASK-0303` 行写作 `docs/ROUTES.md:228`，而 **`:228` 现取是 `TASK-0204` 行**，`TASK-0303` 行现取 **`:240`**。**内容锚引用成立**（`head -568` ＝ `0dbc62b1d1cf86ee`，逐位相同），**行号不成立**。
5. **第 7 条的「两案择一」事实上已按甲案落地，残留的是另一件事。** 现取 `ALIAS=PASS examined=18042 linked_gt1=0 aliased_out=0`；`~/wfp-runs/arms23/` 现取只有 **2 件**且 `nlink=1`（**无孪生**）⇒ 「删输出侧孪生」已是既成事实。**真正的残留** ＝ 白名单里那行 `6417` 上限**对着一个 0 件的树** ⇒ `allowed-tree-grown` 这条红**结构上不可能触发**。
6. **第 12 条的「下一波」动作在我现取之前已被另一条车道做完。** `KNOWN-DEFECTS.md` 现取 `fa1715f3edefb7eb`（`grep -c 'D-G179'` ＝ 7）、`declared.tsv` 于 `15:44:51` 重发、`report-id-domain-check.sh` 的 `BOOK_ENTRY_UNREQUIRED_MISSING` 由 **`n=16` 降到 `n=15`** 且名单中 `D-G179` **消失** ⇒ 「登记为正式条目」**已完成**；**未完成的只剩**「`req` 要么改成要求集、要么校验侧改判出现集之外的空集」这一**修法**。
7. **B-10 不是「未闭项」，是「已具名的零位移事实」——它不该占一个待办波次位。** 现取 `inputs_fp` 与 `#80` 冻值**逐位相同**、覆盖面 **226**（两个独立复算器互证）⇒ 应降为**每波入口/出口自检**。**条目数仍 22，但排期从「8 波 22 项」变成「8 波 21 项 ＋ 1 条横切自检」。**
8. **在册口径「改 `docs/ROUTES.md`／`HANDOFF-NEXT.md` 也要重发 `declared.tsv`」应精化。** 现取机制证：`defect-registry-check.sh`（`c2d0773e5561a9d1`）的 `ALLKEYS='KD CS HO AB KRJ KRF KRP'` —— **`docs/ROUTES.md` 与 `build/MilBridge/HANDOFF-NEXT.md` 都不在其内**；`DECLDRIFT` 只在这 7 键上算（现取 `grep -n 'ROUTES'` 该件**只在该件的打印行里命中一次**）。⇒ 改这两件**不会**让 `DECLDRIFT` 动（现取 `DECLDRIFT=0`），**也不会**触发规则④；**只有「新编号落进 `KD`（或其 route 键）」才必须同趟 `--emit`**。
9. **两件「承重件不在覆盖面」的洞，比在册记的多一件。** 在册（`ROUTES.md §15ae` 未登记段）只点了 `verify-all.sh` **自身不在** `fp_inputs()`；我现取另发现 **`build/MilBridge/tools/pts-gap-count-check.sh` 也不在**（`infp-n.sh list` 命中 **0**），而它是 `TASK-0302` 唯一在册的缺口计数复算器；**`build/MilBridge/tools/display-lease.sh` 同样命中 0**。⇒ 覆盖面洞**至少 3 件**（`verify-all.sh` ＋ `pts-gap-count-check.sh` ＋ `display-lease.sh`）。
10. **C-1 那条处方自身与现场不符。** 该段写「键序＝**十键**固定序」，而**现取哨兵是 13 行**（`SHA/FP/PC/PF/WB/WIN32SHIM/HBTL/WIC/PROVIDER/DWF/WAVE/BASELINE/BASELINE_SHA16`）⇒ 「十键」这个数**照抄会写出与现场不同的规范**。

---

## §6 `NOINFO` 逐条（具名原因；**既不算绿也不算红**）

1. **B-6**：在册的「本笔 **121 件** vs 本笔入笔 **61 件**」**无法现取独立复算** —— 复算必须**执行** `~/w79c/bin/w79-push.sh`（会真推送）。**我现取能证的只是结构**（`grep -c 'FILES+='` ＝ 0 ⇒ 单一手工累积字面量、无动态追加）。`NOINFO(reason=复算需执行真实推送脚本，按纪律不跑)`。
2. **B-15**：在册「`t64` 两次推送零标记（`find ~ -maxdepth 3 -name '*T64*'` ⇒ 命中 0）」**不可现取复算** —— 这是对**过去某时刻**的存在性断言，`find` 现在给 0 无法区分「从未有」与「已被删」。`NOINFO(reason=对过去时刻的存在性断言；现取 find 命中 0 不构成证据)`。
3. **C-1**：`t15` 记的哨兵 `sha16 = c6ee190ed289455c` **我复现不出**，且**仓内/车道均未找到那一刻的字节副本**（在册：`t68` 已试 16 个变体全不中）。`NOINFO(reason=该 sha16 的字节副本现取无处可取)`。
4. **B-3**：`CoverageProbe` 的**死根面**判活/判死 —— 现取在册为 `NOINFO(臂日志零签名)`，我**没有**跑那三支臂（重活，且需显示位）。本件只**登记**该 `NOINFO` 并把「必须判到底」写成 W2 的验收项。`NOINFO(reason=未跑三支臂；本件只读、不跑重活)`。
5. **B-15**：`w80-record.txt` 现取**不存在**（`~/w21-verify/*record*` 只到 `w77`），而 `w27-freeze.py` 的 `GENS['#80']['TXT']` 指向 `/home/links-dev/w186a/w80/w80freeze/w80-record.txt` ⇒ **该代的记录件不在 `~/w21-verify/` 命名约定下**。`NOINFO(reason=记录件路径约定不统一；本件未追到该件实际落点)`。
6. **A-2**：在册的**在册速率**（`2/175 ⇒ 3.5537%` 等）我**未独立复算**（需重跑那批腿）。本件只登记「该数带臂/件代口径、`gdb` 臂与 `nogdb` 臂不可互用」这一在册更正。`NOINFO(reason=未重跑腿批；本件只读)`。
7. **B-1**：`P0-w80-report §10-1` 要求写进 `provider` **三个时刻**的值；现取只能确认**块/重建/canon live** 四处的**现取值**（`7e8a217b4165a6b9`／`8cb1b50619f4c133`／`759ac1686e5ef87d`／`24e4e0a731dbed40`），**无法**确认「`#79` 块的 `759ac1686e5ef87d` 是哪一个物理时刻产出的」。`NOINFO(reason=历史时刻与产物的对应关系现取不可判)`。

---

## §7 本件的边界（如实划界）

- **只读**：本件是本任务**唯一**写入 `$N` 的件；`$N` 内其余件一字未改（§0-4 的三项改动**全部**属于另一条在飞车道，已用 mtime 与内容取证）。写盘走 `temp+rename`。
- **未跑重活**：未跑 `verify-all`、未跑应用、未起显示位、未跑任何腿批、未构建、未推送。凡「重活」一律只写「应由谁、用什么命令、预估代价」。
- **未复核的读数一律标 `NOINFO`**（§6 七条），**不折算成绿**。
- **`git status --porcelain` 的现值**（本件落盘后）：` M build/MilBridge/tools/defect-registry-declared.tsv`／` M samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`?? build/MilBridge/P1-dg179-criteria.md`／`?? build/MilBridge/P1-tail-scout.md` —— **前三条不是我的**。

---

`P1-TAIL-SCOUT=DONE items=22（A3＋B18＋C1） waves=8 W0_required=yes noinfo=7 heavy_ran=none N_touched=only_this_file sha16_self=21a3be1c895a9c03（口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`；末行即本行）`

⏪ **dated 更正 · PROV 路径 ＋ 同件两处打架（`t25`，读时 2026-09-28T16:20:54+0800）** —— 由 `t15` §5-W3 点名、**队长独立核出更精确的一处**：**同一件内两处打架**（本席现取自算复核，两处原文逐字在下）。
⏪ ① **两处不一致（逐字原文）**：**正文**（内容锚＝`### W2 ·` 小节里「**入口（原文照抄）**」那一条的第 `2` 项）逐字写 ——「豁免通道 ＝ `build/MilBridge/retired-path-provenance.tsv`（`kind=code` **永不豁免**）」【**正确**】；**§4 分波表**（内容锚＝表内行首 `| **W2** |` 的那一行）的「改仓件」栏逐字写 ——「`build/MilBridge/tools/retired-path-provenance.tsv`」【**错误**：该路径不存在】。（本轮现取行号：正文 `:254`／§4 表 `:517`，**仅本次有效**；本条自身插入后行号必再变 ⇒ 此后一律用内容锚。）
⏪ ② **裁定**：**以正文那句为准** ＝ 豁免通道真件是 `build/MilBridge/retired-path-provenance.tsv`（本席现取：`2200 B`／mtime `2026-09-27 11:51:43`／sha16 `10d62946231cc809`；`build/MilBridge/tools/` 下**现取 ABSENT**；该件 `kind=code` 永不豁免的语义不变）。
⏪ ③ **责任链（如实记）**：侦察 **§4 分波表**写错 ⇒ **队长据此路径写进 `t14` 契约的 `inScope`** ⇒ 被 **`t14` 如实顶回**（其报告 §2 末段点名该路径不存在）⇒ **本席同趟在册更正**。⇒ **`t14` 处置正确、不计其错**；错源在侦察件，责任链如上。
⏪ **追加后口径**：`head -n -1 build/MilBridge/P1-tail-scout.md` ＝ `e84ff5e42910f57c`（口径＝**末行之前的全文**；末行＝**本行**）。

⏪ **dated 追加 · V3（行号仅旁注；以内容锚为准）（`t31`，读时 2026-09-28T16:33:26.546+0800）** —— 本段 `①` 行内已写「本轮现取行号：正文 `:254`／§4 表 `:517`，**仅本次有效**」；本笔把规则**上升到段级并写死**：
⏪ **规则（逐字，此后一律照此）**：**「本段及其后续一切引用，一律以内容锚为准；行号（含 `:254`／`:517`）仅作『仅本次有效』旁注，不得作为判据。」**
⏪ **现取核对（本席自算，两锚各自唯一）**：内容锚「正文『**入口（原文照抄）**』那一条的第 `2` 项」（含 `豁免通道 ＝ build/MilBridge/retired-path-provenance.tsv`）现取**恰 `1` 行**；内容锚「**§4 分波表**行首 `| **W2** |` 的那一行」现取**恰 `1` 行** ⇒ **内容锚即可定位，行号不必要**（行号随插入即漂移，正是本仓「坐标挂错族」的成因）。
⏪ ⏪ **dated 更正（本笔自伤，`t31`，读时 2026-09-28T16:33:55.980+0800；上文**保留、一字未删**）**：上一条 V3 里「内容锚『正文「入口（原文照抄）」那一条的第 `2` 项』（含 `豁免通道 ＝ build/MilBridge/retired-path-provenance.tsv`）**现取恰 `1` 行**」这句**前半对、后半错**：
⏪ **按该字符串 grep** ⇒ 现取 **`2` 行**（权威正文行 ＋ **本更正段自己的引文**⇒ **自指**）⇒ **子串锚不唯一**；**唯一定位靠结构锚**（「`### W2 ·` 小节里那条『**入口（原文照抄）**』的第 `2` 项」）⇒ **结构锚唯一、子串锚不唯一**（`D-G130` 同族：锚不定域 ⇒ 复算可指向两行）。
⏪ **§4 表锚**「行首 `| **W2** |` 的那一行」⇒ 现取**恰 `1` 行**（该结论成立，未被本更正触及）。⇒ **以本行为准**：本段引用一律用**结构锚**；子串锚只能作**辅助**（且须注明可能自指）。
⏪ **追加后口径**：`head -n -1 build/MilBridge/P1-tail-scout.md` ＝ `69fb6d20a7eea121`（口径＝**末行之前的全文**；末行＝**本行**）；上一行（`t25` 落）的 `e84ff5e42910f57c` 与其后的 `fb1e396e98771b41` 都是**各自写入时刻**的口径 ⇒ **此后以本行为准**。
