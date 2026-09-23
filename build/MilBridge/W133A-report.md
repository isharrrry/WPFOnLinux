# W133A —— 波 `#53` 收尾链台账

**车道** W133A（**收尾链唯一执行者**）｜**任务** = 整波重建 → 五臂重取 → 重钉世代 → 门禁 ×2 →
冻前 `verify-all` → **冻结 `#53`** → 冻后 `verify-all` ×2 → 收尾记录 → **逐径推送** → app-local
｜仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**不是 git 仓库**）
｜模板 = `~/w126a/STATUS.md` ①–⑩ ＋ `build/MilBridge/W126A-report.md`（`#52` 已成功走通一次，含全部坑）

---

## ① 判据（**先写后跑**）

- 全文：`$HOME/w133a/criteria.md`｜**写定时刻 = `2026-09-23 12:0x +0800`**（早于本波**任何**重活读数）
  ｜`sha256` = `028dd2d54ab9d3d184391289d52a78d815f136c985cf88db602540f274fe0436`（16 位 = **`028dd2d54ab9d3d1`**）。
- 写定后**一次收紧**（逐字声明，**收紧 ＝ 不许放宽**）：`GENS['#53']['infp']` 从先记的 `None`
  收紧为**重钉后现算的精确值** `5ac1e5349c7d1dec56fd7d8fe5dd8e9c1cb7c3b4052859f887e45c539981904f`
  （`$HOME/w21-verify/w27-freeze.py` `32e32fab1055b1e0` → **`5acac47065f6a7aa`**）。
- **两件"写域之外、收尾链机械必需"的件**（**先公告后落**；主控 **2026-09-23 12:1x 逐条批准**）：
  - (a) `verify-all.sh` 四处声明同趟改 `gen=#52` → `gen=#53`（**DECL 顶行 ＋ 头注释口径句各加一行；
    步名/步数一字不动，仍 27 步**）：**`0cdd12547a634b37` → `32ddbe487235cc38`**（`bash -n` rc=0；
    `VERIFYALL_SELF=PASS names=27 decl=27 gen=#53 dup=0 order=OK prose=OK prereg=PASS`）。
    **该件不在 `fp_inputs()` 覆盖面内** ⇒ **不动 `inputs_fp`**（改前/改后两次现算**同值**，见 §② (2)）。
  - (b) **新建** `docs/WAVE53-PREREGISTRATION.md`（**`b5ecd5433a57af47`**，5,922 B）：`docs/` 里此前**只有 `WAVE50/51/52`**。
    缺它 ⇒ 第 `[14]` 步 `VERIFYALL-SELF` = `NOINFO reason=prereg-absent`（`rc=2`，**缺声明 ≠ 通过**）
    ⇒ 该步变红 ⇒ **`#53` 冻不了**。件里逐字写明"**由 W133A 在收尾链中补建（主控授权）**"＋
    "**判据先写于 `$HOME/w131a/criteria.md`**（`2026-09-23 10:56 CST`，sha256
    `045477a20ac256df1bf7edcd3d2e75d7f1b88c252843738d57a37476abadd3dc`），**本件不发明新判据**"；
    标题行 = ``# 波 `#53` —— 预登记（`TASK-0109`：…）`` ⇒ 命中 `grep -qE "^#+ .*#53"`。

### ⚠️ 一条**依据更正**（如实记，不掩饰）

主控 12:1x 把「冻结器 `w27-freeze.py:454` 的断言」标成 `NOINFO（不可核）`，依据是
「`find $R -name '*freeze*.py'` ⇒ **0 命中**」。**那条搜索只覆盖了 `$R`**：**冻结器历来不在仓内** ——
它的实在位置 = **`$HOME/w21-verify/w27-freeze.py`**（`sha16 101db5306e1669fe`；`#50`–`#52` 历代同此，
`~/w21-verify/` 里还留着 `w23`–`w52` 各代的 `record.txt` 与 `freeze-*.py`）。
我**现场读过** `:454`：

```python
assert re.search(r'\*\*`' + re.escape(gen) + r'` 收官起 = ' + str(nstep) + r' 步\*\*', vh), \
    f'`verify-all.sh` 头注释里找不到「**`{gen}` 收官起 = {nstep} 步**」这句话 —— 头注释与现实分叉了'
```

⇒ 该依据按**已核**记（并在 `===FROZEN===` 的 BANNER 里逐字说明口径差）；主控另两条依据
（口径句与 DECL 一致、`#52` 的实际形态 = 同趟加两行）与本车道一致，是本次改动的直接依据。

---

## ② 整波 / 重取 / 重钉 —— 逐件 before → after

### (1) native 复现（判据 C2）＋ 整波重建

槽（**一趟槽内先复现、再走波**）：`HEAVYSLOT=ACQUIRED waited=1020s`（**排队 17 min**；
`W124A` 的 29 腿批与 `W128A` 的 `K5 100 25 :185` 链占着槽 ⇒ **我排队、不绕槽**）
｜`MEMOK avail=5895MB`｜**`RELEASED rc=0 held=160 s`**（`max_hold=1500`）。

- **C2**：`bash src/WpfGfx.Linux.Native/build-shim.sh --all` ⇒ 产物 `bin/libwpfwin32.so`（**327,512 B**）
  **重建前后 sha16 都是 `a6365183fa6d26b9`** ⇒ **逐字节复现**（"路径无关"断言**未破**）；
  **`== 导出符号总数：547`（不变）**；ABI 段 `结果：全部一致（编译期 _Static_assert 亦已通过）`。
  ⚠️ 一条**既有**告警如实记：`src/win32_misc.c:224 -Wmisleading-indentation`（`GetDpiForMonitor`），
  **不是**本波落点 ⇒ **未处置、只报**。
- **整波重建**：`WAVE_OWNER=W133A bash build/close-wave.sh --skip-verify-all`
  ⇒ `OUT=/home/links-dev/wfp-runs/close-wave-122558`｜`▶ 波责任人：W133A`
  ｜`[1/6] integration-wave.sh` **`rc=0`**｜**`APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0`**
  ｜**`=== 集成波结束：失败步骤 0 ===`**（逐工程 `0 个错误 0 个警告`）。
  - 波自身输入稳定性：`波前指纹 6781997d55260e95…` ＝ `波后指纹` **逐位相同**（⚠️ 口径 = `wave_fp()`，
    **盯 `build/shims/**`／应用器／`src/**` 的手写输入**，**不是 `fp_inputs()`**，两值**不可互比**）。
  - `[2/6]` native `跳过重建`（我刚重建过）｜`[3/6]` 桥 `源指纹一致（0a8f69b3c5fabd43 == 0a8f69b3c5fabd43）⇒ 无需重发`。
  - `[4/6]` 身份自检：桥源指纹两侧一致 ✓｜生成物指纹 `state=ok`（PC/WB/PF）✓｜**应用器审计 `miss=0`** ✓
    ｜**`输入稳定性：波前==波后 == f0e2b3e8c058cdf017031360a2cc292ffd6ab7b91b4a8ae47c100c3877522bd7`（期间无手写改动）** ✓
  - `[5/6]` **按要求跳过**（`--skip-verify-all`：冻前 `verify-all` **另起一趟**跑，不白跑 15 min）。
  - `[6/6]` **哨兵同步**（见 §⑨）。

