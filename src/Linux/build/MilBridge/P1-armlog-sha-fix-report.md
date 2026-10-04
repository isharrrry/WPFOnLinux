# P1-armlog-sha-fix 报告（`t72`）—— 队长裁定 **(B) 回退**：`known-red.json` 三值还原、`ARM-LOG-SHA` 的红**保留在册**（它是真话）＋ 同族口径入册

**本件口径**：读数一律**捕获式取 `rc`**（`cmd >out 2>err; echo $?`，不接管道 —— 第 `27` 条）；每格带**亚秒 `ts=`**；`NOINFO` 具名（§8）；**未跑整趟门禁**；`arm-logs` 内容**未动**、硬链接**未改成拷贝**。
**⚠️ 与原始 `acceptance` 的关系（如实写）**：本单原始验收要求「该步回绿」；**该条已被队长本趟的 (B) 裁定取代** —— 现取证明「改声明换绿」会把另一条已接线牙（`COLUMN-FLOOR`）顶红，且**两条牙的红各自都是真话** ⇒ 裁定＝**回退＋把红留在册**。

## 0. 一句话
`t67` 重取三份臂日志后，`ARM-LOG-SHA`（**登记表 `known-red.json` vs 现盘**）变红 —— 我按 (甲) 试过「改声明」：`ARMLOG_SHA` 确实回到 `PASS`（`rc=0`／`pass=5 fail=0`），**但同一笔把 `COLUMN-FLOOR` 的 `ARMLOG` 半顶红**（`arm_logs` vs **冻结块**）⇒ 净效果是**红换红**、而且是**掐掉一条真信号**。队长裁 **(B) 回退**：三值还原（还原后与 `HEAD` 版**逐字节 `IDENTICAL`**、`git diff --numstat` **归零**）、`cell=#1` 追回旧 `fp`、`DEFREG` 回 **`DECLDRIFT=0`**、`COLUMN-FLOOR` **绿**、**唯一红回到 `ARM-LOG-SHA` 并保留在册**；重冻结归下一波（§5）。

## 1. 写域（**3 件**）终态与成对读数
| 件 | 本趟「改前」（`HEAD`） | (甲) 试改后 | **(B) 回退后（终态）** | `stat -c %a` | `git ls-files -s` |
|---|---|---|---|---|---|
| `build/MilBridge/known-red.json` | `6351a46296d17b28`／`509` | `29219b6f071c6361`／`509` | **`6351a46296d17b28`／`509`（＝`HEAD` 逐字节相同）** | `644` | `100644` |
| `build/MilBridge/arm-logs/README.md`（口径段） | `7de8a8cb069be60a`／`66` | — | **`337de20145258568`／`67`（保留，与本次裁定无关）** | `600` | `100644` |
| `build/MilBridge/P1-armlog-sha-fix-report.md`（本件） | — | — | 见末行自证 | `644` | 未入索引 |
**另（第 `28` 条追写面）**：`build/MilBridge/HANDOFF-NEXT.md` —— (甲) 那笔追写了 `cell=#1`（新 `fp` `d4a1c1138b1742677d79bd12bae10dc69f4c0296c91f596e87115a5d079e5252`），回退时**再追写一条**把它**追回旧 `fp`**（见 §2 ④）。
- **回退的机器证（三条）**：① 还原后 `cmp`（我按 `git show HEAD:` 取 `HEAD` 版并逐字节比对）⇒ **`IDENTICAL`**；② `git diff --numstat -- build/MilBridge/known-red.json` ⇒ **空**（即 `0 0`，**归零**）；③ `tline`／`textlineproto` 两项**与 `HEAD` 逐字相同**（`arm_logs` **整表**与 `HEAD` 相同 ⇒ 我从未碰过这两项）。
- **模式守恒自证（两口径成对）**：`known-red.json` `644`／`100644`（回退后与 `HEAD` 相同）；`arm-logs/README.md` **`600`／`100644`**（**原样保留、未去改它的模式**，属 `D-G187` 第 `2` 形态既存现场）；本件 `644`／未入索引。写前 `cp -p` 备份：`~/w281-scribe/bak/{known-red.json,HANDOFF-NEXT.md}.pre-t72`。

