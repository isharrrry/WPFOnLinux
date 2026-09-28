# P1-W26 · W8 **第三步**预登记判据 —— 下一跳 `LoGetPenaltyModuleInternalHandle`（＋`LoDisposePenaltyModule` 是否同趟补）

> **本件是判据件（先写），不是实现件**：本件**不做**实现、**不构建**、**不跑腿**、**不占显示位**，供随后的**实现件**与**独立复核件**当契约用。
> **一切读数由我现取**（命令与输出原样贴出）；`P1-w8-step1-criteria.md`／`P1-w8-step2-criteria.md` 只作**形制参照**，**结论一条不抄**；**未引任何既有报告当证据**。
> **边界（硬）**：只读仓树；唯一写入 ＝ 本件；**未** `dotnet build`、**未**跑腿、**未**占显示位、**未**跑整趟门禁、**未** `git add/commit/push`；未改任何判据件／产品件／`docs/ROUTES.md`／`HANDOFF-NEXT.md`／`tools/**`。
> **读取时刻**：`ts=2026-09-29T01:00:26.606+0800`（起点）→ `2026-09-29T01:00:37.759+0800`（末取）。

---

## §0 快照与现取读数

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | **`e528f53`**（`docs(#81): t99 最终对齐判定（无需换代）+ t97 那趟在册腿证据入账`） | `git log --oneline -1` |
| 工作树 | 干净（仅 8 个 `??`：`build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/**` 7 项 ＋ `src/tests/` ⇒ **全属他人**，我一个未动） | `git status --porcelain` |
| 权威 `.so` | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`461e5557bd7dd571`** | `sha256sum` |
| 导出面 | `nm -D --defined-only … \| grep -c .` ＝ **565** ＝ `wc -l src/WpfGfx.Linux.Native/bin/exports.txt` ＝ **565**（`exports.txt` sha16 `b81706ac335f5321`） | `nm`／`wc -l`／`sha256sum` |
| PTS 桩件 | `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`f34cb7c37c3cc61d`**；在册名册 `k_pts_entries[]` 现取 **13** 名 | `sha256sum`／`sed` |
| 缺口面 | `check-shim-coverage.py --tier mapped` ⇒ `扫描到 423 条`；**`[PresentationNative_cor3.dll] 96 条`**；前缀分解 **`Lo=15 Fs=66 Nl=6 Wrapper=5 other=4 total=96`**；**两个候选入口在该缺口面里命中都是 `0`** | 现跑（§2-C2） |
| 缺口三格 | `PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=90 so16=461e5557bd7dd571 exports=565` | 现跑（§2-C3） |
| **前沿** | `PTSGAP_FRONTIER before=LoCreateContext@3 after=LoGetPenaltyModuleInternalHandle@3 carrier_sha16=eed6c1558509dd94 carrier_mtime=2026-09-29 00:54:07.535719882 +0800`｜`PTSGAP_FRONTIER_STATE=NAMED frontier=LoGetPenaltyModuleInternalHandle（具名前沿成立）` | 同上 |
| 在册载体 | `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` ＝ **`eed6c1558509dd94`**：`3 entry=LoGetPenaltyModuleInternalHandle` ＋ `1 entry=LoDisposePenaltyModule`（**`unknown` ＝ 0**）；`:568 PTS_GAP entry=LoGetPenaltyModuleInternalHandle seq=4 err=-10000 calls=1`；`:665 PTS_GAP entry=LoDisposePenaltyModule seq=5 err=-10000 calls=1` | `grep -o`／`grep -n`／`sha256sum` |
| 两页症状（在册腿，`arm_A`，与 `evidence/leg_*.env` 逐位同值） | `leg_23.env`（`c769ad1eea1239be`）：`LEG k=23 alive=yes app_rc=143 magenta=49592 colors=844 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae=141985 ink=428765`｜`NAMED managed_unavail=1 err=-10000 native_gap=2 native_err=-10000`｜`DEV x_up=yes five_stable=yes shim=461e5557bd7dd571 pf=6893d1d3fb1ee110`；`leg_24.env`（`cf629974a04ddcff`）：`magenta=54182 colors=852 ns=…FlowDocumentDemo ae=221857 ink=424107` | `cat` |
| 守卫 | `bash build/MilBridge/tools/pts-pages-guard.sh --legs <证据目录>` ⇒ `rc=0`；`PTS_G10_NAME=PASS observed=LoGetPenaltyModuleInternalHandle names=2 roster=13 domains=pts-declared`｜`PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded` | 现跑 |

✅ **本趟同趟性现取 ＝ `yes`**：`so16=461e5557bd7dd571` ＝ `DEV … shim=461e5557bd7dd571` ＝ 现盘 `.so`（与上一件 `t96` 那次"三者不一致"**不同**，本趟是干净的成对底座）。

---

## §1 ① 诚实边界 ＋ **本步的两条候选：哪一条是主跳、要不要一起做**

### 1.1 上游签名与托管调用点（原文）

`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs`
```
        [DllImport(DllImport.PresentationNative, EntryPoint = "LoDisposePenaltyModule")]
        internal static extern LsErr LoDisposePenaltyModule(
            IntPtr                  penaltyModuleHandle
            );

        [DllImport(DllImport.PresentationNative, EntryPoint = "LoGetPenaltyModuleInternalHandle")]
        internal static extern LsErr LoGetPenaltyModuleInternalHandle(
            IntPtr                  penaltyModuleHandle,
            out IntPtr              penaltyModuleInternalHandle
            );
