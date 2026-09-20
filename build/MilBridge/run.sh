#!/usr/bin/env bash
# T1 / MilBridge —— 一键复现脚本。
#
#   bash build/MilBridge/run.sh             # 生成 + AOT 发布 + 跑闭环
#   bash build/MilBridge/run.sh gen         # 只重新生成 Exports.g.cs
#   bash build/MilBridge/run.sh build       # 只 AOT 发布
#   bash build/MilBridge/run.sh test        # 只跑闭环（复用已有产物）
#   bash build/MilBridge/run.sh t2          # 只跑 T2 调用姿势复现（M7c3 回归）
#   bash build/MilBridge/run.sh hb          # 只跑 HarfBuzz 可行性 spike（M7c4，M0..M6）
#   bash build/MilBridge/run.sh strip       # 只跑运行期 GSUB/GPOS 剥离（M7c5，验收 ①-⑤）
#   bash build/MilBridge/run.sh wic         # 只跑 WIC 句柄桥 + 引用计数配平（M7c6）
#   bash build/MilBridge/run.sh textline    # 只跑 TextLine 契约原型（轨道A）
#   bash build/MilBridge/run.sh compositefont # 只跑 M7d 复合字体短路 + GlyphTypeface(Uri) 诚实失败（补丁 J）
#   bash build/MilBridge/run.sh icu         # 只跑 ICU(UAX#14) vs DWrite 行断对拍预检（B2 前置，73 例）
#   bash build/MilBridge/run.sh nums        # 「一个数字两个消费者」一致性（导出总数/深度分布）
#   bash build/MilBridge/run.sh tline       # 只跑 B2 对拍 harness（驱动真 shim 源：73 例 + 真机 oracle 614 例）
#   bash build/MilBridge/run.sh spike       # 只跑 Phase 1-A 最小验证
#   bash build/MilBridge/run.sh t1d         # 只跑 T1d/R1 覆盖回退探针（四档 + A/B 逐位）
#
# 说明：所有构建产物落在 build/MilBridge/.artifacts/ 下（-p:ArtifactsPath），
#       src/ 与 build/ 下其它工程目录**不产生任何写入**。

set -euo pipefail

export PATH="$HOME/.dotnet:$PATH"

MB="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# refresh_applocal() 要用权威产物路径 ⇒ 这里显式定义 ROOT（脚本原先只有 MB/ART；
# 少了它会在 `set -u` 下炸 "ROOT: 未绑定的变量" —— 实测踩过）。
ROOT="$(cd -- "$MB/.." && pwd)"
# ★ `#39` 阶段 2/3：AOT 桥的输入件也必须跟随**唯一声明**（否则会静默用陈旧 Debug 件）。
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../build/selfbuilt-config.sh"
ART="$MB/.artifacts"
PUB="$ART/publish/MilBridge.Linux/release_linux-x64"
CMD="${1:-all}"

gen() {
  echo "== [1/4] 扫描上游 [DllImport(DllImport.MilCore)] =="
  MB_JSON="$MB/gen/milcore-dllimports.json" python3 "$MB/tools/scan-milcore-dllimports.py" | head -4
  echo "== [2/4] 生成 108 个 AOT 包装 =="
  python3 "$MB/tools/gen-exports.py"
}

build() {
  echo "== [3/4] AOT 发布（NativeLib=Shared，-m:1） =="
  ( cd "$MB/src/MilBridge.Linux" && \
    dotnet publish -c Release -r linux-x64 -m:1 --nologo -p:ArtifactsPath="$ART" )
  echo "-- 导出符号对拍 --"
  nm -D --defined-only "$PUB/wpfgfx_cor3.so" | sed 's/.* T //; s/@@.*//' | sort -u > /tmp/mb-nm.txt
  sort -u "$MB/gen/export-symbols.txt" > /tmp/mb-want.txt
  local missing extra
  missing=$(comm -23 /tmp/mb-want.txt /tmp/mb-nm.txt | wc -l)
  extra=$(comm -13 /tmp/mb-want.txt /tmp/mb-nm.txt | grep -cE '^(Mil|MIL|Wgx|Wpf|GetNext|IWIC|Interop|Render)' || true)
  echo "清单 $(wc -l < /tmp/mb-want.txt) 个 / .so 实到 $(( $(wc -l < /tmp/mb-nm.txt) - extra )) 个；缺失 $missing；额外（诊断面）$extra"
  [ "$missing" -eq 0 ]
}