### (2) 逐件 before → after（**九位**，波前 → 波后 → 冻结刻）

| 位 | `#52` 冻结点（= `w53-pre.sha`） | 波后 | 冻结刻 | 变? |
|---|---|---|---|---|
| `bridge` | `feef049e9d0e313a` | `feef049e9d0e313a` | `feef049e9d0e313a` | **未变** |
| `pc` | `722e0ab8205b7c3f` | `722e0ab8205b7c3f` | `722e0ab8205b7c3f` | **未变** |
| **`pf`** | `358136b0c806ee88` | **`4973bcb28e331cf0`** | `4973bcb28e331cf0` | **变**（同尺寸 **6,123,520 B**） |
| `windowsbase` | `2e4e46e539a72cd7` | `2e4e46e539a72cd7` | `2e4e46e539a72cd7` | **未变** |
| `provider` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | **未变** |
| **`win32shim`** | `bd037229be8db4f6` | **`a6365183fa6d26b9`** | `a6365183fa6d26b9` | **变**（= `TASK-0109`；327,512 B） |
| `wic_shim` | `f7b3026c8c019be2` | `f7b3026c8c019be2` | `f7b3026c8c019be2` | **未变** |
| `hbtextline` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | **未变**（293,165 B） |
| `dwf` | `ce3469f49efcbcfa` | `ce3469f49efcbcfa` | `ce3469f49efcbcfa` | **未变** |

⇒ **`changed = {win32shim, pf}`**，**逐字命中判据 C1 的允许集合**。波内 `REFRESH` 行逐字为证：
`build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/PresentationFramework.dll 358136b0c806ee88 → 4973bcb28e331cf0（权威 4973bcb28e331cf0；副本曾早 11254 秒）`。

🔴 **`pf` 不是构建身份（`D-G92`）—— 第四次连续现场再证**（`#50`/`#51`/`#52`/`#53`）：同源、同命令的两次重建
给出**不同字节**（本次 **同尺寸** 6,123,520 B）。**根因仍 `NOINFO`**（见 §⑩）。

**`APPSYNC`（如实记，非本波引入）**：`APPSYNC-REFRESH=refreshed=30 newer=0 applied=1`；
`APPSYNC=MISMATCH（MISMATCH=0[STALE=0 NEWER-DIFF=0] MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0]
DIVERGENT=0 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0）` ⇒ `STALE=0`／`DIVERGENT=0`／`MISMATCH=0`
三项**全 0**；`UNEXPECTED=6[DECL-GAP-EQ=6]` = **在册**声明类缺口（**不当绿、不改判据**，与 `#52` 逐字同形）。
`close-wave.sh:159-160` 会**长期**印 `⚠️ APPSYNC 非 PASS` —— 那是**登记在册的告警**（不是硬闸），**不是新问题**。

### (3) WIC 权威件同步

干跑 `refreshed=0 newer=0 applied=0`（rc=0）→ `--apply` `APPSYNC-REFRESH=refreshed=0 newer=0 applied=1`
（**写了 0 件** —— 波内那步已刷 30 件）；校验器 ⇒ `MISMATCH=0（STALE=0 NEWER-DIFF=0） MISSING=0
UNEXPECTED=6[DECL-GAP-EQ=6] DIVERGENT=0 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`
⇒ **`STALE=0 DIVERGENT=0`** ✓
（⚠️ 任务书那条"必须显式补根，否则 `STALE=0` 假绿（`D-G91`）"**已被 W113A 修掉**：`sync-applocal-authority.sh:103-105`
不覆盖时**从判据唯一实现派生**根集合（实测派生值**已含 `…/tools`**），显式收窄还会自检拒绝；我仍传同一集合 ⇒ **两法同值**）。

### (4) 五臂重取

槽：`HEAVYSLOT=ACQUIRED waited=861s`（排队 14 min 21 s）｜`MEMOK avail=5870MB`｜**`RELEASED rc=0 held=320 s`**。
`ARMS_DISPLAY=:97 source=reused`（`:97` 当时已在、几何 `1280x1024x24` ⇒ 走"复用"径；**不是我起的、我也没杀它**）。
取臂前自证：`shim=921ba9c65e9fb3be`｜`pc=722e0ab8205b7c3f`｜`run.sh=711f39f468f61cc8`｜`Parity.cs=149dd986a642fdfc`｜`CoverageProbe build rc=0`。

| 臂 | `#52` | 本波 | 变? | 判词（`#52` → 本波） | rc |
|---|---|---|---|---|---|
| `tline` | `56bea7233ba05c7b` | **`44c21d648f79126c`** | **变**（预测命中） | `通过 22 / 失败 2` → **逐字相同** | 1 |
| `tab-zero` | `9150c3a26a3cb789` | `9150c3a26a3cb789` | 未变（预测命中） | `退出码=1`（未登记失败 1/共 1，唯一 = `notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白 期望=0 实得=1`） | 1 |
| `tab-anchor` | `1c43a12dcaa5718a` | `1c43a12dcaa5718a` | 未变（预测命中） | `退出码=0`（`START 红=0 绿=615 判定行=615`／`OVERFLOWED 红=0 绿=421`／`字形释放行=194`） | 0 |
| `tab-rtl` | `92570318851ca7e8` | `92570318851ca7e8` | 未变（预测命中） | `退出码=0`（`红=0`） | 0 |
| `textlineproto` | `4bceceeed570ba70` | `4bceceeed570ba70` | 未变（预测命中） | `通过 10 / 失败 0` → **逐字相同** | 0 |

⇒ **只有 `tline` 变**（该日志内含 app-local 同步行／耗时／被同步权威件 sha／自指 artifact／日期戳文件名
⇒ **程序上不可复算**，它变**本身不构成产品位移信号**）；**五臂判词与 `#52` 逐字相同** ⇒ 判据 C4 命中、**不停手**。
⚠️ 机制留痕：重取脚本末尾用 **`ln -f`** 硬链进 `arm-logs/`（逐行印 `(links=2)`，`arm-log-sha-check.sh` 亦印 `nlink=2`）
—— **仓内既定机制**（`fp_inputs()` 注释写明"重取用 `ln -f`"，且因此**刻意不把 `arm-logs/` 纳入覆盖面**），
**不是**我沙箱的污染（我自己的实验全程 `cp -p`、**零 `ln`**）。

