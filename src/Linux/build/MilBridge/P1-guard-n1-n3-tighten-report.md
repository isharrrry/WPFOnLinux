# P1-GUARD-N1-N3-TIGHTEN（`t136` · W57：`N1` 降「必要非充分」／空态参照集**累积登记**＋作废纪律／`N3` 例外支写死／读数绑定与契约口径更正）

> **来源**：独立复核 `t120`（载体 `build/MilBridge/P1-w43-verify.md`，`6d5bcdf886dc2d5f`／69 行）判 `N1①` 今天呈**假绿形态**（登记集单成员 `{1a76488aa4a790b3}`，实况帧 `ef3fd6765f18f51b` 恰是**曾被写作"作废"**的旧空态指纹 ⇒ 字面 `∉ 参照集` 被读成通过），队长裁定**必须收紧**。本件是**相位翻转的前置**（`N1` 今天 `degraded` 期只印 `INFO`、不进 `rc`；翻转后就会给空态帧发绿）。
> **仪器**：`bash` 语法检查＋`--selftest`（`mktemp` 夹具、无 X／无应用）＋仓外夹具 `~/w281-scribe/t136/fx/**`＋只读牙（`pts-gap-count-check.sh --check`／`defect-registry-check.sh`／`report-id-domain-check.sh`／`infp.sh`）。**零构建、零跑腿、零显示位、零整趟门禁、零 git 写、未碰哨兵、未翻相位位。**

## §1 四条落地（逐条：处置 ＋ 落点 ＋ 收紧方向）

- **①`N1` 要件①降「必要非充分」（`F-3`）** —— **落点**：`build/MilBridge/tools/pts-pages-guard.sh` 的 `N1` 段（口径注释 ＋ `realized` 分支 ＋ 循环后新闸）。
  - `realized` 分支：旧 `PTS_N1=PASS`（必要件齐即绿）⇒ **`PTS_N1=NECESSARY`**，判词写死「**「∉ 参照集」不得单独作为排版绿的依据**」。
  - 循环后**正证据闸**（`PTS_N1_POS=` ＋ `PTS_N1_GATE=`）三源**必须点名**：(a) `N4` 正身份登记（env `PTS_N4_POSITIVE_FP="<k23 sha16>,<k24 sha16>"`；**未登记 ⇒ `NOINFO`、不得给绿**）／(b) 内容锚（`PTS_CONTENT_ANCHOR_RE`，默认 `[Nn]eptune`，命中 **>0**）／(c) `AE(k23,k24)>0`（`compare` 实测优先、`via=compare`；两图不在时用两腿 `fr_sha` 不等、`via=fr-sha-inequality`）。
  - **今天三源一个都不在场**（现取：两腿 `fr_sha` 同值、`neptune` 命中 `0`、`N4` 无登记载体）⇒ 判红并点名 `reason=only-necessary-condition-no-positive-evidence` ✓ **方向＝收紧**。
- **②空态参照集＝累积登记 ＋ 作废纪律** —— **落点**：同一件件头**唯一登记处**。
  - `FRAME_EMPTY_SET` **`{1a76488aa4a790b3}` ⇒ `{1a76488aa4a790b3,ef3fd6765f18f51b}`**（**逐枚给来源与时刻**：前者 ＝ `t122` 重登记、`2026-09-29T04:1x+0800`；后者 ＝ `t119` 那趟 `00:52` 代照进在册 `evidence/shots/g1/{k23,k24,last}.png`，本席 `t136` 现取三帧 `sha256` 前16 同值、各 `189716` B）。
  - **作废纪律（写死）**：**把一枚帧身份从登记集里"作废／移出"这个动作本身是危险的 —— 只有拿到 `N4` 正身份或内容锚正证据才准移出；只凭"换了一版画面"不得移出。**
  - `t124` 段那句"旧登记 `ef3fd6765f18f51b` 作废"**按本件收回**（原文一字未删，以新段为准）⇒ **方向＝收紧**（假绿形态被就地堵死，见 §3(a)）。
