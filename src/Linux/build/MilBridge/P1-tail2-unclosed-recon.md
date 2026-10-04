# P1-tail2 未闭项侦察（`TASK-0758`／`0759`／`0760`）—— 只读侦察 ＋ 逐条落点表

- **读时**：`2026-09-30T00:27:36+0800`（本席 `tF0` 现取）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=14f5421`。
- **件指纹（现取，`sha256` 前 16 位）**：`pkg-src-retiredpath-check.sh e0ab7bd668ffa8a1`｜`pts-pages-guard.sh 962fec114b2d0692`｜`session_inner.sh f1a582d9ea9788c9`｜`repo-alias-allow.tsv 19496f3615ccb45a`｜`arm-logs/README.md 337de20145258568`｜`KNOWN-DEFECTS.md 3d96ed2ce8102869`。
- **边界（照 T-F0 ②）**：只读；**未跑** `static-jaws-check.sh`；**未跑** `verify-all`；大件只用 `wc/head/tail/grep -c`；唯一可写件＝本文件。
- **行号纪律**：下表所有行号**仅本次有效**（内容锚原文一并给出，供下一位现取复核）。

---

## §0 前提核对（三条在册声明**已过期**，先报，免得照陈旧前提动手）

| 声明（出处） | 现取 | 结论 |
|---|---|---|
| `ROUTES.md:415`「`tree` 面补扫 `*.cs`（**现只扫 `*.sh/*.py/*.c/*.h`**）⇒ 现取十件带死根而守卫全绿」 | `pkg-src-retiredpath-check.sh:121,123` 现取**已含** `-o -name '*.cs'`；真树现跑 `RETIREDPATH=PASS mode=tree files=573 hits=3 code=0` | **前提已失效**：`*.cs` 已在射程（`e6b25b7` `B-4` 落的）。`ROUTES.md:415` 那半句需同趟更正 |
| T-F0 ①「`tree` 面（**声明约 `107-110`**）」 | `:106-110` 现取是 `classify_lines()` 里的 **heredoc 数据块探测**（`<<'` ⇒ `kind=data`），**不是** `tree` 面；`tree` 面在 `:120-123` | **声明指错行**；照现场以 `:120-123` 为准 |
| T-F0 ①「现取带死根的 `.cs` 件清单（**≥10 件**）」 | 全仓 `grep -rIl 'wpf-linux-20260906' --include='*.cs'` ⇒ **0 件**；`e6b25b7` 现取改了 **9** 件 `.cs`，`57cd937`（`t46`）另改 1 件 ⇒ 共 **10 件已清零** | **≥10 件无法"现取"**；§2 给的是**历史清单**（非现取），并给出每件**死根常量行原文** |
| T-F0 ②「`session_inner.sh:18` 显示号缺省行」 | `:18` 现取 = `# ── ⏪ \`t159\`：**工具换代**（会话端）…`（注释行）；显示号缺省行现取在 **`:24`** | **行号漂移**；且该条**已闭**（`e6b25b7` `B-9` 已加占用断言，见 §1 `0760-③`） |

---

## §1 逐条表（列＝`条目`｜`现取定位(件:行, 仅本次有效)`｜`现值/原文`｜`修法草稿(可执行)`）

### 0758 · 守卫射程（`build/MilBridge/tools/pkg-src-retiredpath-check.sh`）

| 条目 | 现取定位 | 现值/原文 | 修法草稿 |
|---|---|---|---|
| **0758-① tree 面原文** | `build/MilBridge/tools/pkg-src-retiredpath-check.sh:120-123`（`:121` 单行、`:122-123` 续行） | `121:` `      find "$ROOT" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' -o -name '*.cs' \) 2>/dev/null`<br>`122:` `      find "$ROOT/build" "$ROOT/tests" "$ROOT/src" -type f \`<br>`123:` `           \( -name '*.sh' -o -name '*.py' -o -name '*.c' -o -name '*.h' -o -name '*.cs' \) 2>/dev/null` | **无需改件**（`*.cs` 已在射程）。**改文档**：`ROUTES.md:415` 的「现只扫 `*.sh/*.py/*.c/*.h`」改为现取原文（含 `*.cs`），并写明该扩射程由 `e6b25b7` 落 |
| **0758-② 残留射程洞（真洞，新发现）** | 同上 `:121-123`：射程目录 ＝ **根(`maxdepth 1`)＋`build/`＋`tests/`＋`src/`** | 沙箱两臂（`/tmp/tf0sbx`，三目录齐）：<br>· 针在 `samples/Probe/Foo.cs` ⇒ `RETIREDPATH=PASS mode=tree files=1 hits=0 code=0`（**rc=0，洞**）<br>· 针在 `build/Foo.cs` ⇒ `RETIREDPATH=FAIL` ＋ `build/Foo.cs:2 kind=code rule=code-retired-path`（**rc=1**） | **补射程**：`tree` 面加一条 `find "$ROOT/samples" "$ROOT/tools" -type f \( -name '*.cs' … \)`（或把 `:121` 的 `-maxdepth 1` 放宽为 `-maxdepth 2`）。**须先验收**：`files` 数与耗时（现取 `files=573`）；缺目录时的 `tree-dir-missing` 目录闸（`:171-178`）须同趟把新目录纳入，否则又造一个「没被判」格 |
| **0758-③ 死根 `.cs` 清单** | 全仓（`.cs`）；历史出处 `e6b25b7^` 与 `57cd937^` | **现取 `0` 件**（`grep -c` 逐件全 `0`）；历史 10 件见 **§2** | **无需改件**。建议把 §2 表**入册**为「已清零」证据；`ROUTES.md:416` 的「十件死根面逐件『活/死判定』」改为「已清零，给历史清单＋现取复核命令」 |

### 0759 · 口径句入判据件批

| 条目 | 现取定位 | 现值/原文 | 修法草稿 |
|---|---|---|---|
| **0759-① 「零证据力」口径句** | 判据件 `build/MilBridge/tools/pts-pages-guard.sh:310`（`grep -c '零证据力' <该件>` 现取 **`2`**，命中 `:310`／`:311`）；原载体 `build/MilBridge/P0-mvp-pts-report.md:178` | `:310` 逐字：``#   · **本步只读 `leg_*.env` 的列，不读 `entry=` ⇒ 它的绿对"前沿位移"零证据力。**``<br>`:311` 逐字：``#   ⏪ **dated 更正（`t73`／scribe，2026-09-28）**：上面那半句里的「**不读 `entry=`**」**与事实不符**、按实写 —— 本步**确实读** `entry=`（就是 `g10_name_check`）…「其绿对前沿位移零证据力」这个**结论**仍成立…``<br>报告 `:178` 逐字：``**⚠️ 零证据力口径（`t13` 的读数，逐字入册）**：门禁步 `PTS-PAGES`（`verify-all.sh:1173`，默认读本目录）**只读 `leg_*.env` 的列，不读 `entry=`** ⇒ **它的绿对"前沿位移"零证据力**。`` | **已入判据件自身**（`e6b25b7` `B-8`，`0→2`）。**余项（可选）**：把 `tail-scout B-8` 的 acceptance 做成牙 —— 删件内该句 ⇒ 必红／至少 `NOINFO`；并把报告 `:178` 的句式改成「口径现址＝判据件 `:310`」以防双址漂移。⚠️ 报告里的 `verify-all.sh:1173` 行号**必须现取**（`HANDOFF-NEXT.md` 自救条写「`:1174`，不是 `:1173`」） |
| **0759-② `w27-freeze.py` `provider` 两值注释** | `~/w21-verify/w27-freeze.py:442-445`（`:441` 为 `prev='#79', nstep=55,`） | `:442` ``# `prev_*` = `#79` 块九位行的**现取复核值**；`prev_provider`/`prev_wic_shim` **不取九位行**``<br>`:443` ``# （照 `#79` 先例：那两格取**哨兵**的现取值。本代另有"重建驱动"事实：`#79` 块声明 `759ac1686e5ef87d`，``<br>`:444` ``#  `Provider` 产物先后被重建为 `8cb1b50619f4c133`（02:23:33，＝哨兵现取、亦即下行 `prev_provider`）``<br>`:445` ``#  与 `7e8a217b4165a6b9`（`#80` 块九位行声明值）⇒ 三个时刻都写进 `P0-w80-report.md` §六）`` | **判：注释与事实不符（两处）**。① `:444` 的等式「`8cb1b50619f4c133` ＝ **哨兵现取**」**现取不成立**：`/tmp/bridge-frozen.flag` 与 `~/wfp-runs/bridge-frozen.flag` 现取**同为** `PROVIDER=24e4e0a731dbed40`（两哨兵 `cmp IDENTICAL`）；② 注释只有**两值**，而现取 canon `build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll` ＝ **`24e4e0a731dbed40`**（**第三值**，不在注释内；`#80` 块九位行 `:66` 声明值 `7e8a217b4165a6b9` ✓、`#79` 块 `:140` 声明值 `759ac1686e5ef87d` ✓ ⇒ 注释所声称的 `#79` 声明值**对**）。⇒ 与 `D-G176` §③「四处值互异」同族。**修法**：把 `:444` 的「＝哨兵现取」改为「＝**#80 冻结时刻**哨兵值（非现取）」，并补第三值 `24e4e0a731dbed40`（canon live，现取）＋读时戳。**仓外件 ⇒ 队长写域** |
| **0759-③ `D-G178` 在册条目 ＋ 需改内容锚** | 在册 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:3659`（条目形态标题）；内容锚在**仓外仪器** | 条目现取要点：入口锚 `_block_of_prev()` `~/w21-verify/w27-freeze.py:1313-1317`，判定行 `:1317` 逐字 `        if l.startswith('# RE-FROZEN ' + prev):`；出口锚 `_BLK_HDR` **`:1221`** 逐字 `_BLK_HDR = re.compile(r'^# (?:RE-FROZEN #\d+\b|⏪ \*\*（历史[^）]*）\*\*# RE-FROZEN #\d+\b)')`；冻结器自加装饰 **`:1706`**：``body_lines[0] = f'# ⏪ **（历史，已被 `{gen}` 取代）**' + body_lines[0]``；现取基线 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:81` 正是被装饰后的 `#79` 块头 | **需改内容锚 ＝ 上述三处同宽**：`w27-freeze.py:1317`（入口锚）必须与 `:1221`（出口锚）**同宽**（或改写成「剥掉降级装饰后再比」）。**先加守卫、再改锚**（照已修先例 `build/MilBridge/tools/column-floor-check.sh:154-171`）。**仓外件 ⇒ 队长写域**；**本条只登记**（照在册条目的边界句） |
| **0759-③b `D-G181` 在册条目 ＋ 需改内容锚** | 在册 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:3721`；锚＝各 `verify`／acceptance 契约里 `git diff --numstat -- <件>` 的**调用点** | 现取同形调用点（`grep -rn -- '--numstat'`）：`build/MilBridge/P1-fontstack-fallback-criteria.md:303` 逐字 `git diff --numstat -- build/WindowsBase.Linux/Invariant.Linux.cs upstream/wpf/src/…/Invariant.cs`；同族先例 `build/MilBridge/P1-dg179-report-verify.md:219`（工作树级 ⇒ 空 ⇒ 假绿）与 `:221`（建议改提交级） | **改法（照在册判据三条）**：把 `git diff --numstat -- <件>` 改成**提交级**（`git show --numstat <sha> -- <件>` 或 `git diff --numstat <sha>^ <sha> -- <件>`），或加**备份前缀 `cmp`**；坚持工作树级 ⇒ 输出为空时**判 `NOINFO`，不许判绿**。**只改契约写法、不改产品件**；在册条目明写「责任在队长」 |

### 0760 · 装置小单批（四条）

| 条目 | 现取定位 | 现值/原文 | 修法草稿 |
|---|---|---|---|
| **0760-① `arm-logs` 硬链接两案 ＋ `repo-alias-allow.tsv`** | `build/MilBridge/arm-logs/README.md:3-8`（硬链接理由）、`:24`（`ln -f` 纪律）、`:63-66`（不许 `cp`／不许 `rm`）；`build/MilBridge/repo-alias-allow.tsv:26`（唯一数据行） | 现取 `nlink`：`tline.log=1`／`textlineproto.log=1`／`tab-anchor.log=2`／`tab-rtl.log=2`／`tab-zero.log=2`（README 要「链接数保持 2」）。`repo-alias-allow.tsv:26` 逐字：`/home/links-dev/w62a/negrepo	6417	W62A 负例仓（\`cp -al\` 造的影子树…）`；`:27-33` dated 补注写「现取孪生 ＝ **`0`**（真树 `ALIAS=PASS examined=18075 linked_gt1=0 …`）⇒ `allowed-tree-grown` **现取恒不触发**」，并如实记**量名歧义**（该树**物理件数** `find … | wc -l` ＝ `12918` ≠ 孪生计数） | **两案择一（在册判词见 `HANDOFF-NEXT.md:300`）**：**(甲)** 删输出侧孪生（`#80` 已做法，已达 `ALIAS=PASS`）—— 代价＝`arm-logs` 侧 `*.log` 退化成 `nlink=1`（现取 `tline`／`textlineproto` 已是 1）；**(乙)** 把该树在 `repo-alias-allow.tsv` **声明**掉，**上限＝现读件数**（现读 `0`）。⚠️ **(乙) 若要用，必须同趟处理「上限 = 0 对 12918 件树」的量名歧义**（否则上限钉的是**孪生计数**、被读成**物理件数** ⇒ 一律误红）。入册先例：`P1-tail-scout.md:294` §B-7、`P0-w80-report.md:101` §10-7 |
| **0760-② `~/w79c/bin/w79-push.sh` 的 `FILES` 累积语义** | `~/w79c/bin/w79-push.sh:133-179`（`FILES=` 定义，**仓外件**）；`:180` `PUSH_LIST="${W78_PUSH_LIST_OVERRIDE:-$FILES}"`；`:198` `for f in $FILES; do … git add -- "$f"; done` | 现取：`FILES` 是**一条 47 行的固定多行清单**（`:133-179`，从 `#78` 波起**只增**、无「本波清单」边界、无「上一波清单」对照）；无 `累积`／`只增`／`收缩` 字样（`grep -c` ＝ 0 ⇒ 语义只在**形态**上）。`:182-183` 自救条记「`--check-only` 原先排在 `FILES=` 之前 ⇒ 读 `${FILES:-}` 恒空」 | **改「每波一份清单」**：把 `:133-179` 的 `FILES=` 改为**从本波清单件读**（如 `FILES="$(cat "$HOME/w79c/wave-$GEN.list")"`），并把「清单只增」写成机读行（例 `PUSH_LIST_SCOPE gen=#NN files=<n>`）；同趟保证 `push_infp_tooth()`（`:120-130`）与 `--check-only`（`:184`）读的是同一份。⚠️ **仓外件、且非本仓写域** ⇒ 需**队长授权** |
| **0760-③ `session_inner.sh` 显示号缺省行** | `build/MilBridge/tests/PtsPagesProbe/session_inner.sh:24`（T-F0 声明的 `:18` 已漂移；`:18` 现取＝`t159` 注释行） | `:24` 逐字：`D="${W67_DISPLAY:-:237}"`。**占用断言已在同件落地**（`e6b25b7` `B-9`）：`:66` `CANON_XDIR=/tmp/.X11-unix`、`:70-74` socket **双边**检查、`:110-118` `DISPLAY_LEASE=free`／`official-caller-owned`／否则 `DISPLAY_OCCUPIED … exit 3`；`:52-64` 另加 `t157` 的「分配结果与消费者同源」 | **本条已闭**。余项＝**校正文档行号**（`ROUTES.md:423` 的「`session_inner.sh:18`」⇒ `:24`），并把「反极腿（先占 `:237` ⇒ `rc≠0` 具名拒跑）」记入本波验收（照 `tail-scout B-9`；⚠️ 反极腿要起第二个 `Xvfb` ⇒ **需槽 ＋ 私有 `:2xx`**、按 PID 收） |
| **0760-④ `D-G176` 预留号状态** | 在册 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:3608`（条目形态标题）；声明表 `build/MilBridge/tools/defect-registry-declared.tsv:108` | 现取：条目形态标题 `grep -c '^### 🆕 \*\*\`D-G176\`'` ＝ **`1`**；册内提及 `grep -c 'D-G176'` ＝ **`2`**；声明表 `:108` 逐字 `ID	D-G176	req=KD	present=KD`；`build/MilBridge/known-red.json` 内 `G176` 命中 **`0`**（该件未登记缺陷号）。在册 dated 追记（`:3625`）自述「① 本条的『预留 → 正式条目』这一半现取**已完成**（`t57` 按裁定登记）」 | **本条已闭**（预留语义已消）。余项＝`ROUTES.md:423` 的「`D-G176` 预留号随登记批落」改为「**已落**（`t57`）」，避免后来者重复登记。⚠️ 若走「对手牙」路线（照 `D-G182` 的判据③），`known-red.json` 无该号**不是缺陷**（它是缺陷登记册、不是缺陷条目册） |

---

## §2 0758 死根 `.cs` 清单（**历史，非现取**；现取 ＝ 0 件）

现取复核命令（全仓，现取返回 **0**）：
`cd /home/links-dev/netTest/GitProj/WPFOnLinux && grep -rIl 'wpf-linux-20260906' --include='*.cs' .`

| # | 件 | 死根常量行原文（出处 `e6b25b7^`，行号仅本次有效） | 现取 `grep -c` |
|---|---|---|---|
| 1 | `build/DirectWrite.Linux/WicSeamProbe/Program.cs` | `:15` `            : "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/samples/HelloMil/screenshot.png";` | 0 |
| 2 | `build/MilBridge/tests/BboxProbe/Program.cs` | `:23` `        string font = argv.Length > 0 ? argv[0] : "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/fonts/NotoSans-Regular.ttf";` | 0 |
| 3 | `build/MilBridge/tests/CoverageProbe/Program.cs` | `:88` `        private const string Root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";`（另 `:1028`／`:1159`／`:1240` 三处局部 `const string root` 同串） | 0 |
| 4 | `build/MilBridge/tests/FrameProbe/Program.cs` | `:309` `            string authPc = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll";` | 0 |
| 5 | `build/MilBridge/tests/IcuBreakParity/Program.cs` | `:62` `        _root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";` | 0 |
| 6 | `build/MilBridge/tests/LsProbe/Program.cs` | `:9` `        const string shim = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/src/WpfGfx.Linux.Native/bin/libwpfwin32.so";` | 0 |
| 7 | `build/MilBridge/tests/PcLineOracle/Program.cs` | `:171` `        private const string Root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";` | 0 |
| 8 | `build/MilBridge/tests/ResolverGuardProbe/Program.cs` | `:40` `        string shim = TakeOption(rest, "--shim") ?? "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/src/WpfGfx.Linux.Native/bin/libwpfwin32.so";` | 0 |
| 9 | `build/MilBridge/tests/T2eLineHeight/Program.cs` | `:24` `    private const string Root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";`（另 `:25` `Dir`／`:28` `FontLat` 派生式同串） | 0 |
| 10 | `build/MilBridge/tests/HbTextLineParity/Program.cs` | `:42` `        private const string Root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";`（出处 `57cd937^`；现取 `:42` ＝ `"/home/links-dev/netTest/GitProj/WPFOnLinux"`） | 0 |

- 1–9 件由 `e6b25b7`（`perf+docs(#80): … 9 件 .cs 死根面清零`）改为 **env 注入 ＋ 缺则 `throw`**（现取形态：`Environment.GetEnvironmentVariable("WPF_PROBE_T2E_ROOT")` 等）；第 10 件由 `57cd937`（`t46`）改成**活树字面量**。
- 由此**「十件带死根而守卫全绿」这一前提已闭**：死根 0 件 ＋ 守卫已扫 `*.cs`。**残留的真洞是射程目录**（§1 `0758-②`）。

---

## §3 逐条归属（哪条路线／哪件写域）

| 条目 | 路线 | 写域 | 状态 |
|---|---|---|---|
| 0758-① tree 面原文 | `TASK-0758`（`ROUTES.md:414-417`） | 文档：`docs/ROUTES.md`（**不是**牙本身） | 前提已失效，需更正描述 |
| 0758-② 残留射程洞 | `TASK-0758` | **仓内** `build/MilBridge/tools/pkg-src-retiredpath-check.sh`（＋`--selftest` 新臂 ＋ `fp_inputs()` 位移同趟） | **新发现，待落** |
| 0758-③ 死根 `.cs` 清单 | `TASK-0758` | `*.cs` **只审不改**（除已修 `HbTextLineParity`，`ROUTES.md:417`） | 已清零；建议入册 |
| 0759-① 零证据力口径句 | `TASK-0759`（`ROUTES.md:418-421`） | **仓内** `build/MilBridge/tools/pts-pages-guard.sh`（＋`fp_inputs()`：在覆盖面内） | 已落（`e6b25b7` `B-8`）；余项＝可选牙 |
| 0759-② `provider` 两值注释 | `TASK-0759` | **仓外** `~/w21-verify/w27-freeze.py`（`ROUTES.md:421` 明写**队长写域**） | 待落（须队长动） |
| 0759-③ D-G178／G181 锚 | `TASK-0759` | D-G178：**仓外** `~/w21-verify/w27-freeze.py`（队长写域）；D-G181：**仓内**各 `verify`／criteria 契约写法 | 待落（先加守卫再改锚） |
| 0760-① arm-logs 硬链接两案 | `TASK-0760`（`ROUTES.md:422-425`） | **仓内** `build/MilBridge/repo-alias-allow.tsv`（很可能**只改注释**；`fp_inputs()` 内 ⇒ 必移、件数不变） | **待队长择甲/乙** |
| 0760-② `FILES` 累积语义 | `TASK-0760` | **仓外** `~/w79c/bin/w79-push.sh`（车道写域） | 待落（须授权） |
| 0760-③ `session_inner.sh` 显示号 | `TASK-0760` | **仓内** `build/MilBridge/tests/PtsPagesProbe/session_inner.sh` | **已闭**（`e6b25b7` `B-9`）；余项＝文档行号 |
| 0760-④ `D-G176` 预留号 | `TASK-0760` | **仓外/册**：册内条目已落、声明表已落 | **已闭**（`t57`）；余项＝文档措辞 |

**前置（选读）**：`ROUTES.md:414-425` 的三条 target/判据/写域现取见本文件 §1；`e6b25b7` 现取已同时做了 `B-3/B-4/B-7/B-8/B-9` ⇒ **`TASK-0758`／`0760` 的多数小单在 `#80` 已顺手落地**，本批的真实增量＝**§1 `0758-②`（真洞）＋ `0759-②`／`0759-③`（仓外口径）＋ `0760-①/②`（两案择一／清单语义）**。

---

## §4 边界与 NOINFO（如实划界）

1. **未跑** `static-jaws-check.sh`、**未跑** `verify-all`（照 T-F0 ②）。真树只跑了 `pkg-src-retiredpath-check.sh --tree` 一趟（只读、`RETIREDPATH=PASS files=573 hits=3 code=0 declared=3 self_skip=1`）。
2. **`0758-③` 的「≥10 件现取清单」不可达**：现取为 0 件。§2 给的是**历史清单**（出处 `e6b25b7^`／`57cd937^`），**不是现取** ⇒ 该列已在表内显式标注。
3. **旧树未普查**：`/home/links-dev/netTest/wpf-linux-20260906/` 现取是个**空目录**（只剩 `README-why-this-link-stays.md`）⇒ 仓外旧树里是否另有 `.cs` 死根 **`NOINFO`**（不在本件射程：T-F0 只点了仓内件）。
4. **`0760-②` 的「累积」是形态判读**，非件内自述：`w79-push.sh` 内 `grep -c '累积'` ＝ `0` ⇒ 「只增不收缩」由**清单形态＋无本波边界**推出，**未见**「每波一份清单」的设计句。
5. **沙箱**：`0758-②` 两臂在 `/tmp/tf0sbx`（仓外 `mktemp`‑style 目录）真跑，仓内零写入；本件是本次唯一写入的仓内文件。
6. **未做**：`0760` 各条的 `--selftest` 正/反两腿（`ROUTES.md:424` 的 acceptance）—— 那属**落地方**，本件是**只读侦察**；`0759` 的「删句⇒必红」两极化同此。
