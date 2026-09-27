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


---

# §8 **dated 更正**（2026-09-27，waveman／t21）：§1 表内 provider 归因**不成立**
**原文（保留，一字不改）**：见 §1 表格「`#77` 的 `provider` 位移延续 …（`4041df9a704abfed` → `609192a419d125f2`）」。
**更正（现取可复算）**：① 现树权威件 `build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll` ＝ **`a00895e8158189b9`**；② `find build -name 'DirectWrite.Linux.Provider.dll'` 现取 **58 份**副本、其中 **45 份**同此值，**`609192a419d125f2` 命中 0**；③ 同块 **6 条** `BASELINE tier=` 行与**两哨兵**均写 `a00895e8158189b9`。
⇒ **同块内两种载体矛盾**：九位行（`ACCEPTANCE-BASELINE.md:66`）写 `609192a419d125f2`（**陈旧手写值**）。
**`609192a419d125f2` 的定性（主控更正，现取复核）**：**不是"上一代值"** —— `#77` 块九位行那一格是 **`1f9511a7ef395bfe`**；它是**模板写死那一刻的现取值**（`t17` 的 F6 之后），`#78` 波 `00:36` 重建后才变 `a00895e8158189b9`。
**根因**：`GENS` 核验键表**不含 `provider`** ⇒ 冻结器从未核过这位（`D-G149` 同族）。
**复现**：`sha256sum <provider> | cut -c1-16`｜`find build -name 'DirectWrite.Linux.Provider.dll' | xargs sha256sum | cut -c1-16,60- | sort | uniq -c | sort -rn`｜`grep -m1 -oE '`provider` `[0-9a-f]{16}`' samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`｜`grep -m1 '^PROVIDER=' /tmp/bridge-frozen.flag`
**边界**：不影响其余任何 `#78` 读数；**`#78` 块按主控裁定不改**。

# §9 `#78` 在册未闭的**四组成对读数**（t21 真跑：实际命令＋臂来源件与 sha16＋原始读数行）
## 9.1 `TASK-0752` `−242` 三臂两极化（`~/w79c/ledger-0752.tsv` `sha16 2c07698fb60947de`）
**原位缺陷**：`~/w181a/w7x/bin/leg.sh`（`sha16 8a7229b963b9370d`）的 `absent` 臂指向**活树已装符号件**（`e8127a3d7128d417`／`shappbar=1`）＝**语义反转**。**修正处**：`~/w79c/bin/leg79c.sh`（只改 3 行：根 `W`／`absent`／`ret0`，另加 `baseold`），**原件未动**。
**实际命令**：`bash ~/w79c/bin/leg79c.sh <tag> <arm> 30 <DIAG>`（`WDISP=:232`，自起自收 Xvfb，只按 PID）。
| 趟 | 臂件 sha16 | sym/shappbar | DIAG | APP_TEXT_BYTES | EPNF | APPBAR_DIAG_N |
|---|---|---|---|---|---|---|
| `C79-baseold-diag0/1` | `fc60c34d51fd9247` | 550/0 | 0/1 | **242 / 3808** | 1 | 0 |
| `C79-absent-diag0/1` | **`8857b251e74851d2`** | **553/0** | 0/1 | **357 / 3923** | 1 | 0 |
| `C79-ret0-diag0/1` | `efb087b5c7c33eb2` | 551/1 | 0/1 | **0 / 3629** | 0 | 0/1 |
**结论**：在册值逐位复现（旧件 242／3808；`ret0` 0／3629）⇒ 装置未变；判据要求的**新 absent 件**＝**357／3923**；与旧件恒差 **+115**（件身份：553 vs 550 symbols）⇒ 非树/判据漂移。`ret0` 臂 3808−3629＝**179＝242−63** ✔。判别力：EPNF 1/0、APPBAR_DIAG_N 0/1。
**与 `verifier` 的反事实件不矛盾**（等长改名件 357B/1 行、落仓件 115B/0 行、原始件 242B/1 行 ⇒ 差恰 +242）：件不同源 ⇒ 差值不同（+115 vs +242）；**只引用不复跑**。

