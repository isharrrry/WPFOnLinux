# P1-W16 · 在册证据重取报告（`t86`）—— 恢复「门禁真读的证据 ↔ 现盘九位」同趟可归因

> 车道：`runner`（重活/产品增量执行者）｜载体：`build/MilBridge/P1-evidence-retake-report.md`（新建）
> 本件**全部读数为本趟现取**，命令与输出原样入件；**不引任何既有报告当证据**。
> 读时 `HEAD=9239ce8`（`docs(#81): t83 W8 第一步独立复核载体入账`）。
> 做法与 `t78` 同法：**重跑**（不是搬运），落点＝判据的**默认**证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence`。

---

## 0. 一句话结论

**同趟性恢复**：重取后 `POSTSHIM: shim=3bd193e54785b5db pf=b3f0d129f0234b58（== authority ⇒ 读数可归因）` —— 与现权威件**逐位相同**（重取前在册件载的是 `shim=2a5165700a8c8579`／`pf=8ef62d37e7c2ce2e`，即**旧世代** ⇒ 不同趟）。
**两条关键读数（都是运行期现取）**：① **下一跳被撞的入口 ＝ `LoAcquirePenaltyModule`**（`entry=` 现取 ×3，与台账行 `PTS_GAP entry=LoAcquirePenaltyModule seq=3 err=-10000 calls=1` **逐字同名**）；② 队长裁定的那条真红 **`native-ledger-absent(PTS_GAP n=0)` 已转绿** —— `pts-pages-guard.sh --legs <默认目录>` 现取 **`rc=0`**／**`PTS_GUARD=PASS legs=2/2 fails=-`**。
**第 29 条对账成立**：改动面 **12** 件、备份面 **29** 件（＝全目录逐件 `cp -p`）＋备份回读 `BACKUP_IDENTICAL`。

---

## 1. ① 前置核对：现权威值 ↔ 在册证据载的值（把「不同趟」用读数钉死）

| 面 | 现权威（本趟现取） | 在册证据载的（重取前，本趟现取） | 判定 |
|---|---|---|---|
| `libwpfwin32.so` | `sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ⇒ **`3bd193e54785b5db`** | `five_pre_g1.txt`／`five_post_g1.txt` ⇒ `libwpfwin32.so=2a5165700a8c8579` | **不等** |
| `PresentationFramework.dll` | `sha256sum build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` ⇒ **`b3f0d129f0234b58`** | 同上两件 ⇒ `PresentationFramework.dll=8ef62d37e7c2ce2e` | **不等** |
| 腿里的 `DEV` 行 | —— | `leg_23.env`／`leg_24.env` ⇒ `DEV x_up=yes five_stable=yes **shim=2a5165700a8c8579 pf=8ef62d37e7c2ce2e**` | **不等**（与上两行同值，互相一致 ⇒ 旧世代**自洽但陈旧**） |

⇒ **「门禁真读的证据」与「现盘九位」在重取前不是同一趟**（两件权威值都不同）⇒ 那批读数**不可归因**到当前产品件。其余三件（`wpfgfx_cor3.so=4e25e4b27d4d5ae1`／`PresentationCore.dll=5b6cfda3e12b84fc`／`WindowsBase.dll=9e860cbeecb352e1`）**新旧同值**（本波未重建这三位）。

**`t87` 前置已落地（本趟现取，属"能重取"的前提）**：`build/PresentationFramework.Linux/PtsCache.Linux.cs`（sha16 `ab5851116641cc5c`）里 `NativeReport()` 一带**已按 native 返回约定（`-1` ＝ 写不下）做放大重试**，且真名读取已改到**缺口口径**（`last=` → `PtsGapCount()/PtsGapEntryName(count-1)` → `anchor=` → 兜底 `frontier=`，四者皆取不到 ⇒ `unknown`，**不猜**）—— 若不是这一步落在前，本趟重取会把 `entry=dll:NotImplemented` 那条退化读数**固化**、而不是拿到 §4 的真名。

---

## 2. ② 重取（在册、重跑、重活槽后台）

