# FORK-AND-PUSH —— 从 fork 上游到把本仓工作推上 `feat-Linux` 并设为默认分支

> **状态：已办（2026-09-20 首发；此后每波增量推送）** —— fork、分支、默认分支三件都已落地（现场读数见 §0 表）：`origin = git@github.com:isharrrry/WPFOnLinux.git`、分支 `feat-Linux`、**它已是该 fork 的默认分支**（`git ls-remote --symref origin HEAD` ⇒ `ref: refs/heads/feat-Linux`）。上游 README 已保留为 `README-Window.md`，本仓 `README.md` 是门面。
> ⏪ **远端说明（2026-09-25 主控补注）**：本件正文里的 `git@github.com:<你的账号>/wpf.git` 是**当初的通用写法**（占位账号）；**当前推送远端已改为镜像 `git@gitee.com:the50w/WPFOnLinux.git`**（用户为提升国内推送速度改的），`upstream` 仍指 `https://github.com/dotnet/wpf.git`。⇒ **判据不变**：快进与核字节一律用 `git ls-remote origin feat-Linux` ＋ `HEAD:` 逐件 blob 比对，**与具体远端无关**。
> **本件现在的用途**：① §3.1 记录**现行"每波怎么推"**（这才是每天要用的部分）；② §1／§2／§4 保留**首发当时的完整命令**（历史原文，供别人重建一份 fork 时照做）；③ §6 三笔待还账。
> **现读入口**（以现场为准）：`docs/CURRENT-STATE.md:9`（世代＋冻结）｜`build/MilBridge/HANDOFF-NEXT.md`（现场交接）｜[`ROUTES.md`](ROUTES.md) §13（任务树）。
> 规范见 [`PORT-SPEC.md`](PORT-SPEC.md)。**每一步都给了验证命令**（照本仓习惯：结论要能复算）。

---

## §0 三条先说清的前提（否则会踩坑）

1. ~~**本机没有 `git`**（`command -v git` 为空）~~ —— **已过时（2026-09-20 首发之前就已装好）**：现场 `command -v git` = `/usr/bin/git`、`git version 2.34.1`。推送面固定为 clone `~/netTest/GitProj/WPFOnLinux`（**`$R` 本身不是 git 仓**，也不要把它变成 git 仓：本仓的字节可复算体系依赖"工作树就是工作树"）。
2. **上游快照的精确 commit 定不出来**：`upstream/wpf/**` 是"非 git 手段"搬入的裁剪快照（无 `.git`、无 `Version.Details.xml`、树内无任何 commit 串）。⇒ 见 [`UPSTREAM-PROVENANCE.md`](UPSTREAM-PROVENANCE.md)：它给了**可复算的完整性指纹**（M1–M4）与"把 commit 钉死"的配方。**本仓的构建读的是 `upstream/wpf/**` 这份 vendored 副本，不是 fork 根目录的 WPF 树** —— 所以分支基点选哪个 commit **不影响本仓能否构建**，只影响"与上游同步"这条路线（`ROUTES.md` §8）。
3. **体积**：工作树排除 `bin/`/`obj/`/`.artifacts/` 后 **421 MB**（现读 `du -sh --exclude=bin --exclude=obj --exclude=.artifacts .`；分件：`upstream/wpf` 127 MB、`tests/parity` 216 MB、`build/wic-abi-reference` 72 MB、`tools` 73 MB）。⚠️ 首发时是 384 MB，此后随语料增长 ⇒ **这个数每次都要现量，不许引用**。`.gitignore` 已存在（逐类写清"哪些产物不入库、哪些 `*.log/*.json` 是**证据件**必须入库"）⇒ **先验证它，再 `git add`**。

---

## §1 造 fork 与分支（**首发当时已办；本节保留原文，供别人从零重建**）

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
- 可复算验收：verify-all.sh（首发时 25 步；**现读 33 步**，`#59` 收官起 —— 步数**以 `verify-all.sh` 首行 `VERIFYALL-STEPS-DECL` 为准**，不许在任何文档里写死）、五臂门禁、冻结基线 ACCEPTANCE-BASELINE.md
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

## §3.1 现行「每波增量推送」流程（**`#34` 世代起一直在用；照抄这七步**）

> 前提：`$R` 不是 git 仓 ⇒ 全部操作在 clone `~/netTest/GitProj/WPFOnLinux` 里做，货源是 `$R`。

