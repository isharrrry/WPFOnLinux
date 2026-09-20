#!/usr/bin/env bash
#
# 主控 · 波 `#21` —— **`TextLine.Start` 的冻树牙齿**（`verify-all` 的第 11 步）。
#
# 【为什么需要它（本波新查出的**结构性缺口**，见 `docs/WAVE21-PREREGISTRATION.md` §10.3 / §15.5）】
#   ① 五臂门禁的 `tab-oracle-*` 三支臂（宿主 `build/MilBridge/tests/CoverageProbe/Program.cs`）
#      **一个** `lineStartOffsetsDip` / `TextLine.Start` 的引用都没有 ⇒ **门禁对 `Start` 零判别力**；
#      语料里一直躺着 615 个真值（171 行非零），**从来没有被比较过** —— 这就是 `D-T6-c`
#      （`Start => 0` 与真机法律 `Start == ParagraphIndent` 相反）能长期存活的**结构性原因**。
#   ② 而那五支臂**全部直调 `HbTextLineFactory.FormatParagraph`** ⇒ **不经 `HbTextFrame`、
#      不经 PC 的 `TextFormatter`** ⇒ 真正驱动"产品 `PresentationCore.dll`"的那一层，
#      在 `verify-all.sh` 上**没有任何自动红/绿**（`grep -c PcLineOracle verify-all.sh` = 0）。
#   ⇒ 本步把 `PcLineOracle` 的 **`Start` 列**接进冻树回路。
#
# 【本步的判据面 = **只有 `Start` 一列**，且**明说它不覆盖什么**】
#   判据 = 解析臂自己打印的 `PCLINE START 腿=汇总(B) …` 计数器行，要求：
#     · 该行**存在**（不存在 ⇒ `NOINFO`，不许当绿）
#     · `红=0`（任何一行 `R(我方 Start) != 语料 lineStartOffsetsDip[k]` ⇒ 红）
#     · `判定行>0`（**防空绿**：语料一改，判定行会掉到 0，那时"红=0"是**恒真**、毫无意义）
#     · `NOINFO=0`（可比性缺口不许当绿）
#   ⚠️ **本步不判**臂的其余列。修后 `未登记失败=67`（`行#1 i=0 取不到字符边界` 那一族，
#      `#20` 已定性为**读法口径**、登记为 `D-T6`）**仍是未登记**，属**另一笔账**
#      （"把 67 条压成登记"是**主控的登记决定**，不在本步，也**不许**用本步把它洗绿）。
#      ⇒ 本脚本**只读 `PCLINE START` 那一行**，并与 oracle 自身 rc **分开打印**。
#
# 【为什么自己重建】`PcLineOracle.csproj` 用 `HintPath`+`Private=true` 引 PC ⇒ 产物目录里
#   有一份 `PresentationCore.dll` **副本**。跑之前必须让它与树里的权威件**逐位相同**，
#   否则量的是一份**旧产物**（`D-A2` 那一族）。⇒ 强制重建 + **断言副本 == 树**；不等 ⇒ `NOINFO`。
#
# 三态：rc=0 判据通过｜rc=1 判据**红**（`Start` 列有红 / 恒绿退化）｜rc=2 `NOINFO`（算不出）。
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# ★ `#39` 阶段 2/3：读**权威件**的路径必须跟随**唯一声明**（`build/SelfBuiltConfig.props`）。
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../../build/selfbuilt-config.sh"
cd "$ROOT" || exit 2
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

PROJ_DIR="$ROOT/build/MilBridge/tests/PcLineOracle"
PROJ="$PROJ_DIR/PcLineOracle.csproj"
CORPUS="$ROOT/tests/parity/windows/tab-anchor/out/tab-anchor-raw.json"
KNOWN_RED="$PROJ_DIR/known-red.txt"
OUT="$PROJ_DIR/bin/Release"
AUTH_PC="$ROOT/build/PresentationCore.Linux/bin/$SELFBUILT_CONFIG/PresentationCore.dll"
COPY_PC="$OUT/PresentationCore.dll"
LOG="${PCLINE_STEP_LOG:-/tmp/pc-line-start-step.out}"