### (5) 重钉世代

`cp -p` 备份 ⇒ `~/w133a/backup/known-red.before-w133a.json`（与改前**逐位相同** `d4e0080df6ec497c`）。

- `--check` **前**：**`REPIN_GENERATION=FAIL n=2`**（`generation.arm_logs.tline 不一致`；
  `generation.evidence_log_sha256 声明=56bea7233ba05c7b 现场=44c21d648f79126c`）rc=1 ⇒ **这是"顺序"不是"矛盾"**。
- `--why '<四条理由>'`（① 产品位移 `win32shim`＝`TASK-0109`；② 环成员 `pf` 整波重建自变（`D-G92`）；
  ③ 波尾重取只有 `tline` 变、判词与 `#52` 逐字相同；④ 仪器侧零接线＋两件判据/文档域变更）⇒
  **`REPIN_GENERATION=APPLIED`**（rc=0）：`instr_run_sh=711f39f468f61cc8`｜`instr_program_cs=149dd986a642fdfc`
  ｜`instr_shim=921ba9c65e9fb3be`｜**`evidence_log_sha256=44c21d648f79126c`**
  ｜**`entries[*].caliber 改动字段数 = 0`**（**只动世代记账，没碰任何判据口径**）。
- `--check` **后**：**`REPIN_GENERATION=PASS（世代三项 + 五臂 + 证据日志 + 4 条 entries 的 caliber 全部一致）`** ✓（rc=0）。
- 件：`build/MilBridge/known-red.json` **`d4e0080df6ec497c` → `f108775906eac9aa`**
  （FULL `f108775906eac9aa0e21443e2757b746c01187dbeb1cc92cfcedc9f335492f4e`）。
- **`inputs_fp`（真函数现算，不复制函数体）**：`f0e2b3e8c058cdf017031360a2cc292ffd6ab7b91b4a8ae47c100c3877522bd7`
  → **`5ac1e5349c7d1dec56fd7d8fe5dd8e9c1cb7c3b4052859f887e45c539981904f`**
  （**归因：`known-red.json` 在 `fp_inputs()` 覆盖面内** —— `#28` 起的设计使然；覆盖面仍 **149** 件，
  由 `fp-inputs-hygiene-check.sh` 读 `close-wave.sh` 现算：`FPHYG_COVERAGE_N=149`）。
- **两颗声明牙的两极化（"顺序"不是"矛盾"）**：
  - 重钉**前**：`ARMLOG_SHA=FAIL shape=flat required=5 declared=5 pass=4 fail=1`／`COLUMN_FLOOR=PASS n_ok=5`
  - 重钉**后**：**`ARMLOG_SHA=PASS … pass=5 fail=0`**／**`COLUMN_FLOOR=FAIL … pass=3 fail=1 selfreport=PASS
    reg=f108775906eac9aa base=27293fb5ab91b778`**（`COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline`）
  ⇒ **正是判据 C6 预期的"恰好 1 处声明类红"**（`COLUMN_FLOOR_ARMLOG=FAIL` ∧ `selfreport=PASS`）。

---

## ③ 门禁 ×2（判据 C5）

**一趟槽内跑完两趟**：`HEAVYSLOT=ACQUIRED waited=936s`（排队 15 min 36 s）｜`MEMOK avail=5827MB`
｜**`RELEASED rc=0 held=322 s`**（`max_hold=700`）。

- 第 1 趟（`13:04:05`，写 `gate-rows.txt`）：**`WPTD_DISPLAY=:213`** ⇒ `== 启动自己的 Xvfb :213（1280x1024x24）`（PID 729292）｜**`GATE1_OUTER_RC=0`**
- 第 2 趟（`13:06:46`，写 `gate-rows-f.txt`，`--no-build`）：**`WPTD_DISPLAY=:214`** ⇒ `== 启动自己的 Xvfb :214（1280x1024x24）`（PID 746131）｜**`GATE2_OUTER_RC=0`**
- 两趟各 **6 行 `BASELINE`、6 个 `result=PASS`、0 个 `result=FAIL`**（`default 3/3` ＋ `env 3/3`）；
  `WPTD_SUMMARY=PASS tiers_passed=2/2`｜`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`｜
  `WPTD_BRIDGE_SRC_STALE=no basis=pub=0a8f69b3c5fabd43 now=0a8f69b3c5fabd43 so_file_match=yes`
  ⇒ **门禁本波 12/12 PASS**。
- rows：`gate-rows.txt` sha16 **`978f0ee52989d6c2`**｜`gate-rows-f.txt` sha16 **`8c5d2dd7ed1b8724`**；
  **两本 `config=` 段逐字相同**（`diff` 空 ⇒ `CONFIG_IDENTICAL`）=
  `pc:722e0ab8205b7c3f`／**`pf:4973bcb28e331cf0`**／**`win32shim:a6365183fa6d26b9`**／`bridge:feef049e9d0e313a`／
  `provider:1f9511a7ef395bfe`／`wic_shim:f7b3026c8c019be2`／`hbtextline_shim:921ba9c65e9fb3be(stale:no)`。
- ⚠️ **显示号用空闲 `:2xx` 的理由（不是随手换）**：`:97` 当时**在用但属别的车道**，`:185`/`:188` 也是别人的
  ⇒ 本车道**只用空闲 `:2xx`** ⇒ 两趟**各起自己的 `1280x1024x24`**，几何与 `#52` 落地的几何守卫要求
  （`XREQ_GEOM=1280x1024`）一致，且**不依赖别人的 X、也没杀任何别人的 X** ⇒ 这两趟读数**不可能**是
  "复用别人几何不符的 X"造成的假红/假绿。**Xvfb 由 runner 按 PID 自行收回**（日志末尾 `（脚本收尾：无孤儿）`）。
- ⚠️ **一处如实记的既有现象（非本波引入）**：两趟装配运行目录都印
  `System.Printing.dll ⚠️ 不一致 bin=5ccc76227e5e 权威=19493a86ad92（可能是集成波中途的产物）`
  —— `#52` 同一行**逐字相同**，且它**不在九位里**、**不参与任何判据** ⇒ **只报不处置**。
- ⚠️ **`WPTD_ARTIFACTS` 里 `dwf_sha=24e819debc1e5b13` 是 `Debug` 口径**（应用日志口径）；
  **冻结口径 = `Release` = `ce3469f49efcbcfa`** ⇒ **两套口径不许混比**（这是既有登记事实）。

---

## ④ 冻前 `verify-all`（判据 C6）

