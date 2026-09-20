#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# sync-applocal.sh —— 「五件」权威产物 ⇒ **任意目标目录** 的**带参同步器**
#                    （可多目录；只读核对 `--check`；试跑 `--dry-run`；可选扩面 `--sweep`）
#
# 【它解决什么】把一套件同步到**别人的应用目录**（例：`hc-linux` 的 HandyControlDemo，
#   `/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`）原先
#   **既没有工具、也没有可复算的读数** ⇒ 实测代价见 `D-G56`/`W1`：
#   「应用目录里的件是陈旧的 ⇒ 看起来像"**修复没生效**"」——那是**读数的错**，不是产品件的错。
#   本件把这件事变成**一条命令 + 一份 manifest**：同步前/后**逐个印 sha16**，
#   同步后**断言 `after == authority`**（不等就是 `FAIL`，不是"大概好了"）。
#
# 【⚠️ 与仓内**既有两件**的分工（别把本件读成"重复造轮子"，也别把另外两件当成本件的替代）】
#   · `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` —— **判据的唯一实现**（十类口径：
#     OK/MISMATCH/STALE/DIVERGENT/NEWER-DIFF/MISSING/UNEXPECTED/LIB-COPY/SKIP(obj|stub|ref)/AUTH-MISSING）。
#     ⚠️ 它的 `ITEMS`（`:160-168`）**只有 6 个具名件的权威**：`libwpfwic.so`／`libwpfwin32.so`／
#     `DirectWrite.Linux.Provider.dll`／`WpfGfx.Linux.dll`／`ReachFramework.dll`／`PresentationCore.dll`
#     （`wpfgfx_cor3.so` 的权威是一份**断言**、走 `BRIDGE-ANCHOR`）⇒
#     **`PresentationFramework.dll` 与 `WindowsBase.dll` 两份权威今天仍不在它的表里**
#     （`D-A2` 同族：PC 那一格 `#23` 才补上）⇒ 即"删掉某份 PF/WB 副本，它连 `MISSING` 都不会报"。
#     本件**恰好覆盖这五件**（含 PF/WB），所以两件**不是替代关系**：判据仍归它，覆盖面上本件补它的空。
#   · `build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh` —— **执行**上面那份判据的结论，
#     刷新**仓内** `SCAN_ROOTS`（默认 `$REPO/{build,tests,samples,src}`）里的 `STALE`／`DIVERGENT`
#     落单副本；**它没有"目标目录"参数**，也**不服务仓外的应用目录**。
#   · 本件 = **任意目录**（可仓外）＋ **只保证"目标目录里这五件与权威逐位一致"** ＋ manifest。
#     ⚠️ 本件**不做判据**（不产生那十类口径）、**不删任何文件**、**不扫仓内其它副本**
#     ⇒ 仓内收敛仍请跑 `sync-applocal-authority.sh --apply`（并看 `check-applocal-sync.sh` 的 `APPSYNC=` 行）。
#
# 【权威源（五件；与 `check-applocal-sync.sh` 的 ITEMS 同源口径）】
#   ① `libwpfwin32.so`            ← `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`
#   ② `wpfgfx_cor3.so`            ← `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so`
#   ③ `PresentationCore.dll`      ← `build/PresentationCore.Linux/bin/<cfg>/PresentationCore.dll`
#   ④ `PresentationFramework.dll` ← `build/PresentationFramework.Linux/bin/<cfg>/PresentationFramework.dll`
#   ⑤ `WindowsBase.dll`           ← `build/WindowsBase.Linux/bin/<cfg>/WindowsBase.dll`
#   `<cfg>` 默认 `Release`（本仓门禁/探针树用的是 Release），可用 `--config Debug` 或
#   环境变量 `SELFBUILT_CONFIG` 覆盖 —— **解析出来的绝对路径与 sha16 一律印在屏上**（选错了看得见）。
#
# 【写盘语义（两条刻意的选择，都为了"不留半件"）】
#   · **临时件 + `mv` 改名**（不是 `cp -f` 就地截断）：同目录 `rename(2)` 是原子的；
#     就地截断在**应用正在跑**的现场会把它 `mmap` 的旧页打成 `SIGBUS`（dlopen 后旧 inode 仍安全）。
#   · 每件拷完**立刻回读 sha16 并断言等于权威**；不等 ⇒ 计 `FAIL`（rc=4）并点名。
#   · `--check` / `--dry-run` **一律不写盘**（含不写 manifest）。
#
# 【manifest（`<目标>/.applocal-sync.tsv`）】取 `docs/CURRENT-STATE.md` §4 记的**目标形态**：
#   逐行 `path <TAB> item <TAB> authority <TAB> authority_sha16 <TAB> before <TAB> after <TAB> status`
#   ＋ 表头带 `site / site_line / site_fp / repo / config / at / mode`。
#   **拒绝写空 manifest**（0 行 ⇒ 不写、并印 `manifest=SKIPPED rows=0`）——"空白记录"不许冒充证据。
#   `--no-manifest` 关闭；`--manifest <路径>` 换位置（多目标时是对**每一个**目标目录生效的**文件名**语义：
#   以 `/` 结尾或已存在目录 ⇒ 视为目录；否则视为逐目标同名文件）。
#
# 【三态与退出码（`NOINFO` 不许当绿）】
#   0 = 五件**全部就位且同步后 == 权威**（`--check`：五件**均已一致**）
#   1 = **权威件缺失**（同步不了 ⇒ 本次读数不成立；绝不"跳过并当绿"）
#   2 = 用法 / 目标目录问题（不存在、不像应用宿主目录且未 `--force`）
#   3 = `--check` 下发现**漂移**（陈旧 / 缺件）⇒ 该跑一次同步
#   4 = 写盘失败或**拷后回读 != 权威**
#   汇总行（机读，与 `check-applocal-sync.sh` 的 `APPSYNC=` **刻意不同名**，免得读混）：
#     `SYNC-APPLOCAL=PASS|DRIFT|NOAUTH|FAIL target=<abs> items=N ok=N synced=N created=N drift=N noauth=N same=N rc=N`
#
# 【`--sweep` 扩面（可选）】除五件外，另按 `run-wpfprobe.sh` 的装配口径补齐：`build/*.Linux/bin/<cfg>/`
#   里"工程名 == 程序集名"的每一份 `*.dll`、`DirectWrite.Linux.Provider.dll`、`libwpfwic.so`、
#   MilBridge 发布目录下的**全部** `*.so`。⚠️ `--sweep` 的**期望集合**是本件自己算的、
#   **不在任何门禁的期望模型里** ⇒ 它只是"让应用目录真的完整"，**不构成判据**。
# 【`--with-aliases`】额外写 `uxtheme.dll`/`wtsapi32.dll`/`shell32.dll`/`PresentationNative_cor3.dll`
#   四个 win32 shim **别名副本**（`run-*.sh` 同款"双保险/止损"手法）。默认**不写**。
#
# 【自检】`--selftest`：在 `$TMPDIR` 里造**同形相对路径**的假仓库根（`APPSYNC_REPO_ROOT`），
#   跑成对极性：陈旧 ⇒ `SYNCED` 且拷后相等；幂等 ⇒ 第二次 `OK`；`--check` 抓漂移 rc=3；
#   缺权威 rc=1；`--dry-run` 不动盘；非宿主目录 rc=2 而 `--force` rc=0；自拷贝 `SAME` 不误伤。
#
# 【用法】
#   bash build/MilBridge/tools/sync-applocal.sh /path/to/app/bin/Debug/net10.0
#   bash build/MilBridge/tools/sync-applocal.sh --check /path/to/appdir     # 只读核对（漂移 ⇒ rc=3）
#   bash build/MilBridge/tools/sync-applocal.sh --sweep --mkdir out/a out/b
#   bash build/MilBridge/tools/sync-applocal.sh --list                      # 只印五件权威现值（不动盘）
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"
# ⚠️ `APPSYNC_REPO_ROOT` 是**为 `--selftest`（与"镜像树"复算）留的口子**，不是免罪符：
#   解析出的**仓库根 / 每件绝对路径 / 每件 sha16** 全部印在屏上与 manifest 表头里 ⇒ 指错了树看得见。
REPO="${APPSYNC_REPO_ROOT:-$(cd "$HERE/../../.." && pwd)}"

