# P1-W76 · 驱动链**第三跳**：窗内用合法 `nmp`(`0x3`) 调 `pfnCreateParaclient`(`+176`) 取 `pfsparaclient`

> **本件是 `t156`（runner）的交付**：执行判据件 `build/MilBridge/P1-drive-probe3-criteria.md`（253 行／sha256 `82a3d09c5bbe99bf…`／末行自证 `6e68680b1f107d40`）—— **先完整读了 §1／§2／§3／§4／§8**。
> **写域**：`src/WpfGfx.Linux.Native/**`（`src/win32_pts.c`／`bin/exports.txt`／`tools/pts-gap-decl.txt`）＋本载体。**未碰** `build/MilBridge/tools/**`／`docs/**`／任何 `.cs`／两枚哨兵／`HANDOFF-NEXT.md` 的 `cell=#1`（**队长收口**）／装置件 `build/MilBridge/tests/PtsPagesProbe/**`（只读）。**相位位 `phase=degraded` 未动**；未跑整趟门禁；未 `git add/commit/push`。
> **纪律 28**：本件改了覆盖面内件（`win32_pts.c`／`exports.txt`／`pts-gap-decl.txt`）⇒ 触发成立；`HANDOFF-NEXT.md` 的 `cell=#1` **有意未登记**（队长收口）。

---

## §0 现取快照

| 项 | 跑前现取 | 跑后现取 |
|---|---|---|
| native 权威件 | `so16=` **见 §9**（本件构建后值），**跑前**曾为 `db3c9d5c857ff376` | 同（本件不再重建） |
| 托管权威件 | `pf16=`（现取，见 §9）：`PresentationFramework.dll` | 同 |
| 快照／前置 | `fscbk_snap` 就位（承 `t141`，`nonzero=71`）｜`sect=0x1`／`nmSegment=0x2`／`nmp=0x3`（**本件开工后现取复核**） | — |
| 资源线 | `MemAvailable`／`SwapFree`／`df` 见 §9（逐批现取） | — |

---

## §1 判据的两条**关键更正**（本件照此执行，不照抄前两跳）

### 1.1 更正一：**本跳不是幂等的**（判据 §1.2／§2.2）

托管侧 `CreateParaclient` 有 **10 处覆写**，每一处都是 `new *ParaClient(this); handle = paraClient.Handle;`（`TextParagraph.cs:113-122`／`ContainerParagraph.cs:424-433` 逐字）⇒ **连调两次应得两个不同的活句柄**，且**两个都必须 `+192` 回收**（否则托管表泄漏两条）。
⇒ **本件正腿口径（写死）**：`rc176a=0 ∧ h1≠0` ＋ `rc176b=0 ∧ h2≠0 ∧ h2≠h1` ＋ **两次 `+192` 都 `rc=0`**。
⇒ **P8（必红）**：把 `h1≠h2` 读成"非确定性/失败"＝ **反过读**。

### 1.2 更正二：**T3 必须换料**（判据 §3）

`nms`／`nmSeg` 都是 `ContainerParagraph : BaseParagraph` ⇒ 对 `+176` 的 `HandleToObject(nmp) as BaseParagraph` **是"对类型"** ⇒ **不能**当错类型反腿。
⇒ 本件 T3 用 **真 `sect`**（`Section : UnmanagedHandle`，**不是** `BaseParagraph`）喂 `+176`；`+192` 的反腿用 **`nmSeg1`**（`ContainerParagraph`，**不是** `BaseParaClient`）。两者都是 **live 句柄**（不是伪值）⇒ 新前置 `PRECOND-WRONG-TYPE-LIVE-HANDLE`（判据 `P5`）**由本件反腿现证**。

---

## §2 ② 最小证据串（五格；**跑前写死**）

```
① rc176a = 0                        （+176 首调 fserr=0）
② h1 ≠ 0                            （首调**产出**：托管回调的 `out` 形参真的被写）
③ rc176b = 0 ∧ h2 ≠ 0 ∧ h2 ≠ h1     （次调再产出**另一个**活的；判据 §2.2）
④ rc192a = 0 ∧ rc192b = 0           （**两个**都被 `+192` 接受 ⇒ 类型对＋校验通过 ⇒ 且**回收完成**）
⑤ live_before / live_after          （表内活条目数）⇒ ⚠️ **本件如实记 `NOINFO(无表内活条目只读口)`**，
                                       并写明：**不得**用"腿没崩"代替；泄漏只能用 ④ 的成对成功**间接**证
```
**P3 成对证据（判据 §4-P3，写死）**：判词必须把「`+176` **调用前** `*out == 0`（本件把 `out_pre_h1` 显式留痕）」与「调用后非零」**成对**给出，且 `+192` 的接受必须**同一趟**。缺任一条 ⇒ 判红（`reason=self-made-handle`）。

