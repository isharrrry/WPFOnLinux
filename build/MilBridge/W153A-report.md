# W153A 报告 —— 波 `#61`（**判据接线/射程波 · 零产品改动**）收尾链 ①–⑨

> 车道 `W153A`｜基线 `gen=#60 sha16=da24cb43d2123612` ⇒ 本波冻结 **`gen=#61 sha16=e4b3d8e460896bf1`**
> 放行信号：`~/w21-verify/w60-POST.done`（`2026-09-24 10:43:04`）｜落地令：主控 `10:45`（**判 A**：立刻落地、重活走槽）
> 判据（**先写**）：`~/w153a/criteria.md`｜实现草案：`~/w153a/prep.md`｜记录件：`~/w21-verify/w61-record.txt`
> **纪律**：三件**都不加步**；`src/**`／`build/shims/**`／native 源**一字节未动**；**未碰**主控写域五件。

---

## §1 三件（修前 → 修后；全部 `temp ＋ rename`）

| # | 任务 | 件 | 修前 sha16（bytes）→ 修后 sha16 | diff／锚 |
|---|---|---|---|---|
| ① | `D-G113` 假旋钮 ⇒ **connect** | `build/MilBridge/tools/geom-resend-regression-check.sh` | `cd375326b62f7982`（21,124）→ **`9e619f18dc864c7f`**（22,530） | `+25/−14`／9 hunks／**12 锚** |
| ② | `TASK-0710` `--leg=` 旁路 ⇒ **judge** | `build/MilBridge/tools/geom-revert-beat-check.sh` | `ee43a703736489a3`（44,937）→ **`ade2b2e292df2ace`**（50,544） | `+87/−18`／9 hunks／**10 锚** |
| ③ | `TASK-0711` runner **首写点截断**（方案 A） | `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh` | `ca0482bda5043909`（122,885）→ **`57180b9fad939748`**（123,318） | `+4/−1`／1 hunks／**1 锚** |
| ③b | 仓外 belt（**不落仓**） | `~/w142a/bin/run-gate.sh` | `45a3422e651096d6` → `2e9da0617328759b` | `+4/−0`／2 锚 |
| — | 四处声明同趟 | `verify-all.sh` | `970bb48ba8ebd384`（114,216）→ **`a79c1169a11ac82e`**（116,356） | — |
| — | 本波预登记（新件） | `docs/WAVE61-PREREGISTRATION.md` | — → **`d096b1c421c2cdda`**（9,536） | 标题行含 `#61` |

**逐锚核命中数**：`12 + 10 + 1`（＋belt `2`）**全部 `got=1`，0 个 0 次／>1 次**；`patch -p1 --dry-run` `rc=0`×3，真套用后件 sha16 **与预备记录逐位相同**。

## §2 两极化（**成对**；缺一即作废）

| 件 | 修前件 | 修后件 |
|---|---|---|
| ① `--fix=`／`--pre=` 对角 | 仍 **`PASS`**（两开关只改 `NOTE` 打印 = **假旋钮**） | **`FAIL` `rc=1`** |
| ① 默认档 | 逐字节相同 | **逐字节相同**（换了才变 ⇒ 成对） |
| ① `--fix==--pre` | 静默取其一 | **`USAGE_ERR` `rc=2`**（拒载） |
| ② `--leg=<语料根>` | 锚格**不判**（旁路） | **真判**（与 `--corpus=` 同口径） |
| ② `--leg=<单腿>` | 顶层被带偏 | **`NOT_APPLICABLE` 且不传染** |
| ③ **同路径连跑两趟** | **`6` → `12`**（累积 ⇒ 冻结器 `len(rows)==6` 当场失败） | **`6` → `6`**（不累积） |

