# W70C 报告 —— `TASK-0802`：把工作树的**文档改动**提交并推到 fork 的 `feat-Linux`

> 车道 W70C ｜ 工件：fork `git@github.com:isharrrry/WPFOnLinux.git` 的 `feat-Linux` 分支
> 提交 `a0e783db4208b8b0e572784065b66e46362bbf06`（sha16 `a0e783db4208b8b0`）
> 前置阅读：`docs/FORK-AND-PUSH.md` §6（三笔账）＋ §7（**CRLF 教训**）
> ⚠️ 本件**未跑任何 `dotnet`**、未起应用、未 `pkill`、未 `--force`、未动默认分支设置。

---

## ② 改动前读数（`origin/feat-Linux` head，**改动前**）

```bash
$ cd ~/netTest/GitProj/WPFOnLinux
$ git fetch origin && git log --oneline -3
ce88f44 docs: 钉死上游基点 commit 1cfc37f（#11837）+ 记三笔账的处理口径
171dcdf docs: 更正两处口径 —— 两个大件**都**已被 .gitignore 排掉（各有理由与复算方式）
20ebd60 docs(FORK-AND-PUSH): 补 §7 —— 换行归一化会把「字节可复算」打穿（实测 + 四步处置）
$ git status --short          # 空 ⇒ 工作树干净
$ git ls-remote --symref origin HEAD
ref: refs/heads/feat-Linux	HEAD
ce88f44bc63de08263782abd69beb5cf6c5bc546	HEAD
$ git ls-remote origin refs/heads/feat-Linux
ce88f44bc63de08263782abd69beb5cf6c5bc546	refs/heads/feat-Linux
```

| 项 | 值 |
|---|---|
| **改动前 `origin/feat-Linux` head** | **`ce88f44bc63de08263782abd69beb5cf6c5bc546`**（sha16 `ce88f44bc63de082`） |
| 改动前本地 `HEAD` | 同上（本地 `feat-Linux` 与远端同点，工作树干净） |
| 改动前远端默认分支 | `ref: refs/heads/feat-Linux` ✅（`ls-remote --symref origin HEAD`） |

> **一处本地状态说明（如实记）**：本克隆的 fetch refspec **只有** `+refs/heads/main:refs/remotes/origin/main`
> ⇒ **本地不存在** `origin/feat-Linux` 跟踪 ref，所以改动前的 head 只能由 `git ls-remote` 读
> （`git rev-parse origin/feat-Linux` 当时报 `有歧义的参数 'origin/feat-Linux'`）。
> 推送后我用 `git fetch origin '+refs/heads/feat-Linux:refs/remotes/origin/feat-Linux'` **建立了这条本地跟踪 ref**
> （**只写本地 `refs/remotes/`，不改远端、不改默认分支**），此后 `git rev-parse origin/feat-Linux` 可用。

---

## ③ 同步清单 ＋ **远端 blob == 磁盘** 核对表（11 件，全 `.md`）

**同步口径**：只取 `$R` 里**已改过且属文档/规范类**的件。逐径 `cp -p`，**未用 `rsync --delete`、未用 `git add -A`**，
`git add` 逐类列名 ⇒ `git status --short` 恰好 11 行（6 改 5 增），**无任何多带**。

