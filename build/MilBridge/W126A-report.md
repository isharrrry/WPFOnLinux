# 车道 **W126A** 报告 —— 波 **`#52`** 收尾链（步骤 ①–⑩ 一步到底）

- **车道**：W126A（波 `#52` 收尾链唯一执行者）｜**日期**：2026-09-23 09:05:35 →（见 §⑨）
- **仓库根** `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
- **取代的冻结世代**：`#51 38e67e834430d75c` ⇒ **本波冻结为 `#52 27293fb5ab91b778`**（697,873 B）
- **口径**：凡读数必附命令；**不许手抄哈希**（纪律 49，一律脚本现算）；`NOINFO` **既不算绿也不算红**
- ⚠️ **报告自身 sha16 两行都给**（FULL sha256 ＋ 去行口径值）⇒ 见 §⑨ 末

---

## §0 · 一句话结论

**步骤 ①–⑩ 全部完成**（`#52` 已冻成 `27293fb5ab91b778`）；途中**命中过一次任务书的停条件**（冻前 `verify-all` 第 1 趟出现第 2 处**非声明类**红 `Windowing.Tests`），我**停手报主控**，主控裁定"加几何守卫后重跑" ⇒ 守卫落地、重跑复绿、继续冻结。另有**一次宿主重启**把我打断（非运行时挂死），以及**两处我自己的仪器自伤**（均已还原/留痕）。

---

## §1 · ① 三重握手读数（含等待入账）

### 判据（**先写后跑**，落在 `~/w126a/STATUS.md` 的 `[H0]`）
1. **第一判据 = 活进程**：`ps -eo pid,etime,cmd | grep -E 'w123a|w124a|w118a' | grep -v grep`。
   存在任何 `w123a` 进程 ⇒ **只许等，不许跑整波重建**（会与断链抢同一批产物文件）。
2. **第二判据 = 门**：`~/w123a/STATUS.md` 尾部须见「完成 `<批名>` ok=/skip=/bad=」。
3. **两者冲突 ⇒ 以进程为准**（本会话已有两条车道的 STATUS 滞后于真实动作）。
4. `w118a`／`w128a` 在跑 ⇒ 我入槽一律 `--wait 1800` 让路，**不打断**。

### 读数

| 时刻 | `w123a` 活进程 | 判定 | 动作 |
|---|---|---|---|
| 09:05:35 | **1 条**（`pid=409766`，`bash -c … for b in batch.bin.00 … batch.obj; do bash relink2.sh …`） | 握手**未通过** | **等待** |
| 09:08:10 | **0** | 通过（1/3） | 继续探 |
| 09:08:26 | **0** | 通过（2/3） | 继续探 |
| 09:08:42 | **0** | **通过（3/3）** | 落交接行 ⇒ 进步骤② |

- **等待入账**：09:05:35 → 09:08:10 = **2 min 35 s**。整波入槽另等 **459 s**（见 §2 步骤②）；冻前 `verify-all` 第 2 趟入槽等 **375 s**。
- 🔴 **方法论留痕（我自己踩的）**：我第一版探活用 `ps -eo cmd | grep -c 'w123a'` 得到 **`3`／`2`** ——
  那**把我自己的命令行也数了进去**（探活者污染）。⇒ 改用 **读 `/proc/*/cmdline` ＋ 排除自己的进程树**（`~/w126a/probe-alive.sh`，纪律 `D-G93`）后**三次全 0**。
  **教训**：探活读数必须先证明"**探活者不在被数集合里**"。
- **第二判据这格 = `NOINFO`（未取到）**：`~/w123a/STATUS.md` mtime 停在 **08:55:48**，尾部**没有**「完成 `<批名>` ok=…」行
  （该车道 09:07–09:08 在写 `report-section11-13.md`）。**替代证**（我自己取的，见 §2 步骤②前的复核）：
  `~/w123a/skip.batch.{bin.00,bin.01,bin.02,obj}.txt` **四本全在、全 0 字节**（mtime 09:03–09:05）⇒ 四批**逐批跑完且零跳过**；
  `bash build/MilBridge/tools/hygiene-tooth.sh` ⇒ **`HYGIENE_TOOTH=PASS … multilink=0 cross_region=0`**（`dc1e79a23dbb7eb2` 未改）。
- **主控独立放行（09:1x）**：`w123a` 活进程 0；断链总账 `1421＋6＋4588 = 6015` 已断（`upstream/` 6417 = 声明残留无写者）＝原始跨区共享数 **12432**。
- **主控提示的按 inode 记账项，我按纪律自己复算了一遍**（不引主控的数）：
  `python3 build/artifact-src-fp.py --check --list {PresentationCore,WindowsBase,PresentationFramework}.Linux`（⚠️ **只跑 `--check`**，**不跑 `--selftest`** —— 该自检今天会写真树，登记在 `#33` 剩余清单 B）⇒
  `proj=PresentationCore fp=3ae4746cd655023b n=1374 peer_fp=e442fdc0c64f3379 peer_n=8 state=ok`｜
  `proj=WindowsBase fp=0cf7e7daa70eb8a9 n=327 peer_fp=2a2ed993f748365d peer_n=2 state=ok`｜
  `proj=PresentationFramework fp=01a078bf78c6ed18 n=1363 peer_fp=0e31c2dc0c4e31c4 peer_n=9 state=ok`
  ⇒ **三维 `state=ok`、`peer_fp` 三工程间一致** ⇒ **换 inode 未扰动按 inode 记账的身份拉链**。

### 开工刻基线（全部现算）
- 九位：`bridge feef049e9d0e313a`｜`pc 722e0ab8205b7c3f`｜`pf bc2c47ac7b067bad`｜`windowsbase 2e4e46e539a72cd7`｜
  `provider 1f9511a7ef395bfe`｜**`win32shim bd037229be8db4f6`**(327,256 B)｜`wic_shim f7b3026c8c019be2`｜
  `hbtextline 921ba9c65e9fb3be`｜`dwf ce3469f49efcbcfa`
  ⇒ 相对 `#51` 冻结块：**只有 `win32shim` 一位不同**（`8392fc09564779a1 → bd037229be8db4f6`）
- `inputs_fp`（**真调用函数体**）= `72c5f2263f62a83d301f0852edcb049825e51be09e5646cad55274ba91e48015`（覆盖面 **149** 件）
- `docs/CURRENT-STATE.md:9` = `gen=#51 sha16=38e67e834430d75c`｜`verify-all.sh` `^run_step "` = **27**
- fork 克隆 head = `40a31ba289a94e3eaa8c82c1e8f67c90c4c62794`

---

## §2 · ② 步骤 ①–⑩ 逐步读数（每条 `HEAVYSLOT=` 行与耗时）

> **授权上限**（任务书）：整波 1200／五臂 1200／`verify-all` 1500／`build-shim.sh --all` 600／其余 300。
> **本波无 `MAXHOLD_KILL`、无 `NOINFO reason=low-memory`。**

