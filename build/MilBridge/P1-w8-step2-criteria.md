# P1-W23 · W8 **第二步**（`LoAcquirePenaltyModule` 真实现）的预登记判据 —— 诚实边界 / 假进度必红 / 成对读数 / 纪律第 `30` 条约束

> **本件是判据件（先写），不是实现件**：本件**不做**任何产品改动、**不构建**、**不跑腿**、**不占显示位**，供随后的**实现件**与**独立复核件**当契约用。
> **一切读数由我现取**（命令与输出原样贴出）；`build/MilBridge/P1-w8-step1-criteria.md`（同类前例）只作**形制参照**，**不照抄其结论**；未引任何既有报告当证据。
> **边界（硬）**：只读仓树；唯一写入 ＝ 本件；**未** `dotnet build`、**未**跑腿、**未**占显示位、**未**跑整趟门禁、**未** `git add/commit/push`；未改任何判据件／产品件／`docs/ROUTES.md`／`HANDOFF-NEXT.md`／`tools/**`。
> **读取时刻**：`ts=2026-09-29T00:35:19.127+0800`（起点）→ `2026-09-29T00:35:50.449+0800`（末取）。

---

## §0 快照与现取读数（本件全部结论的底座）

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | `d6ab99b`（`docs(#81): t91 复核载体入账（F-1/F-3 落地成立、落法诚实、G10b 未放宽、正极过）+ 队长认账覆盖面口径说错`） | `git log --oneline -1` |
| 工作树 | 3 个 `M`（`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_pts.c`／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`）＋ `arm_A/**` 7 个 `??` ⇒ **全属他人在飞件**，我一个未动 | `git status --porcelain` |
| 权威 `.so` | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`657f448c2077ba1f`** | `sha256sum` |
| 导出清单 | `src/WpfGfx.Linux.Native/bin/exports.txt` ＝ **`71d651b16c6d9d6e`**／**561** 行；`nm -D --defined-only … \| awk '{print $3}' \| grep -c .` ＝ **561** | `sha256sum`／`wc -l`／`nm` |
| PTS 桩件 | `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`823298d182c6d271`** | `sha256sum` |
| 在册名册 | `k_pts_entries[]` 现取 **12** 名（`ts` 现取：`LoSetDoc`／`LoSetBreaking` 已由 `t81` 加入）；`"LoAcquirePenaltyModule"` 现取在 **`:78`** | `sed -n '70,86p'` |
| 覆盖自检器 | `check-shim-coverage.py`：`扫描到 423 条…`；**`[PresentationNative_cor3.dll] 97 条`**；前缀分解 `Lo=16 Fs=66 Nl=6 Wrapper=5 other=4 total=97`；**`LoAcquirePenaltyModule` 在该缺口面里命中 ＝ `0`** | 现跑（见 §2-C2） |
| 缺口三格 | `PTSGAP=PASS tool=97 dead=11 artifact=1 ops=85 impl=91 so16=657f448c2077ba1f exports=561` | 现跑（见 §2-C3） |
| **前沿** | `PTSGAP_FRONTIER before=LoCreateContext@3 after=LoAcquirePenaltyModule@3 carrier_sha16=e348b4ef70ab521e carrier_mtime=2026-09-29 00:09:11.828693542 +0800`｜`PTSGAP_FRONTIER_STATE=NAMED frontier=LoAcquirePenaltyModule（具名前沿成立）` | 同上 |
| 在册载体 | `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` ＝ **`e348b4ef70ab521e`**／mtime `2026-09-29 00:09:11`：`3 entry=LoAcquirePenaltyModule`；`:511 PTS_GAP entry=LoAcquirePenaltyModule seq=3 err=-10000 calls=1` | `grep -o`／`sha256sum` |
| 两页症状（在册腿证据，`arm_A`） | `leg_23.env`：`LEG k=23 alive=yes app_rc=143 magenta=49943 colors=844 ns=…RichTextBoxDemo ae=141283 ink=428456`｜`NAMED managed_unavail=1 err=-10000 native_gap=1 native_err=-10000`｜`DEV x_up=yes five_stable=yes shim=3bd193e54785b5db pf=b3f0d129f0234b58`；`leg_24.env`：`magenta=54533 colors=852 ns=…FlowDocumentDemo ae=221857 ink=423798` | `cat` |
| 现基线 | `docs/CURRENT-STATE.md:9` ＝ `BASELINE-FROZEN gen=#80 sha256… b27ff6332f263495 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `sed -n '9p'` |

🔴 **两条现取事实，直接影响判据设计（见 §2-C2 与 §4-R6）**：
1. **本增量的「缺口面（ENFE）」读数不会变** —— `LoAcquirePenaltyModule` **本来就不在缺口清单里**（它已导出；现取命中 **0**）。⇒ **`[PresentationNative_cor3.dll] 97 条` 与 `tool/ops/impl` 三格在本增量上都不构成"前进"的证据**，判据**必须**把前进证据压在**行为面**（台账 / 前沿 / `entry=` / 症状）上。
2. **在册腿证据与现盘 `.so` 不是同一趟** —— `leg_*.env` 的 `DEV … shim=3bd193e54785b5db` ≠ 现盘 `.so` `657f448c2077ba1f`。⇒ 任何"before/after 成对"**必须**同趟重取（见 §2-C6 与 §3-P4）。

---

## §1 ① 诚实边界

### 1.1 上游签名与调用点（原文，逐行照抄）

`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs:1569`：
```
        [DllImport(DllImport.PresentationNative, EntryPoint = "LoAcquirePenaltyModule")]
        internal static extern LsErr LoAcquirePenaltyModule(
            IntPtr                  ploc,       // Line Services context
            out IntPtr              penaltyModuleHandle
            );
```
⇒ **`LsErr LoAcquirePenaltyModule(IntPtr ploc, out IntPtr penaltyModuleHandle)`**：入参 ＝ LS 上下文句柄；**出参** ＝ 罚分模块句柄；返回 `LsErr`（`None` ＝ 0；非 `None` ＝ 错）。
紧邻兄弟（同件，本增量**不**含）：`LoDisposePenaltyModule`（`EntryPoint = "LoDisposePenaltyModule"`）／`LoGetPenaltyModuleInternalHandle`。

**调用链（我现取）**：`build/PresentationFramework.Linux/PtsCache.Linux.cs:532` → `:533` → `:548`
```
532:                textFormatterContext = new TextFormatterContext();
533:                TextPenaltyModule penaltyModule = textFormatterContext.GetTextPenaltyModule();
534:                IntPtr ptsPenaltyModule = penaltyModule.DangerousGetHandle();
…
548:            PTS.Validate(PTS.CreateDocContext(ref _contextPool[index].ContextInfo, out context));
```
而 `TextFormatterContext.GetTextPenaltyModule()`（`TextFormatterContext.cs:163-167`）体仅 `return new TextPenaltyModule(_ploc);`；判错在 `TextPenaltyModule.cs:23-32`（`t80` 已引，此处按本件要求重取）：
```
        internal TextPenaltyModule(IntPtr ploc)
        {
            IntPtr ploPenaltyModule;
            LsErr lserr = UnsafeNativeMethods.LoAcquirePenaltyModule(ploc, out ploPenaltyModule);
            if (lserr != LsErr.None)
            {
                TextFormatterContext.ThrowExceptionFromLsError(SR.Format(SR.AcquirePenaltyModuleFailure, lserr), lserr);
            }
            _ploPenaltyModule = ploPenaltyModule;
        }
```
⇒ **托管侧唯一的判错 ＝ `lserr != LsErr.None` ⇒ 抛**。**没有**任何"出参是否真可用"的第二道断言 —— 这一点是本增量"假成功"风险的**全部来源**。

**本地 native 现状（诚实缺口，非假装成功）**：`src/WpfGfx.Linux.Native/src/win32_pts.c:526`
```
int LoAcquirePenaltyModule(void *ploc, void **penaltyModuleHandle)
{
    (void)ploc;
    if (penaltyModuleHandle) *penaltyModuleHandle = NULL;
    return wpf_pts_gap("LoAcquirePenaltyModule");
}
```
⇒ 它**清出参 ＋ 返回 `-10000`**（诚实拒绝），并**计一次数 ＋ 打 `PTS_GAP` 一行**（`wpf_pts_gap()`）。**这是既有诚实做法的下限**：**没实现就说没实现**。

### 1.2 「最小可辩护实现」vs「假成功」的分界（照 `t80` 的口径句，逐字沿用）

> **分界句**：**`return 0`（`LsErr.None`）本身**不是证据**；证据是「这次调用在本进程内留下了**与该对象（`ploc`）绑定**、**可被独立读取**的状态变化」。**

- **算「假装成功」**：返回 `LsErr.None`，但 ① 出参 `penaltyModuleHandle` 仍是 `NULL`／是常量／是**未与 `ploc` 绑定**的全局值；或 ② 没有任何可观测副作用（不计成功/拒绝计数、无可独立读取的观测面）。**后果**：`TextPenaltyModule` 构造**不抛**，`PtsCache.Linux.cs:534` 的 `DangerousGetHandle()` 拿到**坏句柄** ⇒ 症状从"报错"变成"下游拿到垃圾句柄后**更晚、更远**才炸（或静默错排版）"——**更难归因**。
- **算「最小可辩护实现」**（本增量**四件套**，逐条都要有现取证据位）：
  1. **句柄身份校验**：只认 `LoCreateContext` 发过、且**仍在登记表里**的 `ploc`；`NULL`／未知／伪造 ⇒ **失败返回（非 0）且一个字节都不读**（与 `LoDestroyContext` 的四条拒绝面同形）。
  2. **出参真落盘且与 `ploc` 绑定**：`*penaltyModuleHandle` 指向**该上下文对象**上的一个模块句柄（**不是**进程级全局单例 ⇒ 第二个上下文不串味）；并**不 deref** 托管传来的无关地址。
  3. **计数**：成功/被拒各一对（供自检断言）。
  4. **可独立读取**：一条**观测镜**（照 `t81` 的 `wpf_pts_jmp_*` 形制）记下"刚才是哪个 `ploc`、填了什么句柄"——**它是镜像，权威始终是上下文对象本身**；自检**逐字段对拍两者**。
- **⚠️ 不计入"辩护"的东西**：把 `ploc` `(void)` 掉不用；返回常量句柄；把状态存全局；只加一行 `return 0;`；**不动**既有的"未知句柄 ⇒ 拒绝"面（本增量不得把拒绝面改松）。
- **本增量的非目标**：**不**实现罚分模块的**内部算法**（不断行代价、不建 internal handle）、**不**顺带补 `LoGetPenaltyModuleInternalHandle`／`LoDisposePenaltyModule`（各属后续跳）、**不**承诺两页真排版、**不**改应用侧仪表。

### 1.3 既有诚实做法（形制参照，逐条引文件:行，我现取）

| 先例 | 证据位 | 可照抄之处 |
|---|---|---|
| 真对象 ＋ 登记表 ＋ 拒绝面 | `win32_pts.c` 的 `LoCreateContext`／`LoDestroyContext`（`t81` 之前落地） | 句柄身份校验；**未知句柄一个字节都不读**；魔数失效先于 `free` |
| **`t81` 的"四件套"形制**（本增量照抄形状） | `win32_pts.c:324` 起的注释块逐字：「① **句柄身份校验** … ② **参数真落盘**：…落到**该上下文对象**上（**不是**进程级全局单例 ⇒ 第二个上下文不串味）③ **计数**：成功/被拒各一对 ④ **可独立读取**：一个短的**观测镜**（`wpf_pts_jmp_*`）」 | ① ② ③ ④ 四条**逐字** |
| 诚实拒绝（未实现就不装） | `win32_pts.c:526`（本格要改的那个 stub） | 返回非 0 ＋ 清出参 |
| 台账 ＋ 有界打印 | `wpf_pts_gap()`（`win32_pts.c`，被上条调用） | `PTS_GAP entry=… seq=… err=… calls=…` 与"超界截断"行 |
| 自检的**可证伪**形制 | `WpfLinuxWin32_EscStringSelfCheck`（`win32_classification.c:183`）／`WpfLinuxWin32_PtsGapSelfCheck`（`win32_pts.c`） | 逐字段断言 ＋ **投毒出参** ＋ **保存/复原**（"自检不许改变可观测状态"） |

---

## §2 ② 判据 C1–C8（逐条 objective／acceptance／可跑 verify／取哪个字段／期望形状）

> **通用**：每条 verify **必须捕获式取 `rc`**（`cmd >out 2>err; echo $?`）；**不许**从管道末段取 `$?`。
> **通用反过读句**：任何一条"绿"都**不许**被读成"两页真排版"。
> **通用前提（§0 事实 1）**：**缺口面/三格不变是本增量的正常形态** —— 判它们"必须变"就是设计错判据。

### C1 构建面：源码改动真进了 `.so`
- **objective**：本增量真被编译进 `libwpfwin32.so`。
- **acceptance**：`bash src/WpfGfx.Linux.Native/build-shim.sh --symbols >out 2>err; echo $?` ⇒ `rc=0`；`exports.txt` 行数 **＝** `nm -D --defined-only` 的符号数；`.so` 的 `sha16` **≠** before。
- **取哪个字段**：`src/WpfGfx.Linux.Native/bin/exports.txt`（清单）／`libwpfwin32.so`（`sha16`）。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash src/WpfGfx.Linux.Native/build-shim.sh --symbols >/tmp/c1.out 2>/tmp/c1.err; echo "rc=$?"; a=$(nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | grep -c .); b=$(wc -l < src/WpfGfx.Linux.Native/bin/exports.txt); echo "nm=$a exports=$b equal=$([ "$a" = "$b" ] && echo yes || echo NO)"
```
- **期望形状**：`rc=0` ∧ 两值**相等**。**导出面「不变或按需」**：现取 **561**；本增量**可能**因新增自检符号而 **> 561**（那是**允许**的），但**不得下降**。

### C2 缺口面：**本条判"不变"**（防把"面没动"误读成"没前进"）
- **objective**：确认本增量**不改变** `EntryPointNotFoundException` 面（因为该入口本来就已导出）。
- **acceptance**：`check-shim-coverage.py --tier mapped` 的 **`[PresentationNative_cor3.dll] N 条`** before ＝ after（现取 **97**）；`LoAcquirePenaltyModule` 在该缺口面里命中**始终为 `0`**。
- **取哪个字段**：工具 stdout 的 `^  \[PresentationNative_cor3\.dll\] [0-9]+ 条` 行与明细行。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier mapped >/tmp/c2.out 2>/tmp/c2.err; echo "rc=$?"; grep -E '^  \[PresentationNative_cor3\.dll\] [0-9]+ 条' /tmp/c2.out; grep -cE '^  PresentationNative_cor3\.dll  LoAcquirePenaltyModule ' /tmp/c2.out
```
- **期望形状**：`rc=0`；条数 **＝ 97（不变）**；第二值 **＝ 0**。⇒ **本条的绿不构成"前进"证据**（见 §3-P1）。

### C3 台账/前沿面：**前进的唯一强证据在这**
- **objective**：`LoAcquirePenaltyModule` 由"缺口"变"能用"，并使**前沿真的离开它**。
- **acceptance**：`bash build/MilBridge/tools/pts-gap-count-check.sh >out 2>err; echo $?` ⇒ `rc=0`；三格 `tool/ops/impl` **成对给 before/after**；`PTSGAP_FRONTIER` 的 **`after=` 不再是 `LoAcquirePenaltyModule`**（前沿移走），且 `carrier_sha16=` **同趟**给出；`PTSGAP_FRONTIER_STATE` 行在位。
- **取哪个字段**：`PTSGAP=`（三格 ＋ `so16=`／`exports=`）／`PTSGAP_FRONTIER`（`before=`／`after=`／`carrier_sha16=`）／`PTSGAP_FRONTIER_STATE`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/pts-gap-count-check.sh >/tmp/c3.out 2>/tmp/c3.err; echo "rc=$?"; grep -E '^(PTSGAP|PTSGAP_FRONTIER|PTSGAP_FRONTIER_STATE)=' /tmp/c3.out
```
- **期望形状**：`rc=0`；`PTSGAP=` 在 `SO16=` 与现盘 `.so` **一致**；`after=` 的**入口名**（不预判是谁）**≠** `LoAcquirePenaltyModule`。⚠️ **`FRONTIER_STATE=NAMED`** 仍应在位（前沿**具名**这件事本增量不撤销）。

### C4 `entry=` 面：具名**位移**且可回溯
- **objective**：应用侧自报的 `entry=` 面**跟着**位移（而不是被改成常量）。
- **acceptance**：载体 `app_g1.log` 上 `grep -o 'entry=[A-Za-z0-9_]*' … | sort | uniq -c`：`LoAcquirePenaltyModule` 的计数 **after < before**（现取 `3`）；**新出现的具名**（若有）必须能用 `grep -n 'EntryPoint *= *"<该名>"' upstream/wpf/**` 现取**回溯到真实声明**；`unknown` 计数**不增**。
- **取哪个字段**：`build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` 的 `entry=`；上游 `[DllImport]` 声明。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; grep -o 'entry=[A-Za-z0-9_]*' "$D/app_g1.log" | sort | uniq -c; grep -c 'entry=unknown' "$D/app_g1.log"
```
- **期望形状**：`LoAcquirePenaltyModule` 计数**下降**（至 0 为最强）；`unknown` **不增**。

### C5 两页症状面：**不劣化** ＋ 台账效应可见
- **objective**：本增量不把两页推回"进程死"，且台账效应可读。
- **acceptance**：`leg_23.env`／`leg_24.env` 现取：`LEG … alive=yes` ∧ `app_rc ∉ {134,139}` ∧ `magenta ≥` 门禁阈值；`NAMED … native_gap` **after ≥ before**（现取 `1`）且该腿 `DEV … shim=` **＝**本趟 `.so`；守卫 `pts-pages-guard.sh --legs <dir>` ⇒ `rc=0` 且 `PTS_GUARD=`／`PTS_G10_NAME=` 两行在位。
- **取哪个字段**：`leg_{23,24}.env` 的 `LEG`／`NAMED`／`DEV` 三行；守卫的 `PTS_GUARD=`／`PTS_G10_NAME=`／`PTS_G10_ROSTER_SRC=`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; bash build/MilBridge/tools/pts-pages-guard.sh --legs "$D" >/tmp/c5.out 2>/tmp/c5.err; echo "rc=$?"; grep -E '^(PTS_GUARD|PTS_G10_NAME)=' /tmp/c5.out; grep -hE '^(LEG|NAMED|DEV) ' "$D"/leg_23.env "$D"/leg_24.env
```
- **期望形状**：`rc=0`；两腿 `alive=yes`；`native_gap ≥ 1`。**不预判**具体数值。

### C6 同趟性（**本增量必加**：§0 事实 2）
- **objective**：before/after 的所有面**取自同一趟**（同一 `.so`、同一份 `app_g1.log`）。
- **acceptance**：`pts-gap-count-check.sh` 的 `so16=` **＝** `leg_*.env` 的 `DEV … shim=` **＝** 现盘 `.so` 的 `sha16` 前 16；三者**逐位相同**。
- **取哪个字段**：上述三个字段。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && s=$(sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16); g=$(bash build/MilBridge/tools/pts-gap-count-check.sh | grep -o 'so16=[0-9a-f]*' | cut -d= -f2); l=$(grep -h '^DEV ' build/MilBridge/tests/PtsPagesProbe/evidence/leg_23.env | grep -o 'shim=[0-9a-f]*' | cut -d= -f2); echo "so=$s gap_so16=$g leg_shim=$l same=$([ "$s" = "$g" ] && [ "$g" = "$l" ] && echo yes || echo NO)"
```
- **期望形状**：`same=yes`。**现取这一条是 NO**（`leg shim=3bd193e54785b5db` ≠ 现盘 `657f448c2077ba1f`）⇒ **实现件必须先同趟重取**。

### C7 自检面（**受纪律第 `30` 条约束**，见 §5）
- **objective**：新实现带一条**能证伪**的自检，且其读数**按纪律第 `30` 条**带三格。
- **acceptance**：① 新自检（照 `WpfLinuxWin32_*SelfCheck` 形状）**已导出**；② 它在 **"未实现/已实现"两态**或**"fresh/带历史"两前置**下给出**不同**判词；③ 任何引用它的读数**同趟**给出 ①进程新鲜度 ②关键前置量 ③`rc`/`diag` 判词**三格**。
- **取哪个字段**：`exports.txt` 里新自检符号在位；自检读数行的三格。
- **verify（形状）**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && grep -c 'WpfLinuxWin32_\(PtsGap\|PtsJmp\|EscString\|Classification\)SelfCheck' src/WpfGfx.Linux.Native/bin/exports.txt
```
- **期望形状**：**after ≥ before**（现取 3 条：`ClassificationSelfCheck`／`EscStringSelfCheck`／`PtsGapSelfCheck`；若本增量新增则更大）。⚠️ **谁 dlsym 它**本件不预判 ⇒ §6 NOINFO。

### C8 stub 面：该入口**不再**走诚实缺口
- **objective**：`LoAcquirePenaltyModule` 从"缺口路径"里消失（这是**行为面**的机械证据，与 C2 的"缺口面不变"互补）。
- **acceptance**：`grep -c 'return wpf_pts_gap("LoAcquirePenaltyModule")' src/WpfGfx.Linux.Native/src/win32_pts.c` **before ≥ 1 → after ＝ 0**。
- **取哪个字段**：该源件的该字符串命中数。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && grep -c 'return wpf_pts_gap("LoAcquirePenaltyModule")' src/WpfGfx.Linux.Native/src/win32_pts.c
```
- **期望形状**：**＝ 0**（现取 ＝ 1 的形态见 §1.1 的 `:526` 块）。

---

## §3 ③ 「假进度必红」（成对正反腿 ＋ 必红点；形制照 `t80` P1–P6 与 `LOC_POLARITY`）

> **形制**：每条给 **正腿（必绿）**／**反腿（必红并点名）**／**必红点（断言的具体字段）**；**反腿必须在副本文档上跑**（不许改仓内件）。
> **总则（写死）**：**反腿未红、或红而不点名（缺 `reason=`／缺 `file:`／缺字段名）⇒ 该条判不成立**，本增量**不得关账**。

| # | 假形式 | 正腿（必绿） | 反腿（**必红并点名**） | 必红点（断言字段） |
|---|---|---|---|---|
| **P1** | **只改计数不改行为**（改 `pts-gap-decl.txt`／白名单让三格好看） | 真实现 ⇒ C8 的 `grep -c` ＝ **0** | 只改声明件 ⇒ 必报 **`FAIL reason=decl-vs-live-mismatch`** | `nm` 逐名命中 ∧ 声明件；**不一致即红** |
| **P2** | **`return 0` 无副作用**（清空实现体、加一行 `return 0;`） | 真实现 ⇒ C7 的自检在两态下**判词不同** | 把 `LoAcquirePenaltyModule` 换成"只 `return 0;`"的**副本** ⇒ 自检**必红**并点名（如 `reason=handle-null-after-none`） | 出参 `*penaltyModuleHandle` 在返回 0 时**仍为 NULL** ⇒ 红 |
| **P3** | **把 `entry=` 改成硬编码常量名**（改仪表） | 真实现 ⇒ C4 的具名可**回溯上游 `[DllImport]` 声明** | 副本上把 `entry=` 写死常量 ⇒ 必报 **`FAIL reason=entry-name-not-backtraceable`** 并点名该常量 | `grep -n 'EntryPoint *= *"<名>"' upstream/wpf/**` 命中 **0** ⇒ 红 |
| **P4** | **导出位移与 `entry=` 面不同趟**（拼接两趟读数） | 真实现 ⇒ C6 的 `so16=` ＝ `DEV … shim=` ＝ 现盘 | 用**上一趟** `leg_*.env` 配**本趟** `.so` ⇒ 必报 **`FAIL reason=cross-run-pairing`** | 三值不等 ⇒ 红（**现取正是 NO**，故本条今天就会红） |
| **P5** | **台账非零但前沿不动**（只把 `native_gap` 弄成 >0） | 真实现 ⇒ C3 的 `after=` **≠** `LoAcquirePenaltyModule` | 只让台账涨而前沿仍停在同名 ⇒ 必报 **`FAIL reason=ledger-nonzero-frontier-unchanged`** | `PTSGAP_FRONTIER` 的 `before==after` 同名 ⇒ 红（**台账 >0 不免除**） |
| **P6** | **自检恒绿** | 自检**能证伪**（P2） | 把自检改成 `return 1;` ⇒ 必由既有探针同趟报红 | 自检**两态返回值相同** ⇒ 红 |
| **P7** | **把 `native_err`／症状列硬编码**（把 `native_err=-10000` 人工改成 `-`） | 真实现 ⇒ `native_err` 由**真实返回值**决定 | 副本上把该列写死 ⇒ 必报 **`FAIL reason=symptom-column-not-derived`** 并点名该列 | 该列与同趟 `PTS_GAP … err=` 行**不自洽** ⇒ 红 |

---

## §4 ④ 成对读数清单（before／after ＋ 每面「零回归」判法）

| # | 面 | 取哪个文件的哪个字段 | before（本件现取） | after 期望形状 | 零回归判法 |
|---|---|---|---|---|---|
| R1 | 导出面 | `exports.txt` 行数；`nm … \| grep -c .` | **561 / 561** | 两者**相等** ∧ **不下降** | 不相等 ⇒ 红；**下降** ⇒ 红 |
| R2 | 缺口面 | `check-shim-coverage.py` 的 `[PresentationNative_cor3.dll] N 条` | **97** | **＝ 97（不变）** | 变了 ⇒ 需逐条点名归因（本增量**不该**动它） |
| R3 | 三格 | `PTSGAP=` 的 `tool/dead/artifact/ops/impl` | **97 / 11 / 1 / 85 / 91** | 三格按各自口径给成对；`dead`／`artifact` **不变** | `artifact` 变大 ⇒ 逐条点名（账目漂移） |
| R4 | 前沿 | `PTSGAP_FRONTIER` 的 `after=<名>@<calls>` | `after=LoAcquirePenaltyModule@3` | **`after≠LoAcquirePenaltyModule`** | 同名 ⇒ P5 红 |
| R5 | `entry=` 面 | `app_g1.log` 的 `entry=` 直方图 | `3 LoAcquirePenaltyModule`（`e348b4ef70ab521e`） | 该名计数**下降**；`unknown` **不增** | `unknown` **增** ⇒ 读作**仪表退化**（回归） |
| R6 | 两页症状 | `leg_{23,24}.env` 的 `LEG`／`NAMED`／`DEV` | `alive=yes app_rc=143 magenta=49943/54533`；`native_gap=1 native_err=-10000`；`shim=3bd193e54785b5db` | `alive=yes` ∧ `app_rc∉{134,139}` ∧ `magenta ≥` 阈值 ∧ `native_gap ≥ 1` ∧ `shim=` ＝ 本趟 `.so` | `alive` 变／`app_rc∈{134,139}`／`magenta` 掉阈值／`shim` 不匹配 ⇒ **红** |
| R7 | 同趟性 | `so16=` ∧ `DEV … shim=` ∧ 现盘 `.so` | **三者不一致**（`657f448c2077ba1f` vs `3bd193e54785b5db`） | 三者**逐位相同** | 不等 ⇒ 红（P4） |
| R8 | 九位 | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 九位行／`BASELINE tier=` | 现基线 `b27ff6332f263495`（`CURRENT-STATE.md:9`） | **只有 `win32shim` 位**按声明位移 | 出现**未声明**位位移 ⇒ 红 |

🔴 **对 ④ 里"`unified`"一面的点名（现取）**：该名字在**仪器件**里**零命中** ——
```
$ grep -rli 'unified' verify-all.sh build/close-wave.sh build/MilBridge/tools/ build/MilBridge/tests/PtsPagesProbe/ | wc -l
0
```
全仓（排除 `upstream/`／`.git/`／`.agent-teams/`）命中它的**只有**若干**评审报告**与**已编译二进制**；逐行看，那些命中都是 **`git diff --unified=0`**（diff 参数），**不是**任何症状/统计列名。⇒ **"`unified`" 不是一个现存的机器可读面**。**本判据不把它写成字段**；若实现件认为它在别处存在，必须**先给出载体路径 ＋ 现取读数**再并入（见 §6-N6）。

---

## §5 ⑤ 纪律第 `30` 条（**现取确认在册** ＋ 对判据的硬约束）

**在册确认（我现取）**：`HANDOFF-NEXT.md` 现取有该条 —— 块头 `:611`，口径句 `:614`。**口径句逐字**：
> **「凡引用**进程内状态敏感**的仪器读数（自检／探针／计数器镜像／`live` 计数），必须**同趟**给出三格：① **进程新鲜度**（fresh 进程，或同进程 ＋ **已发生的关键调用序**）② **关键前置量**（该读数所依赖的那些计数/`live` 的**当时值**）③ **判词**（`rc`／`diag` 四元组）。缺任一格 ⇒ 该读数**不许当证据** —— 同一个 `.so` 在 fresh 与"带历史"两种前置下会给出**不同**判词。」**

**该条自带的"条在位自检命令"（我照跑，捕获式取 `rc`）**：
```
$ grep -c '进程新鲜[度]' build/MilBridge/HANDOFF-NEXT.md ; echo "rc=$?"
1
rc=0
```
⇒ **在册成立**（`1` 命中）。

**本判据对它的硬约束（写死，实现件与复核件都受约束）**：
1. **凡本判据里出现"自检/探针"读数的地方（C7、P2、P6），同趟必须给三格**：① fresh 进程 **或** 同进程 ＋ 已发生的关键调用序（**逐条列出**：建过几个 LS 上下文、是否写过 `LoSetDoc`／`LoSetBreaking`、是否销毁）② 该读数依赖的**当时值**（`loc_live`／`doc_sets`／`break_sets`／`calls`／`g_pts_jmp_n` 等）③ 判词（`rc` ＋ `diag`）。**缺任一格 ⇒ 该读数不许当证据。**
2. **调用序约束**：**正腿的自检必须在 fresh 进程里跑**；若要跑"带历史"腿，**必须在独立进程里**、且历史**逐条可复现**（不许"上一条腿留下的状态"充当本条腿的前置）。
3. **🔴 误导形态（写清，供复核件识别）**：
   - **把"带历史"的自检红读成"实现坏了"＝ 假红**：同一 `.so` 在 fresh 与带历史两种前置下**判词不同**，成因是**调用序**而非实现（本条自报的现场成对读数即 `fresh rc=1 diag=0` vs `带历史 rc=0 diag=25/32`；**那对数字我未复算** —— 复算需跑探针，本件不许跑 ⇒ 见 §6-N1）。
   - **把 fresh 的绿读成"实现健全的证明"＝ 假绿**：fresh 只证"在该前置下没红"，**不**证"与 `ploc` 绑定的状态真落了" —— 后者要**权威对象**（上下文对象本身）与被读镜像的**逐字段对拍**（`t81` 形制的④）。
   - **跨进程拼读数**：`t80` 的 P4 与本件的 P4 是同族 —— **不同趟的三格不许拼成一对**。

---

## §6 ⑥ `NOINFO` 预期（**在我写判据的时刻必然拿不到**；逐条给"消掉需要什么"）

1. **纪律第 `30` 条那对现场数字（`fresh rc=1 diag=0` / 带历史 `rc=0 diag=25` / `rc=0 diag=32`）的独立复算**：`NOINFO(reason=复算需跑自检/探针（dlopen 仓内 `.so` 并调自检），本件硬边界禁止跑探针；我现取只确认了"该条在册"与"条在位自检命令可通过（`1`）")`。**消掉需要**：实现件或复核件在 fresh 进程里跑一次自检并给出三格。
2. **补完之后链上**下一个**被撞入口是谁**：`NOINFO(reason=只能由运行期逐步取证；本件不跑腿，且任务明令不许预判名字)`。**消掉需要**：实现件补完后跑一趟冷启腿读 `app_g1.log` 的 `entry=` 面（C4）与 `PTS_GAP` 台账行。
3. **`penaltyModuleHandle` 的真实语义**（它下游被 `DangerousGetHandle()` 拿去做什么、`ptsPenaltyModule` 传给 `CreateDocContext` 的哪一字段）：`NOINFO(reason=本仓只有 P/Invoke 声明与调用点，没有 LS 的 C 侧规格/结构体定义)`. **消掉需要**：LS 规格，或"以下游实际使用形状为准"的具名声明。
4. **新自检的调用路径**（谁 `dlsym` 它、由哪一步跑、打哪一行机读键）：`NOINFO(reason=既有三个 `*SelfCheck` 我现取只能证"已导出"（见 C7），**仓内未现取到调用点**）`。**消掉需要**：实现件给出调用点，或本波把它接进一条门禁步（届时键名与步名同趟写死）。
5. **`magenta` 门禁阈值的权威值**：`NOINFO(reason=本件只读、未取该常量；判据里一律写"门禁自带阈值"，由门禁读)`. **消掉需要**：`grep -n 'MAGENTA_FLOOR' build/MilBridge/tools/pts-pages-guard.sh` 的现取值（实现件同趟取）。
6. **`unified` 面的载体**：`NOINFO(reason=现取在仪器件里**零命中**（见 §4 末）；只在若干评审报告与已编译二进制里出现，且那些命中是 `git diff --unified=0`（diff 参数），不是列名)`. **消掉需要**：实现件给出该面的**载体路径 ＋ 现取读数**。
7. **"两页真排版"的判据**：`NOINFO(reason=本增量只是"补一个入口"，真排版还需 LS 族其余 16 条（现取 `Lo=16`）＋ PTS 族 66 条（`Fs=66`）等)`. **消掉需要**：后续各跳落地后的症状面成对读数。

---

## §7 ⑦ 载体与边界遵守自证

- **载体**：`build/MilBridge/P1-w8-step2-criteria.md`（新建；UTF-8；模式 **644**；**首记号不是 `# ⏪ `**；末行自带可复算自报口径）。
- **只读**：本件全部命令为 `grep`／`sed`／`awk`／`cat`／`nm`／`sha256sum`／`wc`／`git log`／`git status` ＋ 两个**纯读**自检器（`check-shim-coverage.py`／`pts-gap-count-check.sh`，后者件头即声明为纯读自检）。**零 `dotnet build`、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
- **未改任何其它件**：两档 `git status --porcelain` 逐行原样 ——
```
# 档 A（本件落盘前）ts=2026-09-29T00:35:19.127+0800
 M build/MilBridge/HANDOFF-NEXT.md
 M src/WpfGfx.Linux.Native/src/win32_pts.c
 M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/arm_A/
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/device/
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/five_post_g1.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/five_pre_g1.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/session.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/shots/
```
⇒ 上述**全部为他人**在飞件（含 `HANDOFF-NEXT.md`／`win32_pts.c`／`pts-gap-decl.txt`／`arm_A/**`）；**我未改**任何判据件／产品件／`ROUTES.md`／`HANDOFF-NEXT.md`／`tools/**`。本件是本次唯一新增件。
- **未引既有报告当证据**：`P1-w8-step1-criteria.md` 只作**形制参照**（分界句口径沿用时**标明出处**，但其**读数一条未抄**）；本件所有读数（`.so`／`exports.txt`／`nm`／`k_pts_entries[]` 12 名与 `:78`／缺口面 97 与 `Lo=16`／三格 97-11-1-85-91／前沿 `before/after` 与 `carrier_sha16`／`app_g1.log` 的 `entry=` 与 `:511 PTS_GAP` 行／两腿 `LEG`·`NAMED`·`DEV` 三行／纪律第 `30` 条在册与条在位自检 `/tmp` 结果／`unified` 零命中）**都是本趟现取**。
- **末行自报口径当场可复算**：见末行。

---

### 结语（自包含）

- **① 诚实边界**：`LsErr LoAcquirePenaltyModule(IntPtr ploc, out IntPtr penaltyModuleHandle)`（`LineServices.cs:1569`）；托管侧**唯一判错 ＝ `lserr != LsErr.None`**（`TextPenaltyModule.cs:23-32`）。**分界句**：`return None` 不是证据，证据是**与该 `ploc` 绑定、可独立读取**的状态变化。**最小可辩护 ＝ 句柄身份校验 ＋ 出参真落盘且与 `ploc` 绑定（非全局单例） ＋ 计数 ＋ 可独立读取的观测镜 ＋ （形制）能证伪的自检**；**非目标**：不实现罚分模块内部算法、不顺带补 `LoDisposePenaltyModule`／`LoGetPenaltyModuleInternalHandle`、不承诺两页真排版、不改仪表。
- **② 判据 C1–C8**：构建面／**缺口面（本条判"不变"，97 → 97）**／台账-前沿面（**前进的唯一强证据**）／`entry=` 面／两页症状面／**同趟性（今天现取是 NO）**／自检面（受纪律 30 约束）／stub 面（`return wpf_pts_gap("LoAcquirePenaltyModule")` 命中 1 → 0）。每条给可跑 verify、字段与期望形状；**不预判名字**。
- **③ 假进度必红 P1–P7**：只改计数／`return 0` 无副作用／硬编码 `entry=` 名／跨趟拼读数／**台账非零但前沿不动**／自检恒绿／症状列不派生；**反腿未红或红而不点名 ⇒ 该条判不成立**。
- **④ 成对读数 R1–R8**（含每面零回归判法）＋ **`unified` 零命中的点名**。
- **⑤ 纪律第 `30` 条**：**在册确认**（`HANDOFF-NEXT.md:611`／`:614`，条在位自检 `grep -c '进程新鲜[度]'` ＝ **1**）；本判据凡引用自检/探针读数**一律要求三格 ＋ 调用序**，并写清两种误导形态（把带历史的红读成实现坏了 ＝ 假红；把 fresh 的绿读成健全证明 ＝ 假绿）。
- **⑥ NOINFO 7 条**，各带"消掉需要什么证据"。

---

`P1-W8-STEP2-CRITERIA 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 427cc82e166f1a48（口径＝末行之前的全文；末行＝本行）`
