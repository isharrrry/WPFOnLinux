# P1-W71 · `nmp` **托管侧类型**只读读数（`t155`）—— 结论：**① `nmp` 就是 `_firstChild`**

本件只回答**一个问题**：native 侧 `+136 → +168` 吃下的那个 `nmp`，在**托管侧**到底是**什么东西**？
（`PtsContext.HandleToObject(nmp)` 的**实际类型**／是否 `BaseParagraph` 族／是否 `ISegment`。）
**不许**读成"排版打通"、**不许**读成"驱动链已通"、**不许**读成任何页级产能结论。

---

## 0. 治具面与口径（写死）

- **仪器**：`build/PresentationFramework.Linux/PtsCache.Linux.cs` 末尾新增 `internal static class P1NmpTypeProbe`
  （**只读**：不写任何字段、不改任何行为、真实委托的**返回值与 `out`/`ref` 参数逐位透传**；
  失败只打 `NOINFO` 行）。形制照同文件 `t133` 的 `[FSCBK-CANARY]`。
- **接入**：把 `cbkgen` 的**三个读槽** `pfnGetFirstPara`／`pfnGetNextPara`／`pfnGetParaProperties`
  接成本类的**透传包装**（`PtsCache.Linux.cs:615-619` 区域，逐行见 §1 的 `numstat`）。
  ⚠️ **记账**：接线面的**封送指针**因此换代 ⇒ `[FSCBK-CANARY]` 的槽值**只准同趟内互比**（跨代比＝无意义读数）。
- **安全**：`PtsContext.HandleToObject` 内部是三条 `Invariant.Assert`（`Invariant.FailFast` **不可捕获**）
  ⇒ 本仪器**先**用 `IsValidHandle`（有界检查、越界返回 `false`、**不断言**）把门，**只有**它说"活句柄"才查表 ⇒ 断言恒真。
- **打印预算**：三槽各 12 行，到点打一行 `[NMP-TYPE-CAP]`；`PTS_NMPTYPE_OFF=1` 只关打印（接线与透传不变）。
- **原生探针**：`nmp` 的产生路径要靠 native 的**驱动探针**（`WPF_PTS_DRIVE_PROBE=1`）**主动**调 `+136`／`+168`；
  该闸**缺省关**（缺省趟的原文：`[DRIVE-PROBE-SKIP] reason=gate-off …（**未发出任何回调调用**；不许当绿）`）。
  ⇒ 本件分**两族趟**：**闸关**（判"零行为改动"）与**闸开**（取 `nmp` 读数）。
- **写域**：`build/PresentationFramework.Linux/**`（只加打印/接线）＋本载体。**未**碰 `src/WpfGfx.Linux.Native/**`、
  `build/MilBridge/tools/**`、`docs/**`、哨兵、`HANDOFF-NEXT.md`。**未**做 `git add`/`commit`/`push`。
- **`cell=#1`：有意未登记**（本波覆盖面登记归队长；本件只落读数与载体）。

---

## 1. 逐件 sha16 ＋ `numstat`（本趟现算）

| 件 | 角色 | sha16 | 备注 |
|---|---|---|---|
| `build/PresentationFramework.Linux/PtsCache.Linux.cs` | 我改的源 | `48cf0d8d7d1a90dd` | `git diff --numstat` ＝ **215 加 / 3 删**（3 删＝原三行接线被**透传包装**替换；备份见 §4） |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | **交件值 `auth_pf16`** | `0b4b65f2c6c7ffd4` | size 6134784，**mtime `2026-09-29 17:25:46.020273749 +0800`** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **交件值 `auth_so16`** | `db3c9d5c857ff376` | size 384816，mtime `2026-09-29 17:05:10.099053478 +0800`（**本件未动原生件**） |
| `src/WpfGfx.Linux.Native/bin/wpfgfx_cor3.so` | 五件之一 | `941e69902d82ef02` | 趟内 `five_pre` 行原文 |

- 托管件重建命令（重活槽内）：`dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -c Release -m:1 --nologo -v q`
  ⇒ `0 个警告 / 0 个错误 / 00:00:29.50`；`HEAVYSLOT=ACQUIRED waited=79s … RELEASED rc=0 held=30s`。
- **审计**：`auth_pf16` 由 `c52d9191feb5ba7c` → `0b4b65f2c6c7ffd4`（**本件唯一一次换代**，之后**不再碰托管件**）。

---

## 2. `[NMP-TYPE]` 原文（两样本各一，逐字）

