# 波 `#74` 报告 —— `TASK-0733`「装置临时件**自清理** ＋ 长跑前**磁盘余量闸**」＋ `TASK-0734`「`NA` 必须**写成声明**才算」＋ `TASK-0735`「软形态残余洞**可见**」

> 车道 **W172A**（唯一写者）｜`state=DONE`｜`CRITERIA_FIRST=yes`（判据 `~/w172a/criteria.md` ＋ 正本 `docs/WAVE74-PREREGISTRATION.md`）
> 权威树 `$R`（**不是 git 仓**）｜报告为**纯 Markdown**（无 JSON／schemaJson／UI 卡片）

## §1 我做了什么（逐条命令 ＋ 现算读数）

| # | 动作 | 现算读数 |
|---|---|---|
| 1 | 继承包**完整性核查** | ENOSPC 窗口 `find ~/w166a/{w73,w74} -newermt '09-25 10:20' ! -newermt '09-25 10:35'` = **0 命中**；587 件里 7 个 0 B **全是本就该空的日志**（`app.log`×4／`landing.lock`／`e.txt`／`stderr.txt`）⇒ **无证据件受损** |
| 2 | 两件基底**现取对照** | `r-gate-step.sh aa9d7188b6b01a2f`（41531 B／`%h=1`）**== 包基底**；`prereg-four-requirements-check.sh a40aac9031304a8f`（30488 B／`%h=1`）**== 包基底** ⇒ **无需重锚**；补丁 `eafadc1cb3884749`／`d4cd80c33d57919d`，`bash -n` OK，**`--selftest` 我亲手复跑** `27/27`×2 |
| 3 | 落仓 5 件（`temp`＋`rename`、写前 `%h==1`、写后现算） | `r-gate-step.sh` → **`eafadc1cb3884749`**｜`prereg-four-requirements-check.sh` → **`56f23e0704232675`**（含候选 `w74b`）｜`close-wave.sh` `086f89e13d8e5522` → **`eda17e5916770d9d`**（白名单 **+3 行**）｜`verify-all.sh` `f9bc5bca5be3d7f2` → **`0c5034591d30642a`**｜`docs/WAVE74-PREREGISTRATION.md` **新建** `1a87743ebdc72a04` |
| 4 | 四处声明**同趟** | 首行 `DECL` = `# VERIFYALL-STEPS-DECL: 42 gen=#74`（插在现行第一行之前）｜头注释口径句 `**\`#74\` 收官起 = 42 步**`｜`STEP-NAMES` **一字未动**｜预登记标题含 `#74`。**步数不变量：首行 `DECL` 42 == `grep -c '^run_step "'` 42** |
| 5 | **显式扩面**（主控裁定 (B)） | `fp_inputs()` 白名单 +3 行 ⇒ 覆盖面 **194 → 197**；**同趟**改第 `[42]` 步 `--expect 194 → 197`；`[12] coverage_n=197` ∧ `[42] files_n=197 declared_expect=197` |
| 6 | **收口判据**（不是"我加了三行"） | 42 条 `run_step` 行抽仓内件 × 197 件活清单 ⇒ **未被覆盖面保护的接线件 = 0**（命令逐字见预登记 §1.3） |
| 7 | 链（**重活走槽**） | wave `rc=0`（`held=189s`；**输入稳定性：波前==波后 == `ddf3cd2b0cef2dce…`**）→ gateapp ×2 `rows=6/6` ∧ `tiers_passed=2/2` ∧ `acceptance=2/2` ∧ `GATE_LINES_IDENTICAL=yes` → gate1／gate2／pre **各 `步骤通过 42 ❌ 失败 0` ∧ `结论：✅ 全部通过`**（gate1≡gate2 判词行归一化后逐字相同） |
| 8 | **冻结** | `FREEZE_RC=0`：`f747350edf97a74a` → **`8b303228ff088349`**，`gen=#74`；九位**只有环成员 `pf`** 位移（`4c45500d413e31e7 → d9e69320cf29924a`）⇒ **零产品位移** |

## §2 判据与两极化（含判否结果）