```
⇒ **入参都是「罚分模块句柄」（`penaltyModuleHandle`），不是 `ploc`** —— 这是与第二步（`LoAcquirePenaltyModule(ploc, out …)`）**最大的一处形状差异**，直接决定"句柄身份校验"要认谁。

托管调用点（我现取，排除声明件）：
```
PresentationCore/MS/internal/TextFormatting/TextPenaltyModule.cs:59:  UnsafeNativeMethods.LoDisposePenaltyModule(_ploPenaltyModule);
PresentationCore/MS/internal/TextFormatting/TextPenaltyModule.cs:80:  LsErr lserr = UnsafeNativeMethods.LoGetPenaltyModuleInternalHandle(_ploPenaltyModule, out penaltyModuleInternalHandle);
```
`TextPenaltyModule.cs` 两处完整上下文（原文节选）：
```
        private void Dispose(bool disposing)
        {
            if (_ploPenaltyModule != IntPtr.Zero)
            {
                UnsafeNativeMethods.LoDisposePenaltyModule(_ploPenaltyModule);   // ← **不检查返回值**
                _ploPenaltyModule = IntPtr.Zero;
                _isDisposed = true;
                GC.KeepAlive(this);
            }
        }
        internal IntPtr DangerousGetHandle()
        {
            if (_isDisposed) { throw new ObjectDisposedException(SR.TextPenaltyModuleHasBeenDisposed); }
            IntPtr penaltyModuleInternalHandle;
            LsErr lserr = UnsafeNativeMethods.LoGetPenaltyModuleInternalHandle(_ploPenaltyModule, out penaltyModuleInternalHandle);
            if (lserr != LsErr.None)
                TextFormatterContext.ThrowExceptionFromLsError(SR.Format(SR.GetPenaltyModuleHandleFailure, lserr), lserr);
            GC.KeepAlive(this);
            return penaltyModuleInternalHandle;
        }
```
⇒ **`LoGetPenaltyModuleInternalHandle` 的判错在托管侧（非 `None` 即抛）**；**`LoDisposePenaltyModule` 的返回值被丢弃** ⇒ 它今天返回 `-10000` **不会**让进程抛。

本地 native 现状（**两个都还是诚实缺口 stub**，我现取）：
```
src/WpfGfx.Linux.Native/src/win32_pts.c:628
int LoDisposePenaltyModule(void *penaltyModuleHandle)
{
    (void)penaltyModuleHandle;                 /* 不 deref、不 free：本层没有需要释放的真资源 */
    return wpf_pts_gap("LoDisposePenaltyModule");
}

