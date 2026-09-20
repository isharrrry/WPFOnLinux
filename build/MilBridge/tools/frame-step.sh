#!/usr/bin/env bash
#
# 主控 · 波 `#24` —— **帧列**（`FrameProbe`）的冻树牙齿（`verify-all` 的**第 12 步**）。
#
# 【为什么需要它（本波新查出的**结构性缺口**，见 `docs/WAVE24-PREREGISTRATION.md` §2）】
#   `#23` 实测：`FrameProbe`（`#22` 建的 `D-T6-b` 帧判据探针）在
#     `verify-all.sh` / `tline-gate.sh` / `pc-line-step.sh` / `run.sh` / `arm-logs/README.md`
#   **五处 grep 全 0** ⇒ 它**不在任何冻树回路里**；而它报的残余红（strict/lenient 各 `红行=3`）
#   **今天无处可登记**。⇒ **欠的是接线，不是登记**（车道 W23D 的结论，主控采纳）。
#   而"帧"这一列在冻树上**没有任何别的牙齿**：`pc-line-step.sh` 只判 `TextLine.Start` 一列。
#
# 【本步判**哪一列**：`帧红`，**不是** `红行` —— 这是本步最重要的一条口径】
#   `#23` 已定性：`红行=3` 那 3 条**全是"行数不等"结构族**（每条自报 `行数我方=4 真值=2`），
#   **不是帧错**：全量 421 行上 `frame == 我方cpFirst`（帧原点机制没坏），
#   只是"我方分行 ≠ 真机分行" ⇒ 我方 cpFirst ≠ 真值 startChar。
#   ⇒ `#24` P2 让 `FrameProbe` 把 `红行` **按族分解**（`Program.cs` 汇总行末尾新增 `帧红=` / `结构红=`，
#     并新增自证行 `FRAMEPROBE 红族分解 …`）：
#       · **帧红**   = 红 ∧ `扫描帧 != 我方cpFirst` ⇒ **帧原点机制本身错**（`D-T6-b` 那一族）；
#       · **结构红** = 红 ∧ `扫描帧 == 我方cpFirst` ∧ `我方cpFirst != 真值 startChar`
#                      ⇒ 「我方分行 ≠ 真机分行」，**不是帧错**。
#   ⛔ **本步断言 `帧红 == 0`，绝不断言 `红行 == 0`**（预登记 §2.2 明令）：
#      把 `红行` 当判据 = 把结构族也吞进来，**与 `#23` 的教训相反**，而且会让本步**永远红**、
#      从而退化成"没人看的红"（事故 `L26` 的同族）。
#   ⚠️ **本步不判**结构族红（`结构红=3`）。它是**另一笔账**（"把 3 条压成登记"是**主控的登记决定**）：
#      本步只在输出里**逐条点名** `结构红` 的 id，让那 3 条**有处可登记**；
#      **不许**读成"本步把它洗绿了"—— 探针自己的 rc（=1）在下面**逐腿原样打印**。
#
# 【`NOINFO` 不许算绿 —— 两类 `NOINFO` 必须分开，否则判据必错】
#   探针的 `NOINFO行`（`#24` 实测 101）**不是仪器缺口**，是**语料性质**：真值数组短于我方行数时，
#   多出来的我方行**没有真值可比**（同族的 `我方行数 != 真值行数 的例` = 60）。
#   `#24` P2 因此也把它按族分解：`仪器族NOINFO`（有真值却扫不出帧 = **仪器缺口**）与
#   `结构族NOINFO`（该行无真值可比 = **语料性质**）。**本步断言 `仪器族NOINFO == 0`**，
#   而 `结构族NOINFO` 只打印并标口径（既**不许当绿**，也**不许当仪器缺口**）。
#   仪器级 `NOINFO` 另有四条，**一律 rc=2**：探针 rc=2｜汇总行缺失｜字段解析不出｜族分解不自洽。
#
# 【三条腿，以及**哪几条决定 rc**（预登记 §2.3 要求逐条写清）】
#   ① `--leg b --tier strict`                      —— **决定 rc**
#   ② `--leg b --tier lenient`                     —— **决定 rc**
#   ③ `--leg b --tier strict --prefix 40`          —— **决定 rc**
#   **理由（为什么 ①② 必须都有）**：`strict` = PC 先试的那一层（`HbTextFallback`），
#     `lenient` = 它返回 null 之后的兜底层（`WpfLinuxLenientTextFallback`）——**两条是不同代码路径**，
#     只跑一条等于把另一条留在回路外（`D-T3` 的一半当初就是这么漏掉的）。
#   **理由（为什么 ③ 也决定 rc，尽管它口径与 ①② 不同）**：`--prefix 40` 把源串变成 `'M'×40 + 用例文本`、
#     首调下标 = 40 ⇒ **段落原点 ≠ 0**，且真值帧 = `40 + startChar` ⇒ 真值侧被**整体平移**
#     （`真值非零行 133 → 421`：`#23` 实测，所以**它的读数不能与 ①② 直接比列**）。
#     它是**唯一**一条"段落原点 ≠ 0"的腿 —— 而 `D-T6-b` 这一族缺陷**恰恰是帧原点与段落原点的关系**。
#     不接它 ⇒ 本步对"假设段落原点恒为 0"这类错误**零判别力**。故接，但**只在输出里标清口径差异**。
#   **所有三条腿的判据形式完全相同**（`帧红==0 ∧ 判定行>0 ∧ 仪器族NOINFO==0 ∧ 自洽==1`）——
#     差别只在**列的可比性**（真值非零行），不在断言；**任一条腿任何一条断言不成立 ⇒ rc=1**。
#   代价：三条腿 ≈ 9~10 分钟（`#24` 实测 ①≈3 min / ②≈3 min / ③≈3.5 min）。
#
# 【为什么自己重建】`FrameProbe.csproj` 用 `HintPath`+`Private=true` 引 PC ⇒ 产物目录里有一份
#   `PresentationCore.dll` **副本**。跑之前必须让它与树里的权威件**逐位相同**，否则量的是一份**旧产物**
#   （`D-A2` 那一族；`#22`/`#23` 都踩过）。⇒ 强制重建 + **断言副本 == 权威**；不等 ⇒ `NOINFO`。
#   ⚠️ 本波 `pc` 由**另一条车道**改（纪律 48）⇒ 全程记 `pc` sha16，**跨整个步变了就作废**（rc=2）。
#
# 三态：rc=0 判据通过｜rc=1 判据**红**（`帧红`≠0 / `仪器族NOINFO`≠0 / **恒绿退化**）｜rc=2 `NOINFO`（算不出）。
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT" || exit 2
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
# 内存纪律（预登记 §7.2）：**所有** dotnet 命令 `-m:1` + `DOTNET_gcServer=0`
export DOTNET_gcServer=0

