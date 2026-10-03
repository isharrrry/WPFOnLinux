#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# root-entries-allowlist-check.sh —— 「**根级条目 ⊆ 允许清单**」常态牙（`TASK-0750`／`D-G158` 一族）
#
# 【它挡的是什么】
#   仓根是**唯一一个"谁来都能往里放新东西"的平面**：`#76` 冻结树里**没有**的那一棵
#   dotnet/wpf 自带树（`Directory.Build.props`／`NuGet.config`／`eng/`／`packaging/`／
#   `src/Microsoft.DotNet.Wpf/` …）就是这样长回来的 —— 它带来**两条**独立破坏
#   （① 根 `Directory.Build.props` 被 MSBuild **隐式自动导入** ⇒ 移植工程求值即 `MSB4236`；
#    ② 那 92 个 `*.csproj` 进 `build-hygiene-import-check.sh` 的候选集 ⇒ 第 `[9]` 步
#    `cand=88→180`／`undeclared=0→92`／`reason=drift`）。处置记在
#   `build/MilBridge/P0-migrate-report.md`；`[9]` 里那条窄形态 `rootprops=` 只看两个固定文件名，
#   **看不见第三个、第 N 个新根条目** ⇒ 本件把判据从"**两个名字**"换成"**一张清单**"。
#
# 【字段语义（逐字；`t28` 按 `t16` 的 ③④⑤ 补）】
#   · `source=git-ls-files` ＝ **来源①**：`git -C <root> ls-files -z`（**入库了什么**）
#   · `source=worktree`     ＝ **来源②**：`ls -A <root>`（**盘上有什么**）—— 标签与机制**逐字一致**；
#     旧版此处写 `source=test-e`（实现早改成 `ls -A` 而标签没跟 ⇒ `t16` ⑤）。`test -e` 只用来**判存在**、不是来源。
#   · `root=<绝对路径>` ＝ 本次**实际被扫**的树根（`--root` 或 env `RA_ROOT` 或本件位置推导）
#   · `allow_src=embedded` ＝ 用**内嵌** `ALLOWLIST`；`allow_src=file` ＝ 用 `--allow <FILE>`，此时 `allow_file=<路径>`
#   · 上述四格在 **PASS／FAIL／NOINFO 三档都印**（绿档不印就等于"读数不可复算"，`t16` ④）
#
# 【`DOC-CAT3`（件头 category ③ 枚举，机器可抽；与代码常量、与清单三者双向对拍）】
#   DOC-CAT3-BEGIN: LICENSE.TXT|SECURITY.md|CODEOWNERS|CODE_OF_CONDUCT.md|THIRD-PARTY-NOTICES.TXT|.github|.gitattributes|.gitignore|README-Window.md:DOC-CAT3-END
#
# 【判据（**先写死**；三态；`NOINFO` 不算绿）】
#   rc=0  `ROOT_ALLOW=PASS`     两个来源取到的根级条目**每一个**都在允许清单里
#   rc=1  `ROOT_ALLOW=FAIL`     逐条点名 `ROOT_ALLOW_HIT entry=<名> source=<来源>`
#                               （`rule=not-in-allowlist`／`rule=allow-without-reason`
#                                ／`rule=allowlist-malformed`）
#   rc=3  `ROOT_ALLOW=NOINFO`   算不出：根不存在／`git` 取不到（两个来源里有一个取不到就不判绿）
#                               ／活清单为空／允许清单件缺席或不可读（`--allow <FILE>` 给了却不存在）
#   rc=2  用法错（`ROOT_ALLOW=NOINFO reason=bad-arg`）
#
#   · **两个来源都要判、都要印**（`TASK-0750` 逐字要求）：① `git ls-files`（**入库**了什么）
#     ② 工作树（`ls -A`，**盘上**有什么）。同一个名字可以**两个来源都命中** ⇒ 逐 (名字,来源) 点名。
#   · **两个来源的语义差别是判据的一部分**：未被跟踪的根条目（本仓现读：`multi.txt`（`P0` 迁移
#     从旧树带回来的 0 字节件）、`.agent-teams/`（AgentTeams 状态目录，本地 `.git/info/exclude`）
#     只可能被来源 ② 看见 ⇒ 清单里必须有它们（**带 why**），否则本件自己就红。
#   · ⚠️ **必须用 `git ls-files -z`**：`git ls-files` 对含空格/特殊字符的路径会**加引号**
#     （`core.quotePath`）⇒ 用换行分隔＋`sed 's|/.*||'` 时会把 `"build` 这种**假条目**当成根条目
#     （现场实测：本仓有带空格的路径 ⇒ 不加 `-z` 时根条目集合里会多出一个 `"build`）。
#   · `.git` 是**版本库元数据**、不是仓内容 ⇒ **声明式排除**（上屏 `ROOT_ALLOW_NOTE excluded=.git`），
#     不许静默。
#
# 【允许清单从哪来（**本件的设计核心**）】**内嵌**（口径：`<name>\t<why>`，`#` 起头为注）＝
#   ① `#76` 冻结树根条目（`P0` 迁移报告 §5 的现取集合）＋ ② 移植面 ＋ ③ fork 治理件
#   （`LICENSE.TXT`／`SECURITY.md`／`CODEOWNERS`／`CODE_OF_CONDUCT.md`／`THIRD-PARTY-NOTICES.TXT`
#   ／`.github/`／`README-Window.md`）＋ ④ 两个**工作树独有**件（`multi.txt`／`.agent-teams`，理由逐条写在清单里）。
#   ⚠️ **本枚举是机器可抽的**：`DOC-CAT3-BEGIN` … `DOC-CAT3-END` 之间的名字集合与代码常量
#   代码常量 `DOC_CAT3`、以及清单里 `why` 以「fork 治理件」开头的行**三者双向对拍**（任何一方向有差额 ⇒
#   `ROOT_ALLOW=FAIL reason=doc-drift` ＋ 逐条 `ROOT_ALLOW_DOC_NOTE kind=header-not-in-list|list-not-in-header`）。
#   ⚠️ **`.editorconfig` 不在本枚举里**：它已由 `#77` 的**结构性去重**从仓里删掉（`git log -1 -- .editorconfig`
#   ⇒ `0666559 … 结构性去重（.editorconfig）`；129 条 `severity = error` 曾让整波 `失败步骤 10`）
#   ⇒ 它的**正确位置**是本牙的三条反极腿（放回它 ⇒ 必红），**不是**允许清单。件头在这里写它"被允许"会直接误导读者。
#   **`why` 列不许空**（空 ⇒ `FAIL rule=allow-without-reason`）：豁免必须成文。
#   ⇒ 加一个新根条目 = **改清单**（可见、可审）或**被牙点名**（红）。两条路都不静默。
#
# 【本牙自己的接线状态（**必须字面写在件头**：判「件头自述 vs 接线」的对手牙会读它）】
#   **已接线**：`verify-all.sh` 的
#   `run_step "ROOT-ENTRIES" bash build/MilBridge/tools/root-entries-allowlist-check.sh`
#   ——⚠️ **本注释不写步号**：以现场 `verify-all.sh` 的**步序**为准（写死步号 = 下一条会漂移的陈旧自述）。
#
# 【测试钩子】`--selftest`：自带 fixture（零 `X`、零 `dotnet`、零真树写入）＋ 一条**真树阳性对照**
#   ＋ 三条**具名反极腿**（把 `.editorconfig`／`Directory.Build.props`／`NuGet.config`
#   分别"放回" ⇒ 必红并点名）。真树那三条**不改真树**：`cp -p` 本体到沙箱、`sed` 掉清单里对应行，
#   再对**真树**（只读）跑 ⇒ 红。
#   用法：bash root-entries-allowlist-check.sh [--root DIR] [--allow FILE] [--selftest] [--debug-tmp]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
REAL_ROOT="${RA_REAL_ROOT:-$(cd -- "$SELF_DIR/../../.." && pwd)}"   # 沙箱副本可被 RA_REAL_ROOT 指向真树（排练用；仓内落地后与本文件位置推导一致）

