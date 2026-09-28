# HANDOFF-NEXT —— wpf-linux 现场交接（**现读现算**；生成 2026-09-24 14:3x，取代此前所有过期版本）
> ⚠️ **本件数值随波变动**：下面所有 sha16／字节数／step 数**一律以 §7 现算为准**；本件是**导航**，不是判据。
> ⚠️ 本件的**唯一权威来源是现场**。若本件与现场冲突，**以现场读数为准**，并按 §7 的七条命令重取。
> ⚠️ **不引行号**（纪律 31）：本仓有若干件**每代重写**、且同一句会**多处出现**（如基线件的「九位」行现盘在 `:14` 与 `:77`，历史块共 7 处）⇒ **一律引内容锚**。

## §1 世代与冻结（现读）
- 冻结哨兵：`docs/CURRENT-STATE.md:9` = `BASELINE-FROZEN gen=#77 sha16=e3ebc811641bd467 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（现取；⚠️ **被哈希的件由这行的 `file=` 字段指定**，不是 `CURRENT-STATE.md` 自己。）
  ⏪ **dated 对齐（`t58`，读时 `2026-09-28T12:33+08:00`）**：**现读** ＝ `BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（**改前**上述 `gen=#77`／`e3ebc811641bd467` 是**留档原文**，不删）。
  （⚠️ **被哈希的件由这行的 `file=` 字段指定**，不是 `CURRENT-STATE.md` 自己。）
- 基线件：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = `e3ebc811641bd467`／**1,138,219 B**（世代链：`#73` `f747350edf97a74a` → `#74` `8b303228ff088349` → `#75` `3b9e463e70220e11` → `#76` `954df351a119d36f` → **`#77` `e3ebc811641bd467`**；现取）。
  ⏪ **dated 对齐（`t58`，读时 `2026-09-28T12:33+08:00`）**：**现读**：块件 `b96d4312565a3c49`（**1,224,932 B**；世代链 `#77 e3ebc811641bd467` → `#78 d60b414d5e99cf72` → `#79 901619543b3d913b` → `#80 b96d4312565a3c49`）；**改前**：`e3ebc811641bd467`／`1,138,219 B`（`#77` 时点，留档）。
- 九位（`#77` 冻结值；取法见 §7-2）：`bridge 4e25e4b27d4d5ae1`｜`pc 53fd7fffcdb30243`｜`pf 4fcd2ca021c39064`｜`windowsbase 07c89f1872c1a3c1`｜`provider 4041df9a704abfed`｜`win32shim fc60c34d51fd9247`｜`wic f7b3026c8c019be2`｜`hbtextline 921ba9c65e9fb3be`｜`dwf b07f801556e1a511`。
  ⏪ **dated 对齐（`t58`，读时 `2026-09-28T12:33+08:00`）**：**现九位（现取，`#80`）**：`bridge 4e25e4b27d4d5ae1`｜`pc 5b6cfda3e12b84fc`｜`pf b9a4f3a0e48e688d`｜`windowsbase 9e860cbeecb352e1`｜`provider 7e8a217b4165a6b9`｜`win32shim 6825dd7071387a46`｜`wic_shim f7b3026c8c019be2`｜`hbtextline 921ba9c65e9fb3be`｜`dwf c83be96f18759edc`（**改前**：上面那行的 `#77` 九值（如 `pc 53fd7fffcdb30243`）逐字留档）。⚠️ `pf` 仍**环成员**（同尺寸 6,123,520 B）。
  ⚠️ **`#77` 五位位移（`pc`／`pf`／`windowsbase`／`provider`／`dwf`）＝ 路径承载体**：`#76` 的九位是**从旧树 `O` 拷进 `N` 的**，`#77` 是 `N` 内**第一次真重建** ⇒ 托管件 DEBUG 目录里嵌的 `*.pdb` **绝对路径**变成 `N` 的路径；**字节大小与 `#76` 冻结值逐位相同**（`3601408`／`6123520`／`1111552`／`104448`／`39936`）⇒ **非产品回归**。`bridge`／`win32shim`／`wic_shim` 是原生/发布件、本波未重建 ⇒ 逐位未变（反证）。口径句：**"托管程序集的哈希是路径承载体；凡跨树位置比较产物哈希，先问『它是在哪个树里产出的』。"**
  （`pf` 仍是**环成员**：整波重建必变、**同尺寸 6,123,520 B** ⇒ 不许当漂移/回归判据，`D-G92`。）
  （`pf` 是**环成员**：整波重建必变、**同尺寸 6,123,520 B** ⇒ 不许当漂移/回归判据，`D-G92`。）
- `inputs_fp`（`#77` 落地后，**覆盖面 211 件**）：`b67560f2ff28932b69cf198aa68ed91ca66f582180d27d4af929deca54dd540c`
  ⏪ **dated 对齐（`t58`，读时 `2026-09-28T12:33+08:00`）**：**现读**：`inputs_fp = `**`abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`**（**覆盖面 225 件**；`t58` 现取 `~/w153a/bin/infp.sh fp`）—— **改前** `b67560f2ff28932b…`／`211 件`（`#77` 时点，留档）。⚠️ 覆盖面在本波起**只在 `build/close-wave.sh` 的白名单**里变；改覆盖面 ⇒ `[42] --expect` **同趟**改（纪律 46／`D-G131`）。
  ⏪ **dated 更正（`t60`，读时 `2026-09-28T12:40+08:00`；`225` 原文保留）**：**现取 ＝ 覆盖面 `226` 件** —— `verify-all.sh:1195` ＝ `run_step "FP-MANIFEST-TEETH" … --expect **226**`；牙现取 `FP_MANIFEST_TEETH=**PASS** reason=ok files_n=**226** files_n_uniq=226 blank_n=0 declared_expect=226` ＋ `FP_MANIFEST_STEP_RC=0`（`tooth_sha16=be19edddf7f02797`）；`inputs_fp` 现取仍 `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`（与 `t58` 同值 ⇒ **覆盖面无变动**）。⚠️ **`225` 的归因（机器证，如实）**：`225` 是 **`t14` 期**读数、被我在 `t58` **引用而未现取** —— `git show 07c0a52b:verify-all.sh` 的第 `1195` 行**当时已是 `--expect 226`** ⇒ 正确答案在 `t58` 那一刻就是 **226**；故本条更正的教训是 **「凡引用计数必须现取，不许搬上一代的数」**（本仓既有口径），**不是**"覆盖面无同步扩面"。
  ⏪ **归因更正（`t60`，同日；主控裁定，逐字）**：上句把 `225` 的来源写成"`t14` 期读数"**不够准** —— **`225` 是主控在 `t58` 派单里逐字给出的过时读数**（派单原文：「…`inputs_fp` 现取 ／ **225 件**（以你现取为准，别抄我这行）」），**我在 `t58` 未复核即引用**（我侧责任 ＝ **未现取**；主控侧 ＝ 给了过时读数，他已自记为本轮**第 4 处**数字错）⇒ **现取 `226` 件**；本条与 `:261`（覆盖面现取 226 件）**一致**。
  （`#62` 后 = `1ffd13f7c927dea71fd5dca866f7c6f81e8efce9939c22c85d55c0a35fb20f96`／158 件；`#61` 后 = `a00bf53a64c47531963b0f82aae689fe4cee1363c7b9e670799566cb7963c668`／157 件。**改动覆盖面内任一件必移**，属设计性变更。）
- **步数**：`verify-all.sh` = **50 步**（`#77` 加 `[48] WIRING-COVERAGE`／`[49] PARSER-GUARD`／`[50] PROTO-ATTR`；首行 `DECL` 声明的步数 == 现取 `run_step` 数，**`DECL` 行数 ≠ 步数**，纪律 46）；覆盖面 **211 件**（`[42] --expect 211`）。
  ⏪ **dated 对齐（`t58`，读时 `2026-09-28T12:33+08:00`）**：**现读**：`verify-all.sh` ＝ **`55` 步**（`grep -c '^run_step "'` ＝ **55**；首行 `# VERIFYALL-STEPS-DECL: 55 gen=#79`）｜覆盖面 **225 件**（`[42] --expect 225`）—— **改前**：`50 步`／`211 件`（`#77` 时点，留档）。⚠️ 步数账的**唯一不变量** ＝ 首行 `DECL` 声明的步数 == 现取 `run_step` 数（本文 §5-46）。
  ⏪ **dated 更正（`t60`，读时 `2026-09-28T12:40+08:00`；`225` 原文保留）**：**现取 ＝ 覆盖面 `226` 件** —— `verify-all.sh:1195` ＝ `run_step "FP-MANIFEST-TEETH" … --expect **226**`；牙现取 `FP_MANIFEST_TEETH=**PASS** reason=ok files_n=**226** files_n_uniq=226 blank_n=0 declared_expect=226` ＋ `FP_MANIFEST_STEP_RC=0`（`tooth_sha16=be19edddf7f02797`）；`inputs_fp` 现取仍 `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`（与 `t58` 同值 ⇒ **覆盖面无变动**）。⚠️ **`225` 的归因（机器证，如实）**：`225` 是 **`t14` 期**读数、被我在 `t58` **引用而未现取** —— `git show 07c0a52b:verify-all.sh` 的第 `1195` 行**当时已是 `--expect 226`** ⇒ 正确答案在 `t58` 那一刻就是 **226**；故本条更正的教训是 **「凡引用计数必须现取，不许搬上一代的数」**（本仓既有口径），**不是**"覆盖面无同步扩面"。
  ⏪ **归因更正（`t60`，同日；主控裁定，逐字）**：上句把 `225` 的来源写成"`t14` 期读数"**不够准** —— **`225` 是主控在 `t58` 派单里逐字给出的过时读数**（派单原文：「…`inputs_fp` 现取 ／ **225 件**（以你现取为准，别抄我这行）」），**我在 `t58` 未复核即引用**（我侧责任 ＝ **未现取**；主控侧 ＝ 给了过时读数，他已自记为本轮**第 4 处**数字错）⇒ **现取 `226` 件**；本条与 `:261`（覆盖面现取 226 件）**一致**。
- 推送（`#77` 冻结时点，**推送前**现取）：`feat-Linux` 本地 HEAD = `fd9a9a1886d25575ae625d44741d45620d554185`（`t1` 两笔：`7027be06e7fddb793ea22411c1f0645626474a73` ＋ `fd9a9a1886d25575ae625d44741d45620d554185`，**随本波推送带走**）；上一波远端值 = `5d45064ab4b5e2003fe509753d3d0689a78eff1e`（**本波两笔**：波件 `9cea5cc4786b8cc3abdc9f9f281aba113c042e82` ＋ **主控登记批** `5d45064ab4b5e2003fe509753d3d0689a78eff1e`；clone = `~/netTest/GitProj/WPFOnLinux`，`origin`=gitee、`upstream`=dotnet/wpf；**本行与其后提交若不一致，以 §7-6 现取为准**）。
  ⏪ **dated 对齐（`t58`，读时 `2026-09-28T12:33+08:00`）**：**现读**：`feat-Linux` 本地 `HEAD` ＝ `git ls-remote origin refs/heads/feat-Linux` ＝ **`81372408d2052b52…`**（`t14` 文档收口三笔：`d80ec2a3…`／`6d09f788…`／`81372408d2052b52…`；`porcelain=0`）—— **改前**：`fd9a9a1886d25575…`（`#77` 时点，留档）。
- 放行标记：`~/w21-verify/w*-POST.done` 现取 21 件：w56-POST.done／w57-POST.done／w58-POST.done／w59-POST.done／w60-POST.done／w61-POST.done／w62-POST.done／w63-POST.done／w64-POST.done／w65-POST.done／w66-POST.done／w67-POST.done／w68-POST.done／w69-POST.done／w70-POST.done／w71-POST.done／w72-POST.done／w73-POST.done／w74-POST.done／w75-POST.done／w76-POST.done（真时刻一律 `stat` 取）。
  ⏪ **dated 对齐（`t58`，读时 `2026-09-28T12:33+08:00`）**：**现读**：`~/w21-verify/w*-POST.done` 现取 **`25` 件**（`w56`…`w80`；新增 `w77-POST.done`／`w78-POST.done`／`w79-POST.done`／`w80-POST.done`）—— **改前**：`21 件`（`#77` 时点，留档）。

## §2 在飞（**先读这节再动手**）
- **在飞**：**`#77`**（仪器波；五件 ＝ `TASK-0740`＋`0742`＋`0744`＋`0745` ＋ 主控同趟追加的「仓根 `Directory.Build.props`/`.targets` 缺席牙」＋ **21 件旧路径重指向**）—— `verify-all.sh` **50 步**／覆盖面 **211 件**；冻结／推送／哨兵读数见本节现取（本件是**导航**，不是判据）。无其它链在跑（槽 `FREE` 时方可起新重活）。
- **下一波 `#64`＝`TASK-0717`**（把「基线率闸」做成牙）：入口 = 新件 `build/MilBridge/tools/baseline-rate-gate.sh`；规格输入 = `~/w157a/baseline-rate-gate.md`（`c4839dc9e8876bcf`／口径 `57915081ffdbacf8`）＋ `~/w157a/bin/baseline-rate-gate.py`（`0dac2ea941b56f4f`，**无第三方依赖**，已逐位复现仓内四个 `REQUIRED_N_ALT`）。
- **待命车道（都已交付包、等落地窗口）**：W180A（`#77`：`0740`＋`0742`＋`0744`＋`0745`）｜W181A（`0747`：`SHAppBarMessage` 返 0）｜W182A（`D-G147` 工作区语义）｜W183A（`TASK-0739`③ 显示号租借）｜W184A（`0744-FU`：装置附 socket 身份）。

