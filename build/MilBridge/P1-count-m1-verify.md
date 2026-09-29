# P1-W97 独立复核（`verifier`）—— `t172`（计数口／解除前置）＋ `t173`（`M1`／行为判别）

> **复核对象（现取，读时 `2026-09-29T19:34–19:5x+0800`）**
> - `build/MilBridge/P1-handle-count-report.md`（`t172`）：88 行／sha16 `34d111905d729dbd`／末行自证 **`3862c1b4165ba872`**（本席 `head -n -1 | sha256sum` 复算 **MATCH ✓**）
> - `build/MilBridge/P1-fsformatsubtrack-report.md`（`t173`）：105 行／sha16 `657aa706a681a56f`／末行自证 **`89b5ddc5e7716846`**（**MATCH ✓**）
> - **代际钉死（一律引提交内 blob，不引在飞工作树）**：`t172` ＝ `git show 68cb5f6:src/WpfGfx.Linux.Native/src/win32_pts.c` ⇒ **`1b642b1a906eb12f`／323433 B**；`t173` ＝ `git show c8d1ff3:…` ⇒ **`d8d784304ff735bf`／326923 B**（两版已抽到车道 `~/wv88y/t180/`）。当前工作树/`HEAD` 的 `.c` ＝ `d8d784304ff735bf` ✓（＝`t173` 代际），`.so`＝`352855f8dfbf8dc7`、`exports`＝669 行／`3942a1aafa41e1ca`。
> - **登记处**：`build/MilBridge/P1-ptsname-result.md`（裁定五十七／五十八原文，现取）。
>
> **八项判词总览**：①**成立**｜②**成立**（"抬高"不污染）｜③**成立**（必要，且反例场景具名）｜④**成立**｜⑤**成立**（`calls` 是同一把标尺，无 `t168` 式混用）｜⑥六形态**实现层成立**、但载体引的 witness 是**格式串常量**（`F-1` medium）｜⑦**成立**｜⑧两改判各有依据，但**解除按入口收窄**（`F-2` medium）。

---

## §1 第 1 项：`t172` 解除的**授权与射程** —— **成立**

**射程声明现取（载体在位的两处）**：`P1-handle-count-report.md:75`（"**只覆盖 native 自有台账**（`t162` 的 subtrack 对象族）；**托管侧 `PtsContext._unmanagedHandles` 的自由链仍没有只读口** ⇒ 那部分**仍 `NOINFO`**"）＋ `:85`（"不得读成'托管句柄表已可读／`+192` 的回收正确性已被证明'"）。**登记处同款**：`P1-ptsname-result.md:671`（裁定五十七 (c)：把 t172 这条当"**解除须带射程**"的范本）。
**"托管表确无只读口"本席现取的三条依据**：① 该表是**私有字段**：`upstream/wpf/…/MS/Internal/PtsHost/PtsContext.cs:558 private HandleIndex[] _unmanagedHandles;`（现取 sha16 `c91e3f94d1188ece`）；② **无任何 count 访问器/属性**（`grep -rn 'HandleCount\|HandlesCount'` 在该托管树命中的只是 `PtsContext` 内部的 `_unmanagedHandles.Length` 循环，不是对外口）；③ **运行期也没有它的读数**：`t172` 两样本的 `app_g1.log` 里 `unmanagedHandle\|HandleIndex\|freeList` 命中 **0**。
**R-4 禁引用句在位 ✓（两处都写死）**：载体 `:75`（"**`t158` R-4 原文照守**"）／`:85`（"后者需托管侧读数"）；**登记处** `:671` 原文："并**写死一句**「**`t158` R-4 的"回收正确性"判词不得引用本口当"托管表已正确回收"**」"。
**额外（本席补，供排期知道）**：托管侧**并非毫无校验手段** —— `PtsContext.cs:112-141` 在 `Invariant.Strict` 下于 dispose 期遍历该表并 `Invariant.Assert(obj is BaseParagraph || Section || LineBreakRecord, "One of PTS Client objects is not properly disposed.")`。它是**断言**（且需 Strict），**不是可读计数** ⇒ 不改变"无只读口"的结论，但意味着"托管表回收正确性"另有**一条需要开关的证明路径**，值得在解除射程里一并点名（`R-4` 今天仍 `NOINFO` 的准确理由是"没有**只读读数**"，不是"没有任何办法"）。
⇒ **判：射程真成立、禁引用句在位**（授权面见 §2.4/§8 的登记处文本）。

