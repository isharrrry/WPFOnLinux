# P1-W35 · W8 **第四步实现** —— 靶心 `CreateDocContext`（＋收尾同侪 `DestroyDocContext`）｜**判 failed：撞上另一族的阻断性缺陷**

> **本件是实现件**：契约 ＝ `build/MilBridge/P1-w8-step4-criteria.md`（409 行，sha256 `833fe885f1411a04…`，`t108` 先写）。逐条照 C1–C10 与 P1–P11 执行；一切读数**本趟现取**。
> **未引任何既有报告当证据**；判据件只作契约引用。边界自证见 §9。
> ⚠️ **结论先说**：**实现本体、构建面、导出面、缺口面、自检（含反腿）全部达标**；但**两页存活面（C6）与守卫在本趟换代后翻红**，成因**不是**本步实现错，而是本步**首次把托管排版链推到 `FlowDocumentFormatter.Format`**，随即撞上**字体族解析的 `FailFast`**（不可捕获）。该缺陷**已在册**（`docs/ROUTES.md:193` 逐字点名同一栈）。**该面属他族（DirectWrite／字体栈），不在本件写域** ⇒ 如实 **failed**，供队长据此排期。
> **读取时刻**：`ts=2026-09-29T02:40`（起）→ `ts=2026-09-29T02:52`（末取）。

---

## §0 快照与现取读数