闸开趟（`WPF_PTS_DRIVE_PROBE=1`）·样本 leg5（`~/w67-work/logs/leg5/app_g1.log`）：

```
[NMP-TYPE] slot=GetFirstPara fserr=0 fSucc=1 nms=0x2 TYPE=MS.Internal.PtsHost.ContainerParagraph nms_isBaseParagraph=1 nms_isISegment=1 nms_firstChild=MS.Internal.PtsHost.ContainerParagraph nmp=0x3 TYPE=MS.Internal.PtsHost.ContainerParagraph nmp_isBaseParagraph=1 nmp_isISegment=1 nmp_firstChild=null PAIR seg=MS.Internal.PtsHost.ContainerParagraph seg_firstChild=MS.Internal.PtsHost.ContainerParagraph nmp_eq_seg_firstChild=1
[NMP-TYPE] slot=GetParaProperties fserr=0 nms=(nil) nmp=0x3 TYPE=MS.Internal.PtsHost.ContainerParagraph nmp_isBaseParagraph=1 nmp_isISegment=1 nmp_firstChild=null PAIR=NOINFO reason=handle-zero
[NMP-TYPE] slot=GetFirstPara fserr=-100002 fSucc=0 nms=0x2 TYPE=MS.Internal.PtsHost.ContainerParagraph nms_isBaseParagraph=1 nms_isISegment=1 nms_firstChild=MS.Internal.PtsHost.ContainerParagraph nmp=(nil) PAIR=NOINFO reason=handle-zero
```

（样本 leg6 的同类行**逐字相同**，仅 `DRIVE-PROBE2` 里的槽地址不同。）

**同趟原生侧原文（我自己这代现取的，非转述）**：

```
[DRIVE-PROBE2] where=FsCreatePageBottomless window=in nms136=0x2 t3=0 rc136a=0 fSucc1=1 nmp1=0x3 rc136b=0 fSucc2=1 nmp2=0x3 idem136=1 rc168=0 v136=FIRSTPARA-HANDLE v168=BASE-PARA-ACCEPTED slot136=0x729730a4ac88 slot168=0x729730a4acb8
```

**代际对拍（`t151`）**：`t151` 记的读数是 `rc136a=0 fSucc1=1 nmp1=0x3 rc136b=0 nmp2=0x3 idem136=1 rc168=0`，
且其**原生件**是 `db3c9d5c857ff376`；本趟 `auth_so16` **同值**（同代）⇒ **同代对拍成立**：`nmp1=0x3`／`rc168=0` 两格**逐格复现**。
⚠️ 本件**没有**引用 `t151` 的任何"结论"；只把**我这代**的原文与它的 `sha16` 摆在同一行。

---

## 3. `_firstChild` 可达性（本条是结论的支点）

**可达**（**不是** `NOINFO`）：`ContainerParagraph._firstChild` 是**实例私有字段**，用反射逐基类找
（`System.Reflection.BindingFlags.NonPublic|Instance|Public`）**只读**取值，不改任何状态。

- `nms`（`0x2`）＝ `MS.Internal.PtsHost.ContainerParagraph`，`isBaseParagraph=1`、`isISegment=1`，
  其 `_firstChild` ＝ **`MS.Internal.PtsHost.ContainerParagraph`**（非 `null`）⇒ **同位可比**。
- `nmp`（`0x3`）＝ `MS.Internal.PtsHost.ContainerParagraph`，`isBaseParagraph=1`、`isISegment=1`，
  其自身 `_firstChild` ＝ `null`（**叶子容器**：自身没有子段 ⇒ 与"它是段里第一个段"相容）。
- **成对读数**：`PAIR … nmp_eq_seg_firstChild=1` ⇐ **对象同一性**（`ReferenceEquals(nms._firstChild, HandleToObject(nmp))`），
  两样本各命中 **2 次**、**0 次 `0`**（`grep -o 'nmp_eq_seg_firstChild=[01]' | sort | uniq -c` ⇒ `2 1`）。
- 另有一格**具名 `NOINFO`**（不掩盖、不算绿）：`GetParaProperties` 槽本仪器按 `nms=(nil)` 记 ⇒
  `PAIR=NOINFO reason=handle-zero`（该槽**没有**"段"入参，成对读数**在定义上不成立**）。

---

## 4. 两趟样本一致性表（闸开；`leg5` / `leg6`）

