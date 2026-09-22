#!/usr/bin/env bash
# build-hygiene-import-check.sh —— `D-R8` 的回归牙（**纯读、零 `dotnet`、零世代成本、零产品件**）
#
# 【它防什么】仓根 `BuildHygiene.props` 是**全仓唯一一份**"排除产物目录"的实现，由**每一份**应有的
#   csproj 用**一行**显式 `<Import>` 引入。一旦某一行掉了 ⇒ 用命令行把中间目录指到仓外
#   （各车道常用的"私有 obj"手法）时，**工程目录下的陈旧 `obj/**/*.AssemblyInfo.cs` 会被默认 glob
#   收进编译** ⇒ 与 SDK 本趟新生成的那份撞成 `CS0579`（`#20` 实测单趟 **16 个 `CS0579`**；
#   `#21` W21B 用"仓根 props + 逐工程一行 Import"修好）。
#   ⇒ **而今天没有任何东西会红**（W27C 实测：`grep -rn --include='*.sh' --include='*.py' -- 'BuildHygiene' .`
#     = **0 命中**；仓内只有文档与 csproj 自己提到它）。本脚本就是补这一颗牙。
#
# 【判据（四档；**绝不把"算不出来"当绿**）】
#   ① **名单可用**：名单存在、非空、且长度 == 本文件声明的 `EXPECT_N`  —— 不满足 ⇒ `NOINFO`
#   ② **实现件在**：`$ROOT/BuildHygiene.props` 存在，**且仍带着** `obj/**;bin/**` —— 不满足 ⇒ `FAIL`
#   ③ **正向**：名单里**每一份** csproj 都存在、且**恰好 1 行**规范 `<Import>` —— 否则 ⇒ `FAIL`
#      （0 行 = `DISAPPEARED`；>1 行 = `DUP`；文件没了 = `FILE-ABSENT`。三者**分开计数**）
#   ④ **反向**：全树（**排除 `obj/` `bin/` `upstream/` `.artifacts/`**）里带规范 `<Import>` 的 csproj
#      **必须都在名单里** —— 有任何一个不在 ⇒ `FAIL`（"偷偷多一个用户"同样要红）
#   ⇒ 四档全过才 `PASS`。
#   ⑤ **声明册齐全**（`#27` W28F 补 · **`D-G21` 的牙**）：全树候选 csproj（排除产物目录）**每一份**
#      **必须恰好落在 `build/MilBridge/tools/build-hygiene-roster.tsv` 的一节里**
#      （`wired` / `notneeded` / `suspended`）—— **一份没表态 ⇒ `FAIL kind=UNDECLARED`**。
#      ⚠️ 老判据**看不见**这一档：`unlisted` 只在"已经带了规范 `<Import>`"时才可能触发（原 `:198-201`）
#      ⇒ 「新增一份**该接线却没接线**的工程」**零东西会红**（= `D-R8` 暴露的形态 = `D-G21`）。
#      机器证（W28F 现场）：今天 `src/WpfGfx.Linux/WpfGfx.Linux.csproj` 就**是**这样一份
#      （默认 glob 生效 ∧ 仓内 `obj/**/*.cs` 在场 ∧ 无 Import），而老判据在它上面 `PASS`。
#      ⚠️ 每一节的**非 wired** 条目都带**见证谓词**（`witness` 列），本脚本**逐条复算**：
#      见证不成立 ⇒ `FAIL kind=WITNESS-EXPIRED`（「**你不再有借口**：要么接线、要么改声明」）。
#      ⇒ **否定项不是免罪符，是可反驳的断言**（纪律 47：不许只读报告，必须核机制）。
#   ⇒ 五档全过才 `PASS`。
#
# 【`#29` W29F 落地（主控裁定 1/2/3，**照裁定落地、不为让树变绿而放松任何一条**）】
#   · **裁定 1**：候选集的推导谓词 **P1**（「默认 `Compile` glob 生效 ∧ 仓内 `obj|bin` 有 `*.cs`」）
#     **并入 `UNDECLARED` 的诊断** —— 红行自己带 `p1=ARMED`（**已上膛**，真暴露）或
#     `p1=IDLE`（**只是没表态**）⇒ 读者不必再去手算它属于哪一种。`WITNESS-EXPIRED` 行也**只追加**
#     同一个 `p1=` 诊断字段（判定语义零改动：`ARMED`/`IDLE` **都照样红**）。
#   · **裁定 2**：`src/WpfGfx.Linux/WpfGfx.Linux.csproj` 在声明册里写 **`suspended` + 见证 `no-in-repo-obj`**
#     —— 它的见证**今天在真树上不成立**（`src/WpfGfx.Linux/obj/Debug/net10.0/*.cs` 在场，实测 2 份）
#     ⇒ **真树今天是 `rc=1` / `FAIL kind=WITNESS-EXPIRED` 点名这一份，这是要的**：
#     它应当**红着**直到主控接线它（或裁定它改走别的机制）。**别为了让树变绿而改判据或改见证。**
#     ⚠️ 自测 case A 用的是**不复制 `obj/` 的镜像** ⇒ 它 PASS **不等于**真树 PASS（见 case Q）。
#   · **裁定 3**：`CAND_MIN` **不许**做成可覆盖的环境变量（否则"只镜像 40 份 wired + `CAND_MIN=0`"
#     会假绿）⇒ 见 `CAND_MIN` 处的注释；反极性 = `--selftest` case R。
#
# 【`#30` W30C 落地（`D-G33`）：见证换成**不依赖构建产物**的谓词】
#   · **被换掉的**：`no-in-repo-obj`（判"工程目录下没有 `obj/`、也没有 `bin/`"）。它是一条
#     **可被"删产物"满足的免罪符** —— `rm -rf <proj>/obj` 就能让它成立，而那是**构建产物**、
#     下一次构建就回来（`#29` W29F 已如实记为边界 ⇒ 登记为 `D-G33`）。⇒ 本件**删除**该谓词：
#     声明册里再写它只会得到 `kind=UNKNOWN-WITNESS` ⇒ **`NOINFO`**（不许当绿；`--selftest` case Q）。
#   · **新谓词一 `not-in-build-coverage`（17 行 `suspended` 用）**：该工程**不在**本仓任何
#     "会构建它"的覆盖面里 ⇒ 仓内不可能产生"工程目录下的陈旧 `obj/**/*.cs`" ⇒ `D-R8` 的向量
#     在本仓内**不可行使**。覆盖面（**全部取自源文本**）＝
#       ① `wpf-linux.sln` 的工程成员（`dotnet build wpf-linux.sln` 会构建成员）
#       ∨ ② `bridge-src-fp.sh --list` 的清单（桥发布会构建的源；＝已有 `fp_locked` 的数据源）
#       ∨ ③ 语料（`*.sh`/`*.py`）里"构建它"的命令行（`dotnet|msbuild … build|publish|pack`）
#       ∨ ④ **闭包**：被上面任一条里的工程以 `<ProjectReference>` 引用（引用者的构建会连它一起编）。
#   · **新谓词二 `foreign-intermediate`（`build/MilBridge/src/MilBridge.Linux` 用）**：该工程
#     **在本仓被构建**，但**每一条**构建命令行都把中间/产物目录指到仓外
#     （`-p:ArtifactsPath=`／`-p:BaseIntermediateOutputPath=`／`-p:IntermediateOutputPath=`）
#     ⇒ **合规构建不会在工程目录下留 `obj/`**。⚠️ **没有构建入口时本谓词不成立**（那是
#     `not-in-build-coverage` 该管的情形；报错行会明说，免得被当成"随便挑一个谓词"）。
#   · **为什么这两条与产物无关**：它们判的是"**本仓有没有一条会在工程目录下编译它的通道**"，
#     输入只有 `wpf-linux.sln`、候选 csproj、`*.sh`/`*.py` 三类**源文本**。
#     建 `obj/`／删 `obj/` **一个字节都不进判据**（`--selftest` case L：`plant_obj` 之后仍 `PASS`）。
#   · **数据源取不到 ⇒ 算不出来**（`WITNESS-UNCOMPUTABLE` ⇒ `NOINFO`，不许当绿、也不许当红）：
#     要求 `$ROOT/wpf-linux.sln` 在、且语料非空。⚠️ 这条契约是**为镜像/零件树**立的：
#     一条只镜像了 csproj 的树里，"本仓没有构建入口"与"我没镜像构建入口"**分不开**
#     ⇒ 不许把后者读成前者的绿（`--selftest` case Y）。
#   · **口径三条（引读数必须连它们一起引）**：
#     ① 语料 = 全树（排除 `obj/` `bin/` `upstream/` `.artifacts/`）的 `*.sh`/`*.py`；
#     ② **本件自己被排除在语料之外**（按文件名）—— 本文件的自测正文里必然出现"构建动词 ＋
#        csproj 名"的字样（那是**它自己的证词**），拿它当证据会**自我 disqualifying**
#        （`D-G15`/`D-G21` 同族：写下那句话的动作本身毁掉了它的证据）；
#     ③ **续行按逻辑行合并**（行尾 `\`）：`build/publish-milbridge.sh:34-35` 的构建命令跨行，
#        不合并的话 `-p:ArtifactsPath=` 落在下一行 ⇒ **假红**（本车道实测过这一档）。
#   · **残余洞（如实记，方向都是"多红"而不是假绿）**：③ 认"文本里有构建动词 ＋ csproj 名"
#     ⇒ 一行**注释**也能把工程算进覆盖面；④ 的闭包按 **csproj 基名**匹配 ⇒ 同名不同目录会互相牵连。
#     两条都只会让读数**更响**；要根治得改成"解析 sln/工程图"，那是另一趟的事。
#
# 【rc（三态，逐条写清）】**0 = PASS ｜ 1 = FAIL ｜ 2 = NOINFO**
#   ⚠️ 与 `baseline-sha-check.sh:14` 的"FAIL 与 NOINFO 都 `rc=1`"**刻意不同**（该件把两态并成一个 rc）。
#      本步按 `frame-step.sh` 的惯例把 `NOINFO` 单列 `rc=2`。两种做法在 `verify-all.sh` 的 `run_step`
#      里**都不会变绿**（非 0 即 `❌`，`verify-all.sh:77-103`）⇒ 单列只是**不让诊断面丢信息**。
#
# 【口径（**历史三个数 `38`/`40`/`42` 的分歧全在这里；引用本脚本的读数必须连口径一起引**）】
#   ①「命中文件数」= `grep -rl --include='*.csproj' -- 'BuildHygiene.props' .`                —— 现 40
#   ②「规范 `Import` **行**数」= 逐份 `grep -cF -- '<Import Project="$([MSBuild]::GetPathOfFileAbove('BuildHygiene.props'))" />'` 之和 —— 现 40
#   ③「任何**提及** `BuildHygiene.props` 的行数」= `grep -rn --include='*.csproj' -- 'BuildHygiene.props' .` —— 现 **82**
#      ⚠️ `82 = 40`（规范 Import 行）+ `42`（注释散文行）。**那 42 行里又有 2 行**同时含子串 `<Import`
#         与 `BuildHygiene.props`（`build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj:38`、
#         `build/MilBridge/tests/TextLineProto/TextLineProto.csproj:30` —— 都是**中文注释**）
#         ⇒ `grep -rn … 'BuildHygiene.props' . | grep -c '<Import'` 打出 **42**。
#         **⇒ `42` 是口径污染出来的数，不是 `Import` 行数**（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:1094`
#         记的"`Import` 行共 42 条"据此更正为 **40**）。
#   ④「名单长度」= 本文件内嵌名单的非空行数 —— 现 40（**独立于被测树**，见下）
#   ⇒ 本脚本把 ①②③④ **分别**打到屏上（`BHYGIENE_USERS_FILES=` / `BHYGIENE_USERS_LINES=` /
#     `BHYGIENE_MENTION_LINES=` / `BHYGIENE_LIST_N=`），**不许**并成一个数。
#
# 【名单从哪来（**本件的设计核心**）】**内嵌 golden 名单**（= 口径④），**不用**"遍历树 + 看 props 在不在"推。
#   理由：遍历推出来的名单**必然与树同步** ⇒ 删掉一行时它只看见"现在有 39 个"，**不会告诉你少了谁**
#   ⇒ 判据会跟着坏件一起缩水（这正是本项目最怕的那种"射程悄悄缩到零而它还是绿的"，见 `D-R4`）。
#   内嵌名单是一份**独立于被测树**的声明，形态与 `build/MilBridge/tools/applier-audit-expected.txt` 同族
#   —— 那份清单在文件头自己写着：「维护：新增/退役应用器时**改这里**，而不是只改 wave ——
#   这样"被摘掉"才会红」。少一份就**点名**。
#   · **"删掉整份 `BuildHygiene.props`"这种更彻底的坏法，本判据抓得住**：那 40 行 `<Import>` 还在
#     （`grep` 照样 40），但 props 文件没了 ⇒ ②档 `FAIL reason=props-missing`（`--selftest` case G 实测）。
#     **连"删 props + 把那 40 行一起摘掉"这种合并坏法也照样红**（②档先跑 ⇒ `props-missing`；W27C 另测一档）。
#   · 名单**也可以**用环境变量 `BHYGIENE_GOLDEN=<file>` 覆盖（供自测与将来外置）；
#     但**内嵌名单 + `EXPECT_N` 是默认且是权威**。
#
# 【维护契约（**必须写进文档，否则这条牙会咬错人**）】本判据断言的是"**这条保护是通过
#   `BuildHygiene.props` + 逐工程一行 `<Import>` 这个机制接的**"。若将来**换机制**
#   （例如改用仓根 `Directory.Build.props`），**必须同时改本文件的内嵌名单与 `EXPECT_N`**，
#   否则本步会红 —— 那是**预期的**（换机制是一件应当被看见的事），**不是**本牙的缺陷。
#
# 【形态】照 `build/MilBridge/tools/baseline-sha-check.sh`（`5836b8296b2e4245`）抄，逐条对应见
#   `build/MilBridge/W27C-report.md` §"抄了它的哪些设计（带行号）"。
# 反极性自测：`--selftest`
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="${BASH_SOURCE[0]}"
REAL_ROOT="$(cd "$HERE/../../.." && pwd)"
ROOT="${BHYGIENE_ROOT:-$REAL_ROOT}"
PROPS_REL='BuildHygiene.props'
PROPS="$ROOT/$PROPS_REL"
EXPECT_N=41                 # `wired` 节条数期望（**截断/被改 ⇒ NOINFO**，不许当绿）
ROSTER_REL='build/MilBridge/tools/build-hygiene-roster.tsv'   # `D-G21` 的声明册（三节 + 见证谓词）
# ⚠️⚠️ `CAND_MIN` **是纯字面量赋值，刻意不做成可覆盖的环境变量**（`#29` W29F 主控裁定 3）：
#   若写成 `CAND_MIN="${CAND_MIN:-82}"`，攻击面 = 「只镜像 40 份 wired 的零件树 + `CAND_MIN=0`」
#   ⇒ 候选集缩成 40 也照样 `PASS` ⇒ 那一档下界闸**当场变成假牙**。今天 `CAND_MIN=82` 会**覆盖**
#   环境里传入的任何值（bash 赋值语义）⇒ `env CAND_MIN=0 bash 本件` 的读数与不传**逐字节相同**
#   （`--selftest` case R 实测）。本文件**唯一**可被环境覆盖的支点是 `BHYGIENE_ROOT` /
#   `BHYGIENE_ROSTER` / `BHYGIENE_GOLDEN` / `BHYGIENE_FPLIST` —— **它们都不放宽候选下界**。
CAND_MIN=88                 # 候选 csproj 的**下界**（`#50`：W81A `W81AWindowProbe` 86→87、W82A `W82AMinMaxProbe` 87→88；本件在 `fp_inputs()` 覆盖面里 ⇒ `--why` 记账）（更少 ⇒ NOINFO：树被截断 ⇒ 反向扫描不可信；
                            #   更多 ⇒ 允许，走 `UNDECLARED` 判据 —— 新增工程正是要它红）
                            #   ⚠️【`#37` B】**新加一份 csproj ⇒ 必须同趟把本常量抬到新的现场数**
                            #     （`samples/ThirdPartyMini/ThirdPartyMini.csproj` 使 83 → 85；`build/MilBridge/tests/TabGapProbe/TabGapProbe.csproj` 使 85 → 86）。
                            #     不改会怎样：**生产路径照旧 PASS**（它只断言"≥ 下界"），而
                            #     `--selftest` 的常量漂移守卫会红：
                            #     `BHYGIENE_SELFTEST=FAIL kind=CONSTANT-DRIFT what=CAND_MIN decl=83 live=85
                            #      （**声明常量与现树对不上 ⇒ 别信本趟自测**）`。
                            #     ⭐ 这是"**同一个语义存在两处 ⇒ 必然分叉**"的又一例：同一个下界在
                            #       **生产**是"≥"、在**自测**是"==" —— 加工程的人只跑生产就看不见它分叉。
