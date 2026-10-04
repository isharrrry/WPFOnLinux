# P1-W12 · W8 第一步（`LoSetDoc`／`LoSetBreaking`）的**预登记判据** —— 诚实边界 / 假进度必红 / 成对读数清单

> **本件是判据件（先写），不是实现件**：本件**不做**任何产品改动，供随后的**实现件**与**独立复核件**当契约用。
> **一切读数由我现取**；命令与输出**原样**贴在下面。`build/MilBridge/P1-ls-family-recon.md`（我自己的上一件）只当**线索**，其读数我**全部重算**（并在 §1.5 更正其中一处**结论性错误**）。
> **边界（硬）**：只读仓树；唯一写入 ＝ 本件；**未** `dotnet build`、**未**跑腿、**未**占显示位、**未**跑整趟门禁、**未** `git add/commit/push`；未改任何判据件／产品件／`docs/ROUTES.md`／`HANDOFF-NEXT.md`。
> **读取时刻**：`ts=2026-09-28T23:00:57.863+0800`（起点）→ `2026-09-28T23:01:55.747+0800`（末取）。

---

## §0 快照（现取）

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | `7435527` | `git log --oneline -1` |
| 工作树 | 12 行（` M build/MilBridge/HANDOFF-NEXT.md`／` M build/MilBridge/tools/defect-registry-declared.tsv`／` M build/MilBridge/tools/pts-pages-guard.sh`／` M samples/WpfFeatureProbe/KNOWN-DEFECTS.md` ＋ 8 个 `??`；**全部为他人**在飞件或我的上一件载体） | `git status --porcelain` |
| 权威 `.so` | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ `2a5165700a8c8579`／337,240 B | `sha256sum` |
| 导出清单 | `src/WpfGfx.Linux.Native/bin/exports.txt` ＝ `1ccaeb8c96eb1abf`／**557** 行 | `sha256sum` / `wc -l` |
| 覆盖自检器 | `check-shim-coverage.py` ＝ `b07cce3f2e7cf51a` | `sha256sum` |
| PTS 桩件 | `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ `bdf6e9f8a1b61eae` | `sha256sum` |
| 腿证据（现盘，`arm_A`） | `build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/leg_23.env` 现读：`LEG k=23 alive=yes app_rc=143 magenta=50468 colors=844 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae=140234 ink=428003` ＋ `NAMED managed_unavail=1 err=-10000 native_gap=0 native_err=-` ＋ `DEV x_up=yes five_stable=yes shim=2a5165700a8c8579 pf=b9a4f3a0e48e688d` | `cat` |

---

## §1 ① 增量定义（可实现的**诚实边界**）

### 1.1 上游签名与调用点（原文）

`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs:1470`：
```
        [DllImport(DllImport.PresentationNative, EntryPoint="LoSetDoc")]
        internal static extern LsErr LoSetDoc(
            IntPtr                  ploc,
            int                     isDisplay,
            int                     isReferencePresentationEqual,
            ref LsDevRes            deviceInfo
            );
```
同件 `:1464` 的紧邻邻居（本增量可同趟做）：
```
        [DllImport(DllImport.PresentationNative, EntryPoint="LoSetBreaking")]
        internal static extern LsErr LoSetBreaking(
            IntPtr                  ploc,
            int                     strategy
            );
```
`LsDevRes`（同件 `:967`，原文）＝ 设备分辨率四字段：
```
    internal struct LsDevRes
    {
        public uint   dxpInch;
        public uint   dypInch;
        public uint   dxrInch;
        public uint   dyrInch;
    }
```
⇒ **参数语义**：`ploc` ＝ `LoCreateContext` 建立的 LS 上下文句柄；`isDisplay` ＝ 是否用于显示；`isReferencePresentationEqual` ＝ 参考设备与呈现设备是否同一；`deviceInfo` ＝ 四个"每英寸点数/分辨率"（上游调用点注释逐字：「We choose to cheat LS to think that our unit is twips.」）。

调用点 `…/textformatting/TextFormatterContext.cs:347-365`（原文）：
```
        internal void SetDoc(
            bool            isDisplay,
            bool            isReferencePresentationEqual,
            ref LsDevRes    deviceInfo
            )
        {
            Invariant.Assert(_ploc != System.IntPtr.Zero);
            LsErr lserr = UnsafeNativeMethods.LoSetDoc(
                _ploc,
                isDisplay ? 1 : 0,
                isReferencePresentationEqual ? 1 : 0,
                ref deviceInfo
                );

            if(lserr != LsErr.None)
            {
                ThrowExceptionFromLsError(SR.Format(SR.SetDocFailure, lserr), lserr);
            }
        }
