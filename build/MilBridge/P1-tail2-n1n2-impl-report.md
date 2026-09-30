# P1-tail2 `TASK-0302` · native `N1` 身份模型 ＋ `N2` 窗分离 —— 实现报告（`T-A22`）

- **读时**：`2026-09-30T14:1x–14:2x+0800`（本席现取；§5 收尾再取）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=333b2bc56ea185b722dd8dd2865f5a8f0f64efbf`（现取）。
- **现件代**：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`e09c8d739c179966`**（421296 B；`51fe76de3d8613de` 416272 B ⇒ 改后）；`bin/exports.txt` ＝ **674** 行（现取 `nm` 逐名见 §3-③）。
- **改前件备份**：`~/tA22-work/libwpfwin32.so.51fe76de3d8613de.bak`；改后件 `~/tA22-work/libwpfwin32.so.e09c8d739c179966`。
- **件指纹（现取；`sha256` 前 16 位）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`＝`74aa285b641de4a6`（改前 `681bd74cd62fc287`）｜`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`＝`a1a4cd69582e9498`（改前 `f9fa0a25c5ab844d`）。
- **只改两件**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（`N1`＋`N2` 本体）＋ `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（**声明行 `so16` 重锚**，`D-G70` 形态）。**导出面一字未动** ⇒ 复述位（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/**/win32_classification.c`）**无随动需要**（`ops`／`impl`／`tool` 三字段未动）。
- **黑名单遵守**：未动 `build/*.Linux/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`；未跑整趟 `verify-all`；重活（构建 ＋ 两条腿）全走 `heavy-slot`；进程只按 PID；写前 `cp -p` 备份。
- **行号纪律**：本件行号**仅本次有效**（内容锚原文一并给出）。

---

## §0 结论速览（自包含）

1. **`N1` 已落地**：native 新增**来源证据台账**（`wpf_pts_prov`）＋ 认领谓词 `wpf_pts_prov_claim`，实现「**按来源证据认领 ＋ 按对象身份核验**」：判据＝① 入参**等值于**在册证据的句柄值（必要）② 证据 `doc` **就是**本次 `pfscontext`（**指针等值**，对象身份核验）③ 通道相符（段句柄 `'S'` ≠ 客户端句柄 `'C'`）④ 会话（`gen`）相符。**反极性三类必红**（`WRONG-OBJECT`／`ABA`／`STALE-GEN`）。
2. **`N1` 主链生效**：`FsQuerySubtrackDetails`／`FsQueryTextDetails` 在"本侧自有对象认不出"时**追加**该认领。实测 `p=0x4`（§2.3 的**索引复用**真例）**被认出**（`v=CLAIMED-NO-CONTENT-MODEL`，`ev_seq=3`、`ord=0`、`gen=1`、`written_out=1,2`、`src=FsCreatePageBottomless`）——**改前**是 `reason=unclaimable-subtrack`。**认出后仍拒**（该段自己的子段序本波无源）⇒ **零假值／永不假成功**。
3. **对象身份核验真咬人**：同值 `0x4` 在**别的 doc** 上被问时**必拒**（`claim=none v=NO-PROVENANCE-EVIDENCE`，`wrong_object` 逐次递增至 **415**）⇒ 只有"产生它的那个 doc"认得出（2 次）。
4. **`N2` 已落地**：`wpf_pts_drive_probe2_oow` 的**窗外腿不再发 `+136` 回调** —— 窗外**只做汇总/拒绝并留痕**（`[WINDOW-SPLIT] window=out action=summarize-only`，`calls136=0`），**窗内**才真枚举/真填（`[WINDOW-SPLIT] window=in action=enum+ledger`，`calls136=2`）。⇒ 原「窗外 `+136` ⇒ `rc=-100002` **×508**」的**不可判形态**归 **0**。
5. **症状门中性**：两条腿（k=24／k=23）的 `alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns` 六项与改前**逐字相同**（同跑器、相邻代成对，§3-⑤）。`PTSGAP=PASS`（rc=0、零 `SITE-DRIFT`）｜`DEFREG=PASS`（rc=0）｜`REPORTID=PASS`（rc=0）。

