# FORK-AND-PUSH —— 从 fork 上游到把本仓工作推上 `feat-Linux` 并设为默认分支

> 目标：把**当前这份工作树**（Linux 移植 + 验收体系 + 文档）放进你对 `dotnet/wpf` 的 **fork**，分支名 `feat-Linux`，并把它设为**该 fork 的默认分支**；同时把上游原始 README 保留为 `README-Window.md`，用本仓的 `README.md` 作为门面。
> 规范见 [`PORT-SPEC.md`](PORT-SPEC.md)｜路线见 [`ROUTES.md`](ROUTES.md)。**每一步都给了验证命令**（照本仓习惯：结论要能复算）。

---

## §0 三条先说清的前提（否则会踩坑）

1. **本机没有 `git`**（`command -v git` 为空）。要么 `sudo apt install git`，要么**在另一台机器上执行**本文命令（把工作树拷过去）。**不要**在没有 `git` 的机器上 `git init` 之后再想办法"补历史"。
2. **上游快照的精确 commit 定不出来**：`upstream/wpf/**` 是"非 git 手段"搬入的裁剪快照（无 `.git`、无 `Version.Details.xml`、树内无任何 commit 串）。⇒ 见 [`UPSTREAM-PROVENANCE.md`](UPSTREAM-PROVENANCE.md)：它给了**可复算的完整性指纹**（M1–M4）与"把 commit 钉死"的配方。**本仓的构建读的是 `upstream/wpf/**` 这份 vendored 副本，不是 fork 根目录的 WPF 树** —— 所以分支基点选哪个 commit **不影响本仓能否构建**，只影响"与上游同步"这条路线（`ROUTES.md` §8）。
3. **体积**：工作树排除 `bin/`/`obj/`/`.artifacts/` 后约 **384 MB**（其中 `upstream/wpf` 127 MB、`tests/parity` 216 MB、`build/wic-abi-reference` 72 MB、`tools` 73 MB）。`.gitignore` 已存在（69 行，逐类写清"哪些产物不入库、哪些 `*.log/*.json` 是**证据件**必须入库"）⇒ **先验证它，再 `git add`**。

---

## §1 造 fork 与分支（在 GitHub + 本机）

```bash
# ① 在 GitHub 上把 dotnet/wpf Fork 到你的账号（网页点 Fork 即可）。
# ② 本机克隆你的 fork，并挂上游：
git clone git@github.com:<你的账号>/wpf.git wpf-linux && cd wpf-linux
git remote add upstream https://github.com/dotnet/wpf.git
git fetch upstream --tags

# ③ 从上游主干切出工作分支（名字固定为 feat-Linux）：
git checkout -b feat-Linux upstream/main
git log --oneline -1        # 记下这个基点 commit（写进下面的提交信息里）
```

> 备选（若你希望分支基点 = 本仓快照对应的上游版本）：先按 [`UPSTREAM-PROVENANCE.md`](UPSTREAM-PROVENANCE.md) §7 的配方把 commit 钉出来，再 `git checkout -b feat-Linux <那个 commit>`。**钉不出来就照上面用 `upstream/main`**（并在提交信息里如实写明"基点未钉死"）。

## §2 保住上游 README，再把工作树铺上去

```bash
# ④ 上游 README 先改名（保住它的历史与身份）：
git mv README.md README-Window.md
git commit -m "chore: 保留上游 Windows README 为 README-Window.md（移植版 README 即将接管根 README）"

# ⑤ 把本仓工作树铺进 fork（**不带 bin/obj/.artifacts**）。
#    ⚠️ 不要用 --delete！（fork 根的 WPF 树要留着；本仓构建读的是 upstream/wpf/**）
SRC=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
rsync -a \
  --exclude='bin/' --exclude='obj/' --exclude='.artifacts/' \
  --exclude='**/bin/' --exclude='**/obj/' --exclude='**/.artifacts/' \
  --exclude='__pycache__/' --exclude='*.pyc' \
  --exclude='.git/' \
  "$SRC"/ ./
# 本仓自带的 README-Window.md 与上游那份内容同源（本仓那份多了 5 行说明）
# 二选一：保留上游原版 ⇒ 下面这一行把覆盖还原；或就用本仓那份（含说明头）。
git checkout -- README-Window.md 2>/dev/null || true
```