src/WpfGfx.Linux.Native/src/win32_pts.c:634
int LoGetPenaltyModuleInternalHandle(void *penaltyModuleHandle, void **internalHandle)
{
    (void)penaltyModuleHandle;
    if (internalHandle) *internalHandle = NULL;
    return wpf_pts_gap("LoGetPenaltyModuleInternalHandle");
}
```
⇒ 两者**都已导出**（缺口面命中 **0**，见 §0）⇒ **本步不会改变 `EntryPointNotFoundException` 面**（与第二步同形，见 §2-C2 的"按实际归因"写法）。

### 1.2 判断（**本判据写死**，含理由与现取证据位）

> **结论：主跳 ＝ `LoGetPenaltyModuleInternalHandle`（本轮必做）；`LoDisposePenaltyModule` 本轮「不必」升级为真实现，但「不许回退」（不得变回未导出，也不得改成假成功）。**

**理由（逐条给现取证据位）**
1. **运行期定靶**：`entry=` 面现取 `3 LoGetPenaltyModuleInternalHandle`（载体 `eed6c1558509dd94`），与台账 `:568 PTS_GAP entry=LoGetPenaltyModuleInternalHandle seq=4` **逐字同名** ⇒ 它是应用链上**被撞到的那一个**。`LoDisposePenaltyModule` 现取只有 `1` 次、且在**清理期**（`seq=5`，晚于 `seq=4`）。
2. **它今天会抛，`LoDisposePenaltyModule` 今天不会**：`TextPenaltyModule.cs:83-84`（非 `None` 即抛） vs `:59`（返回值被丢弃） ⇒ 只有前者在**功能路径**上掐链。
3. **它不补则后续全被挡住**：`PtsCache.Linux.cs:534` 的 `penaltyModule.DangerousGetHandle()` 会抛 ⇒ `:535`／`:536`／`:542`（`GC.SuppressFinalize`）与 **`:548 PTS.CreateDocContext`** 都**走不到**（见 §1.3）。
4. **`LoDisposePenaltyModule` 已是"诚实 stub"**：现取 `:628` 清空入参语义（这里是 `(void)` ＋ 返 `-10000`）⇒ **它不是假装成功**；托管侧丢弃返回值 ⇒ 不会抛 ⇒ **不构成本步的阻塞**。
5. **第二步的教训不直接适用**：第二步必须"同时给 `LoAcquirePenaltyModule` ＋ `LoDisposePenaltyModule`"，是因为**前者提供句柄**而**后者当时未导出**（ENFE ⇒ 终结器路径 `rc=134`）。**本步两者都已导出** ⇒ **不存在**"未导出同伴被终结器撞死"的同类风险。**但**有一条**新的**同类风险（下条）。

**⚠️ 本步必须点名的副作用（`LoDisposePenaltyModule` 的调用来源会变）**
- 现状：`:534` 抛 ⇒ `:542` 的 `GC.SuppressFinalize(_contextPool[index].TextPenaltyModule)` **没被执行** ⇒ 终结器**仍注册** ⇒ 现取的 `1 entry=LoDisposePenaltyModule`（`seq=5`）**来自终结器路径**（`TextPenaltyModule.cs:40-42` → `Dispose(false)`）。
- 补完主跳后：`:534` 成功 ⇒ `:542` **第一次执行** ⇒ 终结器被抑制 ⇒ `LoDisposePenaltyModule` 改由**显式 Dispose** 调用（`PtsCache.Linux.cs:421`／`:493` 的 `_contextPool[index].TextPenaltyModule?.Dispose()`），并**必须**在 `DestroyDocContext`（`:416`／`:488`）**之后**（同件注释逐字：「PTS context must be destroyed first」）。
- ⇒ **推论**：本步**不必**升级 `LoDisposePenaltyModule`；但**若**升级成真实现，**必须同时覆盖两条路径**（终结器 ＋ 显式 `Dispose`），否则会在异常/早退路径上漏释放或重复释放。**这条是本步的"同伴入口"判定**。

### 1.3 本步**会不会**第一次打开一条此前走不到的托管侧路径？—— **会，且已点名**

| 现取证据位 | 现状（before） | 补完主跳后（after 预期形状） |
|---|---|---|
| `PtsCache.Linux.cs:534` | `DangerousGetHandle()` 抛（`-10000`） | **不抛** ⇒ 返回**真 internal handle** |
| `PtsCache.Linux.cs:535`（`_contextPool[index].TextPenaltyModule = penaltyModule;`） | **走不到** | **第一次执行** |
| `PtsCache.Linux.cs:536`（`ContextInfo.ptsPenaltyModule = ptsPenaltyModule;`） | **走不到** | **第一次执行** ⇒ `ContextInfo` **第一次带上真罚分模块句柄** |
| `PtsCache.Linux.cs:537`（`TextFormatter.CreateFromContext(...)`） | **走不到** | **第一次执行** |
| `PtsCache.Linux.cs:542`（`GC.SuppressFinalize(...)`） | **走不到** | **第一次执行**（⇒ §1.2 的副作用） |
| **`PtsCache.Linux.cs:548`（`PTS.Validate(PTS.CreateDocContext(...))`）** | **走不到** | **第一次被走到** ⇒ 该站是**台账 `k_pts_entries[]` 十名之一**（现取名册 13 名含 `CreateDocContext`）⇒ 台账会出现 `CreateDocContext` 行，且 `PTS.Validate` 会因该 stub 返 `-10000` 抛 `PtsException` |
| **收尾同伴** | — | **`DestroyDocContext`**（`PtsCache.Linux.cs:416`＝`PTS.IgnoreError(...)`／`:488`＝`PTS.Validate(...)`）＋ `TextPenaltyModule.Dispose`（`:421`／`:493`） |

⇒ **本步的"下一跳"预期是"前沿从 `LoGetPenaltyModuleInternalHandle` 移到 `CreateDocContext` 或再往里"，而不是"两页真排版"**（不预判具体名字，见 §6-N1）。

### 1.4 分界句与「最小可辩护实现」/「假成功」/「非目标」

> **分界句（沿用前两件，逐字）**：**`return 0`（`LsErr.None`）本身**不是证据**；证据是「这次调用在本进程内留下了**与该对象绑定**、**可被独立读取**的状态变化」。**

- **`LoGetPenaltyModuleInternalHandle` 的最小可辩护实现（本步四件套）**：
  1. **句柄身份校验**：入参是**罚分模块句柄** ⇒ 只认 `LoAcquirePenaltyModule` **自己发过、且仍活着**的句柄；`NULL`／未知／伪造 ⇒ **失败返回（非 0）且一个字节都不读**。
  2. **出参真落盘且与该句柄绑定**：`*penaltyModuleInternalHandle` 指向**该模块**的内部句柄（**不是**进程级全局单例；第二个模块不串味）；`NULL` 出参 ⇒ **拒绝**（不给"写空也算成功"）。
  3. **计数**：成功/被拒各一对（供自检断言）。
  4. **可独立读取**：观测镜记下"刚才是**哪个** `penaltyModuleHandle`、落出了**什么** internal handle"；**权威**始终是模块对象本身，自检**逐字段对拍**两者。
- **算「假装成功」**：返回 `None` 但出参仍 `NULL`／是常量／是未与入参句柄绑定的全局值；或入参是 `NULL`/伪造却照样返回 0。
- **`LoDisposePenaltyModule` 本轮的最小要求（不升级版）**：**保持现形**（已导出 ＋ 诚实返回非 0 ＋ 不 deref）；**并且**：若实现件为覆盖 §1.2 的两条路径而升级它，则**必须**满足"幂等"（同一句柄重复释放不得改坏状态）＋"未知句柄一次性拒绝（不 deref）"。
- **非目标（明确不做）**：不实现罚分模块的**内部算法**（不断行代价、不算 optimal paragraph）；不顺带补 LS 族其余缺失入口（现取 `Lo=15`）；不承诺两页真排版；不改应用侧仪表（`entry=` 面）；**不**把 `CreateDocContext` 的 stub 改成真实现（那是**下一跳**）。

---

## §2 ② 判据 C1–C8

> **通用**：每条 verify **必须捕获式取 `rc`**（`cmd >out 2>err; echo $?`）；**不许**从管道末段取 `$?`。
> **通用反过读句**：任何"绿"都不许被读成"两页真排版"。
> 🔴 **本步对"缺口面"的写法（吸收第二步的教训）**：**不硬凑数字** —— 两个候选入口**现取都不在** `EntryPointNotFoundException` 面里，因此**本步的正常形态就是"缺口面不变"**；**任何变化都必须按实际补了几条来归因并逐条点名**，不许先写死 `96→96` 再去凑（第二步的判据写死 `97→97`，实测因**同趟补同伴 stub** 变成 `97→96` 而被推翻）。

### C1 构建面：源码改动真进了 `.so`
- **objective**：本增量真被编译进 `libwpfwin32.so`。
- **acceptance**：`bash src/WpfGfx.Linux.Native/build-shim.sh --symbols >out 2>err; echo $?` ⇒ `rc=0`；`exports.txt` 行数 **＝** `nm -D --defined-only … | grep -c .`；`.so` 的 `sha16` **≠ before**（before ＝ `461e5557bd7dd571`）。
- **取哪个字段**：`src/WpfGfx.Linux.Native/bin/exports.txt` 行数；`libwpfwin32.so` 的 `sha16`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash src/WpfGfx.Linux.Native/build-shim.sh --symbols >/tmp/c1.out 2>/tmp/c1.err; echo "rc=$?"; a=$(nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | grep -c .); b=$(wc -l < src/WpfGfx.Linux.Native/bin/exports.txt); echo "nm=$a exports=$b equal=$([ "$a" = "$b" ] && echo yes || echo NO)"
```
- **期望形状**：`rc=0` ∧ 两值**相等** ∧ 两值 **≥ 565**（**不得下降**；若新增自检符号而 >565，**允许**）。