**`TASK-0733`（10 腿真跑，`~/w172a/logs/pol0733-run{1,2,3}.txt`）**：默认档 `fate=cleaned-on-exit` ∧ **本趟目录消失** ✅｜`--keep` ⇒ 目录保留 ∧ `R_GATE_OUT_KEPT` 逐字同路径 ✅｜**两趟 `REP_IDENTICAL=yes`**（归一化 `mktemp` 后缀与活 `df` 读数后）｜真小容量 FS `/run/lock`（5 MB）⇒ `DISK_HEADROOM=FAIL avail_gb=0 avail_kb=5116` ＋ **`rc=2`** ∧ **装置一次未跑**（`DEVICE_CALLED=no`）✅｜阈值抬到现场之上（`999999`）⇒ 同判 ✅｜桩 `df` 不可解析 ⇒ `DISK_HEADROOM=NOINFO reason=df-unparsable` ＋ `rc=2` ✅｜预置**过期**件必删、**新鲜／非前缀／符号链接**必留且不跟随（`removed=1 kept=3`）✅｜**只换被判件＝基件** ⇒ 证据目录**必留** ∧ **零 `fate` 行零 `DISK_HEADROOM` 行**（旧版泄漏本体）✅｜调用者 `OUT` 指到 5 MB FS ⇒ `FAIL` ∧ 未建目录 ✅。**无一条判否。**

**`TASK-0734`／`0735`（七夹具成对 ＝ 修前臂 `a40aac9031304a8f` → 落仓件）**：`提及` `NA→FAIL`｜`锚定句` `NA→NA`（**带** `residual=self-negation-not-checked`）｜`机读行 yes` `NA→NA`（**不带**）｜`声明＋证据` `FAIL→FAIL`（**未放宽**）｜`none`／`空值`／`句中令牌` `NA→FAIL`。**无一条判否。**

**🔴 射程扫描命中并上报（本波最有价值的一条）**：收紧后的牙对全量语料跑，**`docs/WAVE72-PREREGISTRATION.md` 从 `NA` 变 `FAIL`**。根因现取：该件 `:20` 是 **`PREREG-NO-REGRESSION-DECISION: yes`（整行机读行，被一对反引号包成行内代码）** ⇒ 行首锚点剥的装饰类 `[[:space:]>#*|!-]`＋emoji＋`§：`＋数字＋`.` **独独漏了行内代码定界符**。**爆炸半径我实测**：`--gate` 批次 **`rc=1`** ⇒ `verify-all` 第 `[34]` 步当场红 ⇒ **本波冻不了**。⇒ **停手报主控**（判据 H14 的判否条件）；主控裁定 **(A) 批候选 `w74b`**（**只认整行被一对反引号包裹**；只一端 ⇒ 不剥、`FAIL`；散文那一支与值检查**一字未动**；并把**可接受装饰形态清单**写进件头）。修后：**`BATCH_RC=0`**｜`files=55 pass=1 fail=0 na=16 out_of_scope=38`｜**`NA→FAIL N=0`**｜`WAVE72 ⇒ NA form=machine-line(yes)` 且**无 `residual=`**｜`--selftest 27 → 31`（既有例 `only_in_arm_base=0`）。

## §3 关键读数表（值 ＋ 出处命令）

| 项 | 值 | 出处 |
|---|---|---|
| 覆盖面 | **197** | `fp-manifest-step.sh --expect 197` ⇒ `names_n=197 would_be_fp=ddf3cd2b0cef2dce` |
| `inputs_fp` | `ddf3cd2b0cef2dcef2de454fbe2f31f578174459de263dd807853447a19d945d` | 整波自印「波前输入指纹」== 独立复算 == `GENS['#74']['infp']`（三方互证） |
| 判词 | 三趟 `42 ✅/0 ❌` ∧ `结论：✅ 全部通过` | `w74-gate1/gate2/pre-*.log` |
| 未保护接线件 | **0** | `logs/census/{refs,cov,uncovered}.txt` |
| 基线 | `8b303228ff088349`（`gen=#74`） | `sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` |
| `PREVCHECK` | `PREVCHECK=PASS gen=#74 keys=7 base=f747350edf97a74a` | 生产冻结路径 `w74-freeze.py.out` |
| **替代核** | `PREVCHECK_SUBST key=prev_infp src=GENS[#73].infp value=17f0abdb… eq=yes` | 车道冻结驱动（逐字断言 `prev_infp_subst == GENS['#73']['infp']`） |
| 九位 | 8 位逐位未变；`pf` `4c45500d413e31e7 → d9e69320cf29924a` | 冻后块九位行（`D-G119` 实例㉕：只从块内/`BASELINE tier=` 取） |
| `/tmp/r-gate-*` | 开工前 **32 件 / 3382 MB** → 现在 **0 件**（`/tmp` 7625 → 4603 MB） | 我**不声称**是自己这一趟清的（无日志证据：`R_GATE_JANITOR` 行不进 `verify-all` 的"自报口径"面；主控也说过同步回收）⇒ 只作**观察**留档 |

