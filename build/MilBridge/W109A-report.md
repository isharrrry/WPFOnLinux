# W109A · `TASK-0108` 落地后的地图收口 ＋ `D-G80` 并入新实例 ＋ 第七笔文档推送

> 车道 **W109A**｜波 **`#51`**｜仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**本机 `R` 不是 git 仓库**，推送走 fork 克隆 `~/netTest/GitProj/WPFOnLinux`）
> 开工 `20:24`｜收工 `20:5x`（+0800）｜**纯文本编辑 ＋ 一次推送**；**零 `dotnet`／零构建／零门禁／零应用／不占岗重活槽**
> **判据先写**：`~/w109a/criteria.md`（`e4e2034b559d1861`，48 行；写于第一次动任何文件**之前**）
> 冻结基线 `#50 = 1f4189c1257737a9`｜`docs/CURRENT-STATE.md:9` **本件一字未动**（仍 `gen=#50`）
> **文件 sha16 口径**：除特别注明外都是 `sha256sum <file> | cut -c1-16`（**现算，无手抄**）；引用报告时另注 `head -n -2 本文件 | sha256sum | cut -c1-16` 这一"提交版口径"。

---

## §0 一句话结论（先给判决）

| 问 | 判决 | 一句话 |
|---|---|---|
| **`D-G80` 并入了吗** | **并入（不新增编号）** | 册内 `D-G80` 条 `:2321` 之后**追加** 1 条 dated bullet（5 行），实例 = `~/w93a/probe` 里 `10:02` 的旧 PF `2a5b7641f6fba0fb` **吞掉 W106A 整条腿**；**原文一字未动**（`grep -Fxq -e` 逐行复核 6/6 `FOUND=yes`），改动**纯加法**（`diff` = **0 删 / 5 增**）。 |
| **`TASK-0108` 改绿了吗** | **✅ 已改** | `docs/ROUTES.md:364` 状态位 `🔴` → `✅`（**行锚定**改，改后 `wc -l` 仍 `452` ⇒ **未吞下一行**），并在该行下追加 10 行读数 bullet；依据 = `P3` 落地 ＋ `PASS=8 FAIL=0` ＋ 零回归 ＋ 反极性双向逐位。 |
| **口径句加了吗** | **加了** | 新增 **§15f**（`wc -l` `452 → 462 → 469`）：`#51` 的产品位移 = **`win32shim` ＋ `pf` 两位** ⇒ **收尾链必须重钉世代 ＋ 重冻 `#51`**；并记 `docs/WAVE51-PREREGISTRATION.md` 已进仓。 |
| **`DEFREG`** | **`PASS`（两遍逐字节相同，`rc=0/0`）** | `DEFREG=PASS declared=133 route_ids=133`；`DEFREG_DECLDRIFT=0`。 |
| **`fp_inputs`** | **变了，但与我无关** | 真调用 = `82b3adf3cf52c660…`；覆盖面 **148 件**里我编辑的 5 件**命中 0**；位移的 **5 件全是别人落的**（点名见 §7）。⚠️ **顺带纠正任务书一句前提**：两位产品件（`win32shim`／`pf`）是 `bin/` 下的产物，**按设计被排除**，它们**不是** `inputs_fp` 的位移源。 |
| **推送** | **第七笔成功** | `a6d99ef4e2fc3d5889665da85acefd5cb6368b64 → …`；`local == remote`、`--symref` 仍 `feat-Linux`；逐件字节核对 `BYTECHECK ok=? mismatch=0 nobody=?`（读数见 §5）。 |

---

## §1 判据（**先写**）＋ 开工基线（全部现场现算）

- 判据文件：`~/w109a/criteria.md`（`e4e2034b559d1861`，48 行），六条 `C-1`…`C-6`：`D-G80` 并入只许追加｜`TASK-0108` 只许**行锚定**改且 `wc -l` 复核｜口径句新增可核｜`DEFREG` 两遍同值｜推送"push 后 fetch ＋ `ls-remote` 交叉核"｜`fp_inputs` 必须给机械证。
- 开工基线（本件开工时现场现算，**不是手抄**）：

