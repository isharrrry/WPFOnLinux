# P1-W28 · 自检卫生报告（`t102`）—— `F-1` 带历史路径漏活条目 ＋ `F-2` 自检扰动自身导出计数面

> 车道：`runner`（重活/产品增量执行者）｜载体：`build/MilBridge/P1-selfcheck-hygiene-report.md`（新建）
> 本件**全部读数为本趟现取**，命令与输出原样入件；**不引任何既有报告当证据**（复核者的两条缺陷只当**线索**，其读数我**全部重算并复现**）。
> 读时 `HEAD=e528f53`｜基线 `win32_pts.c f34cb7c37c3cc61d`／`.so 461e5557bd7dd571`／导出 **565**／名册 **13** 名。

---

## 0. 一句话结论

**两条 medium 都真修了，且各自的"能证伪"都实测有牙。**
· **`F-1`**：主链与两个夹具里**所有** `g_pts_loc_live_n` 断言由**绝对值**改成 **`base` 相对**（`base`＝自检/夹具enter 时的活数）⇒ **带历史路径不再早退、不再漏活条目**；并**新增格 `83`**（"登记表必须回到 `base`"）把"不带泄漏"变成**可证伪的出口断言**。
· **`F-2`**：`g_pts_pen_sets`／`g_pts_pen_rejected` 在**三处**（自检入口保存＋负极性夹具出口＋`f4_binding` 出口）一并 save/restore ⇒ 自检**不再扰动它自己新导出的** `PtsPenaltyModuleAcquisitions()`；并**新增格 `84`**。
· **`F-5`／`F-6` 落册**（口径句入源码注释）。
· **导出面零位移**：`exports.txt` 与修前**逐行相同**（**565**），`.so` 动态导出**名集合逐名相同**（新助手一律 `static`）。
· 验证链全过：`PTSGAP=PASS`／两腿 `alive=yes app_rc=143 native_gap=2`／`PTS-PAGES rc=0 PTS_GUARD=PASS`。

---

## 1. `F-1`（medium）—— 带历史路径漏活条目

### 1.1 修前复现（**先复现，再修**；这正是复核者的那条）

复现配方：**同一进程**里先建 1 个**不销毁**的上下文（＝"带历史"前置），再连续调 3 次自检，每次都读**公开只读口**：`WpfLinuxWin32_PtsGapReport()` 行里的 `loc_live=` 与 `WpfLinuxWin32_PtsPenaltyModuleAcquisitions()`。

```
$ <反腿夹具 A：主链 live_n 断言用绝对值（＝修前形态）> h
START hist=1 loc_live=1 acq=0
RUN1 rc=0 diag=25 loc_live=2 acq=0      ← 漏 1 个活条目，且**判词是 25**（"创建后 live==1"那条绝对值断言）
RUN2 rc=0 diag=25 loc_live=3 acq=0      ← 再漏 1
RUN3 rc=0 diag=25 loc_live=4 acq=0      ← 再漏 1；`WPF_PTS_LOC_MAX=8` ⇒ 再 4 次即满，之后 `LoCreateContext` 起会被拒
```
⇒ **与复核者实测逐项一致**（`1→2→3→4`、`creates/destroys` 不动、`rc=0 diag=25` 三次相同）⇒ **是"下一趟更红"之源**。
**机制（现取源码位）**：`g_pts_loc_live_n != 1`（`:1036`）等**绝对值**断言在"带历史"时**在链条中段就红** ⇒ **早退**，而早退那一刻**已经建过一个上下文**、清理段还没跑到 ⇒ 每次调用漏一个。

### 1.2 修法（两条同时，逐条可核）

① **所有自身的 `live_n` 断言一律 base 相对**（本件改的四处**主链**＋两个夹具各自的 base）：