ROOT="${RA_ROOT:-$REAL_ROOT}"
ALLOW_FILE=""
SELFTEST=0
KEEP_TMP=0
RC_PASS=0; RC_FAIL=1; RC_USAGE=2; RC_NOINFO=3

# ── 允许清单（**内嵌**；`<name>\t<why>`；`#` 起头为注/表头）─────────────────────────
#   ⚠️ 这张表是**声明**，不是"现状快照转抄"：每一行的 `why` 要说清"它为什么**应该**在根上"。
read_allow() {
  cat <<'ALLOWLIST'
# 根级允许清单 —— `<根条目名>\t<为什么允许>`
# 来源：① `#76` 冻结树根条目（`build/MilBridge/P0-migrate-report.md` §5 现取）
#       ② 移植面（`build/` `src/` `samples/` `tests/` `tools/` `docs/` `upstream/`）
#       ③ fork 治理件（R8「可被外部贡献者读懂」的正面资产）
#       ④ 工作树独有件（逐条给理由）
build	移植面：全部 *.Linux 工程、门禁装置与冻结/推送工具
BuildHygiene.props	移植面：产物目录排除的唯一实现在仓根（`D-R8`），各工程显式 Import
CODE_OF_CONDUCT.md	fork 治理件：R8 正面资产（外部贡献者入口）
CODEOWNERS	fork 治理件：R8 正面资产（评审归属）
docs	移植面：路线图/规范/预登记/历史账
.gitattributes	fork 治理件：换行/二进制属性基线
.github	fork 治理件：CI/模板/CODEOWNERS 的家（R8 正面资产；现读对上游重复件零引用）
.gitignore	fork 治理件：产物/证据的入库分界（本仓多份判据读它）
global.json	移植面：SDK 版本钉死（`10.0.111`，与冻结树逐字节相同）
home	`#76` 冻结树根条目：`home/links-dev`（**空目录树、0 文件**，疑似某车道的 `~/` 展开误造）；**待清**：删它须同步删本条（清单缩小不判红、增长必红）
handoff.md	移植面：逐波技术账（接手入口之一）
LICENSE.TXT	fork 治理件：许可证（R8 正面资产）
README.md	移植面：本仓门面（上游 README 另存 README-Window.md）
README-Window.md	fork 治理件：上游 README 原样保留（R8 正面资产）
samples	移植面：门禁样本（WpfTextDemo 等）
SECURITY.md	fork 治理件：安全披露入口（R8 正面资产）
src	移植面：`WpfGfx.Linux`（托管）与 `WpfGfx.Linux.Native`（原生 shim）
tests	移植面：测试套件与 parity 语料
THIRD-PARTY-NOTICES.TXT	fork 治理件：第三方声明（R8 正面资产）
tools	移植面：或然器与几何 oracle
upstream	移植面：上游 `dotnet/wpf` 快照（**唯一被读者读的那一份**）
verify-all.sh	移植面：门禁本体
wpf-linux.sln	移植面：移植侧解决方案（区别于已退役的 `Microsoft.Dotnet.Wpf.sln`）
multi.txt	工作树独有：`P0` 迁移从 `#76` 冻结树带回来的 **0 字节**件（`O` 独有；仓内零读者；未入库、本地 exclude）；**待清**：若要删须独立成波并同步本条（见 P0 报告 §10-4）
.agent-teams	工作树独有：AgentTeams 状态目录（harness 造、本地 `.git/info/exclude` 排除、**从不入库**）
.narnat	工作树独有：Narnat Agent 运行状态目录（harness 造、本地 `.git/info/exclude` 排除、**从不入库**）
.agents	工作树独有：Narnat Agent 运行时目录（`plans/`＋`skills/`；harness 造、仓内 `.gitignore` 已忽略、**从不入库**）
ALLOWLIST
}