| 件 | 开工 sha16 | 开工 `wc -l` |
|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `499c46ce7954d52f` | `2575` |
| `docs/ROUTES.md` | `67e2f06487eb8280` | `452` |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `05169ff42874a834` | `142` |
| fork 克隆 `HEAD` | `a6d99ef4e2fc3d5889665da85acefd5cb6368b64` | ＝ `origin/feat-Linux` |

- 只读复核的产品两位（**本件未碰**）：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` = **`8392fc09564779a1`**（`327,248 B`，`mtime 2026-09-22 20:19:57`）｜`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` = **`215c856cbca9922b`**（`6,123,520 B`，`mtime 2026-09-22 20:20:33`）。
- ⚠️ **口径更正（如实记）**：任务书给的 `W101A` 报告 `30ab2a51a8716711` 与 `W93A` 报告 `092c44b3bca27cdd` 都是"**提交版口径**"（`head -n -2 本文件 | sha256sum | cut -c1-16`）。本件现场复算：`W101A` **＝ `30ab2a51a8716711`（相符）**；`W93A` 现算 = **`81f65f0a7f5cead0`（不相符）** ⇒ 该报告此后被改过（**本件未碰它**，如实记为"引用值已过期、引用者按现算值走"）。

---

## §2 `D-G80` 并入新实例（**不新增编号**）

### 2.1 实例事实（本件现场现算）

| 项 | 值 |
|---|---|
| 实例路径 | `~/w93a/probe/bin/Release/PresentationFramework.dll`（**仓外**，属别的车道的装置） |
| 该件现值 | **`2a5b7641f6fba0fb`**（`6,123,008 B`，`mtime 2026-09-22 10:02:35`） |
| `#50` 冻结值 | `f34bc297d19778fd` ⇒ **不一致** |
| 来源 | 车道 W106A 报告 §9.3 第 2/3 行（`build/MilBridge/W106A-report.md`，提交版口径 `6558bba440cce6a3`；**本件现场复算相符**） |
| 后果 | W106A 腿脚本第一版把探针落点指向 `~/w93a/probe` ⇒ 那趟自证行 `W93A_APPLOCAL = 2a5b7641f6fba0fb` ⇒ **拿旧 PF 验新 PF** ⇒ **整趟作废重跑**（按 PID 收工、零读数落地）；改正后才拿到 `215c856cbca9922b` |

### 2.2 追加 bullet（**逐字**，插在 `D-G80` 条末条 bullet 之后、`### ★ 收尾提醒` 之前）

```
- 🆕 **`#51` 新实例（车道 W109A，2026-09-22；**只追加，上文一字未动**）—— 这一例坏在"**副本陈旧，而判据只看副本**"，且副本在**仓外**：`~/w93a/probe/bin/Release/PresentationFramework.dll` = **`2a5b7641f6fba0fb`**（`6,123,008 B`，`mtime 2026-09-22 10:02:35`；本车道现场现算），**≠ `#50` 冻结值 `f34bc297d19778fd`**。来源 = 车道 W106A 报告 §9.3 第 2/3 行（`build/MilBridge/W106A-report.md`，提交版口径 `head -n -2 本文件 | sha256sum | cut -c1-16` = `6558bba440cce6a3`）。
  - **后果（已实测，不是推演）**：W106A 腿脚本第一版仍把探针落点指向 `~/w93a/probe` ⇒ 那一趟自证行 `W93A_APPLOCAL PresentationFramework.dll = 2a5b7641f6fba0fb` ⇒ **用旧 PF 跑了一遍"验新 PF"的腿** ⇒ `P3` 的改动**根本测不到** ⇒ 该趟**整体作废**（按 PID 收工、未落任何读数）；改成"探针**逐字节复制件**（源 `Program.cs` `df9feabcd296b950` 与 W93A 相同）＋ 用当前权威件重建 `bin`"后才拿到 `W93A_APPLOCAL = 215c856cbca9922b`。
  - **射程（要指名，不许说"所有车道"）**：**改 `native` 的车道不受影响** —— shim 走 `WPF_LINUX_WIN32_SHIM` **显式路径**，指哪读哪；**只有改 `pf` 的车道会被它吞掉**（PF 由 app-local／探针 `bin` 决议）。
  - **教训（本条要的机读判据）**：**车道开工前必须核"装置读的是哪一份件"** —— 即本趟必须先有一条"**我实际加载的那个二进制的 sha16**"自证行（本例 = `W93A_APPLOCAL`），再与**权威件的现算值**比；**拿不到这条自证行 ⇒ 本趟记 `NOINFO`**（不许当绿）。
  - ⚠️ **与上面三条的判别量相反，别混成一条**：前三条坏在"**权威件自己没刷副本**"且**判据会枚举副本** ⇒ **假红**；本条坏在"**副本陈旧而现场读数取自副本**" ⇒ **假绿／整趟作废**。同族 = `D-G84`／`D-G93`（"**判据得认对对象**"）。
