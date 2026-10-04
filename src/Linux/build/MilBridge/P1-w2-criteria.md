# P1-W2 装置牙批甲 判据（**先写，后取读数**）—— `scribe` / `t14`

`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜基点 `HEAD=39f23d0`｜入口读数现取于本件之前（见 §3）
依据件 ＝ `build/MilBridge/P1-tail-scout.md`（`493808af2699c40a`）的 **W2 行** ＋ `### B-3 ·`／`### B-4 ·`／`### B-7 ·`／`### B-8 ·`／`### B-9 ·`（**已现取读过原文**）

## 0 写域
**改**：`inScope` 那 14 件（9 `.cs` ＋ `pkg-src-retiredpath-check.sh`／`retired-path-provenance.tsv`／`pts-pages-guard.sh`／`session_inner.sh`／`repo-alias-allow.tsv`）。
**新建**：`build/MilBridge/P1-w2-criteria.md`／`build/MilBridge/P1-w2-report.md`。其余一件不改；不 commit／push。

## 1 波内顺序（**硬约束**）
**先 B-3（9 件 `.cs`）→ 后 B-4（扩 `tree` 面扫 `*.cs`）**。理由：先扩域则 9 件死根当场判红（正确的红），会把两件事搅成一波返工。⇒ 报告里**必须**给两件的先后与各自现取读数。

## 2 逐条判据（先写死）
| 条 | 判什么 | 成立（绿） | 不成立／`NOINFO` |
|---|---|---|---|
| **B-3** | ① 九件 `.cs` 的退役路径字面量**归零**；② 缺根时**响亮失败**（非静默）；③ `CoverageProbe` 死根面判到底 | ① `git ls-files '*.cs' \| xargs grep -l 'wpf-linux-20260906' \| wc -l` ＝ **0**；② 每处替换为 **env 注入 ＋ 缺则 `throw`**（不静默）；③ 三支臂真跑并断言日志含目标路径签名 | ③ 若槽被占 ⇒ **`NOINFO(reason=槽被占，腿未跑)`**，**不许**当绿、**不许**改判据绕开 |
| **B-4** | `tree` 面是否真扫 `*.cs` | 正极 `RETIREDPATH=PASS mode=tree … code=0` ∧ **`files=` 变大**（域真变了，不是只改打印）；反极＝塞回一处 ⇒ **`FAIL` 并点名 `file`＋`line`** | 只改打印而 `files=` 不变 ⇒ 不成立 |
| **B-7** | 白名单那行（上限 `6417` 对着 **0 件**的树）的处置 | **保留 ＋ 写明它今天就该是 0 件**（不删那行 ⇒ 不把豁免降级为"关牙"）；两极化两腿**都真跑** | 只用"反正 0 件"跳过反极 ⇒ 不成立 |
| **B-8** | ① 「零证据力」句搬进**判据件自身**；② 件头 G10 具名 ＝ 现取前沿 | ① `grep -c '零证据力' pts-pages-guard.sh` ≥ 1；② 件头 G10 名**逐字等于**现取前沿（`LoCreateContext`）；③ 反极＝把前沿日志副本改回旧名 ⇒ ②那条牙**必红并点名** | 行号／名号不现取 ⇒ 不成立 |
| **B-9** | `session_inner.sh` 的默认显示号占用断言 | 新增占用探测：**号空闲 ⇒ 起（打自证行）**；**号被占 ⇒ `rc≠0` ＋ 具名拒跑**（不静默复用）；两腿都真跑 | 真 `:237` 占用腿需显示位＋槽 ⇒ 槽被占时 **`NOINFO(reason=槽被占)`**，改用**沙箱 `X11` 目录注入**做两腿 |

## 3 入口读数（现取，早于任何写）
`inputs_fp = abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`｜覆盖面 `226`｜`grep -c '^run_step "'` ＝ `55`｜`flock -n ~/heavy.lock` ⇒ **`SLOT=HELD`**（`t7` 在飞）⇒ 重活腿先按 §4 处理。

## 4 槽争用口径（**不许当读数、不许绕**）
重活腿（`CoverageProbe` 三支臂、B-9 真显示号占用腿）**走 `~/heavy-slot.sh` ＋ 后台**并报 PID／日志路径；若槽被长占 ⇒ 用**有限等待**换一个确定读数（`HEAVYSLOT=TIMEOUT`），并**逐条具名 `NOINFO`**。

## 5 覆盖面位移归因
凡改到 `fp_inputs()` 覆盖面内的件（`pts-pages-guard.sh`／`session_inner.sh`／`repo-alias-allow.tsv`／`pkg-src-retiredpath-check.sh`／`retired-path-provenance.tsv`／9 件 `.cs`）⇒ **入口／出口各取 `inputs_fp` ＋ 覆盖面件数**，**逐件归因**；零位移也要印两个值。件数不变 ⇒ `[42] --expect 226` 不动（**不得**改 `verify-all.sh`）。

## 6 `NOINFO` 条件（具名）
1. 槽被长占 ⇒ `CoverageProbe` 三支臂 / B-9 真显示位腿 = `NOINFO(reason=heavy-slot 被占，腿未跑)`；
2. `CoverageProbe` 三支臂的「目标路径签名」若在现有日志里找不到 ⇒ 该面判「未测」，`NOINFO`（不许当绿）；
3. `pts-pages-guard` 的 G10 自检若无法从日志取到前沿名 ⇒ `NOINFO`（不许改判据绕开）。

## 7 越域与收尾
`git status --porcelain` 逐行点名（`t7` 的 `P1-task0201-criteria.md` 与它的脏件**不计入**本席）；两牙 `DEFREG`／`REPORTID` 不退化且位移逐件归因；报告 `P1-w2-report.md` 给五条各自「改前原文／现取读数 ＋ 改后逐字」＋ 两极化原始机读行 ＋ 自报 sha16 ＋ 读取时刻。