PROJ_DIR="$ROOT/build/MilBridge/tests/FrameProbe"
PROJ="$PROJ_DIR/FrameProbe.csproj"
CORPUS="$ROOT/tests/parity/windows/tab-anchor/out/tab-anchor-raw.json"
OUT="$PROJ_DIR/bin/Release"
ARM="$OUT/PresentationCore.Tests.dll"
# ★ `#39`：权威件配置**只许从唯一声明处取**（`build/SelfBuiltConfig.props` → 由下面的读取器 source 进来）。
#   写死 `bin/Debug` 那形态会让"切 Release"必须逐个文件 sed ⇒ 必漏（同族教训：同一语义多处 ⇒ 必然分叉）。
#   读取器自检：`bash build/selfbuilt-config.sh --check`（断言 shell 值 == 两条 import 图的 MSBuild 值）。
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../../build/selfbuilt-config.sh"
AUTH_PC="$ROOT/build/PresentationCore.Linux/bin/$SELFBUILT_CONFIG/PresentationCore.dll"
COPY_PC="$OUT/PresentationCore.dll"
LOGDIR="${FRAME_STEP_LOGDIR:-/tmp/frame-step}"

sha16() { [ -f "$1" ] && sha256sum "$1" | cut -c1-16 || echo "MISSING"; }