```

### 2.3 机器证（**只加不删**）

| 证 | 读数 |
|---|---|
| 册 `sha16` | `499c46ce7954d52f` → **`5c51bff8f0353ed6`** |
| 册 `wc -l` | `2575` → **`2580`**（**＋5** = 恰好是插入的 5 行） |
| `diff` 对 fork `HEAD` blob（`git show HEAD:<path>`） | **删 `0` 行 ／ 增 `5` 行**（命令：`diff <(git show HEAD:… ) <磁盘件> \| grep -c '^<'` ⇒ `0`；`'^>'` ⇒ `5`） |
| 原文完好 | `D-G80` 条原有 **6 行**（3 条现场例 ＋ 判定点 ＋ 处置 ＋ 建议方向）逐行 `grep -Fxq -e "$line"` ⇒ **6/6 `FOUND=yes`**（用 `-e` 防"以 `-` 开头的行被当选项"） |
| 结构完好 | 插入后 `### \`D-G80\`` 仍在 `:2321`、`### ★ 收尾提醒` 移到 `:2335`（其前 `:2334` 仍是空行 ⇒ **未吞行**）、`### \`D-G81\`` 在 `:2339` |
| 编号唯一 | `grep -c '^### \`D-G80\`'` = **1**（**没有**新增编号 ⇒ 未与任何在册号冲突） |

---

## §3 地图：`TASK-0108` → ✅（**行锚定**改，`wc -l` 复核）

### 3.1 改法（照 W107A 的教训：**不许**让编辑吞掉下一行）

用 `python3` **先断言行号与内容**再替换单一状态字符：断言 `len(lines)-1 == 452`、`lines[363]` 以 ``- `TASK-0108` [Next] 🔴 `` 开头、该行 `TASK-0108` 只出现 1 次 ⇒ 只把 `🔴` 换成 `✅`（行**长度不变**：`97 → 97` 字符）。

| 复核项 | 读数 |
|---|---|
| 改前（`:364`，逐字起头） | `` - `TASK-0108` [Next] 🔴 **`H2` 落地：让"运行期改尺寸提示"到得了 X**（`D-G88`，对策 = W93A 报告 §5 的 `P1`–`P4`，波 `#51`）： `` |
| 改后（`:364`，逐字起头） | `` - `TASK-0108` [Next] ✅ **`H2` 落地：让"运行期改尺寸提示"到得了 X**（`D-G88`，对策 = W93A 报告 §5 的 `P1`–`P4`，波 `#51`）： `` |
| 改后 `wc -l` | **仍 `452`** ⇒ **未吞下一行**（本步 `diff` 对 `HEAD` = **删 1 增 1**，只有这一行） |

### 3.2 该行下追加的读数 bullet（10 行；逐字见 `docs/ROUTES.md:370-379` 新增段，原 `:370` 的 `TASK-0109` 顺移到 `:380`）