FPLIST_CACHE=''             # `fp-locked` 见证的数据源（惰性算一次）
# ── `#30` W30C（`D-G33`）：两个**不依赖构建产物**的见证谓词的数据源（惰性算一次）──────────
#   ⚠️ 这些量**只在有行用到那两个新谓词时才算**（今天 = 18 行 `suspended`）；算不到就 `COV_RC=2`
#      ⇒ 调用方**转 `NOINFO`**（不许当绿、也不许当红）。口径见头注释。
SLN_REL='wpf-linux.sln'
SLN="$ROOT/$SLN_REL"
COV_READY=''                # 闭包**惰性算一次**的哨兵
COV_RC=0                    #   0=数据源可用 ｜ 2=**算不出来**（⇒ NOINFO）
COV_N=0                     #   闭包里有多少份候选（诊断用，上屏）
CORPUS=''                   #   语料 = `*.sh`/`*.py` 的相对路径（每行一个）
BUILD_LINES=''              #   语料里的"构建命令行"（**逻辑行**，续行已合并；整行）
BUILD_BASES=''              #   上面那些行里出现的 csproj **基名**（去重；每行一个）
declare -A COV=()           #   rel → 1（在"会构建它"的覆盖面里）
# ⚠️ `BHYGIENE_FPLIST=<file>`（`#29` W29F **补文档**；W28F 稿里存在但**头注释一个字都没写**）：
#   它是见证谓词 `fp-locked` 的**数据源覆盖口**（`fp_list()` 的第一分支）—— 正常路径下
#   `fp-locked` 的数据源 = `$REAL_ROOT/build/bridge-src-fp.sh --list`（**现算**，不缓存到盘）。
#   **它只为一个目的存在**：让 `--selftest` 能**两极化**地测 `fp-locked`（见 case S）——
#   没有它，四个见证谓词里就有**一个从来没被"必须红"覆盖过**（射程缺一格）。
#   ⚠️ **残余洞（如实记）**：它同时是一条"**能让证据变绿**"的环境口 —— 指一份**含该路径**的
#      清单即可让 `fp-locked` 成立。边界：① `verify-all.sh` 不设它；② 它**只**影响
#      `fp-locked` 这一条合取项，另几条合取项（`no-in-repo-obj` 等）仍要现算；③ 今天全册只有
#      **1 行**用 `fp-locked`（`build/MilBridge/src/MilBridge.Linux`），且那一条**本来就成立**
#      ⇒ 今天**没有任何**红是靠它压下去的（今天不存在它造成的假绿）。
#   ⚠️ 另一条相关的**位置依赖**（不是洞，是事实）：`fp_list()` 的默认数据源取自 `$REAL_ROOT`
#      （**脚本自己所在那一棵树**），而其余全部判定取自 `$ROOT`（`BHYGIENE_ROOT`）⇒ 当两者
#      **不是同一棵树**时（`BHYGIENE_ROOT` 指向别处、脚本在沙箱里），`fp-locked` 是拿
#      **脚本那棵树**的清单去判**被检树**。本车道实测到这条：`$HOME/w29f-run/w28froot-orig`
#      少了 `bridge-src-fp.sh` ⇒ `fp-locked` 当场不成立 ⇒ **多出一条 `WITNESS-EXPIRED`（噪声）**。
#      方向性：这类失配只会让读数**更响**（多红），不会让红变绿；但它意味着
#      "镜像里的 `fp-locked` 见证的是**真树**的清单，不是镜像自己的"这句话必须**明说**（见 §边界）。
# 规范 Import 行（**逐字节**；`\$` 必须保留 —— 那是 MSBuild 属性函数、不是本脚本的变量）
IMPORT_LINE="<Import Project=\"\$([MSBuild]::GetPathOfFileAbove('BuildHygiene.props'))\" />"
EXCLUDE_SUBSTR='obj/**;bin/**'

sha16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }

