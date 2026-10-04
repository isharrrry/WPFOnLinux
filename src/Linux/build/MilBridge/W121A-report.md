# W121A 报告 —— 把 `D-G75`／`D-G76` 从"报告里的结论"变成"**会变红的仪器**"

> 车道 **W121A**｜仓库根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`｜全程绝对路径
> 冻结基线 = **`#51` `38e67e834430d75c`**（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:25` `# RE-FROZEN #51` 现场现算）
> 开工 `2026-09-23 08:29:54 +0800`｜判定性读数时刻 `08:48 +0800`｜`loadavg` `0.75 → 4.44 / 3.85 / 2.69`｜
> `MemAvailable` `2,844,004 kB`（`MemTotal 8,113,356 kB`）｜kernel `6.8.0-138-generic`
> **零 `dotnet`**、零仓内构建、零应用/探针、零 `verify-all`/`close-wave`/`integration-wave`、**零既有牙被跑**、零 `pkill`
> **不接线**：`verify-all.sh`／`close-wave.sh`／`known-red.json`／四处声明 **一字未改**
> **不碰 W120A 的写域**：`docs/ROUTES.md`／`CURRENT-STATE.md`／`INDEX.md`／`PORT-SPEC.md`／
>   `KNOWN-DEFECTS.md`／`defect-registry-declared.tsv` **只读**

## §0 交付物一览（sha16 全部现场算，不手抄）

| # | 路径 | sha16 | 行 / 字节 |
|---|---|---|---|
| 1 | `build/MilBridge/tools/uia-door-check.sh`（**新建**，`D-G75` 的牙） | **`d8f23e91ade01453`** | 926 行 / 48,600 B |
| 2 | `build/MilBridge/tools/ime-landing-check.sh`（**新建**，`D-G76` 的牙） | **`05207f31189dc62a`** | 906 行 / 50,013 B |
| 3 | `build/MilBridge/W121A-report.md`（本件） | **见收尾消息** | — |
| 4 | `~/w121a/criteria.md`（**判据先写**，08:39 落笔，早于任何实现） | `68f932b28c4d3086` | 156 行 / 14,247 B |
| 5 | `~/w121a/out-uia-live.txt`（现树读数）+ `out-ime-live.txt`（**终版**，含 §4.4 的 `decl_skip=2`） | `1a6791a7bb311e9c` / `17fbf60ae082b37e` | 56 / 17 行 |
| 6 | `~/w121a/out-uia-selftest.txt` + `out-ime-selftest.txt`（两极化逐例）＋ `out-*-live-postreport.txt`（§4.4 成对读数） | `618d2616e045d905` / `b9188ae9a128b913`（postreport 与 live 同 sha16） | 43 / 50 行 |
| 7 | `~/w121a/STATUS.md`（每小步追加一行） | 见 `~/w121a/` | — |

**现场被引用的既有件（供读者复核；sha16 一律现算）**：
`verify-all.sh 1aa2ae4e94827cf3`（27 步现场：`grep -c '^run_step "'` = 27）｜`build/close-wave.sh c757fd5058f1bfd4`｜
`build/MilBridge/known-red.json 089b7324ba12e022`｜`build/MilBridge/tools/defect-registry-declared.tsv dea8c731369ba0ed`｜
`docs/CURRENT-STATE.md b7b2d513cfdab2eb`｜
`src/WpfGfx.Linux.Native/bin/libwpfwin32.so bd037229be8db4f6`（327,256 B；**注意**：W72A 报告里那份是 `c493639d15678803` ⇒ 本件全部读数按**现件**重取）｜
`src/WpfGfx.Linux.Native/src/win32_core.c 3117923a7c899e05`｜`build/PresentationCore.Linux/HwndTarget.Linux.cs 309c5280207061e0`｜
`build/MilBridge/W72A-report.md a1b01055b7080502`。

**⚠️ 并发披露（如实）**：车道 **W120A** 在 `08:48:30` 改了登记面两件 ⇒
`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` `d85d0de47acb550c` → **`05f2ded4bd08c575`**（2676 → 2708 行，**追加**）、
`docs/ROUTES.md` `fe3e3fde0f456250` → **`af8b55a2f3a8906a`**。
本件的两处引用（`KNOWN-DEFECTS.md:2303`/`:2306`）在改后**行号与内容逐字未变**（W120A 是**追加**）；
改后**重取**两件读数：`decl_hits=0`、`decl_proposal=1`（同一行 `:2306`）、`UIA_DOOR`／`IME_LANDING` 状态行**逐字未变**
（见 §4.4 的成对读数）。

---

## §1 判据（**先写**；全文在 `~/w121a/criteria.md`，此处给可执行摘要）

**共同口径**：三态 `0=PASS`／`1=FAIL`／`2=NOINFO`（**`NOINFO` 不是绿**，只在"真查不动"时用）；
机读行各一条；判据的**承认面**必须打印（`*_SCOPE*`）；**正对照必须同趟、同命令出**（把"0"与"grep 写错了"分开）；
纯读；`*_SELF sha16=` 自证；`--selftest` 打 `ST_ATTEST=OPEN/PASS/NOINFO`。

### 1.1 `uia-door-check.sh`（`D-G75`）

| 面 | 字段 | 机械查法 |
|---|---|---|
| A 门（**生产者**） | `prod` | 自有代码 `build/ src/ samples/` 的 `.cs .c .h .py .sh`（**排除 `build/MilBridge/**` 与 `obj|bin|.artifacts|__pycache__`**）里 `WM_GETOBJECT` 的出现**逐行分类**：`case`⟹`consume`／`#define`·`const`⟹`define`／**声明动词**（`SendMessage|PostMessage|SendNotifyMessage|push|post|emit|raise|dispatch|notify`…）打头且 `WM_GETOBJECT` 是**实参**⟹`prod`／其余⟹`other`（只点名） |
| B 应门人 | `consume` | 同批件里 `case … WM_GETOBJECT` 条数 |
| C 断头·映射 | `core_shim` | `build/shims/**` 全文件里字面量 `"UIAutomationCore.dll"`（正对照同目录 `"user32.dll"`） |
| D 断头·导出 | `uia_syms` | 声明的 shim 库（`src/WpfGfx.Linux.Native/bin/*.so`）上 `nm -D --defined-only` 的 `' T Uia'`（**同库正对照** `' T IsWindows10'`＝`ctrl_syms`；另印该库总导出 `ctrl_total`） |
| E 门后的路 | `live_calls_own` | 自有代码＋编译进来的上游源里 provider 面（`AutomationInteropProvider.*`／`AutomationProvider.*(`／9 条 `Uia*` 原始名）的**非注释**出现 |

**`PASS` ⟺ `prod≥1 ∧ consume≥1 ∧ core_shim≥1 ∧ uia_syms≥1 ∧ live_calls_own≥1`**（五条全要）。
**`FAIL`** 逐条点名：`no-producer`／`no-consumer`／`head-severed:core-shim=0`／`head-severed:uia-syms=0`／`no-live-calls`。
**`NOINFO`**：解释器缺、根缺、源覆盖面 0 件、`build/shims` 不在、**候选库一个都没有**、`nm` 缺、金丝雀失明、
扫描器非 0 退、件数/库数低于下限、`UIAD_ANCHORS=strict` 而锚件不在、`UIAD_TEST_BLIND=1`（只给自测）。

