#!/bin/bash
# ============================================================================
#  windowsdesktop-app-linux-framework.sh
#  —— 装/卸「Linux 版 Microsoft.WindowsDesktop.App 共享框架」（L1 路线①）
# ============================================================================
#
#  【它做什么】
#    在 <dotnet root>/shared/Microsoft.WindowsDesktop.App/<ver>/ 造一个**目录**，
#    里面放：自产 12 件托管件 + 4 个原生 .so + 自造的 deps.json/runtimeconfig.json。
#    装好之后，runtimeconfig 里声明了 `Microsoft.WindowsDesktop.App` 的应用
#    （= `net10.0-windows` 编出来的产物，见 WIN-INTEROP.md §7.1）就能
#      dotnet YourApp.dll
#    直接跑，**不必改 runtimeconfig**。
#
#  【它不做什么】
#    · 不动 <dotnet root>/shared/Microsoft.WindowsDesktop.App 之外的任何东西；
#    · 不包装成 NuGet 包，不改 SDK，不改仓内任何工程；
#    · 不安任何"实现"到真实的 WindowsDesktop.App（本机本来就没有）。
#
#  【回滚】整目录可回滚：
#      bash build/third-party/windowsdesktop-app-linux-framework.sh uninstall
#    就删掉 <root>/shared/Microsoft.WindowsDesktop.App/<ver>/（父目录空则一并删）。
#    ⇒ 撤掉之后，应用必须**逐字**回到原始报错：
#      "Framework: 'Microsoft.WindowsDesktop.App', version '10.0.0' (x64) / No frameworks were found."
#
#  【用法】
#    bash build/third-party/windowsdesktop-app-linux-framework.sh install   [选项]
#    bash build/third-party/windowsdesktop-app-linux-framework.sh uninstall [选项]
#    bash build/third-party/windowsdesktop-app-linux-framework.sh verify    [选项]
#    选项：
#      --root <dir>     dotnet 根（默认：`dotnet` 可执行文件所在目录）
#      --version <ver>  框架目录名（默认 10.0.11；见报告 §前置①"目录名必须是 3 段"）
#      --config <Cfg>   自产件配置（默认取 build/SelfBuiltConfig.props，缺省 Release）
#      --force          install 时覆盖已存在的同名版本目录
#      --dry-run        只打印计划，不落盘
#
#  【为什么是脚本，不是手工 cp】
#    16 个文件 + 两个自造清单，手工摆必然漂移；脚本把"装 / 卸 / 验"三件事
#    绑到同一份清单上（同一语义只有一个来源）。
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"

ACTION="${1:-}"
[ -n "$ACTION" ] || { echo "用法: $0 {install|uninstall|verify} [--root <dir>] [--version <ver>] [--config <Cfg>] [--force] [--dry-run]" >&2; exit 2; }
shift || true

DOTNET_ROOT_OPT=""
VER="10.0.11"
CFG=""
FORCE=0
DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root)    DOTNET_ROOT_OPT="$2"; shift 2 ;;
    --version) VER="$2"; shift 2 ;;
    --config)  CFG="$2"; shift 2 ;;
    --force)   FORCE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

# ── dotnet 根 ───────────────────────────────────────────────────────────────
if [ -n "$DOTNET_ROOT_OPT" ]; then
  DOTNET_ROOT_DIR="$(cd "$DOTNET_ROOT_OPT" && pwd)"
else
  DOTNET_BIN="$(command -v dotnet || true)"
  [ -n "$DOTNET_BIN" ] || { echo "找不到 dotnet；请用 --root 指定 dotnet 根。" >&2; exit 1; }
  DOTNET_ROOT_DIR="$(cd "$(dirname "$(readlink -f "$DOTNET_BIN")")" && pwd)"
fi
SHARED_DIR="$DOTNET_ROOT_DIR/shared/Microsoft.WindowsDesktop.App"
FW_DIR="$SHARED_DIR/$VER"

# ── 自产件配置（唯一声明处）─────────────────────────────────────────────────
if [ -z "$CFG" ]; then
  CFG="$(sed -n 's/.*<WpfLinuxSelfBuiltConfiguration[^>]*>\([^<]*\)<.*/\1/p' "$REPO/build/SelfBuiltConfig.props" | head -1)"
  [ -n "$CFG" ] || CFG="Release"