---

## §1 `N1` 身份模型（`PRECOND-NATIVE-CLAIMS-CALLBACK-HANDLES`）

### 1.1 设计口径（写死，防读宽）

裁定四十七 (c)：**身份判据不得依赖 `rc`／数值形态，须独立可读的身份证据**。托管交回的句柄是
`PtsContext.CreateHandle` 的**槽位下标** ⇒ **数值可复用、非稳定身份**（`T-A21` §2.3 实证：同趟 `0x4`
先后当过段句柄与客户端句柄）⇒ 本侧**绝不**按"数值相等"认对象，改认「**产生该句柄的那一次回调调用**」
这一**来源事实**：

| 字段 | 判据作用 |
|---|---|
| `handle` | 托管交回的句柄值（**原样存，不 deref**） |
| `doc` | 交回它的那个上下文（**对象身份核验**：本次 `pfscontext` 指针等值） |
| `channel` | `'S'`＝`+136`／`+144` **段句柄**｜`'C'`＝`+176` **客户端句柄**（**同值异通道＝ABA**） |
| `gen` | 那次枚举的**会话号**（`wpf_pts_doc.prov_gen`，**只增不复用** ⇒ 上一窗的旧身份不可认领） |
| `seq` | 本台账**全局唯一序号**（只增不复用 ⇒ 同值两条证据**可分辨**） |
| `written_out` | 本侧**真把它写进** `FSPARADESCRIPTION.pfspara` 的次数（强化面） |

持有期（裁定四十五 (a)）＝**托管对象生存期**：本侧只持**引用**、**不回收**托管句柄；台账条目随
**下一次枚举会话**或**该 doc 注销**（`DestroyDocContext`）整体失效。

**认领的充分条件**（比"等值"严）：同值候选里**恰有一条**满足（doc ∧ 通道 ∧ 会话）**且没有**任何同值的
「异 doc／异通道／旧会话」条目；后者在册 ⇒ **拒**（**不静默取一条**）。

### 1.2 实现落点（`win32_pts.c`）

| 落点 | 内容 |
|---|---|
| `wpf_pts_doc` | 新增字段 `int prov_gen;`（本 doc 的枚举会话号，**只增不复用**） |
| 新块 `wpf_pts_prov` | 台账本体 ＋ `wpf_pts_prov_retire`／`_register`／`_mark_written`／`_claim`／`_selftest` |
| `wpf_pts_sub_enum` | 入口 `d->prov_gen++` ＋ retire 上一会话的段证据；成功后对每个 `+136`／`+144` 交回的句柄 `register(..., 'S', where, ord, gen)` |
| `FsQuerySubtrackParaList` | `+176` 交回的客户端句柄 `register(..., 'C', ...)`；写 `FSPARADESCRIPTION` 后 `mark_written(..., 'S', children[i])` |
| `FsQuerySubtrackDetails`／`FsQueryTextDetails` | `wpf_pts_sub_claim` 失败后**追加** `wpf_pts_prov_claim(p, doc, 'S')`；认出 ⇒ 判词**分立**（`claimed-by-provenance-no-content-model`／`…-no-text-line-model`）＋ `[PROVCLAIM]` 行；认不出 ⇒ 旧判词**逐字保留** |
| `DestroyDocContext` | `wpf_pts_prov_retire(doc, 0, ...)`（随 doc 注销整体失效） |
| `wpf_pts_drive_probe` | 每进程一次调用 `wpf_pts_prov_selftest()` |

### 1.3 机读证据（**必红腿在内**）

**（a）谓词自检**（改后腿 `app_g1.log` 现取，逐字）：

```
[PROV-SELFTEST] mask=0x1f claim_ok=1 wrong_object=1 aba=1 stale=1 zero_evidence=1 created=2 retired=2 n=0(n0=0) v=PROV-IDENTITY-OK(5/5)（反极性三类必红：wrong-object／ABA／stale-gen）
```