for f in "$PROJ" "$CORPUS" "$AUTH_PC"; do
    [ -f "$f" ] || { echo "FRAME_STEP=NOINFO 缺文件：$f"; exit 2; }
done
mkdir -p "$LOGDIR" || { echo "FRAME_STEP=NOINFO 建不了日志目录：$LOGDIR"; exit 2; }

# 纪律 15/18/40：读数必须连 artifact+字段+sha 一起写；**仪器变更要披露**
# ⚠️ 所有 `echo` 串里**不许出现反引号**（那双引号里的反引号会被做成命令替换）：
#   `#24` P2 首版在三处 echo 里踩了这条 ⇒ 运行时 stderr 打出"帧红: 未找到命令"**并把词吃掉**
#   （实测日志 `$HOME/w24b-run/neg-degen.out:188`）。已改；本注释即为防复发。
echo "FRAME_STEP 仪器·Program.cs = $(sha16 "$PROJ_DIR/Program.cs")（波 #24 P2 后：含 帧红/结构红 + NOINFO 族分解）"
echo "FRAME_STEP 仪器·FrameProbe.csproj = $(sha16 "$PROJ")"
echo "FRAME_STEP 语料           = $(sha16 "$CORPUS")  路径=$CORPUS"
PC_AT_START="$(sha16 "$AUTH_PC")"
echo "FRAME_STEP 被测 pc（树）  = $PC_AT_START  路径=$AUTH_PC"
echo "FRAME_STEP 日志目录       = $LOGDIR"

dotnet build "$PROJ" -c Release -m:1 --nologo -v q >"$LOGDIR/build.log" 2>&1 \
    || { echo "FRAME_STEP=NOINFO 构建失败 ⇒ 算不出，不是绿（见 $LOGDIR/build.log）"; exit 2; }

S_AUTH="$(sha16 "$AUTH_PC")"; S_COPY="$(sha16 "$COPY_PC")"
if [ "$S_COPY" = "MISSING" ] || [ "$S_AUTH" = "MISSING" ]; then
    echo "FRAME_STEP=NOINFO 产物副本或权威件缺失：copy=$S_COPY auth=$S_AUTH"; exit 2
fi
if [ "$S_AUTH" != "$S_COPY" ]; then
    echo "FRAME_STEP=NOINFO 产物目录里的 pc 副本与权威件不符：copy=$S_COPY auth=$S_AUTH"
    exit 2
fi
echo "FRAME_STEP 被测 pc        = $S_COPY（copy == auth ✓）"

num() { printf '%s' "$1" | grep -oE "$2=[0-9]+" | head -1 | cut -d= -f2; }

# 腿表：<标签>|<tier>|<额外参数>   （决定 rc 的三条腿，见文件头）
LEGS=(
  "strict|strict|"
  "lenient|lenient|"
  "strict+prefix40|strict|--prefix 40"
)

DEC=0          # 0=通过 1=红 2=NOINFO；取最大 ⇒ NOINFO 压过红（"算不出"不许被"红"盖住）
STRUCT_IDS=""

