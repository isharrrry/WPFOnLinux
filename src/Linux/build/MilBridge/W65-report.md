# 波 `#65` 报告（`W153A-RATES2` 唯一 owner；**进行中**）

**车道**：`W153A-RATES2`｜**写域**：`build/MilBridge/tools/**`（牙／台账／两件交来的牙）＋ `build/close-wave.sh`（白名单 +1 行）＋ `docs/PREREG-TEMPLATE.md` ＋ `docs/WAVE65-PREREGISTRATION.md`（裁定②扩展）＋ `verify-all.sh`（四处声明）＋ 本报告
**未碰**：`ROUTES.md`／`KNOWN-DEFECTS.md`／`declared.tsv`／`HANDOFF-NEXT.md`（按令留给主控）＋ 任何产品件（`src/**`／`build/shims/**`）

## ① 落地（6 件；`land_w65.py`，temp+rename ＋ 前后 sha 双断言）

```
shell-quote-trap-check.sh     d4317aa7605a31e1 → 39a2e2cdf1948675  （W152A 交，按 sha 逐字节应用）
fp-manifest-teeth-check.sh    (不存在)           → be19edddf7f02797  （新建）
close-wave.sh                 168a33c3d4743559 → 9dfc1e43b4d67fbf  （fp_inputs 白名单 +1 行）
baseline-rate-gate.sh         31cf77abc6a882e3 → 1bad58c07a8264e6  （D-G125 ＋ DECL_UPPER ＋ 四不变量 ＋ 3‑9 改判）
baseline-rate-cases.tsv       8d71171d475a63dc → 1a2df056f5677344  （原 11 行逐字节不动 ＋ 新块 legacy_rows=11 ⇒ 21 行）
docs/PREREG-TEMPLATE.md       17927a59d050fc83 → 300ec21903d54756  （三栏；212 → 223 行）
```

**回读自测**：牙 `BASELINERATE_SELFTEST=PASS`（`bad_ledger_rc=1`／`SELFTEST_DG121_CASES_rc=0`）｜`shell-quote-trap` `41/41` ＋ `ST_ATTEST=PASS`｜`fp-manifest-teeth` `13/13`｜模板落定 sha16 与**数小时前的 DRY-RUN 逐字节相同**。

## ② `D-G126`（我自己的违约）＋ 补救件

**事实（不豁免）**：第一轮备份只备 5 件，**漏了 `shell-quote-trap-check.sh`**（备份清单写在我读 GO **之前**）⇒ 该件在**无备份**状态下被覆盖。
**补救**：fork 克隆 `HEAD:` 该件 = `d4317aa7605a31e1`（与覆盖前现读逐位相同，已由主控独立现核）＋ `~/w152a/w65/backup/…orig` = 同值。
**补救件（主控所派）**：`backup_guard.py` —— **落地前**断言"每件都有备份 ∧ 备份 sha16 == 覆盖前现读 sha16"，缺一即**拒落**。
**两极化（在**影子树**上跑，正例才成立）**：

```
正例（影子树 == 落地前 ∧ 备份齐备）        ⇒ 拒落 0        ✓
反例 A（备份缺失：临时移开该件的备份）      ⇒ 拒落 1（点名）✓
反例 B（备份错版本：改掉影子树里那一件）    ⇒ 拒落 1（点名）✓
BACKUP-GUARD-POLARITY=OK
```

## ③ `inputs_fp` 成对记账

```
before = f148203453b092206b6a9f9529821fa58570ba7035fb5253ca4f4e8da6dd77ae （161）
after  = 4c1056ddca8afc700df3f0777a2c134932a5fc2ddcfc7d1192c38940e3c15fd5 （162）  == after_predicted ✓
交叉表 32 行／16 值：全部退回 ⇒ 逐位 == before ✓；与仪表 attrib 交叉核一致 ✓
+1 行归因：close-wave.sh 的 fp_inputs 白名单多一行 fp-manifest-teeth-check.sh
```

## ④ ⚠️ 落地后首趟 `verify-all`：**36 ✅ / 1 ❌**（成因＝我自己，已修）