槽：`HEAVYSLOT=ACQUIRED waited=657s`（排队 10 min 57 s）｜`MEMOK avail=5774MB`｜**`RELEASED rc=0 held=876 s`**
（`max_hold=1500`；`#49`–`#52` 实测 854–911 s ⇒ 同量级）。日志 `~/w133a/logs/09-verify-pre.log`。

**`[0]` 段逐字**：

```
[0] Xvfb（目标 :99）
  ✅ X-REUSE=reused display=:97（已运行的 Xvfb；几何 1280x1024 相符；注意不是 :99）
  DISPLAY=:97（已用 xdpyinfo 验证可连）
  X_STATE=available（判据：xdpyinfo 对 DISPLAY=:97 成功 ⇒ available）
```

⇒ **几何守卫按设计工作**（`:97` 是 `1280x1024x24`、几何**相符** ⇒ 复用；若不符会 `skipped-geom-mismatch` 并自起）。
⚠️ **这正是 `#52` 那格假红的反面对照**：`#52` 冻前第 1 趟复用了**几何不符**的 `:185`（1024x768）⇒
`Windowing.Tests` 假红（`用例通过 831`）；本波几何相符 ⇒ `Windowing.Tests 44/0`、`用例通过 875`。

**结论行逐字**：**`步骤通过 26  ❌ 失败 1`**｜**`用例通过 875  跳过 2`**｜
`SKIP_GUARD=PASS x_state=available x_died=0 x_suite_skipped=0 x_suite_units=0 x_suite_corpus_max=0 total_skipped=2 violations=none reason=none`
｜**`结论：❌ 失败项：COLUMN-FLOOR`** ⇒ **恰好 1 处红，且就是设计内的声明类红** ⇒ **判据 C6 逐字命中**。
逐套件：`Commands 562/0`／`Rendering 166/2`／**`Windowing 44/0`**／`HelloMil 19/0`／`ManagedLayer 76/0`／`Presentation 8/0`
⇒ `562+166+44+19+76+8 = 875`（**与 `#52` 逐格相同**）。

唯一那 1 处红（逐字母句）：`COLUMN-FLOOR ❌ (rc=1)`／`COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline`／
`COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0 selfreport=PASS reg=f108775906eac9aa base=27293fb5ab91b778 corpus=0cebc0afd5142fbf`
⇒ **`COLUMN_FLOOR_ARMLOG=FAIL` ∧ `selfreport=PASS` = 冻结器 `_is_declaration_class()` 认的形态** ✓。

其余 26 步**全绿**，关键机读行：

- `BASELINESHA=PASS live=27293fb5ab91b778 decl=27293fb5ab91b778`｜`BASELINEGEN=PASS decl_gen=#52 file_newest_gen=#52`（冻前应然）｜`BASELINEDUP=PASS n=0`
- `ARMLOG_SHA=PASS required=5 declared=5 pass=5 fail=0 noinfo=0`（重钉后已转绿）
- **`VERIFYALL_SELF=PASS names=27 decl=27 gen=#53 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=32ddbe487235cc38`**
- **`R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938 mem_mb=5144 win32shim=a6365183fa6d26b9 pc=722e0ab8205b7c3f src=device`**
  ⇒ **`win32shim=` 是 `TASK-0109` 的新件**，`crit=13/13` ⇒ **零回归**（逐字段同 `#52` 基线，只有 `win32shim=` 按设计变）。
- `NULBYTES=PASS files=1221 hits=0 bytes=252550982 canary=ok`｜`FP_INPUTS_HYGIENE=PASS coverage_n=149 artifact_n=0`
  ｜`DEFREG=PASS declared=145 route_ids=145`｜`BUILD-HYGIENE … files=41 undeclared=0`｜
  `HIDDEN_ONLY_STEP=PASS 判定例=32/32`｜`PRODUCT_ENTRY_STEP=PASS 判定例=8/8 在册已知红 5/5`｜
  `SHELL_QUOTE_TRAP=PASS traps=0 files=157`｜`FRAMEPRESENCE=PASS frames=80`｜`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0`｜
  `THIRDPARTY=PASS frames=42`｜`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 unregistered=0 caliber=OK tree_gen=same`

⇒ **无第 2 处非声明类红 ⇒ 停条件④ 未触发**。

---

## ⑤ 冻结 `#53`（判据 C7）

命令：`python3 $HOME/w21-verify/w27-freeze.py ~/w133a/logs/09-verify-pre.log ~/w133a/gate-rows.txt '#53'`

### 🔴 一处**自伤与修复**（如实记，且**它是我自己的缺陷**）

**第 1 次冻结成功（`FREEZE_RC=0`，基线 = `00d969940f88e9d1`）**，但我在冻后 self-review 时发现
**冻结块里有 5 处前向引用指向一个永远不会存在的目标**：我写的是
``见 `===RECORD===` 冻后补记（`#53` 冻结实测）`` —— 而 `===RECORD===` 的内容**就是** `ACCEPTANCE-BASELINE.md`
里那个冻结块 ⇒ **那个"冻后补记"段永远不会存在**。而且**不能靠追加去补**：

```bash
# build/MilBridge/tools/baseline-sha-check.sh:33
live="$(sha256sum "$base" | cut -c1-16)"
```

⇒ 取的是**整份文件**的 sha ⇒ **往 `ACCEPTANCE-BASELINE.md` 追加任何一段都会让 `BASELINESHA` 当场 FAIL**
（`docs/CURRENT-STATE.md:9` 的声明值不会自己跟着变）⇒ 冻后两趟 `verify-all` 会全红。

**处置（按"重冻前必须先还原"的既定程序）**：
1. **按 PID**（**不是 `pkill`**）收掉**刚起 1 分多钟的冻后第 1 趟**（PID `882294`/`882293`/`882291`/`882290`，
   `kill -TERM` 逐个；收后逐个 `/proc/<pid>` 复查 = 全部消失）。**该趟不作为读数**（它是用 `00d969940f88e9d1` 跑的）。
2. **从备份逐字节还原**两件：`ACCEPTANCE-BASELINE.md` → `27293fb5ab91b778`（= `#52` 态）、
   `docs/CURRENT-STATE.md` → `737c78e3a7e5a3a5`（`BASELINE-FROZEN gen=#52`）⇒ 世代交叉断言可过。
3. **修 5 处引用**（`~/w133a/bin/fix-refs.py`，锚点唯一性断言；`w53-record.txt` sha16 `f3bc9025815942ff` → **`457fa1921d9d869c`**）：
   落点改为 **`build/MilBridge/W133A-report.md` §⑤/§⑥/§⑦/§⑧/§⑪**（**真实存在**的交付物），
   并在第一处逐字写明"**为什么指报告、不指本文件**"（上面那条 `BASELINESHA` 机制）。