# 名单来源：`$BHYGIENE_GOLDEN` 优先（自测/将来外置），否则**内嵌**（权威）
golden_read() {
  if [ -n "${BHYGIENE_GOLDEN:-}" ]; then
    [ -f "$BHYGIENE_GOLDEN" ] || return 1
    grep -v '^[[:space:]]*$' "$BHYGIENE_GOLDEN"
  else
    grep -v '^[[:space:]]*$' <<'BHYGIENE_GOLDEN_EOF'
build/DirectWrite.Linux/FallbackCriteria/FallbackCriteria.csproj
build/DirectWrite.Linux/FontEntryClosedLoop/DirectWrite.Linux.FontEntryClosedLoop.csproj
build/DirectWrite.Linux/Probe/DirectWrite.Linux.Probe.csproj
build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj
build/DirectWrite.Linux/SystemFontsProbe/DirectWrite.Linux.SystemFontsProbe.csproj
build/DirectWrite.Linux/Tests/DirectWrite.Linux.Tests.csproj
build/DirectWrite.Linux/WicClosedLoop/DirectWrite.Linux.WicClosedLoop.csproj
build/DirectWrite.Linux/WicSeamProbe/DirectWrite.Linux.WicSeamProbe.csproj
build/DirectWrite.Linux/WicWriteClosedLoop/DirectWrite.Linux.WicWriteClosedLoop.csproj
build/DirectWrite.Linux/WiringSmoke/DirectWrite.Linux.WiringSmoke.csproj
build/MilBridge/spike/AotLib/AotLib.csproj
build/MilBridge/spike/SmokeTest/SmokeTest.csproj
build/MilBridge/tests/BboxProbe/BboxProbe.csproj
build/MilBridge/tests/ClosedLoop/ClosedLoop.csproj
build/MilBridge/tests/CompositeFontProbe/CompositeFontProbe.csproj
build/MilBridge/tests/ContractProbe/ContractProbe.csproj
build/MilBridge/tests/D5CbrProbe/D5CbrProbe.csproj
build/MilBridge/tests/FamilyCoverageSelfTest/FamilyCoverageSelfTest.csproj
build/MilBridge/tests/FrameProbe/FrameProbe.csproj
build/MilBridge/tests/HbSpike/HbSpike.csproj
build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj
build/MilBridge/tests/IcuBreakParity/IcuBreakParity.csproj
build/MilBridge/tests/LsProbe/LsProbe.csproj
build/MilBridge/tests/ResolverGuardProbe/ResolverGuardProbe.csproj
build/MilBridge/tests/T2Repro/T2Repro.csproj
build/MilBridge/tests/T2eLineHeight/T2eLineHeight.csproj
build/MilBridge/tests/TextLineProto/TextLineProto.csproj
build/wic-abi-reference/AbiProbe/AbiProbe.csproj
samples/HelloMil/HelloMil.csproj
samples/HelloWpf/HelloWpf.csproj
samples/WpfFeatureProbe/WpfFeatureProbe.csproj
samples/WpfTextDemo/WpfTextDemo.csproj
src/WpfGfx.Linux/WpfGfx.Linux.csproj
tests/WpfGfx.Linux.Tests/Commands.Tests/WpfGfx.Linux.Commands.Tests.csproj
tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMil.Tests.csproj
tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj
tests/WpfGfx.Linux.Tests/Presentation.Tests/WpfGfx.Linux.Presentation.Tests.csproj
tests/WpfGfx.Linux.Tests/Rendering.Tests/WpfGfx.Linux.Rendering.Tests.csproj
tests/WpfGfx.Linux.Tests/Windowing.Tests/WpfGfx.Linux.Windowing.Tests.csproj
tests/parity/geometry/u14/U14.csproj
tools/GeometryOracle/GeometryOracle.csproj
BHYGIENE_GOLDEN_EOF
  fi
}

# 全树候选 csproj（**排除产物目录** —— 不排除的话 `obj/` 下的 53 份**生成副本**会进反向检查，
# 今天它们里面 0 份带规范 Import（W27C 实测），但**将来一旦有一份陈旧的带**，就会变成假红）
collect_candidates() {
  ( cd "$ROOT" 2>/dev/null && find . -name '*.csproj' \
      -not -path '*/obj/*' -not -path '*/bin/*' \
      -not -path '*/upstream/*' -not -path '*/.artifacts/*' -print )
}

noinfo() { echo "BHYGIENE_IMPORT=NOINFO reason=$1${2:+ $2}"; return 1; }

# ── `D-G21`：声明册读取（三节 + 见证谓词）─────────────────────────────────────
#   列序 = class / proj / witness / reason / declared_by（TAB 分隔；`#` 注释）
roster_read() {
  grep -v '^[[:space:]]*$' "$ROSTER" 2>/dev/null | grep -v '^[[:space:]]*#'
}

# `fp-locked` 见证的数据源：`bridge-src-fp.sh --list` 的**路径**列（纯 `find`+`sha256sum`，零 `dotnet`）
#   **契约（`#29` W29F 改）**：返回 **0 = 清单可用**（清单打到 stdout，**可以为空**）；
#   **1 = 数据源不可用 ⇒ 这一条谓词"算不出来"**（调用方必须转 `NOINFO`，**不许**当成"见证不成立"）。
#   ⚠️ 改前是 `cat …; return $?` ＋ `… || return 1` —— "数据源不在/输出为空"与"清单里没有这一条"
#      在管道里**分不开**（左边不说话 ⇒ 右边 `grep` 判"没有它"）⇒ **"算不出来"被静默升级成一条红**。
#      这正是纪律 21/27/28 的同族病：**算不出来不许冒充判定**（红与绿都不许冒充）。
#   现场（如实记）：本车道一次镜像读数里出现过**一条无法复现的 `WITNESS-EXPIRED`**
#      （`build/MilBridge/src/MilBridge.Linux` 的 `fp-locked+no-in-repo-obj`，同一命令其后 **20/20** 通过；
#      该行同趟的 `p1=IDLE(…*.cs=0)` 证明另一条合取项成立 ⇒ 只能是这里）⇒ 修完，这类抖动会以
#      **`NOINFO kind=WITNESS-UNCOMPUTABLE`** 现身，而不再冒充"见证过期"。
fp_list() {
  if [ -n "${BHYGIENE_FPLIST:-}" ]; then
    [ -f "$BHYGIENE_FPLIST" ] || return 1          # 指了一份不存在的清单 ⇒ 算不出来
    cat -- "$BHYGIENE_FPLIST" 2>/dev/null
    return 0
  fi
  local f="$REAL_ROOT/build/bridge-src-fp.sh"
  [ -f "$f" ] || return 1
  [ -n "$FPLIST_CACHE" ] || FPLIST_CACHE="$(bash "$f" --list 2>/dev/null | awk '{print $2}' | grep -v '^$')"
  [ -n "$FPLIST_CACHE" ] || return 1
  printf '%s\n' "$FPLIST_CACHE"
  return 0
}

# ── `#30` W30C（`D-G33`）：新谓词的数据源（**全是源文本**；与构建产物无关）──────────────
#   ⚠️ **本件自己被排除在语料之外**：本文件的自测正文里必然出现"构建动词 ＋ csproj 名"的字样
#      —— 那是**它自己的证词**，拿它当证据会**自我 disqualifying**（`D-G15`/`D-G21` 同族）。
script_corpus() {
  ( cd "$ROOT" 2>/dev/null && find . \
      \( -name '*.sh' -o -name '*.py' \) \
      -not -path '*/obj/*' -not -path '*/bin/*' -not -path '*/upstream/*' -not -path '*/.artifacts/*' \
      -not -name 'build-hygiene-import-check.sh' -print ) | sed 's|^\./||' | LC_ALL=C sort
}

# 逻辑行（**续行合并**：行尾 `\` ⇒ 与下一行拼接）。现场形态（`build/publish-milbridge.sh:34-35`）：
#   `timeout 1200 dotnet publish "$MB/src/MilBridge.Linux/MilBridge.Linux.csproj" \`
#   `    -c Release -r linux-x64 -m:1 -p:ArtifactsPath="$MB/.artifacts" 2>&1 | tail -4`
#   ⇒ 不合并的话 `-p:ArtifactsPath=` 落在**下一行** ⇒ `foreign-intermediate` **假红**。
logical_lines() {
  awk '{ if (sub(/\\$/, "")) { buf = buf $0 " "; next } print buf $0; buf = "" }
       END { if (buf != "") print buf }' "$1" 2>/dev/null
}

# 构建动词（口径：`dotnet`/`msbuild` 之后出现 build/publish/pack/msbuild）
BUILD_VERB_RE='(dotnet|msbuild)[^|]*(build|publish|pack|msbuild)'
# 私有中间/产物目录（三种合法写法任一 —— 都是"把中间目录指到**工程目录之外**"）
PRIV_OBJ_RE='-p:(ArtifactsPath|BaseIntermediateOutputPath|IntermediateOutputPath)='

refs_of() {   # $1=候选 rel ⇒ 它用 `<ProjectReference>` 引用的 csproj **基名**（每行一个）
  grep -F -- '<ProjectReference' "$ROOT/$1" 2>/dev/null \
    | sed -n 's/.*Include="\([^"]*\)".*/\1/p' | sed 's|.*[/\\]||' | grep -v '^$'
}

coverage_init() {   # 算一次"构建覆盖面闭包"（$ROOT 的源文本；与产物无关）
  [ -n "$COV_READY" ] && return 0
  COV_READY=1
  CORPUS="$(script_corpus)"
  # **数据源可用性契约**：sln 在 ∧ 语料非空 —— 否则"没有构建入口"与"我没镜像构建入口"分不开
  if [ ! -f "$SLN" ] || [ -z "$CORPUS" ]; then COV_RC=2; return 0; fi
  local _fl f rel c base
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    BUILD_LINES+="$(logical_lines "$ROOT/$f" | grep -E -- "$BUILD_VERB_RE" | grep -F -- '.csproj')"$'\n'
  done <<< "$CORPUS"
  # 从构建命令行里抽出 csproj **基名**（命令行里的路径写法五花八门：`..\`、`$(Var)`、绝对路径…）
  BUILD_BASES="$(printf '%s\n' "$BUILD_LINES" | tr ' \t' '\n\n' | grep -F -- '.csproj' \
      | sed -e "s/[\"']//g" -e 's|.*[/\\]||' | grep -v '^$' | LC_ALL=C sort -u)"
  if _fl="$(fp_list)"; then :; else COV_RC=2; return 0; fi
  local -A direct=()
  for rel in "${CAND[@]}"; do
    # ① sln 成员（sln 里用 `\` 作分隔符 ⇒ 两种写法都试）
    if grep -qiF -- "$(printf '%s' "$rel" | tr '/' '\\')" "$SLN" 2>/dev/null \
       || grep -qiF -- "$rel" "$SLN" 2>/dev/null; then direct["$rel"]=1; continue; fi
    # ② BRIDGE_SRC_FP 清单（桥发布会构建的源；复用已有 `fp_list()`）
    if grep -qxF -- "$rel" <<< "$_fl"; then direct["$rel"]=1; continue; fi
    # ③ 语料里的"构建命令行"（按基名匹配）
    if [ -n "$BUILD_BASES" ] && grep -qxF -- "${rel##*/}" <<< "$BUILD_BASES"; then
      direct["$rel"]=1; continue
    fi
  done
  # ④ 闭包：被覆盖面里的工程 `ProjectReference` 引到 ⇒ 也进覆盖面（引用者的构建会连它一起编）
  for rel in "${!direct[@]}"; do COV["$rel"]=1; done
  local changed=1
  while [ "$changed" = 1 ]; do
    changed=0
    for c in "${!COV[@]}"; do
      while IFS= read -r base; do
        [ -n "$base" ] || continue
        for rel in "${CAND[@]}"; do
          [ "${rel##*/}" = "$base" ] || continue
          [ -n "${COV[$rel]:-}" ] && continue
          COV["$rel"]=1; changed=1
        done
      done < <(refs_of "$c")
    done
  done
  COV_N="${#COV[@]}"
}

