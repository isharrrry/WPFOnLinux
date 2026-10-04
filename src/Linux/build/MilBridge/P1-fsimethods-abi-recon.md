# P1-W86 判词：`FSIMETHODS`「合法可得形态」可行性侦察 —— 为什么槽指针当本地函数指针调用即 `SIGSEGV`？

本件是**只读侦察件**（`work` 类）：判 `FSIMETHODS` 表**能不能被"值化"**（值拷贝快照／句柄化），并把 `t165` 的 `SIGSEGV` 的**两成因分开**。
**本件不实现、不跑腿、不构建、不占显示位、不改任何代码**；无运行期腿读数；引他人读数一律带代际并标「引自 X，本席未独立复算」。

---

## §0 身份、边界与在飞件

- 载体：`build/MilBridge/P1-fsimethods-abi-recon.md`（**新建**）。写者＝`scout`；写入面**仅本件**，`$N` 内其余件**一件未改**。
- 结论**只许收紧**；放宽须队长出裁定并在册。
- ⚠️ **在飞件**：`src/WpfGfx.Linux.Native/src/win32_pts.c` 开工现取 **`sha16=e41df5d4c77610ac`／307847 B**（mtime 18:48:03，与 `t165` 交出代际**一致**；HEAD＝`db6a44b`）⇒ 本件对他的引用**行号只在该代有效**。

---

## §1 现取台账（读取时刻＝2026-09-29 18:51–18:57，本席本地，仅本次有效）

| 件 | sha16 | 用途 |
|---|---|---|
| `PtsHost/Pts.cs` | `1a8575a18767a956` | `CreateInstalledObjectsInfo`／`DestroyInstalledObjectsInfo` 的 `[DllImport]` 形状；`FSIMETHODS` 17 槽 |
| `PtsHost/PtsCache.cs` | `25a3e0b6c50c2461` | 装配位与**持有位**（池字段 `:789-790`）、销毁调用点（`:332`／`:404`） |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `e41df5d4c77610ac`（307847 B） | 表的存储点 `:490`、FSCBK 的**窗内值拷贝**方子（`:120-131` 三条理由／`:639`／`:655-686`／`:1712`）、`snap_word` `:1215`、`t165` 驱动格 `:1283-1395`／调用点 `:1653` |
| `build/MilBridge/P1-engine-drive-report.md`（`t165`） | 157 行；末行自证 `091ef2cb3d5bc35f`（**本席当场复算 MATCH=yes**；**内部读数未复算**） | 来源件（`app_rc=139`、`edrive=1`、`fill=0`、`PRECOND-NO-ENGINE-DRIVER`、新认知「只能原样存不许 deref」） |
| `build/MilBridge/P1-fsimethods-recon.md`（`t163`，本席前件） | 238 行；自证 `9105d8ff204e7b3b` | 17 槽全表 ＋ `NOINFO-FSIMETHODS-ABI` |
| `build/MilBridge/P1-format-frame-recon.md`（`t164`，本席前件） | 241 行；自证 `9440f52aaecb1304` | 准入铁律（`准入＝本侧是该值的作者`） |

---

## §2 问 1：`subtrack_methods` 的**真实形态**

**判词：它是「托管对象字段地址」经封送后的**指针**；在**本调用期内**它指向一个 **17×8 B 的可调用函数指针数组**；**调用返回后该地址可能被搬移** ⇒ 跨调用持有即 `use-after-return`。它**不是**"别的东西（间接层）"，也**不是**"不可调用"。**

逐条依据（全部现取）：
1. **托管侧签名**：`Pts.cs:3076-3082`（`[DllImport]`）＝
   ```
   internal static extern int CreateInstalledObjectsInfo(
       [In]
       ref FSIMETHODS fssubtrackparamethods,//IN:  pointer to subtrack paragraph callbacks
       ref FSIMETHODS fssubpageparamethods,// IN:  pointer to subpage paragraph callbacks
       out IntPtr pInstalledObjects, out int cInstalledObjects);
   ```
   ⇒ **`ref` 传的是 `FSIMETHODS` 结构的地址**（不是"指向指针的指针"）⇒ native 收到的 `fssubtrackparamethods` **就是结构基址** ⇒ 17 槽在 **`+0 .. +128`**（**136 B 是计算值，须实测**：`t163` 的 17 槽全为委托字段）。
   ⚠️ 现取**不对称**：`[In]` 只标在**第一个** `ref` 上，第二个 `ref FSIMETHODS` **未标**（默认 `[In, Out]`）⇒ 这一处差异本席**只记不判**（`NOINFO-MARSHAL-ATTR`）。
