# P1-w7-close-report —— W7／`TASK-0302` 前沿具名判定落册（`t69` 补强；`runner`）

> **本件身份**：`t69` 的**补强**部分（队长 `2026-09-28T21:48` 现取裁定：`§13` 那条由**队长本人**已落册；`§15af` 侧的对应落点 ＋ 三格最新值与口径改派给本席）。
> **一件事一句话**：`§15af` 的「进度口径」段后面**新增一条 dated 结论行**（**只增不改**，`numstat = 1 0`），内容＝队长 `§13` 那条的**要点 ＋ 指向其内容锚**（不复制整段），并把 `tool/ops/impl` 最新值与**防读反口径**同趟写进该节。
> 🔴 **两写者规避（本席主动停手的一处）**：共享任务表现取显示 **`t69 [claimed] → verifier`**（`t70 [pending] → verifier`）⇒ 本席**没有**申请/接管 `t69`，**只做队长本条消息明确改派的那一处 `§15af` 追加**；若 `verifier` 亦在写 `docs/ROUTES.md`，请队长先收回/改派再让其动笔（本席本趟**只加了 `§15af` 一行**，未碰 `§13` 的任何一行）。
> **读取时刻**：`2026-09-28T21:47:40–21:48:51 +08:00`，逐格带亚秒 `ts=`。

---

## §1 写入前后成对读数（判据件 `docs/ROUTES.md`）

| 格 | 写前（`ts=2026-09-28T21:48:36.729716942`） | 写后（`ts=2026-09-28T21:48:51.068353489`） | 判据 |
|---|---|---|---|
| 全文 `sha16` | **`ce19680de862e7fc`** | **`2f611466dc4fee22`** | 变（＝内容变了，符合预期） |
| 行数 | **851** | **852** | **+1** |
| `git diff --numstat` | — | **`1 0`** | ✅ **只增不改**（删行 0） |
| 模式（两口径） | `stat -c %a`＝**644** ／ `git ls-files -s`＝**100644** | **同值**（`temp+rename` 后显式 `chmod 644`） | ✅ 守恒 |
| 硬链接 | `%h`＝**1** | **1** | ✅ 未造多重链接 |
| glyph 计数（`✅`／`🟡`／`🔴`） | **308 / 72 / 81** | **308 / 72 / 81** | ✅ **未新增任何记号**（本席本趟**零 glyph 增删**） |

**写前像留档**：`~/t69-runner/bak/ROUTES.md.pre-t69`（`cmp` 与写前现取逐位一致）。

### 逐行「改前→改后」（**唯一一处改动**）
```
锚定行（未动，内容锚＝「的进度口径（逐字，写进子树）」）：
  825  - 🆕 **`TASK-0302` 的进度口径（逐字，写进子树）**：**「进度 ＝ 具名前沿跳数，不是缺口条数」** …（原文一字未动）

新增（紧接其后插入，`diff` 输出 `825a826`）：
  826  - ⏪ **dated 结论 · W7（`TASK-0302` 首个增量）前沿具名判定「补强要点」（`t69` 落，读时 2026-09-28 21:48:51.068353489 +0800；上面各条原文一字未删）**：
       ① 能力前进（已落）：`entry=LoCreateContext` 3 → 0 ／ `exports` 556 → 557 ／ `so16` 6825dd7071387a46 → 2a5165700a8c8579 ／ `tool/ops/impl` 100/88/95 → 99/87/93；
       ② 前沿此刻不可具名（`PTSGAP_FRONTIER_STATE=UNNAMED`）：载体 `app_g1.log` 的 `entry=` 面只有 `entry=unknown` ×2；
       ③ 机制：具名闩取自 shim 台账（`WpfLinuxWin32_PtsGapCalls`／`WpfLinuxWin32_PtsGapReport`）⇒ 台账当期零行 ⇒ 失败发生在「未命中任何 shim 入口」的解析期 ⇒ 结构性无名（可判结论，非「没查到」）；
       ④ 候选池真、此刻不可达：缺口面 `Lo*` 17 行（`^Lo[A-Z]` 口径；若把 `LocbkGetObjectHandlerInfo` 一并计则 18）／`Fs*` 66 行；端口层 `grep` 现取无任何 `Lo*` 的 `DllImport`；
       ⑤ 要变成具名还缺什么：真实调用序上最先到达的那个入口必须先在端口层被触及（照 `t63` 对 `LoCreateContext` 的形制补成具名诚实失败 stub），否则台账无行、前沿永远无名；
       ⑥ 口径（防读反）：`impl` 是缺口计数 ⇒ 真进步让它下降（95→94→93）；进度判据是具名前沿跳数而不是缺口条数；门禁步 `PTS-PAGES` 只读 `leg_*.env` 的列、不读 `entry=` ⇒ 其绿对前沿位移零证据力；
       ⑦ `NOINFO`（具名）：不声称两页可用（23／24 仍洋红占位）；「不可具名」≠「无缺口」。
       **指向**：完整判词与逐块证据在 `§13` 的 `TASK-0302` 子树、内容锚＝「dated 结论 · W7（`TASK-0302` 首个增量）的「前沿具名」判定 ＝ 不可具名」那一条（队长落册，读时 2026-09-28T21:48:04+0800）；本行只补要点与指向、不复制整段、不改上面任何一行。
```
**纪律对照**：① 只增不改 ✅（`numstat 1 0`）② **内容锚**（锚定的是句首串，不是行号）✅ ③ **未新增 `✅/🟡/🔴`**（计数逐格同值，见 §1 表）✅ ④ **不自指**：新行不含本件/本节的任何自计数（唯一数字是**数据**：`3→0`／`556→557`／`unknown ×2`／`17|18`／`66`）✅。

