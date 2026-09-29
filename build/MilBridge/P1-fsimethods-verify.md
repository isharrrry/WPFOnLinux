# P1-W90 独立复核（`verifier`）—— `t168`（drive）＋ `t167`（snapshot）判词

> **复核对象（现取，读时 `2026-09-29T19:0x–19:2x+0800`）**
> - `build/MilBridge/P1-fsimethods-drive-report.md`（`t168`）：107 行／sha16 **`e1d50d10d7091b42`**（本席现取全量前 32 位 `e1d50d10d7091b421dfdcd8499b694f7` ✓）／末行自证 **`a6d7a4bc641f3e80`**（本席 `head -n -1 | sha256sum` 复算 **MATCH ✓**）
> - `build/MilBridge/P1-fsimethods-snapshot-report.md`（`t167`）：106 行／sha16 `287b88f1b283d6c2`／末行自证 **`fb9b49544bc353c3`**（复算 **MATCH ✓**）
> - 判据件 `build/MilBridge/P1-fsimethods-abi-recon.md` ＝ **`62283f54aae6f967`**／208 行（`D1/D2/D3` 三条判别的唯一出处）
>
> **代际钉死（本件一律引用提交内 blob，不引在飞工作树）**：`t168` 的 `win32_pts.c` ＝ `git show 1e29ffd:src/WpfGfx.Linux.Native/src/win32_pts.c` ⇒ **`6d6f753105224f78`／319005 B／4210 行**（＝`t168` 自陈收尾值，本席现取交叉 ✓）；本席已把它抽到车道 `~/wv88y/t170/win32_pts.t168.c`，**本件所有源码行号都指这一份**。
> ⚠️ **读时发现工作树已在动（不属本件写域，只报）**：`19:10:36` 起 `win32_pts.c` 由在飞写者（`t173`）改为 `1b642b1a906eb12f`／323433 B，`bin/libwpfwin32.so` 与 `bin/exports.txt` 随之重建 ⇒ 本席有两处早期读取落在该位移之前（当时工作树＝`t168` 代际），凡引用处均已改回钉版行号。
>
> **七项判词总览**：①算术对、但"吻合"的**性质**要分清（**部分**成立）｜②**`SLOT-ORDER-OK` 推理＝不充分**（缺口具名，§2）｜③**`calls` 分开报如述不成立**（实质分开成立、witness 错，§3）｜④三态闭环 **成立**｜⑤副本专用 **部分成立**（`pre` 值本席不可独立复取＋代际已移，§5）｜⑥副本崩／主链净 **成对成立**｜⑦`t167` 的 `D1` **成立且判据可复现**。

---

## §1 第 1 项：`THUNK-LIVENESS` 的算术与反例

**① 算术（本席自算）**：`0x1b63` = **7011**；`7001 + 10` = **7011** ⇒ 等式成立 ✓。**且第二驱动点给出第二个数据点**（载体只用了第一处）：`phase=slot1 … sobjc=0x1b64 … idobj=7002` ⇒ `0x1b64` = **7012** = `7002 + 10` ✓（同为 +10）⇒ 偏移是**被调方算出的常量**，不是单点巧合。

**② 那个 `10` 的来源（现取原文）**：
- `upstream/wpf/src/…/MS/Internal/PtsHost/PtsHost.cs:93`：`private static int _objectContextOffset = 10;`
- 同件 `:2652`（`SubtrackCreateContext`，入参含 `int idobj`）：`pfssobjc = (IntPtr)(idobj + _objectContextOffset);`
- 同件 `:2967`（`SubpageCreateContext`，同签名）：`pfssobjc = (IntPtr)(idobj + _objectContextOffset + 1);` ⇒ **族另一支会给 +11**
⇒ 观察到的 +10 恰好落在**subtrack 族实现**上；而快照的来源正是 `CreateInstalledObjectsInfo` 的**第一个入参** `fssubtrackparamethods`（钉版 `:618-620` 形参、`:634` `wpf_pts_methods_snapshot(t, fssubtrackparamethods)`）⇒ **「族」与「被调实现」两个独立事实互证**（不是同一个事实的复述）。