⇒ bit0 正腿（同 doc＋同通道＋同会话 ⇒ 认出）／bit1 `WRONG-OBJECT`（异 doc ⇒ 拒）／bit2 **`ABA`**（同值异通道在册 ⇒ 拒）／bit3 `STALE-GEN`（旧会话 ⇒ 拒）／bit4 数值相等但零证据（⇒ 拒）—— **5/5**。

**（b）主链认领**（改后腿现取，逐字，两条）：

```
[PROVCLAIM] entry=FsQuerySubtrackDetails p=0x4 claim=prov doc=0x648e37841010 ev_seq=3 channel=S(+136/+144 段句柄) src=FsCreatePageBottomless ord=0 gen=1 written_out=1 claims_ok=2 wrong_object=1 aba=2 stale=1 zero_ev=1 out=UNWRITTEN bytes=0 v=CLAIMED-NO-CONTENT-MODEL
[PROVCLAIM] entry=FsQuerySubtrackDetails p=0x4 claim=prov doc=0x648e37841010 ev_seq=3 channel=S(+136/+144 段句柄) src=FsCreatePageBottomless ord=0 gen=1 written_out=2 claims_ok=3 wrong_object=1 aba=2 stale=1 zero_ev=1 out=UNWRITTEN bytes=0 v=CLAIMED-NO-CONTENT-MODEL
```

**（c）对象身份核验必咬**（异 doc 的同值入参 ⇒ 拒；改后腿现取一条 ＋ 计数）：

```
[PROVCLAIM] entry=FsQuerySubtrackDetails p=0x4 claim=none doc=0x648e3783e4e0 claims_ok=3 wrong_object=2 aba=2 stale=1 zero_ev=1 v=NO-PROVENANCE-EVIDENCE
（终值：wrong_object=415）
```

⇒ **同一数值 `0x4`**：在**产生它的 doc** 上认出（2 次）；在**别的 doc** 上 414 次**全拒** ⇒「数值相等 ≠ 同一个对象」这条反腿在本实现里**结构上不可通过**。

**（d）反极性两类的**机制**证明**：`mask` bit2（ABA）与 bit1（wrong-object）由 `wpf_pts_prov_selftest` 自建反向腿产生；`wrong_object=415` 是**真腿上的**逐次递增（不是合成夹具）。

---

## §2 `N2` 窗分离（`PRECOND-WINDOW-SEPARATION`）

### 2.1 设计口径（写死）

「**窗外只做汇总/拒绝并留痕，窗内才做枚举/真填**」。根因（现取）：`+136 pfnGetFirstPara` 的实现读
`StructuralCache.CurrentFormatContext`（`ContainerParagraph.cs:105/112/151`）⇒ **只在造型窗内可调**；
窗外真调它 ⇒ `rc=-100002`（**注定失败的发调**，形态**不可判**）。

### 2.2 实现落点（`win32_pts.c`）

- `wpf_pts_drive_probe2_oow`：**删掉**窗外真调 `+136` 的整段（含 `#if WPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD`
  的 REFUSED 提前返回）；改为**只读窗内台账**（`drive_handles_live`／`sub_enum_ok`／`sub_cparas`）并打
  `[WINDOW-SPLIT] window=out action=summarize-only … calls136=0`。`+176` 的窗外探针腿（`[DRIVE-PROBE3-OOW]`）
  **逐字保留**（该槽不读 format context ⇒ 窗不敏感，且它是**探针**而非三入口的内容面；射程见 §5-2）。
- `wpf_pts_sub_enum`：末尾**新增成对行** `[WINDOW-SPLIT] window=in action=enum+ledger … calls136=N`。
- 新增三个成对计数：`g_pts_win_in_enum`／`g_pts_win_out_summary`／`g_pts_win_out_refused`（**不加导出**）。

### 2.3 成对机读读数（改后腿现取，逐字）