## 9.2 `TASK-0753` `D-G147` 工作区事实来源 ↔ `ABM_GETTASKBARPOS` 消费者
**实际命令**：`bash ~/w182a/legs.sh <so> <tag> <out> 20`（自起 `Xvfb :238`；三腿 absent／set(0,0,1280,968)／malformed(n=2)；holder 按 PID 收）
**正向腿（现树权威件 `e8127a3d7128d417`）**：
```
LEG=absent    G147=PASS source=fallback-screen    reason=fallback-declared                    rcWork_eq_rcMonitor=1 prop_present=0 prop_n=0
LEG=set       G147=PASS source=net-workarea       reason=rcWork==_NET_WORKAREA(declared=net-workarea) rcWork_eq_rcMonitor=0 prop_present=1 prop_n=4
LEG=malformed G147=PASS source=fallback-malformed reason=fallback-declared                    rcWork_eq_rcMonitor=1 prop_present=0 prop_n=2
（每腿 XPROP_BEFORE==XPROP_AFTER 同值 ⇒ 属性全程在场）
```
**反向腿（修前件 `fc60c34d51fd9247`）**：见下（`~/w79c/logs/0753b.log`）
  XPROP_BEFORE=_NET_WORKAREA:  not found.
  XPROP_AFTER=_NET_WORKAREA:  not found.
  G147=FAIL source=(none) reason=no-declared-source(silent-identity) rcWork_eq_rcMonitor=1 prop_present=0 prop_n=0
  LEG=absent rc=1
  XPROP_BEFORE=_NET_WORKAREA(CARDINAL) = 0, 0, 1280, 968
  XPROP_AFTER=_NET_WORKAREA(CARDINAL) = 0, 0, 1280, 968
  G147=FAIL source=(none) reason=rcWork!=_NET_WORKAREA rcWork_eq_rcMonitor=1 prop_present=1 prop_n=4
  LEG=set rc=1
  XPROP_BEFORE=_NET_WORKAREA(CARDINAL) = 0, 0
  XPROP_AFTER=_NET_WORKAREA(CARDINAL) = 0, 0
  G147=FAIL source=(none) reason=no-declared-source(silent-identity) rcWork_eq_rcMonitor=1 prop_present=0 prop_n=2
  LEG=malformed rc=1

## 9.3 `TASK-0754` 显示号租借两极化 ＋ `X-CENSUS`
**实际命令**：`bash build/MilBridge/tools/display-lease-gate.sh`（`at=2026-09-27T12:16:06+08:00`）
```
DISPLAY_LEASE_GATE=PASS static=3/3 dynamic=11/11 examined=14 dev_sha16=b12fc3c0fd3d352f
  D4a-external-occupant-refused OK ｜ DISPLAY_LEASE=FAIL reason=occupied-without-lease display=:239 occupants=2 race=post-claim
  D4b-live-lease-named          OK ｜ DISPLAY_LEASE=FAIL reason=held-by-live-pid display=:239 holder_pid=… holder_lane=otherlane
  D5-socket-slot-refused        OK ｜ FIXTURE_TEARDOWN socket=/tmp/.X11-unix/X236 present=no
  FIXTURE_TEARDOWN sleep_pid=… x_pid=… sleep_live=0 x_live=0   ⇒ 「起过 ⇒ 收尾后无进程」✔；「没起过 ⇒ 一个都不杀」由 static 3/3 覆盖
```
**`X-CENSUS`**：冻后两趟现取 `X_CENSUS=PASS leaks=0 new_orphan_sock=0 base_live=0 now_live=1 base_socks=2 now_socks=3` ＋ `X_CENSUS_SNAPSHOT=PASS path=/tmp/w75-xcensus.mcYHsf at=2026-09-27T11:23:49`；**链前基线仍缺 ⇒ `NOINFO reason=pre-chain-baseline-absent`**（要变可判＝`verify-all` 链首补一次快照）。
**⚠️ 同趟现取的仪器缺陷（具名）**：`display-lease.sh:413` stderr 现 `local: 只能在函数中使用`；`reason=pool-exhausted` 用于"整池在白名单外"（更准确应为 `pool-out-of-whitelist`）⇒ 两条归 `t24`／下一趟。

## 9.4 `TASK-0755` `0744-FU` 真腿（`sock=` 随行 ＋ 「符号级 hook 恒瞎」复证）
**实际命令**：`bash build/MilBridge/tools/proto-attribution-check.sh --cases build/MilBridge/tools/proto-attribution-cases.tsv --expect 18`（`at=2026-09-27T12:16:06+08:00`）
```
PROTO_ATTR_GATE=PASS examined=18 mismatch=0 bad_expect=0 posctl=2/2 cut_and_pair=1
N-NOPAIR  NEG  NOT_ATTRIBUTED reason=no-server-side-pair sock_id=present ident=absent sym_call=none SYM_ONLY=never-sufficient
N-CUTNORQ NEG  NOINFO         reason=cut-without-request sock_id=present ident=absent sym_call=XResizeWindow
E-CUTPAIR EDGE ATTRIBUTED     reason=paired-server-event   sock_id=present ident=absent cn_pair=push:1280x1024@+4.7
```
⇒ **`sock=` 随行打印在位**（逐行 `sock_id=present`）；**「符号级 hook 恒瞎」复证**＝`SYM_ONLY=never-sufficient` ∧ `sym_call=none` 而判定仍 `NOT_ATTRIBUTED reason=no-server-side-pair` ✔；`posctl=2/2`。

