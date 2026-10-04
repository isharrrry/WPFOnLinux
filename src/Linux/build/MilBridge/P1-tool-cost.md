# P1 工具耗时刻账（队长口径；数据源＝dsh 会话持久日志）

> **读取时刻**：2026-09-29T19:47–19:52（队长现取）。
> **数据源**：`~/.dsh/sessions/--home-links-dev-netTest-GitProj-WPFOnLinux--/<session>/session.jsonl.zstd`（`zstd -dc` 后逐行解析）。
> **口径实现**：照 dsh 官方 `@deepseek-ai/dsh-session-stats` 折叠规则（`tool/call` → `tool/result` 按 `callId` 配对、`Math.max(0, t_result − t_call)`），**本席自实现**，与 GUI 统计条同源。
> **目的**：把"工具调用为什么吃掉这么多时间"从印象变成读数，并给出**参数级**改法。

## 1 三个口径必须分开（混用就会得出错误的优化目标）

| 口径 | 定义 | 本团队现值（本席自算） |
|---|---|---|
| **工具耗时 `toolMs`** | 配对 `tool/call → tool/result` 的墙钟之和 | 见 §2，**含人工等待与并发重叠** |
| **合并占用** | 同会话内把重叠的工具区间取并集 | captain 97.9 min／runner-A 375.6 min／runner-B 114.6 min |
| **模型时间 `llmMs`** | `step/start → assistant/message` 之和 | captain **8708 s＝2.42 h**（1050 步） |

- **`ask_user_question` 是"等人类"，不是"工具慢"**：本会话 2 次共 **1543.6 s**（单次最长 1529.7 s，其实是本席在等用户回话）。**排除它**，captain 的工具耗时是 `5874 − 1544 = 4330 s ≈ 1.20 h`。**用户 GUI 看到的 1h37m 量级就是这一格**。
- 因此所有"改善"都必须**先扣除人工等待**，否则会把待人的时间算到工具头上。

## 2 captain 会话（`session-703f0164`，跨 29.8 h）逐工具

| 工具 | 耗时 | 次数 | 均 | 单次最大 |
|---|---|---|---|---|
| `bash` | **3181 s** | 500 | 6.36 s | 209.1 s |
| `ask_user_question` | 1544 s（人类） | 2 | 771.8 s | 1529.7 s |
| `agent_teams_create_task` | 742 s | 192 | 3.87 s | 36.1 s |
| `agent_teams_send_message` | 114 s | 72 | 1.58 s | 10.6 s |
| `agent_teams_status` | 108 s | 21 | 5.13 s | 27.5 s |
| `agent_teams_reassign_task` | 76 s | 23 | 3.31 s | 18.3 s |
| `agent_teams_edit_plan` | 68 s | 31 | 2.18 s | 23.3 s |
| 其余 13 个工具合计 | <40 s | — | — | — |

`bash` 内部再分（按命令首特征分类，同一条命令只归一类）：

| 分类 | 耗时 | 次数 | 均 |
|---|---|---|---|
| git 提交/校验 | 1107 s | 196 | 5.65 s |
| guard/check 脚本 | 840 s | 82 | 10.25 s |
| `wave-push.sh` 哨兵 | 517 s | 31 | 16.67 s |
| `sleep` 主动等待 | 367 s | 9 | 40.79 s |
| 其他 | 275 s | 127 | 2.16 s |
| 腿/probe | 68 s | 19 | 3.58 s |
| 编译 | 3 s | 20 | 0.15 s |

## 3 真正的三处大头（按"可省多少"排序）

### 3.1 `job_output` 阻塞等待 —— 最大单点，且**几乎全可省**
- 记录里 `job_output` 的调用 **106/108 次带 `wait: true`**，`timeout_ms` 常见 `600000`／`900000`（即最长阻塞 10–15 min）。
- 实测代价：runner-A 该工具 **108 次 = 297.2 min（4.95 h）**；runner-B 51 次 = 29.1 min。两队合计 **≈5.4 h**，是其会话里最大单项。
- 机理：`wait: true` 是**同步阻塞**——后台任务没结束就干等。**同样的等待可以做别的步**。
- **改法（参数级）**：
  1. 默认用 `job_output` **不带 `wait`**（非阻塞），拿到 `[status: running]` 就先去干别的；仅在"下一动作确实依赖该结果"时才 `wait: true`，且 `timeout_ms` 不超 `120000`。
  2. 派重活时**一次派多件**（独立活可并行），把等待摊平。
  3. 已知完成通知会主动回来（本会话已多次收到 `finished` 通知）⇒ **不需要靠阻塞去"盯着"**。

