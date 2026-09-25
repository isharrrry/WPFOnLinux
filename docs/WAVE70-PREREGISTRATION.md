# 波 `#70` 预登记 —— 「清单/指纹**要有牙**」（`TASK-0724` ＋ `TASK-0728`）

> **判据先写**：判据在**任何落仓动作之前**写定（`CRITERIA_FIRST=yes`；车道 **W168A**，2026-09-25）。
> 权威树 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**非 git 仓**）。
> 波名：`#70`｜owner：**W168A**（独立拥有本波落仓与收尾链）｜上一代：`#69`（基线 `c7cdcbb50e3f19a7`）。
> 落仓前**现取**基点：`verify-all.sh cc675e85d1b42c62`（**41 步**，首行 `DECL 41 gen=#69`）｜
> `build/close-wave.sh 3b891df8317b1f7c`｜覆盖面 **171**（`FPHYG_COVERAGE_N=171`）｜
> `inputs_fp 9ccc8f33404c0ee7ebcf2353a042498197a40505b5be87f621499c822ec6d4be`｜`gen=#69`。

## §1 本波做什么（范围画死）

两件都属「**判据在册、却没有牙床／没有牙**」：

| # | 任务 | 病（现场） | 本波修法 |
|---|---|---|---|
| 1 | `TASK-0724` | `build/MilBridge/tools/fp-manifest-teeth-check.sh`（`#65` 落仓、`be19edddf7f02797`）**在 `fp_inputs()` 覆盖面里，却没有任何一步调用它** ⇒ 正常运行恒 `FP_MANIFEST_TEETH=NOINFO reason=no-manifest`、`rc=2` ⇒ **清单算错也不会响** | **新步 `[42] FP-MANIFEST-TEETH`** ＋ 驱动件 `build/MilBridge/tools/fp-manifest-step.sh`（**同码路径拦截**现取清单） |
| 2 | `TASK-0728` | 波 `#67`：`fp_inputs()` 白名单加的两行**指向不存在的件** ⇒ `xargs sha256sum` 把"没有那个文件"打到 **`stderr`**，`stdout` 仍是部分结果，而管道 rc 取自**最后一段** `cut` ⇒ **恒 0** ⇒ `inputs_fp` **形状完好（64 hex）而覆盖面是缺的** | **折叠进既有第 `[12]` 步** `FP-INPUTS-HYGIENE`（**不另开步**） |

| # | 落点 | 动作／sha16 |
|---|---|---|
| 1 | `build/MilBridge/tools/fp-manifest-step.sh` | **新建** `db4a2d9856534aba`（159 行级、纯读） |
| 2 | `build/MilBridge/tools/fp-inputs-hygiene-check.sh` | **改** `68ef01bfb9c6a8ee` → `5b0b0f4898865e04`（折叠 `0728`；`--selftest` 由 **16 例**加到 **18 例**） |
| 3 | `verify-all.sh` | **改** `cc675e85d1b42c62` → 落仓后现取（**41 → 42 步**） |
| 4 | `build/close-wave.sh` | **改** `3b891df8317b1f7c` → 落仓后现取（覆盖面白名单 **+1 行**） |
| 5 | `docs/WAVE70-PREREGISTRATION.md` | 本文件（新建） |

**步数**：首行 `DECL` 声明的步数 **41 → 42（+1）**；唯一新步＝第 `[42]` 步 `FP-MANIFEST-TEETH`。
**覆盖面**：`fp_inputs()` 显式清单 **+1 行**（落点 1；`docs/**` 与 `verify-all.sh` 都**不在**覆盖面）
⇒ `coverage_n` **171 → 172**；`inputs_fp` **必变**（成因两处：① 白名单 `+1` 行 ② `close-wave.sh`
与 `fp-inputs-hygiene-check.sh` 都是覆盖面成员、本波被改）。
**不碰**：任何产品件（`build/PresentationCore.Linux/**`／`build/PresentationFramework.Linux/**`／
`src/WpfGfx.Linux.Native/**`／`build/shims/**`）｜`build/MilBridge/known-red.json`｜
主控五件（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md`／
`docs/FORK-AND-PUSH.md`／`build/MilBridge/tools/defect-registry-declared.tsv`）｜
`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（**只由冻结器写**）。

### §1.1 `TASK-0728` **以折叠实现、参考件不落仓**（逐字、理由）