```
❌ 失败项：PREREG-FOUR-REQ       （步骤通过 36 ／ 失败 1；用例通过 875 跳过 2）
```

**根因**：我新建的 `docs/WAVE65-PREREGISTRATION.md` **缺「不做回归判定」声明** ⇒ `prereg-four-requirements-check.sh` 判 `missing=7`（缺 `PREREG-REGRESSION-FOUR:` ／四要件逐项／`regression-decision.py` 指名／`REGRESSION` 词）。
**修法**：补 `## §8 「不做回归判定」声明`（`PREREG-NO-REGRESSION-DECISION:` ＋ 逐字「本波不做任何回归判定」；本波**确实**无被试件/无对照臂 ⇒ `N/A` 正确）。
**修后**：`PREREG4=NA rc=0`（`na=1` 与 `pass` **分开计数**）✓
**⚠️ 这是"新预登记件缺 N/A 声明"这一类缺陷的现场第一例 —— 不是产品/判据问题。** 记：**建预登记件时必须同趟带该声明**。

## ⑤ `UNWIRED` 声明 ＋ 接线决策表（裁定①逐字要求）

**`UNWIRED`**：`build/MilBridge/tools/fp-manifest-teeth-check.sh` **在 `fp_inputs()` 覆盖面内（第 263 行）但 `verify-all.sh` 里 `grep -c` = 0（未被调用）**；
正常运行读数 = **`FP_MANIFEST_TEETH=NOINFO reason=no-manifest`（`rc=2`）** ⇒ **既不算绿也不算红** ⇒ **任何汇总不许把它算绿**；接线归 `TASK-0724`。

| 清单来源 | 动 `close-wave.sh`？ | 动 `inputs_fp`？ | 漏改时红在哪步 |
|---|---|---|---|
| **`--paths FILE`**（`fp_inputs()` 尾 `tee`） | **是**（自含于覆盖面） | **是**（`after_predicted` 作废，须重算） | 第 `[11]` 步 `VERIFYALL-SELF` ＋ `FP-INPUTS-HYGIENE` ＋ 指纹对账 |
| **`--expect N`**（牙头推荐，显式常数） | **否**（`verify-all.sh` 不在覆盖面） | **否** | 新增一步（`37→38`）⇒ 漏改四处声明 ⇒ 第 `[11]` 步 **`NOINFO`**（缺声明 ≠ 通过） |

## ⑥ 施工必记 8 条（前 7 条照录 ＋ 第 8 条本波新增）

1 镜像 `not-reached` 不许带过来｜2 自检沙箱那一行不许带过来｜3 故障注入须断言真的改变行为｜4 区间替换核对末行｜5 构造期守卫｜6 改源必重建｜7 3‑9 改严不是读数反复｜**8 备份清单必须在读完全部落地目标之后才动手（`D-G126`）**｜**9（本波新增）建预登记件必须同趟带 `PREREG-NO-REGRESSION-DECISION:` 声明**。

## ⑦ 进行中／待做

```
✅ 落地 6 件 ＋ 回读 ＋ 成对记账 ＋ `D-G126` 补救件（4/4 两极化）
✅ `docs/WAVE65-PREREGISTRATION.md`（40a8f0677ae76056）＋ 该步 `PREREG4=NA rc=0`
🔄 verify-all 第二趟（修正后）**在槽队列里等**（槽上有 W70A 探针与 W158A 的重活 ⇒ 队列 3 条）
⏳ 整波（走槽）→ 门禁 ×2 → 冻前 verify-all（期望 37 ✅/0 ❌）→ `GENS['#65']` ＋ `w65-record.txt` → 冻结 → **立刻报主控** → 冻后 ×2 → POST.done → 推送 → app-local → 两哨兵
```

**另**：`W70A`／`W158A` 正持有/排队重活槽（我入场时链=无、槽=FREE ⇒ **这是本波期间新出现的队列压力**，如实记，供主控调度参考）。

## ⑧ 报告更正 ＋ 纪律合规（主控指正后）

