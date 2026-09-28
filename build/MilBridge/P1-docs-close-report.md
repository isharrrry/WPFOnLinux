# `P1` 文档收口集成报告（车道 `t14`，波 `#80` 后）

> **报告自报**：本件整份 `sha16` 与 `head -n -2` 口径**自指** ⇒ 由 `t15`／队长现取（本件末尾 `SELF` 行给口径）。
> **读数时刻**：`2026-09-28T12:26–12:29+08:00`（个别另注）。**零重活**（无构建／无应用／不占槽）；进程只按 PID。
> ⚠️ **推送与两哨兵未做** —— 按队长**硬协调①**（必须排在 `t57` 之后）⇒ 本件状态 ＝ **文档收口已完成、推送挂起**。

## §1 现场（现取）
| 项 | 值 |
|---|---|
| `HEAD` | `57cd9370606cffc2` |
| `ls-remote origin feat-Linux` | `57cd9370606cffc2` |
| 块件 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | **`b96d4312565a3c49`** |
| 两哨兵 | `cmp` **IDENTICAL**；`WAVE=w80-freeze`／`BASELINE=#80`／`BASELINE_SHA16=b96d4312565a3c49` |
| `docs/CURRENT-STATE.md:9` | `BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 …`（**唯一**声明处；`:8` 散文里的陈旧世代值归 `D-G173`／`t40`，本趟未动 `:8`／`:9`） |
| `porcelain`（我改完后） | **10** 件 |
| `verify-all.sh` | **55 步**（首行 `DECL` 55 `gen=#80`）；覆盖面 **225 件**（`[42] --expect 225`） |

## §2 `[Next]`／`[MVP]` 逐条结账

**抽取域与计数（现算；脚本 `~/w14a/audit.py`）**：全文含 `[Next]`／`[MVP]` 且含 `TASK-\d{4}` 的行 ＝ **113 行**；**§13 树行 77**（树内唯一 TASK **77** 个）／**非树行 36**。
**树内状态（翻转后现算）**：**✅75 ／ 🔴2 ／ 🟡0 ／ ⚪0** —— §13 计数行已同趟改成该值（原文保留）。

### 2.1 本趟翻转的 7 处（原判词**一字未删**，每处各加 dated 结账行）
| TASK | 翻转 | 证据（件＋字段＋sha16／读数） |
|---|---|---|
| `TASK-0747` | 🔴→✅ | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 现取 **`6825dd7071387a46`**（`SHAppBarMessage` 符号 **1**；此前 `fc60c34d51fd9247` ＝ **0**）；`win32shim` 冻结位 `e8127a3d7128d417`（波 `#78`） |
| `TASK-0750` | 🔴→✅ | `build/MilBridge/tools/root-entries-allowlist-check.sh` **`d050d78198e6093c`**；真树 `ROOT_ALLOW=PASS examined=22` |
| `TASK-0751` | 🔴→✅ | `build/MilBridge/tools/wiring-closure-check.sh` **`a1ae1257ffd2638e`**；`WIRING_CLOSURE=PASS steps=55 undeclared=0 fails=0` |
| `TASK-0752` | 🟡→✅ | 三臂 `baseold 242/3808`｜`absent 357/3923`｜`ret0 0/3629`（`DIAG=0/1` 齐） |
| `TASK-0753` | 🟡→✅ | 正向三腿 `G147=PASS`／反向三腿 `G147=FAIL` |
| `TASK-0754` | 🟡→✅ | `DISPLAY_LEASE_GATE=PASS static=3/3 dynamic=11/11 examined=14`（`X-CENSUS` 一格 `NOINFO` **已具名，不折算成绿**） |
| `TASK-0755` | 🟡→✅ | `PROTO_ATTR_GATE=PASS examined=18 posctl=2/2` ＋ 逐行 `sock_id=present` |