4. **机械自检** `bash ~/w133a/bin/check-record.sh` ⇒ `CHECK_RECORD=PASS`（三类外挂声明行齐全且带 `# ` 前缀、
   无残留 `@@`）⇒ **重冻**。

### 第 2 次冻结（**交付态**）`FREEZE2_RC=0`

```
世代交叉断言通过：树上 #52 == GENS[#53][prev]
  · 冻前声明类红项 = ['COLUMN-FLOOR']（冻后必须转绿）
verify-all = 27 步（通过 26 / 失败 1；其中声明类 ['BASELINE-SHA','ARM-LOG-SHA'] 应为红、其余全绿） / 875 通过 2 跳过
牙齿②：`verify-all.sh` 的 `^run_step "` = 27 == 步数 27，且头注释逐字声明了同一数字
九位 = {'bridge':'feef049e9d0e313a','pc':'722e0ab8205b7c3f','pf':'4973bcb28e331cf0','windowsbase':'2e4e46e539a72cd7',
        'provider':'1f9511a7ef395bfe','win32shim':'a6365183fa6d26b9','wic_shim':'f7b3026c8c019be2',
        'hbtextline':'921ba9c65e9fb3be','dwf':'ce3469f49efcbcfa'}
相对开工前变化的位 = ['pf', 'win32shim'] ｜inputs_fp = 5ac1e5349c7d1dec56fd7d8fe5dd8e9c1cb7c3b4052859f887e45c539981904f ｜BRIDGE_SRC_FP = 0a8f69b3c5fabd43
本波位移 = ['pf','win32shim']（在本代声明的允许集合 ['pf','win32shim'] 内…）
本代声明允许位移、且真的动了的位 = ['win32shim']（其余八位逐位与开工前相同）
门禁 6 条机读行 OK（pc:722e0ab8205b7c3f pf:4973bcb28e331cf0）
基线已重冻为 #53；整份 sha16 = a2e49b786d0a1b02
BASELINESHA=PASS live=a2e49b786d0a1b02 decl=a2e49b786d0a1b02
BASELINEGEN=PASS decl_gen=#53 file_newest_gen=#53
BASELINE_BYTES=737918
BASELINEDUP=PASS n=0
ARMLOG_SHA=PASS shape=flat … required=5 declared=5 pass=5 fail=0 noinfo=0
COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=f108775906eac9aa base=a2e49b786d0a1b02 corpus=0cebc0afd5142fbf
✅ 两极化齐：冻前 BASELINE-SHA/ARM-LOG-SHA/COLUMN-FLOOR(ARMLOG) 红 ⇒ 冻后同一批检查器都绿
```

**四颗牙（`#53` 交付态）**：`BASELINESHA=PASS`｜`BASELINEGEN=PASS decl_gen=#53 file_newest_gen=#53`｜
`BASELINE_BYTES=737918`｜`BASELINEDUP=PASS n=0` —— **并用完整核对器逐条复核**（不是只看冻结器自报）：

```
> BASELINE-FROZEN gen=#53 sha16=a2e49b786d0a1b02 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md   （docs/CURRENT-STATE.md:9）
```

**九位（按冻结口径现算）** = 上表「冻结刻」列，与 `#52` 逐位比 ⇒ **只有 `win32shim`（产品）与 `pf`（环成员）变**，
逐字命中判据 C7 的预期。九位口径 = `close-wave.sh:371-380`／`:393-404`（`$SELFBUILT_CONFIG = Release`）。

**冻结器件**：`$HOME/w21-verify/w27-freeze.py` `101db5306e1669fe` →（追加 `GENS['#53']`）`32e32fab1055b1e0`
→（收紧 `infp`）**`5acac47065f6a7aa`** ⇒ **只追加 ＋ 一次收紧，老代（`#52` 及以前）一字未动**
（备份 `~/w133a/backup/w27-freeze.py.before-w133a` = `101db5306e1669fe` 逐位）。
**九位快照** `$HOME/w53-pre.sha`（`8dd00cb414a10ccf`，9 行，键=路径）由 `~/w133a/bin/make-pre53.py` 机械生成
（断言 9 个值**逐字**出现在 `#52` 冻结块里 ＋ 与 `w52-record.txt` 交叉核）。
**记录件** `$HOME/w21-verify/w53-record.txt` = **`457fa1921d9d869c`**。
**`ACCEPTANCE-BASELINE.md` 变更**：`27293fb5ab91b778`（697,873 B）→ **`a2e49b786d0a1b02`（737,918 B）**；
`# RE-FROZEN #53` 成为文件首块（`:49`），`#52` 块降级为 `# ⏪ **（历史，已被 \`#53\` 取代）**`。

**两极化齐（冻结器自己断言）**：冻前 `BASELINE-SHA`／`ARM-LOG-SHA`／`COLUMN-FLOOR(ARMLOG)` **红** ⇒
冻后同一批检查器**绿**。

---

## ⑥ 冻后 `verify-all` ×2（判据 C8）

两趟都必须 `步骤通过 27 ❌ 失败 0`／`结论：✅ 全部通过`／`用例通过 875 跳过 2`；
**判词层机读行两趟逐字相同**；**两趟之间不许换件**（`[26] R-GATE` 读 `win32shim=`）。

| 趟 | 入槽 | `MEMOK` | 槽读数 | `[0]` 段 | 结论 | 判词 |
|---|---|---|---|---|---|---|
| 1（`13:38:20`） | `waited=53s` | `avail=5482MB` | **`RELEASED rc=0 held=854 s`**（`max_hold=1500`） | `✅ X-REUSE=reused display=:97（…几何 1280x1024 相符…）`／`X_STATE=available` | **`步骤通过 27  ❌ 失败 0`**／`用例通过 875  跳过 2`／**`结论：✅ 全部通过`** | `POST1_OUTER_RC=0` |
| 2（`13:54:29`） | `waited=370s` | `avail=5624MB` | **`RELEASED rc=0 held=854 s`** | 同上（逐字相同） | **`步骤通过 27  ❌ 失败 0`**／`用例通过 875  跳过 2`／**`结论：✅ 全部通过`** | `POST2_OUTER_RC=0` |

⇒ **两趟同形**（`held` 都恰好 **854 s**，与 `#52` 的 867/854 s 同量级）；**冻前那 1 处声明类红已转绿**：

- `COLUMN-FLOOR` **✅**：`COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=f108775906eac9aa base=a2e49b786d0a1b02 corpus=0cebc0afd5142fbf`
  ＋ 六个子检 `COLUMN_FLOOR_{OVERFLOWED_JUDGED_MIN,START_JUDGED_MIN,START_RELEASED_MIN,CORPUS,ARMLOG,SELFREPORT}=PASS`
  （`COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无`）⇒ **两极化闭合**。
