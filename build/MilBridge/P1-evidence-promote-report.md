# P1-W11 在册证据换代报告（`t78`）

> 车道：`runner`（重活/产品增量执行者）｜件位：`build/MilBridge/P1-evidence-promote-report.md`（新建）
> 本件**全部读数为本趟现取**，命令与输出原样入件；**不引任何既有报告当证据**。
> 读时：`HEAD=ab1ac00`（`docs(#81): t75 LS 族缺口面侦察入账`，`git log -1 --format=%h` 现取；本趟期间 HEAD 未动）。

---

## 0. 一句话结论

**换代成功、口径如实、判词按实报：**
门禁真读的那份在册证据 `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` 已由**重跑一条同趟 A 臂腿**换代（`cb0a3e5510b07790` → `3729b8b5aa6b3f8d`），
判据 `pts-pages-guard.sh --legs <默认目录>` 的形态判词由 `form=unnamed` 变为 **`PTS_G10_NAME=PASS observed=LoSetDoc names=1 roster=10 domains=dllimport-entry decl=…/TextFormatting/LineServices.cs:1470`**。
判据 `rc` **仍为 1** —— 唯一红是**另一族**的 `PTS_GAP n=0`（按队长裁定**保留为真红、不折叠**），本件**不为绿改判据、不改证据语义**。

---

## 1. ①  只读取证：门禁到底读哪个件、用不用参数

### 1.1 判据件（现取，不许改动）

· `build/MilBridge/tools/pts-pages-guard.sh` **sha16=`b74d2be6f9093115`**／**572 行**（`t76` 终态件；本趟**只读**，未动）。
· 入口分派（**内容锚**＝文件末的 `case "${1:---selftest}" in`，逐字现取）：

```
case "${1:---selftest}" in
  --legs) shift; judge_legs "${1:?--legs 需要目录}"; exit $? ;;
  --g10-name) shift; g10_name_check "${1:?--g10-name 需要目录}"; exit "$G10_RC" ;;
  --selftest) selftest; exit $? ;;
  *) echo "用法: $0 --legs <dir> | --g10-name <dir> | --selftest" >&2; exit 2 ;;
esac
```

⚠️ **纠一处派单措辞（如实）**：派单说「跑判据（**默认路径、无参数**）」——
**按现件读，`无参数` ≠ 判默认证据目录**：`${1:---selftest}` 的展开式使**无参数＝跑 `--selftest`**（合成用例两极化，不读任何证据目录）。
本件两条都跑了，读数分列如下（§5）：
· **真正决定判词的那条 = `--legs <默认证据目录>`**（门禁里跑的就是这一支）；
· 无参数 ⇒ `PTS_GUARD_SELFTEST=PASS pass=37 fail=0`、`rc=0`（判据件自证，与证据无关）。

### 1.2 门禁步（`verify-all.sh` 现取；本件**不改**它）

```
:675  PTS_EVIDENCE_DIR="${PTS_EVIDENCE_DIR:-build/MilBridge/tests/PtsPagesProbe/evidence}"
:1180 run_step "PTS-PAGES" bash build/MilBridge/tools/pts-pages-guard.sh --legs "$PTS_EVIDENCE_DIR"
```

⇒ **门禁用的就是 `--legs` 一支，且带参数（不是空参数）**；默认证据目录 ＝
**`build/MilBridge/tests/PtsPagesProbe/evidence`**（本次换代的落点 ✓）。
本件自证：`verify-all.sh` **本趟未动**（未在我的写域内，也没碰过）。

### 1.3 「仓外那批腿」与「在册件」是不是同一趟

现取三处 `leg_23.env`／`leg_24.env`（`sha256sum | cut -c1-16`）：

| 位置 | `leg_23.env` | `leg_24.env` | `device.txt` | 现取时刻 |
|---|---|---|---|---|
| **在册（换代前）** `evidence/` | `9fb8af8d6fdebb45` | `afb1081916bd0d0d` | `6d2cf7572e7323b7`（`:237`） | 件 mtime `09:32`（`app_g1.log` 却是 `20:48`） |
| **在册（换代后）** `evidence/` | `99fcf0901de5f719` | `ccd9bdedc4756f6e` | `6d2cf7572e7323b7`（`:237`） | `23:04` |
| 仓外 `~/p1-ptsname/legs-after/` | `99fcf0901de5f719` | `e7caea27f5812585` | `6d2cf7572e7323b7`（`:237`） | `22:49` |
| 仓外 `~/p1-ptsname/legs-after2/` | `99fcf0901de5f719` | `e7caea27f5812585` | `6d2cf7572e7323b7`（`:237`） | `22:52` |