- **口径更正**：预登记件的 `#64` 计数应为 **标题行命中 0 ∧ 正文 1 次**（`:111` 解释性引用；我先前报"0"是在 §8 补写**之前**量的 ⇒ 跨版本读数失效）。**判据影响 = 无**（该牙只看标题行）。详见 `docs/WAVE65-PREREGISTRATION.md §9`。
- **硬链接纪律（主控新装置缺陷）**：我这边**全部副本/备份 `%h=1`**（真复制），**从未用过 `cp -al`/`ln`**；本波落地一律 **temp+rename** ⇒ 与备份的 inode **不同**（`close-wave.sh` 备份 ino=8410832 vs `$R` ino=4933808）⇒ **没有写穿**。`$R` 里我落的件现读 `%h=2~4`（`WAVE65-PREREGISTRATION.md` 2／`W65-report.md` 3／`baseline-rate-gate.sh` 4／`shell-quote-trap-check.sh` 4）**来自他人的 `cp -al` 影子农场，不是我**；本件与预登记件的改写**都用 temp+rename**（换 inode、不写穿）。

## ⑨ 【落地后证据】本波落的牙在**落地当小时**就吃到一条真陷阱（**来源 = 车道 W158A 的自报，不是我推断**）

**出处**：车道 **W158A** 自报（主控转来）。**本波落的** `build/MilBridge/tools/shell-quote-trap-check.sh`（`39a2e2cdf1948675`）扫**它的写域**：

```
修前： FAIL reason=dq-backtick traps=6      （6 条全在 W158A 自己的件里，rc=1）
修后： PASS traps=0                          （rc=0）
旁证： `bash -n` 两次都**静默**（⇒ 印证 `bash -n` 不是判据；这正是该牙存在的理由）
形态： `say` 行里**未转义反引号** ⇒ 双引号内触发命令替换（现场 `apply.sh: 251: P03X: 未找到命令`）
```

⚠️ **时序与归属（逐字，不许越界）**：本条是**落地之后**才发生的证据 ⇒ **只写在本报告的"落地后"段**，
**不写进 `docs/WAVE65-PREREGISTRATION.md` 的「判据先写」段**（那会破坏该件的时序声明）。
**归因**：现场读数**由 W158A 自报**，本车道**只登记、未独立复跑**该件的两极化（`traps=6 → 0`）——如实标。
**意义**：本波落的牙**不是"落地即封存"**：它在**同一小时内**对**别的车道的写域**产生了真判据（**6 条真陷阱**）。

## ⑩ 链条读数（逐项现取；本段随链条推进追加）

**① 第二趟 `verify-all`（落地后、修正 N/A 声明后）= 全绿**
```
步骤通过 37  ❌ 失败 0     用例通过 875  跳过 2      结论：✅ 全部通过      rc=0  held=1035s
```
**② `verify-all.sh` 世代声明 = 两处（不是一处）**（判据件第三条硬要求逼出来的）
```
只加 DECL 行 ⇒ VERIFYALL_SELF=NOINFO reason=header-prose-absent gen=#65 现场=37
再补头注释口径句 **`#65` 收官起 = 37 步** ⇒ VERIFYALL_SELF=PASS names=37 decl=37 gen=#65 dup=0 order=OK prose=OK prereg=PASS
件 sha16：6a8ae4e80fefd97b →（+DECL）c525958090f1ca17 →（+口径句）79e4780086588fcb
（两次都 temp+rename；%h 2 → 1 ⇒ 换 inode、**未写穿**别人的影子树；inputs_fp 全程 == 4c1056dd…）
```
**③ 整波 `close-wave.sh --skip-verify-all`（槽内）= rc=0 held=263s**；`输入稳定性：波前==波后 == 4c1056dd…` ✓
**④ 九位位移 = 只有 `pf`**（环成员）：`02b2792448fbd41d` → **`59ba7d2997fcdd62`**，**同尺寸 6,123,520 B** ✓；其余八位逐位未变 ⇒ 符合 `allow_changed={'pf'}`／`pf_required=True`。
**⑤ 应用级门禁 ×2（槽内串行）= 两趟全 PASS**
```
pass1 rc=0 rows=6   WPTD_SUMMARY=PASS tiers_passed=2/2   WPTD_GATE=PASS acceptance=2/2 line_advance=PASS
pass2 rc=0 rows=6   同上
GATE_LINES_IDENTICAL=yes（判词行逐字一致）
ROWS_IDENTICAL=no —— **仅 `rundir=` 与头注释（时间戳/loadavg/mem）不同**；6 条 `BASELINE` 行的**全部测量字段一致**
   （result=PASS／exit=143／drawn=261,144／notdrawn=0／frames_good=14／frames_blank=0／capture=ok／scroll=ok／
     shot_dims=938x938／colors=4112,2945／cross_ae=0／leftover_after=0／pc:722e0ab8205b7c3f／pf:59ba7d2997fcdd62）