## §2 第 2 项：成对可证伪 —— **成立**，且"真台账抬高"**不污染** `distinct=1`

**本席现取（两样本逐字相同，`s1`／`s2`，`HCOUNTLEDGER` 各 4 行）**：
```
read#0  state=NO-READING live=-1 created=-1 destroyed=-1
腿 A    live_before=0 live_after=3 delta=3      created_before=1 created_after=4 destroyed=1            eq=1
腿 B    live_before=3 live_after=0 delta=-3     created_after=4  destroyed=1→destroyed_after=4          eq=1
pair=distinct live_A_after=3 live_B_after=0 distinct=1
```
**三式逐格自算（含载体没写的"起点那一式"）**：起点 `0 = 1 − 1` ✓（腿 A 行给出 `created_before=1 destroyed=1`）；腿 A `3 = 4 − 1` ✓；腿 B `0 = 4 − 4` ✓。
**"抬高"是否污染 `distinct=1`（派单的 ⚠️）—— 不污染，理由是可自算的而不是自陈的**：
- 两条腿的窗口里**恰好只有一个计数在动、且动的量恰为 `n=3`**：腿 A `created 1→4` 而 `destroyed` **冻结在 1**；腿 B `destroyed 1→4` 而 `created` **冻结在 4**。若期间引擎另有建/回收，则①另一个计数会动，或②`delta ≠ ±n` ⇒ 两者都**没有**发生。
- 基线非零（`created=1 destroyed=1`）只抬高**绝对值**，不改变**差值**；而本判据用的正是差值（`delta=±n`）与差值自洽式（`live = created − destroyed`）。⇒ **抬高对"计数口真的在数"这一结论无障碍**。
- 另加一条口径（本席补，避免误读来源）：两条腿**不是两个独立进程**，是**同一趟里的先后两段**，腿 B 的 `live_before=3` 就是腿 A 的 `live_after` ⇒ `distinct=1` 的准确含义是"**同一计数器在两个时点的取值不同**"；**独立复现由 `s1`／`s2` 两样本承担**（两者逐字相同 ✓）。
**"独立于 `rc`"复核**：四条读数的取值只来自 `g_pts_sub_live_n`／`g_pts_sub_created`／`g_pts_sub_destroyed`（钉版 `:1176-1178` 定义、`:1194-1195` claim 自增、`:1207` destroy 自增、`:1298-1301` 端口出口）⇒ 与本趟任何 `rc` 无关 ✓（症状门另列，见 §4）。
**样本门（现取两样本同格）**：`leg_23/24.env`：`alive=yes app_rc=143 magenta=0 colors=383 ns=RichTextBoxDemo/FlowDocumentDemo ae=0/15386 ink=480000`；`NAMED managed_unavail=0 err=- native_gap=0 native_err=-`；`FAILLINE k=23/24 failfast=0 unrec=0` ✓。

## §3 第 3 项：`P8` 落实（`-1` vs 真的 `0`）—— **成立**；"先读 state"**必要**且反例具名