**件③ 的承重机读行**（冻结前补做）：
```
WPTD_TRUNC_R2 p0fix_rows=6|6 prefix_rows=6|12 same_path=yes
```
- 修后件：`WPTD_BASELINE_OUT` **预置成已有一批 6 行**（复用场景）后连跑两趟 ⇒ `rc=0`×2、rows **6 → 6**。
- 修前件：沙箱 `~/w153a/pre-sbx/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh`
  （`cmp` 与修前快照 `ca0482bda5043909` **逐字节同一**；沙箱是**只读 symlink 农场**：`build`/`samples`/`src` 链到 `$R`，**写点全部在 `~/w153a/` 下**）⇒ 同一路径连跑两趟 rows **6 → 12**。
- ⇒ `FIX_OK=yes`／`PREFIX_OK=yes`（**两极化成对**，不是"未验／`NOINFO`"）。主控独立复算认同。

## §3 整波（槽内；`WAVE_OWNER=W153A`）

`bash build/close-wave.sh --skip-verify-all`（**`HEAVYSLOT=ACQUIRED waited=47s`／`RELEASED rc=0 held=179s`**，`OUT=/home/links-dev/wfp-runs/close-wave-104817`）：
- `[1/6] integration-wave.sh rc=0`｜`[2/6]` native 跳过（不比权威件新）｜`[3/6]` 桥**无需重发**（`d697b1e10ff48881 == d697b1e10ff48881`）
- `[4/6]` 身份自检 ✅：**应用器审计 `miss=0`**｜生成物指纹 `state=ok`｜**输入稳定性 波前==波后 == `a00bf53a64c47531963b0f82aae689fe4cee1363c7b9e670799566cb7963c668`**
- `[5/6]` 按要求跳过 verify-all｜`[6/6]` 哨兵已同步、汇总已出
- **九位位移 = 只有 `pf`**：`a1fbf721ae964f8e → d5de121c1c787193`（**同尺寸 6,123,520 B** ⇒ 环成员 `D-G92` 机械位移）；其余八位与 `#60` 冻后**逐位相同** ⇒ **无第二处位移**
- ⚠️ `[4/6]` 照旧印 **`APPSYNC 非 PASS`** —— 与 `~/w152a/logs/close-wave.log:27` **逐字同一行** ⇒ **继承自上一代、非本波引入**（如实记、不缩小）

## §4 应用级门禁 ×2（槽内、严格串行）

- `rc=0`×2、`rows=6`×2；判词行**两趟逐字相同**：
  `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`｜`WPTD_SUMMARY=PASS tiers_passed=2/2`｜`WPTD_BRIDGE_SRC_STALE=no basis=pub=d697b1e10ff48881 now=d697b1e10ff48881 so_file_match=yes`
- 两趟 rows 文件**字节不同** ⇒ 按 `#60` 的**同一条口径**剥运行戳（`date`／`loadavg`／`mem_available`／`run_dir`）后 **diff = 0 行**；判词字段 `result=PASS`／`config=…pf:d5de121c1c787193…`／`drawn=261|144`／`frames_good=14/14`／`colors=4112|2945`／`leftover_after=0` **逐字段相同**
- ⚠️ **`(tier,rep)` 载荷本身也可比**：两趟 6 行 = `default`×3 ＋ `env`×3，`result=PASS` 全 6

## §5 `verify-all`（槽内）

| 趟 | 读数 |
|---|---|
| **冻前** | **`步骤通过 34 ❌ 失败 0`**、`rc=0`、`结论：✅ 全部通过`、`用例通过 875 跳过 2`、`SKIP_GUARD=PASS`、`held=862s`；**声明类红项 = `[]`（全绿）** |
| **冻后 ×2** | 两趟各 **`34 ✅ / 0 ❌`**、`rc=0`、`结论：✅ 全部通过`、`用例通过 875 跳过 2`、无「设备上没有空间」；`BASELINESHA=PASS live=e4b3d8e460896bf1`；`DEFREG=PASS declared=152 route_ids=152` |
| **两趟对拍** | 步判词行 **35 / 35**（**先断言两侧非空** ⇒ 避开"空集恒相等"陷阱）⇒ 剥 12 类运行戳后 **`POST_TWO_IDENTICAL=yes`（diff=0）** |