## 9.5 台账落仓的**硬约束（未执行，具名原因）**
`appbar-startup-ledger.tsv` 现取 **6 腿**，而 `verify-all.sh:1188` 写死 **`--expect-legs 6`** ⇒ 加行即破声明常数（`delta=+N`）。按硬规则 ④（该两处不该由我动）**未加行**，三臂读数落在 §9.1；**下一步最小可执行动作**＝同趟改 `verify-all.sh:1188` `--expect-legs 6→12`（或替换原 6 腿）＋ 台账同步。

# §10 两趟差异的**机器分类（两域分列）** ＋ `ENV-CLASS` 清单 ＋ 分类器判别力
**抽取域**：域① = `^ *· 自报口径 ` 行；域② = 判词行（`步骤通过`／`结论：`）。语料＝冻后两趟 `110835`／`112348`。
**规则**：归一化时间戳 ＋ **只归一化白名单键（`outdir|dir|log|path|file|worst_path|SNAPSHOT`）且值以 `/` 开头**的路径；再比 → 相等＝**标签/环境类**，否则＝**读数类**。（原规则曾含 `(…)=[^ |]*`＋`-<6位数字>` ⇒ 可能吃掉 `avail_gb=97` 类数值字段，**已收紧**；收紧后复算域① 仍 **LABEL=5／READING=4**。）
```
域①（91 vs 91）：原始差异 18 行＝9 对 ＝ 标签类 5 对 ＋ 读数类 4 对
  标签类：TLINE_GATE／COLUMN_FLOOR_SELFREPORT／FRAMEPRESENCE／THIRDPARTY_BUILD／THIRDPARTY_IMAGE
  读数类：THIRDPARTY frames=42↔43｜DISK_HEADROOM avail_gb=97↔96・avail_kb=101822300↔100996644｜R_GATE mem_mb=5778↔5492｜ALIAS wall_s=5.46↔5.61
域②（2 vs 2）：归一化后 **零差异**
```
**`ENV-CLASS` 具名清单**（`~/w79c/envclass-and-classifier.md` `sha16 8a6a43c5b182e643`）：上 4 对逐条注"环境/负载驱动／**不参与任何判据**（两趟皆 `51 ❌ 0`）"。
**合格线**：「**除本清单逐条列出的环境类读数外，读数类差异必须为 0**」；清单之外出现读数类差异 ⇒ **红**（点名字段与两侧值）。
**判别力（自造腿，真跑）**：正极性 `judged_min=615→616` ⇒ `READING=1` 点名 `GATE_COLUMN`；负极性 `outdir=…-111025→…-999999` ⇒ `LABEL=1`。
**两域结论不同不是矛盾；没写域才是缺陷。**

---

## §11 `#78` 块 `provider` 错值：**dated 更正**（`t25`；本节为**纯追加**，§1–§10 原文一字未动）

> **本节为什么存在**：`build/MilBridge/V78-verify-report.md`（`t9`／`verifier`，整份 `01a5ca4a716d5921`）的 finding #1 与**主控现取**两条独立通道同结论：`#78` 冻结块九位行的 `provider` 与**同块** `BASELINE tier=` 机读行、与**现取值**都不一致（`D-G149` 在 `#78` 的**第二代复发**）。
> **本节落地主控裁定的三格**：**块不改**（§11.1）＋ **dated 更正**（§11.2／§11.3）＋ **下一代写对**（§11.4，模板占位符化）＋ **加牙**（`WFREEZE_BLOCKVALUES` 档④）。
> **追加时刻 = `2026-09-27T13:3x+08:00`**（车道 `scribe`／`t25`；本节所有读数**逐条现场现算**，各自标时刻）。
> **纯追加机器证**：改前快照（`948b1f495e6701e1`／228 行）与本件前缀 `cmp` **逐字节相同**，`diff` **只出 `228a229,…`**（**只有追加命令，零删零改**）。

### §11.1 裁定：`#78` 块**一字节不改** —— 现取 ＋ **四条引用链**（读数时刻 `2026-09-27T13:2x–13:3x+08:00`）

