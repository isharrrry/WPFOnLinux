#!/usr/bin/env bash
#
# 收官序列（**一趟波 = 一条命令**）—— 主控独占。
#
# 【为什么需要它】"重建 → 重建 native shim → 重发桥 → 身份自检 → 全量回归"这套顺序
#   在 2026-09-13/14 被**手工跑了三遍**，每一步都是踩出来的：
#     · 忘了同步 native shim 的 4 份副本 ⇒ 探针测旧件（债务 #20）；
#     · 源改了没重发桥 ⇒ `ACCEPTANCE-BASELINE.md` **#6 被冻成"源陈旧"**（事故 D）；
#     · 发布期间手写改了源 ⇒ 产物与"波后树"对不上（波 10 的守卫抓过）。
#   手工顺序**迟早会漏一步**，而漏掉的那一步**不会报错**（这正是本项目最怕的形态）。
#   ⇒ 把顺序写成脚本，**每一步的 rc 都当闸门**，并把"哪一位变了"打进一份汇总。
#
# 【它做什么】
#   0) 前置：确认**没有应用在跑**、没有重发锁，打印波前输入指纹与四处源码 sha；
#   1) `integration-wave.sh`（PC/PF/WB 重建 + 2.5 应用器审计 + 3.5 生成物指纹 + 3.6 副本刷新 + 4 身份 + 5 输入稳定性）；
#   2) **native shim**：源码比权威件新才重建（`--native` 可强制），构建后**同步全部副本并断言同 sha**；
#   3) **桥**：源指纹与发布记录不一致才重发（`--bridge` 可强制），发完记录 fp；
#   4) 身份四件套自检：桥 fp 两侧一致 / 生成物指纹 `state=ok` / `APPSYNC=PASS` / 应用器审计 `miss=0`；
#   5) `verify-all.sh`（`--skip-verify-all` 可跳过）；
#   6) 汇总：八位 + 第九位 + 扩展可见位 + 各步 rc，写 `close-wave-summary.txt`，**并明确打印"下一步要重冻基线"**。
#
# 【它不做什么】**不替你冻基线**（那是 T3 的应用级门禁 + 人工确认），**也不发基线文件**。
#   它只保证"件是干净、自洽、可复现的"，然后告诉你去跑门禁。
#
# 用法：
#   bash build/close-wave.sh                     # 自动判定该重建什么
#   bash build/close-wave.sh --native --bridge   # 强制重建 native / 强制重发桥
#   bash build/close-wave.sh --skip-verify-all   # 只到身份自检（快速）
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# ★ `#39`：九位读数必须跟随**唯一声明**（否则切 Release 后这里会读 Debug 件、而且**不报错**）。
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../build/selfbuilt-config.sh"
cd "$ROOT"
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

FORCE_NATIVE=0; FORCE_BRIDGE=0; SKIP_VERIFY=0; DRY_RUN=0
for a in "$@"; do
    case "$a" in
        --native) FORCE_NATIVE=1 ;;
        --bridge) FORCE_BRIDGE=1 ;;
        --skip-verify-all) SKIP_VERIFY=1 ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
        *) echo "未知参数：$a（-h 看用法）" >&2; exit 2 ;;
    esac
done

OUT="${CLOSE_WAVE_OUT:-$HOME/wfp-runs/close-wave-$(date +%H%M%S)}"
mkdir -p "$OUT"
LOG="$OUT/close-wave.log"
SUMMARY="$OUT/close-wave-summary.txt"
: > "$LOG"

# 波的责任人：`integration-wave.sh` 自 2026-09-14 起**拒绝无责任人的波**（18:15 那趟无人认领的波
# 把并行车道的"当前件读数"集体作废，还留下考古成本）。走本脚本 = 自动认领。
export WAVE_OWNER="${WAVE_OWNER:-close-wave:$(id -un)}"

# 所有输出同时进日志（读者既能看屏也能事后核）
say() { printf '%s\n' "$*" | tee -a "$LOG"; }
run() {  # run <标签> <命令...> ⇒ 记 rc，非零即失败（**不许静默继续**）
    local label="$1"; shift
    say ""; say "──── [$label] $(date -Is)"
    "$@" >>"$LOG" 2>&1; local rc=$?
    say "  rc=$rc  （完整输出：$LOG）"
    [ "$rc" -eq 0 ] || { say "  ❌ [$label] 失败 ⇒ 中止（**不要**在失败后继续后面的步骤：后面的「绿」会建立在坏件上）"; exit "$rc"; }
}