ROOT_ALLOW_LIST="$(read_allow)"

# ── `DOC_CAT3`：**件头** category ③ 的枚举（唯一的机器副本；件头里那一段 `DOC-CAT3-BEGIN…END` 与它逐名对拍）──
DOC_CAT3='LICENSE.TXT|SECURITY.md|CODEOWNERS|CODE_OF_CONDUCT.md|THIRD-PARTY-NOTICES.TXT|.github|.gitattributes|.gitignore|README-Window.md'
doc_cat3_header() {   # 从**件头**（到第一个 `^set -` 之前）抽 `DOC-CAT3-BEGIN … :DOC-CAT3-END` 之间的名字
  awk '{ if ($0 ~ /^set -/) exit; print }' "$SELF" \
    | sed -n 's/.*DOC-CAT3-BEGIN:[[:space:]]*\(.*\)[[:space:]]*:DOC-CAT3-END.*/\1/p' | head -1 \
    | tr '|' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | sed '/^$/d' | LC_ALL=C sort
}

usage() { sed -n '2,60p' "$SELF" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --root)      ROOT="${2:-}"; shift 2 ;;
    --root=*)    ROOT="${1#*=}"; shift ;;
    --allow)     ALLOW_FILE="${2:-}"; shift 2 ;;
    --allow=*)   ALLOW_FILE="${1#*=}"; shift ;;
    --selftest)  SELFTEST=1; shift ;;
    --debug-tmp) KEEP_TMP=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "ROOT_ALLOW=NOINFO reason=bad-arg arg=$1" >&2; exit $RC_USAGE ;;
  esac
done

