# P1-W95 独立复核（`verifier`／`t189`）—— `t176` 三条必修的落账

> **判词：`pass`**（三条必修**真落账**、方向只有收紧；另点名 1 条 medium ＋ 2 条 low **附带**问题，见 §10——**均不改变本判词**，理由写在 §2.4／§10）。
>
> **复核对象（本席现取，读时 `2026-09-29T20:00:50–20:03+0800`）**
> - 载体 `build/MilBridge/P1-w95-report.md`（`t176`）：**63 行**／sha16 **`f6e6187758313ae9`**／末行 `self16=56363a9bad6c72e0`（本席 `head -n -1 | sha256sum | cut -c1-16` 复算 **MATCH ✓**）
> - 落点件 `build/MilBridge/P1-fsimethods-drive-report.md`：**152 行**／sha16 **`63326eeb9ac670ee`**／末行自证 **`86eeec48f329e9f5`**（复算 **MATCH ✓**）
> - 改前代际：`HEAD`（`d7830c9`，`2026-09-29T19:43:23+0800`）版 ＝ **107 行**／`e1d50d10d7091b42`（本席 `git show HEAD:` 现取）
> - ⚠️ **在飞声明**：`build/MilBridge/P1-fsformatsubtrack-report.md` 在 **20:01:55** 被**另一写者**改动（现取 `18ed4d7def636003`／143 行，t176 与 `t180` 读到的都是 `657aa706a681a56f`／105 行）⇒ `t176` 对它的引用**在其读时正确**、今天已过期（非 `t176` 之责）。本件只读、不改任何人写的件。
>
> **§A 通用硬约束自用**：本件引用一律**整行取**（`awk`／`grep -n`）；引他人读数带**代际＋时刻**并标「未独立复算」（见 §5／§9）；资源三值见 §11；未碰 `tools/**`／`tests/**`／`docs/**`／`.cs`／`src/**`／两枚哨兵／`HANDOFF-NEXT.md`；未 `git add/commit/push`（§6）。

---

## §1 判据① 只增不改（三层，逐层现取）

| 层 | 命令（本席现取自算） | 读数 | 判 |
|---|---|---|---|
| ① 对 `HEAD` 的 numstat | `git diff --numstat HEAD -- <落点件>` | **`45	0`** | ✅ 与 `t176` 所报一致 |
| ② 删行数 | `git diff HEAD -- <落点件> \| grep -c '^-[^-]'` | **0** | ✅ 零删行 |
| ③ 加行核算（防"numstat 虚高"） | `grep -c '^+'`（含 `+++` 头）／`grep -c '^+[^+]'`／`grep -c '^+$'` | **46（含 1 行头）／34 非空／11 纯空** ⇒ 45 ＝ 34 ＋ 11 | ✅ 自洽 |
| ④ 三处被更正原文锚**在场**（整行、带行号） | `grep -n` | `:40` ＝ `⇒ **`D2` 结论（重判）：`SLOT-ORDER-OK` —— 槽序指纹支持"槽序正确（未错位）"，`NOINFO-FSIMETHODS-ABI` 的"槽序"部分据此解除**（详见 §5）。`；`:96` ＝ `\| 1 \| **槽序/ABI（`NOINFO-FSIMETHODS-ABI`）** \| **"槽序"部分已解除**：…`；`:66` ＝ `\| `calls` 值 \| **`calls=1`（首调）／`calls=2`（第二驱动点）**；`calls=0` 仅出现在 D3 门未开的两条副本腿上 \| ✅ 分开报 \|`；`:70` ＝ `**归因（现取，具名）**：…**native 的造型入口 `FsFormatSubtrackFinite`**（本波**未实现**…` | ✅ **四处锚原文一字未删** |
| ⑤ 旧自证行保留 | `grep -n 'a6d7a4bc641f3e80'` | `:107` 在场（新自证在 `:152`） | ✅ |
| ⑥ `t176` 自报的抽样命中复核 | `grep -c` | `槽序指纹支持`=2／`部分已解除`=2／`FsFormatSubtrackFinite`=5／`t173`=2／`自证`=4 | ✅ **逐值与其自报相同** |

## §2 判据② `F-1`（high）：方向只有收紧 ＋ 收窄句保真 ＋ 逐槽登记

