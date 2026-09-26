#!/usr/bin/env bash
#
# 主控 · 波 `#28` —— **`D-T5-R`（"整段全是隐形 run"的段落）的冻树牙齿**
#
# 【为什么需要它（`#25` 的欠账 + `#26`/`#27` 的裁决）】
#   `D-T5-R` 已修好（`build/MilBridge/W25A-report.md`：`hiddenonly` 四格 `rc=0` ∧ `A1/A2/A3` 全 PASS，
#   零世代成本），**但"修好"≠"有牙"**：`#25` 实测 `grep -r -- 'D5CbrProbe|hiddenonly'` 在
#   `verify-all.sh` 与**全部** `build/MilBridge/tools/*.sh` 里**仍是 0** ⇒ **今天没有任何门会因这条缺陷回归而变红**。
#   同族事故：`#21`（`Start` 列无牙 ⇒ `D-T6-c` 长期存活）、`#24`（帧列无牙 ⇒ 残余红无处登记）、
#   事故 `L26`（判据存在但没人跑 = 没有判据）。
#   `#26` 的对抗性审计另裁定：**`A1/A2/A3` 三条腿对"那个兜底是否真的是零宽"零判别力**
#   （本探针**从不读**任何几何）⇒ 本步的绿 **≠** "隐形语义已正确"（判别力边界见下，不许省）。
#
# 【本步判什么 —— 一句话】用现成探针 `build/MilBridge/tests/D5CbrProbe/`，在**关掉快路径**
#   （`--collapsible`）的条件下，把 8 个用例 × 2 档 × 2 模式 = **32 格**逐格与**预期判词表**比对；
#   **任一格不符 ⇒ 本步红**。预期表（**绿 28 格 / 预期红 4 格**）：
#     · 目标 `hiddenonly`（整段只有一个 `TextHidden(3)`）× 4 格 ⇒ **`GREEN`** —— 这是 `D-T5-R` 的本体；
#     · 阳性对照 `control`（纯 `TextCharacters`）与 `mod0`（零长 `TextModifier`）× 4 格 ⇒ **`GREEN`**；
#     · `eos1`/`mod1`/`hidden1`/`hiddenmid`（`#24` 修好的四例）× 4 格 ⇒ **`GREEN`**（防回归）；
#     · **`declaredgap` × 4 格 ⇒ 预期 `RED-LENGTH`** —— 它是**断言牙齿对照**（`Program.cs:371-380`：
#       源只声明 4 个码元、分母 `CpLength` 故意声明成 5）⇒ **它必须红**。
#       ⇒ 它证明 `A3`（码元账守恒）**不是空断言**：`A1/A2` 都 PASS 时 `A3` 仍能单独红。
#       ⛔ **这一格是"预期红"，不是失败** —— 谁把它改成"预期绿"就是**放宽断言**。
#
# 【为什么**必须** `--collapsible`（本步最重要的一条机制约束）】
#   生成物 `:546-549` 的快路径条件是 `!AlwaysCollapsible && previousLineBreak == null && lineLength <= 0`；
#   `AlwaysCollapsible=true` ⇒ 快路径关闭 ⇒ 逼被测 run 走「严格档 → 宽松档 → LineServices」三层。
#   **不带 `--collapsible` ⇒ `TextHidden` 被 `SimpleTextLine` 当 Ghost 处理 ⇒ 读出 GREEN**，
#   而那正是 `#23`/`#24A` 实测过的形态：**修前（缺陷活着）`hiddenonly` 也是 GREEN**
#   （`build/MilBridge/W24A-report.md` 修前×快路径开 = `GREEN`）⇒ **那是零判别力的假绿**。
#   ⇒ `--collapsible` 是**写死在脚本里的**，**不接受任何 env 关闭**。
#
# 【断言清单（11 条；缺一条本步都不算"有牙"）】
#   ① 装置自证：`--selftest abort` ⇒ `rc=134` 且标记**无** `T3` 收尾行；`--selftest null` ⇒ `rc=1`
#      且有 `T3` 且打 `verdict=RED-NULL`。任一不符 ⇒ `NOINFO`（装置分不开 abort 与 null ⇒ 读数不可信）。
#   ② 前置文件（工程/权威 `pc`/探针 dll）缺失 ⇒ `NOINFO`。
#   ③ 构建失败 ⇒ `NOINFO`（**"算不出"不是绿**）。
#   ④ **产物副本 == 权威件**：`bin/Release/PresentationCore.dll` 必须与
#      `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` **逐位相同**
#      （`D5CbrProbe.csproj:53` `HintPath` + `:54` `Private=true` ⇒ 产物目录里有一份副本；
#       不等 ⇒ 量的是**旧产物**，`D-A2` 那一族）。
#      先 `dotnet build`；仍不等 ⇒ **强制 `-t:Rebuild` 重试一次**（`#25` 实测过「内容变而 mtime 未变
#      ⇒ 增量判定跳过拷贝」的事故）；再不等 ⇒ `NOINFO`。
#   ⑤ 每格必须**自洽**：`rc=0 但没有 T3 收尾行` ⇒ 判 `FAIL`（"装置假退出"= 假绿的经典形态，
#      **只许加严**）；`rc=2`/有 T3 却无判词/超时 ⇒ `NOINFO`（算不出）。
#   ⑥ **判词与 `rc` 必须一致**（探针自己的法律 `Program.cs:182-183`）：`GREEN ⇒ rc=0`、`RED-* ⇒ rc=1`。
#   ⑦ 判词必须等于**预期判词**，且 `A1/A2/A3` 三项必须等于预期。
#   ⑧ **机制门（防假绿，只加在目标例上）**：`hiddenonly` 的每格必须满足
#      · `D5CBR LAYER` 行含 `快路径(SimpleTextLine)=**关**`（`Program.cs:200`），且
#      · `D5CBR ATTR` 行**不含** `两档零增量`（`Program.cs:430` 的 `NOINFO(两档零增量 ⇒ 这一例没走到托管档)`），且
#      · **`D5CBR DIAGafter` 的宽松档计数里 `relaxedParaDefaults` 必须由 0 变 ≥1**
#        ⇒ 这是**"兜底那条分支真的被走到"的运行期证据**（`#25` 的修法 = `paragraphProperties.DefaultTextRunProperties`
#          兜底；机制证 = 该计数器 `0 → 1`）。**光看 `rc=0` 不算**（`#26` 已裁定）。
#      ⇒ 任一不符 ⇒ **判 `FAIL`**（不是 NOINFO：那是判据退化，不是算不出）。
#   ⑨ **窄射程（只加在 6 个非目标用例上）**：`control`/`mod0`/`eos1`/`mod1`/`hidden1`/`hiddenmid`
#      每格的 `DIAGafter` 里 `relaxedParaDefaults` **必须 = 0** —— 即"新兜底分支**只**在全隐形段落上点火"。
#      依据（`#28` W28H 实测）：这 6 例 × 2 档 × 2 模式 = **24 格全部为 0**（含 12 格 `--nocatch`）。
#      ⇒ 若这条变红，说明产品侧行为**外溢**到别的段落形态上 ⇒ 是**行为变更**，不是噪声。
#      ⛔ 改这条的期望值 = 改判据面，必须与**产品改动同趟**改，并写进报告。
#   ⑩ **防恒绿退化**：`判定例 == 0` ⇒ `FAIL`（唯一例外：**每一格**都是探针自报 `rc=2` 的"算不出"
#      ⇒ `NOINFO`）。这条闸是"分母为 0 时 `红=0` 恒真"的解药。
#   ⑪ 全步期间**权威 `pc` 的 sha 不许变**（纪律 35/48）⇒ 变了 ⇒ `NOINFO`（本次读数不可归因）。
#   ⑫ **`rc=134` 的两种坏法必须可分（`#30` W30D 新增：判据面扩张，触发者是 `#29` W29C 的独立复核）**
#      —— 原实现只取**异常类型名**，而 `LoCreateContext` 只在**消息**里 ⇒ 那个归因分支是**死代码**、
#      每一格 `rc=134` 都被印成"不是 `D-T5-R` 的签名"（**包括真是它的时候**）。现在用**两个信号**：
#      **①** 标记文件（非空）是否**存在** —— 探针 `Program.cs:195` 进用例就落盘 ⇒ 缺 shim 时崩溃**早于**它；
#      **②** 异常类型名 ＋ **消息里有没有 `LoCreateContext`**。判法：
#        · 崩在**用例内** ＋ 消息含 `LoCreateContext` ⇒ `fail`（`失败`，点名"**真签名**"）
#        · 崩在**用例进入之前** ＋ 缺 shim 特征（`DllNotFoundException`/`libwpfwin32`/`WPF_LINUX_WIN32_SHIM`）
#          ⇒ **`st=absent` ⇒ 整步 `NOINFO`（rc=2）**：读数**不可归因**（与⑪同族）；
#          ⛔ 这不是绿（`run_step` 对 `rc≠0` 照样 `❌`），也**不是** `D-T5-R` 回归。
#        · 其余 ⇒ 仍 `fail`（红成立、归因待查）。逐格另印机器读标签 `signature=…`（小写键，见下）。
#      ⇒ 判据面扩张 ⇒ **`judge=` 版本由主控推**（本件只报需求）。
#
# 【三态与 rc 由谁决定（逐条写清，不许含糊）】
#   **全部 32 格都决定 rc**，无"只打印不判"的格；另加①②③④⑪五道 `NOINFO` 闸。
#   优先级（每格的 `st` 有四态：`ok` / `fail` / `misfire` / `absent`）：
#     · 格数不守恒（`判定例 + 假退出格 + 算不出格 != 32`）⇒ `NOINFO`（仪器没跑满 ⇒ 算不出）
#     · `判定例 == 0` 且 32 格**全部**是"探针自报 rc=2" ⇒ `NOINFO`（**算不出，不是绿**）
#     · `判定例 == 0`（其余情形）⇒ `FAIL`（**恒绿退化**：一格都没判过，"符合预期" 恒真）
#     · 有**假退出**格（`rc=0` 却无判词/无收尾 ⇒ **假装置**）⇒ `FAIL`
#       ⚠️ 这一档**故意压过** `NOINFO`（本工程既有约定是"NOINFO 压过红"，见 `frame-step.sh:116`）：
#          "一个 rc=0 且一字不吐的装置"**不是算不出**，是**假绿**；把它洗成 `NOINFO` 正好是
#          预登记禁止的那件事。⇒ **显式记录这条偏离**，供主控裁定。
#     · 有"算不出"的格（`rc=2` / 超时 / 有收尾却无判词 / **`rc=134` 且崩在用例进入之前＋缺 shim 特征**）⇒ `NOINFO`（**NOINFO 不许算绿**）
#     · 有 `FAIL` 格 ⇒ `FAIL`
#     · 否则 `PASS`（`rc=0` **只在 32 格全绿/全按预期红时**给出）
#   ⛔ `NOINFO` **不许算绿** ⇒ `rc=2`（与 `pc-line-step.sh`/`frame-step.sh` 同族）。
#
# 【本步**不**覆盖什么（判别力边界，必须与读数一起读）】
#   · `A1/A2/A3` 对"占位字符是否**真零宽**"**零判别力** —— 本探针**从不读** `line.Width` 或任何几何
#     （`Program.cs:566-567` 的注释：几何一概不量）。
#   · 冻结语料**不含全隐形段落** ⇒ **"能否转绿"可测、"转绿是否对"本仓不可测**（要真机重录，`D-T7`）。
#   · 探针 dll ↔ `Program.cs` 是否同步**不判**（与 `pc-line-step.sh`/`frame-step.sh` 同口径）。
#   ⛔ **不许**把本步的绿读成"隐形语义已正确"。
#
# 【为什么必须把结论行打到 stdout】
#   `verify-all.sh` 的 `run_step`：**绿分支**只回显匹配 `^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO)( |$)`
#   的行（`#26` W26B 的 `D-G10`），**失败分支**跑宽 grep `[A-Z][A-Z0-9_]*=(FAIL|NOINFO)` 抓诊断。
#   ⇒ 本脚本**必须自报 ASCII 键的结论行**（`HIDDEN_ONLY_STEP=PASS|FAIL|NOINFO`），否则屏上只有一个 ✅；
#     而**逐格**那行故意用探针自己的**非 ASCII 键**（`A1非null=` / `A3长度一致=`）⇒ 对那条宽 grep
#     **0 命中**，于是 `declaredgap` 的**预期红**不会被屏上误印成故障（`#26` W26E 实测）。
#
# 【成本（实测口径）】
#   32 格 + 2 次装置自检 = 34 次进程；每格一次 `dotnet <小控制台 dll>`（一例一进程是**必须**的：
#   失败模式是**进程级 abort**，塞进一个进程会让第一个 abort 带走其余全部 ⇒ 后面的例"没跑过"
#   却长得像"没红"，`D-R3` 那一族）。
#   `#28` W28H 实测：每格 **3.2–3.7 s**；整步 ≈ **110–160 s**；峰值 RSS ≈ 0.4–0.7 GB（`dotnet build` 占大头）。
#   ⚠️ **`#29` W29C 独立复核（`$HOME/w29c-report.md 083fdf2e7837534f`）实测**：单步
#      `WALL 102.80 / 101.07 s`、峰值 `RSS 791,060 / 783,732 KB`、**35 次 `dotnet`/趟**
#      （1 次 build ＋ 2 次装置自检 ＋ 32 格）⇒「**本步是一个构建者**」已被**两次独立测量**证实，
#      而**不是**估算（接线与否由主控权衡：它与「构建者独占」纪律冲突）。
#   ⚠️ **它要不要重建 harness：要**（`D5CbrProbe.csproj:53-54` `HintPath`+`Private=true`
#      ⇒ 必须让产物副本跟住权威 `pc`）⇒ **本步是一个构建者**：会起 1 个 `dotnet build`
#      （旗标 `-m:1` + `DOTNET_gcServer=0`）⇒ **不许与其它构建者并发**。
#
# 【反极性（`--selftest`，≥5 档，**必须实测**）】
#   `--selftest` 用**自生成替身**（写在 `mktemp -d` 里，**仓内不留件**）+ **真实旧产物**证明本牙能红：
#     S1  替身 green             ⇒ 期望 `rc=0`（**控住"红是装置造成的"这个替代解释**）
#     S2  替身 abort（目标例）    ⇒ 期望 `rc=1`（真红）
#     S3  替身 silent（rc=0 无输出、不落标记）⇒ 期望 `rc=1`（**判定例=0 / 假装置 ⇒ FAIL**，防恒绿闸活）
#     S4  替身 absent（每格 rc=2）⇒ 期望 `rc=2`（**算不出 ⇒ 不是绿**）
#     S5  替身 fakegreen_dg      ⇒ 期望 `rc=1`（**放宽 A3 对照 ⇒ 假绿被抓**）
#     S6  替身 fakegreen_fp      ⇒ 期望 `rc=1`（**快路径开 + 假绿 ⇒ 机制门活**）
#     S7  替身 mechzero          ⇒ 期望 `rc=1`（接手链 `NOINFO(两档零增量)` ⇒ 机制门活）
#     S8  替身 rcmismatch        ⇒ 期望 `rc=1`（判词 GREEN 而 rc=1 ⇒ 判词/rc 一致性闸活）
#     S9  替身 wrongverdict      ⇒ 期望 `rc=1`（目标例给出预期外的 `RED-LENGTH`）
#     S10 替身 selftestbad       ⇒ 期望 `rc=2`（**装置自证失败 ⇒ NOINFO**）
#     S11 前置件缺失（`HIDDEN_ONLY_DLL` 指向不存在的文件）⇒ 期望 `rc=2`
#     S12 **真实旧产物**（`D-T5-R` 修前的 `pc`，见 `HIDDEN_ONLY_OLDPC`）⇒ 期望 `rc=1`，
#         且**目标 4 格必须全部在红名单里**、`不符 >= 4`。
#         ⚠️ **不要求"恰 4 格红"**：旧世代 `pc` **没有** `relaxedParaDefaults` 字段（那是 `#25` 修法
#         新增的）⇒ 6 个对照例 × 4 格 = **24 格**会按"窄射程不可测 ⇒ 静默关牙不许当绿"也判红
#         （实测 `不符=28`）。`#26` W26E 的草稿写"恰 4 格"，**在旧世代产物上不成立**。
#     S13 **对照组**：私目录里放**权威 `pc` 的副本** ⇒ 期望 `rc=0`
#         （证明 S12 的红**不是私目录装置本身**造成的）—— 它同时是**装置健全性闸**
#         （私目录缺 `WPF_LINUX_WIN32_SHIM` 时它会红：那时每一格都因 `DllNotFoundException` abort）。
#     S14 **放宽断言副本**（`sed` 只摘掉「机制门」那一块）× 替身 `mechzero`
#         ⇒ 期望 `rc=0`（**假绿**）—— 与 S7 原脚本的 `rc=1`（**真红**）构成**成对读数**。
#         ⚠️ 这一档**故意不用**真实旧产物：旧产物没有该字段 ⇒ 副本**不可能**假绿（实测仍 `rc=1`）。
#   ⛔ 每档都**只**在 `mktemp -d` 私目录里动文件：**真树一个字节都不改**（血案教训：**绝不用 `ln`**）。
#   ⛔ 若 `HIDDEN_ONLY_OLDPC` 指的文件不在盘上 ⇒ S12/S13/S14 打 `未取到` 并计入 `skip=`，
#      **不许**把它们洗成通过（汇总行里**看得见**）。
#
# 【极性 seam（四个 env + 一个只给 selftest 的落点 seam）】
#   `HIDDEN_ONLY_PROBE`（默认 `dotnet`）｜`HIDDEN_ONLY_DLL`（默认产物目录里的探针 dll）
#   ｜`HIDDEN_ONLY_AUTH_PC`（默认树里权威 `pc`）｜`HIDDEN_ONLY_OLDPC`（只给 `--selftest` 用）
#   ｜`HIDDEN_ONLY_ROOT`（只给 `--selftest` 生成的"放宽副本"用：副本落在 `mktemp -d` 里，
#     它自己算不出 `../../..` ⇒ 必须显式指回真树。**它只改"读哪棵树"，不改任何判据**）。
#   前三个任一被设置 ⇒ `极性模式=1`：**跳过构建与④/⑪两道闸**（因为极性就是要用**别的**产物），
#   并在屏上打横幅、在末行标 `极性模式=是` ⇒ **不可静默使用**。
#   ⚠️ **装置自检①在极性模式下照跑**（比 `#26` 的草稿更严：那条 seam 少了这一道）。
#   ⛔ `--collapsible` **不可**被 env 关掉；⛔ 预期判词表**不可**被 env 改。
#
# 三态：rc=0 判据通过｜rc=1 判据**红**（任一格不符 / 恒绿退化 / 假装置）｜rc=2 `NOINFO`（算不出）。
set -uo pipefail

