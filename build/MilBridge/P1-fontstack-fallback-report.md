# P1-W38 · 字体栈**降级路径**实现 —— 族解析失败可降级而非 `FailFast`（**只改生成器**）｜C6 判红：守卫的**判据相位**与运行期态漂移

> **本件是实现件**：契约 ＝ `build/MilBridge/P1-fontstack-fallback-criteria.md`（412 行，sha256 `7ceeb953f38fbd4e…`，`t112` 先写）。逐条照 C1–C10、§5 两极化 a/b/c、P1–P8 执行；一切读数**本趟现取**。
> ⚠️ **结论先说**：**崩进程这件事真修好了**（`leg_24` 由 `alive=no app_rc=134 magenta=0 colors=1` 变 `alive=yes app_rc=143`，两页都**真渲染**出内容 —— 见 §C6 的截图判读）；**`FailFast` 位点不再执行**（两处计数 0）；**降级判定行常开可读**；**两极化成对存在**。**但 C6 的 `PTS_GUARD=PASS` 这一格判红** —— 成因是 `pts-pages-guard.sh:51` 的 **`phase=degraded` 相位位**与"`TASK-0302` 已推进到 realized 态"漂移；该件**属 `tools/**`、本件硬条款禁改** ⇒ 如实红 ＋ 给出两侧判读与**反腿实测**（§C6）。
> **读取时刻**：`ts=2026-09-29T03:04`（起）→ `ts=2026-09-29T03:18`（末取）。

---

## §0 改了哪个生成器 ＋ 如何重新生成

**铁律（判据 P8）：只改生成器，不改生成件。** 本件**未碰** `build/PresentationCore.Linux/FamilyCollection.Linux.cs`（手改）—— 它的每一处改动都是**跑生成器**产出的。

| 项 | 值 |
|---|---|
| 生成器 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py` ＝ `3610e096981daab8` → **`8d01f7348a4f88cd`** |
| 生成件 | `build/PresentationCore.Linux/FamilyCollection.Linux.cs` ＝ `19a42240f59af073` → **`6f084373c15504c7`**（2199 → **2206** 行） |
| 重新生成命令 | `python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py --apply` |
| 幂等证明（P8） | 同一命令**再跑一次** ⇒ `[生成] …：内容已是最新（未重写）`；sha16 **identical=yes** |
| 构建 | `dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -c Release` ⇒ **`0 个警告 0 个错误`**，`PresentationCore.dll` ＝ `5b6cfda3e12b84fc` → **`02f158868aa99df4`** |

### 改了什么（两处，都在 `LookupFamily` 的 provider 回退段）

**① 闸门放宽**（根因修复）。原文只有"名字命中 4 个系统复合字体"才走 provider 回退：

```
- if (!OperatingSystem.IsWindows() && SystemCompositeFonts.IsSystemCompositeFontName(familyName))
+ if (!OperatingSystem.IsWindows() && (_fbCompositeName || _fbNullFontFamily))
```

其中 `_fbNullFontFamily = string.Equals(familyName, "ARIAL", StringComparison.Ordinal)`。

**为什么是 `"ARIAL"` 而不是 `"#ARIAL"`**（现取机读）：`FontFamily.cs:38` 的 `NullFontFamilyCanonicalName = CanonicalFontFamilyReference.Create(null, "#ARIAL")`；`CanonicalFontFamilyReference.cs:28-65` 的 `SplitFontFamilyReference` 把 `#` 前的 **location 段**（此处为空）与**族名段**分开、再 `Uri.UnescapeDataString` ⇒ 传到 `FamilyCollection.LookupFamily` 的 `familyName` 的实参是 **`CanonicalFontFamilyReference.FamilyName`（`FontFamily.cs:511`）＝ `"ARIAL"`**。

**为什么这一个名字就是本族的根因**：`FontFamily.cs:311-347` 里 `:330` 取请求族（本机 `Arial` 解析不到 ⇒ null）⇒ `:335` 退到空字体族 `#ARIAL` ⇒ 该名字**过不了**原闸（闸内只有 4 个系统复合字体名）⇒ 落到 `_fontCollection["ARIAL"]` ＝ null ⇒ `:336` 的 **1 参 `Invariant.Assert(family != null)`** ⇒ `Environment.FailFast`（**不可捕获**）⇒ 整进程 `rc=134`。

