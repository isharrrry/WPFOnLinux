# W157A 报告 —— 波 `#64`（`TASK-0717`：把「基线率闸」做成仓内牙）

> **输出格式**：纯文本/Markdown（无 JSON／无 schemaJson／无 HTML／无卡片）
> 车道 **W157A**｜`R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**不是 git 仓库**；推送面 = `~/netTest/GitProj/WPFOnLinux` 的 `feat-Linux`）
> 判据先行：`~/w157a/criteria.md`（`89ac288b87f13384`，391 行）｜方法页 `~/w157a/baseline-rate-gate.md`（`c4839dc9e8876bcf`／口径 `57915081ffdbacf8`）
> `sha16` 口径：`sha256sum <件> | cut -c1-16`，**一律现场现算，不手抄**。

---

## §0 一句话

**`#64` 已冻结并跑完整条收尾链**：把 `D-G118`「基线率闸」做成仓内**牙 ＋ 确定性台账**，接进 `verify-all` 第 `[37]` 步（**36 → 37 步**），覆盖面 `159 → 161`；**零产品改动 ⇒ 九位只有 `pf` 同尺寸位移**；冻前／冻后各趟 `verify-all` **37 ✅ / 0 ❌**；并在本波现场抓到 **`D-G120`**（续行中的注释 ⇒ 命令被截断 ＋ 后续行被**执行**）。

---

## §1 落地（全部 `temp ＋ rename`；前后 sha 双断言；**备份取在任何写之前** → `~/w157a/w64-backup/`）

| 件 | 修前 | 修后 |
|---|---|---|
| `build/MilBridge/tools/baseline-rate-gate.sh` | **新建** | **`31cf77abc6a882e3`**（382 行） |
| `build/MilBridge/tools/baseline-rate-cases.tsv` | **新建** | **`8d71171d475a63dc`**（41 行／11 用例） |
| `verify-all.sh` | `2819b5990e74cc80`（`run_step=36`） | **`6a8ae4e80fefd97b`**（`run_step=37`） |
| `build/close-wave.sh` | `9ee0c2488d25f6f6` | **`168a33c3d4743559`**（名单 +2 行） |
| `docs/WAVE64-PREREGISTRATION.md` | **新建** | **`cbcaceb4886f05a5`**（111 行；标题含字面 `#64`） |
| `~/w21-verify/w27-freeze.py`（不落仓） | `efc72d2bf4862793` | `42efd7db5013b1cf`（加 `GENS['#64']`） |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `4ee96c043b472c11`（919,687 B） | **`6b01358a776dd936`**（**936,553 B**） |
| `docs/CURRENT-STATE.md` | `79703ac46431e0b4` | 机器行 `> BASELINE-FROZEN gen=#64 sha16=6b01358a776dd936` |

---

## §2 牙：`baseline-rate-gate.sh`（`D-G118`）

**判什么**：**在册速率还能不能用来定 `N`** —— 不是重判任何回归结论。

**三态机读行**：`BASELINERATE=PASS|FAIL|NOINFO`（`rc` = `0|1|3`）＋ **逐项字段行**
`registered=<R>/<n>@<时间窗>`／`window=`／`observed=`／`observed_rate=`／`ci_upper=`／`ci_upper_2s=`／`ci_lower_2s=`／
`cp_upper=`／`fisher_p=`／`registered_in_observed_ci=`／`gate=`／`effect=`／`required_n=`／`required_n_power=`／
`voidpremise=`／`voidpremise_reason=`／`gate_closed=`／`effect_impossible=`／`caliber_disagreement=`／
`gate_verdict_1s=`／`gate_verdict_2s=`。

- **`FAIL` 必须点名**「**历史速率落在新样本 CI 之外**」—— 真现场数逐字：
  `DRIFT 历史速率落在新样本 CI 之外（registered=24/27=0.8889 ∉ 现取 CI [0.1268,0.4336]） + VOID-PREMISE ① ci_upper(0.4024) < gate(0.7000);以② observed(0.2500) < effect(0.3000) ⇒ 该效应在现世界不可发生`。
