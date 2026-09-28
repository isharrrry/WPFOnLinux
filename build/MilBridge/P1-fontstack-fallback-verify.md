# P1-FONTSTACK-FALLBACK-VERIFY（`t115` 独立复核 · W38「字体栈降级」· `t114` 的件）

> **本席只读仓树、只写本件。** 对拍标准 ＝ **先写好的判据件** `build/MilBridge/P1-fontstack-fallback-criteria.md`（**`7ceeb953f38fbd4e`**／412 行，本席现取）；队长裁定 ＝ `build/MilBridge/P1-ptsname-result.md` §8 的**十六／十八／十九／二十**（本席现取裁定句）。
> **复核对象** ＝ **入账面 `057d08a`**（`fix(#81): t114 字体栈降级落地 —— 只改生成器（铁律 P8 守住）⇒ 崩进程真修好、k24 真渲染`，`2026-09-29T03:18:04+08:00`；**本席开工时它还在工作树、复核中归队长提交**）。面（`numstat` 现取）：`src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py **+45/−2**`｜`build/PresentationCore.Linux/FamilyCollection.Linux.cs **+41/−1**`｜evidence（`app_g1.log +1774/−291` 等 10 件）｜`P1-fontstack-fallback-report.md +251`｜`HANDOFF-NEXT.md +1`｜`docs/ROUTES.md +4`。
> **本席现取（`ts=2026-09-29 03:18:36.618851291 +0800`）**：生成器 **`8d01f7348a4f88cd`**｜生成件 `FamilyCollection.Linux.cs` **`6f084373c15504c7`**（2235 行）｜`build/WindowsBase.Linux/Invariant.Linux.cs` `d0a35feec973655e`（**本步未动**）｜`libwpfwin32.so` **`a131ea4e6f5cc4f5`**（本步**未**动 native）｜托管/`pf` `2988f5154ecac5dd`｜`PresentationCore.dll` `02f158868aa99df4`｜`wpfgfx_cor3.so` `941e69902d82ef02`｜`pts-pages-guard.sh` `e9688aaa11a1b9f4`｜载体 `P1-fontstack-fallback-report.md` `e1606ad230bfc577`。
> **仪器全部本席自造、仓外、零构建**：`git show/diff/status`（仓内只读）＋ 判据件**自称纯读**的生成器 `--check`（跑前后逐件 hash 对拍证明未写盘）＋ `pts-pages-guard.sh --legs`（纯读判据端）＋ `ctypes` 直读现盘 `.so`（环容量）。夹具全部落 `~/wv88y/t115/`，收尾删净。

---

## §A 崩进程修复面（正面判定）＝ **成立**

**成对读数（本席现取：`git diff 057d08a^ 057d08a -- evidence/leg_{23,24}.env`）**：

| 面 | k=23（before → after） | k=24（before → after） |
|---|---|---|
| `alive` / `app_rc` | `yes→yes` / `143→143` | **`no→yes`** / **`134→143`** |
| `magenta` / `colors` | `49923→0` / `844→383` | `0→0` / **`1→383`** |
| `ink` / `ae` | `428491→480000` / `141323→0` | **`0→480000`** / `480000→15386` |
| `ns` | `…RichTextBoxDemo` 逐字同 | **`…PracticalDemo→…FlowDocumentDemo`**（点中目标页） |
| `native_gap` / `managed_unavail` | `2→0` / `1→0` | `（同）` |
| `DEV shim` / `pf` | `a2de5ff2b667f33f→a131ea4e6f5cc4f5` / `6893d1d3fb1ee110→2988f5154ecac5dd` | 同 |