fi

# ── 清单（同一份清单供 install / verify 用）────────────────────────────────
#   托管 12 件：与官方 WindowsDesktop.App 同名（本仓自产实现）。
MANAGED=(
  "WindowsBase.dll|build/WindowsBase.Linux/bin/$CFG/WindowsBase.dll"
  "System.Xaml.dll|build/System.Xaml.Linux/bin/$CFG/System.Xaml.dll"
  "PresentationCore.dll|build/PresentationCore.Linux/bin/$CFG/PresentationCore.dll"
  "PresentationFramework.dll|build/PresentationFramework.Linux/bin/$CFG/PresentationFramework.dll"
  "PresentationFramework.Classic.dll|build/PresentationFramework.Classic.Linux/bin/$CFG/PresentationFramework.Classic.dll"
  "PresentationUI.dll|build/CycleStub.PresentationUI.Linux/bin/$CFG/PresentationUI.dll"
  "ReachFramework.dll|build/CycleStub.ReachFramework.Linux/bin/$CFG/ReachFramework.dll"
  "System.Printing.dll|build/System.Printing.Linux/bin/$CFG/System.Printing.dll"
  "System.Windows.Input.Manipulations.dll|build/System.Windows.Input.Manipulations.Linux/bin/$CFG/System.Windows.Input.Manipulations.dll"
  "UIAutomationTypes.dll|build/UIAutomationTypes.Linux/bin/$CFG/UIAutomationTypes.dll"
  "UIAutomationProvider.dll|build/UIAutomationProvider.Linux/bin/$CFG/UIAutomationProvider.dll"
  "DirectWriteForwarder.dll|build/DirectWriteForwarder.Linux/bin/$CFG/DirectWriteForwarder.dll"
)
#   原生 4 件：与 samples/ThirdPartyMini 的部署配方同源（同一份权威件）。
NATIVE=(
  "libwpfwin32.so|src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
  "libwpfwic.so|build/DirectWrite.Linux/wic-shim/libwpfwic.so"
  "wpfgfx_cor3.so|build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so"
  "libSkiaSharp.so|build/DirectWrite.Linux/wic-shim/libSkiaSharp.so"
)
#   ⚠️ 运行期 BCL 闭包（**不是**"第 13 件自产件"，是**框架必须替应用提供**的那批 OOB BCL）。
#   为什么框架必须有它们（2026-10-02 实测，见报告 §前置①-4）：
#     应用一旦声明 `FrameworkReference Microsoft.WindowsDesktop.App`，SDK 就认定
#     `System.IO.Packaging` 这一批是"框架提供的"，于是
#       · 把它们从应用的 `ReferenceCopyLocalPaths`/`deps.json` 里剪掉（`CopyLocal=false`）；
#       · 连带的 `PackageReference` 也被 prune（`NU1510`）。
#     ⇒ 框架目录不提供它们，应用启动第一步就 `FileNotFoundException: System.IO.Packaging,
#        Version=9.0.0.0`（内部是 `System.Windows.Application..cctor`）。
#     官方 `Microsoft.WindowsDesktop.App` 本来就含这批件，所以这是"替代 runtime"应有的形态。
#     版本取本仓自产件编译时用的那一版（`build/third-party/WpfLinux.props` 的 9.0.0 系列）。
BCL_PKGS=(
  "System.IO.Packaging.dll|system.io.packaging|9.0.0"
  "System.Configuration.ConfigurationManager.dll|system.configuration.configurationmanager|9.0.0"
  "System.Diagnostics.EventLog.dll|system.diagnostics.eventlog|9.0.0"
  "System.Formats.Nrbf.dll|system.formats.nrbf|9.0.0"
  "System.Security.Cryptography.Pkcs.dll|system.security.cryptography.pkcs|9.0.0"
  "System.Security.Cryptography.ProtectedData.dll|system.security.cryptography.protecteddata|9.0.0"
  "System.Security.Cryptography.Xml.dll|system.security.cryptography.xml|9.0.0"
  "System.Security.Permissions.dll|system.security.permissions|9.0.0"
)
# 自产替身（`#38`：官方 SWE 在非 Windows 上是必抛桩）——按"同名 9.0.0.0"进框架。
BCL_SELFBUILT=(
  "System.Windows.Extensions.dll|build/System.Windows.Extensions.Linux/bin/$CFG/System.Windows.Extensions.dll"
)