| 位 | 修前 | 修后 |
|---|---|---|
| 主链"创建后" | `g_pts_loc_live_n != 1` → `rc=25` | **`g_pts_loc_live_n != base + 1`** |
| 主链"销毁后" | `!= 0` → `rc=27` | **`!= base`** |
| 主链"两个活上下文" | `!= 2` → `rc=42` | **`!= base + 2`** |
| 主链"无泄漏" | `!= 0` → `rc=71` | **`!= base`** |
| 报告行三条 | **字面 `=0` 匹配**（`io_live=0`／`loc_live=0`／`setdoc_sets=0`…） | **解析出数后与 `base`／`save_*` 比**（新增 `static` 助手 `wpf_pts_report_field()`） |
| `wpf_pts_neg_polarity()` | 无 base | 入口记 `nb`，出口断言 `live_n == nb`（`rc=79`） |
| `f4_binding()` | 已有 base（`t97` 加的） | 保留，并把出口断言补齐 |

② **新增格 `83`**：`else if (g_pts_loc_live_n != base) rc = 83;` —— **"自检不带泄漏"的出口断言**（可证伪）。
（**旧格号与 `80/81/82` 一个都没动**；纪律第 `30` 条满足。）

### 1.3 修后成对读数（**纪律第 `30` 条三格**）

**正腿 —— fresh 进程**（独立进程，自检**第一次**调用；此前无任何 LS 上下文）：

| 格 | 现取 |
|---|---|
| ① 进程新鲜度 | **fresh**：该进程在自检前**未建过任何上下文**（`loc_live=0`） |
| ② 依赖的前置量 | `base=0`；`g_pts_loc_live_n=0`；`g_pts_pen_sets=0`；`g_pts_jmp_n=0` |
| ③ 判词 | **`selfcheck=1 diag=0`**，且**连跑两次均 `1/0`**（幂等） |

```
$ <本件真实现>（fresh）
START hist=0 loc_live=0 acq=0
RUN1 rc=1 diag=0 loc_live=0 acq=0
RUN2 rc=1 diag=0 loc_live=0 acq=0
RUN3 rc=1 diag=0 loc_live=0 acq=0
```

**带历史腿 —— 独立进程**（前置逐条可复现：`LoCreateContext()` **一次**、**不销毁**）：

```
$ <本件真实现> h
START hist=1 loc_live=1 acq=0
RUN1 rc=1 diag=0 loc_live=1 acq=0      ← **不再 +1**；判词从 25 变成 0
RUN2 rc=1 diag=0 loc_live=1 acq=0
RUN3 rc=1 diag=0 loc_live=1 acq=0
POST history=1 extra_ctx_still_ok_destroy=0      ← 调用方那个上下文**仍然完好可收**
```
⇒ **`loc_live` 恒为 `base`（1）**、三次调用**不涨**、**判词从"带历史的红（diag=25）"变成绿（0）**，且**不误伤调用方状态**。

**两类误导形态（判据 §5-3 要求写清，本件给现成例子）**：
1. **"带历史的红＝假红"**：上表**反腿 A 那三行**就是 —— 同一个 `.so` 在 fresh 档 `1/0`、带历史档 `0/diag=25`，**成因是调用序（外面还开着别人的上下文）**，**不是实现坏了**。
   ⇒ **本件把它从"要靠人识别"改成"结构上不再发生"**（断言一律 base 相对）；**并把它变成可证伪的出口断言**（格 `83`）。
2. **"fresh 的绿＝假绿"**：fresh 只证"在该前置下没红"；本件把"**真的没漏**"压在**格 `83`**（出口活数 == base）与**调用方那句 `POST history=1 extra_ctx_still_ok_destroy=0`** 上 —— 后者证明**自检没动调用方的对象**。

---

## 2. `F-2`（medium）—— 自检扰动它自己新导出的计数面

### 2.1 修前复现（**两道都拆的形态** ＝ 修前真实形态）