```
[WINDOW-SPLIT] where=FsCreatePageBottomless window=in action=enum+ledger src=+136/+144 ledger_ok=1 ledger_cparas=3 calls136=2(real-callbacks-in-window) in_enum=1 out_sum=0 out_refused=0 v=IN-WINDOW-ENUM+LEDGER
[WINDOW-SPLIT] where=FsCreatePageFinite window=in action=enum+ledger src=+136/+144 ledger_ok=1 ledger_cparas=3 calls136=2(real-callbacks-in-window) in_enum=2 out_sum=2 out_refused=0 v=IN-WINDOW-ENUM+LEDGER
[WINDOW-SPLIT] where=FsCreatePageBottomless window=in action=enum+ledger src=+136/+144 ledger_ok=1 ledger_cparas=1 calls136=2(real-callbacks-in-window) in_enum=3 out_sum=363 out_refused=1 v=IN-WINDOW-ENUM+LEDGER
[WINDOW-SPLIT] where=FsQueryTrackParaList window=out action=summarize-only src=in-window-subenum ledger_ok=1 ledger_cparas=3 nms136=0x2 handles_live=1 calls136=0 … v=OUT-WINDOW-SUMMARIZE-ONLY(from-in-window-ledger) NOINFO=oow-nms-liveness-judge-native-selfrecorded-not-managed-read
[WINDOW-SPLIT] where=FsDestroyPage window=out action=summarize-only src=in-window-subenum ledger_ok=0 ledger_cparas=0 nms136=0x2 handles_live=0 calls136=0 … v=OUT-WINDOW-REFUSED(handles-released/page-destroyed) NOINFO=oow-nms-liveness-judge-native-selfrecorded-not-managed-read
```

**成对口径**：窗内＝**真枚举/真填**（`calls136=2`）｜窗外＝**汇总/拒绝**（`calls136=0`，`out_sum=528`／
`out_refused=1`）。⇒ 判据 D5／`P13`：**不**把"窗内可得"读成"调用期可得"。

---

## §3 验收逐条（可计算）

**① `N1` 机读证据**（含 `wrong-object`／`ABA` 两类反极性必红）：见 §1.3 ——
`mask=0x1f v=PROV-IDENTITY-OK(5/5)`（谓词层）＋ `p=0x4 v=CLAIMED-NO-CONTENT-MODEL`（主链层）＋
`wrong_object=415`（真腿上的对象身份核验）。

**② `N2` 成对读数**（窗外只汇总/拒绝 ＋ 留痕 ｜ 窗内枚举）：见 §2.3 ——
`window=out calls136=0 out_sum=528 out_refused=1` ｜ `window=in calls136=2 ×3`。

**③ 导出面**：`nm -D --defined-only bin/libwpfwin32.so | wc -l` ＝ **674**；`wc -l bin/exports.txt` ＝ **674**；
逐名对拍（`sort` 后 `diff`）＝ **零差异**（无消失、无新增）。

**④ `PTSGAP=PASS`（rc=0、无 `SITE-DRIFT`）＋ 逐处 before/after**：

```
$ R=$PWD bash build/MilBridge/tools/pts-gap-count-check.sh          # rc=0
LIVE  tool=85 dead=11 artifact=1 ops=73 impl=76 so16=e09c8d739c179966 exports=674 root=/home/links-dev/netTest/GitProj/WPFOnLinux
PTSGAP=PASS tool=85 dead=11 artifact=1 ops=73 impl=76 so16=e09c8d739c179966 exports=674 root=/home/links-dev/netTest/GitProj/WPFOnLinux
```

逐处 before/after：唯一字段 `so16` `51fe76de3d8613de`→`e09c8d739c179966`（声明行同趟重锚，见 `pts-gap-decl.txt` 新块）；
`tool/dead/artifact/ops/impl`（85/11/1/73/76）与 `exports`（674）、`w66pre16`（`bf6b683d94549087`）**逐字段未动**；
`SITE-DRIFT`＝**0**；`PTSGAP_HISTORICAL=n=5`、`SITE-HISTORICAL-ONLY`（`KNOWN-DEFECTS.md` 的 ops/impl 历史行）**照旧**。