- 第 `[32]` 步整行（照抄，不截断）：
  `VERIFYALL_SELF=PASS names=34 decl=34 gen=#61 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=a79c1169a11ac82e`
- 第 `[34]` 步批次：`PREREG4_SUMMARY files=42 pass=1 fail=0 na=3 skip=0 noinfo=0 out_of_scope=38`、`rc=0`
- ⚠️ **如实点一句（主控裁定：本波不动它）**：第 `[34]` 步的四态计数（`pass/na/skip/noinfo/out_of_scope`）**只在步日志里**；屏上「自报口径」只抽到 `PREREG4=PASS` ⇒ 见 `D-G117`（**排 `#63`**）。

## §6 冻结（`FREEZE_RC=0`）

```
世代交叉断言通过：树上 #60 == GENS[#61][prev]
verify-all = 34 步（通过 34 / 失败 0）／875 通过 2 跳过
门禁 6 条机读行 OK（pc:722e0ab8205b7c3f pf:d5de121c1c787193）
基线已重冻为 #61；整份 sha16 = e4b3d8e460896bf1
BASELINESHA=PASS live=e4b3d8e460896bf1 decl=e4b3d8e460896bf1｜BASELINEGEN=PASS decl_gen=#61 file_newest_gen=#61
BASELINE_BYTES=880779｜BASELINEDUP=PASS n=0
ARMLOG_SHA=PASS shape=flat required=5 declared=5 pass=5 fail=0 noinfo=0
COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=b3f264bbf43dbd61 base=e4b3d8e460896bf1 corpus=0cebc0afd5142fbf
✅ 两极化齐：冻前 BASELINE-SHA/ARM-LOG-SHA/COLUMN-FLOOR(ARMLOG) 红 ⇒ 冻后同一批检查器都绿
```
- **记录模板先建后冻**：`~/w21-verify/w61-record.txt`（`44558ad7536c09e1`；`===FROZEN===` 段内 **8 条外挂声明** = `COLUMN-FLOOR`×2／`COLUMN-CORPUS`×1／`ARM-LOG-SHA`×5，**全部落在 `# RE-FROZEN` 块内**；占位符**全部**在冻结器 `fmt` 词汇表内、正文**无 `${VAR}`**）。
- **改冻结器前先备份**：`~/w153a/pre/w27-freeze.py.before-61`（`33ea1c4991639ba8`）＋ `.before-61-apply`；`GENS['#61']` 加后 `33ea1c4991639ba8 → 9f656976c0d5fefd`，语法自检 `OK`。
- `~/w153a/w61-pre.sha`（9 行 `<path> <sha16>`，`953628faab7d243b`）与 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:13` 的九位声明 **9/9 相同**。
  ⚠️ 主控曾把该行引成 `:14`；现场 **`:13` = 九位声明行**、`:14` = "相对 `#59` 冻结值"行 —— **主控已认领该笔误**（会自行更正），本报告按 `:13` 记。

## §7 推送／app-local／哨兵

- **逐径推送**（`git add` **逐路径**、绝不 `-A`）：`porcelain=8` **==** `diff --cached --name-only=8`（7 件 ＋ `build/wave-audit.log`）；commit **`34171e51f4891af9c3b46d70abc556f21bdc6c2d`**；`6f2b482..34171e5`（**快进、无 `--force`**）。
- **一致性**：`local == origin/feat-Linux == ls-remote == 34171e5…`；`ls-remote --symref origin HEAD` ⇒ **`feat-Linux`**；`porcelain=0`。
- **`BYTECHECK ok=8 mismatch=0 nobody=0`**（口径：`git cat-file blob HEAD:<path>` vs `$R` 磁盘，逐件 `cmp`）。
- **app-local**：`APPLY_RC=0`｜`APPSYNC-REFRESH=refreshed=0 newer=0 applied=1`｜
  `APPSYNC=MISMATCH（MISMATCH=0[STALE=0 NEWER-DIFF=0] MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0] DIVERGENT=0 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0）`
  ⇒ **`STALE=0 DIVERGENT=0 MISMATCH=0 MISSING=0`**；`CHECK_RC=1` 由**登记在册**的 `UNEXPECTED=6[DECL-GAP-EQ=6]` 决定（与 `#60` 形态逐字相同 ⇒ **继承**）。
