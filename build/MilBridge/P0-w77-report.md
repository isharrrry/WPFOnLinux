# `P0-w77-report.md` —— 波 `#77` 落地报告（**仪器波 · 零产品改动**；车道 `W185A`，唯一写者）

> 合并件：`TASK-0740` ＋ `TASK-0742` ＋ `TASK-0744` ＋ `TASK-0745`（`W180A` 交付包，复核 `12/12`）
> ＋ **主控同趟追加**：仓根 `Directory.Build.props`/`.targets` 缺席牙 ＋ **21 件旧路径重指向** ＋ `pts-gap-count-check.sh` 三修。
> 判据先写：`~/w180a/w77/criteria.md`（包，**任何 `$R` 写入之前**）｜本波追加三条判据写于落地**之后**（`~/w185a/w77/criteria.md §W77-追加`，**逐字登记、不冒充"判据先写"**）。

## §1 结论（**现取**）

| 项 | 值 |
|---|---|
| 基点（落仓前） | `verify-all.sh b30c685909832f38`／`build/close-wave.sh d76b0f6668d83f13`／`DECL 47 #76`／`run_step=47`／`--expect 205`／覆盖面 `205`／基线 `954df351a119d36f` |
| 落仓后 | `verify-all.sh 7b339c0c9c229c0c`／`build/close-wave.sh 1fa59e709919a1db`／`DECL 50 #77`／`run_step=50`／`--expect 211`／覆盖面 `211` |
| 落仓器读数 | `W77_LAND=APPLIED steps=50 coverage=211 expect=211 manifest_rc=0`；`W77_TOOTH_WIRING WIRING_COVERAGE=PASS run_step=50 wiring_n=46 coverage_n=211 missing_n=0`；`W77_TOOTH_PARSER PARSER_GUARD=PASS examined=8 sites_env=4 sites_parser=0 dynamic_n=4` |
| 旧路径重指向 | `grep -rn 'wpf-linux-20260906' --include='*.sh' --include='*.py' . \| grep -v '^./upstream/' \| wc -l` = **0**（21 件／23 处） |
| 包件逐件对账 | 6 件**与包内记录 sha16 逐位相符**（`fa356ae278497e07`／`750f1303ded9c2ed`／`16f9c8c4bb2dd67c`／`49bb6126b499c2cd`／`ebb775d21b225939`／`d3405956ca46402a`），**零差异** |

## §2 五条 TASK 真落地（两极化**全部真跑**，成对读数）

### 2.1 `TASK-0740` · 接线集 ⊆ 覆盖面（新步 `[48] WIRING-COVERAGE`）
- **正极（真树）**：`WIRING_COVERAGE=PASS run_step=50 wiring_n=46 coverage_n=211 missing_n=0 absent_n=0 allowed_n=0 examined=46`（`rc=0`）。
- **反极①（件存在 ∧ 已接线 ∧ 未入名单，**通用性**：从没出现过的件名 `build/MilBridge/tools/ns77-never-seen.sh`）**：`WIRING_COVERAGE_FAIL rule=wired-but-uncovered file=build/MilBridge/tools/ns77-never-seen.sh …` ⇒ `FAIL missing_n=1`（`rc=1`），**点名该件**。
- **反极②（接线指名不存在的件）**：`rule=wired-path-absent file=build/MilBridge/tools/zzz-absent-77.sh` ⇒ `FAIL absent_n=1`（`rc=1`）。
- **空边 4 条**（`run_step` 零行／覆盖面零行／`verify-all` 缺席／抽取器失明）⇒ `NOINFO rc=3`（包内 `--selftest 13/13`，逐例断言）。
- **最值钱的一对**（包内，同一颗牙同一口径只换覆盖面）：落地前真树 `FAIL missing_n=1` 点名 `tests/WpfGfx.Linux.Tests/Commands.Tests/tools/verify-cmd-layout.py` ⇒ 同趟收编 ⇒ `PASS missing_n=0`。