2. **托管实参是"托管对象字段的地址"**：`PtsCache.cs:640` 用 `ref subtrackParaInfo, ref subpageParaInfo` 调它，而实参来自 `PtsCache.cs:433` 的 `ref _contextPool[index].SubtrackParaInfo`／`.SubpageParaInfo` ⇒ 这两个是**池条目的字段**（声明 `PtsCache.cs:789-790`）。
3. **native 侧存储点**：`win32_pts.c:490 t->subtrack_methods = fssubtrackparamethods; /* 原样存，不 deref */`（字段声明 `:103`，表头结构 `:102-106`）。

---

## §3 问 2：为什么当本地函数指针调用会 `SIGSEGV` —— **两成因必须分开**

### §3.1 **主因（use-after-return）—— 本件判定它在**静态上已足够**解释 `t165` 的崩溃**

**存储窗 ≠ 使用窗**（现取，两处 `文件:行`）：
- **存储窗**：`win32_pts.c:490`，位于 **`CreateInstalledObjectsInfo`（入口 `:478-499`，本体 `:482-499`，存储句 `:490`）**；托管侧在**建池期**调它（`PtsCache.cs:433` → `:640`）。
- **使用窗**：**`wpf_pts_drive_probe`（`:1397` 起）**内的 E2 驱动调用点 **`:1653`**；该探针的**调用者**是 **`FsCreatePageBottomless`（`:350`）** 与 **`FsCreatePageFinite`（`:3178`）** —— 即**建页调用窗**（与 `t146`/`t151` 在册的"调用窗＝`FsCreatePage*`"一致）。
⇒ 两个窗口**是不同的 P/Invoke 调用**，中间隔着整段编排（建池 → 建 doc → 建页）。指针在**建页**那次调用里被解引用 ⇒ **封送缓冲早已随建池那次调用结束**。

**为什么"失效"是可判的（本仓**已把这条写成纪律**）**：`win32_pts.c:120-131`（同族先例 `t141`／`PRECOND-FSCBK-SNAPSHOT-IN-DOC` 的窗口常量块）**原文**：
> **为什么必须"值拷贝"而不能存指针**（判据件 `P1-drive-probe-criteria.md` §1.3 现取的三条）：
> ① 入参是**托管对象字段的地址**（`PtsCache.Linux.cs:548` 的 `ref _contextPool[index].ContextInfo`；`ContextInfo` 是 `ContextDesc` 的字段，同件 `:965`）⇒ CLR 只保证**封送期间**该地址有效，**返回后可能搬移** ⇒ 跨调用持有它就是 **use-after-return**；
> ② 现取本模块的 doc 对象（`wpf_pts_doc`）今天**没有**这张表 ⇒ 没有任何地方记着回调表；
> ③ `wpf_pts_fscbk_probe()` 把 103 个字读进**栈上局部**、打印后**不留存**。

⇒ 本席判：**`t165` 的 `SIGSEGV` 的主因＝跨调用持有封送地址（use-after-return）**；被调的那个"函数指针"是**失效缓冲里读出的字节**（读的时候通常不崩——页仍在映射；**跳到它上面就崩**），这与 `t165` 的观测形态（`edrive=1`、`fill=0`、**首个回调处**崩、`app_rc=139`）**一致**。

### §3.2 **次因（槽序／ABI 错位）—— 未排除，且**不能靠 `SIGSEGV` 本身区分**

`t163` 的具名 `NOINFO-FSIMETHODS-ABI` 今天仍成立（17 槽序只能按托管声明推断，native **无镜像结构、无 `offsetof` 断言**）。
⚠️ 但注意：**"槽序错位"与"指针失效"都会给出 `SIGSEGV`** ⇒ **单凭 `t165` 那条读数无法区分**（这正是 `t165` 教训的形态：一次归因会把"还没试"变成"试过了不行"）。
⇒ **本件给出两条免费判别（§7 D1／D2），并要求 D1 必须先于 D2**。
另外现取一条**支持"槽算术本身没错"的旁证**（**仅旁证，不当结论**）：`t165` 的读槽代码用 `+0`（1-based 槽 1 = `pfnCreateContext`）与 `+16`（1-based 槽 3 = `pfnFormatParaFinite`）（`:1346`／`:1347`），与 `Pts.cs:1206-1222` 的字段序（`pfnCreateContext` 首、`pfnFormatParaFinite` 第 3）**自洽**。

