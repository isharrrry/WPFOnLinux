# P1-W79 · ① 装置台账**逐趟**印装置件自身 `sha16`／mtime ② `evidence/arm_A/**` 四件**来源登记**

两节都在本件写域内。**判据件未动**（`pts-pages-guard.sh` 现取 `962fec114b2d0692` ＝ `t157` 交件值）、
**相位位未翻**（`PTS-DIRECTION … phase=degraded`）、**未** `git add/commit/push`、`cell=#1` **有意未登记**。

---

## 1. ① 装置台账：逐趟印"工具换代"（裁定四十三 (c) 采纳 `t156` 建议）

### 1.1 落了什么（**只增不改**）

| 件 | 新增行（机读） | 位置 |
|---|---|---|
| `run-pts-pages-legs.sh` | `LEGS_TOOLS runner_sha16=<…> session_sha16=<…> guard_sha16=<…> mtime_max=<ISO+08:00> mtime_max_epoch=<epoch>` | 紧接 `AUTHORITY:` 行**之后**、**前置之前** |
| `session_inner.sh` | `SESSION_TOOLS session_sha16=<…> session_mtime_epoch=<…> runner_sha16=<…>` | 参数检查**之后**、方向/lease 前置**之前** |

**口径（写死）**：`sha16` 取**当趟实际被执行的那份**文件 —— runner 取**自身路径**（`$SELF_DIR/$(basename "${BASH_SOURCE[0]}")`）、
session 取 `$SESS`（＝本趟要执行的那份；经 `PTS_INNER` 注入桩时**就是桩** ⇒ 桩换代也会被抓）、
guard 取 `$REPO/build/MilBridge/tools/pts-pages-guard.sh`；`session` 端由 runner 经 `W67_RUNNER_SHA16` 下传（缺 ⇒ `none`，**不猜**）。
两行都放在**前置之前** ⇒ 连 `authority-missing`／`app-stale`／`display-not-free` 这类**拒跑**趟也带 ⇒ "**同一批内工具一致**"可机器核。

### 1.2 夹具（**仓外**）与"改前"的**逐字还原**

`~/w281-scribe/t159/fx1.sh`。**改前**副本 ＝ 把 `t159` 插入块**按已知行区间逐行删回**，并**校验 sha16**：

```
DROPPED runner lines 101-123 ; session lines 18-23
RECONSTRUCT=MATCH（删回＝逐字还原 t157 交件字节：runner e6eb370def6b4b8e / session 390927970cd8839f）
```

⇒ "改前"不是"另抄一份"，而是**删回后字节等于 `t157` 交件现取值**（现取期望值逐字硬编码在夹具里，不等就 `exit 3`）。
`kit/` 里放了**伴生脚本**（`legs-to-env.py`／`navclick.py`／`shotstat.py`／`session_inner.sh`）——
⚠️ **具名观察**：`TOENV="$SELF_DIR/legs-to-env.py"` 由**自身目录**派生、**没有 env 旋钮** ⇒ 仓外只复制 runner 会让转换器
**静默失败**（第一版夹具就踩到：`LEGS_TO_ENV_FAIL rc=2`、`obtained=0 refused=2 reasons=converter-rc=2,no-leg-env=1`；
**手工**在仓根跑同一份 `legs-to-env.py` 则该目录 `rc=0 wrote=2` ⇒ 病灶在"副本缺伴生脚本"，不在改动）。**本件不改它**（只在册）。

### 1.3 成对读数

| 极 | 夹具 | `LEGS_TOOLS` 原文（截取） |
|---|---|---|
| **(a) 正极：连续两趟** | `r1`／`r2`（同工具、各 `outdir` 不同） | `runner_sha16=330a90f1f0ac28e4 session_sha16=747cb75279632cc5 guard_sha16=962fec114b2d0692 mtime_max=2026-09-29T18:00:39+0800 mtime_max_epoch=1790676039` —— **两趟逐字节相同**；两趟皆 `LEGSCOUNT requested=2 obtained=2 refused=0` |
| **(b) 因果对 · 会话件换代** | `r3`（桩加一行注释 ⇒ 桩 `747cb75279632cc5` → `a05231024a0dd74d`） | `… session_sha16=a05231024a0dd74d …`（`runner_sha16`／`guard_sha16` **不变**）⇒ **抓住** |
| **(b′) 因果对 · runner 换代** | `r4`（runner 副本加一行注释 ⇒ `330a90f1f0ac28e4` → `ea6ed6c92d4dc145`） | `runner_sha16=ea6ed6c92d4dc145 …`（其余不变）⇒ **抓住** |
| **(a′) 会话端同形** | `s1`／`s2`（真 `session_inner.sh` 两趟，lease 不匹配 ⇒ 前置拒跑 `rc=3`） | `SESSION_TOOLS session_sha16=f1a582d9ea9788c9 session_mtime_epoch=1790675947 runner_sha16=330a90f1f0ac28e4` —— **两趟逐字节相同**；且该行是**第 1 行**、`DISPLAY_MISMATCH` 是**第 2 行**（`grep -an` 现取 `1:` ／ `2:`）⇒ 拒跑趟也带工具身份 |