### 2.2 `TASK-0742` · 解析器不许静默中性化（新步 `[49] PARSER-GUARD`）
- **正极（真树）**：`PARSER_GUARD=PASS examined=8 sites_env=4 sites_parser=0 exempt_used=0 dynamic_n=4 fails=0`（`rc=0`）；`env` 面 4 处逐处上屏裁定 `BENIGN`；`PARSER_GUARD_SELF_EXCLUDED` 逐字上屏（**可见、不静默**）。
- **反极①（沙箱射程内出现未裁定的危害形态，**通用性**）**：`PARSER_GUARD_FAIL rule=unnamed-site family=parser site=build/MilBridge/tools/harmful-77.sh:7` ⇒ `rc=1`。
- **反极②（`--expect-sites` 不符）**：`PARSER_GUARD=FAIL … fails=1` ⇒ `rc=1`。
- 动态面 4/4（4 个 `PARAM` 种类的守卫：**畸形值必响亮拒** ∧ **合法值必过**）；`--selftest 13/13`。
- **一次形态收窄（如实登记）**：宽形态 `or 0\)` 现读命中 4 处**全是表格单元格默认值** ⇒ 会假红 ⇒ 已删；判据由**动态面 ＋ 射程表**承载，**不靠"零命中"**。

### 2.3 `TASK-0744` · 协议级归因（新步 `[50] PROTO-ATTR`）
- **正极**：`PROTO_ATTR_GATE=PASS examined=18 mismatch=0 bad_expect=0 posctl=2/2 cut_and_pair=1`（`rc=0`）；判词 `PROTO_ATTR=ATTRIBUTED cases=18 pass=3 fail=2 noinfo=13`。
- **反极①（`--expect` 翻转）**：`PROTO_ATTR_GATE=FAIL reason=row-count-mismatch` ⇒ `rc=1`。
- **反极②（移除阳性对照）**：`PROTO_ATTR_GATE=FAIL reason=untriggerable` ⇒ `rc=1`（**阳性对照是门槛**）。
- 反极③（`cut` 档 ⇒ `NOT_ATTRIBUTED`）／④（`sock_id=absent` ⇒ `NOINFO`）／⑤（**符号级-only 永不算 `NOT_ATTRIBUTED`**）在语料 18 例内，`--selftest 14/14`。
- **如实边界**：归档真腿 `ATTRIBUTED` **结构性不可达**（装置只印 `fd=<n>`、不印 socket 身份）⇒ 每腿 `NOINFO reason=sock-id-absent`，**拒绝做成假绿**。