---

## §4 问 3：与 `FSCBK` 的**逐条对照**（决定"能不能照 `fscbk` 的方子办"）

| 维度 | `FSCBK`（`t133`/`t138` 已给全表） | `FSIMETHODS`（本件） | 差异是否影响"值化" |
|---|---|---|---|
| 载体 | `FSCBK` 是 **`FSCONTEXTINFO` 的字段**（`Pts.cs:842 internal FSCBK fscbk;`），在结构 **`+40`** 处、**824 B／103 字** | **独立的 `ref` 形参**（`Pts.cs:3079-3080`），native 收到的指针**就是结构基址**（槽 `+0..+128`） | **不影响**：拿到值拷贝的方式不同（成员偏移 vs 形参基址），**照方子的动作相同** |
| 调用点 | `CreateDocContext`（`win32_pts.c:1689` 起） | `CreateInstalledObjectsInfo`（`:485` 段） | 不影响 |
| **本侧已有做法** | ✅ **在调用期内值拷贝**：`wpf_pts_fscbk_snapshot`（`:655`）内 `:667 memcpy(c->fscbk_snap, (const unsigned char *)info + WPF_PTS_FSCBK_OFF, WPF_PTS_FSCBK_SIZE);`，由 `:1712`（在 `CreateDocContext` 内）触发；之后一律读自己的副本（`wpf_pts_snap_word:1215`） | ❌ **只存指针**（`:490`），此后**零 deref** | 🔴 **这就是全部差异**：一个**窗内值化**，一个**跨窗持有** |
| 处置"未快照/全零" | 三态 `NONE/ALLZERO/VALUE`（`:143-145`）＋具名 `[FSCBK-SNAP-GAP]`（`:646-654`）＋拒绝路径**不登记对象** | 无此状态面 | 值化时**应照抄**（判据面） |
| 槽可用性证据 | `t133` 现取 `FSCBK_JOIN=PASS exact=10/10`（现场字节**逐位等于**托管交出的封送指针）；`t146`/`t151`/`t156` **三跳成功调用了 `+56`/`+80`/`+136`/`+176`**（**读数引自 `t165`/`t161` 转引，本席未独立复算**） | 无任何调用读数 | ⇒ **同类封送 thunk 是可调用的**（只要**在有效副本上**取到它） |

⇒ **判词**：两者的**产生方式差异只有一处**——`FSCBK` 是"结构成员"、`FSIMETHODS` 是"独立形参"——**这个差异不改变封送机制**；**能/不能调用取决于"是否在窗内取到值"，与"成员 vs 形参"无关**。
⇒ 因此 `t165` 的结论「`FSIMETHODS` 槽表只能"原样存、不许 deref"」**应收窄**为：**「该指针对的缓冲只在调用期内有效；跨调用 deref 是 use-after-return」**（**不是**"表不可用"）——这正是 🔴 红榜 `P9` 要挡的推广。

---

## §5 问 4：生命周期／GC —— 有"保持存活"机制吗？

- **持有位（有）**：`PtsCache.cs:789-790` — `internal PTS.FSIMETHODS SubtrackParaInfo;`／`SubpageParaInfo;`（池条目字段）；装配在 `:433`（`ref _contextPool[index].SubtrackParaInfo`）→ `:600` `InitInstalledObjectsInfo` → `:640` 调用。⇒ **16 个委托对象由池字段持有**（池存活期间一直有根）。
- **显式机制（无）**：`grep -rn 'GCHandle|GetFunctionPointerForDelegate|AllocHGlobal|MarshalAs' PtsCache.cs Pts.cs` ⇒ **0 命中** ⇒ 本波**没有** `GCHandle`／显式 `GetFunctionPointerForDelegate`／固定缓冲。
- **推论（须由 §7-D1 复核后才算数）**：封送 thunk 的地址由**被持有的委托对象**保活，故**值拷贝出来的 16 个非零字在后续调用中仍可调用**；**唯一短命的东西是"封送缓冲"本身**（它只承载这些指针值的副本）。
  ⚠️ 本席**不把这条当结论**：它是**判定＋理由**，其可证伪设计见 §7-D1/D3。

---

## §6 问 5：「值化」两形态可行性