fp_inputs() {  # 手写输入指纹（应用器 + port-lib + 本脚本 + 波脚本 + **shim 源** + **src/WpfGfx.Linux 源**）
    # 【2026-09-15 主控修：本函数原先**不含 shim 与 src/WpfGfx.Linux** ⇒ 实测两趟波在 shim 从
    #   `fde9e511…` 变成 `0085624234…` 的情况下，`inputs_fp` **逐位相同** ⇒ "输入稳定性 波前==波后"
    #   这一句对 shim 是**空成立**（#14 那趟的 shim 就在波中途被改过而未被发现）。
    #   判据：改后若 shim 变，`inputs_fp` 必须变（一次两极化实测）。
    {
      # ⚠️【`#29` W29B 主控修：**覆盖面任何一条都不许吃进构建产物**（`D-G31` 同族另两处）。
      #   `#28` 只修了下面 `src/WpfGfx.Linux` 那一行；本行与下一行当时**恰好 0 命中**（现场实测
      #   落在 `obj|bin|.artifacts` 下的件数 = **0**）⇒ 属"**恰好没坏**"而不是"**被看着**"。
      #   修法两条约束（W29B 实测遵守）：
      #   ① **`-o` 链一个 token 都不动** —— 只把它**整体**用 `\( \)` 括起来，再与排除子句**相交**
      #      （`(A∨B∨C∨D) ∧ E` 与 `(A∧E)∨(B∧E)∨(C∧E)∨(D∧E)` 等价，但排除子句**只有一份**
      #      —— 抄四份正是 `#28` 那条"同一份逻辑存在两处必然分叉"的坑）。
      #      ⚠️ 这**不是**可选的洁癖：`-a` 比 `-o` 结合紧 ⇒ 若把排除子句**不加括号地**追加到链尾，
      #      它**只作用于最后一个析取支**（`-name 'close-wave.sh'`）⇒ 前面几条支**照样吃产物**。
      #      W29B 实测（`/tmp/w29b-prec`：`patch-a.py`/`close-wave.sh` 各一份，外加 `obj/` 下的同名副本）：
      #        括号形式（本行形状）        ⇒ 2 件，`obj/**` 两件**全被排除**；
      #        不加括号、追加到链尾        ⇒ 3 件，`obj/patch-a.py` **仍被吃进**（`obj/close-wave.sh` 被排除）
      #        ⇒ 那是**假修**：签名上"有排除"、实际上只有一支生效。
      #      （同法测"不加括号放在最前" ⇒ 3 件，换一支漏；**不是**"全树被收进"——
      #       W29B 初版注释曾写成"几乎全树都会被收进覆盖面"，**该说法被上式实测推翻并已更正**。）
      #      另：本行链尾那个 `-maxdepth 2` 与后面三个 `-maxdepth 1` 里，**最后一个胜**（见 ②）
      #      ⇒ `-maxdepth 2` 是**死子句**；W29B 只登记不改（改它会动"覆盖面可能收什么"的语义，
      #      当前树上 0 位移，应单列一趟由主控决定）。
      #   ② 括号**不改变** `-maxdepth` 的行为：GNU find 里它是**全局**选项、**最后一个胜**（W29B 实测：
      #      `find build \( -maxdepth 1 -name 'port-lib.py' -o -maxdepth 3 -name 'known-red.json' \)`
      #      打出**两者** ⇒ 生效的是 `3`）⇒ 本行的生效值仍是链尾那个 `1`，与修前**逐位相同**。
      #   修前/修后本行输出**逐字节相同**（25 件，`diff` 空）；`build/shims` 那行同理（13 件）。
      #   🦷 看住这三条的牙：`build/MilBridge/tools/fp-inputs-hygiene-check.sh`
      #      （判据 = 覆盖面里**不许**出现 `obj/`｜`bin/`｜`.artifacts/` 下的路径；三态 `0/1/2`；
      #       自带 `--selftest` 16 例，含"往覆盖面注入产物 ⇒ 必红"的成对反极性）。
      #      ⚠️ **本函数**在被它自测的覆盖面里**自含 `close-wave.sh`** ⇒ 改本文件必然改 `inputs_fp`
      #      （这是设计使然，不是本牙的副作用）；且 `#28` 已把 `tline-gate.sh` 也纳入覆盖面
      #      ⇒ **别的车道改门禁同样会改 `inputs_fp`**。
      find src/WpfGfx.Linux.Native/tools build \
          \( -maxdepth 2 -name 'patch-*.py' -o -maxdepth 1 -name 'port-lib.py' \
             -o -maxdepth 1 -name 'integration-wave.sh' -o -maxdepth 1 -name 'close-wave.sh' \) \
          -not -path '*/obj/*' -not -path '*/bin/*' -not -path '*/.artifacts/*' 2>/dev/null
      find build/shims -type f -name '*.cs' -not -path '*/obj/*' -not -path '*/bin/*' -not -path '*/.artifacts/*' 2>/dev/null
      # ⚠️【`#28` 主控修：**必须排除构建产物**】本行原先没有 `-not -path` ⇒ `find` 会吃进
      #   `src/WpfGfx.Linux/obj/Debug/net10.0/*.cs`（**构建生成**的 `AssemblyInfo.cs` 与
      #   `.NETCoreApp,Version=v10.0.AssemblyAttributes.cs`，实测 **2 份**）⇒ **每构建一次 `inputs_fp` 就变一次**
      #   ⇒ 「输入稳定性 波前==波后」这条断言**可以被构建本身打穿**，而它审的本来是"**有没有人手写改动**"。
      #   实测证据：`#28` 收尾 `close-wave` 记 `d409b483…`，其后 `verify-all` 只跑了一次 `dotnet build` ⇒
      #   本函数当场变成 `4a3519ea…`（**期间无人手写任何覆盖面文件**）⇒ 不修则本函数**量的不是输入**。
      find src/WpfGfx.Linux -type f -name '*.cs' -not -path '*/obj/*' -not -path '*/bin/*' 2>/dev/null
      # 【`#49` B4 / `R-CSRC`：**原生 C 源**必须进覆盖面】现场：`src/WpfGfx.Linux.Native/src/**`
      #   （`win32_x11.c`/`win32_core.c`/`win32_msg.c` … 共 13 件，含 `src/` 与 `tests/`）**原先一件都不在**本函数里
      #   ⇒ `R-CSRC`：`D-G50`（X 焦点回声）、`D-G55`（`SetCapture` 不派发 `WM_CAPTURECHANGED`）两次**产品级修法**
      #   都改在那里，而"输入稳定性 波前==波后"这条断言对它们**空成立**（改了整个波也看不出）。
      #   ⚠️ 与 `#29` 的 `D-G31` 同一条硬约束：**必须带产物排除** —— 判据件 `fp-inputs-hygiene-check.sh`
      #   （`verify-all` 第 `[12]` 步）断言本覆盖面里**不许**出现 `obj/`｜`bin/`｜`.artifacts/` 下的路径。
      #   （实测：本行加排除前后**输出逐字节相同**（各 13 件、0 件产物）⇒ 排除是"被看着"，不是"恰好没坏"。）
      #   ⚠️ 流程代价：从此**改原生源必须安排在 `IN_FP_0` 采样之前**，否则本脚本 `[4/6]` 自报 `IN_FP_0 != IN_FP_1` 并 `exit 5`。
      find src/WpfGfx.Linux.Native -type f \( -name '*.c' -o -name '*.h' \) \
          -not -path '*/obj/*' -not -path '*/bin/*' -not -path '*/.artifacts/*' 2>/dev/null
      # 【`#28` 主控加：**门禁与登记表**（`D-G22`/`D-G27` 同族）。理由三条，见 W28I 报告：
      #   ① 这两件**决定门禁判什么、门槛多高**，却原先**既不在本覆盖面、也不在 `GEN_KEYS`** ⇒
      #      改它们**零机器红**（`#28` 实测：`tline-gate.sh` 在 7 分钟内被改过两次）；
      #   ② 加进来后，**"本波动了门禁"这件事会在 `inputs_fp` 这一格上看得见**（跨波可比）；
      #   ③ **刻意不纳入 `build/MilBridge/arm-logs/*`** —— 它们是**派生件**（本表 `_FIELDTABLE` 的
      #      `arm_logs{}` 行与 `leg_resolution.why` 逐字自述），且**已有一颗更严的牙**
      #      （`generation.arm_logs` 全 64 位声明 ＋ 已接线的 `verify-all` 第 `[8]` 步 `ARM-LOG-SHA`）；
      #      更要紧的是**重取臂是合规动作**（纪律 34/59）⇒ 纳入后**每个重取过的波**都会
      #      `IN_FP_0 != IN_FP_1` ⇒ 把"输入稳定性"这条断言**自己搞成噪音**（实测机制证：重取用 `ln -f`）。
      #   ⚠️ **流程代价（必须记住）**：入门禁/登记表之后，**"改门禁"必须安排在 `IN_FP_0` 采样之前**
      #      （即**独立准备趟**），否则本脚本自己的 `[4/6]` 输入稳定性检查会 `exit 5`。
      # 【`#31` W31C 加：**四个新核对器**（`D-G22`/`D-G26` 同族 —— "判据改了自己没人看着"）】
      #   现场：`build/MilBridge/tools/` 下新增了四个**判据件**，它们**决定门禁判什么**，
      #   却既不在本覆盖面、也不在 `GEN_KEYS` ⇒ 改它们**零机器红**（与上面 `tline-gate.sh` 同族）。
      #   纳入的四件（现场 sha16 见报告 §3）：
      #     · `verify-all-step-check.sh` —— 第 `[11]` 步的步名/步数/口径句对账
      #     · `fp-inputs-hygiene-check.sh` —— 第 `[12]` 步（看住**本函数自己**的覆盖面）
      #     · `column-floor-check.sh`     —— 列级下限牙
      #     · `hidden-only-step.sh`       —— `D-T5-R` 的牙（`hiddenonly` 四格）
      #   ⚠️ **本行是"纳入读者"这件事本身**：加了之后，**改这四个件**都会移动 `inputs_fp`
      #      ⇒ 与 `tline-gate.sh`/`known-red.json` **同一条流程代价**（改它们要安排在 `IN_FP_0` 之前）。
      #   ⚠️ **它会不会把"波前==波后"变成噪音？不会**：这四个件按定义为"**波中改**"；
      #      而 `close-wave.sh` 的两次采样（`IN_FP_0`/`IN_FP_1`）**都在波尾**（`[4/6]` 段的两次调用）
      #      ⇒ 波中改完、波尾才采样，两次采到的是**同一份改后的值** ⇒ 稳定。**真正的噪音源是"波尾之后
      #      还有人改"**，那是流程违规（本波已在报告里点明），而不是本行的副作用。
      #      反证：`tline-gate.sh` 自 `#28` 纳入以来**每次波中都被改过**，而 `inputs_fp` 的
      #      "波前==波后"断言至今没有被它自己打穿过。
      #   ⏪ **`#31` 主控更正上面 `:136` 那句（**加注不覆盖**：原文一字未动，就地更正）**：
      #      那句写「两次采样（`IN_FP_0`/`IN_FP_1`）**都在波尾**（`[4/6]` 段的两次调用）」—— **与代码不符**。
      #      现盘逐字：`IN_FP_0` 在 `[0/6]` **之后、`[1/6]` 之前**（`:202`，屏上自己印的就是
      #      「**波前**输入指纹 = …」），`IN_FP_1` 才在 `[4/6]`（`:276`，`:277` 断言相等）。
      #      ⇒ 两次采样**分居波首与波尾**，`[1/6] integration-wave.sh` 正好夹在中间。
      #      ⚠️ **结论不变、推理必须换**（这才是关键：**错的推理会把人带进坑**）：
      #        正确的理由是 —— 采样窗口夹住的**只有 `[1/6]` 这一趟**（它是唯一可能重写覆盖面成员的步骤，
      #        而它只做"应用补丁 ＋ 构建"，对**逐字节不变的**生成物不产生差异），
      #        而**人手在 `close-wave` 之前**改的覆盖面成员，**两次采样都吃的是改后的值** ⇒ 稳定。
      #        真正会被这条断言抓住的，恰恰是「**`IN_FP_0` 与 `IN_FP_1` 之间有人手改**」——
      #        那**正是它该抓的**（不是噪音，是目的）。
      #      ⇒ 于是 `:123` 那条流程代价（"改门禁必须安排在 `IN_FP_0` 之前"）**与代码一致**，
      #        而 `:136` 那句曾说的"波中改也无所谓"是**反的** —— 已在 `#31` 更正（W31F 报告 §10 指出）。
      #   ⚠️ **`#33` 主控裁定：再纳入 1 件**（覆盖面 120 → 121）：`pipefail-sigpipe-check.sh`
      #      （`#33` 新建并接线为第 `[17]` 步的牙）—— 它**判什么算判据错** ⇒ 改它必须看得见。
      #   ⚠️ **`#32` 主控裁定：再纳入 5 件**（覆盖面 115 → 120）—— 判据件「**改它必须看得见**」这条
      #      纪律的**欠账**：`product-entry-step.sh`（`#32` 新建并接线）＋ **四件从 `#26`–`#29` 起
      #      就一直没被看着的牙**：`defect-registry-check.sh`（`#32` 真改了它 —— `D-G39` 的 SIGPIPE 伪红，
      #      `load1≈7.8` 时 **50%/趟**）、`baseline-sha-check.sh`、`arm-log-sha-check.sh`、
      #      `build-hygiene-import-check.sh`。⚠️ 这四件此前**既不在覆盖面、也不在 `GEN_KEYS`**
      #      ⇒ 改它们**零机器红**（与 `tline-gate.sh` 当年同族）。
      #   ⚠️ **`#31` 主控裁定：纳入 `shell-quote-trap-check.sh`**（W31C 那句「接线那一趟应把它一并
      #      加进本行」= 采纳）。理由与上面四件同族：它**判什么算陷阱**（双引号里的反引号），
      #      改它 = 改判据 ⇒ 不纳入则**零机器红**。它 `#31` 已接线（`verify-all.sh` 第 `[15]` 步）
      #      ⇒ 覆盖面 114 → **115**。
      #   【`#37` F2：纳入**时间分辨的画面读者** `frame-presence-check.sh`】
      #   ⚠️ 为什么必须纳入：它 `#34` 进仓、`#36` 接线成 `verify-all` 第 `[18]` 步，
      #      而它**判"画面在采样窗口里有没有出现过"** ⇒ **它是判据件**；此前**既不在本覆盖面、
      #      也不在 `GEN_KEYS`** ⇒ 换掉它的判据（例如把"至少一帧达标"改成"最后一帧达标"）
      #      **零机器红**（与 `tline-gate.sh` 当年同族；`#36` 的预登记 §3w ⑤ 已把它登记为缺口）。
      #   ⚠️ 流程代价与上面几件相同：从此**改它必须安排在 `IN_FP_0` 采样之前**。
      #   【`#37` B：**第三方形态 Runner** 也是判据件（它决定 `THIRDPARTY=PASS/FAIL`）】——
      #    与上面那些"判据改了自己没人看着"同族；不纳入 ⇒ 换掉它的阈值/判据**零机器红**。
      #    ⚠️ 血泪：**别把注释塞进这条续行链里** —— `\` 续行先拼行、再认注释，于是 `#` 会把
      #      链尾一起吃掉，后面那行路径就变成**独立命令**被执行（本波实测：它真的把样本跑了一遍，
      #      输出还被灌进了 `xargs sha256sum`）。注释只能写在这种**独立**的注释行上。
      # 【`#49` C2/C4：本波新纳入的**三件判据/执行件**（同族 —— "判据改了自己没人看着"）】
      #   · `build/MilBridge/tools/sync-applocal.sh`  —— **`#49` 新件**：把"五件"权威件同步到**任意目标目录**
      #     （含仓外应用目录）＋ 逐件回读断言 ＋ manifest。接线后它决定"探针/示例实跑的是哪一代件"
      #     ⇒ 是**判据件**（改它必须安排在 `IN_FP_0` 之前）。
      #   · `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` —— `APPSYNC=` 的**判据本体**
      #     （十类口径），而 `build/close-wave.sh` 的 `[4/6] 身份自检` **正在执行它**（实测：
      #     `grep -n 'applocal' build/close-wave.sh` 原先只命中那一行**调用**）⇒ 改它/把 `ITEMS` 里
      #     某件删掉，**零机器红**（`C4`：与 `tline-gate.sh` 在 `#28` 之前同族）。
      #   · `build/DirectWrite.Linux/wic-shim/applocal-expect.py` —— **期望副本集合**的声明式来源
      #     （产 `#EXPECT|` 行）⇒ 它决定"应该有哪些副本"，改它同样零红（`C4`）。
      #   ⚠️ 有意**不**纳入 `sync-applocal-authority.sh`（同一目录下"执行判据结论、真写副本"的那件）：
      #     它每次波尾都会真刷副本 ⇒ 把它算进"输入稳定性"会把该断言自己搞成噪音（同 `arm-logs/` 的裁定）；
      #     本波只**登记**这条边界，不顺手扩大覆盖面（如实划界，见 `docs/WAVE49-PREREGISTRATION.md` §8）。
      # 【`#50` W91A：本波新纳入的**两件 R-GATE 判据件**（同族 —— "判据改了自己没人看着"）】
      #   · `build/MilBridge/tools/r-gate-step.sh` —— 第 `[26]` 步 `R-GATE（连续交互）` 的**判据唯一实现**
      #     （13 格判据 ＋ 三态机读行 `R_GATE=PASS|FAIL|NOINFO`）。它**决定"连续点击算不算过"**
      #     ⇒ 改它 = 改 PASS 的定义；不纳入则**零机器红**（`#26` W84A 建它时把它登记为缺口）。
      #   · `build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh` —— 同一第 `[26]` 步的**装置**：
      #     它落证据（`evidence.txt` 的 `appline_from/to` 区间 ＋ `app.log` 原文）而不裁决，
      #     但**装置改了读数就改了**（例如少点一下、把指针移出窗口）⇒ 同样是判据的承重件。
      #   ⚠️ 流程代价与上面几件相同：从此**改这两件必须安排在 `IN_FP_0` 采样之前**。
      #   ⚠️ **残留缺口（如实登记，本波不扩大改面）**：本波另有三件**改了却仍不在覆盖面里**的件 ——
      #     `verify-all.sh`（第 `[26]` 步＋四处声明；**实测它本来就不在覆盖面**，与本行无关）、
      #     `build/PresentationFramework.Linux/reapply-patches.py` 与 PF 的 `*.Linux.cs` 生成件
      #     （`TASK-0303` 的 `A2/A3` 修法所在）⇒ 对 `inputs_fp` **不可见**，只有 `ARTIFACT-SRC-FP` 看得见。
      # 【`#56` W142A 补一行（**主控 22:5x 逐条批准**）：`regression-decision-cases.tsv` 是第 `[29]` 步
      #   `REGRESSION-DECISION` 的**判据输入** —— `verify-all.sh:959` 把它当 `--cases` 交给牙，
      #   牙逐行比对「台账里**声明的期望** == 工具给的判词」⇒ **改台账 = 改 PASS 的定义**
      #   （与 `tline-gate.sh`／`known-red.json`／`r-gate-step.sh` **同族**：判据件改它必须看得见）。
      #   机械证（两向，都已现场跑过）：
      #     ① `grep -c 'regression-decision' build/MilBridge/tools/tline-gate.sh` = **0**
      #        ⇒ 五臂门禁**不读**它（所以它**不是**走 `tline-gate.sh` 那条路进来的）；
      #     ② `grep -n 'regression-decision-cases' verify-all.sh` = `:959`（步 `[29]` 的 `--cases` 参数）
      #        ⇒ **接线后的 `verify-all` 读它**。
      #   判据：**读 ⇒ 进 `fp_inputs()`**（若判"不读"，则须给"命中 0"的机械证才能不进）。
      #   ⚠️ 本行让 `inputs_fp` 再位移一次（连同 `close-wave.sh` 自含于覆盖面）⇒ 属**设计性变更**，
      #      必须在 `IN_FP_0` 采样**之前**落定（本行落在此处，早于波）。
      # 【`#64` W157A（`TASK-0717`）加两行：`D-G118` 的牙 ＋ **它自己的台账**。
      #   判据照 `#56` 那条「**读 ⇒ 进 `fp_inputs()`**」：本牙**决定门禁判什么**
      #   （基线率闸：*在册速率还能不能用来定 `N`* —— 时间窗／同窗现取／闸是否被排除），
      #   而它在 `verify-all.sh` 第 `[37]` 步被接线 ⇒ `verify-all` **波波都读它**；台账同因
      #   （`--cases` 的输入：11 行确定性用例，改它 = 改门禁判什么）。
      #   **先例（存量惯例，不是本波发明）**：回归判定牙**与它的台账**成对在名单里
      #   （`bash ~/w153a/bin/infp.sh list` 实测命中 2 行）⇒ 本波照同一体例「牙 ＋ 台账」成对入名单。
      #   ⚠️ 本函数**自含 `close-wave.sh`** ⇒ 本行改动必然再挪一次 `inputs_fp`（设计使然）。
      #   ⚠️ 下面两行**必须留在 `\` 续行的参数表内**：注释只能放在**语句之前** ——
      #      插进续行中间会把 `printf` 截断，并把后续行当**命令执行**（本波现场咬到过，见 W157A 报告）。
      #   ⚠️ **九位**：本波零产品改动 ⇒ 只允许 `pf` 同尺寸位移；出现第二处 ⇒ 停手报主控。
      # 【`#66` W158A（`TASK-0720`）加一行：`Nl*`（连字/拼写）有意降级的**判据牙**
      #   `build/MilBridge/tools/nl-intent-check.sh`。判据照本函数上方那条
      #   「**读 ⇒ 进 `fp_inputs()`**」的同族惯例：它是**判据件**（导出面出现那 6 个 `Nl*`
      #   ⇒ 必红；声明面缺合格声明行 ⇒ FAIL），与 `ime-landing-check.sh` 同目录、同风格。
      #   ⚠️ 本改**必须排在 `IN_FP_0` 采样之前**，且**与整波同趟**（本函数自含 `close-wave.sh`
      #      ⇒ 改本文件必然再挪一次 `inputs_fp`；这是设计使然，不是副作用）。
      #   ⚠️ 新增的那一行**必须留在 `\` 续行的参数表内** —— 注释只能放在**语句之前**
      #      （插进续行中间会把 `printf` 截断，并把后续行当**命令执行**；本仓现场咬到过）。
      # 【`#71`（`TASK-0729`）**加二十行**：`build/MilBridge/tests/PtsPagesProbe/` 的**装置四件**
      #   （`session_inner.sh`／`navclick.py`／`legs-to-env.py`／`shotstat.py`）＋ **`evidence/` 十六件**。
      #   现场（`TASK-0729` 原话）：`fp_inputs()` 原先只显式收录 `pts-pages-guard.sh`（判据件）与
      #   `run-pts-pages-legs.sh`（装置入口）**两件** ⇒ 上面那 20 件**全在覆盖面之外** ⇒
      #   **改了它们（含 `leg_*.env` 证据）本步照样绿** ⇒ 第 `[38]` 步 `PTS-PAGES` 的判据输入
      #   不受指纹保护（这正是 `D-G122`／`TASK-0729` 的形态：**判据的输入没人看着**）。
      #   判据照本函数上方那条「**读 ⇒ 进 `fp_inputs()`**」：第 `[38]` 步的判据件
      #   `pts-pages-guard.sh --legs <目录>` **读**的就是 `evidence/`（装置四件则决定"读出来的读数对不对"）。
      #   ⚠️ **本行改动必然再挪一次 `inputs_fp`**（本函数自含 `close-wave.sh`，设计使然）。
      #   ⚠️ **覆盖面变 ⇒ 步本体里那个显式常数必须同趟改**：第 `[42]` 步的 `--expect 172` → **`192`**
      #      （`verify-all.sh` **不在**覆盖面 ⇒ 该常数与生产路径无关；**漏改 ⇒ `files-n-mismatch delta=-20`**）。
      #   ⚠️ **流程代价（必须记住）**：`evidence/` 从此进覆盖面 ⇒ **有意重产证据（重跑装置）必须安排在
      #      `IN_FP_0` 采样之前**，否则本脚本自己的 `[4/6]` 输入稳定性检查会 `exit 5`
      #      （与 `#29`／`#31` 登记的流程代价同族）。
      #   ⚠️ **射程**：`build/DirectWrite.Linux/evidence`（13 件）**不在本波射程**；空件
      #      （`evidence/device/xvfb.log`＝0 B）**合法**（`#70` 的存在性判据只查"存在 ∧ `sha256sum` `stderr` 空"）。
      # 【`#73`（`TASK-0726`）**加两行**：`build/MilBridge/tests/SilentHitProbe/` 的**产出端**
      #   `run-silenthit-legs.sh`（「静默 SEGV」那条腿唯一落盘层：起显示、起应用、跑配方、
      #   收装置、把观测变成机读行）＋ 它的**剔除集** `silenthit-trim.tsv`。
      #   现场（`TASK-0726` 原话）：判据端 `silent-hit-v2-check.sh` `#68` 已入仓并接线成第 `[39]` 步，
      #   而**产出端仍在车道目录**（8 份同形副本）⇒ 第 `[39]` 步只能走 `--cases`（确定性台账），
      #   **没有**任何一个仓内件能把一趟真腿变成 `APP_TEXT_BYTES_TRIMMED`／`SEGV_BRANCH` ⇒
      #   「判据有了、产出端没有」正是 `D-G122` 族（**判据的输入没人看着**）。
      #   判据照本函数上方那条「**读 ⇒ 进 `fp_inputs()`**」：`--legs-from` **读**的就是本产出端产的表，
      #   而剔除集**决定** `APP_TEXT_BYTES_TRIMMED` 这个承重格的**每一个字节**
      #   （它是剔除集的**唯一来源**：仓内 `find . -name '*trim*'` 现取命中 **0** 件；
      #    判据端**只消费**产出端自报的两数并与台账 `trimmed` 列交叉核，**不另持一份口径**）⇒
      #   改它＝改判据输入 ⇒ 不纳入则**零机器红**（与 `ime-landing-check.sh`／`nl-intent-check.sh` 同族）。
      #   ⚠️ **本行改动必然再挪一次 `inputs_fp`**（本函数自含 `close-wave.sh`，设计使然）。
      #   ⚠️ **覆盖面变 ⇒ 步本体里那个显式常数必须同趟改**：第 `[42]` 步的 `--expect 192` → **`194`**
      #      （`verify-all.sh` **不在**覆盖面 ⇒ 该常数与生产路径无关；**漏改 ⇒ `files-n-mismatch delta=-2`**）。
      #   ⚠️ 新增两行**必须留在 `\` 续行的参数表内** —— 注释只能放在**语句之前**
      #      （插进续行中间会把 `printf` 截断，并把后续行当**命令执行**；本仓现场咬到过）。
      #   ⚠️ **射程**：产出端是**重活形态**（起显示＋起应用）⇒ 它**不在门禁里同步跑**；
      #      本两行进覆盖面只保证「**改了会被看见**」，**不**保证「每一波都真跑过一条腿」。
      # 【`#74` W172A（`TASK-0733`／`0734`／`0735`）**加三行 —— 显式扩面（主控 `2026-09-26` 裁定 (B)）**：
      #   现场（本车道**现取**普查）：把 `verify-all.sh` **全部 `42` 条** `run_step` 行里引用的**仓内件**
      #   抽成集合（`grep '^run_step "' … | grep -oE '(build|src|samples|docs)/…\.(sh|py|tsv|json|txt)' | sort -u`），
      #   与**覆盖面活清单**（`fp-manifest-step.sh --expect 194` 现跑，`names_n=194`）取差集
      #   ⇒ **恰好三件未被保护**，且**三件都在门禁里承重**：
      #     · `build/MilBridge/tools/prereg-four-requirements-check.sh`（第 `[34]` 步 `PREREG-FOUR-REQ`，`--gate`）
      #     · `build/MilBridge/tools/pc-line-step.sh`（`PcLineOracle·Start` 列；件头自称"冻树牙齿"）
      #     · `build/MilBridge/tools/frame-step.sh`（`FrameProbe-frame`；件头自称"冻树牙齿"）
      #   判据照本函数上方那条「**读 ⇒ 进 `fp_inputs()`**」：三件的读者都是**生产门禁的一步**
      #   ⇒ 改它们 ＝ 改 `PASS` 的定义；不纳入则**零机器红**
      #   （与 `ime-landing-check.sh`／`nl-intent-check.sh`／`TASK-0729` 那 20 件同族：**判据的输入没人看着**）。
      #   ⚠️ **这是显式扩面（主控批准），不是顺手加的行** —— 原派单只点名了其中一件。
      #   ⚠️ 收口判据 ＝ **复跑同一次普查**得「**未被覆盖面保护的接线件 = 0**」
      #      （命令逐字写在 `docs/WAVE74-PREREGISTRATION.md` §1.3，将来任何冻结都可复跑）。
      #   ⚠️ **覆盖面变 ⇒ 步本体里那个显式常数必须同趟改**：第 `[42]` 步 `--expect 194` → **`197`**
      #      （`verify-all.sh` **不在**覆盖面 ⇒ 该常数与生产路径无关；**漏改 ⇒ `files-n-mismatch delta=-3`**）。
      #   ⚠️ 新增三行**必须留在 `\` 续行的参数表内** —— 注释只能放在**语句之前**
      #      （插进续行中间会把 `printf` 截断，并把后续行当**命令执行**；本仓现场咬到过）。
      printf '%s\n' build/MilBridge/tools/tline-gate.sh build/MilBridge/known-red.json \
          build/MilBridge/tools/verify-all-step-check.sh build/MilBridge/tools/fp-inputs-hygiene-check.sh \
          build/MilBridge/tools/column-floor-check.sh build/MilBridge/tools/hidden-only-step.sh \
          build/MilBridge/tools/shell-quote-trap-check.sh build/MilBridge/tools/product-entry-step.sh \
          build/MilBridge/tools/defect-registry-check.sh build/MilBridge/tools/baseline-sha-check.sh \
          build/MilBridge/tools/arm-log-sha-check.sh build/MilBridge/tools/build-hygiene-import-check.sh \
          build/MilBridge/tools/pipefail-sigpipe-check.sh \
          build/MilBridge/tools/frame-presence-check.sh \
          build/MilBridge/tools/r-gate-step.sh \
          build/MilBridge/tools/nul-bytes-check.sh \
          build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh \
          build/MilBridge/tools/sync-applocal.sh \
          build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh \
          build/DirectWrite.Linux/wic-shim/applocal-expect.py \
          samples/ThirdPartyMini/run-thirdparty-mini.sh \
          build/MilBridge/tools/hygiene-tooth.sh \
          build/MilBridge/tools/regression-decision.py \
          build/MilBridge/tools/uia-door-check.sh \
          build/MilBridge/tools/ime-landing-check.sh \
          build/MilBridge/tools/known-red-arms-check.sh \
          build/MilBridge/tools/geom-revert-beat-check.sh \
          build/MilBridge/tools/geom-resend-regression-check.sh \
          build/MilBridge/tools/proc-pattern-guard.sh \
          build/MilBridge/tools/baseline-rate-gate.sh \
          build/MilBridge/tools/baseline-rate-cases.tsv \
          build/MilBridge/tools/pts-pages-guard.sh \
          build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh \
          build/MilBridge/tools/regime-identity-check.sh \
          build/MilBridge/tools/fp-manifest-teeth-check.sh \
          build/MilBridge/tools/regression-decision-cases.tsv \
          build/MilBridge/tools/nl-intent-check.sh \
          build/MilBridge/tools/silent-hit-v2-check.sh \
          build/MilBridge/tools/silent-hit-v2-cases.tsv \
          build/MilBridge/tools/backup-completeness-gate.sh \
          build/MilBridge/tools/repo-alias-check.sh \
          build/MilBridge/repo-alias-allow.tsv \
          build/MilBridge/tools/bak-completeness-step.sh \
          build/MilBridge/tools/fp-manifest-step.sh \
          build/MilBridge/tools/prereg-four-requirements-check.sh \
          build/MilBridge/tools/pc-line-step.sh \
          build/MilBridge/tools/frame-step.sh \
          build/MilBridge/tests/PtsPagesProbe/session_inner.sh \
          build/MilBridge/tests/PtsPagesProbe/navclick.py \
          build/MilBridge/tests/PtsPagesProbe/legs-to-env.py \
          build/MilBridge/tests/PtsPagesProbe/shotstat.py \
          build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log \
          build/MilBridge/tests/PtsPagesProbe/evidence/device.txt \
          build/MilBridge/tests/PtsPagesProbe/evidence/session.txt \
          build/MilBridge/tests/PtsPagesProbe/evidence/leg_23.env \
          build/MilBridge/tests/PtsPagesProbe/evidence/leg_24.env \
          build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/device.txt \
          build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/leg_23.env \
          build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/leg_24.env \
          build/MilBridge/tests/PtsPagesProbe/evidence/device/xvfb.log \
          build/MilBridge/tests/PtsPagesProbe/evidence/device/xfwm.log \
          build/MilBridge/tests/PtsPagesProbe/evidence/five_pre_g1.txt \
          build/MilBridge/tests/PtsPagesProbe/evidence/five_post_g1.txt \
          build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/boot.png \
          build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/k23.png \
          build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/k24.png \
          build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/last.png \
          build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh \
          build/MilBridge/tools/selfdescription-wiring-check.sh \
          build/MilBridge/tools/lane-path-check.sh \
          build/MilBridge/lane-path-provenance.tsv \
          build/MilBridge/tools/rows-identity-check.sh \
          build/MilBridge/tools/xvfb-census-check.sh \
          build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv \
          build/MilBridge/tools/pts-gap-count-check.sh \
          src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt \
          build/MilBridge/tools/boundary-decl-check.sh
    } | LC_ALL=C sort | xargs sha256sum | sha256sum | cut -d' ' -f1
}
sha16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }

