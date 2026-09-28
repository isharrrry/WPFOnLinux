# P0-w80-report —— 波 `#80` 收口链（冻结 `#80`：`901619543b3d913b` → `b96d4312565a3c49`）

**车道**：`waveman`（`t46`）｜**报告现读**：见文末 SELF 行｜**全程 `temp+rename`**｜**重活全走 `~/heavy-slot.sh`**｜**进程只按 PID**
**资源读数一律 `/proc/meminfo`**（`free` 本地化 ⇒ `free|grep -i swap` 零输出；本波已立口径）

---

## §1 链的走向（每步都给现取判词与时刻）
| 步 | 结果 |
|---|---|
| 起链前九位对拍（对 `~/w21-verify/w80-pre.sha`） | `NINE_KEYS=9 NINE_MATCH=3 NINE_MISMATCH=6`（位移 = `pc,pf,windowsbase,provider,win32shim,dwf`） |
| **整波** `close-wave.sh --native --skip-verify-all` | 首跑 `[5c/6]` 红（见 §3）；按 `#79` 先例**重钉表后不重跑整波**、续链 |
| **重取五臂** `retake-arms-w23.sh` | `rc=0` |
| **重钉** `repin-generation` | `--check rc=1`（`n=3`）→ `--why` `APPLIED` → `--check rc=0` `REPIN_GENERATION=PASS` |
| **应用门禁 ×2**（`gateapp`） | `rows r1=r2=6`，`pass1/pass2 全 PASS=6` |
| **门禁三趟** `gate1/gate2/pre` | 各 **`54 ✅ / 1 ❌`**，唯一红 = `COLUMN-FLOOR`（设计内，见 §2） |
| **冻结 `#80`** | 首跑拒冻（§4）→ 补世代表头行 → 复冻 **`FREEZE_RC=0`** |
| **post1 / post2** | 各 **`55 ✅ / 0 ❌`**（`mtime 12:06:11` / `12:20:49`，均 > 冻结点 `11:51:17`）｜`COLUMN_FLOOR=PASS n_decl=5 n_ok=5`（冻后判否点转绿） |
| **一笔推送** | `71603bd..57cd937`，`PORCELAIN=0`，`REMOTE_PER_COMMIT=PASS n=3` |
| **两哨兵** | `cmp IDENTICAL`，sha16 `f2ab94d32b8e1e40`，`WAVE=w80-freeze`／`BASELINE=#80`／`BASELINE_SHA16=b96d4312565a3c49` |

## §2 `gate1` 四处红（逐条归因与处置；无一条被"忽略"）
1. **`PREREG-FOUR-REQ`** ← `docs/WAVE80-PREREGISTRATION.md state=fail missing=8`（判据节缺 `PREREG-REGRESSION-FOUR:` 机读行／四要件／判据件指名）⇒ **主控**补 NA 形态（`0a87ebeb459c6283 → d4f9fac1ca0c9048`）后转绿。
2. **`COLUMN-FLOOR`** ← `COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=3 bad=tline,textlineproto`（登记表已钉**新**臂日志、`#79` 块仍声明**旧**值）⇒ **冻前必红、设计内**（仓内原话 `ACCEPTANCE-BASELINE.md:2288/:2471`）。**判否点在冻后**：冻后现取 `COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无` ＋ `COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus base=b96d4312565a3c49 rc=0` ✔
3. **`REPO-ALIAS`** ← 我 `重取五臂` 在 `~/wfp-runs/arms23/` 留下的 5 个**硬链接孪生**（`nlink=2`）⇒ 删孪生（仓内件内容与 mtime 一字未动）⇒ 现取 `ALIAS=PASS examined=17799 linked_gt1=0 aliased_out=0 rc=0 reason=no-out-of-repo-alias`。
   ⚠️ 如实划界：`arm-logs/README.md` 说该目录 `*.log`"**是硬链接、不是拷贝**"（mtime 保真 ＋ `find -type f`）⇒ 我删的是**输出侧**孪生（README 口径里那本就是"先落临时目录"的落点），**仓内件现为 nlink=1 的实体件**（内容/mtime 未动）。若主控要求保持"仓内硬链接"形态，替代处置＝在 `repo-alias-allow.tsv` 按上限 5 声明该树（本波未采用）。