### 步骤② · 整波重建
```
cd $R && WAVE_OWNER=W126A bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1200 --wait 1800 -- bash build/integration-wave.sh
```
| 项 | 读数 |
|---|---|
| 槽 | `HEAVYSLOT=ACQUIRED waited=459s`（**入槽等待 7 min 39 s**，`w118a` 让路）｜`HEAVYSLOT=MEMOK avail=2695MB min_avail=1500MB` |
| 释放 | **`HEAVYSLOT=RELEASED rc=0 held=177s max_hold=1200s`** |
| 机读 | **`APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0`**｜**`=== 集成波结束：失败步骤 0 ===`** |
| 责任闸 | `▶ 波责任人：W126A（记录于 …/build/wave-audit.log）` |
| 波自身稳定性 | `波前指纹 32b017f6d63d7a60…` ＝ `波后指纹` **逐位相同** ⇒ `✅ 一致 ⇒ 没有编辑竞态` |
| 日志 | `~/w126a/logs/02-wave.log` |

**`--max-hold 1200` 的理由**：整波含 28 应用器 ＋ 依赖序重建 ＋ 产物发布；`#50`/`#51` 实测 `held=221 s`/`177 s`。
**实际只用 177 s**（同 `#51`）⇒ 如实记：**本趟未用满授权**。

⚠️ **口径更正（我核过源码，免得后人拿错基准）**：上面那个"波前/波后指纹"是 `integration-wave.sh` 的 `wave_fp()`
（`:574-583`），盯的是"**波期间手写输入**有没有被改动"（`build/shims/**`／应用器／`src/**`）——**不是 `fp_inputs()`**。
`#51`（W110A）读到的 `9a265c5a2f9e7c4c…` 是同口径的另一刻值。**两值不可互比**。

**native 另跑**（⚠️ `integration-wave.sh` **从不编译 native**，故必须单独跑，不能省）：
```
bash src/WpfGfx.Linux.Native/build-shim.sh --all     # 槽内 --max-hold 600
```
⇒ `HEAVYSLOT=ACQUIRED waited=0s`｜`MEMOK avail=2320MB`｜**`RELEASED rc=0 held=2s max_hold=600s`**
⇒ **`== 导出符号总数：547`**（**不变** ✓）｜ABI 段 `结果：全部一致（编译期 _Static_assert 亦已通过）`｜产物 `bin/libwpfwin32.so（327256 字节）`
⇒ **`win32shim` 仍 = `bd037229be8db4f6`** ✓ —— **没变 ⇒ 不停手**（任务书：变了才停手报主控）。
如实记一条**与本波改动无关**的既有告警：`src/win32_misc.c:224: warning: this 'if' clause does not guard... [-Wmisleading-indentation]`
（`GetDpiForMonitor`）——该文件**不是** `D-G100` 的落点（`D-G100` 只动 `win32_core.c`／`win32_x11.c`），**我未处置、只报**。

**波后**：`inputs_fp` = `72c5f2263f62a83d…`（**与波前逐位相同** ⇒ 整波重建不改覆盖面成员的**内容** ⇒ **归因：零位移**）；
九位里 **`pf` 变了一位**：`bc2c47ac7b067bad` → **`358136b0c806ee88`**（**同尺寸 6,123,520 B**）⇒ 见 §3。

### 步骤③ · WIC 权威件同步
```
AUTH_ROOT=$R SCAN_ROOTS=$R/build:$R/tests:$R/samples:$R/src:$R/tools bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh [--apply]
```
| 阶段 | 读数 |
|---|---|
| 干跑 | `APPSYNC-REFRESH=refreshed=0 newer=0 applied=0`（rc=0） |
| `--apply` | `APPSYNC-REFRESH=refreshed=0 newer=0 applied=1`（**写了 0 件** ⇒ 无落单者；波内那步已刷 34 件） |
| 校验器 | `MISMATCH=0（STALE=0 NEWER-DIFF=0） MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0] DIVERGENT=0 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0` ⇒ **`STALE=0 DIVERGENT=0`** ✓ |

⚠️ **任务书前提更正（我现场核出的）**：任务书要求"**必须显式补根** `SCAN_ROOTS=…:tools`，否则会打出 `STALE=0` **假绿**（`D-G91`）"。
**`D-G91` 已被车道 W113A（2026-09-22）修掉**：`sync-applocal-authority.sh:103-105` 现在**不覆盖时从判据唯一实现派生**（`check-applocal-sync.sh --print-scan-roots`），
我实测**派生值已含 `…/tools`**；且**显式收窄**时会自检拒绝（`:107`）。⇒ 我仍按任务书**显式传同一集合**（与派生值同集 ⇒ 不是收窄 ⇒ 通过自检），**两法同值**。
`UNEXPECTED=6[DECL-GAP-EQ=6]` = **在册**声明类缺口：**不当绿、不改判据**。

### 步骤④ · 五臂重取（**预测先写、后取读数**）
**预测**（`~/w126a/criteria.md` C4，写于取数之前）：本波只动 `win32shim`（＋可能的 `pf`）⇒ **`tline` 位可能变**（运行相关字段）；
`tab-zero`/`tab-anchor`/`tab-rtl`/`textlineproto` **逐位不变**；五臂**判词与 `#51` 逐字相同**。**判词变了 ⇒ 停手报主控。**

```
ARMS_OUT=$HOME/w126a/arms bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1200 --wait 1800 -- timeout 1150 bash build/MilBridge/tools/retake-arms-w23.sh
```
⇒ `HEAVYSLOT=ACQUIRED waited=12s`｜`MEMOK avail=2474MB`｜**`RELEASED rc=0 held=352s max_hold=1200s`**
（授权 1200：`#50`/`#51` 实测 307/318 s ⇒ 300 s 装不下；**实际 352 s**，比前两代略长，**仍在授权内**）
｜`ARMS_DISPLAY=:97 source=none ⇒ 自起 Xvfb`（`xvfb_pid=678643`，**跑完按 PID 收回**；**未碰** `:0/:1/:10/:95/:96/:99`）
｜取臂前自证：`shim = 921ba9c65e9fb3be`｜`pc = 722e0ab8205b7c3f`｜`run.sh = 711f39f468f61cc8`｜`Parity.cs = 149dd986a642fdfc`｜`CoverageProbe build rc=0`

**读数（五臂 sha16）**：

| 臂 | `#51` 冻结值 | 本波 | 变? | `rc` |
|---|---|---|---|---|
| `tline` | `9d29470d63791d64` | **`56bea7233ba05c7b`** | **变**（**预测命中**） | 1 |
| `tab-zero` | `9150c3a26a3cb789` | `9150c3a26a3cb789` | 未变（预测命中） | 1 |
| `tab-anchor` | `1c43a12dcaa5718a` | `1c43a12dcaa5718a` | 未变（预测命中） | 0 |
| `tab-rtl` | `92570318851ca7e8` | `92570318851ca7e8` | 未变（预测命中） | 0 |
| `textlineproto` | `4bceceeed570ba70` | `4bceceeed570ba70` | 未变（预测命中） | 0 |

**判词（与 `#51` 逐字相同 ⇒ 不停手）**：
- `tline`：**`通过 22 / 失败 2`**（`⇒ **有失败**`，两条既有 ❌）
- `tab-zero`：**`退出码=1`**（唯一失败 = 在册 `notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白 期望=0 实得=1`；`未登记失败 1 / 失败共 1`）
- `tab-anchor`：**`退出码=0`**（`START 红=0 绿=615 判定行=615`／`OVERFLOWED 红=0 绿=421 判定行=421`／`未登记失败 0 / 失败共 0`）
- `tab-rtl`：**`退出码=0`**｜`textlineproto`：**`通过 10 / 失败 0`**