ROOT="${HIDDEN_ONLY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
# ★ `#39` 阶段 2/3：读**权威件**的路径必须跟随**唯一声明**（`build/SelfBuiltConfig.props`）。
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../../build/selfbuilt-config.sh"
# ⚠️ `--selftest` 会用 `bash "$SELF"` **重入本脚本** ⇒ 必须先把自身解析成**绝对路径**：
#    否则"相对 `$0` ＋ 已经 `cd` 过"会让重入变成 `rc=127`（= 命令没找到），
#    而"装置根本没跑"会被读成"判据红"。⇒ 现场解一次，之后一律用 `$SELF`。
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
cd "$ROOT" || exit 2
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
# 内存纪律：**所有** dotnet 命令 `-m:1` + `DOTNET_gcServer=0`
export DOTNET_gcServer=0

PROJ_DIR="$ROOT/build/MilBridge/tests/D5CbrProbe"
PROJ="$PROJ_DIR/D5CbrProbe.csproj"
OUT="$PROJ_DIR/bin/Release"
AUTH_PC="${HIDDEN_ONLY_AUTH_PC:-$ROOT/build/PresentationCore.Linux/bin/$SELFBUILT_CONFIG/PresentationCore.dll}"
LOGDIR="${HIDDEN_ONLY_LOGDIR:-/tmp/hidden-only-step}"