### ⏪ **dated 对齐 · §2（`t58`，读时 `2026-09-28T12:33+08:00`）**
- **现读**：**无链在跑** —— 波 `#80` 已**全链闭环**（冻结 `#80`：`901619543b3d913b` → **`b96d4312565a3c49`**；两趟 `post1`／`post2` 各 **`55 ✅ / 0 ❌`**；推送 `81372408d2052b52…`；两哨兵 `cmp` **IDENTICAL**`），`t14` 的文档收口与 `t57` 的登记批均已落仓并推送，`porcelain=0`。**改前**：本节写 `#77` 在飞（留档上文，未删）。⚠️ **本节的"在飞"读法**：以 `~/w21-verify/w*-POST.done` ＋ `git ls-remote` ＋ `porcelain` **现取**为准。

## §3 队列（一条改动 → 一次冻结）
1. **`#77` 已落地**：`TASK-0740`＋`0742`＋`0744`＋`0745`（W180A 包）＋ 主控同趟追加（仓根 props 牙，**折叠进 `[9]`、不动步数**）＋ **21 件旧路径重指向**：步数 `47→50`／覆盖面 `205→211`／`--expect` **同趟现取**。随后 **`0747`**（W181A，`wsh` 必动 ⇒ 冻结闸 `allow_changed` 要含它）；再 **`#78`**＝`D-G147`＋显示号租借＋`0744-FU`（串行落地、数字现取）。
2. 未闭 `[Next]`（现取）：`TASK-0747`（W181A 包已就绪、等落地窗口；`0740`／`0742`／`0744`／`0745` 已由 `#77` 办）；`TASK-0720`／`0721`／`0732`／`0741`／`0746` **本批已翻 ✅**；`TASK-0709`–`0719`／`0722`–`0739`／`0743` 早已 ✅。
3. 未绿 `[MVP]`：`TASK-0007`（富文本 23／流文档 24 `rc=134`，真因 `TASK-0302`）｜`TASK-0201`（静默 `rc=139`，上界已收到 4.87%）｜`TASK-0302`（PTS／原生 LineServices 缺口 **可操作 88／实现口径 95**，现读 `工具口径 100`）。
4. `TASK-0111` = ✅ **归档为「不可判 ＋ 已知无产品价值」**（号不撤）：① 该红已被 `#54`/`TASK-0210` 修掉（现行桥 `4e25e4b27d4d5ae1` 上 `0/12` 红 vs 旧件 `12/12`）⇒ **产品价值 = 0**；② `A` 臂红率**随时间漂移**（`12/12 = 100%` → `7/28 = 25.0%`）⇒ `P1` 被排除 ⇒ **整批 `VOID-PREMISE`、40 腿不跑**；`N1` 作为修法**撤回**。判据件：`~/w156a/{criteria.md,leg-plan.md,AMENDMENT-1.md,AMENDMENT-2.md,WAVE-PREREG-0111.md}`｜装置 `~/w155a/device/wpfhintsgate.so 3c2a36580a7806f6`。

### §4-追（`t17` dated 更正，2026-09-26；**§1–§3 原文保留**）
- **`#77` 冻结块九位行的 `provider` 是上一代值**（`1f9511a7ef395bfe`），同块位移行与全部 `BASELINE tier=` 机读行写现值 `4041df9a704abfed` ⇒ **同块自相矛盾**；根因＝记录模板写死字面量 ∧ 冻结器三道核不含 `provider`（`D-G149`）。**不改冻结块**；处置见 `docs/WAVE77-PREREGISTRATION.md §8.3`。
- **`provider` 的规约权威 = `build/DirectWrite.Linux/Provider/bin/<CFG>/…`**（工程产出目录；冻结器 `NINE` 与 `applocal-expect.py` 都用它）；`build/PresentationCore.Linux/bin/<CFG>/…` 是**副本**，须与之相等（`D-G150`，牙 = `WFREEZE_NINEAUTH`）。⚠️ 副本刷成权威后，**在册九位的 `provider` 与现场不再相同**（`4041df9a704abfed` → `609192a419d125f2`，冻结点之后的重建位移）。
- **`#77` 的 5 处 `dirname` 层数回归已修**（`D-G149` 同批账；牙 = `WFREEZE_ROOTDEFAULT`，接在 `close-wave.sh [5c/6]`）；覆盖面 **211 → 212**、`inputs_fp = 99db4fb592aba8f7dc53263d9914fa7c47c3f542207c35736ade1cddc08b6709`。
- **`~/w153a/bin/infp.sh`** 已按契约改为**可覆盖默认值**（原硬编码旧路径；`t7` 撤链接后它会静默失能成 `NOINFO`）。
- **`TASK-0745` 的活件状态**：主控已把 `E1+E2` 从活冻结器回退（现读 `6bf3c5c77eee8dd8`，`grep -c check_record_forms` = 0）；返工设计见 `build/MilBridge/P0-w77-repair-report.md §F7`。

### ⏪ **dated 对齐 · §3 队列（`t58`，读时 `2026-09-28T12:33+08:00`）**
- **已闭的本批 `[Next]`（现取判词）**：`TASK-0740`／`0742`／`0744`／`0745`（波 `#77`）｜`TASK-0747`（波 `#78`，`win32shim e8127a3d7128d417`）｜`TASK-0750`／`0751`（波 `#79`，`d050d78198e6093c`／`a1ae1257ffd2638e`）｜`TASK-0752`／`0753`／`0754`／`0755`（车道 `t21` 四组成对读数）｜`TASK-0720`／`0721`／`0732`／`0741`／`0746`（波 `#76`）⇒ 结账表与逐行证据见 `build/MilBridge/P1-docs-close-report.md`（`47d84297e7517a4f`）§2。
- **仍剩（下一波）**：`TASK-0007`（🔴 两页洋红占位，真因 `TASK-0302`）｜`TASK-0201`（🟡 复测功效口径）｜`TASK-0302`（🔴 PTS 增量；**进度 = 具名前沿跳数**，现前沿 `LoCreateContext`）｜新增未闭项 9 条见本文「§下一波未闭项」（`t54`／`t57` 写）。

