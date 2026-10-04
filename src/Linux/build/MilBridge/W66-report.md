# 波 `#66` 报告 —— **`TASK-0720` 落仓**（A3 口径更正 ＋ 11 条 `#if NEVER` 死声明名单落册 ＋ 批 2a 三条 `LsErr` 诚实失败 ＋ `Nl*` 有意降级声明牙 ＋ `fp_inputs()` +1 行）

- **owner**：车道 **W158A-W66EXEC** ｜**工作目录** `~/w158a/` ｜**报告时刻**：`2026-09-24`（本件在**冻结之后**写，如实声明：判据链以 `~/w158a/criteria.md` 的 mtime 为准，本件**不冒充**"早于落地"）。
- **落仓基点（我现取，非抄）**：`verify-all.sh 79e4780086588fcb`｜`close-wave.sh 9dfc1e43b4d67fbf`｜`KNOWN-DEFECTS.md 7a663e8d4d8ee953`｜世代 `#65`（基线 `b9c97237afd4c214`）｜`^run_step` = **37**。
- **冻结结果**：`BASELINE_SHA16 = 8c53d8da067472cb`｜`CURRENT-STATE`：`> BASELINE-FROZEN gen=#66 sha16=8c53d8da067472cb`｜`# RE-FROZEN #66` 命中 1｜残留占位符 0。

---

## §1 落地件（逐件 before → after，全部**现场算**；写前逐件过 `%h==1` 闸）

| 件 | before | after | 说明 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_classification.c` | `1e17b8331c2d3d73` | **`a5923b2fc07dea0b`**（13,661→13,744 B） | A3 注释口径更正（**单行、保行数**；留「111 条」＋ `TOOL-UNSOUND` ＋ 两个新口径） |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `7a663e8d4d8ee953` | **`a31f34c113235dd3`**（717,620→718,486 B） | 11 条 `#if NEVER` 死声明名单落册（**`+1 行/-0 行`**；**由主控搬行** ＋ 同趟重发 `declared.tsv 342a25e8795f58b5`） |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `e6559d0bba3c1044` | **`bcb9858919e6237e`**（13,404→15,189 B） | 批 2a 三条 `LsErr` 诚实失败（`P03`＋`P03X` **同趟**；导出 `547→550`；自检 `== 1`） |
| `build/MilBridge/tools/nl-intent-check.sh` | —（新建） | **`44f5e87b0ed0929c`**（15,123 B） | `Nl*` 有意降级声明牙（单文件自足；`--selftest 4/4`；live `PASS`） |
| `build/close-wave.sh` | `9dfc1e43b4d67fbf` | **`3f190c323b543275`**（40,008→40,955 B） | `fp_inputs()` 名单 **+1 行** ⇒ 覆盖面 `162 → 163` |
| `verify-all.sh` | `79e4780086588fcb` | **`f31123fac6e2c1e6`**（126,758→128,393 B） | 两条 `#66` 声明（口径句 ＋ `STEPS-DECL`，均插在 `#65` 行之前） |
| `docs/WAVE66-PREREGISTRATION.md` | —（新建） | `e6d368b565357ec1` → **`bf6b683d94549087`**（2,890→3,409 B） | 预登记件；`P07B` 把「不做回归判定」声明**补进判据节内**（见 §6） |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `b9c97237afd4c214` | **`8c53d8da067472cb`** | 冻结（`# RE-FROZEN #66`） |
| `docs/CURRENT-STATE.md` | — | `gen=#66 sha16=8c53d8da067472cb` | 机读行由冻结器改（**唯一声明处**） |

**落地纪律**：全部 `temp + os.replace`（换 inode）；写前用 `~/w158a/tools/shadow-gate.sh`（**唯一实现**）逐件断言 `stat -c %h == 1`，不满足 `exit 3` **拒写**。

## §2 判据与两极化（判据**先写**：`~/w158a/criteria.md`，`730f9d283bb9d2fc`）

