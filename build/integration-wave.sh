#!/usr/bin/env bash
#
# 集成波：把托管层移植工程整体拉回"身份一致 + 资源完整"的状态。
#
# 为什么需要它（2026-09-10 实测事故）：
#   port-lib 后来新增了「生成物自动公开签名」与「资源管线（显式清单名 / WPF <Resource> → .g.resources /
#   默认 resx glob）」，但**只有部分工程被重新生成过** → 树里同时存在两份身份不同的同名程序集
#   （例如 System.Xaml：权威产物 654,336 B/未签名/丢 SR 资源 vs 下游 bin 里 701,440 B/已签名/有资源），
#   表现为 PBT 的 MC1000，以及运行期 `System.SR.Format(null)` 的 ArgumentNullException。
#
# 顺序不可颠倒：port-lib 重生成 → 各工程补丁重放 → 按依赖序重建。
# 用法：bash build/integration-wave.sh
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# ★ `#39` 阶段 2/3：本波构建的配置来自**唯一声明**。
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../build/selfbuilt-config.sh"
cd "$REPO"
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

step() { printf '\n=== %s ===\n' "$*"; }
fail=0

# ── 责任归属闸（2026-09-14 加）─────────────────────────────────────────────────
# 【为什么】2026-09-14 18:15:06 出现了一趟**无人认领**的波：8 份 `PORT-CHANGES.md` 被重写、
#   三份 `ARTIFACT-SRC-FP.txt` 被刷新、`pf` 位被顶掉（`50da8513… → 3936c867…`），
#   而**没有任何车道承认发起过它**，日志也没留下。后果很实在：并行车道当时手里的
#   "当前件读数"**集体作废**，主控还要花时间考古"是谁在什么时候重建了什么"。
# ⇒ 波是**主控独占**动作。这里把它变成**结构约束**而不是口头约定：
#     · 必须给出责任人：`WAVE_OWNER=<名字>`（`build/close-wave.sh` 会自动带上）；
#     · 每一趟（无论授权与否走到这里）都往 `build/wave-audit.log` **追加一行可追溯记录**
#       （时间 / pid / ppid / tty / 命令行 / owner）——**认领不到人的重建，从此不可能悄悄发生**；
#     · 未设 `WAVE_OWNER` ⇒ **直接退出**，并打印两种正确用法（要跑就显式认领）。
#   ⚠️ 它只挡"没名字的波"，不挡技术操作；`close-wave.sh` 也已同步带上 `WAVE_OWNER`。
if [ -z "${WAVE_OWNER:-}" ]; then
    for a in "$@"; do case "$a" in --owner=*) WAVE_OWNER="${a#--owner=}" ;; esac; done
fi
AUDIT="$REPO/build/wave-audit.log"
TTYNAME=-; if tty -s 2>/dev/null; then TTYNAME="$(tty 2>/dev/null)"; fi
# 【为什么还记父进程命令行】2026-09-14 18:33:34 那趟波：审计行**写出了 owner=close-wave:links-dev**，
#   但**所有车道都以同一个 OS 用户运行** ⇒ "owner" 分不出是**谁**发的。于是补记**调用者命令行**：
#   `/proc/$PPID/cmdline` 就是发起这次调用的那个 shell 的完整命令行（车道的命令通常自带特征串，
#   例如 `run.sh tline`／`dotnet test …ManagedLayer…`），足以定位发起方。再往上取一层做兜底。
ppid_cmd() {
    local p="${1:-$PPID}" out=""
    out="$(tr '\0' ' ' <"/proc/$p/cmdline" 2>/dev/null)"
    printf '%s' "${out:-?}"
}
{
    printf '%s  owner=%s  pid=%s  ppid=%s  tty=%s  cwd=%s  cmd=%s\n' \
        "$(date -Is)" "${WAVE_OWNER:-<未认领>}" "$$" "${PPID:-?}" "$TTYNAME" \
        "$PWD" "$(tr '\0' ' ' </proc/$$/cmdline 2>/dev/null || echo "$0 $*")"
    printf '    ppid_cmd=%s\n' "$(ppid_cmd)"
    printf '    ppid2_cmd=%s\n' "$(ppid_cmd "$(ps -o ppid= -p ${PPID:-1} 2>/dev/null | tr -d ' ')")"
} >> "$AUDIT" 2>/dev/null
if [ -z "${WAVE_OWNER:-}" ]; then
    cat >&2 <<'EOF'
❌ 这趟集成波**没有责任人** ⇒ 拒绝运行（2026-09-14 起的结构约束）。

   为什么要挡：2026-09-14 18:15 出现过一趟无人认领的波（重写了 PORT-CHANGES.md、
   刷新了生成物指纹、顶掉了 pf 位），**并行车道的"当前件读数"因此集体作废**，
   而没有任何记录说明是谁、基于什么前提发起的。

   两种正确用法：
     bash build/close-wave.sh                 # 推荐：跑"波 + native + 桥 + 身份 + 全量回归"整条收官序列
     WAVE_OWNER=<你的名字> bash build/integration-wave.sh    # 只要这一趟波

   每一次调用都会往 build/wave-audit.log 追加一行（时间/pid/ppid/tty/cmd/owner）。
EOF
    exit 9
fi
printf '  ▶ 波责任人：%s（记录于 %s）\n' "$WAVE_OWNER" "$AUDIT"

# ---------------------------------------------------------------- 0. 输入冻结 + 指纹
# 【为什么需要这一段】本工程吃过两次"编辑竞态"的亏（跑了正在被编辑的 runner / 被测文件在跑动期间
#   被改），而波的输入是**各车道手写的文件**（shim、应用器、`src/WpfGfx.Linux/**`）。协议：
#     · `build/.wave-done` **存在** = 上一波已消化，各车道可以写；
#     · 波运行期间它**必须不存在**（本脚本开波时删掉，结束时无论成败重建）。
#   另外把"波期间输入有没有被改动"做成**内容指纹**（不是 mtime）：只对**手写输入**取指纹
#   （`build/shims/**`、各应用器 `.py`、`src/**` 的源码，排除 bin/obj）——`build/*.Linux/**`
#   的生成物**本来就会被本波重写**，把它们算进来会让这条检查永远为真、等于没有。
WAVE_DONE="$REPO/build/.wave-done"
rm -f "$WAVE_DONE"
trap 'touch "$WAVE_DONE"' EXIT
wave_fp() {
    {
        find src -type f \( -name '*.cs' -o -name '*.py' -o -name '*.c' -o -name '*.h' \) \
            ! -path '*/bin/*' ! -path '*/obj/*'
        find build/shims -type f 2>/dev/null
        find src/WpfGfx.Linux.Native/tools -maxdepth 1 -type f -name '*.py' 2>/dev/null
        # ⚠️ 2026-09-11 主控补：这两条**手写车道**原先进不了指纹 —— 实测代价：波 4（只改 provider 的
        #   CFF 墨迹盒）与前一波的"波前/波后指纹"**逐字相同** ⇒ 这层检查对它们**完全瞎**。
        #   凡是"手写、且会被本波构建/发布带走"的目录都该进指纹；生成物（build/*.Linux/**）仍**故意不列**。
        find build/DirectWrite.Linux -type f \( -name '*.cs' -o -name '*.c' -o -name '*.h' -o -name '*.csproj' -o -name '*.sh' \) \
            ! -path '*/bin/*' ! -path '*/obj/*' 2>/dev/null
        find build/MilBridge/src build/MilBridge/tools build/MilBridge/tests -type f \
            \( -name '*.cs' -o -name '*.csproj' -o -name '*.sh' -o -name '*.py' \) \
            ! -path '*/bin/*' ! -path '*/obj/*' 2>/dev/null
    } | sort | xargs sha256sum 2>/dev/null | sha256sum | cut -d' ' -f1
}
FP_BEFORE="$(wave_fp)"
echo "输入指纹（波前）：$FP_BEFORE"