⚠️ **机制留痕**：重取脚本末尾用 **`ln -f`** 把新日志硬链进 `build/MilBridge/arm-logs/`（五行逐条印 `(links=2)`）——
这是**仓内既定机制**（`fp_inputs()` 的注释里写明"重取用 `ln -f`"，且**因此刻意不把 `arm-logs/` 纳入覆盖面**，否则每个重取过的波都会把"输入稳定性"变成噪音），**不是**我沙箱的污染（我自己的实验全程 `cp -p`、**零 `ln`**）。

### 步骤⑤ · 重钉 `known-red.json`
| 阶段 | 读数 |
|---|---|
| 备份 | `~/w126a/backup/known-red.before-repin.json`（`cp -p`，与改前**逐位相同** `089b7324ba12e022`） |
| `--check` 前 | **`REPIN_GENERATION=FAIL n=2`**（`generation.arm_logs.tline 不一致`；`evidence_log_sha256 声明=9d29470d63791d64 现场=56bea7233ba05c7b`） |
| `--why '…'` | **`REPIN_GENERATION=APPLIED`**：`instr_run_sh=711f39f468f61cc8`｜`instr_program_cs=149dd986a642fdfc`｜`instr_shim=921ba9c65e9fb3be`｜`evidence_log_sha256=56bea7233ba05c7b`｜**`entries[*].caliber 改动字段数=0`** |
| `--check` 后 | **`REPIN_GENERATION=PASS（世代三项 + 五臂 + 证据日志 + 4 条 entries 的 caliber 全部一致）`** ✓ |
| 件 | `known-red.json` **`089b7324ba12e022` → `d4e0080df6ec497c`** |
| `inputs_fp` | **`84fd55d384e93203317d22601cec854d518e69c8f026006231302a2cfbc93366`**（**变** —— 归因：**`known-red.json` 在 `fp_inputs()` 覆盖面内**，`#28` 起的设计使然；覆盖面仍 149 件） |

**两极化（这是"顺序"不是"矛盾"，我查明后更正了自己的措辞）**：

| 时刻 | `arm-log-sha-check.sh` | `column-floor-check.sh` |
|---|---|---|
| 重钉**前** | `ARMLOG_SHA=FAIL pass=4 fail=1` | `COLUMN_FLOOR=PASS n_ok=5` |
| 重钉**后** | **`ARMLOG_SHA=PASS 5/5`** | **`COLUMN_FLOOR=FAIL … bad= tline`** |

`DECLARATION_CHECKS = ('BASELINE-SHA','ARM-LOG-SHA')`（`w27-freeze.py:363`），而 `COLUMN-FLOOR` 只在
`COLUMN_FLOOR_ARMLOG=FAIL ∧ selfreport=PASS` 时才被 `_is_declaration_class()` 认作声明类。
⇒ 任务书说的"冻前恰好 1 处声明类红 = `COLUMN-FLOOR`"**成立的前提是"重钉已做"**（`#51` 就是这个形态）。

### 步骤⑥ · 应用门禁 ×2（**两趟各写一本 rows**）
```
第 1 趟：WPTD_RUN_DIR=$HOME/w126a/gate-e WPTD_BASELINE_OUT=$HOME/w126a/gate-rows.txt     … run-wpftextdemo.sh 60 --tier both
第 2 趟：WPTD_RUN_DIR=$HOME/w126a/gate-f WPTD_BASELINE_OUT=$HOME/w126a/gate-rows-f.txt   … run-wpftextdemo.sh 60 --tier both --no-build
```
> ⚠️ **两趟必须写两本**：写同一本会因追加语义变成 12 行，而冻结器断言 `len(rows)==6` ⇒ 会红。

| 趟 | 入槽 | `MEMOK` | 槽读数 | `default` | `env` |
|---|---|---|---|---|---|
| 1 | `waited=0s` | `avail=6152MB` | **`RELEASED rc=0 held=167s max_hold=300s`** | rep 1/2/3 全 `RESULT=PASS` | rep 1/2/3 全 `RESULT=PASS` |
| 2 | `waited=0s` | `avail=5628MB` | **`RELEASED rc=0 held=162s max_hold=300s`** | 同 | 同 |

- ⇒ **门禁本波 12/12 PASS**（`GATE1_OUTER_RC=0`／`GATE2_OUTER_RC=0`）
- `WPTD_SUMMARY=PASS tiers_passed=2/2`｜`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`
- `WPTD_BRIDGE_SRC_STALE=no basis=pub=0a8f69b3c5fabd43 now=0a8f69b3c5fabd43 so_file_match=yes`（两趟逐字相同）
- 两本 rows：**各 6 行 `BASELINE`／6 `result=PASS`／0 `result=FAIL`**｜sha16 `gate-rows.txt=60130d6c9bc832b4`、`gate-rows-f.txt=2db6410ce31e2fdc`
  ｜**两本 `config=` 逐字相同** = `pc:722e0ab8205b7c3f`／**`pf:358136b0c806ee88`**／`win32shim:bd037229be8db4f6`／
  `bridge:feef049e9d0e313a`／`provider:1f9511a7ef395bfe`／`wic_shim:f7b3026c8c019be2`／`hbtextline_shim:921ba9c65e9fb3be(stale:no)` ⇒ **终态九位**
- `held=167 s`／`162 s`（`#50`/`#51` 实测 161/158 s ⇒ 同量级；**300 s 授权够用、未用满**）

### 步骤⑦ · 冻前 `verify-all`（27 步）—— **第 1 趟命中停条件，第 2 趟通过**
见 §4（逐项）与 §8（停条件与守卫）。

### 步骤⑧ · 冻结 `#52`
见 §6。

### 步骤⑨ · 冻后 `verify-all` ×2
见 §5。

### 步骤⑩ · 记录／推送／app-local
见 §7。

---

## §3 · ③ 九位冻前/冻后成对表 ＋ `pf` 那条既知属性（逐字）

| 位 | `#51` 冻结块 | 冻前刻（我这趟开工时） | **冻结刻 / 冻后刻** | 变? |
|---|---|---|---|---|
| `bridge` | `feef049e9d0e313a` | `feef049e9d0e313a` | `feef049e9d0e313a` | 否 |
| `pc` | `722e0ab8205b7c3f` | `722e0ab8205b7c3f` | `722e0ab8205b7c3f` | 否 |
| `pf` | `bc2c47ac7b067bad` | `bc2c47ac7b067bad` | **`358136b0c806ee88`** | **是**（`D-G92`） |
| `windowsbase` | `2e4e46e539a72cd7` | `2e4e46e539a72cd7` | `2e4e46e539a72cd7` | 否 |
| `provider` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | 否 |
| `win32shim` | `8392fc09564779a1` | **`bd037229be8db4f6`** | **`bd037229be8db4f6`** | **是**（`D-G100`） |
| `wic_shim` | `f7b3026c8c019be2` | `f7b3026c8c019be2` | `f7b3026c8c019be2` | 否 |
| `hbtextline` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | 否 |
| `dwf` | `ce3469f49efcbcfa` | `ce3469f49efcbcfa` | `ce3469f49efcbcfa` | 否 |

