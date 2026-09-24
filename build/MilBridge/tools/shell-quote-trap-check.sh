#!/usr/bin/env bash
# shell-quote-trap-check.sh —— 「**双引号里的裸反引号**」的机器牙（**纯读、零 `dotnet`、零构建**）
#
# ═══════════════════════════════════════════════════════════════════════════════
# 【它防什么】同一个陷阱在本工程已**4 次现场**：
#   ① `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh:659`（早期，已修）；
#   ② 车道 W28F 的 `echo "…`D-G21`…"`（W29F 查出 —— ⚠️ **16/16 与 18/18 自测对它都是盲的**）；
#   ③ **主控**在 `verify-all.sh` 第 `[12]` 步的 `echo` 里把 `` `fp_inputs()` `` 写进双引号
#      （W30D 查出：每趟 stderr 吐"语法错误：未预期的文件结束符"、**横幅丢掉那几个字**，
#       而 `rc` 不受影响 ⇒ 光看 `rc` 永远发现不了）；
#   ④ 车道 W30C 的**新诊断行**（被它自己的 `noise=` 断言当场抓住）。
#   ⇒ **唯一抓住过它的是 `noise=` 断言**，不是任何通用检查。本件就是那颗通用牙。
#
# 【机制（为什么这个写法真的会坏）】bash 里 `"…`cmd`…"` 的 `` ` `` **就是命令替换**，
#   `cmd` 会被执行、那段字面文本**从输出里消失**；若 `cmd` 不存在 ⇒ stderr 多一行
#   `…: cmd: 未找到命令`。本波实测三个真现场（成对读数见 §报告）：
#     · `run-df1-criteria.sh:102` 行首 `` `#` `` ⇒ `OUT` 里少了"行首 `#` ⇒"、并打印 tee 报错；
#     · `seg-instrument.sh:164` `` `/proc/<pid>/maps` ``/`` `smaps` ``/`` `Rss:` `` ⇒ 三条 `未找到命令`；
#     · `run-wpfprobe.sh:948` `` `block_registry_check` `` ⇒ 门禁红字里少了那半句。
#   ⚠️ **`bash -n` 对这三处全部静默通过**（实测 `rc=0`、stderr 空）⇒ 语法检查抓不到它，
#      所以必须**按引号状态逐字符判**，不能靠"能不能编过"。
#
# 【判据（三态）】**0 = PASS**（0 条陷阱）｜**1 = FAIL**（≥1 条 ⇒ **逐条点名** `file:line:col`）｜
#   **2 = NOINFO**（算不出来 ⇒ **不是绿**：取不到文件 / 扫描定义失效 / 锚件不在扫描集 / 扫描器失明…）
#   ⚠️ `NOINFO` **一律 `rc≠0`**（纪律 21/27/28："没声明"不许当绿；`verify-all.sh` 对任何非 0 判 `❌`）。
#   ⚠️ 与 `fp-inputs-hygiene-check.sh`／`build-hygiene-import-check.sh` 的三态**刻意同形**（`0/1/2`）。
#
# ─────────────────────────────────────────────────────────────────────────────
# 【扫描定义（必须能被复核，所以逐字写在这里）】
#   件集 = `find "$ROOT" \( -name '*.sh' -o -name '*.py' \) -type f`
#          减去 `./upstream/*`（vendored 的 WPF 上游，实测只有 `upstream/wpf/build.sh` 一件）、
#          减去 `*/obj/*`、`*/.artifacts/*`、`*/__pycache__/*`（构建产物目录）。
#   ★ **`#60` W152A 改了这一条（`TASK-0713`）**：旧文是「减去 `*/obj/*`、`*/bin/*`、…」——
#     那一条把 `bin/` 与 `obj/` **并列静默排除**。实测（成对）：**同一颗真陷阱**放 `*/bin/*` ⇒
#     `PASS traps=0`（**静默出射程**＝**假绿方向**）、挪到 `build/MilBridge/tools/` ⇒ `FAIL traps=2`。
#     ⇒ 修法 = **`bin/` 纳入扫描**（真判，不再靠"没扫"蒙过去），并把射程**永远打印**：
#     每次跑印一行 `QUOTE_TRAP_SCOPE … bin=INCLUDED excluded=<类:件数 …>` ⇒ **"没扫什么"不许静默**。
#     `--selftest` 新增 `S30/S31/S32` 三例钉住这一条。
#     ⚠️ 今天实测：全树 `*/bin/*` 下的 `*.sh|*.py` = **0 件** ⇒ 本改**读数零位移**（`files=` 不变），
#        它治的是**将来**有件落进 `bin/` 时"牙看不见"。
#   ⚠️ 本工程**没有 `git`**（`command -v git` = 空、仓根无 `.git`）⇒ 不存在"`git ls-files` 才叫 tracked"
#      这种口径。上面这条 `find` 就是**本仓"tracked"的可操作定义**（与 `#29` W29B 给 `fp_inputs()`
#      加排除时用的那条同形）。**两种件集口径的差别只有 `upstream/` 与产物目录**，逐条写在报告里。
#   ★ **扫描集不许悄悄缩水**（`D-R4` 那族"射程缩到零而它还是绿的"）：本件有**两条锚断言** ——
#      ① 仓根 `verify-all.sh` 必须**在**件集里；
#      ② `build/MilBridge/tools/*.sh` 的件数必须 ≥ `QT_MIN_TOOLS`（默认 15；现场 20）。
#      任一不成立 ⇒ `NOINFO reason=scan-definition-broken`（**不是绿**）。
#
# 【哪些位置判红、哪些刻意不判（这是本件的判定核心）】
#   判 **红** 的（`kind=DQ-BACKTICK`）：`` ` `` 落在**双引号字符串里**、且
#     · 不在单引号里（`'…`x`…'` ⇒ 字面量，**绝不判**）；
#     · 不被反斜杠转义（`"\`x\`"` ⇒ 字面量，**绝不判**）；
#     · 不在 `#` 注释里（注释只到行尾，**绝不判**）；
#     · 不落在**加引号的 heredoc 体**里（`cat <<'TXT'` 的体在运行时**不展开**，**绝不判**）。
#   ★ `#31` W31F **改了这一条**（旧件写"不落在双引号内嵌的 `$( … )` 里 ⇒ 不判"）：
#     判据的**真正**分界不是"在不在 `$( )` 里"，而是"这个反引号**在不在双引号字符串里**"。
#     `"$( … )"` 里是**命令上下文** ⇒ 那里的反引号合法（仍不判）；但在 `$( )` **内部新开的**
#     双引号里（`out="$(printf '%s' "abc`X`def")"`）⇒ **它就是双引号里的裸反引号** ⇒ **判红**。
#     实测：旧件对这一档 **0 命中**（假阴性），而真跑 stdout 少了 `abc…def` 那几个字、stderr
#     多一行 `…: X: 未找到命令`（成对读数见报告 §4）；新件命中 2 条（`--selftest` S24 钉住）。
#   ⚠️ **判红的严格性是有意的**：`"…`cmd`…"` 这种**旧式**写法在本仓里 100% 是笔误（本仓一律用 `$( )`），
#      且它**每一次都真的做了命令替换**（实测三处全部 `未找到命令`）。若将来真有人**故意**要用旧式写法，
#      他必须写**显式豁免标记** `shell-quote-trap:allow`（同一行，或**紧邻上一行的注释行**）——
#      写标记 = 签字，且本件会把它印成 `SHELL_QUOTE_ALLOW=` 行 ⇒ **豁免永远是可见的，不会静默**。
#   ★ `#31` W31F **加强**：`kind=HEREDOC-BACKTICK` 由"只报诊断"升为**判红** —— **未加引号**的
#     heredoc 体（`cat <<EOF … `date` … EOF`）在运行时**真的**做命令替换。旧件把它排除在 `rc` 之外
#     ⇒ 那一档 `rc` 恒 0 = **永远响不了的真洞**。实测真跑：体里 `` `date` `` 直接被替换成日期、
#     `` `X` `` 打出 `X: 未找到命令`（`--selftest` S10 由「期望 `rc=0`+`DIAG`」**升为**「期望 `rc=1`+点名」）。
#   ★ `D-G120`（`#65` W152A）**新增第三类**：`kind=CONTINUATION-COMMENT` —— **行尾反斜杠续行里
#     插进来的 `#` 注释行**。现场（`#64` 落地 `BASELINE-RATE-GATE` 时真咬到，主控已复现）：
#       `printf '%s\n' A \` ＋ `    # 注释插在续行中间` ＋ `    B \` ＋ `    C`
#     bash **先把 `\`+换行拼成一个逻辑行、再认注释** ⇒ 拼出来的那一行里的 `#` 起注释 ⇒
#     **吃掉参数表下半截**；紧随的物理行变成**新命令被执行**（`B C` ⇒ `B: 未找到命令`），
#     它的 stdout 还会落进 `{ … } | sort | xargs sha256sum` ⇒ `sha256sum` 去 hash 这些"文件名"、
#     **真名被吞** ⇒ **件数读错（160 vs 161）＋ 指纹凭空多出一个中间值**。
#     ⚠️ **`rc` 指示不了它**：裸 `bash -c` 那一趟 `rc=127`（`B` 是最后一条命令），
#        而真现场（`{ … } | … | sha256sum | cut`）`rc=0`（取自最后一段 `cut`）——
#        **两种读数都对，正因为如此这一族只能按文本形态判**（`--selftest` S35 钉住）。
#     ★ 判据的**真正**分界不是"文本相邻"，而是"**这个续行真的成立**"：三条真跑读数（P3/P4/P5）：
#       · **注释行**行尾 `\` ⇒ bash **不**在注释里续行 ⇒ 下一行照常执行 ⇒ **不算续行**；
#       · 单引号串里的行尾 `\` ⇒ 字面量 ⇒ **不算续行**；
#       · `\\`（偶数个行尾反斜杠）⇒ **不算续行**。
#       ⇒ 实现上 = "那个 `\` 是在 **`N` 态（命令上下文）**里被吃到的"；三条阴性探针分别钉住。
#     ★ 刻意**不判** `.py`（Python 注释在物理行尾就结束，与"注释里不续行"同因）。
#   刻意 **不判红**（只做诊断，绝不进 `rc`）：
#     · `kind=DQ-BRACE-BACKTICK`：双引号内 `${ … }` 里的反引号（`"${x:-`cmd`}"`）—— 只报。
#     · `kind=PY-BACKTICK-FILE`：`.py` 里含反引号的行数（现场 **1481 行 / 60 文件**）——
#       **Python 不做命令替换**，反引号在字符串/文档串里是**普通字符** ⇒ 判红就是 1481 条假红。只报计数。
#   判红的 `.py` 窄族（`kind=PY-SHELLSTRING`）：**同一行**既有反引号、又有 shell 调用标记
#     （`shell=True`／`os.system(`／`os.popen(`／`subprocess.`）⇒ 那个字符串**会**被交给 shell。
#     现场 **0 条**（机器证见报告）；漏判风险 = 标记写成别的形态 ⇒ 那时它是**诊断面**而不是红。
#
# 【扫描器失明的机器证（★ 本件最重要的一条设计）】
#   "一个抓不住东西的检查器永远绿" 是本工程反复栽的坑（`--selftest` 用例失去前提、16/16 对真陷阱全盲）。
#   ⇒ 本件**每一趟**都跑一个**内置金丝雀**：把一段**已知形状**的夹具（20 行；**两类共 5 行**必命中、
#      含反引号但必不命中的 **5 行**）写进自己的沙箱，用**同一个扫描器、同一条代码路径**扫它，
#      要求 `DQ-BACKTICK` 命中行号**恰为** `2,6,8,12`（8 条）**且** `HEREDOC-BACKTICK` 命中行号
#      **恰为** `19`（4 条）—— **两类分别比**（只比一类 ⇒ 另一类的判据偏了也看不出来）。
#      不符 ⇒ `SHELL_QUOTE_TRAP=NOINFO reason=canary-blind`（`rc=2`，**绝不是绿**）。
#     金丝雀夹具的文本本身放在**加引号的 heredoc** 里 ⇒ 本件扫自己时它不被当成代码（自指一致）。
#     可用 `QT_TEST_BLIND=1` **故意弄瞎**扫描器 ⇒ 必须变成 `NOINFO`（`--selftest` 的 S18 就是这一例）。
#   ★ `#31` W31F **给金丝雀加了两条成对探针**（夹具行 13–16 与 18–20）：
#     ① `"$( … <<'CANARY_Q' … )"` 体含反引号 ⇒ 必**不**命中（防**假红**，即本趟那 18 条的形状）；
#     ② `<<CANARY_U`（**无引号**定界）体含反引号 ⇒ 必**命中**（防**假绿**，即旧件的漏判）。
#     实测弄瞎读数（本仓真树 + `--root`）：删掉 ② ⇒ `NOINFO … hd_got=''(0 条) hd_want='19,'(4 条)`；
#     把 ① 的定界符去引号 ⇒ `NOINFO … hd_got='14,19,'(6 条)`（**探针确实活着**）。
#   ⚠️ 另记一条**本件自己的血案**：我第一版独立复算器**忘了在行尾复位"注释"状态**
#      ⇒ **文件里第一个 `#` 之后整份被当注释**，实测把 1043 条候选吃成 **0 命中**。
#      该 bug 已修，并写成 `--selftest` 的 S6／S8 两例（**陷阱在注释之后 / heredoc 之后仍必红**）。
#   ⚠️ `#31` W31F 的**第三条血案**（同族、更隐蔽）：引号/嵌套状态算错 ⇒ 状态**卡住**。
#      现场实测旧件在 `build-hygiene-import-check.sh:307`（`"…"` 与 `'…'` 混排）之后
#      **第 308–508 行整整 201 行**被卡在 `S`（单引号）态 ⇒ 那片区域**全盲**（种一条真陷阱 ⇒
#      旧件 0 命中）。新件把它修成 `N` 态（`--selftest` S29 就是这一形状的回归）。
#      全树机器证：非 `N` 态行首数 **473 → 96**；**没有任何一个文件**的新值比旧值大。
#
# 【临时文件（纪律 63）】所有临时件都在**自己 `mktemp -d`** 的目录里（走 `TMPDIR`）⇒ 沙箱/并发车道互不干扰。
#   `--debug-tmp` 打印实际目录且**不清理**。
#
# 【它是什么、不是什么（边界）】
#   能证明：件集里**每一处**"双引号内的裸反引号"都被点名；无引号 heredoc 体里的反引号被点名；
#   扫描器**本趟确实活着**（金丝雀，**两类判据分别比**）；件集没缩水（锚）。
#   **不能**证明：① 反引号在 `$( )` 的**命令上下文**里被**误写**（那是合法语法，只有人能判）；
#   ② 单引号里"本该是双引号"的笔误（文本上无差别）；③ `.py` 里字符串最终是否被交给 shell
#   （只按同行标记判窄族）；④ `<< EOF`（定界符与 `<<` **之间带空格**）形态的 heredoc **不被识别**
#   ⇒ 那种文件的 heredoc 体**会被当普通 shell 扫** ⇒ 失败方向是**假红（响得出来）而不是假绿**
#   （实测：本仓 `<<` **全部**是紧邻形态；`#31` W31F 复测 6 处 `<<[A-Za-z_]`，无带空格形态）；
#   ⑤ `1 << 20` 这类**算术语义**的 `<<`（本仓唯一一处，在 `shim-in-artifact.sh:102` 的 heredoc 体内）
#   用的是**紧邻要求**来排除，`--selftest` 的 S09 专门测它**不许**把后续行吞掉；
#   ⑥ **普通 `( … )` 的配对是近似的**（按 `(`/`)` 压帧/弹帧）：若某文件在**命令上下文**里出现
#   **未配对**的 `(`（实测本仓 128 件**没有**），帧栈会错位 ⇒ 失败方向**两个都有**，
#   所以 `#31` W31F 用"非 `N` 态行首数"（**473 → 96**，**无一文件变差**）作为机器证把方向钉住；
#   ⑦ `--anchors off`（`QT_ANCHORS=off`）会**跳过**件集缩水锚断言 —— 它**每次都被印在**
#   `SHELL_QUOTE_SCAN=… anchors=off …` 那一行里（可见、不静默），但它**不进** `SHELL_QUOTE_TRAP=` 结论行。
#
# 【成本】单趟 ≈0.2 s（现场 128 件 / 2.4 MB / 40394 行；扫描核心是**一次 `awk` 顺序状态机**）、零 `dotnet`、
#   零世代成本（不动九位、不动 `GEN_KEYS`、不动 `known-red.json`、不动被测树 ⇒ **纯读**）。
#   ⚠️ **实现口径说明（如实写）**：词法状态机写成**一段 `awk`**，由本 bash 脚本驱动（`sed`/`awk`/`grep`
#   在本仓 `build/MilBridge/tools/*` 里是通行做法，本件与之同族）。**不用纯 bash 逐字符循环**的理由是**实测**：
#   同形状的 bash 逐字符版单趟 **7.98 s**，且因为不做 heredoc 体跳过而多出 **328 条假命中**（实测 340 vs 12）。
#
# ─────────────────────────────────────────────────────────────────────────────
# 【接线（已落地；**本件不改 `verify-all.sh`** —— 它是主控写域，这里只记现场读数）】
#   `#31` 主控已把本件接成 `verify-all.sh` 的第 `[15]` 步；现场（`verify-all.sh` sha16
#   `cda2e8a557456bee`、781 行、21 步）：`:695` = `run_step "QUOTE-TRAP" bash build/MilBridge/tools/shell-quote-trap-check.sh`，
#   步名声明在 `:48`（`# VERIFYALL-STEP-NAMES:`，末项 `QUOTE-TRAP`），口径句在 `:20`/`:47`/`:52`。
#   ⚠️ 本件**没有**改 `verify-all.sh` 一个字节（W31F 只写本件；收工 sha16 与开工逐位相同）。
#   ⚠️ 步名/步数声明块与 `build/MilBridge/tools/verify-all-step-check.sh` 的名单必须**同趟**配平
#      （第 `[11]` 步逐字对账；缺一即红）—— 那两件**都不在本车道写域**。
#   ⚠️ `run_step` 绿分支只在行首捞 `^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO)( |$)`（`verify-all.sh:259` 的
#      "自报口径"那行）⇒ 本件的主判词 `SHELL_QUOTE_TRAP=` 正好被它捞到；**逐条命中行**是
#      `SHELL_QUOTE_HIT kind=…`（前缀后是空格，**不匹配**那两条 grep）⇒ 不会污染口径行。
# DG120_PATCH_MARK: `D-G120` CONTINUATION-COMMENT 新类已打入（W152A-W65，波 `#65`）
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ⚠️ 必须**绝对**路径：`--selftest` 会 `cd` 进沙箱再 `bash "$SELF"` 拉起子进程（相对路径在那里 `rc=127`）
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"
REAL_ROOT="$(cd "$HERE/../../.." && pwd)"

