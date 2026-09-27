# `P0-w78-report.md` —— 波 `#78` 落地（**未冻结 · 未推送**；车道 `waveman`）

**结论：`state=BLOCKED`。** 四件包的**载荷已全部落地**（含唯一一处产品改动），**整波已跑完**，但 **`gate1` 5 步红** ⇒ 链条按设计**停在「不冻结」**（`PRE_NOT_ALL_GREEN` 前就已被 `FAILN≠0` 拦住）。**树未冻结、未推送、`porcelain≠0`** —— 如实报主控裁。

## §1 已落地（逐件现取 / 备份取在任何写之前 / `D-G126` 断言）
| 件 | 落点 | sha16 |
|---|---|---|
| `TASK-0747` 产品源 | `src/WpfGfx.Linux.Native/src/win32_oem.c` | `ca500dcefe716835` → **`d6c5b682375a22be`**（9,375 → 16,310 B） |
| `TASK-0747` 牙 ＋ 台账 | `build/MilBridge/tools/{appbar-startup-check.sh,appbar-startup-ledger.tsv}` | `1b29d70d01c3239b`／`01d2248bb6f96f3a` |
| `D-G147` 产品源 ×4 | `src/WpfGfx.Linux.Native/src/{win32_x11.c,win32_core.c,win32_misc.c,win32_internal.h}` | `9fa20864404ab01b→8177fb1dee6c6951`／`e7f6a37a30f5a037→d3f643a5b18ae414`／`b09058febe5954e4→02bfe06166e7f425`／`c13390de6f870999→adfa3fcd8b926d6a` |
| `TASK-0739`③ 装置＋牙＋片段 | `build/MilBridge/tools/{display-lease.sh,display-lease-gate.sh}`＋`docs/WAVE78-PREREGISTRATION-FRAGMENT-TASK0739-3.md` | `b4f6ff69c79b2c0a`／`a638debcab4da178`→**`018c51c12a14479a`**（见 §4-①）／`a701fd5a1fab5c88` |
| `0744-FU` 装置＋FU 牙＋语料＋片段 | `build/MilBridge/tools/devices/{xwrap-sockid.c,xwrap-sockid.so,dev-selftest.c}`／`build/MilBridge/tools/proto-attribution-check.sh`／`docs/WAVE77-PREREGISTRATION-FRAGMENT-TASK0744-FU.md` | `928d1cc2723c887e`／`2656608a20bea6ec`／`d6569503e2f5412b`／`49bb6126b499c2cd→62e46ff230f5c2cc`／`922c68a78296ca2b` |
| 四处声明 ＋ 接线 | `verify-all.sh`（步 `50→51`、`DECL 51 gen=#78`、口径句、`STEP-NAMES` 尾追加 `APPBAR-STARTUP`、`--expect→217`）／`build/close-wave.sh`（覆盖面 ＋5 行） | `verify-all` `8813078cf1fe51a6`→**`d7386f5b4ca9fa8e`**；`close-wave` `ee82b635902d2cfe`→**`06d52a92e2661d47`** |
| 预登记 | `docs/WAVE78-PREREGISTRATION.md`（四要件 ＋ `PREREG-NO-REGRESSION-DECISION:` 机读行 ＋ `WFREEZE-DECL: gen=#78 allow_changed=pf,win32shim,provider pf_required=False`） | `3972 B` |

**读数（现取）**：`VERIFYALL_SELF=PASS names=51 decl=51 gen=#78 dup=0 order=OK prose=OK prereg=PASS`｜`FP_MANIFEST_TEETH=PASS files_n=217 = declared_expect=217`｜`WIRING_COVERAGE=PASS run_step=51 coverage_n=217 missing_n=0`｜`SELFDESC_WIRING=PASS fails=0`｜`LANEPATH=PASS`｜`BOUNDARY_DECL=PASS records=2`｜`DEFREG=PASS declared=182`｜`SHELL_QUOTE_TRAP=PASS traps=0`｜`WFREEZE_CONSISTENCY=PASS（三档）`｜**`nm -D --defined-only libwpfwin32.so | grep -c SHAppBarMessage` = 1**｜导出数 **554**｜`libwpfwin32.so = e8127a3d7128d417`。