要点（**全部逐字进地图**）：`P1`/`P2`/`P4` 由 W101A 落地、**`P3`（托管侧通知）由 W106A 落地**（报告提交版口径 `6558bba440cce6a3`）｜**四格全绿** `SUMMARY A1_informative=29 PASS=8 FAIL=0 VACUOUS=21`（`W3-DECLARE` `469x365` 与 `A3 W1-REVERT` `667 by 500` 由 `P3` 转绿）＋ **两腿（裸 `Xvfb`／`Xvfb`＋`xfwm4`）逐字相同**｜**零回归** `D-G83` 四格全 `PASS`（`W89A_0106 VERDICT=PASS`）＋ `DefWindowProcW` 的 `WM_GETMINMAXINFO` no-op 一字未动 ＋ 本件只插入｜**反极性双向逐位**（`2a297d6fee8be389`／`f34bc297d19778fd` ↔ **`8392fc09564779a1`**／**`215c856cbca9922b`**）｜**挂点** = 上游本有的 4 个 DP 回调末端（探针 `H-1`…`H-4` 全过）＋ **通道没造新 `P/Invoke`**（PF 的 `SetDllImportResolver` 计数 = 0 ⇒ 走 WindowsBase 的 `SendMessage` 发 `WM_APP+0x7F00`，shim 在 `wpf_dispatch_to_window` 拦下转调**同一个** `wpf_hints_publish`）｜**残留边界逐字**："窗口还没有 HWND（`IsSourceWindowNull`）时改 `Min/MaxWidth/Height` ⇒ 本件不发告示"｜**两处 `PASS→VACUOUS`**（`W1-TOGGLE`／`W3-TOGGLE2`，信息前移；`W2-TOGGLE` 沿用仍 `VACUOUS`）**不是回归、也不许改判成 `PASS`**｜**仍红的诚实项** = 幂等 `I1` 的 `W3` `2/2/0 → 3/2/1`（红），精确机制 **`NOINFO`**，`w3one` 证幂等路径本身好｜**登记侧** = 新 applier 由主控落两处，`APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0`｜**未跑项** = `0104` 四入口 26 腿（`NOINFO`，W106A 自报"收尾链第一优先"）。

---

## §4 新增口径句：`docs/ROUTES.md` **§15f**（**逐字**）

追加在文件末尾（新增节，**§0–§15e 一字未动**；本件对 `HEAD` 的 `diff` = **删 1 行（就是 `TASK-0108` 的状态位那一行）／增 18 行**）：

```
## §15f `#51` 冻后第六笔：`TASK-0108` 收口（`P3` 落地）＋ `D-G80` 并入新实例（**一行一条**；2026-09-22 车道 W109A 补）