# 见证谓词复算：0=成立 ｜ 1=不成立（⇒ 红）｜ 2=含**未知**谓词（⇒ NOINFO）｜
#              3=谓词**数据源算不出来**（⇒ NOINFO；**不许当红、更不许当绿**）
witness_ok() {  # $1=见证表达式（`+` 连接，全部必须成立） $2=相对路径
  local expr="$1" rel="$2" f="$ROOT/$2" w ok=1 oIFS="$IFS" _fl base="${2##*/}" _n _bad _ln
  IFS='+'
  for w in $expr; do
    case "$w" in
      import-line)     [ "$(grep -cF -- "$IMPORT_LINE" "$f" 2>/dev/null || true)" = 1 ] || ok=0 ;;
      no-compile-glob) { grep -qE -- '<EnableDefaultItems>[[:space:]]*false' "$f" \
                         || grep -qE -- '<EnableDefaultCompileItems>[[:space:]]*false' "$f"; } || ok=0 ;;
      # ⚠️ `no-in-repo-obj` **已在 `#30` W30C 退休**（`D-G33`：它判的是构建产物是否存在 ⇒
      #    `rm -rf <proj>/obj` 就能让它成立）。写它 ⇒ 落到 `*)` ⇒ **UNKNOWN-WITNESS ⇒ NOINFO**。
      not-in-build-coverage)
        # 该工程**不在**本仓任何"会构建它"的覆盖面里（覆盖面 = sln 成员 ∨ BRIDGE_SRC_FP ∨
        #   语料里的构建命令行 ∨ 它们的 ProjectReference 闭包）⇒ 仓内不可能在它的工程目录下
        #   产生陈旧 `obj/**/*.cs` ⇒ `D-R8` 的向量在本仓内不可行使。**判据不看产物。**
        coverage_init
        [ "$COV_RC" = 0 ] || { IFS="$oIFS"; return 3; }   # 数据源取不到 ⇒ 算不出来（NOINFO）
        [ -z "${COV[$rel]:-}" ] || ok=0 ;;
      foreign-intermediate)
        # 该工程**在本仓被构建**，但**每一条**构建命令行都把中间/产物目录指到仓外
        #   ⇒ 合规构建不会在工程目录下留 `obj/`。**判据不看产物。**
        # ⚠️ 一条构建命令行都没有 ⇒ **不成立**（那是 `not-in-build-coverage` 该管的情形）。
        coverage_init
        [ "$COV_RC" = 0 ] || { IFS="$oIFS"; return 3; }
        _n=0; _bad=0
        while IFS= read -r _ln; do
          [ -n "$_ln" ] || continue
          case "$_ln" in *"$base"*) ;; *) continue ;; esac
          _n=$((_n + 1))
          grep -qE -- "$PRIV_OBJ_RE" <<< "$_ln" || _bad=1
        done <<< "$BUILD_LINES"
        { [ "$_n" -gt 0 ] && [ "$_bad" -eq 0 ]; } || ok=0 ;;
      fp-locked)
        # **算不出来 ≠ 不成立**：数据源不可用时立刻返回 3（调用方转 NOINFO），不许 `ok=0`。
        if _fl="$(fp_list)"; then
          grep -qxF -- "$rel" <<< "$_fl" || ok=0
        else
          IFS="$oIFS"; return 3
        fi ;;
      *)               IFS="$oIFS"; return 2 ;;
    esac
  done
  IFS="$oIFS"
  [ "$ok" = 1 ]
}

# ── `#29` W29F · 主控裁定 1：「候选集判定（P1）并入 `UNDECLARED` 的诊断」─────────────────
#   P1 = **推导谓词**（`#28` W28F 定形；脚本 `$HOME/w28f/pred_p1.py`）：
#        「**默认 `Compile` glob 生效** ∧ **仓内 `obj|bin` 下有 `*.cs`**」
#        ⇒ 满足 P1 的工程，**命令行把中间目录指到仓外**时就会把仓内陈旧的
#          `obj/**/*.AssemblyInfo.cs` 收进编译 ⇒ 撞成 `CS0579`（`D-R8` 的实害向量）。
#   ⇒ 让红的那一行**自己说**它属于哪一种，读者不必再去手算：
#        `p1=ARMED`  = **已上膛**（glob 生效 ∧ 仓内有 `*.cs` ⇒ 这份工程**真的暴露**）
#        `p1=IDLE`   = **只是没表态**（P1 不成立 ⇒ 今天没有实害向量，但**声明仍然缺**）
#   ⚠️ 本函数**只注释诊断、不参与任何计数**：它**不**改 `rc`、不改 `state`、不改任何 `=FAIL`
#      的成立条件 —— 一份 `UNDECLARED` 无论 `ARMED` 还是 `IDLE` **都照样红**（不许把 IDLE 读成绿）。
#   ⚠️ 副作用边界：`find` 只在**该工程自己的** `obj/` `bin/` 下扫（`-maxdepth` 不限但目录很小），
#      且**只在红行上调用**（绿趟零调用 ⇒ 对正极性零成本、零位移）。
p1_tag() {  # $1=相对路径 ⇒ 打 `p1=ARMED|IDLE`（+ 空 P1 时的一句原因）
  local rel="$1" f="$ROOT/$1" d glob=on n
  d="$(dirname "$f")"
  grep -qE -- '<EnableDefaultItems>[[:space:]]*false|<EnableDefaultCompileItems>[[:space:]]*false' "$f" 2>/dev/null && glob=off
  n="$(find "$d/obj" "$d/bin" -name '*.cs' 2>/dev/null | wc -l)"
  if [ "$glob" = on ] && [ "$n" -gt 0 ]; then
    printf 'p1=ARMED(p1:默认Compile-glob生效&仓内obj|bin有*.cs n=%s)' "$n"
  else
    printf 'p1=IDLE(p1:glob=%s 仓内obj|bin的*.cs=%s)' "$glob" "$n"
  fi
}