**现取（两样本）**：`read#0 state=NO-READING live=-1 created=-1 destroyed=-1 v=NO-READING-DISTINCT-FROM-ZERO` vs 初始化后 `state=READING live=0/3 …`。
**源码现取（钉版 `t172`）**：`:1184 static int g_pts_hc_reading = 0;`、`:1196` 台账一建即置 1；四个端口 `:1298-1301` 一律 `return g_pts_hc_reading ? <真值> : -1;`（`PtsHandleReadingState` 返 0/1）⇒ **"没取到"与"真的 0"判词不同**：`(-1, NO-READING)` vs `(0, READING)` —— 后者在腿 B 真的出现（`live_after=0 state=READING`）⇒ 这一对**不是纸上区分**，两份读数都在册。
**"必须先读 `PtsHandleReadingState`" 的必要性 —— 必要，反例场景具名（本席自找）**：哨兵只加在**计数口**上；同族的 `WpfLinuxWin32_PtsSubClaimOk`／`…ClaimBad`／`…SelfTestMask` 现取仍是 `return g_pts_sub_claim_ok;` 等**裸值**（钉版 `:1302-1304`，本笔 3 处删除只重写了三个 `PtsSub{Live,Created,Destroyed}` 体，未动这三个）。⇒ 反例：**台账尚未建立时**这三个口返 0，与"真的 0 次认领"**完全同形**；一个按 `claim_ok == 0 ⇒ 零认领/无异常` 下结论的消费者会把"没读数"读成"没问题"（正是 `P8` 的"缺省值改控制流"）。⇒ 对**计数口**本身尚可用 `<0` 自判，但对**这三个兄弟口**只剩 `PtsHandleReadingState` 一条路 ⇒ 裁定五十七 (e) 把它写成"后续引用该口必须先读"是**必要**的。
**残留半格（low）**：上述三个兄弟口今天仍无哨兵 ⇒ 建议下一波补齐（本件只报）。

## §4 第 4 项：导出面 —— **成立**

- `exports.txt` 现取 **669 行**；`nm -D --defined-only | wc -l` ＝ **669**（两侧相等 ✓）；四个新名在 exports 与 `nm` 里**各命中 1** ✓；`^Fs` ＝ **6**，名单现取 `FsCreatePageBottomless／FsCreatePageFinite／FsDestroyPage／FsQueryPageDetails／FsQueryTrackDetails／FsQueryTrackParaList` ✓。
- **"逐名无消失"本席独立复算（不引其自陈）**：`exports.txt` 是 `nm` 直出（`src/WpfGfx.Linux.Native/Makefile:57`），而**本笔只改了一个翻译单元** ⇒ 我按**源级非静态定义名集**对拍两代际：pre(`6d6f753105224f78`) **173 名** → post(`1b642b1a906eb12f`) **177 名**，**消失 ＝ 空** ✓，新增恰 4 名 `WpfLinuxWin32_PtsHandle{Live,Created,Destroyed}Count`／`…ReadingState` ✓。
- **本笔 3 处删除现取**（`-U0` 只看删除行）：`int WpfLinuxWin32_PtsSubLive/Created/Destroyed(void) { return g_pts_sub_*; }` 三行 —— 即"被加哨兵后重写的三个旧端口体"，**不是判据删除** ✓。
- `tools/pts-gap-decl.txt` 本笔 diff 现取：**只** `so16=291ef08a33f9b6e4→352855f8dfbf8dc7`、`exports=665→669`（同一行替换）✓。
- 症状门逐格见 §2 末（两样本同格）✓。

## §5 第 5 项（重点）：`t173` 行为判别 —— **成立**；`calls` **同一把标尺**（无 `t168` 式混用）