| 形态 | 判 | 依据／代价 |
|---|---|---|
| ① **值拷贝快照**（照 `fscbk` 方子：17 字） | ✅ **得**（**且必须"只能在调用期内"做**） | 方子现成：`:667` 的 `memcpy`（`FSCBK`）＋ `:1712` 的窗内触发点；`FSIMETHODS` 的拷贝只需把"成员偏移"换成"形参基址"（`+0`，起点就是 `ref` 指针本身）⇒ **同一封送机制、同一风险面**。**窗口＝`CreateInstalledObjectsInfo` 的调用期内**（`:485` 段）。**大小 136 B（17×8）是计算值 ⇒ 须实测**（`t127`／`t160` 前例：偏移/尺寸只许实测） |
| ② **句柄化下发**（托管把槽指针包成可调用句柄） | ⛔ **不必要，且今天无机制**（`NOINFO-HANDLE-DOWN`） | 现取：`CreateInstalledObjectsInfo` 的签名给出的是**值**（`[In] ref`，`Pts.cs:3077-3082`）；托管侧**无** `GCHandle`/`AllocHGlobal`（§5）；要做这条属**新托管改动**（越本波写域）⇒ 判"不做"；若队长要，须单独立件 |

**核心问题的正面回答**：**"值拷贝一个函数指针数组后还能不能调用"** ⇒ **能，条件是两条同时成立**：**(i) 拷贝发生在封送窗口内**（否则拷到的是失效缓冲的字节）；**(ii) 被指向的 thunk 有根**（现取托管侧由池字段持有，见 §5）。二者本件均给出**依据**，但**均须由 §7 的读数复核**。

---

## §7 判「得／不得」＋最小可证伪实验设计

**总判词：得（值拷贝快照形态成立）**；**前提是"在窗内值化"**；`t165` 的 `SIGSEGV` **不构成**"表不可用"的证据（`P9`）。

### §7.1 三条判别（D1 必须先于 D2，D3 最后）

- **D1（把两成因分开，第一优先）「窗内副本 vs 窗后读」**
  在 `CreateInstalledObjectsInfo` 的**调用期内**把 17 字值拷贝进本对象（照 `:667`），并**同时**打印；再在 `t165` 的驱动点（`wpf_pts_drive_probe` `:1397` 内、调用点 `:1653`；其调用者为 `FsCreatePage*` `:350`/`:3178`）**用同一悬垂指针读出 17 字**并打印；**逐字比对**：
  - **不同 ⇒ use-after-return 确证**（`SIGSEGV` 归因结束，**不必再谈槽序**）；
  - **相同 ⇒ use-after-return 不成立**（至少该缓冲未被复用），此时 `SIGSEGV` **只能**归因槽序／ABI 或 thunk 不可调用 ⇒ 进 D2/D3。
  ⚠️ `t165` 的教训在此写死：**只有"调用已发出"的读数才允许谈"调用失败"**（`t165` 的 `edrive=1` 表明确实发出了；`calls=0` 的格只能记"没发出去"）。
- **D2（槽序／ABI 指纹，免费）「恰好第 15 槽为 0」**
  托管装配在**第 15 槽**显式置 `IntPtr.Zero`（`PtsCache.cs:617` `subtrackParaInfo.pfnGetFootnoteInfoWord = IntPtr.Zero;`，`t163` 现取：**唯一未装配槽**），其余 16 槽均为非空委托 ⇒ **在 D1 确认有效的副本上**，17 字里**零位必须恰为 index 15**；否则槽序/ABI 错位**确证**。⇒ 这条**必须在 D1 判"副本有效"之后**才使用（在失效缓冲上指数位无意义）。
- **D3（可调用性，最后）「在有效副本上真调槽 1，再槽 3」**
  只有 D1＝"副本有效" **且** D2＝"零位在 15" 都成立，才允许谈"调用"：调槽 1 取 `pfssobjc`（`idobj`/`ffi` 本侧自选，`t164` §3 的**作者性铁律**），再调槽 3（`t165` 已备好：全部 out 参数投毒、`pfsgeom` 自定形状、`fsrcToFill` 本侧矩形、`pfsobjbrk=NULL`（契约允许）））；断言 `rc=0` ∧ `pfspara` 被改写 ∧ **身份可认领** ∧ **只增一条**记账。**族检查（`fam_nmp=H ∧ fam_client=H`）必须保留**（`:1339-1344`）。

### §7.2 前置与形态

- **副本专用**：全部代码在 `#if` 内、缺省 0、**主链产物逐字节不变**（照 `WPF_PTS_FSP_PL_ENGINE_DRIVE` 先例，`t165` 已在册）。
- **值化的判据面照抄 `FSCBK`**：三态（未值化／值化了但全 0／真值）＋具名 gap 行（`:143-145`／`:646-654`）⇒ 让"未值化"与"值化后全 0"**判词不同**。
- **尺寸/偏移只许实测**：136 B／槽 `+0..+128` 是**计算值**，实现件须用编译期断言或运行时读回钉死。