run_check() {
  local -a LIST=()
  local p rel c m
  local n_list=0 n_files=0 n_lines=0 n_ment_f=0 n_ment_l=0
  local disappeared=0 dup=0 unlisted=0 file_absent=0
  local undeclared=0 witness_bad=0 class_conflict=0 n_cand=0 wit_rc=0
  local state=PASS reason=ok

  # ── ① 声明册可用（三节 + 逐条见证；`D-G21`）──────────────────────────────────
  #   节名：wired（**该接线且已接线**）/ notneeded（**声明**不需要，见证复算证明不需要）
  #        / suspended（**声明**今天先不接，见证复算证明理由仍成立）
  if [ -n "${BHYGIENE_ROSTER:-}" ]; then ROSTER="$BHYGIENE_ROSTER"; else ROSTER="$ROOT/$ROSTER_REL"; fi
  if [ ! -f "$ROSTER" ]; then
    noinfo roster-missing "roster=${ROSTER}（**声明册不在 ⇒ 判据算不出**，不许当绿）"; return 2
  fi
  local -a W_ORDER=()
  declare -A WIRED=() NOTNEEDED=() SUSPENDED=() WIT=() CLS=()
  local line n_tab cls proj wit rsn by nw=0 nnn=0 nsus=0 n_bad=0 n_dupdecl=0
  while IFS= read -r line; do
    n_tab="$(printf '%s' "$line" | tr -cd '\t' | wc -c)"
    if [ "$n_tab" -ne 4 ]; then
      echo "BHYGIENE_ROSTER=NOINFO kind=MALFORMED tabs=$n_tab line=$line（**5 列**：class/proj/witness/reason/declared_by）"
      n_bad=$((n_bad + 1)); continue
    fi
    cls="${line%%$'\t'*}"; line="${line#*$'\t'}"
    proj="${line%%$'\t'*}"; line="${line#*$'\t'}"
    wit="${line%%$'\t'*}"; line="${line#*$'\t'}"
    rsn="${line%%$'\t'*}"; by="${line#*$'\t'}"
    [ -n "$proj" ] || { echo "BHYGIENE_ROSTER=NOINFO kind=MALFORMED proj-empty line=$cls"; n_bad=$((n_bad + 1)); continue; }
    # `BHYGIENE_GOLDEN` 只覆盖 **wired** 节（自测钩子；其余两节仍读声明册）
    if [ -n "${BHYGIENE_GOLDEN:-}" ] && [ "$cls" = wired ]; then continue; fi
    [ -z "${WIT[$proj]:-}" ] || { echo "BHYGIENE_ROSTER=NOINFO kind=DUP-DECL proj=$proj（同一份工程声明了两节）"; n_dupdecl=$((n_dupdecl + 1)); continue; }
    case "$cls" in
      wired)      WIRED["$proj"]=1; W_ORDER+=("$proj"); nw=$((nw + 1)) ;;
      notneeded)  NOTNEEDED["$proj"]=1; nnn=$((nnn + 1)) ;;
      suspended)  SUSPENDED["$proj"]=1; nsus=$((nsus + 1)) ;;
      *)          echo "BHYGIENE_ROSTER=NOINFO kind=UNKNOWN-CLASS class=$cls proj=$proj（只认 wired/notneeded/suspended）"
                  n_bad=$((n_bad + 1)); continue ;;
    esac
    WIT["$proj"]="$wit"; CLS["$proj"]="$cls"
  done < <(roster_read)

  if [ "$n_dupdecl" -gt 0 ] || [ "$n_bad" -gt 0 ]; then
    noinfo roster-malformed "bad=$n_bad dup_decl=$n_dupdecl roster=$(sha16 "$ROSTER")（**声明册读不明白 ⇒ 不许当绿**）"
    return 2
  fi

  # `BHYGIENE_GOLDEN` 分支：wired 节改由该文件给出（自测用；语义同旧版）
  if [ -n "${BHYGIENE_GOLDEN:-}" ]; then
    if [ ! -f "$BHYGIENE_GOLDEN" ]; then noinfo golden-missing "source=$BHYGIENE_GOLDEN"; return 2; fi
    while IFS= read -r p; do [ -n "$p" ] || continue; WIRED["$p"]=1; W_ORDER+=("$p"); WIT["$p"]='import-line'; CLS["$p"]=wired; nw=$((nw + 1)); done < <(grep -v '^[[:space:]]*$' "$BHYGIENE_GOLDEN")
  fi

  n_list="$nw"
  if [ "$n_list" -eq 0 ]; then noinfo roster-empty "roster=$(sha16 "$ROSTER")"; return 2; fi
  if [ "$n_list" -ne "$EXPECT_N" ]; then
    noinfo wired-length-mismatch "n=$n_list expect=$EXPECT_N（wired 节被截断/被改 ⇒ 判据算不出，**不许当绿**）"
    return 2
  fi

  # ── ② 实现件在，且仍带着那条排除 ────────────────────────────────────────────
  #   ⚠️ 下面每一条"坏在哪"的行都**刻意写成 `BHYGIENE_DRIFT=FAIL …` 形态**：`verify-all.sh:217`
  #      的失败分支只 grep `[A-Z][A-Z0-9_]*=(FAIL|NOINFO)` ⇒ 这样**逐条点名能上屏**，
  #      而不是只印一行汇总数（诊断面不许丢）。
  if [ ! -f "$PROPS" ]; then
    echo "BHYGIENE_DRIFT=FAIL kind=PROPS-MISSING path=$PROPS_REL（**最彻底的坏法**：实现件没了。无论那 40 行 Import 还在不在 —— 在 ⇒ 指向空气（MSB4019）；不在 ⇒ 一并被摘掉 —— 两种情况都没有保护）"
    echo "BHYGIENE_IMPORT=FAIL reason=props-missing props=$PROPS_REL"
    return 1
  fi
  if ! grep -qF -- "$EXCLUDE_SUBSTR" "$PROPS"; then
    echo "BHYGIENE_DRIFT=FAIL kind=PROPS-CONTENT-LOST path=$PROPS_REL missing='$EXCLUDE_SUBSTR'（文件在、保护被掏空）"
    echo "BHYGIENE_IMPORT=FAIL reason=props-exclusion-lost props=$(sha16 "$PROPS")"
    return 1
  fi

  # ── ③ 正向：wired 节 → 树 ───────────────────────────────────────────────────
  #   ⚠️ 本档**排在下界闸之前**（`#27` W28F 自测实测出来的次序）：删掉一份 wired 工程会让候选数掉到
  #      `CAND_MIN` 以下 —— 若下界闸在前，那份"点名到文件"的 `FILE-ABSENT` 会被一条 NOINFO 盖掉
  #      ⇒ 诊断面从"哪一份没了"退成"候选集变小了"。次序反过来，**两种情形都不绿**，而各自说自己的话。
  for p in "${W_ORDER[@]}"; do
    if [ ! -f "$ROOT/$p" ]; then
      # ⚠️ `#29` W29F：本行文本里的『』**刻意不用反引号** —— 双引号里出现的反引号会被 shell
      #    当**命令替换**执行（`D-G21: command not found`），句子里那几个字**当场消失**。
      #    `--selftest` 的 `noise=` 断言就是为这一类"诊断文本被 shell 吃掉"加的牙（见 `chk()`）。
      echo "BHYGIENE_DRIFT=FAIL kind=FILE-ABSENT path=$p（名单里的工程文件不在树上）（『D-G21』起「名单」含声明册 build-hygiene-roster.tsv 的 wired 节 —— 旧句原文逐字保留在前）"
      file_absent=$((file_absent + 1)); continue
    fi
    c="$(grep -cF -- "$IMPORT_LINE" "$ROOT/$p" 2>/dev/null || true)"; c="${c:-0}"
    if [ "$c" -eq 0 ]; then
      echo "BHYGIENE_DRIFT=FAIL kind=DISAPPEARED path=$p c=0（**这一行掉了 ⇒ 私有 obj 构建会大面积 CS0579**）"
      disappeared=$((disappeared + 1))
    elif [ "$c" -gt 1 ]; then
      echo "BHYGIENE_DRIFT=FAIL kind=DUP path=$p c=$c（同一份工程里插了多行）"
      dup=$((dup + 1))
    fi
  done

  # ── ③' 候选集**下界**（`D-G21` 的前置；**更少 ⇒ NOINFO**，绝不当绿）────────────
  local -a CAND=()
  while IFS= read -r rel; do [ -n "$rel" ] && CAND+=("$rel"); done < <(collect_candidates | sed 's|^\./||')
  n_cand="${#CAND[@]}"
  #   ⚠️ **降级条件**：只有"③ 档一条具体缺陷都没点出来"时才降成 NOINFO —— 若 `FILE-ABSENT`/
  #      `DISAPPEARED` 已经点到具体文件，那条**就是**判据该说的话，不许被一条 NOINFO 盖掉。
  if [ "$n_cand" -lt "$CAND_MIN" ] && [ $((disappeared + dup + file_absent)) -eq 0 ]; then
    noinfo candidates-below-min "n=$n_cand min=$CAND_MIN（**候选集被截断 ⇒ 反向扫描不可信**：镜像/零件树不是真树，不许当绿）"
    return 2
  fi

  # ── ④ 反向：树 → 声明册（**这一档才是 `D-G21` 的牙**）─────────────────────────
  local unknown_wit=0 wit_noinfo=0
  for rel in "${CAND[@]}"; do
    c="$(grep -cF -- "$IMPORT_LINE" "$ROOT/$rel" 2>/dev/null || true)"; c="${c:-0}"
    m="$(grep -cF -- 'BuildHygiene.props' "$ROOT/$rel" 2>/dev/null || true)"; m="${m:-0}"
    [ "$m" -gt 0 ] && n_ment_f=$((n_ment_f + 1))
    n_ment_l=$((n_ment_l + m))
    if [ "$c" -gt 0 ]; then
      n_files=$((n_files + 1)); n_lines=$((n_lines + c))
      if [ -z "${WIT[$rel]:-}" ]; then
        echo "BHYGIENE_DRIFT=FAIL kind=UNLISTED path=$rel c=$c（现场有规范 Import，却不在名单里 ⇒ **多出来的用户也要点名**）（『D-G21』起「名单」= 声明册 build-hygiene-roster.tsv 的**任一节**；旧句原文逐字保留在前）"
        unlisted=$((unlisted + 1)); continue
      fi
      if [ "${WIRED[$rel]:-}" != 1 ]; then
        echo "BHYGIENE_DRIFT=FAIL kind=CLASS-CONFLICT class=${CLS[$rel]} path=$rel c=$c（**声明为 ${CLS[$rel]}，却带着规范 Import** ⇒ 声明与树不符，改声明）"
        class_conflict=$((class_conflict + 1)); continue
      fi
      [ "$c" -eq 1 ] && continue   # 缺 1 行 / 重复行由 ③ 档点名（同一件事不数两次）
      continue
    fi
    # 下面：**不**带规范 Import 的候选 —— 老判据到此 `continue`（`D-G21` 的洞），新判据在这里分岔
    if [ -z "${WIT[$rel]:-}" ]; then
      echo "BHYGIENE_DRIFT=FAIL kind=UNDECLARED path=$rel c=0 $(p1_tag "$rel")（**既不在 wired、也不在 notneeded/suspended ⇒ 一份工程没表态**。『D-G21』：本该接线却没接线的工程，老判据在这一档**看不见**）"
      undeclared=$((undeclared + 1)); continue
    fi
    [ "${WIRED[$rel]:-}" = 1 ] && continue
    witness_ok "${WIT[$rel]}" "$rel"; wit_rc=$?
    case "$wit_rc" in
      0) : ;;
      2) echo "BHYGIENE_ROSTER=NOINFO kind=UNKNOWN-WITNESS path=$rel witness=${WIT[$rel]}（**未知见证谓词 ⇒ 判据算不出，不许当绿**）"
         unknown_wit=$((unknown_wit + 1)) ;;
      3) echo "BHYGIENE_ROSTER=NOINFO kind=WITNESS-UNCOMPUTABLE path=$rel witness=${WIT[$rel]}（**谓词的数据源算不出来 ⇒ 不许当绿、也不许当红**：『fp-locked』的清单取不到，或新谓词要的『wpf-linux.sln』／『*.sh』『*.py』语料不在）"
         wit_noinfo=$((wit_noinfo + 1)) ;;
      *) echo "BHYGIENE_DRIFT=FAIL kind=WITNESS-EXPIRED class=${CLS[$rel]} path=$rel witness=${WIT[$rel]} $(p1_tag "$rel")（**见证今天不成立 ⇒ 你不再有借口**：要么接线、要么改声明）"
         witness_bad=$((witness_bad + 1)) ;;
    esac
  done

  if [ "$unknown_wit" -gt 0 ] || [ "$wit_noinfo" -gt 0 ]; then
    noinfo witness-noinfo "n_unknown=$unknown_wit n_uncomputable=$wit_noinfo roster=$(sha16 "$ROSTER")（声明册里有本脚本不认识的见证谓词，或某个谓词的**数据源取不到** ⇒ **判据算不出来，不许当绿**）"
    return 2
  fi

  [ $((disappeared + dup + unlisted + file_absent + undeclared + witness_bad + class_conflict)) -eq 0 ] || { state=FAIL; reason=drift; }

  # 口径①②③④ **分别**上屏（**不许**并成一个数）；新增项**只加不删**
  echo "BHYGIENE_USERS_FILES=$n_files"
  echo "BHYGIENE_USERS_LINES=$n_lines"
  echo "BHYGIENE_MENTION_FILES=$n_ment_f"
  echo "BHYGIENE_MENTION_LINES=$n_ment_l"
  echo "BHYGIENE_LIST_N=$n_list"
  echo "BHYGIENE_ROSTER_N=$((nw + nnn + nsus))"
  echo "BHYGIENE_ROSTER_CLASSES=wired=$nw notneeded=$nnn suspended=$nsus"
  echo "BHYGIENE_CAND_N=$n_cand"
  # 覆盖面诊断（`#30` W30C）：只在真用到新谓词时才有（惰性算）⇒ 没算就打 `n/a`，**不许瞎报 0**
  if [ -n "$COV_READY" ]; then
    if [ "$COV_RC" = 0 ]; then
      echo "BHYGIENE_COVERAGE=OK n=$COV_N sln_projects=$(grep -c '\.csproj' "$SLN" 2>/dev/null || echo 0) corpus=$(printf '%s\n' "$CORPUS" | grep -c .) build_lines=$(printf '%s\n' "$BUILD_LINES" | grep -c .) build_bases=$(printf '%s\n' "$BUILD_BASES" | grep -c .)"
    else
      echo "BHYGIENE_COVERAGE=UNCOMPUTABLE sln=$([ -f "$SLN" ] && echo present || echo missing) corpus=$(printf '%s\n' "$CORPUS" | grep -c .)（**新谓词的数据源取不到 ⇒ 那些行只能 NOINFO**）"
    fi
  fi
  echo "BHYGIENE_IMPORT=$state reason=$reason files=$n_files lines=$n_lines list=$n_list mention_files=$n_ment_f mention_lines=$n_ment_l disappeared=$disappeared dup=$dup unlisted=$unlisted file_absent=$file_absent expect_n=$EXPECT_N props=$(sha16 "$PROPS") undeclared=$undeclared witness_expired=$witness_bad class_conflict=$class_conflict cand=$n_cand cand_min=$CAND_MIN notneeded=$nnn suspended=$nsus roster=$(sha16 "$ROSTER")"

  [ "$state" = PASS ] && return 0
  return 1
}