RUNNER="${HIDDEN_ONLY_PROBE:-dotnet}"
PROBE_DLL="${HIDDEN_ONLY_DLL:-$OUT/PresentationCore.Tests.dll}"
POLARITY=0
[ -n "${HIDDEN_ONLY_PROBE:-}" ] && POLARITY=1
[ -n "${HIDDEN_ONLY_DLL:-}" ] && POLARITY=1
[ -n "${HIDDEN_ONLY_AUTH_PC:-}" ] && POLARITY=1

TIERS="strict lenient"
MODES="catch nocatch"
ALL_CASES="control eos1 hidden1 mod1 hiddenmid hiddenonly mod0 declaredgap"
TARGET_CASE="hiddenonly"
ASSERT_CTRL_CASE="declaredgap"
NARROW_CASES="control eos1 hidden1 mod1 hiddenmid mod0"
EXPECT_TOTAL=32

sha16() { [ -f "$1" ] && sha256sum "$1" | cut -c1-16 || echo "MISSING"; }

# ═══════════════════════════════════════════════════════════════════════════════════════
#  --selftest：反极性（自生成替身 + 真实旧产物）
# ═══════════════════════════════════════════════════════════════════════════════════════
if [ "${1:-}" = '--selftest' ]; then
    # ── 【`D-G41` 判据件自证】本件在**自测期间**被改写 ⇒ 本趟读数**不可归因**（`NOINFO`：不许当绿、不许冒充绿）──
    #   本件自测以 `bash "$SELF"` **重入自己**（`:304`/`:321`/`:338`/`:351`），还会 `sed … "$SELF" > $T/relaxed.sh`
    #   拿**自己当前的正文**派生一份"该红的"变体（`:378`）⇒ bash 每次为新子进程从磁盘**重读**本件 ⇒
    #   **改件窗口里出的红是凭空的红**。口径：**开头记 sha16、结尾再算一次**；不等 ⇒ `ST_ATTEST=NOINFO`
    #   并点名（含 sha0/sha1 与内层 rc），统一 **rc=2**（`NOINFO` 码，不与 `FAIL` 混）。
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
    # 【`TASK-0737`／`D-G137` 修法：**默认路径不许指向车道目录**】
    #   原默认值写死本件出生那条车道的备份目录（`HIDDEN_ONLY_OLDPC` 的兜底）⇒ 落仓后每次
    #   `--selftest` 都去**一条已失效车道**的目录里取夹具（跨车道读 ⇒ 证据与读数脱钩）。
    #   改为**只认调用者显式给的** `HIDDEN_ONLY_OLDPC`；未给 ⇒ `:352` 的 `! -f` 分支照旧
    #   逐例打「未取到」并计入 `skip=`。
    #   ⚠️ 历史夹具（那次 `D-T5-R` 修前的 `pc`）**不再写进件内**：它是**取证物**，出处记在
    #   `build/MilBridge/lane-path-provenance.tsv` 的 `# RETIRED` 记录里（声明的**唯一**去处），
    #   件内不留陈旧指针；谁重建了那个产物 ⇒ 射程即可恢复。
    OLDPC="${HIDDEN_ONLY_OLDPC:-}"
    # 【`#75` 主控裁定（必须**显式可见**）：射程缩减不许被读成"全射程通过"】
    #   `SKIP_*` 家族对 X 相关跳过已有"这不是绿"的先例 ⇒ 这里同办：判词行尾**必须**带上
    #   `range-reduced reason=…`。三态语义（**不许恒挂**）：
    #     · `OLDPC` 为空（**落仓后的常态**）⇒ `reason=oldpc-not-in-repo`（夹具在仓外车道，已移出）；
    #     · `OLDPC` 非空但不在盘上（**调用者给了错路径**）⇒ `reason=oldpc-not-on-disk`（另一种病，分开报）；
    #     · 在盘上 ⇒ **无该后缀**（射程完整）。
    OLDPC_NOTE=""
    if [ -z "$OLDPC" ]; then OLDPC_NOTE=" range-reduced reason=oldpc-not-in-repo"
    elif [ ! -f "$OLDPC" ]; then OLDPC_NOTE=" range-reduced reason=oldpc-not-on-disk path=$OLDPC"; fi
    T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
    np=0; nf=0; nsk=0

    # ── 替身（自生成；**仓内不留件**） ─────────────────────────────────────────────
    STUB="$T/stub.sh"
    cat > "$STUB" <<'STUBEOF'
#!/usr/bin/env bash
set -u
# 参数形状：<dll名> --case X --tier Y --collapsible --marker M [--nocatch]  或  <dll名> --selftest abort|null --marker M
MODE="${STUB_MODE:-green}"
# ⚠️ **一遍解析完所有参数**（本脚本自己踩过两次）：
#    ① 分两遍解析时，第一遍把位置参数吃空 ⇒ `--case` 永远读不到 ⇒ 每一格都被当成"未知用例"；
#    ② 同理，吃空之后再 `case " $* "` 就永远匹配不到 `--selftest null` ⇒ 装置自证恒为"失败"
#       ⇒ 每一档都被洗成 NOINFO（"装置没跑"被读成"算不出"）。
#    ⇒ 先解析、再用**存下来的** `$ALL` 分派，这两个坑一次堵掉。
ALL=" $* "
c=""; tier=""; marker=""; nc=0
while [ $# -gt 0 ]; do
    case "$1" in
        --case)    c="${2:-}"; shift 2 ;;
        --tier)    tier="${2:-}"; shift 2 ;;
        --marker)  marker="${2:-}"; shift 2 ;;
        --nocatch) nc=1; shift ;;
        *) shift ;;
    esac