### 2.4 `TASK-0745` · 冻结器写记录前自检（**补丁形态；冻结器一字节未动**）
- 包内排练：`RECORDFORM_REHEARSE=PASS arms=28 fail=1`（唯一 FAIL ＝ `ARM PATCHL`）——**如实报**：补丁的**指定基准** `1e2460c1d27e756c` 已被主控在 `2026-09-26 18:01` 重锚取代（现读 `1707dd98434273e9`）⇒ 原器 `E3a` 锚点消失 ⇒ **按设计拒写**（`rc=5 NOINFO reason=anchor-E3a-hits-0`，**不写产物**）。**这正是那条牙在报"我过期了"**。
- 本波**派生** `E1+E2` 两处补丁（`~/w185a/w77/bin/patch745_e12.py`）：`E12_PATCH=APPLIED base_sha16=1707dd98434273e9 out_sha16=1328f1d0b9e7f912 edits=2 (E3=SUPERSEDED-by-controller-reanchor)`；顺序闸 `render<check<makedirs<backup<writeB` ⇒ `yes`。
- **两极化（现行基准，真跑）**：`A1` 正极（7 形态齐）⇒ `bad=0 checked=7 skipped=0`；`A2` 反极（**复现 `#73` 的 `inputs_fp` 位移句**）⇒ `bad=1` 且**点名 `prev_infp`**（`HITS!=1 key=prev_infp … hits=0`）；`A3` 形态出现两次 ⇒ 拒；`A4` 九位行缺席 ⇒ `bad=6`。`REHEARSE745_E12=PASS arms=5 pass=5 fail=0`。
- **逐字声明（主控 `2026-09-26` 要求）**：`W180A` 包里的原 `0745` 补丁（`~/w180a/w77/out/patched-w27-freeze.recordform.py`，`ccd2c363a24fcfef`，基于基准 `1e2460c1d27e756c`）**已被取代（superseded）**；**取代原因 ＝ 其锚点被 `#77` 期的冻结器变更作废**（主控 `18:01` 为 `TASK-0746` 重锚 `w27-freeze.py`：`1e2460c1d27e756c` → `1707dd98434273e9`，`E3a` 锚点（两处 `PREVCHECK=PASS` 打印点）随之消失）。
- **冻结器 before/after**：`1707dd98434273e9`（本波开工现值）→ 只加 `GENS['#77']` → `83b45abedff33c4e` → 再补 `allow_changed` 实测五格 → **`f57132d96da3f5d6`**；版本档 `~/w21-verify/versions/w27-freeze.py.w77-1707dd98434273e9`／`…w77b-83b45abedff33c4e`。**`TASK-0745` 的补丁逻辑一字节未落**（主控写域）。
- **未落项（如实）**：补丁**未**应用（`~/w21-verify/` 是主控写域）⇒ **重新锚定待主控**（主控已追认 `E1+E2` 派生方向）。
- **教训（主控要求进报告）**：**仓外仪器（`~/w21-verify/w27-freeze.py` **不在** `fp_inputs()` 覆盖面）被别的任务改动后，任何以它作文本的补丁都会**静默失去锚点**（本波实测：原器不报错、只是拒写 `rc=5`）⇒ 此类补丁要么**自带锚点断言**（本波已做），要么给该仪器一个**可现取的版本档标识**（`versions/w27-freeze.py.<lane>-<sha16>` 现在就承担了这个角色）。

### 2.5 主控同趟追加 · 仓根 `Directory.Build.props`/`.targets` 缺席牙（**折叠进 `[9] BUILD-HYGIENE`**）
- **为什么折叠而不新开步**：本波契约把 `grep -c '^run_step "'` 钉在 `50`（`47 → 50`，三个新步）⇒ 新开步会变 `51` 与契约冲突；`[9]` 正是"构建卫生"的家（先例 `TASK-0728` 折叠进 `[12]`）。
- **正极（真树）**：`BHYGIENE_ROOTPROPS=PASS exists=0 tracked=0 git=present src=test-e,git-ls-files paths=Directory.Build.props,Directory.Build.targets root=/home/links-dev/netTest/GitProj/WPFOnLinux`；汇总行新增 `rootprops=`／`rootprops_exists=`／`rootprops_tracked=`／`rootprops_git=`。
- **反极①（**真树**把上游原件放回仓根）**：`git show origin/main:Directory.Build.props`（`3a43d0988773baec`）→ 放到仓根 ⇒ `BHYGIENE_DRIFT=FAIL kind=ROOT-PROPS-PRESENT path=Directory.Build.props src=test-e` ＋ `BHYGIENE_IMPORT=FAIL reason=root-props` ＋ `rc=1`；**还原后**回 `PASS`（`git status --porcelain` 前后同为 31）。
- **反极②③（自测）**：`case Z1`（`.props`）／`case Z2`（`.targets`）各必红点名；`case Z3` ＝ **真 `git init` ＋ `git add` ＋ 再 `rm`** ⇒ 工作树**没有**那份文件（存在性那一半绿）但**被跟踪** ⇒ 必红 ⇒ **这就是"只判文件不存在"与"同时判来源"的分水岭**（没有它，第二条来源是死代码）。`case Z4` 正极（`git init` 过、零跟踪）⇒ 不红 ∧ `git=present`。`--selftest **29/29 PASS**`。
- **如实边界**：第二条来源只在 `$ROOT` **本身是 git 仓根**时算得出 ⇒ 否则印 `git=NA` 且**不计入 `PASS`**（`D-G29`：算不出来不许冒充判定）。

## §3 旧路径重指向（21 件／23 处）

