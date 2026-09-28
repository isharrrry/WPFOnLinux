# P1-W4a 收口报告 —— **判词：`BLOCKED`（零承重写入）**：契约写域里的 `build/verify-all.sh` **现取不存在**

⏪ **本件（`t46`／`W4a`）判词：`BLOCKED` —— 本席**未改任何承重件**，收口于本报告。** 契约 `inScope` 的第一条路径 `build/verify-all.sh` **现取不存在**：`ls build/verify-all.sh` ⇒ 「没有那个文件或目录」；`git ls-files | grep verify-all` ⇒ 只有 **`verify-all.sh`（仓根）** 与 `build/MilBridge/tools/verify-all-step-check.sh`；`git log --oneline -- build/verify-all.sh` ⇒ **零提交**（该路径**从未存在过**）。⇒ **三项承重交付（①三步接线 ②四处声明 ③`[42] --expect 226 → 229`）全部只可能落在域外的那一件（仓根 `verify-all.sh`）上** ⇒ 按铁律「**写域严格照 `inScope`、超域即停手报队长**」，本席**零承重写入**、请队长改派（改法见 §3，已现取全部锚点、下一趟可直接照做）。读时 `ts=2026-09-28T17:11:00.540+0800`。

⏪ **§0 判据（先写，本报告一切结论按此读）**：① **本件零写入承重件** ⇒ 没有 before/after 逐处，也没有「写入后复核」的对象（本报告的「复核」只针对**只读读数**）；② 一切数值**现取 ＋ 给命令 ＋ 给 `ts`**；③ **自证值只携末行**（`head -n -1`，`t42` 形态）—— 本件**不写自身全文 `sha16`**；④ `NOINFO` 具名；⑤ 门禁件现取值**只对 `ts=2026-09-28T17:11:00.540+0800` 成立**（第 `24` 条口径）。

⏪ **§1 为什么不做「半件」（这是本席停手的理由，不是懒）**：
⏪ **① `build/close-wave.sh`（域内）白名单 +3 ⇒ 覆盖面 226 → 229，但 `[42] --expect` 在域外件里** ⇒ 那一步必报 `FAIL reason=files-n-mismatch delta=-3`（方向安全，但**仍是红**）⇒ **半件＝把门禁留在红上** ⇒ 不做；
⏪ **② `docs/WAVE81-PREREGISTRATION.md`（域内新建）**：门禁第 `[47]` 步 `BOUNDARY-DECL`（现取 `verify-all.sh:1200` ＝ `run_step "BOUNDARY-DECL" bash build/MilBridge/tools/boundary-decl-check.sh`）**会从 `docs/WAVE*-PREREGISTRATION.md` 读回声明与谓词参数**（见 `verify-all.sh:76` 那条 `DECL` 史实行原文）⇒ 接线未落时先落一份新波预登记，等于**加声明域而不加接线** ⇒ 不做；
⏪ **③ `build/MilBridge/HANDOFF-NEXT.md`（域内）**：本波的服务对象是「**接线的账**」⇒ **接线未落 ＝ 无账可落**（边界明文「只落本波接线的账」）⇒ 不做。
⏪ **⇒ 本件唯一产物 ＝ 本报告**（契约允许新建）；`git status --porcelain` 逐行归属见 §4。