done
mk() { [ -n "$marker" ] && printf '%s\n' "$1" >> "$marker"; }
case "$ALL" in
  *' --selftest abort '*)
      case "$MODE" in selftestbad) exit 0 ;; esac
      exit 134 ;;
  *' --selftest null '*)
      case "$MODE" in
        selftestbad) exit 0 ;;
        *) printf 'D5CBR VERDICT case=selftest tier=- verdict=RED-NULL\n'; mk 'T3 done verdict=RED-NULL'; printf 'D5CBR_EXIT=1\n'; exit 1 ;;
      esac ;;
esac
[ "$MODE" = silent ] && exit 0
mk "T1 before FormatLine#1 index=0"
rc=0; verdict="GREEN"; a1=PASS; a2=PASS; a3=PASS; layer="**关**"; attr="接手链=严格档**接手**"; rpd=0
case "$MODE:$c" in
  absent:*)                 verdict=NOINFO; rc=2 ;;
  fakegreen_dg:declaredgap) verdict=GREEN; rc=0 ;;
  fakegreen_fp:hiddenonly)  layer="**开**"; verdict=GREEN; rc=0 ;;
  mechzero:hiddenonly)      attr="接手链=NOINFO(两档零增量 ⇒ 这一例没走到托管档)"; verdict=GREEN; rc=0 ;;
  rcmismatch:hiddenonly)    verdict=GREEN; rc=1 ;;
  wrongverdict:hiddenonly)  verdict=RED-LENGTH; a3=FAIL; rc=1 ;;
  abort:hiddenonly)         exit 134 ;;
  green:hiddenonly)         rpd=1 ;;
esac
if [ "$c" = hiddenonly ] && [ "$MODE" = green ]; then rpd=1; fi
if [ "$c" = declaredgap ] && [ "$MODE" != fakegreen_dg ]; then verdict=RED-LENGTH; a3=FAIL; rc=1; rpd=0; fi
printf 'D5CBR CASE  case=%s tier=%s effective=严格档(HbTextFallback)\n' "$c" "$tier"
printf 'D5CBR LAYER 快路径(SimpleTextLine)=%s（/替身/）\n' "$layer"
# ⚠️ **两条** DIAG 行都要打：脚本用 `head -1` 取"调用前"、`tail -1` 取"调用后"
#    （真探针 Program.cs:223-224 打 DIAGbefore、:281-282 打 DIAGafter）
printf 'D5CBR DIAGbefore lenient{relaxedCalls=0 relaxedHandled=0 relaxedFailed=0 relaxedParaDefaults=0}\n'
printf 'D5CBR DIAGafter  lenient{relaxedCalls=1 relaxedHandled=1 relaxedFailed=0 relaxedParaDefaults=%s}\n' "$rpd"
printf 'D5CBR ATTR  case=%s tier=%s %s\n' "$c" "$tier" "$attr"
printf 'D5CBR ASSERT case=%s tier=%s A1非null=%s A2无LoCreateContext=%s A3长度一致=%s（Σ=4 期望=4）\n' "$c" "$tier" "$a1" "$a2" "$a3"
printf 'D5CBR VERDICT case=%s tier=%s verdict=%s 行数=1 Σlen=4 Σnl=1 Σ可见长=3 期望=3 异常=-\n' "$c" "$tier" "$verdict"
mk "T3 done verdict=$verdict rc=$rc"
printf 'D5CBR_EXIT=%s\n' "$rc"
exit "$rc"
STUBEOF
    chmod +x "$STUB"

    # ── 私目录装置：**真拷贝**（`cp -a`），⛔ 绝不用 `ln`（血案：硬链接写穿真树） ──────
    #   ⚠️ **血案级教训（`#28` W28H 实测踩到）**：私目录里**没有** `libwpfwin32.so`，而 shim 的
    #     自动探测是**从 app 目录往上找仓** ⇒ 私目录找不到 ⇒ 每一格都在
    #     `FontCacheUtil` 里 `DllNotFoundException: user32.dll → libwpfwin32.so 没找到` 而 **abort(134)**。
    #     ⇒ 那会让**全部 32 格**变红，而 `rc=134` 恰好**也是** `hiddenonly --nocatch` 的真签名
    #       ⇒ **只看 `rc` 这一层**分不开两者。⇒ 必须显式给 `WPF_LINUX_WIN32_SHIM`
    #       （`build/shims/Win32ShimResolver.cs:65` 的 `ShimPathEnv`），并用 S13 当**装置健全性对照**。
    #     ⚠️ **`#29` W29C 独立复核更正**：「假红与真红**不可分**」作为**结论**是**错的** —— 两个可分
    #       信号本来就在本脚本自己的产物里（**标记文件是否被创建**：缺 shim ⇒ 崩溃早于 `Program.cs:195`
    #       的 `Mark`、stdout 停在 `D5CBR TIER` 而无 `D5CBR CASE`；**异常签名**：`DllNotFoundException`
    #       vs 消息含 `LoCreateContext`）。⇒ 本趟（`#30` W30D）已把它升级成**判据**（断言⑫）。
    SHIM="$ROOT/src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
    SHIM_OK=0; [ -f "$SHIM" ] && SHIM_OK=1
    RIG=""
    RIG_BASE_SHA=""
    if [ -f "$OUT/PresentationCore.Tests.dll" ]; then
        mkdir -p "$T/rig" && cp -a "$OUT/." "$T/rig/" && RIG="$T/rig"
    fi
    # 私目录里 pc 的初始 sha（= 权威件的副本）；用于**复原证**
    [ -n "$RIG" ] && RIG_BASE_SHA="$(sha16 "$RIG/PresentationCore.dll")"

    chk() {  # $1=编号 $2=期望rc $3=说明 $4..=env 赋值 + 命令
        local num="$1" want="$2" desc="$3"; shift 3
        local out rc got
        out="$( "$@" 2>&1 )"; rc=$?
        got="$(printf '%s' "$out" | sed -n 's/^HIDDEN_ONLY_STEP=\([A-Z]*\).*/\1/p' | tail -1)"
        if [ "$rc" = "$want" ]; then
            np=$((np+1)); printf 'HIDDEN_ONLY_SELFTEST case=%s expect_rc=%s got_rc=%s got=%s => yes  ｜ %s\n' "$num" "$want" "$rc" "${got:-无结论行}" "$desc"
        else
            nf=$((nf+1)); printf 'HIDDEN_ONLY_SELFTEST case=%s expect_rc=%s got_rc=%s got=%s => NO   ｜ %s\n' "$num" "$want" "$rc" "${got:-无结论行}" "$desc"
        fi
        printf '%s\n' "$out" > "$T/$num.out"
    }
    chk_skip() { nsk=$((nsk+1)); printf 'HIDDEN_ONLY_SELFTEST case=%s => SKIP（未取到）｜ %s\n' "$1" "$2"; }

    # S1..S10：自生成替身（**零 dotnet**）—— 每档一行：编号|期望rc|替身模式|说明
    while IFS='|' read -r num want mode desc; do
        [ -n "$num" ] || continue
        chk "$num" "$want" "$desc" env HIDDEN_ONLY_LOGDIR="$T/log-$num" \
            HIDDEN_ONLY_PROBE="$STUB" HIDDEN_ONLY_DLL="$OUT/PresentationCore.Tests.dll" \
            STUB_MODE="$mode" bash "$SELF"
    done <<'SPECEOF'
