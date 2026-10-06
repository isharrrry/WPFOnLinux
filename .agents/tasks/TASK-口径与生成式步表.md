# 任务：落两条"规则/机制"修正 —— ① 冻结记录模板口径 ＋ ② `verify-all` 步表**生成式**

> 现状：`feat-Linux = 1c9ee114d`，本地==远端，工作区干净，`verify-all` **67✅/0❌**，`[5c/6]` 四档 PASS。
> 先读：`docs/PORT-SPEC.md`、`src/Linux/build/MilBridge/tools/wave-freeze-consistency-check.py`（件头 ＋ `--selftest`）、
> `src/Linux/build/MilBridge/tools/verify-all-step-check.sh`（**第 58–63 行的锚设计与"为什么是故意的"**）、
> `docs.Linux/evidence/freeze/w85-record.txt`。

---

## ① 冻结记录：把"模板口径"写死，并补一台"残渣"牙

**事实（已核实，别推翻）**：记录段是**模板**。`wave-freeze-consistency-check.py:634,822` 明写
「九位行**本应全是 `{…}` 占位符**」「承载现取值的行里**不许出现 16 位 hex 裸字面量**」；
设计动机（件头:29）：`fill()` 只能抓"用了没定义的占位符"，**结构上抓不到"把本该现取的值写死了"**。
本波真出现过的**真漏**是 `date=2026-10-06Txx:xx+08:00`（半填），**现有机制抓不到它**。

**要做两件**：
1. **口径成文**：把下面这段写进 `docs/PORT-SPEC.md`（新增一小节，别改既有正文）——
   > **记录段（`docs.Linux/evidence/freeze/w<NN>-record.txt`）是模板。**
   > `{…}` 占位符**必须保留**（它是"该现取的值不可能被写死"的**保险丝**，见 `WFREEZE_TEMPLATE` 的 `kind=nine` 规则）；
   > **判"记录是否落地"不看有无占位符**，而看 `WFREEZE_BLOCKVALUES` / `NINEAUTH` / `NINESYNC` 三档（它们拿 `GENS` 的值**代换后**与现场对拍）。
   > **不许**为了"看起来填满了"而把 `{…}` 换成裸值（那会把保险丝拆掉，制造"看着像真的、其实是旧值"的假绿）。
   - ⚠️ `docs/PORT-SPEC.md` 可能在**孪生件登记表**里被牙盯 sha16 ⇒ 改完**必须**跑
     `bash src/Linux/build/MilBridge/tools/hygiene-tooth.sh`（及其它读它的牙）并**同趟登记新 sha16**；红了不许放任。
2. **给 `WFREEZE_TEMPLATE` 加 `kind=residue`**：扫**未替换残渣**——机器行（形如 `^[#[:space:]]*[A-Za-z_][A-Za-z0-9_]*=`）里出现
   `xx:xx`／`\bxx\b`／`\bTBD\b`／`\bFIXME\b` 之类**半填占位** ⇒ `WFREEZE_TEMPLATE=FAIL` ＋ 逐行点名 `kind=residue line=N`。
   **要求**：
   - **反极性真跑**（写进 `--selftest` 一腿）：往模板里注入一行 `X=xx:xx` ⇒ 必红并点名 `kind=residue`；
   - **不误伤正文**：本件正文里本来就有大量散文（可能含 "xx"）⇒ 只判**机器行**；给成对读数（现件 PASS → 注入 FAIL → 复原 PASS）；
   - **不许**削弱既有 `kind=nine` / `kind=other` 的判定。

## ② `verify-all` 步表**生成式**（把"三处手改"消掉，且**不改门禁外形**）

**事实（已核实）**：`verify-all-step-check.sh:63` 抽步名的方式是
`sed -n 's/^run_step "\([^"]*\)".*/\1/p'`——**看脚本字面量**；且第 58–60 行注明"**这是故意的**"（缩进/注释/换名的都不算）。
⇒ **所以"脚本读表执行"这条路必然把牙弄瞎**（名字数到 0）。
⇒ **本任务采用"由表生成那些行"**：