## §2 🔴 `gate1` 5 步红（**这就是不冻结的原因**；逐条给现场，`gate1` 日志 `~/w185a/w77/logs/w78-gate1-20260926-223252.log`）
1. **`QUOTE-TRAP`** ❌ `reason=dq-backtick traps=4`（全在 `display-lease-gate.sh:205/214`）⇒ **已修**（反引号改「」）⇒ 现读 `SHELL_QUOTE_TRAP=PASS traps=0`。**此项已转绿。**
2. **`PRODUCT-ENTRY`** ❌ `PRODUCT_ENTRY_STEP=NOINFO 拿不到 PEA_SUM 汇总行（rc=2）`｜`PEA_EXIT=NOINFO rc=2 原因=字体文件不存在：/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/fonts/NotoSans-Regular.ttf` ⇒ **`t7` 撤掉旧路径后，装置仍按旧路径找字体**。现场：旧路径残留于**构建中间物**（`build/MilBridge/.artifacts/obj/*.nuget.dgspec.json` 等，含 `projectPath`/`outputPath` 的旧树绝对路径）⇒ **`t17` 的"仓外／仓内可执行默认值"扫描（只扫 `*.sh`/`*.py`）射程不含它们**。**未修**（需先把相关工程重建/清理中间物，或把装置的目标改为可覆盖默认值）。**这是本波第一条真阻断。**
3. **`PIPEFAIL-SIGPIPE`** ❌ `undeclared_hit=1`｜`SITE verdict=SAFE file=verify-all.sh line=423 kind=head consumer=unused`（`grep -E … | head`）⇒ 需在剔除集里逐条声明或改写该行。**未修**（`verify-all.sh:423` 是历史行；本波只改了下半部 ⇒ 该红的**触发条件**需查清：很可能是文件集/站点数变化后原声明失配）。
4. **`PREREG-FOUR-REQ`** ❌ `PREREG4=FAIL files=59 pass=1 fail=1 na=19 out_of_scope=38` ⇒ 我的 `docs/WAVE78-PREREGISTRATION.md` 未过四要件检查（**本波文件数 58→59**）。**未修**（需按判定器口径补齐；`fail=1` 就是本件）。
5. **`PROC-PATTERN-GUARD`** ❌ `reason=missing-self-exclusion` ⇒ 本波新件里有"按模式匹配进程"的写法缺**自排除声明**（候选：`display-lease.sh`／`display-lease-gate.sh`／`appbar-startup-check.sh`）。**未修**。