1. **逐径 `git add`（白名单制；⚠️ 绝不从 `git status` 生成清单）** —— 一次收尾链的典型白名单 = `verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/known-red.json`／本波新增或改动的 `build/MilBridge/tools/*`／本波车道报告 `build/MilBridge/<车道号>-report.md`／`build/wave-audit.log`／`docs/WAVE<NN>-PREREGISTRATION.md`／`docs/CURRENT-STATE.md`／`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`。
2. **逐件内容审计**：`$R` vs clone 的**受检被跟踪件**，逐个比 `HEAD:` 的 blob。生成物（`build/*.Linux/SR.g.cs`、`tests/parity/linux/**`、`tests/artifacts/**`）**逐字节相同** ⇒ 由它反证"**零产品改动在源级**"。不在白名单却内容不同的件（例如主控的 `defect-registry-declared.tsv`）**不推**，并点名。
3. **快进判据用远程实况**：`git ls-remote origin feat-Linux` —— ⚠️ **不用**陈旧的跟踪引用 `origin/feat-Linux`（它可能停在几天前）。remote == local ⇒ 快进；不等 ⇒ **停手上报**。
4. `git push`（`<旧>..<新>`），然后用 **`HEAD:`**（**不是** `origin/`）逐件核字节：`BYTECHECK ok=<N> mismatch=0`；`commit 变更件数 == 白名单件数`。
5. **app-local 同代**：`bash build/MilBridge/tools/sync-applocal.sh <目标目录>` ＋ `check-applocal-sync.sh` 读 `APPSYNC=…`（合格线：`STALE=0` ∧ `DIVERGENT=0`；`UNEXPECTED=[DECL-GAP-EQ=n]` 若与上一代**形态逐字相同** ⇒ 继承、非本波引入，**点名不追**）。
6. **两处哨兵**（`/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag`）：把 close-wave 写下的**九位**逐位复核（`9/9`），并**手工补** `BASELINE=#<NN> sha16=<…> bytes=<…>`；两处 `cmp` 必须 **IDENTICAL**。
7. **记录**：`~/w21-verify/w<NN>-record.txt` 三段（`===BANNER===`／`===FROZEN===`／`===RECORD===`）。⚠️ **模板先建、再冻结** —— 冻结机器只在 `# RE-FROZEN` 块里找外挂声明行；**缺声明 ⇒ `COLUMN_FLOOR=NOINFO`（缺声明 ≠ 通过）**（`#57` 就为此停过一次）。

## §4 设为 fork 的默认分支（**已办**；本节保留原文）

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
3. **CI 建议（最小集）**：`bash build/MilBridge/tools/{verify-all-step-check.sh,defect-registry-check.sh,shell-quote-trap-check.sh,pipefail-sigpipe-check.sh,fp-inputs-hygiene-check.sh,prereg-four-requirements-check.sh,baseline-sha-check.sh,arm-log-sha-check.sh}` ＋ `bash build/MilBridge/tools/proc-pattern-guard.sh --repo=.`（`TASK-0714` 的牙，`#62` 起）—— 都是**纯读、零 `dotnet`、无 `X`、秒级**，适合每个 PR 跑。
   ⚠️ 注意：**本仓的内部门禁不是这些**，而是 `bash verify-all.sh`（**33 步**，`#59` 收官起）。
4. **契约**：改判据必须让某处**变红**（"改它没人管"= 判据不可信）；动九位必须走整波（`PORT-SPEC` §5）。

## §6 三笔账（**现读状态**：三笔**都还在**；如实登记，别当没看见）

1. **布局重复**：fork 根有 WPF 自己的树，而本仓又把上游快照 vendored 在 `upstream/wpf/**`（127 MB 重复）⇒ 路线 R8 要决定"上游化"（去掉 vendored 副本、把 `upstream/wpf/...` 路径重写成根相对）。
2. **上游 commit 未钉死**：`UPSTREAM-PROVENANCE.md` 给了配方；钉死之后要重算 M1–M4 并写进文档。
3. **大语料**：`tests/parity`（216 MB）与 `build/wic-abi-reference`（72 MB）是否改走 Git LFS / 外部下载 ⇒ 路线 R8 裁定。

**现读（2026-09-24）**：① 布局重复 = 仍在（`upstream/wpf` 127 MB 与 fork 根树并存），路线 `ROUTES.md` §8／§13 `08xx` **未开工**；② 上游 commit **仍未钉死**（`UPSTREAM-PROVENANCE.md` 的 M1–M4 与配方仍有效）；③ 大语料（`tests/parity` 216 MB ＋ `build/wic-abi-reference` 72 MB）**仍直接入库**，LFS/外链未裁定。三笔都**不是**"忘了"，是**排在上游化路线之后**。

---

## §7 【实战补记 · 2026-09-20 首次推送时踩到】**换行归一化会把"字节可复算"打穿**
> **时效**：本节记的是**首发那一趟**的现场（2026-09-20），**修法与验证至今有效**（现场复核：根与 `upstream/wpf/` 两处 `.gitattributes` 都是本仓自有件、`* -text`；`git diff --numstat` 期望 0）。**别把日期当成"已过时"** —— 它是这套字节判据能成立的**前提条件**。

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