say "=== 收官序列 $(date -Is)  loadavg=$(cut -d' ' -f1-3 /proc/loadavg)  OUT=$OUT"

# ── 0) 前置检查 ───────────────────────────────────────────────────────────────
say ""; say "──── [0/6] 前置检查"
# 【`D-G34`（`#30` W30C 修）：旧写法 `pgrep -af '…' | grep -v pgrep` 有**自匹配**洞】
#   ① `pgrep -f` 匹配的是**整条命令行文本** ⇒ **承载本脚本的那个 shell 自己**只要在命令行里
#      提到过那个名字（`#29` 现场：主控的 `bash -c '… samples/WpfTextDemo/ACCEPTANCE-BASELINE.md …'`
#      里引了基线文件路径）就会被匹配到 ⇒ **假报"有应用/探针在跑"、`exit 3`**
#      （其时实际只有两个 `Xvfb`、`loadavg 0.16`；换一支文本干净的包装脚本调用 ⇒ 立即通过）。
#      `grep -v pgrep` 只滤 `pgrep` 自己，**滤不掉调用者** —— 它是一条与缺陷无关的装饰。
#   ② 旧版命中时**只印一句"有应用在跑"**，不点名 ⇒ **"真停"与"假停"在屏上分不开**，
#      而这两种情形要做的动作完全相反（前者去关应用，后者去改调用方式）。
#   ⇒ 修法两条（都要；判据本身**不放宽**：真在跑仍然 `exit 3`）：
#      A. **把"本脚本自己及其全部祖先"从匹配结果里剔掉** —— 本判据要问的是"**别的**进程在不在跑"，
#         **承载本判据的进程链不算**（真应用不在本脚本的祖先链上：它是兄弟/子进程或另一棵树
#         ⇒ 不受本修法影响，三档成对读数见 `W30C-report.md` §②）。
#      B. **逐条点名**（`pid` ＋ 命令行）⇒ 假停当场可辨（"这条命中的是我自己的另一条车道"）。
#   ⚠️ 祖先链用 `/proc/<pid>/stat` 的 `ppid` **现算**，**不用** `pgrep -f`／`ps|grep`
#      —— 它们自己就会自匹配，而本条缺陷**就是这个坑的现场**（纪律 55 家族）。
#   ⚠️ 残余洞（如实记）：**非祖先**的无关进程只要命令行文本里提到那个名字，仍会被算成"在跑"
#      （例如并行的另一条只读车道正在 `grep … WpfTextDemo …`）。这不能靠祖先链解决
#      —— 靠 B 的点名让人一眼看穿；若将来要根治，应改成按**可执行件名**匹配（另一趟的事）。
# 【`#71`（`TASK-0727`）**根治上一条**：判据从「**按命令行文本匹配**」改成「**按可执行件名**」。
#   现场（2026-09-24 波 `#66` `18:42:45`）：一条**推文档的 shell**（`bash -c … python3 - <<'PY' …`，
#   heredoc 正文里提到 `WpfFeatureProbe`／`WpfTextDemo`）被旧判据判成"有应用/探针在跑" ⇒ **整波被挡一次**
#   （0 损害，但**假阳挡波**是这一族最贵的形态：挡波的理由与要做的动作**完全相反**）。
#   修法三条（**判据不放宽**：真有应用在跑**仍然** `exit 3`）：
#     ① 枚举**只读** `/proc/<pid>`：`exe`（只读符号链接的基名）＋ `cmdline`（NUL 分隔的 `argv`）
#        —— **不再用** `pgrep -af`（`-f` 比的是**整条命令行文本**，那正是假阳的根因，也是 `D-G103` 家族）；
#     ② 三个面各判「**这个进程在执行什么**」，不是「这条命令行里出现过什么字」：
#        面① `exe` 基名 = 应用本体（apphost 被直接执行）；
#        面② `argv[0]` 是 `dotnet` 族 ∧ **被执行的那一项**（`argv[1]`；`argv[1]=exec` 时取 `argv[2]`）
#             基名 = 应用程序集；或 `argv[0]` 是 shell ∧ `argv[1]` 基名 = 启动器脚本名；
#        面③ `exe` 是 `dotnet` 族而 `argv` **判不了**（为空／读不到）⇒ **判不了**。
#     ③ **判不了就不挡、但绝不冒充绿**：面③ 记 `cap=1`／`undecidable=<n>`，机读行转 `NOINFO`
#        （依据 = 主控入库的环境读数 `K16`：`["dotnet","WpfFeatureProbe.dll","3"] ⇒ cmdline=[]`）。
#        风险方向 = **假阴**（真应用在跑却漏检 ⇒ 重建会覆盖被 mmap 的 `.so`）—— **如实登记，不当绿**。
#   ⚠️ **为什么不再把"波内构建"当占用**：波内构建跑的是 `dotnet …/MSBuild.dll …`（`argv[1]` 是 `MSBuild.dll`）
#      ⇒ 面② 的结构（判**被执行项**、不判"argv 里出现过路径"）**构造上**不会命中它；旧规则是**子串**
#      ⇒ 任何提到 `WpfFeatureProbe` 的命令行都命中。
#   ⚠️ **为什么 `verify-all.sh` 在跑也不算占用**：它不是**应用本体**，旧行为**本来就不挡**它
#      ⇒ 把它纳入是**行为扩面**，不在本任务口径内（主控 `#71` 裁定）；将来要它须**另开任务、判据先写**。
APP_EXE_APPS='WpfTextDemo WpfFeatureProbe'
APP_ASM_APPS='WpfTextDemo.dll WpfFeatureProbe.dll'
APP_LAUNCHERS='run-wpftextdemo.sh run-wpfprobe.sh run-wpfprobe-1400rate.sh'
SHELL_BASENAMES=' bash sh dash ksh zsh '
self_chain_pids() {   # 打 `$$` 及其**全部祖先**的 pid（每行一个；只读 `/proc`）
    local pid=$$ p
    while [ -n "$pid" ] && [ "$pid" != 0 ] && [ "$pid" != 1 ]; do
        printf '%s\n' "$pid"
        p="$(sed 's/^.*) //' "/proc/$pid/stat" 2>/dev/null | awk '{print $2}')"
        if [ -z "$p" ] || [ "$p" = "$pid" ]; then break; fi
        pid="$p"
    done
}
app_probe_classify() {   # <exe基名> <argv0> <argv1> <argv2> ⇒ 打 `app face=…` / `cap face=…` / `-`
    # 纯函数（**不读 `/proc`**）⇒ 可被内容锚抽出原文单测：判的只有"可执行件名"三面。
    local exe="$1" b0="${2##*/}" b1="${3##*/}" b2="${4##*/}" n
    if [ "$b1" = exec ]; then b1="$b2"; fi        # `dotnet exec <app>.dll`：被执行项在 argv[2]
    for n in $APP_EXE_APPS; do
        if [ "$exe" = "$n" ]; then printf 'app face=exe\n'; return 0; fi
    done
    for n in $APP_LAUNCHERS; do
        if [ "$b1" = "$n" ]; then
            case "$SHELL_BASENAMES" in *" $b0 "*) printf 'app face=launcher\n'; return 0 ;; esac
        fi
    done
    case "$b0" in
        dotnet|dotnet-*)
            for n in $APP_ASM_APPS; do
                if [ "$b1" = "$n" ]; then printf 'app face=argv-asm\n'; return 0; fi
            done
            if [ -n "$b1" ]; then printf -- '-\n'; return 0; fi
            printf 'cap face=argv-undecidable\n'; return 0 ;;
    esac
    printf -- '-\n'
}
app_probe_scan() {   # 枚举 `/proc`（**只读**）；命中/判不了的行打 stdout；计数写 census 件
    local excl pid exe cls d e0 e1 e2
    local -a av=()
    excl=" $(self_chain_pids | tr '\n' ' ')"
    APP_PROBE_EXAMINED=0; APP_PROBE_HITS=0; APP_PROBE_UNDEC=0
    for d in /proc/[0-9]*; do
        pid="${d#/proc/}"
        case "$excl" in *" $pid "*) continue ;; esac   # 排除**本判据自己的整条进程链**（含 `$$` 与 `$PPID`）
        # ⚠️ 两个路径**写成 `/proc/<pid>/…` 字面量**（不用 `$d/…`）：这样本枚举对
        #    `build/MilBridge/tools/proc-pattern-guard.sh`（第 `[27]` 步）**可见**，并被它按
        #    "`/proc` 枚举他人 pid ⇒ 必须能证明排除了自己"逐格判 —— 我实测过：写成 `$d/cmdline`
        #    时那条牙**看不见**本行（同行内既要有 `/proc` 又要有 `cmdline`）⇒ 那是"靠看不见过关"的
        #    假绿形态（正是该牙头注释里记的它自己的自伤）。**宁可见而受审，不可隐而免审。**
        exe="$(readlink "/proc/$pid/exe" 2>/dev/null)"; exe="${exe##*/}"
        [ -n "$exe" ] || continue    # exe 读不到 ⇒ 内核线程/僵尸：**没有 mmap ⇒ 不可能持有 .so** ⇒ 出射程
        APP_PROBE_EXAMINED=$((APP_PROBE_EXAMINED+1))
        av=()
        mapfile -d '' -t av < "/proc/$pid/cmdline" 2>/dev/null
        e0="${av[0]:-}"; e1="${av[1]:-}"; e2="${av[2]:-}"
        cls="$(app_probe_classify "$exe" "$e0" "$e1" "$e2")"
        case "$cls" in
            app*) APP_PROBE_HITS=$((APP_PROBE_HITS+1))
                  printf '%s %s exe=%s argv0=%s argv1=%s\n' "$pid" "$cls" "$exe" "${e0##*/}" "${e1:-<空>}" ;;
            cap*) APP_PROBE_UNDEC=$((APP_PROBE_UNDEC+1))
                  printf '%s %s exe=%s argv0=%s argv1=<空或读不到>\n' "$pid" "$cls" "$exe" "${e0##*/}" ;;
        esac
    done
    # ⚠️ **一件一行**（`examined=…\nhits=…\nundecidable=…`）：写成一行三格时，下面的
    #    `IFS='=' read -r k v` 会把**第一格之后的所有内容**都塞进 `v`（`v="143 hits=0 undecidable=0"`）
    #    ⇒ 机读行印出 `examined=143 hits=0 undecidable=0 hits=0 undecidable=0` 这样的**畸形读数**
    #    （本车道现场被自己的 `P2` 腿当场咬到；`D-G120` 家族：**形状看着完好，内容已经错位**）。
    printf 'examined=%s\nhits=%s\nundecidable=%s\n' "$APP_PROBE_EXAMINED" "$APP_PROBE_HITS" "$APP_PROBE_UNDEC" \
        > "$OUT/app-probe-census.txt"
}
PROBE_CENSUS="$OUT/app-probe-census.txt"
APP_PROBE_LINES="$(app_probe_scan)"     # ⚠️ 子 shell ⇒ 计数只能经 census 件传出来
APP_PROBE_EXAMINED=0; APP_PROBE_HITS=0; APP_PROBE_UNDEC=0
if [ -r "$PROBE_CENSUS" ]; then
    while IFS='=' read -r k v; do
        case "$k" in
            examined)    APP_PROBE_EXAMINED="$v" ;;
            hits)        APP_PROBE_HITS="$v" ;;
            undecidable) APP_PROBE_UNDEC="$v" ;;
        esac
    done < "$PROBE_CENSUS"