```
nohup bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- \
  env PTS_GUARD_REPO=/home/links-dev/netTest/GitProj/WPFOnLinux PTS_GUARD_DISPLAY=:237 \
      PTS_GUARD_APPDIR=/home/links-dev/w67-work/app W67_WORK=/home/links-dev/w67-work \
  bash …/build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh …/build/MilBridge/tests/PtsPagesProbe/evidence \
  > ~/t86-runner/logs/legs.log 2>&1 &
```
· **PID=2402833**，日志 `~/t86-runner/logs/legs.log`（车道目录，**未落 `/tmp`**）。
· 槽读数（逐字）：`HEAVYSLOT=ACQUIRED waited=0s`｜`HEAVYSLOT=MEMOK avail=7713MB min_avail=2500MB`｜`HEAVYSLOT=RELEASED rc=0 held=30s max_hold=1800s`（**held=30s ≪ 1800s**，无 `TIMEOUT`／`MAXHOLD_KILL`／`NOINFO low-memory`）。
· 前置（现取）：`APPSYNC: SYNC-APPLOCAL=PASS target=… items=5 ok=5 synced=0 created=0 **drift=0** noauth=0 same=0 rc=0`（**先 `--check` 得 `drift=0`，故未做 `sync`**）。
· **硬闸成对（可归因的唯一依据）**：跑前 `AUTHORITY: shim=3bd193e54785b5db pf=b3f0d129f0234b58 ｜ APPDIR: shim=3bd193e54785b5db pf=b3f0d129f0234b58`（两对**逐字相等**）→ 跑后 **`POSTSHIM: shim=3bd193e54785b5db pf=b3f0d129f0234b58（== authority ⇒ 读数可归因）`**。
· 装置自证：`X_UP=yes display=:237`（私有 `:23x` ✓）｜`DISPLAY_LEASE=official-caller-owned … xvfb_pid=2403425 owner_pid=2402843`｜同趟：`five_pre_g1.txt` 与 `five_post_g1.txt` **同 sha16**（`b4cd0fc5799063b7`）＋ `FIVE_STABLE_G1=YES`。
· 两条腿：`CLICK k=24 alive=yes expect=FlowDocumentDemo AE=221857 pts_unavail=1 **pts_gap=1** guard=1 fatal=0 unh=0`／`CLICK k=23 alive=yes expect=RichTextBoxDemo AE=141283 pts_unavail=2 **pts_gap=1** guard=1 fatal=0 unh=0`；`APP_RC=143`（`rc_reading: SIGTERM(仪器收的)`）｜`log_bytes=112700`｜`ALL_GROUPS_DONE 00:09:14`（组起 `00:08:50`）。
· 收尾（只按 PID）：装置自收 `xvfb.pid`／`xfwm.pid`；**现扫 `/proc/*/exe` 得 0 个** `Xvfb`／`xfwm4`／`HandyControlDemo` 残留；`display-lease.txt` 已随装置自撤（现取 `ls` ⇒ 无此件）。扫描时排除**自身整条祖先链**；全程**无 `pkill`／`killall`／`pgrep -f`**。
· 资源（现取）：跑前 `MemAvailable=7861004 kB`／`SwapFree=1430268 kB`／`df -Pk` 余 `72632904 kB`；跑后 `8044724 kB`／`1430268 kB`／`72630136 kB` ⇒ 离停手线（2000 MB／512 MB／5 GB）远。

---

## 3. ③ 第 `29` 条「备份面 ≡ 换代面」对账（现取）

· **做法**：跑取**之前**把整个证据目录**逐件** `cp -p` 到仓外 `~/t86-runner/bak/evidence-before/`（`find … -print0 | cpio -pdm0` 保留相对路径与时间戳，**含 `arm_A/` 下的装置同趟副本**）。
· **改动面件数 = 备份面件数**：`find <证据目录> -type f | wc -l` ＝ **29**；`find ~/t86-runner/bak/evidence-before -type f | wc -l` ＝ **29** ⇒ **相等 ✔**（`t78` 那次漏备份 6 件的问题**本趟不存在**）。
· **备份回读断言**：逐件 sha16 对拍（改动前）⇒ `BACKUP_IDENTICAL`（`diff` 空）。
· **逐件对账（改动后现取）**：**CHANGED=12，SAME=17，NEW=0，MISSING=0**：