# ---------------------------------------------------------------- 1. 重生成
# 注意：DirectWriteForwarder / System.Printing / CycleStub.* / DirectWrite.Linux.Provider 是手写工程，
#      不参与 port-lib 重生成（重生成会覆盖它们的手工内容）。
step "1/4 用当前 port-lib 重新生成（统一签名 + 资源管线 + 身份文件）"
for p in System.Xaml WindowsBase UIAutomationTypes UIAutomationProvider \
         System.Windows.Input.Manipulations PresentationCore ReachFramework PresentationFramework; do
    printf '  %-42s ' "$p"
    python3 build/port-lib.py "$p" 2>&1 | grep -E '^\[|错误' | head -1
done

# ---------------------------------------------------------------- 2. 补丁重放
# PC / PF 的生成式应用器（M7b/T2 交付）。
#
# ⚠️ 2026-09-10 主控修：这里原先**只重放 apartment + fontcache**，漏了 registry / olecontext /
#    xamlaccess。而 port-lib 重生成会按上游重建 csproj 与生成物接线 ⇒ 漏掉的应用器会被
#    **静默丢弃**（补丁文件还在，但不再被编译进去），正是本脚本当初要防的那类事故
#    （"只有部分工程被重新生成过"）。现在改为**逐个探测、全部重放**，新增应用器无需再改本文件。
step "2/4 重放各工程补丁（幂等）"
for p in WindowsBase PresentationCore ReachFramework PresentationFramework; do
    if [ -f "build/$p.Linux/reapply-patches.py" ]; then
        printf '  %-42s ' "$p"
        python3 "build/$p.Linux/reapply-patches.py" 2>&1 | tail -1
    fi
done
# 生成式应用器：**显式顺序** + **自动兜底**。
#   · 显式部分 = 历史约定顺序（port-lib → reapply-patches → apartment → fontcache → registry → olecontext → xamlaccess）；
#     `ls | sort` 会把 olecontext 排在 registry 前面，与约定不符（当前这几个应用器改的文件互不相交，
#     顺序其实无关，但**不要靠巧合**）。
#   · 兜底部分 = 凡匹配 patch-presentation*.py 却不在显式表里的，**照样执行并打印 ⚠ 提示**，
#     这样新增应用器不会像 2026-09-10 那次一样被静默漏掉。
#   · 成败一律看**退出码**（各应用器的约定就是"锚点/计数对不上 → 报错退出"），
#     不用关键词匹配输出 —— 否则应用器正常打印里出现"锚点/异常"之类字样会假红。
APPLIERS_EXPLICIT=(
    # ✅ 2026-09-19（`#38`）：`patch-swe-linux` **接通**（把官方 `System.Windows.Extensions` 包换成 Linux 原生替身）。
    #   `#36` 曾因 `CS0012` 回退，`#38` 查明**两条真根因**并都修掉：
    #     ① 应用器的 HintPath 写死 `bin/Release/`，而波把替身建在 **Debug** ⇒ 引用落空、RAR 回落到**官方包**
    #        ⇒ 编出来的 `System.Xaml.dll` 带**包的签名身份**（`PublicKeyToken=cc7b13ffcd2ddd51`）⇒ PF 报 CS0012。
    #        修法：HintPath 改 `bin/$(Configuration)/`（跟随消费方配置）。
    #     ② `System.Security.Permissions 9.0.0` **传递依赖** SWE ⇒ 把直接包引用**整条删掉**也没用，
    #        restore 仍把包拉回来（assets 里 SWE 命中 14 处）⇒ 必须留一个**排除 compile/runtime 资产**的占位包引用。
    #     修后：7 个工程 + 4 个样本全部 **0 error**，替身进应用输出，且 `samples/ThirdPartyMini` 的
    #     `GeneratedInternalTypeHelper` 用例正极性 PASS / 反极性（官方包）`PlatformNotSupportedException` 崩。
    patch-swe-linux
    patch-presentationcore-apartment
    patch-presentationcore-fontcache
    patch-presentationcore-registry
    patch-presentationcore-olecontext
    # 2026-09-11 主控补：T1 的复合字体解析短路（把上游 FamilyCollection.cs 换成生成物）。
    # 顺序上放在其它 PC 应用器之后：它只碰 FamilyCollection.cs 与 csproj 的两条目，
    # 与 apartment/fontcache/registry/olecontext/securityzone 各自改的文件不相交。
    # ⚠️ 即使不写进这张表，下面的「自动兜底」也会执行它并打 ⚠ —— 写进来是为了**顺序确定**、不留悬念。
    patch-presentationcore-compositefont
    # 2026-09-11 主控补：M7b 的**补丁 M**（`TextServicesLoader.TIPsWantToRun` 非 Windows 守卫）。
    # 这是**鼠标输入崩溃**的修法：真应用一收到指针输入 ⇒ `InputManager.ProcessInput` →
    # `TextServicesManager.PreProcessInput` → `TIPsWantToRun` 在 Unix 上 NRE → **SIGABRT / core dumped**。
    # 改动：`Registry.CurrentUser` → `?.`；`Registry.LocalMachine` 为 null ⇒ `return false`（上游 366→378 行）。
    # ⚠️ 不写进这张表也会被下面的「自动兜底」执行并打 ⚠ —— 写进来是为了**顺序确定**、不留悬念
    #    （它只碰 `TextServicesLoader.cs`，与其它 PC 应用器改的文件不相交）。
    patch-presentationcore-textservices
    # 2026-09-11 主控补：T2 的补丁 H（URL 安全区域短路）。原先是靠下面的「自动兜底」执行并打 ⚠；
    # 写进显式表是为了顺序确定、且不再每次刷一条 ⚠ 噪声。
    patch-presentationcore-securityzone
    # 2026-09-18 主控补（`#34` 波）：T2 的**补丁 Q**（`MimeTypeMapper` 的 UrlMon/注册表查询换成内置表）。
    # 与补丁 H 同族（上游要 marshal urlmon 的 COM 接口指针 ⇒ Linux 上封存阶段即抛 MarshalDirectiveException）。
    # 实测触发者：**第三方 app** HandyControl 示例工程 —— XAML 里 `Icon="...icon.ico"` 这种按 URI 引用图片的写法。
    # ⚠️ 不写进这张表也会被下面的「自动兜底」执行并打 ⚠ —— 写进来是为了**顺序确定**、不留悬念
    #    （它只碰 `Shared/MS/Internal/MimeTypeMapper.cs` 与 PC csproj 两行，与其它 PC 应用器不相交）。
    patch-presentationcore-mimetype
    # 2026-09-11 主控补：B2/D3 —— **把 `FullTextLine` 回退接到托管 `HbTextLineFactory`**。
    # 这是 **D3 硬阻塞**的修法：`SimpleTextLine.Create` 返回 null ⇒ 上游 `new FullTextLine`
    # ⇒ `TextFormatterContext.cs:113 LoCreateContext` ⇒ 符号不存在 ⇒ **abort(134)**。
    # 真应用里"文本稍多（实测阈值：同段落第 2 行）"就触发 ⇒ 影响面比鼠标崩溃更大。
    # 两处站点都接（`TextFormatterImp.cs:236-246` 与 `:309`），**接不了就原样回退 LS**（不假装成功）。
    # csproj 同时追加 `DefineConstants=TEXTLINE_SHIM_DIRECT`（PC 里从此走**直构分支**而非反射分支）。
    patch-presentationcore-textline-fallback
    patch-presentationframework-xamlaccess
    # 2026-09-16 · W17C 补：`hbtextline_shim_stale` 的**等号化**接线 ——
    #   构建时把 `build/shims/PresentationCore.HbTextLine.cs` 的内容 sha256 写成
    #   assembly 级 `AssemblyMetadata`（.targets 生成物 + csproj 3 行接线），
    #   读侧 `build/MilBridge/tests/ShimShaReader/`（PEReader，不加载程序集）。
    # ⚠️ 事故背景（本行就是它的修法）：这条接线原来**手改**生成物 csproj，
    #   被本脚本第 1 步 `port-lib.py PresentationCore` 整份重写后**静默**抹掉
    #   （csproj 26ce64b8 → e2558faa、`grep -c HbTextLineShimSha` 0；权威 pc 随之
    #   失去元数据、读侧变 NOINFO）。现在它由应用器产出 ⇒ 必须显式登记，
    #   否则"被抹掉"只表现为一行都不打（与 patch-shared-* 那几条同款事故）。
    patch-presentationcore-hbtextline-shimsha
    # 2026-09-16 · W17C 补：`patch-presentationcore-lineheight-trace`（T1c/D 的行高/行偏移
    #   只读插桩）此前**既不在本表、也不在 applier-audit-expected.txt 里** ⇒ 它只靠下面的
    #   glob 兜底被执行，于是**不在审计覆盖面内**（"被摘掉"不会红）。它是 W17C 之外的
    #   既有缺口，本次一并登记；登记本身不改它的任何行为（内容断言由审计 A 级提供）。
    patch-presentationcore-lineheight-trace
)
# 2026-09-11 主控补：M7b 的 D2（UIA 保留值短路）—— **不在** `patch-presentation*` 通配里 ⇒
# 自动兜底抓不到它，**必须显式登记**。（同理 `wire-uiautomation-resolver` 见下面 PRE_APPLIERS。）
# ⚠️ 它**必须排在「UIAUTOMATION 清单注入」之后**：port-lib 重生成 UIAutomationTypes 的 csproj
#    会把这个补丁块抹掉 ⇒ 顺序是「预应用器 → 定向 port-lib → 本表（含 D2）→ 构建」。
APPLIERS_EXPLICIT+=( patch-uiautomationtypes-reservedvalue )

