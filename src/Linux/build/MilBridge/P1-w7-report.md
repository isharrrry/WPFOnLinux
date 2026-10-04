# P1-w7-report —— W7：`TASK-0302` PTS 增量一个（`LoCreateContext` 真实现 ＋ `LoDestroyContext` 真销毁）

> **车道** `runner`／**任务** `t63`（attempt 1）。**写域** ＝ 契约三条 ＋ 队长本趟批的扩域（`bin/exports.txt`／`pts-gap-decl.txt`／`ROUTES.md`／`KD`／`README.md`／`HANDOFF-NEXT.md`／`docs/unimplemented.md`，**仅限"这些数所在的行"**）。
> **一句话**：把 **`LoCreateContext`** 从「诚实失败 stub」做成**真对象**（并修掉一条**签名错**：修前是两参形，把 NULL 写进了调用方的回调表地址）＋ 同趟补 **`LoDestroyContext`** 真销毁（否则 create 成功会让清理期撞未导出入口 ⇒ 症状倒退）；**能力真前进一格**、**零症状倒退**（before/after 两腿都 `alive=yes`／`app_rc=143`、无 `EntryPointNotFoundException`／`abort(134)`）。
> ⚠️ **但按「进度 ＝ 具名前沿跳数」这条判据，本增量记「具名跳数**不成立**」**：具名缺口 `entry=LoCreateContext` **3→0**（这一格成立），可**下一站无名** —— 载体里应用侧只记 **`entry=unknown`** ⇒ `PTSGAP_FRONTIER_STATE=UNNAMED`（**响亮、不许当绿**）。**算不算"进度"请队长/用户裁定**（`t64` 的硬前置「`TASK-0302` 真落地」按本件读数是"能力真落地、下一站未命名"）。
> **读取时刻**：全文读数现取于 `2026-09-28T20:34–20:50 +08:00`，逐格带亚秒 `ts=`。

---

## §1 判据（先写；含本趟新加的三条口径句，已写进 `pts-gap-count-check.sh` 件头）

1. **进度 ＝ 具名前沿跳数**，**不是缺口条数** —— `impl = ops + stubs` 是**缺口计数** ⇒ **真进步让 `impl` 下降**（本增量实测 `95 → 94`，随后因"名字离开名单"再 `→ 93`：**能力前进，数却变小**）⇒ **计数口径在本增量上读反了**。
2. **门禁步 `PTS-PAGES` 只读** `leg_*.env` 的列（`alive`／`app_rc`／`magenta`／`colors`），**不读 `entry=`** ⇒ **它的绿对「前沿位移」零证据力**（不许拿 `PTS-PAGES=PASS` 当进度证据）。
3. **前沿读数的唯一载体** ＝ `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` 的**具名** `entry=<名>` 行（应用侧自报）；「下一站无名」⇒ `PTSGAP_FRONTIER_STATE=UNNAMED`。
4. **假进度必红**：**计数下降**（`impl` < 基线）**∧ 前沿名未动** ⇒ 牙判 `FAIL reason=FAKE-PROGRESS`（`#66` 的 `P03` 形态：3 个 `Lo*` 名字离开名单而能力为 0）—— 由**装置自身**判红，不靠人读日志。
5. **不许症状倒退**：after **不得出现** `EntryPointNotFoundException`／`abort(134)`；两腿 `alive`／`app_rc`／`magenta`／`colors` 必须成对给出。
6. `NOINFO`／无读数 ⇒ 如实具名，**既不算绿也不算红**。

---

## §2 为什么本增量必须"两条一起做"（**逐字留档**，队长点名要这句）

