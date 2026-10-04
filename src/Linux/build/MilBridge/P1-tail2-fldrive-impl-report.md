# `P1-tail2` `TASK-0302` · 翻 `WPF_PTS_FL_DRIVE` 为**缺省开**（行模型默认驱动）—— 实现报告（`T-A31`）

- **读时**：`2026-09-30T16:2x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=fe4c4712461a6c40a3926392372d4b632c377cdc`（现取，**未换代**；较 `T-A30` 的 `55ad709c…` 已前进 — 中间有他人提交）。
- **改前件备份（仓外 `~/tA31-work/bak/`，`cp -p` 取在**任何写之前**，逐字节复算 = 记录值）**：
  `win32_pts.c.bcd6a00b.bak`（`bcd6a00bce9f67a2`／461075 B）／
  `libwpfwin32.so.8ad93763.bak`（`8ad9376305404ca2`／430736 B）／
  `pts-gap-decl.txt.b74f6609.bak`（`b74f6609e489b4cd`／27450 B）／
  `exports.txt.c561dda4.bak`（`c561dda4eca311c5`／677 行）。
- **只改**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**闸缺省值** `WPF_PTS_FL_DEFAULT 0→1` ＋ 该处注释/文案）／其登记面 `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（`D-G70` 的 `so16` 重锚 ＋ `T-A31` 记录块）／本载体。**未动** `bin/exports.txt`（构建后**逐字节相同**）。
- **黑名单遵守**：未动 `build/*.Linux/**`（生成件）／`build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`；**未跑**整趟 `verify-all`；重活（1 趟构建 ＋ 9 趟腿）全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`；进程只按 PID；禁 `sleep` 轮询；写前 `cp -p` 备份；模式守恒（两件均 `644`→`644`）。
- **行号纪律**：本件行号**仅本次有效**（内容锚原文一并给出）。

---

## §0 结论速览（自包含）

1. **实现已落地（`win32_pts.c`，`T-A31` 指定写域）**：运行期闸的**缺省值**由 `WPF_PTS_FL_DEFAULT 0` 翻为 **`1`**（照 `T-A9` 体例撤销「缺省关」）；**仅显式 `WPF_PTS_FL_DRIVE=0` 才关**（反极性腿 `legs-polar0`／`legs-polar0b`）。闸关留痕行文案随动。
2. **缺省路径现在真驱动行模型**（现取，`legs-newdef*` 各腿）：`[FORMATLINE] … gate=1 … v=DRIVEN`；`[FORMATLINE-LINE]` **42** 行、其中 **`fsflres=2`（段末收束）7** 行；`[FORMATLINE] … complete=1 v=LINES-RECORDED` **7/7**；`gap=0 incomplete=0`；**`failfast=0 unrec=0 app_rc=143 alive=yes`**（**无 `app_rc=134`、无崩溃**）。
3. **症状门成对（① 通过）**：缺省路径下 `alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns` 与改前**逐格相同**（`yes`／`143`／`0`／`383`／`480000`／`FlowDocumentDemo`；`k23` 同理）。⇒ **不触发"判红并回退"**。
4. 🔴 **帧面成对（② 如实判红：产品面零进展）**：两页内容区**仍无任何非空态像素** —— 具名活锚（`Beige`／`DarkGreen`／`GhostWhite`／`LightGoldenrodYellow`）**全 0 px**，帧 `sha16` `ef3fd6765f18f51b` 与改前**逐字节相同**，`ae`／`colors` 逐格相同。⇒ **"首次出现内容"＝否**（**不**把空白读成绿）。
5. 🔴 **如实披露：缺省驱动改变了产品查询面计数** —— `[FSQSTD]`（`FsQuerySubtrackDetails` 调用留痕）两态**分离**：改前/反极性 `718..725`（5 样本）vs 改后 `702..715`（4 样本）。**非**症状门回归（无崩溃／无 `failfast`／帧面不变）；仅"查询次数减少"。其余两个跑次敏感计数（`no-text-line-model`／`[HC-UNHANDLED]`）两态**区间重叠**（§2.3）。
6. **反极性（④ 通过）**：显式 `WPF_PTS_FL_DRIVE=0` ⇒ **回改前**（`v=GATE-OFF calls=0`；症状门/帧面逐格同改前）。
7. **门禁（③）**：`nm -D --defined-only == exports.txt == 677`（逐名零差异）；`PTSGAP=PASS tool=82 dead=11 artifact=1 ops=70 impl=73 so16=ac002caa324a496f exports=677`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`（rc=0，`DECLDRIFT=0`）；`REPORTID=PASS`（rc=0）。
8. **判决：成功（前置已解除 ⇒ 翻闸成立），但产品面仍为降级态**：`T-A28` 当年"缺省必须关"的依据（驱动撞 `Invariant.FailFast`）已由 `T-A30` 解除；本件让**缺省路径**也驱动行模型，**无崩溃/无症状门回归**；但**"从洋红占位变成真实排版"仍未发生**（内容区仍空）。

---

## §1 改动（逐处，`win32_pts.c`）

### 1.1 闸缺省值 `0 → 1`（**本件唯一语义改动**）

| 面 | 件:行（现取） | 原文 |
|---|---|---|
| 缺省宏 | `src/WpfGfx.Linux.Native/src/win32_pts.c:2069-2071`（改后） | `#ifndef WPF_PTS_FL_DEFAULT` ／ `#define WPF_PTS_FL_DEFAULT 1` ／ `#endif` |
| 读数处（**未动**） | 同上 `wpf_pts_fl_enabled()`，`:2080-2084` | `const char *e = getenv("WPF_PTS_FL_DRIVE");` ／ `g_pts_fl_gate = e ? atoi(e) : WPF_PTS_FL_DEFAULT;` |
| 闸关留痕文案 | 同上 `:2199`（改后） | `[FORMATLINE] where=%s window=in gate=0 v=GATE-OFF（仅显式 \`WPF_PTS_FL_DRIVE=0\` 才关；缺省已开）…` |

⇒ **语义**：`getenv` 返回 `NULL`（缺省）⇒ `g_pts_fl_gate = 1`（**开**）；显式 `WPF_PTS_FL_DRIVE=0` ⇒ `atoi("0") = 0`（**关**）；显式 `WPF_PTS_FL_DRIVE=1` ⇒ `1`（**开**，与缺省同）。**这是"仅显式 `=0` 才关"的字面实现**。

### 1.2 注释块（`:2063-2077`，改后）—— 保留 `T-A28` 历史依据 ＋ 记 `T-A31` 翻闸理由

逐字要点（改后现取）：`⏪ T-A28：**运行期闸**（原缺省 **关**）—— 曾以 WPF_PTS_FL_DRIVE=1 才驱。` ⇒ 保留当年"缺省关的理由是现场读数（撞 `LineBase.HandleElementStartEdge` 的 `Invariant.FailFast("We do not expect any Blocks inside Paragraphs")` ⇒ `app_rc=134`）"；**新增** `⏪ T-A31：该 abort 前置已由 T-A30 在行模型写域内解除（PRECOND-LINEMODEL-ELEMENT-SAFE-STARTS：段末行交回源自己的那个 ParagraphBreakRun ⇒ 段末收束 fsflres=2、不再越界撞 Block；闸开时 failfast=0 app_rc=143、[FORMATLINE] 7/7）⇒ 本增量照 T-A9 体例把闸翻为缺省开（撤销「缺省关」）…**。

⇒ **不删历史**（`T-A28` 的依据逐字保留），**只增**本波结论（承 `T-A9`→`T-A17` 的教训：翻闸须同趟核症状门）。

### 1.3 登记面 `tools/pts-gap-decl.txt`

| 落点 | 改前 → 改后 |
|---|---|
| `PTSGAP-DECL` 声明行 `:34` | `so16=8ad9376305404ca2` → **`so16=ac002caa324a496f`**（`tool/dead/artifact/ops/impl/exports/w66pre16` 逐字未动） |
| 新增 `T-A31` 记录块（`:55-67`，插在 `T-A28` 块后） | **只增不改**：记"闸缺省值 `0→1` ＋ 仅显式 `=0` 才关 ＋ 导出面未动 ＋ `so16` 换 ＋ 翻闸理由（`T-A30` 已解除 abort 前置）" |
| 改前 T-A28 块的 `:44` 历史描述 | **逐字保留**（"（缺省 `0`＝关）"是 `T-A28` 当趟现取态 ⇒ 不改历史件） |

### 1.4 构建（现取）

`bash build-shim.sh --symbols`（经 `heavy-slot`）⇒ **`0 错误`**；产物 `bin/libwpfwin32.so` ＝ **`ac002caa324a496f`**（**430736 B，与改前字节数相同** —— 仅常量 `0→1` ＋ 注释/文案；构建期既有的 3 条 `-W*` 警告与本次无关）；`bin/exports.txt` **逐字节未变**（`c561dda4eca311c5`／677 行）。

---

## §2 成对机读读数（**同一跑器**：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=962fec114b2d0692`；同一显示流程 A 臂 `:231`、`1280x1024x24`）

**装置（逐腿同值）**：`SYNC-APPLOCAL=PASS … drift=0 rc=0`；`AUTHORITY … == APPDIR …`；`POSTSHIM: shim=<腿的 .so> pf=1757d610a687777c（== authority ⇒ 读数可归因）`。
**五件**：`libwpfwin32.so=ac002caa324a496f（改后）｜8ad9376305404ca2（改前·改造副本还原）`／`PresentationCore.dll=e47c4b4521c54cb2（T-A30 改后，两态同）`／`PresentationFramework.dll=1757d610a687777c`／`WindowsBase.dll=3886f61b0251140e`／`wpfgfx_cor3.so=941e69902d82ef02`。

**九趟腿（`legs-{olddef×3, newdef×4, polar0×2}`）**：`olddef*` ＝ **改前** `.so` `8ad9376305404ca2`，`WPF_PTS_FL_DRIVE` **不设**；`newdef*` ＝ **改后** `.so` `ac002caa324a496f`，`WPF_PTS_FL_DRIVE` **不设**（**缺省**）；`polar0*` ＝ **改后** `.so`，显式 `WPF_PTS_FL_DRIVE=0`。

### 2.1 症状门 ＋ 帧面（逐腿，现取）

| 腿 | .so | 闸 | `app_rc` | `alive` | `failfast`／`unrec` | `magenta` | `colors` | `ink`(k24) | `ns`(k24) | `ae`(k24/k23) | `fr_sha`(k24／k23) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `legs-olddef`／`olddef2`／`olddef3` | 改前 | **缺省（关）** | 143 | yes | 0／0 | 0 | 383 | 480000 | `…FlowDocumentDemo` | 15386／0 | `ef3fd6765f18f51b`／同 |
| `legs-newdef` | 改后 | **缺省（开）** | 143 | yes | 0／0 | 0 | 383 | 480000 | `…FlowDocumentDemo` | 15386／0 | `ef3fd6765f18f51b`／同 |
| `legs-newdef2`／`newdef3`／`newdef4` | 改后 | **缺省（开）** | 143 | yes | 0／0 | 0 | 383 | 480000 | `…FlowDocumentDemo` | 15386／0 | `ef3fd6765f18f51b`／同 |
| `legs-polar0`／`polar0b` | 改后 | **显式 =0（关）** | 143 | yes | 0／0 | 0 | 383 | 480000 | `…FlowDocumentDemo` | 15386／0 | `ef3fd6765f18f51b`／同 |

`k23`（`RichTextBoxDemo`）：`app_rc=143`／`colors=383`／`ink=480000`／`ae=0`／`fr_sha=ef3fd6765f18f51b`，改前/改后/缺省/显式=0 **逐格同值**。

⇒ **① 症状门六项与改前逐格相同；`app_rc≠134`、无崩溃 ⇒ 不判红、不回退。**

### 2.2 帧面成对（**不把空白读成绿**）—— ② 的帧面那一半

| 面（本席 PIL 自算，现取） | 改前（`olddef`） | 改后（`newdef`） | 反极性（`polar0`） |
|---|---|---|---|
| `k24`／`k23` 帧 `sha16` | `ef3fd6765f18f51b` | **`ef3fd6765f18f51b`**（**逐字节同**） | `ef3fd6765f18f51b` |
| 活锚 `Beige`／`DarkGreen`／`GhostWhite`／`LightGoldenrodYellow` | 0／0／0／0 px | **0／0／0／0 px** | 0／0／0／0 px |
| 死锚 `LightGray`（**不入锚集**） | 51 px | 51 px | 51 px |
| `colors`／`ink` | 383／480000 | 383／480000 | 383／480000 |

⇒ **两页内容区仍无任何非空态像素**；`T-A30` 已建成的"段末安全收束"**未**带来绘制；⇒ **"首次出现内容"＝否**（**如实判红：产品面零进展**）。

### 2.3 三个计数的成对（② 的计数那一半）

| 计数（`grep -c`，现取） | 改前 `olddef×3` | 改后 `newdef×4` | 反极性 `polar0×2` | 判词 |
|---|---|---|---|---|
| `reason=no-text-line-model` | 107,108,108 | 105,106,107,106 | 108,108 | **区间重叠** `105..108` ⇒ 跑次敏感，**不作差异** |
| `[HC-UNHANDLED]` | 111,112,112 | 109,110,111,110 | 112,112 | **区间重叠** `109..112` ⇒ 同上 |
| `[FSQSTD]`（`FsQuerySubtrackDetails` 留痕） | **722,725,725** | **702,705,715,705** | **725,718** | 🔴 **两态分离**：改后 `702..715` ＋ 改前/反极性 `718..725`（间隙 3） ⇒ **如实登记为差异**（见 §6-3） |
| `[FORMATLINE-LINE]`／`fsflres=2`／`LINES-RECORDED`／`GATE-OFF`／`DRIVEN` | 0／0／0／3／0 | **42／7／7／0／3** | 0／0／0／3／0 | **闸开 ⟺ 驱动**（成对可判） |

---

## §3 驱动面（`[FORMATLINE]`／`[FORMATLINE-LINE]`，`legs-newdef` 逐字现取）

```
[FORMATLINE] where=FsCreatePageBottomless window=in gate=1 slot=0x7f70ceb0b2b8 attempted=3 ok_n=3 paras_total=3  calls=20 ok=3 gap=0 incomplete=0 nopara=0 v=DRIVEN geo=NOINFO-FSGEOMETRY-LAYOUT
[FORMATLINE] where=FsCreatePageFinite     window=in gate=1 slot=0x7f70cf9d0ae0 attempted=3 ok_n=3 paras_total=6  calls=40 ok=6 gap=0 incomplete=0 nopara=0 v=DRIVEN geo=NOINFO-FSGEOMETRY-LAYOUT
[FORMATLINE] where=FsCreatePageBottomless window=in gate=1 slot=0x7f70cf9d1878 attempted=1 ok_n=1 paras_total=7  calls=42 ok=7 gap=0 incomplete=0 nopara=0 v=DRIVEN geo=NOINFO-FSGEOMETRY-LAYOUT
```
**逐段（段级汇总行，逐字）**：`para=0x8 nlines=8 dcp_sum=956 complete=1`／`0x9 nlines=6 dcp_sum=571 complete=1`／`0xa nlines=6 dcp_sum=595 complete=1`（`FsCreatePageBottomless`＋`FsCreatePageFinite` 各一套）＋ `0x4 nlines=2 dcp_sum=43 complete=1`；**全部** `v=LINES-RECORDED`。
**段末行（`fsflres=2`，7 条，摘 3 条）**：
```
[FORMATLINE-LINE] … para=0x8 i=7 dcp=681 rc=0 pfsline=… dcpLine=275 fsflres=2 fforced=0 ascent=3342 descent=849 …
[FORMATLINE-LINE] … para=0x9 i=5 dcp=482 rc=0 … dcpLine=89  fsflres=2 …
[FORMATLINE-LINE] … para=0xa i=5 dcp=536 rc=0 … dcpLine=59  fsflres=2 …
```
**闸关（`legs-polar0`，逐字）**：
```
[FORMATLINE] where=FsCreatePageBottomless window=in gate=0 v=GATE-OFF（仅显式 `WPF_PTS_FL_DRIVE=0` 才关；缺省已开） calls=0 ok=0 gap=0
[FORMATLINE] where=FsCreatePageFinite     window=in gate=0 v=GATE-OFF（…）                                     calls=0 ok=0 gap=0
[FORMATLINE] where=FsCreatePageBottomless window=in gate=0 v=GATE-OFF（…）                                     calls=0 ok=0 gap=0
```

⇒ 与 `T-A30` 的"闸开 + 改后 PC"读数**逐格一致**（`calls=42 ok=7 gap=0 incomplete=0`、`fsflres=2` 7 行）；差别只是**本件让它在"缺省"下发生**（`newdef*` 未设任何 `WPF_PTS_FL_DRIVE`）。

---

## §4 反极性（**同一构建 ＋ 同一跑器 ＋ 同一 `.so`**，只差**一个 env**：`WPF_PTS_FL_DRIVE`）

| 判据 | 缺省（`newdef*`） | **显式 `=0`（`polar0*`）** | 改前（`olddef*`） |
|---|---|---|---|
| `[FORMATLINE]` 窗级 | `gate=1 … v=DRIVEN calls=42 ok=7` | **`gate=0 v=GATE-OFF calls=0 ok=0`**（**回改前**） | `gate=0 v=GATE-OFF calls=0` |
| `[FORMATLINE-LINE]` | **42**（真调台账） | **0** | 0 |
| 症状门六项 | `143/yes/0/0/383/480000` | 同 | 同 |
| 帧 `fr_sha`（k24/k23） | `ef3fd6765f18f51b` | 同 | 同 |

⇒ **反极性两证**：① **机械面** —— 只加 `WPF_PTS_FL_DRIVE=0`，`calls` 由 `42` 变 **`0`**、驱动面由 `v=DRIVEN` 变 **`v=GATE-OFF`**（**同一 `.so`**）；② **判词面** —— `polar0*` 的读数与 `olddef*`（改前件）**逐格相同** ⇒ "**显式 `=0` ⟺ 回改前**"钉死。

---

## §5 验收逐条（对 `T-A31` ③）

- **① 症状门成对；`app_rc=134`／崩溃 ⇒ 判红并回退**：§2.1 —— 缺省路径六项**逐格相同**（`143/yes/0/0/383/480000`）、`failfast=0 unrec=0`、`app_rc≠134`、无崩溃 ⇒ **不触发回退**（**绿**）。
- **② 帧面成对（两页是否首次出现非空态像素）＋ 计数成对**：§2.2 —— **仍无内容像素**（四活锚全 `0`、帧 sha 逐字节同）⇒ **"首次出现内容"＝否（如实判红：产品面零进展）**；§2.3 —— `[FORMATLINE]`／`[FSQSTD]`／`no-text-line-model`／`[HC-UNHANDLED]` 计数**全部现取成对**（其中 `[FSQSTD]` **两态分离**，如实登记）。
- **③ 导出面 `nm==exports`；`PTSGAP=PASS`；`DEFREG`／`REPORTID` rc=0**：
  - `nm -D --defined-only libwpfwin32.so` 行数 **677** == `bin/exports.txt` 行数 **677**（**逐名 `diff` 零差异**；`exports.txt` 逐字节未变）；
  - `PTSGAP=PASS tool=82 dead=11 artifact=1 ops=70 impl=73 so16=ac002caa324a496f exports=677`（rc=0，`PTSGAP_FRONTIER_STATE=NAMED`）；
  - `DEFREG=PASS declared=225 route_ids=225`（rc=0，`DECLDRIFT=0 keys=-`）；
  - `REPORTID=PASS`（rc=0；**本载体落地后**现取见 §6-7）。
- **④ 反极性：显式 `WPF_PTS_FL_DRIVE=0` ⇒ 回改前**：§4 —— **逐格回改前**。

---

## §6 边界 · `NOINFO` · 主动披露

1. **改动面（`git status --porcelain` 现取）**：`M src/WpfGfx.Linux.Native/src/win32_pts.c`／`M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` ＋ **本载体**（untracked）＋ **先于本件**的两项 untracked（`build/MilBridge/tasks-tail2/T-A31.md`／`build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`）。`bin/libwpfwin32.so`／`bin/exports.txt` 是**构建生成件**（`git ls-files` 现取 0 ⇒ 不入库），不计入手改面；`exports.txt` **逐字节未变**。
2. **代际（现取 `sha16`）**：`src/…/win32_pts.c` `bcd6a00bce9f67a2`（461075 B）→ **`d0d5f43f7a09f2b0`（461615 B）**｜`tools/pts-gap-decl.txt` `b74f6609e489b4cd`（27450 B）→ **`20cb71cda9a7a1e4`（28959 B）**｜`bin/libwpfwin32.so` `8ad9376305404ca2` → **`ac002caa324a496f`**（**430736 B 不变**）｜`bin/exports.txt` `c561dda4eca311c5`（**未变**）｜`HEAD=fe4c4712461a6c40a3926392372d4b632c377cdc`（**未换代**）。
3. 🔴 **`[FSQSTD]` 两态分离的如实披露（本件主动点名，**新发现**）**：缺省驱动后，`FsQuerySubtrackDetails` 的**成功调用留痕数**由改前/反极性的 `718..725` 降到改后的 `702..715`（改后 4 样本上界 `715` < 反极性下界 `718`）。**归因（native 自记，非托管读数）**：驱动在 `FsCreatePage*` 窗内**枚举并建好了子段模型**（`wpf_pts_sub_enum`／`sub_child_objs`）⇒ 查询期**少了一批重复/无效的 `FsQuerySubtrackDetails` 调用**。**它不构成症状门回归**（无崩溃、无 `failfast`、帧面与症状门六项逐格不变）；但**它是"缺省驱动改变了产品行为"的机器证据**，故**不写成"零差异"**。**消掉/定性需要**：在托管查询侧插桩，指出这 `-7..-20` 次调用的**具体去处**（另一趟构建）。
4. **`NOINFO-FSGEOMETRY-LAYOUT`（承 `T-A28` §6-3，**未消**）**：`pfnFormatLine` 用的页几何（`WPF_PTS_FL_DU/DV = 180000` ＝ `600 DIP`）**仍无入站源** ⇒ 沿用本侧约定并具名 `NOINFO-FSGEOMETRY-LAYOUT`（**不**声称与上游 ABI 几何可比）；`[FORMATLINE]` 行内 `geo=NOINFO-FSGEOMETRY-LAYOUT` 现取在场。
5. **`NOINFO-FORMATLINE-PARALEN`（承 `T-A28` §6-4，**未消**）**：`ΣdcpLine == 该段符号位` 这一半仍**只有自证级**证据（末行 `fsflres=2` ⇒ 排到段尾）；独立对账（`Paragraph.SymbolCount`）**无源**（在 `PresentationFramework` 内，不在本件写域）。
6. **未做的（防被读宽）**：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；未动任何牙本体；未跑既有 parity 语料；**未实现回填**（`FsQueryTextDetails`／`FsQueryLineList*` 一字未改 —— 那是下一跳）；未改任何复述位件（`docs/**`／`HANDOFF-NEXT.md`／`samples/**`）；**未**新增任何 `D-G<digits>` 登记编号。
7. **`REPORTID` 计数（**落地后现取**）**：`REPORTID=PASS files=316 ids=2225 declared=225`（rc=0）。本载体属 `glob=build/MilBridge/*report*.md` ⇒ 落地前 `files=315`；`ids` 的增量**全部**来自本件对既有已声明编号（`D-G70`）的引用（**不新增**登记编号）。
8. **侧效（如实披露，**未进仓**）**：`~/tA31-work/`（`bak/` 四份改前件 ＋ `legs-*/` **9 趟腿**证据 ＋ 跑腿/汇总脚本）；`~/w67-work/app` 现**已同步回改后权威件**（`SYNC-APPLOCAL=PASS drift=0`）。改前腿用**副本还原**：跑前把权威 `.so` 换为 `8ad9376305404ca2`、跑后**逐字节复算换回** `ac002caa324a496f`（`AUTH_AFTER=ac002caa324a496f`（want `ac002caa324a496f`）逐腿现取）。
9. **前提边界（写死）**：本件解除的是「`WPF_PTS_FL_DRIVE` **缺省关**」这道**运行期闸**；`T-A30` 的 `PRECOND-LINEMODEL-ELEMENT-SAFE-STARTS` 是**上游前提**（已由 `T-A30` 解除）。**"从洋红占位变成真实排版"不在本件射程内**（内容区仍空 ⇒ §2.2 判红）；`PTS` 本体（`FsCreatePage*`）仍是**占位降级**，`FsQueryTextDetails` 回填**仍未实现**。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-fldrive-impl-report.md | sha256sum | cut -c1-16`）= `21e91087c7f6f618`