## §4 近期新登记（要看细节读登记册）
- **`D-G115`（判据装置缺陷 · 判词方向）**：`regression-decision.py` 的 `subkind=rate-aggravated` 及判词**不判方向**（`p ≤ alpha ∧ 旧件也红` 就印"本波把速率**显著加重**"）⇒ 在**下行腿/必要性**设计里打印**反结论**（现场：`--old 24/27 --new 0/40` 印"显著加重"，事实是**降到 0**）。**已修**（`#63`）：加 `REGDEC_DIRECTION=` ＋ 下行改 `rate-mitigated`，**上行口径逐字保留**。口径句：**"判词带方向断言 ⇒ 判据必须真的判方向；双尾显著 ≠ 上行显著。"**
- **`D-G116`（臂与腿的有效性）· 7 实例**：① 对照臂改体制（`drop`/`noop` 让 WM 失明 ⇒ 加装饰 ⇒ `m_ok=0`）② **单格判红**（退化/死腿也报 `r_ok2=0`）⇒ **判红 = 四件合取** `START_MAX=0 ∧ m_ok=1 ∧ r_ok2=0 ∧ APP_ALIVE=yes` ③ 腿基线跨腿串味（`xfwm4` 记忆 ⇒ 需 `wmstate` 复位）④ 把"被干涉项的在场"当入分母条件 ⇒ 干涉臂无分母（改用 `TARGET_ATTEMPT_IN_BEAT` ＋ 各臂忠实性断言）⑤ 族识别谓词错（**按 `type` 不按 `prop`**）⑥ "条件同一性"须含 **X 会话寿命/WM 冷热态与时间稳定性** ⑦ **把结果算进体制 ⇒ 用"保护可比性"的名义否掉可比性**。**牙已落地**（`#63`：`regime-identity-check.sh`，**体制列 = 输入侧四列**，结果侧只作诊断、不进 `rc`）。
- **`D-G117`（判据显示层）**：步自报抽取器只认 `KEY=PASS|FAIL|NOINFO` ⇒ `PREREG4=NA`／`…_SUMMARY`／`…_OUT-OF-SCOPE` **不上屏** ⇒ **半可见 = 假绿方向**。**已修**（`#63`，两半）：批次首行带四态计数 ＋ 择一表纳入 `NA`／`SKIP`／`REPORT` ＋ 三类行出口；**显示窗 12 → 16**（现最大 8 行、无步骤触窗）。
- **`D-G118`（判据/功效前提 · 基线率漂移）**：**用历史速率反推 `N`，而速率本身随时间漂移 ⇒ 功效前提被证伪**。口径句：**"条件同一性必须包含『世界的时间稳定性』；凡登记速率都必须带时间窗，且用于定 `N` 之前必须在同窗现取一道基线率闸。"** ⇒ **全仓警示**：`24/27 = 88.9%`／`M2:R2 = 3/33`／`6%→0% 需 131 腿` **在册速率全部隐含"09-23 那个时间窗"**。
- **`D-G119`（判据装置缺陷 · 域选错）**：**掩码域**（假阴性）／**枚举域**（假阳性）／**heredoc 域**（假阳性）／**注释域**（假绿）。**对偶判据**：**「注释里的调用不算调用」的对偶 = 「注释里的『排除』不算证明」** ⇒ **证据域 = 剥注释后的代码文本，且非 shell heredoc 体置空**。
- **`D-G108` 第二种机制（发布完整性）**：**产物只落工作树、从未入库 ⇒ 声明表路由锚指向"远端不存在"的版本**（`handoff.md` 压缩版 333 行 mtime `09:17:44` 晚于 `2e15b61` 8 分钟；声明 `HO` 却已是压缩版）⇒ 由 `#62` 收尾链同趟补推。
- **`D-G114`**（`shell-quote-trap-check.sh:325` 帧栈泄漏 ⇒ 整份文件判据降级为诊断）／**`D-G113`**（假旋钮：开关只改打印）／**`D-G103` 族**（按模式匹配进程的自匹配，本会话 ≥ 9 例）**均已修**（`#60`/`#61`）。
- 登记册自洽：`DEFREG=PASS declared=155 route_ids=155`｜`DECLDRIFT=0`。
  ⏪ **dated 对齐（`t58`，读时 `2026-09-28T12:33+08:00`）**：**现读**：`DEFREG=PASS declared=`**`214`**` route_ids=`**`214`**` ＋ `DEFREG_DECLDRIFT=`**`0`**（`keys=-`；`t57` 的 `D-G176/177/178` 与 `t58` 的 `D-G180` 已入册；`D-G179` **由队长保留**给另一条发现）—— **改前**：`declared=155/route_ids=155`（留档）。

## §5 闸门与纪律（本会话血的教训，逐条都有现场证据）
1. **闸门 = 完成制标记 ＋ 主控显式 GO**。**"闸门字面满足 ≠ 可以写共享 `$R`"**；写前必须确认 ① 收尾/构建链不在跑 ② 重活槽未被别人持 ③ 冻后链已完成。**闸门口径的任何细化必须同趟广播给所有在飞车道**。
2. **逐径 `git add`，绝不 `-A`**（`D-G108`）；推送前先 `ls-remote` 判**快进**（⚠️ `git fetch origin feat-Linux` **不更新** `origin/feat-Linux`），非快进 ⇒ 停手报主控。
3. **进程只按 PID 收**；**绝不** `pkill`/`pgrep -f`（`D-G103`，本会话 ≥ 9 例）。扫 `/proc` 找链/找进程时**必须显式排除 `$$` 与自己的祖先链**（漏排 `$$` 是最常见变体）。
4. **重活一律走槽**：`bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1800 --wait 1800 -- <cmd>`；`HEAVYSLOT=TIMEOUT`／`NOINFO low-memory`／`MAXHOLD_KILL` **都不是读数**。
5. **长任务走后台作业**（前台超 600 s 会被工具链 SIGTERM ⇒ 读数作废）。
6. **写盘 temp + `rename`**；改动前 `cp -p` 备份 —— ⚠️ **备份必须取在"任何写之前"**（`#63` 实测一次取在第一次写之后 ⇒ 备份是混合态，真回滚会回到混合态）。
7. **显示号只用 `:2xx` 空闲号、几何 `1280x1024x24`**（`D-G105`）；**每腿只要新起 `Xvfb`/WM 就与"长寿会话"不同体制**（`D-G116` 实例 ⑥）。
8. **冻结链的每一步都要独立复算**：`步骤通过/失败`、`用例通过`、日志 sha16、`config=` 互证九位、`设备上没有空间` = 0。
9. **对"会反复改写的车道"，单次采样不足以定罪**（反极性序列的中间态看起来像"异物写入"）—— 看时间序列或直接问车道。
10. **`--emit` 是把声明表打到 stdout**（`defect-registry-check.sh --emit > declared.tsv`）；核对"声明 ↔ 现场"先看**被写文件的 mtime**。
11. **指纹类读数（`inputs_fp` 等）只在树静止时有意义**：链在跑时算出的值会漂（现场实测同一命令先后不同）；取指纹**必须在无链在跑时**，并**连算两次比稳**。
12. **「拿哈希去 grep 文件名」是范畴错误**：要举证「某件在覆盖面内」，先让工具**打印清单**再 grep。
13. **派单里的期望读数必须标明出自哪个装置/哪一位**（`WPTD_*` ≠ `TLINE_GATE` ≠ `GEOM*`）。
14. **「必须成为 `head -1`」的插入，锚必须是**位置**，不能是上一代的文本**：解析首个 `^#\s*VERIFYALL-STEPS-DECL:\s*(\d+)\s+gen=(#\d+)` ＋ **先断言 `DECL 数 == grep -c '^run_step "'`** 再插。
15. **冻结只要改写了路由件（`KD`/`CS`/`HO`/`AB`/`KRJ`…），就必须重发 `declared.tsv`**：`req=`/`present=` 是**路由状态快照**。⇒ 冻结那一刻**立刻报主控**由主控重发（`#60`／`#61`／`#62`／`#63` 四次实测：主控都在冻后 `verify-all` 走到 `[10]` **之前**发出）。
16. **`python3 - <<EOF`（stdin 脚本）里不许用 `__file__`**：stdin 下恒为 `<stdin>` ⇒ 反推仓根会静默指到别处 ⇒ 由 bash 侧显式导出仓根并加自测钉住。
17. **改"读数行/报告行"必须断言命中数**：`str.replace` 静默 no-op 是最隐蔽的假更新（车道自伤三次）⇒ 逐字段断言重建或替换后立刻 `grep -c` 复核。**替换/撤销类脚本一律断言 `hits`**。
18. **"两趟对拍"的合格线 = 判词行逐字一致**；跑次戳（`outdir=`／`rundir=`／随机后缀）、仪器计数漂移（实测 `magenta_frames=38 vs 40`）**不算差异，但必须在报告里点名并列出实际数**。
19. **追加"历史行"必须用插入**（不许"替换前缀＋跳到行尾"）；改完 `grep -c` 核旧行仍在。
20. **判据的"生效边界"必须可见**：早于生效代的证据件打 `SKIP` ＋逐件点名 `reason=pre-effective`，与 `PASS` **分开计数**。**禁止**用"放低边界/删掉该件"换取好过。
21. **新牙落地同趟必须过 `PIPEFAIL-SIGPIPE` 牙**：新件一进仓就改 `files=`／`sites=` 读数；凡 `printf … | grep -q` 一律改成 `case`／`[[ == *pat* ]]`／**逐行 `[[ =~ ]]` ＋ here-string**（⚠️ `[[ "$out" =~ $pat ]]` 是**整串**匹配 ⇒ 多行必须逐行）。**该族本会话咬 5 次**。
22. **`echo "post$i_rc=$?"` 是错的**：bash 把 `$i_rc` 当一个未绑定变量（`set -u` 直接退出 ⇒ **少跑一趟**）⇒ 写 **`${i}_rc`**。
23. **"冻前恰 1 处声明类红"是有条件的**：条件是**本波重取过臂／改过被声明件**；仪器波若不动臂与声明件 ⇒ **冻前可以全绿**（`#58`/`#61`/`#62`/`#63` 实测全绿）。派单里的期望读数**必须带条件**。
24. **记录模板里"花括号全大写"会被冻机器当占位符并 `assert` 炸掉** ⇒ 用 `$VAR` 或 `<NAME>`；落地前用机读校验器过一遍。
25. **"恒 0 守卫"是死代码**：守卫/断言必须**用一条已知为真的输入证明它真的会亮**；`==`/`if` 两侧类型要同类（`len(x) == 0` 而非 `x == 0`）。
26. **幂等守卫只判"`NEW` 在不在"**：`NEW` 逐字**包含** `OLD` 时，"新在 ∧ 旧不在"**永不成立** ⇒ 重跑会再插一遍（`#62` 实测）；**守卫只写一半比没有更危险**。
27. **任何对拍/解析在任一侧为空时必须响亮失败**，不许静默判等/判空（本会话三次同族：空文件 `diff` 假报 IDENTICAL／解析取空 ⇒ 假违反／`rc` 取自管道末段）。
28. **引"行号"前必须先 `sed -n` 打出该行原文再写**，不许凭记忆写"权威某行"。
29. **凡"我已推送 X"的断言，必须逐件核到远端**（`git cat-file blob HEAD:<path>`／`ls-remote` ＋ 逐件比），**不许用"那一批推了"代指单件**。
30. **复现别人的"集合类"读数时，成员集合必须先现场取**（如 `bash ~/w153a/bin/infp.sh list`），不许凭记忆列名单。
31. **禁止对"随世代重写或同句多处出现"的文件引绝对行号** ⇒ 一律用**内容锚**（或现场 `grep -n` 取数并声明取数时刻）。
32. **`echo` 的双引号里不许出现反引号**（`QUOTE-TRAP` 会**真的执行命令替换** ⇒ 打 `… 未找到命令` 并啃掉行内容）；`grep -c` 的 `0` 且 `rc=1` ⇒ `|| echo 0` 会得 `"0\n0"`（算术致命）⇒ 先取数再归零。
33. **回复点（备份）集合必须在"读完全部落地目标"之后才冻结**：漏备**不响**（覆盖成功、`sha` 断言也成功 —— 因为断言比的是**覆盖前现读值**，不是**备份件**）⇒ 落地前必须**逐件断言**"有备份 ∧ 备份 `sha16` == 覆盖前现读 `sha16`"，缺一**拒落**。（`D-G126`，波 `#65` 现场：派单 A 表**第 1 件**在无备份状态下被覆盖，靠 fork 克隆 `HEAD:` ＋ 另一份 `backup/*.orig` **两独立来源逐位相同**才救回。）
34. **任何"影子／隔离／回退树"在**写**之前必须逐件断言 `stat -c %h == 1`（实体），不满足即**拒写**：`cp -al`／`cp -l`／`ln` 造出来的不是隔离，是**与权威树同 inode 的农场** ⇒ 一次原地写就**写穿 `$R`**（现场：`#65` 落地后抽样 `$R` 下 17 个 `*.sh`，**16 个 `link>1`**；`shell-quote-trap-check.sh` `%h=4`，孪生在三处车道影子里）。`D-G101` 的旧牙射程是**仓内**跨区、且在 `verify-all` 里**恒不为 PASS** ⇒ 这个方向**没有任何一步会红**。收尾必须交**权威树完好证明**（`find $R -newermt <开工时刻> -type f` 无本方产物 ∧ 本方碰过的每件 `$R` 侧 sha16 == 拷贝时刻读值）。（`D-G127`）
35. **账目对齐**：凡波报告里写下的"已办／已跑／判词"，**必须同趟写回在册状态位**；两处不一致时**以报告里的机器读数为准**，并在发现当趟把另一侧改齐 —— 否则下一位接手者会**按假前提派活**（现场：`TASK-0301` 的反极性腿在 `W70A-report.md` §5 早有判词 `C7 成立`，而 `ROUTES.md` 一直写"未跑" ⇒ 主控据此**多派了一整条车道**）。（`D-G129`）
36. **判据必须声明输入来源并在取数前断言其身份**：输入若是**瞬时/派生**状态（`shadow/`／`out/`／`logs/` 下的中间物）⇒ 一律**先重造**再判（或判 `NOINFO`），否则结论会变成"环境此刻长什么样"的函数、**换一双跑法结论就变**（现场：两件仪器从 `shadow/tree` 取源树，被另一双跑法清空后**照样出结论**；修法是自建源树 ＋ `before-sha256-mismatch` 响亮失败）。（`D-G130`）
37. **"取最新"靠第一行，插入锚必须动态取那一行**：凡用 `sed … | head -1` 取"第一行声明／最新声明"的抽取器，**必须把口径写在件头**；凡往那种块里**插入**新声明，锚一律**动态取"文件里第一行"** ＋ 断言 `hits==1` —— 否则你按"当时的最新行"插，别人再往头部插一行，你的新声明就**落到旧声明之下**，工具读到**上一代** ⇒ `FAIL count-mismatch`（**假红 ＋ 整波返工**）。（`D-G131`，波 `#67` 预备实测）
38. **装置通过环境变量接收"目标"时，开跑前必须断言自己拿到了**：`DISPLAY`／`WDISP`／根目录／臂目录这类目标，缺一个就**拒跑**（非零 rc），并把**实际取到的值印进产物** —— 现场：某腿脚本认 `WDISP` 而调用者只设了 `DISPLAY` ⇒ **4 条腿全打在并不存在的 `:235` 上**、**整批作废**，靠被试件自己打出的 `XOpenDisplay(":235") 失败` 才被发现。**"没打在目标上"与"打上去没反应"在读数里长得一模一样** ⇒ 必须由装置自证落点。（`2026-09-24` W159A 事故；同族 `D-G130` 是"输入取自瞬时状态"，本条是"输入压根没送到"）
39. **输出体积纪律（宿主 OOM 事故后加）**：**几 MB 级文件/日志绝不读进会话** —— 只许 `wc`／`head -n 20`／`tail -n 20`／`grep -c`／`grep -m 5`；自己产生的过 MB 日志**同一条命令里压成一行计数**，原始件只报**路径＋`sha16`＋行数**；**长跑（>120 s）一律放托管后台作业**（`nohup … >> log 2>&1 &`，**不要 `tee` 回灌会话**）并报 **PID＋日志路径**。现场（`2026-09-24 17:24`）：宿主进程 `V8::FatalProcessOutOfMemory`，**同一分钟掐掉了三条会话里的前台长跑**（含一趟冻前 `verify-all`）—— 这不是"省点带宽"，是**别人的读数会被你葬掉**。
40. **报数一律现算，不引用前一次列印**：任何"我报的 `sha16`／字节数"都必须在**发出那条消息的同一条命令里**现取；凡"读数表"，表里每个 `sha` 都要有**机器读者**（逐行现算，不符即 `STALE<<<` ＋ `FAIL`），且**解析不了的行必须 `FAIL`**（"没匹配上" ≠ "通过"，否则那一行永远不在覆盖里）。现场（`2026-09-24` W158A）：**件与表都对，错的只是消息**（把 17:56 的列印抄进 17:57 的消息）；同一轮它还发现表里有**两件挤一行** ⇒ 读者解析不了 ⇒ **那行零检查**。（`D-G125` 实例②）
41. **冻结基线件一旦被误写：唯一安全的修复 = 从 git 取回该世代的逐字节原件**（`git -C <clone> cat-file -p HEAD:samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`）—— **车道不许手工重建 header、不许从中间态备份拼接**（现场：波 `#67` 一条车道为"回到冻前态"按 `[#66 块起点:]` 重写基线件 ⇒ **连带删掉开头 54 行 `BASELINE-HEADER`** ⇒ `BASELINESHA=FAIL`；主控从 git 回灌后逐字节复原）。⇒ **遇基线件损坏：停手、报主控、由主控回灌。**
42. **写冻结基线前必须先留一份 `B.pre-freeze.<gen>.bak`**：`w27-freeze.py` 目前**不备份基线件** ⇒ 一旦写坏，唯一退路是 git（而 git 里只有**已推送过**的世代）⇒ 本波若尚未推送，**没有退路**。（方向已入 `[Next]`，本波不动冻结器。）
43. **长跑前必须现取宿主余量 ＋ 临时件必须可回收（满盘事故后加）**：任何链式长跑（`close-wave`／`verify-all`／整波）**开跑前**先取 `df -m` 的 `available`（**≥ 5 GB** 才放行），并把读数写进**链日志头**；整链中间件**不许**落 `/tmp`（落各自车道目录）；会写临时目录的装置**件头必须写回收策略**。**清理他人临时件必须过两闸**：**①无活进程引用 ②仓内零引用（或远端可逐字取回）** —— **禁用"看着像中间件"当理由**。（现场：`r-gate-step.sh:563` 默认 `OUT` 永不回收 ⇒ 三天 66 件/6.8 GB 撑满 `187G` 宿主，反手把正在跑的波写成 0 B 假红；事故同时**摧毁了六条车道会话**。）
44. **件头自述涉及"装在哪、被谁调用"时必须与代码形状一致，且必须由牙读出来**：凡件头写"未接线／不进 `verify-all`"的件，若 `grep '^run_step "'` **命中该件** ⇒ 必红；反向（自述"已接线"而零命中）⇒ 也必红。（现场：`prereg-four-requirements-check.sh` 件头自称"未接线"而它早已是第 `[34]` 步 ⇒ `D-G136`。）
45. **`NA`／"本波不适用"类声明一律走机读行形态**：新波预登记必须写 `PREREG-NO-REGRESSION-DECISION: <非空且非否定令牌>`（**判据节内**）；"行首锚定声明句"这一形态**只留给历史件**（其残余洞＝行首即声明句、随后自我否定仍算声明，已登记 `D-G135`）。（现场：`#60` 起的整节正则 ⇒ **提到即算**，主控复现"只提及、四要件全缺"也判 `NA rc=0`。）
46. **凡断言两条计数相等，先证明它们在现场真的相等**：把"应该是"当"就是"写进断言，等于给落地器埋一道**永远拒跑**的门。（现场：主控要求 `#75` 断言"`DECL` 数 == `run_step` 数"，而现场 **35 vs 39**（有 4 个"不动步数"的波没加 `DECL` 行）⇒ 照字面写落地器永远拒跑；**真不变量＝首行 `DECL` 声明的步数 == 现取 `run_step` 数**，且**插入前**首行 `DECL` 的 `gen=` 必是**上一波**，不得与 `--wave-gen` 比。）
47. **落地/推送脚本的"派生路径"必须在**参数解析之后**由**同一个 `R`** 现推，并**逐条断言落在 `$R` 之下（两道闸）**：①**字面前缀**闸 `case "$X" in "$R"/*) 拒跑`；②`readlink -f` **解析后**前缀闸（防"`$R` 下的符号链接指到仓外"）。**排练必须两极化证明这两道闸真会红**：**E1（正极）** 异树 `--repo` ⇒ 落地成功且**源树零写入**（`find $R -newermt` 前后对账 ＋ 逐件 `sha` 比对）；**E2（反极）** 派生路径为**指向 `$R` 的符号链接** ⇒ **点名拒跑 ＋ 写入件数 0**。（现场：`2026-09-26` 波 `#76` 窗口内，一条预备车道在沙箱排练 `--apply`，脚本把 `VA/CW/FPMS` **绑在参数解析之前**（用默认 `R`）⇒ **真 `$R` 被写两件**（`verify-all.sh`／`build/close-wave.sh`，窗口 ≈1 分钟，两件 `%h==1` 未写穿，当场还原并逐位复核），并**连带作废**同窗口内正在跑的整趟波读数 —— `close-wave.sh` **正是当时在跑的脚本**。⇒ `D-G130` 实例 ④。）