**① 修前的真实缺陷是"签名错"，不是"少实现"**：托管声明（`LineServices.cs:1407-1411`）是**三参**
`LsErr LoCreateContext(ref LsContextInfo contextInfo, ref LscbkRedefined lscbkRedef, out IntPtr ploc)`，
而修前 shim 是**两参**形 `(const void *, void **)` ⇒ 第二实参落在 `lscbkRedef` 上 ⇒ **把 NULL 写进调用方的回调表地址**（`*lscbkRedef = NULL`），且**从不写 `ploc`**。
**② 只做 create ⇒ 症状倒退**：create 成功 ⇒ `_ploc` 非零 ⇒ 清理路径 `TextFormatterContext.Destroy()`（`upstream/…/TextFormatterContext.cs:243`，由 `TextFormatterImp.CleanupInternal()` 逐上下文调用）会去调 **`LoDestroyContext`**；该入口修前**未导出**（托管侧声明 **18** 个 `Lo*`，shim 只导出 **3** 个）⇒ `EntryPointNotFoundException` ⇒ 本端口注释点名的 **`abort(134)`**（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:30/160/745`）⇒ **把"优雅降级（页级占位）"换成"清理期崩"**。
⇒ 本车道的处置：**停下报队长**（不硬推、也不硬掰），队长裁定**方案 A**（create 真实现 ＋ destroy **真销毁**）并扩了两个写域件。

---

## §3 改动（产品面 ＋ 判据面；逐件 sha16 成对，带 `ts=`）

| 件 | 改前 sha16 | 改后 sha16 | `numstat` | 要点 |
|---|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `73bb1ba58a264f72` | **`bdf6e9f8a1b61eae`** | `100 17` | 格2：三参真 create ＋ 真 destroy ＋ 表/自检/报告面同步 |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `6825dd7071387a46` | **`2a5165700a8c8579`** | （构建产物，`mtime=2026-09-28 20:43:58.465727781`） | 导出 **556→557** |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | 556 行 | **557 行** | （构建重生成，`build-shim.sh --symbols`） | 新增 `LoDestroyContext` |
| `build/MilBridge/tools/pts-gap-count-check.sh` | `9eccf056bf2d7417`(判据端另件) | **见 §7 现取** | `49 5` | 件头三条口径 ＋ 前沿段 ＋ 自测 L8/L9 |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `# PTSGAP-DECL: … ops=88 impl=95 so16=6825dd70… exports=556` | **`… ops=87 impl=93 so16=2a516570… exports=557`** | `5 1` | 重锚 ＋ dated 说明 |
| `win32_classification.c`／`ROUTES.md`／`KD`／`README.md`／`HANDOFF-NEXT.md`／`docs/unimplemented.md` | — | — | `1 1`×4 ＋ `7 7` ＋ `2 2` | **只改数字**（逐处对照见 §6） |
| `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log`（**前沿载体**） | `eb6af2e16ba2bcfb`（116,911 B，`mtime 09:32:46`） | **`cb0a3e5510b07790`**（108,365 B） | `33 148` | 旧件**留档** `~/t63-runner/artifacts/app_g1.log.before-eb6af2e16ba2bcfb`（**未静默换内容**） |

**产品面实现要点**（`win32_pts.c` 格 2）：
- `LoCreateContext(const void *lscontextinfo, const void *lscbkRedef, void **ploc)` —— **三参对齐**；成功 ⇒ `0` ＋ **真句柄**；失败 ⇒ `-10000` ＋ `*ploc = NULL`（**成功给空句柄／失败给非空句柄两种自相矛盾形态都禁止**）；两个入参指针**原样存、不 deref**。
- `LoDestroyContext(void *ploc)` —— **真销毁**：**只认本模块自己分配并登记的句柄**（按**指针身份**查登记表，命中后才比自己的魔数）；`NULL`／未知／重复 ⇒ **一律拒（≠0）且一个字节都不 free**；未知句柄的**内容一个字节都不读**。
- **自检（器件内的牙）**：`PTS_SELFCHECK == 1` 现在要求 create **成功且句柄非空**、destroy(**own**)==0、**重复/未知(0xdeadbeef)/NULL 全被拒**、收尾 `ls_context_live == 0`，且报告行里 `frontier=LoAcquirePenaltyModule`（**前沿位移就在这一格**）。

---

## §4 两极化真跑（**仓外夹具** `~/t63-runner/bin/loc-polarity.c`，链接新 `.so`；原文照抄）