# 2026-09-11 主控补：M7b 的**补丁 N**（`Invariant.FailFast` 在 Linux 上自身 NRE ⇒ **assert 原文被吃掉**）。
# 名字是 `patch-shared-*`，**不在** `patch-presentation*` 通配里 ⇒ 自动兜底抓不到，**必须显式登记**。
# 影响面：`MS.Internal.Invariant` 只编进 WindowsBase（`WindowsBase.Linux.csproj:52` 一带），
#   修法 = 失败路径上 `Registry.LocalMachine?.OpenSubKey(...)` + **主动打印 assert 原文**
#   （语义不变：仍 `FailFast`；**不是**把 assert 变 no-op）。
APPLIERS_EXPLICIT+=( patch-shared-invariant-failfast )

# 2026-09-13 主控补：M7b 的**补丁 P**（建窗失败只报 `Win32Exception 1400`，1400 是本工程自己映射的码
#   ⇒ **真原因被吞掉**，这正是"`XOpenDisplay` 偶发抖动"那条悬案的观测盲区）。
# 名字是 `patch-shared-*`，**不在** `patch-presentation*` 通配里 ⇒ 自动兜底抓不到，**必须显式登记**
#   （与补丁 N 同源；M7b 实测：只跑 `port-lib.py WindowsBase` 会**抹掉它的接线**，`--check` 变 rc=1）。
# 影响面：生成 `build/WindowsBase.Linux/HwndWrapper.Linux.cs` 并**在 WB csproj 里 Remove 上游 +
#   Include 生成物**（与补丁 N 改的是**同一个 csproj**，所以两者都必须排在 port-lib 之后、且都是追加式接线）。
# 它只在**失败路径**上加诊断（`CreateWindowEx` 返 0），成功路径零开销、不改语义。
APPLIERS_EXPLICIT+=( patch-shared-hwndwrapper-diag )

# 2026-09-13 主控补：T1c 的**输入追踪**（缺省关：`WPF_LINUX_INPUT_TRACE=1` 才打、每进程 ≤200 行、只打印）。
# 它回答的是 must-do 里"打字到不了 TextBox"那一格：native 侧已证明**产出了 WM_CHAR**（`[KEY_DIAG] … → WM_KEYDOWN + WM_CHAR`，
#   字符 'A'=0x41/'B'=0x42 都对），而 `[msg]`（打在 **dispatch 期**，`win32_msg.c:293`）**天生看不见 WM_CHAR** ——
#   因为 WPF 在 **thread-preprocess 期**就处理它（`ComponentDispatcher.RaiseThreadMessage` → `HwndSource.OnPreprocessMessage`
#   的 `case WM_CHAR`，`HwndSource.cs:1852-1871`），标了 handled 就不进 `DispatchMessage`（Windows 上读数同样是 0）。
#   头号嫌疑 = `HwndSource._eatCharMessages` 长期为 true（每次 WM_KEYDOWN 置 true，只在该 KEYDOWN 未被 handled 时当场复位，
#   否则靠 `Dispatcher.BeginInvoke(Normal, RestoreCharMessages)` 延后清）⇒ **所有 WM_CHAR 被静默吃掉**。
# 生成 `build/PresentationCore.Linux/{HwndSource,HwndKeyboardInputProvider}.Linux.cs` 并接线（Remove 上游 + Include 生成物）。
# 名字本就落在下面的 `patch-presentation*` 通配里；写进显式表是为了**顺序确定、不留 ⚠ 噪声**。
APPLIERS_EXPLICIT+=( patch-presentationcore-inputtrace )
# 波46（D-G54）：HwndTarget 设根链只读插桩（生成 build/PresentationCore.Linux/HwndTarget.Linux.cs）。
#   同趟登记：审计期望清单 applier-audit-expected.txt 也要有同名一行，否则被摘掉零红。
APPLIERS_EXPLICIT+=( patch-presentationcore-hwndtarget-trace )

