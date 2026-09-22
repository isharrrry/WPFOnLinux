# W110A 报告 —— 波 `#51` 收尾链（`TASK-0108` 落地波）＋ `TASK-9907` 接线（新第 `[27]` 步 `NUL-BYTES`）

车道 = **W110A**｜`R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`｜fork 克隆 `~/netTest/GitProj/WPFOnLinux`
判据（先写）= `~/w110a/criteria.md`｜逐步台账 = `~/w110a/STATUS.md`｜冻结记录 = `~/w21-verify/w51-record.txt`

## 0 · 结论（结论在前）

1. **`TASK-9907` 接线落地**：`verify-all` **26 → 27 步**；四处声明同趟改；现场
   `VERIFYALL_SELF=PASS names=27 decl=27 gen=#51 dup=0 order=OK prose=OK prereg=PASS`（rc=0）；新步单独跑 `NULBYTES=PASS hits=0`（rc=0、秒级）。
   并把判据件 `nul-bytes-check.sh` **纳入 `fp_inputs()` 覆盖面**（设计性变更 ⇒ `inputs_fp` 必变，逐字写明）。
2. **收尾链 ①–⑩ 全部走完**（每步机读行见 §2）：整波 `rc=0`（失败步 0）｜WIC `STALE=0 DIVERGENT=0`｜五臂重取（**预测命中**：只有 `tline` 位变）｜重钉 `REPIN_GENERATION=PASS`｜
   门禁 **12/12 `result=PASS`**｜**冻前 `verify-all` 恰好 1 处红且它就是设计内的 `COLUMN-FLOOR`**｜冻结 `#51` = **`38e67e834430d75c`**｜**冻后 ×2 全绿 27/27**。
3. **`#51` 的位移 = `win32shim` ＋ `pf` 两位**（`TASK-0108` 的 `H2` 落地）；`pf` 在收尾链整波重建之后**又变了一次**（`215c856cbca9922b` → `bc2c47ac7b067bad`，**同尺寸 6,123,520 B**）—— `D-G92`（`pf` **不是构建身份**）的现场再证，**不算失败**，已逐字写进冻结块。

## 1 · ① `TASK-9907` 接线（四处逐字 ＋ 覆盖面 ＋ 边界句）

### 1.1 改了哪几件

| 件 | before → after sha16 | 说明 |
|---|---|---|
| `verify-all.sh` | `227623000850ca5d` → **`1aa2ae4e94827cf3`**（978 行，`bash -n` rc=0） | 四处声明 ＋ 第 `[27]` 步本体 |
| `build/close-wave.sh` | `f440ccdb4e29a942` → **`c757fd5058f1bfd4`**（421 行，`bash -n` rc=0） | `fp_inputs()` 名单纳入新判据件 |
| 备份 | `~/w110a/backup/{verify-all.sh,close-wave.sh}` | `cp -p` 真复制 |
| 补丁脚本 | `~/w110a/patch-step1.py` | 四个锚**唯一性断言**，任一不满足 ⇒ 拒写（`ANCHOR-FAIL`） |

### 1.2 四处逐字

（1）`DECL` **最上面**新插一行（旧 `26 gen=#50` 行**逐字保留**在下面 —— 读者 `decl_line()` 取第一条）：