for spec in "${LEGS[@]}"; do
    TAG="${spec%%|*}"; rest="${spec#*|}"; TIER="${rest%%|*}"; EXTRA="${rest#*|}"
    LOG="$LOGDIR/$TAG.log"
    # shellcheck disable=SC2086
    DISPLAY="${DISPLAY:-:97}" dotnet "$ARM" --corpus "$CORPUS" --leg b --tier $TIER $EXTRA > "$LOG" 2>&1
    PRC=$?
    echo
    echo "FRAME_STEP ── 腿 $TAG（--leg b --tier $TIER $EXTRA）probe_rc=$PRC  日志=$LOG"

    SUM="$(grep -a -m1 '^FRAMEPROBE 汇总 ' "$LOG" || true)"
    FAM="$(grep -a -m1 '^FRAMEPROBE 红族分解 ' "$LOG" || true)"
    if [ -z "$SUM" ] || [ -z "$FAM" ]; then
        echo "FRAME_STEP=NOINFO 腿 $TAG 找不到计数器行（汇总/红族分解）⇒ 算不出（探针换了？腿没跑？）"
        echo "                 probe_rc=$PRC  日志=$LOG"
        DEC=2; continue
    fi
    echo "FRAME_STEP 腿 $TAG 计数器 = $SUM"
    echo "FRAME_STEP 腿 $TAG 族分解 = $FAM"

    JR="$(num "$SUM" 判定行)"; RH="$(num "$SUM" 红行)"; FR="$(num "$SUM" 帧红)"; ST="$(num "$SUM" 结构红)"
    NI="$(num "$FAM" 仪器族NOINFO)"; NS="$(num "$FAM" 结构族NOINFO)"; OK="$(num "$FAM" 自洽)"
    for v in "$JR" "$RH" "$FR" "$ST" "$NI" "$NS" "$OK"; do
        if [ -z "$v" ]; then
            echo "FRAME_STEP=NOINFO 腿 $TAG 计数器字段解析不出来（判定行/红行/帧红/结构红/仪器族NOINFO/结构族NOINFO/自洽）⇒ 算不出"
            DEC=2; continue 2
        fi
    done
    echo "FRAME_STEP 腿 $TAG 机读 判定行=$JR 红行=$RH 帧红=$FR 结构红=$ST 仪器族NOINFO=$NI 结构族NOINFO=$NS 自洽=$OK probe_rc=$PRC"
    # ── 【`#26` W26B · **逐腿累加器**（1 行；`set -u` ⇒ 用 `${LEGSUM:-}` 就地初始化，无需另起一行 `LEGSUM=`）】──
    #   `$JR/$RH/$FR/$ST/$NI/$NS/$OK` 这组变量在 `for` 里被**逐腿覆盖** ⇒ 终局汇总行**不能直接读它们**
    #   （否则印出的是"只剩最后一腿"的**假数**，真数早在循环里被冲掉 —— 预登记 §4 明令）。
    #   另带 `真值非零行`（`$TN`，同一条 `汇总` 行里的既有字段）—— 它是三腿**唯一不同**的那个数
    #   （`strict/lenient` = 133、`strict+prefix40` = 421，见文件头"③ 口径与 ①② 不同"）
    #   ⇒ 有了它，屏上能直接看出"哪条腿的分母是多少"，也就**结构性证明**这三段是三条腿、不是同一腿重复。
    TN="$(num "$SUM" 真值非零行)"
    LEGSUM="${LEGSUM:-}${LEGSUM:+, }$TAG[判定行=$JR 红行=$RH 帧红=$FR 结构红=$ST 仪器族NOINFO=$NI 结构族NOINFO=$NS 自洽=$OK 真值非零行=${TN:-NA}]"

    # ① 族分解自洽（仪器坏了 ⇒ NOINFO，绝不让坏仪器报绿）
    if [ "$OK" -ne 1 ] || [ $((FR + ST)) -ne "$RH" ]; then
        echo "FRAME_STEP=NOINFO 腿 $TAG 红族分解不自洽（帧红 $FR + 结构红 $ST != 红行 $RH，自洽=$OK）⇒ 仪器不可信"
        DEC=2; continue
    fi
    # ② 恒绿退化（一行都没判过 ⇒ "帧红=0" 恒真、毫无意义）
    if [ "$JR" -le 0 ]; then
        echo "FRAME_STEP=FAIL 腿 $TAG 判定行=$JR ⇒ **恒绿退化**：一行都没判过，'帧红=0' 毫无意义"
        DEC=1; continue
    fi
    # ③ 仪器缺口（有真值却扫不出帧）—— `NOINFO` 的那一半，**不许算绿**
    if [ "$NI" -ne 0 ]; then
        echo "FRAME_STEP=FAIL 腿 $TAG 仪器族NOINFO=$NI ⇒ 有真值的行扫不出帧（**仪器/实现缺口**，不是语料性质）"
        DEC=1; continue
    fi
    # ④ 判据本体
    if [ "$FR" -ne 0 ]; then
        echo "FRAME_STEP=FAIL 腿 $TAG **帧红**=$FR / 判定行=$JR ⇒ 帧原点机制错（D-T6-b 那一族）"
        grep -a '^FRAMEPROBE RED ' "$LOG" | head -5 | sed 's/^/      /'
        DEC=1; continue
    fi
    # ⑤ 结构族红：**只点名，不判**（另一笔账；见文件头）
    echo "FRAME_STEP 腿 $TAG 结构族红=$ST（**本步不判**：我方分行 != 真机分行，属登记决定，见文件头）｜结构族NOINFO=$NS（语料性质，非仪器缺口）"
    if [ "$ST" -gt 0 ]; then
        echo "FRAME_STEP 腿 $TAG 结构族红点名（供登记用）："
        grep -a '^FRAMEPROBE RED ' "$LOG" | sed 's/^/      /'
        STRUCT_IDS="$STRUCT_IDS $TAG:$ST"
    fi