4. **`tline-gate（五臂）NOINFO`** ← `arm=tline` 的日志**中途崩了**（73 行、无 `通过 N / 失败 M` 结论行）⇒ 见 §3。

## §3 🔴 `tline` 臂自伤：**死根**（`D-G155` 族"崩了还继续"的现场）
- 崩溃签名（改前现取）：`:56 Unhandled exception. System.IO.DirectoryNotFoundException: …/wpf-linux-20260906/wpf-linux/tests/…`；`:49 一致 0/4（权威 PC=(读不到)）`；四行 `[T0.7] 权威=(权威缺失)`。
- **根因一件**：`build/MilBridge/tests/HbTextLineParity/Program.cs:42` `private const string Root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";` —— **该树已被撤除**，而探针的权威件／shim 源／T1 夹具全从它拼路径 ⇒ 一切"缺件"都是这个死根，不是产品/夹具问题。交叉验证：其余四臂日志死根签名 = 0。
- **修法**（最小改动，与仓内先例 `tests/ProductEntryArm/Program.cs:205` 同形；未加 env、未动逻辑）：字面量 → `"/home/links-dev/netTest/GitProj/WPFOnLinux"`；件 `149dd986a642fdfc → dda989bb024d20e6`，`git diff --numstat` = **`1 1`**，`mode 600`／`nlink=1` 保持，`.tmp` 残留 0，**备份写前取**。
- **重取**（槽内 `timeout 3600 bash build/MilBridge/run.sh tline`；输出**直落仓内路径** ⇒ 无孪生、mtime 为该趟自身）：
  | 项 | 上一代（`HEAD`） | 本趟 |
  |---|---|---|
  | sha16／行数 | `59a203de30d745a8`／232 | **`0153827e9c590d1e`／232** |
  | `grep -c 'Unhandled exception\|权威缺失\|wpf-linux-20260906'` | **6** | **0** |
  | `[T0.7] … ✓ 一致` | 4 | 4 |
  | 结论行 | `通过 22 / 失败 2` | **`通过 22 / 失败 2`** |
  | T 节命中 | 13 | 13 |
  ⇒ **行为不变**（`❌` 行 diff 只差一行折行注释；两条红是**同一对已登记项** `T3 Collapse`／`T3b`）⇒ **修的是自伤，不是把红洗绿**。
- **重钉（先查读者语义再动手）**：`tline-gate.sh:268 GEN_KEYS=("instr_run_sh","instr_program_cs","instr_shim")`／`:270 tree={…"instr_program_cs": i_parity…}`／`repin-generation.py:31` 同键 ⇒ `instr_program_cs` 语义 = `HbTextLineParity/Program.cs` 的 sha16。
  `generation.arm_logs.tline`：`45c94f86…（全64） → 0153827e9c590d1e9dcd51c168a40e625a005c06b9f553b94cf0eaa5ba951eb3`（＝现算 tline.log 全 64 位 ✔）；`generation.instr_program_cs`：`149dd986… → dda989bb024d20e604f1863a7d11d53d97600d4500692c3880347ae1d6a57372`（＝现算 Program.cs 全 64 位 ✔）；`entries[*].caliber 改动字段数=5`；`--check` 复跑 `rc=0`。
  ⚠️ 口径更正（主控已认）：`PREVCHECK=PASS` 是**冻结器** token，重钉侧正确 token = **`REPIN_GENERATION=PASS`**。

## §4 冻结 `#80`（含首跑拒冻，如实入账）
- **首跑拒冻**：`AssertionError: verify-all.sh 头注释里找不到「**#80 收官起 = 55 步**」这句话 —— 头注释与现实分叉了` ⇒ **无部分写**（基线当时仍 `901619543b3d913b`、未落 `POST.done`）。
  处置次序（本仓要的形态）：补世代表头行（照 `#79` 行逐字换号，`e270cb6800cbdfc2 → 600274f130cfe913`，`numstat 2 1`）→ **复算 `inputs_fp` 确认未动**（`abc76bd5…`；`verify-all.sh` 不在覆盖面）→ 复冻。
