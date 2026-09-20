#!/usr/bin/env bash
# ============================================================================
# selfbuilt-config.sh —— **自产件配置的唯一 shell 读取器**（`#39` 阶段 1）
# ============================================================================
#
# ⚠️ **变量名为什么叫 `SELFBUILT_CONFIG` 而不是 `WPF_LINUX_*`**（`#39` 实测踩过）：
#   **应用门禁的默认档会清空全部 `WPF_LINUX_*`/`HLWPF_*` 字体 env** —— 我第一版把变量起名
#   `WPF_LINUX_SELF_CONFIG`，于是那一档里它被 unset ⇒ 应用路径塌成 `bin//net10.0` ⇒
#   应用 `exit=127`（command not found）、门禁三 rep 全红（而 `env` 档照常过）。
#   ⇒ **新增工具变量必须避开判据的清理域**（同族：诊断变量用了 `WPFGFX_ROOTDIAG` 而不是 `WPF_LINUX_*`）。
#
# 【唯一声明处】`build/SelfBuiltConfig.props`（MSBuild 侧由两条 import 图各 import 一次；
#   脚本侧**只许**经本文件读取 —— 任何脚本里再写死 `Debug`/`Release` 都是**分叉**）。
#
# 【用法】
#   source build/selfbuilt-config.sh        # ⇒ 导出 SELFBUILT_CONFIG（并校验取值合法）
#   bash build/selfbuilt-config.sh          # 打印当前值
#   bash build/selfbuilt-config.sh --check        # 两颗牙（见下），rc=0 才算一致
#   bash build/selfbuilt-config.sh --debt         # 打印"还写死 bin/Debug"的处数（阶段 3 欠账）
#   bash build/selfbuilt-config.sh --debt-check   # 🦷 棘轮：欠账**只许减少**（上限 = 脚本里的字面常量）
#
# 【两颗牙（自检模式）】
#   ① **声明唯一**：`SelfBuiltConfig.props` 里恰好 1 条 `<WpfLinuxSelfBuiltConfiguration …>值<…>`；
#      取值 ∈ {Debug, Release}（不是"看起来像"就行）。
#   ② **脚本 == MSBuild**：本脚本解析出来的值，必须等于 `dotnet msbuild -getProperty:` 在
#      **两条 import 图各取一个代表工程**上求出来的值（自产件图 = `build/System.Xaml.Linux`；
#      样本图 = `samples/WpfTextDemo`）⇒ "读了同一份声明"这件事**被机器证明**，而不是靠注释声明。
#   ⚠️ 缺件 / 解析不出 / 求值失败 ⇒ **NOINFO（rc=2）**，不许当绿（本仓铁律）。
# ============================================================================
set -uo pipefail

_SBC_HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SBC_REPO="$(cd -- "$_SBC_HERE/.." && pwd)"
SBC_DECL="${SBC_DECL:-$SBC_REPO/build/SelfBuiltConfig.props}"

_sbc_parse() {   # 从唯一声明处解析取值；多于/少于 1 条 ⇒ 空串
  local n v
  n="$(grep -c '<WpfLinuxSelfBuiltConfiguration' "$SBC_DECL" 2>/dev/null || true)"
  [ "$n" = "1" ] || { echo ""; return 0; }
  v="$(sed -n 's/.*<WpfLinuxSelfBuiltConfiguration[^>]*>\([^<]*\)<.*/\1/p' "$SBC_DECL" | head -1)"
  printf '%s' "$v"
}

SBC_VALUE="$(_sbc_parse)"

_sbc_usage() { sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

if [ "${BASH_SOURCE[0]}" != "$0" ]; then
  # ── 被 source：导出并做**廉价合法性校验**（重活留给 --check）───────────────
  case "$SBC_VALUE" in
    Debug|Release) export SELFBUILT_CONFIG="$SBC_VALUE" ;;
    *) echo "selfbuilt-config: ❌ 声明处解析失败或取值非法（decl=$SBC_DECL value='$SBC_VALUE'）" >&2; return 2 ;;
  esac
  return 0
fi