**判据**：仓内 `*.sh`／`*.py`（排除 `upstream/`）里 `wpf-linux-20260906` 的命中数 == 0。
**改法**：一律**由仓根现推**（`$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../..[/..]" && pwd)`；python 侧 `os.path.dirname(...os.path.abspath(__file__)...)` 链），与 `verify-all.sh:192`／`close-wave.sh:31` 同法。
**安全**：逐处断言"替换命中数恰 1"（`hits!=1` ⇒ 停手）；改动前**逐件 `cp -p` 备份并断言"备份 sha16 == 覆盖前现读 sha16"**（`D-G126`）；写前 `%h==1`。
**三牙复跑**（它们正是为这类默认值而立的）：`LANEPATH=PASS examined=68 hits=15 code=0 undeclared=0 overgrown=0`｜`SELFDESC_WIRING=PASS examined=58 wired=39 unwired=19 undeclared=48 fails=0 run_step=50`｜`ALIAS=PASS examined=17457 linked_gt1=0 aliased_out=0 reason=no-out-of-repo-alias`。
**⚠️ 两处不按"字面替换"办、已逐字说明**：① `repo-alias-check.sh` 的 `ALIAS_ROOT` 是**被扫的树**（＝本仓）⇒ 由仓根现推语义正确；② `backup-completeness-gate.sh` 的 python heredoc **不许用 `__file__`**（纪律 16）⇒ 改由 bash 侧 `export WPF_BCG_DEFROOT` 传进去。
**语法**：23 处改动覆盖的 21 件全部 `bash -n`／`py_compile` 通过。

## §4 我**推翻了哪句话**

1. **`TASK-0720` 的两条加注已过期**：契约让我核对「第 9 处文本 `win32_classification.c:52` 留在 `#77`」＋「防漂移牙排进 `#77`」—— **现取：`docs/ROUTES.md` 里两条加注都不存在**，两件都在 **`#76`** 办完（提交 `9cea5cc`）。实证：`win32_classification.c:52` 现读已写「可操作 88／实现口径 97」；`pts-gap-count-check.sh` 已在 `build/close-wave.sh` 冻前 `[5b/6]` 段接线。⇒ **该加注已过期**，本波**不做这两件**（做了就是重复劳动）。
2. **`PTSGAP=FAIL` 不是"树缺产物"，而是"在册数没有一条过闸的守卫"**：`t4` 的两处 `SITE-NOHIT build/MilBridge/HANDOFF-NEXT.md ops|impl` 的真因是该件写「**88 可操作／97 实现口径**」而抽取式要「**可操作 N／**」。四修同趟后 **`PTSGAP=PASS`**（读数行带 `root=/home/links-dev/netTest/GitProj/WPFOnLinux`，自证打在**本树**）；`--selftest 7/7`。**迁移前"新树缺产物"的判断在本波现取下不成立**（`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 在场、`so16=fc60c34d51fd9247` 命中 `#76` 冻结值）。
3. **`BOUNDARY_DECL` 的"假红"是既有牙自己的分类器缺陷（本波新步把它顶出来）**：形态②原允许**行首一个反引号** ⇒ 多行注释块的**散文续行**被当成"直调" ⇒ 拉进**只被读、从不被执行**的 `build/close-wave.sh`，再从它的 `printf` 白名单参数表里拉进**从未被调用**的 `run-silenthit-legs.sh` ⇒ 声明 `W68-UNWIRED-PRODUCER`（期望 `unwired-in-step`）**假红**（`route=transitive`）。**修法 ＝ 去掉 `[\`(]*` 前缀**（与件头契约"提到路径不算调用（白名单/字符串/注释里的路径一律不算）"一致）；修后真树 `BOUNDARY_DECL=PASS records=2 pass=2 fail=0` ∧ `--selftest 13/13` ∧ **前一代 `verify-all` 上复跑同样 `PASS`** ⇒ 零判定面位移。**新口径句**：**"判『谁调用了什么』时，被引号/反引号包起来的路径是**散文**，不是命令位；证据域必须剥掉引号与注释。"**（**缺陷编号待主控配号**）
4. **`TASK-0745` 的补丁**：其**指定基准已不存在**（主控 `18:01` 重锚）⇒ 原器 `ARM PATCHL` 真红。⇒ **补丁必须重新锚定**才能落地。

