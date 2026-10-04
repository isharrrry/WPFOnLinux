# `V79e-prefer-reds-close-verify.md` —— `t38` 关 `#79` 冻前两红的独立复验（`t39`）

车道 `verifier`／`t39`。`N=/home/links-dev/netTest/GitProj/WPFOnLinux`；只读 `$N`（除本报告）；反极性腿一律在 `~/w28x/t39/**` 的**副本**上做。读数时刻见各条（本报告全部读数取于 **2026-09-28 00:42–00:43**）。

## 0. 判词：**`pass`** —— **据此可否重起 `#79` 链：可**（`waveman` 可从 `pre → 冻结 → post1/post2 → 推送 → 两哨兵` 接着跑，不必重跑整波）

| 项 | artifact | field（现取） | sha16 | 时刻 |
|---|---|---|---|---|
| 红① | `build/MilBridge/tools/pipefail-sigpipe-check.sh` | `PIPEFAIL_SIGPIPE=**PASS undeclared_hit=0 declared=0** files=106 sites=95 hit=0 low=8 diag=4 safe=83 runs=12` | `078e477a59765091` | 00:42 |
| 红② | `build/MilBridge/tools/boundary-decl-check.sh` | `BOUNDARY_DECL=**PASS** records=2 pass=2 fail=0 noinfo=0 coverage=4/6 gaps=0 bystanders=2 expect=2 unverifiable=0 corpus=60 rc=0`；`DECL_RECORD=PASS id=W68-UNWIRED-PRODUCER family=WIRING … obs=PASS **route=none** n_closure=47` | `72c3a93f798f41f7` | 00:42 |
| 改前件（备份） | `~/w196a/backup/root-entries-allowlist-check.sh.pre-t38` / `wiring-closure-check.sh.pre-t38` | 逐处仍为 `printf … \| grep -q` | `e868941384f4bd00` / `1f6ffd939a0b95fa` | 00:42 |
| 改后件 | `build/MilBridge/tools/root-entries-allowlist-check.sh` / `wiring-closure-check.sh` | 逐处已 here-string | `d050d78198e6093c` / `a1ae1257ffd2638e` | 00:43 |

## 1. 红① 逐条复算 ＋ 我自己的反极性

- **形态修（我自己 diff 逐处看，逐字）**：`root-entries` 6 处、`wiring-closure` 3 处，**全部**是
  `printf '%s\n' "$X" | grep -q…` → `grep -q… <<< "$X"`（例：`if ! printf '%s\n' "$list_names" | grep -qxF -- "$dn"` ⇒ `if ! grep -qxF -- "$dn" <<< "$list_names"`）⇒ **是形态修**。
- **不是往声明表塞**：`declared=0`（我现取）且 `pipefail-sigpipe-check.sh` 只有 `--root/--runs/--list/--selftest`、**没有声明表文件**（`ls` 现取只有该 `.sh`）⇒ 无表可塞。
- **我的反极性（副本，真树零改）**：把 `root-entries` 副本的 `:236` 一处改回 `printf|grep -q` ⇒
  ```
  SITE verdict=HIT file=root-entries-allowlist-check.sh line=236 kind=grep-q consumer=cond reach=capture-unknown left="if ! printf '%s\n' \"$list_names\"" dyn-flip dyn_big=4/4 dyn_off=0/4 dyn_small=0/4
  PIPEFAIL_SIGPIPE=FAIL undeclared_hit=1 decl_stale=0 files=1 sites=4 hit=1 low=0 diag=0 safe=3 runs=4
  ```
  同一副本**未改时**（第二个沙箱）⇒ `PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 sites=3` ⇒ **红非空转** ✓

## 2. 红② 判据边界：我跑的四条腿（**这两条就是本条的判据**）

牙内置夹具腿（我用 `--selftest` 执行并读**逐腿判词**，不是只读它的总结）：
```
BDC_LEG=OK name=pos                rc=0 want=0     ← 正极：不在任何调用里 ⇒ route=none ∧ record PASS
BDC_LEG=OK name=neg-direct         rc=1 want=1     ← **腿①** 代码位直调 ⇒ rc=1（want route=direct）
BDC_LEG=OK name=neg-wrapper        rc=1 want=1     ← 代码位经包装件 ⇒ rc=1（want route=transitive）
BDC_LEG=OK name=pos-data-mention   rc=0 want=0     ← **腿②** 只在数据/提及里出现 ⇒ rc=0（want route=none）
（另 8 条：neg-absent=3／neg-new-record=1／neg-count=1／neg-uncovered=1／neg-unmarked=1／neg-evaporated=0／neg-no-record=1／pos-bystander=0）
```
⇒ **代码位引用 ⇒ 判红（direct／transitive 两形态各一条）** ∧ **只提及（注释/数据）⇒ `route=none` ∧ PASS** —— 与 `t38` 的论证（`code_lines_only()` 只剥"不可能是命令起点"的行）**同向且成立**。
**真树现场＝腿②的真实实例**：改前的假红正是由**数据**引起的（`build/close-wave.sh:359` 的 `fp_inputs()` printf 参数表**续行** ＋ `wiring-closure-check.sh` 的 `cat <<'ROSTER'` 体），现取该 record 回到 `obs=PASS route=none` ✓。

