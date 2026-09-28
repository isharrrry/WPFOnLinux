# P1-w3-close-verify —— `t29`（V1／V2／V3）关账的**独立复核**

- **本件** ＝ 独立复核判词载体（`verifier`；任务 `t30`／attempt `1`；沙箱 `~/wv88y/t30/`，`%h==1`、非 `/tmp`）。
- **被复核的写者** ＝ `scribe` 的 `t29`；**那一笔提交** `a9958fb`（`2026-09-28T16:31:22+08:00`，`git show --numstat` 现取 ＝ 三件：`HANDOFF-NEXT.md 10 0`／`P1-w3-close-report.md 79 0`／`tools/wave-push.sh 41 5`）。
- **判据来源** ＝ `build/MilBridge/P1-w3-verify.md`（`t22` 判词，`7515a3c7cb5e3e3c`，**只读未改**）点名的 V1／V2／V3 ＋ 本任务 acceptance 六条。
- **纪律**：全部读数**我现取自算**（成对重跑＝我自己造夹具、自己跑两版件），**未复述** `t29` 的任何结论；**未**引我上一件的输出当证据；`NOINFO` 既不算绿也不算红；**戳带亚秒**。

---

## §0 现取快照（判读基线）

| 项 | 现取 | 读取时刻 |
|---|---|---|
| `HEAD` | 开工 `110ebdf`（`16:35:06`）→ 判读中 `68fb0bf`（`16:35:34`） | `2026-09-28T16:36:37.156991070+08:00` |
| `/tmp/bridge-frozen.flag` | `13` 行／`6cb3f97388c3c4dc`／`279 B`／mtime `2026-09-28 13:48:27.398116209` | `2026-09-28T16:35:11.377682051+08:00` |
| `~/wfp-runs/bridge-frozen.flag` | 同上（`cmp` **IDENTICAL**） | 同上 |
| `build/MilBridge/tools/wave-push.sh` | `121` 行／`9a518e00b3a78163`／`8215 B`／mode `755` | `2026-09-28T16:35:11.377682051+08:00` |
| `build/MilBridge/HANDOFF-NEXT.md` | `369` 行／`3d25341c90eb6dff`／`100829 B` | 同上 |
| `build/MilBridge/P1-w3-close-report.md` | `79` 行／`dd90b22c3fa9c7e0`／`head -n -1` ＝ **`91404599991e8a05`（与文内 `:79` 自报逐位相同）** | `2026-09-28T16:38:01.077610767+08:00` |
| `build/close-wave.sh` | `713` 行／`f9a2ee3ee35baff8`／mtime `10:21:57.131884451` | `2026-09-28T16:37:39.233530491+08:00` |
| `verify-all.sh` | `600274f130cfe913`（未碰） | 同上 |

- **两枚生产哨兵收尾复核**（成对驱动第 `12` 腿）：`13` 行／`6cb3f97388c3c4dc`／`279 B`／mtime **逐字仍是 `2026-09-28 13:48:27.398116209`**（＝我开工基线）⇒ **全部腿只写沙箱路径，生产哨兵零改动**。
- **`porcelain` 逐行归属**（`2026-09-28T16:37:29.824953066+08:00`）：`?? build/MilBridge/P1-task0201-criteria.md`（**`t7` 的**）｜`?? build/MilBridge/P1-v-close2-report.md`（**他人波次新建**）｜` M build/MilBridge/tools/timestamp-order-check.sh`（**他人波次在改**）⇒ **`t29` 名下零脏件、越域为零**（其三件已随 `a9958fb` 提交）。

---

## §1 判据①（V1）—— 错坐标改内容锚：**成立**