判定（逐条，全部现取）：
1. **换代前在册组与本次重跑组不是同一趟**：`session.txt`（`9488744993d13812` vs `c843734b5b934b64`）、`app_g1.log`（`cb0a3e5510b07790` vs `3729b8b5aa6b3f8d`）、`leg_23.env`（`9fb8af8d…` vs `99fcf090…`）三件全不同；且换代前组**内部就不同趟**：`device.txt`／`session.txt`／`leg_*.env` 的 mtime 是 `09:32`，而 `app_g1.log` 是 `20:48`（`app_g1.log` 比配套件晚 11 小时余 ⇒ 那组是拼起来的）。
2. **仓外那批腿与本次重跑组不是同一趟**（`app_g1.log` 不同：`4db15b4c8466fadd`／`3215a0517cb776fc` vs `3729b8b5aa6b3f8d`），**但读数可复现到字节**：`leg_23.env` 三方**逐字节相同**（`99fcf0901de5f719`）；`leg_24.env` **逐格现取对拍**只差**读数格**：仓外 `legs-after`／`legs-after2`（`e7caea27f5812585`）＝ `colors=852 ae=221857` ／ 本次（`ccd9bdedc4756f6e`）＝ `colors=851 ae=221246`；`magenta=55051`／`ink=423346`／`ns`／`app_rc=143`／`managed_unavail=1`／`native_gap=0`／五件代次**逐字相同** ⇒ 同为 A 臂同代件下的**同形读数**（差异＝重拍摄噪声，幅度 <0.3 %）。
3. ⇒ **换代做法（选了「重跑」而不是「搬运」）**：派单②的优先项就是重跑；本件**重跑**并**没有搬运仓外任何件**（仓外件只用于本节的同趟/同形判定，未进仓）。理由：搬运只能搬内容、搬不来「**同一趟**」——而无论搬谁，都得把两侧统一到**同趟口径**；唯一能造出「同趟」的只有**重跑**。

### 1.4 「同趟口径」是怎么统一到位的（自证）

换代后的整组**由同一条 `run-pts-pages-legs.sh` 调用一次性产出**，链条自证逐条现取：
· 装置入口 `run-pts-pages-legs.sh` sha16=`863ef62f1761005a`／208 行，`session_inner.sh` sha16=`53a01752fb09da22`，`legs-to-env.py` sha16=`c914e672eb111e1c`（**三件本趟只读未改**）。
· 跑前前置：`SYNC-APPLOCAL=PASS … drift=0`（§2.1 逐字）＋ 硬闸 `AUTHORITY: shim=2a5165700a8c8579 pf=8ef62d37e7c2ce2e ｜ APPDIR: shim=2a5165700a8c8579 pf=8ef62d37e7c2ce2e`（两对**逐字相等** ⇒ 测的是**现权威五件**，不是陈旧件）。
· 跑后硬闸：`POSTSHIM: shim=2a5165700a8c8579 pf=8ef62d37e7c2ce2e（== authority ⇒ 读数可归因）` ⇒ **`shim`／`pf` 都 == authority** ✓（派单②要求的那条可复算归因）。
· 同趟配套件在册且互相一致：`five_pre_g1.txt` 与 `five_post_g1.txt` **同 sha16（`bc0012e76e369f5c`）**；`session.txt` 里 `FIVE_STABLE_G1=YES`。
⇒ 「同趟」＝**一条腿命令一次产出**，不是拼接。

---

## 2. ②  换代（在册）

### 2.1 腿跑（重活槽、后台、PID／日志在册）

```
nohup bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- \
  env PTS_GUARD_REPO=/home/links-dev/netTest/GitProj/WPFOnLinux \
      PTS_GUARD_DISPLAY=:237 PTS_GUARD_APPDIR=/home/links-dev/w67-work/app \
      W67_WORK=/home/links-dev/w67-work \
  bash /home/links-dev/netTest/GitProj/WPFOnLinux/build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh \
      /home/links-dev/netTest/GitProj/WPFOnLinux/build/MilBridge/tests/PtsPagesProbe/evidence \
  > /home/links-dev/t78-runner/logs/legs-promote.log 2>&1 &
```
· **PID=1550829**，日志 `/home/links-dev/t78-runner/logs/legs-promote.log`（车道目录，**未落 `/tmp`**）；`PID` 另存 `~/t78-runner/bin/legs-promote.pid`。
· 槽读数（现取，逐字）：`HEAVYSLOT=ACQUIRED waited=0s`｜`HEAVYSLOT=MEMOK avail=7380MB min_avail=2500MB`｜`HEAVYSLOT=RELEASED rc=0 held=34s max_hold=1800s`（**held=34s ≪ 1800s**，无 `TIMEOUT`／`MAXHOLD_KILL`／`NOINFO low-memory`）。
· 前置自证：`APPSYNC: SYNC-APPLOCAL=PASS target=/home/links-dev/w67-work/app items=5 ok=5 synced=0 created=0 drift=0 noauth=0 same=0 rc=0`（**先 `--check` 得 `drift=0`，故未做 `sync`**）。
· 装置自证：`X_UP=yes display=:237`（私有 `:23x` ✓；该值**就是腿跑器自带的预置默认**：`run-pts-pages-legs.sh:28` `DISPLAY_NUM="${PTS_GUARD_DISPLAY:-:237}"`，我另显式给了同值 `PTS_GUARD_DISPLAY=:237` ⇒ 两处一致，不是"随手挑号"）｜`DISPLAY_LEASE=official-caller-owned … xvfb_pid=1552207 owner_pid=1550838`。
· 两条腿读数（现取）：`CLICK k=24 alive=yes … magenta=55051 colors=851 AE=221246`（`app_pid=1555062`、`timeout=200s`）／`CLICK k=23 alive=yes … magenta=50461 colors=844 AE=140247`；`APP_RC=143`（`rc_reading: SIGTERM(仪器收的)`）｜`alive_after_seq=yes`｜`ALL_GROUPS_DONE 23:04:39`（组起 `23:04:12`）。
· 具名行（**这就是换代的目标**）：`[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage entry=LoSetDoc err=-10000 action=page-placeholder（已画出页级占位；进程继续）`（两腿各一处，`grep -a` 现取）。
· 资源（跑前/跑后现取）：跑前 `MemAvailable=7433288 kB`／`SwapFree=1441788 kB`／`df -Pk` 余 `72663308 kB`（≈72.7 GB）；跑后 `7660720 kB`／`1441788 kB`／`72661016 kB` ⇒ **离停手线（2000 MB／512 MB／5 GB）远**。

