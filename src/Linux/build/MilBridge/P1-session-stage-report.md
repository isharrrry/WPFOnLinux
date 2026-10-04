# P1-W27 · 本会话阶段翻册收口（`t101`／`scribe`）—— `TASK-0302` 已走两步的实况 ＋ 两条真红的消解方式分离 ＋ 纪律 `29`／`30` 索引 ＋ 本波产品件换代序列

写者 `scribe`（`t101` attempt 1／`8018faf5-f939-41a5-a668-5e4a54f4b23c`）｜仓根 `/home/links-dev/netTest/GitProj/WPFOnLinux`（分支 `feat-Linux`，`HEAD` 现取 `e528f53`）｜读时 `2026-09-29T01:0x+0800`
**一切读数现取自算**（线索只当线索；凡与本席现取不符处**逐条点名**）。本件**不构建、不跑腿、不占显示位、不跑整趟门禁**；判据只在**仓外复制的证据副本**上跑（不碰在册件）。
**写域** ＝ `docs/ROUTES.md`（`§13` 三条 `[MVP]` 行各追一条 dated 行 ＋ `§15af` 尾追一条索引）＋ `build/MilBridge/HANDOFF-NEXT.md`（尾部**索引块**；机器值格 `cell=#1` **一行未动**）＋ 本载体（新建）。**未动** `src/**`／`build/PresentationFramework.Linux/**`／`tools/**`／`verify-all.sh`／`close-wave.sh`／哨兵／`tests/PtsPagesProbe/evidence/**`／任何判据件。

## §0 一句话

`TASK-0302` 这条月级长线**本会话真走了两步**（`t81` `800d0e1` 让台账**第一次真非零**；`t97` `b7e38ab` 让前沿**真前进一跳**并同趟补一处诚实 stub 以免 `rc=134`）⇒ 现取前沿 ＝ `entry=LoGetPenaltyModuleInternalHandle`（`names=2`／`roster=13`／`domains=pts-declared`），**下一步靶心 ＝ 该名**；两条真红**消解方式不同**（一靠**产品能力前进**、一靠**判据修正**），已分别入册；纪律 `29`／`30` 只加**索引**不复写条本体；本波产品件 `.so` **三代**、`pf` **两代**（`t97` **未重建 `pf`** —— 与线索不符，如实记）；`TASK-0007` 仍 `NOINFO(前置未达)`（**不许读成绿**）。

## §1 逐条处置 ＋ 现取读数 ＋ 落点

### ① `TASK-0302` 已走两步（**落点**：`docs/ROUTES.md` `§13` 里行首锚「`TASK-0302 [MVP]`」那一行的 dated 子行区，追 `t101` 收口一条）

- **第一步（`t81`，提交 `800d0e1`）** ⇒ **台账第一次真非零**。本席自算（`git show <提交>:<路径>`）：名册 `k_pts_entries[]` **`10` → `12`**（父提交 10 条、`800d0e1` 12 条）；声明面（在册 `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` 的 `PTSGAP-DECL:` 行）`exports` **`557` → `561`**、`so16` **`2a5165700a8c8579` → `3bd193e54785b5db`**、`ops/impl/tool` **`87/93/99` → `85/91/97`**。
- **第二步（`t97`，提交 `b7e38ab`）** ⇒ **前沿真前进一跳**。同法自算：名册 **`12` → `13`**；`exports` **`561` → `565`**、`so16` **`→ 461e5557bd7dd571`**、`ops/impl/tool` **`85/91/97` → `84/90/96`**（**读向：`impl` 是缺口计数 ⇒ 真进步让它下降**）。
  - **同趟补 `LoDisposePenaltyModule` 诚实缺口 stub 的代价（若不补）**：`TextPenaltyModule.Finalize()` 走释放路径时抛在 `GC.RunFinalizers()` ⇒ 整进程 `rc=134`。⚠️ **该因果链出自 `t97` 的载体 `build/MilBridge/P1-w8-step2-report.md`，本席未独立复跑**（如实标注为**引他人载体**）；**本席能现取的只是当期形态**：在册 `evidence/leg_{23,24}.env` 两腿 `alive=yes`／`app_rc=143`（stub 在位的反证面）。