- **`VOID-PREMISE` 两条并列**（**不取其一**）：① `ci_upper < gate` ② `observed < effect`。
- **响亮 `NOINFO`**（具名）：缺时间窗（`NOINFO-NO-WINDOW`）／空样本（`NOINFO-EMPTY-SAMPLE`）／`n` 非正（`NOINFO-N-NONPOS`）／
  `r` 越界（`NOINFO-R-RANGE`）／参数不可解析（`NOINFO-PARSE`／`NOINFO-USAGE`）—— **禁静默判等**（纪律 27）。
- 🆕 **口径之争先于结论**：`ci_upper=` 用 **Wilson 单侧 95%（主判据）**，`ci_upper_2s=`／`ci_lower_2s=` 用**双侧（诊断）**；
  **两口径在闸比较上结论不同** ⇒ `NOINFO` ＋ 具名 `reason=caliber-disagreement`，**禁止**用"对我方有利的那一界"下 `PASS`/`FAIL`。

### §2.1 算程自证（**先证它会对得上在册**）

| 输入 `alt_rates` | 仓内 `criteria §4` 在册行 | 本牙输出 | 判 |
|---|---|---|---|
| `0.1000-vs-0.8890` | `per_arm=7 power=0.8224` | `per_arm=7 power=0.8224` | ✅ 逐位同 |
| `0.5890-vs-0.8890` | `per_arm=37 power=0.8010` | `per_arm=37 power=0.8010` | ✅ 逐位同 |
| `0.6090-vs-0.8890` | `per_arm=41 power=0.8019` | `per_arm=41 power=0.8019` | ✅ 逐位同 |
| `0.0000-vs-0.0600` | `per_arm=131 power=0.8041` | `per_arm=131 power=0.8041` | ✅ 逐位同 |

另与**独立算程** `~/w157a/bin/baseline-rate-gate.py`（`0dac2ea941b56f4f`）**逐位对账**：
`observed 0.2500`／`cp_upper 0.4187`／`fisher_p 1.848e-06`／双侧 `[0.1268,0.4336]` **全同**。

---

## §3 台账：11 行**确定性合成**用例（不依赖现场腿读数 ⇒ 不随世界漂移而红/绿）

```
CASE DG118-task0111-live-drift    got=FAIL/1/DRIFT          want=FAIL/1/DRIFT          OK   ← 本缺陷真实现场（冻结常量）
CASE a-self-consistent            got=PASS/0/PASS           want=PASS/0/PASS           OK
CASE b-sample-outside-ci          got=FAIL/1/DRIFT          want=FAIL/1/DRIFT          OK   ← 点名
CASE c-effect-impossible          got=FAIL/1/VOID-PREMISE   want=FAIL/1/VOID-PREMISE   OK   ← 只让②成立
CASE d-empty-sample               got=NOINFO/3/NOINFO-EMPTY-SAMPLE  OK
CASE d2-no-window                 got=NOINFO/3/NOINFO-NO-WINDOW    OK
CASE d3-n-nonpositive             got=NOINFO/3/NOINFO-N-NONPOS    OK
CASE d4-r-out-of-range            got=NOINFO/3/NOINFO-R-RANGE     OK
CASE e-counterexample-22-of-27    got=PASS/0/PASS           required_n=43  OK   ← 反例对照①
CASE f-counterexample-12-of-12    got=PASS/0/PASS           required_n=21  OK   ← 反例对照②
CASE g-caliber-disagreement       got=NOINFO/3/caliber-disagreement OK   ← 口径打架
BASELINERATE_CASES=11 passed=11 failed=0 ／ BASELINERATE=PASS
```
- 两条**反例对照**证明闸**不是**恒判 `VOID-PREMISE`（`D-G89`）。
- `--selftest`（夹具在 **`$HOME` 沙箱** `~/baseline-rate-gate-selftest/run-*`）：8/8 ＋ **反极性**（把某行 declared 期望改错 ⇒ `bad_ledger_rc=1` ⇒ **证明"比对"真在比**）。
- 比存量惯例**更严**：逐行除 `state`/`rc` 外还比**具名 reason 类**（因为本牙的验收点之一就是「`FAIL` 必须点名」）。