```
**⑥ 冻前 `verify-all`**：第一趟**被会话生命周期带走**（我自己事故：把 17 min 的等待写成回合内前台循环；停在 `[5]`、无 `rc` 痕迹）
⇒ 主控改由**托管后台作业**重启（`logs/verify-all-prefreeze2.log`）；本车道按**新硬规则**把"等待＋守卫＋冻结"整体写进**托管脚本** `freeze65.sh`（PID `1291109`，日志 `logs/freeze65.out`，标记 `freeze65.DONE`／`freeze65.STOP`）。
## ⑪ 【落地后独立复验】车道 W152A-W65 的只读 POST-LAND（**来源 = 它的报告，主控已现核 `cmp`**）

```
§ 落地后独立复验（车道 W152A-W65，只读；取数 2026-09-24 18:09–18:13，全量 ~/w152a/w65/logs/20-postland.txt 78 行）
- 落点两件 `39a2e2cdf1948675`／`be19edddf7f02797`：与它作者件 `cmp` **逐字节相同**；自测 41/41、13/13，真 rc=0。
- 用**落点件**复跑两极化：`pos.sh` ⇒ FAIL reason=continuation-comment ∧ 点名 line=14 col=5；
  对照 = 它留的**补丁前原件** `d4317aa7605a31e1` ⇒ PASS traps=0（**旧件全盲**）；`neg.sh` ⇒ PASS traps=0。
- 扫树：files=165 sh=80 py=85 ／ traps=0 ／ diag=71 ／ probes=31 cc_fired=24,30 ⇒ 与落仓预期逐项命中；覆盖面 162。
- ★ 覆盖面位移的**第三方佐证**：seg_sha16 758f0d3843202bbe → c9f0c90bf447e08d、段 28→29 行、名字 33→34、161→162，
  `diff` 全文只有一行 `> build/MilBridge/tools/fp-manifest-teeth-check.sh \` ⇒ 本波"+1 行"由独立复验复现。
  ⚠️ 口径：`ANCHOR_SAMPLE=same` 是"与上一次抽样比"（那次已在 #65 之后）⇒ 跨世代位移必须看成对值。
- 成本：一次"污染趟"≈5–6 s（游离命令＝整趟树扫描 ＋ 867 个假名喂 sha256sum）⇒ 整件 58–62 s，按纪律走后台作业。
```

**另记它的两条"字面量脱钩"自纠**（与 `D-G131` 同族，属"**结论里写死的字面量必须现算**"）：
`demo-old-vs-new.sh` 硬编码「33 件」⇒ 改为**现算**；`postland-verify.sh` 的"无长跑"结论 ⇒ 改为**现算 `SELF_PID`／`LONG_RUN`／墙钟**。
⇒ **并入本波必记（第 13 条）**：**凡写进结论的字面量（件数/段数/名字数）都必须现取，不许硬编码**（与纪律 49「冻结 sha 只许脚本算」同族）。

## ⑫ 【链条收尾】冻后 ×2 ＋ POST.done ＋ 推送 ＋ app-local ＋ 哨兵（**读数由 `logs/*.DONE` 现取填入**）