（命令：`bash ~/w95a/nine.sh`；三刻读数分别留档 `~/w126a/precheck/nine-before.txt`／`nine-after-wave.txt`／`nine-pre-freeze.txt`。）

### 🔴 `pf` 这一格**不是构建身份**（`D-G92`）—— 逐字说明（写进冻结块）

> **`pf` 不是构建身份**：同源、同命令的两次重建可给出**不同字节**。
> 本波是一条**新的连续证据**（`#50`/`#51`/`#52` 三代连续）：本波收尾链**整波重建之后**，`pf` 自己变了一次
> —— `bc2c47ac7b067bad` → `358136b0c806ee88`，**同尺寸 6,123,520 B**，期间**无人改任何 PF 源或应用器**。
> ⇒ 本代 `allow_changed = {win32shim, pf}`、`pf_required=False`；**两刻不同不算失败**（它是既知属性，不是回归）。
> **冻结器现场断言**：`本波位移 = ['pf', 'win32shim']`（在允许集合内）；
> `本代声明允许位移、且真的动了的位 = ['win32shim']`（其余八位逐位与开工前相同）。
> **两刻并列**：`#51` 冻结点 `pf = bc2c47ac7b067bad`（那是 `#51` 收尾链整波重建**之后**的值）｜本波冻结点 `pf = 358136b0c806ee88`。
> **仍然 `NOINFO`**：真凶未抓到 ⇒ 见 §8。**要什么样的读数**：一个覆盖 PF **全部**编译输入的指纹。

---

## §4 · ④ 冻前 `verify-all`：27 步逐行 ＋ 那 1 处声明类红（逐字）

**第 1 趟（`07-verify-all-pre.log`）—— 停条件命中，未用于冻结**
- 槽：`HEAVYSLOT=ACQUIRED waited=55s`｜`MEMOK avail=5979MB`｜**`RELEASED rc=1 held=911s max_hold=1500s`**
- 汇总：`步骤通过 25 ❌ 失败 2`｜`用例通过 831 跳过 2`｜`SKIP_GUARD=PASS x_state=available violations=none`
  ｜**`结论：❌ 失败项：Windowing.Tests COLUMN-FLOOR`**
- 逐套件：`Commands.Tests ✅ 562/0`｜`Rendering.Tests ✅ 166/2`｜**`Windowing.Tests ❌ (rc=1)`**｜`HelloMil.Tests ✅ 19/0`｜`ManagedLayer.Tests ✅ 76/0`｜`Presentation.Tests ✅ 8/0`
  （`562＋166＋19＋76＋8 = 831` ⇒ Windowing 的 41 个**通过例因套件 rc=1 未被计入**）
- `Windowing.Tests` 逐例：`失败: 3，通过: 41，已跳过: 0，总计: 44`：
  `X11PresentationTargetTests.EventLoop_DeliversExpose_And_Close [FAIL]`／
  `X11PresentationTargetTests.PresentationTarget_SatisfiesContract [FAIL]`／
  `X11RealInputEventTests.MouseMove_DeliversMotionNotify_WithExactCoordinates(x: 473, y: 2) [FAIL]`
- `[0]` 段逐字：`✅ 复用已运行的 Xvfb（实测 display :185，注意不是 :99）`｜`DISPLAY=:185`｜`X_STATE=available`
- ⇒ **第 2 处红是非声明类 ⇒ 我按任务书停手**（见 §8）

**第 2 趟（`07b-verify-all-pre2.log`）—— 本件的冻结输入**
- 槽：`HEAVYSLOT=ACQUIRED waited=375s`｜`MEMOK avail=6126MB`｜**`RELEASED rc=1 held=854s max_hold=1500s`**｜`VERIFYALL_PRE2_OUTER_RC=1`
- 汇总：**`步骤通过 26 ❌ 失败 1`**｜**`用例通过 875 跳过 2`**｜`SKIP_GUARD=PASS x_state=available x_died=0 x_suite_skipped=0 violations=none reason=none`
  ｜**`结论：❌ 失败项：COLUMN-FLOOR`**
- **逐套件六套件全绿**：`Commands.Tests ✅ 562/0`｜`Rendering.Tests ✅ 166/2`｜**`Windowing.Tests ✅ 44/0`**｜
  `HelloMil.Tests ✅ 19/0`｜`ManagedLayer.Tests ✅ 76/0`｜`Presentation.Tests ✅ 8/0`
  ⇒ `用例通过 875`（**与 `#51` 逐格相同**）
- `[0]` 段逐字（**守卫生效的证据**）：`✅ X-REUSE=reused display=:97（已运行的 Xvfb；几何 1280x1024 相符；注意不是 :99）`｜`DISPLAY=:97`｜`X_STATE=available`
- **唯一那 1 处红 = 设计内声明类（逐字）**：
  ```
  COLUMN-FLOOR                 ❌  (rc=1)
      COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline
      COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0 selfreport=PASS reg=d4e0080df6ec497c base=38e67e834430d75c corpus=0cebc0afd5142fbf
  ```
- **其余 26 步全绿**，关键机读行（逐字）：
  - `BASELINESHA=PASS live=38e67e834430d75c decl=38e67e834430d75c`
  - `BASELINEGEN=PASS decl_gen=#51 file_newest_gen=#51`｜`BASELINEDUP=PASS n=0`
  - `ARMLOG_SHA=PASS shape=flat required=5 declared=5 pass=5 fail=0 noinfo=0`（**重钉后已转绿**）
  - `VERIFYALL_SELF=PASS names=27 decl=27 gen=#52 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=0cdd12547a634b37`
  - `R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938 mem_mb=5321 win32shim=bd037229be8db4f6 pc=722e0ab8205b7c3f src=device`
  - `NULBYTES=PASS files=1210 hits=0 bytes=252109905 skipdir_dirs=141 binext=280 otherext=0 noext=11 diag_noext_nonelf=0 diag_otherext_nul=0 canary=ok`
  - `PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=72 sites=78 hit=0 low=7 diag=2 safe=69 runs=12`
  - `FRAMEPRESENCE=PASS frames=80 max_colors=4113 magenta_frames=38 min_colors=200`
  - `THIRDPARTY=PASS frames=41 max_colors=1642 min_colors=800`｜`THIRDPARTY_BUILD=PASS rc=0`

---

## §5 · ⑤ 冻后 `verify-all` ×2 全绿证据

日志：`~/w126a/logs/09-post.log`（两趟写同一本，用 `冻后第 N 趟` 分段）。

| 趟 | 起始 | 槽 | 汇总 |
|---|---|---|---|
| 1 | 10:50:02 | `ACQUIRED waited=751s`｜`MEMOK avail=5926MB`｜**`RELEASED rc=0 held=867s max_hold=1500s`** | **`步骤通过 27 ❌ 失败 0`**｜`用例通过 875 跳过 2`｜**`结论：✅ 全部通过`** |
| 2 | 11:17:00 | `ACQUIRED waited=837s`｜`MEMOK avail=6051MB`｜**`RELEASED rc=0 held=854s max_hold=1500s`** | **`步骤通过 27 ❌ 失败 0`**｜`用例通过 875 跳过 2`｜**`结论：✅ 全部通过`** |