## §3 本波现场发现（**都在链条里被自己咬住**）
- 🆕 **构建路径缺陷**：`src/WpfGfx.Linux.Native/Makefile` 的 `SRCS` **不含 `win32_oem.c`**（真构建入口是 `build-shim.sh`，其 `SRCS` 含 10 源）。`~/w182a/landing.sh` 的构建步给出 `b5f138f8fefcf4b2`（**`SHAppBarMessage` = 0**）；改用 `build-shim.sh` 重建后 `e8127a3d7128d417`（**1**）。⇒ **凡改 native 源，必须走 `build-shim.sh` 并复核符号**（否则产品改动**静默无效**）。
- 🆕 **`t17` 的重指向改坏了两个"守卫值"**：`~/w182a/landing.sh` 的 `FORBIDDEN` 与 `~/w183a/landing.sh` 的 `R_DEFAULT` 原义是**当时的权威树**（用于"禁止写权威树"的自证），被 `t17` 的"全树可执行默认值"扫成 `$N` ⇒ 语义**反转**（变成"禁止写 `$N`"）⇒ 两包**拒跑**。本波**恢复原字面量语义 ＋ 加覆盖点**（`W78_FORBIDDEN`／`W78_R_DEFAULT`）。⇒ **口径句**：**"路径既能当默认值、也能当守卫值：重指向前必须先看它是**谁**在用；把守卫值一并重指向＝把护栏反转成路障。"**
- 🆕 **`W181A` 的"四处同趟落"少了一处**：`VERIFYALL-STEP-NAMES` 未追加 `APPBAR-STARTUP` ⇒ `VERIFYALL_SELF=FAIL decl-self-inconsistent(DECL=51 但列了 50 个名字)`；本波补齐 ⇒ `PASS`。
- 🆕 **落地器锚点陈旧**（正常摩擦）：`~/w181a/w7x/landing.sh` 把 `boundary-decl-check.sh` 当覆盖面链尾，而 `#77` 已在其后追加 6 行 ⇒ 首趟 `coverage-anchor hits=0` ⇒ **按设计回滚、未留半落地态**；改为**动态取链尾**后 APPLIED。
- ⚠️ **`§追加 2.3` 与现场不符**：契约说"主控已把 `0745` 的 `E1+E2` 装进活冻结器（`6bf3c5c77eee8dd8` → `f9fb7bcac0353a61`）"，但**现取活件 `6bf3c5c77eee8dd8`、`grep -c check_record_forms` = 0**（`t18` 亦报"已回退且可逆"）⇒ **写前自检当前不在位**。本波仍按"带齐 7 种机读形态"写了 `w78` 模板（**防御性**），并把 `GENS['#78']` 装进活件（`6bf3c5c77eee8dd8` → **`389c2c0b196808ed`**，版本档 `versions/w27-freeze.py.w78-6bf3c5c77eee8dd8`）。
- ⚠️ **`#77` 的 `provider` 位移延续**：`t17` 的 F6 把副本刷成权威 ⇒ 在册九位 `provider` 与现场不再相同；本波在 `GENS['#78']` 的 `allow_changed` 里**显式含 `provider` 并逐位归因**（`4041df9a704abfed` → `609192a419d125f2`），`wf-freeze` 三档牙现读 `PASS`。

## §4 显式延期（契约允许；**不静默丢掉**）
1. **根级条目白名单牙**（取代窄形态 `[9] rootprops`）—— **延期**。理由：本波已含**两处产品改动**（`TASK-0747` ＋ `D-G147`）＋ 三件装置/牙 ＋ 整波链，且链条已被 5 处红阻断。**下一步设计**（照主控 §追加 1.1 逐条）：声明根级允许清单（从 `#76` 冻结树根条目现取 ＋ 移植面 ＋ fork 治理件）；断言「`git ls-files` 根级 ⊆ 清单」∧「工作树根级 ⊆ 清单」；超限逐条点名；机读行印判定路径与来源（`git ls-files` vs `test -e`）；两极化：放回 `.editorconfig`／`Directory.Build.props`／`NuGet.config` 任一 ⇒ 必红；接线在 `IN_FP_0` 之前。
2. **「交付 ⊆ 接线」＋「接线 ⟹ 真判」牙** —— **延期**，同上。设计要点照 §追加 1.2（A/B 两方向、具名 reason 黑白名单、合法 `NOINFO` 不误报、反向验证）。
3. `0744-FU` 的 `verify-all` **未新增 `run_step`**（`PROTO-ATTR` 步已存在 ⇒ 其落地器的插入动作会造成**重名**）；改为**载荷替换 ＋ 覆盖面 ＋3**（`214→217`），`PROTO_ATTR_GATE=PASS examined=18 posctl=2/2` 复跑通过。**如实声明**：这偏离了该包 `landing.sh` 的计划形态（`51→52` 步），理由与代价已写在此。

## §5 我推翻了哪句话
1. **「`0745` 的写前自检已装进活冻结器」** —— 现读 **未装**（`check_record_forms`=0；`t18` 同判）。
2. **「仓外可执行默认值一族已清干净」**（`t17` 自报）—— `t18` 已报 4 处残留，本波**再加一类**：**守卫值被误当默认值重指向**（两个包因此拒跑）。
3. **「改 native 源就会生效」** —— `Makefile` 的 `SRCS` 不含 `win32_oem.c`／某些构建路径链旧对象 ⇒ **产品改动可静默无效**（本波实测 `SHAppBarMessage` 从 0 → 1 只在 `build-shim.sh` 之后）。
4. **「`W181A` 四处声明同趟落」** —— 少 `VERIFYALL-STEP-NAMES` 一处（`VERIFYALL_SELF` 当场 `FAIL`）。
5. **`t17` 的账**：两处"守卫值"改动属其射程缺口（本波已回修）。