### 3.2 `static-jaws-check.sh` 重复跑 —— 682 s 里的大头
- **本席实测**：单次 **65.9 s／rc=1**（`STATICJAWS=FAIL`，2026-09-29T19:47 现取）。
- **`t187` 实测（只读逐牙，中位口径见该件 §1）**：一趟 **80.612 s**（`rc=1`、`n=32 excluded=30 noinfo=1`）、`Σ牙=76.321 s`；**31/31 牙都有 `ms`**。最慢 5：

| 牙 | 耗时 | 与 `SJC_TIMEOUT=40 s` 的余量 |
|---|---|---|
| `PRODUCT-ENTRY` | **28.216 s** | 仅 **11.8 s**（**并行化的真正下界**） |
| `WIRING-CLOSURE` | 8.573 s | — |
| `HANDOFF-MV` | 5.711 s（`rc=1` ⇒ 本趟 `fails=1`） | — |
| `DEFECT-REGISTRY` | 5.590 s | — |
| `REPORT-ID-DOMAIN` | 5.175 s | — |

- **两个额外发现**：① `HANDOFF-MV`／`DEFECT-REGISTRY`／`REPORT-ID-DOMAIN` **在同一趟门禁里被算两次**（牙内 ＋ 独立调用）⇒ **零新机制就能省 11.3 s/趟**；② **框架成本只占 5.3%**（`bash` 启动中位 **3 ms**）⇒ "减启动开销"这条路没有收益，全部成本是真扫描。
- captain 会话里被调 **14 次共 581.8 s**；runner-A 3 次 160 s；runner-B 38 次 199 s。合计 **≈15.7 min**。
- **改法**（`t187` 给了依据式下界）：① 只在**步表或牙集合变化**后跑（它是整表体检，不该每笔都跑）；② 若要常跑，加"输入指纹未变 ⇒ 复用上次判词"的缓存；③ 逐牙并行（牙间无共享状态）：4 路下界 `T ≥ max(Σ牙/4, 最慢单牙) + 框架 = max(19.08, 28.216) + 4.29 ≈ **32.5 s**` ⇒ **省 ≈48 s/趟**——**注意下界被 `PRODUCT-ENTRY` 单牙卡死**，再并行也无用，除非先拆那一牙。

### 3.3 单次 1–6 s 的 guard/check 脚本 × 上千次
- 本席实测基准（2026-09-29T19:50，`timeout -k 5 300`，`bash <path>`）：

| 牙 | 实测 | 记录里出现次数（跨 4 会话，现取） |
|---|---|---|
| `sentinel-spec-check.sh` | **298 ms** | 60 |
| `shell-quote-trap-check.sh` | **1028 ms** | — |
| `pipefail-sigpipe-check.sh` | **3283 ms** | — |
| `handoff-machine-values-check.sh` | **6406 ms**（`rc=1`） | 152 |
| `pts-gap-count-check.sh` | **1358 ms** | 136 |
| `timestamp-order-check.sh` | **857 ms** | 29 |
| `pkg-src-retiredpath-check.sh` | **10 ms**（`rc=4`） | 84 |
| `defect-registry-check.sh` | 5.0 s（更早一次现取） | 287 |
| `pts-pages-guard.sh --g10-name …` | 20 ms | 297 |
| `report-id-domain-check.sh`（无参） | **5083 ms** | 192 |
| `pts-pages-guard.sh`（无参＝`--selftest`） | **11871 ms**（首次冷启另 +3455） | 297 |
| `wave-push.sh --write` | 待测 | 48（其中 `--write` 25） |