- **更正形态 ＝ 内容锚（键名本身）**（`HANDOFF-NEXT.md:364` 现取逐字）：「**「哨兵里 `FP`（**键名锚**，不写行号）＝ `bash build/bridge-src-fp.sh` 的 `BRIDGE_SRC_FP`；`WAVE`／`BASELINE`／`BASELINE_SHA16` 三键同理**按键名锚**；行号只能作『仅本次有效』旁注。」**」⇒ 按**键名**定位，不再挂行号 ✔。
- **被更正原句仍在（一字未删）**：`:346` 现取逐字「`B-13` 口径钉死（防串口径）：哨兵**第 11 行起** `FP` 的语义是 **`BRIDGE_SRC_FP`**…」；`git show a9958fb -- HANDOFF` 的 **`^-[^-]` 计数 ＝ `0`**；`numstat ＝ 10 0` ⇒ 纯追加 ✔。前缀独立复核：`head -c 98008 <现件> | cmp - bak/HANDOFF-NEXT.md.pre-t29` ⇒ **IDENTICAL**（pre-t29 ＝ `fff0ac938d0e5a86`／`98008 B`）⇒ 真·纯追加。
- **坐标事实我自算**：`/tmp/bridge-frozen.flag` 逐行现取 ⇒ 第 `1` 行 `SHA=4e25e4b27d4d5ae1`｜**第 `2` 行 `FP=d697b1e10ff48881`**｜第 `11`–`13` 行 `WAVE=w80-freeze`／`BASELINE=#80`／`BASELINE_SHA16=b96d4312565a3c49` ⇒ 原句的「第 11 行起 `FP`」**确错**，`t29` 的现取行序**逐格正确** ✔。
- **「点错族」如实记，且在册有载体**：`:365` 逐字「这是本仓**「坐标挂错族」的又一次** —— 既有各例（在册）：`t71` 的 `:788`（插入前坐标，记第 `3` 次）／`:221`／`:228`／`:240`（`t16` F1 记第 `4` 次）／`t16` 的六号内容锚问题。」我现取载体：`docs/ROUTES.md:829` 逐字含「**第 1–2 次＝`t71` 那笔的六个行号与 `:788` 事实句（父代坐标，`t72` 判 `medium`）、第 3 次＝`t71` 的 `:788`（同族，已由 `t2` 落 dated 更正）；本条为第 4 次**」⇒ **第 `3` 次／第 `4` 次两处序号都有仓内载体** ✔。

### 1.1 判词①：**成立**（更正形态＝内容锚、原句一字未删、同族诚实且有载体、现取行序我复算正确）。

---

## §2 判据②（V2）—— **成对重跑**（改前件 vs 改后件，同一沙箱、同一场景）：**成立**

**成对口径（披露）**：两版件我放在**同一个影子根** `~/wv88y/t30/pre/`（`R` 由脚本自身位置推得 ⇒ `$W/pre`；权威路径 11 条经**只读符号链接**指回 `$N` 的 `build/`／`src/`／`docs/`）。
- `wave-push-new.sh` ＝ 现盘件的 `cp` 副本：`cmp` **IDENTICAL**（`121` 行／`9a518e00b3a78163`）；
- `wave-push-pre.sh` ＝ `~/w281-scribe/bak/wave-push.sh.pre-t29`：`cmp` **IDENTICAL**（`85` 行／`b1a167146f9dcb35`），并与 `git show 192b573:build/MilBridge/tools/wave-push.sh` **逐字节相同**；
- **两版干跑 13 行 `cmp` ＝ `IDENTICAL`** ⇒ 同环境、同取值 ⇒ **唯一变量 ＝ 写块**（`1..79` 行逐字节相同，只差 `:76` 的 `trap` 那行；`emit()` 一字未改）；
- **影子根偏差（如实披露）**：影子根里 `FP=7b2f5733b3496800` ≠ 真树 `d697b1e10ff48881`（`bridge-src-fp.sh` 在影子根下看到的是影子树）⇒ 该行偏差**只影响取值行、不影响写块**；**真树改后件干跑 13 行与两枚生产哨兵 `cmp` ＝ `IDENTICAL`**（即真值未变）。

### 2.1 十二腿原始读数（stdout／stderr **分流**记录；`rc` 逐腿现取）