## §6 边界与 `NOINFO`
`D-G147` 的"工作区事实"是**近似**（包内注释已声明）｜`0744-FU` 的真腿**未在本波复跑**（`~/w184a` 的腿在车道目录，本波只落载荷）｜`X-CENSUS` 在本波链前基线**未取**（契约要求；缺口如实报）｜`PRODUCT-ENTRY` 的装置目标来源未追到底（只钉到"旧路径存在于构建中间物"）。

---

# §7 收口链逐格读数（**冻结 → 冻后两趟 → 推送**；全部现取；车道 `waveman`／`t8`）

> 本节取代文首"**未冻结 · 未推送**"字样：`#78` **已冻结**（`FREEZE_RC=0`）并**已推送**（`f4c93e5`）。
> 复核用 `bash build/MilBridge/tools/defect-registry-check.sh` 等**逐件可复算**；本节的**主控侧读数**与**我复算的读数**分开标注。

## §7.0 世代头与推送头
| 项 | 值 |
|---|---|
| 世代 | `#78` |
| 基线件 | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`｜`sha16` **`d60b414d5e99cf72`** |
| `docs/CURRENT-STATE.md:9` | `> BASELINE-FROZEN gen=#78 sha16=d60b414d5e99cf72 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` |
| 冻前备份（冻结器自做） | `~/w186a/w78/w78freeze/w78freeze/B.pre-freeze.#78.bak`（`e3ebc811641bd467`，`nlink=1`，逐字节==写前现场） |
| 推送提交 | `f4c93e521945373b2461dd2f378c92a5a2ff4633`（本地==远端；`3c302ce..f4c93e5`） |
| 两哨兵 | `cmp` **IDENTICAL**（九位 ＋ `BASELINE_SHA16=d60b414d5e99cf72`，见 §7.8） |

## §7.1 五处红：修前（首趟 `gate1` 原文）→ 修后（冻后 `post2` 现取）
来源：修前 = `~/w185a/w77/logs/w78-gate1-20260926-223252.log`（判词 `步骤通过 46 ❌ 失败 5`／`结论：❌ 失败项：QUOTE-TRAP PRODUCT-ENTRY PIPEFAIL-SIGPIPE PREREG-FOUR-REQ PROC-PATTERN-GUARD`）；修后 = `~/w185a/w77/logs/w78-post2-20260927-112348.log`。

| 牙 | 修前（逐字） | 修后（逐字） |
|---|---|---|
| `QUOTE-TRAP` | `SHELL_QUOTE_TRAP=FAIL reason=dq-backtick traps=4 files=191 sh=102 py=89 diag=76 allow=0` | `SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=191 sh=102 py=89 diag=76 allow=0` |
| `PRODUCT-ENTRY` | `PRODUCT_ENTRY_STEP=NOINFO 拿不到 PEA_SUM 汇总行（rc=2 ⇒ 装置异常/算不出 ⇒ 不是绿）` | `PRODUCT_ENTRY_STEP=PASS 判定例=8/8 判据格=147/147`（装置配置源 `build/MilBridge/tests/ProductEntryArm/{inputs.json,Program.cs}` 的旧路径已修） |
| `PIPEFAIL-SIGPIPE` | `PIPEFAIL_SIGPIPE=FAIL undeclared_hit=1 decl_stale=0 files=102 sites=90 hit=1 low=7 diag=3 safe=79 runs=12` | `PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=102 sites=88 hit=0 low=7 diag=3 safe=78` |
| `PREREG-FOUR-REQ` | `PREREG4=FAIL files=59 pass=1 fail=1 na=19 skip=0 noinfo=0 out_of_scope=38` | `PREREG4=PASS files=59 pass=1 fail=0 na=20 skip=0 noinfo=0 out_of_scope=38`（判据节标题形态已修） |
| `PROC-PATTERN-GUARD` | `PROC-PATTERN-GUARD` 红（`missing-self-exclusion`，`display-lease.sh:51` 字符串字面量自匹配） | `PROC-PATTERN-GUARD ✅`（`post2` 现取） |

