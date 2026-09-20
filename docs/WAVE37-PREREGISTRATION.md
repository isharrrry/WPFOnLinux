# `#37` 预登记（**写在任何改动之前**）

> ⚠️ **时序声明（这一节就是为 `#36` 的流程缺口写的）**：本件在**任何代码/仪器/文档改动之前**落盘。
> `#36` 那一波是**落地之后补写的**收尾记录（见 `docs/WAVE34-PREREGISTRATION.md` §3w 开头），
> 那是违反自家协议的一次，**不许当惯例**。判据：本文件的修改时间必须**早于**本波第一次
> `WAVE_OWNER=… bash build/integration-wave.sh`。

---

## 1. 候选清单（按价值排序；本波**选定**的见 §2）

| # | 项 | 价值 | 代价 | 可证伪的验收（**先写死**） |
|---|---|---|---|---|
| **A** | **权威件切 Release**（Debug → Release） | ⭐⭐⭐ 真应用可用性的最大缺口：Debug 自产件带着上游 `Debug.Assert`/`Invariant.Assert`（**Release 下未必被条件化**）＋ 性能差 | 大：动 HintPath / `AUTH_PC` / `frame-step.sh` / 样本属性；九位**全变** | ① Release 构建 0 error；② `verify-all` 全绿（步数不变或如实 +N）；③ 应用门禁 6/6 PASS 且窗口内色数 **≥** Debug 档（≥3960/≥2828）；④ 五臂按 `GEN_KEYS` 决定是否重取（`pc` 会变 ⇒ 三支 `tab-*` 臂**必须**重取） |
| **B** | **第三方 repro 进仓** | ⭐⭐⭐ 把"第三方 app 能渲染"从**仓外口头证据**升级成**仓内判据** | 中：写一个"第三方形态"的最小工程（独立 csproj ＋ 用 `build/third-party/WpfLinux.props`；用 `WindowChrome`／图片／BAML／`GeneratedInternalTypeHelper`） | ① `bash samples/ThirdPartyMini/run.sh` 开窗、窗口内色数 ≥ 阈值、`rc=143`；② 它的产物**不依赖**仓内 `build/*/bin` 之外的私有路径；③ 接进门禁/`verify-all` 后有**能红能绿**的反极性 |
| **C** | **GDI+ 图像族真解码** | ⭐⭐ 第三方应用常走 `GDI+` 解码图片（今天只做到"应用能起来"：创建/解码类**如实失败**） | 中大：C 侧实现只读族（`GdipCreateBitmapFromFile/FromStream`、`GdipGetImageWidth/Height`、`GdipBitmapLockBits/UnlockBits`、`GdipDisposeImage`），后端复用 wic-shim 的 Skia 解码 | ① 新入口有 `--selftest` 或独立用例；② 第三方形态例子里"从 PNG 加载并画出来"的**截图色数**可测；③ **反极性**：喂一个坏文件 ⇒ 必须返回失败码（不许假装成功） |
| **D** | **`D-G45` SWE 接线**（身份一致方案） | ⭐⭐ 用了 `XamlAccessLevel` 的 BAML 会抛；替身已写好但停用 | 中：先**验一件事**——删 `PackageReference` 后 `obj/project.assets.json` 是否随隐式 restore 更新（`#36` 未验） | ① 7 个工程**一次**接线后全构建 0 error（无 `CS0012`）；② 一个真用 `XamlAccessLevel` 的例从"抛异常"变成"过"；③ `patch-swe-linux.py --check` 7/7；④ 回退路径一行可回 |
| **E** | **`D-T4`**（唯一改像素的已知红：帧步 3 条结构族红） | ⭐⭐ 正确性；但**会让像素变** | 大：重取五臂 ＋ 重取 `PcLineOracle/known-red.txt` 的 `tab0` 族 **136 条** | `#33` 已备可证伪方子 **E1–E4**（零响应复现／两档不同的用例／重建后 `结构红 3→0 ∧ LINECOUNT 60→0 ∧ 结构族NOINFO 101→0` 而 `@default` 臂 `IDENTICAL`／真值自洽／用修前 `pc` 做反极性） |
| **F1** | `FRAMEPRESENCE` 的 `magenta_frames=0` ⇒ **改成 `n/a`** | ⭐ 治"**没测**被印成 0"（本工程的老病） | 小：一行级 ＋ `--selftest` 加一例 | 不给 `--magenta` 时，机读行里**不出现**数字形态的 `magenta_frames=`；给了仍报 31 |
| **F2** | `frame-presence-check.sh` **进 `fp_inputs()`** | ⭐ 它是**判据件**却没人看着（`#36` 登记为缺口） | 小：改 `build/close-wave.sh` | `inputs_fp` **设计性变更**（按代声明）；`FP-INPUTS-HYGIENE` 仍绿（不许把产物路径收进来） |
| **F3** | **"本代必须有一节预登记"的牙** | ⭐⭐ 治 `#36` 那个流程缺口（今天**零机器红**） | 小：挂在现有步 `[11]` 里（步数不变） | 把 `docs/WAVE34-PREREGISTRATION.md` 里本代号的小节标题临时改坏 ⇒ 该步必须**红**（反极性）；恢复 ⇒ 绿 |
| **F4** | **`pf` 可复现性探针** | ⭐ 判定"`pf` 逐位身份是不是噪声"（`#36` 只归因到"是身份不是内容"） | 小：同源重编两次 PF 比 hash | 两次相同 ⇒ 说明身份位是**内容派生**（那 `#36` 的位移就需要更强的输入解释）；两次不同 ⇒ 结论升级为"**`pf` 逐位身份不可复现**，历次'`pf` 变'都是构建噪声" |