---

## §2 我自己的复算（**未照抄队长现取**）

| 项 | 我的现取命令 | 我的读数 | 备注 |
|---|---|---|---|
| 缺口面总行数 | `python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier all`（真身在 `src/WpfGfx.Linux.Native/tools/`） | `rc=0`，`PresentationNative_cor3.dll` 名 **99** 行 | 与队长的「候选池」同源 |
| `Lo*` 族 | `awk '$1=="PresentationNative_cor3.dll"{print $2}'` 后 `grep -cE '^Lo[A-Z]'` | **17**（`^Lo[A-Z]`）｜**18**（`^Lo`，多出 `LocbkGetObjectHandlerInfo`） | ⚠️ **精度注记**：队长的「17」与我的「18」是**两个口径**（差的那一个就是首字母小写的 `LocbkGetObjectHandlerInfo`）⇒ 我在新行里**两个都写了**，避免后人按 17 去找却数出 18 |
| `Fs*` 族 | 同上 `grep -cE '^Fs'` | **66** | 与队长一致 |
| 端口层 `Lo*` 的 `DllImport` | `grep -rn 'EntryPoint *=*"Lo' --include='*.cs' build/ src/` | **0 命中** | 与队长一致 |
| 端口层 PtsGap 面 | `grep -rn 'WpfLinuxWin32_PtsGap' --include='*.cs' build/ src/` | 仅 `build/PresentationFramework.Linux/PtsCache.Linux.cs`（`PtsGapCalls` ＋ 注释里的 `PtsGapReport`） | 与队长一致 |
| 失败现场 | `grep -ac 'entry=unknown' …/evidence/app_g1.log` | **2**（`:511`／`:965`，逐字 `[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage entry=unknown err=-10000 action=page-placeholder`） | 与队长一致 |
| 现盘九位中的 `win32shim` | `sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **`2a5165700a8c8579`** | 与 `t63` 交付态一致（新行引用的就是它） |

**⇒ 结论不变**：前沿此刻**结构性无名**（台账零行 ⇒ 未命中任何 shim 入口的解析期），**不是**「下一站是某个名字」；要变具名必须先让**最先到达**的入口在端口层被触及并补成**具名诚实失败 stub**。

---

## §3 计数两口径／三格最新值（本件只动 `§15af`，未动 `§13`）

- **`§13` 域：本席本趟零写入**（`§13` 那条 dated 结论是**队长**落的：`595bfd7e9e04214d → ce19680de862e7fc`，读时 `2026-09-28T21:48:04.717772617`）⇒ `§13` 的任何计数口径**不由本件改动**，故本件**不**重算/不改写 `§13` 的两口径值。
- **本件改动的两口径（自算，改前→改后）**：
  - 口径 A（**全件行数**）：**`851 → 852`**。
  - 口径 B（**全件内容锚**）：**`ce19680de862e7fc → 2f611466dc4fee22`**。
- **`§15af` 侧三格最新值（同趟写进新行）**：`tool/ops/impl` ＝ **`99/87/93`**；`so16` ＝ **`2a5165700a8c8579`**；`exports` ＝ **`557`** ⇒ 与该节**上面那些 dated 历史行里的旧值**（`工具口径 100`／`so16=6825dd7071387a46`／`exports=556`／`3× entry=LoCreateContext`）**并存而不冲突**：历史行**原文一字未删**（只增不改），新值由本条 dated 行承载。
- **口径句（防读反，逐字）**：**`impl` 是缺口计数 ⇒ 真进步让它下降**（`95→94→93`）⇒「能力前进了、数却变小」；**进度判据是具名前沿跳数，不是缺口条数**；门禁步 `PTS-PAGES` 只读 `leg_*.env` 的列、**不读 `entry=`** ⇒ 它的绿**对前沿位移零证据力**；`UNNAMED` **不是绿**。

---

## §4 并发面与两写者规避（如实记）

- **队长**：已自行落 `§13` 那条（`ts=21:48:04`，纯插入 `1 0`），并在消息里明令本席**只补 `§15af`**。
- **`scribe`**：正在跑 `t73`（`build/MilBridge/tools/pts-pages-guard.sh` ＋ 追写 `HANDOFF-NEXT.md` 的 `cell=#1`）与 `t74`（重冻结批）⇒ **与 `docs/ROUTES.md` 无交集**，本席**未碰** `HANDOFF-NEXT.md`／`known-red.json`／`declared.tsv`／`ACCEPTANCE-BASELINE.md`／`CURRENT-STATE.md`。
- 🔴 **`t69` 的所有权冲突（本席停手点）**：共享任务表现取 **`t69 [claimed] → verifier`**、`t70 [pending] → verifier`。队长的两条消息把 `t69` 说成本席的（"改派给你做补强"），但**任务表未改派** ⇒ 本席**没有** `claim` `t69`（遵「不接管队友已 claim 的任务」），**只执行消息里点名的那一处追加**。若 `verifier` 随后也写 `docs/ROUTES.md`（尤其 `§15af`），**会出现两写者** ⇒ 请队长先把 `t69` 收回或明确改派。