fi
# ⚠️ 纪律 5：**零检查也必须报红** —— 枚举没跑出读数 / 一件都没读到 ⇒ `NOINFO`，**不许静默当绿**。
PROBE_VERDICT="PASS"
if [ ! -r "$PROBE_CENSUS" ]; then
    PROBE_VERDICT="NOINFO reason=census-missing(枚举没跑出读数)"
elif [ "$APP_PROBE_EXAMINED" -eq 0 ]; then
    PROBE_VERDICT="NOINFO reason=zero-examined(一件都没读到 ⇒ 零检查不许当绿)"
elif [ "$APP_PROBE_HITS" -gt 0 ]; then
    PROBE_VERDICT="BLOCK"
elif [ "$APP_PROBE_UNDEC" -gt 0 ]; then
    PROBE_VERDICT="NOINFO reason=undecidable-dotnet-argv(面 3 判不了)"
fi
say "  APP_PROBE_GUARD=${PROBE_VERDICT} faces=3 face3=cap cap=1 examined=${APP_PROBE_EXAMINED} hits=${APP_PROBE_HITS} undecidable=${APP_PROBE_UNDEC}"
case "$PROBE_VERDICT" in
    BLOCK)
        say "  ❌ 有应用/探针在跑 —— 先让它们退出（重建会覆盖被 mmap 的 .so）"
        while IFS= read -r l; do [ -n "$l" ] && say "       · 命中：$l"; done <<< "$APP_PROBE_LINES"
        exit 3 ;;
    NOINFO*)
        while IFS= read -r l; do [ -n "$l" ] && say "       · 判不了：$l"; done <<< "$APP_PROBE_LINES"
        say "     （**刻意的**：判不了就不挡，但**绝不冒充绿** —— 机读行已记 NOINFO；风险方向＝假阴）"
        say "     （面 3 = dotnet 宿主而 argv 为空/读不到；本绿的覆盖面**只有 2/3 面**）" ;;
    *)
        say "     ⚠️ 如实划界：面 3（dotnet 宿主而 argv 判不了）**判不了就不挡** ⇒ 本绿的覆盖面**只有 2/3 面**。" ;;