## §6 未结清的账（主控侧）
- **我（主控）的推送账**：`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／`build/MilBridge/HANDOFF-NEXT.md`／`README.md` 已于 **`f158988cf770`** 推上远端（逐件 `HEAD:` 核对 **5/5 MATCH**，`porcelain=0`）。它们**都不在 `fp_inputs()`**（改它们不动指纹），但**每次改完都要重发 `declared.tsv`**（`DEFREG` 判"route 文件里的编号是否都已声明"，改了却漏发 ⇒ `DEFREG=FAIL reason=undeclared-id-in-route`）。
- **app-local（仓外共享目录）**：`~/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0` 已由主控用 `sync-applocal.sh` 修好（`drift=3 → 0`，**其中一件曾是修前桥 `feef049e9d0e313a`**）。**后续任何"探针测到陈旧件"的现象先查这里**。
- **两处哨兵**：`/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag`（`cmp IDENTICAL`）；`handoff.md`（`HO` 键）与**本件**不同：前者是**上游/入口文档的压缩版**，后者是本交接件。
- **车道报告入库约定**：收尾波的车道报告放 `build/MilBridge/<LANE>-report.md` 并随该波提交推送。

### ⏪ **dated 对齐 · §1–§6 一览（`t58`，读时 `2026-09-28T12:33+08:00`）**
| 处（原行号） | 改前（留档原文一字未删） | 改后（现读） |
|---|---|---|
| §1 冻结哨兵 | `gen=#77`／`e3ebc811641bd467` | **`gen=#80`／`b96d4312565a3c49`** |
| §1 基线件 | `e3ebc811641bd467`／1,138,219 B | **`b96d4312565a3c49`／1,224,932 B** |
| §1 九位 | `#77` 九值（`pc 53fd7fffcdb30243` …） | **`#80` 九值（`pc 5b6cfda3e12b84fc`／`pf b9a4f3a0e48e688d`／`provider 7e8a217b4165a6b9`／`win32shim 6825dd7071387a46`／…）** |
| §1 `inputs_fp` | `b67560f2ff28932b…`／211 件 | **`abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`／225 件** |
  ⏪ **dated 标注（`t62`，读时 `2026-09-28T12:46+08:00`）**：**本格内那个 `225 件` 已被下方 `t60` dated 行取代 ⇒ 现值 ＝ `226 件`**（原文一字未删；改值理由与归因见下方两行）。
  ⏪ **dated 更正（`t60`，读时 `2026-09-28T12:40+08:00`；`225` 原文保留）**：**现取 ＝ 覆盖面 `226` 件** —— `verify-all.sh:1195` ＝ `run_step "FP-MANIFEST-TEETH" … --expect **226**`；牙现取 `FP_MANIFEST_TEETH=**PASS** reason=ok files_n=**226** files_n_uniq=226 blank_n=0 declared_expect=226` ＋ `FP_MANIFEST_STEP_RC=0`（`tooth_sha16=be19edddf7f02797`）；`inputs_fp` 现取仍 `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`（与 `t58` 同值 ⇒ **覆盖面无变动**）。⚠️ **`225` 的归因（机器证，如实）**：`225` 是 **`t14` 期**读数、被我在 `t58` **引用而未现取** —— `git show 07c0a52b:verify-all.sh` 的第 `1195` 行**当时已是 `--expect 226`** ⇒ 正确答案在 `t58` 那一刻就是 **226**；故本条更正的教训是 **「凡引用计数必须现取，不许搬上一代的数」**（本仓既有口径），**不是**"覆盖面无同步扩面"。
  ⏪ **归因更正（`t60`，同日；主控裁定，逐字）**：上句把 `225` 的来源写成"`t14` 期读数"**不够准** —— **`225` 是主控在 `t58` 派单里逐字给出的过时读数**（派单原文：「…`inputs_fp` 现取 ／ **225 件**（以你现取为准，别抄我这行）」），**我在 `t58` 未复核即引用**（我侧责任 ＝ **未现取**；主控侧 ＝ 给了过时读数，他已自记为本轮**第 4 处**数字错）⇒ **现取 `226` 件**；本条与 `:261`（覆盖面现取 226 件）**一致**。
| §1 步数 | 50 步 | **55 步**（首行 `DECL 55 gen=#79`；覆盖面 `[42] --expect 225`） |
  ⏪ **dated 标注（`t62`，读时 `2026-09-28T12:46+08:00`）**：**本格内那个 `[42] --expect 225` 已被下方 `t60` dated 行取代 ⇒ 现值 ＝ `226`**（`verify-all.sh:1195` 现取即 `--expect 226`；原文一字未删）。
  ⏪ **dated 更正（`t60`，读时 `2026-09-28T12:40+08:00`；`225` 原文保留）**：**现取 ＝ 覆盖面 `226` 件** —— `verify-all.sh:1195` ＝ `run_step "FP-MANIFEST-TEETH" … --expect **226**`；牙现取 `FP_MANIFEST_TEETH=**PASS** reason=ok files_n=**226** files_n_uniq=226 blank_n=0 declared_expect=226` ＋ `FP_MANIFEST_STEP_RC=0`（`tooth_sha16=be19edddf7f02797`）；`inputs_fp` 现取仍 `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`（与 `t58` 同值 ⇒ **覆盖面无变动**）。⚠️ **`225` 的归因（机器证，如实）**：`225` 是 **`t14` 期**读数、被我在 `t58` **引用而未现取** —— `git show 07c0a52b:verify-all.sh` 的第 `1195` 行**当时已是 `--expect 226`** ⇒ 正确答案在 `t58` 那一刻就是 **226**；故本条更正的教训是 **「凡引用计数必须现取，不许搬上一代的数」**（本仓既有口径），**不是**"覆盖面无同步扩面"。
  ⏪ **归因更正（`t60`，同日；主控裁定，逐字）**：上句把 `225` 的来源写成"`t14` 期读数"**不够准** —— **`225` 是主控在 `t58` 派单里逐字给出的过时读数**（派单原文：「…`inputs_fp` 现取 ／ **225 件**（以你现取为准，别抄我这行）」），**我在 `t58` 未复核即引用**（我侧责任 ＝ **未现取**；主控侧 ＝ 给了过时读数，他已自记为本轮**第 4 处**数字错）⇒ **现取 `226` 件**；本条与 `:261`（覆盖面现取 226 件）**一致**。
| §1 推送 | `fd9a9a1886d25575…`（推送前） | **本地 `HEAD` == `ls-remote` == `81372408d2052b52…`；`porcelain=0`** |
  ⏪ **dated 更正（`t62`，读时 `2026-09-28T12:45+08:00`；`81372408…` 原文保留）**：**现取** ＝ 本地 `HEAD` ＝ `git ls-remote origin refs/heads/feat-Linux` ＝ **`14599de0a747ede9c7b9108b03a20c6139211ed3`**（本行写下时点之后仍可能被后续提交推进）；**`porcelain=0` 经本次现取复核为真**（非陈旧）。
| §1 放行标记 | 21 件 | **25 件**（`w56`…`w80`） |
  ⏪ **dated 复核（`t62`，读时 `2026-09-28T12:46+08:00`）**：**现取 `ls ~/w21-verify/w*-POST.done | wc -l` ＝ `25`** ⇒ 本格**非陈旧**（`w79-POST.done`／`w80-POST.done` 为末两枚）。
| §4 登记册 | `declared=155` | **`declared=214 route_ids=214`＋`DECLDRIFT=0`** |
  ⏪ **dated 更正（`t62`，读时 `2026-09-28T12:45+08:00`；`214` 原文保留）**：**现取 ＝ `DEFREG=PASS declared=215 route_ids=215`**（`DEFREG_DECL=n=215 route_ids=215`）＋ **`DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-`**。**算术（逐项有机器证）**：`215 = 213 + D-G179 + D-G180` —— `213` ＝ **`t58` 父提交 `81372408` 的 `ID` 行数**（现取 `git show 81372408d2052b52:build/MilBridge/tools/defect-registry-declared.tsv | grep -c '^ID'` ＝ **213**；现读 ＝ **215**）；`+D-G180` ＝ 本波按配号入册（`MSB4236`／fork 根 `Directory.Build.props`）；⚠️ **`+D-G179` 属「提及即声明」** —— 它**只在 `D-G180` 正文里被具名**（主控要求的"保留号"说明），`KD` 里**没有条目**，而 `--emit` 的 declared 集 ＝ **route 件里出现过的编号并集** ⇒ 被**自动声明**；现取 `BOOK_ENTRY_UNREQUIRED_MISSING n=16 ids=… D-G179 …（**已登记的缺口：可见、不判红**）`。⇒ 这与 `D-G179` 那条保留发现（`req` 恒真：同一趟既生成又据以判）是**同一根因的另一面**。
  ⏪ **归因补记（`t62`，同日；主控裁定逐字）**：**`214` 不是任何历史态** —— 现取 `t58` 父提交 `8137240` 的 `ID` 行数 ＝ **213**、`t58` 自身 ＝ **215**；`214` 的**唯一出处 ＝ 主控在 `t58` 契约验收里写的数字**（他后来用 `amend` 改成 `215`，而本表这一格**没跟着变**）⇒ **契约数被当成现值填表**。本条与 `225 件`（主控 `t58` 派单给的过时读数）、`HEAD 8137240…`（`t14` 时点值）**同族不同源**。
- **§6 未结清的账（现读补记）**：① 主控推送账里的五件（`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／`build/MilBridge/HANDOFF-NEXT.md`／`README.md`）**本会话已随 `t14`／`t57`／`t58` 的提交推上远端**（现取 `HEAD==ls-remote`）；② `app-local` 与「两处哨兵」两行的**读法不变**（哨兵**按内容判**：`WAVE=w80-freeze`／`BASELINE=#80`／`BASELINE_SHA16=b96d4312565a3c49`）；③ **九位产物不进 git**（`git ls-files` ＝ 0）⇒ 交接必须靠**构建**或 `~/w-keep-shims/`（本件 §下一波未闭项已写）。