| # | 引用链 | 现取读数（逐条都有机器读者） |
|---|---|---|
| 0 | **件本体** | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` ＝ **`d60b414d5e99cf72`**（全 sha256 `d60b414d5e99cf727f775f5b97678ffee961a0e9317864758644ccc4d371febb`；1,166,396 B／4,459 行） |
| 1 | **冻结日志** | `~/w185a/w77/logs/w78-freeze.log`（`e50eed332d54b3b9`／33 行）`:25` 「基线已重冻为 `#78`；整份 sha16 = `d60b414d5e99cf72`」／`:26` `BASELINESHA=PASS live=d60b414d5e99cf72 decl=d60b414d5e99cf72`／`:30` 「机器行 `gen=#78 sha16=d60b414d5e99cf72` 已对上，核对器 `rc=0`」 |
| 2 | **两趟冻后日志（×2 轮，共 4 份）** | `w78-post1-20260927-095551.log`（`93e2200bd902cc23`／mtime `09-27 10:10:21`）｜`w78-post2-20260927-101021.log`（`674c9d7cce5ec87c`／`10:25:07`）｜`w78-post1-20260927-110835.log`（`8ffb2876d3ff55a2`／`11:23:48`）｜`w78-post2-20260927-112348.log`（`7c221cab09a91283`／`11:38:21`）—— **四份逐份** `:51` `BASELINESHA=PASS live=d60b414d5e99cf72 decl=d60b414d5e99cf72`（另 `:88`／`:89` `COLUMN_FLOOR=… base=d60b414d5e99cf72 corpus=0cebc0afd5142fbf`） |
| 3 | **在册哨兵行** | `docs/CURRENT-STATE.md:9` ＝ `> BASELINE-FROZEN gen=#78 sha16=d60b414d5e99cf72 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（现取） |
| 4 | **两份哨兵** | `/tmp/bridge-frozen.flag` ＝ `~/wfp-runs/bridge-frozen.flag`（各 279 B，`cmp` ⇒ **IDENTICAL**；`sha16 7f8e50a9efc1fddf`×2）：`BASELINE=#78`／`BASELINE_SHA16=d60b414d5e99cf72` |

⇒ **就地改写那一格会同时打断 1／2／3／4 四条引用链**，而「**一份变更集只许一次冻结**」是硬纪律；
⇒ 且**那条错值本身是证据**（它是「**模板写死字面量 ⇒ 跨代必陈旧 ∧ 三道核全瞎**」这条缺陷的**原件**）；
⇒ **正确形态 = dated 更正（原文保留）＋ 下一代写对（占位符化）＋ 加牙使它不可能再犯**。
⇒ **逐字写明（不许含糊）**：**`#79` 冻结之前，远端在册件里确实带着这条已知错的 `provider`** —— 已登记 **`D-G166`** ＋ 本条 dated 更正；位移声明件 `build/MilBridge/blockvalues-shift.tsv:14`（`registered=D-G166`，逐条上屏、**声明不等于放行**）。

### §11.2 `provider` 的**三代**口径（防止把"写死那一刻的现取值"说成"上一代值"）

| 处 | 值（现取） | 它**是**什么 |
|---|---|---|
| `#77` 块九位行（基线件 `:99`） | `1f9511a7ef395bfe` | 那一代的真值（＝ `#76` 块的值 ⇒ 对 `#77` 而言**确实是"上一代值"**） |
| **`#78` 块九位行**（基线件 `:66`） | **`609192a419d125f2`** | **模板 `~/w186a/w78/w78freeze/w78-record.txt:67` 写死那一刻的现取值**（`t17` 的 F6「副本刷成权威」**之后**）—— **既不是** `#77` 块里的值（那格是 `1f9511a7ef395bfe`）、**也不是**本代现取值 |
| 同块 `BASELINE tier=` 机读行（**6 条**）× 盘上两条权威路径 × 两哨兵 | `a00895e8158189b9` | `#78` 整波重建后的**本代真值** |
| `wic_shim` 三处（`#76`／`#77`／`#78` 块） | `f7b3026c8c019be2`（逐位相同） | **同一族的哑弹**：那个字面量**今天恰好写对** ⇒ **不许只修 `provider` 一格** |

⇒ **`609192a419d125f2` 不许说成「上一代值」**（主控更正，逐字采纳）：它**从未是任何一代的"上一代块值"**，它是**字面量写死那一刻的现取值**；`#78` 整波重建 `provider` 之后它**静默过期**。
⇒ 该值在现树 `*.dll`／`*.so` **有界全量扫描命中 0**（读数见 `D-G166` 段；本条**只引用不重算**）。

### §11.3 根因与处置（现取；`D-G166`／`D-G149` 第二代）

- **根因（现取）**：模板 `~/w186a/w78/w78freeze/w78-record.txt`（**`e7abc00e76f08338`**／75 行，**只读引用、一字未改**）九位行里 `provider`／`wic_shim` 是**硬编码字面量**，同行其余七位是占位符；改前的 `~/w21-verify/w27-freeze.py`（`fe479b88a852e482`）`fmt` 字典**没有这两个键** ⇒ `fill()` **只抓「用了没定义的占位符」**，**结构上抓不到「写死了本应现取的值」**；`_PREV_SRC` 的 7 键与 `_TIER_MAP` 的 5 位都不含这两个键 ⇒ **三道核全盲**。
- **处置形态（主控逐字裁定）**：**不改冻结块** ＋ **dated 更正（本节）** ＋ **下一代写对（§11.4）** ＋ **加牙**（`build/MilBridge/tools/wave-freeze-consistency-check.py` 第四档 `WFREEZE_BLOCKVALUES`：九位行 ∧ `BASELINE tier=` 行 ∧ **现取** 三方对拍 ＋ 模板裸 hex 白名单）。