### 2.2 显示器与进程收尾（只按 PID）

· 装置自收（`run-pts-pages-legs.sh` 内，按 `xvfb.pid`／`xfwm.pid`）：跑后现扫 `/proc/*/exe` 得 **0 个** `Xvfb`／`xfwm4` 残留。
· `display-lease.txt` 已被装置自撤：现取 `ls` ⇒ `没有那个文件或目录` ✓（不留可被复用的旧 lease）。
· 扫描纪律：`/proc` 扫显示占用时**排除自身整条祖先链**（现取自报 `selfchain=1544304 1070138`），全程**无 `pkill`／`killall`／`pgrep -f`**。

---

## 3. ③  旧在册件处理（`cp -p` 备份 + 写前/写后读数）

· 备份命令：`cp -p <7 件> ~/t78-runner/bak/evidence-pre/`（**仓外、我自己的车道目录**）；回读断言：`app_g1.log` 备份件 sha16 ＝ 现取 `cb0a3e5510b07790` **逐字相同** ⇒ 备份与在册件同内容。
· **未静默覆盖**：写前/写后读数如下（旧值另与 `git show HEAD:<路径>` 现取**双向核对一致**，故旧值是索引在册值、非我口述）。

| 在册件（判据默认目录内） | 写前 sha16 | 写后 sha16 | 写前/后行数 | 写前/后字节 | 说明 |
|---|---|---|---|---|---|
| `app_g1.log` | `cb0a3e5510b07790` | **`3729b8b5aa6b3f8d`** | `1137` → `1364` | `108365` → `125211` | **换代主件**：`entry=unknown`×2 → `entry=LoSetDoc`×2 |
| `session.txt` | `9488744993d13812` | `c843734b5b934b64` | `28` → `30` | `2256` → `2666` | 同趟日志（含 `DISPLAY_LEASE` 行） |
| `leg_23.env` | `9fb8af8d6fdebb45` | `99fcf0901de5f719` | `4` → `4` | `277` → `272` | 判据真正读的承重件 |
| `leg_24.env` | `afb1081916bd0d0d` | `ccd9bdedc4756f6e` | `4` → `4` | `278` → `273` | 同上 |
| `five_pre_g1.txt` | `1fbedf891db7bf66` | `bc0012e76e369f5c` | `5` → `5` | `178` → `178` | 五件代次表（旧代 `6825dd70…/876f70dd…` → 现权威 `2a516570…/8ef62d37…`） |
| `five_post_g1.txt` | `1fbedf891db7bf66` | `bc0012e76e369f5c` | `5` → `5` | `178` → `178` | 与 `five_pre` **同 sha16** ⇒ 跑腿期间五件未变 |
| `device.txt` | `6d2cf7572e7323b7` | **`6d2cf7572e7323b7`** | `1` → `1` | `22` → `22` | **逐字节相同**（都是 `X_UP=yes display=:237`） |

**同趟副产（跑腿器一次性产出，非我手工另写；如实登记）**：
| 件 | 写前 sha16 | 写后 sha16 |
|---|---|---|
| `arm_A/leg_23.env` | `ae26bbfa7976c776` | `99fcf0901de5f719` |
| `arm_A/leg_24.env` | `8d103daa32cf24d5` | `ccd9bdedc4756f6e` |
| `arm_A/device.txt` | `6d2cf7572e7323b7` | `6d2cf7572e7323b7` |
| `device/xfwm.log` | `8ef9e0450181ec31` | `8f6df378c5d79ac8` |
| `device/xvfb.log` | （见下） | `e3b0c44298fc1c14`（**0 B**，本趟装置无输出；`#70` 已登「空件合法」） |
| `shots/g1/boot.png` | `b21eb530afd3c66c` | `b21eb530afd3c66c`（**逐字节相同**） |
| `shots/g1/k23.png` | `6c4e46b5024bf942` | `edb39dbff97652b1` |
| `shots/g1/k24.png` | `30fa8476edb8d69a` | `dde2ba1b594df52a` |
| `shots/g1/last.png` | `6c4e46b5024bf942` | `edb39dbff97652b1` |

· ⚠️ **拼贴证据的旁注（判定用，非判据）**：新旧 `k23.png` **不同 sha16 但同为 102535 B**、`k24.png` 从 `85148` → 同量级；`boot.png` **完全同 sha16**；两腿 `magenta` 只差个位（`55051`／`50461` 与本趟仓外 `legs-after2` 逐字同值）⇒ 像素读数**可复现到个位**，差异属**同代同形的重拍摄噪声**，不是行为位移。
· ⚠️ **`arm_A/` 下另有未跟踪件**（`arm_A/app_g1.log`／`arm_A/session.txt`／`arm_A/five_*.txt`／`arm_A/arm_A/`／`arm_A/device/`／`arm_A/shots/`）—— 这是**跑腿器自身**的落盘行为（装置入口把同趟件镜像进 `$OUTDIR` 与 `$OUTDIR/arm_A`），本趟**未手工写它们、也未删除它们**（删/改装置＝越域）。其中 `arm_A/app_g1.log` mtime 仍是 `20:57`（**旧件，未被本趟覆盖**）。

---

## 4. ④  指纹与四条不变量（如实记位移）

### 4.1 `inputs_fp`（覆盖面「内容」指纹）