---

## §4 接线（四处声明同趟；**由权威牙判**）

第 `[37]` 步 `BASELINE-RATE-GATE`（`--cases` 形态、纯读、零 `dotnet`、**秒级**）。
`VERIFYALL_SELF=PASS names=37 decl=37 gen=#64 dup=0 order=OK prose=OK prereg=PASS vfile_sha16=6a8ae4e80fefd97b` ✓
- `DECL` 首行 `37 gen=#64`｜`STEP-NAMES` 尾加 `BASELINE-RATE-GATE`｜口径句逐字 ``**`#64` 收官起 = 37 步**``｜`docs/WAVE64-PREREGISTRATION.md`（标题含 `#64`）。
- 预登记**两分支都命中**（`PREREG-NO-REGRESSION-DECISION:` ＋ 正则式 `本波.*不做任何回归判定`）。
  ⚠️ **第一版踩到**：我把 `**` 夹在「本波」与「不做任何回归判定」之间 ⇒ **正则分支不命中**（只剩 marker 分支）⇒ 已去掉、两分支都命中。
  ⚠️ 两条"证据串"**均为 0 次**（本件**刻意不逐字复现**回归判定工件的判词行与那张台账文件名 —— 该牙的"有证据"检测是全文子串匹配，逐字提到就会被判成"有证据"而走 `FAIL`，**假红方向**）。

---

## §5 覆盖面与成对记账（`159 → 161`）

- 加两行进 `fp_inputs()`：**牙 ＋ 它的台账**（**先例**：回归判定牙 `regression-decision.py` **与它的台账**在名单里，现场 `list` 命中 2 行）。
- **三处作用**：① 牙入名单 ② 台账入名单 ③ `close-wave.sh` **自含**于覆盖面而被改。

```
BEFORE_FILES=159  BEFORE_FP=7836c5fa17cd454893f9a4101fe2210181217f035c306122cbbed259293a772f   ← == prev_infp ✓
AFTER_FILES=161   AFTER_FP =f148203453b092206b6a9f9529821fa58570ba7035fb5253ca4f4e8da6dd77ae
AFTER_PREDICTED  == AFTER ✓（组合式预测 ⇒ 无第三隐形位移）
交叉表  (none)161 f1482034 ｜ T 160 556185a7 ｜ G 160 d270404e ｜ G+T 159 59218752
       ｜ C 161 3745d7cb ｜ C+T 160 9219b4f2 ｜ C+G 160 e2fc4c4e ｜ **C+G+T 159 7836c5fa ✓ 逐位 == prev**
ATTRIB_ROLLBACK=PASS
```
（`C`＝`close-wave.sh` 自身／`G`＝牙行／`T`＝台账行；**每格断言 `hits`** —— 缺 `hits` 断言那次吃过假"无位移"。）
落地前后各留一次件清单（`~/w157a/w64-before.list` 159 件／`w64-after.list` 161 件）。

---

## §6 🔴 本波现场抓到的新缺陷 **`D-G120`**（主控已立号；`TASK-0718` 排 `#65`）

**缺陷**：**往 `\` 续行的参数表中间插注释 ⇒ 命令被截断 ＋ 后续行被当命令"执行"**（**静默**，且**失败不改 `rc`**）。

**最小复现（我打过，主控独立复现过）**：
```
$ bash -c 'printf "%s\n" A \
    # comment in the middle
    B \
    C'