| 件 | before sha16 | after sha16 | 判定 |
|---|---|---|---|
| `app_g1.log` | `3729b8b5aa6b3f8d` | **`e348b4ef70ab521e`** | CHANGED（换代主件） |
| `session.txt` | `c843734b5b934b64` | `1e9211b90d7aa52d` | CHANGED |
| `leg_23.env` | `99fcf0901de5f719` | `5b245a02ae5df8a8` | CHANGED |
| `leg_24.env` | `ccd9bdedc4756f6e` | `5cf62452cd3d4fb7` | CHANGED |
| `five_pre_g1.txt` | `bc0012e76e369f5c` | `b4cd0fc5799063b7` | CHANGED |
| `five_post_g1.txt` | `bc0012e76e369f5c` | `b4cd0fc5799063b7` | CHANGED |
| `device/xfwm.log` | `8f6df378c5d79ac8` | `d461229267763d24` | CHANGED |
| `shots/g1/k23.png` | `edb39dbff97652b1` | `b88846d9a2a35e31` | CHANGED |
| `shots/g1/k24.png` | `dde2ba1b594df52a` | `852da0312d50419a` | CHANGED |
| `shots/g1/last.png` | `edb39dbff97652b1` | `b88846d9a2a35e31` | CHANGED |
| `arm_A/leg_23.env` | `99fcf0901de5f719` | `5b245a02ae5df8a8` | CHANGED |
| `arm_A/leg_24.env` | `ccd9bdedc4756f6e` | `5cf62452cd3d4fb7` | CHANGED |
| `device.txt`（主） | `6d2cf7572e7323b7` | `6d2cf7572e7323b7` | SAME（都是 `X_UP=yes display=:237`） |
| `device/xvfb.log`（主） | `e3b0c44298fc1c14` | `e3b0c44298fc1c14` | SAME（0 B，装置本趟无输出） |
| `shots/g1/boot.png` | `b21eb530afd3c66c` | `b21eb530afd3c66c` | SAME（**逐字节相同**） |
| `arm_A/**` 其余 12 件 | —— | —— | SAME（装置入口本趟**未重写** `arm_A/` 那批"上一趟"镜像） |

⇒ **未静默覆盖**：改动面的每一件在改动前都已 `cp -p` 落仓外，且旧值以现取形式留档（上表 before 列）。

---

## 4. ④ 成对读数（before ＝ 现盘在册件〔＝备份面现取〕，after ＝ 本趟重取）

### 4.1 `entry=` 面（C4 那一格，也是"下一跳"的运行期读数）

| | before | after |
|---|---|---|
| `grep -o 'entry=[A-Za-z0-9_:]*' app_g1.log \| sort \| uniq -c` | `2 entry=LoSetDoc` | **`3 entry=LoAcquirePenaltyModule`** |
| `entry=unknown` 计数 | `0` | `0`（**不增** ✔） |
| 具名行原文 | `[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage entry=LoSetDoc err=-10000 action=page-placeholder（已画出页级占位；进程继续）` | **`[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage entry=LoAcquirePenaltyModule err=-10000 action=page-placeholder（已画出页级占位；进程继续）`** |
| native 台账行（`PTS_GAP`） | **0 行** | **`PTS_GAP entry=LoAcquirePenaltyModule seq=3 err=-10000 calls=1`**（**1 行**） |

**⇒ 下一跳被撞的入口 ＝ `LoAcquirePenaltyModule`**（运行期读数，**不是**静态推断）：`t81` 把 `LoSetDoc`／`LoSetBreaking` 补成真实现后，冷启链**越过了这两条**，撞上的下一条是 **已导出但恒 `-10000`** 的 `LoAcquirePenaltyModule` ⇒ 台账**留行**、应用侧记的也是**同一个名字**（两处**逐字同名**）。
⚠️ **读法纪律**：这与 `t80` §1.5 的更正一致 —— **"台账非零"本身不构成"真前进"**；本趟的"真前进"证据＝`entry=` 面**换了一条入口**（`LoSetDoc` → `LoAcquirePenaltyModule`）**且**必须**在补完 W8 第一步之后**才可能出现（重取前在册件是旧世代，读的是 `LoSetDoc`）。