```
# VERIFYALL-STEPS-DECL: 27 gen=#51   ← `#51` **加一步**（26 → 27）：第 `[27]` 步 `NUL-BYTES` —— `D-G82` 的牙（`TASK-9907`）：判「**被判二进制、本意是文本**的源件」，即**声明覆盖面**（扩展名白名单 ＋ 基名清单 ＋ 基名 glob，排除 `upstream/**` 与 `obj|bin|.artifacts|__pycache__|TestResults`）里**不许有真 NUL 字节**（现场 1186 件 / 250.8 MB，`hits=0`）。三态 `NULBYTES=PASS|FAIL|NOINFO` ＋ **内置金丝雀**（每次真跑先自证扫描器没瞎、偏移/行号算得对、声明被遵守）；**纯读、零 `dotnet`、≈0.4 s**；本步不改产品件 ⇒ 九位逐位不动。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改。**步数：26 → 27**）
```

（2）头注释**口径句**新段（判据 = `grep -qF '**`#51` 收官起 = 27 步**'` ⇒ 半句逐字；现场 `grep -cF` = 1）：

```
#   **`#51` 收官起 = 27 步**（**加一步**：第 `[27]` 步 `NUL-BYTES` —— `TASK-9907`／`D-G82`：
#     判据 = `build/MilBridge/tools/nul-bytes-check.sh`（声明覆盖面里不许有真 NUL 字节；
#     三态机读行 `NULBYTES=`；**内置金丝雀**每次真跑先自证）。**纯读、零 `dotnet`、≈0.4 s**、
#     不动九位。⚠️ 若同趟把它纳入 `fp_inputs()` 的 `printf` 名单，**必须安排在 `IN_FP_0` 采样之前**。
#     判据与逐例自测（31 例）见 `build/MilBridge/W97A-report.md`。）
#     ⚠️ **本步「绿」的边界（逐字写死，免得被读成「全仓 0 件」）**：本步的绿 = **声明覆盖面内 0 件含 NUL**，
#       **≠** 全仓 0 件；`upstream/**`（6417 件）未测 ⇒ 该格 **`NOINFO`**；11 件**无扩展名 ELF** 只 `DIAG` **不判红**。
```

（3）`VERIFYALL-STEP-NAMES` 第一行末追加 ` | NUL-BYTES`（末三名字现场读 = `THIRD-PARTY` / `R-GATE（连续交互）` / `NUL-BYTES`）。

（4）步骤本体插在 `[26] R-GATE` 的 `run_step` **之后**（现 `verify-all.sh:891`），口径句逐字含边界：

```
# ── 【`#51` W110A 落地：第 `[27]` 步 `NUL-BYTES` —— 「被判二进制、本意是文本」的源件牙（`D-G82`）】──
… （判据说明 7 行，见文件原文）
#   ⚠️ **「绿」的边界（逐字，与头注释口径句同款）**：本步的绿 = **声明覆盖面内 0 件含 NUL**，**≠** 全仓 0 件；
#     `upstream/**` 未测 ⇒ `NOINFO`；11 件**无扩展名 ELF**（首 NUL 恒在偏移 7）只 `DIAG`、**不判红**。
echo
echo "[27] 源卫生：声明覆盖面里不许有真 NUL 字节（D-G82 的牙；只读、零 dotnet、≈0.4 s；#51 加）"
run_step "NUL-BYTES" bash build/MilBridge/tools/nul-bytes-check.sh
```

### 1.3 现场机读（接线后、冻前）

```
$ grep -c '^run_step "' verify-all.sh
27
$ bash build/MilBridge/tools/verify-all-step-check.sh
VERIFYALL_SELF=PASS names=27 decl=27 gen=#51 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=1aa2ae4e94827cf3
  ∟ 步名多重集合 == 声明；声明自洽；口径句数字一致；无重名；次序一致
rc=0
$ bash build/MilBridge/tools/nul-bytes-check.sh          # 新步单独跑
NULBYTES=PASS files=1186 hits=0 bytes=250806426 skipdir_dirs=141 binext=280 otherext=0 noext=11 diag_noext_nonelf=0 diag_otherext_nul=0 canary=ok
rc=0
```

### 1.4 `build/close-wave.sh` 的 `fp_inputs()`（设计性变更，**逐字写明**）

在 `printf '%s\n'` 名单里、`build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh \` **之前**插一行：

```
          build/MilBridge/tools/nul-bytes-check.sh \
```

理由 = 仓内纪律「**判据改了自己得有人看着**」（`tline-gate.sh`／四件核对器／两件 R-GATE 判据件同族）。
⚠️ **代价**：这一改**必然**动 `inputs_fp`；流程上必须安排在 `IN_FP_0` 采样**之前**（本车道在收尾链**最前**做，满足）。

### 1.5 `inputs_fp` 新旧值（**任务书那个旧值与现场不符，如实记**）

| 时刻 | `inputs_fp` | 覆盖面件数 |
|---|---|---|
| 本车道**开工现场重算** | `82b3adf3cf52c66001bd6cdcf45af652eabef400ca2815f32e7a2e57bb9023d6` | 148 |
| 接线之后 | `873d6f21a51c55ae12def74b78501abec91ace3fa03cfa84ba1f68631de247bc` | 149 |
| 步骤⑤重钉之后（= **GENS `#51` 断言的终值**） | **`58a6c0945b7d535830ce3e3e4f25752b68f3714d3f35f540253eca6e69b3dd36`** | 149 |