- **`FailFast` 位点不再被执行（本席自取的**间接**机器证据）**：新 `app_g1.log` 里 `FailFast|Unrecoverable` 命中 **0**（before 的崩溃腿是 `:797-812` 那一栈）；两腿 `alive=yes` ＋ `session.txt` 的 `fatal=0` **2 处**；`CLICK k=24 alive=yes … AE=15386 guard=187 unh=0`、`CLICK k=23 … AE=0 guard=828 unh=0`。
- **两页都有本趟读数（C3）** ✓：`session.txt` 的 `GROUP 1 arm=A clicks=[24,23]` 且两腿 `DEV shim` **都＝现盘 `.so`**（见 §D 裁定十九）。
- ⇒ **崩进程修复面 ＝ 成立**（`rc=134` 的自由度被关掉，且不是靠"静默 return"——见 ② C4/C5 的降级诊断与两态）。

## §B C6 红面（红面判定）＝ **归因成立（判据相位位，不是实现）**

- **判据端现取（本席自跑，`rc=1`）**：`PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),native-ledger-absent(PTS_GAP n=0) cannot=- diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0(点击前后无像素差) direction=in-file phase=degraded`；`PTS_G10_NAME=PASS form=unnamed reason=frontier-unnamed`。
- **相位位与阈值（本席现取，未被偷改）**：`pts-pages-guard.sh:51` 的**唯一机读声明行** ＝ `# PTS-DIRECTION: absent="magenta=0" present-floor=20000 red-when="magenta=0 AND no-named-line AND native_gap=0" source=TASK-0741 **phase=degraded**`；`:75 MAGENTA_FLOOR="${PTS_GUARD_MAGENTA_FLOOR:-20000}"`；**工具件 `sha16=e9688aaa11a1b9f4` 与本席上一件（`t111`）现取同值** ⇒ **零篡改** ✓。
- **归因（本席自算）**：两腿现在恰好命中 `phase=realized` 的**三条件**（`magenta=0` ∧ 无具名降级行 ∧ `native_gap=0`）且禁区两项都不成立（`colors=383 > 2`、`ink=480000 > 0`），但判据相位仍写死 `degraded`（degraded 期要求"降级还在"＝`magenta ≥ 20000` 且具名行在位）⇒ **红点是"相位位与实测形态不匹配"，不是实现缺陷**；且 `diag` 两条（`colors-out-of-band=383`／`leg23-AE=0`）**如实留在诊断位**、未清零。
- **裁定二十的落地判 ＝ 如实执行**：`phase=degraded` 未翻、`MAGENTA_FLOOR` 未调、无"为换绿而改相位/阈值"的痕迹（工具件逐位未改 ＋ 声明行原样在位）⇒ **维持红**✓。翻转为**协同动作**（前置＝`TASK-0302` 真落地 ＋ 那两条诊断清零；责任＝判据件写者）——本席只核"这一趟没偷翻"。

## ① 🔴 铁律 P8（只改生成器）＝ **成立（三路证据，本席自取）**

1. **生成器改动**：`git diff 057d08a^ 057d08a -- …/patch-presentationcore-compositefont.py` ＝ **`+45/−2`**，内容正是那段"降级判定诊断行 ＋ 闸门放宽（`_fbCompositeName || _fbNullFontFamily`）"（本席逐行现取）；
2. **重生成产物与改动同形**：`git diff 057d08a^ 057d08a -- build/PresentationCore.Linux/FamilyCollection.Linux.cs` ＝ **`+41/−1`**，且**那段插入文本与生成器模板逐字同形**（本席对拍两侧 diff 的文本，字符级一致）⇒ 生成件是**生成出来的**，不是手改的；
3. **再生成一次 identical（本席实跑）**：`python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py --check` ⇒ **`rc=0`**、输出 `[断言] 上游 681 行 → 生成物 2202 行（+1521 行…）`／**`[检查] build/PresentationCore.Linux/FamilyCollection.Linux.cs：内容已是最新`**／`[接线] csproj 已就位（幂等，不改）`；**跑前后 `FamilyCollection.Linux.cs` 的 `sha16` 均为 `6f084373c15504c7`（identical=yes）** ⇒ **幂等且与提交态一致**。
4. **未手改生成件、未碰 `upstream/**`**：`git status --porcelain upstream/` 现取 **0 行**；生成件的改动**完全**由第 2 条那段模板文本解释（无其它插入）；`build/WindowsBase.Linux/Invariant.Linux.cs`（M8）本步 **sha16 `d0a35feec973655e` 未动**（`numstat` 里也不在面内）。
   ⇒ **不接受"手改生成件也算修好"** 的判法：本件**改的落在生成器上**，且重生成复现同结果 ✓。

