# 波 `#70`（`TASK-0724` ＋ `TASK-0728`）· 清单/指纹**要有牙**｜owner **W168A**

**结论**：`FREEZE_RC=0`，基线 **`c7cdcbb50e3f19a7` → `83f6f475c9395e72`**；`verify-all` **41 → 42 步**；覆盖面 **171 → 172**；
**零产品位移**（九位里只有环成员 `pf` 变：`4143bf4f50a7eba1` → `bea7e47e42fd4e01`，同尺寸 6,123,520 B）。
三趟独立 `verify-all`（`gate1`／`gate2`／`pre`）**各 `步骤通过 42 ❌ 失败 0` ∧ `结论：✅ 全部通过` ∧ `用例通过 875 跳过 2`**。

## §1 两件病 · 两处修

| 任务 | 病 | 修法 |
|---|---|---|
| `TASK-0724` | `build/MilBridge/tools/fp-manifest-teeth-check.sh`（`#65` 落仓、`be19edddf7f02797`）**在 `fp_inputs()` 覆盖面里，却没有任何一步调用它** ⇒ 正常运行恒 `FP_MANIFEST_TEETH=NOINFO reason=no-manifest`、`rc=2` ⇒ **清单算错也不会响** | **新步 `[42] FP-MANIFEST-TEETH`** ＋ 驱动件 `build/MilBridge/tools/fp-manifest-step.sh`（**同码路径拦截**现取活清单） |
| `TASK-0728` | `#67`：白名单两行**指向不存在的件** ⇒ `xargs sha256sum` 只把抱怨打到 `stderr`、`stdout` 仍是部分结果，管道 rc 取自最后一段 `cut` ⇒ **恒 0** ⇒ `inputs_fp` **形状完好（64 hex）而覆盖面是缺的** | **折叠进既有第 `[12]` 步**（**不另开步**）：**逐行存在性 ∧ `stderr` 非空 ⇒ FAIL**，并**当场印出旧口径的假指纹** |

**落仓 4 件**（写前逐件 `stat -c %h==1`、先 `cp -p` 备份、temp＋`mv` 原子替换、写后现算）：

| 落点 | before → after |
|---|---|
| `build/MilBridge/tools/fp-manifest-step.sh` | **新建** `db4a2d9856534aba` |
| `build/MilBridge/tools/fp-inputs-hygiene-check.sh` | `68ef01bfb9c6a8ee` → `5b0b0f4898865e04` |
| `build/close-wave.sh` | `3b891df8317b1f7c` → `6297e03253232b39`（白名单 +1 行） |
| `verify-all.sh` | `cc675e85d1b42c62` → `93ae21cdaf712567`（41 → 42 步；四处声明同趟） |
| `docs/WAVE70-PREREGISTRATION.md` | **新建** `47ca5a9993771386` |

**清单从哪来**：`verify-all.sh` **不在**覆盖面 ⇒ 步本体里的 `--expect 172` 是**与生产路径无关**的显式常数（漏改 ⇒ `files-n-mismatch` 红，方向安全）；清单本身由驱动件以**同码路径拦截**从 `close-wave.sh` 现取（`fp_inputs()` 函数体**一个字都没改**）。
**`TASK-0728` 为什么不落参考件**（主控已批复）：`[12]` 的 `capture()` 已握有**被 `cmp` 机器证过完备**的权威成员表（`sha256sum` 的 `argv`）—— 比参考件"重跑 `fp_inputs()` 读 stdout"更强；另起一件必须**再抽一次覆盖面**（本仓明令：同一份逻辑存在两处必然分叉）；参考件 `~/w164a/w70/fp-inputs-existence-check.sh`（`906153a9db4f9164`，实测未截断）自带两条继承缺陷（车道名变量 `W164A_R`；临时件落共享 `/tmp` 固定名）⇒ **记为"已被取代、不落仓"**。

## §2 两极化（`~/w168a/w70/logs/polarity-70.log`，**16/16 腿全绿**；每腿只换一个变量）

- **正极**：`[42]` `FP_MANIFEST_TEETH=PASS reason=ok files_n=172 files_n_uniq=172 blank_n=0`、驱动 `names_n=172 manifest_n=172 expect=172 sha256sum_stderr_bytes=0`；`[12]` `PASS reason=clean coverage_n=172 artifact_n=0 missing_n=0 stderr_bytes=0`。
- **`0724` 反极 A（只换被判件）**：续行参数表中间插一行 `#` 注释（`D-G120` 真咬形态）⇒ `files-n-mismatch files_n=141 expect=172 delta=-31`，**并印出形状完好的假指纹**。
- **`0724` 反极 A′（只换被判件，异物灌进管线）**：断续行 ＋ 插 `printf '%s\n' BASELINERATE=NOINFO` ⇒ `sha256sum-stderr-nonempty stderr_bytes=60`、`manifest_n=141 ≠ names_n=142`。
- **`0724` 反极 B（只换声明常数）**：`--expect 173` ⇒ `files-n-mismatch delta=-1`。
- **`0724` 反极 C**：取不到清单 ⇒ `NOINFO reason=close-wave-missing rc=2`；覆盖面为空 ⇒ `NOINFO reason=manifest-empty rc=2`（**都不算绿**）。
- **`0728` 反极（沙箱副本，真树白名单一字未改）**：一行指向不存在的件 ⇒ `rc=1`／`reason=coverage-member-missing missing_n=1`／**逐条点名** `FP_INPUTS_HYGIENE_MISSING=FAIL kind=MISSING path=build/MilBridge/GONE-70.cs`／**并印出** `would_be_fp=0e8254f8cf842836`（**恰等于当时树上的 `inputs_fp`** ⇒ 旧口径会拿它当绿）；**只把那一行去掉 ⇒ 回绿**（成对）。
- 牙自测：`fp-manifest-teeth-check.sh --selftest` **13/13**；`fp-inputs-hygiene-check.sh --selftest` **16 → 18 例**（新增 `S10` 缺件必红＋`S11` 回绿，及夹具完备性闸）。