## §7 七条命令重建存活态（**先跑这七条，再动手**）
```bash
R=/home/links-dev/netTest/GitProj/WPFOnLinux
# 1) 冻结世代与基线件
sed -n '9p' $R/docs/CURRENT-STATE.md
# 2) 九位（与 §1 逐位比对；pf 是环成员、只作现场值）
for f in build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so build/PresentationCore.Linux/bin/Release/PresentationCore.dll build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll src/WpfGfx.Linux.Native/bin/libwpfwin32.so build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll build/DirectWrite.Linux/wic-shim/libwpfwic.so build/shims/PresentationCore.HbTextLine.cs build/WindowsBase.Linux/bin/Debug/WindowsBase.dll build/DirectWriteForwarder.Linux/bin/Release/DirectWriteForwarder.dll; do sha256sum $R/$f | cut -c1-16; done
# 3) 登记册自洽
bash $R/build/MilBridge/tools/defect-registry-check.sh | tail -3
# 4) 输入指纹（覆盖面 205 件）—— 用已校准的复算器（**只借不改**）
bash ~/w153a/bin/infp.sh fp        # 期望 bb54413c…（#76 冻结值；每波现取）
bash ~/w153a/bin/infp.sh list | wc -l   # 期望 205
# 5) 步数与自检 / 放行标记与记录件
grep -c '^run_step "' $R/verify-all.sh; bash $R/build/MilBridge/tools/verify-all-step-check.sh | grep VERIFYALL_SELF
ls -l ~/w21-verify/w6*-POST.done ~/w21-verify/w6*-record.txt 2>/dev/null
# 6) 推送面（本地 vs 远端 vs 工作树）
git -C ~/netTest/GitProj/WPFOnLinux log --oneline -3; git -C ~/netTest/GitProj/WPFOnLinux ls-remote origin refs/heads/feat-Linux | cut -c1-16; git -C ~/netTest/GitProj/WPFOnLinux status --porcelain | wc -l
# 7) 重活槽与内存
flock -n ~/heavy.lock -c 'echo SLOT=FREE' || echo SLOT=HELD; free -m | awk 'NR==2{print "avail="$7"MB"}'
```
### ⏪ **dated · 机器值「现取生成契约」（`t10`／W1，读时 `2026-09-28T15:53:08+0800`；§1–§6 与 §7 原文**一字未删**）**

**背景**：侦察件 `build/MilBridge/P1-tail-scout.md`（`493808af2699c40a`）§B-11 现取点名——本件机器值是**手抄**的 ⇒ 每代必陈旧。**本波（W1）＝文档面**：逐格落「**一行现取生成命令** ＋ **现取值** ＋ **牙草案** ＋ **代价与落地位置**」。

**① 逐格对照（「现取值」全部由右侧命令现跑取得；「生成命令」即该格的唯一取数入口）**

| # | 处（内容锚） | 在册原文（逐字，留档） | 现取值 | 现取生成命令（一行） |
|---|---|---|---|---|
| 1 | §7-4 输入指纹 | `bash ~/w153a/bin/infp.sh fp        # 期望 bb54413c…（#76 冻结值；每波现取）` | `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f` | `bash ~/w153a/bin/infp.sh fp` |
| 2 | §7-4 覆盖面件数 | `bash ~/w153a/bin/infp.sh list \| wc -l   # 期望 205` | `226` | `bash ~/w153a/bin/infp.sh list \| wc -l` |
| 3 | §7-1 冻结世代 | `sed -n '9p' $R/docs/CURRENT-STATE.md` | `BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `sed -n '9p' docs/CURRENT-STATE.md` |
| 4 | §7-3 登记册自洽 | （§4 原写 `declared=155`；`t58` dated → `214`；`t62` dated → `215`） | `DEFREG=PASS declared=215 route_ids=215` | `bash build/MilBridge/tools/defect-registry-check.sh \| tail -1` |
| 5 | §7-5 步数 | `grep -c '^run_step "'` | `55`（首行声明 `# VERIFYALL-STEPS-DECL: 55 gen=#79`） | `grep -c '^run_step "' verify-all.sh` |
| 6 | §7-5 放行标记（**行内 glob 只覆盖 `w6*`**） | `ls -l ~/w21-verify/w6*-POST.done ~/w21-verify/w6*-record.txt 2>/dev/null` | `w6*-POST.done=10`／`w6*-record.txt=10`（**全量** `w*-POST.done=25`／`*record*=49`，最末 `w77-record.txt`） | `ls ~/w21-verify/w*-POST.done \| wc -l`；`ls ~/w21-verify/*record* \| tail -1` |
| 7 | §7-6 推送面 | `git ls-remote … feat-Linux \| cut -c1-16` | 本地 `HEAD` == `ls-remote` == `88ab841414b6b5e2` | `git log --oneline -1`；`git ls-remote origin refs/heads/feat-Linux \| cut -c1-16` |
| 8 | §2 在飞 | `**`#77`**（仪器波；五件 ＝ …）` | **无链在跑**（`#80` 已全链闭环；本件 `dated 对齐 · §2` 行已载） | `sed -n '9p' docs/CURRENT-STATE.md` ＋ `git status --porcelain` |
| 9 | §1 九位 | `#77` 九值（`pc 53fd7fffcdb30243` …） | 本件 `dated 对齐` 行已给 `#80` 九值；**权威路径表** ＝ `build/MilBridge/tools/wave-freeze-consistency-check.py:104-115` | §7-2 的 `for f in …; do sha256sum …` 循环（**取数口径必须按权威路径表**：`provider` 的 canon 路径 ＝ `build/DirectWrite.Linux/Provider/bin/Release/…`） |

**② 判据（会红的牙草案，逐字）**：新牙 `build/MilBridge/tools/handoff-machine-values-check.sh` 对①表逐格**现跑生成命令**并与**件内该格文本**比对 —— 不等 ⇒ `HANDOFF_MV=FAIL` 并**逐格点名**（`cell=#N anchor=… in-repo=… live=…`）；全等 ⇒ `HANDOFF_MV=PASS cells=9`。**反极性（必须真跑）**：人为把某一格改错一个字符 ⇒ **必红并点名该格**；**不许**「解析不了就跳过」。

**③ 代价与落地位置（逐件；本波**只落文档面**）**：新牙件 ⇒ **新文件**（`build/MilBridge/tools/…`）；入覆盖面 ⇒ `build/close-wave.sh` 的 `fp_inputs()` **+1 行**（覆盖面 `226 → 227`）⇒ `verify-all.sh` 的 `[42] --expect` **必须同趟改**；若接进门禁 ⇒ **步数 `55 → 56`**（四处声明 `DECL`／`STEP-NAMES`／口径句／预登记**同趟**改）。**⚠️ 这三处（新牙件／`close-wave.sh`／`verify-all.sh`）都不在 W1 写域 ⇒ 本波 `NOINFO(reason=落地件不在本波写域)`，牙面按侦察分波表归 W4**。

**④ 本波自证（B-10：入口／出口各一次）**：入口 `inputs_fp=abc76bd55f513b8d…`／覆盖面 `226`；出口同值（逐字读数见 `build/MilBridge/P1-w1-report.md`）⇒ 与 `#80` 冻结值的关系逐格如实写在报告内。


## §8 方法射程边界（**`t29` 补**；与 `docs/ROUTES.md`／缺陷册**同一术语、同一结论**）

- **射程边界（术语逐字）**：`-getProperty:`／`-getItem:Compile` 这类 **MSBuild 求值级**探针**结构上**覆盖不到**编译器级**输入。现场 ＝ 仓根 `.editorconfig`（`76,255 B`／sha16 `bf84100e2afbd3d2`），内含 `dotnet_diagnostic.<RULE>.severity = error` 一类规则（本件现取 **131** 行；在册文本写 **129** ⇒ 两数口径不同，本行**并列记**、不擅改历史文本）。
- **配对实验（唯一变量＝分析器策略）**：`dotnet build src/WpfGfx.Linux/WpfGfx.Linux.csproj -c Release -m:1 --nologo -v q` **加** `-p:EnableNETAnalyzers=false` ⇒ **0 个错误**；**不加** ⇒ **162 条 `error`**（出处 `build/MilBridge/P0-w77-report.md` §4b）。⇒ 策略的唯一来源是那份 `.editorconfig`，而它**不在 MSBuild 的属性/项模型里**。
- **等价成立的口径（不许过读）**：`t1` 的 88/88「求值级等价」（`-getProperty` 27 项 ＋ `-getItem:Compile`）证的是**两树在 MSBuild 求值模型上等价**，**不是**「有效构建输入逐位等价」；`.editorconfig` 属**编译器级**输入 ⇒ **在射程之外**。
- ⚠️ **这是方法的射程边界，不是执行失误**：换任何执行者、任何一趟，求值级探针**都看不见它**（那两个抽取域里根本没有这份文件）；把「求值面等价」写成「有效构建输入等价」是**对结果的过读**，而**方法本身**没有覆盖该输入的**结构**。
- **处置（已落，主控追认）**：`.editorconfig` 已 `git rm` —— 现取：仓根**无**该件、`git cat-file -e HEAD:.editorconfig` ⇒ `Not a valid object name`；原件 ＋ 回退指令存 `~/w-p0mig/quarantine-editorconfig/`（`cp -p` 回仓根 ＋ `git add` 即可逐字节回滚）；移出后整波 `失败步骤 0`。
- **如实划界（`NOINFO`）**：① 只证了**这一件**是本次 10 处失败的成因（配对实验），**不断言**不存在第二件「根级上游件」；② 移出的**只是分析器严重度**（`EnforceCodeStyleInBuild=false` 现读）⇒ **代码风格约束确已消失**，属**有意、逐字声明**的取舍。
- **同族口径（本节另一处，逐字）**：**"托管程序集的哈希是路径承载体；凡跨树位置比较产物哈希，先问『它是在哪个树里产出的』。"**（`#77` 五位位移 ＝ 路径承载体，**不是产品回归**；缺陷册已立**同条目**，**条目号＝待配号**。）
- **出处**：`build/MilBridge/P0-w77-report.md`（§4b／§4c／§4d）｜`build/MilBridge/V77b-rootprops-tooth-verify.md`（§5／§6-F6）｜`docs/WAVE77-PREREGISTRATION.md`（§(b)）。

## 【2026-09-27 · `t21`（waveman）】`#78` 四组成对读数已真跑 ⇒ 见 `P0-w78-report.md` §8–§10
- `TASK-0752`：三臂两极化（`fc60c34d51fd9247` 242/3808 ／ **新件 `8857b251e74851d2`** 357/3923 ／ `efb087b5c7c33eb2` 0/3629）＋ `DIAG=0/1` 两档；**原位跑器 `~/w181a/w7x/bin/leg.sh` 的 `absent` 臂语义反转**（指向活树已装符号件）已在副本修正，原件未动。
- `TASK-0753`：`D-G147` 成对（正向三腿 `G147=PASS`：`fallback-screen`／`net-workarea`／`fallback-malformed`；反向三腿 `G147=FAIL reason=no-declared-source(silent-identity)`／`rcWork!=_NET_WORKAREA`）。
- `TASK-0754`：`DISPLAY_LEASE_GATE=PASS static=3/3 dynamic=11/11 examined=14`；`X-CENSUS` **链前基线缺 ⇒ `NOINFO reason=pre-chain-baseline-absent`**；另报两处仪器口径缺口（`display-lease.sh:413` `local` 在函数外；`pool-exhausted` 应为 `pool-out-of-whitelist`）。
- `TASK-0755`：`PROTO_ATTR_GATE=PASS examined=18 posctl=2/2`；`sock_id=present` 逐行在位；「符号级 hook 恒瞎」复证＝`SYM_ONLY=never-sufficient` ∧ `sym_call=none`。
- 两趟差异机器分类（两域分列）＋ `ENV-CLASS` 合格线见 §10。
- 台账 `appbar-startup-ledger.tsv` **未加行**（`verify-all.sh:1188 --expect-legs 6` 与行数耦合；加行须同趟改常数）。

---
### 【dated 更正 · 2026-09-28T01:59:07+08:00（t36）】三处更正 ＋ `X-CENSUS` 手写判词关账（`D-G168`）
**① 落仓 sha16 已失效（原文一字不删）**：本文曾称 `948b1f495e6701e1`／34236 B／228 行 —— **现取**（2026-09-28T01:59:07+08:00）＝ **`7131ffad2ebac068`／64963 B／432 行**（因 `t25` 在该件上追加所致）。凡引用本报告 sha16 处，一律以**带读取时刻的现读**为准。
**② §8 的「根因＝`GENS` 键表不含 `provider`」与现件不符**：该缺口**已由 `TASK-0745`／`D-G166` 落地补上** —— `w27-freeze.py` 的 `_FORM_NINE` **含 `provider`**（逐键 vs 现取值对拍；`prev_*` 取**哨兵**而非九位行）；`#79` 冻结时 `BLOCKVALUE=PASS keys=9` 即其现场。
**③ `+115` 归因误导（逐字节证）**：`absent` 与 `baseold` 的输出差**不是**"件身份"不可归因 —— 差恰是一行 `[G147_WORKAREA]`（**114 B，含 LF**）；且 `absent` 比 `baseold` **多 3 个 `wpf_x11_workarea_*` 符号**（553 vs 550）⇒ **单变量对只有 `baseold↔ret0`**（同为无/有该三符号之外的差异面），其余配对都是**多变量**，不得当作单变量证据。
**④ `X-CENSUS` 那句 `pre-chain-baseline-absent` 是手写判词**：(a) 与同两趟日志里自引的 **`X_CENSUS=PASS leaks=0 new_orphan_sock=0 base_live=0 now_live=1 base_socks=2 now_socks=3`** 矛盾；(b) 该 reason **不在器具词表**（`xvfb-census-check.sh` 只有 `baseline-absent`／`baseline-format-unknown`／`orphan-socket-residue`／`ps-empty-or-unreadable`／`snapshot-unwritable`／`snapshot-with-ps-file`／`sock-dir-absent`）⇒ **不是器具产出**；登记 **`D-G168`「判词必须来自器具的词表；手写 `reason=` 即假账」**；(c) 处方「链首补快照」**早已实现**（`verify-all.sh:468-473`）。**真缺口（具名）**：**跨整条 `close-wave` 链无基线** —— `grep -c snapshot build/close-wave.sh` = **0**（读取时刻 2026-09-28T01:59:07+08:00）。