⏪ **§2 现取证据（本席自跑，全部只读；行号仅本次有效）**：
⏪ **① 门禁真身在仓根**：`verify-all.sh` sha16 **`600274f130cfe913`**／**`1303` 行**／mode `644`／mtime `2026-09-28 11:51:16.316450201 +0800`；`grep -c '^run_step "' verify-all.sh` ⇒ **`55`**；`# VERIFYALL-STEPS-DECL: 55 gen=#79` 现取 **`:70`**；`# VERIFYALL-STEP-NAMES:` 现取 **`:120`**；头注释口径句 `#   **#79 收官起 = 55 步**` 现取 **`:7`**（紧邻 `:8` 是 `#80 收官起 = 55 步` 的 dated 取代行）；`[42]` 步现取 **`:1195`** ＝ `run_step "FP-MANIFEST-TEETH" bash build/MilBridge/tools/fp-manifest-step.sh --expect 226`；步表**末两行**现取 **`:1210`／`:1211`** ＝ `RETIRED-PATH`／`REPORT-ID-DOMAIN`。
⏪ **② 单步自检（入口读数，rc 现取）**：`bash build/MilBridge/tools/verify-all-step-check.sh` ⇒ **`VERIFYALL_SELF=PASS names=55 decl=55 gen=#79 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=600274f130cfe913`**（`rc=0`）；`bash build/MilBridge/tools/fp-manifest-step.sh --expect 226` ⇒ **`FP_MANIFEST_TEETH=PASS reason=ok files_n=226 files_n_uniq=226 blank_n=0 declared_expect=226 declared_paths=none`** ＋ **`FP_MANIFEST_STEP_RC=0 names_n=226 expect=226 tooth_sha16=be19edddf7f02797`**。
⏪ **③ 三颗新牙现取（**均在覆盖面外**）**：`build/MilBridge/tools/sentinel-spec-check.sh` ＝ `8c8470a3b3dd0c0d`／`118` 行｜`build/MilBridge/tools/wave-push.sh` ＝ `abc03532b87d6c0e`／`142` 行｜`build/MilBridge/tools/timestamp-order-check.sh` ＝ `6ace8e29f3cf6357`／`220` 行；`bash ~/w153a/bin/infp.sh list | grep -c <基名>` 三颗**各 `0`**（`in-list=0`）。
⏪ **④ 覆盖面入口（带 `ts`）**：`bash ~/w153a/bin/infp.sh fp` ⇒ **`62786107cf3c553032d098b2f20dc5facd204c424cf02e849c084a515c2e96bb`**；`… | list | wc -l` ⇒ **`226`**（读时 `ts=2026-09-28T17:11:00.540+0800`）。**本件零写入 ⇒ 本报告只给入口值，出口值不存在**（见 `NOINFO` ②）。
⏪ **⑤ 三牙 `usage` 现取（接线 argv 的依据，`§3` 用）**：`sentinel-spec-check.sh:17` ＝ 「用法：`bash sentinel-spec-check.sh [--selftest]`」｜`wave-push.sh:15` ＝ 「用法：`bash wave-push.sh --dry-run`（只打印 13 行到 stdout、**不写盘**）」｜`timestamp-order-check.sh:43` ＝ 「用法：`bash timestamp-order-check.sh [--file <件>]… [--assume-first-commit ISO] [--selftest]」⇒ **三颗的接线 argv 须按各自 `usage` 现取**，**不许**照抄别处的写法。

⏪ **§3 现成改法（给改派后的下一趟；**本席未执行**，锚点全部现取）**：
⏪ **① 三步接线**：落点 ＝ 步表末尾（现取 `:1211` 之后），与既有写法同形：`run_step "<步名>" bash <牙相对路径> <argv>`；步名建议 `SENTINEL-SPEC`／`WAVE-PUSH`／`TS-ORDER`（**步名与 `STEP-NAMES` 多重集必须同趟一致**）。**步号不许写死**（现件里步号只出现在 `[42]` 这类既有锚里）。
⏪ **② 首行 `DECL` 行**：**插入锚必须动态取「文件里第一行 `# VERIFYALL-STEPS-DECL`」并断言 `hits==1`**（`D-G131`）：现取 `grep -n '^# VERIFYALL-STEPS-DECL' verify-all.sh | head -1` ⇒ **`:70`**；新行形如 `# VERIFYALL-STEPS-DECL: 56 gen=#81   ← …（本波加三步：…）`，插在该行**之前**（与既有惯例同形：新声明在最上）。
⏪ **③ 头注释口径句**：新增一行 `#   **#81 收官起 = 56 步**（⏪ 本行**取代**紧邻下方那条 `55 步`：…）`，插在现取 `:7` 那一行之前（该处已是「取代」链的写法）。
⏪ **④ `STEP-NAMES`**：现取 `:120`（`# VERIFYALL-STEP-NAMES: …`）⇒ **同趟**把三个新步名并进该多重集；判据是 `verify-all-step-check.sh` 的**多重集相等 ＋ 条数相等 ＋ 次序一致 ＋ 无重名**（现取自述见其头注释）。
⏪ **⑤ `[42]`**：现取 `:1195` 的 `--expect 226` ⇒ **同趟**改 `229`。
⏪ **⑥ 覆盖面 `226 → 229`**：`build/close-wave.sh` 的 `fp_inputs()`（现取白名单体在 `:104`–`:115` 的 `find` 链）**+3 行**（三颗牙的显式路径，与既有写法同形）；**`inputs_fp` 必移**（三颗新入 ＋ `close-wave.sh` 自身在覆盖面内）。
⏪ **⑦ 下一趟的预期读数（本席**未**验，属预判、不是读数）**：`VERIFYALL_SELF=PASS names=56 decl=56 …`／`FP_MANIFEST_TEETH=PASS files_n=229 declared_expect=229`／`inputs_fp` ≠ 入口值。**⚠️ 预判不是证据**（本报告不据此判红判绿）。