---

## 2. 本波**选定**的范围

**先做 `F1`–`F4`（仪器四小项，便宜、且都是"治自己"）+ `B`（第三方进仓）**，再按剩余时间决定是否开 `A`（Release）。

**为什么这样排**：

- `F3`/`F1` 治的是**两次真实自伤**（`#36` 落地先于预登记；`#36` 冻后复核发现"没测=0"）⇒ 它们属于"**让下一次不再犯**"，价值高于再加一个功能。
- `B` 是**用户明确要的东西的凭证**：`README` 现在能说"第三方 app 能渲染"，但那条证据在**仓外**。
  把它变成仓内判据之后，**开源首版的承重主张才有牙**。
- `A`（Release）是**最大的一块**，但它会**翻九位 ＋ 改门禁链**；`#36` 刚冻完，连续两波大位移会让"可复算"变难核对
  ⇒ **单独成波**，且必须在 `F*` 落地之后（否则 `F3` 的牙还没长出来，又要补写记录）。

---

## 3. 逐项的**预登记判据**（写死，读数之后不许改）

### 3.1 `F1`（`magenta_frames=n/a`）
- **反极性必须先有**：`--selftest` 里加"**不给 `--magenta` 时不得出现数字形态**"这一例，**且它在旧件上必须失败**（证明这一例不是恒真）。
- 真树上两趟读数（`--judge-only`）：不给 ⇒ `magenta_frames=n/a`；给 ⇒ `31`（帧目录 `$HOME/w34-framepresence-043414`，可复算）。

### 3.2 `F2`（读者的覆盖面）
- 收进 `fp_inputs()` 后，`inputs_fp` **必然变** ⇒ 按代声明（`infp=` 新值），**不许**用"脚本不断言旧值"糊过去。
- 另一条硬要求：`FP-INPUTS-HYGIENE` **仍绿**（新成员是 `.sh` 判据件、不是产物路径）。

### 3.3 `F3`（预登记存在性牙）
- 判据形态（**建议**）：`grep -qE "^## 3[a-z]?\..*`#${GEN}`" docs/WAVE34-PREREGISTRATION.md` 或本波新文件，
  即在**当前世代号**上必须能找到一个"本节属于这一代"的标题；缺 ⇒ `NOINFO`（**缺声明 ≠ 通过**），
  世代号取 `verify-all.sh` 的 `VERIFYALL-STEPS-DECL` 首行（**唯一声明处**，不新造第二处）。
- **反极性两例**：① 把本波小节标题里的 `#37` 改成 `#99` ⇒ 必须红/NOINFO；② 恢复 ⇒ 绿。
- 挂点：**优先挂在现有第 `[11]` 步 `VERIFYALL-SELF` 里**（那一步已经在核"声明 ⇔ 现场"），
  ⇒ **步数不变**；若必须新增步，则按 `#36` 的教训**同趟**改三处声明（`STEPS-DECL`、口径句、**`STEP-NAMES` 名单**）。