⚠️ **任务书给的旧值 `21b720ea4ea56932…` 现场重算 ≠**。**机械归因**（覆盖面成员的 mtime，`stat -c %Y` 现算）：
`build/integration-wave.sh`（26 min 前）＋ `src/WpfGfx.Linux.Native/tools/patch-presentationframework-window-minmax-notify.py`（34 min）
＋ `src/WpfGfx.Linux.Native/src/{win32_core.c,win32_internal.h,win32_msg.c}`（36 min）——**五件全在覆盖面内**，全是**波内车道（`W101A`／`W106A`）的产品改动**。
⇒ 任务书那个数是**更早一刻**的值；**以现场为准**，**不是事故**（`inputs_fp` 的波前/波后一致性由整波脚本自己核：`9a265c5a2f9e7c4c…` 两读一致）。
`FP_INPUTS_HYGIENE=PASS reason=clean coverage_n=149 artifact_n=0`（rc=0，覆盖面里零产物）。

## 2 · ②–⑩ 逐步读数（每条含 `HEAVYSLOT=` 行与耗时）

| 步 | 命令 | `HEAVYSLOT` | 关键机读行 |
|---|---|---|---|
| ① 接线 | 见 §1 | ——（纯文本编辑，不占槽） | `VERIFYALL_SELF=PASS names=27 decl=27 gen=#51`；`NULBYTES=PASS hits=0` |
| ② 整波重建 | `WAVE_OWNER=W110A bash build/integration-wave.sh` | `MEMOK avail=2459MB`／**`RELEASED rc=0 held=177s max_hold=1200s`** | `APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0`；`失败步骤 0`；波前=波后 `9a265c5a…` |
| ②b native | `bash src/WpfGfx.Linux.Native/build-shim.sh --all` | `RELEASED rc=0 held=2s max_hold=600s` | 导出符号 **547**；`win32shim` **仍 `8392fc09564779a1`** ✓ |
| ③ WIC 同步 | `SCAN_ROOTS=…:tools bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh --apply` ＋ `check-applocal-sync.sh` | ——（纯读，秒级） | `APPSYNC-REFRESH=refreshed=0 newer=0 applied=1`；`MISMATCH=0（STALE=0 NEWER-DIFF=0）… DIVERGENT=0` ⇒ **`STALE=0 DIVERGENT=0`** |
| ④ 五臂重取 | `ARMS_OUT=$HOME/w110a/arms bash build/MilBridge/tools/retake-arms-w23.sh` | `MEMOK avail=2223MB`／**`RELEASED rc=0 held=318s max_hold=1200s`** | `tline 6ce993ad… → 9d29470d63791d64`；其余四臂逐位未变；判词与 `#50` 逐字相同 |
| ⑤ 重钉 | `python3 build/MilBridge/tools/repin-generation.py --why '…'` | —— | 前 `FAIL n=2` → **`REPIN_GENERATION=PASS`**；`known-red.json 8a0c0f221e35f42b → 089b7324ba12e022` |
| ⑥ 门禁 ×2 | `WPTD_RUN_DIR=… WPTD_BASELINE_OUT=… run-wpftextdemo.sh 60 --tier both`（第 2 趟 `--no-build`） | `MEMOK 2397MB`／`RELEASED rc=0 held=167s`；`MEMOK 2477MB`／`RELEASED rc=0 held=158s`（授权 300） | 两趟各 **6/6 `result=PASS`**、`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`；rows `e97f301863ca58a9`／`808a2ba7c3cd9f33` |
| ⑦ 冻前 `verify-all` | `bash verify-all.sh`（27 步） | `MEMOK`／**`RELEASED rc=1 held=862s max_hold=1500s`**（授权 1500：`#49`/`#50` 实测 ≈16.3 min） | **`步骤通过 26 ❌ 失败 1`**、`用例通过 875 跳过 2`、`结论：❌ 失败项：COLUMN-FLOOR` ⇒ **唯一红 = 设计内声明类** |
| ⑧ 冻结 | `python3 ~/w21-verify/w27-freeze.py <冻前日志> <rows> '#51'` | —— | **`基线已重冻为 #51；整份 sha16 = 38e67e834430d75c`**；三牙 `BASELINESHA/BASELINEGEN/BASELINEDUP` 全 PASS；`ARMLOG_SHA=PASS 5/5`；`COLUMN_FLOOR=PASS` |
| ⑨ 冻后 ×2 | `bash verify-all.sh` ×2 | 见 §6 | 两趟 **27/27 全绿** |
| ⑩ 记录/推送/app-local | 见 §7 | —— | `BYTECHECK ok=20 mismatch=0 nobody=0`；head `f933e31 → c51a706 → 47db9c2 → d1a58e4`；`STALE=0 DIVERGENT=0` |

### 2.1 步骤④的**预测先写**（`~/w110a/criteria.md` C4，取读数**之前**登记）