esac
if [ -e /tmp/bridge-republish.lock ]; then say "  ❌ 存在 /tmp/bridge-republish.lock（有人正在重发）"; exit 3; fi
say "  ✅ 无应用进程、无重发锁"
IN_FP_0="$(fp_inputs)"; say "  波前输入指纹 = $IN_FP_0"
for f in build/shims/PresentationCore.HbTextLine.cs src/WpfGfx.Linux/Rendering/DrawInstructionCensus.cs \
         src/WpfGfx.Linux/Rendering/SkiaRenderBackend.cs src/WpfGfx.Linux.Native/src/win32_core.c \
         src/WpfGfx.Linux.Native/src/win32_x11.c src/WpfGfx.Linux.Native/src/win32_msg.c; do
    [ -f "$f" ] && say "    $(sha16 "$f")  $f"
done

# ── 决策：该重建什么（**在动手之前先算清**，也让 --dry-run 能只算不做）──────
NATIVE_AUTH="src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
NEED_NATIVE=0
[ "$FORCE_NATIVE" = 1 ] && NEED_NATIVE=1
if [ -f "$NATIVE_AUTH" ]; then
    # 注意 `-printf` 只作用于它前面的那个 -name 谓词 ⇒ 必须用 \( \) 把两个 -name 括起来，
    # 否则 `*.h` 的结果不带时间戳（本脚本初版就踩了这条：会得到空值 ⇒ 误判"不必重建"）。
    newest_src="$(find src/WpfGfx.Linux.Native \( -name '*.c' -o -name '*.h' \) -printf '%T@\n' 2>/dev/null | sort -rn | head -1 | cut -d. -f1)"
    if [ -n "$newest_src" ] && [ "$newest_src" -gt "$(stat -c %Y "$NATIVE_AUTH")" ]; then NEED_NATIVE=1; fi