```
PTS_SELFCHECK=1 (期望 1)
LEG-A1 create ret=0 handle=非空
LEG-A2 destroy(own) ret=0 (期望 0)
LEG-B1 destroy(repeat) ret=-10000 (期望 !=0)
LEG-B2 destroy(0xdeadbeef) ret=-10000 (期望 !=0) 进程存活=yes
LEG-B3 destroy(NULL) ret=-10000 (期望 !=0)
LEG-B4 create(out=NULL) ret=-10000 (期望 !=0)
LEG-C1 二轮 create/destroy ret=0/0 (期望 0/0)
REPORT PTS_GAP_REPORT mode=honest-fail entries=0 calls=0 first=- last=- err=-10000 frontier=- entry_calls=0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0 8:0 9:0 installed_objects_live=0 creates=0 destroys=0 rejected=0 ls_context_live=0 creates=2 destroys=2 rejected=4
LOC_POLARITY=PASS fails=0
```
- `ls_context_live=0 creates=2 destroys=2 rejected=4` ⇒ **零泄漏**、四条拒绝面（重复／未知／NULL／出参空）**各命中一次**。
- `frontier=-` 是**自检复原台账**的后果（自检不许改变可观测状态）⇒ 与件头纪律一致；自检**内部**已断言 `frontier=LoAcquirePenaltyModule`。

---

## §5 跳数成对（**前沿唯一载体**；原文照抄）

**before（我自己真跑，`ts=2026-09-28T20:38`，`rc=0`，两腿）**：
```
3 entry=LoCreateContext        （唯一具名 entry）
PTS_GAP entry=LoCreateContext seq=1 err=-10000 calls=1
[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage entry=LoCreateContext err=-10000 action=page-placeholder
[HC-UNHANDLED] #1 PtsUnavailableException …
```
**after（`ts=2026-09-28T20:45`，`rc=0`，两腿）**：
```
entry=unknown ×2              （**没有任何具名 entry**；shim 台账**一行都没有**）
[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage entry=unknown err=-10000 action=page-placeholder
[HC-UNHANDLED] #1 PtsUnavailableException …
```
⇒ **成对读数**：`entry=LoCreateContext` **3 → 0**（具名缺口**已闭**）；**新前沿 ＝ `unknown`（应用侧无名）**。
⇒ 牙现取（两遍逐字同）：`PTSGAP_FRONTIER before=LoCreateContext@3 after=unknown@2 carrier_sha16=cb0a3e5510b07790 … ` ＋ **`PTSGAP_FRONTIER_STATE=UNNAMED`**。
⇒ **判定**：**「具名前沿跳数」这一格＝不成立**（不是"没动"，是"**下一站没有名字**"）⇒ 按 §1-①，**本增量不计具名进度**；**这一格我记 FAIL**（见 §9 验收表）。

**症状倒退检查（成对，全部现取）**：
| 量 | before | after |
|---|---|---|
| `EntryPointNotFoundException` | 0 | **0** |
| `abort(134)` | 0 | **0** |
| `LoDestroyContext`（应用侧文本） | 0 | **0** |
| `leg_24.env` | `alive=yes app_rc=143 magenta=54826 colors=851` | `alive=yes app_rc=143 magenta=55058 colors=852` |
| `leg_23.env` | `alive=yes app_rc=143 magenta=50236 colors=843` | `alive=yes app_rc=143 magenta=50468 colors=844` |
⇒ **无倒退**（两腿都活着、同一 `app_rc`；占位像素数略升，方向与"少一层失败"一致，但**不作因果主张**）。

**下一站的机械归因候选（源码级，**不是读数** ⇒ 记 `NOINFO`）**：`TextFormatterContext` ctor 里 create 之后**只有托管代码**（`UnsafeNativeMethods.*` 在该 ctor 内**只出现 `LoCreateContext` 一次**，现取 `grep -n`）；路径上紧随的 LS 入口是 `LoSetBreaking`／`LoCreateLine`／`LoCreateBreaks`／`LoCreateParaBreakingSession`／`LoSetDoc`／`LoSetTabs` —— **六个全未导出**（`grep -cx <名> exports.txt` 逐个 = `0`）⇒ 若走到它们即 `EntryPointNotFoundException`（应用侧**不打印异常类型**，故日志里读不到那个词）。**要把它变成具名读数**：把紧随其后的那一个 LS 入口按 `P03` 形制补成**具名诚实失败 stub**（**又一次动 `exports` 锚** ⇒ 需另派一趟）。

---

## §6 假进度判红腿（**原样输出**）＋ 复述位传播