# 2026-09-13 主控补：T1c 的**托管侧出队读数**（`Dispatcher.TranslateAndDispatchMessage` 的 msg/hwnd/handled）。
# 名字是 `patch-windowsbase-*`，**不在** `patch-presentation*` 通配里 ⇒ 自动兜底抓不到，**必须显式登记**
#   （与补丁 N/P 同源：`port-lib.py WindowsBase` 会整份重写 csproj ⇒ 接线被抹掉**且不报编译错**，
#    只表现为"那一行都不打" ⇒ 最容易把"空输出"读成"格①：消息根本不在托管侧"）。
# 它回答的是输入链四格里的"**这一条消息到底有没有从 GetMessage 交给托管**"：
#   与原生侧的 `[MSGFLOW] push/pop` 配对 ⇒ 只有"原生 push 有 + 托管出队没有"这一对能机械指认"取不出来"。
# 缺省关（`WPF_LINUX_INPUT_TRACE` 或 `WPF_LINUX_MSGFLOW_TRACE`，与原生侧同名同义）、只打印、输入消息单独 150 行预算。
APPLIERS_EXPLICIT+=( patch-windowsbase-msgflow )

# 2026-09-13 主控补：T1c 的**第 2 批输入链探针**（P1…P6）—— 失败点已被推到"托管输入链最后一步"：
#   实测 `ProcessTextInputAction ⇒ handled=True` 而 TextBox 文本不变（`changes=0`），且 `_eatCharMessages` 全程 False
#   ⇒ 要问的是"`TextInput` 有没有被 raise、raise 给谁、谁处理了"。这两条应用器分别插在：
#     · `patch-presentationcore-inputsite-trace`：`InputProviderSite.ReportInput`（P1）+（P2/P5 在同名应用的扩展里）
#     · `patch-presentationframework-texteditor-trace`：PF 的 `TextEditorTyping.OnTextInput`（P6a–P6d）
#   两者都落在 `patch-presentation*` 通配里（自动兜底也会跑），写进显式表只为**顺序确定、不留 ⚠ 噪声**。
#   ⚠️ 它们各自往 csproj 注入 2 行 ⇒ `port-lib.py <工程>` 整份重写会**静默抹掉接线**（只表现为"一行都不打"）。
APPLIERS_EXPLICIT+=( patch-presentationcore-inputsite-trace )
APPLIERS_EXPLICIT+=( patch-presentationframework-texteditor-trace )

# 2026-09-13 主控补：T1c 的**第 4 批**（`TextBox.Text` DP 通知链 Q5…Q9）—— 命题改写后的那一格：
#   实测"键入 → 容器 → 渲染 全通，而 `Text` DP/`TextChanged` 陈旧"（样例里屏幕上是 `AB`，`_tb.Text` 仍 `'seed-文本'`）
#   ⇒ 链 = `TextBoxBase.cs:1435 _textContainer.Changed += OnTextContainerChanged` → `:1348` → `TextBox.cs:1194`
#     → `:1206 if(!_isInsideTextContentChange)` → `:1214 new DeferredTextReference(...)` → **`:1216 SetCurrentDeferredValue(TextProperty, dtr)`**
#     → 读 `.Text` 时 `DeferredTextReference.cs:41 GetValue → TextRangeBase.GetTextInternal(...)`。
#   探针**不读任何 DP**（读 `Text` 会自己触发 deferred 解析 = 观测者效应），且**入口探针全在各自早退门之前**。
# 生成 `build/PresentationFramework.Linux/{TextContainer,TextBoxBase,TextBox,DeferredTextReference}.Linux.cs` + csproj 8 行。
APPLIERS_EXPLICIT+=( patch-presentationframework-textbox-textdp-trace )

# 2026-09-13 主控补：T1c 的**第 5 批**（WindowsBase 的 deferred DP 读路径 W1…W4）。
# 【为什么在 WB】第 4 批实测：PF 侧全链绿（`Changed` 已 raise、`TextChanged` 已 raise、`:1216 SetCurrentDeferredValue` 调了两次），
#   而 `DeferredTextReference.GetValue`（PF 哨兵 Q8）**一次都没被调**，样例 18 次读 `_tb.Text` 全拿旧值 ⇒ 断在**读路径**：
#   `DependencyObject.cs:156-171 GetValue ⇒ RequestFlags.FullyResolved` → `:295 GetEffectiveValue`
#   → **`:303 if ((requests & (DeferredReferences|RawEntry)) != 0 || !effectiveEntry.IsDeferredReference) return effectiveEntry;`**（提前返回 ⇒ 不解析）
#   → `:308 !HasModifiers` → `:313 !HasExpressionMarker` → **`:321-333 reference.GetValue(...)` = 真正的解析点（一次都没到）**。
# 名字是 `patch-windowsbase-*`，**不在** `patch-presentation*` 通配里 ⇒ **必须显式登记**（同 msgflow：`port-lib.py WindowsBase`
#   会整份重写 csproj、接线被抹掉**且不报编译错**，只表现为"一行都不打"）。
APPLIERS_EXPLICIT+=( patch-windowsbase-dpvalue-trace )

# 2026-09-13 主控补：T1c 的**第 6 批**（W5 写入口 ×8 带调用栈 + W4a 对象身份 + W6a/W6b 有效值槽 + W7 `GetFlattenedEntry` 三个 return）。
# 【为什么还要这一批】第 5 批实测：写侧出口 `IsDeferredReference=True`、读侧有效值 `False` 且是旧串 ⇒ **中间有人把槽换回去了**。
#   W5 在**所有写 `Text` 的入口**打 `value` 类型 + 目标 hash + **调用栈前 4 帧** ⇒ 若 deferred 写之后紧跟一次 `value=string` 的写，栈直接指人。
# ⚠️ **B 依赖 A**（tracer 类定义在 `DependencyObject.Linux.cs`，同程序集/同 namespace）⇒ **必须同波应用**；
#    B 的 `--check` 会显式核对 A 的接线标记，缺了直接报错（不会悄悄 CS1033/CS0103）。
# ⚠️ 两个名字都不在 `patch-presentation*` 通配里 ⇒ 都要显式登记（`port-lib.py WindowsBase` 会整份重写 csproj、静默抹掉接线）。
APPLIERS_EXPLICIT+=( patch-windowsbase-entry-flatten-trace )