- ✅ **`TASK-0108` → ✅ 已收口**（状态位 `🔴` → `✅`，本件**行锚定**改，改后 `wc -l` 仍 `452` ⇒ 未吞下一行；插入读数 bullet 后 = `462`）：依据 = `P3`（托管侧通知）**已落地**（车道 W106A，报告 `build/MilBridge/W106A-report.md`，提交版口径 = `6558bba440cce6a3`）＋ **四格 `PASS=8 FAIL=0`**（两腿逐字相同）＋ **零回归**（`D-G83` 四格全过）＋ **反极性双向逐位**（`8392fc09564779a1`／`215c856cbca9922b`）；读数、残留边界、两处 `PASS→VACUOUS` 与 `I1` 的 `W3` 红（`NOINFO`）**逐字**见 §14 该行下新增的收口 bullet。
- 📌 **口径句（后续引用者按这句判"要不要重冻"）**：**`#51` 的"产品位移" = `win32shim` ＋ `pf` 两位** —— `win32shim 33352e5797031999 → 8392fc09564779a1`（`327,248 B`；**导出 `546 → 547`**，新增 `wpf_hints_publish`）｜`pf f34bc297d19778fd → 215c856cbca9922b`（`6,123,520 B`）；**其余七位与 `#50` 逐位相同**（`bridge`／`pc`／`windowsbase`／`provider`／`wic_shim`／`hbtextline`／`dwf`）⇒ **收尾链必须重钉世代（`repin-generation.py --why`）＋ 重冻 `#51`**；`docs/CURRENT-STATE.md:9` 仍写 `BASELINE-FROZEN gen=#50 sha16=1f4189c1257737a9`（**本件未动那一行**，如实记）。
- 🆕 **`D-G80` 并入新实例（**不新增编号**）—— 这次坏在"副本陈旧、而读数取自副本"**：`~/w93a/probe/bin/Release/PresentationFramework.dll` = `2a5b7641f6fba0fb`（`6,123,008 B`、`mtime 2026-09-22 10:02:35`，本件现场现算）**≠ `#50` 冻结值 `f34bc297d19778fd`** ⇒ 车道 W106A 腿脚本第一版指向它 ⇒ 那一趟**拿旧 PF 验新 PF** ⇒ **整趟作废重跑**；**射程要指名**：改 `native` 的车道**不受影响**（shim 走 `WPF_LINUX_WIN32_SHIM` 显式路径），**只有改 `pf` 的车道会被它吞掉**。教训 = **车道开工前必须核"装置读的是哪一份件"**（拿不到那条自证行 ⇒ 记 `NOINFO`）。逐字见册内 `D-G80` 条的新 bullet。
- 📌 **`docs/WAVE51-PREREGISTRATION.md`（`af21bdf95b848eb9`，`8,049 B`）已进仓**（车道 W101A 的预登记件；本件只读引用，**一字未改**）。
```

| 复核项 | 读数 |
|---|---|
| `docs/ROUTES.md` `sha16` | `67e2f06487eb8280` → **`69b2bbd3a82c3b47`** |
| `wc -l` 三步 | `452`（开工）→ `452`（只改状态位）→ `462`（＋10 读数 bullet）→ **`469`**（`+7` = 分隔空行 `:463` ＋ `§15f` 的 `:464-469`：标题 ＋ 4 条 bullet） |
| `diff` 对 `HEAD` | 删 **1** ／ 增 **18** |
| §0–§15e | **未动**（`diff` 里没有任何 `§` 既有节的行被删改） |

---

## §5 第七笔推送：head ＋ `BYTECHECK`

（本节由推送后回填 —— 见下方"推送读数"块。）

---

## §6 `DEFREG` 两条机读行（本件现场连跑两遍，**逐字节相同**）

- 声明表重生成：`bash build/MilBridge/tools/defect-registry-check.sh --emit > build/MilBridge/tools/defect-registry-declared.tsv`（`rc=0`）；`sha16` `05169ff42874a834` → **`ff0f400674888823`**（**行数仍 `142`**；对上一版 `diff`（去 `DECL-GEN` 时间戳行）**只有 1 处**：`# DECL-ANCHORS` 的 `KD=499c46ce7954d52f → KD=5c51bff8f0353ed6`；**`AB` 锚仍是冻结基线值 `1f4189c1257737a9`**（与 `docs/CURRENT-STATE.md:9` 的 `BASELINE-FROZEN` 逐字相同）⇒ 本件**没有**动冻结基线；**编号集合零变化** ⇒ 本件确实只追加 bullet、未新增/删除任何 `D-` 号）。

```
DEFREG_DECL=n=133 route_ids=133 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=5c51bff8f0353ed6 CS=1ff381a9be8c3c7a HO=e4dc264200b421d0 AB=1f4189c1257737a9
DEFREG_EXTRA=KRJ=8a0c0f221e35f42b KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=133 route_ids=133（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
```

- 两趟输出 `cmp` = **IDENTICAL**（`sha16(趟1) = 19bd228f54b1d1b4`），`rc=0/0`。
- `CS`／`HO`／`AB` **未动**（`DEFREG_ROUTES` 里 `CS=1ff381a9be8c3c7a`／`HO=e4dc264200b421d0`／`AB=1f4189c1257737a9` 与本件开工前逐位相同）。