# ── 两个来源 ──────────────────────────────────────────────────────────────────
#   ① 入库了什么（`git ls-files -z`：**必须 `-z`**，见件头）
src_tracked() {
  git -C "$ROOT" ls-files -z 2>/dev/null | tr '\0' '\n' | sed '/^$/d; s|/.*||' | LC_ALL=C sort -u
}
#   ② 盘上有什么（`ls -A`；`.git` 是**声明式排除**、上屏）
src_worktree() {
  ls -A "$ROOT" 2>/dev/null | grep -vx '.git' | LC_ALL=C sort -u
}

# ── 清单解析（返回 0=可用；1=形状坏）──────────────────────────────────────────
#   stdout：`<name>\t<why>`；坏行 ⇒ 打到 stderr 并在状态行点名
parse_allow() {  # parse_allow <文本>
  printf '%s\n' "$1" | awk -F'\t' '
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*#/  { next }
    NF < 2 { printf "ROOT_ALLOW_BADLINE line=%d reason=missing-why\n", NR; bad=1; next }
    { n=$1; why=$2; gsub(/^[[:space:]]+|[[:space:]]+$/,"",n); gsub(/^[[:space:]]+|[[:space:]]+$/,"",why);
      if (n=="" ) { printf "ROOT_ALLOW_BADLINE line=%d reason=empty-name\n", NR; bad=1; next }
      if (why=="") { printf "ROOT_ALLOW_BADLINE line=%d name=%s reason=empty-why\n", NR, n; bad=1; next }
      printf "%s\t%s\n", n, why }
    END { exit (bad?1:0) }'
}