### 1.2 `ime-landing-check.sh`（`D-G76`）

| 面 | 字段 | 机械查法 |
|---|---|---|
| A 落点 | `landings` | 五类相加：① 原生 `Imm<大写>(` 形状；② `XOpenIM|XCreateIC|XSetICFocus|XSetICValues|XFilterEvent|Xutf8LookupString`；③ `WM_IME_*` **减**消息名美化器（`return "WM_IME`／`case 0x011F`）；④ `build/shims/**` 里 `"imm32.dll"`；⑤ 声明的库里 `' T Imm'` |
| B 那道门 | `sm82_case` / `sm82_nonzero` | 从 `win32_core.c` 抽 **`GetSystemMetrics` 函数体**，数选中 `82`/`SM_IMMENABLED` 的 `case` 标签，及其**返回非 0** 的条数；**正对照** `sm_ctrl`＝同函数体里 `SM_CXSCREEN|SM_CYSCREEN` 的 `case` 数（≥1 ⇒ 函数体真抽到了） |
| C 在册声明 | `declared=yes|no` | 在**声明的登记面**（`KNOWN-DEFECTS.md` ＋ `docs/**/*.md` ＋ `build/MilBridge/tools/*.tsv`；**报告面 `build/MilBridge/*.md` 只"看得见"不计**）找**同一行**同时含：**触发词**（`IMMENABLED`／`GetSystemMetrics(82)`／`imm32`）＋**裁决词**（`有意降级`／`有意保留`）＋**登记形状**（`已登记`／`已在册`／`在册裁定`／`已裁`／`裁定`／`✅`）**且不含否决词**（`必须`／`要求`／`建议`／`应当`／`需要登记`／`未落地`／`只登记`…） |
| D 断头规模（读数） | `imm_decls`/`imm_names` | 上游 `UnsafeNativeMethodsCLR.cs` 里 `ExternDll.Imm32` 条数 ＋ 唯一 `Imm*` 方法名数 |

**`PASS` ⟺ `declared=yes` ∧ 世界与声明一致**（三条"不一致"全不成立）：
`imm32-unmapped-while-door-open`（门被补成非 0 而 `imm32` 未映射）／`landing-without-mapping`／`declaration-stale`（声明自陈"零落点"而现场有落点）。
**`FAIL`**：`door-not-declared`（**今天的红**）＋上面三条。
**`NOINFO`**：**函数体抽不到**（门的开合量不了）／函数体正对照为 0／登记面 0 件可读／库找不到／件数下限／锚断／金丝雀失明／解释器缺／`IMEL_TEST_BLIND=1`。

### 1.3 两件的**内置金丝雀都在生产路径上跑**（不是只跑在自测里）

`uia-door-check` 每次真跑前在 `TMPDIR` 造 6 件夹具并要求：生产者被数到（=1）／`case` 记 `consume`／
`if (msg == WM_GETOBJECT)` 记 `other`（**不许**记成 `prod`）／**`build/MilBridge/` 里的同句不许被计**（自污染守卫 a）／
`.md` 里的同句不许被计但**必须可见**（守卫 b）／`build/shims/` 里的库名必须数到。
现场自证：`UIA_DOOR_CANARY=ok prod=1 consume=1 other=1 md_hits=1 core_shim=1 doc=1`。

`ime-landing-check` 每次真跑前造并要求：合格声明被数到（`decl_hits≥1`）／提案行被认出并排除（`decl_proposal≥1`）／
**报告形状里的声明可见且不计**（`decl_skip≥1`）／`case SM_IMMENABLED: return 1;` 被看见（`sm82_nonzero≥1`）／
函数体正对照（`sm_ctrl≥1`）／落点检测器（`native_imm≥1`）。
现场自证：`IME_LANDING_CANARY=ok decl_hits=1 decl_proposal=1 decl_skip=1 sm82_nonzero=1 sm_ctrl=2 native_imm=1`。

---

## §2 覆盖面声明（**含"没查什么"**）

### 2.1 `uia-door-check`（现场 `UIA_DOOR_SCOPE*` 行逐字）

```
UIA_DOOR_SCOPE roots=[build src samples] exts=5 skipdirs=6 skiplocal=[build/MilBridge]
                path_roots=[…/PresentationCore …/PresentationFramework …/UIAutomation/UIAutomationProvider]
                so_dirs=[src/WpfGfx.Linux.Native/bin] shim_dir=build/shims anchors=strict min_src=240 min_libs=1
UIA_DOOR_ROSTER files_src=294 files_path=2659 docs=46 binext=16 noext=14 otherext=82 skipdirs=71 shim_files=18
UIA_DOOR_OTHEREXT .config=1 .csproj=33 .json=9 .log=2 .props=5 .targets=4 .txt=20 .xaml=8
```

- **判**：`build/ src/ samples/` 下 `.cs .c .h .py .sh` 共 **294 件**（`--list-notjudged` 可逐条列出全部 294＋147 件）。
- **不判但可见**：文档/报告 `.md` **46 件**（含 `md_hits=2` —— 那两份 `.md` 里出现过这个字符串，**只看见、不计**）；
  二进制类 16／无扩展名 14／未认领扩展名 82（按扩展名分布印出）；被排除目录 71 个。
- **整棵不判**：`build/MilBridge/**`（判据/报告/夹具驻地）——**自污染守卫**，理由不是洁癖：
  本件自己是 `.sh`，而它的金丝雀夹具里**逐字含** `SendMessage(h, WM_GETOBJECT, …)`；不排除 ⇒ **本件给自己造了一个生产者**。
- **不判**：`upstream/**` 的**生产面**（vendored 镜像；只当"路"来数 `live_calls`）。
- **保守面（故意，如实声明）**：`prod` 只认**声明动词形状**。将来若有人用**别的**形状造门 ⇒ 该行落 `other`
  （`UIA_DOOR_OTHER` 点名）⇒ **仍红**。**宁可红、不许假绿**；真遇到时改一处声明（`UIAD_VERBS`）。
- **本件的绿 ≠ "无障碍可用"**：它只判那五个**静态**条件。

### 2.2 `ime-landing-check`（现场 `IME_LANDING_SCOPE*` 行逐字）

```
IME_LANDING_SCOPE root=… native_dir=src/WpfGfx.Linux.Native/src exts=[.c .h] shim_dir=build/shims
  shim_src=src/WpfGfx.Linux.Native/src/win32_core.c reg_files=[samples/WpfFeatureProbe/KNOWN-DEFECTS.md]
  reg_dirs=[docs] reg_tsv=[build/MilBridge/tools/*.tsv] report_skip=build/MilBridge so_dirs=[…] anchors=strict min_src=8
IME_LANDING_REGISTER reg_files=71 decl_hits=0 decl_proposal=1 decl_skip=1 decl_zero_land=0
```