```
$ <反腿 D：去掉 pen 的 save/restore ＋ 删掉格 84（＝修前）>（fresh）
START hist=0 loc_live=0 acq=0
RUN1 rc=1 diag=0 loc_live=0 **acq=3**
RUN2 rc=1 diag=0 loc_live=0 **acq=6**
RUN3 rc=1 diag=0 loc_live=0 **acq=9**
```
⇒ **每次自检使 `PtsPenaltyModuleAcquisitions()` +3**（**且判词全绿** —— 这就是"**绿着漏**"，与复核者实测 `0→3→6→9` 逐项一致）。
**为什么是 +3（本趟逐处定位，比复核者多给一处）**：① 主链对 `loc_a` 成功 acquire 一次；② 负极性夹具内部真调一次；③ 夹具内第一次调用会**再落一次**（`penalty_acquisitions` 与全局计数同源）⇒ **三处**。

### 2.2 修法（三处 save/restore，逐处可核）

| # | 位 | 修前 | 修后 |
|---|---|---|---|
| ① | 自检入口 | `g_pts_pen_sets` **未保存** | **`int save_pen_sets = g_pts_pen_sets, save_pen_rej = g_pts_pen_rejected;`**（落在链条动任何计数**之前**的最前处） |
| ② | 负极性夹具出口（`wpf_pts_neg_polarity`） | 复原了 doc/break/loc，**没复原 pen** | 入口记 `npen/npenrj`，出口 **`g_pts_pen_sets = npen; …`** |
| ③ | `f4_binding()` 出口 | 没有 pen 复原 | 入口记 `f4_pen/f4_penrj`，出口 **复原** |
| ④ | 自检末尾复原段 | 无 pen | **`g_pts_pen_sets = save_pen_sets; g_pts_pen_rejected = save_pen_rej;`** |

**并新增格 `84`**：`else if (g_pts_pen_sets != save_pen_sets) rc = 84;`。

### 2.3 修后成对读数（三格）

**正腿 fresh**：
```
① fresh（该进程自检前未建上下文、未 acquire）  ② base=0／live_n=0／pen_sets=0／save_pen_sets=0
③ RUN1/2/3 均 selfcheck=1 diag=0 且 **acq 逐次同值 = 0**
```
**带历史腿（独立进程）**：
```
① 同进程 + 已发生调用序：LoCreateContext()×1（不销毁）  ② base=1／live_n=1／pen_sets=0
③ RUN1/2/3 均 selfcheck=1 diag=0 且 **acq 逐次同值 = 0**
```
**成对（修前 → 修后）**：`Acquisitions()` 面 **`0→3→6→9` ⇒ `0→0→0`**（**逐次同值**）；**别的已复原面不回退** —— 同一读数行里 `loc_live` 恒为 base、`setdoc/break/doc` 面在修后仍由既有格 `32` 守着（现取 `diag=0` 即那些断言全过）。

### 2.4 我的两条反腿夹具（**能证伪**，逐条给读数）

| 反腿 | 唯一改动 | 现取读数 | 结论 |
|---|---|---|---|
| **B**（去复原） | 删掉三处 pen 复原、基线写死 | `rc=0 **diag=84**`、`acq=3/6/9` | **格 `84` 当场红并点名** ⇒ 该格**有牙** |
| **C**（去断言） | 保留复原、只删格 `84` | `rc=1 diag=0`、`acq=0/0/0` | 复原**独立成立**；⇒ **格 `84` 是"给未来回归"的牙**（今天删了也不会红 —— 这是**如实**的强度说明） |
| **D**（两道都拆＝修前） | 去复原 ＋ 去断言 | `rc=1 diag=0`、**`acq=3/6/9`** | **"绿着漏"** ⇒ 修前真实形态复现 |

---

## 3. `F-5`／`F-6` 同趟落册（口径句，**实现不动** —— 理由逐条）