预备车道留下的参考件 `~/w164a/w70/fp-inputs-existence-check.sh`（`906153a9db4f9164`，实测**未截断**，
两极性 5 腿自测在位）**已被取代、不落仓**。三条理由（**主控已复核批准**）：

1. **`[12]` 的 `capture()` 已经握有权威成员表**：它用 `PATH` 前置的同名 `sha256sum` shim 收 `argv`，
   并由守卫②用 `cmp` **机器证过完备**（"拦截到的集合 == 真正被哈希的 argv 集合"）—— 那是**唯一**
   "真正被哈希的东西"的清单，比参考件"重跑一遍 `fp_inputs()` 再读 `stdout`"**更强**。
2. **原样落会重复"抽覆盖面"逻辑**：本仓明令「**同一份逻辑存在两处必然分叉**」（`#28` 的教训原文）。
   ⇒ **一份提取、两族判据**。
3. 参考件自带**两条继承缺陷**：① 车道名环境变量 `W164A_R`（`D-G137`：从车道沙箱提升为仓内件的工具，
   默认路径只许**仓内或调用者可覆盖**）；② 临时件落**共享 `/tmp` 固定名**（`fp-exist-body-$$.sh`）而
   不是自建 `mktemp -d`（纪律 43／44、纪律 63）。

⚠️ **本波对这两条缺陷做了自检**（读数见报告 §3）：落仓件 `fp-manifest-step.sh` 现取
`grep -c "$HOME/w"` = **0**；临时件一律 `mktemp -d`（优先 `TMPDIR`，无 `TMPDIR` 时落
`$HOME/.cache/wpf-linux/tmp`，**刻意不落共享 `/tmp`**）＋ `trap` 回收。

## §2 判据（落地前写死；读数之后再改即事故）

### 2.0 本波**不做**回归判定（**机读行**；纪律 45）

```
PREREG-NO-REGRESSION-DECISION: yes
```

**本波不做任何回归判定** —— 本波全部判据都是**确定性量**（件数、`rc`、清单逐行形状、`stderr` 字节数、
`grep -c` 计数、sha16），**没有任何"两臂对照 ⇒ 比出一个率"的设计**。因此"回归判定四要件"对本波
**逐条 `N/A`**（**不是"已满足"，是"不适用"**）。全文**没有**引用任何判定工件（既没有判定工件那道
机读行，也没有那份判定台账文件名）⇒ 没有"跑过判定"的证据。

### 2.1 输入来源（纪律 36：**判据的输入必须声明**）

| 输入 | 来源（现取） |
|---|---|
| 覆盖面成员表（**权威**） | `close-wave.sh` 的 `fp_inputs()` 函数体 —— **同码路径**抽出（内容锚 `sed -n '/^fp_inputs()/,/^}/p'`，**不写行号**）后**原样执行**，用 `PATH` 前置同名 `sha256sum` shim 收 `argv` |
| 清单（manifest） | 成员表经**生产同形**命令 `LC_ALL=C xargs sha256sum` 产出；`stderr` **单独收**（非空 ⇒ `FAIL`） |
| 期望件数 `--expect N` | **`verify-all.sh` 步本体里的显式常数**（`N=172`；`verify-all.sh` **不在**覆盖面 ⇒ 与生产路径**无关**，是牙头推荐的唯一来源） |
| 判词 | `build/MilBridge/tools/fp-manifest-teeth-check.sh`（`be19edddf7f02797`）＋ `build/MilBridge/tools/fp-inputs-hygiene-check.sh`（落仓后 `5b0b0f4898865e04`） |
| 世代 | `docs/CURRENT-STATE.md` 第 9 行的 `BASELINE-FROZEN gen=#NN`（**主控派单字符串**；禁自行推断） |

### 2.2 全波判据（`J1`–`J8`；三态，**`NOINFO` 不算绿**）

- **`J1`（`0724` 正极）**：正常树 ⇒ 第 `[42]` 步 `rc=0` ∧ `FP_MANIFEST_TEETH=PASS` ∧
  `files_n == --expect` ∧ `shape_bad=0` ∧ 驱动 `sha256sum_stderr_bytes=0` ∧ 牙自测
  `SELFTEST=PASS total=13 pass=13 fail=0`。