## 2. ① 回退动作（逐条）
- **① `known-red.json` 三个 token 还原**（完整 `64` 位 `hex`；**只还原这三个，其余一字未动**）：
  - `tab-zero`：`b5239c4e5b95fa5625ed573c7a3f4f63cadaed5224f0565f84d8a0694e54ae07` → **`9150c3a26a3cb789582f3df655006955cf1db10dda00d91097d24d97b40e1912`**
  - `tab-rtl`：`70feb4b5d4ab80f70833140556bd97c207439b85cde3b114e02d939091a2b25e` → **`92570318851ca7e85f64017c89bd784d971cfe4028f7b8e47cb79035146755c4`**
  - `tab-anchor`：`2e62d68ed5edd5e7b68c7d965cd74b8ab6c3a203c36b516ba340812c69674948` → **`1c43a12dcaa5718a27f5e4c66d6ff59bd3b6da0b199e384a315b54e7041cc916`**
- **② `tline`／`textlineproto` 确认**：两项现值 `0153827e9c590d1e9dcd51c168a40e625a005c06b9f553b94cf0eaa5ba951eb3`／`c537f0c007a6c9226cfb1d82b42e565056968dc3302976f4d17d3b26d32c901a` —— **与 `HEAD` 逐字相同 ⇒ 从未被动过**。
- **③ `arm-logs` 内容不动、硬链接不动**：三份现取 `nlink=2`、`sha16` ＝ `b5239c4e5b95fa56`／`70feb4b5d4ab80f7`／`2e62d68ed5edd5e7`（**内容＝`t67` 换代后的值，未动**；**未改成拷贝**）。
- **④ 第 `28` 条：`cell=#1` 追回旧 `fp`** —— `HANDOFF-NEXT.md` 追加一条 dated 行：`ts=2026-09-28T21:20:45.022+0800` 现取 `fp` ＝ **`3cdd4b77d98f16b641469dd7ca733d9f21943fff568d37d7f0679029915c74be`**（**与回退前的旧值逐位相同** ⇒ 覆盖面内容面已随回退复原）；该件 `581 → 583` 行（`6ce77c4b3809290e → 825128d27b89bd55`）。
- **⑤ 复跑（原样）**：`HANDOFF-MV` **`rc=0`／`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`**（`ts=2026-09-28T21:20:45.089+0800`）｜`DEFREG` **`rc=0`／`DEFREG=PASS declared=223 route_ids=223`** ＋ **`DEFREG_DECLDRIFT=0 keys=-`**（**无需 `--emit` 即自洽** ⇒ 未越域）｜`COLUMN-FLOOR` **`rc=0`／`COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无`**｜`ARM-LOG-SHA` **`rc=1`／`ARMLOG_SHA=FAIL … pass=2 fail=3`**（＝**回到并保留那条真红**）｜`static-jaws` **`rc=1`／`STATICJAWS=FAIL fails=1`**，**唯一红 ＝ `ARMLOG-SHA`**（`STATICJAWS_HIT step=ARM-LOG-SHA … rc=1`），另一颗 `NOINFO` ＝ `FrameProbe-frame rc=2`。

## 3. ② 那条红是**真话**，必须留下（本次裁定的核心，逐字在册）
- **现象**：`ARMLOG_ARM=tab-zero FAIL reason=sha-mismatch decl=9150c3a26a3cb789 live=b5239c4e5b95fa56 nlink=2`（`tab-rtl`／`tab-anchor` 同形）⇒ `ARMLOG_SHA=FAIL shape=flat required=5 declared=5 pass=2 fail=3`。
- **真因**：`t67` **重建探针后重取了这三份臂日志**（换代） ⇒ **现盘 ≠ 冻结块**（冻结块 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 仍记换代前的值）⇒ 登记表若跟着现盘走，就与冻结块分叉。
- **两条牙的命门关系（写死）**：**`ARM-LOG-SHA`（登记表 `known-red.json` 的 `generation.arm_logs` **vs 现盘日志**）与 `COLUMN-FLOOR` 的 `ARMLOG` 半（同一份 `arm_logs` **vs 冻结块**）**只能同时绿，当且仅当「现盘 = 冻结块」**** ⇒ 现盘一变而冻结未做 ⇒ **必有一红**。
- **处置时机 ＝ 重冻结批**（不是改登记表）：见 §5。
- **为什么回退**：我用「改声明」把 `ARM-LOG-SHA` 换绿，代价是 `COLUMN-FLOOR` 转红、且 `DEFREG` 出现 `DECLDRIFT=1 keys=KRJ`（`KRJ` 正是 `known-red.json` 的锚）⇒ **净效果是「红换红」，并且掐掉了一条真信号** ⇒ 按裁定回退，把真话留给重冻结批。