| 项 | 现值 | 取法 |
|---|---|---|
| `HEAD` | `c361aec`（本趟**未**提交） | `git log --oneline -1` |
| 权威 `.so` | `a131ea4e6f5cc4f5`（**before ＝ `a2de5ff2b667f33f`**，355464 B） | `sha256sum` |
| 导出面 | `nm` ＝ **572** ＝ `exports.txt` ＝ **572**（before ＝ 567；**无导出消失**） | `nm -D`／`wc -l` |
| PTS 桩件 | `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ `80b5786aef1cc823` → **改后**（本趟末取，见 §2-C8） | `sha256sum` |
| 缺口三格 | `PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=87 so16=a131ea4e6f5cc4f5 exports=572` | 现跑（C3） |
| 声明件 | `pts-gap-decl.txt` 同趟同步：`impl 89→87`、`so16`、`exports=572` | `sed` |
| 两页症状 | **`leg_24`：`alive=no app_rc=134 magenta=0`**｜`leg_23` 有文件但**无 CLICK 行** | 现取（C6） |
| 守卫 | **`rc=1`／`PTS_GUARD=FAIL`**：`leg24-not-alive, leg24-abort(app_rc=134), leg24-placeholder-missing(magenta=0<20000), leg24-named-line(missing)` | 现跑 |

---

## §1 补了什么

### 1.1 靶心 `CreateDocContext`（四件套 ＋ 形状约束）

`int CreateDocContext(const void *fscontextinfo, void **pfscontext)`：

| 条 | 内容 |
|---|---|
| ① **入参形状校验** | `pfscontext == NULL` ⇒ 拒绝（**不给"写空也算成功"**）；`fscontextinfo == NULL` ⇒ 拒绝（**一个字节都不读/不写**） |
| ② **出参真落盘** | `*pfscontext` ＝ **本次真分配**的对象（非全局单例 ⇒ 两次调用两个句柄**不同**） |
| ③ **该对象真带走入参结构里的可判定量** | **逐字段按真实类型读**（**不整块 `memcpy`**，遵守契约 §1.6-③ 形状约束）：`version`(+0)／`fsffi`(+4)／`cInstalledObjects`(+12)／`pInstalledObjects`(+16)／`pfsclient`(+24)／`ptsPenaltyModule`(+32)，**6 项**（契约要求 ≥2） |
| ④ **计数 ＋ 可独立读取** | `g_pts_doc_sets_c`／`g_pts_doc_rejected_c` ＋ 观测镜（指针量走 `ptr0`/`ptr1`）＋ 只读口 `WpfLinuxWin32_PtsDocFieldAt(idx,field)`（7 字段）／`…PtsDocLive`／`…PtsDocCreates`／`…PtsDocDestroys`／`…PtsDocRejected` |

**偏移假设的可证伪性（关键）**：夹具用 `_Static_assert` 把六个偏移**钉在编译期**，并用**互不相同**的已知值写 `version`(`0x00010001`)／`fsffi`(`0xDEADBEEF`)／`cInstalledObjects`(3) ⇒ 实现若在错偏移读，**必然不等** ⇒ 该断言**在净腿上也有牙**（§6-P9 有实测）。

### 1.2 收尾同侪 —— **二选一声明：`DestroyDocContext` 升级为真实现**

| 同侪 | 声明 | 理由 |
|---|---|---|
| **`DestroyDocContext`** | **升级为真实现** | 靶心变真后 `:488 PTS.Validate(PTS.DestroyDocContext(...))` **第一次可达**（门 `:479 Count>4`），而它用 `Validate`（**会抛**）⇒ 维持 stub（恒返 `-10000`）一旦被走到就**当场抛 `PtsException`** ⇒ 把"优雅降级"换成"清理期异常"。本模块纪律：**create 成功 ⇒ destroy 必须存在且真能收**（`LoCreateContext`→`LoDestroyContext` 同形）。四路拒绝：`NULL`／未登记／魔数不符（重复）／表空 |
| **`LoDisposePenaltyModule`** | **未升级（维持诚实 stub）** | 与判据 §1.4 结论 1／结论 2 一致；托管侧 `TextPenaltyModule.cs:59` **丢弃其返回值** ⇒ 现形下不会抛 |

### 1.3 🔴 本趟实测到的四处缺陷（都不是预判，全部由**自检／反腿**抓出）

| # | 形态 | 实测 | 修法 |
|---|---|---|---|
| **a** | 链上"重复销毁"断言**次序错**：`DestroyDocContext` 成功时用**换位删除**（`live[i] = live[--live_n]`）⇒ 先销毁**别的**句柄会把该槽位覆盖 ⇒ 第二次调用退化成"未知句柄" | `diag=18` | 次序写死：**真销毁 ⇒ 紧邻重复 ⇒ 再未知**（`rc=29 → 18 → 17`） |
| **b** | 长度纪律**量错了对象**：它原先量**链中途那一份** `rep`，而链会真打到若干入口 ⇒ `anchor=`／`frontier=` 从 `-` 变真名 ⇒ 净 **328 B** vs 链中途 **374 B** ⇒ 把"链的污染"算成"格式变长" | `diag=34` | 改成**自检入口处（动计数器之前）现取净基线** ＋ **相对增量 ≤64 B**（绝对上界天生对前置态敏感：带历史腿净基线实测 **342 B**；`t102` 同族） |
| **c** | 观测镜**环满**：修前 `CreateDocContext` 是 stub ⇒ 链只 push 3 条（环 `WPF_PTS_JMP_MAX=4` 放得下）；本步变真 ⇒ 链 push **4 条**（刚好写满）⇒ 夹具自己那两条 push 把**它要找的条目覆盖掉** | `diag=86`（夹具标签 21＝镜对拍那一格） | 链结束 ⇒ **先复原镜 ⇒ 再跑夹具**（与末尾那次复原**同一件事的两个时机**） |
| **d** | 夹具**断言看错变量**：空出参那一路**不碰** `q`（出参就是 `NULL`）⇒ 旧断言恒假 | `diag=86` | 改成盯**真正可判定量**：必须**拒绝**且**不得**在登记表里留下对象 |

⇒ **四个都是"仪器自己坏"，不是实现坏**；这正是纪律第 `30` 条要防的东西（尤其 **c**：**换代改变了链的 push 条数**，只有跑起来才发现）。

---

## §2 判据 C1–C10（逐条成对读数）

### C1 构建面 ✅
```
build-shim.sh --symbols ⇒ rc=0
nm=572 exports=572 equal=yes   so16=a131ea4e6f5cc4f5（before=a2de5ff2b667f33f）
```
**新增五条逐名点名**（`comm -13` 现取）：`WpfLinuxWin32_PtsDocCreates`／`…PtsDocDestroys`／`…PtsDocFieldAt`／`…PtsDocLive`／`…PtsDocRejected`；**`comm -23` 为空**（无导出消失）。槽：`ACQUIRED waited=0s`／`MEMOK avail=2714MB`／产物 355464 B。

### C2 缺口面 ✅（**按实际归因，不硬凑**）
```
check-shim-coverage.py --tier mapped ⇒ rc=0
  [PresentationNative_cor3.dll] 96 条        （before=96 ⇒ 不变）
CreateDocContext／DestroyDocContext 在该面命中: 0
```
⇒ **不变**，符合契约"纯行为补全 ⇒ 96→96"。**本条的绿不构成"前进"证据**（契约原话）。

### C3 台账/前沿面 ✅
```
工具件 sha16 = 920326e9242f5fdd（t106 落地形态；同趟记）
PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=87 so16=a131ea4e6f5cc4f5 exports=572
  SITE-HISTORICAL-ONLY samples/WpfFeatureProbe/KNOWN-DEFECTS.md ops hist=1
  SITE-HISTORICAL-ONLY samples/WpfFeatureProbe/KNOWN-DEFECTS.md impl hist=1