## §4b 🔴 **本波整波时暴露的迁移级阻断（已处置并**如实登记**）**

**现象**：`bash build/integration-wave.sh`（`WAVE_OWNER=waveman`，槽内）⇒ **`集成波结束：失败步骤 10`**：`WpfGfx.Linux 81 个错误`／`PresentationCore.Linux 30`／`DirectWrite.Linux.Provider 36`／`DirectWriteForwarder.Linux 36`／`PresentationFramework.Linux 18`／`WindowsBase.Linux 3`（＋4 个"0 错误但有警告"的工程）。逐条看**全是分析器诊断**：`src/WpfGfx.Linux/Interop/MilHandleTables.cs:72: error CA1051: 不要声明可见实例字段`。

**根因（配对实验，零推测）**：同一条构建命令
`dotnet build src/WpfGfx.Linux/WpfGfx.Linux.csproj -c Release -m:1 --nologo -v q` **加** `-p:EnableNETAnalyzers=false` ⇒ **`0 个错误`**；**不加** ⇒ **`162 条 error`**。⇒ 唯一变量是**分析器策略**，而策略的唯一来源是**仓根 `.editorconfig`**（`76,255 B`，sha16 **`bf84100e2afbd3d2`** ＝ 与 `git show HEAD:.editorconfig` **逐位相同**，即**上游 `dotnet/wpf` 原件**，提交 `da87399`）—— 内含 **129 条 `dotnet_diagnostic.<RULE>.severity = error`**。

**为什么 `t1` 的"求值级等价"看不见它**：两棵树的 MSBuild 属性**逐项相同**（`EnableNETAnalyzers=true`／`AnalysisLevel=latest`／`TreatWarningsAsErrors=false`／`NoWarn=1701;1702;CS0649;CS0169`），而 `.editorconfig` **不在 MSBuild 的属性/项模型里**（它是**编译器级**分析器配置）⇒ `-getProperty` 27 项 ＋ `-getItem:Compile` 的等价证明**结构上无法覆盖它**。`#76` 的活树（现 `.p0shadow-wpf-linux`）**没有这一件**（`ls -a` 实测）⇒ **`t1` 的"在有效构建输入上逐位等价"这句话被本波证伪**（等价成立的是 MSBuild 求值面，**不是**"有效构建输入"全集）。

**处置（按 `t1` 自己裁定 (A) 的同一条原则）**：`t1` 已按"移出 fork 根里重复的 `dotnet/wpf` 源码/构建基础设施"移出根 `Directory.Build.props`／`Directory.Build.targets`／根 `NuGet.config` ⇒ 本件属**同类漏网**（活树没有它 ∧ 它的存在**改变编译结果**）⇒ 本波**移出仓根**（`git rm .editorconfig`），原件与理由存 `~/w-p0mig/quarantine-editorconfig/`（含回退指令）。**这是本波对 `t1` 交付的一处显式修订**，提请主控追认。

**如实划界**：① 本波**没有**逐件普查"还有没有别的根级上游件会改编译结果"——只证了**这一件**是本次 10 处失败的成因（配对实验），**不断言**不存在第二件（下一波若要彻底收口，应把"根级上游件清单"本身做成牙）；② 移出后 `.editorconfig` 的**代码风格**约束随之消失（`EnforceCodeStyleInBuild=false` 现读 ⇒ 对构建**无**其它作用），这是**有意的、逐字声明的**取舍。

## §4c 结构性去重（本波同趟，提请追认 —— 主控已追认）