**2.1 `NOINFO-FSIMETHODS-ABI` 记未解除 ✓**：落点件 `:118` 现取「**`NOINFO-FSIMETHODS-ABI` 未解除**」（整行），且 `:112-113` 给出理由（零位不动 ⇒ 允许 16 个非零槽任意置换；数据源＝被检方、索引＝native 自己的拷贝字节序 ⇒ 对「native 假设语义 ↔ 托管声明」结构上盲）。

**2.2 收窄句 vs `t167`／`t168` 原始读数 —— 本席逐子句对拍（**不过头**）**
| 收窄句成分 | 本席现取依据（原始件） | 判 |
|---|---|---|
| 「**第 1 槽（常量级）有语义指纹**」 | `t168/app-snapdrive.log:833` ＝ `[FSPARALIST-EDRIVE] phase=slot1 rc=0 sobjc=0x1b63 pre=0xa5a5a5a5a5a5a5a5 rewritten=1 idobj=7001 ffi=0x1 author=… v=OBJCTX-PRODUCED`；`:993` ＝ 同式 `sobjc=0x1b64 … idobj=7002`（本席自算 `0x1b63`=7011=`7001+10`、`0x1b64`=7012=`7002+10`）；装配绑定现取 `PtsCache.cs:603 subtrackParaInfo.pfnCreateContext = new PTS.ObjCreateContext(ptsHost.SubtrackCreateContext);` ＋ 公式 `PtsHost.cs:2652 pfssobjc = (IntPtr)(idobj + _objectContextOffset);`（`:93 _objectContextOffset = 10`，族另一支 `:2967` 为 `+1` ⇒ 可区分 subtrack/subpage） | ✅ 「常量级」**不过头** |
| 「**第 3 槽（名级，且其名只出现在主链 `Pts.FsCreatePageFinite` 路径）**」 | `app-snapdrive.log:1002` ＝ `   at MS.Internal.PtsHost.PtsHost.SubtrackFormatParaFinite(IntPtr, …)`，`:1003/:1004` ＝ `   at MS.Internal.PtsHost.UnsafeNativeMethods.PTS.FsCreatePageFinite(…)`（**主链托管帧**）；装配绑定现取 `PtsCache.cs:605 subtrackParaInfo.pfnFormatParaFinite = new PTS.ObjFormatParaFinite(ptsHost.SubtrackFormatParaFinite);` | ✅ 括注**保真**（该名确实只出现在主链帧里；驱动格那次 `f3(...)` 调用只到 `rc=-100002` 强度） |
| 「**其余 15 槽仅「非空 ＋ 零位一致」**」 | `app-snapdrive.log:686-687` ＝ `nonzero=16 zero_index_win=14` ＋ `zero_cnt_win=1 idx0_zero=14 slotN_zero=15`；`:830` ＝ `[FSPARAMETH-D2] … zero_cnt_win=1 idx0_zero=14 slotN_zero=15 … v=SLOT-ORDER-OK(…)` ⇒ 「非空」＝16 非零字、「零位一致」＝恰一处且落 15 槽；**未验**＝除 1、3 外无任何调用/名级痕迹（本席在 `t180` 与本次都只在驱动格里找到 `phase=slot1`×2 与 `phase=slot3`×1） | ✅ **不过头、也不写过头** |
| 「…那是**必要条件**，不是「槽序未错位」的结论」 | 与判据件一致：`P1-fsimethods-abi-recon.md` 全文 `解除` **0 命中**（本席现取）＋该件 `:122` 只写单向（否则错位**确证**） | ✅ 方向＝**收紧** |

**2.3 逐槽登记表 17 槽齐 ✓（附 1 处数字标注错，见 `V-2`）**：表行现取＝`1`／`2`／`3`／`4–17` ⇒ 覆盖 `1..17` **齐 17 槽** ✓；`1 已验`（依据：常量级指纹，见 2.2 第一行）✓、`3 已验（限名级）`（依据：名级帧＋装配绑定）✓、`2` 与 `4–17` `未验`（依据：无指纹）✓。
**2.4 出处更正落账 ✓**：落点件 `:117` 现取「…**判据件里没有这句**〔**引自** `t170` `F-1`；**本席未独立复算**其 `grep` 计数〕⇒ 该句**不得**再作解除依据」⇒ ① 结论与本源取一致；② 明确标注了出处（`t170`）与"未独立复算"（符合 §A #14）。⚠️ 本席**独立复算**：`grep -c '解除' P1-fsimethods-abi-recon.md` ＝ **0** ✓（该项从此**有**独立复算）。
⇒ **判 `F-1` 落账且方向只有收紧**；附带形状问题只两条（`V-2` low／`V-3` low），**均非"超出读数"** ⇒ 不触发 `needs_revision`（派单给的红线是"该句仍有超出读数的成分"，本席逐子句核后**没有**）。