**③ 反例与"两种说法的强弱"（派单的 ⚠️）**：
- **恒等式读法**：`sobjc = idobj + 10` 对**任意** `idobj` 成立 ⇒ **单看这条等式，它证明不了任何"可调用"**。这一点派单怀疑得对。
- **但它不是恒真断言**，因为承重的不是等式自身而是三件**由被调方产生、native 侧无从编造**的事：
  1. `sobjc` 是**输出参数**：钉版 `:1494` 先置毒 `0xA5A5A5A5A5A5A5A5`、`:1495` 存 `sobjc_pre`、`:1497-1498` 以 `&sobjc` 传入 ⇒ `rewritten=1` 只能由**被调方写内存**产生；
  2. 差值 **10** 由**被调方**计算 —— 本侧只算 `idobj = 7000 + g_pts_sub_seq`（钉版 `:1496`），全件**没有任何一处**算 `idobj+10`（现取：`:1491-1498` 为本侧对该值的全部用法）；
  3. 观察值能**区分族**：subpage 支会给 +11（`PtsHost.cs:2967`）。
- **可证伪性**：若 offset 0 指向的不是 CreateContext 槽（例如 DestroyContext 之类，签名不同），调用后 `sobjc` 保持毒值 ⇒ `rewritten=0`、`v=OBJCTX-NOT-PRODUCED` ⇒ 该读数**会当场变红**。
⇒ **判**：这条吻合的正确读法是「**某个具体的托管实现（subtrack 族 `CreateContext`）真的被执行了**」（falsifiable、非恒真），**不是**「整表可调用」；把它写成"公式一致"太弱（那种读法判不出任何一只槽），写成"副本可调用"在**第 1 槽**上对、在**整表**上不对（与 §2 同源）。

---

## §2 🔴 第 2 项：`SLOT-ORDER-OK` 的推理 —— **判「不充分」**（缺口具名）

**判词：不充分。**「唯一零位落在 1-based 第 15 槽 ⇒ 槽序未错位」**不能**支持"槽序与声明一致（ABI 未错位）"这个结论，且**在结构上不可能**支持——理由三条，逐条给机制：

**2.1 这份指纹是"托管表自己写的"，native 只数自己拷贝的字节。**
- 钉版 `:536`：`memcpy(t->methods_snap, addr, WPF_PTS_METHOD_SIZE);` —— 17 字是**托管传入的** `fssubtrackparamethods` 的**原样拷贝**；
- 钉版 `:540-545`：零位计数与首个零下标，全部在**拷贝副本**上按 native 自己的字节偏移统计；`:603` 判据 `ok = valid && g_pts_method_zero_cnt==1 && t->rb_zero_index_win==14`。
⇒ **数据由被检方（托管）产生、索引由 native 自己的拷贝给出** ⇒ 这条检查是**托管表的自洽性检查**：只要托管表有唯一 NULL 且落在第 15 个字段，那么**无论 native 侧对"第几槽是什么函数"作何假设**，印出来都必然是"零位＝第 15 槽"。所以它**对 ABI 问题是盲的**（这正是判据件 `:155` 自己写下的定性：**"D2 的指纹是'用一个可观测事实反推槽序'，不是直接实测"**）。

**2.2 它能排除什么／不能排除什么（正面回答派单的追问）**
- **能排除**：① 拷贝**整体位移 k**（零位会落到 `slotN = 15 − k`：位移 +1 槽 ⇒ 应见 `slotN=14`，位移 −1 ⇒ 应见 `slotN=16`；现取 15 ⇒ k=0）；② 长度截断／取错结构（不会有"17 字 + 唯一零位"）；③ 托管**声明序与装配序**不一致（若托管按别的顺序填，零位会漂）。
  ⚠️ 但 ① 在 `memcpy(…,136)` 下本来就是**不可能发生**的失效模式，所以"排除了整体位移"这句话的战果很薄。