---

## §3 ③ 反腿（T3 ＋ 窗内外成对）与**零伪值**

- **零伪值**：本件**不使用任何伪值**；T3 用料 ＝ **真 `sect`**（`+176` 反腿）与 **真 `nmSeg1`**（`+192` 反腿）。真值域**逐趟现取**并列（`sect`／`nmSegment`／`nmp`），并写明 T3 所用值**不是**"伪造的小整数"，而是**真实存在的别的族句柄** ⇒ 不受"伪值必须避开真值域"约束，但也**不得**当伪值使用。
- **窗内外成对（判据 §8.3.3，写死口径）**：正腿＝入站 hook 窗内（`FsCreatePageBottomless`）；反腿＝**窗外**（`FsQueryTrackParaList`）。**代码级预判**：`+176` 路径**不读** `CurrentFormatContext` ⇒ 预期 **`窗内=0 ∧ 窗外=0`**，该组合**接受为 `WINDOW-INSENSITIVE(有据)`、不判红**（硬判"实验失败"＝**假红**）；若得「窗内=0 ∧ 窗外≠0」⇒ `WINDOW-SENSITIVE`；**只拿到一条 ⇒ `NOINFO(成因未分)`**。
- **窗外腿的护栏（写死）**：只在「该 doc **仍在册**（native 侧自记 `ctx_live`）」且已缓存**合法** `nmp` 时发调，**上限 4 次**（每调一次多一条托管活条目，回收紧跟其后）；目的是**不**撞 `PtsContext.CreateHandle` 的 `!this.Disposed`（**不可捕获 `FailFast`**，主链禁）。
- **`context 仍活` 读数（判据 §8.3.3）**：本件给 **native 侧自记**读数 —— `ctx_live` ＝「该 doc 仍在 `g_pts_doc_live[]` 登记表里（`DestroyDocContext` 成功会移出并 `free`）」，并**如实标注该口径**（它**不是**托管侧 `PtsContext.Disposed` 的读数）。**已实现的 `WPF_PTS_DRIVE_PROBE3_CTXDEAD` 反腿（编译期、缺省 0、只在副本）** 用于 §8.3.3 那条新 `FailFast` 通路；**是否可达由本件现取判定**。

---

## §4 ④ 「假进度必红 `P1–P9`」逐条对照（**跑前写死**）

| # | 假形式 | 本件的正/反对照 |
|---|---|---|
| `P1` | `fserr` 非零读成成功 | 判词**先看 `fserr`**；`-100002`／`-10000`／其它一律非成功 |
| `P2` | 零句柄当活句柄 | 绿的 ② 要求 `h≠0`；`h=0` 单列 `PARACLIENT-ZERO-HANDLE(未产出)` |
| `P3` | **native 自造句柄值** | `out_pre_h1`（调用前 `0`）＋ `h1`（调用后非零）＋ 同趟 `+192` 接受 —— **三者成对**才认 |
| `P4` | "槽被调用"当"链已通" | 判词只到"该槽返回了 X"；`[DRIVE-PROBE-ENTER]` 在场**不**构成绿 |
| `P5` | 伪值代替 T3 | **零伪值**；反腿用真 `sect`／真 `nmSeg1`；值域声明见 §3 |
| `P6` | 主链制造 `FailFast` | 主链 `NULL`／重复句柄**绝不**喂 `+192`（两条断言都是不可捕获 `FailFast`）；症状门核 `failfast=0 unrec=0` |
| `P7` | 单样本当机制 | **≥2 独立样本**（同闸状态），判词一致 |
| `P8` | "每次新建"反过读 | 见 §1.1；`h1≠h2` **是符合实现**，不是失败 |
| `P9` | **恒定绿判别器** | 🔴 `+200 FInterruptFormattingAfterPara` 是 stub ⇒ **禁用为判别器**；本件**只**做负面对照：对 `NULL` 与对**真句柄**返**同值** ⇒ 证明其无判别力。**接受性判别器只用 `+192`**，且它**必须**先过"对已知非法值必红"的自证（＝T3 反腿 `nmSeg1` ⇒ `-100002`） |

---

## §5 ⑤ `≥2` 独立样本 ＋ `R1–R7` ＋ 纪律 30 三格（**跨闸不可比**）