| 腿 | 件 | 场景 | `rc` | 关键原始行 | 落点状态 |
|---|---|---|---|---|---|
| 1 | 改后（真树） | 正常态 | **0** | `WPW=PASS sentinels=2 cmp=IDENTICAL lines=13 keys=13 … sha16=6cb3f97388c3c4dc` | A/B 均写；**三方 `cmp`（沙箱 A vs 生产哨兵）IDENTICAL** |
| 2 | 改前（影子） | 正常态 | **0** | 同上（`sha16` 段无） | A/B 均写（`ecf4f8c5fd6594fc`） |
| 3 | 改后 | **A 父目录只读 `chmod 500`** | **1** | `WPW=FAIL reason=target-dir-unwritable step=preflight dir=…/l3/a cmd="test -w …/l3/a"`（**stdout**） | **A `ABSENT`、B `ABSENT`** ⇒ 不留半成品 |
| 4 | **改前** | **同场景** | **1** | stderr：`install: 无法创建普通文件 '…/l4/a/f.flag': 权限不够` ＋ `WPW=FAIL reason=sentinels-differ a=… b=…`（**reason 不点真因**） | **A `ABSENT`、B `ecf4f8c5fd6594fc`** ⇒ **部分写** |
| 5 | 改后 | A 父目录**缺失**（深路径） | **0** | `WPW=PASS …`（先 `mkdir -p` 再写） | A/B 均写 ⇒ 见 `V-2`（低） |
| 6 | **改前** | **同场景** | **1** | stderr：`install: … 没有那个文件或目录` ＋ `WPW=FAIL reason=sentinels-differ …` | **A `ABSENT`、B 已写** ⇒ **部分写** |
| 7 | 改后 | **B 目标是目录** | **1** | `WPW=FAIL reason=target-not-a-regular-file step=preflight path=…/l7/b/dirB（"install" 对目录会静默拷进去 ⇒ 必须先拒）`（stdout，**stderr 零行**） | A/B 未写；`dirB` 内 **`0` 个条目** |
| 8 | **改前** | **同场景** | **1** | stderr：`cmp: …/l8/b/dirB: 是一个目录` ＋ `WPW=FAIL reason=sentinels-differ …` | **A 已写**、`dirB` 内**多出 `1` 个垃圾件 `tmp.krbj6cIULs`**（`install` 把临时件静默拷进目录）⇒ **部分写 ＋ 残留** |
| 9 | 改后 | B 的父路径是**普通件** | **1** | `WPW=FAIL reason=target-dir-unusable step=preflight dir=…/l9/b/notadir cmd="mkdir -p …" stderr=mkdir: … 文件已存在` | A/B 未写 |
| 10 | 改后 | **注入 `WPW_TEST_FORCE_FAIL=write-B`** | **1** | ① `WPW=FAIL reason=install-failed step=write-B sentinel=B path=… cmd="install -m 644 <tmp> …" stderr=forced-by-test-hook`｜② `WPW_ROLLBACK why=write-B A=… pre=c9604c198072c885 now=c9604c198072c885 | B=… pre=edadddd8cd75b03f now=edadddd8cd75b03f`｜③ `WPW=FAIL partial=none（A 已回滚到 pre）` | **两枚内容回到 `PRE-A`／`PRE-B`**（`sha16` 逐枚相同） |
| 11 | 改后 | B 父目录只读 | **1** | `WPW=FAIL reason=target-dir-unwritable step=preflight dir=…/l11/b cmd="test -w …"` | A/B 未写 |
| 12 | — | 生产哨兵复核 | — | 两枚 `13` 行／`6cb3f97388c3c4dc`／mtime 未变、`cmp IDENTICAL` | 零改动 |

### 2.2 acceptance 逐格对答

