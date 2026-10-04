# P1-GUARD-FIX3（`t144` · W64：`t139` 三条必修 —— `F-1` 新闸加必要件前置 ／ `F-2` 两处 ENFE 口径 dated 更正 ／ `F-3` 空态集成员出处可复现化）

> **来源**：`t139` 独立复核 `t136` 判 **`pass`**（「方向只有收紧」成立）并同笔点名三条必修；队长裁定三十四判为**必修**（**不**改 `t136` 判词、不开新循环）。三条理由逐字：`F-1` ＝「**机读理由与事实相反**」（后人据 `reason=` 判断必错）／`F-2` ＝「**同一事实两种相反表述**」／`F-3` ＝「登记集成员**在仓内查不到出处**」。
> **写域**：`build/MilBridge/tools/pts-pages-guard.sh` ＋ 本件。**未碰** `HANDOFF-NEXT.md` 的 `cell=#1`（**有意未登记**，见 §6）／`src/**`（`t141` 在飞）／任何 `.cs`／两枚哨兵；**相位位 `degraded` 未翻**；未跑整趟门禁／构建／跑腿／显示位；未 `git add/commit/push`。

## §1 收尾必交①：逐件改前/改后

| 件 | 改前 sha16 / 行数 | 改后 sha16 / 行数 | `numstat` | 删行逐条（可追溯） |
|---|---|---|---|---|
| `build/MilBridge/tools/pts-pages-guard.sh` | `201eca63e6820011` / 1068 | **`a1f192aa760e418a`** / 1136 | **`71 3`**（删行 **3**） | ① `else`（旧 `FAIL` 支的开头）② `echo "  N1-ONLY-NECESSARY …"`（旧：无前置、无条件印）③ `echo "PTS_N1_GATE=FAIL …"`（旧：同一句里也印 `reason=only-necessary…`）⇒ 三行**就是** `F-1` 要治的病灶本体，被换成分支化闸（新支 ＋ 原 `FAIL` 支下沉到前置成立分支） |
| `build/MilBridge/P1-realized-criteria-report.md` | `281b40613d6f1f34` / 214 | **未改**（`F-2` 只需与它一致；其 `t136` 段 `O-1` 已是现取口径） | — | — |

**写前像**：`~/w281-scribe/t144/bak/pts-pages-guard.sh.pre-t144`（`201eca63e6820011`／1068 行；写前 `stat -c %h` ＝ 1、`mode 755`；改后 `h=1`／`mode 755` 不变）。

## §2 收尾必交②：`--selftest` 成对读数 ＋ **承重证明**

| 时机 | 读数 |
|---|---|
| 改前基线（派单给的） | **`PASS pass=66 fail=0`** |
| 改后（本件） | **`PASS pass=72 fail=0`**（**不低于红线 66**；新增 6 条断言：`t144·(a)` 2 条／`t144·(b)` 3 条／`t144·(c)` 1 条 —— **未改任何既有期望值**） |
| **承重证明**（拆掉新前置的**突变体**，仓内临时件，跑完即删） | **`FAIL pass=70 fail=2`**，✗ 恰为两条：`t144·(b) 要件①不成立 ⇒ 闸 NOINFO 具名` ✗ 与 `t144·(b) fails= 无相反 reason` ✗ ⇒ **新腿是承重的**（拆掉 ⇒ 必 ✗），且**旧病灶当场复现**（旧支会把 `only-necessary…` 重新印出来） |
| 突变体清理 | **现取**：`ls build/MilBridge/tools/zz-t144-mutant-guard.sh` ⇒ **无此件**；`git status --porcelain \| grep -c 'zz-t144'` ＝ **0**；`ls build/MilBridge/tools/ \| grep -c '^zz-'` ＝ **0** ⇒ **夹具已清、`tools/**` 零残留**（队长提醒的那件在我跑完同一条命令里就 `rm` 了；队长 `git status` 读到的是它存在的那几秒） |

## §3 收尾必交③：`F-1` 四条判据成对读数（**含三态可分**与「`fails=` 里不再出现相反 reason」）

**改动本体**：给新闸 `FAIL` 支加**前置** —— 用 **per-leg 必要件位** `N1_NEC_23/24`（＝ 要件① `fr_sha` ∉ 参照集 ∧ 要件② `fr_ae_boot>0` ∧ 取值在位）gate；**两腿都 `yes` 才**印 `reason=only-necessary-condition-no-positive-evidence`；否则印 `PTS_N1_GATE=NOINFO reason=necessary-not-satisfied(nec23=…,nec24=…)` 并折 `cannot`；**缺整条 `leg_*.env`** 走 `N1_NECMISS` ⇒ `reason=necessary-input-missing(leg23(env-absent))`。契约块同趟 dated 追加（原句一字未删）。