- **现在的前沿（本席现取自算）**：
  - 在册证据 `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` 现取 **`eed6c1558509dd94`**；`entry=` 面 ＝ **`3 entry=LoGetPenaltyModuleInternalHandle`** ＋ **`1 entry=LoDisposePenaltyModule`**；台账 ＝ **`PTS_GAP entry=LoGetPenaltyModuleInternalHandle seq=4`**／**`PTS_GAP entry=LoDisposePenaltyModule seq=5`**；`leg_{23,24}.env` 的 `native_gap` ＝ **2**（＝ 台账真非零且两条）。
  - 判据（本席把在册证据**整目录复制到仓外** `/tmp/t101-ev` 再跑）：`rc=0`；**`PTS_G10_NAME=PASS observed=LoGetPenaltyModuleInternalHandle names=2 roster=13 domains=pts-declared`**；**`PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded`**。
  - 缺口判据：**`PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=90 so16=461e5557bd7dd571 exports=565`**（rc=0；＝ 在册声明值**逐字段相等**）｜`PTSGAP_FRONTIER before=LoCreateContext@3 after=LoGetPenaltyModuleInternalHandle@3 carrier_sha16=eed6c1558509dd94`｜`PTSGAP_FRONTIER_STATE=NAMED`｜`PTSGAP_CITED=PASS refs=1 strict=1`。
  - ⚠️ **`@n` 口径（本席读判据件现取，防误引）**：`after=<名>@n` 的 `n` ＝ **载体里该名出现的行数**（判据件现算 `grep -ac`），**不是**跳数、也**不是**名册序；`before=…@3` 的 `3` 是**声明值** `PTSGAP_FR_BEFORE_N`（默认 3）⇒ 「前进一跳」指的是**名字换了一站**这件事实，别把 `@3` 读成「第 3／4 跳」。**线索里写的 `after=…@4` 本席现取不成立**（现取 `@3`）。
  - **下一步靶心 ＝ `LoGetPenaltyModuleInternalHandle`**（现 `entry=` 面频次最高且**尚未被实现**的那一站）；`impl` 口径现取仍有 **90** 条缺口。

### ② 两条真红：消解方式**分开**记（**落点**：`docs/ROUTES.md` `§15af` 尾索引 §①）

- **(甲) `native-ledger-absent(PTS_GAP n=0)` ⇒ 靠「真前进」消解**：`t81` 让台账**第一次真非零**（本席现取 `native_gap` ＝ **2**）⇒ 判据件里那支 `[ "$ngap_total" -ge 1 ] || fails+=(native-ledger-absent(PTS_GAP n=0))`（`build/MilBridge/tools/pts-pages-guard.sh`，本席现读在位）**现取不被触发** ⇒ `PTS_GUARD=PASS legs=2/2 fails=-`。**不是**靠改相位／阈值／折叠红行（判据件由他人持有，本席未动它）。
- **(乙) `PTS_G10_NAME` 那条红 ⇒ 靠「判据修正」消解**：`D-G189` **第一面**（判据对其观测面的取值域作了**未声明假设** ⇒ 域一扩张就把**合法状态读成常驻红**，`t76`）＋ **第二面**（**归因锚太松**：旧 `decl_hit()` 只要求同一行同现 `DllImport` 与 `EntryPoint=` 字样 ⇒ **一条注释**即可把任意名字判成「在声明树里对拍上了」，`t77` 的 `F1`／`t82` 落地修法）⇒ 现取判据件里已是**真声明锚四条合取**（本席现读：属性起始行那一支 `^[[:space:]]*\[[[:space:]]*DllImport[[:space:]]*\(` 在位），现取 `domains=pts-declared` ⇒ 绿。
- ⇒ **两类消解不许互换**：一类是**产品能力前进**，一类是**判据强度提升**；把它们混成一类会让后人误以为"改判据也能换来能力"。

### ③ 纪律 `29`／`30` 索引（**落点**：`build/MilBridge/HANDOFF-NEXT.md` 尾部索引块；**不复写**条本体）

- 第 `29` 条 ＝ 「**备份面 ≡ 换代面**」（`t85`）：条本体**内容锚**＝「dated 纪律追加 · 第 `29` 条（「**备份面 ≡ 换代面**」）」（读时块头 `:598`，仅本次有效）。本席本趟**按此条执行**：改动面 2 件（`docs/ROUTES.md`、`build/MilBridge/HANDOFF-NEXT.md`）＋ 1 件新建（本载体，无前像）⇒ 写前逐件 `stat -c %h` ＝ **1** 并 `cp -p` 两件到 `~/w281-scribe/bak/{ROUTES.md,HANDOFF-NEXT.md}.pre-t101`（`cmp` 逐件与写前件相同）⇒ **改动面 ≡ 备份面**。
- 第 `30` 条 ＝ 「**进程内状态敏感仪器**的调用史约束」（`t89`）：条本体**内容锚**＝「dated 纪律追加 · 第 `30` 条（**进程内状态敏感仪器**的调用史约束）」（读时块头 `:611`，仅本次有效）。本件**不引用任何进程内状态读数**（无自检／无探针调用／无 `live` 计数）⇒ 该条对本件**不产生引用义务**；本件引用的判据读数全是**批式件读数**（`pts-pages-guard.sh`／`pts-gap-count-check.sh`／`infp.sh`）。