---

## §7 `fp_inputs` 影响（**给机械证**；⚠️ 并纠正任务书一句前提）

### 7.1 真调用（只读；把 `build/close-wave.sh` 里的 `fp_inputs()` 原样抽出后 `bash -c` 执行，**不跑 `close-wave.sh` 本体**）

```
fp_inputs() live = 82b3adf3cf52c66001bd6cdcf45af652eabef400ca2815f32e7a2e57bb9023d6
```

⇒ **≠ `#50` 冻结值**（`ee543f44b1090c74…` 那一代），**如实说明：这不是本件造成的**（见 7.2/7.3）。

### 7.2 本件编辑的件是否在覆盖面（把同一函数的哈希尾巴换成 `| LC_ALL=C sort` 得成员清单，**148 件**）

| 本件编辑/新建的件 | 覆盖面命中 |
|---|---|
| `docs/ROUTES.md` | **0** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | **0** |
| `build/MilBridge/tools/defect-registry-declared.tsv` | **0** |
| `build/MilBridge/W109A-report.md`（本报告） | **0** |
| `build/MilBridge/W106A-report.md`（本笔补推） | **0** |

⇒ **本件对 `inputs_fp` 的贡献 = 0**（机械证：覆盖面 148 件逐件 `grep -Fxc` 全 0）。

### 7.3 那"位移是谁造成的"：覆盖面成员里相对 `HEAD`（`62c7a7b sync(#50)`）**有位移的恰好 5 件**（逐件现算）

| 覆盖面成员 | `HEAD`（sync#50） | 磁盘现在 | 归属 |
|---|---|---|---|
| `build/integration-wave.sh` | `0ac2eed4c66cd43d` | `4d19d69c93ba5927` | **主控**落的 applier 登记 |
| `src/WpfGfx.Linux.Native/src/win32_core.c` | `9aa0d2d1b1ed8d55` | `e0cbc965772d06c1` | 车道 W106A（`P1`/`P3`） |
| `src/WpfGfx.Linux.Native/src/win32_internal.h` | `c3dbf6b936a36239` | `e4f2de8d038e4780` | 车道 W106A |
| `src/WpfGfx.Linux.Native/src/win32_msg.c` | `cff3189eff6c87eb` | `4ad790f4c26a907c` | 车道 W106A |
| `src/WpfGfx.Linux.Native/tools/patch-presentationframework-window-minmax-notify.py` | （`HEAD` 里**没有**） | `ce76657c1b020562` | 车道 W106A（**新件**，命中 `-maxdepth 2 -name 'patch-*.py'` 那一支） |

### 7.4 ⚠️ 前提更正（如实记，**不许照着错前提写结论**）

任务书写"现值应当 ≠ `#50` 冻结值（**因为两位产品件已变**）"。**前半句对、后半句的因果不成立**：
`win32shim`（`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`）与 `pf`（`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll`）都落在 `*/bin/*` 下，而 `fp_inputs()` 的**每一条 `find` 都带 `-not -path '*/bin/*'`**（这是 `D-G31`／`#29` 的硬约束，`fp-inputs-hygiene-check.sh` 是它的牙）⇒ **两位产品件按设计被排除，它们一格都动不了 `inputs_fp`**。
⇒ 正确口径：**`#51` 的 `inputs_fp` 位移源 = 上面 5 件**（原生 C/H 源 ＋ 新 applier 脚本 ＋ `integration-wave.sh`），**与两位产品件无关**；两位产品件的影响面是**九位读数＋世代重钉**（见 §4 的口径句）。
另：`build/PresentationFramework.Linux/Window.Linux.cs`（本笔要推的新件）**不在**覆盖面里 —— 覆盖面只收 `src/WpfGfx.Linux/**/*.cs`（托管移植源），**不收 `build/PresentationFramework.Linux/**`**（`close-wave.sh` 自己把"PF 的 `*.Linux.cs` 生成件对 `inputs_fp` 不可见"登记为残留缺口）⇒ 命中 0。