- **`J2`（`0724` 反极 A，**只换被判件**）**：`close-wave.sh` 副本在**续行参数表中间**插一行 `#` 注释
  （`D-G120` 真咬形态）⇒ 必 `rc=1` ∧ `files_n < --expect` ∧ 驱动当场印出**形状完好的假指纹**。
- **`J3`（`0724` 反极 B，**只换声明常数**）**：`--expect` 改成 `现取件数+1` ⇒ 必 `rc=1` ∧
  `FAIL reason=files-n-mismatch`。
- **`J4`（`0724` 反极 C）**：缺／取不到清单 ⇒ 必 `rc=2`（`NOINFO`）**且不许出 `PASS`**。
- **`J5`（`0728` 正极）**：`FP_INPUTS_HYGIENE=PASS reason=clean … missing_n=0 stderr_bytes=0`、`rc=0`。
- **`J6`（`0728` 反极，**沙箱副本**，绝不改真树白名单）**：某行指向**不存在的件** ⇒ 必 `rc=1` ∧
  **逐条点名该行**（`kind=MISSING`）∧ 当场印出**旧口径的假指纹** `would_be_fp=`。
- **`J7`（步数账，纪律 46 的**唯一不变量**）**：**首行 `DECL` 声明的步数 == 现取
  `grep -c '^run_step "'` 数**（`42 == 42`）∧ `VERIFYALL_SELF=PASS names=42 decl=42 gen=#70
  dup=0 order=OK prose=OK`。⚠️ **禁止**把「`DECL` 行数 == `run_step` 数」写成断言
  （落仓后现读 `DECL` 行数 **38** vs 步数 **42**）。
- **`J8`（覆盖面与指纹，成对归因）**：`FPHYG_COVERAGE_N == 172`（**逐件归因**：唯一新件
  `build/MilBridge/tools/fp-manifest-step.sh`）∧ `inputs_fp` 必变。

**判否条件**：任一 `J*` 不成立 ⇒ 本波停手、按实报主控（**不许**改判据凑绿）。

## §3 两极化（**先写判据再跑；正极必现／反极必不现**）

| 腿 | 只有一个变量 | 期望 |
|---|---|---|
| `0724` 正极 | 正常 `close-wave.sh` | `rc=0`／`PASS` |
| `0724` 反极 A | **只换被判件**（毒化副本） | `rc=1`／`files-n-mismatch` |
| `0724` 反极 B | **只换声明常数** | `rc=1`／`files-n-mismatch delta=-1` |
| `0724` 反极 C | 清单取不到 | `rc=2`／`NOINFO` |
| `0728` 正极 | 正常白名单 | `rc=0`／`missing_n=0 stderr_bytes=0` |
| `0728` 反极 | **只换被判件**（沙箱副本，一行指向不存在件） | `rc=1`／点名 ＋ `would_be_fp=` |
| `0728` 成对回绿 | **只把那一行去掉** | `rc=0` |

## §4 边界（**逐条 `NOINFO`／不覆盖**，如实划界）

1. 本步判「**清单/指纹有牙**」：清单形状合法 ∧ 件数与声明相符 ∧ 名字都真存在 ∧ `sha256sum` `stderr` 空。
   它**不**判「清单**内容正确**」—— 判不了"该收的没收"（覆盖面缺项）。
2. `--expect` 是**手写常数**：能抓"漏改"（`files-n-mismatch`，方向安全），**抓不到**"覆盖面与常数被
   同一个人同趟改成同一个错值"。
3. 成员表经 `sha256sum` shim 收集：若将来 `fp_inputs()` 改用**不叫 `sha256sum` 的**哈希工具，shim 收不到
   ⇒ 名字表变短 ⇒ `files-n-mismatch` **红**（方向安全，但**原因会被误读**）。
4. 牙的 `MANIFEST-SHAPE` 在生产路径下**很难被触发**（`xargs sha256sum` 对存在的件只吐合法形状行）——
   它是给"将来有人改掉清单生产者"留的齿；今天真正的活齿是**件数牙**（`J3`）与**存在性/stderr**（`J6`）。
5. 本步**不**判 `[12]` 原有的产物族判据是否完备（那是 `#29` 的射程）；两族在 `run_check()` 里
   **产物族先判**，`reason=` 不混。
6. 本波**零产品改动** ⇒ 九位里预计**只有环成员**变（若非如此 ⇒ **停手报主控**）。