| 格 | leg5 | leg6 | 一致 |
|---|---|---|---|
| `[NMP-TYPE]` 行数 / `-CAP` | 14 / 1 | 14 / 1 | ✔ |
| `slot=GetFirstPara fserr=0 fSucc=1` | 2 | 2 | ✔ |
| `slot=GetFirstPara fserr=-100002 fSucc=0`（窗外） | 10 | 10 | ✔ |
| `slot=GetParaProperties fserr=0` | 2 | 2 | ✔ |
| `nmp`(0x3) 托管类型 | `…ContainerParagraph` | 同 | ✔ |
| `nmp_isBaseParagraph` / `nmp_isISegment` | 1 / 1 | 1 / 1 | ✔ |
| `nms`(0x2) `_firstChild` | `…ContainerParagraph` | 同 | ✔ |
| **`nmp_eq_seg_firstChild`** | **1（×2 次）** | **1（×2 次）** | ✔ |
| `nmp_firstChild` | `null` | `null` | ✔ |
| 腿账 k24（alive/rc/magenta/colors/ae/ink） | yes/143/0/383/15386/480000 | 同 | ✔ |
| 腿账 k23（同上） | yes/143/0/383/0/480000 | 同 | ✔ |

**闸关趟（`leg4`，缺省路径）**：`[NMP-TYPE]` ＝ **0 行**、`[DRIVE-PROBE-SKIP] reason=gate-off` ＝ 3 行
⇒ 缺省路径上**原生侧根本没发这三次回调** ⇒ 该趟只能用来看"零行为改动"（见 §5），**不能**当"取不到读数"读。

---

## 5. 症状门逐格对拍（**判"零行为改动"**）

对拍基准：**改前一代**的最后一趟真实腿（`~/t123-runner/logs/t152/samples/f08/`，`pf=c52d9191feb5ba7c`）
vs 我这代**闸关**趟（`~/w281-scribe/t155/leg4/arm_A/`，`pf=0b4b65f2c6c7ffd4`）。

| 格 | 改前（f08·k24／k23） | 改后（leg4·k24／k23） | 判 |
|---|---|---|---|
| `alive` | yes／yes | yes／yes | 同 |
| `app_rc` | 143／143 | 143／143 | 同（SIGTERM＝仪器收的，非崩） |
| `magenta` | 0／0 | 0／0 | 同 |
| `colors` | 383／383 | 383／383 | 同 |
| `ae` | 15386／0 | 15386／0 | 同 |
| `ink` | 480000／480000 | 480000／480000 | 同 |
| `ns` | FlowDocumentDemo／RichTextBoxDemo | 同／同 | 同 |
| `FAILLINE failfast` / `unrec` | 0／0 | 0／0 | 同 |
| `NAMED managed_unavail` / `native_gap` | 0／0 | 0／0 | 同 |
| `FRAME fr_sha` / `fr_lsha` | `ef3fd6765f18f51b`／同 | `ef3fd6765f18f51b`／同 | **同（帧面逐位）** |
| `fr_ae_boot` | 15386 | 15386 | 同 |
| `DEV pf` | `c52d9191feb5ba7c` | `0b4b65f2c6c7ffd4` | **仅此一格按设计换代** |
| `DEV shim` | `db3c9d5c857ff376` | `db3c9d5c857ff376` | 同（原生件没动） |

**`nm` 逐名（原生件，两代同值）**：`nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so`
⇒ **620** 行（`name` 逐名同一份，`sha16` 未变）／`^Fs` 具名导出 ＝ **6**。
⇒ 本件的改动**全在托管侧**，原生导出面**一名不增一名不减**（这是"零行为改动"在原生面的正面取证）。

---

## 6. 结论（三选一，本件落 **①**）

> **① `nmp` 就是 `_firstChild`（`P4` 满足）**：native 侧 `+136` 交出的 `nmp=0x3`，在托管侧是
> **`MS.Internal.PtsHost.ContainerParagraph`**（`isBaseParagraph=1` ∧ `isISegment=1`），
> 且与**段句柄 `0x2` 的 `ContainerParagraph._firstChild` 是同一个对象**（`nmp_eq_seg_firstChild=1`，
> 两样本各 2 次命中、0 次不命中）；下游 `+168` 真路径收下该句柄（`slot=GetParaProperties fserr=0`、
> 原生侧 `rc168=0 v168=BASE-PARA-ACCEPTED`）。

**口径（写死，只是口径本身）**：本结论**只**回答"`nmp` 在托管侧是什么"。
它**不**证明：排版已打通 / 页级产能 / 驱动链已通 / `+136` 在**所有**调用点上都能成功。
**反例已具名在册**：窗外调用（`window=out`／非窗内）`fserr=-100002 fSucc=0 nmp=(nil)`（两样本各 10 行）
⇒ "`nmp` 有值"这件事**有条件**（窗内），条件本身不在本件判据内。