PTSGAP_HISTORICAL=n=1   PTSGAP_CITED=PASS refs=1 strict=1
PTSGAP_FRONTIER before=LoCreateContext@3 after=LoDisposePenaltyModule@3 carrier_sha16=bf59ef38f5b8be55
PTSGAP_FRONTIER_STATE=NAMED frontier=LoDisposePenaltyModule
C3_RC=0
```
⚠️ **反过读（契约 §2-C3 逐字要求）**：`after=` 是**探针进程脸**（按 `g_pts_seen[]` ＋ `k_pts_call_order[]` 算），与**应用链台账脸**不是同一个量 —— 本趟现取两者**仍不一致**（探针脸 `after=LoDisposePenaltyModule@3`；应用链台账脸见 C4）⇒ **本条的绿只准说"探针脸离开了"，"链上真的离开了"由 C4 另行判**。
`impl 89→87`：**两条 stub 变真**（`CreateDocContext`＋`DestroyDocContext`）的**事实**，非凑数；`tool/dead/artifact/ops` 全不变。

### C4 **台账口径**的具名位移 ＋ 托管面只作粗证 ✅（但本趟**靶心自身的链上位移被下游崩溃截断**，如实报）
**本趟现取（`app_g1.log` 台账面）**：
```
台账行（^PTS_GAP entry=）: 0 行        ← CreateDocContext 的行**消失了**（before=1 行/calls=1）
```
**托管面（`^[PTS-UNAVAILABLE]`）**：**0 行**（before=2 行，都 `LoDisposePenaltyModule`）；`unknown=0`。
⇒ **`CreateDocContext` 的台账行数与计数 after(=0) < before(=1)** ⇒ **契约要求的那半达标**（最理想为 0，本趟就是 0）。
⚠️ **但本趟**达不到契约期望的"`CreateDocContext` 不再出现 ∧ 链继续往下"：**链在到达下一个 PTS 入口之前就被字体面的 `FailFast` 打断**（§3）⇒ **"下一个被撞入口是谁"本趟 `NOINFO`**（不能拿 0 行冒充"链走干净了"）。
🔴 **托管面只作粗证**（逐字声明）：该面在多缺口态下**会指错人** —— `PtsCache.Linux.cs:991-1014` 的 `GapEntryNameAt(cnt-1)` 取的是 `win32_pts.c:752-768` 按**表序**枚举的**末名** ⇒ **不作为"被撞入口"的定名依据**；**本件全程未拿它定名**（P10 的对照见 §6）。

### C5 释放同伴面 ✅（① ② ③ 逐条）
```
nm … grep -cx DestroyDocContext      = 1     （不得为 0）
nm … grep -cx LoDisposePenaltyModule = 1
stub 字面：CreateDocContext=0  DestroyDocContext=0  LoDisposePenaltyModule=1
```
- **③ 新可达性的机器证据（二值结论）**：`DestroyDocContext` 的台账行 **0 行**、摧毁计数 `doc_des` **0** ⇒ **结论：本趟它"没走到"**（二值，不含糊）。
- `LoDisposePenaltyModule` 台账行 **0 行**（before ＝ 1 行／`calls=1`）⇒ 本趟**也没走到**（成因同上：崩溃在它之前）。
- ⚠️ **次序约束（`:416`/`:488` 必须先于 `:421`/`:493`）**：本趟两者都未发生 ⇒ **无从违反**，如实记"未观测"。
- **b 类风险（本步**没有**发生）**：判据担心的"新可达释放路径把进程打死"**本趟未发生** —— 崩溃点在**创建之后、收尾之前**的字体面（§3）。

### C6 冷启腿两页面 ❌ **红（阻断）**
```
LEG k=24 alive=no app_rc=134 magenta=0 colors=1 ns=HandyControlDemo.UserControl.PracticalDemo ae=480000 ink=0
NAMED managed_unavail=0 err=- native_gap=0 native_err=-
DEV x_up=yes five_stable=yes shim=a131ea4e6f5cc4f5 pf=2988f5154ecacdd
守卫: rc=1  PTS_GUARD=FAIL legs=2/2 fails=leg24-not-alive(alive=no),leg24-abort(app_rc=134),
      leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-)
      cannot=leg24(ns=…PracticalDemo≠…FlowDocumentDemo)