sha16() { [ -f "$1" ] && sha256sum "$1" | cut -c1-16 || echo "MISSING"; }

for f in "$PROJ" "$CORPUS" "$KNOWN_RED" "$AUTH_PC"; do
    [ -f "$f" ] || { echo "PCLINE_START_STEP=NOINFO 缺文件：$f"; exit 2; }
done

# 纪律 15/18：读数必须连 artifact+字段+sha 一起写
echo "PCLINE_START_STEP 仪器·Program.cs = $(sha16 "$PROJ_DIR/Program.cs")"
echo "PCLINE_START_STEP 语料           = $(sha16 "$CORPUS")"
echo "PCLINE_START_STEP 被测 pc（树）  = $(sha16 "$AUTH_PC")"

dotnet build "$PROJ" -c Release -m:1 --nologo -v q >/dev/null 2>&1 \
    || { echo "PCLINE_START_STEP=NOINFO 构建失败 ⇒ 算不出，不是绿"; exit 2; }

S_AUTH="$(sha16 "$AUTH_PC")"; S_COPY="$(sha16 "$COPY_PC")"
if [ "$S_AUTH" != "$S_COPY" ]; then
    echo "PCLINE_START_STEP=NOINFO 产物目录里的 pc 副本与权威件不符：copy=$S_COPY auth=$S_AUTH"
    exit 2
fi
echo "PCLINE_START_STEP 被测 pc        = $S_COPY（copy == auth ✓）"

DISPLAY="${DISPLAY:-:97}" dotnet "$OUT/PresentationCore.Tests.dll" \
    --pc-lines-oracle "$CORPUS" --leg b --tier strict --known-red "$KNOWN_RED" > "$LOG" 2>&1
ORACLE_RC=$?

COUNTER="$(grep -a -m1 '^PCLINE START ' "$LOG" || true)"
if [ -z "$COUNTER" ]; then
    echo "PCLINE_START_STEP=NOINFO 找不到 \`PCLINE START\` 计数器行（仪器换了/腿没跑）⇒ 算不出"
    echo "                          oracle rc=$ORACLE_RC  日志=$LOG"
    exit 2
fi
echo "PCLINE_START_STEP 计数器 = $COUNTER"
echo "PCLINE_START_STEP oracle 自身 rc=$ORACLE_RC（**不是本步的判据**；其未登记红属另一笔账，见文件头）"

num() { printf '%s' "$1" | grep -oE "$2=[0-9]+" | head -1 | cut -d= -f2; }
RED="$(num "$COUNTER" 红)"; JUDGED="$(num "$COUNTER" 判定行)"; NOINFO="$(num "$COUNTER" NOINFO)"
RED="${RED:-x}"; JUDGED="${JUDGED:-x}"; NOINFO="${NOINFO:-x}"

if [ "$RED" = x ] || [ "$JUDGED" = x ] || [ "$NOINFO" = x ]; then
    echo "PCLINE_START_STEP=NOINFO 计数器字段解析不出来（红/判定行/NOINFO）⇒ 算不出"
    exit 2
fi
if [ "$JUDGED" -le 0 ]; then
    echo "PCLINE_START_STEP=FAIL 判定行=$JUDGED ⇒ **恒绿退化**：一行都没判过，'红=0' 毫无意义"
    exit 1
fi
if [ "$NOINFO" -ne 0 ]; then
    echo "PCLINE_START_STEP=FAIL NOINFO=$NOINFO ⇒ 有不可比的行；**NOINFO 不是绿**"
    exit 1
fi
if [ "$RED" -ne 0 ]; then
    echo "PCLINE_START_STEP=FAIL Start 列有红：红=$RED / 判定行=$JUDGED"
    grep -a '^PCLINE START ' "$LOG" | head -5
    exit 1
fi

echo "PCLINE_START_STEP=PASS Start 列 红=0 绿=$((JUDGED - RED)) 判定行=$JUDGED NOINFO=0"
exit 0