---

## 7. 趟账（含**被拒**趟，逐条具名；不掩盖）

| 趟 | 目录 | 结局 | 具名原因（原文口径） |
|---|---|---|---|
| 1 | `~/w281-scribe/t155/leg1` | `obtained=0 refused=2` | 应用**起不来**：`XOpenDisplay(":237") 失败`（`APP_RC=134`）——见 §8 缺陷 `D-1` |
| 2 | `~/w281-scribe/t155/leg2` | `obtained=0 refused=2` | `device=NOINFO reason=display-not-free display=:237 occupant_pid=3795376`（**假占**）——见 §8 缺陷 `D-2` |
| 3 | `~/w281-scribe/t155/leg3` | `obtained=0 refused=2` | 同上（假占进程仍在） |
| 4 | `~/w281-scribe/t155/leg4` | `LEGS_RUNNER=PASS obtained=2` | 闸关（缺省路径）⇒ 只判"零行为改动" |
| 5 | `~/w281-scribe/t155/leg5` | `LEGS_RUNNER=PASS obtained=2` | 闸开 ⇒ 样本 1（结论用） |
| 6 | `~/w281-scribe/t155/leg6` | `LEGS_RUNNER=PASS obtained=2` | 闸开 ⇒ 样本 2（结论用） |

趟 4/5/6 的腿账逐格：`x_up=yes five_stable=yes shim=db3c9d5c857ff376 pf=0b4b65f2c6c7ffd4`；
`POSTSHIM … （== authority ⇒ 读数可归因）`；显示位＝**`:230`**（我的私有包装脚本现扫 `/proc` cmdline 取的**无人认领**号；
进程**只按 PID** 收：`DEVICE_REAP state=clean who=xvfb/xfwm display=:230`；趟后 `/tmp/.X11-unix` ＝ `X0 X1`）。

**跑腿的包装脚本（仓外私有，未进仓）**：`~/w281-scribe/t155/run/legs.sh`（`$1`＝证据目录，`$2=1` 开原生探针）。

---

## 8. 本件**踩到**的装置缺陷（**具名在册、不在本件写域、本件未改**）

- **`D-1` 显示号"分配值"与"下游取值"不是同一个变量**：腿跑器把 Xvfb 起在**分配**出来的号上
  （`DISPLAY_PICK display=:231 rule=lowest-free`），而 `session_inner.sh` 里的 `$D` 取自 **`W67_DISPLAY`**
  （缺省 `:237`）⇒ 应用被喂了 `:237` 而 Xvfb 在 `:231` ⇒ `XOpenDisplay(":237") 失败` ⇒ `APP_RC=134`。
  **判据面**：`obtained=0 refused=2`（不静默少样本）⇒ 下游拒跑记账正确。
- **`D-2` `occupied_by()` 的**假占**：按 `/proc/*/cmdline` 扫显示号**字面**，
  于是**别的写者**壳的命令行里恰好含 `:237` ⇒ `display-not-free`（本件实测 occupant_pid=3795376 是
  `~/t123-runner/logs/t152` 那侧的 `bash -c`，**不是** X server）。本件用"现扫无人认领号 ＋ 号只放脚本里"绕过，**未改判据件**。
- 两条都**只报不改**：`run-pts-pages-legs.sh`／`session_inner.sh` 属 `build/MilBridge/tests/PtsPagesProbe/**`，**不在 `t155` 写域**。

---

## 9. 备份面 ≡ 换代面

- 写前 `stat -c %h` ＝ **1**（单链接）；备份 `cp -p` 取在**任何写之前**：
  `~/w281-scribe/t155/bak/PtsCache.Linux.cs.pre-t155`（`links=1 mode=644 size=97633 sha16=c7d97972e9e71dda`，
  与改前仓内件 `cmp` 相同）；落仓用 `edit` 定点替换 ＋ 文件尾追加（无整文件重写）。
- **交件后不再碰任何托管件**（`build/PresentationFramework.Linux/**`，含 `.cs` 与重建）——
  `t152` 要在 `auth_pf16=0b4b65f2c6c7ffd4` 这一代上跑满；若需再改托管件，**先发消息给队长**。
- 覆盖面指纹（本人现取，**只作记录**）：`bash ~/w153a/bin/infp.sh fp` ⇒
  `3d1f28abc87db965180bd65aca1cdd7cc0fa3ce4bc07ac4763d590e35f1b2434`。

self16=d848e70750cea454