```
⇒ **托管侧唯一的判错** ＝ `lserr != LsErr.None` ⇒ 抛。**没有**对"文档参数是否真被采用"的第二道断言。

### 1.2 「最小可辩护实现」vs「假成功」的分界（正面回答）

**分界句（本增量的判据基石）**：
> **`return 0`（`LsErr.None`）本身不是证据；证据是「这次调用在该进程内留下了**可被独立读取**的、与该 `ploc` 绑定的状态变化」。**

- **算「假装成功」**：返回 `LsErr.None`，但**没有**任何可观测副作用 —— 既不把 `isDisplay`／`isReferencePresentationEqual`／`deviceInfo` 四字段落到上下文对象上，也不增任何计数，也没有任何机器可读面能证明"它真收了参数"。理由：`SetDoc()` 的判错只有 `lserr`，返回 0 会让 `Init()` 一路走到底（`:155 SetBreaking`）、`Init()` 返回、`PtsCache.Linux.cs:533` 继续 —— **链路"看起来前进了"，但下游若真跑起来，拿到的是"从未被设置过的文档参数"** ⇒ 症状从"报错"变成"排版结果错/静默偏差"，**更难发现**（本仓既有的"假绿方向"口径同族）。
- **算「最小可辩护」**：① **句柄身份校验**（只认 `LoCreateContext` 自己发过、且仍在册的 `ploc`；未知/伪造句柄 ⇒ **失败返回**且不读其内容 —— 与 `LoDestroyContext` 的四条拒绝面同形）；② **参数真落盘**（四个 `uint` 与两个 `int` 落到该上下文对象上，**不是**进程级全局单例）；③ **计数**（成功/拒绝各一个计数，供 `WpfLinuxWin32_*SelfCheck()` 断言）；④ **一条机器可读自检函数**（照既有 `WpfLinuxWin32_EscStringSelfCheck` 的形状，见 §1.3），**且它在"未设置"与"已设置"两态上给出不同结论**。
- **⚠️ 不计入"辩护"的东西**：把 `isDisplay` 等参数**丢掉不用**；把 `deviceInfo` 只**存不校**（`dxpInch==0` 这类明显无效值也不拒）；把状态存到**进程级全局变量**（第二个上下文会串味）。

### 1.3 本地 native 的**既有诚实做法**（逐条引文件:行，全为我现取）

| 先例 | 证据位 | 诚实点（逐字要点） |
|---|---|---|
| **真对象 ＋ 拒绝面**：`LoCreateContext` | `src/WpfGfx.Linux.Native/src/win32_pts.c:284` | 建**真对象**（有魔数 `WPF_PTS_LOC_MAGIC`）、进登记表、返回 0 ＋ `*ploc` 非空 |
| **真销毁 ＋ 四条拒绝面**：`LoDestroyContext` | `win32_pts.c:304-319` | 「未知句柄的**内容一个字节都不读**」；`NULL`／未登记／魔数不符／表空 ⇒ 一律失败返回；**先失效再 free** ⇒ 重复销毁必被拒 |
| **诚实缺口（不假装成功）**：`LoAcquirePenaltyModule` | `win32_pts.c:321-326` | **已导出、但**出参清 `NULL` ＋ `return wpf_pts_gap("LoAcquirePenaltyModule")`（＝ **-10000**）；**不返回 0** |
| 同上：`LoGetPenaltyModuleInternalHandle` | `win32_pts.c:328-333` | 同上形 |
| **台账 ＋ 有界打印**：`wpf_pts_gap()` | `win32_pts.c:139-162` | 计一次数（`g_pts_calls[idx]++`）＋ 打 `PTS_GAP entry=%s seq=%d err=%d calls=%d`（**有界**，超界打 `ledger=truncated`） |
| **真实现 ＋ 自检**：`LoGetEscString` | `src/WpfGfx.Linux.Native/src/win32_classification.c:171`（实作）／`:183`（自检） | 自检**逐字段断言**（六串非空、落在私用区 `0xE000–0xF8FF`、两两不同）⇒ 不给"看起来对"留口子 |
| **自检形状总范例**：`WpfLinuxWin32_PtsGapSelfCheck()` | `win32_pts.c:411` | 自检**敢改状态 ⇒ 必须保存/复原**（`save_calls`／`save_seq`／`save_printed`／各计数），并断言"自检不许改变可观测状态"；且**投毒出参**防止"恒绿假牙"（`:429` 一带逐字：「3 个新入口**各自一个先被投毒的出参**：否则…断言**恒不成立**（恒绿假牙）」） |
| 自检函数**可被外部调用**（已导出） | `src/WpfGfx.Linux.Native/bin/exports.txt:479/481/492/495` | `WpfLinuxWin32_ClassificationSelfCheck`／`…_EscStringSelfCheck`／`…_PtsGapCount`／`…_PtsGapSelfCheck` |

⇒ **既有诚实做法的三条硬规矩（本增量必须照抄）**：**(a)** 未实现 ⇒ **返回非 0（`-10000`）并清出参**，**绝不返回 0**；**(b)** 真实现 ⇒ 真状态 ＋ 拒绝面 ＋ 计数；**(c)** 无论哪种 ⇒ **一条机器可读自检**，且**自检自身要能证伪**（投毒出参／两态不同结论）。

### 1.4 本增量**必须做什么** / **明确不做什么**（非目标）

**必须做（本增量 = W8 第一步）**
1. `LoSetDoc` 与 `LoSetBreaking` **两个入口都进入导出面**（`.so` 里可 `nm -D` 查到；`check-shim-coverage.py` 的缺口面里消失）。
2. 二者**都不返回 `-10000`**：`LoSetDoc` 需**真收参数**（§1.2 的四条）；`LoSetBreaking` 至少**真收 `strategy`**（同形：句柄校验＋落盘＋计数＋自检）。
3. 各带一条**机器可读自检**（形状照 `WpfLinuxWin32_EscStringSelfCheck`／`PtsGapSelfCheck`），**且两态可区分**。
4. **同趟**把 `WpfLinuxWin32_PtsGapSelfCheck()` 里"其余 N 条 stub 返回值必须都 == -10000"这类**既有断言跟着改**（新增的真实现**不再**属于 stub —— 不随之改就是**自检恒红**或**恒绿**）。
5. 导出计数／缺口面／`entry=` 面／两页症状面的**成对读数**（§4）。

**明确不做（非目标，写死防过读）**
- **不**实现 LS 排版本身（不做断行、不做行/子行生成、不做命中测试、不做显示）—— 那是 `LoCreateLine`／`LoCreateBreaks`／`LoEnumLine`／`LoDisplayLine` 等**后续跳**。
- **不**承诺"两页真排版"（本增量至多把前沿**位移一跳**）。
- **不**为"让 `entry=` 变好看"去改应用侧的记录逻辑（那是**改仪表**，不是改能力）。
- **不**动 `LoAcquirePenaltyModule`／`LoGetPenaltyModuleInternalHandle` 的**诚实缺口**语义（它们今天必须继续返回 `-10000`，见 §1.5 的更正）。

### 1.5 🔴 **对我自己上一件（`t75` §3）的更正**（现取重算后成立）

`t75` §3 写「③ `LoAcquirePenaltyModule` **已导出、不补**」。**这只答了"会不会 ENFE"，没答"它返回什么"** —— 我现取重算：

```
$ sed -n '321,326p' src/WpfGfx.Linux.Native/src/win32_pts.c
int LoAcquirePenaltyModule(void *ploc, void **penaltyModuleHandle)
{
    (void)ploc;
    if (penaltyModuleHandle) *penaltyModuleHandle = NULL;
    return wpf_pts_gap("LoAcquirePenaltyModule");
}
$ sed -n '23,32p' upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/TextPenaltyModule.cs
        internal TextPenaltyModule(IntPtr ploc)
        {
            IntPtr ploPenaltyModule;
            LsErr lserr = UnsafeNativeMethods.LoAcquirePenaltyModule(ploc, out ploPenaltyModule);
            if (lserr != LsErr.None)
            {
                TextFormatterContext.ThrowExceptionFromLsError(SR.Format(SR.AcquirePenaltyModuleFailure, lserr), lserr);
            }
            …
```
⇒ 该入口**已导出（不 ENFE）但返回 `-10000`** ⇒ `TextPenaltyModule` 构造**会抛**。因此：

| 目标 | 最小集合（更正后） | 为什么 |
|---|---|---|
| **让 native 台账真非零** | **`LoSetDoc` ＋ `LoSetBreaking`** | 两者都补 ⇒ `Init()` 能跑完 ⇒ `PtsCache.Linux.cs:533` 的 `GetTextPenaltyModule()` **才会被执行**，它调的 `LoAcquirePenaltyModule` **是台账十名之一**、会 `++g_pts_calls[idx]` 并打 `PTS_GAP` ⇒ **台账非零**（在**补完这两条**时就发生，**不需要**任何第三步） |
| 让链路走到 **`PTS.CreateDocContext`（`PtsCache.Linux.cs:548`）** | 上述两条 **＋ `LoAcquirePenaltyModule` 必须成功（返回 0）** | 不成功 ⇒ `TextPenaltyModule` 构造抛 ⇒ `:548` **永不到达** |
| **让两页真排版** | 远不止（LS 族另有 20 条缺失 ＋ PTS 族 66 条…） | §4「零回归」面只断言**不劣化**，不承诺本增量达成 |

**⇒ 对 W8 判据的两条后果（必须写进契约）**：
1. **存在"台账非零但一步没真前进"的可用形态** —— 只补 `LoSetDoc`＋`LoSetBreaking` 就够把台账点亮。⇒ **「台账非零」不构成"真前进"的证据**，判据**必须**另立"前沿位移"的成对面（§3-P3）。
2. **本增量的"下一个被撞的入口"预判（不预判名字，只给形状）**：补完两条后，`entry=` 面**必然**变成**另一条**入口名（§5 列 NOINFO：**我不预判它是谁**），而**台账会同时点亮**。⇒ 判据要求**同趟**给 `entry=` 面 + 台账面**同一趟**的成对值（§3-P4 的"同趟"条款）。

---

## §2 ② 判据（逐条 objective / acceptance / verify；**不预判任何名字结果**）

> 通用口径：**每条 verify 必须"捕获式取 `rc`"**（`cmd >out 2>err; echo $?`）—— 本会话已确立（从管道末段取 `$?` 会把真 FAIL 读成 0）。
> 通用反过读句：**任何一条"绿"都不许被读成本增量达成了"两页真排版"。**

### C1 构建与生效面：`.so` 真重建且九位只按声明位移
- **objective**：本增量的源码改动**真的进了** `libwpfwin32.so`（不是只改了源文件）。
- **acceptance**：`bash src/WpfGfx.Linux.Native/build-shim.sh --symbols >out 2>err; echo $?` ⇒ `rc=0`；`src/WpfGfx.Linux.Native/bin/exports.txt` 的**行数**与 `nm -D --defined-only … | awk '{print $3}' | grep -c .` **相等**；`libwpfwin32.so` 的 `sha16` **与 before 不同**；九位中**只有** `win32shim` 位位移（其余按本波声明表逐条点名）。
- **取哪个文件的哪个字段**：`src/WpfGfx.Linux.Native/bin/exports.txt`（新的导出清单）／`libwpfwin32.so`（新 `sha16`）／`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的九位行（`bridge`/`pc`/`pf`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`hbtextline`/`dwf`）。
- **verify（原文）**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash src/WpfGfx.Linux.Native/build-shim.sh --symbols >/tmp/c1.out 2>/tmp/c1.err; echo "rc=$?"; a=$(nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | grep -c .); b=$(wc -l < src/WpfGfx.Linux.Native/bin/exports.txt); echo "nm=$a exports=$b equal=$([ "$a" = "$b" ] && echo yes || echo NO)"
```
- **期望形状**：`rc=0` ∧ `nm` 与 `exports` 行数**相等** ∧ 两值**都 > 557**（增量后必须更大）。**不预判**具体数字（本件不跑构建）。

### C2 缺口面位移：两个入口从"会 ENFE"名单里消失
- **objective**：`LoSetDoc`／`LoSetBreaking` **真的**从"会抛 `EntryPointNotFoundException`"的集合里消失。
- **acceptance**：`python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier mapped` 的输出里，`^  PresentationNative_cor3\.dll  (LoSetDoc|LoSetBreaking) ` 的命中数 **before > 0 → after = 0**；且 `[PresentationNative_cor3.dll] N 条` 的 `N` **减少恰好等于本次真正补上的入口数**（不是"减少多少都行"）。
- **取哪个字段**：工具 stdout 的两行 —— 明细行 `^  PresentationNative_cor3\.dll  <名>  …` 与汇总行 `  [PresentationNative_cor3.dll] N 条`。
- **verify（原文）**：
```
python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier mapped >/tmp/c2.out 2>/tmp/c2.err; echo "rc=$?"; grep -cE '^  PresentationNative_cor3\.dll  (LoSetDoc|LoSetBreaking) ' /tmp/c2.out; grep -E '^  \[PresentationNative_cor3\.dll\] [0-9]+ 条' /tmp/c2.out
```
- **期望形状**：`rc=0`；第一个 `grep -c` **＝ 0**；明细里**不再**出现这两个名字。

### C3 台账面：native 台账**真非零**，且**同趟**给出前沿名
- **objective**：`PTS_GAP` 台账被真的点亮（而不是"离线把数字改大"）。
- **acceptance**：`bash build/MilBridge/tools/pts-gap-count-check.sh >out 2>err; echo $?` ⇒ `rc=0`（其 PASS 判据自带）；其 `PTSGAP=PASS` 行里 `tool/ops/impl` **三格成对给 before/after**；`PTSGAP_FRONTIER` 行**同趟**给出 `before=<名>@<calls>`／`after=<名>@<calls>`，且 **`PTSGAP_FRONTIER_STATE` ≠ `UNNAMED`**（＝载体里真出现具名前沿）。
- **取哪个字段**：`pts-gap-count-check.sh` 的 `PTSGAP=` 行（`tool=/dead=/artifact=/ops=/impl=/so16=/exports=`）与 `PTSGAP_FRONTIER`／`PTSGAP_FRONTIER_STATE` 两行；其载体源 ＝ `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` 的 `entry=` 面（工具自报 `carrier_sha16=`）。
- **verify（原文）**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/pts-gap-count-check.sh >/tmp/c3.out 2>/tmp/c3.err; echo "rc=$?"; grep -E '^(PTSGAP|PTSGAP_FRONTIER|PTSGAP_FRONTIER_STATE)=' /tmp/c3.out
```
- **期望形状**：`rc=0`；`PTSGAP=` 三格**成对**；`FRONTIER_STATE` **不是** `UNNAMED`。**不预判** `after=` 后面那个名字。

### C4 冷启腿的 `entry=` 面：**位移**（而不是"仍然同一条"）
- **objective**：一趟冷启腿后，应用侧自报的 `entry=` **确实换了一条**（＝真前进一跳），且**不是**被硬编码成常量名。
- **acceptance**：证据目录里 `app_g1.log` 的 `grep -o 'entry=[A-Za-z0-9_]*' … | sort | uniq -c` **after** 与 **before** 相比：① `unknown` 的**计数不增加**；② 出现的**具名集合**与 before **不同**（before 是 `LoSetDoc`；after 必须是另一条**在 `LineServices.cs` 或其邻件里有真实 `[DllImport]` 声明**的名字 —— 用 `grep -n "EntryPoint=\"<该名>\"" upstream/wpf/…` 现取核对）；③ 该名字**不在**运行前人工写死在应用/仪器里的常量集合里（核对法见 §3-P4）。
- **取哪个字段**：`<证据目录>/app_g1.log` 的 `entry=`；与上游 `[DllImport]` 声明的对拍。
- **verify（原文）**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=<证据目录>; grep -o 'entry=[A-Za-z0-9_]*' "$D/app_g1.log" | sort | uniq -c; grep -c 'entry=unknown' "$D/app_g1.log"
```
（腿本身由实现件跑：`bash build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh <证据目录>`——**本件不跑**。）
- **期望形状**：具名集合**变化**且**每条具名都能在上游找到声明**。

### C5 两页症状面：**不劣化**（`alive`／`app_rc`／`magenta`／台账列）
- **objective**：本增量不把两页从"页级可见降级"推回"进程死"。
- **acceptance**：`bash build/MilBridge/tools/pts-pages-guard.sh --legs <证据目录> >out 2>err; echo $?` ⇒ `rc=0`；两腿的 `LEG … alive=yes` 且 `app_rc ∉ {134,139}`；`magenta ≥ MAGENTA_FLOOR`（门禁自带阈值）；`PTS_G10_NAME` 行**在位**；每腿 env 里的 `NAMED … native_gap=<n>` 的 `n` **after ≥ before**（台账被点亮）。
- **取哪个字段**：`<证据目录>/leg_23.env`／`leg_24.env` 的 `LEG` 行（`alive=app_rc=magenta=colors=ae=ink=`）、`NAMED` 行（`managed_unavail=err=native_gap=native_err=`）、`DEV` 行（`x_up=five_stable=shim=pf=`）；`pts-pages-guard.sh` 的 `PTS_GUARD=`／`PTS_G10_NAME=`／`PTS_G10_ROSTER_SRC=` 行。
- **verify（原文）**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=<证据目录>; bash build/MilBridge/tools/pts-pages-guard.sh --legs "$D" >/tmp/c5.out 2>/tmp/c5.err; echo "rc=$?"; grep -E '^(PTS_GUARD|PTS_G10_NAME|PTS_G10_ROSTER_SRC)=' /tmp/c5.out; grep -E '^(LEG|NAMED|DEV) ' "$D"/leg_23.env "$D"/leg_24.env
```
- **期望形状**：`rc=0`；两腿 `alive=yes`；`native_gap` **变为 > 0**。**不预判**绿/红以外的具体数值。

### C6 自检面：新入口**各带一条能证伪的自检**
- **objective**：新入口的"诚实"有机器可读的自证，且该自证**不是恒绿**。
- **acceptance**：新入口对应一条**已导出**的 `WpfLinuxWin32_*SelfCheck`（形态照 `…_EscStringSelfCheck`：逐字段断言 + 两两不同／边界检查）；**两态可选**（"未设置"vs"已设置"给出不同返回值）；且**走过一次自检后**，进程可观测状态与自检前一致（照 `PtsGapSelfCheck` 的保存/复原规矩）。
- **取哪个字段**：`src/WpfGfx.Linux.Native/bin/exports.txt` 里新自检符号的在位（`grep -n '<新自检名>'`）；该自检函数的**返回值两态**（由实现件给出探针读数）。
- **verify（原文，形状）**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && grep -c 'WpfLinuxWin32_.*SelfCheck' src/WpfGfx.Linux.Native/bin/exports.txt
```
- **期望形状**：**after > before**（现有 3 条，见 §1.3 末行）。⚠️ **调用路径（谁 dlsym 它）本件不预判** ⇒ 见 §5 NOINFO。

---

## §3 ③ 「假进度必红」（成对正反夹具 ＋ 必红点，参照 `LOC_POLARITY` 形制）

> **形制（照本仓 `LOC_POLARITY` 的用法：成对正反腿 + 每条必红点逐条受断言）**：每条给 **正腿（应当绿）**、**反腿（必红且点名）**，并要求**在副本文档上跑**（不许改仓内件）。
> 下面每条都写明「**取哪个字段**／**期望形状**」，**不预判名字结果**。

| # | 假形式 | 正腿（必绿） | 反腿（**必红并点名**） | 必红点（断言的具体字段） |
|---|---|---|---|---|
| **P1** | **只改计数不改行为**（把 `check-shim-coverage.py` 的输入白名单／`pts-gap-decl.txt` 改一改，让数字好看） | 真补入口 ⇒ C2 的 `grep -c` **＝0** ∧ `nm` 里真的能查到该符号 | 在**副本**上只从 `pts-gap-decl.txt`／任何**声明件**里删名 ⇒ 判据必须报 **`FAIL reason=decl-vs-live-mismatch`**（点名"声明说没有、现场还有"或反之）| `nm -D --defined-only` 的逐名命中 ∧ 声明件行数；**两者不一致即红** |
| **P2** | **stub 返回 `None` 却无副作用**（`return 0;` 一行了事） | 真实现 ⇒ C6 自检在"未设置/已设置"**两态给出不同结论** | 用"只 `return 0`"的**副本 stub** 替换 ⇒ 自检**必红**（两态同结论）且**点名**该自检 | 自检函数的**两态返回值**；相同 ⇒ 红 |
| **P3** | **把 `unknown` 改成硬编码常量名**（应用侧改仪表让 `entry=` 好看） | 真补 ⇒ C4 的具名**能在上游找到 `[DllImport]` 声明** | 在**副本**上把应用侧 `entry=` 的取值改成写死常量 ⇒ 判据必须报 **`FAIL reason=entry-name-not-backtraceable`**（点名该常量**在上游无声明**） | `app_g1.log` 的 `entry=` 值 ∧ `grep -n 'EntryPoint="<名>"' upstream/wpf/**` 命中数；0 ⇒ 红 |
| **P4** | **导出位移与 `entry=` 面不同趟**（把两趟读数拼成一对） | 同一趟同时产出：`so16=`（来自 `pts-gap-count-check.sh` 的 `so16=` 字段）∧ `DEV … shim=`（来自该趟 `leg_*.env`）**逐位相同** | 用**上一趟**的 `leg_*.env` 配**本趟**的 `.so` ⇒ 判据必须报 **`FAIL reason=cross-run-pairing`** | `pts-gap-count-check.sh` 的 `so16=` ∧ `leg_23.env`／`leg_24.env` 的 `DEV … shim=`；**不等 ⇒ 红** |
| **P5** | **台账非零但一步没真前进**（§1.5 已证其可行性） | 真前进 ⇒ C4 的具名集合**变化** | 只补到"台账点亮"即收工 ⇒ 判据必须报 **`FAIL reason=ledger-nonzero-frontier-unchanged`** | `PTSGAP_FRONTIER` 的 `before=<名>` vs `after=<名>`；**同名 ⇒ 红**（台账 `native_gap>0` **不**免除此红） |
| **P6** | **自检恒绿** | 自检能证伪（见 P2） | 把自检改成 `return 1;` ⇒ 必须由 **既有探针**在同一趟报红 | 自检返回值的**两态**；恒 1 ⇒ 红 |

**必红的判法（统一）**：任一条反腿**未红**或**红而不点名**（缺 `reason=`／缺 `file:` 或字段名）⇒ **该条判据判不成立**，本增量**不得**关账。**每条反腿必须在副本文档上跑**（`git status --porcelain` 里不得出现被改的仓内件）。

---

## §4 ④ 成对读数清单（before／after 各面 ＋ 「零回归」判法）

| # | 面 | 取哪个文件的哪个字段 | **before**（本件现取或实现件写前取） | **after** 期望形状 | **零回归**判法 |
|---|---|---|---|---|---|
| R1 | `entry=` 面 | `<证据目录>/app_g1.log` 的 `entry=<名>` | 现取：仓外具名证据 `~/p1-ptsname/legs-after/app_g1.log`（`4db15b4c8466fadd`）＝ `2 entry=LoSetDoc`；**在册载体** `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log`（`cb0a3e5510b07790`）＝ `2 entry=unknown` | 具名集合**变化**（C4）；`unknown` 计数**不增** | 若 `unknown` 计数**增多** ⇒ 读作**回归**（仪表退化） |
| R2 | 导出计数 | `src/WpfGfx.Linux.Native/bin/exports.txt` 行数；`nm -D --defined-only … \| grep -c .` | 现取 **557 / 557** | **两者相等** ∧ 两值 **> 557** | 两者**不等** ⇒ 红（清单与 `.so` 分叉） |
| R3 | 缺口三格 | `pts-gap-count-check.sh` 的 `PTSGAP=` 行 `tool=/dead=/artifact=/ops=/impl=` | 现取 `tool=99 dead=11 artifact=1 ops=87 impl=93` | `tool` **减少**（＝至少 2，若同趟补两条）且 `ops`／`impl` 按各自口径**同向**；`dead`／`artifact` **不变** | `artifact` **变大** ⇒ 需逐条点名（"已导出却仍在声明里"＝账目漂移） |
| R4 | 两页症状 | `<证据目录>/leg_23.env`／`leg_24.env` 的 `LEG` 行与 `NAMED` 行 | 现读（`arm_A`）：`k=23 alive=yes app_rc=143 magenta=50468 …`／`NAMED managed_unavail=1 err=-10000 native_gap=0 native_err=-` | `alive=yes` ∧ `app_rc ∉ {134,139}` ∧ `magenta ≥` 门禁阈值 ∧ `native_gap > 0` | `alive` 由 `yes` 变其它／`app_rc ∈ {134,139}`／`magenta` 掉到阈值下 ⇒ **红（回归）** |
| R5 | 台账行数 | `PTS_GAP entry=…` 行数（**有界**打印，见 `win32_pts.c:139-162`）；门禁侧读 `WpfLinuxWin32_PtsGapCount()` | 现取：在册载体的 `native_gap=0`；`pts-gap-count-check.sh` 报 `FRONTIER_STATE=UNNAMED` | `native_gap ≥ 1` ∧ `FRONTIER_STATE ≠ UNNAMED` | `native_gap` **仍为 0** ⇒ 本增量**未达成**（不算回归，算**未达**） |
| R6 | 同趟性 | `pts-gap-count-check.sh` 的 `so16=` ∧ `leg_*.env` 的 `DEV … shim=` | 现取 `so16=2a5165700a8c8579`；`DEV … shim=2a5165700a8c8579`（**同值**） | 两值**逐位相同** | 不等 ⇒ **红**（P4） |
| R7 | 九位 | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的九位行／`BASELINE tier=` 行 | 现取 `win32shim` 位随本增量**必动**（产品改动） | **只有** `win32shim` 位按声明位移（其余逐条点名归因） | 出现**未声明**的位位移 ⇒ 红 |

---

## §5 ⑤ `NOINFO` 预期（**在我写判据的时刻必然拿不到**，逐条给"消掉它需要什么证据"）

1. **补完两条后"下一个被撞的入口"具体是哪一个名字**：`NOINFO(reason=只能由运行期逐步取证；本件不跑腿、不预判名字)`。**消掉需要**：实现件在补完 `LoSetDoc`＋`LoSetBreaking` 后跑一趟冷启腿并读 `app_g1.log` 的 `entry=`。
2. **`LoSetDoc` 的真实 LS 语义（写入哪几个文档参数、`fDontReleaseRuns` 一类标志的下游影响）**：`NOINFO(reason=本仓没有 LS 的规格/头文件；上游只有 P/Invoke 声明，没有 `LoSetDoc` 的 C 侧实现或结构体定义可读)`。**消掉需要**：LS 头文件／官方文档，或"以托管侧调用点的实际入参形状为准"的具名声明。
3. **`LsDevRes` 四字段的真实量纲与合法域**：`NOINFO(reason=上游只用它传 `TwipsPerInch=1440`（见 §1.1 调用点注释），没有取值域声明；`dxpInch==0` 是否应拒**我判不了**）`。**消掉需要**：LS 规格或一条在册的"非法值应当被拒"的既有先例。
4. **新自检函数的调用路径（谁 dlsym 它、由哪一步跑、打哪一行机读键）**：`NOINFO(reason=既有三个 `WpfLinuxWin32_*SelfCheck` 我现取只能证"已导出"（`exports.txt:479/481/492/495`），**仓内没有**现取的调用点（`grep -rn 'EscStringSelfCheck' src/WpfGfx.Linux.Native/tests/ tools/` ＝ 0 命中））`。**消掉需要**：实现件现取给出调用点，或本波把它接进一条门禁步（那时键名与步名同趟写死）。
5. **"两页真排版"的判据**：`NOINFO(reason=本增量至多一跳；真排版需要 LS 族其余 20 条缺失 ＋ `LoAcquirePenaltyModule` 成功 ＋ PTS 族 66 条（现取 `PTSGAP=tool=99` 中 `Fs*` 66）)`。**消掉需要**：后续各跳逐一落地后的症状面成对读数。
6. **`magenta` 门禁阈值的权威值**：`NOINFO(reason=本件只读、未取该常量；判据里写成"门禁自带阈值"由门禁读)`。**消掉需要**：`grep -n 'MAGENTA_FLOOR' build/MilBridge/tools/pts-pages-guard.sh` 的现取值（实现件同趟取）。

---

## §6 ⑥ 载体与边界遵守自证

- **载体**：`build/MilBridge/P1-w8-step1-criteria.md`（新建；UTF-8；模式 **644**；**首记号不是 `# ⏪ `**）。
- **只读仓树**：本件全部命令为 `grep`／`sed`／`awk`／`cat`／`nm`／`sha256sum`／`wc`／`git log`／`git status` —— **零 `dotnet build`、零跑腿、零显示位、零整趟门禁、零 `git` 写**。
- **未改任何其它件**：两档 `git status --porcelain` 逐行原样——
```
# 档 A（本件落盘前）ts=2026-09-28T23:00:57.863+0800
 M build/MilBridge/HANDOFF-NEXT.md
 M build/MilBridge/tools/defect-registry-declared.tsv
 M build/MilBridge/tools/pts-pages-guard.sh
 M samples/WpfFeatureProbe/KNOWN-DEFECTS.md
?? build/MilBridge/P1-ls-family-recon.md
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/arm_A/
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/device/
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/five_post_g1.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/five_pre_g1.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/session.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/shots/
```
⇒ 其中**只有** `?? build/MilBridge/P1-ls-family-recon.md` 是我的**上一件**、以及本件（落盘后新增一行）—— **其余全部是他人**在飞件（`HANDOFF-NEXT.md`／`defect-registry-declared.tsv`／`pts-pages-guard.sh`／`KNOWN-DEFECTS.md`／`arm_A/**`），我的**机器值格与判据件一个都没动**。
- **未引既有报告当证据**：`P1-ls-family-recon.md` 只当线索，其**结论性一处我现取更正**（§1.5）；本件所有读数（`.so` sha16／`exports.txt` 557／`win32_pts.c` 行区间／`LineServices.cs` 签名与 `LsDevRes`／`leg_23.env` 各字段／`exports.txt` 的自检符号在位）**都是本趟现取**。
- **末行自报口径当场可复算**：见末行。

---

### 结语（自包含）

- **① 诚实边界**：**`return LsErr.None` 但无"与该 `ploc` 绑定的可独立读取的状态变化" ＝ 假装成功**；最小可辩护实现 ＝ **句柄身份校验 ＋ 参数真落盘（非全局单例） ＋ 计数 ＋ 一条能证伪的自检**（照 `win32_pts.c:284/304/321/411` 与 `win32_classification.c:171/183` 的既有做法）。**非目标**：不实现 LS 排版本身、不承诺两页真排版、不改仪表、不动 `LoAcquirePenaltyModule` 的诚实缺口。
- **① 附：`t75` §3 的自我更正**：`LoAcquirePenaltyModule` **已导出但返回 `-10000`**（`win32_pts.c:321-326`）⇒ `TextPenaltyModule` 构造会抛 ⇒ **台账真非零只需 `LoSetDoc`＋`LoSetBreaking` 两条**（`GetTextPenaltyModule()` 一跑就点亮台账）；要走到 `PTS.CreateDocContext`（`PtsCache.Linux.cs:548`）**还需**让该入口**成功返回 0**。
- **② 判据**：C1–C6 六条，每条含 objective／acceptance／**可跑的 verify 单行**／取哪个字段／期望形状；**不预判任何名字结果**。
- **③ 假进度必红**：P1–P6 六对正反腿（只改计数／空 `return 0`／硬编码名／跨趟拼读数／台账非零但前沿不动／自检恒绿），每条给必红点与 `reason=` 形状。
- **④ 成对读数**：R1–R7 七面（`entry=`／导出计数／缺口三格／两页症状／台账行数／同趟性／九位）＋ 每面零回归判法。
- **⑤ NOINFO 6 条**（下一跳名字／`LoSetDoc` 真语义／`LsDevRes` 值域／自检调用路径／两页真排版判据／`MAGENTA_FLOOR` 权威值），各带"消掉需要什么"。

---

`P1-W8-STEP1-CRITERIA 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 1afd38129a52121a（口径＝末行之前的全文；末行＝本行）`
