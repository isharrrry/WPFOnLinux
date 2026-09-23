# 波 `#54` —— 预登记（`TASK-0210`：**桥侧几何重发／接管**，修 `D-G98` 族）

> ⚠️ **本件的来历（主控 2026-09-23 授权的逐字声明）**：本件由车道 **W139A** 在 `#54` 收尾链中补建（主控 2026-09-23 授权）；**本波判据先写于车道 W134A 的 `~/w134a/criteria.md`（写定 17:15:32／`189a01aed82b1eea`；§10 追加后 `67da3e7fbec24196`），本件不发明新判据**。
> （先例 = `docs/WAVE53-PREREGISTRATION.md`，由车道 W133A 在 `#53` 收尾链中补建；同族机械要求。）
>
> 补建的理由是**仓规机械要求**，不是本车道想加码：`verify-all.sh` 第 `[14]` 步的判据件
> `build/MilBridge/tools/verify-all-step-check.sh` 在标题行里按 `grep -qE "^#+ .*${gen_decl}"` 找本代号，
> **找不到就 `report_noinfo prereg-absent` ⇒ 该步 `NOINFO rc=2`**（缺声明 ≠ 通过）；
> 而该步变红 ⇒ 冻结器的 `green` 名单（含 `VERIFYALL-SELF`）**必失败** ⇒ **`#54` 冻不了**。
> 现场读数（补建前）：`VERIFYALL_SELF=NOINFO reason=prereg-absent gen=#54 扫了 34 件 docs/WAVE*-PREREGISTRATION.md，本代号没出现在任何标题行里`。
>
> ⚠️ **收尾链的判据在** `$HOME/w139a/criteria.md`（写定时刻 = `2026-09-23 17:44 +0800`，sha16 = `1671aeff2d67a905`）。

---

## §0 本波事实（**逐条现场现算，非手抄**）

| 量 | 值 | 来源 |
|---|---|---|
| 本波唯一产品改动 | `TASK-0210`（「桥侧几何重发／接管」，修 `D-G98` 族） | 主控派单 ＋ 车道 **W134A** 落地（`build/MilBridge/W134A-report.md`，口径 `head -n -2` = `af7204d58eb0b681`，471 行） |
| 判定点原文 | `docs/ROUTES.md:738`（`TASK-0210`） | 现场只读 |
| 源 `MilPresentation.cs` | `8b44b61f944aeeaa` → **`a5ecf1a8faaa2a00`** | 现场 `sha256sum` |
| 源 `X11Window.cs`（**未动**） | `ea6c653493f05a93` | 现场 `sha256sum` |
| 源 `X11PresentationTarget.cs`（**未动**） | `9861117f89383476` | 现场 `sha256sum` |
| 件 `bridge` | `feef049e9d0e313a` → **`4e25e4b27d4d5ae1`**（**尺寸不变 5,028,208 B**） | `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` 现场 `sha256sum` |
| `win32shim`（**本波不动**） | **`a6365183fa6d26b9`**（327,512 B） | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 现场 |
| 权威件导出数 | **547**（不变 —— 本修不动导出面） | `nm -D --defined-only` |
| `inputs_fp`（W134A 落地后现场真函数值） | `bb8829c797128cd314a30f6c3abff6b3adfa00173f8fa35a9c0fbd6addec9fc4` | 真函数 `close-wave.sh` 的 `fp_inputs()`（**不复制函数体**）现场现算 |
| 上一代冻结 | `#53`（整份 `a2e49b786d0a1b02`，737,918 B；`docs/CURRENT-STATE.md:9`） | 现场 |
| 本地 = 远端 head（开工时） | `1b44615b564b5adcafea07fb09eb569599db6834` | `git ls-remote --symref origin HEAD` 现场 |

---

## §1 产品修法（一句话）＋ 为什么它是"判定点"

`WC03` 的 `N3` 归因终局已把 `D-G98` 的发起方定罪为**桥**：`wpfgfx_cor3.so` 在**自己那条 X 连接**上、
于 **WM 真还原成 `800x600` 之后 `+85 ms`** 发出一条**裸 `ConfigureWindow`**（`mask=0x000c`（`CWWidth|CWHeight`）、
`w=1280 h=1024`）⇒ 把窗口**顶回最大化几何**（`build/MilBridge/WC03-report.md`，
sha256 `4d279f76ec38f7d2a7fe2e16c9fdc1e1d3e1457c55dea356f284472cba712c8b`，280 行）。

**W134A 的第一交付 = 定位到行**（`TASK-0210` 原文"本件不定位到行"）：
**执行者** = `src/WpfGfx.Linux/Windowing/X11Window.cs:246`（`XResizeWindow`）＋ `:252`（`XSync`，即调用链那一帧）；
**唯一调用者** = `src/WpfGfx.Linux/Interop/MilPresentation.cs:1082-1083`。

**机制（现场逐字段读数，非推理）**：桥的"X 尺寸优先"用 `_lastXSize` 做**一次性边缘探测**，
而它**每次呈现都无条件刷新** ⇒ 采纳 X 尺寸的那一帧过后那条分支**再也不触发** ⇒ `width/height` 落回
MIL 侧**过期的 `target.WindowRect`**（仍 `1280x1024`）⇒ 与 X 缓存（`800x600`）不等 ⇒ **把过期几何顶回 X**。
诊断读数逐字：`来源=WindowRect X11=800x600 haveLast=True last=800x600 Owns=False HwndTargetCreate=800x600 WindowRect=1280x1024`。