- **① 改后件必红且 `reason` 点名真因（哪一枚／哪一步）＝ 成立**：腿 3／11（`step=preflight dir=…`，点名到**具体那一枚的父目录**）、腿 9（`target-dir-unusable` ＋ `cmd` ＋ `mkdir` 的 `stderr` 首行）、腿 10（`step=write-B sentinel=B path=… cmd="install -m 644 <tmp> <path>"`）。
- **② 正常态 ⇒ `WPW=PASS sentinels=2 cmp=IDENTICAL` ＝ 成立**（腿 1；`sha16=6cb3f97388c3c4dc` 与生产哨兵逐字节相同）。
- **③ 不再出现部分写 ＝ 成立**：改后件**五条失败腿**（3／7／9／10／11）全部 **A、B 皆未被写**（`ABSENT`，或注入腿回滚到 `pre`）⇒ 无半成品、无残留（腿 7 的 `dirB` 条目数 `0`）。
- **④ 失败 `reason` 在机读行里可见真因（不只在 stderr）＝ 成立**：全部失败腿的真因**在 stdout 的 `WPW=FAIL reason=…` 行里**（腿 3／7／9／10／11 的 stderr **零行**）；对照改前件：真因只在 `install` 自己的 stderr，机读行给的是**误导性的** `reason=sentinels-differ`。
- **⑤ 成对（改前件「部分写 ＋ reason 不点真因」）＝ 成立**：腿 4／6／8 三条同场景成对读数在册；最强的一格是 **腿 8**：改前件**既部分写、又把临时件静默拷进了目标目录**（`tmp.krbj6cIULs`），机读行只说 `sentinels-differ`。
- **未改口径的证据**：真树干跑 13 行 `cmp` 生产哨兵 **IDENTICAL**（腿 1 三方 `cmp`）⇒ 加固**没动取值** ✔（与写者主张一致，但我用生产哨兵独立对拍）。

### 2.3 判词②：**成立**（十二腿、成对同场景、raw 行在册；改后件必红＋点名真因＋不留半成品，改前件部分写＋reason 不点真因）。

---

## §3 判据③（V3）——「零位移必须带时刻」口径句：**成立（附 `V-1` low）**

- **口径句在位（第 `20` 条）**：`HANDOFF-NEXT.md:367` 现取逐字含形态 **「`ts=<亚秒戳> 时 入口=X 出口=X，覆盖面=N`」**；四要素现取命中：`ts=` `2`／`入口=X` `1`／`出口=X` `1`／`覆盖面=N` `1`；并含「只写『零位移』而不带**读时戳 ＋ 两值 ＋ 覆盖面件数**的 ⇒ **不可对拍**」＋「**任何第三方改动覆盖面内任一件，都会推翻该读数**」⇒ **可判真假** ✔（形态给了、判据给了、推翻条件给了）。
- **编号现取**：本区（`## §下一波未闭项`）**真实编号项最大仍是 `18`**（`awk` 现取）——`第 19`／`第 20` 条都是**块内的链式声称**（`t27` 的块 → `t29` 的块）；全件 `^19.`／`^20.` 各 `1` 处，**均在 `§5` 那份 1–47 清单里**（他区）⇒ 本区**不冲突**（同族观察见 §6-`NOINFO`③）。
- **没有把旧读数写成现值 ＝ 成立**：`e9f95ec0…` 在 `t29` 两件里只出现 **2** 处，两处都写明是 **`t24` 报的、已被推翻**（`P1-w3-close-report.md:46-:47`、`HANDOFF:367`），并给出**现取** `8c4ce894…`；无一处把 `226/226` 或旧值当现值 ✔。
- **我把两个历史值都机械复现了（决定性归因，读时 `2026-09-28T16:37:29.824953066+08:00`）**：用 `infp.sh attrib` 把现盘清单里那一件的 `sha` 换回旧值后重算指纹 ——
  - 换回 **pre-t25** 值（`60009734108344bd6c42be2e93333993d6ee231cda9c806589ad7ae556ef9fc6`）⇒ **`e9f95ec005715b3a…`** ＝ **`t24` 报的那个值** ⇒ 第 `20` 条举的「已被推翻」例子**逐位为真**；
  - 换回 **pre-t31** 值（`231ae30326a4fb31…`，两路取：`git show 110ebdf:…` 与 `bak/pkg-src-retiredpath-check.sh.pre-t31`，`cmp` **IDENTICAL**）⇒ **`8c4ce894d04eae7b1c6d253bc5beabb758a9e99f8430b7b1cd17c8d8707bedd3`** ＝ **`t29` 报的入口/出口值** ⇒ `t29` 的读数在其时刻**为真**且**可复算**。
  - 该件 `in-list=1`（现取清单里在位）⇒ 它是**唯一动因**：现取 `inputs_fp` ＝ **`c87cb187f45082e83d3b217d235d50b24f1183f28d37308f1a175de25210403d`**（两次现取一致），动因件 `build/MilBridge/tools/pkg-src-retiredpath-check.sh` mtime **`2026-09-28 16:32:51.925195455`**（他人波次改）⇒ `8c4ce894…` **已被第三方推翻**（正是第 `20` 条警告的那件事，发生在其落册后 **2 分 45 秒**）。