### 3.4 `F4`（`pf` 探针）
- 探针必须**不动产品树**：`dotnet build -p:OutputPath=/tmp/pf-r1/` 与 `/tmp/pf-r2/`（obj 复用），比两份产物的 sha16；
  若其值 ≠ 现场 `pf`，**如实说明**（不同 OutputPath 可能改内容哈希）。
- 结论只有两种，**都要写进记录**：稳定 ⇒ "身份位是内容派生"；不稳定 ⇒ "**`pf` 逐位身份不可复现**"。

### 3.5 `B`（第三方 repro 进仓）
- 工程的**形态要求**（写死，防止做成"又一个自建样本"）：
  ① 独立 csproj ＋ **只**通过 `build/third-party/WpfLinux.props` 接自产栈（不 import 仓内样本的任何 props）；
  ② 覆盖第三方真会撞的三件事：`WindowChrome`、**图片**、**BAML ＋ `GeneratedInternalTypeHelper`**；
  ③ 运行脚本自带 `Xvfb` 与自己数色（照 `run-wpftextdemo.sh` 的判据形态，但**不复用它的门禁**）。
- **判据**：窗口内颜色数 ≥ 一个**先定死**的阈值（建议 **≥ 800**，理由：HandyControl 实测 1275、自建样本 3960/2828；
  取 800 留足余量，且**低于它一定是坏了**），`rc=143`（被 runner 正常收）。
- **反极性**：把 `libwpfwin32.so` 从应用目录挪走一趟 ⇒ 必须**红**（并如实失败：`DllNotFoundException`）。

---

## 3.4b `F4` 的结果（本波第一件，**已做**）——⭐ 抓出一条**封条纪律缺口**

### 探针（三步，全部可复算）

| 步骤 | 命令（要点） | 结果 |
|---|---|---|
| ① 同源重编 ×2，各自独立 `OutputPath` | `dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -c Debug -t:Rebuild -p:BuildProjectReferences=false -p:OutputPath=/tmp/pf-probe-{a,b}/ -m:1` | 两趟**逐字节相同** = `a3b1df59e1d0d05b`（各 7122432 B） |
| ② 默认输出路径上再干净重编一次（**先备份冻结件、跑完原样放回**） | 同上，但不给 `OutputPath` | 仍是 `a3b1df59e1d0d05b` ⇒ **输出路径形状不影响身份位** |
| ③ 与冻结现场比 | `#36` 冻结的 `pf` = `dbb0a450e09e76a3` | **≠** 干净重编值；逐字节差 = **72 B / 5 段**（PE `TimeDateStamp`、MVID、Debug Directory 的 PDB GUID/校验和）⇒ **IL 与元数据表逐字节相同** |

**探针的安全性（先声明、后执行）**：九位在探针**前后逐位未变**（`$HOME/w37-f4-pre.sha` vs `-post.sha`）；
步②动过冻结件，但**当场按字节放回**并核对 `sha256 = dbb0a450e09e76a3` ✅（`/tmp/pf-frozen-backup.dll` 留档）。

### 结论（三条，都要写进理解里）

1. **PF 的构建是确定性的**：三次独立干净重编给出**同一个**字节序列 ⇒ "每次重编身份位就变"**不是**构建随机性。
2. **冻结的 `pf` 不是"当前源码的构建物"**：它带着**另一套身份位**（IL 相同）。也就是说，
   那份权威件是在**输入与今天不同的时刻**编出来的；最可能的时间窗 = `#36` 波内那次
   **SWE 试接**（那时 PF 的 csproj 里多了一条指向替身的 `<Reference HintPath>`，restore/obj 图随之变），
   而"删掉那条引用后重建"并没有把**中间产物**里的身份位拉回来。⚠️ **机制未完全归因**（未做逐输入对照），
   但"IL 逐字节相同"这条已经证明**产品内容无差异**。
3. ⭐ **封条纪律缺口（本波新登记，建议编号 `D-G46`）**：九位封条只声明"这个哈希是多少"，
   **没有任何一条牙**能区分「封条 = 当前源码的可复现构建」与「封条 = 某次构建留下的身份位」。
   ⇒ 于是"**权威件可能是陈旧的**"这件事在验收里**完全看不见**（本波是**探针**查出来的，不是牙齿）。
   **建议的牙**（二选一，下一波定）：
   ① 波尾对每个权威位跑一次"**干净重编 ≡ 封条值**"的核对（成本：每个托管位 ≈1 min；`bridge` 走 AOT 更贵）；
   ② 退一步：只对**托管位**做，且把结果作为**声明**（`BIT-REBUILD: pc=match pf=stale …`）——
      诚实但不阻塞：`stale` 必须**打印出来**，且**只允许在"逐字节 IL 相同"被证明时**才算通过。