A
bash: 行 4: B: 未找到命令          ← 整体 rc=0
```
⇒ **只印 `A`**；`B`/`C` 成了**新的一条命令**被真的执行。

**本波现场后果**（真数）：
- `FILES_N` 读 **`160`**（应 **161**）；
- 指纹**凭空多出** **`e4888835…`**；
- 机制：被执行的牙把它的 stdout（`BASELINERATE_REASON=NOINFO-USAGE 未知参数 …`）吐进 `{ … } | sort | xargs sha256sum`
  ⇒ `sha256sum` 去 hash `BASELINERATE=NOINFO` 这种"文件名"（stderr 一串 `没有那个文件或目录`）、**而真正的文件名被吞**。

**两条必备牙**（已逐字写进 `w64-record.txt`）：
① 清单**逐行**必须 `<64hex>  <path>`，否则**响亮失败**；
② `files_n` 与**期望件数**对账。

**要害口径句（主控采纳、入册）**：
> **「`\` 续行的参数表中间不许插注释；凡指纹/清单类管线必须另有一条**独立于该清单**的证据（件数 ＋ 逐行形态断言）——『预测值 vs 实测值』同源时，自洽抓不到污染。」**

（**这条最值钱**：`after == after_predicted` **抓不到**它 —— 因为预测就是按同一份**被污染**的清单组合出来的。）
**修法**：注释移到 `printf` **语句之前**、两行文件名**留在参数表内**；修后 `dirty=0`／`FILES_N=161`。

---

## §7 收尾链读数

| 步 | 读数 |
|---|---|
| 接线那一刻 `verify-all` | **37 ✅ / 0 ❌**、`用例通过 875 跳过 2`、`结论：✅ 全部通过` |
| 整波 `close-wave.sh --skip-verify-all` | 槽内 `rc=0`（held 282s）；`[4/6]` **波前==波后 == `f1482034…`**；`[2/6]` native「源码不比权威件新 ⇒ 跳过」；`[3/6]` 桥「源指纹一致 ⇒ 无需重发」；应用器审计 `miss=0`；⚠️ `APPSYNC 非 PASS`（**登记在册**的 `UNEXPECTED=6`，其日志自己写着"不必然是本次引入"） |
| 门禁 ×2（严格串行） | 两趟各 `n=6 pass=6`；**判词行逐字一致** `GATE_PAIR=IDENTICAL`；两本 rows `config=` 均含终态 `pc:722e0ab8205b7c3f` ∧ `pf:02b2792448fbd41d` |
| 冻前 `verify-all` | **37 ✅ / 0 ❌**、`875/2`、`结论：✅ 全部通过`；新步 `[37] BASELINE-RATE-GATE ✅ BASELINERATE=PASS` |
| **冻结** | **`FREEZE_RC=0`**；`世代交叉断言通过：树上 #63 == GENS['#64'][prev]`；**冻前声明类红项 = `[]`**；牙齿② `run_step=37 == nstep 37` 且头注释同数字 |
| 四颗牙 | `BASELINESHA=PASS live=6b01358a776dd936 decl=6b01358a776dd936`｜`BASELINEGEN=PASS decl_gen=#64 file_newest_gen=#64`｜`BASELINE_BYTES=936553`｜`BASELINEDUP=PASS n=0` |
| 冻后 ×2 | 两趟各 **37 ✅ / 0 ❌**、`875/2`、`结论：✅ 全部通过`、新步 ✅；**剥离运行期读数后两趟判词行逐字相同**（各 55 行） |
| `NOFILE_SWAP` 证据 | 两趟 `saved_shim=921ba9c65e9fb3be` 相同、`BASELINESHA=PASS live=6b01358a776dd936` 相同 |
| marker | `~/w21-verify/w64-POST.done` **真 `stat`：`mtime=2026-09-24 16:17:43.450308721 +0800`**、`size=0` |
| app-local | `APPSYNC-REFRESH=refreshed=0 newer=0 applied=1`；`MISMATCH=0[STALE=0 NEWER-DIFF=0] MISSING=0 DIVERGENT=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0` ⇒ **`STALE=0 DIVERGENT=0 MISMATCH=0 MISSING=0`**（`check` 退出码由**登记在册**的 `UNEXPECTED=6[DECL-GAP-EQ]` 决定 —— 与 `#60`/`#61` 形态逐字相同 ⇒ **继承**，不是新问题） |
| 两处哨兵 | `cmp` **IDENTICAL**；**九位 9/9 逐位相符**（集合口径）；手工补 `BASELINE=#64 sha16=6b01358a776dd936 bytes=936553` |