**"同副本只差 `M1` 一个变量"本席现取三条**：
1. **构建命令行**（`t173/run.sh` 现取）：`:36 build_copy "-DWPF_PTS_FSP_PL_METHODS_SNAP=1 -DWPF_PTS_FSP_PL_ENGINE_DRIVE=1 -DWPF_PTS_FSP_PL_M1=1" so-m1` ／ `:37 build_copy "…SNAP=1 …ENGINE_DRIVE=1" so-nom1` ⇒ **只差 `-DWPF_PTS_FSP_PL_M1=1`**，同一源树同一提交 ✓；
2. **源码边界**（钉版 `t173`）：宏 `:105-108`（`#ifndef … #define WPF_PTS_FSP_PL_M1 0`）、实现 `:1487 #if WPF_PTS_FSP_PL_M1` … `:1529 #endif` ⇒ 全部新增在块内、缺省 0 ✓；
3. **产物**：`so-m1/libwpfwin32.so` ＝ `5f92bf431a48f6c9`、`so-nom1/…` ＝ `cb92d00b76da9f57`（本席现取；`run.out:7-8` 两次构建逐行对应 ✓）；腿 X 与 X2 **同一产物**（`run_copy m1`／`m1b`，`run.sh:38/:40`）✓。
**判别读数（本席现取，三腿）**：
| 腿 | 产物 | `phase=slot3`（驱动侧真读数） | `[FSFORMATSUBT]` 行数 | `where=` |
|---|---|---|---|---|
| **Y** | `cb92d00b76da9f57` | **`rc=-100002`** | **0** | `FsCreatePageBottomless` |
| **X** | `5f92bf431a48f6c9` | **`rc=0`** | **1** | `FsCreatePageBottomless` |
| **X2** | `5f92bf431a48f6c9` | **`rc=0`** | **1** | `FsCreatePageBottomless` |
⇒ **同一驱动点、同源同构建、只差 M1 ⇒ `rc` 由 `-100002` 变 `0`** ✓。**旁证（本席补，载体未引）**：驱动侧的 agent 回读也随之改变 —— Y：`o_fsfmtr=0`；X／X2：`o_fsfmtr=1 o_dvrUsed=0 o_dvrTopSpace=0 o_breakpos=0` ⇒ 补上入口后**出参才按契约被写出**，与"该入口原缺 ⇒ 回调抛异常被 catch 成 `-100002`"**互为因果两端**（不是只有 `rc` 一个数字变）。
**`calls` 是否为同一把标尺（派单点名核 `t168` 同类问题）—— 本件没有该问题**：`[FSFORMATSUBT]` 行里的 `calls=%d` 现取＝**真计数器** `g_pts_m1_calls`（钉版 `:1495` 定义、`:1508` 入口自增、`:1526` 打印），**不是字面量**；且**行数与计数器自洽**（Y 0 行、X／X2 各 1 行）⇒ "真的被调用"由"**行数**＋**计数器**"两条同尺证据支撑 ✓。（对照 `t170` 已证的 `t168` 病：那里 `calls=` 取自 `rb_calls` 而"门未开腿"另用别的计数器 —— 本件不存在这种跨尺混用。）

## §6 第 6 项：六形态 ＋ `S-1`/`S-2` 分列 —— **实现层成立**；但载体引的 witness 是**格式串常量**（`F-1`）