- **不能排除**：① 16 个**非零槽之间的任意置换**（零位不动 ⇒ 指纹一字不变）；② 任一非零槽指向**别的**函数；③ 因此也排除不了"**native 假设的槽语义与托管声明不同**"这一 ABI 错位（**这正是当初 `NOINFO-FSIMETHODS-ABI` 要防的那件事**）。

**2.3 要坐实"槽序与声明一致"，还需要什么（缺口清单）**
**槽名口径的本席现取**（`2026-09-29T19:16+0800`，`Pts.cs:1203-1222`）：`FSIMETHODS` 共 **17 只**字段，第 1 ＝`internal ObjCreateContext pfnCreateContext`、第 3 ＝`pfnFormatParaFinite`、**第 15 ＝`internal IntPtr pfnGetFootnoteInfoWord`（`:1220`）** ⇒ 载体引的"第 15 槽＝`PtsCache.cs:617` 置零的那只"**成立** ✓（在仓内 Linux 变体同样置零：`build/PresentationFramework.Linux/PtsCache.Linux.cs:790`）。
**逐槽语义指纹**：对**链上真正会用到的每一只槽**，用本侧作者值调用一次，并检查一个**有区分力**的后置条件（`rc=0` 不算——多数槽都返回 0）。今天已有的指纹只有两只：
| 槽 | 已有指纹 | 强度 |
|---|---|---|
| 1 `pfnCreateContext` | 返回值差＝本族常量 **+10**（§1），且 +11 支可区分 subtrack/subpage | **强**（常量级、可证伪） |
| 3 `pfnFormatParaFinite` | 崩溃栈**名级**：`app-snapdrive.log:1000-1012` 现取 ⇒ `Invariant.FailFast` ← `PtsHost.get_PtsContext()` ← **`PtsHost.SubtrackFormatParaFinite(...)`** ← `PTS.FsCreatePageFinite(...)` | **名级但发生在主链路径**（见 §9 `N-3`：驱动格那次 `f3(...)` 调用本身只到"可捕获异常 −100002"强度，那一行不带方法名） |
| **2、4–17（共 15 槽）** | **无任何指纹**（没被调用过、日志里也无可判行为） | **零** |
⇒ 正确结论应是 **`SLOT-ORDER-OK(第 1、3 槽有语义指纹；其余 15 槽仅"非空 + 零位一致"的静态一致)`**，而不是"槽序未错位"。

**2.4 判据件给的权限（这是本件唯一一处方向性问题，已按派单点名）**
- 判据件 `P1-fsimethods-abi-recon.md:122` 把 D2 写成**单向**判据：**"零位必须恰为 index 15；否则槽序/ABI 错位确证"** ⇒ 只授权**否命题**（不合 ⇒ 红），**没有**授权"合 ⇒ 槽序正确"。
- 判据件 `:124` 那句"只有 D1＝有效 且 D2＝零位在 15 都成立，**才允许谈"调用"（D3）**"是**谈调用的前置**，**不是解除 ABI `NOINFO` 的条件**。
- `t167` 载体 `:97` 引的「**判据明写**：解除需 D1 有效 ＋ D2 吻合」——**在本仓判据件里 0 命中**（现取 `2026-09-29T19:16+0800`：`grep -c '解除' build/MilBridge/P1-fsimethods-abi-recon.md` ＝ **0**；`grep -rln '解除需' build docs` 只命中 `P1-fsimethods-snapshot-report.md`（`t167` 载体自身）与**本件**——本件是引用它作为待判事实，不是第二个出处）。⇒ 这条"解除规则"**无出处**。
- 判据件 `:68` 现取仍写该 `NOINFO` **"今天仍成立"**；`:159` 明确禁止把"得"读成"已做成"。
⇒ 因此 `t168` §5「**`NOINFO-FSIMETHODS-ABI` 的"槽序"部分据此解除**」＝**超出判据件权限的推广**（把一个**必要条件**升成了结论）。**方向**：这不是把红洗绿，而是把"未取得"改记成"已取得"——按本线纪律属**放宽**，须由写者做 dated 收窄（见 §10 `F-1`）。