**冻后 `verify-all` ×2（托管后台作业；各带四守卫）**
```
第 1 趟 rc=0 ｜ 步骤通过 37  ❌ 失败 0 ｜ 结论：✅ 全部通过
        [11] VERIFYALL_SELF=PASS names=37 decl=37 gen=#65 dup=0 order=OK prose=OK prereg=PASS
        [7]  BASELINESHA=PASS live=b9c97237afd4c214
第 2 趟 rc=0 ｜ 步骤通过 37  ❌ 失败 0 ｜ 结论：✅ 全部通过 ｜ [11] 同上 ｜ [7] BASELINESHA=PASS live=b9c97237afd4c214
```
**`w65-POST.done`**：两趟全绿才 touch ⇒ 真 `stat` = `mtime=2026-09-24 18:36:40.926749073 +0800 size=0`（见 `logs/postfreeze65.DONE`）。

**逐径推送（照 `FORK-AND-PUSH §3.1` 七步）**：白名单 **15 件**、**逐径 `git add`**（禁 `-A`／`--force`）⇒ 见 `logs/push65.DONE`：
`OLD_HEAD=f158988cf770f1aed8405548c21d5ec70d7eb83e` → `NEW_HEAD=9ea45567f82e9f32cfa78fa0bbcdd9b82713d821`／`LSREMOTE_HEAD=9ea45567…`（**三方一致**，独立复核：`ls-remote feat-Linux` = clone HEAD = 9ea45567…）／`SYMREF=refs/heads/feat-Linux`／`PORCELAIN=0`／
**`BYTECHECK ok=15 mismatch=0 nobody=0`**（判据 = **`HEAD:` 的 blob == `$R` 工作树**）／`whitelist_n=15`
**对账**：`改了几件（`$R` vs clone `HEAD:` 逐件比）= 推了几件 = 15`；`git status` 只用于对账，**未**用于生成清单。

**app-local（"五件"权威 ⇒ 目标目录；判据归 `check-applocal-sync.sh`）** ⇒ 见 `logs/applocal65.DONE`：
`APP_LOCAL_TARGET=/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`／
`APPSYNC=MISMATCH（MISMATCH=0[STALE=0 NEWER-DIFF=0] MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0] DIVERGENT=0 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0）` ⇒ **合格线 `STALE=0 ∧ DIVERGENT=0` 成立**；`UNEXPECTED=6` 是 **`DECL-GAP-EQ=6`（已声明的缺口）**，且该牙自述 **`APPSYNC` 是告警不是硬闸** ⇒ 不构成不合格。

**两处哨兵**：`/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag` —— 九位行 **9/9**，并**手工补**
`BASELINE=#65 sha16=b9c97237afd4c214`（哨兵自身只自动写九位，基线号按 `NOTE` 要求手工补）。

## ⑬ 本波必记（最终 13 条）

1 镜像 `not-reached` 标签不许带过来｜2 自检沙箱那一行不许带过来｜3 故障注入必须断言"注入真的改变了行为"｜4 区间替换要核对被吃掉的末行｜5 构造期守卫｜
6 改源必重建（源→派生件）｜7 3‑9 改严不是读数反复｜8 **备份清单必须在读完全部落地目标之后才动手**（`D-G126`）｜
9 **建预登记件必须同趟带 `PREREG-NO-REGRESSION-DECISION:` 声明**｜10 **新建/改动任何被牙读的件后立刻单独跑那颗牙**（别等整趟 16 分钟）｜
11 **任何"影子/副本/回退树"写前先断言 `stat -c %h` == 1，否则拒写**（硬链接写穿）｜
12 **冻结记录/模板里的每个字面常量都要有"现取校验"**（我给 `tab-rtl` 手打错过一位）｜
13 **凡写进结论的字面量（件数/段数/名字数）都必须现取，不许硬编码**（W152A 自纠两条，与 `D-G131` 同族）。
**＋ 两条方法学**：**判据要判在渲染产物上、不判模板**（我那条守卫口径错了一格）｜**长跑一律托管后台作业（报 `$!` 与日志路径），并把"判定＋后续动作"写进脚本自身（落 `DONE`/`STOP` 标记）**。