| 判据 | 正极 | 反极（真跑） |
|---|---|---|
| `C1` 单行保行数 ＋ 两口径 ＋ 标记 | `check-111-sweep.sh live_uncorrected=0` | 基线 `=1`（实测）；去掉 `TOOL-UNSOUND` ⇒ 判否翻转 |
| `C2` 11 名集合相等 | 落册名集合 == `check-numbers.py` 现算 `DEAD`（`dead=11/11`） | 基线「缺 11 名」；删一名 ⇒ 点名 |
| `C3` 三条诚实失败 | **进程外驱动**：三条各 `ret=-10000 ∧ out=NULL` ∧ `DISTINCT=9` ∧ `REPORT entries=9 … err=-10000` ∧ `SELFCHECK=1`；台账 `seq=7/8/9` | `return 0` ⇒ 驱动 FAIL ＋ `SELFCHECK=0`；出参不清零 ⇒ `out=NON-NULL`；未打补丁源 ⇒ `MISSING_SYMBOL×3` |
| `C3-j` **自检牙齿**（新增判据） | `P03X` honest ⇒ `SELFCHECK=1` | **NEG-B ⇒ `SELFCHECK=0`**（翻转） |
| `C4` `Nl*` 牙 | 仓内件 `--selftest 4/4` ∧ live `PASS` | 四极自测（含**现场 gcc 编的假 `.so`**） |
| `C5` 覆盖面 +1 | 成员表真跑 `162 → 163`、新牙 0→1 命中 | 基线 0 命中 |
| `C6` 收口 | 冻前/冻后 `37 ✅/0 ❌` | 第 1 趟 `36 ✅/1 ❌` 曾真实发生（见 §6） |

> ⚠️ `criteria.md` 的**三条修订**是**测量之后**追加的（原文一字未删）：① C3 漏了"作假必须翻转"这一格；② 覆盖面写成 121→122（**旧值**，现读 162→163）；③ "link 计数恰好 −1"**不是判据**（并发车道的影子会一次掉 2）。

## §3 九位位移（**正好两位**，与预登记一致）

`相对开工前变化的位 = ['pf','win32shim']`｜`本代声明允许位移且真的动了的位 = ['win32shim']`（`pf` 为环成员，按惯例单列）⇒ **无表外位移、无"该动没动"**。

| 位 | 波前（`#65` 冻结块） | 波后 | |
|---|---|---|---|
| `pf` | `59ba7d2997fcdd62` | `29ad6d7cf3246938` | 环成员（整波重建必变） |
| `win32shim` | `d2b76a0a56a41be1` | `fc60c34d51fd9247` | **native 源新增 3 条导出（547→550）** |
| 其余七位 | — | **逐位未变** | `bridge`／`pc`／`windowsbase`／`provider`／`wic_shim`／`hbtextline`／`dwf` |

`inputs_fp`：`4c1056dd…`（`#65`）→ **`2fa59979bcdd0148…`**（整波自印"波前==波后"）｜`BRIDGE_SRC_FP = d697b1e10ff48881`（未变）｜`native_rebuilt=1 bridge_republished=0`。

⚠️ **取数位置自伤（留痕）**：我第一版位移对照从**件正文的历史行**取波前值（出现过 `f2df3c2b…` 这类中间值）⇒ 改用 `# RE-FROZEN #65` 块 ＋ `BASELINE tier=` 机读行后结论不变（都是这两位）。**波前值只能从当代冻结块取。**

## §4 整波 ＋ 门禁 ×2

- **整波** `close-wave.sh --skip-verify-all`（槽内托管后台作业）：**`rc=0`／`held=183s`**；`输入稳定性：波前==波后 == 2fa59979…` ✓。
  ⚠️ **第 1 次尝试被 `[0/6]` 挡下且是**假阳性**：命中行是 `w153a` 车道推文档的 shell —— 它的**命令行文本**里含 `WpfFeatureProbe`（`D-G34` 已登记的残余：按"命令行文本"而非"可执行件名"匹配）。**没有改判定输入**，等它退出后重起。