### ④ 本波（`#81`）产品件换代序列（**落点**：`HANDOFF-NEXT.md` 尾部索引块 ＋ 本载体 §3）

- `.so`：`2a5165700a8c8579`（`t81` 之前在册声明值）→ `3bd193e54785b5db`（`t81`）→ `657f448c2077ba1f`（`t92`）→ **`461e5557bd7dd571`（`t97`，现盘）**。
- `pf`：`b3f0d129f0234b58`（`t86`／`t87` 那代，在册腿证据载它）→ `83ba5884bb603296`（`t90`）→ **`6893d1d3fb1ee110`（`t95`，现盘）**。
- ⚠️ **与线索不符（如实记）**：线索说 `pf` 本波至少三代（`t90`／`t95`／`t97` 各重建过）⇒ 本席现取**只有两代**：`t97` 的 `b7e38ab` **未改** `build/PresentationFramework.Linux/**`（`git show --stat b7e38ab` 全表＝native ＋ 文档 ＋ 报告），且 `PtsCache.Linux.cs` 最后一次变更 ＝ `4d87912`（`t95` 那笔）、现件 sha16 **`6fecbab40f639616`** 与 `t95` 交付值逐位相同、Release 件 mtime **`2026-09-29 00:39:48`**（＝ `t95` 那趟构建）。
- **同趟性**：在册 `leg_{23,24}.env` 的 `DEV` 轴现取 `x_up=yes five_stable=yes shim=461e5557bd7dd571 pf=6893d1d3fb1ee110` ＋ `five_pre_g1.txt` 同值 ⇒ ＝ **现盘两件**（本席逐位对拍）⇒ **在册证据已与最终值同代**。⚠️ 线索那句 `POSTSHIM … == authority` **本席在仓内与 `~/w67-work` 下都搜不到**（跑腿 stdout 归调用方、未落仓）⇒ 本席用 `DEV` 轴 ＋ `five_pre` 对拍**替证**（结论等价，但**不冒充**该行存在）。
- **容量面现值（本席现取）**：`nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | wc -l` ＝ **565** ＝ `src/WpfGfx.Linux.Native/bin/exports.txt` 行数（**565**）；名册 `k_pts_entries[]` ＝ **13** 名。

### ⑤ `TASK-0007` 现状（**落点**：`§13` 里行首锚「`TASK-0007 [MVP]`」那一行的 dated 子行区，追 `t101` 索引一条）

- **仍 `NOINFO(前置未达)`**：判据反转预告那句「**洋红 = 0 ∧ 无具名行 ∧ 真实排版**」**远未满足** —— 本席现取在册 `leg_{23,24}.env` 的 `magenta` ＝ **`49592`**（k=23）／**`54182`**（k=24）⇒ 两页**仍是洋红占位**（判据 `PTS_GUARD=PASS` 要求占位**在位**，那是止损面绿，**不是**排版绿）。
- **但前置已从「完全未动」推进到「台账真非零、前沿具名并已前进一跳」**：`native_gap` **0 → 2**、`entry=` 面具名两站、`PTSGAP_FRONTIER_STATE=NAMED`。
- ⇒ **本件不许把它写成绿、也不许写成「即将绿」**（真因 `TASK-0302` 仍未落地；判据反转文本与 `TASK-0302` 同趟改）。

### ⑥ `TASK-0201`（**落点**：`§13` 里行首锚「`TASK-0201 [MVP]`」那一行块尾，追 `t101` 索引一条）

- **本会话（波 `#81`）无新读数** ⇒ 本席**不引用**其行内任何数字（只写"保持原位 ＋ 记号仍 🟡"）⇒ 从根上避免「用旧数当现数」。本波新读数都在 PTS／`TASK-0302` 那条线上。

## §2 不变量 / 指纹位移 / 已接线牙（现取）