sha16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }
bytes() { stat -c%s "$1" 2>/dev/null || echo "?"; }

usage() { sed -n '2,80p' "$SELF" | sed 's/^# \{0,1\}//'; }

say()  { printf '%s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*" >&2; }
die()  { local rc="$1"; shift; printf 'ERROR %s\n' "$*" >&2; exit "$rc"; }

# ── 五件权威表（`@CFG@` 在解析期替换；顺序 = 打印顺序 = manifest 行序） ──────────────
ITEMS=(
  "libwpfwin32.so|src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
  "wpfgfx_cor3.so|build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so"
  "PresentationCore.dll|build/PresentationCore.Linux/bin/@CFG@/PresentationCore.dll"
  "PresentationFramework.dll|build/PresentationFramework.Linux/bin/@CFG@/PresentationFramework.dll"
  "WindowsBase.dll|build/WindowsBase.Linux/bin/@CFG@/WindowsBase.dll"
)

MODE=apply; CONFIG="${SELFBUILT_CONFIG:-Release}"; ONLY=""; QUIET=0; FORCE=0; MK=0
SWEEP=0; ALIASES=0; MANIFEST=1; MANIFEST_PATH=""; LISTMODE=0; SELFTEST=0
TARGETS=()
TMPFILES=""
trap 'while IFS= read -r t; do [ -n "$t" ] && rm -f -- "$t"; done <<<"$TMPFILES"' EXIT

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)                 usage; exit 0 ;;
    --list|--print-authorities) LISTMODE=1; shift ;;
    --selftest)                SELFTEST=1; shift ;;
    -n|--dry-run)              MODE=dry; shift ;;
    -c|--check)                MODE=check; shift ;;
    -q|--quiet)                QUIET=1; shift ;;
    --config)                  [ $# -ge 2 ] || die 2 "--config 需要值"; CONFIG="$2"; shift 2 ;;
    --only)                    [ $# -ge 2 ] || die 2 "--only 需要值"; ONLY="$2"; shift 2 ;;
    --sweep)                   SWEEP=1; shift ;;
    --with-aliases)            ALIASES=1; shift ;;
    --force)                   FORCE=1; shift ;;
    --mkdir)                   MK=1; shift ;;
    --no-manifest)             MANIFEST=0; shift ;;
    --manifest)                [ $# -ge 2 ] || die 2 "--manifest 需要值"; MANIFEST_PATH="$2"; shift 2 ;;
    --)                        shift; while [ $# -gt 0 ]; do TARGETS+=("$1"); shift; done ;;
    -*)                        die 2 "未知选项：$1（--help 看用法）" ;;
    *)                         TARGETS+=("$1"); shift ;;
  esac