## §3 冻结守卫（四格全过）与位移账

- 格 1／2：三趟判词行逐字相同；`[11] VERIFYALL_SELF=PASS names=42 decl=42 gen=#70 dup=0 order=OK prose=OK prereg=PASS`｜`[7] BASELINESHA=PASS live=c7cdcbb50e3f19a7`（冻前仍是上一代值）｜`[17] PIPEFAIL_SIGPIPE=PASS`｜`[40] BAK_COMPLETENESS=PASS n_wired=0`｜`[41] ALIAS=PASS aliased_unallowed=0`｜`[42]`／`[12]` 见 §1｜**覆盖面现算 172**。
- 格 3／4：模板占位符全在工具 `fmt` 表内、段标记 1/1/1、FROZEN 段 `COLUMN-FLOOR`×2／`COLUMN-CORPUS`×1／`ARM-LOG-SHA`×5、`^# RE-FROZEN ` 1 ∧ BANNER 段 0；基线件残留占位符 0；冻后 `gen=#70`、`# RE-FROZEN #70`=1、备份 `B.pre-freeze.#70.bak=c7cdcbb50e3f19a7`。
- **步数账（纪律 46）**：**首行 `DECL` = 42 == 现取 `grep -c '^run_step "'` = 42** ∧ 口径句逐字命中；`DECL` **行数 = 38 ≠ 步数** ⇒ **没写那条假断言**。
- **位移**：九位只有 `pf` 变（环成员）；`hbtextline 921ba9c65e9fb3be` **一字节未动**；`BRIDGE_SRC_FP=d697b1e10ff48881` 未变；`inputs_fp=0e8254f8cf842836396a8dcdc7568bfaad59fdbaaf0ee358f682d5e3cda7edd2`（与 `[42]` 自印的 `would_be_fp` **逐位相同** = 交叉证）。
- 应用门禁 ×2：`WPTD_SUMMARY=PASS tiers_passed=2/2`／`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`／判词行 `GATE_LINES_IDENTICAL=yes`／各 6 行 `BASELINE … result=PASS`。⚠️ `ROWS_IDENTICAL=no` = **纯头标差异**（`date/loadavg/mem_available/run_dir`）—— 6 条数据行去掉 `rundir=` 标签后**逐字节相同**（`D-G138` 形态，**不是漂移**）。

## §4 边界（如实划界 · `NOINFO`）

1. 本步判「**清单/指纹有牙**」（清单形状合法 ∧ 件数与声明相符 ∧ 名字都真存在 ∧ `stderr` 空）。它**不**判「清单**内容正确**」—— 判不了"该收的没收"（覆盖面缺项）。
2. `--expect` 是**手写常数**：能抓"漏改"（方向安全），**抓不到**"覆盖面与常数被同趟改成同一个错值"。
3. 名字表经 `sha256sum` shim 收集：将来若把哈希工具**改名**，shim 收不到 ⇒ 名字表变短 ⇒ 红（方向安全，但**原因会被误读**）。
4. 牙的 `MANIFEST-SHAPE` 在生产路径下**很难被触发**（`xargs sha256sum` 对存在的件只吐合法形状行）—— 今天真正的活齿是**件数牙**与**存在性/`stderr`**。
5. 本步**不**判 `[12]` 原有产物族判据是否完备（`#29` 的射程）；两族在 `run_check()` 里**产物族先判**，`reason=` 不混。
6. 应用门禁的 `ROWS_IDENTICAL=no` 只在**头标**上（见 §3），不构成"两趟读数相同"的结论。

## §5 自伤（如实留档，三处均被自己的不变量/门禁当场抓住）

① **拼接漏 `\n`**：给 `[12]` 步插说明注释时 `NOTE12 + anchor` 少了分隔符 ⇒ **把接线的 `run_step "FP-INPUTS-HYGIENE" …` 行吞进了注释**；**步数不变量当场抓住**（`grep -c '^run_step "'` 42 → 41）⇒ 补 `\n` 修复。教训：拼接类操作必须**断言分隔符**，不只断言命中数（`D-G120` 同族）。
② **双引号里的反引号**：新判词的词句里写了反引号 ⇒ bash 真做命令替换、诊断被吃掉（现场 `D-G120: 未找到命令`）。**与 `#69` 被 `[21] QUOTE-TRAP` 抓到的形态同族**；本波自查修掉（`traps=0 files=177`），未等门禁来抓。
③ **冻结守卫里两条恒红判据**：要求 `verify-all` 根本不回显的驱动行、以及模板里天然 0 命中的 `'RE-FROZEN #'` 字面量 ⇒ `STOP`（**未写 `DONE`、未动盘**），就地更正后 `FREEZE_RC=0`。

**机读行**：
`W168A: state=DONE wave=#70 steps=42 gen=#70 sha16=83f6f475c9395e72 evidence=~/w168a/w70/logs/{chain-all-20260925-184827.log,polarity-70.log,w70-pre-20260925-184827.log,w70-post.out,w70-push.out}`