## §4 我没做到的（逐条 `NOINFO` 及原因）

1. **`PREVCHECK` 的 `keys=7` 是"源表大小"、不是"实核集"** —— freezer 印 `keys=len(_PREV_SRC)`，同时打 `⚠️ GENS[#74] 没有 prev_infp ⇒ 本代不核它`。本代实况 ＝ **6 键主来源 ＋ 1 键（声明的）替代来源**。⇒ 如实标注；**建议按 `D-G146` 族入册**（`keys=` 必须等于实核集，或改印 `keys=7(checked=6,skipped=prev_infp)`）。冻结器在**主控写域**，我未动。
2. **`prev_infp` 主来源不可用** —— `#73` 冻结块的记录模板把该字段写成**位移句**（``` `inputs_fp` `旧` → `新` ```）而非**机读形态**（`` `inputs_fp` = `<64hex>` ``）⇒ `PREVCHECK=REFUSE HITS!=1` ⇒ 首次冻结被**拒**（基线零字节改动）。**前向修已做**：`~/w21-verify/w74-record.txt` 的 FROZEN 段带上了机读形态（渲染后正则命中 **1**）⇒ **`#75` 起恢复主来源**；并按主控口径把这段写进预登记／本报告／基线记录。
3. **`janitor` 的射程** —— 只清**同前缀**（`r-gate-step*`）**且 TTL 过期**的目录；它**判不了**"别的前缀／别的车道的残留越堆越多"，也**不是**通用临时件回收器。
4. **`NA` 形态只判形态** —— `0734`／`0735` **判不了作者真心**；残余洞（行首声明句**随后自我否定**）**按裁定不修**，只做可见性。
5. **`0733` 的真装置未跑真应用** —— 两极化用**桩装置**（零 X、零 dotnet）证明"回收／闸门／所有权／rc"这一层；**真应用那一段**由波内第 `[26]` 步 `R-GATE` 承担（本波链里 `R_GATE=PASS crit=13/13`、`DISK_HEADROOM=PASS avail_gb=19 paths=2`）⇒ 桩读数**不是**应用读数。
6. **`/tmp/r-gate-*` 清零的归因** —— 见 §3 末行：**观察**，不归因。

## §5 自伤（如实留档；都被自己的断言/牙当场咬住）

1. **落仓器锚点撞车**：第一版改 `--expect` 用的锚是 `--expect 194` ⇒ 命中 **2** 次（**我自己新插的 `DECL` 文本里也写了"194 → 197"**）⇒ 落仓器 **`rc=9` 拒写**、`verify-all.sh` **一字未动**（无半成品）⇒ 改用只属于那一步的锚 `fp-manifest-step.sh --expect 194`。
2. **预登记机读行的粗体包裹**：我最初写成 `**PREREG-NO-REGRESSION-DECISION: …**` ⇒ `form=` 值尾部多出 `**`（**读出脏**）⇒ 改裸行。
3. **恒真断言**：我的落仓自检里一度写了 `sha16(X) != sha16(X)` 这类**恒真**式 ⇒ 立刻删掉换真检查（**不许拿恒真断言冒充强判据**）。
4. **`QUOTE-TRAP` 同族三处**（本波主线之一就是"引号陷阱"的邻居）：冻结驱动 `say` 里**双引号内写反引号**（`check_prev_values()`／`#73`／旁白里的 `fp_inputs()`）⇒ 命令替换吃掉诊断并报"未预期的文件结束符"；**只影响旁白、未影响判据**；现读该形态 **0**。另：补丁脚本 Python 双引号串内写 ASCII 引号 ⇒ `SyntaxError`（**写盘前**退出，未污染 `$R`）。
5. **`{INFP_PREV}` 的渲染陷阱**：撤键后 freezer 的 `G.get('prev_infp', G['infp'])` 会把旧值渲染成**新值**（"新==新"的假陈述）⇒ 我把模板里两处该占位符改成**字面值**。
6. **链日志抬头误印 `W73 CHAIN`**（生成 driver 时漏改大写）—— 纯字面、留档不改。
7. **`keys=7` 标签**（见 §4.1）—— 不是我的伤，但**是"形状完好的假读数"**，我如实上报而不是拿它当"7/7 全核"的凭证。