## §3 判据③ `F-2`：witness 改引 ＋ 两族计数器分开 —— **落账且与原始件逐值相符**

**本席自算四腿 × 四标签（`grep -ac`，读时 `2026-09-29T20:01:46+0800`，`/home/links-dev/t123-runner/logs/t168/`）**：
| 腿 | `[FSPARALIST-EDRIVE]` | `[FSPARAMETH-D3] gate=` | `[FSPARAMETH-READBACK]` | `[FSPARALIST-PARA-IN]` |
|---|---|---|---|---|
| `app-snapdrive` | **6** | 2 | 2 | 2 |
| `app-snap` | **0** | 3 | 3 | 2 |
| `app-null` | **0** | 3 | 3 | 2 |
| `app-allzero` | **0** | 3 | 3 | 2 |
⇒ 与落点件 `:130-135` 的表**逐值相同** ✓；`6 vs 0` witness 成立 ✓。
**两族计数器是否真分开（本席从钉版源码现取，不复述其结论）**：`t168` 代际（`git show 1e29ffd:` ⇒ `6d6f753105224f78`）`:584 t->rb_calls++; t->rb_same = (diff < 0) ? 1 : 0; t->rb_first_diff = diff;`（＝ `[FSPARAMETH-READBACK] … calls=%d` 的来源，**回读序**）；`:1747` 的 `[FSPARALIST-PARA-IN] … calls=%d` 打印实参在 `:1750 g_pts_dp3_calls`（**另一支探针的窗口计数**）⇒ **两族确实不同** ✓。⇒ 判 `F-2` 落账（**证据链更正**：不改判据、不放松）。

## §4 判据④ `F-3`：点名更正 —— **落账**，但更正段的收尾句有 `V-1`（medium）

**点名更正 ✓（本席自算）**：`grep -ac 'FsFormatSubtrackFinite' t168/app-snapdrive.log` ＝ **0**；`grep -ac 'FsQuerySubtrackDetails'` ＝ **2**，且整行带行号为 `:842` ＝ `[HC-UNHANDLED] #1 EntryPointNotFoundException: Unable to find an entry point named 'FsQuerySubtrackDetails' in shared library 'PresentationNative_cor3.dll'. ｜ 首帧 at MS.Internal.PtsHost.UnsafeNativeMethods.PTS.FsQuerySubtrackDetails(…)`、`:848` ＝ `#2` 同式 ⇒ 落点件 `:146-147` 所写**逐字相符** ✓。`t168` 代际 native 侧两入口**都只有注释**（钉版现取：`FsQuerySubtrackDetails` 命中 1、`FsFormatSubtrackFinite` 命中 1，均为注释行）⇒ 落点件「`FsQuerySubtrackDetails` 现取无实现」✓。
**「`t173` 未白做」是否有可证伪支撑（不是空口安慰）**：本席**从 `t173` 车道原始日志现取** —— `app-nom1.log`：`[FSFORMATSUBT]` **0 行**、`phase=slot3 rc=-100002`；`app-m1.log`／`app-m1b.log`：各 **1 行**、`phase=slot3 rc=0`（两样本同判）⇒ ① "补 `M1` 后同一槽 3 调用 `-100002 → 0`" **有读数** ✓；② `M1` 六形态、③ `S-1` 成立／`S-2` 维持 `NOINFO` 两项本席在 `t180` 已从钉版源码与驱动侧回读核过（`win32_pts.c` M1 块 `:1487-1529` 六条写入 `:1509-1516`；驱动侧 `o_fsfmtr=1 o_dvrUsed=0 o_dvrTopSpace=0 o_breakpos=0`）—— 本件**不重复**那两格、只标「前件已独立复核」。⇒ **该句有可证伪支撑** ✓。