### 4.2 `leg_*.env`（判据真正读的那几列）

| 列 | before | after | 判定 |
|---|---|---|---|
| `k=23 alive` | `yes` | `yes` | **不变**（零回归） |
| `k=24 alive` | `yes` | `yes` | **不变** |
| `k=23 app_rc` | `143` | `143` | **不变**（不在 `{134,139}`） |
| `k=24 app_rc` | `143` | `143` | **不变** |
| `k=23 magenta` | `50461` | `49943` | −518（**门禁阈值 20000 之上、约 2.5× 余量**，属重拍摄抖动） |
| `k=24 magenta` | `55051` | `54533` | −518 |
| `k=23/24 ink` | `428004`／`423346` | `428456`／`423798` | 微增（同族抖动） |
| `ns`（两腿） | `…RichTextBoxDemo`／`…FlowDocumentDemo` | **逐字相同** | **不变** |
| `NAMED … native_gap` | **`0`**（两腿） | **`1`**（两腿） | **0→1**（台账被点亮） |
| `NAMED … native_err` | `-` | `-10000` | 与台账 `err=-10000` 一致 |
| `DEV … five_stable` | `yes` | `yes` | 不变 |
| `DEV … shim`／`pf` | `2a5165700a8c8579`／`8ef62d37e7c2ce2e` | **`3bd193e54785b5db`／`b3f0d129f0234b58`** | **换代**（＝现权威） |

**症状统计（session.txt 里的同趟行）**：`pts_unavail=1/2`（与 before 同为"每腿一处/两处"量级）、`pts_gap **0→1**`、`guard=1`、`fatal=0`、`unh=0` ⇒ **未劣化**。

### 4.3 `five_pre/five_post` 哈希与代次

| | before | after |
|---|---|---|
| `five_pre_g1.txt`／`five_post_g1.txt` sha16 | 两件同为 `bc0012e76e369f5c` | 两件同为 **`b4cd0fc5799063b7`**（**pre == post ⇒ 跑腿期间五件未变** ✔） |
| 内容（现取） | `libwpfwin32.so=2a5165700a8c8579`／`…PresentationFramework.dll=8ef62d37e7c2ce2e` | **`libwpfwin32.so=3bd193e54785b5db`／`…PresentationFramework.dll=b3f0d129f0234b58`**（其余三件同值） |

### 4.4 `PTS-PAGES` 判据（**默认目录、带参数** —— 门禁真读的那条）

```
$ bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence
before: rc=1
  PTS_G10_NAME=PASS observed=LoSetDoc names=1 roster=10 domains=dllimport-entry decl=…/LineServices.cs:1470
  PTS_GUARD=FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0) cannot=- diag=- direction=in-file phase=degraded
after : rc=0
  PTS_G10_NAME=PASS observed=LoAcquirePenaltyModule names=1 roster=12 domains=pts-declared（形态判据：具名行**在在册名单内**；PTS 域不写死任何名字）
  PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded
```
**⇒ 队长裁定保留的那条真红 `native-ledger-absent(PTS_GAP n=0)` 已转绿**（`fails=-`），且不是靠改判据/改阈值/改相位：判据件 `pts-pages-guard.sh` 本趟**只读**（sha16 `b74d2be6f9093115`／572 行，现取同前）；转绿的原因是**证据面**的 `native_gap` 由 `0` 变 `1`（台账真非零），而 `PTS_GAP` 行**原样给在** §4.1。
⚠️ **域口径变化说明（不是缺陷）**：`domains=` 由 `dllimport-entry`（旧代 `entry=LoSetDoc` 属 LineServices 族、在声明树里对拍）变 **`pts-declared`**（新代 `entry=LoAcquirePenaltyModule` 已进 `k_pts_entries[]`）—— 这是 `t76` 判序"**先在册表、后声明树**"的**必然结果**，`roster` 也由 10 变 **12**（`t81` 加了两个名字）。

---

## 5. ⑤ 纪律 28（同趟）＋ 哨兵如实报