| # | 路径 | 类别 | R 磁盘 sha16 | **远端 blob sha16** | 相等 |
|---|---|---|---|---|---|
| 1 | `README.md` | 改 | `456d8b86e0ffb179` | `456d8b86e0ffb179` | ✅ |
| 2 | `docs/ROUTES.md` | 改（§12 TASK 编号与标记规范、§13 任务树） | `9d03152db37fff4a` | `9d03152db37fff4a` | ✅ |
| 3 | `docs/WAVE49-PREREGISTRATION.md` | 改 | `e6460d6204e2a17f` | `e6460d6204e2a17f` | ✅ |
| 4 | `docs/unimplemented.md` | 改 | `66abdab7fc342cab` | `66abdab7fc342cab` | ✅ |
| 5 | `build/DirectWrite.Linux/wic-shim/known-red-PFWB-copies.md` | 改（#49 主控处置） | `8ee55c8f01e41eb9` | `8ee55c8f01e41eb9` | ✅ |
| 6 | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | 改（`D-G62`…`D-G74`） | `c5670b7e177d092e` | `c5670b7e177d092e` | ✅ |
| 7 | `build/MilBridge/W58A-report.md` | **新** | `78ad9a9d7b5ad5ff` | `78ad9a9d7b5ad5ff` | ✅ |
| 8 | `build/MilBridge/W59A-report.md` | **新** | `0ca468561b0b1561` | `0ca468561b0b1561` | ✅ |
| 9 | `build/MilBridge/W60A-report.md` | **新** | `f7d94d1481db3d1d` | `f7d94d1481db3d1d` | ✅ |
| 10 | `build/MilBridge/W61A-report.md` | **新** | `79880bd4b6414648` | `79880bd4b6414648` | ✅ |
| 11 | `build/MilBridge/W62A-report.md` | **新** | `731b6846c08fe5ac` | `731b6846c08fe5ac` | ✅ |

**"远端 blob"这一栏是严格口径**（按主控 W70C 的更正改写）：读的不是 `git show HEAD:<path>`（那是**本地提交**），
而是**推送后从 GitHub 取回的对象** `origin/feat-Linux:<path>`：

```bash
# 远端一致性（严格；本表实际用的就是这一组命令）
cd ~/netTest/GitProj/WPFOnLinux
git fetch origin '+refs/heads/feat-Linux:refs/remotes/origin/feat-Linux'
for f in README.md docs/ROUTES.md docs/WAVE49-PREREGISTRATION.md docs/unimplemented.md \
         build/DirectWrite.Linux/wic-shim/known-red-PFWB-copies.md \
         samples/WpfFeatureProbe/KNOWN-DEFECTS.md \
         build/MilBridge/W{58A,59A,60A,61A,62A}-report.md; do
  a=$(sha256sum /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/"$f" | cut -c1-16)
  b=$(git cat-file blob "origin/feat-Linux:$f" | sha256sum | cut -c1-16)   # ← 远端对象
  [ "$a" = "$b" ] && echo "OK  $f" || echo "**DIFF** $f"
done
```

读数：**11/11 `OK`，`fail=0`**。另附**提交内 blob 的树内读数**（`git ls-tree -r origin/feat-Linux`）：

```
100644 83d71e0e3c9e README.md
100644 80164a904db2 build/DirectWrite.Linux/wic-shim/known-red-PFWB-copies.md
100644 f2de3589df19 build/MilBridge/W58A-report.md
100644 2a52bc6259ff build/MilBridge/W59A-report.md
100644 d8ec24502c9d build/MilBridge/W60A-report.md
100644 fdc870e29a98 build/MilBridge/W61A-report.md
100644 db9577905807 build/MilBridge/W62A-report.md
100644 6a112921e332 docs/ROUTES.md
100644 41f1e378e9ab docs/WAVE49-PREREGISTRATION.md
100644 a5cd1ccae78c docs/unimplemented.md
100644 e4882a9cf7c5 samples/WpfFeatureProbe/KNOWN-DEFECTS.md
```

（`git show HEAD:<path>` 那一遍在**推送前**也做过，11/11 相等 —— 但它只证"**本地提交内容 == 磁盘字节**"，
**不**证远端；两栏都已给出，不要混用。）

### §7 CRLF 教训：本笔的换行读数（**必须过**）

| 检查 | 命令 | 读数 |
|---|---|---|
| 属性层未被归一化 | `git check-attr text eol -- <11 件>` | 全部 `text: unset`（= `* -text`，根 `.gitattributes` 生效；`upstream/wpf/.gitattributes` 不覆盖这些路径） |
| 配置层 | `git config core.autocrlf` / `core.safecrlf` | `false` / `false`（全局亦 `false`） |
| 入库告警 | `git add <11 件>` 的 stderr | **空**（无一条 `CRLF 将被 LF 替换`） |
| 实际行尾 | `grep -c $'\r'` 逐件 | **11 件全 `CR=0`**（纯 LF，本次同步面本就不含 CRLF 件） |
| 索引 == 工作树 | `git diff --numstat \| wc -l` | **0** |