### 对 `#36` 冻结块的影响（如实说明）

**不改冻结块**（它记录的是当时的现场，改了就要重冻）。但**必须这样理解它**：
`pf` 那一行是「**当时现场的身份位**」，**不是**「当前源码的可复现构建」；
而 `pc`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`bridge`/`dwf` 七位**未移动**，
其中 `pc` 等至少在本趟 `integration-wave.sh` 里被重编过而**逐位未变** ⇒ 它们**是**自洽的
（⚠️ 严格说：这也**没有**被"干净重编 ≡ 封条"这条牙证明过 —— 缺口 3 对**每一位**都成立，
只是 `pf` 这一次被探针抓了个现行）。

## 3.3b `F1`–`F3` 的结果（**已做**）

| 项 | 改了什么 | 读数（可复算） |
|---|---|---|
| **`F1`** | `frame-presence-check.sh`：**没给 `--magenta` 时 `magenta_frames` 打 `n/a`**（原来打 `0` ⇒ "没测"冒充"测了，结果是 0"）；`--selftest` 加 **2 例**（形态判据 ＋ 它的反极性） | 自测 **7/7**（原 5 例 ＋ 新 2 例）；真树 `--judge-only=<dir>` ⇒ `magenta_frames=n/a`，加 `--magenta` ⇒ `31`；**反例**：旧件（`/tmp/fpc-before-f1.sh`）同一目录打 `magenta_frames=0` ⇒ 新判据**非恒真** |
| **`F2`** | `build/close-wave.sh` 的 `fp_inputs()` **纳入** `build/MilBridge/tools/frame-presence-check.sh`（它是判据件，此前没人看着） | `coverage_n 123 → 124`；`FP_INPUTS_HYGIENE=PASS reason=clean artifact_n=0`；`inputs_fp` **设计性变更**（按代声明） |
| **`F3`** | `verify-all-step-check.sh` 新增"**本代必须有预登记节**"判据（扫 `docs/WAVE*-PREREGISTRATION.md` 的**标题行**里有没有本代号；缺 ⇒ `NOINFO prereg-absent`），挂在**现有**第 `[11]` 步里（**步数不变**） | 真树 `VERIFYALL_SELF=PASS … prereg=PASS`；自测 **23/23**（原 21 ＋ 新 2 例：**扫到 0 件** / **标题里是别的世代**，都必须 `NOINFO`）；`target_untouched=yes` |

### ⚠️ `F3` 第一次跑就撞上的两件事（都如实记）

1. **位置错了会把别人的原因码盖掉**：新判据初版放在**其它判据之前**，而 `report_noinfo` 会**立刻 `exit 2`**
   ⇒ 自测里本该报 `prose-mismatch` / `duplicate-step-name` 的 **17 例**被它统一改报 `prereg-absent`
   （**同一个现象换一个理由**，会让人查错方向）。修法 = 挪进「**其余判据全过**」的分支里
   ⇒ 它只能把 `PASS` **降级**成 `NOINFO`，永远不能替别人出声。
2. **沙箱要跟上判据**：fixture 在 `mktemp -d` 里、没有 `docs/`，于是所有"期望 `rc=0`"的例都被新判据打红
   （看起来像"新判据把老例全毁了"，其实只是沙箱缺件）⇒ 给 fixture 造一份 `docs/WAVE00-PREREGISTRATION.md`，
   并把 fixture 用到的**每个世代**（本代/下一代/上一代）都写上标题，否则那些例会**换理由**。

## 3.5b `B`（第三方 repro 进仓）的结果（**已做**）

**落了什么**：`samples/ThirdPartyMini/`（工程 ＋ XAML/cs ＋ `run-thirdparty-mini.sh` ＋ `README.md`），
接成 `verify-all` 第 `[19]` 步 `THIRD-PARTY`（`verify-all` **24 → 25 步**）。

**它"第三方"的形态**（写进 `samples/ThirdPartyMini/README.md` 的对照表）：
**只经** `build/third-party/WpfLinux.props` 接线 ｜ **不** import 仓内 `BuildHygiene.props`（用
`EnableDefaultCompileItems=false` ＋ 名册 `notneeded`/`no-compile-glob`）｜ **不进** `wpf-linux.sln`
｜ 产物**复制到仓外**再跑 ｜ 覆盖 `WindowChrome` ＋ 图片解码 ＋ 中文/图标字形 ＋ 数据绑定 ＋ BAML。