## §5 判据⑤ 自伤更正是否诚实 —— **诚实且可复核**

| 项 | 本席现取 | 判 |
|---|---|---|
| 自伤①（自证范围算错） | `P1-w95-report.md:23` 现取：两值并列 `221ee760d2f20714` vs `7af0b8eb3cb5f485`、处置＝从备份**逐字还原**后修脚本重跑、终态 MATCH=YES、并写「**已在册、不掩盖**」 | ✅ 留档（原错句＋更正句**都在场**） |
| 自伤②（初稿误称"不在 `HEAD`／`??`"） | 同件 `:61` 现取：`⏪ 本载体自报口径更正（dated…）` 逐字留档错句「该件**不在 `HEAD`**（`git status --porcelain` 为 `??`）」，并给硬读数 `IN-HEAD=yes` | ✅ 留档 |
| 「还原后交付态 ＝ 它声称的那一代」 | 落点件现取 **152 行／`63326eeb9ac670ee`** ／自证 `86eeec48f329e9f5` 复算 MATCH ✓；`numstat 45 0` ✓；改前锚＝`HEAD` 版 107 行/`e1d50d10d7091b42` ✓ | ✅ 相符 |
| 「改前无第三方漂移」（其 `cp -p` 备份 vs `HEAD`） | `~/w281-scribe/t176/bak/P1-fsimethods-drive-report.md.pre-t176`：`ls -l` 11671 B、`sha256sum`＝`e1d50d10d7091b42`；`git show HEAD:<落点件> \| sha256sum`＝同值；`cmp` ⇒ **IDENTICAL ✓** | ✅ **本席独立复算**（这条原先只有它自陈） |

## §6 判据⑥ 越域 —— **未越域**（含"在飞第三写者"的区分）

- **`git status --porcelain`（现取）**：`M build/MilBridge/P1-fsimethods-drive-report.md`（＝`t176` 的落点）＋ **`M build/MilBridge/P1-fsformatsubtrack-report.md`（mtime `20:01:55` > `t176` 的 `19:57:45` ⇒ 后到写者，非 `t176`）** ＋ 若干 `??` 新件（`P1-f1f2-verifyfix-report.md` 等）。**无 `src/**`／`tools/**`／`tests/**`／`docs/**`／任何 `.cs`／`HANDOFF-NEXT.md`** ✓。
- **两枚哨兵**（具名现取 `HANDOFF-NEXT.md:119`：`/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag`）：两者 `mtime=2026-09-29 19:51:25`（**早于** `t176` 的 19:57:45）＋ `cmp=IDENTICAL` ⇒ **`t176` 未写哨兵** ✓。
- **未 `git add/commit/push`**：`git diff --cached --name-only` ⇒ **0 行**（无暂存）✓；`HEAD` ＝ `d7830c9`（19:43，早于本件落盘）⇒ **未提交** ✓；`push` 面本席**不可判** ⇒ 具名 `NOINFO`（§9 `N-3`）。

## §7 反腿（本席自造，一对）

**反腿①「另一条也以零位吻合为据的推理」**：构造 —— *「若槽序错位（含整表位移 k），托管那只 NULL 字段就会落在别的槽；实测恒为 15 槽 ⇒ 槽序未错位」*。**用现有读数与代码路径推翻它**：
- 零位由 native 在**自己拷贝的副本**上按 `methods_snap[i*8+b]` 逐字统计（钉版 `:540-545`）、判据 `:603 ok = valid && zero_cnt==1 && rb_zero_index_win==14`；而**被调的槽**是按 `(const char *)m + 0`／`+ 16` 取指针（`:1491-1492`）。**两条路径互不引用**：native 侧对"第几槽是什么"的**任何**假设都不改变打印出的零位 ⇒ 该推理**无效**（这正是收窄句括注的理由）。
- 仅有的战果是**统一位移**：位移 `k` ⇒ 零位应落 `slotN = 15 − k`（`k=+1` ⇒ 应见 14）。**收窄句连这条都没主张** ⇒ **保守方向**，不是过头。
- 反过来说：若把 `methods_snap` 当成"native 槽语义证明"，则 `t168` 的 `SLOT-ORDER-OK` 会在**offset 16 被当作别的槽**这类假设下仍然照印 15 槽 ⇒ 这正是 `t170` `F-1` 判它"结构上盲"的机制。⇒ **收窄句只保留能被现有读数支撑的部分** ✓（判 `pass` 的依据之一）。
**反腿②（对本席自己的 P9／P10 自用）**：在 §4 判"`t173` 未白做"**有支撑**之前，我先证明**我要求的那条读数真的在**：`t173` 车道三腿日志逐腿 `grep -ac 'FSFORMATSUBT'` 与 `phase=slot3 rc=` 现取（0/−100002 与 1/0 与 1/0）——不是拿 `t180` 的结论转述。