# 2026-09-20（W56A，`D-G65` 产品修法）：`DispatcherSynchronizationContext.Wait` 的两分支合一。
# 【为什么】上游在"禁用处理"计数非零时改调 Win32 `WaitForMultipleObjectsEx`，而本工程那条是
#   **失败桩**（`win32_misc.c:385`）且**在原理上不可能修好**（传进去的是 .NET 等待子系统的内部
#   对象 id，不是 Win32 HANDLE）⇒ 只要 UI 线程在锁上被争用就抛 `Win32Exception (50)` ⇒ **进程死**
#   （实测栈：`ResourceDictionary.GetValue:485` → `Monitor.Enter_Slowpath` → 本函数；启动期概率性命中）。
#   修法 = 两分支都走托管 `WaitHelper`（Linux 上实测真等待：300 ms 超时返回 258、有信号返回 0，
#   且不碰任何 Win32 消息队列 ⇒ 上游"防重入"的目的照样满足）。实测读数见 `build/MilBridge/W56A-report.md`。
# 【为什么必须显式登记】名字是 `patch-windowsbase-*`，**不在** `patch-presentation*` 通配里 ⇒
#   下面的自动兜底抓不到；而 `port-lib.py WindowsBase` 会整份重写 csproj、把接线**静默**抹掉，
#   表现只是"`Win32Exception (50)` 又回来了"（不改任何 rc、不报编译错）。
APPLIERS_EXPLICIT+=( patch-windowsbase-focus-wait )

# 2026-09-13 主控补：T1c 的**第 9 批**（PF 侧"渲染实际推的镜像变换 vs 报告口径"探针 M1…M6）。
# 【为什么需要】纯 RTL 的墨迹 `[13,42]` **落在它自己的视觉框 `[21.0,86.3]` 之外**（判据1 红、噪声底 0），
#   而 shim 侧已排除（`pw == W` 精确 ⇒ 反演矩阵是"区间自映射"、位置中性）。T1d 用离线装置拟合出**渲染等效变换 `R(y)=42−y`
#   （镜在元素左边缘 21）**，与 `TransformToAncestor` 报的那次（`GetFlowDirectionTransform` = `Matrix(−1,0,0,1,RenderSize.Width,0)`）**不是同一个**。
#   本批探针把"M1' 实推矩阵的 OffsetX / M2 组装点(offset, oldRenderSize, mirror) / M3 推给视觉树 / M4 裁剪镜 / M6 TextBlock.OnRender"并排打出来。
# 名字落在 `patch-presentation*` 通配里（自动兜底也会跑），写进显式表只为**顺序确定、不留 ⚠ 噪声**。
APPLIERS_EXPLICIT+=( patch-presentationframework-mirror-trace )

# ── 预应用器：改的是 **port-lib 的输入**，所以必须「应用器 → 重新 port-lib → 其余应用器」──
# 【为什么需要这一段】`wire-uiautomation-resolver` 按工程既有机制写 `build/shims/*.shims.txt`，
#   而"清单 → csproj Include"这一步是 **port-lib** 干的（`port-lib.py:568-586`）。
#   常规顺序是「step1 port-lib → step2 应用器」，但这条应用器改的正是 step1 的**输入**
#   ⇒ 若只在 step2 跑它，清单写了也**不会进 csproj**，而且**静默**（构建照样成功、resolver 不在）。
#   ⇒ 实测顺序（M7b 给）：wire-uiautomation-resolver → port-lib.py UIAutomationTypes → D2 应用器 → 构建。
#   ⚠️ 定向重跑 port-lib **只重生下列工程的 csproj**，不会动其它工程已注入的接线。
PRE_APPLIERS=(
    wire-uiautomation-resolver
)
PRE_PORTLIB_PROJECTS=(
    UIAutomationTypes
    UIAutomationProvider
)
APPLIERS_ALL=()
for name in "${APPLIERS_EXPLICIT[@]}"; do
    [ -f "src/WpfGfx.Linux.Native/tools/$name.py" ] && APPLIERS_ALL+=("$name")
done
for f in $(ls src/WpfGfx.Linux.Native/tools/patch-presentation*.py 2>/dev/null | sort); do
    name="$(basename "$f" .py)"
    printf '%s\n' "${APPLIERS_ALL[@]}" | grep -qx "$name" || {
        printf '  %-42s ⚠ 不在显式顺序表里，追加执行\n' "$name"
        APPLIERS_ALL+=("$name")
    }
done

# ── 预应用器阶段（含空操作护栏，与主循环同口径）──────────────────────────────
for name in "${PRE_APPLIERS[@]}"; do
    [ -f "src/WpfGfx.Linux.Native/tools/$name.py" ] || { printf '  %-42s ⚠ 预应用器不存在，跳过\n' "$name"; continue; }
    printf '  %-42s ' "$name (预)"
    out=$(python3 "src/WpfGfx.Linux.Native/tools/$name.py" 2>&1); rc=$?
    if [ "$rc" -eq 0 ] && grep -qE '未指定动作|无动作可做|nothing to do' <<<"$out"; then
        printf '❌ 空操作（rc=0 但没做任何事）\n'; printf '%s\n' "$out" | tail -3 | sed 's/^/       /'; fail=$((fail + 1))
    elif [ "$rc" -ne 0 ]; then
        printf '❌ rc=%d\n' "$rc"; printf '%s\n' "$out" | tail -3 | sed 's/^/       /'; fail=$((fail + 1))
    else
        printf '✅ %s\n' "$(printf '%s' "$out" | tr '\n' ' ' | cut -c1-70)"
    fi
done
# 定向重跑 port-lib：把刚写的 shims.txt 注入这两个工程的 csproj
for p in "${PRE_PORTLIB_PROJECTS[@]}"; do
    printf '  %-42s ' "port-lib $p (注入清单)"
    out=$(python3 build/port-lib.py "$p" 2>&1); rc=$?
    if [ "$rc" -ne 0 ]; then printf '❌ rc=%d\n' "$rc"; printf '%s\n' "$out" | tail -3 | sed 's/^/       /'; fail=$((fail + 1))
    else printf '✅\n'; fi
done