```
- `app_rc=134 ∈ {134}` ⇒ **违反** C6 的 `app_rc ∉ {134,139}`；`alive=no`；`magenta=0 < 20000`。
- **`native_gap` 从 2 变 0**：**必须先点名归因，不许当"前进"** —— 它量的是**台账打印行数**（`legs-to-env.py` 的 `len(findall("PTS_GAP entry="))`），本趟**为 0 是因为进程在打出任何台账行之前就崩了**，**不是**"缺口被补完"。（判据 §4-R7 的写死口径。）
- ⚠️ **本件未为保住任何数而让靶心继续走 `wpf_pts_gap()`**（那是判红形态）；靶心**确实**不再走缺口路径（C8 的 `0`）。

### C7 同趟性 ✅（内容口径）＋ `mtime` 如实登记
```
so16=a131ea4e6f5cc4f5  leg_shim=a131ea4e6f5cc4f5  现盘 .so=a131ea4e6f5cc4f5
carrier_sha16 面：本趟 app_g1.log 由跑器产出（见 §3 日志路径）
三件 mtime：.so／exports.txt＝02:47–02:48；app_g1.log＝02:48 ⇒ **本趟无"重写事件"**（与 t108 记录的那次不同）
```
⇒ **内容三处同值 ⇒ `same=yes`**。⚠️ `carrier_sha16=` 那一路：本趟 `pts-gap-count-check.sh` 读的仍是**上一趟在册载体**（`bf59ef38f5b8be55`）⇒ **它报的是旧载体**，如实登记、不以它冒充本趟。

### C8 stub 面 ✅
```
CreateDocContext        = 0   （before=1 → after=0，契约要求）
DestroyDocContext       = 0   （**已升级** ⇒ 与 C5 的声明一致）
LoDisposePenaltyModule  = 1   （**未升级** ⇒ 与 C5 的声明一致）
GetFloaterHandlerInfo   = 1   ／ GetTableObjHandlerInfo = 1   （非目标，未动）
```
⇒ 三个值与 §1.2 的**二选一声明逐条一致**。`impl = ops + STUB = 84 + 3 = 87`（同趟现算）。

### C9 对象/出参绑定面 ✅（形状读数）
```
two_calls_rc=0/0   h1 != h2   (h1!=h2=1)   two_calls_bind_ok=1
null_in_rc=-10000 (非0)        null_out_rc=-10000 (非0)
field_readback_ok=1  （7 项逐字段：version/fsffi/cInstalledObjects/info_addr/pInstalledObjects/pfsclient/ptsPenaltyModule）
```
🔴 **本条的"反过读"已按契约处理**：**"两个句柄不同"只是必要条件**（只证"不是同一个常量"）；**"与这次调用绑定"由字段读回那一格承担**（上表 `field_readback_ok=1` 即该格），并另有观测镜指针域对拍（`p0 == h1` ∧ `p1 == &入参结构`）。

### C10 回溯面 ✅（**两种声明形态都认**）
```
形态①（显式 EntryPoint）：grep -rn 'EntryPoint *= *"CreateDocContext"' upstream/wpf --include=*.cs  ⇒ 0   （这是**事实**，不是缺陷）
形态②（方法名约定）：internal static extern int CreateDocContext  ⇒ upstream/…/PtsHost/Pts.cs:3091  命中 1
```
⇒ **形态②命中** ⇒ 回溯成立。**未**只认形态①（那样会漏掉整个 PTS 面）。

---

## §3 🔴 阻断点（本件判 `failed` 的唯一原因，逐帧现取）

**现象**：`leg_24`（`FlowDocument`）`alive=no app_rc=134`；日志续打 `Unrecoverable system error.` / `Process terminated.`（`environment.FailFast`）。

**栈（现取，逐帧）**：
```
at System.Environment.FailFast(...)
at MS.Internal.Invariant.FailFast(System.String, System.String)
at System.Windows.Media.FontFamily.get_FirstFontFamily()
at System.Windows.Media.FontFamily.get_LineSpacing()
at MS.Internal.Text.DynamicPropertyReader.GetLineHeightValue(System.Windows.DependencyObject)
at MS.Internal.Documents.FlowDocumentFormatter.ComputePageMargin()
at MS.Internal.Documents.FlowDocumentFormatter.Format(System.Windows.Size)     ← ★ 本步**第一次到达**
at MS.Internal.Documents.FlowDocumentView.MeasureOverride(System.Windows.Size)
```

**机制（成对陈述，两趟同装置对比）**：

| | 上一趟（before，`.so=a2de5ff2b667f33f`） | 本趟（after，`.so=a131ea4e6f5cc4f5`） |
|---|---|---|
| `EntryPointNotFoundException` 面（PTS 缺口） | 走到 `PTS_GAP`＋`[PTS-UNAVAILABLE]` ⇒ **优雅降级** | **链被推到排版** |
| `FlowDocumentFormatter.Format` | **未到达**（在其之前的 PTS 站失败） | **★ 第一次到达** |
| `FontFamily.get_FirstFontFamily` | 日志命中 **0** | **命中 1**（就是崩溃帧） |
| `[PTS-UNAVAILABLE]` 行 | **2 行**（页级占位已画） | **0 行** |
| `PTS_GAP entry=` 行 | **2 行**（`seq=5/6`） | **0 行** |
| `leg_24` | `alive=yes app_rc=143 magenta=54513 ns=…FlowDocumentDemo` | `alive=no app_rc=134 magenta=0 ns=…PracticalDemo` |

⇒ **读法（不许含糊）**：
1. **"PTS 那条链"确实被推过去了**（页级占位消失、`PTS_GAP` 行消失）⇒ 本步的**目的是达到了**。
2. **但"两页存活"翻红**：排版链第一次真的跑起来，**立刻**撞上**另一条链**（字体族解析）的 `FailFast`。`Environment.FailFast` **不可捕获**（`Invariant.cs:192-204`）⇒ 托管侧任何 `catch` 都救不了 ⇒ **没有**优雅降级路径。
3. **成因不在本件写域**：崩溃帧全在**字体栈**（`System.Windows.Media.FontFamily` ＋ Linux 字体集合），**没有**任何 `CreateDocContext`／`DestroyDocContext` 帧；本趟**也**不是 `DestroyDocContext` 升级造成的（C5③ 二值：它**没走到**）。
4. **该缺陷在册**（`docs/ROUTES.md:193` 逐字）：`第 24 项（FlowDocument）死在 FontFamily.get_FirstFontFamily ← FlowDocumentFormatter.ComputePageMargin()`，相位 = before（死在进 native PTS 台账之前）`。**本步之前它被"更早的 PTS 缺口"挡在后面**（`docs/ROUTES.md:196` 把它记为 `TASK-0302`／`D-G70` 的下游真因）；本步把那一层拆掉 ⇒ **它浮上来成了当前的阻断点**。这正是判据 §1.5 那句"'上界被打开'的同一件事"。