⏪ **§4 边界／归属（现取）**：`git status --porcelain` ⇒ **恰 `1` 行** ＝ `?? build/MilBridge/P1-task0201-criteria.md`（**`t7` 的**既存未跟踪件，**未读未改**）；本席**零承重写入**、未新建除本报告外的任何件、未 `git add/commit/push`（`HEAD=b5e1d1f`，暂存区 `0`）。⇒ **越域 ＝ 0**。
⏪ **§5 两牙现取（不退化旁证）**：`DEFREG`／`REPORTID` 的现取读数见交件消息（本席**未**改任何 route 件或语料件 ⇒ 二者与入口逐格相同；本报告自身**匹配** `*report*.md` 语料 ⇒ `REPORTID files=+1`，故交件消息给**成对**两值）。

⏪ **`NOINFO`（具名，既不算绿也不算红）**：① **接线后的落定读数**（`VERIFYALL_SELF`／`FP_MANIFEST_TEETH`／步数）—— 本件零写入 ⇒ **不存在**，只有 §2 的**入口**值｜② **`inputs_fp` 出口值** —— 同上；且入口＝出口这件事在**本件**只是「未改任何覆盖面件」的结果，**不是**不变量断言｜③ **三颗新牙的真跑读数**（`--selftest`／`--dry-run`）—— 接线未落，本件按纪律**未跑**（留给下一趟；本件纪律亦明说「**不许**跑整趟 `verify-all`」）｜④ **`STEP-NAMES` 现件清单的长串原文** —— 本席只给行号与判据，**未**把未核对的长串抄进本报告｜⑤ **未跑门禁整趟／整波／冻结／构建／应用／显示位**（本件纪律）｜⑥ **契约 `Verify` 第 1／2 段本身不可执行**（`grep -c '^run_step "' build/verify-all.sh` 指向**不存在的路径** ⇒ 该命令必报「没有那个文件或目录」）—— 这是**契约缺口**，不是本席未跑。

⏪ **§6 请队长裁（一件）**：把 `t46`（或新一件）的 `inScope` 第一条由 `build/verify-all.sh` **改成仓根 `verify-all.sh`**（**或**明文授权本席改仓根 `verify-all.sh`）⇒ 本席即可按 §3 的现成锚点**同趟**落：三步接线 ＋ 四处声明 ＋ `226→229` ＋ `--expect 229`，并按契约跑三颗牙与两个单步自检、给机读行与 `rc`。

⏪ **§7 dated 追加（同趟实测，`ts=2026-09-28T17:11:31.236+0800`；上文一字未删）—— 契约要的「两读数」现取：该步确实会红、方向安全**：把契约 `Verify` 第 `2` 段的命令**原文**在**未接线**的现树上真跑：`bash build/MilBridge/tools/fp-manifest-step.sh --expect 229` ⇒ **`FP_MANIFEST_TEETH=FAIL reason=files-n-mismatch files_n=226 expect=229 delta=-3（件数对不上 ⇒ 有真名被吞或有异物混入；**形状可以完全合法**，只有这一格看得见）`** ＋ **`FP_MANIFEST_STEP_RC=1 names_n=226 expect=229 tooth_sha16=be19edddf7f02797`**。**成对（两读数都给）**：`--expect 226` ⇒ **`PASS reason=ok files_n=226 … declared_expect=226`／`rc=0`**（§2②）｜`--expect 229` ⇒ **`FAIL reason=files-n-mismatch delta=-3`／`rc=1`**（本行） ⇒ **「声明常数 != 现场件数 ⇒ 必红、且方向安全（少 3 件只会红、不会假绿）」这一条**在现树上**成立**；**正极**（白名单 `+3` 后 `files_n=229 ∧ declared_expect=229 ⇒ PASS`）**要等接线落地** ⇒ 记 **`NOINFO(reason=接线未落)`**。
⏪ **§7 附（本行的口径，按第 `24` 条）**：以上两读数的 `sha16`／件数只对 `ts=2026-09-28T17:11:31.236+0800` 成立；`tooth_sha16=be19edddf7f02797` 是**牙**（`fp-manifest-teeth-check.sh`）当刻取值，**不是**被检件。
⏪ **本件自证（本报告全文 `sha16` 只在交件消息里给；本行只携带 `head -n -1` 口径值）**：`head -n -1 build/MilBridge/P1-w4a-report.md` ＝ `3d934e642c3d6506`（口径＝**末行之前的全文**；末行＝**本行**）。