done

# ④ 全步期间 `pc` 不许被动过（纪律 35/48：并发跑同一仪器要标时刻与件 sha）
PC_AT_END="$(sha16 "$AUTH_PC")"
echo
if [ "$PC_AT_END" != "$PC_AT_START" ]; then
    echo "FRAME_STEP=NOINFO 本步期间被测 pc 变了：start=$PC_AT_START end=$PC_AT_END ⇒ 本次读数不可归因（纪律 35）"
    exit 2
fi
echo "FRAME_STEP 被测 pc 全程未变 = $PC_AT_START"
echo "FRAME_STEP 结构族红汇总（**已登记**：build/MilBridge/known-red-frame-structural.md ＋ PcLineOracle/known-red.txt；根因 D-T4（DefaultIncrementalTab 到不了工厂）；**本步不判**）：${STRUCT_IDS:- 无}"

case "$DEC" in
    0) echo "FRAME_STEP=PASS 三条腿（strict / lenient / strict+prefix40）均 帧红=0 ∧ 判定行>0 ∧ 仪器族NOINFO=0 ∧ 自洽=1"
       # ── 【`#26` W26B · 终局**逐腿口径**行（只加不删）】上面那行是**判定结论**（**逐字节未动**）；
       #   本行把三条腿各自的 `判定行/红行/帧红/结构红/仪器族NOINFO/结构族NOINFO/自洽`（累加器 `$LEGSUM`）
       #   与 `pc` sha 一起印出来 —— `verify-all.sh` 的 `run_step` 绿分支会按
       #   `^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO)` 把本行原样回显到屏上（`#26` 的 `D-G10`）。
       #   键名 `FRAME_STEP_LEGS` 是**新键**（现场全仓 grep = **0** 处占用、无消费者解析本步的 stdout）；
       #   它**不替代** `FRAME_STEP`（两者由**同一个 `case "$DEC"` 分支**打印 ⇒ 结构上不可能互相矛盾）。
       echo "FRAME_STEP_LEGS=PASS 逐腿口径：${LEGSUM:- 无}｜结构族红汇总（已登记：known-red-frame-structural.md；根因 D-T4；本步不判）：${STRUCT_IDS:- 无}｜pc=$PC_AT_START"
       exit 0 ;;
    1) echo "FRAME_STEP=FAIL 见上面逐腿点名（帧红≠0 或 仪器族NOINFO≠0 或 恒绿退化）"
       echo "FRAME_STEP_LEGS=FAIL 逐腿已解析口径：${LEGSUM:- 无}"
       exit 1 ;;
    *) echo "FRAME_STEP=NOINFO 见上面逐腿原因（算不出 ⇒ **不是通过**）"
       echo "FRAME_STEP_LEGS=NOINFO 逐腿已解析口径：${LEGSUM:- 无}"
       exit 2 ;;
esac