## §7.2 `PTSGAP` 反漂移牙**本波当场咬住本波自己的过期声明**
- 重锚前：`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` 声明 `so16=fc60c34d51fd9247 exports=550`，而权威件已是 `e8127a3d7128d417`／`554` ⇒ 现场红 `DRIFT so16 decl=… live=…`
- 重锚后：`abb55f0152475ac8 → c39e4b900d60c58c`（`PTSGAP=PASS`）；冻后两趟内 `PTSGAP` 仍在绿侧（同趟声明）。
- 意义：这是 `D-G70` 形态的**第三次**实例 —— **产品/接线一动，声明必须同趟跟**；本波是"**牙在数小时内咬住自己的声明**"。

## §7.3 符号臂两极化：反极件 `sha16 8857b251e74851d2`
- 不装符号臂的可复现产物：`~/w186a/w78/so-poly.dUU4/N/bin/libwpfwin32.so` ⇒ `8857b251e74851d2`，**553** 个符号，`nm -D … | grep -c SHAppBarMessage` = **0**
- 装符号臂：`e8127a3d7128d417`，导出 **554**，命中 **1**
- 字节读数：`TASK-0747` 两极化 —— 不装 ⇒ **每启动 `242 B`**；装 ⇒ **`0 B`**（差恰 `−242`）；其余 diag 逐字节相同，诊断档 `3808 → 3629`（差 `179 = 242 − 63`）
- 材料归 `TASK-0752`；**臂映射修序**：先修 `leg.sh` 臂映射，再跑 `DIAG=0/1`。

## §7.4 两链并存与杀灭（**档位更正**：第二链真／第三链从未诞生）
- **第二链（真）**：`PID 1346438` 于 **22:32:52** 由 `:177` 那次粘贴产出，**当时活着**、卡在 `flock -w 3600` 等重活槽（子树 `1346438 → 1792597 heavy-slot.sh → 1792605 flock`）；`23:30:51` `[5b/6]` 失败后**照旧往下跑**（`D-G155`）；`23:44:11` 写出 `rows=5` 的一趟门禁（活链同趟 `rows=6`）。
  **按 PID 杀灭**：`kill -TERM 1792605 1792597 1346438`（最深先；杀前逐 PID 核 cmdline 防 PID 复用），三个 `TERM` 即灭、**未升级 `KILL`**；死亡 **`∈(23:46:06, 23:46:25)`**（两端＝快照写时／杀后普查；取点 `23:46:20`，理由＝死亡发生在这两条命令之间、现取无更细来源）。杀后：`CHAIN_COUNT=1`、零 `Xvfb`/`dotnet`/`slot` 孤儿。
- **第三链（从未诞生）**：`:175` 的 `$L/bin/…` 解析成 `~/w185a/w77/logs/bin/w78-chain.sh`（**不存在**）⇒ sed 失败 ⇒ 链脚本**从未被改**（现取仍 `b978f6094ada4e17`）；`:177` 的 `cd $N` 因 `N` 未绑定而死 ⇒ 打印的 `CHAIN_PID=2413662` 是**立即死掉的子壳**（现取该 PID 不存在）。⇒ **逐字更正**：先前"它会**每次**再生一条链"与由此下的"杀掉继承链"指令**同属一个错误推论**；**真正该杀且已被杀净的只有第二链**。
- `:175-177` 已拆：`b978f6094ada4e17`（177 行）→ **`a6e81897184c4f2e`（174 行）**；备份 `~/w186a/w78/w78freeze/w78-chain.sh.pre-dismantle.bak`（== 改前现场，`D-G126` 通过）；命中数 `sed-i 1→0／bash-n 1→0／nohup 1→0`；`bash -n` OK。
- `D-G153` 判词据此改为：**"曾 fire 一次（22:32:52 产出第二链）；其后各次因路径解析错与 `$N` 未绑定而失败"**。