**② 降级判定行（常开、机器可读；判据 C4/C5 的可判面）**：

```
[FONT_FALLBACK] requested=<请求族名> fallback=yes|no resolved=<选中族名|none>
```

- 在**闸内**打（`fallback=yes` 时）与**集合解析那一刻之前**打（`fallback=no` 时），**同一仪器、同一口径**产出两态。
- **常开**（不靠 `WPF_LINUX_FONT_DIAG`）；既有的 `[FONT_DIAG] providerFallback:`（环境变量支）**原样保留**。
- `resolved=` 走 `_fontCollection[<请求名>]` 现查；取不到就如实 `none`（**不编名**）。

### 未动的东西（边界自证）
- **`Invariant*` 两件语义一字未改**：`git diff --numstat -- build/WindowsBase.Linux/Invariant.Linux.cs upstream/…/Shared/MS/Internal/Invariant.cs` ⇒ **空**（`FailFast` 仍然"真的终止进程"，只是本族不再走到它）。
- `.so` **未动**（`a131ea4e6f5cc4f5`）；`exports` **未动**（572/572）。
- `build/DirectWrite.Linux/Provider/**`、第三方应用、判据件、`tools/**` 全部未动。

---

## §1 C1–C10 逐条读数

### C1 构建面 ✅（改动真进产物）
```
PresentationCore.Linux.csproj ⇒ 0 个警告 0 个错误（BUILD_RC=0）
ARTIFACT_SRC_FP proj=PresentationCore fp=2f3e458da268e872 n=1374  →  fp=69d0494587369243 n=1374
cdll sha16: 5b6cfda3e12b84fc → 02f158868aa99df4
```
- **逐条点名"哪一件变了"**：**只有 `PresentationCore` 一行**（`fp=` 变、`n=1374` **不变** ⇒ 只改了**内容**、没增删文件）。`WindowsBase`／`PresentationFramework` 两行**逐位未变**。
- **"改动真编进产物"的机械证据**（.NET 元数据里字符串是 **UTF-16**，`strings -a` 看不见 —— 本趟**先踩过这个坑**，如实记）：`PresentationCore.dll` 现取 `FONT_FALLBACK` **utf16=1**、`EmitFontFallbackDiag` **ascii=1**；而既有同款串 `FONT_DIAG` **ascii=0/utf16=2**、`providerFallback` **ascii=2/utf16=3** ⇒ 检出方法与既有串一致、**新串确实进了产物**。

### C2 导出/接口面 ✅（**不靠改导出面收尾**）
```
nm=572 exports=572 diff=0（comm -3 为空）
```
⇒ 本族**不是**缺符号族：**没有**新增/删除任何导出，**未**用"加一个导出"冒充修好。**本条的绿不构成"前进"证据**。

### C3 进程存活面 ✅
```
LEG k=23 alive=yes app_rc=143 magenta=0 colors=391 ns=…RichTextBoxDemo  ae=0      ink=480000
LEG k=24 alive=yes app_rc=143 magenta=0 colors=391 ns=…FlowDocumentDemo ae=14775  ink=480000
session.txt: APP_RC=143（rc_reading: SIGTERM(仪器收的)）; clicks=[24,23] 两页都有 CLICK 行
```
⇒ 两页**都有本趟读数**、`app_rc ∉ {134,139}`、**`clicks=` 覆盖 k=23 与 k=24 两者**（**修前正是 `clicks=[24,23]` 且第一条就死** ⇒ k=23 没有本趟读数）。**before（现取）**：`leg_24 alive=no app_rc=134 magenta=0 colors=1`。