```
不变量：`^run_step "` ＝ 62 ｜ 覆盖面 ＝ 234 ｜ `VERIFYALL-STEPS-DECL: 62 gen=#81` ＝ 1 ｜ `--expect 234` ＝ 1 ⇒ 四条未变
覆盖面成员（本席现算，234 件逐条 grep）：`src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ 1 ｜ `tests/PtsPagesProbe/evidence/` ＝ 16 ｜
  而本件三件 `docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md`／`build/MilBridge/P1-session-stage-report.md` 各 ＝ 0 ⇒ **本件改动面不在覆盖面内**
指纹：`bash ~/w153a/bin/infp.sh fp` 两次现取 —— `122b04afa7f6a1453b9f3f24d549b109666964da713a6c2cdc2dc51360c3e681`（`ts=2026-09-29T01:02:05.988918353+0800`）
      与 `a796005b865597335e92adced8afdc1d865a2354a1360e9cb3ad69d1333e0fbb`（`ts=2026-09-29T01:04:58.800091537+0800`）⇒ **位移发生在这两个时刻之间**，成因经查＝**另一写者改了覆盖面内件**
      `src/WpfGfx.Linux.Native/src/win32_pts.c`（现取 mtime `2026-09-29 01:05:01.023652022`；`git status` 显示该件为 ` M`）—— **非本件改动面**（`src/**` 不在本件写域，本席从未碰它）。
      ⇒ 与 `HANDOFF-NEXT.md` 末条 `cell=#1`（`ts=2026-09-29T00:55:06.276907971+0800`，值 `122b04af…`）**现取已不一致** ⇒ `HANDOFF_MV=DIVERGED reason=cell-mismatch cells=9 equal=7 manual=1 mismatch=1 reasons=,#1:covered-file-changed-since-ts`。
      按派单纪律「**若格值被别人顶掉，如实报你的取值时刻，别反复追写**」⇒ 本席**未追写** `cell=#1`（且本件改动面本就**不在覆盖面内** ⇒ 无"改覆盖面内件必须同趟登记"的义务）。
牙：REPORTID=PASS files=241 ids=2200 declared=224 ｜ DEFREG=PASS declared=224 route_ids=224（**但** `DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN keys=KD` ⇒ 见 §4 未闭项）
    SENTINEL-SPEC：**SSC_VALUE 全 PASS**（含 `key=PF v=6893d1d3fb1ee110`、`key=WIN32SHIM v=461e5557bd7dd571`）⇒ 哨兵与现盘两件相符
    SHELL_QUOTE_TRAP=PASS traps=0 ｜ PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 ｜ STATIC-JAWS 见 §4（本趟读数）
```

## §3 只增不改 / dated 戳 / 内容锚 自证

- **两件改动面各 0 个删行**（机器可算）：`diff <备份> <现值> | grep -c '^<'` ⇒ `docs/ROUTES.md` **0**、`build/MilBridge/HANDOFF-NEXT.md` **0**。⇒ 全是**追加**。
- **`§13` 三条插入点全部用内容锚定位**（本席脚本按内容锚匹配，不按行号）：`dated 更正（补精度）· `t69`` 之后（`TASK-0302` 块尾）／`└─ 真因 = TASK-0302` 之后（`TASK-0007` 块尾）／`dated 口径更正（2026-09-24，主控）` 之后（`TASK-0201` 块尾）；`§15af` 索引落在 **EOF**；`HANDOFF-NEXT.md` 的索引块插在**最后一条 `cell=#1` 行之前**（⇒ 文件仍以 `cell=#1` 行收尾，机器值契约的取行语义不变）。
- **行数位移（仅本次有效）**：`docs/ROUTES.md` 866 → **883** 行（+17）；`HANDOFF-NEXT.md` 630 → **645** 行（+15）。插入点之后的既有行号整体下移 ⇒ 本件内一切行号**仅对写入时刻有效**，(内容锚为准)。
- **`cell=#1` 一行未动**（本席改动面不在覆盖面内 ⇒ 依派单纪律**不追写**）。
- **同趟自查（两处花字/脚本坑，如实记）**：本席第一版落笔脚本把字符串里的 ASCII 引号当成 Python 定界符 ⇒ 语法错；修字器又把列表元素间的定界引号一并改掉 ⇒ 生成块**碎成了重复片段**。**本席当场发现并整件回退（`cp -p` 备份）重做**：第二版改为「中文文本全部写成**纯文本块文件**由脚本原样读入」（不在源码里写含引号的中文字面量）⇒ 现取结构校验：`grep -c 'dated 索引追加 · 纪律' HANDOFF-NEXT.md` ＝ **1**（唯一），`diff` 删行 ＝ **0**，两件块内无 `+ TS +` 之类未求值残留。

## §4 未做项 / `NOINFO` ＋ 边界自证

- **`NOINFO`①（`t97` 的 `rc=134` 因果链）**：**未独立复跑**（本件禁构建／禁跑腿；要复跑就得回到"不补 stub"的 native 形态 ⇒ 越域）⇒ 本载体与 `ROUTES.md` 里该条**逐字标注为引 `t97` 载体**。
- **`NOINFO`②（历史 `exports` 的"实件"读数）**：历史 `.so` 与 `bin/exports.txt` **不在 git 面**（本席现取：`src/WpfGfx.Linux.Native/bin/exports.txt` 现盘 565 行、但 `git show <提交>:<同路径>` 三代表均为 **0 行**）⇒ 历史 `557/561` 只是**在册声明值** `PTSGAP-DECL:`（tracked）；**现取**的 565 有 `nm` ＋ 判据 `LIVE` **双证**。
- **`NOINFO`③（`POSTSHIM == authority` 行本体）**：仓内与 `~/w67-work` 下均搜不到（见 §1④）⇒ 以 `DEV` 轴 ＋ `five_pre` 替证。
- **未闭（他者面，如实点名）**：`DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN keys=KD` ⇒ ① `KNOWN-DEFECTS.md` 侧仍待同趟 `--emit`（`t87` 起就点名、至今未闭）；② 本趟 `docs/ROUTES.md` 的**合法**追加**也会**让「route 文件自 `DECL-GEN` 起有位移」这一格保持为真 ⇒ 该格要闭，须由持有 `defect-registry-declared.tsv`／`--emit` 权限的写者同趟刷新（**本件写域不含它**）。`DEFREG` 本体仍 `PASS`。
- **边界自证**：`git status --porcelain` 里属于**本席**的改动只有 ` M docs/ROUTES.md`、` M build/MilBridge/HANDOFF-NEXT.md`、`?? build/MilBridge/P1-session-stage-report.md`；` M src/WpfGfx.Linux.Native/src/win32_pts.c` 是**他者**（本席零碰）；未 `git add/commit/push`；未构建／未跑腿／未占显示位／未跑整趟门禁；夹具（`/tmp/t101-ev` 证据副本、`/tmp/t101-*.py`、`/tmp/t101-blocks.txt`）**全在仓外**。
- **备份面 ≡ 改动面（第 `29` 条）**：改动面 2 件（+1 新建无前像），备份面 `~/w281-scribe/bak/{ROUTES.md,HANDOFF-NEXT.md}.pre-t101`（写前 `stat -c %h` ＝ 1 ＋ `cp -p`；`cmp` 与写前件逐件相同：`0afdc476c7c3ff22`／`86ff5e04b696dda8`）。


---

**本件自证**：`head -n -1 build/MilBridge/P1-session-stage-report.md | sha256sum | cut -c1-16` ＝ 13ce1e9a60ba04ed（本行系末行；上列各节即被哈希的全文）

## ⏪ `t101` 落盘后补记（同趟；只增不改）

- **本载体自身的计数位移**：`REPORTID` 现取 **`files=242 ids=2201 declared=224`**（§2 那格写的是 `files=241 ids=2200` —— 差 `+1／+1` ＝ **本载体新建**在 `build/MilBridge/*report*.md` 域内的应然增量 ⇒ 该格需按本行读）。
- **`STATIC-JAWS` 现取**：**`STATICJAWS=FAIL fails=1 n=32 excluded=30 noinfo=1 n_total=62`**，**唯一 HIT ＝ `HANDOFF-MV`**（＝ §2 已点名的 `#1:covered-file-changed-since-ts`；本席另跑 `SENTINEL-SPEC` 现取 **全 `SSC_VALUE=PASS`** ⇒ 该牙不再是 HIT）。
- **指纹位移仍在进行（如实记，不追取）**：本席第三次现取 `bash ~/w153a/bin/infp.sh fp` ＝ **`0c67d78c482fb0719d5c49aaf334e8a129a149d545eae9880d19b4e18fea5c6c`**（`ts=2026-09-29T01:06:13.356278931+0800`）⇒ 三次读数（`122b04af…`@01:02:05 → `a796005b…`@01:04:58 → `0c67d78c…`@01:06:13）**逐次在变**，成因都是**他者**在改覆盖面内件 `src/WpfGfx.Linux.Native/src/win32_pts.c`（本席零碰；`git status` 显示该件 ` M` 并新增 `?? src/tests/`）⇒ 现格值与 `HANDOFF-NEXT.md` 末条 `cell=#1`（`ts=00:55:06`，`122b04af…`）不一致是**移动靶**所致，**本席不再追取、也不追写**（派单纪律：被顶掉就如实报取值时刻）。

**本件自证（末行 · `t101` 落盘后）**：`head -n -1 build/MilBridge/P1-session-stage-report.md | sha256sum | cut -c1-16` ＝ b70fdf63a11be60c