⇒ `POST1_OUTER_RC=0`／`POST2_OUTER_RC=0` ⇒ **冻后 27/27 全绿**（含第 `[27]` 步 `NUL-BYTES`）。
逐套件两趟都是 `Commands 562/0`｜`Rendering 166/2`｜`Windowing 44/0`｜`HelloMil 19/0`｜`ManagedLayer 76/0`｜`Presentation 8/0`。

### 关键机读行两趟对照（`awk` 按 `冻后第 N 趟` 分段后逐字段比）

**13 个字段 `IDENTICAL`**：
`BASELINESHA=`｜`BASELINEGEN=`｜`BASELINEDUP=`｜`ARMLOG_SHA=`｜**`COLUMN_FLOOR=`**｜`VERIFYALL_SELF=`｜`NULBYTES=`｜
`FP_INPUTS_HYGIENE=`｜`PIPEFAIL_SIGPIPE=`｜`SKIP_GUARD=`｜`步骤通过`｜`用例通过`｜`结论：`

其中（逐字）：
- `BASELINESHA=PASS live=27293fb5ab91b778 decl=27293fb5ab91b778`｜`BASELINEGEN=PASS decl_gen=#52 file_newest_gen=#52`｜`BASELINEDUP=PASS n=0`
- **`COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=d4e0080df6ec497c base=27293fb5ab91b778 corpus=0cebc0afd5142fbf`**（**冻前那 1 处红已转绿**）
- `ARMLOG_SHA=PASS required=5 declared=5 pass=5 fail=0 noinfo=0`
- `VERIFYALL_SELF=PASS names=27 decl=27 gen=#52 dup=0 order=OK prose=OK prereg=PASS vfile_sha16=0cdd12547a634b37`
- `NULBYTES=PASS files=1210 hits=0 canary=ok`｜`SKIP_GUARD=PASS x_state=available x_died=0 violations=none`

**3 个字段 `DIFF`（都是运行期读数、不是判词 —— 如实记，不当作差异抹掉）**：
| 字段 | 第 1 趟 | 第 2 趟 | 性质 |
|---|---|---|---|
| `R_GATE` | `mem_mb=5806` | `mem_mb=5592` | **运行期内存读数**（同格其余字段逐字相同，判词都是 `R_GATE=PASS crit=13/13 … red=0 noinfo=0`） |
| `FRAMEPRESENCE` | `dir=…/w34-framepresence-111338` | `dir=…/w34-framepresence-114151` | **带时间戳的目录名**（`frames=80 max_colors=4113 magenta_frames=39 min_colors=200` 逐字相同） |
| `THIRDPARTY` | `frames=41 dir=…/w37-tpm-111553` | `frames=42 dir=…/w37-tpm-114403` | **帧数 ＋ 带时间戳的目录名**；判词 `THIRDPARTY=PASS` 与 `max_colors=1642 min_colors=800` 逐字相同（`frames` 是运行期采样计数，**不是判据**） |

### 九位（冻后刻，第 2 次复算，与冻前刻成对并列）
`bridge feef049e9d0e313a`｜`pc 722e0ab8205b7c3f`｜**`pf 358136b0c806ee88`**｜`windowsbase 2e4e46e539a72cd7`｜
`provider 1f9511a7ef395bfe`｜`win32shim bd037229be8db4f6`｜`wic_shim f7b3026c8c019be2`｜`hbtextline 921ba9c65e9fb3be`｜`dwf ce3469f49efcbcfa`
⇒ **与冻前刻（`~/w126a/precheck/nine-pre-freeze.txt`）逐位相同**，**含 `pf`**（预测命中：`verify-all` 的构建没有动 `pf`）。
冻结件两趟之后仍 **`27293fb5ab91b778`**；`inputs_fp` 仍 **`84fd55d3…`**。

---

## §6 · ⑥ 冻结机器行与三颗牙

### 冻结
```
python3 $HOME/w21-verify/w27-freeze.py ~/w126a/logs/07b-verify-all-pre2.log ~/w126a/gate-rows.txt '#52'
```
⇒ `FREEZE_RC=0`：
- `相对开工前变化的位 = ['pf', 'win32shim']`｜`本波位移 = ['pf', 'win32shim']（在本代声明的允许集合 ['pf', 'win32shim'] 内）`
- `本代声明允许位移、且真的动了的位 = ['win32shim']（其余八位逐位与开工前相同）`
- `inputs_fp = 84fd55d384e93203317d22601cec854d518e69c8f026006231302a2cfbc93366`｜`BRIDGE_SRC_FP = 0a8f69b3c5fabd43`
- `门禁 6 条机读行 OK（pc:722e0ab8205b7c3f pf:358136b0c806ee88）`（⇒ **`verify-all` 的构建没有动 `pf`** —— 我在 `[STEP 7-风险]` 的预判命中）
- **`基线已重冻为 #52；整份 sha16 = 27293fb5ab91b778`**（`BASELINE_BYTES=697873`）

### 三颗声明牙（冻后，同一批检查器）
| 牙 | 读数 |
|---|---|
| `BASELINE-SHA` | **`BASELINESHA=PASS live=27293fb5ab91b778 decl=27293fb5ab91b778`**｜`BASELINEGEN=PASS decl_gen=#52 file_newest_gen=#52`｜`BASELINEDUP=PASS n=0` |
| `ARM-LOG-SHA` | **`ARMLOG_SHA=PASS shape=flat required=5 declared=5 pass=5 fail=0 noinfo=0`**（**冻前是 FAIL，冻后转绿** ✓） |
| `COLUMN-FLOOR` | **`COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=d4e0080df6ec497c base=27293fb5ab91b778 corpus=0cebc0afd5142fbf`**（**冻前那 1 处红已转绿** ✓） |

⇒ 冻结器尾行：`✅ 两极化齐：冻前 BASELINE-SHA/ARM-LOG-SHA/COLUMN-FLOOR(ARMLOG) 红 ⇒ 冻后同一批检查器都绿`

### 机器行
```
docs/CURRENT-STATE.md:9  > BASELINE-FROZEN gen=#52 sha16=27293fb5ab91b778 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
```

### ⚠️ 冻结时的两处自伤（都留痕，都已还原）
1. **第 1 次冻结失败**：`COLUMN_FLOOR=NOINFO reason=frozen-block-has-no-COLUMN-FLOOR-line`，冻结器 `assert` 在**写盘之后**失败
   （基线曾被写成 `50badf1f0277b789`）。**根因 = 与 `#51` 同一个坑**：三类外挂声明行（`# COLUMN-FLOOR `／`# COLUMN-CORPUS `／`# ARM-LOG-SHA `）
   **必须在冻结块里且必须有 `# ` 前缀**，我第一版记录件的冻结段**一行都没写**。
   ⇒ `cp -p` **从备份逐字节还原** `ACCEPTANCE-BASELINE.md`（回 `38e67e834430d75c`）＋ `docs/CURRENT-STATE.md`（回 `b7b2d513cfdab2eb`），
   补插 8 行（其中 **`tline` 必须是 `#52` 的 live 值 `56bea7233ba05c7b`**），再重冻。
   **教训（两条合起来才完整，已写进冻结块）**：① 外挂声明行只在**冻结块**里被认（前缀必须 `# `）；
   ② **冻结器是先写盘、后断言** ⇒ 断言失败时盘上**已经**是半成品 ⇒ **重冻前必须先还原**，否则第二代块会叠在坏块上。