case "${1:-}" in
  ""|-h|--help)
    [ "${1:-}" = "" ] || { _sbc_usage; exit 0; }
    printf '%s\n' "${SBC_VALUE:-<解析失败>}"
    [ -n "$SBC_VALUE" ] || exit 2
    ;;
  --debt)
    # 阶段 3 的欠账单：还写死 `bin/Debug` 的处数（**只许减少**，见 --debt-check）
    n="$(cd "$SBC_REPO" && grep -rn "bin/Debug" --include="*.sh" --include="*.py" build src tests verify-all.sh 2>/dev/null \
                | grep -v "^build/selfbuilt-config.sh:" | wc -l)"
    echo "SELFCONFIG_DEBT=$n（写死 bin/Debug 的处数；权威件消费点已全部走唯一声明）"
    (cd "$SBC_REPO" && grep -rc "bin/Debug" --include="*.sh" --include="*.py" build src tests verify-all.sh 2>/dev/null | grep -v "^build/selfbuilt-config.sh:" | awk -F: '$2>0' | sort -t: -k2 -rn | head -8)
    ;;
  --debt-check)
    # 🦷 棘轮：**欠账只许减少**。上限是一个**字面量常量**（不做成可覆盖的环境变量 —— 与
    #   `build-hygiene-import-check.sh` 的 `CAND_MIN` 同族：可覆盖就等于没有牙）。
    DEBT_MAX=167   # 见下方注释：本文件自身的匹配串已被排除在计数之外
    n="$(cd "$SBC_REPO" && grep -rn "bin/Debug" --include="*.sh" --include="*.py" build src tests verify-all.sh 2>/dev/null \
                | grep -v "^build/selfbuilt-config.sh:" | wc -l)"
    if [ "$n" -le "$DEBT_MAX" ]; then
      echo "SELFCONFIG_DEBT_CHECK=PASS live=$n max=$DEBT_MAX（只许减少；降到 0 = 阶段 3 完成）"
      [ "$n" = "$DEBT_MAX" ] && echo "  ⚠️ 与上限相等：本波没有减少欠账（如实报，不当红）"
      exit 0
    fi
    echo "SELFCONFIG_DEBT_CHECK=FAIL live=$n > max=$DEBT_MAX（欠账变多了 ⇒ 有人又写死了配置；停下来核）"
    exit 1
    ;;
  --check)
    rc=0
    # 牙 ①
    if [ -f "$SBC_DECL" ]; then
      n="$(grep -c '<WpfLinuxSelfBuiltConfiguration' "$SBC_DECL")"
      echo "SELFCONFIG_DECL=$([ "$n" = "1" ] && echo PASS || echo FAIL) n=$n file=${SBC_DECL#$SBC_REPO/}"
      [ "$n" = "1" ] || rc=1
    else
      echo "SELFCONFIG_DECL=NOINFO reason=decl-file-absent file=$SBC_DECL"; exit 2
    fi
    case "$SBC_VALUE" in
      Debug|Release) echo "SELFCONFIG_VALUE=$SBC_VALUE（合法）" ;;
      *) echo "SELFCONFIG_VALUE=NOINFO reason=unparsable-or-illegal value='$SBC_VALUE'"; exit 2 ;;
    esac
    # 牙 ②（两条图各一个代表工程；用 dotnet msbuild 求值，不做构建）
    command -v dotnet >/dev/null 2>&1 || { echo "SELFCONFIG_MSBUILD=NOINFO reason=dotnet-absent"; exit 2; }
    for proj in "build/System.Xaml.Linux/System.Xaml.Linux.csproj:自产件图" \
                "samples/WpfTextDemo/WpfTextDemo.csproj:样本图"; do
      rel="${proj%%:*}"; label="${proj##*:}"
      got="$(cd "$SBC_REPO" && dotnet msbuild "$rel" -getProperty:WpfLinuxSelfBuiltConfiguration 2>/dev/null | tr -d '\r' | tail -1)"
      if [ "$got" = "$SBC_VALUE" ]; then
        echo "SELFCONFIG_MSBUILD_${label}=PASS shell=$SBC_VALUE msbuild=$got proj=$rel"
      else
        echo "SELFCONFIG_MSBUILD_${label}=FAIL shell=$SBC_VALUE msbuild='${got:-<空>}' proj=$rel"
        rc=1
      fi
    done
    echo "SELFCONFIG_CHECK=$([ "$rc" -eq 0 ] && echo PASS || echo FAIL)"
    exit "$rc"
    ;;
  *) echo "用法: $0 [--check]" >&2; exit 2 ;;
esac