---

## §8 若队长判「不得」：`(b)`（`cParas` 源）的改判候选

1. **改判到"引擎侧自有记账"**（`t163` §3.2 的方向，**不依赖 `FSIMETHODS`**）：先例 `FsQueryTrackDetails` ＋ `wpf_pts_fsp.c_paras`（句柄＝本对象内字段地址、按对象答数、反腿一对）⇒ 这条**与 `FSIMETHODS` 是否可值化无关**，是**并行的独立路线**。
2. **承认本波只到 `(a)` 为止**（`pfspara` 已由 `t162` 落地），把 `cParas` 维持"无源＋诚实拒绝＋留痕"。
3. **先做 D1 再回头**（不算改判，算**前置**）：在窗内值化＝零托管改动、纯 native 侧，代价最低 ⇒ 若 D1 判"副本有效"，则 §7-D3 即可接上，不必改判。
⇒ **不许**为了"看起来有下一步"而把**跨窗持有的失效指针**当可用表（本件 §3.1 已证其失效）。

---

## §9 `t165` 教训的吸收 ＋ `P9` 守则

- **送检物必须先证明"真的被送到了检查点"**：本件要求每一条**负面结论**都附前置 —— 「调用了才谈调用失败」(`calls>0`)、「值化了才谈槽序」(D1 先行)、「有效副本上才谈可调用性」(D2 先行)。
- **`t165` 两处自伤的正确读法**（本席据其载体现取，**其内部读数未复算**）：族分类写错会让"驱动未发出"看起来像"驱动不可行" ⇒ **`edrive=1` 才使那条 `SIGSEGV` 成为真读数**；而它**仍不能**支持"表不可用"。
- **`P9`**：本件**明确拒绝**把「某一种用法崩了」推广成「表不可得」——**同一张表在窗内是"可读、可拷、且（据同族先例）可调"的**；`t165` 的崩溃恰恰**发生在窗外的跨调用使用**。

---

## §10 诚实边界与具名 `NOINFO`

1. 本件**不含**任何腿读数；`t165` 的 `app_rc=139`／`edrive=1`／`fill=0` 等**均为引自其载体，本席未独立复算**（仅复算其末行自证 MATCH=yes）。
2. 具名 `NOINFO`：
   - `NOINFO-FSIMETHODS-ABI`（沿用 `t163`）：17 槽序**只能按托管声明推断**；native **无镜像结构、无 `offsetof`/`_Static_assert`** ⇒ **D2 的指纹是"用一个可观测事实反推槽序"，不是直接实测**。
   - `NOINFO-MARSHAL-ATTR`：`Pts.cs:3078-3080` 现取**只有第一个 `ref` 标了 `[In]`**，第二个未标 ⇒ CLR 对第二个是否回写、是否采用不同缓冲**无仓内依据**（本件只记不判）。
   - `NOINFO-BUFFER-LIFETIME`：**"封送缓冲在返回后失效"**这一条，本件的依据是**本仓自己在 `:120-131` 写下的三条理由**（同族先例）＋ **窗/用分离的现取**；**不是**对 CLR 实现的实测 ⇒ 标记为**判定**，由 §7-D1 复核后才可升级为读数。
   - `NOINFO-THUNK-LIVENESS`：§5 的"thunk 由被持有的委托保活"同为**判定**，由 D3 复核。
3. **不许**把本件的"得"读成"`FSIMETHODS` 已可值化"：本件判的是**形态可行性**（有方子、有窗口、有指纹），**不是**"已经做成"。

---

## §11 本件自身的验收

1. 新件；末行＝自证行（`head -n -1 <本件> | sha256sum | cut -c1-16`）；`mode 644`；首记号 ＝ `# P1-W86 `。
2. 复核者须**独立重取** §1 表内至少 3 件的 sha16 与引用行（`sed -n` 打原文）；`win32_pts.c` **必须重取**（在飞）；不一致处**只增不改**地追加。
3. 本件**未**授权任何判据放宽；对 `t165` 的处置为**收窄**（§4／§9）。

---

## §12 附录：现取原文摘录（仅本次有效）