> 本波只动 `win32shim`／`pf` 两位 ⇒ 预测 `tline` 位**可能**变（运行相关字段），其余四臂**逐位不变**，五臂**判词**与 `#50` 逐字相同。

**读数命中预测**：只有 `tline` 变（`6ce993ad974d32ad` → `9d29470d63791d64`）；判词逐字相同（`tline` 通过 22/失败 2｜`tab-zero` 退出码=1 且在册红不变｜`tab-anchor` 退出码=0 `START 绿=615`／`OVERFLOWED 绿=421`｜`tab-rtl` 退出码=0｜`textlineproto` 通过 10/失败 0）。

### 2.2 步骤⑦ 那 1 处红的**逐字**（`D-G27` 族的声明类红，**设计如此**）

```
  COLUMN-FLOOR                 ❌  (rc=1)
      COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline
      COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0 selfreport=PASS reg=089b7324ba12e022 base=1f4189c1257737a9 corpus=0cebc0afd5142fbf
 步骤通过 26  ❌ 失败 1
 用例通过 875  跳过 2
 SKIP_GUARD=PASS x_state=available x_died=0 x_suite_skipped=0 x_suite_units=0 x_suite_corpus_max=0 total_skipped=2 violations=none reason=none
 结论：❌ 失败项：COLUMN-FLOOR
```

**冻结块还是 `#50` 的 `tline 6ce993ad974d32ad`，而臂已重取为 `9d29470d63791d64`** ⇒ 冻后同一批检查器**必须转绿**（现场已转绿，见 §6）。
⚠️ **唯一性判定**：`nfail=1` **且**失败项名单**恰好** `COLUMN-FLOOR` ⇒ **无第 2 处非声明类红** ⇒ 按纪律**无需停手**（`D-G87` 反例未触发）。
第 `[27]` 步 `NUL-BYTES` 在同一趟里 **✅**：`NULBYTES=PASS files=1187 hits=0 bytes=250817074 skipdir_dirs=141 binext=280 otherext=0 noext=11 diag_noext_nonelf=0 diag_otherext_nul=0 canary=ok`。
（`files=1186 → 1187` 的差 = 本趟现场多出来的 1 件，属覆盖面自然增长；判据是 `hits=0`，不是件数。）

## 3 · ③ 冻结块要点（**逐字写入的记录件**）

记录件 = `~/w21-verify/w51-record.txt`（三段 `===BANNER===`／`===FROZEN===`／`===RECORD===`）⇒ 由冻结器把它与 `gate-rows.txt` 拼成新的 `ACCEPTANCE-BASELINE.md` 首部。

**成对九位（主控要求必写）**

| 位 | 冻前刻（= 冻结块那一栏，现场现算） | 冻后刻（冻后两趟之后复算） |
|---|---|---|
| `bridge` | `feef049e9d0e313a` | 见 §6 |
| `pc` | `722e0ab8205b7c3f` | 见 §6 |
| `pf` | `bc2c47ac7b067bad` | 见 §6 |
| `windowsbase` | `2e4e46e539a72cd7` | 见 §6 |
| `provider` | `1f9511a7ef395bfe` | 见 §6 |
| `win32shim` | `8392fc09564779a1` | 见 §6 |
| `wic_shim` | `f7b3026c8c019be2` | 见 §6 |
| `hbtextline` | `921ba9c65e9fb3be` | 见 §6 |
| `dwf` | `ce3469f49efcbcfa` | 见 §6 |

⚠️ **冻后刻的读数不可能落在冻结块内**（冻结块与 `docs/CURRENT-STATE.md:9` 同趟写盘、必须逐字自洽，冻后不许再改）⇒ 后半并列在 §6 与 `~/w110a/STATUS.md`。
**判据先写死**（`criteria.md` C8-c）：预测 = 冻后刻与冻前刻**逐位相同**；任一位不同 ⇒ 逐位并列并点名；**`pf` 不同不算失败**（`D-G92`）。

`pf` 的既知属性**逐字写进冻结块**（照 `#50` 先例），并追加**本波新的一条成对读数**：
本车道开工时 `pf=215c856cbca9922b`，跑完整波重建后 `pf=bc2c47ac7b067bad`（**同尺寸 6,123,520 B**，`ARTIFACT_SRC_FP proj=PresentationFramework fp=01a078bf78c6ed18 n=1363 peer_fp=0e31c2dc0c4e31c4 peer_n=9 state=written`）。

## 4 · ④ `fp_inputs`／世代件