test_closed_loop() {
  echo "== [4/4] 闭环测试 =="
  ( cd "$MB/tests/ClosedLoop" && \
    dotnet build -c Release -m:1 --nologo -p:ArtifactsPath="$ART" >/dev/null )
  # **刻意不设 LD_LIBRARY_PATH**：验证 .so 自带 SkiaSharp 解析（MilBridge_SetNativeDir）
  ( cd "$ART/bin/ClosedLoop/release" && dotnet MilBridge.ClosedLoop.dll )
}

t2repro() {
  echo "== T2 调用姿势复现（FontBridge 的 TryLoad+GetExport+delegate，不经 resolver）=="
  ( cd "$MB/tests/T2Repro" && \
    dotnet build -c Release -m:1 --nologo -p:ArtifactsPath="$ART" >/dev/null )
  local font="$MB/../../build/fonts/NotoSans-Regular.ttf"
  # **刻意不设 LD_LIBRARY_PATH**：验证 dladdr 自定位（M7c3 的修复点）
  ( cd "$ART/bin/T2Repro/release" && env -u LD_LIBRARY_PATH \
      dotnet MilBridge.T2Repro.dll --t2-first "$font" )
}

compositefont() {
  echo "== M7d 补丁 J · 复合字体短路 + GlyphTypeface(Uri) 诚实失败（验收 ①-④ + 追加 1）=="
  local ROOT="$MB/../.."
  local APPLIER="$ROOT/src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py"

  echo "-- 应用器 --check（0 = 生成物与 csproj 接线都已就位）--"
  python3 "$APPLIER" --check || return 1

  echo
  echo "-- 接线求值（**不读 XML**：用 msbuild -getItem:Compile 求值）--"
  local items upstream_n gen_n
  items=$(dotnet msbuild "$ROOT/build/PresentationCore.Linux/PresentationCore.Linux.csproj" -m:1 --nologo \
            -getItem:Compile -p:Configuration=Debug 2>/dev/null)
  upstream_n=$(printf '%s' "$items" | grep -c 'internal/FontCache/FamilyCollection.cs"' || true)
  gen_n=$(printf '%s' "$items" | grep -c 'PresentationCore.Linux/FamilyCollection.Linux.cs"' || true)
  echo "   Compile 里上游 FamilyCollection.cs 的条数 = $upstream_n（要求 0：被 Remove 掉）"
  echo "   Compile 里生成物 FamilyCollection.Linux.cs 的条数 = $gen_n（要求 >= 1）"

  echo
  echo "-- 探针（PC 重建**前**跑：S2/S5/S6 失败是预期的；重建**后**跑应当 0 失败）--"
  ( cd "$MB/tests/CompositeFontProbe" && dotnet build -c Release -m:1 --nologo >/dev/null )
  cp "$ROOT/src/WpfGfx.Linux.Native/bin/libwpfwin32.so" "$MB/tests/CompositeFontProbe/bin/Release/" 2>/dev/null || true
  local font="$ROOT/build/fonts/NotoSans-Regular.ttf" rc=0
  # 刻意**只**给 build/fonts：provider 首个族 = Noto Sans（确定性，S8 用它做替身族）
  ( cd "$MB/tests/CompositeFontProbe/bin/Release" && \
    WPF_LINUX_FONT_DIR="$ROOT/build/fonts" dotnet MilBridge.CompositeFontProbe.dll --font "$font" ) || rc=$?
  echo "   → 退出码 $rc（0 = 全绿）"

  echo
  echo "-- 对照证据：只做 ① 短路、不做 ② 代偿的后果（探针内模拟，磁盘未改）--"
  ( cd "$MB/tests/CompositeFontProbe/bin/Release" && \
    WPF_LINUX_FONT_DIR="$ROOT/build/fonts" dotnet MilBridge.CompositeFontProbe.dll --simulate-shortcircuit --font "$font" ) \
    | sed -n '/S2（/,/S2b（/p' | head -20 || true

  return $rc
}