**① 活体判红（本趟真的红过一次，原文照抄）** —— 当 `LoDestroyContext` 导出后**名字离开了缺口名单**（`tool 100→99` ⇒ `ops 88→87`）而**载体还没换代**（仍记 `LoCreateContext`）时：
```
PTSGAP_FRONTIER before=LoCreateContext@3 after=LoCreateContext@3 carrier_sha16=eb6af2e16ba2bcfb …
PTSGAP_FRONTIER_STATE=NAMED frontier=LoCreateContext（具名前沿成立）
  FAKE-PROGRESS impl=93 < 基线 95 而前沿仍是 LoCreateContext ⇒ **名字离开名单而能力为 0**（假进度）
PTSGAP=FAIL tool=99 dead=11 artifact=1 ops=87 impl=93 so16=2a5165700a8c8579 exports=557
```
⇒ **这就是 `#66` 的 `P03` 形态被装置自己抓住**（名字离开名单 ⇒ 计数变好看，而能力/前沿没动）。
**② 自测两极（`--selftest`，现取）**：`L8 计数下降而前沿未动（假进度**必须红**） ⇒ FAIL ok`｜`L9 计数下降且前沿真位移（**不得假红**） ⇒ PASS ok`｜`PTSGAP_SELFTEST=PASS pass=9 fail=0 legs=9 must_red=6`。
**③ 复述位传播（只改数字；逐处"改前→改后"＋件级 `numstat`）**：
```
工具口径 **100** → **99**      ｜ 工具报缺 **100** → **99**
可操作缺口 88 → 87 ／ **可操作 88 → 87 ／ 可操作 88 条 → 87 条 ／ 可操作 88／ → 87／
实现口径 95 → 94 → 93（两段：先按"少一条 stub"，再按"名字离开名单"）
numstat：README.md 1/1 ｜ HANDOFF-NEXT.md 1/1 ｜ ROUTES.md 7/7 ｜ docs/unimplemented.md 2/2
         ｜ KNOWN-DEFECTS.md 1/1 ｜ win32_classification.c 1/1
```
**④ 收口读数（两遍逐字同）**：`PTSGAP=PASS tool=99 dead=11 artifact=1 ops=87 impl=93 so16=2a5165700a8c8579 exports=557 root=/home/links-dev/netTest/GitProj/WPFOnLinux`，`rc=0`；`DEFREG=PASS declared=222 route_ids=222`、`DEFREG_DECLDRIFT=0`（`KD --emit` 同趟重发，`DEFREG_ROUTES … KD=22ccdcbc47c088a2`）；`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`（第 `28` 条 cell=#1 已同趟追写）。

---

## §7 交件成对读数（每格带亚秒 `ts=`）

| 格 | before（`ts` 见列） | after | 备注 |
|---|---|---|---|
| 被改产品件 | `win32_pts.c=73bb1ba58a264f72`（`ts=20:36:55.131957236`） | **`bdf6e9f8a1b61eae`** | 唯一产品源码改动件 |
| `win32shim` 位 | `6825dd7071387a46`（`mtime 10:30:08`） | **`2a5165700a8c8579`**（`mtime 2026-09-28 20:43:58.465727781`） | **九位里唯一位移的一位** |
| 另八位 | `bridge/pc/pf/windowsbase/provider/wic_shim/hbtextline/dwf` 全同 | **全同**（逐位见 `~/t63-runner/logs/build.log` 的 `NINE_BEFORE/AFTER`） | ⚠️ 本趟**只重建 native** ⇒ `provider` **未动**（与 `B-18` 的"每次构建动 provider"不同，**如实记录**） |
| `exports` | 556 | **557** | `LoDestroyContext` 入面 |
| 在册数 | `tool=100 dead=11 artifact=1 ops=88 impl=95` | **`tool=99 … ops=87 impl=93`** | 名字离开名单 ＋ 少一条 stub |
| `inputs_fp` | `fe923e2ece011537…`（`ts=20:36`） | **`37b6131378bccb68…`**（`ts=20:50:00.718845769`） | 覆盖面件内改动 ⇒ 必移 |
| 覆盖面件数 | **234** | **234** | **未变** ⇒ `[42] --expect 234` 不动 |
| 四不变量 | `^run_step "`＝**62**｜`--expect 234`（唯一）｜`:9`＝`gen=#80` | **同上，逐条未变** | 本趟**不加步、不改声明** |
| 前沿载体 | `eb6af2e16ba2bcfb` | **`cb0a3e5510b07790`** | 旧件留档到车道 |
| 槽 | `HEAVYSLOT=ACQUIRED waited=0s`（`avail=6906MB`） | `RELEASED rc=0 held=30s`（批）／构建批 `held=2s` | `TIMEOUT`／`NOINFO`／`MAXHOLD_KILL` **各 0** |