## 4. ③ 队长口径句（逐字入册）
**「凡换代**被冻结块盯着的件**（例：`arm-logs/*.log`、九位产物、基线件），必须同趟做**重冻结**（登记表 `known-red.json` ＋ 冻结块 ＋ 基线件 ＋ `CURRENT-STATE` ＋ `HANDOFF-NEXT` 的对应格 ＋ 同趟 `--emit`），否则 `ARM-LOG-SHA` 与 `COLUMN-FLOOR` 必有一红 —— **红在每个方向上都是真话，掐掉任一条都是假绿**。」**
（根因认账：`t67` 的契约里**没写**「换代 ⇒ 必须同趟重冻结」，所以这一族的红在两条牙之间来回换人。本句已随本件入册；`arm-logs/README.md` 末行的口径段为同族前半。）

## 5. ④ 下一波「重冻结批」的契约骨架（**本趟不做**）
`5` 处耦合（缺一即仍有一红）：① `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` **现行代**的 `# ARM-LOG-SHA arm={tab-zero,tab-rtl,tab-anchor}` 三行（该件 `4605` 行／`47` 个块、`sha16 b96d4312565a3c49`、**不在覆盖面** ⇒ 不动 `fp`）；② `build/MilBridge/tools/wave-freeze-consistency-check.py` 模板里载的 `tab-anchor 1c43a12dcaa5718a`（九值权威）；③ `build/MilBridge/tools/defect-registry-declared.tsv` **同趟 `--emit`**（刷新 `KRJ=` 锚 ⇒ `DECLDRIFT=0`）；④ `docs/CURRENT-STATE.md` 第 `9` 行的 `BASELINE-FROZEN … sha16=`；⑤ `HANDOFF-NEXT.md` 的 `cell=#3` 与 `cell=#9`。⇒ 跨 `docs/`＋`samples/`＋`tools/`，属**正经冻结动作**（还牵世代号与四处声明），归下一波第一件。

## 6. ⑤ 自伤（如实记；`D-G186` 第 `2` 次现场，队长点名）
- **现象**：我第一次给 `build/MilBridge/arm-logs/README.md` 追加口径段时用了**未加引号的 heredoc**（`<<EOF`）⇒ 行内**反引号中的 token** 被 shell 当**命令替换**执行。
- **`stderr` 现取（逐字）**：`bash: 行 1: t67: 未找到命令`／`bash: 行 1: t72: 未找到命令` ⇒ 正文里那两个 token **被替换为空**（`D-G186` 同族：自述含反引号且落在会被 shell 解释的位置）。
- **讽刺点**：这次是**在写「不许这么写」的那条口径句时踩的**（口径句本身引用了 `` `t67` ``／`` `t72` ``）。
- **修法（此后照此）**：写含反引号的文本一律用 **加引号的 heredoc（`<<'EOF'`）** 或 **python 字面量**；本趟已用 python 重写该行 ⇒ `numstat` 仍 `1 0`、前 `66` 行与 `HEAD` `cmp` 相同。

## 7. 红线与不变量（现取，`ts=2026-09-28T21:20:57.614+0800`）
四条不变量未变：`^run_step "` ＝ **`62`**｜覆盖面 ＝ **`234`**｜首行 `DECL` ＝ **`62 gen=#81`**｜`--expect` ＝ **`234`**；两枚哨兵 `cmp` **`rc=0`（IDENTICAL）**；`verify-all.sh`／`build/close-wave.sh`／`src/`／`build/MilBridge/tools/**` **本席一字未改**（**未越域**：`DEFREG` 自洽故**无需** `--emit`）；未跑整趟门禁；未 `git add`／`commit`。

## 8. `NOINFO`／边界（具名）
① **未跑整趟门禁**（本件只做回退 ＋ 复跑相关牙）；② **提交级 `numstat` 给不出**（本席不 `git add`／`commit`）⇒ 回退由**工作树级 `numstat` 归零 ＋ 与 `HEAD` 逐字节 `IDENTICAL`** 承担；③ `ARM-LOG-SHA` 的红**保留、未修** ⇒ 「现盘与冻结块已分叉」这条**世界事实仍成立**，修它归**重冻结批**（§5）；④ `arm-logs/README.md` 的模式 **`600`**（与索引 `100644` 分叉）**未去改**（`D-G187` 第 `2` 形态既存现场，只记两口径）；⑤ `t67` 的其它漏项（若有）**不在本件射程**。
⏪ **本件自证（末行；口径 `head -n -1 build/MilBridge/P1-armlog-sha-fix-report.md | sha256sum | cut -c1-16`）**：`10eb2db1078c8c7c`（**整件全文 `sha256` 只在交件消息里给**，第 `24` 条）。