· **现取（`ts` 见下）**：`bash ~/w153a/bin/infp.sh fp` ⇒ **`4140b706b03ac78f55239206788d0460a9529018489d164837c6a39cbfa98662`**
· **我独立复算**（自己的工具 `~/t78-runner/bin/fp-inputs.sh`：**只取** `close-wave.sh` 的 `fp_inputs()` 本体（内容锚＝函数头行 → 紧随的首个列 0 `}`），在**复制来的** `$0` 上下文里执行 —— 因为该函数用 `$0` 找 `close-wave.sh` 自身）⇒ **逐位相同** `4140b706b03ac78f…`（工具原文见 §7，可复算）。
· **归因（单变量、可复算）**：把 `evidence/app_g1.log` **只在量指纹那一瞬**换回旧件（内容 `cb0a3e5510b07790`）⇒ fp ＝ `28662be3c7c034ad20f3bb572842c3190d59dfca57dc6ddfcd53befede614231`；换回新件（`cp -a` + `touch -r` 复原 mtime，现取 sha16／mtime／mode **逐位复原**，fp 亦回到 `4140b706…`）。
  ⇒ **本件的贡献方向：换内容 ⇒ fp 必动**（覆盖面**读内容**，符合覆盖面语义）；旧值 `0581db21fe4cf1a292e5b54195932bd346fe79ef138807eb4bc34c20869553b2`（队长转述的 `t76` 时刻值）→ 现值 `4140b706b03ac78f…` 之间**还夹着别的车道对覆盖面内件的改动**（`t76` 改 `pts-pages-guard.sh`、`t77` 复核期等）⇒ **本件不声称「整段位移都由我造成」**，只声称「我这一项确有位移、且方向如上行」。

### 4.2 四条不变量（全部现取）

| # | 不变量 | 现取命令 | 现值 |
|---|---|---|---|
| I1 | `^run_step "` 计数 | `grep -c '^run_step "' verify-all.sh` | **`62`** |
| I2 | `VERIFYALL-STEPS-DECL` 现声明 | `grep -m1 '^# VERIFYALL-STEPS-DECL:' verify-all.sh` | **`62 gen=#81`** |
| I3 | `FP-MANIFEST-TEETH --expect` | `grep -n 'run_step "FP-MANIFEST-TEETH"' verify-all.sh` | `:1201 … --expect 234` |
| I4 | 覆盖面**活清单件数** | `bash build/MilBridge/tools/fp-manifest-step.sh --expect 234` | `names_n=234 manifest_n=234 … would_be_fp=4140b706b03ac78f`；`FP_MANIFEST_TEETH=PASS reason=ok files_n=234 files_n_uniq=234 blank_n=0 declared_expect=234` |

· **I1＋I2 同值（62）** ⇒ 步数声明与步本体一致 ✓。
· **I3＋I4 同值（234）且共跑 `PASS`** ⇒ **换代**（只换内容）**没有改变覆盖面件数** ⇒ `--expect` **不需改**（本件也没改）。
· ⚠️ **如实报一处我自己的取证失误**：本次会话中途我曾以 `--expect 197` 跑同一牙并看到 `FAIL reason=files-n-mismatch files_n=234 expect=197 delta=37`；**那是我不该传的自造参数**（该牙按「显式 `--expect` 覆盖」取参），**不是**现场读数，也不代表 `verify-all.sh` 与活清单不一致。现取（各用其正确参数）：`verify-all.sh:1201` ＝ `234`、活清单 ＝ `234`、共跑 `PASS`。**此处按实更正，不掩盖**。

### 4.3 两枚哨兵（`cmp`）+ `wave-push.sh --dry-run`（只读）

· `cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **`IDENTICAL`**（两枚现取 sha16 皆 `b26b245f75a2ea70`、皆 `279 B`、`mtime` 皆 `2026-09-28 23:04`）。
· `bash build/MilBridge/tools/wave-push.sh --dry-run`（只读，13 行）自报：`SHA=4e25e4b27d4d5ae1`｜`FP=d697b1e10ff48881`｜`WIN32SHIM=2a5165700a8c8579`｜`PF=8ef62d37e7c2ce2e`｜`WAVE=w80-freeze`｜`BASELINE=#80`｜`WPW=DRYRUN lines=13 keys=13`。
· ⚠️ **如实登记一处我解释不了的位移（不在我写域内，交队长）**：**两枚哨兵的 `mtime` 都是 `23:04`**，即**落在本趟跑腿窗口内**（我的腿跑 `23:04:07`–`23:04:40`），**但本趟我没有跑过 `wave-push.sh`（只跑过一次 `--dry-run`，且 dry-run 明确不写盘）**；且哨兵内容自报 `WAVE=w80-freeze`／`BASELINE=#80`，而现 `HEAD` 已在 `#81`。⇒ 有**别的写者**在 `23:04` 附近写过哨兵，或外部把旧内容重贴回来。**我只如实报告，不重写哨兵**（按派单：要不要重写哨兵由队长决定）。
· 哨兵与我的换代**无逻辑耦合**：哨兵内容里**没有** `app_g1.log`／`leg_*.env`（13 键＝八位＋`WAVE`／`BASELINE`／`BASELINE_SHA16`），且 `samples/…/ACCEPTANCE-BASELINE.md` 的 `BASELINE-FROZEN` 行现取仍是 `#80`／`b27ff6332f263495` ⇒ **换代不动九位、不动基线**。

---

## 5. ⑤  判词（换代前 / 换代后，成对）

### 5.1 换代前（**低一级证据**：旧 `app_g1.log` 复制进仓外只读夹具 `~/t78-runner/fixture-pre/`，配套用该目录的原件）