done

case "$CONFIG" in Debug|Release) : ;; *) die 2 "--config 只认 Debug|Release（现给：$CONFIG）" ;; esac

# ── 解析权威路径（`@CFG@` 替换；相对 → REPO 下绝对） ─────────────────────────────
AUTH_NAME=(); AUTH_PATH=()
resolve_items() {
  local row name rel
  for row in "${ITEMS[@]}"; do
    name="${row%%|*}"; rel="${row#*|}"
    rel="${rel//@CFG@/$CONFIG}"
    AUTH_NAME+=("$name")
    AUTH_PATH+=("$REPO/$rel")
  done
  # ── `--sweep`：按 `run-wpfprobe.sh` 的装配口径补齐（**不作为判据**，见文件头） ──
  if [ "$SWEEP" = 1 ]; then
    local d proj
    for d in "$REPO"/build/*.Linux/bin/"$CONFIG"/*.dll; do
      [ -f "$d" ] || continue
      proj="$(basename "$(dirname "$(dirname "$(dirname "$d")")")")"
      case "$proj" in CycleStub.*|ReachFramework.Linux) continue ;; esac
      [ "$(basename "$d" .dll)" = "${proj%.Linux}" ] || continue
      AUTH_NAME+=("$(basename "$d")"); AUTH_PATH+=("$d")
    done
    local so
    for so in "$REPO"/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/*.so; do
      [ -f "$so" ] || continue
      AUTH_NAME+=("$(basename "$so")"); AUTH_PATH+=("$so")
    done
    AUTH_NAME+=("libwpfwic.so"); AUTH_PATH+=("$REPO/build/DirectWrite.Linux/wic-shim/libwpfwic.so")
    AUTH_NAME+=("DirectWrite.Linux.Provider.dll")
    AUTH_PATH+=("$REPO/build/DirectWrite.Linux/Provider/bin/$CONFIG/DirectWrite.Linux.Provider.dll")
    AUTH_NAME+=("ReachFramework.dll"); AUTH_PATH+=("$REPO/build/ReachFramework.Linux/bin/$CONFIG/ReachFramework.dll")
  fi
  # `--with-aliases`：同一份 shim 的四个别名（默认不写）
  if [ "$ALIASES" = 1 ]; then
    local a
    for a in uxtheme.dll wtsapi32.dll shell32.dll PresentationNative_cor3.dll; do
      AUTH_NAME+=("$a"); AUTH_PATH+=("$REPO/src/WpfGfx.Linux.Native/bin/libwpfwin32.so")
    done
  fi
  # 去重（同名只留第一条 ⇒ 五件优先；`--sweep` 不会把五件顶掉）
  local i j keep_n=() keep_p=()
  for i in "${!AUTH_NAME[@]}"; do
    local dup=0
    for j in "${!keep_n[@]}"; do [ "${keep_n[$j]}" = "${AUTH_NAME[$i]}" ] && dup=1 && break; done
    if [ "$dup" = 0 ]; then keep_n+=("${AUTH_NAME[$i]}"); keep_p+=("${AUTH_PATH[$i]}"); fi
  done
  AUTH_NAME=("${keep_n[@]}"); AUTH_PATH=("${keep_p[@]}")
  # `--only` 过滤（逗号分隔的件名）
  if [ -n "$ONLY" ]; then
    local want=",$ONLY," kn=() kp=()
    for i in "${!AUTH_NAME[@]}"; do
      case "$want" in *",${AUTH_NAME[$i]},"*) kn+=("${AUTH_NAME[$i]}"); kp+=("${AUTH_PATH[$i]}") ;; esac
    done
    [ "${#kn[@]}" -gt 0 ] || die 2 "--only 一件都没匹配上（给的：$ONLY）"
    AUTH_NAME=("${kn[@]}"); AUTH_PATH=("${kp[@]}")
  fi
}
resolve_items

# ── `--list`：只印五件权威现值（不动盘） ────────────────────────────────────────
if [ "$LISTMODE" = 1 ]; then
  say "# item	authority	sha16	bytes"
  miss=0
  for i in "${!AUTH_NAME[@]}"; do
    p="${AUTH_PATH[$i]}"
    if [ -f "$p" ]; then
      say "$(printf '%s\t%s\t%s\t%s' "${AUTH_NAME[$i]}" "$p" "$(sha16 "$p")" "$(bytes "$p")")"
    else
      say "$(printf '%s\t%s\t**缺失**\t-' "${AUTH_NAME[$i]}" "$p")"; miss=$((miss + 1))
    fi
  done
  say "SYNC-APPLOCAL=LIST repo=$REPO config=$CONFIG items=${#AUTH_NAME[@]} missing=$miss"
  [ "$miss" = 0 ] || exit 1
  exit 0
fi

# ── 拷贝（临时件 + 同目录改名；失败不留残件） ──────────────────────────────────
copy_atomic() {   # $1=源 $2=目标 ⇒ rc0；失败清残件并返非 0
  local src="$1" dst="$2" tmp
  tmp="$(dirname "$dst")/.applocal-sync.$$.$(basename "$dst").tmp"
  TMPFILES="$TMPFILES$tmp"$'\n'
  cp -f -- "$src" "$tmp" || { rm -f -- "$tmp"; return 1; }
  mv -f -- "$tmp" "$dst" || { rm -f -- "$tmp"; return 1; }
  return 0
}

site_line() { grep -n '^copy_atomic()' "$SELF" 2>/dev/null | cut -d: -f1; }
SITE_LINE="$(site_line)"; [ -n "$SITE_LINE" ] || SITE_LINE="NOINFO"
SITE_FP="$(sha16 "$SELF")"; [ -n "$SITE_FP" ] || SITE_FP="NOINFO"
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

run_one_target() {   # $1 = 目标目录（原样，可能相对） ⇒ 置 G_RC 与计数
  local tdir="$1"
  G_RC=0; G_ROWS=0; G_OK=0; G_SYNCED=0; G_CREATED=0; G_DRIFT=0; G_NOAUTH=0; G_SAME=0; G_FAIL=0
  local MANIFEST_ROWS=""

  if [ ! -d "$tdir" ]; then
    if [ "$MK" = 1 ]; then
      mkdir -p -- "$tdir" || die 2 "无法创建目标目录：$tdir"
    else
      warn "目标目录不存在：$tdir（要创建请加 --mkdir）"; G_RC=2; return 0
    fi
  fi
  local TDIR; TDIR="$(cd "$tdir" && pwd)"

  # 像不像"应用宿主目录"（`applocal-expect.py` 的口径：无 runtimeconfig 的库输出目录**不参与判定**）
  local rc_glob=1
  for f in "$TDIR"/*.runtimeconfig.json "$TDIR"/*.deps.json; do [ -e "$f" ] && rc_glob=0 && break; done
  if [ "$rc_glob" != 0 ]; then
    local n_empty; n_empty="$(find "$TDIR" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)"
    if [ "$n_empty" = 0 ]; then
      [ "$QUIET" = 1 ] || say "NOTE  目标目录为空 ⇒ 按**全新部署目录**处理：$TDIR"
    elif [ "$FORCE" != 1 ]; then
      warn "$TDIR 里没有 *.runtimeconfig.json / *.deps.json ⇒ 它**不像**应用宿主目录（库输出目录不参与 app-local 判定）"
      warn "确认要对它同步请加 --force（本次**未写盘**）"
      G_RC=2; return 0
    else
      warn "$TDIR 不像应用宿主目录，但给了 --force ⇒ 照做："$'\n'"      $TDIR"
    fi
  fi

  [ "$QUIET" = 1 ] || {
    say "== 目标 $TDIR"
    say "   仓库根 $REPO   config=$CONFIG   mode=$MODE   件数 ${#AUTH_NAME[@]}"
  }

  local i name apath asha dpath bsha
  for i in "${!AUTH_NAME[@]}"; do
    name="${AUTH_NAME[$i]}"; apath="${AUTH_PATH[$i]}"; dpath="$TDIR/$name"
    G_ROWS=$((G_ROWS + 1))
    if [ ! -f "$apath" ]; then
      G_NOAUTH=$((G_NOAUTH + 1)); G_RC=1
      say "  ✗ $name：**权威件缺失** ⇒ 同步不了（本次读数不成立）：$apath"
      MANIFEST_ROWS="$MANIFEST_ROWS$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s' "$name" "$name" "$apath" "MISSING" "-" "-" "MISSING-AUTH")"$'\n'
      continue
    fi
    asha="$(sha16 "$apath")"
    # 自拷贝（目标 == 权威本体）：`cp a a` 会报 same file ⇒ 显式识别、不写盘、计 SAME
    if [ -f "$dpath" ] && [ "$(readlink -f -- "$dpath")" = "$(readlink -f -- "$apath")" ]; then
      G_SAME=$((G_SAME + 1)); G_OK=$((G_OK + 1))
      say "  = $name：目标**就是权威本体**（同一 inode）⇒ 无需同步  $asha"
      MANIFEST_ROWS="$MANIFEST_ROWS$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s' "$name" "$name" "$apath" "$asha" "$asha" "$asha" "SAME")"$'\n'
      continue
    fi
    if [ -f "$dpath" ]; then bsha="$(sha16 "$dpath")"; else bsha="(缺)"; fi
    if [ "$bsha" = "$asha" ]; then
      G_OK=$((G_OK + 1))
      [ "$QUIET" = 1 ] || say "  ✓ $name：已与权威一致  $asha"
      MANIFEST_ROWS="$MANIFEST_ROWS$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s' "$name" "$name" "$apath" "$asha" "$bsha" "$bsha" "OK")"$'\n'
      continue
    fi
    # 到此：陈旧 / 缺件 ⇒ 该同步（或该报漂移）
    local st; [ "$bsha" = "(缺)" ] && st=CREATED || st=SYNCED
    if [ "$MODE" = check ]; then
      G_DRIFT=$((G_DRIFT + 1)); G_RC=3
      say "  ⚠ $name：**漂移** 目标=$bsha ≠ 权威=$asha（--check 只读，未写盘）"
      MANIFEST_ROWS="$MANIFEST_ROWS$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s' "$name" "$name" "$apath" "$asha" "$bsha" "$bsha" "DRIFT")"$'\n'
      continue
    fi
    if [ "$MODE" = dry ]; then
      G_DRIFT=$((G_DRIFT + 1))
      say "  → $name：**将同步** 目标=$bsha → 权威=$asha  status=WOULD-$st（--dry-run，未写盘）"
      MANIFEST_ROWS="$MANIFEST_ROWS$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s' "$name" "$name" "$apath" "$asha" "$bsha" "$bsha" "WOULD-$st")"$'\n'
      continue
    fi
    if ! copy_atomic "$apath" "$dpath"; then
      G_FAIL=$((G_FAIL + 1)); G_RC=4
      say "  ✗ $name：**写盘失败**（未回读断言）  $apath → $dpath"
      MANIFEST_ROWS="$MANIFEST_ROWS$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s' "$name" "$name" "$apath" "$asha" "$bsha" "-" "FAIL-COPY")"$'\n'
      continue
    fi
    local after; after="$(sha16 "$dpath")"
    if [ "$after" != "$asha" ]; then
      G_FAIL=$((G_FAIL + 1)); G_RC=4
      say "  ✗ $name：**拷后回读 != 权威**  权威=$asha 回读=$after（这才是「修复没生效」的样子）"
      MANIFEST_ROWS="$MANIFEST_ROWS$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s' "$name" "$name" "$apath" "$asha" "$bsha" "$after" "FAIL-READBACK")"$'\n'
      continue
    fi
    if [ "$st" = CREATED ]; then G_CREATED=$((G_CREATED + 1)); else G_SYNCED=$((G_SYNCED + 1)); fi
    say "  ⟳ $name：**已同步**  $bsha → $asha（回读断言通过）"
    MANIFEST_ROWS="$MANIFEST_ROWS$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s' "$name" "$name" "$apath" "$asha" "$bsha" "$after" "$st")"$'\n'
  done

  # ── manifest（apply 且 rows>0 才写；**拒绝写空 manifest**） ──
  local mpath
  if [ -n "$MANIFEST_PATH" ]; then
    case "$MANIFEST_PATH" in
      */) mpath="$MANIFEST_PATH$(basename "$TDIR").applocal-sync.tsv" ;;
      *)  if [ -d "$MANIFEST_PATH" ]; then mpath="$MANIFEST_PATH/$(basename "$TDIR").applocal-sync.tsv"
          else mpath="$MANIFEST_PATH"; fi ;;
    esac
  else
    mpath="$TDIR/.applocal-sync.tsv"
  fi
  if [ "$MANIFEST" != 1 ] || [ "$MODE" != apply ]; then
    [ "$QUIET" = 1 ] || say "   manifest=$([ "$MANIFEST" = 1 ] && echo "SKIPPED(mode=$MODE 不写盘)" || echo "OFF")"
  elif [ "$G_ROWS" = 0 ]; then
    say "   manifest=SKIPPED rows=0（**拒绝写空 manifest**）"
  else
    {
      say "# applocal-sync manifest —— 由 build/MilBridge/tools/sync-applocal.sh 写出"
      say "# site=sync-applocal.sh site_line=$SITE_LINE site_fp=$SITE_FP"
      say "# repo=$REPO config=$CONFIG mode=$MODE at=$STAMP target=$TDIR"
      say "# path：「path」= 目标目录下的文件名；「authority_sha16」= 权威本体的 sha16（前 16 位十六进制）"
      printf 'path\titem\tauthority\tauthority_sha16\tbefore_sha16\tafter_sha16\tstatus\n'
      printf '%s' "$MANIFEST_ROWS"
    } > "$mpath" 2>/dev/null && say "   manifest=$mpath（$G_ROWS 行）" \
      || { warn "manifest 写不进去：$mpath"; G_FAIL=$((G_FAIL + 1)); [ "$G_RC" = 0 ] && G_RC=4; }
  fi

  local verdict=PASS
  case "$G_RC" in 1) verdict=NOAUTH ;; 3) verdict=DRIFT ;; 4) verdict=FAIL ;; esac
  say "SYNC-APPLOCAL=$verdict target=$TDIR items=${#AUTH_NAME[@]} ok=$G_OK synced=$G_SYNCED created=$G_CREATED drift=$G_DRIFT noauth=$G_NOAUTH same=$G_SAME rc=$G_RC"
  return 0
}