**修法（一处）**：接窗路径（`OwnsWindow == false`）上**只读尺寸、不写几何**（以 server（X）为准渲染），
并**无条件**打一行大声诊断 `[GEOWRITE-SUPPRESSED]`（保留 `M3` 精神）。
自己建的窗（M1／HelloMil 路径）**逐字不变**。

---

## §2 承重判据（**确定性，非率**）

W134A 的两条承重判据（`criteria.md §5`）：

1. **协议层台账那条请求的命中数**：旧件 `12/12` 命中（红）⇒ 新件 **`0/12` 命中**（绿）；
2. **`xobs` 时间轴跳数**：旧件 **四跳** ⇒ 新件 **三跳**，末态 **`800x600`**。

率（`M1:R2` 臂 `N=12`/臂）**只作支撑**（`D-G99`：趟数与功效先写）。
**反极性** = 源逐字节复原 ＋ 重建 ⇒ 件逐字节回 `feef049e9d0e313a`、腿全红；放回 ⇒ 件独立复现 `4e25e4b27d4d5ae1`、腿绿。

---

## §3 本波预期位移（**写死在取数之前**）

| 位 | 预期 | 依据 |
|---|---|---|
| `bridge` | **变**（`feef049e9d0e313a` → `4e25e4b27d4d5ae1`） | `TASK-0210`（产品，**已由 W134A 落地**） |
| `pf` | **变**（`4973bcb28e331cf0` → 新；**同尺寸**） | `D-G92`（环成员，**不是构建身份**，不许当漂移/回归判据） |
| 其余七位 | **逐位不变**（含 **`win32shim a6365183fa6d26b9`**） | 本波零别的产品改动 ⇒ 若第三位变 = **停手报主控** |

`inputs_fp`：**预期变**（重钉 `known-red.json` —— 它在 `fp_inputs()` 覆盖面内，`#28` 起的设计使然）。

---

## §4 装置继承（从 `#53`）

- **显示几何守卫**（`D-G105`，`docs/WAVE52-PREREGISTRATION.md` §R1）：`XREQ_GEOM=1280x1024` 两处复用点；
  冻前 `verify-all` 的 `[0]` 段预期 `X-REUSE=reused`。
- **逐径 `git add`**（`D-G108`：绝不 `-A`／`--force`）＋ `porcelain` 逐件计数对账。
- **`repin-generation.py` 的 `temp`＋`os.replace`**（`D-G101`／跨区硬链）。

---

## §5 回滚姿势（**源逐字节还原 ⇒ 件级逐字节回旧值**）

本波唯一产品改动**可完全回滚**，且**件级可逐字节验证**：

1. 把 `src/WpfGfx.Linux/Interop/MilPresentation.cs` **逐字节**还原为 `8b44b61f944aeeaa`（W134A 的反极性已做过一次）；
2. **重建桥**（`bash build/publish-milbridge.sh`）⇒ 件 **逐字节**回到 **`feef049e9d0e313a`**
   （W134A 实测 `cmp` = `IDENTICAL`，且 **pristine 重建可复现** `BUILD_REPRO=YES` ⇒ 反向也机械可复现）；
3. 放回修法 ⇒ 件**独立复现** **`4e25e4b27d4d5ae1`**。

⇒ 世代身份由 `bridge-src-fp.sh` 的**源指纹**（现树 == 发布记录）锁定；冻结器 `GENS['#54']`
的 `allow_changed = {'bridge','pf'}` 与 `#53` 的 `prev_*` 常数把这条回滚姿势**机器化**。

## §6 方法学纪律（W134A 本波实测的坑，**逐字记**）

> **「改件后重建必须 `touch` ＋ `cmp` 到期望件，不许只看 `rc=0`」**

理由（W134A 现场，反极性因此**假成立**过）：`cp -p` **保留 mtime** ⇒ 还原后的源文件 mtime
**早于**上一次构建的输出 ⇒ MSBuild 增量判定"**无需重编**"⇒ **静默用旧件**、`rc=0` 而产物未换。
⇒ 任何"改源 ⇒ 重建"的两极化**必须** `touch` 源 ＋ `cmp` 到期望件（**逐字节**），
**不许**把 `rc=0` 当"重建发生了"。（`#54` 收尾链把这个坑写进 `$HOME/w139a/criteria.md` §2 第 8 条。）

---

## §7 `NOINFO`（**波级，逐条；不猜**）

1. **MIL 侧 `target.WindowRect` 不收敛**：修后仍恒为 `1280x1024`。本波只解除它的**破坏性作用**，
   未修它为何过期（成因在 `pc`/`pf`/shim 的 `WM_SIZE → UpdateWindowSettings` 链上，**属 W134A 写域外**）⇒ `NOINFO`。
2. **桥为什么只在此臂重发**（`M1:R2` 88.9% vs `M2:R2` 9.1% 的臂间差成因）⇒ `NOINFO`（WC03 已记）。
3. **桥那条连接为何绕过 `LD_PRELOAD`** 的机制 ⇒ `NOINFO`（WC03 已记，最像 `RTLD_DEEPBIND`）。
4. **`pf` 非确定性根因**（`D-G92`，第五次连续现场再证）⇒ `NOINFO`。