---

## ④ 提交与推送

**提交信息（中文一句说清"同步了哪些 + 为什么"，正文含"刻意未同步"一节）**：

```
docs: 同步波 #49 期间的文档改动（路线/预登记/缺陷登记 + 5 份车道报告）
（正文：为什么 / 7 条同步清单 / ⚠️ 刻意未同步的 5 类 / 字节口径）
```

| 字段 | 值 |
|---|---|
| **新提交** | **`a0e783db4208b8b0e572784065b66e46362bbf06`**（sha16 `a0e783db4208b8b0`） |
| 父提交 | `ce88f44bc63de08263782abd69beb5cf6c5bc546`（= 改动前远端 head，**快进**，无人被覆盖） |
| tree | `1b7f8e38dbd1412feffd6ee668231b652e1bd896` |
| 改动量 | `11 files changed, 2079 insertions(+), 17 deletions(-)`（5 件 `create mode 100644`） |
| 作者 | `None <harrrry@foxmail.com>` ← `user.name` 未设，**与既往 5 笔提交逐字一致**（非本笔引入，信息性） |

```bash
$ git push origin feat-Linux
To github.com:isharrrry/WPFOnLinux.git
   ce88f44..a0e783d  feat-Linux -> feat-Linux
[push exit=0]
$ git push origin feat-Linux          # 复核再跑一次
Everything up-to-date
[push exit=0]
```

> **关于"主控先看到远端仍是 `ce88f44`"**：主控那次 `ls-remote` 读数**取自本件 push 落地之前**（竞态）。
> 现在同一命令的读数是 `a0e783db…`（见下 §⑤），且二次 `push` 返回 `Everything up-to-date` ⇒ **推送确已落地**。

---

## ⑤ 推送后远端复核读数

```bash
$ git ls-remote --symref origin HEAD
ref: refs/heads/feat-Linux	HEAD                                  ← 默认分支仍是 feat-Linux ✅
a0e783db4208b8b0e572784065b66e46362bbf06	HEAD                  ← 新 head ✅
$ git ls-remote origin refs/heads/feat-Linux
a0e783db4208b8b0e572784065b66e46362bbf06	refs/heads/feat-Linux
$ git fetch origin '+refs/heads/feat-Linux:refs/remotes/origin/feat-Linux'
 * [新分支]          feat-Linux -> origin/feat-Linux
$ git rev-parse origin/feat-Linux
a0e783db4208b8b0e572784065b66e46362bbf06
$ git rev-parse HEAD
a0e783db4208b8b0e572784065b66e46362bbf06                  ← 本地 == 远端 ✅
$ git status -sb
## feat-Linux                                              ← 不领先、不落后（0/0）
```

| 项 | 新旧对照 |
|---|---|
| **远端 `feat-Linux` head** | 旧 `ce88f44bc63de08263782abd69beb5cf6c5bc546` → **新 `a0e783db4208b8b0e572784065b66e46362bbf06`** |
| **远端默认分支（`symref HEAD`）** | `refs/heads/feat-Linux`（**新旧一致，未被改动**） |
| 本地 `HEAD` == 远端 head | ✅ 逐位相同 |
| 落后 / 领先 | `0 / 0` |

---

## ⑥ 任务项 5：`README.md` 的上游 pin 与「构建只读 `upstream/wpf/**`」

**结论：两句原本就在位 ⇒ 本件无需补写。** 读的是**远端**版本（`git show origin/feat-Linux:README.md`）：