- 样本口径：**同一闸状态**（`WPF_PTS_DRIVE_PROBE=1`，`N=1`），**独立进程**；**值可不同、判词必须相同**；判词不同 ⇒ `NOINFO(样本不稳)`。
- `R1` 闸状态｜`R2` 探针读数（§2 五格）｜`R3` **`pfsclient` 与 `nmp` 分字段**（⚠️ 值域同形陷阱：两者都是小正整数 ⇒ **绝不许互喂**）｜`R4` 导出面逐名（无消失）｜`R5` 两页症状面｜`R6` `ENFE_TOTAL` ＋留痕面｜`R7` 同趟性（`DEV shim=`／`pf=`／`session.txt` 的 `shim_sha16`／`pf_sha16`／现盘件 四值同；**不许**拿 `legs=2/2` 当同趟证据）。
- 纪律 30 三格：① 进程新鲜度＋关键调用序（建过几个 `PtsContext`／`FsCreatePageBottomless` 几次／`+80`／`+136`／`+176`／`+192` 各几次／是否走 T3）；② 关键前置量（`sect`／`nmSegment`／`nmp` 现取、快照就位、**是否在窗内**、**该 `PtsContext` 是否仍活**）；③ 判词（`rc` ＋ `diag`，红时点名）。
- ⚠️ **"净腿不崩＝假绿"**：本件证据是 §2 的五格，**不是**"腿没崩"。

---

## §6 ⑥ `P4` 对本跳**不影响**（判据 §6，照抄）

`+176` 只要求 `HandleToObject(nmp) as BaseParagraph` 命中；`+192` 只要求 `as BaseParaClient` ⇒ **都与"是不是该页文档的第一个段落"无关** ⇒ `P4` 的剩余部分（**身份**）不影响本跳。**「就是该文档第一个段落」这类语义级断言仍须 `NOINFO`**，不得由本跳的绿支撑。

---

## §7 ⑨ 口径（**逐字**）＋ `NOINFO` 面 ＋ 边界

- **绿只准读成**：「**在今天的托管态下、在窗内，`pfnCreateParaclient`（`+176`）对合法 `nmp` 返回了一个由托管回调自己产出（`out` 形参确实被写、且下游 `+192` 接受）、且能被 `+192` 成功回收的段落客户端句柄**」。
- **不得**读成：❌"段落模型已成"／❌"排版打通"／❌"三级链已存在"／❌"两页能排版"／❌"`pfsparaclient` 可被 native 安全地长期持有"。
- **`NOINFO` 面（判据 §7.2 五条）**：① 表内 `Obj is BaseParaClient` 的**直接**读数（native 看不到托管表）；② 表内**活条目数** before/after（无只读口 ⇒ 本件第⑤格）；③ `nmp` 是**该页文档第一个段落**；④ `+176` 产出能否**真正用于排版**；⑤ `-100002` 的**具体成因**（类型不对／窗外／context 已销毁 —— 三处 `catch` 都吞进同一个 `CallbackException`）。
- **重活**：全部走 `heavy-slot --min-avail 2500 --max-hold 1800 --wait 3600` **后台**（报 PID 与日志路径；**禁** `tee` 回灌会话）；显示位只用 `:23x`、几何 `1280x1024x24`；**按 PID** 收净；**禁** `pkill`／`pgrep -f`。
- **显示号口径（现取判定后写清）**：装置 `run-pts-pages-legs.sh` 现支持"最小空闲号"自动分配（`:231..:239`）；⚠️ 但 `session_inner.sh:18` 的 `D="${W67_DISPLAY:-:237}"` **不随装置分配号联动**（`t155` 报的 `D-1`）⇒ 本件**先用一趟探明该缺陷现状**，再按**不手工固定装置号**的方式取得可归因读数（做法与依据见 §8）。

---

## §8 装置面现取（**版本边界**：`t157` 修 `D-1`／`D-2` 恰好落在本件跑腿之间）

| 腿 | 时刻 | 装置件行为（逐字现取） | 结果 |
|---|---|---|---|
| **P 腿（`D-1` 现状探针）** | `17:50:07` | `DISPLAY_PICK display=:231 rule=**lowest-free(base=:231 span=9)**`（旧形态：分配端自选号） | 🔴 **`D-1` 现形**：消费端 `session_inner.sh` 取 **`:237`**（`DISPLAY_LEASE=free display=:237`）⇒ 应用拿到 `DISPLAY=:237`（**无 X server**）⇒ `[SHIM_DIAG] XOpenDisplay(":237") 失败` ⇒ **`APP_RC=134`**（core dump）、`boot_alive=no`、`unhand=1`、转换器 rc=1 ⇒ **`LEGSCOUNT … obtained=0 refused=2 reasons=converter-rc=1,no-leg-env=1`**（**计数可见**、非静默 —— `t153` 的计数修复生效） |
| **S1／S2（本件主表两样本）** | `17:51:05` 起 | `DISPLAY_PICK display=:231 rule=**caller-fixed(W67_DISPLAY)**` | ✅ 与消费端**同源**：`session.txt` 的 `DISPLAY_LEASE=official-caller-called display=:231`（逐字 `official-caller-owned display=:231`）⇒ 号一致、应用正常 |
| **T3 副本腿** | `17:50:24` | 不用装置脚本（本件自己的 Xvfb `:239`＋直跑应用） | 不受装置版本影响 |