**六形态本席现取两路证据**：
- **实现路（钉版 `t173` `:1508-1517`）**：`g_pts_m1_calls++`；`*out_fsfmtr_kstop = 1`（①）、`*out_ppfs_subtrack = NULL`、`*out_brk_subtrack = NULL`（⑥）、`*out_dvr_used = 0`（③）、`memset(out_bbox,0,20)`（④）、`*out_mcs_out = NULL`（②）、`*out_kclear_out = 0`、`*out_top_space = 0`（⑤）⇒ **六条都被真的写进调用方的出参** ✓。
- **回读路（驱动侧，本席现取）**：X／X2 的 `phase=slot3 … o_fsfmtr=1 o_dvrUsed=0 o_dvrTopSpace=0 o_breakpos=0` ✓；`pfspara=(nil) rewritten=1 claim=0`、`asserts … C_claimable=0 D_one_new_entry=0 v=E2-ASSERTS-PARTIAL`（**没有任何"成功／可认领"读数**）✓。
- ⚠️ **但载体 §2（`:32-48`）把 `[FSFORMATSUBT] … OUT kstop=1 ppfsSubtrack=(nil) brkOut=(nil) dvrUsed=0 bbox=flat mcOut=(nil) kclearOut=0 topSpace=0` 标成"逐条现取"** —— 那七个 token 在钉版 `:1521-1522` 是**格式串里的字面文本**（连 `rc=0` 也是 `:1518` 的字面，函数 `:1527 return 0`），**不是对出参的回读** ⇒ 该行**不可证伪**（若哪天写入 `dvrUsed=7`，这一行照旧印 `dvrUsed=0`）。见 §11 `F-1`。
**`S-1`／`S-2` 分列** ✓（载体 `:50-53`）：`S-1`＝"契约占位成立"（六形态＋具名留痕＋≥2 样本同判＋`calls=1`）；**`S-2`＝真造型：`🔴 维持 NOINFO`**，并明写"`ppfsSubtrack=(nil)` **不得**被读成排版成功"⇒ 本席在**原始日志**里也**没有**找到任何把 `(nil)` 读成成功的行（驱动侧只有 `E2-ASSERTS-PARTIAL`、`claim=0`）✓。

## §7 第 7 项：粒度声明在位 ＋ `app_rc=134` 与 `S-1` 并存如实记 —— **成立**

- **载体在位**（`:53` 现取）："三条腿（X／Y／X2）**最终都 `app_rc=134` 且 `failfast=1`**（发生在 `M1` 调用**之后**…）⇒ **`S-1` 是"单次调用"级判词、不是"整腿绿"**；不得用"腿没崩"或"腿崩了"任一方向读它" ✓。
- **登记处同款在位**：`P1-ptsname-result.md:687`（裁定五十八 (e)）逐字复述该句，并把它升格为口径（"'绿'必须带它成立的粒度"）✓。
- **并存事实本席现取**：`t173/run.out` 三腿**都** `navclick_rc=1／alive_during=no／app_rc=134／failfast=1／unrec=2`；且**顺序**可核——`[FSFORMATSUBT]` 行号（X `638`、X2 `667`）**早于**该腿首条 `Unrecoverable system error.`（`828`）⇒ "崩在 `M1` 调用**之后**"**不是措辞，是行序** ✓。⇒ 没有被含糊过去 ✓。

## §8 第 8 项：两个前置改判各有现取依据 —— **依据成立**，但解除须**按入口收窄**（`F-2`）

- **`PRECOND-NATIVE-FORMAT-ENTRY-MISSING`**：依据＝§5 的**只差一变量成对实验**（`-100002 → 0`）＋ 出参回读同步由 `o_fsfmtr=0` 变 `1` ⇒ "缺入口"这一因果**被行为证实** ✓（不是靠"腿没崩"）。⇒ **就其点名的那个入口（`FsFormatSubtrackFinite`）而言可解除** —— 载体 `:30` 的限定词"（若 `rc` 不变才须改判）"与登记处 `:685` 的"（就'缺入口'这一因果而言）"**都在** ✓。
- ⚠️ **但同类入口还有一个仍缺**：`FsQuerySubtrackDetails` —— 现取 `exports.txt`（669 行）里命中 **0**、钉版 `t173` 源里只有 1 处**注释**、而**三条腿各 2 条** `EntryPointNotFoundException … 'FsQuerySubtrackDetails' in shared library 'PresentationNative_cor3.dll'`（**连 M1 腿也在**，`run.out` 三腿 `enfe=2` 同名）⇒ "缺 native 入口"这一类**没有清空**。见 §11 `F-2`。
- **`PRECOND-NO-LAYOUT-MODEL`**：依据＝本波造型入口只产出"诚实无进展"（`kstop=1`＝目标未达成、`ppfsSubtrack=(nil)`、`dvrUsed=0`、bbox 平空、`o_dvrTopSpace=0`），`pfspara` 未被产出、内容面 `NOINFO` ⇒ **"本波无排版模型"成立** ✓，且**它是一句否定命题**，其依据是"链被真走过（slot 3 真被调用）却没有产出" ⇒ 与"没走到就说不存在"（`P9` 反面）**有别** ✓；载体据此**只**让 `S-2` 维持 `NOINFO`（`:52`、`:81`）⇒ 未被顺手读成排版成功 ✓。