## 3. 判据域没放松（三颗牙腿数，改前/改后两读）

```
root-entries  : 现件 ROOT_ALLOW_SELFTEST=PASS cases=**18** pass=18 fail=0
                改前件（备份）直接跑 ⇒ **FAIL cases=18 pass=12 fail=6**（假红）
                改前件 + RA_REAL_ROOT="$PWD" ⇒ **PASS cases=18 pass=18 fail=0**  ← 忠实改前值＝18/18
wiring-closure: WIRING_CLOSURE_SELFTEST=PASS cases=**11** pass=11 fail=0
pipefail      : SELFTEST=PASS total=**15** pass=15 fail=0
boundary-decl : BDC-SELFTEST=PASS cases=**14** pass=14 fail=0
boundary-decl 四格（逐字）：DECL_RECORD=PASS id=W68-LEGACY-COPIES … marked=7 evaporated=0（七处 marked(1)）｜DECL_CENSUS candidates=6 covered=4 bystanders=2 expect=2 over=0 gaps=0 keys=legacy-copies,producer｜DECL_BYSTANDER idx=1 file=WAVE16-PREREGISTRATION.md line=203 ／ idx=2 file=WAVE46-PREREGISTRATION.md line=38｜DECL_UNVERIFIABLE n=0
```
⇒ **腿数一条未减**（18＝18、11、14、15 全绿），四格与改前同形。**方法坑我复现了这一对**：备份直接跑＝`12/18`（副本位置把 `SELF_DIR/../../..` 指偏的假红）／加 `RA_REAL_ROOT="$PWD"` ⇒ `18/18` ⇒ **`t38` 没有把假红当成"改前值"写进结论**（我核到它记的是 18/18，与我的忠实读数一致）✓

## 4. 全局四项（现取，00:43）

```
run_step=55（`grep -c '^run_step "'`）
VERIFYALL_SELF=PASS names=55 decl=55 gen=#79 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=**3c80498ab2896955**
FP_MANIFEST_TEETH=PASS reason=ok files_n=**225** files_n_uniq=225（`--expect 225` ⇒ declared_expect 相符）
FP_INPUTS_HYGIENE=PASS reason=clean coverage_n=**225** artifact_n=0
infp.sh fp = **75f61e3de70ec5e6**…（与主控"移后"值逐位相同）｜list|wc -l = **225**
```
⚠️ 附注：`verify-all.sh` 的 sha16 在我这一趟里读到的是 `3c80498ab2896955`（`t30` 那一刻是 `52b4d0a7e687328d`）⇒ 该件在我/别的车道复验期间**又被改过**；**三处计数一致**（55/55/55）且 `VERIFYALL_SELF=PASS`，故不判缺陷，仅记时刻（本报告所有 sha16 都带时刻）。

## 5. findings（1 条低危，不阻塞重起）

- **F1（low）同一 hazard 族有一处不在牙的扫集里**：`root-entries-allowlist-check.sh:197`
  `in_allow() { printf '%s\n' "$parsed" | cut -f1 | grep -qxF -- "$1"; }` —— 它也是"**末段 `grep -q` 早退 ⇒ 上游可能吃 SIGPIPE**"的形态，但牙的匹配只看 `printf … | grep -q`（**紧邻**那条），中间多一个 `cut` 就扫不到（它自报 `sites=95` 不含该处）。**我的独立判断**：**运行期影响未取到读数 ⇒ `NOINFO`**（该处输入是 25 行的清单，管道缓冲够大，实测未见过 SIGPIPE），但**形态上属同一族** ⇒ 建议要么把形态扩到"`… | <任意> | grep -q`"（并按现读重算台账），要么在台账／声明里**具名**豁免它。

**边界与 `NOINFO`**：① 我没有**自撰**夹具树造出"我自己的 declaration"两条腿（那需要一行 wave-prereg 声明语料），而是**执行牙内置的 `neg-direct`／`neg-wrapper`／`pos-data-mention` 三条夹具腿并读逐腿判词** ⇒ 「两条腿真跑」这一格我用的是**内置夹具＋真树实例**（真树那条是数据成因的假红被关掉）；② F1 的运行期影响 `NOINFO`；③ 未跑 `verify-all` 整趟（无重活）；④ `Xvfb :236`（非我的）未动。

`T39=PASS red1=PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 red2=BOUNDARY_DECL=PASS route=none leg_antipode=FAIL点named leg_code=rc1×2 leg_data=rc0 legcounts=18/11/14/15 假红对=12/18↔18/18(RA_REAL_ROOT) global=55/VERIFYALL_SELF/225==225/FP_INPUTS_HYGIENE inputs_fp=75f61e3de70ec5e6 restart=YES findings=1low`
`SELF_SHA16=95338d8d258e300b`（口径＝去掉本行：`head -n -1 build/MilBridge/V79e-prefer-reds-close-verify.md | sha256sum | cut -c1-16`）