ROOT="${QT_ROOT:-$REAL_ROOT}"
ANCHOR_MODE="${QT_ANCHORS:-strict}"        # strict | off（off 只给 --selftest 的小夹具用）
MIN_FILES="${QT_MIN_FILES:-40}"            # 件集下限（现场 127）；低于它 ⇒ 扫描定义失效 ⇒ NOINFO
MIN_TOOLS="${QT_MIN_TOOLS:-15}"            # build/MilBridge/tools/*.sh 下限（现场 20）
MAX_DIAG="${QT_MAX_DIAG:-8}"               # 诊断行的**打印**上限（计数永远全量）
BLIND="${QT_TEST_BLIND:-0}"                # 只给 --selftest 用：故意弄瞎扫描器
KEEP_TMP=0
TMP_DIR_USED=''

# 金丝雀：必命中的**行** 2/6/8/12/19 ＋ 必不命中的行 3/4/5/7/10/14；命中逐反引号计
#   `DQ-BACKTICK` 4 行 × 2 = 8 条 ／ `HEREDOC-BACKTICK` 1 行 × 4 = 4 条（**两类分别比**）
#   ⚠️ 行 9/10/11 = **加引号的 heredoc**（体在运行时**不展开** ⇒ 行 10 必须不命中），
#      行 12 = **heredoc 之后**的陷阱 —— 这一条专测"heredoc 状态必须复位"（本件血案②的现场形状）。
#   ⚠️ **`#31` W31F 新增的两条探针（行 13–18）**：
#      行 13–16 = `"$( … <<'CANARY_Q' … )"` 形态（`#31` 那 18 条假红的真形状）⇒ 行 14 必**不**命中；
#      行 18–20 = `<<CANARY_U`（**无引号**定界）体含反引号 ⇒ 行 19 必**命中**（旧件只 DIAG ⇒ 漏判）。
#      这两条**成对**：一条防假红、一条防假绿，任何一条不成立 ⇒ 扫描器判据已偏 ⇒ NOINFO。
CANARY_FIRE='2,6,8,12,'
CANARY_N=8
CANARY_FIRE_N=4          # 必命中的**行**数（DQ-BACKTICK）
CANARY_HDFIRE='19,'
CANARY_HDN=4             # 必命中的 HEREDOC-BACKTICK 条数（行 19 有 **4** 个反引号，逐反引号计）
CANARY_HDFIRE_N=1        # 必命中的**行**数（HEREDOC-BACKTICK）
CANARY_CLEAN_N=5         # 含反引号但必不命中的**行**数：3/4/7/10/14
CANARY_PROBES=31         # 夹具总行数（20 → 31：`D-G120` 新类探针 11 行）
# ★ `D-G120`（`#65` W152A）**新类** `CONTINUATION-COMMENT` 的金丝雀常量（夹具行 24 / 30 必命中；
#   行 22 / 27 必**不**命中 = 成对阴性探针）。三个类**分别比**：只比两类 ⇒ 第三类的判据偏了也看不出来。
CANARY_CCFIRE='24,30,'
CANARY_CCN=2             # 必命中的条数（每行 1 条：col 指向 `#`）
CANARY_CCFIRE_N=2        # 必命中的**行**数