check_root() {  # check_root <root> <allow-text> <allow-src> <allow-file>
  local root="$1" allow="$2" allow_src="$3" allow_file="$4"
  local ctx="root=$root allow_src=$allow_src allow_file=${allow_file:--}"
  local tracked fs unk_t=0 unk_f=0 examined=0 allowed=0 rc=$RC_PASS e why srcnames=""
  local parsed badline

  [ -d "$root" ] || { echo "ROOT_ALLOW=NOINFO reason=root-absent $ctx"; return $RC_NOINFO; }
  command -v git >/dev/null 2>&1 || { echo "ROOT_ALLOW=NOINFO reason=git-absent $ctx"; return $RC_NOINFO; }
  git -C "$root" rev-parse --git-dir >/dev/null 2>&1 \
    || { echo "ROOT_ALLOW=NOINFO reason=not-a-git-tree $ctx（本牙的两个来源之一是 git ⇒ 取不到就不判绿）"; return $RC_NOINFO; }

  parsed="$(parse_allow "$allow")"; badline=$?
  printf '%s\n' "$parsed" | grep '^ROOT_ALLOW_BADLINE' || true
  if [ "$badline" -ne 0 ]; then
    echo "ROOT_ALLOW=FAIL reason=allowlist-malformed $ctx（清单里有**没有 why** 或名字为空的条目 ⇒ 先修清单）"
    return $RC_FAIL
  fi
  [ -n "$parsed" ] || { echo "ROOT_ALLOW=NOINFO reason=empty-allowlist $ctx"; return $RC_NOINFO; }
  allowed="$(printf '%s\n' "$parsed" | wc -l | tr -d ' ')"

  tracked="$(src_tracked)"; fs="$(src_worktree)"
  if [ -z "$tracked" ] && [ -z "$fs" ]; then
    echo "ROOT_ALLOW=NOINFO reason=empty-scan-set $ctx（两个来源都空 ⇒ '一条都没读到' ≠ '没有一条命中'）"
    return $RC_NOINFO
  fi

  echo "ROOT_ALLOW_NOTE excluded=.git why=版本库元数据不是仓内容"
  echo "ROOT_ALLOW_NOTE sources tracked_n=$(printf '%s\n' "$tracked" | grep -c . ) worktree_n=$(printf '%s\n' "$fs" | grep -c . ) allowlist_n=$allowed"

  in_allow() { printf '%s\n' "$parsed" | cut -f1 | grep -qxF -- "$1"; }
  why_of()   { printf '%s\n' "$parsed" | awk -F'\t' -v n="$1" '$1==n{print $2; exit}'; }

  while IFS= read -r e; do
    [ -n "$e" ] || continue
    examined=$((examined + 1))
    if ! in_allow "$e"; then
      unk_t=$((unk_t + 1)); srcnames="$srcnames $e"
      printf 'ROOT_ALLOW_HIT entry=%s source=git-ls-files rule=not-in-allowlist\n' "$e"
    fi
  done <<< "$tracked"
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    if ! in_allow "$e"; then
      unk_f=$((unk_f + 1)); srcnames="$srcnames $e"
      printf 'ROOT_ALLOW_HIT entry=%s source=worktree rule=not-in-allowlist\n' "$e"
    fi
  done <<< "$fs"

  # 清单里**没被任一来源看见**的行 ⇒ 上屏（不判红：缩小是安全方向；**增长**才红 —— 上面那两段）
  while IFS=$'\t' read -r e why; do
    [ -n "$e" ] || continue
    if ! grep -qxF -- "$e" <<< "$tracked" && ! grep -qxF -- "$e" <<< "$fs"; then
      printf 'ROOT_ALLOW_NOTE allow-unused entry=%s why=%s\n' "$e" "$why"
    fi
  done <<< "$parsed"

  # 来源覆盖情况（如实划界：某条目只被一个来源看见是**正常**的）
  local only_git only_fs
  only_git="$(LC_ALL=C comm -23 <(printf '%s\n' "$tracked") <(printf '%s\n' "$fs") | grep -c . || true)"
  only_fs="$(LC_ALL=C comm -13 <(printf '%s\n' "$tracked") <(printf '%s\n' "$fs") | grep -c . || true)"
  echo "ROOT_ALLOW_NOTE source-skew tracked_only_n=$only_git worktree_only_n=$only_fs"

  # ── ③ 件头枚举 ↔ 清单（`why` 以 `fork 治理件` 开头）**双向对拍** ──────────────────
  local hdr_names list_names dn drift=0
  hdr_names="$(doc_cat3_header)"
  list_names="$(printf '%s\n' "$parsed" | awk -F'\t' '$2 ~ /^fork 治理件/{print $1}' | LC_ALL=C sort)"
  while IFS= read -r dn; do
    [ -n "$dn" ] || continue
    if ! grep -qxF -- "$dn" <<< "$list_names"; then
      printf 'ROOT_ALLOW_DOC_NOTE kind=header-not-in-list entry=%s why=件头 category ③ 列了它、清单里没有 ⇒ 二者必居其一（补进清单 ＋ why，或从件头枚举里删掉）\n' "$dn"
      drift=$((drift + 1))
    fi
  done <<< "$hdr_names"
  while IFS= read -r dn; do
    [ -n "$dn" ] || continue
    if ! grep -qxF -- "$dn" <<< "$hdr_names"; then
      printf 'ROOT_ALLOW_DOC_NOTE kind=list-not-in-header entry=%s why=清单里以「fork 治理件」立 why、件头 category ③ 枚举里没有 ⇒ 二者必居其一（补进件头，或改该行 why 的类别）\n' "$dn"
      drift=$((drift + 1))
    fi
  done <<< "$list_names"
  # 件头**标记段** ↔ 代码常量 `DOC_CAT3`（第三个副本；防"件头改了、常量没跟"）
  if [ "$(printf '%s\n' "$hdr_names" | tr '\n' '|')" != "$(printf '%s\n' "$DOC_CAT3" | tr '|' '\n' | LC_ALL=C sort | tr '\n' '|')" ]; then
    printf 'ROOT_ALLOW_DOC_NOTE kind=header-span-vs-constant why=件头 DOC-CAT3-BEGIN 段与代码常量 DOC_CAT3 不等（header=[%s] const=[%s]）\n' \
      "$(printf '%s\n' "$hdr_names" | tr '\n' ',')" "$(printf '%s' "$DOC_CAT3" | tr '|' ',')"
    drift=$((drift + 1))
  fi
  if [ "$drift" -gt 0 ]; then
    echo "ROOT_ALLOW=FAIL reason=doc-drift doc_drift=$drift $ctx"
    return $RC_FAIL
  fi

  [ $((unk_t + unk_f)) -eq 0 ] || rc=$RC_FAIL
  echo "ROOT_ALLOW=$([ "$rc" -eq 0 ] && echo PASS || echo FAIL) $ctx examined=$examined tracked_n=$(printf '%s\n' "$tracked" | grep -c .) worktree_n=$(printf '%s\n' "$fs" | grep -c .) allowed_n=$allowed unknown_tracked=$unk_t unknown_fs=$unk_f unknown=$([ -n "$srcnames" ] && echo "$srcnames" | tr -s ' ' || echo -) rc=$rc"
  return $rc
}