- `BASELINESHA=PASS live=a2e49b786d0a1b02 decl=a2e49b786d0a1b02`｜`BASELINEGEN=PASS decl_gen=#53 file_newest_gen=#53`｜`BASELINEDUP=PASS n=0`
  ｜`ARMLOG_SHA=PASS … pass=5 fail=0`｜`VERIFYALL_SELF=PASS names=27 decl=27 gen=#53 … vfile_sha16=32ddbe487235cc38`
  ｜**`R_GATE=PASS crit=13/13 … win32shim=a6365183fa6d26b9 pc=722e0ab8205b7c3f src=device`**（两趟都读**新件**）。
- **判词层机读行两趟逐字相同 = 15/19**；**4 处不同全是运行期读数、非判词**（如实记）：
  `R_GATE mem_mb=5360 vs 5242`｜`FRAMEPRESENCE … dir=/home/links-dev/w34-framepresence-134915 vs …-140522`（带时间戳目录名）｜
  `THIRDPARTY … dir=/home/links-dev/w37-tpm-135126 vs …-140735`｜`TLINE_GATE … outdir=…/tline-gate-20260923-134009 vs …-135619`
  —— 与 `#52` 的两趟差异**完全同族（3 类）**；`FRAMEPRESENCE frames=80 max_colors=4113`、`THIRDPARTY frames=42 max_colors=1642` 逐字相同。
- **两趟之间没有换件**：两趟的 `R_GATE … win32shim=a6365183fa6d26b9` **逐字相同**，且冻后刻九位与冻结刻**逐位相同**（含 `pf 4973bcb28e331cf0`）⇒ 判据 C8 命中。
- **冻后刻九位复算（脚本现算，与冻结刻成对并列）**：冻结刻 = 冻后刻 = `bridge feef049e9d0e313a`／`pc 722e0ab8205b7c3f`／`pf 4973bcb28e331cf0`／
  `windowsbase 2e4e46e539a72cd7`／`provider 1f9511a7ef395bfe`／`win32shim a6365183fa6d26b9`／`wic_shim f7b3026c8c019be2`／
  `hbtextline 921ba9c65e9fb3be`／`dwf ce3469f49efcbcfa` ⇒ **本波 `pf` 在冻结前/后都稳定**（`D-G92` 只在**重建**时发作）。
  冻结件仍 **`a2e49b786d0a1b02`**（未被动过）；`inputs_fp` 仍 **`5ac1e5349c7d1dec…904f`**（未变）。

---

## ⑦ 推送（逐径）（判据 C9）

**机制（先搞清再动）**：fork 克隆 `~/netTest/GitProj/WPFOnLinux` 是**独立检出**，**不自动跟随 `$R`**
（现场实测：克隆工作树 `git status --porcelain` **空**、`HEAD = 33df6aa1bafb1a6b03ad43135327847af809f281`，
而 `src/WpfGfx.Linux.Native/src/win32_x11.c` 与 `$R` **DIFF**）⇒ 必须**先 `cp -p` 真件**。

**待推送清单的求法（机械，不靠记忆）**：`git ls-files`（**15,268** 件）逐件 `sha256` 对 `$R` 比
⇒ **11 件 DIFF**；再单独查**未 tracked 但属于本波**的新件 ⇒ **2 件**（`docs/WAVE53-PREREGISTRATION.md`、
`build/MilBridge/W131A-report.md`）。**合计 13 件**：

| # | 件 | 磁盘 sha16 |
|---|---|---|
| 1 | `src/WpfGfx.Linux.Native/src/win32_x11.c` | `9fa20864404ab01b` |
| 2 | `src/WpfGfx.Linux.Native/src/win32_core.c` | `a9cc8762908b417a` |
| 3 | `src/WpfGfx.Linux.Native/src/win32_internal.h` | `4e1880e6054635ff` |
| 4 | `verify-all.sh` | `32ddbe487235cc38` |
| 5 | `docs/WAVE53-PREREGISTRATION.md`（**新建**） | `b5ecd5433a57af47` |
| 6 | `docs/CURRENT-STATE.md` | `81b35c059717b7a8` |
| 7 | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | **`a2e49b786d0a1b02`** |
| 8 | `build/MilBridge/known-red.json` | `f108775906eac9aa` |
| 9 | `build/MilBridge/arm-logs/tline.log` | `44c21d648f79126c` |
| 10 | `build/MilBridge/gen/t2d-family-baseline.txt` | `ab0758aa92ca8356` |
| 11 | `build/MilBridge/gen/t2d-family-matrix.txt` | `e442cefd0e2b6e4a` |
| 12 | `build/wave-audit.log` | `4d1eb629c9323e4f` |
| 13 | `build/MilBridge/W131A-report.md`（**新建**，本波产品车道报告） | `f24241c62d92e495` |

**逐件计数对账（防 `#52` 那次 `add -A` 夹带事故的同族纪律）**：
`git status --porcelain` **13 行**（= 我 cp 的 13 件，**逐行对得上**）＝ `git diff --cached --name-only` **13 件**
⇒ **"本笔恰好 13 件、无夹带"**（未出现任何别的在办车道的 native 源或报告）。

**推送读数**：
- commit = **`aaa5bb5b86d2b5059109eb8f99745e03460aab9b`**（`13 files changed, 1027 insertions(+), 56 deletions(-)`；
  `create mode 100644 build/MilBridge/W131A-report.md`、`create mode 100644 docs/WAVE53-PREREGISTRATION.md`）
- `git push origin feat-Linux`：`33df6aa..aaa5bb5  feat-Linux -> feat-Linux`
- **push 之后重新 `fetch` ＋ 与 `ls-remote` 交叉核**：`local = remote-tracking = ls-remote = aaa5bb5b86d2b5059109eb8f99745e03460aab9b` ⇒ **三者一致** ✓
- **逐件 `BYTECHECK`**（`git cat-file blob origin/feat-Linux:<path> | sha256sum` vs 磁盘）：
  **`ok=13 mismatch=0 nobody=0`**（逐件值见上表，逐件逐位相同）
- `git ls-remote --symref origin HEAD` ⇒ **`ref: refs/heads/feat-Linux  HEAD`** ✓

**⚠️ 两处如实记的观察（都不影响任何判据/指纹）**：

1. **`verify-all.sh` 的 `mode` 被本笔记成 `100755 → 100644`**。**根因不是本件的改动**：`$R` 里它**本来就是 `644`**
   （本车道开工前的 `cp -p` 备份 `~/w133a/backup/verify-all.sh.before-w133a` 实测 `644`），
   而**克隆/远端那一版是 `100755`**（`git ls-tree 33df6aa verify-all.sh` = `100755`）⇒ 这个**预先存在**的模式差
   只是**头一回被提交出来**。**处置**：本件把它**恢复成发布态 `100755`**（`chmod 755` ＋ 逐径 `git add`，
   见本报告 §⑦ 的**第二笔**）—— 理由：该件的**自述用法**就写 `./verify-all.sh`，且前者是**发布态的实际值**；
   ⚠️ **mode 不进任何哈希**（`sha256sum` 只看内容）⇒ **`inputs_fp`／九位／基线一字未动**（改后再算两次同值）。