---

## §3 第 3 项：`calls` 的分开报 —— **如述不成立**（实质分开仍成立）

**现取的三个事实**（`t123-runner/logs/{t167,t168}/**` 原始件）：
1. `[FSPARAMETH-READBACK] … calls=%d` 用的是 `t->rb_calls`（钉版 `:584` 自增、`:593` 打印）＝**回读次数（驱动点序）**；它**每条腿都有且都是 1/2(/3)** —— 门未开的 `t167/app-snap.log` 现取也是 `calls=1,2` ⇒ **不分离任何两类腿**。
2. `[FSPARALIST-PARA-IN] … calls=%d` 用的是另一支探针的 `g_pts_dp3_calls`；**驱动腿与门未开腿都是 {`calls=0`, `calls=1`}**（现取：`t168/app-snapdrive.log` 第一条 PARA-IN 行就是 `calls=0`）⇒ **`calls=0` 并非"仅出现在 D3 门未开的两条副本腿上"**（载体 `:66` 如此写）。
3. `[FSPARALIST-EDRIVE]` 族的行**根本不带 `calls=` 字段**（只有族拒发支 `:1486-1488` 才印 `calls=0`）。
⇒ **结论**：`calls=1／calls=2` 与 `calls=0` **不是同一把标尺上的两个值**（一个是回读序、一个是另一支探针的窗口计数），**"确实分开"这个说法不成立**。
**但真正分开两类腿的证据是足的、也是现取的**：`[FSPARALIST-EDRIVE]` 行数 **6（驱动腿）vs 0（门未开腿）**；`[FSPARAMETH-D3]` 行 **`gate=PASS … src=methods_snap v=THUNK-LIVENESS-TEST` vs `gate=DISABLED`**；以及 `phase=slot1 rc=0 … rewritten=1 v=OBJCTX-PRODUCED` 这类**只有发出调用才会出现的具体读数**。**`gate=PASS` 的判据也可现取复核**：钉版 `:1803` `d2_ok=wpf_pts_methods_d2(t)`、`:1805` `if (d2_ok)`、`:1810` `wpf_pts_engine_drive_from(d, (const void *)t->methods_snap, where)` ⇒ 调用源确为**值化副本**（副本字节 → `:1491/:1492` 取 `+0`／`+16` 两只指针）⇒ **`R4`（调用源＝值化副本）在代码层成立** ✓。

---

## §4 第 4 项：三态闭环 `NONE`／`ALLZERO`／`VALUE` —— **成立**