**装置件现取**：`build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh` mtime **`17:51:03`**、sha16 **`fb469f205b88e444`**；源码里 `⏪ t157` 的两处修法现取可见：
- **修 `D-1`**（`:206-213`）：`elif [ -n "${W67_DISPLAY:-}" ] ⇒ DISPLAY_NUM="$W67_DISPLAY"; PICK_RULE="caller-fixed(W67_DISPLAY)"` ＋ `:246 export W67_DISPLAY="$DISPLAY_NUM"`（**同一个变量单向下传，下游不再有第二个默认值可猜**）；
- **修 `D-2`**（`occupied_by()`）：改为 **socket inode → 真持有者** 判定 ＋ `is_x_server "$pid" || continue`（**只有 X server 才配当占用者**）⇒ 不再按 cmdline **字面**扫号。

**🔴 归因声明（不许含糊）**：本件主表的 **两个样本都跑在 `t157` 之后**（装置件版本一致 ⇒ **同一工具**）；P 腿跑在其**之前**，它是**装置面读数**、**不是**本件主表样本 ⇒ **不参与** `≥2 样本` 的判词一致性统计。**未改装置件一个字**（只读），装置号的取法遵守任务书「用装置自己的号分配」：S1／S2 **只给 `W67_DISPLAY=:231`**（**没有**手工固定 `PTS_GUARD_DISPLAY`），号由装置现取自该变量并与消费端同源。

---

## §9 成品与逐件读数（① ⑦）

| 件 | 跑前 sha16 | 跑后 sha16 | `numstat` |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `8089fdfea1ac6f23` | **`6d967d8843bd902b`** | **`247 0`**（**纯增**） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `db3c9d5c857ff376` | **`99093641234bcb81`** | 生成件（`.gitignore` 忽略 `bin/`） |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `1b161f0513ffb8a8`（620 行） | **`0486b3512c73d86c`**（**640 行**） | 生成件（同上，忽略） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `67613d98c1d1a7e7` | **`7244338a6fa04564`** | `1 1`（只改 `so16=`／`exports=`） |
| 本载体 `build/MilBridge/P1-drive-probe3-report.md` | （新建） | 见末行自证 | — |
| 托管权威件 `PresentationFramework.dll` | `0b4b65f2c6c7ffd4` | **`0b4b65f2c6c7ffd4`**（本件未动） | — |
| 副本产物（T3）`~/t123-runner/logs/t156/t3so/libwpfwin32.so` | — | **`c18183ed1eadefa1`**（`-DWPF_PTS_DRIVE_PROBE3_T3=1`） | **权威件跑前跑后同 sha16**（未被覆盖） |

**裁决**：`PTSGAP=PASS`（`so16=99093641234bcb81 exports=640`）｜`REPORTID=PASS`（本载体入册）｜资源线：起点 `MemAvailable 6117968 kB`／`SwapFree 1381372 kB`／`df` 余 `71182728 kB`。

---

## §10 ② 主链逐样本读数（**同闸状态**：`WPF_PTS_DRIVE_PROBE=1`、`N=1`；两样本判词**相同**）

| # | 腿 | 显示位 | `[DRIVE-PROBE3]`（逐字，除 slot 地址外**逐格相同**） |
|---|---|---|---|
| **S1** | `s1` | `:231`（`rule=caller-fixed(W67_DISPLAY)`） | `where=FsCreatePageBottomless window=in nmp176=0x3 pfsclient=0x1 t3_176=0 out_pre_h1=(nil) rc176a=0 h1=0x4 rc176b=0 h2=0x5 h2_ne_h1=1 rc192a=0 rc192b=0 skip192=0 rc192t3=-9999 rc200_null=0 rc200_hand=0 ctx_live=1 v176a=PARACLIENT-HANDLE v176=PARACLIENT-NEW-PER-CALL(h1,h2) v192=BOTH-RECYCLED v200=CONSTANT-GREEN(禁用为判别器) slot176=0x7ed17707acd0 slot192=0x7ed17707ad00 slot200=0x7ed17707b0d8 calls=1` |
| **S2** | `s2` | `:231`（同上） | **与 S1 逐字段相同**（仅 `slot176/192/200` 因 ASLR 不同：`0x7a792e84aca0/…accd0/…0b0a8`） |