- `BRIDGE_SRC_FP = 0a8f69b3c5fabd43`（两侧同值：现树 == 发布记录；门禁自报 `WPTD_BRIDGE_SRC_STALE=no basis=pub=0a8f69b3c5fabd43 now=0a8f69b3c5fabd43 so_file_match=yes`）⇒ 桥身份自检会过。
- `PRE` 快照 `~/w51-pre.sha`（9 行、**键=相对路径**）：**不是**开工前活取的 —— 本波两处位移在我开工**之前**就由波内车道落定 ⇒ 按 **`#50` 冻结块**九位**逐位重建**（生成脚本机械核过「每个值都逐字出现在 `#50` 冻结块里」）⇒ 冻结器算出的 `changed` = 本波相对 `#50` 的位移本身。
  🩸**自伤 1（已改正）**：首版 PRE 用了**绝对路径**键 ⇒ 冻结器 `开工前快照 … 缺这些路径` 拒绝（`assert` 在**任何写盘之前**，无副作用）⇒ 改成相对路径后通过。
- GENS 表**只追加** `'#51'`（不改编老代；备份 `~/w110a/backup/w27-freeze.py.before-gen51`），追加脚本 `~/w110a/add-gen51.py`。

## 5 · ⑤ 冻结块的三颗声明牙 ＋ `BASELINEDUP`

```
基线已重冻为 #51；整份 sha16 = 38e67e834430d75c
BASELINESHA=PASS live=38e67e834430d75c decl=38e67e834430d75c
BASELINEGEN=PASS decl_gen=#51 file_newest_gen=#51
BASELINE_BYTES=668062
BASELINEDUP=PASS n=0
✅ 机器行 gen=#51 sha16=38e67e834430d75c 已对上，核对器 rc=0
ARMLOG_SHA=PASS shape=flat logdir=…/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0
COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=089b7324ba12e022 base=38e67e834430d75c corpus=0cebc0afd5142fbf
✅ 两极化齐：冻前 BASELINE-SHA/ARM-LOG-SHA/COLUMN-FLOOR(ARMLOG) 红 ⇒ 冻后同一批检查器都绿
```

`docs/CURRENT-STATE.md:9`（同趟改，**只此一处机器声明**）：

```
> BASELINE-FROZEN gen=#51 sha16=38e67e834430d75c file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
```

🩸**自伤 2（已改正）**：第 1 次冻结把 8 行外挂声明行（`COLUMN-FLOOR`／`COLUMN-CORPUS`／`ARM-LOG-SHA`）写成**没有 `# ` 前缀** ⇒ 读者（`column-floor-check.sh` 用 `grep -E '^# COLUMN-FLOOR '`）判 `COLUMN_FLOOR=NOINFO reason=frozen-block-has-no-COLUMN-FLOOR-line`，而冻结器的 `assert` 在**写盘之后** ⇒ 基线曾被写成 `d1f66f944cdf1c39`。
处置：**从备份逐字节还原** `ACCEPTANCE-BASELINE.md`（`1f4189c1257737a9`，与 `#50` 冻结值逐位相同）＋ `docs/CURRENT-STATE.md`（`1ff381a9be8c3c7a`），修记录件后**重冻** ⇒ 终值 `38e67e834430d75c`（`BASELINE_BYTES=668062`）。
**判据未动、未放宽**；两极化照旧成立。

## 6 · ⑥ 冻后 `verify-all` ×2（27/27 全绿）

| 趟 | 日志 | `HEAVYSLOT` | `步骤通过/失败` | `用例通过/跳过` | 结论 |
|---|---|---|---|---|---|
| 第 1 趟 | `~/w110a/logs/09-verify-all-post1.log` | `MEMOK`／**`RELEASED rc=0 held=888s max_hold=1500s`** | **27 / 0** | 875 / 2 | **`结论：✅ 全部通过`** |
| 第 2 趟 | `~/w110a/logs/09b-verify-all-post2.log` | `MEMOK`／**`RELEASED rc=0 held=887s max_hold=1500s`** | **27 / 0** | 875 / 2 | **`结论：✅ 全部通过`** |

**关键机读行两趟逐字比对**（`diff` 口径：逐行取值后字符串比较；现场脚本见 §2 表下方命令）：