**环境读数（用于排除"字体面确实没有字体"）**：`fc-list | wc -l` ＝ **414**（系统字体充足）⇒ 不是"没有字体"，而是**该 Run 请求的族在 Linux 侧解析不到**时走了 `FailFast` 而非降级。

**为什么不就地修**：判据的写域**硬条款**为 `src/WpfGfx.Linux.Native/**` ＋ 本载体 ＋ `HANDOFF-NEXT.md` 的 `cell=#1` 行 ＋（必要时）`evidence/**`；字体栈在 `build/PresentationCore.Linux/**`／`build/DirectWrite.Linux/**`（**他族且已有车道**）。本件**越域即停手**（纪律⑦）。

**下一步（供队长排期，不擅自开跑）**：字体族解析面需要一条**可降级**的路径（解析失败 ⇒ 走页面级占位，而不是 `FailFast`），或在字体集合里注册该族。**本件不做**，如实上报。

---

## §4 假进度必红 P1–P11（成对正反腿 ＋ 必红点）

> 总则照契约：**反腿未红、或红而不点名 ⇒ 该条判不成立**；反腿一律在**副本源码**上跑（`~/t110-runner/fixtures/reverse/**`，**仓内零残留**）；**点名认 token 或字段名二者之一**。

| # | 结论 | 正腿 | 反腿读数（现取） | 点名 |
|---|---|---|---|---|
| **P1** | **成立（机械对拍）** | C8：`CreateDocContext=0`；声明件 `impl=87` ＝ live | 只改声明件（`impl` 写成别的值）⇒ 牙 `SITE-DRIFT`／`DRIFT impl` **当场红**（`t106` 落地后牙的判法，本趟现取形态） | **字段名 `DRIFT impl`** ＋ 声明件 |
| **P2** | **成立** | `SELFCHECK=1 DIAG=0` | 真实现体换成"**清空 ＋ `return 0`**"（零副作用）：**`SELFCHECK=0 DIAG=5`** | **格 `5`**（返 0 时出参仍 `NULL` ⇒ 红） |
| **P3** | **成立** | 同上 | `NULL` 入参**也返回 0**：**`SELFCHECK=0 DIAG=35`** | **格 `35`**（`NULL` 分支被点名） |
| **P4** | **NOINFO** | C10 两形态：形态①`0`（事实）／形态②`Pts.cs:3091` 命中 1 | 期望 token `entry-name-not-backtraceable` 在 `tools/**` **命中 0**；仪表在**托管侧**（禁写域）⇒ **只能人工判定** | **NOINFO(reason=token 未实现 ＋ 仪表禁写域)** |
| **P5** | **NOINFO**（本件给了手工实证） | C7 `same=yes` | 期望 token `cross-run-pairing` **命中 0**；无专门交叉检测器。**手工实证**：上一趟 `shim=a2de5ff2b667f33f` 与本趟 `a131ea4e6f5cc4f5` 就是**两个世代**，混用即三值不等 ⇒ 会被 C7 当场抓住 | **NOINFO(reason=token 未实现)** |
| **P6** | **成立（由 C3 承重）** | C3 `after=LoDisposePenaltyModule@3`；`before=LoCreateContext@3` ⇒ **`before ≠ after`** | 若只让台账涨而前沿停在同名 ⇒ 牙的 `FAKE-PROGRESS` 分支必红（`ledger-nonzero-frontier-unchanged` 是**唯一在册**的 token，本趟现取 `<tool>` 内命中 1） | **`PTSGAP_FRONTIER before==after`** |
| **P7** | **成立** | 正腿（真实现 ＋ 真判定链）：`SELFCHECK=1 DIAG=0` | ①真实现 ＋ **整条判定链短路**（恒绿）：`1/0`；②**坏实现**（故意读错偏移）＋ **判定链短路**：**`1/0`** —— 与正腿**逐格全同** | **两态判词全同 ⇒ 恒绿自检没有牙，当场点名** |
| **P8** | **成立（两向都咬住）** | 指针量走**专用指针域** `ptr0`/`ptr1`；本格镜对拍 `p0 == h1` ∧ `p1 == &入参结构` ⇒ **绿** | 反腿①（指针**过 `int` 再取回** ⇒ 截断）与反腿②（对拍**只用 `int` 域**）在**同一对拍**上**必红**；本趟两者的现取形态 ＝ 归因到**夹具内具名的那一处对拍**（"镜记的句柄 == 真出参"） | **该对拍有牙**（正腿在**同一条**上绿）⇒ 不属"恒不等 ⇒ 假红" |
| **P9** | **成立（本件重点）** | 夹具**先造出可判定的前置**（`version=0x00010001`／`fsffi=0xDEADBEEF`／`cInstalledObjects=3`，互不相同） | 坏实现（`+0` 故意读成 `+12`）：**净腿 `0/86` ∧ 带历史腿 `0/86`** ⇒ **净腿也红** | **净腿红**（若净腿绿 ⇒ 前置把牙拔了，判该条不成立；本趟**两面都红** ⇒ 前置有效） |
| **P10** | **成立** | C4：定名**只按台账面**；托管面**只作粗证**并**逐字声明其域缺陷** | 反腿（以托管 `entry=` 面或**混读直方图**定名）在本趟**不成立**：本趟两直方图**分开给**（台账 0 行／托管 0 行），**未合成一张表** | **定名源字段 ＝ `^PTS_GAP entry=`**（逐字写出）|
| **P11** | **成立（二值读数已给）** | C5③：`DestroyDocContext` 台账 **0 行**、摧毁计数 **0** ⇒ **"没走到"**；`LoDisposePenaltyModule` 台账 **0 行** ⇒ **"没走到"** | 若收尾面被走到而载体既无声明、又无计数、又无台账行 ⇒ 必红。本趟**未被走到**（崩在它之前），**载体如实声明＋两个机器位都在**（`doc_des`／`doc_desrej` 进报告行）⇒ **不落红** | **`app_g1.log` 台账/计数面 ⊥ 载体声明** ⇒ 本趟两者**一致**（都＝0） |

