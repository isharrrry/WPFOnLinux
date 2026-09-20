#!/usr/bin/env bash
# ============================================================================
# gdiplus-decode-check.sh —— `gdiplus.dll` 图像族（`#41` F）的**判据 runner**
# ============================================================================
#
# 【判据三态】
#   GDIPLUS_DECODE=PASS    探针全例通过（真解码 + 内容核对 + 三条如实失败 + 生命周期）
#   GDIPLUS_DECODE=FAIL    有例不通过（**含"撒谎 shim 也能全绿"这种探针失效**）
#   GDIPLUS_DECODE=NOINFO  前置不成立（编不出探针 / 加载不了 shim / 生成不了夹具）⇒ 不许当绿
#
# 【两种模式】
#   bash build/MilBridge/tools/gdiplus-decode-check.sh            # 打产品 shim（libwpfwin32.so）
#   bash build/MilBridge/tools/gdiplus-decode-check.sh --selftest # **反极性**：拿"撒谎 shim"跑同一探针，必须 FAIL
#
# 【为什么 selftest 是这个形态】产品 shim 通过探针只能说"它没被探针抓住"；**撒谎 shim**（全部返回 Ok、
#   宽高答 1×1、Scan0 给 NULL）若也能全绿，就证明探针**只在查状态码**、等于没查内容
#   ⇒ 那样它对我方"假装成功"这类回归**零射程**。selftest 断言这种假实现**必须**被打红。
# ============================================================================
set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd -- "$HERE/../../.." && pwd)"
PROBE_C="$HERE/gdiplus-decode-probe.c"
LIAR_C="$HERE/gdiplus-liar.c"
SHIM="$REPO/src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
WIC="$REPO/build/DirectWrite.Linux/wic-shim/libwpfwic.so"
OUT="${GDIPLUS_CHECK_DIR:-$(mktemp -d /tmp/gdiplus-check.XXXXXX)}"
SELFTEST=0
[ "${1:-}" = "--selftest" ] && SELFTEST=1

mkdir -p "$OUT"
die() { echo "GDIPLUS_DECODE=NOINFO reason=$1 ${2:-}"; exit 2; }

command -v gcc >/dev/null 2>&1 || die "gcc-absent"
command -v convert >/dev/null 2>&1 || die "imagemagick-absent"

# ── 夹具：已知尺寸 7×5、纯色 #FF8000（⇒ (0,0) 的 RGB 必须逐位相等；alpha=FF ⇒ 预乘不影响 RGB）
PNG="$OUT/test-7x5.png"
convert -size 7x5 xc:'#FF8000' "$PNG" 2>/dev/null || die "fixture-png-failed"
JUNK="$OUT/junk.png"
head -c 512 /dev/urandom > "$JUNK"
# 随机字节**偶发**可能是合法图片的概率极低；为确定性起见再钉一个坏魔数（PNG 头之后全 0）
printf '\x89PNG\r\n\x1a\n' > "$JUNK"; head -c 256 /dev/zero >> "$JUNK"

if [ "$SELFTEST" = 1 ]; then
  LIB="$OUT/libgdiplus-liar.so"
  gcc -O1 -fPIC -shared -Wall -o "$LIB" "$LIAR_C" 2>"$OUT/liar-build.log" || die "liar-build-failed"
  echo "（selftest）撒谎 shim = $LIB"
else
  LIB="$SHIM"
  [ -f "$LIB" ] || die "product-shim-absent" "$LIB"
fi

BIN="$OUT/probe"
gcc -O1 -Wall -o "$BIN" "$PROBE_C" -ldl 2>"$OUT/probe-build.log" || die "probe-build-failed"

# 探针也需要解码链：产品档下 shim 会同目录/环境变量找 `libwpfwic.so`；撒谎档不需要
export WPF_LINUX_WIC_SHIM="${WPF_LINUX_WIC_SHIM:-$WIC}"

# 期望值：宽 7 高 5 RGB=ff8000（与上面的 convert 一一对应；**改夹具就必须同趟改这里**）
set +e
"$BIN" "$LIB" "$PNG" 7 5 ff8000 "$JUNK"
rc=$?
set -e

if [ "$SELFTEST" = 1 ]; then
  # 反极性：撒谎 shim ⇒ 探针**必须**红
  if [ "$rc" -ne 0 ]; then
    echo "GDIPLUS_CHECK_SELFTEST=PASS（撒谎 shim 被打红 ⇒ 内容判据真的在咬）"
    exit 0
  fi
  echo "GDIPLUS_CHECK_SELFTEST=FAIL（撒谎 shim 竟然全绿 ⇒ 探针只在查状态码，等于没查内容）"
  exit 1
fi

case "$rc" in
  0) echo "GDIPLUS_DECODE=PASS outdir=$OUT" ;;
  2) echo "GDIPLUS_DECODE=NOINFO reason=probe-nolib outdir=$OUT" ;;
  *) echo "GDIPLUS_DECODE=FAIL rc=$rc outdir=$OUT" ;;
esac
exit "$rc"