---

## §5 `NOINFO`／边界（逐条具名）

1. **本件不声称**两页可用（`TASK-0007` 仍**洋红占位**）；「前沿不可具名」**不等于**「无缺口」。
2. **未跑整趟门禁**；未跑任何牙（本件只做一处文本追加 ＋ 只读复算）。
3. **未 `--emit`**：本趟**未改** `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`defect-registry-declared.tsv` ⇒ 按本仓体例**无需** `--emit`。
4. **两枚哨兵未动**；`src/**` 只读；`build/MilBridge/tools/**` 未动（`pts-pages-guard.sh` 属 `t73`）。
5. **`Lo*` 计数口径差 1**（17 vs 18）已在新行里并列写明（见 §2 精度注记），**不改**队长 `§13` 那条里的「17」。
6. `docs/ROUTES.md` 的行号**仅对本次写入时刻有效**（本仓体例；本件一律用内容锚）。

---

## §6 交件清单（每格带亚秒 `ts=`）

```
写前  ts=2026-09-28T21:48:36.729716942  docs/ROUTES.md sha16=ce19680de862e7fc 行=851 模式=644/100644 %h=1 glyphs=308/72/81
写后  ts=2026-09-28T21:48:51.068353489  docs/ROUTES.md sha16=2f611466dc4fee22 行=852 模式=644/100644 %h=1 glyphs=308/72/81
改动  git diff --numstat -- docs/ROUTES.md ⇒ 1 0（只增）；唯一改动 = 锚定行（内容锚「的进度口径（逐字，写进子树）」）之后插入 1 行（1164 字符）
备份  ~/t69-runner/bak/ROUTES.md.pre-t69（与写前逐位一致）
复算  缺口面 99 行 ｜ Lo* 17（^Lo[A-Z]）/18（^Lo）｜ Fs* 66 ｜ 端口层 Lo* DllImport = 0 ｜ entry=unknown ×2（:511/:965）｜ shim=2a5165700a8c8579
纪律  未动 §13 任何一行；未动 HANDOFF-NEXT/known-red/declared.tsv/AB/CS；未跑门禁；未 --emit；未新增 glyph；本趟仓内写入 = ROUTES.md（1 行）＋ 本报告
```

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-w7-close-report.md | sha256sum | cut -c1-16`）= `d1d431ffdda4d3a8`