## ② 两极化 a / b / c ＝ **成立**（c 的副本形态 `NOINFO`，替代判为**够用**但要点名）

**本席从在册证据现取的成对行**（`grep -oE 'requested=… fallback=(yes|no)( resolved=…)?'`）：

| 极 | 现取行（计数） | 判 |
|---|---|---|
| **a（受控不存在族 ⇒ 必降级且进程活）** | `requested=ARIAL fallback=yes resolved=none` ×2｜`requested=GLOBAL USER INTERFACE fallback=yes resolved=none` ×2 | **成立**（`fallback=yes` ＋ 两腿 `alive=yes`） |
| **b（受控存在族 ⇒ 必不降级）** | `requested=DEJAVU SANS **fallback=no** resolved=DEJAVU SANS` ×1｜`requested=NOTO SANS CJK JP **fallback=no** resolved=NOTO SANS CJK JP` ×2（另 `requested=DEJAVU fallback=no resolved=none` ×3／`GEORGIA fallback=no resolved=none` ×1） | **成立**（存在族 `fallback=no` 且 `resolved=` 指向**该族自身**） |
| **c（"永远降级" 反腿必须被 b 腿红）** | 同趟直方图 **`fallback=no` 7 行 > `fallback=yes` 4 行** ⇒ **"永远降级"当场被否证**（若恒降级，全部行都会是 `yes`） | **形态成立（但非"副本反腿"）** |

- **对"替代够不够用"的判定**：够用**针对本题**（"有没有把降级做成永远降级"）——因为`fallback=no` 的行**同趟并存**，恒降级形态在**同一条日志里就被否证**（不需要副本）；**但**它**不能**替代"副本上恒降级 ⇒ 必红"的那条**仪器级**反腿（那条要一个可构建的托管副本 ⇒ 本件禁构建）⇒ 记 `NOINFO`，并在 Findings 里点名"该条的必红执法仍在 `NOINFO`"。
- 补充：托管侧**诊断字段三格齐**（`requested=`＋`fallback=` 二值＋`resolved=`）⇒ C4 的"降级可判"满足 ✓；且诊断行**只看"名字命中 4 个系统复合字体 ∨ 空字体族名"**（源码现取）⇒ **存在族不进这道闸**，"存在族被误降级"结构上不可能。

## ③ C1–C10 逐条（本席自算）