**§2 五格逐格**：

| 格 | S1 | S2 | 判 |
|---|---|---|---|
| ① `rc176a=0` | **0** | **0** | ✅ |
| ② `h1≠0` | **`0x4`** | **`0x4`** | ✅（且 `out_pre_h1=(nil)` ⇒ **`out` 确实被写**，P3） |
| ③ `rc176b=0 ∧ h2≠0 ∧ h2≠h1` | **0／`0x5`／1** | **0／`0x5`／1** | ✅ **`PARACLIENT-NEW-PER-CALL(h1,h2)`**（判据 §1.1：**不是**幂等跳） |
| ④ `rc192a=0 ∧ rc192b=0` | **0／0** | **0／0** | ✅ **`BOTH-RECYCLED`**（两次都被 `+192` 接受 ⇒ 类型对＋校验通过 ⇒ 回收完成） |
| ⑤ `live_before/after` | **`NOINFO`** | **`NOINFO`** | ⚠️ **判据 §2.4-⑤：今天无"表内活条目数"只读口** ⇒ 记 `NOINFO(无表内活条目只读口)`；泄漏只能由 ④ 的**成对成功间接**证 —— **本件绝不用"腿没崩"代替** |

**`R` 成对读数**：`R1` 闸**开**（`enter=1`／`gate-off=0`／`budget-exhausted=2`；**跨闸不可比** ⇒ 本表全部带闸状态）｜`R2` 见上｜`R3` **`pfsclient=0x1` 与 `nmp176=0x3` 分字段打印**（⚠️ 值域同形陷阱：本趟 `pfsclient` 与 `sect` **同为 `0x1`** ⇒ 本件**绝不互喂**：五次调用的第一个实参恒为 `pfsclient`、句柄实参恒为 `nms`／`nmSeg`／`nmp`／`h1`／`h2`）｜`R4` 导出面 `nm=640=exports.txt 行数`、**逐名对拍零消失**、＋20 逐名在册｜`R5` 症状面（下）｜`R6` `ENFE=0` ＋留痕面（`[DRIVE-PROBE-ENTER]=1`、`[DRIVE-PROBE]=1`、`[DRIVE-PROBE2]=1`、`[DRIVE-PROBE3]=1`、`[DRIVE-PROBE3-OOW]=4`）｜`R7` **同趟性四值同**：两腿 `DEV shim=99093641234bcb81 pf=0b4b65f2c6c7ffd4` ＋ `session.txt` 的 `shim_sha16=99093641234bcb81`／`pf_sha16=0b4b65f2c6c7ffd4` ＋ **现盘件**（`so16=99093641234bcb81`／`pf16=0b4b65f2c6c7ffd4`）⇒ **未拿 `legs=2/2` 当同趟证据**。
**症状门（两样本逐格同）**：`LEG k=23/24 alive=yes app_rc=143 magenta=0 colors=383`、`ns=RichTextBoxDemo/FlowDocumentDemo ae=0/15386`、`NAMED managed_unavail=0 native_gap=0`、`FAILLINE failfast=0 unrec=0`、`ENFE=0`。
**纪律 30 三格**：① **进程新鲜度**：两样本均 fresh；调用序（现取，app 日志）：`CreateDocContext` 6 次（含观测镜行）、入站 `FsCreatePageBottomless` 4 次、**探针只发 1 窗**（`N=1`，其余 2 次 `budget-exhausted`）；窗内 `+80`×2、`+136`×2、**`+176`×2、`+192`×2**，窗外 `+176`×4／`+192`×4；**未走 T3**（主链）。② **关键前置量**：`sect=0x1`／`nmSegment=0x2`／`nmp=0x3`（**逐趟现取**）、快照就位（`nonzero=71`，承 `t141`）、**在 `SetDocumentFormatContext` 窗内**（`FsCreatePageBottomless`）、**该 `PtsContext` 仍活**（`ctx_live=1`，口径见 §12.3）。③ **判词**：`rc176a=rc176b=rc192a=rc192b=0`、`diag=v176=PARACLIENT-NEW-PER-CALL` ＋ `v192=BOTH-RECYCLED`（**无红**）。
> ⚠️ **"净腿不崩＝假绿"**：本件证据是 §2 的五格 ＋ §11 的成对 ＋ §12 的 T3，**不是**"腿没崩"。