say() { printf '%s\n' "$*"; }

usage() {
    cat <<'TXT'
用法：
  shell-quote-trap-check.sh [--root DIR] [--anchors strict|off] [--debug-tmp] [--list-files]
  shell-quote-trap-check.sh --selftest

判据：件集（`*.sh`/`*.py`，减 `upstream/` 与 `obj|bin|.artifacts|__pycache__`）里
      **不许**出现「双引号字符串内的裸反引号」（`echo "…`cmd`…"` ⇒ bash 真的做命令替换）；
      **也不许**出现「**未加引号** heredoc 体里的反引号」（`cat <<EOF … `date` … EOF` ⇒ 同样真的替换）。
      **也不许**出现「行尾反斜杠续行里插进来的 `#` 注释行」（`D-G120`：`\` 先拼行、再认注释 ⇒
      注释把续行剩下的参数表整段吃掉，紧随的物理行变成**新命令被执行**）。
      ⚠️ `cat <<'EOF'`（**单引号定界**）的体是字面文本 ⇒ **判绿**，包括它出现在 `"$( … )"` 内部时。
rc：0 = PASS（0 条陷阱）｜1 = FAIL（逐条点名 file:line:col）｜2 = NOINFO（算不出来 ⇒ **不是绿**）
环境：QT_ROOT（树根，默认=本脚本上溯三级）｜QT_ANCHORS=off（跳过锚断言，只给自测夹具）
      QT_MIN_FILES/QT_MIN_TOOLS（件集下限）｜QT_MAX_DIAG（诊断打印上限）｜QT_TEST_BLIND=1（自测用）
TXT
}

# ── 扫件集：相对路径清单（cd 进 ROOT 后 find ⇒ 清单是仓相对路径） ─────────────────────
collect_lists() {  # collect_lists <tmpd> ; 输出 FILES_N / SH_N / PY_N
    local tmpd="$1"
    ( cd "$ROOT" && find . \( -name '*.sh' -o -name '*.py' \) -type f \
        -not -path './upstream/*' -not -path '*/obj/*' \
        -not -path '*/.artifacts/*' -not -path '*/__pycache__/*' -print 2>/dev/null \
      | sed 's|^\./||' | LC_ALL=C sort ) > "$tmpd/all.list"
    # ── 射程可见（`TASK-0713`／`#60` W152A）：被排除的目录类**逐条计数**，绝不静默 ──────────
    #   ⚠️ 旧件把 `*/bin/*` 与 `*/obj/*` **并列静默排除**；实测（成对）：**同一颗真陷阱**放 `*/bin/*`
    #      ⇒ `PASS traps=0`（**静默出射程**＝假绿方向）、挪到 `build/MilBridge/tools/` ⇒ `FAIL traps=2`。
    #      修法 = **把 `bin/` 纳入扫描**（真判），同时把"没扫什么"**永远打印**。
    #   ⚠️ `upstream/` **刻意保留排除**（vendored 上游快照，改它无意义；与 `fp_inputs()` 同口径），
    #      但它**必须被点名计数**。
    EXCL_REPORT=""
    for _cat in 'upstream:./upstream/*' 'obj:*/obj/*' '.artifacts:*/.artifacts/*' '__pycache__:*/__pycache__/*'; do
        _nm="${_cat%%:*}"; _pt="${_cat#*:}"
        _n=$( ( cd "$ROOT" && find . \( -name '*.sh' -o -name '*.py' \) -type f -path "$_pt" -print 2>/dev/null ) | grep -c . || true )
        EXCL_REPORT="${EXCL_REPORT}${_nm}:${_n:-0} "
    done
    : > "$tmpd/sh.list"; : > "$tmpd/py.list"
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        case "$f" in
            *.sh) printf '%s\n' "$f" >> "$tmpd/sh.list" ;;
            *.py) printf '%s\n' "$f" >> "$tmpd/py.list" ;;
        esac
    done < "$tmpd/all.list"
    # ⚠️ **不许写 `grep -c … || echo 0`**：`grep -c` 在 0 命中时**自己就打印 `0` 并以 1 退出**
    #   ⇒ 那个 `||` 会再补一个 `0` ⇒ 变量变成两行（"0\n0"）⇒ 后面的 `[ … -eq 0 ]` 报"需要整数表达式"
    #   并**一路滑成假绿**。本件自测 S15 的第一次现场就是这个（已修，留此注）。
    FILES_N=$(grep -c . "$tmpd/all.list" 2>/dev/null); FILES_N=${FILES_N:-0}
    SH_N=$(grep -c . "$tmpd/sh.list" 2>/dev/null);    SH_N=${SH_N:-0}
    PY_N=$(grep -c . "$tmpd/py.list" 2>/dev/null);    PY_N=${PY_N:-0}
}