- **③`N3` 例外支条件写死（`F-1`）** —— **落点**：`build/MilBridge/P1-realized-criteria-report.md`（dated 追加，段③）＋ `build/MilBridge/P1-realized-probe-report.md`（`t119` 载体，同日 dated 追记）＋ 守卫侧实现。
  - 条件：**例外仅当两页「内容定义」相同**（`PTS_N3_SAME_CONTENT_PROOF` **非空**的正证据声明）**且两页都确已绘出内容**（两腿 `ink>0`）；**「两页都没绘出内容」不构成例外 ⇒ 必红**；例外成立只**免红**（`PTS_N1_GATE=EXCEPTION`），**不冒充**排版正身份。
  - `t119` 载体**只增不改**地追记：本例**不满足例外**（自陈两页都没绘出内容）⇒ 当年那处**免红不成立**、`N3` **维持红** ⇒ **方向＝收紧**。
- **④读数绑定与契约口径更正** —— **落点**：守卫每条 `PTS_ENFE=` 行绑 `log=`／`log_sha16=`；判据件同日 dated 追加（`F-2`／`O-1`／`O-2`／`F-4`）。
  - **`F-2`**：现取 `PTS_ENFE=INFO total=0 by_name=none allow=none non_allow=none phase=degraded log=build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log log_sha16=84db0eb62d15e0b2`。`t119` 载体引的 **`ENFE_TOTAL=1152` 记具名 `NOINFO`**：原始载体由 `t119` 车道持有（`~/t119-runner/bak/**`）、**本席取不到**；可核三处 ＝ `run-N3-app_g1.log` **1121**／`evidence.pre-t119` **1121**／`057d08a` **1081**（本席 `t134` 另取工作树现值日志 **1085**）⇒ **不留无载体的 `1152`**。
  - **`O-1`**：`ENFE_TOTAL`（缺符号面，现取 **0**）与 `[HC-UNHANDLED]`（托管未处理异常面，内容现取为 `PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'` 族，现取 **1123**）**今天已解耦、不得互相折算**（契约原句一字未删、以更正段为准）。
  - **`O-2`**：**凡引用 `N1` 的结论必须写明相位**；守卫侧每条 `PTS_N1*` 行现取都带 `phase=`（旧 NOINFO 行缺 ⇒ 本件补上）。
  - **`F-4`**：契约件标识成对 —— `t119` 载体写 **`55d6f050ecbe4c7d`／146 行**；本席追加前现取 **`fcb20f641bdbbf3b`／200 行**；追加后 **`281b40613d6f1f34`／214 行**。

## §2 改前/改后（逐件 `sha256` 前16 ＋ `numstat`）

| 件 | 改前 sha16 / 行数 | 改后 sha16 / 行数 | `numstat` | 说明 |
|---|---|---|---|---|
| `build/MilBridge/tools/pts-pages-guard.sh` | `e74ec5c2f6a87f0f` / 921 | **`201eca63e6820011`** / 1068 | **`160 13`** | 装置件（派单允许改）；**13 处删除逐条可追溯**见 §2.1 |
| `build/MilBridge/P1-realized-criteria-report.md` | `fcb20f641bdbbf3b` / 200 | **`281b40613d6f1f34`** / 214 | `14 0` | dated 追加 ＋ 新自证行（旧两条自证行原文保留） |
| `build/MilBridge/P1-realized-probe-report.md`（`t119` 载体） | `a61bd3c243a448ff` / 177 | **`186c918f2937d355`** / 179 | `2 0` | 只增不改：dated 追记插在**自证行之前**（末行原样保留） |
| `build/MilBridge/P1-guard-n1-n3-tighten-report.md`（本件） | 新建 | 见 §7 | 新件 | 载体 |

**§2.1 装置件的 13 处删除（逐条归类；每处都对应本件某条判据）**：① `FRAME_EMPTY_SET="1a76488aa4a790b3"` ⇒ 累积两成员（**②**）；② 旧「只增不减」注句 ⇒ t136 口径块（**①**）；③ NOINFO 判词行补 `phase=`（**`O-2`**）；④ `PTS_N1=PASS` ⇒ `PTS_N1=NECESSARY`（**①**）；⑤–⑧ `ENFE` 四条判词行补 `log=`／`log_sha16=`（**`F-2`**）；⑨–⑬ 自测 5 条**旧期望/断言串**按收紧方向改严（**§4 逐条方向表**）。

## §3 三条两极化**真跑**（仓外夹具 `~/w281-scribe/t136/fx/**`，`realized` 副本由 `sed` 造；判词原文见日志）