**⑤ 症状门成对 ＋ `DEFREG`／`REPORTID`**（**同一跑器 `run-pts-pages-legs.sh`、相邻代、同一显示流程**）：

| 面 | before（`51fe76de3d8613de`） | after（`e09c8d739c179966`） |
|---|---|---|
| leg24 `alive`／`app_rc` | `yes`／`143` | `yes`／`143` |
| leg24 `magenta`／`colors`／`ink` | `0`／`383`／`480000` | `0`／`383`／`480000` |
| leg24 `ns`／`ae` | `…FlowDocumentDemo`／`15386` | `…FlowDocumentDemo`／`15386` |
| leg24 `fr_sha` | `ef3fd6765f18f51b` | `ef3fd6765f18f51b` |
| leg23 `alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`／`fr_sha` | `yes`／`143`／`0`／`383`／`480000`／`…RichTextBoxDemo`／`ef3fd6765f18f51b` | **同** |
| `LEGS_RUNNER` | `PASS requested=2 obtained=2 refused=0` | 同 |

`DEFREG rc=0`：`DEFREG=PASS declared=225 route_ids=225`（`DEFREG_DECLDRIFT=0`）。
`REPORTID rc=0`：`REPORTID=PASS files=310 ids=2218 declared=225`。

---

## §4 before/after 逐处（改前腿 vs 改后腿，同跑器）

| 行／面 | before（`51fe76de3d8613de`） | after（`e09c8d739c179966`） |
|---|---|---|
| `[DRIVE-PROBE2-OOW]`（窗外真调 `+136`） | **509**（其中 `v136=CALLBACK-ERR(-100002)` **508**；`where=FsQueryTrackParaList` 508／`FsDestroyPage` 1） | **0** |
| `[WINDOW-SPLIT] window=out` | 0 | **529**（`summarize-only` 528 ＋ `refused` 1） |
| `[WINDOW-SPLIT] window=in` | 0 | **3**（全部 `calls136=2 v=IN-WINDOW-ENUM+LEDGER`） |
| `[PROV-SELFTEST]` | 0 | **1**（`mask=0x1f` ⇒ 5/5） |
| `[PROVCLAIM]` | 0 | **416**（`claim=prov` 2 ＋ `claim=none` 414） |
| `[FSQSTD] reason=unclaimable-subtrack` | **343** | **361**（其中 `0x4` 的 2 次改判为 `claimed-by-provenance-no-content-model`） |
| `[FSQSTD] reason=claimed-by-provenance-no-content-model` | 0 | **2** |
| `[FSQSTD] rc=0`（本侧自有子轨对象成功） | 506 | 526 |
| `[FSQSTD] reason=null-subtrack` | 2 | 2 |
| `entry=FsQueryTextDetails reason=unclaimable-para` | 53 | 53（`claim=none`） |
| `[FSQSPL] rc=0` | 506 | 526 |
| `[FSPARALIST-FILL]` | 508 | 528 |
| `[SUBENUM]`／`ENUM-OK` | 1015／3 | 1055／3 |
| `[HC-UNHANDLED]` | 398 | 418 |

> ⚠️ **射程（照 `P9`，写清）**：上表中**非零回调面**的差（`rc=0`／`FILL`／`SUBENUM` 各 +20／+20／+40）
> **不是**本改动的判定面：该三项由**托管侧页面枚举次数**驱动（native 不决定其调用次数），同代两次跑
> 已有 ±5 的运行差（`evidence-tail2b` 355／`evidence-tail2b-nowm` 360），且改前腿（`51fe76de`）在同一跑器下
> 与 `T-A20` 车道的非标准腿（576）也不同。**本改动的判定面**＝`[DRIVE-PROBE2-OOW] 509→0`、
> `[WINDOW-SPLIT] 0→532`、`[PROVCLAIM] 0→416`、`[PROV-SELFTEST] 0→1` 四行 —— 这些**只由本改动决定**。

