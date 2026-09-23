# W129A 报告 —— `#52` 冻结后的**登记批（第一批）**：新登记 `D-G108`／`D-G109` ＋ 新 `TASK-0209` ＋ `TASK-0203` 归因落地 ＋ 一笔推送

> **一句话**：把今天上午查明的**三组事**落册 —— ① **发布完整性事件**（`git add -A` 把别的车道的在办件夹带进发布 ⇒ 远端一度与 `#52` 冻结声明不符）＝新号 **`D-G108`**；② **静默 SEGV 族**（与 `134` 族的 21 帧键盘焦点回声递归**异源**：`.NET Finalizer` 线程里 `wpf_queue_push` 的链遍历踩到写坏节点）＝新号 **`D-G109`** ＋ 新任务 **`TASK-0209`**；③ `TASK-0203` 那行的**归因落地**（状态位**仍 🟡**，产品侧未修）。**纯文本编辑 ＋ 一次推送**：零 `dotnet`／零构建／零门禁／零应用／**不占槽**。

**写域（只这四件 ＋ 克隆里的推送）**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`docs/ROUTES.md`／`build/MilBridge/tools/defect-registry-declared.tsv`（`--emit` 重生成）／`build/MilBridge/W129A-report.md`（本文件）。
**未碰**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（冻结基线）｜`docs/CURRENT-STATE.md:9`｜`verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／任何牙／任何产品件（`src/**` —— ⚠️ `$R` 的三件 native 源此刻是**车道 W131A 的在办值**，属 `#53`，**本件一个字节都没动，也不把它们当 `#52` 的声明值**）｜`~/w128a/**`／`~/w124a/**`／`~/w131a/**`／`~/w127a/**`（**除只读**）。
**纪律正项**：**零 `pkill`／零 `killall`／零 `pgrep -f`**（收进程只按 PID、探活读 `/proc/*/cmdline`）；**未跑**任何构建／门禁／波链；判据先写（`~/w129a/criteria.md`）。

---

## 0 开工读数（**现场现算，不手抄**）

| 项 | 值 |
|---|---|
| 仓根 `R` | `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**不是** git 仓库 ⇒ 无推送动作） |
| fork 克隆 | `~/netTest/GitProj/WPFOnLinux`（`feat-Linux`） |
| 冻结基线 | **`#52` = `27293fb5ab91b778`**（`ACCEPTANCE-BASELINE.md`，开工 = 收工**逐位同一**） |
| `docs/CURRENT-STATE.md:9` | `> BASELINE-FROZEN gen=#52 sha16=27293fb5ab91b778 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（开工 = 收工**逐字同一**） |
| `DEFREG`（开工） | `DEFREG=PASS declared=143 route_ids=143`／`DEFREG_DECLDRIFT=0`／`rc=0`（连跑两遍） |
| 远端 head（开工） | `8acfbb87a98ef61958a915fb01f700c71d8663d2`（`HEAD == origin/feat-Linux == ls-remote origin HEAD` 三者一致；`--symref` = `feat-Linux`） |
| 克隆工作树 | `git status --porcelain` **空**（干净） |
| 改前件 sha16 | `KNOWN-DEFECTS.md` **`2f63679f3dcf20c7`**（2790 行）｜`docs/ROUTES.md` **`5d615a54f1d46807`**（648 行）｜`defect-registry-declared.tsv` **`b784a0a7ff2fd784`**（152 行） |

**末号现场核（防幻影声明行）**：册内 `D-G*` 最大号 = **`D-G107`**（`grep -oE 'D-G[0-9]+' | sort -u | tail` ⇒ `…D-G105 D-G106 D-G107`）；`D-G108`／`D-G109` **全仓 0 命中**（五处 route 件 grep 皆空）⇒ **连续取 `D-G108`／`D-G109`** ✓。`TASK-0209` 全仓 0 命中（`TASK-0201`…`0208` 已用）⇒ 新任务号 = `TASK-0209` ✓。

---

## ① 新号与新判词（**逐字**；下面两段是从册里**现抽**的原字节，非重抄 —— 防两处不一致）

**走了"新号"而不是"并入既有条"**，理由：
- `D-G108`（发布完整性）—— 册内**没有任何编号**覆盖"发布动作本身把别人的在办件带上路"这个方向：`D-G101` 是"**写**穿别人的件"（机制 = **inode 共享**），本条的机制是**索引 `-A`**、坏在**发布态**；`D-G80`／`D-G103`／`D-G104` 的射程分别是"判据看不见写者"／"处置毁证据"／"读数器语义"，**都不是发布完整性** ⇒ **独立立号 ＋ 交叉引用**。
- `D-G109`（静默 SEGV）—— 册内 `D-G98` 明文只指 **`134` 族**的几何/尺寸约束那条线（且已写明"不含静默 SEGV"）；`D-G106`／`D-G107` 是**仪器侧**（判据字段选错／正则读不出），本条是**产品侧**（真缺陷 ＋ 判定点）⇒ **独立立号**；`D-G106`／`D-G107` **只交叉引用、不重复登记**。

### `D-G108`（册内 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2792-2803`）