---

## §8 🔴 `D-G188`（我报、队长已立号）：`session_inner.sh` 的占用闸拒绝它自己的官方调用者（**我的绕过读数原样给出**，供 `t68` 当反例腿）

- **官方腿路现取跑不起来**：`run-pts-pages-legs.sh` 自己起 `Xvfb :237`（日志 `X_UP=yes display=:237`）后调 `session_inner.sh` ⇒ 后者立刻：
  `DISPLAY_OCCUPIED=:237 sock=/tmp/.X11-unix/X237 ⇒ 拒跑（号已被占；请用 W67_DISPLAY=<空闲号> 或先按 PID 收净）`
  ⇒ 整批 `rc=1`、`PARSE-ERR 一个 leg_*.env 都没写出`（**`PTS-PAGES` 腿路整条死**）。
- **我的绕过手法（原样，供 `t68` 做反例）**：设它自己的覆盖旋钮 `WPF_X11_DIR=<空目录>` ⇒ 同一趟读出
  `DISPLAY_LEASE=free display=:237 sock=/home/links-dev/t63-runner/x11-decoy/X237`
  ⇒ **闸看到的"租约目录"是伪造的**，而真实 `:237` 正被自己占用 ⇒ **保护是名义的**（一个环境变量即可静默旁路）。
- 本件**不修**这两个件（写域外）；`t68`（`scribe`）接手。

---

## §9 验收表（逐格如实；**有一格我记 FAIL**）

| 契约验收项 | 判 | 证据 |
|---|---|---|
| `pts-gap-count-check.sh` 现取 `PTSGAP=PASS` 且 `ops=`／`impl=`／`tool=` 三口径同时印出 | **passed** | `PTSGAP=PASS tool=99 … ops=87 impl=93 …`（两遍逐字同，`rc=0`）；阈值/命令由本件现取确定、**未沿用推测值** |
| 前沿跳数成对（以载体具名行为准，给前→后） | **passed（成对读数已给）** | `entry=LoCreateContext` **3→0**；after 无具名 entry（`unknown`×2）；`ts` 见 §5 |
| 「**具名**前沿位移」成立（本任务的核心判据） | ❌ **failed（如实）** | `PTSGAP_FRONTIER_STATE=UNNAMED`：下一站无名 ⇒ **不计具名进度**；下一步＝把紧随的 LS 入口补成具名诚实失败（需动 `exports` 锚，另行派单） |
| 假进度必红（装置自身判红，给原样输出） | **passed** | §6 活体判红原文 ＋ 自测 `L8 FAIL ok`／`L9 PASS ok`（`pass=9 fail=0`） |
| 九位位移留痕（不当红） | **passed** | §7：`win32shim` 位移（`6825dd70…→2a516570…`）＋ mtime；另八位同；`provider` **未动**（如实） |
| 资源纪律（走槽＋后台、显示独占、跑前现取、槽参数入册） | **passed** | 构建批 `--min-avail 2500 --max-hold 900 --wait 1800`（`held=2s`）；腿批 `--min-avail 1500 --max-hold 1800 --wait 1800`（`held=30s`，`waited=0s`）；`ts=20:36:55` 现取 `avail=6902MB swapfree=1408MB df=72,706,052KB` |
| 不越域（`ROUTES`／`KD`／`declared.tsv`／两哨兵） | **passed（含队长批的扩域，逐行只改数）** | 本趟改了 `ROUTES.md`／`KD`／`declared.tsv`／`HANDOFF-NEXT.md` —— **均在队长本条消息批的扩域内**；**两哨兵未动**（`cmp` 未跑即未写）；`numstat` 逐件 1/1 或 7/7 |
| 交件含写入前后成对读数（件 sha16／`inputs_fp`／覆盖面／九位）且每格带 `ts=` | **passed** | §7 全表 |
| 载体落 `build/MilBridge/P1-w7-report.md`，末行 `head -n -1` 自证 | **passed** | 本件；全文 `sha16` 只在交件消息里给 |