## §8 推翻的话

**`none`** —— 我没能推翻本件的三条落账：`F-1`（未解除＋收窄＋逐槽登记＋出处更正）**逐子句**与 `t167`/`t168` 原始读数及判据件一致；`F-2` 的四腿读数与两族计数器**逐值**相符；`F-3` 的点名与行号 842/848 **逐字**相符、`FsFormatSubtrackFinite` 命中 0。三条附带问题（`V-1`／`V-2`／`V-3`）**都不构成"超出读数"**，故不改判词。

## §9 具名 `NOINFO`

- **`N-1`** `t176` 的**指纹数据本身**（逐槽"已验/未验"）—— 其载体 `:55` 自陈「照抄 `t170` §2.3／§9，**未独立复算**」；本件在 §2.2 用**原始件**独立复算了 1／3 槽与"其余 15 槽仅非空＋零位一致"，但**未**逐槽重跑 17 只槽的调用（**不可能**：驱动格只调过 2 只）⇒ 「其余 15 槽"未验"」是**否定命题的读数层结论**，不是"已验为空"。
- **`N-2`** `t176` 引的 `t173` 载体代际 `657aa706a681a56f`：**已过期**（`20:01:55` 被后到写者改为 `18ed4d7def636003`／143 行）⇒ 本件对该代际的引用只能标「**读时有效**」。
- **`N-3`** `push` 面：本席未取远端状态（无写权限动作）⇒ `t176` "未 push"**不可判**（`git add`／`commit` 两面已判：0 暂存、`HEAD` 早于落盘）。
- **`N-4`** `t176` 自报的 `mode=644`／`links=1`／pre `size=11671`：本席只复算了 `size=11671`（备份件 `ls -l`）与**现盘** mode（`stat -c %a` ⇒ 644），**pre 的 `mode`/`links` 未取**。
- **`N-5`** 本件**未跑腿、未构建、未占显示位、未跑整趟门禁**；`/tmp/.X11-unix` 现取 `X0 X1`（沿用 `t176` 读数，本席未重取——见 §11 声明）。

## §10 新发现的问题（点名 `文件:行` ＋ 机制；**本件不修**）