2. **另有 6 件别的车道的报告（`W115A/W119A/W121A/W123A/W124A/W125A-report.md`）我没有推** —— 与 `#52`
   的裁定同形：它们**不在克隆里**（未 tracked），且 **`W124A` 当时仍在跑**（它的批在槽里）⇒ 推它们等于推**半成品**。
   （`#52` 当天主控对同族的三件裁定就是"交主控裁"。）⇒ **如主控要，另派一笔补推即可。**

---

## ⑧ app-local 回读（判据 C10）

命令（**显式补根 = 与判据唯一实现派生的同集合**，所以自检通过；两法同值）：
`AUTH_ROOT=$PWD SCAN_ROOTS=$PWD/build:$PWD/tests:$PWD/samples:$PWD/src:$PWD/tools bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh [--apply]`

- 干跑：`APPSYNC-REFRESH=refreshed=0 newer=0 applied=0`（rc=0）
- `--apply`：**`APPSYNC-REFRESH=refreshed=0 newer=0 applied=1`（写了 0 件** —— 波内 `[1/6]` 那步已刷 **30** 件）
- 校验器（`check-applocal-sync.sh`）⇒
  `APPSYNC=MISMATCH（MISMATCH=0[STALE=0 NEWER-DIFF=0] MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0]
  DIVERGENT=0 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0）`
  ⇒ **`STALE=0`／`DIVERGENT=0`／`MISMATCH=0`／`MISSING=0` 全 0** ✓（判据 C10 命中）。
  ⚠️ 校验器 **`rc=1`**，但它**不是因为上面的计数器**：`UNEXPECTED=6[DECL-GAP-EQ=6]` 是**在册**声明类缺口
  （`#49` 起登记，**不当绿、不改判据**）—— 与 `#52` 逐字同形。
- **`win32shim` 是五件权威件之一 ⇒ 应用目录（门禁两趟真正加载的那一份）里的件已是新件**：
  `~/w133a/gate-e/libwpfwin32.so` = **`a6365183fa6d26b9`**｜`~/w133a/gate-f/libwpfwin32.so` = **`a6365183fa6d26b9`**；
  两趟门禁的机读行逐字印 **`WPTD_ARTIFACTS … win32shim_sha=a6365183fa6d26b9 …`**
  （口径：`run-wpftextdemo.sh` 的"二进制类全部读自 **app-local 运行目录** —— 即应用真正加载的那几份"）。

### ⚠️ 顺带处置的一件既有隐患：`~/wfp-runs/arms23` 又变回了**硬链接别名**

- **现场**：本波五臂重取之后，`stat -c '%h %i'` 显示 `build/MilBridge/arm-logs/*.log` 与
  `~/wfp-runs/arms23/*.log` **同 inode、`nlink=2`**（五行全同）⇒ **`arms23` 那一层不构成归档**
  （改任一侧会同时改另一侧 —— 纪律 59 要求的"归档层"再次落空）。
- **机制**：`build/MilBridge/tools/retake-arms-w23.sh:13` 是 `OUT="${ARMS_OUT:-$HOME/wfp-runs/arms23}"`，
  脚本末尾再用 **`ln -f`** 把 `$OUT/*.log` 硬链进 `arm-logs/` ⇒ **默认 OUT 就是"归档目录"本身** ⇒
  **别名是构造出来的**。该件 `:30` 的注释自己就写着 "`#31` W31C 清掉了 11 条别名、把 `$HOME/wfp-runs/arms23` 改成**真副本**"。
  ⚠️ **我按任务书"照 `#52` 用的那个入口"逐字跑（没设 `ARMS_OUT`）** ⇒ 别名被重新造出来。
- **处置（已落地，只改别名侧，零内容位移）**：`cp -p` 到同目录临时名 ＋ `mv -f` 覆盖（**只动 `~/wfp-runs/arms23/**`**）
  ⇒ nlink 2 → **1**、五个新 inode；**逐件 `cmp` = `IDENTICAL`**；
  **权威侧 `arm-logs/*.log` 的 5 个 sha16 逐位未变**（改前 = 改后 =
  `1c43a12dcaa5718a`／`9150c3a26a3cb789`／`92570318851ca7e8`／**`44c21d648f79126c`**／`4bceceeed570ba70`）。
- **改后复算三颗牙**：`ARMLOG_SHA=PASS … pass=5 fail=0`（逐臂印 `nlink=1`）｜
  `BASELINESHA=PASS live=a2e49b786d0a1b02 decl=a2e49b786d0a1b02`｜
  `COLUMN_FLOOR=PASS … base=a2e49b786d0a1b02`｜`inputs_fp` 仍 `5ac1e534…904f` ⇒ **冻结语义零影响**。
- **给主控的一句建议（不在本件写域，未落）**：让 `retake-arms-w23.sh` 的**默认 `OUT` 改成一个不同 inode 的目录**
  （或默认就设 `ARMS_OUT`），否则**每一代重取都会把别名再造一次**。

---

## ⑨ 哨兵两处（任务书 §11）

`close-wave.sh:387-412` 是 `/tmp/bridge-frozen.flag` 的**唯一写者**；本波 `[6/6]` 段已写。

| 处 | 内容 |
|---|---|
| `/tmp/bridge-frozen.flag` | `WIN32SHIM=`**`a6365183fa6d26b9`**｜`WAVE=`**`close-wave-122558`**｜`PF=4973bcb28e331cf0`｜`PC=722e0ab8205b7c3f`｜`SHA=feef049e9d0e313a`｜`FP=0a8f69b3c5fabd43`｜`HBTL=921ba9c65e9fb3be`｜`WIC=f7b3026c8c019be2`｜`PROVIDER=1f9511a7ef395bfe`｜`WB=2e4e46e539a72cd7`｜`DWF=ce3469f49efcbcfa` |
| 镜像 `~/wfp-runs/bridge-frozen.flag` | **逐字节相同**（`cmp` ⇒ `IDENTICAL`），同上 |

**换代前**：`/tmp` 那份**不存在**；镜像 = `close-wave-155140`（**9-18 旧代**，`WIN32SHIM=0098234982391bbf`）
⇒ **本波把两处哨兵都换到了 `TASK-0109` 的件**。
⚠️ `NOTE=` 行仍写"基线号请在冻完后手工补 BASELINE=" ⇒ 按仓规，**哨兵不含基线号**（`close-wave.sh` 不写该字段，我不自造）。