- **C1 构建面（成立）**：生成件进了产物 —— `PresentationCore.dll` `02f158868aa99df4`（＝本趟换代，见 ⑨ 的 `five_pre` 现取）；生成器 `--check` `rc=0`（见 ①）。
- **C2 导出/接口面（成立，**不靠加导出收尾**）**：`nm -D … | grep -c .` ＝ **572** ＝ `exports.txt` 行数（本步**未动 native**、`.so` 仍 `a131ea4e6f5cc4f5`）⇒ 导出面**在原位**，本步的修法**不经过**新增导出 ✓。
- **C3 进程存活面（成立）**：两页**都有本趟读数**（`clicks=[24,23]`；`leg_23`／`leg_24` 各自 `alive=yes app_rc=143`，见 §A）。
- **C4 降级可判面（成立）**：诊断三格齐、`fallback` 二值可读（4 yes／7 no）、`resolved` 给出落到谁（`DEJAVU SANS`／`NOTO SANS CJK JP`／`none`）。
- **C5 正向不误降级 ＋ 两态可区分（成立）**：存在族两例 `fallback=no` 且 `resolved=` 该族自身；与 a 腿的 `yes` **同趟并存** ⇒ 两态可区分 ✓。
- **C6 两页症状面（**不成立** —— 红面）**：判据端的红见 §B；**禁区两项都不成立**（`colors=383 > 2`；`magenta=0` 但 `ink=480000 > 0` ⇒ 不是空白）⇒ **未被读成空白绿** ✓；但 `phase=degraded` 下 `magenta<20000` ＋ 具名行缺失 ⇒ 判据判红（裁定二十：本件维持红）。
- **C7 同趟性（成立，且**不靠守卫**）**：本席逐腿现取 `DEV … shim=` ＝ `a131ea4e6f5cc4f5`（两腿**都**是现盘 `.so`）＋ `five_pre_g1.txt` 的 `libwpfwin32.so` 同值 ＋ `session.txt` 的 `shim_sha16=a131ea4e6f5cc4f5`／`pf_sha16=2988f5154ecac5dd` ⇒ **同趟 yes**（上一趟的跨代问题已消除）。
- **C8 `FailFast` 位点面（成立，**间接**）**：新日志 `FailFast|Unrecoverable` 命中 **0**；`FailFast` 本体未被改（本步改动面**不含** `Invariant.Linux.cs`，其 `sha16` 未动 ⇒ 无"改断言本体"的痕迹）。
- **C9 两极化成对存在（成立）**：a／b 两态同趟并存（见 ②）。
- **C10 正向族怎么选（成立）**：b 腿用的是**在集合里真有**的族（`DEJAVU SANS`／`NOTO SANS CJK JP`，`resolved=` 指向自身）⇒ 不是"随手挑一个能过的族"。

## ④ P1–P8 反腿（仓外副本文档；「未红或红而不点名 ⇒ 不成立」）

| # | 本席能做的 | 判 |
|---|---|---|
| **P8（铁律）** | **我把它做成**"生成器 ↔ 生成件"的三路对拍（① 的四条）：生成器改动 ＋ 生成件同形 ＋ `--check` identical（跑前后 hash 同）＋ `upstream/**` 零改动 | **成立**（可复现：`--check` 一行 + 两侧 `git diff` 文本对拍） |
| **P5（环容量 `WPF_PTS_JMP_MAX=4`）** | 本席现测：同一进程 push **4** 条（`LoCreateContext`／`LoAcquirePenaltyModule`／`LoGetPenaltyModuleInternalHandle`／`CreateDocContext`）后，**只有最后两条可检索**（`rc=1`），前两条 `rc=0`（被覆盖/驱逐） | **成立**（现象已现取；`WPF_PTS_JMP_MAX 4` 源码现取在位）⇒ 任何"用镜追链"的夹具**必须**重验自己的条目没被挤出 |
| **P2（只改计数/仪表）** | 判据端现取：**相位位/阈值零篡改**（§B）、`--check` 未写盘、导出面未动 | **正腿成立**；反腿（把 `MAGENTA_FLOOR` 调掉）需改仓内判据件 ⇒ 禁写 ⇒ `NOINFO` |
| **P3（症状列不派生）** | 本席把 `leg_*.env` 的 `colors/magenta/ink` 与**同一腿**的截图统计（`shots/g1/k24.png colors=383`）与诊断行**同一趟**对齐（`session.txt` 同 `GROUP`／同 `clicks`） | **成立**（三列与日志口径同趟自洽） |
| **P1／P4／P6／P7** | `P1`（把 `FailFast` 改静默 return）／`P6`（恒绿自检）需**托管副本构建**；`P4`（跨趟拼）本席可手工给成对反例（上一代 `leg_23` `shim=a2de5ff2b667f33f` 配现盘 `.so` ⇒ 三值不等）；`P7`（拿"没崩"当降级证据）＝**本件正面拒绝**：`fallback=` 二值 ＋ 两态并存才是证据，「没崩」单独不算（见 ⑤） | **`NOINFO`**（需构建）／`P4` 手工成立／**`P7` 本件正腿成立** |

## ⑤ 纪律第 `30` 条（三格；本族＝崩进程类）