### `.editorconfig` 移出（本波**唯一**的仓结构改动）
- **件**：`/home/links-dev/netTest/GitProj/WPFOnLinux/.editorconfig`，`76,255 B`，sha16 **`bf84100e2afbd3d2`**（与 `git show HEAD:.editorconfig` **逐位相同** = 上游 `dotnet/wpf` 原件，提交 `da87399`）。
- **处置**：`git rm .editorconfig`；**原件 ＋ 回退指令**存 `~/w-p0mig/quarantine-editorconfig/{.editorconfig,README.md}`；另留车道备份 `~/w185a/w77/backup2/.editorconfig`（写前 `cp -p`，断言"备份 sha16 == 覆盖前现读 sha16"）。
- **回退**：`cp -p ~/w-p0mig/quarantine-editorconfig/.editorconfig <仓根> && git add .editorconfig`。
- **理由**：与 `t1` 裁定 (A) **同一条原则**（移出 fork 根里重复的 `dotnet/wpf` 构建基础设施；`t1` 已按此移出根 `Directory.Build.props`／`Directory.Build.targets`／根 `NuGet.config`）—— 本件属**同类漏网**：`#76` 活树**没有**它，而它的存在**改变编译结果**（129 条 `dotnet_diagnostic.<RULE>.severity = error`）。
- **如实划界（逐字）**：移出的**只是分析器严重度**（`EnforceCodeStyleInBuild=false` 现读 ⇒ 它与"代码风格是否参与构建"无关）；**代码风格约束确已消失**，这是**有意的、逐字声明的**取舍。本波**没有**逐件普查"还有没有别的根级上游件会改编译结果"—— 只证了**这一件**是本次 10 处失败的成因（配对实验），**不断言**不存在第二件（主控已把"**根级条目白名单**"形态排进 `#78`）。

### `t1` 那句过强结论的更正（**本波推翻的第二句话**）
`t1` 报「在**有效构建输入**上逐位等价」。本波证伪：它真正证的是「两树在 **MSBuild 求值模型**上等价（88/88）」＋「九位产物**可用于开工**」，**不是**"有效构建输入逐位等价" —— `.editorconfig` 是**编译器级**输入，**不在 MSBuild 属性/项模型里**，`-getProperty` 27 项 ＋ `-getItem:Compile` 的方法射程**结构上覆盖不到它**。

## §4d 🔴 新发现：**九位是路径承载体 ⇒ 跨树位置不可复现**（主控已追认按此走完）

**事实链（可复算，零推测）**：
1. `#76` 的九位是**从旧树 `O` 拷进 `N` 的**（`O` = `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`，`N` = `/home/links-dev/netTest/GitProj/WPFOnLinux`）。⇒ `t1` 报的"九位全部命中 `#76` 冻结值"是**拷贝来的同一性**，不是 `N` 自己**产出**的同一性。
2. 本波是 `N` 里**第一次真重建**（整波 `失败步骤 0`，`rc=0`）⇒ **五位位移**：`pc 722e0ab8205b7c3f→53fd7fffcdb30243`／`pf 963c59991fd1f709→4fcd2ca021c39064`／`windowsbase 2e4e46e539a72cd7→07c89f1872c1a3c1`／`provider 1f9511a7ef395bfe→4041df9a704abfed`／`dwf ce3469f49efcbcfa→b07f801556e1a511`。**四位逐位未变**：`bridge`／`win32shim`／`wic_shim`／`hbtextline` —— 后三者是**原生/发布件**，本波**未**重建 ⇒ **反证"位移只发生在被重建的托管件上"**。
3. **归因 100% 机械**：五个托管件的 **DEBUG 目录里嵌的 `*.pdb` 绝对路径**变成 `N` 的路径（实测 `strings -a` 命中 `/home/links-dev/netTest/GitProj/WPFOnLinux/build/PresentationCore.Linux/obj/Release/PresentationCore.pdb`）；且**字节大小与 `#76` 冻结值逐位相同**（`pc 3601408`／`pf 6123520`／`windowsbase 1111552`／`provider 104448`／`dwf 39936`）。
4. ⇒ **口径句**：**"托管程序集的哈希是**路径承载体**；凡跨树位置比较产物哈希，先问『它是在哪个树里产出的』——`D-G92` 环成员机制是它的特例，不是它的全部。"**
5. **主控裁定**：**不**把 `O` 的九位拷回来（那会掩盖"树已无法产出相同字节"）；`allow_changed` 照**实测**声明 `{'pc','pf','windowsbase','provider','dwf'}`，`set(changed) ⊆ allow_changed` 的断言**保留**（不是放宽）。