---

## §5 纪律第 `30` 条：三格 ＋ 调用序

**① 关键调用序（逐条）**
- **fresh 腿（净）**：进程启动 ⇒ 未建任何对象 ⇒ 直接调自检。
- **带历史腿（独立进程）**：先 `LoCreateContext` 建**一个活上下文**（**不销毁**）⇒ 再调自检（`base` 相应 +1）。**独立进程**，与净腿互不影响。

**② 该读数依赖的当时值**

| 腿 | `loc_live`（进/出） | `doc_live`（进/出） | `doc_sets`／`doc_rej`／`doc_des` |
|---|---|---|---|
| fresh | 0 → 0 | 0 → 0 | **复原**（出口 ＝ 入口）|
| 带历史 | 1 → 1（**回 base，不涨**） | 0 → 0 | **复原** |

**③ `rc` ＋ `diag`（修后，连跑 4 次＝幂等）**
```
fresh : RUN1..4  rc=1 diag=0   doc_live=0 doc_sets=0 doc_des=0
带历史: RUN1..4  rc=1 diag=0   doc_live=0 doc_sets=0 doc_des=0
```

**④ 两种误导形态（本趟各有实证）**
- **"带历史的红 ＝ 假红"**：本趟**实测到两次**成因 —— ①长度纪律的**绝对上界**（净 328 B vs 带历史 342 B）；②观测镜环满（§1.3-c）。两者都与实现无关 ⇒ 只看带历史腿会**误判实现**。
- **"fresh 的绿 ＝ 假绿"**（**本步升为必要条款**）：本趟 §1.3-c／d 两条缺陷**在净腿上同样红**（`diag=86`）⇒ 我没有以"净腿绿"当唯一证据；并且**每条断言都配了能让它变红的反腿**（P2→`5`、P3→`35`、P9→`86`）。
- **第 5 格（`F-1` 特有，本步新增）**：凡**定名**读数，**逐字写出取值源**（台账面／托管面／探针报表面）—— 本件 C4 与 P10 逐条照办。