- **本席自取三格（同趟、同 `GROUP 1 arm=A clicks=[24,23]`）**：① 进程新鲜度／调用序＝**两腿各自独立进程**（`app_pid` 逐腿不同、`clicks=[24,23]` 同组）② 关键前置量＝`leg_*.env` 的 `magenta/colors/ink/ae` ＋ `status` 计数（`guard=187/828`、`unh=0`、`fatal=0`）③ 判词＝`alive=yes`／`app_rc=143` ＋ 判据端 `phase=degraded` 下的红。
- **必要条款「净腿不崩就以为修好了 ＝ 假绿」本席判到**：本趟的**可红对照**就在同一条时间线上 —— **上一代** `leg_24` `alive=no app_rc=134 magenta=0 colors=1 ink=0`（我自 `057d08a^` 现取）⇒ "不崩"**不是**唯一证据；真正的证据是 **`failfast` 位点堆栈消失 ＋ 两态降级诊断 ＋ `ink>0`（真排版）** 三者同趟并存。⇒ **该条款在册** ✓。
- **"带历史的红＝假红"实例（`t114` 自报）**：本席独立复核其**机制** —— 守卫在 `phase=degraded` 下把"已实现形态"判红（§B）；这条红**不指示实现坏了**，指示**判据相位未翻**（裁定二十）⇒ **该实例成立**（判据相位位造成的红＝假红）。

## ⑥ 裁定十九（同趟；不许拿 `legs=2/2` 当证据）＝ **成立**

- 本席**逐腿**现取：`leg_23.env` `DEV … shim=a131ea4e6f5cc4f5`；`leg_24.env` 同值 ⇒ **两腿同代**，且 ＝ 现盘 `.so` ✓；`five_pre_g1.txt` 同值；**未**引用 `legs=2/2` 作为同趟依据（该判据端字段只作"两腿都在"的存在性）。⇒ **跨代已闭**（上一趟 `leg_23` 跨代的形态本趟不存在）。

## ⑦ 不变量 / 指纹 / 哨兵 / `D-G189` / `M6`·`M7`

- **覆盖面**：`infp.sh list` 现取 **234** 条；**`build/DirectWrite.Linux/Provider` 命中 0** ⇒ `M6`／`M7` **不在任何覆盖面**（本席现取复核）；判据件 `:144/:145/:153` **如实登记**了它（"**不在（0）**"／"残留缺口，如实登记；本件不主张扩面"）⇒ **裁定十八（只登记、不扩面）落地** ✓。
- **`inputs_fp`**：`ts=2026-09-29 03:18:36.618851291 +0800` ⇒ **`2a69c310141d40aa4691c669f0e44d3249a29931361ac50d63a383d1489a2a0f`**；`HANDOFF-NEXT.md` 末条 `cell=#1`（`ts=2026-09-29T03:15:30.460862477+0800`）登记 **同值** ⇒ **一致** ✓。
- **两哨兵**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**；字段现取 `SHA=941e69902d82ef02`／`PC=02f158868aa99df4`／`PF=2988f5154ecac5dd`／`WIN32SHIM=a131ea4e6f5cc4f5`／`WB=9e860cbeecb352e1` ⇒ 与 `five_pre_g1.txt` 的五个现取值**逐位相符**（`SHA`＝`wpfgfx_cor3.so`／`PC`＝`PresentationCore.dll` 两位已随本趟换代重写）✓；`WAVE=w80-freeze`／`BASELINE=#80`／`BASELINE_SHA16=b27ff6332f263495` 未变。
- **`D-G189`**：注册表现取 **3** 次 ＝ `git show HEAD:` 版 **3** 次 ⇒ **未被虚假扩大**。

## Findings（不改 `t114` 任何件）