| 态 | 现取逐字（原始腿日志） | 判 |
|---|---|---|
| `NONE` | `[FSPARAMETH-SNAP-GAP] rc=-10000 reason=null-methods entry=CreateInstalledObjectsInfo addr=(nil) state=NONE`（`t168/app-null.log`，2 样本）＋`copy_state=NONE valid_copy=0 zero_cnt_win=0 idx0_zero=0 … nonzero_win=0 … v=NO-VALID-COPY`（`snap=0 gap=2`） | 与另两态**可分**✓ |
| `ALLZERO` | `[FSPARAMETH-SNAP] … state=ALLZERO nonzero=0 zero_index_win=0 w0…w16=(nil)` ＋ `copy_state=ALLZERO valid_copy=0 zero_cnt_win=17 … v=NO-VALID-COPY`（`snap=4 gap=0`） | ✓ |
| `VALUE` | `state=VALUE nonzero=16 zero_index_win=14` ＋ `copy_state=VALUE valid_copy=1 zero_cnt_win=1 idx0_zero=14 slotN_zero=15 … v=SLOT-ORDER-OK` | ✓ |
- **注入开关缺省 0（现取，钉版）**：`:101-103` `WPF_PTS_FSP_PL_METHODS_SNAP` **0**、`:105-106` `WPF_PTS_FSP_PL_METH_NULL` **0**、`:108-109` `WPF_PTS_FSP_PL_METH_ALLZERO` **0**、`:1089-1092` `WPF_PTS_FSP_PL_ENGINE_DRIVE` **0** ⇒ 主链产物不含本块 ✓；四条副本 .so 现取哈希与 `run.out:7-10` 的 `-D` 组合逐条对应：`7c504cccf05d3a62`（SNAP+DRIVE）／`8ba40fe4d09d8326`（SNAP）／`496906112043310c`（SNAP+NULL）／`a406eee9693ebd84`（SNAP+ALLZERO）✓（本席自算，与车道 `so-*/libwpfwin32.so` 现取一致）。
- **口径注记（low）**：三态在 **`v=` 令牌层**并非两两不同——`NONE` 与 `ALLZERO` **共用 `v=NO-VALID-COPY`**；可分性落在 `copy_state=`／`zero_cnt_win=0 vs 17`／`NONE` 独有的具名 gap 行。`FSCBK` 面亦无"每态专用 `v=`"（`P1-fscbk-snapshot-report.md:33/:68` 现取：`state=0/1/2` ＋ `[FSCBK-SNAP-GAP]`）⇒ **不构成与 `FSCBK` 的偏差**。

---

## §5 第 5 项：副本专用（主链逐字节不变）—— **部分成立**

- ✅ **主链"零影响"本席独立复取**：`t168/s1/app_g1.log` 现取 **`FSPARAMETH` 0 行／`FSPARALIST-EDRIVE` 0 行**；`s1/leg_23.env`／`leg_24.env` 现取 `alive=yes app_rc=143 magenta=0 colors=383 ns=…`（`ae=0`／`15386`、`ink=480000`）；`s1/session.txt` 现取 `FAILLINE k=23/24 failfast=0 unrec=0` ⇒ "这些行只出现在副本腿"成立 ✓。
- ✅ `exports` 行数：`t168` 代际本席 19:0x 现取 **665 行／`15cb72a3abdadabb`** ✓。
- ⚠️ **`pre` 值本席无法独立复取 ⇒ 该项给 `NOINFO`（具名 `N-1`）**：`src/WpfGfx.Linux.Native/bin/**` **不在 git**（现取 `git ls-files src/WpfGfx.Linux.Native/bin` ＝ **0**），而该目录已被在飞写者重建（`19:10:39`）。本席 19:0x **现取到 `post` 值＝`291ef08a33f9b6e4`／401712 B（mtime `18:59:16`，与 `run.out:3` 的 build 戳 `18:59:13` 同趟）**，与载体/`run.out:6/:63` 的 `post` 一致 ✓；**同一读时序列的后段该件已变为 `352855f8dfbf8dc7`／402008 B，`exports` 亦 665→**669** 行** ⇒ "重建前后逐字节不变"的**配对**只能引 `t168`／`t167` 自己的 run 记录（`run.out:4` `pre_authority=291ef08a33f9b6e4`、`:6` `MAIN_BYTE_IDENTICAL=yes`），**本席无从复核 `pre`**。
- 顺带（供排期知道）：工作树 `win32_pts.c` 现为 `t173` 的 `FsFormatSubtrackFinite` 占位在飞（`1b642b1a906eb12f`），与 `t168` 代际 `6d6f753105224f78` 不同 ⇒ 引 `t168` 代码必须用 `git show 1e29ffd:`。

---

## §6 第 6 项：副本 `FailFast` 的成对（副本崩／主链净）—— **成立**