## §6 大白话小结（≤5 行）

1. 那颗会撑满宿主盘的临时目录牙，现在**跑完就收**、旧残留按 TTL 自己清，**长跑前先看余量**（不够就亮红、绝不放行）。
2. 跳过"回归判定四要件"的那道门，现在**只有写成声明才打得开**；"提到一句"不再算数，软形态还会**自己标出残余洞**。
3. 全量语料一扫，**抓到一件历史件被新规则误杀**（被反引号包起来的整条机读行）—— 报了、修了**形态清单**，而不是去改历史件。
4. 顺手把**三件"在门禁里承重却没人看着"**的接线件收进覆盖面，并把收口判据定成**"未保护件 = 0"**（可复跑）。
5. 冻结时被上一代记录件的一条**缺形态**挡下 ⇒ **拒冻、基线零字节改动**；换源核过之后才冻 —— **守卫按它该有的样子工作了**。

## §7 冻后链（全绿；本节为**推送后追补**，与小节同批的第二笔提交一并推送）

| 阶段 | 读数 |
|---|---|
| 冻后 `verify-all` ×2 | **各 `步骤通过 42 ❌ 失败 0` ∧ `结论：✅ 全部通过`**｜`BASELINESHA=PASS live=8b303228ff088349 decl=8b303228ff088349`｜`[12] coverage_n=197`｜`[42] declared_expect=197`｜两趟判词行（归一化 `wall_s=`）**逐字相同 ⇒ `GATE_LINES_IDENTICAL=yes`**｜`DEFREG=PASS declared=181 route_ids=181`（主控重发的 `tsv`）｜**无 `DECLDRIFT` 红** |
| `w74-POST.done` | 真 `stat`：`size=0 mtime=2026-09-26 10:45:58` |
| 逐径推送 | `c4789d68…` → **`66a7cd8702c7f54ba118ba783f9669c442de429a`**；`staged == 白名单`（8 件）∧ **主控五件不在白名单**；远端 == 本地；**`BYTECHECK ok=8 mismatch=0`**；`porcelain=0` |
| app-local | `check-applocal-sync` ⇒ **`STALE=0 ∧ DIVERGENT=0`** 达标（`APPSYNC=MISMATCH` 为**在册**告警，非本波引入） |
| 两哨兵 | `/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag` 补 `BASELINE=#74` ／ `BASELINE_SHA16=8b303228ff088349` ⇒ **`cmp = IDENTICAL`** |
| `D-G139` 显示位/进程卫生 | 链期自起三个 `Xvfb` **按 PID** 收净：`1917743`(`:99`)／`2266371`(`:236`)／`2779085`(`:97`)；收后 **`ps -eo args | grep '^Xvfb :'` 命中 0** ∧ **`/tmp/.X11-unix` = `X0 X1 X10 X239`** ⇒ **与链前基线逐项相同（`D-G139=PASS`）**；存活复核用 **`ps -o pid= -p <PIDs>`（不带 `-e`）** |
| 覆盖面漂移复核 | 主控批次落的六件（`KNOWN-DEFECTS.md`／`ROUTES.md`／`README.md`／`HANDOFF-NEXT.md`／`docs/unimplemented.md`／`defect-registry-declared.tsv`）**逐件不在覆盖面内**（现取 `grep -c <name> manifest.txt` 全 **0**）∧ 现算 `would_be_fp=ddf3cd2b0cef2dce` **仍等于**冻结块声明值 ⇒ **无漂移** |

LANE=W172A TASK=0733+0734+0735 R_TOUCHED=build/MilBridge/tools/r-gate-step.sh,build/MilBridge/tools/prereg-four-requirements-check.sh,build/close-wave.sh,verify-all.sh,docs/WAVE74-PREREGISTRATION.md,samples/WpfTextDemo/ACCEPTANCE-BASELINE.md,docs/CURRENT-STATE.md,build/MilBridge/W74-report.md DONE=yes NOINFO=6