tline() {
  echo "== T1b/B2 · HbTextLine 对拍 harness（**驱动真 shim 源**：73 例 CJK + 真机 oracle 614 例）=="
  local SHIM="$MB/../shims/PresentationCore.HbTextLine.cs"
  local SHA; SHA=$(sha256sum "$SHIM" | cut -d' ' -f1)
  echo "被测文件 = build/shims/PresentationCore.HbTextLine.cs"
  echo "           sha256=$SHA  大小=$(wc -c < "$SHIM") B  行数=$(wc -l < "$SHIM")"
  echo "           mtime=$(date -r "$SHIM" +%F\ %T)"
  echo
  # 真机 oracle 的紧凑副本（53MB 原始 dump 流式抽取；缺了就生成）
  if [ ! -f "$MB/gen/layout-b34-compact.json" ]; then
    echo "-- 生成 gen/layout-b34-compact.json（流式抽取真机 oracle，约 25s）--"
    python3 "$MB/tools/extract-layout-b34.py" >/dev/null
  fi
  # ① 直构分支编译闸门（PC 内形态：靠 PC 的 IVT 让 internal 可见）+ **默认值语义自检**
  echo "-- [1/3] 直构分支编译闸门 + 默认值语义自检（TEXTLINE_SHIM_DIRECT，PC 内形态）--"
  refresh_applocal "$MB/tests/HbTextLineParity/bin/Release"
  ( cd "$MB/tests/DirectBranchCheck" && dotnet build -c Release -m:1 --nologo -p:HbShimSrc="$SHIM" 2>&1 | tail -2 \
    && cd bin/Release && dotnet PresentationCore.Tests.dll )
  # ② 对拍主体
  echo "-- [2/3] 对拍主体（反射分支；直构分支由主控重建 PC 后验）--"
  ( cd "$MB/tests/HbTextLineParity" && dotnet build -c Release -m:1 --nologo -p:HbShimSrc="$SHIM" >/dev/null )
  local rc=0
  ( cd "$MB/tests/HbTextLineParity/bin/Release" && T1B_SHIM_SHA256="$SHA" dotnet MilBridge.HbTextLineParity.dll ) || rc=$?
  # ③ LS 绊线装置自证（装置自己必须先证明不撒谎）
  echo
  echo "-- [3/3] LS 绊线装置自证（ld.so 的 LD_DEBUG=symbols 日志 + nm -D 交叉核对）--"
  bash "$MB/tools/t1b-ls-tripwire.sh" --selftest | tail -6
  echo
  echo "→ harness 退出码 $rc（0 = 73 例逐行全等 + 真机口径记账/Collapse 全绿；"
  echo "   非 0 时看上面 ❌ —— 已知未实现项会**保留红**，不会为了变绿而放宽）"
  return $rc
}

hbspike() {
  echo "== T1/M7c4 · 路线 B（HarfBuzz）可行性 spike（M0..M6，7 条对照）=="
  ( cd "$MB/tests/HbSpike" && \
    dotnet build -c Release -m:1 --nologo -p:ArtifactsPath="$ART" >/dev/null )
  # 刻意不设 LD_LIBRARY_PATH：HarfBuzz 走系统 libharfbuzz.so.0，
  # MilCore 轮廓走 dladdr 自定位（M7c3）。两者都不该依赖环境变量。
  ( cd "$ART/bin/HbSpike/release" && env -u LD_LIBRARY_PATH dotnet MilBridge.HbSpike.dll )
}

striplayout() {
  echo "== T1/M7c5 路线 C：运行期 GSUB/GPOS 剥离（验收 ①-⑤）=="
  # 先确保 WiringSmoke 是最新的（指标 ② 靠它跑真实 PC 代码路径）
  dotnet build "$MB/../DirectWrite.Linux/WiringSmoke/DirectWrite.Linux.WiringSmoke.csproj" \
      -c Debug -m:1 --nologo >/dev/null
  dotnet test "$MB/../DirectWrite.Linux/Tests/DirectWrite.Linux.Tests.csproj" \
      -c Debug -m:1 --nologo \
      --filter "FullyQualifiedName~FontLayoutStrippingTests|FullyQualifiedName~StripLayoutSmokeTests"
}

wic() {
  echo "== T1/M7c6 · MILQueryInterface 外部句柄桥（WIC）+ 引用计数配平 =="
  echo "-- GUID 漂移检查（常量必须来自 PC 的 MILGuidData）--"
  python3 "$MB/tools/check-mil-guids.py" || return 1
  echo
  echo "-- 闭环（真 .so + 真 libwpfwic.so，走真 P/Invoke；G 组是 WIC 取证）--"
  ( cd "$MB/tests/ClosedLoop" && \
    dotnet build -c Release -m:1 --nologo -p:ArtifactsPath="$ART" >/dev/null )
  ( cd "$ART/bin/ClosedLoop/release" && env -u LD_LIBRARY_PATH dotnet MilBridge.ClosedLoop.dll )
}