2. **`ACCEPTANCE-BASELINE.md` 里没有 `# RE-FROZEN #50` 块**（只有 `#51`@`:25` 与 `#18`@`:1842`）
   ⇒ 我第一版生成 `w52-pre.sha` 的脚本用"找下一个 `RE-FROZEN` 来切上一代块"**一路吃到 `#18`**（实测切出 1818 行）
   ⇒ 改为**锚 `#51` 块顶部九位清单行（`:47–:49`）**。另修一处：我第一版把 `dwf` 路径用字符串 replace 拼成了
   `build/DirectWriteForwarder.Linux/bin/Release.dll`（**错**）⇒ 改为 `…/bin/Release/DirectWriteForwarder.dll`。

---

## §7 · ⑦ 记录 ＋ 推送 ＋ app-local

### 7.1 记录件
`$HOME/w21-verify/w52-record.txt`（三段 `===BANNER===`／`===FROZEN===`／`===RECORD===`，口径照 `w50`/`w51-record.txt`）——
**它已被冻结器写入 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的首部**；冻结**之后**该文件**只在末尾追加**一段
「冻后补记」（明确标注**不在冻结块内**）。
⚠️ **我第一版记录件漏了三类外挂声明行**（`# COLUMN-FLOOR `／`# COLUMN-CORPUS `／`# ARM-LOG-SHA `）⇒ 第 1 次冻结失败，
补插后重冻成功 —— 详见 §6 与 §8。

### 7.2 推送机制现场勘查（**先搞清机制再动**）
`~/netTest/GitProj/WPFOnLinux` 是**独立检出，不自动跟随 `$R`**（`git status --porcelain` 干净 ⇒ 工作树 == `HEAD(40a31ba289a94e3e…)`）。
逐件比对证实：`src/WpfGfx.Linux.Native/src/win32_core.c` ⇒ **`R=3117923a7c899e05` / `C=e0cbc965772d06c1`（DIFF）**；
`known-red.json`／`ACCEPTANCE-BASELINE.md` 虽"同值"，只是因为它们**在 `#51` 就被提交过且之后没变**，**不是**同步机制。
⇒ **推送必须先显式 `cp`**（`W122A` 的 commit message 里自记过"上一笔 `cp` 清单漏了 `defect-registry-declared.tsv`
⇒ 远端 `DECL-ANCHORS` 过期"—— 那正是漏 cp 的现场）。
⇒ 我用 `git ls-files`（**15260** 件）逐件 `cmp $R/$f vs $C/$f` 求清单（脚本 `~/w126a/cp-and-stage.sh`）。

### 7.3 推送（第 1 笔）
```
推前 head   = 40a31ba289a94e3eaa8c82c1e8f67c90c4c62794   （== origin/feat-Linux）
fetch       : git fetch origin feat-Linux:refs/remotes/origin/feat-Linux   （refspec 陷阱已避）
commit      = 37def7e480ea33fbd965195588410a7ee68b6434  （16 件；逐径 git add，**未用 -A／--force**）
push        : git push origin feat-Linux   ⇒  40a31ba..37def7e  feat-Linux -> feat-Linux
核对（**push 之后重新 fetch**）:
  HEAD(local)     = 37def7e480ea33fbd965195588410a7ee68b6434
  remote-tracking = 37def7e480ea33fbd965195588410a7ee68b6434
  ls-remote       = 37def7e480ea33fbd965195588410a7ee68b6434   ⇒ **三者一致 ✔**
  ls-remote --symref origin HEAD ⇒ `ref: refs/heads/feat-Linux  HEAD` ✔
```
staged 清单（`git status --porcelain`，无夹带）：
```
M build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh ｜ M build/MilBridge/arm-logs/tline.log
M build/MilBridge/gen/t2d-family-baseline.txt ｜ M build/MilBridge/gen/t2d-family-matrix.txt
M build/MilBridge/known-red.json ｜ M build/MilBridge/tools/repin-generation.py ｜ M build/wave-audit.log
M docs/CURRENT-STATE.md ｜ M docs/WAVE52-PREREGISTRATION.md ｜ M samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
M src/WpfGfx.Linux.Native/src/win32_core.c ｜ M src/WpfGfx.Linux.Native/src/win32_internal.h
M src/WpfGfx.Linux.Native/src/win32_x11.c
M tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh
M tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh ｜ M verify-all.sh
```

### 7.4 `BYTECHECK`（**rev = push 之后重新 fetch ＋ `ls-remote` 交叉核**）
```
rev = 37def7e480ea33fbd965195588410a7ee68b6434 ／ ls-remote = 同值 ⇒ rev-xcheck 一致 ✔
ok  build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh
ok  build/MilBridge/arm-logs/tline.log                        (disk=56bea7233ba05c7b)
ok  build/MilBridge/gen/t2d-family-baseline.txt
ok  build/MilBridge/gen/t2d-family-matrix.txt
ok  build/MilBridge/known-red.json                            (disk=d4e0080df6ec497c)
ok  build/MilBridge/tools/repin-generation.py                 (disk=711a1fc30764d84c)
ok  build/wave-audit.log
ok  docs/CURRENT-STATE.md                                     (disk 含 gen=#52 sha16=27293fb5ab91b778)
ok  docs/WAVE52-PREREGISTRATION.md                            (disk 含 §R1)
ok  samples/WpfTextDemo/ACCEPTANCE-BASELINE.md                (disk=27293fb5ab91b778)
ok  src/WpfGfx.Linux.Native/src/win32_core.c                  (disk=3117923a7c899e05)
ok  src/WpfGfx.Linux.Native/src/win32_internal.h
ok  src/WpfGfx.Linux.Native/src/win32_x11.c                   (disk=11142fbef049eb66)
ok  tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh
ok  tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh
ok  verify-all.sh                                             (disk=0cdd12547a634b37)
BYTECHECK ok=16 mismatch=0 nobody=0
```

### 7.5 ⚠️ **刻意不推**的件（逐件点名 ＋ 理由 ＋ **机器证**；请主控裁）
| 件 | `$R` 的 mtime | 为什么不推 |
|---|---|---|
| `docs/ROUTES.md` | **2026-09-23 11:46:29** | **登记车道的人工册件**；mtime 显示它在我推送前 **≈4 分钟**仍在被写 ⇒ 推它 = 推**半成品** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | **2026-09-23 11:46:29** | 同上（主控明示"另派了登记车道，它会**等 `gen=#52` 出现之后**才动册" —— `gen=#52` 已出现 ⇒ 它正在动） |
| `build/MilBridge/tools/defect-registry-declared.tsv` | **2026-09-23 11:47:31** | 同上；且它在我的**禁改清单**里 |