- **`t187` 真实形态基准（10 形态×3 次取中位，件 `P1-tool-cost-profile.md` §2）**：`defect-registry`(无参) **4884 ms**｜`handoff-mv` **5558 ms**｜`report-id-domain`(无参) **5088 ms**｜`pkg-src --tree` **5200 ms**｜`pts-pages-guard --legs` **741 ms**｜`pts-gap-count` **1062 ms**｜`timestamp-order` **652 ms**｜`sentinel-spec` **257 ms**｜`defect-registry --emit` **281 ms**｜`wave-push`(无参) **169 ms**。
- **可缓存性**：同参连跑 3 次结果，**7 个 `SAME`（可缓存）／`--emit` 与 `pts-gap` 为 `DIFF`**（后两者输出含时间性或随行的量，不能只按输入指纹判"无变化"）。
- **量化**：逐脚本「单次成本 × 出现频次」上界 **≈4068 s**；若每笔重复调用有 `m` 重，可省 `(m−1)/m × 上界`（`m=2` ⇒ **≈2034 s ≈34 min**）。**记账口径下界**：提交前若逐条串行单独跑，一轮 ≈4 min。
- **改法**：① **多牙合并成一条命令**（同时消掉"同件算两次"，省 11.3 s/趟）；② **`SAME` 类形态按输入指纹复用上次判词**；③ `--emit`／`pts-gap` **不可缓存**，每次都要真跑。
- ⚠️ **两处"被拒参数冒充基准"已登记**：本席曾用 `--check` 测 `pts-pages-guard`／`report-id-domain` 得 `0.014 s`／`0.006 s`；`t187` 首版亦把 `report-id-domain <单件>`／`pkg-src`(无参) 测成 `6 ms`。**两者都是 usage 拒绝（`rc=4`），真值差 3 个量级**（`5088／5200 ms`）。**被拒参数一律不得计入基准**，其合法形态由 `t188` 固定。
- **`t188` 追加（合法形态表＋可缓存性判定，件 `P1-tool-cost-profile.md` 追加节，自证 `cdbae08ceefb7bac`）**：
  - **合法形态（现取行号）**：`pts-pages-guard.sh:1340-1346` ⇒ `--legs <dir>`／`--g10-name <dir>`／`--c4-ledger <dir>`／`--selftest`，**且无参合法**（`${1:---selftest}`，实测 `PTS_GUARD_SELFTEST=PASS pass=82 fail=0`）；其它（含 `--check`）⇒ **usage `rc=2`**。`report-id-domain-check.sh:51-59` ⇒ `RC_PASS=0/FAIL=1/NOINFO=3/USAGE=4`，无参默认合法（glob `build/MilBridge/*report*.md`）＋`--root/--decl/--corpus-glob/--selftest`；其它 ⇒ **usage `rc=4`**。
  - **实测中位（形态＋参数值成对）**：`pts-pages-guard --legs …/PtsPagesProbe` **31 ms**(`rc=2`)｜`--g10-name …/PtsPagesProbe` **22 ms**(`rc=0`)｜`--c4-ledger …` **12 ms**(`rc=3`)｜`--selftest` **11871 ms**(`rc=0`)；`report-id` 无参 **5083**／`--root .` **5181**／`--corpus-glob` **5128**／`--selftest` **222**（全 `rc=0`）。**8 形态三次输出全 `SAME`**。
  - 🔴 **最重要的新结论：基准必须「形态 ＋ 参数值」成对固定** —— 同为 `--legs`，指向 `…/PtsPagesProbe` 是 **31 ms**、指向 `…/evidence/arm_A` 是 **741 ms**（`t187`），**同形态不同目录值差 24×**。**只固定形态不固定目录值，基准不可比。**
  - **腿类形态的判据**：`report-id` 类＝**件动必跑**；`pts-pages-guard` 腿类＝**有条件跑**（跑腿后必跑，只改文档可跳过）；`--selftest` 类＝**可跳过**。
  - ⚠️ **两值并列、不泛化**：本席那次 `>60 s` 被 `SIGTERM` 的是 **`defect-registry-check.sh --selftest`**（**另一条牙**）；本件这两条牙的 `--selftest` 实测 **11.871 s／0.222 s，均未超 60 s**。