---

## §11 ④ **窗内外成对实验** ⇒ `WINDOW-INSENSITIVE(有据)`

| 腿 | 入口 | 窗 | `nmp176` | `rc176` | 产出句柄 | 回收 | 判 |
|---|---|---|---|---|---|---|---|
| 正腿（S1／S2） | `FsCreatePageBottomless` | **in** | `0x3`（合法） | **0** | `h1=0x4`／`h2=0x5` | `rc192a=rc192b=0` | `PARACLIENT-HANDLE` |
| 反腿（同趟，窗外） | `FsQueryTrackParaList` | **out** | `0x3`（同一合法句柄） | **0** ×4（`calls=1..4`） | `h=0x5`（首条） | **`rc192=0`** | `PARACLIENT-HANDLE(窗外)` |

逐字（S1，窗内侧；S2 同）：
```
[DRIVE-PROBE3-OOW] where=FsQueryTrackParaList window=out nmp176=0x3 pfsclient=0x1 rc176=0 h=0x5 rc192=0 ctx_live=1 v=PARACLIENT-HANDLE(窗外) calls=1
```
⇒ **窗内 `=0` ∧ 窗外 `=0`**，与判据 §8.3.3 的**代码级预判**（`+176` 路径经 `CreateParaclient → new *ParaClient(this) → UnmanagedHandle(ptsContext) → PtsContext.CreateHandle`，**不读** `CurrentFormatContext`）**一致** ⇒ **判定 ＝ `WINDOW-INSENSITIVE(有据)`**（**不判红** —— 硬判"实验失败"是**假红**）。
**护栏（写死并遵守）**：窗外腿**只在**「该 doc 仍在册（`ctx_live=1`）」且已缓存**合法** `nmp` 时发调，**上限 4 次**（实测 `calls=1..4` 后停止）⇒ **未**制造 `FailFast`（症状门 `failfast=0 unrec=0`）。
**旁证（跨腿）**：T3 副本腿在同一趟里**窗内**用**错类型**值得 `-100002`、**窗外**用**合法**值得 `0` ⇒ 与 S 腿合起来看：**`-100002` 在本跳的成因是"类型不对"，不是"窗外"**（把两者分开 —— 这正是判据 §8.2 那条"两成因只看 `rc` 分不开"的应对）。

---

## §12 ③⑤ T3 反腿（**真错类型 live 句柄**）＋ 值域声明 ＋ `context 仍活` 读数

**12.1 T3 用料（判据 §3 的"必须换料"）**：副本产物 `c18183ed1eadefa1`（编译期 `-DWPF_PTS_DRIVE_PROBE3_T3=1`，**权威件未被覆盖**：跑前跑后同 `99093641234bcb81`），应用副本跑（`cp -a` ＋ 换入副本 `.so`）。

| 处 | 喂给 | 用料 | 现取读数 | 判 |
|---|---|---|---|---|
| `+176` 反腿 | `nmp` 槽 | **真 `sect`＝`0x1`**（`Section : UnmanagedHandle`，**不是** `BaseParagraph`；同趟由 `+80` 用真 `sect` 得到 `nmSeg=0x2` ⇒ 它是**live** 的） | `rc176a=rc176b=**-100002**`、`h1=h2=(nil)`、`out_pre_h1=(nil)` | ✅ 期望命中：类型不对 ⇒ `as BaseParagraph` 落空 ⇒ `ValidateHandle` 抛 ⇒ **可捕获**（`app_alive_during=yes`、终态 `app_rc=143`＝我发的 `SIGTERM`、`unrec=0`、`failfast=0`） |
| `+192` 反腿 | `pfsparaclient` 槽 | **真 `nmSeg1`＝`0x2`**（`ContainerParagraph`，**不是** `BaseParaClient`；同趟由 `+80` 产出 ⇒ **live**） | `rc192t3=**-100002**` | ✅ **该判别器过了"对已知非法值必红"的自证**（判据 §4-P9 的硬要求） |