⚠️ 这三件**都不在** `fp_inputs()` 覆盖面内（我自己核过：`grep -c 'defect-registry-declared.tsv'` 我自己的 149 件清单 = **0**），
也**不参与** `#52` 的冻结语义（冻结块断的是九位／`known-red.json`／臂日志／两颗下限值）⇒ **不推不影响 `#52` 的冻结**。
另有 **7 份别的车道的报告**在 `$R` 里但不在克隆里（`W115A`／`W118A`／`W119A`／`W121A`／`W123A`／`W125A`／`W131A`），
其中 **W118A／W131A 的车道当时仍在跑** ⇒ 我**没有推**（避免推半成品），**交主控裁**。

### 7.6 app-local 刷新（**显式补根**；`D-G91` 已于 `#52` 之前被 W113A 修掉）
```
AUTH_ROOT=$R SCAN_ROOTS=$R/build:$R/tests:$R/samples:$R/src:$R/tools bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh --apply
```
- ⇒ `APPSYNC-REFRESH=refreshed=4 newer=0 applied=1`（**本次真刷了 4 件副本**）
- 校验器：`MISMATCH=0（STALE=0 NEWER-DIFF=0） MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0] DIVERGENT=0 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`
  ⇒ **`STALE=0 DIVERGENT=0`** ✓（`UNEXPECTED=6` = **在册**声明类缺口，**不当绿、不改判据**）
- **`check-applocal-sync.sh --selftest`** ⇒ **`SELFTEST=PASS`**、`SELFTEST_RC=0`；
  `计数：OK=6 MISMATCH=0（STALE=0 NEWER-DIFF=0） MISSING=0 UNEXPECTED=0[DECL-GAP-EQ=0 DECL-GAP-DIFF=0] DIVERGENT=0 CROSS-CONFIG=0 LIB-COPY=0 SKIP(obj)=0 SKIP(stub)=0 SKIP(ref)=0 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=2 BRIDGE-NOINFO=0`
  （`BRIDGE-ANCHOR=2` 是自检沙箱里的**诊断计数**，不是失败）

---

## §8 · ⑧ 作废趟／`NOINFO`／纪律偏离／自伤

### 8.1 停条件命中（**本波最重要的一件事**）
- **现象**：冻前 `verify-all` **第 1 趟** `步骤通过 25 ❌ 失败 2`，红#2 = **`Windowing.Tests`（非声明类）** ⇒ **命中任务书停条件** ⇒ **我停手、未冻结、报主控**。
- **根因（现场取证，不是推测）**：`verify-all.sh` 的 `[0] Xvfb` 段**只验"这个 display 连得上"（`xdpyinfo`）、不验几何**
  （`:391-402`）⇒ 复用了**别的车道（W128A）**的 `Xvfb :185 -screen 0 1024x768x24`，而本闸门**自己起的是 `1280x1024x24`**（`:404`）
  ⇒ 依赖窗口几何/指针坐标的三条 `[X11Fact]`/`[X11Theory]` 用例**假红**。
  对照：`#51` 时 `用例通过 875`，第 1 趟 `831`，**差 44 = `Windowing.Tests` 整套件总数**。
- 🔴 **我自己的一处判断被推翻（如实更正）**：我写过"`:185` 是**宿主重启遗留的孤儿**（`PPID=1` ⇒ 被 init 收养）"。
  主控用 `/proc/*/environ` 证明它是 **W128A 的活批次**；**我自己复算也确认**：`pid=183377/183379/183394` 的 `environ` 命中 `DISPLAY=:185`，
  命令是 `~/w128a/run/W010/gdb.cmds --args dotnet HandyControlDemo.dll`；且 `:185` 的 `lstart` = **10:02:46**（**重启之后**才起）。
  ⇒ **"`PPID=1`" 只说明 Xvfb 被 reparent，不等于"无主"**。**我已按主控禁止，未杀它、未碰它。**
- **处置（主控授权；"更严、不是放宽"）**：给 `verify-all.sh` 加 **X 显示几何守卫** —— 复用前必须核
  `几何 == $XREQ_GEOM（1280x1024）`，不符 ⇒ **跳过并点名**，全不符则照常自起自己的；**两处复用点同趟加**
  （**只改 `[0]` 是只修一半**：`x_recheck_alive()`（`D-G59` 的中途复核换显示）**同样"只看能连上"**）。
  三态机读行：`X-REUSE=reused`｜`X-REUSE=skipped-geom-mismatch`｜`X-REUSE=self-started`。
  `verify-all.sh` `1fb43fc4522c8784` → `cb30ccae51a7607a` → **`0cdd12547a634b37`**；`bash -n` rc=0；**步数不变（27）**。
- **两极化实测**（对**真件**提取的真段落跑；**只注入 `pgrep` 的候选清单**，几何探测与自起都是真的）：

| 极性 | 场景 | 期望 | 实测 |
|---|---|---|---|
| ① | 场上只有 `:185`(1024x768) | 跳过 ＋ 自起 | `⏭ X-REUSE=skipped-geom-mismatch display=:185 实测几何=1024x768 … ⇒ **跳过它**` ＋ `✅ X-REUSE=self-started display=:99 -screen 0 1280x1024x24` ✓ |
| ② | 场上有 `:97`(**1280x1024**) | **仍应复用** | `✅ X-REUSE=reused display=:97（几何 1280x1024 相符）`，且**没有自起新的** ✓（**复用能力没被砍掉**） |
| ③（附加） | `$DISPLAY_NUM=:99` 被几何不符者占着 | 跳过 ＋ **避开该号** | `skipped-geom-mismatch :99` ＋ `✅ X-REUSE=self-started display=:100` ✓（不制造"Xvfb 起不来"这种**新**假红） |

  装置留痕：`~/w126a/geomtest/`（`sec0.sh` = 真件 `:383–:456` 逐字；`bin/pgrep` = 只回放给定清单的 shim）；**三个测试 Xvfb 全部按 PID 收掉**，现场只剩 `:97`/`:185`（**都不是我的**）。
  记账：`docs/WAVE52-PREREGISTRATION.md` 追加 **§R1**（`834e370053f7ef2b` → `a5a97b0c0563bd02`，授权内、只追加）。
- **重跑结果**（第 2 趟）：`Windowing.Tests ✅ 44/44`、`用例通过 875`、**`结论：❌ 失败项：COLUMN-FLOOR`（恰好 1 处声明类红）** ⇒ 继续冻结。

### 8.2 宿主重启（"静默挂死"的真身）
- 我在 **09:32:06** 最后落盘，**09:58:21** 被主控按 `~/w126a/STATUS.md` 断点接回，中间 **≈26 min 无写入、无进程**。
- **现算证据**：`uptime -s` = **`2026-09-23 09:45:54`**（`/proc/uptime` = 1174 s，与 `uptime` 的 "up 19 min" 一致）。
  ⇒ **那不是 DSH 运行时挂死，是宿主重启**把我的所有进程与后台 watcher 杀了（这解释了"无进程、无日志"的表象）。