### §11.4 **下一代写对**：记录模板占位符化（仓外件；**主控已采纳为 canonical**）

- **件**：`~/w186a/w79/w79freeze/w79-record.txt` ＝ sha16 **`52571ef51842467d`**／75 行／27,021 B／`%h=1`（现取）。主控已把 `GENS['#79']` 的模板路径**重指到它**（冻结器 `56f17ff47d3c04c3` → **`b3115b9680b0039f`**，主控现取；本件**未动**任何冻结器）。
- **派生方式（纪律 17：逐处断言 `HITS==1`）**：由 `#78` 模板逐条替换 ——
  ① `` `provider` `609192a419d125f2` `` → `` `provider` `{PRV}` ``（`HITS=1`）；
  ② `` `wic_shim` `f7b3026c8c019be2` `` → `` `wic_shim` `{WIC}` ``（`HITS=1`）；
  ③ 第 68 行（相对位移句）追加 **`` `provider` `{PRV_PREV}` → `{PRV}`／`wic_shim` `{WIC_PREV}` → `{WIC}` ``**，并注明「**`#79` 起由 `fmt` 键现取** —— 此前是写死的字面量，见 `D-G166`／`D-G149` 第二代」（`HITS=1`）。
- **静态核对（现取）**：活冻结器 `~/w21-verify/w27-freeze.py`（**`b7912a4a75d36c18`**）`fmt` 字典 **31 键**；模板占位符 **39 处／25 个去重**，**未定义 = 0**；四键 `PRV`／`WIC`／`PRV_PREV`／`WIC_PREV` **逐键在位**（冻结器 `:1617-1618`，值取自其已现算的 `now` 字典，**不是外部输入**）。
- **`fill()` 冒烟（复刻其正则 ＋ 两条 `assert`）**：**PASS**（全部占位符可填、无残留）；把 `{PRV}` 故意拼错成 `{PRV2}` ⇒ **当场红**（`assert` 命中）⇒ **该检查有检测力**。
- **`#78` 那份模板只读未变**：`e7abc00e76f08338`（现取，与开工读数逐位相同）。

### §11.5 模板**裸 16 位 hex 扫描**：逐条点名（只允许**显式声明的常数字段**）

- 命令：`grep -aoE '[0-9a-f]{16}' ~/w186a/w79/w79freeze/w79-record.txt` ⇒ **9 行**。
- ⭐ **九位行（模板 `:67`／基线件 `:66`）已不在命中集里** —— 这是占位符化生效的机器证（见 §11.6 的 L1）。

| 行（模板） | 字段 | 值 | 判定 | 依据（现取） |
|---|---|---|---|---|
| 15 | ⑦ 构建路径缺陷（散文） | `b5f138f8fefcf4b2`／`e8127a3d7128d417` | **常量**（历史读数） | 记录的是**过去动作**的读数（`landing.sh` 旧构建 vs `build-shim.sh` 重建） |
| 16 | ⑧ `DEFREG` 口径 | `f17c41239ffa1408` | **常量**（历史读数） | 「重生成与在册件逐字节相同」那一笔的读数 |
| 17 | ⑨ 冻结器版本链 | `389c2c0b196808ed`／`ea2a08bcc7fa98cf`／`680a4f1320d7ba90`／`88df9632e9f22d85` | **常量**（**版本档名**） | 四值**逐个**在 `~/w21-verify/versions/` 命中 **1** 个归档件（`w27-freeze.py.w78-rootfix-…`／`…w78b-previnfp-…`／`…w78c-infp-…`／`…w78d-allowchanged-…`） |
| 61 | `# COLUMN-CORPUS … sha16=` | `0cebc0afd5142fbf` | **常量 ＋ 有活牙** | `column-floor-check.sh` 档③ 要求 == 语料件现值；**现取** `COLUMN_FLOOR=PASS … corpus=0cebc0afd5142fbf` |
| 62–66 | `# ARM-LOG-SHA arm=<5 臂> sha16=` | 5 值（`1c43a12dcaa5718a`／`9150c3a26a3cb789`／`92570318851ca7e8`／`59a203de30d745a8`／`4bceceeed570ba70`） | **常量 ＋ 有活牙** | 档⑤ **现取** `COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无`（逐臂 `decl==reg`） |

**五世代证据（现取）**：基线件 `#74`–`#78` 各代块里这 6 行的值**逐位相同** ⇒ 判「常量」有实测依据（不是推定）。

