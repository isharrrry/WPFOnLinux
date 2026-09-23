# 波 `#53` —— 预登记（`TASK-0109`：**WM 已死但 EWMH 属性残留 ⇒ 静默丢一次移动**，与 `D-G81` 同族）

> ⚠️ **本件的来历（如实写，不掩饰）**：本件**由车道 W133A 在收尾链中补建**
> （**主控 2026-09-23 12:1x 明确授权**；现场事实 = `docs/` 里此前只有 `WAVE15…WAVE52`，**没有 `WAVE53`**）。
> 补建的理由是**仓规机械要求**，不是本车道想加码：`verify-all.sh` 第 `[14]` 步的判据件
> `build/MilBridge/tools/verify-all-step-check.sh` 在标题行里按 `grep -qE "^#+ .*${gen_decl}"` 找本代号，
> **找不到就 `report_noinfo prereg-absent` ⇒ 该步 `NOINFO rc=2`**（缺声明 ≠ 通过）；
> 而该步变红 ⇒ 冻结器的 `green` 名单（含 `VERIFYALL-SELF`）**必失败** ⇒ **`#53` 冻不了**。
>
> ⚠️ **判据不在这里**：本波的**判据先写于产品车道的** `$HOME/w131a/criteria.md`
> （**写定时刻 = `2026-09-23 10:56 CST`**，**早于该车道任何 X 读数**；
> 口径 `sha256sum` = `045477a20ac256df1bf7edcd3d2e75d7f1b88c252843738d57a37476abadd3dc`，16 位 = `045477a20ac256df`）。
> **本件不发明任何新判据**，只做**波级记录与指针**（收尾链的判据在
> `$HOME/w133a/criteria.md`，写定时刻 = `2026-09-23 12:0x +0800`，sha16 = `028dd2d54ab9d3d1`）。

---

## §0 本波事实（**逐条现场现算，非手抄**）

| 量 | 值 | 来源 |
|---|---|---|
| 本波唯一产品改动 | `TASK-0109`（「WM 已死但 EWMH 属性残留 ⇒ 静默丢一次移动」，与 `D-G81` 同族） | 主控派单 ＋ 车道 **W131A** 落地（`build/MilBridge/W131A-report.md`，口径 `head -n -2` = `f24241c62d92e495`） |
| 源 `win32_x11.c` | `9fa20864404ab01b` | 现场 `sha256sum` |
| 源 `win32_core.c` | `a9cc8762908b417a` | 现场 `sha256sum` |
| 源 `win32_internal.h` | `4e1880e6054635ff` | 现场 `sha256sum` |
| 件 `win32shim` | `bd037229be8db4f6` → **`a6365183fa6d26b9`**（327,512 B） | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 现场 `sha256sum` |
| 权威件导出数 | **547**（不变 —— 本修不动导出面） | `nm -D --defined-only` |
| `inputs_fp`（W131A 落地后） | `f0e2b3e8c058cdf017031360a2cc292ffd6ab7b91b4a8ae47c100c3877522bd7` | 真函数 `close-wave.sh` 的 `fp_inputs()`（**不复制函数体**）现场现算 |
| 上一代冻结 | `#52`（整份 `27293fb5ab91b778`；`docs/CURRENT-STATE.md:9`） | 现场 |
| 本波装置继承 | `#52` 落地的**显示几何守卫**（`XREQ_GEOM=1280x1024`，两处复用点；见 `docs/WAVE52-PREREGISTRATION.md` §R1） | 现场 `verify-all.sh:381-456` |

## §1 产品修法（一句话）＋ 为什么它是"判定点"

`wpf_x11_has_ewmh_wm()` 原先只问「`_NET_SUPPORTING_WM_CHECK` 属性**在不在**」，**不问那个检查窗还在不在树里**
⇒ WM 已死而属性残留时它为**真** ⇒ 走 EWMH 分支（`XSendEvent` 给 root，**没人听**）而**不走兜底**
⇒ 窗**纹丝不动且无任何失败行**（三条 early-return 之外的调用点全部受影响）。
修法 = 语义升级为「**属性在 ∧ 那个检查窗此刻真的在树里**」（临时 `XSetErrorHandler` ＋ `XSync` 换回；
判活**不按错误码白名单**），并加一条**无条件大声诊断** `[WMCHECK_STALE]`。
该谓词全仓**只有 2 个调用点** ⇒ 一处修两处：`win32_x11.c` 的 `moveresize`（`TASK-0109` 本体）
＋ `win32_core.c:653` 的**窗态最大/还原**（同因同修；⚠️ 这一半**今天还没有缺陷号** ⇒ W131A 只取读数、未登记，
登记由主控统一落）。`return 1` 的**对外契约保持不变**。

## §2 本波位移预期（收尾链判据用；**先写**）

相对 `#52` 冻结点（九位快照 `/home/links-dev/w53-pre.sha`，键=路径，9 行，逐位取自 `#52` 冻结块）：

- **`win32shim` 必有**：`bd037229be8db4f6` → `a6365183fa6d26b9`（= `TASK-0109`）。
- **`pf` 可能变**（整波重建的**非确定性**，`D-G92`：`pf` **不是构建身份**；`#50`/`#51`/`#52` 已连续三次同形）
  ⇒ 变了**不算**表外位移，但**必须如实记成对读数**。
- 其余七位（`bridge`/`pc`/`windowsbase`/`provider`/`wic_shim`/`hbtextline`/`dwf`）**逐位不变**。
- 允许集合 = `{win32shim, pf}`；出现**任何**第三位 ⇒ **停手上报，不冻结**。
- `hbtextline` **必须不变**（`build/shims/**` 一个字节都不许动）。
- `BRIDGE_SRC_FP` = `0a8f69b3c5fabd43` **不变**（本修只动 native）⇒ 桥**不必重发**。

## §3 收尾链要跑什么（**判据全文在 `$HOME/w133a/criteria.md`**）

整波重建（`close-wave.sh [1/6]`，`--skip-verify-all`）→ native 复现（`build-shim.sh --all`，**必须复现
`a6365183fa6d26b9`**）→ 五臂重取 → `repin-generation.py --why` → 应用门禁 ×2 → 冻前 `verify-all`
（预期**恰好 1 处声明类红 = `COLUMN-FLOOR`**）→ 冻结 `#53`（四颗牙全 PASS）→ 冻后 `verify-all` ×2（两趟同形）
→ 收尾记录 → **逐径**推送 → app-local → 哨兵（`close-wave.sh [6/6]`）。

⚠️ 停条件（**出现即停手上报，不冻结**）：① 表外位移；② native **复现不出** `a6365183fa6d26b9`；
③ 五臂**判词**与 `#52` 不一致；④ 冻前 `verify-all` 出现**第 2 处非声明类红**；⑤ `hbtextline` 变了。

## §4 本件新建时**点到名**的两件事（供后人复核，不掩饰）

1. 本件是**补建**的（见文首），所以它的"预登记"性质是**波级记录**（判据早在 W131A 的 `criteria.md` 里写定）。
2. `verify-all.sh` 的**四处声明**同趟改到 `gen=#53`（**步名/步数一字不动，仍 27 步**）——
   该件**不在** `fp_inputs()` 覆盖面内（`build/close-wave.sh` 的 `fp_inputs()` 末尾自己写明这条"残留缺口"）
   ⇒ **不动 `inputs_fp`**。改动的 before/after sha16 见 `build/MilBridge/W133A-report.md` §①。
