# 波 `#78` 预登记（**四件合波**）：`TASK-0747` ＋ `D-G147` ＋ `TASK-0739`③ ＋ `TASK-0744-FU`

> 本件与落地**同趟**产出。落仓那刻现取：`run_step=51`（`#78` **加一步** `APPBAR-STARTUP`）／覆盖面 **217**／`--expect 217`。
> **本波有产品改动** ⇒ `win32shim` 与 `pf`（环成员）必动。

## §1 四要件

### 1.1 断言（可判否）
1. **`TASK-0747`**：`src/WpfGfx.Linux.Native/src/win32_oem.c` 的 shell32 段补一处 `SHAppBarMessage`；`ABM_GETTASKBARPOS` 填**本移植的工作区事实**（`wpf_x11_workarea`），其余消息返 `0` ＋ `E_NOTIMPL`，注释**如实写「工作区近似」**。判否：`nm -D --defined-only … | grep -c SHAppBarMessage` ≠ **1**；或两极化（装符号 ⇒ 启动期异常消失且字节读数**恰 `−242`**；不装 ⇒ 每启动 242 B）不成立。
2. **`D-G147`**：工作区语义 —— `win32_x11.c`／`win32_core.c`／`win32_misc.c`／`win32_internal.h` 四件按包内锚点改造；判据 = 工作区事实的**来源**与 `ABM_GETTASKBARPOS` 的**消费者对账**的成对读数。
3. **`TASK-0739`③**：显示号**租借**（装置 `display-lease.sh` ＋ 牙 `display-lease-gate.sh`，带 pid 标记）；判否：起过 ⇒ 收尾后该号**无进程**；没起过 ⇒ **一个都不杀**；`X-CENSUS` 在链前基线上 `leaks=0`。
4. **`TASK-0744-FU`**：装置随行打印 **socket 身份**（`getpeername` 断言 `.X11-unix/`），缺失即 `NOINFO`；并证明「符号级 hook 恒瞎」在新装置上仍成立（`D-G144`）。

### 1.2 判定口径（先写死，见各包 `criteria.md`）
`~/w181a/w7x/criteria.md`（`628b8f592ac330f2`）｜`~/w182a/criteria.md`（`b377848970a1c21a`）｜`~/w183a/criteria.md`（`4115b8b2e3bb5e2b`）｜`~/w184a/criteria.md`（`ee5621b95b22e4c1`）。
三态一律 `PASS`／`FAIL`／`NOINFO`；**`NOINFO` 不算绿**；`examined == 0` ⇒ 一律 `NOINFO`。

### 1.3 输入来源声明（纪律 36）
`verify-all.sh`／`build/close-wave.sh`／`src/WpfGfx.Linux.Native/src/*.c` 的**落地那刻现取 sha16**；覆盖面由 `fp_inputs()` 同码路径现取；九位由 `sha256sum` 现算；`GENS['#78']` 的 `prev_*` 一律取 `#77` **冻后值**。

### 1.4 回归判定（本波**不做**产品回归对比 ⇒ 走机读行形态，纪律 45）
```
PREREG-NO-REGRESSION-DECISION: not-applicable-product-change-wave-78
```

## §2 位移声明（**先写**）
`win32shim` **必动**（产品源 5 文件改动）｜`pf` = **环成员**（整波重建必变，同尺寸）｜`bridge`／`pc`／`wb`／`provider`／`dwf` 若动 ⇒ **逐位点名归因**；**表外位移 ⇒ 停手报主控**。
冻结器配置的**机读声明行**（由新牙 `build/MilBridge/tools/wave-freeze-consistency-check.py` 档② 逐字段核）：
```
WFREEZE-DECL: gen=#78 allow_changed=pf,win32shim,provider pf_required=False
```