---

## §9 推翻的话

**读数面没有推翻任何一条**：`t172` 的 `read#0 -1`、"`3=4−1`／`0=4−4`"、`distinct=1`、导出 4 名与 `^Fs=6`；`t173` 的 `-100002 → 0`、`[FSFORMATSUBT]` 行数 0/1/1、六形态、三腿 `app_rc=134` 与"崩在 M1 之后"，**全部在原始件/钉版上独立复现**。
**我推翻的是三条"证据类/射程"的说法**：① `t173` 把 `[FSFORMATSUBT]` 那行（**格式串常量**）当"逐条现取"（§6／`F-1`，medium）；② `PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 被记作整类可解除，而同类另一入口 `FsQuerySubtrackDetails` 仍缺（§8／`F-2`，medium）；③ "成对两腿"被读成两趟独立时的强度（实为同一趟先后两段；独立复现由 `s1`/`s2` 承担，§2）—— 第三条**不改变结论**，只精确化来源。

## §10 具名 `NOINFO`

- **`N-1`** 托管表（`_unmanagedHandles`）的**活条目数**：仍无只读口 ⇒ `R-4` 回收正确性**仍 `NOINFO`**（射程内已写死）✓ —— **这不是缺陷，是射程**。
- **`N-2`** `PtsSubClaimOk`／`ClaimBad`／`SelfTestMask` 在**未建立台账**时**无法与真 0 区分**（无哨兵）⇒ 这三个口今天"没读数"格不可判（§3）。
- **`N-3`** `[FSFORMATSUBT]` 行的**六 token 无回读** ⇒ 该行**不构成**对六形态的读数（只能作"该函数被调过"的在场证据）；六形态的**可证伪读数**只存在于驱动侧回读（`o_fsfmtr=1 o_dvrUsed=0 o_dvrTopSpace=0 o_breakpos=0`）与源码写入（§6）。
- **`N-4`** `FsQuerySubtrackDetails` 的**消费链后果**：入口仍缺，但本件未测其下游影响（`enfe=2` 只证"仍缺"）⇒ 该入口解锁后的行为**不可判**（§8）。
- **`N-5`** 腿 X／X2 的 `app_rc=134` 的**成因**：本件只读到位序（`[FSFORMATSUBT]` 早于 `Unrecoverable`）与 `failfast=1`，**未**取到该次 FailFast 的具名原因（属另一条路径）⇒ 不判。

## §11 新发现的 medium 以上问题（本件**不修**；点名 `文件:行` ＋ 机制）

- **`F-1`（medium）｜"留痕行 ≠ 读数"**：`build/MilBridge/P1-fsformatsubtrack-report.md:32-48` 把 `[FSFORMATSUBT] … OUT kstop=1 … topSpace=0`（含 `rc=0`）当"**逐条现取**"列出并逐格 ✅。机制：这些 token 在 `win32_pts.c`（钉版 `t173`）`:1518`／`:1521-1522` 是**格式串字面量**，对出参的真正写入在 `:1509-1516`，**打印不做回读** ⇒ 该行**恒真、不可证伪**（P10/P12 同族：印什么就断言什么）。**为什么是缺陷**：本会话的判据纪律要求"留痕行必须能证伪"；此处六形态的**真读数其实已经在手**（驱动侧 `o_fsfmtr/o_dvrUsed/o_dvrTopSpace/o_breakpos`），却引了那条恒真行 ⇒ 下一件若照抄这个范式，会把"常量声明"当"实测"。**修法**（下一波，只增不改）：① 载体改引驱动侧回读行；或② 把 `:1518-1526` 的 `fprintf` 改成回读（填 `%d/%p` 实数），并给 `S-1` 加一条"留痕行必须含≥1 个回读字段"的自检。
- **`F-2`（medium）｜解除未按入口收窄**：`P1-fsformatsubtrack-report.md:30`／`:80`（"`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 由「假设」升为「读数」…**可解除**"）与登记处对同一前置的处置，只带了**因果面**限定词（"就缺入口这一因果而言"），**没有**点明"哪只入口解除、哪只仍缺"。现取：`FsQuerySubtrackDetails` 在 `exports.txt`（669 行）**0 命中**、在钉版源里仅注释、**三条腿各 2 条 ENFE**（含 M1 腿）⇒ 该类缺口未清空。**为什么是缺陷**：前置名是**类名**，下一件据此会把整类（含仍缺的那个入口）一并免掉，排期上等于把一条**仍在**的硬阻塞标记为"已解决"（与裁定五十九 立的"解除越权"同族）。**修法**：把前置登记改成**按入口**（`PRECOND-NATIVE-ENTRY-MISSING(FsFormatSubtrackFinite)`＝可解除；`…(FsQuerySubtrackDetails)`＝**仍开**），并在载体 §7 逐入口列状态。
- **low 观察（一并记，不必单开件）**：① `[FSFORMATSUBT]` 的 `rc=0` 与函数恒定 `return 0` 一致，但**不得**与驱动侧 `phase=slot3 rc=` 混读（载体引用正确 ✓）；② `verify=NONE(…)`／`v=HONEST-NO-PROGRESS` 亦为字面；③ `PtsSubClaimOk/Bad/SelfTestMask` 无哨兵（§3 残留半格）；④ `t172` 两腿是同一趟先后两段而非两趟独立（§2，仅口径）。