```
$ bash build/MilBridge/tools/pts-pages-guard.sh --legs ~/t78-runner/fixture-pre
PTS_G10_NAME=PASS form=unnamed reason=frontier-unnamed（应用侧无具名 entry= ＝**算出来的形态**、不是「算不出」⇒ 本判据按形态通过；名字归因由 pts-gap-count-check.sh 的具名前沿判据承担）
PTS_GUARD=FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0) cannot=- diag=- direction=in-file phase=degraded
rc=1
```
⚠️ 口径声明：该夹具的 `leg_*.env` **当晚被本趟重跑覆盖过**（我用同一路径 `fixture-pre` 做了后备目录）⇒ **该行只作「换代前形态」的旁证**，**不充当承重读数**。承重的「换代前」值是**在册旧件本身**：`app_g1.log`＝`cb0a3e5510b07790`，其 `entry=` 现取 `entry=unknown ×2`（`grep -o 'entry=[A-Za-z0-9_]*' | sort | uniq -c`）。

### 5.2 换代后（**门禁真读的那条**：默认证据目录、带参数）

```
$ bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence
PTS_G10_NAME=PASS observed=LoSetDoc names=1 roster=10 domains=dllimport-entry decl=/home/links-dev/netTest/GitProj/WPFOnLinux/upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs:1470（**域前提修正**：非 PTS 域判定为**该入口名在声明树里对拍上**（内容锚「DllImport … EntryPoint=<名>」，声明位见 decl 字段）⇒ 该格绿并将名字与声明位如实点名；**不**拿 PTS 在册表判它）
PTS_GUARD=FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0) cannot=- diag=- direction=in-file phase=degraded
rc=1
```

### 5.3 「无参数」那条（判据件自证，**不读任何证据目录**）

```
$ bash build/MilBridge/tools/pts-pages-guard.sh
… （37 条合成用例逐行 ok）
PTS_GUARD_SELFTEST=PASS pass=37 fail=0
rc=0
```

### 5.4 判词位移（逐字对照）

| 判据格 | 换代前 | 换代后 |
|---|---|---|
| `PTS_G10_NAME` | `PASS form=unnamed reason=frontier-unnamed` | **`PASS observed=LoSetDoc names=1 roster=10 domains=dllimport-entry decl=…LineServices.cs:1470`** |
| `PTS_GUARD` | `FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0)` | **`FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0)`（原样保留）** |
| `rc` | `1` | `1` |

⇒ **① 目标达成**：门禁真读的件已体现具名前沿（`observed=LoSetDoc`），且名字按 `t76` 的域前提修正被归到**非 PTS 域＋声明位点名**。
⇒ **② 唯一红原样保留**：`native-ledger-absent(PTS_GAP n=0)` —— 两腿 `leg_*.env` 现取 `native_gap=0`（**既在状态**，非本趟造成；本趟 `app_g1.log` 里 `grep -ao 'PTS_GAP [^"]*'` ＝ **0 命中**）。按队长裁定：**不折叠、不改相位、不放宽阈值**，只能由 W8 的 LS 族增量消解。**本件不为绿改判据、不改证据语义**。

---

## 6. 未做项与原因（如实）

1. **未跑整趟门禁**（纪律禁）⇒ 第 `[38]` 步 `PTS-PAGES` 的**步级**读数未取；本件取的是**同一条命令**（`--legs "$PTS_EVIDENCE_DIR"`，`$PTS_EVIDENCE_DIR` 现取默认值）在现树上的读数，两者同口径、同参数、同写域。
2. **未重写哨兵**（派单明示由队长决定）⇒ 只报 §4.3 的 `cmp=IDENTICAL` 与 mtime 疑点。
3. **未改** `--expect`／`verify-all.sh`／`close-wave.sh`／`pts-pages-guard.sh`／`src/**`／`build/PresentationFramework.Linux/**`／`HANDOFF-NEXT.md` 的**机器值格**（只在 EOF `>>` 追加一行 dated 更正，见 §7）。
4. **未消解** `PTS_GAP n=0` 那条真红（属 W8 范畴，越域即停手）。
5. **未清理** `arm_A/` 下的装置副产（属装置行为，删改＝越域）。
6. **未动** `~/p1-ptsname/**`（仓外、他车道）—— 只读。

---

## 7. 边界遵守自证

· 写域内**我手工写**的件：**仅** `build/MilBridge/tests/PtsPagesProbe/evidence/**`（换代，由装置入口产出）＋ 本件 `build/MilBridge/P1-evidence-promote-report.md` ＋ `build/MilBridge/HANDOFF-NEXT.md` **EOF 追加一行**（队长纪律 28 追加要求）。其余在册位移均为**跑腿器自身**产出（§3 副产表）。
· **纪律 28 追加**（队长本趟追加要求，同趟完成）：`HANDOFF-NEXT.md` 于 EOF 追写：

```
⏪ **机器值契约更正 · cell=#1**：以现取为准；`ts=2026-09-28T23:06:35.704011761+0800` 时 现值 ＝ `4140b706b03ac78f55239206788d0460a9529018489d164837c6a39cbfa98662`（命令：`bash ~/w153a/bin/infp.sh fp`）（**`t78` 有意换代覆盖面内证据组 …⇒ 本格随之刷新；**覆盖面件数仍 `234`**（只换内容、不加件）⇒ `--expect 234` 不需改；**维护契约见第 `28` 条**。）
```
  · 写法：`cp -p` 备份旧件到 `~/t78-runner/bak/HANDOFF-NEXT.md.pre-t78` 后**纯 `>>` 追加**；写前 sha16=`4742927b8f9526e7`／`592` 行／mode `644`，写后 sha16=`ebe6916b33cd318d`／`593` 行／mode `644`（显式 `chmod 644`），`git diff --numstat` ＝ **`2 0`**（**只增、零删**；`1 0` 是本趟前的在飞改动）。
  · 值取自**全部落盘完成后的最后一次现取**（先写完证据件、再取值）；工具与我的独立复算**逐位相同**。
  · 判据回绿：`bash build/MilBridge/tools/handoff-machine-values-check.sh` ⇒ **`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`**（`rc=0`）。