## §4e 🔴 本波自捉：`TASK-0744` 的接线**漏了 `--cases`** ⇒ 该步在真门禁里**从未真判过**

**现场（gate1 现取）**：`步骤通过 49 ❌ 失败 1`｜`结论：❌ 失败项：PROTO-ATTR`｜`PROTO-ATTR ❌ (rc=3)` ＋ `PROTO_ATTR=NOINFO reason=usage:--cases-needs-file cases=0 pass=0 fail=0 noinfo=0 rc=3`。

**根因**：包内 `landing.sh` 的 `RUNSTEP_LINES` 把该步写成 `run_step "PROTO-ATTR" bash build/MilBridge/tools/proto-attribution-check.sh` —— **漏了 `--cases`**（该工具**要求**它；用法行原文：`proto-attribution-check.sh --cases <语料.tsv> [--expect N]   # 门禁走这条`）⇒ 走 `usage` 分支、`rc=3`。
**为什么"复核 12/12"和落仓趟都没抓住**：包内 `landing.sh` 的收口断言**只跑了** `wiring-coverage-check.sh` 与 `parser-guard-check.sh`（`W77_TOOTH_WIRING`／`W77_TOOTH_PARSER`），**没跑** `proto-attribution-check.sh`；包内 `polarity.md` 的 `0744` 读数是**带 `--cases` 手跑**的，**不是门禁形态**。

**修法（**不是放宽**：把"判不了"变成"真判"）**：
`run_step "PROTO-ATTR" bash build/MilBridge/tools/proto-attribution-check.sh --cases build/MilBridge/tools/proto-attribution-cases.tsv --expect 18`（与既有 `SILENT-HIT-V2 … --cases … --expect 12` 同形）。
直跑现取：`PROTO_ATTR_GATE=PASS examined=18 mismatch=0 bad_expect=0 posctl=2/2 cut_and_pair=1`｜`PROTO_ATTR=ATTRIBUTED cases=18 pass=3 fail=2 noinfo=13 rc=0`。
`verify-all.sh` **不在 `fp_inputs()` 覆盖面内** ⇒ `inputs_fp` **不移**；`steps=50`／`--expect 211`／`VERIFYALL_SELF=PASS names=50 decl=50 gen=#77`（`vfile_sha16=9811e86e32fdfcb9`）逐格不变。改前备份 `~/w185a/w77/backup2/verify-all.sh`（`7b339c0c9c229c0c`，断言"备份 sha16 == 覆盖前现读 sha16"）。

**口径句（本波新增，通用）**：**"落仓器的收口断言只验它自己点名的牙" ⇒ 没被点名的那颗牙在真门禁里可以是 `NOINFO`（`rc=3`）而整链只差一格红；凡新增一步，收口断言必须**逐一**把该波**每一颗**新牙按"门禁同形"跑一遍（不是按手跑形态）。"**

### §4e-补 主控裁定三条理由（**逐字**）＋ W180A 复核射程更正

**主控 `2026-09-26` 裁定：「不是放宽判据，是把『判不了』变成『真判』」** —— 逐字采纳：
1. **改前它根本没有判**：`PROTO_ATTR=NOINFO reason=usage:--cases-needs-file cases=0 pass=0 fail=0 rc=3` ⇒ 该步走的是 `usage` 分支。⇒ 加 `--cases` 是**让判据开始执行**，与"把红改绿"是相反方向（纪律 20 管的是放宽判据，这里没有放宽任何阈值）。
2. **"回滚成 `NOINFO` 并等包方补"是更坏的选择**：那会把一个**已接线但不判**的牙冻进世代 —— 正是本仓付过代价的两族：`TASK-0724`「在册但没牙床」与 `D-G136`「件头自述 vs 接线不一致」。**已接线的死牙比没有牙更危险**（它看起来是绿的）。
3. `--expect 18` 是**加牙**（语料被截断 ⇒ `row-count-mismatch` 红），与包内预登记 §3.2 一致；而 `verify-all.sh` **不在 `fp_inputs()` 覆盖面** ⇒ `inputs_fp` 不移，`steps=50`／`--expect 211`／`VERIFYALL_SELF=PASS names=50 decl=50` 逐格不变。