| 字段 | 两趟 | 值 |
|---|---|---|
| `步骤通过 / 失败` | **IDENTICAL** | `27 / 0` |
| `用例通过 / 跳过` | **IDENTICAL** | `875 / 2` |
| `SKIP_GUARD` | **IDENTICAL** | `PASS x_state=available … violations=none` |
| `BASELINESHA` | **IDENTICAL** | `PASS live=38e67e834430d75c decl=38e67e834430d75c` |
| `BASELINEGEN` | **IDENTICAL** | `PASS decl_gen=#51 file_newest_gen=#51` |
| `BASELINEDUP` | **IDENTICAL** | **`PASS n=0`** |
| `ARMLOG_SHA` | **IDENTICAL** | `PASS required=5 declared=5 pass=5 fail=0 noinfo=0` |
| `COLUMN_FLOOR` | **IDENTICAL** | **`PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 selfreport=PASS reg=089b7324ba12e022 base=38e67e834430d75c`**（**冻前那 1 处红已转绿**） |
| `VERIFYALL_SELF` | **IDENTICAL** | `PASS names=27 decl=27 gen=#51 dup=0 order=OK prose=OK prereg=PASS` |
| `NULBYTES` | **IDENTICAL** | **`PASS files=1188 hits=0 bytes=250859711 canary=ok`** |
| `FP_INPUTS_HYGIENE` | **IDENTICAL** | `PASS reason=clean coverage_n=149 artifact_n=0` |
| `R_GATE` | **1 处不同** | `crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 win=938x938 win32shim=8392fc09564779a1 pc=722e0ab8205b7c3f` **逐字相同**；唯一差异 = **`mem_mb=2373` vs `mem_mb=2409`**（**运行期内存读数**，不是判词） |

⇒ **判词层两趟逐字相同**；唯一不同的那一格是**运行期内存读数**，**如实记**（不是判据）。

**成对九位（冻后刻，两趟之后复算；命令 `bash ~/w95a/nine.sh`）**：

| 位 | 冻前刻 | 冻后刻 | 一致? |
|---|---|---|---|
| `bridge` | `feef049e9d0e313a` | `feef049e9d0e313a` | ✔ |
| `pc` | `722e0ab8205b7c3f` | `722e0ab8205b7c3f` | ✔ |
| `pf` | `bc2c47ac7b067bad` | `bc2c47ac7b067bad` | ✔ |
| `windowsbase` | `2e4e46e539a72cd7` | `2e4e46e539a72cd7` | ✔ |
| `provider` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | ✔ |
| `win32shim` | `8392fc09564779a1` | `8392fc09564779a1` | ✔ |
| `wic_shim` | `f7b3026c8c019be2` | `f7b3026c8c019be2` | ✔ |
| `hbtextline` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | ✔ |
| `dwf` | `ce3469f49efcbcfa` | `ce3469f49efcbcfa` | ✔ |

⇒ **预测命中：九位逐位相同**（含 `pf` —— 冻后两趟只做增量构建，未重编 PF）。冻结件 `ACCEPTANCE-BASELINE.md` 在两趟之后仍是 **`38e67e834430d75c`**（未被任何一趟改写）；`inputs_fp` 仍是 `58a6c094…`。

## 7 · ⑦ 记录 ＋ 推送 ＋ app-local

### 7.1 记录件

`~/w21-verify/w51-record.txt`（三段 `===BANNER===`／`===FROZEN===`／`===RECORD===`，口径照 `w50-record.txt`）——**它已被冻结器写入 `ACCEPTANCE-BASELINE.md` 的首部**；冻结**之后**该文件**只在末尾追加一段「冻后补记」**（明确标注**不在冻结块内**）。

### 7.2 推送（第 1 笔）

```
推前 head   = f933e314749ae6fb11bf12c4759c277beaa70c7f   （== origin/feat-Linux）
fetch       : git fetch origin feat-Linux:refs/remotes/origin/feat-Linux   （refspec 陷阱已避）
commit      = c51a7069898132931d6308200eb2cfc2e470da64  （20 件；逐径 git add，**未用 -A／--force**）
push        : git push origin feat-Linux   ⇒  f933e31..c51a706  feat-Linux -> feat-Linux
核对（**push 之后重新 fetch**）:
  HEAD(local)     = c51a7069898132931d6308200eb2cfc2e470da64
  remote-tracking = c51a7069898132931d6308200eb2cfc2e470da64
  ls-remote HEAD  = c51a7069898132931d6308200eb2cfc2e470da64   ⇒ **三者一致 ✔**
  ls-remote --symref origin HEAD ⇒ `ref: refs/heads/feat-Linux  HEAD` ✔
staged 清单（`git status --porcelain`，无夹带）:
  A build/MilBridge/W101A-report.md ｜ A build/MilBridge/W105A-report.md ｜ A build/MilBridge/W110A-report.md
  A build/MilBridge/gen/tline-ledger-lines-20260922-2041.txt
  M build/MilBridge/arm-logs/tline.log ｜ M build/MilBridge/gen/t2d-family-{baseline,matrix}.txt ｜ M build/MilBridge/known-red.json
  M build/MilBridge/tools/applier-audit-expected.txt ｜ M build/PresentationFramework.Linux/ARTIFACT-SRC-FP.txt
  M build/PresentationFramework.Linux/PresentationFramework.Linux.csproj ｜ M build/close-wave.sh ｜ M build/integration-wave.sh
  M build/wave-audit.log ｜ M docs/CURRENT-STATE.md ｜ M samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
  M src/WpfGfx.Linux.Native/src/win32_{core.c,internal.h,msg.c} ｜ M verify-all.sh
```