### C2 缺口面：**按实际归因，不硬凑数字**
- **objective**：`EntryPointNotFoundException` 面如实记录（本步的正常形态是**不变**）。
- **acceptance**：`check-shim-coverage.py --tier mapped` 的 **`[PresentationNative_cor3.dll] N 条`** 与 `Lo*` 前缀数**成对给 before/after**（before：**96**／`Lo=15`）；**两个候选入口在该面里的命中恒为 `0`**；若 `N` 变化，**必须点名**"哪一条入口名进了/出了该面"并给出它对应的 `return wpf_pts_gap("…")` 行或导出证据。
- **取哪个字段**：工具 stdout 的 `^  \[PresentationNative_cor3\.dll\] [0-9]+ 条` 行 ＋ 明细行。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier mapped >/tmp/c2.out 2>/tmp/c2.err; echo "rc=$?"; grep -E '^  \[PresentationNative_cor3\.dll\] [0-9]+ 条' /tmp/c2.out; grep -cE '^  PresentationNative_cor3\.dll  (LoGetPenaltyModuleInternalHandle|LoDisposePenaltyModule) ' /tmp/c2.out
```
- **期望形状**：`rc=0`；条数 **按实际归因**（纯行为补全 ⇒ **96→96**；同趟新增导出 ⇒ 允许变化，但**逐条点名**）；第二值 **＝ 0**。⇒ **本条的绿不构成"前进"证据。**

### C3 台账/前沿面：**前进的主证据**
- **objective**：主跳被补后，运行期的**前沿**真的离开 `LoGetPenaltyModuleInternalHandle`。
- **acceptance**：`bash build/MilBridge/tools/pts-gap-count-check.sh >out 2>err; echo $?` ⇒ `rc=0`；三格 `tool/ops/impl` 成对；`PTSGAP_FRONTIER` 的 **`after=` ≠ `LoGetPenaltyModuleInternalHandle`**；`carrier_sha16=` 同趟给出且**等于**现取载体 `sha16`；`PTSGAP_FRONTIER_STATE` 行在位。
- **取哪个字段**：`PTSGAP=`（`tool/dead/artifact/ops/impl/so16/exports`）／`PTSGAP_FRONTIER`（`before=`／`after=`／`carrier_sha16=`）／`PTSGAP_FRONTIER_STATE`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/pts-gap-count-check.sh >/tmp/c3.out 2>/tmp/c3.err; echo "rc=$?"; grep -E '^(PTSGAP|PTSGAP_FRONTIER|PTSGAP_FRONTIER_STATE)=' /tmp/c3.out
```
- **期望形状**：`rc=0`；`so16=` ＝ 现盘 `.so`；**`after=` 的入口名 ≠ `LoGetPenaltyModuleInternalHandle`**（**不预判**它是谁）。⚠️ 若 `CreateDocContext` 真的被走到，那里**也会**出现 `PTS_GAP entry=CreateDocContext …` 行 —— 那是**预期**，不是异常。

