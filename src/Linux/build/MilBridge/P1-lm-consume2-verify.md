# P1-W107 独立复核（`verifier`／`t195`）—— `t194`「到达＋算术」降级见证

> **判词：`needs_revision`** —— ① 🔴 **判据的"算术"半前提不成立**（`:177` 的两个操作数**今天没有写入者**：其唯一源 `PtsHelper.cs:633` 的 `FsQuerySubtrackParaList` native 侧**未实现、未导出**）⇒「两个操作数都是本侧作者 ⇒ `rcPara.dv` 由算术唯一确定」**不成立**，须 dated 收窄＋具名新前置；② 「到达=0」**不是读数而是"没打印"的推断**（本车道**无**任何对该计数口的**读取**载体）＋到达见证**不在 `:174-180` 的下游**（判别力边界未写全）。**`t194` 的交付末态（`S-2a` 维持 7/8、不判绿）方向正确**，本判词不改其 7/8，只判"算式 ✅"这一承载性子结论与其证据类。
>
> **复核对象（本席现取，读时 `2026-09-29T22:47–23:0x+0800`）**
> - 载体 `build/MilBridge/P1-lm-consume2-report.md`：**79 行**／7898 B／sha16 **`4147b10b124c6445`**／末行自证 **`53952bce6cc94bb6`**（本席 `head -n -1 | sha256sum | cut -c1-16` 复算 **MATCH ✓**）
> - 判据件 `build/MilBridge/P1-host-consume-route-criteria.md`（`t191`）：171 行／sha16 **`abfaebc99aa8ec5b`**／自证 `519fb73ec4b95780`
> - 上游针 `upstream/wpf/…/MS/Internal/PtsHost/PtsHelper.cs`：sha16 **`f2ed9552e983fed1`**（读取时刻 `2026-09-29T22:47:46+0800`）
> - 落点件 `src/WpfGfx.Linux.Native/src/win32_pts.c` 现取 **`27b023609512f74f`**／4394 行（＝`t194` 自称末值 ✓）｜`.so`＝**`352855f8dfbf8dc7`**｜`exports`＝**669** 行
> - `HEAD`＝`14f5421`（`2026-09-29T22:41:47+0800`，早于本件落盘）｜原始腿日志 `/home/links-dev/t123-runner/logs/t194/**`
>
> **§A 自用**：引用**整行取**并带代际／时刻；引他人读数标「未独立复算」（§9）；资源三值见 §11；未碰任何人写的件、未 `git add/commit/push`（§6）。

---

## §1 判据是否足够 —— 🔴 **不够**（`needs_revision` 的主因）

**1.1 上游针（本席现取整行，`PtsHelper.cs` sha16 `f2ed9552e983fed1`，读时 `2026-09-29T22:47:46+0800`）**
```
173:                // (2) Arrange and update paragraph metrics
174:                int dvrTopSpace = arrayParaDesc[index].dvrTopSpace;
175:                PTS.FSRECT rcPara = rcTrackContent;
176:                rcPara.v += dvrPara + dvrTopSpace;
177:                rcPara.dv = arrayParaDesc[index].dvrUsed - dvrTopSpace;
178: 
179:                paraClient.Arrange(arrayParaDesc[index].pfspara, rcPara, dvrTopSpace, fswdirTrack);
180:                dvrPara += arrayParaDesc[index].dvrUsed;
181:             }
```
⇒ 该行逐字与 `t194` §B 一致 ✓（**本席独立复算**该项）。