### 2.2 未绿 `[MVP]` 三条（**不许折算成绿**；给现取证据与下一波归属）
| TASK | 终态 | 现取证据 | 下一波归属 |
|---|---|---|---|
| `TASK-0007` | 🔴 未绿 | 两页**仍洋红占位**（`t55` 现取：24 页 `magenta=54826 ink=423547 colors=851`／23 页 `magenta=50236 ink=428205 colors=843`；`alive=yes`／`rc=143`）；⚠️ 行内「**必死 `rc=134`**」是**旧读数** | 真因 `TASK-0302`；随 PTS 增量 |
| `TASK-0201` | 🟡 未绿 | 行内 `15 趟零命中`／`上界≈20%` 取自 **`TASK-0209` 修法之前**（`:206` 已有 dated 口径更正）；现件代重取见该行 dated 追加（车道 `t44`） | 复测功效口径（`t3`／`t10` 族） |
| `TASK-0302` | 🔴 未绿 | **可操作缺口 88／实现口径 95／工具口径 100**；`PTSGAP=PASS tool=100 dead=11 artifact=1 ops=88 impl=95 so16=6825dd7071387a46 exports=556`；在册旧数 `111` 已证 `TOOL-UNSOUND` | 本波新增**具名前沿跳数**口径（§3.3） |

### 2.3 非树行（36 行）机器清单（`sym`＝状态符号；`sha`＝该行 16 位 hex 个数；`rep`＝是否引报告）
```
:408 TASK-9905 [N] sym=✅ sha=5 rep=1
  :412 TASK-9906 [N] sym=✅ sha=1 rep=1
  :414 TASK-0203 [N] sym=✅ sha=2 rep=1
  :424 TASK-0304 [N] sym=✅ sha=0 rep=0
  :425 TASK-0305 [N] sym=✅ sha=0 rep=0
  :426 TASK-0306 [N] sym=✅ sha=0 rep=0
  :432 TASK-0205 [N] sym=✅ sha=1 rep=1
  :438 TASK-0107 [N] sym=✅ sha=0 rep=1
  :444 TASK-0108 [N] sym=✅ sha=0 rep=1
  :475 TASK-0110 [N] sym=✅ sha=3 rep=1
  :488 TASK-0111 [N] sym=✅ sha=2 rep=1
  :508 TASK-0210 [N] sym=✅ sha=2 rep=0
  :513 TASK-0211 [N] sym=✅ sha=3 rep=0
  :519 TASK-0703 [N] sym=✅ sha=0 rep=0
  :525 TASK-0704 [N] sym=✅ sha=0 rep=0
  :546 TASK-0705 [N] sym=✅ sha=1 rep=0
  :573 TASK-0706 [N] sym=✅ sha=0 rep=0
  :582 TASK-0707 [N] sym=✅ sha=0 rep=0
  :593 TASK-0708 [N] sym=✅ sha=1 rep=0
  :599 TASK-9907 [N] sym=✅ sha=4 rep=1
  :693 TASK-0716 [N] sym= sha=0 rep=0
  :705 TASK-0717 [N] sym= sha=0 rep=0
  :716 TASK-0719 [N] sym= sha=0 rep=0
  :733 TASK-0750 [N] sym=✅ sha=0 rep=1
  :734 TASK-0751 [N] sym=✅ sha=0 rep=1
  :736 TASK-0752 [N] sym=✅ sha=1 rep=0
  :737 TASK-0753 [N] sym=✅ sha=0 rep=0
  :738 TASK-0754 [N] sym=✅ sha=0 rep=0
  :739 TASK-0755 [N] sym=✅ sha=0 rep=0
  :788 TASK-0007 [N] sym=✅ sha=0 rep=0
  :789 TASK-0007 [M] sym= sha=1 rep=0```