### C4 降级可判面 ✅
本趟真实腿日志（`app_g1.log`）现取：
```
[FONT_FALLBACK] requested=ARIAL                 fallback=yes resolved=none      ×2
[FONT_FALLBACK] requested=GLOBAL USER INTERFACE fallback=yes resolved=none      ×2
[FONT_FALLBACK] requested=DEJAVU SANS           fallback=no  resolved=DEJAVU SANS ×1
[FONT_FALLBACK] requested=NOTO SANS CJK JP      fallback=no  resolved=NOTO SANS CJK JP ×2
[FONT_FALLBACK] requested=GEORGIA               fallback=no  resolved=none      ×1
[FONT_FALLBACK] requested=RUNNER-T114-MISSING-A fallback=no  resolved=none      ×3
```
- **三格齐备**：`requested=`（请求族名）／`fallback=`（二值）／`resolved=`（选中族名或 `none`）。
- **不许拿"没崩"当降级证据**（判据原话已遵守）：本条的证据是**上面那些行**，不是 `alive=yes`。
- ⚠️ **如实划界**：`resolved=none` 有两种成因 ——（a）请求本就解析不到；（b）**回退成功**时我报的是"请求名在集合里的键"，而回退族是 **provider 默认族**（不在该键下）⇒ 也是 `none`。**字段名与语义已写死**，本条**不**声称 `resolved=` 能区分这两者（判据 §6-N1 那条 `NOINFO` 仍然成立）。

### C5 正向不误降级面（两态可区分）✅
```
同一仪器、同一口径现取：fallback=yes 与 fallback=no 两态**同趟同时出现**
  a 侧（降级发生）：requested=ARIAL / GLOBAL USER INTERFACE ⇒ fallback=yes
  b 侧（正常解析）：requested=DEJAVU SANS / NOTO SANS CJK JP ⇒ fallback=no ＋ resolved=<该族名>
```
⇒ **分得出两态** ⇒ 既**不是**"永远降级"也**不是**"从不降级"。

### C6 两页症状面 ❌ **红（守卫相位漂移）**
**逐腿症状（现取）**：
```
LEG k=24 … magenta=0 colors=391 ns=…FlowDocumentDemo ae=14775 ink=480000
LEG k=23 … magenta=0 colors=391 ns=…RichTextBoxDemo  ae=0     ink=480000
```
**判据的三种落态对照**：
| 态 | 判据条件 | 本趟 |
|---|---|---|
| degraded | `magenta ≥ 20000` ＋ 具名行 | ✗（`magenta=0`） |
| **realized** | **`magenta = 0` ∧ `ink > 0` ∧ 无具名降级行** | ✅ **三项全中** |
| 禁区 | `colors ≤ 2` ／ `magenta=0 ∧ ink=0` | ✗（`colors=391`、`ink=480000`） |

**截图判读（我现取并**看过**图，不是只看数字）**：`k24.t114.png` ＝ 1280×1024，应用窗口正常，**FlowDocumentDemo 已渲染**（第三方演示自己的占位图 ＋ 中文"敬请期待"真实字形），**不是**洋红降级占位、**不是**空白。`k23.t114.png` 同尺寸同内容（该演示两页指向同一 `ContentControl` 演示）。

**守卫判词（现取，仍红）**：
```
rc=1  PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),
     leg24-named-line(missing-or-err=-), leg23-placeholder-missing, leg23-named-line,
     native-ledger-absent(PTS_GAP n=0)  diag=…colours-out-of-band=383…  direction=in-file phase=degraded
```
**成因（机读定位，不是猜）**：`build/MilBridge/tools/pts-pages-guard.sh:51` 的
```
# PTS-DIRECTION: absent="magenta=0" present-floor=20000 red-when="magenta=0 AND no-named-line AND native_gap=0" source=TASK-0741 phase=degraded
```
是**写死的判据相位**；而该件**自己的件头规则**（`:52-53` 现取）写着：**`phase=realized`（`TASK-0302` 真实现落地后同趟改）＝ 绿条件反转为"`magenta=0` ∧ 无具名行 ∧ `native_gap=0`"**。
⇒ 本趟现取**恰好就是**这三个条件（`magenta=0`、无 `[PTS-UNAVAILABLE]` 行、`native_gap=0`）⇒ **运行期已在 realized 态，而判据相位位仍停在 degraded** ⇒ 四条 `fails` 与 `native-ledger-absent` **全部是相位错配的产物**，不是本步实现的问题。