# ── ⭐ 探针的 app-local 副本同步（T1b/2026-09-11；T2 建议⑤ 的根治）────────────────────
#  【为什么必须】探针 bin/Release 里带的是被测程序集的**副本**（DirectWriteForwarder / Provider /
#    PresentationCore / WindowsBase）。**`dotnet build` 不会保证刷新它们**：MSBuild 的 Copy 任务在
#    "目标文件比源文件**更新**"时会 **SkipUnchangedFiles 跳过** ⇒ 只要有人/某次运行把旧副本写成
#    更新的 mtime，**陈旧副本就会一直留着** ⇒ 探针测的是旧 Provider/旧 dll ⇒ **假红**（本项目已栽过一族）。
#    实测（本轮）：`build/MilBridge/tests/T2eLineHeight/bin/Release/DirectWriteForwarder.dll` = fbc6ee51…
#    而权威 `build/DirectWriteForwarder.Linux/bin/Debug/DirectWriteForwarder.dll` = c1020f68… ⇒ **确为陈旧**。
#  【做法】跑探针前**无条件** `cp -f` 权威产物覆盖副本，并把两侧 sha **打出来**（可核对、可留档）。
#  【边界】只读权威产物（含 T2 的 build/DirectWrite.Linux/**），**不写**它们。
refresh_applocal() {   # $1 = 探针 bin/Release 目录
  local d="$1"
  [ -d "$d" ] || return 0
  # ⚠️ 路径口径（T1d 发现、T1b 修）：本脚本的 ROOT = "$MB/.." = **…/wpf-linux/build 本身**
  #   ⇒ 权威产物写成 "$ROOT/DirectWriteForwarder.Linux/…"；曾误拼成 "$ROOT/build/…" ⇒
  #   变成 …/wpf-linux/build/build/… ⇒ **四个权威件永远"缺失（跳过）"**（死代码 + 误导性日志）。
  # 【为什么"影响为零"也要留着这个函数】探针 csproj 用 HintPath + Private=true 直接引权威件，
  #   正常情况下 bin/Release 的副本与权威件 sha 相同（实测 PresentationCore.dll 两侧同为 455ddb38…）；
  #   但"复制语义"依赖 build 的增量判断 ⇒ 这个函数把它变成**无条件 cp -f + 打印两侧 sha**（可核对）。
  local pairs=(
    "$ROOT/DirectWriteForwarder.Linux/bin/$SELFBUILT_CONFIG/DirectWriteForwarder.dll"
    "$ROOT/DirectWrite.Linux/Provider/bin/$SELFBUILT_CONFIG/DirectWrite.Linux.Provider.dll"
    "$ROOT/PresentationCore.Linux/bin/$SELFBUILT_CONFIG/PresentationCore.dll"
    "$ROOT/WindowsBase.Linux/bin/$SELFBUILT_CONFIG/WindowsBase.dll"
  )
  local f base a b MISSING=0
  for f in "${pairs[@]}"; do
    if [ ! -f "$f" ]; then
      echo "  [applocal] ⚠️⚠️ **权威产物缺失，未同步**（这不是跳过，是没得同步）：$f" >&2
      echo "  [applocal] ⚠️⚠️ 缺件 = **无法证明探针测的是权威件** ⇒ 本次读数不可信，请先建出该产物" >&2
      MISSING=$((MISSING + 1))
      continue
    fi
    base="$(basename "$f")"
    a=$(sha256sum "$f" | cut -c1-16)
    if [ -f "$d/$base" ]; then b=$(sha256sum "$d/$base" | cut -c1-16); else b="(缺)"; fi
    if [ "$a" != "$b" ]; then
      cp -f "$f" "$d/$base"
      echo "  [applocal] $base：**陈旧 $b → 已同步为权威 $a**"
    else
      echo "  [applocal] $base：已与权威一致（$a）"
    fi
  done
  if [ "$MISSING" -gt 0 ]; then
    echo "  [applocal] 汇总：**$MISSING 个权威产物缺失** ⇒ 本次探针读数不成立（缺件不静默）"
    return 1
  fi
  echo "  [applocal] 汇总：4/4 权威产物均已就位并与副本一致/已同步"
  return 0
}