for name in "${APPLIERS_ALL[@]}"; do
    # 预应用器已在上面单独跑过（且跑在定向 port-lib **之前**）—— 这里跳过，避免顺序倒置后重跑。
    printf '%s\n' "${PRE_APPLIERS[@]}" | grep -qx "$name" && continue
    printf '  %-42s ' "$name"
    out=$(python3 "src/WpfGfx.Linux.Native/tools/$name.py" 2>&1); rc=$?
    # ── 2026-09-11 主控补 · 空操作护栏（**实测事故**）────────────────────────────
    # 【事故】`patch-presentationcore-textservices`（补丁 M，鼠标输入崩溃的修法）**无参运行
    #   只打印"未指定动作：加 --check / --out PATH / --apply"然后 `exit 0`** —— 于是本循环
    #   打印了 `✅ 补丁 M`，而**它一个字节都没改**：生成物不存在、`WindowsBase.Linux.csproj:281`
    #   仍在编译上游原文件、WindowsBase.dll 里根本没有那条修法。补丁 M 就这样"绿"了两波，
    #   直到主控去核 csproj 接线才发现。
    # 【为什么退出码判断抓不到】本脚本的纪律是"成败一律看退出码"，而这个应用器**契约就违背了
    #   家族约定**（其它 7 个应用器无参运行 = 生成文件；只有它无参 = 空操作且成功返回）。
    # 【修法】除退出码外，**再加一道显式的空操作标记检查**。这是对"不靠关键词匹配"那条原则的
    #   **有意例外**：标记串极窄（只认下面三个），不会因为正常输出里出现"锚点/异常"之类字样而假红。
    #   ⚠️ 真正的修法是让应用器回归家族约定（无参 = 应用），护栏只是**防它再悄悄回来**。
    if [ "$rc" -eq 0 ] && grep -qE '未指定动作|无动作可做|nothing to do' <<<"$out"; then
        printf '❌ 空操作（rc=0 但没做任何事）\n'
        printf '%s\n' "$out" | tail -3 | sed 's/^/       /'
        printf '       ⇒ 该应用器无参运行不生效（违背家族约定：无参应=应用）。\n' >&2
        fail=$((fail + 1)); continue
    fi
    if [ "$rc" -ne 0 ]; then
        printf '❌ rc=%d\n' "$rc"; printf '%s\n' "$out" | tail -3 | sed 's/^/       /'; fail=$((fail + 1))
    else
        printf '✅ %s\n' "$(printf '%s' "$out" | tr '\n' ' ' | cut -c1-70)"
    fi
done

# ------------------------------------------------- 2.5 应用器审计（债务 #13，T1c）
# 【为什么插在重建之前】应用器"注册了但没生效"是**静默**的一族：
#   `port-lib.py <proj>` 会**静默抹掉 csproj 接线**（不报错、只是没有输出行），
#   而 `patch-*.py` 命中 0 也可能 exit 0 ⇒ 于是"重建出来的 DLL 是旧语义"却一切皆绿。
#   这正是 `patch-shared-hwndwrapper-diag` 差点丢掉的那类事故。
# 【口径（T1c 实现，只读）】A 级 = **变换等价**：把应用器**自己声明的**编辑表按序作用到
#   **上游文本**（内存里），要求结果**出现在落盘生成物里** —— 期望值从声明算出来，**不看树**；
#   B 级 = 生成物存在 + banner 提到本脚本 + csproj 有 Include；C 级 = 只查 MARKER_BEGIN
#   （**明说**：C 级抓不了"内容没生效"）。另有一份**独立于本脚本的登记清单**
#   （`build/MilBridge/tools/applier-audit-expected.txt`）：把某条从 `APPLIERS_EXPLICIT`
#   摘掉时，**"少一条"也判红**（否则"被摘掉"在波里不可见）。
# 【实测】20 应用器 / 74 项检查 / 0 miss / rc=0（主控独立实跑复现）；三种牙实测能红：
#   声明改错 / 未登记 / 生成物 == 未打补丁的上游。
step "2.5/5 应用器审计（注册了但没生效 ⇒ 红；债务 #13）"
if [ -f build/MilBridge/tools/applier-audit.py ]; then
    python3 build/MilBridge/tools/applier-audit.py || {
        echo "  ❌ 应用器审计 RED ⇒ 中止：先修接线再重建（否则重建出来的是旧语义、而且后面每一道闸门都会拿它当'当前件'）"
        exit 1
    }
else
    echo "  ⚠️ 缺 build/MilBridge/tools/applier-audit.py ⇒ **无信息**（不等于通过；这条位缺失本身就是事实）"
fi