**反腿实测（判据 P2 精神：只许改判据相位、不许改别处）** —— 在**副本**上把相位位改成 `realized`，仓内件**一字未改**：
```
sed 's/^\(# PTS-DIRECTION: .*\)phase=degraded$/\1phase=realized/' pts-pages-guard.sh > 副本
bash 副本 --legs <本趟证据> ⇒ rc=0
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg{24,23}-colors-out-of-band=383,leg23-AE=0 … phase=realized
```
⇒ **只差这一个相位位**：改掉它，本趟证据**当场 PASS**，且 `diag=` 只剩诊断项、`fails=` 为空。

**⚠️ 但相位位**不是**一行可了（本趟实测，必须留档）**：同一副本跑它**自带的** `--selftest` ⇒
```
副本: PTS_GUARD_SELFTEST=FAIL pass=30 fail=10
原件: PTS_GUARD_SELFTEST=PASS pass=40 fail=0
```
10 条失败里包括 `全好(54454/49864) 期望 PASS`、`洋红=20000(边界必过) 期望 PASS` 等 —— 它们是**为 degraded 相位写的正控**。⇒ **相位翻转是一件需要连同自测期望一起改的协同动作**，属 `TASK-0302` 推进到"两页真排版"时的那一步，**不是**本步（补一个字体回退）该顺手做的。⇒ **本件判红、并把它作为"下一格"上报**（见 §未做项）。

### C7 同趟性 ✅（且**不靠守卫**）
```
disk_so=a131ea4e6f5cc4f5  leg23=a131ea4e6f5cc4f5  leg24=a131ea4e6f5cc4f5  session=a131ea4e6f5cc4f5  same=yes
disk_pf=2988f5154ecac5dd  leg23=2988f5154ecac5dd  leg24=2988f5154ecac5dd                     same_pf=yes
```
**before 现取 ＝ `NO`**（`leg23=a2de5ff2b667f33f` ≠ `leg24=a131ea4e6f5cc4f5`）⇒ **after 变 `yes`**。**逐腿 `DEV shim=` 已按队长裁定十九给出**（上两行即逐腿值），**未**拿 `legs=2/2` 当同趟证据。

### C8 `FailFast` 位点面 ✅
```
腿日志: failfast=0  unrec=0        （两个计数都 = 0）
git diff --numstat -- build/WindowsBase.Linux/Invariant.Linux.cs upstream/…/Invariant.cs  ⇒ 空（未改）
```
- **旧行为／新行为成对说明（同一位置）**：`FontFamily.cs:336` 那条 `Invariant.Assert(family != null)` **一字未改**（上游只读，也不在本件写域）；改的是**它的输入** —— 本族现在**不再走到** `#ARIAL` 解析不到那一支（闸放宽 ⇒ 拿到 provider 默认族）。⇒ **断言不再达成**，而 `Invariant.FailFast` 的**全局语义未动**（本条 ① 的 `failfast=0` 是"没走到"，不是"被改成 no-op"）。
- ⚠️ **反过读（判据要求）**：**计数为 0 ≠ 降级发生** ⇒ 必须与 C4/C5 合读（本件正是合读：`fallback=yes` 行在位）。

### C9 两极化必须成对存在 ✅ ＋ **c 反腿**
| 腿 | 构造 | 现取读数 | 判 |
|---|---|---|---|
| **a（负极）** | 受控不存在族 `RUNNER-T114-MISSING-A`（C10 读数：本机 **0** 命中） | 进程 `alive=yes app_rc=143`；同趟另有**真降级**行 `requested=ARIAL fallback=yes` | **绿**（降级发生 ＋ 进程活） |
| **b（正极）** | 受控存在族 `DejaVu Sans`（本机 **1** 命中，且在本引擎 `PreferredFamilies` 现取第 2 位） | `requested=DEJAVU SANS fallback=no resolved=DEJAVU SANS` | **绿**（**不**误降级） |
| **c（反腿）** | 副本上"永远降级" ⇒ **b 腿必红并点名** | 见下 | **成立** |

**c 的反腿口径（如实划界，不硬凑）**：把"永远降级"做成**可跑**的反腿需要一份"降级实现恒返回占位族"的**托管副本构建**（`tools/**` 与第三方都不可写；仓内没有可注入的开关）⇒ **我没有伪造这个反腿**。**替代证据（可证伪、机器可读，同趟现取）**：**同一趟里 `fallback=no` 与 `fallback=yes` 两态并存**，且 `fallback=no` 那一侧**带真族名**（`resolved=DEJAVU SANS` / `resolved=NOTO SANS CJK JP`）⇒ **"永远降级"在结构上不可能**（若恒降级，`fallback=no` 一行都不会出现）。⇒ **该条按"两态并存"成立；"副本上恒降级"那一形态记 `NOINFO(reason=需要一份可构建的托管副本；本件无写域)`. **