S1|0|green|替身全绿 ⇒ 本步必须 rc=0（控住『红是装置造成的』这个替代解释）
S2|1|abort|目标例进程级 abort ⇒ 必须 rc=1
S3|1|silent|替身 rc=0 且一字不吐、不落标记 ⇒ 必须 rc=1（判定例=0 ⇒ 防恒绿闸活）
S4|2|absent|每格自报 rc=2 ⇒ 必须 rc=2（算不出不是绿）
S5|1|fakegreen_dg|declaredgap 假绿 ⇒ 必须 rc=1（A3 对照被放宽 ⇒ 抓住）
S6|1|fakegreen_fp|目标例快路径=开且假绿 ⇒ 必须 rc=1（机制门活）
S7|1|mechzero|接手链=两档零增量 ⇒ 必须 rc=1（机制门活）
S8|1|rcmismatch|判词 GREEN 而 rc=1 ⇒ 必须 rc=1（判词/rc 一致性闸活）
S9|1|wrongverdict|目标例给预期外的 RED-LENGTH ⇒ 必须 rc=1
S10|2|selftestbad|装置自证失败 ⇒ 必须 rc=2（NOINFO 不许当绿）
SPECEOF

    # S11：前置件缺失 ⇒ NOINFO
    chk "S11" 2 "前置件缺失（HIDDEN_ONLY_DLL 指向不存在的文件）⇒ 必须 rc=2" \
        env HIDDEN_ONLY_LOGDIR="$T/log-S11" HIDDEN_ONLY_PROBE="dotnet" \
        HIDDEN_ONLY_DLL="$T/does-not-exist.dll" bash "$SELF"

    # S12/S13/S14：**真实旧产物**（`D-T5-R` 修前）与对照
    if [ -z "$RIG" ]; then
        chk_skip S12 "私目录装置建不起来（探针产物目录不存在）"
    elif [ "$SHIM_OK" != 1 ]; then
        chk_skip S12 "私目录装置不可用：缺 shim（$SHIM）⇒ 私目录里**每一格都会因 DllNotFoundException 而 abort**，读数不可归因"
    elif [ ! -f "$OLDPC" ]; then
        chk_skip S12 "旧产物不在盘上：$OLDPC"
    else
        # 先**记原 sha**，换上旧产物，跑，再**逐字节复原**并 `cmp` 证
        ORIG="$T/pc.orig"; cp -p "$RIG/PresentationCore.dll" "$ORIG"
        cp -p "$OLDPC" "$RIG/PresentationCore.dll"
        OLD_SHA="$(sha16 "$RIG/PresentationCore.dll")"
        chk "S12" 1 "真实旧产物（D-T5-R 修前 pc=$OLD_SHA）⇒ 必须 rc=1 且 不符>=4 且**目标 4 格全在红名单里**（⚠️ **不要求「恰 4 格红」**：旧世代 pc **没有** relaxedParaDefaults 字段 ⇒ 6 个对照例 × 4 格 = 24 格按「窄射程不可测」也判红 —— W29C 实测 不符=28）" \
            env HIDDEN_ONLY_LOGDIR="$T/log-S12" HIDDEN_ONLY_PROBE="dotnet" \
            WPF_LINUX_WIN32_SHIM="$SHIM" \
            HIDDEN_ONLY_DLL="$RIG/PresentationCore.Tests.dll" bash "$SELF"
        S12_BAD="$(grep -a '^HIDDEN_ONLY_STEP 口径 ' "$T/S12.out" | sed -n 's/.*不符=\([0-9]*\).*/\1/p' | head -1)"
        # 复原 + `cmp` 逐字节证
        cp -p "$ORIG" "$RIG/PresentationCore.dll"
        if cmp -s "$ORIG" "$RIG/PresentationCore.dll" && [ "$(sha16 "$RIG/PresentationCore.dll")" = "$RIG_BASE_SHA" ]; then
            np=$((np+1)); printf 'HIDDEN_ONLY_SELFTEST case=S12-restore expect=IDENTICAL got=IDENTICAL => yes  ｜ cmp 逐字节复原（%s）\n' "$RIG_BASE_SHA"
        else
            nf=$((nf+1)); printf 'HIDDEN_ONLY_SELFTEST case=S12-restore expect=IDENTICAL got=DIFF => NO\n'
        fi
        # S13：同一私目录里换回**权威 pc 的副本** ⇒ 必须 rc=0（证明红不是私目录造成）
        chk "S13" 0 "对照：私目录里放权威 pc 的副本 ⇒ 必须 rc=0（**这是装置健全性闸**：私目录缺 shim 时它会红）" \
            env HIDDEN_ONLY_LOGDIR="$T/log-S13" HIDDEN_ONLY_PROBE="dotnet" \
            WPF_LINUX_WIN32_SHIM="$SHIM" \
            HIDDEN_ONLY_DLL="$RIG/PresentationCore.Tests.dll" bash "$SELF"
        # ⚠️ **不要求"恰 4 格红"**（`#26` W26E 的草稿这么要求，`#28` W28H 实测**不成立**）：
        #   旧世代 pc **没有** `relaxedParaDefaults` 字段 ⇒ 6 个对照例 × 4 格 = **24 格**会因
        #   "窄射程维度不可测"而红（`#24` 世代的 pc 上 `不符合=28`，不是 4）。
        #   ⇒ 判据改成两条**可归因**的：① 目标 4 格**必须在红名单里**；② 不符 >= 4。
        S12_BADLIST="$(grep -a '^HIDDEN_ONLY_STEP=FAIL' "$T/S12.out" | head -1)"
        s12_miss=0
        for tg in strict.catch strict.nocatch lenient.catch lenient.nocatch; do
            case "$S12_BADLIST" in *"hiddenonly.$tg"*) ;; *) s12_miss=$((s12_miss+1));; esac
        done
        printf 'HIDDEN_ONLY_SELFTEST S12 口径 不符=%s（旧世代 pc 无 relaxedParaDefaults ⇒ 对照例 24 格按"窄射程不可测"也判红 ⇒ 期望 >=4 且目标 4 格必在内）\n' "${S12_BAD:-未取到}"
        if [ "${S12_BAD:-x}" = x ] || [ "${S12_BAD:-0}" -lt 4 ] || [ "$s12_miss" != 0 ]; then
            nf=$((nf+1)); printf 'HIDDEN_ONLY_SELFTEST case=S12-attrib => NO（不符=%s 目标缺格=%s ⇒ 红的**归因不精确**）\n' "${S12_BAD:-未取到}" "$s12_miss"
        else
            np=$((np+1)); printf 'HIDDEN_ONLY_SELFTEST case=S12-attrib expect=目标4格全在红名单 got=全在 => yes  ｜ 不符=%s\n' "$S12_BAD"
        fi
    fi

    # S14：**放宽断言副本** ⇒ 假绿（极性③的**成对读数**）
    #   做法：只把「机制门」那一整块断言的条件改成 `false`（`sed` 生成副本，落在 `mktemp -d` 里），
    #   与替身 `mechzero`（目标例看起来 GREEN，但接手链自报 `两档零增量`）配对：
    #     · 原脚本 ⇒ 机制门响 ⇒ **rc=1 真红**
    #     · 放宽副本 ⇒ 机制门被摘掉 ⇒ **rc=0 假绿**
    #   ⚠️ 副本落在 `mktemp -d` 里 ⇒ 它自己算不出 `../../..` ⇒ 用 `HIDDEN_ONLY_ROOT` 指回真树。
    #   ⚠️ 这一档**故意不用**真实旧产物：旧世代 pc **没有** `relaxedParaDefaults` 字段 ⇒
    #      6 个对照例会因"窄射程不可测"而红 ⇒ 副本**不可能**假绿（`#28` W28H 实测：
    #      去 `--collapsible` 的那版副本在旧产物上仍 rc=1）。⇒ 成对读数要用**能假绿**的装置。
    sed -e 's/\[ "\$c" = "\$TARGET_CASE" \]/false/' "$SELF" > "$T/relaxed.sh"
    chmod +x "$T/relaxed.sh"
    if cmp -s "$SELF" "$T/relaxed.sh"; then
        chk_skip S14 "放宽副本与原件逐字节相同（sed 没命中）⇒ 该档无意义"
    else
        chk "S14" 0 "放宽断言副本（**只摘掉机制门**）× 替身 mechzero ⇒ 必须 rc=0（**假绿**；与 S7 原脚本的 rc=1 真红成对）" \
            env HIDDEN_ONLY_LOGDIR="$T/log-S14" HIDDEN_ONLY_ROOT="$ROOT" HIDDEN_ONLY_PROBE="$STUB" \
            HIDDEN_ONLY_DLL="$OUT/PresentationCore.Tests.dll" STUB_MODE=mechzero bash "$T/relaxed.sh"
        printf 'HIDDEN_ONLY_SELFTEST S14 成对读数 原脚本(S7)=rc=1 真红 ｜ 放宽副本=rc=%s 假绿\n' \
            "$(env HIDDEN_ONLY_LOGDIR="$T/log-S14b" HIDDEN_ONLY_ROOT="$ROOT" HIDDEN_ONLY_PROBE="$STUB" HIDDEN_ONLY_DLL="$OUT/PresentationCore.Tests.dll" STUB_MODE=mechzero bash "$T/relaxed.sh" >/dev/null 2>&1; echo $?)"
    fi

    echo "HIDDEN_ONLY_SELFTEST=$([ "$nf" -eq 0 ] && echo PASS || echo FAIL) cases=$((np+nf)) pass=$np fail=$nf skip=$nsk${OLDPC_NOTE:-}"
    [ "$nf" -eq 0 ] && exit 0 || exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════════════════