· 腿跑纪律：显示位 **`:237`**（`:23x` ✓）｜进程**只按 PID** 收（装置自收 `xvfb.pid`／`xfwm.pid`；全程无 `pkill`／`killall`／`pgrep -f`）｜重活**全走 `heavy-slot.sh` 后台**（PID 与日志在册）｜**未跑整趟门禁**。
· **无 `git add`／`commit`／`push`**（全程零）。
· 台账/中间件落**自己的车道目录** `~/t78-runner/`（`bin/`、`bak/`、`logs/`、`fixture-pre/`），**未落 `/tmp`**；仓根未留临时件（`ls batch.pid` ⇒ 无）。
· 件位 sha16：**跑前跑后各算一次**（§3／§4 表内逐件给出）。

---

## 8. 落盘后 HEAD 位移（如实登记，不影响本件结论）

· 本件全部落盘时 `HEAD=ab1ac00`（`docs(#81): t75 LS 族缺口面侦察入账`）；收尾复核时 `HEAD` 已变为 **`a8b8acd`**（`docs(#81): t80 W8 第一步预登记判据入账`）—— **不是我提交的**（本趟零 `git add`／`commit`／`push`）。
· 该位移**只加了一件** `build/MilBridge/P1-w8-step1-criteria.md`（`git show --stat HEAD` 现取：`1 file changed, 306 insertions(+)`）⇒ **不在覆盖面内**、不在我的写域内。
· 位移后复核（全部现取，与 §4／§5 同值）：
  · `inputs_fp` 仍 ＝ `4140b706b03ac78f55239206788d0460a9529018489d164837c6a39cbfa98662`（**未再位移**）；
  · `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 reasons=none`（**仍绿**）；
  · 换代主件 `evidence/app_g1.log` 仍 ＝ `3729b8b5aa6b3f8d`／1364 行／`entry=LoSetDoc`×2；
  · 判据 `--legs <默认目录>` 判词行**逐字未变**（`PTS_G10_NAME=PASS observed=LoSetDoc …` ＋ `PTS_GUARD=FAIL … fails=native-ledger-absent(PTS_GAP n=0)`，`rc=1`）。

## 9. 可复算自报口径

· `inputs_fp` 现取（`bash ~/w153a/bin/infp.sh fp`）＝
  `4140b706b03ac78f55239206788d0460a9529018489d164837c6a39cbfa98662`
· 我的独立复算工具（逐字节入件、可原样重跑）＝ `~/t78-runner/bin/fp-inputs.sh`，现取输出与上**逐位相同**。
· 换代主件 `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log`：`cb0a3e5510b07790`（1137 行／108365 B）→ **`3729b8b5aa6b3f8d`**（1364 行／125211 B）。
· 判据件 `build/MilBridge/tools/pts-pages-guard.sh` ＝ `b74d2be6f9093115`／572 行（**只读，本趟未动**）。
· 腿跑器 `run-pts-pages-legs.sh` ＝ `863ef62f1761005a`／208 行（**只读，本趟未动**）。
· 槽：`HEAVYSLOT=ACQUIRED waited=0s` → `RELEASED rc=0 held=34s max_hold=1800s`；`avail=7380MB min_avail=2500MB`。
本件编排口径（自报可复算）：**正文**（`head -n -1`，261 行）sha16 ＝ `d60ef8beba622462`；**`inputs_fp` 现值** ＝ `4140b706b03ac78f55239206788d0460a9529018489d164837c6a39cbfa98662`（二者与现树各按本节命令现算可逐位对拍）。⚠️ **全文 sha16 是自指量、不可自报**（把全文值写进本行 ⇒ 写下它的动作就改掉了全文 ⇒ 自报值必然与现算不符，本趟实测：自报值按位替换后现算恒不匹配）⇒ 本件**只报正文值与 `inputs_fp`**，全文值由读者现算（`sha256sum` 本件）。模式 `644`。

---

## ⏪ **`t85` dated 关账（`t79` 的 `F1`／`F2`／`F3` ＋ `O1`／`O2`／`O3`）**（读时 `ts=2026-09-28T23:2x+08:00`；**本节为追加，上文一字未改**；本件上方那条自报口径行**原样保留**，本节末另给**新**的自报口径值）

### `F1`（low）备份面 ≠ 换代面 —— 处置：**确诊 ＋ 逐件现取旧像 ＋ 纪律入册**（**未补备份**，理由见下）
- **改动面现取**（`git show --numstat --format='%H %ci %s' b47cf09`）：该笔共 **16** 条 `numstat` 行 ＝ `evidence/` 下 **12** 件 ＋ 四份报告／载体件（`P1-evidence-promote-report.md` `262 0`／`P1-g10-domain-report.md` `91 0`／`P1-g10-domain-verify.md` `100 0`／`P1-ptsname-result.md` `21 1`）。**备份面现取**（`~/t78-runner/bak/evidence-pre/`）：**7** 件 ＝ `app_g1.log`／`device.txt`／`five_post_g1.txt`／`five_pre_g1.txt`／`leg_23.env`／`leg_24.env`／`session.txt`。
  ⇒ **未备份且被改动的 6 件**：`arm_A/leg_23.env`／`arm_A/leg_24.env`／`device/xfwm.log`／`shots/g1/k23.png`／`shots/g1/k24.png`／`shots/g1/last.png`。（`device.txt` 属「**备份了但未变**」⇒ **不计入缺口**；这是 `N=12` 与 `M=7` 之外还要看**集合**的理由。）