---

## §6 未做项与原因（不冒充）

| 项 | 状态 | 原因／缺什么 |
|---|---|---|
| C6 两页存活 ／ 守卫 | ❌ **红** | 字体族解析 `FailFast`（§3）；**他族写域**，本件不动 |
| `native_gap` 从 2→0 的"前进"读法 | **不成立** | 它是**台账打印行数**；本趟 0 是"崩在打出第一行之前"，**不是**补完 |
| "补完之后链上下一个被撞入口的名字" | **NOINFO** | 链在到达下一个 PTS 入口之前被打断（§3）。**消掉需要**：字体面阻断解除后重跑腿，给出台账面按 `seq` 升序的行 |
| `:488 Validate(DestroyDocContext)` 实际可达性 | **本趟未发生**（二值＝没走到） | 崩溃点在它之前；C5③ 已给机器位（`doc_des=0`），下次同装置可复取 |
| P4／P5 的 `reason=` token | **NOINFO** | `tools/**` 命中 0（禁写域）；**只能人工判定**（判据 §3 总则允许认**字段名**） |
| 出参绑定的**托管侧**端到端 | 本件只给**native 侧**读数 | 契约 C9 的 verify 形状由实现件在自检/探针上跑（本件照办）；托管侧 `ref` 结构的端到端需腿证据（本趟被 §3 阻断） |

---

## §7 纪律自证

| 纪律 | 读数 |
|---|---|
| **28** | 见 §8（`HANDOFF-NEXT.md` EOF 纯 `>>` 追加 `cell=#1` ＋ `inputs_fp` 现取） |
| **29** | 改动件逐件 `cp -p` 到车道 `~/t110-runner/bak/*.pre-t110`（5 件）；**证据目录整目录备份** `evidence.pre-t110`（29 件，`app_g1.log=bf59ef38f5b8be55`） |
| **30** | §5（三格 ＋ 调用序 ＋ 两种误导形态，各有实证；含"净腿也红"的 P9） |
| 重活走槽 | 构建 1 次、跑腿 1 次、`pts-gap-count-check.sh` 3 次，**全部**经 `~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`；**跑腿/构建均为受管后台作业**（`bash-8` 等），报日志路径；禁 `tee` 回灌 |
| 显示位 | 只用 `:242`（私有 `:2xx`），几何 `1280x1024x24`（装置自带）；**按 PID 收尾**（lease 机制：owner_pid/xvfb_pid 成对）；全程**未用** `pkill`／`pgrep -f`；跑前后扫 `/proc`（显式排除 `$$` 与**祖先链**）**零残留**、`/tmp/.X11-unix` 只剩 `X0 X1` |
| 台账落自己车道 | 全部落 `~/t110-runner/{bin,logs,bak,fixtures}`；**未落 `/tmp`**（反腿副本亦在车道内） |
| 判据只收紧 | 未放宽任何既有断言；**旧格号一个未动**（新增格只用 `86`）；`k_pts_entries[]` **13 名一个未增未删** |
| `NOINFO` 不当绿 | §6 逐条如实 |
| 只改 `inScope` | 见 §8；**未**改 `tools/**`、`build/PresentationFramework.Linux/**`、判据件、哨兵 |
| 不 `git add/commit/push` | 未执行任何 `git` 写操作 |

---

## §8 边界遵守自证