## §3 `§追加 1`／`§追加 2` 的处置（**本波如实记账**）
- **根级条目白名单牙** ＋ **「交付 ⊆ 接线」／「接线 ⟹ 真判」牙**：**显式延期**（契约允许，`#78` 负载已含两处产品改动 ＋ 三件装置/牙 ＋ 整波链）。延期理由与下一步设计逐字写在 `build/MilBridge/P0-w78-report.md` §延期 —— **不静默丢掉**。
- **两条新登记**（`-getProperty`/`-getItem` 射程边界；九位路径承载性）：落 `docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md`。
- **15 件 tracked 派生件**：本波推送**前**按径 `git add` 入笔（禁 `-A`）⇒ 推送后 `porcelain=0`；**不用** `git restore` 丢件。

## §4 落仓那刻的声明值（**断言相等**，不是常量）
| 声明 | 值 | 来源 |
|---|---|---|
| 步数 | 现读 **51**（50 ＋ `APPBAR-STARTUP`） | `grep -c '^run_step "'` |
| 覆盖面 | 现读 **217**（212 ＋ 本波 5 件） | `infp.sh list \| wc -l` |
| `[42] --expect` | **217**（同趟） | 现取 |
| `inputs_fp` | **必移** | 整波自印 ＋ 独立复算互证 |

## §5 判据（落地前写死）

### 5.1 回归判定（本波不适用）

`PREREG-NO-REGRESSION-DECISION: not-applicable-product-change-wave-78`

（本波是**产品改动 ＋ 装置/声明卫生**合波，**不含**任何"修前/修后"产品对比 ⇒ 四要件对本波不适用；本行是**硬形态**声明 ⇒ 不得带 `residual=` 令牌。**本波不做任何回归判定**。）

### 5.2 四要件逐条落位（判定器口径）
① **断言**（§1.1 四件，可判否）｜② **判据**（§1.2：四包 `criteria.md` ＋ 三态 `PASS/FAIL/NOINFO`，`NOINFO` 不算绿）｜③ **输入来源**（§1.3，纪律 36）｜④ **回归判定**（§5.1 ⇒ `NA`：非 `PASS` 亦非违规）。
**三态词表**：`REGRESSION`／`NOINFO`（皆见本节）；判据件路径 `build/MilBridge/tools/regression-decision.py`（**本波不调用它** —— 不适用）。


### §2-追 dated 更正（**2026-09-27 主控落册**；上面那行机读声明**一字未动**）

上面 §2 的机读声明行写的是 `allow_changed=pf,win32shim,provider`（**3 键**）—— 那是**落地前的预想**。
**实际冻结**时 `GENS['#78'].allow_changed` 是 **6 键**：`pc,pf,provider,win32shim,windowsbase,dwf`（`~/w21-verify/w27-freeze.py` 的 `GENS['#78']` 条目现读）。

**逐键归因（为什么预想少了三键）**：`pc`／`windowsbase`／`dwf` 是 `D-G92` 同族的**路径承载体** —— `#76` 的九位是**从旧树 `O` 拷进 `N` 的**，而 `#78` 是 `N` 内的**真重建**，托管件里嵌的 `*.pdb` **绝对路径**随之改变（**字节大小逐位相同**）；这三位的位移**只在整波跑出来之后才可观测**，属"预想阶段拿不到的量"。
⇒ **权威声明是 `GENS['#78']`（6 键）**，本预登记那一行只作**预想**留存；`GENS` **不收回、不追改**（它反映的是真实位移）。

**同类口径（`t19` 现场顶出的牙）**：`build/MilBridge/tools/wave-freeze-consistency-check.py` 档② 只核**最新声明世代**（按 `gen` 数字取最大）⇒ 本行的 3↔6 落差在 `#79` 预登记落仓后**不再被该档核到**（现读该档为 `WFREEZE_DECL=NOINFO reason=gens-has-no-entry gen=#79`）。**这条"只核最新代"是牙的射程上限**，已作为发现登记（历史世代的"预登记↔实际位移"落差从此不可见）；本更正行即为此留下**可读的**账。