| # | 构造（仓外夹具／真树副本；两侧均带 `PTS_G10_ROSTER_SRC`＋`PTS_G10_DECL_TREE` 覆盖，消"位置伪影"） | `PTS_N1_GATE=` 现取 | `fails=` 里含相反 reason？ | 整步 |
|---|---|---|---|---|
| **(a)** | 必要件成立（两腿 `fr_sha=c0ffee1234abcd99` ∉ 集、`fr_ae_boot=1234>0`）＋ 无正证据 | `FAIL … nec23=yes nec24=yes reason=only-necessary-condition-no-positive-evidence` | **是（1）** —— **保持** | `PTS_GUARD=FAIL` `rc=1` ✓ |
| **(b)** | 要件①**不成立**（两腿 `fr_sha=ef3fd6765f18f51b` **∈ 累积集**） | **`NOINFO phase=realized reason=necessary-not-satisfied(nec23=no,nec24=no)`** | **否（0）** ⇒ **旧病灶消除** ✓ | `PTS_GUARD=FAIL` `rc=1`（**腿级** `leg23/24-n1-frame-unestablished(frame-identity(…∈{…}))` 独立判红 —— 那是**另一条**合法要件，不是本闸那理由） |
| **(c)** | **缺整条 `leg_23.env`** | **`NOINFO reason=necessary-input-missing(leg23(env-absent))`** ⇒ 与 (a)(b) **形态可分** | 否（0） | `PTS_GUARD=FAIL` `rc=1`（`leg23(env-absent)` 进 `cannot=`） |
| **(d)** | 真树在册证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence` 的 `realized` 副本（两腿均 ∈ 累积集） | 逐腿：`PTS_N1=FAIL k=24/23 … criterion=frame-identity(sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b})`；闸：**`NOINFO reason=necessary-not-satisfied(nec23=no,nec24=no)`**（改前此处**仍**多印 `n1-only-necessary-condition-no-positive-evidence(…)` ⇒ **机读理由与事实相反**，现已消） | 否 | `rc=1`（`fails=` 只剩两条腿级 red） |

**三态可分（逐字）**：`only-necessary-condition-no-positive-evidence`（前置成立）／`necessary-not-satisfied(nec23=no,nec24=no)`（必要件不成立）／`necessary-input-missing(leg23(env-absent))`（取值缺）—— 三个 `reason=` **互不相同**，且 (b)(c) **不**把「只有必要条件」当理由 ✓。
**`degraded` 期不受影响**（本闸在 `realized` 分支内）：`degraded` 主件判词**修前/修后逐字相同** ✓（`PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),native-ledger-absent(PTS_GAP n=0) cannot=- diag=… direction=in-file phase=degraded`；`rc` 两侧同为 1；`PTS_N1=INFO` 两行、`PTS_N1_GATE` **0 行** ⇒ 本闸不进 `degraded`）✓。
⚠️ **一次"看似不同"的归因（如实记）**：首次把**写前像**（在 `~/w281-scribe/t144/bak/`，仓外）跑同一目录时，两侧判词差在 `cannot=g10-name-roster-source-unreadable` vs `cannot=-` —— 根因是**写前像在仓外** ⇒ 它按自身位置推 `ROSTER_SRC` 失败（**位置伪影**，不是本件行为差）；按 `PTS_G10_ROSTER_SRC`／`PTS_G10_DECL_TREE` 覆盖两侧后 ⇒ **逐字相同** ✓。

## §4 收尾必交④：`F-2` 两处 ENFE 口径 dated 更正（**现取原文**）

两处**只增不改**（原句保留、更正在其后；**零阈值/判别逻辑改动**）：

- **第一处（`PTS_ENFE` 段口径块，现取 `:579`）**：
  ```
  #   ⏪ **dated 更正（`t144`／`t139` `F-2`；上句原文保留，以本行为准）**：该「同源／计数相等」**今天已解耦** ——
  #     两个量**各自定义、不得互相折算**：`ENFE_TOTAL` ＝ 日志里 `entry point named '<名>'` 的**行数**（**缺符号面**）；`[HC-UNHANDLED]`
  #     ＝ 同名标记的行数（**托管未处理异常面**）。现取实况：`ENFE_TOTAL=0` 而 `[HC-UNHANDLED]` 族 **1123**（内容为 `PtsException: Page formatting
  #     engine did not complete formatting operation …`）⇒ 二者**不可互折**。口径与 `build/MilBridge/P1-realized-criteria-report.md` 的 `t136` 段（`O-1`）**一致**。
  ```
- **第二处（件尾索引块口径句，现取 `:1085`）**：
  ```
  #    ⏪ **dated 更正（`t144`／`t139` `F-2`；上句原文保留，以本行为准）**：**「同源」不等于"计数相等"** —— 两个量**各自定义、不得互相折算**
  #      （`ENFE_TOTAL`＝缺符号面；`[HC-UNHANDLED]`＝托管未处理异常面）；现取：**0** vs **1123**；与判据件 `P1-realized-criteria-report.md` 的 `t136` 段（`O-1`）**一致**。
  ```
⇒ 仓内**三处**（守卫两处 ＋ 判据件 `t136` 段 `O-1` 一处）**口径一致**，不再有"同一事实两种相反表述"。

## §5 收尾必交⑤：`F-3` 取**（乙）**及其证据

**决定：取（乙）**（在 `FRAME_EMPTY_SET` 登记处**如实写明**出处与"仓内不可复现"），**不取（甲）**。理由（三条，均可复核）：
1. **（甲）会改覆盖面件集**：`build/MilBridge/tests/PtsPagesProbe/evidence/**` **在覆盖面指纹内**（现取 `infp.sh list` 含该族）⇒ 往里面加一件会让**覆盖面件数/指纹位移**，并把 `handoff-machine-values-check` 的 `cell=#2`（件数格）基线一起带动 —— 而本波 `cell=#1` 由队长统一对齐，我不该再制造一处未对齐位移。
2. **（甲）会污染装置证据契约**：该目录是**装置自身产物**的落点（`leg_*.env` 的 `FRAME` 行、`DEV` 行、`--legs` 读的列都指向它）；手工放一枚**非运行产物**的 PNG 进去，正是本队反复治过的「**同名不同代／错位副本**」隐患（`t134` 的 `src/tests` 事件同族）。
3. **（乙）零位移且可复核**：改动只在守卫登记处（我的写域内），并给出**可复算命令**。

**登记处现取原文（`FRAME_EMPTY_SET` 上方）**：
```
#   ⏪ `t144`（`t139` `F-3`）**逐枚出处可复现性**（**取（乙）**：只登记出处、**不**往装置证据面塞非装置产物；理由见载体）：
#     · `ef3fd6765f18f51b` —— **仓内可复现** ✓：`build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/k23.png`
#       现势与 `git show HEAD:<同路径>` **同为**该值、各 `189716` B（本席 `2026-09-29T15:0x+0800` 现算）。
#     · `1a76488aa4a790b3` —— ⚠️ **仓内不可复现**（该路径**仓内可达史 8 版均非它**，本席现算命中 **0**）；
#       真实载体在**仓外**：`~/t119-runner/bak/run-N3-runner-shots/g1/{k23,k24,last}.png`
#       （三枚同值 `1a76488aa4a790b3`、各 `189742` B；本席现算）。⇒ **引用该成员时必须连带写明"仓外载体"**，
#       不得当成"仓内可查"；复核命令：`sha256sum ~/t119-runner/bak/run-N3-runner-shots/g1/k23.png | cut -c1-16`。
```
**本席现取的两枚事实**：`ef3fd6765f18f51b`（`189716` B）—— 在册现势与 `HEAD` 版**同值** ✓；`1a76488aa4a790b3`（`189742` B）—— 仓内该路径**可达史 8 版命中 0**，仓外三枚（`k23/k24/last`）同值 ✓；同目录 `boot.png` ＝ `b21eb530afd3c66c`（`190413` B，**不入集**）。
⚠️ **不撤销 `t136` 的纪律**：**「作废＝把一枚帧身份移出集合」这个动作本身危险 —— 只有拿到 `N4` 正身份或内容锚正证据才准移出**（本件只治**出处可复现性**，未动这条纪律的任何一个字）。

## §6 收尾必交⑥：本席主动点名的 `NOINFO` ＋ 边界

1. **覆盖面与 `cell=#1`**：守卫件**在覆盖面内**（现取 `infp.sh list | grep -c 'pts-pages-guard.sh'` ＝ **1**）⇒ 按第 `28` 条本应登记；派单硬约束**明令不碰** `HANDOFF-NEXT.md` 的 `cell=#1`（队长收口）⇒ **本件有意未登记**；指纹本席现取 ＝ `81c167bec1bd9a97c74fc597c598718f7da46233cc9411d4137b01cada8f69a6`（成因含本席守卫件 ＋ 他者 `src/**` 在飞）。
2. **`t145` 的基线提醒（按队长消息，已记）**：`t145` 与我同动守卫件 ⇒ **它必须自己现取当时的 `--selftest`**；**本件交出的新基线是 `PASS 72/0`（不是 `66/0`）**。
3. **未跑／未核（具名）**：① 未跑整趟门禁、未构建、未跑腿、未占显示位（派单禁）；② **未**在真腿日志上验证"端到端三态"（本件的三态读数全部来自**仓外夹具 ＋ 在册证据副本**，无新跑腿）；③ **未**独立复核 `t139` 对 `1a76…` 的其它结论（我只复核了它这条出处主张本身）；④ 判据件**本件未改**（`F-2` 只需守卫侧与它的 `t136` 段一致；若队长要我也在判据件加一行索引，请明示）；⑤ **未**给 `F-3` 取（甲）⇒ `1a76488aa4a790b3` 在仓内**仍然不可复现**（这是**有意**的：登记处已如实写明"仓外载体"）。
4. **残留检查**：突变体已在同一条命令内 `rm`（现取零残留 ✓）；仓外夹具目录 `~/w281-scribe/t144/fx*` 与读数日志留档，仓内**零新增件**（`git status` 只见 ` M build/MilBridge/tools/pts-pages-guard.sh` 与 `?? build/MilBridge/P1-guard-fix3-report.md`）。

**本件自证**：`head -n -1 build/MilBridge/P1-guard-fix3-report.md | sha256sum | cut -c1-16` ＝ d4ecc6400b0e68e1（末行不计入自身）