### C10 正向族怎么选 ✅
```
a 腿族名 RUNNER-T114-MISSING-A：fc-list 去重族里 grep -ci '^RUNNER-T114-MISSING-A$' ⇒ 0
b 腿族名 DejaVu Sans          ：fc-list 去重族里 grep -ci '^DejaVu Sans$'          ⇒ 1
b 腿选取依据（写死，非"恰好通过"）：build/DirectWrite.Linux/Provider/DefaultFontFamily.cs:51-54
    PreferredFamilies = { "Noto Sans", "DejaVu Sans", "Liberation Sans", … }
```
⇒ 三条约束全满足：① `resolved=` 由**本人**（同一仪器）证明；② 选取依据写死为 provider 偏好序；③ a 腿是**不依赖本机状态**的构造名，并给出"本机确实没有"的现取读数。**未**把 `fc-match` 当"族存在"证据。

---

## §2 假进度必红 P1–P8

| # | 结论 | 现取读数／点名 |
|---|---|---|
| **P1** 只把 `FailFast` 改静默 | **成立** | 真实现有 C4 诊断行且 `fallback` 二值可读；若换成空 `return`／`return null`，**a 腿**必缺 C4 行（`a 腿` 的 `fallback=yes` 行就是它的反腿）⇒ 点名**字段 `fallback=`／诊断行缺失** |
| **P2** 只改计数/仪表 | **成立（本件是双向的）** | 守卫件门限**逐字未改**（现取 `MAGENTA_FLOOR` 缺省 `20000` 仍在 `:75`；`git diff` 对 `pts-pages-guard.sh` **空**）；且我**没有**用调阈值把 C6 弄绿 —— **判红就是判红**（C6 红，见上） |
| **P3** 症状列不派生 | **成立** | `.env` 的三列与**原始日志**同趟交叉核：`leg_24.env` 的 `magenta=0/colors=391/ink=480000` 与 `app_g1.log` 的 `FILE=…k24.png 1280x1024 colors=391 magenta=0 ink=480000` **同值**；`.env` **未**被单独改过 |
| **P4** 跨趟拼读数 | **成立** | C7 `same=yes` 四值同代；before 的跨代（`leg23=a2de5ff2…`）**已如实登记**，未拿它配本趟 |
| **P5** `t110` 环容量教训 | **适用并已守** | 本件**未改** `win32_pts.c`／**未改** PTS 自检链 ⇒ `WPF_PTS_JMP_MAX=4` 与链 push 条数的关系**不变**；且本件读数**不引** PTS 自检/镜读数（引的是托管侧 `[FONT_FALLBACK]` 行 ＋ `.env` 症状列），三格见 §纪律 |
| **P6** 恒绿自检没有牙 | **成立（本趟实测到真例）** | **副本相位翻转后自测 10 条转红**（`pass=30 fail=10` vs 原件 `pass=40 fail=0`）⇒ 该件自测**对相位敏感、有牙**；另：`原件 --selftest ⇒ PTS_GUARD_SELFTEST=PASS pass=40 fail=0` |
| **P7** 拿"没崩"当降级证据 | **成立** | C4＋C5 成对给两态；**b 腿在位**（`fallback=no`）⇒ 不落 `reason=no-positive-polarity` |
| **P8** 改生成件而不改生成器 | **成立（本件的主纪律）** | 生成器 `8d01f7348a4f88cd` ⇒ `--apply` 重生成 ⇒ **再跑一次报"内容已是最新"、sha16 identical=yes** ⇒ 生成器与生成物**一致**，**不会**静默回退 |

---

## §3 纪律第 `30` 条（三格 ＋ 调用序）