| # | 构造 | 判词（现取） | 结论 |
|---|---|---|---|
| **a** | 两腿 `fr_sha=ef3fd6765f18f51b`（**累积集新成员**） | `rc=1 PTS_GUARD=FAIL … fails=leg24/leg23-n1-frame-unestablished(frame-identity(sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b})),n1-only-necessary-condition-no-positive-evidence(…)` | **必红点名** ✓（假绿形态就地堵死） |
| **b** | 两腿 `fr_sha=c0ffee1234abcd99`（∉ 集、`fr_ae_boot=1234>0`）⇒ **只有必要件** | `rc=1 PTS_GUARD=FAIL`；`PTS_N1=NECESSARY`×2；`PTS_N1_POS=phase=realized positive=none n4=absent anchor_hits=0 differ=0 via=none n4_unregistered=1 exception_proof= exception_applies=0`；`PTS_N1_GATE=FAIL … reason=only-necessary-condition-no-positive-evidence` | **realized 期必红并点名** ✓ |
| **c** | 同 (b) ＋ `PTS_N3_SAME_CONTENT_PROOF=…`（例外声明）＋ 两腿 `ink>0` | **无声明**：`PTS_GUARD=FAIL`（同 (b)）；**有声明**：`PTS_GUARD=PASS`，`PTS_N1_GATE=EXCEPTION` | **例外支成立 ⇒ 不红（正极）** ✓，且**同夹具去掉声明即红**（**因果对** ✓） |
| 补充 1 | 两腿 `fr_sha` 不等（`0a0b…`／`1213…`）＋ `PTS_N4_POSITIVE_FP` = 两腿登记值 | `PTS_GUARD=PASS`，`positive=n4,differ(via=fr-sha-inequality)` | 正证据源 (a)(c) 可判 ✓ |
| 补充 2 | 夹具 `app_g1.log` 命中锚 1 次 | `PTS_GUARD=PASS`，`positive=anchor(hits=1)` | 正证据源 (b) 可判 ✓ |

**真树读数（在册证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence`）**：`realized` 副本 ⇒ **`rc=1 PTS_GUARD=FAIL`**，两腿 `criterion=frame-identity(sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b})` ＋ `PTS_N1_GATE=FAIL reason=only-necessary-condition-no-positive-evidence`（**收紧前**该目录 `realized` 副本为「四要件齐 ⇒ `PASS`」的假绿形态）；**`degraded` 主件判词修前/修后逐字相同** ✓（`PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),native-ledger-absent(PTS_GAP n=0) cannot=- diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0(点击前后无像素差) direction=in-file phase=degraded`，`rc=1` 两侧相同）。**相位位未翻** ✓。

## §4 `--selftest` 成对读数（**改前 / 收紧后原样 / 终态**）

| 时机 | 读数 |
|---|---|
| **改前** | `PTS_GUARD_SELFTEST=PASS pass=55 fail=0` |
| **收紧后、期望未动**（＝"自测因收紧而该红"的**新基线**） | `PTS_GUARD_SELFTEST=FAIL pass=50 fail=5` —— 5 条**旧期望随收紧而该红**：`realized·真实形态`（`PASS→FAIL`）／`realized·缺 ink`（`NOINFO→FAIL`）／`realized·ENFE 全在 allowlist`（`PASS→FAIL`）／`realized·帧∉集∧位移>0`（`PASS→FAIL`）／`c36` 断言串（参照集改**累积**） |
| **终态** | `PTS_GUARD_SELFTEST=PASS pass=66 fail=0` |

**方向表（每一处改动与方向；无一处放宽）**：`E1` `c15` `PASS→FAIL`｜`E2` `c16` `NOINFO→FAIL`｜`E3` `c33` `PASS→FAIL`｜`E4` 断言串 `{1a76…}`→`{1a76…,ef3f…}`（**更严**）｜`E5` `c37` `PASS→FAIL`｜**新增 11 条断言**：`c40` 新成员必红、`c40` 点名累积集、`c41` 只有必要件必红、`c41` 缺正证据点名、`c42` 例外支成立正极、`c42` 例外支点名、`c43` 去声明因果对、`c44` anchor 正证据、`c44` anchor 点名、`c45` `n4` 正证据、`c45` `n4` 点名。

## §5 牙读数（现取 rc）

| 牙 | rc | 读数 |
|---|---|---|
| `pts-pages-guard.sh --selftest` | 0 | `PASS pass=66 fail=0`（改前 55/0；中间新基线 50/5） |
| `pts-pages-guard.sh --legs <在册证据>`（`degraded`） | 1 | `PTS_GUARD=FAIL …` 与改前**逐字相同** ✓ |
| `pts-pages-guard.sh --g10-name <在册证据>` | 0 | `PTS_G10_NAME=PASS form=unnamed`（未动） |
| `pts-pages-guard.sh --c4-ledger <在册证据>` | 3 | `PTS_C4_LEDGER=NOINFO reason=ledger-empty`（台账空 ⇒ 不当绿；未动） |
| `pts-gap-count-check.sh --check` | 1 | `LIVE tool=90 dead=11 artifact=1 ops=78 impl=81 so16=5ddc9d63b5232f96 exports=594`；残留**恰 1 条既存** `SITE-DRIFT docs/ROUTES.md impl want=81 got=87`（**非本席**） |
| `defect-registry-check.sh` | 0 | `DEFREG=PASS declared=224 route_ids=224`；**`DEFREG_DECLDRIFT=0 keys=-`** |
| `report-id-domain-check.sh` | 0 | `REPORTID=PASS files=263 ids=2207 declared=224`（本件落盘后复跑见 §7） |

## §6 覆盖面与 `cell=#1`（**按派单硬约束：本件不写**）

