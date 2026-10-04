# 任务 T-F0 · 未闭项批（`TASK-0758/0759/0760`）—— 只读侦察 ＋ 逐条落点表

## ① 任务目标
你是本项目（`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`）的**只读侦察**子代理。为 `TASK-0758`／`0759`／`0760` 做逐条现取侦察，产出「件:行 ＋ 现值 ＋ 修法 ＋ 归属」表。要覆盖：

**0758（守卫射程洞）**：
- `build/MilBridge/tools/pkg-src-retiredpath-check.sh` 现取 `tree` 面（声明约 `107-110`，仅本次有效）逐字；证明它**不扫 `*.cs``；现取带死根的 `.cs` 件清单（≥10 件，逐件路径 ＋ 死根常量行原文）。

**0759（口径句入判据件批）**：
- ① `build/MilBridge/tools/pts-pages-guard.sh` 现取是否含「零证据力」口径句（`grep -c`）；该句现载体（`build/MilBridge/P0-mvp-pts-report.md` 现取行原文）。
- ② `~/w21-verify/w27-freeze.py` 现取 `provider` 两值注释（声明约 `:443-444`）逐字，判"注释与事实不符"。
- ③ `D-G178`／`D-G181` 在册条目现取（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`）＋ 需改内容锚的位置。

**0760（装置小单批）**：
- ① `build/MilBridge/arm-logs/README.md` 现取 ＋ `repo-alias-allow.tsv` 现取（硬链接两案的现状与上限）。
- ② `~/w79c/bin/w79-push.sh` 现取 `FILES` 累积语义（现状：**仓外**）。
- ③ `build/MilBridge/tests/PtsPagesProbe/session_inner.sh` 现取 `:18` 显示号缺省行原文。
- ④ `D-G176` 预留号的在册状态（`known-red.json`／`KNOWN-DEFECTS.md` 现取）。

## ② 边界条款
- **只读**：除载体外不许改任何仓内文件。
- **不要跑** `static-jaws-check.sh`；不要跑整趟 `verify-all`。
- 进程只按 PID；显示位只用空闲 `:23x`；禁 `sleep` 轮询；大文件只用 `wc`／`head`／`tail`／`grep -c`。
- 载体（**唯一可写文件**）：`build/MilBridge/P1-tail2-unclosed-recon.md`（不用 `report` 字样）。
- 每条最多 2–3 种方案；失败即报停止。

## ③ 验收标准（可计算）
载体必须含**逐条表**，每行四列：`条目 | 现取定位(件:行, 仅本次有效) | 现值/原文 | 修法草稿(可执行)`；并覆盖 0758（≥10 件死根 `.cs` 清单）／0759（3 条口径句现状）／0760（4 条小单现状）；另给「逐条归属（哪条路线/哪件写域）」。

## ④ 失败报告格式
同 A0。

## ⑤ 完成报告格式
同 A0。