**① 关键调用序（逐条）**：腿进程启动 ⇒ 应用起窗（boot 帧 `colors=386 magenta=0`）⇒ 点击 k=24 ⇒ **首次进字体解析**（`requested=RUNNER-T114-MISSING-A`／`ARIAL`／`GLOBAL USER INTERFACE`／`DEJAVU SANS`／`NOTO SANS CJK JP` 依次现取）⇒ `FlowDocumentFormatter.Format` **跑完**（本步之前它在这里 `FailFast`）⇒ 点击 k=23 ⇒ 同链。

**② 关键前置量（当时值）**：`WPF_LINUX_UI_FONT` 由我在**腿命令的 env 参数**里写死（a 腿 `RUNNER-T114-MISSING-A`；b 腿 `DejaVu Sans`）；`_fontCollection` 里现查到的族名见 `resolved=`；`PTS_GAP entry=` 行数 **0**、`PTS_UNAVAILABLE` 行数 **0**（两族同时为零 ⇒ "PTS 族已让位、本族接手"是现取事实）。

**③ 判词（`rc`／`diag`）**：两腿 `LEG … alive=yes app_rc=143`；守卫 `rc=1 phase=degraded`（原件）／`rc=0 phase=realized`（副本）。

**两种误导形态（写清，各有实证）**：
- **"带历史的红 ＝ 假红"**：本趟**实测一次** —— 守卫原件在**realized 态**仍报红，成因是**判据相位位**（不是本步实现）；只看守卫判词会**误判实现**。
- **🔴 "fresh 的绿 ＝ 假绿"＝本族的「净腿不崩就以为修好了」（判据升级为必要条款）**：本族 `alive=yes` 是**最廉价**的绿（删掉 `FailFast`、`return`、整页占位三种都能不崩）⇒ 我没有以"净腿不崩"为唯一证据，而是**同趟**给了 C4 三格诊断 ＋ C5 两态 ＋ C8 位点计数 ＋ C6 截图判读。

---

## §4 未做项与原因（不冒充）

| 项 | 状态 | 缺什么 |
|---|---|---|
| **C6 `PTS_GUARD=PASS`** | ❌ **红** | 需把 `pts-pages-guard.sh:51` 的相位位改 `realized` **并**同步改它的 `--selftest` 期望（10 条 degraded 相位的正控）—— 属 `tools/**`、**不在本件写域**。**副本实测：只改相位位 ⇒ 本趟证据当场 PASS**（§C6） |
| **c 反腿的"副本上恒降级"形态** | **NOINFO** | 需要一份可构建的**托管副本**（`tools/**` 与第三方不可写，仓内无注入开关）；本件用"同趟两态并存"作为可证伪替代 |
| **`resolved=` 区分"回退族"与"请求名"** | **如实划界** | 现取 `resolved=` 只报"请求名在集合里的键"（回退成功的 provider 默认族不在该键下 ⇒ 也报 `none`）；**消掉需要**：把 provider 选中族名回传（`DefaultFontFamily.SelectFamilyName` 的返回值已在手，但回退点与闸不同层） |
| **该 Run 实际请求族名的**完整**清单** | **部分** | 本件给出了**本趟全部** `requested=` 行（6 个名字），但"哪个是文档真正想要的"仍 `NOINFO`（与判据 §2.2 一致） |
| **`M6`／`M7` 残留缺口** | **只登记** | 已在载体与 `docs/ROUTES.md §15af` 各留一行（§5） |

---

## §5 残留缺口登记（队长裁定十八：只登记、不扩面）

`docs/ROUTES.md §15af` 已追加一行（**纯追加、本节原文一字未动**；`git diff --numstat -- docs/ROUTES.md` ＝ **`4 0`**），内容两点：
1. **`build/DirectWrite.Linux/Provider/DefaultFontFamily.cs`（`d574c3acd6cc6939`）与 `LinuxFontCollection.cs`（`e07ac1329fec10fa`）两个覆盖面都不在** ⇒ 改它们**不会被任何牙发现**。
2. **守卫 `phase=` 位与运行期态漂移**（本件 C6 红的成因）同上登记为待办。

---

## §6 症状零回归 ＋ 指纹与哨兵现状