**`F-5`（反腿判据期望的 `reason` token 未实现）** —— 落点：`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` 一带的**在册注释** + 本节。
· **事实（我现取核过）**：P1/P3/P4/P7 那几条判据里期望的 `reason=decl-vs-live-mismatch`／`reason=entry-name-not-backtraceable`／`reason=cross-run-pairing`／`reason=symptom-column-not-derived` **在 `build/MilBridge/tools/**` 里命中 0**（只有 `ledger-nonzero-frontier-unchanged` 在册，来自 `pts-gap-count-check.sh` 的 `FAKE-PROGRESS` 腿）。
· **判并写清**：**不改实现**（实现那四个 token 属于 `build/MilBridge/tools/**`，**本件禁写域**；而且"造四个新字符串"并不增加任何守卫力）⇒ **落口径句**：**那四条反腿只能由人工判定（点名到字段/格号），判据不得因为"看到某个 `reason=` token"而发绿，也不得因为"没有这个 token"而判红**；真正承重的点在**点名**（缺 `reason=`／缺 `file:`／缺字段名 ⇒ 该条判不成立）。
· **落点**：本件载体本节 ＋（注释面）`win32_pts.c` 的格 4 注释块里加一句指向（只增不改）。

**`F-6`（`PtsPenaltyModuleHandleAt(idx)` 是位置读）** —— 落点：**源码注释**（实现不动）。
· **事实（我现取核过）**：登记表是 **LIFO 紧凑表** ⇒ 任何 `LoDestroyContext()` 都会**换位**；复核者实测"销毁 `c1` 后 `HandleAt(0)` 变成 `h2`"。
· **判并写清**：**不改实现**（改成"按句柄查"就等于**多一个按内容匹配的读口**，会把"位置语义"偷偷换成"身份语义"，而调用方需要的是"第 idx 个在册对象"这个**位置**语义；且它已被 `f4_binding` 的 base 相对断言用着）⇒ **落口径句（写进源码注释）**：**调用方不得跨销毁缓存 `idx`**；每次查询前必须**重新按当前登记表**计算 idx（`f4_binding` 就是现成的正确用法）。
· **落点**：`WpfLinuxWin32_PtsPenaltyModuleHandleAt()` 函数头上方的注释（只增不改）。

---

## 4. 导出面（③）—— **零位移，逐个可核**

```
$ diff <(sort bin_exports.txt.pre-t102) <(sort bin/exports.txt)        ⇒ 空（EXPORTS_IDENTICAL）
$ diff <(nm -D --defined-only .so.pre | awk '{print $3}' | sort) \
       <(nm -D --defined-only .so     | awk '{print $3}' | sort)        ⇒ 空（SO_EXPORT_NAMES_IDENTICAL）
$ wc -l < bin/exports.txt ⇒ 565 ；nm 动态定义行 ⇒ 565
```
⇒ **`nm` ＝ `exports.txt` ＝ `565`（不增不减）**：本件新增的助手（`wpf_pts_report_field()`）**一律 `static`** ⇒ **不进导出面**；**没有任何**新导出符号 ⇒ 无需逐名点名补充（**"导出数变化"这件事本件没发生**）。

---

## 5. 验证链（④⑤⑥⑦，全部现取）

