# 任务：结构上游化 · **第 4 轮（窄而专）** —— 只攻 `tline-gate` 一项，通则走完 D2

> 前情：合并波的**近完整成果**已提交并打标签 **`archive/wave-merge-r3`**（9 笔，`ab0f56aad`…`56faf9561`）。
> 工作区当前在基线 `07a0099d2`（干净）。**本轮从该标签出发**，不要从零重放。
> 先读：`.agents/tasks/TASK-合并波.md`（纪律/落点/登记/D1-D3/回退）＋ `docs.Linux/evidence/STAGE3-SCOPE-REPORT.md`。

---

## ① 起步（照抄）

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
git status --short          # 期望空
git checkout archive/wave-merge-r3
git log --oneline -3        # 期望 56faf9561 / a50ea7347 / a8dd48d1e
# 复核结构面还在（应「在」）：
test -d src/Linux && test -d src/Microsoft.DotNet.Wpf && test -d src/Microsoft.DotNet.Wpf.Linux && test -d Guide.Linux && echo LAYOUT-OK
dotnet build src/Linux/wpf-linux.sln -c Release --nologo -v q   # 期望 0 错
```

## ② 本轮的**唯一目标**：`tline-gate（五臂）` 转绿（或转回 `NOINFO`）

**已知读数**：
- **基线态**（`07a0099d2`）跑 `bash build/MilBridge/tools/tline-gate.sh` ⇒ **`TLINE_GATE=NOINFO arms=5 red=0 green=0 noinfo_arm=5`**、
  `GATE_PROBE=NOINFO state=DECL-GAP`；而基线 `verify-all` 是 64✅/0❌ ⇒ 说明**该步 NOINFO 记绿**。
- **标签态** ⇒ 它变 **红**。
- ⇒ 目标其实是：**把 `tline-gate` 从"红"弄回"NOINFO 或绿"**，判据是 `bash Guide.Linux/verify-all.sh` 里该步不再计红。

**要查的三条线（逐条给读数）**：
1. **世代/臂日志陈旧**：`generation=` 与 `tree_gen=`、以及臂日志目录（`~/wfp-runs/tline-gate-*`、`~/w21-verify/*arm*`）与当前九位是否同代；
   重冻会不会把"期望世代"推到新代而臂日志仍是旧代 ⇒ 判细。**重取五臂**要真跑（`retake-arms-w21.sh`/`retake-arms-w23.sh`；注意它们要 X 与构建，耗时长、注意磁盘 ≥5 GB）。
2. **`GATE_PROBE state=DECL-GAP`**：`build/MilBridge/tests/CoverageProbe/Program.cs` 的 `tab-oracle-*` 三项"自报"为何缺席；
   是路径改写把它打空，还是它本来就 `自报=-`（基线也如此）。
3. **`gate-selfreport-mismatch`**：`COLUMN-FLOOR` 报 `pass=3 fail=1` 是否同源。

**判定口径（重要）**：
- 若**基线态同样是 NOINFO**、而标签态变红 ⇒ 先证明"红是**装置世代/臂日志**引起、不是产品缺陷"（给成对读数）；
- 若结论是"必须重取五臂"，就真跑重取；跑完再冻、再跑 `verify-all`；
- **不许**用环境开关/改判据把该步压成绿（那是削弱判据，本波明令禁止）。

## ③ 通了之后：走完收口（照 `TASK-合并波.md`）

1. **D1**：`dotnet build src/Linux/wpf-linux.sln` 0 错；6 套测试 0 失败；13 颗结构牙 ＋ 8 颗关键牙全绿；
   `bash Guide.Linux/verify-all.sh` 剩余红**逐条具名归因**。
2. **一笔**提交（本波只此一笔；前 9 笔已在标签里）。
3. **重冻**（若前 9 笔已冻住，则核对而非重做）；`docs/ROUTES.md §8` 同步。
4. **D2**：`bash Guide.Linux/verify-all.sh` **×2** 各 `0 ❌`（步数以现场 `VERIFYALL-STEPS-DECL` 为准，本波加了两台新牙 ⇒ 可能是 66）。
5. **最后**：自证 `docs.Linux/evidence/UPSTREAM-MANIFEST.tsv` == 工作树 ⇒ `git rm -r upstream` ＋ 提交 ＋ 再跑一趟 `verify-all` 确认不新增红。

## ④ 边界

- 照 `TASK-合并波.md` §④。**新增**：本轮**只许动与 `tline-gate`/臂日志/世代码/COLUMN-FLOOR 相关的件**，
  以及 §③ 收口所必需的件；**不得**再改落点或七类路径。
- **禁止**：削弱任何判据（改 `--expect`、加豁免、关开关）来凑绿。

## ⑤ 硬停条件（本轮不许越界）

若对第 ② 节三条线各试到 2～3 种做法**仍不能让该步不再计红** ⇒ **停手**，**不要**把标签前进到 `feat-Linux`，**不要**删 `upstream/`，而是：
- 保留标签与工作区（工作区就停在标签态，便于下一步）；
- 输出：① 该步的**成对读数**（基线 vs 标签态 vs 你的尝试）；② 你判定的根因与证据；③ 你**推荐的收口方式**（含"是否可接受一条具名红"的建议）；
- 明确写"**未达 D2**"。
- ⚠️ 若要回退到基线：`git checkout feat-Linux && git reset --hard 07a0099d2`（**并给复原读数**）。

## ⑥ 报告

- `tline-gate` 的成对读数（基线／标签／尝试后）＋ `verify-all` 步骤通过/失败数（逐趟）。
- 你动过的每一件（`git status --short` ＋ `git log --oneline`）。
- 九位/`inputs_fp`/基线前后值。
- 结论：**D2 达成** 或 **未达 ＋ 具名残余 ＋ 推荐收口**。