### 7.3 `BYTECHECK`（**rev = push 之后重新 fetch ＋ `ls-remote` 交叉核**，计数器在主 shell 累加、未用 `tee`）

```
rev = c51a7069898132931d6308200eb2cfc2e470da64 ／ ls-remote = 同值 ⇒ rev-xcheck 一致 ✔
ok  build/MilBridge/arm-logs/tline.log                        (disk=9d29470d63791d64)
ok  build/MilBridge/gen/t2d-family-baseline.txt               (disk=d02dc5feb191f8e8)
ok  build/MilBridge/gen/t2d-family-matrix.txt                 (disk=4fcd3b23d8d288ae)
ok  build/MilBridge/known-red.json                            (disk=089b7324ba12e022)
ok  build/MilBridge/tools/applier-audit-expected.txt          (disk=0f9e718352f183a5)
ok  build/PresentationFramework.Linux/ARTIFACT-SRC-FP.txt     (disk=f605fccc9b574c4f)
ok  build/PresentationFramework.Linux/PresentationFramework.Linux.csproj (disk=e22a7457dc4a8010)
ok  build/close-wave.sh                                       (disk=c757fd5058f1bfd4)
ok  build/integration-wave.sh                                 (disk=4d19d69c93ba5927)
ok  build/wave-audit.log                                      (disk=ac3722da2e1fac5f)
ok  docs/CURRENT-STATE.md                                     (disk=b7b2d513cfdab2eb)
ok  samples/WpfTextDemo/ACCEPTANCE-BASELINE.md                (disk=38e67e834430d75c)
ok  src/WpfGfx.Linux.Native/src/win32_core.c                  (disk=e0cbc965772d06c1)
ok  src/WpfGfx.Linux.Native/src/win32_internal.h              (disk=e4f2de8d038e4780)
ok  src/WpfGfx.Linux.Native/src/win32_msg.c                   (disk=4ad790f4c26a907c)
ok  verify-all.sh                                             (disk=1aa2ae4e94827cf3)
ok  build/MilBridge/W101A-report.md                           (disk=bbd262c6d749fc1b)
ok  build/MilBridge/W105A-report.md                           (disk=cd906e8135f2406b)
ok  build/MilBridge/W110A-report.md                           (disk=f01a71faa3c59590)
ok  build/MilBridge/gen/tline-ledger-lines-20260922-2041.txt   (disk=81880ac3d10638a4)
BYTECHECK ok=20 mismatch=0 nobody=0
```

### 7.4 ⚠️ **刻意不推**的件（逐件点名 ＋ 理由；请主控裁）

| 件 | 大小（B） | 为什么没推 |
|---|---|---|
| `build/.applocal-selftest.log` | 10,666 | **运行日志**（app-local 校验器自测输出），不构成波产物 |
| `build/MilBridge/gen/tline-ledger-lines-20260921-1224.txt` 等 **5 件**（`-1231`／`-1540`／`-1623`／`-1629`） | 957／957／958／958／958 | **`#48`–`#50` 遗留**的臂账本（不是本波产物）；本波那一件已推 |
| `build/MilBridge/src/MilBridge.Resolver/README-合并写.txt` | 1,667 | 与 `#51` 无关的散件（来源未清） |

⚠️ 这三类**都不在** `fp_inputs()` 覆盖面内，也不参与任何判据 ⇒ 不推**不影响** `#51` 的冻结语义。

### 7.5 app-local 刷新（**必须显式补根**，`D-G91`）