- **副本腿（`7c504cccf05d3a62`）**：`t168/app-snapdrive.log` 现取 `Unrecoverable system error.` **×2**（行 `994`／`996`）；第二条驱动点只有 `where=FsCreatePageFinite` ＋ `phase=slot1 rc=0 sobjc=0x1b64 … idobj=7002` 两行，**没有第二条 `phase=slot3`、也没有第二条 `asserts` 行**（EDRIVE 共 6 行＝第一条 4 行＋第二条 2 行）⇒ 崩在第二驱动点之后 ✓；`navclick_rc=1 alive_during=no app_rc=134`、`failfast=1 unrec=2`（`run.out:13-15/:22`，属 runner 捕获，见 `N-5`）。
- **主链两腿**：`s1/session.txt` `FAILLINE k=23/24 failfast=0 unrec=0`；`s1/app_g1.log` 现取 `Unrecoverable`＝**0**、`FailFast`＝**0** ⇒ **成对成立** ✓。
- **机制（现取栈）**：崩溃栈 `app-snapdrive.log:1000-1012` ＝ `Invariant.FailFast` ← `PtsHost.get_PtsContext()` ← `PtsHost.SubtrackFormatParaFinite(...)` ← `PTS.FsCreatePageFinite(...)` ⇒ 副本腿的崩溃点在**主链回调路径**上（`get_PtsContext` 的 `Invariant.Assert`），不是驱动格自己的槽调用 ⇒ 载体的"副本调用不是无条件安全"这句成立，且**归因更准确的说法是"第二驱动点把主链 `FsCreatePageFinite` 走到了 `SubtrackFormatParaFinite` ⇒ `PtsContext` 断言 FailFast"**（载体未点这一层）。

---

## §7 第 7 项：`t167` 的 `D1` —— **成立，判据可复现**

- **判据原文（现取）**：`P1-fsimethods-abi-recon.md:116-118`「在 `CreateInstalledObjectsInfo` 调用期内值拷 17 字并打印；再在驱动点**用同一悬垂指针**读出 17 字并逐字比对：**不同 ⇒ use-after-return 确证**（归因结束，不必再谈槽序）」；`:145` 要求「**值化了才谈槽序**（D1 先行）」。
- **执行面现取**：窗内 `state=VALUE nonzero=16 zero_index_win=14` vs 读回 `same=0 first_diff=0`（**首字即异**）；**三趟独立运行**（`t167` 两腿 ASLR 基址 `0x7fffec534df0`／`0x7ffdde467030` ＋ `t168` 驱动腿 `0x7ffc90d8a020`）判词**逐字一致** `v=USE-AFTER-RETURN-CONFIRMED` ✓；`D2` 记 `NOINFO`、`D3` 记 `gate=SKIP … v=D3-NOT-ATTEMPTED` ⇒ **R1/R5/R6 的顺序纪律照守** ✓。
- **结构性复核（排除混淆）**：比对是"**同一表的** `methods_snap` 副本 vs **同一表的** `t->methods_addr` 现读"（钉版 `:573` `memcpy(now, t->methods_addr, …)`、`:576` 逐字比）⇒ **同一表内自比**；若期间发生重快照，副本与地址**同时**更新，不会把"副本陈旧"误读成"内存被复用" ⇒ 该判据的因果**成立**（这是我要求自己先证明"被检条件真被检了"的那一步）。
- **三态面照抄 `FSCBK`** ✓：`WPF_PTS_METHOD_STATE_NONE/ALLZERO/VALUE`（钉版 `:112-114`）＋具名 `[FSPARAMETH-SNAP-GAP]`（`:525`），与 `FSCBK` 面的 `state=0/1/2` ＋ `[FSCBK-SNAP-GAP]` 同构（`P1-fscbk-snapshot-report.md:33/:68`、判据 `:82/:129` 现取）✓。

---

## §8 推翻的话