### `D-G108`（**发布完整性缺陷 · `git add -A` 把别的车道的在办件夹带进发布**）：**发布树与发布者自己的冻结声明不符**，而推者以为"它只推了自己的收尾件"
- **形态（判词要件①，逐字现场）**：`#52` 冻结块（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `RE-FROZEN #52` 块，`:44-48`／`:85-86`）**逐字宣称** `src/WpfGfx.Linux.Native/src/win32_core.c` **`3117923a7c899e05`** ＋ `src/WpfGfx.Linux.Native/src/win32_x11.c` **`11142fbef049eb66`** ⇒ `win32shim` `8392fc09564779a1` → **`bd037229be8db4f6`**；而远端提交 `37def7e480ea33fbd965195588410a7ee68b6434`（提交信息逐字 `chore(#52): 收尾链 W126A 步骤①-⑩ —— 冻结 #52 27293fb5ab91b778`，`W126A`，`Wed Sep 23 11:49:37 2026 +0800`）之后，**远端实际是** `a9cc8762908b417a`／`9fa20864404ab01b`／`4e1880e6054635ff`（三件 = 车道 **W131A** 的**在办**值，属波 `#53`）⇒ **发布树与它自己的冻结声明不符**。（本件现场机械复核：`git cat-file -p 37def7e:<path> | sha256sum | cut -c1-16` 三件逐位如上；**冻结声明值一律从 `ACCEPTANCE-BASELINE.md` 冻结块现取，不手打**。）
- **机制（判词要件②）= `git add -A` 把当时克隆里所有脏件扫进同一笔**：`git show --stat 37def7e` 逐字 **16 件**，其中 `src/` 下**只有那三件 native 源**（`git show --stat 37def7e -- src/` = `3 files changed, 183 insertions(+), 5 deletions(-)`）；**时间线 14 秒** = W131A 改源件 `mtime 11:49:23` → 提交 `11:49:37` ⇒ **把别人正在改的树冻进了"冻结 `#52`"这一笔**。同形态第二处 = W126A 的第 2 笔 `4d125f8`（其 5 件清单**恰好等于**当时克隆里除它自己报告外的全部脏件，其中 4 件就是 W127A 那批登记件）。
- **危险方向（判词要件③，本条要害）**：**静默污染发布** —— **推者以为只推了自己的收尾件；别人以为远端 == 某个冻结态**；两条都错，而**任何一方的输出都不报警**（没有报错、没有空值、`git status` 还可能是干净的）。这是"**发布完整性**"方向的缺陷，**不是**"我少推了一件"。
- **本次代价（量化）**：远端一度与 `#52` 声明不符（三件值全错、`win32shim` 位也对不上）⇒ 必须**追加一笔还原**才复原；且**产品 `.so` 不在 git 里** ⇒ 若它被同样方式覆盖，**git 侧无法复原**（见"边界"）。
- **处置（已落地）**：还原笔 `1890b007985709b079112e167f455bbe91f8da58`（`revert(#52): 还原被 git add -A 夹带进 37def7e 的 W131A 在办 native 源至 #52 冻结态…`；**逐径 `git add` 三件、无 `-A`**）⇒ 远端三件 blob 回到 `3117923a7c899e05`／`11142fbef049eb66`／`e4f2de8d038e4780`（**本件现场 `git cat-file -p HEAD:<path>` 逐件复核 = 与冻结声明相符**；且 `~/w131a/` 内**零 `git`／`git push` 痕迹** ＋ 其 `LANDING-CHECKLIST.md` §0 闸门**未勾选** ⇒ **不是 W131A 推的**；W127A 那一笔**只 add 了 4 件** ⇒ **也不是它夹带的**）。
- **⚠️ 第二条教训 · "还原姿势"（同一事件的第二个独立面，必须与上面同读）**：当时主控给的 **`git checkout 37def7e^ -- <三件>` 是错的** —— 本件现场机械证：`37def7e^` 三件 = **`e0cbc965772d06c1`／`6477af56fdcfdf20`／`e4f2de8d038e4780`**，即 **`#51` 的态**，**既不等于冻结声明值，还会把 `#52` 刚落的产品侧改动（`D-G100`）一起回退掉**。车道（W127A）按任务书"**若不符则停手**"条款**没有执行**该指令，改用**正确源头** = `~/w131a/backup/{win32_core.c,win32_x11.c,win32_internal.h}.orig`（本件现场现算 = `3117923a7c899e05`／`11142fbef049eb66`／`e4f2de8d038e4780`，**与冻结块声明逐位相同** ⇒ 三件全 `MATCH`）。
  - **口径句（逐字，写给所有"还原/改写冻结态"的指令）**：「**凡"还原/改写冻结态"的指令，必须先拿冻结块（`ACCEPTANCE-BASELINE.md` 的 `RE-FROZEN` 块）逐件对值再执行；不许凭"回到父提交"想当然。**」
- **口径句（逐字，写死）**：「**在克隆里一律逐径 `git add <file>`；`git add -A` 会把别的车道的在办件夹带进发布。**」
- **交叉引用**：`D-G101`（**同族**："我以为只动了我的" ⇒ 写穿别人的件；但机制不同 —— 那条走 **inode 共享**、本条走 **索引 `-A`**）｜`D-G80`（**射程缺口**：判据看不见某个写者）｜`D-G103`（**处置/毁证据**族：本条毁掉的是"发布的**可复原性**"）｜`D-G104`（**同一件两个值必须两行都给** —— 本条的"声明值 vs 远端值"正是这种对）。
- **边界 / `NOINFO`**：① **`libwpfwin32.so` 不在 git**（本件现场 `git ls-files | grep -c 'libwpfwin32.so'` = **`0`**）⇒ **冻文件的件本体无法从 git 历史复原**；⚠️ 但**现场有一条独立证据**：`~/w131a/backup/libwpfwin32.so.orig` = **`bd037229be8db4f6`／`327,256 B`（本件现场现算）＝ 与冻结块声明逐位相同** ⇒ **该值可复核**。**"`bd037229be8db4f6` 是否曾真实存在于 `$R` 现场"** 那一格仍 **`NOINFO`**（不在 git、当时无第三方快照）。② `win32_internal.h` **在 `#52` 冻结块里没有独立声明**（块只声明 core/x11）⇒ 它的冻结值只能由 `#52` 锚九位清单与 W131A 备份间接给出（`e4f2de8d038e4780`）⇒ **该格属"已知边界"，不是本件新缺**。③ **"全仓还有几处 `git add -A`／`git commit -a` 形态"未逐处枚举** ⇒ `NOINFO`（本件只核了 `37def7e`／`4d125f8` 两处）。④ 本条**只登记、未改任何产品件**；**不改**任何既有编号的值与判词、**未**把任何红写成绿。