## §12 证据在册（仓内只读；车道仓外）

- 本件唯一写入：`build/MilBridge/P1-count-m1-verify.md`（新建）。
- 钉版源码副本：`~/wv88y/t180/win32_pts.t172.c`（`1b642b1a906eb12f`）／`~/wv88y/t180/win32_pts.t173.c`（`d8d784304ff735bf`，由 `git show` 现取）。
- 原始读数件（只读）：`/home/links-dev/t123-runner/logs/t172/{s1,s2}/{app_g1.log,leg_23.env,leg_24.env}`、`t172/run.out`；`t173/{app-nom1.log,app-m1.log,app-m1b.log,run.out,run.sh}`、`t173/so-{m1,nom1}/libwpfwin32.so`；登记处 `build/MilBridge/P1-ptsname-result.md`；托管侧 `upstream/…/PtsContext.cs`；构建面 `src/WpfGfx.Linux.Native/Makefile`、`tools/pts-gap-decl.txt`。
- 手段：`git show`／`sha256sum`／`nm -D`／`grep -ac`／`sed -n`／源级名集对拍（python 只读）⇒ 全部只读；未跑腿、未构建、未占显示位、未跑整门禁、未 `git add/commit/push`。
- **`P9`／`P10` 用在自己身上**：下"证据类被抬高"（`F-1`）之前，我先证明**那个条件真的被检了** —— 逐行读了钉版 `:1508-1527`（确认写入在 `:1509-1516`、打印在 `:1518-1526` 且六 token 全在格式串内），并在**驱动侧**找到了本可替代它的真回读（`o_fsfmtr` 等）⇒ 不是"没找到回读就说不存在"。下"同类另一入口仍缺"（`F-2`）之前，我**三处**独立取了它仍缺的证据（exports 0 命中、源内仅注释、三腿各 2 条 ENFE）。

**本件自证（落盘后）**：`head -n -1 build/MilBridge/P1-count-m1-verify.md | sha256sum | cut -c1-16` ＝ 4239c2ebc4121d18（末行不计入自身；末行＝本行）