**我没有推翻这两件的任何"读数"**（三态、`D1` 判词、`gate=PASS`、`slot1 rc=0/rewritten=1`、副本崩／主链净，全部在原始件上独立复现）。**我推翻的是两条"说法"**：
1. **「零位吻合 ⇒ 槽序未错位（并据此把 `NOINFO-FSIMETHODS-ABI` 槽序部分解除）」—— 判不充分**：数据由被检方自写、索引由 native 自己的拷贝给出，**结构上测不到**"native 假设 ↔ 托管声明"（§2.1）；且判据件本身只授权单向（`:122`）、自陈是"反推非实测"（`:155`）、并记该 `NOINFO`"今天仍成立"（`:68`）；`t167` 引的"判据明写解除条件"在判据件里 **0 命中**（§2.4）。
2. **「`calls=1／2` 与 `calls=0` 分开报」—— 如述不成立**：两者来自**不同计数器**，且 `calls=0` **不是**门未开腿的专有值（§3）。
（两条都不是"读数错"，是**结论强度／witness 引用错**；`t168` 的读数面我未能找到任何捏造或跨代相减。）

## §9 具名 `NOINFO`

- **`N-1`** 主链 `bin/libwpfwin32.so` 的 **`pre` 值**：本席不可独立复取（`bin/` 不在 git ＋ 该目录已被在飞代际重建）⇒ "重建前后逐字节不变"**只有 `t168`／`t167` 自己的 run 记录**（`post` 值本席 19:0x 现取过、一致 ✓）。
- **`N-2`** 槽 **2、4–17** 的语义映射：**无任何指纹**（既无调用，也无可判行为）⇒ 今天不可判（§2.3）。
- **`N-3`** 槽 3 在**驱动副本**上的名级指纹：日志里的 `SubtrackFormatParaFinite` 出现于**主链** `PTS.FsCreatePageFinite` 路径（`:1000-1012`）；驱动格那次 `f3(...)` 只有 `rc=-100002`（该行不含方法名）⇒ 该槽**副本调用**只到"可捕获异常"强度。
- **`N-4`** "ABI 全表 17 槽"：无载体（≡`N-2` 的合并表述）。
- **`N-5`** `app_rc=134`：只有 runner 捕获一处载体（`run.out:15`）；本席能独立佐证的是 `Unrecoverable×2` 与"第二驱动点的 slot3/asserts 行缺失"。
- **`N-6`** `t167` 两样本的 `zero_index_now`（2／0／8）逐次不同：证实"该内存被复用"，但**复用者是谁**无载体（不影响 `D1` 判词）。

## §10 新发现的问题（本件**不修**；点名 `文件:行` ＋ 机制 ＋ 为什么是缺陷）

- **`F-1`（high｜方向＝放宽）**：「必要条件式零位指纹」被升成**结论**，并据此解除 `NOINFO`。
  - 载体：`build/MilBridge/P1-fsimethods-drive-report.md:40`（"槽序指纹支持'槽序正确（未错位）'"）与 `:96`（"`NOINFO-FSIMETHODS-ABI` 的'槽序'部分已解除"）；出处链：`build/MilBridge/P1-fsimethods-snapshot-report.md:97`（"判据明写：解除需 D1 有效 ＋ D2 吻合"）。
  - 机制：该指纹的**数据源＝被检方**（钉版 `:536` `memcpy` 自托管入参）＋**索引＝native 自己的拷贝字节序**（`:540-545`、`:603`），故对"native 假设语义 ↔ 托管声明"在结构上盲；判据件 `:122` 只写单向（"否则错位确证"）、`:155` 自陈"反推、非实测"、`:68` 记该 `NOINFO`"今天仍成立"。
  - 为什么是缺陷：把**本会话最承重**的一条从"必要条件通过"抬成"槽序未错位/部分解除"，而**只有 2/17 槽**有语义指纹（第 1 槽常量级、第 3 槽名级且发生在主链路径）⇒ 排期若据此当"已结证据"，会在 15 个未验槽上盲飞。
  - **修法（下一波，只增不改）**：在 `drive-report` 做 dated 追加——把"槽序未错位"收窄为「**第 1／3 槽有语义指纹；其余 15 槽仅"非空＋零位一致"**」，`NOINFO-FSIMETHODS-ABI` 记**未解除**并逐槽登记"已验／未验"，同时更正"判据明写解除条件"的出处（判据件里没有这句）。