### `D-G109`（册内 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2804-2824`）

### `D-G109`（**产品缺陷 · 静默 SEGV 族 = `TASK-0203` 里的那只"静默 `139`"，与 `134` 族**异源**）**：`.NET Finalizer` 线程里 `HwndWrapper::Finalize()` → P/Invoke → `PostMessageW` → **`wpf_queue_push` 的队列链遍历踩到已被写坏的节点** ⇒ **进程静默死（应用自己 0 字节输出）**
- **形态（判词要件①）**：点击序列（9 击腿 `nav1,nav9,ctrl_tb,type,nav10,ctrl_cb[,popitem],nav2,tab3,nav3`）打到第 **7** 击 `nav2` 时，**修前件** `libwpfwin32.so`（`abf6879c027c5e73`）里的消息队列被写到非法状态，`.NET Finalizer` 线程走 `HwndWrapper::Finalize()` → P/Invoke → `PostMessageW` → `wpf_queue_push` 的**自愈分支**，链遍历踩坏指针 ⇒ `SIGSEGV` ⇒ **进程直接静默死**（`timeout` 侧读成 `rc=139`，而**应用自己一个字都没打**）。
- **异源判定（四条独立读数，对着 `134` 族逐条比）**：

  | # | 读数 | 静默 SEGV 族（`W071`／`W077`） | `134` 族（本批 98 趟 ＋ W118A 61 趟） |
  |---|---|---|---|
  | 1 | **线程** | **`.NET Finalizer`（`tid=6`）** | 恒为主线程 `dotnet`（`tid=1`） |
  | 2 | **栈深** | **`depth = 7,088 B`**（浅） | `8,388,656…8,388,672 B`（**满 8 MB 栈底**） |
  | 3 | **环** | **无环**（`R1_CYCLE=False` ∧ `R2_SAMESET=False`；缺 ③托管输入族 与 ④`HwndWrapper::WndProc`／`SubclassWndProc`） | `R1=True ∧ R2=True`（12/12 全符号化趟），轮数 **2,937–2,987**、字节周期 2,808–2,856 |
  | 4 | **终止形态** | **应用输出 0 字节**（`Stack overflow.` 一个字都没来；`app.log`＝`app.err`＝`app.both`＝**0 B**） | 先打 **62,094** 帧托管栈（或 18–19 KB 折叠形）再 `FailStack` ⇒ `rc=134` |