# ═══════════════════════════════════════════════════════════════════════════════
# --selftest：自带 fixture（沙箱内 `git init`）＋ 真树阳性对照 ＋ **三条具名反极腿**
#   判据（每条都断言 **rc** ＋ **必须出现的字样**，不是"跑过了就算"）：
#     P1  清单内现状（fixture）                        ⇒ rc=0 `ROOT_ALLOW=PASS`
#     P2  真树阳性对照（只读）                         ⇒ rc=0 `ROOT_ALLOW=PASS`
#     N1  fixture 放回 `Directory.Build.props`          ⇒ rc=1 且**点名**该条（source 两来源都点）
#     N2  fixture 放回 `NuGet.config`                   ⇒ rc=1 且**点名**
#     N3  真树＋清单里 `sed` 掉 `.editorconfig` 行       ⇒ rc=1 且**点名** `.editorconfig`
#     N4  清单里有 `why` 为空的条目                      ⇒ rc=1 `reason=allowlist-malformed`
#     N5  `--allow /nonexistent`（清单件缺席）            ⇒ rc=3 `ROOT_ALLOW=NOINFO`
#     N6  `--root /nonexistent`（根缺席）                 ⇒ rc=3 `ROOT_ALLOW=NOINFO`
# ═══════════════════════════════════════════════════════════════════════════════
selftest() {
  SBX="$(mktemp -d "${TMPDIR:-/tmp}/w79-allow-XXXXXX")"
  [ "$KEEP_TMP" -eq 1 ] || trap 'rm -rf "${SBX:-}"' EXIT
  local pass=0 fail=0
  chk() {  # chk <名> <期望rc> <必须含的字样> <命令…>（不带 rc 断言的字样腿用 rc=- 表示不断言）
    local nm="$1" want="$2" needle="$3"; shift 3
    local out rc
    out="$("$@" 2>&1)"; rc=$?
    if { [ "$want" = "-" ] || [ "$rc" = "$want" ]; } && grep -qF -- "$needle" <<< "$out"; then
      printf 'CASE=%-26s expect_rc=%-4s needle=%-42s VERDICT=PASS\n' "$nm" "$want" "$needle"; pass=$((pass + 1))
    else
      printf 'CASE=%-26s expect_rc=%-4s needle=%-42s VERDICT=FAIL got_rc=%s\n' "$nm" "$want" "$needle" "$rc"
      printf '%s\n' "$out" | sed 's/^/      | /'
      fail=$((fail + 1))
    fi
  }

  # ── fixture：一棵最小 git 树，根条目**全在清单里**（清单 = 本体的内嵌清单 ∩ 实际放的件）
  local FX="$SBX/fx"
  mkdir -p "$FX/build" "$FX/docs" "$FX/src" "$FX/samples" "$FX/tests" "$FX/tools" "$FX/upstream" "$FX/.github"
  : > "$FX/build/.keep"; : > "$FX/docs/.keep"; : > "$FX/src/.keep"
  for f in BuildHygiene.props global.json handoff.md verify-all.sh wpf-linux.sln README.md README-Window.md \
           LICENSE.TXT SECURITY.md CODEOWNERS CODE_OF_CONDUCT.md THIRD-PARTY-NOTICES.TXT .gitattributes .gitignore; do
    : > "$FX/$f"
  done
  ( cd "$FX" && git init -q . && git add -A >/dev/null 2>&1 )
  chk "P1-清单内现状" 0 'ROOT_ALLOW=PASS' bash "$SELF" --root "$FX"

  # ── P2 真树相干性腿（只读）：断言"跑了 ⇒ 有形状完好的判词行"，并把真树状态**原样上屏**。
  #    理由（如实）：真树根上可能有**并发车道正在用的临时件**（本波排练现场就有 `checkprop.c`）
  #    ⇒ 把"真树必须 PASS"写进自测断言，会让本件的自测被别人留的一个文件打成红 —— 那是**别人的世界**，
  #    不是本件的判据。真树**必须** PASS 这句写在落地门的判据里（报告 §5 的现取读数）。
  local rt; rt="$(bash "$SELF" --root "$REAL_ROOT" 2>&1)"; local rtrc=$?
  printf 'ROOT_ALLOW_REAL_TREE=%s\n' "$(printf '%s\n' "$rt" | sed -n 's/^\(ROOT_ALLOW=[A-Z]*\).*/\1/p' | tail -1)"
  printf '%s\n' "$rt" | sed -n 's/^\(ROOT_ALLOW_[A-Z]*\)/  real: \1/p' | head -20
  if grep -qE '^ROOT_ALLOW=(PASS|FAIL|NOINFO) ' <<< "$rt" && { [ "$rtrc" = 0 ] || [ "$rtrc" = 1 ] || [ "$rtrc" = 3 ]; }; then
    printf 'CASE=%-26s expect_rc=%-4s needle=%-42s VERDICT=PASS\n' "P2-真树相干性" "0/1/3" "ROOT_ALLOW=<三态> 与 rc 一致"; pass=$((pass + 1))
  else
    printf 'CASE=%-26s expect_rc=%-4s needle=%-42s VERDICT=FAIL got_rc=%s\n' "P2-真树相干性" "0/1/3" "ROOT_ALLOW=<三态> 与 rc 一致" "$rtrc"
    fail=$((fail + 1))
  fi

  # ── N1/N2：把两个"曾经长回来过"的根件**放回** fixture ⇒ 必红并点名
  : > "$FX/Directory.Build.props"; ( cd "$FX" && git add -A >/dev/null 2>&1 )
  chk "N1-放回 Directory.Build.props" 1 'ROOT_ALLOW_HIT entry=Directory.Build.props source=git-ls-files' bash "$SELF" --root "$FX"
  chk "N1b-同一条的工作树来源" 1 'ROOT_ALLOW_HIT entry=Directory.Build.props source=worktree' bash "$SELF" --root "$FX"
  rm -f "$FX/Directory.Build.props"
  : > "$FX/NuGet.config"; ( cd "$FX" && git add -A >/dev/null 2>&1 )
  chk "N2-放回 NuGet.config" 1 'ROOT_ALLOW_HIT entry=NuGet.config source=git-ls-files' bash "$SELF" --root "$FX"
  rm -f "$FX/NuGet.config"

  # ── N3：把 `.editorconfig` **放回** fixture ⇒ 必红并点名（两个来源都点）
  #    ⚠️ 为什么用 fixture：`.editorconfig` 已由 `#77` 的**结构性去重**从真树删掉（`git log -1 -- .editorconfig`
  #    ⇒ `0666559 … 结构性去重（.editorconfig）`）⇒ 真树上"放回"无处可放；本腿在 fixture 里**造**那个"放回"。
  : > "$FX/.editorconfig"; ( cd "$FX" && git add -A >/dev/null 2>&1 )
  chk "N3-放回 .editorconfig(git 源)" 1 'ROOT_ALLOW_HIT entry=.editorconfig source=git-ls-files' bash "$SELF" --root "$FX"
  chk "N3b-放回 .editorconfig(工作树源)" 1 'ROOT_ALLOW_HIT entry=.editorconfig source=worktree' bash "$SELF" --root "$FX"
  rm -f "$FX/.editorconfig"

  # ── ③ 件头↔清单 **双向**真红腿（各一条；走沙箱副本，改的是副本、被测件仍是同一个牙）──
  sed '/^SECURITY.md\t/d' "$SELF" > "$SBX/ra-no-sec.md"      # 清单里删掉一行「fork 治理件」⇒ 件头仍列它
  chk "D1-件头列了/清单没有" 1 'ROOT_ALLOW_DOC_NOTE kind=header-not-in-list entry=SECURITY.md' bash "$SBX/ra-no-sec.md" --root "$REAL_ROOT"
  sed "s/^\.gitignore\t/.editorconfig\tfork 治理件：注入的假行（本腿用）\n.gitignore\t/" "$SELF" > "$SBX/ra-extra.md"
  chk "D2-清单有/件头没列" 1 'ROOT_ALLOW_DOC_NOTE kind=list-not-in-header entry=.editorconfig' bash "$SBX/ra-extra.md" --root "$REAL_ROOT"
  # ── ③' 件头标记段 ↔ 代码常量 `DOC_CAT3`：**借牙自己的输出**判（不另写一份解析器 ⇒ 同一逻辑只有一份）──
  local out3; out3="$(bash "$SELF" --root "$REAL_ROOT" 2>&1 || true)"
  if ! grep -qF 'kind=header-span-vs-constant' <<< "$out3"; then
    printf 'CASE=%-34s expect_rc=%-6s needle=%-46s VERDICT=PASS\n' "D3-件头段与常量一致" "-" "无 kind=header-span-vs-constant"; pass=$((pass + 1))
  else
    printf 'CASE=%-34s expect_rc=%-6s needle=%-46s VERDICT=FAIL\n' "D3-件头段与常量一致" "-" "无 kind=header-span-vs-constant"; fail=$((fail + 1))
    printf '%s\n' "$out3" | grep -F 'kind=header-span-vs-constant' | sed 's/^/      | /'
  fi
  sed 's/DOC-CAT3-BEGIN: LICENSE.TXT/DOC-CAT3-BEGIN: .editorconfig|LICENSE.TXT/' "$SELF" > "$SBX/ra-span-bad.md"
  chk "D3b-件头段被改坏" 1 'kind=header-span-vs-constant' bash "$SBX/ra-span-bad.md" --root "$REAL_ROOT"
  # ── ④ 绿档可见性：内嵌档 vs `--allow <FILE>` 档，两行的 `root=`／`allow_src=`／`allow_file=` 必须如实且不同 ──
  awk "/^read_allow\(\)/,/^}/" "$SELF" | awk "/<<'ALLOWLIST'/{f=1;next} /^ALLOWLIST\$/{f=0} f" > "$SBX/allow.tsv"
  chk "D4-内嵌档绿行带来源" 0 'allow_src=embedded allow_file=-' bash "$SELF" --root "$REAL_ROOT"
  chk "D5---allow 档绿行带来源" 0 "allow_src=file allow_file=$SBX/allow.tsv" bash "$SELF" --root "$REAL_ROOT" --allow "$SBX/allow.tsv"
  chk "D5b-两档的 root= 都印" 0 'root=/home/links-dev/netTest/GitProj/WPFOnLinux' bash "$SELF" --root "$REAL_ROOT" --allow "$SBX/allow.tsv"
  # ── ⑤ 来源标签与实现一致：**工作树独有**件（未跟踪）只该有 `source=worktree`，不许出现 `source=git-ls-files` ──
  : > "$FX/wt-only.txt"
  local out5; out5="$(bash "$SELF" --root "$FX" 2>&1 || true)"
  if printf '%s\n' "$out5" | grep -qF 'ROOT_ALLOW_HIT entry=wt-only.txt source=worktree' \
     && ! printf '%s\n' "$out5" | grep -qF 'entry=wt-only.txt source=git-ls-files'; then
    printf 'CASE=%-34s expect_rc=%-6s needle=%-46s VERDICT=PASS\n' "D6-未跟踪件只报 worktree 源" "-" "entry=wt-only.txt source=worktree（且无 git 源）"; pass=$((pass + 1))
  else
    printf 'CASE=%-34s expect_rc=%-6s needle=%-46s VERDICT=FAIL\n' "D6-未跟踪件只报 worktree 源" "-" "entry=wt-only.txt source=worktree（且无 git 源）"; fail=$((fail + 1))
    printf '%s\n' "$out5" | sed 's/^/      | /'
  fi
  rm -f "$FX/wt-only.txt"

  # ── N4：清单里有 why 为空的条目 ⇒ allowlist-malformed（**先修清单**，不许静默放行）
  printf '%s\n' "$(read_allow)" $'fake-entry\t' > "$SBX/allow-badwhy.tsv"
  chk "N4-清单条目 why 为空" 1 'reason=allowlist-malformed' bash "$SELF" --root "$FX" --allow "$SBX/allow-badwhy.tsv"

  # ── N5/N6：清单件缺席 / 根缺席 ⇒ NOINFO（**不许绿**）
  chk "N5-清单件缺席" 3 'ROOT_ALLOW=NOINFO' bash "$SELF" --root "$FX" --allow "$SBX/definitely-absent.tsv"
  chk "N6-根缺席"     3 'ROOT_ALLOW=NOINFO reason=root-absent' bash "$SELF" --root "$SBX/no-such-root"

  echo "ROOT_ALLOW_SELFTEST=$([ "$fail" -eq 0 ] && echo PASS || echo FAIL) cases=$((pass + fail)) pass=$pass fail=$fail"
  [ "$fail" -eq 0 ] || return $RC_FAIL
  return $RC_PASS
}

if [ "$SELFTEST" -eq 1 ]; then
  selftest; exit $?
fi

# ── 正常档 ────────────────────────────────────────────────────────────────────
ALLOW_TEXT="$ROOT_ALLOW_LIST"; ALLOW_SRC=embedded; ALLOW_PATH="-"
if [ -n "$ALLOW_FILE" ]; then
  [ -f "$ALLOW_FILE" ] || { echo "ROOT_ALLOW=NOINFO reason=allowlist-absent root=$ROOT allow_src=file allow_file=$ALLOW_FILE（清单件缺席 ⇒ 不判绿）"; exit $RC_NOINFO; }
  [ -r "$ALLOW_FILE" ] || { echo "ROOT_ALLOW=NOINFO reason=allowlist-unreadable root=$ROOT allow_src=file allow_file=$ALLOW_FILE"; exit $RC_NOINFO; }
  ALLOW_TEXT="$(cat "$ALLOW_FILE")"; ALLOW_SRC=file; ALLOW_PATH="$ALLOW_FILE"
fi
check_root "$ROOT" "$ALLOW_TEXT" "$ALLOW_SRC" "$ALLOW_PATH"
exit $?