**两极化读数**（都实测）：

| 档 | 命令 | 结果 |
|---|---|---|
| 正极性 | `bash samples/ThirdPartyMini/run-thirdparty-mini.sh 25`（仓外 ＋ 四个 `.so`） | `THIRDPARTY=PASS frames=… max_colors=1485 min_colors=800`、`THIRDPARTY_IMAGE=PASS 96x96 format=Bgra32`、`rc=0` |
| 反极性 | 同上 ＋ `--hide-shim`（**不部署** `libwpfwin32.so`） | `THIRDPARTY=FAIL frames=0 reason=app-exit=134`、`rc=1`，日志里逐字是 `DllNotFoundException: 'kernel32.dll' 已映射到 libwpfwin32.so，但没找到可加载的 shim 库` |
| 判据自测 | `--selftest` | `TPM_SELFTEST=PASS pass=4 fail=0`（`FAIL/PASS/NOINFO` ＋ 阈值抬到不可能达到 ⇒ 必须 `FAIL`） |

**⭐ 顺带抓到两条真问题（都已修，且都写进了样本 README 与 `docs/THIRD-PARTY-APPS.md`）**：

1. **"`.so` 放应用目录"这条部署布局，在仓内根本测不出来**：`Win32ShimResolver` 的候选路径会从
   `AppContext.BaseDirectory` **与** `Directory.GetCurrentDirectory()` 两条各自向上走 12 层找仓根
   （`build/shims/Win32ShimResolver.cs:524-537`）⇒ 只要应用在仓内**或 cwd 是仓根**，
   即使**故意不部署** `libwpfwin32.so` 也会被回退救回来（现场：`--hide-shim` 照样 `PASS`、1485 色
   ⇒ **反极性失效**）。修法 = runner **复制到仓外** ＋ **启动时 `cd` 到应用目录**。
   真正的第三方应用天然满足这两条 ⇒ 它**必须**靠 app-local 的四个 `.so`。
2. **"应用崩了"被记成了"仪器没跑"**：初版把"一帧都没采到"一律记 `NOINFO`（`rc=2`）
   ⇒ 反极性那趟**看起来像仪器故障**。现在按**应用退出码**细分：崩 ⇒ `FAIL`（红），
   只有"应用正常收尾却采不到帧"才是 `NOINFO`。

**还有一条仪器教训（自伤，已修）**：`fp_inputs()` 的 `printf` 续行链里**不能塞注释行** ——
`\` 先拼行、再认注释，于是 `#` 把链尾一起吃掉，后面那行路径就变成**独立命令被执行**
（实测：它真的把第三方样本跑了一遍，输出还被灌进 `xargs sha256sum`）。说明只能写在**独立**注释行上。

## 4. 边界（明说，不许沉默扩权）

- 本波**不做**：`A`（Release，单独成波）｜`C`（GDI+）｜`D`（SWE 接线）｜`E`（`D-T4`）—— 除非 §2 的项全部落地且有余量。
- 本波**不碰**上游 `upstream/wpf/**`（只读）。
- 本波**不许**用"改判据"去换绿：任何判据放宽都要单独立项并写清"放宽后谁会漏掉"。

## 5. 复现命令（全部零参数可重算）

```bash
# 仪器四小项
bash build/MilBridge/tools/frame-presence-check.sh --selftest
bash build/MilBridge/tools/frame-presence-check.sh --judge-only=/home/links-dev/w34-framepresence-043414
bash build/MilBridge/tools/frame-presence-check.sh --judge-only=/home/links-dev/w34-framepresence-043414 --magenta
bash build/MilBridge/tools/verify-all-step-check.sh
bash -c 'source <(sed -n "/^fp_inputs()/,/^}/p" build/close-wave.sh); fp_inputs'

# 第三方 repro
bash samples/ThirdPartyMini/run.sh 60

# 波尾（顺序见 docs/WAVE33-PREREGISTRATION.md §6）
WAVE_OWNER=$(whoami) bash build/integration-wave.sh
bash verify-all.sh
python3 $HOME/w21-verify/w27-freeze.py <verify-all-log> <gate-rows> '#37'
```