### C4 `entry=` 面：具名**位移**且可回溯
- **objective**：应用侧自报 `entry=` 跟着位移，且**不是**被改成常量。
- **acceptance**：载体 `app_g1.log` 的 `entry=` 直方图：`LoGetPenaltyModuleInternalHandle` 计数 **after < before**（before ＝ **3**，最理想为 0）；**新出现的具名**必须能用 `grep -n 'EntryPoint *= *"<该名>"' upstream/wpf/**` 现取**回溯到真实声明**；`unknown` **不增**（before ＝ **0**）。
- **取哪个字段**：`build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` 的 `entry=` 直方图。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; grep -o 'entry=[A-Za-z0-9_]*' "$D/app_g1.log" | sort | uniq -c; grep -c 'entry=unknown' "$D/app_g1.log"
```
- **期望形状**：该名计数**下降**；`unknown` **不增**（0 保持 0）。

### C5 释放同伴面：`LoDisposePenaltyModule` **不得回退**，且来源变化可见
- **objective**：本步不得让释放路径变成"未导出"或"假成功"；并如实记录其**调用来源**变化。
- **acceptance**：① `nm -D --defined-only … | grep -cx 'LoDisposePenaltyModule'` ＝ **1**（不得为 0）；② 该入口**仍返回非 0**（若未升级）或**真返回 0 且出参/状态真变**（若升级）—— 由实现件在载体里**二选一声明**；③ `entry=` 面里 `LoDisposePenaltyModule` 的**次数与相位**（清理期）如实记录，并说明它是"终结器路径"还是"显式 Dispose 路径"（判据：同趟给 `PtsCache.Linux.cs:542` 的 `GC.SuppressFinalize` 是否被执行——由 `:534` 是否抛决定）。
- **取哪个字段**：`nm` 命中；`app_g1.log` 的 `entry=` 直方图与 `PTS_GAP … LoDisposePenaltyModule` 行的 `seq=`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | grep -cx 'LoDisposePenaltyModule'; grep -n 'PTS_GAP entry=LoDisposePenaltyModule' build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log
```
- **期望形状**：第一个值 **＝ 1**；第二处**在位**（本步**不要求**它消失）。

### C6 冷启腿两页面：**不劣化** ＋ 台账效应可见
- **objective**：本步不把两页推回"进程死"，且台账效应可读。
- **acceptance**：`leg_23.env`／`leg_24.env`：`LEG … alive=yes` ∧ `app_rc ∉ {134,139}` ∧ `magenta ≥` 门禁阈值；`NAMED … native_gap` **after ≥ before**（before ＝ **2**）且 `DEV … shim=` ＝ 本趟 `.so`；守卫 `pts-pages-guard.sh --legs <dir>` ⇒ `rc=0`，`PTS_GUARD=` 与 `PTS_G10_NAME=` 在位。
- **取哪个字段**：`leg_{23,24}.env` 的 `LEG`／`NAMED`／`DEV` 三行；守卫两行。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; bash build/MilBridge/tools/pts-pages-guard.sh --legs "$D" >/tmp/c6.out 2>/tmp/c6.err; echo "rc=$?"; grep -E '^(PTS_GUARD|PTS_G10_NAME)=' /tmp/c6.out; grep -hE '^(LEG|NAMED|DEV) ' "$D"/leg_23.env "$D"/leg_24.env
```
- **期望形状**：`rc=0`；两腿 `alive=yes`；`native_gap ≥ 2`。

### C7 **同趟性**（本步**必查**，因为成对读数跨趟就是假对）
- **objective**：before/after 的所有面取自**同一趟**。
- **acceptance**：`pts-gap-count-check.sh` 的 `so16=` **＝** `leg_*.env` 的 `DEV … shim=` **＝** 现盘 `.so` 的 `sha16` 前 16（**三者逐位相同**），且 `pts-gap-count-check.sh` 的 `carrier_sha16=` **＝** `app_g1.log` 的实际 `sha16`。
- **取哪个字段**：上述四个值。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; s=$(sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16); g=$(bash build/MilBridge/tools/pts-gap-count-check.sh | grep -o 'so16=[0-9a-f]*' | cut -d= -f2); l=$(grep -h '^DEV ' "$D"/leg_23.env | grep -o 'shim=[0-9a-f]*' | cut -d= -f2); c=$(grep -o 'carrier_sha16=[0-9a-f]*' /tmp/c3.out 2>/dev/null | cut -d= -f2); a=$(sha256sum "$D"/app_g1.log | cut -c1-16); echo "so=$s gap_so16=$g leg_shim=$l carrier=$c app_g1=$a same=$([ "$s" = "$g" ] && [ "$g" = "$l" ] && [ "$c" = "$a" ] && echo yes || echo NO)"
```
- **期望形状**：`same=yes`。**before 现取是 yes**（§0 已验证）；after **必须**保持 yes。