# ---------------------------------------------------------------- 3. 依赖序重建
step "3/4 按依赖序重建（每个工程一次，-m:1）"
ORDER=(
    # ⚠️ 2026-09-16 主控补（车道 V18A 发现，属"D-R7 同族：生效了但没进波"）：
    #   `src/WpfGfx.Linux/**` 原本**不在本表里** ⇒ 改了它（例如 `Windowing/X11Native.cs`）
    #   会出现"**桥里是修后的、而 Debug 可见位与各 app-local 副本还是修前的**"——
    #   后者正是应用门禁实际加载的那一份 ⇒ 读数会**漏掉该改动**。
    #   它是**叶子工程**（csproj 无任何 ProjectReference，只用 SkiaSharp）⇒ 放在最前，
    #   让后面按 HintPath 取它的工程与桥的 AOT 发布都拿到新件。
    src/WpfGfx.Linux/WpfGfx.Linux.csproj
    # `#36` 波：`System.Windows.Extensions` 的 Linux 原生替身 —— **必须排在 XAML/WB/PC/PF 之前**，
    #   因为那四个工程会按 HintPath 取它的 `bin/Release/System.Windows.Extensions.dll`。
    System.Windows.Extensions.Linux
    System.Xaml.Linux
    WindowsBase.Linux
    # ⚠️ 2026-09-10 主控补：Provider 是**手写嵌套工程**，既不参与 port-lib 重生成、原先也不在重建表里，
    #    但 PC 通过补丁 F 的 HintPath 直接引用它（PresentationCore.Linux.csproj 的
    #    `build/DirectWrite.Linux/Provider/bin/Debug/DirectWrite.Linux.Provider.dll`）。
    #    后果：改了 Provider 源码，本波会**拿旧的 DLL 重建 PC** 而毫无提示（实测它停在 17:40 的旧件上）。
    #    它只依赖 SkiaSharp、不依赖任何自产程序集，所以放在 WB 之后、DWF 之前即可。
    build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj
    DirectWriteForwarder.Linux
    UIAutomationTypes.Linux
    System.Windows.Input.Manipulations.Linux
    UIAutomationProvider.Linux
    PresentationCore.Linux
    System.Printing.Linux
    CycleStub.PresentationFramework.Linux
    CycleStub.ReachFramework.Linux
    CycleStub.PresentationUI.Linux
    ReachFramework.Linux
    PresentationFramework.Linux
    ReachFramework.Linux
)
for p in "${ORDER[@]}"; do
    # ORDER 项可以是 build/<Name> 目录，也可以直接是 csproj 的相对路径（Provider 这种嵌套手写工程）。
    if [[ "$p" == *.csproj ]]; then proj="$p"; else proj=$(ls build/$p/*.csproj 2>/dev/null | head -1); fi
    label="$(basename "${proj%.csproj}")"; [ -z "$label" ] && label="$p"
    if [ -z "$proj" ]; then printf '  %-42s %s\n' "$label" '⚠ 找不到工程（计为失败）'; fail=$((fail + 1)); continue; fi
    # ★ `#39` 阶段 2/3：波**按唯一声明**构建（`build/SelfBuiltConfig.props`），
    #   不再隐式吃 `dotnet build` 的默认 Debug ⇒ 改声明那一行 = 改全链路配置。
    out=$(dotnet build "$proj" -c "$SELFBUILT_CONFIG" -m:1 --nologo -v q 2>&1)
    errs=$(printf '%s' "$out" | grep -oE '[0-9]+ 个错误' | tail -1)
    warns=$(printf '%s' "$out" | grep -oE '[0-9]+ 个警告' | tail -1)
    # ⚠️ 2026-09-10 主控补：原先只看 `error `，**警告被完全忽略** —— 而本工程的标准是"0 错 0 警"。
    #    实测代价：T2 引入的 `CS0162`（`const false` 导致的不可达代码，WB/PC 各一条）**悄悄进了树**，
    #    是本波之外偶然重建 WB 才发现的。现在警告计入失败并逐条列出。
    if grep -qE "error |warning " <<<"$out"; then
        printf '  %-42s ❌ %s %s\n' "$label" "${errs:-0 个错误}" "${warns:-0 个警告}"
        printf '%s' "$out" | grep -E "error |warning " | head -4 | sed 's/^/       /'
        fail=$((fail + 1))
    else
        printf '  %-42s ✅ %s %s\n' "$label" "${errs:-0 个错误}" "${warns:-0 个警告}"
    fi
done

# ---------------------------------------------------------------- 3.5 app-local 副本刷新（T2，2026-09-14 接线）
# 【为什么必须有这一步】`HintPath + Private=true` 的语义是"**消费者构建时拷一次**"⇒
#   权威件变了之后，**已存在的 app-local 副本不会自己更新**，而 `DllImport`/程序集加载
#   **先命中 app 目录那份** ⇒ 探针/样例跑的是**旧一代二进制**却一切皆绿（债务 #20）。
#   实测：Provider 副本尺寸 68,608 → 93,184 B 两代并存；`ReachFramework.dll` 副本整齐早 62 秒。
# 【与 3.6 的分工】本步修"产物身份"（防权威件变了副本没跟上）；3.6 记"源身份"（防源变了没重编）。
# 【口径（T2 §24）】**不重复判据**：只执行只读校验器 `check-applocal-sync.sh` 的结论 ——
#   `STALE`（sha≠权威 **且 mtime 早于**权威）与 `DIVERGENT` 落单者才刷；`NEWER-DIFF` 只告警**不盲拷**
#   （mtime 只用于**分类**，不用于放行）；`obj/` 与 `/CycleStub.` 桩件按 `SKIP` 跳过；
#   库输出目录（无 `runtimeconfig.json`）不算宿主、副本不算加载源。
# 【实测牙】A–H 全 PASS（权威换 sha ⇒ 7 份 STALE/exit 1；还原 ⇒ PASS；桩件不判不一致；
#   obj 只 SKIP、同内容 stale bin 照样红；库目录不判、放进宿主就判红）。
#
# ⚠️⚠️【`#49` B2 / `D-G60`：**本步与 3.6 的先后在 `#48` 及以前是**反的**，本趟对调】⚠️⚠️
#   现场（车道 W50A `build/MilBridge/W50A-report.md:42`，实测**推翻**主控原预期）：
#     原来 **3.5 = 写身份记录**（`artifact-src-fp.py --write`）**排在** **3.6 = app-local 副本刷新**
#     之前，而刷新会覆盖身份记录覆盖面里的**被引件** ⇒ **身份记录一出生就是陈旧的**
#     （`artifact-src-fp.py --check` 当场 `rc=2 stale`，且**不随整波重建收敛** —— 因为下一波还是同样的次序）。
#   ⇒ 修法：**先刷新产物副本、再写身份记录**（本段与 3.6 段整体对调）。
#   ⇒ 编号口径（**必须记住，否则读旧报告会读反**）：**`#48` 及以前** `3.5=身份记录`／`3.6=副本刷新`；
#     **`#49` 起** `3.5=副本刷新`／`3.6=身份记录`。旧报告里的引文（`W48A-report.md:156/:160`、
#     `W50A-report.md:205/:453/:454`）按**旧编号**读，本文件不再改动它们（历史留档不动）。
step "3.5/5 app-local 副本刷新（权威件 → 落后的加载源副本；#49 起本步在身份记录之前）"
SYNC_APPS="$REPO/build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh"
if [ -f "$SYNC_APPS" ]; then
    bash "$SYNC_APPS" --apply || { echo "  ❌ 副本刷新失败 ⇒ 计为失败（宁可红，也不让探针测旧件）"; fail=$((fail + 1)); }
else
    echo "  ⚠️ 缺 $SYNC_APPS ⇒ **无信息**（不等于通过）"; fail=$((fail + 1))
fi

# ---------------------------------------------------------------- 3.6 生成物身份指纹（T1c，2026-09-14 接线；#49 起排在本步）
# 【为什么在重建 + 副本刷新之后立刻写】这三个大件（PC/WindowsBase/PF）此前**只有产物 sha**：
#   产物变了才看得见，而"**源变了但没重建**"完全静默 —— 桥那边就出过这件事
#   （事故 D：T2b 22:37 改 `src/WpfGfx.Linux/Rendering/**`、而桥是 22:24 发的，
#   `ACCEPTANCE-BASELINE.md` #6 因此被冻成"源陈旧"）。桥的修法是身份指纹
#   （`build/bridge-src-fp.sh`）；这三个件用同一思路：`build/artifact-src-fp.py`。
#   ⚠️【`#49` B2 / `D-G60`】**必须排在 3.5 之后** —— 3.5 会覆盖本记录覆盖面里的被引件；
#     排在它前面 ⇒ 记录描述的是"刷新前"的树 ⇒ 一出生就 `stale`（见 3.5 段顶部的现场与编号口径）。
# 【口径】覆盖"决定产物的三方"：csproj 里 `Include` 的上游源（**减去被 `Remove` 的**）
#   + 生成物/垫片 + **按声明筛出**的该工程应用器**整脚本** sha + 上游 csproj/port-lib.py/
#   reapply-patches.py；排除 `bin/obj/.artifacts` 与指纹文件自己。
# 【边界（T1c 写明，别当它更强）】它是**内容**指纹 ⇒ **只加注释也会变**；它**不证明能编过**、
#   也**不证明"产物就是这些源编出来的"**（桥有"重建后逐字节可复现"的实测支撑，这三个件**没有**）
#   ⇒ 报 stale 时先看 diff 类型，别一律当"没重建"。
# 【实测】四极性 `--selftest` PASS（改上游源⇒变 / 还原⇒逐位回绿 / 只在 obj/ 加⇒不变 / 只在 bin/ 加⇒不变）；
#   手工牙：给应用器加一行注释 ⇒ `stale` rc=2；挪走指纹文件 ⇒ `noinfo` rc=3（不经管道取真值）。
step "3.6/5 生成物身份指纹（PC/WindowsBase/PF 的源身份；债务 #20 同族；#49 起本步在副本刷新之后）"
if [ -f build/artifact-src-fp.py ]; then
    python3 build/artifact-src-fp.py --write || echo "  ⚠️ 指纹写失败 ⇒ 记为**无信息**（不要当绿）"
else
    echo "  ⚠️ 缺 build/artifact-src-fp.py ⇒ **无信息**（不等于通过）"
fi

# ---------------------------------------------------------------- 3.7 判据件自检（`#49` C6）
# 【为什么必须有这一步】`build/close-wave.sh:309` 的 `[4/6] 身份自检` **执行** app-local 校验器
#   并用它的 rc 决定印 `✅ APPSYNC=PASS` 还是告警；而 3.5 那一步（`sync-applocal-authority.sh --apply`）
#   也**以它的结论为唯一判据**。⇒ 这个校验器一旦"自己的前提坏了"，全波关于 app-local 的读数**都不可信**。
#   🔴 现场（车道 W52C 2026-09-20 实测）：`#39` 在 **09-19 11:11** 把权威配置切到 `Release`，而该校验器
#   最后一次改动是 **11:03** —— 于是它的自检 **`D/E/O/P` 四例当场变红，而没有任何人知道**（本文件 `:141-142`
#   自己写着"自检必须在静树上跑"）。实测：改前件 `--selftest` 首红 `SELFTEST_D rc=1`，其后 14 例**根本没跑到**。
#   ⇒ 判据：**"切权威配置/改判据件"必须同趟重跑自检**，且**红了要停**（`fail+1` 计红），不许当告警。
#   三态照旧：`SELFTEST=PASS`（rc=0）绿 ｜ `SELFTEST=NOINFO`（rc=3）**不许当绿** ⇒ 同样计红 ｜ 其余非 0 ⇒ 红。
#   ⚠️ 成本：一次 ≈ 1–3 min（18 例，各带沙箱树），零 `dotnet`、零构建、不改任何目录。
step "3.7/5 判据件自检（app-local 校验器 --selftest；#49 C6：切配置/改判据件必须同趟重跑）"
ST_CHECKER="$REPO/build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh"
ST_LOG="$REPO/build/.applocal-selftest.log"
if [ -f "$ST_CHECKER" ]; then
    bash "$ST_CHECKER" --selftest > "$ST_LOG" 2>&1
    st_rc=$?
    st_sum="$(grep -m1 -E '^SELFTEST=(PASS|FAIL|NOINFO)' "$ST_LOG" 2>/dev/null || true)"
    if [ "$st_rc" = 0 ]; then
        echo "  ✅ ${st_sum:-SELFTEST=PASS（未印汇总行，按 rc=0 判）}（逐例见 build/.applocal-selftest.log）"
    else
        echo "  ❌ 判据件自检未 PASS（rc=$st_rc；汇总行：${st_sum:-<未印>}）"
        echo "     ⇒ **本波关于 app-local 的读数不可信**（校验器自己的前提坏了）；首几条红例："
        grep -m3 -E 'SELFTEST[A-Z_0-9]*=FAIL' "$ST_LOG" 2>/dev/null | sed 's/^/       /'
        fail=$((fail + 1))
    fi
else
    echo "  ⚠️ 缺 $ST_CHECKER ⇒ **无信息**（不等于通过）"; fail=$((fail + 1))
fi

# ---------------------------------------------------------------- 4. 身份一致性自检
#
# ⚠️ 2026-09-10 主控修：这里原先写 `<ls "$d"/bin/Debug/*.dll | head -1>`，是**错的**——
#    自产工程的输出目录里除了自己的程序集还躺着依赖副本（PC 有 8 个 dll、PF 有 12 个），
#    `ls` 按字典序排 ⇒ WindowsBase 目录取到 `System.Xaml.dll`、PC/PF 目录取到
#    `DirectWriteForwarder.dll`。实测后果：**5 个程序集里 3 个（WB/PC/PF）从未被真正检查**，
#    而 `DirectWriteForwarder.dll` 被"检查"了 3 次 —— 一个只会说"已签名"的假保证。
#    这正是本脚本要防的那类事故（"验证工具本身给假绿"），所以改成**按项目名精确取件**，
#    并且**取不到就算失败**（不许静默跳过）。
step "4/4 身份自检（每个自产程序集：按项目名精确取件 + 是否带公钥）"
for d in System.Xaml.Linux WindowsBase.Linux PresentationCore.Linux \
         PresentationFramework.Linux DirectWriteForwarder.Linux; do
    want="${d%.Linux}.dll"
    dll="build/$d/bin/Debug/$want"
    if [ ! -f "$dll" ]; then
        printf '  %-52s ❌ 找不到（期望 %s）\n' "$d" "$want"
        fail=$((fail + 1)); continue
    fi
    printf '  %-52s %s\n' "$want" \
        "$(python3 - "$dll" <<'PY'
import sys
# 读 PE 的 CLI 头 → Assembly 表版本不方便纯 python，这里只看 #Blob 里是否出现 WCP 公钥前缀
data = open(sys.argv[1], 'rb').read()
key = bytes.fromhex('0024000004800000940000000602000000240000525341310004000001000100')
print('已签名(带公钥)' if key[:24] in data else '未签名')
PY
)"
done

# ---------------------------------------------------------------- 5. 输入稳定性自检
FP_AFTER="$(wave_fp)"
step "5/5 输入稳定性（波期间手写输入有没有被改动）"
printf '  波前指纹 %s\n  波后指纹 %s\n' "$FP_BEFORE" "$FP_AFTER"
if [ "$FP_BEFORE" = "$FP_AFTER" ]; then
    printf '  ✅ 一致 ⇒ 本轮构建结果与"波后树"对得上（没有编辑竞态）\n'
else
    {
        printf '  ⚠️ 波期间手写输入**被改动过** ⇒ 本波产物不保证与波后树一致。\n'
        printf '     谁在波里写了 build/shims/** 或应用器或 src/**？核对后必要时重跑本波。\n'
        printf '     （这正是"跑了正在被编辑的文件"那类事故的机器可见形式）\n'
    } >&2
fi

printf '\n=== 集成波结束：失败步骤 %d ===\n' "$fail"
exit $((fail == 0 ? 0 : 1))
