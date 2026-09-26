# `WAVE78` 预登记片段 —— `TASK-0739` 残留③「显示号租借」（由主控并进正式预登记）

> 本件是**片段**：由车道 `W183A` 交付、**由主控并进** `docs/WAVE78-PREREGISTRATION.md`。
> 车道**不**改 `docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`defect-registry-declared.tsv`。
> 判据本体（先写）＝ `build/MilBridge/tools/` 同目录 **不**放；判据落 `criteria.md`（随包交付，见 §5）。

## H1（本波假设）
**"显示号租借"可以把『约定俗成挑号』变成『要号』**：申请者能**证明**自己拿到的是"此前无人持有且此后由我持有"的号；
拿不到就**显式失败**（`rc=1` ＋ 点名），**绝不静默换号**；源读不到时 `NOINFO`（`rc=3`，**不算绿**）。

**判否条件（先写死）**：
1. 号池里出现**同一个号被两趟同时持有到 `ACQUIRED`** ⇒ 判据破产；
2. 装置在"号被外部进程占"时**仍**打 `ACQUIRED` ⇒ 破产；
3. 装置把**畸形租约**当"无租约"从而抢占 ⇒ 破产；
4. `NOINFO` 被印成 `ACQUIRED`／`rc=0` ⇒ 破产；
5. 反极性四条（`polarity.md`）里任一条**破坏后仍全绿** ⇒ 该腿不是判据 ⇒ 该腿判据降级。

## H2（要落的两件 ＋ 一件由主控并）
| # | 件 | 作用 |
|---|---|---|
| ① | `build/MilBridge/tools/display-lease.sh` | 装置：`acquire`／`release`／`renew`／`verify`／`reap`／`list` |
| ② | `build/MilBridge/tools/display-lease-gate.sh` | 牙：静态面（装置自测 19 例）＋ 动态面（11 腿，真并发/真 Xvfb/真 sleep） |
| ③ | `docs/WAVE78-PREREGISTRATION.md` | **本片段并进去**（主控动作） |

## H3（判据三态 ＋ 机读行形状）
- `rc=0` `DISPLAY_LEASE=ACQUIRED display=:N prior_absent=1 exclusive_now=1 holder_pid=… lstart='…' lane=… job=… claim_epoch=… socket_absent=0|1 lease=…`
- `rc=1` `DISPLAY_LEASE=FAIL reason=<held-by-live-pid|occupied-without-lease|stale-lease-needs-reap|lease-malformed|pool-exhausted|not-my-lease|lstart-mismatch-live-pid|holder-pid-not-alive> …`
- `rc=3` `DISPLAY_LEASE=NOINFO reason=<proc-unreadable-or-ps-empty|sock-dir-absent|lease-dir-unwritable|lstart-unavailable|pool-out-of-whitelist> …`
- `rc=4` 用法错 **或逃逸闸拒跑**（`escape-gate-literal`／`escape-gate-resolved`）
- 牙：`DISPLAY_LEASE_GATE=PASS|FAIL static=p/n dynamic=p/n examined=N dev_sha16=…`

## H4（两极化：**先写、真跑**）
- 正极：牙 `--both` 全绿（静态 3/3 ＋ 动态 11/11）。
- 反极 4 条（`run-polarity.sh`，每条**先断言命中数 `hits==1`**、跑完**逐字节复原**并核 sha16）：
  R1 非原子占位／R2 畸形租约当空／R3 对外部占用失明／R4 `NOINFO` 静默当绿 ⇒ 每条**必须**有腿翻红。
- **假绿探测**：`examined=0` 判红；每条起真进程的腿打 `FIXTURE_PROOF pid=… live=1`；牙打被测装置 `LEASE_DEV_SHA16=`。

## H5（`fp_inputs` 覆盖面与落地次序）
- 两件落 `build/MilBridge/tools/**`：**是否进 `fp_inputs()`** 由主控按成文惯例「读 ⇒ 进 `fp_inputs()`」裁定；
  ⚠️ **若纳入** ⇒ `build/close-wave.sh` 的 `fp_inputs()` 白名单 **+2**、`[FP-MANIFEST-TEETH]` 的 `--expect` **同趟改**，
  且**必须排在** `close-wave.sh` 的 `IN_FP_0` 采样**之前**（否则本代指纹采的是半棵树）。
- 本波**不改**产品件、**不改** `verify-all.sh`（`DISPLAY_NUM=99` 的既成硬编码留待另波）。
- 预登记四要件：本片段随正式预登记走；本波**不做回归判定**（无 `p` 值/无 `N`）⇒ 四要件的 `NA` 由预登记总件给出，
  **不由本片段**（避免"提及即 `NA`"，`D-G134`）。

## H6（射程与边界，**不许夸大**）
- **管**：本波之后新写的"要独占显示位"的仓内件（用 `acquire` 取号）。
- **不管**：`verify-all.sh:225 DISPLAY_NUM=99`（及 `_n` 递增自起）、`frame-presence-check.sh:131` 的 `WPTD_DISPLAY:-:97`、
  `run-silenthit-legs.sh` 的 `DISP_RE=':23[0-9]'`（已是池内约定但**无租约**）——**替换既有调用方**由主控排波。
- 装置**不拦**绕过它直接 `Xvfb :231` 的进程；它只能**发现并响亮报出**（`occupied-without-lease`）。**这不是漏洞，是没有强制层的如实声明。**