else
    NEED_NATIVE=1
fi
FP_NOW="$(bash build/bridge-src-fp.sh | sed -n 's/.*BRIDGE_SRC_FP=\([0-9a-f]\{16\}\).*/\1/p')"
FP_REC="$(sed -n 's/.*BRIDGE_SRC_FP=\([0-9a-f]\{16\}\).*/\1/p' build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/bridge-src-fp.txt 2>/dev/null | head -1)"
if [ "$FORCE_BRIDGE" = 1 ] || [ "$FP_NOW" != "$FP_REC" ]; then NEED_BRIDGE=1; else NEED_BRIDGE=0; fi
say ""; say "──── 计划：native 重建=$([ "$NEED_NATIVE" = 1 ] && echo 是 || echo 否)｜桥重发=$([ "$NEED_BRIDGE" = 1 ] && echo 是 || echo 否)（现树 fp=$FP_NOW 记录=${FP_REC:-无}）｜verify-all=$([ "$SKIP_VERIFY" = 1 ] && echo 跳过 || echo 跑)"
if [ "$DRY_RUN" = 1 ]; then
    say ""; say "  ✅ --dry-run：只算不做（**未运行波/未重建/未重发/未跑回归**）⇒ 退出码 0"
    say "     要真跑：「bash build/close-wave.sh」（可加 --native/--bridge/--skip-verify-all）"
    exit 0