- **`F-1`（low）`t114` 引用的 `failfast=0`／`unrec=0` 两枚读数**在在册证据里无载体**：本席 `grep -oE 'failfast=[0-9]+|unrec=[0-9]+' evidence/*` ⇒ **0 命中**（`session.txt` 只有 `fatal=0` 两处）⇒ 该对读数**不在门禁读面**。可替代的机器读数（本席自取）：两腿 `alive=yes app_rc=143`、`fatal=0` ×2、新日志 `FailFast|Unrecoverable` **0 命中**。**建议**把这两个 token 落进 runner 的 `session.txt`／`leg_*.env`（或判据改引 `fatal=`），否则"位点不再执行"永远只有间接证据。
- **`F-2`（low）生成器自报行数与生成件实际行数不一致**：`--check` 印「生成物 **2202** 行」，而 `wc -l build/PresentationCore.Linux/FamilyCollection.Linux.cs` ＝ **2235**（差 **33** 行）⇒ 措辞/口径需对齐（不影响 identical 判定；`[检查] …内容已是最新` 与 hash identical 已成立）。
- **`O-1`（观察）托管具名面现在整趟为空**：`entry=unknown` 0／`[PTS-UNAVAILABLE]` 0 ⇒ 判据端只能给 `PTS_G10_NAME=PASS **form=unnamed**` ⇒ **"unnamed 通过"不是"具名前进"证据**（与 `t105` 的 `F-1` 同族）；判"下一跳是谁"仍只许读 `^PTS_GAP entry=`（现取也 0 行）。
- **`O-2`（观察）`leg_23` 的 `AE=0`（点击前后无像素差）与 `colors=383` 两条诊断仍在** ⇒ 与裁定二十写的"相位翻转前置＝那两条诊断清零"一致；本件只提醒**别把它们当噪声忽略**（`leg23-AE=0` 意味着该腿的点中判定这趟**没有像素级证据**）。
- **`O-3`（观察）c 反腿的副本形态仍 `NOINFO`**：本趟的 `fallback=no`（7 行）足以否证"永远降级"，但"**恒降级副本 ⇒ 必红**"这条**仪器级**反腿需要一个可构建的托管副本（本件禁构建）⇒ 该条的执法位今天**空**；若判据要它，须由写者另派一件（或改为在证据面加一条"恒降级 ⇒ 全行 `yes`"的机器判据）。

## `NOINFO`（不折绿、不折红）

1. **需托管副本构建的反腿**（`P1` 静默 return／`P6` 恒绿自检／`c` 副本恒降级）⇒ 禁构建未跑。
2. **"`FailFast` 位点不再执行"的**直接**机器读数**：无 token 载体（`F-1`）⇒ 只有间接三证（堆栈消失＋`alive=yes`＋`ink>0`）。
3. **两页真排版**：本步只做"降级而非打死"；`Fs*` 族 66 条未动（裁定二十）⇒ 本件**不**把任何绿读成排版成立。
4. **`M6`／`M7` 的覆盖面**：裁定十八＝只登记不扩面；本席只复核"登记在位 ＋ 覆盖面命中 0"，**不主张**扩面。
5. **整趟门禁 / 真实显示位 / 跑腿面**：本任务禁跑整趟门禁、禁占显示位、禁跑腿 ⇒ 未跑。

---

### §追加（只增不改；`ts=2026-09-29 03:20:12.5+0800`）—— 本席对两页截图的自量 ＋ 一条口径观察

- **本席自己量了截图**（PIL，仓内只读现取）：`build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/{k23,k24,last}.png` 均 `1280x1024`；**distinct_colors = 383**（与 `leg_*.env` 的 `colors=383` **逐位相符**）；**magenta 像素 = 0**（与 `magenta=0` 相符）；深色像素（本席口径 `sum(rgb)<300`）＝ **837862**。⇒ `colors`／`magenta` 两列**可复算** ✓。
- **`O-4`（观察）判据列 `ink=` 的口径未见机读定义**：本趟两腿 `leg_*.env` 均 `ink=480000`（与 `session.txt` 的 **boot** 行 `ink=480000` 同值），而本席对同一张 `k24.png` 自量得 **837862**（口径＝深色像素）⇒ **两值不是同一口径**；判据以 `ink>0` 当"真排版证据"时，该列的**可复算性弱于 `colors`／`magenta`**。**建议**：在判据件或 runner 里写明 `ink` 的定义（量哪张图、按什么阈值），或改用一条可复算的排版证据位。
- `O-1`／`O-2`／`O-3` 三条观察（具名面整趟为空 ⇒ `form=unnamed` 不是前进证据；`leg23-AE=0` 与 `colors-out-of-band=383` 两条诊断仍在；c 反腿的副本形态仍 `NOINFO`）**位置不变、结论不变**。