- **对读数的影响**：挂死窗口内**没有任何我在跑的测量** ⇒ **无作废趟**；步骤 ②–⑤ 的读数都是重启**之前**完成的，
  我在重启后**逐项复算**（`known-red.json d4e0080df6ec497c`／`inputs_fp 84fd55d3…`／`COLUMN_FLOOR_ARMLOG=FAIL bad= tline`／五臂五值）**全部一致**。
- **建议（给主控）**：W80A/W91A/W92A 那三笔"静默挂死"应**同法查 `uptime -s`**。

### 8.3 作废趟清单
| 趟 | 为什么作废 |
|---|---|
| 冻前 `verify-all` **第 1 趟** | **停条件命中**（非声明类红 `Windowing.Tests`）⇒ 不作冻结输入；**保留为证据**（`07-verify-all-pre.log`） |
| 我自造的 `Windowing.Tests` 单跑（私有 `:186`） | **一直等槽**（W128A 占着，`--wait 1800`）⇒ 结论被主控授权的"守卫＋重跑"**取代** ⇒ 我按 PID 杀掉自己的 `176229/176268/176230`，**不作读数**（`~/w126a/logs/diag-windowing-186.log` 保留为证） |
| 第 1 次冻结 | `COLUMN_FLOOR=NOINFO`（缺外挂声明行）⇒ 还原后重冻；**冻结件终值不含它** |

### 8.4 `NOINFO` / 未取到（逐条如实）
1. **握手第二判据（`w123a` 的"完成 `<批名>`"行）= 未取到**（STATUS 未更新）；已用"四本 `skip.batch.*` 全 0 字节 ＋ 卫生牙 `multilink=0 cross_region=0`"作替代证。
2. **`upstream/**`（6417 件）未测**（`NUL-BYTES` 步的 `NOINFO` 格）：该步 `PASS` **只等于「声明覆盖面里 0 件含 NUL」**。
3. **11 件无扩展名 ELF 只 `DIAG` 不判红**（`diag_noext_nonelf=0` ⇒ 本趟这 11 件**全是**真 ELF）。
4. **`UNEXPECTED=6[DECL-GAP-EQ=6]` 未逐条归因**（`#49` 已认定为**在册**声明类缺口；本件只确认"不因本波变多"）。
5. **`DEFREG_DECLDRIFT=1`（changed-route-files-since-DECL-GEN）**：`defect-registry-declared.tsv` 的 `DECL-GEN = 2026-09-23 09:02:37`，
   而 `docs/ROUTES.md` 在其后被别的车道改过 ⇒ 漂移标志立起。**但检查器 `rc=0`、`DEFREG=PASS declared=138 route_ids=138`**
   ⇒ `verify-all` 第 `[16]` 步是 ✅（**本件实测**）⇒ **不构成步红**。⇒ 主控曾**授权**我在"因 `DECLDRIFT` 出现第 2 处红"时跑
   `defect-registry-check.sh --emit` 重新对齐 —— **我判定不需要，故未执行**（该件本就在我的禁改清单里）。
   **主控要我机械核的那条我自己算了**：`build/MilBridge/tools/defect-registry-declared.tsv` **不在** `fp_inputs()` 覆盖面
   （我自己的 149 件清单里 `grep -c` = **0**）⇒ 即便将来重生成它，**也不会动 `inputs_fp`**。
6. **`pf` 不可复现的根因仍未抓到**（`D-G92`，`NOINFO`）：本波又添一条成对读数，但**真凶未明**；**要什么样的读数**：一个覆盖 PF **全部**编译输入的指纹。
7. **第 1 趟那条"1280x1024 下三例全过"的边界**：它**不能单独证明**那三例的产品语义没问题，只证明**它们不再因几何不符而红**。

### 8.5 纪律偏离／自伤（逐条）
- ⚠️ **探活者污染（自伤，已改）**：第一版探活用 `ps -eo cmd | grep -c 'w123a'` 得 `3`／`2` —— **把我自己的命令行数进去了**。⇒ 改用读 `/proc/*/cmdline` ＋排除自己进程树。
- ⚠️ **`w52-pre.sha` 第一版有两处错**（`dwf` 路径拼错 ＋ 切块锚一路吃到 `#18`）⇒ **生成脚本拒写/已修**，`PRE` 从未被写错。
- ⚠️ **`#52` 声明补丁第一版被自己的断言拦下（未落盘）**：`verify-all-step-check.sh:94` 用 `sed 's/.*gen=\([^ ]*\).*/\1/p'` —— `.*` **贪婪** ⇒ 抓该行**最后一个** `gen=`；
  我第一版 DECL 行为了自述又写了一遍 `gen=#52` ⇒ `gen_decl` 会变成垃圾串。⇒ 加断言「**DECL 行里 `gen=` 只许出现 1 次**」并把自述改掉。
- ⚠️ **冻结第 1 次自伤**（见 §6）⇒ 已从备份逐字节还原后重冻。
- ⚠️ **一次 `sleep 60` 的工具调用超时**（我自己的轮询写法问题，无副作用）。
- ✅ **零 `pkill -f`**：全部按 PID（含我杀掉自己的三个诊断进程）。**零 `ln`／硬链接**（我自己的实验一律 `cp -p`；臂日志里的 `ln -f` 是**仓内既定机制**，见 §2 步骤④）。
- ✅ **写域**：产品**源**／`docs/ROUTES.md`／`KNOWN-DEFECTS` 类册件／`defect-registry-declared.tsv`／`applier-audit-expected.txt`／既有牙／其他车道目录 **一字节未改**。

---

## §9 · ⑨ ≤8 行大白话小结

1. `#52` 已冻结为 **`27293fb5ab91b778`**，三颗声明牙全 PASS，冻前那 1 处红（`COLUMN-FLOOR`）已按设计转绿。
2. 产品只动了 `win32shim`（`D-G100` 卫生修，导出 547 不变）；`pf` 又自己变了一次 —— 那是 **`D-G92` 既知属性**，不是回归。
3. 中途**撞上任务书的停条件**（冻前第 1 趟多出一处非声明类红 `Windowing.Tests`），我**停手报主控**，查清是**闸门复用了别人的 1024x768 X**。
4. 按主控授权给闸门加了**几何守卫**（更严），并用三组极性证明它既会跳过错的、也没砍掉复用能力；重跑后 `Windowing` 44/44 复绿。
5. 我先前"`:185` 是重启孤儿"的判断**被推翻**（它是 W128A 的活批次）—— 已如实更正，且**没碰它**。
6. 我这趟**被宿主重启打断过**（`uptime -s` = 09:45:54）：那才是"静默挂死"的真身，建议同法复查 W80A/W91A/W92A。
7. 我自己犯的错都留痕了：探活者污染、`w52-pre.sha` 两处拼装错、声明行 `gen=` 贪婪陷阱、冻结缺外挂声明行（已还原重冻）。
8. 冻结器是**先写盘、后断言** —— 断言失败时盘上已是半成品，**重冻前必须先还原**（这条已写进冻结块，免得后人再踩）。

---

**报告自身口径**：不含本行 sha16 = `b81fb4a66fa80972`（**恰好一行** ⇒ `head -n -1 build/MilBridge/W126A-report.md | sha256sum` 复算应得同值；FULL sha256 由读者现场算／见收尾消息）
