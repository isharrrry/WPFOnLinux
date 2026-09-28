# P1-W1 判据（**先写，后取读数**）—— `scribe` / `t6`

`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜基点 `HEAD=88ab841`｜本件读时 `2026-09-28T15:43:53+0800`（**现取，早于任何写**）

## 0 我承诺的写域
**改**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`、`build/MilBridge/tools/defect-registry-declared.tsv`；
**新建**：`build/MilBridge/P1-dg179-criteria.md`、`build/MilBridge/P1-dg179-report.md`。
其余一件不改；不跑 `dotnet`／门禁长跑／显示位；不 `git add`／`commit`／`push`。

## 1 分母与口径（先写死）
- **名单口径**：`BOOK_ENTRY_UNREQUIRED_MISSING` 的元素集 ＝ `{declared 表里 req 含 KD 的编号}` − `{册内有条目形态标题的编号}` − `{book-entry-required.tsv 列出的编号}`；**分母 `n` ＝ 该差集的元素数**。
- **条目形态口径**（照牙的正则逐字，不复述、不"改进"）：`^#{2,4}.*(^|[^0-9A-Za-z-])<ID>([^0-9]|$)`。
- **册内命中口径**：`grep -c 'D-G179'`（子串计数，**含引用**）。⚠️ 本号在 `D-G180` 正文里**已被引用** ⇒ 落册前 `≥1` **正常**；**不许**把"命中数不变"读成"条目没落上"（条目形态要用 `^#{2,4}` 那条正则单独判）。
- **三态口径**：`DEFREG`／`REPORTID` 的 `PASS rc=0`／`FAIL rc=1`／`NOINFO`（`rc=2` 或 `3`）。

## 2 判什么 ＋ 什么算成立／不成立
| # | 腿 | 成立（绿） | 不成立（红／需归因） |
|---|---|---|---|
| ① | **正极**（真树：条目落册 ＋ 同趟 `--emit`） | 两遍 `DEFREG=PASS declared=215 route_ids=215` ∧ `DECLDRIFT=0 keys=-` ∧ `rc=0`；`REPORTID=PASS`（**不退化**） | 任一遍非 `PASS`；或 `DECLDRIFT≠0` |
| ② | 正极**观察项**：`D-G179` 在名单里的去留 | **消失** ⇒ 与条目形态判定一致 | **仍在** ⇒ **不许假设、不许当绿**：必须给出归因（给不出 ⇒ 本项 `NOINFO`） |
| ③ | **反极 A**（沙箱：把 `D-G179` 列入**要求清单副本** ∧ 册内**无**其条目形态标题） | `REPORTID=FAIL` 且**点名** `D-G179` ＋ `rule=book-entry-heading-missing` | 只上屏"可见"、不判红、不点名 ⇒ 不成立 |
| ④ | **反极 B**（沙箱：手工把 `req` 加宽到**命中 `0`** 的 route 键） | `DEFREG=FAIL reason=declared-id-missing-in-route` 且**点名**该号 ＋ `MISSING-IN=<键>` | 静默 ⇒ 不成立 |
| ⑤ | **追加腿 C**（沙箱：**陈旧表**（`req=KD`）＋ 把该号在 `KD` 的**提及整体删除** ⇒ `KD` 命中 `0`） | `DEFREG=FAIL` 点名 `MISSING-IN=KD` ⇒ 把"恒真"的射程**界定为「同趟生成的那张表」** | 若它也 `PASS` ⇒ 须把"恒真"改写成"连陈旧表也恒真"并如实点名 |
| ⑥ | 形态不变量 | 册**只增不改**：旧行按序子序列 **100%** 在位 ＋ `git diff` 删 `0` | 任一旧行缺失 ⇒ 停手 |
| ⑦ | 引用纪律 | 写进册的**每一个** `D-G<digits>` 都已在 `declared` 集内（否则触发 `undeclared-id-in-route` 红） | 出现未在册号 ⇒ **停手报队长**，不自行立号 |
| ⑧ | 锚一致 | `--emit` 后 `# DECL-ANCHORS` 的 `KD=` ＝ 册现取 `sha16` | 不等 ⇒ 重发不当 |

## 3 `NOINFO` 条件（**不许当绿**）
1. 沙箱构造／工具不可用 ⇒ 该腿 `NOINFO` ＋ 具名原因；
2. 改写后 `BOOK_ENTRY_UNREQUIRED_MISSING` **整行不再上屏**（该行消失）⇒ **不得**读成"已销账"，改用**逐号 `grep`** 细判；
3. 读数与预期不符且**无法归因** ⇒ 该腿 `NOINFO`（既不当绿也不当红），并在报告里**逐字**记原始机读行。

## 4 停手条件
`stat -c %h ≠ 1`／出现未在册编号／`porcelain` 超出写域／`--emit` 预览与现场不符（route 件漂移）⇒ **停手报队长**。