---

## §0 队长起手页（**仓内载体**；`t54` 建）

> ⚠️ **位置说明（先读这句）**：本件纪律是"**只增不改**"⇒ 本节与下面两节一律**追加在文件末尾**、**没有**插到文件头（那一处插入会让 `t14` 的推送与成对重测多一笔）。**读法＝从上往下读到尾**；三节的落仓时刻都是 `2026-09-28T12:2x–12:3x+08:00`（`#80` 冻结 `b96d4312565a3c49` 之后、`t14` 推送之前）。

- **触发语（逐字）**：「**按 `~/wcaptain-audit/CAPTAIN-PREAMBLE.md` 起手**」。
- **该页（仓外件，只引用、不改）现取**：`98afa223eb7a18e7`／**29 行**／2,729 B（读取时刻 `2026-09-28T12:22:32+08:00`）。照 `t29`／`t33` 先例：**仓外件只引用**。
- **三件开口动作（逐字照该页 §0 三条）**：
  1. `agent_teams_status`（**谁在跑、谁卡着**）＋ `tail -60 ~/wcaptain-audit/w78-block-audit.md`（**活账尾**）；
  2. 读绑定规则 `~/wcaptain-audit/BINDING-RULES.md`（**条目清单 ＋ 哪几条带牙 `[牙]`**）⇒ **仓内载体＝本件下一节**；
  3. **量资源**：`awk '/^MemAvailable:/{printf "%d MB\n",$2/1024}' /proc/meminfo`｜`awk '/^SwapFree:/{print $2/1024" MB"}' /proc/meminfo`｜`df -h ~ | tail -1`。
- **起手页 §1 的硬纪律里，与本件直接相关的两条（逐字）**：「每个结论 = **artifact ＋ 字段 ＋ sha16 ＋ 读取时刻**；`NOINFO` **既不算绿也不算红**」「一次**只一个写者**；写前 `stat -c %h`、`temp＋rename`、备份取在任何写之前」。
- **为什么需要这一节（理由句，逐字）**：「本机长期记忆是**查询命中的摘录**（不是全量），中间推理与工具轨迹不保真 ⇒ **文件才是记忆**。」
  ⇒ **推论**：凡要跨会话活着的东西**必须落到仓内件**；仓外的 `~/wcaptain-audit/*` 是队长的**私有记忆**（该页 §2 的"记忆文件地图"自己写着「**都在仓外，不动 `inputs_fp`**」），**仓内**载体＝本件本节 ＋ 下一节（绑定规则）＋ `P0-w80-report.md`／`docs/ROUTES.md` 等**在册**件。
- **⚠️ 该页 §3「当前波」的时效口径（现取更正，只增不改）**：该页 §3 写的是 `#79` 时代的现场（预登记 `docs/WAVE80-PREREGISTRATION.md`、基线取 `# RE-FROZEN #79` 块）。**现取**：`docs/CURRENT-STATE.md:9` = `BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49`；块件 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 现读 **`b96d4312565a3c49`** ⇒ 该页 §3 **必先现取再引用**（该页自己写着"**起手时以仓内现取为准，勿凭本页过期值**"）。

## §绑定规则·跨会话有效（18 条：**8 条有牙 ＋ 1 条部分牙 ＋ 9 条仅成文**）

> **原件（仓外，只引用不改）**：`~/wcaptain-audit/BINDING-RULES.md` = **`22a3a65ec9137918`**／22 行／2,520 B（读取时刻 `2026-09-28T12:22:32+08:00`）⇒ 本节**逐条按现取重算**（不凭印象）。
> **口径（照原件）**：**[牙]** ＝ 门禁/链**每趟读它** ⇒ 跨会话自然生效；**[文]** ＝ 仅成文 ⇒ **必须靠读件**。
> ⚠️ **一条对全节成立的边界**：**有牙 ≠ 牙在仓内** —— 本节的 8 条牙里有 **4 条牙落在仓外**（`~/w79c/bin/*.sh`，见 A 表"牙位置"列）⇒ 换台机器/清车道目录 ⇒ 牙**连同规则一起消失**（建议见 D 表）。

### A. 有牙的 8 条（**牙路径 ＋ 现取 `sha16` ＋ 判据行原文**）

| # | 规则（逐字） | 牙（路径 ／ 现取 `sha16` ／ 位置） | 判据行原文（行号现取） |
|---|---|---|---|
| 1 | **stop 真值只看标记里的 `baseline_sha16`（不看 `rc`）** | `~/w79c/bin/w79-freeze2end.sh` ＝ **`a9f0de4cfc39a0b2`**（**仓外**） | `:31` `_bs="$(sha256sum $R/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md \|cut -c1-16)"; [ -n "$_bs" ] && echo "baseline_sha16=$_bs" \|\| echo "baseline_sha16=none(baseline-unreadable)"`；**"不看 rc"的机器证**＝`:19` 停手按**内容**判：`grep -aq '基线已重冻为 #79' $L/w79-freeze.log \|\| { echo "FREEZE_FAILED ⇒ 停手（**不落 POST.done**）"; echo "STOP=freeze-red"; exit 8; }` |
| 2 | **标记任何字段不许为空 ⇒ 写 `none(<reason>)`** | 同上（`push_rc`／`freeze_last`／`baseline_sha16`） | `:34` 注释逐字「**标记里任何字段都不许为空**；取不到 ⇒ `none(<reason>)`」＋三条出口：`:31`／`:32` `freeze_last=none(no-freeze-log)`／`:36` `push_rc=none(no-PUSH_RC-in-output)` |
| 3 | **测试钩子必须排在"清理/写标记"之前** | 同上（`MARKTEST` 包住真跑块） | `:7`–`:9`（`MARKTEST=0` → `--marktest <outfile> <markfile>` 解析 → `if [ "$MARKTEST" = 0 ]`）**早于** `:10` `rm -f "$MARK"`；且 `:6` 注释逐字「**跳过①②③④，只跑标记块**（块本体一字不改，避免"第二实现"）」 |
| 4 | **覆盖面变 ⇒ `--expect` 同趟改，且"先声明后事实"** | `build/MilBridge/tools/fp-manifest-step.sh` ＝ **`db4a2d9856534aba`**（**仓内**）＋ 判据端 `build/MilBridge/tools/fp-manifest-teeth-check.sh` ＝ **`be19edddf7f02797`**（**仓内**） | `fp-manifest-step.sh:78` `FP_MANIFEST_STEP=NOINFO reason=expect-not-a-number expect=$EXPECT`｜`:150` `FP_MANIFEST_STEP=FAIL reason=sha256sum-stderr-nonempty …`｜`:172` `FP_MANIFEST_STEP_RC=…`；**`delta` 判据行**＝`fp-manifest-teeth-check.sh:175` `FP_MANIFEST_TEETH=FAIL reason=files-n-mismatch files_n=$files_n expect=$expect delta=$(( … ))` |
| 5 | **标记存在 ≠ 链成功；"远端事实"只许 `git ls-remote` 现取** | `~/w79c/bin/w79-push.sh` ＝ **`fb46d69e6a5cd78a`**（**仓外**）＋ 驱动标记块（同 #1 的牙） | `:205` `REM=$(git ls-remote origin refs/heads/feat-Linux \| cut -f1); LOC=$(git rev-parse HEAD)`｜`:213` `REMOTE_AFTER=$(git ls-remote origin refs/heads/feat-Linux \| cut -f1)`｜`:222`–`:224`（**按当刻远端 tip 判祖先**，不用本地 `origin/*` 缓存） |
| 7 | **仓内路径 ≠ 仓内容 ⇒ 判据面按 `git ls-files`／显式 `skipdirs` 划界** | `build/MilBridge/tools/nul-bytes-check.sh` ＝ **`2902c14fa1081a5c`**（**仓内**） | `:107` 现场逐字「它是**仓内路径、但非仓内容** —— `.git/info/exclude:8` 排除它、`git ls-files \| grep -c agent-teams` **= 0**」；`:111` 口径句逐字「`git ls-files`（或显式 `skipdirs`）划界」；实现位 `:152/:155/:207/:277`（`NULB_SKIPDIR_OUT`／`skipdir_dirs`） |
| 8 | **"两个输入"做比较的工具必须用可区分标识命名中间产物** | `~/w79c/bin/diffclass.sh` ＝ **`0b9d9c41e983a930`**（**仓外**） | `:28`–`:29` 按**输入绝对路径的 `sha16`** 命名（`KEY_A`／`KEY_B`）⇒ `:46`–`:47` `EVIDENCE_A=… sha16=… lines=…`；**闸一** `:32` `NOINFO reason=evidence-path-collision detail=A 与 B 解析到**同一绝对路径**…`；**闸二** `:36`–`:37` `同 basename($BA) ∧ 内容不同 ⇒ 拒绝判定` |
| 9 | **route 件（`KD` 等）编辑必须批量在 `--emit` 之前，之后不许再动** | `build/MilBridge/tools/defect-registry-check.sh` ＝ **`c2d0773e5561a9d1`**（**仓内**） | `:251` `DEFREG_DECLDRIFT=$drift changed-route-files-since-DECL-GEN keys=$dkeys`｜`:252` `DEFREG_DECLDRIFT_KEYS=%s  # 机读差集键行（零漂移给 -；`?` = 声明件里读不到锚行）` |

### B. 部分牙 1 条

| # | 规则（逐字） | 现状（现取） | 缺口（逐字） |
|---|---|---|---|
| 15 | **停止线 `avail<2000MB ∨ swapfree<512MB`；每批 `/proc/meminfo`** | `~/heavy-slot.sh`＝**`963987607f95d591`**（口径行 `:92` `min_avail="${HEAVY_MINAVAIL:-1200}"`／`:93` `avail_wait="${HEAVY_AVAILWAIT:-600}"`；`HEAVYSLOT=NOINFO reason=low-memory` 打 `:16`）＋ 队长页 `:12` 逐字「重活一律走槽：`bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`；停手线 `MemAvailable<2000MB ∨ SwapFree<512MB`」 | 槽**只挡内存、不挡 swap**（原件自己写 `[部分牙]`）；`--min-avail` 默认 **1200** 与停手线 **2000** **不是同一个数** ⇒ 两条口径并存、**没有任何一处同时判两者** |

### C. 仅成文的 9 条（**出处 ＝ 件 ＋ 行号 ＋ 判词**；＋ **谁读它**）