- **`V-1`（medium）｜更正段的收尾句过宽，且与同段自述相矛盾**：落点件 `:148` 现取整行 —— `⇒ `PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 的**类型对、点名错**；**下游不得去实现 `FsFormatSubtrackFinite`**（`t168` 代际 native 侧 `FsQuerySubtrackDetails` 现取**无实现**）。` —— 机制/反证：① **同一段的下一行**（`:149`）自己写「`t173` 未白做…**补 `M1` 后同一槽 3 调用 `-100002 → 0`**」，而 `M1` **就是** `FsFormatSubtrackFinite` 的占位（`P1-fsformatsubtrack-report.md` 标题与 §1；源 `win32_pts.c` M1 块 `:1487-1529`）⇒ "不得去实现它"与"补它之后症状消失"**同段并存**；② 与上式原文 `:70`「native 的造型入口 `FsFormatSubtrackFinite`（本波**未实现**）」也不一致；③ 现取两条**不同**症状各有一只入口：`-100002`（驱动格槽 3）→ `FsFormatSubtrackFinite`（t173 已证）；`[HC-UNHANDLED]` 具名 ENFE → `FsQuerySubtrackDetails`（本席现取：`exports.txt` 669 行命中 **0**；托管调用点 `ListParaClient.cs:46`／`ContainerParaClient.cs:47/89/142/177`）。**为什么是缺陷**：这是一句**面向排期的绝对禁令**，会把下一件从 `t173` 已证有效的方向上推开（与"点名错"同类但**反向过头**）。**修法（下一波，dated、只增不改）**：把该句收窄为「**两条症状各对应一只入口**：`-100002` → `FsFormatSubtrackFinite`（`t173` 已由 `M1` 证实）；日志具名 ENFE → `FsQuerySubtrackDetails`（**仍缺**）」。
- **`V-2`（low）｜逐槽登记表一行数字标注错**：落点件 `:129` 现取整行 = `  | 4–17 | **未验（15 槽）** | 仅「非空 ＋ 零位一致」 |` —— 区间 `4–17` 是 **14** 槽（15 ＝ `2` ＋ `4–17`）；同段尾行「15 个未验槽」**是对的** ⇒ 仅该行括注错。**影响**：覆盖仍 17/17、结论不变；对"按槽登记"的审计是可读性瑕疵。**修法**：该行改「4–17（**14** 槽）」或把 `2` 并入同排。
- **`V-3`（low）｜槽 3 的强度是 `t170` 代际口径的照抄，未纳入 `t173` 代际的升级（保守过头，非放松）**：落点件 `:128` 现取括注「…⇒ **副本调用只到「可捕获异常」强度**」。现取更强者：`t173` 的 X/X2 腿 `src=methods_snap` 的槽 3 调用已 `rc=0`，且驱动侧出参按契约被写出（`o_fsfmtr=1 o_dvrUsed=0 o_dvrTopSpace=0 o_breakpos=0`），而 `FsFormatSubtrackFinite` 的唯一托管调用点＝`ContainerParagraph.cs:526`（`FormatParaFinite` 路径）⇒ **副本路径上的名级/行为级绑定今天也成立**。**影响**：偏保守、**不放松**（排期可能低估槽 3 的证据强度）。**修法**：dated 补一句「槽 3 的**副本侧**证据在 `t173` 代际已升级（`rc=0`＋出参按契约写出）；**仍未验** ⇒ 不改变 §2 的收窄结论」。

## §11 证据在册 ＋ 资源 ＋ 自证

- 本件唯一写入：`build/MilBridge/P1-w95-verify.md`（`temp → os.replace`；临时件落 `/tmp/p1-w95-verify.tmp`）。
- 只读来源（现取）：`build/MilBridge/{P1-w95-report.md,P1-fsimethods-drive-report.md,P1-fsimethods-abi-recon.md,P1-TASK-TEMPLATE.md}`（**§A 整节已读**，`:5-21`）、`git show HEAD:<落点件>`、`git show 1e29ffd:src/…/win32_pts.c`（钉版 `6d6f753105224f78`）、`upstream/…/PtsCache.cs`／`PtsHost.cs`／`ContainerParaClient.cs`／`ListParaClient.cs`、`/home/links-dev/t123-runner/logs/{t168,t173}/**`（原始腿日志）、`~/w281-scribe/t176/bak/…pre-t176`、`/tmp/bridge-frozen.flag`／`~/wfp-runs/bridge-frozen.flag`（`stat` 只读）。
- **资源（§A #10）**：`MemAvailable` 三次现取 ＝ **15498032 kB**（20:02:5x）／**14753308 kB**／**14706152 kB**（20:03:0x）；`MemTotal=28831496 kB`；`SwapFree=2097148 kB`；`df -h /home` ⇒ `/dev/sda2 187G 104G 75G 59% /`。本件为**纯只读复核**，未起任何重活／腿／显示位（`/tmp/.X11-unix` 未重取 ⇒ 见 `N-5`）。
- **`P9`／`P10` 用在自己身上**：判"`F-2` 两族计数器分开"前，本席**先**从钉版源码取到两个来源行（`:584` 与 `:1747-1750`）；判"`t173` 未白做有支撑"前，**先**从 `t173` 车道三腿现取 `[FSFORMATSUBT]` 行数与 `slot3 rc`；判"未碰哨兵"前，**先**取两枚哨兵的 `mtime` 与 `cmp`（而不是只看 `git status` 里没有它们）。

**本件自证（落盘后）**：`head -n -1 build/MilBridge/P1-w95-verify.md | sha256sum | cut -c1-16` ＝ 5e65bf2bdf0520af（末行不计入自身；末行＝本行）