# ══════════════════════════════════════════════════════════════════════════════
# --selftest：反极性自测（**必须能证出"该红的红"**，不能只证"该绿的绿"）
# ══════════════════════════════════════════════════════════════════════════════
if [ "${1:-}" = '--selftest' ]; then
  # ── 【`D-G41` 判据件自证】本件在**自测期间**被改写 ⇒ 本趟读数**不可归因**（`NOINFO`：不许当绿、不许冒充红）──
  #   本件自测以 `bash "$SELF"` **重入自己**（`:688`）⇒ bash 每次为新子进程从磁盘**重读**本件 ⇒ 父进程按
  #   旧版造夹具、子进程按新版判定 ⇒ **改件窗口里出的红是凭空的红**。口径：**开头记 sha16、结尾再算一次**；
  #   不等 ⇒ `ST_ATTEST=NOINFO` 并点名（含 sha0/sha1 与内层 rc），统一 **rc=2**（`NOINFO` 码，不与 `FAIL` 混）。
  #   只加在 `--selftest` 路径；**生产路径一字未动**；不删例、不放宽任何期望（成对读数见 `$HOME/w33b-report.md`）。
  if [ -z "${ST_ATTEST_INNER:-}" ]; then
    ST_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    ST0="$(sha256sum "$ST_SELF" | cut -c1-16)"
    printf 'ST_ATTEST=OPEN self=%s sha16=%s\n' "$ST_SELF" "$ST0"
    if [ "${1:-}" = '--selftest' ]; then ST_IN=("$@"); else ST_IN=(--selftest "$@"); fi
    ST_OUT="$(ST_ATTEST_INNER=1 bash "$ST_SELF" "${ST_IN[@]}" 2>&1)"; ST_RC=$?
    printf '%s\n' "$ST_OUT"
    ST1="$(sha256sum "$ST_SELF" | cut -c1-16)"
    if [ "$ST1" != "$ST0" ]; then
      printf 'ST_ATTEST=NOINFO reason=self-rewritten-during-selftest（本件在自测期间被改写 ⇒ 上面的读数不可归因）self=%s sha0=%s sha1=%s inner_rc=%s\n' \
             "$ST_SELF" "$ST0" "$ST1" "$ST_RC"
      exit 2
    fi
    printf 'ST_ATTEST=PASS self=%s sha16=%s（自测期间本件未变 ⇒ 读数可归因）\n' "$ST_SELF" "$ST0"
    exit "$ST_RC"
  fi
  T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
  np=0; nf=0
  ROSTER="${BHYGIENE_ROSTER:-$ROOT/$ROSTER_REL}"

  # ⚠️ `#29` W29F 加：**`mktemp -d` 失败必须当场出声**。现场（本车道自己踩到，如实记录）：
  #   用 `TMPDIR=<一个不存在的目录> bash … --selftest` 跑 ⇒ `mktemp -d` 失败、`$T` **为空**
  #   ⇒ `"$T/A"` 退化成 `/A` ⇒ `mkdir: 无法创建目录 "/A"：权限不够`，而**19 例全部报 NOINFO**——
  #   屏上没有任何一句说"沙箱根本没建起来"（读者会把它读成"判据坏了"）。⇒ 提前断言，
  #   并**明确点名 `TMPDIR`**（纪律 63 的同族：沙箱必须自带 TMPDIR）。
  if [ -z "${T:-}" ] || [ ! -d "${T:-/nonexistent}" ]; then
    echo "BHYGIENE_SELFTEST=FAIL kind=TMPDIR-UNUSABLE tmpdir=${TMPDIR:-<未设>}（**沙箱没建起来 ⇒ 一例都别信**；纪律 63：沙箱必须自带可写的 TMPDIR）"
    exit 2
  fi

  # ── `#29` W29F 主控硬性要求 3：**一切计数都从现件现算，不许有写死值**（`D-G29` 的教训：
  #   有车道把 `gen` 写死 ⇒ 一换代自测就红，而作者在**旧件沙箱**里拿到**假绿**）。
  #   ⚠️ 本件里"写死"的只有两个**声明常量**（`EXPECT_N` = `wired` 节应有的条数、
  #      `CAND_MIN` = 候选 csproj 的下界）。它们**必须**是声明（否则判据跟着坏件缩水，`D-R4`），
  #      但**不许悄悄陈旧** ⇒ 本段在自测开头**用现场件重算这两个数**，不符 ⇒ **自测自己判红**
  #      （不是 PASS、也不是 NOINFO —— 那是"我的常量与今天的树对不上"，必须被人看见）。
  #   数据源全部是**现件**：`roster_read`（现声明册）、`collect_candidates()`（现树）。
  #   取证命令（同一算式的独立写法，见 `W29F-report.md` §F）：
  #     `awk -F'\t' '$1=="wired"' build/MilBridge/tools/build-hygiene-roster.tsv | wc -l`  ⇒ 应与 EXPECT_N 相同
  #     `find . -name '*.csproj' -not -path '*/obj/*' … -print | wc -l`                     ⇒ 应与 CAND_MIN 相同
  echo "BHYGIENE_SELFTEST_TMPDIR=$T（纪律 63：沙箱必须自带 TMPDIR，免得与并发车道撞车）"
  echo "BHYGIENE_SELFTEST_SOURCE=self=$(sha16 "$SELF") roster=$(sha16 "$ROSTER") root=$ROOT"
  n_wired_live="$(roster_read | awk -F'\t' '$1=="wired"{n++} END{print n+0}')"
  n_roster_live="$(roster_read | awk -F'\t' 'NF>=5{n++} END{print n+0}')"
  n_cand_live="$(collect_candidates | wc -l)"
  drift=0
  [ "$n_wired_live" = "$EXPECT_N" ] || { echo "BHYGIENE_SELFTEST=FAIL kind=CONSTANT-DRIFT what=EXPECT_N decl=$EXPECT_N live=$n_wired_live（**声明常量与现声明册对不上 ⇒ 别信本趟自测**）"; drift=1; }
  [ "$n_cand_live"  = "$CAND_MIN"  ] || { echo "BHYGIENE_SELFTEST=FAIL kind=CONSTANT-DRIFT what=CAND_MIN decl=$CAND_MIN live=$n_cand_live（**声明常量与现树对不上 ⇒ 别信本趟自测**）"; drift=1; }
  echo "BHYGIENE_SELFTEST_COUNTS_ERROR self_derived=yes roster_rows=$n_roster_live wired_live=$n_wired_live expect_n=$EXPECT_N cand_live=$n_cand_live cand_min=$CAND_MIN drift=$drift"
  [ "$drift" -eq 0 ] || exit 1

  # 【沙箱 = **只镜像被测面**】仓根 props ＋ **声明册** ＋ **声明册里的全部 csproj**（同相对路径）。
  #   ⚠️ **必须镜像全部候选（今天 82 份），不是只镜像 wired 的 40**：只镜像 40 的话反向扫描的候选集
  #      缩成 40 ⇒ `UNDECLARED` 这一档在副本里**永远不触发** ⇒ 自测变成"作者的判据在缩了射程的 fixture 上"。
  #      （旧版自测就有这一处射程缩减，如实记在 `verify-all.sh:482-483`；本版顺手补上。）
  #   ⚠️ 必须 `cp -p`（**真复制**）而不是硬链接：沙箱里要重写这些文件，硬链接会把改写带回真件
  #      （**仓内零改动是本件的硬约束**；本仓有车道用硬链接沙箱把真树臂日志原地截断过）。
  mirror() {  # $1 = 目标根
    local d="$1" cls p wit rsn by f
    mkdir -p "$d" "$d/$(dirname "$ROSTER_REL")" || return 1
    cp -p "$ROOT/$PROPS_REL" "$d/$PROPS_REL" || return 1
    cp -p "$ROSTER" "$d/$ROSTER_REL" || return 1
    # `#30` W30C：新谓词（`not-in-build-coverage`／`foreign-intermediate`）的数据源
    #   （`wpf-linux.sln` ＋ `*.sh`/`*.py` 语料）**也要镜像** —— 否则镜像里"本仓没有构建入口"
    #   与"我没镜像构建入口"分不开 ⇒ 判据只能报 `WITNESS-UNCOMPUTABLE`／`NOINFO`（不许假绿）。
    [ -f "$ROOT/$SLN_REL" ] && { cp -p "$ROOT/$SLN_REL" "$d/$SLN_REL" || return 1; }
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      mkdir -p "$d/$(dirname "$f")" || return 1
      cp -p "$ROOT/$f" "$d/$f" || return 1
    done < <(script_corpus)
    while IFS=$'\t' read -r cls p wit rsn by; do
      case "$cls" in ''|'#'*) continue ;; esac
      [ -n "$p" ] || continue
      mkdir -p "$d/$(dirname "$p")" || return 1
      cp -p "$ROOT/$p" "$d/$p" || return 1
    done < <(roster_read)
  }
  drop_import() { grep -vF -- "$IMPORT_LINE" "$1" > "$1.tmp" && mv "$1.tmp" "$1"; }
  dup_import()  { printf '%s\n' "$IMPORT_LINE" >> "$1"; }
  gut_props()   { grep -vF -- "$EXCLUDE_SUBSTR" "$1" > "$1.tmp" && mv "$1.tmp" "$1"; }
  # 把某工程的 `EnableDefaultCompileItems=false` 翻成 `true` ⇒ `no-compile-glob` 见证**失效**
  break_glob()  { sed -i 's|<EnableDefaultCompileItems>false</EnableDefaultCompileItems>|<EnableDefaultCompileItems>true</EnableDefaultCompileItems>|' "$1"; }
  # `#30` W30C 夹具：① 往镜像的 sln 里加一条**真形态**的工程记录；
  #   ② 把某脚本里构建命令行的私有中间目录（`-p:ArtifactsPath=…`）抹掉。
  add_sln_entry() {
    printf 'Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "W30C-FIXTURE", "%s", "{99999999-9999-9999-9999-999999999999}"\nEndProject\n' \
      "$(printf '%s' "$2" | tr '/' '\\')" >> "$1"
  }
  strip_priv_obj() { sed -i 's|-p:ArtifactsPath=[^ ][^ ]*||' "$1"; }
  # 造一份"工程目录下出现了 obj/（含 `*.cs`）"的假象。
  #   ⚠️ `#30` W30C：**新见证不看产物** ⇒ 它对判定**零影响**（case L 就是这条的牙）；
  #      它仍然保留，因为"产物的出现/消失**不改变任何一条判定**"这件事本身要被自测**逐例声明**。
  plant_obj()   { mkdir -p "$(dirname "$1")/obj" && printf '// stale\n' > "$(dirname "$1")/obj/stale.AssemblyInfo.cs"; }

  # ⚠️ 必须 `head -1`、且**额外断言结论行恰好 1 条**：`baseline-sha-check.sh:99-101` 记过一次
  #    真事故 —— 声明缺失时该脚本会印**两行同键**（诊断行 + 汇总行），不取首行就"比较永远失败"。
  #     本脚本按构造只有一行 `^BHYGIENE_IMPORT=`，这里**仍然机器断言** `n=1`，防复发。
  # ⚠️ `#29` W29F 加第三项断言 `noise` ＋ 第四项断言 `must`：**诊断文本本身被 shell 吃掉**
  #   也必须算这一例失败。
  #   现场（本车道自己踩到、如实记录）：`echo "…\`D-G21\`…"` 里的反引号**在双引号内仍会被当
  #   **命令替换**执行 ⇒ shell 报错（进 `2>&1`），而句子里那几个字**当场消失**；
  #   此时 `got`/`nl` **照样正确** ⇒ 只查状态值与行数的自测**完全看不见**它
  #   （W28F 稿的 `UNDECLARED` 行就带着这个伤）。
  #   ⚠️⚠️ `noise` 的模式**必须与语言环境无关**：本机 bash 的报错是**中文化**的
  #      `行 313: D-G21: 未找到命令` —— 只写 `command not found` **一条都命中不了**
  #      （本车道实测：加了 `LC_ALL=C` 之前，带伤副件 `--selftest` 仍报 **18/18 PASS = 假绿**）。
  #      ⇒ ① 子进程**显式 `LC_ALL=C`**（让 shell 级报错文本确定）；② 模式**两种语言都收**。
  #   ⚠️ `must`（由调用者用环境变量 `CHK_MUST` 传）是**更强**的一层：直接断言"这一例的诊断
  #      文本里**必须**出现某个子串" ⇒ 即使哪天报错文本再变种，文本被吃掉仍会被抓到。
  chk() {  # $1=case $2=expect $3=root [$4.. = 额外 env]；可选 env `CHK_MUST=<必须出现的子串>`
    local case="$1" expect="$2" root="$3"; shift 3
    local out rc got nl noise ok='no' must_pat="${CHK_MUST:-}" must='n/a'
    out="$(env "$@" LC_ALL=C BHYGIENE_ROOT="$root" bash "$SELF" 2>&1)"; rc=$?
    nl="$(printf '%s\n' "$out" | grep -c '^BHYGIENE_IMPORT=')"
    got="$(printf '%s\n' "$out" | sed -n 's/^BHYGIENE_IMPORT=\([A-Z]*\).*/\1/p' | head -1)"
    noise="$(printf '%s\n' "$out" | grep -cE 'command not found|not found|未找到命令|syntax error|语法错误|unbound variable')"
    if [ -n "$must_pat" ]; then
      if grep -qF -- "$must_pat" <<< "$out"; then must=KEPT; else must=MISS; fi
    fi
    if [ "$got" = "$expect" ] && [ "$nl" -eq 1 ] && [ "$noise" -eq 0 ] && [ "$must" != MISS ]; then
      ok='yes'; np=$((np + 1))
    else
      nf=$((nf + 1))
    fi
    printf 'SELFTEST case=%s expect=%s got=%s concl_lines=%s noise=%s must=%s rc=%s => %s\n' \
           "$case" "$expect" "$got" "$nl" "$noise" "$must" "$rc" "$ok"
    [ "$ok" = yes ] || printf '%s\n' "$out" | grep -E '^BHYGIENE_(DRIFT|ROSTER)=|not found|未找到命令' | head -3 | sed 's/^/          /'
  }

  WIRED_T='build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj'      # wired
  NN_T='build/MilBridge/tests/PcLineOracle/PcLineOracle.csproj'                # notneeded（no-compile-glob）
  SUS_T='tests/parity/windows/tab/src/TabOracle.csproj'                        # suspended（not-in-build-coverage）
  U1P_T='tests/parity/windows/src/U1Parity/U1Parity.csproj'                     # suspended（同上；被 U1Recorder 引用）
  SLNM_T='samples/HelloMil/HelloMil.csproj'                                     # wired ∧ 在 sln 里（= 覆盖面内）
  MBR_T='build/MilBridge/src/MilBridge.Linux/MilBridge.Linux.csproj'           # suspended（fp-locked+foreign-intermediate）
  # `#29` W29F 主控裁定 2 的**现场实例**（⏪ `#29` 收官时已被主控按 `D-G32` 真修掉：该行现在是
  #   `wired`＋`import-line`）—— 保留常量只为旧注释可考；下面**没有**任何 case 再依赖它。
  WPFGFX_T='src/WpfGfx.Linux/WpfGfx.Linux.csproj'
  # `CHK_MUST` = 该例**诊断文本里必须出现**的子串（`chk` 的第四项断言；默认空 = 不判）。
  #   ⚠️ 每个 case **显式置位/清空**，不许靠上例的残留（残留会让断言失去意义）。
  CHK_MUST=''

  # case A：正极性 —— 干净镜像 ⇒ PASS / rc=0
  mirror "$T/A"
  CHK_MUST=''; chk A PASS "$T/A"

  # case B：**必须红** —— 删掉某一份 wired 工程的那一行 Import ⇒ FAIL（DISAPPEARED=1）
  mirror "$T/B"; drop_import "$T/B/$WIRED_T"
  CHK_MUST='kind=DISAPPEARED path=build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj c=0'; chk B FAIL "$T/B"

  # case C：**必须红** —— 同一份工程重复插一行 ⇒ FAIL（DUP=1）
  mirror "$T/C"; dup_import "$T/C/$WIRED_T"
  CHK_MUST='kind=DUP path=build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj c=2'; chk C FAIL "$T/C"

  # case D：**必须红** —— wired 节里的工程文件整个不见了 ⇒ FAIL（FILE-ABSENT=1）
  mirror "$T/D"; rm -f "$T/D/$WIRED_T"
  CHK_MUST='（『D-G21』起「名单」含声明册 build-hygiene-roster.tsv 的 wired 节 —— 旧句原文逐字保留在前）'; chk D FAIL "$T/D"

  # case E：**声明册缺失** ⇒ NOINFO / rc=2（**不许当绿**）
  CHK_MUST='roster-missing'; chk E NOINFO "$T/A" BHYGIENE_ROSTER="$T/no-such-roster.tsv"

  # case F：wired 节被截断（40 → 39 行）⇒ NOINFO / rc=2（防"把名单删几行让判据跟着缩水"）
  roster_read | awk -F'\t' '$1=="wired"{print $2}' | head -39 > "$T/short.list"
  CHK_MUST='wired-length-mismatch'; chk F NOINFO "$T/A" BHYGIENE_GOLDEN="$T/short.list"

  # case G：**必须红** —— 删掉整份 `BuildHygiene.props`（**最彻底的坏法**）⇒ FAIL（props-missing）
  mirror "$T/G"; rm -f "$T/G/$PROPS_REL"
  CHK_MUST='kind=PROPS-MISSING'; chk G FAIL "$T/G"

  # case H：**必须红** —— props 在、但排除那条被掏空 ⇒ FAIL（props-exclusion-lost）
  mirror "$T/H"; gut_props "$T/H/$PROPS_REL"
  CHK_MUST='kind=PROPS-CONTENT-LOST'; chk H FAIL "$T/H"

  # case I：**必须红** —— 树里多出一份**带 Import 但不在声明册**的工程 ⇒ FAIL（UNLISTED=1）
  mirror "$T/I"; printf '%s\n' "$IMPORT_LINE" > "$T/I/EXTRA-Listed.csproj"
  CHK_MUST='（『D-G21』起「名单」= 声明册 build-hygiene-roster.tsv 的**任一节**；旧句原文逐字保留在前）'; chk I FAIL "$T/I"

  # ══ 以下是 `D-G21` 新加的牙（`#27` W28F）：老判据在上面 **I** 之外对这四种情形 **全部 PASS** ══
  # case J：**必须红（新牙·最重要）** —— 树里多出一份**根本不带 Import**、也不在声明册的工程
  #   ⇒ FAIL（UNDECLARED=1）。**这正是 `D-R8` 暴露的形态**（该接线却没接线），老判据看不见。
  mirror "$T/J"; printf '<Project Sdk="Microsoft.NET.Sdk">\n  <PropertyGroup><TargetFramework>net10.0</TargetFramework></PropertyGroup>\n</Project>\n' > "$T/J/EXTRA-Unwired.csproj"
  CHK_MUST='c=0 p1=IDLE(p1:glob=on 仓内obj|bin的*.cs=0)（**既不在 wired、也不在 notneeded/suspended ⇒ 一份工程没表态**。『D-G21』：本该接线却没接线的工程'; chk J FAIL "$T/J"

  # case K：**必须红** —— `notneeded` 的工程把 `EnableDefaultCompileItems` 翻成 true
  #   ⇒ 见证 `no-compile-glob` **失效** ⇒ FAIL（WITNESS-EXPIRED）「你不再有借口」
  mirror "$T/K"; break_glob "$T/K/$NN_T"
  CHK_MUST='kind=WITNESS-EXPIRED class=notneeded'; chk K FAIL "$T/K"

  # case L（`#30` W30C **换极**）：**必须绿** —— `D-G33` 的正题：在 `suspended` 工程的目录下
  #   **造出 `obj/` ＋ `obj/*.cs`**（这正是**旧**见证 `no-in-repo-obj` 判红的那种状态）
  #   ⇒ 新见证 `not-in-build-coverage` **不看产物** ⇒ **仍然 PASS**（"删/建产物"都进不了判据）。
  #   ⚠️ 换极不是放松：旧 case L 证明的"产物出现 ⇒ 红"正是 `D-G33` 认定的**免罪符方向**
  #      （`rm -rf obj` 就能解）；补上的是 U/V/W/X 四档**必红**，而且它们判的都是**结构**。
  mirror "$T/L"; plant_obj "$T/L/$SUS_T"
  CHK_MUST=''; chk L PASS "$T/L"

  # case M：**必须红** —— 声明为 `suspended`/`notneeded` 的工程**偷偷接上了线** ⇒ FAIL（CLASS-CONFLICT）
  #   ⚠️ `#29` W29F 自记缺陷：本行初版**漏了 `CHK_MUST`** ⇒ 它**继承**了 case L 的模式 ⇒
  #      `must=MISS` ⇒ 自测报 `FAIL 17/18`。**这正是 `CHK_MUST` 注释里警告的残留陷阱**，
  #      而且它**是被自测自己抓出来的**（不是被我事后读出来的）。
  mirror "$T/M"; printf '%s\n' "$IMPORT_LINE" >> "$T/M/$SUS_T"
  CHK_MUST='kind=CLASS-CONFLICT class=suspended path=tests/parity/windows/tab/src/TabOracle.csproj c=1'; chk M FAIL "$T/M"

  # case N：**必须 `NOINFO`** —— 声明册里有本脚本不认识的见证谓词 ⇒ rc=2（**不许当绿**）
  awk -F'\t' 'BEGIN{OFS="\t"} $1=="suspended" && !d { $3="no-such-witness"; d=1 } {print}' "$ROSTER" > "$T/unknown-wit.tsv"
  CHK_MUST='kind=UNKNOWN-WITNESS'; chk N NOINFO "$T/A" BHYGIENE_ROSTER="$T/unknown-wit.tsv"

  # case O：**必须 `NOINFO`** —— 候选集被截断（82 → 81）⇒ rc=2（镜像/零件树不是真树，不许当绿）
  mirror "$T/O"; rm -f "$T/O/$SUS_T"
  CHK_MUST='reason=candidates-below-min'; chk O NOINFO "$T/O"

  # case P：**必须 `NOINFO`** —— 声明册有一行列数不足 ⇒ rc=2（读不明白的声明不许当绿）
  awk -F'\t' 'BEGIN{OFS="\t"} NR==1{print "suspended\tbuild/x.csproj"}' "$ROSTER" > "$T/malformed.tsv"
  roster_read | tail -n +2 >> "$T/malformed.tsv"
  CHK_MUST='reason=roster-malformed'; chk P NOINFO "$T/A" BHYGIENE_ROSTER="$T/malformed.tsv"

  # case Q（`#30` W30C **改写**）：**必须 `NOINFO`** —— 声明册里写**已退休**的谓词 `no-in-repo-obj`
  #   （`D-G33` 换掉的那一条）⇒ 本脚本**不再认识**它 ⇒ `kind=UNKNOWN-WITNESS` ⇒ `rc=2`。
  #   **不许当绿**：退休的谓词不许"悄悄复活"成一条判据（它判的是构建产物 ⇒ 免罪符）。
  #   ⏪ 旧 case Q 的前提（`WpfGfx.Linux.csproj` 是 `suspended`＋`no-in-repo-obj`、目录下有 `obj/*.cs`）
  #      已被 `#29` 的 `D-G32` 修掉（该行现在是 `wired`＋`import-line`）⇒ **旧 case Q 自那时起就是红的**
  #      （本车道实测：`case Q expect=FAIL got=PASS concl_lines=1 noise=0 must=MISS rc=0 => no`，
  #       整趟 `BHYGIENE_SELFTEST=FAIL cases=20 pass=19 fail=1`）⇒ 本趟**换内容**。
  #      ⚠️ 换内容**不是**"为了让自测变绿而删档"：新内容仍然要求一个"**不许当绿**"的读数（`NOINFO`），
  #      且函数上下新增了 4 档**必红**（U/V/W/X）—— 反极性档数 4 → 8。
  awk -F'\t' 'BEGIN{OFS="\t"} $1=="suspended" && !d { $3="no-in-repo-obj"; d=1 } {print}' "$ROSTER" > "$T/retired-wit.tsv"
  CHK_MUST='kind=UNKNOWN-WITNESS'; chk Q NOINFO "$T/A" BHYGIENE_ROSTER="$T/retired-wit.tsv"

  # case R（`#29` W29F 加）：**`CAND_MIN` 不可被环境覆盖** —— 把候选集截断到 81（镜像里删一份
  #   `suspended` 件）**且**在环境里塞 `CAND_MIN=0`（"假绿攻击"的原话写法）⇒ 仍必须 `NOINFO`。
  #   若 `CAND_MIN` 被写成 `${CAND_MIN:-82}`，这一例会变成 `PASS` ⇒ 本例就是那条攻击面的**反极性**。
  mirror "$T/R"; rm -f "$T/R/$SUS_T"
  CHK_MUST="min=$CAND_MIN"; chk R NOINFO "$T/R" CAND_MIN=0

  # case S（`#29` W29F 加）：**必须红** —— 见证谓词 **`fp-locked` 的反极性**：把它的数据源
  #   （`BHYGIENE_FPLIST`）换成一份**空**清单 ⇒ 该谓词不成立 ⇒ `FAIL kind=WITNESS-EXPIRED`。
  #   加这一例之前，四个见证谓词（`import-line` / `no-compile-glob` / `no-in-repo-obj` /
  #   `fp-locked`）里**唯独 `fp-locked` 一例红都没有** ⇒ 它是"从没被行使过的牙"（纪律 47）。
  #   ⚠️ 空文件（而不是缺失文件）是刻意的：`fp_list()` 对"文件在但清单空"返回 0 且输出为空
  #      ⇒ 走的正是"清单里没有这一条"那条正常分支，而不是 `cat` 失败那条。
  mirror "$T/S"; : > "$T/empty-fplist"
  CHK_MUST='kind=WITNESS-EXPIRED class=suspended path=build/MilBridge/src/MilBridge.Linux/MilBridge.Linux.csproj witness=fp-locked+foreign-intermediate'
  chk S FAIL "$T/S" BHYGIENE_FPLIST="$T/empty-fplist"

  # case T（`#29` W29F 加）：**必须 `NOINFO`** —— **"算不出来"不许冒充判定**：把 `fp-locked`
  #   的数据源指向一份**不存在**的文件 ⇒ 谓词**算不出来** ⇒ 必须 `rc=2` ＋
  #   `kind=WITNESS-UNCOMPUTABLE`，**既不许判红（WITNESS-EXPIRED）也不许判绿**。
  #   ⚠️ 这一例与 case S **成对**：S 是"清单可用但里面没有它"（⇒ **红**），T 是"清单根本取不到"
  #      （⇒ **NOINFO**）。改前这两件事在管道里分不开（都表现为 grep 不命中）⇒ 本车道实测到
  #      一条**无法复现的假红**（见 `fp_list()` 头注释）；T 就是那条缺口的牙。
  mirror "$T/T"
  CHK_MUST='kind=WITNESS-UNCOMPUTABLE'; chk T NOINFO "$T/T" BHYGIENE_FPLIST="$T/no-such-fplist"

  # ══ `#30` W30C 新加的牙（`D-G33`）：两条**不依赖构建产物**的见证，逐档反极性 ══
  # case U：**必须红** —— 把一份 `suspended` 工程**加进镜像的 `wpf-linux.sln`** ⇒ 它成了覆盖面①
  #   的成员（`dotnet build wpf-linux.sln` 会构建它）⇒ `not-in-build-coverage` 不成立 ⇒ FAIL。
  #   **这就是"暴露变成真的"那一刻**（而"删 `obj/`"永远到不了这一刻）。
  mirror "$T/U"; add_sln_entry "$T/U/$SLN_REL" "$SUS_T"
  CHK_MUST="kind=WITNESS-EXPIRED class=suspended path=$SUS_T witness=not-in-build-coverage"; chk U FAIL "$T/U"

  # case V：**必须红** —— 在镜像的某个脚本里加一条**不带私有中间目录**的构建命令行
  #   ⇒ 覆盖面③命中 ⇒ FAIL。
  mirror "$T/V"; printf 'dotnet build %s\n' "$SUS_T" >> "$T/V/build/integration-wave.sh"
  CHK_MUST="kind=WITNESS-EXPIRED class=suspended path=$SUS_T witness=not-in-build-coverage"; chk V FAIL "$T/V"

  # case W：**必须红（闭包那一半）** —— 覆盖面**内**的工程（`$SLNM_T`，sln 成员）加一行
  #   `<ProjectReference>` 指向 `$U1P_T` ⇒ 它进覆盖面闭包（引用者的构建会连它一起编）⇒ FAIL。
  #   同趟说明**为什么不是"见引用就红"**：`$U1P_T` 今天**本来**就被 `U1Recorder` 引用，而那个
  #   引用者**不在**覆盖面里（外面那支 Windows harness 自己的构建也不在本仓）⇒ 不牵连。
  #   这正是"闭包只从**覆盖面**出发"与"任何 ProjectReference 都算"的区别（后者会**假红**）。
  mirror "$T/W"
  printf '  <ItemGroup><ProjectReference Include="..\\..\\..\\parity\\windows\\src\\U1Parity\\U1Parity.csproj" /></ItemGroup>\n' >> "$T/W/$SLNM_T"
  CHK_MUST="kind=WITNESS-EXPIRED class=suspended path=$U1P_T witness=not-in-build-coverage"; chk W FAIL "$T/W"

  # case X：**必须红** —— `foreign-intermediate` 的反极性：把镜像的 `publish-milbridge.sh` 里
  #   那个 `-p:ArtifactsPath=…` 抹掉 ⇒ 那条构建命令会在**工程目录下**建 `obj/` ⇒ 见证不成立 ⇒ FAIL。
  mirror "$T/X"; strip_priv_obj "$T/X/build/publish-milbridge.sh"
  CHK_MUST="kind=WITNESS-EXPIRED class=suspended path=$MBR_T witness=fp-locked+foreign-intermediate"; chk X FAIL "$T/X"

  # case Y：**必须 `NOINFO`** —— 新谓词的数据源**取不到**（镜像里把 `*.sh`/`*.py` 语料与
  #   `wpf-linux.sln` 都拿掉）⇒ `kind=WITNESS-UNCOMPUTABLE` ⇒ `rc=2`。
  #   ⚠️ 这一例是**为镜像/零件树**立的：那种树里"本仓没有构建入口"与"我没镜像构建入口"
  #      分不开 ⇒ 不许把后者读成前者的**绿**（`D-G29` 同族：算不出来不许冒充判定）。
  mirror "$T/Y"
  find "$T/Y" \( -name '*.sh' -o -name '*.py' \) -delete
  rm -f "$T/Y/$SLN_REL"
  CHK_MUST='kind=WITNESS-UNCOMPUTABLE'; chk Y NOINFO "$T/Y"

  echo "BHYGIENE_SELFTEST=$([ "$nf" -eq 0 ] && echo PASS || echo FAIL) cases=$((np + nf)) pass=$np fail=$nf"
  [ "$nf" -eq 0 ] && exit 0 || exit 1
fi

run_check
exit $?