### §11.6 反极性腿：**把裸 hex 塞回 ⇒ 必红**（真跑；牙本体只读、**未改动**）

命令：`python3 build/MilBridge/tools/wave-freeze-consistency-check.py --root <仓根> --template <件>`

| 腿 | 被检件 | 读数 |
|---|---|---|
| **L1 交付件** | `w79-record.txt`（`52571ef51842467d`） | `WFREEZE_TEMPLATE=FAIL hits=9`，**点名行 = 15／16／17／61／62／63／64／65／66（无 67）** |
| **L2 反极** | 把 `{PRV}` **塞回裸 hex** 的副本 | `hits=**11**` ⇒ **多出的正是第 67 行与第 68 行**（`WFREEZE_TEMPLATE_HIT … line=67 …`）⇒ **必红并点名** |
| **L2b 反极** | 把 `{WIC}` **塞回裸 hex** 的副本 | 同上 `hits=11`（含第 67／68 行） |

**变体 B（`# ALLOWED-HEX` 行首前缀）机制可用、但代价致命（实测，本件**不采用**）**：给那 9 行加前缀 ⇒ `WFREEZE_TEMPLATE=**PASS** hits=0`，**但**两个**活消费点**的行锚同时归零：`^# COLUMN-CORPUS ` **1 → 0**、`^# ARM-LOG-SHA ` **5 → 0** ⇒ 会当场打断 `build/MilBridge/tools/column-floor-check.sh:290`／`:400` 的抽取（`COLUMN_FLOOR` 的档③/⑤ 退化成 `NOTDECLARED`／`NOINFO`）。
⇒ **出路两条（待主控裁；两者都不在本件写域）**：**(甲)** 给这 6 个每代测量值在冻结器 `fmt` 里加键（则 `hits` 9 → 3）；**(乙)** 把牙的白名单语义从「行首前缀」改成「**独立声明件/尾注**」。

### §11.7 主控两处口径错的**点名更正**

1. **同块 `BASELINE tier=` 行是 `6` 条，不是 `7` 条**（主控早期读数为 7；`t19` 已更正，本件独立复算一致）。
   - **抽取域（纪律：数"有几条"必须用判据自己的抽取域）**：`#78` 块 = 基线件**行 7–79**（`:80` 起是带「已被 `#78` 取代」的 `#77` 块）⇒ `sed -n '7,79p' … | grep -c '^BASELINE tier='` = **6**（`tier=default` × `rep=1/2/3` ＋ `tier=env` × `rep=1/2/3`，逐条已现指行号 74–79）。
   - **对照口径（同一命令打到全文件）**：`grep -c '^BASELINE tier=' samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = **348**（**全世代累计**，不是本块）⇒ 该数**不许**当"本块有几条"。
   - **错因（逐字）**：把 `PREVCHECK=PASS keys=7`（**`prev` 键表大小**）串成了"块内机读行条数" ⇒ **凡"有几条/几个"，必须用判据自己的抽取域现取去数，不许把另一处的同名数字串过来**。
   - ⚠️ **同一错误在仓内还有一处残留**：`build/MilBridge/tools/wave-freeze-consistency-check.py:24` 的注释仍写「同块 **7 条** `BASELINE tier=` 机读行」，与现取 **6** 不符（该件**不在本件写域**，逐字报请主控／`t27` 处置）。
2. **`609192a419d125f2` 不许说成「上一代值」** —— 见 §11.2 的三代对照：`#77` 块 `1f9511a7ef395bfe` ≠ 该值 ≠ 本代现值 `a00895e8158189b9`。

### §11.8 供主控**转抄** `docs/ROUTES.md` `#79` 段的文本（**本件不落该件**）

