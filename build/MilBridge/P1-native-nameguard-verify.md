# P1-NATIVE-NAMEGUARD-VERIFY（`t93` 独立复核 · W20「native 侧纵深防御」· `t92` 的件）

> **本席只读仓树、只写本件。** 复核对象＝**入账面** `fe6f551`（`fix(#81): t92 native 纵深防御落地 …`，`2026-09-29T00:39:24+08:00`），面 ＝ `src/WpfGfx.Linux.Native/src/win32_pts.c +130/−2`／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt 1/1`／`build/MilBridge/P1-native-nameguard-report.md +251`／`build/MilBridge/P1-w8-step2-criteria.md +304`／`build/MilBridge/HANDOFF-NEXT.md +1`（`git show fe6f551 --numstat` 现取；**无判据件、无注册表件**）。
> **本席现取（`ts=2026-09-29 00:39:34.824326169 +0800`）**：`HEAD=fe6f551`｜`src/WpfGfx.Linux.Native/src/win32_pts.c` **`823298d182c6d271`**（mtime `00:31:51`，＝`HEAD` 版）｜`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` **`657f448c2077ba1f`**（346088 B／mtime `00:32:02`；**部署件同值** `/home/links-dev/w67-work/app/libwpfwin32.so`）｜`src/WpfGfx.Linux.Native/bin/exports.txt` `71d651b16c6d9d6e`（561 行）｜托管件 `83ba5884bb603296`（未随本件动）｜`build/MilBridge/P1-native-nameguard-report.md` `40b43e9fe4c8ed5b`｜`pts-pages-guard.sh` `944e61f39f24631c`。
> **A/B 的"修前"极（本席自己钉）**：`d6ab99b`（改动前基线）的 `win32_pts.c` ＋ `t92` 的 `cp -p` 备份 `~/t92-runner/bak/libwpfwin32.so.pre-t92`（`3bd193e54785b5db`／346032 B／mtime `2026-09-28 23:15`）—— 该备份只作**只读对拍物**（不作其结论的引据）。
> ⚠️ **并发披露（本席窗口内两次现取，如实记两个值＋时刻）**：`build/PresentationFramework.Linux/PtsCache.Linux.cs` 正被**另一写者（`t95`）**改成 `6fecbab40f639616`（`+37/−2`，题记逐字点名处置 `t91` 的 `G-4`／`G-5`）⇒ 本件**不判**该在飞改动。托管产品件因此**在窗口内换代**：`ts=00:39:34` 时 Release ＋部署件 ＝ **`83ba5884bb603296`**（＝本席 `e2e` 夹具实际加载的那件）；`ts=00:40:45` 时已被在飞写者重建并同步为 **`6893d1d3fb1ee110`**（mtime `00:39:48`，源码 `6fecbab40f639616`）。native 两件（仓内＋部署）在本件窗口内**未动**（`657f448c2077ba1f`）。
> **仪器全部本席自造、仓外、零构建**：`python3`＋`ctypes` 直读两个 `.so`（含 canary 填 0xAA 探"碰不碰缓冲"）；`pwsh 7.6.6` 反射现成托管产物做端到端（不编译任何件）。

---

## ① 截断名真的没了（成对读数，**成立**）

**夹具 P（同一支脚本、同一台账造法，只换 `.so`）逐档现取**：

| `cap` | **修前** `3bd193e54785b5db` | **修后** `657f448c2077ba1f` |
|---|---|---|
| 4 | `rc=1` name=**`'LoA'`** | **`rc=0` name=`''`** |
| 5 | `rc=1` **`'LoAc'`** | **`rc=0` `''`** |
| 12 | `rc=1` **`'LoAcquirePe'`** | **`rc=0` `''`** |
| 21 | `rc=1` **`'LoAcquirePenaltyModu'`** | **`rc=0` `''`** |
| 22（＝名长） | `rc=1` **`'LoAcquirePenaltyModul'`** | **`rc=0` `''`** |
| 23（＝名长＋1） | `rc=1` 全名 | `rc=1` 全名 |
| 24 / 128 | `rc=1` 全名 | `rc=1` 全名 |

- **现册最长名**（`LoGetPenaltyModuleInternalHandle`，**32 B**，我自己从 `k_pts_entries[]` 取长）同法逐档：`cap=1/2/4/5/12/31/32 ⇒ rc=0 ＋ 空串`，`cap=33/34/128 ⇒ rc=1 ＋ 全名`。⇒ **任何不足档都不再返回"貌似完整的短名"**（修前那 5 档的短名在修后一格不剩）。
- **调用者能不能明确判定「没拿到名」**：**能，且两条路都通**——① `rc=0`（唯一"没拿到"形态）；② 内容＝空串。三路（放不下／越界／无该 idx）**归一**成同一形态：`idx=COUNT`／`idx=COUNT+5`／`idx=-1` ⇒ 全 `rc=0`＋`buf=""`；`buf=NULL ⇒ 0`；`cap=-1 ⇒ 0`；`cap=0 ⇒ rc=0` 且 **canary 逐字节未碰**（`buf[0..3]=aaaaaaaa`）。⇒ **不判红**。
- **无越界写**：每个档都先 `memset(buf,0xAA)`，实测 **nul 之后的字节仍是 canary**（`nul后canary=1` 全档）⇒ 只写"名＋nul"。
- **端到端（托管侧，新 `.so`＋`83ba5884bb603296`，`pwsh` 反射现取）**：全新进程 `NativeEntryName=unknown`／`report_len=250`／`NativeError=-10000`；打一次 `LoAcquirePenaltyModule` 后 ⇒ **`NativeEntryName=LoAcquirePenaltyModule`**（真名）／`report_len=292`；`GapEntryNameAt` 在 `cap=22/23 ⇒ <null>`、`cap=24/32/33/128 ⇒ 真名` ⇒ **两层纪律相容**（托管侧那层照旧保守一档，见 `H-4`）。

## ② `O-1` 语义可判（**成立**，射程已在册写明且可机器核）

**夹具 N（长报告串态，`n=292`）逐档现取**：

| `cap` | `rc` | `strlen` | `strlen==cap-1` | 末字节＝nul | 内容＝完整行的前缀 |
|---|---|---|---|---|---|
| 0 | **-1** | （不碰 buf，canary 未动） | — | — | — |
| 1 / 2 / 10 / 64 / 128 / 200 / 249 / 291 | **-1** | `0/1/9/63/127/199/248/290` | **全 True** | True | True |
| 292（＝`n`） | **-1** | 291 | True | True | True |
| 293（＝`n`+1） | **+292** | 292 | True | True | True（＝整行） |
| 294 / 300 / 4096 | **+292** | 292 | False | False（不写多余字节） | True |

- **按 `rc` 判的读者**：`>0` ⇒ 完整行（长度即 `rc`）；`-1` ⇒ **唯一**的"没拿到完整行"形态（`cap=0` 与 `buf=NULL` 亦 `-1`）。**忽略 `rc` 的读者**：拿到的是**该完整行的精确前缀 ＋ 一个 nul**，**不越界、不夹栈垃圾**。
- **"忽略 rc 会读半截行"这条的处置＝在册写明射程（不是彻底关掉）**，且写清了三处、可机器核：代码注释三条（`:1214-1226` 现取）＋ 自检新格 **格 `80`**（canary 断言：`rc==-1 ∧ strnlen==cap-1 ∧ buf[cap] 起仍是 canary`）＋ 托管侧**唯一的消费者**一律 `rc <= 0 ⇒ continue`（`NativeReport()`，`:1214` 段现取）。⇒ **不含糊**，**不判红**；残留风险单列 `H-2`。
- **`-1` 是否唯一失败形态**（我自算）：`cap ≤ n` ⇒ `-1`；`cap ≥ n+1` ⇒ `+n`；无第三值（遍历上表 13 档，`rc ∈ {-1, 292}`）✓；`buf=NULL`／`cap≤0` ⇒ `-1` ✓。
- **新助手未导出**：`WpfLinuxWin32_PtsGapReportTailIsClean` 现取 **`ABSENT`**（`hasattr` 探针）⇒ 与"导出面零位移"一致。

## ③ 不许放宽 / 不许动数（**成立**）

- **`k_pts_entries[]` 语义不变**：把该数组块**逐字节**对拍 —— `d6ab99b` 版与现盘版 **同为 `af5e19b4b78b3094`** ✓（名册 12 名、最长 32 B）。
- **格号数值不许改**：把 `rc = <数>` 的**有序序列**从 `d6ab99b` 与现盘抽出、现盘去掉新号 `80/81` 后 `diff` ⇒ **`SEQUENCE_IDENTICAL`（65 项逐项相同）**；集合面 `comm` 现取＝**被删的号 0 个**、**新增 2 个（`80`、`81`）** ⇒ 旧号一个未动、一个未改名。两个新号的**代码路径**我读到原文：`:984 else if (!g_pts_selfcheck_o1_canary()) rc = 80;`／`:985 else if (!g_pts_selfcheck_f3_boundary()) rc = 81;`（即 `80` ＝ O-1 缓冲不变式面、`81` ＝ F-3 边界面）。
- **纪律 30（调用史敏感）本席读数写明 fresh vs 带历史**（仓外 `ctypes` 直读现盘 `.so`）：
  - **fresh 进程** ⇒ `SelfCheck()=1`、`SelfCheckDiag()=0`（全过）；
  - **带历史①**：先 `LoCreateContext(NULL,NULL,&loc)`（活上下文）⇒ `SelfCheck()=0`、`Diag()=25`；
  - **带历史②**：建上下文 ＋ `LoSetDoc` ＋ `LoSetBreaking` ＋ `DestroyContext`（已收干净）⇒ `SelfCheck()=0`、`Diag()=32`。
  ⇒ 自检**仍然是"干净起点"口径**（`t89` 入册的纪律 30 成立），**本件未改**这三个格号。
- **导出面零位移（三重证据，全部我自己现取）**：
  1. `nm -D --defined-only` 行数 **561** ＝ `exports.txt` 行数 **561** ✓；
  2. **导出名集合逐个对拍**：修前 `.so`（`pre-t92`）561 名 vs 现盘 561 名 ⇒ **`SYMBOL_SETS_IDENTICAL`**（`diff` 无输出）；新助手 `canary|f3_boundary|tail_is_clean|TailIsClean` 在导出集中命中 **0**；
  3. `exports.txt` 与 `pre-t92` 备份 **逐字节相同**（`cmp` ⇒ 同 hash `71d651b16c6d9d6e`）。

## ④ 验证链（本席自跑，**成立**；⚠️ 同趟性仍断，见 `H-1`）

- **`pts-gap-count-check.sh`（现取，`rc=0`）**：`PTSGAP=PASS tool=97 dead=11 artifact=1 ops=85 impl=91 so16=657f448c2077ba1f exports=561` ⇒ `so16` **＝现盘 `.so`**（声明件同趟）；`PTSGAP_FRONTIER before=LoCreateContext@3 after=LoAcquirePenaltyModule@3 carrier_sha16=e348b4ef70ab521e carrier_mtime=2026-09-29 00:09:11`；`PTSGAP_FRONTIER_STATE=NAMED`；`PTSGAP_CITED=PASS refs=1 strict=1`。
- **`pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence`（现取，`rc=0`）**：`PTS_G10_NAME=PASS observed=LoAcquirePenaltyModule names=1 roster=12 domains=pts-declared`；`PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded`。
- **两页症状与前一代成对（现取 `git diff ac29ff1^ ac29ff1 -- …/leg_2*.env`）**：`alive yes→yes`／`app_rc 143→143`（∉{134,139}）／`ns` 逐字同／`native_gap 0→1`（degraded 期设计内）；`magenta 50461→49943`、`55051→54533`；`ink` 微增；`DEV shim 2a5165700a8c8579→3bd193e54785b5db`、`pf 8ef62d37e7c2ce2e→b3f0d129f0234b58`（**＝上一代**，见 `H-1`）。零症状面：`t92` 那趟 runner 日志现取 `2 unh=0`、`CLICK k=23/24 … fatal=0 guard=1 pts_gap=1`、`AE=141283/221857`（**与本件在册 `ae=` 逐位相同**）、`POSTSHIM: shim=657f448c2077ba1f pf=83ba5884bb603296`。
- ⚠️ **`H-1`（medium）同趟性两轴均断**：在册（门禁真读的）证据 `DEV … shim=3bd193e54785b5db pf=b3f0d129f0234b58`，而现盘产品件 `657f448c2077ba1f`／`83ba5884bb603296` ⇒ **两条轴都不同趟**（`t92` 那趟腿用的是新件、`POSTSHIM == authority`，但**没有换代到在册目录**：`git status` 现取在册 `evidence/**` 无改动、hash/mtime 仍是 `00:09`）。**无判据读 `DEV shim/pf`**（我 grep 全仓工具：只有 `pts-pages-guard.sh:456` 在自检夹具里**写**一条假 `DEV` 行）⇒ 今日不构成红，但**收尾前必须换代一次**。

## ⑤ 不变量 / 指纹 / 哨兵 / `D-G189`（**成立**）

- **覆盖面**：`infp.sh list` 现取 **234** 条。
- **`inputs_fp`**：`ts=2026-09-29 00:39:07.921001818 +0800` ⇒ **`f4a21769b3d6399339d9ddb2dc99ec106ca6b4e345803d46b36be508abf15834`**；`HANDOFF-NEXT.md` 末条 `cell=#1`（`:628`）登记 `ts=2026-09-29T00:34:09.065148408+0800` 时现值 ＝ **`f4a21769…`（同值）** ⇒ **一致** ✓（`t92` 的 `>>` 追写在覆盖面**未**位移时取的，值相符）。
- **两哨兵**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**（文件 sha16 `80b300de0921c6f5`）；字段**现取** `SHA=4e25e4b27d4d5ae1`、**`WIN32SHIM=657f448c2077ba1f`**、`WAVE=w80-freeze`、`BASELINE=#80`（`BASELINE_SHA16=b27ff6332f263495` 未变）。**`WIN32SHIM` 轴：与现盘 native 件逐位相符**（`.so` 换代后哨兵**已同趟更新** ⇒ 不该重写）✓。
  ⚠️ **`PF` 轴在飞滞后（本席窗口内的事实，见 `H-5`）**：`ts=00:39:34` 时哨兵 `PF=83ba5884bb603296` 与当时的现盘托管件相符 ✓；`ts=00:40:45` 现取**哨兵仍 `PF=83ba5884bb603296`**，而托管件已被 `t95` 在飞重建为 **`6893d1d3fb1ee110`**（仓内＋部署件同值）⇒ **`PF` 轴不同趟**。该换代属**在飞件**（未提交），本件**不判其红**，只如实记两轴各自的状态。
- **`HANDOFF_MV=PASS`**：`cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`（现取）。
- **`D-G189` 未被虚假扩大**：本件提交面 `numstat` 现取**无** `KNOWN-DEFECTS.md`／无判据件；注册表现取 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` `a92e6e73f2a4f4a5` ＝ `git show HEAD:` 版同值（mtime `2026-09-28 23:23:19`，最近提交 `800d0e1`）⇒ 本件零改动；`D-G189` 出现 **3** 次（正条 ＋ `t82` 追加的第二面）⇒ 面数未增。旁证 `defect-registry-check.sh` ⇒ `DEFREG=PASS declared=224 route_ids=224` `rc=0`。

## ⑥ 载体与边界自证

- **唯一写入** ＝ `build/MilBridge/P1-native-nameguard-verify.md`（新建，UTF-8，首记号 `# P1-NATIVE-NAMEGUARD-VERIFY`，**非** `# ⏪ `，`mode 644`，末行自带可复算自报口径 sha16）。
- **未改 `t92` 任何件**：`win32_pts.c 823298d182c6d271`／`.so 657f448c2077ba1f`／`exports.txt 71d651b16c6d9d6e`／`pts-gap-decl.txt`／`P1-native-nameguard-report.md 40b43e9fe4c8ed5b`／`pts-pages-guard.sh 944e61f39f24631c` —— 复核前后同值。
- **边界**：只读仓树；**未**跑整趟门禁、**未**构建、**未**跑腿、**未**占显示位、**未** `git add/commit/push`；夹具（`native_probe.py`／`probe2.py`／`pair.py`／`e2e.ps1`／各 `*.out`）**全部在 `~/wv88y/t93/` 仓外**，收尾**删净**（仓内残留仅本件）。
- **判词可复现**：夹具脚本已删，但每条结论都带**命令原文＋读数＋件 hash**；主读数落在现盘可复算的件上（两个 `.so`（其一为 `t92` 的 `cp -p` 备份）／`win32_pts.c`／`exports.txt`／`pts-pages-guard.sh`／`pts-gap-count-check.sh`／`git show|diff`）。

## Findings（不改 `t92` 任何件；要改的以「夹具＋读数」给出）

- **`H-1`（medium）同趟性两轴均断**：在册证据 `shim=3bd193e54785b5db`／`pf=b3f0d129f0234b58` vs 现盘 `657f448c2077ba1f`／`83ba5884bb603296`。本件改的正是 `entry=`／`native_gap` 那两面背后的 native 读口 ⇒ **门禁真读的证据已落后一代**；`t92` 那趟腿虽 `POSTSHIM == authority`，但**未换代在册目录**。今日无判据读该字段 ⇒ 非红，**收尾前需换代**。
- **`H-2`（low）内容面无法自证截断**：报告行**没有 in-band 结束标记**（行尾无换行、无 `end=` 字段），`cap` 不足时忽略 `rc` 的读者拿到的是**良构前缀**——"这行是不是完整"只能由 `rc` 或"字段齐不齐"判。射程已在册写明（注释三条＋格 `80`）⇒ 目前**可判**；但任何**将来**忽略 `rc` 的新读者会静默误读。修法二选一：行尾加固定终止字段，或把"必须看 `rc`"写进 `DllImport` 旁的强约束注释（后者已部分存在）。
- **`H-3`（low）`exports.txt` 是构建副产品、不在 git 中**：`git show d6ab99b:src/WpfGfx.Linux.Native/bin/exports.txt` 现取 **不存在** ⇒ "`git diff` 为空 ⇒ 未改"在本件上是**空证明**（我原先那一步作废）。本件的零位移已改由**三重证据**承担（`nm` 名集逐个 diff＋新助手全 `static`＋与 `cp -p` 备份逐字节 `cmp`）——结论不变，但**证据路径要更正**。
- **`H-4`（low，结转／在飞）**：`t91` 的 `G-2`（①路措辞仍短路）、`G-3`（`a..so`／±前导过宽）本件未动、**仍开**；`G-4`（注释 31 B/96 B）、`G-5`（`cap==len+1` 保守）正被**另一写者 `t95`** 在 `PtsCache.Linux.cs` 里在飞处置（现取 `6fecbab40f639616`／`+37/−2`，题记逐字点名 `G-4`／`G-5`）⇒ 本件**不判**该在飞改动，待其落地后另行复核。
- **`H-5`（low；本席窗口内新出现，非 `t92` 之过）**：`t95` 在飞重建托管件并同步部署件（`83ba5884bb603296 → 6893d1d3fb1ee110`，`00:39:48`），**哨兵 `PF` 仍停在 `83ba5884bb603296`** ⇒ `PF` 轴不同趟（`WIN32SHIM` 轴同趟 ✓）。**与 `H-1` 叠加**：此刻在册腿证据的 `pf` 已落后**三代**（`b3f0d129f0234b58` ⇒ `83ba5884bb603296` ⇒ `6893d1d3fb1ee110`）⇒ 收尾换代时须一次对齐到当时现盘值。

## `NOINFO`（不折绿、不折红）

1. **格 `80`／`81` 的"必红"反腿**：要造"删长度守卫""越界写""rc 谎报"三种假形态必须**重编译** ⇒ 本任务**禁构建**，未跑。可得的代替＝代码路径原文（`:984/:985` 两条 `else if`）＋ fresh 进程自检 `1/0` ＋ 带历史两档 `0/25`、`0/32`（**我自取**）。
2. **整趟门禁 / 真实显示面 / 跑腿面**：本任务禁跑整趟门禁、禁占显示位、禁跑腿 ⇒ 未跑（④只用现盘判据与成对读数；两页读数取自 `ac29ff1` 那次重取的在册件）。
3. **`t92` 那趟腿的原始日志之外**：我只取到 `~/t92-runner/logs/legs.log` 的 `POSTSHIM`／`CLICK` 行；其**完整** `MEMOK`／槽位读数未在范围内（不引其载体结论）。

SELF-SHA16 （口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`）＝ d743b07bc0c8f7b5
