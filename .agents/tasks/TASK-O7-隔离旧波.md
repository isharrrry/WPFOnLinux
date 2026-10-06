# 任务：O7 —— `~/` 旧波目录**隔离**（不删）

> 目标：把 `~/` 下**已过期的旧波/临时目录**从"常驻占用几十 GB"降到"隔离区一份、可整批回滚"。
> ⚠️ **只 mv，不 rm**。任何"删除"动作都不许做。

## ① 背景读数（主控实测）

- `~/` 顶层 **1721** 项，疑似旧波/临时目录 **1142** 个；`du -sh` 前几名：
  `t123-runner` 6.5G｜`w62a` 5.2G｜`w-janitor-quarantine-20260926` 5.0G｜`tb21-work` 2.6G｜`t7-runner` 2.2G｜
  `t204-captain` 1.8G｜`w79-close` 1.6G｜`w185a` 1.6G｜`ason-ci` 1.1G｜`w48a` 967M｜`w98a` 811M｜
  `wv88y` 747M｜`w67-work` 744M｜`w85a` 574M｜`tb7-work` 571M｜`w29x` 534M｜`tb14-work` 531M｜`w44a` 478M｜
  `w34-framepresence-*`（数十个，每个 ~472M）…
- **必须保留（外部冻结链/复算器/哨兵）**：`w21-verify`（4.4G，冻结记录 ＋ `w27-freeze.py`）、`w153a`（`infp.sh`）、
  `wfp-runs`（哨兵）、`w-freeze-fix`。
- 环境目录不动：`netTest/`、`node/`、`.nuget`、`.dotnet`、`.local`、`.cache`、`.config`、`.claude`、`.copilot` 及一切点开头目录。

## ② 必做的两步（顺序不可反）

**Step 1 · 读者扫描（决定候选集，不许跳）**
```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
# 在"可执行面"里找出对 ~/ 下那些目录的**真引用**（排除注释/文档里的历史提及要人工判）
grep -rnoE '(/home/links-dev|\$HOME|~)/[A-Za-z0-9._-]+' --include='*.sh' --include='*.py' --include='*.tsv' --include='*.json' src Guide.Linux 2>/dev/null \
  | awk -F: '{print $NF}' | sort -u
```
把命中的顶层目录**全部加入保留清单**（例：`w21-verify`、`w153a`、`wfp-runs`、`w158a`、`w186a`… 以扫描结果为准）。
**口径**：**只有"扫不到读者"的目录才进候选**；扫得到的一律保留，并在报告里逐条点名"谁读它"。

**Step 2 · 隔离（mv，不删）**
```bash
Q="$HOME/w-quarantine-20261006"; mkdir -p "$Q"
# 逐项：mv "$HOME/<候选>" "$Q/"     （同盘 ⇒ 瞬时；跨盘会变慢，及时报）
# 先出**候选清单**（名字 + du -sh）落盘到 $Q/CANDIDATES.tsv，再**逐条** mv；每 mv 一条追加到 $Q/MOVED.tsv
```

## ③ 边界（硬）

- **允许**：在 `$HOME` 下 `mv` 候选目录到隔离区；写隔离区的 `CANDIDATES.tsv`/`MOVED.tsv`/`README.md`。
- **禁止**：`rm -rf` 任何东西；动保留清单里的目录；动 `netTest/`、`node/`、点开头目录；动 `~/w21-verify`／`~/w153a`／`~/wfp-runs`／`~/w-freeze-fix`；
  动**任何正在被进程使用**的目录（先 `lsof +D` 或 `ps` 排除）。
- 单条 mv 失败 ⇒ 记下、继续，不中断全批；最后汇总失败项。

## ④ 验收（可计算）

| # | 判据 |
|---|---|
| A | `$Q/CANDIDATES.tsv` 存在，且**每一条候选**都能在 `Step 1` 的扫描结果里证明"零读者" |
| B | `$Q/MOVED.tsv` 的条目数 == 实际已移动数；`$Q` 下逐项存在 |
| C | 保留清单里的目录**一个都没动**（`du -sh` 前后对照，逐条给值） |
| D | 隔离后 `du -sh ~` 的下降量 ≥ 候选总和（给前后两值） |
| E | `~/` 顶层项数：隔离前 1721 → 隔离后应减少 == `MOVED.tsv` 行数 |

## ⑤ 报告

- Step 1 的扫描原始输出（顶层目录清单）。
- 保留清单（逐条给"谁读它"：文件:行）。
- 候选清单 + 隔离后 `~/` 顶层项数与 `du -sh ~` 前后值。
- 失败/跳过的项，逐条写明原因。
- **不许删任何东西**——报告里要能看出"隔离区可整批 `mv` 回去"。