```markdown
- 🆕 **`#79` 的 `provider` 处置（`t25`；`D-G166`／`D-G149` 第二代）**：`#78` 冻结块九位行的 `provider = 609192a419d125f2` 是**记录模板写死那一刻的现取值**（`t17` 的 F6 之后），**既不是 `#77` 块里的值**（那格 `1f9511a7ef395bfe`）、**也不是本代现取值**（`a00895e8158189b9`）；该值在现树 `*.dll`／`*.so` 有界扫描**命中 0**。⇒ **`#79` 冻结之前，远端在册件里带着这条已知错的 `provider`**（已登记 `D-G166` ＋ dated 更正）。
- **块不改（一字节不改，`sha16=d60b414d5e99cf72`）**：它被**冻结日志**（`BASELINESHA=PASS live==decl`）、**冻后日志 ×2 轮共 4 份**、`docs/CURRENT-STATE.md:9`、**两份哨兵**（`cmp IDENTICAL`）同时引用 ⇒ 就地改写**同时打断四条引用链**；该错值**本身是证据**（「写死字面量 ⇒ 跨代必陈旧 ∧ 三道核全瞎」的原件）。**处置 = dated 更正（原文保留）＋ 下一代写对 ＋ 加牙**（牙 = `WFREEZE_BLOCKVALUES` 档④）。
- **下一代写对**：canonical 记录模板 `~/w186a/w79/w79freeze/w79-record.txt`（`52571ef51842467d`，主控已重指 `GENS['#79']`）：九位行 `provider`／`wic_shim` 改用 `{PRV}`／`{WIC}`，相对位移句用 `{PRV_PREV}`／`{WIC_PREV}`；`fmt` 31 键 / 用到 25 个 / 缺 0；`#78` 那份模板**只读未变**（`e7abc00e76f08338`）。
- **两项待裁**：模板裸 hex 扫描 **9 行**，逐条判为**显式声明的常数字段**（`#74`–`#78` 五世代逐位相同；其中 6 行有活牙 `COLUMN_FLOOR` 档③/⑤ 守着）；但两处**活消费者**把它们锁死成"行首 `# …`"形态 ⇒ `# ALLOWED-HEX` 行首前缀白名单**不可用**（实测 `^# COLUMN-CORPUS` 1→0、`^# ARM-LOG-SHA` 5→0）。⇒ (甲) 给 6 个每代测量值加 `fmt` 键；(乙) 改白名单语义。
```

### §11.9 `artifact + field + sha16`（本件读数总表）

| artifact | field | 值／sha16（现取） |
|---|---|---|
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | 全件 sha16／bytes／lines | **`d60b414d5e99cf72`**／1,166,396 B／4,459 行 |
| 同上 `:66`（`#78` 块九位行） | `provider`（`wic_shim`） | `609192a419d125f2`（`f7b3026c8c019be2`）＝**未改** |
| 同上 `#78` 块内 `BASELINE tier=` | 条数 | **6**（全件口径 **348**） |
| `~/w186a/w79/w79freeze/w79-record.txt` | sha16／lines／bytes／`%h` | **`52571ef51842467d`**／75／27,021 B／1 |
| `~/w186a/w78/w78freeze/w78-record.txt` | sha16（**只读未变**） | `e7abc00e76f08338` |
| `~/w21-verify/w27-freeze.py` | sha16（活件） | `b7912a4a75d36c18` |
| `~/w21-verify/versions/w27-freeze.py.w79-land-…` | sha16（链首） | `fe479b88a852e482` |
| `~/wcaptain-0745/fmt-ext/w27-freeze.fmt-ext.py` | sha16（链中） | `3f1260bbc9213002` |
| `build/MilBridge/tools/wave-freeze-consistency-check.py` | 模板面（L1／L2／L2b） | `FAIL hits=9`／`FAIL hits=11`／`FAIL hits=11` |
| 两份哨兵 | sha16／`cmp` | `7f8e50a9efc1fddf`×2／**IDENTICAL** |
| 冻后日志 ×4 | sha16 | `93e2200bd902cc23`／`674c9d7cce5ec87c`／`8ffb2876d3ff55a2`／`7c221cab09a91283` |
| **本件**（`build/MilBridge/P0-w78-report.md`） | 改前／改后 sha16 | `948b1f495e6701e1` → **见本波落仓读数（报告外）** |

**冻结器链（只读引用，**未改动**）**：`fe479b88a852e482`（`#78` 落地前的活件，归档于 `~/w21-verify/versions/w27-freeze.py.w79-land-fe479b88a852e482`）→ `3f1260bbc9213002`（`fmt` 扩展产物 `~/wcaptain-0745/fmt-ext/w27-freeze.fmt-ext.py`）→ **`b7912a4a75d36c18`**（现装活件）；主控排练读数 **`REHEARSE_BLOCKVALUES=PASS arms=13 pass=13`**（主控现取，本条只引用）。

### §11.10 边界 / `NOINFO`（如实划界）

1. **未重跑**配对实验与 `*.dll`／`*.so` 有界扫描（重活）⇒ 那两格是**引用**（出处 `D-G166` 段与 `P0-w77-report.md`），不是本件现取。
2. **未改**任何冻结器／牙／route 件／基线件／`ROUTES.md`／缺陷册（全在 `outOfScope`）⇒ 本件对现场的**唯一改动**就是本节这段追加。
3. `COLUMN_FLOOR` 那一趟是我以**只读**方式现跑的（`rc=0`），**不是** `verify-all` 全跑 ⇒ 不声称"本波门禁全绿"。
4. 变体 B 的代价我只实测了**行锚归零**这一条（`column-floor-check.sh` 的两处正则）；"它还会连带影响哪些读者"**未逐处枚举** ⇒ `NOINFO`。