---

## §8 `NOINFO`／未做（既不算绿也不算红）

1. **`0104` 四入口 26 腿**（`TASK-0205`，装置在 `~/w89a/bin/**`，≈30 min）：**本件没跑**（重活禁跑）⇒ W106A 点名的"收尾链第一优先"仍然挂着。
2. **`~/w93a/probe` 那份旧 PF**：本件**只登记、未处置**（它在**别的车道的仓外目录**，不在本件写域；"要不要刷它/删它"由主控裁）。
3. **`W93A` 报告的提交版口径值对不上**（现算 `81f65f0a7f5cead0` ≠ 任务书 `092c44b3bca27cdd`）：**未去追**是哪一趟改的（本件未碰该件）⇒ 记 `NOINFO`，引用者按**现算值**走。
4. **以下在仓但尚未推的件**（本件**逐件点名、不擅自推**，交主控裁）：`build/MilBridge/W101A-report.md`（`bbd262c6d749fc1b`，`HEAD` 里没有）｜`src/WpfGfx.Linux.Native/src/{win32_internal.h,win32_core.c,win32_msg.c}`、`build/PresentationFramework.Linux/PresentationFramework.Linux.csproj`、`build/integration-wave.sh`、`build/MilBridge/tools/applier-audit-expected.txt`（都是**已跟踪但落后于磁盘**的件）。⚠️ 仓内既有惯例：**产品侧/门禁侧位移走收尾链的 `sync(#NN)` 提交**（`git log -- src/…` 只出现过 `sync(#49)`／`sync(#50)`／首笔搬入）⇒ 本件**不越界**把它们塞进文档提交。
5. **`docs/CURRENT-STATE.md:9` 仍写 `gen=#50`**：本件**不许动**（那要收尾链重钉后一起改）⇒ 如实记为"口径句已进地图、机器行未动"。
6. **未跑任何构建／门禁**（`verify-all`／`close-wave`／`integration-wave` 一条都没跑）⇒ §3 的读数全部**引自 W106A／W101A／主控复核**，本件**未端到端复跑**。

---

## §9 大白话小结（6 行）

1. **`TASK-0108` 改绿了**：`P3` 落地后 `FAIL` 归零（`PASS=8 FAIL=0`），两腿逐字一样、`D-G83` 四格零回归、反极性双向逐位能来回 ⇒ 够格标 ✅，我按**行锚定**只换了那一个状态字符（改后 `wc -l` 仍是 `452`，没吞行）。
2. **把"这次到底修了什么"写进了地图**：四格读数、两条新 sha16、残留边界（**没有 HWND 时不发告示**）、两处 `PASS→VACUOUS`（信息前移，不是回归）、以及**仍红的 `I1`/`W3`（`NOINFO`）**——红的就写红。
3. **加了口径句**：`#51` 只动了 **`win32shim` ＋ `pf`** 两位 ⇒ **收尾链必须重钉世代 ＋ 重冻 `#51`**；`CURRENT-STATE.md:9` 我没动（还写着 `#50`）。
4. **`D-G80` 多了一个很值的实例**：不是"权威件没刷副本"（那是假红），而是"**读数取自一份 10:02 的旧副本**" ⇒ **整趟作废**；教训一句话：**开工前先核"装置读的是哪一份件"**。
5. **`DEFREG=PASS declared=133`（两遍逐字节相同）**；声明表只动了一行锚（`KD`），编号集合**一个没变** ⇒ 纯追加有机证。
6. **`fp_inputs` 变了但与本文档件无关**：覆盖面 148 件里我编辑的 5 件命中 **0**；位移的 5 件全是原生源/门禁件（W106A 与主控落的）。⚠️ 顺带纠正任务书：**两位产品件在 `bin/` 下，被 `fp_inputs` 按设计排除**，别把它们当 `inputs_fp` 的位移源。