### 3.1 `V-1` 点名（low）—— `C6` 证据行**没有内联 `ts`**，与它自己刚落的口径形态不一致

- **现象**：`P1-w3-close-report.md:51`（入口）写「（本波开工现取，`ts=` 起读时刻见 §0／§1）」——`ts` **转引**；`:52`（出口）写「（本波落定后现取）」——**完全无 `ts`**。⇒ 按第 `20` 条自己的判据（「不带读时戳 ＋ 两值 ＋ 覆盖面件数 ⇒ 不可对拍」），这两行**两值＋覆盖面齐、读时戳不齐**，**无法从该行自身确定「那一刻」是哪一刻**。
- **活证（同一波之后 `2 分 45 秒`）**：`16:32:51.925195455` 他人波次改了覆盖面内的 `pkg-src-retiredpath-check.sh`（`in-list=1`）⇒ 现取指纹 `c87cb187…` ≠ 报告所写 `8c4ce894…`。第三方要复核「出口＝`8c4ce894…`」只能靠**猜时间窗**（我用 `attrib` 反证才定死）。
- **要求修法**：C6 两行内联 `ts`（`ts=2026-09-28T16:29:46.306+0800 时 入口=X 出口=X，覆盖面=226`），或至少出口行写 `ts=<落定后现取的亚秒戳>`；**只增不改**、落 dated 追加。
- **边界**：**句子在册、形态可判、两值当时为真**（我已机械复现）⇒ `V-1` 只打「写者自己的证据行不自足」这一格，**不推翻 V3 关账**。

### 3.2 判词③：**成立**（＋`V-1` low）。

---

## §4 判据④（覆盖面 / 零位移）—— **成立（＋`V-1`）**

- **`wave-push.sh` 在覆盖面外**：`bash ~/w153a/bin/infp.sh list | grep wave-push.sh` ⇒ **`0` 行**；覆盖面件数 **`226`**（现取 `list | wc -l`，路径抽取修好后逐条存在性 `226/226`）⇒ 改它**不动 `inputs_fp`** 的机制为真（对照：`pkg-src-retiredpath-check.sh` 是 `in-list=1`，一改就动 ⇒ 见 §3）。
- **写者「印了两值并声明未动」＝ 成立**：`P1-w3-close-report.md:51-:53` 现取印了**入口**与**出口**两值（两值逐字相同 `8c4ce894d04eae7b1c6d253bc5beabb758a9e99f8430b7b1cd17c8d8707bedd3`）＋覆盖面 `226` ＋ 声明「`wave-push.sh` 现取 `in-list=0`／`HANDOFF-NEXT.md` 亦 `0` ⇒ 本波未动 `inputs_fp`」＋「**这不等于「谁都没动」**」⇒ 不是空口声明。
- **但「带时刻」这一格不齐** ⇒ 见 `V-1`（low）。我另**独立取一次**：开工 `16:35` 与判读 `16:37` 现取均为 `c87cb187…`／`226`（他波位移已发生，与本波无关）。