SELF-SHA16 （口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 9561b60e571ae418

---

## ⏪ `t116` dated 追加 —— 本席（`scribe`）对 `t115` 余项的**独立现取**与关账处置（读时 `2026-09-29T03:2x+0800`；本件上方原文**一字未删**；段末给出新的自报口径值）

**仪器（现取）**：`.so` ＝ `a131ea4e6f5cc4f5`；Release／部署件 ＝ `2988f5154ecacdd`；装置件 `session_inner.sh`／`legs-to-env.py` **本周首改**（覆盖面内 ⇒ 同趟 `cell=#1`）；夹具**全部仓外**（`/tmp/t116-fx`、`/tmp/t116-dry.sh`、证据副本 `/tmp/t116-ev`），**用完删**。

### ① `F-1`：**按（甲）** —— 「位点不再执行」变成装置里的直接读数（成对可判性）
```
修前：grep -oE 'failfast=[0-9]+|unrec=[0-9]+' evidence/**  ⇒ 0 命中（只有 session.txt 的 fatal=0 ×2）⇒ 无载体
修后（同源 cnt/$GLOG 干跑）：无标记 ⇒ FAILLINE k=24 failfast=0 unrec=0 src=app_g1.log:FailFast|Unrecoverable
                              注入 'FailFast' + 'Unrecoverable system error' 各一行 ⇒ failfast=1 unrec=1   （计数器有响应）
转换器往返（仓外夹具 session + 空 app_g1.log）：leg_24.env 第四段 ⇒ FAILLINE k=24 failfast=0 unrec=0 src=…
                              而 LEG／NAMED／DEV 三段与改前**逐字同形**
反兼容（旧格式 session，删该行）：⇒ failfast=- unrec=-（＝"没测到"，不是 0）
```
- **口径**：`failfast=` ＝ `app_g<gi>.log` 里 `FailFast` 的**行数**；`unrec=` ＝ 同日志里 `Unrecoverable system error` 的行数（**≡ 既有 `fatal=`**，同源同量）。**判位点用 `failfast=`**；`alive=yes`／`ink>0`/崩溃栈消失**只作辅证**。
- **装置仍工作（不跑腿的可判证明）**：守卫对装置件**零引用**（`grep -c` ＝ **0**）⇒ `--legs` 判词与装置改动无关；`bash -n` ＋ Python 编译过；新行落在 `CLICK`–`PHASE` 之间 ⇒ 转换器**既有 region 扫描自动带走**（未改锚、未新增解析器）。
- **`NOINFO(未跑腿)`**：**没有**一整趟真腿的端到端读数（派单禁跑腿）⇒ "整趟腿仍工作"只有上面三条**间接**证明。

### ② `F-2`：**口径差 33 ＝ `HEADER` 行数**（不改生成器）
```
生成器（自读 src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py）：
  print(f"[断言] 上游 N 行 → 生成物 {len(out.splitlines())} 行")   ⇒ 数的是**正文 out**
  output = HEADER + out                                          ⇒ 落盘的是**整件**
我自算：HEADER 行数 = 33；生成件 wc -l = 2235 ⇒ 2235 = 2202 + 33 ✓
```
⇒ **口径（逐字）**：该自报**是正文行数、不是整件行数**；整件 ＝ 正文 ＋ `HEADER`（今天 33 行）；两者**都不参与 `identical` 判定**（后者比整件字节）。**本件不改生成器**（`src/**` 越域）。