- ⚠️ **本席派单错误（已认账）**：`t187` 契约里的 `Verify` 命令 `bash build/MilBridge/tools/report-id-domain-check.sh <件>` **本身就是 usage 拒绝形态**（`REPORTID=FAIL reason=usage:unknown-arg`）；runner 自行改用真形态（无参，自行 glob）自验。**队长给的 verify 命令必须自己先跑一遍**，否则会把"命令错"记成"件错"。

## 4 软性成本（不改口径，只改用法）

| 项 | 现值 | 改法 |
|---|---|---|
| 队长 `agent_teams_status` | 21 次／108 s，**平均返回 78–106 KB** | 需要精确状态时直接查目标任务；**不要为了"看看"反复全量拉** |
| 派单正文 | 192 次 `create_task`／742 s；正文累计数百 KB | 通用纪律已抽到 `build/MilBridge/P1-TASK-TEMPLATE.md`（14 条），派单**只写"本件差异"** |
| 派单重复下发 | 本会话为同一目的发过 `t174→t175→t177` 三次（dsh 重启丢单所致） | **重发前先问成员"你有没有这件"**，确认没有再补；不要盲目重复下发 |
| `sleep` 轮询 | 队长 9 次／367 s；runner-A 29 次／1203 s | **禁止用 `sleep` 等后台**；用通知/非阻塞 `job_output` |
| 队长单次长链 | 最长 209 s（`verify-all` 整表） | 整表体检放后台 + 非阻塞收；**不要占住一个 bash 调用 200 s** |

## 5 参数级纪律（立即生效，四条）

1. **`job_output` 默认非阻塞**；仅"下一步依赖它"时才 `wait: true`，`timeout_ms ≤ 120000`。**禁 `sleep` 轮询**。
2. **无信息增量的重复体检不跑**：`static-jaws`（整表）只在步表/牙集合变化后跑；其余牙**同参数短时间内不重复调**。
3. **同类牙合并成一条命令**（一次 bash 调用跑 3–5 条牙 + 汇总），减少调用次数与启动开销。
4. **被拒参数（usage/unknown-arg）不得计入基准**；**基准必须「形态 ＋ 参数值」成对固定**（同形态不同目录值实测差 24×）；`rc∈{2,4}` 一律读作 usage 拒绝。

## 6 未取到的项（具名，不编）

1. ~~`static-jaws` 逐牙耗时分布与并行化下界~~ ⇒ **已由 `t187` 补入 §3.2**（下界 32.5 s，被 `PRODUCT-ENTRY` 28.2 s 单牙卡住）。
2. `pts-pages-guard.sh`／`report-id-domain-check.sh` **全部合法形态**的系统表：**待 `t188`**（本件已给无参/`--legs`/`--tree` 三个真形态的中位值）。
3. `pkg-src-retiredpath-check.sh` 的 `--tree` 与 `--check` 两形态差异：契约里记为 `--check`（实测 `rc=4`），`t187` 记 `--tree`（5200 ms）⇒ **哪个是真形态待 `t188` 判定**。
4. `wave-push.sh --write` 的真实耗时：`t187` 因只读纪律未跑（本席另有 15–17 s 的记录，未同代复算）。
3. 本件 §2/§3 的**工具耗时含并发重叠**（同一步内多个工具并行，各自计时相加会大于墙钟）；**合并占用**只在会话级给出，未做逐工具摊销。
4. `job_output` 的通知机制能否完全替掉阻塞等待：**未被本席实测**，仅有"本会话多次收到 finished 通知"的观察。

## 7 自证

- 本件：`build/MilBridge/P1-tool-cost.md`，**112 行**（本席自算；`wc -l` 口径多末尾空行与自证行各 1），末行 sha16 自证（见末行）。
- 数据源五会话（读取时刻 2026-09-29T19:47–19:52）：captain `session-703f0164`（`origin=None`／depth 0）、`15dc97f2`（runner-A）、`8c6a7152`（runner-B）、`7f66d1f6`（scribe）、`0ed719dc`（scout），后者四者 `origin=subagent`／`depth 1`／parent 均为 captain。
- **未**改任何产品件、未跑 git 写。`t187`／`t188` 的追加节由 runner 写入本件尾（已在其契约中授权）。
sha16(P1-tool-cost.md, 内容口径=head -n -1) = 042ccb17d0b55616