textline() {
  echo "== 轨道A/B1 · TextLine 落地脚手架（编真 shim 源文件 + 9 个欠账回退计数）=="
  # 契约探针（先跑：它给出 6 个宿主侧假设的成立/不成立）
  ( cd "$MB/tests/ContractProbe" && dotnet build -c Release -m:1 --nologo >/dev/null )
  cp "$MB/../../src/WpfGfx.Linux.Native/bin/libwpfwin32.so" "$MB/tests/ContractProbe/bin/Release/" 2>/dev/null || true
  ( cd "$MB/tests/ContractProbe/bin/Release" && dotnet MilBridge.ContractProbe.dll ) || true
  echo
  # 原型本体
  ( cd "$MB/tests/TextLineProto" && dotnet build -c Release -m:1 --nologo >/dev/null )
  ( cd "$MB/tests/TextLineProto/bin/Release" && dotnet MilBridge.TextLineProto.dll )
}

icu() {
  echo "== B2 预检 · ICU(UAX#14) vs DWrite 行断对拍（U1 的 73 例真值，含 58 个 kinsoku-*）=="
  # ⭐ 规则实现现在在 shim 里（HbBreakEngine）⇒ 本目标**驱动真 shim 源**；把它的 sha256 钉住并打印
  local SHIM="$MB/../shims/PresentationCore.HbTextLine.cs"
  local SHA; SHA=$(sha256sum "$SHIM" | cut -d' ' -f1)
  echo "被测文件 = build/shims/PresentationCore.HbTextLine.cs  sha256=$SHA  ($(wc -l < "$SHIM") 行)"
  refresh_applocal "$MB/tests/IcuBreakParity/bin/Release"
  ( cd "$MB/tests/IcuBreakParity" && dotnet build -c Release -m:1 --nologo \
      -p:HbShimSrc="$SHIM" >/dev/null )
  local rc=0
  ( cd "$MB/tests/IcuBreakParity/bin/Release" && T1B_SHIM_SHA256="$SHA" dotnet MilBridge.IcuBreakParity.dll ) || rc=$?
  echo
  echo "→ 探针退出码 $rc（0 = 73 例逐例一致；1 = 有差异 ⇒ 以 DWrite 真值为准，需在 ICU 之上叠规则）"
  echo "   ⚠️ 这里**刻意不**把 rc 当构建失败返回：\"不一致\" 是预检的结论，不是脚本坏了。"
  return 0
}

t1d() {
  echo "== T1d · R1（run 级字体 + 按码点覆盖回退 + 多字体整形）—— 覆盖回退探针 =="
  echo "   （四个档位：default / ab-off / fonts-ui / two-run；期望写在 tools/t1d-probe.sh 末尾）"
  bash "$MB/tools/t1d-probe.sh" "${T1D_OUTDIR:-/tmp/t1d-readings}"
}

nums() {
  echo "== T1b · 「一个数字两个消费者」一致性（唯一真值来源 gen/landing-table.md）=="
  python3 "$MB/tools/check-export-numbers.py"
  local rc=$?
  echo
  echo "-- 牙的自检（证明它能变红）--"
  python3 "$MB/tools/check-export-numbers.py" --self-test
  return $rc
}

spike() {
  echo "== Phase 1-A 最小验证 =="
  ( cd "$MB/spike/AotLib" && \
    dotnet publish -c Release -r linux-x64 -m:1 --nologo -p:NativeLib=Shared -p:PublishAot=true >/dev/null )
  nm -D --defined-only "$MB/spike/AotLib/bin/Release/net10.0/linux-x64/publish/aotspike.so" | grep aotspike
  ( cd "$MB/spike/SmokeTest" && dotnet build -c Release -m:1 --nologo >/dev/null )
  cp "$MB/spike/AotLib/bin/Release/net10.0/linux-x64/publish/aotspike.so" \
     "$MB/spike/SmokeTest/bin/Release/net10.0/"
  ( cd "$MB/spike/SmokeTest" && dotnet bin/Release/net10.0/SmokeTest.dll )
}

case "$CMD" in
  gen)   gen ;;
  build) build ;;
  test)  test_closed_loop ;;
  t2)    t2repro ;;
  hb)    hbspike ;;
  strip) striplayout ;;
  wic)   wic ;;
  textline) textline ;;
  compositefont) compositefont ;;
  icu)   icu ;;
  nums)  nums ;;
  spike) spike ;;
  all)   gen && build && test_closed_loop && t2repro && hbspike && wic ;;
  tline) tline ;;
  t1d)   t1d ;;
  *)     echo "用法: $0 [gen|build|test|t2|hb|strip|wic|textline|compositefont|icu|tline|t1d|spike|all]"; exit 2 ;;
esac