- **六件逐件旧像／新像现取**（`git cat-file -e` 逐件 **`rc=0`**；`git show <rev>:<path> | sha256sum | cut -c1-16` ＋ `| wc -c`）：
  | 件（相对 `evidence/`） | 旧像 `b47cf09^` | 新像 `b47cf09` |
  |---|---|---|
  | `arm_A/leg_23.env` | `ae26bbfa7976c776`（272 B） | `99fcf0901de5f719`（272 B） |
  | `arm_A/leg_24.env` | `8d103daa32cf24d5`（273 B） | `ccd9bdedc4756f6e`（273 B） |
  | `device/xfwm.log` | `8ef9e0450181ec31`（170 B） | `8f6df378c5d79ac8`（170 B） |
  | `shots/g1/k23.png` | `6c4e46b5024bf942`（103687 B） | `edb39dbff97652b1`（102535 B） |
  | `shots/g1/k24.png` | `30fa8476edb8d69a`（86266 B） | `dde2ba1b594df52a`（85148 B） |
  | `shots/g1/last.png` | `6c4e46b5024bf942`（103687 B） | `edb39dbff97652b1`（102535 B） |
  （`k23.png` 与 `last.png` **同哈希** ⇒ `last` 是 `k23` 的副本，如实记。）
- **处置①：纪律入册** —— `build/MilBridge/HANDOFF-NEXT.md` **第 `29` 条**（口径句逐字：「凡改一批件…**备份面 ≡ 换代面**…先现取改动面清单、再按同一清单逐件 `cp -p`…`N ≠ M` 即如实报红」），含**不自指**的条在位自检命令（现取 `n=1`）。
- **处置②：本件不补备份（如实记理由）** —— 六件**已提交**、旧像可从 `b47cf09^` **逐件取回**（上表），补备份**不增加可回退性**，却要去改**仓外**目录（本单只许**只读** `~/t78-runner/**`）⇒ 不补是**有据的**，不是遗漏。

### `F2`（low）`before` 是**声明常量**（不是现取）—— 处置：**在册写明 ＋ 给代价，不实现**（**不许**写成「已解决」）
- **定义位现取**（`build/MilBridge/tools/pts-gap-count-check.sh`；行号**仅本次有效**）：
  - `:305  FR_BEFORE_NAME="${PTSGAP_FR_BEFORE_NAME:-LoCreateContext}"     # 本增量**之前**的具名前沿（声明值）`
  - `:306  FR_BEFORE_N="${PTSGAP_FR_BEFORE_N:-3}"                         # 其台账行计数（声明值）`
  - 使用位 `:313` 的 `echo "PTSGAP_FRONTIER before=${FR_BEFORE_NAME}@${FR_BEFORE_N} after=…"`；另 `:321`／`:322` 用**同名常量**判 `FAKE-PROGRESS`。
- **在册口径（逐字）**：**`PTSGAP_FRONTIER` 的 `before=` 侧 ＝ 「**上一增量**的**声明值**」（判据件内的常量，可用 `PTSGAP_FR_BEFORE_NAME`／`PTSGAP_FR_BEFORE_N` 覆盖），**不是现取** ⇒ `before/after` 这一对**跨趟 by construction**；它只能证「`after` 可具名（且与声明的前沿不同）」，**不能**证「同趟位移」。**要真现取** ⇒ 需**另立判据**：把「上一趟载体」纳入读数面（一条**跨趟账本**，或以上一趟落盘物的**哈希锚**＋「上一趟如何唯一确定」的规定）；**本件不实现**（代价：多一个账本面 ⇒ 又多一处会漂的来源，且当前无判据需求）。
- **`t79` 的判词保持不变**：该条**部分成立** —— 本条只把「**为什么部分**」写清，**不改判词**。

### `F3`（low）时点值缺 `ts` —— 处置：**按第 `24` 条分层写清 ＋ dated 更正入册**
- **被更正的两行现取**（**本件上文**，原文保留）：`:22` 与 `:259` 均写「`build/MilBridge/tools/pts-pages-guard.sh` **sha16=`b74d2be6f9093115`**／**572 行**（`t76` 终态件；本趟**只读**，未动）」。**时点值**：那是 `t78`（读时 `ts≈2026-09-28T23:04:40`）看到的**在飞件**读数，**当时成立**（**不是**错）。
- **分层现取（`t85`）**：
  | 层 | 判据件版本 | 现取来源 |
  |---|---|---|
  | **提交级**（`HEAD` ＝ `b47cf09`） | **`59bffc8e5b5a621a`／483 行** | `git show HEAD:build/MilBridge/tools/pts-pages-guard.sh \| sha256sum`／`\| wc -l`；最后改它的笔 ＝ `7bccbf4`（`2026-09-28 21:55:40`）；`a8b8acd`／`b47cf09` 对该件 **0 行** |
  | `t76` **在飞件**（`t78` 引的那版） | `b74d2be6f9093115`／572 行 | **从未提交**（工作树中间态） |
  | **现盘** | **`944e61f39f24631c`／660 行** | `sha256sum`／`wc -l`（`t82` 终态，**未提交**） |