- **门禁 ×2**（槽内串行，`tests/…/run-wpftextdemo.sh 45`）：`pass1/pass2 rc=0 rows=6`｜`WPTD_SUMMARY=PASS tiers_passed=2/2`｜`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`｜`WPTD_BRIDGE_SRC_STALE=no`（`pub=now=d697b1e10ff48881`）｜**`GATE_LINES_IDENTICAL=yes`**｜`ROWS_IDENTICAL=no`，但**归一化（去 `rundir=`／头注释）后逐字节相同**（差异只有时间戳/loadavg/mem/rundir）。
  ⚠️ **显示号**按硬规则用 `:23x`：脚本默认 `:97`，而 `:97` 现场**已被占用** ⇒ 显式 `WPTD_DISPLAY=:231`（脚本自起 Xvfb 并按 **PID** 收尾）。

## §5 冻前 / 冻后 `verify-all`

- **冻前（第 2 趟，采用趟）**：`logs/w66-verify-all-prefreeze2-20260924-191603.log` ⇒ `步骤通过 37 ❌ 失败 0`、`结论：✅ 全部通过`、`VERIFYALL_SELF=PASS names=37 decl=37 gen=#66 dup=0 order=OK prose=OK prereg=PASS`、`BASELINESHA=PASS live=b9c97237afd4c214`。
- **冻后 ×2（各在槽内、独立生命周期）**：
  - 第 1 趟 `19:49:17` **`rc=0`** ｜ `步骤通过 37 ❌ 失败 0` ｜ `结论：✅ 全部通过` ｜ `[11] VERIFYALL_SELF=PASS names=37 decl=37 gen=#66 dup=0 order=OK prose=OK prereg=PASS` ｜ `[7] BASELINESHA=PASS live=8c53d8da067472cb`
  - 第 2 趟 `20:04:01` **`rc=0`** ｜ 同上逐字相同
  - ⇒ **`touch ~/w21-verify/w66-POST.done`**：真 stat = `mtime=2026-09-24 20:04:01.611727101 +0800 size=0`
  （第 `[7]` 步的 `live` 是**动态现读** ⇒ 两趟判的都是**新基线**，不是写死的旧值。）

## §6 🔴 第 1 趟冻前 `verify-all` 失败（`36 ✅ / 1 ❌`）—— 根因、修法、守卫

- **失败项**：`PREREG-FOUR-REQ`（`PREREG4_FILE file=docs/WAVE66-PREREGISTRATION.md state=fail missing=7`）。
- **根因＝声明写错了节**：`prereg-four-requirements-check.sh` 的 `extract_section()` **只取"第一个标题含『判据』的节"**，而「本波不做任何回归判定」被我写在 **`§0`（判据节之外）** ⇒ `no_rd_decl=0` ⇒ 落进四要件判据 ⇒ `missing=7`。
- **修法**：`patches/P07B.py`（**只加不改**，走 `%h==1` 闸 ＋ `temp+os.replace`）把同一条声明**补进 `§1 判据` 节内** ⇒ `e6d368b565357ec1 → bf6b683d94549087`。**单独复验**（照 `verify-all` 的形态）：`PREREG4=PASS files=47 pass=1 fail=0 na=8` ⇒ 该件从 `fail` 移入 `na`。
- ✅ **守卫生效的现场记录**：我的 `w66-freeze.sh` 见 `步骤通过 36 … 失败 1` ⇒ 当场 `STOP：… ⇒ 不写 DONE`、**没有冻结**。**`FRC≠0／步数不符 ⇒ 不写 DONE` 不是摆设**。
- **施工必记（本波新增）**：**「不做回归判定」这类节级声明，必须落在牙真正抽取的那一节里** —— 位置错了等于没写。

## §7 我自己的仪器／纪律自伤（逐条留痕）