### 1.4 (c) 既有列逐列计数（改前 `r0` vs 改后 `r1`，同一桩）

| 列 token | r0 | r1 | 判 |
|---|---|---|---|
| `CLICK k=`／`FAILLINE k=`／`FRAME k=`／`PHASE k=` | 2／2／2／2 | 2／2／2／2 | **相等** |
| `FILE=`／`APP_RC=`／`LEGS: ` | 3／1／1 | 3／1／1 | **相等** |
| `LEGSCOUNT `／`LEGS_RUNNER=`／`DISPLAY_PICK `／`DISPLAY_HANDOFF `／`AUTHORITY: ` | 1／1／1／1／1 | 1／1／1／1／1 | **相等** |
| `LEGS_TOOLS `（**本件新增**） | **0** | **1** | 不等（＝**只增的行**本身） |
| `SESSION_TOOLS ` | 0 | 0 | 相等（该趟用桩，桩没有这行；真会话面由 (a′) 覆盖） |

**腿账逐字节相同**（同一桩、同一输入 ⇒ 新行**没有扰动**转换器产物）：
`r0/arm_A/leg_23.env` ↔ `r1/arm_A/leg_23.env` `cmp` 相同（`sha16=3f8fb74a41d9285c`）；
`leg_24.env` `cmp` 相同（`b44b5e737d59624a`）。两趟 `LEGS_TO_ENV=OK wrote=2`。

**装置面**：跑前 `/tmp/.X11-unix` ＝ `X0 X1`、跑后 ＝ `X0 X1`；夹具只用 `:239`；收尾扫 `Xvfb :239`／`xfwm4` 残留 ＝ **0 行**。

---

## 2. ② `evidence/arm_A/**` 四件：**取（甲）登记**（不移动、不提交）

### 2.1 现取读数（本席逐件 `stat` ＋ `sha256sum`）

| 件 | mtime | size | sha16 | git |
|---|---|---|---|---|
| `evidence/arm_A/app_g1.log` | `2026-09-28 20:57:20` | 119515 B | `ed782d28a794cea5` | `??` 未跟踪 |
| `evidence/arm_A/device.txt` | `2026-09-29 14:12:12` | 22 B | `6d2cf7572e7323b7` | `??` 未跟踪 |
| `evidence/arm_A/leg_23.env` | `2026-09-29 14:12:12` | 422 B | `285913567aad8516` | `??` 未跟踪 |
| `evidence/arm_A/leg_24.env` | `2026-09-29 14:12:12` | 427 B | `f89dac2796faa25d` | `??` 未跟踪 |

四件**均早于 `t157`**（`t157` 交件在 `17:5x`–`18:0x`，且它的夹具全在仓外）⇒ **`t157` 不是作者**；对照同族**被跟踪**件
`evidence/arm_A/arm_A/{device.txt,leg_23.env,leg_24.env}`（`2026-09-28 20:57:23`、`22/272/273` B）可见"两代同形"。

### 2.2 来源判定（现取"同刻同形"，**不冒充归属**）

- ②③④ 与**同刻**（`14:12:12`）的 `evidence/{device.txt,session.txt,five_post_g1.txt}` 同批 ⇒ 判定＝一趟
  **`outdir=build/MilBridge/tests/PtsPagesProbe/evidence`** 的跑腿所产的**臂子目录**产物
  （转换器把每个臂写进 `<outdir>/arm_A/`；与 `t157` 自己的形制逐字相同：`~/w281-scribe/t155/leg4/arm_A/leg_24.env`）。
- ① 与 `build/MilBridge/P1-dg188-report.md` 那趟**同刻**（该件 `:33` 逐字
  `LEGS_TO_ENV=OK wrote=2 outdir=build/MilBridge/tests/PtsPagesProbe/evidence/arm_A`；`:30` 的 lease 落在 `evidence/arm_A/device/`）
  ⇒ 判定＝**那一趟（`outdir=evidence/arm_A`）**的产物。
- ⚠️ **具名 `NOINFO`**：**具体跑腿编号／写者**判不出（无 PID 血缘、件内无 `ts` 标注）⇒ 只登记"同刻同形"，不冒充归属。

### 2.3 门禁**是否**读这一面（逐字引用，逐条可复核）

**是（三件）**。`build/close-wave.sh` 的门禁输入表（`printf '%s\n' …` 参数表）里逐字列有：

```
          build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/device.txt \
          build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/leg_23.env \
          build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/leg_24.env \
```

（该件现取 `:348-350`；逐件出现次数现取 `1`）。**同表里没有** `…/arm_A/app_g1.log`（现取次数 `0`）。

⚠️ **与"`arm-logs`"不是同一面**：门禁另有具名判据
`ARMLOG_SHA=PASS shape=flat logdir=/home/links-dev/netTest/GitProj/WPFOnLinux/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0`
（`build/MilBridge/P1-refreeze-report.md:21` 逐字）⇒ 那是 `build/MilBridge/arm-logs/`（五臂配方目录），**不是** `evidence/arm_A/`。