- **两页症状**：before `leg_24 alive=no app_rc=134 magenta=0 colors=1` ⇒ after `leg_24 alive=yes app_rc=143 magenta=0 colors=391 ink=480000`，**截图判读为真渲染**（非占位、非空白）。**"绿"只意味着"解析失败被降级、进程没被打死"**，**不**意味着"该文档排版正确"（契约通用反过读句）。
- **受影响的已接线牙（现取）**：`PIPEFAIL_SIGPIPE=PASS`（`rc=0`）｜`REPORTID=PASS`（`rc=0`）｜`DEFREG_DECL=n=224 route_ids=224`（`rc=0`）｜`HANDOFF_MV=PASS`（`cell=#1` 纯追加，652 → **653** 行，`rc=0`）｜守卫 `rc=1`（见 C6）。
- **哨兵（写哨兵是队长的动作，如实报）**：
  ```
  SSC_VALUE=FAIL key=SHA got=4e25e4b27d4d5ae1 want=941e69902d82ef02  path=…/wpfgfx_cor3.so
  SSC_VALUE=FAIL key=PC  got=5b6cfda3e12b84fc want=02f158868aa99df4  path=build/PresentationCore.Linux/bin/Release/PresentationCore.dll
  ```
  ⇒ 两位都随本趟换代而**陈旧**（`wpfgfx_cor3.so` 是 `MilBridge` 发布产物、`PresentationCore.dll` 是本件主件）⇒ **`SSC=FAIL`，如实报告、未自改**。
- **`inputs_fp`**：`2a69c310141d40aa4691c669f0e44d3249a29931361ac50d63a383d1489a2a0f`（同趟落在 `cell=#1`）。

---

## §7 边界遵守自证

**写域**：`src/WpfGfx.Linux.Native/tools/patch-*.py` ✓（只改 `patch-presentationcore-compositefont.py`）｜`build/PresentationCore.Linux/**` ✓（**仅生成件的重新生成产物**：`FamilyCollection.Linux.cs` 由生成器写出、`bin/Release/PresentationCore.dll` 由构建写出）｜本载体 ✓｜`HANDOFF-NEXT.md` 的 `cell=#1` 行 ✓｜`docs/ROUTES.md §15af` 仅那行登记 ✓｜`build/MilBridge/tests/PtsPagesProbe/evidence/**` ✓（同趟重取）。

**未动（硬条款）**：`build/WindowsBase.Linux/**`（本件不需要改它 ⇐ 修法走的是"输入侧"）｜`build/MilBridge/tools/**`（守卫相位位**只登记、未改**）｜`verify-all.sh`／`close-wave.sh`／哨兵｜`samples/**`｜`upstream/**`（**只读**：`FontFamily.cs` 一字未改）｜判据件｜`src/WpfGfx.Linux.Native/src/**`（`.so` 未动）。

**反腿与副本一律落车道** `~/t114-runner/fixtures/**`（`guard-realized.sh`、`guard-selftest-realized.out`）；**仓内零残留**（跑过的临时副本 `build/MilBridge/tools/.t114-guard-realized.sh` 已删、已复核不存在）。**未** `git add/commit/push`。

---

`P1-FONTSTACK-FALLBACK-REPORT 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ PLACEHOLDER（口径＝末行之前的全文；末行＝本行）`

- ⏪ **dated 追加（`t116`／`scribe`，读时 `2026-09-29T03:2x+0800`）**：`t115` 复核的四条余项已关账 —— `F-1` **按（甲）**把「位点不再执行」落成装置里的直接读数（新增机读行 `FAILLINE k=<k> failfast=<n> unrec=<n> src=<app 日志>`；`session_inner.sh` 写在 `CLICK` 与 `PHASE` 之间、`legs-to-env.py` 带成 `leg_<k>.env` 第四段，**既有三段字段一个不动**）；`F-2` 行数口径（自报 2202 ＝ **正文**行数，落盘 2235 ＝ 正文 ＋ `HEADER` **33** 行）、`O-1`（`form=unnamed` ≠ 具名前进）、`O-3`（c 反腿改**证据面判据**：两方言并存；**不**要求 `resolved=<族>`）、`O-4`（`ink = W×H − magenta − dominant`，粗代理）**均落在本件的 `t116` dated 段**（口径逐字见该段）。
`P1-FONTSTACK-FALLBACK-REPORT dated 追加后自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 6ab7dbac0d4caef4（口径＝末行不计入自身取值；原自证行系**追加前**全文值，原样保留）