---

## §5 边界 · `NOINFO` · 主动披露

1. **未改任何其它仓内文件**；`git status --porcelain` 现取 = `M` 两件（`win32_pts.c`／`pts-gap-decl.txt`）
   ＋ 两项**先于本件**的 untracked（`build/MilBridge/tasks-tail2/T-A22.md`／
   `build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`）。
2. **`+176` 窗外探针腿保留（射程声明）**：`[DRIVE-PROBE3-OOW]` 仍发调 —— 它是**探针**（`t160` W-2 两腿实验），
   不产生三入口的**内容面**，且该槽**不读** `CurrentFormatContext`（窗内=0 ∧ 窗外=0 已实证）。
   ⇒ `N2` 的窗分离规则**射程＝内容/枚举面（`+136`／`+144`）**，**不含** `+176`。这是**如实划界**，不是遗漏。
3. **`N1` 认出 ≠ 有内容**：`p=0x4` 认领成功后**仍拒**（该段**自己的子段序**本波无源：窗内只枚举了顶层
   container）⇒ `PRECOND-NATIVE-OWNS-A-PARAGRAPH-MODEL` **仍未解除**（承 `T-A21` §5.2）。本件**只**把该前置的
   **身份面**（`PRECOND-NATIVE-CLAIMS-CALLBACK-HANDLES`）落地。
4. **`no-app-run` 面：已跑**（两条腿，走 `heavy-slot`）；**`NOINFO` 三条**：
   - `NOINFO-oow-nms-liveness-judge-native-selfrecorded-not-managed-read`（逐行在场）：`drive_handles_live`
     是 **native 侧自记**，不是托管读数。
   - `NOINFO-host-window-at-gap-site`（承 `T-A21`）：**在 `FsQuerySubtrackDetails`／`FsQueryTextDetails`
     调用点**直接插桩测"窗外"的读数仍**未取**；本件的 `window=out` 读数取自 `wpf_pts_drive_probe2_oow`
     的调用点（`FsQueryTrackParaList`／`FsDestroyPage`），**不是**三入口内部。
   - `NOINFO-aba-in-main-chain`：主链上**未**出现真 ABA（同 doc 同会话同值异通道）——`aba` 计数 `2` 全来自
     `wpf_pts_prov_selftest` 的**合成腿**；主链的**真**反例是 `wrong_object`（异 doc，415）。ABA 的**主链**实证
     需 `t160` W-2／`FsQuerySubtrackParaList` 的客户端句柄与段句柄**同值**（本趟 `h0∈{0x5,0x7,0xb}` 与
     `children[]=0x4` 不同值）⇒ **本趟未触发**。
5. **前提更正（如实记）**：`T-A21` §2.2 的 `-100002 ×576` 取自 `T-A20` 车道的**非标准**跑器；本件用**标准**
   跑器现取改前腿 ⇒ 同形形态为 **`-100002 ×508`**（**同一形态、不同趟**）⇒ `T-A21` 的"×576"是**该趟**读数，
   不是常量。
6. **未做**：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；未动任何牙本体；未 `git add/commit/push`。
7. **代际**：`.so`＝`e09c8d739c179966`；`win32_pts.c`＝`74aa285b641de4a6`；`pts-gap-decl.txt`＝`a1a4cd69582e9498`；
   改前 `51fe76de3d8613de`／`681bd74cd62fc287`／`f9fa0a25c5ab844d`。
8. **副作用物（仓外）**：`~/tA22-work/**`（备份件／两条腿证据）；`~/w67-work/app`（APPDIR 已刷成改后权威件，
   `SYNC-APPLOCAL=PASS drift=0`）；`~/w67-work/logs/{evidence-before,evidence-after}/`。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-n1n2-impl-report.md | sha256sum | cut -c1-16`）= `7e8a7e3ea2a4e6ef`