**1.2 🔴 那两个操作数**在 `:177` 处**今天没有作者**（本席四条独立取证）
1. **谁写 `arrayParaDesc[…]`**：`PtsHelper.cs:629-636` 现取整行 —— `arrayParaDesc = new PTS.FSPARADESCRIPTION [subtrackDetails.cParas]; … PTS.Validate(PTS.FsQuerySubtrackParaList(ptsContext.Context, subtrack, subtrackDetails.cParas, rgParaDesc, out paraCount));` ⇒ 该数组字段的**唯一填写者**是 **`FsQuerySubtrackParaList`**（native P/Invoke）。
2. **`FsQuerySubtrackParaList` 未实现**：`grep -rn 'FsQuerySubtrackParaList' src/WpfGfx.Linux.Native/` ⇒ **只有 1 处命中，且是注释**（现取整行 `:3717 … 与 FsQuerySubtrackParaList（PtsHelper.cs:633），二者都属 (b)、尚未实现）。`）；`grep -c '^FsQuerySubtrackParaList$' bin/exports.txt` ＝ **0**；`nm -D --defined-only bin/libwpfwin32.so | grep -c` ＝ **0**。
3. **不是别的库实现的**：车道里 app 目录同趟带的 `wpfgfx_cor3.so` 现取 `nm -D --defined-only` 的 `Fs*` 命中 ＝ **0**（`FsQuerySubtrackParaList`／`FsQuerySubtrackDetails` 均 0）⇒ 全舱**没有任何**库导出它。
4. **运行期也确实没走到**：`t194` 正腿日志 `app-wit1.log:678/:684` 现取整行为 `[HC-UNHANDLED] #1 EntryPointNotFoundException: Unable to find an entry point named 'FsQuerySubtrackDetails' in shared library 'PresentationNative_cor3.dll'. ｜ 首帧 at MS.Internal.PtsHost.UnsafeNativeMethods.PTS.FsQuerySubtrackDetails(IntPtr pfsContext, IntPtr pSubTrack, FSSUBTRACKDETAILS& pSubTrackDetails)`；`ContainerParaClient.cs:47` 就先调 `Pts.FsQuerySubtrackDetails(...)`（早于 `:69-72` 的 `ParaListFromSubtrack`→`ArrangeParaList`）⇒ **宿主在 `:174-180` 之前就被缺符号阻断**，`FsQuerySubtrackParaList` 连尝试都没发生。
⇒ 结论：`arrayParaDesc[index].dvrUsed/.dvrTopSpace` **今天既无写入者、其宿主路径也不可达** ⇒ 「两个操作数都是本侧作者」**不成立**；`t194` §B／§1.1 引的 `dvrUsed=16／dvrTopSpace=0` 是**本侧格式化入口的出参**（现取整行 `win32_pts.c:1544 const int seg_h = 16;`／`:1545 const int top_sp = 0;`／`:1550 if (out_dvr_used) *out_dvr_used = seg_h;`）——**与 `:177` 读的两个字段不是同一界面**。
⇒ **判**：判据 §4.2／§5.2／§5.3-②③ 与 `t194` §1.1 的"算式"半**必须收窄**：今天可支持的最大陈述＝「**本侧格式化出参** `dvrUsed=16 ≥ dvrTopSpace=0`（本侧作者）」＋「**新前置** `PRECOND-PARADESC-SOURCE-MISSING`（`FsQuerySubtrackParaList` 未实现 ⇒ `:177` 的操作数无源、该段不可达）」。**不得**再写「两个操作数都是本侧作者 ⇒ `rcPara.dv = 16 > 0` 由算术唯一确定」（`t194` 载体 `FsQuerySubtrackParaList` 命中 **0** ⇒ 该缺口在载体里**未被点名**）。

## §2 「到达」见证是否真到达 —— 部分成立；**"0"缺读取载体**