- **`F-2`（medium）**：`calls` 的 witness 误引（`P1-fsimethods-drive-report.md:66`）。机制＝把 `[FSPARAMETH-READBACK] calls=`（`rb_calls`，钉版 `:584/:593`）与 `[FSPARALIST-PARA-IN] calls=`（`g_pts_dp3_calls`）当成同一标尺；现取门未开腿 `calls=1/2`（非 0）、驱动腿亦有 `calls=0` 行 ⇒ "分开报"如述不成立。修法：改用 `[FSPARALIST-EDRIVE]` 行数（6 vs 0）＋ `[FSPARAMETH-D3] gate=` 作 witnesses（并把两族计数器分开点名）。
- **`F-3`（medium）**：`§2` 归因点名的缺失入口与现取日志不符（`P1-fsimethods-drive-report.md:70` 点名 `FsFormatSubtrackFinite`）。机制/证据：驱动腿日志里 `FsFormatSubtrackFinite` **0 命中**，实际点名的是 `EntryPointNotFoundException: Unable to find an entry point named 'FsQuerySubtrackDetails' in shared library 'PresentationNative_cor3.dll'`（`[HC-UNHANDLED] #1/#2`，`app-snapdrive.log:842/848`），且 `FsQuerySubtrackDetails` 在 `t168` 代际 native 侧**无实现**（钉版仅注释 1 处 `:3532`）。为什么是缺陷：`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 的**类型**对、**点名**错 ⇒ 下游会去实现**错误**的入口（工作树里 `t173` 正在实现被点名的那一个）。
- **low 观察**：① `v=` 令牌上 `NONE`／`ALLZERO` 共用 `NO-VALID-COPY`（§4）；② `t167` 载体 `:6` 自陈"预登记在跑腿前定下、但与载体一并落盘"（对派单"先落最小载体"的偏离，已自认）；③ 三态注入只改了**副本**读数，主链面无对应负腿（现取主链 `FSPARAMETH`＝0 ⇒ 无对照），"缺省 0"由源码 `#ifndef` 保证、非运行期实测；④ `D2` 的 `expect_slotN=15` 与 `calib=` 字段是自证式打印（判据与实现在同一文件内），建议源头上把"15"登记进判据件（已见于 `abi-recon:122` ✓）。

## §11 证据在册（仓内只读；车道仓外）

- 本件唯一写入：`build/MilBridge/P1-fsimethods-verify.md`（新建）。
- 车道：`~/wv88y/t170/win32_pts.t168.c`（`6d6f753105224f78` 钉版）；原始腿日志（只读）：`/home/links-dev/t123-runner/logs/t168/{app-snapdrive,app-snap,app-null,app-allzero}.log`、`t168/{run.out,s1/**}`、`t167/{app-snap,app-snapdrive}.log`；副本产物哈希现取自 `t168/so-*/libwpfwin32.so`。
- 复核手段：`git show`／`git ls-files`／`sha256sum`／`wc`／`grep -ac`／`sed -n`／`nm -D` ⇒ 全部只读；未跑腿、未构建、未占显示位、未跑整门禁、未 `git add/commit/push`。
- **本席自我纪律**：引用源码一律钉 `git show 1e29ffd:` 版（并用 `wc -c` 交叉 319005 B）；下"不充分"结论前先证明所需条件**真的未被检**（钉版里只取用过 `+0`／`+16` 两只槽指针 `:1491-1492`；EDRIVE 行数 2×slot1＋1×slot3；日志全量搜索名级痕迹 ⇒ 见 §2.3／§9）。

**本件自证（落盘后）**：`head -n -1 build/MilBridge/P1-fsimethods-verify.md | sha256sum | cut -c1-16` ＝ 21ea356bacc7faca（末行不计入自身；末行＝本行）