⚠️ **一趟作废（如实记）**：首次 `verify-all` 我按 `--max-hold 900` 进槽 ⇒ 跑到第 `[17]` 步被 `HEAVYSLOT=MAXHOLD_KILL held=900s` 强杀 ⇒ 判「**作废（持有上限，非读数）**」、改 `--max-hold 1500` 重跑（口径来自 `#54` 那条方法学）。

---

## §8 九位（**零产品改动 ⇒ 只允许 `pf` 同尺寸位移**）

| 位 | 开工前 | 现 | 判 |
|---|---|---|---|
| `bridge` | `4e25e4b27d4d5ae1` | `4e25e4b27d4d5ae1` | 未变 |
| `pc` | `722e0ab8205b7c3f` | `722e0ab8205b7c3f` | 未变 |
| **`pf`** | **`9bf76afe89944ccc`** | **`02b2792448fbd41d`** | **变（同尺寸 6,123,520 B）** |
| `windowsbase` | `2e4e46e539a72cd7` | 同 | 未变 |
| `provider` | `1f9511a7ef395bfe` | 同 | 未变 |
| `win32shim` | `d2b76a0a56a41be1` | 同 | 未变 |
| `wic_shim` | `f7b3026c8c019be2` | 同 | 未变 |
| `hbtextline` | `921ba9c65e9fb3be` | 同 | 未变 |
| `dwf` | `ce3469f49efcbcfa` | 同 | 未变 |

**只有 `pf` 动**（`relative 位移 = ['pf']`）⇒ **满足停条件①**（第二处位移 ⇒ 停手报主控；**未发生**）。
📌 **整波什么都没重建**（native 跳过、桥无需重发）**而 `pf` 仍位移** ⇒ 印证在册口径：`pf` 是**环成员**、整波必变、**同尺寸** ⇒ **机械位移，不许当漂移/回归判据**。

---

## §9 `PRE` 与记录件

- `~/w157a/w64-pre.sha`（9 行）**与 `#63` 冻结块「九位（Release 权威件）」内容锚现比 9/9 逐位相符** ✓。
- `~/w21-verify/w64-record.txt`：**先建模板、后冻结**；三段 `===BANNER===`/`===FROZEN===`/`===RECORD===` 解析通过；
  **27 个占位符全部在冻结器定义集内、无未定义**（否则冻结器 `assert` 当场红）；裸花括号 1 处（`awk '{printf …}'`）—— 冻结器用**正则**替换 ⇒ 安全。
- `GENS['#64']`：**改 `w27-freeze.py` 前先 `cp -p` 备份**；位置锚 `count==1`；`temp ＋ rename`；回读断言 ＋ `py_compile` 通过。

---

## §10 五条口径句（落册，均来自现场实测）