`Pts.cs:3076-3082`（sha16 `1a8575a18767a956`）：
```
        [DllImport(DllImport.PresentationNative)]
        internal static extern int CreateInstalledObjectsInfo(
            [In] 
            ref FSIMETHODS fssubtrackparamethods,//IN:  pointer to subtrack paragraph callbacks
            ref FSIMETHODS fssubpageparamethods,// IN:  pointer to subpage paragraph callbacks
            out IntPtr pInstalledObjects,       // OUT: pointer to installed objects array
            out int cInstalledObjects);         // OUT: size of installed objects array
```
`PtsCache.cs:433`／`:640`／`:789-790`（sha16 `25a3e0b6c50c2461`）：
```
            InitInstalledObjectsInfo(ptsHost, ref _contextPool[index].SubtrackParaInfo, ref _contextPool[index].SubpageParaInfo, out installedObjects, out installedObjectsCount);
            PTS.Validate(PTS.CreateInstalledObjectsInfo(ref subtrackParaInfo, ref subpageParaInfo, out installedObjects, out installedObjectsCount));
            internal PTS.FSIMETHODS SubtrackParaInfo;
            internal PTS.FSIMETHODS SubpageParaInfo;
```
`win32_pts.c`（代际 **`e41df5d4c77610ac`**）：
```
:103    const void  *subtrack_methods;       /* 托管传进来的指针，**原样存** */
:120-131  **为什么必须"值拷贝"而不能存指针** …① 入参是**托管对象字段的地址** … CLR 只保证**封送期间**该地址有效，
          **返回后可能搬移** ⇒ 跨调用持有它就是 **use-after-return**；② 本模块的 doc 对象今天没有这张表；③ 探针不留存。
:143-145  #define WPF_PTS_FSCBK_SNAP_NONE 0 / _ALLZERO 1 / _VALUE 2
:490    t->subtrack_methods = fssubtrackparamethods;        /* 原样存，不 deref */
:667    memcpy(c->fscbk_snap, (const unsigned char *)info + WPF_PTS_FSCBK_OFF, WPF_PTS_FSCBK_SIZE);
:1215   static const void *wpf_pts_snap_word(const wpf_pts_doc *d, int idx)   /* 只读自己的副本 */
:1653   if (g_pts_sub_live_n > 0 || 1) wpf_pts_engine_drive(d, where);   /* ⏪ t165 E2（副本专用） */
:1346   const wpf_pts_fn_create_objctx f1 = *(const wpf_pts_fn_create_objctx *)(const void *)((const char *)m + 0);
:1347   const wpf_pts_fn_fmt_para_finite f3 = *(const wpf_pts_fn_fmt_para_finite *)(const void *)((const char *)m + 16);
```
（`:1346`/`:1347` 的 `m` 来自 `:1322`：`if (g_pts_io_live[i]->subtrack_methods) { m = g_pts_io_live[i]->subtrack_methods; break; }` ⇒ **在驱动点解引用"存储窗存下的"指针**。）

---

**判词（本席）**：① `subtrack_methods` 的真实形态＝**封送期内的 17 槽函数指针数组之基址**（`Pts.cs:3076-3082`／`PtsCache.cs:433`/`:640`/`:789-790`／`win32_pts.c:490`），**调用返回后该地址可能被搬移**；② `t165` 的 `SIGSEGV` **主因＝跨调用持有（use-after-return）**——存储窗 `CreateInstalledObjectsInfo`（`:490`）与使用窗 `:1653`（属 `DestroyInstalledObjectsInfo`，`:503`）**是不同调用**，且本仓 `:120-131` 早已写下同族三条理由；**次因（槽序/ABI）未被排除**，须由 D1 先行、D2 指纹（**唯一零槽应在 index 15**，`PtsCache.cs:617`）分别判定；③ 与 `FSCBK` 的**唯一产生方式差异**是"结构成员 vs 独立形参"，**不改变封送机制** ⇒ **照 `fscbk` 方子可办**：**`得`**，条件是 **值拷贝必须在 `CreateInstalledObjectsInfo` 的调用期内完成**（`:667` 模式的搬用；尺寸 136 B 须实测），而**句柄化不必要、今天亦无机制**；④ `t165` 的「只能原样存不许 deref」**收窄**为「**该缓冲只在调用期内有效**」，**不得**推广成"表不可用"（`P9`）；⑤ 若判"不得"，`(b)` 建议改判到**引擎侧自有记账**（`t163` §3.2 路线），或承认本波只到 `(a)` 为止。
`P1-fsimethods-abi-recon 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 35041d7b492824b0（末行＝本行）`