### §11.11 落仓读数与**读取时刻**（本节为 `t25` 的第二次追加；对**原始**快照仍只出 `228a229,…` 一条追加命令）

- **读数时刻（`date -Is` 现取）**：§11.1 的四条引用链取于 **`2026-09-27T13:2x+08:00`**；§11.5／§11.6／§11.7 的扫描与两极化腿取于 **`13:2x–13:31`**；契约 verify 三条取于 **`2026-09-27T13:31:31+08:00`**；**本件落仓时刻**（`stat -c %y`）= **`2026-09-27T13:31:22.834536287+08:00`**。
- **本件落仓读数**：改前 `948b1f495e6701e1`（228 行／34,236 B）→ 改后 **`06adff725662c495`**（352 行／50,803 B）；`%h=1`；⚠️ **改后 sha16 属自指 ⇒ 报告内不给**（照 `WC01`／`WC02` 先例）；`head -n -2` 口径 = `1f180fa8d243e3ae`。同目录 `.tmp` 兄弟件现取**不存在**。
- **纯追加机器证（对原始快照）**：前缀 `cmp` **逐字节相同**；`diff` 输出 **只有 `228a229,352`**（**零删、零改**）⇒ `t21` 的 §1–§10、含其 `provider` dated 更正，**原文一字未动**。
- **契约 verify 三条（逐字读数）**：
  ① `bash -c 'sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md | cut -c1-16'` ⇒ **`d60b414d5e99cf72`**（＝改前值 ⇒ **块一字节未改**）；
  ② `bash -c 'grep -c "^BASELINE tier=" samples/WpfTextDemo/ACCEPTANCE-BASELINE.md'` ⇒ **`348`**（**全世代累计口径**；**本代 `#78` 块内 = `6`**，见 §11.7）；
  ③ `bash -c 'grep -aoE "[0-9a-f]{16}" ~/w186a/w79/w79freeze/w79-record.txt'` ⇒ **12 个值／9 行**（逐条点名见 §11.5；**九位行不在其中**）。
- **顺带机器证（只读、非门禁全跑）**：`REPORTID=PASS files=177 ids=1840 declared=202`（本段用到的编号**全部已在册**）｜`COLUMN_FLOOR=PASS … base=d60b414d5e99cf72 corpus=0cebc0afd5142fbf rc=0` ＋ `COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无`。

### §11.12 §11.11 一处**口径更正**（`t25` 第三次追加；照「加注不覆盖」体例，§11.11 原文一字未删）

- §11.11 写的「改后 **`06adff725662c495`**（352 行／50,803 B）」是**第一次追加（§11.1–§11.10）之后**的状态，**不是**本件终态 —— 因为 §11.11 **本身**又是一次追加 ⇒ **自指**。
- **本件终态（以件外现取为准，`2026-09-27T13:31:48+08:00`）**：`build/MilBridge/P0-w78-report.md` ＝ **`53e4fe86e307bba0`**／**487 行**／**69,245 B**／`%h=1`；`head -n -2` 口径 = 以件外现取为准。
- **两次追加都对**同一个原始快照出**同一条**追加命令形态：对 `948b1f495e6701e1`（228 行）的 `diff` ＝ **只有 `228a229,487`**（**零删、零改**）⇒ `t21` 的 §1–§10（含其 `provider` dated 更正）**逐字节原样**。

### §11.13 自伤与修复（`t25` 第四次追加；**如实留档**）

- **自伤**：我把 §11.1–§11.10 的追加件**累加式复用** —— 第二、三次追加时用的**还是同一份源件**（它已被前一次追加进件里）⇒ 现盘件一度出现 **§11.1–§11.10 ×3、§11.11 ×2**（`wc -l` = **628**／**88,541 B**），比应然多出 **259 行**。
- **为什么没被"纯追加"证据拦住**：三次都只验了"**前缀逐字节相同**" ⇒ **纯追加成立、内容却重复** —— 那条断言**只管前缀、不管重复**（本仓「守卫只写一半比没有更危险」同形）。
- **修复（`temp + rename`）**：以**原始快照**（`948b1f495e6701e1`／228 行 ＝ `t21` 末态；`cmp` 实测现盘件前 228 行与它逐字节相同）为基，**一次性**写入干净追加件（`~/w25a/append-P0-w78.md`，`2772be93b21a416f`／141 行）⇒ 终态**每节恰一次**（机器证：`grep -c '^### §11\.'` 逐节 = **1**）。
- **终态读数**：见本波报告（**自指 ⇒ 件内不写**）；对原始快照的 `diff` ＝ **只有 `228a229,<末行>`**（**零删、零改**）。
- **教训（逐字，供后续波复用）**：**累加式追加的源件必须先断言"源件里该节恰 1 次"，追加后还要数"节出现次数"** —— 只验前缀相同**结构上抓不到重复**。