### 4.1 判词④：**成立**（两值＋覆盖面＋声明在位；`ts` 缺 `V-1`）。

---

## §5 判据⑤／⑥ —— 两牙、越域、`close-wave.sh`、载体、未 `add`

- **两牙现取**（`2026-09-28T16:37:39.233530491+08:00`）：`DEFREG=PASS declared=218 route_ids=218` ∧ `DEFREG_DECLDRIFT_KEYS=-`（`rc=0`）｜`REPORTID=PASS files=201 ids=2074 declared=218`（`rc=0`）。
  - 与 `t29` 当时（`declared=217`／`files=199 ids=2061`）的差 **100% 归因他波**：`declared +1` ＝ `t31` 新号（其提交 `68fb0bf`），`files +2/ids +13` ＝ `t31` 的 `P1-w2-close2-report.md` ＋ 我的 `P1-v-close-verify.md`／`P1-v-close2-report.md` 一族；**本件不匹配 `build/MilBridge/*report*.md`**（`*-verify.md` 形态），故本件**不进 REPORTID 覆盖面**。
- **越域**：`a9958fb` `--numstat` 恰三件、`^-[^-]` 计数在 `HANDOFF` 上 ＝ `0`（`wave-push.sh` 的 `5` 行删除是**写块整块替换**，已在写者报告里点名）；三次 `porcelain` 逐行归属（§0）⇒ **`t29` 零越域**。
- **未碰（现取 `sha16` ＋ `porcelain` 各 `0` 行）**：`build/close-wave.sh` `f9a2ee3ee35baff8`｜`verify-all.sh` `600274f130cfe913`｜`P1-w3-verify.md`（**我的 `t22` 载体**）`7515a3c7cb5e3e3c`｜`tools/sentinel-spec-check.sh` `8c8470a3b3dd0c0d`。
- **载体现取**：`build/MilBridge/P1-w3-close-report.md` `79` 行／全文 `dd90b22c3fa9c7e0`／自报口径 `head -n -1` ＝ `91404599991e8a05`（**我复算逐位相同** ⇒ 自洽）；文内 `⑧` 段对 §1 的**自伤更正链**（`:72`–`:78`）我已核：更正后的真值「`fff0ac938d0e5a86` → `3d25341c90eb6dff`／`359 → 369` 行／`numstat 10 0`／前缀 `IDENTICAL`」**与我现取逐格一致** ⇒ 自伤**如实记且已修正到位** ✔
  - **`V-3` 点名（low）**：同一段 `:77` 的**形态自查三格数不对** —— 它写「`^[^⏪]` ＝ `1`（空行）＋ 块头 `### ⏪` ＋ `8` 条 `- ⏪` 行」；我逐行现取（含首字节）：**新增 `10` 行 ＝ 空行 `2` ＋ `### ` 块头 `1` ＋ `- ⏪` 行 `7`**，`^[^⏪]` ＝ **`8`**（`⏪` 在首字节位置者 `0`）。合计仍 `10` ⇒ **加法巧合掩盖**（`D-G125` 同族：件与表都对、**错的只是消息**）。实质主张（`10` 行全在、`^-[^-]`＝0、前缀 `IDENTICAL`、全块带 `⏪` 标记形态）成立。**要求修法**：dated 追加一行给出逐格读数（空行/块头/`- ⏪`/`^[^⏪]` 各一值）。
- **未** `git add`／`commit`／`push`（我全程只读 `$N`，唯一写 ＝ 本件）。

### 5.1 判词⑤／⑥：**成立**（＋`V-3` low）。

---

## §6 `V-2` 点名（low，登记 W4 风险）—— 改后件把「父目录缺失」变成**自动建目录**