### ③ `O-1`：**`form=unnamed` ≠ 具名前进**（必落册）
```
现取：evidence/app_g1.log 里 entry=unknown = 0、[PTS-UNAVAILABLE] = 0
     守卫 --legs（证据副本）⇒ PTS_G10_NAME=PASS form=unnamed reason=frontier-unnamed
```
⇒ **口径**：`form=unnamed` 只表示"**没有具名行可判、形态判据按其形态通过**"；「具名前进」的证据面是 **`PTSGAP`／台账**（`^PTS_GAP entry=` 行与 `PTSGAP_FRONTIER` 的 `before→after` 名更换）。**两者是两件事，禁止互相折算**；本趟"具名面为空 ＋ 台账 0 行"的态**既不是倒退、也不是前进**。

### ④ `O-3`：**按（乙）** 把 c 反腿改成**证据面判据**（今天可达的那个形态）
```
现取三元组直方图（evidence/app_g1.log）：
   3  requested=DEJAVU   fallback=no  resolved=none
   2  requested=ARIAL    fallback=yes resolved=none
   1  requested=GEORGIA  fallback=no  resolved=none
   ⇒ resolved= 今天恒 none；fallback=no = 7 > fallback=yes = 4（与 t115 记的 no=7>yes=4 相符）
```
⇒ **本件落进判据件**（`P1-fontstack-fallback-criteria.md` 的 `t116` 段）：`C9` 的 c 格改为**要求同一趟读数里两种方言并存** —— ① `requested=<受控不存在族> … fallback=yes` ≥1；② `requested=<受控存在族> … fallback=no` ≥1；**只有其一 ⇒ 必红并点名**（"两态分不开：疑似永远降级／从不降级"）。**不要求** `resolved=<族>`（现取恒 `none` ⇒ 那样是**永不可能绿**的判据；记为**未来项**）。**（甲）路线只写要求与代价**（要可构建副本或旁路开关 ⇒ `src/**` ＋ 构建/跑腿 ⇒ 另派单）。

### ⑤ `O-4`：`ink=` 的口径（自读 `shotstat.py` ＋ **自算复验**）
```
公式（源码注释逐字）：ink = W×H − magenta − dominant（dominant ＝ 出现次数最多的单色像素数；ink<0 ⇒ 0；**无阈值**）
复验（evidence/shots/g1/k24.png，1280x1024）：shotstat.py ⇒ ink=480000
   我按同式自算 ⇒ 480000 = 1310720 − 0 − 830720 ✓（可复算）
"深色像素"（另一量）：复核者 837862／我按"三通道和<384" 840070 ⇒ **与 ink 不是同一个量**
```
⇒ **口径**：`ink=` 只作"**这页是不是纯空白**"的粗证（守卫 `realized` 期只用 `magenta==0 ∧ ink>0`）；**不得**用于阈值/比例/逐位断言，**不得**与 `magenta`／`colors` 并列称"同等可复算"。**未改 `shotstat.py`**（其注释已有口径；本件把它抬进判据册）。

### ⑥ 本席同趟复核（与 `t115` 的成立面不冲突）
- `leg_24 alive=yes app_rc=143`／`colors=383`／`ink=480000`（现取 leg env）；`FailFast|Unrecoverable` 在**应用日志**里现取 **0** 命中（`grep -c` 现取）——这与 `F-1` 的装置口径**互补**：前者是"应用日志里没有该串"，后者是"装置把该计数**落成机读格**"。
- **守卫 `--legs` 的现取判词**（与 `t115` 的 §B 一致）：`PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing…` ⇒ **这正是 C6 的红面**（字体栈降级后页面真排版 ⇒ 既有 `degraded` 相位判据仍在执法）⇒ **不是**本件引入、**也**不是"修好了"的证据；**相位翻转另排**。
⏪ 待办指向：`O-3` 的（甲）路线与 `F-2` 的生成器文案、`F-1` 的"整趟腿端到端"三项**均需另派单**（前两者触 `src/**`，后者需跑腿）。
SELF-SHA16 （`t116` dated 追加后；口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`）＝ dacae10b60e852e2（原自报行 `9561b60e571a` 系**追加前**全文值，原样保留）