# ── `--selftest`：成对极性（在假仓库根里跑，不碰真树） ───────────────────────────
selftest() {
  local T; T="$(mktemp -d "${TMPDIR:-/tmp}/appsync-selftest.XXXXXX")" || die 2 "mktemp 失败"
  local S="$T/repo" A="$T/app" n_fail=0
  local rels=(
    "src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
    "build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so"
    "build/PresentationCore.Linux/bin/Release/PresentationCore.dll"
    "build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll"
    "build/WindowsBase.Linux/bin/Release/WindowsBase.dll"
  )
  local r
  for r in "${rels[@]}"; do mkdir -p "$S/$(dirname "$r")"; printf 'AUTHORITY-%s\n' "$r" > "$S/$r"; done
  mkdir -p "$A"; : > "$A/Probe.runtimeconfig.json"
  local names=(libwpfwin32.so wpfgfx_cor3.so PresentationCore.dll PresentationFramework.dll WindowsBase.dll)
  local i
  for i in "${!names[@]}"; do cp -f "$S/${rels[$i]}" "$A/${names[$i]}"; done
  printf 'STALE\n' > "$A/PresentationCore.dll"                       # 一件陈旧 ⇒ 极性源

  local rc out
  chk() {   # $1=期望 rc $2=期望字样 $3=case 名；其余 = 命令行
    local erc="$1" pat="$2" cname="$3"; shift 3
    out="$(APPSYNC_REPO_ROOT="$S" bash "$SELF" "$@" 2>&1)"; rc=$?
    if [ "$rc" = "$erc" ] && grep -qF -- "$pat" <<<"$out"; then
      say "SELFTEST=PASS case=$cname rc=$rc 命中[$pat]"
    else
      say "SELFTEST=FAIL case=$cname rc=$rc（期望 $erc）期望字样[$pat]"
      printf '%s\n' "$out" | sed 's/^/      | /' | tail -8
      n_fail=$((n_fail + 1))
    fi
  }
  chk 3 'SYNC-APPLOCAL=DRIFT' 'check-抓到陈旧' --check "$A"
  chk 0 'synced=1'            'apply-同步陈旧' --quiet "$A"
  chk 0 'ok=5 synced=0'       'apply-幂等'     --quiet "$A"
  # `--dry-run` 不许动盘：先把一件改回陈旧，dry 跑完必须**还是**陈旧
  cp -f "$A/PresentationFramework.dll" "$T/pf.good"; printf 'STALE2\n' > "$A/PresentationFramework.dll"
  chk 0 'WOULD-SYNCED'        'dry-run-报将同步' --quiet --dry-run "$A"
  if [ "$(sha16 "$A/PresentationFramework.dll")" != "$(sha16 "$T/pf.good")" ]; then
    say "SELFTEST=PASS case=dry-run-不写盘（目标仍为陈旧 sha16=$(sha16 "$A/PresentationFramework.dll")）"
  else
    say "SELFTEST=FAIL case=dry-run-不写盘（目标被改了！）"; n_fail=$((n_fail + 1))
  fi
  cp -f "$T/pf.good" "$A/PresentationFramework.dll"
  # 缺权威 ⇒ rc=1（且不许当绿）
  mv "$S/build/WindowsBase.Linux/bin/Release/WindowsBase.dll" "$T/wb.away"
  chk 1 'SYNC-APPLOCAL=NOAUTH' '缺权威-rc1' --quiet "$A"
  cp -p "$T/wb.away" "$S/build/WindowsBase.Linux/bin/Release/WindowsBase.dll"
  chk 0 'noauth=0' '权威还原-回绿' --quiet "$A"
  # 不像宿主目录 ⇒ rc=2；`--force` ⇒ rc=0（成对）
  mkdir -p "$T/notapp"; printf 'x\n' > "$T/notapp/somefile.txt"
  chk 2 '不像**应用宿主目录' '非宿主-拒写' --quiet "$T/notapp"
  chk 0 'SYNC-APPLOCAL=PASS' '非宿主-force' --quiet --force "$T/notapp"
  # 自拷贝：目标**就是**权威目录 ⇒ SAME，不误报失败
  chk 0 'same=1' '自拷贝-SAME' --quiet --force --only PresentationCore.dll \
        "$S/build/PresentationCore.Linux/bin/Release"
  # `--list` 在假树里必须报 5 件
  chk 0 'items=5 missing=0' 'list-五件' --list
  rm -rf "$T"
  if [ "$n_fail" = 0 ]; then say "SELFTEST-ALL=PASS（12/12）"; return 0; fi
  say "SELFTEST-ALL=FAIL（$n_fail 例未过）"; return 1
}
[ "$SELFTEST" = 1 ] && { selftest; exit $?; }

[ "${#TARGETS[@]}" -gt 0 ] || { usage; die 2 "至少要给一个目标目录（或用 --list / --selftest）"; }

TOT_RC=0
for t in "${TARGETS[@]}"; do
  run_one_target "$t"
  case "$G_RC" in
    0) : ;;
    2) [ "$TOT_RC" -lt 2 ] && TOT_RC=2 ;;
    1) [ "$TOT_RC" -lt 1 ] && TOT_RC=1 ;;
    3) [ "$TOT_RC" -lt 3 ] && TOT_RC=3 ;;
    4) TOT_RC=4 ;;
  esac
done
if [ "${#TARGETS[@]}" -gt 1 ]; then
  say "SYNC-APPLOCAL-TOTAL targets=${#TARGETS[@]} rc=$TOT_RC"
fi
exit "$TOT_RC"