### C8 stub 面：主跳**不再**走诚实缺口
- **objective**：`LoGetPenaltyModuleInternalHandle` 从"缺口路径"消失（行为面机械证据，与 C2 的"缺口面可能不变"互补）。
- **acceptance**：`grep -c 'return wpf_pts_gap("LoGetPenaltyModuleInternalHandle")' src/WpfGfx.Linux.Native/src/win32_pts.c` **before ＝ 1 → after ＝ 0**；**若同时升级了 `LoDisposePenaltyModule`**，则对应串 `return wpf_pts_gap("LoDisposePenaltyModule")` 也 **1 → 0**（**但升级它不是本步的必做项** ⇒ 若维持 stub，该计数保持 **1** 并**必须**在载体里二选一声明）。
- **取哪个字段**：该源件的两个字符串命中数。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && for n in LoGetPenaltyModuleInternalHandle LoDisposePenaltyModule; do printf "%s=%s\n" "$n" "$(grep -c "return wpf_pts_gap(\"$n\")" src/WpfGfx.Linux.Native/src/win32_pts.c)"; done
```
- **期望形状**：`LoGetPenaltyModuleInternalHandle=0`；`LoDisposePenaltyModule` ∈ {0（已升级）, 1（维持诚实 stub）}，**两种都合法**，但必须与 C5 的声明一致。

---

## §3 ③ 「假进度必红 P1–P8」（成对正反腿 ＋ 必红点）

> **总则（写死）**：**反腿未红、或红而不点名（缺 `reason=`／缺 `file:` 或字段名）⇒ 该条判不成立**；**反腿必须在副本文档上跑**，`git status --porcelain` 不得出现被改的仓内件。

| # | 假形式 | 正腿（必绿） | 反腿（**必红并点名**） | 必红点（断言字段） |
|---|---|---|---|---|
| **P1** | **只改计数不改行为**（改 `pts-gap-decl.txt`／白名单凑数字） | 真实现 ⇒ C8 的 `LoGetPenaltyModuleInternalHandle` 命中 ＝ **0** | 只改声明/计数件 ⇒ 必报 **`FAIL reason=decl-vs-live-mismatch`** | `nm` 逐名命中 ∧ 声明件；不一致 ⇒ 红 |
| **P2** | **`return 0` 无副作用** | 真实现 ⇒ 自检在"未实现/已实现"两态判词**不同** | 把该入口换成"清空 + `return 0;`"的**副本** ⇒ 自检**必红**并点名（如 `reason=internal-handle-null-after-none`） | 返回 0 时 `*penaltyModuleInternalHandle` **仍为 NULL** ⇒ 红 |
| **P3** | **假成功：`NULL`/伪造入参也返回 0** | 真实现 ⇒ 对 `NULL`／未知句柄**返回非 0** | 副本上让它对 `NULL` 也返回 0 ⇒ 必报 **`FAIL reason=null-handle-accepted`** | 该入口对 `NULL` 的返回值与出参 ⇒ 红 |
| **P4** | **把 `entry=` 改成硬编码常量名**（改仪表） | 真实现 ⇒ C4 的具名可**回溯上游声明** | 副本上写死常量 ⇒ 必报 **`FAIL reason=entry-name-not-backtraceable`** | `grep -n 'EntryPoint *= *"<名>"' upstream/wpf/**` 命中 0 ⇒ 红 |
| **P5** | **跨趟拼读数** | 真实现 ⇒ C7 的 `same=yes` | 用**上一趟** `leg_*.env`（如 `shim=3bd193e54785b5db` 那一趟）配本趟 `.so` ⇒ 必报 **`FAIL reason=cross-run-pairing`** | `so16=`／`DEV shim=`／现盘 `.so` 三值不等 ⇒ 红 |
| **P6** | **台账非零但前沿不动** | 真实现 ⇒ C3 的 `after ≠ LoGetPenaltyModuleInternalHandle` | 只让台账涨而前沿仍停在同名 ⇒ 必报 **`FAIL reason=ledger-nonzero-frontier-unchanged`** | `PTSGAP_FRONTIER` 的 `before == after` 同名 ⇒ 红（`native_gap>0` 不免除） |
| **P7** | **🔴 恒绿自检没有牙**（第二步暴露） | 自检**能证伪**（P2/P3） | 把自检改成恒 `return 1;` ⇒ **三档探针全绿** ⇒ 必报 **`FAIL reason=selfcheck-no-teeth`**（即：正极/负极/边界三档**判词全同** ⇒ 红） | 三档 `rc`／`diag` **完全相同** ⇒ 红 |
| **P8** | **🔴 观测镜把 64 位指针塞进 `int` 域（第二步实测的假红）** | 指针量走**专用指针域**（现取 `wpf_pts_jmp` 已有 `ptr0`／`ptr1`，见 `win32_pts.c:358-362` 的逐字教训） | 把 internal handle 写进 `int` 域再与真指针比 ⇒ 必报 **`FAIL reason=pointer-truncated-in-int-field`**（该断言**必须**能红；**不许**让它变成"恒不等 ⇒ 假红"而无人识别） | 自检里"真指针 vs 镜里取回值"**恒不等** ⇒ 红**且点名该域** |

**特别说明 P8 的"两向都要咬住"**：第二步现场是「截断 ⇒ 恒不等 ⇒ **假红**」；本判据要求的是「**同一对拍必须有牙**」：正腿（指针走指针域）**必绿**，反腿（塞进 `int` 域）**必红并点名**。**如果反腿不红**（对拍恒绿）或**正腿恒红**（截断导致），两种都判该条**不成立**。

---

## §4 ④ 成对读数清单（before／after ＋ 每面「零回归」判法）

| # | 面 | 取哪个文件的哪个字段 | before（本件现取） | after 期望形状 | 零回归判法 |
|---|---|---|---|---|---|
| R1 | 导出面 | `exports.txt` 行数；`nm … \| grep -c .` | **565 / 565** | 两者**相等** ∧ **≥ 565** | 不相等 ⇒ 红；**下降** ⇒ 红 |
| R2 | 缺口面 | `check-shim-coverage.py` 的 `[PresentationNative_cor3.dll] N 条` ＋ `Lo*` 数 | **96** ／ `Lo=15` | **按实际归因**（纯行为补全 ⇒ 不变） | 变了 ⇒ **必须逐条点名**"哪一条进出"，否则红 |
| R3 | 三格 | `PTSGAP=` 的 `tool/dead/artifact/ops/impl` | **96/11/1/84/90** | 成对给出；`dead`／`artifact` **不变** | `artifact` 变大 ⇒ 逐条点名（账目漂移） |
| R4 | 前沿 | `PTSGAP_FRONTIER` 的 `after=` | `after=LoGetPenaltyModuleInternalHandle@3` | **≠ `LoGetPenaltyModuleInternalHandle`** | 同名 ⇒ P6 红 |
| R5 | `entry=` 面 | `app_g1.log` 直方图 | **3** `LoGetPenaltyModuleInternalHandle` ＋ **1** `LoDisposePenaltyModule`；`unknown=0` | 主跳名计数**下降**；`unknown` **不增** | `unknown` 增 ⇒ **仪表退化（回归）** |
| R6 | 两页症状 | `leg_{23,24}.env` 的 `LEG`／`NAMED`／`DEV` | `alive=yes app_rc=143 magenta=49592/54182`；`native_gap=2 native_err=-10000`；`shim=461e5557bd7dd571` | `alive=yes` ∧ `app_rc∉{134,139}` ∧ `magenta ≥` 阈值 ∧ `native_gap ≥ 2` ∧ `shim=` ＝ 本趟 `.so` | `alive` 变／`app_rc∈{134,139}`／`magenta` 掉阈值／`shim` 不匹配 ⇒ **红** |
| R7 | 同趟性 | `so16=`／`DEV shim=`／现盘 `.so`／`carrier_sha16=`／`app_g1.log` `sha16` | **yes**（`461e5557bd7dd571` 三处同值；`carrier=eed6c1558509dd94` ＝ 载体） | **仍是 yes** | 任一不等 ⇒ 红（P5） |
| R8 | 九位 | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 九位行／`BASELINE tier=` | 现基线见 `docs/CURRENT-STATE.md:9`（`gen=#80`／`b27ff6332f263495`） | **只有 `win32shim` 位**按声明位移 | 出现**未声明**位位移 ⇒ 红 |
| R9 | 释放相位 | `PTS_GAP entry=LoDisposePenaltyModule` 行的 `seq=` 与 `entry=` 计数 | `seq=5`，`1` 次（**终结器路径**） | 相位**仍应在清理期**；来源（终结器 vs 显式 Dispose）**如实声明** | 若它**在功能路径**上出现（早于 `LoGetPenaltyModuleInternalHandle`）⇒ 需点名解释，否则红 |

---

## §5 ⑤ 纪律第 `30` 条（在册）对本判据的硬约束

**在册确认（现取）**：`build/MilBridge/HANDOFF-NEXT.md` 有该条 —— 块头与口径句（内容锚「dated 纪律追加 · 第 `30` 条（**进程内状态敏感仪器**的调用史约束）」）。**口径句要点（逐字）**：凡引用**进程内状态敏感**的仪器读数（自检／探针／计数器镜像／`live` 计数），必须**同趟**给出**三格**：① **进程新鲜度**（fresh 进程，或同进程 ＋ **已发生的关键调用序**）② **关键前置量**（该读数所依赖的那些计数/`live` 的**当时值**）③ **判词**（`rc`／`diag`）。

**本判据的硬约束（写死）**
1. **凡引用自检/探针读数（C2 的镜、C5 的计数、P2/P3/P7/P8 的自检对拍），同趟必须给三格**：① fresh **或** 已发生的关键调用序（**逐条列出**：建过几个 LS 上下文／几个模块句柄、是否写过 `LoSetDoc`／`LoSetBreaking`、是否调过 `LoAcquirePenaltyModule`／`LoGetPenaltyModuleInternalHandle`、是否销毁）② 该读数依赖的**当时值**（`loc_live`／`g_pts_pen_sets`／`g_pts_pen_rejected`／`g_pts_jmp_n`／`calls`／`seq` 等）③ `rc` ＋ `diag`。**缺任一格 ⇒ 该读数不许当证据。**
2. **调用序约束**：**正腿必须在 fresh 进程里跑**；带历史腿必须**独立进程**，且历史**逐条可复现**。
3. **两种误导形态（写清，供复核件识别）**：
   - **带历史的红 ＝ 假红**：同一 `.so` 在 fresh 与带历史两种前置下**判词不同**，成因是**调用序**（例如"先建过活上下文"会让断言绝对值 "`loc_live == 1`" 落空）。
   - **fresh 的绿 ＝ 假绿**：fresh 只证"该前置下没红"，**不**证"与该对象绑定的状态真落了" —— 后者要**权威对象**（模块/上下文对象本身）与被读**镜像**的**逐字段对拍**（§1.4 的④）。
   ⚠️ 该条在册文本里给过一对现场读数（fresh 与带历史的不同 `rc`/`diag`）；**那一对数字我未复算**（复算需跑探针，本件硬边界禁止）⇒ 见 §6-N1。

---

## §6 ⑥ `NOINFO` 预期（**此刻必然拿不到**；逐条给"消掉需要什么"）

1. **纪律第 `30` 条那对现场读数（fresh vs 带历史）的独立复算**：`NOINFO(reason=复算需 dlopen 仓内 `.so` 并调自检/探针，本件硬边界禁止跑探针)`. **消掉需要**：实现件/复核件在 fresh 进程跑一次并给三格。
2. **补完主跳后"链上下一个被撞入口"的具体名字**：`NOINFO(reason=只能运行期逐步取证；本件不跑腿且不许预判名字)`. **消掉需要**：实现件补完后跑一趟冷启腿读 `app_g1.log` 的 `entry=` 与 `PTS_GAP` 行。（**预期形状**已写在 §1.3，但那是我从代码推的，**不是**运行期读数。）
3. **`CreateDocContext` 在本步是否真被走到、以及它抛出的 `PtsException` 落在哪一层被接住**：`NOINFO(reason=需运行期证据；本件只读)`. **消掉需要**：同趟腿证据里出现 `PTS_GAP entry=CreateDocContext` 行（或证明没出现），并给出接住它的托管层文件:行。
4. **`penaltyModuleInternalHandle` 的真实语义**（下游谁用它、`ContextInfo.ptsPenaltyModule` 被 native 侧怎么消费）：`NOINFO(reason=本仓只有 P/Invoke 声明与调用点，没有 LS 的 C 侧规格/结构体定义)`. **消掉需要**：LS 规格或"以下游实际使用形状为准"的具名声明。
5. **`TextPenaltyModule` 终结器在本步之后是否还会在本进程里被跑**（取决于 `:534` 是否抛 ⇒ `:542` 是否执行）：`NOINFO(reason=需运行期证据；`entry=` 面只能给"被调了几次"，给不出"哪条路径调的")`. **消掉需要**：实现件给出 `GC.SuppressFinalize` 执行与否的机器证据（例如计数器/具名行），或给出终结器路径的具名观测。
6. **新自检的调用路径**（谁 `dlsym` 它、由哪一步跑、打哪一行机读键）：`NOINFO(reason=仓内未现取到调用点；本件只能证"已导出")`. **消掉需要**：实现件给调用点，或把它接进一条门禁步（键名与步名同趟写死）。
7. **`MAGENTA_FLOOR` 的权威值**：`NOINFO(reason=本件只读、未取该常量；判据一律写"门禁自带阈值")`. **消掉需要**：`grep -n 'MAGENTA_FLOOR' build/MilBridge/tools/pts-pages-guard.sh` 的现取值。
8. **"两页真排版"的判据**：`NOINFO(reason=本步只是补一个入口；LS 族另有 `Lo=15` 条、PTS 族 `Fs=66` 条等)`. **消掉需要**：后续各跳落地后的症状面成对读数。

---

## §7 ⑦ 载体与边界遵守自证

- **载体**：`build/MilBridge/P1-w8-step3-criteria.md`（新建；UTF-8；模式 **644**；**首记号不是 `# ⏪ `**；末行自带可复算自报口径）。
- **只读**：本件全部命令为 `grep`／`sed`／`awk`／`cat`／`nm`／`sha256sum`／`wc`／`git log`／`git status` ＋ 两个**纯读**自检器（`check-shim-coverage.py`／`pts-gap-count-check.sh`（后者件头自称纯读）＋ `pts-pages-guard.sh --legs`（纯读判据端））。**零 `dotnet build`、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
- **未改任何其它件**：档 A `git status --porcelain` 逐行原样 ——
```
# ts=2026-09-29T01:00:26.606+0800
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/arm_A/
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/device/
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/five_post_g1.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/five_pre_g1.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/session.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/shots/
?? src/tests/
```
⇒ 上述**全部为他人**未跟踪件；**无 `M` 行** ⇒ 本件落盘前工作树**没有**任何被改动件。本件是本次唯一新增件。
- **未引既有报告当证据**：两件同类前例只作**形制参照**（分界句口径沿用时标明出处），其**读数一条未抄**；本件所有读数（`.so`／`exports.txt`／`nm`／名册 13 名／缺口面 96 与 `Lo=15`／三格 96-11-1-84-90／前沿与 `carrier_sha16`／`app_g1.log` 的 `entry=` 直方图与两行 `PTS_GAP`／两腿 `LEG`·`NAMED`·`DEV`／守卫两行／上游两处签名与两个调用点／native 两处 stub 与 `wpf_pts_jmp` 指针域／自检的格4 保存-复原）**都是本趟现取**。
- **末行自报口径当场可复算**：见末行。

---

### 结语（自包含）

- **① 判断（写死）**：**主跳 ＝ `LoGetPenaltyModuleInternalHandle`（本轮必做）**；**`LoDisposePenaltyModule` 不必升级、但不许回退**（它已是已导出的诚实 stub，且托管侧**丢弃其返回值**）。**本步会第一次打开一条托管侧路径**：`:534 DangerousGetHandle()` 成功 ⇒ `:535/536/537/542` 首次执行 ⇒ **`:548 PTS.CreateDocContext` 第一次被走到**（台账十名之一）；**收尾同伴 ＝ `DestroyDocContext`（`:416`／`:488`）＋ `TextPenaltyModule.Dispose`（`:421`／`:493`，必须后于前者）**。**分界句**：`return None` 不是证据，证据是"与该对象绑定、可被独立读取的状态变化"。
- **② 判据 C1–C8**：构建／**缺口面（按实际归因，不硬凑数字）**／台账-前沿（主证据）／`entry=`／**释放同伴不得回退**／两页症状／**同趟性**／stub 面（`return wpf_pts_gap("LoGetPenaltyModuleInternalHandle")` 1→0）。每条给可跑 verify、字段、期望形状；**不预判名字**。
- **③ 假进度必红 P1–P8**：含**恒绿自检没有牙**（P7）与**观测镜 64 位指针塞 `int` 域 ⇒ 截断 ⇒ 假红**（P8，两向都要咬住）。**反腿未红或红而不点名 ⇒ 该条判不成立**；反腿必须在**副本文档**上跑。
- **④ 成对读数 R1–R9**（含每面零回归判法与**释放相位面 R9**）。
- **⑤ 纪律第 `30` 条**：在册；本判据凡引用自检/探针读数**一律要求三格 ＋ 调用序**，**正腿必须 fresh**、带历史腿独立进程，并写清两种误导形态。
- **⑥ NOINFO 8 条**，各带"消掉需要什么证据"。

---

`P1-W8-STEP3-CRITERIA 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ d36092342d71b0e1（口径＝末行之前的全文；末行＝本行）`