· `inputs_fp`：本趟写前 `bf1edb1bf82c15137dab0be3d62a0d7fdc05fb326f02434cda2d230ca1b074de` → **写后 `b97bdecc28664139a044cd5b4cfa772d8f0d7b5d9ef74d83e4cff8f691206c08`**（`bash ~/w153a/bin/infp.sh fp` 现取；独立复算同值）。
· `build/MilBridge/HANDOFF-NEXT.md` 于 **EOF 纯 `>>` 追加**一行 `⏪ **机器值契约更正 · cell=#1**：…`（dated、不自指）：
  写前 sha16 `1f8ecb4176f10e68`／**608** 行 → 写后 `691af2d853672d44`／**609** 行，`git diff --numstat` ＝ **`1 0`**（只增零删），模式不变。
  ⇒ **`handoff-machine-values-check.sh` 回 `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`**（追加前现取是 `DIVERGED … mismatch=1 reasons=,#1:covered-file-changed-since-ts`）。追加后 `inputs_fp` **复取仍同值**，`PTS-PAGES` 判词未变。
· **哨兵（如实报，未写）**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **`IDENTICAL`**（sha16 `cb322d5c54731ca9`）。**现取哨兵内容与现盘九位比对**：
  | 键 | 哨兵内 | 现盘（`wave-push.sh --dry-run` 现取） | 一致？ |
  |---|---|---|---|
  | `SHA`／`FP`／`PC`／`WB`／`HBTL`／`WIC`／`PROVIDER`／`DWF` | `4e25e4b27d4d5ae1`／`d697b1e10ff48881`／`5b6cfda3e12b84fc`／`9e860cbeecb352e1`／`921ba9c65e9fb3be`／`f7b3026c8c019be2`／`24e4e0a731dbed40`／`c83be96f18759edc` | **逐键同值** | ✔ 八位一致 |
  | `PF` | **`b3f0d129f0234b58`** | `b3f0d129f0234b58` | ✔（**哨兵已跟上 `t87` 的新 pf**） |
  | `WIN32SHIM` | **`3bd193e54785b5db`** | `3bd193e54785b5db` | ✔（**哨兵已跟上 `t81` 的新 shim**） |
  | `WAVE`／`BASELINE` | `w80-freeze`／`#80`（`BASELINE_SHA16=b27ff6332f263495`） | 同 | **与 `HEAD` 的 `#81` 不一致** ⇒ **既在的世代标签陈旧**（不是本件造成）⇒ **如实报，是否重写由队长定**（我**未**动哨兵）。 |

---

## 6. ⑥ 不变量与牙（现取入册）

**四条不变量**：
| # | 不变量 | 现取命令 | 现值 |
|---|---|---|---|
| I1 | `^run_step "` 计数 | `grep -c '^run_step "' verify-all.sh` | **`62`** |
| I2 | `VERIFYALL-STEPS-DECL` 现声明 | `grep -m1 '^# VERIFYALL-STEPS-DECL:' verify-all.sh` | **`62 gen=#81`** |
| I3 | `FP-MANIFEST-TEETH --expect` | `grep -n 'run_step "FP-MANIFEST-TEETH"' verify-all.sh` | `:1201 … --expect 234` |
| I4 | 覆盖面**活清单件数** | `bash build/MilBridge/tools/fp-manifest-step.sh --expect 234` | `names_n=234 manifest_n=234 expect=234 would_be_fp=b97bdecc28664139`／**`FP_MANIFEST_TEETH=PASS reason=ok files_n=234 files_n_uniq=234 blank_n=0 declared_expect=234`** |

⇒ I1＝I2（62）✔；I3＝I4（234）✔ ⇒ **本件只换代「已有件的内容」，未增删任何覆盖面内件**（件数仍 234，`--expect` 不需改）。

**两哨兵**：`cmp` ＝ `IDENTICAL`（见 §5）。
**已接线牙（现取，逐条）**：
| 牙 | 读数 |
|---|---|
| `REPORTID` | `REPORTID=PASS files=235 ids=2200 declared=224`（`rc=0`） |
| `DEFREG` | `DEFREG=PASS declared=224 route_ids=224`（`rc=0`） |
| `SENTINEL-SPEC` | **`SSC=PASS lines=13 keys=13 cmp=IDENTICAL`**（`rc=0`） |
| `QUOTE-TRAP` | `SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=203`（`rc=0`） |
| `PIPEFAIL-SIGPIPE` | `PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=114 sites=100 hit=0 low=10 diag=5 safe=85`（`rc=0`） |
| `HANDOFF-MV` | `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`（`rc=0`） |
| `STATIC-JAWS` | **`STATICJAWS=FAIL fails=1 n=32 excluded=30 noinfo=1 n_total=62`**（`rc=1`） |