#  正常模式（**`#31` 已接线** = `verify-all.sh` 的第 `[13]` 步；⚠️ 步号按**现件 21 步**口径 ——
#  `#30` W30D 落地时是 18 步；`#31` 一次接三件（`[13]` 本件 ＋ `[14]` `COLUMN-FLOOR` ＋
#  `[15]` `QUOTE-TRAP`）⇒ 步数 **18 → 21**。⚠️ **改步必同趟改**本行）
# ═══════════════════════════════════════════════════════════════════════════════════════

# ── 断言②：前置件 ────────────────────────────────────────────────────────────────
for f in "$PROJ" "$AUTH_PC" "$PROBE_DLL"; do
    [ -f "$f" ] || { echo "HIDDEN_ONLY_STEP=NOINFO 缺文件：$f"; exit 2; }
done
mkdir -p "$LOGDIR" || { echo "HIDDEN_ONLY_STEP=NOINFO 建不了日志目录：$LOGDIR"; exit 2; }
PROBE_DIR="$(cd "$(dirname "$PROBE_DLL")" && pwd)" || { echo "HIDDEN_ONLY_STEP=NOINFO 探针目录不可达：$PROBE_DLL"; exit 2; }
PROBE_BASE="$(basename "$PROBE_DLL")"

# 读数必须连 artifact+字段+sha 一起写
# ⚠️ 所有 echo 串里**不许出现反引号**（双引号里的反引号会被做成命令替换 —— `#24` 踩过）
echo "HIDDEN_ONLY_STEP 仪器 探针 Program.cs = $(sha16 "$PROJ_DIR/Program.cs")（本步**不判**它与 dll 是否同步）"
echo "HIDDEN_ONLY_STEP 仪器 探针 dll        = $(sha16 "$PROBE_DLL")（⚠️ 随被测 pc 换代而变：HintPath+Private=true 内嵌副本）"
PC_AT_START="$(sha16 "$AUTH_PC")"
echo "HIDDEN_ONLY_STEP 被测 pc（树）        = $PC_AT_START  路径=$AUTH_PC"
echo "HIDDEN_ONLY_STEP 日志目录             = $LOGDIR"
if [ "$POLARITY" = 1 ]; then
    echo "HIDDEN_ONLY_STEP ⚠️ 极性模式=是：runner=$RUNNER  dll=$PROBE_DLL"
    echo "HIDDEN_ONLY_STEP ⚠️ 极性模式**跳过**构建与 副本==权威 闸、跳过 被测 pc 不变 闸；装置自检照跑"
fi

# ── 断言③④：构建 + 产物副本 == 权威件 ─────────────────────────────────────────
if [ "$POLARITY" = 0 ]; then
    dotnet build "$PROJ" -c Release -m:1 --nologo -v q >"$LOGDIR/build.log" 2>&1 \
        || { echo "HIDDEN_ONLY_STEP=NOINFO 构建失败 ⇒ 算不出，不是绿（见 $LOGDIR/build.log）"; exit 2; }
    S_AUTH="$(sha16 "$AUTH_PC")"; S_COPY="$(sha16 "$PROBE_DIR/PresentationCore.dll")"
    if [ "$S_COPY" != "$S_AUTH" ]; then
        echo "HIDDEN_ONLY_STEP 产物副本（$S_COPY）!= 权威（$S_AUTH）⇒ 强制 -t:Rebuild 重试一次"
        echo "HIDDEN_ONLY_STEP   （依据：W25A 实测过增量判定跳过拷贝的事故：内容变而 mtime 未变）"
        dotnet build "$PROJ" -c Release -m:1 --nologo -v q -t:Rebuild >"$LOGDIR/build-rebuild.log" 2>&1 \
            || { echo "HIDDEN_ONLY_STEP=NOINFO 强制重建失败 ⇒ 算不出（见 $LOGDIR/build-rebuild.log）"; exit 2; }
        S_COPY="$(sha16 "$PROBE_DIR/PresentationCore.dll")"
    fi
    if [ "$S_COPY" = "MISSING" ] || [ "$S_COPY" != "$S_AUTH" ]; then
        echo "HIDDEN_ONLY_STEP=NOINFO 产物目录里的 pc 副本与权威件不符：copy=$S_COPY auth=$S_AUTH"
        echo "HIDDEN_ONLY_STEP   ⇒ 量到的会是一份**旧产物**（D-A2 那一族）⇒ 算不出，不是绿"
        exit 2
    fi
    echo "HIDDEN_ONLY_STEP 被测 pc（副本）      = $S_COPY（copy == auth ✓）"
else
    S_COPY="$(sha16 "$PROBE_DIR/PresentationCore.dll")"
    echo "HIDDEN_ONLY_STEP 极性模式：副本=$S_COPY 权威=$PC_AT_START（**故意允许不符**）"
fi

# ── 断言①：装置自证（abort 与 null 必须可分辨；**极性模式也跑**） ───────────────
ST_A="$LOGDIR/selftest-abort"; ST_N="$LOGDIR/selftest-null"
rm -f "$ST_A.marker" "$ST_N.marker"
# ulimit -c 0：abort 会转储核心，别拿几百 MB 磁盘换一个已知会 abort 的自检
( cd "$PROBE_DIR" && ulimit -c 0 && timeout 120 "$RUNNER" "$PROBE_BASE" --selftest abort --marker "$ST_A.marker" ) >"$ST_A.out" 2>&1
RC_A=$?
( cd "$PROBE_DIR" && timeout 120 "$RUNNER" "$PROBE_BASE" --selftest null --marker "$ST_N.marker" ) >"$ST_N.out" 2>&1
RC_N=$?
OK_A=0; [ "$RC_A" = 134 ] && ! grep -qa '^T3 ' "$ST_A.marker" 2>/dev/null && OK_A=1
OK_N=0; [ "$RC_N" = 1 ] && grep -qa '^T3 ' "$ST_N.marker" 2>/dev/null \
        && grep -qaF 'verdict=RED-NULL' "$ST_N.out" && OK_N=1
echo "HIDDEN_ONLY_STEP 自检 abort: rc=$RC_A（期望 134 且标记无 T3）⇒ $([ "$OK_A" = 1 ] && echo OK || echo 失败)"
echo "HIDDEN_ONLY_STEP 自检 null : rc=$RC_N（期望 1 且有 T3 且 verdict=RED-NULL）⇒ $([ "$OK_N" = 1 ] && echo OK || echo 失败)"
if [ "$OK_A" != 1 ] || [ "$OK_N" != 1 ]; then
    echo "HIDDEN_ONLY_STEP=NOINFO 装置自证失败 ⇒ 本装置分不开 abort 与 null，读数不可信（算不出，不是绿）"
    exit 2
fi

# ── 主体：8 用例 × 2 档 × 2 模式 = 32 格 ──────────────────────────────────────
N_OK=0; N_BAD=0; N_ABSENT=0; N_MISFIRE=0; N_JUDGED=0; N_CELLS=0
BADLIST=""; ABSLIST=""; MISLIST=""
: > "$LOGDIR/cells.tsv"
echo
echo "HIDDEN_ONLY_STEP ── 逐格（--collapsible 写死；格 = 用例.档.模式）"