# ── awk 状态机（写进沙箱再 -f 调起；单趟顺序、跨行保持引号状态、识别加引号的 heredoc） ──────
write_awk() {  # write_awk <path>
    cat > "$1" <<'AWKPROG'
# 输出协议（制表符分隔，单趟顺序）：
#   HIT   <kind> <file> <line> <col> <excerpt>
#   DIAG  <kind> <file> <line> <col> <excerpt>
#   ALLOW <kind> <file> <line> <col> <excerpt>
#   PYC   <file> <n>          每文件一行：含反引号的 .py 行数
#   STAT  lines=<n> bytes=<n> files=<n> cmdsub=<n> pyc=<n> pycomment=<n> blind=<n>
function exc(s,   t) {
    t = s
    gsub(/\t/, " ", t)
    if (length(t) > 110) t = substr(t, 1, 110) "…"
    return t
}
function emit(tag, kind, f, ln, col, txt) {
    printf "%s\t%s\t%s\t%d\t%d\t%s\n", tag, kind, f, ln, col, exc(txt)
    if (tag == "HIT") hitn[kind]++
}
# ── 嵌套帧栈（★ `#31` W31F 新增；旧件用 `nest` + `stack` 两个标量，见下方逐条论证）────────
#   `kinds`：每帧一个字符 —— `p` = `$( … )`｜`s` = 普通 `( … )`（子 shell/数组/算术）｜`b` = `${ … }`
#   `rets` ：与 `kinds` **平行**，存"这一帧闭合后回到哪个引号状态"（`N`/`D`）
#   ⚠️ 旧件**三个**后果（全部现场实测，见报告 §2）：
#     ① 进入 `$(` 时**状态仍是 `D`** ⇒ heredoc 识别分支（只在 `N` 态里）**永远看不到** `<<'DELIM'`
#        ⇒ 体被当普通 shell 扫 ⇒ 体里的反引号被判成 `DQ-BACKTICK`（**假红 18 条**，现场即
#        `build/MilBridge/tools/column-floor-check.sh:201-203` 的 python 注释）。
#     ② `"$(cmd "arg" … )"` 里那个**内层双引号**把状态从 `D` 打成 `N`（丢掉外层 `D`）⇒ 之后
#        的引号全乱 ⇒ 实测 `build-hygiene-import-check.sh` **第 308–508 行整整 201 行**被卡在
#        `S`（单引号）态 ⇒ **盲区**（那里藏真陷阱也抓不到；实测种一条 ⇒ 旧件 0 命中）。
#     ③ `D` 态里**单引号不被识别** ⇒ `"$(sed -n 's/…`…`…/…')"` 这类（`verify-all-step-check.sh:251`）
#        在旧件里被算成"合法命令替换"，在新件里正确地落进 `S` 态。
#   ⚠️ **实测口径（128 件全树）**：非 `N` 态行首数 **473 → 96**；**没有任何一个文件**的新值比旧值大
#      （即本改动**只会减少**"引号态盲区"、不会新增）⇒ 方向是**加强**、不是改动判定语义。
function topk(   L) { L = length(kinds); return (L > 0) ? substr(kinds, L, 1) : "" }
function pushk(k, r) { kinds = kinds k; rets = rets r }
function popk(   L) {
    L = length(kinds)
    if (L == 0) return
    state = substr(rets, L, 1)
    kinds = substr(kinds, 1, L - 1)
    rets  = substr(rets, 1, L - 1)
}
function scanline(f, line, ln,   i, n, c, d, p, j, q, rest, k, t, tk) {
    hd_seen = 0                                  # ★ 每行先清（本件血案②：不清 ⇒ heredoc 结束后被反复重开）
    linecont = 0                                 # ★ `D-G120`：每行先清（"本行以反斜杠续行结尾且该反斜杠在 N 态"）
    if (hd) {                                   # heredoc 体内：不是 shell 代码
        t = line
        if (hd_dash) sub(/^\t+/, "", t)
        if (t == hd_delim) { hd = 0; return }
        # ★ `#31` W31F **加强**：`<<EOF`（**未加引号**定界）的体在运行时**真的**做命令替换
        #   ⇒ 体里每个反引号都是真陷阱 ⇒ 判 **HIT**（旧件只 `emit("DIAG", …)` ⇒ **不进 `rc`**）。
        #   现场实证：`cat <<EOF` + 体里 `` `X` `` ⇒ 真跑 stdout 少了那两个反引号、stderr 多一行
        #   `…: X: 未找到命令`（成对读数见报告 §4）。**无引号** heredoc 体是本仓**唯一**会被
        #   `read -r … <<EOF` 这类"值即命令输出"写法用到的形态 ⇒ 漏判它 = 真洞。
        if (!hd_quoted) {
            for (p = 1; p <= length(line); p++) {
                if (substr(line, p, 1) != "`") continue
                if (allow) emit("ALLOW", "HEREDOC-BACKTICK", f, ln, p, line)
                else       emit("HIT",   "HEREDOC-BACKTICK", f, ln, p, line)
            }
        }
        return
    }
    i = 1; n = length(line)
    while (i <= n) {
        c = substr(line, i, 1)
        if (state == "C") return                  # 注释只到行尾（复位在驱动层）
        if (state == "S") {                       # 单引号：反引号是字面量
            if (c == "'") state = "N"
            i++; continue
        }
        if (state == "D") {                       # 双引号
            if (c == "\\") { i += 2; continue }   # 转义 ⇒ 字面量
            if (c == "\"") { state = "N"; i++; continue }
            if (c == "$") {
                d = substr(line, i + 1, 1)
                # ★ `$(` ⇒ **进入真正的命令上下文**：状态切 `N`，把"回到 `D`"压进帧。
                #   旧件只 `nest++` 而不切状态 ⇒ 这正是上面 ①②③ 的共同根因。
                if (d == "(") { pushk("p", "D"); state = "N"; i += 2; continue }
                # `${` ⇒ 仍是**双引号字符串内部**（参数展开不终止 DQ）⇒ 状态保持 `D`，只压一帧
                if (d == "{") { pushk("b", "D"); i += 2; continue }
                i++; continue
            }
            if (c == "`") {
                # 帧顶是 `b`（即 `${ … }` 里，如 `"${x:-`cmd`}"`）⇒ 诊断；否则（裸 DQ，或
                # DQ 内部再嵌的 DQ）⇒ **判红**。★ 新件里"帧顶是 `p`"只可能意味着"这个 DQ 是在
                # `$( … )` **内部**新开的" ⇒ 那里的裸反引号**真的**会做命令替换 ⇒ 该判红
                #（旧件把它算成合法 ⇒ 实测假阴性：`out="$(printf '%s' "abc`X`def")"` 旧件 0 命中、
                #  新件 2 命中，而真跑 stdout 少了 `abc…def` 那几个字）。
                if (topk() == "b") {
                    emit("DIAG", "DQ-BRACE-BACKTICK", f, ln, i, line)
                } else if (allow) {
                    emit("ALLOW", "DQ-BACKTICK", f, ln, i, line)
                } else {
                    emit("HIT",   "DQ-BACKTICK", f, ln, i, line)
                }
                i++; continue
            }
            # ⚠️ `D` 态里**只有 `}` 能闭合 `${ … }`**；`"…SKIP(stub)…"` 里的那个 `)` 是**字面字符**。
            #   实测血案（W31F 第一版）：把 `)` 也接上闭合 ⇒ `build/DirectWrite.Linux/wic-shim/
            #   check-applocal-sync.sh:163` 的 `SKIP(stub)` 弹掉了数组的 `(` 帧 ⇒ 状态错成 `N`
            #   ⇒ 其后整片注释被当 DQ 扫 ⇒ **多出 30 条假红**。修法：`D` 态不认 `)`。
            if (c == "}") { if (topk() == "b") popk(); i++; continue }
            i++; continue
        }
        # ── state N（命令上下文）──
        # ★ `D-G120`：**行尾反斜杠 = 续行**，且**只有 `N` 态才算数**（单引号里是字面量；注释里
        #   bash 根本不续行；`\\` 也不是续行 —— 三条都有真跑读数 P3/P4/P5，见报告 §2）。
        #   标记留给**下一物理行**判 `CONTINUATION-COMMENT`（判定点在 `dofile`，不在本函数）。
        if (c == "\\") { if (i == n) linecont = 1; i += 2; continue }
        if (c == "'") { state = "S"; i++; continue }
        if (c == "\"") { state = "D"; i++; continue }
        # ★ 新：`$(` / `${` 在**命令上下文**里也要压帧（旧件只在 `D` 态里认它们 ⇒ `echo $( … )`
        #   根本没有帧 ⇒ 里面再套 `"…"` 时配对会错）。帧的"返回态"就是 `N` ⇒ 对**良构**代码
        #   （实测全树 128 件）状态序列零变化；它只让**嵌套**情形算得对。
        if (c == "$") {
            d = substr(line, i + 1, 1)
            if (d == "(") { pushk("p", "N"); i += 2; continue }
            if (d == "{") { pushk("b", "N"); i += 2; continue }
            i++; continue
        }
        # ★ 新：普通 `( … )`（子 shell / 数组 / `$(( ))` 算术）也压帧 ⇒ `$( ( … ) … )` 能正确配对
        if (c == "(") { pushk("s", "N"); i++; continue }
        if (c == ")") { if (topk() == "p" || topk() == "s") popk(); i++; continue }
        if (c == "}") { if (topk() == "b") popk(); i++; continue }
        if (c == "#") {
            p = (i > 1) ? substr(line, i - 1, 1) : " "
            # ★ `D-G114`（`#60` W152A 修）：**先判帧顶是不是 `b`** —— 是 `b`（＝在 `${ … }` 里）就
            #   **绝不**当注释。因为 `${#arr[@]}` 里那个 `#` 的前一字符正是 `{`，而 `{` 就在下面那个
            #   字符类里 ⇒ 旧件把它判成"注释"并 `return` 到行末 ⇒ `${`（`:280` 压 `b`）**永远等不到 `}`**
            #   （`:301` 只有 `}` 能弹 `b`）⇒ **帧顶永久滞留 `b`** ⇒ 此后**本文件任何**双引号里的裸反引号
            #   都走 `:291` 的 `emit("DIAG","DQ-BRACE-BACKTICK")` ⇒ **不进 `rc`** ＝ **假绿**。
            #   实证：`tools/prereg-four-requirements-check.sh:313` 的真陷阱（真跑 stderr 打 `SKIP: 未找到命令`、
            #   汇总行里 `` `SKIP` `` 那几个字消失）。两极化：同一颗陷阱前面只多一行 `if [[ ${#arr[@]} -gt 0 ]]`
            #   ⇒ 旧件 `PASS traps=0`、新件 `FAIL traps=2`。全树量化 `traps 0→2`、`diag 73→71`、**零假红**。
            #   ⚠️ 本改**只修"帧顶错成 `b`"**；"**真的**在 `${ … }` 里"那一档**仍只诊断、不进 `rc`**（语义未动）。
            if (topk() != "b" && (i == 1 || p == " " || p == "\t" || p ~ /[;|&(){}<>]/)) { state = "C"; return }
            i++; continue
        }
        if (c == "<" && substr(line, i + 1, 1) == "<") {
            if (substr(line, i + 2, 1) == "<") { i += 3; continue }   # here-string <<<
            j = i + 2
            if (substr(line, j, 1) == "-") { hd_dash = 1; j++ } else hd_dash = 0
            q = substr(line, j, 1)
            if (q == "'" || q == "\"") {
                rest = substr(line, j + 1); k = index(rest, q)
                if (k > 0) {
                    hd_delim = substr(rest, 1, k - 1); hd_quoted = 1; hd_seen = 1
                    i = j + k + 1; continue
                }
            } else {
                rest = substr(line, j)
                if (match(rest, /^[A-Za-z0-9_]+/)) {                       # 紧邻定界符（本仓 43/43 如此）
                    hd_delim = substr(rest, 1, RLENGTH); hd_quoted = 0; hd_seen = 1
                    i = j + RLENGTH; continue
                }
            }
            i += 2; continue                                               # `1 << 20` 这类算术 ⇒ 不是 heredoc
        }
        if (c == "`") { cmdsub++; i++; continue }                          # 命令上下文里的反引号：合法
        i++
    }
}
function dofile(f, kind,   line, ln, marker) {
    state = "N"; kinds = ""; rets = ""; hd = 0; hd_seen = 0; hd_delim = ""
    hd_quoted = 0; hd_dash = 0; prev_allow = 0; allow = 0
    # ★ `D-G120`：跨物理行的两个进位（文件之间必须复位，否则上一份的尾巴会污染下一份）
    prev_cc_bs = 0; prev_cc_state = "N"
    ln = 0
    if (blind) return
    while ((getline line < f) > 0) {
        ln++; lines++; bytes += length(line) + 1
        if (kind == "py") {
            if (index(line, "`") == 0) continue
            if (line ~ /^[ \t]*#/) { pycomment++; continue }                # 纯注释行不看
            if (line ~ /shell[ \t]*=[ \t]*True|os\.system[ \t]*\(|os\.popen[ \t]*\(|subprocess\./) {
                emit("HIT", "PY-SHELLSTRING", f, ln, index(line, "`"), line)
            } else { pyc[f]++ }
            continue
        }
        marker = (index(line, "shell-quote-trap:allow") > 0)
        allow = (marker || prev_allow) ? 1 : 0
        prev_allow = (marker && line ~ /^[ \t]*#/) ? 1 : 0
        # ★ `D-G120`（`#65` W152A）**第三类**：上一物理行的**行尾反斜杠续行**成立（上一行结束时
        #   仍在 `N` 态）且本行匹配 `^[ \t]*#` ⇒ 本行是**被插进续行里的注释** ⇒ 判红。
        #   ⚠️ 必须**在 scanline 之前**判：此刻 prev_cc_* 还是上一行留下的值（scanline 会清 linecont）。
        #   ⚠️ `hd` 里不判（heredoc 体不是代码）；`.py` 走上面的分支，根本到不了这里。
        if (!hd && prev_cc_bs && prev_cc_state == "N" && line ~ /^[ \t]*#/) {
            cc = index(line, "#")
            if (allow || prev_allow) emit("ALLOW", "CONTINUATION-COMMENT", f, ln, cc, line)
            else                     emit("HIT",   "CONTINUATION-COMMENT", f, ln, cc, line)
        }
        scanline(f, line, ln)
        prev_cc_bs = linecont
        if (state == "C") state = "N"                                       # ★ 行尾必须复位（本件自己的血案）
        prev_cc_state = state
        if (hd_seen) hd = 1
    }
    close(f)
}
BEGIN {
    FS = "\t"
    while ((getline lf < shlist) > 0) { if (lf == "") continue; files++; dofile(lf, "sh") }
    close(shlist)
    while ((getline lf < pylist) > 0) { if (lf == "") continue; files++; dofile(lf, "py") }
    close(pylist)
    for (f in pyc) if (pyc[f] > 0) printf "PYC\t%s\t%d\n", f, pyc[f]
    for (k in hitn) printf "HITN\t%s\t%d\n", k, hitn[k]
    printf "STAT\tlines=%d\tbytes=%d\tfiles=%d\tcmdsub=%d\tpycomment=%d\tblind=%d\n", \
           lines, bytes, files, cmdsub, pycomment, blind
}
AWKPROG
}

# ── 金丝雀（每一趟都跑；不符 ⇒ NOINFO） ──────────────────────────────────────────
write_canary() {  # write_canary <path>
    cat > "$1" <<'CANARY'
# canary: 行 2/6/8/12 必须命中；行 3/4/5/7/10 必须不命中
echo "A `must_fire_1` B"
echo 'A `must_not_fire_squote` B'
echo "A \`must_not_fire_escaped\` B"
echo "A $(date) B"
printf '%s\n' "C `must_fire_2` D"
# 注释里的 `must_not_fire_comment` 不算
echo "E `must_fire_3` F"
cat <<'CANARY_EOF'
echo "F `must_not_fire_heredoc_body` G"
CANARY_EOF
echo "H `must_fire_4` I"
probe_a="$(printf '%s' <<'CANARY_Q' 2>/dev/null
echo "J `must_not_fire_dq_cmdsub_heredoc_body` K"
CANARY_Q
)"
# 下面这一行与上面那一段**配对**：无引号定界 ⇒ 体真的做命令替换 ⇒ 必须命中
cat <<CANARY_U
L `must_fire_heredoc_unquoted_1` M `must_fire_heredoc_unquoted_2` N
CANARY_U
# == D-G120 continuation-comment probes ==
# a normal comment line (previous line does NOT end with a backslash) => must NOT fire
printf '%s\n' CAN_CC_1 \
    # CAN_CC_COMMENT_1 inside the continuation => MUST fire
    CAN_CC_2
s='can_cc_squote\
# the backslash above is inside single quotes => NOT a continuation => must NOT fire
'
printf '%s\n' CAN_CC_3 \
	# CAN_CC_COMMENT_2 with a leading tab => MUST fire
	CAN_CC_4
CANARY
}

run_awk() {  # run_awk <tmpd> <shlist> <pylist> [<blind>]
    local tmpd="$1" shl="$2" pyl="$3" b="${4:-0}"
    ( cd "$ROOT" && awk -v shlist="$shl" -v pylist="$pyl" -v blind="$b" -f "$tmpd/scan.awk" ) 2>"$tmpd/awk.err"
}

# ── 主判据 ─────────────────────────────────────────────────────────────────────
run_check() {
    local tmpd rc awke out canline canfire cann canhd canhdn cancc canccn hitn hitlines n
    local TMPBASE="${TMPDIR:-/tmp}"

    TMP_DIR_USED=''
    [ -n "$ROOT" ] || { say "SHELL_QUOTE_TRAP=NOINFO reason=empty-root"; return 2; }
    if [ ! -d "$ROOT" ]; then
        say "SHELL_QUOTE_TRAP=NOINFO reason=root-missing root=$ROOT"
        return 2
    fi
    if ! command -v awk >/dev/null 2>&1; then
        say "SHELL_QUOTE_TRAP=NOINFO reason=awk-not-found（PATH 上没有 awk ⇒ 词法扫描器跑不起来）"
        return 2
    fi
    tmpd="$(mktemp -d "$TMPBASE/shell-quote-trap.XXXXXX" 2>/dev/null)" || {
        say "SHELL_QUOTE_TRAP=NOINFO reason=mktemp-failed TMPBASE=$TMPBASE"; return 2; }
    TMP_DIR_USED="$tmpd"

    write_awk "$tmpd/scan.awk"
    collect_lists "$tmpd"

    # ── 取不到件 ⇒ NOINFO（纪律：不许当绿）───────────────────────────────────────
    if [ "${FILES_N:-0}" -eq 0 ]; then
        say "SHELL_QUOTE_TRAP=NOINFO reason=scan-empty root=$ROOT（扫描集为空 ⇒ 算不出来）"
        [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"; return 2
    fi
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        if [ ! -r "$ROOT/$f" ]; then
            say "SHELL_QUOTE_TRAP=NOINFO reason=unreadable-file file=$f"
            [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"; return 2
        fi
    done < "$tmpd/all.list"

    # ── 扫描定义不许悄悄缩水（锚断言；D-R4 那族）────────────────────────────────
    if [ "$ANCHOR_MODE" = strict ]; then
        if [ "${FILES_N:-0}" -lt "$MIN_FILES" ]; then
            say "SHELL_QUOTE_TRAP=NOINFO reason=scan-definition-broken files=$FILES_N min=$MIN_FILES（件集缩小 ⇒ 射程可能已缩到零）"
            [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"; return 2
        fi
        if ! grep -qx 'verify-all.sh' "$tmpd/all.list"; then
            say "SHELL_QUOTE_TRAP=NOINFO reason=scan-definition-broken anchor-missing=verify-all.sh"
            [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"; return 2
        fi
        n="$(grep -c '^build/MilBridge/tools/.*\.sh$' "$tmpd/all.list" 2>/dev/null)"; n=${n:-0}
        if [ "$n" -lt "$MIN_TOOLS" ]; then
            say "SHELL_QUOTE_TRAP=NOINFO reason=scan-definition-broken tools=$n min=$MIN_TOOLS（build/MilBridge/tools/*.sh 没进扫描集）"
            [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"; return 2
        fi
    fi

    # ── 金丝雀：证明扫描器本趟活着（★ 防"检查器失明"）────────────────────────────
    write_canary "$tmpd/canary.sh"
    printf '%s\n' 'canary.sh' > "$tmpd/canary.list"
    : > "$tmpd/empty.list"
    if [ "$BLIND" = 1 ]; then
        canline="$( ( cd "$ROOT" && awk -v shlist="$tmpd/canary.list" -v pylist="$tmpd/empty.list" -v blind=1 -f "$tmpd/scan.awk" ) 2>/dev/null )"
    else
        canline="$( ( cd "$tmpd" && awk -v shlist="canary.list" -v pylist="empty.list" -v blind=0 -f "$tmpd/scan.awk" ) 2>/dev/null )"
    fi
    # ⚠️ 命中是**逐反引号**计的（`"…`x`…"` 的开、闭两个反引号**都**落在双引号里 ⇒ 每行 2 条）
    #   ⇒ 金丝雀比的是**行号集合**（去重）＋ 命中**条数**，两个都不许含糊；`DQ-BACKTICK` 与
    #   `HEREDOC-BACKTICK` **两类都比**（`#31` W31F：只比一类 ⇒ 另一类的判据偏了也看不出来）。
    canfire="$(printf '%s\n' "$canline" | awk -F'\t' '$1=="HIT" && $2=="DQ-BACKTICK"{print $4}' | sort -nu | tr '\n' ',')"
    cann="$(printf '%s\n' "$canline" | awk -F'\t' '$1=="HIT" && $2=="DQ-BACKTICK"{n++} END{print n+0}')"
    canhd="$(printf '%s\n' "$canline" | awk -F'\t' '$1=="HIT" && $2=="HEREDOC-BACKTICK"{print $4}' | sort -nu | tr '\n' ',')"
    canhdn="$(printf '%s\n' "$canline" | awk -F'\t' '$1=="HIT" && $2=="HEREDOC-BACKTICK"{n++} END{print n+0}')"
    # ★ `D-G120`：第三类也**单独比**（行号集合 ＋ 条数）—— 只比两类 ⇒ 新类判据偏了也看不出来
    cancc="$(printf '%s\n' "$canline" | awk -F'\t' '$1=="HIT" && $2=="CONTINUATION-COMMENT"{print $4}' | sort -nu | tr '\n' ',')"
    canccn="$(printf '%s\n' "$canline" | awk -F'\t' '$1=="HIT" && $2=="CONTINUATION-COMMENT"{n++} END{print n+0}')"
    if [ "$canfire" != "$CANARY_FIRE" ] || [ "$cann" != "$CANARY_N" ] \
       || [ "$canhd" != "$CANARY_HDFIRE" ] || [ "$canhdn" != "$CANARY_HDN" ] \
       || [ "$cancc" != "$CANARY_CCFIRE" ] || [ "$canccn" != "$CANARY_CCN" ]; then
        say "SHELL_QUOTE_TRAP=NOINFO reason=canary-blind dq_got='$canfire'($cann 条) dq_want='$CANARY_FIRE'($CANARY_N 条) hd_got='$canhd'($canhdn 条) hd_want='$CANARY_HDFIRE'($CANARY_HDN 条) cc_got='$cancc'($canccn 条) cc_want='$CANARY_CCFIRE'($CANARY_CCN 条)（扫描器本趟没有按已知形状命中 ⇒ 它的绿不算证据）"
        [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"; return 2
    fi

    # ── 正扫 ───────────────────────────────────────────────────────────────────
    out="$(run_awk "$tmpd" "$tmpd/sh.list" "$tmpd/py.list" 0)"
    rc=$?
    if [ "$rc" -ne 0 ]; then
        say "SHELL_QUOTE_TRAP=NOINFO reason=awk-failed rc=$rc"
        sed 's/^/    awk| /' "$tmpd/awk.err" 2>/dev/null | head -5
        [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"; return 2
    fi

    hitn="$(printf '%s\n' "$out" | awk -F'\t' '$1=="HIT"{n++} END{print n+0}')"
    hitlines="$(printf '%s\n' "$out" | awk -F'\t' '$1=="HIT"{print "SHELL_QUOTE_HIT kind=" $2 " file=" $3 " line=" $4 " col=" $5}')"
    allowlines="$(printf '%s\n' "$out" | awk -F'\t' '$1=="ALLOW"{printf "SHELL_QUOTE_ALLOW kind=%s file=%s line=%s col=%s\n", $2, $3, $4, $5}')"
    allown="$(printf '%s\n' "$out" | awk -F'\t' '$1=="ALLOW"{n++} END{print n+0}')"
    diagn="$(printf '%s\n' "$out" | awk -F'\t' '($1=="DIAG")||($1=="PYC"){n++} END{print n+0}')"
    stat="$(printf '%s\n' "$out" | awk -F'\t' '$1=="STAT"{print $2}')"
    # 诊断区（**绝不进 `rc`**）：每类**只印前 MAX_DIAG 条**，全量计数另印 `SHELL_QUOTE_DIAGN`
    diaglines="$(printf '%s\n' "$out" | awk -F'\t' -v max="$MAX_DIAG" '
        $1=="DIAG" { d[$2]++; if (d[$2] <= max) printf "SHELL_QUOTE_DIAG kind=%s file=%s line=%s col=%s\n", $2, $3, $4, $5; next }
        END { for (k in d) printf "SHELL_QUOTE_DIAGN kind=%s n=%d\n", k, d[k] }
    ')"
    pycfiles="$(printf '%s\n' "$out" | awk -F'\t' '$1=="PYC"{n++} END{print n+0}')"
    pyclines="$(printf '%s\n' "$out" | awk -F'\t' '$1=="PYC"{s+=$3} END{print s+0}')"
    # `.py` 诊断：**按行数取前 MAX_DIAG 个文件**（现场 60 文件 / 1481 行）—— 全量只印总量
    pyclist="$(printf '%s\n' "$out" | awk -F'\t' '$1=="PYC"{printf "%s\tSHELL_QUOTE_DIAG kind=PY-BACKTICK-FILE file=%s lines=%s\n", $3, $2, $3}' \
               | sort -k1 -nr | head -n "$MAX_DIAG" | cut -f2)"

    say "SHELL_QUOTE_SCAN=files=$FILES_N sh=$SH_N py=$PY_N anchors=$ANCHOR_MODE ${stat:-lines=0}"
    # ★ `TASK-0713`／`#60` W152A：**射程行** —— "扫了什么／没扫什么"永远可见（`bin/` 已纳入 ⇒ 不在排除表里）
    say "QUOTE_TRAP_SCOPE root=$ROOT files=$FILES_N sh=$SH_N py=$PY_N included=*.sh,*.py bin=INCLUDED excluded=${EXCL_REPORT:-none} (excluded dirs counted one by one; 'not scanned' must never be silent)"
    say "SHELL_QUOTE_CANARY=OK probes=$CANARY_PROBES must_fire=$CANARY_FIRE_N must_not_fire=$CANARY_CLEAN_N fired=$CANARY_FIRE hd_fired=$CANARY_HDFIRE($CANARY_HDN 条) cc_fired=$CANARY_CCFIRE($CANARY_CCN 条)"

    # ★ `#31` W31F：`reason=` **按类分**（旧件一律 `dq-backtick` ⇒ 若命中的全是无引号 heredoc 体，
    #   那一行会**说谎**）。判定值（PASS/FAIL/NOINFO）与 `rc` 语义零改动。
    hndq="$(printf '%s\n' "$out" | awk -F'\t' '$1=="HIT" && $2=="DQ-BACKTICK"{n++} END{print n+0}')"
    hnhd="$(printf '%s\n' "$out" | awk -F'\t' '$1=="HIT" && $2=="HEREDOC-BACKTICK"{n++} END{print n+0}')"
    hncc="$(printf '%s\n' "$out" | awk -F'\t' '$1=="HIT" && $2=="CONTINUATION-COMMENT"{n++} END{print n+0}')"
    # ★ `D-G120`：由**命中类集合**拼 `reason=` —— 既有两类的**三种组合**字符串逐字不变
    #   （`dq-backtick` / `heredoc-backtick` / `dq-backtick+heredoc-backtick`），新类只做**追加**。
    failreason=""
    if [ "$hndq" -gt 0 ]; then failreason="dq-backtick"; fi
    if [ "$hnhd" -gt 0 ]; then
        if [ -n "$failreason" ]; then failreason="$failreason+heredoc-backtick"; else failreason="heredoc-backtick"; fi
    fi
    if [ "$hncc" -gt 0 ]; then
        if [ -n "$failreason" ]; then failreason="$failreason+continuation-comment"; else failreason="continuation-comment"; fi
    fi
    [ -n "$failreason" ] || failreason="unknown-empty-hitn"

    if [ "$hitn" -gt 0 ]; then
        printf '%s\n' "$hitlines"
        [ -n "$allowlines" ] && printf '%s\n' "$allowlines"
        say "SHELL_QUOTE_TRAP=FAIL reason=$failreason traps=$hitn files=$FILES_N sh=$SH_N py=$PY_N diag=$diagn allow=$allown"
        emit_diag_tail
        [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"
        return 1
    fi
    say "SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=$FILES_N sh=$SH_N py=$PY_N diag=$diagn allow=$allown"
    emit_diag_tail
    [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"
    return 0
}

# 诊断尾巴（**只印、绝不进 rc**）：诊断行 + `.py` 反引号量级（按行数取前 MAX_DIAG 个文件）
emit_diag_tail() {
    [ -n "${allowlines:-}" ] && printf '%s\n' "$allowlines"     # 豁免永远可见（PASS/FAIL 都印）
    [ -n "$diaglines" ] && printf '%s\n' "$diaglines"
    [ -n "$pyclist" ] && printf '%s\n' "$pyclist"
    if [ "${pycfiles:-0}" -gt 0 ]; then
        say "SHELL_QUOTE_DIAGN kind=PY-BACKTICK-FILE n_files=$pycfiles n_lines=$pyclines（**Python 不做命令替换 ⇒ 不判红**，只报量级；上面只列前 $MAX_DIAG 个文件）"
    fi
}

# ── 反极性自测 ─────────────────────────────────────────────────────────────────
run_selftest() {
    # ── 【`D-G41` 判据件自证】本件在**自测期间**被改写 ⇒ 本趟读数**不可归因**（`NOINFO`：不许当绿、不许冒充红）──
    #   本件自测以 `bash "$SELF"` **重入自己**（`:673`/`:757`）⇒ bash 每次为新子进程从磁盘**重读**本件
    #   ⇒ 父进程按旧版造夹具、子进程按新版判 ⇒ **改件窗口里出的红是凭空的红**。
    #   口径：**开头记 sha16、结尾再算一次**；不等 ⇒ `ST_ATTEST=NOINFO` 并点名（含 sha0/sha1 与内层 rc），
    #   统一 **rc=2**（`NOINFO` 码，不与 `FAIL` 混）。只加在 `--selftest` 路径；**生产路径一字未动**；
    #   不删例、不放宽任何期望（成对读数见 `$HOME/w33b-report.md`）。
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
            return 2
        fi
        printf 'ST_ATTEST=PASS self=%s sha16=%s（自测期间本件未变 ⇒ 读数可归因）\n' "$ST_SELF" "$ST0"
        return "$ST_RC"
    fi
    local sb fix tmp_before tmp_after total=0 pass=0 fail=0 dtmp
    local TMPBASE="${TMPDIR:-/tmp}"
    sb="$(mktemp -d "$TMPBASE/qt-selftest.XXXXXX")" || { say "SELFTEST=FAIL reason=mktemp-failed"; return 1; }
    fix="$sb/root"
    mkdir -p "$fix/build/MilBridge/tools" "$fix/sub"
    tmp_before="$(find /tmp -maxdepth 1 \( -name 'shell-quote-trap.*' -o -name 'qt-selftest.*' \) 2>/dev/null | LC_ALL=C sort)"

    # ── 夹具（陷阱文本一律放在**加引号的 heredoc**里 ⇒ 本件扫自己时它不算代码）────────────
    cat > "$fix/sub/F01-trap-dquote.sh" <<'FIX'
echo "A `D-G21` B"
FIX
    cat > "$fix/sub/F02-squote.sh" <<'FIX'
echo 'A `x` B'
FIX
    cat > "$fix/sub/F03-escaped.sh" <<'FIX'
echo "A \`x\` B"
FIX
    cat > "$fix/sub/F04-cmdsub.sh" <<'FIX'
echo "A $(date) B"
FIX
    cat > "$fix/sub/F05-comment.sh" <<'FIX'
# echo "A `x` B"
FIX
    cat > "$fix/sub/F06-after-comment.sh" <<'FIX'
# 上面这一行是注释，里面有一个 `x`
echo "A `mustfire` B"
FIX
    cat > "$fix/sub/F07-heredoc-quoted.sh" <<'FIX'
cat <<'TXT'
echo "A `x` B"
TXT
FIX
    cat > "$fix/sub/F08-after-heredoc.sh" <<'FIX'
cat <<'TXT'
body `x`
TXT
echo "A `mustfire` B"
FIX
    cat > "$fix/sub/F09-arithmetic-shift.sh" <<'FIX'
a=$((1 << 20))
echo "A `mustfire` B"
FIX
    cat > "$fix/sub/F10-heredoc-unquoted.sh" <<'FIX'
cat <<EOF
value `date` here
EOF
FIX
    cat > "$fix/sub/F11-allow.sh" <<'FIX'
# shell-quote-trap:allow
echo "A `legacy` B"
FIX
    cat > "$fix/sub/F12-dq-cmdsub-inner.sh" <<'FIX'
echo "A $(echo `date`) B"
FIX
    cat > "$fix/sub/F13-py-shellstring.py" <<'FIX'
import subprocess
subprocess.run("open `foo`", shell=True)
FIX
    cat > "$fix/sub/F14-py-docstring.py" <<'FIX'
"""文档串里 `到处都是` 反引号，Python 不做命令替换"""
x = 1
FIX
    # ── `#31` W31F 新增夹具（6 条；`F15`/F16 是本趟那 18 条假红的**真形状**）──────────────
    # F15：`"$( … <<'QEOF' … )"` —— **单引号定界**的 heredoc 在 `$( … )` **内部**
    #   ⇒ 体是字面文本 ⇒ 必须**不**命中（旧件在这里判红 18 条）
    cat > "$fix/sub/F15-dq-cmdsub-heredoc.sh" <<'FIX'
js="$(python3 - "$reg" <<'QEOF' 2>/dev/null
# 单引号定界 ⇒ bash 对体不做任何替换；下面这行**真跑**即可分辨：字面 ⇒ A`W31F_MARK`B
print("A`W31F_MARK`B")
QEOF
)"
printf 'F15=[%s]\n' "$js"
FIX
    # F16：**同样的引号形状、但没有 heredoc**，且反引号**真的**会替换
    #   ⇒ 旧件在这里**漏判**（实测 0 命中），新件必须命中
    cat > "$fix/sub/F16-dq-cmdsub-implicit.sh" <<'FIX'
out="$(printf '%s' "abc`W31F_NO_SUCH_CMD`def" 2>/dev/null)"
printf 'OUT=[%s]\n' "$out"
FIX
    # F17/F18：历史真陷阱①（`seg-instrument.sh:164` 的**等价原文**）／它的 『』 中和形态
    cat > "$fix/sub/F17-hist-seg-raw.sh" <<'FIX'
echo "# 口径：`/proc/<pid>/maps`每行 = 一段；ΣRss 来自 `smaps`逐段 `Rss:`"
FIX
    cat > "$fix/sub/F18-hist-seg-neutral.sh" <<'FIX'
echo "# 口径：『/proc/<pid>/maps』每行 = 一段；ΣRss 来自 『smaps』逐段 『Rss:』"
FIX
    # F19/F20：历史真陷阱②（`run-wpfprobe.sh:948` 的**等价原文**）／它的 『』 中和形态
    cat > "$fix/sub/F19-hist-probe-raw.sh" <<'FIX'
BLOCK_REGISTRY_RESULT=x
echo "   ❌ 块注册表断言未通过（$BLOCK_REGISTRY_RESULT）⇒ 门禁判红（`block_registry_check`见 3.5/5 节）"
FIX
    cat > "$fix/sub/F20-hist-probe-neutral.sh" <<'FIX'
BLOCK_REGISTRY_RESULT=x
echo "   ❌ 块注册表断言未通过（$BLOCK_REGISTRY_RESULT）⇒ 门禁判红（『block_registry_check』见 3.5/5 节）"
FIX
    # F21：`#31` W31F 修的**盲区**回归 —— 上一行是 `"…" + '…' + '…'` 混排（旧件在这里
    #   把状态打成 `S` 并**卡住 201 行**，`build-hygiene-import-check.sh:307` 的真实形状）
    #   ⇒ 紧邻的下一行**必须**仍被抓到
    cat > "$fix/sub/F21-blind-range-regress.sh" <<'FIX'
BUILD_BASES="$(printf '%s\n' "$BUILD_LINES" | sed -e "s/[\"']//g" -e 's|.*[/\\]||' | LC_ALL=C sort -u)"
echo "A `W31F_BLIND_RANGE` B"
FIX
    # ── `#60` W152A 新增夹具 4 件（`TASK-0713` 射程 2 件 ＋ `D-G114` 泄漏 2 件）────────────
    # ⚠️ 夹具一律**纯 ASCII**：`col` 是**按字节**算的（实测 `x：` 三字节 ⇒ col 偏 2）⇒ 夹中文会算不准列号。
    # F22：真陷阱落在 **`bin/`** 下（`TASK-0713` 的现场形状）—— 旧件把它**静默排除**（`PASS traps=0`）
    mkdir -p "$fix/bin"
    cat > "$fix/bin/F22-bin-trap.sh" <<'FIX'
echo "bin trap: `TASK0713_NOT_A_CMD` here"
FIX
    # F22b：`bin/` 下的**干净**件（阴性对照：扫 `bin/` 不许凭空制造红）
    cat > "$fix/bin/F22b-bin-clean.sh" <<'FIX'
echo "bin clean: $(printf '%s' ok)"
FIX
    # F23：`D-G114` 的**泄漏形状** —— 前面一行 `if [[ ${#arr[@]} -gt 0 ]]`（`${#…}` 把 `b` 帧漏在栈顶），
    #   后面一行**真的**双引号内裸反引号 ⇒ 旧件 `PASS traps=0`（**假绿**），新件必须红。
    cat > "$fix/sub/F23-brace-leak-dq.sh" <<'FIX'
arr=(1 2)
if [[ ${#arr[@]} -gt 0 ]]; then :; fi
echo "leak probe: `D_G114_NOT_A_CMD` end"
FIX
    # F23b：同一段文字的**中和形态**（裸反引号换成 `$( )`）⇒ 必须绿（成对阴性对照）
    cat > "$fix/sub/F23-leak-neutral.sh" <<'FIX'
arr=(1 2)
if [[ ${#arr[@]} -gt 0 ]]; then :; fi
echo "leak probe: $(printf '%s' D_G114_NEUTRAL) end"
FIX
    # ── `D-G120`（`#65` W152A）新增夹具 5 件（**只增不减**；三条阴性 / 两条阳性成对）───────────
    # ⚠️ 夹具一律**纯 ASCII**（`col` 按字节算；夹中文会把列号算偏）。
    # F24：**真现场形状**（`#64` 落地 `BASELINE-RATE-GATE` 时咬到的那一行）：注释插在续行中间。
    cat > "$fix/sub/F24-continuation-comment.sh" <<'FIX'
# D-G120: a comment inserted in the middle of a backslash continuation (the real shape)
printf '%s\n' A \
    # D_G120_CONTINUATION_COMMENT_INSERTED
    B \
    C
FIX
    # F24b：**正极性对照**（P2 形状）—— 注释块挪到 `printf` 语句**之前** ⇒ 必须绿
    cat > "$fix/sub/F24b-comment-before.sh" <<'FIX'
# D-G120 fix: the comment block moved BEFORE the statement (outside the continuation)
printf '%s\n' A \
    B \
    C
FIX
    # F24c：**防假红①**（P4 形状）—— 行尾 `\` 在**单引号串**里 ⇒ 不是续行 ⇒ 那一行 `#` 是字符串内容
    cat > "$fix/sub/F24c-squote-continuation.sh" <<'FIX'
s='canary_like_squote\
# this hash is inside single quotes, NOT a comment
'
printf '%s\n' "$s"
FIX
    # F24d：**防假红②**（P5 形状）—— `\\`（双反斜杠结尾）不是续行 ⇒ 下一行是**正常注释**
    cat > "$fix/sub/F24d-double-backslash.sh" <<'FIX'
echo X \\
# this is a normal comment line (the backslash above was escaped)
echo Y
FIX
    # F24e：**防假绿②**（P6 形状）—— `$( )` **内部**的续行里插注释 ⇒ 同样是真陷阱（真跑 V=[a]）
    cat > "$fix/sub/F24e-cmdsub-continuation-comment.sh" <<'FIX'
v="$(printf '%s' a \
    # D_G120_CONTINUATION_COMMENT_IN_CMDSUB
    b)"
printf '%s\n' "$v"
FIX
    printf 'x=1\n' > "$fix/build/MilBridge/tools/gate.sh"
    printf 'y=2\n' > "$fix/verify-all.sh"
    # 只看子集：夹具单独成树，用 QT_ANCHORS=off 跑（锚断言另有 S15/S16 两例专测）
    rm -rf "$sb/only"; mkdir -p "$sb/only"

    one() {  # one <编号> <期望rc> <树根> <anchors> <必须出现的正则> [<必须不出现的正则>] [额外env...]
        total=$((total + 1))
        local id="$1" want="$2" root="$3" anch="$4" must="$5" mustnot="${6:-}" out rc ok=1 key
        shift 6 2>/dev/null || shift $#
        out="$( ( cd "$sb" && env "$@" QT_ROOT="$root" QT_ANCHORS="$anch" bash "$SELF" 2>&1 ) )"; rc=$?
        key="$(printf '%s\n' "$out" | grep -E '^SHELL_QUOTE_TRAP=' | head -1)"
        [ "$rc" = "$want" ] || ok=0
        if [ -n "$must" ] && ! grep -qE "$must" <<< "$out"; then ok=0; fi
        if [ -n "$mustnot" ] && grep -qE "$mustnot" <<< "$out"; then ok=0; fi
        if [ "$ok" = 1 ]; then
            pass=$((pass + 1)); say "SELFTEST CASE $id = PASS rc=$rc  $key"
        else
            fail=$((fail + 1))
            say "SELFTEST CASE $id = FAIL rc=$rc want=$want must='$must' mustnot='$mustnot'  $key"
            printf '%s\n' "$out" | sed 's/^/      | /'
        fi
    }
    # 每次只留一件夹具 ⇒ 用单件树
    onefile() {  # onefile <编号> <期望rc> <夹具相对路径> <必须> [<必须不出现>] [extra env...]
        local id="$1" want="$2" rel="$3" must="$4" mustnot="${5:-}"
        shift 5 2>/dev/null || shift $#
        rm -rf "$sb/only"; mkdir -p "$sb/only/$(dirname "$rel")"
        cp -p "$fix/$rel" "$sb/only/$rel"
        one "$id" "$want" "$sb/only" off "$must" "$mustnot" "$@"
    }

    # 正极性（★ 已实测的经验：这三个真现场就是这一形状）
    onefile S01-trap-dquote        1 "sub/F01-trap-dquote.sh"        'SHELL_QUOTE_HIT kind=DQ-BACKTICK file=sub/F01-trap-dquote\.sh line=1 col=9'
    # ★ 最关键的阴性对照：单引号里是**字面量**
    onefile S02-squote-literal     0 "sub/F02-squote.sh"             '^SHELL_QUOTE_TRAP=PASS' 'SHELL_QUOTE_HIT'
    onefile S03-escaped-literal    0 "sub/F03-escaped.sh"            '^SHELL_QUOTE_TRAP=PASS' 'SHELL_QUOTE_HIT'
    onefile S04-dollarparen-legal  0 "sub/F04-cmdsub.sh"             '^SHELL_QUOTE_TRAP=PASS' 'SHELL_QUOTE_HIT'
    onefile S05-comment-ignored    0 "sub/F05-comment.sh"            '^SHELL_QUOTE_TRAP=PASS' 'SHELL_QUOTE_HIT'
    # ★ 失明回归：陷阱在**注释之后**必须仍命中（我第一版独立复算器就死在这里）
    onefile S06-after-comment      1 "sub/F06-after-comment.sh"      'file=sub/F06-after-comment\.sh line=2 col=9'
    onefile S07-heredoc-quoted     0 "sub/F07-heredoc-quoted.sh"     '^SHELL_QUOTE_TRAP=PASS' 'SHELL_QUOTE_HIT'
    # ★ 失明回归：陷阱在**加引号的 heredoc 之后**必须仍命中（状态必须复位）
    onefile S08-after-heredoc      1 "sub/F08-after-heredoc.sh"      'file=sub/F08-after-heredoc\.sh line=4 col=9'
    # ★ 失明回归：`1 << 20` **不许**被当 heredoc 而吞掉后续行
    onefile S09-arithmetic-shift   1 "sub/F09-arithmetic-shift.sh"   'file=sub/F09-arithmetic-shift\.sh line=2 col=9'
    # ★ `#31` W31F **加强**（旧件此处期望 `rc=0` + **仅** `DIAG`、且把 `SHELL_QUOTE_HIT` 列为"必须不出现"）：
    #   **未加引号**的 heredoc 体在运行时**真的**做命令替换（成对读数：真跑 stdout 少了那两个反引号、
    #   stderr 多一行 `…: X: 未找到命令`）⇒ 它是**真陷阱** ⇒ 期望由「绿 + 只诊断」升为「**红 + 逐条点名**」。
    #   ⚠️ 这是**加强**（旧件那一档 `rc` 恒 0 ⇒ 这条判据**永远响不了** = 一个真洞），不是放宽。
    onefile S10-heredoc-unquoted   1 "sub/F10-heredoc-unquoted.sh"   'SHELL_QUOTE_HIT kind=HEREDOC-BACKTICK file=sub/F10-heredoc-unquoted\.sh line=2 col=7'
    # 显式豁免标记：绿，但豁免必须**可见**
    onefile S11-allow-marker       0 "sub/F11-allow.sh"              'SHELL_QUOTE_ALLOW kind=DQ-BACKTICK file=sub/F11-allow\.sh line=2' 'SHELL_QUOTE_HIT'
    # 双引号内 $( … ) 里的反引号：合法
    onefile S12-dq-cmdsub-inner    0 "sub/F12-dq-cmdsub-inner.sh"    '^SHELL_QUOTE_TRAP=PASS' 'SHELL_QUOTE_HIT'
    # .py 窄族：字符串真的交给 shell ⇒ 红
    onefile S13-py-shellstring     1 "sub/F13-py-shellstring.py"     'SHELL_QUOTE_HIT kind=PY-SHELLSTRING file=sub/F13-py-shellstring\.py line=2'
    # .py 文档串：只诊断，绝不判红（否则现场 1481 行全是假红）
    onefile S14-py-docstring       0 "sub/F14-py-docstring.py"       'SHELL_QUOTE_DIAG kind=PY-BACKTICK-FILE file=sub/F14-py-docstring\.py lines=1' 'SHELL_QUOTE_HIT'

    # ── `#31` W31F 新增 7 例（**只增不减**）────────────────────────────────────────────
    # ★ S23 = 本趟那 18 条假红的**真形状**：单引号定界的 heredoc 在 `"$( … )"` 内部
    #   ⇒ 体是字面文本 ⇒ 必须绿（旧件在这里红 18 条 = **假红**）
    onefile S23-dq-cmdsub-heredoc-quoted   0 "sub/F15-dq-cmdsub-heredoc.sh" '^SHELL_QUOTE_TRAP=PASS' 'SHELL_QUOTE_HIT|SHELL_QUOTE_DIAG kind=HEREDOC'
    # ★ S24 = 极性成对：**同样的引号形状、没有 heredoc**，反引号**真的**替换 ⇒ 必须红
    #   （旧件在这一档 **0 命中** = **假阴性**；真跑证据见报告 §4）
    onefile S24-dq-cmdsub-implicit         1 "sub/F16-dq-cmdsub-implicit.sh" 'SHELL_QUOTE_HIT kind=DQ-BACKTICK file=sub/F16-dq-cmdsub-implicit\.sh line=1 col=24'
    # ★ S25/S26 = 历史真陷阱①（`seg-instrument.sh:164` 等价原文）成对：原文必红、『』 必绿
    #   S25 钉「首条命中的 file:line:col」，S25b 钉**条数**（那一行有 3 处替换 ⇒ 6 个反引号）
    onefile S25-hist-seg-raw               1 "sub/F17-hist-seg-raw.sh"       'SHELL_QUOTE_HIT kind=DQ-BACKTICK file=sub/F17-hist-seg-raw\.sh line=1 col=18'
    onefile S25b-hist-seg-raw-count        1 "sub/F17-hist-seg-raw.sh"       'SHELL_QUOTE_TRAP=FAIL reason=dq-backtick traps=6 '
    onefile S26-hist-seg-neutral           0 "sub/F18-hist-seg-neutral.sh"   '^SHELL_QUOTE_TRAP=PASS' 'SHELL_QUOTE_HIT'
    # ★ S27/S28 = 历史真陷阱②（`run-wpfprobe.sh:948` 等价原文）成对：原文必红、『』 必绿
    onefile S27-hist-probe-raw             1 "sub/F19-hist-probe-raw.sh"     'SHELL_QUOTE_HIT kind=DQ-BACKTICK file=sub/F19-hist-probe-raw\.sh line=2 col=88'
    onefile S28-hist-probe-neutral         0 "sub/F20-hist-probe-neutral.sh" '^SHELL_QUOTE_TRAP=PASS' 'SHELL_QUOTE_HIT'
    # ★ S29 = **盲区回归**：混排引号那一行（旧件在此卡进 `S` 态、其后 201 行全盲）之后
    #   紧邻的陷阱必须仍被抓到（旧件实测：种一条 ⇒ 0 命中）
    onefile S29-blind-range-regress        1 "sub/F21-blind-range-regress.sh" 'SHELL_QUOTE_HIT kind=DQ-BACKTICK file=sub/F21-blind-range-regress\.sh line=2 col=9'

    # ── `#60` W152A 新增 5 例（`TASK-0713` 射程 3 例 ＋ `D-G114` 泄漏 2 例；**只增不减**）────
    # S30 = `bin/` 下的真陷阱**必须红**（`TASK-0713`；**旧件在这一档 `PASS traps=0` = 假绿**）
    onefile S30-bin-trap-must-fire          1 "bin/F22-bin-trap.sh"     'SHELL_QUOTE_HIT kind=DQ-BACKTICK file=bin/F22-bin-trap\.sh line=1 col=17'
    # S31 = 射程**必须可见**：`QUOTE_TRAP_SCOPE` 行必须在，且逐字声明 `bin=INCLUDED`
    onefile S31-scope-visible               1 "bin/F22-bin-trap.sh"     '^QUOTE_TRAP_SCOPE .*bin=INCLUDED .*excluded='
    # S32 = 阴性对照：`bin/` 下的**干净**件 ⇒ 不许因为"扫了 bin"就多红
    onefile S32-bin-clean-no-red            0 "bin/F22b-bin-clean.sh"   '^SHELL_QUOTE_TRAP=PASS' 'SHELL_QUOTE_HIT'
    # ★ S33 = `D-G114` 泄漏**必须已修**（**旧件这一档 `PASS traps=0` = 假绿**：一行 `${#…}` 把整份文件的判据闭掉）
    onefile S33-brace-leak-must-fire        1 "sub/F23-brace-leak-dq.sh" 'SHELL_QUOTE_HIT kind=DQ-BACKTICK file=sub/F23-brace-leak-dq\.sh line=3 col=19'
    # ★ S34 = 泄漏的**成对阴性对照**：同一段文字换成 `$( )` ⇒ 必须绿
    onefile S34-brace-leak-neutral          0 "sub/F23-leak-neutral.sh" '^SHELL_QUOTE_TRAP=PASS' 'SHELL_QUOTE_HIT'

    # ── `D-G120`（`#65` W152A）新增 6 例（**只增不减**；阳性 3 / 阴性 3，成对）────────────────
    # ★ S35/S35b = **真现场形状**必红，并**逐字点名** `#` 那一行（`line=3 col=5`）；S35b 钉**条数**
    onefile S35-continuation-comment        1 "sub/F24-continuation-comment.sh" 'SHELL_QUOTE_HIT kind=CONTINUATION-COMMENT file=sub/F24-continuation-comment\.sh line=3 col=5'
    onefile S35b-continuation-comment-count 1 "sub/F24-continuation-comment.sh" 'SHELL_QUOTE_TRAP=FAIL reason=continuation-comment traps=1 '
    # ★ S36 = **反极性对照**：同一段文字，注释块移到语句**之前** ⇒ 必须绿（否则判的就是"文本相邻"）
    onefile S36-comment-before-statement   0 "sub/F24b-comment-before.sh" '^SHELL_QUOTE_TRAP=PASS' 'SHELL_QUOTE_HIT'
    # ★ S37/S38 = **防假红**：单引号串里的行尾 `\` ／ `\\`（双反斜杠）都不是续行 ⇒ 必须绿
    onefile S37-squote-not-continuation    0 "sub/F24c-squote-continuation.sh" '^SHELL_QUOTE_TRAP=PASS' 'SHELL_QUOTE_HIT'
    onefile S38-double-backslash-not-cont  0 "sub/F24d-double-backslash.sh" '^SHELL_QUOTE_TRAP=PASS' 'SHELL_QUOTE_HIT'
    # ★ S39 = **防假绿**：`$( )` 内部的同形状**同样是真陷阱** ⇒ 必须红
    onefile S39-cmdsub-continuation-comment 1 "sub/F24e-cmdsub-continuation-comment.sh" 'SHELL_QUOTE_HIT kind=CONTINUATION-COMMENT file=sub/F24e-cmdsub-continuation-comment\.sh line=2 col=5'

    # 三态：取不到件 / 树不存在 / 锚件不在件集
    rm -rf "$sb/emptyroot"; mkdir -p "$sb/emptyroot"
    one S15-scan-empty      2 "$sb/emptyroot" off 'reason=scan-empty'
    one S16-root-missing    2 "$sb/no-such-root" off 'reason=root-missing'
    # strict 锚断言：有 .sh 但没有 verify-all.sh ⇒ NOINFO（不是绿）
    rm -rf "$sb/noanchor"; mkdir -p "$sb/noanchor/sub"
    cp -p "$fix/sub/F02-squote.sh" "$sb/noanchor/sub/"
    one S17-anchor-missing  2 "$sb/noanchor" strict 'reason=scan-definition-broken'
    # ★ 扫描器失明 ⇒ 必须 NOINFO，**不许** PASS（本件最重要的一条反极性）
    rm -rf "$sb/goodtree"; cp -rp "$fix" "$sb/goodtree"
    one S18-blind-canary    2 "$sb/goodtree" off 'reason=canary-blind' '' QT_TEST_BLIND=1
    # 同一棵树上不弄瞎 ⇒ 必须红（成对读数：证明 S18 的 NOINFO 只来自"弄瞎"）
    one S19-blind-pair      1 "$sb/goodtree" off 'SHELL_QUOTE_HIT'

    # 纪律 63：临时件必须落在**本沙箱的 TMPDIR** 下，且共享 /tmp 不留痕
    dtmp="$( ( cd "$sb" && QT_ROOT="$fix" QT_ANCHORS=off bash "$SELF" --debug-tmp 2>&1 ) \
            | sed -n 's/^QT_TMP_DIR=//p' | head -1)"
    total=$((total + 1))
    case "$dtmp" in
        "$TMPBASE"/*) pass=$((pass + 1)); say "SELFTEST CASE S20-tmpdir = PASS 临时目录=$dtmp（在 \$TMPDIR=$TMPBASE 之下）" ;;
        *) fail=$((fail + 1)); say "SELFTEST CASE S20-tmpdir = FAIL 临时目录='$dtmp' 不在 \$TMPDIR=$TMPBASE 之下" ;;
    esac
    rm -rf "$dtmp" 2>/dev/null
    tmp_after="$(find /tmp -maxdepth 1 \( -name 'shell-quote-trap.*' -o -name 'qt-selftest.*' \) 2>/dev/null | LC_ALL=C sort)"
    total=$((total + 1))
    if [ "$tmp_before" = "$tmp_after" ]; then
        pass=$((pass + 1)); say "SELFTEST CASE S21-no-tmp-leak = PASS 共享 /tmp 上 shell-quote-trap.*/qt-selftest.* 开工==收工"
    else
        fail=$((fail + 1)); say "SELFTEST CASE S21-no-tmp-leak = FAIL 共享 /tmp 有新痕 before=[$tmp_before] after=[$tmp_after]"
    fi
    # 反极性总闸：S18 与 S19 是**成对**的（同一棵树，只换"弄瞎"开关）
    total=$((total + 1))
    if [ "$fail" -eq 0 ]; then
        pass=$((pass + 1)); say "SELFTEST CASE S22-pair = PASS 同一棵树：弄瞎 ⇒ NOINFO / 不弄瞎 ⇒ FAIL（金丝雀是活的）"
    else
        fail=$((fail + 1)); say "SELFTEST CASE S22-pair = FAIL 见上面明细"
    fi

    say "SELFTEST_SANDBOX=$sb"
    if [ "$fail" -eq 0 ]; then
        say "SELFTEST=PASS total=$total pass=$pass fail=$fail"
        rm -rf "$sb"; return 0
    fi
    say "SELFTEST=FAIL total=$total pass=$pass fail=$fail（沙箱保留供诊断）"
    return 1
}

# ── 入口 ─────────────────────────────────────────────────────────────────────
while [ "$#" -gt 0 ]; do
    case "$1" in
        --root)      ROOT="$2"; shift 2 ;;
        --anchors)   ANCHOR_MODE="$2"; shift 2 ;;
        --debug-tmp) KEEP_TMP=1; shift ;;
        --list-files) LIST_ONLY=1; shift ;;
        --selftest)  run_selftest; exit $? ;;
        -h|--help)   usage; exit 0 ;;
        *)           say "unknown-arg: $1"; usage; exit 2 ;;
    esac
done

if [ "${LIST_ONLY:-0}" = 1 ]; then
    TMPD_L="$(mktemp -d "${TMPDIR:-/tmp}/shell-quote-trap.XXXXXX")"
    collect_lists "$TMPD_L"
    say "FILES=$FILES_N sh=$SH_N py=$PY_N"
    cat "$TMPD_L/all.list"
    rm -rf "$TMPD_L"
    exit 0
fi

if [ "$KEEP_TMP" = 1 ]; then
    run_check; rc=$?
    [ -n "$TMP_DIR_USED" ] && say "QT_TMP_DIR=$TMP_DIR_USED"
    exit "$rc"
fi

run_check
exit $?
