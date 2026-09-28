# P1-W25 · 在册证据**最终**对齐报告（`t99`，收口）—— 判定：**无需换代**

> 车道：`runner`（重活/产品增量执行者）｜载体：`build/MilBridge/P1-evidence-retake-final-report.md`（新建）
> 本件**全部读数为本趟现取**，命令与输出原样入件；**不引任何既有报告当证据**（唯一引用的 `~/t97-runner/logs/legs4.log` 是**我自己那趟的原始日志**，非报告件）。
> 读时 `HEAD=4d87912`（`docs(#81): t94 在册证据再换代（两轴同趟，G-1 闭）+ t95 t91 余项处置（G-2~G-5）`）。

---

## 0. 一句话结论：**两轴已经同趟 ⇒ 本件不换代**

**判定依据（全部现取，两轴 + 同趟硬闸三条都过）**：

| 面 | 现权威（本趟现取） | 在册证据载的（本趟现取） | 判定 |
|---|---|---|---|
| `shim` 轴 | `sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ⇒ **`461e5557bd7dd571`** | `five_pre/five_post_g1.txt` ⇒ `libwpfwin32.so=461e5557bd7dd571`；`leg_23/24.env` ⇒ `DEV … shim=461e5557bd7dd571` | **相等 ✔** |
| `pf` 轴 | `sha256sum build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` ⇒ **`6893d1d3fb1ee110`** | 同上两件 ⇒ `PresentationFramework.dll=6893d1d3fb1ee110`；`DEV … pf=6893d1d3fb1ee110` | **相等 ✔** |
| **同趟硬闸** | —— | 我那趟的原始日志：`AUTHORITY: shim=461e5557bd7dd571 pf=6893d1d3fb1ee110 ｜ APPDIR: shim=461e5557bd7dd571 pf=6893d1d3fb1ee110` → **`POSTSHIM: shim=461e5557bd7dd571 pf=6893d1d3fb1ee110（== authority ⇒ 读数可归因）`** | **`POSTSHIM == authority` ✔** |

⇒ **`t90`／`t92`／`t95`／`t97` 之后的那一趟（`t97` 的同趟重取）已经把在册证据对齐到"所有产品改动落定之后"的现盘**，**本件无需再跑**：按派单"**若两轴已经同趟 ⇒ 如实报「无需再换代」并给出全部成对读数，不要为了跑而跑**"执行。
⚠️ **一切以现取为准**：派的背景（「`t94` 跑的时候 `t95`／`t97` 还没落定，所以大概率仍会断代」）**在现取下不成立** —— `t97` 之后又重取过一次（`app_g1.log` mtime **`2026-09-29 00:54:07`**、腿组起 `00:53:46`），那一趟就是收口值。

**⇒ 本件不写 `evidence/**` 一个字节**（下方 §2 给"改动面 0"的现取对账）；**也不重复追写 `cell=#1`**（§5：格值已是当前值，且写入时刻晚于证据落盘）。

---

## 1. ① 「需不需要」的完整成对读数（现取）

### 1.1 在册那一趟的自证（`session.txt` 头 + 我那趟日志）

```
build/MilBridge/tests/PtsPagesProbe/evidence/session.txt 头三行（现取）:
  DISPLAY_LEASE=official-caller-owned display=:237 sock=/tmp/.X11-unix/X237 xvfb_pid=3158093 owner_pid=3157509 …
  =============== GROUP 1 arm=A clicks=[24,23] 00:53:46 ===============
  shim_sha16=461e5557bd7dd571 pf_sha16=6893d1d3fb1ee110
```
· **`session.txt` 头三行里的 `shim_sha16`／`pf_sha16` 与现权威逐位相同** ⇒ 这一趟跑的就是现盘件。
· `POSTSHIM`／`AUTHORITY` 两行**不在** `session.txt` 里（装置入口 `run-pts-pages-legs.sh` 打在**自己的 stdout**）⇒ 我引**我自己那趟的原始日志** `~/t97-runner/logs/legs4.log`：`POSTSHIM: shim=461e5557bd7dd571 pf=6893d1d3fb1ee110（== authority ⇒ 读数可归因）`（同日志还有 `HEAVYSLOT=RELEASED rc=0 held=30s`）。
· **时序（现取 `stat`）**：`app_g1.log 00:54:07`｜`session.txt 00:54:09`｜`leg_23.env 00:54:10`｜`HANDOFF-NEXT.md 00:55:06` ⇒ 证据先落、`cell=#1` 后写 ⇒ **该格取样点已含本趟**（§5）。

### 1.2 ④ `entry=` 面（**含"链上下一个被撞入口"的运行期读数**）

| 项 | 现取（在册） |
|---|---|
| 直方图 | **`3 entry=LoGetPenaltyModuleInternalHandle`** ＋ **`1 entry=LoDisposePenaltyModule`** |
| `entry=unknown` | **`0`**（不增） |
| 具名行（原文） | `[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage entry=LoGetPenaltyModuleInternalHandle err=-10000 action=page-placeholder（已画出页级占位；进程继续）` |
| native 台账（原文） | `PTS_GAP entry=LoGetPenaltyModuleInternalHandle seq=4 err=-10000 calls=1` ＋ `PTS_GAP entry=LoDisposePenaltyModule seq=5 err=-10000 calls=1` |

⇒ **链上下一个被撞的入口（运行期，不是静态推断）＝ `LoGetPenaltyModuleInternalHandle`**（应用侧 3 次 + 台账 `seq=4`，两处**逐字同名**）；`LoDisposePenaltyModule` 是**清理期**那一次（`seq=5`，每进程一次）。

### 1.3 ④ `leg_*.env`（判据真正读的那几列）

```
leg_23.env: LEG k=23 alive=yes app_rc=143 magenta=49592 colors=844 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae=141985 ink=428765
            NAMED managed_unavail=1 err=-10000 native_gap=2 native_err=-10000
            DEV x_up=yes five_stable=yes shim=461e5557bd7dd571 pf=6893d1d3fb1ee110
leg_24.env: LEG k=24 alive=yes app_rc=143 magenta=54182 colors=852 ns=HandyControlDemo.UserControl.FlowDocumentDemo ae=221857 ink=424107
            NAMED managed_unavail=1 err=-10000 native_gap=2 native_err=-10000
            DEV x_up=yes five_stable=yes shim=461e5557bd7dd571 pf=6893d1d3fb1ee110
```
⇒ 两腿 `alive=yes` ∧ `app_rc=143 ∉ {134,139}` ∧ `magenta` 远高于阈值（2.4–2.7×）∧ **`native_gap=2`** ∧ `five_stable=yes`。

### 1.4 ④ `five_pre/five_post` 哈希（同趟性 + 跑腿期间未换件）

```
five_pre_g1.txt  sha16 = 68a461824686b1e7   five_post_g1.txt sha16 = 68a461824686b1e7   ⇒ 两件**同 sha16** ⇒ 跑腿期间五件未变
内容（两件逐字相同）: libwpfwin32.so=461e5557bd7dd571 / wpfgfx_cor3.so=4e25e4b27d4d5ae1 /
                     PresentationCore.dll=5b6cfda3e12b84fc / PresentationFramework.dll=6893d1d3fb1ee110 /
                     WindowsBase.dll=9e860cbeecb352e1
```

### 1.5 ④ 判据（`--legs` 默认目录 —— 门禁真读的那条）

```
$ bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence
rc=0
PTS_G10_NAME=PASS observed=LoGetPenaltyModuleInternalHandle names=2 roster=13 domains=pts-declared（形态判据：具名行**在在册名单内**；PTS 域不写死任何名字）
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded
```

---

## 2. ③ 纪律第 `29` 条（备份面 ≡ 换代面）—— **本件改动面 ＝ 0**

派单要求"改动面每件 `cp -p` 备份"。**本件判定无需换代 ⇒ 不写 `evidence/**` 一个字节**，故**无换代面**；为把"确实一件都没改"钉成读数（而不是我口头声明），现取如下：

```
$ git status --porcelain -- build/MilBridge/tests/PtsPagesProbe/evidence     ⇒ 12 个 ' M'，**全部是那趟（00:53–00:54）留下的未提交改动**（＝他人/前序在飞），不是本件产生
$ stat -c '%y %n' …/evidence/app_g1.log …/evidence/leg_23.env …/evidence/session.txt
  2026-09-29 00:54:07 / 00:54:10 / 00:54:09     ← 本件读时已 ≥ 00:5x，本件**未触碰**（未跑腿、未重取、未 `cp`）
```
⇒ **改动面 0 ＝ 备份面 0**（无需备份任何件；`t78` 漏备份 6 件的教训在本件**不适用**，因为本件没有换代面）。**如实报**，不为了"凑对账"而空跑一趟。

---

## 3. ⑤ 纪律 28：`inputs_fp` 与 `cell=#1`（**已是最新 ⇒ 不追写**）

· 现取 `bash ~/w153a/bin/infp.sh fp` ⇒ **`122b04afa7f6a1453b9f3f24d549b109666964da713a6c2cdc2dc51360c3e681`**。
· `FP-MANIFEST-TEETH` 自报 `would_be_fp=`**`122b04afa7f6a145`**（两者一致 ⇒ 覆盖面口径自洽）。
· `build/MilBridge/HANDOFF-NEXT.md`（现取 `sha256sum` `86ff5e04b696dda8`／**630** 行）**最后一行**就是 `cell=#1`：`ts=2026-09-29T00:55:06.276907971+0800`，值 ＝ `122b04afa7f6a145…` **＝ 当前值**。
· **时序对拍**：证据件 mtime `00:54:07`～`00:54:10` **早于**该格写入 `00:55:06` ⇒ **取样点已含在册那一趟**（也就是说：这一格**本来就是我上一件 `t97` 同趟写的收口值**）。
· ⇒ **本件不重复追写**（派单要求"别为了跑而跑"、纪律 28 的意图是"改了就登记"——本件没改）：追写只会把同一值再写一遍。**如实交出我的取值时刻**：`ts ∈ [本件开跑, 落盘]`（`00:5x`），与格内值**逐位相同**。
· `handoff-machine-values-check.sh` ⇒ **`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`**。

---

## 4. ⑥ 哨兵（**逐键比对，两位都查**；如实报，不写）

```
$ cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag   ⇒ IDENTICAL（两枚同 sha16 cc18d56c3fbaeb85）
哨兵内容（现取）: SHA=4e25e4b27d4d5ae1  FP=d697b1e10ff48881  PC=5b6cfda3e12b84fc
                  PF=6893d1d3fb1ee110  WB=9e860cbeecb352e1  WIN32SHIM=461e5557bd7dd571
                  HBTL=921ba9c65e9fb3be  WIC=f7b3026c8c019be2  PROVIDER=24e4e0a731dbed40
                  DWF=c83be96f18759edc   WAVE=w80-freeze  BASELINE=#80  BASELINE_SHA16=b27ff6332f263495
现盘（现取）        : WIN32SHIM=461e5557bd7dd571   PF=6893d1d3fb1ee110
```

| 键 | 哨兵内 | 现盘 | 一致？ |
|---|---|---|---|
| **`WIN32SHIM`** | `461e5557bd7dd571` | `461e5557bd7dd571` | **✔ 一致**（`t92` 之后那次换代已被写进哨兵） |
| **`PF`** | `6893d1d3fb1ee110` | `6893d1d3fb1ee110` | **✔ 一致**（`t95` 那次换代也已被写进哨兵） |
| 另八位（`SHA`／`FP`／`PC`／`WB`／`HBTL`／`WIC`／`PROVIDER`／`DWF`） | 逐键如实列出 | **逐键同值** | ✔ |
| `WAVE`／`BASELINE` | `w80-freeze`／`#80`（`BASELINE_SHA16=b27ff6332f263495`） | 同（`docs/CURRENT-STATE.md` 口径） | **标签陈旧**（与 `HEAD` 的 `#81` 不一致）——**既在项、非本件造成**；是否重写由队长定 |

牙：**`sentinel-spec-check.sh` ⇒ `SSC=PASS lines=13 keys=13 cmp=IDENTICAL`**（`SSC_VALUE=PASS key=BASELINE_SHA16 v=b27ff6332f263495`／`SSC_VALUE=PASS key=WAVE v=w80-freeze`）⇒ **无一位不一致**（`t92` 时那条 `SSC=FAIL key=WIN32SHIM` 已随哨兵跟上而消失，`t95` 的 `PF` 位亦已跟上）。

---

## 5. 不变量与受影响牙（现取）

**四条不变量**：`^run_step "` 计数 **62** ＝ `VERIFYALL-STEPS-DECL` 现声明 **`62 gen=#81`**；`[42]` 的 `--expect` ＝ **234** ＝ 覆盖面活清单 `names_n=234 manifest_n=234` ＋ **`FP_MANIFEST_TEETH=PASS reason=ok files_n=234 files_n_uniq=234 blank_n=0 declared_expect=234`**。

**已接线牙（现取）**：`SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=203`｜`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=114 sites=100 hit=0 low=10 diag=5`｜**`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`**｜`REPORTID=PASS files=240 ids=2200 declared=224`｜`DEFREG=PASS declared=224 route_ids=224`｜**`SSC=PASS lines=13 keys=13 cmp=IDENTICAL`**。
（本件未改任何覆盖面内件 ⇒ 上述牙的输入与本件之前**同一批**。）

---

## 6. 未做项与原因（如实）

1. **未换代**（派单①的判定结果）：两轴同趟、`POSTSHIM == authority` ⇒ **无需再换代**；按派单"不要为了跑而跑"**不空跑**。
2. **未写 `evidence/**`**（无换代面）⇒ **无第 29 条备份动作**（§2 给了"改动面 0"的现取证据）。
3. **未重复追写 `cell=#1`**（格值已是当前值、写入时刻晚于证据落盘，§3）。
4. **未写哨兵**（写哨兵是队长的动作；§4 已逐键报"无一位不一致"，仅世代标签陈旧）。
5. **未跑整趟门禁**（纪律禁）；**未改** `src/**`／`build/PresentationFramework.Linux/**`／`build/MilBridge/tools/**`／`verify-all.sh`／`close-wave.sh`／`docs/ROUTES.md`；**未** `git add/commit/push`。
6. **`LoGetPenaltyModuleInternalHandle` 未补**（它是**运行期现取的下一跳**，属 W8 后续跳，不在本件射程）。

---

## 7. 边界遵守自证

· **本件唯一写入 ＝ 本件载体**（`build/MilBridge/P1-evidence-retake-final-report.md`）；写域内的另外两处（`evidence/**`／`CELL=#1` 行）**本件一字未写**（理由见 §0 判定、§2 改动面 0、§3 格值已最新）。
· **腿跑纪律**：本件**未跑腿**（判定为"无需换代"）⇒ **未占显示位**、**未起 X**、**未起槽**；现扫 `/proc/*/exe` ⇒ **0 个** `Xvfb`／`xfwm4`／`HandyControlDemo` 残留（`(scan done)`）。
· **重活**：本件无重活（只跑纯读判据/牙）⇒ 未用 `heavy-slot.sh`（也不需要；如实记）。
· **台账/中间件**：`~/t99-runner/{bin,logs,bak}`（**未落 `/tmp`**）；仓根未留临时件。
· **资源（现取）**：`MemAvailable=3967596 kB`／`SwapFree=1400060 kB` ⇒ 离停手线（2000 MB／512 MB）远；`df -Pk` 余量 `72606096 kB`（≈72.6 GB，≫ 5 GB）。
· **件位 sha16**：在册件现值逐件给出（§1）＋本件自报（末行）。
· **无 `git add`／`commit`／`push`**（全程零）。
本件编排口径（自报可复算）：**正文**（`head -n -1`，157 行）sha16 ＝ `7ac0e0a09e266bcd`；**`inputs_fp` 现值** ＝ `122b04afa7f6a1453b9f3f24d549b109666964da713a6c2cdc2dc51360c3e681`；**判定 ＝ 无需换代**（两轴同趟、`POSTSHIM == authority`；改动面 **0**）。⚠️ **全文 sha16 是自指量、不可自报** ⇒ 只报正文值与 `inputs_fp`。模式 `644`。