**验证（推之前必须过）**：

```bash
git status --short | wc -l                       # 看规模，心里有数
git check-ignore -v build/MilBridge/known-red.json docs/CURRENT-STATE.md \
    src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cat
#   ⇒ 期望：前两件**不被忽略**（它们是判据件/基线件），最后一件**被忽略**（构建产物）
du -sh --exclude=bin --exclude=obj --exclude=.artifacts .    # 期望 ≈ 384 MB
find . -type d \( -name bin -o -name obj -o -name .artifacts \) -not -path './.git/*' | wc -l   # 只看数量，不该出现在 git status 里
```

## §3 提交与推送

```bash
# ⑥ 第一笔提交：**只搬不整理**（方便审阅时区分"搬入"与"改造"）
git add -A
git commit -F - <<'MSG'
feat(Linux): 引入 WPF→Linux 源码移植、验收体系与文档（首笔：整树搬入）

- 替换式移植：upstream/wpf/** 只读；build/*.Linux/*.csproj 剔除 Windows-only 源、加入生成的 *.Linux.cs
- 原生面：libwpfwin32.so（win32 shim）、libwpfwic.so（WIC shim）、wpfgfx_cor3.so（AOT milcore 桥）
- 可复算验收：verify-all.sh（25 步）、五臂门禁、冻结基线 ACCEPTANCE-BASELINE.md
- 文档：README.md（移植版）、README-Window.md（上游原文）、docs/PORT-SPEC.md（规范）、docs/ROUTES.md（并行路线）
- 分支基点：<上面 git log 记下的 commit>（本仓 upstream 快照的精确 commit 未钉死，见 docs/UPSTREAM-PROVENANCE.md）

本笔为整树搬入，未做路径/布局整理（见 docs/ROUTES.md §8 的上游化路线）。
MSG

# ⑦ 第二笔：文档与门面整理（把 README/索引 的改动与搬入分开，便于 review）
git add README.md README-Window.md docs/ .gitignore
git commit -m "docs: 移植版 README 接管根 README；新增 PORT-SPEC/ROUTES/INDEX/FORK-AND-PUSH 与文档索引"

# ⑧ 推上去
git push -u origin feat-Linux
```

## §4 设为 fork 的默认分支

**方式 A（网页）**：你的 fork → `Settings` → `General` → `Default branch` → 切到 `feat-Linux` → `Update`。
**方式 B（`gh` CLI）**：

```bash
gh repo edit <你的账号>/wpf --default-branch feat-Linux
gh repo view <你的账号>/wpf --json defaultBranchRef -q .defaultBranchRef.name   # 验证
```

> ⚠️ 切默认分支**不影响** fork 与上游的关系：`upstream/main` 随时可 `git fetch upstream` 同步；将来要向上游提 PR 时，从 `feat-Linux` 切一个聚焦分支即可。

## §5 并行协作怎么发（给"网友一起做"用的约定）

1. **一条路线一个分支**：`feat/linux-r1-window`、`feat/linux-r3-text`、`feat/linux-r7-gates`…… 路线定义见 [`ROUTES.md`](ROUTES.md)。
2. **每个 PR 必须带**：`docs/WAVE<NN>-PREREGISTRATION.md`（或路线报告的预登记节）**判据 + 反极性**、`build/MilBridge/<车道号>-report.md`（自报 sha16 + 开工/收工件 sha16 + 复算命令 + 边界/`NOINFO` + "推翻了哪句话"）。
3. **CI 建议（最小集）**：`bash build/MilBridge/tools/{defect-registry-check.sh,shell-quote-trap-check.sh,pipefail-sigpipe-check.sh,fp-inputs-hygiene-check.sh}`＋`bash build/MilBridge/tools/baseline-sha-check.sh` —— 都是纯读、零 `dotnet`、秒级，适合每个 PR 跑。
4. **契约**：改判据必须让某处**变红**（"改它没人管"= 判据不可信）；动九位必须走整波（`PORT-SPEC` §5）。