### 2.4 处置：为何取（甲）登记、（乙）出仓为何**不可**

- **（乙）不可**：三件**在门禁输入表里** ⇒ 出仓 ＝ **直接改门禁输入面**（还会改覆盖面指纹）⇒ 比"留着噪声"更危险。
- **（甲）登记**（本件所做）：不动文件、不提交（**裁定六**照旧），把"谁/哪趟/为何不提交/是否门禁读面"写进 `docs/ROUTES.md` §15af 尾部（**只增不改**）。
- 🔴 **具名风险（待队长裁；不在本件写域）**：三件**未跟踪**却被门禁输入表列出 ⇒ **别人 clone 后**该输入面缺件、与现树不一致（行为可能不同）。
  处置选项：① 提交这三件；② 从该表剔除；③ 保留 ＋ 写"缺件即 `NOINFO`"的口径。三者都要动 `build/close-wave.sh`
  （**不在** `t159` 写域：本件写域 ＝ `build/MilBridge/tests/PtsPagesProbe/**` ＋ `docs/ROUTES.md` ＋ 载体）⇒ **只登记、不执行**。

**登记行原文**见 `docs/ROUTES.md` 末条 `⏪ **dated 登记（t159／scribe …）**`（本节内容逐字同源）。

---

## 3. 逐件改前／改后（现取 sha16 ＋ 行数 ＋ `numstat`）

| 件 | 改前 | 改后 | `numstat` |
|---|---|---|---|
| `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh` | `e6eb370def6b4b8e`（350 行） | **`330a90f1f0ac28e4`**（373 行） | `23 / 0`（纯新增） |
| `build/MilBridge/tests/PtsPagesProbe/session_inner.sh` | `390927970cd8839f`（266 行） | **`f1a582d9ea9788c9`**（272 行） | `6 / 0`（纯新增） |
| `docs/ROUTES.md` | `333c5857e9cabed7`（962 行） | **`8065dcd86dd19c25`**（979 行） | `17 / 0`（纯新增） |
| `build/MilBridge/tools/pts-pages-guard.sh`（**判据件**） | `962fec114b2d0692`（1346 行） | **同值、未动** | — |

- `bash -n` 两件装置件 **OK**；全仓 `shell-quote-trap-check.sh --root . --anchors off` ⇒ `SHELL_QUOTE_HIT` 命中 **0**。
- 相位位：`sed -n '51p' pts-pages-guard.sh` ⇒ `phase=degraded`（**未翻**）。
- ⚠️ **夹具里自己踩过一次 DQ-BACKTICK**（`~/w281-scribe/t159/fx1.sh` 的一行 `echo "== \`SESSION_TOOLS\` …"` 触发命令替换、打印
  `SESSION_TOOLS: 未找到命令`）—— **只在仓外夹具**、不影响读数；**仓内两件装置件 0 命中**（上面现取）。如实在册。

---

## 4. 具名 `NOINFO`（不算绿、也不算红）

1. **四件未跟踪件的"具体跑腿编号／写者"判不出**（无 PID 血缘、件内无 `ts`）⇒ 只登记"同刻同形"的来源判定。
2. **`r4`／`r0` 的转换器 `rc` 一次性干扰**（第一版夹具）：被我判为**副本缺伴生脚本**（`TOENV` 由 `SELF_DIR` 派生、
   无 env 旋钮）⇒ 计入 §1.2 的具名观察；**不是**改动引入（手工跑同一份转换器 `rc=0`，且 kit 版 r0/r4 均 `conv_rc=0`）。
3. **`SESSION_TOOLS` 在 r0/r1 两趟计数 0**：那两趟用**桩**（桩没有这行）⇒ 该列不参与"既有列对拍"；
   会话端由 `s1`／`s2`（真件两趟）单独覆盖。
4. **未跟踪件与门禁输入面的一致性**：本件**未裁、未动**（选项在 §2.4）⇒ 该风险记 **`NOINFO(待队长裁)`**。
5. `arm_A/app_g1.log` **不在**门禁输入表（现取 `close-wave.sh` 命中 `0`）⇒ 它是**纯遗留产物**，
   与另三件**不同面**；本件把它**一并登记**（同一目录、同一"无人认领"问题），但**处置口径不合并**。

---

## 5. 纪律

- 写域内改动只有上表三件 ＋ 本载体；**未碰** `src/WpfGfx.Linux.Native/**`（`t158` 在飞）、任何 `.cs`、两枚哨兵、
  `HANDOFF-NEXT.md` 的 `cell=#1`、`build/close-wave.sh`（**只引用**）。
- 夹具全在**仓外** `~/w281-scribe/t159/`（`fx1.sh` 与 `fx1/kit/**`）；**未进仓**。
- 显示只用 `:239`；夹具进程**按 PID** 收净（残留扫 0 行）；跑前/跑后 `/tmp/.X11-unix` ＝ `X0 X1`。
- 未跑整趟门禁、**未构建**；`cell=#1` **有意未登记**。

self16=86131b02acc18617