- ⇒ **在册写法**：**判据件读数一律带 `ts=` ＋ 「提交级／在飞件」标注**；只写 sha16 会被下一个写者立刻作废（第 `24` 条）。

### `O1`（观察）判据被第三方改过 —— 处置：**归因写明**
- **时序（现取）**：`t79` 只读时（`ts≈23:11:46`）工作树已是 `t82` 的**第一趟** —— `9b46dc9b3fbfda32`／**643** 行、`mtime 23:08:51`、`--selftest` 例数 **37 → 40**；**同一时刻提交级仍是 `59bffc8e5b5a621a`／483**（上表）。
- **结论（后人可直接用）**：**证据换代笔 `b47cf09` 与判据件无关**（`git show --numstat` 空）⇒ 换代**不改变判据**；判据的两次移动（`t76` → `b74d2be6f9093115`、`t82` → `9b46dc9b3fbfda32` → `944e61f39f24631c`）都发生在**工作树**、且**都未提交**。`t79` 的「`pass=40 ≠ 37`」归因 `t82`（判据面收紧：非 PTS 域归因锚，载体 `build/MilBridge/P1-g10-anchor-tighten-report.md`），**不是** `t78` 的越域。

### `O2`（观察）归因证据只在仓外 —— 处置：**两行原样落仓**（落点＝**本节**；**不改仓外件、不落证据目录**）
- **落点选择与理由**：落在**本件**（报告），**不**在 `build/MilBridge/tests/PtsPagesProbe/evidence/` 下新建件 —— 因为该目录**在覆盖面内**（`close-wave.sh` 的 `fp_inputs()`）⇒ 新建件会**移动 `inputs_fp`** 并改变「在册证据集」的语义（那套件是**装置跑腿的产出**，不是**仓外日志的转录**）；本件是引它们的载体 ⇒ 版本化在一起更省事，且**零指纹位移**。
- **仓外源（只读，未改）**：`~/t78-runner/logs/legs-promote.log`：`sha16=f5b6811d26faefa0`／**44** 行／`mtime 2026-09-28 23:04:40.733`。
- **两行原样（`sed -n`／`grep -n` 现取）**：
```
4:AUTHORITY: shim=2a5165700a8c8579 pf=8ef62d37e7c2ce2e ｜ APPDIR: shim=2a5165700a8c8579 pf=8ef62d37e7c2ce2e
43:POSTSHIM: shim=2a5165700a8c8579 pf=8ef62d37e7c2ce2e（== authority ⇒ 读数可归因）
```
- ⚠️ **时点标注（第 `24` 条；本席现取）**：这两行是 **`ts≈23:04:40` 的时点值**；**现盘 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ `3bd193e54785b5db`**（≠ 日志里的 `2a5165700a8c8579`），且在册证据 `five_pre_g1.txt`／`five_post_g1.txt`／`leg_23.env` **仍载** `shim=2a5165700a8c8579`（本席现取）⇒ 该换代的「权威面」**只在那一刻成立**；**要把「证据 ↔ 现盘」重新接上，需在新一趟重取腿**（属下一波，不在本单）。

### `O3`（观察）指纹侧未留痕 —— 处置：**成对读数入册（现已闭合，不报红）**
- `t79` 现取的 `inputs_fp=b8f10edccaf381dab7ab8583c73a1510…` 是**时点值**（那一趟的读数），仓内 0 命中属实。
- **现取对拍（`t85`）**：`bash ~/w153a/bin/infp.sh fp` ⇒ **`ec63b28dc68e6468f6c78dda573af9dc5567fc39d67a785379d2941d4a78d3b1`**；`build/MilBridge/HANDOFF-NEXT.md` **最后一条** `cell=#1` 行（`ts=2026-09-28T23:16:43.998+0800`）现值 ＝ **同值**；`bash build/MilBridge/tools/handoff-machine-values-check.sh` ⇒ **`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`**（`rc=0`），明细行现取 `cell=#1 … state=equal corrected=ec63b28d… live=ec63b28d…`。⇒ **一致**；`t82` 收尾的三次 `cell=#1` 追写（`23:11:47`／`23:13:21`／`23:16:43`）已把该格接上现盘。**未替他人改写任何格。**

### 本件自身遵守（第 `29` 条，本条刚入册）＋ 边界自证
- **改动面 ＝ 3 件 ＝ 备份面 3 件**：`build/MilBridge/P1-evidence-promote-report.md`／`docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md`，逐件写前 `cp -p` 到 `~/w281-scribe/bak/*.pre-t85`（逐件 `cmp` 通过）；**覆盖面零位移**（三件均**不在** `fp_inputs()` 名单内 ⇒ 按本单硬条款**未**追写 `cell=#1`）。
- **未改**：`pts-pages-guard.sh`（本件无需改它 ⇒ 未改）／`verify-all.sh`／`build/close-wave.sh`／`src/**`／`build/PresentationFramework.Linux/**`／两枚哨兵／`evidence/**`（只读）／`~/t78-runner/**`（只读）。未跑整趟门禁、未构建、未跑腿、未占显示位、未 `git add/commit/push`。
**本件编排口径（自报可复算；`t85` 关账后）**：`head -n -1 build/MilBridge/P1-evidence-promote-report.md | sha256sum | cut -c1-16` ＝ `477c21fad3c45f55`（含上文与 `t85` 关结节；**上一版**（`t85` 之前）＝ `d60ef8beba622462`，那一行**原样保留在上方**）