- **① 作者是本侧驱动 ✓**：`g_pts_fsp_pl_consumes`／`…_resolve_ok` 定义与增点全在 native（现取整行 `:1130 static int g_pts_fsp_pl_consumes = 0;   /* 延迟回收（+192）次数 ⇒ 也＝"消费解析"次数 */`、`:1142/:1143` 导出、`:3602 g_pts_fsp_pl_consumes++;`、`:3619 if (is_ok) g_pts_fsp_pl_resolve_ok++;`），**不是**由 `rc` 推出、也非自造 ✓。
- **② 被拒/被跳计入输出 ✓（就本趟可核的范围）**：`t194/run.out` 现取四条腿 `wit1 app_rc=134 / LMWIT=1 fill=2`、`wit2 …fill=2`、`nodvr …fill=2`、`noarr …fill=0` ⇒ 四腿都有独立条目、无"跳过"行；`run2.out` 只跑了两条正腿（见 §6 代际注记）。
- **③ ≥2 独立样本 ✓**：`cmp app-wit1.log app-wit2.log` 现取 ⇒ **DIFFER（第 138 字节起）** ⇒ 是**两趟独立 run**（非复制）✓；两腿的 `[LMWIT] part=arithmetic` 行**逐字相同**（`:dvrUsed=16 dvrTopSpace=0 rcpara_dv=16 … v=ARITHMETIC-OK(dv>0)`）✓。⚠️ 因此"逐字一致"只能指**读数行**，**不能**指整腿日志（见 §10 `W-4`）。
- **④ 反腿为 0 时是否真判红**：见 §3 —— 反腿②确为红（`fill=0`）✓，但**正腿的到达同样为 0** ⇒ 该反腿不构成"到达半"的区分力证据（如实记）。
- 🔴 **本席发现的证据类问题**：`consumes=0 ∧ resolve_ok=0` 在本车道**没有任何读取载体** —— `grep -rl 'PtsFsParaListConsumes\|PtsFsParaListResolveOk' t194/` 只命中 `head.md`／`body.md`／`final.md`（＝`t194` 自己的载体）与两个 `.so` 二进制本身；腿件（`leg_*.env`／`session.txt` 类）里 `consumes`／`resolve_ok` 命中 **0**；四腿日志里 `[LMWIT] part=arrival` 行命中 **0**（该行阈值 ≥2，而两计数恒 0 ⇒ **永不打印**）⇒ 「恒 0」是从**"该行没出现"**推出来的，属**回显推断而非读取**（模板 §A-7 恒真断言族：读数必须来自读取）。⇒ 见 §10 `W-2`。

## §3 两条必红反腿 —— **都非绿 ✓**，但②与正腿**同因**

| 反腿 | 产物（本席现取车道 .so） | 逐字读数（整行，现取） | 判 |
|---|---|---|---|
| ① `NODVR`（`-DWPF_PTS_FSP_PL_LMWIT_NODVR=1`） | `so-nodvr/libwpfwin32.so` ＝ **`c4ddc7ca3c1f7763`** | `[LMWIT] part=arithmetic dvrUsed=0 dvrTopSpace=0 rcpara_dv=0 upstream=PtsHelper.cs:177 v=ARITHMETIC-FAIL(dv<=0,NODVR-REVERSE-LEG)` | ✅ 非绿；且**是真行为反腿**：现取整行 `:1553 const int dvr_u = WPF_PTS_FSP_PL_LMWIT_NODVR ? 0 : seg_h;`＋`:1554 if (out_dvr_used) *out_dvr_used = dvr_u;` ⇒ 改的是**出参本身**，不是只改打印 |
| ② `NOARR`（`-DWPF_PTS_FSP_PL_LMWIT_NOARR=1`） | `so-noarr/libwpfwin32.so` ＝ **`a5428b4e6b0e97d1`** | 该腿 `[LMWIT] part=arithmetic … v=ARITHMETIC-OK(dv>0)`（**与正腿同**）＋ `[FSPARALIST-FILL]` **0 行** | ✅ 非绿（`fill=0` ⇒ 列表未填 ⇒ 到达量恒 0）；⚠️ **但与正腿"到达=0"同因** ⇒ 它只证明"到达半为假时不给绿"，**不证明**判据能区分"到达=0"与"到达>0"（本波无任一腿拿到到达量） |

## §4 判词粒度 —— **措辞合规 ✓**