## §6 之后要还的三笔账（如实登记，别当没看见）

1. **布局重复**：fork 根有 WPF 自己的树，而本仓又把上游快照 vendored 在 `upstream/wpf/**`（127 MB 重复）⇒ 路线 R8 要决定"上游化"（去掉 vendored 副本、把 `upstream/wpf/...` 路径重写成根相对）。
2. **上游 commit 未钉死**：`UPSTREAM-PROVENANCE.md` 给了配方；钉死之后要重算 M1–M4 并写进文档。
3. **大语料**：`tests/parity`（216 MB）与 `build/wic-abi-reference`（72 MB）是否改走 Git LFS / 外部下载 ⇒ 路线 R8 裁定。

---

## §7 【实战补记 · 2026-09-20 首次推送时踩到】**换行归一化会把"字节可复算"打穿**

首次 `git add` 时 git 打了一屏 `warning: … 中的 CRLF 将被 LF 替换` —— 根因是**上游 WPF 自带的
`.gitattributes`（`* text=auto` 一族）**：它会**在入库时**把 CRLF 归一化成 LF（`text=auto` 与
`core.autocrlf` 无关，`autocrlf=false` 也照样归一化）⇒ **库内的 blob ≠ 我们磁盘上的字节**
⇒ 本仓所有以**字节**为口径的判据（冻结基线逐件 sha16、五臂日志、语料指纹、`UPSTREAM-PROVENANCE.md` 的 M1–M4）
在贡献者机器上会**系统性对不上**。实测：`…/Themes/…/Aero.NormalColor.xaml` 磁盘 `ba5aac98cde01dfd` vs 库内 `1cc961578f705428`。

**处置（本仓已落地，别人照做即可）**：

1. **配置层关掉**（你的建议）：
   ```bash
   git config core.autocrlf false          # 局部
   git config --global core.autocrlf false # 全局
   git config --global core.safecrlf false
   ```
   ⚠️ 但**光靠配置不够** —— `text=auto` 写在 `.gitattributes` 里，属性优先于配置。
2. **属性层关掉**（本仓已提交这两份）：仓库根 `.gitattributes` 与 `upstream/wpf/.gitattributes` 都设为
   `* -text`。⚠️ git 的属性**深层文件胜出** ⇒ 只改根不够，vendored 那一层必须一起改
   （这是本仓对上游快照的**唯一一处刻意偏差**，已登记在 `UPSTREAM-PROVENANCE.md` §3 顶部 + §9 附录存了上游原文）。
3. **首次入库必须强制重建索引**（**最容易踩的一脚**）：`git rm -r --cached .` 会因为
   "暂存内容与工作区及 HEAD 都不同"而**拒绝**（要 `-f`）；若只是 `git add -A`，git 看到 stat(mtime/size) 没变
   **会跳过重新哈希** ⇒ **旧（被归一化的）blob 留在索引里**，你以为改好了其实没改。
   ```bash
   git rm -r --cached -f -q .     # -f 必需；只清索引，不动工作树
   git add -A                     # 按新属性重新入库
   ```
4. **验证（必须过，否则别推）**：
   ```bash
   git diff --numstat | wc -l     # 期望 0：索引与工作树字节一致
   for f in $(git ls-files | shuf -n 30); do
     a=$(sha256sum "$f" | cut -d' ' -f1); b=$(git cat-file blob ":0:$f" | sha256sum | cut -d' ' -f1)
     [ "$a" = "$b" ] || echo "字节差异: $f"
   done                            # 期望 0 行
   ```
5. 顺带：`find . -type f -size +100M` 必须为空（GitHub 拒收 >100 MB 单文件）。本仓两个大件**都已**被
   `.gitignore` 排掉、各有理由：`…/u14/linux-results-u14.json`（118 MB，探针输出、可重算 ）、
   `…/layout-b34/windows-results.json`（53 MB，Windows 侧 dump；现所有读者都走仓内派生件
   `build/MilBridge/gen/layout-b34-compact.json`）。
   （**更正**：本条早期版本误写「它必须入库」，与 `.gitignore:51` 的既有规则冲突，已改。）