- **判**：原生源 `src/WpfGfx.Linux.Native/src/**` 的 `.c/.h`（**12 件**，`files_native=12`）；
  `build/shims/**`（18 件，任何扩展名）；**登记面 71 件**（缺陷册 1 ＋ `docs/**/*.md` ＋ `tools/*.tsv`）。
- **只"看得见"不计**：`build/MilBridge/*.md`（**报告面**）——现场命中 **1 行**（`W72A-report.md:302` 的**建议**句）⇒ 打 `IME_DECL_SKIP`。
- **不判**：运行期真实表现（按组合键会不会出预编辑窗）＝ `NOINFO`（需跑应用，本件禁跑）；
  `upstream/**` 的 `imm32` P/Invoke **声明**（只作 `imm_decls` 读数）；XIM 能否在真会话里装上（需原生探针）。
- **本件的绿 ≠ "中文能打"**：它只判"**在册的有意降级与世界一致**"。

---

## §3 **当前树读数**（两件都**按设计**红；逐条依据 `文件:行`）

### 3.1 `UIA_DOOR=FAIL`（rc=1）

```
UIA_DOOR=FAIL prod=0 consume=1 core_shim=0 uia_syms=0 ctrl_syms=8 live_calls=2 (all=69) libs=1
             reason=[no-producer head-severed:core-shim=0 head-severed:uia-syms=0]
UIA_DOOR_CTRL automation_peer=67 core_control="user32.dll"=5 core_any=0 md_hits=2 nm_alive=1/1 ctrl_total=544
UIA_DOOR_CONSUME path=build/PresentationCore.Linux/HwndTarget.Linux.cs line=1138 detail=case WindowMessage.WM_GETOBJECT:
UIA_DOOR_LIVE site=own path=build/PresentationCore.Linux/HwndTarget.Linux.cs line=1484
               detail=return AutomationInteropProvider.ReturnRawElementProvider(handle, wparam, lparam, el);
UIA_DOOR_LIVE site=own path=build/PresentationFramework.Linux/TextBoxBase.Linux.cs line=2034
               detail=AutomationProvider.RaiseAutomationEvent(TextPatternIdentifiers.TextSelectionChangedEvent, this);
UIA_DOOR_LIB path=…/src/WpfGfx.Linux.Native/bin/libwpfwin32.so uia_syms=0 ctrl_syms=8 ctrl_total=544 uia_any=0
```

| 判据面 | 读数 | 逐条依据（现件） |
|---|---|---|
| **A 门不存在** | **`prod=0`** | 自有代码里 `WM_GETOBJECT` **只出现 1 次且是消费者**：`build/PresentationCore.Linux/HwndTarget.Linux.cs:1138` `case WindowMessage.WM_GETOBJECT:`。**正对照**：同一批扫描 `automation_peer=67`（⇒ 扫描器有效）；`prod=0` 不是"没扫到"。**注意**：`D-U1` 那条口径**必须**用"**无门**"，不是"零调用者"（`docs/CURRENT-STATE.md:510` 的更正行） |
| **B 应门人在** | `consume=1` | 同上 `:1138` |
| **C 未映射（断头）** | **`core_shim=0`** | `build/shims/**`（18 件）里 `"UIAutomationCore.dll"` **0 命中**；**正对照** 同目录 `"user32.dll"` = **5**；`core_any=0`（连 `UIAutomationCore` 子串都没有）。断头的对象 = `upstream/…/UiaCoreProviderApi.cs` 的 **9 条** `[DllImport(DllImport.UIAutomationCore…`（现场 `grep -c` = 9，行 `:116/:119/:124/:127/:130/:133/:136/:140/:143`） |
| **D 未导出（断头）** | **`uia_syms=0`** | `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 的 `' T Uia'` = **0**、`uia_any`（符号表任何位置含 `Uia`）= **0**；**正对照**：**同一个库**里 `' T IsWindows10'` = **8**、总导出 `' T '` = **544**；`nm` 本身另用系统 libc 的 `' T malloc'` 自证（`nm_alive=1/1`）。⇒ 这与 `D-U1` 的裁决一致（"不加映射"），但**论据是"无门＋断头"，不是"零调用者"** |
| **E 门后的路在** | `live_calls_own=2` | 自有代码 **2 条**（`HwndTarget.Linux.cs:1484` 直呼 `AutomationInteropProvider.ReturnRawElementProvider`；`TextBoxBase.Linux.cs:2034` 走 `AutomationProvider.RaiseAutomationEvent` 门面）；编译进来的上游源里共 **69** 条（含 W72A 点名的 `HwndHost.cs:632`／`Popup.cs:3435`／`AutomationPeer.cs:335`） |
| **金丝雀** | `UIA_DOOR_CANARY=ok` | 6 项全中（见 §1.3） |
| stderr | **0 字节** | 无噪声（`~/w121a/err-uia-live.txt` = 0 B） |

⇒ **判词**：**门不存在**（`prod=0`）**＋ 门后是断头**（`core_shim=0` 且 `uia_syms=0`）⇒ 辅助功能**静默不可用**。
**这就是设计内的红**：仪器红，不是 `NOINFO`。

### 3.2 `IME_LANDING=FAIL`（rc=1）

```
IME_LANDING=FAIL landings=0 declared=no ctrl=5 sm82_nonzero=0 shim_map=0 so_syms=0 decl_hits=0
               reason=[door-not-declared]
IME_LANDING_LANDINGS landings=0 native_imm=0 native_xim=0 native_wmime=0 wmime_beauty=1 shim_map=0
                     so_syms=0 files_native=12 shim_files=18
IME_LANDING_DOOR sm_body_found=1 sm_body_lines=26 sm82_case=0 sm82_nonzero=0
                 door=GetSystemMetrics82 today=makes_immEnabled_false
IME_LANDING_REGISTER reg_files=71 decl_hits=0 decl_proposal=1 decl_skip=1 decl_zero_land=0
                    （**写完本报告后**再取一趟 ⇒ `decl_skip=2`：多出来的那一条正是**本报告自己** ⇒ 见 §4.4）
IME_LANDING_CTX imm_decls=18 imm_names=14 imm_chain_IMMENABLED=6 tsf_guard=3
IME_DECL_PROPOSAL path=samples/WpfFeatureProbe/KNOWN-DEFECTS.md line=2306
                  detail=- 处置：**本波只登记**。要求：②那一重**必须在册登记为"有意降级"**…
IME_DECL_SKIP path=build/MilBridge/W72A-report.md line=302
              detail=建议**明确登记为"有意降级"**并写进 `docs/CURRENT-STATE.md`…