for c in $ALL_CASES; do
  for t in $TIERS; do
    for m in $MODES; do
      tag="$c.$t.$m"; base="$LOGDIR/$tag"
      N_CELLS=$((N_CELLS + 1))
      # ⚠️ 标记文件必须先删：探针是**追加**写（Program.cs:68），不删会把上一趟的 T3 读成"活过"
      rm -f "$base.marker"
      args=(--case "$c" --tier "$t" --collapsible --marker "$base.marker")
      [ "$m" = nocatch ] && args+=(--nocatch)
      ( cd "$PROBE_DIR" && ulimit -c 0 && timeout 180 "$RUNNER" "$PROBE_BASE" "${args[@]}" ) \
          >"$base.out" 2>"$base.err"
      rc=$?

      survived=0; grep -qa '^T3 ' "$base.marker" 2>/dev/null && survived=1
      verdict="$(grep -a -m1 '^D5CBR VERDICT case=' "$base.out" 2>/dev/null | grep -o 'verdict=[A-Za-z-]*' | head -1 | cut -d= -f2)"
      aline="$(grep -a -m1 '^D5CBR ASSERT case=' "$base.out" 2>/dev/null || true)"
      a1=-; a2=-; a3=-
      case "$aline" in *'A1非null=PASS'*) a1=PASS;; *'A1非null=FAIL'*) a1=FAIL;; esac
      case "$aline" in *'A2无LoCreateContext=PASS'*) a2=PASS;; *'A2无LoCreateContext=FAIL'*) a2=FAIL;; esac
      case "$aline" in *'A3长度一致=PASS'*) a3=PASS;; *'A3长度一致=FAIL'*) a3=FAIL;; esac
      # 机制门的原料（断言⑧⑨）
      layer=非关
      grep -qaF '快路径(SimpleTextLine)=**关**' "$base.out" && layer=关
      mechzero=0
      grep -qaF '两档零增量' "$base.out" && mechzero=1
      # 兜底分支的运行期计数（宽松档）：`DIAGbefore` 是**第一**次出现，`DIAGafter` 是**最后**一次
      rpd_before="$(grep -a -o 'relaxedParaDefaults=[0-9]*' "$base.out" 2>/dev/null | head -1 | cut -d= -f2)"
      rpd_after="$(grep -a -o 'relaxedParaDefaults=[0-9]*' "$base.out" 2>/dev/null | tail -1 | cut -d= -f2)"
      rpd_before="${rpd_before:-x}"; rpd_after="${rpd_after:-x}"
      # ── abort 的**双信号归因**（`#30` W30D：从"只印出来"升级成**判据**）─────────────
      # 【为什么必须两个信号】`rc=134` 既是 `D-T5-R` 的真签名，**也**可能是环境/装置问题
      #   （`#28` W28H 实测：私目录缺 `WPF_LINUX_WIN32_SHIM` ⇒ 每一格都 `DllNotFoundException`
      #   而 abort ⇒ 32 格假红）⇒ **只看 `rc` 这一层分不开**。
      # 【⚠️ `#29` W29C 独立复核抓到的缺陷（本趟修）】原实现只取**异常类型名**
      #   （`grep -aoE '[A-Za-z]+Exception'`），而 `LoCreateContext` **只出现在异常消息里**
      #   ⇒ 下面那个 `*LoCreateContext*` 分支**恒不命中（死代码）** ⇒ **每一格 `rc=134` 都被印成
      #   "不是 `D-T5-R` 的签名 ⇒ 先怀疑环境"，包括真是它的时候** ⇒ 归因被毁。
      #   ⚠️ 那**不是**"分不开"，而是"**信号取错了地方**"：两个可分信号**本来就在同一趟的产物里**
      #   （不需要额外跑探针）：
      #     ① **进程进展**：`marker` 文件是否**非空** —— 探针 `Program.cs:195` 的
      #        `Mark("T0 enter …")` 在**用例进入时**就落盘（`FileMode.Append` ＋ `Flush(true)`）；
      #        缺 shim 时崩溃**早于**它 ⇒ 标记文件**从不出现**、stdout 停在 `D5CBR TIER` 而**没有** `D5CBR CASE`。
      #     ② **异常签名**：类型名（`$exsig`）＋ **消息全文里有没有 `LoCreateContext`**（`msg_ls`）。
      #   ⇒ 判法（见下方 `rc=134` 分支）：两者都是"用例内 abort"才叫真签名；"崩在用例进入之前
      #     ＋缺 shim 特征"判 `absent`（**NOINFO：读数不可归因**，与断言⑪同族），
      #     ⛔ 既不洗成绿，也不冒充 `D-T5-R` 回归。
      exsig="$(grep -aoE '[A-Za-z]+Exception' "$base.err" 2>/dev/null | head -1)"
      exsig="${exsig:-无异常签名}"
      marker_any=0; [ -s "$base.marker" ] && marker_any=1
      msg_ls=0; grep -aq 'LoCreateContext' "$base.err" 2>/dev/null && msg_ls=1
      env_miss=0
      grep -aqE 'DllNotFoundException|libwpfwin32|WPF_LINUX_WIN32_SHIM' "$base.err" 2>/dev/null && env_miss=1
      # 机器读的**归因标签**（`#30` W30D 加）：只在"`rc=134` 且无判词"这一格才有值 ⇒
      #   `signature=env-missing-shim(…)` ／ `signature=d-t5-r-true-abort(…)` ／ `signature=unknown-abort(…)`。
      #   ⚠️ 键**故意小写**：`verify-all.sh` 的失败诊断宽 grep 是 `[A-Z][A-Z0-9_]*=(FAIL|NOINFO)`
      #   ⇒ 小写键＋括号值**不可能**被它误捞（与逐格三个非 ASCII 键同一考虑，见文件头）。
      sigh=""
      if [ "$rc" = 134 ] && [ -z "$verdict" ]; then
          if [ "$marker_any" = 0 ] && [ "$env_miss" = 1 ]; then
              sigh="signature=env-missing-shim(marker=absent,exsig=$exsig)"
          elif [ "$msg_ls" = 1 ]; then
              sigh="signature=d-t5-r-true-abort(marker=present,msg=LoCreateContext,exsig=$exsig)"
          else
              sigh="signature=unknown-abort(marker=$([ "$marker_any" = 1 ] && echo present || echo absent),exsig=$exsig)"
          fi
      fi

      # 预期表（**写死**；declaredgap 是"预期红"的断言对照）
      e_rc=0; e_verdict=GREEN; e_a1=PASS; e_a2=PASS; e_a3=PASS
      case "$c" in "$ASSERT_CTRL_CASE") e_rc=1; e_verdict=RED-LENGTH; e_a3=FAIL;; esac

      st=ok; why=""
      if [ "$survived" = 0 ] && [ "$rc" = 0 ] && [ -z "$verdict" ]; then
          # ⚠️ 这一族**单独计数**（misfire，不是 fail）：它是"**假装置**"的签名 ——
          #    进程 rc=0、一字不吐、连标记都不落 ⇒ "每一格 rc=0" 却什么都没判。
          #    ⛔ 绝不许把它读成绿，也**不许**把它与"探针自报算不出（rc=2）"混为一谈。
          st=misfire; why="装置假退出：rc=0 却既无 T3 收尾行也无判词（**rc=0 不等于绿**）"
      elif [ "$rc" = 124 ]; then
          st=absent; why="超时挂死（timeout 180）⇒ 算不出"
      elif [ -z "$verdict" ]; then
          if [ "$rc" = 134 ]; then
              # 【`#30` W30D：把这个 `rc` 的两种坏法**真的分开**（判据面扩张，与本改动同趟登记）】
              #   · **真签名**（崩在**用例内**：标记已落）＋ 消息含 `LoCreateContext` ⇒ `fail`（rc 仍 1）
              #   · **装置/环境**（崩在**用例进入之前**：标记未创建 ＋ 缺 shim 特征）⇒ `st=absent`
              #     ⇒ 整步 `NOINFO`（rc=2）：读数**不可归因**，与断言⑪「pc 变了 ⇒ NOINFO」同族。
              #     ⛔ `NOINFO` 经 `run_step` 仍是 `❌` ⇒ **不是绿**；也**不许**读成 `D-T5-R` 回归
              #        （那正是 `#28` W28H 那 32 格假红的形态）。
              #   ⚠️ 默认仍是 `st=fail`（下面这行**逐字节未动**）：只有同时满足两个信号才降级成 NOINFO。
              st=fail
              if [ "$marker_any" = 0 ] && [ "$env_miss" = 1 ]; then
                  st=absent
                  why="装置/环境（**不是 D-T5-R 的红**）：rc=134 且崩在**用例进入之前**（标记文件未创建）＋缺 shim 特征（$exsig）⇒ 读数**不可归因**（NOINFO；不是绿、也不是回归）"
              elif [ "$msg_ls" = 1 ]; then
                  why="进程级 ABORT（rc=134；异常=$exsig ＋ 消息含 LoCreateContext ⇒ **D-T5-R 的真签名**）"
              elif [ "$marker_any" = 1 ]; then
                  why="进程级 ABORT（rc=134；崩在**用例内**（标记已落）但异常=$exsig 不含 LoCreateContext ⇒ 红成立，归因待查）"
              else
                  why="进程级 ABORT（rc=134；标记未落 ＋ 异常=$exsig ⇒ 红仍成立，但归因要另查，先怀疑环境/私目录装置）"
              fi
          else st=absent; why="无判词（rc=$rc）⇒ 输出形态变了/算不出"; fi
      elif [ "$rc" = 2 ]; then
          st=absent; why="探针自报 NOINFO rc=2"
      else
          case "$verdict" in
            GREEN)  [ "$rc" = 0 ] || { st=fail; why="判词 GREEN 而 rc=$rc（判词与 rc 不一致）"; } ;;
            RED-*)  [ "$rc" = 1 ] || { st=fail; why="判词 $verdict 而 rc=$rc（判词与 rc 不一致）"; } ;;
            *)      st=absent; why="判词形态不认识：$verdict" ;;
          esac
          if [ "$st" = ok ] && [ "$rc" != "$e_rc" ]; then st=fail; why="rc=$rc 期望 $e_rc"; fi
          if [ "$st" = ok ] && [ "$verdict" != "$e_verdict" ]; then st=fail; why="判词=$verdict 期望 $e_verdict"; fi
          if [ "$st" = ok ] && { [ "$a1" != "$e_a1" ] || [ "$a2" != "$e_a2" ] || [ "$a3" != "$e_a3" ]; }; then
              st=fail; why="A1/A2/A3=$a1/$a2/$a3 期望 $e_a1/$e_a2/$e_a3"
          fi
          # 断言⑧ 机制门：只加在**目标例**上
          if [ "$st" = ok ] && [ "$c" = "$TARGET_CASE" ]; then
              if [ "$layer" != 关 ]; then st=fail; why="机制门：快路径=**开** ⇒ 本格没走托管档，绿是零判别力的假绿"; fi
              if [ "$st" = ok ] && [ "$mechzero" = 1 ]; then st=fail; why="机制门：接手链=NOINFO(两档零增量) ⇒ 被测路径根本没执行"; fi
              if [ "$st" = ok ] && ! { [ "$rpd_before" = 0 ] && [ "$rpd_after" != x ] && [ "$rpd_after" -ge 1 ]; }; then
                  st=fail; why="机制门：兜底分支没被走到（relaxedParaDefaults before=$rpd_before after=$rpd_after，期望 0 ⇒ >=1）⇒ 光看 rc=0 不算"
              fi
          fi
          # 断言⑨ 窄射程：只加在 6 个非目标用例上
          #   ⚠️ **两种坏法必须分开报**（`#28` W28H 实测踩到，见报告 §6）：
          #     · 字段**在**且 ≠0  ⇒ 新兜底分支**外溢**到别的段落形态（行为变更）
          #     · 字段**不在**（`x`）⇒ 这一维**根本没被行使** —— 旧产物/仪器换代时会这样
          #       （`relaxedParaDefaults` 是 `#25` 修法**新增**的计数器 ⇒ `#24` 世代的 pc 没有它）。
          #   两者都判 `fail`：本工程的铁律是**"静默关牙不许当绿"**（`D-G17`：跳过越界 = 判据不当绿）。
          #   ⛔ 不许把"字段不在"洗成绿（那正好是"没行使却被读成通过"）。
          case " $NARROW_CASES " in *" $c "*)
              if [ "$st" = ok ] && [ "$rpd_after" = x ]; then
                  st=fail; why="窄射程**不可测**：输出里没有 relaxedParaDefaults 字段（旧产物/仪器换代）⇒ 这一维没行使，静默关牙不许当绿"
              elif [ "$st" = ok ] && [ "$rpd_after" != 0 ]; then
                  st=fail; why="窄射程：非目标例的 relaxedParaDefaults=$rpd_after（期望 0）⇒ 新兜底分支**外溢**到别的段落形态"
              fi ;;
          esac
      fi

      case "$st" in
        ok)      N_OK=$((N_OK + 1)); N_JUDGED=$((N_JUDGED + 1)) ;;
        fail)    N_BAD=$((N_BAD + 1)); N_JUDGED=$((N_JUDGED + 1)); BADLIST="$BADLIST $tag" ;;
        misfire) N_MISFIRE=$((N_MISFIRE + 1)); MISLIST="$MISLIST $tag" ;;
        absent)  N_ABSENT=$((N_ABSENT + 1)); ABSLIST="$ABSLIST $tag" ;;
      esac
      # ⚠️ **grep 卫生**：stdout 上的三项断言**故意用探针自己的非 ASCII 键**
      #    （`A1非null=` / `A2无LoCreateContext=` / `A3长度一致=`）—— 因为 `verify-all.sh` 的失败诊断
      #    grep 是 `[A-Z][A-Z0-9_]*=(FAIL|NOINFO)`：若这里打 `A3=FAIL`，那么**每一格预期红**
      #    （`declaredgap`）都会被它捞成"诊断"，屏上就会把**预期红**印得像故障（`#26` W26E 实测 0 命中）。
      #    TSV（`cells.tsv`）里仍用短 ASCII 键，那是给机器读的文件，不经 `verify-all` 的 grep。
      printf 'HIDDEN_ONLY_STEP 格 %-24s rc=%-3s verdict=%-11s A1非null=%-4s A2无LoCreateContext=%-4s A3长度一致=%-4s 快路径=%-2s 兜底计数=%s→%s ⇒ %s%s\n' \
          "$tag" "$rc" "${verdict:-?}" "$a1" "$a2" "$a3" "$layer" "$rpd_before" "$rpd_after" "$st" "${why:+  ｜ $why}${exsig:+  ｜ 异常=$exsig}${sigh:+  ｜ $sigh}"
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
          "$tag" "$rc" "${verdict:-?}" "$a1" "$a2" "$a3" "$layer" "$rpd_after" "$st" "$why" >> "$LOGDIR/cells.tsv"
    done
  done