| # | 规则（逐字／缩写） | 出处（件 ＋ 行号 ＋ 判词，现取） | 谁读它 |
|---|---|---|---|
| 6 | **`cmp` 相同 ≠ 当代（哨兵按内容判 `BASELINE`／`BASELINE_SHA16`）** | `build/MilBridge/T24-report.md`（**`23f30c6cc0cdcd53`**）`:41`「**附加独立证（两哨兵）**：`/tmp/bridge-frozen.flag` 的九键 + `BASELINE=#79` + `BASELINE_SHA16=901619543b3d913b` …」＋ `:126`「两哨兵 `cmp` ⇒ **IDENTICAL**」 | 收尾车道 ＋ 复验者（`t24`／`t40` 验收都是这么读的）；**队长** |
| 10 | **冻结与哨兵必须是"最后两个动作"（九位是重建驱动）** | `build/MilBridge/P0-w80-report.md`（**`3cc9becdc15f2211`**）`:60` §6 标题「两条结构性结论…」＋ `:95` §10-1 逐字「…＋"因此冻结与哨兵必须是最后两个动作"…」 | 收尾车道（`t46` 族）＋ 队长 |
| 11 | **计数类/点读指纹必须带读取时刻；判"某件不存在"必须给不经 `tail`／`head` 截断的原文** | `build/MilBridge/P0-mvp-pts-report.md`（**`d79a0c009515b3c4`**）`:82`「`> 读取时刻：**2026-09-28T09:5x+08:00**（各条另注）」＋ `:136`／`:147`（两处 `inputs_fp` 都带时刻） | **所有写报告的车道**；队长（据此字段判账） |
| 12 | **关系式/区间类数字：转述前自己算、或标"未复核"** | 应用实例 `build/MilBridge/VPts-t52-review.md`（**`fae0b816b04dfe58`**）`:85`「复述位（我自己的口径＝**行**，读时 `09:48:45`）…」＋ `:86` 逐字「⚠️ 口径差异如实记：`t52` 自报"**7 处复述位**"，我按**行**数得 **9 行／4 件**」（**主控两次同族错**在**仓外**审计件 ⇒ 该半 `NOINFO`） | 复验者 ＋ 队长 |
| 13 | **落仓一律 `temp+rename`；反极性腿一律在副本树上跑** | `build/MilBridge/HANDOFF-NEXT.md:54`（本件 §5 纪律 6 逐字「**写盘 temp + `rename`**；改动前 `cp -p` 备份 —— ⚠️ **备份必须取在"任何写之前"**」）＋ 实例 `build/MilBridge/P0-teeth-close-report.md`（`t31` 三条腿全在副本树、真树两件 `sha16` 为落仓态） | **所有写者**（含本条自己：本节就是 `temp+rename` 落的） |
| 14 | **静默阈值 30 min ⇒ 存活检查 ⇒ 仍静默 ⇒ `reassign_task` 重试** | **仓外**（队长规程／派单件）⇒ `NOINFO(reason=载体不在仓内；仓内只检索到同形词 `W47A-report.md:37` 的"存活检查"＝另一种含义)` | **队长**（队员只受其后果影响） |
| 16 | **成员按契约对齐必须用存储契约文本；同句拒两次即停手报队长** | **仓外**（契约文本存于团队状态，本会话只读）⇒ `NOINFO(reason=载体不在仓内)` | 队长 ＋ 成员（对齐时） |
| 17 | **派单 `verify` 一律给可重跑、`rc=0` 的单行命令原文** | **仓外**（任务契约的 `Verify` 字段）⇒ `NOINFO(reason=载体不在仓内)` | 队长（写）／成员（执行） |
| 18 | **事实与账必须连 `artifact ＋ field ＋ sha16 ＋ 读取时刻`；缺数据写 `NOINFO`，不许猜** | `~/wcaptain-audit/CAPTAIN-PREAMBLE.md:11`（逐字）＋ 本件 `:88`（纪律 40「**报数一律现算，不引用前一次列印**」） | **全体**（本仓纪律，每个任务收口都用它） |

### D. 待升牙候选（3 条；**升牙＝把"靠读件"变成"每趟有人读它"**）

1. **「撤/删任何路径前，全仓 `grep` 该路径的读取者（含 `*.cs`、探针源、牙）」** —— 现出处 `~/wcaptain-audit/CAPTAIN-PREAMBLE.md:14`（**仓外**，`[文]`）。**升牙理由（本波现成证据）**：`build/MilBridge/tools/pkg-src-retiredpath-check.sh`（`d54a5a14c1934bac`）的 `tree` 面**只扫 `*.sh/*.py/*.c/*.h`、不扫 `*.cs`** ⇒ 现取**九件 `.cs` 带死根而守卫全绿**（见下一节 N4）⇒ 这条规则**今天恰恰在它最需要的地方没有牙**。
2. **「陈述前必须现取核对口径（波次/同体制/CI 都算）；数字与字段名逐字抄」** —— 现出处 `~/wcaptain-audit/CAPTAIN-PREAMBLE.md:15`（**仓外**，`[文]`）。**升牙理由**：本仓已有同族的**在册**先例（口径类缺陷成族）⇒ 有现成的形态可抄：给"口径句"配**机读读者**（现成实现见 `build/MilBridge/tools/prereg-four-requirements-check.sh` 与 `defect-registry-check.sh` 的"机读行 + 逐条上屏"两形态）。
3. **「标记里任何字段不许为空 ⇒ 写 `none(<reason>)`」** —— 出处 `~/wcaptain-audit/BINDING-RULES.md:6`。**⚠️ 它其实已经有牙，但牙在仓外**：`~/w79c/bin/w79-freeze2end.sh`（`a9f0de4cfc39a0b2`）`:31/:32/:36`。**升牙＝把它搬进仓内**（否则清一次车道目录 ⇒ 规则与牙一起消失；这与 A 表顶部那条边界是同一件事）。

## §下一波未闭项（具名，不许静默）

> **本节由 `t54` 建（9 条），`t14` 在其后**追加**（**别另起一套**：本节就是唯一清单；追加以"§下一波未闭项（续）"或直接在本节末尾加条）。
> **每条都给"件 ＋ 字段 ＋ `sha16` ＋ 现取时刻"级证据指针**；凡取不到的格一律 `NOINFO` 并具名原因。
> **现取时刻（本节各行另注）**：`2026-09-28T12:22:32–12:23:52+08:00`（`#80` 冻结 `b96d4312565a3c49` 之后、`t14` 推送之前）。

1. **`D-G176` 预留（九位跨同一输入两次整波不复现）** —— 证据件 `build/MilBridge/P0-w80-report.md`（**`3cc9becdc15f2211`**／104 行）`:60`（§6 标题）＋ `:95`（§10-1 逐字）。口径：**本波不登记号值**（写进 route 件会让 `DEFREG=FAIL reason=undeclared-id-in-route`）⇒ **下一波随登记批一起落**；证据指针＝该报告 §6 的两个时刻读数（`provider` 三时刻 `759ac1686e5ef87d`／`8cb1b50619f4c133`／`7e8a217b4165a6b9`）。
2. **`D-G178`（候选，主控仪器缺陷）＋ 同族在车道侧** —— `P0-w80-report.md:82`（§8 标题）＋ `:96`（§10-2 逐字「`w27-freeze.py` 入口锚严格行首 vs 出口锚容忍装饰 ⇒ 冻后 `--prev-check-only` 假红」）。**车道侧同族**：推牙取块按 `^# RE-FROZEN #79` **严格行首** ⇒ 冻后上一代块头被加装饰 ⇒ **取空拦停**（提交已生成、**零部分推送**），已按同族修法改成"**取全文第一处** `` `inputs_fp` `` **声明**"（判据语义不变）；载体＝`~/w79c/bin/w79-push.sh`（现取 `fb46d69e6a5cd78a`，**仓外**）⇒ **下一波把它搬进仓内**并把锚改成内容锚。
3. **三条死根面（`unused`／`unused`／`used` ＋ 死根面 `NOINFO`）** —— `P0-w80-report.md:86`（§9 表）。现取逐件：
   - `build/MilBridge/tests/T2eLineHeight/Program.cs`（**`26abfba8bbd1ac17`**）`:24` `private const string Root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";` ⇒ **`unused`**（判据：`grep -c 'T2e' verify-all.sh` = **0**，报告 §9 逐字"无运行期调用者"）；
   - `build/MilBridge/tests/PcLineOracle/Program.cs`（**`a787a9db23c3302c`**）`:171` 同形常量 ⇒ **`unused`**；
   - `build/MilBridge/tests/CoverageProbe/Program.cs`（**`a6d0352b86467111`**）`:88` 同形常量（另 `:1028`／`:1159`／`:1240` 局部字面量）⇒ **`used`**（三支 tab 臂宿主：`retake-arms-w23.sh:109-128`）⇒ **常量本身 `unused`** ＋ **死根面 `NOINFO(臂日志零签名)`**（**必须查清**，`NOINFO` 不许当绿）。
   - **本波已修的一件（前后 `sha16`）**：`build/MilBridge/tests/HbTextLineParity/Program.cs:42` ＝ `149dd986a642fdfc`（**前值引自 `t46` 的 `P0-w80-report.md §3`／本件未独立复算该前值**）→ **`dda989bb024d20e6`**（**现取**；`numstat 1 1`，死根签名 6→**0**）。
   - **另六件＝字面残留（本波只审不改，逐件给行号与原文摘录，结论 `NOINFO(reason=未做活/死判定)`）**：`tests/FrameProbe/Program.cs`（`503e6ebd86d70303`）`:309`｜`tests/ResolverGuardProbe/Program.cs`（`76caccc4693bf4a1`）`:40`｜`tests/LsProbe/Program.cs`（`b8dba8fbbc05a327`）`:9`｜`tests/BboxProbe/Program.cs`（`c06f605002cb5d48`）`:23`｜`tests/IcuBreakParity/Program.cs`（`1b2815e197638a23`）`:62`｜`DirectWrite.Linux/WicSeamProbe/Program.cs`（`08f7bd96d1c33f22`）`:15`（逐行原文见本次落仓的车道证据件，或 `grep -n 'wpf-linux-20260906' <件>` 现取）。
4. **守卫射程洞（本波发现，下一波登记；本波不改牙）** —— `build/MilBridge/tools/pkg-src-retiredpath-check.sh`（**`d54a5a14c1934bac`**）`:107`–`:110` 的 `tree` 面逐字：`find "$ROOT" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \)` ＋ `find "$ROOT/build" "$ROOT/tests" "$ROOT/src" -type f \( -name '*.sh' -o -name '*.py' -o -name '*.c' -o -name '*.h' \)` ⇒ **不扫 `*.cs`** ⇒ 现取**十件带死根而守卫全绿**（九件现存 ＋ `HbTextLineParity` 本波已修）⇒ **射程洞如实记**（与 D 表候选 1 同源）。
5. **仪器注释陈旧（`provider` 两值重复）** —— `~/w21-verify/w27-freeze.py`（**`7e3d0fecefa9f20c`**）`:443`–`:444` 现取逐字：`:443` `# （照 `#79` 先例：那两格取**哨兵**的现取值。本代另有"重建驱动"事实：`#79` 块声明 `759ac1686e5ef87d`，`／`:444` `#  \`Provider\` 产物先后被重建为 \`8cb1b50619f4c133\`（02:23:33）与 \`8cb1b50619f4c133\` ⇒ 三个时刻都写进 \`P0-w80-report.md\` §六）` ⇒ **同一值连写两次**（应为 `8cb1b…` 与第三个值 `7e8a217b4165a6b9` 或注明"第二次同值"）⇒ **注释与事实不符**，下一波改准（该件**仓外**，队长写域）。
6. **`FILES` 累积语义** —— `P0-w80-report.md:100`（§10-6 逐字「`~/w79c/bin/w79-push.sh` 的清单是**累积**的（本笔 **121 件** vs 本笔入笔 **61 件**）」）；同件 `:78`（§7）现取同形读数。⇒ 建议下一波改"**每波一份清单 ＋ 逐件归宿**"。
7. **`arm-logs` 硬链接形态的两种处置** —— `P0-w80-report.md:101`（§10-7）＋ 现场 `:25`／`:26`（§2-3：`repo-alias` 红＝`~/wfp-runs/arms23/` 的 5 个 `nlink=2` 孪生；`arm-logs/README.md` 说该目录 `*.log`"**是硬链接、不是拷贝**"）⇒ 两案：（甲）删输出侧孪生（本波做法，已达 `ALIAS=PASS`）／（乙）把该树在 `repo-alias-allow.tsv` **声明**掉（**上限**待定）⇒ **下一波择一并写清代价**。
8. **`PTS-PAGES` 的"零证据力"射程句仍只在报告里、未入判据件自身** —— 句子载体＝`build/MilBridge/P0-mvp-pts-report.md`（**`d79a0c009515b3c4`**）`:178` 逐字「门禁步 `PTS-PAGES`（`verify-all.sh:1173`，默认读本目录）**只读 `leg_*.env` 的列，不读 `entry=`** ⇒ **它的绿对"前沿位移"零证据力**」；**判据件** `build/MilBridge/tools/pts-pages-guard.sh`（**`bfa6414eb7104f85`**）现取**不含该句**（`grep -c '零证据力'` = **0**）⇒ 下一波把该口径句搬进判据件自身（本仓"口径搬进判据件"的既有做法见 `TASK-0741`）。
   ⚠️ **本件现取的三处更正（两口径并列，供下一波一次改准）**：① 该句里引的 `verify-all.sh:1173` **现取是 `fi`**；`run_step "PTS-PAGES"` 的真实行号 ＝ **`verify-all.sh:1174`**（`run_step "PTS-PAGES" bash build/MilBridge/tools/pts-pages-guard.sh --legs "$PTS_EVIDENCE_DIR"`）⇒ **引行号必须现取**。② 该句说的"不读 `entry=`"**成立**：G10 实现（`pts-pages-guard.sh:180`–`:190`）读的是 `leg_*.env` 里 `NAMED … native_gap=<计数>` **计数**，不读前沿名。③ **但件头 `pts-pages-guard.sh:22` 的描述里具名了旧前沿**：逐字 `#   G10 至少一条 native \`PTS_GAP entry=CreateInstalledObjectsInfo\`           否 ⇒ FAIL` —— 而现前沿是 **`LoCreateContext`**（`t52`/`t55` 的具名行证据）⇒ **描述与实现都不回答"前沿是谁"**，且描述里的具名还是**旧名** ⇒ 下一波同趟做：把零证据力口径句搬进件 ＋ 修正 G10 描述的具名。
9. **`session_inner.sh:18` 的显示号缺占用断言** —— `build/MilBridge/tests/PtsPagesProbe/session_inner.sh`（**`f687ad65fd05f6e2`**）`:18` 现取逐字 `D="${W67_DISPLAY:-:237}"` ⇒ **默认值没有"该号是否已被占用"的断言**（本波已知陷阱、**故意缓**）⇒ 下一波加占用探测（或改成"现取空闲号"）。
10. **`inputs_fp` 相对 `#80` 冻结值的漂移 ＝ 0（本批零位移，具名事实）** —— 现取 `2026-09-28T12:30:21+08:00`：`bash ~/w-p0mig/bin/infp-n.sh fp`（只读抽取 `build/close-wave.sh` 的 `fp_inputs()`，不执行收割脚本）＝ **`abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`** ＝ `#80` 冻结值（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:69`，该件现取 `sha16=b96d4312565a3c49`）**逐位相同**（同趟 `EXTRACT_SELFSAME=yes`、`FILES_N=226` ＝ `build/MilBridge/P0-w80-report.md:77` 的 `INFP_COUNT_RULER` 常数 `226`）；**机制（现取，双向）**：本批 `t57` 的三件 —— `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`3b9abdfd0c619391`）／`build/MilBridge/tools/defect-registry-declared.tsv`（`6f1a3f99a922a6f1`）／`build/MilBridge/HANDOFF-NEXT.md`（本节自身）—— **一件都不在 `fp_inputs()` 覆盖面内**：逐件 `infp-n.sh list` 命中 ＝ `0`／`0`／`0`，且 `fp_inputs()` 的显式白名单与 `find` 链里逐字 `grep` 这三件 ＝ **0 命中** ⇒ 本批对 `inputs_fp` **机械零影响**（不是"漂移被掩盖"，是覆盖面不含；覆盖面现取 **226 件**，`#80` 冻后零改动）。⚠️ **如实划界**：本批**没有**把 `inputs_fp` 推离冻值，因此**无位移需放行**；`#80` 之后其他车道的改件（`docs/CURRENT-STATE.md` `13077b52c938f8af` 等）亦全在覆盖面外（`fp_inputs()` 现取不认它们）。

11. **「`§1–§6` 的机器值是**手抄**的 ⇒ 每代必陈旧」**（`t62` 建条；编号按现取清点：本节原有 1–10，本条 ＝ **第 11**）—— **本波一次出现三例，同族不同源**：① `225 件`（**主控 `t58` 派单里给的过时读数**，我未复核即引用）；② `declared=214`（**主控 `t58` 契约里的验收数字**被当成现值填表；现取 `215`）；③ `HEAD 8137240…`（**`t14` 时点值**；现取 HEAD ＝ `14599de0a747ede9c7b9108b03a20c6139211ed3`）。⇒ **下一波待办**：把该节的机器值改为**由脚本现取生成**（或至少加一颗牙，判「该节现值格 vs 现场」不一致即红）；**定性**：与 `D-G140`（对全量语料的断言会过期）／`D-G132`（声明没有机读读者）**同族但判词不同** —— 本条是**"人手抄写的机器值"**；**证据指针**：本件 `:128`／`:131`／`:134`／`:136` 四处的 `t60`／`t62` dated 行（各自带现取时刻与现取值）；**边界**：本波**只补 dated 更正**，**未**改成脚本生成、**未**新增牙（不改判据）。

12. **`D-G179` 候选：声明表 `req` 列在**自动路径**上恒真（`verifier` 于 `t15` 两侧真跑；真树只读、沙箱 `~/w31x/dg179/`；工具 `build/MilBridge/tools/defect-registry-check.sh` 现取 `c2d0773e5561a9d1`）** —— ① **正侧（恒真）**：KD 副本里对既有编号 `D-G152`（原 `req=AB`、KD 命中 `0`）**只写一句提及**⇒ `--emit` 后该行自动变 `req=KD,AB present=KD,AB`，同趟校验仍 `DEFREG=PASS declared=215 route_ids=215`（`rc=0`）⇒ **"生成 `req`" 与 "拿 `req` 判红" 是同一个出现集**（`emit_decl()` 第 134 行的 `req` ＝ `{KD,CS,HO,AB}` 里的出现集）⇒ 只要编号在任一 route 件出现过，规则③就不可能红。② **反侧（人工改表仍有牙）**：把副本表里 `D-G152` 的 `req` 手工加宽到 `HO`（该件命中 `0`）⇒ `DEFREG=FAIL reason=declared-id-missing-in-route` ＋ 逐条点名 `D-G152 req=HO MISSING-IN=HO route=…/handoff.md`（`rc=1`）。③ **我另加的两条腿（供定号取舍）**：`req` **收窄**成子集 ⇒ `DEFREG=PASS`（**欠报不可见**）；`req` 塞非 route 键（`KRJ`）⇒ `DEFREG=NOINFO reason=decl-unparsable`（`rc=2`，三态未坏）。现取（`2026-09-28T12:56:56–12:57:15`）：真树 `DEFREG=PASS declared=215 route_ids=215`／`DEFREG_DECLDRIFT=0 keys=-`。⇒ **下一波**：登记为正式条目（`req` 语义要么改成"**要求集**"，要么校验侧改判"出现集之外的空集"）。
13. **哨兵同名字段 `FP` ＝ `BRIDGE_SRC_FP`，**不是** `inputs_fp`（哨兵里没有 `inputs_fp` 这一格）⇒ 对拍必须分口径（`verifier` 于 `t15` 顶出；本波差点因此造出假红）** —— 三件证据指针：① 哨兵原文行 `/tmp/bridge-frozen.flag:2`（`FP=d697b1e10ff48881`）与镜像件同值；② 定义链 `build/close-wave.sh`（现取 `f9a2ee3ee35baff8`）`:602` `FP_NOW2="$(bash build/bridge-src-fp.sh …)"` → `:686` `printf 'FP=%s\n' "$FP_NOW2"`；③ 我现取（`2026-09-28T12:40:15`／`12:55:11`）`bash build/bridge-src-fp.sh` ⇒ `BRIDGE_SRC_FP=d697b1e10ff48881 BRIDGE_SRC_N=78`。而 226 件 `inputs_fp` 现取（`~/w153a/bin/infp.sh fp`，`2026-09-28T12:39:35`／`12:41:09`／`13:0x`）＝ `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`（＝ `GENS['#80']['infp']`，`~/w21-verify/w27-freeze.py:448`）⇒ **拿 `infp` 去比哨兵 `FP` 即假红（`d697b1e1…` vs `abc76bd55…`）**。**口径句**：哨兵＝**九位 ＋ 第 10 键 `FP`（`BRIDGE_SRC_FP`）＋ `WAVE`／`BASELINE`／`BASELINE_SHA16` 共 13 行**；`FP` **不属九位**（九位＝ `SHA`／`PC`／`PF`／`WB`／`PROVIDER`／`WIN32SHIM`／`WIC`／`HBTL`／`DWF`）。
14. **哨兵是**仓外仪器**写的（仓内没有写者、也没有读者）** —— 现取（`2026-09-28T12:39:55`）：`grep -rln 'BASELINE_SHA16' --include='*.sh' --include='*.py' .` ⇒ **仓内 0 命中**；写者链在仓外：`~/w79c/bin/w79-push.sh:247`／`~/w79c/bin/w79-chain.sh:172`（`install -m 644` 两地）＋ `~/w79c/w80/close-wave.pre-t46.sh:679-700` 的 `printf` 块（`FP=` 即 `FP_NOW2`）。⇒ 与「8 条绑定规则牙有 4 条在仓外」（本节 §绑定规则 C/D 表）同源：**靠约定、无仓内读者**；**下一波**：把写哨兵的那一小段搬进仓内（否则清一次车道目录，哨兵就成孤儿）。
15. **推送标记（`.done`）适用面与命名不统一，且**仓内没有强制读者**（`verifier` 于 `t15` 现取）** —— ① 现取事实（`2026-09-28T12:57:27`）：`~/w14a/` 只有四枚 `W80_DOCSCLOSE.done`（12:31）／`W80_T58.done`（12:35）／`W80_T60.done`（12:41）／`W80_T62.done`（12:46），三字段齐全（`push_rc=0`／`stop_line=none(all-steps-ok)`／`remote=<sha>`）；② **`t64` 两次推送零标记**（`find ~ -maxdepth 3 -name '*T64*'` ⇒ **命中 0**），`t65` 因此把"标记字段非空"记 `NOINFO`；③ 全 `~` `maxdepth 3` 共 **41** 枚 `*.done`，散在车道目录（`~/w79c/logs/*`、`~/w79c/w80/*` …）⇒ **命名/位置无统一约定**；④ **仓内零读者**：`grep -rIl '\.done' build/MilBridge/tools verify-all.sh build/close-wave.sh` ⇒ **0 命中** ⇒ "`push_rc=`／`stop_line=` 不许为空"这条纪律**没有机器面**。⇒ **下一波两案择一**：（甲）规定"所有推送必须有标记 ＋ 至少一名**仓内**读者"；（乙）把标记搬进仓内（那时"字段不许为空"才有牙）。**本波不改。**
16. **`docs/ROUTES.md:228`（`TASK-0303` 行）的引用形态需写明"前缀口径"（`verifier` 于 `t15` 现取；**不是**"陈旧"）** —— 该行引 `build/MilBridge/W78A-report.md` `0dbc62b1d1cf86ee`／**568 行**；现取整件为 **582 行**／`720e12fceb761941`（`d80ec2a` 于 `12:30:46` 追加了 14 行 dated 更正）。**但**：`head -568` 该件 ⇒ **`0dbc62b1d1cf86ee` 逐位相同**（我自算）⇒ 引用**成立**（＝"只增不改"下的**前缀**快照）。⇒ 下一波把该行的引用**写明口径**（如"`568` 行前缀快照"），否则读者拿整件哈希对不上会误判成 stale。
17. **`docs/ROUTES.md:166` 的 §13 计数行与**它自己那棵树**不符（`verifier` 于 `t15` 现取；同族＝第 11 条"手抄机器值"）** —— 计数行现取逐字 `TASK 行 **77** ＝ ✅**75** ／ 🟡**0** ／ 🔴**2** ／ ⚪**0`；我用"行首树形符号锚 `─ TASK-nnnn`"独立抽取（脚本 `~/w31x/s13count.py`）得 **77 行**（与计数行**同数**）但分类是 **✅74 ／ 🟡1 ／ 🔴2 ／ ⚪0** —— 差的那一格里是 **`:205` `TASK-0201 [MVP] 🟡`**（该行**正文**里另有一个带 ✅ 的 dated 重取读数，机械取"行内第一个 ✅"会把 🟡 吞掉）。同错第二处＝`§15af:788`（`树内状态现算 ✅75／🟡0／🔴2`；且该行把抽取域写成"含 `[Next]` 的行"，却在 🔴 里点了两件 **`[MVP]`** 行 ⇒ 域描述与分类自相矛盾）。**同族第二笔（口径要写明）**：`§13` 树内**唯一 TASK 行 = 79 行**（多出的两行是 **`:209` `TASK-0202`**／**`:216` `TASK-0204`**，**不带** `[MVP]`/`[Next]` 标记），而计数行写"TASK 行 **77**"、`:788` 写"唯一 TASK **77** 个" ⇒ **77 只对"带标记的行"成立**，对"唯一 TASK"不成立。⇒ 下一波做 dated 更正（`🟡0→1`、`✅75→74`）＋写明"TASK 行"的两种口径（全行 `79`／带标记 `77`）＋把"状态记号取**标签后**那一个（不得取正文里第一个 ✅）"写进抽取口径。


18. **门禁是"构建驱动" ⇒ 冻后跑门禁必使 `PROVIDER` 位位移**（`D-G176` 最小复现：**单工程一次 `dotnet build` 4.35 s 即换值**；`verifier` 于 `t15` 现取 ＋ 自己复现） —— ① 本环起点（`2026-09-28T12:55:11`，门禁起跑前）`#80` 块九位行（`ACCEPTANCE-BASELINE.md:66`）／`BASELINE tier=`（`:74-79`）／哨兵 `PROVIDER=`／canon live **四处同值 `7e8a217b4165a6b9`**；② 我这趟门禁 `[1] 构建` 之后 canon 变 `d093559be572ccbf`（mtime `12:55:54.2642120`，**字节数不变 `104448 B`**，九位其余 8 位 mtime 未动）⇒ `WFREEZE_NINEAUTH=FAIL`（canon `d093559be572ccbf` vs copy `7e8a217b4165a6b9`）＋`WFREEZE_BLOCKVALUES=FAIL gen=#80 key=provider block9=tier=`7e8a217b4165a6b9` live=`d093559be572ccbf``；③ **最小复现**：`dotnet build build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj -c Release -m:1 --nologo -v q`（`4.35 s`、`rc=0`、源码 mtime 仍 `09-15`／`09-16`）⇒ 值再变 **`24e4e0a731dbed40`** ⇒ **同一输入连续两次构建给出不同字节**；④ 同趟门禁 `55 ✅/0 ❌`、875 例全绿、五臂全绿 ⇒ **不是产品回归**（新字节行为一致）；⑤ **结构性后果**：`门禁×2 → 冻结 → post1/post2 → 推送 → 哨兵` 里只要**冻后**再跑一次会 `dotnet build` 的门禁，冻结块的 `provider` 就**必然**与 live 分叉 ⇒ **"冻后重跑门禁"与"块值恒真"不可兼得**；⑥ **本波处置**：按契约**不碰 `#80` 块**、不当新红；哨兵十键按**现取**重写（`PROVIDER=24e4e0a731dbed40`，两枚 `279 B`／`sha16=c6ee190ed289455c`／`cmp IDENTICAL`，末笔提交 `13:14:09` 之后 `12 s`），依据 `close-wave.sh:679-700`"**谁重建，谁更新，不留人工步骤**"；**下一波待办**：定则（`provider` 是否允许"位位移"免钉／门禁是否必须**冻前**跑／或给 `provider` 加一颗"同输入复现性"牙）。

> **本节与 `t14` 的分工（逐字，防并行改同一件）**：**`t54` 建这 9 条并把节头写死**；`t14` 若要补条，**在同一节内追加**（或加"（续）"），**不要另起一节**，也不要在本节内改写既有条目的数字（照本件纪律：**只增不改**）。