| 项 | 读数 |
|---|---|
| 重建 `.so` | 槽 `ACQUIRED waited=0s`／`RELEASED rc=0 held=2s`（`heavy-slot.sh` 后台）；产物 **346472 B**；**0 警告 0 错误** |
| 指纹 | `win32_pts.c f34cb7c37c3cc61d → dd37a51b…`（见 §7）｜`.so 461e5557bd7dd571 → **`4e999451e9ab137e`**`｜`exports.txt` **逐行相同** |
| `PTSGAP` | **`PASS tool=96 dead=11 artifact=1 ops=84 impl=90 so16=4e999451e9ab137e exports=565`**（只同趟换声明件的 `so16` 一位；另同趟同步 1 处复述位 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `97/85/91 → 96/84/90` —— 它在我落盘期间被别的车道更新过一半）＋ `FRONTIER_STATE=NAMED frontier=LoGetPenaltyModuleInternalHandle` |
| 前置 | `SYNC-APPLOCAL` 先 `DRIFT rc=3` ⇒ **按要求先 `sync` 至 `drift=0`** 才跑腿 |
| 冷启腿 | `AUTHORITY: shim=4e999451e9ab137e pf=6893d1d3fb1ee110 ｜ APPDIR: 同值` → **`POSTSHIM: shim=4e999451e9ab137e pf=6893d1d3fb1ee110（== authority ⇒ 可归因）`**；两腿 `LEG … alive=yes app_rc=143 magenta=49592/54182`、`NAMED … native_gap=2 native_err=-10000`、`DEV … shim=4e999451e9ab137e`；`HEAVYSLOT=RELEASED rc=0 held=31s` |
| **第 `29` 条** | 证据目录**全目录 29 件**逐件 `cp -p` 到仓外 ⇒ **改动面 29 ≡ 备份面 29**、回读 `BACKUP_IDENTICAL`；逐件 **CHANGED=12／SAME=17／NEW=0／MISSING=0** |
| **纪律 28** | `inputs_fp`：`797f97138675df13…`（修法落定后）→ **`c62441ca6c548636…`**（再落 `F-5`/`F-6` 口径句注释后；**单变量归因**：把源件换回注释前版本 ⇒ `797f9713…`，复原 ⇒ `c62441ca…` 且 `RESTORE_IDENTICAL`）；`HANDOFF-NEXT.md` EOF **纯 `>>`** 追写 `cell=#1` 两次（`80d9df2aa0a0268f`/645 → `7e642d6fea047e28`/646 → **`b9fca067a2daa898`/647**），`numstat` 分别 `1 0`／`2 0` ⇒ **`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`** |
| **⑥ 哨兵** | 两枚 `cmp IDENTICAL`；**逐键比对：`WIN32SHIM=4e999451e9ab137e` ＝ 现盘 ✔、`PF=6893d1d3fb1ee110` ＝ 现盘 ✔**，另八位同值 ⇒ **无一位不一致**；牙 **`SSC=PASS lines=13 keys=13 cmp=IDENTICAL`**（收口前一刻 `WIN32SHIM` 位曾为 `461e5557bd7dd571` ⇒ `SSC=FAIL`；**在我落盘期间该位被写到现盘值**（写哨兵＝队长的动作）⇒ 现已一致，**如实记两次读数**） |
| **不变量** | `^run_step "` 计数 **62** ＝ 现声明 **`62 gen=#81`**；`[42]` `--expect` **234** ＝ 活清单 234 ＋ `FP_MANIFEST_TEETH=PASS`（`would_be_fp=797f97138675df13`） |
| **⑦ 牙** | `SHELL_QUOTE_TRAP=PASS traps=0 files=203`｜`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 sites=100`｜**`HANDOFF_MV=PASS`**｜`REPORTID=PASS files=242 ids=2201 declared=224`｜`DEFREG=PASS declared=224 route_ids=224`｜**`SSC=FAIL`（哨兵位，见上）**｜**`STATICJAWS=FAIL fails=1`**（另一族、`tools/**` 禁写域、未动） |
| **判据复核** | `pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` ⇒ **`rc=0`／`PTS_GUARD=PASS legs=2/2 fails=-`**／`PTS_G10_NAME=PASS observed=LoGetPenaltyModuleInternalHandle names=2 roster=13 domains=pts-declared` |

---

## 6. 未做项与原因（如实）