## §7.5 `DEFREG`：口径限定 ＋ **冻后红 → 主控按纪律 15 重发 → 重跑**
- **口径限定（逐字）**：`DEFREG=PASS declared=182 route_ids=182` 是 `KD`/`CS`/`HO`/`AB`/`KRJ`/`KRF`/`KRP` **七件 route 口径**下的数；本波新增 `D-G149`–`D-G152` **只登记在 `docs/ROUTES.md`**（该件**不是** route 键；`ALLKEYS='KD CS HO AB KRJ KRF KRP'`）⇒ 四号非 declared 集成员、规则④无从触发。**重发生成不抬数**（现取：重生成与在册件逐字节相同，`sha16 f17c41239ffa1408`／190 行／182 条 `ID` 行，仅 `# DECL-GEN` 时间戳不同）；本波对在册件的改动**只有时间戳**（`git diff --numstat` 1/1）。
- **冻后红（本波流程缺口，非数据错）**：`DEFREG=FAIL reason=undeclared-id-in-route`（`DEFREG_DECL=n=182 route_ids=198`／`DECLDRIFT=2`），**点名 16 个号**：
  `D-G147`／`D-G149`／`D-G152`／`D-G153`–`D-G157`／`D-G158`／`D-G159`／`D-G160`–`D-G165`，**`route=AB` ＝ 本行基线件自身**（其 `sha16` 已是冻结后的 `d60b414d5e99cf72`）。
  根因：**本记录块（§7.5–§7.12／冻结块 ⑧–⑮）把新编号写进了 `# RE-FROZEN #78` 块 ⇒ 冻结一落，冻结块本身成了 `DEFREG` 的路由输入**，而在册件仍是 `09-26 23:00` 那一版。
  **只读复现**：`DRC_DECL=<旧在册件> bash build/MilBridge/tools/defect-registry-check.sh` ⇒ **同一条 `FAIL` ＋ 同一份 16 号点名**（rc=1）。
- **修（具名记账）**：**主控在冻后按纪律 15 重发在册件** `build/MilBridge/tools/defect-registry-declared.tsv`：**`e63de8664240d736`（191 行／182 号）→ `95c80adb49ffc02c`（207 行／198 号）**；备份 `~/w-freeze-backup/declared.tsv.pre-reemit-e63de8664240d736`（`D-G126` 断言过）；`--emit` 走 temp＋rename。**修后**：`DEFREG=PASS declared=198 route_ids=198`，`DECLDRIFT=0`（我独立复跑同值）。
  **安全性**：在册件**不在**覆盖面（`close-wave.sh` 命中 **0**；活清单命中 **0**）⇒ **`inputs_fp` 逐位未变** `a3bded5d…`（`n=217`）⇒ 推送牙前提仍成立。
- **两趟红的读数（只作中间态）**：`post1`（`095551`，`10:10:21`，`sha16 93e2200bd902cc23`，`50 ❌ 1`）／`post2`（`101021`，`10:25:07`，`674c9d7cce5ec87c`，`50 ❌ 1`）；红的标记保件 `crisis-20260926/POST12.done.RED-1025.bak`。
- **口径句／牙草案**：**「冻结记录里出现的新编号必须同趟进 `declared.tsv`，否则冻后 `DEFREG` 必红」**；牙 `freeze-block-ids-declared-teeth`（抽块内全部 `D-G\d+` ⊆ declared，缺 ⇒ 红并逐条点名；两极化：写入未声明号 ⇒ 必红／正常 ⇒ 绿）⇒ 与「`ROUTES.md` 的编号 ⊆ declared」**互为姊妹**（都是"**编号的载体换了，读者没跟上**"）。**如实划界**：冻前 `gate1`/`pre` 都是 `51/0` ⇒ 属**流程缺口**。

## §7.6 冻结输入同一性（`D-G157`／`D-G158`）：判词 `PASS` ＋ 载体
- `PRELOG`（**本代 `TS=20260926-234150`**）：`~/w185a/w77/logs/w78-pre-20260926-234150.log`｜`mtime 2026-09-27 01:27:02`｜`20301B`｜`232 行`｜`sha16 4945e11f073c044c`｜判词 `步骤通过 51 ❌ 失败 0`／`结论：✅ 全部通过`
- 下限 **`FLOOR = max(静链死亡, 本代 wave 结束)`**：**强锚** ＝ `w78-wave-20260926-234150.log` 的 `mtime 2026-09-27 00:37:31`；**弱锚** ＝ 静链死亡 `∈(23:46:06,23:46:25)`（次要件）。**载体**：`~/w186a/w78/logs/w78-input-identity.log`（同趟现取；`PRELOG` 身份"不许内联 ≠ 可以不记"）
- 两档口径：`EXPECT_CHAIN=running`（链在跑：`CHAIN_COUNT=1` ∧ 活 PID 在场）／`exited`（接手重跑：`CHAIN_COUNT=0` ∧ `WRITER_COUNT=0`）；**枚举显式排除 `$$` 与全祖先链**。接手档判词：**`W78_INPUT_IDENTITY=PASS`**。