- **复冻现取**：`PREVCHECK=PASS gen=#80 keys=7 checked=7 skipped=0`｜`BLOCKVALUE=PASS keys=9 tier_keys=8 bsfp=1 infp=1`｜`基线已重冻为 #80；整份 sha16 = b96d4312565a3c49`｜`FREEZE_RC=0`｜`POST.done` 落 `11:51:17`。
- **唯一机器声明点**：`docs/CURRENT-STATE.md:9` 现读 `> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（**由冻结同趟写成**；`CSDECL=PASS n_decl_lines=1 auth_line=8`）。如实口径：`#80` 块**本身不含** `BASELINE-FROZEN` 行（块内是 `# RE-FROZEN #80` ＋ 九位行 ＋ `inputs_fp` 行），两处的"一致"＝块件现算值 == `CS:9` 声明值 ✔
- 块内五条 `# ARM-LOG-SHA` = 主控模板（`9c8a29d5b90a6bfd`）= 现场日志 **5/5**：`tline 0153827e9c590d1e`／`tab-anchor 1c43a12dcaa5718a`／`tab-zero 9150c3a26a3cb789`／`tab-rtl 92570318851ca7e8`／`textlineproto c537f0c007a6c922`；块内 `inputs_fp = abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f` ✔（与现取逐位同）

## §5 两趟 post（成对）
```
post1 11:51:32→12:06:11  「步骤通过 55  ❌ 失败 0」结论：✅ 全部通过  ｜ COLUMN_FLOOR=PASS n_decl=5 n_ok=5
post2 12:06:11→12:20:49  「步骤通过 55  ❌ 失败 0」结论：✅ 全部通过  ｜ COLUMN_FLOOR=PASS n_decl=5 n_ok=5
```
两趟均 `mtime > 冻结点`；`COLUMN-FLOOR` 的**判否点在冻后转绿**（§2-2）。

## §6 🔴 两条结构性结论（本波最有价值的发现；`D-G176` 预留、本波不登记）
1. **九位跨同一输入两次整波不复现**：同源、同参数、相隔约 5 分钟的两趟整波产出**不同字节**
   `pc efbdba3aa75d5086 → 5b6cfda3e12b84fc`｜`pf e2ad7c6a9838ede2 → b9a4f3a0e48e688d`｜`dwf cb6c09c6c5377a77 → c83be96f18759edc`（`windowsbase`／`provider`／`win32shim` 两次逐位不变）。
   ⇒ **归因口径（主控裁定）**：**不许**写成"`D-G92` 环成员·路径承载体"（本条的**路径未变、字节仍变** ⇒ 路径承载解释不了它），只许记"**同源同参重建产出不同字节（机制未定）**"。
   ⇒ **因此"冻结与哨兵必须是最后两个动件的动作"**：一旦冻结后还有任何重建，声明就会与现场不符。
2. **`blockvalues-shift.tsv` 的 `live=` 被钉住（设计）＋ 整波每次都重建** ⇒ **同一趟 `close-wave` 里"重钉"与 `[5c/6]` 通过结构上不可兼得**；换代收口只能走 `#79` 那条路：**整波首红如实留档 → 重钉表 → 四档单跑 PASS → 续链（不重跑整波）**。
   先例（现取）：`close-wave-142038`（`#79` 自己的整波）= `WFREEZE_BLOCKVALUES=FAIL gen=#78 declared_shifts=0 bad=5`。