fi

# ── 1) 集成波（PC/PF/WB + 三道波内检查） ──────────────────────────────────────
run "[1/6] integration-wave.sh" bash build/integration-wave.sh

# ── 2) native shim（按需重建 + 同步全部副本 + 断言同 sha） ────────────────────
if [ "$NEED_NATIVE" = 1 ]; then
    run "[2/6] native shim 重建（源码比权威件新，或 --native）" bash src/WpfGfx.Linux.Native/build-shim.sh --all
    say "  同步副本（**4 份必须同 sha**）："
    ASHA="$(sha16 "$NATIVE_AUTH")"
    while IFS= read -r c; do
        [ "$c" = "$NATIVE_AUTH" ] && continue
        cp -f "$NATIVE_AUTH" "$c"
        got="$(sha16 "$c")"
        [ "$got" = "$ASHA" ] && say "    ✅ $got  $c" || { say "    ❌ 同步失败：$got != $ASHA  $c"; exit 4; }
    done < <(find . -name 'libwpfwin32.so' -not -path './upstream/*' -not -path '*/.artifacts/*' 2>/dev/null | LC_ALL=C sort)
    while IFS= read -r c; do
        [ "$(sha16 "$c")" = "$ASHA" ] || { say "    ❌ 副本不同 sha：$c"; exit 4; }
    done < <(find . -name 'libwpfwin32.so' -not -path './upstream/*' -not -path '*/.artifacts/*' 2>/dev/null)
    say "  权威件 libwpfwin32.so = $ASHA（$(stat -c%s "$NATIVE_AUTH") B）"
else
    say ""; say "──── [2/6] native shim：源码不比权威件新 ⇒ **跳过重建**（要强制用 --native）｜$(sha16 "$NATIVE_AUTH")"
fi

# ── 3) 桥（源指纹不一致才重发） ───────────────────────────────────────────────
if [ "$NEED_BRIDGE" = 1 ]; then
    run "[3/6] 桥重发（现树 $FP_NOW ≠ 发布记录 ${FP_REC:-无}）" bash build/publish-milbridge.sh
else
    say ""; say "──── [3/6] 桥：源指纹一致（$FP_NOW == $FP_REC）⇒ **无需重发**（要强制用 --bridge）"
fi

# ── 4) 身份四件套 ─────────────────────────────────────────────────────────────
say ""; say "──── [4/6] 身份自检"
FP_NOW2="$(bash build/bridge-src-fp.sh | sed -n 's/.*BRIDGE_SRC_FP=\([0-9a-f]\{16\}\).*/\1/p')"
FP_REC2="$(sed -n 's/.*BRIDGE_SRC_FP=\([0-9a-f]\{16\}\).*/\1/p' build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/bridge-src-fp.txt 2>/dev/null | head -1)"
if [ "$FP_NOW2" = "$FP_REC2" ] && [ -n "$FP_NOW2" ]; then say "  ✅ 桥源指纹两侧一致：$FP_NOW2"
else say "  ❌ 桥源指纹不一致：现树=$FP_NOW2 记录=${FP_REC2:-无} ⇒ 部署件不是当前源编的（**事故 D 形态**）"; exit 5; fi

if python3 build/artifact-src-fp.py --check >>"$LOG" 2>&1; then say "  ✅ 生成物指纹 state=ok（PC/WB/PF）"
else say "  ❌ 生成物指纹非 ok（stale/noinfo；**stale 也可能是"源改了没重建"**）"; exit 5; fi

if bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh >>"$LOG" 2>&1; then say "  ✅ APPSYNC=PASS"
else say "  ⚠️ APPSYNC 非 PASS —— 逐条见日志（不必然是本次引入，但**别让探针测旧件**）"; fi

if bash build/check-appliers.sh >>"$LOG" 2>&1; then say "  ✅ 应用器审计 miss=0（**注册了但没生效**这一族已关门）"
else say "  ❌ 应用器审计 RED ⇒ 中止（重建出来的是旧语义）"; exit 5; fi

IN_FP_1="$(fp_inputs)"
if [ "$IN_FP_0" = "$IN_FP_1" ]; then say "  ✅ 输入稳定性：波前==波后 == $IN_FP_1（期间无手写改动）"
else say "  ❌ 输入指纹变了（波期间有人改了应用器/波脚本）⇒ 本次结果与「波后树」对不上"; exit 5; fi

# ── 5) 全量回归 ───────────────────────────────────────────────────────────────
if [ "$SKIP_VERIFY" = 1 ]; then
    say ""; say "──── [5/6] verify-all：**按要求跳过**（--skip-verify-all）⇒ 本趟不得作为完成判据③的依据"
else
    run "[5/6] verify-all.sh" bash verify-all.sh
fi


