# 任务：结构上游化 · **收尾（把整波真正闭合）** —— 补外部冻结记录段，让 `close-wave [5c/6]` 四档转绿

> 现状：`feat-Linux = 914962338`，工作区干净，`verify-all` **66✅/0❌**（已达成 D2），
> `bash src/Linux/samples/ThirdPartyMini/run-thirdparty-mini.sh 20` ⇒ **`THIRDPARTY=PASS max_colors=1644`**（主控亲测）。
> **本轮只做"整波闭合"**：把外部冻结记录段补齐，让 `close-wave.sh` 的 `[5c/6]` 四档转绿。
> 先读：`docs/PORT-SPEC.md`（§5 整波链）＋ `docs/FORK-AND-PUSH.md §3.1`（七步）＋ `.agents/tasks/TASK-合并波.md`（纪律）。

---

## ① 现状读数（我实测，别重查）

```
WFREEZE_CONSISTENCY=FAIL rootdefault=FAIL decl=PASS nineauth=FAIL blockvalues=FAIL（四档互不代偿）
WFREEZE_TEMPLATE_AUTO src=freezer-GENS path=/home/links-dev/w21-verify/w82/freeze/w82-record.txt
WFREEZE_BLOCKVALUES_TIER_NA keys=windowsbase,hbtextline,dwf
```
- `~/w21-verify/` 下有 `w81*/w82*`，**没有 `w83*`** ⇒ 记录段缺失，模板回退取 `w82`。
- 仓内声明面**已**是 `#83`：`docs/CURRENT-STATE.md:9` = `BASELINE-FROZEN gen=#83 sha16=cc7d2c486ca268b8`（我核过，与 `src/Linux/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 实测 sha16 逐位相符），`ACCEPTANCE-BASELINE.md` 已有 `# RE-FROZEN #83`。

## ② 要做的事（按序；**用本仓自己的冻结链，别手工糊**）

1. **备份外部冻结器**：`cp -p ~/w21-verify/w27-freeze.py ~/w21-verify/w27-freeze.py.bak-pre83`（可回退）。
2. **先落那一行路径修正**（把它并进本轮唯一一笔收尾提交）：
   `docs/CURRENT-STATE.md:9` 的 `file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` → `file=src/Linux/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（**只改路径，不动 `gen`/`sha16`**）。
   > ⚠️ **顺序很要紧**：本仓 SDK 会把提交号编进 `AssemblyInformationalVersion` ⇒ **任何新提交都会让九位再位移一次**。
   > ⇒ 先把**所有**提交做完，再冻结；**冻结之后就不要再提交**（除 §②.7 的清单收尾）。
3. **在冻结器里加 `GENS['#83']`**：照 `#82` 条目的**形状**逐字段填（新记录模板路径 `~/w21-verify/w83/freeze/w83-record.txt`、
   本代九位现取、`allow_changed` 按**实际位移位**列全、`pf_required` 与现状一致）。**逐字段要有依据**（`WFREEZE_DECL` 会把预登记文本与 `GENS` 逐字段对拍 ⇒ 两边必须一致）。
4. **建 `~/w21-verify/w83/`**（`freeze/`、`logs/`、`bin/`），由 `#82` 的 `w82-record.txt` 为模板生成 `w83-record.txt`（三段 `===BANNER===`／`===FROZEN===`／`===RECORD===`；
   `{NSTEP}`/`{NCASE}`/`{NSKIP}`/`{GEN}`/`{PREV}`/`{WSH*}` 全部换成**现取真值**）。**`# RE-FROZEN` 块里锚定声明行必须齐**（缺声明 ⇒ 冻结机器判 `NOINFO`，不算过）。
5. **重发 roster**：`python3 src/Linux/build/MilBridge/tools/wave-freeze-consistency-check.py --emit-roster`（把 `src/Linux/build/MilBridge/wfreeze-root-sites.tsv`
   按**新落点**重出）⇒ 治 `WFREEZE_ROOTDEFAULT=FAIL`。
6. **治 `WFREEZE_NINEAUTH=FAIL`**：同名产物的多条"权威路径"之间必须相等（见该脚本 `NINEAUTH` 档）——按现落点把两条路径与**真实产出目录**对齐；
   若确属"两条路径本就该不同"，按脚本口径给出**具名**处置（不许改判据）。
7. **治 `WFREEZE_BLOCKVALUES=FAIL`**：`src/Linux/build/MilBridge/blockvalues-shift.tsv` 逐键声明（`block9`/`tier`/`live` 三格**逐位现取**、`registered=` 用**已入册**缺陷号，`why` 写明成因）。
   注意 `TIER_NA keys=windowsbase,hbtextline,dwf` —— 这三键只由九位行授权、不判，别乱补。
8. **复跑判定**：`bash src/Linux/build/close-wave.sh`（整趟；若耗时过长，至少跑到 `[5c/6]` 并给原始行）⇒ 期望
   `WFREEZE_CONSISTENCY=PASS rootdefault=PASS decl=PASS nineauth=PASS blockvalues=PASS`。
   然后 `bash Guide.Linux/verify-all.sh` **一趟**确认**仍 66✅/0❌**（冻结不该把判据面弄红）。

## ③ 边界

- **允许**：改 `~/w21-verify/**`（外部冻结链，这是本仓规定动作）、`src/Linux/build/MilBridge/wfreeze-root-sites.tsv`、
  `src/Linux/build/MilBridge/blockvalues-shift.tsv`、`docs/CURRENT-STATE.md:9`（仅路径）。
- **禁止**：改任何**产品件逻辑**、改落点、**削弱判据**（改 `--expect`／加豁免／关开关／把 `NOINFO` 当绿）、
  在冻结之后再新增提交（除上面 §②.2 那一笔）。
- **尝试上限**：每个档 2～3 种做法。

## ④ 硬停

四档里任何一档 2～3 种做法仍不 PASS ⇒ **停手**：**保持**现有 `feat-Linux = 914962338`（`verify-all` 66/0 的可用状态）不被弄坏，
`git status` 必须干净或**任何**未提交改动都要列清；输出每档的成对读数与你的根因判断。**不要在解锁不了的四档上继续改产品件。**

## ⑤ 报告

- `bash src/Linux/build/close-wave.sh` 的 `[5c/6]` **原始行**（四档逐条）。
- `~/w21-verify/w83/` 的实际树 ＋ `w83-record.txt` 的 `===FROZEN===` 段原文。
- `GENS['#83']` 的条目原文（含 `allow_changed` 与依据）。
- `git log --oneline -3` ＋ `git status --short`；`inputs_fp` / 九位 / 基线**前后成对值**；`verify-all` 一趟的通过/失败数。
- 结论：**四档 PASS** 或 **未达 ＋ 逐档具名残余 ＋ 推荐**。