- **读数**（腿 5，改后件、影子根、`rc=0`）：`WPW=PASS sentinels=2 cmp=IDENTICAL lines=13 keys=13 a=…/l5/a/deep/f.flag b=…/l5/b/f.flag` —— 深路径的父目录是工具**自己 `mkdir -p` 建出来的**，随后写入成功。对照腿 6（改前件同场景）⇒ `install: … 没有那个文件或目录` ＋ **部分写**。
- **我不判为错**：`t22` §V2 的修法建议**正是**「先对 `$S_A` 也 `mkdir -p`」⇒ 写者按建议执行、且方向是「堵死隐式部分写」。
- **但登记为 W4 首跑前的风险（低⇒接线时升 medium）**：目录闸对「**路径写错**」与「**目录真缺**」不做区分 ⇒ 若 `WPW_S1` 打错一处（例如少了 `/build/`），工具会**静默建出整条陌生目录树**并把哨兵写进去，同时**生产两枚仍旧**（读数看起来还能 `PASS`）。`close-wave.sh` 接线后这个通道会变成「假绿」的同族（`D-G181`／`D-G182` 家族）。
- **要求修法（择一，须两极化）**：① 只对**两条规范路径**（`/tmp/bridge-frozen.flag`、`$HOME/wfp-runs/bridge-frozen.flag`）或显式 `WPW_MKDIR_OK=1` 时才自动建，否则 `WPW=FAIL reason=target-dir-absent-not-sanctioned step=preflight dir=…`；② 或把「自动建了什么目录」打进 `WPW=PASS` 行（`mkdir=…` 逐条上屏），让「建了陌生目录」在读数里可见。

---

## §7 `NOINFO`（具名，既不算绿也不算红）

1. **`NOINFO(reason=时间性不可回溯源)`**：`t29` 当时的 `porcelain` 清单只在其报告里；越域我另用**提交级** `--numstat`（三件）＋ 当前 `porcelain` 归属判。
2. **`NOINFO(reason=生产写路未做真写)`**：本波与我的复核**都只写沙箱路径** ⇒ 「生产写路首跑」仍留 **W4**（我另加一条：两枚生产哨兵 mtime／`sha16` 全程未变，这正是「没做真写」的证据）。
3. **`NOINFO(reason=自然失败下的回滚未复现)`**：腿 10 的失败是**测试钩子注入**的 ⇒ 只证代码路径，未证自然失败；写者已在报告 `:65-④` 具名，**我确认该具名成立且诚实**。
4. **`NOINFO(reason=牙未接线)`**：`wave-push.sh`／`sentinel-spec-check.sh`／`timestamp-order-check.sh` 的**门禁效果**不可判（接线归 W4）。
5. **`NOINFO(reason=本波未跑门禁/构建/整波/应用/显示位)`**：按纪律未跑 ⇒ 该面无读数。
6. **`NOINFO(reason=他波在飞件)`**：`?? P1-task0201-criteria.md`（`t7`）｜`?? P1-v-close2-report.md`｜` M tools/timestamp-order-check.sh`（**他人波次正在改**）⇒ 均不计入本判词。
7. **`NOINFO(reason=跨区同号无机器判据)`**：`§5` 清单里的 `^19.`／`^20.` 与本区「第 19／20 条」同号不同列表——「编号只在区内唯一」这条**只有成文、无牙**。

---

## §8 我自己的自伤（如实记，三条；读数无误但过程有坑）

1. **路径抽取器第一版是假红**：`awk '{ $1=""; sub(/^  /,"") }'` 只剥掉一个空格 ⇒ 抽出的 226 条路径**全部带前导空格** ⇒ 存在性判据报 **`226` 条 MISSING**（若照此落笔会写成「覆盖面件全缺」的响亮失败）。改用 `sed 's/^[0-9a-f]\{64\}  //'` 后 ⇒ **缺失 `0`**。**教训**：`infp.sh list` 的分隔是**两个空格**，抽取后必须断言件数＋存在性两侧非空。
2. **「pre-t31」我第一版取自 `git show HEAD:` ⇒ HEAD 已含 `t31`** ⇒ `SUBST old=3bd03726089bf949 new=3bd03726089bf949`（**空转**，指纹原样 `c87cb187…`）。改用父提交 `110ebdf` ＋ `bak/*.pre-t31`（两路 `cmp IDENTICAL`）后归因才成立。**同族**：`D-G181`（在「已经变了的那一版」上取基线＝恒真/恒空）。
3. **`^[^⏪]` 的本机语义与我的预测不符**：我预期 `10`（全部行首非 `⏪`），实得 `8` ⇒ 放弃字符类、改用**逐行首字节**核（`od -An -tx1`），才得到 §5 的三格读数。