- **两处哨兵**（`/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag`）：`cmp` **IDENTICAL**；九位逐位复核 **9/9**（含新 `PF=d5de121c1c787193`）；按格式**手工补** `BASELINE=#61 sha16=e4b3d8e460896bf1 bytes=880779`。

## §8 `NOINFO`／边界（照录，不许缩小）

1. **件① 只证**"开关接进了判据"；**不证**任何语料层面的回归结论（那要臂/腿数/功效 ⇒ `D-G116`，**排 `#63`**）。
2. **件② 只证**"派生语料会真判、单腿格不传染"；**不证**该语料本身的代表性。
3. **件③ 只证**"行数不再增长"；**不证**冻结器今后不会被别的写点撑破。
4. 第 `[32]`／`[33]` 两步**只读**语料与台账（**不跑应用腿、不碰 `dotnet`**）⇒ 它们的绿**不**等于产品行为正常。
5. **`D-G115` 修法／`D-G116` 跨臂体制牙／`known-red.json` 陈旧 `why` 重钉 ⇒ 排 `#63`**（主控明令不在本波范围）。
6. **源级反极性**（对判据件逐字节复原再重建）：属"改门禁"，必须安排在 `IN_FP_0` 之前 ⇒ **本波不做**（点名缺这一格）。

## §9 口径句（落册，均来自现场实测）

1. **"闸门字面满足 ≠ 可以写共享 `$R`"**：写前须确认**链/槽不在跑** ∧ **上一代 `POST.done` 已出**；本波现场：我按字面 `gen=#61` 就写过 1 件、随后 `mv` 出（**零损伤但如实入册**）；后由主控**显式放宽为 A** 并提供"无交集"的机械依据 ⇒ 我**先等槽释放**再落地（**不绕过自己事先写死的闸**）。
2. **"能造出假绿的旋钮不许留"**：①"只改打印不改判据"的开关、②"一个格的不适用传染成顶层不适用"的旁路、③`>>` 复用同一路径把行数撑过冻结器上限 —— 三者同族；修法都是**把接口接死＋加严参数面**（未知参数/同值 ⇒ 拒绝运行），而**不是**加一行注释说明。
3. **逐锚核命中数时，"锚"要按生成器真正用的那一串数**：本波 3 份补丁的 **hunk 数**（9/9/1）与**锚数**（12/10/1）不同 —— 报数时**两者都写**，否则后人按另一种口径复算会对不上。

## §10 交付物 sha16（现场现算）

| 件 | sha16 |
|---|---|
| `docs/WAVE61-PREREGISTRATION.md`（仓内新件） | `d096b1c421c2cdda` |
| `verify-all.sh`（仓内） | `a79c1169a11ac82e` |
| 两件牙（仓内） | `9e619f18dc864c7f`／`ade2b2e292df2ace` |
| 仓内 runner | `57180b9fad939748` |
| 冻结基线 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `e4b3d8e460896bf1`（880,779 B） |
| `~/w21-verify/w61-record.txt` | `44558ad7536c09e1` |
| 判据 `~/w153a/criteria.md`（仓外） | `70f82d0ae740fb73` |
| 实现草案 `~/w153a/prep.md`（仓外） | `11b3d7a53fcd99c9` |
| 本报告 `build/MilBridge/W153A-report.md` | 见本件末行（口径 `head -n -1`） |

**零残留**：无本车道遗留 `dotnet`／`verify-all`／`close-wave`／`Xvfb :2xx` 进程（按 `/proc/*/cmdline` 的 **argv0** 判、**未用** `pgrep -f`／`pkill`）；`/tmp/.X11-unix/` 只有别人的 `X0 X1 X97 X99`。

`W153A-report.md` sha16（去自身行口径 `head -n -1`）= `c50e2e6d8759c772`