1. **「条件同一性」必须包含『世界的时间稳定性』**：凡登记速率都必须带**时间窗**，且用于定 `N` 之前必须在**同窗现取**一道基线率闸 —— 对不上就 `VOID-PREMISE`，**不许拿历史速率凑功效**（`D-G118`）。
2. **干涉臂的入分母条件不许用「被去掉的那件事还在」**；要用「该拍上确实发生了这次尝试」＋各臂各自的忠实性断言（`D-G116` 第 4 实例）。
3. **「谓词选错 ⇒ 恒 0 ⇒ 读成『线上没有』」**：族识别按 `type`、忠实验证按 `prop==type==靶原子`，**两个谓词各管一件事**（`D-G116` 第 5 实例 · `PROP-VS-TYPE`）。
4. **口径之争先于结论**：同一件事有两个口径时，**在判据上打架 ⇒ `NOINFO` 且具名**，禁止挑对我方有利的那一界。
5. **`\` 续行的参数表中间不许插注释**；凡指纹/清单类管线必须另有一条**独立于该清单**的证据（件数 ＋ 逐行形态断言）—— **「预测值 vs 实测值」同源时，自洽抓不到污染**（`D-G120`）。

---

## §11 推送（逐径 `git add`；**禁 `-A`**）

```
推送前（快进判据用**远程实况**，不用本地猜测）：remote = 3e9d6f96c4c7ced9fdaf84b8dbe69c40d91887ef
  ⇒ git merge-base --is-ancestor 远程 本地 = 是 ⇒ **可快进、无需 --force**
push: 3e9d6f9..b505af4  feat-Linux -> feat-Linux
refspec 陷阱（显式 fetch 到远程跟踪 ref）: 3e9d6f9..b505af4  feat-Linux -> origin/feat-Linux
  本地 HEAD            = b505af4b247eb91f6057131316322e4223c905a8
  origin/feat-Linux    = b505af4b247eb91f6057131316322e4223c905a8
  ls-remote(feat-Linux)= b505af4b247eb91f6057131316322e4223c905a8     ← **三者一致**
  ls-remote --symref origin HEAD : refs/heads/feat-Linux               ← 仍 `feat-Linux`
  porcelain（推送后）  = 0
porcelain（推送前）8 行 == `--cached` 8 件（**逐一相同、无夹带**；未用 `-A`）
**BYTECHECK ok=8 mismatch=0 nobody=0**（口径 `git cat-file blob origin/feat-Linux:<path>` vs `$R` 磁盘逐件）
变更集（8 件）：verify-all.sh／build/close-wave.sh／build/MilBridge/tools/baseline-rate-gate.sh（新）／
  build/MilBridge/tools/baseline-rate-cases.tsv（新）／docs/WAVE64-PREREGISTRATION.md（新）／
  samples/WpfTextDemo/ACCEPTANCE-BASELINE.md／docs/CURRENT-STATE.md／build/MilBridge/W64-report.md（新）
```

## §12 写域（**逐件核过**）

- **主控写域四件逐件核「不在变更集」** ✓：`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／
  `build/MilBridge/tools/defect-registry-declared.tsv`／`build/MilBridge/HANDOFF-NEXT.md` —— 本次 `git diff --name-only` 里**一件都没有**。
- ⚠️ **如实报（交主控）**：这三件在 `$R` **工作树里比远端超前**（主控写域、我**未碰**）：
  `ROUTES.md` `$R=ee077b07396f764e` vs 远端 `08a90b86a3d8e41e`｜`KNOWN-DEFECTS.md` `$R=088c530942eafa74` vs `ea5c6366f30b3875`｜
  `declared.tsv` `$R=2b38145ce33d5f1d` vs `350ea07a8e91393c` ⇒ **需主控自行推送**（本车道的 `add` 是逐径的，不会带上它们）。
- **`src/**` 一字未动**（零产品改动；九位只 `pf` 位移即为机械证）。
- 本地件：`~/w157a/criteria.md`｜`~/w157a/baseline-rate-gate.md`｜`~/w157a/bin/{baseline-rate-gate.py,w64-attrib.py,w64-gate.sh,w64-post.sh,patch-gens64.py}`｜
  `~/w157a/logs/{verify-all-w64-1,verify-all-w64-prefreeze,verify-all-w64-post1,verify-all-w64-post2,close-wave-w64,w64-gate}.log`｜
  `~/w157a/{w64-pre.sha,w64-before.list,w64-after.list,gate-rows.txt,gate-rows-f.txt}`｜`~/w157a/w64-backup/**`。