⚠️ **`STATIC-JAWS` 那条红与**本件**无关，如实点名**：日志里被点名的项是 `STATICJAWS_RAN step=PIPEFAIL-SIGPIPE jaw=build/MilBridge/tools/pipefail-sigpipe-check.sh rc=0 stderr=0行 ms=2259` ⇒ 那是**另一族**（静态牙对某一步的自述/接线面），**不在本件写域**（`build/MilBridge/tools/**` 明列禁改），**未动**。本件只如实报告。

---

## 7. 未做项与原因（如实）

1. **未重写哨兵**（派单明示"写是队长的事"）⇒ 只见 §5 的现取比对与 `cmp=IDENTICAL`；`WAVE/#80` 与 `#81` 的标签陈旧**不是本件造成**。
2. **未跑整趟门禁**（纪律禁）⇒ 第 `[38]` 步 `PTS-PAGES` 的**步级**读数未取；本件取的是**同一条命令**（`--legs "$PTS_EVIDENCE_DIR"`，`$PTS_EVIDENCE_DIR` 现取默认值）在现树上的读数。
3. **未消解 `LoAcquirePenaltyModule` 的缺口**（诚实边界：它**必须**继续 `return wpf_pts_gap(...)`；补它是 W8 的下一步，不属本件）。
4. **未处理 `STATIC-JAWS=FAIL`**（另一族，且 `build/MilBridge/tools/**` 在禁写域）。
5. **未动** `arm_A/` 下装置同趟副本（装置入口本趟**未重写**它们 ⇒ 逐件 `SAME`；删改它们＝越域）。
6. **未改** `pts-pages-guard.sh`／`verify-all.sh`／`build/close-wave.sh`／`src/**`／`build/PresentationFramework.Linux/**`／哨兵／`docs/ROUTES.md`；**未** `git add/commit/push`。

---

## 8. 边界遵守自证

- **写域内实际被写的件**：`build/MilBridge/tests/PtsPagesProbe/evidence/**`（由**装置入口**一次性产出：换代 12 件、其余逐件 SAME）＋ 本件 ＋ `build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` 行（`>>` 追加，`numstat 1 0`）。
- **第 `29` 条**：改动面 **12** ≡ 备份面覆盖（备份取的是**全目录 29 件**，逐件 `cp -p`，回读 `BACKUP_IDENTICAL`）⇒ 无漏备份件。
- **腿跑纪律**：显示位 `:237`（`:23x` ✓）｜进程**只按 PID** 收（装置自收 pid 件；零 `pkill`/`killall`/`pgrep -f`；扫 `/proc` 时排除自身祖先链，现扫 0 残留）｜重活**全走 `heavy-slot.sh` 后台**（PID=2402833、日志在册、`held=30s`）｜**未跑整趟门禁**。
- **台账/中间件**落 `~/t86-runner/`（`bin/`／`logs/`／`bak/evidence-before/`），**未落 `/tmp`**；仓根未留临时件。
- **件位 sha16**：**跑前跑后各算一次**（§3 表内逐件给出）。
- **无 `git add`／`commit`／`push`**（全程零）；`git status --porcelain` 只列出写域内的件 ＋ 装置自己产出的 `arm_A/**`（后者的 untracked 形态与 `t78` 那次一致，我未动）。
本件编排口径（自报可复算）：**正文**（`head -n -1`，200 行）sha16 ＝ `a01e3743329c781b`；**`inputs_fp` 现值** ＝ `b97bdecc28664139a044cd5b4cfa772d8f0d7b5d9ef74d83e4cff8f691206c08`；**改动面/备份面** ＝ `12`/`29`（§3 逐件对账）。⚠️ **全文 sha16 是自指量、不可自报** ⇒ 只报正文值与 `inputs_fp`，全文值由读者现算。模式 `644`。