# BCL 的权威源解析：NuGet 全局包缓存里取**指定版本**的 `lib/net*/<文件>`
#   ⚠️ **必须按版本取**，不能取"最高版本"：自产件是按 9.0.0 这一版编的，
#      框架里换成 10.0.x（身份 10.0.0.0）就绑不上（"提供高"不满足"请求 9.0.0.0"以外的语义是另一回事，
#      这里要的是**恰好满足请求**）。
resolve_nuget_lib() {  # $1=文件名 $2=包 id $3=版本  → 打印路径
  local gp="${NUGET_PACKAGES:-$HOME/.nuget/packages}"
  local dir="$gp/$2/$3"
  [ -d "$dir" ] || return 1
  # 先取"点版本号"目标（net8.0 / net9.0 …；**排除** net462 这种三位数 TFM），
  # 没有则退回 netstandard*。`sort -V | tail -1` 取最高。
  local libdir
  libdir="$(ls -d "$dir"/lib/*/ 2>/dev/null | sed 's#/$##' | grep -E '/lib/net[0-9]+\.[0-9]+$' | sort -V | tail -1)"
  [ -n "$libdir" ] || libdir="$(ls -d "$dir"/lib/netstandard*/ 2>/dev/null | sed 's#/$##' | sort -V | tail -1)"
  [ -n "$libdir" ] || return 1
  [ -f "$libdir/$1" ] || return 1
  printf '%s\n' "$libdir/$1"
}

sha16() { sha256sum "$1" | cut -c1-16; }

# 全部"目标名|权威源"对（install / verify 共用同一份，避免两处漂移）
all_entries() {
  local e name src id ver
  for e in "${MANAGED[@]}" "${NATIVE[@]}"; do printf '%s|%s\n' "${e%%|*}" "$REPO/${e#*|}"; done
  for e in "${BCL_SELFBUILT[@]}"; do printf '%s|%s\n' "${e%%|*}" "$REPO/${e#*|}"; done
  for e in "${BCL_PKGS[@]}"; do
    name="${e%%|*}"; id="$(printf '%s' "$e" | cut -d'|' -f2)"; ver="$(printf '%s' "$e" | cut -d'|' -f3)"
    if src="$(resolve_nuget_lib "$name" "$id" "$ver")"; then
      printf '%s|%s\n' "$name" "$src"
    else
      printf '%s|%s\n' "$name" "MISSING-IN-NUGET-CACHE"
    fi
  done
}

print_plan() {
  echo "REPO            = $REPO"
  echo "DOTNET_ROOT     = $DOTNET_ROOT_DIR"
  echo "FRAMEWORK_DIR   = $FW_DIR"
  echo "SELF-BUILT CFG  = $CFG"
}