- **本件改了覆盖面内件**（现取：`bash ~/w153a/bin/infp.sh list | grep -c 'pts-pages-guard.sh'` ＝ **1**）⇒ 按第 `28` 条**本应**同趟现取指纹并追写 `cell=#1`；但派单「**不碰**」清单**明列** `HANDOFF-NEXT.md` 的 `cell=#1` ⇒ **本件遵照派单不写**（并以本行如实记这次**有意未登记**）。
- **指纹位移（现取，如实交取值时刻）**：本席收工前 `bash ~/w153a/bin/infp.sh fp` ＝ **`0d4ba945fd210893e6a4c5b7cd0b8a67d71df828e87711bb023674376c24583b`**；同窗口另有他者在飞换代（`src/WpfGfx.Linux.Native/src/win32_pts.c`、现盘 `.so` 已到 `5ddc9d63b5232f96`／`exports 594`）⇒ **位移为混合成因**（本席的守卫件 ＋ 他者 `src/**`），**同代一次性对齐归队长收尾**。

## §7 未做项、修正记录与自证

- **未做**：不翻相位位（`phase=degraded` 保持）；不跑 `--emit`（派单：`t134` 刚做过，本件非必需；`DECLDRIFT` 现取已为 `0`）；不构建／不跑腿／不占显示位／不跑整趟门禁；未 `git add/commit/push`；未碰 `src/**`（`t133` 在飞）、产品件、两枚哨兵。
- **本趟的两处自身缺陷（已就地修，如实记）**：① 新增判词行里**双引号 `echo` 内嵌反引号**触发 `DQ-BACKTICK`（输出里 `t136`／`∉ 参照集`／`N3` 等 token 被命令替换吃掉）⇒ 已审计（新增块内**奇数反引号行数 ＝ 0**）并改为「」或去反引号；② `PTS_N4_POSITIVE_FP` 的夹具**取值序写反**（口径是 `<k23 sha16>,<k24 sha16>`）⇒ 已更正夹具、口径本身未改（**不放宽**）。
- **`t119` 载体末行自证仍为字面 `PLACEHOLDER`**（本席**未**改写它 —— 派单禁"就地改写原文任何一行"）⇒ 成对读数：**插入前**（177 行版式）应为 `ca38c9d5a569ed4c`（可用 `~/w281-scribe/t136/bak/P1-realized-probe-report.md.pre-t136` 复算）；**插入后**（179 行版式）现算 ＝ **`ab2a7748b54a7b7b`** ⇒ 件主填该行时用后者（该值**不写进件内**，以免自指）。
- **备份面（第 `29` 条）**：三件**写前** `stat -c %h` ＝ 1、`cp -p` 至 `~/w281-scribe/t136/bak/*.pre-t136`；仓外夹具 `~/w281-scribe/t136/fx/**`（用完已删）。
- **边界**：写域 ＝ `build/MilBridge/tools/pts-pages-guard.sh`（装置件，允许改）＋ `build/MilBridge/P1-realized-criteria-report.md`（dated 追加）＋ `build/MilBridge/P1-realized-probe-report.md`（dated 追加）＋ 本件（新建）＋ 仓外 `~/w281-scribe/t136/**`。

**本件自证**：`head -n -1 build/MilBridge/P1-guard-n1-n3-tighten-report.md | sha256sum | cut -c1-16` ＝ 4318a85fcd2ba4a8（末行不计入自身）