```
:210  4. **上游快照的出处** ✅ 已钉死：`upstream/wpf/` = `dotnet/wpf` 的裁剪快照，
      **基点 commit = `1cfc37f708f91ff4556bd25af414546c446f3a16`**
:183  | `upstream/wpf/` | 上游 `dotnet/wpf` 快照（**只读**；基点 commit `1cfc37f708f9`）。⚠️ **账一**…
      **本仓构建只读 `upstream/wpf/**`，根目录那份不使用**（`.csproj` 与应用器锚点都按 `upstream/wpf/...` 写死）。
```

**task 里点名的"31 页只有 23/24 会崩"那行**（`README.md:26`）也已在位，逐字：

```
| ⑥ | **切「富文本」/「流文档」页必崩**（`EntryPointNotFoundException: CreateInstalledObjectsInfo` …
   | ⛔ **本波不修**：这是 **PTS/LineServices 未实现**（那 **111 条 `Fs*`/`Lo*` 缺口**）⇒ 属路线 R3
   ⇒ 逐页实测（车道 W60A 报告 `0dfd49ab332c317d` §4，31 页全表）：**只有第 23 项「富文本框」与
   第 24 项「流文档」会崩**（各复现 3/3、2/2，均 `rc=134`），其余 **29 页 `alive=yes`、`unh=0`、帧差 >0**
```

`docs/ROUTES.md` 远端复核：`:108 ## §12 TASK 编号与标记规范`、`:161 ## §13 当前任务树` ✅ 在位。

---

## ⑦ `NOINFO` 清单（做不到的，逐条给确切原因）

| # | 项 | 状态 | 确切原因 |
|---|---|---|---|
| 1 | **源码/门禁数据同步** | **NOINFO（未做，非失败）** | task 明确"只同步文档/规范，不要把源码树、构建产物带进去"。故下面这 12 件**已改但未同步**（见 §⑧ 台账）⇒ **fork 的源码仍是旧快照**：文档里标 `已修` 的若干条（`D-G64`/`D-G65`/`D-G66`/`#49` 配置分叉等）**其源码修复不在本分支上**。这不是本件能解决的，须整波同步 |
| 2 | **fork 侧门禁读数**（`verify-all.sh` / `defect-registry-check.sh` …） | **NOINFO** | ① 本件任务不要求跑；② 即使跑，fork 上的 `build/MilBridge/tools/defect-registry-declared.tsv`（`8efdd2131b3b9110` vs 远端 `e9220043d619adf1`）与 `docs/unimplemented.md` 是**两个不同波次**的版本 ⇒ 读出来的红/绿**不对应工作树的声明集**，属"不可信的绿/红"，按 `PORT-SPEC` 的口径宁可不取 |
| 3 | **"远端一致性"在推送前就断言** | **已修正** | 主控指出的口径问题：`git show HEAD:<path>` 读本地提交，**不能**用来断言远端。本报告 §③ 的"远端 blob"栏已改用推送后 fetch 回来的 `origin/feat-Linux:<path>`；推送前那遍仅主张"本地 == 磁盘"。 |
| 4 | **`git rev-parse origin/feat-Linux`（改动前/推送前）** | **当次不可取** | 本地 fetch refspec 只映射 `refs/heads/main` ⇒ 该跟踪 ref 不存在（报错原文：`fatal: 有歧义的参数 'origin/feat-Linux'：未知的版本或路径不存在于工作区中`）。已按 §② 说明建立 ref 后取得，**非**远端故障 |
| 5 | **本报告自身的提交** | **未提交（刻意）** | 本文件在 sync 提交 `a0e783d` **之后**才生成 ⇒ 不在那笔提交里。若主控要它入库，须再走一次同步（本件未获授权自推） |
| 6 | `samples/**/bin|obj`、`.xwd`、大 JSON 语料、构建产物 | **未带入（正面合规）** | 按 task 与 `.gitignore`/`FORK-AND-PUSH` §7.5；`git status` 也印证未混入 |

---

## ⑧ 附：已改但**刻意未同步**的件（给下一波用，非本件交付）

sha16：`R 磁盘` vs `远端 blob`（**同族全部不等** ⇒ 源码面确实落后工作树）：

| 路径 | R 磁盘 | 远端 blob |
|---|---|---|
| `verify-all.sh` | `12bce6872327e8e9` | `5ee3ad984ee7412d` |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `8efdd2131b3b9110` | `e9220043d619adf1` |
| `build/third-party/WpfLinux.props` | `bdc3954b4a129112` | `46cb80dc5ae8b1ed` |
| `src/WpfGfx.Linux.Native/src/win32_core.c` | `529d999e4818568d` | `e1edbd04113c9125` |
| `src/WpfGfx.Linux.Native/src/win32_internal.h` | `fd5d220931bebf8d` | `472e6560024f758c` |
| `src/WpfGfx.Linux.Native/src/win32_x11.c` | `050f349638bbf87e` | `e3e1b3e10c88f6fe` |
| `src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs` | `62203635d795f832` | `748f781620ea4008` |
| `src/WpfGfx.Linux/Commands/MilCommandLayout.cs` | `d13821c359c30db9` | `4f4f3f8fc3495c16` |
| `src/WpfGfx.Linux/Resources/MilChannel.cs` | `4a79d7437fd428ba` | `384d024ab7987dfa` |
| `tests/WpfGfx.Linux.Tests/Commands.Tests/CommandCoverageTests.cs` | `50559c6143d61c22` | `7cd7e1baf5e5529c` |
| `tests/WpfGfx.Linux.Tests/Commands.Tests/CommandRoundTripTests.cs` | `be06c15e66600833` | `99dfdf889fc818f0` |
| `tests/WpfGfx.Linux.Tests/Commands.Tests/GoldenBinaryReplayTests.cs` | `39c3a7b45dbadd3d` | `0275f10e0f5c0ca2` |

发现方式（可复算，**零 `dotnet`**）：`rsync -rcn -i`（排除 `upstream/`、`bin/obj/.artifacts`、`__pycache__`、
`tests/parity/`、`build/wic-abi-reference/`、`*.so`、`*.xwd`）⇒ 差异 21 行，其中 **doc 类 11 件（本次已同步）**、
**代码/门禁类 12 件（§⑧，未同步）**，无第三类。

**纪律复核**：全程无 `git push --force`（reflog 只有 `commit:` 记录，见下）；未改远端默认分支设置（只读它）；
未 `git add -A`；未 `pkill -f`；未跑 `dotnet`；**未在 `$R` 里 `git init`**（`ls -d $R/.git` ⇒ 不存在）。

```
$ git reflog show feat-Linux | head -3
a0e783d feat-Linux@{0}: commit: docs: 同步波 #49 期间的文档改动（路线/预登记/缺陷登记 + 5 份车道报告）
ce88f44 feat-Linux@{1}: commit: docs: 钉死上游基点 commit 1cfc37f（#11837）+ 记三笔账的处理口径
171dcdf feat-Linux@{2}: commit: docs: 更正两处口径 —— 两个大件**都**已被 .gitignore 排掉（各有理由与复算方式）
```

---

## 大白话小结（≤6 行）

1. 远端旧头 `ce88f44`，现在新头 **`a0e783d`** —— 首推就成功了（`ce88f44..a0e783d`），主控看到旧头是**推送前的竞态读数**，再推一次是 `Everything up-to-date`。
2. 一共推了 **11 件、全是 `.md`**：README、ROUTES（新增 §12/§13）、WAVE49 预登记、unimplemented、known-red-PFWB、KNOWN-DEFECTS ＋ 5 份车道报告（W58A…W62A）。
3. 字节核对**全过 11/11**，而且按主控更正的口径改成了**严格远端核对**：`git cat-file blob origin/feat-Linux:<path>` == 磁盘 sha256；推送前那遍只算"本地==磁盘"。
4. 默认分支**仍是 `feat-Linux`**（`ls-remote --symref origin HEAD` 直读），没碰它；没有 `--force`，父提交就是旧头 ⇒ 纯快进、不覆盖任何人。
5. README 里的上游 pin（`1cfc37f708f9…`）和「构建只读 `upstream/wpf/**`」**本来就在位**，还有"31 页只有 23/24 会崩"那行也在 ⇒ **不必补写**。
6. 唯一要记住的缺口：**源码/门禁数据这 12 件没推**（task 只要文档）⇒ 文档写着"已修"的几条，其修复**还不在这个分支上**，得等整波同步。

**报告自身 sha16**：`a495713e4ee32d92`
口径（自指行的复算方式）：本值取自定义本行**之前**的版本（`wc -l` = 247）。复算 = 把本行末那 16 位十六进制串替换回占位串
`（见收尾消息；本行之后无法自指）` 后 `sha256sum build/MilBridge/W70C-report.md | cut -c1-16`；填值后文件摘要自然另计
（收尾消息里两个值都给）。