---

## ⑩ `NOINFO` 逐条（**取不到就写 `NOINFO`，不许猜**）

1. **`pf` 非确定性根因**（`D-G92`）：本波又添一条成对读数（`358136b0c806ee88` → `4973bcb28e331cf0`，**同尺寸**），
   **真凶未明**。**要什么样的读数**：一个覆盖 PF **全部**编译输入（含生成件与时间/路径相关输入）的指纹。
2. **`tline` 臂日志 sha 变化不可归因**：该日志内含 app-local 同步行／耗时／被同步权威件 sha／自指 artifact／
   日期戳文件名 ⇒ **程序上不可复算**；判据只能是**判词**（本波 = `通过 22 / 失败 2`）。
3. **`UNEXPECTED=6[DECL-GAP-EQ=6]` 未逐条归因**：`#49` 已认定为**在册**声明类缺口；本件只确认"**不因本波变多**"。
4. **`upstream/**`（6417 件）未测**：`NUL-BYTES` 步的 `PASS` **只等于「声明覆盖面里 0 件含 NUL」**。
5. **`D-G83`（`WM_GETMINMAXINFO` 四格）本波未重跑**：装置在别的车道的 `~/w89a/bin/**`（≈30 min，重活）。
   W131A 的**静态替代**（`DefWindowProcW` 那一段与修前逐字相同）我**未重做**，故为 `NOINFO`。
6. **真应用"拖动窗口"未被本波重测**：`TASK-0109` 的产品侧验收由 W131A 的深仪器负责（`green=7 red=5` → `green=12 red=0`）；
   本件只冻结**件级**读数。
7. **`System.Printing.dll` 的 `bin`/权威不一致未归因**（两趟门禁都印）：`#52` 同一行逐字相同，
   不在九位里、不参与判据。
8. **`:97` 的所有者未定人**：本波**复用了它**（五臂 ＋ `verify-all [0]` 段），几何 `1280x1024` 相符；
   **我没有杀它、也没有改它**（`#52` 期间主控明令"不许杀别人的 X"）。它的存活是这两项读数的**外部依赖**。
9. **`verify-all.sh` 的 `[26]` 步 `mem_mb` 等运行期读数逐趟不同**：不是判据，只如实记。
10. **主控给的"冻结器不在现场"那条 `NOINFO` 我判为口径差**（见 §① 更正）—— 若主控坚持按"不可核"记，
    则本波的"改 `verify-all.sh` 声明"仍**有另外两条已核依据**（口径句与 DECL 一致、`#52` 的实际形态），结论不变。

---

## ⑪ 内存三值与纪律

- `MemAvailable`：**开工 5,859 MB**（`12:04:38` 现读 `free -m`）｜**最低 4,976 MB**（`14:07` 冻后复算刻，两趟冻后 `verify-all` 与别的车道批交叠）
  ｜**收工 5,590 MB**（`14:2x`）｜各重活入槽时的 `MEMOK avail=` 依次 **5895 / 5870 / 5827 / 5774 / 5482 / 5624 MB**
  ｜**全程 `oom_kill = 0`**。
- `loadavg`：开工 `1.20 1.57 1.79` → 收工 `1.04 1.29 1.35`。
- **每趟重活都在槽里**（逐趟 `HEAVYSLOT=ACQUIRED waited=…`／`MEMOK`／`RELEASED rc=… held=… max_hold=…` 已逐条记在 §②/③/④/⑥）
  —— 排队合计 ≈ **1020＋861＋936＋657＋53＋370 = 3,897 s（≈65 min）**（**排队不绕槽**：`W124A` 的 29 腿批与 `W128A` 的链先后占着槽）。
- **无 `MAXHOLD_KILL`、无 `low-memory`** ⇒ **无因纪律作废的趟**。**唯一被作废的一趟**见 §⑤
  （我自己**按 PID** 收掉的第 1 次冻后趟，**已声明不作读数**，且它用的是被废弃的基线 `00d969940f88e9d1`）。
- **全程零 `pkill`／零 `killall`／零 `pgrep -f`**：收进程**只按 PID**（`kill -TERM <pid>` 逐个 ＋ 逐个 `/proc/<pid>` 复查消失），
  探活一律读 `/proc/*/cmdline`（本报告里"某进程在不在"的每一条都是这么取的）。
- 显示号：本车道**只用空闲 `:213`／`:214`**（两趟门禁自起，几何 `1280x1024x24`；**收工时 `/tmp/.X11-unix/` 里两者都已不在** —— runner 按 PID 自己收了）；
  **未碰** `:0`／`:1`（用户桌面）／`:97`／`:185`／`:188`（别人的）。
- 本车道沙箱 `~/w133a/**` 的 `find -type f -links +1` = **0**（**零硬链接**；只有 `arms23` 那一处**清别名**，
  且是**把别人的别名改成真副本**，见 §⑧）。

---

## ⑫ 大白话小结（≤6 行）

1. 波 `#53` 的收尾链**走完了**：整波重建 rc=0、native **逐字节复现** `a6365183fa6d26b9`（导出仍 547）、
   五臂重取（只 `tline` 位变、判词与上代**逐字相同**）、重钉世代 `PASS`。
2. **`#53` 已冻结**：整份 `a2e49b786d0a1b02`（737,918 B），四颗牙全 `PASS`；冻前那 1 处声明类红
   （`COLUMN-FLOOR`）**冻后转绿** ⇒ 两极化齐。九位里**只有 `win32shim`（产品）与 `pf`（环成员，`D-G92`）**变。
3. **门禁 ×2 = 12/12 PASS**；冻前 `verify-all` **恰好 1 处声明类红**、`用例通过 875`（与上代同值）；
   `R_GATE=PASS crit=13/13` 且 `win32shim=` 是新件 ⇒ **零回归**。
4. **两件写域之外的件**（`verify-all.sh` 声明改 `#53`、新建 `WAVE53-PREREGISTRATION.md`）**先公告后落**、
   主控逐条批准，且**都不动 `inputs_fp`**；`inputs_fp` 的位移**唯一归因**于重钉 `known-red.json`。
5. **一处自伤我做了修复**：第 1 次冻结块里 5 处前向引用指向不存在的段落，且**不能靠追加去补**（会让
   `BASELINESHA` 必红）⇒ 我**按 PID 停掉刚起的冻后趟**、**从备份逐字节还原**、修好引用后**重冻**，
   全部过程与两次的 sha 都在 §⑤。**被作废的那趟已声明不作读数。**
6. **没做到的**：`pf` 非确定性根因、`tline` 日志变化的归因、`D-G83` 四格与真应用拖动、`:97` 的所有者 —— 全列在 §⑩。