# ── 5b) 在册数防漂移（`D-G70`／`TASK-0720` 残项；**`#76` 新增**）────────────────────
# 【判什么】`D-G70` 的「在册数」（PTS 缺口：工具口径／**可操作**／实现口径）此前是一条
#   **零守卫的裸文本** —— `#66` 在**同一波里**既把它更正成 `103／91／97`、又落了 `P03`
#   （`win32_pts.c` 新增 3 条 `LsErr` 诚实失败导出 ⇒ `exports 547→550`）⇒ 那 3 个 `Lo*`
#   名字当场**离开缺口名单** ⇒ **更正它的那一刻它就已经过期**（真值 `100／88／97`），
#   而当时**没有任何在跑读数会响**（四个候选牙在 `verify-all.sh`／`integration-wave.sh`／
#   `known-red.json` 里**全 0 命中**）。车道路线图把它记成「在册数纠正」，但**纠正过的数
#   照样会漂** ⇒ 本步把它变成**每次冻结前现算 ＋ 逐字段对账**。
# 【放哪儿／为什么】主控 `2026-09-26` 裁定：**接线走 `close-wave.sh` 冻前，不加
#   `verify-all` 步**（理由：**冻结那一刻才是这个数说话的地方**）。本步落在 `[5/6]` 与
#   `[6/6]` **之间** ⇒ ① 此时 `[2/6]` 已重建 shim、`[4/6]` 已过身份自检、`[5/6]` 已过全量回归
#   ⇒ 读的是**最终态**；② 本步红 ⇒ `run()` 当场 `exit` ⇒ **`[6/6] 汇总` 与两哨兵都不会落**
#   ⇒ 「在册数是假的」这件事**不可能被写成一份形状完好的收波记录**。
# 【它不判什么（如实划界）】只判「**在册数与其 6 处正文复述位一致**」，
#   **不判**「88／97 这个数在语义上对不对」（那是 `D-G70` 的取证部分）；
#   复述位所在的**文档件**不在 `fp_inputs()` 覆盖面内 ⇒ 改文档**不**移动 `inputs_fp`
#   （但改了**数**本步每次冻结都当场可见）。
# 【成本】纯读、零 `dotnet`、< 3 s；不写 `$R`。
say ""; say "──── [5b/6] 在册数防漂移（D-G70；三态 PTSGAP=PASS|FAIL|NOINFO，**NOINFO 不算绿**）"
run "[5b/6] pts-gap-count-check.sh" bash build/MilBridge/tools/pts-gap-count-check.sh

# ── 6) 汇总 ───────────────────────────────────────────────────────────────────
say ""; say "──── [6/6] 汇总（**八位 + 第九位 + 桥指纹**，逐字复制进下一版基线表头）"
{
    echo "# close-wave summary  $(date -Is)  OUT=$OUT"
    echo "bridge=$(sha16 build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so)  bridge_bytes=$(stat -c%s build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so)"
    echo "pc=$(sha16 build/PresentationCore.Linux/bin/$SELFBUILT_CONFIG/PresentationCore.dll)"
    echo "pf=$(sha16 build/PresentationFramework.Linux/bin/$SELFBUILT_CONFIG/PresentationFramework.dll)"
    echo "windowsbase=$(sha16 build/WindowsBase.Linux/bin/$SELFBUILT_CONFIG/WindowsBase.dll)"
    echo "provider=$(sha16 build/DirectWrite.Linux/Provider/bin/$SELFBUILT_CONFIG/DirectWrite.Linux.Provider.dll)"
    echo "win32shim=$(sha16 "$NATIVE_AUTH")  win32shim_bytes=$(stat -c%s "$NATIVE_AUTH")"
    echo "wic_shim=$(sha16 build/DirectWrite.Linux/wic-shim/libwpfwic.so)"
    echo "hbtextline_shim=$(sha256sum build/shims/PresentationCore.HbTextLine.cs | cut -c1-16)"
    echo "dwf=$(sha16 build/DirectWriteForwarder.Linux/bin/$SELFBUILT_CONFIG/DirectWriteForwarder.dll)"
    echo "BRIDGE_SRC_FP=$FP_NOW2"
    echo "inputs_fp=$IN_FP_1"
    BRIDGE_REPUB=$NEED_BRIDGE
    echo "native_rebuilt=$NEED_NATIVE  bridge_republished=$BRIDGE_REPUB"
    echo "verify_all=$([ "$SKIP_VERIFY" = 1 ] && echo SKIPPED || echo PASS)"
} | tee -a "$LOG" > "$SUMMARY"
# ── 哨兵同步（2026-09-14 加；T3 抓到"哨兵未更新"）────────────────────────────
# 【为什么写在这里】`/tmp/bridge-frozen.flag` 是各车道判断"当前件"的唯一入口，
#   而它此前**靠人手工更新** ⇒ 2026-09-14 出现"产物已换代、哨兵还是上一代"的事故
#   （T3 按纪律改用"主控给的九位 + 自己 sha256sum"才没被带偏）。
#   ⇒ 让**产生当前件的那条命令**顺手公布哨兵：谁重建，谁更新，不留人工步骤。
FLAG="${CLOSE_WAVE_FLAG:-/tmp/bridge-frozen.flag}"
{
    printf 'SHA=%s\n' "$(sha16 build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so)"
    printf 'FP=%s\n'  "$FP_NOW2"
    printf 'PC=%s\n'  "$(sha16 build/PresentationCore.Linux/bin/$SELFBUILT_CONFIG/PresentationCore.dll)"
    printf 'PF=%s\n'  "$(sha16 build/PresentationFramework.Linux/bin/$SELFBUILT_CONFIG/PresentationFramework.dll)"
    printf 'WB=%s\n'  "$(sha16 build/WindowsBase.Linux/bin/$SELFBUILT_CONFIG/WindowsBase.dll)"
    printf 'WIN32SHIM=%s\n' "$(sha16 "$NATIVE_AUTH")"
    printf 'HBTL=%s\n' "$(sha256sum build/shims/PresentationCore.HbTextLine.cs | cut -c1-16)"
    printf 'WIC=%s\n'  "$(sha16 build/DirectWrite.Linux/wic-shim/libwpfwic.so)"
    printf 'PROVIDER=%s\n' "$(sha16 build/DirectWrite.Linux/Provider/bin/$SELFBUILT_CONFIG/DirectWrite.Linux.Provider.dll)"
    printf 'DWF=%s\n'  "$(sha16 build/DirectWriteForwarder.Linux/bin/$SELFBUILT_CONFIG/DirectWriteForwarder.dll)"
    printf 'WAVE=%s\n' "$(basename "$OUT")"
    printf 'NOTE=本哨兵由 close-wave.sh 自动更新；基线号请在冻完后手工补 BASELINE=\n'
} > "$FLAG"
# ── 哨兵镜像（2026-09-15 加；防 `/tmp` 被整盘清掉）────────────────────────────
# 【为什么】2026-09-14 实测发生过 `/tmp` **被整盘清空**（连带丢掉哨兵、备份与日志）
#   ⇒ 同一份内容再写一份到 `$HOME/wfp-runs/`（与"scratch/备份放 `$HOME` 不放 `/tmp`"同族），
#   并**打印两处路径**；两处不一致时**以本波刚写的这份为准**（它就是"产生当前件的那条命令"的产物）。
FLAG_MIRROR="${CLOSE_WAVE_FLAG_MIRROR:-$HOME/wfp-runs/bridge-frozen.flag}"
if mkdir -p "$(dirname "$FLAG_MIRROR")" 2>/dev/null && cp -f "$FLAG" "$FLAG_MIRROR" 2>/dev/null; then
    say "  🔖 哨兵镜像已同步（$FLAG_MIRROR；防 /tmp 被清）"
else
    say "  ⚠️ 哨兵镜像写失败（$FLAG_MIRROR）—— 只更新了 $FLAG；本行即为证据，不要当成功"
fi
say "  🔖 哨兵已更新（$FLAG）：bridge=$(sha16 build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so) pc=$(sha16 build/PresentationCore.Linux/bin/Debug/PresentationCore.dll) win32shim=$(sha16 "$NATIVE_AUTH") hbtextline=$(sha256sum build/shims/PresentationCore.HbTextLine.cs | cut -c1-16)"

say ""; say "  ✅ 序列完成。汇总文件：$SUMMARY"
say "  ▶ **下一步（不能省）**：用上面的八位去跑应用级门禁并**重冻基线**（samples/WpfTextDemo/ACCEPTANCE-BASELINE.md），"
say "     然后重取 tline 六项 / RTL 三条 / --only=textbox-edit 等读数 —— **任何一位变了，旧基线即作废**。"
exit 0