---

## §10 `NOINFO`／未做／边界（逐条具名）

1. **下一站归因** ＝ `NOINFO reason=next-frontier-unnamed`：应用侧只记 `entry=unknown`；shim 台账**零行** ⇒ 失败**不在**任何已导出 stub 上；源级候选是六个**未导出** LS 入口（§5）。
2. **`provider` 位未动**：本趟只重建 native（`build-shim.sh`），**没跑托管构建** ⇒ 与 `B-18`（"每次构建动 provider"）**不适用**；九位里唯一位移是 `win32shim`（如实记录，不当红）。
3. **`WAVE66` 的 `C3` 冻证据被本增量"取代"**：该条要求三条 `LsErr` 诚实失败"各 `ret == -10000`"；`LoCreateContext` 现在**真的成功** ⇒ 该句只对历史成立 ⇒ **冻证据一字不动**（`w66pre16=bf6b683d94549087` 仍在 pin 内、文件未改），**取代关系由 `pts-gap-decl.txt` 的 dated 说明 ＋ 本件登记**。
4. **未跑整趟门禁／未跑 `verify-all`**：本趟只跑了两支相关牙（`pts-gap-count-check`／`pts-pages-guard` 的 `--selftest` 与 live）＋ `DEFREG`／`HANDOFF-MV`。
5. **用户现场不外推**；「两页仍洋红占位」这一事实**未变**（`magenta` 数仍是大头）⇒ 本增量**不声称页面可用**。

---

## §11 我推翻了哪句话

1. **推翻"PTS 三十条缺口里 `LoCreateContext` 只是'没实现'"这个隐含读法**：现取证明它是**签名错**（两参 vs 三参）⇒ 修前它**污染调用方的回调表地址**（写 NULL）⇒ 这条比"缺实现"更严重。
2. **推翻"只做 create 就行"**：只做 create ⇒ 清理期撞**未导出**的 `LoDestroyContext` ⇒ `EntryPointNotFoundException`／`abort(134)`（本端口注释点名的老症）⇒ **必须两条同趟**。
3. **推翻我自己上一趟的判据假设**：我在 `t20` 里假设"实现一格 ⇒ `impl` 减一"；现取发现**连 `tool`／`ops` 都会动**（`LoDestroyContext` 导出后**名字离开缺口名单**：`tool 100→99`、`ops 88→87`）⇒ 在册数是**三格联动**，不是一格。
4. **推翻"门禁绿 ⇒ 有进度"**：`PTS-PAGES` 只读 `leg_*.env` 的列、**不读 `entry=`** ⇒ 它的绿对前沿位移**零证据力**（本件把它写死在判据件件头）。
5. **`D-G188`（新）**：`session_inner.sh` 的占用闸**拒绝自己的官方调用者**，且**可被一个环境变量静默旁路** ⇒ "保护是名义的"。

---

## §12 交件结论（首段给队长点名要的两句并列）

- **计数口径读反了**：`impl` 是**缺口计数** ⇒ **真进步让它下降**（`95 → 94`，再因名字离开名单 `→ 93`）；**能力前进了，数却变小**。
- **具名前沿位移**：`entry=LoCreateContext` **3→0**（**具名缺口已闭**）；**下一站 ＝ `unknown`（无名）** ⇒ **本增量不计"具名跳数"**（`PTSGAP_FRONTIER_STATE=UNNAMED`）。
- **产品事实**：`LoCreateContext` 真对象（三参 ABI 修正）＋ `LoDestroyContext` 真销毁；导出 `556→557`；`PTS_SELFCHECK=1`；两极化 `LOC_POLARITY=PASS`（重复/未知/NULL/出参空四条拒绝面全中、零泄漏）。
- **零症状倒退**：两腿 `alive=yes`／`app_rc=143`；`EntryPointNotFoundException`／`abort(134)` **各 0**。
- **锚与传播**：`impl 95→94→93`／`exports 556→557`／`so16` 换、`ops 88→87`／`tool 100→99` 走 6 件 17 处（只改数）；`PTSGAP=PASS`、`DEFREG=PASS declared=222`、`HANDOFF_MV=PASS`。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-w7-report.md | sha256sum | cut -c1-16`）= `4e4d4ee6309cfa54`
