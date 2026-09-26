# BASELINE-HEADER date=2026-09-26T2x:xx+08:00 display=:23x（`verify-all` 头标目标显示号）｜车道 = **W185A-W77LAND**（唯一写者）
#   cpu=3核  run_dir=/home/links-dev ｜车道工作目录 `~/w185a/w77/`（`criteria.md`／`logs/`＝链条日志）
#   ⚠️ 权威件构建配置 = Release（唯一声明 = build/SelfBuiltConfig.props）
#   ⚠️ 判据先行：`~/w180a/w77/criteria.md`（`W180A` 交付包，**写于任何 `$R` 写入之前**）＋ 本波车道 `~/w185a/w77/criteria.md`（**追加三条判据写于落地之后**：仓根 props 牙／旧路径重指向／`BOUNDARY-DECL` 分类器修 —— **逐字登记、不冒充"判据先写"**）
#   ⚠️ `docs/WAVE77-PREREGISTRATION.md` 与**落地同趟**产出（四要件齐全 ＋ 机读行 `PREREG-NO-REGRESSION-DECISION: not-applicable-instrument-wave-77` ＝ **硬形态**，`PREREG4=NA form=machine-line` **不带残余洞令牌**）
#   ⚠️ **本波是仪器波 · 零产品改动**：三颗新牙 ＋ 一处分区牙 ＋ 21 件旧路径重指向 ＋ 一份**仓外补丁**（`TASK-0745`，**冻结器一字节未动**）。
#   ⚠️ **射程边界（如实，不许读成绿）**：① `PROTO_ATTR` 的**归档真腿 `ATTRIBUTED` 结构性不可达**（装置只印 `fd=<n>`、不印 socket 身份）⇒ 每腿 `NOINFO reason=sock-id-absent`，判据由 `--cases`（18 例）承载；② `PARSER_GUARD` 的 `parser` 面**形态故意保守**（宽形态 `or 0\)` 在现仓 4 处**全是表格默认值** ⇒ 会假红 ⇒ 已删），判据由**动态面 4/4 ＋ 射程表**承载，**不靠"零命中"**；③ 仓根 props 牙的第二条来源（`git ls-files`）只在 `$ROOT` **本身是 git 仓根**时算得出，否则印 `git=NA` 且**不计入 `PASS`**；④ `TASK-0745` 的补丁**未落**（冻结器是主控写域）且其**指定基准已被主控重锚取代**（见 RECORD ④）。

# RE-FROZEN #77 —— ✅ **当前冻结基线** —— 内容 = 「**接线件 ⊆ 覆盖面要有常态牙** ＋ **解析器不许静默中性化** ＋ **协议级归因** ＋ **冻结器记录形态自检（补丁）**」合波（`TASK-0740` ＋ `TASK-0742` ＋ `TASK-0744` ＋ `TASK-0745`）＋ **主控同趟追加**（仓根 `Directory.Build.props`/`.targets` 缺席牙）＋ **21 件旧路径重指向**
#   ① **`TASK-0740`（`D-G140`：一次性普查不能当常态判据）现场与修法**：波 `#74` 的普查发现"`42` 条 `run_step` 抽路径 × `194` 件活清单 ⇒ 恰 `3` 件承重牙不在覆盖面"，`#74` 把余量收干净 —— **但这条缺口本身没有牙守**（同类缺口此前已长过一次：`TASK-0729`）。本波新牙 `build/MilBridge/tools/wiring-coverage-check.sh`（第 `[48]` 步 `WIRING-COVERAGE`）：**接线集 ⊆ 覆盖面**，`missing_n>0` ⇒ 红并**逐件点名**；三态 `PASS`/`FAIL`/`NOINFO`，`examined==0`／抽成空集／活清单零行 ⇒ **`NOINFO`（算不出 ≠ 绿）**。**每次运行现扫**（`D-G140` 口径句落地）。收口实测：落地前真树 `FAIL missing_n=1` 点名 `tests/WpfGfx.Linux.Tests/Commands.Tests/tools/verify-cmd-layout.py` ⇒ **同趟收编它**（覆盖面 `205 → 211`）⇒ 落地后 `PASS missing_n=0`（**同一颗牙、同一口径，只换覆盖面**）。
#   ② **`TASK-0742`（`D-G143`：解析不出不许静默中性化）现场与修法**：仓外原始案发地是一个**总是**返回 `(0, 0)` 的 `wh()` ⇒ 整条谓词恒零、正极性永远不成立、整条路被读成"没有该现象"（`#67` 的正极性就是这么被**假负**掐掉的）。本波落 `build/MilBridge/tools/parser-guard-check.sh` ＋ **唯一机读声明** `build/MilBridge/tools/parser-guard-decl.txt`（第 `[49]` 步 `PARSER-GUARD`）：**危害形态的口径**＝「中性值与合法读数**不可区分**」（返回 `0`/`-1`/`(0,0)` 当几何/尺寸用）⇒ 红；哨兵型（`None`/`''`/`'?'`）且下游**按哨兵判** ⇒ 不危害。**口径住在声明件头，不住在牙里**（判据只有一处）。动态面 4/4（每个 `PARAM` 种类真跑：畸形值必响亮拒 ∧ 合法值必过）；射程表逐处裁定 4 处 `BENIGN`（`frame-presence-check.sh:136`／`t1c-census.sh:45`／`geom-revert-beat-check.sh:98`／`baseline-sha-check.sh:62`），`parser` 面 **0 处**（窄形态）。**一次形态收窄如实登记**（见上"射程边界"②）。
#   ③ **`TASK-0744`（`D-G144`：符号级 hook 恒瞎）现场与修法**：托管层 X11 P/Invoke 走 `NativeLibrary` 句柄 ⇒ `LD_PRELOAD` 符号级 hook 对这条路径**恒瞎**（两腿都没 `CALL XResizeWindow`，而 wire 上**真有** `ConfigureWindow(mask=0xc,1280x1024)`）⇒ 符号台账会把人引向"应用没调用"的**假结论**（真凶恰是应用自己）。本波落 `build/MilBridge/tools/proto-attribution-check.sh` ＋ 确定性语料 `build/MilBridge/tools/proto-attribution-cases.tsv`（第 `[50]` 步 `PROTO-ATTR`）：吃 **wire 台账**（`PROTO fd/op0/head` ＋ `popcount(mask)` **自洽**）＋ **fd 的 socket 身份必须随行打印**（缺失 ⇒ `NOINFO reason=sock-id-absent`，**这一格是闸**）＋ 链的最外层应用帧可命名 ＋ 服务器侧 `|Δ|≤50 ms` **成对事件**；三态 `ATTRIBUTED`／`NOT_ATTRIBUTED`／`NOINFO`，**"符号级没有 CALL"永不算 `NOT_ATTRIBUTED`**；**阳性对照是门槛**（`role=POSCTL` 必须真判 `ATTRIBUTED`，否则 `FAIL reason=untriggerable`）。**口径句**：**"凡判『谁调用了什么』，必须用协议级/wire 级证据并打印连接的 socket 身份；符号级 hook 的『没调用』不构成证据。"**
#   ④ **`TASK-0745`（`D-G145`：本代记录带齐下一代所需机读形态）—— 本波交**补丁**，冻结器一字节未动**：`~/w21-verify/w27-freeze.py` 是**主控写域**（`#76` 之后 `2026-09-26 18:01` 被主控重锚：`1e2460c1d27e756c` → `1707dd98434273e9`）⇒ 包内补丁器**按设计拒写**（`rc=5 NOINFO reason=anchor-E3a-hits-0`），排练器 `ARM PATCHL` **真红**（**这正是那条牙在报"我过期了"**，不是静默放行；`E3` ＝ `D-G146` 建议块，**已被主控改动取代**）。本波车道**派生**一份 `E1+E2` 两处补丁（`E12_PATCH=APPLIED base_sha16=1707dd98434273e9 out_sha16=1328f1d0b9e7f912 edits=2`）并在**现行基准**上真跑两极化：`A1` 正极（7 形态齐）⇒ `bad=0 checked=7`；`A2` 反极（**复现 `#73` 位移句**）⇒ `bad=1` **点名 `prev_infp`**；`A3` 形态两次 ⇒ 拒；`A4` 九位行缺席 ⇒ `bad=6`；顺序闸 `render<check<backup<writeB` ⇒ `yes`。**补丁的重新锚定待主控**（本波**不碰**冻结器）。
#   ⑤ **主控同趟追加：仓根 `Directory.Build.props`/`.targets` 缺席牙**（**折叠进既有第 `[9]` 步 `BUILD-HYGIENE`，不动步数**）—— 理由：本波契约把 `grep -c '^run_step "'` 钉在 `50`，新开步会变 `50`+1 与契约冲突；`[9]` 正是"构建卫生"的家（先例：`TASK-0728` 折叠进 `[12]`）。两件与上游**逐字节相同**且**仍在远端** ⇒ 任何一次上游合并都会把它们**原样带回**，届时移植工程求值立刻 `error MSB4236`（**症状要跑到构建才看见**；本条要的是"被加回来的那一刻就响"）。判定**同时**取两条来源（`test -e` ∧ `git ls-files --error-unmatch`），判读行 `BHYGIENE_ROOTPROPS=` ＋ 汇总行四格。`--selftest` **29/29 PASS**（新增 `Z1`/`Z2` 存在性、`Z3` **真 `git init`＋`add`＋`rm`**（**"只判不存在"与"同时判来源"的分水岭**）、`Z4` 正极）。
#   ⑥ **旧路径重指向（21 件／23 处）**：仓内 `*.sh`／`*.py`（排除 `upstream/`）里 `wpf-linux-20260906` 的默认值**全部改为由仓根现推**（`verify-all.sh:192`／`close-wave.sh:31` 同法）；现取命中数 **0**。三牙复跑 `LANEPATH=PASS`／`SELFDESC_WIRING=PASS run_step=50`／`ALIAS=PASS`。
#   ⑦ **`pts-gap-count-check.sh`（`t4` 现场三修 ＋ 措辞对齐）**：① 默认 `R` 由仓根现推；② **读数行带 `root=`**；③ `build/close-wave.sh` **显式传 `R="$ROOT"`**；④ `build/MilBridge/HANDOFF-NEXT.md` 复述措辞由「**88 可操作／97 实现口径**」改为抽取式要求的「**可操作 88／实现口径 97**」⇒ `PTSGAP` **`FAIL`（两处 `SITE-NOHIT`）→ `PASS`**；`--selftest 7/7`。
#   ⑧ **落地时咬出一处既有牙缺陷（**待主控配号**）**：`build/MilBridge/tools/boundary-decl-check.sh` 的调用闭包分类器形态②原为 `^[[:space:]]*[\\`(]*<path>`（**允许行首一个反引号**）⇒ 把**多行注释块的散文续行**当成"直调" ⇒ 拉进**只被读、从不被执行**的件（`close-wave.sh`），再从它的 `printf` 白名单参数表里拉进**从未被调用**的件 ⇒ 使声明 `W68-UNWIRED-PRODUCER`（期望 `unwired-in-step`）**假红**（本波 `WIRING-COVERAGE` 新步把它顶出来：`route=transitive`）。**修法 ＝ 去掉 `[\\`(]*` 前缀**（与件头契约"提到路径不算调用"一致）；修后 `BOUNDARY_DECL=PASS records=2 pass=2 fail=0` ∧ `--selftest 13/13` ∧ **前一代 `verify-all` 上复跑同样 `PASS`**（零判定面位移）。**口径句**：**"判『谁调用了什么』时，被引号/反引号包起来的路径是**散文**，不是命令位；证据域必须剥掉引号与注释。"**
#   ⑨ **四处声明同趟**（**加三步**形态）：`# VERIFYALL-STEPS-DECL: 50 gen=#77`（插在现行第一行**之前**，newest-first）＋ 头注释口径句「**`#77` 收官起 = 50 步**」＋ `# VERIFYALL-STEP-NAMES: … | WIRING-COVERAGE | PARSER-GUARD | PROTO-ATTR` ＋ 本预登记件；**纪律 46 真不变量**＝首行 `DECL` 步数 == 现取 `grep -c '^run_step "'`（**`DECL` 行数 ≠ 步数**，不写那条假断言）。`--expect 211 → 211`（本波已由落仓器同趟改）。
#   ⑩ **零产品改动**：`src/**`／`build/shims/**`／native 源、`tests/WpfGfx.Linux.Tests/**` 一字节未动 ⇒ 九位除 **`pf`（环成员，`D-G92`：整波重建必变、同尺寸）**外**不该动**；`allow_changed={'pf'}` ＋ `pf_required=True`。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `53fd7fffcdb30243`／`pf` `4fcd2ca021c39064`（6123520 B）／`windowsbase` `07c89f1872c1a3c1`／`provider` `1f9511a7ef395bfe`／`win32shim` `fc60c34d51fd9247`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`／`dwf` `b07f801556e1a511`
#     · **相对 `#76` 冻结值**：**五位位移** —— `pc` `722e0ab8205b7c3f` → `53fd7fffcdb30243`／`pf` `963c59991fd1f709` → `4fcd2ca021c39064`（**环成员**，`D-G92`）／`windowsbase` `2e4e46e539a72cd7` → `07c89f1872c1a3c1`／`provider` `1f9511a7ef395bfe` → `4041df9a704abfed`／`dwf` `ce3469f49efcbcfa` → `b07f801556e1a511`；**四位逐位未变**：`win32shim` `fc60c34d51fd9247`／`bridge`／`wic_shim`／`hbtextline`。
#   ⚠️ **五位位移的归因（100% 机械，不是产品回归）**：`#76` 的九位是**从旧树 `O` 拷进 `N` 的**（`O` = `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`，`N` = `/home/links-dev/netTest/GitProj/WPFOnLinux`）；本波是**第一次在 `N` 里真重建**，五个托管程序集的 **DEBUG 目录里嵌的 `*.pdb` 绝对路径**随之变成 `N` 的路径（实测 `strings -a` 命中 `/home/links-dev/netTest/GitProj/WPFOnLinux/build/PresentationCore.Linux/obj/Release/PresentationCore.pdb`），而**字节大小与 `#76` 冻结值逐位相同**（`pc 3601408`／`pf 6123520`／`windowsbase 1111552`／`provider 104448`／`dwf 39936`）⇒ 位移是**路径驱动**的同一个物理量，属 `D-G92` 环成员机制的**同一族**。`bridge`／`win32shim`／`wic_shim` 是**原生/发布件**，本波**未**重建（值逐位未变）⇒ 反证「位移只发生在**被重建的托管件**上」。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   ⚠️ **九位只许从最新冻结块的九位行或 `BASELINE tier=` 机读行取**（`D-G119` 实例㉕）。
#   **`inputs_fp` = `b67560f2ff28932b69cf198aa68ed91ca66f582180d27d4af929deca54dd540c`**（**本波冻后值 · 机读形态** —— 这一行是**下一代 `prev_infp` 的唯一来源**；上一代 = `bb54413c8a3f0474a3d04e41dc08ec29fb993f7ea7a8ab689ae29f372904eb9a`）。覆盖面 **205 → 211**（白名单 **+6 行**：本波 5 新件 ＋ `TASK-0740` 收编的 `verify-cmd-layout.py`），`[42] --expect` **同趟** `205 → 211`。
#   【① 落仓（**owner = 本波唯一写者**；写前逐件 `stat -c %h==1` 断言、`temp＋rename` 原子替换、`mktemp -d`＋`trap`；**逐件备份取在任何写之前**并断言"备份 sha16 == 覆盖前现读 sha16"，缺一**拒落**（`D-G126`））】
#      **6 新件**：`build/MilBridge/tools/wiring-coverage-check.sh`／`parser-guard-check.sh`／`parser-guard-decl.txt`／`proto-attribution-check.sh`／`proto-attribution-cases.tsv`（`W180A` 包，逐件与包内记录 sha16 相符）／`docs/WAVE77-PREREGISTRATION.md`。
#      **改件**：`verify-all.sh`（三新步 ＋ 四处声明 ＋ `--expect 205 → 211`）／`build/close-wave.sh`（覆盖面 **+6 行** ＋ `[5b/6]` 显式传 `R=`）／`build/MilBridge/HANDOFF-NEXT.md`（复述措辞对齐 ＋ §2/§3 对齐 ＋ §7 根路径）／`docs/ROUTES.md`（§13 四处状态位 ＋ §15ad 波块）／`build/MilBridge/tools/build-hygiene-import-check.sh`（仓根 props 牙，折叠进 `[9]`）／`build/MilBridge/tools/boundary-decl-check.sh`（分类器形态②修）／`build/MilBridge/tools/pts-gap-count-check.sh`（`R` 现推 ＋ 读数行 `root=`）／**21 件旧路径重指向**。
#      **纪律 35 · 本波变更集逐笔列全（一条都不省）**：
#       ① `W180A` 包四件（`TASK-0740`／`0742`／`0744`／`0745`）—— 6 新件 ＋ 三新步 ＋ `build/close-wave.sh` 覆盖面 **+6 行** ＋ `[42] --expect 205 → 211`；
#       ② **21 件旧路径重指向**（23 个文本点；判据 = 仓内 `*.sh`／`*.py` 里 `wpf-linux-20260906` 命中数 == **0**）；
#       ③ `TASK-0720` 残项现取核对（**结论：`docs/ROUTES.md` 里那两条加注已过期** —— 两件都在 `#76` 办完，提交 `9cea5cc`）＋ `pts-gap-count-check.sh` 三修（`R` 现推／读数行 `root=`／`close-wave.sh` 显式传 `R=`）＋ `HANDOFF-NEXT.md` 措辞对齐 ⇒ `PTSGAP` **`FAIL`（两处 `SITE-NOHIT`）→ `PASS`**；
#       ④ **仓根 `.editorconfig` 移出（结构性去重；主控 `2026-09-26` 追认）** —— `bf84100e2afbd3d2`／`76,255 B`，与 `git show HEAD:.editorconfig` 逐位相同（上游原件）；原件 ＋ 回退指令存 `~/w-p0mig/quarantine-editorconfig/`（`cp -p` 回仓根 ＋ `git add` 即可逐字节回滚）。⚠️ **如实划界**：移出的**只是 129 条 `dotnet_diagnostic.<RULE>.severity = error`**（`EnforceCodeStyleInBuild=false` 现读），**代码风格约束确已消失**，这是**有意的、逐字声明的**取舍；本波**只证了这一件**是整波 10 处失败的成因（配对实验 `-p:EnableNETAnalyzers=false` ⇒ 0 错误／不加 ⇒ 162 条 `error`），**不断言**没有第二件；
#       ⑤ **`PROTO-ATTR` 接线修正** —— 包内 `landing.sh` 的 `RUNSTEP_LINES` **漏了 `--cases`** ⇒ 门禁里 `PROTO_ATTR=NOINFO reason=usage:--cases-needs-file cases=0 … rc=3`（**该步根本没在判**；`gate1` 一度 `步骤通过 49 ❌ 失败 1`）⇒ 补 `--cases build/MilBridge/tools/proto-attribution-cases.tsv --expect 18` ⇒ `PROTO_ATTR_GATE=PASS examined=18 mismatch=0 bad_expect=0 posctl=2/2`。**主控裁定逐字：「不是放宽判据，是把『判不了』变成『真判』」**，三条理由：**（1）改前它根本没有判**（走 `usage` 分支）⇒ 加 `--cases` 是让判据**开始执行**，与"把红改绿"相反方向；**（2）"回滚成 `NOINFO` 并等包方补"是更坏的选择** —— 那会把一个**已接线但不判**的牙冻进世代，正是 `TASK-0724`「在册但没牙床」与 `D-G136`「件头自述 vs 接线不一致」两族，**已接线的死牙比没有牙更危险**；**（3）`--expect 18` 是加牙**，且 `verify-all.sh` **不在 `fp_inputs()` 覆盖面** ⇒ `inputs_fp` 不移、`steps`／`--expect`／`VERIFYALL_SELF` 逐格不变。**`W180A` 复核射程更正**：「已复核 12/12」应读作「**只复核了被点名的两颗牙 ＋ 手跑形态的第三颗**」（更正同时落在 `docs/WAVE77-PREREGISTRATION.md §7.5` 与 `~/w180a/w77/SUPERSEDED-NOTE-W77.md`，包的原文一字未动）；
#       ⑥ `TASK-0745` **补丁重锚（`E1+E2`）** —— 原包补丁的指定基准被主控 `18:01` 的重锚（为 `TASK-0746`）作废（`E3a` 锚点消失）⇒ 原器按设计拒写（`rc=5`）、排练器 `ARM PATCHL` 真红；**冻结器逻辑一字节未落**（主控写域）；
#       ⑦ `t1` 的两笔提交（`7027be06e7fddb793ea22411c1f0645626474a73` 结构性去重 ＋ `fd9a9a1886d25575ae625d44741d45620d554185` 报告收口）**随本波推送带走**，推送后**逐笔**核到远端；
#       ⑧ 主控同趟追加：仓根 `Directory.Build.props`/`.targets` **缺席牙**（折叠进 `[9] BUILD-HYGIENE`，**不动步数**）；
#       ⑨ **本波新发现**（只记账、不修）：`BOUNDARY_DECL` 分类器形态②缺陷（**已修**，见 FROZEN ⑧）／**九位是路径承载体**（`#76` 的九位是**拷贝来的**、`#77` 是 `N` 内**第一次真重建** ⇒ 五位位移，归因 100% 机械；见 FROZEN 九位行下方）。
#      **落仓器**：`~/w180a/w77/landing.sh`（两相；五闸：写者／`%h==1`／纪律 46 唯一不变量／覆盖面 == `--expect`／锚点 `hits==1`；**派生路径一律在参数解析之后由同一个 `R` 现推** ＋ 两道闸（字面前缀 ＋ `readlink -f` 解析后前缀）—— 这正是一次**真事故**（`D-G130` 实例④：原版把 `VA/CW/FPMS` 绑在参数解析**之前** ⇒ 真 `$R` 被写两件）的产物；逃逸断言两极化 E1/E2 已真跑）。
#      ⇒ `W77_LAND=APPLIED steps=50 coverage=211 expect=211`；`✅` 自指牙 `VERIFYALL_SELF=PASS`。
#   【② 判据与两极化（**全部真跑**，原始读数 `~/w180a/w77/logs/` 与 `~/w185a/w77/logs/`）】见 FROZEN 段 ①②③⑤⑧ 与 `polarity.md`；自测 `13/13`／`13/13`／`14/14`／`29/29`／`7/7`／`13/13`（`TASK-0745` 排练 `28/29`，唯一 FAIL ＝ `ARM PATCHL` **如实报基准过期**）。
#   【③ 链条】落仓 → 整波（`~/heavy-slot.sh` 内 `integration-wave`；`WAVE_OWNER` 必填）→ 应用级门禁 ×2（判词行逐字相同）→ `gate1`／`gate2`／`pre`（期望 **50 ✅ / 0 ❌**、`[42] files_n=211 declared_expect=211`）→ 冻结（生产路径 `PREVCHECK=PASS`）→ 冻后 `verify-all` ×2 → 推送 → app-local → 两哨兵 `cmp`。
#   【④ 未落项（如实）】`TASK-0745` 的补丁**未应用到冻结器**（主控写域）且其**指定基准已被主控在 `2026-09-26 18:01` 的重锚取代** ⇒ 需主控重新锚定；本波**不动**冻结器。
#   【⑤ 覆盖面位移**逐件归因**】`205 → 211`（**+6 行**）：`wiring-coverage-check.sh`／`parser-guard-check.sh`／`parser-guard-decl.txt`／`proto-attribution-check.sh`／`proto-attribution-cases.tsv`（本波 5 新件）＋ `tests/WpfGfx.Linux.Tests/Commands.Tests/tools/verify-cmd-layout.py`（`TASK-0740` 收编的缺口件）。逐件归因见预登记 §4.1／§5。
#   【⑥ 零产品改动】九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸**）⇒ 见 FROZEN 段 ⑩。
#   【⑦ 自伤（如实留档，全部被自己的断言/牙当场咬住）】① 我给新牙写的诊断串里在**双引号内**用了反引号（`error MSB4236`）⇒ `BHYGIENE_SELFTEST` 的 `noise` 断言**当场红**（`case Z1/Z2 => no`），改成无反引号写法；② 我的"顺序闸"第一版用 `text.index('TASK-0730')` 取了**首次出现**（在检查点**之前**）⇒ 自造假红 ⇒ 改成 `index(..., i_check)`；③ `TASK-0745` 派生补丁器第一版直接复用原器 `A_E1`（以 `    return bad` 结尾）—— 主控把该行改成 `    return bad, checked, skipped` 之后它**仍然是子串**（**前缀命中**）⇒ 插入点落进表达式中间 ⇒ `ast` 当场 `invalid syntax` ⇒ 改用**自定界锚**（`D-G131` 同族：锚必须自定界）。
#   【⑧ 推送／app-local／哨兵】逐径 `git add`（**绝不** `-A`／不从 `git status` 生成清单）；app-local 合格线 `STALE=0 ∧ DIVERGENT=0`；两哨兵补 `BASELINE=#77` ＋ 新 `BASELINE_SHA16` 并 `cmp` 验 `IDENTICAL`。⚠️ **本波例外（逐字声明）**：本波契约**明确要求**同趟更新 `docs/ROUTES.md` §13／`build/MilBridge/HANDOFF-NEXT.md` §1–§3／`docs/CURRENT-STATE.md:9` 并**重发** `defect-registry-declared.tsv` ⇒ 这三件**随本波推送**（旧约定"主控五件不推"中与它们相关的部分**由本波契约取代**；`KNOWN-DEFECTS.md`／`FORK-AND-PUSH.md` 本波**未改、也不推**）。`t1` 的两笔（`7027be06`／`fd9a9a18`）**随本波推送带走**，推送后**逐笔**核到远端。
#   【⑨ 内存／进程／显示位】重活一律 `~/heavy-slot.sh --min-avail 1500 --max-hold <N> --wait 3600`；链头写 `df -Pk` 第 4 列 ＋ `free -m` 的 `avail`／`swapfree`；收进程**只按 PID**（禁 `pkill`／`pgrep -f`）；自起显示位记 PID ＋ `EXIT trap` 按 PID 收净（`D-G139`）。
#   【⑩ 如实边界（`NOINFO`）】① `PROTO_ATTR` 归档真腿 `ATTRIBUTED` 结构性不可达（见 BANNER）；② `PARSER_GUARD` 的 `parser` 面故意保守（见 BANNER）；③ 仓根 props 牙的第二条来源在非 git 仓根上 `NA`；④ `TASK-0745` 补丁未落 ＋ 基准过期（见 ④）；⑤ 本波**不做任何回归判定**（仪器/装置波；机读行 `PREREG-NO-REGRESSION-DECISION: not-applicable-instrument-wave-77`）。
BASELINE tier=default rep=1 config=pc:53fd7fffcdb30243,bridge:4e25e4b27d4d5ae1,pf:4fcd2ca021c39064,provider:4041df9a704abfed,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w185a/w77/gate/gate-r1
BASELINE tier=default rep=2 config=pc:53fd7fffcdb30243,bridge:4e25e4b27d4d5ae1,pf:4fcd2ca021c39064,provider:4041df9a704abfed,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w185a/w77/gate/gate-r1
BASELINE tier=default rep=3 config=pc:53fd7fffcdb30243,bridge:4e25e4b27d4d5ae1,pf:4fcd2ca021c39064,provider:4041df9a704abfed,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w185a/w77/gate/gate-r1
BASELINE tier=env rep=1 config=pc:53fd7fffcdb30243,bridge:4e25e4b27d4d5ae1,pf:4fcd2ca021c39064,provider:4041df9a704abfed,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w185a/w77/gate/gate-r1
BASELINE tier=env rep=2 config=pc:53fd7fffcdb30243,bridge:4e25e4b27d4d5ae1,pf:4fcd2ca021c39064,provider:4041df9a704abfed,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w185a/w77/gate/gate-r1
BASELINE tier=env rep=3 config=pc:53fd7fffcdb30243,bridge:4e25e4b27d4d5ae1,pf:4fcd2ca021c39064,provider:4041df9a704abfed,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w185a/w77/gate/gate-r1
# ⏪ **（历史，已被 `#77` 取代）**# RE-FROZEN #76 —— ✅ **当前冻结基线** —— 内容 = 「**边界声明做成有机读读者** ＋ **在册数补正** ＋ **判据口径搬进判据件自身**」合波（`TASK-0732` ＋ `TASK-0720` 残项 ＋ `TASK-0721` 纯文档面 ＋ `TASK-0741`）
#   ① **`TASK-0732`（`D-G132`：诚实声明没有机读读者）现场与修法**：`#68` 写的两条边界声明（`producer=UNWIRED-IN-STEP`／`legacy-copies=DEPRECATED×7`）**全仓没有任何一件去求值它**，且它的谓词是**手工执行**、域是**拼写**（大小写／连字符／经 wrapper 调用一变就既不报警也不覆盖）。本波新牙 `build/MilBridge/tools/boundary-decl-check.sh` 把它做成**通用读者**：声明与谓词参数**从预登记语料读回**（牙内**零硬编码** —— `producer=`／`WAVE68`／`SilentHitProbe` 命中全 **0**，同命令在语料上命中 **1** 作正极性对照），谓词的域是**件路径身份**（`run_step` argv 逐条 `realpath -m` 归一 ＋ **包装件传递闭包** ≤3 层、带环守卫、**只认命令形态**），三态 `PASS`／`FAIL`／`NOINFO`，并有**覆盖闭包**把「**没有谓词的声明**」逐条点名成红、**旁观带上限**（`DECL-BOUNDARY-BYSTANDERS: expect=2`，零余量，超出 ⇒ `rule=bystander-tree-grown` 逐条点名；缺该行 ⇒ `bystander-expect-absent`）。
#   ② **`TASK-0720` 残项现场与修法**：`D-G70` 的「在册数」在正文里分散且**互相矛盾**（`#66` 落装置面后 `103/91` 已过期；`111` 经 W174A 穷举 11 种算法**证伪**、其唯一"出处"是注释自述）。本波落**唯一机读声明行** `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（`tool=100 dead=11 artifact=1 ops=88 impl=97` ＋ 三个内容锚 `so16`／`exports`／`w66pre16`）＋ 新牙 `build/MilBridge/tools/pts-gap-count-check.sh`（**每次冻结前**现算并逐字段**零余量**对账；`PTSGAP_CITED` 轨核 11 处复述位，不符 ⇒ 逐处 `CITED-MISSING` 点名）；牙挂 `build/close-wave.sh` 的 **`[5b/6]`**（在 `[5/6]` 与 `[6/6]` 之间 ⇒ 读**最终态**；本步红 ⇒ `run()` 当场 `exit` ⇒ 汇总与两哨兵都不落）。C 源第 9 处（**仅注释**：`可操作 91／实现口径 97` → `88／97`，同行同字节长）。
#   ③ **`TASK-0721` 纯文档面**：那条路线的**装置面** `#67` 早已落地（第 `[38]` 步 `PTS-PAGES`，`PTS_GUARD=PASS legs=2/2`、`--selftest 12/12`，两件在 `close-wave.sh` 覆盖面内）；旧的"0 命中"是 **BRE `|` 字面量陷阱**的**假证据**（`grep -rn 'A|B|C'` 无 `-E` ⇒ 恒不中，主控已立 `D-G141`）。本波**不加步、不加件**，文档面由**主控**落（`ROUTES` 行加注 ＋ `C1` 取代声明）。
#   ④ **`TASK-0741`（`D-G142`：判据口径文本单点存在）现场与修法**：`PTS` 的**方向口径**（洋红 `=0` ⇒ 页级占位缺席／**未修方向**）在仓内**只**活在 `verify-all.sh` 一条历史 `DECL` 行里，**判据件自身没有** ⇒ 单点脆弱。本波把它搬进 `build/MilBridge/tools/pts-pages-guard.sh`：**件头口径句** ＋ **口径自证闸**（`direction_gate()` 读回机读行 `# PTS-DIRECTION: …` 并与编译常量 `MAGENTA_FLOOR` 对账；**缺句／不符 ⇒ `PTS_DIRECTION=FAIL` ＋ 本步当场红**，`rc=1`）＋ 判词行**行尾** `direction=` 标记 —— **既有判词前缀语义一字不改**（`PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=-` 原样，仅行尾多一格）；自测 `12/12 → 17/17`。
#   ⑤ **四处声明同趟**（**加一步**形态）：`# VERIFYALL-STEPS-DECL: 47 gen=#76`（插在现行第一行**之前**，newest-first）＋ 头注释口径句「**`#76` 收官起 = 47 步**」＋ `# VERIFYALL-STEP-NAMES: … | BOUNDARY-DECL` ＋ 本预登记件；**纪律 46 真不变量**＝首行 `DECL` 步数 == 现取 `grep -c '^run_step "'`（**`DECL` 行数 ≠ 步数**，不写那条假断言）。
#   ⑥ **零产品改动**：`src/**`（除 win32_classification.c **注释**一行）／`build/shims/**`／native 源、`tests/WpfGfx.Linux.Tests/**` 一字节未动 ⇒ 九位除 **`pf`（环成员）**外**不该动**；`allow_changed={'pf'}` ＋ `pf_required=True`。实测 `wsh`（`fc60c34d51fd9247` **未变** ⇒ 本波**不**声明 `allow_changed` 含 `wsh`；C 注释改动经四腿实测**不动** `.so`，含**阳性对照**）。
#   ⑦ **两极化（全部真跑，原始读数 `~/w176a/w76/logs/pol-*.out` 与 `polarity.md`）**：`BOUNDARY_DECL` **1 正 ＋ 9 反**（正＝现树 ⇒ `PASS records=2 coverage=4/6 gaps=0 bystanders=2 expect=2`；反＝直调 `route=direct`／经 wrapper `route=transitive`／目标换成**不存在的件名** ⇒ `NOINFO`（**防恒挂**）／语料**加新声明而不动牙** ⇒ 红（**证通用性**）／删记录 ⇒ `record-count-mismatch`／未覆盖声明 ⇒ `declaration-without-predicate` 点名／车道副本未标废 ⇒ `lane-unmarked`／车道回收 ⇒ `evaporated`（**不变红**）／旁观超上限 ⇒ `bystander-tree-grown`／缺上限行 ⇒ `bystander-expect-absent`）＋ 牙自测 `13/13`；`TASK-0741` **1 正 ＋ 1 反**（在位 ⇒ `PTS_GUARD=PASS legs=2/2 … direction=in-file` `rc=0`；沙箱删句 ⇒ `PTS_DIRECTION=FAIL` ＋ `PTS_GUARD=FAIL … direction=missing` `rc=1`）＋ 自测 `17/17`；`TASK-0720` 模块自测 `7/7`（5 例必红）＋ 其自带 5 腿极化（A 真树 ⇒ `PASS`／B1 逐字 ⇒ 红／**B2 只改一词 ⇒ 绿**＝落地即绿的机器证）。
#   ⑧ **冻结器（仓外，本波**不改**它）**：`~/w21-verify/w27-freeze.py`；**本波冻结在真冻上**必须打印生产路径 `PREVCHECK=PASS gen=#76 keys=… base=（上一代基线的 sha16）`；`prev_infp` 取自 **`GENS['#75']['infp']`**（主控裁定：现读全 64 hex）；`keys=` 的语义缺陷**由主控改**（本车道**不碰**，只照实报 `keys=`／`skipped`）。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`／`pf` `963c59991fd1f709`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `fc60c34d51fd9247`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`／`dwf` `ce3469f49efcbcfa`
#     · **相对 `#75` 冻结值**：`pf` `ca509e7eadaa4ede` → `963c59991fd1f709`（**环成员**，`D-G92`：整波重建必变、同尺寸）；其余八位 `pc` `722e0ab8205b7c3f`／`windowsbase` `2e4e46e539a72cd7`／`win32shim` `fc60c34d51fd9247`／`dwf` `ce3469f49efcbcfa`／`bridge`／`provider`／`wic_shim`／`hbtextline` **逐位未变**。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   ⚠️ **九位只许从最新冻结块的九位行或 `BASELINE tier=` 机读行取**（`D-G119` 实例㉕）。
#   **`inputs_fp` = `bb54413c8a3f0474a3d04e41dc08ec29fb993f7ea7a8ab689ae29f372904eb9a`**（**本波冻后值 · 机读形态** —— 这一行是**下一代 `prev_infp` 的唯一来源**；上一代 = `b31e281698056ece0d2480f0455f1ecf9cb7fdf3225024b6e20615911b1b3213`）。覆盖面 **202 → 205**（白名单 **+3 行**：`boundary-decl-check.sh`／`pts-gap-count-check.sh`／`pts-gap-decl.txt`），`[42] --expect` **同趟** `202 → 205`。
#   【① 落仓（**owner = 本车道 W176A**；写前逐件 `stat -c %h==1` 断言、`temp＋rename` 原子替换、`mktemp -d`＋`trap`）】
#      **4 新件**：`build/MilBridge/tools/boundary-decl-check.sh` **`41ea8e7c6d13dbf5`**（件 1 主牙；`711`）／
#      `build/MilBridge/tools/pts-gap-count-check.sh` **`b545a981124d8074`**（件 2 牙；落仓值 `155a1f84dd609d92` ⇒ 同波按主控裁定 **(A)** 修 `D-G114` 同族管道陷阱后为此值）／
#      `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` **`abb55f0152475ac8`**（在册数唯一机读声明行）／
#      `docs/WAVE76-PREREGISTRATION.md`（四要件 ＋ 三条机器声明行）。
#      **4 改件**：`verify-all.sh` `ee4ab2bdbe43cc72` → **`b30c685909832f38`**（新步 `BOUNDARY-DECL` ＋ 四处声明 ＋ `--expect 202 → 205`）／
#      `build/close-wave.sh` `70e047f318663a19` → **`d76b0f6668d83f13`**（`[5b/6]` 接线 ＋ 覆盖面 **+3 行**）／
#      `build/MilBridge/tools/pts-pages-guard.sh` `d42e9395f31e3681` → **`da8c48cc118e134e`**（件 4：件头口径句 ＋ 口径自证闸 ＋ 行尾 `direction=`；中间值 `c8c4ab6e2a812e55` ⇒ 同波修 `D-G114` 同族管道后为此值）／
#      `src/WpfGfx.Linux.Native/src/win32_classification.c`（**仅注释**，同行同字节长）。
#      **落仓器**：`~/w176a/w76/landing.sh` **`3e34581a01895563`**（两相；五闸：写者／`%h==1`／纪律 46 唯一不变量／覆盖面 == `--expect`／锚点 `hits==1`；re-anchor 硬 pin `so16`／`exports`／`WAVE66`；落仓后四条收口断言 ＋ 两颗新牙实跑，**任一不过自动回滚**）
#      ⇒ `W76_LAND=APPLIED steps=47 expect=205 coverage=205`；`✅` 自指牙 `VERIFYALL_SELF=PASS names=47 decl=47`。
#   【② 判据与两极化（**全部真跑**，原始读数 `~/w176a/w76/logs/`）】见 FROZEN 段 ⑦ 与 `polarity.md`（**每条都真跑、无"设计上应该"**）。
#   【③ 射程扫描（`D-G140` 口径句）】语料成员表 ＝ 现取 `docs/WAVE*-PREREGISTRATION.md`（本波落仓后 **57** 件），**每次运行重扫**并打印 `DECL_CORPUS files=… at=… digest=…`；覆盖闭包的**旁观候选**有**声明式上限**（`expect=2`）；一次性扫描的结论**只能当当时的读数**。
#   【④ 链条】落仓（`landing.sh` 五闸 → `--apply`）→ 整波（`~/heavy-slot.sh` 内 `close-wave.sh --skip-verify-all`；应在 `[5b/6]` 打出 `PTSGAP=PASS`）→ 应用级门禁 ×2（判词行逐字相同）→ `gate1`／`gate2`／`pre`（期望 **47 ✅ / 0 ❌**、`[42] files_n=205 declared_expect=205`）→ 冻结（生产路径 `PREVCHECK=PASS`）→ 报主控并**停住**。
#   【⑤ 覆盖面位移**逐件归因**】`202 → 205`（**+3 行**）：`boundary-decl-check.sh`（件 1 判据件）／`pts-gap-count-check.sh`（件 2 判据件）／`pts-gap-decl.txt`（件 2 的声明行 —— 牙**读**它 ⇒ 判据照成文惯例「**读 ⇒ 进 `fp_inputs()`**」）。三件**逐件归因**已写进预登记 §5。
#   【⑥ 零产品改动】九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸**），`wsh` 见 FROZEN ⑥。
#   【⑦ 自伤（如实留档，全部被自己的断言/牙当场咬住）】① `landing.sh` 的**模式规范化**漏了（`--dry-run` ≠ `dry-run`）⇒ 演练里 dry-run **掉进应用相**（真落仓时的写者闸仍先拦住了，未伤 `$R`）⇒ 已修并加"dry-run 不写一字节"注释；② 我新写的预登记散文**以反引号包着 `producer=UNWIRED-IN-STEP` 起头** ⇒ 被**我自己的覆盖闭包**判成 `DECL_GAP=FAIL`（**不把散文令牌当豁免**）⇒ 改措辞；③ 冻结数据面（`close-wave.sh` 覆盖面）第一版把续行符加到**空行**上，被 applier 的**形态断言** `coverage-append-outside-printf-chain` 当场拒写；④ 件 2 牙的 `R` **硬指真仓**而 `DECL` 是相对路径 ⇒ 落仓器必须传 `R=`（否则**静默读真仓**）。
#   【⑪ **`D-G114` 同族修（主控裁定 (A)：同波修）**】`gateapp` 后主控现取发现 `[24] PIPEFAIL-SIGPIPE` **红在两件新落地件上**（`pts-gap-count-check.sh:176` 与 `pts-pages-guard.sh:262` 的 `printf … | grep -qF` 管道；牙是**动态实测**：`dyn_big=12/12` 翻转／`dyn_off=0/12`）⇒ 两条管道改成 **here-string**（`grep -qF -- "$sub" <<< "$out"`／`grep -qF 'PTS_DIRECTION=FAIL' <<< "$_sbo"`；**无管道 ⇒ 无 SIGPIPE**），**判词语义一字未改**（`PTSGAP=PASS …`／`PTS_GUARD=PASS legs=2/2 … direction=in-file` 逐字相同；自测 `7/7`／`17/17`）；修后 `PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 files=96 sites=87`。⚠️ 两件**都在覆盖面内** ⇒ `inputs_fp` 必变 ⇒ **整波重跑 ＋ `GENS['#76']['infp']` 重填**（旧读数一律作废，`#69` 纪律）。
#   【⑧ 推送／app-local／哨兵】逐径 `git add`（**绝不** `-A`／不从 `git status` 生成清单）；**主控五件不推**（`KNOWN-DEFECTS.md`／`ROUTES.md`／`HANDOFF-NEXT.md`／`FORK-AND-PUSH.md`／`defect-registry-declared.tsv` —— 文档面由主控落与推）；app-local 合格线 `STALE=0 ∧ DIVERGENT=0`；两哨兵补 `BASELINE=#76` ＋ 新 `BASELINE_SHA16` 并 `cmp` 验 `IDENTICAL`。
#   【⑨ 内存／进程／显示位】重活一律 `~/heavy-slot.sh --min-avail 1500 --max-hold <N> --wait 3600`；链头写 `df`／`mem_avail`；收进程**只按 PID**（禁 `pkill`／`pgrep -f`）；自起显示位**记 PID ＋ `EXIT trap` 按 PID 收净**，收尾与链前基线逐项比对（`D-G139`）。
#   【⑩ 如实边界（`NOINFO`）】① 件 2 牙的真树实跑绿**依赖前置**（主控 8 处文档面替换 ＋ `S1` 引用改 `-check.sh`），未落 ⇒ `PTSGAP=FAIL` ⇒ 落仓器**按设计回滚**；② **件 4 判据写于实现之后**（派单中途加入，已在 `criteria.md §1.8` 逐字登记）；③ 本波**不做任何回归判定**（仪器/装置波；机读行 `PREREG-NO-REGRESSION-DECISION: not-applicable-instrument-wave-76`）。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:963c59991fd1f709,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w176a/w76/gate/gate-r1
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:963c59991fd1f709,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w176a/w76/gate/gate-r1
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:963c59991fd1f709,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w176a/w76/gate/gate-r1
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:963c59991fd1f709,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w176a/w76/gate/gate-r1
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:963c59991fd1f709,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w176a/w76/gate/gate-r1
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:963c59991fd1f709,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w176a/w76/gate/gate-r1
# ⏪ **（历史，已被 `#76` 取代）**# RE-FROZEN #75 —— ✅ **当前冻结基线** —— 内容 = 「**四件装置/判据卫生**」合波（`TASK-0736` ＋ `TASK-0737` ＋ `TASK-0738` ＋ `TASK-0739`，**仪器波 · 零产品改动**）：① **件头自述 vs 接线**（新牙 `build/MilBridge/tools/selfdescription-wiring-check.sh`：件头含"未接线"而 `^run_step` **命中**该件 ⇒ 必红；**反向**（自述"已接线"而**零命中**）⇒ 也必红；`--selftest` 8/8）＋ 同趟修 `prereg-four-requirements-check.sh` 件头的陈旧自述（**不写死步号**）＋ **接线为一步** `SELFDESC-WIRING`；② **落地件不许出现车道路径**（新牙 `build/MilBridge/tools/lane-path-check.sh`：`kind=code` 必红且**永不许豁免**；`comment`／`data` 走**声明式出处清单** `build/MilBridge/lane-path-provenance.tsv` ＋ **每类件数上限**（现读 > 上限 ⇒ 红）；`--selftest` 16/16）＋ **同趟修三处真默认值**（`hidden-only-step.sh`／`geom-revert-beat-check.sh`／`tests/W81AWindowProbe/run-w81a-legs.sh`）；③ **比较域必须区分"读数"与"标签"**（新牙 `build/MilBridge/tools/rows-identity-check.sh`：只标签差异 ⇒ `PASS` ＋ **必印** `LABEL_ONLY_DIFF fields=…`；读数真差异 ⇒ `FAIL`；语料＝`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` **最新冻结块现取**；`--selftest` 12/12）；④ **长跑自起显示位收尾收净 ＋ 自查**（`verify-all.sh` 记本趟自起 `Xvfb` PID ＋ `EXIT trap` **按 PID** 收；**复用者／`--no-x` ⇒ 一个都不杀**；新牙 `build/MilBridge/tools/xvfb-census-check.sh` 以 `[0]` 段落的**自含链前基线**比对 `ps` ＋ `/tmp/.X11-unix/`，差异**点名 PID**；"死 socket"与"活泄漏"**分开判**；`--selftest` 12/12）。
#   ① **`TASK-0736`（`D-G136`）现场与修法**：`build/MilBridge/tools/prereg-four-requirements-check.sh` 件头长期自述「**未接线（不进 verify-all，由主控编排）**」，而它**早已**是 `verify-all.sh` 的一步（现取 `run_step "PREREG-FOUR-REQ" … --gate --glob 'docs/WAVE*-PREREGISTRATION.md'`）⇒ 下一位读者按**假前提**派活（会去"接线"一件已接线的东西）。修法＝件头自述改「**已接线**」且**不写步号**（步号会漂）＋ 造牙。两极化：**正极** 自述"已接线" ∧ 命中 ⇒ `PASS`；**反极 1** 自述"未接线" ∧ 命中 ⇒ `FAIL rule=forward-selfdesc-notwired-but-wired`（**落地前真树现红 1 处**）；**反极 2** 自述"已接线" ∧ **拿掉接线** ⇒ `FAIL rule=reverse-selfdesc-wired-but-not-wired` ⇒ 落仓器**整体回滚**（**同趟闸**的机器证）。
#   ② **`TASK-0737`（`D-G137`）现场与修法**：从车道沙箱"提升"为仓内件的工具，**默认路径仍指向它出生的那条车道** ⇒ 落仓后每次运行都往**别人的目录**写证据/中间件（跨车道写入 ⇒ 证据与读数脱钩）。**现取普查**：命中 **9 处/9 件** —— **可执行行 3 处＝真默认值**（`hidden-only-step.sh:220` `HIDDEN_ONLY_OLDPC` 兜底／`geom-revert-beat-check.sh:93` `GEOMBEAT_LIVE_DIR` 兜底／`tests/W81AWindowProbe/run-w81a-legs.sh:59` `W81A_OUT` 兜底）＋ `data` 7 行（`hygiene-tooth.sh` 的登记表 B/G/H：仓外装置根/孪生/夹具，**按设计就指向仓外**）＋ `comment` 8 处（含 `wm-awaited.sh:5` 的**判据原文出处**、`tline-gate.sh:808`／`pipefail-sigpipe-check.sh:15` 的现场证据出处、`nsvclick` 一类重写理由）⇒ **照字面"出现即红"落地＝当场红、本波冻不了** ⇒ 主控裁定 **(甲)＋(乙) 组合**：硬在 `code` 行；`comment`／`data` **不判红但必须逐条可见并显式声明**（清单 ＋ 每类上限，**树长大也红**）。三处真默认值同趟修（`OLDPC` 只认显式 `HIDDEN_ONLY_OLDPC`；`SANDBOX` 改 `mktemp -d`；`OUT` 改 `$HOME/.cache/wpf-linux/w81a-out`）。
#   ③ **`TASK-0738`（`D-G138`）现场与修法**：`#69` 两趟应用级门禁的 `BASELINE` 六行**逐字段相同**，唯一差异是行尾 `rundir=…gate-r1` vs `…gate-r2` **标签** ⇒ 自报 `ROWS_IDENTICAL=no` **是标签造成的、不是读数漂移**；**不区分就会因假红去改本已正确的件**。**现取**：`grep -rn 'ROWS_IDENTICAL' build/MilBridge/tools/ verify-all.sh close-wave.sh` = **0 命中**（仓内**零实现**，只有报告文字）⇒ 修法＝新牙（`--selftest` 含**现场形态**与**阴性对照**：标签也相同 ⇒ **不得**印 `LABEL_ONLY_DIFF`，防"恒印"把判词稀释成噪声）。
#   ④ **`TASK-0739`（`D-G139`）现场与修法**：`verify-all` 的 `[0]` 段**自起 Xvfb 且跑完不收**（`ppid=1` 孤儿）⇒ 跨波慢性泄漏（主控在 `#73` 前按 PID 清掉 **5 个**累积孤儿，最老 **13 h 14 m**）。**本波现场二次取证**：`#74` 冻后链的 `verify-all.sh` 起的 `Xvfb :99`（`pid 1917743`，`ppid` ＝ 那条 `verify-all`）⇒ **链退出不收即成新孤儿**。修法①＝记自起 PID ＋ `EXIT trap` **按 PID** 收；修法②＝普查牙（**自含**链前基线；`X239` 一类"基线里就有且无主的死 socket" ⇒ 具名可见、**不判红、不冒充归因**）。
#   ⑤ **`skip=1` 的射程声明与销账（**声明值已更正，见文末更正节**）（主控裁定）**：`0737` 去掉 `HIDDEN_ONLY_OLDPC` 的车道默认值后，第 `[19]` 步 `HIDDEN-ONLY` **在生产模式下不用那些夹具**（门禁射程未缩）；`--selftest` 下丢掉 **1** 条（S12/S13/S14）⇒ 判词行尾**必须**挂 `range-reduced reason=oldpc-not-in-repo`（**三态**：空／`not-on-disk`／**无后缀**），**不许**让 `PASS` 被读成"全射程通过"；**声明值 `skip=1` 落纸（更正后）**（`criteria.md §1.2` ＋ 预登记 `§3b`），落仓相**只声明 ＋ 断言后缀在位**，**冻前**由钩子 `polarity/skip-decl-freeze-hook.sh` 吃冻前 `verify-all` 日志做**等式断言**并把 `SKIP_DECL_FREEZE=OK declared=1 observed=1 range_reduced=yes` 落进本记录（`MISMATCH` ⇒ 停手报主控；`NOINFO` ⇒ 不算绿、点名 reason）。**三处真默认值的门禁读数影响如实点名**：`hidden-only-step.sh` 那一处 ⇒ `--selftest` 下 `skip=1`（`cases=12 pass=12 fail=0`）；**门禁 `[19]` 是生产模式、无 `skip=` 格、射程未缩**；`geom-revert-beat-check.sh`／`W81AWindowProbe` 两处**不在门禁** ⇒ **读数零变化**。
#   ⑥ **四处声明同趟**（**加四步**形态）：`# VERIFYALL-STEPS-DECL: 46 gen=#75`（**插在现行第一行 DECL 之前** —— `decl_line()` 是 `sed … | head -1`，`D-G131`）／`# VERIFYALL-STEP-NAMES: …` **行尾追加**四个步名（`SELFDESC-WIRING`／`LANE-PATH`／`ROWS-IDENTITY`／`X-CENSUS`；**既有步序一字不动**）／头注释口径句 ``**`#75` 收官起 = 46 步**``／`docs/WAVE75-PREREGISTRATION.md`（新建，标题含 `#75`）。
#   ⑦ **零产品改动**：`src/**`／`build/shims/**`／native 源、`tests/WpfGfx.Linux.Tests/**` 一字节未动 ⇒ 九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸**，`D-G92`）。
#   ⑧ **两极化（全部真跑，原始读数 `~/w173a/w75/logs/` 与 `polarity.md`）**：`0736` **1 正 ＋ 2 反**（含"**拿掉接线 ⇒ `rule=reverse` ⇒ 回滚**"的同趟闸机器证）；`0737` **1 正 ＋ 4 反**（**`code` 写进清单照样红**／未声明 `comment` 红／上限 < 现读红）＋ 自测 16 例（含 `# RETIRED` 形状非法必红）；`0738` 自测 12 例（**只标签差异 ⇒ `PASS` ＋ 必印**／**读数差异 ⇒ `FAIL`**／**标签也同 ⇒ 禁印**）；`0739` **真机 5 腿**（起过 ⇒ 收净／**没起过 ⇒ 不误杀**／自起豁免 `PASS`／**同一真实状态不声明 ⇒ `FAIL` 并点名 PID**／收尾回基线）＋ 自测 12 例；`skip=3` 三极化 **3 腿**（常态／错路径／**完整 ⇒ 后缀为空**＝防"恒挂"）。
#   ⑨ **冻结器（仓外，本波**不改**它）**：`~/w21-verify/w27-freeze.py`；**本波冻结必须打印**生产路径 `⟦PREVCHECK⟧ …` ＋ `PREVCHECK=PASS gen=#75 keys=7 base=#74`（回归守卫；**没有那行 ⇒ 停手报主控**）。⚠️ 本代 `GENS[#75]['prev_infp']` **恢复主来源**（`#74` 的记录块带 `` `inputs_fp` = `<64hex>` `` 机读形态，已前向修复）⇒ **7 键全走主来源**，不用替代来源。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`／`pf` `ca509e7eadaa4ede`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `fc60c34d51fd9247`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#74` 冻结值**：`pf` `d9e69320cf29924a` → `ca509e7eadaa4ede`（**环成员**，`D-G92`：整波重建必变、同尺寸）；其余八位**逐位未变**。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   ⚠️ **九位只许从最新冻结块的九位行或 `BASELINE tier=` 机读行取**（`D-G119` 实例㉕）。
#   **`inputs_fp` = `b31e281698056ece0d2480f0455f1ecf9cb7fdf3225024b6e20615911b1b3213`**（**本波冻后值 · 机读形态** —— 这一行是**下一代 `prev_infp` 的唯一来源**；`w27-freeze.py` 的 `_PREV_SRC['prev_infp']` 用 ``` `inputs_fp` = `<64hex>` ``` 抽）。覆盖面 **197 → 202**（白名单 **+5 行**）。
#   【① 落仓（**owner = 本车道 W173A**；写前逐件 `stat -c %h==1` 断言、`temp＋mv` 原子替换、写后现算 sha16；**6 改 ＋ 6 新 = 12 件**）】
#      **6 新件**：`build/MilBridge/tools/selfdescription-wiring-check.sh` **`fbba3de1d9fb84b8`**（继承自 `~/w166a/w75/patches/`，未重做）／`build/MilBridge/tools/lane-path-check.sh` **`eebaccfadef9b479`**／`build/MilBridge/lane-path-provenance.tsv` **`f1c195ca683a8dd4`**／`build/MilBridge/tools/rows-identity-check.sh` **`ce75edaf58c9c955`**／`build/MilBridge/tools/xvfb-census-check.sh` **`6dcb102673083d64`**／`docs/WAVE75-PREREGISTRATION.md` **`0d784ddb65073516`**。
#      **6 改件**：`verify-all.sh` `0c5034591d30642a` → **`ee4ab2bdbe43cc72`**（四处声明 ＋ 自起 PID／`trap` ＋ 链前快照 ＋ 四步 ＋ `--expect 197 → 202`）／`build/close-wave.sh` `eda17e5916770d9d` → **`70e047f318663a19`**（白名单 **+5 行**）／`build/MilBridge/tools/prereg-four-requirements-check.sh` `56f23e0704232675` → **`7d71b22b8e60292f`**（**只改件头那半句**）／`build/MilBridge/tools/hidden-only-step.sh` `505f315026092584` → **`a8ddffc1e00db20f`**（默认值 ＋ 射程后缀）／`build/MilBridge/tools/geom-revert-beat-check.sh` `ade2b2e292df2ace` → **`cd4e6198f7998ee7`**／`build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh` `08b917a54b18b965` → **`497322c957e5c1fc`**。**未碰**主控五件（`KNOWN-DEFECTS.md`／`ROUTES.md`／`HANDOFF-NEXT.md`／`FORK-AND-PUSH.md`／`defect-registry-declared.tsv`）。
#      **落仓器**：`~/w173a/w75/landing.sh`（两相；五闸：写者／`%h==1`／纪律 46 唯一不变量／`expect==files_n`／**锚点 6/6 命中数==1**；**锚定编辑不整件覆盖**（`#74` 碰同一批件 ⇒ 整件覆盖会冲掉它的工作）；失败**整体回滚**）；备份 `~/w173a/w75/backup/<时刻>/`。
#   【② 判据与两极化（**全部真跑**，原始读数 `~/w173a/w75/logs/pol-07*.txt`）】见 FROZEN 段 ⑧；四件牙的判定点：`0736` ＝ 件头抽取 ＋ `^run_step` 命中判；`0737` ＝ `classify_hits()` 状态机（`code`／`comment`／`data`）＋ 上限对账 ＋ `# RETIRED` 形状校验；`0738` ＝ `block_rows()`／`split_fields()`（比较域声明）；`0739` ＝ `read_ps_raw()`／`filter_ps_live()`／`read_socks()` ＋ `verify-all.sh` 的 `x_reap_own_display()`。
#   【③ 射程扫描（`D-G140` 口径句）】成员表 ＝ 现取 `build/MilBridge/tools/*.sh` ＋ `build/MilBridge/tests/**` 的**代码件**（`*.sh`／`*.py`）**59 件**（`LANEPATH examined=59`）＋ `ps -eo pid=,args=` 全机 `Xvfb :` ＋ `/tmp/.X11-unix/` 成员；**两处都是接线牙、每次运行重扫**（读数带 `examined=`／`hits=`／`X_CENSUS_AT=`／`X_CENSUS_SRC=`）⇒ 一次性扫描只作当时读数（本记录里的现场扫描值：命中 19 处 ＝ `code` 3 ＋ `comment` 9 ＋ `data` 7；落仓后 `code=0`）。
#   【④ 链条】落仓（`landing.sh --dry-run` 重取五格 → `--apply`）→ 整波（`~/heavy-slot.sh` 内，`close-wave.sh --skip-verify-all`）→ 门禁应用腿 ×2（`run-wpftextdemo.sh 45`，`WPTD_RUN_DIR` 各自指定 ⇒ `rundir` 标签不同 ⇒ `D-G138` 的现场形态）→ `verify-all` ×3（gate1／gate2／**pre**）→ **冻前销账钩子**（`skip-decl-freeze-hook.sh` 吃 `pre` 日志）→ 冻结（**生产路径必须打 `PREVCHECK=PASS`**）→ 冻后 ×2 → `w75-POST.done`（真 `stat`）→ 逐径推送（**排除主控五件**）→ app-local（`STALE=0 ∧ DIVERGENT=0`）→ 两哨兵 `cmp IDENTICAL`。日志一律 `~/w173a/w75/logs/`。
#   【⑤ 覆盖面位移**逐件归因**】`197 → 202`（**+5 行**：`selfdescription-wiring-check.sh`／`lane-path-check.sh`／`lane-path-provenance.tsv`／`rows-identity-check.sh`／`xvfb-census-check.sh` —— 五件**都在门禁里承重**（四件是新步、一件是判据输入）⇒ 依据成文惯例「**读 ⇒ 进 `fp_inputs()`**」）；`inputs_fp` `ddf3cd2b0cef2dcef2de454fbe2f31f578174459de263dd807853447a19d945d` → `b31e281698056ece0d2480f0455f1ecf9cb7fdf3225024b6e20615911b1b3213` **成因** = 这 5 件 ＋ 六个改内容件（其中 `close-wave.sh` **自含于覆盖面**，`#28` 起的设计使然）。**同趟必改的声明常数**：第 `[42]` 步 `--expect 197` → **`202`**（漏改 ⇒ `FAIL reason=files-n-mismatch delta=-5`，方向安全）。**独立复算互证**：整波自印「波前输入指纹」＝ 现算 `fp-manifest-step.sh --expect 202` 的 `would_be_fp`。
#   【⑥ 零产品改动】九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸**）。
#   【⑦ 自伤（如实留档，全部被自己的断言/牙当场咬住）】① 第一版 `lane-path-check.sh` 的 awk 单引号状态机被**双重引号地狱**写成两枚引号 ⇒ `data` 分档失败（夹具暴露）；② 同一件里 `echo "…「D-G137」…「code」…"` 用了**反引号** ⇒ **仓内自己的 `D-G114` 牙当场 `SHELL_QUOTE_TRAP=FAIL traps=2`**（修后 `PASS traps=0 files=79`，同一颗牙**两次**咬住我：另一处是新加的报错串）；③ `local x="$(cmd)"; [ $? -eq 3 ]` 的 **`$?` 是 `local` 的** ⇒ 三态判据读错（改成先赋值再取）；④ 范围销账驱动第一版把**注释里那半句**当抽取出口 ⇒ 切掉了 `elif` 分支（改成"抽到 `oldpc-not-on-disk … fi` 那行为止"＋**抽出行数 > 20 即 `NOINFO`** 的守卫）；⑤ 我给 `landing.sh`／`details.md` 生成器写中文时**三次**用了未转义反引号 ⇒ 命令替换吃掉文本（已改）。
#   【⑧ 推送／app-local／哨兵】逐径 `git add`（**绝不** `-A`／不从 `git status` 生成清单）；**必须排除主控五件**；`BYTECHECK ok=<N> mismatch=0`（逐件比 `$R` vs 克隆 `HEAD:` blob 字节）；app-local 合格线 `STALE=0 ∧ DIVERGENT=0`；两哨兵补 `BASELINE=#75` ＋ `BASELINE_SHA16=<新值>` 并 `cmp` 验 `IDENTICAL`。
#   【⑨ 内存／进程／显示位】重活一律 `~/heavy-slot.sh --min-avail 1500 --max-hold <N> --wait 3600`；`MAXHOLD_KILL`／`NOINFO low-memory` 那趟**作废、不是读数**；收进程**只按 PID**（禁 `pkill`／`pgrep -f`；查存活用**不带 `-e`** 的 `ps -o pid= -p <PIDs>`）；本波自己起的显示位**全部按 PID 收掉**，并按 `D-G139` 在链后现取 `ps -eo args | grep '^Xvfb :'` 与 `/tmp/.X11-unix/` 与**链前基线**比对（差异点名 PID）。链头基线：`Xvfb :` 命中 **0**（现取）；`/tmp/.X11-unix/` = `X0 X1 X10 X239`。
#   【⑩ 声明值销账】`SKIP_DECL_FREEZE=OK declared=1 observed=1 range_reduced=yes`（出处＝冻前 `verify-all` 的 `[19]` 判词行 `HIDDEN_ONLY_SELFTEST=PASS … skip=3 range-reduced reason=oldpc-not-in-repo`；对账键 `SKIP_DECL_FREEZE_RAW`）。`MISMATCH` ⇒ 停手报主控（**不许**当场改声明值）；`NOINFO` ⇒ 不算绿、点名 reason。

## ✍️ 声明值更正（`2026-09-26 12:5x`；主控裁定 **(甲)**，**本节的声明值取代前文**）
**前提更正（逐字，三处同趟）**：
1. **门禁里第 `[19]` 步跑的是生产模式**（`run_step "HIDDEN-ONLY" bash …/hidden-only-step.sh`，**没有 `--selftest`**）
   ⇒ 判词是 `HIDDEN_ONLY_STEP=PASS 判定例=32/32 …`，**根本没有 `skip=` 这一格**；
   而 `HIDDEN_ONLY_OLDPC` 与 S12/S13/S14 **只存在于 `--selftest` 里** ⇒ **门禁的射程一点没缩**。
   ⚠️ 因此前文任何「门禁射程缩减／`[19]` 会多打 3 条未取到」的说法**一律作废**（`D-G146` 同族：声明比实况强）。
2. **射程缩减 ＋ S12/S13/S14 只在 `--selftest`**。
3. **现读**（经重活槽真跑 `hidden-only-step.sh --selftest`，`held≈7 s`）：
   `HIDDEN_ONLY_SELFTEST=PASS cases=12 pass=12 fail=0 **skip=1** range-reduced reason=oldpc-not-in-repo`
   —— 更正：**`cases=12`**（不是 14）；**`--selftest` 耗时 ≈7 s**（先前那句"110–160 s"是**生产模式**的耗时）。
4. ⇒ **声明值 = `skip=1`**（**只许来自现读**，不许来自任何人的转述）；`range-reduced reason=oldpc-not-in-repo` 后缀在真跑里可见 ✓。
5. **销账钩子的输入必须指 `--selftest` 的日志**（链条日志里没有这一格）⇒ 冻结报告那一格应为
   **`SKIP_DECL_FREEZE=OK declared=1 observed=1 range_reduced=yes`**（`MISMATCH` ⇒ 停手；`NOINFO` ⇒ 不算绿并点名 reason）。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ca509e7eadaa4ede,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w173a/w75/gate/gate-r1
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ca509e7eadaa4ede,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w173a/w75/gate/gate-r1
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ca509e7eadaa4ede,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w173a/w75/gate/gate-r1
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ca509e7eadaa4ede,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w173a/w75/gate/gate-r1
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ca509e7eadaa4ede,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w173a/w75/gate/gate-r1
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ca509e7eadaa4ede,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w173a/w75/gate/gate-r1
# ⏪ **（历史，已被 `#75` 取代）**# RE-FROZEN #74 —— ✅ **当前冻结基线** —— 内容 = 「**装置自清理 ＋ `NA` 判据收紧**」落仓（`TASK-0733` ＋ `TASK-0734` ＋ `TASK-0735`，**仪器波 · 零产品改动**）：① `build/MilBridge/tools/r-gate-step.sh` 加**两条会红的**机器判据（临时件**自清理**：默认档 `mktemp -d` ＋ `trap … EXIT`，`janitor` **按 TTL 只清同前缀旧件**，`--keep` 语义逐字声明，`R_GATE_OUT` 显式给出 ⇒ `ownership=external`；**磁盘余量闸**：长跑前**现取** `df -Pk` 第 4 列，闸 `OUT_ROOT`／仓根／调用者 `OUT` 取更小者，低于阈值 ⇒ `DISK_HEADROOM=FAIL` ＋ `rc=2` ＋ 判 `NOINFO`，取不到数 ⇒ `NOINFO`）；② `build/MilBridge/tools/prereg-four-requirements-check.sh` 把 `NA` 从「**提及即算**」收紧为**两形态**（**行首锚定声明句** ∨ **机读行**且值非空非否定），并加**软/硬分档可见性**（软形态**必上屏** `PREREG4_NA_FORM … residual=self-negation-not-checked`，机读行**不得**带）；③ **同趟显式扩面**（主控裁定 (B)）＝ `build/close-wave.sh` 的 `fp_inputs()` 白名单 **+3 行**（三件**在门禁里承重**却**不在覆盖面**）⇒ 覆盖面 **194 → 197** ＋ 第 `[42]` 步 `--expect 194 → 197` 同趟。
#   ① **`TASK-0733`（`D-G133`）现场与修法**：旧版 `OUT="${R_GATE_OUT:-/tmp/r-gate-step-$$}"` **默认永不清理** ⇒ 现场 `2026-09-25` 清点 `/tmp/r-gate-step-*` **66 件 / 6.8 GB**（本波开工前现取仍有 **32 件 / 3382 MB**，最新 mtime `09-26 01:59`）⇒ 同一时刻宿主只剩 **79 MB** ⇒ **反手击停正在跑的波 `#68`**（两段日志 **0 B**、40 s 内 `rc=1`，差点被读成"判据红"）。修法＝**退出即清**（`trap … EXIT`，`fate=cleaned-on-exit` **必上屏**）＋ **janitor 按 TTL（默认 180 min）只清同前缀旧件**（**本趟目录**／**新鲜件**／**非前缀件**／**符号链接**永不入清空集；`readlink -f` 须**直接**位于 `OUT_ROOT` 之下防逃逸）＋ `--keep` **唯一效果**（不被删 ∧ **必上屏** `R_GATE_OUT_KEPT=`，**不改 `rc`、不改判据**）＋ **余量闸**（**取不到数 ⇒ `NOINFO`，永不放行**）。
#   ② **`TASK-0734`／`TASK-0735`（`D-G134`／`D-G135`）现场与修法**：旧判据是**整节正则**（`[[ "$sec" =~ 本波.*不做任何回归判定 ]]`，`.` 跨行 ⇒ **"提到"与"声明"同权**）⇒ 判据节里一句散文"提及"、四要件一件没写就能拿到 `PREREG4=NA`（**假绿通道**；`NA` 正是"跳过回归判定四要件"的那道门）。修法＝**声明的形式**触发（**行首锚定声明句** ∨ **机读行**值非空 ∧ 非否定令牌 `none`／`no`／`false`／`0`／`n/a`／`na`／`null`／`-`）；只提及 ⇒ 打 `PREREG4_NOTE mention-only` 并**走正常路径**（该 `FAIL` 就 `FAIL`）；**「声明 ∧ 引用回归判定工件」仍 `FAIL`（不放宽）**；`NA` 由**软形态**授予 ⇒ **必上屏** `residual=self-negation-not-checked`（**不进计数、不改 `rc`**），**机读行**（硬形态）**不得**带该令牌。
#   ③ **候选 `w74b`（主控裁定 (A) 批；`d4cd80c33d57919d → 56f23e0704232675`，4 hunks）** —— **补"可接受装饰形态清单"的缺口**：行首锚点原本剥 `[[:space:]>#*|!-]`＋emoji＋`§：`＋数字＋`.`，**漏了行内代码定界符** ⇒ 历史件 `docs/WAVE72-PREREGISTRATION.md:20`（整行**就是**那条机读行、被一对反引号包起来）被判成"仅提及" ⇒ `NA → FAIL` ⇒ **第 `[34]` 步 `--gate` 批次 `rc=1`**（本波当时**冻不了**）。修法＝**只**在机读行那一支、**只认整行被一对反引号包裹**（只一端 ⇒ 不剥、`FAIL`）；**散文那一支与值检查一字未动**；件头**逐项列全**可接受装饰（空白／`<!--`／成对行内代码／组合）。
#   ④ **四处声明同趟**（**不动步数**形态）：`# VERIFYALL-STEPS-DECL: 42 gen=#74`（**插在现行第一行 DECL 之前** —— `decl_line()` 是 `sed … | head -1`，`D-G131`）／`# VERIFYALL-STEP-NAMES: …` **一字不改**（本波**不加步**，42 → 42）／头注释口径句 ``**`#74` 收官起 = 42 步**``／`docs/WAVE74-PREREGISTRATION.md`（新建，标题含 `#74`）。
#   ⚠️ **`prev_infp` 的核法（本代特殊；主控 `2026-09-26` 裁定 A）**：**主来源**（上一代块里的 `` `inputs_fp` = `<64hex>` `` 机读形态）**不可用** —— `#73` 的记录模板**缺**该形态（**已前向修复**：本件已带该形态 ⇒ `#75` 起恢复主来源）。本代改用**替代权威来源** `GENS['#73']['infp']` = `17f0abdb41764ac91e3c728d57136193c3cc483a2a8680d61e93206503da5aad`
#      （`#73` 冻结时冻结器自己 `assert INFP == G['infp']` 验过 ⇒ 等价于「`#73` 冻后现算值」） ⇒ 机读行 `PREVCHECK_SUBST key=prev_infp src=GENS[#73].infp eq=yes`。
#      ⇒ 本代 **7/7 键都真核过**（6 键主来源 ＋ 1 键**声明的**替代来源），**不是**「少核一个」。
#   **`inputs_fp` = `ddf3cd2b0cef2dcef2de454fbe2f31f578174459de263dd807853447a19d945d`**（**本波冻后值 · 机读形态** —— 这一行是**下一代 `prev_infp` 的唯一来源**
#      （`w27-freeze.py` 的 `_PREV_SRC['prev_infp']` 用 ``` `inputs_fp` = `<64hex>` ``` 抽）；上一代 `#73` 块
#      **只写了位移句**（`` `inputs_fp` `<旧>` → `<新>` ``）⇒ 本波冻结被 `PREVCHECK=REFUSE HITS!=1 key=prev_infp` 挡下。
#      ⚠️ **教训入册**：冻结记录里凡被 `prev_*` 抽的字段，**必须逐字带上该字段的机读形态**，不许只写散文/位移句。）
#   ⑤ **覆盖面位移（显式扩面）**：`17f0abdb41764ac91e3c728d57136193c3cc483a2a8680d61e93206503da5aad` → `ddf3cd2b0cef2dcef2de454fbe2f31f578174459de263dd807853447a19d945d`，`coverage_n` **194 → 197**（白名单 **+3 行**：`prereg-four-requirements-check.sh`／`pc-line-step.sh`／`frame-step.sh` —— 三件**都在 `verify-all` 里承重**却**不在覆盖面**，依据成文惯例「**读 ⇒ 进 `fp_inputs()`**」）。**同趟必改的声明常数**：第 `[42]` 步 `--expect 194` → **`197`**（漏改 ⇒ `FAIL reason=files-n-mismatch delta=-3`，方向安全）。**收口判据 ＝ 复跑普查得「未被覆盖面保护的接线件 = 0」**（命令逐字写在 `docs/WAVE74-PREREGISTRATION.md` §1.3）。**独立复算互证**：整波自印「波前输入指纹」= 现算 `fp-manifest-step.sh --expect 197` 的 `would_be_fp`，**逐位相同**。
#   ⑥ **零产品改动**：`src/**`／`build/shims/**`／native 源、`tests/WpfGfx.Linux.Tests/**` 一字节未动 ⇒ 九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸 6,123,520 B**，`D-G92`）。
#   ⑦ **两极化（全部真跑，原始读数 `~/w172a/logs/`）**：`0733` **10 腿**（默认档 `fate=cleaned-on-exit` ＋ 目录消失／`--keep` 保留且 `R_GATE_OUT_KEPT` 逐字同路径／两趟 `REP_IDENTICAL=yes`／真小容量 FS `/run/lock`（5 MB）⇒ `DISK_HEADROOM=FAIL avail_gb=0` ＋ `rc=2` ∧ **装置一次未跑**／阈值 `999999` ⇒ 同判／桩 `df` 不可解析 ⇒ `NOINFO` ∧ `rc=2`／过期件必删 ∧ 新鲜·非前缀·符号链接必留／**只换被判件＝基件** ⇒ 目录必留 ＋ **零 `fate` 行零余量行**／调用者 `OUT` 在 5 MB FS ⇒ **FAIL** ∧ 未建目录）；`0734` **七夹具成对**（提及／`none`／空值／句中令牌／声明＋证据 ⇒ **`FAIL`**；锚定句 ⇒ `NA` **带** `residual=`；机读行 ⇒ `NA` **不带**）＋ **全量语料批**（`BATCH_RC=0`／`fail=0`／`na=16`／**`NA→FAIL N=0`**／`WAVE72 ⇒ NA form=machine-line(yes)` 无 `residual=`）。
#   ⑧ **冻结器（仓外，本波**不改**它）**：`~/w21-verify/w27-freeze.py` `439236d6d2504d9a`（`#72` 接线后生产路径已真用过一次）；**本波冻结必须打印** `⟦PREVCHECK⟧ …` ＋ `PREVCHECK=PASS gen=#74 keys=7 base=f747350edf97a74a`（回归守卫；**没有那行 ⇒ 停手报主控**）。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`／`pf` `d9e69320cf29924a`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `fc60c34d51fd9247`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#73` 冻结值**：`pf` `4c45500d413e31e7` → `d9e69320cf29924a`（**环成员**，`D-G92`：整波重建必变、同尺寸）；其余八位**逐位未变**。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   ⚠️ **九位只许从最新冻结块的九位行或 `BASELINE tier=` 机读行取**（`D-G119` 实例㉕）。
#   【① 落仓（**owner = 本车道**；写前逐件 `stat -c %h==1` 断言、temp＋`mv` 原子替换、写后现算 sha16）】5 件：
#      `build/MilBridge/tools/r-gate-step.sh`（`aa9d7188b6b01a2f` → **`eafadc1cb3884749`**）／
#      `build/MilBridge/tools/prereg-four-requirements-check.sh`（`a40aac9031304a8f` → **`56f23e0704232675`**，含候选 `w74b`）／
#      `build/close-wave.sh`（`086f89e13d8e5522` → **`eda17e5916770d9d`**，白名单 **+3 行** ＋ 注释块）／`verify-all.sh`（`f9bc5bca5be3d7f2` → **`0c5034591d30642a`**，`--expect 194 → 197` ＋ 两处声明）／
#      `docs/WAVE74-PREREGISTRATION.md`（**新建**）。**未碰** `KNOWN-DEFECTS.md`／`ROUTES.md`／`HANDOFF-NEXT.md`／`FORK-AND-PUSH.md`／`defect-registry-declared.tsv`（主控五件）。
#   【② 判据与两极化（**全部真跑**，原始读数 `~/w172a/logs/`）】见 FROZEN 段 ⑦；两件牙的判定点：`0733` ＝ `disk_headroom()`／`janitor()`／`cleanup_out()`／`out_fate()`；`0734`／`0735` ＝ `na_decl_forms()` ＋ `check_file()` 的 `no_rd_decl`／`na_form` 分档。
#   【③ 射程扫描（`D-G140` 口径句）】成员表 ＝ 现取 `docs/WAVE*-PREREGISTRATION.md` **55 件**（在册 **17**／生效边界前 **38**）；两臂逐件对账 ⇒ **`NA→FAIL N=0`**；**一次性扫描只是当时的读数**——接线牙（第 `[34]` 步）**每跑必重扫**。
#   【④ 链条】整波（`~/heavy-slot.sh` 内）→ 门禁 ×2 → 冻前 `verify-all`（期望全绿）→ 冻结（**生产路径必须打 `PREVCHECK=PASS`**）→ **冻后 ×2** → `w74-POST.done`（真 `stat`）→ 逐径推送（**排除主控五件**）→ app-local（`STALE=0 ∧ DIVERGENT=0`）→ 两哨兵 `cmp IDENTICAL`。
#      日志一律 `~/w172a/w74/logs/`（链日志头现取 `df -m` 余量 = 24,164 MB）。⚠️ 链日志抬头误印 `=== W73 CHAIN 开始`（生成 driver 时漏改大写 `W73`）—— **纯字面**、不影响判据，**留档不改**。
#   【⑤ 覆盖面位移**逐件归因**】`194 → 197`（**+3 行**，**显式扩面**：`prereg-four-requirements-check.sh`／`pc-line-step.sh`／`frame-step.sh`）；`inputs_fp` `17f0abdb41764ac91e3c728d57136193c3cc483a2a8680d61e93206503da5aad` → `ddf3cd2b0cef2dcef2de454fbe2f31f578174459de263dd807853447a19d945d` **成因** = 这三件 ＋ 两个改内容件（`r-gate-step.sh`／`prereg-four-requirements-check.sh`，本就**在**名单内）＋ `close-wave.sh` 自身（**自含于覆盖面**，设计使然）。
#   【⑥ 零产品改动】九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸**）。
#   【⑦ 自伤（如实留档，全部被自己的断言/牙当场咬住）】① 落仓器第一版改 `--expect` 用的锚是 `--expect 194` ⇒ 命中 **2** 次（**我自己新插的 `DECL` 文本里也写了"194 → 197"**）⇒ 落仓器 **`rc=9` 拒写**、`verify-all.sh` **一字未动**（无半成品），改用**只属于那一步的锚** `fp-manifest-step.sh --expect 194`；② 预登记件的机读行我最初写成 `**PREREG-NO-REGRESSION-DECISION: …**`（粗体包裹）⇒ `form=` 值尾部多出 `**` ⇒ **我自己发现的读出脏**，改成裸行；③ 我自查脚本里一度写了 `sha16(PREREG_SRC) != sha16(PREREG_SRC)` 这类**恒真断言** ⇒ 立刻删掉、换成真检查（**不许拿恒真断言冒充强判据**）；④ 候选 `w74b` 第一版（`a089e51cfd1c745e`，**未落仓**）剥"行首起头即剥"＋"值尾部剥" ⇒ 主控裁定**改为只认成对包裹**（`56f23e0704232675`）；⑤ 链 driver 抬头误印 `W73`。
#   【⑧ 推送／app-local／哨兵】逐径 `git add`（**绝不** `-A`／不从 `git status` 生成清单）；**必须排除主控五件**；`BYTECHECK ok=<N> mismatch=0`（逐件比 `$R` vs 克隆 `HEAD:` blob 字节）；app-local 合格线 `STALE=0 ∧ DIVERGENT=0`；两哨兵补 `BASELINE=#74` ＋ `BASELINE_SHA16=<新值>` 并 `cmp` 验 `IDENTICAL`。
#   【⑨ 内存／进程】重活一律 `~/heavy-slot.sh --min-avail 1500 --max-hold <N> --wait 3600`；`MAXHOLD_KILL`／`NOINFO low-memory` 那趟**作废、不是读数**；收进程**只按 PID**（禁 `pkill`／`pgrep -f`；查存活用不带 `-e` 的 `ps -o pid= -p <PIDs>`）；本波自己起的显示位**全部按 PID 收掉**，并按 `D-G139` 在链后现取 `ps -eo args | grep '^Xvfb :'` 与 `/tmp/.X11-unix/` 与链前基线比对（差异点名 PID）。链头基线：`Xvfb :` 命中 **0**；`/tmp/.X11-unix/` = `X0 X1 X10 X239`。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:d9e69320cf29924a,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w172a/w74/gate/gate-r2
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:d9e69320cf29924a,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w172a/w74/gate/gate-r2
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:d9e69320cf29924a,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w172a/w74/gate/gate-r2
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:d9e69320cf29924a,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w172a/w74/gate/gate-r2
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:d9e69320cf29924a,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w172a/w74/gate/gate-r2
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:d9e69320cf29924a,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w172a/w74/gate/gate-r2
# ⏪ **（历史，已被 `#74` 取代）**# RE-FROZEN #73 —— ✅ **当前冻结基线** —— 内容 = 「**静默 SEGV 那条腿的产出端收进仓**」落仓（`TASK-0726`）：① 新建 `build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh`（仓内**唯一**产出端：起显示、起应用、跑 9 击配方、收装置、把观测变成机读行）＋ 同目录 `silenthit-trim.tsv`（剔除集**唯一来源**）；② `build/close-wave.sh` 的 `fp_inputs()` 白名单 **+2 行**；③ `verify-all.sh` 第 `[42]` 步 `--expect 192 → 194` ＋ 头注释两处声明；④ 车道 **7 份**同形副本标 `DEPRECATED-BY=… (WAVE73)`（`~/w128a/bin/one128.sh` 留作历史真命中的产出者证据，**未动**）。**本波零产品位移**（不改任何产品件；九位里只有环成员 `pf` 变）。
#   ① **产出端**：`run-silenthit-legs.sh` 的**环境自断言**（纪律 38）＝ `DISPLAY`（须 ∈ `:23[0-9]`）∧ `WPF_PROBE_TAG` ∧ `WPF_PROBE_RUNDIR` 三件**各自单独打印**，缺一即 `ENVGUARD=FAIL` ＋ `rc=9`；`--tag`／`--out` 若给了就**必须**与两个 `WPF_PROBE_*` 逐字相同（同一件东西两个名字 ⇒ 读数会指到别处）。**单变量构造**（`--pair`／`--only-shim`／`--only-app`）逐件取 `(相对路径,字节数,sha16)` 做集合差 ⇒ `diff_n == 1` ∧ 唯一差异路径 == 声明的变体路径 才跑；构造后**去硬链接化**并**两次**断言 `%h == 1`（覆盖变体前后各一次）——`cp -a` 会保留源树内的硬链接，两臂共享 inode 时改一臂等于改两臂。
#   ② **剔除集（唯一来源）**：`silenthit-trim.tsv` ＝ `needle<TAB>trail_sp<TAB>trimmed<TAB>tag<TAB>surface<TAB>provenance` 22 行（6 条 `trimmed=yes` 行首锚定逐字 needle ＋ 16 条 `trimmed=no`；`trail_sp` 显式记录尾部空格个数、由产出端重建 —— TSV 字段切分会吃掉行尾空白）。**判据端只消费**：`silent-hit-v2-check.sh` 吃产出端自报的 `APP_TEXT_BYTES`／`APP_TEXT_BYTES_TRIMMED`／`TRIM_GATE`／`SEGV_BRANCH` 并与台账 `trimmed` 列交叉核，**不自己算剔除**（现取 `find $R -name '*trim*'` 命中 **0** 件）⇒ **不存在"同一口径两处"**。
#   ③ **两极化 4 腿全部真跑**（原始读数 `~/w171a/logs/pol-*.log`）：**R1** 真静默 SEGV（真 C 程序 `volatile int *p=0; *p=1`，真内核裁决）⇒ `rc=139` ∧ `APP_TEXT_BYTES=43`／`TRIMMED=0` ∧ `SEGV_BRANCH=rc139` ∧ **红签名打出**；**R2** 重放历史真现场（`~/w128a/frozen/W077`）⇒ `APP_TEXT_BYTES=0`／`TRIMMED=0` ∧ **`stop-signo11`** ∧ 红签名 —— 与 `#68` 参考实现的重放读数**逐字相同**（交叉证）；**C1** 真进程不崩（有输出、正常退出）⇒ `rc=0`／`branch=none` ⇒ **不打红**；**C2** **真 WPF 应用活腿**（私有应用目录 `~/w67-work/app`、私有显示 `:237`、走 `~/heavy-slot.sh`）⇒ `rc=124`／`APPLICATION_TEXT_BYTES=242`／`phase=alive-after-recipe` ⇒ **不打红** —— 与在册活腿台账 `live-legs-green.tsv` 的 10 条**逐格相同**（`242`／`none`／`alive-after-recipe`／`NOT-HIT`）。
#   ④ **四处声明同趟**（**不动步数**形态）：`# VERIFYALL-STEPS-DECL: 42 gen=#73`（**插在现行第一行 DECL 之前** —— `decl_line()` 是 `sed … | head -1`，`D-G131`）／`# VERIFYALL-STEP-NAMES: …` **一字不改**（本波**不加步**，42 → 42）／头注释口径句 `**`#73` 收官起 = 42 步**`／`docs/WAVE73-PREREGISTRATION.md`（新建，标题含 `#73`）。
#   ⑤ **覆盖面位移**：`999791b4d88a6389e9215b3b882134002bab896965af71b6c06efa892e39a891` → `17f0abdb41764ac91e3c728d57136193c3cc483a2a8680d61e93206503da5aad`，`coverage_n` **192 → 194**（白名单 **+2 行**：`run-silenthit-legs.sh` ＋ `silenthit-trim.tsv`）。**同趟必改的声明常数**：第 `[42]` 步 `FP-MANIFEST-TEETH` 的 `--expect 192` → **`194`**（`verify-all.sh` **不在**覆盖面 ⇒ 与生产路径无关；**漏改 ⇒ `FAIL reason=files-n-mismatch delta=-2`**，方向安全）。**独立复算互证**：整波自印「波前输入指纹」= 现算 `fp-manifest-step.sh --expect 194` 的 `would_be_fp`，**逐位相同**（两条互不相干的机制）。
#   ⑥ **零产品改动**：`src/**`／`build/shims/**`／native 源、`tests/WpfGfx.Linux.Tests/**` 一字节未动 ⇒ 九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸 6,123,520 B**，`D-G92`）。
#   ⑦ **7 份副本标废的改前/改后 `sha16`**：`~/w118a/bin/one118.sh` `13674b647160f2fc` → `0ded290a970290ff`｜`~/wc06/probe/one_wc06.sh` `46d5e2c3cf9296cc` → `76ea3f451e260fd6`｜`~/wc07/bin/one128g.sh` `1e09bf458957596e` → `64ecd6e0b4f5e42b`｜`~/wc08/bin/one_wc08.sh` `20782a3b21aec293` → `9357444fcad7dbe6`｜`~/wc11/bin/one_wc11.sh` `8eee56d895cc21e3` → `e20b95ea2261fe3d`｜`~/w155a/w65d109/bin/leg.sh` `15a427eca2e83f03` → `6402d8aa7f583580`｜`~/w159a/bin/leg.sh` `64d027a98c537b0b` → `ece8c0b3a30b1d00`；`~/w128a/bin/one128.sh` **未动**（`b5217b83870a4d9c` 改前 == 改后）。逐件 `%h == 1`。
#   ⑧ **冻结器（仓外，不改 ⇒ 本波冻结是 `#72` 接线后生产路径的第一次真用）**：`~/w21-verify/w27-freeze.py` `dfe84694c6cf7a25` → `439236d6d2504d9a`；**放行条件（`#72` 余账）**：生产路径必须打印 `⟦PREVCHECK⟧ …` ＋ `PREVCHECK=PASS gen=#73 keys=7 base=2eb64610f65a0d07`。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`／`pf` `4c45500d413e31e7`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `fc60c34d51fd9247`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#72` 冻结值**：`pf` `147aac2dbbc6a0d8` → `4c45500d413e31e7`（**环成员**，`D-G92`：整波重建必变、同尺寸）；其余八位**逐位未变**。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   ⚠️ **九位只许从最新冻结块的九位行或 `BASELINE tier=` 机读行取**（`D-G119` 实例㉕）。
#   【① 落仓（**owner = 本车道**；写前逐件 `stat -c %h==1` 断言、temp＋`mv` 原子替换、写后现算 sha16）】4 件：
#      `build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh`（**新建**）／`build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv`（**新建**）／
#      `build/close-wave.sh`（`247cb3d16e2a5392` → **`086f89e13d8e5522`**，白名单 **+2 行**）／`verify-all.sh`（`66da0964f462bb7c` → **`f9bc5bca5be3d7f2`**，`--expect 192 → 194` ＋ 两处声明）／
#      `docs/WAVE73-PREREGISTRATION.md`（**新建**）。**未碰** `KNOWN-DEFECTS.md`／`ROUTES.md`／`HANDOFF-NEXT.md`／`FORK-AND-PUSH.md`／`defect-registry-declared.tsv`（主控五件）。
#   【② 判据与两极化（`TASK-0726`；**全部真跑**，原始读数 `~/w171a/logs/`）】判定点 = 产出端的 `analyse_rundir()`（**唯一实现**）：
#      R1 真静默 SEGV（真进程、真内核裁决）⇒ `LEG … rc=139 APP_TEXT_BYTES=43 APP_TEXT_BYTES_TRIMMED=0 TRIM_GATE=ok STACKOVF=0 SEGV_BRANCH=rc139 FAMILY=139-segv phase=nav undeclared=0 HIT=yes` ＋ `SILENT_SEGV_HIT=yes …`（**红签名**）；
#      R2 重放历史的真静默 SEGV 现场 ⇒ `… rc=1 APP_TEXT_BYTES=0 … SEGV_BRANCH=stop-signo11 … HIT=yes`（与 `#68` 参考实现的重放读数**逐字相同**）；
#      C1 真进程不崩 ⇒ `… rc=0 APP_TEXT_BYTES=41 APP_TEXT_BYTES_TRIMMED=41 … SEGV_BRANCH=none … HIT=no`（**无红签名**）；
#      C2 **真 WPF 应用活腿**（走 `~/heavy-slot.sh`，`held=47s`）⇒ `… rc=124 APP_TEXT_BYTES=242 … SEGV_BRANCH=none FAMILY=alive phase=alive-after-recipe … HIT=no`（**无红签名**；与在册活腿台账逐格相同）。
#      `--selftest` **8 例全 PASS**：S1 剔除集装载／S2 真静默 SEGV 档必 HIT／S3 活腿档必 NOT-HIT／S4 未声明 tag 必 NOINFO／S5 已声明 tag 必 0 undeclared ＋ 剔净／S6 **尾部空格 needle 成对**（无空格 ⇒ 23 B **不剔**；有空格 ⇒ 0 B **必剔**）／S7 环境闸反极性（清空三件 ⇒ `rc=9`）／S8 单变量断言成对（只差一件 ⇒ 接受 `diff_n=1`；多一件 ⇒ 拒绝 `diff_n=2`）。
#      ⚠️ **两处自伤（都被自己的自检当场咬住）**：① `ARM_DIFF` 最初直接数 `diff` 的 `<>` **行数** ⇒ 一件内容变了会给**两行** ⇒ "只差一件"被数成 `2` ⇒ 这条断言**恒假**（S8a 咬住，改为"去重后的相对路径数"）；② 归一化相对路径的 `sed` 写成两条表达式，第二条把第一条已经成功的替换**再匹配一次**（`p` 标志只作用于第二条）⇒ 差异集**恒空**（S8b 从"拒绝"变成"`diff_n=0`"，咬住）。
#   【③ 单源核查（主控 `#73` 前置条件）】现取 `grep -n 'trimmed\|TRIMMED\|剔除' build/MilBridge/tools/silent-hit-v2-check.sh` ⇒ 判据端**只消费**（`:28` 逐字"产出端一致性闸：吃产出端机读行"），**不自己算剔除**；`find $R -name '*trim*'` ⇒ **0 件** ⇒ `silenthit-trim.tsv` 天然是**唯一来源**，不构成"同一口径两处"。
#   【④ 链条】整波（`~/heavy-slot.sh` 内）→ 门禁 ×2 → 冻前 `verify-all`（期望全绿）→ 冻结（**生产路径必须打 `PREVCHECK=PASS`**）→ **冻后 ×2** → `w73-POST.done`（真 `stat`）→ 逐径推送（**排除主控五件**）→ app-local（`STALE=0 ∧ DIVERGENT=0`）→ 两哨兵 `cmp IDENTICAL`。
#      日志一律 `~/w171a/w73/logs/`（链日志头现取 `df -m` 余量 = 25,343 MB）。
#   【⑤ 覆盖面位移**逐件归因**】`192 → 194`（**+2 行**：产出端 ＋ 剔除集）；`inputs_fp` `999791b4d88a6389e9215b3b882134002bab896965af71b6c06efa892e39a891` → `17f0abdb41764ac91e3c728d57136193c3cc483a2a8680d61e93206503da5aad` **唯一**成因 = 这两件 ＋ `close-wave.sh` 自身（它**自含于覆盖面**，设计使然）。
#   【⑥ 零产品改动】九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸**）。
#   【⑦ 自伤（如实留档）】见 ② 的两条（都被自检咬住）；另：`--app-cmd` 形态最初把应用 cwd 指向不存在的目录 ⇒ `cd` 失败 ⇒ `app.rc=90`（自检外的一条腿当场暴露，已改为 `mk_arm_dir()` 显式建目录）；`REPO` 在车道目录下解析成 `/`（落仓后自然正确），已加存在性守卫避免印出误导性读数。
#   【⑧ 推送／app-local／哨兵】逐径 `git add`（**绝不** `-A`／不从 `git status` 生成清单）；**必须排除主控五件**；`BYTECHECK ok=<N> mismatch=0`（逐件比 `$R` vs 克隆 `HEAD:` blob 字节）；app-local 合格线 `STALE=0 ∧ DIVERGENT=0`；两哨兵补 `BASELINE=#73` ＋ `BASELINE_SHA16=<新值>` 并 `cmp` 验 `IDENTICAL`。
#   【⑨ 内存／进程】重活一律 `~/heavy-slot.sh --min-avail 1500 --max-hold <N> --wait 3600`；`MAXHOLD_KILL`／`NOINFO low-memory` 那趟**作废、不是读数**；收进程**只按 PID**（禁 `pkill`／`pgrep -f`；查存活用不带 `-e` 的 `ps -o pid= -p <PIDs>`）；本波自己起的显示位（`:236`／`:237`）**全部按 PID 收掉**（零遗留：`ls /tmp/.X11-unix` 只剩 `X0/X1/X10/X239`）。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:4c45500d413e31e7,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w171a/w73/gate/gate-r2
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:4c45500d413e31e7,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w171a/w73/gate/gate-r2
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:4c45500d413e31e7,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w171a/w73/gate/gate-r2
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:4c45500d413e31e7,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w171a/w73/gate/gate-r2
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:4c45500d413e31e7,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w171a/w73/gate/gate-r2
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:4c45500d413e31e7,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w171a/w73/gate/gate-r2
# ⏪ **（历史，已被 `#73` 取代）**# RE-FROZEN #72 —— ✅ **当前冻结基线** —— 内容 = 「**冻结器与抽取器锚在语义上**」落仓（`TASK-0730` ＋ `TASK-0731`）：① 冻结器（**仓外** `~/w21-verify/w27-freeze.py`）新增 `check_prev_values()` —— `prev_pf`／`prev_pc`／`prev_wb`／`prev_wsh`／`prev_dwf` 取基线件**九位行**、`prev_bsfp`／`prev_infp` 取块内 `BRIDGE_SRC_FP`／`inputs_fp` 行，**每个来源命中数须恰为 1**，并与 `BASELINE tier=` 交叉核；不符 ⇒ **拒冻（rc=2）∧ 基线件零字节改动**（核验插在**任何写盘之前**）。同趟把 `B.pre-freeze.<gen>.bak` 做进冻结器（`cp -a` 真拷贝 ＋ 逐字节断言 ＋ `%h==1`）；② `build/MilBridge/tools/column-floor-check.sh` 的 `extract_newest_block()` **出口条件锚行首**（旧写法用**无锚**的「`RE-FROZEN` ＋ 井号」当退出条件 ⇒ 块内正文只要提到该字样就提前截断，把紧随其后的声明行全排除 ⇒ `COLUMN_FLOOR=NOINFO`（**病因错**）），并新增两条**响亮**守卫（块尾找不到 ⇒ `NOINFO reason=block-end-not-found`；出口锚的**域**由两种机制现取自证 ⇒ `NOINFO reason=block-header-form-mismatch`）。
#   ① **改的全是既有件，不加步**：`build/MilBridge/tools/column-floor-check.sh` **`2be59234f7266e0f` → `e997d316515e4128`**（52,716 → 65,548 B）：出口锚 ＋ `block_span()`／`hdr_form_counts()` 两个只读助手 ＋ 第 ② 段两道守卫 ＋ `--selftest` **+8 例**（既有 **26 例逐字未改**，例数只增不减）。
#   ② **仓外件（如实标注：不进覆盖面）**：`~/w21-verify/w27-freeze.py` **`c22cfb93c43d23fa` → `56e54035c6e1df1b`**（104,070 → 116,295 B）＋ 前像 `w27-freeze.py.bak-w72`（`c22cfb93c43d23fa`）＋ 版本档 `~/w21-verify/versions/w27-freeze.py.w72-56e54035c6e1df1b` ＋ 两份补丁件。**自举声明**：本波改了冻结器 ⇒ **`#72` 的冻结就是它改后的第一次真用**；落仓前已用新增的 `--prev-check-only` 在**沙箱基线副本**上排练（正常档 `PREVCHECK=PASS rc=0`／三个错值档 `PREVCHECK=REFUSE rc=2` ∧ 副本 sha16 逐位未变）。
#   ③ **出口锚为什么不能只写行首那一种**（本波实测）：历史块头是**降级形态** ⇒ 只认行首会让抽块**跑到 EOF**（真件 57 行 → 3573 行）。出口锚 = **块头行**（两种形态：未降级头以 `RE-FROZEN` ＋ 井号起，降级头以装饰符起；**逐字正则见件内 `:158`**）。现取自证：装饰符形态 **45** 行**全部**是降级块头；两种形态合计数 = **51** ＝ 块数；机制 B（剥掉 Markdown 行内代码跨度后，按「行首 `# ` 且含 `RE-FROZEN` ＋ 井号＋世代号」匹配）亦 **51**，且两法**逐行同集合**（真件上 51/51 agree）。
#   ④ **四处声明同趟**（**不动步数**形态）：`# VERIFYALL-STEPS-DECL: 42 gen=#72`（**插在现行第一行 DECL 之前**）／`# VERIFYALL-STEP-NAMES: …` **一字不改**／头注释口径句 `**\`#72\` 收官起 = 42 步**`／本文件（新建，标题含 `#72`）。**步数账**：首行 `DECL` = 42 == 现取 `grep -c '^run_step "'` = 42（纪律 46）；`DECL` **行数** = 38 ≠ 42 —— **没写那条假断言**。
#   ⑤ **覆盖面 192 → 192**（不加不减行）；但 `column-floor-check.sh` **在覆盖面内**（`close-wave.sh:263`）⇒ `inputs_fp` **必移**，**逐件归因仅 1 件**。
#   ⑥ **落地前写死的指纹预测**（`J0`）：本波整波自印 `inputs_fp` = `999791b4d88a6389e9215b3b882134002bab896965af71b6c06efa892e39a891`；该预测由**落仓之后、整波之前**的现树算出（`J0` 留档 `~/w170a/w72/w72-inftp0.txt`）⇒ 与整波自印**逐位相符**才算兑现。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`／`pf` `147aac2dbbc6a0d8`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `fc60c34d51fd9247`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#71` 冻结值**：`pf` `e9fe77a43f950f2c` → `147aac2dbbc6a0d8`（**环成员**，`D-G92`：整波重建必变、同尺寸）；其余八位**逐位未变**。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   ⚠️ **九位只许从最新冻结块的九位行或 `BASELINE tier=` 机读行取**（`D-G119` 实例㉕）。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落仓（**owner = 本车道**；写前逐件 `stat -c %h==1` 断言、temp＋`mv` 原子替换、写后现算 sha16）】2 件：
#      `build/MilBridge/tools/column-floor-check.sh`（`2be59234f7266e0f` → **`e997d316515e4128`**，52,716 → 65,548 B）／
#      `docs/WAVE72-PREREGISTRATION.md`（**新建**）。**未碰** `KNOWN-DEFECTS.md`／`ROUTES.md`／`HANDOFF-NEXT.md`／`FORK-AND-PUSH.md`／`defect-registry-declared.tsv`（主控五件）、`verify-all.sh`／`close-wave.sh` 与任何产品件、`known-red.json`。
#      仓外（**不进覆盖面**）：`~/w21-verify/w27-freeze.py`（`c22cfb93c43d23fa` → **`56e54035c6e1df1b`**）＋ 前像 `w27-freeze.py.bak-w72` ＋ 版本档 `versions/w27-freeze.py.w72-56e54035c6e1df1b` ＋ 两份补丁件；**`$R` 里一字节未落**。
#   【② 判据与两极化（`TASK-0731`；**全部真跑**，原始读数在 `~/w170a/logs/`）】判定点 = `extract_newest_block()`（改前在 `:156-158`）：
#      (a) **块内非行首提该字样 ⇒ 不得提前截断**：① **真仓真件**（基线里 `#52` 块正文 `blkL123` **真含**该字样）⇒ 旧件抽 **122** 行／新件抽 **201** 行；② **合成档**（字样插在 `# COLUMN-FLOOR` **之前**）⇒ 旧件 `COLUMN_FLOOR=NOINFO reason=frozen-block-has-no-COLUMN-FLOOR-line`（rc=2）／新件 **`COLUMN_FLOOR=PASS`（rc=0）**。⚠️ 该合成档落在**真基线副本**上 ⇒ 与真树读数可同口径比。
#      (b) **正常档 ⇒ 取到正确块**：真件上新旧**整份 stdout 逐字节相同**（14 行）∧ 机读行 7 条相同 ∧ rc 都 0；块首 = `# RE-FROZEN ` 行、块尾 = `BASELINE tier=env rep=3 …`、行数 57 == 独立现算的块边界（`9..66`）。
#      (c) **无块 ⇒ `NOINFO`（不是 `PASS`）**：删掉未降级块头 ⇒ 落到下一可识别块头（远古 `#18`）⇒ `NOINFO reason=frozen-block-has-no-COLUMN-FLOOR-line` rc=2；把**所有**未降级块头都删掉 ⇒ `NOINFO reason=baseline-has-no-RE-FROZEN-block` rc=2。两档**都**是 `NOINFO`，**没有** `PASS`。
#      (e) **出口锚的域必须自证**（主控附加条件 ①②）：下一块块头换成第三种装饰 ⇒ `NOINFO rc=2` ∧ 机读行**点名** `reason=block-header-form-mismatch` ＋ `form_mismatch=yes`；把**除当前块外**每一条块头都换成第三种装饰（向后**没有**可识别块头）⇒ `NOINFO reason=block-end-not-found`（**绝不把 EOF 当块尾**）。**旧件在同一档给 `COLUMN_FLOOR=PASS rc=0`** ⇒ 这条守卫把"静默的形状完好假读数"变成**响亮的 `NOINFO`**。
#      四腿**同时**做进 `--selftest`（主控附加条件 ③）：新增 `C0731a/b/c/e/f/g/h` 共 **8 例**，`--selftest` **26 → 34 例全 PASS ∧ rc=0**，既有 26 例**逐行逐字不变**（`diff` 空）。
#   【③ 判据与两极化（`TASK-0730`；仓外冻结器，**沙箱排练**）】`--prev-check-only '#72' --baseline <沙箱副本>`：
#      正极 `PREVCHECK=PASS gen=#72 keys=7`（7 个 `prev_*` 来源**命中数全 1**，`BASELINE tier=` 三键 agree=yes）rc=0；
#      反极三个错值档（`prev_pf` 填 `#67` 事故里那个值 `cbd1884faeb4837e`／`prev_infp` 填上一代值／`prev_wsh` 填更早的值）**全部** `PREVCHECK=REFUSE … MISMATCH` rc=2；
#      另两档：更老代（`#71`，其上一代块缺 `inputs_fp` 形态）⇒ `REFUSE baseline-has-no-#70-block` rc=2；九位行复制两遍 ⇒ `REFUSE 九位行命中 2 条` ＋ 5 个键 `HITS!=1`（**不许静默取第一**）rc=2。
#      **基线件零字节改动**：上述**每一档**跑完现算副本 sha16 = `cc814b708c141ae8`，与跑前**逐位相同**（`绝不动真基线`）。
#   【④ 链条】整波（`~/heavy-slot.sh` 内）→ 门禁 ×2 → 冻前 `verify-all`（期望全绿）→ 冻结 → **冻后 ×2** → `w72-POST.done`（真 `stat`）→ 逐径推送（**排除主控五件**）→ app-local（`STALE=0 ∧ DIVERGENT=0`）→ 两哨兵补 `BASELINE=#72` ＋ 新 `BASELINE_SHA16` 并 `cmp` 验 `IDENTICAL`。
#      日志一律 `~/w170a/w72/logs/`（链日志头现取 `df -m` 余量）。
#   【⑤ 覆盖面位移**逐件归因**】`192 → 192`（**不加不减行**）；`inputs_fp` 变（`5b92204468d65d7694b0b462500287e46e6e25debf0a4d5ddb559a6295e29ea4` → `999791b4d88a6389e9215b3b882134002bab896965af71b6c06efa892e39a891`）**唯一**成因 = `build/MilBridge/tools/column-floor-check.sh` 在覆盖面内（`close-wave.sh:263`）⇒ **仅 1 件**；`verify-all.sh` **不在**覆盖面（`--expect 192` 那个声明常数**不动**，因为件数没变）。
#   【⑥ 零产品改动】**`src/**`／`build/shims/**`／native 源、`verify-all.sh`／`close-wave.sh` 一字节未动** ⇒ 九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸 6123520 B**）⇒ 机械位移。**停条件**：出现**第二处**位移（或 `pf` 没动）⇒ 停手报主控。
#   【⑦ 自伤（如实留档）】① 补丁第一次用 `\uXXXX` 转义写装饰符号，**转义码猜错**（`\u29d6` ≠ `⏪` U+23EA）⇒ `--selftest` 新增档的 fixture **没造出来**，而那一档当时**照样报 `NOINFO rc=2`（假绿！）** ⇒ 当场改成"按形状找降级块头 ＋ 断言 fixture 非空 ＋ 点名病因"，并补了"两侧计数都必须 `>0`"的断言；② 沙箱里第一次跑 `--selftest` 失败，根因是**工具的 `--selftest` 包装层在 `while` 参数循环里 `shift` 过 ⇒ `"$@"` 已空**、`--root` 传不进内层（既有行为，非本波引入）⇒ 改用 `CFC_ROOT` 环境变量在沙箱里指根；③ 探路阶段把"含该字样的行"也当成块头，导致**自己第一次数块**数错（`0 块有正文命中`）—— 这正是本件要修的病，已如实记。
#   【⑧ 推送／app-local／哨兵】逐径 `git add`（**绝不** `-A`／不从 `git status` 生成清单）；**必须排除主控五件**；`BYTECHECK ok=<N> mismatch=0`（逐件比 `$R` vs 克隆 `HEAD:` blob 字节）。
#   【⑨ 内存／进程】重活一律 `~/heavy-slot.sh --min-avail 1500 --max-hold <N> --wait 3600`；`MAXHOLD_KILL`／`NOINFO low-memory` 那趟**作废、不是读数**；收进程**只按 PID**（禁 `pkill`／`pgrep -f`），查存活用 `ps -o pid= -p <PIDs>`（**不加 `-e`**）。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:147aac2dbbc6a0d8,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w170a/w72/gate/gate-r2
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:147aac2dbbc6a0d8,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w170a/w72/gate/gate-r2
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:147aac2dbbc6a0d8,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w170a/w72/gate/gate-r2
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:147aac2dbbc6a0d8,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w170a/w72/gate/gate-r2
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:147aac2dbbc6a0d8,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w170a/w72/gate/gate-r2
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:147aac2dbbc6a0d8,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w170a/w72/gate/gate-r2
# ⏪ **（历史，已被 `#72` 取代）**# RE-FROZEN #71 —— ✅ **当前冻结基线** —— 内容 = 「**覆盖面与前置检查**」落仓（`TASK-0729` ＋ `TASK-0727`）：① `build/MilBridge/tests/PtsPagesProbe/` 的**装置 4 件 ＋ `evidence/` 16 件共 20 件**收进 `build/close-wave.sh` 的 `fp_inputs()` 覆盖面（`coverage_n` **172 → 192**；此前只有 `pts-pages-guard.sh`（判据件）与 `run-pts-pages-legs.sh`（装置入口）两件在名单里 ⇒ 改其余 20 件**零机器红** ＝ 第 `[38]` 步 `PTS-PAGES` 的**判据输入不受指纹保护**）；② `close-wave.sh` 的 `[0/6]` 前置检查改**按可执行件名**判（旧判据 `pgrep -af "$APP_PROBE_RE"` 比的是**整条命令行文本** ⇒ 一条**只是提到**该模式的旁观 shell 就能**假阳挡波**，`#66` 现场 `18:42:45`）。**本波零产品位移**（不改任何产品件；九位里只有环成员 `pf` 变）。
#   ① **覆盖面 `fp_inputs()` +20 行**（**第六手**：`#66` → 163、`#67` → 165、`#68` → 167、`#69` → 171、`#70` → 172）：`build/close-wave.sh` **`6297e03253232b39` → `247cb3d16e2a5392`**（41,471 → 52,186 B）。**逐件归因**（20 件，`sha16` 见 `docs/WAVE71-PREREGISTRATION.md` §5）：`session_inner.sh`／`navclick.py`／`legs-to-env.py`／`shotstat.py`（装置四件）＋ `evidence/` 十六件（`app_g1.log`／`device.txt`／`session.txt`／`leg_23.env`／`leg_24.env`／`arm_A/{device.txt,leg_23.env,leg_24.env}`／`device/{xvfb.log,xfwm.log}`／`five_pre_g1.txt`／`five_post_g1.txt`／`shots/g1/{boot,k23,k24,last}.png`）⇒ `coverage_n` **172 → 192**。⚠️ `evidence/device/xvfb.log`＝**0 B 合法**（存在性判据只查"存在 ∧ `sha256sum` `stderr` 空"；**不许**为"看着干净"删空件）。
#   ② **同趟必改的声明常数**：`verify-all.sh` **`93ae21cdaf712567` → `d5829ded84c7adb3`**（147,267 → 149,949 B）—— 第 `[42]` 步 `FP-MANIFEST-TEETH` 的 `--expect 172` → **`--expect 192`**。`verify-all.sh` **不在**覆盖面（现场 `hit=0`）⇒ 该常数与生产路径**无关**，是牙头推荐的唯一来源；**漏改 ⇒ 当场 `FAIL reason=files-n-mismatch files_n=192 expect=172 delta=20`**（方向安全）。现测成对读数：`--expect 172` ⇒ `PASS`；`--expect 171` ⇒ `FAIL delta=1`；`--expect 192`（未同趟改覆盖面时）⇒ `FAIL delta=-20`。
#   ③ **前置检查改按可执行件名**（`TASK-0727`；`D-G34` 的残余）：三面**写死**在 `close-wave.sh` 里 —— 面① `/proc/<pid>/exe` **基名** ＝ 应用本体（`WpfTextDemo`／`WpfFeatureProbe`，apphost 被直接执行）；面② `argv[0]` 是 `dotnet` 族 ∧ **被执行的那一项**（`argv[1]`；`argv[1]=exec` 时取 `argv[2]`）基名 ＝ 应用程序集（`WpfTextDemo.dll`／`WpfFeatureProbe.dll`），或 `argv[0]` 是 shell ∧ `argv[1]` 基名 ＝ 启动器脚本名；面③ `exe` 是 `dotnet` 族而 `argv` **判不了**（为空／读不到）⇒ `cap=1`／`undecidable=<n>`、机读行转 `NOINFO`。**机读行**（每次 `[0/6]` 都印）：`APP_PROBE_GUARD=<PASS|BLOCK|NOINFO…> faces=3 face3=cap cap=1 examined=<n> hits=<n> undecidable=<n>`。⚠️ **枚举写成 `/proc/<pid>/…` 字面路径**是为了**被第 `[27]` 步 `PROC-PATTERN-GUARD` 看见**（写成 `$d/cmdline` 时那条牙**看不见**本行 ⇒ "靠看不见过关"的假绿形态）；靠 `self_chain_pids` 的**祖先链证明**取 `full`。
#   ④ **四处声明同趟**（**不动步数**形态）：`# VERIFYALL-STEPS-DECL: 42 gen=#71`（**插在现行第一行 DECL 之前** —— `decl_line()` 是 `sed … | head -1`，`D-G131`）／`# VERIFYALL-STEP-NAMES: …` **一字不改**（本波**不加步**）／头注释口径句 `**\`#71\` 收官起 = 42 步**`／本文件（新建，标题含 `#71`）。
#   ⑤ **两份新件**：`docs/WAVE71-PREREGISTRATION.md`（**新建** `c41d0a362ba6eec9`，13,647 B）。⚠️ 本波**不新建任何牙／驱动件**（两件改动都在既有件里）：`TASK-0729` 只加白名单行，`TASK-0727` 只改既有前置检查块。
#   ⑥ **覆盖面转移的复算口径**：`172（`#70` 收官值，现取成员表 172 行）＋ 20 ＝ 192`；影子沙箱（**真拷贝**、`%h==1`）先证**保真**（改前 `close-wave.sh` ＋ 退回 20 件 ⇒ 指纹逐位 `== 0e8254f8cf842836396a8dcdc7568bfaad59fdbaaf0ee358f682d5e3cda7edd2` ＝ 现树值 ∧ 成员 172），再由**逐件成对归因**（20/20：去一件 ⇒ 必变；还原 ⇒ 逐位回到前值）、**覆盖面内改动必变**、**覆盖面外改动不变**、**病／修成对**（同一腿删掉 `evidence/leg_23.env`：改前 `PASS coverage_n=172`（**看不见**）／改后 `FAIL missing_n=1 coverage_n=192`（**看见并点名**））逐条钉住。
#   ⑦ **落地前写死的指纹预测**（`J0`，两版都留档）：本波整波自印 `inputs_fp` = `5b92204468d65d7694b0b462500287e46e6e25debf0a4d5ddb559a6295e29ea4`；第一版预测 `d1d2d3306a9bb39d1c11973ab5c7f58319a366f269c6a2e0e3e12f4f7969c453` 由**修前**补丁算出，被 `P2` 腿当场咬出 census 件**一格一行 vs 一行三格**的解析缺陷（`IFS='=' read` 把第一格之后的内容全塞进 `v` ⇒ 机读行印成 `examined=143 hits=0 undecidable=0 hits=0 undecidable=0` 的**畸形读数**）⇒ 更正后重算为 **`5b92204468d65d7694b0b462500287e46e6e25debf0a4d5ddb559a6295e29ea4`**（实测逐位相符）。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`／`pf` `e9fe77a43f950f2c`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `fc60c34d51fd9247`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#70` 冻结值**：`pf` `bea7e47e42fd4e01` → `e9fe77a43f950f2c`（**环成员**，`D-G92`：整波重建必变、同尺寸）；其余八位**逐位未变**。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   ⚠️ **九位只许从最新冻结块的九位行或 `BASELINE tier=` 机读行取**（`D-G119` 实例㉕）。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落仓（**owner = 本车道**；写前逐件 `stat -c %h==1` 断言、temp＋`mv` 原子替换、写后现算 sha16）】3 件：
#      `build/close-wave.sh`（`6297e03253232b39` → **`247cb3d16e2a5392`**，41,471 → 52,186 B；覆盖面 +20 行 ＋ 前置检查三面）／
#      `verify-all.sh`（`93ae21cdaf712567` → **`d5829ded84c7adb3`**，147,267 → 149,949 B；`--expect 192` ＋ 新 `DECL` ＋ 口径句）／
#      `docs/WAVE71-PREREGISTRATION.md`（**新建** `c41d0a362ba6eec9`）。
#      **未碰** `KNOWN-DEFECTS.md`／`ROUTES.md`／`HANDOFF-NEXT.md`／`FORK-AND-PUSH.md`／`defect-registry-declared.tsv`（主控五件）与任何产品件。
#      备份 = `~/w169a/w71/old/close-wave.sh`（改前真拷贝 `6297e03253232b39`）＋ `~/w169a/w71/sbxrepo.old/verify-all.sh`（改前真拷贝 `93ae21cdaf712567`）＋ 基线件 `B.pre-freeze.#71.bak`（`cp -a`，非硬链接；逐件 `%h==1` 已断言）。
#   【② 判据与两极化（**真树 ＋ 影子沙箱上全部真跑**，非重活）】见 `~/w169a/w71/logs/{polarity-fp.log,polarity-proc.log,polarity-app.log}`：
#      ① 声明链：`VERIFYALL_SELF=PASS names=42 decl=42 gen=#71 dup=0 order=OK prose=OK prereg=PASS`；
#      ② 真不变量：**首行 `DECL` = 42 == 现取 `grep -c '^run_step "'` = 42**（⚠️ `DECL` 行数 = 38 ≠ 42，**没写那条假断言** —— 纪律 46）；
#      ③ `TASK-0729` **影子保真**：改前 `cw` ＋ 退回 20 件 ⇒ 指纹逐位 `== 0e8254f8…`（成员 172）⇒ 影子是现树的**忠实**影子；
#      ④ `TASK-0729` **逐件成对归因 20/20**：去一件 ⇒ 指纹必变；还原 ⇒ 逐位回到 `J0` 前值（**没有第三隐形位移**）；
#      ⑤ `TASK-0729` **覆盖面内改动必变**（新收件与原有件各一档）／**覆盖面外新增不变**（成员仍 192，指纹逐位不变）；
#      ⑥ `TASK-0729` **病／修成对**（**只换本波改动**，同一腿删 `evidence/leg_23.env`）：改前 `FP_INPUTS_HYGIENE=PASS coverage_n=172`（**证据件消失而门禁全绿 ＝ 病**）／改后 `FAIL reason=coverage-member-missing missing_n=1 coverage_n=192`（**看见并点名**）／还原 ⇒ 回绿；
#      ⑦ `TASK-0727` **假阳腿（真进程）**：真 `bash -c` ＋ heredoc 正文提到 `WpfFeatureProbe`／`WpfTextDemo`（`#66` 现场同形，`exe=bash`）⇒ 新判据 `rc=0` ∧ `APP_PROBE_GUARD=PASS … examined=145 hits=0 undecidable=0`；**旧码对照腿（同一旁观进程、只换被判件）**⇒ 改前副本**内容锚抽原文原样跑**的旧判据 `rc=3` ∧ 点名该 pid（**假阳性挡波的现场复现**）；
#      ⑧ `TASK-0727` **真阳腿（真应用进程）**：真 apphost `samples/WpfFeatureProbe/bin/Debug/net10.0/WpfFeatureProbe`（私有 `:233`、走 `~/heavy-slot.sh`、真跑）⇒ `rc=3` ∧ `APP_PROBE_GUARD=BLOCK faces=3 face3=cap cap=1 examined=148 hits=1 undecidable=0` ∧ 点名 `pid=285075 app face=exe exe=WpfFeatureProbe`；
#      ⑨ 面③ 判据可见性：`cap=1`／`face3=cap`／`undecidable=` **在机读行里**；分类器单测含 K16 形态（`exe=dotnet` ∧ `argv` 空 ⇒ `cap`）；**真 `close-wave.sh` 跑的三趟现场 `undecidable=0`**；
#      ⑩ 牙的自证（**成对，只换本波改动**）：第 `[27]` 步 `PROC-PATTERN-GUARD` —— 改前 `form=P2 pgrep`／改后 **`form=PROC verdict=full proof=ancestor-chain via-helper:self_chain_pids`**，两臂都 `PASS`；`QUOTE-TRAP traps=0`（两臂同读数）；`PIPEFAIL-SIGPIPE undeclared_hit=0`（两臂同读数）；
#      ⑪ 预登记：`prereg-four-requirements-check.sh` 判 `PREREG4=NA rc=0`。
#   【③ 重锚（基点现取）】落仓第一步现取：`verify-all.sh 93ae21cdaf712567`（首行 DECL `42 gen=#70` ∧ `^run_step "` = 42 ⟹ **真不变量成立**）；`build/close-wave.sh 6297e03253232b39`；
#      覆盖面成员表 **172** 行；`inputs_fp=0e8254f8cf842836396a8dcdc7568bfaad59fdbaaf0ee358f682d5e3cda7edd2`；落仓后现取 `coverage_n=192` ∧ `inputs_fp=5b92204468d65d7694b0b462500287e46e6e25debf0a4d5ddb559a6295e29ea4`（**与落地前预测 `J0` 逐位相符**）。
#   【④ 整波】`close-wave.sh --skip-verify-all`（槽内，`rc` 见 `~/w169a/w71/logs/w71-wave-*.log`）：`[0/6]` 前置检查现取 `APP_PROBE_GUARD=PASS faces=3 face3=cap cap=1 examined=144 hits=0 undecidable=0`（**本波自己的波**：新判据**没有**假挡；这正是 `TASK-0727` 的验收面）。
#   【⑤ 门禁 ×2 ＋ 冻前 `verify-all`】**三趟各** `步骤通过 42 ❌ 失败 0` ∧ `结论：✅ 全部通过` ∧ `用例通过 875 跳过 2`；
#      应用级门禁两趟判词行逐字相同（`GATE_LINES_IDENTICAL`）＋ `BASELINE … result=PASS` 行（`rows` 口径）见下。
#   【⑥ 覆盖面位移**逐件归因**】`172 → 192`：新增 **20 行**（逐件列见本块 ①与预登记 §5），**没有第二处位移**。
#      `inputs_fp` **变**（`0e8254f8cf842836396a8dcdc7568bfaad59fdbaaf0ee358f682d5e3cda7edd2` → `5b92204468d65d7694b0b462500287e46e6e25debf0a4d5ddb559a6295e29ea4`）的成因三处、都已归因：① 白名单 `+20` 行；② 覆盖面成员 `close-wave.sh` **本波被改**（**设计性**：本函数自含自身）；③ 新增件的**内容**进哈希。⚠️ `verify-all.sh` **不在**覆盖面 ⇒ 它被改**不**影响 `inputs_fp`（现场 `hit=0` 机械证）。
#   【⑦ 零产品改动】**`src/**`／`build/shims/**`／native 源一字节未动** ⇒ 九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸 6123520 B**）⇒ 机械位移，**不许当漂移/回归判据**。
#      **停条件**：出现**第二处**位移（或 `pf` 没动）⇒ **停手报主控**。
#   【⑧ 自伤（如实留档）】① **census 件格式错**：`APP_PROBE_UNDEC` 等计数原写成**一行三格**（`examined=… hits=… undecidable=…`），而读取端是 `IFS='=' read -r k v` ⇒ `v` 被塞成 `"143 hits=0 undecidable=0"`、机读行印成**畸形读数**；**被本波自己的 `P2` 腿当场咬到**（现场 `examined=143 hits=0 undecidable=0 hits=0 undecidable=0`）⇒ 改**一件一行**并**重算 `J0` 预测**（两版都留档）。教训：**机读行的形状要当场读一遍**，不能只信"变量算对了"。
#      ② **旁观进程形状假**：第一次用 `nohup bash -c '…'; sleep 300` 起旁观进程时，bash 把最后一条命令 **exec** 掉 ⇒ 进程映像被替换成 `sleep 300`、cmdline 里**没有** heredoc 正文 ⇒ `P3` 判成"旧码没假阳"（**假读数**）。修法＝尾随一个**内建命令**（`:`）阻断 exec 优化，并在起进程后**当场断言 cmdline 含模式**。教训：**"用真进程演示"必须核进程形状**。
#      ③ **落仓后才发现基点断言失效**：`mkpatch.py` 原本从 `$R` 读改前件，落仓后 `$R` 已是改后件 ⇒ 断言失败；改为从**改前归档真拷贝**读 ⇒ 生成过程**可复现**（车位里不再依赖 $R 的当下状态）。
#   【⑨ 推送／app-local／哨兵】逐径 `git add`（**绝不** `-A`／不从 `git status` 生成清单）；**必须排除主控五件**；`BYTECHECK ok=<N> mismatch=0`（逐件比 `$R` vs 克隆的 `HEAD:` blob）；app-local 报 `STALE=0`／`DIVERGENT=0`；两处哨兵（`/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag`）补 `BASELINE=#71` 与 `BASELINE_SHA16=<新值>` 并 `cmp` **IDENTICAL**。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:e9fe77a43f950f2c,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w169a/w71/gate/gate-r2
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:e9fe77a43f950f2c,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w169a/w71/gate/gate-r2
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:e9fe77a43f950f2c,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w169a/w71/gate/gate-r2
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:e9fe77a43f950f2c,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w169a/w71/gate/gate-r2
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:e9fe77a43f950f2c,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w169a/w71/gate/gate-r2
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:e9fe77a43f950f2c,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w169a/w71/gate/gate-r2
# ⏪ **（历史，已被 `#71` 取代）**# RE-FROZEN #70 —— ✅ **当前冻结基线** —— 内容 = **`TASK-0724` ＋ `TASK-0728` 落仓**（「清单/指纹要有牙」）：把 `#65` 落仓、却**从未被任何一步调用**的指纹清单牙 `build/MilBridge/tools/fp-manifest-teeth-check.sh` **接进门禁**（新步 `[42]`），并把「`fp_inputs()` 白名单**每一行都真存在**」做成**硬判据**（**折叠进既有第 `[12]` 步**，不另开步）。**本波零产品位移**（不改任何产品件；九位里只有环成员 `pf` 变）。
#   ① **新步 `[42] FP-MANIFEST-TEETH`**（`verify-all.sh` **`cc675e85d1b42c62` → `93ae21cdaf712567`**，141,337 → 147,267 B）：`run_step "FP-MANIFEST-TEETH" bash build/MilBridge/tools/fp-manifest-step.sh --expect 172` —— 驱动件以**内容锚**（`sed -n '/^fp_inputs()/,/^}/p'`）抽出 `close-wave.sh` 的 `fp_inputs()` **函数体原文**并**原样执行**，用 `PATH` 前置的同名 `sha256sum` shim 收 **`xargs` 真正交给 `sha256sum` 的那张名字表**（`xargs` 是 `exec`、看不见 shell 函数 ⇒ 只能从 `PATH` 拦），再以**生产同形**命令 `LC_ALL=C xargs sha256sum` 产出**活清单**交给牙；四条守卫（抽得出／**拦截不扰动**（拦截指纹==无拦截指纹）／名字表非空／`stderr` 空 ∧ 清单行数==名字数）任一不过 ⇒ **一律非零**（宁可不判、不许假绿）；牙**自带 `--selftest` 13/13** 也同趟跑（证"装置还活着"）。
#   ② **`TASK-0728` 折叠进第 `[12]` 步**（`FP-INPUTS-HYGIENE`；**不另开步**）：`build/MilBridge/tools/fp-inputs-hygiene-check.sh` **`68ef01bfb9c6a8ee` → `5b0b0f4898865e04`** —— 同趟加上**集合完整性**两条硬判据：**逐行 `-e ∧ -f`** ∧ **`sha256sum` 的 `stderr` 必须为空**；触发时**逐条点名**（`FP_INPUTS_HYGIENE_MISSING=FAIL kind=MISSING|NOT-REGULAR path=…`）**并把旧口径本会给出的那个形状完好的 64-hex 假指纹当场印出来**（`would_be_fp=`）。**为什么折叠、不落参考件**：本件已握有**被 `cmp` 机器证过完备**的权威成员表（`sha256sum` 的 `argv`），另起一件就必须**再抽一次覆盖面** ⇒ 正是本仓明令「**同一份逻辑存在两处必然分叉**」；且参考件 `~/w164a/w70/fp-inputs-existence-check.sh`（`906153a9db4f9164`，**实测未截断**）自带两条继承缺陷（车道名环境变量 `W164A_R`；临时件落**共享 `/tmp` 固定名**）⇒ **记为"已被取代、不落仓"**。`--selftest` 由 **16 例**加到 **18 例**（新增 `S10` 缺件必红 ＋ `S11` 只去掉那一行 ⇒ 回绿，成对）。
#   ③ **四处声明同趟**：`# VERIFYALL-STEPS-DECL: 42 gen=#70`（**插在现行第一行 DECL 之前** —— `decl_line()` 是 `sed … | head -1`，`D-G131`）／`# VERIFYALL-STEP-NAMES: … | FP-MANIFEST-TEETH`／头注释口径句 `**\`#70\` 收官起 = 42 步**`／本文件（新建，标题含 `#70`）。
#   ④ **两份新件**：`build/MilBridge/tools/fp-manifest-step.sh`（**新建** `db4a2d9856534aba`，纯读、零 `dotnet`、单趟 ≈0.4 s）／`docs/WAVE70-PREREGISTRATION.md`（**新建** `47ca5a9993771386`）。
#   ⑤ **覆盖面 `fp_inputs()` +1 行**（**第五手**：`#66` → 163、`#67` → 165、`#68` → 167、`#69` → 171）：`build/close-wave.sh` **`3b891df8317b1f7c` → `6297e03253232b39`**（白名单尾追加 `build/MilBridge/tools/fp-manifest-step.sh`）⇒ `coverage_n` **171 → 172**。**逐件归因**：唯一新件就是那行驱动件；`verify-all.sh` **不在**覆盖面（现场 `hit=0`）⇒ 常数 `--expect` 与生产路径**无关**。
#   ⑥ **`--expect 172` 的维护契约**：该常数**手写在步本体里**，与覆盖面**同趟**改；**漏改 ⇒ 第 `[42]` 步红 `files-n-mismatch delta=±k`**（方向安全）。**为什么不用 `tee`/`--paths`**：那要动 `close-wave.sh` 的 `fp_inputs()` 本体（`tee` 一个清单文件）⇒ 多一处写点、且把"清单来源"与"被审对象"绑死；`--expect` 是牙头**推荐**的、**与生产路径无关**的唯一来源。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`／`pf` `bea7e47e42fd4e01`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `fc60c34d51fd9247`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#69` 冻结值**：`pf` `4143bf4f50a7eba1` → `bea7e47e42fd4e01`（**环成员**，`D-G92`：整波重建必变、同尺寸）；其余八位**逐位未变**。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   ⚠️ **九位只许从最新冻结块的九位行或 `BASELINE tier=` 机读行取**（`D-G119` 实例㉕）。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落仓（**owner = 本车道**；写前逐件 `stat -c %h==1` 断言、先备份、temp＋`mv` 原子替换、写后现算 sha16）】4 件：
#      `verify-all.sh`（`cc675e85d1b42c62` → `93ae21cdaf712567`，141,337 → 147,267 B）／`build/close-wave.sh`（`3b891df8317b1f7c` → `6297e03253232b39`）／
#      `build/MilBridge/tools/fp-inputs-hygiene-check.sh`（`68ef01bfb9c6a8ee` → `5b0b0f4898865e04`；折叠 `TASK-0728`）／
#      `build/MilBridge/tools/fp-manifest-step.sh`（**新建** `db4a2d9856534aba`）／`docs/WAVE70-PREREGISTRATION.md`（**新建** `47ca5a9993771386`）。
#      **未碰** `KNOWN-DEFECTS.md`／`ROUTES.md`／`HANDOFF-NEXT.md`／`FORK-AND-PUSH.md`／`defect-registry-declared.tsv`（主控五件）与任何产品件。
#      备份 = `~/w168a/w70/backup/{verify-all.sh,close-wave.sh,fp-inputs-hygiene-check.sh}`（`cp -p` 真拷贝，非硬链接；逐件 `%h==1` 已断言）。
#   【② 判据与两极化（**落地前/落地后在真树与沙箱副本上全部真跑**，非重活）】**16/16 腿全绿**（`~/w168a/w70/logs/polarity-70.log`）：
#      ① 声明链：`VERIFYALL_SELF=PASS names=42 decl=42 gen=#70 dup=0 order=OK prose=OK prereg=PASS`；
#      ② 真不变量：**首行 `DECL` = 42 == 现取 `grep -c '^run_step "'` = 42**（⚠️ `DECL` 行数 = 38 ≠ 42，**没写那条假断言** —— 纪律 46）；
#      ③ `[42]` 正极 `rc=0`／`FP_MANIFEST_TEETH=PASS reason=ok files_n=172 files_n_uniq=172 blank_n=0 shape_bad=0`／驱动 `names_n=172 manifest_n=172 expect=172 sha256sum_stderr_bytes=0`；
#      ④ `[42]` **反极 A（只换被判件）**：续行参数表中间插一行 `#` 注释（`D-G120` 真咬形态）⇒ `rc=1`／`files-n-mismatch files_n=141 expect=172 delta=-31`／**当场印出形状完好的假指纹**；
#      ⑤ `[42]` **反极 A′（只换被判件，异物灌进管线）**：断开续行并插 `printf '%s\n' BASELINERATE=NOINFO` ⇒ `rc=1`／`sha256sum-stderr-nonempty stderr_bytes=60`／`manifest_n=141 ≠ names_n=142`；
#      ⑥ `[42]` **反极 B（只换声明常数）**：`--expect 173` ⇒ `rc=1`／`files-n-mismatch files_n=172 expect=173 delta=-1`；
#      ⑦ `[42]` **反极 C**：`--close-wave` 指向不存在的件 ⇒ `NOINFO reason=close-wave-missing rc=2`；覆盖面为空 ⇒ `NOINFO reason=manifest-empty rc=2`（**两档都不算绿**）；
#      ⑧ `[12]` 正极 `FP_INPUTS_HYGIENE=PASS reason=clean coverage_n=172 artifact_n=0 missing_n=0 stderr_bytes=0`、`rc=0`；
#      ⑨ `[12]` **反极（沙箱副本，真树白名单一字未改）**：某行指向不存在的件 ⇒ `rc=1`／`reason=coverage-member-missing missing_n=1`／**逐条点名** `FP_INPUTS_HYGIENE_MISSING=FAIL kind=MISSING path=build/MilBridge/GONE-70.cs`／**并印出旧口径的假指纹** `would_be_fp=0e8254f8cf842836`（**恰等于当时树上的 `inputs_fp`** ⇒ 旧口径会拿它当绿）；
#      ⑩ 成对回绿：只把那一行去掉 ⇒ `rc=0`／`missing_n=0 stderr_bytes=0`；
#      ⑪ 牙自测：`fp-manifest-teeth-check.sh --selftest` **13/13**、`fp-inputs-hygiene-check.sh --selftest` **18/18**（含新 `S10`/`S11` 成对腿与 `SB-no-tmp-leak`）；
#      ⑫ 预登记：`prereg-four-requirements-check.sh` 单件与批次门禁形态**都**判 `PREREG4=NA rc=0`（`fail=0`）。
#   【③ 重锚（基点现取）】落仓第一步现取：`verify-all.sh cc675e85d1b42c62`（首行 DECL `41 gen=#69` ∧ `^run_step "` = 41 ⟹ **真不变量成立**）；
#      `build/close-wave.sh 3b891df8317b1f7c`；`FPHYG_COVERAGE_N=171`；落仓后现取 `coverage_n=172` ∧ `inputs_fp=0e8254f8cf842836396a8dcdc7568bfaad59fdbaaf0ee358f682d5e3cda7edd2`。
#   【④ 整波】`close-wave.sh --skip-verify-all`（槽内，`rc` 见 `~/w168a/w70/logs/w70-wave-*.log`）。
#   【⑤ 门禁 ×2 ＋ 冻前 `verify-all`】**三趟各** `步骤通过 42 ❌ 失败 0` ∧ `结论：✅ 全部通过` ∧ `用例通过 875 跳过 2`；
#      应用级门禁两趟判词行逐字相同（`GATE_LINES_IDENTICAL`）＋ 6 条 `BASELINE … result=PASS` 行（`rows` 口径）见下。
#   【⑥ 覆盖面位移**逐件归因**】`171 → 172`：**唯一**新增行 = `build/MilBridge/tools/fp-manifest-step.sh`。
#      `inputs_fp` **变**（`9ccc8f33404c0ee7ebcf2353a042498197a40505b5be87f621499c822ec6d4be` → `0e8254f8cf842836396a8dcdc7568bfaad59fdbaaf0ee358f682d5e3cda7edd2`）的成因两处、都已归因：① 白名单 `+1` 行；② 覆盖面成员 `close-wave.sh` 与 `fp-inputs-hygiene-check.sh` **本波被改**（两者都在白名单内 ⇒ **设计性**，不是隐形位移）。
#      `[42]` 步自印的 `would_be_fp` 与现场 `inputs_fp` **逐位相同** ⇒ **本步审的那份清单就是生产输入集**（交叉证）。
#   【⑦ 零产品改动】**`src/**`／`build/shims/**`／native 源一字节未动** ⇒ 九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸 6123520 B**）⇒ 机械位移，**不许当漂移/回归判据**。
#      **停条件**：出现**第二处**位移（或 `pf` 没动）⇒ **停手报主控**。
#   【⑧ 两处自伤（如实留档）】① **拼接漏换行**：给 `verify-all.sh` 插 `[12]` 步说明注释时，`NOTE12 + anchor` 少了分隔 `\n` ⇒ **把接线的 `run_step "FP-INPUTS-HYGIENE" …` 行吞进了注释**；**当场被步数不变量抓住**（`grep -c '^run_step "'` 从 42 掉到 41）⇒ 补 `\n` 修复。教训并入：拼接类操作必须**断言分隔符**，不只断言命中数（`D-G120` 同族）。
#      ② **双引号里的反引号**：`fp-inputs-hygiene-check.sh` 的 FAIL 词句里写了 `` `sha256sum` ``／`` `D-G120` `` ⇒ bash **真做了命令替换**（现场 `D-G120: 未找到命令`、诊断文字被吃掉）。**这与 `#69` 被 `[21] QUOTE-TRAP` 抓到的形态同族**；本波我自查修掉（`traps=0`），未等门禁来抓。
#   【⑨ 推送／app-local／哨兵】逐径 `git add`（**绝不** `-A`／不从 `git status` 生成清单）；**必须排除主控五件**；`BYTECHECK ok=<N> mismatch=0`（逐件比 `$R` vs 克隆的 `HEAD:` blob）；app-local 报 `STALE=0`／`DIVERGENT=0`；两处哨兵（`/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag`）补 `BASELINE=#70` 与 `BASELINE_SHA16=<新值>` 并 `cmp` **IDENTICAL**。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:bea7e47e42fd4e01,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w168a/w70/gate/gate-r2
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:bea7e47e42fd4e01,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w168a/w70/gate/gate-r2
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:bea7e47e42fd4e01,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w168a/w70/gate/gate-r2
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:bea7e47e42fd4e01,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w168a/w70/gate/gate-r2
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:bea7e47e42fd4e01,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w168a/w70/gate/gate-r2
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:bea7e47e42fd4e01,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w168a/w70/gate/gate-r2
# ⏪ **（历史，已被 `#70` 取代）**# RE-FROZEN #69 —— ✅ **当前冻结基线** —— 内容 = **`TASK-0725` 落仓**：把 `D-G126` 前半句与 `D-G127` 两条**会红的牙**接进 `verify-all` 第 `[40]`／`[41]` 步 ＋ 四处声明 ＋ `fp_inputs()` 四行。**本波零产品位移**（不改任何产品件；九位里只有环成员 `pf` 变）。
#   ① **新步 `[40] BAK-COMPLETENESS`**：`run_step "BAK-COMPLETENESS" bash build/MilBridge/tools/bak-completeness-step.sh` —— 驱动件同时做两件事：跑 `D-G126` 牙的 `--selftest`（8 腿：正例 ＋ 反例A 备份缺失／反例B 备份错版本／**反例C 备份是硬链接**／零检查空 plan 必须红）**＋** 求值本波 `producer=UNWIRED-IN-STEP` 声明的**可跑谓词**（`n_wired = grep -E '^[[:space:]]*run_step .*backup-completeness-gate\.sh.*--plan' verify-all.sh` ⇒ **`n_wired==0` 才绿**；产出端一旦被接线 ⇒ **当场翻红**）⇒ `D-G132`（声明没有机读读者）**本波就地供给**。三态 `BAK_COMPLETENESS=PASS|FAIL|NOINFO`（`NOINFO` 不算绿）。
#   ② **新步 `[41] REPO-ALIAS`**：`run_step "REPO-ALIAS" bash build/MilBridge/tools/repo-alias-check.sh --allow build/MilBridge/repo-alias-allow.tsv` —— 判「`$R` 内 `%h>1` 的件在**仓外**有没有同 inode 孪生」。🔴 **口径句：允许清单是声明式豁免，不是把牙关掉** —— 白名单**只降 `aliased_out` 一项**、四项计数照打；**未被覆盖的孪生照旧 `FAIL reason=out-of-repo-alias`**；**当前件数 > 上限 ⇒ `FAIL reason=allowed-tree-grown`**（树长大也红）；唯一一种「有孪生还给绿」= 全部覆盖 ∧ 各有界（`reason=known-alias-trees`）。三态 `ALIAS=PASS|FAIL|NOINFO`；**零检查必红**；**扫不完 ⇒ `NOINFO`**（绝不把「没扫完」当「没孪生」）。
#   ③ **四处声明同趟**：`# VERIFYALL-STEPS-DECL: 41 gen=#69`（**插在现行第一行 DECL 之前** —— `decl_line()` 是 `sed … | head -1`，`D-G131`）＋ 头注释口径句 ``**`#69` 收官起 = 41 步**`` ＋ `VERIFYALL-STEP-NAMES` 行尾 `| BAK-COMPLETENESS | REPO-ALIAS` ＋ 预登记 H1。**步数 39 → 41**（`NSTEP=41`）。
#   ④ **新判据件 4 个**：`build/MilBridge/tools/backup-completeness-gate.sh`（`ab73167a2427cbdf`，19,894 B）／`build/MilBridge/tools/repo-alias-check.sh`（`b11e13f8bb024abc`，27,487 B）／`build/MilBridge/repo-alias-allow.tsv`（`5813863882022812`，2,443 B；**每行带「为什么允许」**）／`build/MilBridge/tools/bak-completeness-step.sh`（`8f51bf7dc6b0cf20`，5,236 B）。
#   ⑤ **覆盖面 `fp_inputs()` +4 行**（**第四手**：`#66` → 163、`#67` → 165、`#68` → 167）：`build/close-wave.sh` **`622624a27c8bf6e0` → `3b891df8317b1f7c`**（41,193 → 41,417 B）⇒ **覆盖面 `167 → 171`**。`inputs_fp` = `9ccc8f33404c0ee7ebcf2353a042498197a40505b5be87f621499c822ec6d4be`（`ddf948f39c57213ee9fbd57f3e4538ad5fbc6ad534d157dc43538bfe6a7c0b45` → 本值；归因 = 白名单 **+4 行** ＋ 新增四件**内容**）。
#   ⑥ **两处落仓补丁（以实件为准，**不采**死车道的描述件）**：① `repo-alias-check.sh` = 实件 `eccf5dadb4df5861` ＋ `~/w164a/patches/repo-alias-check.diff`（`--allow` 白名单 ＋ 落点去车道名；`patch rc=0`）—— ⚠️ **开工时的真漂移**：描述件声称牙带 `--allow`，而**实件里 `--allow` 命中 = 0** ⇒ 照它接线本步**在真树上必红**（`aliased_out=6417 rc=1`）⇒ **永远冻不了**；② `backup-completeness-gate.sh` = 实件 `cb0246aab85af2b9` ＋ **去车道名**补丁（备份根／selftest 沙箱默认值不再指向 `~/w163a`，改仓外 `$HOME/.cache/wpf-linux`，仍可 env 覆盖；**判定语义零改动**，自测仍 `legs=8 bad=0`；**现测对 `~/w163a` 零写入**）。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`／`pf` `4143bf4f50a7eba1`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `fc60c34d51fd9247`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#68` 冻结值**：`pf` `ddb412ee7efa4b65` → `4143bf4f50a7eba1`（**环成员**，`D-G92`：整波重建必变、同尺寸）；其余八位**逐位未变**。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   ⚠️ **九位只许从最新冻结块的九位行或 `BASELINE tier=` 机读行取**（`D-G119` 实例㉕）。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落仓（**owner = 本车道**；写前逐件 `stat -c %h==1` 断言、先备份、temp＋`os.replace`、写后现算 sha16）】7 件：
#      `verify-all.sh`（`cf0a4dd317bb48ac` → `cc675e85d1b42c62`，137,887 → 141,337 B）／`build/close-wave.sh`（`622624a27c8bf6e0` → `3b891df8317b1f7c`）／
#      `build/MilBridge/tools/backup-completeness-gate.sh`（**新建** `ab73167a2427cbdf`）／`build/MilBridge/tools/repo-alias-check.sh`（**新建** `b11e13f8bb024abc`）／
#      `build/MilBridge/repo-alias-allow.tsv`（**新建** `5813863882022812`）／`build/MilBridge/tools/bak-completeness-step.sh`（**新建** `8f51bf7dc6b0cf20`）／
#      `docs/WAVE69-PREREGISTRATION.md`（**新建** `24daa7c260aa32c6`）。**未碰** `KNOWN-DEFECTS.md`／`ROUTES.md`／`HANDOFF-NEXT.md`／`FORK-AND-PUSH.md`／`declared.tsv`／`known-red.json`／`integration-wave.sh`（主控写域／未授权）。
#      备份 = `~/w167a/w69/pre/{verify-all.sh.before,close-wave.sh.before}`（`cp -a`，非硬链接；逐件 `%h==1` 已断言）。
#   【② 判据与两极化（**落地前在真拷贝里全部真跑**，非重活）】① 声明链：完整 ⇒ `VERIFYALL_SELF=PASS names=41 decl=41 gen=#69 dup=0 order=OK prose=OK prereg=PASS`。② **白名单两极化（成对，真硬链接 fixture）**：孪生**不在**清单里 ⇒ `ALIAS=FAIL … aliased_unallowed=2 reason=out-of-repo-alias rc=1`；在清单里且**上限==实际** ⇒ `ALIAS=PASS … aliased_unallowed=0 reason=known-alias-trees rc=0`；在清单里但**上限==实际−1** ⇒ `ALIAS=FAIL reason=allowed-tree-grown rc=1` ⇒ **允许清单不是遮羞布**。③ **`UNWIRED` 谓词两极化**：现状 ⇒ `n_wired=0` 绿；沙箱插一条真调用产出端的 `run_step` ⇒ `n_wired=1` **步翻红**。④ `PREREG4=NA rc=0`（判据节内机读行）。⑤ 牙自测：`BCG-SELFTEST=PASS legs=8 bad=0`／`ALIAS-SELFTEST=PASS legs=7 bad=0`。
#   【③ 重锚（基点现取）】落仓第一步现取：`verify-all.sh cf0a4dd317bb48ac`（首行 DECL `39 gen=#68` ∧ `^run_step "` = 39 ⟹ **真不变量成立**）｜`close-wave.sh 622624a27c8bf6e0`｜覆盖面 167｜`inputs_fp ddf948f3…`｜`CURRENT-STATE:9 gen=#68 a51071d05d6d7896`｜`df` ≥ 5 GB 已写进链日志头。⚠️ **`DECL` 行数（现读 35）≠ 步数（现读 39）** —— 本波**不**写「`DECL` 行数 == `run_step` 数」这条断言（纪律 46）。
#   【④ 整波】`close-wave.sh --skip-verify-all`（槽内，rc 见 `~/w167a/w69/logs/w69-wave-*.log`）。
#   【⑤ 门禁 ×2 ＋ 冻前 `verify-all`】**三趟各** `步骤通过 41 ❌ 失败 0` ∧ `结论：✅ 全部通过` ∧ `用例通过 875 跳过 2`；现读：步骤通过 41 ❌ 失败 0｜用例通过 875 跳过 2；`[11]`＝VERIFYALL_SELF=PASS names=41 decl=41 gen=#69 dup=0 order=OK prose=OK prereg=PASS；`[17]`＝PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=88 sites=85 hit=0 low=7 diag=3 safe=75 runs=1；`[12]`＝FP_INPUTS_HYGIENE=PASS reason=clean coverage_n=171 artifact_n=0；`[40]`＝BAK_COMPLETENESS=PASS tooth=PASS n_wired=0 decl_steps=41 obs_steps=41 rc=0；`[41]`＝ALIAS=PASS examined=13768 linked_gt1=6417 aliased_out=6417 aliased_allowed=6417 aliased_unallowed=0 roots=1 maxdepth=16 wall_s=11.96 rc=0 reason=known-alias-trees。
#   【⑥ `UNWIRED` 声明（**本波起有机器读者**）】`producer=UNWIRED-IN-STEP`：`D-G126` 牙的**真用法**（落地前 `--plan` 驱动的完备性判定）**不在门禁** —— 判据口径**限定到代码形状**（`grep -E '^[[:space:]]*run_step .*backup-completeness-gate\.sh.*--plan' verify-all.sh` ⇒ `n_wired=0`），**全文 `grep` 命中只作旁证** ⇒ **不许把 `--selftest` 的 `PASS` 读成「本次落地的每件都真被查过」**。⚠️ 该谓词**由第 `[40]` 步求值**（不是散文）⇒ 产出端被接线的那一天，门禁**当场翻红**（`D-G132` 的本波供给）。
#   【⑦ 覆盖面位移**逐件归因**】+4 = 白名单 4 行（两牙 ＋ 白名单 `tsv` ＋ 步驱动件）＋ 四件**内容**；**无第三处隐形位移**（成员表差分：现读 `coverage_n=171`）。
#   【⑧ 射程边界（如实）】① 牙 1 的真用法**不在门禁**（见 ⑥）；② 牙 2 **只覆盖 inode 共享**：同内容独立真拷贝**不报**（正确行为）、孪生在 `--roots` 外／深于 `--maxdepth` ⇒ 不检出、符号链接影子与**写穿已发生的历史** ⇒ **不覆盖**；③ 白名单是**声明式豁免**、不下调判据强度，但**未被点名的树一旦出现即红、需人复核**（设计意图）；④ `docs/**` 不在覆盖面 ⇒ 改预登记不动 `inputs_fp`；⑤ 本波**零 `dotnet` 改动产品件**，两处落仓补丁只去车道名／加白名单，**判定语义未改**。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:4143bf4f50a7eba1,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w167a/w69/gate/gate-r2
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:4143bf4f50a7eba1,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w167a/w69/gate/gate-r2
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:4143bf4f50a7eba1,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w167a/w69/gate/gate-r2
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:4143bf4f50a7eba1,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w167a/w69/gate/gate-r2
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:4143bf4f50a7eba1,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w167a/w69/gate/gate-r2
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:4143bf4f50a7eba1,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w167a/w69/gate/gate-r2
# ⏪ **（历史，已被 `#69` 取代）**# RE-FROZEN #68 —— ✅ **当前冻结基线** —— 内容 = **`TASK-0722` 落仓**：`D-G123` 的口径修法（判据端入仓，`verify-all` 第 `[39]` 步 `SILENT-HIT-V2`）＋ 四处声明 ＋ `fp_inputs()` 两行。**本波零产品位移**（不改任何产品件；九位里只有环成员 `pf` 变）。
#   ① **新步 `[39] SILENT-HIT-V2`**（`verify-all.sh` **`9d28301987351fd1` → `cf0a4dd317bb48ac`**，135,873 → 137,887 B）：`run_step "SILENT-HIT-V2" bash build/MilBridge/tools/silent-hit-v2-check.sh --cases build/MilBridge/tools/silent-hit-v2-cases.tsv --expect 12`。**步数 38 → 39**（`NSTEP=39`）。
#   ② **四处声明同趟**：`# VERIFYALL-STEPS-DECL: 39 gen=#68`（**插在现行第一行 DECL 之前** —— `decl_line()` 是 `sed … | head -1`，`D-G131`）＋ 头注释口径句 ``**`#68` 收官起 = 39 步**`` ＋ `VERIFYALL-STEP-NAMES` 行尾 `| SILENT-HIT-V2` ＋ 预登记 H1。
#   ③ **新判据件**：`build/MilBridge/tools/silent-hit-v2-check.sh`（`9eccf056bf2d7417`，23,313 B／426 行）—— 三态 `SILENTHIT=PASS|FAIL|NOINFO`；**单一实现**（`judge()` 一处）：**三条件合取** ∧ 第三支 `SEGV_BRANCH` **具名**（四支白名单 `rc139/fate/term/stop-signo11`）∧ **阳性对照＝门槛**（无 HIT 行 ⇒ `FAIL reason=untriggerable`）∧ 跨件代**禁合池**（`--denom`）＋ `D-G128` 两条（`INJ_ALIVE`／`VARIANT_INPLACE`）；**空表／缺列／非整数／零行被检查 ⇒ `NOINFO rc=2`**（零检查必须报红）。`--selftest` 9 例（`degenerate_flips=3`）／`--gate-selftest` 12 例。
#   ④ **新台账**：`build/MilBridge/tools/silent-hit-v2-cases.tsv`（`7bc8a739cb66927c`，1,632 B／表头＋12 行）—— 逐行「判定输入 → 期望判词」；**阳性对照来自在册 4 条历史真命中**（`W071`／`W077`／`L1B024`／`W8AA-04`）＋ 2 条现件代活腿（`NOT-HIT`）＋ 2 条闸例（`NOINFO`）。
#   ⑤ **覆盖面 `fp_inputs()` +2 行**（**第三手**：`#66` → 163、`#67` → 165）：`build/close-wave.sh` **`7281832adf70a02d` → `622624a27c8bf6e0`**（41,078 → 41,193 B）⇒ **覆盖面 `165 → 167`**。`inputs_fp` = `ddf948f39c57213ee9fbd57f3e4538ad5fbc6ad534d157dc43538bfe6a7c0b45`（`ab58dd6165a454ca981f2761bc5643f3424a647381bf7af8a83f180591d0b8ec` → 本值；归因 = 白名单 **+2 行** ＋ 新增两件**内容**，**无第三处** —— 成员表差分已验：只退一件 ⇒ 166、两件都退 ⇒ 与基点逐位相同）。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`／`pf` `ddb412ee7efa4b65`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `fc60c34d51fd9247`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#67` 冻结值**：`pf` `cbd1884faeb4837e` → `ddb412ee7efa4b65`（**环成员**，`D-G92`：整波重建必变、同尺寸）；其余八位**逐位未变**。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   ⚠️ **九位只许从最新 `RE-FROZEN` 块的九位行或 `BASELINE tier=` 机读行取**（`D-G119` 实例㉕）。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落仓（**owner = 本车道**；写前逐件 `stat -c %h==1` 断言、先备份、`mv` 原子替换、写后现算 sha16）】5 件：
#      `verify-all.sh`（`9d28301987351fd1` → `cf0a4dd317bb48ac`）／`build/close-wave.sh`（`7281832adf70a02d` → `622624a27c8bf6e0`）／
#      `build/MilBridge/tools/silent-hit-v2-check.sh`（**新建** `9eccf056bf2d7417`）／`build/MilBridge/tools/silent-hit-v2-cases.tsv`（**新建** `7bc8a739cb66927c`）／
#      `docs/WAVE68-PREREGISTRATION.md`（**新建** `c48fb294a991c640`）。**未碰** `KNOWN-DEFECTS.md`／`ROUTES.md`／`HANDOFF-NEXT.md`／`declared.tsv`／`known-red.json`（主控写域）。备份 = `~/w162a/land/backup/{verify-all.sh.before-w68,close-wave.sh.before-w68}`。
#   【② 判据与两极化（**落地前**在真拷贝树里全部真跑，非重活）】① 声明链：完整 ⇒ `VERIFYALL_SELF=PASS names=39 decl=39 gen=#68 dup=0 order=OK prose=OK prereg=PASS`；**删 `run_step` 行保声明 ⇒ `FAIL names=38 decl=39` rc=1**。② 台账 12 行 ⇒ `rc=0`（`rows=12 examined=12 hits=6 nothit=4 noinfo=2 mismatch=0 posctl=2/2`）；**空台账／缺列 ⇒ `NOINFO rc=2`**。③ `--polarity` 在位 ⇒ rc=0；树里换成未变体 ⇒ **rc=1 点名 `VARIANT_INPLACE`**。④ `--selftest` rc=0／`--gate-selftest` rc=0（12/12）。⑤ `PREREG4=NA rc=0`。
#   【③ 重锚（`#67` 落仓后的基点）】`#67` 把步数做成 38（`DECL` 首行 `38 gen=#67`）、白名单做成 165 ⇒ 本波落仓第一步 = `land/apply.sh --reanchor-all` 现取基点 ＋ 与放行件对账（**不符即 `rc=9` 拒跑**）：`verify-all.sh 9d28301987351fd1`｜`close-wave.sh 7281832adf70a02d`｜`run_step=38`｜`fp 165 件`。
#   【④ 整波】`close-wave.sh --skip-verify-all`（槽内，rc 见 `~/w162a/w68/logs/w68-wave-*.log`）。
#   【⑤ 门禁 ×2 ＋ 冻前 `verify-all`】**三趟各** `步骤通过 39 ❌ 失败 0` ∧ `结论：✅ 全部通过` ∧ `用例通过 875 跳过 2`；现读：待冻前读数｜待冻前读数；`[11]`＝VERIFYALL_SELF=PASS names=39 decl=39 gen=#68 dup=0 order=OK prose=OK prereg=PASS；`[17]`＝PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=85 sites=85 hit=0 low=7 diag=3 safe=75 runs=1；`[12]`＝待冻前读数；`[39]`＝SILENTHIT=PASS。
#   【⑥ `UNWIRED` 两条（逐字，已写进 `DECL` 首行）】① `producer=UNWIRED-IN-STEP`：产出端（腿驱动）**仍在车道**（8 份同形副本），`verify-all` 里**没有任何一步调用它** —— 判据口径**限定到代码形状**（`grep -cE '^[[:space:]]*run_step .*silenthit' verify-all.sh` **= 0**），**全文 `grep` 命中只作旁证**（`D-G119` 实例㉔）⇒ **不许把 `--cases` 的 `PASS` 读成「现件代已复现／已清零」**。② `legacy-copies=DEPRECATED×7`（`w118a`／`wc06`／`wc07`／`wc08`／`wc11`／`w155a w65d109`／`w159a`；`w128a/one128.sh` 留作历史真命中的产出者证据）⇒ 收编归 `TASK-0726`（排 `#69`）。
#   【⑦ 本车道自伤与旧读数作废（如实留痕）】① **覆盖面基数**：我先前的 `162 件／4c1056dd…` 是**过期 `/tmp` 清单**（窗口内 `#66`／`#67` 白名单手已落）⇒ 现读 **165 件／`ab58dd61…`**；`nl-intent-check.sh`／`pts-pages-guard.sh` 命中**各 1**（原"命中 0"作废）。② **needle provenance**：曾用"整文件按 utf-16-le 解码后再找"核 `[HC-UNHANDLED]` ⇒ 该字面量在 dll 里落在**奇字节偏移**（199831）⇒ **假 MISS**；改**字节搜**后命中。③ `[HC-UNHANDLED] #` 的**件内字面量行尾不带空格** ⇒ 我原写法会**永远剔不到**（已按件内实测改正）。④ **判据端的"第二集"（诊断开关族 13 条）是在真腿上被闸抓出来的**：`wo-off-1` 报 `UNDECL=28`（`[WINSTATE_DIAG]`×26＋`[WMCK_DIAG]`×2）⇒ 补出「已声明但不剔」＋ `DIAG:excluded-from-denominator`。**判据咬到了判据自己**。
#   【⑧ 射程边界（如实）】`--legs-from`（产出端一致性闸）**本波不接线**（无产出端 ⇒ 报 `NOINFO reason=no-producer-lines`，**不许静默通过**）；`--denom` 的"分母 = 应用真的跑过的腿数"仍只在判据文本与用例表层面，**未落到表的列上**（改表会破 W155A 四张自证夹具）⇒ 记 `TASK-0722` 残项。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ddb412ee7efa4b65,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w162a/w68/gate/gate-r2
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ddb412ee7efa4b65,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w162a/w68/gate/gate-r2
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ddb412ee7efa4b65,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w162a/w68/gate/gate-r2
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ddb412ee7efa4b65,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w162a/w68/gate/gate-r2
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ddb412ee7efa4b65,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w162a/w68/gate/gate-r2
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ddb412ee7efa4b65,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w162a/w68/gate/gate-r2
# ⏪ **（历史，已被 `#68` 取代）**# RE-FROZEN #67 —— ✅ **当前冻结基线** —— 内容 = **`TASK-0721` 落仓**：把 `D-G122` 的牙 `PTS-PAGES` 接进 `verify-all` 第 `[38]` 步（**落地前预置**：门禁只跑判据那一半 `--legs`，重活由波内前置落证据目录）＋ 四处声明 ＋ `fp_inputs()` 两行。**本波零产品位移**（不改任何产品件）。
#   ① **新步 `[38] PTS-PAGES`**（`verify-all.sh` **`f31123fac6e2c1e6` → `9d28301987351fd1`**，128,393 → 135,873 B）：`run_step "PTS-PAGES" bash build/MilBridge/tools/pts-pages-guard.sh --legs "$PTS_EVIDENCE_DIR"`；常量 `PTS_EVIDENCE_DIR="${PTS_EVIDENCE_DIR:-build/MilBridge/tests/PtsPagesProbe/evidence}"`。**步数 37 → 38**（`NSTEP=38`）。
#   ② **四处声明同趟**：`# VERIFYALL-STEPS-DECL: 38 gen=#67`（**插在现行第一行 DECL 之前** —— `decl_line()` 是 `sed … | head -1`，见 `D-G131`）＋ 头注释口径句 ``**`#67` 收官起 = 38 步**`` ＋ `VERIFYALL-STEP-NAMES` 行尾 `| PTS-PAGES` ＋ 预登记 H1。
#   ③ **新判据件**：`build/MilBridge/tools/pts-pages-guard.sh`（`d42e9395f31e3681`，14,220 B；`cmp` 与 `~/w156a/w67guard/bin/` 原件**逐字节相同**）—— 三态 `PTS_GUARD=PASS|FAIL|NOINFO`；承重 `G1`–`G10`（两腿 `alive=yes`／`app_rc ∉ {134,139}`／洋红 `≥20000`／具名行 `err≠0`／`PTS_GAP ≥1`）；`G11/G12` 装置自证走 `NOINFO`；`D1–D6` 只诊断。`--selftest` **12/12**。**落定态现跑** `PTS_GUARD=PASS legs=2/2`。
#   ④ **新装置**（六件，`%h=1`，外来硬编码命中 **0**）：`build/MilBridge/tests/PtsPagesProbe/` 下 `run-pts-pages-legs.sh`（`b4b70bc0bf21074d`，10,683 B）／`session_inner.sh`（`5ef538137c6700aa`）／`navclick.py`（`e3d8b6ec4f5a4f6a`）／`legs-to-env.py`（`40105fec0b66d055`）／**`shotstat.py`（`65dea80e885c9f37`）**——⚠️ **第 6 件前序清单里没有**，但 `session_inner.sh` 的 `:61`／`:70` 要它（缺它 `colors/magenta` 取不到）；装置**假绿/假红 5 处修法**见 §⑥。
#   ⑤ **覆盖面 `fp_inputs()` +2 行**：`build/close-wave.sh` **`3f190c323b543275` → `7281832adf70a02d`**（40,955 → 41,078 B）⇒ **覆盖面 `163 → 165`**（`FPHYG_COVERAGE_N=165`；`infp.sh list` **165 行 ∧ `err` 空**）。`inputs_fp` = `ab58dd6165a454ca981f2761bc5643f3424a647381bf7af8a83f180591d0b8ec`（`2fa59979bcdd0148281fb3c011578ce0da43c30c89c11eca1b1da9a9d48610c8` → 本值；归因 = 白名单 **+2 行** ＋ 新增两件**内容**，**无第三处**）。⚠️ `波前==波后` 那句**作废**（整波那趟两端都在缺件态），以本值为准。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`／`pf` `cbd1884faeb4837e`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `fc60c34d51fd9247`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#66` 冻结值**：`pf` `29ad6d7cf3246938` → `cbd1884faeb4837e`（**环成员**，`D-G92`）；其余八位**逐位未变**（`pc`／`windowsbase`／`win32shim`／`bridge`／`wic_shim`／`hbtextline`／`dwf`／`provider`）。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   ⚠️ **九位只许从最新 `RE-FROZEN` 块的九位行或 `BASELINE tier=` 机读行取**（`D-G119` 实例㉕）。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落地（`cp -a --remove-destination` ＋ **写前逐件 `%h==1` 断言**；先 `cp -p` 备份）】3 件：`verify-all.sh`（`f31123fac6e2c1e6` → `9d28301987351fd1`）／`build/close-wave.sh`（`3f190c323b543275` → `7281832adf70a02d`）／`docs/WAVE67-PREREGISTRATION.md`（**新建** `b7da932a7dbcb934`）；另 6 件装置 ＋ 1 件判据件（§③④）。**未碰** `docs/KNOWN-DEFECTS.md`／`ROUTES.md`／`HANDOFF-NEXT.md`／`declared.tsv`／`known-red.json`。
#   【② 缺陷与判据（先写）】`criteria.md` 写于**任何补丁之前**（mtime 早于 `patches/` 全部产物）。
#   【③ 重锚（**第三次**，`D-G131`）】`#66` 往声明块加了两行 ⇒ 起点由 `79e4780086588fcb` 变 `f31123fac6e2c1e6`；`#66` 的白名单 +1 行 ⇒ `close-wave.sh` 由 `9dfc1e43b4d67fbf` 变 `3f190c323b543275`。⇒ **落仓第一步 = 现取基点 ＋ 重锚** 已写进 `~/w160a/land.sh` 第 1 节（**默认路径**，不是特例）。
#   【④ 整波】`close-wave.sh --skip-verify-all`（槽内，`held=187s`，`rc=0`）；`native_rebuilt=0`／`bridge_republished=0`。
#   【⑤ 门禁 ×2 ＋ 冻前 `verify-all`（槽内、严格串行）】**三趟各** `步骤通过 38 ❌ 失败 0` ∧ `结论：✅ 全部通过` ∧ `用例通过 875 跳过 2`；`[11] VERIFYALL_SELF=PASS names=38 decl=38 gen=#67 … prereg=PASS`；`[17] PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=84 sites=85 hit=0`；`[38] PTS_GUARD=PASS legs=2/2`；两趟门禁判词行**逐字相同**（`diff` 空）。
#   【⑥ 装置级缺陷与修法（**本波实测**，每条都有现场判词）】
#      🔴 **(1) `GROUPS` 撞 bash 内置只读变量** ⇒ `GROUPS=("A:24,23")` **静默无效**、`${#GROUPS[@]}` 仍是 9、
#         `echo "LEGS: ${GROUPS[*]}"` 打的是**进程 GID 列表**（现场 `LEGS: 1000 24 27 30 46 122 135 136 4` == `id -G` 逐字）
#         ⇒ 9 行 `MISSING-SHIM`、**一条腿都跑不出来且无报错**。修法 = **换名 `LEG_GROUPS`**；机械证 `~/w160a/repro-groups.sh`。**`D-G119` 家族新实例。**
#      (2) 分组 argv 形态错：`A:24`／`A:23` 被拆成两个 argv ⇒ 下游读成 `ARM=A`/`KS=A`；改为 `A:24,23`。
#      (3) 显示占用**自匹配**（`D-G103` 族）：槽里的子壳命令行也带 `PTS_GUARD_DISPLAY` ⇒ 原口径只排 `$$`/`$PPID` **不够**；改为排**整条祖先链**。
#      (4) A 臂需 `$DLLS/A.libwpfwin32.so` 存在 ⇒ 由 `~/w160a/stage-arms.sh` 运行时装配（= 当前权威件**同字节**副本，自证 `app=fc60c34d51fd9247 == arms/A`）。
#      (5) 转换器按 `session.txt` 的**目录**找 `app_g*.log` ⇒ 日志在 `$W/logs/<tag>/` 而 `$OUTDIR` 里没有 ⇒ `native_gap=0` ⇒
#         **假红** `PTS_GUARD=FAIL fails=native-ledger-absent`；修法 = `SESS_LOGDIR` ＋ 转换前**镜像**（现读 `native_gap=1` == 原始日志 `PTS_GAP entry=` 命中 1）。
#      🔴 **(6) `PIPEFAIL-SIGPIPE` 陷阱（gate1 现抓，`[17]` 那格）**：`run-pts-pages-legs.sh:85` 的
#         `if tr … | grep -q -- "$DISPLAY_NUM"; then` 是**末段早退** ⇒ `pipefail` 下 `rc≠0` ⇒ 那个 `if` 可能**恒假**
#         ⇒ **显示占用检查静默失效**（装置会在别人占用的显示号上开跑）。修法 = **去管道**，先取变量再 `case`。
#         修前 `PIPEFAIL_SIGPIPE=FAIL undeclared_hit=1 hit=1 sites=86` ⇒ 修后 `PASS undeclared_hit=0 hit=0 sites=85`（**改代码，不是改声明**）。
#         ⇒ 本波**独立发现**：装置原样落仓会**假绿**（(1)(2)(5)(6)）／**假红**（(3)(5)）。
#      ⚠️ **射程边界（如实）**：`build/MilBridge/tests/PtsPagesProbe/evidence/**`（16 件）**不在 `fp_inputs()` 覆盖面**
#         ⇒ **证据件的完整性不受指纹保护**：有人改 `leg_*.env` ⇒ 本步**仍绿**。候选修法：**(i)** 把证据目录作为**声明语料**纳入覆盖面（只在"有意重产"时挪指纹）；**(ii)** 把 `[38]` 升级为**自己跑腿**（才有 `D-G122` 的原始射程；代价 ≈45 s/趟）。**本波不扩，只声明。**
#   【⑦ 关于 `column-floor-check.sh` 的抽块器（**本波踩到、如实记**）】`extract_newest_block()` 的**退出条件**是
#      "冻结标题那一串字样（`R` 起头、中间带连字符、结尾紧跟井号）在块内**再次出现**" —— 条件是**无行首锚**的，
#      所以 **FROZEN 段正文里也不能出现那个字样**（一旦出现，抽块会**提前截断**，紧随其后的
#      `# COLUMN-FLOOR`／`# COLUMN-CORPUS`／`# ARM-LOG-SHA` 会**全被排除** ⇒ `COLUMN_FLOOR=NOINFO`）；
#      **BANNER 段出现更致命**（抽块会在标题行之前就退出 ⇒ 块为空）。
#      ⚠️ 本注**故意不把那串字样原样写出来** —— 否则这条"提醒"自己就把它引回来了（本波第一次修就是这样，被
#         `build-record.py` 的硬断言当场抓住）。判据由 `build-record.py` 的硬断言守：**全模板只许标题那一处命中**。
#   【⑦ 本车道自伤（如实留痕）】①**第一版两极化里那个"正极成立"其实是被另一个真实残留命中的**（`sleep 300 "$D"` 语法无效 ⇒ 假进程没起来）——**结论对、机制错**；②未显式设 `PTS_GUARD_DISPLAY` ⇒ 两档都撞默认 `:237`；③**本车道自己留下了 `Xvfb :237` ＋ `xfwm4 :237`**（`ppid=1`、无 X 客户）——**"起显示只 `:23x`"这条硬规则的第一次违反者是本波自己**；已按 PID 收干净（未动别人的 `:99`／`:97`）。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:cbd1884faeb4837e,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w160a/w67gate/gate-r2
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:cbd1884faeb4837e,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w160a/w67gate/gate-r2
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:cbd1884faeb4837e,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w160a/w67gate/gate-r2
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:cbd1884faeb4837e,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w160a/w67gate/gate-r2
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:cbd1884faeb4837e,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w160a/w67gate/gate-r2
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:cbd1884faeb4837e,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w160a/w67gate/gate-r2
# ⏪ **（历史，已被 `#67` 取代）**# RE-FROZEN #66 —— ✅ **当前冻结基线** —— 内容 = **`TASK-0720` 落仓**：A3 口径更正 ＋ 11 条 `#if NEVER` 死声明名单落册 ＋ 批 2a 三条 `LsErr` 诚实失败（导出 `547 → 550`）＋ `Nl*` 有意降级声明牙 ＋ `fp_inputs()` +1 行。**本波有产品面位移**（native 源改了）⇒ 见 ⑥。
#   ① **A3 口径更正**：`src/WpfGfx.Linux.Native/src/win32_classification.c` **`1e17b8331c2d3d73` → `a5923b2fc07dea0b`**（13,661 → 13,744 B）：**单行、保行数**，保留字面「111 条」（留下"旧数被作废"的痕迹）＋ 同行 `TOOL-UNSOUND` 更正标记 ＋ 两个新口径（`可操作 91`／`实现口径 97`）。判据 = `check-111-sweep.sh` `live_uncorrected=0`（修前 = 1）。
#   ② **11 条 `#if NEVER` 死声明名单落册**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` **`7a663e8d4d8ee953` → `a31f34c113235dd3`**（717,620 → 718,486 B，**`+1 行 / -0 行`**）：11 名与 `check-numbers.py` 现算 `DEAD` 集合**相等**（成员表先取）；独立复核：8 个 `#if NEVER` 区间与现算 `DEAD_RANGES` 逐字相同，另两区间（`3442-3466`／`3598-3617`）只有**裸 C 原型、无 `[DllImport]`** ⇒ 正确地不在名单内。**⚠️ 该件由主控搬行**（口径：字符串由本车道 `patches/P02-NEWLINE.txt` 产、`apply.sh` 的 applier 产字节；主控落 `$R` 并同趟重发 `declared.tsv` = `342a25e8795f58b5`、`DEFREG=PASS declared=167 DECLDRIFT=0`）。
#   ③ **批 2a 三条 `LsErr` 诚实失败**：`src/WpfGfx.Linux.Native/src/win32_pts.c` **`e6559d0bba3c1044` → `bcb9858919e6237e`**（13,404 → 15,189 B；`P03`（5 处）＋`P03X`（2 处）**必须同趟**）：新增 `LoCreateContext`／`LoAcquirePenaltyModule`／`LoGetPenaltyModuleInternalHandle`（`ret == -10000` ∧ 出参置 `NULL`）；**导出 `547 → 550`**；`WpfLinuxWin32_PtsGapSelfCheck() == 1`；台账逐条 `PTS_GAP entry=… seq=7/8/9 err=-10000`。
#      🔴 **`D-G128` 实例①（假牙）＋ 修法同趟**：原自检 `else if (p1 != NULL) rc = 12/14/16;` 三条**恒绿**（链条走到第 7/9 条时 `p1` 早被第 1 条入口清成 `NULL`）⇒ 删掉出参清零仍 `SELFCHECK=1`。`P03X` 给三条入口**各自投喂毒的出参**（`q1/q2/q3`）⇒ **删掉清零 ⇒ `SELFCHECK=0`（判否翻转）**，且 honest 档两树都 `=1`。**2×2 矩阵**见本波报告。
#   ④ **`Nl*` 有意降级声明牙（新建）**：`build/MilBridge/tools/nl-intent-check.sh` **新建 `44f5e87b0ed0929c`**（15,123 B，单文件自足）：`--selftest` **4/4**（含**现场 gcc 编的假 `.so`** 阳性对照）∧ live `NL_INTENT_RESULT=PASS capability=0 declared=yes anchors=3/3`。
#   ⑤ **覆盖面 +1 行**：`build/close-wave.sh` **`9dfc1e43b4d67fbf` → `3f190c323b543275`**（`fp_inputs()` 名单 **+1 行** `build/MilBridge/tools/nl-intent-check.sh`；注释块置于 `printf` **语句之前**，新行留在 `\` 续行参数表内）⇒ **覆盖面 `162 → 163`**（`FPHYG_COVERAGE_N=163`）。
#      ⚠️ **`inputs_fp` 一笔（成对）**：`4c1056ddca8afc700df3f0777a2c134932a5fc2ddcfc7d1192c38940e3c15fd5`（`#65` 冻后值）→ **`2fa59979bcdd0148281fb3c011578ce0da43c30c89c11eca1b1da9a9d48610c8`**（整波自印"波前==波后"）。
#      ⚠️ **`UNWIRED`（如实声明，不许算绿）**：`nl-intent-check.sh` **在覆盖面内但未被 `verify-all` 调用** —— 证据 = **只看代码形状**：`grep '^run_step "' verify-all.sh | grep -c 'nl-intent'` = **0**（全文 `grep -c` = 2，那两条是**本波新加的声明正文**，**属 `D-G119` 实例㉔ 的污染形态**）⇒ 接线归 `[Next] TASK-0724`。
#   ⑥ **产品面位移 = 两位（预期即两位）**：`win32shim`（native 源改了 ⇒ 必变）＋ `pf`（环成员 ⇒ 必变）；其余七位**逐位未变**。**没有第三处位移、也没有"该动没动"**。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`（3601408 B）／`pf` `29ad6d7cf3246938`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `fc60c34d51fd9247`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`（293165 B）／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#65` 冻结值**：`pf` `59ba7d2997fcdd62` → `29ad6d7cf3246938`（**环成员**）；`win32shim` `d2b76a0a56a41be1` → `fc60c34d51fd9247`（**native 源新增 3 条导出** ⇒ `547 → 550`）；其余**七位逐位未变**（`pc` 仍 `722e0ab8205b7c3f`、`windowsbase` 仍 `2e4e46e539a72cd7`、`dwf` 仍 `ce3469f49efcbcfa`）。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   **臂日志聚合（两种口径都给）**：`cat` 口径 `2f276db59de241cb`／`find|sort|xargs` 口径 `6e246ef5b87d69ea`（本波**不改** `GEN_KEYS` ⇒ **五臂不重取**）。
#   **冻前 `verify-all` = `37` 步（`37 ✅ / 0 ❌`、`用例通过 875 跳过 2`）**：见下 §RECORD 的 ⑥ 行。
#   —— 外挂声明（**两族必须落在最新 `# RE-FROZEN` 块内**）——
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落地（全部 `temp ＋ os.replace`；前后 sha **双断言** ＋ **写前逐件 `%h==1` 断言**）】7 件：`P01`／`P03`＋`P03X`／`P04`／`P05`／`P06`（`verify-all.sh` 两条声明）／`P07`（新建预登记件）；`P02` 由主控搬行（见 `# RE-FROZEN` ②）。
#      ⚠️ **拒绝写穿的机制**：全部走**同目录 `mkstemp` ＋ `os.replace`**（换 inode）；写前用**唯一实现** `~/w158a/tools/shadow-gate.sh` 断言每件 `stat -c %h == 1`（不满足 ⇒ `exit 3` 拒写）。现场命中一行**假阳性**（`w153a` 车道推文档的 shell 命令行文本里含 `WpfFeatureProbe`）⇒ 后续实测均在 `%h==1` 下进行。
#   【② 缺陷与判据（先写）】`D-G128` 实例①（**反极性腿恒绿假牙**：注入点被上游清空 ⇒ 该腿不是证据）／`D-G119` 实例㉔（**判据的输入被它自己的文档正文污染**：`grep -c nl-intent` 被新写的声明正文从 0 顶到 2）—— 判据、两极化与判否条件见 `~/w158a/criteria.md`（含三条**测量后**追加的判据修订，未就地改写原判据）。
#   【③ 整波】`close-wave.sh --skip-verify-all`（槽内，`held=183s`）：波前/波后 `inputs_fp` 对账 = `2fa59979bcdd0148281fb3c011578ce0da43c30c89c11eca1b1da9a9d48610c8`；九位位移 = **预期 `pf` ＋ `win32shim` 两位**（**出现第三处、或该动没动 ⇒ 停手报主控**）⇒ 实测**正好两位**。
#   【④ 五臂／重钉】**本波不改 `GEN_KEYS`**（不动 `run.sh`／`HbTextLineParity/Program.cs`／`build/shims/PresentationCore.HbTextLine.cs`）⇒ **五臂不重取**、臂日志 sha 与 `#65` **逐位相同**（`ARMLOG_SHA=PASS declared=5 pass=5`）。
#   【⑤ 门禁 ×2（槽内、严格串行）】**合格线 = 判词行逐字一致**（`BASELINE` 六条机读行 `result=PASS`、`pc:722e0ab8205b7c3f`／`pf:29ad6d7cf3246938`／`win32shim:fc60c34d51fd9247` 为终态）。显示号按硬规则 `:23x`（`WPTD_DISPLAY=:231`；脚本自起 Xvfb 并按 PID 收尾）＝**本波新立**（`run-wpftextdemo.sh` 默认 `:97`，而 `:97` 现场已被占用）。
#   【⑥ 冻前 `verify-all`（槽内）】**`37 ✅ / 0 ❌`**、`rc=0`、`结论：✅ 全部通过`、`用例通过 875 跳过 2`。
#      ⚠️ **本波第 1 趟冻前 `verify-all` 曾 `36 ✅ / 1 ❌`**：失败项 = `PREREG-FOUR-REQ`（`PREREG4_FILE … state=fail missing=7`）。
#        **根因＝声明写错了节**：`prereg-four-requirements-check.sh` 的 `extract_section()` 只取**第一个标题含「判据」的节**，
#        而我把「本波不做任何回归判定」写在 `§0`（**判据节之外**）⇒ `no_rd_decl=0` ⇒ 落进四要件判据。
#        **修法**：`patches/P07B.py`（只加不改）把同一条声明补进 `§1 判据` 节内 ⇒ 该件 `e6d368b565357ec1 → bf6b683d94549087`（2,890 → 3,409 B）；
#        单独复验（照 `verify-all` 的形态）`PREREG4=PASS files=47 pass=1 fail=0 na=8` ⇒ 该件从 `fail` 移入 `na`。
#        ⇒ **施工必记（本波新增）**：**「不做回归判定」这类节级声明，必须落在牙真正抽取的那一节里** —— 位置错了等于没写。
#        ⚠️ 同趟的**守卫生效记录**：`w66-freeze.sh` 见 `步骤通过 36 … 失败 1` ⇒ 当场 `STOP`、**没有冻结**（`FRC≠0／步数不符 ⇒ 不写 DONE` 这条纪律不是摆设）。
#      逐步骤核：`VERIFYALL_SELF=PASS names=37 decl=37 gen=#66 prose=OK prereg=PASS` ＋ `FP-INPUTS-HYGIENE` 覆盖面 `163`／`artifact_n=0`。
#   【⑦⑧⑨ 冻后追加（`APPEND_ONLY`）】冻结 `#66` 的 `FREEZE_RC`／冻后两极化（`BASELINE-SHA`／`ARM-LOG-SHA`／`COLUMN-FLOOR` 冻前红 ⇒ 冻后绿）／**冻后 ×2 两趟**（各 `37 ✅ / 0 ❌`）。
#   【牙与件（现算 sha16）】`~/w158a/criteria.md`（`730f9d283bb9d2fc`）｜`~/w158a/apply.sh`｜`~/w158a/patches/P0{1,2,3,3X,4,5,6,7}.py`｜`~/w158a/tools/{shadow-gate.sh,verify-chain.py,sparse-leg.sh,anchor-precheck.sh,report-table-check.sh,land-r66.sh}`｜`build/MilBridge/W66-report.md`（本波报告）｜`docs/WAVE66-PREREGISTRATION.md`（`e6d368b565357ec1`）。
#   【本波四条口径句（落册，均来自现场实测）】
#      ① **凡「反极性／对照」腿，必须先证明它的注入点在自己那一层还活着**（切断被注入的对象 ⇒ 该腿**必须翻转**）；注入点在链路下游被上游清空／覆盖 ⇒ 那条腿是**假牙**（恒绿），不是证据（`D-G128` 实例①）。
#      ② **凡「未接线／未调用」类主张，必须把 grep 限定到「代码形状」**（`^run_step` 之类）；**全文命中只作数量级旁证** —— 判据的输入会被它自己的文档正文污染（`D-G119` 实例㉔）。
#      ③ **凡「某物已不存在／已清空」的判据，必须由「创建它的那条路径」同趟检查一遍**（否则检查本身就是它的创建者）—— 现场：`apply.sh` 开工的 `mkdir -p … shadow` 每跑一次就把空 `shadow/` 造回来，而"农场已清"的验收格正是 `ls -d … shadow`（`D-G128` 实例③）。
#      ④ **同一逻辑不许存在两处** —— 本波把"链式复核"抽成**唯一实现**（`tools/verify-chain.py`）并**三处迁移**：同一个"把补丁的 `after` 直接比现态"的 bug 在 `apply.sh`／`sparse-leg`／`land-r66` **犯了三次**，每次都是**假红**。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:29ad6d7cf3246938,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w158a/w66gate/gate-r2
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:29ad6d7cf3246938,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w158a/w66gate/gate-r2
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:29ad6d7cf3246938,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w158a/w66gate/gate-r2
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:29ad6d7cf3246938,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w158a/w66gate/gate-r2
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:29ad6d7cf3246938,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w158a/w66gate/gate-r2
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:29ad6d7cf3246938,provider:1f9511a7ef395bfe,win32shim:fc60c34d51fd9247,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w158a/w66gate/gate-r2
# ⏪ **（历史，已被 `#66` 取代）**# RE-FROZEN #65 —— ✅ **当前冻结基线** —— 内容 = **判据装置批 E**（**零产品改动**）：`D-G125`（静默丢行 ⇒ 假绿）的修法 ＋ `DECL_UPPER` 承重 token ＋ 四条册级不变量 ＋ 3‑9 改判，另交接入仓两件牙（`TASK-0718`）。
#   ① **`TASK-0719`（`D-G125`／`D-G121` 的承载件）**：`build/MilBridge/tools/baseline-rate-gate.sh` **`31cf77abc6a882e3` → `1bad58c07a8264e6`**（580 行）。
#      · **`D-G125` 修法**：删掉 `run_cases()` 里 `if len(parts) != len(COLS): continue` 的**静默跳过** ⇒ 改**按行宽分派**（8 列旧形态／10 列新形态）＋ **册级自洽**（行宽既非 8 也非 10 ⇒ **响亮 `NOINFO-DECL-COLUMN-WIDTH`**；前缀/新行一致性 ⇒ `decl-upper-legacy-judged`／`decl-upper-newrow-unjudged`）。
#      · **`DECL_UPPER=EVALUATED|NOT-EVALUATED`**（**单一承重 token，可 grep**）：在 `F = {}` 下一行初始化 ⇒ **任何早退都恰打一个值、永不为 `-`**；3‑4 自洽处置 `EVALUATED`。**保留** `decl_upper_checked` 七值细分。
#      · **四条册级不变量**（`FAIL` 具名）：`decl-upper-pairing-violated`（token 与细分原因自相矛盾／白名单外的新原因一律默认 `FAIL`）／`decl-upper-legacy-judged`／`decl-upper-newrow-unjudged`／`decl-upper-notreached-unpaired`（`-` 只许配三条前置 `NOINFO` 码）。**允许集白名单** = {7 值} ∪ {`na`, `-`, `column-width`}。
#      · **3‑9 改判**：新行退回旧形态 ⇒ **`FAIL/1`** ＋ 点名 `decl-column-required-on-new-row`（细分原因 `column-width`）—— **`cases21` 计数不变（`21/0`），变的是那一行的期望值 ⇒ 加严，不是读数反复**。
#   ② **`TASK-0718`（W152A 交来的两件，按 sha 逐字节应用）**：`build/MilBridge/tools/shell-quote-trap-check.sh` **`d4317aa7605a31e1` → `39a2e2cdf1948675`**（`--selftest` **41/41**、`ST_ATTEST=PASS`）｜`build/MilBridge/tools/fp-manifest-teeth-check.sh` **新建 `be19edddf7f02797`**（`--selftest` **13/13**）。
#   ③ **台账**：`build/MilBridge/tools/baseline-rate-cases.tsv` **`8d71171d475a63dc` → `1a2df056f5677344`**（**原 11 行逐字节不动** ＋ 新块（表头声明两列 ＋ `legacy_rows=11`）10 行 ⇒ **21 行**）。
#   ④ **模板**：`docs/PREREG-TEMPLATE.md` **`17927a59d050fc83` → `300ec21903d54756`**（§3.2 三栏 `p0`／`p0 时间窗`／`p0 来源锚`；17,397 → 18,874 B；`wc -l` 212 → 223）。
#   ⑤ **接线 ＋ 覆盖面**：`verify-all.sh` 四处声明改 `gen=#65`（**不加步 ⇒ 仍 `37` 步**）｜`build/close-wave.sh` **`168a33c3d4743559` → `9dfc1e43b4d67fbf`**（`fp_inputs()` **+1 行**：`build/MilBridge/tools/fp-manifest-teeth-check.sh`）⇒ **覆盖面 `161 → 162`**。
#      ⚠️ **`inputs_fp` 两笔（成对、带机械归因）**：`f148203453b092206b6a9f9529821fa58570ba7035fb5253ca4f4e8da6dd77ae`（`#64` 冻后值 ＝ 本波 `prev_infp`）→ **`4c1056ddca8afc700df3f0777a2c134932a5fc2ddcfc7d1192c38940e3c15fd5`**（**after == after_predicted** 已验）。
#      **交叉表 32 行／16 值**（按"哪些件处于已落地状态"命名）：**全部退回 ⇒ 逐位 == before**；**+1 行归因** = 白名单多一行；**成对同值的机械原因** = `fp-manifest` 那一行**只在 `close-wave` 处于已落地状态时才存在于清单里**。
#      ⚠️ **`UNWIRED`（如实声明，不许算绿）**：`fp-manifest-teeth-check.sh` **在覆盖面内（第 263 行）但 `verify-all.sh` 里 `grep -c` = 0（未被调用）**；其正常运行读数 = **`FP_MANIFEST_TEETH=NOINFO reason=no-manifest`（`rc=2`）** ⇒ 接线归 `[Next] TASK-0724`。
#   ⑥ **零产品改动**：`src/**`／`build/shims/**`／native 源**一字节未动** ⇒ 九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸 6123520 B**）⇒ 机械位移，**不许当漂移/回归判据**。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`（3601408 B）／`pf` `59ba7d2997fcdd62`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `d2b76a0a56a41be1`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`（293165 B）／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#64` 冻结值**：`pf` `02b2792448fbd41d` → `59ba7d2997fcdd62`（**环成员**：**同尺寸 6123520 B** ⇒ 机械位移）；其余**八位逐位未变**（`pc` 仍 `722e0ab8205b7c3f`、`windowsbase` 仍 `2e4e46e539a72cd7`、`win32shim` 仍 `d2b76a0a56a41be1`、`dwf` 仍 `ce3469f49efcbcfa`）。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   **臂日志聚合（两种口径都给）**：`cat` 口径 `2f276db59de241cb`／`find|sort|xargs` 口径 `6e246ef5b87d69ea`（本波**不改** `GEN_KEYS` ⇒ **五臂不重取**）。
#   **冻前 `verify-all` = `37` 步（`37 ✅ / 0 ❌`、`用例通过 875 跳过 2`）**：见下 §RECORD 的 ⑥ 行。
#   —— 外挂声明（**两族必须落在最新 `# RE-FROZEN` 块内**）——
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落地（全部 `temp ＋ rename`；前后 sha **双断言**）】6 件：见 `# RE-FROZEN` 的 ①–⑤。
#      ⚠️ **合约 ② 违约（如实记，已补救但不豁免）**：**第一轮备份只备 5 件，漏了 `shell-quote-trap-check.sh`**（备份清单写在读落地令**之前**）⇒ 该件在**无备份**状态下被覆盖。**补救**：fork 克隆 `HEAD:` 该件 = `d4317aa7605a31e1`（与覆盖前现读逐位相同）＋ `~/w152a/w65/backup/shell-quote-trap-check.sh.orig` = 同值（两独立来源）⇒ 恢复件可信。⇒ 主控立 **`D-G126`**，**施工必记第 8 条：备份清单必须在读完全部落地目标之后才动手**；并派补救件 `~/w153a/w65rate2/backup_guard.py`（**落地前**断言"每件都有备份 ∧ 备份 sha16 == 覆盖前现读 sha16"，缺一即**拒落**；两极化在**影子树**上跑：正例 拒落 0／反例 A 备份缺失 ⇒ 拒落／反例 B 备份错版本 ⇒ 拒落）。
#   【② 缺陷与判据（先写）】`D-G125`（静默丢行 ⇒ 假绿）／`D-G121`（公式口径误用 ⇒ 上界低报）／`D-G120`（续行注释吃参数表）—— 三者的判据、反极性、判否条件见判据链四件与 `docs/WAVE65-PREREGISTRATION.md`。
#   【③ 整波】`close-wave.sh`（槽内）：波前/波后 `inputs_fp` 对账 = `4c1056ddca8afc700df3f0777a2c134932a5fc2ddcfc7d1192c38940e3c15fd5`；九位位移 = **预期只有 `pf`**（环成员；**出现第二处位移 ⇒ 停手报主控**）。
#   【④ 五臂／重钉】**本波不改 `GEN_KEYS`**（不动 `run.sh`／`HbTextLineParity/Program.cs`／`build/shims/PresentationCore.HbTextLine.cs`）⇒ **五臂不重取**、臂日志 sha 与 `#64` **逐位相同**。
#   【⑤ 门禁 ×2（槽内、严格串行）】**合格线 = 判词行逐字一致**（`BASELINE` 六条机读行 `result=PASS`、`pc:722e0ab8205b7c3f`／`pf:59ba7d2997fcdd62` 为终态）。
#   【⑥ 冻前 `verify-all`（槽内）】**`37 ✅ / 0 ❌`**、`rc=0`、`结论：✅ 全部通过`、`用例通过 875 跳过 2`。
#      ⚠️ **本波首趟 `verify-all`（落地后）曾 36 ✅ / 1 ❌**：失败项 = `PREREG-FOUR-REQ`，**根因 = 我新建的 `docs/WAVE65-PREREGISTRATION.md` 缺「不做回归判定」声明**（该牙判 `missing=7`）⇒ 补 `PREREG-NO-REGRESSION-DECISION:` ＋ 逐字「本波不做任何回归判定」后，本机复核 `PREREG4=NA rc=0`（`na=1` 与 `pass` **分开计数**）。**这是"新预登记件缺 N/A 声明"的现场第一例，不是产品/判据问题** ⇒ 施工必记第 9 条：**建预登记件必须同趟带该声明，并立刻单独跑一次该牙**。
#      逐步骤核：`VERIFYALL_SELF=PASS names=37 decl=37 gen=#65 prose=OK prereg=PASS` ＋ `FP_INPUTS_HYGIENE=PASS coverage_n=162 artifact_n=0`（**覆盖面 +1 行、`artifact_n` 仍 0**）。
#   【⑦⑧⑨ 冻后追加（`APPEND_ONLY`）】冻结 `#65` 的 `FREEZE_RC`／冻后两极化（`BASELINE-SHA`／`ARM-LOG-SHA`／`COLUMN-FLOOR` 冻前红 ⇒ 冻后绿）／**冻后 ×2 两趟**（各 `37 ✅ / 0 ❌`）。
#   【牙与件（现算 sha16）】`~/w153a/w65rate2/criteria.md`（`a08293721b805036`）｜`~/w153a/w65rate2/CONSTRUCTION-ORDER.md`（`0fbba59efae0c578`）｜`~/w153a/w65rate2/REBASE.md`｜`~/w153a/w65rate2/PREGO.md`（`5c6ef78f756c3cae`）｜`build/MilBridge/W65-report.md`（本波报告，含 `UNWIRED` 格与接线决策表）｜`docs/WAVE65-PREREGISTRATION.md`（`40a8f0677ae76056`）。
#   【本波五条口径句（落册，均来自现场实测）】
#      ① **凡「看不懂就跳过」的循环，都是在把假绿写进工具** —— 收下的行数与声明的行数必须对账，丢一行就要响（`D-G125`）。
#      ② **登记一个上界，必须同时登记它的『公式名』与『`k` 是几』**；`k > 0` 时只许用 Clopper–Pearson 单侧上界；申报值／申报公式／样本的 `k` 三者必须机检一致 —— 不一致就是 `FAIL`，不是笔误（`D-G121`）。
#      ③ **`NOT-EVALUATED` 只有与细分原因合读才有意义**：单独引用 token 视为不完整引用；允许集是**白名单**，新原因一律默认 `FAIL`（`AMENDMENT-3`）。
#      ④ **替换的边界由内容定，不由索引定；改完必须核对紧邻两行的身份**（`D-G119` ㉒）／**凡『清单/台账』类输入，都要能回答『它是何时、由谁、从什么生成的』**（㉓）。
#      ⑤ **`\` 续行的参数表中间不许插注释**；凡指纹/清单类管线必须另有一条**独立于该清单**的证据（件数 ＋ 逐行形态断言）—— **「预测值 vs 实测值」同源时，自洽抓不到污染**（`D-G120`）。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:59ba7d2997fcdd62,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w153a/w65rate2/gate-r2
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:59ba7d2997fcdd62,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w153a/w65rate2/gate-r2
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:59ba7d2997fcdd62,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w153a/w65rate2/gate-r2
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:59ba7d2997fcdd62,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w153a/w65rate2/gate-r2
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:59ba7d2997fcdd62,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w153a/w65rate2/gate-r2
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:59ba7d2997fcdd62,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w153a/w65rate2/gate-r2
# ⏪ **（历史，已被 `#65` 取代）**# RE-FROZEN #64 —— ✅ **当前冻结基线** —— 内容 = **判据装置批**（**零产品改动**）：把 `D-G118`「基线率闸」做成仓内**牙 ＋ 确定性台账**，并把第 `[37]` 步接进 `verify-all`（**36 → 37 步**）；覆盖面 `159 → 161`。
#   ① **`D-G118`（基线率闸 · 新牙）**：**新建** `build/MilBridge/tools/baseline-rate-gate.sh` **`31cf77abc6a882e3`**（382 行）。判「**在册速率还能不能用来定 `N`**」—— 逐项印 `registered=<R>/<n>@<时间窗>`／`window=`／`observed=`／`observed_rate=`／`ci_upper=`／`ci_upper_2s=`／`ci_lower_2s=`／`cp_upper=`／`fisher_p=`／`registered_in_observed_ci=`／`gate=`／`effect=`／`required_n=`／`required_n_power=`／`voidpremise=`／`voidpremise_reason=`／`gate_closed=`／`effect_impossible=`／`caliber_disagreement=`／`gate_verdict_1s=`／`gate_verdict_2s=`。**三态 `BASELINERATE=PASS|FAIL|NOINFO`**（`rc` = `0|1|3`）：`PASS` ⟸ 历史速率**落在**新样本 CI 内 ∧ `ci_upper ≥ gate` ∧ `observed ≥ effect`；`FAIL` ⟸ 闸判失败，**其中"历史速率落在新样本 CI 之外"必须点名**（`DRIFT …registered=… ∉ 现取 CI […]`）；`NOINFO` ⟸ 缺时间窗／空样本／`n` 非正／`r` 越界／参数不可解析 ⇒ **响亮失败**（具名 `reason=NOINFO-*`）。**`VOID-PREMISE` 两条并列**（**不取其一**）：① `ci_upper < gate`（先写的闸门被**排除**，不是"没观测到"）② `observed < effect`（要排除的效应量**在现世界不可发生** ⇒ 连重算 `N` 都无意义）。
#      🔺 **两个口径的角色（写死）**：**主判据 = Wilson 单侧 95%（`ci_upper=`）**；**诊断列 = Wilson 双侧（`ci_upper_2s=`/`ci_lower_2s=`）＋ Clopper–Pearson 单侧（`cp_upper=`）**。**当两个口径在闸比较上结论不同**（`ci_upper_1s < gate ≤ ci_upper_2s`，或反向的边界情形）⇒ 判词**必须** `NOINFO` ＋ 具名 `reason=caliber-disagreement`，**禁止**用"对我方有利的那一界"下 `PASS`/`FAIL` —— **口径之争先于结论，必须显形**（同族：`D-G98` 一格定罪／`D-G118` 拿历史速率凑功效／`D-G116` 把结果侧算进体制）。
#      **算程自证**：**逐位复现**仓内在册四个 `REQUIRED_N_ALT` 值（`alt_rates=0.1000-vs-0.8890 ⇒ per_arm=7 power=0.8224`；`0.5890-vs-0.8890 ⇒ 37 / 0.8010`；`0.6090-vs-0.8890 ⇒ 41 / 0.8019`；`0.0000-vs-0.0600 ⇒ 131 / 0.8041`）；与独立算程 `~/w157a/bin/baseline-rate-gate.py` **逐位对账**（`observed 0.2500`／`cp_upper 0.4187`／`fisher_p 1.848e-06`／双侧 `[0.1268,0.4336]` 全同）。**纯 `math`/`comb`、无第三方依赖、纯读、零 `dotnet`、无网络、无 `X`；墙钟 3.44 s、RSS 10.7 MB。**
#   ② **`D-G118`（台账）**：**新建** `build/MilBridge/tools/baseline-rate-cases.tsv` **`8d71171d475a63dc`**（41 行／**11 行用例**）。**全部确定性合成**（常量写死）⇒ **不依赖任何现场腿读数 ⇒ 本步不随被测世界漂移而红/绿**。逐行声明期望并与**真判词**比对 `state/rc/**reason_class**`（比存量惯例"只比 state+rc"**更严** —— 因为本牙的验收点之一就是「`FAIL` 必须点名」）。11 行：`DG118-task0111-live-drift`（**本缺陷真实现场**，冻结常量 ⇒ `FAIL/1/DRIFT`）｜`a-self-consistent` ⇒ `PASS/0/PASS`｜`b-sample-outside-ci` ⇒ `FAIL/1/DRIFT`（**点名**）｜`c-effect-impossible` ⇒ `FAIL/1/VOID-PREMISE`（**只让②成立**）｜`d-empty-sample`／`d2-no-window`／`d3-n-nonpositive`／`d4-r-out-of-range` ⇒ `NOINFO/3/NOINFO-*`（四条**各自不同**的具名 reason）｜`e-counterexample-22-of-27` ⇒ `PASS/0/PASS`（`required_n=43`）｜`f-counterexample-12-of-12` ⇒ `PASS/0/PASS`（`required_n=21`）｜`g-caliber-disagreement` ⇒ `NOINFO/3/caliber-disagreement`（闸取在两界之间）。**两条反例对照证明闸不是恒判 `VOID-PREMISE`**（`D-G89`）。`--selftest`（夹具在 **`$HOME` 沙箱** `~/baseline-rate-gate-selftest/run-*`）另含**反极性**：把某行 declared 期望改错 ⇒ 必须 `rc≠0`。
#   ③ **接线（`verify-all.sh`：36 → 37 步；四处声明同趟）**：第 `[37]` 步 `BASELINE-RATE-GATE`（`--cases` 形态）。四处声明 = `VERIFYALL-STEPS-DECL` 首行 `37 gen=#64`／`VERIFYALL-STEP-NAMES` 尾加 `BASELINE-RATE-GATE`／头注释逐字 ``**`#64` 收官起 = 37 步**``（冻结器硬断言）／新建 `docs/WAVE64-PREREGISTRATION.md`（**标题行含字面 `#64`**）。现场 = `VERIFYALL_SELF=PASS names=37 decl=37 gen=#64 dup=0 order=OK prose=OK prereg=PASS`。
#   ④ **覆盖面 `159 → 161`**（`fp_inputs()` 加两行：**牙 ＋ 它的台账**；**先例**＝回归判定牙与它的台账**成对**在名单里）。三处作用：① 牙入名单 ② 台账入名单 ③ `close-wave.sh` **自含**于覆盖面而被改。
#      ⚠️ **`inputs_fp` 两笔（成对、带机械归因）**：`7836c5fa17cd454893f9a4101fe2210181217f035c306122cbbed259293a772f`（`#63` 冻后值 ＝ 本波 `prev_infp`）→ **`f148203453b092206b6a9f9529821fa58570ba7035fb5253ca4f4e8da6dd77ae`**。**组合式预测 == 实测**（`AFTER_PREDICTED == AFTER` ⇒ **无第三隐形位移**）；**8 格交叉表**（`C`＝`close-wave.sh` 自身／`G`＝牙行／`T`＝台账行）**全部退回 `C+G+T` ⇒ 159 件 ＝ `7836c5fa17cd454893f9a4101fe2210181217f035c306122cbbed259293a772f` 逐位相同**；每格**断言 `hits`**（缺断言那次吃过假"无位移"）。**现盘 ＝ `f148203453b092206b6a9f9529821fa58570ba7035fb5253ca4f4e8da6dd77ae` ＝ `infp.sh fp` 真函数实测逐位相同**；`dirty=0`（清单**逐行**必为 `<64hex>  <path>`）。
#      🆕 **`D-G120`（本波现场抓到的解析缺陷，已由主控立号）**：往 `printf '%s\n' … \ ` 的**续行参数表中间**插注释 ⇒ `\`＋换行合成一个逻辑行、`#` 在续行里仍起注释 ⇒ **吃掉参数表下半截**，且**后续三行成为新命令被真的执行** ⇒ 其 stdout 落进 `{ … } | sort | xargs sha256sum` ⇒ `sha256sum` 去 hash `BASELINERATE=NOINFO` 这种"文件名"、**真名被吞**。**现场数：`FILES_N` 读 `160`（应 161）、指纹凭空多出 `e4888835…`**。**两条必备牙**：① 清单**逐行**必须 `<64hex>  <path>`，否则响亮失败 ② `files_n` 与期望件数对账。**要害口径句**：**「`\` 续行的参数表中间不许插注释；凡指纹/清单类管线必须另有一条**独立于该清单**的证据（件数 ＋ 逐行形态断言）——『预测值 vs 实测值』同源时，自洽抓不到污染。」**（修法：注释移到**语句之前**、两行文件名留在参数表内；修后 `dirty=0`／`FILES_N=161`。）**`TASK-0718` 排 `#65` 做牙，本波不做。**
#   ⑤ **零产品改动**：`src/**`／`build/shims/**`／native 源**一字节未动** ⇒ 九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸 6123520 B**）⇒ 机械位移，**不许当漂移/回归判据**。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`（3601408 B）／`pf` `02b2792448fbd41d`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `d2b76a0a56a41be1`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`（293165 B）／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#63` 冻结值**：`pf` `9bf76afe89944ccc` → `02b2792448fbd41d`（**环成员 `D-G92`**：**同尺寸 6123520 B** ⇒ 机械位移）；其余**八位逐位未变**（`pc` 仍 `722e0ab8205b7c3f`、`windowsbase` 仍 `2e4e46e539a72cd7`、`win32shim` 仍 `d2b76a0a56a41be1`、`dwf` 仍 `ce3469f49efcbcfa`）。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   **冻前 `verify-all` = `37` 步（`37 ✅ / 0 ❌`、`用例通过 875 跳过 2`）**：见下 §RECORD 的 ⑥ 行。
#   —— 外挂声明（**两族必须落在最新 `# RE-FROZEN` 块内**；`column-floor-check.sh:229` 用 `grep -E '^# COLUMN-FLOOR '` 在本块里找，缺 ⇒ `COLUMN_FLOOR=NOINFO`（**缺声明 ≠ 通过**））——
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落地（全部 `temp ＋ rename`；前后 sha **双断言**；落前 `cp -p` 备份到 `~/w157a/w64-backup/`，**备份取在任何写之前**）】
#      `build/MilBridge/tools/baseline-rate-gate.sh` **新建** `31cf77abc6a882e3`（382 行）｜
#      `build/MilBridge/tools/baseline-rate-cases.tsv` **新建** `8d71171d475a63dc`（41 行／11 用例）｜
#      `verify-all.sh` `2819b5990e74cc80`（`run_step=36`）**→ `6a8ae4e80fefd97b`**（`run_step=37`）｜
#      `build/close-wave.sh` `9ee0c2488d25f6f6` **→ `168a33c3d4743559`**（名单 +2 行；覆盖面 159 → 161）｜
#      `docs/WAVE64-PREREGISTRATION.md` **新建** `cbcaceb4886f05a5`（111 行；标题行含 `#64`）｜
#      `~/w157a/w64-pre.sha`（开工前九位快照，**按 `#63` 冻结块九位行逐位重建**，现场 9/9 逐位相符）。
#   【② 缺陷复现（改前，逐字机读行）】`D-G120`（本波现场抓到，主控立号）：往 `fp_inputs()` 的 `printf … \` 参数表中间插 9 行注释 ⇒
#      最小复现 `bash -c 'printf "%s\n" A \`＋注释＋`B \`＋`C'` ⇒ 只印 `A`、`B` 被当命令执行（`行 4: B: 未找到命令`，且 **rc 仍是 0**）；
#      现场后果 `FILES_N=160`（应 161）、指纹 `e4888835…`（凭空多出，真名被吞、`sha256sum` 去 hash `BASELINERATE=NOINFO` 这种"文件名"）。
#   【③ 整波】`close-wave.sh --skip-verify-all`：槽内 `rc=0`、`[4/6]` **波前==波后 = `f148203453b092206b6a9f9529821fa58570ba7035fb5253ca4f4e8da6dd77ae`**；九位位移 = **预期只有 `pf`**（环成员）；**`inputs_fp` 必变**（见 §FROZEN）。
#   【④ 五臂／重钉】**本波不改 `GEN_KEYS`**（不动 `build/MilBridge/run.sh`／`HbTextLineParity/Program.cs`／`build/shims/PresentationCore.HbTextLine.cs`）⇒ **五臂不重取**、**五臂 sha 与 `#63` 逐位相同**（现场现算 5/5）；`known-red.json` 本波未改 ⇒ **无需重钉**（`REPIN_GENERATION` 现场状态见报告）。**臂日志聚合两口径**：`cat` 口径 = `2f276db59de241cb`、`find|sort|xargs` 口径 = `6e246ef5b87d69ea`。
#   【⑤ 门禁 ×2（槽内、严格串行）】**合格线 = 判词行逐字一致**（`BASELINE` 六条机读行 `result=PASS`、`pc:722e0ab8205b7c3f`／`pf:02b2792448fbd41d` 为终态）。
#   【⑥ 冻前 `verify-all`（槽内）】**`37 ✅ / 0 ❌`**、`rc=0`、`结论：✅ 全部通过`、**`用例通过 875 跳过 2`**。
#      ⚠️ 本波第 `[37]` 步是**新步**：现场 `BASELINERATE_CASES=11 passed=11 failed=0`／`BASELINERATE=PASS`；
#      并逐步骤核 `VERIFYALL_SELF=PASS names=37 decl=37 gen=#64 prose=OK prereg=PASS` ＋ `FP_INPUTS_HYGIENE=PASS coverage_n=161 artifact_n=0`。
#      另记一趟**作废**：首次 `verify-all` 我按 `--max-hold 900` 进槽 ⇒ 跑到第 `[17]` 步被 `HEAVYSLOT=MAXHOLD_KILL held=900s` 强杀 ⇒
#      **判"作废（持有上限，非读数）"**并改用 `--max-hold 1500` 重跑（口径来自 `#54` 那条方法学）。
#   【⑦⑧⑨ 待冻后追加（`APPEND_ONLY`）】冻结 `#64` 的 `FREEZE_RC`／四颗牙／**冻后 ×2 两趟**（各 `37 ✅ / 0 ❌`、`用例通过 875 跳过 2`、`NOFILE_SWAP`）／`~/w21-verify/w64-POST.done`（**真 `stat` 时刻**）／逐径推送 ＋ `HEAD:` 字节核对 ＋ app-local ＋ 两处哨兵（手工补 `BASELINE=#64 …`）。
#   【牙与件（现算 sha16）】`~/w157a/criteria.md`（`89ac288b87f13384`，**判据先行**）｜`~/w157a/baseline-rate-gate.md`（`c4839dc9e8876bcf`／口径 `57915081ffdbacf8`，方法页）｜`~/w157a/bin/baseline-rate-gate.py`（`0dac2ea941b56f4f`，独立算程）｜`~/w157a/bin/w64-attrib.py`（成对记账器，**每格断言 `hits`**）｜`~/w157a/w64-before.list`／`~/w157a/w64-after.list`（159／161 件清单）｜`~/w157a/w64-pre.sha`（九位快照）｜`build/MilBridge/W64-report.md`（链报告，`APPEND_ONLY`）。
#   【本波五条口径句（落册，均来自现场实测）】
#      ① **「条件同一性」必须包含『世界的时间稳定性』**：凡登记速率都必须带**时间窗**，且用于定 `N` 之前必须在**同窗现取**一道基线率闸 —— 对不上就 `VOID-PREMISE`，**不许拿历史速率凑功效**（`D-G118`）。
#      ② **干涉臂的入分母条件不许用「被去掉的那件事还在」**；要用「该拍上确实发生了这次尝试」＋各臂各自的忠实性断言（`D-G116` 第 4 实例，`AMENDMENT-2 §B3`）。
#      ③ **「谓词选错 ⇒ 恒 0 ⇒ 读成『线上没有』」**：族识别按 `type`、忠实验证按 `prop==type==靶原子`，**两个谓词各管一件事，不许混用**（`D-G116` 第 5 实例 · 具名陷阱 `PROP-VS-TYPE`）。
#      ④ **口径之争先于结论**：同一件事有两个口径（单侧/双侧）时，**两口径在判据上打架 ⇒ `NOINFO` 且具名**，禁止挑对我方有利的那一界下判词。
#      ⑤ **`\` 续行的参数表中间不许插注释**；凡指纹/清单类管线必须另有一条**独立于该清单**的证据（件数 ＋ 逐行形态断言）—— **「预测值 vs 实测值」同源时，自洽抓不到污染**（`D-G120`）。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:02b2792448fbd41d,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w157a/gate-e
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:02b2792448fbd41d,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w157a/gate-e
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:02b2792448fbd41d,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w157a/gate-e
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:02b2792448fbd41d,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w157a/gate-e
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:02b2792448fbd41d,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w157a/gate-e
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:02b2792448fbd41d,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w157a/gate-e
# ⏪ **（历史，已被 `#64` 取代）**# RE-FROZEN #63 —— ✅ **当前冻结基线** —— 内容 = **判据／显示层批 D**（**零产品改动**）：① `D-G115` 判词补「方向」 ② `D-G116` 新牙「跨臂体制同一性」 ③ `D-G117` 自报抽取器隐去状态（两半） ④ `known-red.json` 陈旧 `why` 更正＋重钉；并把第 `[36]` 步接进 `verify-all`（**35 → 36 步**）。
#   ① **`D-G115`（判词方向）**：`build/MilBridge/tools/regression-decision.py` `71734fce77842478`（1003 行）**→ `6a0e8ccc0c6cb5d7`**（1058 行）。新增机读行 **`REGDEC_DIRECTION=A高于B|B高于A|无显著差`**（由 `p` ＋ 两臂**点估计现算**）＋ 图例行 `REGDEC_DIRECTION_LEGEND`（`A`=新臂／被试件，`B`=旧臂／对照件）；判词**按方向选词**：上行 ⇒ `rate-aggravated`（**既有口径逐字保留**）／下行 ⇒ `rate-mitigated` ＋ 逐字写「**这不是本波引入** —— 本波做的是把它**压下去**」；**显著 ∧ 两臂点估计相等 ⇒ 方向算不出来 ⇒ `NOINFO`**（不许印任何方向词）。**成对现场**：`--old 24/27 --new 0/40 … --old-repro yes` ⇒ 修前 `rate-aggravated`（**印反**：事实 88.9% → 0%）／修后 `REGDEC_DIRECTION=B高于A` ＋ `rate-mitigated`。`--selftest` **26/26 → 28/28**（**只增两例**：下行＋上行）；台账 `regression-decision-cases.tsv` `5d3c26a1c8d83688` → `de6290cfad8892a1`（**+2 行**）⇒ 真台账 `--cases` **9/9 PASS**。**口径句**：判词带方向断言 ⇒ 判据必须真的判方向；双尾显著 ≠ 上行显著。
#   ② **`D-G116`（跨臂体制同一性）**：**新建** `build/MilBridge/tools/regime-identity-check.sh` **`97cfab155dfa9bce`**（284 行）。**体制列 = 输入侧四列**：`BASE`／`MAXGEOM`（`AFTER_M1` 的 geom）／`START_MAX`／`m_ok`；不等 ⇒ 该 `pair` 标 `INCOMPARABLE` ＋ **逐腿点名** ＋ `FAIL`。**结果侧**（`after_R` geom／`r_ok`／`r_ok2`／`fgeom`／`frame`／`CFG_HIT`／`GEOWRITE`）**只作诊断列 `REGIME_OUTCOME_DIAG=`、不进 `rc`** —— **"不进 `rc`" ≠ "不显示"**。**口径句**：**把结果算进体制，等于用「保护可比性」的名义否掉可比性。** ⚠️ 这一条是 `#63` 派单的**规格错误**（原表把 `AFTER_R2_SETTLED` 的 `fgeom` 列进体制），由车道现场现算推翻、主控 `2026-09-24` **裁定采纳车道方案**：39 腿 / 6 pair 实测 **输入侧四列在多臂 pair 里逐项相同（0 个不可比）**，而 `fgeom` **与 `r_ok2` 39/39 同向**（修后臂 `800x600@+0+0 ∧ r_ok2=1`；修前臂 `1280x1024@+0+0 ∧ r_ok2=0`）⇒ 若把它算进体制，**A1／POL2（唯一的两个多臂 pair）全部被判不可比**。另断言「**判红 = 四件合取**」（`START_MAX=0 ∧ m_ok=1 ∧ r_ok2=0 ∧ APP_ALIVE=yes`；`APP_ALIVE` 的**声明式派生** = `RESULT` ∧ `AFTER_R2_SETTLED` ∧ `DONE` 三行都在）⇒ **单格 `r_ok2` 判红必判违规**。现场：`REGIME_IDENTITY=PASS reason=ok legs=39 pairs=6 multi_arm_pairs=2 incomparable=0 red=19 red_violations=0 unchecked=1`。**射程缺口逐字上屏**：`REGIME_NOT_IN_LEDGER frame-at-base reason=probe-no-T0-decoration-geom` ＋ `REGIME_UNCHECKED=1`（现台账不记录 T0 装饰几何 ⇒ **不冒充"装饰也查过了"**）。`--selftest` **12/12**。
#   ③ **`D-G117`（显示层把状态吃掉）**：**两半同趟**。半① `build/MilBridge/tools/prereg-four-requirements-check.sh` `235d76b61cdc46a4`（443 行）**→ `a40aac9031304a8f`**（459 行）：批次门禁形态下**逐件输出先缓冲**，末尾把批次判词行印在**最前面** —— `PREREG4=<批次判词> files=… pass=… fail=… na=… noinfo=… out_of_scope=…`（**逐字匹配**抽取正则、**零语义改动**）。半② `verify-all.sh` 的「自报口径」抽取器：**值词表 `(PASS|FAIL|NOINFO) → (PASS|FAIL|NOINFO|NA|SKIP|REPORT)`**（本仓工具今天真会印的状态）＋ **汇总/计数/射程三类行**（`…_SUMMARY`／`…_COUNTS`／`…_SCOPE `）另开出口；显示窗 `12 → 16`（**只放宽显示窗、判定语义零改动**，与 `#31` 那次 `8 → 12` 同口径）。**成对现场**：修前屏上只有 `自报口径 PREREG4=PASS`（`na=4`／`out_of_scope=38` 只在步日志）⇒ 修后首行 `PREREG4=PASS files=43 pass=1 fail=0 na=4 skip=0 noinfo=0 out_of_scope=38`；**阳性对照**（喂「只有 `NA` 态」的步）⇒ `PREREG4=NA` ＋ `PREREG4_SUMMARY …` **都上屏**。**口径句**：判据的沉默/半可见，必须能被证明是「没东西可判」，而不是被显示层吃掉。
#   ④ **`known-red.json` 陈旧 `why`**：`cc0dd903972d7f73` **→ `2209966ee1d2c5cc`**（`generation.geom_corpus.why` 里那句**与现场为假**的『本波（`#59`）只接线、不改两件牙……今天**没有机器读它**』⇒ 逐字留档 ＋ 更正为『**本键有机器读者** = `build/MilBridge/tools/geom-revert-beat-check.sh` 的 `GEOMCORPUS=` 那一格；`#59` **实测改了牙1**（`9412ec0149111348 → ee43a703736489a3`）而**该牙就是读者**（实际读点 `:283`，`:274` 是它的文档串）⇒ 纪律 47 那条缺口在 `#59` 落地时即已闭合；另一件牙 `geom-resend-regression-check.sh` 现场 `grep` = **0 命中**』）；同趟 `repin-generation.py --why` 重钉 ⇒ `REPIN_GENERATION=PASS`，**世代三项／五臂／证据日志／`geom_corpus.sha256` 逐位未变**。
#   ⑤ **接线（`verify-all.sh`：35 → 36 步；四处声明同趟）**：第 `[36]` 步 `REGIME-IDENTITY`。四处声明 = `VERIFYALL-STEPS-DECL` 首行 `36 gen=#63`（**位置锚**：解析首个 `^#\s*VERIFYALL-STEPS-DECL:\s*(\d+)\s+gen=(#\d+)` ＋ **先断言 `DECL 数 == grep -c '^run_step "'`** 再插，**不照抄上一代文本**）／`VERIFYALL-STEP-NAMES` 尾加 `REGIME-IDENTITY`／头注释逐字 ``**`#63` 收官起 = 36 步**``（冻结器硬断言）／新建 `docs/WAVE63-PREREGISTRATION.md`（**标题行含字面 `#63`**）。`verifall_self` 现场 = `VERIFYALL_SELF=PASS names=36 decl=36 gen=#63 dup=0 order=OK prose=OK prereg=PASS`。
#   ⑥ **零产品改动**：`src/**`／`build/shims/**`／native 源**一字节未动** ⇒ 九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸 6,123,520 B**）⇒ 机械位移，**不许当漂移/回归判据**。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`（3601408 B）／`pf` `9bf76afe89944ccc`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `d2b76a0a56a41be1`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`（293165 B）／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#62` 冻结值**：`pf` `3c808e94034c4514` → `9bf76afe89944ccc`（**环成员 `D-G92`**：**同尺寸 6,123,520 B** ⇒ 机械位移）；其余**八位逐位未变**。
#   ⚠️ **`inputs_fp` 两笔（成对、带机械归因）**：`1ffd13f7c927dea71fd5dca866f7c6f81e8efce9939c22c85d55c0a35fb20f96`（`#62` 冻后值）→ **`7836c5fa17cd454893f9a4101fe2210181217f035c306122cbbed259293a772f`**。**覆盖面 `158 → 159` 件**：
#      ① 被改 4 件：`regression-decision.py`／`regression-decision-cases.tsv`／`known-red.json`／
#         **`build/close-wave.sh`**（后者是**名单变更**所致 —— `close-wave.sh` **自含于**覆盖面，设计使然）；
#      ② **新增 1 件**：`build/MilBridge/tools/regime-identity-check.sh`（**新牙入名单**，与 `#62` 加
#         `proc-pattern-guard.sh` **同形**存量惯例；位置锚 = `geom-resend-regression-check.sh` 之后）。
#      **机械归因（16 行交叉表 ＋ 断言命中数）**：把 4 件**逐件/逐子集**退回 `#62` 版（新牙行**删除**）重算指纹 ⇒
#      **全部退回（hits=5）＝ `1ffd13f7c927dea71fd5dca866f7c6f81e8efce9939c22c85d55c0a35fb20f96` ＝ `#62` 声明值逐位相同**；
#      **现盘 ＝ `7836c5fa17cd454893f9a4101fe2210181217f035c306122cbbed259293a772f` ＝ `infp.sh fp` 真函数实测逐位相同**；16 档**互不相同**（hits 逐档 0/1/2/3/4）⇒ 无静默 no-op。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   **冻前 `verify-all` = `36` 步（`36 ✅ / 0 ❌`、`用例通过 875 跳过 2`）**：见下 §RECORD 的 ⑥ 行。
#   —— 外挂声明（**两族必须落在最新 `# RE-FROZEN` 块内**；`column-floor-check.sh:229` 用 `grep -E '^# COLUMN-FLOOR '` 在本块里找，缺 ⇒ `COLUMN_FLOOR=NOINFO`（**缺声明 ≠ 通过**））——
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落地（全部 `temp ＋ rename`；前后 sha **双断言**；落前 `cp -p` 备份到 `$HOME/w152a/backups/`）】
#      `regression-decision.py` `71734fce77842478`（1003 行）**→ `6a0e8ccc0c6cb5d7`**（1058 行）｜
#      `regression-decision-cases.tsv` `5d3c26a1c8d83688` → `de6290cfad8892a1`（15 行）｜
#      `regime-identity-check.sh` **新**（284 行）｜
#      `prereg-four-requirements-check.sh` `235d76b61cdc46a4`（443 行）**→ `a40aac9031304a8f`**（459 行）｜
#      `verify-all.sh` `58422c5f1f2c5682`（1122 行／`run_step=35`）**→ `2819b5990e74cc80`**（1139 行／`run_step=36`）｜
#      `close-wave.sh` `07ee249b8f570895` **→ `9ee0c2488d25f6f6`**（名单 +1 行）｜
#      `known-red.json` `cc0dd903972d7f73` → `2209966ee1d2c5cc`｜
#      `docs/WAVE63-PREREGISTRATION.md` **新**（`#63` 在标题）。
#   【② 缺陷复现（改前，逐字机读行）】
#      `D-G115`：`--old 24/27 --new 0/40 --same-time --old-sha16 feef049e9d0e313a --new-sha16 4e25e4b27d4d5ae1 --pairs 40 --pair-old-only 24 --old-repro yes --planned-legs 40 --planned-power 0.80`
#        ⇒ 修前 `REGDEC_SUBKIND=rate-aggravated` ＋ `REGDEC_REASON reason=rate-aggravated(fisher_p=3.006e-15≤alpha 且旧件也红 ⇒ …本波把速率**显著加重**…)` —— **事实是 88.9% → 0%**（降到 0）⇒ **判词方向印反**。
#      `D-G116`：`fgeom` 与 `r_ok2` **39/39 同向**（修后臂 `800x600@+0+0 ∧ r_ok2=1`；修前臂 `1280x1024@+0+0 ∧ r_ok2=0`）⇒ 它是**结果**不是**体制**（见 §FROZEN ②）。
#      `D-G117`：修前屏上只有 `自报口径 PREREG4=PASS`，`na=4`／`out_of_scope=38` 只在步日志。
#   【③ 整波】`close-wave.sh --skip-verify-all`：槽内 `rc=0`、`[4/6]` **波前==波后 = `7836c5fa17cd454893f9a4101fe2210181217f035c306122cbbed259293a772f`**；九位位移 = **预期只有 `pf`**（环成员）；**`inputs_fp` 必变**（见 §FROZEN）。
#   【④ 五臂／重钉】**本波不改 `GEN_KEYS`**（不动 `build/MilBridge/run.sh`／`HbTextLineParity/Program.cs`／`build/shims/PresentationCore.HbTextLine.cs`）⇒ **五臂不重取**、**五臂 sha 与 `#62` 逐位相同**（现场现算 5/5）；**`known-red.json` 本波改了（只改散文）** ⇒ 同趟 `repin-generation.py --why/--check`（`REPIN_GENERATION=PASS`，**世代三项／五臂／证据日志／`geom_corpus.sha256` 逐位未变**）。
#   【⑤ 门禁 ×2（槽内、严格串行）】**合格线 = 判词行逐字一致**。
#   【⑥ 冻前 `verify-all`（槽内）】**`36 ✅ / 0 ❌`**、`rc=0`、`结论：✅ 全部通过`、**`用例通过 875 跳过 2`**；
#      ⚠️ **本波是首个带「自报口径抽取器改动」的波** ⇒ 逐步骤核对「匹配行数 ≤ 显示窗（16）」且「总判行在窗内」，
#      并把三类新增出口行的**实际条数**逐段点名（见报告 §…「自报口径窗核对表」）。
#   【⑦⑧⑨ 待冻后追加（`APPEND_ONLY`）】冻结 `#63` 的 `FREEZE_RC`／四颗牙／**冻后 ×2 两趟**（各 `36 ✅ / 0 ❌`、`用例通过 875 跳过 2`、`NOFILE_SWAP`）／`~/w21-verify/w63-POST.done`（**真 `stat` 时刻**）／逐径推送 ＋ `HEAD:` 字节核对 ＋ app-local ＋ 两处哨兵。
#   【牙与件（现算 sha16）】`~/w152a/criteria63.md`（**判据先行**）｜`~/w152a/report.md`（链报告，`APPEND_ONLY`）｜
#      `~/w152a/logs/patch-dg115.py`／`patch-dg117a.py`／`wire-verify-all63.py`（**位置锚**补丁器，每条替换 `assert count==1`）｜
#      `~/w152a/w63-pre.sha`（开工前九位快照，**按 `#62` 冻结块九位行逐位重建**）。
#   【本波四条口径句（落册，均来自现场实测）】
#      ① **「结果」不许算进「体制」**：把与被试项**同向**的量当体制条件 ⇒ 会**用「保护可比性」的名义否掉可比性**（`D-G116`）。
#      ② **「不进 `rc`」≠「不显示」**：结果侧差异必须**照样可见**（诊断列），否则就是另一种「显示层把状态吃掉」。
#      ③ **判词带方向断言 ⇒ 判据必须真的判方向**；双尾显著 ≠ 上行显著（`D-G115`）。
#      ④ **对拍/解析在任一侧为空时必须响亮失败**；且**替换/撤销类脚本必须断言命中行数**（本波现场：交叉表第一版静默匹配 **0** 行 ⇒ 8 档全部同值 ＝ 假「无位移」；断言后 hits=5 才成立）。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:9bf76afe89944ccc,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w152a/gate-r1
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:9bf76afe89944ccc,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w152a/gate-r1
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:9bf76afe89944ccc,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w152a/gate-r1
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:9bf76afe89944ccc,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w152a/gate-r1
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:9bf76afe89944ccc,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w152a/gate-r1
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:9bf76afe89944ccc,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w152a/gate-r1
# ⏪ **（历史，已被 `#63` 取代）**# RE-FROZEN #62 —— ✅ **当前冻结基线** —— 内容 = **装置欠债批 C（`TASK-0714`：把「按模式收/数进程」做成牙）＋ 文档收尾（`TASK-0715` 剩余两件）**
#   ① **背景（`D-G103` 族本会话咬 5 次，全零损害）**：① `pkill -f '<模式>'` 误杀自身本体｜② `pgrep -P "$$" -f <模式>`（`$$` 只作 **`-P` 集合限定**、**不构成"排除"**；命令替换的子 shell 与脚本同源 argv ⇒ 仍自匹配）｜③ 收拾看门狗时把自己那条 shell `kill -TERM`｜④ 数残留进程**把自己算进去**（假阳性 1）｜⑤ `--live-selftest` 按**整条 cmdline 子串**判"显示被占" ⇒ 自匹配伪报 `display busy`。判据 = **凡按模式匹配命令行文本收/数进程，必须能证明排除了自身（`$$` ∧ `$PPID` 两者），能按 PID 就绝不按模式**。
#   ② **接线（`verify-all.sh`：**实测 34 → 35 步**；四处声明同趟）**　⚠️ 基线是**实测 34**（`#60` 收官起，`DECL` 首行 `34 gen=#60`、`^run_step "` 计 34）—— **不是** `#59` 的 33；本波 +1 ⇒ 预期 **35**，**以落地时实测 + 1 为准**。：新步 `PROC-PATTERN-GUARD`（`build/MilBridge/tools/proc-pattern-guard.sh`；纯读、零 `dotnet`、无 `X`、秒级）。四处声明 = `VERIFYALL-STEPS-DECL` **首行** `35 gen=#62`（**位置锚**：解析**首个** `^#\s*VERIFYALL-STEPS-DECL:\s*(\d+)\s+gen=(#\d+)`；插在它**之上** —— 本仓每代都在其上方再插一行 ⇒ **不许用上一代文本当锚**）/`VERIFYALL-STEP-NAMES` 行尾追加 `` | PROC-PATTERN-GUARD ``/头注释口径句**逐字** `` **`#62` 收官起 = 35 步** ``（`verify-all-step-check.sh:169` 用 `grep -qF` 找，一个字符都不能改）/新建 `docs/WAVE62-PREREGISTRATION.md`（**标题行含 `#62`** —— 冻结器的 `prereg` 前置）。**预期** `VERIFYALL_SELF=PASS names=35 decl=35 gen=#62 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=58422c5f1f2c5682`。
#   ③ **牙本体（仓外原型 → 落仓）** `~/w154a/tooth/proc-pattern-guard.sh`：三态 `PROCGUARD=PASS|FAIL|NOINFO`（**红优先于 `NOINFO`**）；`FAIL` 时**逐处点名** `file:line` ＋ 形态 ＋ 缺什么 ＋ 理由码（`missing-any-proof`／`missing-PPID($$-only-as--P-set-restriction)`／`missing-$$`／`exclude-self-label-without-pid`／`proc-scan-no-self-exclusion`）；`--selftest` **19/19**（两例两极化 ＋ 现场各次咬的**专门格**：裸 `pkill -f` 必红／`/proc` 双排除必绿／`pgrep -P "$$" -f` 必红／`pkill -x` 名模式必绿／`--exclude-self` 单标签必红／**注释里的 `pkill -f` 必绿**（防 20+ 条纪律注释被误判）／`ps|grep -c` 必红／祖先链必绿／`kill $(pgrep -f)` 必红／`/proc` 子串自匹配必红／argv 身份必绿／零命中树必 `PASS`（活性证明）／空树必 `NOINFO`／**自扫本件零 `pkill`**）；件内**零** `pkill`/`pgrep`（读 `/proc` 并显式排除自身 pid）；输出固定打 `PROCGUARD_BLINDSPOT indirect=invisible eval=invisible non-sh-py=invisible outside-repo=invisible interactive=invisible`。
#   ④ **同趟必须修的 6 处调用点**（**承重**：接线那一刻树上必须绿，否则新步在落地当场就 ❌）：`tests/WpfGfx.Linux.Tests/Windowing.Tests/start-xvfb.sh:33`（裸 `pkill -f "Xvfb :<显示号变量>"`）｜`tests/.../Presentation.Tests/run-wpfprobe.sh:109` 与 `run-wpftextdemo.sh:339`（`pgrep -P "$$" -f …`＝事故 ② 形态）｜`run-wpftextdemo.sh:380`（只排 `$$`，`missing-PPID`）｜`run-wpfprobe-1400rate.sh:63`（只记录）与 `:108`（`pgrep -c -f` 数残留＝事故 ④）。**修法**（逐处，见 `~/w154a/tooth-plan.md` §5）：改读 `/proc/<pid>/cmdline` ＋ **argv 精确比对** ＋ **`$$` ／ 父进程 pid 变量 双排除**，或补上父进程 pid 的排除；**不许**退化成 `pgrep -x`／`pkill -x` 之类的"按名字全局杀"（会跨车道误伤）。**这 6 处全是测试装置/runner，不是九位产品件** ⇒ 不触发整波产品位移；且 `tests/**` **不在** `fp_inputs()` 覆盖面里（与 `#47` 记录一致）。
#   ⑤ **判据件入覆盖面**：`build/close-wave.sh` 的 `fp_inputs()` 名单**同趟**加 `build/MilBridge/tools/proc-pattern-guard.sh`（位置锚：`build/MilBridge/tools/geom-resend-regression-check.sh \` 那一行**之后**；尾行 `regression-decision-cases.tsv` 保持最后一行不动）。⇒ `coverage_n 157 → 158`（**恰好 +1**）、`proc-pattern` 命中 **0 → 1**；`close-wave.sh` **自含于**覆盖面 ⇒ 改它必改 `inputs_fp`（设计使然）。
#   ⑥ **文档收尾（`TASK-0715` 剩余两件；文档不是路由键 ⇒ 不动 `DEFREG`）**：`docs/FORK-AND-PUSH.md`（155 行，09-20）＋ `docs/PORT-SPEC.md`（99 行，09-23）按 `~/w154a/docs-align.md` 的 **17 个 hunk（15 替换 ＋ 2 插入）**：`FORK-AND-PUSH.md` 10 处 ＋ `PORT-SPEC.md` 7 处改写为**现读事实**：`git` **在**（`/usr/bin/git` 2.34.1）／fork 已建且 **`feat-Linux` 已是默认分支**（`ls-remote --symref`）／本地 == 远端 `a87b301`／工作树 **421 MB**（原写 384）／`verify-all` **不是 25 步**（**以 `VERIFYALL-STEPS-DECL` 首行为准**）／发波链 ② 补 **native 必须另跑 `src/WpfGfx.Linux.Native/build-shim.sh --all`**（`integration-wave.sh` **从不编译 native**）／⑥ 改**条件式**（未重取臂 ⇒ 冻前可能全绿）／⑨ 记录件加 **`build/MilBridge/HANDOFF-NEXT.md`**（**不是** `handoff.md` —— 那是 `HO` 路由键、**不许删行**）＋ **先建模板再冻结**（`#57` 的坑）。**`README-Window.md` 一字不动**（上游原文逐字保留）。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`（3601408 B）／`pf` `3c808e94034c4514`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `d2b76a0a56a41be1`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`（293165 B）／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#61` 冻结值**：`pf` `d5de121c1c787193` → `3c808e94034c4514`（**环成员 `D-G92`**：整波重建必变、**同尺寸 6,123,520 B** ⇒ 机械位移，**不许当漂移/回归判据**）；其余**八位逐位未变**（`pc` `722e0ab8205b7c3f`／`wb` `2e4e46e539a72cd7`／`wsh` `d2b76a0a56a41be1`／`dwf` `ce3469f49efcbcfa` 同上代）⇒ **主控独立现算复核**。
#   ⚠️ **`inputs_fp` 两笔（成对、带机械归因）**：`a00bf53a64c47531963b0f82aae689fe4cee1363c7b9e670799566cb7963c668`（`#61` 冻后值）→ **`1ffd13f7c927dea71fd5dca866f7c6f81e8efce9939c22c85d55c0a35fb20f96`**。归因 = **本波动了覆盖面 157 → 158 件**：**新增 1 件**判据件（`build/MilBridge/tools/proc-pattern-guard.sh`，本波同趟纳入名单）＋ 一件被改（`build/close-wave.sh` 自身的名单行 ⇒ 它**自含于**覆盖面，设计使然）。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波**未改桥源** ⇒ 逐位未变）。
#   **冻前 `verify-all` = `35` 步**：见下 §RECORD 的 ⑥ 行（**条件式预期**：本波**未重取臂** ⇒ 冻前声明类红"可能全绿"，**照现场报，不许为凑预期去动东西**）。
#   **本波同趟改到 `#62`**：新建 `docs/WAVE62-PREREGISTRATION.md`（**标题行含 `#62`**）＋ `verify-all.sh` 四处声明 ＋ `build/close-wave.sh` 名单 ＋ 六处调用点 ＋ `docs/FORK-AND-PUSH.md`／`docs/PORT-SPEC.md`（逐字草案见 `~/w154a/docs-align.md`）。
#   **边界／`NOINFO`（照录，不许缩小）**：① 牙**只判仓内 `*.sh`/`*.py` 的静态文本**，**不管**"按 PID 杀对了没有"，也不管仓外脚本（5 次咬里多发生在 `$HOME/**` 的车道目录 ⇒ 它**判不了**）⇒「牙 `PASS`」**不**等于"这台机器上不再有自匹配事故"；② 牙看不见**变量间接／`eval`／非 `.sh`·`.py` 的调用方／非 shell heredoc 体**（如 `python3 - <<EOF`）⇒ 件头与输出**双声明**；③ `proof=full` 是"**能证明**"不是"已证明跑对"（构造本身写错看不见 ⇒ 只有成对实验能证）；④ `--exclude-self` 目前**仓内无任何程序理解它** ⇒ 判据要求它**必须**与具体 `$$`/`$PPID` 同域出现（防"贴标签就绿"）；⑤ `rc=2`（`NOINFO`）在 `verify-all` 里**就是 ❌**（`run_step` 只认 `rc==0`）—— 这是**有意**的：**缺声明 ≠ 通过**；⑥ **红优先于 `NOINFO`**（不许用 `NOINFO` 把 `FAIL` 遮成灰）。
#   —— 外挂声明（**两族必须落在最新 `# RE-FROZEN` 块内**；`column-floor-check.sh:229` 用 `grep -E '^# COLUMN-FLOOR '` 在本块里找，缺 ⇒ `COLUMN_FLOOR=NOINFO`（**缺声明 ≠ 通过**））——
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落地（全部 `temp ＋ rename`；前后 sha **双断言**；**幂等守卫** ＝ 插入前断言目标文本尚不存在）】`verify-all.sh`（33 步）→ **35 步**｜`build/MilBridge/tools/proc-pattern-guard.sh` **新**（自报 sha16 落地后现算）｜`build/close-wave.sh` 名单 `+1` 行｜六处调用点（`start-xvfb.sh`／`run-wpfprobe.sh`／`run-wpftextdemo.sh` ×2／`run-wpfprobe-1400rate.sh` ×2）｜`docs/WAVE62-PREREGISTRATION.md` **新**｜`docs/FORK-AND-PUSH.md`／`docs/PORT-SPEC.md`（逐字 hunk，落完 `grep -c` 逐处复核）。
#   【② 缺陷复现（改前，逐字机读行）】牙在**只读闸下**对 `$R` 的现场读数（本波开工前）：`PROCGUARD_SCOPE files=161 hits=15 na=2 full=9 partial=6` ⇒ **`PROCGUARD=FAIL reason=missing-self-exclusion`**（**历史两次读数 `hits=7 full=1` 与 `hits=9 full=3` 均已作废并归因**：前者是牙自身一处计数改法所差；后者未含「引号式 /proc 路径」那 6 处**本来就已证明**的命中。**三次读数里 `partial=6` 的集合始终相同** ⇒ 落地范围未变。归因与四修见 `~/w154a/report.md` §10／§12 与 `criteria.md` §7.5）；`full=3` = **仓内既有的正确样板**三处：`build/close-wave.sh:292`（`self_chain_pids` 祖先链）＋ `geom-revert-beat-check.sh:141`／`:143`（`/proc` 扫描 ＋ 双排除 ＋ argv 身份）。`na=2` = `verify-all.sh:434/496` 的 `pgrep -a Xvfb`（**名字模式**、按判据**不适用** ⇒ 不许判红）。
#   【③ 整波】`close-wave.sh --skip-verify-all`：槽内 `rc=0`、`失败步骤=0`、`[1/6]` appliers 读数、`[4/6]` **波前==波后 = `1ffd13f7c927dea71fd5dca866f7c6f81e8efce9939c22c85d55c0a35fb20f96`**；九位位移 = **预期只有 `pf`**（环成员）；**`inputs_fp` 必变**（新纳 1 件 ＋ `close-wave.sh` 自含）⇒ 见 §FROZEN。
#   【④ 五臂／重钉】**本波不改 `GEN_KEYS`**（不动 `build/MilBridge/run.sh`／`HbTextLineParity/Program.cs`／`build/shims/PresentationCore.HbTextLine.cs`）⇒ **五臂不重取**、**五臂 sha 与 `#61` 逐位相同**（现场复核 5/5）。⚠️ **本波采用路线 A（把 6 处修好）⇒ 不改 `known-red.json`**；故这一段**预期不触发**（`known-red.json` 的陈旧 `why` 重钉已划给 `#63`，本波不碰）。若万一改了它 ⇒ 同趟 `repin-generation.py --why/--check`，并注意 `DEFREG_EXTRA=KRJ=` 变化 ⇒ **主控同趟重发 `defect-registry-declared.tsv` 归零 `DECLDRIFT`**。
#   【⑤ 门禁 ×2（槽内）】两趟逐行对拍合格线 = **判词行逐字一致**（跑次戳／临时目录随机后缀／仪器计数漂移**不算差异但必须点名**）。读数见 §FROZEN。
#   【⑥ 冻前 `verify-all`】见 §FROZEN：`35` 步、`用例通过 875 跳过 2`；**声明类红照现场报**（本波**未重取臂** ⇒ 若全绿就报全绿，**不凑预期**）。
#   【⑦⑧⑨ 待冻后追加（`APPEND_ONLY`）】冻结 `#62` 的 `FREEZE_RC`／四颗牙／**冻后 ×2 两趟**（各 `35 ✅ / 0 ❌`、`用例通过 875 跳过 2`、`NOFILE_SWAP`）／`~/w21-verify/w62-POST.done`／逐径推送 ＋ `HEAD:` 字节核对 ＋ app-local ＋ 两处哨兵。
#   【牙与件（现算 sha16）】`~/w154a/criteria.md`（**判据先行** `§0–§6`）｜`~/w154a/tooth/proc-pattern-guard.sh`（牙原型，`--selftest` **19/19**）｜`~/w154a/tooth-plan.md`（四处声明的**位置锚** ＋ 6 处最小修法 ＋ 落地脚本五条硬要求）｜`~/w154a/docs-align.md`（25 处 hunk，`OLD` 逐字 `count==1` 已机械复核）｜`~/w154a/w62-record.draft.txt`（**本模板**）｜`~/w154a/report.md`。
#   【两条新落册的口径句（均来自现场实测）】① **"必须成为 `head -1`"的插入，锚必须是位置**（`VERIFYALL-STEPS-DECL` 首行每代都被上一波在其**之上**再插一行；本车道落地前实测 `#59` = `33 gen=#59`，插在它之上才对）。② **改调用点前先看它有没有"自审行"**：`run-wpfprobe.sh:104`／`run-wpftextdemo.sh:472` 的 `KILL_AUDIT` 只禁 `pkill|killall|kill -f`，**不禁 `pgrep -f`** ⇒ 本波必须**同时**把 `pgrep` 族写进判据（否则"改了却没人看"）。
#   【⑦ 冻结（`FREEZE_RC=0`）】基线重冻为 `#62` ⇒ 见 `docs/CURRENT-STATE.md:9` 的 `BASELINE-FROZEN gen=#62 sha16=` （落地时现填）／字节数（落地时现填）。上代 `#61` 值**成对留档**。世代交叉断言：`树上 #61 == GENS[#62][prev]`；`牙齿②：^run_step " = 35 == 步数 35，且头注释逐字声明了同一数字`。
#   【⑧ 冻后 `verify-all` ×2】**两趟各 `35 ✅ / 0 ❌`（`rc=0`、`结论：✅ 全部通过`）**、`用例通过 875 跳过 2`、`SKIP_GUARD=PASS x_state=available violations=none`、`X-REUSE=reused display=:99`。**对拍**：两趟判词逐字一致；**冻前 vs 冻后也逐字一致**；仪器计数漂移照实点名。**`NOFILE_SWAP=YES`**（判据 `C4`）：`before=after=saved_shim=`（落地时现填）。
#   【⑧ 放行标记】两趟连续绿之后创建 `~/w21-verify/w62-POST.done` ⇒ 它是 `#63` 的放行信号。
#   【⑨ 推送／app-local／哨兵】逐径 `git add`（**绝不**从 `git status` 生成清单）；**快进判据用远程实况** `git ls-remote origin feat-Linux`（⚠️ **不用**陈旧跟踪引用 `origin/feat-Linux`）；`BYTECHECK ok=<N> mismatch=0`（口径 `<N>/<N>`，逐件比 `$R` vs 克隆的 **`HEAD:`** blob）；fetch 的 `feat-Linux` 是**默认分支**（`ls-remote --symref origin HEAD` 现场复核）；**app-local** 走 `sync-applocal.sh` ＋ `check-applocal-sync.sh`（合格线 `STALE=0` ∧ `DIVERGENT=0`）；**两处哨兵**（`/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag`）逐位复核九位并手工补 `BASELINE=#62 sha16=… bytes=…`，两处 `cmp` = **IDENTICAL**。
#   【牙自身的读数也要进记录（主控 `#62` 裁定）】落地后必须把**两颗现读**写进本记录：① 牙的 `--selftest` 例数（现读 **19/19**，落地后若加例则照实报）；② 牙对**落地后**的 `$R` 的 `PROCGUARD_SCOPE` 行（预期 `files=162 hits≤9 na=2 full=… partial=0`，**`files` 由 161 → 162 是因为牙自己进了 `build/MilBridge/tools/`**）＋ 顶层 `PROCGUARD=PASS`。
#   【闸基线（主控 `#62` 改判，整行照抄机读行）】`PROCGUARD_SCOPE files=161 hits=15 na=2 full=9 partial=6 noinfo=0` ＋ `PROCGUARD=FAIL reason=missing-self-exclusion`。
#     · **判词依据**：`partial>0 → FAIL`｜`files < --min-files` ⇒ `NOINFO`｜`len(hits)==0 ∧ na==0` ⇒ 活性证明｜**否则 `PASS`** ⇒ **6 处修完 `partial=0` 即 `PASS`，与 `full` 的数量无关**。
#     · **历史读数**：`hits=7 full=1`（旧牙计数口径）→ `hits=9 full=3`（未含引号式 `/proc` 路径）→ **`hits=15 full=9`（现读）**；**三次 `partial=6` 的集合始终是同样那 6 处** ⇒ 判定语义与落地范围未变。多出的 6 个 `full` = `run-wpfprobe.sh:115-117`／`run-wpftextdemo.sh:351-353`（`argv-identity@loop`，**本来就已证明、以前"看不见"**）。
#   【牙自身的读数（落地后现取，整行照抄）】① `bash build/MilBridge/tools/proc-pattern-guard.sh --selftest | tail -1`（**落地后实测 `PROCGUARD_SELFTEST=19/19`**）；② `bash build/MilBridge/tools/proc-pattern-guard.sh --repo="$PWD" | grep -E '^PROCGUARD_SCOPE|^PROCGUARD='` ⇒ **落地后实测**：`PROCGUARD_SCOPE files=162 hits=21 na=4 full=21 partial=0 noinfo=0` ＋ `PROCGUARD=PASS reason=all-hits-proved`（`files 161 → 162` 的成因 = **牙自己进了 `build/MilBridge/tools/`**；`hits 15 → 21` = 6 处修法把裸模式调用换成 `/proc` 枚举后**被判为已证明**，而 `partial` 由 6 归 0）。
#     · **`files 161 → 162` 的成因**：**牙自己进了 `build/MilBridge/tools/`**（新件被自扫计入）—— 与"树里别的件变了"无关。
#   【交叉引用】① **`D-G119`（判据装置缺陷 · 域选错）**：四处自伤 = **掩码域**（假阴性：引号里的 `/proc/…/cmdline` 被抹 ⇒ 靠"看不见"过关）／**枚举域**（假阳性：把"读一个给定 pid 的 `/proc/$p/cmdline`"当枚举特征 ⇒ 函数参数被当循环变量）／**heredoc 域**（假阳性：`loop_ranges` 算全文 ⇒ Python heredoc 的 `for` 当 shell 循环 ⇒ 永不 `done`）／**注释域**（假绿：注释原文当 `probe` ⇒ 注释里的"已排除"当证明）；**对偶判据** = **"注释里的调用不算调用" 的对偶：注释里的"排除"不算证明**（`criteria.md` §2.0，钉子 = 自测格 `bad-proof-in-comment-only` 必红）。② **`D-G116`（跨臂体制同一性牙）**。③ 相关：`D-G103`（按模式收进程族）。
#   【⚠️ 落地期硬约束（主控 `#62` ⑤）】**交叉表把牙自身的 sha256 也算进名单** ⇒ **牙一变（哪怕只改注释），`only_tooth_in_list`／`after_predicted`／`only_cw` 都要重算**，且**改后的牙必须重新报 sha16 与 `--selftest` 例数**。**本件落地前必须用"最终牙"复算**（`python3 ~/w154a/logs/infp-cross-check.py` 不带 `--cw-new` 即打现值），**落地后复核 R1–R4**。现读值（以牙 `43fbe8a830526b6d` 复算）：`before=a00bf53a…`／`only_tooth_in_list=e2f7cb3fd083abf18880b62c96f4bd543f9253026b37a2ddf528fd99de989c48`／`only_cw_changed=f002b4bef022bfd4a076c3f1b55f6ecd9f9c994cb6aad1f97884e0695dcea87c`／`after_predicted=1ffd13f7c927dea71fd5dca866f7c6f81e8efce9939c22c85d55c0a35fb20f96`。
#   【本代常数补记（照 `#58`/`#59` 的体例，落地时如实记我补了什么）】向 `~/w21-verify/w27-freeze.py` 的 `GENS` 表加 `'#62'` 一项：`TXT='/home/links-dev/w21-verify/w62-record.txt'`（**先建模板、再冻结**）｜`prev='#61'`｜`nstep=35`｜`green` = `#61` 的既有项 **＋ `PROC-PATTERN-GUARD`**（本波**加一步**）｜`allow_changed={'pf'}`（零产品改动）｜`prev_pf`／`prev_pc`／`prev_wb`／`prev_wsh`／`prev_dwf` 一律取 **`#61` 冻后值**｜`infp`/`prev_infp` 现场取。
#   【⚠️ 模板级硬约束（本车道现场查出，落地时必读）】**记录正文里禁止出现 `$` 紧跟花括号加大写字母的写法** —— 冻结机器 `w27-freeze.py` 的占位符替换正则是"花括号里全大写"，它会把这种 shell 变量**当成未定义的占位符**并 `assert` **当场炸掉**（本车道第一版模板就踩了：`pkill -f "Xvfb :<变量>"` 与"补父进程 pid 排除"两处）。写 shell 片段时一律用 `$VAR` 形态、或用尖括号占位（如 `<显示号变量>`）。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:3c808e94034c4514,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w154a/gate-e2
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:3c808e94034c4514,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w154a/gate-e2
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:3c808e94034c4514,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w154a/gate-e2
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:3c808e94034c4514,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w154a/gate-e2
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:3c808e94034c4514,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w154a/gate-e2
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:3c808e94034c4514,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w154a/gate-e2
# ⏪ **（历史，已被 `#62` 取代）**# RE-FROZEN #61 —— ✅ **当前冻结基线** —— 内容 = **判据接线/射程波 · 零产品改动**：把三处**能造出假绿/假红的旋钮**接死 —— ① **`D-G113`「假旋钮」⇒ connect**（`--fix=`/`--pre=` **真的**进判据）② **`TASK-0710`** `--leg=` 旁路 ⇒ **judge**（派生语料**真判**、`--leg` 档 `NOT_APPLICABLE` 且**不传染**）③ **`TASK-0711`** 仓内 runner **首写点截断**（`>>` → `>`）。**三件都不加步**（**34 → 34**）。
#   ① **件①（`D-G113`：假旋钮 ⇒ connect）**：`build/MilBridge/tools/geom-resend-regression-check.sh` `cd375326b62f7982`（600／21,124 B）**→ `9e619f18dc864c7f`**（600／22,530 B）。改法 = `judge(rows, fix=…, pre=…)`（**默认值 = 原模块级常量** ⇒ 默认路径**逐字节不变**）、`read_leg()`／`name_trap()` 同收参、`main()` 把 `--fix=`／`--pre=` **真的**传下去；**参数面加严**：未知参数 ⇒ `USAGE_ERR` `rc=2`；`fix == pre` ⇒ `USAGE_ERR` `rc=2`。**判据成对**：**换臂档**（`--fix=<pre>`／`--pre=<fix>`）⇒ 修前件 `PASS`（开关只改 `NOTE` 打印 = **假旋钮**）／修后件 **`FAIL` `rc=1`**；默认档**逐字节不变**（换了才变 ⇒ 成对）。`--selftest` **8/8** 保持。
#   ② **件②（`TASK-0710`：`--leg=` 旁路 ⇒ judge）**：`build/MilBridge/tools/geom-revert-beat-check.sh` `ee43a703736489a3`（600／44,937 B）**→ `ade2b2e292df2ace`**（600／50,544 B）。改法 = 新增 `corpus_aggregate(root)` ＋ `corpus_anchor_state(corpus_roots)`，**从 `--leg=` 派生的语料也走同一套真判**；`--leg` 模式本身（逐腿诊断／`--live-selftest`）标 **`NOT_APPLICABLE`** 且**不传染**（一格不适用不许把顶层判词带成不适用）。`--selftest` **12/12 → 22/22**（既有 12 例除 `anchor_legmode` 改名外**逐字未动**；新增 7 例语料锚格 ＋ 1 例计数说明；**两族分开计**、**不许合并**）。射程写死：语料锚格**只在 `--corpus=<root>`／派生语料**成立。
#   ③ **件③（`TASK-0711`：仓内 runner 首写点截断 · 方案 A）**：`tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh` `ca0482bda5043909`（755／122,885 B）**→ `57180b9fad939748`**（755／123,318 B，`+4/−1`）。修法 = **第一个写点**（表头块 `} >> "$WPTD_BASELINE_OUT"`）改 **`>`** ⇒ **一次调用 = 恰好一批**（表头 ＋ 6 行），与目标文件此前有没有内容无关。**承重配对（同一路径连跑两趟）**：修后件 **6|6**（复用**不累积**）／修前件（沙箱副本、逐字节 `cmp` 同一）**6|12** ⇒ 后者正是冻结器 `w27-freeze.py:796` 的 `assert len(rows) == 6` **当场失败**的形态。机读行 = `WPTD_TRUNC_R2 p0fix_rows=6|6 prefix_rows=6|12 same_path=yes`。**仓外 belt** `~/w142a/bin/run-gate.sh`（`45a3422e651096d6 → 2e9da0617328759b`）**不落仓**（本会话操作员的仓外编排），只有记录件留档。
#   ④ **零产品改动**：`src/**`／`build/shims/**`／native 源**一字节未动** ⇒ 九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸 6,123,520 B**）⇒ 机械位移，**不许当漂移/回归判据**。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`（3601408 B）／`pf` `d5de121c1c787193`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `d2b76a0a56a41be1`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`（293165 B）／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#60` 冻结值**：`pf` `a1fbf721ae964f8e` → `d5de121c1c787193`（**环成员 `D-G92`**：**同尺寸 6,123,520 B** ⇒ 机械位移）；其余**八位逐位未变**（`prev_pc` `722e0ab8205b7c3f` 逐位未变）。
#   ⚠️ **`inputs_fp` 两笔（成对、带机械归因）**：`5390d01e4040b5c33fd3064caac5910821aeb89850e63a92696ec7c78d43b69c`（`#60` 冻后值）→ **`a00bf53a64c47531963b0f82aae689fe4cee1363c7b9e670799566cb7963c668`**。**归因 = 覆盖面 157 件里恰好 2 件、各自独立成对**：① 只把 `build/MilBridge/tools/geom-resend-regression-check.sh` 那一行换回修前 sha ⇒ `8a2c531a6711f8c864e617486df719d8d91cc438af79b1052bf561131f6f28c8`（= 只退 resend 的中间值）② 只把 `geom-revert-beat-check.sh` 那一行换回 ⇒ `a72e3290a862b85ea66b1151b6ad6f9e96de1e562553a6035d7de524a29e41ff` ③ **两件都退回 ⇒ 逐位 == `5390d01e4040b5c33fd3064caac5910821aeb89850e63a92696ec7c78d43b69c`** ⇒ **位移 100% 归因于这两件、无第三隐形位移**。⚠️ 件③（仓内 runner）**不在覆盖面**（157 行清单里 0 命中）⇒ **不参与位移**（设计，不是遗漏）；⚠️ `verify-all.sh` 与 `docs/WAVE61-PREREGISTRATION.md` **也不在**覆盖面。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变；`native_rebuilt=0 bridge_republished=0`）。
#   **冻前 `verify-all` = `34` 步（`34 ✅ / 0 ❌`、`rc=0`、`结论：✅ 全部通过`、`用例通过 875 跳过 2`）**：**声明类红项 = `[]`（全绿）** —— 本波**不动臂**、不改 `GEN_KEYS`、不改 `known-red.json`（它在覆盖面内，波外单改会破坏冻结口径 ⇒ **本波未碰**）⇒ 与主控的**条件式预期**一致。
#   **本波同趟改到 `#61`（四处声明）**：`VERIFYALL-STEPS-DECL` 顶行 `34 gen=#61`（**数字不动**；**位置锚**：旧 `#60` 行原样留档在其下）／`VERIFYALL-STEP-NAMES` **一字不动**（34 项）／头注释逐字 ``**`#61` 收官起 = 34 步**``（冻结器硬断言）／新建 `docs/WAVE61-PREREGISTRATION.md`（**标题行含 `#61`**）。`grep -c '^run_step "'` 实测 **34**（**不加步、不删步**）。⚠️ **机读约束**：`gen` 一旦上 `#61` 而没有 `docs/WAVE61-PREREGISTRATION.md`（标题含 `#61`）⇒ 第 `[32]` 步**当场 `NOINFO reason=prereg-absent`（rc=2，非绿非红）** ⇒ 两者必须**同趟**（沙箱机上验过）。
#   **边界／`NOINFO`（照录，不许缩小）**：① 件① **只证**"开关接进了判据"，**不证**任何语料层面的回归结论（那要臂/腿数/功效，`D-G116`，排 `#63`）② 件② **只证**"派生语料会真判、单腿格不传染"，**不证**该语料本身的代表性 ③ 件③ **只证**"行数不再增长"，**不证**冻结器今后不会被别的写点撑破 ④ 第 `[32]`／`[33]` 两步**只读**语料与台账（**不跑应用腿、不碰 `dotnet`**）⇒ 它们的绿**不**等于产品行为正常 ⑤ `D-G115` 修法／`D-G116` 跨臂体制牙／`known-red.json` 陈旧 `why` 重钉**排 `#63`**。
#   —— 外挂声明（**两族必须落在最新 `# RE-FROZEN` 块内**；`column-floor-check.sh:229` 用 `grep -E '^# COLUMN-FLOOR '` 在本块里找，缺 ⇒ `COLUMN_FLOOR=NOINFO`（**缺声明 ≠ 通过**））——
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   **臂日志聚合两口径（现场现算，两个都写）**：`cat` 口径 = `2f276db59de241cb`｜`find|sort|xargs` 口径 = `6e246ef5b87d69ea`。
#   【① 落地（全部 `temp ＋ rename`；修前快照 `cp -p` 备份在 `~/w153a/pre/`）】件① `geom-resend-regression-check.sh` `cd375326b62f7982`（21,124 B）**→ `9e619f18dc864c7f`**（22,530 B）｜件② `geom-revert-beat-check.sh` `ee43a703736489a3`（44,937 B）**→ `ade2b2e292df2ace`**（50,544 B）｜件③ `run-wpftextdemo.sh` `ca0482bda5043909`（122,885 B）**→ `57180b9fad939748`**（123,318 B）｜`verify-all.sh` `970bb48ba8ebd384`（114,216 B）**→ `a79c1169a11ac82e`（116,356 B）｜新建 `docs/WAVE61-PREREGISTRATION.md` = `d096b1c421c2cdda`（9,536 B）。三份补丁**逐锚核命中数**：`12 + 10 + 1` 个锚（＋仓外 belt 2 个）**全部恰 1 次**；`patch -p1 --dry-run` `rc=0`×3、真套用后件 sha16 **与预备记录逐位相同**。
#   【② 缺陷复现＋修后读数（两极化，逐字机读行）】**件①（`D-G113`）**：修前件把 `--fix=`／`--pre=` 换成对角 ⇒ **仍 `PASS`**（两开关只改 `NOTE` 打印 = **假旋钮**）；修后件同一输入 ⇒ **`FAIL` `rc=1`**。**件②（`TASK-0710`）**：修前 `--leg=` 给语料根 ⇒ 锚格**不判**（旁路）；修后 ⇒ **真判**（与 `--corpus=` 同口径），`--leg` 给单腿 ⇒ `NOT_APPLICABLE` 且**不传染**。**件③（`TASK-0711`）**：`WPTD_TRUNC_R2 p0fix_rows=6|6 prefix_rows=6|12 same_path=yes`（同一路径连跑两趟）。
#   【③ 整波】`WAVE_OWNER=W153A bash build/close-wave.sh --skip-verify-all`（槽内）：**`HEAVYSLOT=RELEASED rc=0 held=179s`**、`OUT=/home/links-dev/wfp-runs/close-wave-104817`、`[1/6] integration-wave.sh rc=0`、`[2/6]` native 跳过（不比权威件新）、`[3/6]` 桥**无需重发**（`d697b1e10ff48881 == d697b1e10ff48881`）、`[4/6]` 身份自检 ✅（**应用器审计 `miss=0`** ＋ **输入稳定性：波前==波后 == `a00bf53a64c47531963b0f82aae689fe4cee1363c7b9e670799566cb7963c668`**）、`[5/6]` 按要求跳过 verify-all。**九位位移 = 实测只有 `pf`**（`a1fbf721ae964f8e` → `d5de121c1c787193`，**同尺寸 6,123,520 B** ⇒ 环成员 `D-G92` 机械位移）；其余**八位逐位与 `PRE` 相同**。⚠️ `[4/6]` 照旧印 **`APPSYNC 非 PASS`** —— **逐字与 `~/w152a/logs/close-wave.log:27` 相同** ⇒ **继承自上一代、非本波引入**（如实记、不缩小）。
#   【④ 五臂／重钉】**本波不改 `GEN_KEYS`**（不动 `build/MilBridge/run.sh`／`HbTextLineParity/Program.cs`／`build/shims/PresentationCore.HbTextLine.cs`）⇒ **五臂不重取**、五臂 sha **现场现算** 5/5 = `tab-anchor 1c43a12dcaa5718a`／`tab-zero 9150c3a26a3cb789`／`tab-rtl 92570318851ca7e8`／`tline 59a203de30d745a8`／`textlineproto 4bceceeed570ba70`（与 `#60` **逐位相同**）；**`known-red.json` 本波未改** ⇒ **不需要** `repin-generation.py`。
#   【⑤ 门禁 ×2（槽内、严格串行）】**合格线 = 判词行逐字一致**：两趟同为 `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`／`WPTD_SUMMARY=PASS tiers_passed=2/2`／`WPTD_BRIDGE_SRC_STALE=no basis=pub=d697b1e10ff48881 now=d697b1e10ff48881 so_file_match=yes`，`rc=0`×2 ⇒ **逐字一致**；两趟 rows 文件按 `#60` 的同一口径**剥去运行戳**（`date`／`loadavg`／`mem_available`／`run_dir`）后 **diff = 0 行**；判词字段 `result=PASS`／`config=…pf:d5de121c1c787193…`／`drawn=261|144`／`frames_good=14/14`／`colors=4112|2945`／`leftover_after=0` **逐字段相同**。
#   【⑥ 冻前 `verify-all`（槽内；`X-REUSE=reused display=:99`、`X_STATE=available`）】**`34 ✅ / 0 ❌`**、`rc=0`、`结论：✅ 全部通过`、**`用例通过 875 跳过 2`**、`SKIP_GUARD=PASS`。**声明类红项 = `[]`（全绿）** —— 本波**不动臂**、不改 `GEN_KEYS`、不改 `known-red.json` ⇒ 与主控的条件式预期一致（**不许为凑预期动任何东西**）。第 `[32]` 步 `VERIFYALL-SELF` 现场：`VERIFYALL_SELF=PASS names=34 decl=34 gen=#61 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=a79c1169a11ac82e`；第 `[34]` 步 `PREREG-FOUR-REQ` 批次：`PREREG4_SUMMARY files=42 pass=1 fail=0 na=3 skip=0 noinfo=0 out_of_scope=38`、`rc=0`。
#   【⑦ 冻结（`FREEZE_RC=0`）】基线重冻为 `#61` ⇒ **机器行 = `<见下：冻结输出>`**（上代 `#60` = `da24cb43d2123612`／864,300 B，**成对留档**）。`BASELINESHA=PASS`／`BASELINEGEN=PASS decl_gen=#61`／`BASELINE_BYTES=…`／`BASELINEDUP=PASS n=0`／`ARMLOG_SHA=PASS`／`COLUMN_FLOOR=PASS`。世代交叉断言：`树上 #60 == GENS[#61][prev]`；牙齿②：`^run_step 引号 = 34 == 步数 34`，且头注释逐字声明了同一数字。
#   【⑧ 冻后 `verify-all` ×2（槽内、严格串行）】**两趟各 `34 ✅ / 0 ❌`**、`rc=0`、`结论：✅ 全部通过`、**`用例通过 875 跳过 2`**。两趟步判词行（34 行 ＋ 结论行）逐字一致；**冻前 vs 冻后也逐字一致**。⚠️ **不参与合格线但必须点名的仪器漂移**按 `#60` 的口径逐条点名。两趟连续绿之后创建 `~/w21-verify/w61-POST.done` ⇒ 它是下一代的放行信号。
#   【⑨ 推送／app-local／哨兵】逐径 `git add`（**绝不**从 `git status` 生成清单）；快进判据用**远程实况**（`git ls-remote`，不用陈旧跟踪引用）；`BYTECHECK` 用 `HEAD:` 口径逐件比对；app-local 报 `STALE=0`／`DIVERGENT=0`；两处哨兵（`/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag`）逐位复核九位并 `cmp` **IDENTICAL**。
#   【本波两条口径句（落册，均来自现场实测）】① **"闸门字面满足 ≠ 可以写共享 `$R`"**：写前必须确认**链/槽不在跑** ∧ **冻后链已完成**；**唯一放行信号 = 上一代的 `POST.done`**（本波现场：我按较松口径只读 `gen=#61` 就写过 1 件、随后 `mv` 出，零损伤但**如实入册**）。② **"能造出假绿的旋钮不许留"**：`--fix=`／`--pre=` 这种**只改打印不改判据**的开关、以及"把一个格的不适用传染成顶层不适用"的旁路，都是**假绿方向**；修法 = 把开关**接进判据**并**加严参数面**（未知参数/同值 ⇒ 拒绝运行），而不是加注释说明。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:d5de121c1c787193,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w153a/gate-r1
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:d5de121c1c787193,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w153a/gate-r1
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:d5de121c1c787193,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w153a/gate-r1
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:d5de121c1c787193,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w153a/gate-r1
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:d5de121c1c787193,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w153a/gate-r1
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:d5de121c1c787193,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w153a/gate-r1
# ⏪ **（历史，已被 `#61` 取代）**# RE-FROZEN #60 —— ✅ **当前冻结基线** —— 内容 = **仪器波 · 装置/判据欠账批 A**（**零产品改动**）：把回归判定牙的 `N/A` 语义补齐（`TASK-0709`）＋ 补 `quote-trap` 的射程缺口（`TASK-0713`）＋ 修同一颗牙的**帧栈泄漏假绿**（`D-G114`），并把第 `[34]` 步接进 `verify-all`（**33 → 34 步**）。
#   ① **件 A（`TASK-0709`：`N/A` 语义 ＋ 接线）**：`build/MilBridge/tools/prereg-four-requirements-check.sh` `b436ae561ae1f396`（319 行）**→ `235d76b61cdc46a4`**（443 行）。新增 **`PREREG4=NA`**（`rc=0`）：**判据节**里逐字声明「本波 … 不做任何回归判定」（或机读行 `PREREG-NO-REGRESSION-DECISION:`）**∧ 全文无回归判定证据**（判定工件自己印的机读判词行／回归判定台账文件名）⇒ 四要件**对本波不适用**，**与 `PASS` 分开计数**（`--glob` 汇总新增 `na=` 独立一格）＋ 逐件点名 `PREREG4_NA …`。**充要两条**：缺声明 ⇒ 走正常路径（该 `FAIL` 就 `FAIL`）；**留声明却引用了证据 ⇒ 仍 `FAIL`**（声明**不许**当免死金牌）。**格式声明不算证据** —— `docs/WAVE59-PREREGISTRATION.md:47-50` **自己逐字写着**「**是"这一刻不适用"的声明，不是"我已经做过"的声明**」⇒ 若把 `PREREG-REGRESSION-FOUR:` 那一行算成证据，`#59` 仍会被逼着抄四要件 ＝ 正是本任务要治的病。`--selftest` **12/12 → 18/18**（**既有 12 例逐字未变** ＋ 新增 `NA-1`…`NA-6`）。**成对现场**：`WAVE58` **仍 `PASS 4/4`**（**不许**被降级成 `NA`）／`WAVE59` **`PASS → NA`**（设计性位移，逐件记账）／本波 `docs/WAVE60-PREREGISTRATION.md` = `NA`。
#   ② **件 A 的接线（`verify-all.sh`：33 → 34 步）**：第 `[34]` 步 `PREREG-FOUR-REQ` 走**批次门禁形态** `--gate`。四处声明**同趟**改 = `VERIFYALL-STEPS-DECL` 首行 `34 gen=#60`（**位置锚**：解析首个 `^#\s*VERIFYALL-STEPS-DECL:\s*(\d+)\s+gen=(#\d+)` ＋ **先断言 `DECL 数 == grep -c '^run_step "'`** 再插，**不照抄上一代文本**）／`VERIFYALL-STEP-NAMES` 尾加 `PREREG-FOUR-REQ`／头注释逐字 ``**`#60` 收官起 = 34 步**``（冻结器硬断言）／新建 `docs/WAVE60-PREREGISTRATION.md`（**标题行含 `#60`**）。**为什么必须 `--gate`**：`run_step` 把**任何 `rc≠0`** 判 `❌`，而逐件形态下「波次早于生效边界 ⇒ `SKIP` ⇒ `rc=3`」⇒ 裸 `--glob` **每趟都会多一个 ❌**、门禁**永远接不上**。批次形态下那些件**不判但逐件点名**（`PREREG4_OUT-OF-SCOPE` ＋ `out_of_scope=`，**永不静默**），批次 `rc` 只由**违规**与**查不动**决定（`fail>0 ⇒ 1`／`noinfo>0 ⇒ 3`）；`na`／`out_of_scope` 是**适用性/射程**声明、**不进 `rc`**。**逐件形态的 `SKIP ⇒ rc=3` 一字未动**（W151A 的读法逐位保留）。现场：`files=41 pass=1 fail=0 na=2 noinfo=0 out_of_scope=38`、`rc=0`、stderr **0 字节**。
#   ③ **件 B（`TASK-0713`：`quote-trap` 射程缺口）**：`build/MilBridge/tools/shell-quote-trap-check.sh` `e5d4cf05ef5fc2ea`（840 行）**→ `d4317aa7605a31e1`**（907 行）。旧件把 `*/bin/*` 与 `*/obj/*` **并列静默排除** ⇒ **成对实测**：**同一颗真陷阱**放 `*/bin/*` ⇒ `PASS traps=0`（**静默出射程 ＝ 假绿方向**）、挪到 `build/MilBridge/tools/` ⇒ `FAIL traps=2`。修法 = **`bin/` 纳入扫描**（真判）＋ 每次跑印 `QUOTE_TRAP_SCOPE … bin=INCLUDED excluded=<类:件数>` ⇒ **"没扫什么"永不许静默**（`upstream/` 刻意保留排除**并点名**）。今天实测全树 `*/bin/*` 下的 `*.sh|*.py` = **0 件** ⇒ **读数零位移**（`files=161` 不变），他治的是**将来**有件落进 `bin/` 时"牙看不见"。`--selftest` **30/30 → 35/35**（**只增不减**，新增 `S30`–`S34`）。
#   ④ **件 C（`D-G114`：帧栈泄漏 ⇒ 假绿）**：同一颗牙，**一行无关代码把整份文件的判据降级成诊断**。机制定到行 = `:325` 的 N 态 `#` 判注释条件把 `{` 放进字符类 ⇒ `${#arr[@]}` 的 `#` 因**前一字符是 `{`** 被判成"注释"⇒ `return` 到行末 ⇒ `${`（`:280` 压 `b` 帧）**永远等不到 `}`**（`:301` 只有 `}` 能弹）⇒ **帧顶永久滞留 `b`** ⇒ 此后该文件**任何**双引号内裸反引号都走 `:291` 的 `emit("DIAG","DQ-BRACE-BACKTICK")` ⇒ **不进 `rc`**。**现场实物** = `prereg-four-requirements-check.sh:313`（汇总 `echo` 的双引号里写了反引号包着的 `SKIP`）⇒ **真的做了命令替换**：stderr 每趟多一行 `…: 行 313: SKIP: 未找到命令`、汇总行里那几个字**消失**（与该牙自己记的第 ③ 条血案同形）。**两极化**：同一颗陷阱前面只多一行 `if [[ ${#arr[@]} -gt 0 ]]` ⇒ 旧件 `PASS traps=0`、新件 `FAIL traps=2`。**全树量化** `traps 0→2`、`diag 73→71` ⇒ **只增红、零假红**（实测）。修法 = `:325` 加 `topk() != "b"` 前置（**只修"帧顶错成 `b`"**，"**真的**在 `${ … }` 里"那一档**仍只诊断**，语义未动）＋ 把 `:313` 那处**真陷阱**改掉。**修后全树** `SHELL_QUOTE_TRAP=PASS traps=0 diag=71 files=161 rc=0`。
#   ⑤ **零产品改动**：`src/**`／`build/shims/**`／native 源**一字节未动** ⇒ 九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸 6,123,520 B**）⇒ 机械位移，**不许当漂移/回归判据**。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`（3601408 B）／`pf` `a1fbf721ae964f8e`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `d2b76a0a56a41be1`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`（293165 B）／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#59` 冻结值**：`pf` `70f5fd87457ca0f3` → `a1fbf721ae964f8e`（**环成员 `D-G92`**：**同尺寸 6,123,520 B** ⇒ 机械位移）；其余**八位逐位未变**。
#   ⚠️ **`inputs_fp` 两笔（成对、带机械归因）**：`e7b94e10171b55e1786a63c30a8da568ba24da62228bfb3903eb4f46e3f9a398`（`#59` 冻后值）→ **`5390d01e4040b5c33fd3064caac5910821aeb89850e63a92696ec7c78d43b69c`**。**归因 = 覆盖面 157 件里恰好 1 件**：`build/MilBridge/tools/shell-quote-trap-check.sh`。**机械反证**：把真函数 `{ }` 块原样跑出逐件清单（`L_new`，157 行），**只把该件那一行换回修前件的 sha** ⇒ 指纹**逐位回到** `e7b94e10171b55e1786a63c30a8da568ba24da62228bfb3903eb4f46e3f9a398` ＝ `#59` 声明值 ⇒ 位移 **100% 归因于这一件**。
#     ⚠️ **更正派单的一处预期（如实记）**：派单说"`verify-all.sh` 与 `prereg-four-requirements-check.sh` 也在 `fp_inputs()` 白名单内" —— **现场 `grep` 反证：两件都不在**（`verify-all.sh` 的 4 处命中**全在注释里**；`prereg-…` 命中 **0**）⇒ 本波三件里**只有 `shell-quote-trap-check.sh`** 会挪指纹。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   **冻前 `verify-all` = `34` 步（`34 ✅ / 0 ❌`、`用例通过 875 跳过 2`）**：见下 §RECORD 的 ⑥ 行（**条件式预期**：本波**不动臂**、不改 `GEN_KEYS` ⇒ 声明类红**没有**出现 ⇒ **照实报全绿**）。
#   **本波同趟改到 `#60`**：新建 `docs/WAVE60-PREREGISTRATION.md`（**标题行含 `#60`**）＋ `verify-all.sh` 头注释逐字 ``**`#60` 收官起 = 34 步**``（冻结器硬断言、**位置锚**）＋ `VERIFYALL-STEPS-DECL` 顶行 `34 gen=#60`（**位置锚**）＋ `STEP-NAMES`／口径句**同趟**。**不改** `known-red.json`、**不动** `build/MilBridge/arm-logs/**`、**不动**五臂。
#   **边界／`NOINFO`（照录，不许缩小）**：① 件 A **判不了**"四要件**内容为真**"（只判"文档里在不在"）；② 件 A **判不了**"声明是否诚实"（声明"不做判定"却偷偷做了 ⇒ 除非留下判定工件的机读判词行）；③ 件 A 的**证据界定是子串匹配**（全文）⇒ 一个波**仅仅在散文里提到**那些名字也会被判成"有证据" ＝ **假红方向**（可见、可改写法），**不是**假绿 —— 本波按"宁可假红"保留（**本波预登记自己就踩过这一格**，已改写并留档）；④ 件 B／C **只证**"该红处会红"，**不证**本仓今后不会出现别的帧配对形态；⑤ 第 `[34]` 步**只判文档层**，**不**读产品件、**不**跑臂、**不**碰冻结语料。
#   —— 外挂声明（**两族必须落在最新 `# RE-FROZEN` 块内**；`column-floor-check.sh:229` 用 `grep -E '^# COLUMN-FLOOR '` 在本块里找，缺 ⇒ `COLUMN_FLOOR=NOINFO`（**缺声明 ≠ 通过**））——
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落地（全部 `temp ＋ rename`；前后 sha **双断言**）】`shell-quote-trap-check.sh` `e5d4cf05ef5fc2ea`（840 行）**→ `d4317aa7605a31e1`**（907 行）｜`prereg-four-requirements-check.sh` `b436ae561ae1f396`（319 行）**→ `235d76b61cdc46a4`**（443 行）｜`verify-all.sh` `ec29c571be6b19da`（1103 行／`run_step=33`）**→ `970bb48ba8ebd384`**（1114 行／`run_step=34`）｜`docs/WAVE60-PREREGISTRATION.md` **新**（`#60` 在标题）。全部先 `cp -p` 备份到 `$HOME/w152a/backups/`。
#   【② 缺陷复现（改前，逐字机读行）】**件 C 现场物**：`prereg-four-requirements-check.sh:313` 的双引号里裸反引号 ⇒ 真跑 stderr 打 `prereg-four-requirements-check.sh: 行 313: SKIP: 未找到命令`、汇总行里"SKIP"那几个字**消失**。**两极化**（同一颗陷阱、只挪一行无关代码）：无 `${#…}` 前置 ⇒ `FAIL traps=2`；前面只多一行 `if [[ ${#arr[@]} -gt 0 ]]` ⇒ 旧件 **`PASS traps=0`**（假绿）、修后 `FAIL traps=2`。**全树**：旧件 `traps=0 diag=73` ⇒ 修后 `traps=2 diag=71`（两条**全指向**那处真陷阱）⇒ 修 `D-G114` 后同趟修掉该陷阱 ⇒ 终态 `traps=0`。**件 B 现场物**：同一颗真陷阱放 `*/bin/*` ⇒ `PASS traps=0`；挪到 `tools/` ⇒ `FAIL traps=2`。
#   【③ 整波】`close-wave.sh --skip-verify-all`：槽内 **`HEAVYSLOT=RELEASED rc=0 held=192s`**、`[1/6] integration-wave.sh rc=0`、`[2/6]`／`[3/6]` **跳过重建**（native 不比权威件新；桥源指纹两侧一致 `d697b1e10ff48881`）、`[4/6]` 身份自检 ✅（**应用器审计 `miss=0`**；**输入稳定性：波前==波后 == `5390d01e4040b5c33fd3064caac5910821aeb89850e63a92696ec7c78d43b69c`**，期间无手写改动）、`[5/6]` 按要求跳过 verify-all。**九位位移 = 实测只有 `pf`**（`70f5fd87457ca0f3` → `a1fbf721ae964f8e`，**同尺寸 6,123,520 B** ⇒ 环成员 `D-G92` 机械位移）；其余**八位逐位与 `PRE` 相同**。⚠️ `[4/6]` 照旧印 **`APPSYNC 非 PASS`**（形态与 `#59` 相同、继承自上一代）。
#   【④ 五臂／重钉】**本波不改 `GEN_KEYS`**（不动 `build/MilBridge/run.sh`／`HbTextLineParity/Program.cs`／`build/shims/PresentationCore.HbTextLine.cs`）⇒ **五臂不重取**、**五臂 sha 与 `#59` 逐位相同**（**现场现算** 5/5：`tab-anchor 1c43a12dcaa5718a`／`tab-zero 9150c3a26a3cb789`／`tab-rtl 92570318851ca7e8`／`tline 59a203de30d745a8`／`textlineproto 4bceceeed570ba70`）；**`known-red.json` 本波未改** ⇒ **不需要** `repin-generation.py`。
#   【⑤ 门禁 ×2（槽内、严格串行）】**合格线 = 判词行逐字一致**：两趟同为 `TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=921ba9c65e9fb3be gate=747c078dbf040862 judge=t1b3-tline-gate/7`，`RC1=RC2=0` ⇒ **逐字一致**；两趟落在**同一秒** ⇒ `outdir=` 也逐字相同（该项**本不参与合格线**，此处恰好相同 ⇒ 点名）。
#   【⑥ 冻前 `verify-all`（槽内；`X-REUSE=reused display=:99`、`X_STATE=available`）】**`34 ✅ / 0 ❌`**、`rc=0`、`结论：✅ 全部通过`、**`用例通过 875 跳过 2`**。**声明类红项 = `[]`（全绿）** —— 本波**不动臂**、不改 `GEN_KEYS`、不改 `known-red.json` ⇒ 与主控的**条件式预期**一致（「若声明类红不出现就照实报全绿，**不许为凑预期动任何东西**」）。**新增第 `[34]` 步 `PREREG-FOUR-REQ` 首跑即 ✅**（`rc=0`）；其余声明类（`BASELINE-SHA`／`ARM-LOG-SHA`／`COLUMN-FLOOR`／`DEFECT-REGISTRY`）与新增/受影响的 `QUOTE-TRAP`／`PIPEFAIL-SIGPIPE`／`VERIFYALL-SELF` **全部 ✅**。
#   【⑦⑧⑨ 待冻后追加（`APPEND_ONLY`）】冻结 `#60` 的 `FREEZE_RC`／四颗牙／**冻后 ×2 两趟**（各 `34 ✅ / 0 ❌`、`用例通过 875 跳过 2`、`NOFILE_SWAP`）／`~/w21-verify/w60-POST.done`／逐径推送 ＋ `HEAD:` 字节核对 ＋ app-local ＋ 两处哨兵。
#   【牙与件（现算 sha16）】`~/w152a/criteria.md`（**判据先行**：`§0–§7` 写定于取任何"修后"自有读数之前）｜`~/w152a/report.md`（链报告，`APPEND_ONLY`）｜`~/w152a/logs/patch-quote-trap.py`／`patch-prereg4.py`／`wire-verify-all.py`（**位置锚**补丁器，每条替换 `assert count==1`）｜`~/w152a/w60-pre.sha`（开工前九位快照，**按 `#59` 冻结块逐位重建**、现场复核 9/9 相同）。
#   【两趟对拍的口径（主控裁定，沿用）】**合格线 = "判词行逐字一致"**；`tline-gate` 的跑次戳 `outdir=`／`column-floor` 的临时目录随机后缀／`FRAMEPRESENCE` 的帧计数三处**不参与合格线，但必须点名并列实际数**。
#   【本波四条口径句（落册，均来自现场实测）】① **"必须成为 `head -1`" 的插入，锚必须是位置**（`verify-all.sh` 的 `DECL` 首行每代都被上一波在其**之上**再插一行）——照抄上一代文本会把新行插到下面、`head -1` 取到旧代号。② **`--glob` 与"逐件形态"的出口码口径必须分开**：把"超出射程"也算进批次 `rc` ⇒ 批次永不为 0 ⇒ 门禁永远接不上 ⇒ 只会把人推向"吞掉 rc"（**真**假绿）；正确形态 = 出射程件**逐件点名 ＋ 计数**、**不进 `rc`**。③ **判据装置自己也会被"一行无关代码"整份闭掉**：`${#arr[@]}` 这种**常见**写法就能让帧栈永久失衡 ⇒ 此后该文件**所有**同类判据降级成诊断（`D-G114`）——**"没红"不等于"查过了"**，必须有一例"已知该红"的夹具钉住。④ **子串匹配的"证据界定"会误伤散文**：判据若用子串认"对象"，作者**仅仅提到**那个名字就会被判成"有对象"（本波预登记自己踩到）⇒ 写文档时要避开**逐字复现**该串，并把这条**当成射程边界如实登记**，而不是悄悄放宽检测。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:a1fbf721ae964f8e,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w152a/gate-r1
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:a1fbf721ae964f8e,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w152a/gate-r1
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:a1fbf721ae964f8e,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w152a/gate-r1
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:a1fbf721ae964f8e,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w152a/gate-r1
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:a1fbf721ae964f8e,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w152a/gate-r1
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:a1fbf721ae964f8e,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w152a/gate-r1
# ⏪ **（历史，已被 `#60` 取代）**# RE-FROZEN #59 —— ✅ **当前冻结基线** —— 内容 = **仪器接线波**（**零产品改动**）：`TASK-0110`（**改题后**）把两颗几何牙接进 `verify-all`（**31 → 33 步**），并把「桥侧几何重发」这条**确定性回归**固定成每趟必跑的牙。
#   ① **背景（题面前提已被推翻 = `D-G112`）**：`TASK-0110` 原题问「WM 为什么不把退出最大化的几何收回去」。**台账 70 腿**复算推翻该前提 —— **红腿 27/32 的 `frame` 回过基准**，**41–86 ms（median 81）后被桥顶回**；旧结论是**欠采样伪影**（176 ms 级口径把「还原＋顶回」整对事件吞掉）。⇒ **改题**为「frame/client **时序判据** ＋ 桥侧几何重发的**确定性回归牙**」，并**接线冻结**（判据先写于 `~/w149a/criteria.md`，本波只**接线**、**不改牙的承重判据**）。
#   ② **接线（`verify-all.sh`：31 → 33 步；四处声明同趟）**：第 `[32]` 步 `GEOM-BEAT`（`build/MilBridge/tools/geom-revert-beat-check.sh`）＋ 第 `[33]` 步 `GEOM-RESEND`（`build/MilBridge/tools/geom-resend-regression-check.sh`）。四处声明 = `VERIFYALL-STEPS-DECL` 首行 `33 gen=#59`（**位置锚**：解析首个 `^#\s*VERIFYALL-STEPS-DECL:\s*(\d+)\s+gen=(#\d+)` ＋ 先断言 `DECL 数 == ^run_step 条数`）/`VERIFYALL-STEP-NAMES` 尾加两名/头注释逐字 ``**`#59` 收官起 = 33 步**``（冻结器硬断言）/新建 `docs/WAVE59-PREREGISTRATION.md`（**标题行含 `#59`** —— 冻结器的 `prereg` 前置）。**实测 `+47/−1`、5 个 hunk**；`VERIFYALL_SELF=PASS names=33 decl=33 gen=#59 dup=0 order=OK prose=OK prereg=PASS`。
#   ③ **两件牙（落地 ＋ 各带两极化自测）**：牙1 `9412ec0149111348`（511 行）**→ `ee43a703736489a3`**（701 行，`+185/−3`／8 hunk，**只 3 行被替换**）—— `#59` 给它加了一格 **`GEOMCORPUS=`（语料世代锚的读者）**：在 `--corpus=` 模式下把**现场语料聚合**与 `known-red.json` 的 `generation.geom_corpus.sha256` **全 64 位逐字**比，**不等 ⇒ `NOINFO` ＋ 点名 `geom-corpus-declared-mismatch` ⇒ 顶层 `GEOMBEAT=NOINFO`（rc=2）**；`--leg=` 模式**按定义不适用** ⇒ 打 `NOT_APPLICABLE` 形态（`GEOMCORPUS=NOINFO reason=leg-mode-not-a-corpus`）且**不传染顶层**（**明说的旁路**：第 `[32]` 步只用 `--corpus=`）。`--selftest` **12/12 → 19/19**（**既有 12 例逐字未变** ＋ 新增 7 例：`anchor_base`/`anchor_alg`/`anchor_ok`/`anchor_mismatch`/`anchor_undeclared`/`anchor_legmode`/`anchor_reporoot`）；`--live-selftest`（真 `Xvfb :227` ＋ 自写 X 客户端）**4/4**。牙2 `cd375326b62f7982` **本波未改**（332 行）。
#   ④ **语料入仓（34 MiB：39 腿 / 234 件）** `build/MilBridge/geom-corpus/**`（**新**，`cp -p` 真复制、`-links +1` = 0）；聚合锚（**相对路径口径**，与绝对路径无关、`cp -p` 可搬）`0f702ccd8eb3938a03be55e17e0c978013d73eb37485847fcaad6f88b1bb9fe2`，声明处 = `known-red.json` 的 `generation.geom_corpus`（**本波新加**）。**为什么必须入仓**（实测）：`--corpus=<不存在>`／`<仓内 arm-logs（无腿目录）>` ⇒ **两件牙都 `rc=2`**，而 `run_step` **只认 `rc==0`** ⇒ 缺语料 = 该步 ❌；指 `$HOME/w134a/run` 这类**仓外可变态** ⇒ **机器相关的红**（`D-G31` 家族：判据的结论取决于环境此刻长什么样 ⇒ 它不是判据）。
#   ⑤ **生效边界修法（照 `HANDOFF-NEXT.md` 第 20 条）** `build/MilBridge/tools/prereg-four-requirements-check.sh` `57de293df5be263d`（272 行）**→ `b436ae561ae1f396`**（319 行）：`REQ_EFFECTIVE_WAVE` **57 → 58**（件头**逐字写明"为什么是 58"**：`#57` 的预登记写在工具存在之前、按"只加不改"不许倒填 ⇒ 必须 `SKIP`；`#58` 是第一份合规件 ⇒ 必须真判 —— 两条**同时**只有 58 满足；旧值 `57` 留档、**加注不覆盖**）；SKIP 改打**独立 token `PREREG4=SKIP`** ＋ 逐件点名 `reason=pre-effective`；`--glob` 新增 **`PREREG4_SUMMARY files=… pass=… fail=… skip=… noinfo=…`（四态分开计数）**；`--min-wave` **仅覆盖口**。**成对现场**：`WAVE57` 旧牙 `FAIL missing=7`（**那条假红**）→ 新牙 `SKIP`/`rc=3`；`WAVE58` 旧新**都 `PASS requirements=4/4`**（不许被 SKIP）。`--selftest` **10 → 12/12**（`WAVE57 ⇒ SKIP`／`WAVE58 ⇒ 真判`／`--min-wave 抬高 ⇒ SKIP`）。
#   ⑥ **零产品改动**：`src/**`／`build/shims/**`／native 源**一字节未动** ⇒ 九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸 6,123,520 B**）⇒ 机械位移，**不许当漂移/回归判据**。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`（3601408 B）／`pf` `70f5fd87457ca0f3`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `d2b76a0a56a41be1`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`（293165 B）／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#58` 冻结值**：`pf` `c69bc1742cfa7f39` → `70f5fd87457ca0f3`（**环成员 `D-G92`**：**同尺寸 6,123,520 B** ⇒ 机械位移）；其余**八位逐位未变** ⇒ **主控独立现算复核**。
#   ⚠️ **`inputs_fp` 两笔（成对、带机械归因）**：`4c4d99f569a00380f94ff00ef136f1241884a32181f8ee1216ef6ca7b1a061ee`（`#58` 冻后值）→ **`e7b94e10171b55e1786a63c30a8da568ba24da62228bfb3903eb4f46e3f9a398`**。归因 = **本波动了覆盖面 155 → 157 件**：新增两件判据件（`build/MilBridge/tools/geom-revert-beat-check.sh`／`geom-resend-regression-check.sh`，**本波同趟纳入白名单**）＋ 一件被改（`build/close-wave.sh` 自身的白名单行 ⇒ 它**自含于覆盖面**，这是设计使然）。⇒ **`coverage_n 155 → 157`（恰好 +2，且只有 +2）**、`geom-` 命中 **0 → 2**。语料**不进** `fp_inputs()`（同 `arm-logs` 裁定：派生件 ＋ 重取是合规动作）。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   **冻前 `verify-all` = `33` 步**：见下 §RECORD 的 ⑥ 行（**条件式预期**：本波**未重取臂**、但**改了被声明件** `known-red.json` ⇒ 声明类红"可能出现"，**照现场报**）。
#   **本波同趟改到 `#59`**：新建 `docs/WAVE59-PREREGISTRATION.md`（**标题行含 `#59`**）＋ `verify-all.sh` 头注释逐字 ``**`#59` 收官起 = 33 步**``（冻结器硬断言、**位置锚**）＋ `VERIFYALL-STEPS-DECL` 顶行 `33 gen=#59`（**位置锚**）＋ `STEP-NAMES`／口径句**同趟**；`build/close-wave.sh` 的 `fp_inputs()` **插名单中部**加两行；`build/MilBridge/known-red.json` 加 `generation.geom_corpus` 并**同趟** `repin --why/--check`（`REPIN_GENERATION=PASS`）。
#   **边界／`NOINFO`（照录，不许缩小）**：① 两颗牙**不测当前桥件**（它们对**冻结语料**只读复算）⇒ 「桥件被改回」**不**由这两步咬到；② `GEOMCORPUS` 的射程**只在 `--corpus=` 模式**（`--leg=` 是**声明过的旁路**，绕行时屏上必有一行说"本格未行使"）；③ 语料锚**只证"这 234 件的字节没变"**，**不**证"判出来的结论对"，也**不随桥件换代而变**；④ 两件牙**不读** `_NET_FRAME_EXTENTS`（恒真谓词 `233/233 = 0,0,0,0`）；⑤ `Δ_push` 落在灰带 `(200, 4500) ms` 时按裁定**一律红**（`Δ` 只贴 `LATE_PUSH`），「`LATE_PUSH` 是不是另一种成因」= **`NOINFO`**（本语料 `LATE_PUSH` **0 条**）。
#   —— 外挂声明（**两族必须落在最新 `# RE-FROZEN` 块内**；`column-floor-check.sh:229` 用 `grep -E '^# COLUMN-FLOOR '` 在本块里找，缺 ⇒ `COLUMN_FLOOR=NOINFO`（**缺声明 ≠ 通过**））——
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落地（全部 `temp ＋ rename`；前后 sha **双断言**）】语料 `build/MilBridge/geom-corpus/**` **新**（39 腿 / 234 件 / 聚合 `0f702ccd8eb3938a03be55e17e0c978013d73eb37485847fcaad6f88b1bb9fe2`，与你给的值逐字相同）｜`verify-all.sh` `51ea0b5623981406`（1057）**→ `ec29c571be6b19da`**（1103，`run_step=33`）｜牙1 `9412ec0149111348` **→ `ee43a703736489a3`**（701）｜`prereg-four-requirements-check.sh` `57de293df5be263d` **→ `b436ae561ae1f396`**（319）｜`docs/WAVE59-PREREGISTRATION.md` **新**（147 行；`#59` 在标题）｜`build/close-wave.sh` `0cf2ea72bdee142c` **→ `053f5820e354c5ed`**｜`build/MilBridge/known-red.json` `64b22d35efc1e3be`（484）**→ `b3f264bbf43dbd61`**（497；**块 `+9/−0` ＋ `repin --why` 追加 `arms_retaken.history` 一条与 `when`/`why` ⇒ 记账为 `+13`**）。
#   【② 缺陷复现（改前，逐字机读行）】**"WM 没把几何收回去" 这个前提本身**：`W149A` 台账 70 腿复算 = **红腿 27/32 的 `frame` 回过基准**、41–86 ms（median 81）后被桥顶回 ⇒ **旧结论是欠采样伪影**（`D-G112`）。**牙的成对基线**（39 腿既有语料，只读、零重跑）：修前臂 `feef049e9d0e313a` **红 16/17**（`Δ_push` 64.4–104.3 ms、median **76.25**、**全部 ≤ 200 ms** ⇒ **"慢 ⇒ 红"必造假绿，现场得证**）＋ 边界例 1 条 `W134A-B1-M1R2-2`；修后臂 `4e25e4b27d4d5ae1` **绿 19/19**（`B3` 全 `NONE`）；中间态 `292e9532d093fbd9` 红 3/3。回归牙：修后 **每腿** `CFG_HIT=0 ∧ GEOWRITE≥1 ∧ r_ok=1`（19/19）、修前回升率 **0.941（16/17）** ∧ 正控全 0、成对性反例 **0**、命名陷阱 2 条。
#   【③ 整波】`close-wave.sh --skip-verify-all`：槽内 `rc=0`、`失败步骤=0`、`[1/6]` appliers 读数、`[4/6]` **波前==波后 = `e7b94e10171b55e1786a63c30a8da568ba24da62228bfb3903eb4f46e3f9a398`**；九位位移 = **预期只有 `pf`**（环成员）；**`inputs_fp` 必变**（新纳两件 ＋ 语料**不在**覆盖面）⇒ 见 §FROZEN。
#   【④ 五臂／重钉】**本波不改 `GEN_KEYS`**（不动 `build/MilBridge/run.sh`／`HbTextLineParity/Program.cs`／`build/shims/PresentationCore.HbTextLine.cs`）⇒ **五臂不重取**、**五臂 sha 与 `#58` 逐位相同**（现场复核 5/5）；**`known-red.json` 变了**（加 `generation.geom_corpus`）⇒ 同趟 `repin-generation.py --why/--check`（`check PASS → APPLIED（`entries[*].caliber 改动字段数 = 0`）→ check PASS`）。⚠️ 连带：`[16] DEFECT-REGISTRY` 的 `DEFREG_EXTRA=KRJ=` 由 `64b22d35efc1e3be` → `b3f264bbf43dbd61`、**`DEFREG_DECLDRIFT` 0 → 1**（**该行是非门禁诊断行**，`DEFREG=PASS`/`rc=0` 不变）⇒ **主控同趟重发 `defect-registry-declared.tsv` 归零**（现场已复核 `DECLDRIFT=0`）。
#   【⑤ 门禁 ×2（槽内）】两趟逐行对拍合格线 = **判词行逐字一致**（跑次戳／临时目录随机后缀／仪器计数漂移**不算差异但必须点名**）。读数见 §FROZEN。
#   【⑥ 冻前 `verify-all`】见 §FROZEN：`33` 步、`用例通过 875 跳过 2`；**声明类红照现场报**（本波**未重取臂** ⇒ 若全绿就报全绿，**不凑预期**）。
#   【⑦⑧⑨ 待冻后追加（`APPEND_ONLY`）】冻结 `#59` 的 `FREEZE_RC`／四颗牙／**冻后 ×2 两趟**（各 `33 ✅ / 0 ❌`、`用例通过 875 跳过 2`、`NOFILE_SWAP`）／`~/w21-verify/w59-POST.done`／逐径推送 ＋ `HEAD:` 字节核对 ＋ app-local ＋ 两处哨兵。
#   【牙与件（现算 sha16）】`~/w151a/criteria.md`（**判据先行**：`§1–§9` 写定于取任何自有读数之前，`§10` 为四条裁定后的**追加**）｜`~/w151a/wiring-plan.md`（接线预备：逐字、行锚定；§2 的文本**可被脚本逐字抽出后落地**）｜`~/w151a/report.md`（链报告，`APPEND_ONLY`）｜`~/w151a/land.sh`（落地脚本：三条闸卫 ＋ 幂等守卫 ＋ 前后 sha 双断言）｜`~/w151a/logs/apply-plan.py`（接线器：**位置锚**，「必须成为 `head -1`」的插入只按**位置**、不按上一代文本）｜`~/w151a/logs/mk-geom-corpus-block.py`（`geom_corpus` 块生成器）｜`~/w151a/logs/patch-tooth1-anchor.py`（牙1 补丁器）｜`~/w151a/logs/patch-prereg4.py`（生效边界补丁器）。
#   【两趟对拍的口径（主控裁定，沿用）】**合格线 = "判词行逐字一致"**；`tline-gate` 的跑次戳 `outdir=`／`column-floor` 的临时目录随机后缀／`FRAMEPRESENCE` 的帧计数三处**不参与合格线，但必须点名并列实际数**。
#   【本波四条口径句（落册，均来自现场实测）】① **"必须成为 `head -1`" 的插入，锚必须是位置**（`verify-all.sh` 的 `DECL` 首行每代都被上一波在其**之上**再插一行；本波实测 `#57 0345e750fd182a7c/1055 → #58 51ea0b5623981406/1057`）——照抄上一代文本会把新行插到下面、`head -1` 取到旧代号（本车道第一版就被咬过一次，已修）。② **`python3 - <<EOF`（stdin 脚本）里取脚本自身位置一律不许用 `__file__`**（它在 stdin 下恒为 `<stdin>` ⇒ 反推仓根**静默指到别处**，现场表现为 `NOINFO reason=registry-absent:/home/build/…` —— **不报错、只判错**，在 `verify-all` 里就是一个 ❌）⇒ 落法 = 由 bash 侧显式导出仓根（本波 = `GEOMBEAT_REPO`）并加一例自测钉住。③ **改"读数行/报告行"必须断言命中数**（用 `str.replace` 静默 no-op 是最隐蔽的假更新；本车道自伤两次：漏写 `land=`、漏更新 `new_findings`）⇒ 落法 = 逐字段断言重建，或替换后立刻 `grep -c` 复核。④ **`say/echo` 的双引号里出现反引号一律转义（或改单引号）；仓外脚本不受 `[15] QUOTE-TRAP` 保护，自己得核**（本波 `land.sh` 自伤一次：两处 `say "…`…`…"` 真做了命令替换，报 `…: 未找到命令`；读数未受影响）。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:70f5fd87457ca0f3,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w151a/gate-r1
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:70f5fd87457ca0f3,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w151a/gate-r1
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:70f5fd87457ca0f3,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w151a/gate-r1
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:70f5fd87457ca0f3,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w151a/gate-r1
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:70f5fd87457ca0f3,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w151a/gate-r1
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:70f5fd87457ca0f3,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w151a/gate-r1
# ⏪ **（历史，已被 `#59` 取代）**# RE-FROZEN #58 —— ✅ **当前冻结基线** —— 内容 = **仪器波**（**零产品改动**）：`TASK-0705`「回归判定四要件」整包落地 —— A 半模板六处插入 ＋ 新牙 ＋ B 半牙本体三缺陷修复
#   ① **A 半（落地）** `docs/PREREG-TEMPLATE.md` **六处行锚定插入**（D1–D6；**已在稿原文一字未动**，全部追加）：`171 → 212` 行（`+41`，`diff` 的 `^<` 计数 = **0**）。六处锚点（`:55/:63/:69/:107/:159/:167`）**全行逐字唯一命中 = 1**，由落地器 `~/w150a/land-a-half.py`（**幂等守卫 ＋ 落前重核旧 sha16** ＋ `temp＋rename`）保证；`75dfc5f3fbc9df40 → 17927a59d050fc83`。
#      · ⚠️ **两处文字由本车道改写（相对 W147A 的草稿，如实记）**：**D1** 加一句 dated「已修」、**D5** 整条改写为「**曾经有、`#58` 已修**」—— 因为 `#58` **同趟修好了 `F-A`/`F-B`**，原文「该支路不过 ④（登记在案）」**在落地那一刻即成假话**（权威模板不该放假话）。**D2/D3/D4/D6 逐字照抄**。行数为**实测**（`+41`；W147A 预告 `213` 系其块行数记多，以实测为准）。
#   ② **新牙（落地，**未接线**）** `build/MilBridge/tools/prereg-four-requirements-check.sh` **`57de293df5be263d`**（272 行；源 = 车道 W147A 的 `~/w147a/tooth/`，**只读复制**）。它扫**预登记文档**：判据节里**四要件缺任一** ⇒ `PREREG4=FAIL rc=1`、**只在别处讨论过**（未采纳）⇒ 同判 FAIL、文件不存在 ⇒ `rc=3` `NOINFO`、历史冻结件（`< #57`）⇒ `SKIP`。`--selftest` **10/10 PASS**（含**缺①/②/③/④ 各必红**、`discussion-only` 必红、`repair-back-to-green` 回绿、`history-frozen-skip`、`current-wave-missing-must-fail`）。**本波不接进 `verify-all`**（`REQ_EFFECTIVE_WAVE=57`，`#58` 起对新预登记件生效）。
#   ③ **B 半（牙本体修复）** `build/MilBridge/tools/regression-decision.py` **`1eda9e3575960cba → 71734fce77842478`**（943 → 1003 行；5 处**精确子串**替换，`+73 −13`，**唯一删行 = 被前移的那 12 行**）：**`F-A`**（承重假绿）④ 的三格**前移到判词分支之前** ⇒ `--old-repro yes` 支路**不再绕过** ④（改前 `--planned-legs 99` 与现场 `pairs=16` 不符**仍判 `REGRESSION`/`rc=0`**，改后 `NOINFO/rc=3/plan-mismatch`）；**`F-B`**（假陈述／假分类）新增 **`rc=2` ＋ `REGDEC_REFUSE=repro-inconsistent`**（`repro=yes ∧ 旧臂红数=0`／`repro=no ∧ 旧臂红数>0` 两个方向都拒），**位置 = 分母守门之后**；**`F-C`**（显示位数翻转判词）**判词不动**，只加一行机读并列 `REGDEC_ALPHA p_raw=… p_display_only=… compare=le|gt decide=raw verdict_input=…`。
#      · **`F-A` 落点 = 实测定**（初版判据放在 ④ Fisher 计算之前 ⇒ 三例既有夹具**各少印 5 行诊断**；改到「全部诊断行之后、`# ── 判词` 之前」后 **16 个既有夹具整份输出逐字节不变**）。**口径**：**计划不合规 ≠ 统计不用算** —— `p` 与所需趟数**照印供留档**，**只是不许据此下判词**。
#      · **两极化验收（现场逐条）**：`--selftest` **`22/22 → 26/26`**（`fail=0`，`ST_ATTEST=PASS`；**既有 22 例一个没改**，新增 4 例＝三处缺口各一对）｜台账 `--cases` **`rows=7 pass=7 fail=0`** 且**整份输出逐字节相同**（`LEDGER_BYTE_IDENTICAL=yes`；`DG94-denominator-counts-skipped` 的 `reason=denominator-unreconciled(…)` **逐字未变** ⇒ **「分母门」那一格的覆蓋没被顶掉**）｜20 个夹具逐例跑**修前/修后两件**比整份输出 ⇒ **`identical=17 changed=3`**，`changed` **恰好 = 3 个新夹具**｜本车道验收脚本 `~/w150a/verify-fix.sh` **18 条两极性**：修后 `VERIFY=PASS total=18`、**同一脚本对修前件 `pass=10 fail=8`（8 条红恰好是缺陷条）** ⇒ **脚本自己有牙**。
#   ④ **零产品改动**：`src/**`／`build/shims/**`／native 源**一字节未动** ⇒ 九位**不应有产品位移**；`pf` 是**环成员**（整波重建必变、**同尺寸 6,123,520 B**）⇒ 机械位移，**不许当漂移/回归判据**。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`（3601408 B）／`pf` `c69bc1742cfa7f39`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `d2b76a0a56a41be1`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`（293165 B）／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#57` 冻结值**：`pf` `cce46045c58adba6` → `c69bc1742cfa7f39`（**环成员 `D-G92`**：**同尺寸 6,123,520 B** ⇒ 机械位移）；其余**八位逐位未变** ⇒ **主控独立现算复核**。
#   ⚠️ **`inputs_fp` 两笔（成对、带机械归因）**：`abd349fd58133955538e830d60401f6f0e7ef4ea9d068e6a8020626eea827d3d`（`#57` 冻后值）→ **`4c4d99f569a00380f94ff00ef136f1241884a32181f8ee1216ef6ca7b1a061ee`**。归因 = **本波只动了覆盖面 155 件里的 1 件**（`build/MilBridge/tools/regression-decision.py`，**它在 `fp_inputs()` 白名单内**）；**机械反证**：把该行内容换回修前件 ⇒ 指纹**逐位回到** `abd349fd58133955538e830d60401f6f0e7ef4ea9d068e6a8020626eea827d3d` ＝ `#57` 声明值 ⇒ **位移 100% 归因于这一件**。另三件**不在覆盖面**（现场 `grep` 命中 0）：`docs/PREREG-TEMPLATE.md`／`build/MilBridge/tools/prereg-four-requirements-check.sh`（新件）／主控三件（`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv`）。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   **冻前 `verify-all` = `31` 步**：**通过 30 ❌ 失败 1**、失败项**唯一** = `COLUMN-FLOOR`（**声明类**）｜`用例通过 875 跳过 2`｜`X-REUSE=reused display=:99`｜`SKIP_GUARD=PASS`｜`设备上没有空间` = **0**｜`[29] REGRESSION-DECISION` 在本波**换件后仍绿**（它跑的就是本波修好的那颗牙）｜`[19] FP-INPUTS-HYGIENE` 绿（覆盖面**不含构建产物**）。
#   **本波同趟改到 `#58`**：新建 `docs/WAVE58-PREREGISTRATION.md`（**标题行含 `#58`** —— 冻结器的 `prereg` 前置）＋ `verify-all.sh` 头注释逐字 ``**`#58` 收官起 = 31 步**``（冻结器硬断言，**位置锚**——`#57` 链把该文件改到 `0345e750fd182a7c`，**不许照抄上一代文本行**）＋ `VERIFYALL-STEPS-DECL` 顶行 `31 gen=#58`（**位置锚**）＋ `STEP-NAMES`／口径句**同趟**。两件**都不在 `fp_inputs()`** ⇒ **不再挪指纹**。
#   **边界／`NOINFO`（照录，不许缩小）**：`F-A`/`F-B` 的**射程未枚举**（全仓还有几处判词被支路绕过／假陈述 ⇒ 未逐处枚举）｜`run_cases` **只比 `state`+`rc`、不比 `reason`** ⇒ 未修（只登记口径差；`F-B` 的覆盖靠**位置约束 ＋ 逐字人核**承担）｜新牙的 `--selftest` 只证明"缺件必红、齐全必绿"，**不证明**任何具体预登记件的四要件**内容为真**｜`F-C` 的**人读纪律**机器强制不了（只做到"两种读法并排印出、逐字标注"）｜`inputs_fp` 的 after 值在**树静止**时才有意义。
#   —— 外挂声明（**两族必须落在最新 `# RE-FROZEN` 块内**；`column-floor-check.sh:229` 用 `grep -E '^# COLUMN-FLOOR '` 在本块里找，缺 ⇒ `COLUMN_FLOOR=NOINFO`（**缺声明 ≠ 通过**））——
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落地（A 半 ＋ 新牙 ＋ B 半，全部 `temp ＋ rename`）】`docs/PREREG-TEMPLATE.md` `75dfc5f3fbc9df40 → 17927a59d050fc83`（`171 → 212` 行、`+41`/`−0`）｜`prereg-four-requirements-check.sh`（新）`57de293df5be263d`／272 行｜`regression-decision.py` `1eda9e3575960cba → 71734fce77842478`／1003 行。**落前把三件重取基线**（`1eda9e3575960cba`／`5d3c26a1c8d83688`／`75dfc5f3fbc9df40`）逐位核对 ⇒ 与原型基线**完全一致**才动手；`verify-all.sh` 已是 `#57` 链改后的 `0345e750fd182a7c`（1055 行）⇒ 头注释/DECL 的改动**全部用位置锚**。
#   【② 缺陷复现（改前，逐字机读行）】`F-A`：`--old 3/16 --new 10/16 --pairs 16 --planned-legs 99 --planned-power 0.1 --old-repro yes` ⇒ **`REGRESSION_DECISION=REGRESSION`／`REGDEC_RC=0`**（而同条件的 `--old-repro no` ⇒ `NOINFO/rc=3/plan-mismatch`）｜`F-B1`：`--old 0/5 --new 4/5 … --old-repro yes` ⇒ `REGRESSION/rate-aggravated`，理由断言「旧件也红」**与同屏 `REGDEC_TABLE old=0/5` 矛盾**｜`F-B2`：`--old 3/16 … --old-repro no` ⇒ **假分类** `statistical-new-only`｜`F-B0`（本车道新查出）：`--old 3/5 --new 5/5 … --old-repro no` ⇒ `reason=not-significant(… 且旧件 0 红 …)` 与同屏 `old=3/5` 矛盾｜`F-C`：`0/25 vs 5/25 ⇒ p=0.050152`（三位 `0.050` ⇒ 人读会翻成 `REGRESSION`）。
#   【③ 整波】`close-wave.sh --skip-verify-all`：槽内 `rc=0`、`失败步骤=0`、`[1/6]` appliers 读数、`[4/6]` **波前==波后 = `4c4d99f569a00380f94ff00ef136f1241884a32181f8ee1216ef6ca7b1a061ee`**；九位位移 = **预期只有 `pf`**（环成员）；**`inputs_fp` 必变**（`regression-decision.py` 在覆盖面白名单内）⇒ 见 §FROZEN 的成对记账（**before/after ＋ 机械反证**）。
#   【④ 五臂／重钉】**本波不改 `GEN_KEYS`**（不动 `build/MilBridge/run.sh`／`HbTextLineParity/Program.cs`／`build/shims/PresentationCore.HbTextLine.cs`）⇒ **五臂不重取**、**`known-red.json` 不动**（`:180` 那条**叙述**里出现的修前 sha16 属 `#52` 波的历史记录，**不改也不重钉**；改牙本体**不**动它——`known-red.json` 是 `fp_inputs()` 成员，若改动它会额外挪一次指纹）。五臂日志现场逐臂复算与 `#57` 声明**逐位相同**：`1c43a12dcaa5718a`／`9150c3a26a3cb789`／`92570318851ca7e8`／`59a203de30d745a8`／`4bceceeed570ba70`。
#   【⑤ 门禁 ×2（槽内）】两趟逐行对拍合格线 = **判词行逐字一致**（跑次戳／临时目录随机后缀／仪器计数漂移**不算差异但必须点名**）。读数见 §FROZEN。
#   【⑥ 冻前 `verify-all`】见 §FROZEN：`通过 30 ❌ 失败 1`（唯一声明类红 `COLUMN-FLOOR`）／`用例通过 875 跳过 2`。
#   【⑦⑧⑨ 待冻后追加（`APPEND_ONLY`）】冻结 `#58` 的 `FREEZE_RC`／四颗牙／**冻后 ×2 两趟**（各 `31 ✅ / 0 ❌`、`用例通过 875 跳过 2`、`NOFILE_SWAP`）／`~/w21-verify/w58-POST.done` 的 mtime／推送 head ＋ `BYTECHECK`／app-local `STALE/DIVERGENT`／哨兵两处。
#   【牙与件（现算 sha16）】`~/w150a/criteria.md`（判据先行）｜`~/w150a/report.md`（链报告）｜`~/w150a/apply-fix.py`（B 半替换器：**精确子串 ＋ 命中 1 次断言 ＋ `temp＋rename`**）｜`~/w150a/land-a-half.py`（A 半插入器：**行锚定 ＋ 幂等守卫 ＋ 落前重核**）｜`~/w150a/verify-fix.sh`（18 条两极性验收，**只拿机读行判**）｜`~/w150a/regression-decision-fix.diff`（unified diff）。
#   【两趟对拍的口径（主控裁定，沿用）】**合格线 = "判词行逐字一致"**；`tline-gate` 的跑次戳 `outdir=`／`column-floor` 的临时目录随机后缀／`FRAMEPRESENCE` 的帧计数三处**不算差异**，但**必须点名并列出实际数**。**护栏**：任一**判词行**不同 ⇒ **停手报主控**。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:c69bc1742cfa7f39,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:c69bc1742cfa7f39,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:c69bc1742cfa7f39,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:c69bc1742cfa7f39,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:c69bc1742cfa7f39,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:c69bc1742cfa7f39,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
# ⏪ **（历史，已被 `#58` 取代）**# RE-FROZEN #57 —— ✅ **当前冻结基线** —— 内容 = 关掉 **`TASK-0211`** 的三处窄 `TOCTOU`／生命周期缺陷
#   ① **A 点** `src/WpfGfx.Linux.Native/src/win32_msg.c` `PostMessageW`：旧实现 `:846` 锁内取 `target = w->owner_thread` → `:848` 放锁 → `:880/:881` 在**陈旧指针**上解引用 → `:883` 入队（`:879` 那次"再取锁"对陈旧指针**无救**）。修法 = 删 `:848`/`:882` 两次放锁，"查表→判死→取 pt→入队"收进**同一临界区**，放锁挪到 `wpf_queue_push` **之后**。
#   ② **B 点** 同文件 `PostThreadMessageW`：旧实现 `:896` 放锁 → `:906` 入队（**此后无锁且无任何存活校验**）。修法同形；`if (!target)` 展开为"**先放锁再报 1444**"。
#   ③ **fd 点** `src/WpfGfx.Linux.Native/src/win32_core.c` `wpf_thread_destroy` `:151-152`：旧实现在**锁外** `close(wake_read/wake_write)` 且**不置 `-1`**（对照创建路径 `:210` 有置）⇒ 唤醒路径可能写**已关闭/已复用 fd 号**。修法 = **锁内先置 `-1` 再 close**。
#   ⚠️ **修法只靠一条前提成立（本波升格为判据）**：`wpf_queue_push` **自己也会放锁**（`win32_msg.c:98` 取、`:132` 放），"放锁挪到 push 之后"之所以成立**完全依赖递归锁计数** —— 调用者深度 1 → push 取到 2 → `:132` 只掉回 **1** ⇒ `:134 wake` 与 msgflow **仍在 A/B 的临界区内**；前提一破（锁改成普通互斥量）修法**静默失效**。牙 `premise.py`（`bc7cc452f07a41b5`）：P1 **行为**取证（同线程二次取锁 5 s 内返回；**负对照** = 假 `PTHREAD_MUTEX_NORMAL` 件 ⇒ `P1=FAIL`）／P2 件级（`n_unlock=1 unlock@14a5d < wake@14a65`）／P3 源级同一 `attr`。
#   ⭐ **本波最硬的方法论产出：构建确定性 ＋ 预测对拍** —— 在 `/tmp` 用**未改原件**重建 ⇒ 产件 sha16 **`2067cb1c97728791`**、与冻结件**逐字节相同**（导出两边 547）⇒ 干跑给出的修后件 sha 是**可对拍预测值**，真实落地**逐位命中 `d2b76a0a56a41be1`**（三趟反极性件 `aeb179a2d3d9ca44`／`d60f056672f7b4d5`／`5d58b2c18791c369` 亦**全部命中**）。
#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`（5028208 B）／`pc` `722e0ab8205b7c3f`（3601408 B）／`pf` `cce46045c58adba6`（6123520 B）／`windowsbase` `2e4e46e539a72cd7`／`provider` `1f9511a7ef395bfe`／`win32shim` `d2b76a0a56a41be1`／`wic_shim` `f7b3026c8c019be2`／`hbtextline` `921ba9c65e9fb3be`（293165 B）／`dwf` `ce3469f49efcbcfa`。
#     · **相对 `#56` 冻结值**：`win32shim` `2067cb1c97728791` → `d2b76a0a56a41be1`（**本波改 native**，预期内）；`pf` `f2df3c2b464b7f00` → `cce46045c58adba6`（**环成员 `D-G92`**：**同尺寸 6,123,520 B** ⇒ 机械位移，**不许当漂移/回归判据**）；其余**七位逐位未变** ⇒ **主控独立现算复核**。
#   ⚠️ **`inputs_fp` 两笔（成对、带机械归因）**：`4ce9f65af5f102a6d9cc8d9e72e79b99e9214a634a15796abe6f7f6447b47ef2`（`#56` 冻结值）→ **`abd349fd58133955538e830d60401f6f0e7ef4ea9d068e6a8020626eea827d3d`**。第一笔 = 整波后 `ecaf53ddc2b5f508e790d64e2a9c024f1e3e7f70b0c6d4457218c0e71d69bd9b`，归因 = **本波改的 native 源在覆盖面内**（覆盖面 155 件中 `src/WpfGfx.Linux.Native` **42 件**，机械验证）；第二笔 = 重钉后 `abd349fd58133955538e830d60401f6f0e7ef4ea9d068e6a8020626eea827d3d`，归因 = **`known-red.json` 因重钉而变**（它是覆盖面成员，机械验证）；反证 = `arm-logs` 在覆盖面里 **0 件** ⇒ 五臂重取**不**挪指纹。
#     ⚠️ **口径：指纹类读数只在树静止时有意义** —— 同一命令在 `verify-all` 在跑时曾算出 `cdfba971…`，树静止后稳定于 `abd349fd58133955538e830d60401f6f0e7ef4ea9d068e6a8020626eea827d3d` ⇒ 前者**作废**（不当第三次位移）。
#   **`BRIDGE_SRC_FP` = `d697b1e10ff48881`**（上一代 `d697b1e10ff48881`；本波未改桥源 ⇒ 逐位未变）。
#   **冻前 `verify-all` = `31` 步**：**通过 30 ❌ 失败 1**、失败项**唯一** = `COLUMN-FLOOR`（**声明类**）｜`用例通过 875 跳过 2`｜`X-REUSE=reused display=:99`｜`SKIP_GUARD=PASS`｜`设备上没有空间` = **0**｜四新步 `HYGIENE`／`REGRESSION-DECISION`／`UIA-DOOR`／`IME-LANDING` 全 ✅。
#   **本波同趟改到 `#57`**：新建 `docs/WAVE57-PREREGISTRATION.md`（**标题行含 `#57`** —— 冻结器的 `prereg` 前置）＋ `verify-all.sh` 头注释逐字 ``**`#57` 收官起 = 31 步**``（冻结器 `:486-487` 的硬断言）＋ `VERIFYALL-STEPS-DECL` 顶行 `31 gen=#57`。两件**都不在 `fp_inputs()`** ⇒ **不会再挪指纹**。
#   **两点停手（判得对；停手后由主控补本模板续跑）**：① 装置 `~/w142a/bin/run-gate.sh` 的 rows 是**追加日志**（跑完 12 行 = `#56` 的 6 行 ＋ 本趟 6 行），冻结器断言恰 6 行 ⇒ 车道按**终态 config** 过滤出 6 行写 `~/w146a/w57-rows.txt`（`15323 B`）⇒ 冻结器打"门禁 6 条机读行 OK"；**建议**：该装置每趟换新文件或先截断，否则"两本 rows 对拍"会失真。② 冻结器要求 `TXT` 是**含三段段标与占位符的模板**，而派单把"记录"排在 ⑦ 之后 ⇒ **顺序与工具期望相反**；车道**拒绝编造记录**（正确）⇒ 由主控供本模板。
#   **边界／`NOINFO`（照录，不许缩小）**：三处的**自然发生率／可利用性** = `NOINFO`（牙是**结构性**判据，不产生并发触发读数；WC07 现行件 `0/12` 是"没走到那条路"，**不是**"窗口不存在"）｜**C5 零回归只取到 ①导出数 547 ②ABI 自检**；`QUEUE_INVARIANT`／WC07 触发件／样本应用**未跑 ⇒ `NOINFO`，不填绿**｜**源级反极性**（改 `src/**` 后重编）**未做**｜`fd` 残余能否被自然触发 = `NOINFO`（存在性已证）。
#   —— 外挂声明（**两族必须落在最新 `# RE-FROZEN` 块内**；`column-floor-check.sh:229` 用 `grep -E '^# COLUMN-FLOOR '` 在本块里找，缺 ⇒ `COLUMN_FLOOR=NOINFO`（**缺声明 ≠ 通过**））——
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=59a203de30d745a8
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 落地】`2067cb1c97728791` → **`d2b76a0a56a41be1`**（导出 **547** 未变）；源件 `win32_msg.c` `12175591b736bb3f → 4a88fffb1a0cd7f1`、`win32_core.c` `c66528843de4a370 → e7f6a37a30f5a037`；`pred_hit=YES`。
#   【② 三点各自成对反极性（三趟独立重建；**禁止合并判一次**）】`onlyA.so aeb179a2d3d9ca44` ⇒ A=`BROKEN[0]`／B=`HELD[1]`／fd=`FDFIXED`｜`onlyB.so d60f056672f7b4d5` ⇒ A=`HELD`／B=`BROKEN[0]`／fd=`FDFIXED`｜`onlyfd.so 5d58b2c18791c369` ⇒ A/B=`HELD`／fd=**`FDSTALE rc=1`**｜终态 `fullfix.so d2b76a0a56a41be1` ⇒ 全 `HELD`＋`FDFIXED`；`premise=PASS` 三趟皆然。**主控独立 4/4 复算通过**。
#   【③ 整波】`close-wave.sh --skip-verify-all`：`rc=0`、`失败步骤=0`、`[1/6] appliers=28 ok=95 miss=0 red=0`、`[4/6] 波前==波后 = ecaf53dd…`、槽 `held=197s`；位移 = `win32shim` ＋ `pf`；`APPSYNC` 非 PASS = **登记在册的告警**（`UNEXPECTED=6[DECL-GAP-EQ=6]`，非硬闸）。
#   【④ 五臂＋重钉】五臂重取（`:97` 复用）：**只有 `tline` 变**（`69b070d4fe25877d → 59a203de30d745a8`，含耗时戳），另四臂**逐字节相同**（`9150c3a26a3cb789`／`1c43a12dcaa5718a`／`92570318851ca7e8`／`4bceceeed570ba70`）；**判词行 `diff` = 空** ⇒ 与 `#56` **逐字相同**；`REPIN_GENERATION=APPLIED → --check=PASS`、`entries[*].caliber 改动字段数 = 0`；`known-red.json 102a883d91b9c41c → 64b22d35efc1e3be`；旧件按纪律 59 归档 `~/w146a/arm-logs-archive-56/`。
#   【⑤ 门禁 ×2（槽内）】两趟逐行对拍**相同**（唯一差异 = `MEMOK avail=` 内存读数）：`TLINE_GATE=PASS`，口径 `judge=t1b3-tline-gate/7`，**该装置无 `result=` 行**（**不许与 `#56` 的 `WPTD_*` 装置混用口径**）｜`arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK`；`unlocated=1` = `tline/T3b`（按册判 `PASS`）。
#   【⑥ 冻前 `verify-all`】见 §FROZEN：`通过 30 ❌ 失败 1`（唯一声明类红 `COLUMN-FLOOR`）／`用例通过 875 跳过 2`。
#   【⑦⑧⑨ 待冻后追加（`APPEND_ONLY`）】冻结 `#57` 的 `FREEZE_RC`／四颗牙／**冻后 ×2 两趟**（各 `31 ✅ / 0 ❌`、`用例通过 875 跳过 2`、`NOFILE_SWAP`）／`~/w21-verify/w57-POST.done` 的 mtime／推送 head ＋ `BYTECHECK`／app-local `STALE/DIVERGENT`／哨兵两处。
#   【车道自陈的两起越界（全零损伤）】两次在**口令收紧前**写了 `$R`（第一次构建从未开始；第二次偏差窗口约 55 s，全盘 sha 扫描证明未污染共享位置）。**口径句（落册）**：**"闸门字面满足 ≠ 可以写共享 `$R`；写前必须确认 ① 收尾/构建链不在跑 ② 重活槽未被别人持 ③ 冻后链已完成。"**
#   【牙与件（现算 sha16）】`pushtooth.py` `c2e5f14b2124570d`（主判据：**可达性**锁深度集合分析；旧线性牙 `lockspan.py` 对 B 修后**假红**、`fdsafe.py` 最早一版在修前件上**假绿** —— 均实测抓到并改正）｜`fdsafe.py` `255eba9192ed3fb7`｜`premise.py` `bc7cc452f07a41b5`｜`patch/apply.py` `c767d13111ddb6e6`｜`criteria.md` `0843abd3f52c971a`。
#   【`NOINFO`（逐条，不许缩小）】见 §FROZEN 末段。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:cce46045c58adba6,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:cce46045c58adba6,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:cce46045c58adba6,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:cce46045c58adba6,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:cce46045c58adba6,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:cce46045c58adba6,provider:1f9511a7ef395bfe,win32shim:d2b76a0a56a41be1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
# ⏪ **（历史，已被 `#57` 取代）**# RE-FROZEN #56 —— ✅ **当前冻结基线** —— 内容 = 收掉 `#56`（**仪器波** · `TASK-0708`：四件新牙接线；
#   收尾链 ①–⑨ 由车道 **W142A** 一步到底）：
#   **① 本波是什么**：**只接线，零产品改动**。把 `#52` 收口时登记为「牙已备、无人跑」的四件牙接进
#     `verify-all.sh`（**27 → 31 步**）：`[28]` `HYGIENE`（`TASK-0706`）／`[29]` `REGRESSION-DECISION`（`TASK-0705`）／
#     `[30]` `UIA-DOOR`（**在册红形态**，跑新消费者 `known-red-arms-check.sh`）／`[31]` `IME-LANDING`（`D-G76` 在册降级）。
#     四处声明同趟改；`tline-gate.sh` 一字未改；`src/**` 一字节未动。
#   **② 装置／判据件（本波变更，主控逐条批准）**
#     · `verify-all.sh` `80455e8d5eb92cb3` → **`eb29ced9d81b2345`**（`^run_step "` = **31**；`bash -n` rc=0；
#       `VERIFYALL_SELF=PASS names=31 decl=31 gen=#56 dup=0 order=OK prose=OK prereg=PASS`）
#     · `build/close-wave.sh` `c757fd5058f1bfd4` → **`0cf2ea72bdee142c`**（`fp_inputs()` 名单 +5 件＋tsv；`bash -n` rc=0）
#     · **新建** `build/MilBridge/tools/known-red-arms-check.sh`（`8c9aee142ebe0432`，自检 10/10 PASS）／
#       `build/MilBridge/tools/regression-decision-cases.tsv`（`5d3c26a1c8d83688`）／
#       `docs/WAVE56-PREREGISTRATION.md`（`5e549908db73fae7`）
#     · `build/MilBridge/known-red.json`：`433d2d371787c004` → `453d17ca981d3116`（并入 `arm=uia-door`）
#       → **`102a883d91b9c41c`**（本波重钉；`entries[*].caliber 改动字段数 = 0` ⇒ **只动世代记账，没碰任何判据口径**）
#     · **五臂重取**：`tline` `a46cb0b4e853fa1f` → **`69b070d4fe25877d`**（该日志含 app-local 同步行／耗时／日期戳）；
#       其余四臂 **`tab-zero 9150c3a26a3cb789`／`tab-anchor 1c43a12dcaa5718a`／`tab-rtl 92570318851ca7e8`／
#       `textlineproto 4bceceeed570ba70` 逐位不变**（**预测先写、事后命中**）；别名侧 `nlink 2→1` 真副本（`cmp IDENTICAL`）。
#   **③ 九位（终态）与位移对账**
#     · `bridge` `4e25e4b27d4d5ae1`（5028208 B）｜`pc` `722e0ab8205b7c3f`（3601408 B）｜`pf` `b4c81eb3f1376f86`（6123520 B）｜`windowsbase` `2e4e46e539a72cd7`｜
#       `provider` `1f9511a7ef395bfe`｜`win32shim` `2067cb1c97728791`｜`wic_shim` `f7b3026c8c019be2`｜
#       `hbtextline` `921ba9c65e9fb3be`（293165 B）｜`dwf` `ce3469f49efcbcfa`。
#     · ⚠️ **位移对账（相对 `#55` 冻结块那一栏）**：**只有 `pf`** `f2df3c2b464b7f00` → `b4c81eb3f1376f86`（**同一尺寸 6123520 B**），
#       且它是**预测里点名的那一位**（本波零产品改动，`pf` 是**环成员**：整波重建必换身份字节，`D-G92`）；
#       其余八位 `bridge`／`pc`／`windowsbase`／`provider`／`win32shim`／`wic_shim`／`hbtextline`／`dwf` **逐位未变**
#       （含 **`win32shim 2067cb1c97728791` 与 `#55` 同**、**`bridge 4e25e4b27d4d5ae1` 不动**、`BRIDGE_SRC_FP` `d697b1e10ff48881` 与 `#55` `d697b1e10ff48881` 同）。
#     · 🔴 **`pf` 不是构建身份（`D-G92`，逐字）**：同源、同命令的两次重建可给出**不同字节**。本波是**第七条连续证据**；
#       **两刻并列见 `===RECORD===` 步骤③**；**两刻不同不算失败**（本代 `allow_changed={'pf'}`、`pf_required=False`）。
#   **④ 判据/登记件**：`inputs_fp` = `1a999e79f236303891b06c54ef659fe989262cd841140641a13ad27acf12254e`（`#55` 冻结点 = `ca0a768162af87f88d8b84d777a66b769da8a74ea3e5ab273741f781c0e50e20`；本波两笔位移**逐条可归因**：
#   ⚠️ **口径句（主控 23:2x 裁定，逐字）**：`[29] REGRESSION-DECISION ✅` 只指**本步的行式径通过**；该牙 `--old-repro yes` 支路**缺 ④ 检查（假绿，已登记 `D-G99` 追加位点）**，本波**不修**、随 `#58` 修。
#     ① 接线（覆盖面 +6 件 ＋ `close-wave.sh` 自含）② 重钉 `known-red.json`，它在覆盖面内）
#     ｜`bridge-src-fp` = `d697b1e10ff48881`（`#55` = `d697b1e10ff48881`，**逐位相同** —— 桥源零改动）。
#   **⑤ 零回归**：九位里八位逐位不动｜应用门禁 **×2 各 6/6 PASS**（`config=` 两本逐字相同）
#     ｜`hbtextline` **逐位未变**（`build/shims/**` 零字节改动）｜`fp-inputs-hygiene` 绿（`coverage_n=155 artifact_n=0`）。
# ── 🦷 外挂声明行（**`#31` W31D 起的三类**；`column-floor-check.sh` 读者用 `^# COLUMN-FLOOR ` 等前缀锚定）
#   ⚠️ **血案留痕（同一个坑已踩两次：`#51` W110A、`#52` W126A）**：这些行**必须有 `# ` 前缀**，且**必须在冻结块里**。
#     `#51` 第 1 次冻结把 8 行写成**无 `# ` 前缀** ⇒ `COLUMN_FLOOR=NOINFO reason=frozen-block-has-no-COLUMN-FLOOR-line`；
#     `#52` 第 1 次冻结**一行都没写** ⇒ 同样失败。**本件（`#56`）在落盘之前先机械自检这 8 行齐全**。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=69b070d4fe25877d
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
# ── `#56` 收尾链记录（车道 **W142A**，2026-09-23 22:2x–23:xx +0800）──────────────────────────────
# 【本件与记录件的关系】本段由本车道手写落盘（机械自检：三段标记齐全／8 行外挂声明带 `# ` 前缀／
#   占位符名合法）；**冻结完成后**冻后两趟与推送读数按 `#51`/`#52`/`#54`/`#55` 先例**只在末尾追加**
#   （保真证明见本文件末的 `APPEND_ONLY_PROOF`）。
# 【判定点/口径】本波判据先写于 `~/w142a/criteria.md`（sha16 `e4611d42fd8254d6`，**开工前落盘**）。
#   条目：C1 九位（零产品改动 ⇒ 九位与 `#55` 逐位相同；`pf` 为环成员，`D-G92`）｜C2 四处声明（`names=31 decl=31`；
#   头注释逐字含 `` **`#56` 收官起 = 31 步** ``）｜C3 每条重活前空盘/可写预检（≥5 GiB ＋ `/tmp` 可写）｜
#   C4 冻前 `verify-all` 恰 1 处声明类红 `COLUMN-FLOOR`｜C5 冻后 ×2 各 `31 ✅ / 0 ❌`、两趟间不许换件｜
#   C6 在册红只 `arm=uia-door`（`rc_tooth=1`）；牙回 `NOINFO` ⇒ 该步必须 `rc=2`｜C7 tsv 处置（读 ⇒ 进 `fp_inputs()`）｜
#   C8 `NOINFO` 既不算绿也不算红｜C9 推送逐径 `git add` ＋ 字节核对。
#
# ① 起点（现场重算，不照抄派单书）
#   · 已冻结 = `#55`（`docs/CURRENT-STATE.md:9` = `gen=#55 sha16=38320d5e377a0dc8`，785,675 B）｜四颗牙全 PASS
#   · 远端 head（= 本地）= `502f3061cee5e0f0f4713d18b36438633d921875`（`--symref` = `feat-Linux`）
#   · `verify-all.sh` 起手 = `80455e8d5eb92cb3`（98433 B；`^run_step "` = 27；`DECL` 顶行 `27 gen=#55`）
#   · `build/close-wave.sh` 起手 = `c757fd5058f1bfd4`（36725 B）｜`known-red.json` 起手 = `433d2d371787c004`
#   · `inputs_fp` 起手（真函数算） = `929cb1b7f2db5fb40f54415dd49ac40a4dc1c778e566ae8f3d42971e2c4b38d9`
#   · 磁盘 `df --output=avail /` = 70435920 KB｜`MemAvailable` 开工 = 3866 MB｜`nproc` = 4
#
# ② ⚠️ **并发写者（如实记）**：本车道 22:25:16 开工；22:25:45–22:26:47 之间**主控侧**已把本波落件做完
#   （`verify-all.sh` → `eb29ced9d81b2345`／`known-red.json` → `453d17ca981d3116`／`close-wave.sh` → `027e1551b148c29e`；
#   消费者／tsv／预登记三件 17:20:04 已在仓内）。⇒ 本车道的落件动作改为**复核 ＋ 补缺口**，
#   本车道**独立**补的唯一一件 = `regression-decision-cases.tsv` 进 `fp_inputs()`（主控 22:5x 逐条批准）。
#
# ③ 整波（`WAVE_OWNER=W142A bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1200 --wait 1800 -- bash build/close-wave.sh --skip-verify-all`）
#   · ⚠️ **偏差如实记**：主控给的命令是裸 `bash build/integration-wave.sh`；本车道走 `close-wave.sh --skip-verify-all`
#     —— 它的 `[1/6]` **就是** `integration-wave.sh`（同一条读数），另含 `[2/6]` native／`[3/6]` 桥／`[4/6]` 身份自检／
#     `[6/6]` **哨兵刷新**（`integration-wave.sh` 单跑**不刷哨兵**，而开工时哨兵仍是 20:57 旧版）。主控已批准该偏差。
#   · 槽：`HEAVYSLOT=ACQUIRED waited=0s`／`MEMOK avail=4617MB`／**`RELEASED rc=0 held=242s`**／`max_hold=1200s`
#   · `[0/6]` 波前输入指纹 = `e1e4a5f2aa7635cf30a1663d3500ab2590eebfaf01898b92442e52b914c3f646`（= 接线后现算值）
#   · `[1/6]` = **`APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0`** ＋ **`=== 集成波结束：失败步骤 0 ===`**
#   · `[2/6]` native `源码不比权威件新 ⇒ 跳过重建`｜`[3/6]` 桥 `源指纹一致（d697b1e10ff48881 == d697b1e10ff48881）⇒ 无需重发`
#   · `[4/6]` 桥源 fp 两侧一致 ✓／生成物指纹 `state=ok` ✓／应用器审计 `miss=0` ✓／
#     **输入稳定性：波前==波后 == `e1e4a5f2aa7635cf30a1663d3500ab2590eebfaf01898b92442e52b914c3f646`**（预测命中）
#   · `[6/6]` **哨兵已刷新**（`/tmp/bridge-frozen.flag`；镜像 `~/wfp-runs/bridge-frozen.flag`）
#   · `OUT=/home/links-dev/wfp-runs/close-wave-223105`｜`CLOSEWAVE_OUTER_RC=0`
#   · **两刻 `pf` 并列（`D-G92`）**：整波**前** `pf` = `f2df3c2b464b7f00`；整波**后** = `b4c81eb3f1376f86`（**同尺寸 6123520 B**）。
#     其余八位两刻逐位相同；`win32shim` 两刻都 `2067cb1c97728791`。
#
# ④ 四步逐件单独跑（判据 C6；日志 `~/w142a/logs/step28..31*.log`）
#   · `[28]` `HYGIENE` rc=**0**｜`HYGIENE_TOOTH=PASS roots=PASS evidence=PASS inode=PASS scope=REPORT semantic_undecidable=7
#     multilink=0 cross_region=0 ext_ext_hits=0 ext_strict=0 code_files=73`（⚠️ `HYGIENE_SCOPE` **永不为 PASS** ⇒ 它**不**声称全域干净）
#   · `[29]` `REGRESSION-DECISION` rc=**0**｜`REGRESSION_LEDGER=PASS rows=7 pass=7 fail=0`
#   · `[30]` `UIA-DOOR` rc=**0**｜`KNOWN_RED_ARMS=PASS arms=1 ok=1 fail=0 noinfo=0 registered_red=uia-door`
#     （牙本体**直跑** rc=**1** = 设计内红：`UIA_DOOR=FAIL prod=0 consume=1 core_shim=0 uia_syms=0 ctrl_syms=8 live_calls=2 (all=69) libs=1`
#     —— 与在册 `expected_shape` **逐字相符**；消费者判「红 ∧ 在册 ⇒ 放行」⇒ 该步 `rc=0`）
#   · `[31]` `IME-LANDING` rc=**0**｜`IME_LANDING=PASS landings=0 declared=yes ctrl=5 sm82_nonzero=0 shim_map=0 so_syms=0 decl_hits=2`
#   · 消费者自检：`KRA_SELFTEST=PASS total=10 pass=10 fail=0 target_untouched=yes`
#   · 口径步：`VERIFYALL_SELF=PASS names=31 decl=31 gen=#56 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO`
#   · 覆盖面牙：`FP_INPUTS_HYGIENE=PASS reason=clean coverage_n=155 artifact_n=0`（本车道改过 `fp_inputs()` 后仍绿）
#
# ⑤ 五臂重取（预测**先写**于 `~/w142a/STATUS.md`，早于取数）
#   · 预测：判词应与 `#55` 逐字相同；`tline` 那支 sha **可能变**（含耗时/日期戳）；四支 tab/proto 臂 sha 预期不变。
#   · 槽：`RELEASED rc=0 held=492s`／`max_hold=1200s`｜`ARMS_OUT=~/wfp-runs/arms56`（新目录）｜
#     `ARMS_DISPLAY=:97 source=reused`（复用已存在的 `:97`，**未自起、未碰任何人的 X**）
#   · 自证行：`shim=921ba9c65e9fb3be pc=722e0ab8205b7c3f run.sh=711f39f468f61cc8 Parity.cs=149dd986a642fdfc`
#   · sha：`tline a46cb0b4e853fa1f → （读数见本件末的**冻后追加段**） **变（预测内）**`｜
#     `tab-zero 9150c3a26a3cb789`／`tab-anchor 1c43a12dcaa5718a`／`tab-rtl 92570318851ca7e8`／
#     `textlineproto 4bceceeed570ba70` **四臂逐位不变**
#   · 判词（**与 `#55` 逐字相同**）：`tline 通过 22 / 失败 2`｜
#     `tab-zero 退出码=1（未登记失败 1 / 失败共 1）`（唯一 = `notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白 期望=0 实得=1`）｜
#     `tab-anchor START 红=0 绿=615 判定行=615`／`OVERFLOWED 红=0 绿=421 判定行=421`／`字形释放行=194`｜
#     `tab-rtl 红=0 绿=0 判定行=0 NOINFO=163`｜`textlineproto 探针 通过 4 / 失败 2`（`run.sh` 口径）
#   · 别名侧 `nlink 2 → 1`（`TASK-0502` 波尾必做②）：五件 `cp -p` 临时名 ＋ `mv -f`，`cmp IDENTICAL`、
#     inode 互异；**权威侧 `build/MilBridge/arm-logs/*.log` sha 逐位未变**。
#
# ⑥ 重钉世代（`repin-generation.py`）
#   · **重钉前** `--check` = **`REPIN_GENERATION=FAIL n=2`**（`generation.arm_logs.tline` ＋
#     `evidence_log_sha256 声明=a46cb0b4e853fa1f 现场=69b070d4fe25877d`）＝**声明类红**，由本步转绿。
#   · `--why '波 #56（仪器波 TASK-0708）五臂重取：…'` ⇒ **`REPIN_GENERATION=APPLIED`**：
#     `instr_run_sh=711f39f468f61cc8`／`instr_program_cs=149dd986a642fdfc`／`instr_shim=921ba9c65e9fb3be`／
#     `evidence_log_sha256=69b070d4fe25877d`／**`entries[*].caliber 改动字段数 = 0`**
#   · `--check` ⇒ **`REPIN_GENERATION=PASS`**｜`known-red.json`：`453d17ca981d3116` → **`102a883d91b9c41c`**
#   · `arm-log-sha-check.sh` 单跑 ⇒ `ARMLOG_SHA=PASS shape=flat required=5 declared=5 pass=5 fail=0 noinfo=0`
#
# ⑦ 应用门禁 ×2（判据：两本 rows 各 6/6 PASS）
#   · 第 1 趟 `:215`（自起 1280x1024x24）：`GATE1_OUTER_RC=0`｜`WPTD_SUMMARY=PASS tiers_passed=2/2`｜
#     `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`｜rows `~/w142a/gate-rows.txt`（sha16 `9b360369765f2934`）⇒ **6 条 `result=PASS`／0 FAIL**
#   · 第 2 趟（`--no-build`）`:216`：`GATE2_OUTER_RC=0`｜rows `~/w142a/gate-rows-f.txt`（sha16 `90663773755e893c`）⇒ **6 条 `result=PASS`／0 FAIL**
#   · 两本 `config=` 段 **`CONFIG_IDENTICAL`**：`pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:b4c81eb3f1376f86,provider:1f9511a7ef395bfe,win32shim:2067cb1c97728791,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no)`
#   · ⚠️ **偏差如实记**：本步为**裸跑**（未走槽）；主控现场核过当时槽 `flock` FREE、空闲内存 4082 MB、
#     `:215`/`:216` 均空闲 ⇒ **读数有效**；`⑥⑧` 两步改回**槽内** `--max-hold 1800`。
#
# ⑧ 冻前 `verify-all`（31 步；槽内 `--min-avail 1500 --max-hold 1800 --wait 1800`）
#   · 槽：`（读数见本件末的**冻后追加段**）`｜`PRE_OUTER_RC=（读数见本件末的**冻后追加段**）`｜日志 `~/w142a/logs/24-verify-pre.log`（sha16 `（读数见本件末的**冻后追加段**）`）
#   · 步数与用例：**`（读数见本件末的**冻后追加段**）`**／**`用例通过 875 跳过 2`**
#   · `[0]` 段：**`X-REUSE=reused display=:99`**（几何 1280x1024 相符而复用）｜**`X_STATE=available`**
#   · 唯一红 = **`COLUMN-FLOOR`**（**声明类**）：`COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch
#     pass=3 fail=1 noinfo=0 selfreport=PASS reg=102a883d91b9c41c base=38320d5e377a0dc8 corpus=0cebc0afd5142fbf`
#     ＋ `COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad=tline`（**正是本波重取要冻进去的那一格** ⇒ **冻后必转绿**）
#   · 若出现 `设备上没有空间` ⇒ 该趟作废重跑（本波**未出现**）
#
# ⑨ 冻结 `#56`（`python3 ~/w21-verify/w27-freeze.py ~/w142a/logs/24-verify-pre.log ~/w142a/gate-rows.txt '#56'`）
#   · ⚠️ **`w27-freeze.py` 的 `GENS` 表原无 `#56` 条目**（最大 `#55`）⇒ 本车道按**该表自身格式**补了一条
#     （`prev='#55'`、`nstep=31`、`allow_changed={'pf'}`、`pf_required=False`、`prev_wsh=2067cb1c97728791`、`prev_wb=2e4e46e539a72cd7`、
#     `prev_dwf=ce3469f49efcbcfa`、`prev_pc=722e0ab8205b7c3f`、`infp=1a999e79f236303891b06c54ef659fe989262cd841140641a13ad27acf12254e`、`prev_infp=ca0a768162af87f88d8b84d777a66b769da8a74ea3e5ab273741f781c0e50e20`、`prev_bsfp=d697b1e10ff48881`、
#     `green=[… 31 步名 …]`），并 `cp -p` 备份原件到 `~/w142a/backup/w27-freeze.py.orig`（`1dda5297af0c8e2d`）。
#     **该件是仓外工具 ⇒ 归主控复核。**
#   · 四颗牙（冻后必须全 PASS）：`BASELINE-SHA`／`BASELINE-GEN`（`decl_gen=#56`）／`BASELINE-BYTES`／`BASELINEDUP n=0`。
#   · 臂日志聚合两口径（如实并列）：`ARMAGG_CAT=b3ebce3f8428a061`｜`ARMAGG_FIND=2c2ab8ae5ce8512c`。
#
# ⑩ 冻后 `verify-all` ×2
#   · 第 1 趟：`（读数见本件末的**冻后追加段**）`｜`POST1_OUTER_RC=（读数见本件末的**冻后追加段**）`｜**`（读数见本件末的**冻后追加段**）`**｜`结论：（读数见本件末的**冻后追加段**）`（日志 `~/w142a/logs/25-verify-post1.log`）
#   · 第 2 趟：`（读数见本件末的**冻后追加段**）`｜`POST2_OUTER_RC=（读数见本件末的**冻后追加段**）`｜**`（读数见本件末的**冻后追加段**）`**｜`结论：（读数见本件末的**冻后追加段**）`（日志 `~/w142a/logs/26-verify-post2.log`）
#   · 两趟之间**不许换件**：`NOFILE_SWAP=（读数见本件末的**冻后追加段**）`（`win32shim`／`bridge` 两刻逐字并列）
#   · 判词层对照：两趟自报口径行逐条对照，差异只允许是**运行期读数**（时间戳／mktemp／帧数／内存）。
#
# ⑪ `NOINFO` 逐条（如实记，既不算绿也不算红）
#   · `verify-all` 第 `[11]` 步自报 `dynamic_trace=NOINFO`（成因未测；`#55` 同形）。
#   · `tab-rtl` 臂：`红=0 绿=0 判定行=0 NOINFO=163`（面缺字形；`#55` 逐字同形）。
#   · `textlineproto` 臂：`探针 通过 4 / 失败 2`＋`通过 10 / 失败 0`（在册欠账项，非本波引入）。
#   · `tab-zero` 臂：`退出码=1`（唯一失败 = `notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白`；`#55` 同形）。
#   · `pf` 的非确定性（`D-G92`）：**只证"同源同命令两次重建可给不同字节"**，**成因未定**。
#   · `HYGIENE` 的 `scope=REPORT`／`semantic_undecidable=7`：口径射程**恒不为 PASS** ⇒ 不声称全域干净。
#
# ⑫ 记录／推送／app-local／哨兵
#   · 推送（逐径 `git add`）：commit `（读数见本件末的**冻后追加段**）` ⇒ `（读数见本件末的**冻后追加段**）`｜`--symref` = `feat-Linux`｜
#     `BYTECHECK ok=（读数见本件末的**冻后追加段**） mismatch=0 nobody=0`｜本地领先（未推，登记车道在办）：`docs/ROUTES.md`／
#     `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv`。
#   · app-local：`STALE=0 DIVERGENT=0 MISMATCH=0 MISSING=0`｜**`APP_ART win32shim=2067cb1c97728791 bridge=4e25e4b27d4d5ae1`**。
#   · 哨兵两处：`/tmp/bridge-frozen.flag` 与 `~/wfp-runs/bridge-frozen.flag` `cmp IDENTICAL`｜
#     `SHA=4e25e4b27d4d5ae1`／`WIN32SHIM=2067cb1c97728791`／`WAVE=（读数见本件末的**冻后追加段**）`。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:b4c81eb3f1376f86,provider:1f9511a7ef395bfe,win32shim:2067cb1c97728791,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:b4c81eb3f1376f86,provider:1f9511a7ef395bfe,win32shim:2067cb1c97728791,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:b4c81eb3f1376f86,provider:1f9511a7ef395bfe,win32shim:2067cb1c97728791,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:b4c81eb3f1376f86,provider:1f9511a7ef395bfe,win32shim:2067cb1c97728791,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:b4c81eb3f1376f86,provider:1f9511a7ef395bfe,win32shim:2067cb1c97728791,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:b4c81eb3f1376f86,provider:1f9511a7ef395bfe,win32shim:2067cb1c97728791,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w142a/gate-e
# ⏪ **（历史，已被 `#56` 取代）**# RE-FROZEN #55 —— ✅ **当前冻结基线** —— 内容 = 收掉 `#55` 这一波（收尾链 11 步由车道 **W141A** 一步到底）：
#   **① 产品侧：`TASK-0209`「修 `win32_msg.c:57-82` 队列链遍历 ＋ 给『写坏者』取证」**（判 `D-G109` 静默 SEGV）
#     落点（三件，全在 `src/WpfGfx.Linux.Native/`）：`src/win32_msg.c`（`4ad790f4c26a907c` → **`12175591b736bb3f`**）／
#     `src/win32_internal.h`（`4e1880e6054635ff` → **`c13390de6f870999`**）／
#     `src/win32_core.c`（`a9cc8762908b417a` → **`c66528843de4a370`**）
#     ⇒ **`win32shim` 位变**：`a6365183fa6d26b9` → **`2067cb1c97728791`**（**尺寸 327,512 → 327,672 B**；**导出符号 547 不变**）。
#     修法 = **F1** 零解引用隔离抢救 ＋ **F2** 具名台账 `[QUEUE_CORRUPT]`（`static`）＋
#     **F3** `wpf_thread_destroy` 摘链 ＋ **F3b** 置空 `owner_thread` ＋ **(A)** 具名台账 `[POSTMSG_DEAD_TARGET]`
#     ＋ **(B)** `PostMessageW` 对"窗口线程已死"的目标**拒绝投递**（`return 0` ＋ `ERROR_INVALID_WINDOW_HANDLE`）。
#     **四档成对**：基线 `rc=139` → `fixed` 主队列 +0 → `fixed2` +1（静默改投）→ **`fixed3` 返回 0／+0／具名行**。
#     两极化（源级 ＋ 件级两层）：三源复原 ⇒ 件逐字节回 `a6365183fa6d26b9`、腿 `rc=139` 崩回来；放回 ⇒ 件独立复现 `2067cb1c97728791`。
#     W136A 报告（口径 `head -n -1` = `96dc6f442f95e449`）逐条见 BANNER。
#   **② 装置／判据件（本波收尾链内变更，主控逐条预授权）**
#     · `verify-all.sh` `4bcc0cf7aab10bb5` → **`80455e8d5eb92cb3`**（两处声明同趟改 `gen=#55`；**步数仍 27**；
#       `bash -n` rc=0；`VERIFYALL_SELF=PASS names=27 decl=27 gen=#55 dup=0 order=OK prose=OK prereg=PASS`）
#     · **新建** `docs/WAVE55-PREREGISTRATION.md`（`5c062a33a2b0eb17`）—— 见 BANNER 的 ② 与 `===RECORD===` 步骤⑦
#     · `build/MilBridge/known-red.json`（本波**重钉**）= `433d2d371787c004`（`#54` 冻结点 = `9a26c67a6f9fe1e4`；
#       本代开工现场 = `47554efd60b4554f`；`entries[*].caliber 改动字段数 = 0` ⇒ **只动世代记账，没碰任何判据口径**）
#     · **五臂重取**：`tline` `664a0c048a1ed3a1` → **`a46cb0b4e853fa1f`**（该日志含 app-local 同步行／耗时／日期戳）；
#       其余四臂 **`tab-zero 9150c3a26a3cb789`／`tab-anchor 1c43a12dcaa5718a`／`tab-rtl 92570318851ca7e8`／
#       `textlineproto 4bceceeed570ba70` 逐位不变**（**预测先写、事后命中**）。
#   **③ 九位（终态）与位移对账**
#     · `bridge` `4e25e4b27d4d5ae1`（5028208 B）｜`pc` `722e0ab8205b7c3f`（3601408 B）｜`pf` `f2df3c2b464b7f00`（6123520 B）｜`windowsbase` `2e4e46e539a72cd7`｜
#       `provider` `1f9511a7ef395bfe`｜`win32shim` `2067cb1c97728791`（327,672 B）｜`wic_shim` `f7b3026c8c019be2`｜
#       `hbtextline` `921ba9c65e9fb3be`（293165 B）｜`dwf` `ce3469f49efcbcfa`。
#     · ⚠️ **位移对账（相对 `#54` 冻结块那一栏）**：`win32shim` `a6365183fa6d26b9` → `2067cb1c97728791`（= **`TASK-0209`，产品位移**）；
#       `pf` `ec570d30f6754631` → `f2df3c2b464b7f00`（= **整波重建的非确定性**，`D-G92`）；其余七位 `bridge`／`pc`／`windowsbase`／
#       `provider`／`wic_shim`／`hbtextline`／`dwf` **逐位未变**（含 **`bridge` `4e25e4b27d4d5ae1` 不动** ——
#       本波产品改动全在 native shim，**桥源一行未改**：`BRIDGE_SRC_FP` `d697b1e10ff48881` 与 `#54` 冻结点 `d697b1e10ff48881` **逐位相同**）。
#     · 🔴 **`pf` 不是构建身份（`D-G92`，逐字）**：同源、同命令的两次重建可给出**不同字节**。
#       本波是**第六条连续证据**（`#50`/`#51`/`#52`/`#53`/`#54`/`#55`）：`#54` 冻结点 `pf` = `ec570d30f6754631`
#       （那是 `#54` 收尾链整波重建**之后**的值），本波收尾链整波重建后 → `f2df3c2b464b7f00`（**同尺寸 6123520 B**）。
#       **两刻并列见 `===RECORD===` 步骤③**；**两刻不同不算失败**（本代 `allow_changed={'win32shim', 'pf'}`、`pf_required=False`）。
#   **④ 判据/登记件**：`fp_inputs()` 覆盖面 **149** 件（与 `#54` 的覆盖面清单**逐行 IDENTICAL**）；
#     `inputs_fp` = `ca0a768162af87f88d8b84d777a66b769da8a74ea3e5ab273741f781c0e50e20`（`#54` 冻结点 = `5ba630999c60a746aca0ea582ba19324c535cfb4c89be2a6db36683209697365`；⚠️ 本代开工现场 = `1344571ddaafcf2f143fd3a8f06ee0c795c93df9ab53e9716a4d0c0ee4b70cca`，
#     **成因 = W136A 落仓时对 `known-red.json` 的自动重钉（`4e9c2dbe…`）与主控现算，都发生在本车道开工之前**）
#     ｜`bridge-src-fp` = `d697b1e10ff48881`（`#54` = `d697b1e10ff48881`，**逐位相同** —— 桥源零改动）。
#   **⑤ 零回归**：权威件导出 **547**｜`hbtextline` **逐位未变**（`build/shims/**` 零字节改动）｜
#     应用门禁 **×2 各 6/6 PASS**（`config=` 两本逐字相同）。

# ── 🦷 外挂声明行（**`#31` W31D 起的三类**；`column-floor-check.sh` 读者用 `^# COLUMN-FLOOR ` 等前缀锚定）
#   ⚠️ **血案留痕（同一个坑已踩两次：`#51` W110A、`#52` W126A）**：这些行**必须有 `# ` 前缀**，且**必须在冻结块里**。
#     `#51` 第 1 次冻结把 8 行写成**无 `# ` 前缀** ⇒ `COLUMN_FLOOR=NOINFO reason=frozen-block-has-no-COLUMN-FLOOR-line`；
#     `#52` 第 1 次冻结**一行都没写**（`w52-record.txt` 的 `===FROZEN===` 段缺它们）⇒ 同样失败。
#     两次都是**冻结器 `assert` 在写盘之后**失败 ⇒ 盘上已是半成品 ⇒ **重冻前必须先从备份逐字节还原**。
#     **本件（`#55`）在落盘之前先机械自检这 8 行齐全**（见 `~/w141a/bin/make-record-w55.py` 的末段断言）。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=a46cb0b4e853fa1f
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
# ── `#55` 收尾链记录（车道 **W141A**，2026-09-23 21:0x–21:xx +0800）──────────────────────────────
# 【本件与记录件的关系】本段由 `~/w141a/bin/make-record-w55.py` 生成（机械自检：三段标记齐全／
#   8 行外挂声明带 `# ` 前缀／无「连续两个 `@`」残留／占位符名合法）；**冻结完成后**冻后两趟与推送读数
#   按 `#51`/`#52`/`#54` 先例**只在末尾追加**（保真证明见本文件末的 `APPEND_ONLY_PROOF`）。
#
# ① 判据（**先写**，早于任何重活）：`~/w141a/criteria.md`（`97b2e9825040a061`，写定 2026-09-23 21:1x）。
#    本车道**不新发明判据**：波级判据先写于车道 **W136A** 的 `~/w136a/criteria.md`（`ea19ce8d7b008b0c`，17:14）。
#    本车道自己写的第一条 = **`C0` 空盘/可写预检**（本波新增入册的方法学），写在 `~/w141a/STATUS.md` 的 `[H0]`。
#
# ② 空盘/可写预检读数（判据 `C0`）——**每条重活趟之前**都做：
#    `df --output=avail /` ⇒ **77,799,724–77,808,952 KB ≈ 74.2–74.2 GiB**（判据 ≥ 5 GiB ⇒ 通过）
#    `printf x > /tmp/w141-$$.t && rm -f` ⇒ **TMP_WRITE=OK**；逐趟机读行 `PRECHECK=PASS df_avail_kb=… min_kb=5242880 tmp_write=OK`。
#    **本波零 `ENOSPC` 趟**（对比 `#54` 冻后第 2 趟的瞬时 `ENOSPC` ⇒ 三步 `rc=2 NOINFO` 被汇总计成 `❌`）。
#    ⚠️ 一条**如实记**：本车道第 1 次冻前 `verify-all` 是**前台**跑的，被本会话工具链的 600 s 上限
#    **SIGTERM 中断**（`timeout 1450 bash verify-all.sh` 当时仍在跑）⇒ 其输出管道已断、**读数不可用**
#    ⇒ 记「**作废（会话工具链中断，环境成因，非读数）**」，并按 PID 收掉残留（**未用 `pkill`**），
#    改为**后台重跑**（`--min-avail 1500 --max-hold 1500 --wait 1800 -- timeout 1450 bash verify-all.sh`）。
#
# ③ 整波 / 五臂 / 重钉 逐件 before→after：
#    · ① native：`build-shim.sh --all` ⇒ 产物 `bin/libwpfwin32.so` **前后都是 `2067cb1c97728791`**（327,672 B）
#      ⇒ **逐字节复现**；`== 导出符号总数：547`（**不变**）；ABI 段 `结果：全部一致` ✓
#      （⚠️ 一条**既有**告警如实记：`src/win32_misc.c:224 -Wmisleading-indentation`（`GetDpiForMonitor`），**不是本波落点**，未处置、只报）
#    · ① 整波：`WAVE_OWNER=W141A bash build/close-wave.sh --skip-verify-all` ⇒ **`CLOSEWAVE_RC=0`**
#      ｜`[1/6] rc=0`｜**`APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0`**｜**`=== 集成波结束：失败步骤 0 ===`**
#      ｜`[2/6]` native `源码不比权威件新 ⇒ 跳过重建`｜`[3/6]` 桥 `源指纹一致（d697b1e10ff48881 == d697b1e10ff48881）⇒ 无需重发`
#      ｜**`输入稳定性：波前==波后 == 1344571ddaafcf2f143fd3a8f06ee0c795c93df9ab53e9716a4d0c0ee4b70cca`**（波内零手写改动）
#    · ① 波后九位：`bridge=4e25e4b27d4d5ae1`｜`pc=722e0ab8205b7c3f`｜**`pf=f2df3c2b464b7f00`**（`ec570d30f6754631` → 变）｜`2e4e46e539a72cd7`｜`1f9511a7ef395bfe`｜
#      **`win32shim=2067cb1c97728791`**｜`f7b3026c8c019be2`｜`921ba9c65e9fb3be`｜`ce3469f49efcbcfa` ⇒ **`changed = {win32shim, pf}`**（集合口径），
#      **无第三位变**（**判据 `C1` 逐字命中**：`bridge` 仍 `4e25e4b27d4d5ae1`）。
#    · ② 五臂重取（`retake-arms-w23.sh`，`ARMS_OUT=$HOME/wfp-runs/arms23`）：
#      **预测（取数之前写定）= 只有 `tline` 会变**（依据：现场 `grep -c 'win32shim\|libwpfwin32' build/MilBridge/arm-logs/*.log`
#      = **0/0/0/0/0** ⇒ 五臂日志**都不含权威件 sha**）⇒ **实测命中**：
#      `tline 664a0c048a1ed3a1 → a46cb0b4e853fa1f`（**变**）；`tab-zero 9150c3a26a3cb789`／`tab-anchor 1c43a12dcaa5718a`／
#      `tab-rtl 92570318851ca7e8`／`textlineproto 4bceceeed570ba70`（**四臂逐位不变**）。
#      五臂**判词与 `#54` 冻结块逐字相同**：`tline 通过 22 / 失败 2`（rc=1）｜`tab-zero 退出码=1`（未登记失败 1/共 1）｜
#      `tab-anchor 退出码=0`（`START 红=0 绿=615 判定行=615`／`OVERFLOWED 红=0 绿=421 判定行=421`）｜
#      `tab-rtl 退出码=0`（`红=0 绿=0 判定行=0 NOINFO=163`）｜`textlineproto rc=0`。
#      `ARMS_DISPLAY=:97 source=reused`（**复用**，未自起、未碰任何人的 X）。
#      ⚠️ `ln -f` 造出 `nlink=2` ⇒ 按 **`TASK-0502` 波尾必做②** 把**别名侧** `~/wfp-runs/arms23/*.log`
#      改成**真副本**（`cp -p` ＋ `mv -f`）：五件 `nlink 2 → 1`、inode 互不相同、逐件 `cmp` = **IDENTICAL**，
#      **权威侧 `arm-logs/*.log` 五个 sha16 逐位未变**。
#      ⚠️ **`TASK-0502` 波尾必做①** = `sync-applocal-authority.sh --apply`（见 ⑩）。
#    · ③ 重钉世代：`repin-generation.py --check` 前 **`FAIL n=2`**（`generation.arm_logs.tline` 不一致 ＋
#      `evidence_log_sha256 声明=664a0c048a1ed3a1 现场=a46cb0b4e853fa1f`）⇒ `--why '<逐条理由>'` ⇒ **`APPLIED`**（rc=0）
#      ｜`instr_run_sh=711f39f468f61cc8`｜`instr_program_cs=149dd986a642fdfc`｜`instr_shim=921ba9c65e9fb3be`｜
#      **`evidence_log_sha256=a46cb0b4e853fa1f`**｜**`entries[*].caliber 改动字段数 = 0`** ⇒ `--check` 后 **`PASS`**（rc=0）
#      ｜件：`known-red.json 47554efd60b4554f → 433d2d371787c004`。
#      **`inputs_fp`（真函数现算，不复制函数体）**：`1344571ddaafcf2f143fd3a8f06ee0c795c93df9ab53e9716a4d0c0ee4b70cca`
#      → **`ca0a768162af87f88d8b84d777a66b769da8a74ea3e5ab273741f781c0e50e20`**；**归因（机械）**：覆盖面现场 = **149 件**、与 `#54` 清单**逐行 IDENTICAL**，
#      其中 **mtime 晚于整波开工（20:53:45）的件恰 1 件 = `build/MilBridge/known-red.json`** ⇒ 这一跳唯一可归因到重钉。
#
# ④ 门禁 ×2（两趟各写一本 rows）：
#    · 第 1 趟 `WPTD_DISPLAY=:213` ⇒ `== 启动自己的 Xvfb :213（1280x1024x24）`｜**`GATE1_OUTER_RC=0`**
#      ｜rows = `~/w141a/gate-rows.txt`（`d23f36b3b535d229`）
#    · 第 2 趟 `--no-build`，`WPTD_DISPLAY=:214` ⇒ `== 启动自己的 Xvfb :214（1280x1024x24）`｜**`GATE2_OUTER_RC=0`**
#      ｜rows = `~/w141a/gate-rows-f.txt`（`c68021075a54a9f9`）
#    · **两趟各 6 条 `BASELINE` 行／6 个 `result=PASS`／0 个 `result=FAIL`**（`default 3/3` ＋ `env 3/3`）
#      ⇒ **门禁本波 12/12 PASS**｜`WPTD_SUMMARY=PASS tiers_passed=2/2`｜`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`
#      ｜`WPTD_BRIDGE_SRC_STALE=no basis=pub=d697b1e10ff48881 now=d697b1e10ff48881 so_file_match=yes`
#    · 两本 `config=` 段**逐字相同**（`CONFIG_IDENTICAL`）：`pc:722e0ab8205b7c3f`／`bridge:4e25e4b27d4d5ae1`／`pf:f2df3c2b464b7f00`／
#      `provider:1f9511a7ef395bfe`／**`win32shim:2067cb1c97728791`**／`wic_shim:f7b3026c8c019be2`／`hbtextline_shim:921ba9c65e9fb3be(stale:no)`
#
# ⑤ 冻前 `verify-all`（**空盘预检通过后**跑；槽 `--min-avail 1500 --max-hold 1500 --wait 1800`）：
#    ⇒ 见后续追加段（`#54` 先例：**预期恰好 1 处声明类红 = `COLUMN-FLOOR`**、`用例通过 875`、
#    `X_STATE=available`、`[0]` 段 `X-REUSE=reused` 且几何 1280x1024）。
#
# ⑥ 冻结 `#55`：四颗牙（`BASELINESHA`／`BASELINEGEN decl_gen=#55`／`BASELINE_BYTES`／`BASELINEDUP n=0`）
#    ＋ `ARM-LOG-SHA`／`COLUMN-FLOOR` 冻后转绿两极化 —— 见后续追加段。
#
# ⑦ `inputs_fp()` 覆盖率与「输入稳定性」的关系（逐字口径，防误读）：
#    `verify-all.sh` 与 `docs/WAVE55-PREREGISTRATION.md` **都不在** `fp_inputs()` 覆盖面内
#    ⇒ 本波改它们**不动** `inputs_fp`；**动它的只有重钉 `known-red.json`**（见 ③）。
#
# ⑧ 写域守纪（**逐条**）：本车道**未改** `src/**` 之外的任何产品件；**未 add 任何他车道在办件**
#    （`~/w137a/**`（`#56` 仪器波预置件）、`~/wc05/**`、`~/wc07/**`、`~/wc08/**` 一律**只读**）；
#    **登记三件**（`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv`）
#    **登记归主控** ⇒ 本件**一件未碰**。推送一律**逐径 `git add`**（`D-G108`：绝不 `-A`／`--force`）。
#
# ⑨ 落盘纪律：一律 `temp ＋ rename`（`D-G101`：跨区硬链接）/ 本波改动的件**逐件 `cp -p` 备份**到 `~/w141a/backup/`；
#    **不许手抄哈希** —— 本记录与报告里所有 sha16 都**现场现算**（`make-record-w55.py` 逐条 `assert`）。
#
# ⑩ `TASK-0502` 两条波尾必做：① `sync-applocal-authority.sh --apply`（见后续追加段）；
#    ② 别名侧硬链接已断（`nlink 2 → 1`，见 ③ 五臂段）✓。
#
# ⑪ `NOINFO`（**波级，逐条；不猜**）：
#    1. **托管侧（.NET/WPF）对 `PostMessageW` 返回 0 的反应未验证**（W136A 零 `dotnet`，只到 native 层）⇒ `NOINFO`。
#    2. **`[POSTMSG_DEAD_TARGET]` 在真应用中的出现率未取到**（只在构造腿上 1 行）⇒ `NOINFO`。
#    3. **定时器那一半（`g_wpf.timers` 的 `owner_thread`）仍无读数**（静态改动，未造场景）⇒ `NOINFO`。
#    4. **`DeadThread` 场景（线程先死、窗口还活着）在真应用中的出现率未取到** ⇒ `NOINFO`。
#    5. **两样本（`W071`/`W077`）为何都在第 7 击 `nav2`**（时序耦合）⇒ `NOINFO`。
#    6. **`siaddr=0x0` 不作为判据**（与指令语义不符；`D-G109` 判词不依赖它）⇒ 该格 `NOINFO`。
#    7. **`THIRDPARTY frames=` 的逐趟差异不可归因**（`#54` 已记：四趟 41/42/43 本质可变，未定因）⇒ `NOINFO`。
#    8. **`APPSYNC` 的整体 `MISMATCH` 是"告警语义"**（`UNEXPECTED>0` 的在册缺口所致），本件只确认"**不因本波变多**"⇒ `NOINFO`。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:f2df3c2b464b7f00,provider:1f9511a7ef395bfe,win32shim:2067cb1c97728791,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w141a/gate-e
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:f2df3c2b464b7f00,provider:1f9511a7ef395bfe,win32shim:2067cb1c97728791,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w141a/gate-e
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:f2df3c2b464b7f00,provider:1f9511a7ef395bfe,win32shim:2067cb1c97728791,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w141a/gate-e
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:f2df3c2b464b7f00,provider:1f9511a7ef395bfe,win32shim:2067cb1c97728791,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w141a/gate-e
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:f2df3c2b464b7f00,provider:1f9511a7ef395bfe,win32shim:2067cb1c97728791,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w141a/gate-e
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:f2df3c2b464b7f00,provider:1f9511a7ef395bfe,win32shim:2067cb1c97728791,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w141a/gate-e
# ⏪ **（历史，已被 `#55` 取代）**# RE-FROZEN #54 —— ✅ **当前冻结基线** —— 内容 = 收掉 `#54` 这一波（收尾链 11 步由车道 **W139A** 一步到底）：
#   **① 产品侧：`TASK-0210`「桥侧几何重发／接管」（修 `D-G98` 族）**
#     落点：`src/WpfGfx.Linux/Interop/MilPresentation.cs`（`8b44b61f944aeeaa` → **`a5ecf1a8faaa2a00`**，
#     **唯一改动点 `:1086-1115`**：接既有窗（`OwnsWindow == false`）路径**只读尺寸、不写几何**，
#     自己建的窗分支**逐字保留**；另加一行无条件大声诊断 `[GEOWRITE-SUPPRESSED]`）
#     ⇒ **`bridge` 位变**：`feef049e9d0e313a` → **`4e25e4b27d4d5ae1`**（**尺寸不变 5028208 B**）。
#     W134A 报告（口径 `head -n -2` = `af7204d58eb0b681`）的**两条承重判据**逐字：
#     **① 协议层台账那条 `ConfigureWindow` 命中 `12/12` → `0/12`**；**② `xobs` 时间轴 `四跳` → `三跳`**（末态 `800x600`）。
#     ⚠️ **`Z3`（如实记）**：MIL 侧 `target.WindowRect` **不收敛**（修后仍恒 `1280x1024`）⇒ 本波**只解除它的破坏性作用**，
#     未修其成因（属 W134A 写域外）⇒ 该格 **`NOINFO`**；**本波与 `D-G98` 的因果按此排除**（处置的是桥侧那一次越权重发）。
#   **② 装置／判据件（本波收尾链内变更，主控逐条批准）**
#     · `verify-all.sh` `32ddbe487235cc38` → **`4bcc0cf7aab10bb5`**（两处声明同趟改 `gen=#54`；**步数仍 27**；
#       `bash -n` rc=0；`VERIFYALL_SELF=PASS names=27 decl=27 gen=#54 dup=0 order=OK prose=OK prereg=PASS`）
#     · **新建** `docs/WAVE54-PREREGISTRATION.md`（`d082ebd5086a4d3a`）—— 见 BANNER 的 ② 与 `===RECORD===` 步骤⑦
#     · `build/MilBridge/known-red.json`（本波**重钉**）= `9a26c67a6f9fe1e4`（`#53` = `f108775906eac9aa`；
#       `entries[*].caliber 改动字段数 = 0` ⇒ **只动世代记账，没碰任何判据口径**）
#     · **`samples/**/bin/**` 两份派生副本 ＋ `FallbackCriteria/bin/Debug` 一件**（最小真同步，主控授权）—— 见 BANNER 末段与 `===RECORD===` 步骤⑦′
#   **③ 九位（终态）与位移对账**
#     · `bridge` `4e25e4b27d4d5ae1`（5028208 B）｜`pc` `722e0ab8205b7c3f`（3601408 B）｜`pf` `ec570d30f6754631`（6123520 B）｜`windowsbase` `2e4e46e539a72cd7`｜
#       `provider` `1f9511a7ef395bfe`｜`win32shim` `a6365183fa6d26b9`（327,512 B）｜`wic_shim` `f7b3026c8c019be2`｜
#       `hbtextline` `921ba9c65e9fb3be`（293165 B）｜`dwf` `ce3469f49efcbcfa`。
#     · ⚠️ **位移对账（相对 `#53` 冻结块那一栏）**：`bridge` `feef049e9d0e313a` → `4e25e4b27d4d5ae1`（= **`TASK-0210`，产品位移**）；
#       `pf` `4973bcb28e331cf0` → `ec570d30f6754631`（= **整波重建的非确定性**，`D-G92`）；其余七位 `pc`／`windowsbase`／`provider`／
#       `win32shim`／`wic_shim`／`hbtextline`／`dwf` **逐位未变**（含 **`win32shim` `a6365183fa6d26b9` 不动**）。
#     · 🔴 **`pf` 不是构建身份（`D-G92`，逐字）**：同源、同命令的两次重建可给出**不同字节**。
#       本波是**第五条连续证据**（`#50`/`#51`/`#52`/`#53`/`#54`）：`#53` 冻结点 `pf` = `4973bcb28e331cf0`
#       （那是 `#53` 收尾链整波重建**之后**的值），本波收尾链整波重建后 → `ec570d30f6754631`（**同尺寸 6123520 B**）。
#       **两刻并列见 `===RECORD===` 步骤⑦**；**两刻不同不算失败**（本代 `allow_changed={'bridge', 'pf'}`、`pf_required=False`）。
#   **④ 判据/登记件**：`fp_inputs()` 覆盖面 **149** 件；`inputs_fp` = `5ba630999c60a746aca0ea582ba19324c535cfb4c89be2a6db36683209697365`（`#53` 冻结点 = `5ac1e5349c7d1dec56fd7d8fe5dd8e9c1cb7c3b4052859f887e45c539981904f`）
#     ｜`bridge-src-fp` = `d697b1e10ff48881`（`#53` = `0a8f69b3c5fabd43`，**本波变** —— 桥源改了 ⇒ 桥必须在 `IN_FP_0` **之前**已重发；现场 `[3/6]` 走"源指纹一致 ⇒ 无需重发"径）。
#   **⑤ 零回归**：`R_GATE=PASS crit=13/13`（`win32shim=a6365183fa6d26b9`）｜权威件导出 **547**｜
#     `hbtextline` **逐位未变**（`build/shims/**` 零字节改动）｜应用门禁 **×2 各 6/6 PASS**（`config=` 两本逐字相同）。

# ── 🦷 外挂声明行（**`#31` W31D 起的三类**；`column-floor-check.sh` 读者用 `^# COLUMN-FLOOR ` 等前缀锚定）
#   ⚠️ **血案留痕（同一个坑已踩两次：`#51` W110A、`#52` W126A）**：这些行**必须有 `# ` 前缀**，且**必须在冻结块里**。
#     `#51` 第 1 次冻结把 8 行写成**无 `# ` 前缀** ⇒ `COLUMN_FLOOR=NOINFO reason=frozen-block-has-no-COLUMN-FLOOR-line`；
#     `#52` 第 1 次冻结**一行都没写**（`w52-record.txt` 的 `===FROZEN===` 段缺它们）⇒ 同样失败。
#     两次都是**冻结器 `assert` 在写盘之后**失败 ⇒ 盘上已是半成品 ⇒ **重冻前必须先从备份逐字节还原**。
#     **本件（`#54`）在落盘之前先机械自检这 8 行齐全**（见 `~/w139a/bin/check-record-w54.py`）。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=664a0c048a1ed3a1
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【步骤①·native 复现 ＋ 整波重建】**一趟槽内做完**（先 `build-shim.sh --all` ⇒ 复现后再走 `close-wave.sh`）：
#     槽 `HEAVYSLOT=ACQUIRED waited=0s`／`MEMOK avail=5368MB`／**`RELEASED rc=0 held=167s`**（`max_hold=1200`）。
#     · `bash src/WpfGfx.Linux.Native/build-shim.sh --all` ⇒ 产物 `bin/libwpfwin32.so`（**327,512 B**）
#       **重建前后 sha16 都是 `a6365183fa6d26b9`** ⇒ **逐字节复现**；**`== 导出符号总数：547`（不变）**；
#       ABI 段 `结果：全部一致（编译期 _Static_assert 亦已通过）`。
#       ⚠️ 一条**既有**告警如实记：`src/win32_misc.c:224 -Wmisleading-indentation`（`GetDpiForMonitor`），**不是**本波落点 ⇒ 未处置、只报。
#     · `WAVE_OWNER=W139A bash build/close-wave.sh --skip-verify-all` ⇒ **`CLOSEWAVE_RC=0`**
#       ｜`OUT=/home/links-dev/wfp-runs/close-wave-174529`
#       ｜`[1/6] integration-wave.sh` **`rc=0`**｜**`APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0`**
#       ｜**`=== 集成波结束：失败步骤 0 ===`**
#       ｜`[2/6]` native `跳过重建`｜`[3/6]` 桥 `源指纹一致（d697b1e10ff48881 == d697b1e10ff48881）⇒ 无需重发`（W134A 已发）
#       ｜`[4/6]` 桥源指纹两侧一致 ✓／生成物指纹 `state=ok`（PC/WB/PF）✓／应用器审计 `miss=0` ✓
#       ｜**`输入稳定性：波前==波后 == 5ba630999c60a746aca0ea582ba19324c535cfb4c89be2a6db36683209697365（期间无手写改动）`**（⚠️ 与本代 `inputs_fp` **同值**：本波覆盖面在波内零手写改动）
#       ｜`[6/6]` 哨兵已更新（`/tmp/bridge-frozen.flag` ＋ 镜像 `~/wfp-runs/bridge-frozen.flag`，`cmp` IDENTICAL）。
#     · 波后九位（`close-wave-summary.txt` 现读）：`bridge=4e25e4b27d4d5ae1`｜`pc=722e0ab8205b7c3f`｜**`pf=ec570d30f6754631`**｜`windowsbase=2e4e46e539a72cd7`｜
#       `provider=1f9511a7ef395bfe`｜**`win32shim=a6365183fa6d26b9`**｜`wic_shim=f7b3026c8c019be2`｜`hbtextline_shim=921ba9c65e9fb3be`｜`dwf=ce3469f49efcbcfa`
#       ⇒ **`changed = {bridge, pf}`**，**逐字命中判据 C1**（其余七位逐位未变）。
#   【步骤②·native 副本一致性】整波 `[2/6]` 走"源码不比权威件新 ⇒ 跳过重建"径；**权威件 sha16 = `a6365183fa6d26b9`（327,512 B）**，
#     与步骤①重编前**逐位相同** ⇒ **本波零 shim 位移**（`#53` 的 `TASK-0109` 制品未被扰动）。
#   【步骤③·WIC 权威件同步（`sync-applocal-authority.sh`）】见步骤⑩（同一件，收尾那一趟一并跑）。
#   【步骤④·五臂重取】**预测先写**（`$HOME/w139a/criteria.md` §C4，写定 17:44，早于取数）：只有 `tline` **可能**变
#     （该日志含 app-local 同步行／耗时／被同步权威件 sha／自指 artifact／日期戳文件名 ⇒ 程序上不可复算），其余四臂应为**逐位不变**。
#     槽 `HEAVYSLOT=ACQUIRED waited=0s`／`MEMOK avail=4974MB`／**`RELEASED rc=0 held=319s`**（`max_hold=1200`）。
#     `ARMS_DISPLAY=:97 source=none ⇒ 自起 Xvfb`（`xvfb_pid=1261094`，`1280x1024x24`；**跑完按 PID 自收**，脚本 `trap`）｜
#     取臂前自证：`shim=921ba9c65e9fb3be`｜`pc=722e0ab8205b7c3f`｜`run.sh=711f39f468f61cc8`｜`Parity.cs=149dd986a642fdfc`。
#     | 臂 | `#53` 冻结点 | 本波 | 变? | 判词（`#53` → 本波） | rc |
#     |---|---|---|---|---|---|
#     | `tline` | `44c21d648f79126c` | **`664a0c048a1ed3a1`** | **变**（**预测命中**） | `通过 22 / 失败 2` → **逐字相同** | 1 |
#     | `tab-zero` | `9150c3a26a3cb789` | `9150c3a26a3cb789` | 未变（预测命中） | `退出码=1`（未登记失败 1/共 1，唯一 = `notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白 期望=0 实得=1`） | 1 |
#     | `tab-anchor` | `1c43a12dcaa5718a` | `1c43a12dcaa5718a` | 未变（预测命中） | `退出码=0`（`START 红=0 绿=615 判定行=615`／`OVERFLOWED 红=0 绿=421 判定行=421`／`字形释放行=194`） | 0 |
#     | `tab-rtl` | `92570318851ca7e8` | `92570318851ca7e8` | 未变（预测命中） | `退出码=0`（`红=0`；`缺字形` 例仍在 `NOINFO`） | 0 |
#     | `textlineproto` | `4bceceeed570ba70` | `4bceceeed570ba70` | 未变（预测命中） | `通过 10 / 失败 0` → **逐字相同** | 0 |
#     ⇒ **只有 `tline` 变**、**五臂判词与 `#53` 逐字相同** ⇒ 判据 C4 命中、**不停手**。
#     ⚠️ 机制留痕：重取脚本末尾用 **`ln -f`** 硬链进 `arm-logs/`（逐行印 `(links=2)`）—— **仓内既定机制**
#     （`fp_inputs()` 注释写明"重取用 `ln -f`"，且因此**刻意不把 `arm-logs/` 纳入覆盖面**），**不是**本车道沙箱的污染。
#     **`TASK-0502` 波尾必做②（本次顺带办掉）**：把**别名侧** `~/wfp-runs/arms23/*.log` 改成**真副本**
#     （`cp -p` 同目录临时名 ＋ `mv -f`；**只动 `~/wfp-runs/arms23/**`**）：六件 `nlink 2 → 1`、inode 互不相同、
#     逐件 `cmp` = **IDENTICAL**，**权威侧 `arm-logs/*.log` 五个 sha16 逐位未变**（= 上表本波列）。
#   【步骤⑤·重钉世代】
#     `--check` **前**：**`REPIN_GENERATION=FAIL n=2`**（`generation.arm_logs.tline 不一致`；
#       `evidence_log_sha256 声明=44c21d648f79126c 现场=664a0c048a1ed3a1`）rc=1 ⇒ **这是"顺序"不是"矛盾"**。
#     `--why '<五条理由>'`（① 产品位移 `bridge`＝`TASK-0210`；② 环成员 `pf` 整波重建自变（`D-G92`）；
#       ③ 波尾重取只有 `tline` 变、五臂判词与 `#53` 逐字相同；④ 仪器侧零接线（世代三项现场逐位不变）；
#       ⑤ 两件判据/文档域变更都在 `fp_inputs()` 覆盖面外）⇒ **`REPIN_GENERATION=APPLIED`**（rc=0）：
#       `instr_run_sh=711f39f468f61cc8`｜`instr_program_cs=149dd986a642fdfc`｜`instr_shim=921ba9c65e9fb3be`｜
#       **`evidence_log_sha256=664a0c048a1ed3a1`**｜**`entries[*].caliber 改动字段数 = 0`**（**只动世代记账，没碰任何判据口径**）。
#     `--check` **后**：**`REPIN_GENERATION=PASS（世代三项 + 五臂 + 证据日志 + 4 条 entries 的 caliber 全部一致）`** ✓（rc=0）。
#     件：`build/MilBridge/known-red.json` **`f108775906eac9aa` → `9a26c67a6f9fe1e4`**。
#     **`inputs_fp`（真函数现算，不复制函数体）**：`5ac1e5349c7d1dec56fd7d8fe5dd8e9c1cb7c3b4052859f887e45c539981904f` → **`5ba630999c60a746aca0ea582ba19324c535cfb4c89be2a6db36683209697365`**（**归因：`known-red.json` 在覆盖面内**）。
#   【步骤⑥·应用门禁 ×2】两趟**各写一本 rows**（写同一本会变 12 行 ⇒ 冻结器断言 6 行会红）；
#     槽 `HEAVYSLOT=ACQUIRED waited=0s`／`MEMOK avail=…`／**`RELEASED rc=0 held=…`**（`max_hold=800`）。
#     第 1 趟（`17:55:5x`）：`WPTD_DISPLAY=:213` ⇒ **`== 启动自己的 Xvfb :213（1280x1024x24）`**（PID 1261972）｜**`GATE1_OUTER_RC=0`**；
#     第 2 趟（`--no-build`）：`WPTD_DISPLAY=:214` ⇒ **`== 启动自己的 Xvfb :214（1280x1024x24）`**（PID 1277874）｜**`GATE2_OUTER_RC=0`**。
#     **两趟各 6 条 `BASELINE` 行、6 个 `result=PASS`、0 个 `result=FAIL`**（`default 3/3` ＋ `env 3/3`）⇒ **门禁本波 12/12 PASS**；
#     `WPTD_SUMMARY=PASS tiers_passed=2/2`｜`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`｜
#     `WPTD_BRIDGE_SRC_STALE=no basis=pub=d697b1e10ff48881 now=d697b1e10ff48881 so_file_match=yes`。
#     两本 `config=` 段**逐字相同**（`diff` 空 ⇒ `CONFIG_IDENTICAL`）=
#     `pc:722e0ab8205b7c3f`／**`bridge:4e25e4b27d4d5ae1`**／**`pf:ec570d30f6754631`**／`provider:1f9511a7ef395bfe`／**`win32shim:a6365183fa6d26b9`**／
#     `wic_shim:f7b3026c8c019be2`／`hbtextline_shim:921ba9c65e9fb3be(stale:no)`。
#     ⚠️ 两趟**各自自起** `1280x1024x24`（**只用空闲 `:2xx`**，不依赖别人的 X、也没杀任何人的 X）；收工时 `/tmp/.X11-unix/` 里两个 socket 都已不在 ⇒ **零残留**。
#   【步骤⑦·冻前 `verify-all`（27 步）】
#     ⚠️ **第 1 趟（`18:00`）出现第 2 处非声明类红 ⇒ 触发判据 C7 硬停条件②，本车道当场停手报主控**（读数逐字保留在 `~/w139a/logs/09-verify-pre.log`）：
#       `步骤通过 25 ❌ 失败 2`／`用例通过 799 跳过 2`／`结论：❌ 失败项：ManagedLayer.Tests COLUMN-FLOOR`。
#       根因 = **桥换代使 `samples/**/bin/**` 的两份派生副本当场陈旧**（`feef049e9d0e313a`，mtime 2026-09-21）
#       ⇒ `ManagedLayer.DP1ReproTests.闸门_win32shim被测件与权威件同sha`（`DP1ReproTests.cs:129` 的
#       `CheckBridgeCopies():168-206` **枚举 `samples/**` 下全部 `wpfgfx_cor3.so`** 并要求逐份 == 权威）
#       **必红**；**不是本车道引入、也不是产品回归**（`#53` 时两份与当时权威同 sha ⇒ 该套件 76/0 绿）。
#   【步骤⑦′·最小真同步（主控 2026-09-23 18:1x **显式授权**；`#46` 先例 `build/MilBridge/W46H2-report.md` §1.3）】
#     **只同步"派生副本"**（逐件理由：`check-applocal-sync.sh` 的 `ITEMS` 权威表 ＋ `BRIDGE-ANCHOR` 的发布记录锚）：
#     | # | 件 | 权威 | before → after | 是否派生副本 |
#     |---|---|---|---|---|
#     | 1 | `samples/WpfFeatureProbe/bin/Release/net10.0/wpfgfx_cor3.so` | 发布件（`BRIDGE_SO_SHA256`，唯一写点 `publish-milbridge.sh:81`） | `feef049e9d0e313a` → **`4e25e4b27d4d5ae1`** | **是**（同一二进制的派生副本） |
#     | 2 | `samples/ThirdPartyMini/bin/Debug/net10.0/wpfgfx_cor3.so` | 同上 | `feef049e9d0e313a` → **`4e25e4b27d4d5ae1`** | **是**（`run-thirdparty-mini.sh:147` 自己就 `deploy "$MIL" wpfgfx_cor3.so`） |
#     | 3 | `build/DirectWrite.Linux/FallbackCriteria/bin/Debug/WpfGfx.Linux.dll` | `src/WpfGfx.Linux/bin/$SELFBUILT_CONFIG/net10.0/WpfGfx.Linux.dll`（`ITEMS` 权威项） | `374b5a538ea955aa` → **`05433f1ee7e4092b`** | **是**（`#53` 时 `sha == 权威` ⇒ 计 `DECL-GAP-EQ`） |
#     **明确"不同步"的件（给理由）**：`build/DirectWrite.Linux/FallbackCriteria/bin/Debug/PresentationCore.dll`
#     （`9465f9dce39e2dfc`，4,068,864 B）——**在册**于 `known-red-PC-copies.md`（处置列逐字："**另一份 PC 构建**，
#     4,068,864 B，**非"旧版同一件"**"），且**没有出现在任何 `DIVERGENT`／`BRIDGE-ANCHOR` 点名里** ⇒ 不碰。
#     **读数**：先备份（`~/w139a/backup/samples-bridge-copies/` 三件 `cp -p`）⇒ 断言权威值（桥 `4e25e4b27d4d5ae1`／MIL `05433f1ee7e4092b`）
#     ⇒ 覆盖 ⇒ **全仓（除 `upstream/**`）恰 4 份桥件、去重值 = 1 个 = `4e25e4b27d4d5ae1`**；
#     `check-applocal-sync.sh` 前后对照：前 `DIVERGENT=2`／`BRIDGE-ANCHOR=2`／`UNEXPECTED=6[DECL-GAP-EQ=5 DECL-GAP-DIFF=1]`
#     ⇒ 后 **`DIVERGENT=0`／`BRIDGE-ANCHOR=0`／`UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0]`**（= `#53` 逐字同形，**在册缺口如实保留未洗**），
#     `MISMATCH=0[STALE=0 NEWER-DIFF=0]`／`MISSING=0`／`RETIRED=0`／`AUTH-MISSING=0` **四项仍全 0**，`ANCHOR-OK ×4`；
#     **`inputs_fp` 同步前后逐位相同 = `5ba630999c60a746aca0ea582ba19324c535cfb4c89be2a6db36683209697365`**；三件**均 untracked**（`git check-ignore` = `.gitignore:19:**/bin/`）、
#     **覆盖面 149 件里 `grep -cF` 逐件 = 0**；**未碰**任何 `*.xaml`／`*.cs`／`*.csproj`。
#   【步骤⑦″·冻前 `verify-all` 重跑】槽 `HEAVYSLOT=ACQUIRED waited=0s`／`MEMOK avail=5155MB`／**`RELEASED rc=0 held=…`**（`max_hold=1500`）；
#     `[0]` 段逐字：`✅ X-REUSE=reused display=:99（:99 上已有可用 X server，几何 1280x1024 相符而复用）`／
#     `X_STATE=available（判据：xdpyinfo 对 DISPLAY=:99 成功 ⇒ available）` ⇒ **几何守卫按设计工作**（`D-G105`）。
#     **结论行逐字**：**`步骤通过 26 ❌ 失败 1`**｜**`用例通过 875 跳过 2`**｜
#     `SKIP_GUARD=PASS x_state=available x_died=0 x_suite_skipped=0 x_suite_units=0 x_suite_corpus_max=0 total_skipped=2 violations=none reason=none`｜
#     **`结论：❌ 失败项：COLUMN-FLOOR`** ⇒ **恰好 1 处红、且就是设计内的声明类红** ⇒ **判据 C7 逐字命中**。
#     逐套件：`Commands 562/0`／`Rendering 166/2`／`Windowing 44/0`／`HelloMil 19/0`／**`ManagedLayer 76/0`**／`Presentation 8/0`
#     ⇒ `562+166+44+19+76+8 = 875`（**与 `#53` 逐格相同**）。
#     唯一那 1 处红（逐字母句）：`COLUMN-FLOOR ❌ (rc=1)`／`COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline`／
#     `COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0 selfreport=PASS reg=9a26c67a6f9fe1e4 base=a2e49b786d0a1b02 corpus=0cebc0afd5142fbf`
#     ⇒ **`COLUMN_FLOOR_ARMLOG=FAIL` ∧ `selfreport=PASS` = 冻结器 `_is_declaration_class()` 认的形态** ✓。
#     其余 26 步**全绿**，关键机读行：`VERIFYALL_SELF=PASS names=27 decl=27 gen=#54 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=4bcc0cf7aab10bb5`｜
#     `ARMLOG_SHA=PASS required=5 declared=5 pass=5 fail=0 noinfo=0`｜`DEFREG=PASS declared=147 route_ids=147`｜
#     `FP_INPUTS_HYGIENE=PASS coverage_n=149 artifact_n=0`｜`BUILD-HYGIENE … files=41 undeclared=0`｜
#     `HIDDEN_ONLY_STEP=PASS 判定例=32/32`｜`PRODUCT_ENTRY_STEP=PASS 判定例=8/8 在册已知红 5/5`｜
#     `SHELL_QUOTE_TRAP=PASS traps=0 files=157`｜`FRAMEPRESENCE=PASS frames=80 max_colors=4113`｜
#     `PIPEFAIL_SIGPIPE=PASS undeclared_hit=0`｜`THIRDPARTY=PASS frames=41 max_colors=1642`｜
#     `NULBYTES=PASS files=1228 hits=0 bytes=252792235 canary=ok`｜**`R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938 mem_mb=… win32shim=a6365183fa6d26b9 pc=722e0ab8205b7c3f src=device`**。
#     ⇒ **无第 2 处非声明类红 ⇒ 停条件② 未触发（已解除）**。
#   【步骤⑧·冻结 `#54`】见 `===FROZEN===` 段与下方 ③ ④；冻结器 = `$HOME/w21-verify/w27-freeze.py`
#     （本车道的 `GENS['#54']` 条目：`PRE=/home/links-dev/w139a/w54-pre.sha`（`0fc196e2ee4d04da`，9 行）／`prev='#53'`／
#     `allow_changed={'bridge','pf'}`／`pf_required=False`／`bs_fp=d697b1e10ff48881`／`infp='5ba630999c60a746aca0ea582ba19324c535cfb4c89be2a6db36683209697365'`）。
#     ⚠️ **`PRE` 快照的来源如实记**（口径与 `#50`–`#53` 逐条同形）：本波产品位移（`TASK-0210` ⇒ `bridge`）
#     在本车道开工**之前**就由波内车道 W134A 落定 ⇒ 现场**已不存在**"改前值" ⇒ `PRE` 按 **`#53` 冻结块**九位
#     **逐位重建**（生成脚本 `~/w139a/bin/make-pre54.py` 机械核过"9 个值都逐字出现在 `#53` 块里"
#     ＋ 与 `w53-record.txt` 交叉核 ＋"现场九位里**只有 `bridge` 已 ≠ `#53` 冻结点`"的一致性断言）。
#     冻结块**只追加**；`#53` 块降级为 `# ⏪ **（历史，已被 `#54` 取代）**`。
#   【步骤⑨·冻后 `verify-all` ×2】两趟都预期 `步骤通过 27 ❌ 失败 0`／`结论：✅ 全部通过`／`用例通过 875 跳过 2`；
#     **两趟之间不许换件**（第 `[26]` 步 `R-GATE` 会读 `win32shim=`）。逐条读数与"判词层机读行两趟逐字相同"的对照见报告 §⑥。
#   【步骤⑩·收尾记录 ＋ 推送 ＋ app-local】见 ⑤ ⑥。
#
#   ① **表外位移**（判据 C1）：**未触发** —— `changed` 恰好 = `{bridge, pf}`，
#      两者都在 `GENS['#54']['allow_changed']` 里；**`win32shim` 逐位未变**（`a6365183fa6d26b9`）、**导出仍 547**。
#   ② **native 复现不出 `a6365183fa6d26b9`**（判据 C3）：**未触发** —— 重建前后 sha16 **都是 `a6365183fa6d26b9`**（327,512 B）。
#   ③ **五臂判词与 `#53` 不一致**（判据 C4）：**未触发** —— 五臂判词逐字相同（见步骤④表）。
#   ④ **冻前 `verify-all` 出现第 2 处非声明类红**（判据 C7 硬停条件②）：**触发过一次并如实停手** ——
#      根因 = `samples/**/bin/**` 两份**派生副本**陈旧（**产品件换代的机械后果**，不是回归）；
#      处置 = 主控授权的最小真同步（步骤⑦′）⇒ 重跑后 **`26 ✅ / 1 ❌（只 `COLUMN-FLOOR`）`、`用例通过 875`** ⇒ 解除。
#   ⑤ **`hbtextline` 变了**：**未触发** —— `921ba9c65e9fb3be` 从波前到冻前**逐位未变**（`build/shims/**` 零字节改动）。
#   ⑥ 附加自守（不是任务书的停条件，但我自己也停）：**导出数变化**（547 → 别的）／**`R_GATE` 不再是 `crit=13/13`** —— 都未触发。
#
#   ⚠️ **`NOINFO` 逐条（不猜）**：
#   ① **MIL 侧 `target.WindowRect` 不收敛**（`Z3`）：修后仍恒 `1280x1024`；本波只解除其破坏性作用，未修成因（属 W134A 写域外）。
#   ② **`pf` 的非确定性根因仍未抓到**（`D-G92`，`NOINFO`）：本波又添一条成对读数（`4973bcb28e331cf0` → `ec570d30f6754631`，**同尺寸 6123520 B**）。
#   ③ **`tline` 臂日志的 sha 变化不可归因**（`NOINFO`）：该日志内含 app-local 同步行／耗时／被同步权威件 sha／
#      自指 artifact／日期戳文件名 ⇒ **程序上不可复算**；判据只能是**判词**（本波 = `通过 22 / 失败 2`）。
#   ④ **`UNEXPECTED=6[DECL-GAP-EQ=6]` 未逐条归因**（`NOINFO`）：`#49` 已认定为**在册**声明类缺口；本件只确认"**不因本波变多**"。
#   ⑤ **`upstream/**`（6417 件）未测**（`NUL-BYTES` 步的 `NOINFO` 格）：该步 `PASS` **只等于「声明覆盖面里 0 件含 NUL」**。
#   ⑥ **`D-G83`（`WM_GETMINMAXINFO` 四格）本波未重跑**（`NOINFO`）：装置在别的车道的 `~/w89a/bin/**`（≈30 min，重活）。
#   ⑦ **真应用"拖动窗口"未被本波重测**（`NOINFO`）：`TASK-0210` 的产品侧验收由 W134A 的深仪器负责（旧 12/12 红 → 新 0/12 红）。
#   ⑧ **`System.Printing.dll` 的 `bin`/权威不一致未归因**（`NOINFO`）：`#52`/`#53` 同一行**逐字相同**，不在九位里、不参与判据。
#   ⑨ **`verify-all.sh` 的 `[26]` 步 `mem_mb` 等运行期读数逐趟不同**：不是判据，只如实记。
#   ⑩ **两份 `samples/**/bin/**` 派生副本"为什么不被任何声明链刷新"未归因到设计意图**（`NOINFO`）：
#      整波 app-local 刷新**显式拒绝**（`WARN … 不由权威锚定 ⇒ 不盲拷，交给它自己的构建链`），
#      而两个 `*.csproj` 都没有 `wpfgfx_cor3.so` 的 Copy 项 ⇒ **每波产品换代都会重现这一格**（**建议**见报告 §⑫）。
#
#   🔖 **哨兵两处**：`/tmp/bridge-frozen.flag`（唯一写者 = `build/close-wave.sh:387-412`）＋
#     镜像 `~/wfp-runs/bridge-frozen.flag` ⇒ `cmp` **IDENTICAL**；`SHA=4e25e4b27d4d5ae1`／`WIN32SHIM=a6365183fa6d26b9`／`WAVE=close-wave-174529`。
#   📤 **推送（逐径）**：见报告 §⑦（`git status --porcelain` 逐件计数对账 ＋ 逐径 `git add`（**绝不** `-A`／`--force`，
#     `D-G108` 事故族）＋ push 后**重新 `fetch`**（refspec：默认跟踪 ref 不更新 ⇒ 假 MISMATCH）＋
#     `ls-remote --symref origin HEAD` ＋ 逐件 `git cat-file blob origin/feat-Linux:<path>` 字节核对）⇒
#     读数 = `BYTECHECK ok=… mismatch=0 nobody=0`；**最终 head 以现场 `ls-remote` 读数为准**（本报告自己那一笔会让 head 再前进）。
#   ♻️ **本车道的回滚姿势（供后人）**：`verify-all.sh` 的声明改动可由 `~/w139a/bin/patch-verifyall-w54.py --revert`
#     逐字节还原；`w27-freeze.py` 的 `GENS['#54']` 只追加（备份 `~/w139a/backup/w27-freeze.py.before-w139a`）；
#     三件最小真同步前的原件在 `~/w139a/backup/samples-bridge-copies/`；
#     冻结前的两件（`ACCEPTANCE-BASELINE.md`／`docs/CURRENT-STATE.md`）在 `~/w139a/backup/*.before-w139a`。
#
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ec570d30f6754631,provider:1f9511a7ef395bfe,win32shim:a6365183fa6d26b9,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w139a/gate-e
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ec570d30f6754631,provider:1f9511a7ef395bfe,win32shim:a6365183fa6d26b9,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w139a/gate-e
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ec570d30f6754631,provider:1f9511a7ef395bfe,win32shim:a6365183fa6d26b9,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w139a/gate-e
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ec570d30f6754631,provider:1f9511a7ef395bfe,win32shim:a6365183fa6d26b9,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w139a/gate-e
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ec570d30f6754631,provider:1f9511a7ef395bfe,win32shim:a6365183fa6d26b9,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w139a/gate-e
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:4e25e4b27d4d5ae1,pf:ec570d30f6754631,provider:1f9511a7ef395bfe,win32shim:a6365183fa6d26b9,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w139a/gate-e
# ⏪ **（历史，已被 `#54` 取代）**# RE-FROZEN #53 —— ✅ **当前冻结基线** —— 内容 = 收掉 `#53` 这一波（收尾链 11 步由车道 **W133A** 一步到底）：
#   **① 产品侧：`TASK-0109`「WM 已死但 EWMH 属性残留 ⇒ 静默丢一次移动」**（与 `D-G81` 同族）
#     落点：`src/WpfGfx.Linux.Native/src/win32_x11.c`（`9fa20864404ab01b`）
#     ＋ `src/WpfGfx.Linux.Native/src/win32_core.c`（`a9cc8762908b417a`）
#     ＋ `win32_internal.h`（`4e1880e6054635ff`，只改声明注释）⇒ **`win32shim` 位变**：
#     `bd037229be8db4f6` → **`a6365183fa6d26b9`**；`bash src/WpfGfx.Linux.Native/build-shim.sh --all` 复核
#     **导出符号 547 不变**（`nm -D --defined-only`），ABI 布局段全部一致。
#     ⚠️ **它同时救了两处**：`win32_core.c:653` 的**窗态最大/还原**（`:655 return` 后永远等不到
#     `ConfigureNotify`）—— 那一半**今天还没有缺陷号**（W131A 只取读数、未登记）。
#     ⚠️ **修法排除项（W131A 实测，供后人省一趟）**：`XSendEvent` 的返回值在活/死/无 WM **三相都 = 1**
#     ⇒ "接返回值再兜底"**不可行**；查 `_NET_SUPPORTED` 非空**不可行**（WM 死后仍在，`n=78`）；
#     四个候选 liveness API 在**已销毁窗**上、**不装 X 错误处理器时全部 `exit(1)`**（比原来更糟）
#     ⇒ 必须"临时 `XSetErrorHandler` ＋ 换回之前 `XSync`"。
#   **② 装置／判据件（本波收尾链内变更，主控逐条批准）**
#     · `verify-all.sh` `0cdd12547a634b37` → **`32ddbe487235cc38`**（四处声明同趟改 `gen=#53`；**步数仍 27**；
#       `bash -n` rc=0；`VERIFYALL_SELF=PASS names=27 decl=27 gen=#53 dup=0 order=OK prose=OK prereg=PASS`）
#     · **新建** `docs/WAVE53-PREREGISTRATION.md`（`b5ecd5433a57af47`）—— 见 BANNER 的 ② 与 `===RECORD===` ①
#     · `build/MilBridge/known-red.json`（本波**重钉**）= `f108775906eac9aa`（`#52` = `d4e0080df6ec497c`）
#   **③ 九位（终态）与位移对账**
#     · `bridge` `feef049e9d0e313a`（5028208 B）｜`pc` `722e0ab8205b7c3f`（3601408 B）｜`pf` `4973bcb28e331cf0`（6123520 B）｜`windowsbase` `2e4e46e539a72cd7`｜
#       `provider` `1f9511a7ef395bfe`｜`win32shim` `a6365183fa6d26b9`（327,512 B）｜`wic_shim` `f7b3026c8c019be2`｜
#       `hbtextline` `921ba9c65e9fb3be`（293165 B）｜`dwf` `ce3469f49efcbcfa`。
#     · ⚠️ **位移对账（相对 `#52` 冻结块那一栏）**：`win32shim` `bd037229be8db4f6` → `a6365183fa6d26b9`（= `TASK-0109`）；
#       `pf` `358136b0c806ee88` → `4973bcb28e331cf0`（= **整波重建的非确定性**，`D-G92`）；其余七位 `bridge`／`pc`／
#       `windowsbase`／`provider`／`wic_shim`／`hbtextline`／`dwf` **逐位未变**。
#     · 🔴 **`pf` 不是构建身份（`D-G92`，逐字）**：同源、同命令的两次重建可给出**不同字节**。
#       本波是**第四条连续证据**（`#50`/`#51`/`#52`/`#53`）：`#52` 冻结点 `pf` = `358136b0c806ee88`
#       （那是 `#52` 收尾链整波重建**之后**的值），本波收尾链整波重建后 → `4973bcb28e331cf0`（**同尺寸 6123520 B**）。
#       **两刻并列见 `===RECORD===` ②**；**两刻不同不算失败**（本代 `allow_changed={win32shim, pf}`、`pf_required=False`）。
#   **④ 判据/登记件**：`fp_inputs()` 覆盖面 **149** 件；`inputs_fp` = `5ac1e5349c7d1dec56fd7d8fe5dd8e9c1cb7c3b4052859f887e45c539981904f`（`#52` 冻结点 = `84fd55d384e93203317d22601cec854d518e69c8f026006231302a2cfbc93366`）
#     ｜`bridge-src-fp` = `0a8f69b3c5fabd43`（`#52` = `0a8f69b3c5fabd43`，**本波未变** ⇒ 桥不必重发）。
#   **⑤ 零回归**：`R_GATE=PASS crit=13/13`（`win32shim=a6365183fa6d26b9`）｜权威件导出 **547**｜
#     `hbtextline` **逐位未变**（`build/shims/**` 零字节改动）｜`nproc=3`。

# ── 🦷 外挂声明行（**`#31` W31D 起的三类**；`column-floor-check.sh` 读者用 `^# COLUMN-FLOOR ` 等前缀锚定）
#   ⚠️ **血案留痕（同一个坑已踩两次：`#51` W110A、`#52` W126A）**：这些行**必须有 `# ` 前缀**，且**必须在冻结块里**。
#     `#51` 第 1 次冻结把 8 行写成**无 `# ` 前缀** ⇒ `COLUMN_FLOOR=NOINFO reason=frozen-block-has-no-COLUMN-FLOOR-line`；
#     `#52` 第 1 次冻结**一行都没写**（`w52-record.txt` 的 `===FROZEN===` 段缺它们）⇒ 同样失败。
#     两次都是**冻结器 `assert` 在写盘之后**失败 ⇒ 盘上已是半成品 ⇒ **重冻前必须先从备份逐字节还原**。
#     **本件（`#53`）在落盘之前先机械自检这 8 行齐全**（见 `~/w133a/bin/check-record.sh`）。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=44c21d648f79126c
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
# ── ① 本波改了什么（逐件 sha16，改前 → 改后）────────────────────────────────────
#   **产品件**（值进九位；改前 = `#52` 冻结块那一栏）：
#     · `src/WpfGfx.Linux.Native/src/win32_x11.c` `11142fbef049eb66` → `9fa20864404ab01b`
#       ＋ `win32_core.c` `3117923a7c899e05` → `a9cc8762908b417a`
#       ＋ `win32_internal.h` `e4f2de8d038e4780` → `4e1880e6054635ff`（**只改声明注释**）
#       （**`TASK-0109`**，落地车道 = **W131A**，2026-09-23 11:49）
#       ⇒ `win32shim` `bd037229be8db4f6` → **`a6365183fa6d26b9`**（**导出 547 不变**；`build-shim.sh --all` rc=0）
#   **判据/文档件（本波收尾链内变更，主控 2026-09-23 12:1x 逐条批准）**：
#     · `verify-all.sh` `0cdd12547a634b37` → **`32ddbe487235cc38`**：四处声明同趟改 `gen=#52` → `gen=#53`
#       （**DECL 顶行 ＋ 头注释口径句各加一行；步名/步数一字不动，仍 27 步**）；
#       `bash -n` rc=0；`VERIFYALL_SELF=PASS names=27 decl=27 gen=#53 dup=0 order=OK prose=OK prereg=PASS`。
#       ⚠️ **该件不在 `fp_inputs()` 覆盖面内** ⇒ 改它**不动 `inputs_fp`**（改前/改后两次现算**同值** `f0e2b3e8…`，见 ②）。
#       ⚠️ **依据更正（如实记）**：主控 12:1x 把「`w27-freeze.py:454` 断言」那条标成 `NOINFO（不可核）`，
#         理由是「`find $R -name '*freeze*.py'` ⇒ **0 命中**」。**那条搜索只覆盖了 `$R`**；冻结器**历来不在仓内**，
#         它的实在位置 = `$HOME/w21-verify/w27-freeze.py`（sha16 `101db5306e1669fe`，`#50`–`#52` 历代同此）。
#         我**现场读过** `:454`：`assert re.search(r'\*\*`' + re.escape(gen) + r'` 收官起 = ' + str(nstep) + r' 步\*\*', vh)`。
#         ⇒ 该依据按**已核**记；另两条（口径句与 DECL 一致、`#52` 的实际形态=加两行）与主控一致，是本件的直接依据。
#     · **新建** `docs/WAVE53-PREREGISTRATION.md`（`b5ecd5433a57af47`，`docs/` 里此前只有 `WAVE15…WAVE52`）：
#       标题行 = ``# 波 `#53` —— 预登记（`TASK-0109`：…）`` ⇒ 命中 `verify-all.sh:207-221` 的 `grep -qE "^#+ .*#53"`。
#       缺它 ⇒ 第 `[14]` 步 `VERIFYALL-SELF` = `NOINFO reason=prereg-absent`（`rc=2`，**缺声明 ≠ 通过**）⇒ 冻不了。
#       件里逐字写明"**由 W133A 在收尾链中补建（主控授权）**"＋"**判据先写于 `$HOME/w131a/criteria.md`**
#       （`2026-09-23 10:56 CST`，sha256 `045477a20ac256df1bf7edcd3d2e75d7f1b88c252843738d57a37476abadd3dc`），
#       **本件不发明新判据**"。该件**不在** `fp_inputs()` 覆盖面内。
#   **登记/承重件**：`build/MilBridge/known-red.json`（本波**重钉**）= `f108775906eac9aa`（`#52` = `d4e0080df6ec497c`）——
#     它在覆盖面内 ⇒ **`inputs_fp` 由此而变**（见 ② 步骤⑤）。`build/MilBridge/arm-logs/**` 由重取脚本更新（`ln -f`）。
#   **登记/地图件**（**由登记车道维护，本车道未改**）：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`｜`docs/ROUTES.md`｜
#     `build/MilBridge/tools/defect-registry-declared.tsv`。
#   **冻结产物**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（本件 = 它的新首部）｜`docs/CURRENT-STATE.md:9`（同趟改）。
#   **仪器侧**：**零接线**（`verify-all` 仍 27 步）；**九位之外无第三者位移**。
# ── ② 收尾链每步读数（命令 + 槽读数 + rc + 关键原文）────────────────────────────
#   【步骤①·native 复现 ＋ 整波重建】**一趟槽内做完**（先 `build-shim.sh --all` ⇒ 复现后再走 `close-wave.sh`）：
#     槽：`HEAVYSLOT=ACQUIRED waited=1020s`（**入槽排队 17 min**；`W124A` 的 29 腿批与 `W128A` 的 `K5 100 25 :185` 链
#       先后占着槽 ⇒ **我排队、不绕槽**）｜`MEMOK avail=5895MB`｜**`RELEASED rc=0 held=160 s`**。
#     · **C2 native 复现**：`bash src/WpfGfx.Linux.Native/build-shim.sh --all` ⇒
#       产物 `bin/libwpfwin32.so`（**327512 字节**）**重建前后 sha16 都是 `a6365183fa6d26b9`** ⇒
#       **逐字节复现**（"路径无关"断言**未破**）✓；`== 导出符号总数：547`（**不变**）✓；
#       ABI 段 `结果：全部一致（编译期 _Static_assert 亦已通过）` ✓
#       （⚠️ 一条**既有**告警如实记：`src/win32_misc.c:224 -Wmisleading-indentation`（`GetDpiForMonitor`），
#        **不是**本波落点，我**未处置、只报**。）
#     · **整波重建**（`bash build/close-wave.sh --skip-verify-all`，`WAVE_OWNER=W133A`）：
#       `▶ 波责任人：W133A`；`OUT=/home/links-dev/wfp-runs/close-wave-122558`。
#       `[0/6]` `✅ 无应用进程、无重发锁`；`波前输入指纹 = f0e2b3e8c058cdf017031360a2cc292ffd6ab7b91b4a8ae47c100c3877522bd7`
#       `[1/6] integration-wave.sh` **`rc=0`**；`APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0`；
#       **`=== 集成波结束：失败步骤 0 ===`**（逐工程 `0 个错误 0 个警告`）。
#       波自身输入稳定性：`波前指纹 6781997d55260e95dbec0602345587a005305d948e023990746313d8ac1f9b50`
#         ＝ `波后指纹` **逐位相同** ⇒ `✅ 一致`（⚠️ **口径**：这是 `wave_fp()` 的独立口径，盯的是
#         `build/shims/**`／应用器／`src/**` 的**手写输入**，**不是 `fp_inputs()`**；两值**不可互比**）。
#       `[2/6]` native：`源码不比权威件新 ⇒ 跳过重建`（我刚重建过）｜`[3/6]` 桥：`源指纹一致 ⇒ 无需重发`
#       `[4/6]` 身份自检四项：桥源指纹两侧一致 `0a8f69b3c5fabd43` ✓｜生成物指纹 `state=ok`（PC/WB/PF）✓｜
#         **应用器审计 `miss=0`** ✓（"注册了但没生效"这一族已关门）｜
#         **`输入稳定性：波前==波后 == f0e2b3e8…2bd7`（期间无手写改动）** ✓ ⇒ 整波**不动 `inputs_fp`**。
#         ⚠️ 第 3 行 `⚠️ APPSYNC 非 PASS` 是**登记在册的告警**（见下），**不是本波引入**。
#       `[5/6]` **按要求跳过**（`--skip-verify-all`：冻前 `verify-all` 我**另起一趟**跑，避免白跑 15 min）
#       `[6/6]` **哨兵已更新**（`close-wave.sh` 是它的**唯一写者**）：两处**逐字节一致**（`cmp` = IDENTICAL）——
#         `/tmp/bridge-frozen.flag` 与镜像 `~/wfp-runs/bridge-frozen.flag`：
#         `WIN32SHIM=a6365183fa6d26b9`｜`WAVE=close-wave-122558`｜`PF=4973bcb28e331cf0`｜`PC=722e0ab8205b7c3f`
#         ｜`SHA=feef049e9d0e313a`｜`FP=0a8f69b3c5fabd43`｜`HBTL=921ba9c65e9fb3be`｜`WIC=f7b3026c8c019be2`
#         （**换代前**：`/tmp` 那份**不存在**、镜像是 `close-wave-155140`（**9-18 旧代**，`WIN32SHIM=0098234982391bbf`））
#     · **波后九位（本车道现算，逐位并列）**：`bridge feef049e9d0e313a`（5028208 B，**未变**）｜
#       `pc 722e0ab8205b7c3f`（3601408 B，**未变**）｜**`pf 358136b0c806ee88` → `4973bcb28e331cf0`**（**同尺寸 6123520 B**）｜
#       `windowsbase 2e4e46e539a72cd7`（**未变**）｜`provider 1f9511a7ef395bfe`（**未变**）｜
#       **`win32shim a6365183fa6d26b9`**（327512 B，= `TASK-0109`）｜`wic_shim f7b3026c8c019be2`（**未变**）｜
#       `hbtextline 921ba9c65e9fb3be`（**未变** ⇒ `build/shims/**` 零字节改动）｜`dwf ce3469f49efcbcfa`（**未变**）。
#       ⇒ **`changed = {win32shim, pf}`**，**逐字命中判据 C1 的允许集合**（波内 `REFRESH` 行逐字为证：
#       `build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/PresentationFramework.dll 358136b0c806ee88 → 4973bcb28e331cf0
#        （权威 4973bcb28e331cf0；副本曾早 11254 秒）`）。
#       🔴 **这是 `D-G92`（`pf` 不是构建身份）的第四次连续现场再证**（`#50`/`#51`/`#52`/`#53`）。
#     · **`APPSYNC` 如实记（不是本波引入）**：`APPSYNC-REFRESH=refreshed=30 newer=0 applied=1`；
#       `APPSYNC=MISMATCH（MISMATCH=0[STALE=0 NEWER-DIFF=0] MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0]
#        DIVERGENT=0 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0）`
#       ⇒ `STALE=0`／`DIVERGENT=0`／`MISMATCH=0` 三项**全 0**；`UNEXPECTED=6[DECL-GAP-EQ=6]` = **在册**声明类缺口
#       （**不当绿、不改判据**，与 `#52` 逐字同形）。`close-wave.sh:159-160` 会**长期**印 `⚠️ APPSYNC 非 PASS`
#       —— 那是**登记在册的告警**（APPSYNC 是告警不是硬闸），**不是新问题**。
#   【步骤③·WIC 权威件同步】干跑 `refreshed=0 newer=0 applied=0`（rc=0）→ `--apply`
#     `APPSYNC-REFRESH=refreshed=0 newer=0 applied=1`（**写了 0 件** —— 波内那步已刷 30 件）；
#     校验器 ⇒ `MISMATCH=0（STALE=0 NEWER-DIFF=0） MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0] DIVERGENT=0
#     RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0` ⇒ **`STALE=0 DIVERGENT=0`** ✓
#     （⚠️ 任务书里那条"必须显式补根，否则 `STALE=0` 假绿（`D-G91`）"**已被 W113A 修掉**：
#      `sync-applocal-authority.sh:103-105` 不覆盖时**从判据唯一实现派生**根集合，实测派生值**已含 `…/tools`**；
#      显式收窄还会自检拒绝。我仍传同一集合 ⇒ **两法同值**。）
#   【步骤④·五臂重取】**预测先写**（`$HOME/w133a/criteria.md` C4）：只有 `tline` 位**可能**变
#     （`tline.log` 程序上不可复算）；其余四臂**逐位不变**；五臂**判词**与 `#52` 逐字相同。读数：
#     槽：`HEAVYSLOT=ACQUIRED waited=861s`（**排队 14 min 21 s**）｜`MEMOK avail=5870MB`｜**`RELEASED rc=0 held=320 s`**
#       （授权 1200：`#50`/`#51`/`#52` 实测 307/318/352 s ⇒ 300 s 装不下）。`ARMS_DISPLAY=:97 source=reused`
#       （` :97` 当时已在、几何 `1280x1024x24` ⇒ 走"复用"径；**不是我起的、我也没杀它**）。
#     取臂前自证：`shim=921ba9c65e9fb3be`｜`pc=722e0ab8205b7c3f`｜`run.sh=711f39f468f61cc8`｜`Parity.cs=149dd986a642fdfc`｜
#       `CoverageProbe build rc=0`。
#     读数（五臂 sha16；`#52` 冻结值 → 本波）：
#     | 臂 | `#52` | 本波 | 变? | 判词（`#52` → 本波） | `rc` |
#     |---|---|---|---|---|---|
#     | `tline` | `56bea7233ba05c7b` | **`44c21d648f79126c`** | **变**（**预测命中**） | `通过 22 / 失败 2` → **逐字相同** | 1 |
#     | `tab-zero` | `9150c3a26a3cb789` | `9150c3a26a3cb789` | 未变（预测命中） | `退出码=1`（未登记失败 1/失败共 1，唯一 = `notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白 期望=0 实得=1`） | 1 |
#     | `tab-anchor` | `1c43a12dcaa5718a` | `1c43a12dcaa5718a` | 未变（预测命中） | `退出码=0`（`START 红=0 绿=615 判定行=615`／`OVERFLOWED 红=0 绿=421 判定行=421`／`字形释放行=194`） | 0 |
#     | `tab-rtl` | `92570318851ca7e8` | `92570318851ca7e8` | 未变（预测命中） | `退出码=0`（`红=0`；`缺字形` 例仍在 `NOINFO`） | 0 |
#     | `textlineproto` | `4bceceeed570ba70` | `4bceceeed570ba70` | 未变（预测命中） | `通过 10 / 失败 0` → **逐字相同** | 0 |
#     ⇒ **只有 `tline` 变**（**逐格命中判据 C4**：`tline.log` 内含 app-local 同步行／耗时／被同步权威件 sha／
#       自指 artifact／日期戳文件名 ⇒ **程序上不可复算**，它变**本身不构成产品位移信号**）；
#       **五臂判词与 `#52` 逐字相同** ⇒ **不停手** ✓
#     ⚠️ **机制留痕**：重取脚本末尾用 **`ln -f`** 把新日志硬链进 `build/MilBridge/arm-logs/`
#       （五行逐条印 `(links=2)`，`arm-log-sha-check.sh` 亦印 `nlink=2`）—— 这是**仓内既定机制**
#       （`fp_inputs()` 的注释写明"重取用 `ln -f`"，且因此**刻意不把 `arm-logs/` 纳入覆盖面**），
#       **不是**我沙箱的污染（我自己的实验全程 `cp -p`、零 `ln`）。
#   【步骤⑤·重钉世代】
#     改前 `cp -p` 备份 ⇒ `~/w133a/backup/known-red.before-w133a.json`（与改前**逐位相同** `d4e0080df6ec497c`）。
#     `--check` **前**：**`REPIN_GENERATION=FAIL n=2`**（`generation.arm_logs.tline 不一致`；
#       `generation.evidence_log_sha256 声明=56bea7233ba05c7b 现场=44c21d648f79126c`）⇒ rc=1
#       —— **这是"顺序"不是"矛盾"**（登记表还是 `#52` 的臂值）。
#     `--why '<四条理由>'` ⇒ **`REPIN_GENERATION=APPLIED`**（rc=0）：
#       `generation.instr_run_sh = 711f39f468f61cc8`｜`instr_program_cs = 149dd986a642fdfc`｜
#       `instr_shim = 921ba9c65e9fb3be`｜**`evidence_log_sha256 = 44c21d648f79126c`**｜
#       **`entries[*].caliber 改动字段数 = 0`**（⇒ 只动世代记账，**没碰任何判据口径**）。
#     `--check` **后**：**`REPIN_GENERATION=PASS（世代三项 + 五臂 + 证据日志 + 4 条 entries 的 caliber 全部一致）`** ✓（rc=0）
#     件：`known-red.json` **`d4e0080df6ec497c` → `f108775906eac9aa`**
#       （FULL `f108775906eac9aa0e21443e2757b746c01187dbeb1cc92cfcedc9f335492f4e`）。
#     **`inputs_fp`（重钉后，现算）**：`f0e2b3e8c058cdf017031360a2cc292ffd6ab7b91b4a8ae47c100c3877522bd7`
#       → **`5ac1e5349c7d1dec56fd7d8fe5dd8e9c1cb7c3b4052859f887e45c539981904f`**
#       （**归因：`known-red.json` 在 `fp_inputs()` 覆盖面内** —— `#28` 起的设计使然；覆盖面仍 **149** 件）。
#       ⇒ 我把 `GENS['#53']['infp']` 从**先记的 `None`** **收紧**成这个精确值（**收紧＝不许放宽**；
#       `w27-freeze.py` `32e32fab1055b1e0` → `5acac47065f6a7aa`，逐字记在此）。
#     **两颗声明牙的两极化（这是"顺序"不是"矛盾"）**：
#       · 重钉**前**：`ARMLOG_SHA=FAIL shape=flat required=5 declared=5 pass=4 fail=1` ／`COLUMN_FLOOR=PASS n_ok=5`
#       · 重钉**后**：**`ARMLOG_SHA=PASS … pass=5 fail=0`** ／
#         **`COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0
#          selfreport=PASS reg=f108775906eac9aa base=27293fb5ab91b778 corpus=0cebc0afd5142fbf`**
#       ⇒ **逐字命中判据 C6 预期的那 1 处声明类红**（`COLUMN_FLOOR_ARMLOG=FAIL` ∧ `selfreport=PASS`）⇒ **冻后必须转绿**。
#   【步骤⑥·应用门禁 ×2】两趟**各写一本 rows**（写同一本会变 12 行 ⇒ 冻结器断言 6 行会红）；
#     显示号用**空闲 `:2xx`**（自起 `1280x1024x24` ⇒ 与 `#52` 落地的几何守卫要求 `XREQ_GEOM` 一致，
#     且**不依赖别人的 X**：`:97` 当时虽在，但是**别的车道**的）：
#     槽：**一趟槽内跑完两趟门禁** ⇒ `HEAVYSLOT=ACQUIRED waited=936s`（**排队 15 min 36 s**）｜
#       `MEMOK avail=5827MB`｜**`RELEASED rc=0 held=322 s`**（授权 700；`#50`/`#51`/`#52` 两趟合计 161×2/158×2/167+162 s ⇒ 同量级）。
#     第 1 趟（13:04:05，写 `gate-rows.txt`）：`WPTD_DISPLAY=:213` ⇒ **`== 启动自己的 Xvfb :213（1280x1024x24）`**（PID 729292）
#       ｜`GATE1_OUTER_RC=0`
#     第 2 趟（13:06:46，写 `gate-rows-f.txt`，`--no-build`）：`WPTD_DISPLAY=:214` ⇒ **`== 启动自己的 Xvfb :214（1280x1024x24）`**（PID 746131）
#       ｜`GATE2_OUTER_RC=0`
#     ⇒ **两趟各 6 行 `BASELINE`、各 6 个 `result=PASS`、0 个 `result=FAIL`**（`default 3/3` ＋ `env 3/3`）；
#       `WPTD_SUMMARY=PASS tiers_passed=2/2`｜`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`｜
#       `WPTD_BRIDGE_SRC_STALE=no basis=pub=0a8f69b3c5fabd43 now=0a8f69b3c5fabd43 so_file_match=yes`；
#       rows sha16 = **`978f0ee52989d6c2`**（`gate-rows.txt`）／**`8c5d2dd7ed1b8724`**（`gate-rows-f.txt`）。
#       **两本 `config=` 段逐字相同**（`diff` 空 ⇒ `CONFIG_IDENTICAL`）=
#       `pc:722e0ab8205b7c3f`／**`pf:4973bcb28e331cf0`**／**`win32shim:a6365183fa6d26b9`**／`bridge:feef049e9d0e313a`／
#       `provider:1f9511a7ef395bfe`／`wic_shim:f7b3026c8c019be2`／`hbtextline_shim:921ba9c65e9fb3be(stale:no)`
#       ⇒ **就是终态九位** ⇒ **门禁本波 12/12 PASS**、**无表外位移**。
#     ⚠️ **显示号用空闲 `:2xx` 的理由（不是随手换）**：`:97` 当时**在用但属别的车道**（W124A／W128A 的链），
#       `:185`/`:188` 也是别人的；本车道**只用空闲 `:2xx`** ⇒ **两趟各自起了自己的 `1280x1024x24`**，
#       几何与 `#52` 落地的几何守卫要求（`XREQ_GEOM=1280x1024`）**一致**，且**不依赖别人的 X**、
#       **也没杀任何别人的 X** ⇒ 这两趟读数**不可能是"复用别人几何不符的 X"造成的假红/假绿**。
#     ⚠️ **一处如实记的既有现象（非本波引入）**：两趟装配运行目录时都印
#       `System.Printing.dll ⚠️ 不一致 bin=5ccc76227e5e 权威=19493a86ad92（可能是集成波中途的产物）`
#       —— `#52` 的同一行**逐字相同**，且它**不在九位里**、**不参与任何判据** ⇒ 我只报不处置。
#   【步骤⑦·冻前 `verify-all`（27 步）】
#     槽：`HEAVYSLOT=ACQUIRED waited=657s`（**排队 10 min 57 s**；`W124A` 的长跑批占着槽 ⇒ 我排队）｜
#       `MEMOK avail=5774MB`｜**`RELEASED rc=0 held=876 s`**（授权 1500；`#49`–`#52` 实测 854–911 s ⇒ 同量级）。
#     日志：`~/w133a/logs/09-verify-pre.log`（`PRE_OUTER_RC=1` —— **声明类红的那 1 处**，见下）。
#     `[0] Xvfb（目标 :99）` 段**逐字**：**`✅ X-REUSE=reused display=:97（已运行的 Xvfb；几何 1280x1024 相符；注意不是 :99）`**
#       ｜`DISPLAY=:97（已用 xdpyinfo 验证可连）`｜`X_STATE=available（判据：xdpyinfo 对 DISPLAY=:97 成功 ⇒ available）`
#       ⇒ **几何守卫按设计工作**（`:97` 当时是一台 `1280x1024x24`，几何**相符** ⇒ 复用；若不符会 `skipped-geom-mismatch` 并自起）。
#       ⚠️ **这正是 `#52` 那格假红的反面对照**：`#52` 冻前第 1 趟复用了**几何不符**的 `:185`（1024x768）⇒
#       `Windowing.Tests` 假红（`用例通过 831`）；本波**几何相符** ⇒ `Windowing.Tests 44/0`、`用例通过 875`。
#     结论行（逐字）：**`步骤通过 26  ❌ 失败 1`**｜**`用例通过 875  跳过 2`**｜
#       `SKIP_GUARD=PASS x_state=available x_died=0 x_suite_skipped=0 x_suite_units=0 x_suite_corpus_max=0 total_skipped=2 violations=none reason=none`｜
#       **`结论：❌ 失败项：COLUMN-FLOOR`** ⇒ **恰好 1 处红，且就是设计内的声明类红** ⇒ **判据 C6 逐字命中** ⇒ **继续 ⑧ 冻结**。
#     逐套件：`Commands 562/0`／`Rendering 166/2`／**`Windowing 44/0`**／`HelloMil 19/0`／`ManagedLayer 76/0`／`Presentation 8/0`
#       ⇒ `562+166+44+19+76+8 = 875`（**与 `#52` 逐格相同**；`#52` 那趟假红时是 `831`，差 **44 = 整套件**）。
#     唯一那 1 处红（逐字母句）：`COLUMN-FLOOR ❌ (rc=1)`／
#       `COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline`／
#       `COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0
#        selfreport=PASS reg=f108775906eac9aa base=27293fb5ab91b778 corpus=0cebc0afd5142fbf`
#       ⇒ **`COLUMN_FLOOR_ARMLOG=FAIL` ∧ `selfreport=PASS` = 冻结器 `_is_declaration_class()` 认的形态** ✓（**冻后必须转绿**）。
#     其余 26 步**全绿**，关键机读行：
#       `BASELINESHA=PASS live=27293fb5ab91b778 decl=27293fb5ab91b778`｜`BASELINEGEN=PASS decl_gen=#52 file_newest_gen=#52`（冻前应然）｜`BASELINEDUP=PASS n=0`
#       `ARMLOG_SHA=PASS required=5 declared=5 pass=5 fail=0 noinfo=0`（**重钉后已转绿**）
#       **`VERIFYALL_SELF=PASS names=27 decl=27 gen=#53 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=32ddbe487235cc38`**
#       **`R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938 mem_mb=5144 win32shim=a6365183fa6d26b9 pc=722e0ab8205b7c3f src=device`**
#         ⇒ **`win32shim=` 是 `TASK-0109` 的新件**，`crit=13/13` ⇒ **零回归**；`NULBYTES=PASS files=1221 hits=0 canary=ok`；
#         `FP_INPUTS_HYGIENE=PASS coverage_n=149 artifact_n=0`；`DEFREG=PASS declared=145 route_ids=145`；
#         `HIDDEN_ONLY_STEP=PASS 判定例=32/32`；`PRODUCT_ENTRY_STEP=PASS 判定例=8/8 在册已知红 5/5`；
#         `SHELL_QUOTE_TRAP=PASS traps=0`；`FRAMEPRESENCE=PASS frames=80`；`THIRDPARTY=PASS frames=42`。
#     ⇒ **无第 2 处非声明类红 ⇒ 停条件④ 未触发**。
#   【步骤⑧·冻结 `#53`】见 `===FROZEN===` 段与下方 ③ ④；冻结器 = `$HOME/w21-verify/w27-freeze.py`
#     `<verify-all 日志> <门禁 rows> #53`（**本代常数 = `GENS['#53']`，只追加，老代一字不动**）。
#     命令：`python3 $HOME/w21-verify/w27-freeze.py ~/w133a/logs/09-verify-pre.log ~/w133a/gate-rows.txt '#53'`
#     （**本代常数 = `GENS['#53']`**：`PRE=/home/links-dev/w53-pre.sha`（`8dd00cb414a10ccf`）｜`prev='#52'`｜
#      `nstep=27`｜`prev_pf='358136b0c806ee88'`｜`prev_pc='722e0ab8205b7c3f'`｜
#      **`infp='5ac1e5349c7d1dec56fd7d8fe5dd8e9c1cb7c3b4052859f887e45c539981904f'`**（重钉后的现算终值）｜
#      `hb='921ba9c65e9fb3be'`｜`bs_fp='0a8f69b3c5fabd43'`｜`allow_changed={'win32shim','pf'}`｜`pf_required=False`｜
#      `prev_wsh='bd037229be8db4f6'`｜`prev_wb='2e4e46e539a72cd7'`｜`prev_dwf='ce3469f49efcbcfa'`）；
#      `w27-freeze.py` `101db5306e1669fe` →（追加 `GENS['#53']`）`32e32fab1055b1e0` →（**收紧 `infp`**）**`5acac47065f6a7aa`**
#      ⇒ **只追加 + 一次收紧，老代（`#52` 及以前）一字未动**（备份 `~/w133a/backup/w27-freeze.py.before-w133a` = `101db5306e1669fe` 逐位）。
#     ⚠️ **落盘之前先跑机械自检** `bash ~/w133a/bin/check-record.sh`（**`#51`/`#52` 两次血案的对策**）：
#      断言 `===FROZEN===`..`===RECORD===` 段里 `# COLUMN-FLOOR `×2／`# COLUMN-CORPUS `×1／`# ARM-LOG-SHA `×5 **齐全且带 `# ` 前缀**，
#      且 `@@` 占位符**清零**（`tline` 那行必须 = 本波 live 值 `44c21d648f79126c`）。
#     🔴 **血案留痕（`#51` W110A、`#52` W126A 各踩一次，同一个坑）**：这些外挂声明行**只在冻结块里被认**，且**必须有 `# ` 前缀**；
#      而**冻结器是先写盘、后断言** ⇒ 断言失败时盘上**已经**是半成品（`#51` 曾写成 `d1f66f944cdf1c39`、
#      `#52` 曾写成 `50badf1f0277b789`）⇒ **重冻前必须先从备份逐字节还原**。本件**先自检再落盘**，两次都没触发。
#     冻结读数（**四颗牙 ＋ 位移 ＋ 两极化 ＋ 终态整份 sha**）：见 **`build/MilBridge/W133A-report.md` §⑤「冻结块（四颗牙 ＋ 按冻结口径现算的九位）」**。
#     ⚠️ **为什么这里指报告、不指本文件**：本块**就是** `ACCEPTANCE-BASELINE.md` 的内容 ⇒ **往本文件追加任何一段都会改整份 sha** ⇒
#     `BASELINESHA` 必 FAIL（`baseline-sha-check.sh:33` 取的是**整份文件**的 sha）。⇒ 冻后实测读数一律落 `build/MilBridge/W133A-report.md`；**不许**回头改本块。
#     预期（判据 C7）：`相对开工前变化的位 = ['pf','win32shim']`（在允许集合内）｜
#       `BASELINESHA/BASELINEGEN/BASELINE_BYTES/BASELINEDUP` **四颗全 PASS**（`decl_gen=#53 file_newest_gen=#53`）｜
#       `ARMLOG_SHA=PASS 5/5`｜**`COLUMN_FLOOR=PASS`**（**冻前那 1 处红必须转绿**）｜
#       门禁 6 条机读行 `pc:722e0ab8205b7c3f pf:4973bcb28e331cf0` 与冻结刻现算九位一致。
#   【步骤⑨·冻后 `verify-all` ×2】
#     两趟都必须 **`步骤通过 27 ❌ 失败 0`**／**`结论：✅ 全部通过`**／`用例通过 875 跳过 2`
#       （含冻前那 1 处声明类红 **转绿**）；**判词层机读行两趟逐字相同**（运行期读数如 `mem_mb`／带时间戳目录名
#       **允许不同、要如实记**）；**两趟之间不许换件**（`[26] R-GATE` 读 `win32shim=` ⇒ 中途换件会让两趟自相矛盾）。
#     冻结刻／冻后刻**各复算一次九位成对并列**（`pf` 两刻可能不同 —— `D-G92`，**不算失败**）。
#     逐条读数见 **`build/MilBridge/W133A-report.md` §⑥「冻后 `verify-all` ×2」**（同上理由：本块不许被追加）。
#   【步骤⑩·收尾记录 ＋ 推送 ＋ app-local】见 ⑤ ⑥。
# ── ③ 停条件逐条核（**出现即停手，不冻结**）──────────────────────────────────
#   ① **表外位移**（判据 C1）：无 —— `changed` 恰好 = `{win32shim, pf}`，两者都在 `GENS['#53']['allow_changed']` 里；
#      另七位**逐位与 `#52` 冻结点相同**。
#   ② **native 复现不出 `a6365183fa6d26b9`**（判据 C2）：**未触发** —— 重建前后 sha16 **都是 `a6365183fa6d26b9`**（327512 B），
#      `导出符号总数：547` 不变，ABI 段全一致。
#   ③ **五臂判词与 `#52` 不一致**（判据 C4）：**未触发** —— `通过 22 / 失败 2`／`退出码=1`／`退出码=0`／`退出码=0`／`通过 10 / 失败 0`
#      与 `#52` **逐字相同**。
#   ④ **冻前 `verify-all` 出现第 2 处非声明类红**（判据 C6）：见下方 ② 步骤⑦ 的现读；**只出现声明类那 1 处** ⇒ 未触发。
#   ⑤ **`hbtextline` 变了**：**未触发** —— `921ba9c65e9fb3be` 从波前到冻前**逐位未变**（`build/shims/**` 零字节改动）。
#   ⑥ 附加自守（不是任务书的停条件，但我自己也停）：**导出数变化**（547 → 别的）／**`R_GATE` 不再是 `crit=13/13`** —— 都未触发。
# ── ④ `NOINFO` 逐条（**取不到就写 `NOINFO`，不许猜**）────────────────────────────
#   ① **`pf` 的非确定性根因仍未抓到**（`D-G92`，`NOINFO`）：本波又添一条成对读数
#      （`358136b0c806ee88` → `4973bcb28e331cf0`，**同尺寸 6,123,520 B**），但**真凶未明**；
#      **要什么样的读数**：一个覆盖 PF **全部**编译输入（含生成件与时间/路径相关输入）的指纹。
#   ② **`tline` 臂日志的 sha 变化不可归因**（`NOINFO`）：该日志内含 app-local 同步行／耗时／被同步权威件 sha／
#      自指 artifact／日期戳文件名 ⇒ **程序上不可复算**；判据只能是它的**判词**（本波 = `通过 22 / 失败 2`）。
#   ③ **`UNEXPECTED=6[DECL-GAP-EQ=6]` 未逐条归因**（`NOINFO`）：`#49` 已认定为**在册**声明类缺口；
#      本件只确认"**不因本波变多**"（与 `#52` 逐字同形）。
#   ④ **`upstream/**`（6417 件）未测**（`NUL-BYTES` 步的 `NOINFO` 格）：该步 `PASS` **只等于「声明覆盖面里 0 件含 NUL」**。
#   ⑤ **`D-G83`（`WM_GETMINMAXINFO` 四格）本波未重跑**（`NOINFO`）：装置在别的车道的 `~/w89a/bin/**`（≈30 min，重活）。
#      静态替代（W131A 已做、我**未重做**）：`DefWindowProcW` 的 `WM_GETMINMAXINFO` 那一段与修前**逐字相同**。
#   ⑥ **真应用"拖动窗口"未被本波重测**（`NOINFO`）：`TASK-0109` 的产品侧验收由 W131A 的深仪器负责（`green=12 red=0`），
#      本件只冻结件级读数。
#   ⑦ **`System.Printing.dll` 的 `bin`/权威不一致**（两趟门禁都印）**未归因**（`NOINFO`）：`#52` 同一行**逐字相同**，
#      不在九位里、不参与判据 ⇒ 我只报不处置。
#   ⑧ **`:97` 的所有者未定人**（`NOINFO`）：本波**复用了它**（五臂 + `verify-all [0]` 段），几何 `1280x1024` 相符；
#      **我没有杀它、也没有改它**（`#52` 期间主控明令"不许杀别人的 X"）。它的存活是这两项读数的**外部依赖**。
# ── ⑤ 推送（**逐径**，绝不 `git add -A`／`git add .`）────────────────────────────
#   **机制（先搞清再动）**：fork 克隆 `~/netTest/GitProj/WPFOnLinux` 是**独立检出**，**不自动跟随 `$R`**
#     （`#52` 现场实测：克隆 `git status --porcelain` 干净，而 `win32_core.c` 与 `$R` **DIFF**）
#     ⇒ 必须**先 `cp -p` 真件**，**不许**用 `git add -A`／`git add .`（`#52` 期间出过一次**夹带事故**：
#     某车道用 `git add -A` 把另一条在办车道的 native 源扫进同一笔，事后 `revert` 还原 —— 见 `build/MilBridge/W127A-report.md` §⑪）。
#   **本件的纪律（逐条执行并留证）**：① `git status --porcelain` 与 `git diff --cached --name-only` **逐件列出并计数**，
#     贴"本笔恰好 N 件、无夹带"；② **逐径** `git add <file>`；③ `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`
#     （**refspec 陷阱**：默认只跟 `main`，拿旧 ref 比会得**假 MISMATCH**）；④ `git push origin feat-Linux`；
#     ⑤ push 之后**重新 fetch** ＋ 与 `git ls-remote` **交叉核**；⑥ 逐件 `git cat-file blob origin/feat-Linux:<path> | sha256sum`
#     与磁盘 `cmp` ⇒ `BYTECHECK ok=? mismatch=? nobody=?`；⑦ `git ls-remote --symref origin HEAD` 仍须 `ref: refs/heads/feat-Linux`。
#   **逐条读数见 `build/MilBridge/W133A-report.md` §⑦「推送（逐径）」**（同上理由：本块不许被追加）。
#   ⚠️ **推送窗口干净性（我先核过）**：主控 12:1x 确认"本波不会再有别人往 `R` 落产品改动"；
#     我另核了一条**同族**的装置事实：`applocal-expect.py` 的期望目录**共 71 个、全部在 `$R` 内**，
#     **不含** `~/w89a/app` ⇒ 本波整波重建**不会动** W124A 正在跑的那个应用目录（`D-G80` 族的口径：先核装置读的是哪一份件）。
# ── ⑥ app-local 刷新（含五件权威件之一 `win32shim`）──────────────────────────
#   命令：`AUTH_ROOT=$R SCAN_ROOTS=$R/build:$R/tests:$R/samples:$R/src:$R/tools bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh [--apply]`
#     ＋ `bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh`（**逐件回读**）。
#   判据（C10）：`STALE=0 DIVERGENT=0`；**`win32shim` 是五件权威件之一 ⇒ 应用目录里的件必须是 `a6365183fa6d26b9`**
#     （贴 `APP_ART win32shim=` 那一行）—— 波内 `[1/6]` 那步已经刷过 30 件副本。
#   `UNEXPECTED=6[DECL-GAP-EQ=6]` = **在册**声明类缺口 ⇒ **不当绿、不改判据**。
#   逐条读数见 `build/MilBridge/W133A-report.md` §⑧「app-local 回读」**（同上理由）。
# ── ⑦ 内存三值与纪律 ─────────────────────────────────────────────────────────
#   **值见 `build/MilBridge/W133A-report.md` §⑪「内存三值与纪律」**（同上理由）。口径：`MemAvailable` **开工／最低／收工**三值 ＋
#   `loadavg`；所有重活**走槽**（每趟都记 `HEAVYSLOT=ACQUIRED waited=…`／`MEMOK`／`RELEASED rc=… held=… max_hold=…`）；
#   **无 `MAXHOLD_KILL`、无 `low-memory`**（⇒ 无作废趟）；**不许 `pkill`／`killall`／`pgrep -f`** —— 收进程**只按 PID**，
#   探活读 `/proc/*/cmdline`；**不许手抄哈希**（一律现场算 16 位小写，报件给 FULL ＋ 口径值两行）；
#   显示号只用空闲 `:2xx`；**绝不许碰** `:0`／`:1`（用户桌面）／`:97`／`:185`／`:188`。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:4973bcb28e331cf0,provider:1f9511a7ef395bfe,win32shim:a6365183fa6d26b9,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w133a/gate-e
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:4973bcb28e331cf0,provider:1f9511a7ef395bfe,win32shim:a6365183fa6d26b9,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w133a/gate-e
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:4973bcb28e331cf0,provider:1f9511a7ef395bfe,win32shim:a6365183fa6d26b9,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w133a/gate-e
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:4973bcb28e331cf0,provider:1f9511a7ef395bfe,win32shim:a6365183fa6d26b9,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w133a/gate-e
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:4973bcb28e331cf0,provider:1f9511a7ef395bfe,win32shim:a6365183fa6d26b9,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w133a/gate-e
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:4973bcb28e331cf0,provider:1f9511a7ef395bfe,win32shim:a6365183fa6d26b9,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w133a/gate-e
# ⏪ **（历史，已被 `#53` 取代）**# RE-FROZEN #52 —— ✅ **当前冻结基线** —— 内容 = 收掉 `#52` 这一波（收尾链 10 步由车道 **W126A** 一步到底）：
#   **① 产品侧：`D-G100` 独立卫生修**（`TASK-0108` 之后的独立卫生修）
#     落点：`src/WpfGfx.Linux.Native/src/win32_core.c`（`3117923a7c899e05`）
#     ＋ `src/WpfGfx.Linux.Native/src/win32_x11.c`（`11142fbef049eb66`）⇒ **`win32shim` 位变**：
#     `8392fc09564779a1` → **`bd037229be8db4f6`**；`bash src/WpfGfx.Linux.Native/build-shim.sh --all` 复核
#     **导出符号 547 不变**。⚠️ **本波不修 `D-G98`**（真因已转向「过期尺寸约束挡还原」，属 `TASK-0111`）。
#   **② 装置／危险处置（三件）**：跨区硬链断链（`D-G101`，W123A，只换 inode）｜`repin-generation.py`
#     `temp`＋`os.replace`（`711a1fc30764d84c`，不在覆盖面内）｜两件新牙未接线。
#   **③ 判据件变更：`verify-all.sh` 的 X 显示几何守卫**（授权 = 主控；见 `docs/WAVE52-PREREGISTRATION.md` §R1）：
#     复用外部 Xvfb 前**必须**核几何 `== $XREQ_GEOM（1280x1024）`；不符 ⇒ 跳过＋点名；两处复用点同趟加。
#     `verify-all.sh` `1fb43fc4522c8784` → **`0cdd12547a634b37`**。**步数不变（仍 27）**。
#   **④ 九位（终态）与位移对账**
#     · `bridge` `feef049e9d0e313a`（5028208 B）｜`pc` `722e0ab8205b7c3f`（3601408 B）｜`pf` `358136b0c806ee88`（6123520 B）｜`windowsbase` `2e4e46e539a72cd7`｜
#       `provider` `1f9511a7ef395bfe`｜`win32shim` `bd037229be8db4f6`｜`wic_shim` `f7b3026c8c019be2`｜`hbtextline` `921ba9c65e9fb3be`（293165 B）｜`dwf` `ce3469f49efcbcfa`。
#     · ⚠️ **位移对账（相对 `#51` 冻结块那一栏）**：`win32shim` `8392fc09564779a1` → `bd037229be8db4f6`（= `D-G100`）；
#       `pf` `bc2c47ac7b067bad` → `358136b0c806ee88`（= **整波重建的非确定性**，`D-G92`）；其余七位 `bridge`／`pc`／`windowsbase`／
#       `provider`／`wic_shim`／`hbtextline`／`dwf` **逐位未变**。
#     · 🔴 **`pf` 不是构建身份（`D-G92`，逐字）**：同源、同命令的两次重建可给出**不同字节**。
#       本波是一条**新的连续证据**（`#50`/`#51`/`#52` 三代连续）：`#51` 冻结点 `pf` = `bc2c47ac7b067bad`
#       （那是 `#51` 收尾链整波重建**之后**的值），本波收尾链整波重建后 → `358136b0c806ee88`（**同尺寸 6,123,520 B**）。
#       **两刻并列见 `===RECORD===` ②**；**两刻不同不算失败**（本代 `allow_changed={win32shim, pf}`、`pf_required=False`）。
#   **⑤ 判据/登记件**：`build/MilBridge/known-red.json`（本波**重钉**）= `d4e0080df6ec497c`；`fp_inputs()` 覆盖面 **149** 件；
#     `inputs_fp` = `84fd55d384e93203317d22601cec854d518e69c8f026006231302a2cfbc93366`（`#51` 冻结点 = `58a6c0945b7d535830ce3e3e4f25752b68f3714d3f35f540253eca6e69b3dd36`）｜`bridge-src-fp` = `0a8f69b3c5fabd43`（`#51` = `0a8f69b3c5fabd43`）。

# ── 🦷 外挂声明行（**`#31` W31D 起的三类**；`column-floor-check.sh` 读者用 `^# COLUMN-FLOOR ` 等前缀锚定）
#   ⚠️ **血案留痕（`#51` 与 `#52` 各踩一次，同一个坑）**：这些行**必须有 `# ` 前缀**。
#     `#51`（W110A）第 1 次冻结把 8 行写成**无 `# ` 前缀** ⇒ `COLUMN_FLOOR=NOINFO reason=frozen-block-has-no-COLUMN-FLOOR-line`
#     ⇒ 冻结器 `assert` 在**写盘之后**失败（基线曾被写成 `d1f66f944cdf1c39`）⇒ 只能从备份还原后重冻。
#     `#52`（W126A）**同一个坑再踩一次**（第 1 次冻结把基线写成 `50badf1f0277b789`）⇒ 同样从备份逐字节还原后重冻。
#     ⇒ **教训（两条合起来才完整）**：① 外挂声明行只在**冻结块**里被认（前缀必须 `# `）；
#     ② **冻结器是"先写盘、后断言"** ⇒ 断言失败时盘上**已经**是半成品，**重冻前必须先还原**，否则第二代块会叠在坏块上。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=56bea7233ba05c7b
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
# ── ① 本波改了什么（逐件 sha16，改前 → 改后）────────────────────────────────────
#   **产品件**（值进九位；改前 = `#51` 冻结块那一栏）：
#     · `src/WpfGfx.Linux.Native/src/win32_core.c` `3117923a7c899e05` ＋ `win32_x11.c` `11142fbef049eb66`（**`D-G100`**）
#       ⇒ `win32shim` `8392fc09564779a1` → **`bd037229be8db4f6`**（**导出 547 不变**；`build-shim.sh --all` rc=0）
#   **判据件（本波收尾链内变更，授权在案）**：
#     · `verify-all.sh` `1fb43fc4522c8784` → `cb30ccae51a7607a`（`[0]` 段几何守卫）→ **`0cdd12547a634b37`**
#       （`x_recheck_alive()` 同趟加 ＋ 定义提顶层）；`bash -n` rc=0；`VERIFYALL_SELF=PASS names=27 decl=27 gen=#52`
#     · `docs/WAVE52-PREREGISTRATION.md` `834e370053f7ef2b` → **`a5a97b0c0563bd02`**（追加 **§R1**，只追加）
#   **装置/危险处置件（不是产品改动）**：
#     · 跨区硬链断链（W123A）：`bin/`＋`obj/` 4588 ＋ 6 件产品 DLL ＋ 1421 登记件，**只换 inode**
#     · `build/MilBridge/tools/repin-generation.py` `a2ca0a26bf99dc7a` → `711a1fc30764d84c`（temp＋`os.replace`）
#     · 新牙两件（未接线）：`hygiene-tooth.sh dc1e79a23dbb7eb2`／`regression-decision.py 1eda9e3575960cba`
#   **仪器侧**：**零接线**（`verify-all` 仍 27 步）
#   **登记/地图件**（**由登记车道维护，本车道未改**）：`KNOWN-DEFECTS.md`｜`docs/ROUTES.md`｜
#     `defect-registry-declared.tsv`（⚠️ 它的 `DECL-GEN` = 2026-09-23 09:02:37，`DEFREG_DECLDRIFT=1`；
#     但检查器 **rc=0**、`DEFREG=PASS declared=138` ⇒ **不构成步红** ⇒ 我**没有**动它）
#   **冻结产物**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（本件 = 它的新首部）｜`docs/CURRENT-STATE.md:9`（同趟改）
# ── ② 收尾链每步读数（命令 + rc + 关键原文）──────────────────────────────────
#   【三重握手（本波特有）】第一判据 = **活进程**（我**读 `/proc/*/cmdline`**，以免探活者污染自己）：
#     09:05:35 见 `w123a` **1 条存活**（`pid=409766`，跑断链批）⇒ **等待**；09:08:10/09:08:26/09:08:42 **三次探活全 0** ⇒ 通过。
#     ⚠️ **我第一版用 `ps -eo cmd | grep -c 'w123a'` 得 `3`／`2` —— 那是把我自己的命令行数了进去**（探活者污染）。
#     第二判据（门）：`~/w123a/STATUS.md` 尾部**没有**「完成 `<批名>` ok=/skip=/bad=」行 ⇒ 该格 `NOINFO`；
#     我另取替代证：`skip.batch.{bin.00,bin.01,bin.02,obj}.txt` **四本全在、全 0 字节**（逐批跑完零跳过）
#     ＋ `HYGIENE_TOOTH=PASS … multilink=0 cross_region=0`。**等待入账 09:05:35→09:08:10 = 2 min 35 s**。
#   【步骤②·整波重建】`WAVE_OWNER=W126A bash build/integration-wave.sh`（槽内 `--max-hold 1200`；理由：28 应用器＋
#     依赖序重建＋产物发布，`#50`/`#51` 实测 221/177 s）⇒ `HEAVYSLOT=ACQUIRED waited=459s`（**入槽等待 7 min 39 s**）／
#     `MEMOK avail=2695MB`／**`RELEASED rc=0 held=177 s`**；`APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0`；
#     **`失败步骤 0`**；`▶ 波责任人：W126A`。波自身输入稳定性：`波前指纹 32b017f6d63d7a60…` ＝ `波后指纹` **逐位相同** ✓
#     （⚠️ **口径**：那是 `wave_fp()` 的独立口径（盯 `build/shims/**`／应用器／`src/**` 的**手写输入**），**不是 `fp_inputs()`**；
#      我核过 `integration-wave.sh:574-583`。两值**不可互比**。）
#     native 另跑（`integration-wave.sh` **从不编译 native**）：`bash …/build-shim.sh --all` ⇒ `rc=0 held=2 s`，
#     **`导出符号总数：547` 不变**，ABI 段 `结果：全部一致（_Static_assert 亦已通过）` ⇒ **`win32shim` 仍 `bd037229be8db4f6`** ✓
#     （一条既有告警如实记：`win32_misc.c:224 -Wmisleading-indentation`，**不是** `D-G100` 的落点，我未处置只报。）
#   【步骤③·WIC 权威件同步】⚠️ **任务书前提更正**：`D-G91`（默认 `SCAN_ROOTS` 漏 `$REPO/tools`）**已被 W113A 修掉** ——
#     `sync-applocal-authority.sh:103-105` 不覆盖时**从判据唯一实现派生**（实测派生值**已含 `…/tools`**，我用 `--print-scan-roots` 验过），
#     显式收窄还会自检拒绝。我仍按任务书显式传**同集合**（两法同值）。
#     干跑 `refreshed=0 newer=0 applied=0`；`--apply` `refreshed=0 newer=0 applied=1`（**写 0 件**；波内那步已刷 34 件）；
#     校验器 `MISMATCH=0（STALE=0 NEWER-DIFF=0） MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=6] DIVERGENT=0 AUTH-MISSING=0` ⇒ **`STALE=0 DIVERGENT=0`** ✓
#   【步骤④·五臂重取】**预测先写**（`~/w126a/criteria.md` C4：只有 `tline` 可能变）⇒ 读数 `HEAVYSLOT=RELEASED rc=0 held=352 s`
#     （`ARMS_DISPLAY=:97 source=none ⇒ 自起 Xvfb`，跑完按 PID 收回）：
#     `tline` `9d29470d63791d64` → **`56bea7233ba05c7b`**（**变，预测命中**）；`tab-zero`/`tab-anchor`/`tab-rtl`/`textlineproto`
#     **逐位未变**。判词与 `#51` **逐字相同**：`tline` 通过 22/失败 2｜`tab-zero` 退出码=1（唯一失败 = 在册
#     `notab-control@w40@em24@RTL@tab0`）｜`tab-anchor` 退出码=0（`START 绿=615`／`OVERFLOWED 绿=421`）｜`tab-rtl` 0｜`textlineproto` 10/0。
#     （机制：重取脚本用 **`ln -f`** 硬链进 `arm-logs/`（`(links=2)`），**仓内既定机制**，非我沙箱污染。）
#   【步骤⑤·重钉】`repin-generation.py --check` 前 **`FAIL n=2`** → `--why '…'` ⇒ **`APPLIED`**
#     （`instr_run_sh=711f39f468f61cc8`／`instr_program_cs=149dd986a642fdfc`／`instr_shim=921ba9c65e9fb3be`／
#      `evidence_log_sha256=56bea7233ba05c7b`／**`entries[*].caliber 改动字段数=0`**）→ `--check` 后 **`PASS`**；
#     `known-red.json` `089b7324ba12e022` → **`d4e0080df6ec497c`**。
#     两极化（**顺序**而非矛盾）：重钉前 `ARMLOG_SHA=FAIL pass=4 fail=1`／`COLUMN_FLOOR=PASS n_ok=5`；
#     重钉后 **`ARMLOG_SHA=PASS 5/5`**／**`COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline`** ＋ `COLUMN_FLOOR=FAIL … selfreport=PASS`。
#   【步骤⑥·应用门禁 ×2】两趟**各写一本 rows**（写同一本会变 12 行 ⇒ 冻结器断言 6 行会红）：
#     第 1 趟 `WPTD_RUN_DIR=…/gate-e WPTD_BASELINE_OUT=…/gate-rows.txt … 60 --tier both` ⇒ `waited=0s`／`MEMOK avail=6152MB`／
#       **`RELEASED rc=0 held=167 s`**；第 2 趟（`--no-build`，写 `gate-rows-f.txt`）⇒ `avail=5628MB`／**`held=162 s`**。
#     两趟各 `default 3/3` ＋ `env 3/3` = **机读行 6/6 `result=PASS`**；`WPTD_SUMMARY=PASS tiers_passed=2/2`；
#     `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`；`WPTD_BRIDGE_SRC_STALE=no basis=pub=0a8f69b3c5fabd43 now=0a8f69b3c5fabd43 so_file_match=yes`。
#     rows sha16 = `60130d6c9bc832b4`（`gate-rows.txt`）／`2db6410ce31e2fdc`（`gate-rows-f.txt`）；**两本 `config=` 逐字相同**
#     = `pc:722e0ab8205b7c3f`／`pf:358136b0c806ee88`／`win32shim:bd037229be8db4f6`／`bridge:feef049e9d0e313a`／`provider:1f9511a7ef395bfe`／`wic_shim:f7b3026c8c019be2`／
#     `hbtextline_shim:921ba9c65e9fb3be(stale:no)`（**终态九位**）⇒ **门禁本波 12/12 PASS**。
#   【步骤⑦·冻前 `verify-all`（27 步）】**第 1 趟 = 停条件命中**（详见 ③ 与 ④）：
#     `RELEASED rc=1 held=911 s`｜`步骤通过 25 ❌ 失败 2`｜`用例通过 831 跳过 2`｜`SKIP_GUARD=PASS x_state=available violations=none`｜
#     `结论：❌ 失败项：Windowing.Tests COLUMN-FLOOR`。红#1 = `COLUMN-FLOOR`（**设计内声明类，预期**）；
#     🔴 **红#2 = `Windowing.Tests`（非声明类）** ⇒ **我按任务书停手，未冻结**，报主控裁定。
#     根因 = 闸门 `[0]` 段复用**别人的** `Xvfb :185`（1024x768；`/proc/*/environ` 实测属 **W128A**，非我先前误判的"重启孤儿"）
#     而非自起 1280x1024 ⇒ 三条 `[X11Fact]`/`[X11Theory]` **假红**（`831` vs `#51` 的 `875`，差 **44 = Windowing 整套件**）。
#     主控**禁止杀 `:185`**（那是 W128A 在跑的批次），**授权**我加**几何守卫** ⇒ 见下。
#   【步骤⑦b·几何守卫＋重跑】**几何守卫 ＋ 重跑**（授权 = 主控 2026-09-23 10:2x；见 `docs/WAVE52-PREREGISTRATION.md` §R1）
#     `verify-all.sh` `1fb43fc4522c8784` → `cb30ccae51a7607a`（`[0]` 段）→ **`0cdd12547a634b37`**（`x_recheck_alive()` ＋ 定义提顶层）；
#     **两处复用点同趟加** —— 只改 `[0]` 是**只修一半**：`x_recheck_alive()`（`D-G59` 的中途复核换显示）**同样"只看能连上"**
#     ⇒ 中途会换到别人的几何。`bash -n` rc=0；`VERIFYALL_SELF=PASS names=27 decl=27 gen=#52`（**步数不变**）。
#     **两极化实测**（对真件提取的真段落跑；**只注入 `pgrep` 的候选清单**，几何探测与自起都是真的）：
#      ① 只有 `:185`(1024x768) ⇒ `⏭ X-REUSE=skipped-geom-mismatch display=:185 实测几何=1024x768（空=取不到）≠ 本闸门要求 1280x1024 ⇒ **跳过它**`
#         ＋ `✅ X-REUSE=self-started display=:99 -screen 0 1280x1024x24` ✓
#      ② 有 `:97`(**1280x1024**) ⇒ `✅ X-REUSE=reused display=:97（已运行的 Xvfb；几何 1280x1024 相符；注意不是 :99）`
#         且**没有自起新的** ⇒ **复用能力没被砍掉** ✓
#      ③（附加）`$DISPLAY_NUM=:99` 被一台几何不符者占着 ⇒ `skipped-geom-mismatch :99` ＋ **`self-started :100`**
#         （**避开被占号** ⇒ 不制造"Xvfb 起不来"这种**新**假红）✓
#     **重跑（第 2 趟）**：`HEAVYSLOT=ACQUIRED waited=375s`｜`RELEASED rc=1 held=854 s`（授权 1500）｜
#     **`步骤通过 26 ❌ 失败 1`**｜**`用例通过 875 跳过 2`**（**= `#51` 的 875** ⇒ `Windowing.Tests` **44/44 全过**）
#     ｜`SKIP_GUARD=PASS x_state=available x_died=0 violations=none`｜**`结论：❌ 失败项：COLUMN-FLOOR`**
#     ⇒ **恰好 1 处红，且就是设计内的声明类红** ⇒ **继续 ⑧ 冻结**。
#   【步骤⑧·冻结】`python3 $HOME/w21-verify/w27-freeze.py <冻前日志> <rows> '#52'` ⇒ 本文件即其 `TXT` 输入；
#     `PRE=/home/links-dev/w52-pre.sha`（**口径如实记**：本波产品位移在本车道开工**之前**已落定 ⇒ "改前值"不存在 ⇒
#     `PRE` 按 **`#51` 冻结块**九位**逐位重建**，键=路径、9 行；`~/w126a/make-pre52.py` 机械核过"每个值都逐字出现在
#     `#51` 块九位清单（`:47–:49`）里"）。⚠️ **仪器更正留痕**：`ACCEPTANCE-BASELINE.md` 里**没有** `# RE-FROZEN #50` 块
#     （只有 `#51`@`:25` 与 `#18`@`:1842`）⇒ "找下一个 `RE-FROZEN` 切上一代块"会**一路吃到 `#18`**（实测切出 1818 行）⇒ 改锚九位清单行。
#   【步骤⑨·冻后 `verify-all` ×2】两趟都必须**全绿 27/27**（含第 `[27]` 步 `NUL-BYTES`）；逐条读数与两趟对照写入 `~/w126a/STATUS.md`
#     与 `build/MilBridge/W126A-report.md`；关键机读行两趟**逐字相同**（运行期读数如 `mem_mb` 允许不同、**要如实记**）。
#     **冻后刻**再复算一次九位，与**冻前刻**成对并列（`pf` 两刻可能不同 —— `D-G92`，**不算失败**）。
#   【步骤⑩·记录／推送／app-local 刷新】写 `$HOME/w21-verify/w52-record.txt`（本文件；**冻后只许在末尾追加「冻后补记」段**）
#     ｜推送（fork 克隆 `~/netTest/GitProj/WPFOnLinux`）：**必须先 `cp` 真件**（克隆是独立检出，不自动跟随 `$R`）⇒
#       逐径 `git add`（**不许 `-A`／`--force`**）→ `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux` →
#       `git push origin feat-Linux` → **push 之后重新 fetch** ＋ 与 `ls-remote` **交叉核** ⇒ 逐件
#       `git cat-file blob HEAD:<path>` 与磁盘 `cmp` ⇒ `BYTECHECK ok=? mismatch=? nobody=?`
#     ｜app-local：`sync-applocal-authority.sh`（**显式补 `SCAN_ROOTS=…:tools`**）＋ `check-applocal-sync.sh --selftest`
#       ⇒ 现场 `STALE=0 DIVERGENT=0`（`UNEXPECTED=6` 在册，不当绿）。
# ── ③ 冻前 `verify-all` 的逐项读数（本件的冻结输入）─────────────────────────────
#   **第 1 趟（停条件命中，未用于冻结）**：日志 `~/w126a/logs/07-verify-all-pre.log`，
#     `HEAVYSLOT=ACQUIRED waited=55s`／`MEMOK avail=5979MB`／**`RELEASED rc=1 held=911 s`**；
#     `步骤通过 25 ❌ 失败 2`｜`用例通过 831 跳过 2`｜`结论：❌ 失败项：Windowing.Tests COLUMN-FLOOR`。
#     逐套件：`Commands 562`／`Rendering 166(+2)`／**`Windowing ❌`**／`HelloMil 19`／`ManagedLayer 76`／`Presentation 8`
#     （`562+166+19+76+8 = 831` ⇒ Windowing 的 41 个通过例因套件 rc=1 **未被计入**）。
#     `Windowing.Tests` 逐例：`失败: 3，通过: 41，已跳过: 0，总计: 44`：
#       `X11PresentationTargetTests.EventLoop_DeliversExpose_And_Close [FAIL]`／
#       `X11PresentationTargetTests.PresentationTarget_SatisfiesContract [FAIL]`／
#       `X11RealInputEventTests.MouseMove_DeliversMotionNotify_WithExactCoordinates(x: 473, y: 2) [FAIL]`
#     `[0]` 段逐字：`✅ 复用已运行的 Xvfb（实测 display :185，注意不是 :99）`、`DISPLAY=:185`、`X_STATE=available`。
#     ⇒ **非声明类红 ⇒ 停手**（任务书要求）。
#   **第 2 趟（本件的冻结输入）**：日志 `~/w126a/logs/07b-verify-all-pre2.log`，`RELEASED rc=1 held=854 s`。
#     `[0]` 段逐字：`✅ X-REUSE=reused display=:97（已运行的 Xvfb；几何 1280x1024 相符；注意不是 :99）`、`DISPLAY=:97`、`X_STATE=available`。
#     逐套件**六套件全绿**：`Commands 562/0`／`Rendering 166/2`／**`Windowing 44/0`**／`HelloMil 19/0`／`ManagedLayer 76/0`／`Presentation 8/0`
#     ⇒ `用例通过 875`（**与 `#51` 逐格相同**）。
#     **唯一那 1 处红 = 设计内声明类**（逐字母句）：`COLUMN-FLOOR ❌ (rc=1)`／
#       `COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline`／
#       `COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0
#        selfreport=PASS reg=d4e0080df6ec497c base=38e67e834430d75c corpus=0cebc0afd5142fbf`
#     其余 26 步**全绿**，其中关键机读行：
#       `BASELINESHA=PASS live=38e67e834430d75c decl=38e67e834430d75c`｜`BASELINEGEN=PASS decl_gen=#51 file_newest_gen=#51`｜`BASELINEDUP=PASS n=0`
#       `ARMLOG_SHA=PASS required=5 declared=5 pass=5 fail=0 noinfo=0`（**重钉后已转绿**）
#       `VERIFYALL_SELF=PASS names=27 decl=27 gen=#52 dup=0 order=OK prose=OK prereg=PASS vfile_sha16=0cdd12547a634b37`
#       `R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 win=938x938 win32shim=bd037229be8db4f6 pc=722e0ab8205b7c3f`
#       `NULBYTES=PASS files=1210 hits=0 bytes=252109905 canary=ok`｜`FP_INPUTS_HYGIENE=PASS`｜`SKIP_GUARD=PASS x_state=available x_died=0 violations=none`
# ── ④ `NOINFO` / 残余（逐条如实）────────────────────────────────────────────────
#   ① **第 1 趟冻前 `verify-all` 因停条件未用于冻结** —— 它的红#2（`Windowing.Tests`）根因**已定罪**
#      （闸门复用别人的 1024x768 X ⇒ 假红），并已由**几何守卫**修掉、第 2 趟**复绿 44/44** 佐证。
#      **但仍如实记一条边界**：那三例**在 1280x1024 下全过**并不能单独证明"它们的产品语义没问题"，
#      只证明"它们不再因**几何不符**而红"。
#   ② **`upstream/**`（6417 件）未测**（`NUL-BYTES` 步的 `NOINFO` 格）：该步的 `PASS` **只等于「声明覆盖面里 0 件含 NUL」**。
#   ③ **11 件无扩展名 ELF 只 `DIAG` 不判红**（`diag_noext_nonelf=0` ⇒ 本趟这 11 件**全是**真 ELF）。
#   ④ **`UNEXPECTED=6[DECL-GAP-EQ=6]` 未逐条归因**（`#49` 已认定为**在册**声明类缺口；本件只确认"不因本波变多"）。
#   ⑤ **`DEFREG_DECLDRIFT=1`（changed-route-files-since-DECL-GEN）**：`defect-registry-declared.tsv` 的
#      `DECL-GEN = 2026-09-23 09:02:37`，而 `docs/ROUTES.md` 在其后被别的车道改过 ⇒ 漂移标志立起。
#      **但检查器 `rc=0`、`DEFREG=PASS declared=138 route_ids=138` ⇒ `verify-all` 第 `[16]` 步是 ✅**（**本件实测**）
#      ⇒ **不构成步红**，我**没有**动那个声明表（它在我的禁改清单里）。⇒ **漂移的成因不在本车道**，`NOINFO`。
#   ⑥ **`pf` 的不可复现根因仍未抓到**（`D-G92`，`NOINFO`）：本波又添一条成对读数（`bc2c47ac7b067bad` →
#      `358136b0c806ee88`，同尺寸），但**真凶未明**；**要什么样的读数**：一个覆盖 PF **全部**编译输入的指纹。
#   ⑦ **我自造并作废的一趟**（`~/w126a/logs/diag-windowing-186.log`）：私有 `:186` 上单跑 `Windowing.Tests`
#      一直等槽（W128A 占着），结果被主控授权的"守卫＋重跑"取代 ⇒ 我按 PID 杀掉自己的三个进程，**该趟不作读数**。
#   ⑧ **`:185`（W128A 的）我没有碰、也没有杀**（主控明令）；本件的处置是"**闸门学会跳过它**"，不是"移走它"。
# ── ⑤ 内存三值与纪律偏离（逐条写）──────────────────────────────────────────────
#   · **授权上限**：整波 1200／五臂 1200／`verify-all` 1500／`build-shim.sh --all` 600／其余 300。
#     **实际**：整波 `held=177 s`／shim `2 s`／五臂 `352 s`／门禁 `167 s`＋`162 s`／冻前 `verify-all` 第 1 趟 `911 s`。
#     **无 `MAXHOLD_KILL`、无 `NOINFO reason=low-memory`。**
#   · **零 `pkill -f`**：全部按 PID。**探活读 `/proc/*/cmdline`**（`D-G93`）——⚠️ 我第一版用 `ps|grep -c 'w123a'` 得 `3`／`2`，
#     **那是把我自己的命令行数进去了**；换 `/proc` 法后三次全 0。
#   · ⚠️ **宿主重启打断过我一次**（`uptime -s` = 2026-09-23 09:45:54）：09:32:06 最后落盘 → 09:58:21 被主控接回。
#     **窗口内无在跑测量 ⇒ 无作废趟**；重启后我**逐项复算**了 ②–⑤ 的读数，**全部一致**。
#   · ⚠️ **我自造并作废的一趟**：为验证"几何是否那三例失败之因"，我在**私有 `:186`** 上单跑 `Windowing.Tests`；
#     它**一直等槽**（W128A 占着）⇒ 结果被主控授权的"守卫＋重跑"**取代** ⇒ 我按 PID 杀掉自己的 `176229/176268/176230`，
#     **该趟作废、不作读数**（日志 `~/w126a/logs/diag-windowing-186.log` 保留为证）。
#   · **写域**：本车道只写 `~/w126a/**`、`build/MilBridge/W126A-report.md`、本文件、`~/w52-pre.sha`、
#     `~/w21-verify/w27-freeze.py`（**只追加** `#52` 一代常数）、`docs/WAVE52-PREREGISTRATION.md`（授权内**追加** §R1），
#     以及收尾链按配方必须动的件（`verify-all.sh`（**授权**：几何守卫 ＋ `#52` 的四处声明）、冻结产物、
#     `docs/CURRENT-STATE.md:9` 机器行、`build/MilBridge/known-red.json`（重钉）、app-local 副本）。
#     产品**源**／`docs/ROUTES.md`／`KNOWN-DEFECTS` 类册件／`defect-registry-declared.tsv`／
#     `applier-audit-expected.txt`／既有牙／`~/w123a/**`／`~/w124a/**`／`~/w118a/**`／`~/w125a/**`／`~/w128a/**` **一字节未改**。
# ══════════════════════════════════════════════════════════════════════════════
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:358136b0c806ee88,provider:1f9511a7ef395bfe,win32shim:bd037229be8db4f6,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w126a/gate-e
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:358136b0c806ee88,provider:1f9511a7ef395bfe,win32shim:bd037229be8db4f6,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w126a/gate-e
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:358136b0c806ee88,provider:1f9511a7ef395bfe,win32shim:bd037229be8db4f6,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w126a/gate-e
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:358136b0c806ee88,provider:1f9511a7ef395bfe,win32shim:bd037229be8db4f6,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w126a/gate-e
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:358136b0c806ee88,provider:1f9511a7ef395bfe,win32shim:bd037229be8db4f6,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w126a/gate-e
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:358136b0c806ee88,provider:1f9511a7ef395bfe,win32shim:bd037229be8db4f6,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w126a/gate-e
# ⏪ **（历史，已被 `#52` 取代）**# RE-FROZEN #51 —— ✅ **当前冻结基线** —— 内容 = 收掉 `#51` 这一波（收尾链 10 步由车道 **W110A** 一步到底）：
#   **① `TASK-0108` 的 `H2` 落地（产品侧，波内两段）**：
#     `W101A`（`P1` 幂等发布 ＋ `P2` 尺寸真变补一拍 ＋ `P4` 重入闸）＋ `W106A`（`P3` 托管侧通知）
#     ⇒ 四格里 **3 格转绿**（`W101A`）＋ 两格转绿（`W106A`）⇒ 判据表 **`PASS=8 FAIL=0`**。
#     落点：`src/WpfGfx.Linux.Native/src/{win32_core.c,win32_internal.h,win32_msg.c}`（⇒ `win32shim` 位变，
#     导出 **546 → 547** = 新 `wpf_hints_publish`）＋ 新应用器
#     `src/WpfGfx.Linux.Native/tools/patch-presentationframework-window-minmax-notify.py`
#     ＋ 其生成件 `build/PresentationFramework.Linux/Window.Linux.cs`（⇒ `pf` 位变）。
#     **applier 登记两处由主控落**（`build/integration-wave.sh` ＋ `build/MilBridge/tools/applier-audit-expected.txt`）
#     ⇒ 本波 `APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0`（新件**显式执行**，
#     `APPLIER_AUDIT applier=patch-presentationframework-window-minmax-notify tier=A ok=3 miss=0`）。
#   **② `TASK-9907` 接线（仪器侧）**：`D-G82` 的牙 `build/MilBridge/tools/nul-bytes-check.sh`
#     接成 `verify-all` 第 `[27]` 步 `NUL-BYTES` —— **步数 26 → 27**；四处声明（`DECL` ／ `STEP-NAMES`
#     ／ 头注释口径句 ／ 预登记 H1）**同趟**改；该件**同趟纳入 `fp_inputs()` 覆盖面**（设计性变更）。
#     现场读数 = `NULBYTES=PASS files=1187 hits=0 bytes=250817074 canary=ok`（rc=0，≈0.4 s）。
#     ⚠️ **本步「绿」的边界逐字写死**：**声明覆盖面内 0 件含 NUL ≠ 全仓 0 件**；`upstream/**` 未测 ⇒ `NOINFO`；
#       11 件**无扩展名 ELF**（首 NUL 恒在偏移 7）只 `DIAG`、**不判红**。
#   **③ 装置侧（本波、非产品）**：`build/MilBridge/tools/wm-awaited.sh`（`57a852f6948e1c67`）＋
#     `build/MilBridge/tools/nul-bytes-check.sh`（`409d83d945f7d563`）；波尾新登记 `D-G88`…`D-G97`
#     （册 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 与 `defect-registry-declared.tsv` **由登记车道维护**，
#      本车道**一字节未改**）。
#   ── 九位（Release 权威件）**现算**（占位符由冻结器替换，值 = 冻结那一刻的现场）──────────
#     · `bridge` `feef049e9d0e313a`（5028208 B）｜`pc` `722e0ab8205b7c3f`（3601408 B）｜`pf` `bc2c47ac7b067bad`（6123520 B）｜`windowsbase` `2e4e46e539a72cd7`｜
#       `provider` `1f9511a7ef395bfe`｜`win32shim` `8392fc09564779a1`（327248 B）｜`wic_shim` `f7b3026c8c019be2`｜`hbtextline` `921ba9c65e9fb3be`（293165 B）｜`dwf` `ce3469f49efcbcfa`。
#     · ⚠️ **位移对账（相对 `#50` 冻结块那一栏）**：`pf` `f34bc297d19778fd` → `bc2c47ac7b067bad`｜`win32shim` `33352e5797031999` → `8392fc09564779a1`；
#       `bridge`／`pc`／`windowsbase`／`provider`／`wic_shim`／`hbtextline`／`dwf` **逐位未变**。
#     · ⚠️ **`PRE` 快照的口径（必写，否则后人会读成事故）**：`/home/links-dev/w51-pre.sha`（9 行、键=路径）
#       **不是**本车道开工前活取的 —— 本波两处位移在 **`W110A` 开工之前**就由波内车道（`W101A`／`W106A`）落定
#       ⇒ 现场不存在「改前值」⇒ `PRE` 按 **`#50` 冻结块**九位**逐位重建**（可复算：值就是 `#50` 块里那九个数；
#       生成脚本机械核过「每个值都逐字出现在 `#50` 冻结块里」）⇒ 冻结器算出的 `changed` = **本波相对 `#50` 冻结点**的位移本身。
#     · ⚠️ 本代 `prev_pc`=722e0ab8205b7c3f／`prev_pf`=f34bc297d19778fd／`prev_wsh`=33352e5797031999／`prev_wb`=2e4e46e539a72cd7／`prev_dwf`=ce3469f49efcbcfa（= `PRE`）。
#   ── 🔴 **`pf` 这一格不是构建身份（主控裁定，`D-G92`；本波第二次现场再证）** ────────────────
#     **`pf` 这一格不是构建身份**：同源、同命令、逐字相同的整波重建**可给出不同字节**。
#     `#50` 已记四条成对读数；**本波（`#51`）再加一条**：本车道开工时 `pf` = `215c856cbca9922b`，
#     跑完**整波重建**（`WAVE_OWNER=W110A bash build/integration-wave.sh`，`rc=0`、失败步 0）之后
#     = `bc2c47ac7b067bad` —— **同尺寸 6,123,520 B**、源指纹 `ARTIFACT_SRC_FP proj=PresentationFramework
#     fp=01a078bf78c6ed18 n=1363 peer_fp=0e31c2dc0c4e31c4 peer_n=9 state=written`。
#     ⇒ 本格**只作「当下那一刻的现场值」**，**不许**被后人当漂移／回归判据。
#   ── 冻前／冻后**成对九位**（主控要求必写）────────────────────────────────────────────
#     · **冻前刻**（本件写盘那一刻，现场 `sha256sum` 复算）= **本块九位那一栏**。
#     · **冻后刻**（本件写盘之后、冻后两趟 `verify-all` 之后各复算一次）——⚠️ **该读数在物理上不可能落在本块内**：
#       本块与 `docs/CURRENT-STATE.md:9` 的机器行**同趟写盘、必须逐字自洽**（`BASELINE-SHA` 比的就是这份整份 sha16），
#       **冻后不许再改本件**（改了 `BASELINE-SHA`／`BASELINEDUP` 立刻红）。⇒ 成对读数的**后半**逐位并列在
#       `build/MilBridge/W110A-report.md` §5 与 `~/w110a/STATUS.md`（同趟现场算，命令 `bash ~/w95a/nine.sh`）。
#     · **判据先写死（后取，`W110A` 写盘前登记在 `~/w110a/criteria.md` C8-c）**：预测 = 冻后刻与冻前刻**逐位相同**
#       （特别是 `pf`：冻后两趟 `verify-all` 只做**增量构建**）。**失败判据**：任一位不同 ⇒ 必须在 `W110A-report.md`
#       里**逐位并列并点名**；其中 **`pf` 不同不算失败**（本节上一条已裁明它不是构建身份）。
#   ⚠️ **`BRIDGE_SRC_FP` = `0a8f69b3c5fabd43`**（上一代 `0a8f69b3c5fabd43`，**两侧同值**：现树 == 发布记录；
#     `WPTD_BRIDGE_SRC_STALE=no basis=pub=0a8f69b3c5fabd43 now=0a8f69b3c5fabd43 so_file_match=yes`）⇒ `close-wave.sh` 的桥身份自检**会过**。
#   **臂日志**：本波 `tline` 位变字节（`6ce993ad974d32ad` → `9d29470d63791d64`，运行相关字段
#     ⇒ **非产品位移**）⇒ 按纪律**重取五臂**（`ARMS_OUT=$HOME/w110a/arms bash build/MilBridge/tools/retake-arms-w23.sh`，
#     `rc=0`、`held=318 s`、`ARMS_DISPLAY=:97 source=reused`）；其余四臂与 `#50` 冻结值**逐位相同**。五臂判词：
#     `tline` 通过 22/失败 2（两条既有 ❌，与 `#50` 逐字相同）｜`tab-zero` 退出码=1（唯一失败 = 在册 `notab-control@w40@em24@RTL@tab0`）｜
#     `tab-anchor` 退出码=0（`START 绿=615`／`OVERFLOWED 绿=421`）｜`tab-rtl` 退出码=0｜`textlineproto` 通过 10/失败 0。
#   **臂日志聚合（两种口径都算，`#31` 起同趟写）**：`cat` 口径 = `020e5497c0c2a18f`；`find|sort|xargs` 口径 = `4d2bb03340753dea`。
#   **`inputs_fp`** = `58a6c0945b7d535830ce3e3e4f25752b68f3714d3f35f540253eca6e69b3dd36`（上一代 `ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48`）。本代 `inputs_fp` 的位移**可逐条归因**（覆盖面 148 → 149 件）：
#     ① `build/MilBridge/tools/nul-bytes-check.sh` 是本波**新纳入** `fp_inputs()` 的（`TASK-9907` 接线动作
#        —— 仓内纪律「判据改了自己得有人看着」，与 `#50` 纳入两件 R-GATE 判据件同族）；
#     ② `build/MilBridge/known-red.json`（本波步骤⑤重钉：`8a0c0f221e35f42b` → `089b7324ba12e022`）**本来就在**覆盖面内 ⇒ 必变；
#     ③ 波内产品改动也有几件在覆盖面内（`src/WpfGfx.Linux.Native/src/win32_{core.c,msg.c,internal.h}`
#        ＋ 新应用器 `patch-presentationframework-window-minmax-notify.py`）⇒ 同样必变。
#     ⚠️ 验收动作（`verify-all` 单跑）**不动** `inputs_fp`（现场复算：跑前跑后同值）。
#   **`known-red.json`**：`8a0c0f221e35f42b`（本波开工，`#50` 重钉件的后继）→ **`089b7324ba12e022`**（步骤⑤ `repin-generation.py --why` 重钉）；
#     JSON diff **只有 3 处语义**：`generation.arm_logs.tline`／`arms_retaken`（`history` 追加 ＋ `when`/`why`）／`evidence_log_sha256`；
#     `entries[*].caliber` 改动字段数 = **0**；`--check` 前 `FAIL n=2` → 后 **`REPIN_GENERATION=PASS`**。
#     备份：`~/w110a/backup/known-red.before-repin.json`（与 before 逐位相同 ⇒ 备份有效）。
#   **`verify-all.sh` 的世代声明**：`gen=#50` → **`#51`**（`VERIFYALL-STEPS-DECL: 27 gen=#51`；**加一步** 26 → 27）。
#     现场读数：`VERIFYALL_SELF=PASS names=27 decl=27 gen=#51 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=1aa2ae4e94827cf3`。
#   **`docs/CURRENT-STATE.md:9` 的机器行**：同趟改成 `gen=#51`（`BASELINE-SHA` 判的就是它 ⇔ 本件整份 sha16）。
#   【外挂声明：`D-G27` 的读者要读的 4 类行】⚠️ 谁改它们谁要让读者一起绿。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=9d29470d63791d64
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【冻前那 1 处声明类红（**这是设计，不是失败**）】`verify-all` 第 `[14]` 步 `COLUMN-FLOOR` 在**冻前必红**：
#     `COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline`（冻结块还是 `#50` 的 `6ce993ad974d32ad`，而臂已重取为 `9d29470d63791d64`）
#     ＋ `COLUMN_FLOOR_SELFREPORT=PASS` ⇒ 形态**逐字命中** `w27-freeze.py` 的 `_is_declaration_class()`
#     （`COLUMN_FLOOR_ARMLOG=FAIL` ∧ `selfreport=PASS`）⇒ 冻后同一批检查器**必须转绿**（`ARMLOG_SHA=PASS 5/5` ＋ `COLUMN_FLOOR=PASS`）。
#     ⚠️ 现场 `n_ok=4`（`n_decl=5 = n_ok 4 ＋ bad 1`，`bad` 恰好只剩 `tline` 一个名）；`reg=089b7324ba12e022 base=1f4189c1257737a9`。
# ── ① 本波改了什么（逐件 sha16，改前 → 改后）────────────────────────────────────
#   **产品/构建件**（值进九位；改前 = `#50` 冻结块那一栏）：
#     · `src/WpfGfx.Linux.Native/src/{win32_core.c,win32_internal.h,win32_msg.c}`（**W101A** `TASK-0108` `H2`：
#       `P1` 幂等发布／`P2` 尺寸真变补一拍／`P4` 重入闸）⇒ `win32shim` `33352e5797031999` → **`8392fc09564779a1`**
#       （导出 546 → 547 = 新 `wpf_hints_publish`；`bash src/WpfGfx.Linux.Native/build-shim.sh --all` 复跑 rc=0）
#     · `src/WpfGfx.Linux.Native/tools/patch-presentationframework-window-minmax-notify.py`（**W106A** 新建应用器，
#       `ce76657c1b020562`）＋ 生成件 `build/PresentationFramework.Linux/Window.Linux.cs`（`5a0449ccc02e5433`）
#       ⇒ `pf` `f34bc297d19778fd` → **`bc2c47ac7b067bad`**（⚠️ 见冻结块的「不是构建身份」）
#   **仪器/判据件**（本波新接线；**已进** `fp_inputs()` 覆盖面 —— `TASK-9907` 接线动作）：
#     · `build/MilBridge/tools/nul-bytes-check.sh` `409d83d945f7d563`（**W97A** 新建，**W110A** 接线为第 `[27]` 步）
#     · `verify-all.sh` `227623000850ca5d` → **`1aa2ae4e94827cf3`**（四处声明 ＋ 第 `[27]` 步本体）
#     · `build/close-wave.sh` `f440ccdb4e29a942` → **`c757fd5058f1bfd4`**（`fp_inputs()` 名单纳入上面那件判据件）
#     · `build/MilBridge/tools/wm-awaited.sh` `57a852f6948e1c67`（装置侧，**不在**覆盖面内）
#   **登记/地图件**（**由登记车道维护，本车道未改**）：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`｜`docs/ROUTES.md`｜
#     `build/MilBridge/tools/defect-registry-declared.tsv`｜`build/MilBridge/known-red.json`（见冻结块）。
#   **冻结产物**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（本件 = 它的新首部）｜`docs/CURRENT-STATE.md:9`（机器行同趟改）。
# ── ② 收尾链每步读数（命令 + rc + 关键原文）──────────────────────────────────
#   【步骤①·接线】四处逐字（详见 `W110A-report.md` §1）：`DECL` 最上面新插 `27 gen=#51`（旧 `26 gen=#50` **原样保留**）｜
#     头注释口径句含**逐字**半句「**`#51` 收官起 = 27 步**」｜`STEP-NAMES` 第一行末追加 ` | NUL-BYTES`｜
#     步骤本体插在 `[26] R-GATE` 的 `run_step` 之后（`:891`）。现场：`grep -c '^run_step "'` = **27**、
#     `VERIFYALL_SELF=PASS names=27 decl=27 gen=#51 dup=0 order=OK prose=OK prereg=PASS`（rc=0）、
#     新步单跑 `NULBYTES=PASS files=1186 hits=0`（rc=0）。
#   【步骤②·整波重建】`WAVE_OWNER=W110A bash build/integration-wave.sh`（槽内 `--max-hold 1200`，理由：整波 28 应用器＋
#     依赖序重建＋产物发布，`#50` 同量级 ⇒ 300 s 装不下）⇒ `HEAVYSLOT=MEMOK avail=2459MB`／
#     **`RELEASED rc=0 held=177 s`**；`APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0`；`失败步骤 0`；
#     波前＝波后输入指纹 `9a265c5a2f9e7c4c…`。native 另跑 `build-shim.sh --all`（`rc=0 held=2 s`，导出 547）。
#   【步骤③·WIC 权威件同步】显式补根（`D-G91`：默认根漏 `$REPO/tools` ⇒ 会打 `STALE=0` 假绿）：
#     `AUTH_ROOT=$R SCAN_ROOTS=$R/build:$R/tests:$R/samples:$R/src:$R/tools bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh --apply`
#     ⇒ `APPSYNC-REFRESH=refreshed=0 newer=0 applied=1`（**没有落单者** ⇒ 写 0 件）；校验器
#     `MISMATCH=0（STALE=0 NEWER-DIFF=0）MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=6] DIVERGENT=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`
#     ⇒ **`STALE=0 DIVERGENT=0`**（`UNEXPECTED=6` 是**在册**声明类缺口：不当绿、不改判据）。
#   【步骤④·五臂重取】预测**先写**（`criteria.md` C4：只有 `tline` 可能变）⇒ 读数**命中预测**：
#     `tline` `6ce993ad974d32ad` → **`9d29470d63791d64`**；`tab-zero`/`tab-anchor`/`tab-rtl`/`textlineproto` **逐位未变**；
#     判词与 `#50` 逐字相同。`HEAVYSLOT=MEMOK avail=2223MB`／`RELEASED rc=0 held=318 s`（授权 1200：`#50` 实测 307 s）。
#   【步骤⑤·重钉】`repin-generation.py --check` 前 `FAIL n=2` → `--why '…'`（逐条写明本波改动）⇒ `REPIN_GENERATION=APPLIED`
#     → `--check` 后 **`PASS`**；`known-red.json` `8a0c0f221e35f42b` → `089b7324ba12e022`。
#   【步骤⑥·应用门禁 ×2】两趟**都写 rows**（第 2 趟写另一本，避免追加语义把 6 行变成 12 行）：
#     第 1 趟：`WPTD_RUN_DIR=$HOME/w110a/gate-e WPTD_BASELINE_OUT=$HOME/w110a/gate-rows.txt … run-wpftextdemo.sh 60 --tier both`
#       ⇒ `HEAVYSLOT=MEMOK avail=2397MB`／**`RELEASED rc=0 held=167 s`**；`WPTD_TIER=default rep=1/2/3 RESULT=PASS`
#       ＋ `WPTD_TIER=env rep=1/2/3 RESULT=PASS` ⇒ **机读行 6/6 `result=PASS`**；`WPTD_SUMMARY=PASS tiers_passed=2/2`、
#       `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_BRIDGE_SRC_STALE=no basis=pub=0a8f69b3c5fabd43 now=0a8f69b3c5fabd43 so_file_match=yes`；
#       `rows.txt` sha16 = `e97f301863ca58a9`（`BASELINE` 6 行 / `result=PASS` 6 / `result=FAIL` 0）。
#     第 2 趟（`--no-build`，写 `gate-rows-f.txt`）：**`RELEASED rc=0 held=158 s`**、三条机读行逐字相同 ⇒
#       `rows-f.txt` sha16 = `808a2ba7c3cd9f33`（6/6 `result=PASS`）。两本 `BASELINE` 六行的 config 逐项相同
#       （`pc:`＋`722e0ab8205b7c3f`／`pf:`＋`bc2c47ac7b067bad`／`win32shim:`＋`8392fc09564779a1` = **终态九位**）⇒ **门禁本波 12/12 PASS**。
#   【步骤⑦·冻前 `verify-all`（27 步）】`HEAVYSLOT=MEMOK`／**`RELEASED rc=1 held=862 s`**（授权 1500：`#49`/`#50` 实测 ≈16.3 min）：
#     **`步骤通过 26 ❌ 失败 1`**、`用例通过 875 跳过 2`、`SKIP_GUARD=PASS x_state=available violations=none`、
#     **`结论：❌ 失败项：COLUMN-FLOOR`** —— **唯一那 1 处就是设计内的声明类红**（`COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline`
#     ＋ `COLUMN_FLOOR_SELFREPORT=PASS`）；第 `[27]` 步 `NUL-BYTES` ✅（`NULBYTES=PASS files=1187 hits=0 bytes=250817074 canary=ok`）。
#     ⇒ **无第 2 处非声明类红** ⇒ 不必停手。
#   【步骤⑧·冻结】`python3 $HOME/w21-verify/w27-freeze.py ~/w110a/logs/07-verify-all-pre.log ~/w110a/gate-rows.txt '#51'`
#     ⇒ 本文件即其 `TXT` 输入；`PRE=/home/links-dev/w51-pre.sha`；`nstep=27`、`875 通过 2 跳过`。
#   【步骤⑨·冻后 `verify-all` ×2】两趟都必须全绿（含第 `[27]` 步 `NUL-BYTES`）；逐条读数见 `build/MilBridge/W110A-report.md` §6 与 `~/w110a/STATUS.md`。
#   【步骤⑩·记录／推送／app-local 刷新】
#     · 推送（fork 克隆 `~/netTest/GitProj/WPFOnLinux`）：逐径 `git add`（**不许 `-A`／`--force`**）→
#       `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`（**refspec 陷阱**）→ `git push origin feat-Linux` →
#       **push 之后重新 fetch** 再核 `rev-parse HEAD` == `ls-remote origin HEAD`、`--symref` 仍 `feat-Linux`；
#       逐件 `git cat-file blob HEAD:<path>` 与磁盘 `cmp` ⇒ `BYTECHECK ok=? mismatch=? nobody=?`（见 `W110A-report.md` §7）。
#     · `TASK-9906` 类的 app-local 刷新：`sync-applocal-authority.sh`（**必须显式补 `SCAN_ROOTS=…:tools`**，`D-G91`）
#       ＋ `check-applocal-sync.sh` ⇒ 现场 `STALE=0 DIVERGENT=0`（`UNEXPECTED=6[DECL-GAP-EQ=6]` 是**在册**缺口，不当绿）。
# ── ③ 冻前 `verify-all` 的逐项读数（本件的冻结输入）─────────────────────────────
#   日志 `~/w110a/logs/07-verify-all-pre.log`（`RELEASED rc=1 held=862 s`）：`步骤通过 26 ❌ 失败 1`／`用例通过 875 跳过 2`／
#     `SKIP_GUARD=PASS x_state=available violations=none`／`结论：❌ 失败项：COLUMN-FLOOR`。
#     · ① `COLUMN-FLOOR ❌`（**设计内**）—— 逐字形态 `COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline` ＋ `COLUMN_FLOOR_SELFREPORT=PASS`
#       ＋ 总判 `COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0
#       selfreport=PASS reg=089b7324ba12e022 base=1f4189c1257737a9 corpus=0cebc0afd5142fbf`（第 `[14]` 步）。
#     · 其余 **26 步全绿**，含第 `[27]` 步 `NUL-BYTES` ✅ 与 `VERIFYALL-SELF` ✅（`names=27 decl=27 gen=#51`）。
# ── ④ `NOINFO` / 残余（逐条如实）────────────────────────────────────────────────
#   ① **`pf` 不可复现的根因**（`NOINFO`，`D-G92`）：本波又观察到一个新的成对读数（收尾链整波重建前后 `215c856cbca9922b` → `bc2c47ac7b067bad`），
#      但**真凶仍未抓到**（重活禁跑额外重建趟）。**要什么样的读数**：一个覆盖 PF **全部**编译输入的指纹。
#   ② **`upstream/**`（6417 件）未测**（`NUL-BYTES` 步的 `NOINFO` 格）：本步的 `PASS` **只等于「声明覆盖面里 0 件含 NUL」**。
#   ③ **11 件无扩展名 ELF 只 `DIAG` 不判红**（`diag_noext_nonelf=0` ⇒ 本波这 11 件**全是**真 ELF）。
#   ④ **`UNEXPECTED=6[DECL-GAP-EQ=6]`** 未逐条归因（`#49` 已认定为**在册**声明类缺口；本件只确认「不因本波变多」）。
#   ⑤ 任务书给的 `inputs_fp` 旧值 **与现场不符**（见 `W110A-report.md` §1.5）：现场重算 = `82b3adf3cf52c660…`，
#      机械归因 = 覆盖面内 5 件（`integration-wave.sh` ＋ 新应用器 ＋ 三件原生 C 源）在任务书写成之后被改过 ⇒ **以现场为准**。
# ── ⑤ 内存三值与纪律偏离（逐条写）──────────────────────────────────────────────
#   · 短步照 300/280：门禁每趟（held **167 s**／**158 s**）。
#   · **三条长步放宽（主控授权，理由逐条）**：整波 `--max-hold 1200`（实际 held **177 s**）／五臂 `--max-hold 1200`
#     （实际 **318 s**；`#50` 实测 307 s ⇒ 300 装不下）／`verify-all` `--min-avail 1500 --max-hold 1500 -- timeout 1450`
#     （实际 **862 s**；`#49`/`#50` 实测 ≈16.3 min ⇒ 300 s 只会拿 `MAXHOLD_KILL`＝作废趟）。
#     `build-shim.sh --all` `--max-hold 600`（实际 2 s）。
#   · `--min-avail 1500`（内存闸门）**未动**；全程拿到 `HEAVYSLOT=MEMOK`，无 `NOINFO reason=low-memory`、无 `MAXHOLD_KILL`。
#   · **零 `pkill -f`**：全部按 PID（臂/门禁的 Xvfb 由各自 runner 自收）。
#   · **写域**：本车道只写 `~/w110a/**`、`build/MilBridge/W110A-report.md`、本文件、`~/w51-pre.sha`、
#     `~/w21-verify/w27-freeze.py`（**只追加** `#51` 一代常数），以及收尾链按配方必须动的件
#     （`verify-all.sh`、`build/close-wave.sh` 的 `fp_inputs()`、冻结产物 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`、
#      `docs/CURRENT-STATE.md:9` 机器行、`build/MilBridge/known-red.json`（重钉）、app-local 副本）。
#     产品源／`docs/ROUTES.md`／`KNOWN-DEFECTS.md`／`defect-registry-declared.tsv`／`applier-audit-expected.txt`／
#     `r-gate-step.sh`／`nul-bytes-check.sh`／`wm-awaited.sh`／`~/w105a/**`／`~/w109a/**` **一字节未改**。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:bc2c47ac7b067bad,provider:1f9511a7ef395bfe,win32shim:8392fc09564779a1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w110a/gate-e
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:bc2c47ac7b067bad,provider:1f9511a7ef395bfe,win32shim:8392fc09564779a1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w110a/gate-e
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:bc2c47ac7b067bad,provider:1f9511a7ef395bfe,win32shim:8392fc09564779a1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w110a/gate-e
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:bc2c47ac7b067bad,provider:1f9511a7ef395bfe,win32shim:8392fc09564779a1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w110a/gate-e
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:bc2c47ac7b067bad,provider:1f9511a7ef395bfe,win32shim:8392fc09564779a1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w110a/gate-e
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:bc2c47ac7b067bad,provider:1f9511a7ef395bfe,win32shim:8392fc09564779a1,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w110a/gate-e
# ⏪ **（历史，已被 `#51` 取代）**# RE-FROZEN #50 —— ✅ **当前冻结基线** —— 内容 = 收掉 `#50` 这一波（步骤 1–4 由车道 **W94A** 落定、步骤 5–9 由车道 **W95A** 跑完）：
#   **① `TASK-0702`／`R-GATE`**：把「连续点击／交互响应」从**仓外仪器**（`$HOME/w47b-click.sh`，`#47` 车道 W47B 留）
#      **收编进仓**并接进 `verify-all` 第 `[26]` 步（`R-GATE（连续交互）`；13 格判据逐格继承 `docs/WAVE49-PREREGISTRATION.md` §3 B3 的六格表
#      ＋ 装置自加的 `⑦` 承重连续腿／`⑧` 像素通道；判据唯一实现 = `build/MilBridge/tools/r-gate-step.sh`）。
#   **② `TASK-0108` 前哨**：本波**只登记** `D-G88`／`D-G89`／`D-G90` 三号（产品缺陷／装置判据恒真／仪器硬截断），
#      分节标题同趟扩写（`## `#49` 波前新登记 … ＋ `#50` 波尾新登记（`D-G88`…`D-G90`，2026-09-22）`）。
#   **③ 产品侧修法**（波内车道落，逐件可归因，见 `===RECORD===` ①）：`D-G85`（`pc`）、`A2/A3`（`pf`）、
#      `D-G83`＋`D-G81`（`win32shim`）、GIF frames（`wic_shim`）；`dwf` **无源改动可归因**（见下 ⚠️）。
#   **④ `D-G42` 波内复发 ＋ 本波修掉**（**冻前那第 2 处红的处置**，主控裁定"(a) 修那 9 处"）：
#      本波新建的**两件**被同一族（`pipefail` ＋ 管道左侧被 SIGPIPE 杀死 ⇒ 判据翻转）命中 **9 处** ——
#      `build/MilBridge/tools/r-gate-step.sh`（`TASK-0702` 的**判据唯一实现**）**8** 处
#      ＋ `build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh:255` **1** 处。
#      **方向 = 假 FAIL**，且 `r-gate-step.sh` 的 `c11`（"窗口内连做三下、各自 EVT 都出"）**正是承载 `D-G55` 的那一格**
#      ⇒ **证据切片一旦超过 64 KiB 管道缓冲，`R-GATE` 会假红**。**本波已修**（判据文本一字未动，只换喂法：
#      `printf '%s' "$S" | grep -qE PAT` → `grep -qE PAT <<<"$S"`；`grep … | head -8 | sed … || echo "（无）"` → 先收进变量再分两路印）。
#      成对读数：牙 **rc=0／`undeclared_hit=0`**；`--selftest` **21/21**；私有副本把 `c11` 载荷换成 ≈250 KB ⇒
#      **旧写法 `S1 => NO`＋`crit=12/13`＋`R_GATE_SELFTEST=FAIL 18/21`**、**新写法同载荷 `S1 => yes`＋`crit=13/13`＋`21/21`**、
#      **阴性对照不放松**（`S11` 缺 `seq-combo` 时两版都 `FAIL`）。**登记**：该族**已有编号 `D-G42`** ⇒ **不新增编号**，
#      只在 `D-G42` 条目里加一条 bullet（`KNOWN-DEFECTS.md` `aec62c485d5010b9` → `368b293d4ef7f1cb`）＋ `--emit` 重生成 tsv
#      ⇒ **`DEFREG=PASS declared=126 route_ids=126`（编号总数不变）**、`DEFREG_DECLDRIFT=0`。
#      ⚠️ 该族**禁止用"写进 `DECL` 声明表"转绿**（`DECL` 口径只许写**不在本车道写域**的真 HIT；对本波自建件用它 = **压绿**）。
#   ── 九位（Release 权威件）**现算**（占位符由冻结器替换，值 = 冻结那一刻的现场）──────────
#     · `bridge` `feef049e9d0e313a`（5028208 B）｜`pc` `722e0ab8205b7c3f`（3601408 B）｜`pf` `f34bc297d19778fd`（6123008 B）｜`windowsbase` `2e4e46e539a72cd7`｜
#       `provider` `1f9511a7ef395bfe`｜`win32shim` `33352e5797031999`｜`wic_shim` `f7b3026c8c019be2`｜`hbtextline` `921ba9c65e9fb3be`（293165 B）｜`dwf` `ce3469f49efcbcfa`。
#     · ⚠️ **位移对账（相对 `#49` 冻结块那一栏）**：`pc` `56ee75ced8d6aece` → `722e0ab8205b7c3f`｜`pf` `6375fabf89ac7fef` → `f34bc297d19778fd`｜
#       `win32shim` `c493639d15678803` → `33352e5797031999`｜`wic_shim` `56278c14b4ecd672` → `f7b3026c8c019be2`｜`dwf` `de2d555105b7d04b` → `ce3469f49efcbcfa`；
#       `bridge`／`windowsbase`／`provider`／`hbtextline` **逐位未变**。
#     · ⚠️ **`PRE` 快照的口径（必写，否则后人会读成事故）**：`/home/links-dev/w50-pre.sha`（9 行、键=路径）
#       **不是**本车道开工前活取的 —— 本波五处位移在 **`W95A` 开工之前**就由波内车道／整波重建落定
#       ⇒ 现场不存在"改前值"⇒ `PRE` 按 **`#49` 冻结块**九位**逐位重建**（可复算：值就是 `#49` 块里那九个数）。
#       因此冻结器算出的 `changed` = **本波相对 `#49` 冻结点**的位移本身。
#     · ⚠️ **同时记一个更窄的口径**（两个都写、都标清，免得拿错基准）：`W94A` **活取**的"波前九位"是
#       `pc 5aa6361a5ba02991`／`pf 2a5b7641f6fba0fb`／`win32shim 33352e5797031999`／`wic_shim f7b3026c8c019be2`／`dwf de2d555105b7d04b`
#       ⇒ 相对它，**本波之内**真正位移的只有 `pc`／`pf`／`dwf`；`win32shim`／`wic_shim` 的位移发生在 `#49` 冻结之后、`W94A` 开工之前。
#     · ⚠️ 本代 `prev_pc`=56ee75ced8d6aece／`prev_pf`=6375fabf89ac7fef／`prev_wsh`=c493639d15678803／`prev_wb`=2e4e46e539a72cd7／`prev_dwf`=de2d555105b7d04b（= `PRE`）。
#   ── 🔴🔴 **`pf` 这一格不是构建身份（主控裁定，必读；逐字照录）** ────────────────────────────
#     **`pf` 这一格不是构建身份**：同源、同命令、逐字相同的整波重建**可给出不同字节**。
#     四条成对读数（四趟整波，每趟预测先写后取）：`881c56e26808269f`／`decd920092287b03`／`581c864a7f2ad36c`／**`f34bc297d19778fd`**；
#     而 `ARTIFACT_SRC_FP proj=PresentationFramework fp=5b38ea7420b26377 n=1362` **四趟逐位相同**，
#     隔离 `dotnet build -t:Rebuild` **连跑两次同值**（`decd920092287b03` ×2）。
#     二进制级差异 = 同尺寸（6123008 B）、**72 字节**不同，簇全在 PE `TimeDateStamp` ＋ MVID ＋ 调试目录（**不是**时间戳随机）。
#     ⇒ 本格**只作"当下那一刻的现场值"**，**不许**被后人当漂移／回归判据；真凶留 `NOINFO`（复算配方见 `build/MilBridge/W94A-report.md` §3.4 与 §7.1）。
#     ⇒ 同理：本波 `dwf` **无源改动可归因**（`NOINFO`），但它的值**四趟整波稳定** ⇒ 可用；"为什么第一趟会变"是 `NOINFO`。
#   ── 冻前／冻后**成对九位**（主控要求必写）────────────────────────────────────────────
#     · **冻前刻**（本件写盘那一刻，现场 `sha256sum` 复算）= **本块九位那一栏**（即 `feef049e9d0e313a`／`722e0ab8205b7c3f`／`f34bc297d19778fd`／`2e4e46e539a72cd7`／`1f9511a7ef395bfe`／`33352e5797031999`／`f7b3026c8c019be2`／`921ba9c65e9fb3be`／`ce3469f49efcbcfa`）。
#     · **冻后刻**（本件写盘之后、冻后两趟 `verify-all` 之后各复算一次）——⚠️ **该读数在物理上不可能落在本块内**：
#       本块与 `docs/CURRENT-STATE.md:9` 的机器行**同趟写盘、必须逐字自洽**（`BASELINE-SHA` 比的就是这份整份 sha16），
#       **冻后不许再改本件**（改了 `BASELINE-SHA`／`BASELINEDUP` 立刻红）。⇒ 成对读数的**后半**逐位并列在
#       `build/MilBridge/W95A-report.md` §5 与 `~/w95a/STATUS.md`（同趟现场算，命令 `bash ~/w95a/nine.sh`）。
#     · **判据先写死（后取，`W95A` 写盘前登记）**：预测 = 冻后刻与冻前刻**逐位相同**（特别是 `pf`：冻后两趟 `verify-all`
#       只做**增量构建**，PF 的 `obj/` 与 csproj 在整波末态下已最新 ⇒ 不重编 ⇒ 字节不动）。**失败判据**：任一位不同
#       ⇒ 必须在 `W95A-report.md` 里**逐位并列并点名是哪一位**；其中 **`pf` 不同不算失败**（本节上一条已裁明它不是构建身份）。
#   ⚠️ **`BRIDGE_SRC_FP` = `0a8f69b3c5fabd43`**（上一代 `0a8f69b3c5fabd43`，**两侧同值**：现树 == 发布记录 `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/bridge-src-fp.txt`）
#     ⇒ `close-wave.sh:301-304` 的桥身份自检**会过**；`SRC_ROOTS=src/WpfGfx.Linux build/MilBridge`、`BRIDGE_SRC_N=78`。
#   **臂日志**：本波 `tline` 位变字节（`2103f88183b17a6a` → `6ce993ad974d32ad`，36 行 diff **全部**是运行相关字段
#     ⇒ **非产品位移**）⇒ 按纪律**重取五臂**（`ARMS_OUT=$HOME/w94a/arms bash build/MilBridge/tools/retake-arms-w23.sh`，`rc=0`、`held=307s`、
#     `ARMS_DISPLAY=:97 source=self-started`）；其余四臂与 `#49` 冻结值**逐位相同**。五臂判词：
#     `tline` 通过 22/失败 2（两条既有 ❌，与 `#49` 逐字相同）｜`tab-zero` 退出码=1（唯一失败 = 在册 `notab-control@w40@em24@RTL@tab0`）｜
#     `tab-anchor` 退出码=0（`START 绿=615`／`OVERFLOWED 绿=421`）｜`tab-rtl` 退出码=0｜`textlineproto` 探针 4/2 ＋ 通过 10/0。
#   **臂日志聚合（两种口径都算，`#31` 起同趟写）**：`cat` 口径 = `f59631f6af2f6c43`；`find|sort|xargs` 口径 = `60c635413a71ee83`。
#   **`inputs_fp`** = `ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48`（上一代 `9f2199b212bed2b212035f87ff6006672605ff7bea6221c0be540301b1a8380b`）。本代 `inputs_fp` 的位移**可逐条归因**（覆盖面 147 件）：
#     ① `build/MilBridge/tools/r-gate-step.sh` ＋ `build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh`
#        两件 R-GATE 判据件是本波**新纳入** `fp_inputs()` 的（`#50` W91A 接线动作）；② 本波冻前那第 2 处红
#        （`PIPEFAIL-SIGPIPE`）的修法改了 `r-gate-step.sh` —— **它在覆盖面内 ⇒ `inputs_fp` 必变**。
#        ⚠️ 修前的值 `f3fb5db87480ada8fd1502148f3c889549be756c0e60912bfc38109a4a3cc730`（`W94A` 步骤④重钉后的终值）
#        **作废**；本代断言的是**修后终值**（见冻结器 `GENS['#50']['infp']`）。
#        ⚠️ 登记动作（`KNOWN-DEFECTS.md`／四个路由件／`defect-registry-declared.tsv`）**不在**覆盖面内（现场点算）
#        ⇒ **不动** `inputs_fp`（登记前后两次现场复算同值，见 `W95A-report.md` §2.5）。
#   **`known-red.json`**：`a747b713532e7631`（本波开工，`#49` 重钉件的后继）→ **`8a0c0f221e35f42b`**（步骤④ `repin-generation.py --why` 重钉）；
#     JSON diff **只有 3 处语义**：`generation.arm_logs.tline`／`arms_retaken`（`history` 追加 ＋ `when`/`why`）／`evidence_log_sha256`；
#     `entries[*].caliber` 改动字段数 = **0**；`--check` 前 `FAIL n=2` → 后 **`REPIN_GENERATION=PASS`**。
#     备份：`~/w94a/known-red.before-repin.json`（65143 B，与 before 逐位相同 ⇒ 备份有效）。
#   **`verify-all.sh` 的世代声明**：`gen=#49` → **`#50`**（`VERIFYALL-STEPS-DECL: 26 gen=#50`；**加一步** 25 → 26）。
#     现场读数：`VERIFYALL_SELF=PASS names=26 decl=26 gen=#50 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=227623000850ca5d`。
#   【外挂声明：`D-G27` 的读者要读的 4 类行】⚠️ 谁改它们谁要让读者一起绿。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=6ce993ad974d32ad
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【冻前那 1 处声明类红（**这是设计，不是失败**）】`verify-all` 第 `[14]` 步 `COLUMN-FLOOR` 在**冻前必红**：
#     `COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline`（冻结块还是 `#49` 的 `2103f88183b17a6a`，而臂已重取为 `6ce993ad974d32ad`/登记表已重钉）
#     ＋ `COLUMN_FLOOR_SELFREPORT=PASS` ⇒ 形态**逐字命中** `w27-freeze.py` 的 `_is_declaration_class()`
#     （`COLUMN_FLOOR_ARMLOG=FAIL` ∧ `selfreport=PASS`）⇒ 冻后同一批检查器**必须转绿**（`ARMLOG_SHA=PASS 5/5` ＋ `COLUMN_FLOOR=PASS`）。
#     ⚠️ 任务书那一栏写的是 `n_ok=3`；**现场是 `n_ok=4`**（`n_decl=5 = n_ok 4 ＋ bad 1`，`bad` 恰好只剩 `tline` 一个名）
#     ⇒ 以现场为准（本波**冻前**现场三次复算同值：15:4x 只读一趟、16:0x 冻前 `verify-all` 内、冻结器运行时）。
# ── ① 本波改了什么（逐件 sha16，改前 → 改后）────────────────────────────────────
#   **产品/构建件**（值进九位；改前 = `#49` 冻结块那一栏）：
#     · `src/WpfGfx.Linux.Native/tools/patch-presentationcore-mousecapture-release.py`（**W88A 新建应用器**，`D-G85`）
#       ＋ 由其生成的 `MouseDevice.Linux.cs` ⇒ `pc` `56ee75ced8d6aece` → **`722e0ab8205b7c3f`**
#     · `build/PresentationFramework.Linux/reapply-patches.py`（**W86A `A2`/`A3`**）⇒ `pf` `6375fabf89ac7fef` → **`f34bc297d19778fd`**（⚠️ 见冻结块的"不是构建身份"）
#     · `src/WpfGfx.Linux.Native/src/{win32_core.c,win32_internal.h}`（**W82A** `D-G83`）＋ `src/win32_x11.c`（**W89A** `D-G81`）
#       ＋ **W86A `A1` 新增源** `src/win32_pts.c` ⇒ `win32shim` `c493639d15678803` → **`33352e5797031999`**
#     · `build/DirectWrite.Linux/wic-shim/**`（**W79A**：GIF frames）⇒ `wic_shim` `56278c14b4ecd672` → **`f7b3026c8c019be2`**
#     · `dwf` `de2d555105b7d04b` → **`ce3469f49efcbcfa`**（**无源改动可归因**，`NOINFO`；值四趟整波稳定）
#   **仪器/判据件**（本波新接线；两件**已进** `fp_inputs()` 覆盖面 —— `#50` W91A 裁定）：
#     · `build/MilBridge/tools/r-gate-step.sh`  `23b6ee91a4a8dc9b`（**W84A** 新建，**W90A** 加强读数）—— 第 `[26]` 步的**判据唯一实现**
#     · `build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh`  `93f914d6c041c88d`（**W84A** 新建装置：私有 Xvfb ＋ 私有 app 目录 ＋ `xdotool` 真实节奏）
#     · `build/integration-wave.sh`  `0ac2eed4c66cd43d`（**W84A** R-GATE 接线 ＋ **W91A** `APPLIERS_EXPLICIT` 注册）
#     · `build/close-wave.sh`  `f440ccdb4e29a942`（**W91A**：`fp_inputs()` 纳入上面两件 R-GATE 判据件）
#     · `build/MilBridge/tools/build-hygiene-import-check.sh`  `545f3bd1d21b6ee8`（**W81A**，`build-hygiene-roster.tsv` 同趟）
#     · `build/MilBridge/tools/product-entry-step.sh`  `4fdf5de43f1a211a`（`#49` 波尾 W76A，落在 `#49` 冻结**之后**）
#   **本波冻前收尾修掉的两件**（`PIPEFAIL-SIGPIPE` 那第 2 处红的处置，详见冻结块 ④）：
#     · `build/MilBridge/tools/r-gate-step.sh`  `23b6ee91a4a8dc9b` → **`aa9d7188b6b01a2f`**（8 处 `printf … | grep -q` → `grep -q … <<<`）
#     · `build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh`  `5691050c5c67cf1d` → **`08b917a54b18b965`**（`… | head -8 | sed … || echo "（无）"` → 先收进变量再分两路印）
#   **登记/预登记/地图件**：`docs/WAVE50-PREREGISTRATION.md`（`TASK-0702` 的预登记）｜
#     `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`  `4234508f811bd9ba` → **`aec62c485d5010b9`**（2382 → 2407 行；新登记 `D-G88`/`D-G89`/`D-G90`）｜
#     `docs/ROUTES.md`（四处地图改动，W96A）｜`build/MilBridge/tools/defect-registry-declared.tsv`（`DEFREG=PASS declared=126 route_ids=126`，
#     `DEFREG_DECLDRIFT=0`）｜`build/MilBridge/known-red.json`（见冻结块）｜`docs/CURRENT-STATE.md` 机器行（本冻结同趟改）。
# ── ② 收尾链每步读数（命令 + rc + 关键原文）──────────────────────────────────
#   【步骤 ⑤·应用门禁 ×2】两趟**都写 rows**（第 2 趟写另一本，避免追加语义把 6 行变成 12 行）：
#     第 1 趟：`WPTD_RUN_DIR=$HOME/w95a/gate-e WPTD_BASELINE_OUT=$HOME/w95a/gate-rows.txt bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both`
#       槽内 ⇒ `HEAVYSLOT=ACQUIRED waited=0s`／`MEMOK avail=2818MB`／**`RELEASED rc=0 held=161s`**；
#       `WPTD_TIER=default rep=1/2/3 RESULT=PASS` ＋ `WPTD_TIER=env rep=1/2/3 RESULT=PASS` ⇒ **机读行 6/6 `result=PASS`**；
#       `WPTD_SUMMARY=PASS tiers_passed=2/2`、`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、
#       `WPTD_BRIDGE_SRC_STALE=no basis=pub=0a8f69b3c5fabd43 now=0a8f69b3c5fabd43 so_file_match=yes`；
#       `rows.txt` sha16 = `4a7fad3a66f527fe`（`BASELINE` 6 行 / `result=PASS` 6 / `result=FAIL` 0）；
#       窗口：**自起 Xvfb :97**（PID 2352477），收工无孤儿、跑完按 PID 自收（`pgrep Xvfb` rc=1）。
#     第 2 趟（`--no-build`，写 `gate-rows-f.txt`）：**`RELEASED rc=0 held=157s`**、同样三条机读行逐字相同、
#       `rows-f.txt` sha16 = `abbb0cc925d50e6e`（6/6 `result=PASS`）。两本的 `BASELINE` 六行 **config/result 读数逐项相同**
#       （只有 header 的 `date`/`loadavg`/`mem` 与 `run_dir` 不同）⇒ **门禁本波 12/12 PASS**。
#   【步骤 ⑥·冻前 `verify-all`】**跑了两趟**（第 1 趟出现第 2 处红 ⇒ 修 ⇒ 第 2 趟才是冻结输入）：
#     第 1 趟 `~/w95a/logs/06-verify-all-pre.log`（`HEAVYSLOT=RELEASED rc=1 held=874s`）⇒ `步骤通过 24 ❌ 失败 2`、
#       `结论：❌ 失败项：COLUMN-FLOOR PIPEFAIL-SIGPIPE` —— 第 1 处是**设计内**（见下），第 2 处是 `PIPEFAIL-SIGPIPE`
#       （`undeclared_hit=9`，9 处**全在本波自建件里**）⇒ **按纪律停手报主控**（未冻结）。
#     第 2 趟（**本件的冻结输入**）`~/w95a/logs/06b-verify-all-pre2.log`：修完那 9 处之后重跑，
#       预期**恰好 1 处声明类红 = `COLUMN-FLOOR`**（`bad= tline`）＋ 第 `[26]` 步 `R-GATE` 仍 `PASS crit=13/13`。
#   【步骤 ⑦·冻结】`python3 $HOME/w21-verify/w27-freeze.py ~/w95a/logs/06-verify-all-pre.log ~/w95a/gate-rows.txt '#50'`
#     ⇒ 本文件即其 `TXT` 输入；`PRE=/home/links-dev/w50-pre.sha`；`nstep=26`、`875 通过 2 跳过`。
#   【步骤 ⑧·冻后 `verify-all` ×2】两趟都必须全绿（含第 `[26]` 步 `R-GATE`）；逐条读数见 `build/MilBridge/W95A-report.md` §5 与 `~/w95a/STATUS.md`。
#   【步骤 ⑨·记录／推送／app-local 刷新】
#     · 推送（fork 克隆 `~/netTest/GitProj/WPFOnLinux`，`HEAD=7feca487741a8070` = `origin/feat-Linux`）：
#       `git push origin feat-Linux`；⚠️ **`fetch` refspec 陷阱**（`#48`/`#49` 两度踩到）⇒ 核对前**必须**显式
#       `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`，再逐件 `git cat-file blob origin/feat-Linux:<path> | sha256sum` 与磁盘比对；
#       `git ls-remote --symref origin HEAD` 仍须是 `feat-Linux`。推送前后 head sha 与逐件核对结果见 `W95A-report.md` §7。
#     · `TASK-9906` app-local 刷新：`sync-applocal.sh`／`check-applocal-sync.sh`（含 `--apply`）until `STALE=0`；
#       再把两本**书面登记册**（`build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md` ＋ `known-red-PFWB-copies.md`）里
#       **已转绿的 30 条删掉**、**保留 8 条在册红**；`UNEXPECTED=6[DECL-GAP-EQ=5 DECL-GAP-DIFF=1]` 是**在册**声明类缺口
#       （**不许**当绿、**不许**擅自改判据）。
#       ⚠️ **口径已先核**：两本册子**都不在** `fp_inputs()` 覆盖面里（现场点算
#       `sed -n '/^fp_inputs()/,/^}/p' build/close-wave.sh | grep -c 'known-red-PC-copies|known-red-PFWB-copies'` = **0**）
#       ⇒ 删表**不动 `inputs_fp`**、不构成"必须先于 `IN_FP_0` 采样"的约束（任务书给的那条前提**现场被否**，如实记）。
# ── ③ 冻前 `verify-all` 的逐项读数（本件的冻结输入）─────────────────────────────
#   第 1 趟（`~/w95a/logs/06-verify-all-pre.log`，`RELEASED rc=1 held=874s`）：`步骤通过 24 ❌ 失败 2`／`用例通过 875 跳过 2`／
#     `SKIP_GUARD=PASS x_state=available violations=none`／`结论：❌ 失败项：COLUMN-FLOOR PIPEFAIL-SIGPIPE`。
#     · ① `COLUMN-FLOOR ❌`（设计内）—— 逐字形态 `COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline` ＋ `COLUMN_FLOOR_SELFREPORT=PASS`
#       ＋ 总判 `COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0 selfreport=PASS`
#       （第 `[14]` 步）。⚠️ 现场是 `n_ok=4`（不是 `3`：`n_decl=5 = 4 ok ＋ 1 bad`，`bad` 恰好只剩 `tline`）。
#     · ② `PIPEFAIL-SIGPIPE ❌`（**第 2 处红**）—— `PIPEFAIL_SIGPIPE=FAIL undeclared_hit=9 decl_stale=0 files=67 sites=92 hit=12 low=10 diag=2 safe=68 runs=12`；
#       9 条 `UNDECLARED_HIT` 全在本波自建件（`r-gate-step.sh` 8 处 ＋ `run-w81a-legs.sh:255` 1 处）⇒ **按纪律停手报主控**。
#     · 其余 24 步**全绿**（含第 `[26]` 步 `R-GATE（连续交互）`：`R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938`）。
#   第 2 趟（**本件写盘所依据的那一趟**）—— 在**修掉那 9 处**并**重算 `inputs_fp`** 之后重跑：预期**恰好 1 处声明类红 = `COLUMN-FLOOR`**、
#     其余 25 步全绿（含 `R-GATE` 仍 `PASS crit=13/13`、`PIPEFAIL-SIGPIPE` 必须**转绿**）；`[0]` 段选的显示号与 `X_STATE` 见 `W95A-report.md` §2。
#   ⚠️ 第 2 趟若**再出现第 2 处非声明类红** ⇒ 按纪律**再次停手报主控**，不自己压绿（本波第 1 趟就是照这条停的）。
# ── ④ `NOINFO` / 残余（逐条如实）────────────────────────────────────────────────
#   ① **`pf` 不可复现的根因**（`NOINFO`，主控已裁定"不修、不追凶"）：已排除工程确定性开关（`Deterministic=true`）、
#      PF 单独构建（两次同值）、csproj 内容（每波末态可复现）；已证源指纹四趟相同而产物四趟不同。
#      **要什么样的读数**：一个能覆盖 PF **全部**编译输入（含 `obj/` 生成源、引用件、`Compile` 项集合与次序）的指纹。
#   ② **`dwf` 第一趟整波为何位移**（`NOINFO`；此后三趟稳定 ⇒ 值可用）。
#   ③ **`D-G88`／`D-G89`／`D-G90` 的落地**不在本波（只登记；`TASK-0108`／`TASK-0703` 等）。
#   ④ **`UNEXPECTED=6[DECL-GAP-EQ=5 DECL-GAP-DIFF=1]`** 未逐条归因（`#49` 已认定为**在册**声明类缺口；本件只确认"不因本波变多"）。
#   ⑤ **`D-G77` 的 `exit 5` 支**（自起 Xvfb 失败 ⇒ 大声失败）本波未实测（本波 `:97` 顺利自起 ⇒ 走的是正常支）；`ARMS_XVFB_BIN` 反极性留给专门车道。
#   ⑥ **冻后刻九位**的读数位置（不在本块内）已在冻结块里写明并**先写了预测与失败判据**；取值结果见 `W95A-report.md` §5。
# ── ⑤ 内存三值与纪律偏离（逐条写）──────────────────────────────────────────────
#   · 短步照 300/280：门禁每趟（held **161 s**／**157 s**）。
#   · **两条长步放宽（主控授权，理由逐条）**：门禁 `--max-hold 1200`（任务书明示；实际 held ≤161 s）／
#     `verify-all` `--min-avail 1500 --max-hold 1500 -- timeout 1450`（`#49` 实测单趟 ≈16.3 min ⇒ 300 s 装不下，用它只会拿 `MAXHOLD_KILL` ＝作废趟）。
#     `--min-avail 1500`（内存闸门）**未动**；两趟都拿到 `HEAVYSLOT=MEMOK`，无 `NOINFO reason=low-memory`、无 `MAXHOLD_KILL`。
#   · **零 `pkill -f`**：全部按 PID（自起的 Xvfb 由 runner 自己按 PID 收）。
#   · **写域**：本车道只写 `~/w95a/**`、`build/MilBridge/W95A-report.md`、本文件、以及收尾链按配方必须动的件
#     （冻结产物 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`、`docs/CURRENT-STATE.md:9` 机器行、app-local 副本与两本登记册）。
#     产品件／`close-wave.sh`／`verify-all.sh`／五臂判据／`docs/ROUTES.md`／`KNOWN-DEFECTS.md`／`handoff.md` **一字节未改**。
BASELINE tier=default rep=1 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:f34bc297d19778fd,provider:1f9511a7ef395bfe,win32shim:33352e5797031999,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w95a/gate-e
BASELINE tier=default rep=2 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:f34bc297d19778fd,provider:1f9511a7ef395bfe,win32shim:33352e5797031999,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w95a/gate-e
BASELINE tier=default rep=3 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:f34bc297d19778fd,provider:1f9511a7ef395bfe,win32shim:33352e5797031999,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w95a/gate-e
BASELINE tier=env rep=1 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:f34bc297d19778fd,provider:1f9511a7ef395bfe,win32shim:33352e5797031999,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w95a/gate-e
BASELINE tier=env rep=2 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:f34bc297d19778fd,provider:1f9511a7ef395bfe,win32shim:33352e5797031999,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w95a/gate-e
BASELINE tier=env rep=3 config=pc:722e0ab8205b7c3f,bridge:feef049e9d0e313a,pf:f34bc297d19778fd,provider:1f9511a7ef395bfe,win32shim:33352e5797031999,wic_shim:f7b3026c8c019be2,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w95a/gate-e
# ⏪ **（历史，已被 `#50` 取代）**# RE-FROZEN #49 —— ✅ **当前冻结基线** —— 内容 = 收掉 `#48` 冻后剩下的一波：**①`D-G57` 文字零墨**（`build/shims/PresentationCore.HbTextLine.cs` 单段分支改按**计划面**取字形 id ⇒ 页签/按钮/搜索框出墨）＋ **②`D-G72`/`TASK-0008`**（shim `GetMonitorInfoW` 按 `cbSize` 写入 ⇒ 点顶部菜单条不再 NRE）＋ **③`TASK-0403`**（通道级具名台账进 `src/WpfGfx.Linux/{Resources/MilChannel.cs,Commands/MilCommandDispatcher.cs}` ⇒ 桥重发）＋ **④`TASK-1002`**（`wic-shim/applocal-expect.py` 补声明图 ⇒ `UNEXPECTED 16→6`）＋ **⑤仪器侧**：`B4`/`R-CSRC` 把 `src/WpfGfx.Linux.Native/**/*.{c,h}` 纳入 `fp_inputs()`、`C2`/`C4` 纳入 `sync-applocal.sh`／`check-applocal-sync.sh`／`applocal-expect.py` ⇒ `inputs_fp` **必变**（设计性）；`B1` 修"显示号选定后不复核"；并修掉 `D-G77`／`D-G79` 两条**会让读数静默失真**的仪器缺陷。
#   ── 九位（Release 权威件）**现算**（占位符由冻结器替换，值 = 冻结那一刻的现场）──────────
#     · `bridge` `feef049e9d0e313a`（5028208 B）｜`pc` `56ee75ced8d6aece`（3601408 B）｜`pf` `6375fabf89ac7fef`（6119424 B）｜`windowsbase` `2e4e46e539a72cd7`｜
#       `provider` `1f9511a7ef395bfe`｜`win32shim` `c493639d15678803`｜`wic_shim` `56278c14b4ecd672`｜`hbtextline` `921ba9c65e9fb3be`（293165 B）｜`dwf` `de2d555105b7d04b`。
#     · ⚠️ **位移对账（相对 `#48` 冻结值那一栏）**：`bridge` `e3ea092010734f44` → `feef049e9d0e313a`（`TASK-0403` 台账进桥 ⇒ **按需重发**）｜`pc` `9465f9dce39e2dfc` → `56ee75ced8d6aece`｜`pf` `1011da6390c3bf1e` → `6375fabf89ac7fef`｜`windowsbase` `79740e9ba7fbf9ca` → `2e4e46e539a72cd7`｜`win32shim` `abf6879c027c5e73` → `c493639d15678803`（`D-G72` 修法）｜`hbtextline` `e89fed55fd8e32bc` → `921ba9c65e9fb3be`（零墨修法）；`provider`／`wic_shim`／`dwf` **逐位未变**。
#     · ⚠️⚠️ **必记一行（主控要求）**：`pc`/`pf` 的**整波重建值**与**定向重建值**不同 —— 零墨修法后只重建 `build/PresentationCore.Linux` 得到 `pc 21e3e88a5090cd3b`，而整波重建得到 `56ee75ced8d6aece`（`pf` 同理：定向 `1011da6390c3bf1e` → 整波 `6375fabf89ac7fef`）。**同一个源、不同的构建范围/顺序会给出不同字节**（`D-G46` 族；`W70A` 已证"同命令连跑两次同值"⇒ 不是随机）⇒ **本波冻结取的是整波值**，不是定向值；不许把两处读成漂移。
#     · ⚠️ **`PRE` 快照的口径（必写，否则后人会读成事故）**：`/home/links-dev/w49-pre.sha`（9 行、键=路径）**不是**开工前活取的 —— 本波三处世代位在**本车道开工之前**就被波内车道改过（`hbtextline` 12:32／`win32shim` 12:31／`pc` 12:33）⇒ 现场已不存在"改前值"⇒ `PRE` 按 **`#48` 冻结块**九位**逐位重建**（可复算：值就是 `#48` 冻结块里那九个数）。因此冻结器算出的 `changed` = **本波相对 `#48` 冻结点**的位移本身（与 `#46`/`#47`/`#48` 的"产品位移"一栏同形）。
#     · ⚠️ 本代 `prev_pc`=9465f9dce39e2dfc／`prev_pf`=1011da6390c3bf1e／`prev_wsh`=abf6879c027c5e73／`prev_wb`=79740e9ba7fbf9ca／`prev_dwf`=de2d555105b7d04b **全部与 `#48` 冻结值一致**（= `PRE`）。
#   ⚠️ **`BRIDGE_SRC_FP` = `0a8f69b3c5fabd43`**（上一代 `f10b4b297b2358e6`，**两侧同值**：现树 == 发布记录 `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/bridge-src-fp.txt`）⇒ `close-wave.sh:301-304` 的桥身份自检**会过**。
#   **臂日志**：位 sha 变 ⇒ 按纪律**重取五臂**。⚠️ 本波重取**跑了两轮**：第一轮（15:37:58–15:43:38）**X-混淆、已作废**（`D-G77`：`:97` 当时不存在）；修法落地后正式两趟（①无 `:97` 自起＝`source=self-started`；②有 `:97` 复用＝`source=reused`），两趟 `textlineproto` 日志**去时间戳后逐行相同**、判词均回到 **通过 4 / 失败 2**、`XOpenDisplay` 计数 **0**。
#   **臂日志聚合（两种口径都算，`#31` 起同趟写）**：`cat` 口径 = `7e15b9c3d3d8ada2`；`find|sort|xargs` 口径 = `5caae84d6e94e18a`。
#   **`inputs_fp`** = `9f2199b212bed2b212035f87ff6006672605ff7bea6221c0be540301b1a8380b`（上一代 `cad0801cf1dff2fdf1600b803315d1c57b0d2afcc9ebf45e170f2b3885677da4`）。⚠️ 本波 `inputs_fp` **必变**是**设计性**的，可归因**六件**：① `build/close-wave.sh` 的 `fp_inputs()` 新增 `src/WpfGfx.Linux.Native/**/*.{c,h}`（`B4`/`R-CSRC`）＋三件判据件（`C2`/`C4`：`sync-applocal.sh`／`check-applocal-sync.sh`／`applocal-expect.py`）；② `build/shims/PresentationCore.HbTextLine.cs`（零墨修法）；③ `src/WpfGfx.Linux/{Resources/MilChannel.cs,Commands/MilCommandDispatcher.cs}`（`TASK-0403`）；④ `src/WpfGfx.Linux.Native/src/{win32_core.c,…}`（`D-G72`）；⑤ `build/MilBridge/known-red.json`（`entries[1]` 重钉 ＋ `repin-generation` 重钉世代/五臂）；⑥ **`build/MilBridge/tools/product-entry-step.sh`**（`d0b503cd5f74dfcf → 4fdf5de43f1a211a`：把 `D-G57` 零墨修法的**已知代价具名登记** —— 5 格 `field=ext`（`M_modifier_w80/_w120/_w200/_w320/_winf` 各 `k=0`，`delta=-0.515625`），依据 = 同代 A/B「只换权威 pc」：修前 `9465f9dce39e2dfc` ⇒ **147/147 全 OK**；修后 `56ee75ced8d6aece` ⇒ 同样 5 格 `ours=17.484375`／`truth=18.000000`。**语义 = 改了判据口径（把已知代价具名），不是把产品改绿**；下界/正控/`noinfo` 三条闸一格未动，不在册的红照旧 `FAIL`，在册格"消失"判 `NOINFO`）。⚠️ 本波改的两件仪器（`retake-arms-w23.sh`、`run-wpftextdemo.sh`）**都不在** `fp_inputs()` 覆盖面里（现场点算：覆盖面 **143 件**，`sed -n '/^fp_inputs()/,/^}/p' build/close-wave.sh | grep -c 'retake-arms\|run-wpftextdemo'` = **0**）⇒ 改它们**不动** `inputs_fp`。
#   **`entries[1]` 重钉（本波必做，`D-G57` 的直接后果）**：`known-red.json` 的 `tline` 臂 `T2d-Extent余差` 由 `count==95` 重钉为 **`count==1242`**（**现场实测**：`build/MilBridge/arm-logs/tline.log:149` 原文 `[② Extent 余差清单] 共 1242 条（主对拍集 1202 + LH 组 40；容差 0.01 DIP）`）。**不去动它就会 `registry-stale(drift)` ⇒ FAIL**（门禁比的是这里：`tline-gate.sh` 的 `eval_shape`）。原因 = 零墨修法**改变了墨迹盒（Extent）的取值**；同代 A/B 已证两腿只差 `-p:HbShimSrc`（`通过 22/失败 2` 与两条既有 ❌ 逐字不变）⇒ 变的是**读数本身**，不是判据漂移。`known-red.json` **在 `fp_inputs()` 覆盖面里**（点名成员）⇒ 重钉后 `inputs_fp` 如上。
#   【外挂声明：`D-G27` 的读者要读的 4 类行】⚠️ 谁改它们谁要让读者一起绿。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=2103f88183b17a6a
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【冻前那 1 处声明类红（**这是设计，不是失败**）】`verify-all` 第 `[14]` 步 `COLUMN-FLOOR` 在**冻前必红**：
#     `COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=3 bad= tline`（冻结块还是 `#48` 的 `960e28f59ee974e5`，而登记表已重钉为 `2103f88183b17a6a`）＋ `COLUMN_FLOOR_SELFREPORT=PASS`
#     形态**逐字命中** `w27-freeze.py` 的 `_is_declaration_class()`（`COLUMN_FLOOR_ARMLOG=FAIL` ∧ `selfreport=PASS`）⇒ 冻后同一批检查器必须转绿。
#     ⚠️ 第一趟重取（X-混淆）时该行是 `bad= tline textlineproto`；X-混淆作废后重取 ⇒ `textlineproto` 回到 `4bceceeed570ba70`（= `#48` 冻结值）⇒ **收敛为只剩 `tline` 一条**，这正是"那条红应当收敛"的成对读数。
# ── ① 本波改了什么（逐件 sha16，改前 → 改后）────────────────────────────────────
#   **产品/构建件**（值进九位）：
#     · `build/shims/PresentationCore.HbTextLine.cs`  `e89fed55fd8e32bc` → **`921ba9c65e9fb3be`**（零墨修法：单段分支按**计划面**取字形 id）
#     · `build/PresentationCore.Linux/**`（整波重建）  `pc 9465f9dce39e2dfc` → **`56ee75ced8d6aece`**
#     · `src/WpfGfx.Linux.Native/src/{win32_core.c,win32_internal.h,…}`（`D-G72`：`GetMonitorInfoW` 按 `cbSize` 写入）  `win32shim abf6879c027c5e73` → **`c493639d15678803`**
#     · `src/WpfGfx.Linux/{Resources/MilChannel.cs,Commands/MilCommandDispatcher.cs}`（`TASK-0403` 通道级具名台账）⇒ 桥重发  `bridge e3ea092010734f44` → `79e45aed26487045`（波前就已由波内车道重发）→ **`feef049e9d0e313a`**
#     · `build/DirectWrite.Linux/wic-shim/applocal-expect.py`（`TASK-1002` 补声明图）  `51b09c345c1dfb5d`（见 `docs/WAVE49-PREREGISTRATION.md` §13）
#   **仪器/判据件（本波新修，两件都不在 `fp_inputs()` 覆盖面）**：
#     · `build/MilBridge/tools/retake-arms-w23.sh`  `2546fee35078a993` → **`a160671709db61c2`**（`D-G77`：`:97` 不在就自起、起不来就 `exit 5`；第 4 步那行内容一字未动，行号 `:83` → `:131`）
#     · `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh`  `e657abba148a9bce` → **`3feab1cdac3318a7`**（`D-G79`：枚举全部候选、按**标题**认领**可见**的那个）
#   **登记/预登记件**：`docs/WAVE49-PREREGISTRATION.md`（H1 含 `#49`）｜`build/MilBridge/known-red.json`（`entries[1]` 95→1242 ＋ 世代/五臂重钉）｜`docs/CURRENT-STATE.md` 机器行（本冻结同趟改）。
#   **`verify-all.sh` 的世代声明**：`gen=#48` → **`#49`**（DECL 首行新增一条 ＋ 口径句新增一条；**步数不动 = 25**）。现场读数：`VERIFYALL_SELF=PASS names=25 decl=25 gen=#49 dup=0 order=OK prose=OK prereg=PASS`（`verify-all.sh` 整份 sha16 = `bb416e92ab34ff64`）。
# ── ② 收尾链每步读数（命令 + rc + 关键原文）──────────────────────────────────
#   【勘察结论（为什么从第 ② 步接续）】`build/wave-audit.log` 最后一条是 `w50a @2026-09-20T00:11`（那是 `#48` 的波）；
#     `build/MilBridge/arm-logs/*` 五个文件的 mtime 全停在 `9-20 00:17–00:21`；`BASELINEGEN=PASS decl_gen=#48`；
#     `known-red.json entries[1]` 仍是 `count==95`；`~/w71a/` 下**只有 `BRIEF.md`、零日志零报告**
#     ⇒ **整波从未跑过**，从 §6 收尾链**第 ② 步**接续（不是"从中间接"）。
#   【第 ② 步】`WAVE_OWNER=W76A bash build/integration-wave.sh`（槽内）⇒ `rc=0`、`失败步骤 0`、`APPLIER_AUDIT appliers=26 ok=89 miss=0 red=0`、耗时 **233 s**、`HEAVYSLOT=ACQUIRED waited=43s`。
#     ⚠️ 该趟的 3.6 刷新步**自动**把四份落后副本同步到权威：`REFRESH …libwpfwin32.so abf6879c027c5e73 → c493639d15678803` ×4（`CompositeFontProbe`／`ContractProbe`／`SystemFontsProbe`／`WpfFeatureProbe`）⇒ **任务书红字②（"四份副本落后"）不需要手做**，日志逐条在册。
#   【第 ③ 步·桥】`bash build/publish-milbridge.sh`（槽内）⇒ `rc=0`、耗时 **23 s**；`BRIDGE_SRC_FP=0a8f69b3c5fabd43`（现场 == 发布记录两侧一致）；`bridge` 位 `79e45aed26487045` → **`feef049e9d0e313a`**（5,028,208 B）。
#   【第 ④ 步·重取五臂】跑三轮（第一轮作废，见上）：正式两趟 rc 均 `0`（①held **329 s**／②held **333 s**，槽内 `--max-hold 1200`）。
#   【第 ⑤ 步·重钉】`repin-generation.py --why '…'` ⇒ `REPIN_GENERATION=APPLIED`（`instr_shim=e89fed55…→921ba9c6…`、`evidence_log_sha256=2103f88183b17a6a`）＋ `--check` = **`REPIN_GENERATION=PASS`**；`known-red.json` `25c21ca0f33208ae`（改前，406 行）→ `a22648c79ca71801`（`entries[1]` 重钉）→ `e38300c235593d3b`（第一次 repin）→ **`00ad5e0c38379a13`**（X-混淆作废、重取后第二次 repin）。
#   【第 ⑥ 步·门禁 ×2】见 ③。
#   【第 ⑦ 步·冻前 `verify-all`】`bash verify-all.sh`（槽内 `--max-hold 1500 -- timeout 1450`）⇒ 读数见 ④。
# ── ③ `D-G79`（门禁认错窗口）—— 机制、修法、两极性（本波最要紧的一条）───────
#   【现场】门禁**两趟 ×2 = 12/12 假 FAIL**：`fail_reasons=("no-window")`、`capture=all-blank colors=0`、`exit=143`（应用活着）。
#     第一次是门禁自起 `Xvfb :97`（PID 101837）；我按 `WAVE18-PREREGISTRATION.md:86` 的纪律起**常驻** `Xvfb :97`（`setsid`，PID 183453）再跑第二遍 ⇒ **仍然 6/6 FAIL** ⇒ 排除"X 不稳/偶发"。
#   【机制（最小复现，同一份件、同一 app-local 目录）】`xwininfo -root -tree` 逐字：
#       `0x200006 (has no name): ("HwndWrapper[WpfTextDemo;;94a965e1…]") 800x600 +0+0`   ← 门禁 `head -1` 取它（`Map State: IsUnMapped`，**永远不 map**）
#       `0x200005 "WpfTextDemo — text / binding / image / effect": (…) 938x938 +0+0`      ← **真窗**（`Map State: IsViewable`）
#       `0x200004 "SystemResourceNotifyWindow"`／`0x200003 "MediaContextNotificationWindow"`／`0x200002 (has no name)`（800x600）
#     应用侧自报（`WPF_LINUX_CREATE_DIAG=1`）：`CREATE xid=0x200005 style=0x2cf0000` → `CREATE xid=0x200006 style=0x0`（**主窗之后、ShowWindow 之前**由**托管侧**新建；`XCreateSimpleWindow` 在 shim 里只有一处 `win32_x11.c:404`）→ `[SHOW_DIAG] ShowWindow hwnd=0x200005 a=5` → `CREATE_DIAG MAP xid=0x200005 … 938x938`。
#     ⇒ **X 里新建窗口默认压在最上层** ⇒ 那个无名顶层窗排在 `xwininfo -root -tree` 第一位；而门禁那句 `grep -F 'WpfTextDemo'` 命中的是 **`WM_CLASS`**（本进程**每个**顶层窗都是 `HwndWrapper[WpfTextDemo;;<guid>]`）⇒ 5 个窗全成候选，`head -1` 取到的是那个**永远不 map** 的无名窗 ⇒ 等到 60 s 超时判 `no-window`。
#     ⇒ **产品侧没有回归**：真窗建/缩放/映射/呈现全正常（`X11 Resize → 938x938`、`committed=886`、`skia 指令 261 条`、`未画种类 0`）。
#     ⇒ 对照 `#48`（W48A）那趟的 `windows-*.txt`：**唯一候选就是 `0x200005`**（`938x938 IsUnMapped→IsViewable`）⇒ **这条洞一直在，只是这一代被触发**。
#   【修法（`run-wpftextdemo.sh:869` 那一格）】`head -1` → **枚举全部候选**，取**第一个**「`WM_NAME` 以 `WpfTextDemo` 开头 ∧ 宽高 ≥64 ∧ `Map State: IsViewable`」者；日志行同时印出 `name=`（可读性）。
#   【正极性（修前/修后成对）】修前：`head -1 = 0x200006`（`IsUnMapped`）⇒ `no-window`（12/12）；修后：认领到 `0x200005`（`IsViewable`）⇒ 门禁读数见 ③ 的读数块。
#   【反极性（"真窗认不出来 ⇒ 必须仍 FAIL"）】把真窗的 `WM_NAME` 改名 ＋ 持续 `unmap`（在它还是 unmapped 时就改，**确定性**、无竞态）⇒ 门禁**必须回到 FAIL**；若仍然 PASS ⇒ 说明修法退化成"任意候选可见即过" ⇒ 修法作废。读数见 ③ 的读数块。
#   【残余边界（如实划）】一个**别的进程**的**可见**窗口若标题也以 `WpfTextDemo` 开头，仍会被认领 —— 这与修前注释"按标题认领"的**原意一致**，但**不是**"只认我自己的进程树"；**未**纳入本修法。**同族未修**（同一句 `… | grep -F 'WpfTextDemo' | grep -oE '0x…' | head -1` 的**另外三处载体**，已登记未动）：`build/MilBridge/tools/t1c-census.sh:248`（**census 现场同样被认错**：本波 census 读数 `SHOT frames=0 best_colors=0 best= win=0x200006`）／`run-wpftextdemo.sh:850`（`first-sight` 抢拍）／`run-wpfprobe.sh:412`。
# ── ④ `NOINFO` 清单 ───────────────────────────────────────────────────────────
#   ① **`D-G79` 的那条"无名顶层窗是谁建的"** —— 按主控裁定**不在本波**（已记入 `D-G79` 的边界，冻结后另派车道）。
#   ② **`①与②` 两趟 `tline.log` 的 sha 不同**（`deb49fbf21fb3b3f` vs `2103f88183b17a6a`）而 `textlineproto` 逐行相同 —— `tline.log` 程序上**不可复算**（`#48` 已证：耗时字段、**自指**的上一趟产物 sha、日期戳文件名、`mktemp` 路径）⇒ **不构成位移信号**；本波按 ② 那一趟（复用 `:97`，与门禁同径）重钉。
#   ③ **冻后 `verify-all` ×2** 的结论由 ⑤ 给出。
# ── ⑤ 内存三值与纪律偏离（主控要求逐条写）────────────────────────────────────
#   · **短步照 300/280**：`integration-wave`（held **233 s**）／桥重发（held **23 s**）／应用门禁每趟（held ≤600）。
#   · **两条原子长步放宽（已获主控批准）**：重取五臂 `--min-avail 1500 --max-hold 1200 -- timeout 1150`（实际 held **329 s／333 s**）｜冻前/冻后 `verify-all` `--min-avail 1500 --max-hold 1500 -- timeout 1450`（实际 held 见 ④⑤）。**理由**：这两步是**原子长步**，300 s 装不下；`--min-avail 1500`（内存闸门）**未动**。
#   · **排队情况**：`HEAVYSLOT=ACQUIRED waited=43s`（整波，前面是 `W77A` 的 150 s 档）／桥重发 `waited=0s`／重取①`waited=0s`②`waited=0s`（**它自己的 1200 s 持有把 `W77A` 挡在外面**）／门禁第一趟 `waited=30s`。
BASELINE tier=default rep=1 config=pc:56ee75ced8d6aece,bridge:feef049e9d0e313a,pf:6375fabf89ac7fef,provider:1f9511a7ef395bfe,win32shim:c493639d15678803,wic_shim:56278c14b4ecd672,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w76a/gate-fix/e
BASELINE tier=default rep=2 config=pc:56ee75ced8d6aece,bridge:feef049e9d0e313a,pf:6375fabf89ac7fef,provider:1f9511a7ef395bfe,win32shim:c493639d15678803,wic_shim:56278c14b4ecd672,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w76a/gate-fix/e
BASELINE tier=default rep=3 config=pc:56ee75ced8d6aece,bridge:feef049e9d0e313a,pf:6375fabf89ac7fef,provider:1f9511a7ef395bfe,win32shim:c493639d15678803,wic_shim:56278c14b4ecd672,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w76a/gate-fix/e
BASELINE tier=env rep=1 config=pc:56ee75ced8d6aece,bridge:feef049e9d0e313a,pf:6375fabf89ac7fef,provider:1f9511a7ef395bfe,win32shim:c493639d15678803,wic_shim:56278c14b4ecd672,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w76a/gate-fix/e
BASELINE tier=env rep=2 config=pc:56ee75ced8d6aece,bridge:feef049e9d0e313a,pf:6375fabf89ac7fef,provider:1f9511a7ef395bfe,win32shim:c493639d15678803,wic_shim:56278c14b4ecd672,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w76a/gate-fix/e
BASELINE tier=env rep=3 config=pc:56ee75ced8d6aece,bridge:feef049e9d0e313a,pf:6375fabf89ac7fef,provider:1f9511a7ef395bfe,win32shim:c493639d15678803,wic_shim:56278c14b4ecd672,hbtextline_shim:921ba9c65e9fb3be(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w76a/gate-fix/e
# ⏪ **（历史，已被 `#49` 取代）**# RE-FROZEN #48 —— ✅ **当前冻结基线** —— 内容 = 修 **`D-G56`**（我方两个 applier 把**插桩横幅插在「类属性块 ↔ 类声明」之间** ⇒ 两条/三条类属性**挂到插桩类身上** ⇒ `NameScope` 挂不到页面根 ⇒ 带 `Storyboard.TargetName` 的 BAML 页**一加载就未处理异常、进程 abort**）；本波**产品改源 = 两个 applier 的插入锚（零语义改动的换锚）**，位移与归因见下方。
#   ① **本波修的是什么（判定点，代码级）**：`EDITS` 的语义是「把 `TRACE_CLASS` 文本拼在**锚行前面**」，而锚原本就是**类声明行** ⇒ 只要类声明前有属性行，横幅就必然夹在中间。
#     · **发现者与原始读数**（车道 `W47A`，`build/MilBridge/W47A-report.md` `68bfb1301c67d485`）：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2068-2083`。诊断行 = `[NS] ATTRCOUNT DependencyObject=0`（源里 2 条属性**全跑到插桩类身上**）、`[NS] WINDOW … scope=null FindName(ControlMain)=null`、4 个页面 `scope=null FindName(PathDemo)=null`；而 `dpField=True dpOwner=NameScope attachableMember=NameScope`（链的**其余环节都好**）＋ 名字**确实进了 BAML** ⇒ 断链**只在"属性归属"那一格**。
#     · **修法（换锚，两处）**：`src/WpfGfx.Linux.Native/tools/patch-windowsbase-dpvalue-trace.py` 新增 `WB_TYPE_HEAD_ANCHOR`（现场 `:643-644`，= 该类型 **doc 注释的首两行**；上游实测**只出现 1 次** —— 同文件里 `    /// <summary>$` 有 55 处，只锚 `<summary>` 会命中 55 次被 `_build()` 的"要求 1"判死），W0 那条 edit 的锚由类声明行改为它（现场 `:848-849`）；同族第二例 `patch-presentationframework-mirror-trace.py` 的 `FE_TYPE_HEAD_ANCHOR`（现场 `:263-264`）＋ M0 那条 edit（现场 `:295-296`）。
#       applier 件 sha16（现场算）：`patch-windowsbase-dpvalue-trace.py` `1bff235f3d389788` → **`5203f958c234882f`**；`patch-presentationframework-mirror-trace.py` `a4e6599a8f0a9e75` → **`1b9852b037da70f1`**。
#     · **为什么换锚、不"追加到文件末尾"**（`W48D-report.md` §2.3）：插入文本**一个字节没改**、只是落点早了 27 行（WB）/11 行（PF）；而 `TRACE_CLASS` 声明在 `namespace System.Windows` **内**、调用点写**非全限定**名 `WpfLinuxDpValueTrace.…` ⇒ 挪出 namespace 就得动调用点或**新增一处同名声明**（本仓反复登记的那一族坑）。
#     · **"只插入"的机械证明**（`--prove` 两件 rc=0）：把插桩逆序回代后与上游**逐字节相同** —— `DependencyObject.Linux.cs` 回代 sha256 `edeb712d0bc7b433…` == 上游 `edeb712d0bc7b433…`；`FrameworkElement.Linux.cs` / `TextBlock.Linux.cs` 各自同形 ⇒ 换锚**没有**顺手改上游一个字节。
#     · ✅ **判据①（生成件形状，现场逐行读过原文）**：插桩类现在落在类型**整段之前**，「doc ＋ 属性块 ＋ 类声明」**三段紧贴如上游**：
#       `build/WindowsBase.Linux/DependencyObject.Linux.cs:612` `    [System.ComponentModel.TypeDescriptionProvider(typeof(MS.Internal.ComponentModel.DependencyObjectProvider))]`／`:613` `    [System.Windows.Markup.NameScopeProperty("NameScope", typeof(System.Windows.NameScope))]`／`:614` `    public class DependencyObject : DispatcherObject`（**三条连续、无横幅**；修前是 `:51-52 属性 → :53-63 横幅 → :64 插桩类 → :614 类声明`）；
#       `build/PresentationFramework.Linux/FrameworkElement.Linux.cs:303` `    [StyleTypedProperty(Property = "FocusVisualStyle", StyleTargetType = typeof(Control))]`／`:304` `    [XmlLangProperty("Language")]`／`:305` `    [UsableDuringInitialization(true)]`／`:306` `    public partial class FrameworkElement : UIElement, IFrameworkInputElement, ISupportInitialize, IHaveResources, IQueryAmbient`。
#       生成件 sha16（现场算）：`DependencyObject.Linux.cs` `cdd5867fc742ffee` → **`2985c671c57c7775`**（184,597 B 不变）；`FrameworkElement.Linux.cs` `61a5f1e45e6017fb` → **`3af06981155e89aa`**（292,005 B 不变）；`TextBlock.Linux.cs` `6067276d0fc3a8da` **未重写**（该件不插类 ⇒ 阴性对照）。
#   ② **两极化读数（同一驱动、同一坐标，只差两个件；`W48D-report.md` §5）**：
#       ⛔ **修前**（`#47` 冻结件 `WindowsBase 84a2826c471e60ea`／`pf 366e9486536bc291`，`$HOME/w48d-run/BEFORE/app.log`，`HC_INPUT_DIAG=1`）：
#         `[NS] ATTRCOUNT DependencyObject=0 FrameworkElement=1 Control=0 TextBlock=2`｜`[NS] ASSM … attrCount=0 nameScopeHits=none nonInherit=False`｜`[NS] CHAIN attrOnDependencyObject=False attrOnRootType=False dpField=True dpNull=False dpOwner=NameScope dpName=NameScope attachableMember=NameScope`｜`[NS] WINDOW HandyControlDemo.MainWindow scope=null FindName(ControlMain)=null`｜`[NS] loaded …GeometryAnimationDemo scope=null isINS=False contentScope=null upHits=none FindName(PathDemo)=null`。
#       ✅ **修后**（`$HOME/w48d-run/AFTER/app.log`）：`[NS] ATTRCOUNT **DependencyObject=2 FrameworkElement=4** Control=0 TextBlock=2`｜`[NS] ASSM attrCount=2 nameScopeHits=**HIT:System.Xaml** nonInherit=**True**`｜`[NS] CHAIN **attrOnDependencyObject=True attrOnRootType=True**` ＋ 其余逐字相同｜`[NS] WINDOW … **scope=NameScope FindName(ControlMain)=ContentControl**`｜`[NS] loaded …GeometryAnimationDemo **scope=NameScope** … **FindName(PathDemo)=Path**`。
#       ⇒ `docs/WAVE48-PREREGISTRATION.md` §2 判据②三条（`ATTRCOUNT ≥ 2` ∧ `scope` 非 null ∧ `FindName` 非 null）**逐条成立**（修前逐条不成立）。
#       ⛔ **判据③ 反极性 · 修前**（点最右页签「工具」→ 点该页第 2 项 `MorphingAnimation` @(429 435)，`mode=hold150`）：`!!! APP DIED`／`!! Unhandled exception. System.InvalidOperationException: 'PathDemo' name cannot be found in the name scope of 'HandyControlDemo.UserControl.GeometryAnimationDemo'.`（栈 `Storyboard.ResolveTargetName Storyboard.cs:276` ← `BeginStoryboard.Invoke :197` ← `FrameworkElement.OnLoaded` `build/PresentationFramework.Linux/FrameworkElement.Linux.cs:5989`）／`alive=no`。
#       ✅ **判据③ · 修后**：同一坐标 `after : … LB(ListBoxDemo sel=1/3)`、`EV LB.SelectionChanged … sel=1/3 added=1`／**`alive=yes`**／`[NS] loaded …GeometryAnimationDemo scope=NameScope … FindName(PathDemo)=Path`。
#       ✅ **判据③ 的第二条腿（把 hc 侧仪器整个关掉 ⇒ 产品级）**：`$HOME/w48d-tools/tools3-nodiag.sh`（**不设** `HC_INPUT_DIAG`，坐标用上一趟 `[GEO]` 复放，每步做 `xwd`/`compare` 帧差证明确实换了页）——
#         修前 `BEFORE step=tools#1(MorphingAnimation) **alive=no** AE(s2,s3)=480000` ＋ `BEFORE FINAL alive=no unhandled_lines=1`；修后 `AFTER step=tools#1(MorphingAnimation) **alive=yes** AE(s2,s3)=39765`；
#         两条腿的**同一位移帧差逐位相同**：`AE(s0,s1)=238109`（点「工具」页签）、`AE(s1,s2)=6541`（点 #0 `HatchBrushGenerator`）**BEFORE ≡ AFTER** ⇒ 点击确实落在同一处、同一个页面上（"`alive=yes` 不告诉你点到哪儿"这条自伤已用 `AE` 成对读掉）。
#         ⚠️ 这条腿**顺带暴露第三条无关缺陷** `tools#2` `Effects`（`alive=no`，`System.NotImplementedException` 栈顶 `MediaContext.CommitChannel()` ← `MediaContext.cs:2151`）＝ **`D-G58`**，**与 `D-G56` 不是同一条**（异常类型/栈/判定点全不同），本波未修。
#   ③ **防复发判据（两个 applier 各两条，互相独立）＋ 各自的两极化**：判据**跟随 `--check`**（现场实测：生成物过时时 `--check` rc=1 **照样打出**判据行 ⇒ 不是"写了不跑"）；`bash build/check-appliers.sh` = **`APPLIER_AUDIT_SUMMARY appliers=25 ok=86 miss=0 red=0 rc=0`**、`--with-check` = `ok=111 miss=0 red=0 rc=0`；重新生成后两件 `--check` 均 **rc=0**。
#     · ① **形状判据**（文件级）：任何一行匹配 `^\s*\[[^\]]*\]\s*$` 的属性行，其**下一个非空行**都不许匹配 `^\s*//\s*(T1c\b|=+\s*$)`；② **内容判据**（类级）：自类声明向上数**连续**紧贴属性行 ≥ 下限（WB `DependencyObject` ≥ 2；PF `TYPE_ATTR_FLOOR`：`FrameworkElement` = 3、`TextBlock.Linux.cs` = `None`＝本件不插类）。
#     · **两极化实测**（`$HOME/w48d-tools/polarity.py`，只读；**同一份判据代码、同一函数、只换输入**）：负极 = 修前落盘件、正极 = 用修后 applier 在内存里现算的生成物 ⇒
#       `WB   NEG(修前落盘件): fails=2 紧贴属性行=0` ／ `WB   POS(修后现算件): fails=0 紧贴属性行=2`；
#       `PF FrameworkElement.Linux.cs NEG: fails=2 紧贴属性行=0` ／ `PF FrameworkElement.Linux.cs POS: fails=0 紧贴属性行=3`；
#       `PF TextBlock.Linux.cs NEG: fails=0  POS: fails=0` ← **阴性对照**（证明判据不是恒红）。
#     · **为什么两条都要**：①抓"**任何人**又把横幅插进某个属性块中间"（形状），②抓"**本类型的属性真的回到了类身上**"（内容）；伪造方式不同 ⇒ 单靠一条有盲区（把横幅挪到 doc 之前却顺手搬走属性行 ⇒ ①绿②红）。
#   ④ **九位（Release 权威件）**：`bridge` `e3ea092010734f44`（5019968 B）／`pc` `9465f9dce39e2dfc`（3601408 B）／`pf` `1011da6390c3bf1e`（6119424 B）／`windowsbase` `79740e9ba7fbf9ca`／`provider` `1f9511a7ef395bfe`／`win32shim` `abf6879c027c5e73`／`wic_shim` `56278c14b4ecd672`／`hbtextline` `e89fed55fd8e32bc`（290825 B）／`dwf` `de2d555105b7d04b`。
#   ⚠️ **位移对账（两栏，别混读）**：
#     · **相对 `#47` 冻结值那一栏**：`windowsbase` `84a2826c471e60ea` → `79740e9ba7fbf9ca`；`pc` `043eff4b1d8ecd7d` → `9465f9dce39e2dfc`；`pf` `366e9486536bc291` → `1011da6390c3bf1e` ⇒ **本波三位变**（`windowsbase`/`pf` 是**产品位移**：两个 applier 的产物；`pc` 是**整波重建位移**）；其余**六位逐位未变**（`bridge` `e3ea092010734f44` == `e3ea092010734f44`、`provider` `1f9511a7ef395bfe` 未动、`win32shim` `abf6879c027c5e73` == `abf6879c027c5e73`、`wic_shim` `56278c14b4ecd672` 未动、`hbtextline` `e89fed55fd8e32bc` 未动、`dwf` `de2d555105b7d04b` == `de2d555105b7d04b`）。
#     · ⚠️ **口径勘误（本车道现场核出，如实记）**：任务/登记口径把本波写成"**九位只动两位**（`windowsbase`/`pf`，`pc` 未重建）"—— 那**只是 `W48D` 车道「单件重建」那一刻的读数**（`build/MilBridge/W48D-report.md:5` 与 `:399-400`；该时刻 `pc` 确实仍 `043eff4b1d8ecd7d`）。**整波重建后 `pc` 也动了**：整波日志 `$HOME/w50a/02-integration-wave.log:149-150` 的 `REFRESH` 行自报"权威 **9465f9dce39e2dfc**"，本车道 00:14:55 现场 `sha256sum` 复核同一值；`pf` 亦由 `bd73f9e2376d67ac` 再移到现场 `1011da6390c3bf1e`。⇒ **本波位移集合 = 三位**（`windowsbase`／`pc`／`pf`），与 `GENS['#48']['allow_changed']` **逐字一致**；"只动两位"**不作为本代口径**。
#     · ⚠️ 上两格现场值（`pc 9465f9dce39e2dfc`／`pf 1011da6390c3bf1e`）**不是终值**（`close-wave.sh` 波尾若再重编环成员 `pf`，它会再变）⇒ 一切以冻结器现算的 `9465f9dce39e2dfc`/`1011da6390c3bf1e` 为准。
#     · **相对开工快照 `PRE`**（`/home/links-dev/w48-pre.sha`，9 行，现场核：**逐行就是 `#47` 冻结值**）：⇒ 冻结器算出的 `changed` = **产品位移本身**（`#46`/`#47` 同口径，不是事故；这是**更严**的一栏）。
#     · ⚠️ 本代 `prev_pc=043eff4b1d8ecd7d`／`prev_pf=366e9486536bc291`／`prev_wsh=abf6879c027c5e73`／`prev_wb=84a2826c471e60ea`／`prev_dwf=de2d555105b7d04b` **全部与 `#47` 冻结值一致**（= `PRE`）。
#   ⚠️ **`BRIDGE_SRC_FP` = `f10b4b297b2358e6`**（上一代 `f10b4b297b2358e6`，**两侧同值**）：本波**没改** `src/WpfGfx.Linux/**` ⇒ 值不变；本车道现场跑 `bash build/bridge-src-fp.sh` = `BRIDGE_SRC_FP=f10b4b297b2358e6 BRIDGE_SRC_N=78` ⇒ `close-wave.sh:301-304` 的桥身份自检**会过**，`close-wave.sh` 的 `[3/6]` 步会**跳过重发**（源指纹一致）。
#   **臂日志**：位 sha 变 ⇒ 按纪律**重取五臂**（`ARMS_OUT=NOINFO`：本车道写记录时**尚未重取**，输出目录由主控按现场定）。
#     预测（**未被本车道证实**，如实标）：**只有 `tline` 一支会变**。现场证据（本车道逐字读）：`build/MilBridge/arm-logs/tline.log:9` `  [applocal] PresentationCore.dll：已与权威一致（043eff4b1d8ecd7d）`、`:10` `  [applocal] WindowsBase.dll：已与权威一致（84a2826c471e60ea）`；另四份臂日志对 `043eff4b1d8ecd7d`／`366e9486536bc291`／`84a2826c471e60ea` **各 0 命中**（逐份 `grep -c` 实测）⇒ 只有 `tline` 自报 `pc`/`windowsbase` 的权威 sha，而**这两样本波都变** ⇒ 该两行必换、日志必换；三支 `tab-*` 与 `textlineproto` 预期**逐位不变**（`#46`/`#47` 的实测先例）。
#     `GEN_KEYS` 三件（`instr_run_sh`=`build/MilBridge/run.sh` `711f39f468f61cc8`／`instr_program_cs`=`build/MilBridge/tests/HbTextLineParity/Program.cs` `149dd986a642fdfc`／`instr_shim`=`build/shims/PresentationCore.HbTextLine.cs` `e89fed55fd8e32bc`）**本波未动** ⇒ `entries[*].caliber` **0 改动**；本车道现场跑 `python3 build/MilBridge/tools/repin-generation.py --check` = **`REPIN_GENERATION=PASS（世代三项 + 五臂 + 证据日志 + 4 条 entries 的 caliber 全部一致）`**（这是**重钉前**的读数）。
#     ⚠️ **重钉不幂等**（`#46` 实测发现、`#47` 照旧）：`--why` 的值**只追加**进 `generation.arms_retaken.history`，同一条 `--why` 再跑仍会写盘并再追加一条 ⇒ **重钉只做一趟、`--why` 必须给**。本波重钉**前**现场值 = **`00a75a87ec5ed0d6`**（406 行；本车道现场 `sha256sum` 复核，= `#47` 终态）。
#   **`verify-all` 同趟五处已改到 `#48`**（主控现场逐条核；`verify-all.sh` sha16 现为 **`5ee3ad984ee7412d`** —— 主控在 W50B 交件后按"三位位移＋`D-G57` 未修"更正了 DECL/口径句，故比你写记录时的 `50e8fb979a979921` 新）：
#     ① `verify-all.sh:44`（读者 `decl_line()` 取**第一条** ⇒ 机器读**首行**）：`# VERIFYALL-STEPS-DECL: 25 gen=#48   ← `#48` **不动步数**（修 `D-G56`：两个 applier 把插桩横幅插在**类属性块与类声明之间** ⇒ 属性挂错类 ⇒ `NameScope` 挂不上 ⇒ BAML 页加载即 abort；另修 `D-G57`——只动 `windowsbase`/`pf` 两位）`（**`#48` 那行已插在 `#47`（`:45`）之上**）；
#     ② `verify-all.sh:62` `# VERIFYALL-STEP-NAMES: …`（25 个名字；本波**不加步、不改名**）；
#     ③ `verify-all.sh:72`（口径句）：`#   **`#48` 收官起 = 25 步**（**不动步数**：修 **`D-G56`**（`patch-windowsbase-dpvalue-trace.py` / `patch-presentationframework-mirror-trace.py` 的插入锚上移到属性块之外）…）`；
#     ④ 现场 `^run_step "` **25 处**（`grep -c '^run_step "' verify-all.sh` = **25**）= 实测步数 `25`：第 `[16]` 步（`VERIFYALL-SELF`）用 `verify-all-step-check.sh` 抽 `^run_step "NAME"` 的**多重集合**去比声明（步数/步名/次序三处自洽），冻结器 `w27-freeze.py:338-343` 另有两颗牙（`^run_step "` 行数 == 步数 **且** 头注释逐字声明「**`#48` 收官起 = 25 步**」）；
#     ⑤ `docs/WAVE48-PREREGISTRATION.md:1` 标题含 `#48`（读者 `build/MilBridge/tools/verify-all-step-check.sh` 的 prereg 那一档）。
#   仓内自查牙**现场读数**（本车道实跑）：`VERIFYALL_SELF=PASS names=25 decl=25 gen=#48 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=50e8fb979a979921`（rc=0）⇒ **同趟五处已自洽**（本波**不动步数**）。
#   【外挂声明：`D-G27` 的读者要读的 4 类行】⚠️ 谁改它们谁要让读者一起绿。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=960e28f59ee974e5   ← **重取后**的现场值（主控按 `sha256sum build/MilBridge/arm-logs/tline.log` 改写；重取前为 3a6eca716ada5bdb）（主控须在重取后改写，见下 `===RECORD===` 告示②）
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   ⚠️⚠️【**冻结前必做的两件事**（本车道无法代做，做了会越界）】
#     ① 🟡 **`DEFECT-REGISTRY` 会随时变红 —— 冻结前必须复跑一次确认绿**（本车道实测到它**从红转绿的全过程**，如实记）：
#         · **00:14 现场跑** = **rc=1**：`DEFREG=FAIL reason=undeclared-id-in-route`、`D-G59 first-seen=KD:2123`，并 `DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN`、`DEFREG_DECL=n=94 route_ids=95`、`DEFREG_ROUTES=KD=34255dd774998439 …`；
#         · **00:16:05-06 主控已处置**（`KNOWN-DEFECTS.md` 与声明表同趟改：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` mtime `00:16:05`、`build/MilBridge/tools/defect-registry-declared.tsv:1` 逐字 `# DECL-GEN = (--emit) 2026-09-20 00:16:06 +0800`）；
#         · **00:17:30 本车道复跑** = **rc=0**：`DEFREG=PASS declared=96 route_ids=96`、`DEFREG_DECLDRIFT=0`、`DEFREG_DECL=n=96 route_ids=96`、`DEFREG_ROUTES=KD=c244831bb66b65a7 CS=4232c38def314cb7 HO=9f1b05c5c8cefb5a AB=9b9e3cb7bcb8280b`（声明表 sha16 现为 `1fb06485459e90d6`，105 行；`D-G59` 已在表里 = `:77 ID D-G59 req=KD present=KD`）。
#         ⚠️ **为什么仍要写在这里**：这一项在 `GENS['#48']['green']` 里且**不是**声明类 ⇒ 一旦在**冻前那趟 `verify-all`** 里红，`w27-freeze.py:326` 的 `assert _ok` 会**当场 AssertionError**（与 `#47` 那趟的"声明类红可接受"**不是**同一回事）。任何**新登记的 `D-` 编号**或任何 **route 件（`KNOWN-DEFECTS.md`/`CURRENT-STATE.md`/`handoff.md`/`ACCEPTANCE-BASELINE.md`）的改动**都会让它再红 ⇒ 若冻结前还动过登记文本，**先** `bash build/MilBridge/tools/defect-registry-check.sh --emit` 重生成 `build/MilBridge/tools/defect-registry-declared.tsv`、**再**复跑确认 `DEFREG=PASS`。⚠️ 本车道现场核：**该 `.tsv` 不在 `fp_inputs()` 的成员里**（`sed -n '/^fp_inputs()/,/^}/p' build/close-wave.sh | grep -c 'declared.tsv'` = **0**；成员里只有 `defect-registry-check.sh`）⇒ 重生成它**不动 `inputs_fp`**。
#     ② 🔴 **`# ARM-LOG-SHA arm=tline` 那一行的 sha16 只能在重取之后填** —— 上面冻结块里写的是**重取前**的现场值 `3a6eca716ada5bdb`（= `#47` 那一代的稳态值，本车道 00:14 `sha256sum build/MilBridge/arm-logs/tline.log` 复核）。本波 `pc`/`windowsbase` 都变、而 `tline.log:9-10` **自报**它们 ⇒ **重取后必然变**；`build/MilBridge/tools/arm-log-sha-check.sh` 与 `column-floor-check.sh` 的第 ⑤ 档会判 `MISMATCH` ⇒ 冻结器**最后两条断言**（`ARMLOG_SHA=PASS`／`COLUMN_FLOOR=PASS`）会 `AssertionError`。⇒ 请在**重取臂之后、重冻之前**按现场改写该行：`sha256sum build/MilBridge/arm-logs/tline.log | cut -c1-16`（重钉 `known-red.json` 的 `generation.arm_logs[*]` 会同一趟写上**全 64 位**，两者必须一致）。另四行本车道现场核**不含** `pc`/`windowsbase`/`pf` sha ⇒ 预期不变，但同样建议现场复核。
#     （替代做法：若确实不想在记录里维护这一行，**删掉它** —— 第 ⑤ 档只迭代"冻结块声明 ∪ 登记表声明"的交集，少一行只是少一条牙、**不会**判红；但 `#31` 立的这条牙就此退化成 `NOTDECLARED`，**不推荐**。）
#   【① 这一波修的是什么】一条产品缺陷 `D-G56`（**我方 applier 自伤**，不是上游的毛病）：
#     · **`D-G56`**（`#47` 现场由 W47A 发现、**本波修**）：横幅把类属性块与类声明打断 ⇒ `[NameScopeProperty]`/`[TypeDescriptionProvider]`/`[StyleTypedProperty]`/`[XmlLangProperty]`/`[UsableDuringInitialization]` 归属变成插桩类 ⇒ `DependencyObject` 属性数 **0**、`FrameworkElement` 三条也丢 ⇒ BAML 页面 `NameScope` 挂不到根 ⇒ `Storyboard.TargetName` 解析失败 ⇒ 点「工具」页第 2 项即**未处理异常 + core dump**。修法与两极化读数见 FROZEN 段 ①②③。
#       **验收判据（`docs/WAVE48-PREREGISTRATION.md` §2 落地前写死，本波逐条取读数）**：① 生成件里属性紧贴类声明（`sed -n` 原文见 FROZEN ①）；② `ATTRCOUNT DependencyObject ≥ 2` ∧ `scope` 非 null ∧ `FindName(ControlMain)` 非 null（**逐条成立**）；③ 反极性：点「工具」页签 → 点第 2 项 `MorphingAnimation` ⇒ **进程活着**（**成立**，含"关仪器"第二条腿）；④ 防复发判据 ＋ **能两极化证明它会红**（**成立**，四条判据每条都实测过"能红"与"能绿"）；⑤ `D-G57` 先取证再决定是否落 ⇒ **本波未取证、未修**（见 ①b）。
#       ⛔ **反证条件（预登记 §3 写死）**："修后 `attrCount` 仍 0、或 `[NS] scope` 仍 null、或该页仍 abort ⇒ 修法无效，停并撤回结论"。**该反证未触发**（修后 `ATTRCOUNT=2`、`scope=NameScope`、`alive=yes`）—— 如实记，不当作"顺带通过"。
#   【①b **本波未修**（点名留给下一波，别当成已修）】
#     · ⛔ **`D-G57`（页签标题与「实用示例」按钮文字零墨）—— 本波未修、根因仍 `NOINFO`**：读数（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2085-2088`）页签行 `colors=1, stddev=0%`（**纯色零墨**）、按钮 `colors=8, stddev=0.15%`（对照：导航项 `colors=69, stddev=10.47%`、搜索框 `colors=19`）；页签**仍可命中**（点它真换页）⇒ 不是命中问题、是**没画字**。本车道全仓找过：**没有任何 `D-G57` 的修法或新读数**（`grep -rn -- 'D-G57' build/MilBridge/W48*.md` 命中 **0**；唯一命中 `build/MilBridge/W49A-report.md:200` 是它在引用声明行）。⚠️ **但 `verify-all.sh:44` 的 `#48` 声明行与 `docs/WAVE48-PREREGISTRATION.md:1` 的标题都写着"另修 `D-G57`"** ⇒ **声明超出了实际改动**（如实登记为口径不符；**不动声明、不放宽判据**，由主控裁定是补记还是改声明）。
#     · ⛔ **`D-G58`（「工具」页第 2 项 `Effects` 加载即 `NotImplementedException`）—— 本波未修，判定点已收到行、**具体命令 = `NOINFO`**：`D-G56` 修后 `tools#0 HatchBrushGenerator`／`tools#1 MorphingAnimation` **通过**（产品级、无仪器，`alive=yes`），`tools#2 Effects` **仍然死**（`alive=no`）。栈顶 `System.Windows.Media.MediaContext.CommitChannel()` ← `upstream/…/Media/MediaContext.cs:2151` 的 `Channel.Commit();`。**判定点**：C# 里**没有任何** `throw new NotImplementedException()`（全仓只 2 处**注释**解释"native 失败 ⇒ `HRESULT.Check` 抛它"：`src/WpfGfx.Linux/Interop/MilNative.NotificationWindow.cs:14`、`Interop/MilNative.cs:405`）；`MilChannel.Commit()`（`src/WpfGfx.Linux/Resources/MilChannel.cs:241-263`）**返回批里第一个失败 HRESULT**、并把 `E_NOTIMPL` 逐条记进 `NotImplRegistry`/`NotImplCommands`（`:266-274`）⇒ **决策点 = 批里哪一条 `MilCmd` 返回 `E_NOTIMPL`**；取该读数需开桥诊断汇（`MilPresentation.DiagnosticSinkEnabled`，`:247`）—— **本波未取到 ⇒ `NOINFO`**。机制假说（仍是假说）：修前该页 Storyboard 根本没起来，修后**真的播动画** ⇒ 首次走"动画帧提交"路径 ⇒ 撞上未实现命令；**未做**"只回退名字域、其余不动"的对照实验。
#     · ⛔ **`D-G59`（工具缺陷，本波未修）**：`verify-all.sh` 选 X 显示用**字符串序最小**且选定后**整趟不复核**（判定点 `verify-all.sh:366-373`：候选由 `pgrep -a Xvfb … | sort -u` 抽显示号、取第一个 `xdpyinfo` 通的）⇒ 可能选中**别人遗留的死显示**。`#47` 冻后第二趟的现场后果：`[0]` 选中 `:66`（第一趟是 `:97`），该显示在 `[2]` 前已死 ⇒ `XOpenDisplay` NULL ⇒ **47 例 X 用例静默变跳过**（`SKIP_GUARD=FAIL` **正确红** —— 这颗牙值得保留）＋ `ManagedLayer.Tests` 端到端**硬红**。**加害者已由车道 `W50A` 独立复现、并写进 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2138-2143`**：是某车道的**私有 Xvfb**（`$HOME/w48d/run.sh:12` `DISP="${W48D_DISPLAY:-:64}"`；其 `xvfb.log` mtime `23:48:21`/`23:48:53`，而 w49a 那趟 `verify-all` 起于 `23:48:55` —— **差 2 s**；`$HOME/w48d-run/AFTER/app.log:808` 留着 `XIO: fatal IO error 2 … on X server ":66"`），且 `verify-all.sh:370-371` 的 `sort -u` **字符串序让低号胜**（`66` < `97`）。**本波处置（写进 `KNOWN-DEFECTS.md:2143`，不是修法）**：跑 `verify-all` 前**只留一个可用显示**（本波 `:97`）并**复核日志头 `[0]` 报出的显示号**。修法建议未落（①数值序且优先本趟自起的；②选定后 `xdpyinfo` 探活、死了换下一个；③把"选中的显示号 + 探活结果"打进日志头）。
#   【② 为什么此前没被发现】三条，逐条点名：
#     ① **全仓没有任何"属性归属"判据** —— 属性挂错类**不抛异常、不影响编译**，`--check`/`--applier-audit` 只看"锚是否命中 / 生成物是否最新" ⇒ 在**带病**树上 `bash build/check-appliers.sh` 照样 `miss=0 red=0`（`#47` 现场实测）。把它变成读数的，是 `W47A` 才第一次用的 `[NS] ATTRCOUNT`（应用自报属性计数）。
#     ② **它是 applier 插入语义的副作用**：`EDITS` = "把 `TRACE_CLASS` 拼在**锚行前面**"，锚 = 类声明行 ⇒ **只要类声明前有属性行，横幅就必然夹在那里**；机器普查（`W48D-report.md` §7 `R-W48D-3`）在 `build/*.Linux/*.cs` **48 个生成件**上扫这个**形状** ⇒ 命中**恰好 2 处**（就是本波修的两处），另有 **3 处同族但只分尸注释、不分尸属性**（`PresentationFramework.Linux/TextContainer.Linux.cs:112-129`、`TextEditorTyping.Linux.cs:34-45`、`WindowsBase.Linux/Dispatcher.Linux.cs:30-42`）⇒ 判据① 对它们**绿的**（属性块没被碰），本波**不动、仅登记**。
#     ③ **发现它需要"带 `Storyboard.TargetName` 的 BAML 页" ＋ 真的去点它**：修前 Tools 页在第 1 项就 `core dumped`，把 `D-G58`（`E_NOTIMPL`）与 **hc 侧仪器自伤**（`App.xaml.cs` 的 `Describe()` 对 `e.OriginalSource`＝`Run` 调 `VisualTreeHelper.GetParent` ⇒ 上游按**设计**抛 `InvalidOperationException: '…Run' is not a Visual or Visual3D.` ⇒ 挂在类处理器里无人接 ⇒ 进程死）**一起盖住** ⇒ `W48D-report.md` §5 的"关仪器第二条腿"是唯一把它们分开的办法。该仪器自伤归**仪器**（只在 `HC_INPUT_DIAG=1` 时装那个 handler；栈顶落在 hc 侧、不在产品里；抛的是上游自己的契约 `upstream/…/Media/VisualTreeHelper.cs:116-128`）⇒ **不是产品缺陷、不是本波改动引起的**；主控已落修法（向上循环里先判 `cur is Visual` 且把 `GetParent` 包 `try/catch`，纯仪器、零产品影响）。
#   【③ `inputs_fp` 的变化与原因点名】`8a8661b926e47489b9840736992209d3977ab10429e42dcdcbe9df1a5a0ddeaf` → **`cad0801cf1dff2fdf1600b803315d1c57b0d2afcc9ebf45e170f2b3885677da4`**（本代 `infp=None`，冻结器**不断言**旧值）。可归因**两件**，与 `docs/WAVE48-PREREGISTRATION.md:23` 的两条预测**逐条对上**：
#     ① **两个 applier 在 `fp_inputs()` 覆盖面里**（`build/close-wave.sh:104-108`：`find src/WpfGfx.Linux.Native/tools build \( -maxdepth 2 -name 'patch-*.py' -o -maxdepth 1 -name 'port-lib.py' … \)` **点名** `patch-*.py`）⇒ 本波改的 `patch-windowsbase-dpvalue-trace.py`（`1bff235f3d389788` → `5203f958c234882f`）与 `patch-presentationframework-mirror-trace.py`（`a4e6599a8f0a9e75` → `1b9852b037da70f1`）**必然**移动 `inputs_fp`（设计使然）。
#     ② **重钉 `build/MilBridge/known-red.json`** —— 重取五臂后四处必须同趟钉齐（`D-G19` 的教训），而它是 `fp_inputs()` 的**点名成员**（`build/close-wave.sh:179` 的 `printf` 那一行）；重钉前现场值 `00a75a87ec5ed0d6`（406 行），重钉会改 `generation.arm_logs[*]` 与 `evidence_log_sha256`（`tline` 变）＋ 追加 `arms_retaken.history`。
#     ⚠️ **两件可分离归因（本车道 00:14:55 现场算，重钉前）**：`inputs_fp` 已从 `8a8661b926e47489b9840736992209d3977ab10429e42dcdcbe9df1a5a0ddeaf` 变为 **`b983d9bee6c36b5e88dd1a3587d8724c3680479e521cb5c1531c0fc1b868c9bf`** —— 这一跳**只由 ①** 造成（当时 `known-red.json` **仍是** `00a75a87ec5ed0d6`、**未重钉**）⇒ 重钉那一跳是**第二因**、尚未发生。⚠️ 这条也顺带证明"`inputs_fp` 确实在看着 applier"（不是纸面承诺）。
#     ⚠️ **与 `#47` 的差异（如实记）**：`#47` 只有"重钉"一因（本波的产品改源是 shim 的 C 源，**不在**覆盖面里，见 `#47` 的 `R-CSRC`）；**本波的产品改源就在覆盖面里** ⇒ 本波的 `inputs_fp` 变化是**两因**。
#   【④ 本波登记的风险/欠账（自陈）】
#     🟡 **`R-DEFREG`**：见文首告示① —— `DEFECT-REGISTRY` 在 00:14 是**真红**（`D-G59` 未进声明表）、00:16 已由主控 `--emit` 处置、00:17:30 复跑 = **`DEFREG=PASS`**；但它**是绿的函数、不是常量**（新登记编号或 route 件改动 ⇒ 再红）⇒ **冻前那趟必须复跑确认**。
#     🟡 **`R-DECLDRIFT`（本波实测过它的两态）**：`DEFREG_DECLDRIFT` 在 00:14 是 `1 changed-route-files-since-DECL-GEN`、在 00:17:30 是 **`0`** ⇒ 这个字段就是"route 件（`KNOWN-DEFECTS.md`/`CURRENT-STATE.md`/`handoff.md`/`ACCEPTANCE-BASELINE.md`）是否在本代声明之后被动过"的读数，与 `R-DEFREG` 同根；**改登记文本必须与声明表同趟**。
#     🔴 **`R-AL`**：见文首告示② —— `# ARM-LOG-SHA arm=tline` 的 sha16 **只能在重取之后填**；填错 ⇒ `column-floor-check.sh` 第 ⑤ 档 `MISMATCH` ⇒ 冻结器最后一步崩。
#     🟡 **`R-REPIN`（沿用 `#46`/`#47` 的发现）**：`repin-generation.py` **不做新鲜度/原因校验**（`--why` 只追加）⇒ **重钉只做一趟**、且它能**把陈旧臂日志洗成绿**。
#     🟡 **`R-ARMSTALE`（沿用 `#46` 的 R8 / `#47` 的 R-ARMSTALE）**：五臂重取后必须核"五份 `mtime` 全晚于重取开始时刻"，否则是**陈旧日志被重钉洗绿**。本车道现状实测（00:14）：五份 `mtime` = `tline 23:07:54`／`tab-zero 23:08:33`／`tab-anchor 23:11:33`／`tab-rtl 23:11:39`／`textlineproto 23:11:48`，`links=2`（仍是 `#47` 那趟的硬链接件）⇒ **本波尚未重取**。
#     🟡 **`R-CSRC`（`#47` 已登记的欠账，仍在）**：shim 的 C 源 `src/WpfGfx.Linux.Native/src/**` **不在 `fp_inputs()` 覆盖面** ⇒ "改产品源必须看得见"在 shim C 源上仍是欠账（本波不涉及，但别把它当成"已经看得见"）。
#     🟡 **`R-APPSYNC`（现场读数，未定性 ⇒ `NOINFO`）**：本波整波日志 `$HOME/w50a/02-integration-wave.log:152` 自报 `APPSYNC=MISMATCH（MISMATCH=0[STALE=0 NEWER-DIFF=0] MISSING=0 UNEXPECTED=12[DECL-GAP-EQ=8 DECL-GAP-DIFF=4] DIVERGENT=4 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0 …）`，同趟 `:151` `APPSYNC-REFRESH=refreshed=47 newer=0 applied=1`、`:153` `校验器：刷新前 exit=1 / 刷新后 exit=1`。属"app-local 副本表 / 声明覆盖面"欠账（`#46` 的 `W1`、`#47` 的 `R-APP` 同族），**归因 `NOINFO`**（本车道未追）。⇒ 收尾时**别让探针测到旧件**。
#     🟡 **`R-PCCOPY`（`W48D-report.md` §7 `R-W48D-5`，本波应已收敛、但需现场复核）**：`W48D` 单件重建时 `build/PresentationCore.Linux/bin/Release/WindowsBase.dll` 曾是**陈旧副本**（`84a2826c471e60ea`）；整波重建会刷新它 —— 判据不用它、只作为"探针别测到旧件"的提醒（`#47` 的 §13 纪律③：app-local 副本这一跳有两半）。
#   【⑤ 未达标 / 未做 / 已知限制（不许当绿）】
#     ⏳ **`D-G57` 本波未修**（根因 `NOINFO`）⇒ 见 ①b；**不许**因为"页签能点"就把它读成绿。
#     ⏳ **`D-G56` 撤登记判据③的"3 项逐项点一遍"只完成 2/3**：`HatchBrushGenerator`（#0）与 `MorphingAnimation`（#1）**实测通过**；`Effects`（#2）死于**另一条**缺陷（`D-G58`）⇒ 那一格**只能是 `NOINFO`**，**不能读成绿**，但也**不是 `D-G56` 复发**。
#     ⏳ **`#47` 的"冻后两趟"实际只有 1 趟有效 —— 纪律事故，如实登记、不粉饰**：第一趟（`$HOME/w49a/post-freeze-1.log`）`rc=0`；**第二趟**（`$HOME/w49a/post-freeze-2.log`，`23:48:55`→`00:09:01`）`rc=1`，且**同时踩了两条独立的并发事故**：① `[0]` 选中别人遗留的 `:66` 死显示（＝ `D-G59` 的现场形态）；② **另一条车道在该趟执行期间就地改写了 `verify-all.sh`**（`gen=#47` → `gen=#48`，sha16 `bde0bce61f2ffbac` → `50e8fb979a979921`，mtime `23:53:14`）⇒ bash **边读边执行**脚本 ⇒ 步 `[6] FrameProbe-frame` 被执行**两次** ＋ 三条 stderr（`verify-all.sh: 行 517: … 未找到命令`／`/: 是一个目录`）。⇒ **该趟不可归因、整份作废**；**第二趟尚未重取** ⇒ `#47` 与"冻后 ×2"的这条偏离**就此留在案**（判据仍是 `rc=0` ∧ `步骤通过 25 ❌ 失败 0` ∧ 失败步名为空 ∧ `SKIP_GUARD=PASS`）。
#     ⏳ **`verify-all.sh` 被改的次数与每次时刻 = `NOINFO`**（mtime 只留最后一次）⇒ 可证明的只有"第二趟 `:93` 读到的是现树那份"。
#     ⏳ **本波的车道自陈（`W48D-report.md` §6）**：① 一条**作废的读数**（`Q6c` 相位漏了 `geoblock` ⇒ 页签那一下根本没点，脚本照样打印 `alive=yes`，读到的其实是「样式」页 ⇒ 整份作废重跑）；② hc 侧仪器自伤（`Run` 崩溃，见 ②③）；③ `python3 -m py_compile` 在已有 `__pycache__/` 里新增两份 `.pyc`（`fp_inputs()` 的模式是 `-name 'patch-*.py'`、**不匹配 `.pyc`** ⇒ 不动 `inputs_fp`；保留不删）。
#     ⏳ **`#46` 留的活照旧**：`P3` 阈值重标（判据页明令不许放宽）、`D-G54` 的 `WS_EX_LAYERED` 呈现腿、`D-T4`/`D-G48` 的产品修、`#46` 的 `R10`（route/声明件不在覆盖面）与 `W1`（桥副本同步）欠账。
#   【⑥ 五臂与门禁】本波位移集合 = `windowsbase`（产品）＋ `pf`（产品）＋ `pc`（整波重建）**三位**；五臂**由主控在收尾链里重取**（本车道未跑、未重钉、未冻结）；应用门禁 6 条机读行**本车道未跑**（`NOINFO`，见 BANNER 的 `{待主控补}`）；五臂日志两种聚合口径（冻结时现算）＝ `cat` 口径 `9e4f1f6f47aebbbb`／`find|sort|xargs` 口径 `9824258f1564273b`。
#   【`NOINFO`】① **应用门禁 `run_dir` / rows 文件 / 6 条机读行**（本车道写记录时 `$HOME/w50a/` 下**没有**门禁目录 ⇒ 未跑，见 BANNER）；② **五臂日志重取后的 sha**（尤其 `tline` 的重取后值，见文首告示②；并须核五份 `mtime` 全晚于重取开始时刻）；③ **重钉后的 `known-red.json` 终态 sha**（重钉前 = `00a75a87ec5ed0d6`，406 行）；④ **本波 `inputs_fp` 终值**（`cad0801cf1dff2fdf1600b803315d1c57b0d2afcc9ebf45e170f2b3885677da4` 由冻结器现算；重钉前现场 = `b983d9bee6c36b5e88dd1a3587d8724c3680479e521cb5c1531c0fc1b868c9bf`）；⑤ `25`/`871`/`2` 由冻结器从**冻前那趟 `verify-all` 日志**现算（本波**不动步数** = 25）；⑥ 九位里 `e3ea092010734f44`/`9465f9dce39e2dfc`/`1011da6390c3bf1e`/`abf6879c027c5e73` 的终值由冻结器现算（本车道现场值仅供对账、且**非终值**：`bridge e3ea092010734f44`、`pc 9465f9dce39e2dfc`、`pf 1011da6390c3bf1e`、`windowsbase 79740e9ba7fbf9ca`、`provider 1f9511a7ef395bfe`、`win32shim abf6879c027c5e73`、`wic_shim 56278c14b4ecd672`、`hbtextline e89fed55fd8e32bc`、`dwf de2d555105b7d04b`，00:14:55 现场算）；⑦ **`D-G57` 的根因与修法**（本波未取证）；⑧ **`D-G58` 那条 `E_NOTIMPL` 的具体 `MilCmd`**（需开桥诊断汇）；⑨ **`D-G59` 的修法**（本波未落）；⑩ **`#47` 冻后第二趟的有效重取**（尚未做）；⑪ **`APPSYNC=MISMATCH` 的 `UNEXPECTED=12[DECL-GAP-EQ=8 DECL-GAP-DIFF=4]`／`DIVERGENT=4` 归因**；⑫ **`[UsableDuringInitialization]`/`[XmlLangProperty]`/`[StyleTypedProperty]` 三条属性各自的行为后果**未逐条测（本波只证了"属性回到了类身上"这件事本身）。
BASELINE tier=default rep=1 config=pc:9465f9dce39e2dfc,bridge:e3ea092010734f44,pf:1011da6390c3bf1e,provider:1f9511a7ef395bfe,win32shim:abf6879c027c5e73,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w50a/gate-e
BASELINE tier=default rep=2 config=pc:9465f9dce39e2dfc,bridge:e3ea092010734f44,pf:1011da6390c3bf1e,provider:1f9511a7ef395bfe,win32shim:abf6879c027c5e73,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w50a/gate-e
BASELINE tier=default rep=3 config=pc:9465f9dce39e2dfc,bridge:e3ea092010734f44,pf:1011da6390c3bf1e,provider:1f9511a7ef395bfe,win32shim:abf6879c027c5e73,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=261 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=4112 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w50a/gate-e
BASELINE tier=env rep=1 config=pc:9465f9dce39e2dfc,bridge:e3ea092010734f44,pf:1011da6390c3bf1e,provider:1f9511a7ef395bfe,win32shim:abf6879c027c5e73,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w50a/gate-e
BASELINE tier=env rep=2 config=pc:9465f9dce39e2dfc,bridge:e3ea092010734f44,pf:1011da6390c3bf1e,provider:1f9511a7ef395bfe,win32shim:abf6879c027c5e73,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w50a/gate-e
BASELINE tier=env rep=3 config=pc:9465f9dce39e2dfc,bridge:e3ea092010734f44,pf:1011da6390c3bf1e,provider:1f9511a7ef395bfe,win32shim:abf6879c027c5e73,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2945 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w50a/gate-e
# ⏪ **（历史，已被 `#48` 取代）**# RE-FROZEN #47 —— ✅ **当前冻结基线** —— 内容 = 修 **`D-G55`**（`SetCapture`/`ReleaseCapture` **只改软状态、一条消息都不派发** ⇒ 上游 `Mouse.Captured` 恒不复位 ⇒ **点过一次控件之后，窗口内后续点击全被路由到那个控件**）；本波**产品改源只有 `win32shim` 一位**（`pc`/`pf` 的位移见下方归因）。
#   ① **`win32shim`（本波必做项）**：`D-G55` = 用户报告"hc 能跑，但界面里点击没反应，包括输入框和列表项"的**直接成因**（本仓**⑬ 块 `clickprobe` 是上一件 `W47B` 才立起来的判据**）。
#     · **两极化读数**（同一进程、同一坐标，**只差"点击之间有没有把指针移出窗口"**；装置 = `samples/WpfFeatureProbe/FeatureBlocks.cs:1112` 的 ⑬ 块 ＋ 驱动器 `$HOME/w47b-click.sh`（sha16 `7e86e3f105dc8778`，私有 X 显示 ＋ `xdotool` `mousedown`→停 150 ms→`mouseup`）：
#       ⛔ **修前 · 连做**（真实用户动作；`$HOME/w47b-out-0919-224552/READING.txt`，sha16 `78f7c01039a9291b`）：S2/S3 的 `src=ListBox directlyover=ListBox **captured=ListBox**`，而**当场**重算 `freshhit=TextBoxView`/`DockPanel` 是对的 ⇒ `tb.focus` **0 次**、`combo.opened` **0 次**、`tb.text` **0 行**；`WM_LBUTTONDOWN=9 WM_LBUTTONUP=9`（点**确实**到了窗口，不是"没点到"）。
#       ✅ **修前 · 单发**（每一步之间先把指针停到窗口外）：三类**全部命中**（`lst.selection=1`／`tb.focus`／`combo.opened` ＋ 下拉测试色 `22D3EE=19,449 px`）—— **这正是本缺陷此前"看不见"的原因**：拍干净帧/找指针必须把指针移出窗口，而**移出窗口恰好就是释放捕获的动作**。
#       ✅ **修后 · 连做**（`$HOME/w47-verify-new/READING.txt`，sha16 `31155505efaf6bef`；件 = `win32shim` `abf6879c027c5e73`）：S2/S3 **按下瞬间** `captured=TextBox`／`captured=ComboBox`，而三段**抬起之后**都回到 `captured=null`（S1 全程 `null`；那份读数的"move 末行"`captured=ComboBox` 是 S3 **按下那一瞬间**的采样，不是终态）；
#         `tb.focus 次数=2`、`tb.text` **6 行**（`abc` 逐字进：`=1 'a'`／`=2 'ab'`／…／`=6 'abcabc'`）、`combo.opened=2`、`combo.closed=1`、`combo.selection=1`、`lst.selection` 序列 `1 → 0 → 1`（阴性对照：点卡片空白只出 `card.pos`；改点第 0 项 ⇒ 选择跟着走）。
#         ⚠️ **口径勘误（本车道现场核出，如实记）**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `D-G55` 节把修后读数写成 `tb.focus 0→3`／`tb.text →7`；**盘上那份读数文件逐字是 2／6**（`grep -o 'tb.focus 次数=[0-9]*' "$HOME/w47-verify-new/READING.txt"` = **2**）。两处同一装置、同一件、同一驱动 ⇒ **以读数文件为准**；`3`/`7` 的出处本车道**找不到**（登记为待更正项，不作为判据）。
#     · **机制链（源码级闭合，逐跳 `file:line`）**：上游 `MouseDevice.cs:386-394` 清内部捕获状态**只认** `RawMouseAction.CancelCapture`（托管状态在 `MouseDevice.cs:1028-1047` 的 `ChangeMouseCapture()`，即 `Mouse.Captured`）；
#       该动作的**唯一来源** = `HwndMouseInputProvider` 处理 **`WM_CAPTURECHANGED`**（`:679` 的 `case WindowMessage.WM_CAPTURECHANGED:` ⇒ `:730-737` 在 `!IsOurWindow(lParam) && _active` 下上报 `RawMouseActions.CancelCapture`；本车道现场逐行核过上游原文）；
#       而本 shim 的 `SetCapture`/`ReleaseCapture`（`src/WpfGfx.Linux.Native/src/win32_core.c:970-998`）**只改软状态、不派发任何消息**（全仓 `WM_CAPTURECHANGED`/`0x0215` 在 `src/WpfGfx.Linux.Native/**` 原本 **0 命中**）—— 对照：**同一个文件**的 `SetFocus():942-955` **会**派发 `WM_KILLFOCUS`/`WM_SETFOCUS` ⇒ **同一模式漏了捕获这一路**（`D-G49` 那条修法同族）。
#     · **修法（`win32shim` 位 `e700c383ec1ecdc8` → `abf6879c027c5e73`：两处派发 ＋ 一个常量；源件 sha16 = `win32_core.c` `4e054c88cc3f5fce`／`win32_internal.h` `472e6560024f758c`）**：
#       `win32_core.c:983`（`SetCapture` 易主时向**失去捕获**的窗口派发，`lParam` = 新捕获窗口：`if (old && old != hwnd) wpf_dispatch_to_window(old, WM_CAPTURECHANGED, 0, (LPARAM)hwnd);`）；
#       `win32_core.c:996`（`ReleaseCapture` 向旧窗口派发，`lParam = 0` ⇒ `!IsOurWindow(0)` 成立 ⇒ 命中上游 `CancelCapture` 分支：`if (old) wpf_dispatch_to_window(old, WM_CAPTURECHANGED, 0, 0);`）；
#       `win32_internal.h:40` `#define WM_CAPTURECHANGED 0x0215`（**本波没有**引入任何新 applier、没有改 `src/WpfGfx.Linux/**`）。
#     · **反证条件（预登记 §2 落地前写死）**："若**连做**序列下 `captured` 仍钉住 ⇒ 修法无效，停并撤回结论"。**该反证未触发**：修后 S1–S3 三段**抬起后** `captured=null`、三类控件事件齐（读数见上）—— 如实记，不当作"顺带通过"。
#     · **为什么此前没被发现**：本仓**没有任何"连续点击"判据**；既有门禁里与"点击后该出现什么"最接近的一条是 `nativecombo:!7C3AED` 这种**负向式**（无人点击时不该出现测试色 ⇒ 从不渲染它**照样绿**），而**像素/`AE` 类**判据要拍干净帧**必须把指针移出窗口**、那正好是**释放捕获**的动作 ⇒ **系统性藏住**这一类缺陷（`W47B` 已把这条自伤如实登记：`build/MilBridge/W47B-report.md` §5）。
#   ② **九位（Release 权威件）**：`bridge` `e3ea092010734f44`（5019968 B）／`pc` `043eff4b1d8ecd7d`（3601408 B）／`pf` `366e9486536bc291`（6119424 B）／`windowsbase` `84a2826c471e60ea`／`provider` `1f9511a7ef395bfe`／`win32shim` `abf6879c027c5e73`／`wic_shim` `56278c14b4ecd672`／`hbtextline` `e89fed55fd8e32bc`（290825 B）／`dwf` `de2d555105b7d04b`。
#     ⚠️ **`pc`/`pf` 为什么会变（如实归因）**：**不是**因果耦合，而是**整波重建即变字节**（非确定构建：MVID／内嵌时间戳；`#44`/`#46` 两趟实测同形态）。本波的**产品改源只有 `win32shim` 一位**；预登记 §3 的预测（"只有 `win32shim` 必变；`pc`/`pf` 可能因整波重建变字节；`bridge` 源未动、AOT 可复现 ⇒ 预期不变"）与本代 `allow_changed={'pc','pf','win32shim'}` 一致。
#     ⚠️ **`bridge` 若动了 ⇒ 停下来核**：源未改而 AOT 件逐位变 = **表外位移**，冻结器会当场 `AssertionError`（停条件①）。
#   ⚠️ **位移对账（两栏，别混读）**：
#     · **相对 `#46` 冻结值那一栏**（`ACCEPTANCE-BASELINE.md` 旧块，逐字）：`win32shim` `e700c383ec1ecdc8` → `abf6879c027c5e73`；`pc` `043eff4b1d8ecd7d` → `043eff4b1d8ecd7d`；`pf` `366e9486536bc291` → `366e9486536bc291`
#       ⇒ **本波三位变**（`win32shim` 是产品位移，`pc`/`pf` 是重建位移）；其余**六位逐位未变**（`bridge` `e3ea092010734f44` == `e3ea092010734f44`、`windowsbase` `84a2826c471e60ea` == `84a2826c471e60ea`、`provider` `1f9511a7ef395bfe` 未动、`wic_shim` `56278c14b4ecd672` 未动、`hbtextline` `e89fed55fd8e32bc` 未动、`dwf` `de2d555105b7d04b` == `de2d555105b7d04b`）。
#     · **相对开工快照 `PRE`**（`/home/links-dev/w47-pre.sha`，9 行，`31bdf7662131ff64`）：本波 `PRE` **逐行就是 `#46` 冻结值**（本车道现场核对：九位与 `#46` 冻结块**逐字相同**）⇒ 冻结器算出的 `changed` = **产品位移本身**（`#46` 那趟同口径，不是事故；这是**更严**的一栏）。
#     · ⚠️ 本代 `prev_pc=043eff4b1d8ecd7d`／`prev_pf=366e9486536bc291`／`prev_wsh=e700c383ec1ecdc8`／`prev_wb=84a2826c471e60ea`／`prev_dwf=de2d555105b7d04b` **全部与 `#46` 冻结值一致**（= `PRE`）——`#46` 那趟 `prev_pc` 是"波内中间值"的歧义，**本代没有**。
#   ⚠️ **`BRIDGE_SRC_FP` = `f10b4b297b2358e6`**（上一代 `f10b4b297b2358e6`，**两侧同值**）：本波**没改** `src/WpfGfx.Linux/**` ⇒ 值不变，且"**现树 == 发布记录**"两侧一致（发布记录 `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/bridge-src-fp.txt` 逐字 `BRIDGE_SRC_FP=f10b4b297b2358e6`／`PUBLISHED_AT=2026-09-19T20:48:55+08:00`；本车道现场跑 `bash build/bridge-src-fp.sh` = `f10b4b297b2358e6 BRIDGE_SRC_N=78`）⇒ `close-wave.sh:301-304` 的桥身份自检**会过**，且 `close-wave.sh` 的 `[3/6]` 步会**跳过重发**（源指纹一致）。
#   **臂日志**：位 sha 变 ⇒ 按纪律**重取五臂**（`ARMS_OUT=NOINFO`：本车道写记录时**尚未重取**，输出目录由主控按现场定；`#46` 的形状 = `$HOME/w46h/arms` ＋ `ln -f` **硬链接**进 `build/MilBridge/arm-logs/`，五份 `links=2`）。
#     预测（**未被本车道证实**，如实标）：**只有 `tline` 一支会变** —— 它自报权威件 `pc`/`pf` 的 sha（现场核：五份臂日志里**只有** `tline.log` 含 `043eff4b1d8ecd7d`/`366e9486536bc291`，其余四份 **0 命中**），而 `pc`/`pf` 本波重建 ⇒ 该行内容必换；三支 `tab-*` 与 `textlineproto` 预期**逐位不变**（`#46` 那趟的实测先例）。
#     `GEN_KEYS` 三件（`instr_run_sh`=`build/MilBridge/run.sh`／`instr_program_cs`=`HbTextLineParity/Program.cs`／`instr_shim`=`build/shims/PresentationCore.HbTextLine.cs`）**本波未动** ⇒ `entries[*].caliber` **0 改动**，重钉后 `--check` 应收敛到 `REPIN_GENERATION=PASS`（`build/MilBridge/tools/repin-generation.py`）。
#     ⚠️ **重钉不幂等**（`#46` 实测的新发现，本波照旧）：`--why` 的值**只追加**进 `generation.arms_retaken.history`，**同一条 `--why` 再跑一次仍会写盘并再追加一条** ⇒ **重钉只做一趟、`--why` 必须给**（`#46` 的 `known-red.json` 因此从 `7deadeac97659e46` → `8680255933728e95` → `1fa4c4540fe1b69f`）。本波重钉**前**现场值 = **`1fa4c4540fe1b69f`**（402 行，= `#46` 终态；本车道现场 `sha256sum` 复核）。
#   **`verify-all` 同趟五处已改到 `#47`**（本车道现场逐条核，`verify-all.sh` sha16 `bde0bce61f2ffbac`）：
#     ① `verify-all.sh:44`（读者 `decl_line()` 取**第一条** ⇒ 机器读**首行**）：`# VERIFYALL-STEPS-DECL: 25 gen=#47   ← `#47` **不动步数**（修 `D-G55`：`SetCapture/ReleaseCapture` 不派发 `WM_CAPTURECHANGED` ⇒ `Mouse.Captured` 恒不复位；只动 `win32shim` 一位）`；
#     ② `verify-all.sh:61` `# VERIFYALL-STEP-NAMES: …`（25 个名字；本波**不加步、不改名**）；
#     ③ `verify-all.sh:71`（口径句）：`#   **`#47` 收官起 = 25 步**（**不动步数**：修 **`D-G55`** —— 上游 `MouseDevice` 清捕获状态只认 `RawMouseAction.CancelCapture`，其唯一来源是 …）`；
#     ④ 现场 `^run_step "` **25 处**（`grep -c '^run_step "' verify-all.sh` = **25**）= 实测步数 `25`：第 `[16]` 步（`verify-all.sh:676`，`VERIFYALL-SELF`）用 `verify-all-step-check.sh` 抽 `^run_step "NAME"` 的**多重集合**去比声明（步数/步名/次序三处自洽），冻结器 `w27-freeze.py:326-331` 另有两颗牙（`^run_step "` 行数 == 步数 **且** 头注释逐字声明同一数字）；
#     ⑤ `docs/WAVE47-PREREGISTRATION.md:1` 标题含 `#47`（读者 `build/MilBridge/tools/verify-all-step-check.sh` 的 prereg 那一档）。
#     仓内自查牙**现场读数**（本车道实跑）：`VERIFYALL_SELF=PASS names=25 decl=25 gen=#47 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=bde0bce61f2ffbac`（rc=0）⇒ **同趟五处已自洽**（本波**不动步数**）。
#   【外挂声明：`D-G27` 的读者要读的 4 类行】⚠️ 谁改它们谁要让读者一起绿。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=3a6eca716ada5bdb   ← 重取后现场值（主控按 `sha256sum build/MilBridge/arm-logs/tline.log` 改写）
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   ⚠️⚠️【**冻结前必改的一行**（本车道无法代填）】上面 `# ARM-LOG-SHA arm=tline` 那一行的 `sha16=` 是**重取前**的值 `e061054f73c9a2e7`。本波重建了 `pc`/`pf`，而 `tline.log` **自报**它们 ⇒ **重取后必然变**；`build/MilBridge/tools/arm-log-sha-check.sh` 与 `column-floor-check.sh` 的第 ⑤ 档会判 `MISMATCH` ⇒ **冻结器最后两条断言**（`ARMLOG_SHA=PASS`／`COLUMN_FLOOR=PASS`）会**当场 AssertionError**。
#     ⇒ 请在**重取臂之后、重冻之前**按现场改写该行：`sha256sum build/MilBridge/arm-logs/tline.log | cut -c1-16`（重钉 `known-red.json` 的 `generation.arm_logs[*]` 会同一趟写上**全 64 位**，两者必须一致）。另四行（`tab-anchor`/`tab-zero`/`tab-rtl`/`textlineproto`）本车道现场核**不含** `pc`/`pf` sha ⇒ 预期不变，但**同样建议现场复核**。
#     （替代做法：若确实不想在记录里维护这一行，**删掉它**即可 —— 第 ⑤ 档只迭代"冻结块声明 ∪ 登记表声明"的交集，少一行只是少一条牙，**不会**判红；但 `#31` 立的这条牙就此退化成 `NOTDECLARED`，**不推荐**。）
#   【① 这一波修的是什么】一条产品缺陷 `D-G55`（**用户报告的"点击没反应"的直接成因**）：
#     · **`D-G55`**（`#47` 现场发现、**本波修**）：在冻结件 `#46`（`win32shim e700c383ec1ecdc8`）上，**点一次控件之后 `Mouse.Captured` 一直挂在那个控件上**；此后鼠标点到窗口内**任何别的地方**，事件都被送给上一个控件（`e.OriginalSource`/`Mouse.DirectlyOver` 冻结在上一个控件，而**当场** `VisualTreeHelper.HitTest` 报的是正确元素 ⇒ 分叉在"**路由按捕获、命中按位置**"）⇒ 表现为**连点三个控件只有第一个有反应**。
#       根因 = shim **不派发 `WM_CAPTURECHANGED`**（见 FROZEN 段 ①的逐跳链）；修法 = 两处派发 ＋ 常量 `0x0215`。
#       **验收判据（预登记 §2 落地前写死，本波逐条取读数）**：仓内 ⑬ 块**连做**序列下 `tb.focus ≥ 1` ∧ `tb.text` 增长 ∧ `combo.opened ≥ 1` ∧ `combo.selection=1` ∧ `combo.closed ≥ 1` ∧ `lst.selection` 出现 —— **修后逐条成立**（读数原文见 FROZEN 段 ①）；**反极性**（"抬起后 `captured` 是否仍钉住"）也在同趟读到位（抬起后 `captured=null`）。
#     · ⛔ **本波如实登记的两条"没做到"**：① 预登记 §2 的**仓外 hc 腿**（`NativeTextBoxDemo` 点 TextBox ⇒ 焦点；**随后**点别处仍要有反应）**本车道写记录时尚未收口**（`$HOME/w47a-run/**` 的 hc 复测在飞，见 `NOINFO`）；② `KNOWN-DEFECTS.md` 的 `D-G55` 节里修后读数与盘上读数文件**不一致**（`3`/`7` vs `2`/`6`，见 FROZEN 段 ①口径勘误）。
#   【② 为什么此前没被发现】三条，逐条点名：
#     ① 本仓**从来没有"连续点击"判据** —— ⑬ 块 `clickprobe` 是**上一件**（`W47B`，`build/MilBridge/W47B-report.md`，sha16 `760e56072d7f90ef`）才立起来的，而它**不在任何自动门禁的驱动路径里**（判词由外部驱动给，块自报 `INCONCLUSIVE`）；
#     ② **像素/`AE` 类判据对此类缺陷系统性假绿**：要拍干净帧就必须把指针移出窗口 = **释放捕获**（`W47B` §5 自伤第 1/2 条）；
#     ③ 门禁里与点击最接近的那条 `nativecombo:!7C3AED` 是**负向式**（无人点击时不出现测试色）⇒ "点了也开不了"**照样绿**（`#46` 已对这条同类口径明说"只算吻合、不是证明"）。
#   【③ `inputs_fp` 的变化与原因点名】`a47546ec0ed887f8b344a3c8367424cbab55d87eb90dceef5cb6dd3bf3ff0807` → **`8a8661b926e47489b9840736992209d3977ab10429e42dcdcbe9df1a5a0ddeaf`**（本代 `infp=None`，冻结器**不断言**旧值）。可归因**一件**：
#     ① **重钉 `build/MilBridge/known-red.json`** —— 重取五臂后四处必须同趟钉齐（`D-G19` 的教训），而它是 `fp_inputs()` 的**点名成员**（`build/close-wave.sh:179` 的 `printf` 那一行）；重钉前现场值 `1fa4c4540fe1b69f`，重钉会改 `generation.arm_logs[*]` 与 `evidence_log_sha256`（`tline` 变）＋ 追加 `arms_retaken.history`。
#     ⚠️ **与 `#46` 的差异（如实记）**：`#46` 还有第二因"新 applier 进覆盖面"；**本波没有**新 applier、也没有改 `close-wave.sh`/`tline-gate.sh`。
#     ⚠️ **本波的产品改源不在覆盖面里（本车道现场核出的欠账）**：`src/WpfGfx.Linux.Native/src/**`（`win32_core.c`/`win32_internal.h`）**不在 `fp_inputs()` 的任何一条 `find` 里**（`sed -n '/^fp_inputs()/,/^}/p' build/close-wave.sh | grep -c 'WpfGfx.Linux.Native/src'` = **0**；覆盖面只有 `src/WpfGfx.Linux.Native/tools` 的 `patch-*.py`、`build/shims/*.cs`、`src/WpfGfx.Linux/**/*.cs` 与门禁/登记表那一组文件）⇒ **改 shim 的 C 源不动 `inputs_fp`**；本波 `inputs_fp` 若变，**只**来自重钉。
#       ⇒ 欠账（下一波办）：把 shim 的 C 源纳进覆盖面**或**另立一颗牙（`#14` 那次"改 shim 必须看得见"的原意，目前只覆盖 `*.cs`）。
#   【④ 本波登记的风险/欠账（自陈）】
#     🔴 **`R-AL`（本记录里最硬的一条，见文首告示）**：`# ARM-LOG-SHA arm=tline` 的 sha16 **只能在重取之后填** —— 填错 ⇒ `column-floor-check.sh` 第 ⑤ 档 `MISMATCH` ⇒ 冻结器**最后一步**崩。
#     🔴 **`R-CSRC`（欠账）**：shim 的 C 源不在 `fp_inputs()`/`GEN_KEYS` 覆盖面（见 ③）⇒ 本波"改产品源"这件事**在 `inputs_fp` 那一格上看不见**（`#14` 同族：那一格的量程没盖住这一位）。
#     🔴 **`R-GATE`（假绿口子，须写明）**：本波把 ⑬ 块登记进了门禁（`run-wpfprobe.sh:325` 的 `BLOCKS` 末尾 ` clickprobe` ＋ `:609` 的 `EXPECT "clickprobe:!22D3EE"`），但那条 EXPECT 是**负向式**（静止时不该出现下拉项容器的测试色）⇒ **`WFP_GATE=PASS` 只证明"没画错"，不证明"点击有反应"**；本缺陷的回归网承重的仍是**外部真实点击的序列判据**（`$HOME/w47b-click.sh` §4），**不在自动门禁里**。⇒ 建议下一波把它接线（或至少写进门禁的"已知半自动"栏）。
#     🟡 **`R-REPIN`（沿用 `#46` 的发现）**：`repin-generation.py` **不做新鲜度/原因校验**（`--why` 只追加），**重钉只做一趟**。
#     🟡 **`R-APP`（现场读数，未定性）**：本波在飞的 `bash build/publish-milbridge.sh`（`$HOME/w48a/01-publish.log`）自报 `APPSYNC=MISMATCH`（`MISMATCH=5[STALE=5 NEWER-DIFF=0]`、`DIVERGENT=3`），而日志自己写着"上述副本不是本次发布引入的" ⇒ 属 `#46` 的 `W1` 同族欠账（"桥的 app-local 副本没有链去同步"）；本车道现场核 `libwpfwin32.so` **五份副本全部 = `abf6879c027c5e73`**（= 权威件，**无陈旧副本**），`samples/**` 下 `wpfgfx_cor3.so` 两份也 = `e3ea092010734f44`。⇒ 收尾时**别让探针测到旧件**。
#     🟡 **`R-ARMSTALE`（沿用 `#46` 第 R8 条）**：五臂重取后必须核"五份 `mtime` 全晚于重取开始时刻"，否则是"**陈旧日志被重钉洗绿**"（`#46` 用这条补偿判据）。
#   【⑤ 未达标 / 未做 / 已知限制（不许当绿）】
#     ⏳ **仓外 hc 复测未收口**：预登记 §2 的 hc 腿（点 TextBox ⇒ 焦点、随后点别处仍有反应）本车道写记录时**在飞**（`$HOME/w47a-run/{geo,nav,navall,Q1..Q6}`，最后写入 ≈22:53）⇒ 本记录**不声称**hc 侧已复验。
#     ⏳ **⑬ 块的判据腿只覆盖三类点击的"连做"**：键盘腿只做了 TextBox 的 `xdotool type`；ListBox 的 `Up/Down`、ComboBox 的 `Alt+Down`/`F4`、双击（`WM_LBUTTONDBLCLK=0`）、右键、窗口外点击**均未做**（`W47B` §7.3 已登记）。
#     ⏳ **`W47B` 未查项照旧**：`lstitem h=12` 的观感值未查；hc 上的 `Mouse.Captured` 读数未取（`NOINFO`）。
#     ⚠️ **hc 与仓内判据的异同（不许越界声称）**：本缺陷**足以解释**"**点过一次之后、窗口内点别处点不动**"这一整类现象（与用户报告吻合）；但 `W47B` §6 独立复测过 **hc 的 TextBox 页点击是好的**（`focus=TextBox`、`type abc` ⇒ `len 4→7`）⇒ **不能**说"hc 的病根就是这个"；hc 是第三方模板层（`hc:ToggleBlock`/`DropDownElement`），仍有 `D-G50` 那类各自的问题。
#     ⚠️ **车道自陈的仪器自伤（`W47B` §5，留在案、不当绿）**：① 第一版驱动"每步把指针停到窗口外"**自己造出假绿**（那一步正是**释放捕获**的动作）；② 像素/`AE` 腿对本类缺陷**系统性无效** ⇒ 承重的是 `EVT` 语义行 ＋ `captured` 字段；③ 早期"命中区域溢出布局矩形"的假说已被 `POS bounds`（`descendant == actual`、`Clip=null`）＋ 机内命中梯子**自我证伪**；④ `lstitem h=12` 未查。
#     ⏳ **`#46` 留的活照旧**：`P3` 阈值重标（阈值口径过高，判据页明令不许放宽）、`D-G54` 的 `WS_EX_LAYERED` 呈现腿、`D-T4`/`D-G48` 的产品修、`#46` 的 `R10`（route/声明件不在覆盖面）与 `W1`（桥副本同步）欠账。
#   【⑥ 五臂与门禁】本波位移集合 = `win32shim`（产品）＋ `pc` ＋ `pf`（重建）**三位**；五臂**由主控在收尾链里重取**（本车道未跑、未重钉、未冻结）；应用门禁 6 条机读行**本车道未跑**（`NOINFO`）；五臂日志两种聚合口径（冻结时现算）＝ `cat` 口径 `0a27329be93f44b9`／`find|sort|xargs` 口径 `79f3182723486205`。
#   【`NOINFO`】① **应用门禁 run_dir / rows / 6 条机读行**（未跑，见 BANNER 段）；② **五臂日志重取后的 sha**（尤其 `tline` 的重取后值，见文首告示）；③ **重钉后的 `known-red.json` 终态 sha**（重钉前 = `1fa4c4540fe1b69f`）；④ **本波 `inputs_fp` 终值**（`8a8661b926e47489b9840736992209d3977ab10429e42dcdcbe9df1a5a0ddeaf` 由冻结器现算；重钉前现场 = `a47546ec0ed887f8b344a3c8367424cbab55d87eb90dceef5cb6dd3bf3ff0807`）；⑤ `25`/`871`/`2` 由冻结器从**冻前那趟 `verify-all` 日志**现算（本波**不动步数** = 25）；⑥ 九位里 `e3ea092010734f44`/`043eff4b1d8ecd7d`/`366e9486536bc291`/`abf6879c027c5e73` 的终值由冻结器现算（本车道现场值仅供对账：`bridge e3ea092010734f44`、`pc 043eff4b1d8ecd7d`、`pf 366e9486536bc291`、`win32shim abf6879c027c5e73`，均为**重建前**）；⑦ **仓外 hc 腿**与 hc 上的 `Mouse.Captured` 读数；⑧ `KNOWN-DEFECTS.md` 里 `D-G55` 修后读数 `3`/`7` 的出处（盘上读数文件是 `2`/`6`）。
BASELINE tier=default rep=1 config=pc:043eff4b1d8ecd7d,bridge:e3ea092010734f44,pf:366e9486536bc291,provider:1f9511a7ef395bfe,win32shim:abf6879c027c5e73,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w48a/gate-e
BASELINE tier=default rep=2 config=pc:043eff4b1d8ecd7d,bridge:e3ea092010734f44,pf:366e9486536bc291,provider:1f9511a7ef395bfe,win32shim:abf6879c027c5e73,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w48a/gate-e
BASELINE tier=default rep=3 config=pc:043eff4b1d8ecd7d,bridge:e3ea092010734f44,pf:366e9486536bc291,provider:1f9511a7ef395bfe,win32shim:abf6879c027c5e73,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w48a/gate-e
BASELINE tier=env rep=1 config=pc:043eff4b1d8ecd7d,bridge:e3ea092010734f44,pf:366e9486536bc291,provider:1f9511a7ef395bfe,win32shim:abf6879c027c5e73,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w48a/gate-e
BASELINE tier=env rep=2 config=pc:043eff4b1d8ecd7d,bridge:e3ea092010734f44,pf:366e9486536bc291,provider:1f9511a7ef395bfe,win32shim:abf6879c027c5e73,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w48a/gate-e
BASELINE tier=env rep=3 config=pc:043eff4b1d8ecd7d,bridge:e3ea092010734f44,pf:366e9486536bc291,provider:1f9511a7ef395bfe,win32shim:abf6879c027c5e73,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w48a/gate-e
# ⏪ **（历史，已被 `#47` 取代）**# RE-FROZEN #46 —— ✅ **当前冻结基线** —— 内容 = 修 **`D-G50`**（HC 组合框下拉"弹出即被关掉"：**X 焦点回送被重复翻译成第二条 `WM_SETFOCUS`**）＋ 修 **`D-G54`**（弹窗内容零渲染：**把"根 ＋ 呈现目标"从通道级下沉到 target/HWND 级**）；同趟**撤回**我方两条自陈错判（`D-G52`/`D-G53`）。
#   ① **`win32shim`（本波必做项）**：`D-G50` 的根因 = **焦点回送**。链条逐层（读数出处写在括号里）：
#     · shim `src/WpfGfx.Linux.Native/src/win32_x11.c` 的 `case FocusIn:`/`case FocusOut:` **无条件**把每个 X 焦点事件翻成 `WM_SETFOCUS`/`WM_KILLFOCUS`（判定点：`docs/WAVE46-PREREGISTRATION.md` §1）；
#     · 而 `SetFocus()`（`win32_core.c`）**已同步**派发过一遍焦点消息，随后 **X 对我们自己那次 `XSetInputFocus` 的回送**又被翻译一次
#       ⇒ 主窗口收到**第二条 `WM_SETFOCUS`**（原文：`SETFOCUS → XSetInputFocus(0x200008)`（弹窗）→ `SETFOCUS → XSetInputFocus(0x200004)`（主窗）→ 四条回送，`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `D-G50` 判词第 4 层）；
#     · 此刻 WPF 键盘焦点已在弹窗（另一个 `HwndSource`）里，而 `GetFocus()` 仍返回本窗口 ⇒ 撞上上游 `HwndKeyboardInputProvider.OnSetFocus`（**与上游逐字相同，已 diff 核实**）里的
#       `if (focus == thisSource.Handle) … if (hwndSource != thisSource) Keyboard.ClearFocus();`（`KNOWN-DEFECTS.md:1780-1781`）⇒ 焦点被清空
#       ⇒ 命中 `PresentationFramework …/ComboBox.cs:1109 OnIsKeyboardFocusWithinChanged` 的 `currentFocus == null` 分支 ⇒ **`Close()`**；
#     · Win32 上**不存在**"抓取伪焦点"这类消息 ⇒ 这条翻译是**我方移植引入的语义偏差**。
#     修法（`win32shim` 位 `11f81eb9dfc60a12` → `e700c383ec1ecdc8`）：按"**自己请求的回送**"识别并吃掉（`g_x_focus_want`/`g_x_focus_want_pending`，回送到齐后恢复逐条翻译；保留 `detail=NotifyPointer` 路径与 `g_focus_window` 记账）；
#     并同趟落**建窗/映射腿 env 门控有界诊断**（`WPF_LINUX_CREATE_DIAG=1`，≤40 行/进程，只打印）—— 留仓是为了"修好后的判据在冻结之后仍可复算"（`docs/WAVE46-PREREGISTRATION.md` §9）。
#   ② **`bridge`（`D-G54` 的修法）**：弹窗内容**确实渲染了，但被呈现到主窗口**（一帧 413×274／439 条 skia 指令），弹窗 HWND `0x200008` **从未当过呈现目标**（`已呈现` 计数 0）；
#     因 = `MilPresentation.cs TryResolveTarget` 取资源表里**第一个**带 `NativeWindow` 的目标，而 `IMilChannel.Root` 是**通道级单槽**（被弹窗那次 `SetRootFromHandle` 覆盖）。
#     设计稿的关键纠偏（`docs/WAVE46-PERTARGET-PRESENT-DESIGN.md`）：**存储本来就是每目标一棵根**（`MilTarget.Root`），按通道的只有**读者** ⇒ 本轮改的是读者 ＋ 一笔"根句柄的通道归属"。
#     改动 **4 处，全在 `src/WpfGfx.Linux/**`（合计 `+350/−98`）**（`build/MilBridge/W46G-report.md` §1.1）：
#       `Interop/MilPresentation.cs` `ee89f32def7c98d2 → 8b44b61f944aeeaa`（`CollectTargets` 收**全部**目标＋**句柄升序**排序；`PresentChannel` → 逐目标 `PresentTarget`：**它自己的 HWND／自己的尺寸／自己的清屏色**；**返回码口径** = "多目标至少一个成功即 `S_OK`"，全败才带出失败）；
#       `Resources/MilChannel.cs` `dcc34a49e0f7176d → 384d024ab7987dfa`（`MarkTargetRooted`/`IsTargetRooted` = **根句柄的通道归属**，本轮唯一不能省的新状态；**预检下沉到 `Commit()`**，覆盖**四条**提交路径）；
#       `Interop/MilNative.cs` `ee4a0e8dd82b0cab → e1d7bfa0fd03a01f`；`Commands/MilCommandDispatcher.cs` `b0ddcd23f3e0cbca → 748f781620ea4008`。
#       ⇒ 这就是"**为什么 `bridge` 动**"的读数：不是重建副作用，是**本波的产品改源**（4 件源件的 mtime 都在 `20:07–20:09`，`docs/WAVE46-CLOSEOUT-RUNBOOK.md` §0.1）。
#   ③ **`pc`**：新 applier `src/WpfGfx.Linux.Native/tools/patch-presentationcore-hwndtarget-trace.py`（`2026-09-19 20:03`，10,261 B）＝ 给 `HwndTarget` **设根链加只读插桩**（`WPF_LINUX_HT_TRACE=1`）；applier 自带锚点/`throw`/大括号/结构断言（`docs/WAVE46-PROGRESS.md`「已落仓」表）。
#   **两条"撤回"（本波自陈的错判，必须与原登记一起读）**：
#     ⛔ **`D-G52` 撤回**（"透明填充不可命中"）：三行背景对照给出 `EVT bgprobe transparent hit`（透明 `Border` **收到了**点击）、`opaque hit`、`Background=null` 正确地不命中；那条 `overlay=0` 读数出自我**没有模板的裸 `Control` 复刻件**（**我自己的仪器不忠实**）。**真正的覆盖层**（HandyControl `hc:ToggleBlock`，模板根 `Border Background="{TemplateBinding Background}"`）实测**吃到了 `MouseDown`**（`TBlkMouseDown cs=2 …`）⇒ `D-G50` 的根因**不是**命中测试，是上面的焦点回送。
#     ⛔ **`D-G53` 撤回**（"弹窗不建窗/不出画"）：`WPF_LINUX_CREATE_DIAG=1` 打出的完整腿迹是 `CREATE 0x200008 … → SetWindowPos → ShowWindow(SW_SHOWNA) → MAP 0x200008 xywh=559,356,413x274 → 几毫秒后 SW_HIDE → DESTROY`；`mapped=0` 是**销毁后的终值**，而每 300 ms 的 `xwininfo` 采样**分辨力不足**（窗口只活几毫秒）⇒ 它**不是**独立缺陷，是 `D-G50` 的同一条链（`docs/WAVE46-PREREGISTRATION.md` §8）。纪律教训：**看"是否发生过"要用事件日志，不要用低频轮询 ＋ 终值字段**。
#   **产品侧验收判据（落地前写死，逐条读数）**：
#     ✅ 弹窗**当过一次呈现目标**：`HWND 0x200008 已呈现 413x274（skia 指令 29 条）` = **0 → 2**（旧桥 0）；首帧 `1x1（0 条）` → 稳态 `413x274（29 条）`；`[preflight] … id=0x35` **1 → 2**（`handle=0x3` / `handle=0x894`，与 `[CMD] 派发 id=0x35` 的 2 条对齐）—— 台账盲区已闭（`build/MilBridge/W46I-report.md` §2.1/§2.3，**三趟独立复跑逐字相同**）。
#     ✅ 主窗口**不再按弹窗尺寸出帧**：`grep -c 'HWND 0x200004 已呈现 413x274'` = **0**（三趟 ＋ 旧桥都是 0）。⚠️ 派单书写的"改前 = 1"是 **`W46A` 修 `ConfigureNotify` 归属之前的旧读数**；本条今天只是**防回归**。
#     ✅ **不是一块纯色**：`WPFGFX_ROOTDIAG=1` ⇒ `ROOTDIAG 通道2 target.Root=0x893 … 从根可达=57 孤立=964`（>1）＋ `AUX_flat_block=no` ＋ 像素判据 **`P2` 色数 `66 → 152`**；W46I 另测弹窗矩形**色数 206**、非白 **14.31%**、逐行 10 段（蓝底选中条 ＋ 8 条文本）＝ **完整 9 项列表**。
#       ⚠️ 口径：`从根可达=57` 是**本目标首次呈现之后的稳态**；同一趟里设根后**第一次** ROOTDIAG 是 `从根可达=1` ⇒ 引这条判据**必须连"何时采样"一起写**。
#     ✅ **主窗口没被动过**：同一时刻旧桥 vs 新桥**逐像素 `AE=0`**（主窗区／弹窗矩形／全屏三档）；下拉打开后主窗区仍 `AE=0`，全屏 `AE=17185` **全部落在弹窗矩形内**。
#     ✅ **单窗口门禁（防"修一处坏一处"）**：`WPTD_SUMMARY=PASS tiers_passed=2/2`；6 条机读行 `result=PASS`，`drawn=260/144`、`colors=3960/2828`、`frames_good=14/14`、`cross_ae=0`、`exit=143` **与上一冻结块（`#44`）逐字段相同**（只有 `config=` 元组随四位位移变，见下）。
#     ⛔ `P3=FAIL`（`AE=12220 < 20000`）**如实记，不算产品未达标**：该阈值是按"弹窗被画成一整块白"的几何标定的，而**修好后内容是一张白底列表**（下半区 103250 px 里 94690 仍是列表白底、非白仅 ~8560）⇒ 口径过高。
#       `W46I` 又证 `P2` 与 `P3` 有**互不重叠的盲区**（纯色块 `P2=FAIL` 而 `P3=PASS`；"窗口在、几何对、一像素不画" `P2=PASS 色数=66` 而只有 `P3=AE=0` 抓得住）⇒ **承重的是 `P2 ∧ P3` 这个合取**，单看 `P2` 会假绿；`P3` 重标是下一波的活（`docs/WAVE46-DG54-CRITERIA.md` §8）。
#     ⛔ **两条口径勘误（别再用）**：① `grep -c '已呈现.*0x200008'` **词序敏感、恒 0**（真实行形是 `通道 N → HWND 0x… 已呈现 WxH`）；② 只读 **stderr** 台账会得出"弹窗那条 `SetRoot` 没进预检"的**假象** —— stderr 有固定 400 行预算（`[mil] …诊断预算用尽（已打 400 条）`），判据**必须读文件汇**（`WPF_LINUX_MIL_LOG`）。
#     截图留档：`$HOME/w46-evidence/pop_post-2x-w46G.png`（sha16 `3b4b878d8c2743fc`）／`pop_full-2x-w46I.png`（`8ca405df8227a64f`）；原跑目录 `$HOME/w46g-run/postA/VERDICT.txt` **已不在场**（本波磁盘清理后实测无此目录）⇒ 读数以 `W46G-report.md` §3 与 `W46I-report.md` §3 为准。
#   **九位（Release 权威件）**：`bridge` `e3ea092010734f44`（5019968 B）／`pc` `043eff4b1d8ecd7d`（3601408 B）／`pf` `366e9486536bc291`（6119424 B）／`windowsbase` `84a2826c471e60ea`／`provider` `1f9511a7ef395bfe`／`win32shim` `e700c383ec1ecdc8`／`wic_shim` `56278c14b4ecd672`／`hbtextline` `e89fed55fd8e32bc`（290825 B）／`dwf` `de2d555105b7d04b`。
#   ⚠️ **位移对账（两栏，别混读）**：
#     · **相对 `#44` 冻结值那一栏**（`ACCEPTANCE-BASELINE.md` 旧块，逐字）：`bridge` `496951adff86a557` → `e3ea092010734f44`；`pc` `45e7e0a46f5912c0` → `043eff4b1d8ecd7d`；`pf` `a93097f7a918597f` → `366e9486536bc291`；`win32shim` `11f81eb9dfc60a12` → `e700c383ec1ecdc8`
#       ⇒ **本波四位变**；其余**五位逐位未变**（`windowsbase` `84a2826c471e60ea` == `84a2826c471e60ea`、`provider` 未动、`wic_shim` 未动、`hbtextline` `e89fed55fd8e32bc` 未动、`dwf` `de2d555105b7d04b` == `de2d555105b7d04b`）。
#     · **相对开工快照 `PRE`**（`/home/links-dev/w46-pre.sha`，9 行，`069e6693d4c2d3d5`）：本波 `PRE` 是**按 `#44` 冻结值**写的（`docs/WAVE46-PROGRESS.md:103`；我逐行现场核对 = `#44` 冻结值）⇒ 冻结器算出的 `changed` = **同一集合**，正好等于本代 `allow_changed` 声明的四位。
#       ⚠️ **对 runbook §6.4 的口径更正**：那里假设"`PRE` 只能在改动之后采 ⇒ `changed` 只反映**波内重建**位移"；**本波实际不是**（`PRE` ＝ `#44` 冻结值）⇒ `changed` 直接就是**产品位移**。这是**更严**的一栏，如实记（不是事故）。
#     · ⚠️ 冻结项 `prev_pc` = `45e7e0a46f5912c0` —— 那是**波内中间值**（`20:48` 开工时的现树 `pc`，`build/MilBridge/W46H-report.md` §2 第②列），**不是 `#44` 冻结值**（`45e7e0a46f5912c0`）。**对账请用上面那一栏**，`45e7e0a46f5912c0` 只当"开工"参照。
#       （`prev_pf`=`a93097f7a918597f`、`prev_wsh`=`11f81eb9dfc60a12`、`prev_wb`=`84a2826c471e60ea`、`prev_dwf`=`de2d555105b7d04b` 与 `#44` 冻结值**一致**，可直接当"改前"。）
#   ⚠️ **`pc`/`pf` 为什么会变（如实归因）**：**不是**因果耦合，而是**整波重建即变字节**（非确定构建：MVID／内嵌时间戳）—— `20:50:22` 重建 `PresentationCore`、`20:51:29` 重建 `PresentationFramework`（`W46I-report.md` §4.3 给了 mtime 与旁证：`build/*.Linux/SR.g.cs` 的 `20:49:09–20:49:17`、`ARTIFACT-SRC-FP.txt` 的 `20:51:32`、`build/.wave-done` 的 `20:51:56`）。**本波的产品改源只有 `bridge`/`win32shim` 两位**。
#   ⚠️ **`inputs_fp` 变了**（`493551dbffb1a937297bcb222389690c6df9bafa0c5c468a19e31a07b32c2f5f` → **`a47546ec0ed887f8b344a3c8367424cbab55d87eb90dceef5cb6dd3bf3ff0807`**）：本波 `infp=None`（冻结器**不断言**旧值），理由**点名两件**：① 按纪律**重钉** `build/MilBridge/known-red.json`，而它是 `fp_inputs()` 的**点名成员**（`build/close-wave.sh:179-180`）；② **新 applier** `patch-presentationcore-hwndtarget-trace.py` 进覆盖面（`find src/WpfGfx.Linux.Native/tools … -name 'patch-*.py'`）。⇒ 属**设计性变更**（"改判定输入必须看得见"），由本记录声明。
#   ⚠️ **`BRIDGE_SRC_FP` = `f10b4b297b2358e6`**（上一代 `794ea22406cc88ab`）：本波改了 `src/WpfGfx.Linux/**` ⇒ 该值必换，且**已重发桥**使"**现树 == 发布记录**"两侧一致 —— 发布记录 `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/bridge-src-fp.txt` 逐字 `BRIDGE_SRC_FP=f10b4b297b2358e6`／`PUBLISHED_AT=2026-09-19T20:48:55+08:00`／`BRIDGE_SO_SHA256=e3ea092010734f44…`（`W46H-report.md` §2.3 复核：`20:48` 开工时两侧不一致、`20:49` 重发后一致、`21:29` 收尾仍一致）⇒ `close-wave.sh:301-304` 的桥身份自检现在**会过**。
#   **臂日志**：位 sha 变 ⇒ 按纪律**重取五臂**（`ARMS_OUT=$HOME/w46h/arms`，用 `ln -f` **硬链接**进 `build/MilBridge/arm-logs/`，五份 `links=2`）。
#     **只有 `tline` 一支内容变**（`928b79e6a300cea0 → e061054f73c9a2e7`；机制 = 它自报权威件 `pc` 的 sha，而 `pc` 变了）；三支 `tab-*` 与 `textlineproto` **逐位不变**；五份 `mtime` 全晚于重取开始时刻（`20:55:24`）⇒ **不是"陈旧日志被重钉洗绿"**（runbook §4 反向陷阱的补偿判据已过）。
#     `GEN_KEYS` 三件（`instr_run_sh`/`instr_program_cs`/`instr_shim`）**未动** ⇒ `entries[*].caliber` **0 改动**，`--check` 收敛 `REPIN_GENERATION=PASS（世代三项 + 五臂 + 证据日志 + 4 条 entries 的 caliber 全部一致）`。
#   **`verify-all` 同趟五处改到 `#46`**（`VERIFYALL-STEPS-DECL` **首行** `25 gen=#46` ＋ 口径句 ＋ 预登记标题）：仓内自查牙 **`VERIFYALL_SELF=PASS names=25 decl=25 gen=#46 dup=0 order=OK prose=OK prereg=PASS`**，`grep -c '^run_step "' verify-all.sh` = **25** = 实测步数（`25`）；本波**不动步数**（`docs/WAVE46-PROGRESS.md` 收尾前置件表第 3 条）。
#   【外挂声明：`D-G27` 的读者要读的 4 类行】⚠️ 谁改它们谁要让读者一起绿。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=e061054f73c9a2e7
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 这一波修的是什么】两条产品缺陷，都是"**真实第三方应用（仓外 HC demo）＋ 仓内探针**"逼出来的：
#     · **`D-G50`**（`#44` 现场发现、`#45` 定位、**本波修**）：HC 示例应用 `NativeComboBoxDemo`（被测件 = **标准 `ComboBox` ＋ HandyControl 模板**，不是 HC 私有控件）**点开下拉后立刻被关掉**。
#       本波用四层仪器把链条打穿到判定点（`docs/WAVE46-PREREGISTRATION.md` §1）：命令链**全通**（`TBlkMouseDown cs=2` ⇒ `EV DropDownOpened open=True` ⇒ `EV Executed … handled=True`）；关闭者是 **`Popup` 自己拆窗**（`DropDownClosed` 调用栈 `OnDropDownClosed ← OnPopupClosed ← Popup.OnClosed ← Popup.DestroyWindow`）；
#       触发条件 = **键盘焦点在弹窗打开途中被清成 `null`**（`LOSTFOCUS ComboBoxItem → null`，`GOTFOCUS → PopupRoot`）⇒ 命中 `ComboBox.cs:1109` 的 `Close()`；判定点 = shim **无条件**翻译 X 的**抓取伪焦点**事件（见 FROZEN 段 ①）。
#       **修后读数（同一真实节奏点击）**：同一次点击内 `Executed` 路由 **1 条**（此前 2 条 = 点击 ＋ 我自己的探针）、`Combo( open=True …)` 的 1 Hz 快照 **5 次**（下拉**持续开着**）、`DropDownOpened/Closed` **2/2**（腿A 点击开、腿B **点别处**关 ＝ 正常 WPF 语义）、全屏 `AE=11630` 与"程序化打开"那次**完全一致** ⇒ **`D-G50` 的唯一产品缺口就是焦点回送**（§10）。
#       ⚠️ 同趟还**撤除了三个"鼠标重放按键去重"实验**（三条判据全被反证：窗口相同／时间戳不动／`state` 含本键掩码都会误杀正常点击）—— **产品侧不需要它**，如实记。
#     · **`D-G54`**（**本波新登记**、本波修）：弹窗**建窗 ✓ 映射 ✓ 几何对 ✓**（`413x274+559+356`）但**内容零渲染** —— 修前弹窗下半区 `色数 66 → 1`（那一个颜色 = 建窗时给的 X 背景色白）。
#       `W46C` 的桥侧台账把它从"没画"纠正为"**画给了别人**"（一帧 413×274/439 条指令被呈现给主窗 HWND `0x200004`），`W46G` 按设计稿改成**按目标呈现**（见 FROZEN 段 ②），`W46I` 独立三趟复算 ＋ 三条主动证伪支持该声称。
#   【② 为什么此前没被发现】`D-G50` 在 `KNOWN-DEFECTS.md` 里长期就是"**已定位、未修**"（`:1625`），而**仓内判据完全没有覆盖"点击后应出现列表像素"**：
#     门禁那条 `EXPECT "nativecombo:!7C3AED"` 是"**无人点击时**测试色不应出现" ⇒ 下拉**从不渲染它也照样绿**（`docs/WAVE46-PREREGISTRATION.md` §7 明说这条**只算吻合、不是证明**）。
#     `D-G54` 同理：`D-G51`/`D-G53` 两次把它误记成"不建窗/不出画"，直到用**事件日志**（`WPF_LINUX_CREATE_DIAG`）＋**桥侧逐目标台账**才看清"建了、map 了、画了 —— 画给了别人"。
#   【③ `inputs_fp` 的变化与原因点名】`493551dbffb1a937297bcb222389690c6df9bafa0c5c468a19e31a07b32c2f5f` → `a47546ec0ed887f8b344a3c8367424cbab55d87eb90dceef5cb6dd3bf3ff0807`（本代 `infp=None`，冻结器**不断言**旧值）。可归因**两件**，都具体到件：
#     ① **重钉 `build/MilBridge/known-red.json`** —— 重取五臂后四处必须同趟钉齐（`D-G19` 的教训），而它是 `fp_inputs()` 的**点名成员**（`build/close-wave.sh:179-180`）；
#     ② **新 applier 进覆盖面** —— `src/WpfGfx.Linux.Native/tools/patch-presentationcore-hwndtarget-trace.py`（`20:03`）落在 `find … -name 'patch-*.py'` 里。
#     位移链条（现场逐点读数，`W46H-report.md` §2.2）：`493551db…`（`#44` 冻结值）→ `4d7c973a7248b850…`（`20:48` 开工，**新 applier**）→ `279a4790a7a5a9fd…`（**重钉后**）→ `a47546ec0ed887f8…`（**终态**，那次幂等实测又追加一条 history 之后再算）。
#     ⚠️ 与 `#44` 那次不同：**本波真正改的 `src/WpfGfx.Linux/**`（`bridge` 那 4 件）就在覆盖面里**（`find src/WpfGfx.Linux -name '*.cs'`）⇒ 产品改源本身也会动 `inputs_fp`，这是设计使然。
#   【④ 本波新发现的假绿/欠账（自陈，两条）】
#     🔴 **`R10` 欠账（"改被判的输入"看不见）**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（route 件）与 `build/MilBridge/tools/defect-registry-declared.tsv`（声明件）**都不在 `fp_inputs()` 覆盖面、也不在 `GEN_KEYS`**
#       （现场核：`sed -n '/^fp_inputs()/,/^}/p' build/close-wave.sh | grep -n 'KNOWN-DEFECTS\|declared.tsv'` = **0 命中**）⇒ 唯一会红的是 `defect-registry-check.sh` 自己，而它审的是"**声明合不合规**"，不是"**输入有没有被改**"。
#       现场证据：`DEFREG_DECLDRIFT=2 changed-route-files-since-DECL-GEN`（`KNOWN-DEFECTS.md` 与声明表都在 `DECL-GEN` 之后被改过），而**没有任何牙因此变红**（drift 只是诊断行）。
#       本波已按 runbook §1-P7 `--emit` 补声明（现 `DEFREG=PASS declared=90 route_ids=90`）⇒ **留痕，不假装没有**；把 route/声明件纳进覆盖面是**下一波的活**。
#     🔴 **`W1` 新风险（桥的 app-local 副本没有任何链去同步）**：`publish-milbridge.sh`、`integration-wave.sh` 3.6 步、`close-wave.sh:277` 的循环**都只 `find libwpfwin32.so`**，**不管 `wpfgfx_cor3.so` 副本**
#       ⇒ 本波被 `verify-all` 的 `ManagedLayer.Tests` **真牙**咬到：`DP1ReproTests.cs:154`「闸门_win32shim被测件与权威件同sha」**[FAIL]**，`check-applocal-sync.sh` 同趟 `BRIDGE-ANCHOR=2 APPSYNC=MISMATCH`；`#44` 那趟之所以绿，是因为当时权威**恰好**就是副本里那个 sha。
#       后果实测：这份 `verify-all` 日志拿去冻结会让 `w27-freeze.py:305` **当场 `AssertionError`**（`nfail(2) != len(_expected_red)(1)`）。本波对策 = **手工同步两份副本**（`samples/**` 不在覆盖面 ⇒ 无指纹影响）＋ 该套件单独复跑 **PASS 1/1**（`$HOME/w46h/08-managedlayer-gate-after-sync.log`）。
#       ⇒ **欠账（下一波办，别在本波末尾动判定件）**：把"桥副本同步"接进某条链或立一颗牙（`libwpfwin32.so` 有 `close-wave.sh:274-287`，桥**没有**）。
#   【⑤ 重钉不幂等（本波实测的新发现，写进来免得下次又踩）】`repin-generation.py` **不做任何新鲜度/原因校验**（runbook §9-R8）：`--why` 的值**只追加**进 `generation.arms_retaken.history`（`:104-111`），**同一条 `--why` 再跑一次仍会写盘并再追加一条**。
#     现场证据（`W46H-report.md` 补记 ＋ `$HOME/w46h/04b-repin-idempotent-rerun.log`）：`known-red.json` `7deadeac97659e46`（394 行，= `#44` 声明）→ **`8680255933728e95`（398 行，`21:04:38` 第一次重钉）** → **`1fa4c4540fe1b69f`（402 行，终态，同句 `--why` 再跑一次）**；`history` 现 5 条，其中**两条内容相同**（都是本波那句 `--why`）。
#     ⇒ 判据"声明 == 现场"仍然成立（`--check` `REPIN_GENERATION=PASS`），`known-red.json` 的**语义没坏**；但"重钉跑了两次"这件事**只留在 history 里** ⇒ **`--why` 必须给，且重钉只做一趟**。
#   【⑥ 未达标 / 未做 / 已知限制（不许当绿）】
#     ⛔ `w46-popup-verify.sh` 的 `P3` 仍 `FAIL`（阈值口径过高，见 FROZEN 段）；**`P3` 阈值未调**（判据页明令不许放宽）⇒ 该装置总判仍是 `VERDICT=FAIL`。
#     ⛔ **承重判据是合取**：W46I 的三条证伪证明"纯色块骗得过 `P3`"、"一像素不画骗得过 `P2`" ⇒ 只许用 `P2 ∧ P3` ＋ `ROOTDIAG 从根可达>1` ＋ `AUX_flat_block=no` ＋ 肉眼**一起**看；`P3` 重标／"下半区非白像素数"口径是**下一波的活**。
#     ⏳ `D-G54` 的**已知限制**（修法 A 的代价）：弹窗的 alpha/阴影与 `Window.Opacity` 仍按"**不透明呈现**"走；`WS_EX_LAYERED` 那条呈现腿（shim 的 `UpdateLayeredWindow` 是失败桩且**上游不回退**）**未修**。
#     ⏳ `D-T4`/`D-G48` 的"透参"产品修、`D-G47` 的潜在真缺陷定性：仍是下一波。
#     ⏳ 车道自陈的两条纪律事故（**留在案，不当绿**）：① `W46G` 那 4 件源**先改后备份**（违反"改前先备份"；事后用逆脚本证明 pre-state 复原件 sha16 与动手前现场值 **4/4 逐位相同** —— 可复原，但违规照记）；
#       ② `W46G` 的**仪器自伤**：导出 `WPF_LINUX_MIL_LOG` 使 `[create]` 台账每资源一行（358 行）烧光 stderr 的 400 行预算 ⇒ 单窗口门禁**误报"空帧 FAIL"**；**清掉该变量重跑即 `PASS 2/2`**（非产品回归）。
#     ⏳ 另有两处**本波报告自己点名的口径勘误**（见 FROZEN 段）：`已呈现.*0x200008` 恒 0 不能用；`config=` 的"逐字段相同"只在**行为/读数**那 14 个字段上成立（`config` 元组有四位不同）。
#   【⑦ 五臂与门禁】`TLINE_GATE`／应用门禁 6 条机读行见下方 `rows`；本波位移集合 = `bridge` ＋ `pc` ＋ `pf` ＋ `win32shim` **四位**（见 FROZEN 段的两栏对账）。
#   【`NOINFO`】`25`/`871`/`2` 由冻结器从**冻前那趟 `verify-all` 日志**现算（我写记录时那趟还在跑；本波步数**未变** = 25）；主窗晚期"≈443 条指令"这个数**本轮取不到**（`W46G` 已用"旧桥 vs 新桥逐像素 `AE=0`"作更强替代）；`P3` 阈值重标、`R10`/`W1` 两条欠账的产品化都**留给下一波**。
BASELINE tier=default rep=1 config=pc:043eff4b1d8ecd7d,bridge:e3ea092010734f44,pf:366e9486536bc291,provider:1f9511a7ef395bfe,win32shim:e700c383ec1ecdc8,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w46h/gate-e2
BASELINE tier=default rep=2 config=pc:043eff4b1d8ecd7d,bridge:e3ea092010734f44,pf:366e9486536bc291,provider:1f9511a7ef395bfe,win32shim:e700c383ec1ecdc8,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w46h/gate-e2
BASELINE tier=default rep=3 config=pc:043eff4b1d8ecd7d,bridge:e3ea092010734f44,pf:366e9486536bc291,provider:1f9511a7ef395bfe,win32shim:e700c383ec1ecdc8,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w46h/gate-e2
BASELINE tier=env rep=1 config=pc:043eff4b1d8ecd7d,bridge:e3ea092010734f44,pf:366e9486536bc291,provider:1f9511a7ef395bfe,win32shim:e700c383ec1ecdc8,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w46h/gate-e2
BASELINE tier=env rep=2 config=pc:043eff4b1d8ecd7d,bridge:e3ea092010734f44,pf:366e9486536bc291,provider:1f9511a7ef395bfe,win32shim:e700c383ec1ecdc8,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w46h/gate-e2
BASELINE tier=env rep=3 config=pc:043eff4b1d8ecd7d,bridge:e3ea092010734f44,pf:366e9486536bc291,provider:1f9511a7ef395bfe,win32shim:e700c383ec1ecdc8,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w46h/gate-e2
# ⏪ **（历史，已被 `#46` 取代）**# RE-FROZEN #44 —— ✅ **当前冻结基线** —— 内容 = 修 **`D-G49`**：**鼠标五键的 `GetKeyState` 恒 0 ⇒ 真实第三方应用里控件永不激活**
#   根因（代码级）：上游 `PresentationCore/System/Windows/Input/Win32MouseDevice.cs:45,61` 判按钮状态的**唯一**来源是
#     `(GetKeyState(VK_LBUTTON) & 0x8000) != 0 ? Pressed : Released` —— **它不看消息**。
#     而本 shim 的 `g_wpf.key_state[256]` **只由键盘翻译层填写** ⇒ 五个鼠标 VK 恒 0 ⇒ WPF 永远认为"左键没按下" ⇒
#     上游 `ButtonBase.OnMouseLeftButtonDown` 里 `Focus(); if (e.ButtonState == Pressed) { CaptureMouse(); SetIsPressed(true); }`
#     判假 —— 而 `Focus()` 在判据**之前** ⇒ **焦点照拿、激活永不发生**。
#   修法（三处，全在 shim 的 C 源）：① `win32_x11.c` 新增 `wpf_x11_mouse_keystate()`（问 `XQueryPointer` 的**真实指针按键态**）；
#     ② `win32_core.c` 的 `wpf_keystate_read()` 仅对 `0x01/0x02/0x04/0x05/0x06` 五个 VK 改走它（**键盘路径逐字未动**）；
#     ③ `win32_internal.h` 加声明。
#   产品侧验收（仓外 hc demo，Release 权威件 + 声明档；判据在 `docs/WAVE44-PREREGISTRATION.md` §2 落地前写死）：
#     ✅ `P1` 复选框：**控件自身 24×24 盒内**像素 `AE 0 → 338`（修前只多一个**框外**的焦点虚线）；再点一次 `276`（**可反复切换**）
#     ✅ `P4` 正对照：导航点击换页 `AE=235937`；✅ `P5` 反极性：静置 3 s `AE=0`；✅ `P6` 应用活着、`app.log` 0 异常 0 断言
#     ⛔ `P2` 组合框：**下拉仍不开**（可见 X 窗口数 `1→1`）⇒ 另有一条待查（不在本波射程）；⛔ `P3` **判据本身写错**：
#        WPF 的 `Slider` 默认 `IsMoveToPointEnabled=false` ⇒ **点轨道本来就不该动** ⇒ 该条作废，须改成"拖 thumb"再判
#   **九位（Release 权威件）**：`bridge` `496951adff86a557`（未动）／`pc` `45e7e0a46f5912c0`（3600384 B）／`pf` `a93097f7a918597f`（6119424 B）／`windowsbase` `84a2826c471e60ea`（未动）／
#     `provider` 未动／`win32shim` `11f81eb9dfc60a12`（**本波就是改它**）／`wic_shim` 未动／`hbtextline` `e89fed55fd8e32bc`（未动）／`dwf` `de2d555105b7d04b`（未动）。
#   ⚠️ **位移预测对账（预登记 §3 写死过，如实记）**：`win32shim` 必变 ✓；**预测错了一条** —— `pc`/`pf` 也变了
#     （`deb8e19265917814`→`45e7e0a46f5912c0`、`d160eaed711edb61`→`a93097f7a918597f`），原因**不是**因果耦合，而是**整波重建即变字节**（非确定构建：MVID／内嵌时间戳）。
#     `bridge`/`windowsbase`/`provider`/`wic_shim`/`hbtextline`/`dwf` 六位**逐位未变** ✓。
#   ⚠️ **`inputs_fp` 变了**（`ee98113baa280482491cdaceba76404a8d57517bffab9ec55ce5c7674d5fe812` → **`493551dbffb1a937297bcb222389690c6df9bafa0c5c468a19e31a07b32c2f5f`**）—— 预登记 §3 预测「不动」，**那条错了**，如实记：
#     本波按纪律**重钉** `build/MilBridge/known-red.json`（重取五臂后四处必须同趟钉齐），而**它在覆盖面里**
#     （「改登记表必须看得见」是设计）⇒ 属**设计性变更**，由本记录声明。本波真正改的 `src/*.c|*.h` **不在**覆盖面里（那半预测成立）。
#   ⚠️ **`BRIDGE_SRC_FP` = `794ea22406cc88ab`**（未变）。
#   **臂日志**：位 sha 变 ⇒ 按纪律**重取五臂**（`ARMS_OUT=$HOME/w44-arms`，硬链接进 `build/MilBridge/arm-logs/`）。
#     `GEN_KEYS` 三件**未动** ⇒ 世代键不变；重取后只有 `tline` 一支的内容变了（它记录权威件 sha）。
#   【外挂声明：`D-G27` 的读者要读的 4 类行】⚠️ 谁改它们谁要让读者一起绿。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=928b79e6a300cea0
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 这一波修的是什么】`D-G49`（本波**新登记**）：真实第三方应用（仓外 HandyControl demo）**能被点开、但控件永不激活** ——
#     复选框不勾、组合框下拉不开、滑块不动，**只拿到焦点**。仓内**从未登记**过它（`grep -rn "点不动\|ButtonState" docs/ samples/ handoff.md` = 0 命中），
#     也**没有任何点击注入的测试**（全仓无源级 `xdotool/ButtonPress` 调用点）⇒ 这条是"真实应用一用就现形、而仓内判据完全没覆盖"的典型。
#   【② 为什么此前没被发现】仓内的样本/门禁只**看画面**（帧存在性、颜色数、列级真值），**从不点控件**；
#     而"能画对"与"点得动"是两条独立的链 —— 前者走渲染（MIL/Skia/X11 呈现），后者走**输入**（X 事件 → shim 消息 → WPF 输入栈 → 控件状态机）。
#   【③ 本波新增的三条仪器教训（都留档）】
#     · publish 目录里**根本没有** `libwpfwin32.so` ⇒ 早前几件 hc 仪器里那句 `[ -f "$src" ] && cp …` **静默什么都没做**，
#       应用目录一直躺着 `#40` 世代的老 shim（`73c488a6aa0450e2`）⇒ **读数是旧件上的读数**。本波的验收件改为从**权威位路径**
#       `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 取，并把两边的 sha 一起印出来对账。
#     · `integration-wave.sh` 在 `WAVE_OWNER` 未设时**拒绝运行**（结构性约束，`rc=9`）—— 它不是构建失败，**别把它读成红**。
#     · 两个 hc 仪器件**共用 `:95`** ⇒ 后者的收尾杀掉前者还在用的 X server ⇒ 那次的 `SIGSEGV`／`X connection broken`
#       是**自伤**，不是产品崩溃（相关读数作废）。此后 hc 件一律**独占**显示号并 `export DISPLAY`。
#   【④ 未达标/未做（不许当绿）】
#     ⛔ `P2` 组合框下拉：修后 `nwin 1→1`、`AE=7418`（≈ 仅焦点）⇒ **Popup 这条路另有问题**，本波**不修**，另立条目查
#        （下一个判别实验：`xdotool search` 含**未映射**窗口的计数 —— 分清"窗口没建"与"建了没映射"）。
#     ⛔ `P3` 判据作废（见上）；正确的滑块判据 = **拖 thumb**（mousedown→move→mouseup），须重写后再判。
#     ⏳ `D-T4`/`D-G48` 的"透参"产品修、`D-G47` 的潜在真缺陷定性：仍是下一波。
#   【⑤ 五臂与门禁】`TLINE_GATE`／应用门禁 6 条机读行见下方 `rows`；本波位移集合 = `pc` ＋ `pf` ＋ `win32shim` 三位（见上面 FROZEN 段的对账）。
BASELINE tier=default rep=1 config=pc:45e7e0a46f5912c0,bridge:496951adff86a557,pf:a93097f7a918597f,provider:1f9511a7ef395bfe,win32shim:11f81eb9dfc60a12,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w44-gate-e
BASELINE tier=default rep=2 config=pc:45e7e0a46f5912c0,bridge:496951adff86a557,pf:a93097f7a918597f,provider:1f9511a7ef395bfe,win32shim:11f81eb9dfc60a12,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w44-gate-e
BASELINE tier=default rep=3 config=pc:45e7e0a46f5912c0,bridge:496951adff86a557,pf:a93097f7a918597f,provider:1f9511a7ef395bfe,win32shim:11f81eb9dfc60a12,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w44-gate-e
BASELINE tier=env rep=1 config=pc:45e7e0a46f5912c0,bridge:496951adff86a557,pf:a93097f7a918597f,provider:1f9511a7ef395bfe,win32shim:11f81eb9dfc60a12,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w44-gate-e
BASELINE tier=env rep=2 config=pc:45e7e0a46f5912c0,bridge:496951adff86a557,pf:a93097f7a918597f,provider:1f9511a7ef395bfe,win32shim:11f81eb9dfc60a12,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w44-gate-e
BASELINE tier=env rep=3 config=pc:45e7e0a46f5912c0,bridge:496951adff86a557,pf:a93097f7a918597f,provider:1f9511a7ef395bfe,win32shim:11f81eb9dfc60a12,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w44-gate-e
# ⏪ **（历史，已被 `#44` 取代）**# RE-FROZEN #40 —— ✅ **当前冻结基线** —— 内容 = **权威件从 Debug 切到 Release**（`#39` 阶段 2/3 的落地）：
#   动机 = **`D-G47`**：真实第三方应用被 `MS/Internal/Helper.cs:591` 那句 `Debug.Assert`
#   （带 `[Conditional("DEBUG")]`）直接终止。切换后 **S5/S6 两极化**在仓外被测到（见 `record`）。
#   ① **配置唯一声明**：`build/SelfBuiltConfig.props` ＋ 唯一 shell 读取器 `build/selfbuilt-config.sh`
#      （`--check` 两颗牙：声明恰好 1 条 ＋ **shell == 两条 MSBuild 图**；`--debt`/`--debt-check` 棘轮）；
#   ② **161 处消费点**接线（生成器/波/验收构建与 6 个 `dotnet test`/5 个 `AUTH_PC`/门禁与样本 runner/
#      第三方 runner/桥的 AOT 输入/应用侧副本表/14 个探针工程 48 处引用/`ManagedLayer.Tests`），
#      ⇒ **"切配置必须逐个 sed"这个雷被拆掉**（写死的处数 198 → 161，棘轮只许减少）；
#   ③ **`hbtextline` 一字节未动**、`bridge` 未动；**九位里 6 位换了构建配置**（pc/pf/windowsbase/provider/dwf
#      路径进 `bin/Release/`；`win32shim`/`wic_shim` 因 `#41` F 重建而变化）——**这是本波的目的**，如实声明。
#   ＋ **`#41` F：GDI+ 图像族真解码**（只读族真做、写族与流式**如实失败**；解码**复用同一条链**
#      `WpfWic_DecodeFileToBgra`，Skia 仍只在一个文件里被调用）＋ **`#42` G：`D-T4` 的定位读数**
#      （新探针 `TabGapProbe` 推翻其一半措辞，并抓出新缺陷 **`D-G48`**：HB 兜底接不住 ⇒ 落到不存在的原生 LS ⇒ **崩**）。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行。
#   **九位（Release 权威件）**：`bridge` `496951adff86a557`／`pc` `deb8e19265917814`／`pf` `d160eaed711edb61`（6119424 B）／`windowsbase` `84a2826c471e60ea`／
#     `provider` 未动（同源重建）／`win32shim` `73c488a6aa0450e2`／`wic_shim` 因 `#41` F 重建而变化／`hbtextline` `e89fed55fd8e32bc`（未动）／`dwf` `de2d555105b7d04b`。
#   ⚠️ **`inputs_fp` 变了**（`e28d03fbe7de04ff7c2437a02c2bebd441666660a1b1ab825df854d186cfe901` → **`ee98113baa280482491cdaceba76404a8d57517bffab9ec55ce5c7674d5fe812`**）：本波改了 `close-wave.sh`、`frame-step.sh`、
#     `run-wpftextdemo.sh`、`HbTextLineParity/Program.cs`、`ManagedLayer.Tests` 等一大批消费点与生成器。
#   ⚠️ **`BRIDGE_SRC_FP` = `794ea22406cc88ab`**（未变；本波不碰 `src/WpfGfx.Linux.Native` 的 C# 源）。
#   【外挂声明：`D-G27` 的读者要读的 4 类行】⚠️ 谁改它们谁要让读者一起绿。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=9746cbcb46420307
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 五臂：**本波重取过**（有理由）】`GEN_KEYS` 在本波被两次改动：
#     · `instr_run_sh`（`build/MilBridge/run.sh` 的权威件路径改读唯一声明）；
#     · `instr_program_cs`（`HbTextLineParity/Program.cs` 的 T0.7 权威路径改读唯一声明）
#     ⇒ 按纪律**重取五臂**（`ARMS_OUT=$HOME/w40-arms2`，硬链接进 `build/MilBridge/arm-logs/`），
#     并**四类地方同趟钉齐**（`generation` 三项 ＋ `arm_logs` 五臂 ＋ `evidence_log_sha256` ＋
#     **`entries[*].caliber`**）——本波为此写了可复用工具 `build/MilBridge/tools/repin-generation.py`（带 `--check`）。
#     ⚠️ 教训（现场）：只改前三处 ⇒ 门禁报 `registry-generation-inconsistent` 并点名 4 条**完全无辜**的条目
#     （它们只是如实记录着旧世代）⇒ **同一个语义存在多处 ⇒ 必然分叉**。
#     `TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK tree_gen=same`。
#   【② 应用门禁】两档 × 3 rep（见 `baseline-rows` 的 6 条机读行）；配置 = Release。
#   【③ E · `D-G47` 的**产品两极化**（同一份 hc 代码，只换自产件配置）】
#     S5（Release 自产件 pc=deb8e19265917814 pf=d160eaed711edb61）：`rc=124`（跑到 runner 超时 ⇒ 进程活着）、**`assert_hits=0`**、
#        `frames=8`、`max_colors=373` ⇒ **越过了 `MS/Internal/Helper.cs:591` 那句 `Debug.Assert`** 并开始渲染；
#     S6（Debug 自产件）：`rc=134`、`frames=1`、`max_colors=1`、**`assert_hits=1`** ⇒ 那句断言**复现**。
#     ⇒ **两极化成立**：Release 治好了 `D-G47` 的终止形态。⚠️ 如实附注：Release 档只画到 **373 色**
#       （`#34` 那次是 1275 色）⇒ "越过断言"成立、"恢复成 #34 那个完整界面"**尚未成立**（另立待办）。
#   【④ F · GDI+ 图像族真解码】探针 `gdiplus-decode-check.sh` **14/14 PASS**（7×5 真解码、首像素 `ffff8000`
#     逐位等、scan0 非空 stride=28；三条如实失败 `FileNotFound(10)`/`UnknownImageFormat(13)`/`NotImplemented(6)`；
#     Dispose 幂等）。**反极性**：撒谎 shim ⇒ 被打红 6 例 ⇒ 内容判据真的在咬。
#     ⚠️ 过程自伤：助手第一版把 `obj_new()` 的 **1-based 句柄索引**当指针用 ⇒ 段错误（探针当场抓到）；已修。
#   【⑤ G · `D-T4`：新探针**推翻其一半措辞**并抓出**新缺陷 `D-G48`**】`tab=4/24/48` ⇒ 行宽
#     **32.797 / 56.797 / 104.797** ⇒ tab 值**确实影响排版**；而 `tab=0`（与 tab 步长 > 容器宽的折行档）
#     会落到**原生 LineServices** ⇒ `EntryPointNotFoundException: LoCreateContext` ⇒ **崩**（不是降级）
#     ⇒ 登记 `D-G48`；判据已落地（出现 EXCEPTION 即 FAIL）。**不改 `D-T4` 登记册**（需独立一波）。
#   【⑥ 本波**没做**（边界）】① `D-T4` 的产品侧修法与登记册更正；② `D-G48` 的修法（要么让兜底出结果、
#     要么如实抛可诊断异常）；③ hc 在 Release 件下的渲染完整度（373 vs 1275）；④ `upstream/wpf` provenance（要联网）。
BASELINE tier=default rep=1 config=pc:deb8e19265917814,bridge:496951adff86a557,pf:d160eaed711edb61,provider:1f9511a7ef395bfe,win32shim:73c488a6aa0450e2,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w40-gate-e
BASELINE tier=default rep=2 config=pc:deb8e19265917814,bridge:496951adff86a557,pf:d160eaed711edb61,provider:1f9511a7ef395bfe,win32shim:73c488a6aa0450e2,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w40-gate-e
BASELINE tier=default rep=3 config=pc:deb8e19265917814,bridge:496951adff86a557,pf:d160eaed711edb61,provider:1f9511a7ef395bfe,win32shim:73c488a6aa0450e2,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w40-gate-e
BASELINE tier=env rep=1 config=pc:deb8e19265917814,bridge:496951adff86a557,pf:d160eaed711edb61,provider:1f9511a7ef395bfe,win32shim:73c488a6aa0450e2,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w40-gate-e
BASELINE tier=env rep=2 config=pc:deb8e19265917814,bridge:496951adff86a557,pf:d160eaed711edb61,provider:1f9511a7ef395bfe,win32shim:73c488a6aa0450e2,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w40-gate-e
BASELINE tier=env rep=3 config=pc:deb8e19265917814,bridge:496951adff86a557,pf:d160eaed711edb61,provider:1f9511a7ef395bfe,win32shim:73c488a6aa0450e2,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w40-gate-e
# ⏪ **（历史，已被 `#40` 取代）**# RE-FROZEN #39 —— ✅ **当前冻结基线** —— 内容 = **权威件配置收敛到"唯一声明处"**（`#39` **阶段 1**；**值仍是 Debug**，
#   ⇒ 本波**行为等价**，切 Release 的阶段 2/3 **尚未动**）：
#   ① 新 `build/SelfBuiltConfig.props` = **唯一声明处**（`<WpfLinuxSelfBuiltConfiguration>Debug</…>`）；
#      两条 import 图**各 import 它一次**（`build/Directory.Upstream.props` → 全部 `build/*.Linux/*.csproj`；
#      仓根 `BuildHygiene.props` → 全部样本）⇒ MSBuild 侧只有一个来源。
#   ② 新 `build/selfbuilt-config.sh` = **唯一 shell 读取器**，带三件牙：
#      `--check` 断言「声明恰好 1 条且取值合法」＋「**shell 值 == MSBuild 值**（两条图各取一个代表工程求值）」；
#      缺件/解析不出/求值失败 ⇒ **`NOINFO`（rc=2）**；另有 `--debt`/`--debt-check` = 阶段 3 的**棘轮**
#      （统计还写死 `bin/Debug` 的处数，**上限是脚本里的字面常量、只许减少**）。
#   ③ 三处**关键消费点**改走声明（共 14 处）：`frame-step.sh` 的 `AUTH_PC`｜`run-wpftextdemo.sh` 的
#      样本 bin ＋ 自产件一致性扫描 ＋ Provider｜`close-wave.sh` 的九位读数 10 处。
#   ⚠️ **行为等价是构造性的**：配置值仍是 `Debug`，14 处解析出的路径与改前**逐字相同**；
#      应用门禁两档 × 3 rep 全绿、`verify-all` 25 步全绿（见 `record`）。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行。
#   **九位：4 位位移**（**都不改产品 C# 源**，却都在 `integration-wave.sh` 重编后换了身份位）——
#     `pc` `4cbdeeabb0338213 → 659a5dc64156b26a`、`pf` `37fd347eb55ca02e → e9ea2f57c8a36e7d`、`windowsbase` `19de048ecb968daa → 1b385c64c56fb10c`、`dwf` `24e819debc1e5b13 → d9258fcdec872917`；
#     其余五位逐位与 `#38` 相同（`bridge` `496951adff86a557`／`provider` 未动／`win32shim` `8c4f5a8685882b8f`／`wic_shim` 未动／
#     `hbtextline` 未动 ⇒ `GEN_KEYS` 三项全未变）。
#   【⭐ `D-G46` 的第二个独立实例（本波拿到，比 `#36` 那次更硬）】`pc` 的 `#38` 期副本（
#     `$HOME/w37-tpm-080656/app/PresentationCore.dll`）与现场件逐字节比：**大小相同（4199424 B）、只差 71 B / 6 段**，
#     且全部落在**身份字段**上（PE `TimeDateStamp`、`#GUID` 堆的 MVID、Debug Directory 的 PDB GUID/age/校验和）
#     ⇒ **IL 与元数据表逐字节相同** ⇒ **产品内容零差异**。
#     并**排除掉两条候选机制**（都实测否掉）：① `System.Windows.Extensions` 替身两代**逐字节相同**
#     （`4499439dff4b1e54`）；② 它引用的 `System.Xaml` 两代也**逐字节相同**（`856b84d2af114acb`）。
#     ⇒ 机制**仍未归因**（`D-G46` 的登记文字保持"未归因"，本波只是把"排除了什么"写清）。
#   ⚠️ **`inputs_fp` 变了**（`cf89d8be0f909ecea0f228c4e75cbf1dfb0db9ac32d8d41815e8cf20e816d342` → **`e28d03fbe7de04ff7c2437a02c2bebd441666660a1b1ab825df854d186cfe901`**）：本波改了 `close-wave.sh`（九位读数走声明 ＋ 设计性变更）、
#     `frame-step.sh`、`run-wpftextdemo.sh`、`build/Directory.Upstream.props`、`BuildHygiene.props`（各加 1 行 import）。
#   ⚠️ **`BRIDGE_SRC_FP` = `794ea22406cc88ab`**（未变；本波不碰 `src/WpfGfx.Linux.Native` 的 C# 源）。
#   【外挂声明：`D-G27` 的读者要读的 4 类行】⚠️ 谁改它们谁要让读者一起绿。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=70bbbe00a34f363c
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 五臂：**不重取**（有理由）】本波只动 `.sh` 与两个 `.props` ⇒ `GEN_KEYS` 三项
#     （`instr_shim`=`build/shims/PresentationCore.HbTextLine.cs`、`instr_run_sh`、`instr_program_cs`）
#     **一字节未动** ⇒ 臂日志逐位未变（`ARM-LOG-SHA` 5/5 PASS、`tline` 仍 `70bbbe00a34f363c`）。
#   【② 阶段 1 的**同源证明**（反极性）】把唯一声明那一行改成 `Release` ⇒ **shell 与两条 MSBuild 图同时读到 Release**
#     （三边一起动）；改回 `Debug` ⇒ 三边一起回。这正是"配置只许有一处"的机器证（`selfbuilt-config.sh --check`）。
#   【③ ⚠️ 门禁当场抓到我的一处真错（已修，值得记）】第一版变量名起成 **`WPF_LINUX_SELF_CONFIG`**，
#     而**应用门禁的默认档就是"清空全部 `WPF_LINUX_*`/`HLWPF_*` 字体 env"** ⇒ 那一档里它被 `unset`
#     ⇒ 应用路径塌成 `bin//net10.0` ⇒ 应用 **`exit=127`（command not found）**、`default` 档三 rep 全红，
#     而 `env` 档照常 2828 色（症状 = "只有主档死"）。改名 **`SELFBUILT_CONFIG`**（清理域之外）后两档恢复。
#     ⇒ **纪律：新增工具变量必须避开判据的清理域**（同族先例：诊断变量用 `WPFGFX_ROOTDIAG`）。
#   【④ ⚠️ 另一处自伤：棘轮被自己顶红】`--debt` 的统计 grep **自己的模式串里也有 `bin/Debug`**
#     ⇒ 把 186 顶成 192 ⇒ `SELFCONFIG_DEBT_CHECK=FAIL live=192 > max=186`。修法 = 计数时**排除本文件**
#     （同族教训：**"写下那句话的动作本身会改变证据"**）。
#   【⑤ 本波**没做**（边界，不许当已做）】① **改值**（`Debug → Release`）—— 必须与阶段 2（`integration-wave` 以
#     Release 重建九个位 ＋ bridge AOT）和阶段 3（186 处逐处判定，**不许 sed 全替**）**同趟**，否则会出现
#     "权威件 Release、仪器读 Debug"的混合态；② `D-G47`（那条 `Debug.Assert`）因此在**本波仍未治**；
#     ③ GDI+ 图像族真解码；④ `D-T4`；⑤ `upstream/wpf` 的 provenance（要联网）。
BASELINE tier=default rep=1 config=pc:659a5dc64156b26a,bridge:496951adff86a557,pf:e9ea2f57c8a36e7d,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w39-gate-c
BASELINE tier=default rep=2 config=pc:659a5dc64156b26a,bridge:496951adff86a557,pf:e9ea2f57c8a36e7d,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w39-gate-c
BASELINE tier=default rep=3 config=pc:659a5dc64156b26a,bridge:496951adff86a557,pf:e9ea2f57c8a36e7d,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w39-gate-c
BASELINE tier=env rep=1 config=pc:659a5dc64156b26a,bridge:496951adff86a557,pf:e9ea2f57c8a36e7d,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w39-gate-c
BASELINE tier=env rep=2 config=pc:659a5dc64156b26a,bridge:496951adff86a557,pf:e9ea2f57c8a36e7d,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w39-gate-c
BASELINE tier=env rep=3 config=pc:659a5dc64156b26a,bridge:496951adff86a557,pf:e9ea2f57c8a36e7d,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w39-gate-c
# ⏪ **（历史，已被 `#39` 取代）**# RE-FROZEN #38 —— ✅ **当前冻结基线** —— 内容 = **把 `D-G45` 打通**：官方 `System.Windows.Extensions` 包
#   （`XamlAccessLevel`/`SoundPlayer`/`X509Certificate2UI` 在非 Windows 上**必抛**）→ **仓内 Linux 原生替身**。
#   `#36` 回退的原因**不是"替身不可用"**，而是两条真根因（本波查明并修掉）：
#   ① 应用器 HintPath 写死 `bin/Release/`，而波把替身建在 **Debug** ⇒ 引用**落空** ⇒ RAR 回落到**官方包**
#      ⇒ `System.Xaml.dll` 带**包的签名身份**（`PublicKeyToken=cc7b13ffcd2ddd51`）⇒ `PresentationFramework`
#      报 `CS0012: 类型"XamlAccessLevel"在未引用的程序集中定义`；修法 = HintPath 改 `bin/$(Configuration)/`。
#   ② `System.Security.Permissions 9.0.0` **传递依赖** SWE ⇒ 把直接包引用**整条删掉**也没用
#      （restore 仍把包拉回来，`project.assets.json` 里 SWE 命中 14 处）⇒ 必须留一条
#      **排除 `compile;runtime` 资产**的**占位包引用**（`#36` 只试过 `ExcludeAssets="runtime"` —— 编译资产还在 ⇒ 包照样赢）。
#   ⇒ 7 个工程 + 4 个样本 **全 0 error**；替身进每个应用输出目录；`integration-wave.sh` rc=0（应用器审计 `appliers=24 ok=83 miss=0`）。
#   ＋ **替身公开面按上游真实用法补齐**：`SoundPlayer`（`Dispose`/`IsLoadCompleted`/`LoadCompleted`/`Stream`/
#      `new SoundPlayer(Stream)`/`LoadAsync`/`Play` —— 来自 `SoundPlayerAction.cs`）与**同属官方包的**
#      `X509Certificate2UI`/`X509SelectionFlag`（`WindowsBase` 的 `PackageDigitalSignatureManager` 用）；
#      替身改为**公开签名**（本仓 `build/keys/WcpPublicKey.snk`，与其他自产件同形态）⇒ 强命名引用不再报 `CS8002`。
#   ＋ **B4 两极化判据进了仓**：`samples/ThirdPartyMini` 里引用 **internal** 类型 ⇒ PBT 生成
#      `GeneratedInternalTypeHelper`（生成物命中 1 次）⇒ `LoadBaml` 必然走 `XamlAccessLevel`：
#      **正极性 `THIRDPARTY=PASS max_colors=1642`｜反极性（换回官方包）`FAIL reason=app-exit=134`
#      ＋ `System.PlatformNotSupportedException: System.Windows.Extensions types are not supported on this platform.`**
#   ＋ **新登记 `D-G47`**（与 SWE 无关、反极性对照过）：真实第三方 demo 运行期死在
#      `Assertion Failed: DependencyProperties can only be set on DependencyObjects`（`TemplateContent` 解析模板）
#      ⇒ **Debug 权威件带着"活的"`Invariant.Assert`**，真实应用会被断言终止（`rc=134`）——留给"权威件切 Release"那一波。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行。
#   **九位：4 位变** —— `pc` `dafb387d4aad3af8 → 4cbdeeabb0338213`、`pf` `7beba536851e8992 → 37fd347eb55ca02e`、`windowsbase` `279a7e6cfef37094 → 19de048ecb968daa`、
#     `dwf` `497c203a105b3ae7 → 24e819debc1e5b13`（四件都被"接线 + 重建"牵动：它们直接/间接引用 SWE）；
#     其余五位逐位与 `#37` 相同（`bridge` `496951adff86a557`／`provider` 未动／`win32shim` `8c4f5a8685882b8f`／`wic_shim` 未动／
#     `hbtextline` 未动 ⇒ `GEN_KEYS` 三项全未变 ⇒ **不重取五臂**）。
#   ⚠️ **`inputs_fp` 变了**（`269377aa402fc838df797635d2cca0b39b0831a8975a8bc7a0f78a90b35316c7` → **`cf89d8be0f909ecea0f228c4e75cbf1dfb0db9ac32d8d41815e8cf20e816d342`**）：本波动了 `build/integration-wave.sh`（应用器接通）、
#     `src/WpfGfx.Linux.Native/tools/patch-swe-linux.py`（两条根因的修法）、`verify-all.sh`（代账 `25 gen=#38`）、
#     `build/MilBridge/tools/build-hygiene-import-check.sh`（`CAND_MIN` 83 → 85）等。
#   ⚠️ **`BRIDGE_SRC_FP` = `794ea22406cc88ab`**（未变、**未重发** —— 本波不碰 `src/WpfGfx.Linux.Native/*.cs|*.csproj` 的 C# 源）。
#   【外挂声明：`D-G27` 的读者要读的 4 类行】⚠️ 谁改它们谁要让读者一起绿。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=70bbbe00a34f363c
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 五臂：**不重取**（有理由）】本波只动 `.cs`（替身，**不在 `GEN_KEYS`**）、应用器与波脚本 ⇒
#     `GEN_KEYS` 三项（`instr_shim`=`build/shims/PresentationCore.HbTextLine.cs`、`instr_run_sh`、`instr_program_cs`）
#     **一字节未动** ⇒ 臂日志逐位未变（`ARM-LOG-SHA` 5/5 PASS、`tline` 仍 `70bbbe00a34f363c`）。
#   【② 本波最硬的一组读数 = B4 两极化】正极性 `THIRDPARTY=PASS frames=28 max_colors=1642 min_colors=800`
#     ＋ `THIRDPARTY_IMAGE=PASS 96x96 format=Bgra32`；反极性（配方换回官方包）`THIRDPARTY=FAIL frames=0
#     reason=app-exit=134`、`rc=1`，异常逐字 `System.PlatformNotSupportedException: System.Windows.Extensions
#     types are not supported on this platform.` ⇒ "官方包必抛 / 替身不抛"第一次有了**仓内**两极化判据。
#   【③ 第三方 demo（仓外）复验：库 + demo **0 error**，但运行期死于一条**与 SWE 无关**的断言】
#     反极性对照（换回官方包）**同一个 assert**（不是 `PlatformNotSupportedException`）⇒ ① 不是接线造成的；
#     ② 该 demo 的程序集里**没有** `GeneratedInternalTypeHelper`（实测 0）⇒ 它走不到 SWE 那条路。
#     根因方向 = **Debug 权威件 + 上游 `Invariant.Assert` 未条件化** ⇒ 登记 **`D-G47`**。
#   【④ 一处自伤（如实记）】`patch-swe-linux.py` 被我的一次引号写坏的补丁弄成了语法错误
#     （文件当时**没有备份**）⇒ 靠"局部重建 + `ast.parse` 复核"救回；教训 = **改仪器前先备份**
#     （本波后续每一步都先 `cp` 备份，见 `$HOME/w38-backup/`）。
#   【⑤ **本波没做**（边界）】① 权威件 **Debug → Release**（下一波；`D-G47` 正指向它）；② GDI+ 图像族真解码；
#     ③ `D-T4`；④ `upstream/wpf` 的 provenance（要联网）。
BASELINE tier=default rep=1 config=pc:4cbdeeabb0338213,bridge:496951adff86a557,pf:37fd347eb55ca02e,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w38-gate-b
BASELINE tier=default rep=2 config=pc:4cbdeeabb0338213,bridge:496951adff86a557,pf:37fd347eb55ca02e,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w38-gate-b
BASELINE tier=default rep=3 config=pc:4cbdeeabb0338213,bridge:496951adff86a557,pf:37fd347eb55ca02e,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w38-gate-b
BASELINE tier=env rep=1 config=pc:4cbdeeabb0338213,bridge:496951adff86a557,pf:37fd347eb55ca02e,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w38-gate-b
BASELINE tier=env rep=2 config=pc:4cbdeeabb0338213,bridge:496951adff86a557,pf:37fd347eb55ca02e,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w38-gate-b
BASELINE tier=env rep=3 config=pc:4cbdeeabb0338213,bridge:496951adff86a557,pf:37fd347eb55ca02e,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w38-gate-b
# ⏪ **（历史，已被 `#38` 取代）**# RE-FROZEN #37 —— ✅ **当前冻结基线** —— 内容 = **① 第三方形态**进仓（`verify-all` **24 → 25 步**）：
#   新第 `[19]` 步 `THIRD-PARTY` 跑 `samples/ThirdPartyMini`（只经 `build/third-party/WpfLinux.props` 接线、
#   **不进** `wpf-linux.sln`、把产物**复制到仓外**再跑、判据 = 采样窗口内颜色数 ≥ 800；反极性 = 不部署
#   `libwpfwin32.so` ⇒ `FAIL`）—— 它把"第三方 app 能渲染"从**仓外口头证据**升级成**仓内判据**
#   ＋ **② 仪器四项**：`F1` `magenta_frames=n/a`（"没测"不许冒充 0）｜`F2` 新读者进 `fp_inputs()`（123 → 124）｜
#   `F3` **"本代必须有预登记节"的牙**（挂在现有第 `[11]` 步里 ⇒ **步数不变**）｜`F4` `pf` **可复现性探针**
#   ⇒ 登记 **`D-G46`**（封条分不清"可复现构建"与"某次构建的身份位"）
#   ＋ **③ 覆盖面 124 → 125**（第三方 runner 也是判据件）＋ **④ 声明表 81 → 82**（`D-G46`）＋ `CAND_MIN` 83 → 85。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行。
#   **九位：只有环成员 `pf` 变** —— `dbb0a450e09e76a3 → 7beba536851e8992`（`integration-wave.sh` 重编引起；**与 `D-G46` 的发现一致**：它是"构建身份位"，不是内容）。其余八位逐位与 `#36` 相同：`bridge` `496951adff86a557`／`pc` `dafb387d4aad3af8`／`windowsbase` `279a7e6cfef37094`／`provider` 未动／`win32shim` `8c4f5a8685882b8f`／`wic_shim` 未动／`hbtextline` 未动（`GEN_KEYS` 三项全未变 ⇒ **不重取五臂**）／`dwf` `497c203a105b3ae7`。
#   ⚠️ **`inputs_fp` 变了**（`c28cd49f8e802c7522f484aef81a40ffb98db2459e5c2c571b0031616c70f0f8` → **`269377aa402fc838df797635d2cca0b39b0831a8975a8bc7a0f78a90b35316c7`**）：本波动了 `build/close-wave.sh`（`fp_inputs()` 两处纳入）、
#     `verify-all.sh`（+1 步 ＋ 三处声明）、`build/MilBridge/tools/{frame-presence-check,verify-all-step-check,build-hygiene-import-check,defect-registry-declared}.{sh,tsv}`、`build/MilBridge/known-red.json` 等。
#   ⚠️ **`BRIDGE_SRC_FP` = `794ea22406cc88ab`**（未变、**未重发** —— 本波不碰 `src/WpfGfx.Linux.Native/*.cs|*.csproj`）。
#   【外挂声明：`D-G27` 的读者要读的 4 类行】⚠️ 谁改它们谁要让读者一起绿。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=70bbbe00a34f363c
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 五臂：**不重取**（有理由）】本波只动 `.sh`/`.py`/`.md`/样本工程 ⇒ 世代绑定三项（`GEN_KEYS`：
#     `instr_shim`=`build/shims/PresentationCore.HbTextLine.cs`、`instr_run_sh`、`instr_program_cs`）**一字节未动**
#     ⇒ 臂日志逐位未变（`ARM-LOG-SHA` 5/5 PASS，`tline` 仍 `70bbbe00a34f363c`）。
#   【② 第三方形态的读数（两极化，都实测）】正极性 `THIRDPARTY=PASS max_colors=1485 min_colors=800`
#     ＋ `THIRDPARTY_IMAGE=PASS 96x96 format=Bgra32`（应用自己打印的解码结果）＋ `rc=0`；
#     反极性（`--hide-shim`）`THIRDPARTY=FAIL reason=app-exit=134`、`rc=1`，日志逐字含
#     `DllNotFoundException: 'kernel32.dll' 已映射到 libwpfwin32.so，但没找到可加载的 shim 库`。
#     ⭐ 两条**真问题**（都已修、都写进 `samples/ThirdPartyMini/README.md` 与 `docs/THIRD-PARTY-APPS.md`）：
#     ① `Win32ShimResolver` 的候选路径会从 `AppContext.BaseDirectory` **与** `Directory.GetCurrentDirectory()`
#        两条各自向上走 12 层找仓根（`Win32ShimResolver.cs:524-537`）⇒ **应用在仓内或 cwd=仓根时，
#        不部署 `.so` 也会被回退救回来**（现场：`--hide-shim` 照样 1485 色 PASS ⇒ 反极性失效）⇒
#        runner 改成"复制到仓外 ＋ 启动时 `cd` 到应用目录"；② "一帧没采到"原先一律记 `NOINFO`，
#        把"应用崩了"混成"仪器没跑" ⇒ 现在按**应用退出码**细分（崩 ⇒ `FAIL`）。
#   【③ `F4` 探针**推翻了"pf 是噪声"这个猜想**（结论比猜想更有用）】三趟干净重编（两趟到 `/tmp` 各自
#     独立 `OutputPath`、一趟默认路径）**逐字节相同** = `a3b1df59e1d0d05b` ⇒ **构建是确定性的**；
#     而 `#36` 冻结的 `pf` = `dbb0a450e09e76a3` **不等于任何一趟干净重编**，差异仍只有 **72 B / 5 段**
#     （PE 时间戳、MVID、Debug Directory 的 PDB GUID/校验和）⇒ **IL 与元数据逐字节相同**。
#     ⇒ 冻结块里那一行是"**当时现场的身份位**"，**不是**"当前源码的可复现构建" ⇒ 登记 **`D-G46`**：
#     九位封条**没有任何牙**能区分这两件事（本波是**探针**查出来的）。探针安全性：九位探针前后逐位未变、
#     动过的冻结件当场按字节放回（`sha256 = dbb0a450e09e76a3`）。
#   【④ 本波自伤一次（如实记）】`fp_inputs()` 的 `printf` **续行链里塞了注释行** ⇒ `\` 先拼行、再认注释，
#     `#` 把链尾吃掉 ⇒ 后面那行路径变成**独立命令被执行**（它真的把第三方样本跑了一遍，输出被灌进
#     `xargs sha256sum`）。修法 = 注释只能写在独立注释行上；现场留在 `docs/WAVE37-PREREGISTRATION.md` §3.3b。
#   【⑤ **本波没做**（边界，不许当已做）】① 权威件 **Debug → Release**（单独成波：会翻九位 ＋ 改门禁链）；
#   【⑥ 收尾期的文档落地（如实登记，时序与 `#36` 同形）】下面这些在**冻前那趟 `verify-all` 之后**才更新：
#     `docs/CURRENT-STATE.md`（顶部 `#37` 摘要 ＋ `#37` 冻结节）、`handoff.md`（`#37` 速览）、
#     `docs/WAVE37-PREREGISTRATION.md`（§3.3b／§3.4b／§3.5b）、`docs/THIRD-PARTY-APPS.md`（§1b）、
#     `README.md`、`samples/ThirdPartyMini/README.md`（新）。它们**不在 `fp_inputs()` 覆盖面、
#     **不是九位成员、也不是基线文件** ⇒ **不影响本块的任何机器声明**；两条相关检查器
#     （`BASELINE-SHA`／`DEFECT-REGISTRY`）在文档落地后**当场复跑 rc=0**（其余六条同批也 rc=0）。
#     ② `D-G45`（`System.Windows.Extensions` 接线）；③ GDI+ **图像族真解码**；④ `D-T4`；⑤ `upstream/wpf` 的
#     provenance（要联网环境补）；⑥ `.gitignore` 里那两份大件的"gzip/LFS"若将来要入库才需要选型（今天已查明可排除）。
BASELINE tier=default rep=1 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:7beba536851e8992,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w37-gate-b
BASELINE tier=default rep=2 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:7beba536851e8992,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w37-gate-b
BASELINE tier=default rep=3 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:7beba536851e8992,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w37-gate-b
BASELINE tier=env rep=1 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:7beba536851e8992,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w37-gate-b
BASELINE tier=env rep=2 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:7beba536851e8992,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w37-gate-b
BASELINE tier=env rep=3 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:7beba536851e8992,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w37-gate-b
# ⏪ **（历史，已被 `#37` 取代）**# RE-FROZEN #36 —— ✅ **当前冻结基线** —— 内容 = **① 把"时间分辨的画面读者"接进 `verify-all`**（`#34` 两条**仪器伪影**的制度性修法）：
#   新牙 `build/MilBridge/tools/frame-presence-check.sh`（判据 = **采样窗口内"标记色是否出现过"**，三态、`--selftest` 5/5）
#   成为新第 `[18]` 步 `FRAME-PRESENCE` ⇒ **`verify-all` 23 → 24 步**（`#36` 收官起 = 24 步）＋
#   **② `D-G45` 登记**：把官方 `System.Windows.Extensions` 包换成 Linux 原生替身（`build/System.Windows.Extensions.Linux/`，
#   构建 0 错）的**接线试接后回退** —— 接线时 `PresentationFramework` 报 11 错（`CS0012: 类型"XamlAccessLevel"在未引用的程序集中定义`），
#   根因是**程序集身份不一致**（包签名 / 替身未签名）；替身工程与应用器都留着、应用器在 `integration-wave.sh` 里**注释停用**；
#   **③ `pf` 唯一一位位移已逐字节归因**（72 B / 5 段，全在**构建身份**字段上：PE 时间戳、MVID、Debug Directory 的 PDB GUID/校验和；
#   **IL 与元数据表逐字节相同**）＋ **④ 本节与记录是"落地之后"补写的**（流程缺口，见 `docs/WAVE34-PREREGISTRATION.md` §3w）。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行。
#   **九位：1 位变** —— `pf` `f5beeb353baa959c → dbb0a450e09e76a3`（7122432 B，**同尺寸**；逐字节差异 = 72 B / 5 段，**全在构建身份字段**（PE 时间戳 4 B、MVID 16 B、
#     Debug Directory 4 B ＋ PDB GUID 16 B ＋ PDB 校验和 32 B）⇒ **IL 与元数据堆逐字节未动**（`#~`/`#Strings`/`#US`/`#Blob` 与 `AssemblyRef` 全同）。
#     ⚠️ **归因到"是身份不是内容"为止；"为什么这一趟的身份位会变"仍未归因**（下一波的同源重编探针见 §3w ③）。
#     其余八位逐位与 `#35` 相同（`bridge` `496951adff86a557`／`pc` `dafb387d4aad3af8`／`windowsbase` `279a7e6cfef37094`／`provider`／`win32shim` `8c4f5a8685882b8f`／`wic_shim`／`dwf` `497c203a105b3ae7`）——
#     ⚠️ 这说明**"同源重建 ⇒ 逐位相同"对本仓的多数产物成立**（本波所有九位都被重编过），`pf` 是**例外**，不是通例。）
#   ⚠️ **`inputs_fp` 变了**（`982cdbe68f48dd517952c76ef448dad80bfffb177147728cbdc95c37171e2880` → **`c28cd49f8e802c7522f484aef81a40ffb98db2459e5c2c571b0031616c70f0f8`**）：本波改了 `build/MilBridge/known-red.json`（`tline` 臂重钉**两处**：`generation.evidence_log_sha256` 与 `generation.arm_logs.tline`）。
#   ⚠️ **`BRIDGE_SRC_FP` = `794ea22406cc88ab`**（未变、**未重发** —— 本波不碰 `src/WpfGfx.Linux.Native/*.cs|*.csproj`）。
#   【外挂声明：`D-G27` 的读者要读的 4 类行（`COLUMN-FLOOR` 两行 ＋ `COLUMN-CORPUS` 一行 ＋ 五条 `ARM-LOG-SHA`）】⚠️ 谁改它们谁要让读者一起绿。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=70bbbe00a34f363c
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 五臂重取：**只有 `tline` 变**】`cbf42d86addd266f → 70bbbe00a34f363c`（其余四臂逐位未变）；
#     重取口径 = `ARMS_OUT=$HOME/w36-arms bash build/MilBridge/tools/retake-arms-w23.sh`（纪律 59），硬链接进 `build/MilBridge/arm-logs/`（`nlink=2`）；
#     臂日志聚合两种口径：`cat` = `6fcc5c658cd3e05a`、`find|sort|xargs` = `89c11b2450942ee5`。
#     ⚠️ **重钉要点（`D-G44` 的第二处，本波亲手撞到）**：`tline` 的声明在**两处** —— 本块（收官器写）与
#     `build/MilBridge/known-red.json`（`generation.evidence_log_sha256` **16 位** ＋ `generation.arm_logs.tline` **全 64 位**）。
#     只改一处会让 `ARM-LOG-SHA` 与 `COLUMN-FLOOR` 的 `ARMLOG` 子检**互相打架** ⇒ 本波先重钉 JSON、再由收官器写本块。
#   【② 应用门禁】`:97` 上两档 × 3 rep 全绿（`gate_a_rc=0`、`gate_b_rc=0`）；6 条 `BASELINE` 机读行的 `pc:`/`pf:` 是**终态**值；
#     逐 rep 的窗口内画面证据 = `$HOME/w36-gate-a/`、`$HOME/w36-gate-b/` 的 `burst2-<档>-r<rep>-<帧>.png`（每 rep 6 帧连拍）。
#   【③ 第 `[18]` 步 `FRAME-PRESENCE` 的来历（两条都是**我自己造的**仪器伪影）】
#     ① 旧判据取"**颜色数最多**的一帧" ⇒ 任何"让颜色数**下降**的变化"被系统性漏掉：`--late-content` 实测颜色数
#        **3960 → 2556**（内容变色但颜色变少）⇒ 采用帧永远落在**变化之前**，我据此报过一条**假红**；
#     ② "**跑了 N 秒 ≠ 拍了 N 秒**"：采样脚本 12 张截图实际落在 **t≈0.4–4.8 s**，而内容 **t≈8.0 s** 才出现。
#     新读者的判据是**时间分辨**的（窗口内标记色是否出现过），并把窗口**印在读数里**；
#     `--selftest` **5/5** 覆盖 `FAIL/PASS/PASS/FAIL/NOINFO` ⇒ "**能红能绿**"两极化在册。
#   【④ `D-G45`（本波登记，**未治本**）】替身与应用器都已写好（`build/System.Windows.Extensions.Linux/`、`patch-swe-linux.py`：7 工程、
#     `--check`/幂等/两形态迁移都验过），接线后 `PresentationFramework` 报 11 错（`CS0012: 类型"XamlAccessLevel"在未引用的程序集中定义`）
#     ⇒ 四工程对 SWE 的**程序集身份不一致**（包签名、替身未签名；删 `PackageReference` 后 `project.assets.json` 是否随隐式 restore 更新亦未验）。
#   ＋ **⑤ 收尾期落了「发布就绪」文档**（为开源首版）：仓根 `README.md`、`.gitignore`、
#   `docs/RELEASE-READINESS.md`（含 GitHub 单文件 100 MB 硬限的实测拦路：`tests/parity/geometry/u14/linux-results-u14.json` = 118.2 MB）、
#   `docs/THIRD-PARTY-APPS.md` ＋ `build/third-party/WpfLinux.props`（第三方工程接入配方）、
#   `build/fonts/LICENSE-OFL.txt`（Noto Sans 是 OFL ⇒ 必须随附）；**不动任何覆盖面、不动九位**（实测 `fp_inputs`/`BRIDGE_SRC_FP` 逐字未变）。
#     已回退：应用器在 `integration-wave.sh` 里**注释停用**、从 `applier-audit-expected.txt` 摘掉（`--check` 复核 **0/7 已接线**）、替身工程**保留**（`ORDER` 里、构建 0 错）。
#   【⑤ **本波没做**（边界，不许当已做）】① GDI+ **图像族真解码**（今天只做到"应用能起来"）；② 权威件**切 Release**
#     （上游 `Debug.Assert`/`Invariant.Assert` 会 FailFast 真实应用）；③ `D-T4`（唯一改像素的已知红）；④ 第三方原生 interop 的**发布说明**；
#     ⑤ **新读者 `frame-presence-check.sh` 没进 `fp_inputs()` 覆盖面**（它是判据件、理应被看着；留给下一波，理由 = 不在收尾波里改覆盖面定义）；
#     ⑥ **预登记时序**：`#36` 的落地**先于**预登记（违反自家协议，如实登记在 `docs/WAVE34-PREREGISTRATION.md` §3w 开头）。
#   【⑥ 收尾期另落的「发布就绪」文档（如实登记）】`README.md`（仓根，新）、`.gitignore`（新）、
#     `docs/RELEASE-READINESS.md`（新）、`docs/THIRD-PARTY-APPS.md`（新）、`build/third-party/WpfLinux.props`（模板，新）、
#     `build/fonts/LICENSE-OFL.txt` ＋ `build/fonts/README.md`（Noto Sans 是 **SIL OFL 1.1** ⇒ 必须随附全文）。
#     **实测「三不动」**：① `fp_inputs()` 逐字未变（`c28cd49f8e802c7522f484aef81a40ffb98db2459e5c2c571b0031616c70f0f8`）；② `BRIDGE_SRC_FP` 未变（`794ea22406cc88ab`）；③ 九位未变。
#     三条相关检查器**当场复跑全绿**：`DEFREG=PASS declared=81`、`BHYGIENE_IMPORT=PASS`、`QUOTE-TRAP` rc=0。
#     ⚠️ **时序如实说**：它们落在那趟**作为冻前输入**的 `verify-all` 跑到第 `[5]` 步之后
#     （⇒ 该日志第 `[10]` 步起读的是「落了文档的树」，第 `[1]`–`[9]` 是落之前的树；文档不在任何判据的输入里，故三不动）；
#     且**本块没有任何机器声明依赖它们**。
BASELINE tier=default rep=1 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:dbb0a450e09e76a3,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w36-gate-b
BASELINE tier=default rep=2 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:dbb0a450e09e76a3,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w36-gate-b
BASELINE tier=default rep=3 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:dbb0a450e09e76a3,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w36-gate-b
BASELINE tier=env rep=1 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:dbb0a450e09e76a3,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w36-gate-b
BASELINE tier=env rep=2 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:dbb0a450e09e76a3,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w36-gate-b
BASELINE tier=env rep=3 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:dbb0a450e09e76a3,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w36-gate-b
# ⏪ **（历史，已被 `#36` 取代）**# RE-FROZEN #35 —— ✅ **当前冻结基线** —— 内容 = **① 第三方 app 的"正道通道"落地**：`Win32ShimResolver` 挂**默认 ALC 级钩子**
#   （`AssemblyLoadContext.Default.ResolvingUnmanagedDll`）⇒ **第三方程序集**的 `[DllImport("user32.dll")]` 也能落到我们的 shim；
#   映射表补 `shell32`/`ntdll`/`gdiplus`/`msimg32`/`dwmapi` 五个名字，并为此新建 shim 源文件
#   `src/WpfGfx.Linux.Native/src/win32_oem.c` ＋ `win32_gdiplus.c`（约 35 个入口；口径：能真做的真做、做不到的**如实失败**、
#   GDI+ 只做到"应用能起来"）＋ **② `dwmapi` 语义订正**（"有 DWM 但合成关闭" = S_OK＋FALSE，而不是一律 `NOT_SUPPORTED`；
#   后者会让 WPF 走进"不画客户区"的路）＋ **③ `RtlGetVersion` 越界写修好**（见下，这条是"零探针装置下能渲染"的最后一击）＋
#   **④ `D-G44` 登记并修好收官器**（声明类改成**逐项极性**判定：冻前红/绿都接受，冻后必须绿）。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行。
#   **九位：5 位变** —— `pc` `6f86961e164b689b → dafb387d4aad3af8`、`pf` `3978376f2b56c5c0 → f5beeb353baa959c`（波尾重编）、`windowsbase` `1114a28ec5a03ab7 → 279a7e6cfef37094`（三件都编入解析器）、
#   `win32shim` `cc621224c7492132 → 8c4f5a8685882b8f`（OEM/GDI+ 面）、`dwf` `0ed422ef2dd46445 → 497c203a105b3ae7`（同源）。
#   ⚠️ **`inputs_fp` 变了**（`5f73a979…` → **`982cdbe68f48dd517952c76ef448dad80bfffb177147728cbdc95c37171e2880`**）：本波重钉了 `build/MilBridge/known-red.json` 的 `tline` 臂日志并重生成声明表
#   ⇒ 覆盖面里那两件的内容变了。**如实声明**，不当作事故。
#   【外挂声明：`D-G27` 的读者要读的 4 类行（值逐位与 `#33`/`#34` 相同）】⚠️ 谁改它们谁要让读者一起绿。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=cbf42d86addd266f
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① **零探针装置下第三方 app 渲染出完整界面**（本波最重要的产品结论）】判据 = 根窗口截图里**窗口矩形内**的颜色数：
#     旧探针配置（5 个 `.dll.so` 桩 ＋ 6 个硬链接别名）1274 ｜ **零桩零别名（本波产品形态）1275** ✅。
#     走的路径：`user32` 族经 **ALC 钩子**落 shim；`shell32/gdiplus/msimg32/dwmapi` 由 shim 新面提供；`ntdll` 由 shim 的 `RtlGetVersion` 提供。
#   【② **根因（纪律候选 79）**】我上一版 `RtlGetVersion` 按"我以为的 280 字节"写满整个结构并回填 `dwOSVersionInfoSize`；
#     而**调用方的托管声明算出的大小不同**（`szCSDVersion` 用 ANSI `ByValTStr(128)` 时整个结构仅 **148** 字节，Unicode 才是 280）
#     ⇒ **越界踩坏调用方内存**。症状**不是异常**：窗口建得出来、`WPF_LINUX_MIL_TRACE` **一行都没有**、整屏全黑（呈现链没跑到）。
#     修法：只写前 20 字节固定字段、`dwOSVersionInfoSize` **原样回填调用方声明值**、其余仅在声明长度够时才清。
#   【③ 逐名二分（同一批读数）】撤 `gdiplus`/`shell32`/`msimg32`/`dwmapi` ⇒ 1274/1275/1275/1275（都正常）；**只有撤 `ntdll` 会黑屏**
#     —— 这条二分把病因从"映射面"缩到"某个实现" ⇒ 直接指向 `RtlGetVersion`。
#   【④ `D-G44`】收官器前置与波内声明态互斥（已修：声明类逐项极性）；同族第二处（臂重钉在 `known-red.json`、冻结脚本没覆盖）**如实登记**。
#   【⑤ 应用门禁】两档各 3 rep 全绿（读数见门禁 6 条机读行；`default`：drawn=260/colors=3960；`env`：drawn=144/colors=2828）。
#   【⑥ **本波没做**】① 新读者 `frame-presence-check.sh` **仍未接进** `verify-all` 步骤表（步骤数仍 23）；
#     ② `System.Windows.Extensions` 替身**仍未接进**九工程 `PackageReference`（靠"构建后部署"）；
#     ③ 权威件仍是 **Debug 构建**；④ `D-T4` 未动；⑤ GDI+ **图像族**（真解码）未接 Skia/WIC，只做到"应用能起来"。
BASELINE tier=default rep=1 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:f5beeb353baa959c,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w35-gate-b
BASELINE tier=default rep=2 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:f5beeb353baa959c,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w35-gate-b
BASELINE tier=default rep=3 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:f5beeb353baa959c,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w35-gate-b
BASELINE tier=env rep=1 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:f5beeb353baa959c,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w35-gate-b
BASELINE tier=env rep=2 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:f5beeb353baa959c,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w35-gate-b
BASELINE tier=env rep=3 config=pc:dafb387d4aad3af8,bridge:496951adff86a557,pf:f5beeb353baa959c,provider:9aa0d744802aaa31,win32shim:8c4f5a8685882b8f,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w35-gate-b
# ⏪ **（历史，已被 `#35` 取代）**# RE-FROZEN #34 —— ✅ **当前冻结基线** —— 内容 = **① 由第一个真实第三方 WPF 应用（HandyControl 示例工程）实测撞出来的移植缺口并修**（`MimeTypeMapper` 的 UrlMon/注册表查询 → 内置表＝补丁 Q；WIC 的**流分支**：`IWICImagingFactory_CreateDecoderFromStream` ＊派生对象的**字节继承** ＊`CreateBitmap` 真实现）＋ **② 两个"谎话/缺失"级 shim 缺陷**（`SetWindowRgn` 原返回 0 且注释把语义写错 ⇒ **任何 `WindowChrome` 应用必崩**；全局钩子三件套**完全没导出** ⇒ 第三方应用被 `EntryPointNotFoundException` 掀掉）＋ **③ 把官方包在非 Windows 上"必抛"的实现换成 Linux 原生替身**（`System.Windows.Extensions`：`XamlAccessLevel` 等；该包只有 `runtimes/win` 才是真实现）＋ **④ 仪器加固**：新增**时间分辨**的画面读者 `build/MilBridge/tools/frame-presence-check.sh`（三态、能红能绿、`--selftest` 5/5）＋ **⑤ `D-G44`**：`w27-freeze.py` 的前置与波内声明态**互斥**，改成"声明类**冻前必红、冻后必绿**"的两极化。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行（本处照纪律 53 **不重述值**）。
#   **九位：5 位变** —— `bridge` `496951adff86a557`（4991984 B；AOT 重建：呈现路径加"根投影诊断"，env 门控 `WPFGFX_ROOTDIAG`，默认关）、`pc` `b877ff3e3437145a → 6f86961e164b689b`（4198912 B；补丁 Q ⇒ 表外扩展名不再走 UrlMon 的 COM 封送）、`pf` `445a278b4a17ba07 → 3978376f2b56c5c0`（7122432 B；波尾 `[1/6] integration-wave.sh` 重编）、`win32shim` `0098234982391bbf → cc621224c7492132`（`SetWindowRgn` 返 1 ＋ `SetWindowsHookEx/W/A`/`UnhookWindowsHookEx`/`CallNextHookEx` 如实失败）、`wic_shim` `03b67fbcd7c385b6 → 3df2ed77727bd4cf`（导出 77 → 78）。
#   ⚠️ **权威 `pc` 口径 = 波内 `integration-wave` 的构建**（`6f86961e164b689b`）；主控此前手工构建得过 `e659ca1c02dddf26`，**未归因**（疑与 PC 内嵌 shim 内容 sha 的 `AssemblyMetadata` 有关 —— 那天 `win32shim` 是在手工构建**之后**才重建的）。两值不同这件事**如实记录**，不掩盖。
#   ⚠️ **`inputs_fp` 是设计性变更**：`dc47e9751e0e1405fc55df86473a01b709dd37751434de173b1fc23da6bc955e` → **`5f73a97968fb5e4fef964390d0eabac8e0aeb3e852f9a399c8bbf8c96e709db0`**（本波把 `patch-presentationcore-mimetype.py` 与 `applier-audit-expected.txt` 纳入覆盖面 ⇒ 计数与值都变；脚本按代声明，不断言旧值）。
#   【外挂声明：`D-G27` 的读者 `column-floor-check.sh` 要读的 **4 类行**，本块继续钉下（值逐位与 `#33` 相同）】⚠️ 这几行**不是**本波的读数，是**外挂声明**：谁改它们谁要让读者一起绿。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=071aaf4573cebd58
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 五臂：**只有 `tline` 变**（`57d752a3981a9b91 → 071aaf4573cebd58`），其余四臂逐位未变。重取用 `ARMS_OUT=$HOME/w34-arms`（纪律 59），硬链接进 `build/MilBridge/arm-logs/`（`nlink=2`）。臂日志聚合两种口径：`cat` = `18fc115c17b43a54`、`find|sort|xargs` = `75691ad1a403007d`。
#   【② 应用门禁：两档 × 3 rep 全绿】`default`：`drawn=260 colors=3960 frames_good=14/14`；`env`：`drawn=144 colors=2828 frames_good=14/14`；`WPTD_SUMMARY=PASS tiers_passed=2/2`、**0 处 ❌**；截图 `$HOME/w34-gate-accept1/wpftextdemo-{default,env}-r{1..3}.png`。6 条 `BASELINE` 机读行的 `pc/pf` 见文末（逐行 `pc:6f86961e164b689b` `pf:3978376f2b56c5c0`）。
#   【③ **第三方应用里程碑（本轮最重要的产品结论）**】HandyControl 示例工程（v3.6.0.0，仓库外 `/home/links-dev/hc-linux`）在 Linux 上：
#     编译 **0 error**（库 1,711,104 B / demo 2,904,064 B，148 个 Page 进 BAML）；
#     **开窗并渲染完整界面** —— 自定义 chrome（标题栏＋`v1.0.0.0 .NET 10.0`＋三个按钮）、左侧导航栏中文控件名（画刷/按钮/…/展开框，各带图标）、右侧内容区一张**真实图片**；
#     证据 = **时间分辨**采样（每 0.5s 一帧、**窗口矩形内**数颜色）：`f001–f015` 1–3 色 → **`f016` 起 1091→1241 色**并稳定到采样结束；`rc=124`（被 timeout 杀，非崩）。
#     截图 `$HOME/w34-hc-34/f001..f036.png`（**f032 经人眼复核**）；**A/B**：去掉探针重建后逐帧一致 ⇒ 不是探针动作的功劳。
#     ⚠️ **诚实边界**：这一结论**不随本仓冻结**（HandyControl 不在仓内、探针装置在仓外），本块只把它记成"本波的产品依据"，**不构成仓内判据**。
#   【④ 三条**同类仪器伪影**（本波的"读数"教训，提议纪律 78）】
#     ㈠ 门禁判据③取"**颜色数最多**的一帧" ⇒ 任何"让颜色数**下降**的变化"被系统性漏掉（"首帧后换 Content"那次我据此报过**假红**）；
#     ㈡ 采样脚本"跑了 N 秒"被当成"拍了 N 秒"（12 张截图落在 t≈0.4–4.8s，而内容在 t≈8.0s 才出现 ⇒ 早期"只有背景"也是**假读数**）；
#     ㈢ `cp -p` 保 mtime ⇒ MSBuild 判"未改动"⇒ **构建没重编**（靠"产物 sha 变没变"抓住）。
#     ⇒ 判据的时间窗/口径必须覆盖结论的时间域与方向；新读者 `frame-presence-check.sh` 就是这条纪律的落点（`--selftest` 五例：FAIL/PASS/PASS/FAIL/NOINFO）。
#   【⑤ `D-G44`：冻结器的前置自相矛盾（已修）】原 `w27-freeze.py` 要求输入 `verify-all` 日志**全绿**，而 `BASELINE-SHA`/`ARM-LOG-SHA` 在波内**必然红**（在飞横幅改基线整份 sha；五臂重钉本就属"冻"这趟）⇒ "必须先绿才能冻"与"波内这两项必红"互斥。现改成**两极化**：冻前这两项**必须在日志里是 ❌**（证明真动了），冻后同一对检查器**必须转绿**（脚本内真跑）。本基线块就是这条改法跑出来的。
#   【⑥ **本波没做**（不许读成已做）】① 新读者**已进仓但未接进 `verify-all` 步骤表**（步骤数仍 `23`）；② `System.Windows.Extensions` 替身**已给 Linux 原生实现，但九个产品工程还没把它的 `PackageReference` 换掉**（今天靠"构建后部署"这一步，见 `docs/WAVE34-PREREGISTRATION.md` §3n）；③ 权威件仍是 **Debug 构建**（上游 `Debug.Assert` 会 FailFast 真实应用，`Invariant.Assert` 更是无条件）⇒ 切 Release 未做；④ `D-T4`（唯一会改像素的已知红）未动；⑤ 第三方原生 interop 的"正道通道"（映射表补齐＋ALC 钩子）未做，本轮靠**探针桩/硬链接别名**验证可行性。
BASELINE tier=default rep=1 config=pc:6f86961e164b689b,bridge:496951adff86a557,pf:3978376f2b56c5c0,provider:9aa0d744802aaa31,win32shim:cc621224c7492132,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w34-gate-accept2
BASELINE tier=default rep=2 config=pc:6f86961e164b689b,bridge:496951adff86a557,pf:3978376f2b56c5c0,provider:9aa0d744802aaa31,win32shim:cc621224c7492132,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w34-gate-accept2
BASELINE tier=default rep=3 config=pc:6f86961e164b689b,bridge:496951adff86a557,pf:3978376f2b56c5c0,provider:9aa0d744802aaa31,win32shim:cc621224c7492132,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w34-gate-accept2
BASELINE tier=env rep=1 config=pc:6f86961e164b689b,bridge:496951adff86a557,pf:3978376f2b56c5c0,provider:9aa0d744802aaa31,win32shim:cc621224c7492132,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w34-gate-accept2
BASELINE tier=env rep=2 config=pc:6f86961e164b689b,bridge:496951adff86a557,pf:3978376f2b56c5c0,provider:9aa0d744802aaa31,win32shim:cc621224c7492132,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w34-gate-accept2
BASELINE tier=env rep=3 config=pc:6f86961e164b689b,bridge:496951adff86a557,pf:3978376f2b56c5c0,provider:9aa0d744802aaa31,win32shim:cc621224c7492132,wic_shim:3df2ed77727bd4cf,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/w34-gate-accept2
# ⏪ **（历史，已被 `#34` 取代）**# RE-FROZEN #33 —— ✅ **当前冻结基线** —— 内容 = **① 把「`pipefail` ＋ 管道左侧被 SIGPIPE 杀死 ⇒ 判据错」这一族扫穷尽**（5 件 **57 处**，其中 `integration-wave.sh` 的两处是**假绿**方向：编译器警告静默通过／一个什么都没做的应用器被报 ✅）＋ **新建牙并接线第 `[17]` 步**（`verify-all` **22 → 23 步**）＋ **② `--selftest` 加固落地**（11 件：`D-G41` 的"本件 sha 自测首尾一致"自证 ＋ 三处同族前提加固）＋ **③ `FrameProbe` 的 3 条结构族红查清**（**它早已在**两本册子里**登记过** ⇒ 陈旧的是 `frame-step.sh` 自己那两句"未登记"；根因 = 已登记的 `D-T4`，且**不再需要一次 Windows 重录**）＋ **④ 补上 `#31`/`#32` 记的两个"未取到"读数** ＋ **⑤ 覆盖面 120 → 121、声明表 77 → 79**。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行（本处照纪律 53 **不重述值**）。
#   **九位**：**只有环成员 `pf` 变**（`a1ce403a74225f10 → 445a278b4a17ba07`，波尾 `[1/6] integration-wave.sh` 重编引起）；`bridge`/`pc`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` **逐位未动**（**本波不碰任何产品件** —— 改的全是 `.sh` 仪器）；**`hbtextline` 一字节未动 = `e89fed55fd8e32bc`（290825 B）** ⇒ **世代绑定三项（`GEN_KEYS`）全未变** ⇒ **不重取五臂**（臂日志逐位未变，两种聚合口径 `89cfd1fbeef3c4ab`／`c42fed87f7c1d5ed` 亦同）。`BRIDGE_SRC_FP=fdcb41bdc373eee3`（未变、**未重发**）。
#   ⚠️ **`inputs_fp` 是设计性变更**：`2b6e4df8b45e5912e79b7cf5317822b0bbc0a786528f7e77e4f7e4219fdbc4e9` → **`dc47e9751e0e1405fc55df86473a01b709dd37751434de173b1fc23da6bc955e`**（成员 **120 → 121**：**`#33` 主控把新接线的牙 `pipefail-sigpipe-check.sh` 纳入覆盖面**）。⚠️ 改覆盖面里的任何一件都会移动本指纹 ⇒ 必须安排在 `close-wave.sh` 的 `IN_FP_0` 之前（波尾实测 `波前==波后 == dc47e9751e0e1405fc55df86473a01b709dd37751434de173b1fc23da6bc955e`，**期间无手写改动**）。
#   【外挂声明：`D-G27` 的读者 `column-floor-check.sh` 要读的 **4 类行**，本块继续钉下（值逐位与 `#32` 相同）】⚠️ 该读者读的是**最新** `# RE-FROZEN` 块 ⇒ 本块成为最新块后声明必须跟着上来（否则第 `[14]` 步立刻 `NOINFO reason=declaration-gap`）。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=57d752a3981a9b91
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① `D-G42`：那一族**还剩 57 处**，且其中两处是**假绿**方向】**机制**（`#32` 定证）：`set -o pipefail` 下，**非末段**因读端提前关闭而吃 `SIGPIPE`（`rc=141`）⇒ 整条管线 rc 变非 0 ⇒ 用在 `if`/`&&`/`||` 里的管线**判据被翻转**。最典型 `printf '%s' "<多行串>" | grep -q PAT`（bash 的 `printf` 对多行串**每行一次 `write()`**，`grep -q` 命中即退）。
#     **本波修掉的 57 处**（同一改法 `… | grep -q PAT` → `grep -q PAT <<<"$V"`）：`check-applocal-sync.sh` **47**（A–P 18 例里 **13 例**的条件含此形态 —— `#26` W26C 当年只覆盖了 M/M2 段 7 处）｜`integration-wave.sh` **3**｜`publish-milbridge.sh` **1**｜`column-floor-check.sh` **1**｜`fp-inputs-hygiene-check.sh` **1**。
#     **⭐ 两处"假绿"（比假红更坏）**：`integration-wave.sh` 的「**0 错 0 警**」检查（`printf '%s' "$out" | grep -qE "error |warning "`，`$out` 是编译器输出）⇒ 伪负 = **警告静默通过**；同件两处「**空操作护栏**」（`grep -qE '未指定动作|无动作可做|nothing to do'`）⇒ 伪负 = **一个什么都没做的应用器会被报 ✅**。另有 `publish-milbridge.sh` 一处**假警**方向（明明 `APPSYNC=PASS` 却报"非 PASS"）。
#     **成对读数**：五个站点在 **216 KB 多行载荷**上 **OLD 真阳性 `wrong=40/40` → NEW `0/40`**；两种真阴性**改前改后都 `0/40`**（**不放松、不新增假红**）。整件：`check-applocal-sync.sh --selftest` **18/18 → 18/18**；`fp-inputs-hygiene-check.sh --selftest` **16/16 → 16/16**；**判定面零位移机器证** = `1..543` 与 `936..$` 行 before==after **逐字节相同**、47 处改动**全在**其 `--selftest` 分支（自 `:544` 起）内。
#     **⭐ 新牙 `build/MilBridge/tools/pipefail-sigpipe-check.sh`（第 `[17]` 步）的判据不是正则**：每个候选站点**抽进沙箱真跑**（造"左端多行 ≫ 管道缓冲、右端命中即退"的最小复现），**实测**那条管线在 `pipefail` 下真的非 0 才算 `HIT`；**抽不出来跑**的降 `DIAG`（只报量级、不进 rc）；**数据面够不着**的单列 `LOW`（可见、不入 rc）。真树读数：`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=1 files=56 sites=73 hit=1 low=10 diag=2 safe=60 runs=12`、**单趟 ≈4.8 s**、`--selftest` **15/15**（含"**单行左端 ⇒ 必不命中**"这条阴性对照）；**弄瞎 ⇒ `NOINFO reason=canary-blind`**（**不是绿**）；声明表里的例外若过期（`decl_stale`）也出声。
#     ⚠️ **一条被推翻的旧结论**：`#32` 记的"**小串安全**"**不成立** —— 实测 **1,337 B / 75 行**仍有 **2/300** 的翻转率（1.3 KB → 0.7%、119 KB → 220/300、250 KB → 300/300；**只有单行 200 KB 是 0/100**）⇒ **判据是"几次 `write()`"，不是"多少字节"**。⇒ 这也是"那条不准的推理若被写进结论，就会让后人**不去查**剩下的 57 处"的现场。
#     ⚠️ **唯一的例外留在册**：`tests/…/run-wpfprobe.sh:566`（诊断分支，车道写域外）**声明为例外**（`declared_ok=1`，且牙自带 `decl_stale` 检测）⇒ 留给 `#34`。
#   【② `D-G43`：`--selftest` 的"清单"没有权威，且**有一支自测会写真树**】**清点口径三版不一**：`grep -rln '--selftest'` 命中 **60** 个文件（其中 48 个是 `.md`/`.cs`/仅提及者）｜`#32` W32B 数 **12**｜`#33` W33B 实测 **15** ⇒ "本仓有几件实现了 `--selftest`"**没有单一权威、也没有牙**。
#     **⚠️ 更重的一条**：`build/artifact-src-fp.py --selftest` **会写"真树"** —— 它往 `upstream/wpf/**.cs` **追加一行**再 `copy2` 还原，并在 `build/*.Linux/obj|bin` 下**建/删**探针件 ⇒ 若 `SIGKILL`（或超时）落在那个窗口内，会**留下被改的真源 ＋ 一个 `.fp-selftest-bak`**。⇒ **零-`dotnet`／并发车道禁跑它**；它自己应当改成沙箱自测。
#     **本波落地的加固（11 件的 `--selftest` 段，只加在自测路径上）**：
#       · **`D-G41` 的"本件 sha 自测首尾一致"自证**：开头记本件 sha16、结尾再算一次；不等 ⇒ `ST_ATTEST=NOINFO reason=self-rewritten-during-selftest` ＋ 点名（含 `sha0`/`sha1`/`inner_rc`），**`rc=2`**（`NOINFO` 不许当绿、也**不许**冒充红）。**教科书式两极化**（在 `baseline-sha-check.sh` 上）：**旧件** ＋ 自测窗口内改写 ⇒ 输出与未扰动趟**逐字节相同**、`BSC_SELFTEST=PASS 6/6`、`rc=0`（**静默**）；**新件** ＋ **同一次**改写 ⇒ `ST_ATTEST=NOINFO … sha0=… sha1=…`、**`rc=2`**（出声且点名）。
#       · **`baseline-sha-check.sh` 的 4 处会移动的前提**（**推翻 `#32` W32B 判它"自持"的结论**）：`case E` 把"更新的世代"**写死成字面量 `#99`**、`case D` 把"不匹配的世代"写死成 `#000`；夹具 `scrub()` 的 `grep -v … > tmp && mv` 在**输入每一行都被滤掉**时 `grep` 退出 1 ⇒ `&&` 短路 ⇒ **`mv` 不执行 ⇒ 剥不干净且静默**；`$GEN` 为空时仪器前提缺失却被混进 `fail=` 计数（与真红不可分）⇒ 世代现算 ＋ 前提缺失即 `NOINFO`。
#       · **`t1b-ls-tripwire.sh`**：旧件在"真构建产物不在"时 `if [ -f "$SHIM" ]` 为假 ⇒ **两行 `nm -D` 交叉核对整段消失**，而 `:109` 照印「装置自证 **通过**（…与 **nm -D** 事实一致）」、`rc=0`。成对读数：真树 = 2 行 nm ＋ `rc=0`；同件搬进"产物不在"的沙箱 = **0 行 nm ＋ 照印"通过" ＋ `rc=0`**。⇒ 修后 `NOINFO reason=nm-crosscheck-premise-unmet` ＋ **`rc=2`**；放一个假产物 ⇒ 仍 **`rc=1`**（牙还在）。
#       · **`defect-registry-check.sh` 的"夹具/声明不同源"**：**不是**静默绿而是**假红**（旧件 ＋ 窗口内改写声明表 ⇒ `FAIL cases=10 pass=1 fail=3 noinfo=2 not-as-expected=4`、`rc=1`、reason `declared-id-missing-in-route`）⇒ 改为 `NOINFO reason=fixture-decl-not-same-source`，并**冻结同源**。
#   【③ `FrameProbe` 的 3 条结构族红：**它早已登记过**，陈旧的是 `frame-step.sh` 自己那句"未登记"】**逐条点名**（三条腿各 3 条、去重后 3 个 `id`）：`B-indent/lead-tab-b-t-c@w40@LTR@i24@tab0`、`B-indent-extra/…@i0p24@tab0`、`B-indent-extra/…@i24nl@tab0`（皆 `@tab0`、文本 `"\tb\tc"`）。**差在行#1 的 `startChar`**：我方 `cpFirst=1` vs 真机 `2`；用例级 = 我方 4 行 `[1,1,1,2]` vs 真机 2 行 `[2,3]`。
#     **⚠️ 它其实已经登记在两处**：`build/MilBridge/known-red-frame-structural.md`（`#25` W25C，2026-09-17 12:31，逐字点名这 3 条）＋ `build/MilBridge/tests/PcLineOracle/known-red.txt`（`#24`，2026-09-16 12:00，同 3 个用例 id，注 `修前: 行数 期望=2 实得=4`）；**根因也早在册 = `D-T4`**（PC 路径不携带 `DefaultIncrementalTab`）。**陈旧的是 `frame-step.sh` 的两句**（登记件比该句**早 1h37m** ⇒ **那句"未登记"诞生即假**）⇒ 本波按纪律 61 **只改字面**（判据/`rc`/既有字段零改动）：`已登记**：build/MilBridge/known-red-frame-structural.md ＋ PcLineOracle/known-red.txt；根因 D-T4（DefaultIncrementalTab 到不了工厂）；**本步不判**`。
#     **同一性判据（四条件，机器可判）**：同臂 ＋ 其 `@default` 孪生例真值行数不同 ＋ 我方两档行数相同 ＋ 错位都在 `li=1` 且 `(我方 cpFirst, 真值) = (1,2)`。**反例在场**（判据的证伪面）：同族共 **60** 条（`^FRAMEPROBE LINECOUNT`），形状分布 `(2,1)×26 (3,1)×18 (4,1)×10 **(4,2)×3** (3,2)×3` ⇒ **只有 `(4,2)` 那 3 条红**；`(3,2)` 那 3 条**同族同臂同"多分行"却不红**（真值第 1 行 `startChar` 恰等于我方 `cpFirst`）⇒ **"按名字像"归族会误并成 60 条**。
#     **成因在"我方"，且不是一个"断行算法错"**：真值 `perChar` TAB 宽度 `[DefaultIncrementalTab=0] = {0:224}`（**224/224 全 0**）vs `[=default] = {96:56, 72:34, 16:15, …}`；**配对 144、含 TAB 119、真值两档不同 `60` ／ 我方两档不同 `0`**；`60/60` 我方行数 == 其 `@default` 孪生真值行数（**同用例换 `@default`，我方与真机逐位相同**）⇒ 该维**根本没进排版**。静态链条：shim `:3959` 有 `defaultIncrementalTab = NaN`、`:2895` `NaN ⇒ 4×em`，但**严格档应用器 `:4657-4670` 没传它**；PC 两个接线点只传 `indentDip`/`paragraphIndentDip`；生成物里 `defaultIncrementalTab` **0 命中**。
#     **⭐ 本条顺带澄清 `D-T4` 的一句**：`KNOWN-DEFECTS.md` 的 `D-T4` 写「该输入下**真机行为没有真值**、需补 Windows 重录」—— **今天不成立**：`tab-anchor` 的 `tab0`/`default` **两臂齐备**且是真 Windows 录制（`os=Windows NT 10.0.22631.0`、`measurement=FormatLine 循环录制`）⇒ **`D-T4` 已有可判红的产品判据、不再需要一次 Windows 重录**。**本波不用新编号**（挂在 `D-T4` 名下；⚠️ 若将来要新立，必须同趟在声明表加行，否则规则④判 `undeclared-id-in-route`）。
#     **⚠️ 本波刻意"不修"它**（裁定留档）：修它要**翻九位**（`shim` 是九位成员）＋**改生成器**（`TextFormatterImp.Linux.cs` 是生成物、`:1` 逐字"不要手改"）＋**重取五臂** ＋ 重钉 `known-red.json` ＋ 重取 `PcLineOracle/known-red.txt` 的 `tab0` 族 **136 条**，而收益只是 3 条**结构族**红变绿（`[6]` 的判据一字不变）⇒ 它应当**独立成波**并用**可证伪方子**验证（见下）。**也不把判据扩到判结构族** —— 那会让 3 条立刻红且**使登记立即失效**（W33C 的撤登记条件⑤）；`#24` 已写死"**绝不断言 `红行 == 0`**"。
#     **可证伪方子（留给 `#34`）**：E1 复现"零响应"＋**反极性必须找到"我方两档不同"的用例**（否则该判据恒真）；E2 补接线重建后跑 `frame-step.sh` ⇒ 期望 `结构红 3→0 ∧ LINECOUNT 60→0 ∧ 结构族NOINFO 101→0` 而 `@default` 臂 **`IDENTICAL`**（能区分 `D-T4` 是唯一根因 vs 另有"断在 tab 之前/之后"的缺口）；E3 真值自洽；E4 用修前 `pc` 做反极性。
#   【④ 补上两个"未取到"的读数（`#31`/`#32` 的欠账）】
#     · **`hidden-only-step.sh --selftest` 真树一趟**（它是构建者、要拉 runner，`#32` 因此未取）：**`HIDDEN_ONLY_SELFTEST=PASS cases=16 pass=16 fail=0 skip=0`、`rc=0`、`real 5m33.395s`**。逐例要点：`S12`（真实旧产物）`expect_rc=1 got_rc=1` 且 **`S12-attrib` 目标 4 格全在红名单**（`不符=28`，脚本自注"不要求恰 4 格红"）｜`S13`（私目录放权威 `pc` 副本）`rc=0` = **装置健全性闸**｜`S14` 成对读数「原脚本 `rc=1` 真红 ｜ 放宽副本 `rc=0` **假绿**」⇒ 牙的判别力有成对证明。
#     · **`close-wave.sh` 的 `IN_FP` 窗口"成对实验"**（`#31` 记的"只有推理、没有读数"这条洞）：用**同码路径**（`source <(sed -n "/^fp_inputs()/,/^}/p" build/close-wave.sh)` ＋ `cd` 进沙箱根）在最小沙箱树上采样两次，**中间故意改一个覆盖面成员** ⇒ `IN_FP_0 = cf8135ce224cdd24…` ≠ `IN_FP_1 = d71c233d7dd6a436…` ⇒ **`close-wave.sh` 的 `[4/6]` 会 say「❌ 输入稳定性」并 `exit 5`** —— 正是它该做的；**阴性对照**（不手改）两次**逐位相同**（`bab9be7f4ba1c85c…`）。⚠️ **射程**：该实验在**最小沙箱树**上做（成员集缩小到"会被 `find` 命中的那些"），它证的是**机制的判别力**，不是"真树那 121 件件都这样"（同一函数、同一码路径 ⇒ 传递性成立）。
#   【⑤ 覆盖面与声明表】`fp_inputs()` **120 → 121**（纳入新牙）｜**声明表 77 → 79**（新登记 `D-G42`/`D-G43`；`known-red-frame-structural.md` 的身份表**重锚**：被测 `pc`、判据脚本、三份读数日志的 sha 全部更新到本世代）。
#   【⑥ 主控自纠（本波 4 处）】① 我**先派单、后写预登记**（顺序反了）—— 已在 `docs/WAVE33-PREREGISTRATION.md` 开头如实标注，`#34` 起改回"先预登记再派单"；② 我派单书里说"`check-applocal-sync.sh` **多处**"，实测是 **47 处**；③ 我派的粗扫描给的"**185 行命中**"被车道证伪为**不是**高危数（精确高危改前 **22 条**）；④ 我用 `pkill -f 'w32-mem'` 停采样器时**把承载它的 shell 一起杀了**（`pkill -f` 自匹配；本仓上一次同族现场是 `close-wave.sh` 的 `pgrep`）⇒ 已改成**按 pid 停**的脚本。
#   【⑦ 波尾与门禁】`close-wave.sh`（`--skip-verify-all`，**rc=0**）⇒ `native_rebuilt=0`、`bridge_republished=0`（两侧 `BRIDGE_SRC_FP=fdcb41bdc373eee3` 一致）、生成物指纹 `state=ok`、**应用器审计 `miss=0`**、**输入稳定性 波前==波后 == `2b6e4df8b45e5912e79b7cf5317822b0bbc0a786528f7e77e4f7e4219fdbc4e9`（期间无手写改动）**、`[0/6]` 前置检查命中 **0**；五臂 **`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=9c8feed504ec436c judge=t1b3-tline-gate/7`** ＋ **`GATE_PROBE=PASS`**（三支臂自报 `a6d0352b86467111` ＝ 现场探针源）＋ `GATE_COLUMN=PASS`（`判定行=615 红=0 绿=615 NOINFO=0 字形释放行=194`）＋ **`GATE_COLUMN_EXTRA=PASS`（三支臂，`rtl`/`zero` 两支 `judged_min=none`）**；`verify-all` **两趟各 `rc=0` / 23 步 / 871 通过 2 跳过 / `SKIP_GUARD=PASS`**（两趟结论区逐字相同，唯二差异 = 根目录那一行的时间戳与 `[0]` 步『启动 Xvfb』↔『复用已有』）；应用门禁**两趟** `RUN1_RC=0`/`RUN2_RC=0`、**各 6/6 `BASELINE … result=PASS`**（`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_BRIDGE_SRC_STALE=no`），每趟 `config=` 逐字带 `pc:b877ff3e3437145a`／`pf:445a278b4a17ba07`。
#   【⑧ 内存信封】采样器（**v2 行格式**，每 20 s 一行）；**全文件窗口** = 共 **98 样本**（15:51:38 → 16:24:00）：`MemAvailable` **谷底 1762 MB**（15:53:59）／均值 2804 MB；`SwapFree` **谷底 1728 MB / 2047 MB**（16:23:00）；`load1` 峰值 **6.37**；采样 `dotnet` 峰值 **6**；**告警 0 条**（`note=only-dotnet-count` 的 **0** 条〔**只有 `dotnet>3` 破线** —— 那是**车道纪律**的阈值，而 `verify-all` 的测试步**合法地**同时有 5–6 个 `dotnet`（test host ＋ MSBuild 节点）⇒ **不是资源事故**〕｜`swapfree<250MB` **0** 条｜`avail<1000MB` **0** 条｜其它 **0** 条）。窗口边界 = **起链 15:51:38 → 收链后 16:24:00**（采样器由主控**发波前**起、**收链后**手工停 ⇒ 这个窗口**就是本波的窗口**，不是滚动文件）。（本窗口内**没有** `swapfree=0MB`、**告警 0 条**、`avail` 谷底 1762 MB 也远高于警戒线 800 MB；⭐ **开局时 swap 是满额空闲（`swapfree=2047 MB / 2047 MB`）** —— 与 `#31`（开局 104 MB）／`#32`（开局 75 MB）形成对照：**同一个仓、同一台机，前两波开局就紧是因为前一波留下的**，本波是干净开局 ⇒ "swap 紧"这件事的**归属要看上一波**，不许当成当波的性质。）
#   【⑨ 留给 `#34`（按价值）】① ⭐ **`D-T4` 的产品侧修法**（把 `defaultIncrementalTab` 接到工厂；用本块 ③ 的 E1–E4 方子验证）—— 本波已把它从"需要一次 Windows 重录"降级成"**有现成真值可直接判红**"，这是本波最大的一笔移交；② `D-G11`（应用器生成物 ⇔ 产物的**等号读者**）；③ `tests/…/run-wpfprobe.sh:566` 那处**已声明的例外**（修掉即可让 `declared=1 → 0`）；④ **`artifact-src-fp.py --selftest` 改沙箱**（今天它会写真树）；⑤ **`--selftest` 清单的权威**（60/12/15 三个数 ⇒ 给一份机器可读的清单 ＋ 一条"清单完备"的牙）；⑥ 行名口径 `COLUMN_FLOOR_<臂>_<列>_<键>` ＋ 两支 `judged_min:null` 臂的声明行；⑦ `D-G30` 残り（`--help` 窗 ＋ 死 `-maxdepth 2` 子句）；⑧ `verify-all` 的实际执行轨迹（`VERIFYALL_STEPS_RUN=`）；⑨ `D-G26` 族化（`FrameProbe`/`PcLineOracle`/`D5CbrProbe`/`ProductEntryArm` **仍无身份**）。
#   【本波三条车道（全部零 `dotnet`）】`W33A`（`$HOME/w33a-report.md ccf5bd2d6ff12411`：那一族**全仓普查 ＋ 修 57 处** ＋ 新建牙）｜`W33B`（`$HOME/w33b-report.md`：`--selftest` 加固**落地 11 件** ＋ `D-G41` 自证 ＋ 三条同族前提加固）｜`W33C`（`$HOME/w33c-report.md a5bbe4490f1803f3`：3 条结构族红**查清**并**推翻主控前提**）。
#   **本波最值钱的三条**：① **一个"已被写进结论的不准推理"被实测推翻**（`#32` 记的"小串安全"）—— 若留着它，剩下的 57 处就不会有人去查，而其中**两处是假绿方向**（编译器警告静默通过／空转的应用器被报 ✅）；② **`--selftest` 第一次有了"我在跑的时候自己有没有被改"的自证**（`D-G41` 落地 11 件），并把三处"前提会消失却照印通过"的件修成 `NOINFO`；③ **3 条结构族红"红着但没有登记"这个判断被推翻** —— 它**早已登记在两本册子里**，陈旧的是**判据件自己那句"未登记"**（比登记件还早 1h37m 的那句）。⇒ 这三条的共同形态是：**"结论"比"读数"活得久**。
#   **"未取到"（不许当绿，逐条）**：① `integration-wave.sh`／`publish-milbridge.sh` **不能整件跑**（构建者、零-`dotnet` 车道硬约束）⇒ W33A 只给**表达式级**成对读数 ＋ `bash -n` ＋ 逐行 diff；② 3 处**小数组**站点（`integration-wave.sh` 两处 ＋ `check-applocal-sync.sh` 一处，`array-small`/`dyn_small=0/12`）按"**不扩射程**"**未改**，只列 `LOW`；③ `build/MilBridge/run.sh` 两处 `DIAG`（左端是外部命令 `python3`/`dotnet`）**只报量级**；④ `check-applocal-sync.sh --selftest` 的**偶发红**（SIGPIPE，`SELFTEST_E`/`SELFTEST_J` 各咬过一次）**已由 W33A 的 47 处修复覆盖**，但**本波没有"改后连跑 N 趟"的成对读数**（它不在 W33B 写域、W33A 又不许整件跑）；⑤ `--leg a` 未独立复算（沿用登记件边界）；⑥ `artifact-src-fp.py --selftest` 与 `hidden-only-step.sh --selftest` 的**改后**读数（前者禁跑、后者本波只取了**改前**那一趟：`cases=16 pass=16`；W33B 的 `D-G41` 自证改动**未在新一趟里复核**）。
BASELINE tier=default rep=1 config=pc:b877ff3e3437145a,bridge:d567c26f197ec1e3,pf:445a278b4a17ba07,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w33/gate2
BASELINE tier=default rep=2 config=pc:b877ff3e3437145a,bridge:d567c26f197ec1e3,pf:445a278b4a17ba07,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w33/gate2
BASELINE tier=default rep=3 config=pc:b877ff3e3437145a,bridge:d567c26f197ec1e3,pf:445a278b4a17ba07,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w33/gate2
BASELINE tier=env rep=1 config=pc:b877ff3e3437145a,bridge:d567c26f197ec1e3,pf:445a278b4a17ba07,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w33/gate2
BASELINE tier=env rep=2 config=pc:b877ff3e3437145a,bridge:d567c26f197ec1e3,pf:445a278b4a17ba07,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w33/gate2
BASELINE tier=env rep=3 config=pc:b877ff3e3437145a,bridge:d567c26f197ec1e3,pf:445a278b4a17ba07,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w33/gate2
# ⏪ **（历史，已被 `#33` 取代）**# RE-FROZEN #32 —— ✅ **当前冻结基线** —— 内容 = **① 产品侧真缺陷 `D-T2-c` 落地**（`CollectLenient` 第一次**收集 modifier 覆盖终点**并接到**每一个**调用点 ⇒ 走产品入口的 5 个 `M_modifier` 例 **18 条逐行红 → 0**）＋ **② 产品入口臂第一次接进 `verify-all`**（新第 `[16]` 步 `PRODUCT-ENTRY`，`verify-all` **21 → 22 步**）＋ **③ `D-G39` 的真因取到并修掉**（不是"并发写 route 件"，是 `defect-registry-check.sh` **自己管线里的 SIGPIPE 竞态**；`load1≈7.8` 时 **40 趟里 20 趟伪红**）＋ **④ 覆盖面补齐**（`fp_inputs()` 115 → 120：把 5 个**判据件**纳入）＋ **⑤ 对 `#31` 两处结论的更正**（`APPSYNC` 的 `OK` 63→65 逐字归因；`D-G39` 的"静树不复现"是**低负载窗口**的性质）。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行（本处照纪律 53 **不重述值**）。
#   **九位**：**只有 `pc` 与环成员 `pf` 变** —— `pc 7374308a00c55572 → b877ff3e3437145a`（4197888 B；`#31` 以来**第一次动到产品件**，因为 `D-T2-c` 的修法必须改应用器生成的 `TextFormatterImp.Linux.cs`）｜`pf f418131a53fa2951 → a1ce403a74225f10`（波尾 `[1/6] integration-wave.sh` 重编引起，与 `#26`–`#31` 同惯例）；`bridge`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` **逐位未动**；**`hbtextline` 一字节未动 = `e89fed55fd8e32bc`（290825 B，mtime `2026-09-17 00:12:06` 早于本波开工 11 小时）** ⇒ **世代绑定三项（`GEN_KEYS`）全未变** ⇒ **不重取五臂**（五臂日志逐位未变，两种聚合口径 `89cfd1fbeef3c4ab`／`c42fed87f7c1d5ed` 亦同）。`BRIDGE_SRC_FP=fdcb41bdc373eee3`（未变、**未重发** —— 本波只改 `src/WpfGfx.Linux.Native/tools/*.py`，而该覆盖面只收 `*.cs|*.csproj|*.props|*.targets|*.resx`）。
#   ⚠️ **`inputs_fp` 是设计性变更**：`46d2a2b0f510f77059051e68b49f5d3a8a52e300f9995b1df720e9e7aa013a84` → **`2b6e4df8b45e5912e79b7cf5317822b0bbc0a786528f7e77e4f7e4219fdbc4e9`**（成员 **115 → 120**）。逐笔说清是谁加的：`#28` 纳入 `tline-gate.sh`/`known-red.json`；W31C 纳入四个新核对器（110 → 114）；`#31` 主控纳入 `shell-quote-trap-check.sh`（114 → 115）；**`#32` 主控纳入五个判据件**（115 → 120）：`product-entry-step.sh`（本波**新建并接线**的第 `[16]` 步）＋ **四个此前一直没有被看着的牙** —— `defect-registry-check.sh`（本波**改了它**，见 ③）／`baseline-sha-check.sh`／`arm-log-sha-check.sh`／`build-hygiene-import-check.sh`。
#     ⚠️ 那四件属于**同一条纪律**的欠账：判据件"**改它必须看得见**"（`D-G22`/`D-G26` 同族）。⚠️ **改覆盖面里的任何一件都会移动本指纹** ⇒ 这些改动**必须安排在 `close-wave.sh` 的 `IN_FP_0` 采样之前**（波尾实测：`波前==波后 == 2b6e4df8b45e5912e79b7cf5317822b0bbc0a786528f7e77e4f7e4219fdbc4e9`，**期间无手写改动**）。
#   【外挂声明：`D-G27` 的读者 `column-floor-check.sh` 要读的 **4 类行**，本块继续钉下（值逐位与 `#31` 相同）】
#   ⚠️ **为什么每块都要重钉一遍**：该读者读的是**最新** `# RE-FROZEN` 块 ⇒ 本块一旦成为最新块，声明就必须跟着上来（否则第 `[14]` 步立刻 `NOINFO reason=declaration-gap`）。这与 `#31` 的处理**同构**。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=57d752a3981a9b91
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① `D-T2-c` 落地：`CollectLenient` 第一次**收集** modifier 覆盖终点】**缺口**（`#31` `D-G38` 定量）：走产品入口的 5 个 `M_modifier` 例 **18 条逐行红**，`w`/`witw` 我方**恒 `45.968000`**（真值 `74.573333`／`115.690000`／`156.916667`），`w80`/`w120` 还**少一整行**。**根因**：`CollectLenient` 只记 modifier **起点**，而 `:170-173` 的 out 形参表里**没有 `modifierScopeEnd`**、三个调用点也**不传** ⇒ shim 吃默认 **`-1`** ⇒ `kh = visibleLen` ⇒ 零宽跨度从真机的 **`[6,45)`** 放大到 **`[6,62)`** ⇒ 把本该可见的 `[45,62)` 也清零。
#     ⚠️ **这不是新账**：生成物自己 `:414-421` 就逐字记着「`modifierScopeEnd = -1`（"到段末"）是**已知错**的跨度，修它必须先让 `CollectLenient` 收集」—— 登记号 `D-T2-c`。本波就是去还这笔账。
#     **修法（`#32` W32A，只改应用器）**：`CollectLenient` 增 `out int modifierScopeEnd`；见到 `TextModifier` 那个 run 时按其**字符范围**记终点（重基到收集串）；**优先级** = 若后来按 R1 找到 `TextEndOfSegment`，**以它为准**（上游语义），两者都没有 ⇒ `-1`（保留"到段末"的退化）；然后把新形参接到**每一个**形参对等的调用点（**一个都不许漏** —— 漏一个站点那条路径仍错而别的路径会绿，正是"半接线能静默通过"的形态）。生成物由脚本重出，**未手改生成物**。
#     **成对读数（修前 → 修后，同一支臂、同一档位、同一字体）**：`PEA_SUM cases=8 lines_judged=133 ok=117 red=18 noinfo=0`、`rc=1` ⇒ **`cases=8 lines_judged=147 ok=147 red=0 noinfo=0`、`rc=0`**（`lines_judged` **133 → 147** 正是"`w80`/`w120` 各补回一行"的算术：8 例的判据格 = 行数 × 7）。3 个阴性对照 `F_lat_words_*` **98/98 仍全绿**；`PEA_NOMOD`（装置内诊断：同文本摘掉 modifier）**逐字节相同** ⇒ 修法**不误伤"无 modifier"路径**的机器证。修后 `w` 的 Δ = `+0.011333`（**字体 advance 取整口径的既有量级**，不是本次修法的残差）。
#     **⭐ 语义选择的依据是"真机真值自己印出来的"**：`build/MilBridge/gen/layout-b34-compact.json` 的 `M_modifier_w200.lines[0].runs` 逐字是 `[[0,6,0,45.96666666666667],[45,17,45.96666666666667,110.95000000000002]]`、`w=156.91666666666669` —— 即真机上**被 `TextModifier` 覆盖的 `[6,45)` 那 39 个字符整体 Ghost（零宽）**，可见的只有 `[0,6)` ＋ `[45,62)` 两段 ⇒ **"覆盖终点"就是该 run 的字符范围终点**，不是"到段末"、也不是"到 `TextEndOfSegment`"。（这条把"我们凭什么这么改"从**论证**变成了**读数**。）
#     **结构性断言同趟更新，逐条只加强**：`P3` 的 needle 从"min 探针传同一组两个实参"扩成"**同一组三个**实参"；`n_mod_args == 2` 的计数牙齿换到长 needle（语义不变、覆盖面变宽）；**新增 4 条 needle**（形参表有 `out int modifierScopeEnd`／站点1 传下去／站点2-3 传下去／覆盖终点取自 run 自己的字符范围）。**反极性 7 个变体全部拿到真红**（在内存里破坏应用器模板，**零构建、零写盘**），其中一条正是"**min 漏传 `modifierScopeEnd` ⇒ 当场报红**"。
#   【② 产品入口臂第一次接进 `verify-all`（新第 `[16]` 步 `PRODUCT-ENTRY`）】**为什么现在才能接**：它 `#31` 时**按设计是红的**（`D-G38`），而"在册红"机制是 `#32` 的候选之一 —— 但 ①把它修绿了，于是它**不需要**"在册红"，直接作为**普通绿步**接进来（**更硬**：没有"预期红"这层可以被放宽的东西）。
#     **新件** `build/MilBridge/tools/product-entry-step.sh`（`f28e9e7c52e0a919`）：三态自报 `PRODUCT_ENTRY_STEP=PASS|FAIL|NOINFO`；**构建 → 断言产物目录里的 `pc` 副本 == 权威 `pc`**（`D-A2` 那一族：不重编就会量到旧产物）→ 跑臂 → 判 `PEA_SUM` ＋ **逐例正控 `PEA_POSCTL`** ＋ **两条下界**（`EXPECT_CASES=8`、`EXPECT_CELLS=147`）。
#     ⚠️ **两条下界是"防恒绿"的**：例数或判据格数缩水 ⇒ `NOINFO`（**不是绿**）—— 这正是纪律 47／`#31` `D-G37` 那一族的落点。⚠️ **正控比 `rc` 更重要**：5 个 M 例必须**逐例**打 `REACHED(lenient)`（严格档在 `TextModifier` 上必 bail）⇒ 少一例就 `NOINFO`。
#     `--selftest` **12/12 就地全绿**、**零 `dotnet`**（替身 runner/build 重入本件），**前提自持**（不读冻结基线/登记表/世代号）；测试钩子 `PRODUCT_ENTRY_COPY_SHA` **只在 `SKIP_BUILD=1` 时被接受** ⇒ 生产路径**用不了它**把"副本 != 权威"洗掉。
#     ⚠️ **本步刻意没有"预期红"**：若将来它在现役树上红，正确动作是去查**产品侧那条链路**，**不是**在这里登记预期红、更不是放宽下界。
#     ⚠️ **射程**：证的是"**走产品入口那条路径**上 8 个例的逐行读数与真值一致"；**不证**"modifier 的语义在所有语料上都对"（语料只有 b34 家族的 8 例）。五臂喂**语料 meta**、**绕过 PC** ⇒ 本步与它们**互补**。
#     ⚠️ **成本**：构建 ≈1.6 s ＋ 跑 ≈13 s ⇒ **≈15 s/趟**（远小于 `hidden-only` 的 102 s）。
#     **⭐ 顺带一条现场（本波牙咬自己的第二次）**：新件第一版在三处 `chk` 说明串里把**反引号写进了双引号** ⇒ 真跑 stderr 吐 `PEA_SUM: 未找到命令` 并把说明串的字吃掉；**第 `[15]` 步的牙当场逮住**（`SHELL_QUOTE_TRAP=FAIL traps=6`，逐条点名 `product-entry-step.sh 129/132/133`）。⇒ 这是这一族的**第 7 次现场**，也是**第一次由专职牙（而不是运气）在冻之前抓住**；修后 `traps=0`、`files=129 sh=55 py=74`、该件 `--selftest` 12/12、stderr **0 行**。
#   【③ `D-G39`：真因取到并修掉 —— **不是"并发写 route 件"**，是核对器**自己管线里的 SIGPIPE 竞态**】**`#31` 登记的原话**：「`defect-registry-check.sh` 在**并发写 route 件**的窗口里会出假红；静树下 60/60 不复现，机制未取到」。**本波把它查到底并推翻了那个归因**：真因是 `printf '%s' "<多行串>" | grep -q…` 形态（4 处）—— bash 的 `printf '%s'` 对**多行串**是**每行一次 `write()`**（`strace` 实测：449 B/75 行 → **52 次** `write`）；`grep -q` 命中第一行即**退出并关闭读端** ⇒ printf 的下一次 `write()` 吃 **EPIPE→SIGPIPE** ⇒ `set -o pipefail` 把管线报成 **141（非 0）** ⇒ `||` 分支被触发 ⇒ **一个确实写在声明表里的编号被判成"未声明"**。⇒ `DEFREG=FAIL reason=undeclared-id-in-route` 是**伪红**。
#     **⚠️ `#31` 的两条结论都要更正（纪律 61「加注不覆盖」：`#31` 块原文一字未动，更正写在这里 ＋ `CURRENT-STATE` 的 ⏪ 注）**：
#       1. `#31` 写「静树 60 趟 60 绿、`--selftest` 10 趟 10 绿 ⇒ **静树不复现**」—— **那是一个低负载窗口的性质，不是该件的性质**。本波在同一台机上、`load1≈7.8` 时**独立复现 40 趟 → 20 FAIL ＋ 1 NOINFO**，点名过 **18 个编号**，逐个查过 `grep -c "^ID	<id>	"` ⇒ **全部都在声明表里**。⇒ 更正不是"数错了"，而是**归纳错了**（把一次窗口的读数当成了件的属性）。
#       2. `#31` 写「`declared` 只有 394 B（远小于 64 KB 管道缓冲）⇒ **排除** SIGPIPE」—— **推理错、结论也错**：管道缓冲大小与本案**无关**，因为 printf 不是"一次写完"，而是**每行一次 `write`**，`grep -q` 在第 1 行命中就退出、printf 还剩 50+ 次 `write()` 要发 ⇒ **423 B 的串照死**。
#       3. **再更正一处**：`#31` 把 10:05 那次瞬时 FAIL（点名 `D-G9`）归因成"某车道正在写 route 件" —— **错的**，那就是本条（当时三条车道在跑、`load1` 高）。
#     **修法（`#32` 主控，8 处）**：全部改 here-string（`grep -q… <<< "$x"`／`awk … <<< "$x"`）⇒ **零 SIGPIPE**。**成对读数**：修前同负载（`load1≈7.8`）**40 趟 → 20 FAIL ＋ 1 NOINFO**；修后同负载（`load1≈8.66`）**40 趟 → FAIL=0 NOINFO=0**。该件 `sha16` `733c04570d4602f5 → b98b7d8926b275c9`。
#     **同族前科（本仓第二次）**：`#26` W26C 在 `check-applocal-sync.sh` 的 M 段实测 **≈6.6%/趟**，同样改用 `<<<`。⇒ **新纪律 71**：**多行串不许用 `printf | grep -q`**（`grep -q`/`head -1` 的提前退出会让左端吃 SIGPIPE，而 `pipefail` 把它变成一个**判据错**；改用 here-string 或"先把内容读进变量/关联数组再判"）。⚠️ 该件自己的头注释 `:25` 原先**自称**"全程不用 `printf|grep -q` 形态" —— 那句在 `#27`–`#31` 期间是**伪证**（已按纪律 61 就地加注更正）。
#     ⚠️ **该件此前不在 `fp_inputs()` 覆盖面里**（本波同趟纳入，见上面那笔 115 → 120）—— 也就是说：**"判据件改了没人看得见"这条欠账，本波又还了一笔。**
#   【④ 对 `#31` 的一处口径更正：`APPSYNC` 的 `OK` 63 → 65】**`#31` 块 ⑨ 写「逐字计数：… **与 `#30` 逐字相同 ⇒ 本波零新增红成立**」—— 那句话**结论对、引用错**：该工具印**两行不同口径**（`计数：…` 详表 vs `APPSYNC=…（…）` 摘要），`#30` 引的是**前者**、`#31` 引的是**后者** ⇒ 「逐字相同」比较了两串**不同的东西**。**同口径逐项比**：红色计数器**逐字相同**（`MISMATCH=1（STALE=1 NEWER-DIFF=0）｜MISSING=0｜UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0]｜DIVERGENT=1｜RETIRED=0｜AUTH-MISSING=0｜BRIDGE-ANCHOR=0｜BRIDGE-NOINFO=0` ⇒ **零新增红成立**）；**`OK` 63 → 65（+2）** —— 逐字归因（机器证）：`#31` W31A 新建的臂产物目录 `build/MilBridge/tests/ProductEntryArm/bin/Debug/` 下**恰好两份**进入 `scan()` 射程且都判 `OK`（`PresentationCore.dll 7374308a00c55572`／`DirectWrite.Linux.Provider.dll 9aa0d744802aaa31`）；取证 = `grep -n ProductEntryArm <该趟输出>` ⇒ 恰好 2 行且都是 `OK`。
#   【⑤ 主控自纠（本波 4 处）】① `D-G39` 的前两条结论被推翻（见 ③，**两条都是"把窗口读数当属性"＋"排除得太快"**）；② `#31` 的 `APPSYNC` 那句引错行（见 ④）；③ 我在 12:04 读到应用器 `514e9d052a2b3326` 并据此准备写"W32A 的修前 sha 与我对不上"—— 实际是**我在车道写盘的那一瞬取数**（那份 diff 的 mtime 正是 `12:04:31`）⇒ **"在别人写盘时取到的 sha16 不是一个版本"**（`$HOME` 下 8 份历史副本一致给出真值 `64cac206bf10635f`）；④ 我先前在 `#31` 记的"静树不复现"已按纪律 61 更正。
#   【⑥ 波尾与门禁】`close-wave.sh`（`--skip-verify-all`，**rc=0**）⇒ `native_rebuilt=0`、`bridge_republished=0`（两侧 `BRIDGE_SRC_FP=fdcb41bdc373eee3` 一致）、生成物指纹 `state=ok`、**应用器审计 `miss=0`**、**输入稳定性 波前==波后 == `2b6e4df8b45e5912e79b7cf5317822b0bbc0a786528f7e77e4f7e4219fdbc4e9`（期间无手写改动）**、`[0/6]` 前置检查命中 **0**（无应用/探针在跑、无重发锁）；五臂 **`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=9c8feed504ec436c judge=t1b3-tline-gate/7`** ＋ **`GATE_PROBE=PASS`**（三支臂自报 `a6d0352b86467111` ＝ 现场探针源 ⇒ `PASS`）＋ `GATE_COLUMN=PASS`（`判定行=615 红=0 绿=615 NOINFO=0 字形释放行=194`）＋ **`GATE_COLUMN_EXTRA=PASS`（三支臂：`anchor 判定行=421 judged_min=421`；`rtl 判定行=0 judged_min=none`；`zero 判定行=0 judged_min=none`）**；`verify-all` **两趟各 `rc=0` / 22 步 / 871 通过 2 跳过 / `SKIP_GUARD=PASS`**（两趟结论区**逐字相同**，唯二差异 = 根目录那一行的时间戳与门禁 `outdir` 的时间戳）；应用门禁**两趟** `RUN1_RC=0`/`RUN2_RC=0`、**各 6/6 `BASELINE … result=PASS`**（`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_BRIDGE_SRC_STALE=no`），每趟 `config=` 逐字带 `pc:b877ff3e3437145a`／`pf:a1ce403a74225f10`。
#   【⑦ 内存信封】采样器（**v2 行格式**，每 20 s 一行）；**全文件窗口** = 共 **261 样本**（12:01:24 → 13:34:49）：`MemAvailable` **谷底 1083 MB**（12:58:32）／均值 2323 MB；`SwapFree` **谷底 70 MB / 2047 MB**（12:06:05）；`load1` 峰值 **11.62**；采样 `dotnet` 峰值 **6**；**告警 51 条**（`note=only-dotnet-count` 的 **20** 条〔**只有 `dotnet>3` 破线** —— 那是**车道纪律**的阈值，而 `verify-all` 的测试步**合法地**同时有 5–6 个 `dotnet`（test host ＋ MSBuild 节点）⇒ **不是资源事故**〕｜`swapfree<250MB` **31** 条｜`avail<1000MB` **0** 条｜其它 **0** 条）。窗口边界 = **12:01:24（采样器起 —— 在**车道阶段之前**）→ 13:34:49（收链后手工停）** ⇒ 这个窗口**覆盖了「车道阶段 ＋ 波尾链」整段**，不是滚动文件。⚠️ **一处如实标注**：原采样器设了 240 次上限，于 **13:21:15** 自行到顶；主控在 **13:28:0x** 起了一个**追加**到同一文件的采样器（日志里留了一行`# 采样器重启 …` 标记）⇒ **13:21:15–13:28:0x 之间有约 6 分钟空档**（那一段正好是 `verify-all` 第二趟中段）。⚠️ **本波 `SwapFree` 谷底 = 70 MB（12:06:05）而全程未到 0**；同一笔 `MemAvailable` 始终 ≥ 1083 MB，`avail<1000MB` 的告警 **0 条** ⇒ 与 `#30`/`#31` 两次 `swapfree=0MB` 相比，本波的资源画像更宽松。（本窗口内**没有** `swapfree=0MB`；⚠️ 但**开局时 swap 已经很紧**：第一笔 12:01:24 就只有 104 MB 空闲 —— 那是上一波留下的，不是本波造成的。）
#   【⑧ 留给 `#33`（按价值）】① **`D-G11`**（应用器生成物 ⇔ 产物 没有等号读者 ⇒ "生成物超前于产物"可以不报红）；② **行名口径** `COLUMN_FLOOR_<臂>_<列>_<键>` ＋ 两支 `judged_min:null` 臂要不要插 `# COLUMN-FLOOR … judged_min=none`（**本波仍故意不插**：`D-G19` 的裁定就是"无下限 ⇒ 刻意不声明"；插了上屏行会从 7 涨到 9，而本波 `head -8 → 12` 已留余量）；③ **`D-G30` 残り**（`--help` 窗口位移 与 那条死 `-maxdepth 2` 子句**同趟**改）；④ `verify-all` 的**实际执行轨迹**（结论区印 `VERIFYALL_STEPS_RUN=`）；⑤ `D-G26` 族化（`FrameProbe`/`PcLineOracle`/`D5CbrProbe` **仍无身份**）；⑥ **`--selftest` 前提自持的推广**（W32B 的审计表；本波只落了 `column-floor` 与新建的 `product-entry-step` 两件）；⑦ `defect-registry-check.sh` 其余**未实测**的时序窗口（`awk … exit` 的中段 `sed`）；⑧ **"多行串 `printf|grep -q`"的全仓普查**（本波只修了一件；纪律 71 立起来之后应有一次**全仓扫**，并且**那件事本身应该有一支牙**）。
#   【本波三条车道】`W32A`（`$HOME/w32a-report.md`，**构建者**：`D-T2-c` 落地 ＋ 产品入口臂由红转绿 ＋ 接线准备；只改应用器，生成物由脚本重出）｜`W32B`（`$HOME/w32b-report.md`，零 `dotnet`：`--selftest` 前提自持审计，**只给 diff 不落**）｜`W32C`（`$HOME/w32c-report.md`，零 `dotnet`：`D-G39` 机制 —— **它取到了真因，并当场推翻主控两条结论**）。
#   **本波最值钱的三条**：① **产品侧的账还了一笔**：`D-T2-c` 从"登记着、没人修"变成"修好且有牙"（5 例 18 红 → 0，阴性对照 98/98 不动，`PEA_NOMOD` 逐字节相同）；而**语义依据来自真机真值自己印出的 `runs` 数组**，不是我们的论证。② **一支牙第一次在冻之前抓住"这一族"的第 7 次现场** —— 而且是**主控自己新写的件**（`product-entry-step.sh` 的三处说明串）；③ **一个长期随机打红 `verify-all` 第 `[10]` 步的伪红被查到根并修掉**（`load1≈7.8` 时 **50%/趟**），而它此前被两次归因错（"并发写 route 件"／"静树不复现"）。
#   **"未取到"（不许当绿，逐条）**：① W32A 的 §3⑤/⑥（`verify-all` 一整趟／应用门禁一趟）在报告里**引用了尚不存在的 §7 追加区** ⇒ 以**主控波尾那两趟**为准（``verify-all` 两趟各 `rc=0` / 22 步 / 871 通过 2 跳过；应用门禁两趟各 **6/6 `result=PASS`**；五臂 `TLINE_GATE=PASS … judge=t1b3-tline-gate/7`；**本节 ①–④ 的读数与它们逐字一致**（含 `PRODUCT_ENTRY_STEP=PASS 判定例=8/8 判据格=147/147`）`）；② `D-G39` 的**其余时序窗口**（`awk … exit` 中段 `sed`）标 M、**未实测**；③ 反引号牙的 `.py` 半边只报量级（Python 不做命令替换）；④ `product-entry-step.sh` 的**生产路径**趟与 `--selftest` 的**长跑稳定性**（本波只跑了 12/12 一次 ＋ 波尾那一趟）；⑤ `frame-step.sh` 的 3 条**结构族红**仍是红（`known-red-frame-structural` 的登记决定，**本步不判**）。
BASELINE tier=default rep=1 config=pc:b877ff3e3437145a,bridge:d567c26f197ec1e3,pf:a1ce403a74225f10,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w32/gate2
BASELINE tier=default rep=2 config=pc:b877ff3e3437145a,bridge:d567c26f197ec1e3,pf:a1ce403a74225f10,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w32/gate2
BASELINE tier=default rep=3 config=pc:b877ff3e3437145a,bridge:d567c26f197ec1e3,pf:a1ce403a74225f10,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w32/gate2
BASELINE tier=env rep=1 config=pc:b877ff3e3437145a,bridge:d567c26f197ec1e3,pf:a1ce403a74225f10,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w32/gate2
BASELINE tier=env rep=2 config=pc:b877ff3e3437145a,bridge:d567c26f197ec1e3,pf:a1ce403a74225f10,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w32/gate2
BASELINE tier=env rep=3 config=pc:b877ff3e3437145a,bridge:d567c26f197ec1e3,pf:a1ce403a74225f10,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w32/gate2
# ⏪ **（历史，已被 `#32` 取代）**# RE-FROZEN #31 —— ✅ **当前冻结基线** —— 内容 = **① 三件「牙已备、无人跑」的件第一次接线**（新第 `[13]` 步 `HIDDEN-ONLY`（`D-T5-R` 的 32 格对照；**构建者**）／第 `[14]` 步 `COLUMN-FLOOR`（`D-G27` 的外挂读者）／第 `[15]` 步 `QUOTE-TRAP`（双引号里的反引号 = 命令替换），`verify-all` **18 → 21 步**）＋ **② `D-G27`/`D-G9` 的 4 类外挂声明行补齐**（`#30` 块自己留白的那 4 类，本块把它们钉住）＋ **③ 走产品入口的臂第一次量到产品侧真缺陷**（`D-G38`：5 个 `M_modifier` 例宽度少 `110.948667` DIP，根因 = `modifierScopeEnd` 未接线；臂**已建、未接线**）＋ **④ 反引号陷阱这一族第一次有牙，且上线即咬出 12 条真陷阱与检查器自身 3 处失明**（`D-G35`/`D-G36`）＋ **⑤ 仪器自身的回归第一次被自己的牙咬住**（`D-G37`：`column-floor --selftest` 被 `judged_min:null` 扩臂打穿 `18/18 → 11/18` 而无人察觉 ⇒ 修后 **26/26**；`D-G39`：`defect-registry-check` 在并发窗口里的假红，静树 60/60 不复现）。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行（本处照纪律 53 **不重述值**）。
#   **九位**：**只有环成员 `pf f418131a53fa2951`（7122432 B）变**（`51e987d58da11654 → f418131a53fa2951`，波尾 `[1/6] integration-wave.sh` 重编引起）；`bridge`/`pc`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` **逐位未动**；**`hbtextline` 一字节未动 = `e89fed55fd8e32bc`（290825 B）** ⇒ **世代绑定三项全未变** ⇒ **不重取五臂**（本波**没有**动 `pc`/shim/探针 ⇒ 臂日志（`89cfd1fbeef3c4ab`／`c42fed87f7c1d5ed` 两种口径）**逐位未变**）。`BRIDGE_SRC_FP=fdcb41bdc373eee3`（未变，未重发 —— 本波改的全是 `.sh`/`.json`/`.md`，而该覆盖面只收 `*.cs|*.csproj|*.props|*.targets|*.resx`）。
#   ⚠️ **`inputs_fp` 是设计性变更**：`98f600e5f44797b4ce0ef90f745fb5501d8adfa2b2afc66747128c7a0072c484` → **`46d2a2b0f510f77059051e68b49f5d3a8a52e300f9995b1df720e9e7aa013a84`**（成员 **110 → 115**：`#31` 三次纳入判据件 —— 先说清楚**每一步是谁加的**：`#28` 纳入 `tline-gate.sh`/`known-red.json`；W31C 纳入 `verify-all-step-check.sh`/`fp-inputs-hygiene-check.sh`/`column-floor-check.sh`/`hidden-only-step.sh`（110 → 114）；主控**同趟**把新接线的第 4 个读者 `shell-quote-trap-check.sh` 一并纳入（114 → 115）。⚠️ **改覆盖面里的任何一件都会移动本指纹** ⇒ 这些改动**必须安排在 `close-wave.sh` 的 `IN_FP_0` 采样之前**（波尾那趟实测：`波前==波后 == 46d2a2b0f510f77059051e68b49f5d3a8a52e300f9995b1df720e9e7aa013a84`，**期间无手写改动**）。
#   ⏪ **一条本波更正的口径（纪律 61「加注不覆盖」）**：本块之前的注释曾写「`IN_FP_0`/`IN_FP_1` **两次采样都在波尾**」—— **与代码不符**：`IN_FP_0` 在 `[0/6]` 之后、`[1/6]` **之前**（`close-wave.sh:202`，屏上自印「**波前**输入指纹」），`IN_FP_1` 才在 `[4/6]`（`:276`）。⇒ 两次采样**分居波首与波尾**。**结论不变、推理必须换**：窗口夹住的只有 `[1/6]` 那一趟（它只应用补丁 ＋ 构建，对逐字节不变的生成物无差异）；而**人手在 `close-wave` 之前**改的覆盖面成员，**两次采样都吃改后的值** ⇒ 稳定。真正会被这条断言抓住的，恰恰是「`IN_FP_0` 与 `IN_FP_1` 之间有人手改」—— 那**正是它该抓的**。
#   【外挂声明：`D-G27` 的读者 `column-floor-check.sh` 要读的 **4 类行**，本块**全部钉下**】⭐ 这就是本波「**声明与判据同趟**」那一条纪律的落地：`#30` 块**刻意留白**（它只写了 2 行 `# COLUMN-FLOOR`，并在散文里说"本波刻意不写"），`#31` 把**缺的第 ③⑤ 两类补齐**、并**同趟接线**第 `[14]` 步。
#   ⚠️ **`#30` 那处散文与现场当时就已分叉**（本波新立的**纪律 70**）：散文说"4 类行**本波刻意不写**"，而**紧接着下面两行就是那 4 类里的 2 类**，而且是**行首落地、真件真读**的活声明（`column-floor-check.sh` 当场读出 `frozen=615/421`）。⇒ 本块按纪律 61 **只追加**：`#30` 原文一字未动，更正只出现在这里。
#   ⚠️ **为什么补行必须与接线同趟**（本波实测的成对读数）：**补行前** = 3 行 `PASS` ＋ `COLUMN_FLOOR_CORPUS=NOINFO … decl=<缺>` ＋ 总判 `NOINFO`/`rc=2`（⇒ 会**挡住** `verify-all` 全绿）；**补行后** = 全 `PASS`（含 `COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无`）、`rc=0`。
#   ⚠️ **`# ARM-LOG-SHA` 这 5 行治什么**：`generation.arm_logs` **也是"自己声明自己"**（`D-G9` 残差）——`#30` 实测「失真臂日志 ＋ 同趟把 `arm_logs` 也改掉 ⇒ `ARMLOG_SHA=PASS pass=5 fail=0`」。有了这 5 行，"同趟改 `arm_logs` 洗绿"会撞上一份**在别的文件里的**声明。值 = 现盘 5 件臂日志 `sha256sum | head -c16`（与 `generation.arm_logs` 前 16 位逐位相同；**唯一 64 位全值仍只声明在 `known-red.json`**，本处不重抄全值）。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=57d752a3981a9b91
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   【① 三件「牙已备、无人跑」第一次接线 ⇒ `verify-all` 18 → 21 步】三件的**成色**各不相同，逐条写清：
#     · **`[13] HIDDEN-ONLY`**（`D-T5-R` 的牙；`#28` 交付、`#30` 修两处、`#31` 首次接线）：8 用例 × 2 档 × 2 模式 = **32 格**逐格与预期判词表比对；本波实测 **`HIDDEN_ONLY_STEP=PASS 判定例=32/32`**，`hiddenonly` 四格 `GREEN` **且兜底分支被走到**（兜底计数 `0→1` 的**机制证**），`declaredgap` 四格 `RED-LENGTH`（证明 `A3` 码元账守恒**不是空断言**）。⚠️ 它**是构建者**（实测 ≈ +102 s／趟、35 次 `dotnet`／趟）⇒ 位置放在 `[12]` 之后。⚠️ **射程边界**：`A1/A2/A3` 三条腿**从不读任何几何** ⇒ 本步的绿 **≠**「隐形语义已正确」。
#     · **`[14] COLUMN-FLOOR`**（`D-G27` 的外挂读者；`#30` 交付、`#31` 首次接线）：对冻结块声明的**每一个** (臂,列,键) 三元组判 ①登记表⇔本块 ②本块 ≥ **语料复算**下界 ③语料整份 sha ④门禁自报值⇔本块 ⑤`arm_logs`⇔本块。本波实测 **`COLUMN_FLOOR=PASS … pass=3 fail=0 noinfo=0 selfreport=PASS`**，5 条 `# ARM-LOG-SHA` 逐条 `OK`。**只有 ②（语料复算）回答"这个数该是多少"** —— ①④⑤ 都是"两处声明互证"。
#     · **`[15] QUOTE-TRAP`**（`#31` 新建并接线）：本波实测 **`SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=128 sh=54 py=74 diag=60 allow=0`**。⚠️ **它上线第一趟就是红的**（`traps=18`），见 `D-G36` —— **那 18 条是它的假阳性**，不是被测件的缺陷。
#   【② `D-G35`：反引号陷阱这一族第一次有牙】**缺口**：`echo "… `词` …"` 里的反引号**是命令替换**（不是引号）⇒ 那段被当命令跑，**跑不出来就把字吃掉**并往 stderr 吐「未找到命令」。**这一族在本仓至少发生过 6 次**（`run-wpfprobe.sh:659`、W28F、`#30` 主控自己在第 `[12]` 步的 `echo`、W30C、以及本波一次咬出的 12 条），而**前四次里只有一次**被别的牙偶然抓到（W29F 的 `noise=` 断言）。**为什么长期没人管**：**`bash -n` 对它一律静默通过** ⇒ "能不能编过"**不是判据**；唯一能判的办法是**把那一行原样抽出来真跑**。**本波 12 条逐条实证（0 误报）**：`run-df1-criteria.sh:102`（stdout 丢 `#` 两字、rc 仍 0，2 条）｜`seg-instrument.sh:164`（丢字 ＋ stderr **3 条**「没有那个文件或目录／`smaps`: 未找到命令／`Rss:`: 未找到命令」，6 条）｜`seg-instrument.sh:165`（2 条）｜`run-wpfprobe.sh:948`（**旧账：任务书只提 `:659`，同一文件 `:948` 还有一处，此前没有任何牙抓到**，2 条）。**修法**：12 条当场改掉（3 文件 4 行）＋ 新建牙并接线 ＋ **同趟**把它纳入 `fp_inputs()`。
#   【③ `D-G36`：反引号检查器自身三处失明（两颗假红、一颗恒绿真洞）】**①假红 18 条**：`column-floor-check.sh:201-203` 是**一个 `<<'PYEOF'` heredoc 体内的 Python 注释**（单引号定界 ⇒ 反引号是**字面文本**），而旧件在 `js="$(python3 - "$reg" <<'PYEOF' 2>/dev/null` 这种**行内引号数为奇数**的形态上误判"处于双引号内" ⇒ **不把 `<<'PYEOF'` 当 heredoc**。**主控独立实证**：把那三行抽进沙箱真跑 ⇒ `python3` **原样收到**反引号、stdout 正确、stderr **0 行**。**②盲区 201 行**：旧件读到 `build-hygiene-import-check.sh:307`（该行引号数为**偶数** 4，**同样**把状态机带偏）之后 **`:308-508` 整整 201 行卡在单引号态** ⇒ 整片不判（实证：往 `:400` 种真陷阱 ⇒ **旧件命中 0、新件命中 2**）。**③恒绿的真洞**：**无引号定界的 heredoc**（`<<EOF`）其体**会**做替换，而旧件对它**只发 `DIAG`、不进 `rc`**（真跑证据：体里的 `` `date` `` 被替换成**真实日期**）⇒ 升为 `HIT kind=HEREDOC-BACKTICK` 并进 `rc`。**修法**：重写状态机（`nest/stack` → **引号态感知帧栈**）而非打补丁（根因不是"奇偶"而是"`$( … )` 内的引号**泄漏到外面**"）；金丝雀 10 → **20** 行且**两类判据分别比**；`--selftest` 22 → **30** 例（**只加强**）。**量化机器证**：非 `N` 态行首数 **473 → 96**（19 → 13 文件）、**`新>旧` 的文件数 = 0**。**边界**：定界符**带空格**的 `<< EOF` 仍不识别 ⇒ 失败方向是**假红不是假绿**；普通 `( )` 配对是**近似**。
#   【④ `D-G37`：「牙已备、无人跑」的第三例 —— 自测回归无人察觉】**现象**：`#30` 声称 `--selftest` **18/18**；W31B 按 `D-G30` 把两支 `judged_min:null` 臂写进登记表后，**同一支不改一字的检查器**当场变成 **`cases=18 pass=11 fail=7`**，而它**当时尚未接线 ⇒ 没有任何东西会响**。**归因（单变量实验）**：沙箱里**只把两支 `null` 臂拿掉** ⇒ 当场回 **`18/18`**（⇒ **是 W31B 的改动引入的回归**，不是"18/18 从来是假的"）。**根因三条**：生成器对 JSON `null` 直接 `%s` ⇒ 印出 Python 的 `None`；判据里 **"显式 `null`" 与 "键缺" 共用同一个哨兵字面量 `"None"`** ⇒ **三态塌成两态**；第 ④ 段自报核对**按列取行 ＋ 贪婪 `sed`**，而门禁的 `GATE_COLUMN_EXTRA=` **一行塞 3 支臂** ⇒ 拿**别的臂**的值来比。**修法（生成器 ＋ 解析器两侧，只加强）**：三态显式化（整数／显式 `null` ⇒ `none`／键缺 ⇒ 故障）；例数 **18 → 26**；真树读数**逐字节不变**。**本条的第二个现场**：主控插 4 类声明行后，旧件又多出**两例前提死**（`N1` 的前提是"冻结构**没有** `# COLUMN-CORPUS` 行"、`G3b` 的前提是"冻结构**没有**那 5 行 `# ARM-LOG-SHA`"）⇒ **7 红变 9 红**；修法 = **前提自持**（夹具改用"裸基线"），**期望值一字未改**。
#   【⑤ `D-G38`：走产品入口的臂第一次量到产品侧真缺陷】**臂** = `build/MilBridge/tests/ProductEntryArm/`（`TextFormatter.Create()` ＋ `FormatLine`，**真走产品入口**）。读数：`PEA_SUM cases=8 lines_judged=133 ok=117 red=18 noinfo=0`、`rc=1`；3 个阴性对照 **98/98 全绿**（最大 |Δ| = `0.022667` DIP ⇒ 红的 |Δ| **是绿的 5000 倍** ⇒ 红不是装置噪声；主控**独立重跑**输出与车道那趟 `cmp` **IDENTICAL**）。**真红**：`w`/`witw` 我方**恒 `45.968000`**，真值 `74.573333`／`115.690000`／`156.916667`（`|Δ| = 28.605 ~ 110.949`），另加 `len`/`nl`/`lbNull` 与 `w80`/`w120` 的**整行缺失**。**根因**：`CollectLenient:226` 只记 modifier **起点**，`:170-173` 的 out 形参表**没有 `modifierScopeEnd`**、`:342-345` 调用点**不传** ⇒ shim `:3974` 吃默认 **`-1`** ⇒ `:2913-2922` 的 `kh = visibleLen = 62` ⇒ 零宽跨度 **`[6,62)`**（真机语义 **`[6,45)`**）⇒ 把本该可见的 `[45,62)` 也清零。**⭐ 本条顺带推翻一条已登记的归因**：`#30`/纪律 67 那句"那 5 条 **Extent** 余差与 modifier 跨度同根" —— 端到端逐例实测 **`ext` 我方 == 真值 == `18.000000`（5/5 OK）**，而 `18.080000` 出现在**阴性对照**上、**那正是它的真值** ⇒ 所谓 `0.08` 的差是**两个不同语料的真值相减**。⇒ 纪律 67 已按纪律 61 加 ⏪ 注（原文一字未动）。**它不接线**（按设计是红的；接线需要"**在册红**"声明机制）⇒ `#32` 头号。
#   【⑥ `D-G39`：`defect-registry-check` 在并发窗口里的假红】**症状（车道实测）**：同一棵树上连跑 3 次，`DEFREG_ROUTES` 的 4 个 sha16 **逐位相同**，判决却是 `FAIL(D-G12)`／`FAIL(D-E1)`／`PASS`；10 次里 9 绿 1 红（红的那次点名 `D-G27`）—— 被点名的 5 个编号**全部在声明表里** ⇒ 那些指控是**伪的**。**主控独立复核（收窄射程的三条机器证）**：**静树下 60 趟 `rc=0`/60**、`--selftest` **10 趟 10 绿**｜`declared` 只有 **394 B**（远小于管道缓冲 ⇒ **排除 SIGPIPE 假设**）｜声明表 70 行**全部是 4 个真 TAB 字段**（**排除"分隔符混用"假设**）。⇒ 症状**只在并发写 route 件的窗口里**出现，**静树不复现**，**机制未取到**（如实标）。**纪律落点**：`verify-all` 的**正确运行前提本来就是静树**；本条**不许**用"把第 ④ 条判据改弱"来治。
#   【⑦ 主控自纠（本波 6 处，全部留档）】① **我在 `#30` 块与 `CURRENT-STATE` 里写的"那 5 条 Extent 余差同根"被端到端实测推翻** ⇒ 已加 ⏪ 注（见 ⑤）；② 第 `[9]` 步 echo 里的"**40 份 csproj**"是陈旧口径（roster `wired` 已 41、`EXPECT_N=41`）⇒ 更正为 **41**；③ `CURRENT-STATE` 顶部"最新冻结（现在 **`#24`**）"早已陈旧（跨了 6 代）⇒ 更正；④ **我派单书里写死"真树读数应为 `NOINFO rc=2`"，而我自己在 09:58 已把声明行插上** ⇒ 车道当场点出"派单书过期" ⇒ **纪律：派单书里凡是"现场读数应为 X"的句子必须带取样时刻**；⑤ **我先前把 `ps -eo pid,args | grep -c dotnet` 当进程数判据** ⇒ 现场复现 `pgrep -c -x dotnet = 0` 而它报 **4**（多出的全是**承载这次测量的那个 `bash -c` 自己**）⇒ 立**纪律 69**；⑥ 我把 `CURRENT-STATE` 里一处"最新冻结"改成 `#30` 时**没有同趟改成 `#31`**（因为当时 `#31` 块还不存在）⇒ 在本块落地时一并改（**这类"中间态文档"是本波自己造出来的，如实记**）。
#   【⑧ 波尾与门禁】`close-wave.sh`（`--skip-verify-all`，**rc=0**）⇒ `native_rebuilt=0`、`bridge_republished=0`（两侧 `BRIDGE_SRC_FP=fdcb41bdc373eee3` 一致）、生成物指纹 `state=ok`、**应用器审计 `miss=0`**、**输入稳定性 波前==波后 == `46d2a2b0f510f77059051e68b49f5d3a8a52e300f9995b1df720e9e7aa013a84`（期间无手写改动）**、`[0/6]` 前置检查命中 **0**（无应用/探针在跑、无重发锁）；五臂 **`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=9c8feed504ec436c judge=t1b3-tline-gate/7`** ＋ **`GATE_PROBE=PASS`**（三支臂自报 `a6d0352b86467111` ＝ 现场探针源 ⇒ `PASS`）＋ `GATE_COLUMN=PASS`（`判定行=615 红=0 绿=615 NOINFO=0 字形释放行=194`）＋ **`GATE_COLUMN_EXTRA=PASS`（三支臂：`anchor 判定行=421 judged_min=421`；`rtl 判定行=0 judged_min=none`；`zero 判定行=0 judged_min=none`）**；`verify-all` **两趟各 `rc=0` / 21 步 / 871 通过 2 跳过 / `SKIP_GUARD=PASS`**（两趟结论区**逐字相同**，唯二差异是 `[0]` 步"启动 Xvfb"↔"复用已有"与门禁 `outdir` 的时间戳）；应用门禁**两趟** `RUN1_RC=0`/`RUN2_RC=0`、**各 6/6 `BASELINE … result=PASS`**（`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_BRIDGE_SRC_STALE=no`）。
#   【⑨ `APPSYNC`（校验器全量，**静树**）】`APPSYNC=MISMATCH`、**`rc=1`**，逐字计数：`MISMATCH=1[STALE=1 NEWER-DIFF=0] MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0] DIVERGENT=1 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`。**与 `#30` 逐字相同 ⇒ "本波零新增红"成立**（`APPSYNC` 是**告警不是硬闸**；⚠️ 上一版记录里那串"OK=63 MISMATCH=1 …"是**另一套计数器**的口径，本处按本工具自己的汇总行**逐字**抄，不混用）。
#   【⑩ 内存信封】采样器（**v1 行格式**）每 20 s 一行；**该文件的全文件窗口** = 共 **106 样本**（11:21:22 → 11:56:25）：`MemAvailable` **谷底 1082 MB**（11:24:03）／均值 2348 MB；`SwapFree` **谷底 0 MB**（11:54:45）；`load1` 峰值 **6.98**；采样 `dotnet` 峰值 **6**；**告警 16 条**（`dotnet>3` **10** 条〔车道阈值的口径问题〕｜`swapfree<250MB` **6** 条｜`avail<1000MB` **0** 条）。窗口边界 = **起链 11:21:22 → 收链后 11:56:25**（⚠️ 采样器由主控在**发波前**起、**收链后**手工停 ⇒ 这个窗口**就是本波的窗口**，不是滚动文件）。⚠️ **`swapfree=0MB` 的样本：11:54:45、11:55:05、11:55:25、11:55:45、11:56:05（共 5 个）**。
#     ⚠️ **本波的采样器用的是 v1 行格式**（`HH:MM:SS avail=…MB swapfree=…MB load1=… dotnet=N`，**没有** `total=` 与 `swapfree` 的分子/分母两个字段）—— 与 `w30-fill.py` 期望的 v2 行格式**不同**。**如实标出**，免得后人按 v2 正则解析本段时误判"采样器坏了"。
#     ⚠️ **告警 16 条，要分两类读**：**10 条是 `dotnet>3`**（采样器沿用**车道纪律**的阈值；而 `verify-all` 的测试步**合法地**同时有 5–6 个 `dotnet`（test host ＋ MSBuild 节点）⇒ 那 10 条是**阈值口径不适配**，不是资源事故）；**6 条是 `swapfree` 破线**（见下）。
#     ⚠️ **第二次 `swapfree=0MB` 现场（与 `#30` 同族，但这次更干净）**：`11:53:25 swapfree=337MB` → `11:54:05 292MB` → **`11:54:45 0MB`**，连续 **5 个样本（100 s）为 0**，`11:56:25` 回到 `6MB`；**而同一笔 `MemAvailable` = 3587~3932 MB（看着完全健康）**、`load1` 只有 1.4~1.9、`dotnet` 只有 1。⇒ **预警必须看 `swapfree`，不能看 `avail`** 这条纪律**第二次被现场证实**；⚠️ 触发时机是**应用门禁**（在画窗口/截图），**不是**构建期 —— 这一条是 `#30` 那次没看出来的（那次只有"avail 健康"这一个对照）。
#   【⑪ 留给 `#32`（按价值）】① **产品侧**：给「产品入口臂」一套"**在册红**"声明机制（像第 `[4]` 步五臂那样登记**期望红的坐标与条数**）＋ 修 `modifierScopeEnd`（方案 A：`CollectLenient` 补 `out` 形参 ＋ 调用点传参 ⇒ 动 `pc`；方案 B：shim 侧墨迹并集 ⇒ 动 `instr_shim`）—— 两者都会动九位，**必须独立成波**；② **行名口径**：`COLUMN_FLOOR_OVERFLOWED_JUDGED_MIN=` 三支臂**前缀逐字相同**（与文件头"前缀唯一 ⇒ 抽取无歧义"冲突）⇒ 改 `COLUMN_FLOOR_<臂>_<列>_<键>`，与"要不要给两支 `judged_min:null` 臂插 `# COLUMN-FLOOR … judged_min=none` 行"**同趟**（**本波故意不插**：`D-G19` 的裁定就是"无下限 ⇒ 刻意不声明"；且插了会把上屏行从 7 涨到 9 —— 本波已把 `run_step` 的行窗 `head -8` 放宽到 **12**，正是为此留余量）；③ **`defect-registry-check` 并发假红的机制**（`DRC_*` 覆盖 ＋ 写者线程复现）；④ `D-G30` 残り（`--help` 窗口位移与那条死 `-maxdepth 2` 子句**同趟**改）；⑤ `D-G11`（产物↔生成物等号读者）；⑥ `verify-all` 的实际执行轨迹（`VERIFYALL_STEPS_RUN=`）；⑦ `D-G26` 族化（`FrameProbe`/`PcLineOracle`/`D5CbrProbe` 仍无身份）；⑧ `--selftest` 的"前提自持"推广到其余自测件（本波只做了 `column-floor` 一件）。
#   【本波四条车道（除 W31A 外全部零 `dotnet`）】`W31A`（`$HOME/w31a-report.md`，**构建者**：产品入口臂 `ProductEntryArm` ＋ 5 个 M 例的定量归因 ＋ 98/98 阴性对照）｜`W31B`（`$HOME/w31b-report.md`，`D-G30` 第三格：`COL2_ARM` 扩到三支臂 ＋ 显式 `judged_min:null` ＋ `判定行 == 红 + 绿` 等式牙 ＋ `judge=` `/6 → /7`）｜`W31C`（`$HOME/w31c-report.md c10278aea28e4b7c`：反引号检查器 ＋ `arms23` 改真副本（清 11 条硬链接别名，**真件逐位零位移**）＋ `fp_inputs()` 纳入 4 个新读者）｜`W31D`（`$HOME/w31d-report.md`：把 `column-floor --selftest` 从 `11/18` 修回 **`26/26`**，三态语义，**只加强**）｜`W31E`（`$HOME/w31e-report.md 19f27b0294a395`：`retake-arms-w23.sh` 硬链接守卫 ＋ `known-red.json` 七处「加注不覆盖」）｜`W31F`（`$HOME/w31f-report.md`：反引号检查器三处失明，`--selftest` 22 → **30**）—— **共六条车道**。
#   **本波最值钱的四条**：① **"牙已备、无人跑"这一族一次清掉三件**（`hidden-only`/`column-floor`/`quote-trap` 全部接线），而**接线第一趟就分别证明了三件事**：`hidden-only` 是绿的（可接）、`column-floor` 是绿的（声明行补齐后）、`quote-trap` 是**红的**（上线即咬出 18 条命中 —— 其中 **12 条真陷阱**是本波自己修的，**6 条是它自己的假阳性**，见 ②）；② **`#31` 反引号牙上线**：同一趟里先咬出 12 条**真陷阱**（含一处**旧账** `run-wpfprobe.sh:948`），再被金丝雀咬出**检查器自身的 3 处失明**（两颗假红 ＋ 1 处**恒绿的真洞**：无引号 heredoc 体内的反引号**真的会替换**）⇒ **"新牙上线"的第一次读数同时是"新牙自己的错"**，这正是把仪器也纳入射程的价值；③ **"没有一支臂走产品入口"的代价第一次被量到**（`D-G38`：宽度少 `110.948667` DIP、5 例 18 条红、阴性对照全绿），且**顺带推翻了一条已登记的归因**（`Extent` vs 宽度）；④ **自测回归无人察觉**（`D-G37`：`18/18 → 11/18` 而没有任何门会响）—— 与纪律 68 同族，本波**第二次**现场。
#   **主控自纠（本波 6 处）**：见冻结块 ⑦（Extent 归因／`[9]` 的"40 份"／`CURRENT-STATE` 的"#24"／派单书写死现场读数／`ps|grep` 数进程／"中间态文档"未同趟改）。
#   **"未取到"（不许当绿，逐条）**：① `hidden-only-step.sh` 的 `--selftest` 12 例**本波未在真树上重跑**（只跑了生产路径 32 格 —— 它是构建者，11 例要 `dotnet`）⇒ **该件的自测绿是 `#30` 的读数，不是本波的**；② 产品入口臂**未接线**（按设计是红的）⇒ 它在 `verify-all` 里的端到端读数**不存在**；③ `defect-registry-check` 并发假红的**机制**（只取到症状与"静树 60/60 不复现"）；④ `retake-arms-w23.sh` 守卫之后那 51 行"仍能跑通"**没有证据**（只能证守卫块语法/语义正确、且在写入前 `exit 4`）—— 真跑它正是要禁止的动作；⑤ 反引号牙的 `.py` 半边只报**量级**（Python 不做命令替换）；⑥ `close-wave.sh` 的 `IN_FP` 采样窗口"夹住的只有 `[1/6]`"是**读源码 ＋ 一次实测**（两次采样同值）得出的，**没有**做过"故意在窗口中间改一个覆盖面成员 ⇒ 必红"的成对实验。
BASELINE tier=default rep=1 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:f418131a53fa2951,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w31/gate2
BASELINE tier=default rep=2 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:f418131a53fa2951,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w31/gate2
BASELINE tier=default rep=3 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:f418131a53fa2951,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w31/gate2
BASELINE tier=env rep=1 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:f418131a53fa2951,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w31/gate2
BASELINE tier=env rep=2 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:f418131a53fa2951,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w31/gate2
BASELINE tier=env rep=3 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:f418131a53fa2951,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w31/gate2
# ⏪ **（历史，已被 `#31` 取代）**# RE-FROZEN #30 —— ✅ **当前冻结基线** —— 内容 = **① `D-G26`：探针自报身份 ＋ 门禁 `probe` 段（＋按纪律 59 重取三支 `tab-*` 臂）** ＋ **② `D-G27`：列级下限的「外挂读者」（`column-floor-check.sh`，本块同时钉下它要读的声明）** ＋ **③ `D-G33`：构建卫生见证由「判产物」改成「判结构」** ＋ **④ `D-G34`：`close-wave.sh` 的 `pgrep` 自匹配** ＋ **⑤ `D-T5-R` 的牙修两处（归因升级成判据）** ＋ **⑥ 登记 `D-G26`–`D-G34` 与纪律 63–68**（预登记 `docs/WAVE30-PREREGISTRATION.md` §8）。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行（本处照纪律 53 **不重述值**）。
#   **九位**：**只有环成员 `pf 51e987d58da11654`（7122432 B）变**（`a91e564da4d4f2cb → 51e987d58da11654`，波尾 `integration-wave.sh` 重编引起）；`bridge`/`pc`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` **逐位未动**；**`hbtextline` 一字节未动 = `e89fed55fd8e32bc`（290825 B）** ⇒ **世代绑定三项全未变** ⇒ **不重取五臂**（⚠️ 但本波**按 `D-G26` 的需要重取了三支 `tab-*` 臂**，那是**为让日志带上探针身份行**，不是世代前进）。`BRIDGE_SRC_FP=fdcb41bdc373eee3`（未变，未重发）。
#   【外挂声明：**本波不写进本块，留给 `#31` 与接线同趟落**】`D-G27` 的读者 `column-floor-check.sh` 要读 4 类行
#   （`# COLUMN-FLOOR arm=tab-oracle-anchor col=START judged_min=615 released_min=194`／`col=OVERFLOWED judged_min=421`／
#   `# COLUMN-CORPUS file=… sha16=0cebc0afd5142fbf`／5 行 `# ARM-LOG-SHA arm=… sha16=…`）。⚠️ **本波刻意不写**：
#   ① 那 4 类行**必须与它自己的接线同趟**（单插 ⇒ `[7] BASELINE-SHA` 直接红）；② 它今天**尚未接线** ⇒ 写了也无人读，
#   反而把"声明先行、判据后到"的空窗留在块里。**值已实测**：两颗下限与 `#29` **逐位相同**（重取三支臂后重算亦同），
#   语料 sha16 = `0cebc0afd5142fbf`。⇒ `#31` 接线 `[14]` 时把这几行与新的 `judge=` 版本同趟写入即可。
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
#   【⭐ `#31` 主控：**接线同趟**补上第 ③⑤ 两类行（`D-G27` 的读者 `column-floor-check.sh` 于 `#31`
#      首次接线 = `verify-all.sh` 第 `[14]` 步）】下面是**追加**，本块上面的叙述**一字未动**。
#   ⚠️ 顺带如实记一条：上面那句散文写「本波（`#30`）刻意不写」这 4 类行，而紧接着的 **2 行
#      `# COLUMN-FLOOR` 实际上当时已经写了**（`column-floor-check.sh` 读到的 `frozen=615/421` 就是它们）
#      ⇒ 散文与现场**当时就已经分叉**；`#31` 把缺的两类补齐后，**4 类全部到位、分叉消除**
#      （这正是本块自己那句「`#31` 接线 `[14]` 时把这几行与新的 `judge=` 版本同趟写入即可」的落地）。
#   ⚠️ **为什么必须与本步接线同趟**：只插声明不接线 ⇒ 无人读（"声明先行、判据后到"的空窗）；
#      只接线不插声明 ⇒ 第 `[14]` 步 `COLUMN_FLOOR=NOINFO reason=declaration-gap-or-raised-awaiting-refreeze`。
#      （`#31` 实测：补行前 = 3 行 `PASS` ＋ `COLUMN_FLOOR_CORPUS=NOINFO … decl=<缺>` ＋ 总判 `NOINFO`/`rc=2`；
#        补行后 = 全 `PASS` 且 `COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5`、`rc=0`。）
#   ⚠️ **`# ARM-LOG-SHA` 这 5 行治什么**：`generation.arm_logs` 今天**也是"自己声明自己"**（`D-G9` 残差）——
#      `#30` 实测「失真臂日志 ＋ 同趟把 `arm_logs` 也改掉 ⇒ `ARMLOG_SHA=PASS pass=5 fail=0`」；
#      有了这 5 行，"同趟改 `arm_logs` 洗绿"就会在这里撞上一份**在别的文件里的**声明。
#      值 = 现盘 5 件臂日志 `sha256sum | head -c16`（与 `generation.arm_logs` 前 16 位逐位相同；
#      唯一 64 位全值仍只声明在 `known-red.json`，本处**不重抄全值**）。
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=57d752a3981a9b91
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
#   ⚠️ **以上 4 类行的作用**：`column-floor-check.sh` 的三档据此判 —— ①登记表⇔本块｜②本块声明 ≥ **语料复算**的下界｜③语料整份 sha｜④门禁机读行自报值⇔本块｜⑤`arm_logs`⇔本块。**只有②（语料复算）回答"这个数该是多少"**。⇒ 把「改小下限仍绿」与「同趟改 `arm_logs` 洗绿」两条自指通道**都变成有痕编辑**。
#   【① `D-G26`：探针身份】**缺口**：产生五臂读数的探针 `CoverageProbe/Program.cs` **既不在 `GEN_KEYS`**（那里的 `instr_program_cs` 指**另一个** `Program.cs` = `HbTextLineParity/Program.cs`）**、也不在 `fp_inputs()`**（现场 `grep -c CoverageProbe` = **0**）、**臂日志里也不记它的 sha** ⇒ **改测量代码没有任何指纹会动**（`#26` W26A 真的改过它，只靠人工记账）。**修法**：探针构建时把源 sha 嵌进 `AssemblyMetadata` ＋ 入口打 `TAB_LINES_PROBE sha256=<64>`；门禁加 `probe` 段 ＋ **`GATE_PROBE=`** 机读行。
#     **正极性**：三支 `tab-*` 日志首行 `TAB_LINES_PROBE sha256=a6d0352b86467111…9a40 path=…` ＝ 现场探针源 **全 64 位逐字相等**；`GATE_PROBE=PASS`、`TLINE_GATE=PASS`、`rc=0`。**⭐ 最硬的零位移证据**：三支新日志**剥掉 `^TAB_LINES_PROBE` 行后与旧件 `cmp` 逐字节 IDENTICAL** ⇒ **只新增了一行身份、读数零位移**（`判定行=615`/`字形释放行=194` 与下限逐位相符）。
#     **反极性**：必红 **6 档**（一位翻转／**前缀＋48 个 0**／另一合法 64 位／声明改过的副本／**现场探针真改一字节**／双行冲突）＋ 必 `NOINFO` **3 档**（无自报行 ⇒ **老日志不许读成绿**／声明源缺件／`probes` 整节缺失）＋「只声明一支不牵连」。⭐ **"前缀＋48 个 0"是"必须比 64 位"的铁证**：点名行里**两侧前 16 位逐字相同**，只因后 48 位不同而 FAIL。
#     **⚠️ 作者修掉方案草稿的 5 处真缺陷**，其中两处会让这颗牙**上线即哑**：`<Import>` 被写进 `<ItemGroup>`（MSBuild 当它是一个 item ⇒ **targets 永不导入** ⇒ 元数据不生成 ⇒ 自报恒 `NOINFO`）；`GATE_PROBE=NOINFO` 与 `TLINE_GATE=PASS … all-as-registered` **同时出现**（违反"**`NOINFO` 不许当绿**"）。均已修并给成对复现读数。
#     **边界**：证"**这份日志出自哪一版探针**"；**不证**"探针的测量逻辑是对的"。`FrameProbe`/`PcLineOracle`/`D5CbrProbe` **仍无身份**（族化 = 二期）。
#   【② `D-G27`：下限值本身没有牙齿】**缺口**：两颗列级下限（`START` 615/194、`OVERFLOWED` 421）**唯一声明处** = `known-red.json`；**改小它 ⇒ 门禁照新门槛比、仍然 `PASS`**（实测 `615→421`／`421→400`／`194→0`／两处同降 **四档全 `rc=0`**，且 **`GATE_COLUMN=`/`GATE_COLUMN_EXTRA=` 两行归一化掉声明值后 `cmp` 逐字节 IDENTICAL**）；**同族的第三个自指值** = `generation.arm_logs`（失真日志＋同趟改它 ⇒ `ARMLOG_SHA=PASS`）。**修法** = 新件 `build/MilBridge/tools/column-floor-check.sh`（`--selftest` **18/18**）＋ **本块上面那 4 类声明行**。
#     ⚠️ **它尚未接线**（`#31` 第一项）：接线会让 `verify-all` 步数 `18 → 19/20`，而**声明行必须与重冻同趟**（单独插会让 `[7] BASELINE-SHA` 直接红）⇒ 本波先把**声明钉下**、把**步骤留给 `#31`**（届时它一插即绿）。
#   【③ `D-G33`：见证不再"判产物"】**缺口**：17 行 `suspended` 的见证 `no-in-repo-obj` 判的是**构建产物** ⇒ **删掉 `obj/` 就能变绿**（现场复现：造 `obj/*.cs` ⇒ `FAIL`；**再删掉那个 `obj/` ⇒ 回到 `PASS`** —— 免罪符）。**修法**：改成 **`not-in-build-coverage`**（判**结构**：该工程不在"会被以私有中间目录构建"的闭包内），`MilBridge.Linux` → `fp-locked+foreign-intermediate`。**修后**：无 `obj`／有 `obj`／再删 ⇒ 三趟 **`rc=0` 且 `cmp` IDENTICAL**（产物零影响）；**结构性失效仍必红 4 档**（加进 sln／脚本里加 `dotnet build`／覆盖面内加 `ProjectReference`／抹掉 `-p:ArtifactsPath=`）；数据源取不到 ⇒ **`WITNESS-UNCOMPUTABLE` ⇒ `NOINFO`**。`--selftest` 就地 **25/25**。
#     ⚠️ **作者抓到一件更早的事**：**改前 `--selftest` 本就是红的** —— `#29` 的 `D-G32` 把 `WpfGfx` 真修好之后，`case Q` 的前提（`suspended`+`no-in-repo-obj`）**消失** ⇒ 该例永远红（可复现 `cases=20 pass=19 fail=1`），而 **`verify-all.sh:529` 只跑生产路径、不跑 `--selftest`** ⇒ **没有任何东西看着"用例失去前提"**。⇒ **纪律 68**。
#   【④ `D-G34`：`close-wave.sh` 的 `pgrep` 自匹配】**缺口**：`[0/6]` 的 `pgrep -af '…|WpfTextDemo|…'` **会匹配到承载它的那个 shell 自己** —— 实测：主控用一条**命令行文本里含 `WpfTextDemo`** 的 `bash -c` 调用 ⇒ **假报"有应用/探针在跑"、`exit 3`**（当时只有两个 `Xvfb`、`loadavg 0.16`）。**修法**：命中 ∧ **不属于本脚本自己及其祖先链** ＋ **逐条点名**。**修后成对读数**：脏命令行 **3→0**／**真有"应用"在跑仍 `rc=3`**（且新增点名行 `· 命中：… run-wpftextdemo-fake 90`，旧件该 grep = 0）／干净对照 **0/0**。
#   【⑤ `D-T5-R` 的牙】**修掉两处**：① `*LoCreateContext*` 归因分支原本是**死代码**（`grep -aoE '[A-Za-z]+Exception'` 只取**异常类型名**）⇒ **每一格 `rc=134` 都被印成"不是 D-T5-R 的签名 ⇒ 先怀疑环境"，包括真是它的时候**；② 屏上仍写"恰 4 格红"而真判据是"≥4 且目标在内"。**修后**：真签名格 ⇒ `…消息含 LoCreateContext ⇒ **D-T5-R 的真签名**`（整步 `rc=1` 一字不变）；**缺 shim 格 ⇒ `rc=1 FAIL` → `rc=2 NOINFO`**（`signature=env-missing-shim`）—— **"仪器缺件"不再冒充"被测件失败"**。判据骨架行 **`MISS=0`**；`--selftest` 就地 **12/12**（**0 次 `dotnet`**）。⚠️ **它仍未接线**（是**构建者**：实测 +101.9 s/趟、35 次 `dotnet`/趟 ⇒ 会让 `verify-all` 多一个构建者）⇒ 留给 `#31` 与 `[14]` 同趟。
#   【波尾与门禁】`close-wave.sh`（rc=0）⇒ `native_rebuilt=0`、桥源指纹两侧一致、生成物指纹 `state=ok`、**应用器审计 `miss=0`**、**输入稳定性 波前==波后**；五臂 **`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc`** ＋ **`GATE_PROBE=PASS`** ＋ `GATE_COLUMN=PASS` ＋ `GATE_COLUMN_EXTRA=PASS`、rc=0；`verify-all` **rc=0 / 18 步 / 871 通过 2 跳过**；`ARMLOG_SHA=PASS 5/5`；应用门禁**两趟** `RUN1_RC=0`/`RUN2_RC=0`、**6/6 `BASELINE … result=PASS`**。
#   【⑥ `APPSYNC`】校验器全量（**静树**）⇒ `APPSYNC=MISMATCH`、`rc=1`，逐字计数：
#     `计数：OK=63  MISMATCH=1（STALE=1  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0]  DIVERGENT=1  NO-AUTHORITY=39  LIB-COPY=0  SKIP(obj)=7  SKIP(stub)=6  SKIP(ref)=10  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0`。
#     **关键项**：`MISMATCH=1`｜`MISSING=0`｜`UNEXPECTED=1`｜`DIVERGENT=1`｜`RETIRED=0`｜`AUTH-MISSING=0`｜**`BRIDGE-ANCHOR=0`｜`BRIDGE-NOINFO=0`**。
#     ⚠️ **本波 `pc` 未变**（与 `#26` 同一 `pc` 世代 —— **该前提已由本脚本现算断言**）⇒ **可直接与 `#26` 的记录逐字比对**：`#26` 记的是 `MISMATCH=1[STALE=1] MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1] DIVERGENT=1 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`。**逐字相同 ⇒ "本波零新增红"成立；不同 ⇒ 必须逐条点名并解释**，**不许**用"长期在册"一句话盖过去。
#   【⑦ 内存信封】采样器（v2）每 20 s 一行；**该文件的全文件窗口** = 共 **1039 样本**（18:01:15 → 23:47:34）：`MemAvailable` **谷底 1536 MB**（19:14:39）／均值 3099 MB；`SwapFree` **谷底 0 MB / 2047 MB**（21:50:08）；`load1` 峰值 **9.42**；采样 `dotnet` 峰值 **7**；**告警 10 条**（21:50:08 ALERT avail=4050MB swapfree=0MB load1=3.01 dotnet=1；21:50:28 ALERT avail=4231MB swapfree=25MB load1=2.79 dotnet=；0；21:50:48 ALERT avail=3945MB swapfree=57MB load1=2.70 dotnet=；21:51:08 ALERT avail=3877MB swapfree=60MB load1=2.76 dotnet=；21:51:28 ALERT avail=3946MB swapfree=66MB load1=2.85 dotnet=；21:51:48 ALERT avail=3723MB swapfree=66MB load1=2.96 dotnet=；21:52:08 ALERT avail=3982MB swapfree=68MB load1=2.98 dotnet=；21:52:28 ALERT avail=3881MB swapfree=74MB load1=2.64 dotnet=；0）。
#     ⚠️ **该窗口是采样器自己的生命周期，不等于本波窗口**（该文件是**滚动**的：前面几波的样本也在里面）。引用本段时必须**连窗口边界一起引**，不许只引谷底值。
#     ⚠️ **本波并行车道上限仍是 7**（纪律 57），实际最多 **4 条**（W30A–W30F（六条，除 W30B 外全部零 dotnet）），其中**三条零-dotnet 车道与主控的重活同跑**（`close-wave` 重建 ＋ `verify-all` 测试套件 ＋ 两趟应用门禁）⇒ 谷底仍**未破警戒线**（阈值 `avail<800` / `swapfree<100`）。
#     ⚠️ **主控自纠（本波第 6 处）：第一版采样器报数口径错** ——
#     `read -r _ tot used free shared buff av < <(grep -E '^Mem' /proc/meminfo | awk '{printf "%s ", $2}')`
#     取的是**每一行的第 2 字段**（按 `/proc/meminfo` 的**行序**），而 `read` 把这些值**按位置**塞进 7 个变量 ⇒ 实测打出 `avail=0MB`，并且**当场触发一条假 ALERT**（`[ 0 -lt 800 ]` 为真）。
#     ⇒ **"从 `/proc` 读数"也必须逐字段具名取**，不许靠"行序 ＋ 位置变量"隐式对齐；v2 改成按名字取，并对"字段非法"直接 `exit 9`（**读数缺失必须与读数很小可区分** —— 否则 `0` 会伪装成一个"极小但合法"的读数，并每 20 秒报一次假警）。
#   【⑧ 留给 `#31`（按价值）】① **接线 `[13]`/`[14]`**（`HIDDEN-ONLY` 与 `COLUMN-FLOOR`；**B 式声明**：`19 gen=#31` ＋ 追加 ``**`#31` 收官起 = N 步**``，**保留 `#30` = 18 作为史实**）｜② **`D-G30` 第三格**（给 `tab-zero`/`tab-rtl` 的对账行**只互校不下限**的读者：`COL2_ARM` 补两臂 ＋ 显式 `judged_min:null` ＋ **"该列须整列 NOINFO"的自证**；另加 `判定行 == 红 + 绿` 等式牙）｜③ **产品侧：走产品入口的臂**（`TextFormatter.Create()`＋`FormatLine`，真值复用 `layout-b34-compact.json` 的 5 个 M 例、**免 Windows 重录**）—— `#30` W30E 已用零 `dotnet` 复算证明那 5 条 `M_modifier` Extent 余差**与 modifier 跨度未接线同根**，而**今天没有任何一支臂走产品路径** ⇒ **纪律 67**｜④ **反引号的机器检查**（同一陷阱已 4 次现场：`run-wpfprobe.sh:659`、W28F、主控、W30C；**唯一抓住它的是 `noise=` 断言**）｜⑤ **`D-G11`**（产物↔生成物等号读者）｜⑥ `verify-all` 的**实际执行轨迹**那一半。
#   【本波六条车道（除 W30B 外全部零 `dotnet`）】`W30A`（`$HOME/w30a-report.md 7cce22e9ba7176ef`，`D-G27` ＋ 新读者）｜`W30B`（`$HOME/w30b-report.md bcddba5849536f10`，**构建者**：`D-G26` ＋ 重取三支臂，纪律 59 全流程留档）｜`W30C`（`$HOME/w30c-report.md c53d79c7b48d54c2`，`D-G33` ＋ `D-G34` ＋ `D-G30` 第三格方案）｜`W30D`（`$HOME/w30d-report.md b3b004660e351e6a`，`D-T5-R` 修两处 ＋ 重锚）｜`W30E`（`$HOME/w30e-report.md ccf1494687ae6bf1`，产品侧只读根因）｜`W30F`（`$HOME/w30f-report.md 0443d6168708f6d0`，**主控仪器清账**，修 5 件）。**主控**：修掉自己 `[12]` 步的反引号活缺陷、清 7 个可写硬链接别名。
#   **本波最值钱的四条**：① **一个"上线即哑"的牙被拦下**（W30B 修掉草稿里 `<Import>` 写进 `<ItemGroup>` 与"`NOINFO` 当绿"两处 —— 没有它，`D-G26` 会静默失效）；② **两块自指通道被钉成有痕编辑**（`D-G27` 的外挂声明 ＋ `D-G33` 的"删产物免罪符"）；③ **三条真实的资源/工程隐患被翻出来**：`swapfree=0MB` 而 `avail` 看着健康、`arms23` 那份"归档"其实是**硬链接**（纪律 59 的归档层是空的）、**没有任何东西看着"`--selftest` 用例失去前提"**；④ **纪律 67**：连续五波"零产品位移"，一半原因是**没有一支臂走产品入口**（W30E 已复算证明 Extent 余差与 modifier 同根）。
#   **主控自纠（本波 4 处）**：① **我自己的 `[12]` 步 `echo` 把反引号写在双引号里** ⇒ 命令替换 ⇒ **每趟 stderr 吐语法错误、横幅丢 `fp_inputs()`**（W30D 查出；我当场复现了"字被吃掉"的形态）；② 我派单书说"W29C 的锚也已过期" —— **被 W30D 实测推翻**（它报的就是现件，只有 W28H 的锚过期）；③ 我改 roster 时**漏第 5 列**（`#29` 的判据当场报 `roster-malformed`）；④ 我在 `#29` 定的"备份晚了"事故促成**纪律 65**，而 W30F 又查出**我的三个 `-fill.py` 仍带 `#27` 时代的 `fp_inputs()` 硬编码拷贝**（⇒ 它打印过老定义的值；记录本身未被污染）。
#   **"未取到"（不许当绿）**：`verify-all` 端到端回显（各车道禁跑；替代证已给）｜产品路径的 modifier 实测读数（禁 `dotnet` ＋ **臂不存在**）｜`D-T5-R` 三条要 `dotnet` 的自测例｜`a6d0352b…` 探针源在**重取之前**的日志与门禁的干净对照（被 W30C 的 `close-wave.sh` 改动混入）｜`instr_pc` = `7b47a7b3d69ad62f` 与现场 `pc` dll 的世代差异（该键被 `arm-log-sha-check.sh:53` 自述**信息性** ⇒ 只登记不判缺陷）。
BASELINE tier=default rep=1 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:51e987d58da11654,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w30-gate2
BASELINE tier=default rep=2 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:51e987d58da11654,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w30-gate2
BASELINE tier=default rep=3 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:51e987d58da11654,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w30-gate2
BASELINE tier=env rep=1 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:51e987d58da11654,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w30-gate2
BASELINE tier=env rep=2 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:51e987d58da11654,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w30-gate2
BASELINE tier=env rep=3 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:51e987d58da11654,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w30-gate2
# ⏪ **（历史，已被 `#30` 取代）**# RE-FROZEN #29 —— ✅ **当前冻结基线** —— 内容 = **① `D-G30`：`OVERFLOWED` 的对账行成为牙** ＋ **② `D-G31`：`fp_inputs()` 不再把构建产物当输入** ＋ **③ 第 `[12]` 步 `FP-INPUTS-HYGIENE`** ＋ **④ `D-G32`：修掉 `WpfGfx.Linux.csproj` 的**真暴露****（连锁三处 ＋ **桥重发**）＋ **⑤ 登记 `D-G26`/`D-G27`/`D-G30`/`D-G32`/`D-G33`/`D-G34` 与纪律 63/64/65**（预登记 `docs/WAVE29-PREREGISTRATION.md`）。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行（**本处照纪律 53 不重述值**）。
#   **九位**：**只有环成员 `pf a91e564da4d4f2cb`（7122432 B）变**（`9178561e0fb1451c → a91e564da4d4f2cb`，**波尾 `integration-wave.sh` 重编引起**）；`bridge`/`pc`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` **逐位未动**；**`hbtextline` 一个字节未动 = `e89fed55fd8e32bc`（290825 B）** ⇒ **世代绑定三项全未变** ⇒ **不重取五臂、不重钉 `known-red.json` 的世代三项**（`generation` 仍 `#23`）。
#   ⭐ **`bridge` 的重发是"零位移重发"**：本波为 `D-G32` 改了 `src/WpfGfx.Linux/WpfGfx.Linux.csproj`（加一行规范 `<Import>`）⇒ `BRIDGE_SRC_FP b6acdba4f01599d8 → fdcb41bdc373eee3`（桥 `ProjectReference` 它）⇒ `close-wave.sh` 的 `[3/6]` **真的重发了桥**（rc=0），**但重发后的 `.so` 与 `#28` 逐位相同**（`bridge d567c26f197ec1e3` 未变）—— 因为那行 `<Import>` 只改 `DefaultItemExcludes`（一个 Item 排除属性）、**不进 IL**。⇒ **这是"真修了一个真缺陷、而没有引入任何产品行为位移"的现场证据。**
#   **`inputs_fp = 4ce9f65af5f102a6d9cc8d9e72e79b99e9214a634a15796abe6f7f6447b47ef2`**（`6f8e8ef7a9e7042ae225f1a6efb79e223bd3183621e0304af966af86aa54894e → 4ce9f65af5f102a6d9cc8d9e72e79b99e9214a634a15796abe6f7f6447b47ef2`）—— ⚠️ **设计性变更**：`#29` 把 `fp_inputs()` 的**三条 `find` 统一加了 `obj|bin|.artifacts` 排除**（`D-G31`），而 `close-wave.sh` **自己就在覆盖面里** ⇒ 它一变、指纹必变。⚠️ 另一处**必记**：`#28` 引入的 `-o` 链**必须用 `\( \)` 括起来**才有效（`-a` 比 `-o` 紧 ⇒ 不括号时排除**只作用于最后一支**，实测 `obj/patch-a.py` 仍被吃进 —— 那是**假修**）。
#   【① `D-G30`：`OVERFLOWED` 的对账行成为牙】探针**同时**为两列打对账行（`CoverageProbe/Program.cs:1817`/`:1832`），而 `#28` 合入的 `REC_RE` **只锚 `START`** ⇒ 该列对账行**没有读者**：**X1 谎报**（绿 421→420）与 **X3 整条删除**都 **`rc=0`/`PASS`**（假绿），**X2 该列汇总行 `绿` 谎报**也 `PASS`（`D-G19` 只读 `判定行`）。修后：**X1/X3 各 `rc=1` 并逐字点名**（`…-extra-recon-mismatch` / `…-extra-recon-gone`（点名"命中 **0** 行"）），**X2 顺带治了**；`START` 既有八档**全部不变**、`tab-zero`/`tab-rtl` **不误伤**、两列同时失真 ⇒ **两条点名俱在**。
#     **⭐ 它救了一次假红（本波最值钱的工程判断之一）**：`OVERFLOWED` 的逐例行有**两种形态** —— 形态①（判定过，**288 行**）`行=3 红=0 绿=3[ NOINFO=k]`；形态②③④（**未判**：面缺字形／格式化抛／对齐非 Left，**148 行**）`行=3 NOINFO=面缺字形(本列依赖字形)2` ⇒ **整行没有 `红=`/`绿=`**。**照抄 `START` 的 `PCC_RE` 会在今天的干净树上直接打假红**（作者做了**反实验**：退化成"只认形态①" ⇒ `rc=1`/`FAIL`/`recon-mismatch`）。修法 = **逐例求和不可信时跳过第 1 层，第 2/3 层（对账行 ⇔ 汇总行，不依赖逐例解析）永远比** ⇒ X1/X2/X3 一个都没跑掉。⚠️ 形态②的尾数是**缺字形字符数**、不是行数（尾数求和 **463** ≠ 194）。⚠️ 作者**自曝**第一版无条件比求和 ⇒ 打出**假指控**（与 `#28` W28J 的 X11 同族）。
#     **⚠️ 验证口径（作者顶回主控）**：`FAIL(col)`/`NOINFO(col)` 行**行首有两个空格** ⇒ 主控一直在用的 `grep -E '^FAIL\(col\)'` **恒 0 命中**，会把"有点名"误读成"没点名"；正确口径 = `'^ +(FAIL|NOINFO)\(col\)'`。
#     **明示边界**：`判定行` **上向**谎报（421→615）抓不到；三层**协同**谎报抓不到；`tab-zero`/`tab-rtl` 的 `OVERFLOWED` 对账行**仍无读者**（`COL2_ARM` 未声明，沿用 `D-G19` 裁定）。
#   【② `D-G31` ＋ 第 `[12]` 步：`fp_inputs()` 不许把构建产物当输入】**缺口**：`find src/WpfGfx.Linux -type f -name '*.cs'` 没排除 `obj/` ⇒ 吃进 **2 份构建生成的文件**（`AssemblyInfo.cs` 与 `…AssemblyAttributes.cs`）⇒ **每构建一次 `inputs_fp` 就变一次**（现场：`close-wave` 报一个值，其后 `verify-all` 只跑一次 `dotnet build` ⇒ 当场变另一个值，**期间无人手写任何覆盖面文件**）⇒ 它量的**不是"输入"**。修后**覆盖面仍 110 件、路径集合逐字节相同**（零位移）。**⭐ 新核对器的设计值得复用**：**拒绝"第二实现"**（另写一份 `find` 会与被测者**共模** ⇒ 覆盖面被偷偷改小时核对器**同步缩水** ⇒ **该响时反而绿**），改用**同码路径拦截**（抽 `fp_inputs()` 函数体在本进程执行，只拦 `find`/`printf` 与 `sha256sum`）＋ 三条机器守卫（**不扰动**：拦截指纹 == 无拦截指纹｜**完备**：拦截集合 `cmp` 实际交给 `sha256sum` 的 argv 集合｜生产者白名单），任一不过 ⇒ `NOINFO`。**逻辑只有一份。** `--selftest` **16/16**；就地 `rc=0 coverage_n=110 artifact_n=0`（0.37 s）。
#   【③ `D-G32`：修掉 `WpfGfx.Linux.csproj` 的真暴露】**它是 `#21` W21B 自己标过 `*** STILL EXPOSED ***` 的那一份**（仓内 `obj/Debug/net10.0/*.cs` 两份在场 ⇒ 以命令行私有 obj 手法构建时 `CS0579`）。`#29` 的新判据（`D-G21`）按主控裁定把它判红（`WITNESS-EXPIRED`、`p1=ARMED n=2`、`rc=1`）⇒ **主控接住这个红并真修**（**不回退换绿屏**）。**三处必须同趟**：① `csproj` 加一行规范 `<Import>`；② 声明册该行 `suspended → wired`；③ **判据内嵌 golden 名单 ＋ `EXPECT_N` `40 → 41`**（**只改前两处 ⇒ `BHYGIENE_IMPORT=NOINFO reason=wired-length-mismatch n=41 expect=40`，`rc=2`，不许当绿**）。修后：`BHYGIENE_IMPORT=PASS reason=ok files=41 lines=41 list=41 mention_files=41 mention_lines=83 expect_n=41`、`rc=0`。
#   【④ 登记与纪律】**新登记**：**`D-G26`**（**产生读数的探针既不在 `GEN_KEYS`、也不在 `fp_inputs()`、臂日志也不记它的 sha** ⇒ 改测量代码零指纹会动；`#26` W26A **真的改过它**、只靠人工记账）｜**`D-G27`**（**下限值本身没有牙齿** —— 改小 `615→421` ⇒ 门禁照新门槛比、**仍 `PASS`**；⚠️ `#29` W29D 另查出**同族第三个自指值** `generation.arm_logs["tab-anchor"]`：失真日志＋同改 `arm_logs` ⇒ `ARMLOG_SHA=PASS` ⇒ **`D-G27` 应与 `D-G9` 合案**）｜**`D-G30`**（本波已修）｜**`D-G32`**（本波已修）｜**`D-G33`**（**`no-in-repo-obj` 见证有假绿解**：删掉 `src/WpfGfx.Linux/obj/` 就能变绿，而那是构建产物、下次构建即回来 ⇒ "删产物"成了**免罪符**）｜**`D-G34`**（**`close-wave.sh:134` 的 `pgrep -af` 自匹配** —— 主控那条 `bash -c` 复合命令的**命令行文本里含 `WpfTextDemo`** ⇒ `pgrep` 匹配到**承载它的 shell 自己** ⇒ 假报"有应用/探针在跑"、`exit 3`（实际只有两个 `Xvfb`、`loadavg 0.16`）⇒ **判据的输入不止文件系统，还包括调用者的命令行**）｜**`D-G29`**（`--selftest` 把被测件的当前世代写死 ⇒ 一换代自测就红、而作者在旧件沙箱里拿到**假绿**）。
#     **纪律 63**（**自测沙箱必须自带 `TMPDIR`** —— 两条车道的同一 `--selftest` 会互删 fixture）｜**64**（**派生件不许进"输入指纹"** —— 判据：一个件若"由本趟某步骤产生"，它进的是**核对器**，不是 `fp_inputs()`；臂日志刻意不纳入）｜**65**（**任何车道落地前，主控必须先留 pre-landing 备份** —— 本波退回动作一度因"备份晚了"而没有旧字节，靠车道自己的备份才救回来）。
#   【位移账】**九位相对 `#29` 开工快照（`$HOME/w30-pre.sha`）**：变化的位 = **`['pf']`**（其余八位含 `bridge`/`hbtextline` **逐位断言未动**）⇒ **表外位移 = 0**；**20 件快照里唯一变化的也是 `pf`**。**臂日志 5 份与 `generation.arm_logs` 全程未动。**
#   【波尾与门禁】`close-wave.sh --skip-verify-all`（rc=0）⇒ **`[3/6]` 桥真的重发**（`BRIDGE_SRC_FP fdcb41bdc373eee3`，rc=0）、`native_rebuilt=0`、生成物指纹 `state=ok`、**应用器审计 `miss=0`**、**输入稳定性 波前==波后 == `4ce9f65af5f102a6d9cc8d9e72e79b99e9214a634a15796abe6f7f6447b47ef2`**；五臂 **`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc`** ＋ `GATE_COLUMN=PASS` ＋ **`GATE_COLUMN_EXTRA=PASS`**、rc=0；`verify-all` **rc=0 / 18 步 / 871 通过 2 跳过**（`[4]`–`[12]` 全 ✅，含新第 `[12]` 步）；应用门禁**两趟** `RUN1_RC=0`/`RUN2_RC=0`、**6/6 `BASELINE … result=PASS`**。
#   【⑥ `APPSYNC`】校验器全量（**静树**）⇒ `APPSYNC=MISMATCH`、`rc=1`，逐字计数：
#     `计数：OK=63  MISMATCH=1（STALE=1  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0]  DIVERGENT=1  NO-AUTHORITY=39  LIB-COPY=0  SKIP(obj)=7  SKIP(stub)=6  SKIP(ref)=10  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0`。
#     **关键项**：`MISMATCH=1`｜`MISSING=0`｜`UNEXPECTED=1`｜`DIVERGENT=1`｜`RETIRED=0`｜`AUTH-MISSING=0`｜**`BRIDGE-ANCHOR=0`｜`BRIDGE-NOINFO=0`**。
#     ⚠️ **本波 `pc` 未变**（与 `#26` 同一 `pc` 世代）⇒ **可直接与 `#26` 的记录逐字比对**：`#26` 记的是 `MISMATCH=1[STALE=1] MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1] DIVERGENT=1 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`。**逐字相同 ⇒ "本波零新增红"成立；不同 ⇒ 必须逐条点名并解释**，**不许**用"长期在册"一句话盖过去。
#   【⑦ 内存信封】采样器（v2）每 20 s 一行，共 **784 样本**（18:01:15 → 22:22:30）：`MemAvailable` **谷底 1536 MB**（19:14:39）／均值 3148 MB；`SwapFree` **谷底 0 MB / 2047 MB**（21:50:08）；`load1` 峰值 **9.42**；采样 `dotnet` 峰值 **7**；**告警 10 条**（21:50:08 ALERT avail=4050MB swapfree=0MB load1=3.01 dotnet=1；21:50:28 ALERT avail=4231MB swapfree=25MB load1=2.79 dotnet=；0；21:50:48 ALERT avail=3945MB swapfree=57MB load1=2.70 dotnet=；21:51:08 ALERT avail=3877MB swapfree=60MB load1=2.76 dotnet=；21:51:28 ALERT avail=3946MB swapfree=66MB load1=2.85 dotnet=；21:51:48 ALERT avail=3723MB swapfree=66MB load1=2.96 dotnet=；21:52:08 ALERT avail=3982MB swapfree=68MB load1=2.98 dotnet=；21:52:28 ALERT avail=3881MB swapfree=74MB load1=2.64 dotnet=；0）。
#     ⚠️ **本波并行车道上限仍是 7**（纪律 57），实际最多 **4 条**（W27D ＋ W28A/B/C），其中**三条零-dotnet 车道与主控的重活同跑**（`close-wave` 重建 ＋ `verify-all` 测试套件 ＋ 两趟应用门禁）⇒ 谷底仍**未破警戒线**（阈值 `avail<800` / `swapfree<100`）。
#     ⚠️ **主控自纠（本波第 6 处）：第一版采样器报数口径错** ——
#     `read -r _ tot used free shared buff av < <(grep -E '^Mem' /proc/meminfo | awk '{printf "%s ", $2}')`
#     取的是**每一行的第 2 字段**（按 `/proc/meminfo` 的**行序**），而 `read` 把这些值**按位置**塞进 7 个变量 ⇒ 实测打出 `avail=0MB`，并且**当场触发一条假 ALERT**（`[ 0 -lt 800 ]` 为真）。
#     ⇒ **"从 `/proc` 读数"也必须逐字段具名取**，不许靠"行序 ＋ 位置变量"隐式对齐；v2 改成按名字取，并对"字段非法"直接 `exit 9`（**读数缺失必须与读数很小可区分** —— 否则 `0` 会伪装成一个"极小但合法"的读数，并每 20 秒报一次假警）。
#   【⑧ 留给 `#30`（按价值）】① **`D-G30` 同族**（`tab-zero`/`tab-rtl` 的 `OVERFLOWED` 对账行仍无读者；`判定行` 上向谎报；三层协同谎报）｜② **`D-G27`＋`D-G9` 合案**（给三个自指值一个**外挂**读者；⚠️ 那个"另一处"不许是同一份 `known-red.json`；W29D 的 A＋B＋**C（语料复算）**草稿已备，**只有 C 回答"这个数该是多少"**）｜③ **`D-G26`**（探针自报 `sha256=<64>` ＋ 门禁读它；⚠️ **必须重取三支 `tab-*` 臂**，W29E 已把三种"不重取"替代**逐一实测否掉**；时序按纪律 59）｜④ **`D-G33`**（换一个**不依赖构建产物是否存在**的见证）｜⑤ **`D-T5-R` 接线**（W28H/W29C 已把 12 格对照读数补齐并独立复核；成本实测 **+101.9 s/趟 ≈ +1.70 min**、峰值 RSS ≈790 MB、**35 次 `dotnet`/趟** ⇒ **它会把 `verify-all` 变成构建者** ⇒ 与"构建者独占"冲突，故仍延后；⚠️ 接线前先修作者自曝的两处：`:499` 的 `*LoCreateContext*` **死归因分支**、`:316` 的"恰 4 格红"**字面**）｜⑥ **`D-G34`**（`pgrep` 判据要排除"调用者自己的命令行"）｜⑦ **`D-G11`**（产物↔生成物等号读者）｜⑧ `verify-all` 的**实际执行轨迹**那一半。
#   【⑨ "未取到"（不许当绿）】**"下限 615/421 属于哪一版探针"未定**（探针 mtime `14:48:13` 早于臂日志 `17:52:10`，而后者是 `#27` 复原顶过的 ⇒ **mtime 先后不能定版**）｜`--selftest` **内部**不证跨世代（做成外部三趟）｜`verify-all` 的**实际执行轨迹**（仓内无落点）｜**`D-G18` 的真机侧仍无读数**（读上游源码的推论）｜W28H 报的**「返空串」/「半接线」两个 `pc` 不在盘上** ⇒ 那两档应用器级反极性未取到。
#   【本波车道（六条，除构建者外全部零 `dotnet`）】`W29A`（`$HOME/w29a-report.md 2feea1d1359a1685`，落 `D-G30`）｜`W29B`（`$HOME/w29b-report.md 34bafee2a2232cb6`，`D-G31` ＋ 新核对器）｜`W29C`（`$HOME/w29c-report.md 083fdf2e7837534f`，**构建者**：`D-T5-R` 四条复核 ＋ 重锚，**只交付**）｜`W29D`（`$HOME/w29d-report.md 12079e44516f8fe2`，`D-G27` 草稿）｜`W29E`（`$HOME/w29e-report.md a8da6e8e887099a6`，`D-G26` 方案）｜`W29F`（`$HOME/w29f-report.md 899339e537d56468`，`D-G21` 落地）。**主控**：接线第 `[12]` 步、推 `judge=/4 → /5`、做 `D-G32` 三处同趟。
#   **本波最值钱的四条**：① **两块"与什么都没发生完全不可区分"的假绿被治**（`OVERFLOWED` 的对账行谎报/删除；`fp_inputs()` 把构建产物当输入）；② **一个真缺陷被真修**（`WpfGfx` 的 `CS0579` 暴露 —— 而且**修完桥重发是确定性的、九位零位移**）；③ **独立复核再次打掉主控与作者的自报**：W29A **救了一次假红**（照抄 `PCC_RE` 会在干净树上假红）＋ **顶回主控的 `grep` 口径**（`FAIL(col)` 行首两空格）；W29F **顶回它自己的一个"位移"误判**（把 `HbTextLineParity/Program.cs` 与探针 `CoverageProbe/Program.cs` 混成一个 —— **那正是 `D-G26` 存在的原因**）；W29C **把 W28H 的一条"推翻"分成两层，两层都对**（`#26` 那句按**原始探针层**读没错），并**否掉了 W28H 的"缺 shim 不可分"结论**（marker 文件 ＋ 异常签名两个信号都在它自己的证据里）；④ **三条新纪律**（63/64/65）。
#   **主控自纠（本波 5 处）**：① `$?` 在管道后取到的是管道 rc（我一度把 `[9]` 的 `rc=1` 读成 0）；② **备份晚了** —— 决定退回时手上没有旧字节，靠车道自己的 pre-landing 备份才救回（⇒ **纪律 65**）；③ 我的 roster 编辑**漏了第 5 列**（判据当场报 `roster-malformed`，不许当绿）；④ 我那条 `bash -c` 的**命令行文本触发了 `close-wave` 的 `pgrep` 自匹配** ⇒ 假停（⇒ **`D-G34`**）；⑤ 我先前用 `grep -E '^FAIL\(col\)'` 复核点名 —— **行首有两个空格** ⇒ 恒 0 命中（**结论对、方法错**，由 W29A 顶回）。
#   **一次并发事故（诚实记）**：主控为退回 `D-G21` 而覆盖了 `build-hygiene-import-check.sh`，W29F 察觉后用**可验证的反向 sed 复原出 byte-exact 的 `044dc8ea72de361b`**（哈希自证）并复 land ⇒ 最终 `e961151803412d46`。⇒ **退回与复 land 都必须以"可证还原"为动作**（纪律 65）。
#   **W29F 抓掉 4 个仪器缺陷，最重一个是 W28F 遗留、且是"复现"的旧陷阱**：`echo "…\`D-G21\`…"` 的**反引号写在双引号里仍被当命令替换执行** ⇒ 句子里那几个字**当场消失**，而 `got`/`nl` **照样正确** ⇒ **16/16 与 18/18 对这个伤都是盲的**。⚠️ `noise` 断言首版只匹配英文 `command not found`，而**本机报的是中文化的"未找到命令"⇒ 仍假绿**；加严后**这颗牙当场咬了它自己**。⇒ 与 `handoff` 记的 `run-wpfprobe.sh:659` 是**同一陷阱的第二次**。
#   **边界（贯穿全波）**：`A1/A2/A3` 对"占位是否真零宽"**零判别力**（`D5CbrProbe/Program.cs:567` **自己就这么写**；全文件对产出行的属性读取**只有** `:259 line.Length` 与 `:272 line.NewlineLength`）⇒ **那些绿 ≠ 隐形语义已正确**；`--selftest` 全绿 ≠ 它在真实数据的所有形态上都对（W28G 的 8 例夹具没覆盖"逐例行格式族"与"行尾符族"）。
BASELINE tier=default rep=1 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:a91e564da4d4f2cb,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w29-gate2
BASELINE tier=default rep=2 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:a91e564da4d4f2cb,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w29-gate2
BASELINE tier=default rep=3 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:a91e564da4d4f2cb,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w29-gate2
BASELINE tier=env rep=1 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:a91e564da4d4f2cb,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w29-gate2
BASELINE tier=env rep=2 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:a91e564da4d4f2cb,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w29-gate2
BASELINE tier=env rep=3 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:a91e564da4d4f2cb,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w29-gate2
# ⏪ **（历史，已被 `#29` 取代）**# RE-FROZEN #28 —— ✅ **当前冻结基线** —— 内容 = **① `D-G19`：`OVERFLOWED` 列的下限牙** ＋ **② `D-G20`：门禁读探针的「逐例对账行」** ＋ **③ `D-G22`：第 `[11]` 步 `VERIFYALL-SELF`（门禁自检）** ＋ **④ `D-G23`/`D-G24`/`fp_inputs()` 三条小项** ＋ **⑤ 登记 `D-G26`–`D-G30` 与 4 处旧记录更正（含两条纪律 63/64）**（预登记 `docs/WAVE28-PREREGISTRATION.md`）。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行（**本处照纪律 53 不重述值**）。
#   **⭐ 这是第三次"零产品位移、仪器大改"**（`#26`/`#27` 之后）：
#     · **九位里只有 `pf 9178561e0fb1451c`（7122432 B）变**（环成员，**波尾 `integration-wave.sh` 重编引起**）；`bridge`/`pc`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` **逐位未动**；
#     · **`hbtextline` 一个字节未动 = `e89fed55fd8e32bc`（290825 B）** ⇒ **世代绑定三项全未变** ⇒ **不重取五臂、不重钉 `known-red.json` 的世代三项**（`generation` 仍 `#23`）；
#     · **`inputs_fp` = `6f8e8ef7a9e7042ae225f1a6efb79e223bd3183621e0304af966af86aa54894e`** —— ⚠️ **本代是"设计性变更"**：`build/close-wave.sh` 的 `fp_inputs()` **新增纳入两件**（`build/MilBridge/tools/tline-gate.sh` ＋ `build/MilBridge/known-red.json`，110 → **112** 条），因为它们是"**判什么、门槛多高**"的来源、原先**既不在覆盖面也不在 `GEN_KEYS`**（`D-G22`/`D-G27` 同族）。⇒ **与 `#27` 的值不同是预期的**（`0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8 → 6f8e8ef7a9e7042ae225f1a6efb79e223bd3183621e0304af966af86aa54894e`），且**它自己也在覆盖集里**（`close-wave.sh` 改了自己 ⇒ 自 sha 也变）。
#     · `BRIDGE_SRC_FP=b6acdba4f01599d8`（未变；桥未重发）。
#   **仪器位移（本波）**：`build/MilBridge/tools/tline-gate.sh 59ce84346325eb21 →（W28D 落 `D-G19`）3a8bb7d40f0e8c60 →（主控合入 W28G 的 `D-G20`）d17bede10d02aa7a →（主控修 W28J 查出的两处正则缺陷）见现场`｜`build/MilBridge/known-red.json b7a4ad0907f9d76b →（W28D 加 `additional`）fafb61e70c41fb7a →（主控补 `_FIELDTABLE` 索引）524e4c3eaa88bae2 →（主控落 `D-G24` 删散文 `cross_check`）见现场`｜`verify-all.sh bb1efc78b88cf3b4 →（接线第 `[11]` 步 ＋ 机器读声明块）75e741aa5cc3abaf →（更正被 W28F 证伪的断言）见现场`｜`build/close-wave.sh`（`fp_inputs()` 扩两件）｜`build/MilBridge/tools/defect-registry-check.sh`（`D-G23` 改名 `got_*=`）｜`build/MilBridge/tools/build-hygiene-import-check.sh`（注释归属更正）｜**新建** `build/MilBridge/tools/verify-all-step-check.sh`｜**新建**（**未接线**）`build/MilBridge/tools/hidden-only-step.sh`（W28H 交付，留给 `#29`）。**五臂臂日志、`generation.arm_logs` 全程未动。**
#   【① `D-G19`：`OVERFLOWED` 列的下限牙】**缺口**：列级闸只给 `START` 一列钉了下限，而 `OVERFLOWED` **有汇总行却没有下限牙** ⇒ W28C 在副本上把该列 `判定行` 由 **421 改到 400**（以及整条汇总行删除、汇总行重复）⇒ **旧门禁三档全部 `rc=0`/`PASS`/`GATE_REASON=all-as-registered`，且归一化后 stdout 与未失真那趟 `cmp` 逐字节 IDENTICAL**（= 三种坏法**与什么都没发生完全不可区分**）。**修法**：`generation.column_gate.additional`（`{{column:"OVERFLOWED", judged_min:421}}`，**只钉 `judged_min`** —— 该汇总行**没有** `字形释放行` 字段，**不许造一个**）＋ 门禁 `COL2_ARM` 段 ＋ 新机读行 `GATE_COLUMN_EXTRA=`。
#     **正极性（现场逐字）**：`GATE_COLUMN_EXTRA=PASS state=READINGS-OK arm=tab-oracle-anchor col=OVERFLOWED 判定行=421 红=0 绿=421 NOINFO=194 judged_min=421`；`GATE_COLUMN=PASS state=READINGS-OK arm=tab-oracle-anchor col=START 判定行=615 红=0 绿=615 NOINFO=0 字形释放行=194 非零真值行判定=171 judged_min=615 released_min=194`；`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc judge=t1b3-tline-gate/4`、rc=0。
#     **反极性（≥6 档实测）**：① 判定行 **421→400** ⇒ `rc=1` `FAIL column-gate-extra-regressed`（明细 `FAIL(col) tab-oracle-anchor/OVERFLOWED :: 判定行=400 < 声明下限 421`）；② 汇总行**整条删除** ⇒ `rc=2` `NOINFO column-gate-extra-readings-gone`（`命中 0 行`）；③ 下限**改大** 422 ⇒ `rc=1`；④ **删声明** ⇒ `rc=2` `column-gate-extra-undeclared`；⑤ 汇总行**重复** ⇒ `rc=2`（`命中 2 行`）；⑥ **`tab-zero` 的该列整列消失 ⇒ 仍 `rc=0`**（**刻意不声明**那两支臂：它们的 `判定行=0`、整列 NOINFO ⇒ 钉 0 是**恒不可违反的假牙**）；⑥b **两列互不牵连**（`START` 退化 ⇒ `GATE_COLUMN=FAIL` 而 `EXTRA=PASS`，反向亦成立）。
#     **零位移机器证**：归一化后整份 stdout **只多 1 行**（新机读行）；`TLINE_GATE=` **17 字段只有 `gate=`/`outdir=` 两个自证字段不同**；改前每一行含 `TAB_LINES` 的读取点在新件里**逐字节仍在（23/23 KEPT、`MISS=0`）**；`RED_BY_FIELD` **7 键 7/7 KEPT**（⚠️ `#27` 记录写"六键"是旧数 —— 第七键 `列START·红` 是 W27A 加的；W28D 当场顶回主控）；`gate-readings.json` **顶层键 14=14 零增删**、臂 `readings` **+1 键**；`entries[*].caliber.judgment_version` 4 条 **`/3 → /4`**。
#     **`421` 的词义由语料独立复算**：`latin` 288 例/**421 行**、`hebrew+arabic` 148 例/**194 行**、全语料 436 例/**615 行** ⇒ 与日志 `:1342`/`:1340` 的汇总行逐位相同。
#   【② `D-G20`：门禁读探针的「逐例对账行」】**缺口**：探针在逐例循环后**自己**打对账行（`CoverageProbe/Program.cs:1817`），而门禁对 `对账` 的**读取点是 0** ⇒ 「汇总行与逐例之和不一致」抓不到。W28G 的四档最小失真（**A 汇总谎报 615→614**／**B 对账行被改**／**C 删整条对账行**／**D 数对但自报不一致**）在旧门禁上**全部 `rc=0`/`PASS`**。
#     **⭐ 该行的稳定性是"结构性"证明，不是统计性证明**：**汇总行与对账行由同一个 `if` 块产出**（`:1812`/`:1825`）、**中间无条件分支** ⇒ **"汇总行在 ⇔ 对账行在"**；且 `START` 的对账行**只在 `anchor` 出现**是**构造性**的（`startField` 由语料 schema 决定：`lineStartOffsetsDip` 出现次数 anchor **436** / rtl **0** / zero **0**）。
#     **修法（只加不删 32 行，锚 = `col_noinfo = [x for x in col_bad if x[2] == "NOINFO"]` 这一行、全文件唯一）**：`REC_RE` 读对账行、`PCC_RE` 逐例求和，三层（**逐例之和 == 对账行 == 汇总行**）任一不等 ⇒ `FAIL`＋点名 `**汇总/逐例不一致**：…`。**"对账行缺失"判 `FAIL` 而不是 `NOINFO`**（**假红不可能**：新段只跑"汇总行已命中恰 1 行"的臂，而由结构性事实，汇总行在则对账行必在；缺该列的两支臂**连汇总行都没有**）。判 `NOINFO` 会把"**仪器回退**"错归成"**声明缺失**"、诱导人去改登记表。
#     **反极性（8 例 ＋ 独立复核 3 例）**：baseline `PASS`；A/B/C/D/G（重复）**`FAIL`＋点名**；E `tab-zero`/F `tab-rtl`（无该列）**`PASS`**（不误伤）；H `PASS`；**X9（删一条逐例绿行、汇总不动）⇒ 抓到（612≠615）** —— 这是 `D-G14` **结构性看不见**的一类失真，**纯增益**；**X10（删 `START` 汇总行）⇒ 只 1 条 `NOINFO`、不重复点名**。
#     **⭐ 零位移是构造性的**：独立复核车道**把现件那 32 行切掉** ⇒ 得 **897 行、sha16 `3a8bb7d40f0e8c60`**，与"只有 `D-G19` 那一版"**逐位相同** ⇒ **`D-G20` 的输入恰为 +32/−0、单 hunk**，于是"改前/改后"是**同一棵树上的 +32 行**、全部对照成对。
#     **⚠️ 两处真缺陷（`#28` W28J 独立复核查出、主控当场修）**：① **潜伏假红（混合行形态）** —— 探针的逐例绿行**可选追加** ` NOINFO=n`（`:1557`/`:1744`），而原正则带尾锚 `$` ⇒ 那种行**红/绿被漏计** ⇒ **假指控**（X11 夹具实测打出**假**不一致）；② **CRLF ⇒ 假红**（X8 实测 `逐例求和(0,0,0) ≠ 615`）—— 而**门禁自己在 `:170` 用 `tr -d '\r'`**，说明作者本来预期过 CRLF。**修法**：`NOINFO` 改成**同行可选组**取、两个正则都加 `\r?`；改后现场仍全绿、`FAIL(col)` **0 条**。
#     ⚠️ **教训（与 `D-G29` 同族）**：**"作者的 `--selftest` 全绿"与"它在真实数据的所有形态上都对"是两件事** —— W28G 的 8 例夹具**没有**覆盖"**逐例行格式族**"与"**行尾符族**"（它写过"假红不可能"的论证，**只在它论证的那一族里成立**）⇒ **反极性夹具必须按"数据形态族"列举，不能只按"语义档"列举。**
#   【③ `D-G22`：第 `[11]` 步 `VERIFYALL-SELF`】**缺口**：`verify-all.sh` **自己不在 `fp_inputs()` 覆盖面里、也没有任何自指指纹牙** ⇒ **波中改门禁不会有任何东西红**（`#27` 一趟里它被改了 **5 次**，全靠人工记账跟住）。**更早的活标本**：`#24` 收官时写的"**当前期望是 13 步**"在 `#26`/`#27` **连加 3 步**时**毫无反应**、全程零红。
#     **修法**：`verify-all.sh` 头注释里加**机器读声明块**（`VERIFYALL-STEPS-DECL: 17 gen=#28` ＋ `VERIFYALL-STEP-NAMES: …`），第 `[11]` 步**每趟**核对「现场 `^run_step "` 抽出的**步名多重集合/条数/次序/无重名** ⇔ 声明块 ⇔ 口径句数字」；分叉 ⇒ `FAIL`，**缺声明 ⇒ `NOINFO`**（`rc=2`，不许当绿）。
#     **现场正极性（逐字）**：`VERIFYALL_SELF=PASS names=17 decl=17 gen=#28 dup=0 order=OK prose=OK dynamic_trace=NOINFO`、rc=0。**零 `dotnet`、纯读、单趟 ≤0.01 s。**
#     **反极性：`--selftest` 21/21**（10 红 ＋ 5 `NOINFO` ＋ 正极性 ＋ 接线后模拟 ＋ 换次序/自相矛盾 ＋ **"同名步"2 档**）。⚠️ **"只做集合相等"会让同名步全绿漏过** —— 作者实测：把 `run_step "BASELINE-SHA"` 原样再写一遍、并把 `DECL 16→17`、清单写两遍、口径句全配平 ⇒ ①②③⑤ 全过，**唯一判词是 `duplicate-step-name(BASELINE-SHA×2)`** ⇒ 因此额外加了"**无重名**"这一维。
#     **⭐ 世代无关性（三个方向实测）**：同一份核对器 —— 现件 `#28`/17 步 **21/21**｜**上一代形态** `#27`/16 步 **21/21**｜**下一代形态** `#30`/18 步 **21/21**，且汇总行强制印 `fixture_gen=`/`fixture_n=` ⇒ **任何绿都自带"在哪一代取的"**。
#     **⚠️ `D-G29`（本波实测撞到的假绿）**：作者首版的 fixture **把 `gen=#27` 写死**（`'… gen=#27' % n`），而 `n` 从真件现算 ⇒ 主控把世代推到 `#28`/17 后**就地**跑 ⇒ **`cases=19 pass=13 fail=6`**，而作者在**自己的沙箱里对着一份旧真件**跑出的是 **19/19**。⇒ **"作者的 `--selftest` 全绿"这句话，在被测件换代之后不再有信息量**（与 `#26` §9.1b"静树必要但不充分"是**姊妹**）。**修法已落**（fixture 全部从被测件现算 ＋ 加两档反极性 `stale-gen`/`gen-nonexistent`）；**主控裁定**：`gen=#99` ⇒ **`NOINFO`（`rc=2`）正确、不许改 `FAIL`** —— "**缺声明**"与"**分叉**"是两件事。
#     **⚠️ 它抓不到什么**：**整份 `verify-all.sh` 被换成 `exit 0`**（牙长在体内）⇒ 那需要**外挂**读者，属 `D-G22` 的残余；步**内容**（命令行/注释/文案）变化不在射程；缩进步/死分支步**静态漏网**（需结论区印实际执行轨迹，那一半仓内**今天没有落点**，作者如实标 `NOINFO`）。
#   【④ 三条小项】**`D-G23`**：第 `[10]` 步 `--selftest` 汇总行的 `pass=/fail=/noinfo=` **数的是"现场 `got=` 值的个数"，不是"通过例数"**（`pass=2` 极易被读成"只有 2 例通过"）；权威字段是 `not-as-expected=`。**修法**：改名 `got_pass=/got_fail=/got_noinfo=`（**只改名、不改语义**，**+12 B**）。⚠️ **旁证**：同族四支核对器里 `pass=` 有**两个相反含义**（本支按 **expect** 分桶，另三支按"是否达预期"）⇒ 只改本支最小最安全。**机器证**：11 行输出**只有汇总行**不同、**10 条逐例子行 `cmp` IDENTICAL**、sed 回旧名后**整份 `cmp` IDENTICAL**、三态 `rc` 不变、**全仓读者数 = 0**。
#     **`D-G24`**：`known-red.json` 的 `leg_resolution.cross_check` 是**一段没有任何读者的散文**，而它 4 条里 **3 条与现场不符**（`tab-zero`/`tab-rtl`/`tab-anchor`；仅 `textlineproto` 相符），**结构化的 `generation.arm_logs` 却 5/5 相符**。**修法 = 删掉散文、只留结构化**（净 **−445 B**）。⚠️ **两处必须做对**：① **`leg_resolution.conclusion` 不许删** —— 门禁 `:257-258` **确实读它**（打进 `腿核清` 行）；② 删整行会留**悬空逗号** ⇒ 必须同时去掉上一行（`how`）的行尾逗号（作者实测撞到 `JSONDecodeError`）。**机器证**：门禁差分 **rc 0/0**、`TLINE_GATE=` **逐字相同**、归一化后 `cmp IDENTICAL`；结构级"**除该键外整份 JSON 逐字段相同 = True**"。
#     **`fp_inputs()` 扩两件**：见上"设计性变更"。**⚠️ 刻意不纳入 `build/MilBridge/arm-logs/*`**（纪律 **64**）：它是**派生件**（本表 `_FIELDTABLE` 的 `arm_logs{}` 行与 `leg_resolution.why` **逐字自述**）、**已有更严的牙**（全 64 位 `arm_logs` ＋ 已接线的 `[8] ARM-LOG-SHA`），且**重取臂是合规动作**（纪律 34/59 用 `ln -f`）⇒ 纳入后**每个重取过的波**都会 `IN_FP_0 != IN_FP_1` ⇒ 把"输入稳定性"**自己搞成噪音**（`close-wave.sh` 会 `exit 5`）。⚠️ **流程代价（新纪律的一部分）**：入门禁/登记表之后，**"改门禁"必须安排在 `IN_FP_0` 采样之前**（**独立准备趟**）。
#   【⑤ 登记与更正】**新登记**：**`D-G26`**（**产生读数的探针 `CoverageProbe/Program.cs` 既不在 `GEN_KEYS`、也不在 `fp_inputs()`、臂日志里也不记它的 sha** ⇒ **改测量代码没有任何指纹会动**；而 `#26` W26A **真的改过它**、只靠人工记账跟住 ⇒ 比 `D-G22` 更重：那条管"判据"，这条管"**测量**"）｜**`D-G27`**（**下限值本身没有任何牙齿** —— 两颗列级下限都只有一个声明处 `known-red.json`，而它**既不在 `GEN_KEYS` 也不在 `fp_inputs()`** ⇒ **把 `615→421`/`421→400` 一改，门禁照着新门槛比、仍然 `PASS`**；与 `D-G22`/`D-G26` **同族、方向相反**：那条管"判据/测量"，这条管"**判据的门槛**"）｜**`D-G28`**（**登记表自己的索引 `_FIELDTABLE` 没跟上新增声明面**：W28D 新增 `additional` 时索引未改，`grep` 出提到它的条目 = **0**；**同趟已修**，并把 `judge=` 的版本语义写进索引）｜**`D-G29`**（**核对器的 `--selftest` 把被测件的当前世代写死** ⇒ 一换代自测就红、而作者在旧件沙箱里拿到**假绿**）｜**`D-G30`**（**`OVERFLOWED` 的"仪器自洽"对账行仍无人读** ⇒ 该列对账行**谎报**或**整条删掉**都 `rc=0`/`PASS`；与 `D-G19` 立项理由**同族的第二颗缺口**）。
#     **旧记录更正 4 处**：① **`D-G21` 被推翻一句** —— `#27` 写的"那 42 份**都不是**暴露工程（逐份核过）"**错**：按推导谓词 P1（「默认 `Compile` glob 生效 ∧ 仓内 `obj|bin` 有 `*.cs`」）**真有 1 份暴露却没接线 = `src/WpfGfx.Linux/WpfGfx.Linux.csproj`**，而且 **`#21` W21B 自己的表就标着 `*** STILL EXPOSED ***`**（我当时只核了 **csproj 里字面写的** `BaseIntermediateOutputPath`、**没核"glob 是否生效"**）；② "6 份真不暴露"的**理由错**（真理由是 `EnableDefaultCompileItems=false`，不是我写的"SDK 恰覆盖"—— 那在命令行手法下**不成立**，全仓 `TreatAsLocalProperty` 命中 **0**，且**未实测**）；③ 我写的"`.sh`/`.py` 里命中 0"**今天机器计数是 1，而那 1 处就是我写进 `verify-all.sh` 注释的那句话** ⇒ **写下那句话的动作本身毁掉了它的证据**（与 `D-G15` 同形）；④ 那个 53 份的**归属写错**（全在 **`upstream/`** 下，不在 `obj/`）—— 已更正核对器注释。**另更正 `#27` 记录里的"`RED_BY_FIELD` 六键"** ⇒ 实为 **7 键**（W28D 顶回）。
#     **新纪律 2 条**：**63**（**自测沙箱必须自带 `TMPDIR`** —— 否则两条车道的同一 `--selftest` 会互删 fixture；W28I 实测同一个**未改动**的脚本三次跑出三个结果）｜**64**（**派生件不许进"输入指纹"** —— 判据：一个件若"由本趟某步骤产生"，它进的是**核对器**，不是 `fp_inputs()`）。
#   【位移账】**九位相对 `#28` 开工快照（`$HOME/w28-pre-lanes.sha`）**：变化的位 = **`['pf']`**（`byname` 逐个断言其余八位未动，含 `hbtextline`）⇒ **表外位移 = 0**（预登记 §5 停条件①②③④**全未触发**；② 的例外 = 上面那条**设计性**的 `fp_inputs()` 变更，已单列）。**臂日志 5 份与 `generation.arm_logs` 全程未动**（开工/收工聚合 sha 逐位相同）。
#   【波尾与门禁】`close-wave.sh --skip-verify-all`（rc=0）⇒ `[1/6] integration-wave.sh` rc=0、`native shim` 跳过重建、**桥源指纹一致 ⇒ 无需重发**、身份自检：桥指纹两侧一致 ✅／生成物指纹 `state=ok` ✅／**应用器审计 `miss=0`** ✅／**输入稳定性 波前==波后 == `6f8e8ef7a9e7042ae225f1a6efb79e223bd3183621e0304af966af86aa54894e`** ✅。
#     五臂 **`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc`**、`GATE_REASON=all-as-registered`、rc=0；**新增两条机读行** `GATE_COLUMN=`（`START`）与 **`GATE_COLUMN_EXTRA=`**（`OVERFLOWED`）。
#     `verify-all` **rc=0 / 17 步 / 871 通过 2 跳过**（`[4]`–`[11]` 全 ✅，含本波新接的 **`[11]` `VERIFYALL-SELF`**）。⚠️ **步数口径：`#15`=9、`#16`–`#20`=10、`#21`–`#23`=11、`#24`=12、`#24` 收官起=13、`#25`/`#26`=14、`#27` 收官起=16、`#28` 收官起=17**；机器证 = `grep -c '^run_step "' verify-all.sh` ⇒ **17**，**且从 `#28` 起这个数有牙**（第 `[11]` 步）。
#   【⑥ 判据读数】应用门禁**两趟**（`run_dir=…/w28-gate1`、`…/w28-gate2`；按 `D-G7` 逐字记录装置行）⇒ `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、**6/6 `BASELINE … result=PASS`**、六条机读行的 `config=pc:`/`pf:` **都是终态值** ⇒ **本波"零产品位移"的预测兑现**（`drawn`/`colors`/`frames`/`cross_ae` 应与 `#27` **逐位相同**）。
#   【⑦ `APPSYNC`】校验器全量（**静树**）⇒ `APPSYNC=MISMATCH`、`rc=1`，逐字计数：
#     `计数：OK=63  MISMATCH=1（STALE=1  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0]  DIVERGENT=1  NO-AUTHORITY=39  LIB-COPY=0  SKIP(obj)=7  SKIP(stub)=6  SKIP(ref)=10  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0`。
#     **关键项**：`MISMATCH=1`｜`MISSING=0`｜`UNEXPECTED=1`｜`DIVERGENT=1`｜`RETIRED=0`｜`AUTH-MISSING=0`｜**`BRIDGE-ANCHOR=0`｜`BRIDGE-NOINFO=0`**。
#     ⚠️ **本波 `pc` 未变**（与 `#26` 同一 `pc` 世代）⇒ **可直接与 `#26` 的记录逐字比对**：`#26` 记的是 `MISMATCH=1[STALE=1] MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1] DIVERGENT=1 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`。**逐字相同 ⇒ "本波零新增红"成立；不同 ⇒ 必须逐条点名并解释**，**不许**用"长期在册"一句话盖过去。
#   【⑧ 内存信封】采样器（v2）每 20 s 一行，共 **265 样本**（18:01:15 → 19:29:19）：`MemAvailable` **谷底 1536 MB**（19:14:39）／均值 3090 MB；`SwapFree` **谷底 819 MB / 2047 MB**（18:48:17）；`load1` 峰值 **9.42**；采样 `dotnet` 峰值 **7**；**告警 0 条**（无）。
#     ⚠️ **本波并行车道上限仍是 7**（纪律 57），实际最多 **4 条**（W27D ＋ W28A/B/C），其中**三条零-dotnet 车道与主控的重活同跑**（`close-wave` 重建 ＋ `verify-all` 测试套件 ＋ 两趟应用门禁）⇒ 谷底仍**未破警戒线**（阈值 `avail<800` / `swapfree<100`）。
#     ⚠️ **主控自纠（本波第 6 处）：第一版采样器报数口径错** ——
#     `read -r _ tot used free shared buff av < <(grep -E '^Mem' /proc/meminfo | awk '{printf "%s ", $2}')`
#     取的是**每一行的第 2 字段**（按 `/proc/meminfo` 的**行序**），而 `read` 把这些值**按位置**塞进 7 个变量 ⇒ 实测打出 `avail=0MB`，并且**当场触发一条假 ALERT**（`[ 0 -lt 800 ]` 为真）。
#     ⇒ **"从 `/proc` 读数"也必须逐字段具名取**，不许靠"行序 ＋ 位置变量"隐式对齐；v2 改成按名字取，并对"字段非法"直接 `exit 9`（**读数缺失必须与读数很小可区分** —— 否则 `0` 会伪装成一个"极小但合法"的读数，并每 20 秒报一次假警）。
#   【⑨ ⚠️ 留给 `#29` 的清单（本波**刻意不落**）】① **`D-G30`**（`OVERFLOWED` 的对账行纳入判据；`REC_RE` 泛化成带列名捕获组）｜② **`D-G26`**（探针自报 sha ＋ 门禁读它 —— **要重取三支臂**）｜③ **`D-G27`**（给"下限值本身"一个外挂读者；⚠️ 那个"另一处"**不许**是同一份 `known-red.json`）｜④ **`D-G21`**（W28F 的三节声明册 ＋ 见证谓词，成稿已备）｜⑤ **`D-T5-R` 有牙**（W28H 的新件 `build/MilBridge/tools/hidden-only-step.sh` **已在仓内但未接线** ⇒ 要按 **17 步**重锚 ＋ 它自己的 12 格对照读数复核）｜⑥ **`D-G11`**（读者目录先于/同趟）｜⑦ `verify-all` 的**实际执行轨迹**那一半（`--trace` 在仓内**今天没有落点**）。
#   【本波的九条车道：两条落地 ＋ 六条只读交付 ＋ 一条构建者（全部零 `dotnet`，除构建者）】`W28D`（`$HOME/w28d-report.md 9eca1749845918f0`，**落 `D-G19`**：`tline-gate.sh` ＋ `known-red.json` 同趟）｜`W28E`（`$HOME/w28e-report.md 5daa47e2f7c2398f`，`D-G22` 判据 ＋ 接线 ＋ **`D-G29` 修法**）｜`W28F`（`$HOME/w28f-report.md 64a41d3ac67bde5e`，`D-G21` 判据形状 ＋ **推翻主控一句**）｜`W28G`（`$HOME/w28g-report.md 98efa0c364abbee3`，`D-G20` 判据 ＋ 假绿实证）｜`W28I`（`$HOME/w28i-report.md 6e984ff27fa2c24c`，`D-G23`/`D-G24`/`fp_inputs()` 三草稿）｜`W28J`（`$HOME/w28j-report.md 6857ec31d463dcfa`，**合体后的独立复核** ＋ 查出 `D-G20` 段两处真缺陷）｜`W28H`（**构建者**，`D-T5-R` 有牙；交付 `build/MilBridge/tools/hidden-only-step.sh`，**未接线**）。
#   **本波最值钱的四条（按价值）**：
#     1. **两块"与什么都没发生完全不可区分"的假绿被治**：`OVERFLOWED` 的三档失真（判定行改小／汇总行删除／重复）**旧门禁全部 `rc=0`/`PASS` 且 stdout `cmp` 逐字节 IDENTICAL**；`START` 的"汇总⇔逐例不一致"四档同样全绿 ⇒ 现在**各自 `rc=1/2` 并逐字点名到 `arm=… col=…`**。**而两段的零位移都是构造性证明的**（后者：切掉 32 行就**逐位**回到前一版的 sha）。
#     2. **`D-G22`：门禁第一次"自己有牙"** —— `verify-all` 的步数口径从"只靠人记得"变成**每趟核对**（步名多重集合/条数/次序/无重名 ⇔ 声明 ⇔ 口径句），且**世代无关性三方向实测**（`#27`/`#28`/`#30` 形态各 21/21）。这条的现场标本就是"`当前期望是 13 步`在连加 3 步期间毫无反应"。
#     3. **一连串"我自己的断言被别人的独立复核推翻"** —— `RED_BY_FIELD` 6→**7**（W28D）｜"42 份都不是暴露工程"**被推翻**（W28F，且 `#21` W21B 自己的表早就标了 `*** STILL EXPOSED ***`）｜"`.sh`/`.py` 命中 0"**今天是我自己写的注释**（自我 disqualifying）｜"作者的 `--selftest` 19/19"在被测件换代后是**假绿**（主控接线时当场撞到 `13/19`）｜`D-G20` 段的两处正则缺陷（W28J）。⇒ **本波是"独立复核把主控与作者的自报各打掉几处"的一波**，这比任何一条新牙都值钱。
#     4. **两条通用纪律**：**63**（自测沙箱自带 `TMPDIR`）＋ **64**（派生件不进输入指纹）。而 **64 的落地**（`fp_inputs()` 纳入门禁＋登记表两件）把"**本波动了门禁**"这件事第一次变成 `inputs_fp` 上一格**看得见**的东西。
#   **同波还查明/留下（按 `#29` 的价值排序）**：① `D-G30` ｜② `D-G26`（探针身份无处可查）｜③ `D-G27`（下限本身无牙）｜④ `D-G21` 的成稿 ｜⑤ `D-T5-R`（新件已在仓内、未接线）｜⑥ `D-G11` ｜⑦ 执行轨迹那一半。
#   **主控自纠（本波 7 处，全部留档）**：① `RED_BY_FIELD` 键数（抄 `#26` 旧记录 ⇒ 被 W28D 顶回）｜② "42 份都不是暴露工程"（只核了 csproj 字面量、没核 glob 生效 ⇒ 被 W28F 推翻）｜③ "`.sh`/`.py` 命中 0"（**我自己把它写成 1**）｜④ 我给 `[9]` 写的"两条排除"（真值 1 条）｜⑤ `_FIELDTABLE` 索引漏登 `additional`（**我自己的惯例漏网**，已修）｜⑥ 首版内存采样器字段错位 ⇒ 假 `avail=0` ＋ 假 ALERT（`#27` 末，本波沿用 v2）｜⑦ 我用 `find`（不带 `upstream`/`.artifacts` 排除）数出 135 份并据此**怀疑车道**（是我错）。⇒ **本波"主控被自己的车道纠正"的次数（4 次）超过了它纠正车道的次数。**
#   **两次仪器事故（都按纪律处置）**：① W28E 的 fixture 写死世代 ⇒ 主控接线后就地 `13/19`（**假绿在"沙箱对着旧件"这一步**）⇒ 作者修 + 主控裁定 `NOINFO` 那一档；② W28I 的 `--selftest` 未隔离 `TMPDIR` ⇒ 与并发车道撞车 ⇒ 读数不可用 ⇒ **立纪律 63**。
#   **"未取到"（不许当绿）**：① `--selftest` **内部**不证跨世代（作者如实标，做成外部三趟）｜② `verify-all` 的**实际执行轨迹**那一半（仓内无落点）｜③ `D-G18` 的真机侧仍**无读数**（读上游源码的推论）｜④ `D-G26` 的"下限 615/421 属于哪一版探针"**未定**（`CoverageProbe/Program.cs` mtime `14:48:13` 早于臂日志 `17:52:10`，而后者是 `#27` 复原顶过的 ⇒ **mtime 先后不能定版**，纪律 35 记 `NOINFO`）｜⑤ W28H 的 12 格 `--nocatch` 对照读数（它本趟在跑，见其报告）。
BASELINE tier=default rep=1 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:9178561e0fb1451c,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w28-gate2
BASELINE tier=default rep=2 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:9178561e0fb1451c,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w28-gate2
BASELINE tier=default rep=3 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:9178561e0fb1451c,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w28-gate2
BASELINE tier=env rep=1 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:9178561e0fb1451c,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w28-gate2
BASELINE tier=env rep=2 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:9178561e0fb1451c,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w28-gate2
BASELINE tier=env rep=3 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:9178561e0fb1451c,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w28-gate2
# ⏪ **（历史，已被 `#28` 取代）**# RE-FROZEN #27 —— ✅ **当前冻结基线** —— 内容 = **① 列级闸接进五臂门禁（`D-G14` 的"下半身"：钉下限）** ＋ **② `D-G17`：跳过数可见性 ＋ 上限断言** ＋ **③ 第 `[9]` 步 `BUILD-HYGIENE`（`D-R8` 的回归牙）** ＋ **④ 第 `[10]` 步 `DEFECT-REGISTRY`（`D-G15` 的机器对账）** ＋ **⑤ 新登记 `D-G19`–`D-G25` 与对旧记录的 4 处更正**（预登记 `docs/WAVE27-PREREGISTRATION.md`）。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行（**本处照纪律 53 不重述值**）。
#   **⭐ 本波与 `#26` 同类：又一次"零产品位移、仪器大改"**：
#     · **九位里只有 `pf 3d44e756475b5dd4`（7122432 B）变** —— 环成员，**由波尾 `integration-wave.sh` 重编引起**（与 `#26` 同一形态）；`bridge`/`pc`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` **逐位未动**；
#     · **`hbtextline` 一个字节未动 = `e89fed55fd8e32bc`（290825 B）** ⇒ **世代绑定三项全未变** ⇒ **不重取五臂、不重钉 `known-red.json` 的世代三项**（`generation` 仍 `#23`）；
#     · **`inputs_fp` 与 `#26` 逐位相同 = `0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8`**（`BRIDGE_SRC_FP=b6acdba4f01599d8`，桥未重发）；
#     · **`pf` 的位移方向**：`ebbe3bab855cdd55 → 3d44e756475b5dd4`（**`#27` 波内除它之外没有第二位动**，见"位移账"）。
#   **变的都是"冻树回路里的仪器"（不在九位里，但都要在本块留档）**：`build/MilBridge/tools/tline-gate.sh b37a5c9f55ae71a4 → 59ce84346325eb21`（`+116/−5`，680→791 行，W27A 接列级闸；judge `t1b3-tline-gate/2 → /3`）｜`build/MilBridge/known-red.json 84fcfb4f728deead → b7a4ad0907f9d76b`（W27A 加 `generation.column_gate` ＋ 4 条 `judgment_version` `/2→/3` ＋ 改写 `pending.open[0]` ＋ `changelog` 11→12 ＋ `_FIELDTABLE` ＋1；**`GEN_KEYS` 三项逐字节未变**）｜`verify-all.sh f1dc01793a160c19 → ad705fa5b0cdb331`（W27B 落 `D-G17`）`→ ff0d3a0b636ad302`（主控接 `[9]`）`→ d9812c6657f7eda3`（主控并入 W28A 独立取证与射程披露）`→ a4db9f8149af7a07`（主控接 `[10]`）`→ bb1efc78b88cf3b4`（主控修 4 处口径失真：`[X11Fact]` 8→26、两个 82 的区分、预登记口径）｜**新建** `build/MilBridge/tools/build-hygiene-import-check.sh`｜**新建** `build/MilBridge/tools/defect-registry-check.sh` ＋ `build/MilBridge/tools/defect-registry-declared.tsv`｜`docs/*` 与 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的口径更正（见 ⑤）。**三支 `tab-*` 臂日志未动**（`tline`/`textlineproto` 同样未动）。
#   【① 列级闸接进五臂门禁 —— `D-G14` 的"下半身"】`#26` 把探针的覆盖闸从**整例级**改成**逐列级**（于是 `Start` 列的判定行 421→615），但**门禁对列级读数零读取点**（`grep TAB_LINES START tline-gate.sh` = 0）⇒ `#26` 留下的**假绿窗口**：把 `字形释放行` 从 194 悄悄改小、或让整列退回"放行了但一行没判"，门禁**仍 `PASS/rc=0`**。
#     **修法**：`generation.column_gate` 声明（`arms["tab-oracle-anchor"]` 的 `{column:"START", judged_min:615, released_min:194}`）＋ `tline-gate.sh` 新增 `COL_ARM` 读取点 ＋ **新机读行** `GATE_COLUMN=`。**下限值 = `#26` 的实测值本身，不留余量**（本工程惯例：留余量 = 允许静默退化）。
#     **正极性（现场逐字）**：`GATE_COLUMN=PASS state=READINGS-OK arm=tab-oracle-anchor col=START 判定行=615 红=0 绿=615 NOINFO=0 字形释放行=194 非零真值行判定=171 judged_min=615 released_min=194`；`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc`、`rc=0`。
#     **反极性 ≥4 档（全部实测）**：① 退化日志（`字形释放行=0`）⇒ **`FAIL column-gate-regressed`、`rc≠0`**（**这正是治假绿的那一档**）；② `judged_min+1` ⇒ `FAIL`；③ `released_min+1` ⇒ `FAIL`；④ **删声明 ⇒ `NOINFO`**（**不许当绿**）。
#     **零位移机器证**：既有 **13 个读取点一个都没删或放宽**（改前每一行含 `TAB_LINES` 的读取点在新件里**逐字节仍在**）；`RED_BY_FIELD` 原六键 **6/6 KEPT**；`TLINE_GATE=` 那一行的既有字段（`arms/red/green/noinfo_arm/registered/unlocated/drift/gone/unregistered/caliber/generation/tree_gen/saved_shim`）**逐项与 `#26` 相同**（除新增项）。
#     **世代三件不动**：`GEN_KEYS` 三项未变；`entries` 的 `reason`/`red_authority`/`carrier` 等**逐字节未变**（只推 `caliber.judgment_version`）。
#     ⚠️ **`--selftest` 缺席的替代**：门禁没有 `--selftest`；W27A 用"**造两棵只差'有无 `column_gate`'的沙箱树**跑门禁、归一化后 `cmp` 一致"替代（照 W26D 的做法）。⚠️ **沙箱树必须硬链接/真拷贝** —— 纪律 56/60：**硬链接沙箱是双向的**（`root` 会看到同一 inode），而 `find -type f` 会**跳过符号链接**。
#   【② `D-G17`：跳过数的可见性与上限断言】问题 = `verify-all` 对 `total_skipped` **零断言**，且 `X11FactAttribute` 在**发现期**就 `Skip` ⇒ **`--no-x`／无 X 机器上静默关掉一批牙而全绿**。
#     **修法（只加不删）**：`run_step` 绿分支把跳过数记进 `SKIP_OBS[套件]` 并**立刻印"声明来源清单"**（`↳ 跳过清单 … ｜本步上限 = N 例（静态 ＋ 语料 ＋ X 项，X_STATE=…）`＋`声明来源：…`）；末尾加**上限断言**：越上限 ⇒ `SKIP_GUARD=FAIL` **计入 `fail`**；X 可用却被跳过 ⇒ 同样 `FAIL`；X **不可用**时跳过 ⇒ 不判失败但必须 `SKIP_GUARD=REDUCED` ＋ 结论区逐字写明"**射程缩减**"（**不许无声**）。
#     **只加不删机器证**：两件（`verify-all.sh`、`frame-step.sh`）"改前独有行" = **0 / 0**；**既有终局行逐字节未动**；**11 个既有用例的逐例通过失败完全相同（6/5）**。
#     **本波 `verify-all` 现场实测**：`Rendering.Tests ✅ 通过 162 跳过 2 合计 164` 下面**逐字出现** `↳ 跳过清单 Rendering.Tests：2 例（**跳过不许无声**）｜本步上限 = 27 例（静态 2 ＋ 语料 25 ＋ X 项 0，X_STATE=available）` ＋ `声明来源：静态 2（DrawingBrushTests.cs:201 空壳用例 + TileFlipTruthTests.cs:240 T2b 登记缺口）+ [ParityFact]×25（ParityTests.cs:42 缺 ParityData）` ⇒ **"跳过"从此上屏且带上限**。
#   【③ 第 `[9]` 步 `BUILD-HYGIENE` —— `D-R8` 的回归牙（`#27` 首次接线）】问题 = `#21` W21B 修好 `D-R8`（`BuildHygiene.props` 全仓唯一排除实现 ＋ 40 份 csproj 各一行 `<Import>`）之后 **5 个世代里"接线有没有掉"没有任何东西会红**（机器证：改正 `grep` 过滤器写法后，仓内**任何 `.sh`/`.py` 里 `BuildHygiene` 命中 = 0**；阳性对照 = `baseline-sha-check.sh` 同法能命中）。
#     **判据四档 ＋ 三态**：① 名单里每份**恰有 1 行**规范 `<Import>`（少=掉线/多=重复）；② 树里没有未登记用户；③ `BuildHygiene.props` 在**且仍带那条排除**；④ 名单 = **内嵌 golden 40 行 ＋ `EXPECT_N=40`**（不用遍历推 —— 遍历推必然与坏件同步缩水，`D-R4` 同族）。`rc=0` PASS ／ `rc=1` FAIL（`BHYGIENE_DRIFT=FAIL kind=… path=…` **逐条点名**）／ `rc=2` **NOINFO**（名单缺失/不可解析）。
#     **作者自测**：`--selftest` **9/9**（6 例断言"必须红"、2 例断言"必须 NOINFO"、1 例正极性），每例 `concl_lines=1`。**现场正极性**：`BHYGIENE_IMPORT=PASS reason=ok files=40 lines=40 list=40 mention_files=40 mention_lines=82 disappeared=0 dup=0 unlisted=0 file_absent=0 expect_n=40 props=c88fcccde138263b`、`rc=0`。
#     **✅ 独立咬合取证（`#27` W28A —— 不是作者自测）**：`--selftest` 是"作者的判据在作者的 fixture 上"；另派车道在**真实那 40 份 csproj 的真副本**上（`cp -p`、**无硬链接**、`-links +1` 命中 0）独立扰动，**6 种坏法全部 `rc=1` 且逐条点名到具体文件**：`DISAPPEARED c=0`／`DUP c=2`／`UNLISTED`（含**射程探针**那份）／`PROPS-MISSING`／`PROPS-CONTENT-LOST`／**合并坏法**（删 props ＋ 摘掉 40 行）；阴性对照（未扰动副本）`rc=0` 证明"红"不是沙箱噪声；**真树零污染**（3 个件 ＋ csproj 聚合 sha 开工==收工**逐位相同**）。报告 `$HOME/w28a-report.md 0675cd3e196b3d78`。
#     ⚠️ **一处射程缩减（如实记录，今天不产生假绿）**：副本模式下反向扫描的候选集 = **被镜像的子树**（真树 **82 个 `*.csproj` 文件** → 副本 40 个）；42 份缺口件里带规范 `<Import>` 的 = **0**（E7a/E7b 逐字节相同即证）⇒ 只有**整树 `cp -a`** 才与真树等价。
#     ⚠️ **两处口径已写窄（原注释写宽了，主控当场改）**：① `unlisted` **只在 `grep -cF "$IMPORT_LINE" > 0` 时才可能触发** ⇒ 它只能看见"**已经带了规范 `<Import>` 的文件**"，一份**新加的、本该接线却没接线**的工程**这一档看不见**（已登记 `D-G21`）；② 判据只查**一条**排除（`BuildHygiene.props:61` 的 `obj/**;bin/**`，`grep -cF` = **1**），原写"那两条"是错的。
#   【④ 第 `[10]` 步 `DEFECT-REGISTRY` —— `D-G15` 的机器对账（`#27` 首次接线）】问题 = **同一个缺陷编号的登记地点是散的**（`D-G2`/`D-G3` 只在 `docs/CURRENT-STATE.md` 里有陈述、缺陷册 `KNOWN-DEFECTS.md` 里没有条目），而"某编号在哪些文件里、有没有漏登记"**没有任何机器会红**。
#     **判据**：把四个 **route 件**（`KNOWN-DEFECTS.md`/`CURRENT-STATE.md`/`handoff.md`/`ACCEPTANCE-BASELINE.md`）现场抽出的 `D-` 编号集合，与**声明件** `defect-registry-declared.tsv` **双向**比对并逐条点名：① 声明了而 `req=` 指名的某 route 件里没有 ⇒ `FAIL declared-id-missing-in-route`（**声明是伪证**）；② route 件里有而声明里没有 ⇒ `FAIL undeclared-id-in-route`（**新登记没被声明**）。三态 `rc=0/1/2`。**纯读、零 `dotnet`**。
#     **为什么声明件不是"又一份手工清单"（`D-R4` 同族）**：它由核对器自己的 `--emit` **机械生成**（`req=` 直接由现场出现点推出）⇒ **它不是权威、是一个必须与现场同步的快照**；`DEFREG_DECLDRIFT` 行把"快照之后 route 件又变了"如实打出来（**诊断行，不判红**）。
#     **现场正极性（逐字）**：`DEFREG_DECL=n=61 route_ids=61 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*`、`DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN`、`DEFREG=PASS declared=61 route_ids=61（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）`、`rc=0`。
#     **反极性**：`--selftest` **10/10**（`DRC_SELFTEST=PASS cases=10 … not-as-expected=0`，`rc=0`）；**逐例同时断言"值"与"`rc`"**（三态 0/1/2）—— 其中 **5 例断言"必须红"**（含"声明里有、route 里删掉"与"route 里多一个未声明编号"**两个方向**）、3 例断言"必须 NOINFO"（缺声明件/0 条/畸形行）、2 例正极性。
#     **✅ 主控独立复核（不是照抄它的自报）**：主控用**自己的** python 复算两侧集合 ⇒ 现场并集 **61** / 声明 **61**、**双向差集皆空**、`req` 逐条声明也全对得上。⚠️ **复核中主控自己先错了一次**：第一版匹配器用 `(?<![A-Za-z0-9-])` 做左界 ⇒ 把 `TOOTH-D-F1b-ABSENT` 这种**嵌在更长标识符里的编号**全判成"不存在"，一度报出 **4 处假违规**。真相 = 核对器用**最长匹配**（`TOKRE="\bD-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*\b"`）⇒ `D-F1b-ABSENT` 是**独立编号**、`D-F1b` **不会**被它冒充。⇒ **错的复核器比没有复核更危险。**
#     ⚠️ **两处口径必须读窄**：① `present=` **不进判据**（只作诊断行 `DEFREG_DECLMETA=`），因为它含 `known-red*.json` 这类**会被其它车道并发改**的件 ⇒ 判红会变成**假红**（**主控裁定维持不判红**）；② `--selftest` 汇总行的 `pass=`/`fail=`/`noinfo=` **数的是"现场 `got=` 值的个数"，不是"通过例数"**（今天 `pass=2` 极易被误读）⇒ **权威字段是 `not-as-expected=`（= 0）**；**主控已把这个坑逐字写进 `[10]` 的注释块**（已登记 `D-G23`）。
#   【⑤ 登记与更正】**新登记**：**`D-G19`**（列级闸**只给 `START` 一列**钉下限 ⇒ `hasOverflowed` 那列仍可静默；⚠️ **措辞更正** = 该列**红今天已有牙**、"缺的只是判定面/退化"这一半；射程更正 = **`tab-zero`/`tab-rtl` 的 `OVERFLOWED` 整列 NOINFO（判定行=0）**，下限工具在它们身上**无效**、故**刻意不声明**）｜**`D-G20`**（门禁**不读**探针自带的逐例对账行 ⇒ "汇总行与逐例行不一致"抓不到）｜**`D-G21`**（`[9]` 的反向扫描只能看见"已带规范 `<Import>` 的文件" ⇒ 新增一份"**该接线却没接线**"的工程**零东西会红**；且暴露触发**只在命令行**（仓内 `.sh`/`.py` 里 `-p:BaseIntermediateOutputPath` **命中 0**）⇒ **今天无法用推导名单关洞**）｜**`D-G22`**（**`verify-all.sh` 自己不在 `inputs_fp()` 覆盖面里、也没有自指指纹牙** ⇒ 波中改门禁**不会有任何东西红**；本波实测它在**一趟里被改了 5 次、全程零机器红**）｜**`D-G23`**（`[10]` 自测汇总行**字段名会误导**）｜**`D-G24`**（`known-red.json:69` 的 `leg_resolution.cross_check` 是**没有任何读者的散文**，而它 4 条里 **3 条与现场不符**、结构化 `arm_logs` 却 **5/5 正确**）｜**`D-G25`**（`caliber.judgment_version` 的"**同趟推进**"要求**没有任何读者** ⇒ 忘推进不会红）。
#     **对旧记录的更正（4 处）**：① **`D-G15` 的现场证据自我 disqualifying** —— `grep -c 'D-G2\|D-G3' KNOWN-DEFECTS.md` = 0 **今天不成立**（实测 **4**：`D-G20` 的前缀、`D-G15` 条目正文自己两处、`D-R8` 那句"可复用到 `D-G3`"）⇒ **登记这个缺陷的动作本身毁掉了它的现场证据**；**不否定 `D-G15` 的结论**（`D-G2`/`D-G3` 确无自己的缺陷册条目），否定的是**那个查询串作为证据**（正确读法 = `\bD-G2\b` 精确匹配 ＋ 钉版本）。② `CURRENT-STATE.md` 里 `D-G2`/`D-G3` 的行号 `:368/:369` **已过期**，今为 `:384/:385`。③ **"两文件 `D-G` 条目 10 vs 14" 口径未重现**（今天 KD 标题 18｜CS 表格行 6｜any-token KD 20 vs CS 17）⇒ **如实标"未重现"，不硬凑**。④ **`D-G19` 的判据形状与射程两处措辞**（同上）。**另更正一处主控自己在 `KNOWN-DEFECTS.md` 的口径**：**42 / 40 / 38 三档**（40 = 文件数 = `<Import>` 元素数；42 = "含 `Import` 子串的行"数，含 2 行注释散文；38 = `#21` W21B 的**动作计数**，史实），并**加注不覆盖** `#26` 的历史写法。⚠️ **`ACCEPTANCE-BASELINE.md:51` 那处"42"主控裁定不改** —— 它在 **`#26` 冻结块正文里**，改它会让 `#26` 记录的**整份 sha 变成不可复算**，**那正是 `D-G23`（`#23` 的 sha 今天不可判定）被我登记为缺陷的形态** ⇒ **宁留一处已加注的旧数，不制造一处不可复算的历史**。
#   【位移账】**九位相对 `#27` 开工快照（`$HOME/w27-pre-lanes.sha`，2026-09-17 17:47:37）**：变化的位 = **`['pf']`**（`byname` 逐个断言：`bridge`/`pc`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` **逐位未动**；`hbtextline` **逐位未动**）⇒ **表外位移 = 0**（预登记 §2/§5 的停条件①②③④**全未触发**）。**仪器位移 5 件＋2 新建**（见上）。**`inputs_fp` 与 `BRIDGE_SRC_FP` 逐位相同。**
#   【波尾与门禁】`close-wave.sh --skip-verify-all`（**rc=0**）⇒ `[1/6] integration-wave.sh` rc=0、`native shim` **跳过重建**（源码不比权威件新）、**桥源指纹一致**（`b6acdba4f01599d8` == `b6acdba4f01599d8`）⇒ **无需重发**、身份自检：桥源指纹两侧一致 ✅／生成物指纹 `state=ok` ✅／**应用器审计 `miss=0`**（`APPLIER_AUDIT_SUMMARY appliers=22 ok=80 miss=0 red=0`）✅／**输入稳定性 波前==波后 == `0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8`**（期间无手写改动）✅；⚠️ `APPSYNC` 非 PASS（**逐条见日志**；与 `#26` 同一族，见下）。
#     五臂 **`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc`**、`GATE_REASON=all-as-registered`、**`GATE_COLUMN=PASS state=READINGS-OK arm=tab-oracle-anchor col=START 判定行=615 红=0 绿=615 NOINFO=0 字形释放行=194 非零真值行判定=171 judged_min=615 released_min=194`**、`rc=0`。
#     `verify-all` **rc=0 / 16 步 / 871 通过 2 跳过**（第 `[4]` 五臂 ✅、`[5]` `Start` 列 ✅、`[6]` `FrameProbe-frame` ✅、`[7]` `BASELINE-SHA` ✅、`[8]` `ARM-LOG-SHA` ✅、**`[9]` `BUILD-HYGIENE` ✅**、**`[10]` `DEFECT-REGISTRY` ✅**）。⚠️ **步数口径：`#15`=9、`#16`–`#20`=10、`#21`–`#23`=11、`#24`=12、`#24` 收官起=13、`#25`/`#26`=14、`#27` 收官起=16**（旧步数读数不能互相引用）；机器证 = `grep -c '^run_step "' verify-all.sh` ⇒ **16**。
#   【⑥ 判据读数】应用门禁**两趟**（`run_dir=…/w27-gate1`、`…/w27-gate2`；按 `D-G7` 逐字记录装置行）⇒ `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、**6/6 `BASELINE … result=PASS`**、六条机读行的 `config=pc:`/`pf:` **都是终态值** ⇒ **本波"零产品位移"的预测兑现**（`drawn`/`colors`/`frames`/`cross_ae` 应与 `#26` **逐位相同**）。
校验器全量（**静树**）⇒ `APPSYNC=MISMATCH`、`rc=1`，逐字计数：
#     `计数：OK=63  MISMATCH=1（STALE=1  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0]  DIVERGENT=1  NO-AUTHORITY=39  LIB-COPY=0  SKIP(obj)=7  SKIP(stub)=6  SKIP(ref)=10  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0`。
#     **关键项**：`MISMATCH=1`｜`MISSING=0`｜`UNEXPECTED=1`｜`DIVERGENT=1`｜`RETIRED=0`｜`AUTH-MISSING=0`｜**`BRIDGE-ANCHOR=0`｜`BRIDGE-NOINFO=0`**。
#     ⚠️ **本波 `pc` 未变**（与 `#26` 同一 `pc` 世代）⇒ **可直接与 `#26` 的记录逐字比对**：`#26` 记的是 `MISMATCH=1[STALE=1] MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1] DIVERGENT=1 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`。**逐字相同 ⇒ "本波零新增红"成立；不同 ⇒ 必须逐条点名并解释**，**不许**用"长期在册"一句话盖过去。
采样器（v2）每 20 s 一行，共 **83 样本**（18:01:15 → 18:28:36）：`MemAvailable` **谷底 2048 MB**（18:03:15）／均值 3037 MB；`SwapFree` **谷底 885 MB / 2047 MB**（18:08:35）；`load1` 峰值 **9.42**；采样 `dotnet` 峰值 **6**；**告警 0 条**（无）。
#     ⚠️ **本波并行车道上限仍是 7**（纪律 57），实际最多 **4 条**（W27D ＋ W28A/B/C），其中**三条零-dotnet 车道与主控的重活同跑**（`close-wave` 重建 ＋ `verify-all` 测试套件 ＋ 两趟应用门禁）⇒ 谷底仍**未破警戒线**（阈值 `avail<800` / `swapfree<100`）。
#     ⚠️ **主控自纠（本波第 6 处）：第一版采样器报数口径错** ——
#     `read -r _ tot used free shared buff av < <(grep -E '^Mem' /proc/meminfo | awk '{printf "%s ", $2}')`
#     取的是**每一行的第 2 字段**（按 `/proc/meminfo` 的**行序**），而 `read` 把这些值**按位置**塞进 7 个变量 ⇒ 实测打出 `avail=0MB`，并且**当场触发一条假 ALERT**（`[ 0 -lt 800 ]` 为真）。
#     ⇒ **"从 `/proc` 读数"也必须逐字段具名取**，不许靠"行序 ＋ 位置变量"隐式对齐；v2 改成按名字取，并对"字段非法"直接 `exit 9`（**读数缺失必须与读数很小可区分** —— 否则 `0` 会伪装成一个"极小但合法"的读数，并每 20 秒报一次假警）。
@MEM2@
#   【⑨ ⚠️ 一个**仍未接线**的假绿窗口（本波查明、留给 `#28`）】`OVERFLOWED` 那一列**今天没有下限牙**（`D-G19`）：W28C 在**副本**上把该列的 `判定行` 由 **421 改到 400** ⇒ **今天的门禁仍 `rc=0` / `PASS` / `GATE_REASON=all-as-registered`，且 stdout 与未失真那趟逐字相同**；整条汇总行删除也同样 `rc=0/PASS`。⇒ **那是假绿**（旁证：`tab-anchor.log:1342` 的 `TAB_LINES OVERFLOWED … 判定行=421 NOINFO=194 … 真值True=22`）。**方案的补丁与 6 档反极性已备**（`$HOME/w28c/gate-w28c.diff 5d1c5c322e222715` ＋ `registry-w28c.diff b5ffad3ed9a7f2b1`，`judged_min=421`，**不需要重取臂/不需要动 `arm_logs`/0 次 `dotnet`**）⇒ **`#28` 头号项**。**同族另两条也留给 `#28`**：`D-G20`（门禁不读逐例对账行）、`D-G25`（`judgment_version` 的推进无牙）。
#   【本波的九条车道：两条落地 ＋ 五条只读交付（全部**零 `dotnet`**，与 `#26` 一致）】`W27A`（`build/MilBridge/W27A-report.md d74700706abb9e39`，列级闸接线，**已由主控现场复核**）｜`W27B`（`build/MilBridge/W27B-report.md dbef220a99cfd925`，`D-G17`）｜`W27C`（`build/MilBridge/W27C-report.md 7adcad13e3e38d43` ＋ 新件 `build-hygiene-import-check.sh 2607d0ba856f169a`，`D-R8` 回归牙）｜`W27D`（`build/MilBridge/W27D-report.md 83cd40cf1e9d6c97` ＋ 新件 `defect-registry-check.sh 35838bf64f658447` ／ `defect-registry-declared.tsv`，`D-G15` 机器对账）｜`W27E`（`$HOME/w27e/lastchar-width.md debd498f0e72148b`，`D-G18` 末字符宽度退化）｜`W27F`（`$HOME/w27f/wiring-insert.diff f6374df504d369d0`，`D-T5-R` 接线重锚）｜`W27G`（`$HOME/w27g/recipe.md e2c803a6b17e8f6d`，`D-G11` 落地时序与补丁可用性）。**波尾追加三条只读车道**（见下"波尾车道"）。
#   **本波最值钱的四条（按价值）**：
#     1. **把 `#26` 留下的假绿窗口关上（`D-G14` 的"下半身"）**：列级读数**第一次进五臂门禁**（新机读行 `GATE_COLUMN=`），并把下限钉在**实测值本身**；四档反极性实测（含"退化 ⇒ `FAIL column-gate-regressed`"与"删声明 ⇒ `NOINFO`"）；**13 个既有读取点一个没动、`RED_BY_FIELD` 6/6 KEPT、`TLINE_GATE=` 既有字段逐项与 `#26` 相同** ⇒ **判据面只扩不缩**。
#     2. **两颗新牙从"交付"变成"每趟都跑"**：第 `[9]` 步（`D-R8` 的接线回归）与第 `[10]` 步（`D-G15` 的编号对账）⇒ 从此**每趟全量回归**都会核对"构建卫生接线"与"缺陷编号的双向一致性"。两颗牙都不是"作者自测即完成"：`[9]` 另派车道在**真副本**上做了 6 种坏法的独立咬合取证（真树零污染、聚合 sha 逐位相同），`[10]` 由主控**用自己的脚本**复算了双向集合差集（**并因此抓出我自己复核器的一个真错**）。
#     3. **"跳过"第一次上屏并带上限**（`D-G17`）：`--no-x` 再也不许**静默关牙而全绿**；X 不可用时必须打 `SKIP_GUARD=REDUCED` 并逐字写明"射程缩减"。
#     4. **一连串"预登记/文档里的数也是错的"**：本波至少 **6 个数**被现场推翻 —— `verify-all.sh` 头注释的"不带锚得 17"（真值 **20**，且**差额不是常数**）｜`CURRENT-STATE.md` 的"**当前期望是 13 步**"（真值 **16**）｜`[X11Fact]` 的"8 条"（真值 **26**，且**同文件已写着 26**）｜`ARCHITECTURE.md` 的"8 条需真 server"（真值 **18**）｜**预登记自己传下去的"42 条 `Import` 行"**（真值 **40**）｜`verify-all.sh` 的"那两条排除"（真值 **1**）。⇒ **纪律 49 的又一次现场证明：凡引用数必须现场算，连"我自己上一段写的数"也不例外。**
#   **波尾车道（`#27` 收官时追加的三条只读车道，全部零 `dotnet`）**：
#     · **`W28A`**（`$HOME/w28a-report.md 0675cd3e196b3d78`）：`[9]` 的**独立咬合取证**（在真实 40 份 csproj 的 `cp -p` 副本上做 6 种坏法 ＋ 1 个射程探针；阴性对照；真树聚合 sha 开工==收工逐位相同；`find -type f -links +1` = 0）。**它报出的两处口径失真**（"两条排除"、副本模式候选集收缩）**主控当场改进 `verify-all.sh` 与本文件的 ③**。它自报**未做到 5 条**（未证 `CS0579` 端到端（要 `dotnet`）、未做整树 `cp -a`、"删整个 `PropertyGroup`"系代码推出未实测、非 UTF-8/权限位未测、整树同射程对照未做）⇒ **如实保留**。
#     · **`W28B`**（`$HOME/w28b-report.md a86efb3c9e2a018b`）：文档口径一致性侦察（**零仓内改动**），交出**精确到 `文件:行` 的改单**并**逐条点名"不许改"的 30 余处史实**；推翻"得 17"、纠正 `[X11Fact]` 的真身位置、发现 **"82" 有两个不同对象撞成同一个数**、报出纪律清单 **1–60 编号无缺无重** 与 `:408` 行内重复、`:500–502` 顶格子项两处排版事故。**主控采纳它几乎全部改文**，但**推翻它一条建议**：它建议改 `ACCEPTANCE-BASELINE.md:51` 的"42"，**主控裁定不改**（理由见 ⑤：会把 `#26` 的整份 sha 变成不可复算）。
#     · **`W28C`**（`$HOME/w28c-report.md 53aed532200ccab9`）：`D-G19` 的**方案成稿 ＋ 假绿实证**（副本上 `OVERFLOWED 判定行 421→400` ⇒ 今天仍 `rc=0/PASS`；整条汇总行删除 ⇒ 仍 `rc=0/PASS`），并**更正 `D-G19` 的判据形状与射程**、顺带查出 `D-G24`（`known-red.json:69` 散文 3/4 与现场不符而结构化 `arm_logs` 5/5 正确）与 `D-G25`（`judgment_version` 推进无牙）。它**自曝第一版草稿的"张冠李戴"缺陷**（把附加列并进 `col_verdict` ⇒ `OVERFLOWED` 退化时既有 `GATE_COLUMN=FAIL … col=START` 报错列）并已修留证。
#   **主控自纠（本波 6 处，全部留档）**：① 独立复核 `[10]` 时**我的匹配器先错**（左界 `(?<![A-Za-z0-9-])` 把 `TOOTH-D-F1b-ABSENT` 里的编号判成"不存在"，一度报 **4 处假违规**）—— **错的复核器比没有复核更危险**｜② 我先用不带 `upstream`/`.artifacts` 排除的 `find` 数出 **135** 份 csproj 并据此**怀疑 W28A 的 82 是错的** ⇒ **是我错、它对**（脚本自己的 `collect_candidates()` 就是 82）｜③ `[9]`/`[10]` 注释里**我把口径写宽了 3 处**（"新加的 csproj 没进名单 ⇒ 抓得住"、"那两条排除"、把"82"当单一对象）—— **两处由车道当场顶回、一处由 W28B 查出**｜④ 头注释里我抄来的"不带锚得 17"**是错的**（真值 20，且差额不是常数）⇒ 改成"别引用任何写死的差额"｜⑤ 我用 `findall` 带捕获组测 `TOKRE` ⇒ 得到 `['-ABSENT']` 而**误以为最长匹配坏了**（真因是 `findall` 返回组内容）｜⑥ 第一版内存采样器**字段错位 ⇒ 打出假 `avail=0` 并触发假 ALERT**（见 ⑧）。
#   【W27A 的一处仪器事故与裁定】W27A 的自检夹具顺着**硬链接**打穿了仓内 `arm-logs/tab-anchor.log`（`open(p,"w")` 原地截断），它 **4 分钟内原地复原**、内容 `574d012a41a3db06…` 与 `generation.arm_logs` 声明**逐位相同**（6 份独立 `cp` 副本互证，核对器 `PASS`）。**唯一残留位移 = mtime `14:31 → 17:52:10`**。**主控裁定：接受**（内容零位移；弱配对只拒"日志早于仪器"，"更新"方向不影响；`arm_logs` 钉的是 sha 不是 mtime）。⇒ 已登记进 `KNOWN-DEFECTS.md` 并**加强纪律 60**（硬链接沙箱是**双向**的：`open(w)` 穿透、`sed -i` 会 de-link、`cp` 安全）。
#   【W27F 的交付已过期（如实记）】它的接线 diff 是在"14 步"版上重锚的，而本波收官时 `verify-all.sh` 已是 **16 步** ⇒ `$HOME/w27f/wiring-insert.diff` 的锚点**再次过期**；`D-T5-R` 的"有牙"步骤**留给 `#28`**（它是**构建者**：首跑有 12 个 `--nocatch` 格无独立记录 ⇒ 不许在没有对照读数的情况下落地）。
#   【`#28` 候选（按价值排序，全部带判据与成本）】① **`D-G19`**（给 `OVERFLOWED` 钉下限；补丁与 6 档反极性已备，**零世代成本、不需重取臂**）｜② **`D-G20`**（门禁读逐例对账行）｜③ **`D-G21`**（让"该接线却没接线"也能红 —— 需要"新增 csproj 必须显式声明需要/不需要 BuildHygiene"的判据形状）｜④ **`D-G22`**（给 `verify-all.sh` 自己一个步数/步名自检；⚠️ **不许做成自指改写**）｜⑤ **`D-G25`**（给 `judgment_version` 一个读者；⚠️ 先想清"谁有权定版本号"）｜⑥ **`D-T5-R`** 的有牙步骤（**是构建者**，需先取 12 格的独立对照读数）｜⑦ **`D-G11`**（读者目录必须**先于/同趟**落地，否则 `close-wave` 在 `[1/6]` 就 abort；`inputs_fp` 会变）｜⑧ **`D-G24`**（删掉 `known-red.json:69` 的散文，只留结构化 `arm_logs`）｜⑨ **把 `tline-gate.sh`/`known-red.json`/`arm-logs/*` 纳入 `fp_inputs()`**（W28C 实测它们**不在** 110 条覆盖集里 ⇒ 改门禁不会被"波前==波后"发现，与 `D-G22` 同族）｜⑩ **`D-G23`**（`[10]` 自测字段改名）。
#   **两条"仍未取到"（不许当绿）**：① `D-T5-R` 的 12 个 `--nocatch` 格在本波**没有独立对照记录**；② `D-G18` 的真机侧**无读数**（它是读上游源码得出的推论，W27E 的离线模型与探针有 5 条 MISMATCH 且 `wSkipTab=61` vs 模型 14 **差 47 复现不出**）⇒ 如实标 `未取到`。
BASELINE tier=default rep=1 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:3d44e756475b5dd4,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w27-gate2
BASELINE tier=default rep=2 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:3d44e756475b5dd4,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w27-gate2
BASELINE tier=default rep=3 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:3d44e756475b5dd4,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w27-gate2
BASELINE tier=env rep=1 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:3d44e756475b5dd4,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w27-gate2
BASELINE tier=env rep=2 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:3d44e756475b5dd4,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w27-gate2
BASELINE tier=env rep=3 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:3d44e756475b5dd4,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w27-gate2
# ⏪ **（历史，已被 `#27` 取代）**# RE-FROZEN #26 —— ✅ **当前冻结基线** —— 内容 = **① `D-G14` 列级覆盖闸（＋`D-G12` 字宽列）** ＋ **② `D-G10`：`verify-all` 绿屏也印自报口径** ＋ **③ `D-G13`：`--selftest` 的假红改成 `NOINFO`** ＋ **④ `D-G9`：结构化 `arm_logs` + `verify-all` 第 `[8]` 步** ＋ **⑤ 登记与纪律（`D-G15`–`D-G17`、纪律 52b/56–59、51 与 §9.1b 更正）**（预登记 `docs/WAVE26-PREREGISTRATION.md`）。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行（**本处照纪律 53 不重述值**）。
#   **⭐ 本波是"零产品位移、仪器大改"的一波（第一次）**：
#     · **九位里只有 `pf ebbe3bab855cdd55`（7122432 B）变** —— 环成员，**由波尾 `integration-wave.sh` 重编引起**；`bridge`/`pc`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` **逐位未动**；
#     · **`hbtextline` 一个字节未动 = `e89fed55fd8e32bc`（290825 B）** ⇒ **世代绑定三项全未变** ⇒ 不重取五臂、不重钉 `known-red.json` 的世代三项；
#     · **`inputs_fp` 与 `#25` 逐位相同 = `0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8`**（本波**完全不碰** `patch-*.py`/`port-lib.py`/两个波脚本/`build/shims/**`/`src/WpfGfx.Linux/**`）；
#     · `BRIDGE_SRC_FP=b6acdba4f01599d8`（未变；桥未重发）。
#   **变的都是"冻树回路里的仪器"（不在九位里，但都要在本块留档）**：`CoverageProbe/Program.cs dea2a02cf8bab55a → 2477901979795979`｜`verify-all.sh 741b638acaf02e7a →（W26B 落 `D-G10`）ff961780c130734b →（主控补头注释 12→13 步）927fce4467d2de70 →（主控接 `[8]`）fe22c60399aa31be →（主控修 `echo` 里的反引号）见现场`｜`frame-step.sh 37f27df68e52bf8c → a8800cd897606cf7`｜`check-applocal-sync.sh 7bc9364091a28fd4 → 27ecae1580a07527`｜新建 `arm-log-sha-check.sh`｜`known-red.json e623d2b17d948e3b →（W26D 加 `arm_logs`）5aead470c23a99ff →（主控重注入）见现场`｜**三支 `tab-*` 臂日志重取**：`tab-anchor 56abc845dbd29e93 → 574d012a41a3db06`、`tab-zero 424d4c6d5ab121cb → 78204619fa5b4eee`、`tab-rtl 5e4d9ef3c64f7d7e → cbaa579c547b4ac3`（`tline`/`textlineproto` **未动**）。
#   【① `D-G14` 列级覆盖闸（＋`D-G12`）——**本波唯一的"真实覆盖率收益"**】问题 = 覆盖闸是**整例级**的（`Program.cs:1367-1386`：`∃ch 使 NominalGlyph(常量字体,0,ch)==0` ⇒ `continue`，整例一个字段都不判）⇒ 把**与字体无关的列**（`TextLine.Start`，真值 ≡ `ParagraphIndent`）也一起埋掉。
#     **正向读数（`tab-anchor`）**：`Start` 列 **判定行 421 → 615、`NOINFO` 194 → 0、红 0**；`字形释放行=194`、`非零真值行判定=171`（两个上界都打满）；`OVERFLOWED` 列 421/194 **原样**。
#     **RTL 收益**：**真值侧可达 33 行**（`D-paraindent` hebrew：PI24 15 + PI48 18）、**我方实判也是 33 行（33/33）** —— 落在预测区间 `[24,33]` 的**上端**（148 例全部格式化成功、无例行数不足）。
#     **⭐ 既有读数零位移是机器证的（不是声称）**：436 条 `CASE` 行 `diff` **差异 0 行**；`合计`/`最大差` 行 **IDENTICAL**；288 例逐例 `(结构,位置)` 字典相等；`FAILCASE 0→0`；**剔掉 `NOINFO=面缺字形` 后既有 421 条 `START` 逐例行差异 0 行**；`NOINFO=行数不符` **0 处**。
#     **三级反极性（全部实测；每档 shim `cmp` 复位）**：正极性 **红 0**｜`Start => 0`（`D-T6-c` 复发）⇒ **红 171**＝既有 138 ＋ 新释放 33（预测逐位中）｜`=> PI+24` ⇒ **红 615**｜补测 `=> 24.0` ⇒ **红 484**（证明 24 与 48 未被吞）。**四档满足 `红+绿+NOINFO == 615`**。⚠️ `NOINFO=行数不符` 通道**本趟未被行使 ⇒ 不读成"已证"**。
#     **`D-G12`（字宽列接线）**：`perChar[].width` 真的接进比较（容差 0.05，与 `xFromLeftDip` 同口径）；缺省与 `=1.0` 两趟**逐字节相同**（`pass 39/fail 18`，今天**不红**）｜牙级 `=2.0` ⇒ **可判字宽 97/97 全红** ⇒ **有判别力**。
#     ⚠️ **它自己抓出并修正了一版"把绿洗成红"**：第一版把 39 例判红，其中 **19 条真值字符是 `\t`**（真值宽是**网格推进量** 82.653333 = 96−13.346667、**不是字形宽**）、**16 条我方宽=0**（`GetTextBounds` 退化、**根本没量到**）⇒ 最终口径 = **只比真测量值**（97 条），其余 **64 条一律 `NOINFO` 不计红绿**。**收益要按 97 条读、不是 356 条**（356 = 判定集 178 ＋ 跳过集 178）。
#     ⚠️ **两条仪器局限（不读成绿）**：① 门禁要求五臂齐备 ⇒ **无法**用三支 tab 臂做门禁级 A/B（本件改用"门禁所读那几行的逐字节/逐值对比"，更强）；② `D-G12` 的"我方零宽"3 条都在**末字符** ⇒ 疑似**既有 `GetTextBounds` 末字符区间退化**，**只计不可判、未修** ⇒ 已列入 `#27`。
#   【② `D-G10`：`verify-all` 的**绿屏第一次印出自报口径**】`verify-all.sh:104`（内层 `fi` 之后/外层 `else` 之前）回显 `^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO)`（`head -8`）＋`:121-124` 红分支**零命中兜底 `tail -12`** ＋`:129` 印出被 `cp` 的日志路径。**机器证"只加不删"**：`verify-all.sh` 与 `frame-step.sh` 的**改前独有行 = 0 / 0**（+29 / +17）；**既有终局行 `FRAME_STEP=PASS` 文本逐字节未动**（改前 `:189` ≡ 改后 `:197`）。
#     **本波 `verify-all` 两趟的绿屏实测**：`[7] BASELINE-SHA ✅` 下跟三行 `· 自报口径 BASELINESHA=/BASELINEGEN=/BASELINEDUP=`；`[8] ARM-LOG-SHA ✅` 下跟 `· 自报口径 ARMLOG_SHA=PASS shape=flat … required=5 declared=5 pass=5 fail=0 noinfo=0` ⇒ **"绿的时候判了什么"从此上屏**。
#     **真漏报例（成对已给）**：`tline-gate.sh --logdir`（缺参数）⇒ 日志 26 B、**`rc=3`、旧 grep 0 命中** ⇒ 改前屏上**只有 `❌ (rc=3)`**；改后 = 兜底 `| NOINFO --logdir 缺参数` ＋ 日志路径。
#     **尖锐问题已答**：13 步里"`=NOINFO` 却 `rc=0`"**今天不存在**（7 处打印点同分支非零退出 ＋ 9 份真日志机器证）⇒ 新回显**不会**把 `NOINFO` 误读成失败（只回显、不改 `rc`、不并第四态）。主控裁定：**不采纳"只印 `=PASS`"的加固**（那会把 `NOINFO` 从屏上藏起来，与"`NOINFO` 不许当绿、但也不该被藏"相反）。
#   【③ `D-G13`：`--selftest` 的**假红**改成 `NOINFO`】`check-applocal-sync.sh`：`SELFTEST_M2` 那条"两次取数之间仓库变了"**不再报 `FAIL`**，改报 `NOINFO`（判词行**打印两时刻的值**）；退出码三态 = `0` 全 PASS｜`1` 有子例 FAIL｜**`3` 有子例 NOINFO（本文件既有码）**。
#     **反极性①（该红的还红）**：真坏①（删"截断自称"分支）⇒ `SELFTEST_M2=FAIL`；真坏②（**印了但数字错**）⇒ `FAIL`（截断数不符）；真坏③（M1 删 `[写点]` 打印）⇒ `SELFTEST_M=FAIL`。**反极性②（只是仓库被改）**：沙箱确定性复现竞态 ⇒ 改前 `FAIL` rc=1 → 改后 `NOINFO` ＋ `SELFTEST=NOINFO` **rc=3**；且改后 M2 为 `NOINFO` 时 **O/P 仍继续跑**（改前 FAIL 时立即 exit、O/P 从未跑）。
#     **✅ 它这一趟是"加严"**：以前只查告诫**字样在不在**、**不查数字** ⇒ "印了但印错数"能过；现在 N 必须**逐位等于**枚举器自报值 ⇒ **实测"改前 18/18 PASS、改后 FAIL"**（`57c76545b3311337` vs `ac91c13136cdde49`）⇒ **它在旧自测里抓出一个真缺陷**。
#     ✅ **判定面位移 = 0**：静树整份输出改前/改后**逐字节相同**（`static.before.log` = `static.quiet.log` = `33e759c22654fb6d`，主控复核）；`--selftest` **18/18 PASS / rc=0**（主控独立复跑复核）。
#     ⚠️ **一条"自称、待复现"**：它报 `printf '%s' "$outM" | grep -q PAT` 在 `pipefail` 下因 `grep -q` 提前退出 ⇒ 写端 **SIGPIPE** ⇒ 假判"串不在"，自称 M 段 ≈6.6%/次、并撞到过 1 次。**主控按同形与更强形态共试 2500 次**（200 KB 位首 ×200、5 MB 位首 ×2000、**5 MB 位末** ×300，并统计管道 `rc` 分布）⇒ **假判 0 次、`rc` 恒 0** ⇒ **标"自称、待复现"**：在拿到复现配方或留档 transcript 之前**不许据此改判据**（站点计数"14 vs 主控数到 38 行"也不是同一口径）。
#   【④ `D-G9`：结构化 `arm_logs` ＋ `verify-all` 第 `[8]` 步】`known-red.json` 的 `generation` 加**结构化** `arm_logs`（键 = 臂日志文件名主干、**值 = sha256 全 64 位**），**外科式插入**（不整份 `json.dump`：删 0 行/增 16 行；主控重注入时**只改 3 行** = 三支被重取的臂）；`GEN_KEYS` 三项与 `entries` 四条**逐字节未变**。
#     **加未知键的安全性有自证**：门禁只按 `GEN_KEYS` 取键、`entries[*].caliber` 全脚本只读一处、**无 schema 校验器**；"只差 `arm_logs`"的两棵沙箱树跑门禁 ⇒ 归一化后 `cmp` **逐字节相同**、均 `PASS caliber=OK tree_gen=same`。
#     **⭐ 牙齿的现场实证（先咬后合）**：臂重取后、重注入前 ⇒ `ARMLOG_SHA=FAIL … pass=2 fail=3`，**精确点名三支臂**（`decl=旧值 live=新值`）；重注入后 ⇒ **`PASS pass=5 fail=0`**。核对器 `--selftest` **12/12**（其中 **7 例断言"必须红"**，含"声明 = 现场前 16 位 + 48 个 0 ⇒ 必红"）；**缺声明 ⇒ `NOINFO`、`rc=0` 只在全 PASS**；对**未落地的树**给 `NOINFO reason=arm_logs-absent`（**不假绿**）。
#   【⑤ 登记与纪律】新登记 **`D-G15`**（缺陷登记地点分散：`D-G2`/`D-G3` **只在 `CURRENT-STATE`**、缺陷册里没有；两文件 `D-G` 条目 **10 vs 14**）｜**`D-G16`**（`RED_BY_FIELD` 6 键而 `entries` 只用 3 键 ⇒ "未被使用的能力"是陷阱；⚠️ **主控裁决与点名者措辞相反**：门禁判红**不依赖** `RED_BY_FIELD`（`:383-384`/`:440` 是 `fail_n>0`、`:535-539` 注释"只要有 `FAILCASE` 行就判红"）⇒ **不是红条件失效**）｜**`D-G17`**（`verify-all` 对 `total_skipped` **零断言** ＋ X11 在**发现期** Skip ⇒ **`--no-x`/无 X 机器上静默关牙而全绿**）；对 `D-G13` 的**两条更正 ＋ 一条待复现**；把 W25K 的"① 有牙 24"校正为 **真牙 14／半牙 8／假牙 2**（另有 3 处重复计数 ⇒ 独立牙齿 **24→21**；**5 条 `①w` 不算牙** —— 校验器 `rc` 在 4 个调用点全被丢弃）。
#     **新立/更正的纪律**：**51 更正**（`tline-gate.sh` 是**纯读者**：`dotnet` 命中 0、10 处 `run.sh` 字样全是注释/读路径 ⇒ **零 `dotnet` 车道可以跑它**）｜**52b**（反极性动冻件时**要声明窗口**、动完**复原并自证**；**窗口内任何人读门禁都无效** —— 主控自己在窗口里取到的那次 `tree_gen=advanced` 读数**已作废**；**波尾第一步 = 核冻件复原**）｜**56**（给门禁造沙箱树要硬链接/真拷贝：`tline-gate.sh:191` 用 `find -type f` 找日志 ⇒ **符号链接会被整个跳过**；⚠️ 点名者那条"`stat -c %Y` 不解引用符号链接"的机制**主控复现失败、未立为纪律**）｜**57**（**并行车道上限 = 7**：第 8 条让 harness RSS 3.63→4.04 GB、**swap 一度只剩 7 MB**；"控内存"第一手段是限车道数，不是限构建）｜**58**（**审计报告本身也要连 artifact + sha**：被引件漂移会让"登记处（文件:行）"整列不可重放）｜**59**（**重取臂前必须换 `OUT` 并先归档**：`retake-arms-w23.sh:11` 写死的 `$OUT` 与 `arm-logs/*.log` **同 inode** ⇒ 原地重取会**截断上一世代证据**；⚠️ 主控两次给那条车道发警告都失败 ⇒ **保护只能做成仓库侧**，已把五支日志归档到 `$HOME/wfp-runs/w26-armlogs-archive-141549/`）｜**§9.1b 修订**（`--selftest` 静树**必要但不充分**）。
#     **主控自纠（本波 5 处，全部留档）**：① 误判一条只读车道"越界跑了 `frame-step.sh`"⇒ **撤回**（**`PPID` 定不到车道**：所有车道的 bash 都由同一 dsh 宿主派生；`list_agents` 显示当时唯一在跑的是有 `dotnet` 权限的那条、且预登记本就写着"第 `[5]`/`[6]`/`[7]` 步必须重跑"）｜② `grep -rl -- 'PAT' --include=…` 里 `--` 把选项变成操作数 ⇒ **过滤器静默失效** ⇒ 据此误判过一条引注（**纪律 55**）｜③ 一次九位对比**用错快照路径** ⇒ `awk` 打不开文件、每格与空串比 ⇒ 一度输出"九位全变了"的假结论｜④ 插登记块时**把 `D-G13` 的标题挤掉**（末尾误带一行标题）、并把 `§9.1b` 的修订脚本指向错文件 ⇒ 都被自己的核对拦下并修好｜⑤ 我插的 `[8]` 头注释把 `` `#26` `` 写在双引号里 ⇒ **反引号触发命令替换**（纯外观），已修。
#   【波尾与门禁】`close-wave.sh --skip-verify-all`（rc=0）⇒ `native_rebuilt=0`、`bridge_republished=0`、桥源指纹两侧一致、生成物指纹 `state=ok`、**应用器审计 `miss=0`**、**输入稳定性 波前==波后 = `0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8`**。
#     五臂 **`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2`**、`GATE_REASON=all-as-registered`、`rc=0`（**重取臂前后逐项相同**）。
#     `verify-all` **rc=0 / 14 步 / 871 通过 2 跳过**（第 `[4]` 五臂 ✅、`[5]` `Start` 列 ✅、`[6]` `FrameProbe-frame` ✅、`[7]` `BASELINE-SHA` ✅、**第 `[8]` `ARM-LOG-SHA` ✅**）。⚠️ **步数口径：`#24` = 12、`#24` 收官起 = 13、`#26` 起 = 14**（旧步数读数不能互相引用）。
#   【⑥ 判据读数】应用门禁**两趟**（`run_dir=…/w26-gate1`、`…/w26-gate2`；按 `D-G7` 逐字记录装置行）⇒ `WPTD_GATE=PASS`、**6/6 `BASELINE … result=PASS`**、六条机读行的 `config=pc:`/`pf:` **都是终态值** ⇒ **本波"零产品位移"的预测兑现**（`drawn`/`colors`/`frames`/`cross_ae` 与 `#25` 逐位相同）。
#   【⑦ `APPSYNC`（波尾、`pc` 定型后读）】校验器全量（**静树**）⇒ `APPSYNC=MISMATCH（MISMATCH=1[STALE=1 NEWER-DIFF=0] MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0] DIVERGENT=1 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`、`rc=1`，逐字计数：`计数：OK=63  MISMATCH=1（STALE=1  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0]  DIVERGENT=1  NO-AUTHORITY=39  LIB-COPY=0  SKIP(obj)=7  SKIP(stub)=6  SKIP(ref)=10  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0`。（与 `#25` 逐字一致：**本波零新增红**；三条红全是长期在册的 —— `FallbackCriteria` 那份 `UNEXPECTED-EQ`（`D-A1`）、`GeometryOracle` 那份 `STALE`、`WpfGfx.Linux.dll [Debug]` 的 2 种 sha（`DIVERGENT`））；**`BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`** ⇒ `D-A2-r` 那颗新牙**今天零红**。⚠️ 本波 `pc` 未变 ⇒ 与 `#25` 的 `pc` 世代相同，故可直接与 `#25` 比对。
#   【⑧ 内存信封】160 样本 / ~53 分钟：`MemAvailable` **最低 2628 / 均值 2860 MB**；`SwapFree` **采样最低 7 MB**；`load1` 峰值 **6.59**；采样 `dotnet` 峰值 **1**。⚠️ **谷底值必须单列**：**14:06:04 那一笔采样直接记到 `SwapFree=7 MB`**（swap 共 2047 MB，**一度几乎耗尽**）—— 也就是说 **20 秒节奏**这次**抓到了**瞬时谷底（不必然每次都抓得到：谷底只存在几十秒）。⚠️ **主控自纠（本条是"报数口径"的又一实例）**：我先前用 `awk` 统计时写的是 `s<ms`，而 **`awk` 对来自字段的字符串做的是字典序比较**（`"7" < "341"` 为**假**）⇒ 一度得出"采样最低 341 MB"的**错数**。⇒ **凡在 `awk` 里比数，必须写 `s+0 < ms+0`**（或先 `+0` 归一）。**根因 = 车道数开到了 8**：`node`（harness 自己）RSS 从 3.63 GB 涨到 **4.04 GB**（构建峰值只有 0.6 GB）⇒ **本机的并行车道上限 = 7**（纪律 57）。另：占用大头是 harness 自己 ⇒ "控内存"的第一手段是**限车道数**，不是限构建。（本波告警共 1 条：ALERT 14:06:04 avail=3330MB swapfree=7MB）
#   【⑨ ⚠️ 一个**未接线的假绿窗口**（本波查明、**故意留给 `#27`**）】`#26` 的只读车道 W26H 用"逐字抽出解析器"做了 **12 行判定矩阵**，其中一行是：**列级闸"放行了但一行没判"（`字形释放行=0`）＋ 今天的门禁 ⇒ 仍 `PASS/rc=0`** ⇒ **那是一处假绿**（门禁对列级读数**零读取点**；`grep TAB_LINES START/OVERFLOWED tline-gate.sh` = **0**）。**接线草稿已备**（`$HOME/w26h/gate-wiring.diff`，`+106/−5`、**无读取点被删或放宽**）：`generation.column_gate` 声明 ＋ `判定行<judged_min` 或 `字形释放行<released_min` ⇒ `FAIL column-gate-regressed` ＋ 新键 `列START·红` ＋ 机读行 `GATE_COLUMN=`。
#     **主控裁决 = 留到 `#27`**（它要动**门禁的 judge 版本** `/2 → /3` ＋ `RED_BY_FIELD` ＋ 登记表 `judgment_version`/`pending`，属**世代级仪器改动**，应与它自己的预登记同趟做）。**今天的暴露面**：读数已打满（`判定行=615`、`字形释放行=194`）、臂已重取 ⇒ 只有当**将来**有人让"释放行数"悄悄变少时才会静默变绿 ⇒ **`#27` 头号项**。
#     **同矩阵另两行也值钱**：**"释放列真红" ＋ 原门禁 ⇒ `FAIL/unregistered=1`** ⇒ **这一半牙齿今天就有、不需要接线**；**"把那条红登记进 `entries`" ⇒ `PASS registered=5 unregistered=0`** ⇒ **新列红是可登记的**（但今天 `RED_BY_FIELD` **没有列级字段** ⇒ 登记不了 ⇒ 见 `D-G16`）。
#   【本波的九条车道：一条落地 + 八条只读（全部零 `dotnet`，除落地那条）】`W26A`（`build/MilBridge/W26A-report.md 5244e218631572ee`，`D-G14`+`D-G12` 落地）｜`W26B`（`209deb193af68ef4`，`D-G10`）｜`W26C`（`f58dcba766731ebe`，`D-G13`）｜`W26D`（`491fd9f8def6d2d8`，`D-G9`）｜`W26E`（`$HOME/w26e/report.md 7210293bd3e7c016` + `hidden-only-step.sh d49ddf6e305d043d`，`D-T5-R` 有牙草稿）｜`W26F`（`$HOME/w26f/has-teeth-audit.md fe2ff7889e00b068`，审 W25K）｜`W26G`（`$HOME/w26g/report.md 10dfe35fcea1b154`，`D-G2`/`D-G3` + 回归牙方案）｜`W26H`（`$HOME/w26h/gate-wiring.diff 181336824ddfa7c7` + `report.md dcdf41a9a208d673`，列级闸接门禁草稿）｜（`W26I` 未开：`hasOverflowed` 更大判别面与 `D-G14` 同文件 ⇒ 按预登记延后）。
#   **本波最值钱的四条（按价值）**：
#     1. **真实覆盖率收益 + 零产品位移**：`Start` 列判定行 **421→615**、`NOINFO 194→0`、**RTL 非零 `Start` 由"行使 0 行"→"行使 33 行"**（33/33），而**九位只动环成员 `pf`、`inputs_fp` 一字未变**；既有读数零位移是**机器证的**。
#     2. **`D-G9` 的牙齿"先咬后合"现场实证**：臂重取后核对器 `FAIL pass=2 fail=3` 精确点名三支臂（**这正是 `#25` 之前"没有任何机器会红"的那种不一致**），重注入后 `PASS 5/5`；且它是 `verify-all` 的**第 `[8]` 步** ⇒ 从此**每趟全量回归都会核对臂日志的世代归属**。
#     3. **`D-G10`：绿屏第一次印出口径** —— 以前绿的时候只有 `✅`（"跑了什么、分母多少、覆盖面到哪"全在被 `rm -f` 掉的日志里）；现在 `[7]`/`[8]` 的绿行下面**自报口径**直接上屏，并附**一个真漏报例的成对读数**（缺参数 ⇒ `rc=3`、旧 grep 0 命中）。
#     4. **W26F 对 W25K 的对抗性审计**：把"① 有牙 24"校正为 **真牙 14／半牙 8／假牙 2**，并**当场抓到 W25K 自己犯了"看代码里有那个量就以为它在判"这一族错**（把 `RED_BY_FIELD` 的两个零引用键当成两条缺陷的牙）—— **审计报告本身也会犯被测对象的病**，这就是纪律 58 的来源。
#   **同波还查明/留下（按 `#27` 的价值排序）**：① **列级闸接进五臂门禁**（见 ⑨；草稿已备、无读取点被删；**接线＋钉下限＋重取臂＋重算 `arm_logs` 必须同趟**）｜② **`D-G17`**（`total_skipped` 零断言 ⇒ `--no-x` 静默关牙）｜③ **`D-T5-R` 变"有牙"**（草稿 `$HOME/w26e/hidden-only-step.sh`：32 格 ＋ 10 条断言含"判定例=0 ⇒ FAIL"与机制门；**是构建者**）｜④ **`D-R8` 的回归牙**（W26G 首推：唯一"已修且**完全**无牙"，判据零 `dotnet`/零世代/不动 `inputs_fp`；注意现场有 **40 个 csproj / 42 条 `Import`** 而文档写 38 —— 报数必须写清口径）｜⑤ **`D-R3` 的补法是坑**（`ResolverGuardProbe` 里 `return 0` 出现 **6** 次、`return 1` **0** 次 ⇒ 直接接线就是**恒绿假牙**）｜⑥ **`D-G11`**（产物↔生成物等号读者，1 笔 `pc` 重建；改 `patch-*.py` ⇒ **必须波前落地**）｜⑦ **`D-G15`** 的两份登记建机器对账｜⑧ **`D-G12` 的末字符退化**（3 条）等等。
BASELINE tier=default rep=1 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:ebbe3bab855cdd55,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w26-gate2
BASELINE tier=default rep=2 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:ebbe3bab855cdd55,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w26-gate2
BASELINE tier=default rep=3 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:ebbe3bab855cdd55,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w26-gate2
BASELINE tier=env rep=1 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:ebbe3bab855cdd55,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w26-gate2
BASELINE tier=env rep=2 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:ebbe3bab855cdd55,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w26-gate2
BASELINE tier=env rep=3 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:ebbe3bab855cdd55,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w26-gate2
# ⏪ **（历史，已被 `#26` 取代）**# RE-FROZEN #25 —— ✅ **当前冻结基线** —— 内容 = **① `D-T5-R` 修好（"全隐形段落"不再 abort；**只在应用器 ⇒ 零世代成本**）** ＋ **② `D-A2-r` 方案 B 落地（桥的只读绝对锚判据）** ＋ **③ 两条登记结算（帧结构族书面登记 + 13 份副本按世代）** ＋ **④ 收官时补的登记与草稿（`D-G9`–`D-G14`）**（预登记 `docs/WAVE25-PREREGISTRATION.md`，含 §9.1 波尾硬性动作与 §9.1b 静树纪律）。
#   ⚠️ **本文件的整份 sha 由 `build/MilBridge/tools/baseline-sha-check.sh` 机器核对**；**唯一声明处** = `docs/CURRENT-STATE.md` 里那条 `BASELINE-FROZEN` 机器行（**本处照纪律 53 不重述该值** —— 重述就是 `#23` 那次"三个文档两个值"的成因）。核对器**三态**、`rc=0` 只在全 PASS 时给出，`BASELINEDUP` 另禁"散文式 sha 声明"。
#   `inputs_fp=0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8`
#     （⚠️ 相对 `#24` 变了：**唯一变化组 = G1 `patch-*.py`**，且只改了其中 **1** 份 —— `#24` 的值是 `a87034194a66f7d18a9903a06337ad839cae8dba2669736abbec9cd8f6dee793`。）
#   `BRIDGE_SRC_FP=b6acdba4f01599d8`（**未变**；`bridge` 也未重发）
#   **⭐ 相对 `#24` 只有两位变**：**`pc 7374308a00c55572`**（4197888 B）｜**`pf eb48655d697a4188`**（环成员，**由波尾 `integration-wave.sh` 重编引起** —— `pc` 在车道重建后**没再动**，这正是**纪律 46** 的形态）｜`inputs_fp`。
#   **⭐ `hbtextline` 一个字节未动 = `e89fed55fd8e32bc`**（290825 B）⇒ **世代绑定三项（`run.sh` / `Parity.cs` / shim）全未变** ⇒ **不重取五臂、不重钉 `known-red.json`**（其 `generation` **仍是 `#23`** —— **这是设计**：登记表的 `generation` 标识的是门禁绑定那三项仪器）。**这一条是本波最重要的成本结论**：`D-T5-R` 的修法**全部落在应用器**，所以买到了"产品行为变了、世代成本为 0"。
#   **未变**：`bridge d567c26f197ec1e3`（4987840 B；`BRIDGE_SRC_FP` 两侧一致 ⇒ 波尾判定"无需重发"）、`windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf`。
#   【① `D-T5-R` 修好（`hiddenonly`：整段全是隐形 run）】**机制证**：`lastFail` `"没有 run properties"` → `"-"`、`relaxedHandled/Failed` `0/1 → 1/0`、**新计数器 `relaxedParaDefaults` `0 → 1`** ⇒ **兜底真的执行了**（不是"接了线没生效"）。
#     **落点 = 生成物 `:259-267`**（`if (props == null && paragraphDefault != null)`，位置在**两次 `props = run.Properties` 之后、两个失败点之前** —— 一行覆盖两处）；两站点 `:710`/`:817` 各透传一处，来源 = `paragraphProperties.DefaultTextRunProperties`。
#     **读数（`hiddenonly`，**必须带 `--collapsible`**；strict/lenient × 带 catch / `--nocatch` 四格）**：修前 `rc=1 RED-EXC-LS`（`A1/A2/A3` 全 FAIL、`Σ=0`）／`--nocatch` **`rc=134`**（标记停在 `T1 before FormatLine#1`）⇒ 修后**四格全 `rc=0` GREEN ∧ `A1/A2/A3` 全 PASS（`Σ=3`/3）**。
#     **三级反极性（每级成对）**：① **牙级假修**（只删代码不动 needle）⇒ 应用器 `rc=1`、生成物 sha **未变 = 没写盘**；② **返空串假修** ⇒ **`rc=1 RED-LENGTH`**、`A1/A2` PASS 而 **`A3` FAIL（`Σ可见长=2` 期望 3）** ⇒ **"修好"与"修得对"是两件事**；③ **半接线假修** ⇒ **仍红**且与修前**逐位相同**（`RED-EXC-LS`/`134`、`relaxedParaDefaults=0`、`lastFail` 同串），**计数牙齿 `n_default_src` 在代码阶段就报红**（`0 ≠ 2`）。
#     **⭐ 写法本身是设计**：`paragraphDefault` 为 `null`（调用方没接线）时**行为与修前逐位相同** ⇒ **"半接线"不会静默变绿**（生成物注释里写明了这条）。
#     **回退证**：`cp -p` 复原应用器 ⇒ 生成物逐字节回 `a6f1b678ce87a8a2` ⇒ **`pc` `cmp` 逐字节回到 `476994e35d31a7e1`**（与 `#24` 留档 IDENTICAL），再恢复 ⇒ 回 `7374308a00c55572`（**往返闭合**）。
#     **零射程**：`PcLineOracle` 修前/修后 1,480 行**只差 2 行**（都是新增诊断字段）、**判据行 sha `573de10e62159227` == 同值**、汇总 `红=0 绿=421 判定行=421 NOINFO=0`；`frame-step.sh` = **`FRAME_STEP=PASS`**（三腿 `帧红=0 结构红=3`，与 `#24` **同值**）；该腿 **`relaxedCalls=0`** = "新分支在冻结语料上一次都不执行"的**运行期证明**。
#     ⚠️ **判别力边界（不许省略）**：`A1/A2/A3` 对"占位字符是否**真零宽**"**零判别力**（探针**从不读 `line.Width` 或任何几何**）；冻结语料**不含全隐形段落** ⇒ **"能否转绿"可测、"转绿是否对"本仓不可测**（要真机重录，即 `D-T7`）。**这个绿 ≠ 隐形语义已正确。**
#     ⚠️ **"修好"≠"有牙"**：`grep 'D5CbrProbe|hiddenonly'` 在 `verify-all.sh` 与全部 `tools/*.sh` 里**仍是 0** ⇒ 今天**没有任何门会因这条缺陷变红**（与 `D-G10` 同族）。要变成"有牙的门"需新写一步 —— **本波未做**，登记为欠账。
#     ⚠️ **严格档 shim 的兜底未接**（形参表里没有 `TextRuntimeProperties`；接它 = 动 shim = 付世代成本）。**对本用例无影响已证**（严格档先 `Bail "run 类型 TextHidden 不支持"` 再落宽松档）。
#   【② `D-A2-r` 方案 B 落地（桥的**只读**绝对锚判据）】`build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` `fc4c249851fa1d71 → 7bc9364091a28fd4`（778 → 945 行；8 个 hunk **全为追加**，`+173/−6`，6 条删除行 = 被同名改写的那 6 行本身；自检 A–O 用例体**一行未动**）。
#     锚 = `<publish>/bridge-src-fp.txt` 里的 `BRIDGE_SO_SHA256`（写点 `build/publish-milbridge.sh:81`）；**桥绝不进 `ITEMS`**（结构上产生不了 `STALE`/`NEWER-DIFF` ⇒ **进不了 `sync-applocal-authority.sh:103` 那条"用 376 B 的 `.txt` 覆盖 4.9 MB 的 `.so`"的写路径** —— 主控读码核过：`bridge_anchor_check()` 函数体内 `CNT_STALE`/`CNT_NEWER` **0 处**）。
#     新计数器 **`CNT_BRIDGE_ANCHOR`/`CNT_BRIDGE_NOINFO`（两者都红）**：定义 `:168`｜调用 `:884`｜摘要 `:886`｜**进 `rc` `:935`（判定链）+ `:936`**。`--selftest` **18 例全 PASS / rc=0**（基线 17/17；新例 `SELFTEST_P`，主控**独立重跑复核过**）。
#     **反极性（真件形态沙箱，真件零接触）**：两份副本一起换旧桥 `caf7baf9e67719aa` ⇒ **旧件 `APPSYNC=PASS rc=0`（`D-A2-r` 现场）→ 新件 `APPSYNC=MISMATCH rc=1 BRIDGE-ANCHOR=2`**，其余 12 个计数器**逐字相同** ⇒ **红只来自新判据**；`cp -p` 还原 ⇒ `cmp IDENTICAL`。**今天 0 条新红**（两份副本都 == 记录）。另测：只换一份 ⇒ `=1`；记录整份移走／锚行删掉／0 份副本 ⇒ 三种 **`BRIDGE-NOINFO=1` + rc=1**（**NOINFO 不许当绿**）。
#     **射程缺口（明说）**：只覆盖 `SCAN_ROOTS` 内 `find` 到的**现存**副本；**不防篡改**（记录与副本同权限）；"记录过期 vs 件被换"**不可分**（都判红、不给成因）；`.so.dbg` 无判据；源级陈旧不归它管；**"桥少了一份（剩 1 份且 == 记录）本判据报绿"** —— 明确缺口，不是漏测。
#   【③ 两条登记结算】① **3 条结构族帧红**（`行数我方=4 真值=2`，`@tab0`）**今天首次有书面登记**：新建 `build/MilBridge/known-red-frame-structural.md`（3 条，`B-indent/…@i24@tab0`、`B-indent-extra/…@i0p24@tab0`、`B-indent-extra/…@i24nl@tab0`）。**只读性有实证**：读者集合 = **空**（`FrameProbe/Program.cs` 与 `frame-step.sh` 里 `known-red` **各 0 命中**、新文件名全仓 **0 引用**），且沙箱三趟（有登记/空登记/**整份不存在**）⇒ `rc` 与所有计数器**逐字相同**。② `known-red-PC-copies.md` 追加**按世代结算**（`e5946a8a7ce1cfe0 → 8497a0ca1689cf90`；**只增不改**：主控核实删除/改写 **0** 行、新增 215 行）。
#     **⭐ 世代切换现场实录（本波真实逮到）**：`pc` 在 **12:30:42** 重建后，上一代那 **12 份"已转绿"在同一分钟内全部回落为"仍红"**。主控独立枚举：34 份 `PresentationCore.dll` 中 **3 份 = 新权威、31 份落后** ⇒ 波尾要收敛的是 **31 份，不是 12 份**；而 **`close-wave.sh` 自己不会刷新副本**（`grep -n sync-applocal` = 0）。⇒ 已写成预登记 §9.1 的硬性动作。
#   【④ 收官时补的登记与草稿（`D-G9`–`D-G14`，全部有实测依据）】
#     · **`D-G9`｜臂日志（派生件）的世代归属没有机器核对**：现场 `tab-zero 424d4c6d5ab121cb`／`tab-rtl 5e4d9ef3c64f7d7e`／`tab-anchor 56abc845dbd29e93`，而登记表 `generation.leg_resolution.cross_check`（**一条散文串**）仍写旧值；**门禁不读它**（`grep -c cross_check tline-gate.sh` = **0**），三个新 sha 在 `tools/**`/`known-red.json`/`verify-all.sh` 里**引用 0 次**。⏪ **措辞已收窄**：不是"没被登记"而是"**没有机器读者**" —— `docs/WAVE24-PREREGISTRATION.md:203` **有散文出生证**，`:204` 那句「**不需要重钉**」**才是病根**。**修法草稿已备**（结构化 `arm_logs` 字段 + 只读核对器 `arm-log-sha-check.sh`，`--selftest` **9/9**，对今天真树给 **`NOINFO`** ⇒ 不假绿；**0 笔 `dotnet`、不动 `inputs_fp`**）。
#     · **`D-G10`｜`verify-all` 的成功步骤 stdout 从来不落盘**：`verify-all.sh:64` `mktemp` + `:100` **只在失败分支** `cp`、`:102` 无条件 `rm -f` ⇒ 绿的步骤"判了什么、分母多少"只能靠报告文字。**三颗牙齿今天就在自报**（`PCLINE_START_STEP=`/`FRAME_STEP=`/`BASELINE*=`）—— 缺的只是 `run_step` 那一行回显；**行级草稿已备**（插入点 = `verify-all.sh` 行 90 之后 / 91 之前；只加不删；`--selftest` 6/6）。
#     · **`D-G11`｜应用器的生成物没有"等号读者"**：现场实测到"**生成物已超前于产物**"而**不报任何红**。口径 = `HEADER + out` 的整串（应用器 `:1052`）；**补丁草稿已备**（扩展既有 shimsha 应用器 + 零依赖读者）；⭐ **反极性②无需重建**（手改生成物一行 ⇒ `TFF_SHA=yes`）。
#     · **`D-G12`｜`--tab-oracle` 读了 `perChar[].width` 却从不比较**（356 条真值"读了不用"）—— 与 `D-G8` 的 `scanrc` 同族。
#     · **`D-G13`（仪器级）｜`--selftest` 的 `SELFTEST_M2` 有既有竞态** ⇒ **并发改仓时会假红**（机制读码确认：拿 M 时刻的输出去满足 M2 时刻新算的要求）。**裁决**：修法 = 值只许一处并钉住，或**不一致时报 `NOINFO`、不许报 `FAIL`**（NOINFO 不该冒充红）。⇒ 立**波尾纪律 §9.1b：`--selftest` 必须在静树上跑**。
#     · **`D-G14`｜覆盖闸是"整例级"的 ⇒ 把与字体无关的列也一起埋掉**（"RTL 半身不遂"的真因）：闸在 `CoverageProbe/Program.cs:1367-1386`。非拉丁字符**只有 6 个码点**；系统**装了**覆盖它们的面，缺的是探针挑中的那一份（Liberation **1.x**）；**换面救不回来**（与真值面 Arial 的 `max|Δ|` 最小 **0.3167 = 6.3× 容差** ⇒ 换面后**变红**）。✅ **真能治它的是"列级闸"**：`TextLine.Start` 真值 ≡ `ParagraphIndent`（主控独立复算 **615/615 行 == 、反例 0**，含全部 194 个缺字形行）⇒ 加列级粒度后 **RTL 非零 `Start` 由"行使 0 行"→"行使 33 行"**（`D-paraindent` hebrew RTL：PI24 15 + PI48 18）。**可施工补丁草稿已备并被主控实测**（`patch -p1` `rc=0`、产物与其参考件逐字节相同）。
#   【⑤ 波尾与门禁】`close-wave.sh --skip-verify-all`（rc=0）⇒ **`native_rebuilt=0`、`bridge_republished=0`**、桥源指纹两侧一致 `b6acdba4f01599d8`、生成物指纹 `state=ok`、应用器审计 **`miss=0`**、**输入稳定性 波前==波后 == `0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8`**。
#     五臂 **`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2`**、`GATE_REASON=all-as-registered`、`rc=0`。
#     `verify-all` **rc=0 / 13 步 / 871 通过 2 跳过**（第 [4] 五臂 ✅、第 [5] `PcLineOracle·Start 列` ✅、第 [6] `FrameProbe-frame` ✅、**第 [7] `BASELINE-SHA` ✅**）。
#     ⚠️ **`verify-all` 步数口径**：`#15`=9 / `#16`–`#20`=10 / `#21`–`#23`=11 / `#24`=12（帧列）→ **13（收官补 `BASELINE-SHA`）** ⇒ **`#25` 起=13**；旧步数读数不能互相引用。
#   【⑥ 判据读数】应用门禁**两趟**（`run_dir=…/w25-gate1`、`…/w25-gate2`；按 `D-G7` 逐字记录装置行）⇒ `WPTD_GATE=PASS`、**6/6 `BASELINE … result=PASS`**、六条机读行的 `config=pc:` **全部是新 `pc`** ⇒ **`D-T5-R` 的修法对应用门禁零影响**（与预测一致：`samples/**` 对那类 run **0 载体**）。
#   【⑦ `APPSYNC`（波尾、`pc` 定型 + 副本收敛之后再读）】校验器全量（**静树**，`~/wfp-runs/w25-appsync.log`）⇒ `APPSYNC=MISMATCH`（`MISMATCH=1[STALE=1 NEWER-DIFF=0]`、`UNEXPECTED=1[DECL-GAP-EQ=1]`、`DIVERGENT=1`、`MISSING=0`、`AUTH-MISSING=0`、**`BRIDGE-ANCHOR=0`、`BRIDGE-NOINFO=0`**）、`rc=1`。**三条红全部是长期在册的**：① `FallbackCriteria/bin/Debug/WpfGfx.Linux.dll`（`c400ab1638e0c3d2`，`UNEXPECTED-EQ` = 未声明的传递依赖副本，`D-A1` 那一处）；② `tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll`（`EXPECT c400ab1638e0c3d2 ACTUAL 16baacfccfcf1df0`，副本早 452,841 秒 ⇒ 即 `known-red-PC-copies.md` 的 **PC-4**）；③ `WpfGfx.Linux.dll [Debug]` 有 2 种 sha（⇒ `DIVERGENT`）。**⇒ 本波零新增红。**⚠️ **相对 `#24` 明显收敛**（`#24` 是 `MISMATCH=18[STALE=18]`／`DIVERGENT=3`）—— 那批落后副本在 `#24` 之后已被刷新。⚠️ **并更正一条**：本波一条只读车道（W25C）据"按 `find` 全枚举"报"波尾要收敛 **31** 份落后副本"，而**校验器的权威口径是 0**：`sync-applocal-authority.sh` 干跑给 `refreshed=0 newer=0 applied=0`，且明说"**同类加载源副本都已是权威 sha**" ⇒ **不需要 `--apply`**（那 31 份是校验器**不认**的非加载源副本；且主控那条计数命令自己也写坏了）。⭐ `--selftest` 在**静树**上重跑 = **`SELFTEST=PASS`／`rc=0`**（18 例；§9.1b 满足 —— 并发期那次 PASS 不作波尾读数）。
#   【⑧ 内存信封】120 样本 / 60 分钟：`MemAvailable` **最低 1961 MB / 均值 2773 MB**；`SwapFree` **最低 537 MB**；`load1` 峰值 **9.75**（3 核；含 `verify-all` 的 `dotnet test` 多 testhost）；采样到 `dotnet` 进程峰值 **6**。⚠️ **主控自己的仪器两处如实登记**：① 看门狗（阈值 `avail<1000 / swapfree<250 / dotnet>2`）报 **60 条**，**全部来自 `dotnet>2`** —— 而 `verify-all` 第 [2] 步 `dotnet test` **正常就会起 3–6 个 `dotnet`**（testhost 也叫 `dotnet`）⇒ **阈值口径定错**：`dotnet>2` 对"车道并发"有意义、对"`verify-all` 自身"是**正常操作** ⇒ **一个在正常操作上会响的判据是坏判据**（与 `D-G13` 同族）。**内存两档阈值一次都没响过**（`avail` 最低 1961 ≫ 1000、`swapfree` 最低 537 ≫ 250）⇒ **本波未发生内存压力**。② 采样器 `dotnet_procs` 字段有个小疣（`pgrep -c` 无匹配时"打印 0 + 返回 1" ⇒ `|| echo 0` 多吐一个 `0`）⇒ 日志偶有裸 `0` 行，主行数据完整。
#   【⑨ ⚠️ 一条口径】`APPSYNC` 的红数与 `known-red-PC-copies.md` 的 `[在册红·已转绿]` **只在某个"权威 `pc` sha"下有意义**（本波**当场逮到**世代切换：`pc` 一重建，12 份"已转绿"一分钟内全部回落）⇒ **必须在波尾、`pc` 定型之后再读**；**"转绿"≠永久销账**。
#   【本波的四条落地 + 六条只读车道（**零 `dotnet`**）】四条落地车道：`W25A`（`build/MilBridge/W25A-report.md 2bb495e622b9ec19`，`D-T5-R`）｜`W25B`（`fb7469b4bc107312`，`D-A2-r` 方案 B）｜`W25C`（`0dac420628c926c8`，登记结算）｜以及主控自己落的收官件。六条只读车道（报告全在 `~/w25-recon/`）：`W25D`（`fae47460963941c2` 自报口径方案）｜`W25E`（`460d32d1baec7949` 可复算性审计）｜`W25F`（`a2d495211364222f` `D-T7` 真机重录配方）｜`W25G`（`dba49243f2b9749a` `hasOverflowed` 判别面）｜`W25H`（`6cefb2be1bd2df58` RTL 全 NOINFO 根因）｜`W25I`（`9340d85dfcf91fc0`/`1ea7e434ded9386c` 列级闸补丁草稿）｜`W25J`（`f33275ff44602243` `D-G9`/`D-G11` 草稿）｜`W25K`（`dae70fe788008654` 登记册健康审计）。
#   **本波最值钱的四条（按价值）**：
#     1. **`D-T5-R` 修好且零世代成本**（见 ①）—— 产品行为真的变了（`hiddenonly` 四格全绿），而**世代绑定三项一个字节未动** ⇒ 这是"把修法落在应用器"这条路线第二次兑现。
#     2. **W25D 推翻了主控派单的前提**：三颗牙齿**今天就在自报**，缺的是 `run_step` 的回显 ⇒ 把一件"改三处脚本"的活儿收敛成"改一处 `run_step`"，并给出**一个真例**证明旧失败 grep 会漏（`tline-gate.sh --logdir` 缺参 ⇒ `rc=3`、grep **0 命中**、屏上只剩 `❌`）。
#     3. **W25H 查明"RTL 半身不遂"的真因并给出可治的一刀**（见 ④ `D-G14`）—— 而且它**否掉了整条字体路线**（换面后是变红不是变绿），省掉一整条弯路；同时**更正了主控文档里一句跑了四波的老话**（"RTL 那 33 行全在 `C-rtl-indent`" ⇒ 数目对、归属错：在 `D-paraindent`；`C-rtl-indent` 该列 45 行非零 **0** 行）。主控独立复算两次逐位相同。
#     4. **W25K 的登记册健康审计**：**① 有牙 24（含 5 条不进 `rc`）｜② 无牙 37｜③ 假牙 1** ⇒ **记账面健康、牙齿面很薄**；并点名 4 处"文档说 N、实测 M"。顺着它的对账，主控抓到 **`D-R7` 的修法只做了一半**（`patch-presentationcore-lineheight-trace` 已进 `APPLIERS_EXPLICIT` **会跑**，但**不在 `applier-audit-expected.txt`** ⇒ 把它摘掉**不会红**）⇒ **已补那一行**（纯加强：被审计 **22** / 必查 **22**，补前 22/21；补后审计仍 `rc=0`）。
#   **两条口径更正（主控自纠，都上了台面）**：
#     · **W25E**：把"结论可复算"与"引用的物可考"**分成两把尺** —— 13 条结论**数值层面 13/13 命中**，但"引用的物今天都在盘上且逐字对得上"只有 **≈77%**（3 条不合格，同一根因 = 派生件的世代归属没有机器核对 + PASS 时 stdout 不留档）。这一条直接生出了 `D-G9`/`D-G10`。
#     · **主控一次误判（已撤回并留档，纪律 51 内）**：12:47 有一条 `frame-step.sh` 在跑，我**先点名了一条只读车道"越界"**；复核后**撤回** —— **进程树定不到车道**（`PPID` 是 dsh 宿主，**每一条车道的 bash 都由同一宿主派生**），而 `list_agents` 显示当时**唯一在跑的是 W25A**，且它**正是有 `dotnet` 权限的那条**、预登记 §2 本就写了"第 [5][6][7] 步必须重跑" ⇒ **最可能是它的正当位移复核**。留下的两条真教训：**定人不能用 `PPID`**；**"禁止车队"必须连"会自行构建的步骤脚本"一起点名**（`frame-step.sh:94` 自建 harness，那个 dll 的 sha 是**派生量、不是冻件**）。
#   **新立/细化的纪律**：**53**（顶层结论自己必须有牙齿 + 值只许一处声明）｜**54**（"让基线核对基线自己"会自指 ⇒ 必须再跑一趟）｜**55**（`--` 之后的一切都是操作数 ⇒ `grep -rn -- 'PAT' --include=…` 会**静默关掉**过滤器；同族：管道后 `$?`、`pgrep -f` 自匹配、`grep -c` 无匹配时"打印 0 + 返回 1"）｜**51 细化**（禁止车队要连自建脚本一起点名）｜**§9.1b**（`--selftest` 必须静树跑）。
#   **留给 `#26` 的（按价值）**：① **`D-G10` 落 `run_step` 回显 + 三颗牙齿汇总行**（草稿已备、只加不删）；② **`D-G14` 列级闸**（补丁已被主控验过可 `patch`，把 RTL 非零 `Start` 从 0 行变 33 行；**不动产品件**，但要按纪律 34 **人工重取三支 `tab-*` 臂**）；③ **`D-G9` 结构化臂日志 + 只读核对器**（零世代成本）；④ **`D-G11` 产物↔生成物等号读者**（`1 笔 pc 重建 + 1 个工具项目`；改 `patch-*.py` ⇒ **必须波前落地**）；⑤ **`D-G12`**（`perChar[].width` 接进比较）；⑥ **`D-T5-R` 变"有牙"**（新写一步）；⑦ `D-T7` 真机重录（配方已备：**真值录"断行后果"、不录码点**；且**语料未录时该步必须报 `NOINFO`**）；⑧ `hasOverflowed` 的更大判别面（真值 **1293 行**、今天只判 **421**）。
BASELINE tier=default rep=1 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:eb48655d697a4188,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w25-gate2
BASELINE tier=default rep=2 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:eb48655d697a4188,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w25-gate2
BASELINE tier=default rep=3 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:eb48655d697a4188,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w25-gate2
BASELINE tier=env rep=1 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:eb48655d697a4188,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w25-gate2
BASELINE tier=env rep=2 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:eb48655d697a4188,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w25-gate2
BASELINE tier=env rep=3 config=pc:7374308a00c55572,bridge:d567c26f197ec1e3,pf:eb48655d697a4188,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w25-gate2
# ⏪ **（历史，已被 `#24` 取代；下表九位与"11 步"口径只对 `#23` 成立）**# RE-FROZEN #23 —— ✅ **当前冻结基线** —— 内容 = **`D-T6-b` 修法（**Option 1**：新增 `_paragraphOrigin`，`_lineStart` 语义不变）+ `D-F2`（三个只写不读的计数器接出口）**（预登记 `docs/WAVE23-PREREGISTRATION.md`，含 §9–§14 收官节与 **6 处主控自我更正**）。
#   ⚠️ **本波是"必须付那笔成本"的一波**：shim 是**世代绑定的三项之一**（`tline-gate.sh` 的 `SH_SHIM`），**且应用器也改了**（宽松档的 `paragraphOrigin: cpFirst` 注入）⇒ **五臂重取 + 登记表重钉到 `#23`**。
#   **⚠️ 本波最值钱的一条（事故级）**：`_lineStart` 在 shim 里是**双用字段** —— `shim:3661`/`:3694`/`:3701` 拿它当 `_text`/`_plan` 的**相对**下标（`Collapse`/`BuildCollapsedLine`），
#     而 `GetTextBounds`/`GetIndexedGlyphRuns`/折叠越界判定拿它当**绝对**段落系下标。⇒ **预登记字面的 `_lineStart = paragraphOrigin + range.Start` 会打断折叠路径**（`_text.Substring`/`_plan.Sub` 切错串或越界），而 `Collapse` **在真机消费路径上**（`MS/Internal/Text/Line.cs:165`）。
#     ⇒ 落地形态 = **Option 1**：**新增 `_paragraphOrigin`**、`_lineStart` 语义与赋值**一字未动**、只改 **3 个绝对消费者** + **折叠行透传**。主控逐点审计：4 处改到位、**3 处相对消费者 `cmp` 逐字节未变**。
#   **相对 `#21` 三位变了**：**`hbtextline 76089e1de586ac91 → e89fed55fd8e32bc`**（283,557 → **290,825 B**）｜**`pc e7cabff9417ed380 → 7b47a7b3d69ad62f`**（**4,197,376 B**）｜`pf 2fb1a896f8277647 → 1c3fe23261c22bc6`（环成员，**由波尾 `integration-wave.sh` 重编引起** —— `pc` 在车道重建后没再动，`pf` 动了）；`inputs_fp a2b74537… → 6146f3641b87a5a7d74e182ab9ca3f6f72299377bbfce2993843cb56ccbca0ca`（**两个原因**：shim + 应用器）。
#   `inputs_fp=6146f3641b87a5a7d74e182ab9ca3f6f72299377bbfce2993843cb56ccbca0ca`
#     ⚠️ **主控自纠（`#23`，两处）**：① 本块原先只用「`a2b74537… → 6146f364…`」的**叙述形式**写它，**没有 `key=value` 那一行** ⇒ **机器 `grep inputs_fp=` 抓不到**（`#21` 的块有）；
#     ② **更严重：我手抄那个值时漏了一个 `b`**（写成 63 位的 `…77bfce…`，正确是 64 位的 `…77bbfce…`）⇒ **冻结基线一度带着错哈希**。
#     现已改为**由脚本现场计算后写入**（与 `close-wave.sh` 的 `fp_inputs()` 同一实现）⇒ **不再手抄哈希**。冻结基线必须可被机器逐位比对，这两处都违反，故如实留档。
#   **未变**：`bridge d567c26f197ec1e3`（4,987,840 B；**不重发桥**，与预测一致）、`BRIDGE_SRC_FP=b6acdba4f01599d8`、`windowsbase`、`provider`、`win32shim`、`wic_shim`、`dwf`。
#   【① `D-T6-b` 的读数（分母 = `script==latin` 288 例 / 421 行）】**宽松档 红 133 → 3**｜**严格档 红 3 → 3（日志逐字节相同）**｜**`--fresh-source` 133 → 3**｜**`--prefix 40` 红 421 → 3**。
#     **`GetTextBounds(cpFirst,1)` 读空的行：宽松 104 → 0、`--prefix 40` 522 → 0。**
#     ⚠️ **预测写 0、实测 3 —— 是主控的口径错，不是修法没做完**（车道如实上报而未改判据）：残余 3 条全 `@tab0`、每条自报 **`行数我方=4 真值=2`** ⇒ **是"行数不等"结构族，不是帧错**。
#     机器证（421 行全量、不抽样）：**`frame == cpFirst` 421/421**；**`cpFirst == truth` 的 418 行里帧错 = 0**；`cpFirst ≠ truth` 恰 3 行且全红 ⇒ **帧族红 = 0/418**。主控独立复跑确认（宽松/严格/prefix40 三腿 `红行=3`、`判定行=421`）。
#   【② `D-F2` 读数（两极化）】修前运行时 `HB_TEXTLINE` 三字段 `grep -c` = **0/0/0** → 修后**各 2 处**（`candidates=371(扫描1次) scanCapped=0 segmentFaceUnresolved=0 runFaceSlotMissing=0`）；pc 二进制里的 **UTF-16 用户串** `0/0/0 → 2/1/1`。另 3 处注释伪证（自称"诊断行报 `capped=`"）已改成"出口 = `HB_TEXTLINE` 汇总行"。
#   【③ 零射程（机器证）】**严格档腿日志逐字节相同**；**`PcLineOracle` 日志逐字节相同**（`db37ce865e8b91b1`，连时间戳都没有）；宽松/`--prefix 40` 只变预期列（`LINECOUNT` **60/60 全同**）。
#   【④ 纪律 38 红线（主控实跑）】`python3 <patcher>` 重生成 ⇒ 生成物 **`fef2cfb47f882a82 → fef2cfb47f882a82` 逐字节不变**，注入 `paragraphOrigin: cpFirst` 仍在 **`:268`**；`patcher --check` **rc=0**；`check-appliers.sh` ⇒ **`appliers=22 ok=80 miss=0 red=0 rc=0`**（与 `#21` 同数 ⇒ 没落进"注册了但没生效"那一族）。
#   【⑤ 波尾与门禁】**必须先跑 `close-wave.sh`**（`OUT=…/close-wave-23`，`rc=0`）：`native_rebuilt=0`、`bridge_republished=0`、桥源指纹两侧一致、生成物指纹 `state=ok`、应用器审计 `miss=0`、**输入稳定性 波前==波后 = `6146f364…ca0ca`**；
#     五臂 **`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2`**、`GATE_REASON=all-as-registered`、`rc=0`（`known-red.json 3bf26e12f320dece → e623d2b17d948e3b`）；
#     `verify-all` **rc=0 / 11 步 / 871 通过 2 跳过**（第 [4] 五臂 ✅、第 [5] `PcLineOracle·Start 列` ✅）；等号读者 **`SHIM_SHA=no`（`cmp=full64`、`product_sha16 == tree_sha16 == e89fed55fd8e32bc`）**。
#   【⑥ 判据读数：**与 `#21` 逐位相同**】应用门禁**两趟**（`run_dir=…/w23-gate1b`、`…/w23-gate2b`；**两趟都走"复用常驻 `:97`"分支**，按 `D-G7` 逐字记录）⇒ `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、**6/6 `BASELINE … result=PASS`**、`drawn=260/144`、`colors=3960/2828`、`frames_good=14/14`、`cross_ae=0`、`leftover_after=0`、`scroll=ok`、`exit=143`、`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 runs=167`、`WPTD_BRIDGE_SRC_STALE=no`。
#     **六条机读 `BASELINE` 行与 `#21` 逐字相同**（只差 `pc`/`pf`/`hbtextline_shim` 三个 sha 与 `rundir`，已机器 `diff` 证过）。
#     ⇒ **§5.1 的命名候选（`TrimText` 的 `CharacterEllipsis` 经 `_collapsedRange`）没有兑现** —— 本件确实改了 `_collapsedRange.CharacterIndex`，但**渲染读数不变**。
#   【⑦ 本波同波落地的其余两件（**不改九位**）】
#     · **`D-A2` 检查器覆盖面**：`ITEMS` 补 `PresentationCore.dll` + `SCAN_ROOTS` 补 `$REPO/tools` + `applocal-expect.py` 补 PC ⇒ **13 份点名红**（12 PC + 1 `tools`）；**新建书面登记** `build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md`（`e5946a8a7ce1cfe0`）+ `show_registry()`（只读，自述"**登记≠已容忍：本段不参与判定**"）⇒ **`rc` 一字未动**（`APPSYNC=MISMATCH`、`rc=1`）。⚠️ **`close-wave.sh` 从此会长期打印 `⚠️ APPSYNC 非 PASS`** —— 那是**登记在册的**，不是新问题（主控已核实它是告警、不是硬闸；`publish-milbridge.sh:100-112` 亦**不改退出码**）。
#     · **`D-T5` 判据（只测不修）**：新探针 `build/MilBridge/tests/D5CbrProbe/` ⇒ **`eos1`/`mod1` 在两条腿都是 `RED-EXC-LS`/`ABORT 134`**（**快路径开即产品缺省也如此**）；`control`（阳性对照）与 `mod0` GREEN。**abort 与 null 已可分辨**（判读逻辑自身过两极化：`--selftest abort`⇒134、`null`⇒1）。⭐ **主修法不必动 shim**（`ExtractRun`/`CollectLenient` 都在应用器里）⇒ **零世代成本**。
#   【⑧ 新登记（本波）】`D-G7`（常驻 `:97` **第 3 次死**，且**它死了不会让任何判据变红**；危害是装置悄悄从"复用"变"自起" ⇒ 波形文档那句声明变假）；`D-G8`（`check-applocal-sync.sh:654` 的 `scan; scanrc=$?` —— **`grep -c scanrc` = 1**，赋值后从未被读 ⇒ **权威整份不见时 `rc` 可能仍 0** ⇒ `APPSYNC=PASS` 可以骗人；修它必须同趟改 `SELFTEST_E`）。
#   【⑨ 主控自我更正（本波 6 处，全部留档）】① §3.2 的 `startChar` 预测数用错列（应是 179/133，不是 171/138）；② 停条件 6 的"17 份"前提（`pc` 变了 + `refresh_applocal` 会让它合法变化）；③ 给 W23B 的"88"是把 `Start` 列混进帧列；④ 把车道自己跑的 `FrameProbe` 当成"别人跑的"；⑤ **"帧族红 → 0"被我写成 "133→0 / 421→0"**（把结构红混进帧数）；⑥ **§8 收官清单漏了 `close-wave.sh`** ⇒ 我把读数取在规范波尾**之前**，而波尾重建动了 `pf` ⇒ 应用门禁基线作废 ⇒ 已按正确顺序重取（本表就是重取后的）。
#   【⑩ 内存信封（用户要求，40 分钟 / 80 样本）】`MemAvailable` **最低 2,752 / 最高 4,397 / 均值 3,406 MB**；**`SwapFree` 全程未动（1,057 MB = 开工值）** ⇒ **未发生内存压力**；`load1` 峰值 4.63（3 核）。协议 = 同时只允许一个重构建者 + 全体 `-m:1` + `DOTNET_gcServer=0` + 构建前 `<1200 MB` 自检。

BASELINE tier=default rep=1 config=pc:7b47a7b3d69ad62f,bridge:d567c26f197ec1e3,pf:1c3fe23261c22bc6,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w23-gate2b
BASELINE tier=default rep=2 config=pc:7b47a7b3d69ad62f,bridge:d567c26f197ec1e3,pf:1c3fe23261c22bc6,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w23-gate2b
BASELINE tier=default rep=3 config=pc:7b47a7b3d69ad62f,bridge:d567c26f197ec1e3,pf:1c3fe23261c22bc6,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w23-gate2b
BASELINE tier=env rep=1 config=pc:7b47a7b3d69ad62f,bridge:d567c26f197ec1e3,pf:1c3fe23261c22bc6,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w23-gate2b
BASELINE tier=env rep=2 config=pc:7b47a7b3d69ad62f,bridge:d567c26f197ec1e3,pf:1c3fe23261c22bc6,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w23-gate2b
BASELINE tier=env rep=3 config=pc:7b47a7b3d69ad62f,bridge:d567c26f197ec1e3,pf:1c3fe23261c22bc6,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:e89fed55fd8e32bc(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w23-gate2b

# ⏪ **（历史，已被 `#23` 取代；下表九位与"11 步"口径只对 `#21` 成立）**# RE-FROZEN #21 —— ✅ **当前冻结基线** —— 内容 = **`D-T6-c` 定性并落地：`TextLine.Start` 由 `=> 0` 改为 `=> _paragraphIndentDip`**（预登记 `docs/WAVE21-PREREGISTRATION.md`，含 §10–§15 五处**自我更正**）。
#   **本波又是一波"必须付那笔成本"的**：shim 正是在册红门禁**世代绑定的三项之一**（`tline-gate.sh:137` 的 `SH_SHIM` 只绑这一个文件）⇒ **五臂重取 + 登记表重钉**。已实测：shim 一改，门禁逐字 `TLINE_GATE=NOINFO … caliber=MISMATCH … tree_gen=advanced … rc=2`（**设计，不是缺陷**）；重钉后 `TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#21 tree_gen=same saved_shim=76089e1de586ac91 gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2`、`GATE_REASON=all-as-registered`、`rc=0`。
#   **相对 `#19` 三位变了**：**`hbtextline fe1b7ed8fa3ed231 → 76089e1de586ac91`**（278,692 → 283,557 B）｜**`pc f4a454c8fe69cdfe → e7cabff9417ed380`**｜`pf bd4e28e6a6f8b0e5 → 2fb1a896f8277647`（环成员）。**未变**：`bridge d567c26f197ec1e3`（4,987,840 B；**本波不重发桥**，与预测一致）、`windowsbase 1114a28ec5a03ab7`、`provider`、`win32shim`、`wic_shim`、`dwf 0ed422ef2dd46445`、`BRIDGE_SRC_FP=b6acdba4f01599d8`。
#   【① 真机法律（三条**互相独立**的证据）】`Start ≡ IdealToReal(ParagraphIndent)`（`TextAlignment=Left`）：**①** 真机源码 `upstream/wpf/…/TextFormatting/TextMetrics.cs:255-263` 的**注释原文** "Paragraph start to line start is paragraph indent"、代码 `_paragraphToText = pap.ParagraphIndent + _textStart;`，而 `Start` 又减掉 `_textStart`（`:355-358`）⇒ **精确相消**；**②** 真机语料 `lineStartOffsetsDip`（真机臂 `Program.cs:445` 的 `R(line.Start)`）在 **615/615 行**上精确相等 —— 对照 `Start==Indent` 只 **337/615**；`PI → Start` 是**双射** `{0:[0],24:[24],48:[48]}`；**③** 另一条车道**盲复核**（落盘后才读预登记）独立重算得**逐位相同**的结果。
#   【② "3222/3222 恒为 0"是**语料性质**、不是实现性质】那个数出自 `layout-b34` 语料（614 例/3222 行），而该语料 `cases*.json` 里 **`ParagraphIndent` 与 `Indent` 出现次数各为 0** ⇒ 真法律的**唯一非零驱动量压根没被采样**。**同一条伪证有三个落点**，`#21` 三处都处置了：我方 shim 的注释（已改成真法律 + 语料性质说明）、`layout-b34` 的推断、`tab-anchor-oracle.json` 的 `unavailableOrUntested`（改成**现算**：由 `analyze.py` 从语料逐行重算后写入）。
#   【③ 判据 + **两极化是实测、不是声明**】逐行 `R(我方 Start)` vs 语料 `lineStartOffsetsDip[k]`，**只对 `TextAlignment=Left` 断言**（语料头 `paragraphProperties.fixed` 钉死）。修前 pc `f4a454c8fe69cdfe` ⇒ **红 138 行 / 88 例**（判定行 421、最大 Δ=48.0 @`D-paraindent/lead-tab-a@w100@LTR@i0p48@default` 行#0）；修后 pc `e7cabff9417ed380` ⇒ **红 0 / 绿 421 / 最大 Δ=0.000000**。红证 (b)（临时错驱动量 `Start = Indent`）⇒ **红 222 行 / 148 例**。
#   【④ ⚠️ **分母口径**（本波两次踩到，已立为纪律候选）】臂的可判定集 = `script=latin` 的 **421 行**，**不是**整份语料的 615 行。主控预登记两次把"语料总量"当成"本条腿的分母"（预期红 **171 vs 真值 138**、红证(b) **278 vs 真值 222**），两次都由车道用实测纠正。⇒ 凡写"预期红/绿"必须**同时写清分母是哪一档**。
#   【⑤ ⚠️ **覆盖边界**】法律在 **LTR(138 行) / RTL(33 行) 两向都有 0 反例**（**语料侧**证据），但 RTL 那 33 行**全在 `C-rtl-indent` 组 = Hebrew ⇒ 被覆盖闸（缺字形）跳过**，而 `latin` 的 138 行**恰好全 LTR** ⇒ **本判据实际行使的只有 LTR 那一半**。**不许**写成"判据覆盖了 RTL"。
#   【⑥ "零射程"是机器证】修前/修后同版仪器日志按列对比 ⇒ `PCLINE CASE` 头 **436/436 相同**、`STRUCT 56/56`、`TWIN 355/355`、`NAMED 6/6`、`GUARD 74/74` **全逐位相同**、**修后新增红 = 0 例**，且既有读数与 `#19` 冻结基线**逐位复现**（`红=127 绿=57`、`零缩进 63/41`、`PI≠0 64/112`、`未登记失败=67`）。
#   【⑦ 本波新查出的**结构性缺口**（并已修一半）】**真正驱动"产品 `pc`"的那一层，在冻树回路里没有任何自动红/绿**：五支臂全直调 `HbTextLineFactory.FormatParagraph`（不经 `HbTextFrame`/PC `TextFormatter`）；三支 tab 臂的宿主 `CoverageProbe/Program.cs` 对 `lineStartOffsetsDip`/`TextLine.Start` **零引用**（**语料里躺着 615 个真值、门禁从来没看过** ⇒ 这就是 `D-T6-c` 能长期存活的原因）；`PcLineOracle` 既不在五臂也不在 `verify-all`。⇒ `#21` 新增 **`verify-all` 第 11 步** `build/MilBridge/tools/pc-line-step.sh`（**只判 `Start` 一列**，自带"防恒绿退化（`判定行>0`）"与"产物副本==权威件"自检；**明说它不覆盖** `D-T6` 那 67 条未登记读法口径红）。**步数 10 → 11，口径已变。**
#   【⑧ 波与门禁读数】`close-wave.sh --skip-verify-all`（`OUT=/home/links-dev/wfp-runs/close-wave-184641`，18:46:41–18:48:20）⇒ **`native_rebuilt=0`、`bridge_republished=0`**、桥源指纹两侧一致 `b6acdba4f01599d8`、生成物指纹 `state=ok`、应用器审计 `miss=0`、**输入稳定性 波前==波后** `inputs_fp=a2b74537427ecc4a987edbe52a59c5d01d4817d54de58f445833c33dfb0e78e0`。随后**重取五臂 + 重钉登记表**（`build/MilBridge/known-red.json` `3bf26e12f320dece → 2fdc02931c2af796`），最后 `verify-all`。
#   【⑨ `verify-all`（冻树，日志 `$HOME/wfp-runs/verify-all-21.out`）】**`步骤通过 11 ❌ 失败 0`、`用例通过 871 跳过 2`、`结论：✅ 全部通过`、脚本 `rc=0`**；第 [4] 步五臂 ✅、**第 [5] 步 `PcLineOracle·Start 列` ✅**（`红=0 绿=421 判定行=421 NOINFO=0`）。
#   【⑩ 判据读数：**与 `#19` 逐位相同**】应用门禁**两趟**（`run_dir=…/w21-gate1`、`…/w21-gate2`；基线 `baseline21-run2.md`；stdout `gate21-run1.out`、`gate21-run2.out`）⇒ `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、**6/6 `BASELINE … result=PASS`**，`drawn=260/144`、`colors=3960/2828`、`frames_good=14/14`、`shot_dims=938x938`、`cross_ae=0`、`leftover_after=0`、`scroll=ok`、`exit=143` **全部与 `#19` 相同**；`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 runs=167`；`WPTD_BRIDGE_SRC_STALE=no`；普查 `T1C_CENSUS_SUMMARY frame=3 runs=167 handles=167 glyphs=1717 id0=0 nonlatin=421 maxid=63151 allnotdefruns=0 distinctpids=4 rc=0`（与 `#16` 逐位相同）。**六条机读 BASELINE 行与 `#19` 逐字相同**（只差 `pc`/`pf`/`hbtextline_shim` 三个 sha 与 `rundir`，已用机器 `diff` 证过）。两趟都跑在**常驻 `:97`**（复用分支）。
#   【⑪ P1 构建溯源】等号读者读 **`SHIM_SHA=no`**（`product_sha16 == tree_sha16 == 76089e1de586ac91`）⇒ **产物确实是用这一份 shim 编出来的**。
#   【⑫ 本波还落地/更正了什么（**不改变上面任何读数**，但都要连读数一起读）】
#     · **`D-R8` 收敛**：新增仓根 `BuildHygiene.props`（`c88fcccde138263b`，**全仓唯一一份排除实现**）+ **38 个 csproj 各加一行 `Import`**。暴露集是**实测 33**（不是上一波估的"7"），封 32，**1 个按停条件挂起**（`src/WpfGfx.Linux/WpfGfx.Linux.csproj`：它落在冻结的 `BRIDGE_SRC_FP` 覆盖面内）。证明：`plain` 清单 **80/80 逐字节相同**、仓内陈旧产物条目 **78→2**；**波后 38 行 import 逐字节存活**（主控实测 `cmp`，纪律 38 的红线判据）。
#     · **第三处伪证修复**：`tests/parity/windows/tab-anchor/analyze.py`（`8f953bd002616689 → f4780fbb12efbc7c`）把"Start 恒为 0"的手写断言改成**现算**，重生成 `out/tab-anchor-oracle.{json,txt}`（`a31a813114256faf → 0cebc0afd5142fbf`、`bdf2c31a7a34fbc9 → 34bab0b1032d2cd2`）。**前置检查**：该 oracle 原先**可逐字节复现**（未改动状态下重跑 `analyze.py` 与原文件 `cmp` IDENTICAL）；**证明只该动的地方动了**：`cases` 块**逐字未动**、`unavailableOrUntested` **只有 1 条变**、其余顶层键全同、重跑**幂等**。
#     · **两处错话更正**：`build/MilBridge/arm-logs/README.md:24` 与 `verify-all.sh` 里把 `arm-logs/*.log` 说成"**软链/符号链接**"—— 与同文件 `:3-8`/`:60-64` 的实测结论（**必须 `ln -f` 硬链接**；`cp` 顶 mtime 会架空弱配对判据；`ln -s` 会被 `find -type f` 漏掉 ⇒ 全臂 NOINFO）相反，已改。
#     · **一条文档漂移（新登记）**：渲染侧非九位可见位 `WpfGfx.Linux.dll` 现为 **`c400ab1638e0c3d2`**（mtime 2026-09-16 15:08:58，**本波未动**），而**该值在仓内任何文档里都查不到** —— 文档仍引 `#16` 世代的 `0c597fb6ec1eec70`（连 `D-A1` 的登记行都在引它）。⇒ 既非九位、也无指纹判据盯它 ⇒ **它漂了没有任何东西会红**。

BASELINE tier=default rep=1 config=pc:e7cabff9417ed380,bridge:d567c26f197ec1e3,pf:2fb1a896f8277647,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:76089e1de586ac91(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w21-gate2
BASELINE tier=default rep=2 config=pc:e7cabff9417ed380,bridge:d567c26f197ec1e3,pf:2fb1a896f8277647,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:76089e1de586ac91(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w21-gate2
BASELINE tier=default rep=3 config=pc:e7cabff9417ed380,bridge:d567c26f197ec1e3,pf:2fb1a896f8277647,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:76089e1de586ac91(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w21-gate2
BASELINE tier=env rep=1 config=pc:e7cabff9417ed380,bridge:d567c26f197ec1e3,pf:2fb1a896f8277647,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:76089e1de586ac91(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w21-gate2
BASELINE tier=env rep=2 config=pc:e7cabff9417ed380,bridge:d567c26f197ec1e3,pf:2fb1a896f8277647,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:76089e1de586ac91(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w21-gate2
BASELINE tier=env rep=3 config=pc:e7cabff9417ed380,bridge:d567c26f197ec1e3,pf:2fb1a896f8277647,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:76089e1de586ac91(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w21-gate2

# ⏪ **（历史，已被 `#21` 取代；下表九位与"10 步"口径只对 `#19` 成立）**# RE-FROZEN #19 —— 内容 = **`P4`（`HasOverflowed` 上方的**过时文档注释**）+ **严格档（`HbTextFallback.TryFormatLine`）的 **indent 接线**（`D-T3` 的另一半）**（预登记 `docs/WAVE19-PREREGISTRATION.md`，含**修订 v2**）。
#   **本波是"必须付那笔成本"的一波**：`build/shims/PresentationCore.HbTextLine.cs` **正是在册红门禁世代绑定的三项之一**（`tline-gate.sh:137` 的 `SH_SHIM` 只绑这一个文件）⇒ **五臂必须重取、登记表必须重钉**（`#16`/`#17`/`#18` 都没付的那笔）。已实测：shim 一改，门禁**逐字**变成 `TLINE_GATE=NOINFO … tree_gen=advanced … rc=2`（**设计，不是缺陷**）。
#   **相对 `#18` 三位变了**：**`hbtextline bc04c05ab6d8d82a → fe1b7ed8fa3ed231`**（275,765 → 278,692 B）｜**`pc df6dbb1c2bfb4162`→`f4a454c8fe69cdfe`**（4,196,864 B；**注释也改它，见 ③**）｜`pf`（环成员）。**未变**：`bridge d567c26f197ec1e3`（4,987,840 B；**本波不重发桥**，与预测一致）、`windowsbase 1114a28ec5a03ab7`、`provider`、`win32shim`、`wic_shim`、`dwf 0ed422ef2dd46445`。
#   【① 波（两段式，因为第 10 步在重钉前必然 NOINFO）】`close-wave.sh --skip-verify-all`（`OUT=…/close-wave-w19a`，`15:41:17`）：**`native_rebuilt=0`、`bridge_republished=0`**、身份自检四项 ✅、输入稳定 `288447d98d255f4c56ce04300a6fbe7977a62940e45f78617cd1d44873668d39`。随后**重取五臂 + 重钉登记表**，最后 `verify-all`（见 ⑥）。
#   【② **P1 的构建溯源核对（本波免费拿到的一条强判据）**】新 `pc` 里内嵌的 `HbTextLineShimSha` **必须**等于现树 shim：等号读者读出 `SHIM_SHA=no reason=content-compare artifact=f4a454c8fe69cdfe shim=fe1b7ed8fa3ed231 product_sha16=fe1b7ed8fa3ed231 tree_sha16=fe1b7ed8fa3ed231 cmp=full64` ⇒ **产物确实是用这一份 shim 编出来的**（不是"应该是"）。
#   【③ 一条新口径（本波产出，引用前必读）】**`pc` 的 sha 变了** **不再蕴含**"行为变了"：`#16` 的 P1 把 **shim 整文件的内容 sha** 编进了 `AssemblyMetadata`（`HbTextLineShimSha.targets:58`）⇒ **改一句注释就改 DLL 字节**（车道 W19A 实测：同 obj 路径、只差一句注释，`32533cae → 4fb7baad`）。`#16`/`#17` 那句"注释不进元数据"说的是**标识符/字面量**层面，与"整文件 sha 被注入"是两件事。⇒ 判"产物里是哪个 shim"用**等号读者**（本波 `no` ✓），**不是**比 `pc` 的 sha 变没变。
#   【④ 两件与它们的判据】
#     · **A（`P4`）**：把 `HasOverflowed` 上方那段"真机 3222/3222 全 false ⇒ 本实现恒 false"的**过时注释**拆成两个命题（**语料分布 ≠ 取值域**）并逐条对上 `D-O1` 的三分支。**零代码改动**经"剔 `///` 行后 `diff` 为空"**机器证过**。**判据 = 行为读数逐位不变**（见 ⑤，成立）。
#     · **B（严格档 indent）**：`HbTextFallback.TryFormatLine` 加 **带默认值**的 `indentDip`/`paragraphIndentDip`（**既有调用点零改动 ⇒ 逐位等价**，两重证据：工厂内 5 处用法全是加法/直接赋值 ⇒ 0 是加法单位元；元数据实测私生 pc 读回 **8 形参 `optional=True default=0`**、而权威修前 pc 读回 **6 形参、无缩进形参**（负控）），PC 严格档调用点（生成物 `:565`）传 **`paragraphProperties.Indent`/`.ParagraphIndent`（原始 DIP）**，**没有**用 `settings.Pap.*`（×300）。
#       **判据（用 W19B 新建的严格档腿 `--tier strict` 量；层级来源自证：严格档接手 270 例、宽松档 0 例）**：
#       **E2 ✅** `B-indent/lead-tab-a@w140@LTR@i24@default`：**tab 网格锚 `0.000000 → 24.000000`（Δ=0.000000）**、宽 Δ=+0.000989、`a` x Δ=0.000000 ⇒ **三项全绿**（修前只有宽是绿的、锚 Δ=−24.000000）；**E3 ✅** `B-indent/notab-control@w80@LTR@i24@default`：宽 `26.695312 → 50.695312`（Δ=+0.001979）。
#       **E4 ✅（射程外逐位不动）** 零缩进桶 `红=63 绿=41 /212` **与修前逐位相同**。
#       **E5 ✅（本波最锐的一条）** 孪生恒等式（我方 == `@i0` 孪生）**是缺陷态签名** ⇒ 修前违反 **0**、修后 **75**、最大差 `0.0020 → 24.0020` ⇒ **签名如期破裂**。
#       **E1 ⚠️ 部分达成，且**我预登记的目标写错了****：修前 `非0缩进 红=184 绿=0` → 修后 **`红=127 绿=57`**；**但按失配词精确核过**：`结构=FAIL` 共 **116 条、全部是 `@tab0`**（= 已登记的"本臂表达不出来的输入"族）⇒ **非 tab0 的结构失败 = 0** ⇒ **indent 机制完全修好**；残留的 **67 条非 tab0 位置红全部是同一个失配词 `行#1 i=0 取不到字符边界`**（另有 54 条 `@tab0` 位置红）⇒ 那是**另一族、与 indent 无关**，由 W19B **独立发现**（它只看到其中 19 条零缩进的）、**机制未归因** ⇒ 登记为 **`D-T6`**。⇒ **E1 原写的"红=92 绿=92"是错的**（它不知道这一族存在）；正确的读法是**按桶 + 按失配词**。
#   【⑤ 判据读数：**与 `#18` 逐位相同**（这是 A/B 两件的"射程外不动"断言）】应用门禁**两趟**（`run_dir=…/w19-gate1`、`…/w19-gate2`；基线 `baseline19-run2.md` **`1e917738b14b1b4e`**；stdout `gate19-run2.out` **`ff741db848cc119e`**、run1 `37d92e45d727964c`）⇒ `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、**6/6 `BASELINE … result=PASS`**，`drawn=260/144`、`colors=3960/2828`、`frames_good=14/14`、`shot_dims=938x938`、`cross_ae=0`、`leftover_after=0`、`scroll=ok`、`exit=143` **全部与 `#18` 相同**；`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 runs=167`。两趟都跑在**常驻 `:97`**（复用分支）。
#     **前提复读（预登记点名要做的）**：`samples/**` 对 `Indent`/`ParagraphIndent` 仍 **0 命中** ⇒ 应用门禁"逐位不变"的**前提成立**。
#   【⑥ `verify-all`（**10 步**）】`rc=0`、**步骤通过 10 / 失败 0 / 用例通过 871 / 跳过 2**、**第 10 步 `tline-gate（五臂）✅`**（日志 `$HOME/wfp-runs/w19-pre/verify-all-19.out`）。
#   【⑦ 五臂重取 + 登记表重钉到 `#19`（**本波特有**）】
#     · 五臂：先 `-c Release` 重建 CoverageProbe/TextLineProto（探针 dll `16013cbe1a0e268a`、mtime `15:41:37` ≥ shim mtime `15:30:15`），再逐条重跑，最后 `ln -f` 入 `arm-logs/`。**四支逐字节不变**：`tab-zero b9d81590f3fcd800`、`tab-anchor 99d72b385fe23a90`、`tab-rtl 419e8aaa9c72a9a0`、`textlineproto 4bceceeed570ba70` ⇒ **本波两件未进它们的射程**（它们直接调 `HbTextLineFactory.FormatParagraph`，不经 `HbTextFallback`；A 只改注释）。**`tline` 换了日志**：`89ad10ac614b4d3b → aa7259da9e2c77e8`（+54 B），**30 行差全是身份/管道**（shim sha/大小/mtime/行数、`[applocal]`/`[T0.7]` 的权威同步与 `一致 4/4`、`固定=实读`、上一趟 artifact 回显、带时间戳的清单文件名、`/tmp/tmp.*`、已用时间），**判据行逐字节相同**（`exact=73 diff=0`、记账 `1298/1298`、宽度 `>0.34DIP=0`、折叠判定一致 `1297/1298`、明细 `232/236`、`② Extent 余差清单 95`、`T3b ❌`）⇒ **四条在册读数逐条复现、`drift=0 gone=0`**。
#     · 登记表 `build/MilBridge/known-red.json` **`f9843bde351029dc` → `3bf26e12f320dece`**（`rev 8`、`generation.id=#19`、`instr_shim=fe1b7ed8fa3ed231…`、entries **仍 4 条**、每条 `caliber.instr_shim` 随世代更新、新增 `arms_retaken` 块；`expected_shape`/`expected_reading` **一字未改**）。
#     · 门禁：`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#19 tree_gen=same saved_shim=fe1b7ed8fa3ed231 gate=b37a5c9f55ae71a4`、`GATE_REASON=all-as-registered`、`rc=0`。**两极化重做**：删 `tline/T3b` ⇒ `registered=3 unregistered=1` + `GATE_REASON=unregistered-failure` + **`rc=1`**；真表 ⇒ **`rc=0`**。
#   【⑧ 等号读者 + T17A 工具（并列留档，`D-R4`）】读者 `no`（见 ②）；T17A 工具 `SHIM_IN_ARTIFACT=PASS artifact=f4a454c8fe69cdfe new=2/2 stable=14/14`（**只证下界、`PASS` 不区分内容**）。
#   【⑨ 本波产出的更正与新登记】**F1** 见 ③（P1 × 注释的新口径）｜**F2** 应用器里 P2 的**来源计数牙齿**从 `1/1` 变 `2/2` ⇒ 它**当场 `rc=1` 拦下了车道**（**它是对的**），按设计改口径并写明理由（**没有删牙齿**）｜**F3** 车道**自己的牙齿连错三版**（恒绿假牙齿 / 两次假红）＋一处仪器事故（注错失败却继续跑 ⇒ 陈旧突变被当结果）⇒ **已留档**，并立"牙齿写完必须两极化实测、注错失败要停"的形态｜**`D-R8`（新立）**：`TextLineProto`/`HbTextLineParity` 的 csproj **缺 `EnableDefaultCompileItems=false`** ⇒ 私有 obj 重定向下 `16×CS0579`（已证与改动无关：换修前 shim 同样报、错误码条数不变）｜**`D-T6`（新立）**：上述 `行#1 i=0 取不到字符边界` 族（67 非 tab0 + 54 tab0 位置红，**单一致命词**），**机制未归因**｜**W19B 推翻的三条**：预登记"把 env 去掉就是严格档腿"**不成立**（旧臂在 `Main` 里**无条件**置 `WPF_LINUX_TEXTLINE_FALLBACK=0`，且旧正控 `DiagHandled()<=0 ⇒ rc=2` **结构上**不允许严格档腿）、`W17A` 的"本臂对严格档零射程"与"腿 B 436 例全落宽松档"都只在**未改动的臂**上成立。
#   【⑩ 仪器版本（本波改动）】**改**：`build/shims/PresentationCore.HbTextLine.cs` **`fe1b7ed8fa3ed231`**｜`src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` **`daa1fe2a32d454cf`** ⇒ 生成物 `TextFormatterImp.Linux.cs` **`799e0366b312ec65`**｜`build/MilBridge/tests/PcLineOracle/Program.cs` **`a46e5e046583f69a`**（加 `--tier auto|strict|lenient` + 档位感知正控 + 逐例层级归因）；臂产物 `de25d3e0f8a00b00`（重建后）｜`build/MilBridge/known-red.json` **`3bf26e12f320dece`**（rev 8）。**未变**：`build/MilBridge/run.sh 3e513e88a4fa4ec9`、`HbTextLineParity/Program.cs 2e458928fc1577c2`、`tline-gate.sh b37a5c9f55ae71a4`、`verify-all.sh a68823631e8f8919`、`shim-in-artifact.sh e2e1a42b5f0e5b45`、`ShimShaReader/Program.cs 0ef57677afef9f6d`、`MinMaxProbe/Program.cs cfcf464457163280`、`integration-wave.sh 1172784c38fb8e31`、`port-lib.py d9f428a25f06dacc`。**本波报告**：`build/MilBridge/W19A-report.md` **`699cc39187268297`**（517 行）｜`build/MilBridge/W19B-report.md` **`da1d5fe7f55adfb6`**（34,024 B）。
#   【⑪ 收尾清单里还没做的（不许当绿）】① **`D-T6`**（`行#1 i=0 取不到字符边界` 族）**机制未归因** —— 它是**严格档腿上唯一残留的非 tab0 红**，判"严格档腿是否干净"必须先把它定性（**本波只登记**）② **严格档腿修后 `rc` 仍是 1**（因为 `D-T6` 67 条 + `@tab0` 族 54 条位置红）⇒ **不许拿整腿 rc 读成"B 没修好"**，也**不许**拿"整腿绿"当目标 ③ `D-R8`（两个 csproj 缺 `EnableDefaultCompileItems=false`）**只登记未修** ④ `D-R3` 的残项（真宿主可达性、AOT 镜像内 `X11Native` 的静态构造）**未测** ⑤ `D-T5`/`D-T4`/`D-T2-c`/`D-F2`/`D-E1`/`D-A1`~`D-A3`/`D-F1c`①c/`D-F3`/`7CJK candidates=45`/MIL 侧三个计数：**未动或未取到读数** ⑥ 任何新判据仍未接进 `verify-all.sh`。
#
# ================= 以下是本趟（#19）门禁的机读行（逐字取自 baseline 输出；run_dir=/home/links-dev/wfp-runs/w19-gate2） =================
# BASELINE-HEADER date=2026-09-16T15:50:52+08:00 display=:97 host=linksdev-VirtualBox kernel=6.8.0-138-generic
#   loadavg=0.41 1.21 2.07  cpu=3核
#   mem_available=3472 MB  mem_total=7923 MB
#   run_dir=/home/links-dev/wfp-runs/w19-gate2  repeat=3  timeout=90s  tier=both
#   git_head=(no git) samples_src=samples/WpfTextDemo  runner=run-wpftextdemo.sh
BASELINE tier=default rep=1 config=pc:f4a454c8fe69cdfe,bridge:d567c26f197ec1e3,pf:bd4e28e6a6f8b0e5,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:fe1b7ed8fa3ed231(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w19-gate2
BASELINE tier=default rep=2 config=pc:f4a454c8fe69cdfe,bridge:d567c26f197ec1e3,pf:bd4e28e6a6f8b0e5,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:fe1b7ed8fa3ed231(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w19-gate2
BASELINE tier=default rep=3 config=pc:f4a454c8fe69cdfe,bridge:d567c26f197ec1e3,pf:bd4e28e6a6f8b0e5,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:fe1b7ed8fa3ed231(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w19-gate2
BASELINE tier=env rep=1 config=pc:f4a454c8fe69cdfe,bridge:d567c26f197ec1e3,pf:bd4e28e6a6f8b0e5,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:fe1b7ed8fa3ed231(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w19-gate2
BASELINE tier=env rep=2 config=pc:f4a454c8fe69cdfe,bridge:d567c26f197ec1e3,pf:bd4e28e6a6f8b0e5,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:fe1b7ed8fa3ed231(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w19-gate2
BASELINE tier=env rep=3 config=pc:f4a454c8fe69cdfe,bridge:d567c26f197ec1e3,pf:bd4e28e6a6f8b0e5,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:fe1b7ed8fa3ed231(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w19-gate2
#   CENSUS(字形普查, 期望 id0≈0 / nonlatin>0 / maxid≈63151) T1C_CENSUS_SUMMARY frame=3 runs=167 handles=167 glyphs=1717 id0=0 nonlatin=421 maxid=63151 allnotdefruns=0 distinctpids=4 rc=0
#   CWIC(诊断趟 WPF_LINUX_CWIC_TRACE=1, 期望 materialize尺寸=96x96 fmt=…c90f Bgra32) NA [cwic-trace] source=0x5 ownedByWic=True materialize尺寸=96x96 foreignSources=0 shimGetSize=96x96（第二次=96x96 ok=True） format=6fddc324-4e03-4bfe-b185-3d77768dc90f → SKBitmap=96x96 colorType=Bgra8888 alphaType=Unpremul stride=384 bufferSize=36864 copyPixels=S_OK
[cwic-trace]   describe(source)= h=5 via=slot kind=FormatConverter foreign=0 ownedByWic=1 refs=1 size=96x96 rowBytes=384 fmt=6fddc324-4e03-4bfe-b185-3d77768dc90f pixels=yes decoded=1
#   WIC_NATIVE(诊断趟 WPF_LINUX_WIC_TRACE=1, 期望 prc=(0,0,96,96) 且 REFUSE=0) refuse=0
0 WIC_TRACE COPY_PIXELS h=5 96x96 foreign=0 prc=(0,0,1x1)
WIC_TRACE COPY_PIXELS_SUBRECT prc=(0,0,1x1) dst=4 cb=4
WIC_TRACE COPY_PIXELS h=5 96x96 foreign=0 prc=null
#   CENSUS_ORPHANS CENSUS_ORPHANS before=0 after=0；自起 Xvfb=无）
#   CENSUS_ALL（普查全量仪表行，前向兼容：新仪表自动入基线）
#     CENSUS_ORPHANS before=0 after=0
#     [GLYPH_CENSUS] frame=1 runs(绘制次数)=0 不同句柄=0 全notdef的run=0 glyphs=0 id0=0 maxId=0 非拉丁(id>=0x1000)=0 桶[0]=0 [1,FF]=0 [100,FFF]=0 [1000,3FFF]=0 [>=4000]=0 面标识: pid==0的run=0 不同面数=0 渲染器=(未知) hook成功=0 hook失败=0 无渲染器=0 资源查不到=0  [无信息：所有 run 的面标识相同 —— 若全为 0 则可能是字段没被填]
#     [GLYPH_CENSUS] 原点Y汇总: runs=0 distinct_origin_y=0  Y值(DIP)=[]
#     [GLYPH_CENSUS] frame=2 runs(绘制次数)=167 不同句柄=167 全notdef的run=0 glyphs=1717 id0=0 maxId=63151 非拉丁(id>=0x1000)=421 桶[0]=0 [1,FF]=1280 [100,FFF]=16 [1000,3FFF]=122 [>=4000]=299 面标识: pid==0的run=0 不同面数=4 渲染器=WpfGfx.Linux.Text.TextRenderer hook成功=167 hook失败=0 无渲染器=0 资源查不到=0  [有信息：确有多个不同面]
#     [GLYPH_CENSUS] 原点Y汇总: runs=167 distinct_origin_y=12  Y值(DIP)=[前8个:10.210,10.210,11.139,12.067,12.995,24.133,25.107,29.292…]
#     [GLYPH_CENSUS] 相关性: originDIP.y=10.210 的 run 数=13 其设备Y去重数=13  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=10.210 的 run 数=27 其设备Y去重数=7  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=11.139 的 run 数=17 其设备Y去重数=2 设备Y=[80.631,525.487]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=12.067 的 run 数=35 其设备Y去重数=8  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=12.995 的 run 数=48 其设备Y去重数=25  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=24.133 的 run 数=1 其设备Y去重数=1 设备Y=[62.639]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=25.107 的 run 数=5 其设备Y去重数=1 设备Y=[540.038]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=29.292 的 run 数=4 其设备Y去重数=2 设备Y=[162.146,323.515]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=45.589 的 run 数=7 其设备Y去重数=2 设备Y=[179.122,340.491]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=61.886 的 run 数=2 其设备Y去重数=1 设备Y=[196.098]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=78.183 的 run 数=5 其设备Y去重数=1 设备Y=[213.074]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=94.479 的 run 数=3 其设备Y去重数=1 设备Y=[230.050]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] run#0 handle=0x00000018 n=11 id0=0 max=91 pid=0x20000003 originDIP=(0.000,24.133) devX=37.500 devY=62.639 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,37.500] first16=58,83,73,55,72,91,87,39,72,80,82
#     [GLYPH_CENSUS] run#1 handle=0x0000001c n=2 id0=0 max=36710 pid=0x20000005 originDIP=(0.000,11.139) devX=37.500 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=18749,36710
#     [GLYPH_CENSUS] run#2 handle=0x0000001d n=3 id0=0 max=18 pid=0x20000004 originDIP=(24.000,11.139) devX=62.500 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,18,3
#     [GLYPH_CENSUS] run#3 handle=0x0000001e n=3 id0=0 max=27897 pid=0x20000005 originDIP=(35.672,11.139) devX=74.658 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=27897,27147,11929
#     [GLYPH_CENSUS] run#4 handle=0x0000001f n=3 id0=0 max=18 pid=0x20000004 originDIP=(71.672,11.139) devX=112.158 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,18,3
#     [GLYPH_CENSUS] run#5 handle=0x00000020 n=4 id0=0 max=47307 pid=0x20000005 originDIP=(83.344,11.139) devX=124.316 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=9492,21230,15698,47307
#     [GLYPH_CENSUS] run#6 handle=0x00000021 n=3 id0=0 max=121 pid=0x20000004 originDIP=(131.344,11.139) devX=174.316 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,121,3
#   ORIGIN_Y(判据⑦ 行推进；阈值 10；根治前=6 / 根治后=12) 原点Y汇总: runs=167 distinct_origin_y=12  Y值(DIP)=[前8个:10.210,10.210,11.139,12.067,12.995,24.133,25.107,29.292…] verdict=PASS 取值频次:      2 originDIP=(83.344,11.139)       2 originDIP=(71.672,11.139)       2 originDIP=(35.672,11.139)       2 originDIP=(24.000,11.139) 
#   读图（保留格；普查/计数绿 ≠ 像素对 —— T1d 已登记这条预测假绿）：需人工/视觉复核 run_dir 下的 *-after.png
#   REAPED_ORPHANS total=0 detail=none（辅助趟漏下的孤儿；按精确 argv+ppid==1+PID 回收）
#   BRIDGE_SRC_STALE(桥→源 身份；期望 no；yes=部署件不是当前源编的⇒本趟读数作废) no basis=pub=b6acdba4f01599d8 now=b6acdba4f01599d8 so_file_match=yes
#
# ================= ↓↓↓ 历史：#18 表头与 #18 机读行（**已被上面的 #19 表头取代，不再生效**）↓↓↓ =================
# BASELINE-HEADER date=2026-09-16T15:15:58+08:00 display=:97 host=linksdev-VirtualBox kernel=6.8.0-138-generic
#   loadavg=1.37 2.23 1.91（门禁启动时刻；负载闸门 1min ≤ 12 通过）  cpu=3核
#   mem_available=（见机读行同目录的 baseline 文件头）  mem_total=7923 MB
#   run_dir=/home/links-dev/wfp-runs/w18-gate2  repeat=3  timeout=90s  tier=both
#   git_head=(no git) samples_src=samples/WpfTextDemo  runner=run-wpftextdemo.sh（5dfb2635b87bb351）
# RE-FROZEN #18 —— 内容 = **`D-R3`：给两个"产品侧无保护"的 `NativeLibrary.SetDllImportResolver` 安装点加守卫**（预登记 `docs/WAVE18-PREREGISTRATION.md`，含其**修订 v2**）。
#   三件：**V1** `build/shims/Win32ShimResolver.cs`（`[ModuleInitializer]`，编进 **WindowsBase / PresentationCore / UIAutomationTypes / UIAutomationProvider** 四个程序集）｜**V2** `src/WpfGfx.Linux/Windowing/X11Native.cs`（静态构造）｜**V3** `build/DirectWrite.Linux/WicClosedLoop/Program.cs`（**删掉死映射**）。
#   **相对 `#17` 五位变了（本波是单波里动得最多的一次）**：**`bridge caf7baf9e67719aa → d567c26f197ec1e3`**（**桥重发**：V2 是桥源）、**`pc df6dbb1c2bfb4162 → 663114436443d2de`**、**`windowsbase e6216fe961a2bfb9 → 1114a28ec5a03ab7`**（**这一位自 `#8` 以来第一次动**）、**`dwf b6743030ff1eb907 → 0ed422ef2dd46445`**、`pf`（环成员）。**未变**：`provider`/`win32shim`/`wic_shim`/**`hbtextline`（本波一个字节未动）**。
#   【① 两件的 sha 链（三态，含"收窄"这一次）】V1 `build/shims/Win32ShimResolver.cs`：修前 **`ff3c53964cb8328b`** → 守卫版 `37b65d0ede827650` → **收窄后 `0735327b6ca3ae4b`**（31,607 B）｜V2 `src/WpfGfx.Linux/Windowing/X11Native.cs`：修前 **`045faa9b0785f6d2`** → 守卫版 `12d7cf8217b34c0c` → **收窄后 `8ede4d8a13cb3a28`**（17,068 B）｜V3 `build/DirectWrite.Linux/WicClosedLoop/Program.cs`：`ef09e6e09e8e6f75` → **`f7c7fd61ef5c8ad8`**。
#   【② 本波最值钱的一条：**"无条件自证"会污染以"段数"为尺子的判据 ⇒ 已收窄**】
#     · 第一版（车道 V18A）为了让"装了没生效"能当场发现，做了**无条件自证**（装完就用真 `[DllImport]` 走一次）⇒ 实测**正常路径就把 shim 提前 dlopen**：`/proc/self/maps` 里 `libwpfwin32.so` **0 → 5 段**；V2 更糟 —— `X11Native` 的静态构造在正常路径就把 **`libX11.so.6` 载进来（0 → 6 段、TOTAL +35）**。
#     · **主控裁决 = 收窄**（自证**只在"我们输了竞态"的分支里跑**）。**理由本身是判据**：本项目的**内存类主判据是"段数 / Σ虚拟"**（`D-F1c` 线的口径）⇒ **无条件多一次 dlopen 就是往那把尺子里塞一个新映射**，而"数值判据推论不变"是**论证不是读数**。
#     · **收窄的验收核心（实测，见车道报告 `narrow-maps.log`）**：`libwpfwin32.so`：V1 PC **修前 0→0 / 收窄前 0→5 / 收窄后 0→0** ✓；`libX11`：V2 **修前 0→0 / 收窄前 0→6 / 收窄后 0→0** ✓（V2 收窄后 TOTAL **244→244**）。
#       **机器断言下在"针数"上**（TOTAL 在同目标不同进程间有 ±2 抖动；V1 收窄后 TOTAL 仍 +13 与修前 +15 同源 = 自然触发自身的 cctor/JIT，与 dlopen 无关）。
#   【③ 两极化红证（`prefix.log` `e1e863738df59fae`（修前，**已被后续重跑覆盖、无副本，车道已写勘误**）/ `postfix.log` `0c8bb85d7d0255cc`（修后））】
#     · **(a) 抢先者映射同名 ⇒ 无害** ✓：四件产品程序集 `TRIGGER=natural NO_THROW`、`ResolverConflict=True`、**`SelfCheckShimVersion=1`**（真 `[DllImport]` 证明赢家接到的是我们的 shim）；而 **`variant=none` 时该值为 0** ⇒ **自证确实没在正常路径跑**（收窄的行为指纹）。V2：`replica` ⇒ `CCTOR_RESULT=NO_THROW` + `SelfCheckX11NameResolved=True`。
#     · **(b) 抢先者不映射我们的名字 ⇒ 响亮且点名** ✓：`InvalidOperationException: WPF-on-Linux: 本程序集的 'user32.dll' 解析不到 —— 当前生效的解析器不是我们这一个…`（列全 6 个名字）。V2 的 `broken` 变体同理点名 `libX11.so.6`。
#     · **非空泛** ✓：隔离夹具（依赖带齐、故意无 shim）⇒ 收窄后我们**赢了竞态、自证不跑**，缺件由**原有解析路径**在**首个真 `[DllImport]`** 处响亮失败（带候选路径与修复命令）—— **不是**守卫吞掉（守卫内部的非空泛证明由 `broken` 变体给出）。
#   【④ 桥重发的红证（预登记 §3 要求的三条，逐条实测）】① `BRIDGE_SRC_FP` **两侧一致** = **`b6acdba4f01599d8`**（发布记录与现树重算都是它）；② **新桥里确实编进了本波代码**（`grep -a`：ASCII 标识符 `X11Native` 命中 **1**、`SelfCheckX11NameResolved` 命中 **4**；中文文案 `当前生效的解析器不是我们这一个` 以 **UTF-16LE** 命中 **1**、UTF-8 命中 0 —— 托管字面量的既定形态）；③ **旧桥已留档可回退**：`$HOME/wfp-runs/w18-pre/wpfgfx_cor3.caf7baf9e67719aa.so`（4,983,696 B），新桥 `d567c26f197ec1e3`（4,987,840 B），`cmp` 不同（预期）。
#   【⑤ 判据读数：**逐位不变**（这是本波"位移表"的核心预测）】应用门禁**两趟**（`run_dir=…/w18-gate1`、`…/w18-gate2`；基线 `baseline18-run2.md` **`8c57ba2db68b43dc`**；stdout `gate18-run2.out` **`bfa7c18baa53c702`**、run1 `8a2e795179c7b22a`）⇒ `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、**6/6 `BASELINE … result=PASS`**，且 `drawn=260/144`、`colors=3960/2828`、`frames_good=14/14`、`shot_dims=938x938`、`cross_ae=0`、`leftover_after=0`、`scroll=ok`、`exit=143` **与 `#17` 逐位相同**；`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 runs=167`。
#     **装置来源**：两趟都是 **常驻 `:97`**（runner 走"复用已存在的 X server"分支 —— 纪律 30 的正路；`:97` 在波前由主控用 `setsid` 重新起过，因为上一轮的常驻进程已不在）。
#   【⑥ 五臂在册红门禁 + 登记表】`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#16 tree_gen=same saved_shim=bc04c05ab6d8d82a gate=b37a5c9f55ae71a4`、`GATE_REASON=all-as-registered`、`rc=0`（登记表 `build/MilBridge/known-red.json` **`f9843bde351029dc`**、`generation.id=#16`、entries 4、`changelog rev 7`）。
#     **为什么本波不需要重取臂/重钉表**：世代只绑 `run.sh`/`Parity`/**`PresentationCore.HbTextLine.cs`**（已核 `tline-gate.sh:137` 的 `SH_SHIM` 只绑那**一个**文件，**不是**整个 `build/shims/**`），而本波**没碰它** ⇒ 实测 `tree_gen=same`。
#   【⑦ 等号读者 + T17A 工具（并列留档，`D-R4`）】读者：`SHIM_SHA=no reason=content-compare artifact=663114436443d2de artifact_bytes=4196864 shim=bc04c05ab6d8d82a product_sha16=bc04c05ab6d8d82a tree_sha16=bc04c05ab6d8d82a cmp=full64`、`rc=0`；T17A 工具：`SHIM_IN_ARTIFACT=PASS artifact=663114436443d2de new=2/2 stable=14/14`、`rc=0`（**它只证下界、`PASS` 不区分内容**）。
#   【⑧ `verify-all` + 波内自检】`close-wave.sh`（`15:08:49 → 15:12:43`）：**`native_rebuilt=0`、`bridge_republished=1`**（`rc=0`）、`verify_all=PASS`（**10 步 0 失败 / 871 通过 2 跳过**）；身份自检：桥源指纹两侧一致 ✅、生成物指纹 `state=ok（PC/WB/PF）` ✅、应用器审计 `miss=0` ✅、**输入稳定性 波前==波后 = `da68a95174e2ec5ab9b141c554de5afd31b58dccb139b291ae6d25526c072217`** ✅。`hbtextline_shim_stale=no`（`basis=auth`）、`BRIDGE_SRC_STALE=no`、`APPSYNC` 非 PASS（`D-A1`，与 `#16`/`#17` 同形）。
#   【⑨ 本波产出的**更正与新登记**】
#     · **`D-R3` 的严重性上调（从"潜在"改为"可达"）**：只读审计 R17C 曾断言"外部安装者**只能输**"，**被 V18A 用实测推翻** —— `Assembly.LoadFrom(pc)` 之后**外国解析器装得上**（`FOREIGN_INSTALL=OK`）⇒ **模块初始化器不是加载期跑的** ⇒ 产品丢竞态**可达**（红证即走这条路径）。⇒ 本波修的就是这条**可达**的路径。
#     · **预登记的位移表**漏了一项（已记）：**`dwf` 也变**。机制 = `build/DirectWriteForwarder.Linux/DirectWriteForwarder.Linux.csproj:76-77` 用 **HintPath 引用 `WindowsBase.dll`** ⇒ WB 字节一变，Roslyn 确定性输出把**引用件字节**纳入输入哈希 ⇒ `dwf` 跟着变（**与 `pf`/`reach` 环成员同族机制**）。⇒ 记作**预登记不完整**，**不是未归因位移**。
#     · **`integration-wave.sh` 的 `ORDER` 缺 `WpfGfx.Linux`（已修，`D-R7` 同族："生效了但没进波"）**：改了 `src/WpfGfx.Linux/**` 之后，波会重发桥（拿到修后代码），但 **Debug 可见位与各 app-local 副本仍是修前的** —— 而后者**正是应用门禁加载的那一份** ⇒ 读数会漏掉该改动。**主控已加为 `ORDER` 第一项**（它是叶子工程：csproj 无任何 `ProjectReference`、只用 SkiaSharp）：`build/integration-wave.sh` **`770419556b9597df`（38,072 B）→ `1172784c38fb8e31`（38,717 B）**；干跑当时即给出 `桥重发=是`。
#     · **判据口径的两处修订（原文保留在预登记 v1）**：① V2 的 (a)/(b) 判据在本机**互斥**（`libX11.so.6` 是系统可解析名 ⇒ 两种抢先者可观察面相同）⇒ 改为"**响亮 ⟺ 我们自己映射的名字解析不到**"；② **收窄的代价如实登记**：判据**① 不再由守卫行使**（车道用 `realcall` 直测到 `REAL_DLLIMPORT=OK`，但**① 的修前对照没测过**、**V2 的 ① 没测过**），判据**④ 的"安装点响亮"退回修前同款行为**（由首个真 `[DllImport]` 响亮失败，已实测）。
#   【⑩ 仪器版本（本波新增/改动）】**改**：`build/shims/Win32ShimResolver.cs` **`0735327b6ca3ae4b`**、`src/WpfGfx.Linux/Windowing/X11Native.cs` **`8ede4d8a13cb3a28`**、`build/DirectWrite.Linux/WicClosedLoop/Program.cs` **`f7c7fd61ef5c8ad8`**、`build/integration-wave.sh` **`1172784c38fb8e31`**。**未变**：`build/shims/PresentationCore.HbTextLine.cs` **`bc04c05ab6d8d82a`**（世代绑定）、`build/MilBridge/run.sh 3e513e88a4fa4ec9`、`HbTextLineParity/Program.cs 2e458928fc1577c2`、`build/MilBridge/tools/tline-gate.sh b37a5c9f55ae71a4`、`build/MilBridge/known-red.json f9843bde351029dc`、`verify-all.sh a68823631e8f8919`、`build/MilBridge/tools/shim-in-artifact.sh e2e1a42b5f0e5b45`、`build/MilBridge/tests/ShimShaReader/Program.cs 0ef57677afef9f6d`、`build/MilBridge/tests/PcLineOracle/Program.cs 544aab374ee8e1a6`（+`known-red.txt 89324f1f643167e5`）、`build/MilBridge/tests/MinMaxProbe/Program.cs cfcf464457163280`、`build/port-lib.py d9f428a25f06dacc`、`build/MilBridge/tools/applier-audit-expected.txt eecf8f28d3e6b9f9`、`build/check-appliers.sh 025d7f5148af36b9`、`build/DirectWrite.Linux/wic-shim/applocal-expect.py 6eafbea14e7ea41e`、`check-applocal-sync.sh aad23482f84bdf44`。**本波报告**：`build/MilBridge/V18A-report.md` **`2d7809699ebf51d4`**（606 行；§10 = 收窄节）。
#   【⑪ 收尾清单里还没做的（不许当绿）】① `D-R3` 的**产品侧守卫**已落，但**仍有 9 个安装点里其余 7 个**只在只读审计里被枚举过（本波只动产品侧那两个 + 删一个死映射）；② **`D-R3` 的"真宿主里会不会走到"没测**（只证了路径可达）；③ **AOT 镜像内 `X11Native` 静态构造是否会被执行、其 `Assembly` 身份**仍未测（R17C §7-③，需运行期诊断）；④ `P4`（`HasOverflowed` 注释）与**严格档 indent 缺口**仍留到下一波（同批动 shim）；⑤ `D-T5`/`D-T4`/`D-T2-c` 只登记未修；⑥ 新判据仍未接进 `verify-all.sh`；⑦ `D-F2` 专项、`D-E1`、`D-A1`/`D-A2`/`D-A3`、`D-F1c`①c、`D-F3`、`7CJK candidates=45`、MIL 侧三个计数：**未动或未取到读数**。
#
# ================= 以下是本趟（#18）门禁的机读行（逐字取自 baseline 输出；run_dir=/home/links-dev/wfp-runs/w18-gate2） =================
# BASELINE-HEADER date=2026-09-16T15:15:58+08:00 display=:97 host=linksdev-VirtualBox kernel=6.8.0-138-generic
#   loadavg=0.82 1.64 1.73  cpu=3核
#   mem_available=3199 MB  mem_total=7923 MB
#   run_dir=/home/links-dev/wfp-runs/w18-gate2  repeat=3  timeout=90s  tier=both
#   git_head=(no git) samples_src=samples/WpfTextDemo  runner=run-wpftextdemo.sh
BASELINE tier=default rep=1 config=pc:663114436443d2de,bridge:d567c26f197ec1e3,pf:d8bfdc23f260ccd2,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w18-gate2
BASELINE tier=default rep=2 config=pc:663114436443d2de,bridge:d567c26f197ec1e3,pf:d8bfdc23f260ccd2,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w18-gate2
BASELINE tier=default rep=3 config=pc:663114436443d2de,bridge:d567c26f197ec1e3,pf:d8bfdc23f260ccd2,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w18-gate2
BASELINE tier=env rep=1 config=pc:663114436443d2de,bridge:d567c26f197ec1e3,pf:d8bfdc23f260ccd2,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w18-gate2
BASELINE tier=env rep=2 config=pc:663114436443d2de,bridge:d567c26f197ec1e3,pf:d8bfdc23f260ccd2,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w18-gate2
BASELINE tier=env rep=3 config=pc:663114436443d2de,bridge:d567c26f197ec1e3,pf:d8bfdc23f260ccd2,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w18-gate2
#   CENSUS(字形普查, 期望 id0≈0 / nonlatin>0 / maxid≈63151) T1C_CENSUS_SUMMARY frame=3 runs=167 handles=167 glyphs=1717 id0=0 nonlatin=421 maxid=63151 allnotdefruns=0 distinctpids=4 rc=0
#   CWIC(诊断趟 WPF_LINUX_CWIC_TRACE=1, 期望 materialize尺寸=96x96 fmt=…c90f Bgra32) NA [cwic-trace] source=0x5 ownedByWic=True materialize尺寸=96x96 foreignSources=0 shimGetSize=96x96（第二次=96x96 ok=True） format=6fddc324-4e03-4bfe-b185-3d77768dc90f → SKBitmap=96x96 colorType=Bgra8888 alphaType=Unpremul stride=384 bufferSize=36864 copyPixels=S_OK
[cwic-trace]   describe(source)= h=5 via=slot kind=FormatConverter foreign=0 ownedByWic=1 refs=1 size=96x96 rowBytes=384 fmt=6fddc324-4e03-4bfe-b185-3d77768dc90f pixels=yes decoded=1
#   WIC_NATIVE(诊断趟 WPF_LINUX_WIC_TRACE=1, 期望 prc=(0,0,96,96) 且 REFUSE=0) refuse=0
0 WIC_TRACE COPY_PIXELS h=5 96x96 foreign=0 prc=(0,0,1x1)
WIC_TRACE COPY_PIXELS_SUBRECT prc=(0,0,1x1) dst=4 cb=4
WIC_TRACE COPY_PIXELS h=5 96x96 foreign=0 prc=null
#   CENSUS_ORPHANS CENSUS_ORPHANS before=0 after=0；自起 Xvfb=无）
#   CENSUS_ALL（普查全量仪表行，前向兼容：新仪表自动入基线）
#     CENSUS_ORPHANS before=0 after=0
#     [GLYPH_CENSUS] frame=1 runs(绘制次数)=0 不同句柄=0 全notdef的run=0 glyphs=0 id0=0 maxId=0 非拉丁(id>=0x1000)=0 桶[0]=0 [1,FF]=0 [100,FFF]=0 [1000,3FFF]=0 [>=4000]=0 面标识: pid==0的run=0 不同面数=0 渲染器=(未知) hook成功=0 hook失败=0 无渲染器=0 资源查不到=0  [无信息：所有 run 的面标识相同 —— 若全为 0 则可能是字段没被填]
#     [GLYPH_CENSUS] 原点Y汇总: runs=0 distinct_origin_y=0  Y值(DIP)=[]
#     [GLYPH_CENSUS] frame=2 runs(绘制次数)=167 不同句柄=167 全notdef的run=0 glyphs=1717 id0=0 maxId=63151 非拉丁(id>=0x1000)=421 桶[0]=0 [1,FF]=1280 [100,FFF]=16 [1000,3FFF]=122 [>=4000]=299 面标识: pid==0的run=0 不同面数=4 渲染器=WpfGfx.Linux.Text.TextRenderer hook成功=167 hook失败=0 无渲染器=0 资源查不到=0  [有信息：确有多个不同面]
#     [GLYPH_CENSUS] 原点Y汇总: runs=167 distinct_origin_y=12  Y值(DIP)=[前8个:10.210,10.210,11.139,12.067,12.995,24.133,25.107,29.292…]
#     [GLYPH_CENSUS] 相关性: originDIP.y=10.210 的 run 数=13 其设备Y去重数=13  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=10.210 的 run 数=27 其设备Y去重数=7  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=11.139 的 run 数=17 其设备Y去重数=2 设备Y=[80.631,525.487]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=12.067 的 run 数=35 其设备Y去重数=8  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=12.995 的 run 数=48 其设备Y去重数=25  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=24.133 的 run 数=1 其设备Y去重数=1 设备Y=[62.639]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=25.107 的 run 数=5 其设备Y去重数=1 设备Y=[540.038]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=29.292 的 run 数=4 其设备Y去重数=2 设备Y=[162.146,323.515]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=45.589 的 run 数=7 其设备Y去重数=2 设备Y=[179.122,340.491]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=61.886 的 run 数=2 其设备Y去重数=1 设备Y=[196.098]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=78.183 的 run 数=5 其设备Y去重数=1 设备Y=[213.074]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=94.479 的 run 数=3 其设备Y去重数=1 设备Y=[230.050]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] run#0 handle=0x00000018 n=11 id0=0 max=91 pid=0x20000003 originDIP=(0.000,24.133) devX=37.500 devY=62.639 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,37.500] first16=58,83,73,55,72,91,87,39,72,80,82
#     [GLYPH_CENSUS] run#1 handle=0x0000001c n=2 id0=0 max=36710 pid=0x20000005 originDIP=(0.000,11.139) devX=37.500 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=18749,36710
#     [GLYPH_CENSUS] run#2 handle=0x0000001d n=3 id0=0 max=18 pid=0x20000004 originDIP=(24.000,11.139) devX=62.500 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,18,3
#     [GLYPH_CENSUS] run#3 handle=0x0000001e n=3 id0=0 max=27897 pid=0x20000005 originDIP=(35.672,11.139) devX=74.658 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=27897,27147,11929
#     [GLYPH_CENSUS] run#4 handle=0x0000001f n=3 id0=0 max=18 pid=0x20000004 originDIP=(71.672,11.139) devX=112.158 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,18,3
#     [GLYPH_CENSUS] run#5 handle=0x00000020 n=4 id0=0 max=47307 pid=0x20000005 originDIP=(83.344,11.139) devX=124.316 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=9492,21230,15698,47307
#     [GLYPH_CENSUS] run#6 handle=0x00000021 n=3 id0=0 max=121 pid=0x20000004 originDIP=(131.344,11.139) devX=174.316 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,121,3
#   ORIGIN_Y(判据⑦ 行推进；阈值 10；根治前=6 / 根治后=12) 原点Y汇总: runs=167 distinct_origin_y=12  Y值(DIP)=[前8个:10.210,10.210,11.139,12.067,12.995,24.133,25.107,29.292…] verdict=PASS 取值频次:      2 originDIP=(83.344,11.139)       2 originDIP=(71.672,11.139)       2 originDIP=(35.672,11.139)       2 originDIP=(24.000,11.139) 
#   读图（保留格；普查/计数绿 ≠ 像素对 —— T1d 已登记这条预测假绿）：需人工/视觉复核 run_dir 下的 *-after.png
#   REAPED_ORPHANS total=0 detail=none（辅助趟漏下的孤儿；按精确 argv+ppid==1+PID 回收）
#   BRIDGE_SRC_STALE(桥→源 身份；期望 no；yes=部署件不是当前源编的⇒本趟读数作废) no basis=pub=b6acdba4f01599d8 now=b6acdba4f01599d8 so_file_match=yes
#
# ================= ↓↓↓ 历史：#17 表头与 #17 机读行（**已被上面的 #18 表头取代，不再生效**）↓↓↓ =================
# BASELINE-HEADER date=2026-09-16T12:44:52+08:00 display=:97 host=linksdev-VirtualBox kernel=6.8.0-138-generic
#   loadavg=2.03 3.60 2.80（门禁启动时刻；负载闸门 1min ≤ 12 通过）  cpu=3核
#   mem_available=3197 MB  mem_total=7923 MB
#   run_dir=/home/links-dev/wfp-runs/w17-gate3  repeat=3  timeout=90s  tier=both
#   git_head=(no git) samples_src=samples/WpfTextDemo  runner=run-wpftextdemo.sh（5dfb2635b87bb351）
# RE-FROZEN #17 —— 内容 = **PC 侧三件**：**P1**（`AssemblyMetadata` 把"产物里编的是哪个 shim"从**下界**升级成**等号**）＋ **P2**（`D-T3`：宽松回退的 indent 接线，`Indent`/`ParagraphIndent` 各归其槽）＋ **P3**（`D-T2` 真身：min 宽度探针补 `TextModifier` 作用域实参）。**`build/shims/PresentationCore.HbTextLine.cs` 本波**一个字节未动**（仍 `bc04c05ab6d8d82a`）** ⇒ 世代绑定（`run.sh`/`Parity`/shim）**未变**，五臂日志与登记表**无需重取/重钉**（实测 `generation=#16 tree_gen=same`、`drift=0 gone=0 unregistered=0`）。
#   ⚠️ **本波发了两次波，两次都留档（第一次的那份产物**不能**当基线，原因已定案）**：
#     · **第一趟**（`close-wave-w17`，`12:24:12`）：`W17_WAVE_EXIT=0`、`verify_all=PASS`，但它**静默抹掉了 P1** —— 波第 1 步 `python3 build/port-lib.py <proj>` **从上游重新生成** `PresentationCore.Linux.csproj`，把 P1 当初**手加**的那 6 行 `<Import … HbTextLineShimSha.targets />` 连同重写掉了（`26ce64b8f4452ed4`/205,939 B → `e2558faa0cc6b5d1`/205,471 B），`pc` 从 `18c49eec6992c7d9`（含元数据）退回 **`ac16320a14f549d4`（4,194,816 B、无元数据）**。
#       **所有绿判据都没红**：波的身份检查量的是"源 → 产物"（`state=ok`），**不是**"我上次手加的东西还在"；PC 那行还报"0 错误 0 警告"。**唯一红它的是 P1 自己的等号读者**（`ShimShaReader` 给 `NOINFO reason=attribute-absent`）。
#       ⇒ **已立纪律 38**：往**生成物**里手加的东西必须把"加它的动作"放进**生成机制**，且**红线判据 = 跑一次 `port-lib.py` 之后它还在**。车道 W17C 已按正确通道重落（新应用器 `patch-presentationcore-hbtextline-shimsha.py` **`81f821ae225eb3a0`**，并登记进 `integration-wave.sh` 的 `APPLIERS_EXPLICIT` 与 `applier-audit-expected.txt` ⇒ **摘掉它会判红**）。
#     · **第二趟**（`close-wave-w17b`，`12:42:58`）：`W17B_WAVE_EXIT=0`、`verify_all=PASS`（10 步 0 失败 / 871 通过）、输入稳定 `db3110fc…`；**接线活过了波** —— 波后 csproj 里 import 命中 **1**，等号读者在波后 `pc df6dbb1c2bfb4162`（4,195,328 B）上给 **`SHIM_SHA=no`**（`product_sha16 == tree_sha16`、`cmp=full64`）⇒ **P1 现在是耐久的**。**本表头取自第二趟之后的产物。**
#   【① 三件的落地与**各自**的判据读数（逐件、四元组口径）】
#     · **P1**（车道 W17C）：应用器新增 `patch-presentationcore-hbtextline-shimsha.py`（生成 `HbTextLineShimSha.targets` **`3127e82b76ce8c24`** 并只插 3 行到 `Sdk.targets` 锚点前；幂等、`--check` rc=0/1、`--prove` 只读）。**三态读者** `build/MilBridge/tests/ShimShaReader/**`（`PEReader`+`MetadataReader`、**不加载程序集**；`rc 0=no / 1=yes / 2=NOINFO`；7 个 `NOINFO` 用例）。
#       **两极化（A/B/C）**：**A** 改 shim 一字节 + `cp -p` 保旧 mtime + **不重建** ⇒ **`yes`**（**旧的 mtime 代理在这里给假绿 `no`**）；**B** 源改回 + **不重建** ⇒ **`yes`**（判据是**内容**、不是"有没有重建"）；**C** 重建 ⇒ **`no`**。**重落后的第二级红证**：摘掉接线 ⇒ `--check rc=1` + applier 审计**红** + 读者 **`NOINFO attribute-absent rc=2`**；还原 ⇒ **`no rc=0`**。
#       **P1 的"行为中性"是**读数**不是论证**（三点对照，主控）：**P1-off**（`#16` 的 `c0763fc10173e7ff` 副本）与 **P1-only**（`18c49eec6992c7d9`）跑同一条臂 ⇒ stdout **逐字节相同**（`2bca3316fcdb264b`：非0缩进 红=184/224、`rc=1`）；而 **P1+P2**（`1280323c9173bcde`）⇒ 红=72/224、`rc=0`、与前者差 **917 行** ⇒ **P1 中性成立 + P2 效应可分离，一把取到**。
#     · **P2**（车道 W17B；应用器 `a3357070dae6de99`、生成物 `9fd04d10a6479dcd`）：`TryFormatLine` 收 `indentDip`/`paragraphIndentDip` 两个 DIP 形参，站点1 传 **`paragraphProperties.Indent` / `.ParagraphIndent`（原始 DIP）** —— **没有**用 `settings.Pap.*`（那是**理想整数 ×300**，PI=24 DIP 到达时是 **7200**，`WAVE17` §0.0 的 F2）。**评据表 E1–E8**（用 W17A 的臂 `PcLineOracle` 判）：
#       **E1** `rc=1（未登记失败 228）→ rc=0（未登记 0 / 红 116 / 绿 172 / 不可比 148）` ✅（登记表 136 条全在 `@…@tab0` 臂，见 ⑩）
#       **E2** 非0缩进 `红 184 → 红 0`（拆开：**`@default` 臂 92 条修前红 → 92/92 全绿**）✅ ｜ **E3** `PI≠0 红 88 → 红 0`（`@default` 臂 44/44 全绿）**且全表无一条 `Δ≈+7200/14400`** ⇒ **不是坏修法** ✅
#       **E4** `notab-control@w80@LTR@i24`：宽 `26.695312 → 50.695312`（Δ=+0.001979）、`x(a)=24.000000`、`x(b)=37.347656`（三个 Δ ≤0.002）✅ ｜ **E5** `lead-tab-a@w140@LTR@i24`：宽 `109.347656`Δ=+0.000989、**tab 网格锚 `0.000000 → 24.000000`（Δ=0.000000，精确复位）**、`a x=96.000000` ⇒ **三项全绿** ✅
#       **E6** 零缩进同层对照 **`52/52` 逐位不动** ✅（射程外不动的机器断言）｜ **E8** 正控 `relaxedHandled=496>0`、`relaxedFailed=0` ✅（`relaxedCalls` 544→496 是正常收敛，拿 544 当判据会**假红**）
#       **E7 ❌ 判据本身错了、已被推翻**：E7 要求"孪生恒等式修后仍违反 0"，实测 **违反 102/144** —— 而那条恒等式**修前成立恰恰因为两边错得一样**（`i24` 本就该比 `@i0` 宽 24）⇒ **它把缺陷态当成了规律**，已降级为"缺陷态指纹"，复跑时**不许**把 102 当红。
#     · **P3**（车道 W17D；应用器 `188f75a67294138f`、生成物 `56a5b4a5be1c6bcc`）：新臂 `build/MilBridge/tests/MinMaxProbe/**`（public `TextFormatter.Create().FormatMinMaxParagraphWidth`）。**构造用例翻转（测出来的）**：判别例 `mod0`（**零长** `TextModifier` 在 cp=0）**修前 `min=22.652344 max=0.000000 rel=gt`（Min>Max，真机契约禁止）⇒ 修后 `min=0.000000 max=0.000000 rel=eq`**；阴性对照 `control`（无 modifier）`min=22.652344 max=90.609375 rel=lt` **两相逐位不动**；二者唯一差别 = `CollectLenient` 有没有记下 modifier ⇒ **单变量归因成立**。既有臂 `PcLineOracle` 复跑 stdout 与 P2 交付**逐字节相同**（`07615909a1ffaa8b`）⇒ **射程外不动**。
#   【② 波后"读数迁移"的机器断言（循环成员 churn 不伤判据）】波内重建使 `pc` 换 sha 多次（见 ⑭），**两臂读数逐字节迁移到最终件**：`PcLineOracle` 在最终 `pc` 上 stdout `dfb250295761b4ce`，与三点对照的 P1+P2 **完全一致**；`MinMaxProbe` 在最终 `pc` 上仍 `mod0: rel=eq` / `control: rel=lt`。它与 W17B 交付那趟的差 **2 行、全是登记表路径**（`$HOME` 版 vs **已回仓**的 repo 版，条数同为 136）—— 逐行归因完毕。
#      ⚠️ **一条口径更正（本波产出）**：`pc` 的 sha **依赖构建路径**（同源同 `@(Compile)`，仓内 `obj` 与两个不同 `$HOME` obj 得到**三个不同 sha**；同目录内重复构建才逐字节相同）⇒ **"换目录重建得同 sha"不是有效的可复现性判据**，见 ⑩ 的 `D-R6`。
#   【③ 应用门禁（本波跑了**三趟**，读数全部逐位相同；本表头取第三趟）】`default drawn=260 colors=3960`、`env drawn=144 colors=2828`、两档 `frames_good=14 frames_total=14 frames_blank=0`、`shot_dims=938x938`、`cross_ae=0`、`max_concurrent_apps=1`、`leftover_after=0`、`scroll=ok`、`exit=143` —— **三趟彼此逐位相同，且与 `#16` 逐位相同** ⇒ 同时确认 **P2 的预测①（应用门禁不变）** 与 **P1/P3 的端到端中性**。
#     · 第 1 趟（`pc=14086882b1509dcd`，基线 `baseline17-run1.md` `591500e4fed84871`）装置来源 = **runner 自起的 Xvfb**（常驻 `:97` 当时已挂 ⇒ 我"打印了检查却没让它拦住运行"，**自己的失误已留档**）。
#     · 第 2 趟（`pc=ac16320a14f549d4`，基线 `7b73fe7a20616021`）与 **第 3 趟（本表头，`pc=df6dbb1c2bfb4162`，基线 `baseline17-run3.md` `1d16c6436b8fbe94`，stdout `gate17c.out` `6c834059abf861c5`）**装置来源 = **常驻 `:97`（runner 走"复用已存在的 X server"分支）**，纪律 30 的正路。
#   【④ 等号读者 + T17A 工具（**并列留档**，因为"两条都绿、其中一条其实不分内容"正是本项目最怕的假绿）】
#     · **等号读者**（判"产物里是哪个 shim"）：`SHIM_SHA=no reason=content-compare artifact=df6dbb1c2bfb4162 artifact_bytes=4195328 shim=bc04c05ab6d8d82a product_sha16=bc04c05ab6d8d82a tree_sha16=bc04c05ab6d8d82a asm=PresentationCore cmp=full64 …`，`rc=0`。
#     · **T17A 工具**（只证**下界**）：`SHIM_IN_ARTIFACT=PASS artifact=df6dbb1c2bfb4162 artifact_bytes=4195328 shim=bc04c05ab6d8d82a new=2/2 stable=14/14 missing=- recent=2/2 refs=23`、`rc=0`。
#     · ⚠️ **口径（`D-R4`，`#16` 收官夜立、本波沿用）**：T17A 的 `PASS` **不区分内容** —— 它自述的"无新符号 ⇒ 退化成 `WEAK-PASS rc=3`"**是错的**（W17C 用三份**内容不同**的产物各打一次，**三次都 `PASS rc=0`**；`WEAK-PASS` 今天**不可达**）⇒ **"产物里是哪个 shim"一律以等号读者为准**，T17A 工具降级为"只证下界"。
#   【⑤ 身份位（逐字，本趟 `WPTD_ARTIFACTS`）】`WPTD_BRIDGE_SRC_STALE=no`（`basis=pub=0b7c5a54267064fc now=0b7c5a54267064fc so_file_match=yes`）｜**`hbtextline_shim_stale=no`**（`basis=auth`：`src_mtime=1789467925` < `pc_compare_mtime=1789533728`）｜波内身份自检：桥源指纹两侧一致 ✅、生成物指纹 `state=ok（PC/WB/PF）` ✅、**应用器审计 `appliers=22 ok=80 miss=0 red=0 rc=0`**（本波**升过覆盖面**：把 `patch-presentationcore-lineheight-trace` 与新的 shimsha 应用器一起登记进两处清单，见 ⑩ 的 `D-R7`）✅、输入稳定性 ✅。
#   【⑥ `APPSYNC` 非 PASS —— 与 `#16` 同形，**两份仪器 sha 都要记**（纪律 35）】波内读数 = 旧检查器：`OK=45 MISMATCH=0（STALE=0 NEWER-DIFF=0） MISSING=0 UNEXPECTED=1 DIVERGENT=0 NO-AUTHORITY=20 LIB-COPY=0 SKIP(obj)=6 SKIP(stub)=4 SKIP(ref)=10 RETIRED=0` ⇒ `APPSYNC=MISMATCH`，唯一原因 = `build/DirectWrite.Linux/FallbackCriteria/bin/Debug/WpfGfx.Linux.dll`（内容 == 权威 `0c597fb6ec1eec70`）⇒ **`D-A1`**。**仪器 sha**：`applocal-expect.py` **`6eafbea14e7ea41e`** + `check-applocal-sync.sh` **`aad23482f84bdf44`**（`#16` 收官夜 TAPPS 加固后的版本，自检 17/17；波后主控复读为 `UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0]`、`rc=1`，日志 `$HOME/wfp-runs/w16-pre/appsync-new.out`）。
#   【⑦ 与 `#16` 的差（逐位）】**变**：**`pc c0763fc10173e7ff → df6dbb1c2bfb4162`**｜**`pf 9ef136caddb10370 → 388053cd4c9ba91f`**（环成员，每波必变，预期）。**未变**：`bridge caf7baf9e67719aa`（4,983,696 B）、`windowsbase e6216fe961a2bfb9`、`provider 9aa0d744802aaa31`、`win32shim 0098234982391bbf`（283,648 B）、`wic_shim 03b67fbcd7c385b6`、**`hbtextline bc04c05ab6d8d82a`（本波未动 shim）**、`dwf b6743030ff1eb907`、`BRIDGE_SRC_FP 0b7c5a54267064fc`。`inputs_fp` `fe1bbcae…9adf → db3110fc78bb0346564ef37e7753e0b8483d8bf95de6642b7a2d3bf1b297738c`（**预期**：应用器/`integration-wave.sh` 都在该指纹覆盖面里）。
#   【⑧ 扩展可见位（逐字，本趟 `WPTD_ARTIFACTS_EXT`）】`reachframework 9a4196436cef71c0`（`visible-not-frozen`）｜`systemxaml d6ea4ffe6a5d4737`（`visible-not-frozen`）｜`presentationui 22c35c7935499f18`｜`pfclassic 55f981c3261309ea`｜`systemprinting 92bfb23aee5f43cc`｜`uiatypes 2ac8d37b7cdc5afd`｜`uiaprovider 352ccd757a2f2fb0`｜`manipulations c264f0ec86fad755`｜`libskia a02cd03f1ebcbb97`（`libskia_nuget_2_88_9_match=yes`）。**口径不变**：扩展位变化**不自动作废基线**，但**必须在本表头记录**。
#   【⑨ 渲染侧（M7b）】**未随本波重建**：`src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll` = **`0c597fb6ec1eec70`**（注意 TFM 子目录）。
#   【⑩ 在册红门禁（五臂）+ 登记表】仪器 `build/MilBridge/tools/tline-gate.sh` **`b37a5c9f55ae71a4`**（本波未改）、`judge=t1b3-tline-gate/2`；登记表 `build/MilBridge/known-red.json` **`f9843bde351029dc`**（`schema 4`、`generation.id=#16`、**entries 4**、`changelog rev 7`）。**读数**：`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#16 tree_gen=same saved_shim=bc04c05ab6d8d82a`、`GATE_REASON=all-as-registered`、`rc=0`。**两极化重做**：删 `tline/T3b` ⇒ `registered=3 unregistered=1` + `GATE_REASON=unregistered-failure` + **`rc=1`**；真表 ⇒ **`rc=0`**。**为什么本波不需要重取臂/重钉表**：世代只绑 `run.sh`/`Parity`/shim 三项，而**本波 `shim` 未动** ⇒ 已实测 `tree_gen=same`。
#   【⑪ 本波产出的**新登记**（逐条；详见 `docs/CURRENT-STATE.md` §4 与 `WAVE17-PREREGISTRATION.md`）】
#     · **`D-R5`**：**手改生成物**的落地件会被下一趟波静默抹掉（本波第一趟波就发生了）；**纪律 38** 已立（含"红线判据 = 跑一次 `port-lib.py` 后它还在"）。
#     · **`D-R6`**：`pc` 的 sha **依赖构建路径** ⇒ "换目录重建得同 sha"**不成立**；有效表述 = "同一输出目录内重复构建逐字节相同"。
#     · **`D-R7`（已修）**：`patch-presentationcore-lineheight-trace` **不在任何接线清单里** ⇒ 长期在 applier 审计**覆盖面之外**（"生效了但没注册"）；登记后审计 **`appliers=20 ok=74` → `22 ok=80 miss=0 red=0`**（覆盖面变大 = 判据变强）。**副作用已记**：它的执行时机提前 ⇒ csproj 补丁块顺序变 ⇒ 该 csproj 的 sha 与"波留下的那份"必然不同（**内容多重集相同**，机器断言）。**主控裁决 = 保留登记**（审计覆盖面 > 生成物字节同一性）。
#     · **`D-T4`（产品缺口）**：PC 路径**不携带 `DefaultIncrementalTab`** ⇒ 停靠位非默认的段落在**应用路径上**也拿不到它（shim 恒取 `4×em`）。**仪器侧** = 任何走 PC 的臂**喂不进去**（`PcLineOracle` 的 `tab0` 族 **136 条**已按"如实标注射程"登记，**不是**消音；表已**回仓** `build/MilBridge/tests/PcLineOracle/known-red.txt` **`89324f1f643167e5`**，155 行；已核：**非注释行 0 条含 `default`、每条都以 `@tab0` 结尾**）。**产品侧** = 真实缺口，**本波只登记不修**（它**在 P2 射程之外**）；真机在该输入下的行为**没有真值** ⇒ 判据需先补 Windows 重录。
#     · **`D-T5`**：含 **`Length ≥ 1`** 的 `TextModifier`/`TextEndOfSegment` 的段落在 PC 路径上**整条交回 LS**（Linux 侧抛 `EntryPointNotFoundException: LoCreateContext`）⇒ `CollectLenient` 的 modifier 记账对**真实源**永不生效。根因双证：`TextModifier.CharacterBufferReference` 是 **sealed default** ⇒ `ExtractRun` 返 null ⇒ `CollectLenient`（生成物 `:149-152`）**必然 return false** ⇒ **只有 `Length ≤ 0` 的 modifier 能过**。**同时推翻了 TDT2 §2.5 那张构造例表**（它设计的 `Length=1` 例**到不了被测代码**）。
#     · **`D-T2-c`**：两个宽度探针共用一把**缺 `modifierScopeEnd`** 的已知错尺子（max 传 open+close、`scopeEnd` 默认 −1 = "`[open, 段末)`"，shim 自己在 `:3854-3858` 标注实测错）；**前置** = `CollectLenient` 记下覆盖终点，**前置未满足前不许改**（改 = 编值，纪律 22）。
#     · **两条被推翻的"判据/设计"（比落地件更值钱）**：① 上面的 TDT2 构造例表；② **E7**（"孪生恒等式修后仍违反 0"）—— 它**把缺陷态当成了规律**（与 `L25`、`ProviderShapeTests` 同族，第 N 个实例）。
#   【⑫ `verify-all`（**10 步**，与 `#16` 同口径）】两趟波内各跑一次，均 **`步骤通过 10 ❌ 失败 0`、`用例通过 871 跳过 2`、`结论：✅ 全部通过`**；冻树那趟日志 `$HOME/wfp-runs/close-wave-w17b/close-wave.log`（`inputs_fp=db3110fc…`）。
#   【⑬ 仪器版本（纪律 18；同名文件一律写全路径）】`build/MilBridge/run.sh` **`3e513e88a4fa4ec9`**（未改）｜`build/MilBridge/tests/HbTextLineParity/Program.cs` **`2e458928fc1577c2`**（未改）｜**`build/shims/PresentationCore.HbTextLine.cs` `bc04c05ab6d8d82a`（本波未动）**｜应用器：`patch-presentationcore-textline-fallback.py` **`188f75a67294138f`**（P2+P3）、**新增** `patch-presentationcore-hbtextline-shimsha.py` **`81f821ae225eb3a0`**（P1）⇒ 生成物 `TextFormatterImp.Linux.cs` **`56a5b4a5be1c6bcc`**、`HbTextLineShimSha.targets` **`3127e82b76ce8c24`**｜**新增臂**：`build/MilBridge/tests/PcLineOracle/Program.cs` **`544aab374ee8e1a6`**（+ 登记表 `known-red.txt` **`89324f1f643167e5`**）、`build/MilBridge/tests/MinMaxProbe/Program.cs` **`cfcf464457163280`**｜**新增等号读者** `build/MilBridge/tests/ShimShaReader/Program.cs` **`0ef57677afef9f6d`**｜`build/MilBridge/tools/shim-in-artifact.sh` **`e2e1a42b5f0e5b45`**（只证下界）｜`build/MilBridge/tests/CoverageProbe/Program.cs` **`a8727a5bed6bf049`**（三支 tab 臂的真仪器；不在世代绑定里）｜`build/artifact-src-fp.py` **`687ff7dabe87fda4`**｜门禁 runner `tests/…/run-wpftextdemo.sh` **`5dfb2635b87bb351`**｜`build/MilBridge/tools/tline-gate.sh` **`b37a5c9f55ae71a4`**｜`build/MilBridge/known-red.json` **`f9843bde351029dc`**｜五臂日志 `build/MilBridge/arm-logs/`（`tline 89ad10ac614b4d3b`、`tab-zero b9d81590f3fcd800`、`tab-anchor 99d72b385fe23a90`、`tab-rtl 419e8aaa9c72a9a0`、`textlineproto 4bceceeed570ba70`；`README.md 6924605fab87660e`）｜`build/integration-wave.sh` **`770419556b9597df`**｜`build/MilBridge/tools/applier-audit-expected.txt` **`eecf8f28d3e6b9f9`**｜`build/check-appliers.sh` **`025d7f5148af36b9`**｜`verify-all.sh` **`a68823631e8f8919`**（**10 步**）｜`build/DirectWrite.Linux/wic-shim/applocal-expect.py` **`6eafbea14e7ea41e`**、`check-applocal-sync.sh` **`aad23482f84bdf44`**｜`build/DirectWrite.Linux/FallbackCriteria/mem-sampler.sh` **`09e5bab7c3d246f6`**｜`build/close-wave.sh` **`68c7167c61b4e00e`**。
#   【⑭ `pc` 的**中间态留痕**（本波重建多次；**任何引用下列 sha 的读数都属于中间态**）】`c0763fc10173e7ff`（`#16` 冻结值）→ `18c49eec6992c7d9`（P1，4,195,328 B）→ `1280323c9173bcde`（P1+P2）→ `14086882b1509dcd`（P1+P2+P3，4,195,328 B）→ `ac16320a14f549d4`（**第一趟波把 P1 抹掉后**，4,194,816 B、**无元数据**）→ `7680da47c39ec7d9`… 更正：`7680da47c39ec7ed`（重落 P1，4,195,328 B）→ **`df6dbb1c2bfb4162`（第二趟波，本表头值）**。另有车道私建的两个**路径相关** sha（`e879cb67c7fa029e` / `7a33d6c401f3c661`）—— 见 ⑩ 的 `D-R6`，**它们不是"不一致"，是"sha 依赖路径"**。
#   【⑮ 收尾清单里**还没做**的（不许当绿）】① **`#17` 未接任何新判据进 `verify-all.sh`**（等号读者/T17A 工具都还没接；接前要先定 `rc` 语义与"每波点名新符号"的制度）；② **`D-T5`**（真 modifier → LS 回退）与 **`D-T4`**（`DefaultIncrementalTab`）**只登记未修**（都在 PC 接线点，需先补判据）；③ **`D-T2-c`** 的前置（`CollectLenient` 记 `modifierScopeEnd`）未做；④ **严格档（`HbTextFallback.TryFormatLine`）的 indent 缺口**仍是 shim 侧缺口（`P2` 只修了宽松档）；⑤ **`P4`（`HasOverflowed` 的过时注释）本波**裁决不做**（理由：本波 shim 未动 ⇒ 世代不变；为一行注释去换一次五臂重取+重钉不划算），**随下一件动 shim 的活一起做**；⑥ **`D-E1`**（真机 `Inflate`）、**`D-F2`**（需专门专项，前置 = 把从不打印的 `SegmentFaceUnresolved` 印出来）、**`D-A1`/`D-A2`/`D-A3`**（app-local 期望模型那一族）、**`D-R2`** 已关闭但**产品侧两个无保护的解析器安装点（`D-R3`）**仍登记为波次项；⑦ **`D-F1c`①c**（1CJK 该 ttc 3 段）、**`D-F3`**、`7CJK candidates=45`、MIL 侧三个计数（需会加载 MIL 的宿主）**均未取到读数**。
#
# ================= 以下是本趟（#17）门禁的机读行（逐字取自 baseline 输出；run_dir=/home/links-dev/wfp-runs/w17-gate3） =================
# BASELINE-HEADER date=2026-09-16T12:44:52+08:00 display=:97 host=linksdev-VirtualBox kernel=6.8.0-138-generic
#   loadavg=2.03 3.60 2.80  cpu=3核
#   mem_available=3197 MB  mem_total=7923 MB
#   run_dir=/home/links-dev/wfp-runs/w17-gate3  repeat=3  timeout=90s  tier=both
#   git_head=(no git) samples_src=samples/WpfTextDemo  runner=run-wpftextdemo.sh
BASELINE tier=default rep=1 config=pc:df6dbb1c2bfb4162,bridge:caf7baf9e67719aa,pf:388053cd4c9ba91f,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w17-gate3
BASELINE tier=default rep=2 config=pc:df6dbb1c2bfb4162,bridge:caf7baf9e67719aa,pf:388053cd4c9ba91f,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w17-gate3
BASELINE tier=default rep=3 config=pc:df6dbb1c2bfb4162,bridge:caf7baf9e67719aa,pf:388053cd4c9ba91f,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w17-gate3
BASELINE tier=env rep=1 config=pc:df6dbb1c2bfb4162,bridge:caf7baf9e67719aa,pf:388053cd4c9ba91f,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w17-gate3
BASELINE tier=env rep=2 config=pc:df6dbb1c2bfb4162,bridge:caf7baf9e67719aa,pf:388053cd4c9ba91f,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w17-gate3
BASELINE tier=env rep=3 config=pc:df6dbb1c2bfb4162,bridge:caf7baf9e67719aa,pf:388053cd4c9ba91f,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/w17-gate3
#   CENSUS(字形普查, 期望 id0≈0 / nonlatin>0 / maxid≈63151) T1C_CENSUS_SUMMARY frame=3 runs=167 handles=167 glyphs=1717 id0=0 nonlatin=421 maxid=63151 allnotdefruns=0 distinctpids=4 rc=0
#   CWIC(诊断趟 WPF_LINUX_CWIC_TRACE=1, 期望 materialize尺寸=96x96 fmt=…c90f Bgra32) NA [cwic-trace] source=0x5 ownedByWic=True materialize尺寸=96x96 foreignSources=0 shimGetSize=96x96（第二次=96x96 ok=True） format=6fddc324-4e03-4bfe-b185-3d77768dc90f → SKBitmap=96x96 colorType=Bgra8888 alphaType=Unpremul stride=384 bufferSize=36864 copyPixels=S_OK
[cwic-trace]   describe(source)= h=5 via=slot kind=FormatConverter foreign=0 ownedByWic=1 refs=1 size=96x96 rowBytes=384 fmt=6fddc324-4e03-4bfe-b185-3d77768dc90f pixels=yes decoded=1
#   WIC_NATIVE(诊断趟 WPF_LINUX_WIC_TRACE=1, 期望 prc=(0,0,96,96) 且 REFUSE=0) refuse=0
0 WIC_TRACE COPY_PIXELS h=5 96x96 foreign=0 prc=(0,0,1x1)
WIC_TRACE COPY_PIXELS_SUBRECT prc=(0,0,1x1) dst=4 cb=4
WIC_TRACE COPY_PIXELS h=5 96x96 foreign=0 prc=null
#   CENSUS_ORPHANS CENSUS_ORPHANS before=0 after=0；自起 Xvfb=无）
#   CENSUS_ALL（普查全量仪表行，前向兼容：新仪表自动入基线）
#     CENSUS_ORPHANS before=0 after=0
#     [GLYPH_CENSUS] frame=1 runs(绘制次数)=0 不同句柄=0 全notdef的run=0 glyphs=0 id0=0 maxId=0 非拉丁(id>=0x1000)=0 桶[0]=0 [1,FF]=0 [100,FFF]=0 [1000,3FFF]=0 [>=4000]=0 面标识: pid==0的run=0 不同面数=0 渲染器=(未知) hook成功=0 hook失败=0 无渲染器=0 资源查不到=0  [无信息：所有 run 的面标识相同 —— 若全为 0 则可能是字段没被填]
#     [GLYPH_CENSUS] 原点Y汇总: runs=0 distinct_origin_y=0  Y值(DIP)=[]
#     [GLYPH_CENSUS] frame=2 runs(绘制次数)=0 不同句柄=0 全notdef的run=0 glyphs=0 id0=0 maxId=0 非拉丁(id>=0x1000)=0 桶[0]=0 [1,FF]=0 [100,FFF]=0 [1000,3FFF]=0 [>=4000]=0 面标识: pid==0的run=0 不同面数=0 渲染器=(未知) hook成功=0 hook失败=0 无渲染器=0 资源查不到=0  [无信息：所有 run 的面标识相同 —— 若全为 0 则可能是字段没被填]
#     [GLYPH_CENSUS] 原点Y汇总: runs=0 distinct_origin_y=0  Y值(DIP)=[]
#     [GLYPH_CENSUS] frame=3 runs(绘制次数)=167 不同句柄=167 全notdef的run=0 glyphs=1717 id0=0 maxId=63151 非拉丁(id>=0x1000)=421 桶[0]=0 [1,FF]=1280 [100,FFF]=16 [1000,3FFF]=122 [>=4000]=299 面标识: pid==0的run=0 不同面数=4 渲染器=WpfGfx.Linux.Text.TextRenderer hook成功=167 hook失败=0 无渲染器=0 资源查不到=0  [有信息：确有多个不同面]
#     [GLYPH_CENSUS] 原点Y汇总: runs=167 distinct_origin_y=12  Y值(DIP)=[前8个:10.210,10.210,11.139,12.067,12.995,24.133,25.107,29.292…]
#     [GLYPH_CENSUS] 相关性: originDIP.y=10.210 的 run 数=13 其设备Y去重数=13  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=10.210 的 run 数=27 其设备Y去重数=7  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=11.139 的 run 数=17 其设备Y去重数=2 设备Y=[80.631,525.487]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=12.067 的 run 数=35 其设备Y去重数=8  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=12.995 的 run 数=48 其设备Y去重数=25  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=24.133 的 run 数=1 其设备Y去重数=1 设备Y=[62.639]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=25.107 的 run 数=5 其设备Y去重数=1 设备Y=[540.038]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=29.292 的 run 数=4 其设备Y去重数=2 设备Y=[162.146,323.515]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=45.589 的 run 数=7 其设备Y去重数=2 设备Y=[179.122,340.491]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=61.886 的 run 数=2 其设备Y去重数=1 设备Y=[196.098]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=78.183 的 run 数=5 其设备Y去重数=1 设备Y=[213.074]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=94.479 的 run 数=3 其设备Y去重数=1 设备Y=[230.050]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] run#0 handle=0x00000018 n=11 id0=0 max=91 pid=0x20000003 originDIP=(0.000,24.133) devX=37.500 devY=62.639 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,37.500] first16=58,83,73,55,72,91,87,39,72,80,82
#     [GLYPH_CENSUS] run#1 handle=0x0000001c n=2 id0=0 max=36710 pid=0x20000005 originDIP=(0.000,11.139) devX=37.500 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=18749,36710
#     [GLYPH_CENSUS] run#2 handle=0x0000001d n=3 id0=0 max=18 pid=0x20000004 originDIP=(24.000,11.139) devX=62.500 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,18,3
#     [GLYPH_CENSUS] run#3 handle=0x0000001e n=3 id0=0 max=27897 pid=0x20000005 originDIP=(35.672,11.139) devX=74.658 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=27897,27147,11929
#     [GLYPH_CENSUS] run#4 handle=0x0000001f n=3 id0=0 max=18 pid=0x20000004 originDIP=(71.672,11.139) devX=112.158 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,18,3
#   ORIGIN_Y(判据⑦ 行推进；阈值 10；根治前=6 / 根治后=12) 原点Y汇总: runs=167 distinct_origin_y=12  Y值(DIP)=[前8个:10.210,10.210,11.139,12.067,12.995,24.133,25.107,29.292…] verdict=PASS 取值频次:      2 originDIP=(0.000,12.995)       2 originDIP=(0.000,12.067)       1 originDIP=(83.344,11.139)       1 originDIP=(81.523,12.067) 
#   读图（保留格；普查/计数绿 ≠ 像素对 —— T1d 已登记这条预测假绿）：需人工/视觉复核 run_dir 下的 *-after.png
#   REAPED_ORPHANS total=0 detail=none（辅助趟漏下的孤儿；按精确 argv+ppid==1+PID 回收）
#   BRIDGE_SRC_STALE(桥→源 身份；期望 no；yes=部署件不是当前源编的⇒本趟读数作废) no basis=pub=0b7c5a54267064fc now=0b7c5a54267064fc so_file_match=yes
#
# ================= ↓↓↓ 历史：#16 表头与 #16 机读行（**已被上面的 #17 表头取代，不再生效**；#16 的完整波记录见 handoff.md）↓↓↓ =================
# BASELINE-HEADER date=2026-09-15T18:53:52+08:00 display=:97 host=linksdev-VirtualBox kernel=6.8.0-138-generic
#   loadavg=1.35 1.82 1.75（门禁启动时刻；负载闸门 1min ≤ 12 通过）  cpu=3核
#   mem_available=3826 MB  mem_total=7923 MB
#   run_dir=/home/links-dev/wfp-runs/mygate16b  repeat=3  timeout=90s  tier=both
#   git_head=(no git) samples_src=samples/WpfTextDemo  runner=run-wpftextdemo.sh（5dfb2635b87bb351）
# RE-FROZEN #16 —— 内容 = **`D-T2`（Tab 的缩进 / 停靠位 / 折行钳位语义，9 件）+ `D-O1`（`TextLine.HasOverflowed` 由**恒假**改成**真实现**）**；`build/shims/PresentationCore.HbTextLine.cs` 从 `b5118424dc977aef`（`#15`）走到 **`bc04c05ab6d8d82a`**（275,765 B、mtime `18:25:25`），该源被编进 `PresentationCore.Linux`。
#   波 = `WAVE_OWNER=主控 bash build/close-wave.sh`，**2026-09-15 18:37:16 → 18:41:17**（`OUT=$HOME/wfp-runs/close-wave-w16`，`W16_WAVE_EXIT=0`）：**native 重建=0（步骤 2 跳过：原生源不比权威件新）／桥重发=0（步骤 3 跳过：源指纹两侧一致 `0b7c5a54267064fc`）／`verify_all=PASS`**；汇总 `close-wave-summary.txt`（`$HOME/wfp-runs/close-wave-w16/`）。
#   **发波原因（写清，免得后人以为"没事跑什么波"）**：`#16` 落地期间门禁一度报 **`hbtextline_shim_stale=yes`** —— 当时 `pc` = `303604882d71f954`，**早于**最终的 shim 件（`bc04c05ab6d8d82a`）⇒ 那一趟的 `PASS` 是"**用旧文本栈盖章的相容**"，**不能**当最终基线。本波的作用就是**重建 `pc`**（`303604882d71f954 → c0763fc10173e7ff`）把最终 shim 编进产物。
#   ⚠️ **门禁跑了**两趟**，两趟都留档；本表头取自**第二趟****。
#     · **第一趟**（`18:42–18:44`，`run_dir=$HOME/wfp-runs/mygate16`，屏日志 `$HOME/wfp-runs/gate16.out` sha16 **`559d85a9bf1ac32d`**）：**6/6 `RESULT=PASS`**、读数与第二趟**逐项相同**；但**我忘了设 `WPTD_BASELINE_OUT`** ⇒ 这一趟**没有机读 `BASELINE` 行** ⇒ 它只能当**旁证**，不能当表头来源。**这是我的操作失误，如实记**（runner 的行为是对的：不指定就不写机读行）。
#     · **第二趟**（`18:53:52` 起）**6/6 `result=PASS`**，本表头与下面的机读行**全部取自它**：基线文件 `$HOME/wfp-runs/w16-pre/baseline16-run2.md`（sha16 **`cfd38fe2a3393fda`**）、屏日志 `$HOME/wfp-runs/w16-pre/gate16b.out`（sha16 **`2db6fb0e2457406b`**）。
#   【① 本波内容（逐条，全部落在 shim 源与本波重建的产物里）】
#     · **`D-T2` 的九件**（顺序即落地顺序，每件落完各自取一次读数）：`2` → `2b` → `2c` → `2d` → `2e` → `1a` → `1b′` → `1c` → `1d`（另有 `1b` **落地后回退**，见下）。
#       **本波确立的 Tab 语义（由 oracle 的逐字符真值定，不是猜的）**：tab 的 `adv` = `I_tab − Indent`（**与 `PI` 无关**）；tab 的 `x` = `Indent + PI` ⇒ **网格锚点 = `Indent`**（整形侧 `startPenX = indentDip`）、**内容起点 = `Indent + PI`**（`lineContentStartX` / `_startPenX`）；行 `Width` = `Indent + 内容宽`（**盒坐标、不含 `PI`**）；钳位目标 = `container − ParagraphIndent`（经 `room = clampWidth − lineStart`，等价于 `D-T1` 原本的 `stop > clampWidth`）；**行中 `\t` 对判据的贡献 = 仅当 `pen + I > clampWidth` 时为 `I`**；行尾 tab 之后的可折叠性需要 `a >= room`；**强制断行的回退分支必须用同一把尺子，并且在"该行的笔位"上重算 `\t` 的 advance**。
#       **`1b` 的如实记录（落地 → 实测变差 → 回退）**："无条件把行中 `\t` 计入贡献"（=`I`）⇒ 净回归 **8 → 10**（修好 0 / 弄坏 2）⇒ **回退**；改写成 `1b′`（条件 `pen + I > clampWidth`）⇒ 与上一轮**逐字节相同**（零位移）——**零位移本身就是结论**：它证明"强制断行的回退分支会把被排除的用例重新收回来"。`1c`（回退分支改用同一把尺子 + `a >= room`）⇒ 8 → 4；`1d`（回退分支在**该行笔位**重算 `\t` 的 advance）⇒ **4 → 0**。
#       **`tab-anchor` 臂的逐轮流水（结构败 / 判定过）**：`#15` 132/110 → 只改探针（补 `indentDip`/`paragraphIndentDip`）49/180 → `2` 55/233 → `2b` 45/243 → `2c` 37/251 → `2d` 35/253 → `2e` 14/274 → `1a` 8/280 → `1b` 10（**回退**）→ `1b′` 8（零位移）→ `1c` 4/284 → `1d` **0/288**。
#     · **`D-O1`（本波最后一件，件 `bc04c05ab6d8d82a`）**：`HasOverflowed` 原先**恒返回 `false`**，而它是**折叠资格闸门**的输入（`:3465` `if (!HasOverflowed && !_keepState) return this;`）⇒ 恒假把闸门**焊死**（只有 `_keepState` 路径会折叠）。改成真实现：`!(_paragraphWidth > 0) ⇒ false`；`_startPenX >= _paragraphWidth ⇒ true`；否则 `_boxOriginX + _width > _paragraphWidth + 1e-9`（**严格 `>`** ⇒ "恰好贴边" 判 `false`）。新增字段/参数 `_boxOriginX`（**授权同 `1a` 的 `gridAnchor` 先例：同一种模式**）；顺手更正 `_startPenX` 的注释（它的语义是 `Indent + ParagraphIndent`）。
#   【② 判据读数：**哪些成立、哪些不成立**（逐条，四元组口径 = 件 sha + 仪器版本 + 判据口径 + artifact 名/字段名）】
#     · **成立（正极性，最强的一条）**：**`tab-anchor` 臂由 132 结构败 → 0**、`判定过 288`、`rc=0`（日志 `build/MilBridge/arm-logs/tab-anchor.log` sha16 **`99d72b385fe23a90`**、mtime `18:49`）。`#15` 时该臂是"**有史以来第一次真实运行**"（`判定过 110 / 结构败 132 / 不可比(缺字形)148`）。
#     · **成立**：`tline` 臂**六项不变量逐条未动** —— `exact=73 diff=0`｜记账 `1298/1298`（①硬断 286/286 ②空行 68/68 ③行尾空白 988/988）｜宽度 `>0.34DIP = 0`｜折叠判定一致 `1297/1298`｜折叠明细 `232/236`｜`Extent` 余差 `95`（`gen/t2d-extent-mismatches.txt` `43155c1e108e4324`；其中 `*_tabs_*` 族 36 条同值、故题见 `#15` 表头 ②）。日志 `build/MilBridge/arm-logs/tline.log` sha16 **`89ad10ac614b4d3b`**、mtime `18:52`。
#     · **成立（三条臂在 `#16` 未动，且是**重取**实测）**：`tab-zero` **`b9d81590f3fcd800`**、`tab-rtl` **`419e8aaa9c72a9a0`**、`textlineproto` **`4bceceeed570ba70`** 与 `#15` **逐字节相同**（见 ③ 的机制证明）。
#     · **不成立（保留红，未动）**：`tline` 的 **`T3`（Collapse 与真机一致）仍 ❌**（明细 `232/236`）与 **`T3b`（折叠明细契约级断言）仍 ❌ 且 `unlocated:true`**（`① 判别式红 0/236；② 红 4/236；③ 红 2/236`）⇒ 两条**原样保留在登记表**（登记 ≠ 已容忍）。`tab-zero` 的 1 条老红（`notab-control@w40@em24@RTL@tab0`，`行#0 尾部空白 期望=0 实得=1`）**仍在**。
#     · **可归因的位移（`D-O1` 打开折叠闸门，**不是新缺陷**）**：`T3` 的"折叠**判定**一致"由 `1298/1298` 变 **`1297/1298`** —— 新增一处不一致 `A1_nbsp_zwsp_w40|行#0 Collapse hasCollapsed 期望 False 实得 True`；**方向与机制一致**的计数器实测：`collapseIneligible 2090→2088`、`collapseApplied 236→237`、`collapsedRangesReturned 236→237`、`collapsedRangesNull 1062→1061`。**按预登记 §4.6.6 的替换口径接受**（"位移允许，但每一条移动的用例都必须被归因；归因不到 ⇒ 停 + 回退"），已逐字写进登记表该条的 `carrier`。
#     · **本波未取到的读数（不许当绿）**：见 ⑪。
#   【③ 五臂在**波后树上重取** + 由此得到的**机制证明**（本波最值钱的一条新证据）】
#     · **为什么必须重取**：三支 tab 臂 + `textlineproto` 是**弱配对**（日志**不自报**被测件），纪律 29 只允许用「树 == 世代」∧「日志 mtime ≥ 世代被测件 mtime」配对。旧日志（`18:26–18:31`）**满足时间序**，但"`pc` 变了、它们的读数**为什么可以不变**"当时**只是推理**。
#     · **怎么取的（主控，`18:46:50–18:52:42`）**：先按 `build/MilBridge/arm-logs/README.md` 步骤 1 **重建会编进 shim 的探针**（`dotnet build -c Release`：`CoverageProbe` rc=0、0 错；`TextLineProto` rc=0、0 错）—— 这一步把探针本地那份 `PresentationCore.dll` 从 `303604882d71f954`（`17:13:03`）刷成权威 `c0763fc10173e7ff`；再逐条重跑五臂；最后用 **`ln -f`**（**绝不 `cp`**、**绝不 `ln -s`**）把新日志硬链接进 `build/MilBridge/arm-logs/`。旧日志**逐字保留**在 `$HOME/wfp-runs/w16/do1/*.log`（`ln -f` 只换名字，旧的 inode 仍挂在原名下）。
#     · **结果（这就是那个证明）**：`tab-zero`／`tab-anchor`／`tab-rtl`／`textlineproto` 四条**逐字节不变**——**在 `pc` 变了、且探针本地那份 `pc` 副本也被换掉的条件下**。
#       **机制（把"为什么可以不变"写成可复核的机制，而不是"大概是吧"）**：`build/MilBridge/tests/CoverageProbe/CoverageProbe.csproj` 里 `<Compile Include="$(HbShimSrc)" Link="PresentationCore.HbTextLine.cs" />` + `DefineConstants=…;TEXTLINE_SHIM_DIRECT`（`HbShimSrc` 默认就是 `build/shims/PresentationCore.HbTextLine.cs`），而 `HbTextLineFactory` **声明在 shim 源内部**（`shim:3777`）、探针的文本生产全部走 `HbTextLineFactory.FormatParagraph`（`Program.cs` 的 `:460/:640/:775/:880/:956/:1087/:1174/:1352`）⇒ **内联的那一份胜出**（C# `CS0436`「与导入类型冲突 ⇒ 用文件里定义的那个」，该 csproj 本就 `NoWarn` 掉 `CS0436`）。
#       **另一条独立佐证**：探针二进制 `bin/Release/PresentationCore.Tests.dll` 的 mtime = `18:25:50` **≥** shim 冻结时刻 `18:25:25` ⇒ 它确实是"按最终 shim 重建过的"（README 步骤 1 的原话："不重建就是在量旧 shim"）。
#       ⇒ **结论**：这三支臂与 `textlineproto` 量的是 **shim 源**，**不是 `pc` DLL**，所以"世代只绑三项仪器（含 shim 源）"对它们**是正确的那把尺子**，`pc` 变化**不进入**它们的读数。**这条以前是推理，现在是实测。**
#     · **`tline` 如实记录（它**确实**变了，但**不是读数**变）**：`ad07ead4022539d2 → 89ad10ac614b4d3b`，`diff` **14 行**，**逐行都是身份/管道**：`[applocal]`/`[T0.7]` 两行的 `pc` 权威 sha（`303604882d71f954 → C0763FC10173E7FF`，含 `一致 4/4`）、`已用时间`、`/tmp/tmp.*` 目录名、带时间戳的 artifact 路径（`gen/tline-ledger-lines-20260915-1830.txt → …-1852.txt`）与"上一趟 artifact"的回显 sha/mtime。**零条判据/读数行移动**；四条登记读数在新日志里**逐条复现**。
#       ⇒ **口径上的教训（已升为纪律 36）**：这里"旧日志 vs 新日志"**不是**"逐字节相同"能判的 —— 一条"必须逐字节相同"的绿色判据会**误报**；正确的口径是预登记 §4.6.6 已经写下的那条：**位移允许，但每一条移动的行都必须被归因**。
#   【④ `ARTIFACT-SRC-FP` 两极化 + 输入稳定性】
#     · 仪器 `build/check-fp-polarity.sh` **`f91d12bed2494889`**（本波未改）；正极性 = `build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt` 里 `file=<sha16>  build/shims/PresentationCore.HbTextLine.cs` 那一行 = **`bc04c05ab6d8d82a`** == 现树 shim；负极性 = 与波前存档比对 ⇒ **除 shim 那一行外逐位不变**。
#     · **诚实边界（承 `#15`）**：`file=` 只记**源的样子**，不证明产物里真的编进了它 ⇒ 本波**已把"产物侧"那半边落地**（见 ⑩ 的 `#17`）。
#     · **输入稳定性**：波前 == 波后 == **`fe1bbcae1e20ae7caadcdf5106172401c28cea6edfd4b66b55cc841b3de29adf`**（`#15` 是 `ac90d784…a74a`）。**补记（主控，18:53）**：三条车道（T17A/TAPPS/TDT2）收工后**我再算了一遍**，**逐位仍相同** ⇒ 他们的写入**不在这份指纹的覆盖面里**（覆盖面 = `src/WpfGfx.Linux/**`、`build/shims/**/*.cs`、`patch-*.py`、`port-lib.py`、`integration-wave.sh`、`close-wave.sh`）—— 这一点是**实测**，不是"应该不会"。
#   【⑤ 身份位（逐字）】`WPTD_BRIDGE_SRC_STALE=no`（`basis=pub=0b7c5a54267064fc now=0b7c5a54267064fc so_file_match=yes`）｜**`hbtextline_shim_stale=no`**（`basis=auth`：`src_mtime=1789467925` < `pc_compare_mtime=1789468694`）—— **这一位是本波存在的理由**（波前它是 `yes`）｜波内身份自检：桥源指纹两侧一致 ✅、生成物指纹 `state=ok（PC/WB/PF）` ✅、应用器审计 `miss=0` ✅、输入稳定性 ✅。
#   【⑥ `APPSYNC` 非 PASS —— 但**检查器在读数之后被改过**，所以这里必须记**两套读数 + 两套仪器 sha**（纪律 35 的现场）】
#     · **波内读数（仪器 = 旧检查器）**：`OK=45 MISMATCH=0（STALE=0 NEWER-DIFF=0） MISSING=0 UNEXPECTED=1 DIVERGENT=0 NO-AUTHORITY=20 LIB-COPY=0 SKIP(obj)=6 SKIP(stub)=4 SKIP(ref)=10 RETIRED=0` ⇒ `APPSYNC=MISMATCH`。**唯一原因** = `build/DirectWrite.Linux/FallbackCriteria/bin/Debug/WpfGfx.Linux.dll` 被判 `UNEXPECTED`，内容 == 权威 `0c597fb6ec1eec70` ⇒ 已登记 **`D-A1`**（**不是陈旧件**，但它也**不许当绿**）。
#     · **波后读数（主控自己复读，仪器 = 车道 TAPPS 加固后的新检查器）**：`APPSYNC=MISMATCH`、`OK=45 MISMATCH=0（STALE=0 NEWER-DIFF=0） MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0] DIVERGENT=0 NO-AUTHORITY=20 LIB-COPY=0 SKIP(obj)=6 SKIP(stub)=4 SKIP(ref)=10 RETIRED=0`、**rc=1**（日志 `$HOME/wfp-runs/w16-pre/appsync-new.out`）。**计数与类别名都没被洗白**（`UNEXPECTED` **未改名**、`UNEXPECTED=N` 槽仍在），`D-A1` 那一条现在被**点名**为"**声明图缺口、内容相等**"——**可见、仍红、非绿**。车道另做了两极化：往该路径塞一份内容不同的副本 ⇒ `UNEXPECTED-DIFF` + `DIVERGENT=1` + `rc=1`；还原 ⇒ `UNEXPECTED-EQ` + `rc=1`。
#     · **仪器 sha（两套都要记）**：波内 = `build/DirectWrite.Linux/wic-shim/applocal-expect.py` **`7c131b3f33b7e74e`** + `check-applocal-sync.sh` **`3ba5284bad838b14`**；波后 = **`6eafbea14e7ea41e`** + **`aad23482f84bdf44`**（自检 15/15 → **17/17 `SELFTEST=PASS` rc=0**）。
#     · **`verify-all` 不受影响（实测）**：`grep -n 'appsync\|APPSYNC\|applocal' verify-all.sh` ⇒ **无输出** ⇒ 换这个检查器**不可能**改变任何 `verify-all` 裁决。
#   【⑦ 与 `#15` 的差（逐位）】`pc 532c7f54f7573070 → c0763fc10173e7ff`｜`pf 06b12fb74fb50c96 → 9ef136caddb10370`（**环成员，每波必变，预期**）｜`hbtextline b5118424dc977aef → bc04c05ab6d8d82a`。**未变**：`bridge caf7baf9e67719aa`（4,983,696 B）、`windowsbase e6216fe961a2bfb9`、`provider 9aa0d744802aaa31`、`win32shim 0098234982391bbf`（283,648 B）、`wic_shim 03b67fbcd7c385b6`、`dwf b6743030ff1eb907`、`BRIDGE_SRC_FP 0b7c5a54267064fc`。**中间态留痕**：`#16` 波第一步曾把 `pc` 建到 `303604882d71f954`（**不含最终 shim**，就是 `hbtextline_shim_stale=yes` 的那一份）⇒ **任何引用 `303604882d71f954` 的读数都属于中间态**。
#   【⑧ 扩展可见位（逐字，本趟 `WPTD_ARTIFACTS_EXT`）】`reachframework b49ec81054d95988`（`visible-not-frozen`）｜`systemxaml d6ea4ffe6a5d4737`（`visible-not-frozen`）｜`presentationui 0aca055185e02298`｜`pfclassic 55f981c3261309ea`｜`systemprinting a6e2146b981cd5dc`｜`uiatypes 2ac8d37b7cdc5afd`｜`uiaprovider 352ccd757a2f2fb0`｜`manipulations c264f0ec86fad755`｜`libskia a02cd03f1ebcbb97`（`libskia_nuget_2_88_9_match=yes`）。**口径不变：扩展位变化不自动作废基线，但必须在本表头记录**；`reachframework`/`systemxaml` 是**可见位、不进冻结元组**（每波都在动 ⇒ 噪声大于信息；若变了**且**门禁读数有差异则升级进元组）。
#   【⑨ 渲染侧（M7b）】**未随本波重建**：`src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll` = **`0c597fb6ec1eec70`**（**注意 TFM 子目录**）。
#   【⑩ 在册红门禁（五臂）+ 登记表**
#     · 仪器 `build/MilBridge/tools/tline-gate.sh` **`b37a5c9f55ae71a4`**（本波未改）、`judge=t1b3-tline-gate/2`；登记表 `build/MilBridge/known-red.json` **`f9843bde351029dc`**（`schema tline-known-red/4`、`generation.id=#16`、**entries 4** = 3 条 `tline` + 1 条 `tab-oracle-zero`、`changelog rev 7`）。
#     · **读数**：`bash build/MilBridge/tools/tline-gate.sh --logdir build/MilBridge/arm-logs` ⇒ **`rc=0`**、逐字 `TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#16 tree_gen=same saved_shim=bc04c05ab6d8d82a gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2`、`GATE_REASON=all-as-registered`（outdir `$HOME/wfp-runs/gate16-arms2`）。
#     · **重钉（`changelog rev 7`，主控，代落盘披露）**：改 `generation.instr_pc` `4e73167ba0aa7f5c → c0763fc10173e7ff`（**该项不参与世代绑定** —— 实测 `tline-gate.sh:234` 的 `GEN_KEYS = (instr_run_sh, instr_program_cs, instr_shim)`）、`evidence_log` 指向 `build/MilBridge/arm-logs/tline.log`（`89ad10ac614b4d3b`）、新增 `arms_retaken` 块记录这次的机制证明；另修一条**陈旧路径**（`tab-oracle-zero` 条目的 `artifact` 原写 `$HOME/wfp-runs/tab-zero-w15.log` ⇒ 改为 `build/MilBridge/arm-logs/tab-zero.log`，旧路径存进新的 `artifact_origin`）—— 这是纪律 4（**记录自己会陈旧**）的现场实例。**未新增/未删除任何判据、未放宽任何口径**；`entries` 的 `expected_shape`/`expected_reading` **一字未改**。rev 6 备份 `$HOME/wfp-runs/w16-arms/known-red.rev6.json`（`391c907c7d114e01`）。
#     · **两极化（重钉后重做，实测）**：删 1 条 `tab-oracle-zero` 条目 ⇒ `registered=3 unregistered=1` + `GATE_REASON=unregistered-failure` + **rc=1**；删 `tline/T3b` ⇒ `registered=3 unlocated=0 unregistered=1` + 同因 + **rc=1**；真表 ⇒ **rc=0**。表副本 `$HOME/wfp-runs/w16-arms/kn-red-minus{a,b}.json`。
#     · **这条门禁在本波第一次"因为仪器被改而必须重取"**（纪律 34 的现场）：三支 tab 臂的**真正仪器是 `CoverageProbe/Program.cs` `a8727a5bed6bf049`**，而它**不在**世代绑定里 ⇒ 改探针不会让 `caliber` 变红，读数却整批变 ⇒ 所以本波的规则是"**改探针 ⇒ 必须重取三支 tab 臂 + 在 `changelog` 记探针新 sha**"。
#   【⑪ 本波四条车道（含新开的三个）与它们的产物 —— 全部**可复算**】
#     · **`#17`（产物侧 shim sha 证据，此前死过两次，本波第三次派发并落地）**：车道 **T17A**（`c17ed3a2-bed0-4c37-8aa0-471d8d91adb7`）。产物 `build/MilBridge/tools/shim-in-artifact.sh` **`e2e1a42b5f0e5b45`**（16,612 B）+ 报告 `build/MilBridge/T17A-report.md` **`de044cb22c77c9c8`**。**读数**：`SHIM_IN_ARTIFACT=PASS artifact=c0763fc10173e7ff artifact_bytes=4194816 shim=bc04c05ab6d8d82a new=2/2 stable=14/14 missing=- recent=2/2 refs=23`、`rc=0`。它读的是**编译后的 DLL 的托管堆**（不是源）：`NEW` token = `_boxOriginX`/`boxOriginX`（`D-O1` 引入），各自在 `#Strings` 里**恰好出现一次**（文件偏移 `0x2b694c`/`0x2b694d`），且在 `~/t1d-backups/` 里 **23 份有效旧 shim 版本中全部缺失**。**机制经实测**：`#Strings` 里的名字是 **UTF-8**、`#US` 里的字符串字面量是 **UTF-16LE** —— 字面量 `[LIVEBLOBS]` 有 1 处 UTF-16LE 命中而 **0 处 ASCII 命中** ⇒ 拿 `strings | grep` 交叉核对会产出**假红**；纯注释短语（`行盒远缘`）与局部变量名（`penLine`）**处处 0 命中**，证明注释与局部变量**不进元数据**。**红证**：对三份旧 DLL（`9adac6b8d8e285c3`、`684424fea3a0812a`、`530d76bd4327873e`）⇒ `MISMATCH rc=1` 并**点名**缺哪两个 token，而稳定 token 14/14 仍在（⇒ 红的是 token，不是拿错了文件）；另测 `NOINFO rc=2`：路径不存在／目录／非 PE／截断 64 KiB／shim 缺失／仓库根定不出。连跑两次机读行逐字节相同；只读性已验证（跑前跑后 `pc`/shim/`ARTIFACT-SRC-FP` sha 未变）。
#       **⚠️ 它的诚实边界（必须一起读）**：这是一个 **下界**（"产物 ⊇ 版本 `bc04c05ab6d8d82a`"），**不是**"产物 == 这一份源代码"。本代 shim 只引入 **2 个新符号**，其余改动是注释更正（**可证不进元数据**）与**既有名字之下的逻辑修改** ⇒ **将来若某次 shim 改动不引入任何新符号，这条检查会退化成 `WEAK-PASS rc=3`（故意非 0）** ⇒ **本波起，凡改 shim 的波必须点名"本波新引入的符号"**（已写进收尾清单）。把下界变成等号有三条路，**本波一条都没走**：(A1) T1c `draft-shimsha` 里的 `AssemblyMetadata("HbTextLineShimSha", …)` 路线 —— 注意 `PresentationCore` 是 `GenerateAssemblyInfo=false` ⇒ **今天一条这种 attribute 都没有**，且它**会改 `pc` 的 sha** ⇒ 必须单独一波；(A2) PDB 的 document checksum —— **未测、不做任何声称**；(A3) 私有输出目录做确定性重建后比 sha —— **未跑**。另有两件元数据**原理上答不了**：**编进去的是哪个 `.cs` 文件**、以及 PE/强名称完整性。**本脚本未接进 `verify-all.sh`**（接线是主控的决定，**本波没接**）。
#     · **`D-A1` 加固 + "检查器还瞎着的那半"**：车道 **TAPPS**（`0b387845-54b7-41c5-baf1-21e577a0c02f`）。改 `applocal-expect.py` `7c131b3f33b7e74e → 6eafbea14e7ea41e`、`check-applocal-sync.sh` `3ba5284bad838b14 → aad23482f84bdf44`，报告 `build/DirectWrite.Linux/TAPPS-blind-half-report.md` **`9071d4bcf39918b8`**。**新查出的、比 `D-A1` 更大的洞**：检查器的 `ITEMS` **只覆盖 5 个件**（Provider/WpfGfx/ReachFramework/libwpfwin32/libwpfwic）⇒ `build/DirectWrite.Linux/FallbackCriteria/bin/Debug/` 里 **17 个 DLL 只有 2 个被判定**，`grep -c PresentationCore.dll` 对检查器自己的输出 = **0**；而**那个目录里真的躺着一份 `#15` 时代的 `PresentationCore.dll`（`532c7f54f7573070`、mtime `12:54:42`），当时权威已经是 `c0763fc10173e7ff`** ⇒ 一份**陈旧产物就贴在探针旁边，没人判**（这正是纪律 23 的"你量的是旧东西"家族）。**主控已处置并披露**：把那一份刷成权威（刷前 `532c7f54f7573070`/4,194,304 B，刷后 `c0763fc10173e7ff`/4,194,816 B，`cmp` 与权威逐字节相同）—— **但刷一份不等于补洞**：这一类"存在未被判定的副本"仍在登记项里。另两条实测：`.so` 副本（**含已发布的桥**，`EXPECT=UNKNOWN`、**根本没有权威可比**）**不可能变红** —— 往宿主目录里放一份**与权威等值**的 `libwpfwic.so` ⇒ `OK`、`UNEXPECTED=0`、**`rc=0`**；以及拷贝点枚举器自身漏报（只印 20 个里的 18 个；只扫 `build/**/*.sh` ⇒ 漏 2 个 MSBuild `<Copy>` 与 `run-wpftextdemo.sh:179/:191` 两处桥保存/恢复；只匹配字面文件名 ⇒ 漏 13 处变量间接写入，含 `run.sh:210` 的 `refresh_applocal` 与 `close-wave.sh:130`）。20 个点里 17 个只读点无害，**3 个写点全是真的洞**（今天"看着安静"只因副本恰好 sha 相同；删掉或改旧**都不会红**，其中两处还用 `2>/dev/null || true` **吞掉失败**）。
#     · **`D-T2` 边界的复核（登记被部分推翻）**：车道 **TDT2**（`ca6611a3-50cc-41db-bf55-9ce0e21fdf31`），报告 `build/MilBridge/TDT2-boundary-report.md` **`6388461b4ecd0de7`**（53,018 B）。① **原登记的"`ParagraphIndent ≠ 0` 时 max 含 indent 而 min 不含"被**推翻****：对生成物 `TextFormatterImp.Linux.cs`（`f86198dfdd349332`）`grep -n indentDip` **只有一处命中、在 `:256`**，**min/max 两个探针都不传 indent**；那个"接了 indent"的版本只存在于**一份从未编译过的草稿**里（`T1c-report.md:2764-2765`「撤：C `:305` ⇒ CS0103 根因」，与本文件 `CURRENT-STATE.md:233` 的 `(305,100) CS0103` 对得上），两份 `$HOME` 快照（`5dedc21f5f372c78` 波前、`569fefc718340086` `#13` 前）也都证实如此。② **真正残留的不对称**在 **`TextModifier` 作用域实参**：max 探针传 `modifierOpenIndex/CloseIndex`、min 探针**一个都不传** ⇒ 判为**缺陷、不是"照抄真机"**（上游 min/max 与 `FormatLine` 用同一份 `PrepareFormatSettings`；且 max 探针那条跨度 `scopeEnd = −1`「到段末」正是 shim 自己标注为错的形态 `shim:1731-1732`/`:3855-3858`）。**量级是"预测"不是"实测"**（如实记）。③ **"没有臂消费 `minWidth`"被确认、且比登记的更强**：13 个臂宿主 **0 命中**；大小写不敏感全扫只有"生产者"与 `maxWidth` 的**输入**读取；**30 份 oracle JSON 全都没有 min/max 输出字段**；且**每个臂都直接调 `FormatParagraph`** ⇒ **没有任何臂驱动 PC 的 `TextFormatter`**，`FormattedText.MinWidth` **零覆盖**。
#     · **`D-T2` 边界之外、本波新查出的**冻结相关**项（主控自己复核过生成物，见 §4 新行）**：PC 侧 `:575` 把 `settings.Pap.ParagraphIndent` 传给宽松回退 `TryFormatLine` 的 `paragraphIndent`，而 `:256` 把它送进 shim 的 **`indentDip`** 槽；`paragraphIndentDip` 恒 0、**`Pap.Indent` 从不被传**。按本波确立的 Tab 语义（`indentDip` = 网格锚点），应用路径的**停靠网格锚点会变成 `PI` 而不是 `Indent`**（内容起点是对的）。**五臂全都看不见它**（`layout-b34` 语料 `Indent = paragraphIndent = 0`，614/614；臂自己把 `indentDip`/`paragraphIndentDip` 接对了）。**量级未测、应用路径未实测**（`Pap.ParagraphIndent` 在该路径上是否非 0 **没有测**）⇒ 登记为新的开放项，**本波不许修**（一改就动 `pc`，会把正在冻的这份基线作废）。
#   【⑫ `verify-all`（**本波 = 10 步**，口径已在 `#15` 波后变过：第 10 步 = 在册红门禁）】
#     · 冻结后在**静树**上重跑：`bash verify-all.sh` ⇒ **`步骤通过 10  ❌ 失败 0`**、`用例通过 871  跳过 2`、`rc=0`、第 10 步 `tline-gate（五臂）✅`（日志 `$HOME/wfp-runs/w16-pre/verify-all-16.out` **`ce174c8cde3e9692`**）。
#     · **跑前/跑后环境已记（`D-R2` 的关闭判据要求"每趟记 `loadavg`/`mem_available`"）**：`1.43 1.61 1.68` / `3185 MB` → `1.36 1.67 1.70` / `3530 MB`。
#     · **`D-R2`（`ManagedLayer.Tests` 的负载敏感性）计数：静树带环境记录的绿趟 = 1/5**（`#15` 那 5 趟连续绿是**波内**跑的、**没记 `loadavg`** ⇒ 按现有判据**不计入**）。**本条仍开**，不许读成已关。
#     · 🔴 **同一小时内的更正（主控 19:02–19:13）—— 上面那行写的时候我只跑了一趟；补齐 5 趟后**结论变了**，如实记**：连跑 5 趟静树 `verify-all`（**每趟都记 `loadavg`/`mem_available`**）⇒ **3 绿 / 2 红**。
#       逐趟：`#1` 18:58–19:00:37 **`rc=0`**、10 步 0 失败、871 通过（`ce174c8cde3e9692`）｜`#2` 19:02–19:04 **`rc=0`**、10 步 0 失败、871 通过（`191c041650331085`）｜`#3` 19:04–19:05:58 **`rc=1`**、9 步 1 失败、**795** 通过（`1555da7c8c41f72c`）｜`#4` 19:05:58–19:08:06 **`rc=1`**、同上（`0211affddd3aa2c1`）｜`#5` 19:08:06–19:10:16 **`rc=0`**、10 步 0 失败、871 通过（`048f143b2439abc4`）。两趟红**都是同一项**：`ManagedLayer.Tests ❌ (rc=1)`。
#       **读数辨析（判 `D-R2` 的关键）**：两趟红里 `ManagedLayer.Tests` **一条用例都没产出** —— 该趟合计 `795 = 787`（前 4 个测试工程：562+162+44+19）`+ 8`（`Presentation.Tests`），而绿趟是 `871 = 787 + 76 + 8` ⇒ **是 TESTHOST 整批崩掉（0 个案例），不是"某几条用例失败"**。**环境**：这 5 趟 `loadavg` 全在 **1.26–2.41**、`mem_available` **3026–3296 MB**，且**没有任何别的车道在跑**（三条车道已收工，只有文档在写）。
#       ⇒ **原"负载敏感"这一定性被本批读数**否掉****：`#15` 那次红发生在"4 条车道并发"时，当时只能记成"**强先验、不是已证**"；**现在**在**更低的负载**下（1.26–2.41，对当时 4.26+）**仍然 2/5 红** ⇒ **触发因素不是机器负载**。
#       **判别性对照**：同一工程**在 `:99` 上单独跑 3 趟**（`19:10:40`/`19:11:51`/`19:13:04`；`loadavg` **0.59–0.64**、`mem_available` 3067–3080 MB、**序列里没有别的测试工程**）⇒ **3/3 `rc=0`、`已通过! 失败 0，通过 76，总计 76`**（日志 `$HOME/wfp-runs/w16-pre/managedlayer-iso-{1,2,3}.log`）。⇒ **「单独跑往往绿 / 在 `verify-all` 里会红」**。**但「序列/上下文」这条假设并没有被证实**（后续实验把它削弱了，如实记）**：
#       **后续判别实验（19:14–19:21，4 趟）**：按 `[2]` 段顺序先跑前置测试工程、再跑 `ManagedLayer.Tests`。**第 1 批 2 趟全红**（`测试主机进程崩溃`；`失败 11/通过 52/合计 63`、`失败 12/通过 59/合计 71`）—— **但这 2 趟里我自己的命令把 HelloMil 的 csproj 路径写错了**（`MSB1009: 项目文件不存在`、`rc=1`）⇒ **那不是干净的「序列」数据点**（仪器错误与被测件失败同时在场）。**路径改对后重跑 2 趟**（`HelloMil rc=0 通过 19`）⇒ **`ManagedLayer rc=0`、`已通过! 失败 0，通过 76，总计 76`（2/2 全绿）**。
#       ⇒ **诚实的结论**：这是一条**间歇**缺陷。观测到红的帧 = `verify-all` 里 2/5 ＋ 我那批含仪器错误的序列 2/2；观测到绿的帧 = `verify-all` 里 3/5 ＋ 单独跑 3/3 ＋ 修正序列 2/2。**唯一被真正否掉的是「负载」**（红的帧 `loadavg` 1.0–1.2，比绿的帧还低）；**触发器未定**，候选 = 时序 / 共享状态（testhost 复用、`obj` 与构建服务器、X 连接或窗口状态），**都还没有判别性读数**。
#       **故此**：关闭判据**保持原样**（要**连续** 5 趟静树全绿）⇒ **当前 3/5 且不连续、未达成、计数归零重来**；**新待办** = 把触发器钉死（候选：时序 / 共享状态；**负载已排除**），并明确**下一批实验必须先把命令自身的正确性核过**（我的 `MSB1009` 就是反例）。**不许**把这条红读成「环境问题所以不算」—— 纪律 30 的**反面同样成立**：**红就是红，直到有读数说明它是装置问题**。
#     · 🔴🔴 **2026-09-15 23:2x–23:5x 定案（同一天里对 `D-R2` 的**第二次**更正，也是最终一次）**：#       **触发器不是负载、也不是序列，是测试程序集里的 `SetDllImportResolver` 单槽位竞态。** 一次崩溃日志（`console;verbosity=normal` 拿到全栈）就定案了：#       `The type initializer for 'WpfGfx.Linux.Tests.ManagedLayer.Win32Shim' threw an exception. ---- System.InvalidOperationException : A resolver is already set for the assembly.`，栈直指 **`tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs:163`**。#       **机制**：该 API **对同一程序集只能调一次**，而那个程序集有**两个**安装点（`X11Guard.cs:163` 无保护、`DP1ReproTests.cs:63` 静默 `catch`）⇒ **谁先跑由 xUnit 的集合并行调度决定**；`DP1ReproTests` 先赢 ⇒ `Win32Shim..cctor` 抛 ⇒ **静态构造 ⇒ 整进程毒化** ⇒ 30 条用例全灭 / testhost 崩。**判别实验**：A（构建前置）/B（纯单独）交替各 3 趟 ⇒ **3/6 红**，两边**一样**⇒"构建前置"假设也被否掉。#       **已修（三处，全在 `tests/**` ⇒ 不动九位、不动 `inputs_fp`/`ARTIFACT-SRC-FP`** —— 实测 `ARTIFACT-SRC-FP.txt` 里 `tests/` 行数 = 0）：删掉冗余安装点、两个 `X11Guard` 容忍"被抢先"、**装完用真的 `[DllImport]` 自证一次**。#       **验证**：修后**单跑 6 趟全绿**（`race=0`×6、`hostcrash=0`×6；修前同形态 3/6 红）＋ **关闭判据：连续 5 趟静树 `verify-all` 全部 `rc=0`、10 步 0 失败、`race=0`**（逐趟环境 `0.67/3949MB→0.73/3771MB`、`0.73→0.84`、`0.84→0.71`、`0.71→0.81`、`0.81→0.77`，日志 `$HOME/wfp-runs/w16-pre/dr2close/v{1..5}.out`）。#       **⚠️ 我自己在这条修法上踩了一次并留档**：自证最初写成 `NativeLibrary.TryLoad("user32.dll", assembly, …)`，**那个 API 不走 `DllImportResolver`**（它只用程序集定搜索路径）⇒ 恒 false ⇒ **毒化类型、33 条用例全灭**（冒烟当场抓到；改成真 `[DllImport]` 后 76/76）。#       **同族尾巴（新开只读审计车道 R17C 抓出）**：删掉重复安装点后本程序集只剩一个安装点，而 `SystemParametersInfoTests.cs:40-41` 的 6 个 `[DllImport("user32.dll")]` 调用点**自己不碰 `Win32Shim`** ⇒ 顺序一反就 `DllNotFoundException`（**与 `D-R2` 同形态、成因不同**）⇒ **已补修**（该类的静态构造加 `_ = Win32Shim.LoadedPath;`）。#       **边界**：这是**装置缺陷**（测试程序集），**不是产品缺陷**；产品侧同类实例**目前不存在**（R17C 全仓枚举 9 个安装点/14 个程序集实例化、2 处同程序集碰撞，唯一活着那处**产品侧总是赢**），但产品侧有**两个无保护安装点**已登记为波次项（`build/shims/Win32ShimResolver.cs:174` 的 `[ModuleInitializer]`×4 程序集、`src/WpfGfx.Linux/Windowing/X11Native.cs:34` 的静态构造）。
#       **顺带留档（同一批里我自己的失误）**：第一次做隔离对照时命令里没把 `~/.dotnet` 放进 `PATH` ⇒ 三趟全是 **`rc=127`（command not found）**。**`127` 既不是"通过"也不是"失败"，是"根本没跑"** —— 改正后重跑的 3/3 绿才是读数。同族教训：**任何非 0 退出码在当成结论之前，先分清它是哪一类**。
#   【⑬ 仪器版本（纪律 18；同名文件一律写全路径）】`build/MilBridge/run.sh` **`3e513e88a4fa4ec9`**（未改）｜`build/MilBridge/tests/HbTextLineParity/Program.cs` **`2e458928fc1577c2`**（未改）｜`build/MilBridge/tests/CoverageProbe/Program.cs` **`a8727a5bed6bf049`**（**三支 tab 臂的真正仪器；不在世代绑定里**）｜`build/shims/PresentationCore.HbTextLine.cs` **`bc04c05ab6d8d82a`**｜`src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` **`07dc7627f609e031`** ⇒ 生成物 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` **`f86198dfdd349332`**｜`build/artifact-src-fp.py` **`687ff7dabe87fda4`**｜门禁 runner `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh` **`5dfb2635b87bb351`**｜在册红门禁 `build/MilBridge/tools/tline-gate.sh` **`b37a5c9f55ae71a4`**｜登记表 `build/MilBridge/known-red.json` **`f9843bde351029dc`**｜五臂日志目录 `build/MilBridge/arm-logs/`（**硬链接**；其 `README.md` **`6924605fab87660e`** —— ⚠️ `docs/CURRENT-STATE.md` §7 早先写的 `72f7f0c8b678e98f` **是错的**，已更正，纪律 4 实例）｜`build/bridge-src-fp.sh` **`03ec025bfb370071`**｜`build/close-wave.sh` **`68c7167c61b4e00e`**｜`build/integration-wave.sh` **`3aaf962fa115b6f6`**｜`verify-all.sh` **`a68823631e8f8919`**（**10 步**）｜`build/check-appliers.sh` **`025d7f5148af36b9`**｜`build/check-fp-polarity.sh` **`f91d12bed2494889`**｜`build/DirectWrite.Linux/FallbackCriteria/mem-sampler.sh` **`09e5bab7c3d246f6`**｜**新增** `build/MilBridge/tools/shim-in-artifact.sh` **`e2e1a42b5f0e5b45`**｜**改动** `build/DirectWrite.Linux/wic-shim/applocal-expect.py` **`6eafbea14e7ea41e`**、`build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` **`aad23482f84bdf44`**。
#   【⑭ 本波留下的**新登记项**（不许当绿；逐条）】① `D-A1` 的加固已落（`UNEXPECTED=N[DECL-GAP-EQ/DIFF]`，两极红证齐），但 **app-local 检查器的 `ITEMS` 只覆盖 5 个件** ⇒ 未被判定的托管副本（如 `FallbackCriteria/bin/Debug` 里 17 个只有 2 个被查）与**全部 `.so` 副本（含已发布的桥）**是洞（后者的红证 = 等值副本也报 `OK`+`rc=0`）；② 检查器的**拷贝点枚举器自身漏报**（18/20、只扫 `build/**/*.sh`、只匹配字面名），**3 个写点是真的洞**；③ **PC 侧 `ParagraphIndent` 进 `indentDip` 槽**（应用路径、五臂不可见、量级未测、**本波不许修**）；④ `D-T2` 边界的**真身是 `TextModifier` 作用域实参不对称**（判为缺陷、量级未测），原登记的"indent 不对称"**已推翻**；⑤ **`#17` 只是下界**（`new=2/2` 靠 `D-O1` 的两个新符号）⇒ **改 shim 的波必须点名新符号**，否则退化成 `WEAK-PASS rc=3`；⑥ `D-F1c`①c（1CJK 该 ttc **3 段**，目标 1–2）、`D-F3`（按目录全量预载 ⇒ 内存地板）、`D-F2`、`ContractProbe P6`、`D-E1`、`D-B1`、`D-K1`、`7CJK candidates=45`、MIL 侧 `CachedFileCount/CachedBytes/LiveFaceCount`（需一个会加载 MIL 的宿主）—— 均**未取到读数**，不许当绿；⑦ **`Tabs` 显式停靠位**仍是"公开 API 不存在 ⇒ 边界"。
#   【⑮ 收尾清单里**还没做**的（不许当绿）】① 把 `shim-in-artifact.sh` 接成 `verify-all` 的新步骤（**未接**）；② `D-R2` 的静树 5 趟（**当前 3/5 且非连续、两趟红 ⇒ 未达成**，见 ⑫ 的更正）；③ PC 侧 `indentDip` 接线与 `TextModifier` 作用域实参两处的判别实验（**新臂 + 真机重录**，见 §4 新行）；④ `D-F1c`①c 的 `/proc/<pid>/maps` 归因快照；⑤ app-local `ITEMS` 扩表；⑥ 本波 shim 的"新符号点名"是否要写进 `run.sh` 的自检（**未做**）。
#
# ================= 以下是本趟（#16）门禁的机读行（逐字取自 baseline 输出；run_dir=/home/links-dev/wfp-runs/mygate16b） =================
# BASELINE-HEADER date=2026-09-15T18:53:52+08:00 display=:97 host=linksdev-VirtualBox kernel=6.8.0-138-generic
#   loadavg=1.35 1.82 1.75  cpu=3核
#   mem_available=3826 MB  mem_total=7923 MB
#   run_dir=/home/links-dev/wfp-runs/mygate16b  repeat=3  timeout=90s  tier=both
#   git_head=(no git) samples_src=samples/WpfTextDemo  runner=run-wpftextdemo.sh
BASELINE tier=default rep=1 config=pc:c0763fc10173e7ff,bridge:caf7baf9e67719aa,pf:9ef136caddb10370,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/mygate16b
BASELINE tier=default rep=2 config=pc:c0763fc10173e7ff,bridge:caf7baf9e67719aa,pf:9ef136caddb10370,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/mygate16b
BASELINE tier=default rep=3 config=pc:c0763fc10173e7ff,bridge:caf7baf9e67719aa,pf:9ef136caddb10370,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/mygate16b
BASELINE tier=env rep=1 config=pc:c0763fc10173e7ff,bridge:caf7baf9e67719aa,pf:9ef136caddb10370,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/mygate16b
BASELINE tier=env rep=2 config=pc:c0763fc10173e7ff,bridge:caf7baf9e67719aa,pf:9ef136caddb10370,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/mygate16b
BASELINE tier=env rep=3 config=pc:c0763fc10173e7ff,bridge:caf7baf9e67719aa,pf:9ef136caddb10370,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:bc04c05ab6d8d82a(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/mygate16b
#   CENSUS(字形普查, 期望 id0≈0 / nonlatin>0 / maxid≈63151) T1C_CENSUS_SUMMARY frame=3 runs=167 handles=167 glyphs=1717 id0=0 nonlatin=421 maxid=63151 allnotdefruns=0 distinctpids=4 rc=0
#   CWIC(诊断趟 WPF_LINUX_CWIC_TRACE=1, 期望 materialize尺寸=96x96 fmt=…c90f Bgra32) NA [cwic-trace] source=0x5 ownedByWic=True materialize尺寸=96x96 foreignSources=0 shimGetSize=96x96（第二次=96x96 ok=True） format=6fddc324-4e03-4bfe-b185-3d77768dc90f → SKBitmap=96x96 colorType=Bgra8888 alphaType=Unpremul stride=384 bufferSize=36864 copyPixels=S_OK
[cwic-trace]   describe(source)= h=5 via=slot kind=FormatConverter foreign=0 ownedByWic=1 refs=1 size=96x96 rowBytes=384 fmt=6fddc324-4e03-4bfe-b185-3d77768dc90f pixels=yes decoded=1
#   WIC_NATIVE(诊断趟 WPF_LINUX_WIC_TRACE=1, 期望 prc=(0,0,96,96) 且 REFUSE=0) refuse=0
0 WIC_TRACE COPY_PIXELS h=5 96x96 foreign=0 prc=(0,0,1x1)
WIC_TRACE COPY_PIXELS_SUBRECT prc=(0,0,1x1) dst=4 cb=4
WIC_TRACE COPY_PIXELS h=5 96x96 foreign=0 prc=null
#   CENSUS_ORPHANS CENSUS_ORPHANS before=0 after=0；自起 Xvfb=无）
#   CENSUS_ALL（普查全量仪表行，前向兼容：新仪表自动入基线）
#     CENSUS_ORPHANS before=0 after=0
#     [GLYPH_CENSUS] frame=1 runs(绘制次数)=0 不同句柄=0 全notdef的run=0 glyphs=0 id0=0 maxId=0 非拉丁(id>=0x1000)=0 桶[0]=0 [1,FF]=0 [100,FFF]=0 [1000,3FFF]=0 [>=4000]=0 面标识: pid==0的run=0 不同面数=0 渲染器=(未知) hook成功=0 hook失败=0 无渲染器=0 资源查不到=0  [无信息：所有 run 的面标识相同 —— 若全为 0 则可能是字段没被填]
#     [GLYPH_CENSUS] 原点Y汇总: runs=0 distinct_origin_y=0  Y值(DIP)=[]
#     [GLYPH_CENSUS] frame=2 runs(绘制次数)=167 不同句柄=167 全notdef的run=0 glyphs=1717 id0=0 maxId=63151 非拉丁(id>=0x1000)=421 桶[0]=0 [1,FF]=1280 [100,FFF]=16 [1000,3FFF]=122 [>=4000]=299 面标识: pid==0的run=0 不同面数=4 渲染器=WpfGfx.Linux.Text.TextRenderer hook成功=167 hook失败=0 无渲染器=0 资源查不到=0  [有信息：确有多个不同面]
#     [GLYPH_CENSUS] 原点Y汇总: runs=167 distinct_origin_y=12  Y值(DIP)=[前8个:10.210,10.210,11.139,12.067,12.995,24.133,25.107,29.292…]
#     [GLYPH_CENSUS] 相关性: originDIP.y=10.210 的 run 数=13 其设备Y去重数=13  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=10.210 的 run 数=27 其设备Y去重数=7  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=11.139 的 run 数=17 其设备Y去重数=2 设备Y=[80.631,525.487]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=12.067 的 run 数=35 其设备Y去重数=8  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=12.995 的 run 数=48 其设备Y去重数=25  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=24.133 的 run 数=1 其设备Y去重数=1 设备Y=[62.639]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=25.107 的 run 数=5 其设备Y去重数=1 设备Y=[540.038]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=29.292 的 run 数=4 其设备Y去重数=2 设备Y=[162.146,323.515]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=45.589 的 run 数=7 其设备Y去重数=2 设备Y=[179.122,340.491]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=61.886 的 run 数=2 其设备Y去重数=1 设备Y=[196.098]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=78.183 的 run 数=5 其设备Y去重数=1 设备Y=[213.074]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=94.479 的 run 数=3 其设备Y去重数=1 设备Y=[230.050]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] run#0 handle=0x00000018 n=11 id0=0 max=91 pid=0x20000003 originDIP=(0.000,24.133) devX=37.500 devY=62.639 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,37.500] first16=58,83,73,55,72,91,87,39,72,80,82
#     [GLYPH_CENSUS] run#1 handle=0x0000001c n=2 id0=0 max=36710 pid=0x20000005 originDIP=(0.000,11.139) devX=37.500 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=18749,36710
#     [GLYPH_CENSUS] run#2 handle=0x0000001d n=3 id0=0 max=18 pid=0x20000004 originDIP=(24.000,11.139) devX=62.500 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,18,3
#     [GLYPH_CENSUS] run#3 handle=0x0000001e n=3 id0=0 max=27897 pid=0x20000005 originDIP=(35.672,11.139) devX=74.658 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=27897,27147,11929
#     [GLYPH_CENSUS] run#4 handle=0x0000001f n=3 id0=0 max=18 pid=0x20000004 originDIP=(71.672,11.139) devX=112.158 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,18,3
#     [GLYPH_CENSUS] run#5 handle=0x00000020 n=4 id0=0 max=47307 pid=0x20000005 originDIP=(83.344,11.139) devX=124.316 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=9492,21230,15698,47307
#     [GLYPH_CENSUS] run#6 handle=0x00000021 n=3 id0=0 max=121 pid=0x20000004 originDIP=(131.344,11.139) devX=174.316 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,121,3
#   ORIGIN_Y(判据⑦ 行推进；阈值 10；根治前=6 / 根治后=12) 原点Y汇总: runs=167 distinct_origin_y=12  Y值(DIP)=[前8个:10.210,10.210,11.139,12.067,12.995,24.133,25.107,29.292…] verdict=PASS 取值频次:      2 originDIP=(83.344,11.139)       2 originDIP=(71.672,11.139)       2 originDIP=(35.672,11.139)       2 originDIP=(24.000,11.139) 
#   读图（保留格；普查/计数绿 ≠ 像素对 —— T1d 已登记这条预测假绿）：需人工/视觉复核 run_dir 下的 *-after.png
#   REAPED_ORPHANS total=0 detail=none（辅助趟漏下的孤儿；按精确 argv+ppid==1+PID 回收）
#   BRIDGE_SRC_STALE(桥→源 身份；期望 no；yes=部署件不是当前源编的⇒本趟读数作废) no basis=pub=0b7c5a54267064fc now=0b7c5a54267064fc so_file_match=yes
#
# ================= ↓↓↓ 历史：#15 表头与 #15 机读行（**已被上面的 #16 表头取代，不再生效**；#15 的完整波记录见 handoff.md）↓↓↓ =================
# BASELINE-HEADER date=2026-09-15T13:01:00+08:00 display=:97 host=linksdev-VirtualBox kernel=6.8.0-138-generic
#   loadavg=4.26 4.57 3.87（门禁启动时刻；负载闸门 1min ≤ 12 通过）  cpu=3核
#   mem_available=3721 MB  mem_total=7923 MB
#   run_dir=/home/links-dev/wfp-runs/mygate15b  repeat=3  timeout=90s  tier=both
#   git_head=(no git) samples_src=samples/WpfTextDemo  runner=run-wpftextdemo.sh（5dfb2635b87bb351）
# RE-FROZEN #15 —— 内容 = **`D-F1c`（回退路径的内存 + 自旋）+ `D-F1b`（回退 run 的面身份）**（`build/shims/PresentationCore.HbTextLine.cs` 从 `17b2cdfe08f13280` 走到 **`b5118424dc977aef`**，该源被编进 `PresentationCore.Linux`）。
#   波 = `close-wave.sh` **12:53:19 → 12:59:25**（`OUT=/home/links-dev/wfp-runs/close-wave-w15`）：**native 重建=0 / 桥重发=0 / `verify_all=PASS`（9 步 0 失败）**；汇总 `close-wave-summary.txt`（sha16 `d4547285eb109263`）。
#   ⇒ 门禁 `WPTD_GATE=PASS`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 threshold=10 runs=167`、**6 条 `BASELINE … result=PASS`**。
#   ⚠️ **本波门禁跑了两次，第一趟不能作基线（已留档、原因已定案）**：第一趟（`$HOME/wfp-runs/mygate15/`）**default rep=1 判 `FAIL`（`exit=134`、`capture=all-blank`、`drawn=NA`）** —— 真因**不是应用缺陷**：该趟应用自报
#       `[WIN_DIAG] X 连接: dpy=无 x_failed=1 dpy_error="XOpenDisplay(":97") 失败：无 X server 或 DISPLAY 不可用。"` ⇒ `Unhandled exception System.ComponentModel.Win32Exception (1400)` 抛在 `HwndWrapper..ctor`（`build/WindowsBase.Linux/HwndWrapper.Linux.cs:125`）。
#       = **`runner` 自起 Xvfb 的"就绪竞态"**（`run-wpftextdemo.sh` 头部注释里已记过同型的 `1400` 症状与它的两次 `xdpyinfo` 缓解，实测**仍不够**）。**判为装置竞态的依据（同为硬读数）**：同一份件、同一份配置的 **rep=2/3 与 env 1/2/3 全 PASS**（`drawn=260/144`、`colors=3960/2828`、`frames=14/14`）。
#       **处置**：起一个**常驻** `Xvfb :97`（`1280x1024x24`）让 runner 走"**复用已存在的 X server**"分支 ⇒ 第二趟 **6/6 PASS**（本表头）。
#       **两趟都留档**：第一趟 `$HOME/wfp-runs/w15-pre/gate-r1-xrace/{baseline-run1.md（fa07c603fc9503e1）,app-default-r1.crash.log（a7772dd0b681dd03）,tier-readings-run1.txt（0e6a5418dd3357b0）}`；第二趟 `$HOME/wfp-runs/w15-pre/{baseline-run2.md（5f5a6b72be973f8b）,gate-run2.out（6b9c049939634038）}`。
#       **立为待修（runner 属 T3 写域）**：X 未就绪必须让 runner **在任何一趟之前**以 `NOINFO/rc=2` 拒绝启动（或常驻 Xvfb 并显式断言稳定），**不许**把"环境缺 X"记成应用 `FAIL` —— 否则机器一抖就产出一个假红（与 `L27`/`L28` 同族）。
#   【① 本波内容（逐条，全部落在 shim 源里）】
#     · **自旋真因（一行）**：`build/shims/PresentationCore.HbTextLine.cs:1021` 的 B2 覆盖位图循环**每轮把游标重置为 `0xFFFFFFFF`** —— `hb_set_next(set,&cp)` 的语义是"取 `*cp` 之后第一个元素（`*cp == HB_SET_VALUE_INVALID` ⇒ 取第一个）"⇒ 每轮都被要求"从头给第一个" ⇒ 永远返回同一个值、`HashSet.Add` 反复空加 ⇒ **纯用户态死循环**（无 IO、无输出、CPU 满、内存平）。正确写法：`uint c = 0xFFFFFFFFu; while (hb_set_next(hs, ref c) != 0) { … }`（**循环体内不重置**）。⇒ **这一行是 `#14` 上"跑不完"的直接原因**。
#     · **覆盖位图前置**（`CoversFace` 从"过滤之后"移到"过滤之前"）：原先每个过主键筛选的候选面都被 `HbFaceCache.Covers` ⇒ `Get` ⇒ **建 Entry 并写进 `s_faces`**（`MaxFaces=512`、本机 371 面 ⇒ **永不淘汰**）⇒ 峰值 ~3.3 GB。**已声明位移**：`coverageProbe 60 → 53`。
#     · **面 blob 按路径共享**（窗口 10）：`s_sharedBlobTable`（每 `path` 一份 blob，`AcquireSharedBlob`/`ReleaseSharedBlob`）＋ `hb_face_create(sharedBlob, faceIndex)`；`liveBlobs` 记账修正（只对我们建的 blob 计数，HarfBuzz 自建的表子 blob 单列 `ForeignBlobDestroys`）。**修前**：`NotoSansCJK-Regular.ttc` 在系统档按面重复 mmap；**单位判据（窗口 10）**：10 面 ⇒ 15 段→**1 段**、`liveBlobs=0`、`foreignBlobDestroys=20`（=10 面 × 2 表）。
#     · **`D-F1b` 的 E1 修法**：`FaceFromRef` 原先用 `new GlyphTypeface(new Uri(...))` ⇒ 对 `.ttc` 抛 `FileFormatException` ⇒ `FaceSlot=-1` ⇒ **静默回退到段落字体**；改为 `HbFaceCache.FamilyOf` → `new Typeface(…)` → `TryGetGlyphTypeface`（复用应用路径 `GetResolvedFace`，不另造第二条路）。
#   【② 判据读数：**哪些成立、哪些不成立**（逐条，四元组口径）】
#     · **成立（正极性）**：`run.sh tline` **能在有界资源下跑完** —— 件 `b5118424dc977aef`｜仪器 `run.sh 3e513e88a4fa4ec9` + `HbTextLineParity/Program.cs 2e458928fc1577c2`｜日志 `$HOME/wfp-runs/tline-bounded-20260915-124846.log`（sha16 `15fcee62971a3b4f`）｜**`elapsed=171 s`、`rss_peak=1219 MB < 2048 守卫`、自然终止（非 124/143）、artifact 为**本趟产物**（`gen/tline-detail-full.txt` `effc036f218f122d`/11041 B/12:52:04）、六项齐、`T1.73 exact=73 diff=0`**。`rc=1` **逐字记录、不作通过条件**（`rc = coreOk && collapseOk && machineOk ? 0 : 1`，而 `collapseOk` 含 `T3`/`T3b` 的保留红 ⇒ `rc=0` 在本仪器版**不可达**；口径见 `L29`）。
#     · **成立**：记账 `1298/1298`（①硬断 286/286 ②空行 68/68 ③行尾空白 988/988）｜**`T2` 判据由 ❌ 转 ✅**（宽度 `>0.34DIP` **34 → 0**；最大差 `0.333333 @ A1_long_word_w150`）｜折叠判定 `1298/1298`、明细全等 **225/236 → 232/236**｜不一致用例 **10 → 4**。
#     · **不成立（保留红，未动）**：`T3`（Collapse 与真机一致）与 `T3b`（折叠明细契约级断言，`unlocated:true`）—— 两者在 `#15` **仍 ❌**，登记表原样保留。
#     · **变差（新登记，未归因）**：紧口径 `Extent` 余差 **59 → 95（+36）**，36 条**全在 `*_tabs_*` 族**、**同值 `+0.0628`**、**布局（断点/宽度/真值宽/我们宽）逐位不变 36/36**；行级 `Extent 1260/1298 → 1223/1298`。归因另派（只读车道，产物 `$HOME/wfp-runs/t16-draft/PLUS36-ATTRIB.md`），**登记表已按"变差不是变好"写明**。
#     · **本波未取到的读数（不许当绿）**：`D-F1c`① 的三条（1CJK 档峰值 ≤300 MB／消 ×faces 乘法／该 `.ttc` 段数 13→1–2）—— 需 **T2 波后复取**（预登记 ⑧：**主判据 = 段数/Σ虚拟，RSS 只作旁证**）；`D-F3` 的地板读数与致因；**波后不变项复取**（`candidates` 10/45/371、`Scans=1`、面选择普查 26/26、`LINE_W=16.0000`、`CR_W=3.3440`、`GID=9498`、`ADV_DIP=16.0000`、`CRITERIA=PASS`、`TOOTH-D-F1b-ABSENT`）；`+CJK` 34 条的**独立复核**（T3 已核：与 `#13` **逐名相同 34/34**，`diff` 输出为空）。
#   【③ `ARTIFACT-SRC-FP` 两极化（本波"免费获得"的判据，已机械化）】
#     · 仪器 `build/check-fp-polarity.sh`（**`f91d12bed2494889`**，本波新写；**已做 19 用例红证**：正极性变红 ✅、负极性改值/增行/删行三种都能变红并点名 ✅、4 种 `NOINFO` ✅、双侧绿控 ✅；**已知沉默降级**：**不给波前存档时负极性整块被静默跳过且输出与"真做了且绿"逐字同形** ⇒ 调用方必须显式传存档，这条已登记）。
#     · **正极性 ✅**：`build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt` 里 `file=<sha16>  build/shims/PresentationCore.HbTextLine.cs` 那一行 = **`b5118424dc977aef`** == 现树 shim。
#     · **负极性 ✅**：与波前存档（`$HOME/wfp-runs/w15-pre/ARTIFACT-SRC-FP.pre.txt`，sha256 `9ac71d3eacfa2a14719b1b5501060559b0fe2e8ff2dad26e094a1784c5f5d89c`，4443 B，mtime 10:59:31）比对 ⇒ **除 shim 那一行外，其余 `file=` 行逐位不变**。（`fp=`/`peer_fp=`/`peer=` 允许变，按构造每波必变。）
#     · **诚实边界**：`file=` 只记**源的样子**，**不证明产物里真的编进了它**。本波**另做了一次内容级抽检**（主控）：新 `PresentationCore.dll`（`532c7f54f7573070`）里 `grep -a -c` 命中 **只在本波 shim 窗口 10 才有的标识符** `ForeignBlobDestroys=1 / s_sharedBlobTable=1 / AcquireSharedBlob=1 / SharedBlobAcquires=1 / s_transientBlobs=1` ⇒ **产物确实含当前 shim 源**。**这类"产物内 sha"的机制化 = `#17`**（本波只做了抽检，没落判据）。
#   【④ 身份位（逐字）】`WPTD_BRIDGE_SRC_STALE=no`（`basis=pub=0b7c5a54267064fc now=0b7c5a54267064fc so_file_match=yes`）｜`hbtextline_shim_stale=no`（`basis=auth`：`src_mtime=1789447534` < `pc_compare_mtime=1789448082`）｜波内身份自检：桥源指纹两侧一致 ✅、生成物指纹 `state=ok（PC/WB/PF）` ✅、应用器审计 `miss=0`（20 个应用器 / 74 个锚点）✅、**输入稳定性 波前==波后 = `ac90d7847938880e8b13f4ed91a94b3d10f0b49cc1d5584d4dacb08d0c13a74a`**（含 shim 与 `src/WpfGfx.Linux/**`）✅。
#   【⑤ `APPSYNC` 非 PASS —— **本波 §2.3 期望 `PASS` 未达成，如实记录**】
#     计数行（逐字）：`OK=45 MISMATCH=0（STALE=0 NEWER-DIFF=0） MISSING=0 UNEXPECTED=1 DIVERGENT=0 NO-AUTHORITY=20 LIB-COPY=0 SKIP(obj)=6 SKIP(stub)=4 SKIP(ref)=10 RETIRED=0` ⇒ `APPSYNC=MISMATCH`。
#     **唯一原因**：`build/DirectWrite.Linux/FallbackCriteria/bin/Debug/WpfGfx.Linux.dll` 被判 `UNEXPECTED`（"引用图**没有**要求这一份"），而它的**内容 == 权威 `0c597fb6ec1eec70`**（`build/DirectWrite.Linux/FallbackCriteria/FallbackCriteria.csproj` 只有三条 `HintPath`〔PC/WB/DWF〕，**没有** `WpfGfx.Linux` 引用 ⇒ 那份是**传递依赖副本**被拷进来的）⇒ **不是陈旧件**；波内 `REFRESH(group)` 还**刷新过**它（`b280168cef9689d0 → 0c597fb6ec1eec70`）。
#     ⇒ **新登记 `D-A1`：app-local 期望模型不覆盖"传递依赖副本"**（该副本 12:37 由车道构建产生 ⇒ 12:33 的 `APPSYNC=PASS` 那次它还不存在，故不是本波引入的红）。**不许把它洗成绿**：期望模型要么覆盖传递依赖，要么给它一个**显式且可判红**的类（内容不同即红）。
#   【⑥ 与 #14 的差（逐位）】`pc 9adac6b8d8e285c3 → 532c7f54f7573070`｜`pf ed51db81db76bc76 → 06b12fb74fb50c96`（**环成员，每波必变，预期**）｜`hbtextline 17b2cdfe08f13280 → b5118424dc977aef`｜`provider 71ba86c6495347fe → 9aa0d744802aaa31`｜`dwf 2f77dbdf5e7e2cd5 → b6743030ff1eb907`。
#     **本波未重发但相对 #14 已变**：`bridge 759a322431f1e457 → caf7baf9e67719aa`（**12:43:18 重发**，4,983,696 B；原因是 M7b 在 `src/WpfGfx.Linux/**` 落的 `SkiaFontFileCache` 改了桥源 ⇒ `BRIDGE_SRC_FP=0b7c5a54267064fc / N=78`；**#15 波内指纹一致 ⇒ 未再重发**）。
#     **未变**：`win32shim 0098234982391bbf`（native 未重建）、`windowsbase e6216fe961a2bfb9`、`wic_shim 03b67fbcd7c385b6`。
#   【⑦ 扩展可见位（逐字，本趟 `WPTD_ARTIFACTS_EXT`）】`reachframework 6ae0ef573669a5d3`｜`systemxaml d6ea4ffe6a5d4737`｜`presentationui a7f5756c6d34bc42`｜`pfclassic 55f981c3261309ea`｜`systemprinting bfbba2b8f8c03254`｜`uiatypes 2ac8d37b7cdc5afd`｜`uiaprovider 352ccd757a2f2fb0`｜`manipulations c264f0ec86fad755`｜`libskia a02cd03f1ebcbb97`（`libskia_nuget_2_88_9_match=yes`）。**口径：扩展位变化不自动作废基线，但必须在本表头记录。**
#   【⑧ 渲染侧（M7b）】**未随本波重建**：`src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll` = **`0c597fb6ec1eec70`**（mtime 12:38；主控实读 `dotnet build src/WpfGfx.Linux/WpfGfx.Linux.csproj` ⇒ `error CS = 0`，**增量无变化**）。**注意 TFM 子目录**（`bin/Debug/net10.0/`）。波的 `step 3.6` 把 **36 份 app-local 副本**刷新到权威（含 9 份 `WpfGfx.Linux.dll`、12 份 `DirectWrite.Linux.Provider.dll`、7 份 `ReachFramework.dll`）。
#   【⑨ 门禁本身在本波首次以"五臂"运行 ⇒ 立刻抓出一条长期没人跑的红（`L26` 的现场）】
#     · `bash build/MilBridge/tools/tline-gate.sh --log <5 份日志> --outdir …` ⇒ 逐字：
#       `TLINE_GATE=FAIL arms=5 red=3 green=2 noinfo_arm=0 registered=3 unlocated=1 drift=0 gone=0 unregistered=179 caliber=OK generation=#15 tree_gen=same saved_shim=b5118424dc977aef gate=338e468d1ad0f43c judge=t1b3-tline-gate/2`、`GATE_REASON=unregistered-failure`。
#       ⇒ **3 条在册红形状全对（`drift=0 gone=0`）**，但 **179 条未登记失败**：`tab-anchor`（436 例，**有史以来第一次真实运行**）`结构败=132`（探针层报 `未登记失败 178`）+ `tab-zero` 的 1 条老红（新表只覆盖 `tline` 臂 ⇒ 没把它带过来）。
#     · **`tab-anchor` 的机制形态（逐字）**：`A-anchor/lat-a-t-b@w96@LTR@i0@default` ⇒ `行数 期望=3 实得=2；真值行=[a]w=13.35 | [\t]w=96.00 | [b]w=13.35；我方行=[len=1,tws=0,nl=0]w=13.35 | [len=3,tws=1,nl=1]w=109.35`，而同例 **`@tab0` 变体 `结构=PASS`** ⇒ **"停靠位非 0 时的锚定/折行语义"与真值不一致**（真值把 `\t` 断成**独立一行并铺满停靠位**）。这与 `D-T2` 同面；它也解释了 shim 注释里那句"`layout-b34` 把她 `DefaultIncrementalTab` 写死成 0"。
#     · 同批其他臂：`tab-zero cases=86 判定过=85 结构败=1`（`notab-control@w40@em24@RTL@tab0` 行#0 尾部空白）｜`tab-rtl cases=84 判定过=8 结构败=0 不可比(缺字形)=76`（= 已登记项）｜`textlineproto`：`TextLineProto 段 == 通过 10 / 失败 0 ==`（`gen/textline-proto.png` 前后 sha 相同 `f442be49706592e5`），其 `ContractProbe` 段 `== 探针：通过 4 / 失败 2 ==`（`P1 new GlyphTypeface(new Uri(file://…))` = 已登记 `D-F2`；`P6 BeginInit + 属性 setter 构造 GlyphRun` ⇒ `InvalidOperationException` 抛在 `GlyphRun.CheckInitialized()` = **新发现，待登记**）。
#     · **处置**：把这 179 条按"**老红补登** / **真缺陷** / **装置缺陷** / **未定位（`unlocated:true`）**"逐条裁定并登进 `known-red.json`（另派车道；**登记 ≠ 已理解、更 ≠ 已容忍**）；`verify-all` 第 10 步由**主控**在门禁能给出 `PASS … unregistered=0` 之后再接。
#   【⑩ 仪器版本（纪律 18；同名文件一律写全路径）】`build/MilBridge/run.sh` **3e513e88a4fa4ec9**（本波未改）｜`build/MilBridge/tests/HbTextLineParity/Program.cs` **2e458928fc1577c2**｜`build/MilBridge/tests/CoverageProbe/Program.cs` **9bece92645db596a**（**探针二进制已于 13:02 用 `b5118424` 重建**，`bin/Release/PresentationCore.Tests.dll`）｜`build/artifact-src-fp.py` **687ff7dabe87fda4**｜门禁 runner `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh` **5dfb2635b87bb351**｜在册红门禁 `build/MilBridge/tools/tline-gate.sh` **338e468d1ad0f43c**｜登记表 `build/MilBridge/known-red.json` **129883bf803b0f5d**（`schema tline-known-red/4`、`generation.id=#15`）｜内存采样器 `build/DirectWrite.Linux/FallbackCriteria/mem-sampler.sh` **09e5bab7c3d246f6**｜`build/bridge-src-fp.sh` **03ec025bfb370071**｜`build/close-wave.sh` **68c7167c61b4e00e**｜`build/integration-wave.sh` **3aaf962fa115b6f6**｜`verify-all.sh` **ca071bf60f4c67b7**（9 步）｜`build/check-fp-polarity.sh` **f91d12bed2494889**。
#   【⑪ 收尾清单里"还没做"的（不许当绿；逐条）】① T2 波后复取（`D-F1c`① 三条 + `D-F3` 地板 + `CachedFileCount/CachedBytes/LiveFaceCount`）② 波后不变项复取（见 ②末）③ `+CJK` 34 条独立复核 ④ `Extent +36` 归因 ⑤ `tab-anchor` 179 条裁定与登记 ⇒ 之后接 `verify-all` 第 10 步 ⑥ `docs/CURRENT-STATE.md` §1/§4 + `handoff.md` 波记录 + `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`L25`–`L29`、`D-A1`、`P6`）⑦ `D-R2` 计数（本波 `verify-all` 是第 N 趟干净；关闭判据 = 连续 5 趟）。
#   🚩 **2026-09-15 13:0x 补记（主控；不改变上面任何一位）**：① **`D-R2` 关闭判据已达成** —— `close-wave.sh` 的**真实**波趟里 `verify-all` **连续 5 趟全绿**（`close-wave-203111` → `102523` → `105027` → `105739` → **本趟 `close-wave-w15`**；上一次红 = `close-wave-195021` 的 `ManagedLayer.Tests ❌ rc=1`；两个"无汇总"目录 `193821`/`193434` 是 `--dry-run`、**不打断连续计数**）。② **在册红门禁**：五臂读数 `TLINE_GATE=FAIL arms=5 red=3 green=2 noinfo_arm=0 registered=3 unlocated=1 **drift=0 gone=0** unregistered=179 caliber=OK generation=#15 tree_gen=same`（`GATE_REASON=unregistered-failure`）⇒ **179 条未登记失败的裁定与登记 = `verify-all` 第 10 步的前置**。③ **本波文档落点**：`docs/CURRENT-STATE.md`（**`ad3f5a813196cb6f`**：§1 九位=#15、§3 六条重核、§4 新增 `D-A1`/`tab-anchor`/`P6`/X 竞态四行、§5 新增纪律 28/29/30、`D-R2` 关闭）、`handoff.md`（**`07867c35f1d34875`**：波 `#15` 完整记录）、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（T3 写：`L25`–`L29`、`D-A1`）。
#   🚩 **2026-09-15 16:5x 补记之二（主控；不改变上面任何一位）**：
#     ④ **在册红门禁已接成 `verify-all` 第 10 步**（**步数 9 → 10、口径已变**）：仪器 `build/MilBridge/tools/tline-gate.sh` = **`b37a5c9f55ae71a4`**｜登记表 `build/MilBridge/known-red.json` = **`cebd534238c3b649`**（`schema 4`、`generation.id=#15`、**entries 182** = 原 3 条 `tline` + **新补 179 条非 tline 臂**）｜五臂日志目录 `build/MilBridge/arm-logs/`（**硬链接**：拷贝会顶掉 mtime 从而架空弱配对判据；符号链接会被 `find -type f` 漏掉 ⇒ 实测 `rc=2`；约定见该目录 `README.md`）。**读数**：`--logdir build/MilBridge/arm-logs` ⇒ `rc=0`、`TLINE_GATE=PASS arms=5 red=3 green=2 noinfo_arm=0 registered=182 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK`。**两极化实测**：删 1 条 `tab-anchor` 条目 ⇒ `rc=1`/`unregistered=1`；删 `tline/T3b` ⇒ 同形态；真表 ⇒ `rc=0`。**⚠️ 修掉门禁自身两个缺陷（同一族："一支臂两把尺子"；两处都只加强红检测）**：未登记检测取探针自报的 `UNREGISTERED`（含**位置面**，178 条）而在册红判读只取 `结构=`（132 条）⇒ `结构=PASS 位置=FAIL` 的 case 两边不一致 ⇒ **无论怎么登记都到不了 PASS**（实测 `unregistered=46` 或 `gone=46` 二选一）；修法 = 该 case **有 `FAILCASE` 行就判红**，且 `判据状态` 读数与 `judge_red` **同一把尺子**。**代落盘披露**：179 条登记由**主控**生成（原派车道两次中途失败且本项阻塞第 10 步），**逐条取自门禁自己的输出**，未新增/未删除判据、未放宽口径（`changelog rev5`）。
#     ⑤ **`D-R2` 又开了**：`#15` 波让 `verify-all` **连续 5 趟全绿**（`close-wave-203111→102523→105027→105739→w15`），但**波后手动 `verify-all`（16:47，含新第 10 步）** ⇒ `步骤通过 9 ❌ 失败 1`、失败项 `ManagedLayer.Tests`、原文 **`活动的测试运行已中止。原因: 测试主机进程崩溃`**（7 条失败全在窗口族）⇒ **崩溃形态与 `#14` 同族**。**混杂因素诚实披露**：该趟是在**4 条后台车道同时活动**时跑的，而 `verify-all` **不记 `loadavg`** ⇒ "负载"是强先验、**不是已证**；⇒ 关闭判据仍是"**静树下 ≥5 趟无崩溃，且每趟记 `loadavg`/`mem_available`**"。**新第 10 步本身在那趟里 ✅**（门禁在 `verify-all` 内可跑通）。
#   九位（**再次逐字取自本趟 `WPTD_ARTIFACTS`，供机器读**）：
#     WPTD_ARTIFACTS bridge_sha=caf7baf9e67719aa bridge_bytes=4983696 pc_sha=532c7f54f7573070 pf_sha=06b12fb74fb50c96 provider_sha=9aa0d744802aaa31 win32shim_sha=0098234982391bbf wic_shim_sha=03b67fbcd7c385b6 hbtextline_shim_sha=b5118424dc977aef hbtextline_shim_stale=no hbtextline_stale_basis=auth hbtextline_src_mtime=1789447534 pc_compare_mtime=1789448082 windowsbase_sha=e6216fe961a2bfb9 dwf_sha=b6743030ff1eb907
#
# ================= 以下是本趟（#15）门禁的机读行（逐字取自 baseline 输出；run_dir=/home/links-dev/wfp-runs/mygate15b） =================
# BASELINE-HEADER date=2026-09-15T13:04:54+08:00 display=:97 host=linksdev-VirtualBox kernel=6.8.0-138-generic
#   loadavg=4.26 4.57 3.87  cpu=3核
#   mem_available=3724 MB  mem_total=7923 MB
#   run_dir=/home/links-dev/wfp-runs/mygate15b  repeat=3  timeout=90s  tier=both
#   git_head=(no git) samples_src=samples/WpfTextDemo  runner=run-wpftextdemo.sh
BASELINE tier=default rep=1 config=pc:532c7f54f7573070,bridge:caf7baf9e67719aa,pf:06b12fb74fb50c96,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:b5118424dc977aef(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/mygate15b
BASELINE tier=default rep=2 config=pc:532c7f54f7573070,bridge:caf7baf9e67719aa,pf:06b12fb74fb50c96,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:b5118424dc977aef(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/mygate15b
BASELINE tier=default rep=3 config=pc:532c7f54f7573070,bridge:caf7baf9e67719aa,pf:06b12fb74fb50c96,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:b5118424dc977aef(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/mygate15b
BASELINE tier=env rep=1 config=pc:532c7f54f7573070,bridge:caf7baf9e67719aa,pf:06b12fb74fb50c96,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:b5118424dc977aef(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/mygate15b
BASELINE tier=env rep=2 config=pc:532c7f54f7573070,bridge:caf7baf9e67719aa,pf:06b12fb74fb50c96,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:b5118424dc977aef(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/mygate15b
BASELINE tier=env rep=3 config=pc:532c7f54f7573070,bridge:caf7baf9e67719aa,pf:06b12fb74fb50c96,provider:9aa0d744802aaa31,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:b5118424dc977aef(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/mygate15b
#   CENSUS(字形普查, 期望 id0≈0 / nonlatin>0 / maxid≈63151) T1C_CENSUS_SUMMARY frame=3 runs=167 handles=167 glyphs=1717 id0=0 nonlatin=421 maxid=63151 allnotdefruns=0 distinctpids=4 rc=0
#   CWIC(诊断趟 WPF_LINUX_CWIC_TRACE=1, 期望 materialize尺寸=96x96 fmt=…c90f Bgra32) NA [cwic-trace] source=0x5 ownedByWic=True materialize尺寸=96x96 foreignSources=0 shimGetSize=96x96（第二次=96x96 ok=True） format=6fddc324-4e03-4bfe-b185-3d77768dc90f → SKBitmap=96x96 colorType=Bgra8888 alphaType=Unpremul stride=384 bufferSize=36864 copyPixels=S_OK
[cwic-trace]   describe(source)= h=5 via=slot kind=FormatConverter foreign=0 ownedByWic=1 refs=1 size=96x96 rowBytes=384 fmt=6fddc324-4e03-4bfe-b185-3d77768dc90f pixels=yes decoded=1
#   WIC_NATIVE(诊断趟 WPF_LINUX_WIC_TRACE=1, 期望 prc=(0,0,96,96) 且 REFUSE=0) refuse=0
0 WIC_TRACE COPY_PIXELS h=5 96x96 foreign=0 prc=(0,0,1x1)
WIC_TRACE COPY_PIXELS_SUBRECT prc=(0,0,1x1) dst=4 cb=4
WIC_TRACE COPY_PIXELS h=5 96x96 foreign=0 prc=null
#   CENSUS_ORPHANS CENSUS_ORPHANS before=0 after=0；自起 Xvfb=无）
#   CENSUS_ALL（普查全量仪表行，前向兼容：新仪表自动入基线）
#     CENSUS_ORPHANS before=0 after=0
#     [GLYPH_CENSUS] frame=1 runs(绘制次数)=0 不同句柄=0 全notdef的run=0 glyphs=0 id0=0 maxId=0 非拉丁(id>=0x1000)=0 桶[0]=0 [1,FF]=0 [100,FFF]=0 [1000,3FFF]=0 [>=4000]=0 面标识: pid==0的run=0 不同面数=0 渲染器=(未知) hook成功=0 hook失败=0 无渲染器=0 资源查不到=0  [无信息：所有 run 的面标识相同 —— 若全为 0 则可能是字段没被填]
#     [GLYPH_CENSUS] 原点Y汇总: runs=0 distinct_origin_y=0  Y值(DIP)=[]
#     [GLYPH_CENSUS] frame=2 runs(绘制次数)=0 不同句柄=0 全notdef的run=0 glyphs=0 id0=0 maxId=0 非拉丁(id>=0x1000)=0 桶[0]=0 [1,FF]=0 [100,FFF]=0 [1000,3FFF]=0 [>=4000]=0 面标识: pid==0的run=0 不同面数=0 渲染器=(未知) hook成功=0 hook失败=0 无渲染器=0 资源查不到=0  [无信息：所有 run 的面标识相同 —— 若全为 0 则可能是字段没被填]
#     [GLYPH_CENSUS] 原点Y汇总: runs=0 distinct_origin_y=0  Y值(DIP)=[]
#     [GLYPH_CENSUS] frame=3 runs(绘制次数)=167 不同句柄=167 全notdef的run=0 glyphs=1717 id0=0 maxId=63151 非拉丁(id>=0x1000)=421 桶[0]=0 [1,FF]=1280 [100,FFF]=16 [1000,3FFF]=122 [>=4000]=299 面标识: pid==0的run=0 不同面数=4 渲染器=WpfGfx.Linux.Text.TextRenderer hook成功=167 hook失败=0 无渲染器=0 资源查不到=0  [有信息：确有多个不同面]
#     [GLYPH_CENSUS] 原点Y汇总: runs=167 distinct_origin_y=12  Y值(DIP)=[前8个:10.210,10.210,11.139,12.067,12.995,24.133,25.107,29.292…]
#     [GLYPH_CENSUS] 相关性: originDIP.y=10.210 的 run 数=13 其设备Y去重数=13  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=10.210 的 run 数=27 其设备Y去重数=7  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=11.139 的 run 数=17 其设备Y去重数=2 设备Y=[80.631,525.487]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=12.067 的 run 数=35 其设备Y去重数=8  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=12.995 的 run 数=48 其设备Y去重数=25  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=24.133 的 run 数=1 其设备Y去重数=1 设备Y=[62.639]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=25.107 的 run 数=5 其设备Y去重数=1 设备Y=[540.038]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=29.292 的 run 数=4 其设备Y去重数=2 设备Y=[162.146,323.515]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=45.589 的 run 数=7 其设备Y去重数=2 设备Y=[179.122,340.491]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=61.886 的 run 数=2 其设备Y去重数=1 设备Y=[196.098]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=78.183 的 run 数=5 其设备Y去重数=1 设备Y=[213.074]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=94.479 的 run 数=3 其设备Y去重数=1 设备Y=[230.050]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] run#0 handle=0x00000018 n=11 id0=0 max=91 pid=0x20000003 originDIP=(0.000,24.133) devX=37.500 devY=62.639 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,37.500] first16=58,83,73,55,72,91,87,39,72,80,82
#     [GLYPH_CENSUS] run#1 handle=0x0000001c n=2 id0=0 max=36710 pid=0x20000005 originDIP=(0.000,11.139) devX=37.500 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=18749,36710
#     [GLYPH_CENSUS] run#2 handle=0x0000001d n=3 id0=0 max=18 pid=0x20000004 originDIP=(24.000,11.139) devX=62.500 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,18,3
#     [GLYPH_CENSUS] run#3 handle=0x0000001e n=3 id0=0 max=27897 pid=0x20000005 originDIP=(35.672,11.139) devX=74.658 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=27897,27147,11929
#     [GLYPH_CENSUS] run#4 handle=0x0000001f n=3 id0=0 max=18 pid=0x20000004 originDIP=(71.672,11.139) devX=112.158 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,18,3
#   ORIGIN_Y(判据⑦ 行推进；阈值 10；根治前=6 / 根治后=12) 原点Y汇总: runs=167 distinct_origin_y=12  Y值(DIP)=[前8个:10.210,10.210,11.139,12.067,12.995,24.133,25.107,29.292…] verdict=PASS 取值频次:      2 originDIP=(0.000,12.995)       2 originDIP=(0.000,12.067)       1 originDIP=(83.344,11.139)       1 originDIP=(81.523,12.067) 
#   读图（保留格；普查/计数绿 ≠ 像素对 —— T1d 已登记这条预测假绿）：需人工/视觉复核 run_dir 下的 *-after.png
#   REAPED_ORPHANS total=0 detail=none（辅助趟漏下的孤儿；按精确 argv+ppid==1+PID 回收）
#   BRIDGE_SRC_STALE(桥→源 身份；期望 no；yes=部署件不是当前源编的⇒本趟读数作废) no basis=pub=0b7c5a54267064fc now=0b7c5a54267064fc so_file_match=yes
#
# ================= ↓↓↓ 历史：#14 表头与 #14 机读行（**已被上面的 #15 表头取代，不再生效**；#14 的完整波记录见 handoff.md）↓↓↓ =================
# BASELINE-HEADER date=2026-09-15T11:05:00+08:00 display=:97 host=linksdev-VirtualBox kernel=6.8.0-138-generic
#   loadavg=1.34 3.11 2.62（门禁启动时刻；负载闸门 1min ≤ 12 通过）  cpu=3核
#   mem_available=4881 MB  mem_total=7923 MB
#   run_dir=/home/links-dev/wfp-runs/go-freeze14  repeat=3  timeout=90s  tier=both
#   git_head=(no git) samples_src=samples/WpfTextDemo  runner=run-wpftextdemo.sh
# RE-FROZEN #14 —— 内容 = **`D-F1` 字体回退修复 + `GetIndexedGlyphRuns()` 真实现**。
#   波 = `close-wave-105739`（native 重建=0 / 桥重发=0 / **`verify_all=PASS`：9 步 0 失败**）⇒ 门禁 `WPTD_GATE=PASS`、6 条 `BASELINE … result=PASS`、`runner exit=0`。
#   ⚠️ 本波**跑了两次**：第一趟（`close-wave-105027`）**不能作基线**，两条理由已入档：① `D-F1` 把**非 DIRECT 编译**弄断（`TextLineProto`/`HbTextLineParity` 各 4 个 `error CS`）⇒ 仪器出不了读数；② 那趟的 **shim 在波中途被改过**而 `inputs_fp` **没发现**（见 ⑥，已修）。第二趟（本表头）两条都已消除。
#   🚩 2026-09-15 11:3x **补记（主控；不改变上面任何一位）**：基线冻结后实测发现 **`#14` 上 `run.sh tline` 跑不完** —— 在 `layout-b34` oracle 段**自旋 + 无界内存**（RSS `1.9 → 3.1 → 4.19 GB`、101% CPU、CPU 时间 16 分钟、**12+ 分钟零输出**、打开的字面 `/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc`；最后按 **PID** `kill -TERM` ⇒ `rc=143`。**`#13` 同段秒级完成**）⇒ 立为在册缺陷 **`D-F1c`**（疑似 `D-F1` 的 `plan == null` 也建计划 + `allowFallback:true` 引入；已派 T1d 最高优先级诊断）。
#     ⇒ **本基线的成立范围限定为**：**应用级门禁**（`WPTD_GATE=PASS`、6 条 `BASELINE … result=PASS`、`runner exit=0`）**+ `verify-all`（9 步 0 失败）**。
#     ⇒ **文本 harness 段在 `#14` 上"无读数"**（不是"失败读数"：它在结构上就没有产物）：`tline` 六项、34 条 `+CJK` `Extent` 对比**都取不到**，必须等 `D-F1c` 修好。
#     ⇒ 因此波的顺序重排为：**`#15` = `D-F1c` + `D-F1b`**（同属字体回退残留），**`D-T2`（Tab 缩进）+ `D-O1`（`HasOverflowed`，会打开折叠路径）顺延到 `#16`**，产物侧 shim sha 顺延到 `#17`。详见 `docs/WAVE15-PREREGISTRATION.md` 顶部重排说明。
#   【① 本波内容（逐条）】
#     · **字体回退被"走到"**：`FormatParagraph(..., HbFontPlan plan = null, ...)` 的 **`plan == null` 分支原先走单面度量**（绕过了 `allowFallback`）⇒ 现在**单面路径也先构造计划**（单 run `HbRunFaceInfo` + `HbFontPlanner.Build(..., allowFallback:true, 宽松闸)`），候选集/顺序**沿用我们自己的**（`PickFromRuns` → `HbFontCandidates.TryFindCovering`）；**找不到 ⇒ `NoteFailed` ⇒ 沿用当前面（不假装成功）**。
#     · **`GetIndexedGlyphRuns()` 真实现**（**推翻主控先前"上游 0 个调用点 ⇒ 不实现"的裁定**；**新依据 = 它正是真值的观测装置**：`GlyphTypeface.FontUri` / `GlyphIndices`（0=`.notdef`）/ `AdvanceWidths`）⇒ `IndexedGlyphRun{TextSourceCharacterIndex, TextSourceLength, GlyphRun}` 全部来自既有 `_glyphRuns`/`_glyphRunCharStart`；`StillOwedMembers` **6 → 5**（`OwedMembers` 仍 9）。
#     · **修法命中的真值**：`与`（`U+4E0E`）原落 `.notdef`（`600/1000 em = 9.6000 DIP @em16`）而真机 = **`16.0000 = 1.0 em`**（回退到 CJK 全宽字形）⇒ 同一行短 `6.4` ⇒ **`cr.Width = −3.0560`（真值 `3.3433`）**——这是唯一有真值的、用户可见的渲染差异。
#   【② 判据分工（**按实测改过**，T2 的发现）】**C2（`GlyphIndices ≠ 0`）+ C3（与真值差/符号）是"回退有没有发生"的主判据**；**C1（我们报的 advance == 我们所选面自己的 advance，逐位无容差）降为反作弊**（堵"把 `.notdef` 硬改成 1 em"那条捷径）——因为**实测 C1 抓不到这个 bug**（`9.6` 就是该面自己 glyph 0 的 advance ⇒ C1a/C1b 都自洽）。
#   【③ 两极化牙（实测）】正极（落地件）：`与` 行宽 **`16.0000`**、advance **`16.0000`**、`gids=[9498]`（**≠0**）；负极（`/tmp` 变体 `allowFallback:false`）：行宽 **`9.6000`**、`gids=[0]` ⇒ **回到旧读数** ✓。**零覆盖档**（`U+10FFFD`）**两边都落 `.notdef`** ⇒ **完全可比**（真值 `18.0/18.666667/14.4` ↔ 我们 `14.4@em24` 同口径）⇒ 已登记为"可比的一档"。
#     **两处禁止**（写进判据）：不许把 `.notdef` 的宽度硬改成 1 em 冒充回退；不许改 oracle/真值。
#   【④ 本波引入并修掉的阻塞（如实登记）】`D-F1` 初版用了**只在 DIRECT 分支可见**的成员（`GlyphTypeface.FaceIndex`、`IndexedGlyphRun` 3 参构造）⇒ **两条反射分支宿主编不过**：`build/MilBridge/tests/{TextLineProto,HbTextLineParity}` 各 **4 个 `error CS`**（`run.sh tline`/`textline` 因此出不了读数）。
#     **主控最小复现**：`dotnet build build/MilBridge/tests/TextLineProto -p:HbShimSrc="$PWD/build/shims/PresentationCore.HbTextLine.cs"` ⇒ `CS1061 "GlyphTypeface" 未包含 "FaceIndex"` + `CS1729 "IndexedGlyphRun" 不包含采用 3 个参数的构造函数`。
#     **修法**：`#if TEXTLINE_SHIM_DIRECT` 强类型 / `#else` 反射（**内联在调用点**，不做 helper；`IndexedGlyphRun` 走同类私有 `MakeIndexedGlyphRun`，**取不到就响亮抛、不用桩**）。
#     **四条判据实测**：① 两条反射宿主 `error CS` **4 → 0**（主控起波前独立复核）｜② DIRECT 不回归（`CoverageProbe` 0 错、`--fallback-check` `PASS`/`rc=0`）｜③ **非 DIRECT 运行期实调**：`MilBridge.TextLineProto.dll` 实跑 **`rc=0`**、A7 `抛出 0 个；总计 6/6`、`GetIndexedGlyphRuns→IndexedGlyphRun[]`（**真对象、非桩、不抛**）｜④ 两处陈旧注释 `6 → 5` 已改。
#     ⚠️ **仍缺的一格（如实登记）**：判据 ③ 只到"真对象 + 不抛"，**值级**（`FontUri`/`GlyphIndices`/`AdvanceWidths`）需**非 DIRECT 宿主自己打印** ⇒ 已派 T1b 在其宿主里加约 5 行值级打印 + "换成缺该码点字体 ⇒ `FontUri` 应指向另一个面"的对照；**在它落地前，这一格在"非 DIRECT 配置"下没有值级证据**（DIRECT 面由 T2 的 runner 覆盖）。
#   【⑤ 本波新增的能力（两条，都带牙）】
#     · **`ARTIFACT-SRC-FP` 逐文件行**（T1c，`build/artifact-src-fp.py` **纯插入 +16/−0**，工具 sha **`30abca613580cb77 → 687ff7dabe87fda4`**）：`file=<sha256 前16>  <仓库相对路径>`，覆盖 **PC 34 / WB 23 / PF 18** 行，**`build/shims/PresentationCore.HbTextLine.cs` 命中 1**；`file=` 与既有 `fp=/n=/peer_fp=/peer_n=/peer=/tool_sha256=` **互不为前缀** ⇒ 五处消费者（`close-wave.sh:149` 只取 rc、`integration-wave.sh:410` 只 `--write`、两个 runner **自己算 sha/mtime、不读 FP 文件**、`--check` 只读 `fp=/peer_*`）**语义未变**（落码前后关键行逐字相同、三行 `state=ok`）。
#       ⇒ **闭合两条今晚反复咬人的缺口**：`PC 内 shim sha = unknown` 有了内容级答案；**`hbtextline_shim_stale` 可以从 mtime 代理升级为内容比对**（`basis=content`，牙中 `rec=fde9e511… vs cur=72313e438cd2bb44` ⇒ 打 `yes`；还原 ⇒ `no`）。
#       **牙（两极化，实测）**：给 shim 加一行注释 ⇒ 该行 sha 变 + `--check` 报 **`state=stale note=kind=src`**（`fp=8a8f65c9664451e1` vs 记录 `d9b7cac83d3c2016`）、**rc=2**；`cp -p` 还原 + `touch -d @1789438795` ⇒ **sha 回 `fde9e511e8443cf2`、mtime 回 `1789438795`**、三行 `state=ok`、rc=0 ✓（**牙期间未跑 `--write`**，FP 记录保持原样）。
#       **诚实边界**：`file=` 只记**源的样子**，**不证明产物里真的编进了它**（"产物内 sha"另需 build 侧手段：生成哈希进产物 / PDB / 元数据）。
#     · **`close-wave.sh` 的 `fp_inputs()` 补入 shim 与 `src/WpfGfx.Linux/**`**（主控自查后修）：原实现只含 appliers/`port-lib.py`/两个波脚本 ⇒ **实测两趟波在 shim 从 `fde9e511…` 变成 `0085624234…` 的情况下 `inputs_fp` 逐位相同** ⇒ "**输入稳定性 波前==波后**"这句**对 shim 是空成立**（`#14` 第一趟的 shim 恰在波中途被改过而未被发现）。**修后 `inputs_fp=e9a44d944015c33e401bc0d27c2dac53a4c57f2a17ed8bcc18c06ecbb7aeeecb`**（≠ 旧值 `5e3df7dd…`，输入集变了 ⇒ fp 变）。**两极化实测（改 shim 一行 ⇒ fp 必须变）待做**（等 shim 静置）。
#   【⑥ 身份位（逐字）】WPTD_BRIDGE_SRC_STALE=no（`basis=pub=705ed5ccd0c498a1 now=705ed5ccd0c498a1 so_file_match=yes`）｜
#     `hbtextline_shim_stale=no`（`basis=auth`：`src_mtime=1789441003` < `pc_compare_mtime=1789441113`）｜波内身份自检：桥源指纹两侧一致 ✅、生成物指纹 `state=ok（PC/WB/PF）` ✅、应用器审计 `miss=0` ✅、**输入稳定性 波前==波后 = `e9a44d94…`** ✅（**现在真的含 shim**）。
#   【⑦ 与 #13 的差（逐位）】`pc d7a848dfeedcf29b → 9adac6b8d8e285c3`｜`pf e36447bed6b29e8f → ed51db81db76bc76`（**环成员，每波必变，预期**）｜`hbtextline fde9e511e8443cf2 → 17b2cdfe08f13280`。**未变 6 位**：`bridge 759a322431f1e457`（桥未重发）、`win32shim 0098234982391bbf`（native 未重建）、`windowsbase e6216fe961a2bfb9`、`provider 71ba86c6495347fe`、`wic_shim 03b67fbcd7c385b6`、`dwf 2f77dbdf5e7e2cd5`。
#   【⑧ 扩展可见位（逐字）】vs #13 变化 3 处：`reachframework 062c465f… → 094f6d0769e2ce90`、`presentationui 8b688faa… → 4fa1eb9ea95b5516`、`systemprinting cec723f6… → 90f3197422d4e66d`。
#   【⑨ `APPSYNC` 非 PASS = 既存 · 非本波引入】（`samples/HelloWpf/bin/Release/net10.0/DirectWrite.Linux.Provider.dll` 缺件；已裁定**走修不走改口径**）。该校验器**仍看不见"脚本拷贝的原生件"**（`invisible_copysites=20|invisible_write=3|invisible_read=17` 已显式印出）。
#   【⑩ 仪器版本（纪律 18；**两个同名 `Program.cs` 一律写全路径**）】
#     · `build/MilBridge/run.sh` **3e513e88a4fa4ec9**（本波未改）｜`build/MilBridge/tests/HbTextLineParity/Program.cs` **2e458928fc1577c2**｜`build/MilBridge/tests/CoverageProbe/Program.cs` **9bece92645db596a**｜`build/artifact-src-fp.py` **687ff7dabe87fda4**｜门禁 runner `tests/…/run-wpftextdemo.sh` **5dfb2635b87bb351**。
#   【⑪ `1400` 计数（两口径不混用）】门禁口径：`#13`=168 → 本趟 **+6 ⇒ 174**；每次启动口径：199 → 再 +（门禁 6 + 探针 N）。**两口径均 0 次发生**；各趟 `leftover_after=0`。
#   九位（**逐字取自本趟 `WPTD_ARTIFACTS`**）：
#     WPTD_ARTIFACTS bridge_sha=759a322431f1e457 bridge_bytes=4950352 pc_sha=9adac6b8d8e285c3 pf_sha=ed51db81db76bc76 provider_sha=71ba86c6495347fe win32shim_sha=0098234982391bbf wic_shim_sha=03b67fbcd7c385b6 hbtextline_shim_sha=17b2cdfe08f13280 hbtextline_shim_stale=no hbtextline_stale_basis=auth hbtextline_src_mtime=1789441003 pc_compare_mtime=1789441113 windowsbase_sha=e6216fe961a2bfb9 dwf_sha=2f77dbdf5e7e2cd5
#   扩展可见位（逐字）：
#     WPTD_ARTIFACTS_EXT reachframework_sha=094f6d0769e2ce90 reachframework_role=visible-not-frozen systemxaml_sha=d6ea4ffe6a5d4737 systemxaml_role=visible-not-frozen presentationui_sha=4fa1eb9ea95b5516 pfclassic_sha=55f981c3261309ea systemprinting_sha=90f3197422d4e66d uiatypes_sha=2ac8d37b7cdc5afd uiaprovider_sha=352ccd757a2f2fb0 manipulations_sha=c264f0ec86fad755 libskia_sha=a02cd03f1ebcbb97 libskia_nuget_2_88_9_match=yes(nuget-2.88.9-linux-x64) ｜ 口径=扩展位变化不自动作废基线，但必须在下一版表头记录；reachframework/systemxaml 是可见位、不进冻结元组
#   判定：WPTD_TIER_SUMMARY=default passed=3/3 failed=0 inconclusive=0 ｜ WPTD_TIER_SUMMARY=env passed=3/3 failed=0 inconclusive=0
#     ｜ WPTD_SUMMARY=PASS tiers_passed=2/2 ｜ WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 threshold=10 runs=167
#     ｜ WPTD_GATE=PASS acceptance=2/2 line_advance=PASS ｜ **runner exit=0** ｜ 6 条 BASELINE 全 PASS（见下机读行）
#   【⑫ 已知边界（登记，不是缺陷）】`.ttc` 多面：单面路径的 `segmentFaces` 走 **1 参构造 ⇒ face 0**（`HbFaceRef(fontPath, glyphFaceIndex)` 那边保留面索引）⇒ 多面 `.ttc` 的段面选择受限。
#   冻结来源：runner 自产机读行（`WPTD_BASELINE_OUT`）+ 同趟 stdout（`/tmp/gate14.stdout.log`）；原始证据 `~/wfp-runs/go-freeze14/**`；波证据 `~/wfp-runs/close-wave-105739/**`。
#   上一版（#13）的表头由本版取代（备份 `~/wfp-runs/ACCEPTANCE-BASELINE-13.md`）。
#   哪几位一变就要重冻：pc / pf / bridge / provider / win32shim / wic_shim / hbtextline / windowsbase / dwf（九位全在下面机读行里）
BASELINE tier=default rep=1 config=pc:9adac6b8d8e285c3,bridge:759a322431f1e457,pf:ed51db81db76bc76,provider:71ba86c6495347fe,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:17b2cdfe08f13280(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3962 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/go-freeze14
BASELINE tier=default rep=2 config=pc:9adac6b8d8e285c3,bridge:759a322431f1e457,pf:ed51db81db76bc76,provider:71ba86c6495347fe,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:17b2cdfe08f13280(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3962 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/go-freeze14
BASELINE tier=default rep=3 config=pc:9adac6b8d8e285c3,bridge:759a322431f1e457,pf:ed51db81db76bc76,provider:71ba86c6495347fe,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:17b2cdfe08f13280(stale:no) result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3962 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/go-freeze14
BASELINE tier=env rep=1 config=pc:9adac6b8d8e285c3,bridge:759a322431f1e457,pf:ed51db81db76bc76,provider:71ba86c6495347fe,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:17b2cdfe08f13280(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/go-freeze14
BASELINE tier=env rep=2 config=pc:9adac6b8d8e285c3,bridge:759a322431f1e457,pf:ed51db81db76bc76,provider:71ba86c6495347fe,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:17b2cdfe08f13280(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/go-freeze14
BASELINE tier=env rep=3 config=pc:9adac6b8d8e285c3,bridge:759a322431f1e457,pf:ed51db81db76bc76,provider:71ba86c6495347fe,win32shim:0098234982391bbf,wic_shim:03b67fbcd7c385b6,hbtextline_shim:17b2cdfe08f13280(stale:no) result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0 rundir=/home/links-dev/wfp-runs/go-freeze14
#   CENSUS(字形普查, 期望 id0≈0 / nonlatin>0 / maxid≈63151) T1C_CENSUS_SUMMARY frame=3 runs=167 handles=167 glyphs=1717 id0=0 nonlatin=421 maxid=63151 allnotdefruns=0 distinctpids=4 rc=0
#   CWIC(诊断趟 WPF_LINUX_CWIC_TRACE=1, 期望 materialize尺寸=96x96 fmt=…c90f Bgra32) NA [cwic-trace] source=0x5 ownedByWic=True materialize尺寸=96x96 foreignSources=0 shimGetSize=96x96（第二次=96x96 ok=True） format=6fddc324-4e03-4bfe-b185-3d77768dc90f → SKBitmap=96x96 colorType=Bgra8888 alphaType=Unpremul stride=384 bufferSize=36864 copyPixels=S_OK
[cwic-trace]   describe(source)= h=5 via=slot kind=FormatConverter foreign=0 ownedByWic=1 refs=1 size=96x96 rowBytes=384 fmt=6fddc324-4e03-4bfe-b185-3d77768dc90f pixels=yes decoded=1
#   WIC_NATIVE(诊断趟 WPF_LINUX_WIC_TRACE=1, 期望 prc=(0,0,96,96) 且 REFUSE=0) refuse=0
0 WIC_TRACE COPY_PIXELS h=5 96x96 foreign=0 prc=(0,0,1x1)
WIC_TRACE COPY_PIXELS_SUBRECT prc=(0,0,1x1) dst=4 cb=4
WIC_TRACE COPY_PIXELS h=5 96x96 foreign=0 prc=null
#   CENSUS_ORPHANS CENSUS_ORPHANS before=0 after=0；自起 Xvfb=无）
#   CENSUS_ALL（普查全量仪表行，前向兼容：新仪表自动入基线）
#     CENSUS_ORPHANS before=0 after=0
#     [GLYPH_CENSUS] frame=1 runs(绘制次数)=0 不同句柄=0 全notdef的run=0 glyphs=0 id0=0 maxId=0 非拉丁(id>=0x1000)=0 桶[0]=0 [1,FF]=0 [100,FFF]=0 [1000,3FFF]=0 [>=4000]=0 面标识: pid==0的run=0 不同面数=0 渲染器=(未知) hook成功=0 hook失败=0 无渲染器=0 资源查不到=0  [无信息：所有 run 的面标识相同 —— 若全为 0 则可能是字段没被填]
#     [GLYPH_CENSUS] 原点Y汇总: runs=0 distinct_origin_y=0  Y值(DIP)=[]
#     [GLYPH_CENSUS] frame=2 runs(绘制次数)=167 不同句柄=167 全notdef的run=0 glyphs=1717 id0=0 maxId=63151 非拉丁(id>=0x1000)=421 桶[0]=0 [1,FF]=1280 [100,FFF]=16 [1000,3FFF]=122 [>=4000]=299 面标识: pid==0的run=0 不同面数=4 渲染器=WpfGfx.Linux.Text.TextRenderer hook成功=167 hook失败=0 无渲染器=0 资源查不到=0  [有信息：确有多个不同面]
#     [GLYPH_CENSUS] 原点Y汇总: runs=167 distinct_origin_y=12  Y值(DIP)=[前8个:10.210,10.210,11.139,12.067,12.995,24.133,25.107,29.292…]
#     [GLYPH_CENSUS] 相关性: originDIP.y=10.210 的 run 数=13 其设备Y去重数=13  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=10.210 的 run 数=27 其设备Y去重数=7  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=11.139 的 run 数=17 其设备Y去重数=2 设备Y=[80.631,525.487]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=12.067 的 run 数=35 其设备Y去重数=8  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=12.995 的 run 数=48 其设备Y去重数=25  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=24.133 的 run 数=1 其设备Y去重数=1 设备Y=[62.639]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=25.107 的 run 数=5 其设备Y去重数=1 设备Y=[540.038]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=29.292 的 run 数=4 其设备Y去重数=2 设备Y=[162.146,323.515]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=45.589 的 run 数=7 其设备Y去重数=2 设备Y=[179.122,340.491]  ⇒ **设备Y各不相同 = origin 只是行内相对量**
#     [GLYPH_CENSUS] 相关性: originDIP.y=61.886 的 run 数=2 其设备Y去重数=1 设备Y=[196.098]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=78.183 的 run 数=5 其设备Y去重数=1 设备Y=[213.074]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] 相关性: originDIP.y=94.479 的 run 数=3 其设备Y去重数=1 设备Y=[230.050]  ⇒ **设备Y全同 = 上游就叠在同一处**
#     [GLYPH_CENSUS] run#0 handle=0x00000018 n=11 id0=0 max=91 pid=0x20000003 originDIP=(0.000,24.133) devX=37.500 devY=62.639 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,37.500] first16=58,83,73,55,72,91,87,39,72,80,82
#     [GLYPH_CENSUS] run#1 handle=0x0000001c n=2 id0=0 max=36710 pid=0x20000005 originDIP=(0.000,11.139) devX=37.500 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=18749,36710
#     [GLYPH_CENSUS] run#2 handle=0x0000001d n=3 id0=0 max=18 pid=0x20000004 originDIP=(24.000,11.139) devX=62.500 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,18,3
#     [GLYPH_CENSUS] run#3 handle=0x0000001e n=3 id0=0 max=27897 pid=0x20000005 originDIP=(35.672,11.139) devX=74.658 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=27897,27147,11929
#     [GLYPH_CENSUS] run#4 handle=0x0000001f n=3 id0=0 max=18 pid=0x20000004 originDIP=(71.672,11.139) devX=112.158 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,18,3
#     [GLYPH_CENSUS] run#5 handle=0x00000020 n=4 id0=0 max=47307 pid=0x20000005 originDIP=(83.344,11.139) devX=124.316 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=9492,21230,15698,47307
#     [GLYPH_CENSUS] run#6 handle=0x00000021 n=3 id0=0 max=121 pid=0x20000004 originDIP=(131.344,11.139) devX=174.316 devY=80.631 CTM=[1.0417,0.0000,0.0000,1.0417,37.500,69.028] first16=3,121,3
#   ORIGIN_Y(判据⑦ 行推进；阈值 10；根治前=6 / 根治后=12) 原点Y汇总: runs=167 distinct_origin_y=12  Y值(DIP)=[前8个:10.210,10.210,11.139,12.067,12.995,24.133,25.107,29.292…] verdict=PASS 取值频次:      2 originDIP=(83.344,11.139)       2 originDIP=(71.672,11.139)       2 originDIP=(35.672,11.139)       2 originDIP=(24.000,11.139) 
#   读图（保留格；普查/计数绿 ≠ 像素对 —— T1d 已登记这条预测假绿）：需人工/视觉复核 run_dir 下的 *-after.png
#   REAPED_ORPHANS total=0 detail=none（辅助趟漏下的孤儿；按精确 argv+ppid==1+PID 回收）
#   BRIDGE_SRC_STALE(桥→源 身份；期望 no；yes=部署件不是当前源编的⇒本趟读数作废) no basis=pub=705ed5ccd0c498a1 now=705ed5ccd0c498a1 so_file_match=yes