1. **链式复核的同一个 bug 犯了 3 次**（把补丁的 `after` 直接与文件现态比，而 `P03X` 骑着 `P03`）⇒ 抽成**唯一实现** `tools/verify-chain.py`，`apply.sh [3b]`／`sparse-leg` ②／`land-r66` ③ **三处全部迁移**（"同一逻辑两处必然分叉"）。
2. 🔴 **`UNWIRED` 的证据被它自己的文档正文污染**：声明里写了 `nl-intent-check.sh` ⇒ 裸 `grep -c nl-intent` 由 **0 变 2**，"0 = 未接线"当场失效 ⇒ 改成**只看 `^run_step` 行 = 0**（全文命中只作数量级旁证）。
3. **"某物已不存在"的判据被创建它的那条路径破坏**：`apply.sh` 开工 `mkdir -p … shadow` 每次把空 `shadow/` 造回来，而"农场已清"的验收格正是 `ls -d … shadow`。
4. **自匹配计数**：用 `ps | grep heavy-slot | grep -c w158a` 自查槽进程，读数 2 —— 那是**我的检查命令自己**。
5. **`bash -n` 不是判据**：我给 `say` 行写了未转义反引号（`DQ-BACKTICK`），`bash -n` 两次都静默通过，是**仓内 `shell-quote-trap-check.sh`** 当场抓到 6 条并点名到行。
6. **取数位置**：位移对照第一版引用了件正文里的中间值（见 §3 尾）。
7. **`patch -R` 的 `-p` 深度**照抄了另一次实验 ⇒ 稀疏腿四件假红。
8. **报告表的机器读者自带一个洞**：原有一行是"两件挤一行" ⇒ 解析不了 ⇒ 永远不在复核覆盖面内（零检查）。
9. **冻前 `verify-all` 第 1 趟**：见 §6（这一条是**真缺陷**级，不只是仪器）。

## §8 `NOINFO` / 边界（如实写）

1. **`nl-intent-check.sh` 的 `UNWIRED`**：在 `fp_inputs()` 覆盖面内（`FPHYG_COVERAGE_N=163`）但**未被 `verify-all` 调用**（`grep '^run_step "' … | grep -c nl-intent` = **0**）⇒ **不许算绿**；接线归 `[Next] TASK-0724`。
2. **`P02` 的落行由主控执行**（口径：本车道 `patches/P02-NEWLINE.txt` 产字节 + applier 产 after；主控搬行 ＋ 同趟重发 `declared.tsv`）。
3. **`fp_inputs()` 的成员数**不再是施工单注释里的 120/121（那是 `#33` 时代旧值）：本波 = **162 → 163**。
4. **`KNOWN-DEFECTS.md` 是主控写域、波内会动**（本波观测到 ≥6 次变更）⇒ 本报告里该件的 sha16 **只作序列证据**，不作当前值断言。
5. **`exports=550` 那一格**在本波由"单文件腿"（`tools/s3-mini.sh`）＋ 全量整波共同覆盖：单文件腿给**行为级**读数，`547→550` 由整波重建后的 `nm -D` 现读（本波 `win32shim` 位移即其证据）。

## §9 本波口径句（落册）

1. **凡「反极性／对照」腿，必须先证明它的注入点在自己那一层还活着**（切断被注入对象 ⇒ 该腿**必须翻转**）；被上游清空／覆盖 ⇒ 那条腿是**假牙**，不是证据（`D-G128` 实例①）。
2. **凡「未接线／未调用」类主张，必须把 `grep` 限定到「代码形状」**（`^run_step` 之类）；全文命中只作数量级旁证（`D-G119` 实例㉔）。
3. **凡「某物已不存在／已清空」的判据，必须由创建它的那条路径同趟检查一遍**（否则检查本身就是它的创建者）。
4. **「不做回归判定」这类节级声明，必须落在牙真正抽取的那一节里** —— 位置错了等于没写（本波现场）。
5. **波前值只能从当代 `# RE-FROZEN` 块取**；从件正文的历史行取 ⇒ 会拿到中间值。

---

## §10 冻后收口（**本段在冻结之后追加** —— 冻结件本身**一字未动**，其声明 sha `8c53d8da067472cb` 保持有效）