## §7.7 记录模板三条审计 ＋ 我自己的口径错（如实）
- 每次编辑后重审：**占位符 21/21 ∈ 冻结器 `fmt` 表**（否则 `fill()` 当场崩）；**七形态计数改前＝改后**（`九位`2／`BRIDGE_SRC_FP`1／`inputs_fp`1／`COLUMN-FLOOR`2／`COLUMN-CORPUS`1／`ARM-LOG-SHA`5／`RE-FROZEN`1）；段标记各 1；**新增文本对七条 `prev_*` 正则零命中**（否则把"命中数==1"顶成 2 ⇒ 拒冻）。
- 我踩并自纠的口径错：① 我把 `RE-FROZEN` 字样写进记录 ⇒ **计数 1→2** ⇒ 被**我自己的不变量**抓住后改写措辞 ⇒ 口径句**「编辑新文本时必须重审『机器形态计数』—— 新文本本身可能命中被判据读的正则」**（与 `0745` 那次同族，两次实体教训）；② `grep -F '^cd $N …'`（`^` 在 `-F` 下成字面量）⇒ 命中数断言**假红** ⇒ **断言失败即零写**；③ **整块 grep 数五键得 2**，而冻结器只在**九位行内**数 ⇒ 按**从源码取出的 `_NINE_HDR`** 精确复核得 **1/1/1/1/1 ＋ 1 ＋ 1 ⇒ 完全合规**（`#79` 不会被拒）⇒ 口径句**「数命中数必须用判据自己的抽取口径（含作用域），不许用『整块 grep』代替」**，与 `D-G119` 同族 ⇒ 牙里把作用域做成可核字段 `SCOPE=nine-line|block|whole-file`。