```
AUTH_ROOT=$R SCAN_ROOTS=$R/build:$R/tests:$R/samples:$R/src:$R/tools \
  bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh --apply
  ⇒ APPSYNC-REFRESH=refreshed=0 newer=0 applied=1      （没有落单者 ⇒ 真写 0 件）
  … check-applocal-sync.sh
  ⇒ 计数：OK=200  MISMATCH=0（STALE=0  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0]  DIVERGENT=0
    CROSS-CONFIG=101  LIB-COPY=23  SKIP(obj)=14 SKIP(stub)=20 SKIP(ref)=12  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0
  ⇒ **STALE=0  DIVERGENT=0** ✔（`rc=1` 由 `UNEXPECTED=6` 决定 —— 那是**在册**声明类缺口，**不当绿、不改判据**）
```
⚠️ 若按脚本**默认** `SCAN_ROOTS`（`build:tests:samples:src`，**漏 `tools`**）跑，它会给 `STALE=0` 的**假绿**（`D-G91`）⇒ 本车道**显式补根**后取值。
桥副本 4/4 与发布记录一致（`BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`）。

### 7.6 第二笔推送（**本报告本体**）

```
推前 head = c51a7069898132931d6308200eb2cfc2e470da64
commit    = 47db9c26e1632f9b019155f94ca78d1b7aad276d   （1 件：build/MilBridge/W110A-report.md）
push      : c51a706..47db9c2  feat-Linux -> feat-Linux
核对      : HEAD(local) == remote-tracking == ls-remote ⇒ 三者一致 ✔ ；--symref 仍 `feat-Linux` ✔
逐件核对  : git cat-file blob 47db9c2:build/MilBridge/W110A-report.md | cmp - 磁盘 ⇒ ok（该 rev 上本报告 sha16 = 1db430dc1abe6c20）
```

⚠️ **本报告的自指口径（免得后人算错）**：上面那笔 commit 里的就是本报告的 **v2**。本节这行记账本身又坐一笔（v3）⇒ **报告里写不出自己所在 commit 的 hash**（写了就永远滞后一笔、且改一次 hash 变一次）。
⇒ **最终 head 记在 `~/w110a/STATUS.md` 与交件消息里**，不在本件内（同 `#50` 的「冻后刻九位不可能落在冻结块内」是同一条道理）。

## 8 · ⑧ 作废趟／`NOINFO`／纪律偏离

- **作废趟：0**（无 `HEAVYSLOT=NOINFO reason=low-memory`、无 `MAXHOLD_KILL`；每趟都拿到 `MEMOK`）。
- **`NOINFO`**：① `pf` 不可复现根因（`D-G92`，本波又得一条成对读数，真凶仍未抓）；② `NUL-BYTES` 的 `upstream/**` 未测格（6417 件）⇒ 本步 `PASS` **只等于「声明覆盖面内 0 件含 NUL」**；③ `UNEXPECTED=6[DECL-GAP-EQ=6]`（在册缺口，不当绿、不改判据）；④ 11 件无扩展名 ELF 只 `DIAG`（本波 `diag_noext_nonelf=0` ⇒ 这 11 件全是真 ELF）。
- **纪律偏离**：无（三条长步的 `--max-hold` 放宽均在任务书授权内，且逐条写了理由；`--min-avail 1500` 未动；零 `pkill -f`）。
- **写域**：产品源／`docs/ROUTES.md`／`KNOWN-DEFECTS.md`／`defect-registry-declared.tsv`／`applier-audit-expected.txt`／`r-gate-step.sh`／`nul-bytes-check.sh`／`wm-awaited.sh`／`~/w105a/**`／`~/w109a/**` **一字节未改**。

## 9 · ⑨ ≤8 行大白话小结

1. `TASK-9907` 接线做完了：`verify-all` 从 26 步变 27 步，新第 `[27]` 步是「源件里不许有 NUL 字节」的牙，四处声明同趟改对，机器自检 PASS。
2. 那条牙的判据件也进了「输入指纹」的覆盖面（判据改了自己得有人看着）⇒ 指纹必变，已逐字说明。
3. 收尾链十步一步没落：整波重建绿、WIC 同步零漂、五臂重取**预测命中**、重钉 PASS、门禁两趟 12/12 绿。
4. 冻前那一趟 `verify-all` **只红 1 处**，就是设计内的 `COLUMN-FLOOR`（臂日志声明还没跟上重取），没有第二处红。
5. `#51` 已冻结：基线整份 `38e67e834430d75c`，三颗声明牙全 PASS，机器行只剩一处声明。
6. 本波只动两位 `win32shim`／`pf`；`pf` 在整波后又自己变了一次（同尺寸），这是已知的「`pf` 不是构建身份」，不算失败。
7. 我自伤两处都留了痕并改正：`PRE` 键口径用错（拒绝在任何写盘之前）、冻结块声明行漏 `# ` 前缀（从备份逐字节还原后重冻）。
8. 没能做到的：`pf` 不可复现的真凶仍未抓到（`NOINFO`）。
