# 任务：结构上游化 · **第 5 轮（收尾长尾）** —— 把"七类路径"在第 ②/⑤ 类的落点深度长尾做干净，冲到 D2

> 起点：**detached HEAD = `e1db565c3`**（在标签 `archive/wave-merge-r3` 之上，`tline-gate` 已转绿）。工作区应干净。
> 先读：`.agents/tasks/TASK-合并波.md`（纪律/落点/登记/D1-D3/回退）＋ `TASK-合并波-R3.md`（上一轮诊断）＋
> `docs.Linux/evidence/STAGE3-SCOPE-REPORT.md`（**七类路径语义**）。

---

## ① 起步

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
git status --short                 # 期望空
git log --oneline -1               # 期望 e1db565c3
git rev-parse --abbrev-ref HEAD    # 期望 HEAD（detached）
bash src/Linux/build/MilBridge/tools/tline-gate.sh | tail -1   # 期望 PASS（不要弄回红）
```

## ② 本轮范围 = **落点深度长尾**（已逐条实测，不是猜的）

### 2.1 `src/Linux/build/port-lib.py`（**最要紧，`OUTROOT` 语义变了**）
实测现存旧布局派生：
```python
OUTROOT = os.path.dirname(HERE)                                  # :29
return os.path.join(OUTROOT, "upstream", "wpf")                  # :37
decl = os.path.join(OUTROOT, "src", "Linux", "build", "SelfBuiltConfig.props")   # :151
want = os.path.join(OUTROOT, "build", proj_name + ".Linux", "bin", cfg, …)       # :164
pat  = os.path.join(OUTROOT, "build", proj_name + ".Linux", "bin", "**", …)      # :168
```
⇒ `src/Linux/build/` 现在**不再是仓根**（深度 2→3），这些 `OUTROOT` 派生**全部指错**（例如 `repo/src/Linux/upstream/wpf` 不存在）。
**逐处改**成新落点：`upstream/wpf` → `<仓根>/src/Microsoft.DotNet.Wpf/`；`build/<proj>.Linux/` → `<仓根>/src/Microsoft.DotNet.Wpf.Linux/src/<proj>/`；
`SelfBuiltConfig.props` → 按新相对位置。**并把 `OUTROOT` 的语义写清**（它到底该是仓根还是 `src/Linux`），别留歧义。

### 2.2 `WpfLinuxRoot` / `UpstreamWpfRoot` 上溯层数
- `src/Linux/build/Directory.Upstream.props`（`:17-18` 等）：`$(WpfLinuxRoot)upstream/wpf/` 与 `WpfLinuxRoot` 的定义/上溯层数要跟着落点加深重算。
- `src/Microsoft.DotNet.Wpf.Linux/src/PresentationBuildTasks/PresentationBuildTasks.Linux.csproj:322` 与同目录 `Directory.Build.props:4-5`：
  `$(MSBuildThisFileDirectory)../../upstream/wpf/` ⇒ 按新深度补 `..`（或统一改指 `<仓根>/src/Microsoft.DotNet.Wpf/`）。
- **全仓同族**：`GetFullPath('$(MSBuildThisFileDirectory)..…','build',…)`、`NormalizeDirectory(…,'..','..'…)`、`os.path.dirname` 链、
  shell 的 `/../../`：凡"自指针"都要按新深度**逐处重算**。判据＝构建真能编、且不再回落到旧路径。

### 2.3 `bin/Debug` 硬编码（"Release 声明 vs 硬编码"的撕裂）
- `src/Linux/build/SelfBuiltConfig.props` 自述"`*.csproj` 的 `<HintPath>` 里 100 处写死 `bin/Debug`"；我实测新落点下 **29 个文件**仍写死。
- 权威值域是 `WpfLinuxSelfBuiltConfiguration`（**现读 `Release`**），shell 侧**唯一读取器**是 `src/Linux/build/selfbuilt-config.sh`。
- ⇒ 把这些写死点改成"**引用唯一来源**"（csproj 用 `$(WpfLinuxSelfBuiltConfiguration)`；shell/python 用 `selfbuilt-config.sh`），
  **不许**逐个改成新的写死值（那还是分叉）。

## ③ 通了之后：走完收口（照 `TASK-合并波.md`）

1. **D1**：`dotnet build src/Linux/wpf-linux.sln`（按自产配置）**0 错**；全部 `dotnet test` **0 失败**；13 颗结构牙 ＋ 8 颗关键牙全绿；
   `bash Guide.Linux/verify-all.sh` 剩余红**逐条具名归因**（只允许"未重冻/臂滞后"这类）。
2. **一笔**提交。
3. **重冻**：冻结块 `# RE-FROZEN`／`# ARM-LOG-SHA` 随五臂重钉、两枚 `bridge-frozen.flag`、`docs/CURRENT-STATE.md:9`、
   仓外 `~/w153a/bin/infp.sh` 的 `CW=`；`docs/ROUTES.md §8` 同步（dated 追加）。
4. **D2**：`bash Guide.Linux/verify-all.sh` **×2** 各 **0 ❌**（步数以现场 `VERIFYALL-STEPS-DECL` 为准）。
5. **前进主线**：`git branch -f feat-Linux <该提交>` 或 `git checkout feat-Linux && git merge --ff-only <提交>`（**只在 D2 达成后**）。
6. **最后**：自证 `docs.Linux/evidence/UPSTREAM-MANIFEST.tsv` == 工作树 ⇒ `git rm -r upstream` ＋ 提交 ＋ 再跑一趟确认不新增红。

## ④ 边界

- 照 `TASK-合并波.md` §④。**新增**：本轮**只许动** §② 点名的"自指针/硬编码"类 ＋ §③ 收口所必需的件；**不得**再改落点、不得重写七类之外的东西。
- **禁止**削弱判据凑绿（改 `--expect`／加豁免／关开关／把 NOINFO 当绿）。
- `tline-gate` 刚转绿：改 `run.sh`/`known-red.json` 一带时要**复核它别回红**。

## ⑤ 硬停条件

§② 每条各试 2～3 种做法仍不能让 D2 的 0 红成立 ⇒ **停手**：
- **不**前进 `feat-Linux`、**不**删 `upstream/`；
- 输出：① `verify-all` 逐趟通过/失败数 ＋ 剩余红逐条具名归因；② 你判定的根因与证据；③ 你推荐的收口方式（含"可否接受一条具名红"的判断）；
- 明确写"**未达 D2**"，并给工作区状态（`git status`、`HEAD`）。
- 回退（若要）：`git reset --hard e1db565c3`。

## ⑥ 报告

- `verify-all` **逐趟**步骤通过/失败数（贴原始行）；九位/`inputs_fp`/基线**前后成对值**。
- §② 每条：改了哪些文件、改前/改后读数。
- `git log --oneline`（本波提交）＋ `git status --short`。
- 结论：**D2 达成** 或 **未达 ＋ 具名残余 ＋ 推荐收口**。