## §7.8 推送四腿 ＋ 远端与哨兵（现取）
```
PUSH_LIST_GAP=PASS（覆盖面里每一件脏件都在推送清单上）
staged=7 ；COMMIT=f4c93e5 ；FF=yes（remote 3c302ce → local f4c93e5）
INFP_AT_PUSH=a3bded5d3c3e384cc8621e3da5401ccc99e8d16f2e4be11577463034c77ceb94
FROZEN_INFP =a3bded5d3c3e384cc8621e3da5401ccc99e8d16f2e4be11577463034c77ceb94  INFP_FREEZE_PUSH_MATCH=PASS
INFP_RULER2=SAME_SOURCE_AGREE（**同源**，非独立互证：两件尺子共用同一 sed 抽取式／同一 tail 串／同一两处 replace／同一 digest 双跳；冻结器也 source 同一函数）
INFP_COUNT_RULER=PASS（live=217 == 声明常数 [42] --expect 217；**唯一真独立**的量：读另一件的陈述常数）
REMOTE_PER_COMMIT=PASS n=4（d2dec07..f4c93e5 逐笔在场：3c302ce／192f54e／3b5af06／f4c93e5）
PORCELAIN=0 ｜ SENTINELS-IDENTICAL
```
- **两哨兵九位与 `BASELINE_SHA16`**：`SHA=4e25e4b27d4d5ae1 FP=d697b1e10ff48881 PC=f9d6cd3e9647a20e PF=8190809cc16426e2 WB=ff04a83e07e0def9 WIN32SHIM=e8127a3d7128d417 HBTL=921ba9c65e9fb3be WIC=f7b3026c8c019be2 PROVIDER=a00895e8158189b9 DWF=9a8975db981cee8f BASELINE_SHA16=d60b414d5e99cf72`（两处 `cmp` 逐字节相同）。
- **`porcelain` 推后现读 ＝ 0（推送前 7）的解释**：推送前那 7 件（`build/.applocal-selftest.log`／`build/MilBridge/tools/defect-registry-declared.tsv`／`build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt`／`build/PresentationFramework.Linux/ARTIFACT-SRC-FP.txt`／`build/wave-audit.log`／`docs/CURRENT-STATE.md`／`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`）**全在推送清单上**，逐径 `git add` 后进 `f4c93e5` ⇒ 它们从 `porcelain` 里消失；**工作树字节未变**（`git diff --stat HEAD` 为空）。
- **`192f54e`（28 件）与 `3b5af06`（2 件）两笔意外提交**：由我脚本两个 bug 产出（`--check-only` 早退排在 `git add`/`commit` 之后；干跑桩只换 `git push`）、**内容全真**、经主控裁定**保留、未重写历史**；已**逐笔核到远端**（见上 `n=4`，真数据含"远端已有 `3c302ce`／缺 `192f54e`、`3b5af06`"的混合集实证）。
- **`d2dec07..HEAD` 射程**：含 `t17` 那笔 `3c302ce` 与上述两笔误提交 ＋ 本笔 `f4c93e5` ⇒ **不许只核"我自己那一笔"**。
- **主控侧读数（具名，非我复算）**：两趟日志 `sha16 8ffb2876d3ff55a2`／`7c221cab09a91283`、`mtime 11:23:48`／`11:38:21`（皆晚于冻结时刻 `09:55:11`）、`INFP_AT_PUSH` 用仓内权威重算器现取 —— 与我的复算**同值**。
- **主控自伤（供其归档）**：其手搓量法（抽 `fp_inputs()` 后 `sha256sum`）得 `be43f2016db4a880…` ⇒ 与官方件口径不同（该函数只吐路径表）⇒ 结论**「两个读数不一致时先怀疑自己的量法」**（`D-G38` 镜像），未据此下过红判。

## §7.9 未落地项（**待下一趟，各自带 freeze**）
1. `TASK-0745`（本代记录带齐下一代机读形态）**落地**（本波交**补丁**；活冻结器 `check_record_forms`=0 现读**未装**）。
2. 冻结器侧两腿 `--prelog-ts`／`--prelog-epoch-floor`（与调用方"按本代 `TS` 取件"**同趟**；调用方改 `build/close-wave.sh` ⇒ **覆盖件** ⇒ 必须排推送之后）。
3. 成员表锚行（`# COVERAGE-MEMBERS-SHA16` ＋ `members.<gen>.tsv` 入仓）作为 `coverage-shrink-declaration-teeth`（`D-G165`，跨代差集）与 `coverage-members-anchor-teeth`（同代锚行↔本体）的**前一代前置**。
4. `D-G153` 牙 `chain-script-tail-teeth`（可执行尾部为空／禁 `nohup…自身&`／顶层语句白名单；反极性：带 `:177` 形态的副本 ⇒ 必红）；`D-G163`（只读／干跑分支必须先于任何写动作 `exit`）；`D-G164`（脏覆盖件必须都在推送清单上）；`D-G159` 的 `path-transition-withdraw-teeth`。
5. `D-G156` 的 `lane-path-ownership-teeth`（链的 `L` 由脚本自身路径推导、禁跨车道字面量）＋ **同目录四世代碎片处置**（先保件后清；`w77-*` 只声明不删）。
6. `t19` 五处同族残留／`t16` 根 props 牙／`t7` 冻后项 —— 各自随下一次冻结走。
7. 冻结块内的**新编号同趟进 `declared.tsv`** 那条牙（§7.5）。

## §7.10 §6 的一条更正（现取推翻）
§6 写「`X-CENSUS` 在本波链前基线**未取**」——**已过时**：冻后两趟现取 `X_CENSUS=PASS leaks=0 new_orphan_sock=0 base_live=0 now_live=1 base_socks=2 now_socks=3`，`X_CENSUS_SNAPSHOT=PASS path=/tmp/w75-xcensus.mcYHsf lines=3 at=2026-09-27T11:23:49` ⇒ 基线**已取且在册**。