---

## §9 判词表

| # | 判据 | 判词 | 关键读数 |
|---|---|---|---|
| ① | V1 错坐标 ⇒ 内容锚 ＋ 原句仍在 ＋ 点错族 | **成立** | `:364` 内容锚；`^-[^-]`＝`0`；前缀 `cmp IDENTICAL`；`ROUTES:829` 载体 |
| ② | V2 成对重跑（必红点名真因／正常 `PASS`／不留半成品／真因在机读行／改前件部分写） | **成立** | 十二腿；改后 `rc=1` 五腿 A/B 均未写；改前 腿 4／6／8 部分写（腿 8 还留垃圾件） |
| ③ | V3 口径句在位 ＋ 可判真假 ＋ 未把旧读数当现值 | **成立（＋`V-1`）** | 四要素齐；`e9f95ec0…` 只作「已推翻」例，两历史值我 `attrib` 机械复现 |
| ④ | 覆盖面：`in-list=0` ＋ 印两值并声明未动 | **成立（＋`V-1`）** | `wave-push.sh` `in-list=0`；两值＋`226`＋声明在位；`ts` 缺 |
| ⑤ | 两牙不退化／越域零／`close-wave.sh` 未碰／未 `add` | **成立** | `DEFREG 218/218`／`REPORTID 201/2074`；`a9958fb` 三件；`f9a2ee3ee35baff8` 未碰 |
| ⑥ | 载体就位 ＋ 自报 `sha16`＋亚秒读时 | **成立** | `dd90b22c3fa9c7e0`／`head -n -1`＝`91404599991e8a05` 复算命中 |
| 追加 | `V-2`（low）自动建目录无闸 ／ `V-3`（low）形态自查三格数错 | **点名** | 腿 5 `rc=0` 自动建树；`10` 行 ＝ `2` 空 ＋ `1` 块头 ＋ `7` 条 `- ⏪` |

- **推翻 `t29` 的话**：**没有推翻**（三处关账的实质主张我逐条独立复现成立；其 `§1` 自伤已自纠且我更正数逐格对上）。**新点名三处**：`V-1`（low，C6 行缺内联 `ts`）／`V-2`（low，`mkdir -p` 无闸，接线升 medium）／`V-3`（low，形态自查三格数错）。
- **本件自报**：全文 `sha16` 与 `head -n -1` 值在**交件消息里现取**（末行只携带机读结论，不自带自指值 ⇒ 无自指矛盾）。

P1-W3-CLOSE-VERIFY: t30 attempt 1 | 判词①-⑥ 成立（③④ 附 V-1）| 新点名 V-1(low 缺内联ts)/V-2(low mkdir无闸)/V-3(low 形态自查数)/推翻 none | wave-push.sh 9a518e00b3a78163 vs pre-t29 b1a167146f9dcb35 成对十二腿 | HANDOFF 3d25341c90eb6dff 前缀纯追加 | 生产哨兵 6cb3f97388c3c4dc mtime 13:48:27.398116209 未变 | inputs_fp 现取 c87cb187f45082e8（8c4ce894 已被他波推翻，attrib 反证 100% 归因 pkg-src-retiredpath-check.sh）| close-wave.sh f9a2ee3ee35baff8 未碰 | DEFREG 218/218 | REPORTID 201/2074 | HEAD 68fb0bf