### §10.1 逐径推送（`git add` 逐径、**禁 `-A`**）
白名单 **11 件**（= 本波**声明**的改动件，**不从 `git status` 生成**）：
`verify-all.sh`（`f31123fac6e2c1e6`）｜`build/close-wave.sh`（`3f190c323b543275`）｜`build/MilBridge/tools/nl-intent-check.sh`（新 `44f5e87b0ed0929c`）｜`src/WpfGfx.Linux.Native/src/win32_classification.c`（`a5923b2fc07dea0b`）｜`src/WpfGfx.Linux.Native/src/win32_pts.c`（`bcb9858919e6237e`）｜`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`a31f34c113235dd3`）｜`docs/WAVE66-PREREGISTRATION.md`（新 `bf6b683d94549087`）｜`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（`8c53d8da067472cb`）｜`docs/CURRENT-STATE.md`（`15cad8c179c99258`）｜`build/MilBridge/W66-report.md`｜`build/MilBridge/tools/defect-registry-declared.tsv`（`333d8190c865eaca`）
- 逐件 `staged blob == $R 现读` ✅ 11/11；对账 `staged=11 == 白名单=11` ∧ **白名单外零改动** ✅
- 提交 **`08118d1ed4b7 → 64881eedb4fe8add21900fb6a5a4241d27be4b0c`**｜`git push` 后 `ls-remote HEAD == 本地 HEAD` ✅｜`symref=refs/heads/feat-Linux` ✅｜`porcelain=0` ✅
- **BYTECHECK（`HEAD:` 逐件核字节）`ok=11 mismatch=0 nobody=0`** ✅
- ⚠️ **不含** `docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md`（主控明说那两件等 `POST.done` 之后由主控落 ⇒ 不进本笔）。

### §10.2 app-local 同代同步（**如实记录：判词行是 `MISMATCH`，不是全绿**）
`APPSYNC=MISMATCH（MISMATCH=0[STALE=0 NEWER-DIFF=0] MISSING=0 **UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0]** DIVERGENT=0 …）`｜`OK=200`
- **app 目录侧**：`STALE=0 ∧ DIVERGENT=0 ∧ MISSING=0 ∧ MISMATCH=0` ⇒ **app-local 自身同代同步成立**。
- **那 6 条 `UNEXPECTED-EQ` 与本波无关**（机械证：mtime = **`2026-09-19 15:10:31/32`（5 条）＋ `2026-09-23 17:45:39`（1 条）**，全部**早于本波开工 `2026-09-24 18:42`**；且内容 `sha == 权威`）：`build/MilBridge/.artifacts/bin/ClosedLoop/release/`、`tests/{ResolverGuardProbe,InputTraceProbe,BboxProbe,IcuBreakParity}/bin/Release/…/DirectWrite.Linux.Provider.dll`（= `1f9511a7ef395bfe`）＋ `build/DirectWrite.Linux/FallbackCriteria/bin/Debug/WpfGfx.Linux.dll`（= `05433f1ee7e4092b`）。**都在 app 目录之外**。
- 工具自身在输出里声明这一族"**登记在册、且 `APPSYNC` 是告警不是硬判据**"（`close-wave.sh` 会长期打印 `[⚠️ APPSYNC 非 PASS]`）。
- ⇒ **本车道不把它读成绿、也不读成"我这波弄红的"**：按现读上报，**口径由主控裁定**。

### §10.3 两处哨兵
`/tmp/bridge-frozen.flag` 与 `~/wfp-runs/bridge-frozen.flag`：两处都补 `BASELINE=#66 sha16=8c53d8da067472cb` ⇒ **`cmp -s` `IDENTICAL`** ✅｜哨兵 sha16 = `66b43b62c9553a0b`。

### §10.4 冻结件**未被后续步骤改动**
`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 仍是 `8c53d8da067472cb`（= `CURRENT-STATE` 声明值）⇒ 冻后两步（推送/同步）**没有**碰它；本报告的 §10 是**报告**上的追加，不改任何冻结件。

---

## §11 app-local 口径（**主控裁定，2026-09-24 20:08**）

**本波判「过」** —— 硬判据 = `STALE=0 ∧ DIVERGENT=0 ∧ MISSING=0 ∧ MISMATCH(计数)=0`（`OK=200`）；
判词词面 `MISMATCH` 由 `UNEXPECTED=6[DECL-GAP-EQ=6]` 触发，那 6 条 mtime（`09-19`／`09-23`）**全部早于本波开工 `18:42`**、
内容 == 权威件、路径**都在 app 目录之外** ⇒ **波外既有、登记在册**。
主控另记一条「**判词词面 ≠ 硬判据**」的读法风险（待 `#67` 窗口后落册）。

> 本车道的处置留痕：上报时**按现读报 `MISMATCH`、不粉饰成 `PASS`**，也不据此判本波失败 —— 由主控裁定。