**12.2 🔴 值域声明（判据 §3 的硬要求，逐字口径）**：**本件未使用任何伪值**。T3 所用 `0x1`／`0x2` **不是**"伪造的小整数"，而是**真实存在的、别的族的 live 句柄** ⇒ 不受"伪值必须避开真值域"约束；真值域**逐趟现取**并列：**`sect=0x1`／`nmSegment=0x2`／`nmp=0x3`**（S1／S2／T3 三趟现取一致）⇒ 前置 **`PRECOND-WRONG-TYPE-LIVE-HANDLE`（判据 `P5`）由本件反腿现证成立**（`+176` 对**真错类型 live 句柄**返 `-100002`，且**不是** FailFast）。
**12.3 `context 仍活` 读数（判据 §8.3.3）**：`ctx_live=**1**`（正腿与窗外腿同趟现取）。**口径如实标注**：它是 **native 侧自记** —— 「该 doc 仍在 `g_pts_doc_live[]` 登记表里（`DestroyDocContext` 成功会把它移出并 `free`）」；它**不能**证明托管 `PtsContext.Disposed == false` ⇒ **不是**托管侧读数。另有只读口 `WpfLinuxWin32_PtsCtxAliveCount`（现存活上下文数）。
**12.4 判别器现取三家（P9）**：接受性判别器**只用 `+192`**（类型正好 `BaseParaClient` ＋ `ValidateHandle` ＋ 顺带清理；**已过非法值自证**）；`+184` 不用（需两个 client 且改显示信息）；**`+200` 禁用** —— 负面对照现取：`rc200_null=**0**`（喂 `NULL`，**已知非法**）与 `rc200_hand=**0**`（喂真句柄）**同值** ⇒ `v200=CONSTANT-GREEN(禁用为判别器)` ⇒ **它没有判别力**（判据 §2.3／P9 现证）。
**12.5 `WPF_PTS_DRIVE_PROBE3_CTXDEAD` 反腿（§8.3.3 那条新 `FailFast` 通路）＝ `NOINFO(本应用生命周期内不可达)`**：**逐趟现取** `grep -c 'DestroyDocContext'` ＝ **0**（S1／S2／P 腿／T3 腿**四趟全 0**）⇒ 应用从不走 `DestroyDocContext`（它被 `SIGTERM` 收）⇒ 「在已销毁 context 上调 `+176`」这条反腿**在本应用里打不出来**。**机制已在**（编译期开关、缺省 0、只在副本触发，源码在册）⇒ 若要打它，须另开一件用**能优雅退出**的装置/应用路径。**不得**用"没打出来"当"该通路不存在"。

---

## §13 ⑥ 「假进度必红 `P1–P9`」逐条成对

| # | 正腿（现取） | 反对照（现取） | 判 |
|---|---|---|---|
| `P1` | `fserr=0` 才叫成功；T3 得 `-100002` ⇒ 判 `CALLBACK-ERR` | 判词**先看 `fserr`**，`h` 非零**不**单独立功 | ✅ |
| `P2` | 绿要求 `h≠0`（`0x4`／`0x5`） | T3 的 `h=(nil)` 判 `CALLBACK-ERR`，**不**判绿；单列 `PARACLIENT-ZERO-HANDLE(未产出)` 形态 | ✅ |
| `P3` | **成对**：`out_pre_h1=(nil)` → `h1=0x4`（**同一趟**）＋ 同趟 `+192` 接受 | 本件**未**在调用前自造非零值（`out_pre` 逐趟现取为 `nil`）⇒ 无法把两者混淆 | ✅ |
| `P4` | 判词只到"该槽返回了 X" | `[DRIVE-PROBE-ENTER]=1` 在场**不**构成绿（绿来自五格） | ✅ |
| `P5` | **零伪值**；反腿用真 `sect`／真 `nmSeg1` 且**都 live**（同趟 `+80` 产出/入参） | 反腿**不空转**：`rc176a=-100002`（**红了并点名** `CALLBACK-ERR(-100002)`） | ✅ |
| `P6` | 主链 `NULL`／重复句柄**绝不**喂 `+192`（两条不可捕获 `FailFast` 断言） | 主链症状门 `failfast=0 unrec=0`（两样本）；窗内 `h1≠h2` ⇒ 无需"跳过二次回收"（`skip192=0`） | ✅ |
| `P7` | **两样本**判词**逐格相同**（`PARACLIENT-NEW-PER-CALL`＋`BOTH-RECYCLED`） | **未**用机制级措辞去支撑单样本 | ✅ |
| `P8` | `h1≠h2` 判为**符合实现**（`v176=PARACLIENT-NEW-PER-CALL(h1,h2)`） | **未**把 `h1≠h2` 读成"非确定性/失败"；反向形态 `CACHED-SAME-HANDLE` 只作"须点名缓存支"的占位 | ✅ |
| `P9` | 判别器 `+192`：T3 自证"对非法值必红"（`rc192t3=-100002`） | `+200` 对 `NULL` 与对真句柄**同值 0** ⇒ 判 `CONSTANT-GREEN` 并**点名禁用** | ✅ |