3. **两个时刻的九位（`§六` 要求）**：
   - 时刻①（冻结那一刻，按块内 `九位（Release 权威件）` 行）：`bridge 4e25e4b27d4d5ae1`｜`pc 5b6cfda3e12b84fc`｜`pf b9a4f3a0e48e688d`｜`windowsbase 9e860cbeecb352e1`｜`provider 7e8a217b4165a6b9`｜`win32shim 6825dd7071387a46`｜`wic_shim f7b3026c8c019be2`｜`hbtextline 921ba9c65e9fb3be`｜`dwf c83be96f18759edc`
   - 时刻②（写哨兵那一刻，哨兵九键现取）：**与①逐位相同，差异位 = 无**
   ⇒ 判定：**本代两趟 post 未重建这九件**（否则会逐位具名）；差异位为空 ⇒ 无需"结构性 vs 一次性"的分派。
4. **`provider` 三时刻**（只报事实、不归因）：
   `759ac1686e5ef87d`（`#79` 块**声明值**，冻结那一刻的值，亦 = `Provider/bin/Debug` 件现读）→ `8cb1b50619f4c133`（**哨兵值** ＝ `GENS['#80']['prev_provider']`，`02:23:33` 重建后）→ `7e8a217b4165a6b9`（**live 现取**，本代冻结值）。
   ⚠️ `~/w21-verify/w27-freeze.py:443-444` 注释把两个值写成同一个（**陈旧**）；**本波不改仪器**（冻后动仪器＝让 `#80` 读数不可复算），列 §10 具名项。

## §7 推送与哨兵（账实）
- **一笔推送**：`71603bd..57cd937  HEAD -> feat-Linux`（`staged=61`）；`ls-remote` 现取 **`57cd9370606cffc219945a38fad334568fe133ee`** ＝ 本地 `HEAD`；`REMOTE_PER_COMMIT=PASS n=3`（`993eb5d5..57cd937` 逐笔在场）；**`PORCELAIN=0`**。
- **推牙（窗口牙）**：`INFP_AT_PUSH=FROZEN_INFP=abc76bd55f513b8d…` ⇒ **`INFP_FREEZE_PUSH_MATCH=PASS`**（本代不再需要"具名位移放行"路径）＋ `INFP_RULER2=SAME_SOURCE_AGREE` ＋ `INFP_COUNT_RULER=PASS（live=226 == 声明常数 226）`。
- **清单 ↔ `porcelain`**：`FILES` 由 75 件扩到 **121 件**（+46 件本代新落仓件，逐件在命令输出里点名），`staged=61` ⇒ **双向差集：`porcelain − FILES = ∅`（无静默漏）／本笔 − FILES = ∅**；`porcelain` 终值 **0**。
- **两哨兵**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**；两件 sha16 同 **`f2ab94d32b8e1e40`**；`mtime 12:21:26.453246830 +0800`（**由本笔推送重写**）。内容（题定值）：`WAVE=w80-freeze`／`BASELINE=#80`／`BASELINE_SHA16=b96d4312565a3c49` ＋ 九位（§6-3 时刻②）。
- **块件未被动过**：推送后现取 `b96d4312565a3c49` ＝ 冻结值 ✔（`CS:9` 亦仍 `gen=#80 sha16=b96d4312565a3c49`）。

## §8 `D-G178` 候选（**主控仪器缺陷**，本波只登记不改）＋ **同族在车道侧咬到我**
- 主控现场：`w27-freeze.py` 的 `_block_of_prev()` 入口锚**严格行首**（`:1316-1321`），而 `_BLK_HDR`（`:1221`）容忍降级装饰；冻结器自己在 `:1706` 给上一代块加 `# ⏪ **（历史，已被 #NN 取代）**` 前缀 ⇒ **冻后 `--prev-check-only '#80'` 报 `PREVCHECK=REFUSE baseline-has-no-RE-FROZEN-#79-block rc=2`（假红）** ⇒ 独立复验者最坏会去动已冻结的基线。
- **同族现场（我的车道侧，已修）**：`~/w79c/bin/w79-push.sh` 的 `FROZEN_INFP` 原先按 `sed -n '/^# RE-FROZEN #79/…'` **严格行首**取块 ⇒ `#80` 冻结后该行被加装饰 ⇒ `FROZEN_INFP=<缺> … reason=no-frozen-infp-in-#79-block ⇒ 停手，不推送`（**该笔提交已生成但零部分推送**）。修法：取**全文第一处** `` `inputs_fp` = `…` `` 声明（最新块在最前，装饰与否无关）⇒ **判据语义不变**（仍是"在册声明 == 现取"）⇒ 复跑 `PASS`。

