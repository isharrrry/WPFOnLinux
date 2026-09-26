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