```

| 面 | 读数 | 逐条依据（现件） |
|---|---|---|
| **A 零落点** | **`landings=0`** | ① `native_imm=0`（`Imm<大写>(` 在 12 件原生源里 0）；② `native_xim=0`（`XOpenIM/XCreateIC/XSetICFocus/XSetICValues/XFilterEvent/Xutf8LookupString` 全 0；**反面对照**：按键只经 `win32_x11.c:1129 XLookupString(&ev.xkey, chbuf, sizeof(chbuf), &ksChar, NULL)` —— **XIC 传 `NULL`**）；③ `native_wmime=0` 且 `wmime_beauty=1`（唯一命中是**消息名美化器** `win32_msg.c:477 case 0x011F: return "WM_IME_SETCONTEXT";` —— **名字不是实现**）；④ `shim_map=0`（`"imm32.dll"` 在 `build/shims/**` 0 命中；**正对照** `"user32.dll"`＝`ctrl=5`）；⑤ `so_syms=0`（`' T Imm'`） |
| **B 门今天关着（巧合）** | `sm82_case=0`、`sm82_nonzero=0` | `src/WpfGfx.Linux.Native/src/win32_core.c:1842 int GetSystemMetrics(int nIndex)` 的函数体 **26 行**（`:1842-1866`）里**没有**选中 `82`／`SM_IMMENABLED` 的 `case` ⇒ 走 `:1865 default: return 0;` ⇒ 托管侧 `SafeSystemMetrics.IsImmEnabled`（`upstream/…/Shared/MS/Win32/SafeSystemMetrics.cs:103 GetSystemMetrics(SM.IMMENABLED) != 0`，`NativeValues.cs:521 IMMENABLED = 82`）恒 false。**正对照** `sm_ctrl=2`（同函数体里 `SM_CXSCREEN`/`SM_CYSCREEN` 的 `case` 都被数到 ⇒ 函数体真抽到了） |
| **C 没人在册登记过** | **`declared=no`（`decl_hits=0`）** | 登记面 **71 件**里，唯一两处含「有意降级」字样的行**都是提案、不是声明**，且**都被本件点名可见**：<br>· `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2306`（`D-G76` 自己那句"**要求**：②那一重**必须**在册登记为'有意降级'…"）⇒ `IME_DECL_PROPOSAL`（含否决词`要求`/`必须`/`只登记`）；<br>· `build/MilBridge/W72A-report.md:302`（"**建议**明确登记为…"）⇒ `IME_DECL_SKIP`（报告面，**看得见、不计**）。<br>⇒ **"要求登记" ≠ "已登记"**；这也正是本件最容易假绿的地方（引用缺陷册自己那行就会假绿）。 |
| **断头规模（读数）** | `imm_decls=18`、`imm_names=14` | `upstream/…/Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:386-441` 的 **18 条** `[DllImport(ExternDll.Imm32…`（**14** 个唯一方法名：`ImmGetContext`/`ImmReleaseContext`/`ImmAssociateContext`/`ImmSetConversionStatus`/`ImmGetConversionStatus`/`ImmSetOpenStatus`/`ImmGetOpenStatus`/`ImmNotifyIME`/`ImmGetProperty`/`ImmGetCompositionString`(×4 重载)/`ImmConfigureIME`(×2)/`ImmSetCompositionWindow`/`ImmSetCandidateWindow`/`ImmGetDefaultIMEWnd`）⇒ 门一开就会撞上这 14 个未映射入口 |
| **门 1 是明确决定（对照）** | `tsf_guard=3` | `build/WindowsBase.Linux/TextServicesLoader.Linux.cs:128 if (!System.OperatingSystem.IsWindows())` / `:248 if (hklm == null)` ⇒ TSF 显式关闭**有理由**；与门 2 的**巧合**刻意分开（这正是 `D-G76` 要害） |
| **金丝雀 / stderr** | `IME_LANDING_CANARY=ok` / 0 字节 | 见 §1.3 |

⇒ **判词**：**组合输入不可用，而且那道门"没人决定过"** ⇒ `door-not-declared`。**这就是设计内的红**。

---

## §4 夹具 ＋ 两极化自检**逐例读数**（严格 63 / `D-G29`：对**现件**跑）

### 4.1 `uia-door-check.sh --selftest`（`ST_ATTEST=PASS`，rc=0）

```
UIA_DOOR_SELFTEST=PASS total=38 pass=38 fail=0 not-as-expected=0
```
（全文 `~/w121a/out-uia-selftest.txt` `618d2616e045d905`）

| 例 | 夹具做什么 | want | 实测 |
|---|---|---|---|
| **S01 装门 ⇒ 绿** | 私有树：`build/PresentationCore.Linux/Door.Linux.cs` 加 `SendMessage(h, WindowMessage.WM_GETOBJECT, …)` ＋ `build/shims/*.cs` 加 `"UIAutomationCore.dll"` 映射 ＋ `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` = **3 行 C stub**（`gcc -shared -fPIC`，导出 `UiaReturnRawElementProvider`/`UiaClientsAreListening`/`IsWindows10OrGreater`） | 0 | **`rc=0 state=PASS`**；`prod=1`、`uia_syms=2`、`ctrl_syms=1`（三条断言逐条 PASS） |
| **S02 反极性：拆门 ⇒ 回红** | 同一棵树上只删那份生产者 | 1 | `rc=1 state=FAIL`，`reason=[no-producer` ✅ |
| **S03 只加映射不加导出** | 换一块**不导出** `Uia*` 的库（`D-U1` 里那条"未来错误"的形态） | 1 | `rc=1`，`reason=[head-severed:uia-syms=0` ✅ |
| **S03b 有导出但没映射** | 同一棵树只拆映射行 | 1 | `rc=1`，`reason=[head-severed:core-shim=0` ✅ |
| **S04 拆应门人** | 删 `case WindowMessage.WM_GETOBJECT:` | 1 | `rc=1`，`reason=[no-consumer` ✅ |
| **S05 自污染守卫 a** | 生产者写在 `build/MilBridge/Canary.Door.cs`（**判据内扩展名**） | 1 | `rc=1`，`reason=[no-producer` ✅（**不自污染**） |
| **S05b 自污染守卫 b** | 生产者只写在 `.md` 里 | 1 | `rc=1`，`reason=[no-producer`＋`docs=1`（**可见**） ✅ |
| S06 候选库一个都没有 | 库目录指向空 | 2 | `NOINFO reason=no-shim-lib-found` ✅ |
| S07 空树 | 空目录 | 2 | `NOINFO`（`no-shim-dir`） ✅ |
| S08/S12 件数下限 | `UIAD_MIN_SRC=999999` | 2 | `reason=too-few-files` ✅ |
| S09 `nm` 缺 | `UIAD_NM=/nonexistent/nm` | 2 | `reason=nm-missing` ✅ |
| S10 解释器缺 | `UIAD_PYTHON=/nonexistent/python3` | 2 | `reason=python-missing` ✅ |
| **S11 弄瞎** | `UIAD_TEST_BLIND=1`（树里**真有**门） | 2 | `NOINFO reason=scanner-blinded` ✅（**不绿、也不冒充红**） |
| **S12 金丝雀弄坏** | `UIAD_CANARY_BREAK=1` | 2 | `NOINFO reason=canary-blind` ✅（证明这条断言是活的） |
| S13 锚断 | 合成树缺三锚 | 2 | `reason=anchor-missing` ✅ |
| S14 TMPDIR 隔离 | — | 0 | `UIA_DOOR_TMPDIR=<沙箱>/tmp/…` ✅ |
| **S15 生产路径（真树）** | `--root $R` | LIVE | `rc=1 state=FAIL` 且 `UIA_DOOR_CANARY=ok` ✅ |
| S16 `/tmp` 残留 | — | 断言 | `uiad-run.*` 残留 = 0 ✅ |

**⚠️ 披露（本轮唯一一次"非纯读"动作，**在仓外、只给夹具**）**：S01/S03 的"**假 `Uia*` 导出**"必须是一个**真 ELF**
（`nm -D` 只认 `.dynsym`）⇒ 夹具用 `gcc -shared -fPIC -x c -`（3 行 stub，落 `$TMPDIR` 沙箱、**不落仓内**）。
**零 `dotnet`**；仓内树 mtime 前后逐件核过（§附）。若某台机器没有 `gcc`，`--selftest` 会**如实**回
`NOINFO reason=premise-unmet:gcc-missing`（**生产路径不需要 gcc**）。本机 `/usr/bin/gcc` 在。

### 4.2 `ime-landing-check.sh --selftest`（`ST_ATTEST=PASS`，rc=0）

```
IME_LANDING_SELFTEST=PASS total=45 pass=45 fail=0 not-as-expected=0
```
（全文 `~/w121a/out-ime-selftest.txt` `b9188ae9a128b913`）

| 例 | 夹具做什么 | want | 实测 |
|---|---|---|---|
| **S01 现树形态** | 门巧合关着（`default: return 0`）＋零声明 | 1 | **`rc=1`，`reason=[door-not-declared`**；`landings=0`、`sm82_nonzero=0` ✅（**这就是今天的红**） |
| **S02 补上在册声明 ⇒ 回绿** | 夹具 `docs/DECL.md` 加一行合格声明 | 0 | **`rc=0 state=PASS`**，`decl_hits=1` ✅ |
| **S03 反极性：拆掉那行 ⇒ 回红** | 同一棵树只把那一行拿掉 | 1 | `rc=1`，`reason=[door-not-declared` ✅ |
| **S04 未来错误：把门补成 1** | `case SM_IMMENABLED: return 1;` | 1 | `rc=1`，`reason=[door-not-declared imm32-unmapped-while-door-open`＋`sm82_nonzero=1` ✅（**`D-G76` 预言的未来错误从此会红并点名**） |
| **S05 有声明也不放过坏世界** | 声明在，门却被补成 1 | 1 | `rc=1`，`reason=[imm32-unmapped-while-door-open` ✅ |
| **S06 有落点却无落地库** | 原生源加 `ImmGetContext(h)`，声明自陈"零落点" | 1 | `reason=[landing-without-mapping`＋`declaration-stale` ✅ |
| **S07 报告不自污染** | 合格声明只写在 `build/MilBridge/FAKE-report.md` | 1 | `rc=1 reason=[door-not-declared`＋`IME_DECL_SKIP path=build/MilBridge/FAKE-report.md`（**可见不计**） ✅ |
| **S08 提案 ≠ 声明** | 只写"要求…必须登记为有意降级" | 1 | `rc=1 reason=[door-not-declared`＋`IME_DECL_PROPOSAL path=docs/PROP.md` ✅ |
| S09 函数体抽不到 | shim 源里没有 `GetSystemMetrics` | 2 | `NOINFO reason=sm-body-not-found` ✅（**门的开合量不了 ⇒ 不许绿**） |
| S10 登记面 0 件 | 登记面指向"存在但空" | 2 | `reason=no-register-surface` ✅ |
| S11 库找不到 | `IMEL_SO_DIRS=nonexistent-dir` | 2 | `reason=no-shim-lib-found` ✅ |
| S12 件数下限 / S13 `nm` 缺 / S14 解释器缺 | — | 2 | `too-few-files` / `nm-missing` / `python-missing` ✅ |
| **S15 弄瞎** | `IMEL_TEST_BLIND=1`（夹具里有声明、门关着） | 2 | `NOINFO reason=scanner-blinded` ✅ |
| **S16 金丝雀弄坏** | `IMEL_CANARY_BREAK=1` | 2 | `NOINFO reason=canary-blind` ✅ |
| S17 锚断 | 夹具缺 `KNOWN-DEFECTS.md` | 2 | `reason=anchor-missing` ✅ |
| S18 TMPDIR 隔离（先把 S03 拆掉的那行放回） | — | 0 | `IME_LANDING_TMPDIR=<沙箱>/tmp/…`，`state=PASS` ✅ |
| **S19 生产路径（真树）** | `--root $R` | LIVE | `rc=1 state=FAIL` 且 `IME_LANDING_CANARY=ok` ✅ |
| S20 `/tmp` 残留 | — | 断言 | `imel-run.*` 残留 = 0 ✅ |

**IME 侧的夹具不需要编译器**（库用 `cp -p` 真复制权威件；**不用 `ln`/硬链接**——`D-G30` 血账）。

### 4.3 两极化四问的**结论**

| 问 | UIA | IME |
|---|---|---|
| ① 当前树 ⇒ **该红的红**（不是 `NOINFO` 冒充） | ✅ `UIA_DOOR=FAIL`，红在名字上（3 条 reason） | ✅ `IME_LANDING=FAIL`，红在名字上（`door-not-declared`） |
| ② 夹具**装门/补声明** ⇒ **回绿** | ✅ S01 `PASS`（门＋应门人＋映射＋**真导出**＋路） | ✅ S02 `PASS`（一行合格声明） |
| ③ **弄瞎仪器** ⇒ `NOINFO` | ✅ S11/S12/S09/S10/S06/S07/S08/S13 | ✅ S15/S16/S09/S10/S11/S12/S13/S14/S17 |
| ④ **反极性：拆掉门/声明** ⇒ **回到红** | ✅ S02（拆生产者）/S03（拆导出）/S03b（拆映射）/S04（拆应门人）/S05/S05b | ✅ S03（拆声明）/S06（加落点却不登记） |

### 4.4 **成对读数：本报告自己引起的位移**（自污染守卫的现场赔付）

写完本报告后**重取**两件读数（`~/w121a/out-*-live-postreport.txt`），逐字比对：

| 件 | 报告写入**前** | 报告写入**后** | 差异 |
|---|---|---|---|
| `uia-door-check` | `UIA_DOOR=FAIL prod=0 consume=1 core_shim=0 uia_syms=0 …` | **逐字相同** | **0**（本报告整棵落在 `build/MilBridge/**` ⇒ 守卫 a 直接不判；`prod` 没有被报告里的 `SendMessage(… WM_GETOBJECT …)` 顶高） |
| `ime-landing-check` | `IME_LANDING=FAIL … decl_hits=0 reason=[door-not-declared]`；`decl_skip=1`（`W72A-report.md:302`） | **状态行逐字相同**；`decl_skip=2` —— 新增的一条是 **`build/MilBridge/W121A-report.md:68`**（现场现取；本报告自身行号会随本文件的后续编辑漂移，**这是"看得见"这一格的性质**）（它逐字含 `declared=yes\|no` ＋ 触发词，**若被当成声明就会把本件自己的结论翻成 `declared=yes` ⇒ 假绿**） | **只有"看得见"这一格 +1；`decl_hits` 仍 0、状态仍 `FAIL`** |

⇒ 这条是**守卫在真实场景下的赔付**：**判据件自己的文档不会把自己的读数翻过来**。
去掉守卫会怎样？现场就能复现：把守卫关掉（自测 S07/S05b 正是这个夹具）⇒ 状态立刻从 `FAIL` 翻成 `PASS`。

---

## §5 **接线草案（逐字，不落地）** —— 含"**必须登记为在册红**"那一步

### 5.0 为什么**不能**直接 `run_step`

两件仪器今天都是 `rc=1`。直接接线 ⇒ 每趟 `verify-all` 的失败数从"声明类 `N`"变成 `N+2`
⇒ 冻结脚本的断言 `assert '结论：❌ 失败项' in log and nfail == len(_expected_red)`
（`~/w21-verify/w27-freeze.py:411-413`，`_expected_red = _decl_red_names`，而 `_decl_red_names`
只由"**声明类且真红**"填，`DECLARATION_CHECKS` 现场只有 `('BASELINE-SHA','ARM-LOG-SHA')` ＋ `COLUMN-FLOOR` 的特例）
会**当场失败**。⇒ **必须走仓内既有的「在册红」形态**。

### 5.1 **在册红**的样板（照抄它，别发明）

`build/MilBridge/tools/tline-gate.sh:1302`：
```python
emit("GATE_REASON=%s" % (",".join(reasons) if reasons else "all-as-registered"))
```
⇒ 它的口径行是 `TLINE_GATE=PASS … registered=182 unlocated=1 drift=0 gone=0 **unregistered=0** caliber=OK generation=#15 tree_gen=same`
＋ `GATE_REASON=all-as-registered`。**语义**：**红 == 在册 ⇒ `rc=0`（PASS）**；**红不在册（`unregistered`）⇒ `rc=1`**。

### 5.2 逐字七步

**第 1 步（必须先做）· 开号登记**
- 首选**复用既有编号**：`build/MilBridge/tools/defect-registry-declared.tsv:96-97` 已有
  `ID<TAB>D-G75<TAB>req=KD<TAB>present=KD` 与 `ID<TAB>D-G76<TAB>req=KD<TAB>present=KD`
  ⇒ 两件仪器就是这两条的"**仪器面**"，**不必新开号**（新开号的语法在同文件头注释：
  `ID<TAB>D-…<TAB>req=KD,CS,…<TAB>present=…`；`req=` 点名的**每个** route 文件里都要有条目，
  现场 112/112）。
- ⚠️ **这一步与车道 W120A 撞写域**（它正在改 `docs/ROUTES.md`／`CURRENT-STATE.md`／
  `defect-registry-declared.tsv`／`KNOWN-DEFECTS.md`）⇒ **由主控串行安排**；本件**没动**这几件。

**第 2 步 · `known-red.json` 登记（形态照 `entries[]`）**
```json
{ "arm": "uia-door", "case_id": "D-G75/no-producer+head-severed",
  "artifact": "build/MilBridge/tools/uia-door-check.sh stdout", "field": "UIA_DOOR",
  "expected_shape": "FAIL prod=0 consume=1 core_shim=0 uia_syms=0 live_calls=2",
  "carrier": "**该仪器自己的机读行**（`UIA_DOOR=FAIL … reason=[no-producer head-severed:core-shim=0 head-severed:uia-syms=0]`）",
  "generation": "#52", "caliber": { "instr_uia_door_check_sh": "<现场 sha16>" } }
```
```json
{ "arm": "ime-landing", "case_id": "D-G76/door-not-declared",
  "artifact": "build/MilBridge/tools/ime-landing-check.sh stdout", "field": "IME_LANDING",
  "expected_shape": "FAIL landings=0 declared=no sm82_nonzero=0 shim_map=0",
  "carrier": "**该仪器自己的机读行**（`IME_LANDING=FAIL … reason=[door-not-declared]`）",
  "generation": "#52", "caliber": { "instr_ime_landing_check_sh": "<现场 sha16>" } }
```
重钉（仓内既有件）：`python3 build/MilBridge/tools/repin-generation.py --why '<逐字理由>'`
（⚠️ **不给 `--why` 也写盘**，那是假绿风险）→ 之后 `--check` 应回 `REPIN_GENERATION=PASS`。

**第 3 步 · 步骤脚本加"在册红包装"（**由主控裁定要不要做**）**
```
读 known-red.json → 取 arm=uia-door / arm=ime-landing 的 expected_shape
现场机读行**逐字段**比对（uia: prod,consume,core_shim,uia_syms,live_calls_own；
                     ime: landings,declared,sm82_nonzero,shim_map）
  一致  ⇒ 打印 UIA_DOOR=FAIL … registered=yes  ＋ GATE_REASON=all-as-registered ⇒ exit 0
  不一致 ⇒ 打印 GATE_REASON=registry-stale(drift|gone)                     ⇒ exit 1
```
- **不许**把 `FAIL` 直接改写成 `PASS`（那是"把红说绿"）；**不许**把两件仪器为了好接而改成 `NOINFO`（本件的目的就是红）。
- 建议把 `UIA_DOOR_OTHER`（**未声明形状**的 `WM_GETOBJECT` 出现）也纳入"非空即红"，
  防将来有人用别的形状造门、而登记表仍"期望红"⇒ 假绿。

**第 4 步 · `verify-all.sh` 四处声明（**同趟**改；漏一处第 `[11]` 步会红）**
- `build/MilBridge/tools/verify-all-step-check.sh` 现场判 `decl-self-inconsistent`／`count-mismatch`／`prose-mismatch`。
- ① `# VERIFYALL-STEPS-DECL: 27 gen=#51`（现件 `:46`）⇒ 顶上**新增**一行
  `# VERIFYALL-STEPS-DECL: 29 gen=#52   ← `#52` **加两步**（27 → 29）：第 `[28]` 步 `UIA-DOOR` ＋ 第 `[29]` 步 `IME-LANDING`（D-G75／D-G76 的牙；**在册红**形态）`
  （若主控要把两件并成一步 `UIA-IME-DOORS` ⇒ 28）
- ② `# VERIFYALL-STEP-NAMES:`（现件 `:65`）末尾追加 ` | UIA-DOOR | IME-LANDING`
- ③ 头注释口径句（现件 `:85` 起那段 `**#51 收官起 = 27 步**`）后追加
  `**`#52` 收官起 = 29 步**（加第 `[28]`/`[29]` 步，判据 `uia-door-check.sh`／`ime-landing-check.sh`；纯读、零 `dotnet`、≈1–3 s；**在册红**）`
- ④ 头注释里那句机器读的"收官后应为 N"（现件 `:22` 的 `grep -c '^run_step "'` 口径）⇒ 改成 **29**
- 接线锚（**不许**用 `echo "====="`，本文件里 4 处）：现件最后一个 `run_step` 是
  `run_step "NUL-BYTES" bash build/MilBridge/tools/nul-bytes-check.sh`（现件 `:891`，**行号会漂 ⇒ 用正文字符串作锚**）
- 追加（逐字）：
  ```
  run_step "UIA-DOOR"    bash build/MilBridge/tools/uia-door-check.sh
  run_step "IME-LANDING" bash build/MilBridge/tools/ime-landing-check.sh
  ```
- ⚠️ 冻结脚本 `~/w21-verify/w27-freeze.py` 的 `GENS['#52']['green']` 里**必须**含这两个步名
  （形态照 `#51` 那条 `green=[… 'NUL-BYTES']`）；否则 `assert _ok, f'缺绿: {_nm}'` 当场失败。

**第 5 步 · `close-wave.sh` 的 `fp_inputs()`（**同趟**，且在 `IN_FP_0` 采样**之前**）**
见 §6（现场机械核：新建本件**不动** `inputs_fp`；**接线那一趟**若按惯例纳入，则**必变**）。

**第 6 步 · 把两件的 `--selftest` 也接上**（纪律 63／`D-G29`：判据件自测必须对**现件**跑）
- 形态照第 `[11]`/`[12]` 步：`--selftest` 的 rc 单独断言。本机现场：UIA `PASS total=38 pass=38 fail=0`、
  IME `PASS total=45 pass=45 fail=0`。
- ⚠️ UIA 的 `--selftest` **需要 `gcc`**（夹具的假导出）；无 `gcc` 的机器会如实回
  `NOINFO reason=premise-unmet:gcc-missing`（**生产路径不需要 gcc**）。

**第 7 步 · 在册红的"射程"必须写死**（否则将来门真装上了，登记表没人更新 ⇒ 假绿）
- 包装层**逐字段**比对（见第 3 步），**不许**只比状态词；
- 门真装上那一趟，`prod`/`uia_syms` 会变 ⇒ 比对失配 ⇒ `registry-stale` ⇒ 红 ⇒ 逼人更新登记表
  （这正是"**门一装上它必须绿、绿灯要有据**"的反面保险）。

---

## §6 `inputs_fp` 影响（**机械核**，不给结论不给数）

```
$ grep -c 'uia-door-check\|ime-landing-check' build/close-wave.sh      ⇒ 0      ← 本件不在覆盖面
$ grep -c 'nul-bytes-check.sh'               build/close-wave.sh      ⇒ 1      ← 正对照（#51 新建的判据件**在**名单里）
$ awk '/^fp_inputs\(\)/,/^\}/' build/close-wave.sh | grep -c 'build/MilBridge/tools/'  ⇒ 15   ← 显式名单（**不是 glob**）
$ awk '/^fp_inputs\(\)/,/^\}/' build/close-wave.sh | wc -l             ⇒ 161    ← 该函数总行数（含 find 段与注释）
```

⇒ **新建这两件 `inputs_fp` 逐位不动**（`fp_inputs()` 是**显式文件名名单**：`close-wave.sh:216-228` 的续行链，
不是 `tools/*.sh` 通配）。

**但接线那一趟会影响**：按仓内惯例「**判据件改了自己必须看得见**」（`close-wave.sh:137-146` 的四件先例、
`:166` 的 `pipefail-sigpipe-check.sh`、`:184-185` 的第三方 Runner），**接线时应把两件加进那条续行链** ⇒
`inputs_fp` **必变** ⇒ 与 `tline-gate.sh`/`known-red.json` **同一条流程代价**：
**必须安排在 `IN_FP_0` 采样之前（独立准备趟）**，否则 `close-wave.sh` 自己的 `[4/6]` 输入稳定性检查会 `exit 5`。
⚠️ 加续行链时**别把注释塞进链里**（`close-wave.sh:186-187` 的血账：`#` 会吃掉链尾，让后一行变成独立命令被执行）。

---

## §7 `D-G75` 空缺表里**还能量化**的项 ⇒ 可机械化候选清单（**只列，不扩面**）

现场 12 条（W72A 报告 §4）里，本件已覆盖 **#1／#3／#6／#7／#9**（UIA 门/断头、XIM、imm32、`WM_IME_*`）。
其余 **7 条**可机械化的候选（每条一句判据草案；**要不要做成牙由主控裁定**）：

| 空缺 | 候选仪器（一句话判据） | 现成的机械抓手（现场读数） |
|---|---|---|
| **#2** `SetWinEventHook`/`NotifyWinEvent` 空壳 | `uia-eventhook-check`：断言"三件 no-op（`NotifyWinEvent` 空体、`SetWinEventHook` 置 error 50 返 NULL、`IsWinEventHookInstalled` 恒 0）**与在册声明一致**"；`nm` 正对照（`' T IsWinEventHookInstalled'`=1）＋ 反极性（把 `IsWinEventHookInstalled` 改成恒 1 ⇒ 必须红） | `src/WpfGfx.Linux.Native/src/win32_misc.c:469-477`（`.so` 现场 `' T IsWinEventHookInstalled'`=1） |
| **#4** UIA client 侧无落点 | `uia-client-check`：自有代码里 `AutomationElement`／`UIAutomationClient` 引用数 == 0，**正对照** `IRawElementProviderSimple` 非 0；`wpf-linux.sln` 的 `^Project(` 8 个里 UIA 工程 == 0 | 本件 `live_calls` 已数到 provider 面；client 面可同法一行加 |
| **#5** AT-SPI2 / D-Bus 桥无落点 | `atspi-bridge-check`：自有代码里 `atspi\|dbus` 的命中**只许是那 2 条注释**（多于 2 ⇒ 有人动工了 ⇒ 必须更新登记）；三态同上 | W72A 现场：`atspi\|dbus` 自有代码命中 = 0（只有 `win32_misc.c:469-470` 与 `extract-win32-inventory.py:423` 两条注释） |
| **#8** TSF/CTF 空壳（**有理由的关闭**） | `tsf-guard-check`：断言 `TextServicesLoader.Linux.cs:128/:248` 两处守卫**在**且仍在 `ServicesInstalled` 取值链上（**回归牙**：删守卫 ⇒ 红）；本件已把它作读数（`tsf_guard=3`） | `build/WindowsBase.Linux/TextServicesLoader.Linux.cs`（sha16 `92c2ab584b4e48a0`） |
| **#10** `InputMethod.PreferredImeState` 静默 no-op | `ime-silent-noop-check`：断言"写 `ImeState` 的分支走 TSF ⇒ `TextServicesCompartmentContext.Current` 返 `null`"这条**静默**路径**在册可见**（要么在册登记为已知静默 no-op，要么给它一条具名台账） | `upstream/…/PresentationFramework/…/InputMethod.cs:517-538` → `TextServicesCompartmentContext.cs:71-73` |
| **#11** MSAA `IAccessible` 成员表为空 | `msaa-shim-check`：断言 `build/shims/Accessibility.Shim.cs` 里 `IAccessible` 接口**成员数 == 0**（门 E 关着时成立），一旦有人补成员 ⇒ 必须同时**开登记**（否则红） | `build/shims/Accessibility.Shim.cs:17-27` |
| **#12** `UiaGetReserved*` 两值**已降级**（`D2`） | `uia-reserved-check`：断言两处短路**仍在**（`UiaCoreTypesApi.Linux.cs:74-87`）且文件自陈"降级不是对齐"那句**在**（**回归牙**：与 `D-U1` 的 `D3`/`D4` 同族，成本≈0） | `build/UIAutomationTypes.Linux/UiaCoreTypesApi.Linux.cs`（W72A 记 `23240b70aaddc2c9`） |

**共同成本**：每条 ≈ **0 条 `dotnet`、< 1 s、零世代位**（都是静态/符号面）⇒ 想做成牙的**边际成本很低**；
但每条都**要么**在现树上是红的（⇒ 需按 §5 的在册红形态接），**要么**是"回归牙"（现树绿、只在有人改坏时红）
—— 主控按后者接**不会**增加冻前红数，**优先推荐** `#8`/`#12` 两条回归牙（今天绿、成本 0）。

---

## §8 `NOINFO` / 未做 / 存疑（**如实**）

### 8.1 本件判据内**故意**保留的 `NOINFO`（不是没做，是"真查不动"）

1. **"AT 真连上来能不能看见控件"** —— 需要一个外部的 AT/UIA 客户端进程 ⇒ 本件禁跑应用。
   *复算配方*：W72A 报告 §7 配方 1（造门后反射调 9 条入口之一会得 `DllNotFoundException`，那是 `D4` 牙的射程）。
2. **"真按一个组合键会怎样"（IME 运行期）** —— 需跑应用/看 `WPF_LINUX_KEY_DIAG` ⇒ `NOINFO`。
3. **XIM 能不能在真会话里装上**（`XOpenIM` 返 NULL 还是可用）—— 需一个 X 会话下的原生探针 ⇒ `NOINFO`。
4. **AT-SPI2 桥的成本** —— 需读 `at-spi2-core` 的 D-Bus IDL ⇒ 超出本件。

### 8.2 本件**没做**的（逐条）

1. **没接线**：`verify-all.sh`／`close-wave.sh`／`known-red.json`／四处声明 **一字未改**（草案见 §5）。
2. **没落地任何产品代码**：`src/**`、`build/shims/**`、`build/*.Linux/**`、applier **一字未改**。
3. **没动登记面**：`docs/ROUTES.md`／`CURRENT-STATE.md`／`INDEX.md`／`PORT-SPEC.md`／
   `KNOWN-DEFECTS.md`／`defect-registry-declared.tsv` **只读**（W120A 的写域）。
4. **没跑**：`dotnet`（0 次）、`verify-all`、`close-wave`、`integration-wave`、`publish-*`、
   **任何既有牙**（`nul-bytes-check.sh`／`shell-quote-trap-check.sh`/… 一次都没跑）、任何应用/探针、`pkill`。
5. **没把"有意降级"真的登记进册**（`D-G76` 处置的执行）—— 那是登记面写域 ⇒ 只给草案（§5 第 1 步）。
6. **UIA 的 `prod` 保守面**：只认声明动词形状；`UIA_DOOR_OTHER` 里的形状**不判绿**（见 §2.1）。今天 `other=0`。
7. **`upstream/**` 生产面未判**（本件只把上游当"路"来数）；`md_hits=2` 那两份 `.md` **没在报告里点名**
   （要逐条：`--list-notjudged`）。
8. **`decl_proposal`/`decl_skip` 的词表是我定的**（`IMEL_DECL_*`）⇒ 若主控认为口径要调（例如"裁定"一词过宽），
   改**一处**声明即可，**判据结构不变**。
9. **W72A 的 `NOINFO#2` 仍开放**（75 处 `CreatePeerForElement` 未逐条核）——本件没接手。
10. **`D-G75` 的"最小第一步 C/D"**（AT-SPI2 桥／XIM 闭环）**没做**（那是独立里程碑，本件只做 A 的仪器面）。

### 8.3 存疑（请主控裁定）

1. **`UIA_DOOR=FAIL` 该不该进 `verify-all`**：本件给的是"在册红"形态；若主控更愿意把它做成
   **仓外仪器**（像 `$HOME/w47b-click.sh` 之于 `#47`）或**只读巡检**（不进每趟），两件都支持（纯读、秒级、零世代成本）。
2. **两件并一步还是两步**：并成 `UIA-IME-DOORS` ⇒ 步数 27→28；分成两步 ⇒ 27→29。**判据不变**（两台机读行各自独立）。
3. **IME 的 `PASS` 语义**：本件把 `PASS` 定义为"**在册的有意降级与世界一致**"。
   若主控认为"没实现 IME 就不该有绿"，那应把 IME 这条**只**接成"回归牙"（今天红 ⇒ 必须按在册红接）；
   两种读法**都写在 §1.2 里**，改法是改 `PASS` 合取项**一处**。

---

## §9 大白话小结（≤6 行）

1. **UIA 那扇门，我用 5 个数把它钉住了**：生产者 `0`（自有代码里这条消息只被人**应门**、没人**发**）、
   应门人 `1`、映射 `0`、导出 `0`（同一块库里 `IsWindows10*` 有 `8` 个 ⇒ 不是我数错）、门后的路 `2` 条 ⇒ **`UIA_DOOR=FAIL`**。
2. **门一旦装上它就会绿**：私有夹具里塞进一个生产者 ＋ 一条映射 ＋ 一个**真的** `Uia*` 导出 ⇒ `PASS`；
   再把生产者拆掉 ⇒ **立刻回到红**（38 例自检全过，含"弄瞎 ⇒ `NOINFO`"）。
3. **输入法那条更狠**：落点 `0`（`Imm`/`XIM`/`WM_IME` 全是 0，唯一那条 `WM_IME_SETCONTEXT` 只是**消息名美化器**），
   而关着它的那道门（`GetSystemMetrics(82)`）是 **`default: return 0` 巧合关的**。
4. ⇒ **`IME_LANDING=FAIL door-not-declared`**：没人**决定**过这件事。我特意把"**要求**登记"和"**已经**登记"分开——
   缺陷册 `D-G76` 自己那行、和 W72A 报告那句建议，**都被我认成提案**（在屏上点名可见，但**不算声明**）。
5. **补上一行合格声明 ⇒ `PASS`；拆掉 ⇒ 回到红**；有人把门"补成 1"（`case SM_IMMENABLED: return 1;`）⇒
   **点名 `imm32-unmapped-while-door-open`** —— 这正是 `D-G76` 预言的未来错误，**从此会红**（45 例自检全过）。
6. **我没接线**（那是主控的决定）：两件今天**故意是红的**，直接进 `verify-all` 会把冻结断言打穿 ⇒
   草案写在 §5，关键是第 1 步"按仓内规矩登记为**在册红**"。零 `dotnet`、仓内只新增两个 `.sh` 与这份报告。