1. **`F-5`／`F-6` 未改实现**（只落口径句）—— 理由逐条见 §3（前者在禁写域且不增守卫力；后者会偷换语义、且现用法已被断言依赖）。
2. **主链那条"创建后 `live_n`"的既有格号 `25` 未改数**（只把**比较基准**改成 `base+1`）—— 纪律要求"既有格号数值不许改"；**格号语义未变**（仍是"创建后活数应恰为 1 个"）。
3. **未写哨兵**（`WIN32SHIM` 位陈旧已如实报）。
4. **未跑整趟门禁**（纪律禁）；**未改** `build/PresentationFramework.Linux/**`／`build/MilBridge/tools/**`／`verify-all.sh`／`close-wave.sh`／哨兵／`docs/ROUTES.md`／`samples/**`；**未** `git add/commit/push`。
5. **证据重取**：**做了**（本件换代 `.so` ⇒ 两轴必断）—— 派单允许"判定必须同趟重取时先说明"：我的判定＝**必须**（否则 `PTS-GUARD` 的绿不可归因到现盘件），已按第 29 条全目录备份。

---

## 7. 终态指纹（现取）

| 件 | 写前 | 写后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `f34cb7c37c3cc61d` | **`f3ae1159a852a25a`**（**1267** 行，`wc -l` 现取） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `461e5557bd7dd571` | **`4e999451e9ab137e`**（346472 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `b81706ac335f5321` | **逐行相同**（565 行） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `so16=461e5557…` | `so16=4e999451e9ab137e`（其余格一字未动） |
| `build/MilBridge/tests/PtsPagesProbe/evidence/**` | 29 件（全备份） | 12 件换代（同趟） |

---

## 8. 边界遵守自证

· **写域内被写的件**：`src/WpfGfx.Linux.Native/**`（产品源 ＋ 两件构建产物 ＋ 声明件）＋ `build/MilBridge/tests/PtsPagesProbe/evidence/**`（§6-5 已说明"必须同趟重取"）＋ 本件 ＋ `HANDOFF-NEXT.md` 的 `cell=#1` 行（`>>`）—— **全部在派单写域内**。
· **`cp -p` 回拷坑的规避**：**没有**把任何备份件回拷进仓内；`.so`／`exports.txt` 全部由 `build-shim.sh --symbols` **重新生成**（不存在"mtime 反旧 ⇒ 静默跳过编译"）。
· **新增函数口一律 `static`**（`wpf_pts_report_field()`）⇒ 导出面零位移（§4）。
· **腿跑纪律**：显示位 **`:237`**（`:23x` ✓，且**未**把 `PTS_GUARD_DISPLAY` 写到别处）；进程**只按 PID** 收（装置自收 `xvfb.pid`／`xfwm.pid`；全程零 `pkill`／`killall`／`pgrep -f`；现扫 `/proc/*/exe` 0 残留）；重活全走 `heavy-slot.sh` 后台；**未跑整趟门禁**。
· **台账/中间件**落 `~/t102-runner/{bin,logs,bak,fixtures}`（**未落 `/tmp`**）；仓根未留临时件。
· **件位 sha16**：**跑前跑后各算一次**（§5／§7 逐件给出）。
· **资源（现取）**：`MemAvailable=3911784 kB`（≈3.9 GB，> 停手线 2000 MB）／`SwapFree=1171452 kB`（> 512 MB）／`df -Pk` 余 `72600948 kB`（≈72.6 GB，≫ 5 GB）。
· **无 `git add`／`commit`／`push`**（全程零）。
本件编排口径（自报可复算）：**正文**（`head -n -1`，214 行）sha16 ＝ `acaa217cc4d26aaf`；**`inputs_fp` 现值** ＝ `c62441ca6c5486366a8c2f0bfc06ee88dd4833ca4d0290cbd72be4302cf4d8d2`；**导出面零位移**（`nm`＝`exports`＝`565`）｜**改动件 ⊆ 备份面**（4＋29）。⚠️ **全文 sha16 是自指量、不可自报** ⇒ 只报正文值与 `inputs_fp`。模式 `644`。