## §9 死根面只读审计（`§五`；本波只审不改）
| 件（行号） | 调用面（调用点＋步名） | 是否真走该 `Root` | 结论词 |
|---|---|---|---|
| `build/MilBridge/tests/T2eLineHeight/Program.cs:24` | **无运行期调用者**（`grep -c 'T2e' verify-all.sh` = 0；`run.sh:181` 只在注释提到其产物；`build-hygiene-import-check.sh:213` 只把 `.csproj` 列进卫生名册＝编译不跑） | 不可达 | **`unused`** |
| `build/MilBridge/tests/CoverageProbe/Program.cs:88`（另 `:1028`／`:1159` 局部字面量） | **三支 tab 臂宿主**（`retake-arms-w23.sh:109-128`；`tline-gate.sh` 读其日志） | 宿主被真跑；命令行给活树绝对路径；**本趟三支臂日志死根签名 = 0** ⇒ 该面未触达或静默回退 | **`used`** ＋ 死根面 **`NOINFO(臂日志零签名)`** |
| `build/MilBridge/tests/PcLineOracle/Program.cs:171` | **`verify-all.sh:691` `run_step "PcLineOracle·Start 列"`**（本趟 gate1/pre 该步 ✅ `红=0 绿=421 判定行=421`） | 探针真跑；`grep -c '\bRoot\b'` = 1 ⇒ **常量只有声明、无引用** | 探针 **`used`**／该常量 **`unused`** |
- **守卫射程洞（现取原文）**：`build/MilBridge/tools/pkg-src-retiredpath-check.sh:108-110` 的 `tree` 面只扫 `-name '*.sh' -o -name '*.py' -o -name '*.c' -o -name '*.h'` ⇒ **`*.cs` 不在射程** ⇒ 十件 `.cs` 带死根而守卫全绿。**本波不改牙**，列 §10。

## §10 未闭项（逐条具名；本波不登记号值以免 `DEFREG` 立刻红）
1. **`D-G176`（预留）**："九位跨同一输入两次整波不复现（同源同参、机制未定）"＋"因此冻结与哨兵必须是最后两个动件"＋"`blockvalues-shift.tsv` 重钉与 `[5c/6]` 同趟不可兼得"（§6 两条）。
2. **`D-G178`（候选，主控仪器）**：`w27-freeze.py` 入口锚严格行首 vs 出口锚容忍装饰 ⇒ 冻后 `--prev-check-only` 假红（§8）。
3. **三条死根面**（§9）：`T2eLineHeight:24` 清字面量；`PcLineOracle:171` 删常量；`CoverageProbe:88` 的 `NOINFO(未触达或静默回退)` **必须查清**（`NOINFO` 不许当绿）。
4. **守卫射程**：`pkg-src-retiredpath-check.sh` 的 `tree` 面不扫 `*.cs`（§9 原文）。
5. **仪器注释陈旧**：`w27-freeze.py:443-444` 的 `provider` 两值重复（§6-4）。
6. **`FILES` 累积语义**：`~/w79c/bin/w79-push.sh` 的清单是**累积**的（本笔 121 件 vs 本笔入笔 61 件）⇒ 建议下一波改成"每波一份清单 ＋ 逐件归宿"的形态（本波如实记，未改）。
7. **`arm-logs` 硬链接形态**：本波以"删输出侧孪生"达成 `ALIAS=PASS`；若要保持 README 的"仓内是硬链接"形态，需在 `repo-alias-allow.tsv` 声明该树（上限＝现读件数）（§2-3）。

## SELF（自指口径）
本文件自指纹口径：`head -n -1 | sha256sum | cut -c1-16`（末行即本行，逐次重算）。