done

# ── 断言⑪：全步期间权威 pc 不许变 ──────────────────────────────────────────────
DEC=0; DREASON=""
if [ "$POLARITY" = 0 ]; then
    PC_AT_END="$(sha16 "$AUTH_PC")"
    echo
    if [ "$PC_AT_END" != "$PC_AT_START" ]; then
        echo "HIDDEN_ONLY_STEP=NOINFO 本步期间被测 pc 变了：start=$PC_AT_START end=$PC_AT_END ⇒ 读数不可归因（纪律 35）"
        exit 2
    fi
    echo "HIDDEN_ONLY_STEP 被测 pc 全程未变 = $PC_AT_START"
fi

# ── 判决（优先级见文件头，逐条） ─────────────────────────────────────────────
if [ $((N_JUDGED + N_MISFIRE + N_ABSENT)) -ne "$EXPECT_TOTAL" ]; then
    DEC=2; DREASON="格数不守恒：判定例 $N_JUDGED + 假退出 $N_MISFIRE + 算不出 $N_ABSENT != 期望 $EXPECT_TOTAL ⇒ 仪器没跑满"
elif [ "$N_JUDGED" = 0 ] && [ "$N_ABSENT" = "$EXPECT_TOTAL" ]; then
    DEC=2; DREASON="每一格都是探针自报的算不出（rc=2）⇒ 算不出，不是绿"
elif [ "$N_JUDGED" = 0 ]; then
    DEC=1; DREASON="判定例=0 ⇒ **恒绿退化**：一格都没判过，'符合预期' 恒真、毫无意义（假退出格：$MISLIST）"
elif [ "$N_MISFIRE" != 0 ]; then
    DEC=1; DREASON="有**装置假退出**的格（rc=0 却无判词 ⇒ 比'算不出'更严重，故判红不判 NOINFO）：$MISLIST"
elif [ "$N_ABSENT" != 0 ]; then
    DEC=2; DREASON="有算不出的格：$ABSLIST（**NOINFO 不许算绿**）"
elif [ "$N_BAD" != 0 ]; then
    DEC=1; DREASON="有判据不符的格：$BADLIST"
else
    DEC=0
fi

POL_TAG=$([ "$POLARITY" = 1 ] && echo 是 || echo 否)
echo
echo "HIDDEN_ONLY_STEP 口径 判定例=$N_JUDGED 期望=$EXPECT_TOTAL 符合=$N_OK 不符=$N_BAD 假退出=$N_MISFIRE 算不出=$N_ABSENT 极性模式=$POL_TAG"
echo "HIDDEN_ONLY_STEP 口径 目标=$TARGET_CASE（四格，含 --collapsible、机制门、兜底计数 0 到 >=1 ｜机制证）｜预期红对照=$ASSERT_CTRL_CASE（四格必须 RED-LENGTH）｜窄射程=$NARROW_CASES 兜底计数必须恒 0"
case "$DEC" in
    0) echo "HIDDEN_ONLY_STEP=PASS 判定例=$N_JUDGED/$EXPECT_TOTAL 全部符合预期（$TARGET_CASE 四格 GREEN 且兜底分支被走到；对照仍绿；$ASSERT_CTRL_CASE 四格 RED-LENGTH 证明 A3 非空断言）｜自检=OK ｜pc=$PC_AT_START ｜极性模式=$POL_TAG"
       exit 0 ;;
    1) echo "HIDDEN_ONLY_STEP=FAIL 判定例=$N_JUDGED/$EXPECT_TOTAL：$DREASON"
       exit 1 ;;
    *) echo "HIDDEN_ONLY_STEP=NOINFO 判定例=$N_JUDGED/$EXPECT_TOTAL：$DREASON（算不出 ⇒ **不是通过**）"
       exit 2 ;;
esac