- 载体 `:11`（R4）与 `:62-63`（§5）现取整行**逐字**写明：「**`dvrUsed=0` 时宿主仍会走 `Arrange`** ⇒ 本见证**区分不了**"内容真被消费"与"只是到达"；**不得**据此宣布整页排版成功，**不得**把它写成"直读宿主局部"。粒度＝**「到达 ＋ 算术」**」✓。
- 本席现取：载体里 `直读宿主局部` 命中 2、`排版成功` 命中 3 —— **全部出现在否定句**（"不得…"）中；`到达＋算术` 命中 3 ✓；**未**发现任何"直读宿主局部"的肯定表述、**未**发现宣布整页排版成功 ⇒ 本项 **合规** ✓。

## §5 `S-2a` 回到 8/8 的合法性 —— **未发生 8/8；记账诚实 ✓（含 1 处措辞越界）**

- 载体 `:49-60` 现取：八条逐条列表 ✓；**第 4 条**列为 `🔴 **降级见证：算式 ✅／到达 ❌ ⇒ 仍 NOINFO（具名前置）**`、**粒度列＝`—`**（与其余 7 条的"单次调用／单段／整腿"**区分标注** ✓）；末行 `⇒ **S-2a` ＝ 7/8（未达 8/8）**；**不得**写成"整页排版成功"` ✓。
- 与派单标题「`S-2a` 7/8→**8/8**」不同：`t194` **没有**声称 8/8，而是维持 7/8 ＋具名 `PRECOND-ARRIVAL-WITNESS-NEEDS-LONG-LEG` ✓（诚实失败）。
- ⚠️ 唯一越界处：第 8 条行的括注（见 §10 `W-4`，low）。
- 附：`t194` §1.2 对"为何到不了到达量"的解释**本席可复核**：增点在换代延迟回收路径（现取 `:3602`／`:3619`，**不是**载体所写的 `:3575`／`:3577` —— 那是**改前代际**的行号，见 §10 `W-3`）＋本腿只 `fill=2` ⇒ 到不了配额 ⇒ 解释成立 ✓。

## §6 越域与世代 —— **未越域 ✓**（附一处代际混排，low）

- **托管层／上游**：`git status --porcelain` 现取只有 ` M src/WpfGfx.Linux.Native/src/win32_pts.c`（＋若干 `??` 新载体）；`git diff HEAD --stat -- build/PresentationFramework.Linux upstream/wpf` ⇒ **0 行** ✓；`build/PresentationFramework.Linux/PtsCache.Linux.cs` 现取 `mtime=2026-09-29 17:23:50`（**早于**本件 22:43 的跑腿）✓。
- **世代留痕**：`.so` 现取 `352855f8dfbf8dc7`＝`run.out:4` 的 `pre_authority`＝`:6` 的 `post_authority`（`MAIN_BYTE_IDENTICAL=yes`）✓；`exports` 669 行 ✓；`win32_pts.c` 现取 `27b023609512f74f`（＝其 §6 末值 ✓）。
- **未 `git add/commit/push`**：`git diff --cached --name-only` ⇒ 0 ✓；`HEAD=14f5421`（22:41:47）**早于**本件落盘 ⇒ 未提交 ✓；`push` 面不可判 ⇒ 具名 `NOINFO`（§9）。
- ⚠️ **代际混排（low）**：四条腿**不在同一趟** —— A／B 来自 `run2.out`（`ts=22:45:36`，`built[GREEN]=b87b175d3e4ba3a3`），C／D 来自 `run.out`（`ts=22:43:11`，`built[GREEN]=15159d438501ce85`），而 run1→run2 之间**源件被改过**（载体自陈的阈值 `≥3 → ≥2`，现取注释在 `:3604`）⇒ 载体 §3 的四腿表**未标代际**。影响：该改动只影响联合判词行的**打印阈值**，而四腿的到达计数皆为 0（该行从未打印）⇒ **对所引字段无影响**；但按 `P11`（跨代相减）该表应加一列代际或注明。

## §7 反腿（本席自造，一对）

**反腿①「算术成立但宿主**没走到** `:174-180`」** —— 我构造的对照**不是假想，而是当前实测形态**：宿主在 `ContainerParaClient.cs:47` 就被缺符号 `FsQuerySubtrackDetails` 阻断（§1.2-4 现取 ENFE 整行），即使越过它，`ParaListFromSubtrack`（`:633`）也会撞上同样未实现的 `FsQuerySubtrackParaList` ⇒ `arrayParaDesc` 永远填不上 ⇒ **`:174-180` 一次都不执行**，而本侧"算术"读数照样打印 `v=ARITHMETIC-OK(dv>0)`。⇒ **`t194` 的到达见证区分不了这一形态**（它数的是 `+192` 回收，而回收的**前置是客户端被创建**，不是 `:174-180` 被执行）；更一般地：`arrayParaDesc.Length == subtrackDetails.cParas`（`:629`），而 LM-1 自己的 `I-1` 允许 `cParas=0`（现取整行 `win32_pts.c:1546 const int want_cparas = (fsnm_segment != NULL) ? 1 : 1;` 与注释 `cParas≥0 且只在确无子段时为 0`）⇒ **`cParas=0` 时 `:155` 的循环体（含 `:177`）一次都不跑，而后代的 `+192` 回收照旧可以发生** ⇒ 将来长腿拿到 `consumes>0` 时，仍可能是在"宿主没走到 `:174-180`"的状态下给绿。**判词有没有如实写**：**没有** —— 载体 §5 只写了 `dvrUsed=0` 那条限制，**未写**这一条（判据件 §4.3-④ 只要求"晚于 `:179`"，**未要求"下游于 `:174-180`"**）⇒ 见 §10 `W-2`。
**反腿②（P9／P10 自用）**：在判 §1.2"操作数无作者"之前，我先证明**我要求的条件真的被检了**：① 现取 `arrayParaDesc` 的**填写者**代码行（`:629-636`）；② 现取 native 全目录对该入口的命中（**只有注释**）＋ `exports`／`nm` 各 **0**；③ 现取**另一库**（`wpfgfx_cor3.so`）的 `Fs*` 导出数（**0**）；④ 现取运行期**首断点**（`FsQuerySubtrackDetails` ENFE 整行，行 678/684）。四条互不依赖。

## §8 推翻的话

**我推翻了 `t194`（及其判据草案）的一条**：**「`rcPara.dv` 的两个操作数都是本侧作者 ⇒ 由算术唯一确定」** —— 那两个操作数今天**无写入者、其宿主路径也不可达**（§1.2 四条取证），`t194` 引的值是**另一界面**（格式化出参）的值 ⇒ 该子结论**不成立**（判 `needs_revision`）。
**我没有推翻**：`dvrUsed=16 ≥ dvrTopSpace=0` 这一**出参**读数本身 ✓；`NODVR` 腿的真行为反腿与 `ARITHMETIC-FAIL` ✓；`NOARR` 腿 `fill=0` ✓；`S-2a` 维持 7/8 ✓；主链 `.so` 逐字节不变／`exports` 669 ✓；8/8 未宣称 ✓；粒度与"不得直读／不得宣布排版成功"的措辞 ✓。

## §9 具名 `NOINFO`

- **`N-1`** 到达计数口的**真值**：本波**无读取载体** ⇒ 「`consumes=0 ∧ resolve_ok=0`」属**推断**（§2 末）；本席亦**无法**把它升级为读数（不跑腿、不构建）。
- **`N-2`** `t194` 引的 `t160` 主链腿 `fill=1056/1044` 时 `consumes=33/34`：其载体自陈「引自 `t160` 载体，本席未独立复算」；本席**亦未**复算（跨件，不在本件射程）。
- **`N-3`** `push` 面：未取远端状态 ⇒ `t194` "未 push"不可判（`git add`／`commit` 两面已判）。
- **`N-4`** `wpfgfx_cor3.so` 的**构建来源**（本仓是否产出它）：本席只核了它的导出面（`Fs*`＝0），未核其来源 ⇒ 不作为作者性依据。
- **`N-5`** 本件**未跑腿／未构建／未占显示位／未跑整趟门禁**（`/tmp/.X11-unix` 未重取）。

## §10 新发现的问题（点名 `文件:行` ＋ 机制；**本件不修**）

- **`W-1`（high）｜判据的"算术"半前提不成立**：`build/MilBridge/P1-host-consume-route-criteria.md:89`（"而 `dvrUsed`/`dvrTopSpace` **都是本侧作者**（`LM-1` 现取 `dvrUsed=16`、`dvrTopSpace=0`）⇒ `rcPara.dv = 16 > 0` 由算术唯一确定"）与 `build/MilBridge/P1-lm-consume2-report.md:26`（同义）把**两个不同界面**的值当成"源与消费对"：`:177` 读的是 `arrayParaDesc[index]` 字段，其唯一填写者 `PtsHelper.cs:633` 的 `FsQuerySubtrackParaList` **未实现、未导出**（native `:3717` 自陈；`exports`／`nm` 各 0；`wpfgfx_cor3.so` 亦 0），且宿主在 `ContainerParaClient.cs:47` 已先被 `FsQuerySubtrackDetails` 缺符号打断 ⇒ **今天该段不可达、两个操作数无源**。为什么是缺陷：这是**第 4 条"算式 ✅"这一承载性子结论**的地基；把它当已证，会让下一波（长腿拿到到达量后）在"宿主从未执行过 `:174-180`"的状态下判绿。
  `requiredFix`：判据件与载体均做 **dated 收窄** —— ① 算式半改述为「**本侧格式化出参** `dvrUsed=16 ≥ dvrTopSpace=0`（本侧作者；`win32_pts.c:1544-1550`）」；② **具名新前置** `PRECOND-PARADESC-SOURCE-MISSING`（`FsQuerySubtrackParaList` 未实现 ⇒ `:177` 的操作数无源）；③ 把「`rcPara.dv = 16 > 0` 由算术唯一确定」改为**条件式**（"一旦段落描述数组有源"）并标注其依赖。
- **`W-2`（medium）｜到达见证：既是"没读"也是"不挡在该段下游"**：① `consumes=0 ∧ resolve_ok=0` 在 `t194` 车道**无任何读取载体**（§2 末），属"该打印行没出现"的**回显推断**；② 该计数是 `+192` 回收，其前置是**客户端被创建**，**不是** `:174-180` 被执行 —— 反例可达且**今天就是实测形态**（§7 反腿①）＋ `cParas=0` 时 `:155` 循环体一次不跑而回收照旧。为什么是缺陷：`P8`/恒真族意义上，"0"必须是**读取**；`P10` 意义上，见证必须真的落在被证对象的下游。
  `requiredFix`：① 判据把到达见证改成**落在 `:174-180` 路径上**的事件（如 `FsQuerySubtrackParaList` 的调用/`paraCount>0`，或每段 `ParaClient.Arrange` 到达计数），或至少把联合条件加上 `cParas>0 ∧ arrayParaDesc 非空`；② 载体把"恒 0"改为"**未取到读数（缺读取载体）**"，并补一个**对该计数口的显式读取**（导出口 `WpfLinuxWin32_PtsFsParaListConsumes/ResolveOk`）作为 `0` 的载体。
- **`W-3`（low）｜自源行号是**改前**代际的**：`P1-lm-consume2-report.md:19`／`:29` 引 `win32_pts.c:1117`／`:3575`／`:3597`／`:3577`，而交付代际 `27b023609512f74f` 里对应行现取为 `:1130`／`:3602`／`:3619`（`t194 numstat 42 0` 正落在此区间之前）⇒ 复核者按所引行号会落到别处。`requiredFix`：按交付代际重取行号（并沿用"行号仅本次有效"标注）。
- **`W-4`（low）｜"逐字一致"的粒度**：`P1-lm-consume2-report.md:59` 第 8 条行写「✅（A／B **逐字一致**）」而该行**粒度列＝整腿**；本席现取 `cmp app-wit1.log app-wit2.log` ⇒ **DIFFER（第 138 字节起）** ⇒ 只有 `[LMWIT]` **读数行**逐字一致，**整腿日志不一致**。`requiredFix`：改为「两样本**读数行**逐字一致（日志本体不同：地址等 138 字节起）」。

**反腿结论（派单要求的一句话）**：`t194` 的到达见证**不能**区分「算术成立但宿主没走到 `:174-180`」；该边界的**第一半**（`dvrUsed=0` 那半）已在载体 §5 如实写死 ✓，**第二半**（见证不在该段下游；`cParas=0` 逃逸口）**未写** ⇒ 本条按 §10 `W-2` 计入 `findings`。

## §11 证据在册 ＋ 资源 ＋ 自证

- 本件唯一写入：`build/MilBridge/P1-lm-consume2-verify.md`（`temp → os.replace`；临时件落 `/tmp/p1-lm-consume2-verify.tmp`）。
- 只读来源（现取）：`build/MilBridge/{P1-lm-consume2-report.md,P1-host-consume-route-criteria.md,P1-TASK-TEMPLATE.md}`（§A `:5-21` 已读）、`upstream/…/PtsHost/PtsHelper.cs`（`:145-181`／`:623-637` 整行）、`…/PtsHost/ContainerParaClient.cs`（`:41/:47/:69-72` 整行）、`src/WpfGfx.Linux.Native/src/win32_pts.c`（`:110-118`／`:1130`／`:1544-1559`／`:3602-3619`／`:3717` 整行）、`src/WpfGfx.Linux.Native/bin/{libwpfwin32.so,exports.txt}`（`nm`／`wc -l`）、`/home/links-dev/t123-runner/logs/t194/**`（四腿日志、`run.out`／`run2.out`、`so-*/`、`copyapp-*/`）。
- **资源（§A #10）**：`MemAvailable` 三次现取 ＝ **20244372 kB**（`22:51:34`）／**20232780 kB**（`22:51:36`）／**21374156 kB**（`22:51:38`）；`MemTotal=28831496 kB`；`SwapFree=2097148 kB`；`df -h /home` ⇒ `/dev/sda2 187G 104G 74G 59% /`。本件为**纯只读复核**：未起腿／未构建／未占显示位。
- **`P9`／`P10` 用在自己身上**：见 §7 反腿②（判 `W-1` 前先把"操作数确实无作者"用四条互不依赖的现取取证）；判 `W-2` 前先搜遍本车道找**读取载体**（只命中载体自身与二进制 ⇒ 确认"无读取"这一否定命题）。

**本件自证（落盘后）**：`head -n -1 build/MilBridge/P1-lm-consume2-verify.md | sha256sum | cut -c1-16` ＝ 59095ac60f913ea5（末行不计入自身；末行＝本行）

---

## ⏪ `t207`（A-1）dated 收窄 · `W-1` **分路径**（读时 `2026-09-29T23:25:07+0800`；**只增不改**、删行数 0、行号「仅本次有效」）

**来源**：`t206` 裁决（**照引**：载体 `build/MilBridge/P1-lm-consume3-verify.md`，末行自证 `818df822191c0c31`；**本席未独立复算**）。
**被更正的原文**（本件内，**一字未删**；**本席现取**行号「仅本次有效」）：`:37`（「今天**既无写入者、其宿主路径也不可达**」那句结论）、`:3`（判词行）、`:33`／`:3`（填写者与"未实现"两条）、`:38`（"必须收窄"那句）。
**收窄（逐字）**：上述写死的两句 —— 「**唯一填写者 ＝ `PtsHelper.cs:633`**」与「**`PtsHelper.cs:174-180` 不可达**」——
**只在 `subtrack-path`（`ContainerParaClient.cs:70→:72`）上成立；在 `track-path`（`PtsHelper.cs:134→:137`）上不成立**。
**优先规则（写死）**：本件凡此两句的表述，与本段冲突时**以本段为准**；上面原文**一字未删**。

`P1-LM-CONSUME2-VERIFY 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ b79f6c385a493b19`（⏪ `t207` 追加后重算；**上面历史自证行原文保留**）