# ── deps.json / runtimeconfig.json 生成（最小内容，仿 Microsoft.NETCore.App 形态）──
#
#   ⚠️ `assemblyVersion` **必须有**（前置①实测）：
#     留空 ⇒ 宿主为该框架件建出的 TPA 条目版本为空 ⇒ 与应用的 `AssemblyRef 4.0.0.1`
#     对不上（连 `Microsoft.NETCore.App` 里那份 4.0.0.0 的空门面也比它"高"）
#     ⇒ 启动即 `FileNotFoundException: WindowsBase, Version=4.0.0.1`。
#     版本**从文件里现读**（`read_assembly_versions`），不写死、不猜。
read_assembly_versions() {  # $1.. = dll 路径；输出 "<name>\t<version>"
python3 - "$@" <<'PY'
import struct, sys, os

def rva2off(data, sections, rva):
    for vaddr, vsize, rawptr, rawsize in sections:
        if vaddr <= rva < vaddr + max(vsize, rawsize):
            return rawptr + (rva - vaddr)
    return None

def assembly_version(path):
    data = open(path, 'rb').read()
    e = struct.unpack_from('<I', data, 0x3c)[0]
    coff = e + 4
    nsec = struct.unpack_from('<H', data, coff + 2)[0]
    size_opt = struct.unpack_from('<H', data, coff + 16)[0]
    opt = coff + 20
    magic = struct.unpack_from('<H', data, opt)[0]
    dd = opt + (96 if magic == 0x10b else 112)
    cli_rva = struct.unpack_from('<I', data, dd + 14 * 8)[0]
    sec = opt + size_opt
    sections = []
    for i in range(nsec):
        o = sec + i * 40
        vsize, vaddr, rawsize, rawptr = struct.unpack_from('<IIII', data, o + 8)
        sections.append((vaddr, vsize, rawptr, rawsize))
    cli = rva2off(data, sections, cli_rva)
    md_rva = struct.unpack_from('<I', data, cli + 8)[0]
    md = rva2off(data, sections, md_rva)
    ver_len = struct.unpack_from('<I', data, md + 12)[0]
    p = md + 16 + ver_len
    nstreams = struct.unpack_from('<H', data, p + 2)[0]
    p += 4
    streams = {}
    for _ in range(nstreams):
        off, size = struct.unpack_from('<II', data, p); p += 8
        end = data.index(b'\0', p)
        streams[data[p:end].decode('ascii', 'replace')] = (md + off, size)
        p = (end + 1 + 3) & ~3
    toff, tsize = streams.get('#~') or streams.get('#-')
    heap = data[toff + 6]
    str_sz = 4 if (heap & 0x01) else 2
    blob_sz = 4 if (heap & 0x04) else 2
    tbl = data[toff:toff + tsize]
    so = streams['#Strings'][0]
    base = os.path.splitext(os.path.basename(path))[0]
    for h in range(0, len(tbl) - 22):
        if tbl[h:h + 4] != b'\x04\x80\x00\x00':
            continue
        ma, mi, bd, rv = struct.unpack_from('<HHHH', tbl, h + 4)
        if ma > 100 or mi > 100:
            continue
        ni = struct.unpack_from('<I' if str_sz == 4 else '<H', tbl, h + 16 + blob_sz)[0]
        end = data.index(b'\0', so + ni)
        if data[so + ni:end].decode('ascii', 'replace') == base:
            return "%d.%d.%d.%d" % (ma, mi, bd, rv)
    raise SystemExit("Assembly 表未找到: " + path)

for p in sys.argv[1:]:
    print("%s\t%s" % (os.path.basename(p), assembly_version(p)))
PY
}