## §3 本波必须落册的更正（逐条给证据）
1. **在册自相矛盾（`TASK-0209`）已消**：`docs/ROUTES.md` 的 `TASK-0203` 子树那句「产品侧修复另立 `TASK-0209` ⇒ `D-G109` 仍红、不许当"已修"」**原文保留**，其下加 **dated 裁定**：机器读数 `git log` **`ef1dc8f`**（wave(#55)：冻结 `#55`（`38320d5e377a0dc8`）＋ **`TASK-0209` 修 `win32_msg.c:57-82`** 队列链遍历）＋ `~/w136a/LANDED.done`（**134 B**，在位）＋ `src/WpfGfx.Linux.Native/src/win32_msg.c` **`4a88fffb1a0cd7f1`** ⇒ **`TASK-0209` ＝ ✅（随波 `#55` 冻结并推送；`§15w` 早已写 `🔴 → ✅`）**；**`D-G109` 的"仍红"只对「异源＋残余」那一半成立**（与 `TASK-0203` 的**测量交付**分开记账）。
2. **过期读数清扫（导出面三口径）**：本页新增 dated 现取块 —— **在册口径** `wc -l < src/WpfGfx.Linux.Native/bin/exports.txt` ＝ **`556`**｜**`nm -D --defined-only`** ＝ **`556`**｜**`nm -D` 全量** ＝ **`648`**；四处历史站点（`:469`／`:484`／`:511`／`:675` 的 `547`）**点名判为历史读数**（各带波次语境）。⚠️ **更正派单里的两个数**：派单写「`550`／`642`」，**现取是 `556`／`556`／`648`**。PTS 面 `111`／`impl 97` **已由前波改准**（现取 `88`／`95`／工具 `100`、`so16=6825dd7071387a46`、`exports=556`），本趟只加口径块。
3. **`W78A §2.1` 更正已落册**：`build/MilBridge/W78A-report.md` 末尾 **dated 追加**（原文一字未动）—— `InitFloaterObjInfo`（`PtsCache.cs:648-666`）／`InitTableObjInfo`（`:673-726`）**只填回调结构体、不调 native** ⇒ 那两条导出**不在上下文创建链上**（只在 native→managed 回调里被调：`PtsHost.cs:1094/1098` → `PtsCache.cs:259/278`）⇒ **预期前沿由 `idx4` 改为 `idx6`**，且「故意停在 `idx4`」**不可用**；同趟把 **「进度 ＝ 具名前沿跳数，不是缺口条数」** 写进 `docs/ROUTES.md` 的 `TASK-0302` 子树（证据：`#66` 的 `P03` 假进度 ＋ 现取 `evidence/app_g1.log` `eb6af2e16ba2bcfb` 的 `3× entry=LoCreateContext`／`0× CreateInstalledObjectsInfo` ⇒ 前沿跳数 **0 → 1**）。
4. **九位权威产物是「本地物件」**（现取）：`.gitignore:22-26` 忽略 `src/WpfGfx.Linux.Native/bin/` ⇒ `git ls-files …/libwpfwin32.so` ＝ **0**、`…/exports.txt` ＝ **0**；该 `.so` 现取 **336,984 B**／`6825dd7071387a46` ⇒ **干净克隆取不回、必须重建**（`R8` 判据① 正是「干净 clone ＋ 按 README 从零构建」）。已写进 `README.md`／`docs/RELEASE-READINESS.md`／`docs/CURRENT-STATE.md`／`docs/ROUTES.md` 四处 dated 块；**未结账项＝「九位产物不进 git ⇒ 交接靠构建或 `~/w-keep-shims/`」**。
5. **README「账一」**：现取 **已由 P0 迁移波完成逐字点名更正**（`README.md:180`「**根目录那份不使用** —— **那句已被证伪**」＋两条独立机制 ＋ `error MSB4236`）⇒ 本趟**不改判词**，只加末尾 dated 块；⚠️ **入册（新号）未落**：号值**待配号**（`t57`／队长），本趟**不动 route 件**（队长硬协调①）。
6. **`docs/INDEX.md`／`docs/unimplemented.md`**：各加 dated 块（现场对齐 `#80`／块件／唯一声明点／55 步／225 件；PTS 条按 `pts` 波真实结果＋具名前沿跳数口径；产物不进 git）。

## §4 被改件逐件 before→after（`temp+rename`；备份取在任何写之前）
| 件 | before sha16 | after sha16 | 行数 |
|---|---|---|---|
| `docs/ROUTES.md` | `e5b963493548931d` | **`709ab499060cd6db`** | 795 |
| `build/MilBridge/W78A-report.md` | `0dbc62b1d1cf86ee` | **`720e12fceb761941`** | 583 |
| `README.md` | `9ad1ea09b05389ca` | **`4f9ecf32fbdc0b6a`** | 235 |
| `docs/RELEASE-READINESS.md` | `a5125bee7930be42` | **`df0cc9cd84a98a37`** | 113 |
| `docs/CURRENT-STATE.md` | `5f5670f32967935e` | **`13077b52c938f8af`** | 944 |
| `docs/INDEX.md` | `a6cf2c435087b6c7` | **`ab78a99c40f54b9f`** | 85 |
| `docs/unimplemented.md` | `d170bf69e621d6b1` | **`06eaf0492ca735dd`** | 620 |
**两腿**：①前缀腿 —— `docs/ROUTES.md` 之外六件均为**纯追加**（`cmp` 前缀断言：原文字节全等）；`docs/ROUTES.md` 本趟**三笔**（翻转＋计数行／§3.2 块／§3.3+§3.6 块），其 9 处为**行内状态位翻转**（原判词全文保留在同一行内、紧随其后另起 dated 行）；②单元腿 —— 每个新增 dated 块 `grep -c` **恰 1 次**。

## §5 四项门禁（现取 `2026-09-28T12:28:29+08:00`）
- `DEFREG=**FAIL** reason=undeclared-id-in-route`（`DEFREG_ROUTES=KD=3b9abdfd0c619391 CS=13077b52c938f8af HO=a4d8ffcf4c37f6fe AB=b96d4312565a3c49`；`DEFREG_DECLDRIFT=4 keys=KD,CS,AB,KRJ`）—— **归因**：`KD` 现含 `D-G176`／`D-G177`／`D-G178`（车道 `t57` 正在入册）而声明表尚未 `--emit` ⇒ **该红归 `t57`**；我**未新增任何未声明号值**（新写文本只引 `D-G70`／`D-G109`／`D-G129`／`D-G173` 四个**已声明**号）。
- `REPORTID=**FAIL**` —— 四处点名**全在** `build/MilBridge/P0-w80-report.md`（`:60`／`:82`／`:95`／`:96`，即 `D-G176`／`D-G178`）⇒ **同归 `t57`**；**我改的 7 件被点名 0 次**。
- `BOUNDARY_DECL=**PASS** records=2 pass=2 fail=0 coverage=4/6 gaps=0 bystanders=2 corpus=61 rc=0` ✔
- `PIPEFAIL_SIGPIPE=**PASS** undeclared_hit=0 declared=0 files=106 sites=96 hit=0 safe=84 runs=12` ✔

## §6 我推翻了哪句话
1. `docs/ROUTES.md` 的 `TASK-0747`／`0750`／`0751`／`0752`／`0753`／`0754`／`0755` **7 处状态位**与现场不符 ⇒ 翻 ✅（证据见 §2.1）。
2. 「`TASK-0209` ⇒ `D-G109` 仍红、不许当已修」**读起来像"产品修法未做"** ⇒ 与波 `#55` 的落地事实不符（§3.1）。
3. `build/MilBridge/W78A-report.md:170`／`:171`「上下文创建期**无条件**调用」⇒ **错**（不在创建链上；`idx4→idx6`）。
4. `TASK-0007` 行内「**必死 `rc=134`**」⇒ **旧读数**（现取 `rc=143` ＋ 洋红占位）。
5. **派单里的数**：导出面 `550`／`642` ⇒ 现取 **`556`／`556`／`648`**；`verify-all.sh:1173` ⇒ 该行现取是 `fi`，`run_step "PTS-PAGES"` 真实行号 **`1174`**。

## §7 `NOINFO` 清单（既不算绿也不算红）
1. **推送与两哨兵：未做**（队长硬协调①：必须排在 `t57` 之后）⇒ 本件**不声称**已推、不声称哨兵已换成我的文档那一笔之后的代。
2. **`D-G176`／`D-G177`／`D-G178` 入册与 `--emit`**：归 `t57`（我**未动** `KD`／`declared.tsv`）。
3. **README「账一」的新号入册**：**待配号**（`t57`／队长）。
4. `docs/INDEX.md`／`docs/unimplemented.md` **逐段**与现场一致性：只做 dated 块 ＋ `#80` 现场钉，**未逐段重写**旧段 ⇒ 该格 `NOINFO`。
5. `[Next]` 表的**逐行原文**：本件给**机器生成清单**（113 行／树 77／非树 36 ＋ 每行 `sym/sha/rep`），**未**把 113 行原文抄进本件（避免第二份真相）。
6. `build/MilBridge/HANDOFF-NEXT.md`：按队长硬协调②**本趟不动**（`t54` 已写三节、`t57` 只追加一行）；其 §7 的 `R=` **现取已是 git 树路径**（`:105` `R=/home/links-dev/netTest/GitProj/WPFOnLinux`）⇒ 该格**已验证满足、无需改**。

SELF=件外现取（自指）