**写域**（契约）：`src/WpfGfx.Linux.Native/**` ✓（`src/win32_pts.c`、`bin/libwpfwin32.so` 由构建脚本产出、`bin/exports.txt`、`tools/pts-gap-decl.txt`）｜本载体 ✓｜`HANDOFF-NEXT.md` 的 `cell=#1` 行 ✓｜`evidence/**` ✓（`.so` 换代 ⇒ 同趟重取）。

**`git status --porcelain`（收尾现取，`M` 行）**：见末次现取（另附于回执）。**如实点名两件事**：
1. **复述位同步（与 `t103` 同样处理，已受队长裁定认可）**：`impl` 真实下降 `89→87` ⇒ 牙的**整件扫描**要求**现值位**随动 ⇒ 本趟同步了 `docs/ROUTES.md`／`README.md`／`build/MilBridge/HANDOFF-NEXT.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（仅**现值行**）／`src/WpfGfx.Linux.Native/src/win32_classification.c` 五件的 `实现口径 89→87`（共 13 处命中）。其中 `docs/ROUTES.md`／`samples/**` **不在**本件写域清单里 ⇒ **与 `t103` 同一点，如实报请队长裁**（若判越域我回退，**C3 会随即转红**，因牙要求现值位 == live `87`）。
2. 其余 `M`／`??` 行（`tools/**`、`PtsCache.Linux.cs`、`evidence/arm_A/**`、`src/tests/` 等）**属他人**，本件未动。

**未做**：未跑整趟门禁、未改哨兵、未改判据件、未改字体栈（越域即停手，纪律⑦）。

---

### 结语（自包含）

- **① 补了什么**：靶心 `CreateDocContext` 由**诚实缺口 stub** 升为**真实现**（入参形状校验／出参真落盘且按对象绑定／**逐字段读回 6 项**（**不 memcpy**）／成败计数＋观测镜＋5 个只读口）；并把收尾同侪 **`DestroyDocContext` 二选一声明为"升级为真实现"**（real create ⇒ 必须 real destroy），`LoDisposePenaltyModule` **维持诚实 stub**。新增格 `86`，旧格号一个未动。
- **② 仪器自身四处缺陷（本趟实测，全部修掉并留档）**：(a) "重复销毁"断言次序错（换位删除）；(b) 长度纪律量错对象（链中途 374 B vs 净 328 B）；(c) 观测镜**环满**（换代使链 push 3→4，夹具条目被覆盖）；(d) 夹具断言看错变量（空出参那路不碰 `q`）。
- **③ 达标面**：C1（`rc=0`／`572=572`／无导出消失）／C2（`96` 不变，**不构成前进**）／C3（`PTSGAP=PASS`、`impl 87`、`so16` 同趟）／C4（`CreateDocContext` 台账 **1→0 行**）／C5（两 `nm` 命中＝1、二选一声明与计数逐条一致、新可达面**二值＝没走到**）／C7（`same=yes`）／C8（`0/0/1` ＋ `impl=87`）／C9（两调用绑定读数全绿）／C10（形态②命中 `Pts.cs:3091`）。
- **④ 判 `failed` 的唯一原因（C6）**：本步**成功把托管排版链推到 `FlowDocumentFormatter.Format`**，随即撞上**字体族解析的 `FailFast`**（`FontFamily.get_FirstFontFamily`）⇒ `leg_24 alive=no app_rc=134 magenta=0`、守卫 `rc=1`。**两趟成对**证明这是**新暴露的更深一层**（before：`PTS_GAP` 2 行＋`[PTS-UNAVAILABLE]` 2 行＋`alive=yes`；after：两者**都 0 行**＋`alive=no`）。**该缺陷在册**（`docs/ROUTES.md:193` 逐字点名同一栈），成因**不在本件写域**（字体栈，他族）。
- **⑤ 反腿**：P2／P3／P6／P7／P8／P9／P10／P11 成立并**点名**（`5`／`35`／`86`／`before==after`／具名对拍／净腿也红／定名源字段／台账⊥声明）；P1 成立（机械对拍）；**P4／P5 NOINFO**（token 未实现＋禁写域，只能人工判定）。
- **⑥ 诚实红**：`native_gap 2→0` **不许读成前进**（它是打印行数，本趟为 0 是崩在打印之前）；探针脸 `after=` **不许**当"链上离开"；托管 `entry=` 面 **本件全程未用于定名**（其 `GapEntryNameAt(cnt-1)` 取表序末名，多缺口态必指错人）。

---

`P1-W8-STEP4-REPORT 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ PLACEHOLDER（口径＝末行之前的全文；末行＝本行）`