gen_deps() {  # $1 = 目标目录
  local verfile="$1/.assembly-versions.tsv"
  # shellcheck disable=SC2046
  read_assembly_versions $(ls "$1"/*.dll) > "$verfile"
  python3 - "$1" "$VER" "$verfile" <<'PY'
import json, os, sys
d, ver, verfile = sys.argv[1], sys.argv[2], sys.argv[3]
vers = {}
for line in open(verfile):
    n, v = line.rstrip('\n').split('\t')
    vers[n] = v
managed = sorted(f for f in os.listdir(d) if f.endswith('.dll'))
native  = sorted(f for f in os.listdir(d) if f.endswith('.so'))
pkg = "Microsoft.WindowsDesktop.App.Runtime.linux-x64/%s" % ver
runtime = {f: {"assemblyVersion": vers[f]} for f in managed}   # assemblyVersion 必需；fileVersion 不实读就不写
entry = {"runtime": runtime}
if native:
    entry["native"] = {f: {} for f in native}
deps = {
    "runtimeTarget": {"name": ".NETCoreApp,Version=v10.0/linux-x64", "signature": ""},
    "compilationOptions": {},
    "targets": {".NETCoreApp,Version=v10.0": {},
                ".NETCoreApp,Version=v10.0/linux-x64": {pkg: entry}},
    "libraries": {pkg: {"type": "package", "serviceable": True, "sha512": "",
                        "path": "microsoft.windowsdesktop.app.runtime.linux-x64/%s" % ver}},
}
open(os.path.join(d, "Microsoft.WindowsDesktop.App.deps.json"), "w").write(json.dumps(deps, indent=2))
PY
  rm -f "$verfile"
}

gen_runtimeconfig() {  # $1 = 目标目录
python3 - "$1" <<'PY'
import json, os, sys
d = sys.argv[1]
cfg = {"runtimeOptions": {"tfm": "net10.0",
                          "rollForward": "LatestPatch",
                          "framework": {"name": "Microsoft.NETCore.App", "version": "10.0.0"}}}
open(os.path.join(d, "Microsoft.WindowsDesktop.App.runtimeconfig.json"), "w").write(json.dumps(cfg, indent=2))
PY
}

do_install() {
  echo "=== install：Linux 版 Microsoft.WindowsDesktop.App（L1 路线①）==="
  print_plan
  [ "$DRY" = 1 ] && { echo "(--dry-run：不落盘)"; return 0; }
  [ -e "$FW_DIR" ] && [ "$FORCE" != 1 ] && { echo "已存在：$FW_DIR（要覆盖请加 --force）" >&2; exit 1; }

  mkdir -p "$SHARED_DIR"
  local stage="$SHARED_DIR/.stage-$VER-$$"
  rm -rf "$stage"; mkdir -p "$stage"

  while IFS= read -r e; do
    local name="${e%%|*}" src="${e#*|}"
    [ "$src" = "MISSING-IN-NUGET-CACHE" ] && { echo "缺件（NuGet 缓存里找不到 ${name}；先跑 build/setup-env.sh 预热）" >&2; rm -rf "$stage"; exit 1; }
    [ -f "$src" ] || { echo "缺件（大声失败）：$src" >&2; rm -rf "$stage"; exit 1; }
    cp -p "$src" "$stage/$name"
  done < <(all_entries)
  gen_deps "$stage"
  gen_runtimeconfig "$stage"

  rm -rf "$FW_DIR"
  mv "$stage" "$FW_DIR"          # temp + rename：装出来的框架目录一次到位
  echo "OK 已安装 → $FW_DIR"
  echo "--- 逐件在位（sha16 / 字节）---"
  list_all
}

do_uninstall() {
  echo "=== uninstall ==="
  print_plan
  [ "$DRY" = 1 ] && { echo "(--dry-run：不删)"; return 0; }
  if [ ! -e "$FW_DIR" ]; then echo "不存在（无操作）：$FW_DIR"; return 0; fi
  rm -rf "$FW_DIR"
  rmdir "$SHARED_DIR" 2>/dev/null || true     # 父目录只剩空壳才删
  echo "OK 已移除 $FW_DIR（整目录回滚）"
  echo "父目录现在：$(ls -la "$SHARED_DIR" 2>/dev/null || echo '（已删）')"
}

list_all() {
  while IFS= read -r e; do
    local name="${e%%|*}"
    if [ -f "$FW_DIR/$name" ]; then
      printf "  %-42s %10d  %s\n" "$name" "$(stat -c%s "$FW_DIR/$name")" "$(sha16 "$FW_DIR/$name")"
    else
      printf "  %-42s %s\n" "$name" "MISSING"
    fi
  done < <(all_entries)
  for j in Microsoft.WindowsDesktop.App.deps.json Microsoft.WindowsDesktop.App.runtimeconfig.json; do
    if [ -f "$FW_DIR/$j" ]; then
      printf "  %-42s %10d  %s\n" "$j" "$(stat -c%s "$FW_DIR/$j")" "$(sha16 "$FW_DIR/$j")"
    else
      printf "  %-42s %s\n" "$j" "MISSING"
    fi
  done
}

do_verify() {
  local bad=0 n=0
  while IFS= read -r e; do
    local name="${e%%|*}" src="${e#*|}"
    n=$((n + 1))
    if ! cmp -s "$FW_DIR/$name" "$src"; then
      echo "DIFF/MISSING: $name（框架目录 vs 权威件）"; bad=1
    fi
  done < <(all_entries)
  echo "--- 框架目录内容 ---"; list_all
  [ "$bad" = 0 ] && echo "VERIFY=PASS ($n/$n 与权威件逐字节相同)" || { echo "VERIFY=FAIL"; exit 1; }
}

case "$ACTION" in
  install)   do_install ;;
  uninstall) do_uninstall ;;
  verify)    do_verify ;;
  *) echo "未知动作: $ACTION" >&2; exit 2 ;;
esac