---

## §14 ⑨ `NOINFO` 清册 ＋ 具名前置状态

| # | 项 | 状态 |
|---|---|---|
| 1 | 该 `pfsparaclient` 在**托管表内且 `Obj is BaseParaClient`** 的**直接**读数 | **`NOINFO`**（native 看不到托管表；`+192` 的 `rc=0` 只是**间接**证据） |
| 2 | 表内**活条目数** before/after（第⑤格、泄漏面） | **`NOINFO(无表内活条目只读口)`**；**不得**用"腿没崩"代替（本件两样本 `failfast=0 unrec=0` 只是症状门，**不是**该格读数） |
| 3 | `nmp` 是**该页文档的第一个段落** | **`NOINFO`**（判据 §6：`P4` 的**身份**部分不影响本跳；语义级断言不得由本件绿支撑） |
| 4 | `+176` 产出的客户端**能否真正用于排版** | **`NOINFO`**（需 `FormatParaFinite` 一族，属后续跳） |
| 5 | `-100002` 的**具体成因**（类型不对／窗外／context 已销毁） | **部分**：本件已把 **类型不对 vs 窗外** 分开（§11／§12）；**"context 已销毁"这一支** ＝ `NOINFO(不可达，§12.5)`；托管侧异常类型仍未读（需托管侧读数件） |
| 6 | 该 `+176` 调用**是否在窗内**的**托管侧**确证 | **`NOINFO`**（窗内归类来自 `FlowDocumentPage.cs:136/199` 的 `using` 代码结构；`ctx_live` 只是**native 侧自记**） |

**具名前置**：`P0`(`+176` 偏移) ✅（本件 `_Static_assert` 把下标 `17` 钉死为 `40+17*8==176`）｜`P1`(快照) ✅（`nonzero=71`）｜`P2`(`PRECOND-WINDOW-FORMAT-CONTEXT`) ✅ **本槽现证"对窗不敏感"（`WINDOW-INSENSITIVE(有据)`）**｜`P3`(live `sect`) ✅｜`P4`(`PRECOND-DOWNSTREAM-ACCEPTOR`) ⚠️ **部分**（本跳不受影响）｜**`P5`(`PRECOND-WRONG-TYPE-LIVE-HANDLE`) ✅ 本件反腿现证闭合**。

---

## §15 口径 · 边界 · 纪律 · 收尾

- **绿只准读成（判据 §7.1 逐字）**：「**在今天的托管态下、在窗内，`pfnCreateParaclient`（`+176`）对合法 `nmp` 返回了一个由托管回调自己产出（`out` 形参确实被写、且下游 `+192` 接受）、且能被 `+192` 成功回收的段落客户端句柄**」。
- **不得**读成：❌"段落模型已成"／❌"排版打通"／❌"三级链已存在"／❌"两页能排版"／❌"`pfsparaclient` 可被 native 安全地长期持有"。
- **边界**：改动面 ＝ `src/WpfGfx.Linux.Native/{src/win32_pts.c, bin/exports.txt, tools/pts-gap-decl.txt}` ＋ 本载体（**全在写域内**）；**未碰** `build/MilBridge/tools/**`／`docs/**`／任何 `.cs`／两枚哨兵／`HANDOFF-NEXT.md` 的 `cell=#1`（**有意未登记**，队长收口）／装置件（**只读**；`t157` 的修改**不是我**）；相位位 `phase=degraded` **未动**；未跑整趟门禁；未 `git add/commit/push`。
- **纪律**：构建 ×2（权威 ＋ T3 副本）与全部腿（P／S1／S2／T3）**全部** `heavy-slot --min-avail 2500 --max-hold …` **后台**（日志：`build.out`／`build2.out`／`legs.out`／`legs2.out`／`t3leg.out`）；显示位只用 `:23x`（装置自取 `:231`；T3 腿 `:239`）、几何 `1280x1024x24`；**按 PID** 收净（T3 腿自起 Xvfb 按 `$XPID` 收）—— 跑后 `/tmp/.X11-unix/` 现取仅 `X0 X1`；**未用** `pkill`／`pgrep -f`；**未 `tee`** 回灌会话。
- **收尾牙**：`PTSGAP=PASS`(0)｜`REPORTID=PASS`(0)｜`SYNC-APPLOCAL=PASS drift=0`；`HANDOFF_MV` 的 `cell=#1` 与 `SSC` 哨兵属队长面。
`P1-DRIVE-PROBE3 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 8a1740c697c2c2e4（末行＝本行）`