- **判定点（反汇编级，逐字）**：`PC-1`／`PC-2` = **`0x7fff740dcdf3`**，符号化 = **`wpf_queue_push + 259`**（`libwpfwin32.so`，函数入口 `0x11cf0` ⇒ `+0x103` = `0x11df3`）；`objdump -d --disassemble=wpf_queue_push` 该处逐字 **`11df3: mov 0x38(%rax),%rax`**（= `p = p->next` 链遍历），回溯 `#1 PostMessageW`（`+0xc7`）；浅栈扫描另证调用链 = `HwndWrapper::Finalize()` → `System.GC::RunFinalizers()` → `IL_STUB_PInvoke(…WindowMessage…)` → `PostMessageW+0xc7` → `wpf_queue_push+0x103`。⇒ **判定点 = `src/WpfGfx.Linux.Native/src/win32_msg.c:57-82`** 的**非法队列状态自愈分支**（`head != NULL ∧ tail == NULL`）里约 **`:79`** 的 `while (p->next) p = p->next;`。
- **两个样本同址 ⇒ 确定性缺陷（非偶发）**：`W071`（`pad` **`1129`**）与 `W077`（`pad` **`1226`**）在**两个不同相位**上给出**逐位相同**的故障停止点 —— `PC-1 = PC-2 = 0x7fff740dcdf3`、同 `tid=6`、同 `depth=7088`、**同 `rsp=0x7fff7600a450`**、同栈映射 `stackmap=`（空 = 非 `[stack]`）、同 **死在第 7 击 `nav2` 之后**（`CLICKS_TRIED=9 CLICKS_LANDED=7 ENTRY_DETAIL=nav1,nav9,ctrl_tb,nav10,ctrl_cb,popitem,nav2`）、同 **0 字节输出**、同 `FAULTCOUNT=3 GDBSTOP_SIGS=11,11,11`。（本件现场现算：`runs.tsv` 两行 ＋ 两份 `frozen/<tag>/gdb.txt` 的 `W118A-STOP-*`／`PC-*` 行。）
- **实时计数（中途读数，本件现场从机读台账复算）**：**2 命中 / 100 有效主臂趟 = 2.0%**（口径 = `~/w128a/runs.tsv` 106 行 = 表头 ＋ 105 趟；其中 `arm=gdb` **100** 趟为主臂，`family=134-stackovf` **98**、`family=other` **2**（就是 `W071`／`W077`）、`nogdb` **5** 趟为阳性对照全部 `124/alive/落地 8`；`siaddr0` 两趟均 `0x0`、`ext_kill_suspect` 两趟均 `yes`（⇒ 旧口径把这两趟**误剔**，见下"口径修正"））。⚠️ **该批仍在跑** ⇒ **最终计数与 95% 单侧上界本件 `NOINFO`**，以 W128A 交数终值为准。
- **⚠️ 口径修正（三条件合取，逐字，必须同时写进本号与 `TASK-0203`）**：**`SILENT_SEGV_HIT ⇔ 应用输出 == 0 B（剔掉 `timeout:` 那行）∧ `STACKOVF == 0` ∧ 死于 SIGSEGV（`RC==139` ∨ `APP_FATE` 含 SIGSEGV ∨ `gdb.txt` 含 `Program terminated with signal SIGSEGV` ∨ **`gdb.txt` 里存在 `W118A-STOP-N`（`N≥1`）且 `signo=11`**）** —— **最后一支直接从 `gdb.txt` 的停止点行读，抗收尾截断**。**旧口径**（字面 `APP_RC==139`）在 `ARM=gdb` 下**天生打不着**（那时 `APP_RC` 是 gdb 自己的 rc）；**重扫结果**：`~/w128a` 旧口径 **0 命中** → 新口径 **2**（`W071`／`W077`），即**旧口径漏判 2 ＋ 误剔 2**（两趟都被错标 `EXTERNAL_KILL_SUSPECT=yes`）；`~/w118a` 71 趟与 `~/w98a` 128 趟**零影响、结论不变**。
- **⚠️ 同一件两个值（`D-G104` 第三条，两个都给）**：`W128A-report.md` **§④ 正文**写"`W071`（垫 **`PAD=903`**，第 71 趟主臂）"，而**机读台账** `~/w128a/runs.tsv` 现算 = **`pad=1129`**（**`903` 实为 `W057` 的 `pad`** —— 本件现场核：`pad` 与 `tag` 的对应是 `round(i×2823/175)`，`903→i=56`、`1129→i=70`、`1226→i=76`，而 `W071`↔`i=70`、`W077`↔`i=76` **自洽**）⇒ **以台账为准 = `1129`／`1226`**；两个值都留档（不覆盖正文），**该项与判词无关**（判定点靠 `PC-1`／`PC-2` 与 `runs.tsv` 其余字段，不靠 `pad`）。
- **⚠️ 不许把 `siaddr=0x0` 当依据**：该字段与指令语义不符（`mov 0x38(%rax),%rax` 的故障地址应是 `p+0x38`，且入口与循环都已排除 `p==NULL`）⇒ **本号判词不依赖 `siaddr`**（W128A 同样判"不采信"并如实 `NOINFO`）。
- **⚠️ `D-G98` 的适用范围（防后人并成一条；上一批 W127A 已写、此处只复述不重复登记）**：**`D-G98` 只指 `134` 族的几何/尺寸约束那条线，不含本条静默 SEGV** —— 两者**异源**（线程／栈深／有无环／应用输出四条全不同）。
- **处置（产品侧未修 ⇒ 本号仍红）**：已开 **`TASK-0209`**（修 `win32_msg.c:57-82` 的队列链遍历 ＋ 给写坏来源取证；判据须先写）。⚠️ **本号不是"已修"**，`TASK-0203` 的状态位**仍 🟡**。
- **交叉引用**：`D-G106`（**本批仪器侧**：假可疑把真命中踢出分母 —— 本条这两趟**正是受害者**）｜`D-G107`（**本批仪器侧**：`thread=(\S+)` 读不出 `.NET Finalizer` ⇒ 本条这两趟一度被判 `NOINFO`）｜`D-G98`（**异源的那条线**）｜`D-G96`（证据要活过重跑：`W071`／`W077` 已 `cp -a` 冻结到 `~/w128a/frozen/`）。
- **边界 / `NOINFO`**：① **"'上游写坏者'是谁未取证"** ⇒ `NOINFO`（`wpf_queue_push` 是**崩溃点**，**不是已定的根因点**；两件 `.so` 之间差 **25 个导出** ⇒ **不许归因到单一函数**）；② **自然发生率**（不带 gdb）与**有 WM 腿**均**未跑** ⇒ `NOINFO`；③ 装置为 `Xvfb 1024x768` **无 WM**，与用户现场（`:10` xrdp ＋ xfwm4）**不同构** ⇒ 结论只对本装置成立；④ **`W98A` 的 `L1B024` 与本族是否同一事件** ⇒ `NOINFO`（那趟的故障栈当年没抓到；只作"同族的第二个样本"人格对照）；⑤ **W128A 报告的最终表与自身 sha16 未落**（§⑮ `<<<TABLES>>>`／§⑯ `<<<SELFSHA>>>` **仍是占位符**；本件现算 sha16 = **`34cbdff1b5d1bebd`**、FULL `34cbdff1b5d1bebdc344ae24d1198ccfeb02e161baf25547b21f31fc4b0eba68` ⇒ 该报告**仍在写**，最终值以它自报为准）；⑥ 本条**只登记、未改任何产品件**；**不改**任何既有编号的值与判词、**未**把任何红写成绿。

---

## ② 新 `TASK-0209` 逐字（落 `docs/ROUTES.md` §15o）

> 🆕 **新任务 `TASK-0209` [Next] 🔴**（号现场核：`TASK-0201`…`0208` 已用、`TASK-0209` 全仓 0 命中）：**修 `src/WpfGfx.Linux.Native/src/win32_msg.c:57-82` 的队列链遍历 ＋ 给"写坏 `head` 链的上游写者"取证** —— ① 判据**先写**（含"**终结器路径 `HwndWrapper::Finalize()` → P/Invoke → `PostMessageW` → `wpf_queue_push`**"这条链的取证：每趟必须给出 `PC`／`tid`／`depth` 三格，拿不到 ⇒ `NOINFO`）；② **两极化**要求：修后件臂上该签名 **0/N**，且**同一装置上仍能复现 `134` 族**（证明不是把装置弄哑）；③ **不许**只在 `wpf_queue_push` 里加空指针守卫就收工（那是**崩溃点**、不是**根因点**）—— 必须点名**写坏者**或如实 `NOINFO`；④ 沿用 `D-G109` 的**新口径**（`APP_RC==139` 在 `ARM=gdb` 下不可达，见 `D-G106`）。**交叉引用** `D-G109`／`D-G106`／`D-G107`／`D-G96`（证据冻结）。

---

## ③ `TASK-0203` 追加段逐字（**状态位保持 🟡**；落 `docs/ROUTES.md` §15o，**上面各节登记一字未动**）

> 🔁 **`TASK-0203` 追加（车道 W128A 交数 ＋ 本件现场复算，2026-09-23；上面各节登记**一字未动**）**：归因已落到"**异源 ＋ 具名判定点 ＋ 两个同址样本 ＋ 实时 `2.0%`**" —— 异源四条读数与判定点逐字见上 `D-G109`；样本 = `W071`／`W077`（`PC-1=PC-2=0x7fff740dcdf3`、`tid=6`、`depth=7088` 逐位相同）；计数 = **2/100 = `2.0%`（中途）**。⚠️ **状态位仍 🟡**（**产品侧未修**，处置已开 `TASK-0209`）；⚠️ **`D-G98` 的适用范围照旧：只指 `134` 族的几何/尺寸约束那条线，不含静默 SEGV**（上批已写，此处**不重复登记**，只保证与 `D-G109` 并列可读）；⚠️ **最终计数／上界仍 `NOINFO`**（W128A 批次在跑，其报告 §⑮／§⑯ 仍是 `<<<TABLES>>>`／`<<<SELFSHA>>>` 占位符，本件现算 sha16 **`34cbdff1b5d1bebd`** ⇒ 该报告**仍在写**）。

**本件对 `W128A` 读数的独立复核（机械、只读 `~/w128a/**`）**：
- `~/w128a/runs.tsv` 现读 **106 行**（表头 ＋ 105 趟）；`arm` 分布 = `gdb` **100**／`nogdb` **5**；`family` 分布 = `134-stackovf` **98**／`alive` **5**／`other` **2**；`stackovf` = `1` **98**／`0` **7**；`ext_kill_suspect` = `no` **103**／`yes` **2**（= 两趟命中）。
- `family=other` 的两行**就是** `W071`／`W077`：两行 `pcsym0` 皆 **`wpf_queue_push`**、`shim_check` 皆 **`abf6879c027c5e73`**（修前件）、`siaddr0` 皆 **`0x0`**、`entry_detail` 皆 `nav1,nav9,ctrl_tb,nav10,ctrl_cb,popitem,nav2`、`clicks_landed=7`、`dead_at_s` `28`／`29`、`faults=3`、`gdbstop_sigs=11,11,11,`。
- `~/w128a/frozen/{W071,W077}/gdb.txt` 的 `W118A-STOP-*` 行**逐字**（本件现场读）：`W118A-STOP-1 signo=11 siaddr=0x0 depth=7088 stackmap= deep=yes thread=.NET Finalizer tid=6 exh=no rsp=0x7fff7600a450`（两趟**逐字相同**，含 `rsp`）；`PC-1`／`PC-2` = **`0x7fff740dcdf3`**（两趟**逐位相同**）；`PCSYM-1=wpf_queue_push + 259 in section .text of …/app-P/libwpfwin32.so`。
- 应用输出：`frozen/W071/{app.log,app.err,app.both}` **皆 0 字节**；`frozen/W077/{app.log,app.err,app.both}` **皆 0 字节** ⇒ **"静默"成立**。
- 阳性对照：5 趟 `nogdb` 全 **`124`／`alive`／落地 8** ⇒ **无一批作废**。
- ⇒ **`2/100 = 2.0%` 是本件现场从机读台账复算的，不是转述**。

---

## ④ 口径句与"还原姿势"教训逐字

1. **`D-G108` 主口径句**：「**在克隆里一律逐径 `git add <file>`；`git add -A` 会把别的车道的在办件夹带进发布。**」
2. **`D-G108` 还原姿势口径句**：「**凡"还原/改写冻结态"的指令，必须先拿冻结块（`ACCEPTANCE-BASELINE.md` 的 `RE-FROZEN` 块）逐件对值再执行；不许凭"回到父提交"想当然。**」
3. **`D-G109` 命中口径（三条件合取）**：**`SILENT_SEGV_HIT ⇔ 应用输出 == 0 B（剔掉 `timeout:` 那行）∧ `STACKOVF == 0` ∧ 死于 SIGSEGV（`RC==139` ∨ `APP_FATE` 含 SIGSEGV ∨ `gdb.txt` 含 `Program terminated with signal SIGSEGV` ∨ `gdb.txt` 里存在 `W118A-STOP-N`（`N≥1`）且 `signo=11`）**。
4. **`D-G109` 不采信项**：**不许把 `siaddr=0x0` 当依据**（与指令语义不符；判词不依赖它）。
5. **`D-G98` 适用范围（照旧）**：**只指 `134` 族的几何/尺寸约束那条线，不含静默 SEGV**。

**还原姿势的机械证（本件现场现算，`git cat-file -p <rev>:<path> | sha256sum | cut -c1-16`）**：

| rev | `win32_core.c` | `win32_x11.c` | `win32_internal.h` |
|---|---|---|---|
| **`37def7e^`（= 主控原指令的源头）** | `e0cbc965772d06c1` | `6477af56fdcfdf20` | `e4f2de8d038e4780` |
| `37def7e`（冻结笔，实际带上远端的） | `a9cc8762908b417a` | `9fa20864404ab01b` | `4e1880e6054635ff` |
| **`HEAD`（还原笔 `1890b00` 之后 = 当前远端）** | **`3117923a7c899e05`** | **`11142fbef049eb66`** | **`e4f2de8d038e4780`** |
| **冻结块声明（从 AB 现取）** | **`3117923a7c899e05`** | **`11142fbef049eb66`** | （块**未单独声明**） |
| `~/w131a/backup/*.orig`（还原**正确源头**） | `3117923a7c899e05` | `11142fbef049eb66` | `e4f2de8d038e4780` |

⇒ **`37def7e^` ≠ 冻结声明值**（且会把 `#52` 的 `D-G100` 一起回退）**机械成立**；`1890b00` 之后**远端 == 冻结声明**逐件成立。
⇒ **`.so` 那一格**：`git ls-files | grep -c 'libwpfwin32.so'` = **`0`** ⇒ **不在 git**；但 `~/w131a/backup/libwpfwin32.so.orig` 现算 = **`bd037229be8db4f6`／`327,256 B`** = 与冻结块声明**逐位相同** ⇒ **该值可复核**；"它是否曾真实存在于 `$R` 现场" = **`NOINFO`**。

---

## ⑤ `DEFREG` 两条机读行（**现场跑两遍，`cmp` 逐字节 IDENTICAL，`rc=0`/`0`**）

```
DEFREG_DECL=n=145 route_ids=145 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=9e22f5f695af6365 CS=737c78e3a7e5a3a5 HO=e4dc264200b421d0 AB=27293fb5ab91b778
DEFREG_EXTRA=KRJ=d4e0080df6ec497c KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=145 route_ids=145（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
rc=0
```

- **两条要点行**：**`DEFREG=PASS declared=145 route_ids=145`** ｜ **`DEFREG_DECLDRIFT=0`**（改前 = `143` ⇒ **本批 ＋2**（`D-G108`／`D-G109`））。
- **幻影号自检（引用前先确认存在）**：`--emit` 输出与旧表 `diff`（**去注释行口径**） = **`23a24,25`**（**只 ＋2 行、0 删、0 改**；`git diff` 另有 **2 行头变化** = `# DECL-GEN` 时间戳 ＋ `# DECL-ANCHORS` 的 `KD=` 新值，属 `--emit` 的**机械头**）；两条新行逐字 = `ID<TAB>D-G108<TAB>req=KD<TAB>present=KD`／`ID<TAB>D-G109<TAB>req=KD<TAB>present=KD` ⇒ **无幻影**。
- **新号只声明在 `KD`**（`req=KD`）—— 本件**未碰** `CS`／`HO`／`AB`（三个 route 文件 sha16 与开工**逐位相同**：`CS=737c78e3a7e5a3a5`／`HO=e4dc264200b421d0`／`AB=27293fb5ab91b778`）。
- `--emit` **只把新表打到 stdout**（`defect-registry-check.sh:403`）⇒ 本件走 **temp ＋ `os.replace`** 落盘（**不用原地截断写**，避 `D-G101`；落盘前后 `mode` `644→644`、`links=1→1`、`size 6566→6622`）。
- **两遍差异**：`cmp /tmp/w129a-defreg1.txt /tmp/w129a-defreg2.txt` ⇒ **IDENTICAL**；期间**未**跑任何构建/门禁。

---

## ⑥ 推送前后 head ＋ `BYTECHECK`

- **推送前**：`8acfbb87a98ef61958a915fb01f700c71d8663d2`（= `origin/feat-Linux` = `ls-remote origin HEAD`；`git status --porcelain` **空**）。
- **推送**：逐径 `git add <file>`（**绝无 `-A`、无 `--force`** —— 本批登记的 `D-G108` 正是 `-A` 造成的）→ `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`（**refspec 显式**，避陷阱）→ `git push origin feat-Linux` → **重 `fetch` ＋ 与 `ls-remote origin HEAD` 交叉核** → `--symref` 仍 `feat-Linux`。
- **第 1 笔后 head** = **`a0a0205637e68c2b73dc05071126430b442cbfce`**（现场 `git rev-parse HEAD`）。
- **第 2 笔（RECORD-补，本报告自身）**：⚠️ **"最终 head"是本报告无法自指的格**（写进去就会再前进一笔）⇒ 本件按 **W126A 的结构性自洽表述**：**最终 head = 携带本报告的最后一笔**；**可机读的判据 = `HEAD == origin/feat-Linux == ls-remote origin HEAD` 三者相等 ∧ `--symref` 仍 `feat-Linux`**（逐字读数见文末 `===RECORD===`）。
- **`BYTECHECK`**（判据 = **远端 blob == 克隆工作树**；`$R` 与远端**不同**的件**单列并说明"本地领先"**）：逐字读数见文末 `===RECORD===`。

**件 sha16（改前 → 改后；`links` 全 `1`）**

| 件 | 改前 | 改后 | 行数 |
|---|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `2f63679f3dcf20c7` | **`9e22f5f695af6365`** | 2790 → **2824** |
| `docs/ROUTES.md` | `5d615a54f1d46807` | **`3712b63a52875344`** | 648 → **663** |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `b784a0a7ff2fd784` | **`423bff22079d04ea`** | 152 → **154** |
| `build/MilBridge/W129A-report.md` | —（新建） | 见文末 `===RECORD===` | 本文件 |

**改法是"追加 ＋ 行锚定"，事后 `wc -l` 复核**：`KNOWN-DEFECTS.md` **2790 → 2824**（＋34 = 两个新节），`docs/ROUTES.md` **648 → 663**（＋15 = 空行 ＋ `## §15o` 标题 ＋ 空行 ＋ 12 条 bullet）⇒ **无吞行**；`D-G107` 的"边界 / `NOINFO`"行改后仍**恰好 1 处**（`grep -c` = `1`）。既有 `D-` 节标题（行首 `### `）数 = **63**（未被删改）。

---

## ⑦ 件对账（"改了几件" ↔ "推了几件"）

- **本件编辑 = 3 件 ＋ 新建 1 件 = 4 件**（上表）。推送**逐径**；`git status --porcelain` 与"改了几件"**逐件对上，无夹带**。
- **`$R` ↔ 远端全量对账（机械）**：克隆 `git ls-files` **15262 件**，逐件与 `$R` 比 sha256 ⇒ **不同者恰好 6 件**：
  1. `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`$R` `9e22f5f695af6365` vs 克隆改前 `2f63679f3dcf20c7`）—— **本件，已推**；
  2. `docs/ROUTES.md`（`3712b63a52875344` vs `5d615a54f1d46807`）—— **本件，已推**；
  3. `build/MilBridge/tools/defect-registry-declared.tsv`（`423bff22079d04ea` vs `b784a0a7ff2fd784`）—— **本件，已推**；
  4. `src/WpfGfx.Linux.Native/src/win32_core.c`（`$R` `a9cc8762908b417a` vs 克隆 `3117923a7c899e05`）—— **别人的在办件（车道 W131A，属 `#53`）⇒ 本地领先，本件不代推、也不改动**；
  5. `src/WpfGfx.Linux.Native/src/win32_x11.c`（`9fa20864404ab01b` vs `11142fbef049eb66`）—— 同上；
  6. `src/WpfGfx.Linux.Native/src/win32_internal.h`（`4e1880e6054635ff` vs `e4f2de8d038e4780`）—— 同上。
  ⇒ **除本件 4 件外，唯一差异就是 W131A 的三件在办 native 源**（克隆侧恰 = `#52` 冻结声明值 ⇒ 正是 `D-G108` 的还原结果，自洽）。
- ⚠️ **本件故意未推的一件（防重犯 `D-G108`）**：`build/MilBridge/W128A-report.md`（**别人的在办件**，其 §⑮／§⑯ 仍是 `<<<TABLES>>>`／`<<<SELFSHA>>>` 占位符 ⇒ **仍在写**）⇒ **不随本笔夹带**。另：`git ls-files` 侧有 **7365 件**（`upstream/**` 等）**在 `$R` 不存在** ⇒ 那是"`$R` 未落地上游全树"，**不是**本件的差异，记 `NOINFO`（本件不普查上游）。

---

## ⑧ `fp_inputs` 影响（**机械证：零影响**）

- **本件现场真调用**（口径 = 从 `build/close-wave.sh` 抽 `fp_inputs()` 函数体到 `/tmp` 跑，**不跑波、不重建**）：两遍**逐字相同** =
  **`f0e2b3e8c058cdf017031360a2cc292ffd6ab7b91b4a8ae47c100c3877522bd7`**。
- ⚠️ 该值 **≠ `#52` 冻结期的值**，但 **= 车道 W127A 落批后记录的值**（`build/MilBridge/W127A-report.md` §⑧ 逐字）⇒ **跨批不变**。
- **三条机械证（合起来才叫"零影响"）**：
  1. **覆盖面成员里本件 4 件命中全 0**：`grep -c` 于 `/tmp/w129a-fp.sh` ⇒ `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` **0**／`docs/ROUTES.md` **0**／`build/MilBridge/tools/defect-registry-declared.tsv` **0**／`build/MilBridge/W129A-report.md` **0**。
  2. **覆盖面成员文件内容一键未变**：把覆盖面里的 `.sh`／`.py`／`.json` 逐个在 `$R` 与克隆 `HEAD` 间比 sha16 ⇒ **`DIFF` 0 行**（覆盖面里的 `defect-registry-check.sh` 本件**只读调用**、未改一字节）。
  3. ⇒ **指纹两遍相同 ∧ 成员零命中 ∧ 成员内容零变动** ⇒ **本笔对 `inputs_fp` 贡献 = 0**（位移**不归因**于本件）。

---

## ⑨ `NOINFO`／未做（**既不算绿也不算红**）

1. **`W128A` 的最终计数与 95% 单侧上界** = `NOINFO`（批仍在跑；报告 §⑮／§⑯ 仍是占位符 ⇒ 该报告**仍在写**，本件现算 sha16 = `34cbdff1b5d1bebd`、FULL `34cbdff1b5d1bebdc344ae24d1198ccfeb02e161baf25547b21f31fc4b0eba68` ⇒ **以它自报终值为准**）。
2. **`D-G109` 的"上游写坏者"** = `NOINFO`（`wpf_queue_push` 是**崩溃点**、不是已定根因点；两件 `.so` 差 **25 个导出** ⇒ **不许归因单一函数**）；**自然发生率（不带 gdb）与有 WM 腿未跑**；装置 `Xvfb 1024x768` 无 WM **与用户现场不同构**。
3. **`W98A` 的 `L1B024` 与 `D-G109` 是否同一事件** = `NOINFO`（那趟故障栈当年没抓到）。
4. **`D-G108` 的"全仓还有几处 `git add -A`／`commit -a`"** = `NOINFO`（只核了 `37def7e`／`4d125f8`）；**"`bd037229be8db4f6` 是否曾真实存在于 `$R` 现场"** = `NOINFO`（`.so` 不在 git、当时无第三方快照）。
5. **未跑任何牙自检**（`defect-registry-check.sh --selftest` **未跑** —— 避免被读成"跑门禁"；本件只跑它的**只读判据行**与 `--emit` 到 stdout）。
6. **`W128A-report.md` 未推**（别人在办）；**未代 W131A 推**它的三件 native 源（属 `#53`）。
7. **本件无锁、无握手**："没撞车"只是**时间序观察**（`$R` 三个 route 件的开工 = 收工读数自洽），**不是**互斥证明。

---

## ⑩ 大白话小结（6 行）

1. **今天上午三组事全落册了**：`D-G108`（发布被 `-A` 污染）、`D-G109`（静默 SEGV 与 `134` **不是一回事**），外加新任务 `TASK-0209` 去修那处队列链。
2. **`TASK-0203` 只补"归因落地"这一句，状态位仍是 🟡** —— 因为**产品一个字没修**（修的人是 `TASK-0209`）。
3. **最难自证的一格是"静默"**：两趟命中的 `app.log`／`app.err` **都是 0 字节**，而且**两个不同相位给出的故障地址逐位相同**（`0x7fff740dcdf3`）⇒ 这不是偶发，是**确定性缺陷**。
4. **登记表机器读过了**：`declared=145 route_ids=145`、漂移 `0`、连跑两遍**逐字节相同** —— 号没有多、没有少、没有幻影。
5. **`-A` 那件事我一边登记一边躲**：本笔**逐径 `git add`**，并且**故意不推** `W128A-report.md`（别人还在写），三件 native 源也一个字节没碰。
6. **本笔对输入指纹零影响**（三条机械证），冻结物 `AB` 与 `CS:9` **开工 = 收工逐位相同**。

---

## `===RECORD===`（推送读数；本段**只追加**，上面正文**一字未动**）

### 第 1 笔（3 件目标件）—— **已推**
- 推送前 head = `8acfbb87a98ef61958a915fb01f700c71d8663d2`（= `origin/feat-Linux` = `ls-remote origin HEAD`）。
- 推送后 head = **`a0a0205637e68c2b73dc05071126430b442cbfce`**；**push 后重 `fetch`** ⇒ `HEAD == origin/feat-Linux == ls-remote origin HEAD` **三者相等**；`ls-remote --symref origin HEAD` = `ref: refs/heads/feat-Linux` ✓。
- `git push` 逐字：`8acfbb8..a0a0205  feat-Linux -> feat-Linux`（`origin` = 用户 fork）。
- **`BYTECHECK`**（判据 = **远端 blob == 克隆工作树**）：**`ok=3 mismatch=0 nobody=0`** —— 逐件三方比（`git cat-file -p HEAD:<path>` vs 克隆工作树 vs `$R`）**全等**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` `9e22f5f695af6365`｜`docs/ROUTES.md` `3712b63a52875344`｜`build/MilBridge/tools/defect-registry-declared.tsv` `423bff22079d04ea`。
- **`$R` 与远端不同的件**（**本地领先，预期，本件不代推**）= `src/WpfGfx.Linux.Native/src/{win32_core.c,win32_x11.c,win32_internal.h}` 三件（车道 **W131A** 在办，属 `#53`；`$R` 值 `a9cc8762908b417a`／`9fa20864404ab01b`／`4e1880e6054635ff`，远端 = 冻结声明值）。
- 件对账：`git status --porcelain` 提交前 = **恰好 3 件 ` M`**、`git diff --cached --stat` = `3 files changed, 53 insertions(+), 2 deletions(-)` ⇒ **无夹带**。

### 第 2 笔（**本报告自身**）—— **已推**
- 推送后 head = **`966c3c983c90a177d63bdc56606e41613375dd56`**；`git push` 逐字 = `a0a0205..966c3c9  feat-Linux -> feat-Linux`；**重 `fetch` 后** `HEAD == origin/feat-Linux == ls-remote origin HEAD` **三者相等**、`--symref` 仍 `feat-Linux`。
- **`BYTECHECK`（实测，4 件）**：**`ok=4 mismatch=0 nobody=0`** —— 逐件三方比（`git cat-file -p HEAD:<path>` vs 克隆工作树 vs `$R`）**全等**：

  | 件 | 远端 blob = 克隆工作树 = `$R` |
  |---|---|
  | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `9e22f5f695af6365` |
  | `docs/ROUTES.md` | `3712b63a52875344` |
  | `build/MilBridge/tools/defect-registry-declared.tsv` | `423bff22079d04ea` |
  | `build/MilBridge/W129A-report.md`（第 2 笔那一版） | `2bc0acf0c363828b` |

- **`$R` 与远端不同（本地领先，预期，本件不代推）**：`win32_core.c` `3117923a7c899e05` → `$R` `a9cc8762908b417a`｜`win32_x11.c` `11142fbef049eb66` → `$R` `9fa20864404ab01b`｜`win32_internal.h` `e4f2de8d038e4780` → `$R` `4e1880e6054635ff`（三件 = 车道 **W131A** 在办，属 `#53`）。

### 第 3 笔（**RECORD-补** —— 本段，本报告自身）—— 已推
- ⚠️ **"最终 head"这一格对本报告是自指**：写进去就会再前进一笔 ⇒ 按 **W126A 的结构性自洽表述**：**最终 head = 携带本报告的最后一笔**；**可机读的等价判据 = `HEAD == origin/feat-Linux == ls-remote origin HEAD` 三者相等 ∧ `--symref` 仍 `feat-Linux`**（第 1、2 笔均已用这条判据实测通过）。
- `BYTECHECK`：本报告这一行的**新 blob** = 本文件现字节（由上表 `FULL sha256` 唯一确定）；**等价式** = `remote blob(report) == 克隆工作树 == $R` —— 本笔**就是用这三者相等的字节建的**（`cp -p` 后逐件 `cmp` 通过才 `git add`）；其余 **3 件实测 `ok=3 mismatch=0 nobody=0`**（值同上表）。

（末两行 = 本行 ＋ sha16 行；口径 `head -n -2 <本文件> | sha256sum | cut -c1-16`）
本报告 sha16 = `e12cdbafb61f2f0d`