1. **唯一来源**：新建 `src/Linux/build/MilBridge/verify-all-steps.tsv`
   列：`seq<TAB>name<TAB>cmd<TAB>needs_x<TAB>bare_tooth`（首行表头 ＋ `#` 注释；**现读 67 步逐条录入**，逐字照现脚本）。
2. **生成器**：新建 `src/Linux/build/MilBridge/tools/gen-verify-all-steps.py`：
   - 读 tsv ⇒ 生成 ①`run_step "…"` 整块（**与现脚本逐字同形**，含缩进风格）②`# VERIFYALL-STEPS-DECL: <N> gen=<GEN>`
   ③`# VERIFYALL-STEP-NAMES: 名1 | 名2 | …`（若现脚本用的是别的承载行名，以现场为准）；
   - `--check` 档：**只读**、对拍，不写盘；
   - `--write` 档：就地替换 `Guide.Linux/verify-all.sh` 里的生成块（块用
     `# >>> GENERATED-BY: gen-verify-all-steps.py >>>` / `# <<< END GENERATED <<<` 夹住）。
3. **落进 `verify-all.sh`**：把现有那 67 条 `run_step` ＋ 三条声明**换成生成块**（生成结果**逐字等价**：
   改前/改后 `sed -n 's/^run_step "\([^"]*\)".*/\1/p'` 的输出**逐行相同**，`diff` 为空 ⇒ 这是等价性证明，**必须先做**）。
4. **防手改牙**：新建 `src/Linux/build/MilBridge/tools/verify-all-steps-generated-check.sh`：
   `gen-verify-all-steps.py --check` ⇒ 分叉即 **FAIL 并逐条点名**（多/少/改了哪一步）。
   **反极性真跑**：手改脚本里某一步的命令（或往 tsv 加一步不重生成）⇒ 必红点名；复原回 PASS。
5. **接入门禁**：把该牙加为一步（**步数 67 → 68**），并**同趟**改：四处声明（`STEPS-DECL` 步数/口径句/`STEP-NAMES`/预登记）
   ＋ `fp_inputs()` 覆盖面（`tsv` ＋ `gen-*.py` ＋ 新牙）＋ `[42] --expect` 同趟 ＋ `HANDOFF-NEXT.md` 更正行。

## ③ 通用纪律（两条都适用）

- **不许**削弱任何判据、不许把 `NOINFO` 当绿、不许用开关把某档关掉。
- 动覆盖面内件 ⇒ `inputs_fp` 必移 ⇒ 追加 `HANDOFF-NEXT.md` 的 `cell=#1/#2/#3`（必要时 `#9`）更正行。
- **顺序**：两件都做完 → **提交** → 冻后不再新增提交 → `verify-all` **×2**。
- 任一件 2～3 种做法仍不能"绿 ＋ 不新增红" ⇒ **回退该件**，记"未做＋原因"，另一件照做；**末态 `git status` 必须干净**。

## ④ 验收

| # | 判据 |
|---|---|
| A | `bash Guide.Linux/verify-all.sh` **×2** 各 **0 ❌**（步数按现场 `VERIFYALL-STEPS-DECL`，②后应为 68） |
| B | `verify-all-step-check.sh` rc=0（`VERIFYALL_SELF=PASS names=N decl=N`）；**等价性**：改前/改后 `run_step` 步名序列 `diff` 为空 |
| C | `gen-verify-all-steps.py --check` rc=0；**反极性**：手改一步 ⇒ 新牙红点名；复原 PASS |
| D | `WFREEZE_TEMPLATE=PASS`；**反极性**：注入 `X=xx:xx` ⇒ `kind=residue` 红点名；复原 PASS；`kind=nine` 旧腿仍红（`--selftest` 全过） |
| E | `docs/PORT-SPEC.md` 新口径在册；读它的牙（`hygiene-tooth` 等）rc=0 |
| F | `[5c/6]` 四档 PASS；`THIRDPARTY=PASS max_colors ≥ 800`；`git status --short` 干净 |

## ⑤ 报告

逐件：改了什么（文件＋关键行）／成对读数／反极性原文／是否达成。
外带：`inputs_fp`／步数／九位前后值；`git log --oneline -3`；**未做项**逐一说明。