**`W180A` 复核结论的射程更正（纪律 35/40）**：「已复核 12/12」这句话的**射程**必须更正为「**只复核了被点名的两颗牙（`W77_TOOTH_WIRING`／`W77_TOOTH_PARSER`）＋ 手跑形态的第三颗**」—— 第三颗在**门禁形态**下从未被跑过（见 §4e）。该更正同趟落在：① 本报告；② `docs/WAVE77-PREREGISTRATION.md` §7.5；③ `~/w180a/w77/SUPERSEDED-NOTE-W77.md`（**原文一字未动**，按本仓体例追加 dated 更正）。

**与本次新落的 `TASK-0740` 的边界（三条互补、互不代偿）**：`TASK-0740` 管「**接线件 ⊆ 覆盖面**」；主控排进 `#78` 的 A 管「**交付 ⊆ 接线**」（本波交付的牙没接线 ⇒ 红并点名）；B 管「**接线 ⟹ 真判**」（`NOINFO reason=usage…`／`cases=0`／`no-cases`／`no-manifest` 这类"接上了但没判"⇒ 红并点名该步；**合法 `NOINFO` 允许**，不许一律当红）。

## §5 边界与 `NOINFO`（**逐条**）

`PROTO_ATTR` 归档真腿 `ATTRIBUTED` 不可达（装置不印 socket 身份）｜`PARSER_GUARD` 的 `parser` 面形态**故意保守**（宽形态会假红，已删）⇒ 判据由**动态面＋射程表**承载，**不靠"零命中"**｜仓根 props 牙的第二条来源在非 git 仓根上 `NA`（**不计入 `PASS`**）｜`TASK-0745` 补丁未落（主控写域）｜**本波不做任何回归判定**（仪器波，机读行 `PREREG-NO-REGRESSION-DECISION: not-applicable-instrument-wave-77`）｜新旧**两树对照**类判据必须用**物理路径**（旧路径现是**指向 `N` 的符号链接**，`readlink -f` 后逐字打印，否则**自己跟自己比**；`t1` 已踩过一次）｜**mtime 类判据在本窗口不可信**（并发写者做过保留 mtime 的整树拷贝）⇒ 在场判据一律用**内容 sha16 ＋ `git status --porcelain`**。

## §6 自伤（**如实留档，全部被自己的断言/牙当场咬住**）

① 新牙诊断串里在**双引号内**用了反引号（`error MSB4236`）⇒ `BHYGIENE_SELFTEST` 的 `noise` 断言**当场红**（`case Z1/Z2 => no`）⇒ 改无反引号写法；② 我的"顺序闸"第一版用 `text.index('TASK-0730')` 取了**首次出现**（在检查点**之前**）⇒ **自造假红** ⇒ 改成 `index(..., i_check)`；③ `TASK-0745` 派生补丁器第一版直接复用原器 `A_E1`（以 `    return bad` 结尾）—— 主控把该行改成 `    return bad, checked, skipped` 后它**仍是子串**（**前缀命中**）⇒ 插入点落进表达式中间 ⇒ `ast` **当场 `invalid syntax`** ⇒ 改**自定界锚**（`D-G131` 同族）；④ 第一版 `~/w180a/w77/landing.sh --apply --repo <沙箱>` 排练把编辑打到**真 `$R`**（`VA/CW/FPMS` 绑在参数解析**之前**）⇒ 爆炸半径**恰好 2 件**（`%h==1` 未写穿，已逐件还原）⇒ 修后新增**两道闸**并**两极化排练**证其会红（`D-G130` 实例④／纪律 47）。

## §7 链与推送

见 `~/w185a/w77/logs/`（`integration-wave.log`／`w77-*.log`）与本节末**现取**读数：

```
（本节由收尾链写入：wave／gateapp ×2／gate1/2/pre/post1/2／冻结／推送／app-local／两哨兵）
```
